CREATE OR REPLACE TYPE BODY MM_LOGGER_ADAPTER IS
-----------------------------------------------------------------------------
MEMBER FUNCTION IS_LOGGING RETURN BOOLEAN IS
BEGIN
	RETURN SELF.LOG_TYPE <> 0;
END IS_LOGGING;
-----------------------------------------------------------------------------
MEMBER FUNCTION IS_LOGGING_EVENTS RETURN BOOLEAN IS
BEGIN
	RETURN SELF.LOG_TYPE IN (1,3);
END IS_LOGGING_EVENTS;
-----------------------------------------------------------------------------
MEMBER FUNCTION IS_LOGGING_EXCHANGES RETURN BOOLEAN IS
BEGIN
	RETURN SELF.LOG_TYPE IN (2,3);
END IS_LOGGING_EXCHANGES;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_START AS
BEGIN
	SELF.FINISH_MESSAGE := NULL;
	LOGS.START_PROCESS(SELF.PROCESS_NAME,
					   p_EVENT_LEVEL => LEAST( LOGS.CURRENT_LOG_LEVEL,
												CASE SELF.TRACE_ON
												WHEN 1 THEN LOGS.c_LEVEL_DEBUG
												WHEN 2 THEN LOGS.c_LEVEL_ALL
												ELSE LOGS.c_LEVEL_FATAL
												END ),
					   p_KEEP_EVENT_DETAILS => SELF.IS_LOGGING_EXCHANGES);
	LOGS.SET_PROCESS_TARGET_PARAMETER('External Account', CASE NVL(SELF.EXTERNAL_ACCOUNT_NAME,'?')
															WHEN '?' THEN '*'
															ELSE SELF.EXTERNAL_ACCOUNT_NAME
															END);
	SELF.FINISH_MESSAGE := NULL;
	SELF.PROCESS_STARTED := 1;
END LOG_START;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_START ( p_MARKET IN VARCHAR2, p_ACTION IN VARCHAR2 ) AS
v_STAT NUMBER;
v_MKT_ACTION VARCHAR2(130);
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	SELF.LAST_EVENT_ID := NULL;
	SELF.EXCHANGE_IS_ACTIVE := 0;

	v_MKT_ACTION := p_MARKET;
	IF v_MKT_ACTION IS NOT NULL THEN
		v_MKT_ACTION := v_MKT_ACTION||'.';
	END IF;
	v_MKT_ACTION := v_MKT_ACTION||p_ACTION;

	SELF.MEX_MARKET := p_MARKET;
	SELF.MEX_ACTION := p_ACTION;

	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_INFO_DETAIL('Starting exchange: '||SELF.EXCHANGE_NAME||' for '||NVL(SELF.EXTERNAL_ACCOUNT_NAME,'*')||CASE WHEN v_MKT_ACTION IS NULL THEN NULL ELSE' ('||v_MKT_ACTION||')' END, v_PROCEDURE, v_STEP);

END LOG_START;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_ERROR ( p_MESSAGE IN VARCHAR2 ) AS
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_ERROR(P_MESSAGE, v_PROCEDURE, v_STEP);
END LOG_ERROR;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_WARN ( p_MESSAGE IN VARCHAR2 ) AS
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_WARN(P_MESSAGE, v_PROCEDURE, v_STEP);
END LOG_WARN;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_INFO ( p_MESSAGE IN VARCHAR2 ) AS
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_INFO(P_MESSAGE, v_PROCEDURE, v_STEP);
END LOG_INFO;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_REQUEST( p_REQUEST_HEADERS IN CLOB ,
                                  		 p_REQUEST_BODY IN CLOB ,
                                  		 p_BODY_CONTENT_TYPE IN VARCHAR2 ) AS
v_MKT_ACTION VARCHAR2(130);
v_MESSAGE VARCHAR2(4000);
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	v_MKT_ACTION := SELF.MEX_MARKET;
	IF v_MKT_ACTION IS NOT NULL THEN
		v_MKT_ACTION := v_MKT_ACTION||'.';
	END IF;
	v_MKT_ACTION := v_MKT_ACTION||SELF.MEX_ACTION;

	v_MESSAGE := 'Request: '||SELF.EXCHANGE_NAME||' for '||NVL(SELF.EXTERNAL_ACCOUNT_NAME,'*')||CASE WHEN v_MKT_ACTION IS NULL THEN NULL ELSE' ('||v_MKT_ACTION||')' END;

	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_INFO(v_MESSAGE, v_PROCEDURE, v_STEP);

	SELF.LAST_EVENT_ID := LOGS.LAST_EVENT_ID();

	IF NOT p_REQUEST_HEADERS IS NULL THEN
		LOG_ATTACHMENT('Request Headers','text/plain', p_REQUEST_HEADERS);
	END IF;

	IF NOT p_REQUEST_BODY IS NULL THEN
		LOG_ATTACHMENT('Request Body', p_BODY_CONTENT_TYPE, p_REQUEST_BODY);
	END IF;
END LOG_REQUEST;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_RESPONSE ( p_RESPONSE_HEADERS IN CLOB ,
                                  		 p_RESPONSE_BODY IN CLOB ,
                                  		 p_BODY_CONTENT_TYPE IN VARCHAR2 ) AS
v_MKT_ACTION VARCHAR2(130);
v_MESSAGE VARCHAR2(4000);
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	v_MKT_ACTION := SELF.MEX_MARKET;
	IF v_MKT_ACTION IS NOT NULL THEN
		v_MKT_ACTION := v_MKT_ACTION||'.';
	END IF;
	v_MKT_ACTION := v_MKT_ACTION||SELF.MEX_ACTION;

	v_MESSAGE := 'Response: '||SELF.EXCHANGE_NAME||' for '||NVL(SELF.EXTERNAL_ACCOUNT_NAME,'*')||CASE WHEN v_MKT_ACTION IS NULL THEN NULL ELSE' ('||v_MKT_ACTION||')' END;

	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_INFO(v_MESSAGE, v_PROCEDURE, v_STEP);

	SELF.LAST_EVENT_ID := LOGS.LAST_EVENT_ID();

	IF NOT p_RESPONSE_HEADERS IS NULL THEN
		LOG_ATTACHMENT('Response Headers','text/plain', p_RESPONSE_HEADERS);
	END IF;

	IF NOT p_RESPONSE_BODY IS NULL THEN
		LOG_ATTACHMENT('Response Body', p_BODY_CONTENT_TYPE, p_RESPONSE_BODY);
	END IF;

END LOG_RESPONSE;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_ATTACHMENT ( p_DESCRIPTION IN VARCHAR2,
                                             p_ATTACHMENT_TYPE IN VARCHAR2,
                                             p_ATTACHMENT IN CLOB ) AS
BEGIN
	LOGS.POST_EVENT_DETAILS(P_DESCRIPTION, P_ATTACHMENT_TYPE, P_ATTACHMENT);
END LOG_ATTACHMENT;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_DEBUG ( p_MESSAGE IN VARCHAR2 ) AS
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_DEBUG(P_MESSAGE, v_PROCEDURE, v_STEP);
END LOG_DEBUG;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_EXCHANGE_ERROR (p_EXCHANGE_ERROR IN VARCHAR2) AS
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_ERROR(p_EXCHANGE_ERROR, v_PROCEDURE, v_STEP);
END LOG_EXCHANGE_ERROR;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_EXCHANGE_IDENTIFIER (p_EXCHANGE_IDENTIFIER IN VARCHAR2) AS
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_NOTICE('Exchange Identifier: ' || p_EXCHANGE_IDENTIFIER, v_PROCEDURE, v_STEP);
END LOG_EXCHANGE_IDENTIFIER;
-----------------------------------------------------------------------------
OVERRIDING MEMBER PROCEDURE LOG_STOP ( p_RESULT IN MEX_RESULT ) AS
v_EVENT_STATUS		VARCHAR2(32);
v_EXCHANGE_STATUS	VARCHAR2(32);
v_ERROR_TEXT		VARCHAR2(4000);
v_MSG				VARCHAR2(512);
v_RET_CODE			NUMBER;
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
BEGIN
	-- Reset the Last Event Id
	SELF.LAST_EVENT_ID := NULL;

	v_ERROR_TEXT := MEX_SWITCHBOARD.GetErrorText(p_RESULT);

	IF p_RESULT.STATUS_CODE NOT IN (MEX_SWITCHBOARD.c_Status_Success, MEX_SWITCHBOARD.c_Status_No_More_Messages) THEN
		v_RET_CODE := p_RESULT.STATUS_CODE;
		v_EVENT_STATUS := 'Error';
		v_EXCHANGE_STATUS := 'Error';
		v_MSG := v_MSG||' (exchange response may contain more details): ';
		v_MSG := SUBSTR(v_MSG||v_ERROR_TEXT,1,512);
	ELSE
		v_RET_CODE := MEX_SWITCHBOARD.c_Status_Success;
		v_EVENT_STATUS := 'Normal';
		v_EXCHANGE_STATUS := 'Success';
		IF v_ERROR_TEXT IS NULL THEN
			v_ERROR_TEXT := v_EXCHANGE_STATUS;
		END IF;
		v_MSG := SUBSTR(v_MSG||': '||v_ERROR_TEXT,1,512);
		v_ERROR_TEXT := NULL;
	END IF;

	-- log an error message if necessary
	IF v_RET_CODE <> MEX_SWITCHBOARD.c_Status_Success THEN
		LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
		LOGS.LOG_ERROR(v_MSG||' ('||p_RESULT.STATUS_CODE||')', v_PROCEDURE, v_STEP);
	END IF;

	LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
	LOGS.LOG_INFO_DETAIL('Finished exchange: '||v_MSG||' ('||p_RESULT.STATUS_CODE||')', v_PROCEDURE, v_STEP);

	SELF.EXCHANGE_IS_ACTIVE := 0;

END LOG_STOP;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_STOP ( p_STATUS IN NUMBER, p_MESSAGE IN VARCHAR2 ) AS
v_PROCEDURE PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP  PROCESS_LOG_EVENT.STEP_NAME%TYPE;
v_STAT	NUMBER;
BEGIN
	-- Bug Fix for errant code that calls Log_Stop prior to ever calling Log_Start
	IF SELF.PROCESS_STARTED = 0 THEN
		SELF.LOG_START;
	END IF;
	SELF.PROCESS_STARTED := 0;

	IF NVL(p_STATUS,GA.SUCCESS) <> GA.SUCCESS THEN
		LOGS.GET_CALLER(v_PROCEDURE, v_STEP);
		LOGS.LOG_FATAL(NULL, v_PROCEDURE, v_STEP, p_SQLERRM => p_MESSAGE);
		LOGS.STOP_PROCESS(SELF.FINISH_MESSAGE, v_STAT, p_STATUS, p_MESSAGE);
	ELSE
		LOGS.STOP_PROCESS(SELF.FINISH_MESSAGE, v_STAT);
	END IF;
	
END LOG_STOP;
-----------------------------------------------------------------------------
MEMBER FUNCTION GET_END_MESSAGE RETURN VARCHAR2
AS
BEGIN
	IF SELF.PROCESS_STARTED = 1 THEN
		RETURN LOGS.GET_FINISH_MESSAGE;
	ELSE
		RETURN SELF.FINISH_MESSAGE;
	END IF;
END GET_END_MESSAGE;
-----------------------------------------------------------------------------
-- constructor
CONSTRUCTOR FUNCTION MM_LOGGER_ADAPTER ( p_EXTERNAL_SYSTEM_ID IN NUMBER,
										 p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
										 p_PROCESS_NAME IN VARCHAR2,
										 p_EXCHANGE_NAME IN VARCHAR2,
										 p_LOG_TYPE IN NUMBER := 3,
										 p_TRACE_ON IN NUMBER := 0
									   ) RETURN SELF AS RESULT IS
BEGIN
	SELF.EXTERNAL_SYSTEM_ID := p_EXTERNAL_SYSTEM_ID;

	SELECT NVL(MAX(EXTERNAL_SYSTEM_NAME),'?')
    INTO SELF.EXTERNAL_SYSTEM_NAME
    FROM EXTERNAL_SYSTEM
    WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;

	SELF.EXTERNAL_ACCOUNT_NAME := p_EXTERNAL_ACCOUNT_NAME;
	SELF.PROCESS_NAME := p_PROCESS_NAME;
	SELF.EXCHANGE_NAME := p_EXCHANGE_NAME;
	SELF.LOG_TYPE := p_LOG_TYPE;
	SELF.TRACE_ON := p_TRACE_ON;
	SELF.PROCESS_STARTED := 0;
	SELF.FINISH_MESSAGE := NULL;

	SELF.LAST_EVENT_ID := NULL;

	RETURN;
END;
-----------------------------------------------------------------------------
END;
/
