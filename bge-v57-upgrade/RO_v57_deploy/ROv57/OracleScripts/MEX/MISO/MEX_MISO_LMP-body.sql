CREATE OR REPLACE PACKAGE BODY MEX_MISO_LMP IS

----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_LMP(p_DATE    IN DATE,
                      p_CSV     IN CLOB,
                      p_RECORDS OUT MEX_MISO_LMP_OBJ_TBL,
                      p_STATUS  OUT NUMBER,
                      p_MESSAGE OUT VARCHAR2) IS
    v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_FIELDS         PARSE_UTIL.STRING_TABLE;
    v_INDEX          BINARY_INTEGER;
    v_DATE_STRING    VARCHAR2(8);
    v_TIMESTAMP      DATE;
    v_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
	v_LINE_COUNTER BINARY_INTEGER := 0;
	DATA_START_LINE CONSTANT BINARY_INTEGER := 5;
  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_MISO_LMP_OBJ_TBL();

    -- parse the clob into lines
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMM');
    v_INDEX       := v_LINES.FIRST;

    -- loop over lines
    WHILE v_LINES.EXISTS(v_INDEX) LOOP
		v_LINE_COUNTER := v_LINE_COUNTER + 1;
      IF LENGTH(v_LINES(v_INDEX)) > 0 AND v_LINE_COUNTER > DATA_START_LINE THEN
        --   parse each line into fields
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_INDEX), ',', v_FIELDS);

        --start importing LMP values from each line
        --IF v_DATE_STRING = NVL(SUBSTR(v_FIELDS(1),1,6), '') THEN
          v_PRICE_SCHEDULE := PRICE_QUANTITY_SUMMARY_TABLE();
          FOR I IN 4 .. v_FIELDS.COUNT LOOP
            --calculate the date + hour
           	v_TIMESTAMP := TO_CUT(p_DATE + (I - 3) / 24, 'EST');

            IF v_FIELDS(I) IS NOT NULL THEN
              v_PRICE_SCHEDULE.EXTEND();
              v_PRICE_SCHEDULE(v_PRICE_SCHEDULE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(v_FIELDS(I),
                                                                                     v_TIMESTAMP,
                                                                                     NULL);
            END IF;
          END LOOP;
          p_RECORDS.EXTEND();
          p_RECORDS(p_RECORDS.LAST) := MEX_MISO_LMP_OBJ(v_FIELDS(1),
                                                       v_FIELDS(2),
                                                       v_FIELDS(3),
                                                       v_PRICE_SCHEDULE);
        --END IF;
      END IF;
      v_INDEX := v_LINES.NEXT(v_INDEX);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_MISO_LMP.PARSE_LMP: ' || SQLERRM;
  END PARSE_LMP;
	----------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_LMP_FILE(p_DATE             	IN DATE,
                           p_MARKET_TYPE      	IN VARCHAR2,
						   p_LOG_ONLY			IN BINARY_INTEGER :=0,
                           p_RECORDS          	OUT MEX_MISO_LMP_OBJ_TBL,
                           p_STATUS           	OUT NUMBER,
                           p_MESSAGE          	OUT VARCHAR2,
						   p_LOGGER				IN OUT mm_logger_adapter) IS
    v_RESPONSE_CLOB CLOB;
    v_LMP_URL       VARCHAR2(255);
    v_LMP_FILENAME  VARCHAR2(255);
    v_LMP_BASE_URL  VARCHAR2(40);
	v_RESULT MEX_RESULT;
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_MISO_LMP_OBJ_TBL();

	v_LMP_FILENAME := TO_CHAR(p_DATE, 'YYYYMMDD');
	IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
  		v_LMP_FILENAME := '/da_lmp/' || v_LMP_FILENAME || '_da_lmp.csv';
	ELSE
  		v_LMP_FILENAME := '/rt_lmp/' || v_LMP_FILENAME || '_rt_lmp_final.csv';
	END IF;
	
	v_LMP_BASE_URL := GET_DICTIONARY_VALUE('URL', 1, 'MarketExchange', 'MISO', 'LMP', 'LMP File');

    v_LMP_URL := v_LMP_BASE_URL || v_LMP_FILENAME;

	v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => v_LMP_URL, p_Logger => p_LOGGER, p_Log_Only => p_LOG_ONLY);
	
    IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
    	v_RESPONSE_CLOB := NULL;
		p_STATUS  := v_RESULT.STATUS_CODE;
    ELSE
    	v_RESPONSE_CLOB := v_RESULT.RESPONSE;
		p_STATUS  := GA.SUCCESS;
        PARSE_LMP(p_DATE, v_RESPONSE_CLOB, p_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
	
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_MISO_LMP.FETCH_LMP_FILE: ' || SQLERRM;
  END FETCH_LMP_FILE;
	----------------------------------------------------------------------------------------------------

END MEX_MISO_LMP;
/
