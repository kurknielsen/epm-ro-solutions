CREATE OR REPLACE PACKAGE BODY MEX_PJM_OASIS IS
g_REPORT_END_LINE CONSTANT VARCHAR2(16) := 'End of Report';
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
  FUNCTION GET_LOAD_FORECAST_NAME(v_STR IN VARCHAR2)
     RETURN VARCHAR2
  AS
     v_LOAD_FORECAST_NAME  VARCHAR2(256);
     v_LF_MID_ATLANTIC     CONSTANT VARCHAR2(256) := 'MID ATLANTIC REGION';
     v_LF_AP               CONSTANT VARCHAR2(256) := 'AP';
     v_LF_AEP              CONSTANT VARCHAR2(256) := 'AEP';
     v_LF_DAYTON           CONSTANT VARCHAR2(256) := 'DAYTON';
     v_LF_COMED            CONSTANT VARCHAR2(256) := 'COMED';
     v_LF_DUQUESNE         CONSTANT VARCHAR2(256) := 'DUQUESNE';
     v_LF_WESTERN_REGION   CONSTANT VARCHAR2(256) := 'WESTERN REGION';
     v_LF_DOMINION         CONSTANT VARCHAR2(256) := 'DOMINION';
     v_LF_SOUTHERN_REGION  CONSTANT VARCHAR2(256) := 'SOUTHERN REGION';
     v_LF_RTO_COMBINED     CONSTANT VARCHAR2(256) := 'RTO COMBINED';
     v_LF_HOUR_INTEGRATED  CONSTANT VARCHAR2(256) := 'HOUR ENDING INTEGRATED FORECAST LOAD MW';
   BEGIN
     IF INSTR(v_STR,v_LF_MID_ATLANTIC || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_MID_ATLANTIC;
     ELSIF INSTR(v_STR,v_LF_AP || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_AP;
     ELSIF INSTR(v_STR,v_LF_AEP || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_AEP;
     ELSIF INSTR(v_STR,v_LF_DAYTON || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_DAYTON;
     ELSIF INSTR(v_STR,v_LF_COMED || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_COMED;
     ELSIF INSTR(v_STR,v_LF_DUQUESNE || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_DUQUESNE;
     ELSIF INSTR(v_STR,v_LF_WESTERN_REGION || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_WESTERN_REGION;
     ELSIF INSTR(v_STR,v_LF_DOMINION || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_DOMINION;
     ELSIF INSTR(v_STR,v_LF_SOUTHERN_REGION || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_SOUTHERN_REGION;
     ELSIF INSTR(v_STR,v_LF_RTO_COMBINED || ' ' || v_LF_HOUR_INTEGRATED) > 0 THEN
        v_LOAD_FORECAST_NAME := v_LF_RTO_COMBINED;
     END IF;

     RETURN(v_LOAD_FORECAST_NAME);
   END GET_LOAD_FORECAST_NAME;
----------------------------------------------------------------------------------------------------
 PROCEDURE PARSE_LOAD_FORECAST(p_RESPONSE_CLOB IN CLOB,
                               p_RECORDS       OUT MEX_PJM_LOAD_TBL,
                               p_STATUS        OUT NUMBER,
                               p_MESSAGE       OUT VARCHAR2) IS

    v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS         PARSE_UTIL.STRING_TABLE;
    v_IDX          BINARY_INTEGER;
    v_COLS_IDX     BINARY_INTEGER;
    v_CURRENT_DATE DATE;
    v_HEADER_FOUND BOOLEAN := FALSE;
    v_DATE         VARCHAR2(8);
    v_HOUR         NUMBER(2);

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_PJM_LOAD_TBL();   -- the load zones

    WHILE v_LINES.EXISTS(v_IDX) LOOP
      -- Skip any blank line
      IF RTRIM(LTRIM(v_LINES(v_IDX))) IS NOT NULL THEN
        -- Check if the line is Load Forecast header
        IF GET_LOAD_FORECAST_NAME(V_LINES(V_IDX)) IS NOT NULL THEN
            v_HEADER_FOUND := TRUE;
            p_RECORDS.EXTEND();  -- get a new load zone
            p_RECORDS(p_RECORDS.LAST) :=  MEX_PJM_LOAD(ZONE_ID => NULL,
                                                       ZONE_NAME => GET_LOAD_FORECAST_NAME(V_LINES(V_IDX)),
                                                       SCHEDULES => MEX_SCHEDULE_TBL());
            v_IDX := v_LINES.NEXT(v_IDX);             -- Blank Line
            v_IDX := v_LINES.NEXT(v_IDX);             -- Date header
            v_IDX := v_LINES.NEXT(v_IDX);             -- Column marker
        ELSE
            IF v_HEADER_FOUND THEN
              PARSE_UTIL.TOKENS_FROM_SPACE_DELIM_STRING(V_LINES(V_IDX), v_COLS);

              -- AM Load Forecast
              v_COLS_IDX := v_COLS.FIRST;
              v_DATE := v_COLS(v_COLS_IDX);
              -- Skip the next Date and AM column
              v_COLS_IDX := v_COLS.NEXT(v_COLS_IDX);
              v_COLS_IDX := v_COLS.NEXT(v_COLS_IDX);
              v_HOUR := 1;
              -- 12 Load Forecast values for AM
              WHILE v_COLS.EXISTS(v_COLS_IDX) LOOP
                  p_RECORDS(p_RECORDS.LAST).SCHEDULES.EXTEND();
                  v_CURRENT_DATE := TO_CUT_WITH_OPTIONS(TO_DATE(v_DATE, 'MM/DD/YY HH24') + v_HOUR/24,g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION);
                  p_RECORDS(p_RECORDS.LAST).SCHEDULES(p_RECORDS(p_RECORDS.LAST).SCHEDULES.LAST) := MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                                                                                                                VOLUME => TO_NUMBER(v_COLS(v_COLS_IDX)),
                                                                                                                RATE => NULL);
                  v_HOUR := v_HOUR + 1;
                  v_COLS_IDX := v_COLS.NEXT(v_COLS_IDX);
              END LOOP;

              -- PM Load Forecast
              v_IDX := v_LINES.NEXT(v_IDX);
              PARSE_UTIL.TOKENS_FROM_SPACE_DELIM_STRING(V_LINES(V_IDX), v_COLS);
              v_COLS_IDX := v_COLS.FIRST;
              -- Skip the PM column
              v_COLS_IDX := v_COLS.NEXT(v_COLS_IDX);
              -- 12 Load Forecast values for PM
              WHILE v_COLS.EXISTS(v_COLS_IDX) LOOP
                  p_RECORDS(p_RECORDS.LAST).SCHEDULES.EXTEND();
                  v_CURRENT_DATE := TO_CUT_WITH_OPTIONS(TO_DATE(v_DATE, 'MM/DD/YY HH24') + v_HOUR/24,g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION);
                  p_RECORDS(p_RECORDS.LAST).SCHEDULES(p_RECORDS(p_RECORDS.LAST).SCHEDULES.LAST) := MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                                                                                                                VOLUME => TO_NUMBER(v_COLS(v_COLS_IDX)),
                                                                                                                RATE => NULL);
                  v_HOUR := v_HOUR + 1;
                  v_COLS_IDX := v_COLS.NEXT(v_COLS_IDX);
              END LOOP;

            END IF;
        END IF;
      ELSE
          -- Blank line terminates a particular load forecast section
          v_HEADER_FOUND := FALSE;
      END IF;

      v_IDX := v_LINES.NEXT(v_IDX);
END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_OASIS.PARSE_LOAD_FORECAST: ' || UT.GET_FULL_ERRM;
  END PARSE_LOAD_FORECAST;
----------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_LOAD_FORECAST(p_CRED				IN MEX_CREDENTIALS,
								p_LOG_ONLY			IN NUMBER,
                                p_RECORDS     OUT MEX_PJM_LOAD_TBL,
                                p_STATUS      OUT NUMBER,
                                p_MESSAGE     OUT VARCHAR2,
								p_LOGGER 			IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_RESPONSE_CLOB     CLOB;
    v_ISO_URL       	VARCHAR2(255);
	v_RESULT		MEX_RESULT;
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_LOAD_TBL();

	v_ISO_URL := GET_DICTIONARY_VALUE('URL', 1, 'MarketExchange', 'PJM', 'OASIS', 'LoadForecast');

	v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => v_ISO_URL,
										 p_Logger => p_LOGGER,
										 p_Cred => p_CRED,
										 p_Log_Only => p_LOG_ONLY);

	p_STATUS  := v_RESULT.STATUS_CODE;
	IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success OR p_LOG_ONLY <> 0 THEN
		v_RESPONSE_CLOB := NULL;
	ELSE
		v_RESPONSE_CLOB := v_RESULT.RESPONSE;
	END IF;

    IF p_STATUS = MEX_Switchboard.c_Status_Success THEN
      PARSE_LOAD_FORECAST(v_RESPONSE_CLOB, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_OASIS.FETCH_LOAD_FORECAST: ' || UT.GET_FULL_ERRM;
  END FETCH_LOAD_FORECAST;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OP_RESV_RATES_MSRS
    (
    p_RESPONSE_CLOB   IN CLOB,
    p_RECORDS         OUT MEX_PJM_OP_RES_RATES_TBL,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) IS

	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
BEGIN

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX             := v_LINES.FIRST;
	p_RECORDS := MEX_PJM_OP_RES_RATES_TBL();

		-- Skip first 4 lines and 'End of Report' line
    WHILE v_LINES.EXISTS(v_IDX) AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0 LOOP
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 4 THEN
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
			p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_OP_RES_RATES(TO_DATE(v_COLS(1), 'MM/DD/YYYY'),
                                                              NVL(TO_NUMBER(v_COLS(2)), 0),
                                                              NVL(TO_NUMBER(v_COLS(3)), 0),
                                                              NVL(TO_NUMBER(v_COLS(4)), 0),
                                                              NVL(TO_NUMBER(v_COLS(5)), 0),
                                                              NVL(TO_NUMBER(v_COLS(6)), 0),
                                                              NVL(TO_NUMBER(v_COLS(7)), 0),
                                                              NVL(TO_NUMBER(v_COLS(8)), 0));
        END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_LOGGER.LOG_ERROR('Error in MEX_PJM_OASIS.PARSE_OP_RESV_RATES_MSRS: ' || UT.GET_FULL_ERRM);
		RAISE;
END PARSE_OP_RESV_RATES_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_OP_RESV_RATES(p_RESPONSE_CLOB   IN CLOB,
															p_DA_RATE_RECORDS OUT PRICE_QUANTITY_SUMMARY_TABLE,
															p_RT_RATE_RECORDS OUT PRICE_QUANTITY_SUMMARY_TABLE,
															p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_HEADER_FOUND BOOLEAN := FALSE;
BEGIN

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE_CLOB, v_LINES);
	v_IDX             := v_LINES.FIRST;
	p_DA_RATE_RECORDS := PRICE_QUANTITY_SUMMARY_TABLE();
	p_RT_RATE_RECORDS := PRICE_QUANTITY_SUMMARY_TABLE();

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		-- Skip any blank line
		IF RTRIM(LTRIM(v_LINES(v_IDX))) IS NOT NULL THEN
			-- the first row is the header
			IF v_HEADER_FOUND = FALSE THEN
				v_HEADER_FOUND := TRUE;
			ELSE
					PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
					p_DA_RATE_RECORDS.EXTEND();
					p_DA_RATE_RECORDS(p_DA_RATE_RECORDS.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(v_COLS(2), TO_DATE(v_COLS(1), 'MM/DD/YYYY'), NULL);
					p_RT_RATE_RECORDS.EXTEND();
					p_RT_RATE_RECORDS(p_RT_RATE_RECORDS.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(v_COLS(3), TO_DATE(v_COLS(1), 'MM/DD/YYYY'), NULL);
			END IF;
		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_LOGGER.LOG_ERROR('Error in MEX_PJM_OASIS.PARSE_OP_RESV_RATES: ' || UT.GET_FULL_ERRM);
		RAISE;
END PARSE_OP_RESV_RATES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_OP_RESV_RATES(p_CRED			IN MEX_CREDENTIALS,
							  P_LOG_ONLY		IN NUMBER,
							  p_DATE            IN DATE,
							  p_DA_RATE_RECORDS OUT PRICE_QUANTITY_SUMMARY_TABLE,
							  p_RT_RATE_RECORDS OUT PRICE_QUANTITY_SUMMARY_TABLE,
							  p_OP_RESV_RATES OUT MEX_PJM_OP_RES_RATES_TBL,
							  p_STATUS          OUT NUMBER,
							  p_MESSAGE         OUT VARCHAR2,
							  p_LOGGER 			IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
	v_RESPONSE_CLOB CLOB;
	v_YYYYMM        VARCHAR2(32);
    v_ISO_URL       	VARCHAR2(255);
	v_RESULT		MEX_RESULT;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	p_DA_RATE_RECORDS := PRICE_QUANTITY_SUMMARY_TABLE();
	p_RT_RATE_RECORDS := PRICE_QUANTITY_SUMMARY_TABLE();
	v_YYYYMM := TO_CHAR(p_DATE, 'YYYYMM');
	v_ISO_URL := GET_DICTIONARY_VALUE('URL', 1, 'MarketExchange', 'PJM', 'OASIS', 'OpResvRates') ||
										 v_YYYYMM || '.csv';

	v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => v_ISO_URL,
										 p_Logger => p_LOGGER,
										 p_Cred => p_CRED,
										 p_Log_Only => p_LOG_ONLY);

	p_STATUS  := v_RESULT.STATUS_CODE;
	IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success OR p_LOG_ONLY <> 0 THEN
		v_RESPONSE_CLOB := NULL;
	ELSE
		v_RESPONSE_CLOB := v_RESULT.RESPONSE;
	END IF;

	IF p_STATUS = MEX_Switchboard.c_Status_Success THEN

		IF p_DATE >= TO_DATE(NVL(GET_DICTIONARY_VALUE('Operating Reserve Go Live', 0, 'MarketExchange', 'PJM','?','?'), '12/01/2008'),'MM/DD/YYYY') THEN
			PARSE_OP_RESV_RATES_MSRS(v_RESPONSE_CLOB,
								     p_OP_RESV_RATES,
								     p_LOGGER);
		ELSE
        	PARSE_OP_RESV_RATES(v_RESPONSE_CLOB,
								p_DA_RATE_RECORDS,
								p_RT_RATE_RECORDS,
								p_LOGGER);
        END IF;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		P_STATUS  := SQLCODE;
		P_MESSAGE := 'Error in MEX_PJM_OASIS.FETCH_OP_RESV_RATES: ' || UT.GET_FULL_ERRM;
END FETCH_OP_RESV_RATES;
----------------------------------------------------------------------------------------------------
END MEX_PJM_OASIS;
/
