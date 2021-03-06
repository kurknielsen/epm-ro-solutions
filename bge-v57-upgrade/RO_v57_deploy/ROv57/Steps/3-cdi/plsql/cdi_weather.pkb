CREATE OR REPLACE PACKAGE BODY CDI_WEATHER AS

-- Package Constants --
c_PACKAGE_NAME                 CONSTANT VARCHAR2(32) := 'CDI_WEATHER';
c_STEP_NAME                    CONSTANT VARCHAR2(32) := '';
c_SYSTEM_SETTING_LIBRARY       CONSTANT NUMBER(1)    := 0;
c_SYSTEM_SETTING_MODULE        CONSTANT VARCHAR2(32) := 'Client Data Interface';
c_SYSTEM_SETTING_KEY1          CONSTANT VARCHAR2(32) := 'Weather Service';
c_IMPORT_WEATHER               CONSTANT VARCHAR2(32) := 'CDI: Import Weather';
c_BWI_STATION_NAME             CONSTANT VARCHAR2(16) := 'BWI';
c_DRYBULB_PARAMETER_NAME       CONSTANT VARCHAR2(16) := 'Drybulb';
c_DEWPOINT_PARAMETER_NAME      CONSTANT VARCHAR2(16) := 'Dewpoint';
c_WTHI_PARAMETER_NAME          CONSTANT VARCHAR2(16) := 'WTHI';
c_DATE_FORMAT                  CONSTANT VARCHAR2(32) := 'MM/DD/YYYY';
c_DATE_TIME_FORMAT             CONSTANT VARCHAR2(32) := 'MM/DD/YYYY HH24:MI:SS';
c_INPUT_FILE_DATE_FORMAT       CONSTANT VARCHAR2(16) := 'YYYYMMDD';
c_MINIMUM_USEFUL_LINE_LENGTH   CONSTANT NUMBER(2)    := 50;

l_BWI_STATION_ID               PLS_INTEGER;
l_DRYBULB_PARAMETER_ID         PLS_INTEGER;
l_DEWPOINT_PARAMETER_ID        PLS_INTEGER;
l_WTHI_PARAMETER_ID            PLS_INTEGER;
l_WEATHER_SERVICE_HOST         VARCHAR2(32);
l_WEATHER_SERVICE_USER         VARCHAR2(32);
l_WEATHER_SERVICE_PASS         VARCHAR2(32);
l_WEATHER_SERVICE_PORT         VARCHAR2(32);
l_WEATHER_SERVICE_HDIR         VARCHAR2(256);

PROCEDURE INITIALIZE_INTERFACE AS
BEGIN
   l_WEATHER_SERVICE_HOST := GET_DICTIONARY_VALUE('Host',           c_SYSTEM_SETTING_LIBRARY, c_SYSTEM_SETTING_MODULE, c_SYSTEM_SETTING_KEY1);
   l_WEATHER_SERVICE_USER := GET_DICTIONARY_VALUE('User',           c_SYSTEM_SETTING_LIBRARY, c_SYSTEM_SETTING_MODULE, c_SYSTEM_SETTING_KEY1);
   l_WEATHER_SERVICE_PASS := GET_DICTIONARY_VALUE('Password',       c_SYSTEM_SETTING_LIBRARY, c_SYSTEM_SETTING_MODULE, c_SYSTEM_SETTING_KEY1);
   l_WEATHER_SERVICE_PORT := GET_DICTIONARY_VALUE('Port',           c_SYSTEM_SETTING_LIBRARY, c_SYSTEM_SETTING_MODULE, c_SYSTEM_SETTING_KEY1);
   l_WEATHER_SERVICE_HDIR := GET_DICTIONARY_VALUE('Host Directory', c_SYSTEM_SETTING_LIBRARY, c_SYSTEM_SETTING_MODULE, c_SYSTEM_SETTING_KEY1);
   SELECT MAX(STATION_ID)   INTO l_BWI_STATION_ID        FROM WEATHER_STATION   WHERE UPPER(STATION_ALIAS)   = 'BWI';
   SELECT MAX(PARAMETER_ID) INTO l_DRYBULB_PARAMETER_ID  FROM WEATHER_PARAMETER WHERE UPPER(PARAMETER_ALIAS) = 'DRYBULB';
   SELECT MAX(PARAMETER_ID) INTO l_DEWPOINT_PARAMETER_ID FROM WEATHER_PARAMETER WHERE UPPER(PARAMETER_ALIAS) = 'DEWPOINT';
   SELECT MAX(PARAMETER_ID) INTO l_WTHI_PARAMETER_ID     FROM WEATHER_PARAMETER WHERE UPPER(PARAMETER_ALIAS) = 'WTHI';
END INITIALIZE_INTERFACE;

PROCEDURE CALCULATE_PARAMETER_WIHI(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE) AS
v_PROCEDURE_NAME VARCHAR2(30) := 'CALCULATE_PARAMETER_WIHI';
CURSOR c_SELECT IS
   SELECT DISTINCT(TRUNC(COLUMN_VALUE,'DD')) PARAMETER_DATE
   FROM TABLE(CAST(CDI_GET_DATE_RANGE_INTERVAL(p_BEGIN_DATE, p_END_DATE,'H') AS DATE_COLLECTION)) A
   WHERE NOT EXISTS (SELECT NULL FROM STATION_PARAMETER_VALUE WHERE PARAMETER_DATE = A.COLUMN_VALUE AND PARAMETER_ID = l_WTHI_PARAMETER_ID);
v_MARK_TIME PLS_INTEGER := DBMS_UTILITY.GET_TIME;
BEGIN
   MERGE INTO STATION_PARAMETER_VALUE T
   USING
   (SELECT GA.BASE_CASE_ID  "CASE_ID",
      BULB_D.STATION_ID     "STATION_ID",
      l_WTHI_PARAMETER_ID   "PARAMETER_ID",
      BULB_D.PARAMETER_CODE "PARAMETER_CODE",
      BULB_D.PARAMETER_DATE "PARAMETER_DATE",
      (10 * (17.5 + 0.2 * DEW_D.PARAMETER_VAL + 0.55 * BULB_D.PARAMETER_VAL) + 3 * (17.5 + 0.2 * DEW_D1.PARAMETER_VAL + 0.55 * BULB_D1.PARAMETER_VAL) + 1 * (17.5 + 0.2 * DEW_D2.PARAMETER_VAL + 0.55 * BULB_D2.PARAMETER_VAL))/14 "PARAMETER_VAL"
   FROM STATION_PARAMETER_VALUE    BULB_D
      JOIN STATION_PARAMETER_VALUE BULB_D1 ON BULB_D1.STATION_ID = BULB_D.STATION_ID AND BULB_D1.PARAMETER_ID = BULB_D.PARAMETER_ID     AND BULB_D1.PARAMETER_DATE = BULB_D.PARAMETER_DATE - 1 AND BULB_D1.PARAMETER_CODE = BULB_D.PARAMETER_CODE
      JOIN STATION_PARAMETER_VALUE BULB_D2 ON BULB_D2.STATION_ID = BULB_D.STATION_ID AND BULB_D2.PARAMETER_ID = BULB_D.PARAMETER_ID     AND BULB_D1.PARAMETER_DATE = BULB_D.PARAMETER_DATE - 2 AND BULB_D2.PARAMETER_CODE = BULB_D.PARAMETER_CODE
      JOIN STATION_PARAMETER_VALUE DEW_D   ON DEW_D.STATION_ID   = BULB_D.STATION_ID AND DEW_D.PARAMETER_ID   = l_DEWPOINT_PARAMETER_ID AND DEW_D.PARAMETER_DATE   = BULB_D.PARAMETER_DATE     AND DEW_D.PARAMETER_CODE   = BULB_D.PARAMETER_CODE
      JOIN STATION_PARAMETER_VALUE DEW_D1  ON DEW_D1.STATION_ID  = DEW_D.STATION_ID  AND DEW_D1.PARAMETER_ID  = DEW_D.PARAMETER_ID      AND DEW_D1.PARAMETER_DATE  = DEW_D.PARAMETER_DATE - 1  AND DEW_D1.PARAMETER_CODE  = DEW_D.PARAMETER_CODE
      JOIN STATION_PARAMETER_VALUE DEW_D2  ON DEW_D2.STATION_ID  = DEW_D.STATION_ID  AND DEW_D2.PARAMETER_ID  = DEW_D.PARAMETER_ID      AND DEW_D2.PARAMETER_DATE  = DEW_D.PARAMETER_DATE - 1  AND DEW_D2.PARAMETER_CODE  = DEW_D.PARAMETER_CODE
   WHERE BULB_D.STATION_ID = l_BWI_STATION_ID
      AND BULB_D.PARAMETER_ID = l_DRYBULB_PARAMETER_ID
      AND BULB_D.PARAMETER_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) S
   ON (T.PARAMETER_DATE = S.PARAMETER_DATE AND T.CASE_ID = S.CASE_ID AND T.STATION_ID = S.STATION_ID AND T.PARAMETER_ID = S.PARAMETER_ID AND T.PARAMETER_CODE = S.PARAMETER_CODE)
   WHEN MATCHED THEN
      UPDATE SET T.PARAMETER_VAL = S.PARAMETER_VAL
   WHEN NOT MATCHED THEN
      INSERT(CASE_ID, STATION_ID, PARAMETER_ID, PARAMETER_CODE, PARAMETER_DATE, PARAMETER_VAL)
      VALUES (S.CASE_ID, S.STATION_ID, S.PARAMETER_ID, S.PARAMETER_CODE, S.PARAMETER_DATE, S.PARAMETER_VAL);
   FOR v_SELECT IN c_SELECT LOOP
      LOGS.LOG_NOTICE('WIHI Parameter Not Calculated For ' || TO_CHAR(v_SELECT.PARAMETER_DATE, c_DATE_FORMAT), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
   END LOOP;
   LOGS.LOG_INFO('Elapsed Seconds: ' || TO_CHAR(ROUND((DBMS_UTILITY.GET_TIME-v_MARK_TIME)/100)), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
END CALCULATE_PARAMETER_WIHI;

FUNCTION IS_VALID_DATE(p_DATE_STRING IN OUT NOCOPY VARCHAR2) RETURN BOOLEAN IS
v_DATE DATE;
BEGIN
   v_DATE := TO_DATE(p_DATE_STRING, c_INPUT_FILE_DATE_FORMAT);
   RETURN TRUE;
EXCEPTION
   WHEN OTHERS THEN
      RETURN FALSE;
END IS_VALID_DATE;

PROCEDURE EXTRACT_VALIDATE_STORE(p_STAGING_CONTENT IN VARCHAR2) AS
v_PROCEDURE_NAME VARCHAR2(30) := 'EXTRACT_VALIDATE_STORE';
v_BEGIN_DATE          DATE := CONSTANTS.HIGH_DATE;
v_END_DATE            DATE := CONSTANTS.LOW_DATE;
v_FORECAST_BEGIN_DATE DATE := CONSTANTS.HIGH_DATE;
v_FORECAST_END_DATE   DATE := CONSTANTS.LOW_DATE;
v_ACTUAL_BEGIN_DATE   DATE := CONSTANTS.HIGH_DATE;
v_ACTUAL_END_DATE     DATE := CONSTANTS.LOW_DATE;
v_PARAMETER_DATE      DATE;
v_FIELDS GA.STRING_TABLE;
v_COUNT PLS_INTEGER := 0;
v_STATUS PLS_INTEGER;
v_STATION_PARAMETER_VALUE STATION_PARAMETER_VALUE%ROWTYPE;
BEGIN
   LOGS.LOG_DEBUG(p_STAGING_CONTENT, v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
   IF TRIM(p_STAGING_CONTENT) IS NULL OR LENGTH(TRIM(p_STAGING_CONTENT)) < c_MINIMUM_USEFUL_LINE_LENGTH THEN
      LOGS.LOG_WARN('Invalid File Record: ' || TRIM(p_STAGING_CONTENT), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
   ELSE
      UT.TOKENS_FROM_STRING(p_STAGING_CONTENT, ',', v_FIELDS);
      IF v_FIELDS(1) <> c_BWI_STATION_NAME THEN
         LOGS.LOG_WARN('Invalid Weather Station Identifier: ' || v_FIELDS(1), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
      ELSIF v_FIELDS(2) NOT IN ('Forecast','Actual') THEN
         LOGS.LOG_WARN('Invalid Weather Parameter Code: ' || v_FIELDS(2), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
      ELSIF v_FIELDS(3) NOT IN (c_DRYBULB_PARAMETER_NAME, c_DEWPOINT_PARAMETER_NAME) THEN
         LOGS.LOG_WARN('Invalid Weather Parameter Identifier: ' || v_FIELDS(3), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
      ELSIF NOT IS_VALID_DATE(v_FIELDS(4)) THEN
         LOGS.LOG_WARN('Invalid Weather Parameter Date: ' || v_FIELDS(4), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
      ELSE
         v_COUNT := v_COUNT + 1;
         v_STATION_PARAMETER_VALUE.STATION_ID := l_BWI_STATION_ID;
         v_STATION_PARAMETER_VALUE.PARAMETER_ID := CASE WHEN v_FIELDS(3) = c_DRYBULB_PARAMETER_NAME THEN l_DRYBULB_PARAMETER_ID ELSE l_DEWPOINT_PARAMETER_ID END;
         v_STATION_PARAMETER_VALUE.PARAMETER_CODE := SUBSTR(v_FIELDS(2),1,1);
         v_STATION_PARAMETER_VALUE.PARAMETER_DATE := TO_DATE(v_FIELDS(4), c_INPUT_FILE_DATE_FORMAT);
         v_BEGIN_DATE := LEAST(v_STATION_PARAMETER_VALUE.PARAMETER_DATE, v_BEGIN_DATE);
         v_END_DATE := GREATEST(v_STATION_PARAMETER_VALUE.PARAMETER_DATE, v_END_DATE);
         IF v_STATION_PARAMETER_VALUE.PARAMETER_CODE = CONSTANTS.CODE_ACTUAL THEN
            v_ACTUAL_BEGIN_DATE := LEAST(v_STATION_PARAMETER_VALUE.PARAMETER_DATE, v_ACTUAL_BEGIN_DATE);
            v_ACTUAL_END_DATE := GREATEST(v_STATION_PARAMETER_VALUE.PARAMETER_DATE, v_ACTUAL_END_DATE);
         ELSE
            v_FORECAST_BEGIN_DATE := LEAST(v_STATION_PARAMETER_VALUE.PARAMETER_DATE, v_FORECAST_BEGIN_DATE);
            v_FORECAST_END_DATE := GREATEST(v_STATION_PARAMETER_VALUE.PARAMETER_DATE, v_FORECAST_END_DATE);
         END IF;
         FOR v_INDEX IN 5..v_FIELDS.COUNT LOOP
            v_STATION_PARAMETER_VALUE.PARAMETER_VAL:= TO_NUMBER(v_FIELDS(v_INDEX));
            v_PARAMETER_DATE := v_STATION_PARAMETER_VALUE.PARAMETER_DATE + 1/24;
            IF v_PARAMETER_DATE <> DST_SPRING_AHEAD_DATE(v_PARAMETER_DATE) THEN   -- Skip Hour Ending 2 AM For The Spring Transition Date --
               IF v_PARAMETER_DATE = DST_FALL_BACK_DATE(v_PARAMETER_DATE) AND v_FIELDS.COUNT = 28 THEN -- Add Another Hour Ending 2 AM For The Fall Transition Date --
                  WR.PUT_STATION_PARAMETER_VALUE(v_STATION_PARAMETER_VALUE.STATION_ID, v_STATION_PARAMETER_VALUE.PARAMETER_ID, v_STATION_PARAMETER_VALUE.PARAMETER_CODE, v_PARAMETER_DATE, GA.LOCAL_TIME_ZONE, v_STATION_PARAMETER_VALUE.PARAMETER_VAL, v_STATUS);
                  v_PARAMETER_DATE := v_PARAMETER_DATE + 1/24;
               END IF;
               WR.PUT_STATION_PARAMETER_VALUE(v_STATION_PARAMETER_VALUE.STATION_ID, v_STATION_PARAMETER_VALUE.PARAMETER_ID, v_STATION_PARAMETER_VALUE.PARAMETER_CODE, v_PARAMETER_DATE, GA.LOCAL_TIME_ZONE, v_STATION_PARAMETER_VALUE.PARAMETER_VAL, v_STATUS);
            END IF;
         END LOOP;
      END IF; 
      IF v_COUNT > 0 THEN                    
         INSERT INTO CDI_WEATHER_HISTORY(BEGIN_DATE, END_DATE, REC_TS) VALUES (v_BEGIN_DATE, v_END_DATE, SYSTIMESTAMP);
         INSERT INTO CDI_WEATHER_HISTORY(BEGIN_DATE, END_DATE, REC_TS, PARAMETER_CODE) VALUES (v_ACTUAL_BEGIN_DATE, v_ACTUAL_END_DATE, SYSTIMESTAMP, 'A');
         INSERT INTO CDI_WEATHER_HISTORY(BEGIN_DATE, END_DATE, REC_TS, PARAMETER_CODE) VALUES (v_FORECAST_BEGIN_DATE, v_FORECAST_END_DATE, SYSTIMESTAMP, 'F');
      ELSE
         LOGS.LOG_ERROR('No Useful Content Extracted From The Weather Parameter Staging Table', v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
      END IF;
   END IF;
END EXTRACT_VALIDATE_STORE;

PROCEDURE IMPORT_WEATHER AS
CURSOR c_SELECT IS SELECT STAGING_CONTENT FROM CDI_WEATHER_PARAMETER_STAGING ORDER BY STAGING_ID;
BEGIN
   FOR v_SELECT IN c_SELECT LOOP
      EXTRACT_VALIDATE_STORE(v_SELECT.STAGING_CONTENT);
   END LOOP;
END IMPORT_WEATHER;

PROCEDURE RUN_INTERFACE AS
v_PROCEDURE_NAME VARCHAR2(30) := 'RUN_INTERFACE';
v_TIMESTAMP TIMESTAMP := SYSTIMESTAMP;
v_MESSAGE VARCHAR2(1000);
v_STATUS NUMBER;
v_MARK_TIME PLS_INTEGER := DBMS_UTILITY.GET_TIME;
BEGIN
   LOGS.START_PROCESS(c_IMPORT_WEATHER);
   LOGS.LOG_INFO(c_IMPORT_WEATHER, v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
   IMPORT_WEATHER;
   LOGS.LOG_INFO(c_IMPORT_WEATHER || ' Complete. Elapsed Seconds: ' || TO_CHAR(ROUND((DBMS_UTILITY.GET_TIME-v_MARK_TIME)/100)), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
   LOGS.STOP_PROCESS(v_MESSAGE, v_STATUS);
EXCEPTION
   WHEN OTHERS THEN
      ROLLBACK;
      ERRS.ABORT_PROCESS;
END RUN_INTERFACE;

PROCEDURE DEX_INTERFACE
   (
   p_IMPORT_FILE      IN CLOB,
   p_IMPORT_FILE_PATH IN VARCHAR2,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   ) AS
v_CONTAINER PARSE_UTIL.BIG_STRING_TABLE_MP;
BEGIN
   EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_WEATHER_PARAMETER_STAGING';
-- Parse The File Into Records And Post To The Staging Table --   
   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_IMPORT_FILE, v_CONTAINER);
   p_MESSAGE := 'Number Of Records Read From Input Container: ' || TO_CHAR(v_CONTAINER.COUNT);
-- Process Each Line --
   FOR v_INDEX IN v_CONTAINER.FIRST..v_CONTAINER.LAST LOOP
      INSERT INTO CDI_WEATHER_PARAMETER_STAGING(STAGING_CONTENT)
      VALUES(v_CONTAINER(v_INDEX));
   END LOOP;
   COMMIT;
   RUN_INTERFACE;
EXCEPTION
   WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := SQLERRM;
END DEX_INTERFACE;

END CDI_WEATHER;
/
