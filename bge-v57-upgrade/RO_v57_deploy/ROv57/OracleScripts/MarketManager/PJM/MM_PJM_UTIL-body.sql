CREATE OR REPLACE PACKAGE BODY MM_PJM_UTIL IS

	-- Author  : KCHOPRA
	-- Created : 12/4/2004 5:43:02 PM
	-- Purpose :

	----------------------------------------------------------------------------------------------------
	v_ARRAY_INDEX BINARY_INTEGER;


---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------

FUNCTION GET_CONTRACT_ID_FOR_ISO_ACCT
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2
	) RETURN INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE IS

	v_ID INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;
	v_STATUS NUMBER;
	v_MESSAGE VARCHAR2(4000);
BEGIN

	EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_EXTERNAL_ACCOUNT_NAME, EC.ED_INTERCHANGE_CONTRACT, EC.ES_PJM, v_ID, v_STATUS, v_MESSAGE);

	IF v_STATUS <> GA.SUCCESS THEN
		RAISE_APPLICATION_ERROR(-20001, v_MESSAGE);
	END IF;

	RETURN v_ID;

END GET_CONTRACT_ID_FOR_ISO_ACCT;

---------------------------------------------------------------------------------------------------
/*
	looks at the value of the entity attribute on the contract specified by the external credential
	(credential iso name = contract alias); returns TRUE if value is 'Read' or 'Write',
	otherwise returns FALSE;
*/
FUNCTION HAS_ESUITE_ACCESS
	(
	p_ATTR_ID IN ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE,
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2
	) RETURN BOOLEAN IS

	v_CAN_READ BOOLEAN := FALSE;
	v_ATTRIBUTE_VAL TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
	v_CONTRACT_ID NUMBER(9);
	v_CONTRACT_NAME INTERCHANGE_CONTRACT.CONTRACT_NAME%TYPE;
	v_ERROR_MESSAGE VARCHAR2(4000);
BEGIN
	v_CONTRACT_ID := GET_CONTRACT_ID_FOR_ISO_ACCT(p_EXTERNAL_ACCOUNT_NAME);

	SELECT ATTRIBUTE_VAL
	INTO v_ATTRIBUTE_VAL
	FROM TEMPORAL_ENTITY_ATTRIBUTE T
	WHERE T.OWNER_ENTITY_ID = v_CONTRACT_ID
		AND T.ATTRIBUTE_ID = p_ATTR_ID
		AND ROWNUM = 1;

	IF UPPER(v_ATTRIBUTE_VAL) IN ('READ', 'WRITE', '1') THEN
		v_CAN_READ := TRUE;
	END IF;

	RETURN v_CAN_READ;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		BEGIN
			SELECT CONTRACT_NAME INTO v_CONTRACT_NAME
			FROM INTERCHANGE_CONTRACT
			WHERE CONTRACT_ID = v_CONTRACT_ID;

			v_ERROR_MESSAGE := 'No eSuite Access Attribute was found for Contract ' ||
			v_CONTRACT_NAME || ' and Attribute ID=' || p_ATTR_ID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_ERROR_MESSAGE := 'No Contract found for PJM External Account Name = ' || p_EXTERNAL_ACCOUNT_NAME;
		END;

		RAISE_APPLICATION_ERROR(-20001, v_ERROR_MESSAGE);
END;
---------------------------------------------------------------------------------------------------

	/*
    13-Dec-2004, jbc: updated to use the external ID of the transaction rather than the
    TP contract number if we're in MarketManager (since we can't have different contracts)
  */
	FUNCTION GET_TRANSACTION_ID(p_CONTRACT_NUMBER IN VARCHAR2,
															p_SERVICE_DATE    IN DATE) RETURN NUMBER IS
		v_TX_ID      NUMBER;
		v_USE_EXT_ID BOOLEAN := FALSE;
	BEGIN
		v_USE_EXT_ID := NVL(MODEL_VALUE_AT_KEY(1,
								'Scheduling',
								'PJM Export',
								'Use External ID') = '1',
								FALSE);

		IF v_USE_EXT_ID = TRUE THEN
			SELECT MIN(TRANSACTION_ID)
				INTO v_TX_ID
				FROM INTERCHANGE_TRANSACTION ITX
			 WHERE p_SERVICE_DATE BETWEEN ITX.BEGIN_DATE AND
						 NVL(ITX.END_DATE, HIGH_DATE)
				 AND ITX.TRANSACTION_IDENTIFIER = p_CONTRACT_NUMBER;
		ELSE
			SELECT MIN(TRANSACTION_ID)
				INTO v_TX_ID
				FROM TP_CONTRACT_NUMBER A, INTERCHANGE_TRANSACTION B
			 WHERE p_SERVICE_DATE BETWEEN A.BEGIN_DATE AND NVL(A.END_DATE, HIGH_DATE)
				 AND A.CONTRACT_NUMBER = p_CONTRACT_NUMBER
				 AND B.CONTRACT_ID = A.CONTRACT_ID;
		END IF;

		IF v_TX_ID IS NULL THEN
			v_TX_ID := -1;
		END IF;

		RETURN v_TX_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN - 1;
	END GET_TRANSACTION_ID;

---------------------------------------------------------------------------------------------------

	FUNCTION GET_PSE(p_ORG_ID IN VARCHAR2, p_ORG_NAME IN VARCHAR2) RETURN NUMBER IS
		v_PSE_ID NUMBER := NULL;
	BEGIN
		IF NOT p_ORG_ID IS NULL THEN
			BEGIN
				SELECT PSE_ID
					INTO v_PSE_ID
					FROM PURCHASING_SELLING_ENTITY
				 WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) =
							 UPPER('PJM-' || TRUNC(p_ORG_ID, 0));
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_PSE_ID := NULL;
				WHEN TOO_MANY_ROWS THEN
					-- ??
					LOGS.LOG_WARN('More than one PSE for PJM found. Using the first one.');
					SELECT PSE_ID
						INTO v_PSE_ID
						FROM PURCHASING_SELLING_ENTITY
					 WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) =
								 UPPER('PJM-' || TRUNC(p_ORG_ID, 0))
						 AND ROWNUM = 1; -- just grab the first one
			END;
		END IF;
		IF v_PSE_ID IS NULL AND NOT p_ORG_NAME IS NULL THEN
			BEGIN
				SELECT PSE_ID
					INTO v_PSE_ID
					FROM PURCHASING_SELLING_ENTITY
				 WHERE UPPER(PSE_ALIAS) = UPPER('PJM: ' || TRIM(p_ORG_NAME));
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					BEGIN
						SELECT PSE_ID
							INTO v_PSE_ID
							FROM PURCHASING_SELLING_ENTITY
						 WHERE UPPER(REPLACE(PSE_ALIAS, ',', '')) =
									 UPPER('PJM: ' || TRIM(REPLACE(p_ORG_NAME, ',', '')));
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
							BEGIN
								-- schedule 9 and 10 summary replaces the comma in the name with a space
								SELECT PSE_ID
									INTO v_PSE_ID
									FROM PURCHASING_SELLING_ENTITY
								 WHERE UPPER(REPLACE(PSE_ALIAS, ',', ' ')) =
											 UPPER('PJM: ' || TRIM(REPLACE(p_ORG_NAME, ',', ' ')));
							EXCEPTION
								WHEN NO_DATA_FOUND THEN
									v_PSE_ID := NULL;
								WHEN TOO_MANY_ROWS THEN
									-- ??
									LOGS.LOG_WARN('More than one PSE for PJM found. Using the first one.');
									SELECT PSE_ID
										INTO v_PSE_ID
										FROM PURCHASING_SELLING_ENTITY
									 WHERE UPPER(REPLACE(PSE_ALIAS, ',', '')) =
												 UPPER('PJM: ' || TRIM(REPLACE(p_ORG_NAME, ',', '')))
										 AND ROWNUM = 1; -- just grab the first one
							END;
					END;
				WHEN TOO_MANY_ROWS THEN
					-- ??
					LOGS.LOG_WARN('More than one PSE for PJM found. Using the first one.');
					SELECT PSE_ID
						INTO v_PSE_ID
						FROM PURCHASING_SELLING_ENTITY
					 WHERE UPPER(PSE_ALIAS) = UPPER('PJM: ' || TRIM(p_ORG_NAME))
						 AND ROWNUM = 1; -- just grab the first one
			END;
		END IF;
		/* I'm not sure we want to return PJM if we can't find the PSE
    IF v_PSE_ID IS NULL THEN
      BEGIN
        SELECT PSE_ID INTO v_PSE_ID
        FROM PURCHASING_SELLING_ENTITY
        WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) = 'PJM';
      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          -- ??
              POST_TO_APP_EVENT_LOG('Admin','MM_PJM_UTIL','Retrieve PSE ID','WARNING','PROCESS',
                        NULL,NULL,'More than one PSE for PJM found. Using the first one.',
                        GB.g_OSUSER);
          SELECT PSE_ID INTO v_PSE_ID
          FROM PURCHASING_SELLING_ENTITY
          WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) = 'PJM'
                AND ROWNUM = 1; -- just grab the first one
      END;
    END IF;
    */
		RETURN v_PSE_ID;
	END GET_PSE;
	----------------------------------------------------------------------------------------------------
	FUNCTION GET_PSE(p_ISO_ACCOUNT_NAME IN VARCHAR2) RETURN NUMBER IS
		v_CONTRACT_ID NUMBER;
		v_PSE_ID NUMBER;
	BEGIN
		--If the contract cannot be found, this function will raise an application error.
		v_CONTRACT_ID := GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCOUNT_NAME);

		SELECT BILLING_ENTITY_ID
		INTO v_PSE_ID
		FROM INTERCHANGE_CONTRACT
		WHERE CONTRACT_ID = v_CONTRACT_ID;

		RETURN v_PSE_ID;
	END GET_PSE;
  ----------------------------------------------------------------------------------------------------
	FUNCTION GET_COMMODITY_ID
	(
	p_COMMODITY_NAME IN VARCHAR2
	) RETURN NUMBER IS
	v_COMMODITY_ID NUMBER(9);
	BEGIN
		ID.ID_FOR_COMMODITY(p_COMMODITY_NAME, FALSE, v_COMMODITY_ID);
		RETURN v_COMMODITY_ID;
	END GET_COMMODITY_ID;

----------------------------------------------------------------------------------------------------
FUNCTION CREATE_SERVICE_POINT
	(
	p_SERVICE_POINT_NAME IN VARCHAR2,
	p_EXTERNAL_IDENTIFIER IN VARCHAR2,
	p_NODE_TYPE IN VARCHAR2
	) RETURN NUMBER IS
	v_SP_ID NUMBER(9);
BEGIN

	ID.ID_FOR_SERVICE_POINT(p_SERVICE_POINT_NAME, FALSE, v_SP_ID);
	IF v_SP_ID <= 0 THEN
		IO.PUT_SERVICE_POINT(o_OID => v_SP_ID,
				 p_SERVICE_POINT_NAME      => p_SERVICE_POINT_NAME,
				 p_SERVICE_POINT_ALIAS     => p_SERVICE_POINT_NAME,
				 p_SERVICE_POINT_DESC      => 'Created by Market Manager via MM_PJM_UTIL',
				 p_SERVICE_POINT_ID        => 0,
				 p_SERVICE_POINT_TYPE      => 'Wholesale',
				 p_TP_ID                   => 0,
				 p_CA_ID                   => 0,
				 p_EDC_ID                  => 0,
				 p_ROLLUP_ID               => 0,
				 p_SERVICE_REGION_ID       => 0,
				 p_SERVICE_AREA_ID         => 0,
				 p_SERVICE_ZONE_ID         => 0,
				 p_TIME_ZONE               => 0,
				 p_LATITUDE                => NULL,
				 p_LONGITUDE               => NULL,
				 p_EXTERNAL_IDENTIFIER     => p_EXTERNAL_IDENTIFIER,
				 p_IS_INTERCONNECT         => 0,
				 p_NODE_TYPE               => p_NODE_TYPE,
				 p_SERVICE_POINT_NERC_CODE => NULL,
                 p_PIPELINE_ID             => NULL,
                 p_MILE_MARKER             => NULL);
		COMMIT;
	END IF;
	RETURN v_SP_ID;

END CREATE_SERVICE_POINT;
----------------------------------------------------------------------------------------------------
/*
	Given a Pnode ID, tries to create a service point based on this Pnode ID's row
	in the PJM_EMKT_PNODES table.
*/
FUNCTION ID_FOR_SERVICE_POINT_NAME
	(
	p_SERVICE_POINT_NAME IN VARCHAR2
	) RETURN NUMBER IS

	v_SERVICE_POINT_ID NUMBER(9);
	v_PEP_ROW PJM_EMKT_PNODES%ROWTYPE;
	v_NODENAME PJM_EMKT_PNODES.NODENAME%TYPE;
	v_IS_ZONE NUMBER(1) := 0;
BEGIN

	v_NODENAME := p_SERVICE_POINT_NAME;

	--Strip off the (PJM) at the end if there happens to be one there.
	IF SUBSTR(p_SERVICE_POINT_NAME, -5) = '(PJM)' THEN
		v_NODENAME := TRIM(SUBSTR(v_NODENAME, 1, LENGTH(v_NODENAME)-5));
	END IF;

	--Strip off the _ZONE at the end if there happens to be one there.
	IF SUBSTR(p_SERVICE_POINT_NAME, -5) = '_ZONE' THEN
		v_NODENAME := TRIM(SUBSTR(v_NODENAME, 1, LENGTH(v_NODENAME)-5));
		v_IS_ZONE := 1;
	END IF;

	--See if there is a different NODENAME for this node.
	v_NODENAME := NVL(GET_DICTIONARY_VALUE(v_NODENAME, 1, 'MarketExchange', 'PJM', 'Corrected NodeName'), v_NODENAME);

	SELECT P.SERVICE_POINT_ID
	INTO v_SERVICE_POINT_ID
	FROM SERVICE_POINT P, PJM_EMKT_PNODES PEP
	WHERE PEP.NODENAME = v_NODENAME
		AND P.EXTERNAL_IDENTIFIER = TO_CHAR(PEP.PNODEID)
		AND (v_IS_ZONE = 0 OR PEP.NODETYPE = 'Zone');

	RETURN v_SERVICE_POINT_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		BEGIN
			SELECT PEP.*
			INTO v_PEP_ROW
			FROM PJM_EMKT_PNODES PEP
			WHERE PEP.NODENAME = v_NODENAME;

			v_SERVICE_POINT_ID := CREATE_SERVICE_POINT(v_PEP_ROW.NODENAME, v_PEP_ROW.PNODEID, v_PEP_ROW.NODETYPE);
			RETURN v_SERVICE_POINT_ID;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
         -- can't find anything like this in the system; we're out of sync with PJM
				LOGS.LOG_WARN('NodeName ' || v_NODENAME || ' not found. Run the Query Node List action to update the node list.');
				RETURN NULL;
		END;

END ID_FOR_SERVICE_POINT_NAME;
----------------------------------------------------------------------------------------------------
/*
	Given a Pnode ID, tries to create a service point based on this Pnode ID's row
	in the PJM_EMKT_PNODES table.
*/
FUNCTION ID_FOR_SERVICE_POINT_PNODE
	(
	p_PNODE_IDENT IN VARCHAR2
	) RETURN NUMBER IS

	v_PEP_ROW PJM_EMKT_PNODES%ROWTYPE;
	v_SERVICE_POINT_ID NUMBER(9);
	v_COUNT NUMBER;
BEGIN
	-- is there a service point already in the SERVICE_POINT table?
	SELECT P.SERVICE_POINT_ID
	INTO v_SERVICE_POINT_ID
	FROM SERVICE_POINT P
	WHERE P.EXTERNAL_IDENTIFIER = p_PNODE_IDENT;

	RETURN v_SERVICE_POINT_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		-- try to find a definition in the PJM_EMKT_NODES table, and create
		-- a service point based on this definition
		BEGIN

			SELECT PEP.*
			INTO v_PEP_ROW
			FROM PJM_EMKT_PNODES PEP
			WHERE PEP.PNODEID = TO_NUMBER(p_PNODE_IDENT);

			-- See if a Service Point already exists with this name, but the wrong external id.
			SELECT COUNT(*)
			INTO v_COUNT
			FROM SERVICE_POINT
			WHERE SERVICE_POINT_NAME = v_PEP_ROW.NODENAME;

				-- If it does exist by that name, but the wrong external id, then
                -- append (PJM) to the name so that we are not trying to overwrite
                -- a MISO Service Point (and failing with a Duplicate Entity error).
				IF v_COUNT > 0 THEN
                    v_PEP_ROW.NODENAME := v_PEP_ROW.NODENAME || ' (PJM)';
				END IF;

				v_SERVICE_POINT_ID := CREATE_SERVICE_POINT(v_PEP_ROW.NODENAME, p_PNODE_IDENT, v_PEP_ROW.NODETYPE);
				RETURN v_SERVICE_POINT_ID;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
          -- can't find anything like this in the system; we're out of sync with PJM
					LOGS.LOG_WARN('Pnode ' || p_PNODE_IDENT || ' not found. Run the Query Node List action to update the node list.');
					RETURN NULL;
		END;
END ID_FOR_SERVICE_POINT_PNODE;

FUNCTION GET_COMMIT_STATUS_RES_TRAIT RETURN NUMBER IS
BEGIN
     RETURN g_TG_UPD_COMMIT_STATUS;
END GET_COMMIT_STATUS_RES_TRAIT;

FUNCTION GET_ACTIVE_SCHEDULE_RES_TRAIT RETURN NUMBER IS
BEGIN
     RETURN g_TG_MR_ACTIVE_SCHEDULE;
END GET_ACTIVE_SCHEDULE_RES_TRAIT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_POINT_OWNERSHIP
	(
	p_SERVICE_POINT_ID IN NUMBER,
	p_CONTRACT_ID IN NUMBER,
	p_DATE IN DATE,
	p_OWNERSHIP_PERCENT OUT NUMBER,
	p_IS_SCHEDULER OUT NUMBER
	) AS
BEGIN
	SELECT OWNERSHIP_PERCENT, IS_SCHEDULER
	INTO p_OWNERSHIP_PERCENT, p_IS_SCHEDULER
	FROM PJM_SERVICE_POINT_OWNERSHIP
	WHERE SERVICE_POINT_ID = p_SERVICE_POINT_ID
		AND CONTRACT_ID = p_CONTRACT_ID
		AND p_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, p_DATE);
EXCEPTION
	--If there is no record, assume full ownership.
	WHEN NO_DATA_FOUND THEN
		p_OWNERSHIP_PERCENT := 100;
		p_IS_SCHEDULER := 1;
END GET_SERVICE_POINT_OWNERSHIP;
---------------------------------------------------------------------------------------------------
FUNCTION GET_SERVICE_POINT_OWNERSHIP
	(
	p_TRANSACTION_ID IN NUMBER,
	p_DATE IN DATE
	) RETURN NUMBER IS
	v_POD_ID NUMBER(9);
	v_CONTRACT_ID NUMBER(9);
	v_IS_SCHEDULER NUMBER(1);
	v_OWNERSHIP_PERCENT NUMBER;
BEGIN
	SELECT POD_ID, CONTRACT_ID INTO v_POD_ID, v_CONTRACT_ID FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	GET_SERVICE_POINT_OWNERSHIP(v_POD_ID, v_CONTRACT_ID, p_DATE, v_OWNERSHIP_PERCENT, v_IS_SCHEDULER);

	RETURN v_OWNERSHIP_PERCENT;
END GET_SERVICE_POINT_OWNERSHIP;
---------------------------------------------------------------------------------------------------
FUNCTION GET_STATUS_MESSAGE
	(
	p_REC IN t_STATUS,
	p_VERB_SUCCESS IN VARCHAR2 := 'processed',
	p_PLURAL_NOUN IN VARCHAR2 := 'schedules'
	) RETURN VARCHAR2 IS
	v_MESSAGE VARCHAR2(2000);
BEGIN
	v_MESSAGE := (p_REC.SUCCEEDED+p_REC.REJECTED+p_REC.ERROR)||' total ' || p_PLURAL_NOUN || UTL_TCP.CRLF||
	p_REC.SUCCEEDED || ' successfully ' || p_VERB_SUCCESS;

	IF p_REC.REJECTED + p_REC.ERROR > 0 THEN
		v_MESSAGE := v_MESSAGE || UTL_TCP.CRLF ||
		(p_REC.REJECTED+p_REC.ERROR) || ' failed (See Exchange Log for details.)';
	END IF;

	RETURN v_MESSAGE;

END GET_STATUS_MESSAGE;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_CURRENT_TIME_ZONE
    (
    p_DATE IN DATE,
    p_TIME_ZONE OUT VARCHAR2
    ) AS
BEGIN

    IF p_DATE >= DST_SPRING_AHEAD_DATE(p_DATE) AND p_DATE <= DST_FALL_BACK_DATE(p_DATE) THEN
        p_TIME_ZONE := 'EDT';
    ELSE
        p_TIME_ZONE := 'EST';
    END IF;

END GET_CURRENT_TIME_ZONE;
-----------------------------------------------------------------------------------------------------
PROCEDURE ADD_PRICE_TO_GEN_SCHED
    (
    p_SCHEDULE_DATE IN DATE,
    P_MARKET_TYPE IN VARCHAR2,
    p_EXTERNAL_ID IN VARCHAR2,
    p_PRICE IN NUMBER,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
v_SERVICE_POINT_ID SERVICE_POINT.SERVICE_POINT_ID%TYPE;
v_SC_ID SC.SC_ID%TYPE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
CURSOR C_TRANSACTION_IDS IS
    SELECT TRANSACTION_ID
    FROM INTERCHANGE_TRANSACTION
    WHERE TRANSACTION_TYPE = 'Generation'
    AND COMMODITY_ID = v_COMMODITY_ID
    AND POD_ID = v_SERVICE_POINT_ID
    AND SC_ID = v_SC_ID
    AND END_DATE >= TRUNC(p_SCHEDULE_DATE);

BEGIN

    p_STATUS := GA.SUCCESS;
    
    SELECT SERVICE_POINT_ID
    INTO v_SERVICE_POINT_ID
    FROM SERVICE_POINT
    WHERE EXTERNAL_IDENTIFIER = p_EXTERNAL_ID;
    
    v_SC_ID := ID.ID_FOR_SC('PJM');
    IF P_MARKET_TYPE = 'DayAhead' THEN
        ID.ID_FOR_COMMODITY('DayAhead Energy', FALSE, v_COMMODITY_ID);
    ELSE
        ID.ID_FOR_COMMODITY('RealTime Energy', FALSE, v_COMMODITY_ID);
    END IF;        
    
    FOR v_TRANSACTION_ID IN C_TRANSACTION_IDS LOOP
         
        UPDATE IT_SCHEDULE SET			
			PRICE = NVL(p_PRICE, PRICE)
		WHERE TRANSACTION_ID = v_TRANSACTION_ID.Transaction_Id
			AND SCHEDULE_TYPE = 1 --FORECAST
			AND SCHEDULE_STATE = GA.INTERNAL_STATE
			AND SCHEDULE_DATE = p_SCHEDULE_DATE;			
		IF SQL%NOTFOUND THEN
			INSERT INTO IT_SCHEDULE (
				TRANSACTION_ID,
				SCHEDULE_TYPE,
				SCHEDULE_STATE,
				SCHEDULE_DATE,
				AS_OF_DATE,
				AMOUNT,
				PRICE)
			VALUES (
				v_TRANSACTION_ID.Transaction_Id,
				1, --FORECAST
				GA.INTERNAL_STATE,
				p_SCHEDULE_DATE,
				LOW_DATE, 
				0,
				p_PRICE);
		END IF;  
    
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS := SQLCODE;
        p_MESSAGE := SQLERRM;
END ADD_PRICE_TO_GEN_SCHED;
-----------------------------------------------------------------------------------------------------------    
BEGIN
	-- 11-mar-2009, jbc: PJM SC should get created as part of SetupMarket
	--ID.ID_FOR_SC('PJM', TRUE, g_PJM_SC_ID);

	BEGIN
		FOR v_ARRAY_INDEX IN 1 .. g_STATEMENT_TYPE_ARRAY.COUNT LOOP
			g_STATEMENT_TYPE_ID_ARRAY.EXTEND();
			BEGIN
				SELECT S.STATEMENT_TYPE_ID
					INTO g_STATEMENT_TYPE_ID_ARRAY(v_ARRAY_INDEX)
					FROM STATEMENT_TYPE S
				 WHERE S.STATEMENT_TYPE_NAME LIKE g_STATEMENT_TYPE_ARRAY(v_ARRAY_INDEX) || '%';
			EXCEPTION WHEN NO_DATA_FOUND THEN
				LOGS.LOG_ERROR('MM_PJM_UTIL pkg init can''t find statement ' || g_STATEMENT_TYPE_ARRAY(v_ARRAY_INDEX));
			END;
		END LOOP;
	EXCEPTION WHEN OTHERS THEN
		LOGS.LOG_ERROR(p_EVENT_TEXT => 'Error in MM_PJM_UTIL pkg initialization!', p_SQLERRM => UT.GET_FULL_ERRM);
	END;
END MM_PJM_UTIL;
/
