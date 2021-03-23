DECLARE
	PROCEDURE INSERT_MESSAGE_DEFINITION
		(
		p_MESSAGE_CODE IN VARCHAR2,
		p_TEXT IN VARCHAR2,
		p_IDENTIFIER IN VARCHAR2,
		p_DESCRIPTION IN VARCHAR2 := NULL,
		p_SOLUTION IN VARCHAR2 := NULL
		) AS
		v_MESSAGE_ID NUMBER;
		v_MESSAGE_IDENT MESSAGE_DEFINITION.MESSAGE_IDENT%TYPE;
		v_MESSAGE_TYPE MESSAGE_DEFINITION.MESSAGE_TYPE%TYPE;
		v_MESSAGE_NUMBER MESSAGE_DEFINITION.MESSAGE_NUMBER%TYPE;
	BEGIN
		--The Message Code is <Type>-<Number>, so find tokens by "-" character.
		v_MESSAGE_TYPE := REGEXP_SUBSTR(p_MESSAGE_CODE, '[^-]+', 1, 1);
		v_MESSAGE_NUMBER := TO_NUMBER(REGEXP_SUBSTR(p_MESSAGE_CODE, '[^-]+', 1, 2));
	
		--See if this message definition exists.
		SELECT MAX(MESSAGE_ID), MAX(MESSAGE_IDENT)
		INTO v_MESSAGE_ID, v_MESSAGE_IDENT
		FROM MESSAGE_DEFINITION
		WHERE MESSAGE_TYPE = v_MESSAGE_TYPE
			AND MESSAGE_NUMBER = v_MESSAGE_NUMBER;
			
		--Insert the definition if it does not already exist.
		IF v_MESSAGE_IDENT IS NULL THEN
			SELECT OID.NEXTVAL INTO v_MESSAGE_ID FROM DUAL;
			INSERT INTO MESSAGE_DEFINITION(
				MESSAGE_ID, 
				MESSAGE_TYPE, 
				MESSAGE_NUMBER, 
				MESSAGE_TEXT, 
				MESSAGE_DESC, 
				MESSAGE_SOLUTION, 
				MESSAGE_IDENT)
			VALUES (
				v_MESSAGE_ID,
				v_MESSAGE_TYPE,
				v_MESSAGE_NUMBER,
				p_TEXT,
				p_DESCRIPTION,
				p_SOLUTION,
				p_IDENTIFIER);
		ELSIF v_MESSAGE_IDENT <> p_IDENTIFIER THEN
			-- changed the identifier name? then this is a different exception,
			-- and we need to update the definition and also clear references
			UPDATE MESSAGE_DEFINITION SET
				MESSAGE_TEXT = p_TEXT,
				MESSAGE_DESC = p_DESCRIPTION,
				MESSAGE_SOLUTION = p_SOLUTION,
				MESSAGE_IDENT = p_IDENTIFIER
			WHERE MESSAGE_ID = v_MESSAGE_ID;
			-- clear refs
			UPDATE PROCESS_LOG_EVENT SET MESSAGE_ID = NULL WHERE MESSAGE_ID = v_MESSAGE_ID;
			UPDATE PROCESS_LOG_TRACE SET MESSAGE_ID = NULL WHERE MESSAGE_ID = v_MESSAGE_ID;

		-- else - do nothing. keep any customizations to message text, description, and solution
		END IF;
	END INSERT_MESSAGE_DEFINITION;
BEGIN
	-- the following text can be generated using this query:
/*
SELECT CHR(9)||'INSERT_MESSAGE_DEFINITION('||
	UT.GET_LITERAL_FOR_STRING(TRIM(MESSAGE_TYPE)||'-'||
		-- generate numbers that start from 0 (or 20,000 for ORA message type) instead of using current numbers which
		-- if entered through UI start at 99,999 (or 20,999 for ORA message type)
		TO_CHAR(COUNT(1) OVER (PARTITION BY MESSAGE_TYPE ORDER BY MESSAGE_NUMBER)-1+CASE WHEN MESSAGE_TYPE='ORA' THEN 20000 ELSE 0 END,'FM00009'))||', '||
	UT.GET_LITERAL_FOR_STRING(MESSAGE_TEXT)||', '||
	UT.GET_LITERAL_FOR_STRING(MESSAGE_IDENT)||
	CASE WHEN MESSAGE_DESC IS NULL AND MESSAGE_SOLUTION IS NULL THEN
			NULL
		 WHEN MESSAGE_SOLUTION IS NULL THEN
		 	', '||UT.GET_LITERAL_FOR_STRING(MESSAGE_DESC)
		 ELSE
		 	', '||UT.GET_LITERAL_FOR_STRING(MESSAGE_DESC)||', '||UT.GET_LITERAL_FOR_STRING(MESSAGE_SOLUTION)
		END||');'
FROM MESSAGE_DEFINITION
ORDER BY MESSAGE_TYPE, MESSAGE_NUMBER;
*/

	INSERT_MESSAGE_DEFINITION('ORA-20000', 'General Exception', 'ERR_GENERAL');
	INSERT_MESSAGE_DEFINITION('ORA-20001', 'Assertion Failed', 'ERR_ASSERT', 'A required condition has not been met.');
	INSERT_MESSAGE_DEFINITION('ORA-20002', 'Insufficient Privileges', 'ERR_PRIVILEGES', 'You do not have appropriate privileges to perform this action.', 'Request the specified privilege from an Administrator.');
	INSERT_MESSAGE_DEFINITION('ORA-20003', 'Entry Already Exists', 'ERR_DUP_ENTRY', 'An identical entry already exists, and duplicates are not allowed.');
	INSERT_MESSAGE_DEFINITION('ORA-20004', 'No Such Entry', 'ERR_NO_SUCH_ENTRY', 'No entry in the database meets the specified criteria.');
	INSERT_MESSAGE_DEFINITION('ORA-20005', 'Too Many Matching Entries', 'ERR_TOO_MANY_ENTRIES', 'More than one entry in the database meets the specified criteria when only one was expected.');
	INSERT_MESSAGE_DEFINITION('ORA-20006', 'Invalid or Missing Argument', 'ERR_ARGUMENT');
	INSERT_MESSAGE_DEFINITION('ORA-20007', 'Invalid Date Specification', 'ERR_INVALID_DATE');
	INSERT_MESSAGE_DEFINITION('ORA-20008', 'Invalid Date Range', 'ERR_DATE_RANGE');
	INSERT_MESSAGE_DEFINITION('ORA-20009', 'Data Is Locked', 'ERR_DATA_LOCKED');
	INSERT_MESSAGE_DEFINITION('ORA-20010', 'Invoice Is Closed', 'ERR_INVOICE_CLOSED');
	INSERT_MESSAGE_DEFINITION('ORA-20011', 'User Requested Process Termination', 'ERR_CANCELLED', 'A user has cancelled this process and requested that it terminate.');
	INSERT_MESSAGE_DEFINITION('ORA-20012', 'Overlapping Dates Not Allowed', 'ERR_DATES_OVERLAP');
	INSERT_MESSAGE_DEFINITION('ORA-20013', 'Circular Reference', 'ERR_CIRC_REF', 'A Charge Component with a ''Combination'' Rate Structure indirectly references itself.', 'Reconfigure the component so that there is no cycle in the component references.');
	INSERT_MESSAGE_DEFINITION('ORA-20014', 'Cannot Change Current Privileges', 'ERR_ALTER_PRIVS', 'The specified action could materially alter your current privileges. This is not allowed.');
	INSERT_MESSAGE_DEFINITION('ORA-20015', 'Cannot Delete Current User', 'ERR_DELETE_CURRENT', 'An attempt was made to remove the current user from the database. This is not allowed.');
	INSERT_MESSAGE_DEFINITION('ORA-20016', 'Cannot Delete Super-User Role', 'ERR_DELETE_SUPERUSER', 'An attempt was made to remove the ''Super-User'' role from the database. This is not allowed.');
	INSERT_MESSAGE_DEFINITION('ORA-20017', 'Row Cannot Be Edited', 'ERR_ROW_NOT_EDITABLE');
	INSERT_MESSAGE_DEFINITION('ORA-20018', 'No Sender Address Specified', 'ERR_NO_SENDER');
	INSERT_MESSAGE_DEFINITION('ORA-20019', 'No Recipient Address Specified', 'ERR_NO_RECIPIENTS');
	INSERT_MESSAGE_DEFINITION('ORA-20020', 'Business Rule Violation', 'ERR_BUS_RULE', 'Input data does not comply with business or validation rules.');
	INSERT_MESSAGE_DEFINITION('ORA-20021', 'Run-Away Loop', 'ERR_RUNAWAY_LOOP', 'A logic error has occurred that has resulted in a potential infinite loop.');
	INSERT_MESSAGE_DEFINITION('ORA-20022', 'Process Died', 'ERR_PROCESS_DIED', 'A Calculation Component has indicated that the calculation process should abort.');
	INSERT_MESSAGE_DEFINITION('ORA-20023', 'Statement Type Required', 'ERR_NO_STATEMENT_TYPE', 'A Formula Input or Result definition is trying to query or record a schedule value, but no statement type has been specified.', 'The Calculation Process entry may need to be defined as Statement Type Specific. Alternatively, define a global or other value named '':statement_type'' that indicates the statement type from/to which schedule values should be queried/recorded.');
	INSERT_MESSAGE_DEFINITION('ORA-20024', 'Could Not Start Process', 'ERR_COULD_NOT_START_PROCESS', 'An error occurred while creating a new process entry.');
	INSERT_MESSAGE_DEFINITION('ORA-20025', 'Cannot Modify Super-User Assignments', 'ERR_MODIFY_SUPERUSER', 'Only a Super-User can grant or revoke the Super-User role. Only a Super-User can delete other Super-Users.');
	INSERT_MESSAGE_DEFINITION('ORA-20026', 'Cannot Open Multiple Imports', 'ERR_SO_IMP_OPEN_CONFLICT', 'There is already an open import for this schema; you cannot have two open imports at the same time.');
	INSERT_MESSAGE_DEFINITION('ORA-20027', 'Operation Not Allowed: Import Closed', 'ERR_SO_IMP_CLOSED', 'This import is closed.  You cannot change a closed import; please open it and try again.');
	INSERT_MESSAGE_DEFINITION('ORA-20028', 'Operation Not Allowed: Import Open', 'ERR_SO_IMP_OPEN', 'This import is open. You cannot purge an open import; please close it and then try again.');
	INSERT_MESSAGE_DEFINITION('ORA-20029', 'DBMS_LOCK Not Available', 'ERR_NO_DBMS_LOCK', 'An attempt was made to access the DBMS_LOCK package, but the user does not have access to it.', 'Have a DBA grant an Oracle EXECUTE privilege on the SYS.DBMS_LOCK package, or disable locking.');
	INSERT_MESSAGE_DEFINITION('ORA-20030', 'Lock Wait Timeout', 'ERR_LOCK_WAIT_TIME_OUT');
	INSERT_MESSAGE_DEFINITION('ORA-20031', 'Failed to Acquire Lock', 'ERR_FAILED_TO_ACQUIRE_LOCK');
	INSERT_MESSAGE_DEFINITION('ORA-20032', 'Failed to Release Lock', 'ERR_FAILED_TO_RELEASE_LOCK');
	INSERT_MESSAGE_DEFINITION('ORA-20033', 'System-Date-Time Table Not Populated', 'ERR_MISSING_SYSTEM_DATE_TIME', 'The table named SYSTEM_DATE_TIME has not been populated for the requested time zone and date range', 'Try changing your query to use a different time zone or date range, or have a System Administrator populate the SYSTEM_DATE_TABLE for the specified time zone and date range');
	INSERT_MESSAGE_DEFINITION('ORA-20034', 'Configuration Import Cannot Be Purged', 'ERR_CANNOT_PURGE_CONFIG_IMP', 'The most recent Product Script configuration import cannot be purged.');
	INSERT_MESSAGE_DEFINITION('ORA-20035', 'Insufficient Privileges for Audit Setup', 'ERR_AUDIT_PRIVS', 'An attempt was made to create the Audit table but the user has not been granted the proper database privileges.', 'Have a DBA grant the following Oracle privileges to the schema: CREATE TABLE, CREATE TRIGGER, and CREATE PROCEDURE.');
	INSERT_MESSAGE_DEFINITION('ORA-20036', 'Cannot Modify System Users', 'ERR_MODIFY_SYSTEM_USER', 'Only a Super-User can create, modify, or delete System Users.');
	INSERT_MESSAGE_DEFINITION('ORA-20037', 'No Breakpoints Defined', 'ERR_NO_BREAKPOINT', 'No WRF Breakpoints have been defined for the specified Season Day Type', 'Define the breakpoint values to use for the specifed Season Day Type and try again');
	INSERT_MESSAGE_DEFINITION('ORA-20038', 'No Weather Parameters Defined', 'ERR_NO_WEATHER_PARMS', 'No Weather Parameters have been defined for WRF calculations for the specified Season Day Type', 'Define the weather parameters to use for the specifed Season Day Type and try again');
	INSERT_MESSAGE_DEFINITION('ORA-20039', 'Missing Credentials', 'ERR_NO_CREDENTIALS', 'An external system requires credentials that are not currently defined', 'Verify that credentials have been uploaded for the external system and external account. If the external system requires a username and password, verify that they have been defined are not blank. If the external system requires any certificates, verify that certificates have been uploaded');
	INSERT_MESSAGE_DEFINITION('ORA-20040', 'No Session Manager', 'ERR_NO_SESSION_MGR', 'The SESSION_MGR package or synonym does not exist.', 'Have a DBA create the SESSION_MGR package or synonym.');
	INSERT_MESSAGE_DEFINITION('ORA-20041', 'Invalid Session', 'ERR_INVALID_SESSION', 'An attempt was made to kill a session that cannot be killed: the session was not an application session or it is an application session that belongs to another schema.');
	INSERT_MESSAGE_DEFINITION('ORA-20042', 'ALTER SYSTEM Privilege Required', 'ERR_NO_ALTER_SYS_PRIVS', 'The Session Management Schema does not have the appropriate privileges to kill a session.', 'Have a DBA grant the following Oracle privileges to the Session Management Schema: ALTER SYSTEM.');
	INSERT_MESSAGE_DEFINITION('ORA-20043', 'Cannot Disable Self', 'ERR_CANNOT_DISABLE_SELF', 'An attempt was made to disable the current user.  This is not allowed.');
	INSERT_MESSAGE_DEFINITION('ORA-20044', 'Cannot Acknowledge Alert', 'ERR_CANNOT_ACK_ALERT', 'Users are not allowed to acknowledge alerts which they did not receive.  You must belong to a role associated with the alert.');
	INSERT_MESSAGE_DEFINITION('ORA-20045', 'Cannot Delete Entity', 'ERR_CANNOT_DELETE_ENTITY', 'An entity could not be deleted from the system. Either the entity to be deleted was a reserved system entity (which cannot be deleted) or the entity is still referenced.', 'If the entity could not be deleted due to being referenced, remove references to the entity and try again.');
	INSERT_MESSAGE_DEFINITION('ORA-20046', 'Invalid Reactor Procedure', 'ERR_INVALID_REACTOR_PROC');
	INSERT_MESSAGE_DEFINITION('ORA-20047', 'Cannot Enumerate Column Values', 'ERR_CANNOT_ENUM_COL_VALS', 'An attempt was made to lock data with incomplete criteria. Values for missing criteria column could not be enumerated.', 'A system administrator should configure enumeration via the System Dictionary.');
	INSERT_MESSAGE_DEFINITION('ORA-20048', 'Cannot Find Delete Procedure', 'ERR_CANNOT_FIND_DEL_PROC', 'An attempt was made to find a delete procedure based on the ENTITY_TYPE field, but one was not found.', 'Check that the ENTITY_TYPE field is a valid entity domain table alias.');
	INSERT_MESSAGE_DEFINITION('ORA-20049', 'Data Import Error', 'ERR_DATA_IMPORT', 'The data import encountered a fatal error.', 'Review the logs to find the problems with the import file.');
	INSERT_MESSAGE_DEFINITION('ORA-20050', 'Cannot Find Jump Here Action', 'ERR_JUMP_ACTION', 'The application could find the target IO Table, but it did not have the Jump Here action.', 'A system administrator should create a Jump Here navigation action for the IO Table, either as a child of the report or the IO table.');
	INSERT_MESSAGE_DEFINITION('ORA-20051', 'Cannot Find Target IO Table', 'ERR_TARGET_IO_TABLE', 'The application could find not find the target IO Table.', 'A system administrator should create a the IO Table.');
	INSERT_MESSAGE_DEFINITION('ORA-20052', 'Cannot Delete Entity Still In Use', 'ERR_CHILD_TABLE', 'The entity could not be deleted becuase it is still in use by another entity.', 'Find the reference to this entity and remove or change it.');
	INSERT_MESSAGE_DEFINITION('ORA-20053', 'Auditing Not Enabled', 'ERR_AUDIT_ENABLED', 'Auditing is not enabled on the given System Table.', 'A system administrator should enable auditing on the System Table.');
	INSERT_MESSAGE_DEFINITION('ORA-20054', 'Cannot Modify Program Limit With Results', 'ERR_CANNOT_MODIFY_PROG_LIMIT', 'Once a Program Limit has associated Event Results, its Execution Period, Template, and Period cannot be modified.', 'A possible solution is to delete the Program Limit and create a new one.');
	INSERT_MESSAGE_DEFINITION('ORA-20055', 'Unable to send message', 'ERR_MEX_SEND_MESSAGE', 'Unable to send a message to an external system.', 'This could be caused by incorrect credentials defined for the external system or misconfiguration of the end point in the MEX Switchboard.');
	INSERT_MESSAGE_DEFINITION('ORA-20056', 'Cannot Orphan an Entity', 'ERR_CANNOT_ORPHAN_ENTITY', 'Entities that can only be referenced using a relationship to another entity cannot have their last relationship to the referencing entity deleted.');
	INSERT_MESSAGE_DEFINITION('ORA-20057', 'Cannot Orphan Resource Enrollment', 'ERR_CANNOT_ORPHAN_ENROLLMENT', 'Changes that result in a Resource being enrolled in a Program which isn''t available at the Resource''s Service Location cannot be made.');
	INSERT_MESSAGE_DEFINITION('ORA-20058', 'Program Component Invalid', 'ERR_INVALID_PROG_COMP', 'The given Smart Grid Program has a missing or invalid charge component.', 'The Program''s component must be changed.');
	INSERT_MESSAGE_DEFINITION('ORA-20059', 'Conflicting DR Event', 'ERR_CONFLICT_DR_EVENT', 'There is already a DR Event that starts at the same time with the same VPP.');
	INSERT_MESSAGE_DEFINITION('ORA-20060', 'Missing MPRN', 'ERR_MISSING_MPRN', 'The data import could not be processed because the MPRN does not exist in system.');
	INSERT_MESSAGE_DEFINITION('ORA-20061', 'Missing Serial Number', 'ERR_MISSING_SERIAL_NUMBER', 'The data import could not be processed because the Serial Number does not exist in the system');
	INSERT_MESSAGE_DEFINITION('ORA-20062', 'Missing NQH Static Data', 'ERR_MISSING_NQH_STATIC_DATA', 'The data import could not be processed because the static data is missing.');
	INSERT_MESSAGE_DEFINITION('ORA-20063', 'Template Dates Not Populated', 'ERR_MISSING_TEMPLATE_DATES', 'The table named TEMPLATE_DATES has not been populated for the requested time zone and date range.', 'Try changing your query to use a different time zone or date range, or have a System Administrator populate the TEMPLATE_DATES table for the specified time zone and date range');
	INSERT_MESSAGE_DEFINITION('ORA-20064', 'Crystal Reports SDK Missing', 'ERR_CRYSTAL_SDK_MISSING', 'The Crystal Reports SDK has not been installed in this schema.', 'The System Administrator must install the Crystal Reports SDK before Server-Side Crystal Reports functionality can be used.');
	INSERT_MESSAGE_DEFINITION('ORA-20065', 'Missing Time Zone Offset', 'ERR_MISSING_TZ_OFFSET', 'The Time Zone Offset cannot be determined for the requested time zone.', 'Have a DBA populate the SYSTEM_TIME_ZONE table with the appropriate offset for the requested Time Zone.');
	INSERT_MESSAGE_DEFINITION('ORA-20066', 'Invalid File Type', 'ERR_INVALID_FILE_TYPE', 'The file being loaded does not match the format for the specified file type.', 'Select a different file type and reload the file.');
	INSERT_MESSAGE_DEFINITION('ORA-20067', 'Invalid Number', 'ERR_INVALID_NUMBER', 'Unable to convert the string character set to a numeric value.');
	INSERT_MESSAGE_DEFINITION('ORA-20068', 'Invalid Charge Component', 'ERR_INVALID_CHARGE', 'A determinant accessor is not available. In the current context, only the following types of charge components can be used: components with a Formula rate structure that do not reference the accessor and components with a Service charge type that do not have a TOU Template assigned.');
  	INSERT_MESSAGE_DEFINITION('ORA-20069', 'Day Type Template', 'ERR_DAY_TYPE_TEMPLATE', 'A Day Type Template is assigned in a context reserved for TOU Templates; please update relevant entity definitions and try again.');
	INSERT_MESSAGE_DEFINITION('ORA-20070', 'Missing Profile Data', 'ERR_MISSING_PROFILE_DATA', 'The assigned Historical Profile does not have current set of data.');
	INSERT_MESSAGE_DEFINITION('ORA-20071', 'Unsupported Operation', 'ERR_UNSUPPORTED_OPERATION', 'This method or operation is not supported in this implementation.');
	INSERT_MESSAGE_DEFINITION('ORA-20072', 'Invalid or Missing Return Value', 'ERR_RETURN_VALUE', 'Return value for this operation is either invalid or missing.');
	INSERT_MESSAGE_DEFINITION('TDIE-00001', 'Estimated Usage Factor Not Imported', 'TDIE_EST_USAGE_FACT_NOT_IMP', 'Specified meter is not active during the effective date range of the estimated usage factor.', 'Confirm end date on meter. If necessary, extend the end date and reprocess the message.');

	COMMIT;
END;
/
