CREATE OR REPLACE PACKAGE MM_PJM_OASIS IS
   -- $Revision: 1.9 $
  -- Author  : AHUSSAIN
  -- Created : 9/21/2006 4:22:10 PM
  -- Purpose :
   TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE MARKET_EXCHANGE
   (
   p_BEGIN_DATE               IN DATE,
   p_END_DATE                 IN DATE,
   p_EXCHANGE_TYPE           IN VARCHAR2,
   p_ENTITY_LIST              IN VARCHAR2,
   p_ENTITY_LIST_DELIMITER    IN CHAR,
   p_LOG_ONLY               IN NUMBER :=0,
   p_LOG_TYPE                IN NUMBER,
   p_TRACE_ON                IN NUMBER,
   p_STATUS                   OUT NUMBER,
   p_MESSAGE                  OUT VARCHAR2);

PROCEDURE LOAD_FORECAST_REPORT
    (
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_TIME_ZONE IN VARCHAR2,
   p_STATEMENT_TYPE IN NUMBER,
   p_LAST_UPDATE_DATE OUT DATE,
   p_STATUS OUT NUMBER,
   p_CURSOR IN OUT REF_CURSOR
   );

PROCEDURE GET_LAST_UPDATE_DATE(p_LAST_UPDATE_DATE OUT DATE);

  g_ET_QUERY_LOAD_FORECAST VARCHAR2(20) := 'Query Load Forecast';
  g_ET_QUERY_OP_RESV_RATES VARCHAR2(20) := 'Query OP Resv Rates';

END MM_PJM_OASIS;
/
CREATE OR REPLACE PACKAGE BODY MM_PJM_OASIS IS

  g_PJM_SC_ID SC.SC_ID%TYPE;
  ----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_IT_TRANSACTION_ID(p_ZONE IN VARCHAR2,
                                p_TRANSACTION_ID OUT INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE) IS

    v_SERVICE_ZONE_NAME  SERVICE_ZONE.SERVICE_ZONE_NAME%TYPE;
    v_SERVICE_ZONE_ID    SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
	v_SERVICE_ZONE_ALIAS SERVICE_ZONE.SERVICE_ZONE_ALIAS%TYPE;
	v_COMMODITY_ID       IT_COMMODITY.COMMODITY_ID%TYPE;
	v_INTERVAL           INTERCHANGE_TRANSACTION.TRANSACTION_INTERVAL%TYPE;
    v_TRANSACTION        INTERCHANGE_TRANSACTION%ROWTYPE;

BEGIN

    v_INTERVAL := 'Hour';
    -- Set the zone to 'PJM' for 'RTO Combined' load forecast
    IF UPPER(p_ZONE) = 'RTO COMBINED' THEN
       v_SERVICE_ZONE_ALIAS := 'PJM';
    ELSE
	   v_SERVICE_ZONE_ALIAS := UPPER(p_ZONE);
    END IF;

     -- we need the commodity_id , if no record add one
    v_COMMODITY_ID := MM_PJM_UTIL.GET_COMMODITY_ID(MM_PJM_UTIL.g_COMM_DA_ENERGY);
    IF v_COMMODITY_ID = -1 THEN
    	v_COMMODITY_ID := 0;
    END IF;

    BEGIN -- transaction zone lookup

      SELECT ITT.TRANSACTION_ID
      INTO p_TRANSACTION_ID
      FROM INTERCHANGE_TRANSACTION ITT, SERVICE_ZONE SZ
      WHERE SZ.SERVICE_ZONE_ALIAS = v_SERVICE_ZONE_ALIAS
      AND SZ.SERVICE_ZONE_ID = ITT.ZOD_ID
      AND ITT.TRANSACTION_INTERVAL = v_INTERVAL
      AND ITT.COMMODITY_ID = v_COMMODITY_ID
      AND ITT.TRANSACTION_TYPE = 'Load'
      AND SC_ID = g_PJM_SC_ID;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN

      BEGIN -- add new transaction

        BEGIN -- lookup service zone

          SELECT SZ.SERVICE_ZONE_NAME, SZ.SERVICE_ZONE_ID
          INTO v_SERVICE_ZONE_NAME, v_SERVICE_ZONE_ID
          FROM SERVICE_ZONE SZ
          WHERE SZ.SERVICE_ZONE_ALIAS = v_SERVICE_ZONE_ALIAS;
        EXCEPTION
          WHEN OTHERS THEN
          IO.PUT_SERVICE_ZONE(v_SERVICE_ZONE_ID,
                              v_SERVICE_ZONE_ALIAS,
                              v_SERVICE_ZONE_ALIAS,
                              'PJM Load Forecast Zone',
							  0,
							  NULL,
                              0,
                              0,
							  NULL);
         END;

        -- Use the service zone when creating the transaction
        IF v_SERVICE_ZONE_ID IS NOT NULL THEN
          v_TRANSACTION.TRANSACTION_ID := 0;
          v_TRANSACTION.TRANSACTION_NAME := UPPER(p_ZONE) || ' Forecast Load';
          v_TRANSACTION.TRANSACTION_ALIAS := UPPER(p_ZONE) || ' Forecast Load';
          v_TRANSACTION.TRANSACTION_DESC := 'Created by MarketManager on ' || UT.TRACE_DATE(SYSDATE) || ' via Load Forecast import.';
          v_TRANSACTION.TRANSACTION_TYPE := 'Load';
          v_TRANSACTION.TRANSACTION_INTERVAL := v_INTERVAL;
          v_TRANSACTION.SC_ID := g_PJM_SC_ID;
          v_TRANSACTION.COMMODITY_ID := v_COMMODITY_ID;
          v_TRANSACTION.ZOD_ID := v_SERVICE_ZONE_ID;
          v_TRANSACTION.BEGIN_DATE := TO_DATE('01/01/2000','MM/DD/YYYY');
          v_TRANSACTION.END_DATE := TO_DATE('01/01/2020','MM/DD/YYYY');

          MM_UTIL.PUT_TRANSACTION(p_TRANSACTION_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');
          COMMIT;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          -- no transaction
          p_TRANSACTION_ID := NULL;
      END;

  END;

END GET_IT_TRANSACTION_ID;
  ----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOAD_FORECAST(p_RECORDS     IN MEX_PJM_LOAD_TBL,
                                             p_STATUS      OUT NUMBER,
                                             p_MESSAGE     OUT VARCHAR2) IS
  v_IDX                   BINARY_INTEGER;
  v_LOAD_FORECAST_IDX     BINARY_INTEGER;
  v_LOADS                 MEX_SCHEDULE_TBL;
  v_TRANSACTION_ID        INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

BEGIN
    p_STATUS        := GA.SUCCESS;
    v_IDX := p_RECORDS.FIRST;
    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        GET_IT_TRANSACTION_ID(p_RECORDS(v_IDX).ZONE_NAME, v_TRANSACTION_ID);

      IF v_TRANSACTION_ID IS NOT NULL THEN
        v_LOADS    := p_RECORDS(v_IDX).SCHEDULES;
        v_LOAD_FORECAST_IDX := v_LOADS.FIRST;

        WHILE v_LOADS.EXISTS(v_LOAD_FORECAST_IDX) LOOP
          ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TRANSACTION_ID,
                             p_SCHEDULE_TYPE => 1,
                             p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                             p_SCHEDULE_DATE => v_LOADS(v_LOAD_FORECAST_IDX).CUT_TIME,
                             p_AS_OF_DATE => LOW_DATE,
                             p_AMOUNT => v_LOADS(v_LOAD_FORECAST_IDX).VOLUME,
                             p_PRICE => v_LOADS(v_LOAD_FORECAST_IDX).RATE,
                             p_STATUS => p_STATUS);
          v_LOAD_FORECAST_IDX := v_LOADS.NEXT(v_LOAD_FORECAST_IDX);
        END LOOP;
      END IF;

      v_IDX := p_RECORDS.NEXT(v_IDX);
    END LOOP;

    IF p_STATUS = GA.SUCCESS THEN
      COMMIT;
    END IF;

EXCEPTION
  WHEN OTHERS THEN
    P_STATUS  := SQLCODE;
    P_MESSAGE := 'MM_PJM_OASIS.IMPORT_LOAD_FORECAST: ' || UT.GET_FULL_ERRM;
END IMPORT_LOAD_FORECAST;
  ----------------------------------------------------------------------------------------------------
  PROCEDURE QUERY_LOAD_FORECAST(p_CRED   IN mex_credentials,
  								p_LOG_ONLY	IN NUMBER,
  								p_STATUS OUT NUMBER,
								p_MESSAGE OUT VARCHAR2,
								p_LOGGER IN OUT mm_logger_adapter) IS
	v_LOAD_FORECAST_TBL MEX_PJM_LOAD_TBL;
  BEGIN
    p_STATUS           := GA.SUCCESS;
    -- get all the PJM creds, but only use the first one (we only need this for
    -- the proxy login information)

    MEX_PJM_OASIS.FETCH_LOAD_FORECAST(p_CRED,
									  p_LOG_ONLY,
                               	      v_LOAD_FORECAST_TBL,
                               	      p_STATUS,
                               	      p_MESSAGE,
									  p_LOGGER);

    IF p_STATUS = GA.SUCCESS THEN
      IMPORT_LOAD_FORECAST(v_LOAD_FORECAST_TBL, p_STATUS, p_MESSAGE);

      -- update last downloaded date
      PUT_DICTIONARY_VALUE('LastUpdate', TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI'), 1, 'MarketExchange', 'PJM', 'OASIS', 'LoadForecast');
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_MESSAGE := UT.GET_FULL_ERRM;
      p_STATUS  := SQLCODE;
  END QUERY_LOAD_FORECAST;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_LAST_UPDATE_DATE(p_LAST_UPDATE_DATE OUT DATE) IS
   v_DATE_STR VARCHAR2(64);
BEGIN
     v_DATE_STR := GET_DICTIONARY_VALUE('LastUpdate', 1, 'MarketExchange', 'PJM', 'OASIS', 'LoadForecast');
     p_LAST_UPDATE_DATE := TO_DATE(NVL(v_DATE_STR, '01/01/1900 00:00'), 'MM/DD/YYYY HH24:MI');
END GET_LAST_UPDATE_DATE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RESV_RATES_REG(p_RECORDS IN MEX_PJM_OP_RES_RATES_TBL) IS
v_IDX      BINARY_INTEGER;
v_DA_MKT_PR_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_RTO_REL_MKT_PR_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_RTO_DEV_MKT_PR_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_EAST_REL_MKT_PR_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_EAST_DEV_MKT_PR_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_WEST_REL_MKT_PR_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_WEST_DEV_MKT_PR_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;

	-------------------------------------------------
    FUNCTION GET_PRICE_ID(p_MKT_PRICE_NAME IN VARCHAR2) RETURN NUMBER IS

        v_PRICE_ID     MARKET_PRICE.MARKET_PRICE_ID%TYPE;
        v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
        v_PJM_SC_ID    SCHEDULE_COORDINATOR.SC_ID%TYPE;
        v_MARKET_TYPE  MARKET_PRICE.MARKET_TYPE%TYPE;
    BEGIN

        ID.ID_FOR_SC('PJM', FALSE, v_PJM_SC_ID);

        ID.ID_FOR_MARKET_PRICE_EXT_IDENT(p_MKT_PRICE_NAME, v_PRICE_ID);

		IF v_PRICE_ID <= 0 THEN
           IF INSTR(p_MKT_PRICE_NAME, 'DA') > 0 THEN
                ID.ID_FOR_COMMODITY('DayAhead Energy', FALSE, v_COMMODITY_ID);
                v_MARKET_TYPE := 'DayAhead';
            ELSE
                ID.ID_FOR_COMMODITY('RealTime Energy', FALSE, v_COMMODITY_ID);
                v_MARKET_TYPE := 'RealTime';
            END IF;
            IO.PUT_MARKET_PRICE(o_OID                   => v_PRICE_ID,
                                p_MARKET_PRICE_NAME     => p_MKT_PRICE_NAME,
                                p_MARKET_PRICE_ALIAS    => '?',
                                p_MARKET_PRICE_DESC     => '?',
                                p_MARKET_PRICE_ID       => 0,
                                p_MARKET_PRICE_TYPE     => 'Market Result',
                                p_MARKET_PRICE_INTERVAL => 'Day',
                                p_MARKET_TYPE           => v_MARKET_TYPE,
                                p_COMMODITY_ID          => v_COMMODITY_ID,
                                p_SERVICE_POINT_TYPE    => NULL,
                                p_EXTERNAL_IDENTIFIER   => p_MKT_PRICE_NAME,
                                p_EDC_ID                => 0,
                                p_SC_ID                 => v_PJM_SC_ID,
                                p_POD_ID                => 0,
                                p_ZOD_ID                => 0);
        END IF;
        RETURN v_PRICE_ID;
    END GET_PRICE_ID;
	------------------------------------------------
	PROCEDURE PUT_MARKET_PRICE_VALUE
	(
		p_MARKET_PRICE_ID IN NUMBER,
		p_PRICE_DATE      IN DATE,
		p_PRICE           IN NUMBER
	) AS


	BEGIN
		IF p_MARKET_PRICE_ID IS NULL OR p_MARKET_PRICE_ID < 0 THEN
			RETURN;
		END IF;

		MERGE INTO MARKET_PRICE_VALUE A
		USING (SELECT p_MARKET_PRICE_ID MARKET_PRICE_ID, p_PRICE_DATE PRICE_DATE FROM DUAL) B
		ON (A.MARKET_PRICE_ID = B.MARKET_PRICE_ID AND A.PRICE_CODE = 'A' AND A.PRICE_DATE = B.PRICE_DATE)
		WHEN MATCHED THEN
			UPDATE SET A.PRICE = p_PRICE
		WHEN NOT MATCHED THEN
			INSERT (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE)
			VALUES (p_MARKET_PRICE_ID, 'A', p_PRICE_DATE, LOW_DATE, p_PRICE);

	END PUT_MARKET_PRICE_VALUE;
	--------------------------------------------
BEGIN

	v_DA_MKT_PR_ID := GET_PRICE_ID('PJM DA OpResv Rate');
	v_RTO_REL_MKT_PR_ID := GET_PRICE_ID('PJM RT RTO OpResv Reliability Rate');
	v_RTO_DEV_MKT_PR_ID := GET_PRICE_ID('PJM RT RTO OpResv Deviations Rate');
	v_EAST_REL_MKT_PR_ID := GET_PRICE_ID('PJM RT East OpResv Reliability Rate');
	v_EAST_DEV_MKT_PR_ID := GET_PRICE_ID('PJM RT East OpResv Deviations Rate');
	v_WEST_REL_MKT_PR_ID := GET_PRICE_ID('PJM RT West OpResv Reliability Rate');
	v_WEST_DEV_MKT_PR_ID := GET_PRICE_ID('PJM RT West OpResv Deviations Rate');

	v_IDX := p_RECORDS.FIRST;
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP

		PUT_MARKET_PRICE_VALUE(v_DA_MKT_PR_ID, p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).DA_RATE);
		PUT_MARKET_PRICE_VALUE(v_RTO_REL_MKT_PR_ID, p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).RTO_RELIABILITY_RATE);
		PUT_MARKET_PRICE_VALUE(v_RTO_DEV_MKT_PR_ID, p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).RTO_DEVIATION_RATE);
		PUT_MARKET_PRICE_VALUE(v_EAST_REL_MKT_PR_ID, p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).EAST_RELIABILITY_RATE);
		PUT_MARKET_PRICE_VALUE(v_EAST_DEV_MKT_PR_ID, p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).EAST_DEVIATION_RATE);
		PUT_MARKET_PRICE_VALUE(v_WEST_REL_MKT_PR_ID, p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).WEST_RELIABILITY_RATE);
		PUT_MARKET_PRICE_VALUE(v_WEST_DEV_MKT_PR_ID, p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).WEST_DEVIATION_RATE);

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

END IMPORT_OP_RESV_RATES_REG;
-----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RESV_RATES(p_RECORDS     IN PRICE_QUANTITY_SUMMARY_TABLE,
															 p_MARKET_TYPE IN VARCHAR2) IS
	v_IDX      BINARY_INTEGER;
	v_PRICE_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
	v_STATUS NUMBER;
	v_MESSAGE VARCHAR2(256);
	FUNCTION GET_PRICE_ID RETURN MARKET_PRICE.MARKET_PRICE_ID%TYPE IS
		v_PRICE_NAME   VARCHAR2(64);
		v_PRICE_ID     MARKET_PRICE.MARKET_PRICE_ID%TYPE;
		v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
		v_PJM_SC_ID    SCHEDULE_COORDINATOR.SC_ID%TYPE;
	BEGIN
		v_PRICE_NAME := 'PJM ' || p_MARKET_TYPE || ' OpResv Rate';
		ID.ID_FOR_MARKET_PRICE_EXT_IDENT(v_PRICE_NAME, v_PRICE_ID);
		IF v_PRICE_ID <= 0 THEN
			ID.ID_FOR_SC('PJM', FALSE, v_PJM_SC_ID);
			IF p_MARKET_TYPE = 'DA' THEN
				ID.ID_FOR_COMMODITY('DayAhead Energy', FALSE, v_COMMODITY_ID);
			ELSE
				ID.ID_FOR_COMMODITY('RealTime Energy', FALSE, v_COMMODITY_ID);
			END IF;
			IO.PUT_MARKET_PRICE(o_OID                   => v_PRICE_ID,
													p_MARKET_PRICE_NAME     => v_PRICE_NAME,
													p_MARKET_PRICE_ALIAS    => '?',
													p_MARKET_PRICE_DESC     => '?',
													p_MARKET_PRICE_ID       => 0,
													p_MARKET_PRICE_TYPE     => 'Market Result',
													p_MARKET_PRICE_INTERVAL => 'Day',
													p_MARKET_TYPE           => CASE p_MARKET_TYPE WHEN 'DA' THEN 'DayAhead' ELSE 'RealTime' END,
													p_COMMODITY_ID          => v_COMMODITY_ID,
													p_SERVICE_POINT_TYPE    => NULL,
													p_EXTERNAL_IDENTIFIER   => v_PRICE_NAME,
													p_EDC_ID                => 0,
													p_SC_ID                 => v_PJM_SC_ID,
													p_POD_ID                => 0,
													p_ZOD_ID                => 0);
		END IF;
		RETURN v_PRICE_ID;
	END GET_PRICE_ID;
BEGIN
	v_PRICE_ID := GET_PRICE_ID();
	IF v_PRICE_ID > 0 THEN
		v_IDX := p_RECORDS.FIRST;
		WHILE p_RECORDS.EXISTS(v_IDX) LOOP
			MM_UTIL.PUT_MARKET_PRICE_VALUE(p_MARKET_PRICE_ID => v_PRICE_ID,
																		 p_PRICE_DATE      => p_RECORDS(v_IDX).SCHEDULE_DATE,
																		 p_PRICE_CODE      => 'A',
																		 p_PRICE           => p_RECORDS(v_IDX).PRICE,
																		 p_PRICE_BASIS     => NULL,
																		 p_STATUS          => v_STATUS,
																		 p_ERROR_MESSAGE   => v_MESSAGE);
			v_IDX := p_RECORDS.NEXT(v_IDX);
		END LOOP;
	END IF;
END IMPORT_OP_RESV_RATES;
  ----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_OP_RESV_RATES(p_CRED   IN mex_credentials,
  							  p_LOG_ONLY	IN NUMBER,
							  p_BEGIN_DATE IN DATE,
							  p_END_DATE   IN DATE,
							  p_STATUS     OUT NUMBER,
							  p_MESSAGE    OUT VARCHAR2,
							  p_LOGGER IN OUT mm_logger_adapter) IS
	v_DA_RATES price_quantity_summary_table;
	v_RT_RATES price_quantity_summary_table;
	v_OP_RESV_RATES mex_pjm_op_res_rates_tbl;
	v_DATE DATE;
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	p_STATUS := GA.SUCCESS;

	UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
	v_DATE := TRUNC(v_BEGIN_DATE, 'MM');
	WHILE v_DATE <= p_END_DATE LOOP
		MEX_PJM_OASIS.FETCH_OP_RESV_RATES(p_CRED, p_LOG_ONLY, v_DATE, v_DA_RATES, v_RT_RATES, v_OP_RESV_RATES, p_STATUS, p_MESSAGE, p_LOGGER);
		IF p_STATUS = GA.SUCCESS THEN
			IF v_DATE >= TO_DATE(NVL(GET_DICTIONARY_VALUE('Operating Reserve Go Live', 0, 'MarketExchange', 'PJM','?','?'), '12/01/2008'),'MM/DD/YYYY') THEN
				IMPORT_OP_RESV_RATES_REG(v_OP_RESV_RATES);
			ELSE
				IMPORT_OP_RESV_RATES(v_DA_RATES, 'DA');
				IMPORT_OP_RESV_RATES(v_RT_RATES, 'RT');
			END IF;
		END IF;
		v_DATE := ADD_MONTHS(v_DATE, 1);
	END LOOP;

END QUERY_OP_RESV_RATES;
----------------------------------------------------------------------------------------------------

PROCEDURE IMPORT_OP_RESV_RATES_FROM_FILE
    (
    p_IMPORT_FILE IN CLOB,
	p_LOG_TYPE    IN NUMBER,
    p_TRACE_ON    IN NUMBER,
    p_STATUS      OUT NUMBER,
    p_MESSAGE     OUT VARCHAR2
    ) IS
v_OP_RESV_RATES MEX_PJM_OP_RES_RATES_TBL;
v_LOGGER  MM_LOGGER_ADAPTER;
v_DUMMY   VARCHAR2(512);

BEGIN
	--For MSRS testing
    p_STATUS := GA.SUCCESS;
	v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_PJM,
                                   NULL,
                                   'Import Operating Reserve From file',
                                   'Import Operating Reserve From file',
                                   p_LOG_TYPE,
                                   p_TRACE_ON);
	MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

    MEX_PJM_OASIS.PARSE_OP_RESV_RATES_MSRS(p_IMPORT_FILE, v_OP_RESV_RATES, v_LOGGER);

	IF LOGS.GET_ERROR_COUNT() = 0 THEN
		IMPORT_OP_RESV_RATES_REG(v_OP_RESV_RATES);
	END IF;

	-- clean up
    p_STATUS := GA.SUCCESS;
	p_MESSAGE := 'Import Operating Reserve Report from File Complete.';
	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
	p_MESSAGE := p_MESSAGE || ' See event log for details.';

EXCEPTION
    WHEN OTHERS THEN
		p_STATUS := SQLCODE;
--@@	p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);
END IMPORT_OP_RESV_RATES_FROM_FILE;
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

	v_CRED 	mex_credentials;
	v_LOGGER	mm_logger_adapter;
	v_LOG_ONLY NUMBER;
BEGIN
		p_STATUS := GA.SUCCESS;
		v_LOG_ONLY := NVL(p_LOG_ONLY,0);

		MM_UTIL.INIT_MEX(EC.ES_PJM,
					 NULL,
					 'PJM:OASIS',
                     p_EXCHANGE_TYPE,
                     p_LOG_TYPE,
                     p_TRACE_ON,
                     v_CRED,
                     v_LOGGER,
					 TRUE);
		MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

        CASE p_EXCHANGE_TYPE
            WHEN g_ET_QUERY_LOAD_FORECAST THEN
               QUERY_LOAD_FORECAST(v_CRED, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			WHEN g_ET_QUERY_OP_RESV_RATES THEN
			 	QUERY_OP_RESV_RATES(v_CRED, v_LOG_ONLY, p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE, v_LOGGER);
			ELSE
				p_STATUS := -1;
				p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
				v_LOGGER.LOG_ERROR(p_MESSAGE);
        END CASE;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := UT.GET_FULL_ERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE LOAD_FORECAST_REPORT
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
  p_LAST_UPDATE_DATE OUT DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	) AS
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
  v_DATE_STR VARCHAR2(64);
BEGIN
	UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
	OPEN p_CURSOR FOR
    SELECT SERVICE_ZONE_NAME, SERVICE_ZONE_ORDER, SDT.HOUR_YYYY_MM_DD SCHEDULE_DATE, AMOUNT
      FROM (SELECT TRANSACTION_ID, S.SERVICE_ZONE_NAME,
							CASE UPPER(SUBSTR(S.SERVICE_ZONE_NAME,1,5))
								WHEN 'MID A' THEN '01'
								WHEN 'AP' THEN '02'
								WHEN 'AEP' THEN '03'
								WHEN 'DAYTO' THEN '04'
								WHEN 'COMED' THEN '05'
								WHEN 'DUQUE' THEN '06'
								WHEN 'WESTE' THEN '07'
								WHEN 'DOMIN' THEN '08'
								WHEN 'SOUTH' THEN '09'
								WHEN 'PJM' THEN '10'
								ELSE '11'
							END "SERVICE_ZONE_ORDER"
              FROM INTERCHANGE_TRANSACTION T, SERVICE_ZONE S
             WHERE SC_ID = (SELECT SC_ID FROM SC WHERE SC_ALIAS = 'PJM')
               AND COMMODITY_ID = (SELECT COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_ALIAS = 'DA')
               AND CONTRACT_ID = 0
               AND T.ZOD_ID = S.SERVICE_ZONE_ID
               AND T.ZOD_ID != 0) A,
           IT_SCHEDULE,
		   SYSTEM_DATE_TIME SDT
     WHERE A.TRANSACTION_ID = IT_SCHEDULE.TRANSACTION_ID
       AND SCHEDULE_STATE = GA.INTERNAL_STATE
       AND SCHEDULE_TYPE = p_STATEMENT_TYPE
       --AND SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
         AND SDT.TIME_ZONE = p_TIME_ZONE
           AND SDT.DAY_TYPE = '1'
           AND SDT.DATA_INTERVAL_TYPE = 1
           AND SDT.CUT_DATE_SCHEDULING BETWEEN v_BEGIN_DATE AND v_END_DATE
           AND SDT.MINIMUM_INTERVAL_NUMBER >= 30
           AND SDT.CUT_DATE_SCHEDULING = SCHEDULE_DATE
			ORDER BY 2,3
	   ;

  -- now get the last update date from the system dictionary
  v_DATE_STR := GET_DICTIONARY_VALUE('LastUpdate', 1, 'MarketExchange', 'PJM', 'OASIS', 'LoadForecast');
  p_LAST_UPDATE_DATE := TO_DATE(NVL(v_DATE_STR, '01/01/1900 00:00'), 'MM/DD/YYYY HH24:MI');


END LOAD_FORECAST_REPORT;
----------------------------------------------------------------------------------------------------

BEGIN
  -- Initialization
  SELECT SC_ID
    INTO g_PJM_SC_ID
    FROM SCHEDULE_COORDINATOR
   WHERE SC_NAME = 'PJM';
EXCEPTION
  WHEN OTHERS THEN
    g_PJM_SC_ID := 0;

END MM_PJM_OASIS;
/