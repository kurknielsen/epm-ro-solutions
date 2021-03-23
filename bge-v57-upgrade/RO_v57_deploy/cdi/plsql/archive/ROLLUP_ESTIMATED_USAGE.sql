PROCEDURE ROLLUP_ESTIMATED_USAGE(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE) AS
v_PROCEDURE_NAME VARCHAR2(30) := 'ROLLUP_ESTIMATED_USAGE';
CURSOR c_SELECT IS
   SELECT A.AGGR_IDENTIFIER, A.SUPPLIER, 'BGE' EDC_EXTERNAL_ID, E.ESP_ID, B.BEGIN_DATE, B.END_DATE, TRIM(A.RTO_POOL_ID) || c_DEFAULT_PLC_BAND "RTO_POOL_ID", C.PERIOD_ID, C.TEMPLATE_ID, COUNT(*) "ACCOUNT_COUNT", SUM(D.PROFILED_USAGE * C.USAGE_FACTOR) "ESTIMATED_USAGE"
   FROM BGE_MASTER_ACCOUNT          A
      JOIN CDI_TEMP_ESTIMATE_USAGE  B ON B.BILL_ACCOUNT = A.BILL_ACCOUNT AND B.SERVICE_POINT = A.SERVICE_POINT
      JOIN CDI_TOU_UF_LOOKUP        C ON C.BILL_ACCOUNT = A.BILL_ACCOUNT AND C.SERVICE_POINT = A.SERVICE_POINT AND C.TEMPLATE_ID = B.TEMPLATE_ID AND C.PERIOD_ID = B.PERIOD_ID
      JOIN CDI_TOU_PROFILES_BY_DATE D ON D.TEMPLATE_ID = C.TEMPLATE_ID AND D.PERIOD_ID = C.PERIOD_ID AND D.CUT_DATE BETWEEN B.BEGIN_DATE AND B.END_DATE
      JOIN ENERGY_SERVICE_PROVIDER  E ON E.ESP_EXTERNAL_IDENTIFIER = A.SUPPLIER
   WHERE A.IDR_STATUS <> 'Y'
      AND A.EFFECTIVE_DATE   <= B.END_DATE
      AND A.TERMINATION_DATE >= B.BEGIN_DATE
   GROUP BY A.AGGR_IDENTIFIER, A.SUPPLIER, E.ESP_ID, B.BEGIN_DATE, B.END_DATE, TRIM(A.RTO_POOL_ID) || c_DEFAULT_PLC_BAND, C.PERIOD_ID, C.TEMPLATE_ID;
v_COUNT        PLS_INTEGER := 0;
v_UPDATE_COUNT PLS_INTEGER := 0;
v_INSERT_COUNT PLS_INTEGER := 0;
v_MARK_TIME    PLS_INTEGER := DBMS_UTILITY.GET_TIME;
BEGIN
   EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_ESTIMATED_USAGE';
   EXECUTE IMMEDIATE 'TRUNCATE TABLE SYNCH_DATES';
   EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_TEMP_ESTIMATE_USAGE';
   INSERT INTO SYNCH_DATES(SYNCH_DATE) SELECT COLUMN_VALUE DAYS FROM TABLE(CAST(GET_DATE_RANGE_INTERVAL(p_BEGIN_DATE, p_END_DATE, 'D') AS DATE_ARRAY));
   COMMIT;

   INSERT INTO CDI_TEMP_ESTIMATE_USAGE(BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD, BEGIN_DATE, END_DATE, DATE_COUNT)
   WITH SELECT_CONTENT AS
      (SELECT BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD, MIN(BEGIN_DATE) BEGIN_DATE, MAX(END_DATE) END_DATE, COUNT(*) DATE_COUNT
      FROM BGE_RTO_MONTHLY_USAGE
      WHERE BEGIN_DATE <= p_END_DATE
         AND END_DATE >= p_BEGIN_DATE
         AND READ_CODE <> 'AL'
      GROUP BY BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD)
   SELECT BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD, p_BEGIN_DATE, BEGIN_DATE-1, DATE_COUNT
   FROM SELECT_CONTENT
   WHERE 0 < CASE WHEN BEGIN_DATE > p_BEGIN_DATE THEN 1 ELSE 0 END + CASE WHEN END_DATE < p_END_DATE THEN 0 ELSE 0 END;

   INSERT INTO CDI_TEMP_ESTIMATE_USAGE(BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD, BEGIN_DATE, END_DATE, DATE_COUNT)
   WITH SELECT_CONTENT AS
      (SELECT BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD, MIN(BEGIN_DATE) BEGIN_DATE, MAX(END_DATE) END_DATE, COUNT(*) DATE_COUNT
      FROM BGE_RTO_MONTHLY_USAGE
      WHERE BEGIN_DATE <= p_END_DATE
         AND END_DATE >= p_BEGIN_DATE
         AND READ_CODE <> 'AL'
      GROUP BY BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD)
   SELECT BILL_ACCOUNT, SERVICE_POINT, TEMPLATE_ID, PERIOD_ID, TIME_PERIOD, END_DATE+1, p_END_DATE -1, DATE_COUNT
   FROM SELECT_CONTENT
   WHERE 0 < CASE WHEN BEGIN_DATE > p_BEGIN_DATE THEN 0 ELSE 0 END + CASE WHEN END_DATE < p_END_DATE THEN 1 ELSE 0 END;

   QUICK_ANALYZE('SYNCH_DATES');
   QUICK_ANALYZE('CDI_ACCOUNT_PLC_BAND');
   QUICK_ANALYZE('BGE_MASTER_ACCOUNT');
   QUICK_ANALYZE('CDI_ACCOUNT_PLC_BAND');
   QUICK_ANALYZE('CDI_TEMP_ESTIMATE_USAGE');

   FOR v_SELECT IN c_SELECT LOOP
      UPDATE CDI_ESTIMATED_USAGE
      SET END_DATE = v_SELECT.BEGIN_DATE
      WHERE AGGR_IDENTIFIER           = v_SELECT.AGGR_IDENTIFIER
         AND SUPPLIER                 = v_SELECT.SUPPLIER
         AND EDC_EXTERNAL_ID          = v_SELECT.EDC_EXTERNAL_ID
         AND END_DATE                 = v_SELECT.BEGIN_DATE -1
         AND RTO_POOL_ID              = v_SELECT.RTO_POOL_ID
         AND TEMPLATE_ID              =  v_SELECT.TEMPLATE_ID
         AND PERIOD_ID                =  v_SELECT.PERIOD_ID
         AND ACCOUNT_COUNT            = v_SELECT.ACCOUNT_COUNT
         AND NVL(ESTIMATED_USAGE,-99) = NVL(v_SELECT.ESTIMATED_USAGE,-99);
      IF SQL%ROWCOUNT = 0 THEN
         INSERT INTO CDI_ESTIMATED_USAGE(AGGR_IDENTIFIER, SUPPLIER, EDC_EXTERNAL_ID, ESP_ID, BEGIN_DATE, END_DATE, RTO_POOL_ID, PERIOD_ID, TEMPLATE_ID, ACCOUNT_COUNT, ESTIMATED_USAGE)
         VALUES (v_SELECT.AGGR_IDENTIFIER, v_SELECT.SUPPLIER, v_SELECT.EDC_EXTERNAL_ID, v_SELECT.ESP_ID, v_SELECT.BEGIN_DATE, v_SELECT.END_DATE, v_SELECT.RTO_POOL_ID, v_SELECT.PERIOD_ID, v_SELECT.TEMPLATE_ID, v_SELECT.ACCOUNT_COUNT, v_SELECT.ESTIMATED_USAGE);
         v_INSERT_COUNT := v_INSERT_COUNT + 1;         
      ELSE
         v_UPDATE_COUNT := v_UPDATE_COUNT + 1;         
      END IF;
      v_COUNT := v_COUNT + 1;
      IF MOD(v_COUNT, 20000) = 0 THEN
         COMMIT;
      END IF;
   END LOOP;
   COMMIT;
   LOGS.LOG_INFO('Records Posted To The CDI_ESTIMATED_USAGE Table, Insert Count: ' || TO_CHAR(v_INSERT_COUNT) || ', Update Count: ' || TO_CHAR(v_UPDATE_COUNT), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
   LOGS.LOG_INFO('Elapsed Seconds: ' || TO_CHAR(ROUND((DBMS_UTILITY.GET_TIME-v_MARK_TIME)/100)), v_PROCEDURE_NAME, c_STEP_NAME, c_PACKAGE_NAME);
END ROLLUP_ESTIMATED_USAGE;