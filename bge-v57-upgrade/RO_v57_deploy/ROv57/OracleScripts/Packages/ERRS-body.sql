CREATE OR REPLACE PACKAGE BODY ERRS AS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
-- Function used to determine whether a message code is in the appropriate ORA-XXXXX format.
FUNCTION IS_VALID_ORA_CODE
	(
	p_MSGCODE IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	RETURN REGEXP_LIKE(p_MSGCODE,'^ORA-[0-9]{5}$');
END IS_VALID_ORA_CODE;
----------------------------------------------------------------------------------------------------
-- Function used to determine whether a message code is in the MMMMMM-XXXXX format.
FUNCTION IS_VALID_MSGCODE
	(
	p_MSGCODE IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	RETURN REGEXP_LIKE(p_MSGCODE,'^[A-Z]{3,6}-[0-9]{5}$');
END IS_VALID_MSGCODE;
----------------------------------------------------------------------------------------------------
FUNCTION STRIP_CODE_FROM_SQLERRM
	(
	p_SQLERRM IN VARCHAR2
	) RETURN VARCHAR2 IS

	v_FIRST_TOKEN VARCHAR2(32);

BEGIN
	v_FIRST_TOKEN := SUBSTR(TRIM(REGEXP_SUBSTR(p_SQLERRM, '[^:]+', 1, 1)),1,32);
	-- does message begin with an ORA message code? If so, remove it
	IF IS_VALID_ORA_CODE(v_FIRST_TOKEN) THEN
		RETURN SUBSTR(p_SQLERRM,LENGTH(v_FIRST_TOKEN)+3);
	ELSE
		RETURN p_SQLERRM;
	END IF;
END STRIP_CODE_FROM_SQLERRM;
----------------------------------------------------------------------------------------------------
-- Used to re-raise exceptions for the specified SQLCODE and SQLERRM
PROCEDURE RERAISE
	(
	p_SQLCODE IN PLS_INTEGER,
	p_SQLERRM IN VARCHAR2
	) AS
BEGIN
	-- Application errors:
	IF p_SQLCODE BETWEEN -20999 AND -20000 THEN
		RAISE_APPLICATION_ERROR(p_SQLCODE, STRIP_CODE_FROM_SQLERRM(p_SQLERRM), TRUE);
	-- EXCEPTION_INIT -1403 is disallowed:
	ELSIF p_SQLCODE IN (100, -1403) THEN
		RAISE NO_DATA_FOUND;
	-- Invalid err numbers:
	ELSIF p_SQLCODE > 0 AND p_SQLCODE != 100 THEN
		RAISE_APPLICATION_ERROR(-20000, p_SQLERRM, TRUE);
	-- Re-raise any other exception:
	ELSIF p_SQLCODE != 0 THEN
		EXECUTE IMMEDIATE '   DECLARE x_CEPTION EXCEPTION; ' ||
							'   PRAGMA EXCEPTION_INIT (x_CEPTION, ' ||
							TO_CHAR(p_SQLCODE) || ');' ||
							'   BEGIN  RAISE x_CEPTION; END;';
	END IF;
END RERAISE;
----------------------------------------------------------------------------------------------------
-- Parse the SQLERRM and return the embedded message code
FUNCTION GET_MESSAGE_CODE
	(
	p_SQLERRM IN VARCHAR2
	) RETURN VARCHAR2 IS
	v_FIRST_TOKEN VARCHAR2(32);
	v_SECOND_TOKEN VARCHAR2(32);
	v_MESSAGE_CODE VARCHAR2(32);
BEGIN
	--p_SQLERRM will be in one of the following formats:
	-- ORA-XXXXXX: Custom Message Text: Extra Message
	-- ORA-20000: MMMMMM-XXXXX: Custom Message Text: Extra Message
	--We want to return something other than ORA-20000 if we can.

	--Get the first and second colon delimited token.
	v_FIRST_TOKEN := SUBSTR(TRIM(REGEXP_SUBSTR(p_SQLERRM, '[^:]+', 1, 1)),1,32);
	v_SECOND_TOKEN := SUBSTR(TRIM(REGEXP_SUBSTR(p_SQLERRM, '[^:]+', 1, 2)),1,32);
	
	--If the first code is ORA-20000 then return the second code if it is valid.
	IF v_FIRST_TOKEN = MSGCODES.c_ERR_GENERAL AND IS_VALID_MSGCODE(v_SECOND_TOKEN) THEN
		v_MESSAGE_CODE := v_SECOND_TOKEN;
	--Otherwise, return the first code if it is valid.
	ELSIF IS_VALID_ORA_CODE(v_FIRST_TOKEN) THEN
		v_MESSAGE_CODE := v_FIRST_TOKEN;
	--Otherwise, just return null.
	ELSE
		v_MESSAGE_CODE := NULL;
	END IF;
		
	RETURN v_MESSAGE_CODE;
END GET_MESSAGE_CODE;
----------------------------------------------------------------------------------------------------
PROCEDURE ROLLBACK_TO
	(
	p_SAVEPOINT_NAME IN VARCHAR2
	) IS
	
	INVALID_SAVEPOINT EXCEPTION;
	PRAGMA EXCEPTION_INIT(INVALID_SAVEPOINT, -1086);
	
BEGIN

	EXECUTE IMMEDIATE 'ROLLBACK TO '||p_SAVEPOINT_NAME;

EXCEPTION
	WHEN INVALID_SAVEPOINT THEN
		LOG_AND_CONTINUE;
		
END ROLLBACK_TO;
----------------------------------------------------------------------------------------------------
-- Private function called by both LOG_AND_CONTINUE and LOG_AND_RAISE
PROCEDURE LOG_EXCEPTION
	(
	p_EXTRA_MESSAGE IN VARCHAR2,
	p_LOG_LEVEL IN NUMBER,
	p_ALERT_TRIGGER IN VARCHAR2,
	p_PROCEDURE_NAME IN VARCHAR2,
	p_STEP_NAME IN VARCHAR2,
	p_SOURCE_NAME IN VARCHAR2,
	p_SOURCE_DATE IN DATE,
	p_SOURCE_DOMAIN_ID IN NUMBER,
	p_SOURCE_ENTITY_ID IN NUMBER,
	p_SAVEPOINT_NAME IN VARCHAR2,
	p_RE_RAISE IN BOOLEAN
	) IS
v_FULL_ERRM		VARCHAR2(32767);
v_MESSAGE_CODE	VARCHAR2(64);
v_PROC_NAME		PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP_NAME		PROCESS_LOG_EVENT.STEP_NAME%TYPE;
v_ALERT_TRIGGER	SYSTEM_ALERT_TRIGGER.TRIGGER_VALUE%TYPE;
BEGIN
	-- If a savepoint name was specified then rollback to it
	IF p_SAVEPOINT_NAME IS NOT NULL THEN
		BEGIN
			ROLLBACK_TO(p_SAVEPOINT_NAME);
		EXCEPTION
			WHEN OTHERS THEN
				LOG_AND_CONTINUE('Attempting rollback to '||p_SAVEPOINT_NAME);
		END;
	END IF;
	
	-- only raise an alert for levels of notice or higher
	IF p_LOG_LEVEL >= LOGS.c_LEVEL_NOTICE THEN
		-- lookup a message code, if available, for current error
		v_MESSAGE_CODE := GET_MESSAGE_CODE(SQLERRM);
		-- get error info and stack-trace
		v_FULL_ERRM := UT.GET_FULL_ERRM;

		-- if no trigger value specified, use extra message (if supplied) and sqlerrm.
		-- trim to 1000 chars since that is the limit of SYSTEM_ALERT_TRIGGER.TRIGGER_VALUE
		v_ALERT_TRIGGER := SUBSTR(NVL(p_ALERT_TRIGGER,
							   CASE WHEN p_EXTRA_MESSAGE IS NULL THEN v_FULL_ERRM
									ELSE p_EXTRA_MESSAGE||': '||v_FULL_ERRM
									END),
								1, 1000);

		-- signal any applicable alerts
		ALERTS.TRIGGER_ALERTS(v_ALERT_TRIGGER,
								p_LOG_LEVEL,
								GET_DICTIONARY_VALUE('Alert Message',0,'System','Exceptions'),
								ALERTS.c_TYPE_EXCEPTION);
	END IF;
	
	-- for performance, we can go ahead and check the log-level here and skip this
	-- work only to have the event filtered by the LOGS package...
	IF LOGS.IS_LEVEL_ENABLED(p_LOG_LEVEL) OR p_LOG_LEVEL >= LOGS.c_LEVEL_NOTICE THEN
		-- if this is less than a notice then alert code above was not executed, so
		-- we haven't yet looked up the message code or retrieved error info & stack-trace
		IF p_LOG_LEVEL < LOGS.c_LEVEL_NOTICE THEN
			v_MESSAGE_CODE := GET_MESSAGE_CODE(SQLERRM);
			v_FULL_ERRM := UT.GET_FULL_ERRM;
		END IF;
		
		IF p_PROCEDURE_NAME IS NULL AND p_STEP_NAME IS NULL THEN
			-- look back one additional level since we know the caller is
			-- LOG_AND_CONTINUE or LOG_AND_RAISE
			LOGS.GET_CALLER(v_PROC_NAME, v_STEP_NAME, 2);
		ELSE
			v_PROC_NAME := p_PROCEDURE_NAME;
			v_STEP_NAME := p_STEP_NAME;
		END IF;

		-- record a message in the process log
		LOGS.LOG_EVENT(p_LOG_LEVEL, p_EXTRA_MESSAGE, v_PROC_NAME, v_STEP_NAME,
					p_SOURCE_NAME, p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID,
					v_MESSAGE_CODE, v_FULL_ERRM);
	END IF;
	
	IF p_RE_RAISE THEN
		ERRS.RERAISE(SQLCODE, SQLERRM);
	END IF;
END LOG_EXCEPTION;
----------------------------------------------------------------------------------------------------
-- Log the current exception. If SQLERRM starts with a predefined message code, the
-- recorded log event will be associated with that message. If p_ALERT_TRIGGER is null,
-- then UT.GET_FULL_ERRM will be used as a trigger value. If a savepoint name is specified
-- then it will be used in a ‘rollback to’ operation.
PROCEDURE LOG_AND_CONTINUE
	(
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_LOG_LEVEL IN NUMBER := LOGS.c_LEVEL_ERROR,
	p_ALERT_TRIGGER IN VARCHAR2 := NULL,
	p_PROCEDURE_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL,
	p_SOURCE_NAME IN VARCHAR2 := NULL,
	p_SOURCE_DATE IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_SAVEPOINT_NAME IN VARCHAR2 := NULL
	) IS
BEGIN
	LOG_EXCEPTION(p_EXTRA_MESSAGE, p_LOG_LEVEL, p_ALERT_TRIGGER,
				  p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME, p_SOURCE_DATE,
				  p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_SAVEPOINT_NAME, FALSE);
END LOG_AND_CONTINUE;
----------------------------------------------------------------------------------------------------
-- Same as above, except the exception is re-raised after the log event is recorded.
PROCEDURE LOG_AND_RAISE
	(
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_LOG_LEVEL IN NUMBER := LOGS.c_LEVEL_ERROR,
	p_ALERT_TRIGGER IN VARCHAR2 := NULL,
	p_PROCEDURE_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL,
	p_SOURCE_NAME IN VARCHAR2 := NULL,
	p_SOURCE_DATE IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_SAVEPOINT_NAME IN VARCHAR2 := NULL
	) IS
BEGIN
	LOG_EXCEPTION(p_EXTRA_MESSAGE, p_LOG_LEVEL, p_ALERT_TRIGGER,
				  p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME, p_SOURCE_DATE,
				  p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_SAVEPOINT_NAME, TRUE);
END LOG_AND_RAISE;
----------------------------------------------------------------------------------------------------
-- This method calls LOG_AND_CONTINUE with a FATAL level, then it calls LOGS.STOP_PROCESS
-- to end the current process, and finally it re-raises the exception.
PROCEDURE ABORT_PROCESS(
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_ALERT_TRIGGER IN VARCHAR2 := NULL,
	p_PROCEDURE_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL,
	p_SOURCE_NAME IN VARCHAR2 := NULL,
	p_SOURCE_DATE IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_SAVEPOINT_NAME IN VARCHAR2 := NULL
	) IS
v_PROCESS_STATUS NUMBER := LOGS.c_LEVEL_FATAL;
v_MESSAGE VARCHAR2(32767);
v_SQLCODE NUMBER;
v_SQLERRM VARCHAR2(32767);
BEGIN
	-- process never started? then log error message and raise source exception
	IF SQLCODE = MSGCODES.n_ERR_COULD_NOT_START_PROCESS THEN
		LOG_EXCEPTION(p_EXTRA_MESSAGE, LOGS.c_LEVEL_ERROR, p_ALERT_TRIGGER,
					  p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME, p_SOURCE_DATE,
					  p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_SAVEPOINT_NAME, FALSE);
		LOGS.GET_SOURCE_OF_START_FAILURE(v_SQLCODE, v_SQLERRM);
		ERRS.RERAISE(v_SQLCODE, v_SQLERRM);

	-- otherwise, log fatal message and abort the process
	ELSE
		LOG_EXCEPTION(p_EXTRA_MESSAGE, LOGS.c_LEVEL_FATAL, p_ALERT_TRIGGER,
					  p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME, p_SOURCE_DATE,
					  p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_SAVEPOINT_NAME, FALSE);
		LOGS.STOP_PROCESS(v_MESSAGE, v_PROCESS_STATUS, SQLCODE, UT.GET_FULL_ERRM);
		-- re-raise the exception
		ERRS.RERAISE(SQLCODE, SQLERRM);
	END IF;

END ABORT_PROCESS;
----------------------------------------------------------------------------------------------------
-- Raises an exception. If the message code is in the format ‘ORA-XXXXX’ then an
-- exception with the specified SQLCODE (the ‘XXXXX’ in the message code) will be raised.
-- Otherwise, a SQLCODE of -20,000 will be used. Note that this will use
-- RAISE_APPLICATION_ERROR, so if a SQLCODE is specified that is outside the range of
-- -20,000 to -20,999 then -21,000 will be used instead. If specified to keep the
-- exception source then the SQLERRM of the resulting exception will include a
-- reference to the current one (if this method is called from within an exception
-- handler)
PROCEDURE RAISE
	(
	p_MESSAGE_CODE IN VARCHAR2,
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_KEEP_EXCEPTION_SOURCE IN BOOLEAN := FALSE
	) IS
v_MSG_DEF	UT.MSG_DEF;
v_SQLCODE	PLS_INTEGER;
v_SQLERRM	VARCHAR2(32767);
BEGIN
	UT.GET_MESSAGE_DEFINITION(p_MESSAGE_CODE, v_MSG_DEF);
	-- no such message code?
	IF v_MSG_DEF.MESSAGE_ID IS NULL THEN
		v_SQLCODE := -20000;
		v_SQLERRM := 'Unknown General Exception ('||p_MESSAGE_CODE||')';
	ELSIF v_MSG_DEF.MESSAGE_TYPE = 'ORA' THEN
		-- ORA code?
		v_SQLCODE := -v_MSG_DEF.MESSAGE_NUMBER;
		v_SQLERRM := v_MSG_DEF.MESSAGE_TEXT;
	ELSE
		-- If not ORA code, use ORA-20000
		v_SQLCODE := -20000;
		v_SQLERRM := p_MESSAGE_CODE||': '||v_MSG_DEF.MESSAGE_TEXT;
	END IF;

	-- add custom text if there is any
	IF p_EXTRA_MESSAGE IS NOT NULL THEN
		v_SQLERRM := v_SQLERRM||': '||p_EXTRA_MESSAGE;
	END IF;

	-- raise it
	RAISE_APPLICATION_ERROR(v_SQLCODE, v_SQLERRM, p_KEEP_EXCEPTION_SOURCE);
END RAISE;
--==================================================================================================
-- Helper methods for constructing consistent message text for frequently used errors:
--==================================================================================================
-- These raise MSGCODES.c_ERR_PRIVILEGES
----------------------------------------------------------------------------------------------------
-- These methods are for throwing exceptions after using CAN_READ, CAN_WRITE, or
-- CAN_DELETE to validate module-level security.
PROCEDURE RAISE_NO_READ_MODULE
	(
	p_MODULE_NAME IN VARCHAR2
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_PRIVILEGES, 'The "Select ' || UPPER(p_MODULE_NAME) || '" Privilege is required.');
END RAISE_NO_READ_MODULE;
----------------------------------------------------------------------------------------------------
PROCEDURE RAISE_NO_WRITE_MODULE
	(
	p_MODULE_NAME IN VARCHAR2
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_PRIVILEGES, 'The "Update ' || UPPER(p_MODULE_NAME) || '" Privilege is required.');
END RAISE_NO_WRITE_MODULE;
----------------------------------------------------------------------------------------------------
PROCEDURE RAISE_NO_DELETE_MODULE
	(
	p_MODULE_NAME IN VARCHAR2
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_PRIVILEGES, 'The "Delete ' || UPPER(p_MODULE_NAME) || '" Privilege is required.');
END RAISE_NO_DELETE_MODULE;
----------------------------------------------------------------------------------------------------
-- These methods are for throwing exceptions after using SD package to validate
-- data-level security
PROCEDURE RAISE_NO_PRIVILEGE_ACTION
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER := NULL,
	p_ENTITY_ID IN NUMBER := NULL
	) AS
	v_MESSAGE VARCHAR2(32767);
BEGIN

	IF p_ENTITY_DOMAIN_ID IS NULL OR p_ENTITY_ID IS NULL THEN
		v_MESSAGE := 'The "' || p_ACTION_NAME || '" Privilege is required.';
	ELSE
		v_MESSAGE := 'The "' || p_ACTION_NAME || '" Privilege is required for the ';
		IF p_ENTITY_ID = SD.g_ALL_DATA_ENTITY_ID THEN
			v_MESSAGE := v_MESSAGE || TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_DOMAIN_ID, EC.ED_ENTITY_DOMAIN) || ': <All Data>.';
		ELSE
			v_MESSAGE := v_MESSAGE || TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_ID, p_ENTITY_DOMAIN_ID, TRUE) || '.';
		END IF;
	END IF;
	
	ERRS.RAISE(MSGCODES.c_ERR_PRIVILEGES, v_MESSAGE);
	
END RAISE_NO_PRIVILEGE_ACTION;
----------------------------------------------------------------------------------------------------
-- This raises MSGCODES.c_ERR_ARGUMENT
PROCEDURE RAISE_BAD_ARGUMENT
	(
	p_ARGUMENT_NAME IN VARCHAR2,
	p_ARGUMENT_VALUE IN VARCHAR2,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_ARGUMENT, 'Argument "' || p_ARGUMENT_NAME || '" had an invalid value of "' || p_ARGUMENT_VALUE || '". ' || p_ADDITIONAL_INFO);
END RAISE_BAD_ARGUMENT;
----------------------------------------------------------------------------------------------------
-- This raises MSGCODES.c_ERR_INVALID_DATE
PROCEDURE RAISE_BAD_DATE
	(
	p_DATE_STRING IN VARCHAR2,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	) AS
v_MSG VARCHAR2(4000);
BEGIN
	v_MSG := '"' || p_DATE_STRING || '" is not a valid date in this context';
	IF p_ADDITIONAL_INFO IS NULL THEN
		v_MSG := v_MSG||'.';
	ELSE
		v_MSG := v_MSG||': '||p_ADDITIONAL_INFO;
	END IF;
	ERRS.RAISE(MSGCODES.c_ERR_INVALID_DATE, v_MSG);
END RAISE_BAD_DATE;
----------------------------------------------------------------------------------------------------
-- This raises MSGCODES.c_ERR_DATE_RANGE
PROCEDURE RAISE_BAD_DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_DATE_RANGE, 'A date range from ' || TEXT_UTIL.TO_CHAR_DATE(p_BEGIN_DATE) || ' to ' 
		|| TEXT_UTIL.TO_CHAR_DATE(p_END_DATE) || ' is not valid in this context. ' || p_ADDITIONAL_INFO);
END RAISE_BAD_DATE_RANGE;
----------------------------------------------------------------------------------------------------
-- This raises MSGCODES.c_ERR_DATES_OVERLAP
PROCEDURE RAISE_OVERLAPPING_DATES
	(
	p_BEGIN_DATE1 IN DATE,
	p_END_DATE1 IN DATE,
	p_BEGIN_DATE2 IN DATE,
	p_END_DATE2 IN DATE,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_DATES_OVERLAP, 'The date range from ' || TEXT_UTIL.TO_CHAR_DATE(p_BEGIN_DATE1) || ' to ' 
		|| TEXT_UTIL.TO_CHAR_DATE(p_END_DATE1) || ' overlaps with the date range from ' || TEXT_UTIL.TO_CHAR_DATE(p_BEGIN_DATE2) 
		|| ' to ' || TEXT_UTIL.TO_CHAR_DATE(p_END_DATE2) || '. ' ||  p_ADDITIONAL_INFO);
END RAISE_OVERLAPPING_DATES;
----------------------------------------------------------------------------------------------------
-- This raises MSGCODES.c_ERR_BUS_RULE
PROCEDURE RAISE_BUSINESS_RULE_ERROR
	(
	p_BUSINESS_RULE IN VARCHAR2
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_BUS_RULE, 'The following rule has been violated:' || p_BUSINESS_RULE);
END RAISE_BUSINESS_RULE_ERROR;
----------------------------------------------------------------------------------------------------
-- This helper methods raise MSGCODES.c_ERR_ASSERT and should only be used after calling
-- legacy API routines that set a p_STATUS (and optionally p_MESSAGE) instead of raising
-- exceptions. The p_PROCEDURE_NAME parameter should be the name of the API that returned
-- this status. An exception will only be raised when p_STATUS is non-zero.
PROCEDURE VALIDATE_STATUS
	(
	p_PROCEDURE_NAME IN VARCHAR2,
	p_STATUS IN NUMBER,
	p_MESSAGE IN VARCHAR2 := NULL
	) AS
BEGIN
	ASSERT(NVL(p_STATUS,GA.SUCCESS) = GA.SUCCESS, 'Procedure ' || p_PROCEDURE_NAME || ' returned an invalid status of ' || p_STATUS || '. ' || p_MESSAGE);
END VALIDATE_STATUS;
----------------------------------------------------------------------------------------------------
-- This procedure is the same as the one above, except that it validates that the
-- specified error message is NULL. If non-null, an exception is raised.
PROCEDURE VALIDATE_ERROR_MESSAGE
	(
	p_PROCEDURE_NAME IN VARCHAR2,
	p_ERROR_MESSAGE IN VARCHAR2
	) AS
BEGIN
	ASSERT(p_ERROR_MESSAGE IS NULL, 'Procedure ' || p_PROCEDURE_NAME || ' returned an error message: ' || p_ERROR_MESSAGE);
END VALIDATE_ERROR_MESSAGE;
----------------------------------------------------------------------------------------------------
END ERRS;
/
