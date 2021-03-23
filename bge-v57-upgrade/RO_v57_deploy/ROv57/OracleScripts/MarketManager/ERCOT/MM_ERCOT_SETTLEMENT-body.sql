CREATE OR REPLACE PACKAGE BODY MM_ERCOT_SETTLEMENT IS

--------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SETTLEMENT_TOTALS
	(
    p_RECORDS IN MEX_ERCOT_CHARGE_TOTAL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
v_IDX BINARY_INTEGER;

PROCEDURE UPDATE_SCHEDULE(v_EXT_ID IN VARCHAR2, v_DATE IN DATE,
							v_TXN_NAME IN VARCHAR2, v_CHARGE_AMOUNT IN NUMBER,
                            v_SETTLEMENT_TYPE IN NUMBER) IS
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	BEGIN
		v_TRANSACTION_ID := MM_ERCOT_UTIL.GET_TX_ID(v_EXT_ID,
                                                    'Market Result',
                                                    v_TXN_NAME,
                                                    'Day');

        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                                            v_DATE + 1/86400,
                                            v_CHARGE_AMOUNT,
                                            v_SETTLEMENT_TYPE);
	END UPDATE_SCHEDULE;
BEGIN
	 p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF;

	v_IDX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
    	CASE
        WHEN p_RECORDS(v_IDX).CHARGE_ABBR = '"BENABILLAMTTOT' OR
                p_RECORDS(v_IDX).CHARGE_ABBR = '"BENABILLAMT_ERCOTTOT' THEN
        	UPDATE_SCHEDULE('BENABILLAMT', p_RECORDS(v_IDX).CHARGE_DATE,
            				'ERCOT Total Balancing Energy Neutrality Adjustment Charge',
                            p_RECORDS(v_IDX).CHARGE_TOTAL,
                            p_RECORDS(v_IDX).SETTLEMENT_TYPE);
		WHEN p_RECORDS(v_IDX).CHARGE_ABBR = '"BLABILLAMTTOT' THEN
        	UPDATE_SCHEDULE('BLABILLAMTTOT', p_RECORDS(v_IDX).CHARGE_DATE,
            				'ERCOT Total Black Start Service Charge',
                            p_RECORDS(v_IDX).CHARGE_TOTAL,
                            p_RECORDS(v_IDX).SETTLEMENT_TYPE);
        WHEN p_RECORDS(v_IDX).CHARGE_ABBR = '"LBEBILLAMT_ERCOTTOT' THEN
        	UPDATE_SCHEDULE('LBEBILLAMT', p_RECORDS(v_IDX).CHARGE_DATE,
            				'ERCOT Total Local Balancing Energy Service Charge',
                            p_RECORDS(v_IDX).CHARGE_TOTAL,
                            p_RECORDS(v_IDX).SETTLEMENT_TYPE);
        WHEN p_RECORDS(v_IDX).CHARGE_ABBR = '"ELAOOMBILLAMTTOT' OR
                p_RECORDS(v_IDX).CHARGE_ABBR = '"ELAOOMBILLAMT_ERCOTTOT' THEN
        	UPDATE_SCHEDULE('ELAOOMBILLAMT', p_RECORDS(v_IDX).CHARGE_DATE,
            				'ERCOT Total OOM Energy Charge',
                            p_RECORDS(v_IDX).CHARGE_TOTAL,
                            p_RECORDS(v_IDX).SETTLEMENT_TYPE);
        WHEN p_RECORDS(v_IDX).CHARGE_ABBR = '"LAOOMBILLAMTTOT' THEN
        	UPDATE_SCHEDULE('LAOOMBILLAMTTOT', p_RECORDS(v_IDX).CHARGE_DATE,
            				'ERCOT Total OOM Replacement Capacity Charge',
                            p_RECORDS(v_IDX).CHARGE_TOTAL,
                            p_RECORDS(v_IDX).SETTLEMENT_TYPE);
        WHEN p_RECORDS(v_IDX).CHARGE_ABBR = '"LARMRBILLAMTTOT' OR
                p_RECORDS(v_IDX).CHARGE_ABBR = '"LARMRBILLAMT_ERCOTTOT'   THEN
        	UPDATE_SCHEDULE('LARMRBILLAMT', p_RECORDS(v_IDX).CHARGE_DATE,
            				'ERCOT Total RMR Reserve Service Charge',
                            p_RECORDS(v_IDX).CHARGE_TOTAL,
                            p_RECORDS(v_IDX).SETTLEMENT_TYPE);
        WHEN p_RECORDS(v_IDX).CHARGE_ABBR = '"UCRPBILLAMTTOT' THEN
        	UPDATE_SCHEDULE('UCRPBILLAMTTOT', p_RECORDS(v_IDX).CHARGE_DATE,
            				'ERCOT Total Replacement Reserve Uplift Charge',
                            p_RECORDS(v_IDX).CHARGE_TOTAL,
                            p_RECORDS(v_IDX).SETTLEMENT_TYPE);
		ELSE
        	NULL;
       END CASE;

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

    IF p_STATUS = GA.SUCCESS THEN
    	COMMIT;
  	END IF;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MM_ERCOT_SETTLEMENT.IMPORT_SETTLEMENT_TOTALS: ' || SQLERRM;
END IMPORT_SETTLEMENT_TOTALS;
--------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SETTLEMENT_TOTALS
	(
	p_CRED	IN mex_credentials,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_SETTLEMENT_TYPE IN VARCHAR2,
    p_PERIOD_TYPE IN VARCHAR2,
	p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_ERCOT_CHARGE_TOTAL_TBL;
BEGIN

    MEX_ERCOT_SETTLEMENT.FETCH_TOTAL_CHARGES_FILE(p_BEGIN_DATE,
                                                  p_END_DATE,
                                                  p_SETTLEMENT_TYPE,
                                                  p_PERIOD_TYPE,
                                                  p_CRED,
												  p_LOG_ONLY,
                                                  v_RECORDS,
                                                  p_STATUS,
                                                  p_MESSAGE,
												  p_LOGGER);

	IF p_STATUS = GA.SUCCESS THEN
    	IMPORT_SETTLEMENT_TOTALS(v_RECORDS, p_STATUS, p_MESSAGE);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MM_ERCOT_SETTLEMENT.IMPORT_SETTLEMENT_TOTALS: ' || SQLERRM;
END IMPORT_SETTLEMENT_TOTALS;
--------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

	v_CRED mex_credentials;
	v_LOGGER mm_logger_adapter;
	v_LOG_ONLY NUMBER;
BEGIN
	v_LOG_ONLY := NVL(p_LOG_ONLY, 0);

	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_MEX_SWITCHBOARD,
		p_EXTERNAL_ACCOUNT_NAME => NULL,
		p_PROCESS_NAME => 'ERCOT:SETTLEMENT',
		p_EXCHANGE_NAME => p_EXCHANGE_TYPE,
		p_LOG_TYPE => p_LOG_TYPE,
		p_TRACE_ON => p_TRACE_ON,
		p_CREDENTIALS => v_CRED,
		p_LOGGER => v_LOGGER);
		
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	IF p_EXCHANGE_TYPE = g_ET_IMPORT_ANNUAL_INITIAL THEN
		IMPORT_SETTLEMENT_TOTALS(v_CRED, p_BEGIN_DATE, p_END_DATE, MM_ERCOT_UTIL.g_ERCOT_INITIAL, MM_ERCOT_UTIL.g_ERCOT_YEARLY,v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
    ELSIF p_EXCHANGE_TYPE = g_ET_IMPORT_MONTHLY_INITIAL THEN
		IMPORT_SETTLEMENT_TOTALS(v_CRED, p_BEGIN_DATE, p_END_DATE, MM_ERCOT_UTIL.g_ERCOT_INITIAL, MM_ERCOT_UTIL.g_ERCOT_MONTHLY,v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
    ELSIF p_EXCHANGE_TYPE = g_ET_IMPORT_ANNUAL_FINAL THEN
		IMPORT_SETTLEMENT_TOTALS(v_CRED, p_BEGIN_DATE, p_END_DATE, MM_ERCOT_UTIL.g_ERCOT_FINAL, MM_ERCOT_UTIL.g_ERCOT_YEARLY, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
    ELSIF p_EXCHANGE_TYPE = g_ET_IMPORT_MONTHLY_FINAL THEN
		IMPORT_SETTLEMENT_TOTALS(v_CRED, p_BEGIN_DATE, p_END_DATE, MM_ERCOT_UTIL.g_ERCOT_FINAL, MM_ERCOT_UTIL.g_ERCOT_MONTHLY, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
    ELSIF p_EXCHANGE_TYPE = g_ET_IMPORT_ANNUAL_TRUE_UP THEN
		IMPORT_SETTLEMENT_TOTALS(v_CRED, p_BEGIN_DATE, p_END_DATE, MM_ERCOT_UTIL.g_ERCOT_TRUEUP, MM_ERCOT_UTIL.g_ERCOT_YEARLY, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
	ELSIF p_EXCHANGE_TYPE = g_ET_IMPORT_MONTHLY_TRUE_UP THEN
		IMPORT_SETTLEMENT_TOTALS(v_CRED, p_BEGIN_DATE, p_END_DATE, MM_ERCOT_UTIL.g_ERCOT_TRUEUP, MM_ERCOT_UTIL.g_ERCOT_MONTHLY, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
    ELSE
		p_STATUS := -1;
		p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
		v_LOGGER.LOG_ERROR(p_MESSAGE);
	END IF;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
----------------------------------------------------------------------------------------------------------------------
END MM_ERCOT_SETTLEMENT;
/
