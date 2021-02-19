CREATE OR REPLACE PACKAGE BODY CDI_REPORT AS

   /*============================================================================*
   *   PACKAGE BODY                                                             *
   *============================================================================*/

   /*----------------------------------------------------------------------------*
   *   PRIVATE VARIABLES                                                        *
   *----------------------------------------------------------------------------*/

   g_STEP_NAME     PROCESS_EVENTS.STEP_NAME%TYPE;
   g_ERROR_MESSAGE VARCHAR2(1024);

   /*----------------------------------------------------------------------------*
   *   BUILD_DAY_CUT_RANGE                                                      *
   *----------------------------------------------------------------------------*/
   PROCEDURE BUILD_DAY_CUT_RANGE
   (
      p_BEGIN_DATE IN DATE,
      p_END_DATE   IN DATE
   ) IS
      -- LOCAL VARIABLES --
      v_NUM_DAYS  PLS_INTEGER;
      v_DAY_BEGIN DATE;
      v_DAY_END   DATE;
   BEGIN
      v_NUM_DAYS := p_END_DATE - p_BEGIN_DATE + 1;
      EXECUTE IMMEDIATE 'TRUNCATE TABLE DAY_CUT_RANGE';
      FOR I IN 1 .. v_NUM_DAYS
      LOOP
         UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,
                           p_BEGIN_DATE + (I - 1),
                           k_LOCAL_TIME_ZONE,
                           v_DAY_BEGIN,
                           v_DAY_END);
         INSERT INTO DAY_CUT_RANGE
         VALUES
            (p_BEGIN_DATE + (I - 1),
             v_DAY_BEGIN,
             v_DAY_END);
      END LOOP;
   END;

   -- --------------------------------------------------------------------------------------
   -- ID_FOR_STATEMENT_TYPE
   -- --------------------------------------------------------------------------------------
   -- MODIFICATION HISTORY
   -- Person         Date         Comments
   -- -----------    -----------  ----------------------------------------------------------
   --  KN            Jan 6 2014   Created
   -- --------------------------------------------------------------------------------------
   FUNCTION id_for_statement_type(p_statement_type_name IN VARCHAR) RETURN NUMBER IS
      v_statement_type_id   NUMBER;
      v_statement_type_name statement_type.statement_type_name%TYPE;
   BEGIN

      v_statement_type_name := ltrim(rtrim(p_statement_type_name));

      IF v_statement_type_name IS NULL THEN
         RETURN 0;
      END IF;

      BEGIN
         SELECT statement_type_id
           INTO v_statement_type_id
           FROM statement_type
          WHERE statement_type_name = v_statement_type_name;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            errs.log_and_continue(p_log_level => logs.c_level_debug);
            v_statement_type_id := ga.no_data_found;
      END;

      RETURN v_statement_type_id;
   END id_for_statement_type;

   /*----------------------------------------------------------------------------*
   *   USAGE_ALLOCATION_REPORT                                                  *
   *----------------------------------------------------------------------------*/
   PROCEDURE USAGE_ALLOCATION_REPORT
   (
      p_MODEL_ID      IN NUMBER,
      p_SCHEDULE_TYPE IN CHAR,
      p_BEGIN_DATE    IN DATE,
      p_END_DATE      IN DATE,
      p_AS_OF_DATE    IN DATE,
      p_TIME_ZONE     IN VARCHAR,
      p_CONTEXT_ID1   IN NUMBER,
      p_CONTEXT_ID2   IN NUMBER,
      p_CONTEXT_ID3   IN NUMBER,
      p_REPORT_NAME   IN VARCHAR2,
      p_STATUS        OUT NUMBER,
      p_CURSOR        IN OUT REF_CURSOR
   ) IS

      -- LOCAL VARIABLES --
      v_BEGIN_DATE     DATE;
      v_END_DATE       DATE;
      v_CUT_BEGIN_DATE DATE;
      v_CUT_END_DATE   DATE;

   BEGIN

      g_STEP_NAME  := 'USAGE_ALLOCATION_REPORT.GET PARAMETERS';
      p_STATUS     := GA.SUCCESS;
      v_BEGIN_DATE := TRUNC(p_BEGIN_DATE, 'MONTH');
      v_END_DATE   := LAST_DAY(v_BEGIN_DATE);

      g_STEP_NAME := 'USAGE_ALLOCATION_REPORT.BUILD DATE XREF';
      BUILD_DAY_CUT_RANGE(v_BEGIN_DATE, v_END_DATE);

      g_STEP_NAME := 'USAGE_ALLOCATION_REPORT.GET CUT RANGE';
      UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,
                        v_BEGIN_DATE,
                        v_END_DATE,
                        k_LOCAL_TIME_ZONE,
                        v_CUT_BEGIN_DATE,
                        v_CUT_END_DATE);

      g_STEP_NAME := 'USAGE_ALLOCATION_REPORT.TRUNCATE TEMP';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_EXTERNAL_USAGE_SUMMARY';
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CDI_INTERNAL_USAGE_SUMMARY';

      g_STEP_NAME := 'USAGE_ALLOCATION_REPORT.QUERY EXTERNAL';
      INSERT INTO CDI_EXTERNAL_USAGE_SUMMARY
      -- Interval Account
        ---@@ RMUD Modification
         SELECT CDI_SUPPLIER, CDI_SEGMENT,  CDI_METER_TYPE,CDI_IS_AGGREGATE_ACCOUNT, CDI_SERVICE_DATE, SUM(CDI_KWH)
         FROM
           (SELECT SUPPLIER_EXTERNAL_ID AS CDI_SUPPLIER,
                   SEGMENT_ID CDI_SEGMENT,
                   SUBSTR(METER_TYPE, 1, 1) AS CDI_METER_TYPE,
                   0 AS CDI_IS_AGGREGATE_ACCOUNT,
                   USAGE_DATE AS CDI_SERVICE_DATE,
                        SUM(NVL(INTERVAL_1, 0) + NVL(INTERVAL_2, 0) +
                            NVL(INTERVAL_3, 0) + NVL(INTERVAL_4, 0) +
                            NVL(INTERVAL_5, 0) + NVL(INTERVAL_6, 0) +
                            NVL(INTERVAL_7, 0) + NVL(INTERVAL_8, 0) +
                            NVL(INTERVAL_9, 0) + NVL(INTERVAL_10, 0) +
                            NVL(INTERVAL_11, 0) + NVL(INTERVAL_12, 0) +
                            NVL(INTERVAL_13, 0) + NVL(INTERVAL_14, 0) +
                            NVL(INTERVAL_15, 0) + NVL(INTERVAL_16, 0) +
                            NVL(INTERVAL_17, 0) + NVL(INTERVAL_18, 0) +
                            NVL(INTERVAL_19, 0) + NVL(INTERVAL_20, 0) +
                            NVL(INTERVAL_21, 0) + NVL(INTERVAL_22, 0) +
                            NVL(INTERVAL_23, 0) + NVL(INTERVAL_24, 0) +
                            NVL(INTERVAL_25, 0)) AS CDI_KWH
               FROM CDI_RO_INTERVAL_USAGE A
               WHERE USAGE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
               GROUP BY SUPPLIER_EXTERNAL_ID,SEGMENT_ID, SUBSTR(METER_TYPE, 1, 1),  USAGE_DATE
             UNION ALL
                SELECT SUPPLIER_EXTERNAL_ID AS CDI_SUPPLIER,  SEGMENT_ID CDI_SEGMENT, 'I' AS CDI_METER_TYPE, 0 AS CDI_IS_AGGREGATE_ACCOUNT,
                       USAGE_DATE AS CDI_SERVICE_DATE,
                        SUM(NVL(INTERVAL_1, 0) + NVL(INTERVAL_2, 0) +
                            NVL(INTERVAL_3, 0) + NVL(INTERVAL_4, 0) +
                            NVL(INTERVAL_5, 0) + NVL(INTERVAL_6, 0) +
                            NVL(INTERVAL_7, 0) + NVL(INTERVAL_8, 0) +
                            NVL(INTERVAL_9, 0) + NVL(INTERVAL_10, 0) +
                            NVL(INTERVAL_11, 0) + NVL(INTERVAL_12, 0) +
                            NVL(INTERVAL_13, 0) + NVL(INTERVAL_14, 0) +
                            NVL(INTERVAL_15, 0) + NVL(INTERVAL_16, 0) +
                            NVL(INTERVAL_17, 0) + NVL(INTERVAL_18, 0) +
                            NVL(INTERVAL_19, 0) + NVL(INTERVAL_20, 0) +
                            NVL(INTERVAL_21, 0) + NVL(INTERVAL_22, 0) +
                            NVL(INTERVAL_23, 0) + NVL(INTERVAL_24, 0) +
                            NVL(INTERVAL_25, 0)) AS CDI_KWH
                   FROM CDI_RO_AMI_INTERVAL_USAGE A
                  WHERE USAGE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
                  GROUP BY SUPPLIER_EXTERNAL_ID,  SEGMENT_ID, USAGE_DATE)
            GROUP BY  CDI_SUPPLIER, CDI_SEGMENT,  CDI_METER_TYPE,CDI_IS_AGGREGATE_ACCOUNT, CDI_SERVICE_DATE
         UNION ALL
         -- Period Account
         SELECT C.ESP AS CDI_SUPPLIER,
                C.SEGMENT AS CDI_SEGMENT,
                C.METER_TYPE AS CDI_METER_TYPE,
                C.CDI_IS_AGGREGATE_ACCOUNT,
                C.SERVICE_DATE AS SERVICE_DATE,
                SUM(C.CDI_AVG_KWH) AS CDI_KWH
           FROM ( --2
                 SELECT A.ESP,
                         A.SEGMENT,
                         A.METER_TYPE,
                         A.CDI_IS_AGGREGATE_ACCOUNT,
                         DCA.LOCAL_DAY AS SERVICE_DATE,
                         A.CDI_AVG_KWH
                   FROM ( --3
                          SELECT CCU.SUPPLIER_EXTERNAL_ID ESP,
                                  CCU.SEGMENT_ID SEGMENT,
                                  SUBSTR(CCU.METER_TYPE, 1, 1) METER_TYPE,
                                  GREATEST(CCU.BEGIN_DATE, v_BEGIN_DATE) AS BEGIN_DATE,
                                  LEAST(CCU.END_DATE, v_END_DATE) AS END_DATE,
                                  -- 25662
                                  DECODE(account_model_option, 'AGGREGATE', 1, 0) AS CDI_IS_AGGREGATE_ACCOUNT, --4
                                  CCU.RETAIL_USAGE/(CCU.END_DATE - CCU.BEGIN_DATE + 1) AS CDI_AVG_KWH
                            FROM CDI_CUSTOMER_CONSUMPTION CCU
                            -- @@ RMUD Modification
                            where ACCOUNT_METER_EXTERNAL_ID not like '%_STOU'
                            ) A, --3
                         DAY_CUT_RANGE DCA
                  WHERE DCA.LOCAL_DAY BETWEEN A.BEGIN_DATE AND A.END_DATE) C --2
          GROUP BY C.ESP,
                   C.SEGMENT,
                   C.METER_TYPE,
                   C.CDI_IS_AGGREGATE_ACCOUNT,
                   C.SERVICE_DATE;

      g_STEP_NAME := 'USAGE_ALLOCATION_REPORT.QUERY INTERNAL';
      INSERT INTO CDI_INTERNAL_USAGE_SUMMARY
         SELECT /*+ ORDERED USE_HASH(A,B) USE_HASH(A,C) PARALLEL(A,0) PARALLEL(C,8) PARALLEL(D,0) PARALLEL(E,0)
                          PARALLEL(F,0) PARALLEL(B,0) FULL(A) FULL(B) FULL(D) FULL(E) FULL(F) FULL(C) */
          (SELECT AA.ESP_EXTERNAL_IDENTIFIER
             FROM ENERGY_SERVICE_PROVIDER AA
            WHERE E.ESP_ID = AA.ESP_ID) AS RO_SUPPLIER,
          (SELECT BB.POOL_EXTERNAL_IDENTIFIER
             FROM POOL BB
            WHERE F.POOL_ID = BB.POOL_ID) AS RO_SEGMENT,
          A.METER_TYPE AS RO_METER_TYPE,
          A.IS_AGGREGATE_ACCOUNT AS RO_IS_AGGREGATE_ACCOUNT,
          A.SERVICE_DATE AS RO_SERVICE_DATE,
          SUM(C.LOAD_VAL) AS RO_KWH
           FROM SERVICE_STATE    A,
                SERVICE          D,
                PROVIDER_SERVICE E,
                SERVICE_DELIVERY F,
                DAY_CUT_RANGE    B,
                SERVICE_LOAD     C
          WHERE A.SERVICE_CODE = 'A'
            AND A.SERVICE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
            AND A.SERVICE_ID = D.SERVICE_ID
            AND D.PROVIDER_SERVICE_ID = E.PROVIDER_SERVICE_ID
            AND D.SERVICE_DELIVERY_ID = F.SERVICE_DELIVERY_ID
            AND A.SERVICE_DATE = B.LOCAL_DAY
            AND A.SERVICE_ID = C.SERVICE_ID
            AND C.SERVICE_CODE = 'A'
            AND C.LOAD_DATE BETWEEN B.CUT_BEGIN_DATE AND B.CUT_END_DATE
            AND C.LOAD_CODE = '1'
            AND C.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE
          GROUP BY E.ESP_ID,
                   F.POOL_ID,
                   A.METER_TYPE,
                   A.IS_AGGREGATE_ACCOUNT,
                   A.SERVICE_DATE;

      g_STEP_NAME := 'USAGE_ALLOCATION_REPORT.QUERY';
      OPEN p_CURSOR FOR
         SELECT DECODE(GROUPING(SUPPLIER), 1, 'TOTAL', SUPPLIER) AS SUPPLIER,
                DECODE(GROUPING(METER_TYPE),
                       1,
                       'TOTAL',
                       DECODE(METER_TYPE,
                              'I',
                              'Interval',
                              'P',
                              'Period',
                              'UNKNOWN')) AS METER_TYPE,
                DECODE(GROUPING(IS_AGGREGATE),
                       1,
                       'TOTAL',
                       DECODE(IS_AGGREGATE, 1, 'Yes', 0, 'No', 'UNKNOWN')) AS IS_AGGREGATE,
                DECODE(GROUPING(SEGMENT), 1, 'TOTAL', SEGMENT) AS SEGMENT,
                DECODE(GROUPING(SERVICE_DATE),
                       1,
                       'TOTAL',
                       TO_CHAR(SERVICE_DATE, 'MM/DD/YYYY')) AS SERVICE_DATE,
                ROUND(SUM(RO_KWH), 2) AS RO_KWH,
                ROUND(SUM(CDI_KWH), 2) AS CDI_KWH,
                ROUND(SUM(NVL(abs(RO_KWH), 0)) - SUM(NVL(CDI_KWH, 0)), 2) AS DIFF,
                DECODE(SUM(NVL(CDI_KWH, 0)),
                       0,
                       DECODE(SUM(NVL(RO_KWH, 0)), 0, 0, 9999999),
                       ROUND((SUM(NVL(abs(RO_KWH), 0)) - SUM(NVL(CDI_KWH, 0))) * 100 /
                             SUM(NVL(CDI_KWH, 0)),
                             2)) AS PCT_DIFF
           FROM (SELECT /*+ ORDERED FULL(AAA) FULL(BBB) USE_HASH(AAA,BBB) */
                  COALESCE(AAA.RO_METER_TYPE, BBB.CDI_METER_TYPE) AS METER_TYPE,
                  COALESCE(AAA.RO_IS_AGGREGATE_ACCOUNT,
                           BBB.CDI_IS_AGGREGATE_ACCOUNT) AS IS_AGGREGATE,
                  COALESCE(AAA.RO_SUPPLIER, BBB.CDI_SUPPLIER) AS SUPPLIER,
                  COALESCE(AAA.RO_SEGMENT, BBB.CDI_SEGMENT) AS SEGMENT,
                  COALESCE(AAA.RO_SERVICE_DATE, BBB.CDI_SERVICE_DATE) AS SERVICE_DATE,
                  AAA.RO_KWH AS RO_KWH,
                  BBB.CDI_KWH AS CDI_KWH
                   FROM CDI_INTERNAL_USAGE_SUMMARY AAA
                   FULL OUTER JOIN CDI_EXTERNAL_USAGE_SUMMARY BBB
                     ON AAA.RO_SUPPLIER = BBB.CDI_SUPPLIER
                    AND AAA.RO_SEGMENT = BBB.CDI_SEGMENT
                    AND AAA.RO_METER_TYPE = BBB.CDI_METER_TYPE
                    AND AAA.RO_IS_AGGREGATE_ACCOUNT =
                        BBB.CDI_IS_AGGREGATE_ACCOUNT
                    AND AAA.RO_SERVICE_DATE = BBB.CDI_SERVICE_DATE) AAAA
          GROUP BY ROLLUP(SUPPLIER,
                          METER_TYPE,
                          IS_AGGREGATE,
                          SEGMENT,
                          SERVICE_DATE)
          ORDER BY SUPPLIER,
                   METER_TYPE,
                   IS_AGGREGATE,
                   SEGMENT,
                   SERVICE_DATE;

   EXCEPTION
      WHEN OTHERS THEN
         g_ERROR_MESSAGE := SQLERRM;
         OPEN p_CURSOR FOR
            SELECT g_STEP_NAME     AS STEP,
                   g_ERROR_MESSAGE AS ERROR_MESSAGE
              FROM DUAL;
   END USAGE_ALLOCATION_REPORT;

   -----------------------------------------------------------------------------
   -- User     Date        CR                      Comments
   -- ----   ----------- ------   --------------------------------------------------
   --  SR     20-MAR-2012  COMEd 5.3- Enhancements   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE GET_UFE_PARTICIPANT_REPORT
   (
      P_BEGIN_DATE                  IN DATE,
      P_END_DATE                    IN DATE,
      P_TIME_ZONE                   IN VARCHAR2,
      P_RATE_CLASS                  IN VARCHAR2 -- DSC
     ,
      P_ESP_ID                      IN NUMBER --SUPPLIER
     ,
      P_POOL_ID                     IN NUMBER,
      P_ACCOUNT_EXTERNAL_IDENTIFIER IN VARCHAR2,
      P_STATUS                      OUT NUMBER,
      P_CURSOR                      OUT REF_CURSOR
   ) AS
   BEGIN
      POST_TO_APP_EVENT_LOG('UFE PARTCIPANT',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'GET_UFE_PARTICIPANT_REPORT',
                            NULL,
                            'BEGIN GET_UFE_PARTICIPANT_REPORT',
                            USER);

      P_STATUS := GA.SUCCESS;
      OPEN P_CURSOR FOR
         SELECT DISTINCT A.ACCOUNT_EXTERNAL_IDENTIFIER,
                         ERC.RATE_CLASS,
                         ESP.ESP_ALIAS,
                         P.POOL_EXTERNAL_IDENTIFIER,
                         A.IS_UFE_PARTICIPANT
           FROM ACCOUNT                 A,
                ACCOUNT_ESP             AE,
                ACCOUNT_EDC             AEDC,
                ACCOUNT_STATUS          AST,
                EDC_RATE_CLASS          ERC,
                ENERGY_SERVICE_PROVIDER ESP,
                POOL                    P
          WHERE A.ACCOUNT_ID = AST.ACCOUNT_ID
            AND A.ACCOUNT_ID = AE.ACCOUNT_ID
            AND A.ACCOUNT_ID = AEDC.ACCOUNT_ID
            AND ERC.RATE_CLASS = AEDC.EDC_RATE_CLASS
            AND ESP.ESP_ID = AE.ESP_ID
            AND P.POOL_ID = AE.POOL_ID
            AND (ERC.RATE_CLASS = P_RATE_CLASS OR P_RATE_CLASS = 'ALL')
            AND (ESP.ESP_ID = P_ESP_ID OR P_ESP_ID = 1)
            AND (P.POOL_ID = P_POOL_ID OR P_POOL_ID = 1)
            AND A.ACCOUNT_EXTERNAL_IDENTIFIER LIKE
               TRIM(P_ACCOUNT_EXTERNAL_IDENTIFIER)
            AND AST.BEGIN_DATE <= P_END_DATE
            AND AST.END_DATE >= P_BEGIN_DATE
            AND AE.BEGIN_DATE <= P_END_DATE
            AND AE.END_DATE >= P_BEGIN_DATE
            AND AEDC.BEGIN_DATE <= P_END_DATE
            AND AEDC.END_DATE >= P_BEGIN_DATE
         -- ORDER BY   AST.BEGIN_DATE  ,AST.END_DATE
         ;
      POST_TO_APP_EVENT_LOG('UFE PARTCIPANT',
                            'REPORTING',
                            'END REPORT',
                            'NORMAL',
                            'STOP',
                            'GET_UFE_PARTICIPANT_REPORT',
                            NULL,
                            'END GET_UFE_PARTICIPANT_REPORT',
                            USER);
   EXCEPTION
      WHEN OTHERS THEN
         P_STATUS := SQLCODE;
         POST_TO_APP_EVENT_LOG('UFE PARTCIPANT',
                               'REPORTING',
                               'TERMINATE REPORT',
                               'ERROR',
                               'STOP',
                               'GET_UFE_PARTICIPANT_REPORT',
                               NULL,
                               SUBSTR(SQLERRM, 1, 512),
                               USER);
         OPEN p_CURSOR FOR
            SELECT NULL
              FROM DUAL;
   END GET_UFE_PARTICIPANT_REPORT;

   -----------------------------------------------------------------------------
   -- User     Date        CR                      Comments
   -- ----   ----------- ------   --------------------------------------------------
   --  SR     20-MAR-2012  COMEd 5.3- Enhancements   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE PUT_UFE_PARTICIPANT
   (
      P_ACCOUNT_EXTERNAL_IDENTIFIER IN VARCHAR2,
      P_IS_UFE_PARTICIPANT          IN NUMBER,
      P_STATUS                      OUT NUMBER,
      P_MESSAGE                     OUT VARCHAR2
   ) IS

   BEGIN
      POST_TO_APP_EVENT_LOG('UFE PARTCIPANT',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'PUT_UFE_PARTICIPANT',
                            NULL,
                            'BEGIN PUT_UFE_PARTICIPANT',
                            USER);
      P_STATUS := GA.SUCCESS;
      UPDATE ACCOUNT A
         SET A.IS_UFE_PARTICIPANT = P_IS_UFE_PARTICIPANT
       WHERE A.ACCOUNT_EXTERNAL_IDENTIFIER = P_ACCOUNT_EXTERNAL_IDENTIFIER;

      POST_TO_APP_EVENT_LOG('UFE PARTCIPANT',
                            'REPORTING',
                            'END REPORT',
                            'NORMAL',
                            'STOP',
                            'PUT_UFE_PARTICIPANT',
                            NULL,
                            'END PUT_UFE_PARTICIPANT',
                            USER);

   EXCEPTION
      WHEN OTHERS THEN
         P_MESSAGE := 'ERROR in updating UFE Participant';
         P_STATUS  := SQLCODE;
         POST_TO_APP_EVENT_LOG('UFE PARTCIPANT',
                               'REPORTING',
                               'TERMINATE REPORT',
                               'ERROR',
                               'STOP',
                               'PUT_UFE_PARTICIPANT',
                               NULL,
                               SUBSTR(SQLERRM, 1, 512),
                               USER);

   END PUT_UFE_PARTICIPANT;

   /*
   -----------------------------------------------------------------------------
   -- User     Date        CR                      Comments
   -- ----   ----------- ------   --------------------------------------------------
   --  SR     20-MAR-2012  COMEd 5.3- Enhancements   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE GET_UFT_UFC_PARTICIPATION
   (
      P_BEGIN_DATE                  IN DATE
     ,P_END_DATE                    IN DATE
     ,P_TIME_ZONE                   IN VARCHAR2
     ,P_STATUS                      OUT NUMBER
     ,P_CURSOR                      OUT REF_CURSOR
   ) AS
   BEGIN
       POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                             'REPORTING',
                                  'BEGIN REPORT',
                            'NORMAL',
                            'START',
                                  'GET_UFT_UFC_PARTICIPATION',
                            NULL,
                            'BEGIN GET_UFT_UFC_PARTICIPATION',
                                  USER
                                   );
      P_STATUS := GA.SUCCESS;
      OPEN P_CURSOR FOR
         SELECT U.PSE_NAME ESP_ID,
                U.POOL_NAME,
                U.IS_UFT_PARTICIPANT,
                U.IS_PJM_TRANSMISSION_UPLOAD,
                U.IS_UFC_PARTICIPANT,
                U.IS_PJM_CAPACITY_UPLOAD,
                --U.ESP_ID ORIGINAL_ESP_ID,
                U.POOL_NAME ORIGINAL_POOL_NAME,
                U.BEGIN_DATE,
                U.END_DATE
           FROM CDI_UFC_UFT_PARTICIPATION U
          ORDER BY U.PSE_NAME, U.POOL_NAME;

           POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                                'REPORTING',
                                     'END REPORT',
                                     'NORMAL',
                               'STOP',
                               'GET_UFT_UFC_PARTICIPATION',
                               NULL,
                               'END GET_UFT_UFC_PARTICIPATION',
                               USER
                               );

   EXCEPTION
        WHEN OTHERS THEN
          P_STATUS := SQLCODE;
          POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                                'REPORTING',
                                'TERMINATE REPORT',
                                'ERROR',
                                'STOP',
                                'GET_UFT_UFC_PARTICIPATION',
                                 NULL,
                                 SUBSTR(SQLERRM,1,512),
                                 USER
                                 );
        OPEN P_CURSOR FOR SELECT NULL FROM DUAL;
   END GET_UFT_UFC_PARTICIPATION;

   -----------------------------------------------------------------------------
   -- User     Date        CR                      Comments
   -- ----   ----------- ------   --------------------------------------------------
   --  SR     20-MAR-2012  COMEd 5.3- Enhancements   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE PUT_UFT_UFC_PARTICIPATION
   (
      P_ORIGINAL_ESP_ID             IN NUMBER
     ,P_ORIGINAL_POOL_NAME          IN VARCHAR2
     ,P_ESP_ID                      IN VARCHAR2
     ,P_POOL_NAME                   IN VARCHAR2
     ,P_IS_UFT_PARTICIPANT          IN NUMBER
     ,P_IS_PJM_TRANSMISSION_UPLOAD  IN NUMBER
     ,P_IS_UFC_PARTICIPANT          IN NUMBER
     ,P_IS_PJM_CAPACITY_UPLOAD      IN NUMBER
     ,P_BEGIN_DATE                  IN DATE
     ,P_END_DATE                    IN DATE
     ,P_STATUS                      OUT NUMBER
     ,P_MESSAGE                     OUT VARCHAR2
   ) IS

   LV_COUNT NUMBER;

   BEGIN

      POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'PUT_UFT_UFC_PARTICIPATION',
                            NULL,
                            'BEGIN PUT_UFT_UFC_PARTICIPATION',
                            USER
                             );
      P_STATUS := GA.SUCCESS;

      SELECT COUNT(*)
        INTO LV_COUNT
        FROM CDI_UFC_UFT_PARTICIPATION
       WHERE PSE_NAME = P_ESP_ID
         AND POOL_NAME = P_ORIGINAL_POOL_NAME;

      IF LV_COUNT = 1 THEN
      UPDATE CDI_UFC_UFT_PARTICIPATION
         SET PSE_NAME = P_ESP_ID,
             POOL_NAME = P_POOL_NAME,
             IS_UFT_PARTICIPANT = P_IS_UFT_PARTICIPANT,
             IS_PJM_TRANSMISSION_UPLOAD = P_IS_PJM_TRANSMISSION_UPLOAD,
             IS_UFC_PARTICIPANT = P_IS_UFC_PARTICIPANT,
             IS_PJM_CAPACITY_UPLOAD = P_IS_PJM_CAPACITY_UPLOAD,
             BEGIN_DATE = P_BEGIN_DATE,
             END_DATE = P_END_DATE,
             MODIFIED_DATE = SYSDATE
       WHERE ESP_ID = P_ORIGINAL_ESP_ID AND POOL_NAME = P_ORIGINAL_POOL_NAME;
      ELSE
      INSERT INTO CDI_UFC_UFT_PARTICIPATION VALUES (P_ESP_ID,P_POOL_NAME,P_IS_UFT_PARTICIPANT,
          P_IS_PJM_TRANSMISSION_UPLOAD,P_IS_UFC_PARTICIPANT,P_IS_PJM_CAPACITY_UPLOAD,NVL(P_BEGIN_DATE,CONSTANTS.LOW_DATE),NVL(P_END_DATE,k_HIGH_DATE),SYSDATE,SYSDATE);
      END IF;

       POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                               'REPORTING',
                               'END REPORT',
                               'NORMAL',
                               'STOP',
                               'PUT_UFT_UFC_PARTICIPATION',
                               NULL,
                               'END PUT_UFT_UFC_PARTICIPATION',
                               USER
                               );
   EXCEPTION
      WHEN OTHERS THEN
         P_MESSAGE := 'ERROR in updating / inserting UFC_UFT_PARTICIPATION table';
          P_STATUS := SQLCODE;
          POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                                'REPORTING',
                                'TERMINATE REPORT',
                                'ERROR',
                                'STOP',
                                'PUT_UFT_UFC_PARTICIPATION',
                                 NULL,
                                 SUBSTR(SQLERRM,1,512),
                                 USER
                                 );

   END PUT_UFT_UFC_PARTICIPATION;

   PROCEDURE DEL_UFT_UFC_PARTICIPATION
   (
     P_ORIGINAL_ESP_ID             IN NUMBER
    ,P_ORIGINAL_POOL_NAME          IN VARCHAR2
   )IS
   BEGIN
            POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                                     'REPORTING',
                                     'BEGIN REPORT',
                                     'NORMAL',
                                     'START',
                                     'DEL_UFT_UFC_PARTICIPATION',
                                     NULL,
                                     'BEGIN DEL_UFT_UFC_PARTICIPATION',
                                     USER
                                    );

           DELETE FROM CDI_UFC_UFT_PARTICIPATION    WHERE ESP_ID = P_ORIGINAL_ESP_ID AND POOL_NAME = P_ORIGINAL_POOL_NAME;

             POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                               'REPORTING',
                               'END REPORT',
                               'NORMAL',
                               'STOP',
                               'DEL_UFT_UFC_PARTICIPATION',
                               NULL,
                               'END DEL_UFT_UFC_PARTICIPATION',
                               USER
                               );
   EXCEPTION
      WHEN OTHERS THEN

          POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                                'REPORTING',
                                'TERMINATE REPORT',
                                'ERROR',
                                'STOP',
                                'DEL_UFT_UFC_PARTICIPATION',
                                 NULL,
                                 SUBSTR(SQLERRM,1,512),
                                 USER
                                 );

   END DEL_UFT_UFC_PARTICIPATION;

   */

   -- -----------------------------------------------------------------------------
   -- User  Date        CR       Comments
   -- ----  ----------- ------   --------------------------------------------------
   -- KN   02-Dec-2013           Added Self Scheduling and UFE Participant
   -- MY   27-Apr-2012 ******   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE GET_UFT_UFC_PARTICIPATION
   (
      P_STATUS OUT NUMBER,
      P_CURSOR OUT REF_CURSOR
   ) AS
   BEGIN
      POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'GET_UFT_UFC_PARTICIPATION',
                            NULL,
                            'BEGIN GET_UFT_UFC_PARTICIPATION',
                            USER);
      P_STATUS := GA.SUCCESS;
      OPEN P_CURSOR FOR
         SELECT U.PSE_NAME,
                U.POOL_NAME,
                U.IS_UFT_PARTICIPANT,
                U.IS_PJM_TRANSMISSION_UPLOAD,
                U.IS_UFC_PARTICIPANT,
                U.IS_PJM_CAPACITY_UPLOAD,
                U.Is_Self_Scheduling,
                U.IS_UFE_PARTICIPANT,
                U.BEGIN_DATE,
                U.END_DATE,
                U.UFC_UFT_PART_ID
           FROM CDI_UFC_UFT_PARTICIPATION U

          ORDER BY U.PSE_NAME,
                   U.POOL_NAME;

      POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                            'REPORTING',
                            'END REPORT',
                            'NORMAL',
                            'STOP',
                            'GET_UFT_UFC_PARTICIPATION',
                            NULL,
                            'END GET_UFT_UFC_PARTICIPATION',
                            USER);

   EXCEPTION
      WHEN OTHERS THEN
         P_STATUS := SQLCODE;
         POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                               'REPORTING',
                               'TERMINATE REPORT',
                               'ERROR',
                               'STOP',
                               'GET_UFT_UFC_PARTICIPATION',
                               NULL,
                               SUBSTR(SQLERRM, 1, 512),
                               USER);
         OPEN P_CURSOR FOR
            SELECT NULL
              FROM DUAL;
   END GET_UFT_UFC_PARTICIPATION;

   -- -----------------------------------------------------------------------------
   -- User  Date        CR       Comments
   -- ----  ----------- ------   --------------------------------------------------
   -- KN   02-Dec-2013           Added Self Scheduling and UFE Participant
   -- MY   27-Apr-2012 ******   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE PUT_UFT_UFC_PARTICIPATION
   (
      P_UFC_UFT_PART_ID            IN NUMBER,
      P_PSE_NAME                   IN VARCHAR2,
      P_POOL_NAME                  IN VARCHAR2,
      P_IS_UFT_PARTICIPANT         IN NUMBER,
      P_IS_PJM_TRANSMISSION_UPLOAD IN NUMBER,
      P_IS_UFC_PARTICIPANT         IN NUMBER,
      P_IS_PJM_CAPACITY_UPLOAD     IN NUMBER,
      P_IS_SELF_SCHEDULING         IN NUMBER,
      P_IS_UFE_PARTICIPANT         IN NUMBER,
      P_BEGIN_DATE                 IN DATE,
      P_END_DATE                   IN DATE,
      P_STATUS                     OUT NUMBER,
      P_MESSAGE                    OUT VARCHAR2
   ) IS

      lv_cnt                        NUMBER DEFAULT 0;
      lv_begin_date                 DATE;
      lv_end_date                   DATE;
      lv_is_ufc_participant         NUMBER;
      lv_is_uft_participant         NUMBER;
      lv_is_pjm_capacity_upload     NUMBER;
      lv_is_pjm_transmission_upload NUMBER;
      lv_is_self_scheduling         NUMBER;
      lv_is_ufe_participant         NUMBER;

   BEGIN

      POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'PUT_UFT_UFC_PARTICIPATION',
                            NULL,
                            'BEGIN PUT_UFT_UFC_PARTICIPATION',
                            USER);
      P_STATUS := GA.SUCCESS;

      IF P_BEGIN_DATE IS NULL THEN
         lv_begin_date := LOW_DATE;
      ELSE
         lv_begin_date := P_BEGIN_DATE;
      END IF;

      IF P_END_DATE IS NULL THEN
         lv_end_date := HIGH_DATE;
      ELSE
         lv_end_date := P_END_DATE;
      END IF;

      IF P_IS_UFC_PARTICIPANT IS NULL THEN
         lv_is_ufc_participant := 0;
      ELSE
         lv_is_ufc_participant := P_IS_UFC_PARTICIPANT;
      END IF;

      IF P_IS_UFT_PARTICIPANT IS NULL THEN
         lv_is_uft_participant := 0;
      ELSE
         lv_is_uft_participant := P_IS_UFT_PARTICIPANT;
      END IF;

      IF P_IS_PJM_CAPACITY_UPLOAD IS NULL THEN
         lv_is_pjm_capacity_upload := 0;
      ELSE
         lv_is_pjm_capacity_upload := P_IS_PJM_CAPACITY_UPLOAD;
      END IF;

      IF P_IS_PJM_TRANSMISSION_UPLOAD IS NULL THEN
         lv_is_pjm_transmission_upload := 0;
      ELSE
         lv_is_pjm_transmission_upload := P_IS_PJM_TRANSMISSION_UPLOAD;
      END IF;

      IF P_IS_SELF_SCHEDULING IS NULL THEN
         lv_is_self_scheduling := 0;
      ELSE
          lv_is_self_scheduling := P_IS_SELF_SCHEDULING;
      END IF;

      IF P_IS_UFE_PARTICIPANT IS NULL THEN
         lv_is_ufe_participant := 0;
      ELSE
         lv_is_ufe_participant := P_IS_UFE_PARTICIPANT;
      END IF;


      IF P_UFC_UFT_PART_ID IS NULL THEN
         SELECT MAX(UFC_UFT_PART_ID)
           INTO lv_cnt
           FROM CDI_UFC_UFT_PARTICIPATION;

         INSERT INTO CDI_UFC_UFT_PARTICIPATION
            (UFC_UFT_PART_ID,
             PSE_NAME,
             POOL_NAME,
             IS_UFT_PARTICIPANT,
             IS_PJM_TRANSMISSION_UPLOAD,
             IS_UFC_PARTICIPANT,
             IS_PJM_CAPACITY_UPLOAD,
             IS_SELF_SCHEDULING,
             IS_UFE_PARTICIPANT,
             BEGIN_DATE,
             END_DATE,
             CREATE_DATE,
             MODIFIED_DATE)
         VALUES
            (lv_cnt + 1,
             P_PSE_NAME,
             P_POOL_NAME,
             lv_is_uft_participant,
             lv_is_pjm_transmission_upload,
             lv_is_ufc_participant,
             lv_is_pjm_capacity_upload,
             lv_is_self_scheduling,
             lv_is_ufe_participant,
             lv_begin_date,
             lv_end_date,
             SYSDATE,
             SYSDATE);
      ELSE
         UPDATE CDI_UFC_UFT_PARTICIPATION
            SET PSE_NAME                   = P_PSE_NAME,
                POOL_NAME                  = P_POOL_NAME,
                IS_UFT_PARTICIPANT         = lv_is_uft_participant,
                IS_PJM_TRANSMISSION_UPLOAD = lv_is_pjm_transmission_upload,
                IS_UFC_PARTICIPANT         = lv_is_ufc_participant,
                IS_PJM_CAPACITY_UPLOAD     = lv_is_pjm_capacity_upload,
                IS_SELF_SCHEDULING         = lv_is_self_scheduling,
                IS_UFE_PARTICIPANT         = lv_is_ufe_participant,
                BEGIN_DATE                 = lv_begin_date,
                END_DATE                   = lv_end_date,
                MODIFIED_DATE              = SYSDATE
          WHERE UFC_UFT_PART_ID = P_UFC_UFT_PART_ID;
      END IF;

      -- update the IS_EXPORT_SCHEDULE flag
      -- multiple entries not handled here
      IF P_POOL_NAME = 'CPP-B' THEN
         UPDATE interchange_transaction
            SET is_export_schedule = P_IS_PJM_CAPACITY_UPLOAD
          WHERE transaction_name = 'COMED-B-2010_PLC@COMED'
            AND transaction_type = 'Plc';

         UPDATE interchange_transaction
            SET is_export_schedule = P_IS_PJM_TRANSMISSION_UPLOAD
          WHERE transaction_name = 'COMED-B-2010_NSPL@COMED'
            AND transaction_type = 'Nspl';

      ELSIF P_POOL_NAME = 'CPP-H' THEN
         UPDATE interchange_transaction
            SET is_export_schedule = P_IS_PJM_CAPACITY_UPLOAD
          WHERE transaction_name = 'CEDPH-H-2008_PLC@COMED'
            AND transaction_type = 'Plc';

         UPDATE interchange_transaction
            SET is_export_schedule = P_IS_PJM_TRANSMISSION_UPLOAD
          WHERE transaction_name = 'CEDPH-H-2008_NSPL@COMED'
            AND transaction_type = 'Nspl';
      ELSE
         UPDATE interchange_transaction
            SET is_export_schedule = P_IS_PJM_CAPACITY_UPLOAD
          WHERE transaction_name =
                (SELECT upper(pse.pse_alias) || '_PLC'
                   FROM purchasing_selling_entity pse
                  WHERE pse.pse_name = P_PSE_NAME)
            AND transaction_type = 'Plc';

         UPDATE interchange_transaction
            SET is_export_schedule = P_IS_PJM_TRANSMISSION_UPLOAD
          WHERE transaction_name =
                (SELECT upper(pse.pse_alias) || '_NSPL'
                   FROM purchasing_selling_entity pse
                  WHERE pse.pse_name = P_PSE_NAME)
            AND transaction_type = 'Nspl';
      END IF;

      COMMIT;

      POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                            'REPORTING',
                            'END REPORT',
                            'NORMAL',
                            'STOP',
                            'PUT_UFT_UFC_PARTICIPATION',
                            NULL,
                            'END PUT_UFT_UFC_PARTICIPATION',
                            USER);
   EXCEPTION
      WHEN OTHERS THEN
         P_MESSAGE := 'ERROR in updating / inserting UFC_UFT_PARTICIPATION table';
         P_STATUS  := SQLCODE;
         POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                               'REPORTING',
                               'TERMINATE REPORT',
                               'ERROR',
                               'STOP',
                               'PUT_UFT_UFC_PARTICIPATION',
                               NULL,
                               SUBSTR(SQLERRM, 1, 512),
                               USER);

   END PUT_UFT_UFC_PARTICIPATION;

   -- -----------------------------------------------------------------------------
   -- User  Date        CR       Comments
   -- ----  ----------- ------   --------------------------------------------------
   -- MY   27-Apr-2012 ******   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE DEL_UFT_UFC_PARTICIPATION
   (
      P_UFC_UFT_PART_ID IN NUMBER,
      p_STATUS          OUT NUMBER,
      P_MESSAGE         OUT VARCHAR2
   ) IS
   BEGIN
      POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'DEL_UFT_UFC_PARTICIPATION',
                            NULL,
                            'BEGIN DEL_UFT_UFC_PARTICIPATION',
                            USER);
      p_STATUS := GA.SUCCESS;
      DELETE FROM CDI_UFC_UFT_PARTICIPATION
       WHERE UFC_UFT_PART_ID = P_UFC_UFT_PART_ID;

      POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                            'REPORTING',
                            'END REPORT',
                            'NORMAL',
                            'STOP',
                            'DEL_UFT_UFC_PARTICIPATION',
                            NULL,
                            'END DEL_UFT_UFC_PARTICIPATION',
                            USER);
   EXCEPTION
      WHEN OTHERS THEN

         POST_TO_APP_EVENT_LOG('UFT UFC PARTCIPATION',
                               'REPORTING',
                               'TERMINATE REPORT',
                               'ERROR',
                               'STOP',
                               'DEL_UFT_UFC_PARTICIPATION',
                               NULL,
                               SUBSTR(SQLERRM, 1, 512),
                               USER);

   END DEL_UFT_UFC_PARTICIPATION;

   -----------------------------------------------------------------------------
   -- User     Date        CR                      Comments
   -- ----   ----------- ------   --------------------------------------------------
   --  SR     20-MAR-2012  COMEd 5.3- Enhancements   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE GET_ESTIMATED_USAGE_PERIOD
   (
      p_BEGIN_DATE    IN DATE,
      p_END_DATE      IN DATE,
      p_TIME_ZONE     IN VARCHAR2,
      p_RATE_CLASS    IN VARCHAR2,
      p_ESP_EXTERNAL  IN VARCHAR2,
      p_POOL_EXTERNAL IN VARCHAR2,
      p_ACCOUNT_ID    IN VARCHAR2,
      p_METER_TYPE    IN VARCHAR2,
      p_ACCOUNT_TYPE  IN VARCHAR2,
      p_RUN_VERSION   IN VARCHAR2,
      p_STATUS        OUT NUMBER,
      p_CURSOR        OUT REF_CURSOR
   ) AS

   BEGIN
      POST_TO_APP_EVENT_LOG('GET ESTIMATED USAGE FOR REPORT',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'GET_ESTIMATED_USAGE_PERIOD',
                            NULL,
                            'BEGIN GET_ESTIMATED_USAGE_PERIOD',
                            USER);

      P_STATUS := GA.SUCCESS;
      OPEN P_CURSOR FOR
         SELECT DISTINCT A.ACCOUNT_EXTERNAL_ID,
                         A.ACCOUNT_MODEL_OPTION,
                         A.METER_TYPE,
                         A.DELIVERY_SERVICE_CLASS,
                         A.SUPPLIER_EXTERNAL_ID,
                         A.SEGMENT_ID,
                         A.MISSING_BEGIN_DATE,
                         A.MISSING_END_DATE,
                         A.ESTIMATED_USAGE
           FROM CDI_EST_MISSING_PER_ACC A
          WHERE (A.DELIVERY_SERVICE_CLASS = P_RATE_CLASS OR
                P_RATE_CLASS = 'ALL')
            AND (A.SUPPLIER_EXTERNAL_ID = P_ESP_EXTERNAL OR P_ESP_EXTERNAL = 'ALL')
            AND (A.SEGMENT_ID = P_POOL_EXTERNAL OR P_POOL_EXTERNAL = 'ALL')
            AND   A.ACCOUNT_EXTERNAL_ID LIKE        TRIM(P_ACCOUNT_ID)
            AND (A.METER_TYPE = P_METER_TYPE OR P_METER_TYPE = 'ALL')
            AND (A.ACCOUNT_MODEL_OPTION = P_ACCOUNT_TYPE OR P_ACCOUNT_TYPE = 'ALL')
            AND (A.RUN_ID = p_RUN_VERSION OR p_RUN_VERSION = 'ALL')
            AND A.MISSING_BEGIN_DATE <= p_END_DATE
            AND A.MISSING_END_DATE >= p_BEGIN_DATE
            ORDER BY A.ACCOUNT_EXTERNAL_ID,
                     A.ACCOUNT_MODEL_OPTION,
                     A.METER_TYPE,
                     A.DELIVERY_SERVICE_CLASS,
                     A.SUPPLIER_EXTERNAL_ID,
                     A.SEGMENT_ID,
                     A.MISSING_BEGIN_DATE,
                     A.MISSING_END_DATE;

      POST_TO_APP_EVENT_LOG('GET ESTIMATED USAGE FOR REPORT',
                            'REPORTING',
                            'END REPORT',
                            'NORMAL',
                            'STOP',
                            'GET_ESTIMATED_USAGE_PERIOD',
                            NULL,
                            'END GET_ESTIMATED_USAGE_PERIOD',
                            USER);
   EXCEPTION
      WHEN OTHERS THEN
         P_STATUS := SQLCODE;
         POST_TO_APP_EVENT_LOG('GET ESTIMATED USAGE FOR REPORT',
                               'REPORTING',
                               'TERMINATE REPORT',
                               'ERROR',
                               'STOP',
                               'GET_ESTIMATED_USAGE_PERIOD',
                               NULL,
                               SUBSTR(SQLERRM, 1, 512),
                               USER);
         OPEN p_CURSOR FOR
            SELECT NULL
              FROM DUAL;
   END GET_ESTIMATED_USAGE_PERIOD;

   -----------------------------------------------------------------------------
   -- User     Date        CR                      Comments
   -- ----   ----------- ------   --------------------------------------------------
   --  SR     20-MAR-2012  COMEd 5.3- Enhancements   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE GET_ESTIMATED_USAGE_INTERVAL
   (
      P_BEGIN_DATE    IN DATE,
      P_END_DATE      IN DATE,
      P_TIME_ZONE     IN VARCHAR2,
      P_POOL_EXTERNAL IN VARCHAR2,
      P_ACCOUNT_ID    IN VARCHAR2,
      p_RUN_VERSION   IN VARCHAR2,
      P_STATUS        OUT NUMBER,
      P_CURSOR        OUT REF_CURSOR
   ) AS

   BEGIN
      POST_TO_APP_EVENT_LOG('GET ESTMATED USAGE INTERVAL',
                            'REPORTING',
                            'BEGIN REPORT',
                            'NORMAL',
                            'START',
                            'GET_ESTIMATED_USAGE_INTERVAL',
                            NULL,
                            'BEGIN GET_ESTIMATED_USAGE_INTERVAL',
                            USER);

      P_STATUS := GA.SUCCESS;
      OPEN P_CURSOR FOR
        SELECT D.ACCOUNT_EXTERNAL_ID ACCOUNT_EXTERNAL_ID,
               d.delivery_service_class dsc,
               D.usage_date MISSING_DATE,
               D.interval_1 HOUR1,
               D.interval_2 HOUR2,
               D.interval_3 HOUR3,
               D.interval_4 HOUR4,
               D.interval_5 HOUR5,
               D.interval_6 HOUR6,
               D.interval_7 HOUR7,
               D.interval_8 HOUR8,
               D.interval_9 HOUR9,
               D.interval_10 HOUR10,
               D.interval_11 HOUR11,
               D.interval_12 HOUR12,
               D.interval_13 HOUR13,
               D.interval_14 HOUR14,
               D.interval_15 HOUR15,
               D.interval_16 HOUR16,
               D.interval_17 HOUR17,
               D.interval_18 HOUR18,
               D.interval_19 HOUR19,
               D.interval_20 HOUR20,
               D.interval_21 HOUR21,
               D.interval_22 HOUR22,
               D.interval_23 HOUR23,
               D.interval_24 HOUR24,
               D.interval_25 HOUR25
       FROM CDI_EST_MISSING_INT_ACC_DAY D
       WHERE (D.SEGMENT_ID = P_POOL_EXTERNAL OR P_POOL_EXTERNAL = 'ALL')
          AND D.ACCOUNT_EXTERNAL_ID LIKE TRIM(P_ACCOUNT_ID)
          AND (D.RUN_ID = p_RUN_VERSION OR p_RUN_VERSION = 'ALL')
          AND D.usage_date BETWEEN P_BEGIN_DATE AND P_END_DATE
       ORDER BY D.ACCOUNT_EXTERNAL_ID, D.delivery_service_class, D.usage_date;

      POST_TO_APP_EVENT_LOG('GET ESTMATED USAGE INTERVAL',
                            'REPORTING',
                            'END REPORT',
                            'NORMAL',
                            'STOP',
                            'GET_ESTIMATED_USAGE_INTERVAL',
                            NULL,
                            'END GET_ESTIMATED_USAGE_INTERVAL',
                            USER);
   EXCEPTION
      WHEN OTHERS THEN
         P_STATUS := SQLCODE;
         POST_TO_APP_EVENT_LOG('GET ESTMATED USAGE INTERVAL',
                               'REPORTING',
                               'TERMINATE REPORT',
                               'ERROR',
                               'STOP',
                               'GET_ESTIMATED_USAGE_INTERVAL',
                               NULL,
                               SUBSTR(SQLERRM, 1, 512),
                               USER);
         OPEN p_CURSOR FOR
            SELECT NULL
              FROM DUAL;
   END GET_ESTIMATED_USAGE_INTERVAL;

   -- -----------------------------------------------------------------------------
   -- To compare the forecast at daily level for 2 different dates and for different Suppliers
   -- User  Date        CR       Comments
   -- ----  ----------- ------   --------------------------------------------------
   -- SR   13-Mar-2014 ******   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE FC_GET_DATA_DAILY
   (
      p_MODEL_ID      IN NUMBER,
      p_DATE1         IN DATE,
      p_DATE2         IN DATE,
      p_TIME_ZONE     IN VARCHAR,
      p_REPORT_NAME   IN VARCHAR2,
      p_STATUS        OUT NUMBER,
      p_CURSOR        IN OUT REF_CURSOR
   )AS
      v_BEGIN_DATE1 DATE;
      v_END_DATE1    DATE;
      v_BEGIN_DATE2 DATE;
      v_END_DATE2 DATE;

   BEGIN

      UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,p_DATE1,p_DATE1,p_TIME_ZONE,v_BEGIN_DATE1,v_END_DATE1);
      UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,p_DATE2,p_DATE2,p_TIME_ZONE,v_BEGIN_DATE2,v_END_DATE2);

      Open p_CURSOR for
         SELECT S1.ESP_NAME, S1.ESP_ID, S1.ESP_ALIAS,
               ROUND(S1.AMOUNT,3) MWH1, ROUND(S2.AMOUNT,3) MWH2,
               ROUND(S1.AMOUNT - S2.AMOUNT, 3) DELTA_MWH_VALUE,
               to_char(DECODE(S2.AMOUNT, 0, 0,
                            (S1.AMOUNT - S2.AMOUNT)*100/(S2.AMOUNT)),'999,990.0') || '%'  DELTA_MHW_PERCENT
         FROM
           (SELECT H.ESP_ID, H.ESP_NAME, H.ESP_ALIAS, /*TRUNC(G.LOAD_DATE)LOAD_DATE, */SUM(G.LOAD_VAL + G.TX_LOSS_VAL + G.DX_LOSS_VAL) AMOUNT
            FROM ENERGY_DISTRIBUTION_COMPANY A,
                 PROVIDER_SERVICE B,
                 SERVICE_OBLIGATION C,
                 SERVICE_DELIVERY D,
                 SCHEDULE_GROUP E,
                 SCHEDULE_COORDINATOR F,
                 SERVICE_OBLIGATION_LOAD G,
                 ESP H,
                 CDI_UFC_UFT_PARTICIPATION CDI,
                 PSE P
            WHERE B.ESP_ID = H.ESP_ID
               AND UPPER(H.ESP_TYPE) = 'CERTIFIED'
               AND UPPER(H.ESP_STATUS) = 'ACTIVE'
               AND UPPER(SUBSTR(A.EDC_STATUS,1,1)) = 'A'
               AND NOT A.EDC_EXCLUDE_LOAD_SCHEDULE = 1
               AND B.EDC_ID = A.EDC_ID
               AND C.MODEL_ID = 1
               AND C.SCENARIO_ID = 1
               AND C.AS_OF_DATE = LOW_DATE
               AND C.PROVIDER_SERVICE_ID = B.PROVIDER_SERVICE_ID
               AND D.SERVICE_DELIVERY_ID = C.SERVICE_DELIVERY_ID
               AND E.SCHEDULE_GROUP_ID = D.SCHEDULE_GROUP_ID
               AND F.SC_ID = D.SC_ID
               AND G.SERVICE_OBLIGATION_ID = C.SERVICE_OBLIGATION_ID
               AND G.SERVICE_CODE = 'F'
               AND G.LOAD_DATE BETWEEN v_BEGIN_DATE1 AND v_END_DATE1
               AND CDI.PSE_NAME = P.PSE_NAME
               AND CDI.IS_UFE_PARTICIPANT = 1
               AND P.PSE_ID = B.PSE_ID
            GROUP BY H.ESP_ID, H.ESP_NAME, H.ESP_ALIAS/*, TRUNC(G.LOAD_DATE)*/
           ) S1,
           (SELECT H.ESP_ID, H.ESP_NAME, H.ESP_ALIAS,/* TRUNC(G.LOAD_DATE)LOAD_DATE,*/ SUM(G.LOAD_VAL + G.TX_LOSS_VAL + G.DX_LOSS_VAL) AMOUNT
          FROM ENERGY_DISTRIBUTION_COMPANY A,
                 PROVIDER_SERVICE B,
                 SERVICE_OBLIGATION C,
                 SERVICE_DELIVERY D,
                 SCHEDULE_GROUP E,
                 SCHEDULE_COORDINATOR F,
                 SERVICE_OBLIGATION_LOAD G,
                 ESP H,
                 CDI_UFC_UFT_PARTICIPATION CDI,
                 PSE P
            WHERE B.ESP_ID = H.ESP_ID
               AND UPPER(H.ESP_TYPE) = 'CERTIFIED'
               AND UPPER(H.ESP_STATUS) = 'ACTIVE'
               AND UPPER(SUBSTR(A.EDC_STATUS,1,1)) = 'A'
               AND NOT A.EDC_EXCLUDE_LOAD_SCHEDULE = 1
               AND B.EDC_ID = A.EDC_ID
               AND C.MODEL_ID = 1
               AND C.SCENARIO_ID = 1
               AND C.AS_OF_DATE = LOW_DATE
               AND C.PROVIDER_SERVICE_ID = B.PROVIDER_SERVICE_ID
               AND D.SERVICE_DELIVERY_ID = C.SERVICE_DELIVERY_ID
               AND E.SCHEDULE_GROUP_ID = D.SCHEDULE_GROUP_ID
               AND F.SC_ID = D.SC_ID
               AND G.SERVICE_OBLIGATION_ID = C.SERVICE_OBLIGATION_ID
               AND G.SERVICE_CODE = 'F'
               AND G.LOAD_DATE BETWEEN v_BEGIN_DATE2 AND v_END_DATE2
               AND CDI.PSE_NAME = P.PSE_NAME
               AND CDI.IS_UFE_PARTICIPANT = 1
               AND P.PSE_ID = B.PSE_ID
            GROUP BY H.ESP_ID, H.ESP_NAME, H.ESP_ALIAS/*, TRUNC(G.LOAD_DATE)*/
           ) S2
           WHERE S1.ESP_ID = S2.ESP_ID
           ORDER BY DELTA_MWH_VALUE DESC;

   EXCEPTION
     WHEN OTHERS THEN
              POST_TO_APP_EVENT_LOG('FORECASTING',
                                    'REPORTING',
                                    'TERMINATE REPORT',
                                    'ERROR',
                                    'STOP',
                                    'FC_GET_DATA_DAILY',
                                    NULL,
                                    SUBSTR(SQLERRM,1,512),
                                    USER);
   End FC_GET_DATA_DAILY;

   -- -----------------------------------------------------------------------------
   --For a given supplier, comparing the forecast and temperature at hourly level for 2 different date
   -- User  Date        CR       Comments
   -- ----  ----------- ------   --------------------------------------------------
   -- SR   13-Mar-2014 ******   Created
   -- -----------------------------------------------------------------------------
   PROCEDURE FC_GET_DATA_HOURLY
   (
    p_MODEL_ID      IN NUMBER,
    p_DATE1         IN DATE,
    p_DATE2         IN DATE,
    p_TIME_ZONE     IN VARCHAR,
    p_ESP_ID        IN NUMBER,
    p_ESP_NAME      IN VARCHAR,
    p_ESP_ALIAS     IN VARCHAR,
    p_STATUS        OUT NUMBER,
    p_CURSOR        IN OUT REF_CURSOR
   )AS
   v_BEGIN_DATE1 DATE;
   v_END_DATE1    DATE;
   v_BEGIN_DATE2 DATE;
   v_END_DATE2 DATE;
   v_STATION_ID NUMBER;
   v_PARAMETER_ID NUMBER;

   BEGIN

      UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,p_DATE1,p_DATE1,p_TIME_ZONE,v_BEGIN_DATE1,v_END_DATE1);
      UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,p_DATE2,p_DATE2,p_TIME_ZONE,v_BEGIN_DATE2,v_END_DATE2);

      -- Station ID and Parameter ID values are used for weather display
      SELECT STATION_ID
        INTO v_STATION_ID
        FROM WEATHER_STATION
       WHERE STATION_NAME = 'ORD';

      SELECT PARAMETER_ID
        INTO v_PARAMETER_ID
        FROM WEATHER_PARAMETER
       WHERE PARAMETER_NAME ='TEMPERATURE';

       Open p_CURSOR for
         SELECT SUBSTR(FROM_CUT_AS_HED(S1.LOAD_DATE, p_TIME_ZONE), 12) "HOUR",
                p_ESP_ID ESP_ID,p_ESP_NAME ESP_NAME, p_ESP_ALIAS ESP_ALIAS,
                ROUND(S1.AMOUNT,3) MWH1, ROUND(S2.AMOUNT,3) MWH2,
                ROUND(S1.AMOUNT - S2.AMOUNT, 3) DELTA_MWH_VALUE,
                to_char(DECODE(S2.AMOUNT, 0, 0,
                (S1.AMOUNT - S2.AMOUNT)*100/(S2.AMOUNT)),'999,990.0') || '%' DELTA_MHW_PERCENT,
                S1.PARAMETER_VAL PARAMETER_VAL1,  S2.PARAMETER_VAL PARAMETER_VAL2
         FROM
           (SELECT G.LOAD_DATE, SUM(G.LOAD_VAL + G.TX_LOSS_VAL + G.DX_LOSS_VAL) AMOUNT, W.PARAMETER_VAL
            FROM ENERGY_DISTRIBUTION_COMPANY A,
                 PROVIDER_SERVICE B,
                 SERVICE_OBLIGATION C,
                 SERVICE_DELIVERY D,
                 SCHEDULE_GROUP E,
                 SCHEDULE_COORDINATOR F,
                 SERVICE_OBLIGATION_LOAD G,
                 CDI_UFC_UFT_PARTICIPATION CDI,
                 PSE P,
                 (SELECT nvl(u.PARAMETER_CODE,v.PARAMETER_CODE) PARAMETER_CODE, nvl(u.PARAMETER_DATE,v.PARAMETER_DATE) PARAMETER_DATE, decode(u.PARAMETER_CODE, 'A',u.PARAMETER_VAL,v.PARAMETER_VAL) PARAMETER_VAL FROM
                        (SELECT PARAMETER_CODE,PARAMETER_VAL,PARAMETER_DATE
                        FROM STATION_PARAMETER_VALUE
                        WHERE PARAMETER_DATE BETWEEN V_BEGIN_DATE1 AND V_END_DATE1
                        AND STATION_ID = v_STATION_ID
                        AND PARAMETER_ID = v_PARAMETER_ID
                        AND PARAMETER_CODE IN ('A'))U, -- find the Actual first
                        (SELECT PARAMETER_CODE,PARAMETER_VAL,PARAMETER_DATE
                        FROM STATION_PARAMETER_VALUE
                        WHERE PARAMETER_DATE BETWEEN V_BEGIN_DATE1 AND V_END_DATE1
                        AND STATION_ID = v_STATION_ID
                        AND PARAMETER_ID = v_PARAMETER_ID
                        AND PARAMETER_CODE IN ('F'))v --  if Actual is not available then find forecast
                        WHERE u.PARAMETER_DATE(+) = v.PARAMETER_DATE
                 )W  --weather
            WHERE B.ESP_ID = p_ESP_ID
               AND UPPER(SUBSTR(A.EDC_STATUS,1,1)) = 'A'
               AND NOT A.EDC_EXCLUDE_LOAD_SCHEDULE = 1
               AND B.EDC_ID = A.EDC_ID
               AND C.MODEL_ID = 1
               AND C.SCENARIO_ID = 1
               AND C.AS_OF_DATE = LOW_DATE
               AND C.PROVIDER_SERVICE_ID = B.PROVIDER_SERVICE_ID
               AND D.SERVICE_DELIVERY_ID = C.SERVICE_DELIVERY_ID
               AND E.SCHEDULE_GROUP_ID = D.SCHEDULE_GROUP_ID
               AND F.SC_ID = D.SC_ID
               AND G.SERVICE_OBLIGATION_ID = C.SERVICE_OBLIGATION_ID
               AND G.SERVICE_CODE = 'F'
               AND G.LOAD_DATE BETWEEN v_BEGIN_DATE1 AND v_END_DATE1
               AND CDI.PSE_NAME = P.PSE_NAME
               AND CDI.IS_UFE_PARTICIPANT = 1
               AND P.PSE_ID = B.PSE_ID
               AND to_char(G.LOAD_DATE,'HH24') = to_char(W.PARAMETER_DATE,'HH24')
            GROUP BY G.LOAD_DATE,W.PARAMETER_VAL
           ) S1,
           (SELECT G.LOAD_DATE, SUM(G.LOAD_VAL + G.TX_LOSS_VAL + G.DX_LOSS_VAL) AMOUNT, W.PARAMETER_VAL
          FROM ENERGY_DISTRIBUTION_COMPANY A,
                 PROVIDER_SERVICE B,
                 SERVICE_OBLIGATION C,
                 SERVICE_DELIVERY D,
                 SCHEDULE_GROUP E,
                 SCHEDULE_COORDINATOR F,
                 SERVICE_OBLIGATION_LOAD G,
                 CDI_UFC_UFT_PARTICIPATION CDI,
                 PSE P,
                 (SELECT nvl(u.PARAMETER_CODE,v.PARAMETER_CODE) PARAMETER_CODE, nvl(u.PARAMETER_DATE,v.PARAMETER_DATE) PARAMETER_DATE, decode(u.PARAMETER_CODE, 'A',u.PARAMETER_VAL,v.PARAMETER_VAL) PARAMETER_VAL FROM
                        (SELECT PARAMETER_CODE,PARAMETER_VAL,PARAMETER_DATE
                        FROM STATION_PARAMETER_VALUE
                        WHERE PARAMETER_DATE BETWEEN V_BEGIN_DATE2 AND V_END_DATE2
                        AND STATION_ID = v_STATION_ID
                        AND PARAMETER_ID = v_PARAMETER_ID
                        AND PARAMETER_CODE IN ('A'))U,-- find the Actual first
                        (SELECT PARAMETER_CODE,PARAMETER_VAL,PARAMETER_DATE
                        FROM STATION_PARAMETER_VALUE
                        WHERE PARAMETER_DATE BETWEEN V_BEGIN_DATE2 AND V_END_DATE2
                        AND STATION_ID = v_STATION_ID
                        AND PARAMETER_ID = v_PARAMETER_ID
                        AND PARAMETER_CODE IN ('F'))v-- if Actual is not available then find forecast
                        WHERE u.PARAMETER_DATE(+) = v.PARAMETER_DATE
                 )W    --weather
            WHERE B.ESP_ID = p_ESP_ID
               AND UPPER(SUBSTR(A.EDC_STATUS,1,1)) = 'A'
               AND NOT A.EDC_EXCLUDE_LOAD_SCHEDULE = 1
               AND B.EDC_ID = A.EDC_ID
               AND C.MODEL_ID = 1
               AND C.SCENARIO_ID = 1
               AND C.AS_OF_DATE = LOW_DATE
               AND C.PROVIDER_SERVICE_ID = B.PROVIDER_SERVICE_ID
               AND D.SERVICE_DELIVERY_ID = C.SERVICE_DELIVERY_ID
               AND E.SCHEDULE_GROUP_ID = D.SCHEDULE_GROUP_ID
               AND F.SC_ID = D.SC_ID
               AND G.SERVICE_OBLIGATION_ID = C.SERVICE_OBLIGATION_ID
               AND G.SERVICE_CODE = 'F'
               AND G.LOAD_DATE BETWEEN v_BEGIN_DATE2 AND v_END_DATE2
               AND CDI.PSE_NAME = P.PSE_NAME
               AND CDI.IS_UFE_PARTICIPANT = 1
               AND P.PSE_ID = B.PSE_ID
               AND to_char(G.LOAD_DATE,'HH24') = to_char(W.PARAMETER_DATE,'HH24')
            GROUP BY G.LOAD_DATE,W.PARAMETER_VAL
           ) S2
           WHERE to_char(S1.LOAD_DATE,'HH24') = to_char(S2.LOAD_DATE,'HH24')
           ORDER BY S1.LOAD_DATE;

   EXCEPTION
     WHEN OTHERS THEN
              POST_TO_APP_EVENT_LOG('FORECASTING',
                                    'REPORTING',
                                    'TERMINATE REPORT',
                                    'ERROR',
                                    'STOP',
                                    'FC_GET_DATA_HOURLY',
                                     NULL,
                                     SUBSTR(SQLERRM,1,512),
                                     USER);

   End FC_GET_DATA_HOURLY;

  -- --------------------------------------------------------------------------------------
  -- da_rt_hourly_ufe - Report on all suppliers (including bundled H and B) before and after UFE
  -- --------------------------------------------------------------------------------------
  -- MODIFICATION HISTORY
  -- Person         Date         Comments
  -- -----------    -----------  ----------------------------------------------------------
  --  KN           May 28 2014   Created
  -- --------------------------------------------------------------------------------------
  -- First column should be the zone load, Forecast state Zone Load (ComEd Initial Zone Load)
  --      for Day Ahead reports and Final state Zone Load (ComEd Initial Zone Load) for Scheduling reports
  -- Second column should be UFE, Day Ahead UFE for Day Ahead reports and Scheduling UFE for Scheduling reports
  -- Display all schedules values in ‘with UFE’ versions of the report, self schedulers,
  --      remaining suppliers, H-Supplied, B-Supplied (see table below for source fields state)
  -- Display all schedules values in the ‘without UFE’ versions of the report, self schedulers,
  --      remaining suppliers, CPP-H, B_Supplied, and CPP-QF
  --Check column:  Display the difference between ZL – all schedule values with the expectation
  --      that on the ‘with UFE’ versions of the report this will be zero and for ‘without UFE’
  --      versions of the report this will equal the UFE
  -- -------------------------------------------------------------------------
  -- Source Schedule                 |Scheduling Process |Day Ahead Process  |
  -- --------------------------------|-------------------|-------------------|
  -- Zone Load                       |Internal State     |Internal State     |
  -- ComEd Initial Zone Load          |Final              |Forecast           |
  -- --------------------------------|-------------------|-------------------|
  -- Certified Suppliers - aggregated|Internal State     |Internal State     |
  -- name@COMED                      |Forecast           |Forecast           |
  -- --------------------------------|-------------------|-------------------|
  -- ComEd Hourly                    |Internal State     |Internal State     |
  -- CPP-H@COMED”                    |Preliminary        |Forecast           |
  -- --------------------------------|-------------------|-------------------|
  -- ComEd Blended                   |Internal State     |Internal State     |
  -- B_SUPPLIED@COMED                |Preliminary        |Forecast           |
  -- --------------------------------|-------------------|-------------------|
  -- ComEd QF                        |Internal State     |Internal State     |
  -- CPP-QF@COMED                    |Preliminary        |Forecast           |
  -- --------------------------------|-------------------|-------------------|

PROCEDURE DA_RT_HOURLY_UFE
(
   p_MODEL_ID      IN NUMBER,
   p_SCHEDULE_TYPE IN CHAR,
   p_BEGIN_DATE    IN DATE,
   p_END_DATE      IN DATE,
   p_TIME_ZONE     IN VARCHAR,
   p_SCHEDULES     IN VARCHAR2,
   p_UFE           IN VARCHAR2,
   p_STATUS        OUT NUMBER,
   p_CURSOR        IN OUT REF_CURSOR
) AS
   lc_proc_nme CONSTANT VARCHAR2(40) := 'UFE_VALIDATE';

   c_zone_load interchange_transaction.transaction_name%TYPE := 'ComEd Initial Zone Load';
   c_cpph      interchange_transaction.transaction_name%TYPE := 'CPP-H@COMED';
   c_cppb      interchange_transaction.transaction_name%TYPE := 'B_SUPPLIED@COMED';
   c_rtou      interchange_transaction.transaction_name%TYPE := 'RTOU@COMED';
   c_cppqf     interchange_transaction.transaction_name%TYPE := 'CPP-QF@COMED';
   c_da_ufe    interchange_transaction.transaction_name%TYPE := 'Day Ahead UFE';
   c_sched_ufe interchange_transaction.transaction_name%TYPE := 'Scheduling UFE';

   c_without_ufe it_schedule.schedule_type%TYPE := id_for_statement_type('Without UFE');

   v_zone_load interchange_transaction.transaction_name%TYPE;
   v_ufe       interchange_transaction.transaction_name%TYPE;

   v_cert_type     it_schedule.schedule_type%TYPE;
   v_supplier_type it_schedule.schedule_type%TYPE;
   v_H_B_type      it_schedule.schedule_type%TYPE;
   v_QF_type       it_schedule.schedule_type%TYPE;
   v_ufe_type      it_schedule.schedule_type%TYPE;
   v_load_type     it_schedule.schedule_type%TYPE;
   v_da_rt_type    it_schedule.schedule_type%TYPE;
   v_muni_type     it_schedule.schedule_type%TYPE;

   v_begin_date DATE;
   v_end_date   DATE;
   v_status     PLS_INTEGER;

BEGIN
   id.id_for_transaction(c_zone_load, 'Load', FALSE, v_zone_load);

   CASE p_SCHEDULES
      WHEN 'Day Ahead' THEN
           v_cert_type     := ga.SCHEDULE_TYPE_FORECAST;
           v_supplier_type := ga.SCHEDULE_TYPE_FORECAST;
           v_H_B_type      := ga.SCHEDULE_TYPE_FORECAST;
           v_QF_type       := ga.SCHEDULE_TYPE_FORECAST;
           v_load_type     := ga.SCHEDULE_TYPE_FORECAST;
           v_da_rt_type    := ga.SCHEDULE_TYPE_FORECAST;
           v_muni_type     := ga.SCHEDULE_TYPE_FORECAST;
           id.id_for_transaction(c_da_ufe, 'Load', FALSE, v_ufe);
           CASE p_UFE
                WHEN 'Without UFE' THEN
                     v_cert_type     := c_without_ufe;
                     v_supplier_type := c_without_ufe;
                     v_H_B_type      := c_without_ufe;
                WHEN 'With UFE' THEN
                     NULL;
            END CASE;
      WHEN 'Scheduling' THEN
         v_cert_type     := ga.SCHEDULE_TYPE_FORECAST;
         v_supplier_type := ga.SCHEDULE_TYPE_PRELIM;
         v_H_B_type      := ga.SCHEDULE_TYPE_PRELIM;
         v_QF_type       := ga.SCHEDULE_TYPE_PRELIM;
         v_da_rt_type    := ga.SCHEDULE_TYPE_PRELIM;
         v_load_type     := ga.SCHEDULE_TYPE_FINAL;
         v_muni_type     := ga.SCHEDULE_TYPE_FORECAST;
         id.id_for_transaction(c_sched_ufe, 'Load', FALSE, v_ufe);
         CASE p_UFE
              WHEN 'Without UFE' THEN
                 v_cert_type     := c_without_ufe;
                 v_supplier_type := c_without_ufe;
                 v_H_B_type      := c_without_ufe;
              WHEN 'With UFE' THEN
                  NULL;
          END CASE;

   END CASE;

   UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,
                     p_BEGIN_DATE,
                     p_END_DATE,
                     p_TIME_ZONE,
                     v_BEGIN_DATE,
                     v_END_DATE);

   OPEN p_cursor FOR
   -- ComEd Inital Zone Load
      SELECT it.transaction_name,
             '1' ORDER_FIELD,
             FROM_CUT_AS_HED(s.SCHEDULE_DATE, p_TIME_ZONE) schedule_date,
             s.amount amount
        FROM it_schedule             s,
             interchange_transaction it
       WHERE s.schedule_state = ga.internal_state
         AND s.schedule_type = v_load_type
         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
         AND s.transaction_id = it.transaction_id
         AND it.transaction_id = v_zone_load
      UNION
      -- Scheduling / Day Ahead
      SELECT it.transaction_name,
             '2' ORDER_FIELD,
             FROM_CUT_AS_HED(s.SCHEDULE_DATE, p_TIME_ZONE) schedule_date,
             s.amount amount
        FROM it_schedule             s,
             interchange_transaction it
       WHERE s.schedule_state = ga.internal_state
         AND s.schedule_type = v_da_rt_type
         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
         AND s.transaction_id = it.transaction_id
         AND it.transaction_id = v_ufe
      UNION
      -- CPPH, B_SUPPLIED, CPPQF
      SELECT it.transaction_name,
             decode(it.transaction_name, c_cpph, '4', c_cppb, '5', c_rtou, '6' ) ORDER_FIELD,
             FROM_CUT_AS_HED(s.SCHEDULE_DATE, p_TIME_ZONE) schedule_date,
             SUM(s.amount) amount
        FROM interchange_transaction it,
             it_schedule             s
       WHERE it.transaction_type = 'Load'
         AND it.transaction_name IN (c_cpph, c_cppb, c_rtou)
         AND s.transaction_id = it.transaction_id
         AND s.schedule_state = ga.internal_state
         AND s.schedule_type = v_H_B_type
         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
       GROUP BY it.transaction_name,
                s.schedule_date
      UNION
      -- CPPQF
      SELECT it.transaction_name,
             '8' ORDER_FIELD,
             FROM_CUT_AS_HED(s.SCHEDULE_DATE, p_TIME_ZONE) schedule_date,
             SUM(s.amount) amount
        FROM interchange_transaction it,
             it_schedule             s
       WHERE it.transaction_type = 'Load'
         AND it.transaction_name = c_cppqf
         AND s.transaction_id = it.transaction_id
         AND s.schedule_state = ga.internal_state
         AND s.schedule_type = v_QF_type
         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
       GROUP BY it.transaction_name,
                s.schedule_date
      UNION
      --Certified
      SELECT it.transaction_name,
             it.transaction_name ORDER_FIELD,
             FROM_CUT_AS_HED(s.SCHEDULE_DATE, p_TIME_ZONE) schedule_date,
             SUM(s.amount) amount
        FROM interchange_transaction it,
             it_schedule             s
       WHERE it.transaction_id = s.transaction_id
         AND s.schedule_state = ga.INTERNAL_STATE
         AND s.schedule_type = v_cert_type
         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
         AND EXISTS
       (SELECT 1
                FROM interchange_transaction a,
                     pse_esp                 pe,
                     energy_service_provider es
               WHERE (a.transaction_name LIKE '%@COMED' OR
                     a.transaction_name LIKE '%@ComEd')
                 AND a.transaction_id = s.transaction_id
                 AND upper(a.transaction_interval) = 'HOUR'
                 AND a.pse_id > 0
                 AND a.pse_id = pe.pse_id
                 AND pe.esp_id = es.esp_id
                 AND upper(es.esp_type) = 'CERTIFIED'
                 AND EXISTS (SELECT 1
                        FROM tp_contract_number b
                       WHERE a.contract_id = b.contract_id)
                    --Is UFF Participation true
                 AND EXISTS (SELECT 1
                        FROM cdi_ufc_uft_participation cdi,
                             interchange_transaction   sit,
                             pse
                       WHERE cdi.pse_name = pse.pse_name
                         AND sit.transaction_id = s.transaction_id
                         AND pse.pse_id = sit.pse_id
                         AND CDI.IS_UFE_PARTICIPANT = 1)

              )
       GROUP BY it.transaction_name,
                s.schedule_date
      UNION
      --Certified (MUNI's)
      SELECT it.transaction_name,
             it.transaction_name ORDER_FIELD,
             FROM_CUT_AS_HED(s.SCHEDULE_DATE, p_TIME_ZONE) schedule_date,
             SUM(s.amount) amount
        FROM interchange_transaction it,
             it_schedule             s
       WHERE it.transaction_id = s.transaction_id
         AND s.schedule_state = ga.INTERNAL_STATE
         AND s.schedule_type = v_muni_type
         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
         AND EXISTS
       (SELECT 1
                FROM interchange_transaction a,
                     pse_esp                 pe,
                     energy_service_provider es
               WHERE (a.transaction_name LIKE '%@COMED' OR
                     a.transaction_name LIKE '%@ComEd')
                 AND a.transaction_id = s.transaction_id
                 AND upper(a.transaction_interval) = 'HOUR'
                 AND a.pse_id > 0
                 AND a.pse_id = pe.pse_id
                 AND pe.esp_id = es.esp_id
                 AND upper(es.esp_type) = 'CERTIFIED'
                 AND EXISTS (SELECT 1
                        FROM tp_contract_number b
                       WHERE a.contract_id = b.contract_id)
                    --Is UFF Participation true
                 AND EXISTS
               (SELECT 1
                        FROM cdi_ufc_uft_participation cdi,
                             interchange_transaction   sit,
                             pse
                       WHERE cdi.pse_name = pse.pse_name
                         AND sit.transaction_id = s.transaction_id
                         AND pse.pse_id = sit.pse_id
                         AND nvl(CDI.IS_UFE_PARTICIPANT, 0) = 0)

              )
       GROUP BY it.transaction_name,
                s.schedule_date
      UNION ALL
      -- Check Sum Column
      SELECT 'Check Sum' transaction_name,
             '3' ORDER_FIELD,
             FROM_CUT_AS_HED(s.SCHEDULE_DATE, p_TIME_ZONE) schedule_date,
             s.amount - checksum.amount amount
        FROM it_schedule s,
             interchange_transaction it,
             (SELECT x.schedule_date schedule_date,
                     SUM(x.amount) amount
                FROM (
                      -- CPPH, B_SUPPLIED, RTOU
                      SELECT s.SCHEDULE_DATE schedule_date,
                              SUM(s.amount) amount
                        FROM interchange_transaction it,
                              it_schedule             s
                       WHERE it.transaction_type = 'Load'
                         AND it.transaction_name IN (c_cpph, c_cppb, c_rtou)
                         AND s.transaction_id = it.transaction_id
                         AND s.schedule_state = ga.INTERNAL_STATE
                         AND s.schedule_type = v_H_B_type
                         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                       GROUP BY s.schedule_date
                      UNION ALL
                       -- CPPQF
                      SELECT s.SCHEDULE_DATE schedule_date,
                              SUM(s.amount) amount
                        FROM interchange_transaction it,
                              it_schedule             s
                       WHERE it.transaction_type = 'Load'
                         AND it.transaction_name = c_cppqf
                         AND s.transaction_id = it.transaction_id
                         AND s.schedule_state = ga.INTERNAL_STATE
                         AND s.schedule_type = v_QF_type
                         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                       GROUP BY s.schedule_date
                       UNION ALL
                      --Certified
                      SELECT s.SCHEDULE_DATE schedule_date,
                             SUM(s.amount) amount
                        FROM interchange_transaction it,
                             it_schedule             s
                       WHERE s.transaction_id = it.transaction_id
                         AND s.schedule_state = ga.INTERNAL_STATE
                         AND s.schedule_type = v_cert_type
                         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                         AND EXISTS
                       (SELECT 1
                                FROM interchange_transaction a,
                                     pse_esp                 pe,
                                     energy_service_provider es
                               WHERE (a.transaction_name LIKE '%@COMED' OR
                                     a.transaction_name LIKE '%@ComEd')
                                 AND a.transaction_id = s.transaction_id
                                 AND upper(a.transaction_interval) = 'HOUR'
                                 AND a.pse_id > 0
                                 AND a.pse_id = pe.pse_id
                                 AND pe.esp_id = es.esp_id
                                 AND upper(es.esp_type) = 'CERTIFIED'
                                 AND EXISTS
                               (SELECT 1
                                        FROM tp_contract_number b
                                       WHERE a.contract_id = b.contract_id)
                                    --Is UFF Participation true
                                 AND EXISTS
                               (SELECT 1
                                        FROM cdi_ufc_uft_participation cdi,
                                             interchange_transaction   sit,
                                             pse
                                       WHERE cdi.pse_name = pse.pse_name
                                         AND sit.transaction_id = s.transaction_id
                                         AND pse.pse_id = sit.pse_id
                                         AND CDI.Is_Ufe_Participant = 1))
                       GROUP BY s.schedule_date
                      UNION
                      SELECT s.SCHEDULE_DATE schedule_date,
                             SUM(s.amount) amount
                        FROM interchange_transaction it,
                             it_schedule             s
                       WHERE s.transaction_id = it.transaction_id
                         AND s.schedule_state = ga.INTERNAL_STATE
                         AND s.schedule_type = v_muni_type
                         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
                         AND EXISTS
                       (SELECT 1
                                FROM interchange_transaction a,
                                     pse_esp                 pe,
                                     energy_service_provider es
                               WHERE (a.transaction_name LIKE '%@COMED' OR
                                     a.transaction_name LIKE '%@ComEd')
                                 AND a.transaction_id = s.transaction_id
                                 AND upper(a.transaction_interval) = 'HOUR'
                                 AND a.pse_id > 0
                                 AND a.pse_id = pe.pse_id
                                 AND pe.esp_id = es.esp_id
                                 AND upper(es.esp_type) = 'CERTIFIED'
                                 AND EXISTS
                               (SELECT 1
                                        FROM tp_contract_number b
                                       WHERE a.contract_id = b.contract_id)
                                    --Is UFF Participation true
                                 AND EXISTS
                               (SELECT 1
                                        FROM cdi_ufc_uft_participation cdi,
                                             interchange_transaction   sit,
                                             pse
                                       WHERE cdi.pse_name = pse.pse_name
                                         AND sit.transaction_id = s.transaction_id
                                         AND pse.pse_id = sit.pse_id
                                         AND nvl(CDI.Is_Ufe_Participant, 0) = 0))
                       GROUP BY s.schedule_date) x
               GROUP BY x.schedule_date) checksum
       WHERE s.schedule_state = ga.internal_state
         AND s.schedule_type = v_load_type
         AND s.schedule_date BETWEEN v_begin_date AND v_end_date
         AND s.transaction_id = it.transaction_id
         AND it.transaction_id = v_zone_load
         AND checksum.schedule_date = s.schedule_date
       ORDER BY 2,
                3;
END DA_RT_HOURLY_UFE;
-- --------------------------------------------------------------------------------------
-- GET_ICAP_ALLOCATIONS
-- MODIFICATION HISTORY
-- Person      Date          Comments
-- -----------  -----------  ----------------------------------------------------------
-- KN           Feb 8 2021   Created - Copied from Chip Fox BGE 5.7 upgrade 
-- --------------------------------------------------------------------------------------
PROCEDURE GET_ICAP_ALLOCATIONS
   (
   p_ANCILLARY_SERVICE_ID IN NUMBER,
   p_BEGIN_DATE           IN DATE,
   p_END_DATE             IN DATE,
   p_AREA_ID              IN NUMBER,
   p_CURSOR              OUT GA.REFCURSOR
   ) AS
BEGIN
   OPEN p_CURSOR FOR
      SELECT ANCILLARY_SERVICE_NAME, ALLOCATION_NAME, BEGIN_DATE, END_DATE, ALLOCATION_VAL, DEFAULT_VAL
      FROM ANCILLARY_SERVICE_ALLOCATION A
         JOIN ANCILLARY_SERVICE B ON B.ANCILLARY_SERVICE_ID = A.ANCILLARY_SERVICE_ID
      WHERE A.BEGIN_DATE <= p_END_DATE
         AND A.END_DATE >= p_BEGIN_DATE
      ORDER BY ANCILLARY_SERVICE_NAME, ALLOCATION_NAME;
END GET_ICAP_ALLOCATIONS;
-- --------------------------------------------------------------------------------------
-- GET_AGG_ENROLLMENT_DETAILS
-- MODIFICATION HISTORY
-- Person      Date          Comments
-- -----------  -----------  ----------------------------------------------------------
-- KN           Feb 8 2021   Created - Copied from Chip Fox BGE 5.7 upgrade 
-- --------------------------------------------------------------------------------------
PROCEDURE GET_AGG_ENROLLMENT_DETAILS
   (
   p_TIME_ZONE           IN VARCHAR2,
   p_BEGIN_DATE          IN DATE,
   p_END_DATE            IN DATE,
   p_ENROLLMENT_CASE_ID  IN NUMBER,
   p_FILTER_MODEL_ID     IN NUMBER,
   p_FILTER_SC_ID        IN NUMBER,
   p_SHOW_FILTER_SC_ID   IN NUMBER,
   p_FILTER_EDC_ID       IN NUMBER,
   p_SHOW_FILTER_EDC_ID  IN NUMBER,
   p_FILTER_ESP_ID       IN NUMBER,
   p_SHOW_FILTER_ESP_ID  IN NUMBER,
   p_FILTER_PSE_ID       IN NUMBER,
   p_SHOW_FILTER_PSE_ID  IN NUMBER,
   p_FILTER_POOL_ID      IN NUMBER,
   p_SHOW_FILTER_POOL_ID  IN NUMBER,
   p_SHOW_USAGE_FACTORS  IN NUMBER,
   p_SHOW_WEIGHTED_COUNT IN NUMBER,
   p_CURSOR             OUT GA.REFCURSOR
   ) AS
v_EDC_ID NUMBER(9) := NVL(p_FILTER_EDC_ID, CONSTANTS.ALL_ID);
v_SHOW_EDC_ID NUMBER(1) := NVL(p_SHOW_FILTER_EDC_ID, 0);
v_SC_ID NUMBER(9) := NVL(p_FILTER_SC_ID, CONSTANTS.ALL_ID);
v_SHOW_SC_ID NUMBER(1) := NVL(p_SHOW_FILTER_SC_ID, 0);
v_PSE_ID NUMBER(9) := NVL(p_FILTER_PSE_ID, CONSTANTS.ALL_ID);
v_SHOW_PSE_ID NUMBER(1) := NVL(p_SHOW_FILTER_PSE_ID, 0);
v_ESP_ID NUMBER(9) := NVL(p_FILTER_ESP_ID, CONSTANTS.ALL_ID);
v_SHOW_ESP_ID NUMBER(1) := NVL(p_SHOW_FILTER_ESP_ID, 0);
v_POOL_ID NUMBER(9) := NVL(p_FILTER_POOL_ID, CONSTANTS.ALL_ID);
v_SHOW_POOL_ID NUMBER(1) := NVL(p_SHOW_FILTER_POOL_ID, 0);
v_MODEL_ID NUMBER(9) := NVL(p_FILTER_MODEL_ID,GA.DEFAULT_MODEL);
v_SHOW_MODEL_ID NUMBER(1) := CASE WHEN p_FILTER_MODEL_ID IS NULL THEN 0 ELSE 1 END;
v_MIN_INTERVAL_NUM NUMBER := GET_INTERVAL_NUMBER(CONSTANTS.INTERVAL_DAY);
c_NON_AGG_ACCOUNT_NAME VARCHAR2(18) := 'Accounts (Non Agg)';
BEGIN
    SP.CHECK_SYSTEM_DATE_TIME(p_TIME_ZONE, p_BEGIN_DATE, p_END_DATE);
    OPEN p_CURSOR FOR
    WITH SDT AS
        (SELECT S.LOCAL_DATE,
            S.LOCAL_DAY_TRUNC_DATE
        FROM SYSTEM_DATE_TIME S
        WHERE S.TIME_ZONE = p_TIME_ZONE
            AND S.DATA_INTERVAL_TYPE = GA.GAS_MODEL -- DAILY
            AND S.DAY_TYPE = GA.STANDARD
            AND S.MINIMUM_INTERVAL_NUMBER >= v_MIN_INTERVAL_NUM
            AND S.LOCAL_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
    SELECT Q.LOCAL_DATE,
        Q.LOCAL_DAY_TRUNC_DATE,
        Q.SC_ID,
        Q.SC_NAME,
        Q.EDC_ID,
        Q.EDC_NAME,
        Q.PSE_ID,
        Q.PSE_NAME,
        Q.ESP_ID,
        Q.ESP_NAME,
        Q.POOL_ID,
        Q.POOL_NAME,
        Q.MODEL,
        Q.COLUMN_MODEL_ID,
        Q.SORT_ORDER,
        Q.ACCOUNT_NAME,
     -- Q.AGGREGATE_ID,
        CASE WHEN Q.ACCOUNT_NAME = c_NON_AGG_ACCOUNT_NAME THEN SUM(Q.NON_AGG_COUNT) ELSE NULL END AS NON_AGG_COUNT,
        CASE WHEN Q.ACCOUNT_NAME = c_NON_AGG_ACCOUNT_NAME THEN NULL ELSE SUM(Q.SERVICE_ACCOUNTS) END AS AGG_COUNT,
        CASE WHEN p_SHOW_USAGE_FACTORS = 1 AND Q.ACCOUNT_NAME <> c_NON_AGG_ACCOUNT_NAME
          THEN SUM(Q.SERVICE_ACCOUNTS * Q.USAGE_FACTOR)/SUM(Q.SERVICE_ACCOUNTS)
          ELSE NULL END USAGE_FACTOR,
        CASE WHEN p_SHOW_WEIGHTED_COUNT = 1 AND Q.ACCOUNT_NAME <> c_NON_AGG_ACCOUNT_NAME
          THEN SUM(Q.SERVICE_ACCOUNTS * Q.USAGE_FACTOR)
          ELSE NULL END WEIGHTED_COUNT
    FROM (SELECT DATA.LOCAL_DATE,
            DATA.LOCAL_DAY_TRUNC_DATE,
            CASE WHEN v_SHOW_SC_ID = 1 THEN SC.SC_ID ELSE CONSTANTS.ALL_ID END SC_ID,
            CASE WHEN v_SHOW_SC_ID = 1 THEN SC.SC_NAME ELSE NULL END SC_NAME,
            CASE WHEN v_SHOW_EDC_ID = 1 THEN EDC.EDC_ID ELSE CONSTANTS.ALL_ID END EDC_ID,
            CASE WHEN v_SHOW_EDC_ID = 1 THEN EDC.EDC_NAME ELSE NULL END EDC_NAME,
            CASE WHEN v_SHOW_MODEL_ID = 1 THEN (CASE WHEN DATA.MODEL_ID = CONSTANTS.ELECTRIC_MODEL THEN 'Electric' ELSE 'Gas' END)
                ELSE NULL END AS MODEL,
            CASE WHEN v_SHOW_MODEL_ID = 1 THEN DATA.MODEL_ID ELSE GA.DEFAULT_MODEL END AS COLUMN_MODEL_ID,
            CASE WHEN v_SHOW_PSE_ID = 1 THEN PSE.PSE_ID ELSE CONSTANTS.ALL_ID END PSE_ID,
            CASE WHEN v_SHOW_PSE_ID = 1 THEN PSE.PSE_NAME ELSE NULL END PSE_NAME,
            CASE WHEN v_SHOW_ESP_ID = 1 THEN ESP.ESP_ID ELSE CONSTANTS.ALL_ID END ESP_ID,
            CASE WHEN v_SHOW_ESP_ID = 1 THEN ESP.ESP_NAME ELSE NULL END ESP_NAME,
            CASE WHEN v_SHOW_POOL_ID = 1 THEN P.POOL_ID ELSE CONSTANTS.ALL_ID END POOL_ID,
            CASE WHEN v_SHOW_POOL_ID = 1 THEN P.POOL_NAME ELSE NULL END POOL_NAME,
            CASE WHEN AGGREGATE_ID = 0 THEN 1 ELSE 2 END SORT_ORDER,
            ACCOUNT_NAME,
            AGGREGATE_ID,
            NON_AGG_COUNT,
            SERVICE_ACCOUNTS,
            USAGE_FACTOR
        FROM (SELECT SDT.LOCAL_DATE,
                    SDT.LOCAL_DAY_TRUNC_DATE,
                    D.EDC_SC_ID,
                    D.EDC_ID,
                    D.MODEL_ID,
                    D.PSE_ID,
                    D.ESP_ID,
                    D.POOL_ID,
                    D.ACCOUNT_NAME,
                    D.AGGREGATE_ID,
                    NON_AGG_COUNT,
                    SERVICE_ACCOUNTS,
                    USAGE_FACTOR
              FROM (SELECT SDT.LOCAL_DATE,
                        EDC.EDC_ID,
                        PE.PSE_ID,
                        AESP.ESP_ID,
                        AESP.POOL_ID,
                        EDC.EDC_SC_ID,
                        NVL(A.MODEL_ID, GA.DEFAULT_MODEL) AS MODEL_ID,
                        0 AS ACCOUNT_ID,
                        c_NON_AGG_ACCOUNT_NAME AS ACCOUNT_NAME,
                        0 AS AGGREGATE_ID,
                        COUNT(A.ACCOUNT_ID) AS NON_AGG_COUNT,
                        0 AS SERVICE_ACCOUNTS,
                        0 AS USAGE_FACTOR
                    FROM ACCOUNT A,
                        ACCOUNT_ESP AESP,
                        PSE_ESP PE,
                        ACCOUNT_EDC AEDC,
                        ENERGY_DISTRIBUTION_COMPANY EDC,
                        SDT
                    WHERE A.ACCOUNT_MODEL_OPTION <> ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE
                        AND A.IS_SUB_AGGREGATE = 0
                        AND v_MODEL_ID IN (CONSTANTS.ALL_ID, NVL(A.MODEL_ID,GA.DEFAULT_MODEL))
                        AND AESP.ACCOUNT_ID = A.ACCOUNT_ID
                        AND v_ESP_ID IN (CONSTANTS.ALL_ID, AESP.ESP_ID)
                        AND v_POOL_ID IN (CONSTANTS.ALL_ID, AESP.POOL_ID)
                        AND SDT.LOCAL_DATE BETWEEN AESP.BEGIN_DATE (+) AND NVL(AESP.END_DATE (+), CONSTANTS.HIGH_DATE)
                        AND PE.ESP_ID = AESP.ESP_ID
                        AND v_PSE_ID IN (CONSTANTS.ALL_ID, PE.PSE_ID)
                        AND SDT.LOCAL_DATE BETWEEN PE.BEGIN_DATE (+) AND NVL(PE.END_DATE (+), CONSTANTS.HIGH_DATE)
                        AND AEDC.ACCOUNT_ID = A.ACCOUNT_ID
                        AND v_EDC_ID IN (CONSTANTS.ALL_ID, AEDC.EDC_ID)
                        AND SDT.LOCAL_DATE BETWEEN AEDC.BEGIN_DATE (+) AND NVL(AEDC.END_DATE (+), CONSTANTS.HIGH_DATE)
                        AND EDC.EDC_ID = AEDC.EDC_ID
                        AND v_SC_ID IN (CONSTANTS.ALL_ID, EDC.EDC_SC_ID)
                     GROUP BY SDT.LOCAL_DATE, EDC.EDC_ID, AESP.ESP_ID, AESP.POOL_ID, EDC.EDC_ID, PE.PSE_ID,
                        EDC.EDC_SC_ID, NVL(A.MODEL_ID, GA.DEFAULT_MODEL)
              UNION
                    SELECT AAS.SERVICE_DATE AS LOCAL_DATE,
                        EDC.EDC_ID,
                        PE.PSE_ID,
                        AESP.ESP_ID,
                        AESP.POOL_ID,
                        EDC.EDC_SC_ID,
                        NVL(A.MODEL_ID, GA.DEFAULT_MODEL) AS MODEL_ID,
                        A.ACCOUNT_ID,
                        A.ACCOUNT_NAME,
                        AESP.AGGREGATE_ID,
                        0 AS NON_AGG_COUNT,
                        SUM(AAS.SERVICE_ACCOUNTS) AS SERVICE_ACCOUNTS,
                        SUM(AAS.USAGE_FACTOR) AS USAGE_FACTOR
                   FROM AGGREGATE_ACCOUNT_SERVICE  AAS,
                     ACCOUNT A,
                     AGGREGATE_ACCOUNT_ESP AESP,
                     ACCOUNT_EDC AEDC,
                     ENERGY_DISTRIBUTION_COMPANY EDC,
                     PSE_ESP PE
                   WHERE A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE
                        AND v_MODEL_ID IN (CONSTANTS.ALL_ID, NVL(A.MODEL_ID,GA.DEFAULT_MODEL))
                        AND AESP.ACCOUNT_ID = A.ACCOUNT_ID
                        AND v_ESP_ID IN (CONSTANTS.ALL_ID, AESP.ESP_ID)
                        AND AAS.AGGREGATE_ID = AESP.AGGREGATE_ID
                        AND AAS.CASE_ID = p_ENROLLMENT_CASE_ID
                        AND v_POOL_ID IN (CONSTANTS.ALL_ID, AESP.POOL_ID)
                        AND AAS.SERVICE_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
                        AND AAS.SERVICE_DATE BETWEEN AESP.BEGIN_DATE AND NVL(AESP.END_DATE, CONSTANTS.HIGH_DATE)
                        AND PE.ESP_ID = AESP.ESP_ID
                        AND v_PSE_ID IN (CONSTANTS.ALL_ID, PE.PSE_ID)
                        AND AAS.SERVICE_DATE BETWEEN PE.BEGIN_DATE AND NVL(PE.END_DATE, CONSTANTS.HIGH_DATE)
                        AND AEDC.ACCOUNT_ID = A.ACCOUNT_ID
                        AND v_EDC_ID IN (CONSTANTS.ALL_ID, AEDC.EDC_ID)
                        AND AAS.SERVICE_DATE BETWEEN AEDC.BEGIN_DATE AND NVL(AEDC.END_DATE, CONSTANTS.HIGH_DATE)
                        AND EDC.EDC_ID = AEDC.EDC_ID
                        AND v_SC_ID IN (CONSTANTS.ALL_ID, EDC.EDC_SC_ID)
                     GROUP BY AAS.SERVICE_DATE, EDC.EDC_ID, AESP.ESP_ID, AESP.POOL_ID, EDC.EDC_ID,
                        EDC.EDC_SC_ID, PE.PSE_ID, NVL(A.MODEL_ID, GA.DEFAULT_MODEL), A.ACCOUNT_ID, A.ACCOUNT_NAME, AESP.AGGREGATE_ID) D,
                        SDT
                     WHERE SDT.LOCAL_DATE = D.LOCAL_DATE (+)) DATA,
            POOL P,
            ENERGY_SERVICE_PROVIDER ESP,
            ENERGY_DISTRIBUTION_COMPANY EDC,
            SCHEDULE_COORDINATOR SC,
            PURCHASING_SELLING_ENTITY PSE,
            SDT
        WHERE DATA.EDC_ID = EDC.EDC_ID (+)
            AND DATA.ESP_ID = ESP.ESP_ID (+)
            AND DATA.PSE_ID = PSE.PSE_ID (+)
            AND DATA.POOL_ID = P.POOL_ID (+)
            AND DATA.EDC_SC_ID = SC.SC_ID (+)
            AND SDT.LOCAL_DATE = DATA.LOCAL_DATE) Q
     GROUP BY Q.LOCAL_DATE,
        Q.LOCAL_DAY_TRUNC_DATE,
        Q.SC_ID,
        Q.SC_NAME,
        Q.EDC_ID,
        Q.EDC_NAME,
        Q.ESP_ID,
        Q.ESP_NAME,
        Q.PSE_ID,
        Q.PSE_NAME,
        Q.POOL_ID,
        Q.POOL_NAME,
        Q.MODEL,
        Q.COLUMN_MODEL_ID,
        Q.SORT_ORDER,
        Q.ACCOUNT_NAME --,
      --Q.AGGREGATE_ID
    ORDER BY Q.LOCAL_DATE,
            Q.MODEL,
            Q.SC_NAME,
            Q.EDC_NAME,
            Q.ESP_NAME,
            Q.PSE_NAME,
            Q.POOL_NAME,
            Q.SORT_ORDER,
            Q.ACCOUNT_NAME;
END GET_AGG_ENROLLMENT_DETAILS;
-- --------------------------------------------------------------------------------------
-- PUT_AGG_ENROLLMENT_DETAILS
-- MODIFICATION HISTORY
-- Person      Date          Comments
-- -----------  -----------  ----------------------------------------------------------
-- KN           Feb 8 2021   Created - Copied from Chip Fox BGE 5.7 upgrade 
-- --------------------------------------------------------------------------------------
PROCEDURE PUT_AGG_ENROLLMENT_DETAILS
   (
   p_LOCAL_DATE         IN DATE,
   p_ENROLLMENT_CASE_ID IN NUMBER,
   p_AGGREGATE_ID       IN NUMBER,
   p_AGG_COUNT          IN NUMBER,
   p_USAGE_FACTOR       IN NUMBER,
   p_STATUS            OUT NUMBER
   ) AS
BEGIN
   UPDATE AGGREGATE_ACCOUNT_SERVICE SET SERVICE_ACCOUNTS = p_AGG_COUNT, USAGE_FACTOR = NVL(p_USAGE_FACTOR,USAGE_FACTOR)
   WHERE CASE_ID = p_ENROLLMENT_CASE_ID
      AND AGGREGATE_ID = p_AGGREGATE_ID
      AND SERVICE_DATE = p_LOCAL_DATE
      AND AS_OF_DATE = CONSTANTS.LOW_DATE;
   COMMIT;
   p_STATUS := GA.SUCCESS;
END PUT_AGG_ENROLLMENT_DETAILS;
-- --------------------------------------------------------------------------------------
-- INTERPRET_RUN_TYPE / GET_SYSTEM_SUMMARY
-- MODIFICATION HISTORY
-- Person      Date          Comments
-- -----------  -----------  ----------------------------------------------------------
-- KN           Feb 8 2021   Created - Copied from Chip Fox BGE 5.7 upgrade 
-- ------------------------------------------------------------------------------------
PROCEDURE INTERPRET_RUN_TYPE(p_RUN_TYPE_ID IN NUMBER, p_SERVICE_CODE OUT VARCHAR2, p_SCENARIO_ID OUT NUMBER) AS
BEGIN

   ASSERT(NVL(p_RUN_TYPE_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED, 'An invalid value for RUN_TYPE_ID was specified: ' || p_RUN_TYPE_ID, MSGCODES.c_ERR_ARGUMENT);
   IF p_RUN_TYPE_ID < 0 THEN
      SELECT ST.SERVICE_CODE, ST.SCENARIO_ID INTO p_SERVICE_CODE, p_SCENARIO_ID FROM SETTLEMENT_TYPE ST WHERE ST.SETTLEMENT_TYPE_ID = (p_RUN_TYPE_ID * -1);
   ELSE
      p_SERVICE_CODE := GA.FORECAST_SERVICE;
      p_SCENARIO_ID := p_RUN_TYPE_ID;
   END IF;
END INTERPRET_RUN_TYPE;
--
PROCEDURE GET_SYSTEM_SUMMARY
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_RUN_TYPE_ID       IN NUMBER,
    p_TIME_ZONE         IN VARCHAR2,
    p_INTERVAL          IN VARCHAR2,
    p_MODEL_ID          IN NUMBER,
    p_EDC_ID            IN NUMBER,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS
    
    v_EDC_ID NUMBER(9) := NVL(p_EDC_ID, CONSTANTS.ALL_ID);

    v_MODEL_ID NUMBER(9) := NVL(p_MODEL_ID,GA.DEFAULT_MODEL);

    v_SERVICE_CODE CHAR(1);
    v_SCENARIO_ID NUMBER(9);

    v_BEGIN DATE;
    v_END DATE;

    v_CUT_BEGIN_DATE DATE;
    v_CUT_END_DATE DATE;

    v_VALID_DATA_INTERVAL_TYPES NUMBER_COLLECTION;

BEGIN

    ASSERT(p_INTERVAL IS NOT NULL, 'A null value was given for INTERVAL, this field must be non-null.',
        MSGCODES.c_ERR_ARGUMENT);

    IF p_INTERVAL NOT IN (CONSTANTS.INTERVAL_15_MINUTE, CONSTANTS.INTERVAL_30_MINUTE, CONSTANTS.INTERVAL_HOUR, CONSTANTS.INTERVAL_DAY) THEN
        v_BEGIN := DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_BEGIN_DATE,p_INTERVAL);
        v_END := DATE_UTIL.END_DATE_FOR_INTERVAL(DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_END_DATE,p_INTERVAL),p_INTERVAL);
    ELSE
        v_BEGIN := p_BEGIN_DATE;
        v_END := p_END_DATE;
    END IF;

    SP.CHECK_SYSTEM_DATE_TIME(p_TIME_ZONE,v_BEGIN,v_END);
    INTERPRET_RUN_TYPE(p_RUN_TYPE_ID,v_SERVICE_CODE,v_SCENARIO_ID);
    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,v_BEGIN,v_END,p_TIME_ZONE,v_CUT_BEGIN_DATE,v_CUT_END_DATE);

    OPEN p_CURSOR FOR
        SELECT 
         Q.DT,
         Q.EDC_ID,
         Q.EDC_NAME,
         SUM(Q.SYSTEM_LOAD) AS SYSTEM_LOAD,
         SUM(Q.STANDARD_OFFER_LOAD) AS STANDARD_OFFER_LOAD, 
         SUM(Q.SUPPLIER_LOAD) AS SUPPLIER_LOAD, 
         SUM(Q.UFE) AS UFE,
         CASE WHEN SUM(Q.SYSTEM_LOAD) = 0 THEN NULL ELSE ROUND(SUM(Q.UFE)/SUM(Q.SYSTEM_LOAD),5)*100 END AS UFE_PCT,
         SUM(Q.BOTTOM_UP_LOAD) AS BOTTOM_UP_LOAD
         FROM (SELECT TRIM(CASE p_INTERVAL
                        WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS DT,
            EDC.EDC_ID,
            EDC_NAME,
            SYSTEM_LOAD,
            STANDARD_OFFER_LOAD, 
            SUPPLIER_LOAD, 
            UFE,
            (STANDARD_OFFER_LOAD + SUPPLIER_LOAD + UFE) AS BOTTOM_UP_LOAD
        FROM (SELECT 
                 EDC_ID,
                 LOAD_DATE, 
                 0 AS SYSTEM_LOAD,
                 CASE WHEN ESP.ESP_TYPE = 'Standard Offer' 
                   THEN SUM(LOAD_VAL + TX_LOSS_VAL + DX_LOSS_VAL) 
                   ELSE 0 END AS STANDARD_OFFER_LOAD,
                 CASE WHEN ESP.ESP_TYPE = 'Standard Offer' 
                   THEN 0 
                   ELSE SUM(LOAD_VAL + TX_LOSS_VAL + DX_LOSS_VAL) END AS SUPPLIER_LOAD,
                 SUM(UFE_LOAD_VAL) AS UFE
                FROM SERVICE_OBLIGATION SO, SERVICE_OBLIGATION_LOAD SOL, PROVIDER_SERVICE PS, ESP
                WHERE SERVICE_CODE = v_SERVICE_CODE
                  AND LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE
                  AND LOAD_CODE = 1
                  AND SOL.SERVICE_OBLIGATION_ID = SO.SERVICE_OBLIGATION_ID
                  AND SO.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
                  AND PS.ESP_ID = ESP.ESP_ID
                  AND (PS.EDC_ID = v_EDC_ID OR v_EDC_ID = CONSTANTS.ALL_ID)
                GROUP BY EDC_ID, LOAD_DATE, ESP_TYPE
            UNION ALL
            SELECT EDC_ID,
                LOAD_DATE, 
                UFE_SYSTEM_LOAD AS SYSTEM_LOAD, 
                0 AS STANDARD_OFFER_LOAD,
                0 AS SUPPLIER_LOAD,
                0 AS UFE 
            FROM EDC_SYSTEM_UFE_LOAD
            WHERE MODEL_ID = v_MODEL_ID
              AND SCENARIO_ID = v_SCENARIO_ID
              AND AS_OF_DATE = CONSTANTS.LOW_DATE
              AND SERVICE_CODE = v_SERVICE_CODE
              AND (EDC_ID = v_EDC_ID OR v_EDC_ID = CONSTANTS.ALL_ID)
              AND LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE
              AND LOAD_CODE = 1) A,
          EDC,
          SYSTEM_DATE_TIME SDT
        WHERE SDT.TIME_ZONE = p_TIME_ZONE
            AND SDT.DAY_TYPE = GA.STANDARD
            AND v_MODEL_ID IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
            AND v_MODEL_ID = SDT.DATA_INTERVAL_TYPE
            AND A.LOAD_DATE (+) = SDT.CUT_DATE
            AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                  AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
            AND A.EDC_ID = EDC.EDC_ID) Q
        GROUP BY Q.DT, Q.EDC_ID, Q.EDC_NAME
        ORDER BY Q.DT, Q.EDC_NAME;
END GET_SYSTEM_SUMMARY;

END CDI_REPORT;
/
