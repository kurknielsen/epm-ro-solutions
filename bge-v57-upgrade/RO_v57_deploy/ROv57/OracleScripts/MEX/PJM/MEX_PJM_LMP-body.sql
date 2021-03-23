CREATE OR REPLACE PACKAGE BODY MEX_PJM_LMP IS
g_REPORT_END_LINE CONSTANT VARCHAR2(16) := 'End of Report';
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LMP
	(
	p_DATE    IN DATE,
	p_CSV     IN CLOB,
	p_MONTHLY IN NUMBER,
	p_RECORDS OUT MEX_PJM_LMP_OBJ_TBL,
	p_STATUS  OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) IS
    v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_FIELDS         PARSE_UTIL.STRING_TABLE;
    v_INDEX          BINARY_INTEGER;
    v_DATE_STRING    VARCHAR2(8);
    v_TIMESTAMP      DATE;
    v_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_LMP_OBJ_TBL();

    -- parse the clob into lines
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMM');
    v_INDEX       := v_LINES.FIRST;

    -- loop over lines
    WHILE v_LINES.EXISTS(v_INDEX) LOOP
      IF LENGTH(v_LINES(v_INDEX)) > 0 THEN
        --   parse each line into fields
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_INDEX), ',', v_FIELDS);

        --start importing LMP values from each line
        IF v_DATE_STRING = NVL(SUBSTR(v_FIELDS(1),1,6), '') THEN
          v_PRICE_SCHEDULE := PRICE_QUANTITY_SUMMARY_TABLE();
          /*
            DST: on the spring forward day, there's 24 hours listed and the 0300
            hour is zero. On the fall back day, there's 25 hours listed and the
            second 0200 hour follows the first one (unlike the eSchedules format).
          */
          FOR I IN 8 .. v_FIELDS.COUNT LOOP
            --calculate the date + hour

            IF p_MONTHLY = 0 THEN
            	v_TIMESTAMP := p_DATE + (I - 7) / 24;
            ELSE
            	v_TIMESTAMP := TO_DATE(v_FIELDS(1), 'YYYYMMDD') + (I - 7) / 24;
            END IF;

			IF TRUNC(v_TIMESTAMP) != TRUNC(DST_SPRING_AHEAD_DATE(v_TIMESTAMP)) OR TO_CHAR(v_TIMESTAMP, 'HH24') != '03' THEN
            IF v_FIELDS(I) IS NOT NULL THEN
              v_PRICE_SCHEDULE.EXTEND();
              v_PRICE_SCHEDULE(v_PRICE_SCHEDULE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(v_FIELDS(I),
                                                                                     v_TIMESTAMP,
                                                                                     NULL);
            END IF;
			END IF;
          END LOOP;
          p_RECORDS.EXTEND();
          p_RECORDS(p_RECORDS.LAST) := MEX_PJM_LMP_OBJ(v_FIELDS(2),
                                                       v_FIELDS(3),
                                                       v_FIELDS(4),
                                                       v_FIELDS(5),
                                                       v_FIELDS(6),
                                                       v_FIELDS(7),
                                                       v_PRICE_SCHEDULE);
        END IF;
      END IF;
      v_INDEX := v_LINES.NEXT(v_INDEX);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_LMP.PARSE_LMP: ' || SQLERRM;
  END PARSE_LMP;
----------------------------------------------------------------------------------------------------
FUNCTION GET_TIMESTAMP_FOR_LMP
	(
	p_LMP_DATE IN DATE,
	p_HOUR_NUMBER IN NUMBER
	) RETURN DATE IS
	v_DAY DATE := TRUNC(p_LMP_DATE);
	v_RTN DATE;
BEGIN
	
	IF TRUNC(v_DAY) = TRUNC(DST_FALL_BACK_DATE(v_DAY)) THEN
		--Hours 1 and 2
		IF p_HOUR_NUMBER BETWEEN 1 AND 2 THEN
			v_RTN := v_DAY + (p_HOUR_NUMBER) / 24;
		--The DST hour -- 2:00:01
		ELSIF p_HOUR_NUMBER = 3 THEN
			v_RTN := v_DAY + 2/24 + 1/86400;
		--After the DST hour
		ELSE
			v_RTN := v_DAY + (p_HOUR_NUMBER - 1) / 24;
		END IF;
	ELSE
		v_RTN := v_DAY + (p_HOUR_NUMBER) / 24;
	END IF;
	
	RETURN v_RTN;
END GET_TIMESTAMP_FOR_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_LMP_ML
	(
	p_DATE    IN DATE,
	p_CSV     IN CLOB,
	p_MONTHLY IN NUMBER,
	p_ENG_RECORDS OUT PRICE_QUANTITY_SUMMARY_TABLE,
	p_RECORDS OUT MEX_PJM_LMP_ML_OBJ_TBL,
	p_STATUS  OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_FIELDS PARSE_UTIL.STRING_TABLE;
v_INDEX BINARY_INTEGER;
v_DATE_STRING VARCHAR2(8);
v_TIMESTAMP DATE;
v_ENG_PRICE_NEXT BOOLEAN:= FALSE;
J BINARY_INTEGER;
K BINARY_INTEGER;
--v_ENERGY_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
v_TOTAL_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
v_CONG_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
v_LOSS_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    p_ENG_RECORDS := PRICE_QUANTITY_SUMMARY_TABLE();
    p_RECORDS := MEX_PJM_LMP_ML_OBJ_TBL();

    -- parse the clob into lines
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMM');
    v_INDEX := v_LINES.FIRST;

    -- loop over lines
    WHILE v_LINES.EXISTS(v_INDEX) LOOP
      IF LENGTH(v_LINES(v_INDEX)) > 0 THEN
        --   parse each line into fields
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_INDEX), ',', v_FIELDS);
        IF v_FIELDS(1) LIKE 'End of%Energy Price Data' THEN
            v_ENG_PRICE_NEXT := FALSE;
        ELSIF v_FIELDS(1) LIKE 'Start of%Energy Price Data' THEN
            v_ENG_PRICE_NEXT := TRUE;
        ELSIF v_ENG_PRICE_NEXT = TRUE THEN
            FOR I IN 2 .. v_FIELDS.COUNT LOOP
                v_TIMESTAMP := GET_TIMESTAMP_FOR_LMP(
					CASE p_MONTHLY WHEN 0 THEN p_DATE ELSE TO_DATE(v_FIELDS(1), 'YYYYMMDD') END, I - 1);
                IF TRUNC(v_TIMESTAMP) != TRUNC(DST_SPRING_AHEAD_DATE(v_TIMESTAMP)) OR TO_CHAR(v_TIMESTAMP, 'HH24') != '03' THEN
                    IF v_FIELDS(I) IS NOT NULL THEN
                        p_ENG_RECORDS.EXTEND();
                        p_ENG_RECORDS(p_ENG_RECORDS.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(
                                                                v_FIELDS(I),
                                                                v_TIMESTAMP,
                                                                NULL);
                    END IF;
                END IF;
            END LOOP;

        --start importing LMP values from each line
        ELSIF v_DATE_STRING = NVL(SUBSTR(v_FIELDS(1),1,6), '') THEN
          v_TOTAL_PRICE_SCHEDULE := PRICE_QUANTITY_SUMMARY_TABLE();
          v_CONG_PRICE_SCHEDULE := PRICE_QUANTITY_SUMMARY_TABLE();
          v_LOSS_PRICE_SCHEDULE := PRICE_QUANTITY_SUMMARY_TABLE();
          /*
            DST: on the spring forward day, there's 24 hours listed and the 0300
            hour is zero. On the fall back day, there's 25 hours listed and the
            second 0200 hour follows the first one (unlike the eSchedules format).
          */
            J := 8;
            K := 8;
            LOOP
                v_TIMESTAMP := GET_TIMESTAMP_FOR_LMP(
					CASE p_MONTHLY WHEN 0 THEN p_DATE ELSE TO_DATE(v_FIELDS(1), 'YYYYMMDD') END, K - 7);

                IF TRUNC(v_TIMESTAMP) != TRUNC(DST_SPRING_AHEAD_DATE(v_TIMESTAMP)) OR TO_CHAR(v_TIMESTAMP, 'HH24') != '03' THEN
                    IF v_FIELDS.EXISTS(J) AND v_FIELDS(J) IS NOT NULL THEN
                        v_TOTAL_PRICE_SCHEDULE.EXTEND();
                        v_TOTAL_PRICE_SCHEDULE(v_TOTAL_PRICE_SCHEDULE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(
                                                                                    v_FIELDS(J),
                                                                                    v_TIMESTAMP,
                                                                                    NULL);
                    END IF;
                    IF v_FIELDS.EXISTS(J+1) AND v_FIELDS(J+1) IS NOT NULL THEN
                        v_CONG_PRICE_SCHEDULE.EXTEND();
                        v_CONG_PRICE_SCHEDULE(v_CONG_PRICE_SCHEDULE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(
                                                                                    v_FIELDS(J+1),
                                                                                    v_TIMESTAMP,
                                                                                    NULL);
                    END IF;
                    IF v_FIELDS.EXISTS(J+2) AND v_FIELDS(J+2) IS NOT NULL THEN
                        v_LOSS_PRICE_SCHEDULE.EXTEND();
                        v_LOSS_PRICE_SCHEDULE(v_LOSS_PRICE_SCHEDULE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(
                                                                                    v_FIELDS(J+2),
                                                                                    v_TIMESTAMP,
                                                                                    NULL);
                    END IF;
                END IF;
                J := J+3;
                K := K+1;
                EXIT WHEN J >= v_FIELDS.COUNT;
            END LOOP;

            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_LMP_ML_OBJ(v_FIELDS(2),
                                                           v_FIELDS(3),
                                                           v_FIELDS(4),
                                                           v_FIELDS(5),
                                                           v_FIELDS(6),
                                                           v_FIELDS(7),
                                                           v_TOTAL_PRICE_SCHEDULE,
                                                           v_CONG_PRICE_SCHEDULE,
                                                           v_LOSS_PRICE_SCHEDULE);
        ELSE
            NULL;
        END IF;
      END IF;
      v_INDEX := v_LINES.NEXT(v_INDEX);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_LMP.PARSE_LMP_ML: ' || SQLERRM;
END PARSE_LMP_ML;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FTR_ZONAL_LMP
	(
	p_DATE    IN DATE,
	p_CSV     IN CLOB,
	p_RECORDS OUT MEX_PJM_LMP_OBJ_TBL,
	p_STATUS  OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) IS
v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
v_FIELDS         PARSE_UTIL.STRING_TABLE;
v_INDEX          BINARY_INTEGER;
v_DATE_STRING    VARCHAR2(8);
v_TIMESTAMP      DATE;
v_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
v_HOUR_NUMBER	 NUMBER;
v_DAY			 DATE;
  	BEGIN
      p_STATUS := MEX_UTIL.g_SUCCESS;
      p_RECORDS := MEX_PJM_LMP_OBJ_TBL();

      -- parse the clob into lines
      PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

      v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMM');
      v_INDEX       := v_LINES.FIRST;

      -- loop over lines
      WHILE v_LINES.EXISTS(v_INDEX) LOOP
        IF LENGTH(v_LINES(v_INDEX)) > 0 THEN
          --   parse each line into fields
          PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_INDEX), ',', v_FIELDS);

          --start importing LMP values from each line
          IF v_DATE_STRING = NVL(SUBSTR(v_FIELDS(1),1,6), '') THEN
            v_PRICE_SCHEDULE := PRICE_QUANTITY_SUMMARY_TABLE();
            /*
              DST: on the spring forward day, there's 24 hours listed and the 0300
              hour is zero. For the Fall DST switch day, data for the second hour ending,
			  hour 200 appears last (after hour ending 24)
          */
            v_DAY := TO_DATE(v_FIELDS(1), 'YYYYMMDD');
			FOR I IN 3 .. v_FIELDS.COUNT LOOP
				--calculate the date + hour
				IF TRUNC(v_DAY) = TRUNC(DST_FALL_BACK_DATE(v_DAY)) THEN
					IF I-2 >= 3 AND I-2 <= 24 THEN -- Hours 4 to 24
						v_HOUR_NUMBER := I-1; 
					ELSIF I-2 = 25 THEN -- Column 27 is Hour 3 (Second 02:00Hr)
						v_HOUR_NUMBER := 3;
					ELSE -- Hours 1 and 2
						v_HOUR_NUMBER := I-2;
					END IF;
				ELSE
					v_HOUR_NUMBER := I-2;
				END IF;
					
				v_TIMESTAMP := GET_TIMESTAMP_FOR_LMP(v_DAY, v_HOUR_NUMBER);


      			IF TRUNC(v_TIMESTAMP) != TRUNC(DST_SPRING_AHEAD_DATE(v_TIMESTAMP)) OR TO_CHAR(v_TIMESTAMP, 'HH24') != '03' THEN
                  IF v_FIELDS(I) IS NOT NULL THEN
                    v_PRICE_SCHEDULE.EXTEND();
                    v_PRICE_SCHEDULE(v_PRICE_SCHEDULE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(v_FIELDS(I),
                                                                                           v_TIMESTAMP,
                                                                                           NULL);
                  END IF;
      			END IF;
				END LOOP;
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_LMP_OBJ(v_FIELDS(2),
                                                         v_FIELDS(3),
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         v_PRICE_SCHEDULE);
          END IF;
        END IF;
        v_INDEX := v_LINES.NEXT(v_INDEX);
      END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_LMP.PARSE_FTR_ZONAL_LMP: ' || SQLERRM;
END PARSE_FTR_ZONAL_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FTR_ZONAL_LMP_MSRS
    (
    p_DATE    IN DATE,
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_LMP_OBJ_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
    p_FROM_FILE IN BOOLEAN := FALSE
    ) IS
v_LINES          PARSE_UTIL.BIG_STRING_TABLE_MP;
v_FIELDS         PARSE_UTIL.STRING_TABLE;
v_INDEX          BINARY_INTEGER;
v_DATE_STRING    VARCHAR2(8);
v_TIMESTAMP      DATE;
v_PRICE_SCHEDULE PRICE_QUANTITY_SUMMARY_TABLE;
v_HOUR_NUMBER	 NUMBER;
v_DAY			 DATE;
v_FROM_FILE BOOLEAN;
BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_LMP_OBJ_TBL();
    
    -- parse the clob into lines
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    IF p_FROM_FILE = FALSE THEN
        v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMM');
    END IF;  
    v_FROM_FILE := p_FROM_FILE;
    v_INDEX       := v_LINES.FIRST;

    -- loop over lines
    WHILE v_LINES.EXISTS(v_INDEX) LOOP
        IF LENGTH(v_LINES(v_INDEX)) > 0 THEN
            IF INSTR(v_LINES(v_INDEX), g_REPORT_END_LINE) <> 0 THEN
                EXIT;
            END IF;            
        
            --   parse each line into fields
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_INDEX), ',', v_FIELDS);
            
            IF v_FROM_FILE = TRUE THEN
                v_DATE_STRING := SUBSTR(v_FIELDS(1), LENGTH(v_FIELDS(1)) - 5);
                v_FROM_FILE := FALSE;
            END IF;

            --start importing LMP values from each line
            IF v_DATE_STRING = NVL(SUBSTR(v_FIELDS(1),1,6), '') THEN
                v_PRICE_SCHEDULE := PRICE_QUANTITY_SUMMARY_TABLE();
            /*
              DST: on the spring forward day, there's 24 hours listed and the 0300
              hour is zero. For the Fall DST switch day, data for the second hour ending,
			  hour 200 appears last (after hour ending 24)
            */
                                                      
                v_DAY := TO_DATE(v_FIELDS(1), 'YYYYMMDD');
                FOR I IN 4 .. v_FIELDS.COUNT LOOP
				--calculate the date + hour
				    IF TRUNC(v_DAY) = TRUNC(DST_FALL_BACK_DATE(v_DAY)) THEN
					    IF I-3 >= 3 AND I-3 <= 24 THEN -- Hours 4 to 24
						    v_HOUR_NUMBER := I-2; 
					    ELSIF I-3 = 25 THEN -- Column 28 is Hour 3 (Second 02:00Hr)
						    v_HOUR_NUMBER := 3;
					    ELSE -- Hours 1 and 2
						    v_HOUR_NUMBER := I-3;
					    END IF;
				    ELSE
					    v_HOUR_NUMBER := I-3;
				    END IF;
					
				    v_TIMESTAMP := GET_TIMESTAMP_FOR_LMP(v_DAY, v_HOUR_NUMBER);

				    IF TRUNC(v_TIMESTAMP) != TRUNC(DST_SPRING_AHEAD_DATE(v_TIMESTAMP)) OR TO_CHAR(v_TIMESTAMP, 'HH24') != '03' THEN
				        IF v_FIELDS(I) IS NOT NULL THEN
					        v_PRICE_SCHEDULE.EXTEND();
					        v_PRICE_SCHEDULE(v_PRICE_SCHEDULE.LAST) := PRICE_QUANTITY_SUMMARY_TYPE(v_FIELDS(I),
																						   v_TIMESTAMP,
																						   NULL);
				        END IF;
				    END IF;
				END LOOP;
				
				p_RECORDS.EXTEND();
                --use the name as the pnodeid; it is not the same pnodeid as in service pt table so
                --it is not useful to us
				p_RECORDS(p_RECORDS.LAST) := MEX_PJM_LMP_OBJ(v_FIELDS(3),
															 v_FIELDS(3),
															 NULL,
															 NULL,
															 NULL,
															 NULL,
															 v_PRICE_SCHEDULE);
          END IF;
        END IF;
        v_INDEX := v_LINES.NEXT(v_INDEX);
      END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_LMP.PARSE_FTR_ZONAL_LMP_MSRS: ' || SQLERRM;
END PARSE_FTR_ZONAL_LMP_MSRS;
-----------------------------------------------------------------------------------------------
PROCEDURE FETCH_LMP_FILE
  	(
	p_DATE             	IN DATE,
	p_MARKET_TYPE      	IN VARCHAR2,
	p_MONTHLY			IN NUMBER,
	p_RECORDS          	OUT MEX_PJM_LMP_OBJ_TBL,
	p_STATUS           	OUT NUMBER,
	p_MESSAGE          	OUT VARCHAR2,
	p_LOGGER 			IN OUT NOCOPY MM_LOGGER_ADAPTER
	) IS

    v_RESPONSE_CLOB CLOB;
    v_LMP_URL       VARCHAR2(255);
    v_LMP_FILENAME  VARCHAR2(255);
    v_LMP_BASE_URL  VARCHAR2(40);
	v_RESULT		MEX_RESULT;
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_LMP_OBJ_TBL();
	v_LMP_BASE_URL := GET_DICTIONARY_VALUE('URL', 0, 'MarketExchange', 'PJM', 'LMP', 'LMP');

    IF p_MONTHLY = 0 THEN
    	v_LMP_FILENAME := TO_CHAR(p_DATE, 'YYYYMMDD');
    	IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
      		v_LMP_FILENAME := '/lmpda/' || v_LMP_FILENAME || '-da.csv';
    	ELSE
      		v_LMP_FILENAME := '/lmp/' || v_LMP_FILENAME || '.csv';
    	END IF;
    ELSE
        v_LMP_FILENAME := TO_CHAR(p_DATE, 'YYYYMM');
    	IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
      		v_LMP_FILENAME := '/lmpmonthly/' || v_LMP_FILENAME || '-da.csv';
    	ELSE
      		v_LMP_FILENAME := '/lmpmonthly/' || v_LMP_FILENAME || '-rt.csv';
    	END IF;
    END IF;

   		v_LMP_URL := v_LMP_BASE_URL || v_LMP_FILENAME;
        v_RESULT := Mex_Switchboard.FetchURL(v_LMP_URL, p_LOGGER);

		p_STATUS  := v_RESULT.STATUS_CODE;
        IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
       		v_RESPONSE_CLOB := NULL;
    	ELSE
    		v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    	END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        PARSE_LMP(p_DATE, v_RESPONSE_CLOB, p_MONTHLY, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_LMP.FETCH_LMP_FILE: ' || SQLERRM;
  END FETCH_LMP_FILE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LMP_ML_FILE
	(
	p_DATE             	IN DATE,
	p_MARKET_TYPE      	IN VARCHAR2,
	p_MONTHLY			IN NUMBER,
	p_ENG_RECORDS       OUT PRICE_QUANTITY_SUMMARY_TABLE,
	p_RECORDS          	OUT MEX_PJM_LMP_ML_OBJ_TBL,
	p_STATUS           	OUT NUMBER,
	p_MESSAGE          	OUT VARCHAR2,
	p_LOGGER 			IN OUT NOCOPY MM_LOGGER_ADAPTER
	) IS
v_RESPONSE_CLOB CLOB;
v_LMP_URL       VARCHAR2(255);
v_LMP_FILENAME  VARCHAR2(255);
v_LMP_BASE_URL  VARCHAR2(40);
v_RESULT		MEX_RESULT;
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_LMP_ML_OBJ_TBL();
    p_ENG_RECORDS := PRICE_QUANTITY_SUMMARY_TABLE();
	v_LMP_BASE_URL := GET_DICTIONARY_VALUE('URL', 0, 'MarketExchange', 'PJM', 'LMP', 'LMP');
    IF p_MONTHLY = 0 THEN
    	v_LMP_FILENAME := TO_CHAR(p_DATE, 'YYYYMMDD');
    	IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
      		v_LMP_FILENAME := '/lmpda/' || v_LMP_FILENAME || '-da.csv';
    	ELSE
      		v_LMP_FILENAME := '/lmp/' || v_LMP_FILENAME || '.csv';
    	END IF;
    ELSE
        v_LMP_FILENAME := TO_CHAR(p_DATE, 'YYYYMM');
    	IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
      		v_LMP_FILENAME := '/lmpmonthly/' || v_LMP_FILENAME || '-da.csv';
    	ELSE
      		v_LMP_FILENAME := '/lmpmonthly/' || v_LMP_FILENAME || '-rt.csv';
    	END IF;
    END IF;

    v_LMP_URL := v_LMP_BASE_URL || v_LMP_FILENAME;

        v_RESULT := Mex_Switchboard.FetchURL(v_LMP_URL, p_LOGGER);

		p_STATUS  := v_RESULT.STATUS_CODE;
        IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
       		v_RESPONSE_CLOB := NULL;
    	ELSE
    		v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    	END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        PARSE_LMP_ML(p_DATE, v_RESPONSE_CLOB, p_MONTHLY, p_ENG_RECORDS, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_LMP.FETCH_LMP_ML_FILE: ' || SQLERRM;
END FETCH_LMP_ML_FILE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_FTR_ZONAL_LMP_FILE
	(
	p_DATE 				IN DATE,
	p_RECORDS          	OUT MEX_PJM_LMP_OBJ_TBL,
	p_STATUS           	OUT NUMBER,
	p_MESSAGE          	OUT VARCHAR2,
	p_LOGGER 			IN OUT NOCOPY MM_LOGGER_ADAPTER
	) IS
    v_RESPONSE_CLOB CLOB;
    v_LMP_URL       VARCHAR2(255);
    v_LMP_FILENAME  VARCHAR2(255);
    v_LMP_BASE_URL  VARCHAR2(60);
	v_RESULT		MEX_RESULT;
BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_LMP_OBJ_TBL();
	v_LMP_BASE_URL := GET_DICTIONARY_VALUE('URL', 0, 'MarketExchange', 'PJM', 'LMP', 'FTR ZONAL LMP');
	v_LMP_FILENAME := TO_CHAR(p_DATE, 'YYYYMM') || '-daftrzone.csv';

    v_LMP_URL := v_LMP_BASE_URL || v_LMP_FILENAME;

    v_RESULT := Mex_Switchboard.FetchURL(v_LMP_URL, p_LOGGER);

	p_STATUS  := v_RESULT.STATUS_CODE;
    IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
    	v_RESPONSE_CLOB := NULL;
    ELSE
    	v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN      
        PARSE_FTR_ZONAL_LMP_MSRS(p_DATE, v_RESPONSE_CLOB, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_LMP.FETCH_FTR_ZONAL_LMP_FILE: ' || SQLERRM;
END FETCH_FTR_ZONAL_LMP_FILE;
----------------------------------------------------------------------------------------------------

END MEX_PJM_LMP;
/
