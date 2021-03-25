--Revision: $Revision: 1.9 $
DECLARE
	v_SUPER_ID	NUMBER(9);
	v_POWER_ID	NUMBER(9);
	v_USER_ID	NUMBER(9);
	v_ADMIN_ID	NUMBER(9);
	v_READ_ID	NUMBER(9);

	v_ACTION_ID NUMBER(9);
	v_ROLES		UT.STRING_MAP;

	----------------------------------------------------------------------------------------------------
	PROCEDURE PUT_SYSTEM_ACTION_ROLE
		(
		p_ACTION_ID IN NUMBER,
		p_ROLE_ID IN NUMBER,
		p_REALM_ID IN NUMBER,
		p_ENTITY_DOMAIN_ID IN NUMBER,
		p_ENTRY_DATE IN DATE
		) AS
    
    	v_COUNT PLS_INTEGER;
    
	BEGIN
		IF p_ROLE_ID IS NULL THEN
			RETURN; -- no role? nothing to do...
		END IF;

		SELECT COUNT(1)
		INTO v_COUNT
		FROM SYSTEM_ACTION_ROLE
		WHERE ACTION_ID = p_ACTION_ID AND ROLE_ID = p_ROLE_ID AND REALM_ID = p_REALM_ID AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
		
		IF v_COUNT = 0 THEN
			INSERT INTO SYSTEM_ACTION_ROLE (ACTION_ID, ROLE_ID, REALM_ID, ENTITY_DOMAIN_ID, ENTRY_DATE)
			VALUES (p_ACTION_ID, p_ROLE_ID, p_REALM_ID, p_ENTITY_DOMAIN_ID, p_ENTRY_DATE);
		END IF;
	END PUT_SYSTEM_ACTION_ROLE;
	--------------------------------------------------------
	FUNCTION PUT_SYSTEM_ACTION
		(
		p_ACTION_ID OUT NUMBER,
		p_ACTION_NAME IN VARCHAR2,
		p_ACTION_ALIAS IN VARCHAR2,
		p_ACTION_DESC IN VARCHAR2,
		p_ENTITY_DOMAIN_ID IN NUMBER,
		p_MODULE IN VARCHAR2,
		p_ACTION_TYPE IN VARCHAR2
		) RETURN BOOLEAN AS
	BEGIN
		p_ACTION_ID := ID.ID_FOR_SYSTEM_ACTION(p_ACTION_NAME);

		IF p_ACTION_ID <= 0 THEN

			SELECT OID.NEXTVAL INTO p_ACTION_ID FROM DUAL;

			INSERT INTO SYSTEM_ACTION (ACTION_ID, ACTION_NAME, ACTION_ALIAS, ACTION_DESC, ENTITY_DOMAIN_ID, MODULE, ACTION_TYPE, ENTRY_DATE)
			VALUES (p_ACTION_ID, p_ACTION_NAME, p_ACTION_ALIAS, p_ACTION_DESC, p_ENTITY_DOMAIN_ID, p_MODULE, p_ACTION_TYPE, SYSDATE);

			RETURN TRUE;

		ELSE
			UPDATE SYSTEM_ACTION SET ACTION_NAME = p_ACTION_NAME, ACTION_ALIAS = p_ACTION_ALIAS, ACTION_DESC = p_ACTION_DESC, ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID, MODULE = p_MODULE, ACTION_TYPE = p_ACTION_TYPE, ENTRY_DATE = SYSDATE
			WHERE ACTION_ID = p_ACTION_ID;

			RETURN FALSE;
		END IF;
	END PUT_SYSTEM_ACTION;
	--------------------------------------------------------    
	PROCEDURE PUT_SYSTEM_ACTION_DOMAINS
		(
		p_ROLES IN UT.STRING_MAP,
		p_ACTION_NAME IN VARCHAR2,
		p_MODULE IN VARCHAR2,
		p_ACTION_TYPE IN VARCHAR2
		) AS
		
		v_ACTION_ID NUMBER(9);
		v_ROLES		UT.STRING_MAP := p_ROLES;
		v_ROLE		VARCHAR2(32);
		v_ROLE_ID	NUMBER(9);
		CURSOR cur_DOMAINS(p_REGEX_CATEGORY IN VARCHAR2) IS
			SELECT ENTITY_DOMAIN_ID
			FROM ENTITY_DOMAIN
			WHERE ((SUBSTR(p_REGEX_CATEGORY,1,1) <> '!' AND REGEXP_LIKE(NVL(ENTITY_DOMAIN_CATEGORY,'?'), p_REGEX_CATEGORY))
				OR (SUBSTR(p_REGEX_CATEGORY,1,1) = '!' AND NOT REGEXP_LIKE(NVL(ENTITY_DOMAIN_CATEGORY,'?'), SUBSTR(p_REGEX_CATEGORY,2))))
				AND NVL(IS_PSEUDO,0) = 0
				AND ENTITY_DOMAIN_ID <> 0;

	BEGIN
		IF NOT PUT_SYSTEM_ACTION(v_ACTION_ID, p_ACTION_NAME, SUBSTR(p_ACTION_NAME,1,32), p_ACTION_NAME, -1, p_MODULE, p_ACTION_TYPE) THEN
		    RETURN; -- if action already existed, return - don't bother changing role assignments
		END IF;

		IF v_ACTION_ID IS NOT NULL THEN

			-- super-user has access to everything
			v_ROLES('S') := '.';

			v_ROLE := v_ROLES.FIRST;
			WHILE v_ROLES.EXISTS(v_ROLE) LOOP
				v_ROLE_ID := CASE v_ROLE WHEN 'S' THEN v_SUPER_ID WHEN 'A' THEN v_ADMIN_ID WHEN 'P' THEN v_POWER_ID WHEN 'U' THEN v_USER_ID WHEN 'R' THEN v_READ_ID ELSE NULL END;
				FOR v_DOMAIN IN cur_DOMAINS(v_ROLES(v_ROLE)) LOOP
					PUT_SYSTEM_ACTION_ROLE(v_ACTION_ID, v_ROLE_ID, SD.g_ALL_DATA_REALM_ID, v_DOMAIN.ENTITY_DOMAIN_ID, SYSDATE);
				END LOOP;
				v_ROLE := v_ROLES.NEXT(v_ROLE);
			END LOOP;

		END IF;

	END PUT_SYSTEM_ACTION_DOMAINS;
	--------------------------------------------------------    
	PROCEDURE PUT_SYSTEM_ACTION_SIMPLE
		(
		p_ROLES IN VARCHAR2,
		p_ACTION_NAME IN VARCHAR2,
		p_ENTITY_DOMAIN_ID IN NUMBER,
		p_MODULE IN VARCHAR2,
		p_ACTION_TYPE IN VARCHAR2
		) AS
		v_ACTION_ID NUMBER(9);
		v_ROLES		UT.STRING_MAP;
		v_IDX		PLS_INTEGER;
	BEGIN
		IF p_ENTITY_DOMAIN_ID = -1 THEN
			FOR v_IDX IN 1..LENGTH(p_ROLES) LOOP
				v_ROLES(SUBSTR(p_ROLES,v_IDX,1)) := '.';
			END LOOP;
			PUT_SYSTEM_ACTION_DOMAINS(v_ROLES, p_ACTION_NAME, p_MODULE, p_ACTION_TYPE);
		ELSE
			IF NOT PUT_SYSTEM_ACTION(v_ACTION_ID, p_ACTION_NAME, SUBSTR(p_ACTION_NAME,1,32), p_ACTION_NAME, p_ENTITY_DOMAIN_ID, p_MODULE, p_ACTION_TYPE) THEN
			    RETURN; -- if action already existed, return - don't bother changing role assignments
			END IF;

			IF v_ACTION_ID IS NOT NULL THEN
				-- super-user has access to everything
				PUT_SYSTEM_ACTION_ROLE(v_ACTION_ID, v_SUPER_ID, SD.g_ALL_DATA_REALM_ID, p_ENTITY_DOMAIN_ID, SYSDATE);
			
				IF INSTR(p_ROLES, 'A') > 0 THEN
					PUT_SYSTEM_ACTION_ROLE(v_ACTION_ID, v_ADMIN_ID, SD.g_ALL_DATA_REALM_ID, p_ENTITY_DOMAIN_ID, SYSDATE);
				END IF;
				IF INSTR(p_ROLES, 'P') > 0 THEN
					PUT_SYSTEM_ACTION_ROLE(v_ACTION_ID, v_POWER_ID, SD.g_ALL_DATA_REALM_ID, p_ENTITY_DOMAIN_ID, SYSDATE);
				END IF;
				IF INSTR(p_ROLES, 'U') > 0 THEN
					PUT_SYSTEM_ACTION_ROLE(v_ACTION_ID, v_USER_ID, SD.g_ALL_DATA_REALM_ID, p_ENTITY_DOMAIN_ID, SYSDATE);
				END IF;
				IF INSTR(p_ROLES, 'R') > 0 THEN
					PUT_SYSTEM_ACTION_ROLE(v_ACTION_ID, v_READ_ID, SD.g_ALL_DATA_REALM_ID, p_ENTITY_DOMAIN_ID, SYSDATE);
				END IF;
			END IF;
		END IF;
	END PUT_SYSTEM_ACTION_SIMPLE;
	--------------------------------------------------------    

BEGIN
    -- get role IDs
	SELECT MAX(ROLE_ID) INTO v_SUPER_ID
	FROM APPLICATION_ROLE
	WHERE ROLE_NAME = 'Super-User';

	SELECT MAX(ROLE_ID) INTO v_ADMIN_ID
	FROM APPLICATION_ROLE
	WHERE ROLE_NAME = 'Administrator';

	SELECT MAX(ROLE_ID) INTO v_READ_ID
	FROM APPLICATION_ROLE
	WHERE ROLE_NAME = 'Read-Only';

	SELECT MAX(ROLE_ID) INTO v_USER_ID
	FROM APPLICATION_ROLE
	WHERE ROLE_NAME = 'User';

	SELECT MAX(ROLE_ID) INTO v_POWER_ID
	FROM APPLICATION_ROLE
	WHERE ROLE_NAME = 'Power-User';

-- MODULE-LEVEL SECURITY ACTIONS
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select ADMIN', 0, 'Admin', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select BILLING', 0, 'Billing', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select DATA SETUP', 0, 'Data Setup', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select FORECASTING', 0, 'Forecasting', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select PRODUCT', 0, 'Product', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select PROFILING', 0, 'Profiling', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select PUBLIC', 0, 'Public', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select QUOTE MANAGEMENT', 0, 'Quote Management', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select SCHEDULING', 0, 'Scheduling', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select SETTLEMENT', 0, 'Settlement', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select WEATHER', 0, 'Weather', 'Select');

	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Update ADMIN', 0, 'Admin', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update BILLING', 0, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update DATA SETUP', 0, 'Data Setup', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update FORECASTING', 0, 'Forecasting', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PRODUCT', 0, 'Product', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PROFILING', 0, 'Profiling', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SAP', 'Update PUBLIC', 0, 'Public', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update QUOTE MANAGEMENT', 0, 'Quote Management', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update SCHEDULING', 0, 'Scheduling', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update SETTLEMENT', 0, 'Settlement', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update WEATHER', 0, 'Weather', 'Update');

	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Delete ADMIN', 0, 'Admin', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete BILLING', 0, 'Billing', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete DATA SETUP', 0, 'Data Setup', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete FORECASTING', 0, 'Forecasting', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete PRODUCT', 0, 'Product', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete PROFILING', 0, 'Profiling', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SAP', 'Delete PUBLIC', 0, 'Public', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete QUOTE MANAGEMENT', 0, 'Quote Management', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete SCHEDULING', 0, 'Scheduling', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete SETTLEMENT', 0, 'Settlement', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Delete WEATHER', 0, 'Weather', 'Delete');
	
-- DATA-LEVEL SECURITY ACTIONS
	
	-- ENTITY MANAGER
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select Entity', -1, 'Data Setup', 'Select');
	v_ROLES('S') := '.';
	v_ROLES('A') := '^Configuration$|^Security$'; -- Admins can only edit config and security entities
	v_ROLES('P') := '!^Security$'; -- Power-users can edit everything EXCEPT security entities
	v_ROLES('U') := '!^Calculations$|^Configuration$|^Security$'; -- Users can edit everything EXCEPT calculation, config, and security entities
	PUT_SYSTEM_ACTION_DOMAINS(v_ROLES, 'Create Entity', 'Data Setup', 'Update');
	PUT_SYSTEM_ACTION_DOMAINS(v_ROLES, 'Update Entity', 'Data Setup', 'Update');
	PUT_SYSTEM_ACTION_DOMAINS(v_ROLES, 'Delete Entity', 'Data Setup', 'Delete');

	-- AUDIT TRAIL
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select Audit Trail', -1, 'Common', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Update Audit Trail', -1, 'Common', 'Update');

	-- PROCESS LOG
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select All Processes', 0, 'Common', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Select Sessions', 0, 'Admin', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Kill Session', 0, 'Admin', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Terminate Any Process', 0, 'Common', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Truncate Trace', 0, 'Common', 'Delete');

	-- OTHER ADMIN
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Manage Users and Roles', 0, 'Admin', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Manage All Credentials', 0, 'Admin', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Manage Message Definitions', 0, 'Admin', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Manage E-mail Log', 0, 'Admin', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_UPDATE_RESTRICTED, 0, 'Admin', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SAP', SD.g_ACTION_APPLY_DATA_LOCK_GROUP, 0, 'Admin', 'Admin');
	
	-- SCHEDULING
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', SD.g_ACTION_TXN_SELECT, -200, 'Scheduling', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_TXN_UPDATE, -200, 'Scheduling', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_TXN_DELETE, -200, 'Scheduling', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_TXN_LOCK_STATE, -200, 'Scheduling', 'Admin');
	
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_BAO_UPDATE, -200, 'Scheduling', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_BAO_LOCK_STATE, -200, 'Scheduling', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SP', SD.g_ACTION_BAO_ACCEPT, -200, 'Scheduling', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SP', SD.g_ACTION_BAO_ACCEPT_EXT, -200, 'Scheduling', 'Admin');
	
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', SD.g_ACTION_SSMETER_SELECT, -390, 'Scheduling', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_SSMETER_UPDATE, -390, 'Scheduling', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_SSMETER_LOCK_STATE, -390, 'Scheduling', 'Admin');
	
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', SD.g_ACTION_MSRMNT_SRC_SELECT, -1040, 'Scheduling', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_MSRMNT_SRC_UPDATE, -1040, 'Scheduling', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_MSRMNT_SRC_LOCK_STATE, -1040, 'Scheduling', 'Admin');

	-- BILLING
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select PSE Billing', -160, 'Billing', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Calculate PSE Billing', -160, 'Billing', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PSE Billing Disputes Internal', -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PSE Billing Disputes External', -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PSE Invoice Due Dates', -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PSE Invoice Line Items', -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PSE Billing Status', -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PSE Invoice Status',  -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Update PSE Invoice Attachments',  -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Send PSE Invoice',  -160, 'Billing', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SP', 'Approve PSE Invoice', -160, 'Billing', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_PSE_BILL_LOCK_STATE, -160, 'Billing', 'Admin');

	-- SCHEDULING/BILLING STATEMENT TYPES
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select by Statement Type', -740, 'Common', 'Select');

	-- ALERTS ADMINISTRATION ACTIONS
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Select Alert Occurrences', -960, 'Admin', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Create Alert Occurrences', -960, 'Admin', 'Create');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Update Alert Occurrences', -960, 'Admin', 'Update');

	-- CONFIGURATION IMPORT/EXPORT
	PUT_SYSTEM_ACTION_SIMPLE('SAPU', 'Configuration Export', 0, 'Common', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAP', 'Configuration Import', 0, 'Common', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SAP', 'Manage My Configuration Imports', 0, 'Common', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Manage All Configuration Imports', 0, 'Common', 'Admin');

	-- CALCULATION PROCESSES
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Manage Calculation Process Security', -1020, 'Common', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select Calculation Process', 0, 'Common', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', 'Select Calculation Process for Entity', -1, 'Common', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SAP', 'Purge Calculation Process', 0, 'Common', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SAP', 'Purge Calculation Process for Entity', -1, 'Common', 'Delete');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Run Calculation Process', 0, 'Common', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', 'Run Calculation Process for Entity', -1, 'Common', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Update Calculation Process Lock State', 0, 'Common', 'Admin');
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Update Calculation Process Lock State for Entity', -1, 'Common', 'Admin');

	-- MARKET_PRICES
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', SD.g_ACTION_MKT_PRICE_SELECT, EC.ED_MARKET_PRICE, 'Product', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_MKT_PRICE_UPDATE, EC.ED_MARKET_PRICE, 'Product', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_MKT_PRICE_LOCK_STATE, EC.ED_MARKET_PRICE, 'Product', 'Admin');

	--BACKGROUND JOBS
	PUT_SYSTEM_ACTION_SIMPLE('SA', 'Manage All Jobs', 0, 'Common', 'Admin');

	--DER Aggregator/Disaggregator Actions
	PUT_SYSTEM_ACTION_SIMPLE('SP',SD.g_ACTION_UPDATE_EXT_DER_RST, EC.ED_EXTERNAL_SYSTEM, 'Load Management', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR',SD.g_ACTION_SELECT_DER_RESULTS, EC.ED_PROGRAM, 'Load Management', 'Select');
	PUT_SYSTEM_ACTION_SIMPLE('SP',SD.g_ACTION_ACCEPT_EXT_DER_RST, EC.ED_PROGRAM, 'Load Management', 'Update');

	PUT_SYSTEM_ACTION_SIMPLE('SAPUR',SD.g_ACTION_SELECT_DER_RST_DET,0,'Load Management','Select');
	
	--DER Capacity Forecast
	PUT_SYSTEM_ACTION_SIMPLE('SAPU', SD.g_ACTION_RUN_DER_FORECAST, 0, 'Load Management', 'Update');

	-- DR Billing
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_CALC_PROGRAM_BILLING, EC.ED_PROGRAM, 'Load Management', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', SD.g_ACTION_SELECT_PROG_BILLING, EC.ED_PROGRAM, 'Load Management', 'Select');

	--Schedule Management Mapping
	PUT_SYSTEM_ACTION_SIMPLE('SPU', SD.g_ACTION_UPDATE_SCHED_MAN_MAP, EC.ED_TRANSACTION, 'Load Management', 'Update');

	-- Updated Incumbent Entity
	PUT_SYSTEM_ACTION_SIMPLE('SA', SD.g_ACTION_UPDATE_INCUMBENT_ENT, CONSTANTS.NOT_ASSIGNED, 'Common', 'Update');
	
	-- Financial Settlement
	PUT_SYSTEM_ACTION_SIMPLE('SAPU', SD.g_ACTION_RUN_ANY_FIN_SETTLEMNT, 0,'Financial Settlement', 'Update');

	-- ROML Import/Export
	PUT_SYSTEM_ACTION_SIMPLE('S', SD.g_ACTION_ROML_PUB_SUB, 0,'Admin', 'Admin');

	-- CSB Bill Case
	PUT_SYSTEM_ACTION_SIMPLE('SAPU', SD.g_ACTION_BILL_CASE_EDIT, 0, 'CSB', 'Update');
	PUT_SYSTEM_ACTION_SIMPLE('SAPUR', SD.g_ACTION_BILL_CASE_VIEW, 0, 'CSB', 'Select');

	PUT_SYSTEM_ACTION_SIMPLE('SAPU', SD.g_ACTION_BIL_CASE_MAN_LIN_EDIT, 0, 'CSB', 'Update');

	-- DONE!
	COMMIT;
END;
/

