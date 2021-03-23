CREATE OR REPLACE PACKAGE MM_UTIL AS

--Market Manager Utility package
--These procedures are called by other MarketManager procedures, but not by the GUI.
--This package should not reference other MarketManager packages.

TYPE REF_CURSOR IS REF CURSOR;

PROCEDURE APPEND_UNTIL_FINISHED_CLOB
   (
   p_RECORD_DELIMITER IN CHAR,
   p_RECORDS IN VARCHAR,
   p_FILE_PATH IN VARCHAR,
   p_LAST_TIME IN NUMBER,
   p_CLOB_LOC OUT NOCOPY CLOB
   );

PROCEDURE PURGE_CLOB_STAGING_TABLE;

PROCEDURE APPEND_UNTIL_FINISHED_XML
   (
   p_RECORD_DELIMITER IN CHAR,
   p_RECORDS IN VARCHAR,
   p_FILE_PATH IN VARCHAR,
   p_LAST_TIME IN NUMBER,
   p_XML OUT XMLTYPE
   );

PROCEDURE PUT_TRANSACTION
   (
   o_OID OUT NUMBER,
   p_INTERCHANGE_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE,
   p_SCHEDULE_STATE IN NUMBER,
   p_TRANSACTION_STATUS IN VARCHAR2 --JUST PASS NULL FOR EXTERNAL (WILL BE IGNORED)
   );

PROCEDURE PUT_MARKET_PRICE_VALUE
   (
   p_MARKET_PRICE_ID IN NUMBER,
   p_PRICE_DATE      IN DATE,
   p_PRICE_CODE      IN CHAR,
   p_PRICE           IN NUMBER,
   p_PRICE_BASIS     IN NUMBER,
   p_STATUS          OUT NUMBER,
   p_ERROR_MESSAGE   OUT VARCHAR2
   );

PROCEDURE POST_UNCONFIRMED_SCHED_ALARM(p_MARKET IN VARCHAR2, p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE, p_DATE IN DATE);

PROCEDURE POST_PART_CLEARED_DEMAND_ALERT
   (
   p_TXN_ID      IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
   p_MAX_BID_QTY IN NUMBER,
   p_CLEARED_QTY IN NUMBER,
   p_MARKET_NAME IN VARCHAR2
   );

FUNCTION GET_MAX_PS_DEMAND
   (
   p_TXN_ID IN NUMBER,
   p_SCHEDULE_DATE IN DATE
   ) RETURN NUMBER;

FUNCTION GET_LOGGER
   (
   p_EXTERNAL_SYSTEM_ID IN NUMBER,
   p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
   p_PROCESS_NAME IN VARCHAR2,
   p_EXCHANGE_NAME IN VARCHAR2,
   p_LOG_TYPE IN NUMBER,
   p_TRACE_ON IN NUMBER
   ) RETURN MM_LOGGER_ADAPTER;

PROCEDURE INIT_MEX
   (
   p_EXTERNAL_SYSTEM_ID IN NUMBER,
   p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
   p_PROCESS_NAME IN VARCHAR2,
   p_EXCHANGE_NAME IN VARCHAR2,
   p_LOG_TYPE IN NUMBER,
   p_TRACE_ON IN NUMBER,
   p_CREDENTIALS OUT MEX_CREDENTIALS,
   p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
   p_IS_PUBLIC   IN BOOLEAN := FALSE
   );

PROCEDURE INIT_MEX
   (
   p_EXTERNAL_SYSTEM_ID IN NUMBER,
   p_PROCESS_NAME IN VARCHAR2,
   p_EXCHANGE_NAME IN VARCHAR2,
   p_LOG_TYPE IN NUMBER,
   p_TRACE_ON IN NUMBER,
   p_CREDENTIALS OUT MM_CREDENTIALS_SET,
   p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
   p_IS_PUBLIC   IN BOOLEAN := FALSE
   );

FUNCTION GET_EXT_ACCOUNT_FOR_TXN
   (
   p_TRANSACTION_ID IN NUMBER,
   p_EXTERNAL_SYSTEM_ID IN NUMBER
   ) RETURN VARCHAR2;

PROCEDURE START_EXCHANGE
   (
   p_IS_IMPORT IN BOOLEAN,
   p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
   );

PROCEDURE STOP_EXCHANGE
   (
   p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
   p_IN_STATUS IN NUMBER,
   p_IN_MESSAGE IN VARCHAR2,
   p_RETURN_MESSAGE OUT VARCHAR2
   );

FUNCTION DETERMINE_STATEMENT_TYPE
   (
      p_REPORT_STATEMENT_TYPE IN VARCHAR2,
       p_VERSION_NUMBER IN VARCHAR,
      p_EXTERNAL_SYSTEM_ID IN NUMBER,
      p_EXTERNAL_SYS_IDENTIFIER_TYPE IN VARCHAR2 := EI.g_DEFAULT_IDENTIFIER_TYPE,
      p_STATEMENT_TYPE_NAME_PREFIX IN VARCHAR2 := NULL
   ) RETURN NUMBER;

--Bilateral Contract Statuses
g_BILAT_REQUIRES_APPROVAL CONSTANT VARCHAR2(16) := 'Requires Apvl';
g_BILAT_APPROVED CONSTANT VARCHAR2(16) := 'Approved';
g_BILAT_PENDING_CP_APPROVAL CONSTANT VARCHAR2(16) := 'Pending CP Apvl';
g_BILAT_REJECTED CONSTANT VARCHAR2(16) := 'Rejected';

g_UNCONFIRMED_BILAT_SCHEDULE CONSTANT VARCHAR2(32) := 'Unconfirmed Bilateral Schedule';

g_ALERT_PRIORITY CONSTANT VARCHAR2(16) := '3';

END MM_UTIL;
/
CREATE OR REPLACE PACKAGE BODY MM_UTIL AS
----------------------------------------------------------------------------------------------------
g_PARTIAL_DEMAND_CLEAR SYSTEM_ALERT.ALERT_NAME%TYPE := 'Partial clear on p/s demand bid';
----------------------------------------------------------------------------------------------------
PROCEDURE APPEND_UNTIL_FINISHED_CLOB
	(
	p_RECORD_DELIMITER IN CHAR,
	p_RECORDS IN VARCHAR,
	p_FILE_PATH IN VARCHAR,
	p_LAST_TIME IN NUMBER,
	p_CLOB_LOC OUT NOCOPY CLOB
	) AS

v_TOKEN_TABLE GA.BIG_STRING_TABLE;
v_ROW_DATA VARCHAR2(4000);

BEGIN

    -- Tokenize into string table.
    UT.TOKENS_FROM_BIG_STRING(p_RECORDS,p_RECORD_DELIMITER,v_TOKEN_TABLE);

	-- Get what was already in the staging table for this session.
    BEGIN
	    SELECT ROW_CONTENTS INTO p_CLOB_LOC
        FROM DATA_IMPORT_STAGING_AREA
        WHERE SESSION_ID = USERENV('SESSIONID')
        	AND FILE_NAME = p_FILE_PATH
            AND ROW_NUM = 0 FOR UPDATE;
		IF p_CLOB_LOC IS NULL THEN
        	DBMS_LOB.CREATETEMPORARY(p_CLOB_LOC,TRUE);
        END IF;
	-- If it didn't exist, create a new clob.
	EXCEPTION
    	WHEN NO_DATA_FOUND THEN
        	DBMS_LOB.CREATETEMPORARY(p_CLOB_LOC,TRUE);
    END;

	-- Open the clob for writing, and add the tokens to it.
    DBMS_LOB.OPEN(p_CLOB_LOC, DBMS_LOB.LOB_READWRITE);
    FOR v_INDEX IN v_TOKEN_TABLE.FIRST..v_TOKEN_TABLE.LAST LOOP
		v_ROW_DATA := v_TOKEN_TABLE(v_INDEX) || CHR(13) || CHR(10);
        DBMS_LOB.WRITEAPPEND(p_CLOB_LOC, LENGTH(v_ROW_DATA), v_ROW_DATA);
    END LOOP;
    DBMS_LOB.CLOSE(p_CLOB_LOC);

	-- Insert back into the staging table if this was the first time.
	-- If this was not the first time, we have already updated the actual object in the table.
    IF DBMS_LOB.ISTEMPORARY(p_CLOB_LOC) = 1 THEN
       	INSERT INTO DATA_IMPORT_STAGING_AREA
           	(SESSION_ID, FILE_NAME, ROW_NUM,
             ROW_CONTENTS, STATUS)
        VALUES
           	(USERENV('SESSIONID'), p_FILE_PATH, 0,
             p_CLOB_LOC, 'B');
	END IF;

	IF p_LAST_TIME = 1 THEN
		-- If this is the last time, mark the rows in the table as Finished.
		-- We are returning the final clob.
    	UPDATE DATA_IMPORT_STAGING_AREA
        SET STATUS = 'F'
        WHERE SESSION_ID = USERENV('SESSIONID')
        	AND FILE_NAME = p_FILE_PATH;
	ELSE
		-- Clean up the clob since it's not the final one.
	    IF DBMS_LOB.ISTEMPORARY(p_CLOB_LOC) = 1 THEN
	    	DBMS_LOB.FREETEMPORARY(p_CLOB_LOC);
	    END IF;
		p_CLOB_LOC := NULL;
	END IF;


EXCEPTION
	WHEN OTHERS THEN
        IF NOT p_CLOB_LOC IS NULL THEN
        	IF DBMS_LOB.ISTEMPORARY(p_CLOB_LOC) = 1 THEN
            	DBMS_LOB.FREETEMPORARY(p_CLOB_LOC);
            END IF;
        END IF;

		RAISE;

END APPEND_UNTIL_FINISHED_CLOB;
----------------------------------------------------------------------------------------------------

PROCEDURE PURGE_CLOB_STAGING_TABLE AS
BEGIN

	DELETE FROM DATA_IMPORT_STAGING_AREA
	WHERE SESSION_ID = USERENV('SESSIONID')
		AND STATUS = 'F';

END PURGE_CLOB_STAGING_TABLE;
----------------------------------------------------------------------------------------------------

PROCEDURE APPEND_UNTIL_FINISHED_XML
	(
	p_RECORD_DELIMITER IN CHAR,
	p_RECORDS IN VARCHAR,
	p_FILE_PATH IN VARCHAR,
	p_LAST_TIME IN NUMBER,
	p_XML OUT XMLTYPE
	) AS

v_CLOB_LOC CLOB;

BEGIN
    APPEND_UNTIL_FINISHED_CLOB(p_RECORD_DELIMITER, p_RECORDS, p_FILE_PATH, p_LAST_TIME, v_CLOB_LOC);
	IF p_LAST_TIME = 1 AND v_CLOB_LOC IS NOT NULL THEN
		p_XML := XMLTYPE.CREATEXML(v_CLOB_LOC);
		PURGE_CLOB_STAGING_TABLE;

		IF DBMS_LOB.ISTEMPORARY(v_CLOB_LOC) = 1 THEN
		   	DBMS_LOB.FREETEMPORARY(v_CLOB_LOC);
	    END IF;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		BEGIN
			IF NOT v_CLOB_LOC IS NULL THEN
				IF DBMS_LOB.ISTEMPORARY(v_CLOB_LOC) = 1 THEN
					DBMS_LOB.FREETEMPORARY(v_CLOB_LOC);
				END IF;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN ERRS.LOG_AND_CONTINUE;
		END;

		ERRS.LOG_AND_RAISE;

END APPEND_UNTIL_FINISHED_XML;
-------------------------------------------------------------------------------------
PROCEDURE PUT_TRANSACTION
	(
	o_OID OUT NUMBER,
	p_INTERCHANGE_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE,
	p_SCHEDULE_STATE IN NUMBER,
	p_TRANSACTION_STATUS IN VARCHAR2 --JUST PASS NULL FOR EXTERNAL (WILL BE IGNORED)
	) AS
BEGIN

	IF p_SCHEDULE_STATE = GA.INTERNAL_STATE THEN
		EM.PUT_TRANSACTION(
			o_OID,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_NAME,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_DESC,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_ID,
			p_TRANSACTION_STATUS,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_TYPE,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER,
			NVL(p_INTERCHANGE_TRANSACTION.IS_FIRM, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_IMPORT_SCHEDULE, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_EXPORT_SCHEDULE, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_BALANCE_TRANSACTION, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_BID_OFFER, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_EXCLUDE_FROM_POSITION, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_IMPORT_EXPORT, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_DISPATCHABLE, 0),
			p_INTERCHANGE_TRANSACTION.TRANSACTION_INTERVAL,
			p_INTERCHANGE_TRANSACTION.EXTERNAL_INTERVAL,
			p_INTERCHANGE_TRANSACTION.ETAG_CODE,
			p_INTERCHANGE_TRANSACTION.BEGIN_DATE,
			p_INTERCHANGE_TRANSACTION.END_DATE,
			NVL(p_INTERCHANGE_TRANSACTION.PURCHASER_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SELLER_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.CONTRACT_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SC_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.POR_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.POD_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.COMMODITY_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SERVICE_TYPE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.TX_TRANSACTION_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.PATH_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.LINK_TRANSACTION_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.EDC_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.PSE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.ESP_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.POOL_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SCHEDULE_GROUP_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.MARKET_PRICE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.ZOR_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.ZOD_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SOURCE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SINK_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.RESOURCE_ID, 0),
			p_INTERCHANGE_TRANSACTION.AGREEMENT_TYPE,
			p_INTERCHANGE_TRANSACTION.APPROVAL_TYPE,
			p_INTERCHANGE_TRANSACTION.LOSS_OPTION,
			p_INTERCHANGE_TRANSACTION.TRAIT_CATEGORY,
			NVL(p_INTERCHANGE_TRANSACTION.TP_ID, 0)
			);
	ELSE
		IO.PUT_EXTERNAL_TRANSACTION(
			o_OID,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_NAME,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_DESC,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_ID,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_TYPE,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_CODE,
			p_INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER,
			NVL(p_INTERCHANGE_TRANSACTION.IS_FIRM, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_IMPORT_SCHEDULE, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_EXPORT_SCHEDULE, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_BALANCE_TRANSACTION, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_BID_OFFER, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_EXCLUDE_FROM_POSITION, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_IMPORT_EXPORT, 0),
			NVL(p_INTERCHANGE_TRANSACTION.IS_DISPATCHABLE, 0),
			p_INTERCHANGE_TRANSACTION.TRANSACTION_INTERVAL,
			p_INTERCHANGE_TRANSACTION.EXTERNAL_INTERVAL,
			p_INTERCHANGE_TRANSACTION.ETAG_CODE,
			p_INTERCHANGE_TRANSACTION.BEGIN_DATE,
			p_INTERCHANGE_TRANSACTION.END_DATE,
			NVL(p_INTERCHANGE_TRANSACTION.PURCHASER_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SELLER_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.CONTRACT_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SC_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.POR_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.POD_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.COMMODITY_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SERVICE_TYPE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.TX_TRANSACTION_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.PATH_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.LINK_TRANSACTION_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.EDC_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.PSE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.ESP_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.POOL_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SCHEDULE_GROUP_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.MARKET_PRICE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.ZOR_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.ZOD_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SOURCE_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.SINK_ID, 0),
			NVL(p_INTERCHANGE_TRANSACTION.RESOURCE_ID, 0),
			p_INTERCHANGE_TRANSACTION.AGREEMENT_TYPE,
			p_INTERCHANGE_TRANSACTION.APPROVAL_TYPE,
			p_INTERCHANGE_TRANSACTION.LOSS_OPTION,
			p_INTERCHANGE_TRANSACTION.TRAIT_CATEGORY,
			NVL(p_INTERCHANGE_TRANSACTION.TP_ID,0));
	END IF;
END PUT_TRANSACTION;
-------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_PRICE_VALUE
	(
	p_MARKET_PRICE_ID IN NUMBER,
	p_PRICE_DATE      IN DATE,
	p_PRICE_CODE      IN CHAR,
	p_PRICE           IN NUMBER,
	p_PRICE_BASIS     IN NUMBER,
	p_STATUS          OUT NUMBER,
	p_ERROR_MESSAGE   OUT VARCHAR2
	) AS

	v_AS_OF_DATE DATE;
BEGIN

	p_STATUS              := GA.SUCCESS;
	SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

	IF GA.VERSION_MARKET_PRICE THEN
		v_AS_OF_DATE := SYSDATE;
	ELSE
		v_AS_OF_DATE := LOW_DATE;
	END IF;

	UPDATE MARKET_PRICE_VALUE
		 SET PRICE_BASIS = p_PRICE_BASIS, PRICE = p_PRICE
	 WHERE MARKET_PRICE_ID = p_MARKET_PRICE_ID
		 AND PRICE_CODE = p_PRICE_CODE
		 AND PRICE_DATE = p_PRICE_DATE
		 AND AS_OF_DATE = v_AS_OF_DATE;

	IF SQL%NOTFOUND THEN
		INSERT INTO MARKET_PRICE_VALUE
			(MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
		VALUES
			(p_MARKET_PRICE_ID,
			 p_PRICE_CODE,
			 p_PRICE_DATE,
			 v_AS_OF_DATE,
			 p_PRICE_BASIS,
			 p_PRICE);
	END IF;

	SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

EXCEPTION
	WHEN OTHERS THEN
		SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
		p_STATUS              := SQLCODE;
		p_ERROR_MESSAGE       := SQLERRM;

END PUT_MARKET_PRICE_VALUE;
-------------------------------------------------------------------------------------
PROCEDURE POST_UNCONFIRMED_SCHED_ALARM(p_MARKET IN VARCHAR2, p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE, p_DATE IN DATE) IS
	v_TXN_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
BEGIN
	SELECT TRANSACTION_NAME INTO v_TXN_NAME FROM Interchange_Transaction
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	ALERTS.TRIGGER_ALERTS(g_UNCONFIRMED_BILAT_SCHEDULE, LOGS.c_Level_Notice, 'Unconfirmed schedule for ' || v_TXN_NAME || ' on ' || TO_CHAR(p_DATE, 'YYYY-MM-DD'));
END POST_UNCONFIRMED_SCHED_ALARM;
-------------------------------------------------------------------------------------
PROCEDURE POST_PART_CLEARED_DEMAND_ALERT
	(
	p_TXN_ID      IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
	p_MAX_BID_QTY IN NUMBER,
	p_CLEARED_QTY IN NUMBER,
	p_MARKET_NAME IN VARCHAR2
	) IS

	v_TXN_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;

BEGIN
	SELECT TRANSACTION_NAME
		INTO v_TXN_NAME
		FROM INTERCHANGE_TRANSACTION
	 WHERE TRANSACTION_ID = p_TXN_ID;

	ALERTS.TRIGGER_ALERTS(g_PARTIAL_DEMAND_CLEAR,
		LOGS.c_Level_Notice,
		v_TXN_NAME || 'did not fully clear (cleared qty: ' || p_CLEARED_QTY || ', max bid qty: ' || p_MAX_BID_QTY || ')');

END POST_PART_CLEARED_DEMAND_ALERT;
-------------------------------------------------------------------------------------
FUNCTION GET_MAX_PS_DEMAND
	(
	p_TXN_ID IN NUMBER,
	p_SCHEDULE_DATE IN DATE
	) RETURN NUMBER IS

	v_MAX_BID_QTY NUMBER;
	--WHAT IS THIS FOR?
BEGIN
	SELECT SUM(TRAIT_VAL) /*SUM(QUANTITY)*/
	INTO v_MAX_BID_QTY
	FROM IT_TRAIT_SCHEDULE A
	WHERE TRANSACTION_ID = p_TXN_ID
		AND SCHEDULE_STATE = GA.INTERNAL_STATE
		AND SCHEDULE_DATE = p_SCHEDULE_DATE
		AND TRAIT_GROUP_ID = TG.g_TG_OFFER_CURVE
		AND TRAIT_INDEX = TG.g_TI_OFFER_QUANTITY
	--	AND SET_NUMBER = ??
		AND STATEMENT_TYPE_ID = 0;

	RETURN v_MAX_BID_QTY;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END GET_MAX_PS_DEMAND;
-------------------------------------------------------------------------------------
FUNCTION GET_LOGGER
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_PROCESS_NAME IN VARCHAR2,
	p_EXCHANGE_NAME IN VARCHAR2,
	p_LOG_TYPE IN NUMBER,
	p_TRACE_ON IN NUMBER
	) RETURN MM_LOGGER_ADAPTER IS

BEGIN
	RETURN MEX_SWITCHBOARD.GET_LOGGER(p_EXTERNAL_SYSTEM_ID,
									p_EXTERNAL_ACCOUNT_NAME,
									p_PROCESS_NAME,
									p_EXCHANGE_NAME,
									p_LOG_TYPE,
									p_TRACE_ON);

END GET_LOGGER;
-------------------------------------------------------------------------------------
PROCEDURE INIT_MEX
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_PROCESS_NAME IN VARCHAR2,
	p_EXCHANGE_NAME IN VARCHAR2,
	p_LOG_TYPE IN NUMBER,
	p_TRACE_ON IN NUMBER,
	p_CREDENTIALS OUT MEX_CREDENTIALS,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_IS_PUBLIC	IN BOOLEAN := FALSE
	) AS
BEGIN
	MEX_SWITCHBOARD.INIT_MEX(p_EXTERNAL_SYSTEM_ID,
							p_EXTERNAL_ACCOUNT_NAME,
							p_PROCESS_NAME,
							p_EXCHANGE_NAME,
							p_LOG_TYPE,
							p_TRACE_ON,
							p_CREDENTIALS,
							p_LOGGER,
							p_IS_PUBLIC);

END INIT_MEX;
-------------------------------------------------------------------------------------
PROCEDURE INIT_MEX
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_PROCESS_NAME IN VARCHAR2,
	p_EXCHANGE_NAME IN VARCHAR2,
	p_LOG_TYPE IN NUMBER,
	p_TRACE_ON IN NUMBER,
	p_CREDENTIALS OUT MM_CREDENTIALS_SET,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_IS_PUBLIC	IN BOOLEAN := FALSE
	) AS
BEGIN
	MEX_SWITCHBOARD.INIT_MEX(p_EXTERNAL_SYSTEM_ID,
							 p_PROCESS_NAME,
							 p_EXCHANGE_NAME,
							 p_LOG_TYPE,
							 p_TRACE_ON,
							 p_CREDENTIALS,
							 p_LOGGER,
							 p_IS_PUBLIC);
END INIT_MEX;
-------------------------------------------------------------------------------------
PROCEDURE START_EXCHANGE
	(
	p_IS_IMPORT IN BOOLEAN,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) AS

	v_FULL_ACCESS_FOR_IMPORTS BOOLEAN;

BEGIN
	--Set the IS_INTERFACE flag.
	--  If this is a File Import, check the Dictionary flag for whether we allow full interface access.
	--  Otherwise, always set the flag to TRUE to allow full access for market downloads.
	IF p_IS_IMPORT THEN
		v_FULL_ACCESS_FOR_IMPORTS := NVL(GET_DICTIONARY_VALUE('Full Access For File Imports',0,'MarketExchange'),0) = '1';
		IF v_FULL_ACCESS_FOR_IMPORTS THEN
			SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
		END IF;
	ELSE
		SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
	END IF;

	--Start the logger
	p_LOGGER.LOG_START;

END START_EXCHANGE;
---------------------------------------------------------------------------------------
PROCEDURE STOP_EXCHANGE
	(
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_IN_STATUS IN NUMBER,
	p_IN_MESSAGE IN VARCHAR2,
	p_RETURN_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	-- Turn off the IS_INTERFACE flag.
	SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

	p_LOGGER.LOG_STOP(p_IN_STATUS, p_IN_MESSAGE);
	p_RETURN_MESSAGE := p_LOGGER.GET_END_MESSAGE;

END STOP_EXCHANGE;
-----------------------------------------------------------------------------------------------------

FUNCTION GET_EXT_ACCOUNT_FOR_TXN
	(
	p_TRANSACTION_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER
	) RETURN VARCHAR2 IS
v_CONTRACT_ID NUMBER;
BEGIN
	SELECT CONTRACT_ID
	INTO v_CONTRACT_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_INTERCHANGE_CONTRACT, v_CONTRACT_ID, p_EXTERNAL_SYSTEM_ID);

END GET_EXT_ACCOUNT_FOR_TXN;
---------------------------------------------------------------------------------
FUNCTION DETERMINE_STATEMENT_TYPE
	(
	   p_REPORT_STATEMENT_TYPE IN VARCHAR2,
       p_VERSION_NUMBER IN VARCHAR,
	   p_EXTERNAL_SYSTEM_ID IN NUMBER,
	   p_EXTERNAL_SYS_IDENTIFIER_TYPE IN VARCHAR2 := EI.g_DEFAULT_IDENTIFIER_TYPE,
	   p_STATEMENT_TYPE_NAME_PREFIX IN VARCHAR2 := NULL
	) RETURN NUMBER IS

v_IDs NUMBER_COLLECTION;
v_STATEMENT_TYPE_ORDER STATEMENT_TYPE.STATEMENT_TYPE_ORDER%TYPE;
v_STATEMENT_TYPE_ID STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE := 0;
v_STATEMENT_TYPE_NAME STATEMENT_TYPE.STATEMENT_TYPE_NAME%TYPE;
v_STATEMENT_TYPE_AND_VERSION VARCHAR(64);

BEGIN
    IF p_VERSION_NUMBER IS NULL THEN
       v_STATEMENT_TYPE_AND_VERSION := p_REPORT_STATEMENT_TYPE;
    ELSE
       v_STATEMENT_TYPE_AND_VERSION := p_REPORT_STATEMENT_TYPE || '(' || p_VERSION_NUMBER || ')';
    END IF;

    -- no statement type specified?
    -- then look it up by external identifier using report's type
    v_IDs := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(v_STATEMENT_TYPE_AND_VERSION, EC.ED_STATEMENT_TYPE, p_EXTERNAL_SYSTEM_ID, p_EXTERNAL_SYS_IDENTIFIER_TYPE);

    --Create statement type dynamically
    IF v_IDs.COUNT = 0 THEN
         -- Statement type name
         IF p_REPORT_STATEMENT_TYPE = 'F' THEN
            v_STATEMENT_TYPE_NAME := p_STATEMENT_TYPE_NAME_PREFIX || 'Revision #' || p_VERSION_NUMBER;
         ELSIF p_REPORT_STATEMENT_TYPE = 'P' THEN
            v_STATEMENT_TYPE_NAME := p_STATEMENT_TYPE_NAME_PREFIX || 'Indicative (#' || p_VERSION_NUMBER || ')';
         END IF;

         -- Get Statement type order
		 BEGIN
			SELECT S.STATEMENT_TYPE_ORDER + TO_NUMBER(p_VERSION_NUMBER)
			INTO   v_STATEMENT_TYPE_ORDER
			FROM   STATEMENT_TYPE S, EXTERNAL_SYSTEM_IDENTIFIER E
			WHERE  E.ENTITY_ID = S.STATEMENT_TYPE_ID
				   AND E.IDENTIFIER_TYPE = p_EXTERNAL_SYS_IDENTIFIER_TYPE
				   AND E.EXTERNAL_IDENTIFIER = p_REPORT_STATEMENT_TYPE
				   AND E.EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;

		 EXCEPTION
		 	WHEN OTHERS THEN
			 	RAISE_APPLICATION_ERROR(-20000,'No statement type exists for code '''||p_REPORT_STATEMENT_TYPE||'''');
		 END;

		 -- Create Statement type
		 IO.PUT_STATEMENT_TYPE(v_STATEMENT_TYPE_ID, v_STATEMENT_TYPE_NAME, v_STATEMENT_TYPE_NAME, v_STATEMENT_TYPE_NAME, 0, v_STATEMENT_TYPE_ORDER);

		 IF v_STATEMENT_TYPE_ID < 0 THEN
		 	RAISE_APPLICATION_ERROR(-20000,'Failed to create statement type for code '''||v_STATEMENT_TYPE_AND_VERSION||''' (status = '||v_STATEMENT_TYPE_ID||')');
		 END IF;

         -- Add the external identifier for statement type
         EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(p_EXTERNAL_SYSTEM_ID, EC.ED_STATEMENT_TYPE, v_STATEMENT_TYPE_ID, v_STATEMENT_TYPE_AND_VERSION, p_EXTERNAL_SYS_IDENTIFIER_TYPE);

		 -- Add the external identifier for market schedules
		 IF p_EXTERNAL_SYSTEM_ID = EC.ES_SEM THEN
	         EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(p_EXTERNAL_SYSTEM_ID, EC.ED_STATEMENT_TYPE,
			 		v_STATEMENT_TYPE_ID, 'Initial Ex-Post ' || v_STATEMENT_TYPE_AND_VERSION, NULL); --@@ MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);
         END IF;
		 RETURN v_STATEMENT_TYPE_ID;
    ELSE
       RETURN v_IDs(v_IDs.FIRST);
    END IF;

END DETERMINE_STATEMENT_TYPE;
---------------------------------------------------------------------------------
END MM_UTIL;
/

