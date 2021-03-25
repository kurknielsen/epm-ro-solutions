CREATE OR REPLACE PACKAGE BODY MM_PJM_ERPM IS


---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
     RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------
FUNCTION ID_FOR_SERVICE_ZONE
	(
	p_ZONE_NAME IN VARCHAR2
	) RETURN NUMBER AS
v_ID NUMBER(9);
BEGIN
	SELECT A.SERVICE_ZONE_ID
	INTO v_ID
	FROM SERVICE_ZONE A
	WHERE A.SERVICE_ZONE_ALIAS= p_ZONE_NAME
		AND ROWNUM = 1;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_ID := 0;
		RETURN v_ID;
END ID_FOR_SERVICE_ZONE;
-------------------------------------------------------------------------------------------------------
FUNCTION GET_TX_ID
  (
  p_EXT_ID IN VARCHAR2,
  p_TRANS_TYPE IN VARCHAR2 := 'Market Result',
  p_NAME IN VARCHAR2 := NULL,
  p_INTERVAL IN VARCHAR2 := 'Hour',
  p_COMMODITY_ID IN NUMBER := 0,
  p_CONTRACT_ID IN NUMBER := 0,
  p_ZOD_ID IN NUMBER := 0,
  p_SERVICE_POINT_ID IN NUMBER := 0,
  p_POOL_ID IN NUMBER := 0,
  p_SELLER_ID IN NUMBER := 0
  ) RETURN NUMBER IS

  v_ID NUMBER;
  v_SC NUMBER(9);
  v_SUFFIX VARCHAR2(32) := '';
  v_TMP VARCHAR2(32);
  v_NAME VARCHAR2(64);
  v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
  v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

BEGIN
	IF p_EXT_ID IS NULL THEN
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_TYPE = p_TRANS_TYPE
            AND CONTRACT_ID = p_CONTRACT_ID
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID)
            AND (p_ZOD_ID = 0 OR ZOD_ID = p_ZOD_ID);
	ELSE
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_IDENTIFIER = p_EXT_ID
            AND (p_CONTRACT_ID = 0 OR CONTRACT_ID = p_CONTRACT_ID)
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID)
            AND (p_ZOD_ID = 0 OR ZOD_ID = p_ZOD_ID);
	END IF;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_NAME := NVL(p_NAME,p_EXT_ID);

        SELECT SC_ID
        INTO v_SC
        FROM SCHEDULE_COORDINATOR
        WHERE SC_NAME = 'PJM';

		IF p_CONTRACT_ID <> 0 THEN
    	    SELECT ': '||CONTRACT_NAME
	        INTO v_TMP
	        FROM INTERCHANGE_CONTRACT
	        WHERE CONTRACT_ID = p_CONTRACT_ID;
			v_SUFFIX := v_SUFFIX||v_TMP;
		END IF;
        IF p_SELLER_ID <> 0 THEN
    	    SELECT ': '||PSE_NAME
	        INTO v_TMP
	        FROM PURCHASING_SELLING_ENTITY
	        WHERE PSE_ID = p_SELLER_ID;
			v_SUFFIX := v_SUFFIX||v_TMP;
        END IF;
        IF p_POOL_ID <> 0 THEN
    	    SELECT ': '||POOL_NAME
	        INTO v_TMP
	        FROM POOL
	        WHERE POOL_ID = p_POOL_ID;
			v_SUFFIX := v_SUFFIX||v_TMP;
        END IF;
        IF p_SERVICE_POINT_ID <> 0 THEN
    	    SELECT ': '||SERVICE_POINT_NAME
	        INTO v_TMP
	        FROM SERVICE_POINT
	        WHERE SERVICE_POINT_ID = p_SERVICE_POINT_ID;
			v_SUFFIX := v_SUFFIX||v_TMP;
        END IF;
	--create the transaction
    	v_TRANSACTION.TRANSACTION_ID := 0;
        v_TRANSACTION.TRANSACTION_NAME := SUBSTR(v_NAME||v_SUFFIX,1,64);
        v_TRANSACTION.TRANSACTION_ALIAS := SUBSTR(v_NAME||v_SUFFIX,1,32);
        v_TRANSACTION.TRANSACTION_DESC := v_NAME||v_SUFFIX;
        v_TRANSACTION.TRANSACTION_TYPE := p_TRANS_TYPE;
        v_TRANSACTION.TRANSACTION_IDENTIFIER := p_EXT_ID;
        v_TRANSACTION.TRANSACTION_INTERVAL := p_INTERVAL;
        v_TRANSACTION.BEGIN_DATE := TO_DATE('1/1/2000','MM/DD/YYYY');
        v_TRANSACTION.END_DATE := TO_DATE('12/31/2020','MM/DD/YYYY');
        v_TRANSACTION.SELLER_ID := p_SELLER_ID;
        v_TRANSACTION.CONTRACT_ID := p_CONTRACT_ID;
        v_TRANSACTION.SC_ID := v_SC;
        v_TRANSACTION.POD_ID := p_SERVICE_POINT_ID;
        v_TRANSACTION.POOL_ID := p_POOL_ID;
        v_TRANSACTION.ZOD_ID := p_ZOD_ID;
        v_TRANSACTION.COMMODITY_ID := p_COMMODITY_ID;

		MM_UTIL.PUT_TRANSACTION(v_TRANSACTION_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');

		RETURN v_TRANSACTION_ID;
END GET_TX_ID;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULE_VALUE
  (
  p_TX_ID IN NUMBER,
  p_SCHED_DATE IN DATE,
  p_AMOUNT NUMBER,
  p_PRICE NUMBER := NULL,
  p_TO_INTERNAL BOOLEAN := TRUE
  ) AS

v_STATUS NUMBER;
v_IDX BINARY_INTEGER;

BEGIN

	FOR v_IDX IN 1..MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
		IF p_TO_INTERNAL THEN
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                               p_SCHEDULE_TYPE => MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(v_IDX),
                               p_SCHEDULE_STATE => 1,
                               p_SCHEDULE_DATE => p_SCHED_DATE,
                               p_AS_OF_DATE => SYSDATE,
                               p_AMOUNT => p_AMOUNT,
                               p_PRICE => p_PRICE,
                               p_STATUS => v_STATUS);
		END IF;
        ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                           p_SCHEDULE_TYPE => MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(v_IDX),
                           p_SCHEDULE_STATE => 2,
                           p_SCHEDULE_DATE => p_SCHED_DATE,
                           p_AS_OF_DATE => SYSDATE,
                           p_AMOUNT => p_AMOUNT,
                           p_PRICE => p_PRICE,
                           p_STATUS => v_STATUS);
	END LOOP;

END PUT_SCHEDULE_VALUE;
---------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NETWK_SERV_PK_LD
	(
	p_RECORDS IN MEX_PJM_ECAP_LOAD_OBL_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2) AS

v_INDEX BINARY_INTEGER;
v_ZONE_NAME VARCHAR2(16);
v_COMMODITY_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_TRANSACTION_ID NUMBER(9);
v_ZOD_ID NUMBER(9);

BEGIN
	p_STATUS  := GA.SUCCESS;
	IF p_RECORDS.COUNT = 0 THEN
      RETURN;
    END IF;

    SELECT COMMODITY_ID INTO v_COMMODITY_ID
    FROM IT_COMMODITY WHERE COMMODITY_NAME = 'RealTime Energy';

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP
        --v_ZONE_NAME := p_RECORDS(v_INDEX).LOADZONEAREA;
        v_ZONE_NAME := p_RECORDS(v_INDEX).ZONEAREA;
        v_ZOD_ID := ID_FOR_SERVICE_ZONE(v_ZONE_NAME);

        SELECT CONTRACT_ID INTO v_CONTRACT_ID
        FROM INTERCHANGE_CONTRACT
        WHERE CONTRACT_ALIAS = p_RECORDS(v_INDEX).COMPANYSELECTED || ': PJM';

        v_TRANSACTION_ID := GET_TX_ID(v_ZONE_NAME || ':Coincident Peak Load:'
        								|| p_RECORDS(v_INDEX).COMPANYSELECTED,
                                        'Coincident Pk Ld', NULL, 'Day',
                                        v_COMMODITY_ID, v_CONTRACT_ID,
                                        v_ZOD_ID);


        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
        				 	p_RECORDS(v_INDEX).LOADDATE + + 1/86400,
                            p_RECORDS(v_INDEX).NSPL);

        v_INDEX := p_RECORDS.NEXT(v_INDEX);
    END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN IMPORT_NETWORK_SERV_PEAK_LD ' ||
                                    UT.GET_FULL_ERRM;
END IMPORT_NETWK_SERV_PK_LD;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CAPACITY_OBLIGATION
	(
	p_RECORDS IN MEX_PJM_ECAP_LOAD_OBL_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2) AS

v_INDEX BINARY_INTEGER;
v_ZONE_NAME VARCHAR2(16);
v_COMMODITY_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_TRANSACTION_ID NUMBER(9);
v_ZOD_ID NUMBER(9);
BEGIN
	p_STATUS  := GA.SUCCESS;
	IF p_RECORDS.COUNT = 0 THEN
      RETURN;
    END IF;

    SELECT COMMODITY_ID INTO v_COMMODITY_ID
    FROM IT_COMMODITY WHERE COMMODITY_NAME = 'Capacity';

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP
        v_ZONE_NAME := p_RECORDS(v_INDEX).ZONEAREA;
        v_ZOD_ID := ID_FOR_SERVICE_ZONE(v_ZONE_NAME);

        SELECT CONTRACT_ID INTO v_CONTRACT_ID
        FROM INTERCHANGE_CONTRACT
        WHERE CONTRACT_ALIAS = p_RECORDS(v_INDEX).COMPANYSELECTED || ': PJM';

        v_TRANSACTION_ID := GET_TX_ID(v_ZONE_NAME || ':Capacity Obligation:'
        								|| p_RECORDS(v_INDEX).COMPANYSELECTED,
                                        'Obligation', NULL, 'Day',
                                        v_COMMODITY_ID, v_CONTRACT_ID,
                                        v_ZOD_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
        				 	p_RECORDS(v_INDEX).LOADDATE + + 1/86400,
                            p_RECORDS(v_INDEX).OBLIGATION);

        v_INDEX := p_RECORDS.NEXT(v_INDEX);
    END LOOP;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS                   := SQLCODE;
      p_MESSAGE            := 'ERROR OCCURED IN IMPORT_CAPACITY_OBLIGATION ' ||
                                    UT.GET_FULL_ERRM;
END IMPORT_CAPACITY_OBLIGATION;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NETWK_SERV_PK_LD
(
    p_CRED       IN mex_credentials,
    p_LOG_ONLY   IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2,
    p_LOGGER     IN OUT mm_logger_adapter
) AS
    v_RECORDS    MEX_PJM_ECAP_LOAD_OBL_TBL;
    v_BEGIN_DATE DATE;
BEGIN

    p_STATUS := GA.SUCCESS;
    --**check for esuite access
    v_BEGIN_DATE := p_BEGIN_DATE;
    WHILE v_BEGIN_DATE <= p_END_DATE LOOP
        MEX_PJM_ERPM.FETCH_NETWK_SERV_PK_LD(p_CRED,
                                            p_LOG_ONLY,
                                            v_BEGIN_DATE,
											p_CRED.EXTERNAL_ACCOUNT_NAME,
                                            v_RECORDS,
                                            p_STATUS,
                                            p_MESSAGE,
                                            p_LOGGER);

        IF p_STATUS = GA.SUCCESS THEN
            IMPORT_NETWK_SERV_PK_LD(v_RECORDS, p_STATUS, p_MESSAGE);
        END IF;
        --NSPL download is always for start_date through start_date + 4
        v_BEGIN_DATE := v_BEGIN_DATE + 5;
    END LOOP;
END IMPORT_NETWK_SERV_PK_LD;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CAPACITY_OBLIGATION
(
    p_CRED       IN mex_credentials,
    p_LOG_ONLY   IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2,
    p_LOGGER     IN OUT mm_logger_adapter
) AS
    v_RECORDS    MEX_PJM_ECAP_LOAD_OBL_TBL;
    v_BEGIN_DATE DATE;
BEGIN

    p_STATUS := GA.SUCCESS;
    --**check for esuite access
    v_BEGIN_DATE := p_BEGIN_DATE;
    WHILE v_BEGIN_DATE <= p_END_DATE LOOP
		MEX_PJM_ERPM.FETCH_CAPACITY_OBLIGATION(p_CRED,
                                               p_LOG_ONLY,
                                               v_BEGIN_DATE,
                                               p_CRED.EXTERNAL_ACCOUNT_NAME,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE,
                                               p_LOGGER);

        IF p_STATUS = GA.SUCCESS THEN
            IMPORT_CAPACITY_OBLIGATION(v_RECORDS, p_STATUS, p_MESSAGE);
        END IF;
        --Capacity download is always for start_date through start_date + 4?
        v_BEGIN_DATE := v_BEGIN_DATE + 5;
    END LOOP;
END IMPORT_CAPACITY_OBLIGATION;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

v_CREDS mm_credentials_set;
v_CRED 	mex_credentials;
v_LOGGER mm_logger_adapter;
v_LOG_ONLY NUMBER;

BEGIN

	v_LOG_ONLY := NVL(p_LOG_ONLY, 0);

	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_PJM,
		p_PROCESS_NAME => 'PJM:ERPM',
		p_EXCHANGE_NAME => p_EXCHANGE_TYPE,
		p_LOG_TYPE => p_LOG_TYPE,
		p_TRACE_ON => p_TRACE_ON,
		p_CREDENTIALS => v_CREDS,
		p_LOGGER => v_LOGGER);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	WHILE v_CREDS.HAS_NEXT LOOP
		v_CRED := v_CREDS.GET_NEXT;
		CASE p_EXCHANGE_TYPE
			WHEN g_ET_QUERY_NSPL THEN
				IMPORT_NETWK_SERV_PK_LD(v_CRED, v_LOG_ONLY, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE, v_LOGGER);
			WHEN g_ET_QUERY_CAPACITY_OBLIG THEN
				IMPORT_CAPACITY_OBLIGATION(v_CRED, v_LOG_ONLY, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE, v_LOGGER);
			ELSE
				p_STATUS := -1;
				p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
				v_LOGGER.LOG_ERROR(p_MESSAGE);
				EXIT;
		END CASE;
	END LOOP;
	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := UT.GET_FULL_ERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
--------------------------------------------------------------------------------------------------
END MM_PJM_ERPM;
/
