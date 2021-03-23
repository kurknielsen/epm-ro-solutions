CREATE OR REPLACE PACKAGE BODY CDI_ACCEPT_SETTLEMENT_LOAD AS

   -- SYNCH DATA TABLES --
PROCEDURE GET_ACCEPT_LOAD
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_STATUS OUT NUMBER,
   p_CURSOR OUT REF_CURSOR
   ) IS
v_BEGIN_DATE    DATE;
v_END_DATE      DATE;
BEGIN
   UT.CUT_DAY_INTERVAL_RANGE(1, p_BEGIN_DATE, p_END_DATE, 'EDT', 60, v_BEGIN_DATE, v_END_DATE);
   OPEN p_CURSOR FOR
        SELECT  FROM_CUT_AS_HED( LOAD_DATE,'EDT') LOAD_DATE,
                REPORTING_SEGMENT,
                VOLTAGE_CLASS,
                PLC_BAND,
                POLR_TYPE,
                POOL_NAME,
                SUPPLIER,
                SCHEDULE_TYPE,
                LOAD_AMOUNT
         FROM
         (
             SELECT  LOAD_DATE,
                REPORTING_SEGMENT,
                VOLTAGE_CLASS,
                PLC_BAND,
                POLR_TYPE,
                POOL_NAME,
                RFP_TICKET SUPPLIER,
                SCHEDULE_TYPE_NAME SCHEDULE_TYPE,
                LOAD_VAL+TX_LOSS_VAL+DX_LOSS_VAL+UE_LOSS_VAL LOAD_AMOUNT
                FROM   CDI_ACCEPT_LOAD
                WHERE  LOAD_DATE  <= v_END_DATE
                AND    LOAD_DATE  >= v_BEGIN_DATE
         )
         WHERE ROUND(LOAD_AMOUNT,3) <>  0.000
         ORDER BY
                1,2,3,4,5,6;

END GET_ACCEPT_LOAD;

PROCEDURE GET_COMPETITIVE_DATA
   (
   p_SCHEDULE_TYPE_NAME IN VARCHAR2,
   p_SCHEDULE_TYPE      IN CHAR,
   p_STATEMENT_TYPE_ID  IN NUMBER,
   p_BEGIN_DATE         IN DATE,
   p_END_DATE           IN DATE,
   p_STATUS            OUT NUMBER
   ) AS
v_BEGIN_DATE  DATE;
v_END_DATE    DATE;
v_SCHEDULE_ID NUMBER;
BEGIN
   UT.CUT_DATE_RANGE(1, p_BEGIN_DATE, p_END_DATE, 'EDT', v_BEGIN_DATE, v_END_DATE);
   UT.DEBUG_TRACE(p_SCHEDULE_TYPE_NAME||' '||p_SCHEDULE_TYPE||' '|| p_STATEMENT_TYPE_ID);

   DELETE FROM CDI_ACCEPT_LOAD
   WHERE UPPER(trim(SCHEDULE_TYPE)) = UPPER(TRIM(p_SCHEDULE_TYPE))
   AND STATEMENT_TYPE_ID = p_STATEMENT_TYPE_ID
   AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

   COMMIT;

  SYS.DBMS_STATS.GATHER_TABLE_STATS (
     OwnName           => 'RTO_ADMIN'
    ,TabName           => 'CDI_ACCEPT_LOAD'
    ,Estimate_Percent  => 0.1
    ,Block_sample      => TRUE
    ,Granularity       => 'GLOBAL'
    ,Method_Opt        => 'FOR COLUMNS LOAD_DATE, STATEMENT_TYPE_ID SIZE 1'
    ,Degree            => NULL
    ,Cascade           => TRUE
    ,No_Invalidate  => FALSE);

   INSERT INTO CDI_ACCEPT_LOAD CAL
           SELECT /*+ LEADING(A) FULL(A) FULL(B) FULL(C) FULL(D) FULL(E) FULL(H) FULL(I) FULL(J) FULL(K) FULL(M) FULL(SDT) */
                E.TARIFF_ID ,
                E.REPORTED_SEGMENT,
                E.VOLTAGE_CLASS,
                E.PLC_BAND,
                E.POLR_TYPE,
                M.ESP_NAME,
                C.ESP_ID,
                E.POOL_NAME,
                E.POOL_ID,
                H.PSE_NAME,
                H.PSE_ID,
                D.SERVICE_POINT_ID,
                NULL AS RFP_TICKET,
                J.CONTRACT_NUMBER AS PJM_CONTRACT_ID,
                p_SCHEDULE_TYPE_NAME,
                CASE WHEN UPPER(K.SERVICE_POINT_NAME) LIKE '%ALM%' THEN 1 ELSE 0 END AS IS_ALM,
                SUM(LOAD_VAL) AS LOAD_VAL,
                SUM(TX_LOSS_VAL) AS TX_LOSS_VAL,
                SUM(DX_LOSS_VAL) AS DX_LOSS_VAL,
                SUM(UFE_LOAD_VAL) AS UE_LOSS_VAL,
                A.LOAD_DATE,
                p_STATEMENT_TYPE_ID AS STATEMENT_TYPE_ID,
                A.SERVICE_CODE AS SCHEDULE_TYPE,
                0 AS IS_INC --YSP 6/6/2007
            FROM  SERVICE_OBLIGATION_LOAD A, SERVICE_OBLIGATION B, PROVIDER_SERVICE C,
                  SERVICE_DELIVERY D, POOL E, PURCHASING_SELLING_ENTITY H,
                  INTERCHANGE_CONTRACT I, TP_CONTRACT_NUMBER J, SERVICE_POINT K,
                  ENERGY_SERVICE_PROVIDER M,
                  SYSTEM_DATE_TIME   SDT
            WHERE
                    A.SERVICE_OBLIGATION_ID = B.SERVICE_OBLIGATION_ID
            AND     A.SERVICE_CODE          = p_SCHEDULE_TYPE
            AND     B.MODEL_ID              = 1
            AND     B.SCENARIO_ID           = 1
            AND     B.AS_OF_DATE            = c_LOW_DATE
            AND     B.PROVIDER_SERVICE_ID   = C.PROVIDER_SERVICE_ID
            AND     B.SERVICE_DELIVERY_ID   = D.SERVICE_DELIVERY_ID
            AND     C.ESP_ID                <> (SELECT ESP_ID FROM ENERGY_SERVICE_PROVIDER WHERE UPPER(ESP_NAME) = 'DEFAULT')
            AND     D.POOL_ID               = E.POOL_ID
            AND     H.PSE_ID                = C.PSE_ID
            AND     I.CONTRACT_NAME         = H.PSE_NAME
            AND     J.CONTRACT_ID           = I.CONTRACT_ID
            AND     K.SERVICE_POINT_ID      = D.SERVICE_POINT_ID
            AND     C.ESP_ID                = M.ESP_ID
            AND     SDT.TIME_ZONE           = c_DEFAULT_TIME_ZONE
            AND     SDT.DATA_INTERVAL_TYPE  = c_DATA_INTERVAL_TYPE
            AND     SDT.DAY_TYPE            = c_DAY_TYPE
            AND     SDT.CUT_DATE            = A.LOAD_DATE
            AND     A.LOAD_DATE             BETWEEN v_BEGIN_DATE AND v_END_DATE
            AND     SDT.LOCAL_DAY_TRUNC_DATE BETWEEN I.BEGIN_DATE AND NVL(I.END_DATE,  SDT.LOCAL_DAY_TRUNC_DATE)
            AND     SDT.LOCAL_DAY_TRUNC_DATE BETWEEN J.BEGIN_DATE AND NVL(J.END_DATE,  SDT.LOCAL_DAY_TRUNC_DATE)
            GROUP BY
                E.TARIFF_ID ,
                E.REPORTED_SEGMENT,
                E.VOLTAGE_CLASS,
                E.PLC_BAND,
                E.POLR_TYPE,
                M.ESP_NAME,
                C.ESP_ID,
                E.POOL_NAME,
                E.POOL_ID,
                H.PSE_NAME,
                H.PSE_ID,
                D.SERVICE_POINT_ID,
                J.CONTRACT_NUMBER,
                p_SCHEDULE_TYPE_NAME,
                CASE WHEN UPPER(K.SERVICE_POINT_NAME) LIKE '%ALM%' THEN 1 ELSE 0 END,
                A.LOAD_DATE,
                p_STATEMENT_TYPE_ID,
                A.SERVICE_CODE;
END GET_COMPETITIVE_DATA;

PROCEDURE GET_NON_COMPETITIVE_DATA
    (
        p_SCHEDULE_TYPE_NAME IN VARCHAR2,
        p_SCHEDULE_TYPE IN  CHAR,
        p_STATEMENT_TYPE_ID IN NUMBER,
        p_BEGIN_DATE    IN  DATE,
        p_END_DATE      IN  DATE,
        p_STATUS        OUT NUMBER
    )
IS
   v_BEGIN_DATE DATE;
   v_END_DATE   DATE;
   v_DATE       DATE;

BEGIN
   UT.CUT_DAY_INTERVAL_RANGE(1, p_BEGIN_DATE, p_END_DATE, 'EDT', 60,  v_BEGIN_DATE, v_END_DATE);
   EXECUTE IMMEDIATE 'truncate table CDI_ACCEPT_LOAD_BK';
   INSERT 
   INTO CDI_ACCEPT_LOAD_BK BK
       SELECT /*+ LEADING(A) FULL(A) FULL(B) FULL(C) FULL(D) FULL(E) FULL(H) FULL(K) */
        E.TARIFF_ID ,
        E.REPORTED_SEGMENT,
        E.VOLTAGE_CLASS,
        E.PLC_BAND,
        E.POLR_TYPE,
        (SELECT ESP_NAME FROM  ENERGY_SERVICE_PROVIDER WHERE ESP_ID = C.ESP_ID) ESP_NAME,
        C.ESP_ID,
        E.POOL_NAME,
        E.POOL_ID,
        H.PSE_NAME,
        H.PSE_ID,
        D.SERVICE_POINT_ID,
        NULL AS RFP_TICKET,
        NULL PJM_CONTRACT_ID,
        p_SCHEDULE_TYPE_NAME,
        CASE WHEN UPPER(K.SERVICE_POINT_NAME) LIKE '%ALM%' THEN 1 ELSE 0 END AS IS_ALM,
        SUM(LOAD_VAL) AS LOAD_VAL,
        SUM(TX_LOSS_VAL) AS TX_LOSS_VAL,
        SUM(DX_LOSS_VAL) AS DX_LOSS_VAL,
        SUM(UFE_LOAD_VAL) AS UE_LOSS_VAL,
        A.LOAD_DATE,
        p_STATEMENT_TYPE_ID,
        A.SERVICE_CODE AS SCHEDULE_TYPE -- WAS SCHEDULE_TYPE NAME YSP 3/29/2007
       FROM
                SERVICE_OBLIGATION_LOAD A,
                SERVICE_OBLIGATION B,
                PROVIDER_SERVICE C,
                SERVICE_DELIVERY D,
                POOL E,
                PURCHASING_SELLING_ENTITY H,
                SERVICE_POINT K
            WHERE   A.SERVICE_OBLIGATION_ID = B.SERVICE_OBLIGATION_ID
            AND     A.SERVICE_CODE          = p_SCHEDULE_TYPE
            AND     B.MODEL_ID              = 1
            AND     B.SCENARIO_ID           = 1
            AND     B.AS_OF_DATE            = c_LOW_DATE
            AND     B.PROVIDER_SERVICE_ID   = C.PROVIDER_SERVICE_ID
            AND     B.SERVICE_DELIVERY_ID   = D.SERVICE_DELIVERY_ID
            AND     C.ESP_ID                = (SELECT ESP_ID FROM ENERGY_SERVICE_PROVIDER WHERE UPPER(ESP_NAME) = 'DEFAULT')
            AND     D.POOL_ID               = E.POOL_ID
            AND     H.PSE_ID                = C.PSE_ID
            AND     K.SERVICE_POINT_ID      = D.SERVICE_POINT_ID
            AND     A.LOAD_DATE             BETWEEN v_BEGIN_DATE AND v_END_DATE
            GROUP BY
                   E.TARIFF_ID,  E.REPORTED_SEGMENT,
                   E.VOLTAGE_CLASS, E.PLC_BAND,
                   E.POLR_TYPE,
                   C.ESP_ID, E.POOL_NAME,
                   E.POOL_ID, H.PSE_NAME,
                   H.PSE_ID, D.SERVICE_POINT_ID,
                   K.SERVICE_POINT_NAME,
                   A.SERVICE_CODE, A.LOAD_DATE;

       COMMIT;

     SYS.DBMS_STATS.GATHER_TABLE_STATS
     (OwnName           => USER,
      TabName           => 'CDI_ACCEPT_LOAD_BK',
      Estimate_Percent  => 0.1,
      Block_sample      => TRUE,
      DEGREE            => NULL,
      CASCADE           => FALSE);


     g_STEP_NAME := 'INSERT INTO CDI_ACCEPT_LOAD';
      INSERT /* APPEND PARALLEL(CAL, 32767) PARALLEL_INDEX(CAL, 32767) */ INTO CDI_ACCEPT_LOAD CAL
            SELECT
                 BGE.TARIFF_ID            AS TARIFF_ID,
                 BGE.REPORTING_SEGMENT    AS REPORTED_SEGMENT,
                 BGE.VOLTAGE_CLASS        AS VOLTAGE_CLASS,
                 BGE.PLC_BAND             AS PLC_BAND,
                 BGE.POLR_TYPE            AS POLR_TYPE,
                 BGE.ESP_NAME             AS ESP_NAME,
                 BGE.ESP_ID               AS ESP_ID,
                 BGE.POOL_NAME            AS POOL_NAME,
                 BGE.POOL_ID              AS POOL_ID,
                 BGE.PSE_NAME             AS PSE_NAME,
                 BGE.PSE_ID               AS PSE_ID,
                 BGE.SERVICE_POINT_ID     AS SERVICE_POINT_ID,
                 BGE.SUPPLIER_ID          AS RFP_TICKET,
                (case WHEN inc_tab.is_inc = 1 then BGE.PJM_INC_INC_ID
                else BGE.PJM_BASE_ID
                END
                ) AS PJM_CONTRACT_ID,
                BGE.SCHEDULE_TYPE_NAME    AS SCHEDULE_TYPE_NAME,
                BGE.IS_ALM                AS IS_ALM,
                SUM(BGE.LOAD_VAL * BGE.SHARE_OF_LOAD * nvl(INC_TAB.BASE_LOAD_FACTOR,1)) AS LOAD_VAL, --YSP 6/6/2007
                SUM(BGE.TX_LOSS_VAL * BGE.SHARE_OF_LOAD * nvl(INC_TAB.BASE_LOAD_FACTOR,1)) AS TX_LOSS_VAL,
                SUM(BGE.DX_LOSS_VAL * BGE.SHARE_OF_LOAD * nvl(INC_TAB.BASE_LOAD_FACTOR,1)) AS DX_LOSS_VAL,
                SUM(BGE.UE_LOSS_VAL * BGE.SHARE_OF_LOAD * nvl(INC_TAB.BASE_LOAD_FACTOR,1)) AS UE_LOSS_VAL,
                BGE.LOAD_DATE AS LOAD_DATE,
                BGE.STATEMENT_TYPE_ID AS STATEMENT_TYPE_ID, --YSP 3/29/2007
                BGE.SCHEDULE_TYPE AS SCHEDULE_TYPE,
                NVL(INC_TAB.IS_INC,0)--YSP 6/6/2007
            FROM
                (SELECT distinct CALB.TARIFF_ID            AS TARIFF_ID,
                         CALB.REPORTING_SEGMENT    AS REPORTED_SEGMENT,
                         CALB.VOLTAGE_CLASS        AS VOLTAGE_CLASS,
                         CALB.PLC_BAND             AS PLC_BAND,
                         CALB.POLR_TYPE            AS POLR_TYPE,
                         CALB.ESP_NAME             AS ESP_NAME,
                         CALB.ESP_ID               AS ESP_ID,
                         CALB.POOL_NAME            AS POOL_NAME,
                         CALB.POOL_ID              AS POOL_ID,
                         CALB.PSE_NAME             AS PSE_NAME,
                         CALB.PSE_ID               AS PSE_ID,
                         CALB.SERVICE_POINT_ID     AS SERVICE_POINT_ID,
                         A.SUPPLIER_ID             AS SUPPLIER_ID,
                         CALB.REPORTING_SEGMENT,
                         CALB.STATEMENT_TYPE_ID,
                         CALB.SCHEDULE_TYPE,
                         A.PJM_INC_INC_ID,
                         A.PJM_BASE_ID,
                         CALB.SCHEDULE_TYPE_NAME    AS SCHEDULE_TYPE_NAME,
                         CALB.IS_ALM                AS IS_ALM,
                         CALB.LOAD_DATE,
                         CALB.LOAD_VAL, A.SHARE_OF_LOAD, CALB.TX_LOSS_VAL, CALB.DX_LOSS_VAL,
                         CALB.UE_LOSS_VAL,
                         SDT.LOCAL_DAY_TRUNC_DATE FROM
                BGE_SUPPLIER_VIEW A,
                CDI_ACCEPT_LOAD_BK CALB,
                SYSTEM_DATE_TIME   SDT --YSP 6/7/2007
                WHERE CALB.POLR_TYPE = A.POLR_TYPE
                AND SDT.LOCAL_DAY_TRUNC_DATE >=  A.POWER_FLOW_START
                AND SDT.LOCAL_DAY_TRUNC_DATE <= NVL(A.POWER_FLOW_END , SDT.LOCAL_DAY_TRUNC_DATE)
                AND SDT.TIME_ZONE = c_DEFAULT_TIME_ZONE --YSP 6/7/2007
                AND SDT.DATA_INTERVAL_TYPE = c_DATA_INTERVAL_TYPE --YSP 6/7/2007
                AND SDT.DAY_TYPE = c_DAY_TYPE --YSP 6/7/2007
                AND SDT.CUT_DATE = CALB.LOAD_DATE --YSP 6/7/2007
                ) BGE,
                (select a.plc_date,a.rfp_ticket,a.polr_type,1-a.base_load_factor AS BASE_LOAD_FACTOR,1 is_inc
                from cdi_base_load_alloc a
                where a.base_load_factor != 1
                union all
                select a.plc_date,a.rfp_ticket,a.polr_type,a.base_load_factor AS BASE_LOAD_FACTOR, 0 is_inc
                from cdi_base_load_alloc a
                where a.base_load_factor != 1
                union all
                select b.plc_date,b.rfp_ticket,b.polr_type,b.base_load_factor,0 is_inc
                from cdi_base_load_alloc b
                where b.base_load_factor = 1) inc_tab  --YSP 6/6/2007
            WHERE
             INC_TAB.PLC_DATE(+)  = BGE.LOCAL_DAY_TRUNC_DATE --YSP 6/7/2007
            AND INC_TAB.POLR_TYPE(+) = BGE.POLR_TYPE
            AND INC_TAB.RFP_TICKET(+) = BGE.SUPPLIER_ID
           GROUP BY
                 BGE.TARIFF_ID,
                 BGE.REPORTING_SEGMENT,
                 BGE.VOLTAGE_CLASS,
                 BGE.PLC_BAND,
                 BGE.POLR_TYPE,
                 BGE.ESP_NAME,
                 BGE.ESP_ID,
                 BGE.POOL_NAME,
                 BGE.POOL_ID,
                 BGE.PSE_NAME,
                 BGE.PSE_ID,
                 BGE.SERVICE_POINT_ID,
                 BGE.SUPPLIER_ID ,
              (case WHEN inc_tab.is_inc = 1 then BGE.PJM_INC_INC_ID
                else BGE.PJM_BASE_ID
                END
                ),
                --A.PJM_BASE_ID,
                BGE.SCHEDULE_TYPE_NAME,
                BGE.IS_ALM,
                BGE.LOAD_DATE,
                BGE.STATEMENT_TYPE_ID,
                BGE.SCHEDULE_TYPE,
                INC_TAB.IS_INC;
END GET_NON_COMPETITIVE_DATA;

PROCEDURE PUT_LOSS_CREDIT
    (
        p_DATE      IN DATE,
        p_CHARGE    IN NUMBER
    )
 IS
 v_TOTAL_AMT      NUMBER(18,4);
 v_AMOUNT         NUMBER(14,4);
 v_PRELIM         PLS_INTEGER := 2;
 v_FORECAST       PLS_INTEGER := 1;
 v_STATE          PLS_INTEGER := 1;
 v_COUNT          PLS_INTEGER;
 v_TRUE           BOOLEAN;
BEGIN
   FOR eFOR IN
   (
      SELECT TRANSACTION_ID AS ID FROM INTERCHANGE_TRANSACTION
      WHERE UPPER(TRANSACTION_IDENTIFIER) LIKE '%CUSHION%'
   ) LOOP

      v_TRUE := TRUE;

     SELECT COUNT(*) INTO v_COUNT
     FROM IT_SCHEDULE
     WHERE TRANSACTION_ID   = eFOR.ID
     AND   SCHEDULE_TYPE    = v_FORECAST
     AND   SCHEDULE_STATE   = v_STATE
     AND   AS_OF_DATE       = c_LOW_DATE
     AND   SCHEDULE_DATE    = p_DATE;

     IF v_COUNT = 0 THEN

        BEGIN
          SELECT AMOUNT INTO v_AMOUNT
          FROM IT_SCHEDULE
          WHERE TRANSACTION_ID   = eFOR.ID
          AND   SCHEDULE_TYPE    = v_PRELIM
          AND   SCHEDULE_STATE   = v_STATE
          AND   AS_OF_DATE       = c_LOW_DATE
          AND   SCHEDULE_DATE    = p_DATE;
        EXCEPTION
          WHEN OTHERS THEN
            v_TRUE := FALSE;
        END;

        IF v_TRUE THEN

          INSERT INTO IT_SCHEDULE
          (
            TRANSACTION_ID,
            SCHEDULE_TYPE,
            SCHEDULE_STATE,
            SCHEDULE_DATE,
            AS_OF_DATE,
            AMOUNT
          )
          VALUES
          (
            eFOR.ID,
            v_FORECAST,
            v_STATE,
            p_DATE,
            c_LOW_DATE,
            v_AMOUNT
          );

        END IF;

      END IF;

   END LOOP;



   BEGIN
     SELECT SUM(B.AMOUNT) INTO v_TOTAL_AMT
     FROM INTERCHANGE_TRANSACTION  A, IT_SCHEDULE B
     WHERE UPPER(A.TRANSACTION_IDENTIFIER) LIKE '%CUSHION%'
     AND A.TRANSACTION_ID = B.TRANSACTION_ID
     AND B.SCHEDULE_TYPE  = v_FORECAST
     AND B.SCHEDULE_STATE = v_STATE
     AND B.SCHEDULE_DATE  = p_DATE
     AND B.AS_OF_DATE     = c_LOW_DATE;
   EXCEPTION
    WHEN OTHERS THEN
      v_TOTAL_AMT := 0;
   END;


   FOR C1 IN
   (
     SELECT B.TRANSACTION_ID, B.AMOUNT, A.TRANSACTION_NAME
     FROM INTERCHANGE_TRANSACTION  A, IT_SCHEDULE B
     WHERE UPPER(A.TRANSACTION_IDENTIFIER) LIKE '%CUSHION%'
     AND A.TRANSACTION_ID = B.TRANSACTION_ID
     AND B.SCHEDULE_TYPE  = v_FORECAST
     AND B.SCHEDULE_STATE = v_STATE
     AND B.SCHEDULE_DATE  = p_DATE
     AND B.AS_OF_DATE     = c_LOW_DATE
   ) LOOP

    v_AMOUNT := C1.AMOUNT + (p_CHARGE * C1.AMOUNT/v_TOTAL_AMT);
    UPDATE IT_SCHEDULE
        SET AMOUNT = v_AMOUNT
    WHERE
         TRANSACTION_ID = C1.TRANSACTION_ID
    AND  SCHEDULE_TYPE  = v_PRELIM
    AND  SCHEDULE_STATE = v_STATE
    AND  SCHEDULE_DATE  = p_DATE
    AND  AS_OF_DATE     = c_LOW_DATE ;

  END LOOP;
  commit;
END   PUT_LOSS_CREDIT;

PROCEDURE MAIN
(
    p_SCHEDULE_TYPE IN VARCHAR2,
    p_BEGIN_DATE    IN  DATE,
    p_END_DATE      IN  DATE,
    p_STATUS        OUT NUMBER
)
IS
    v_ICAP_VALUE    NUMBER;
    v_NET_VALUE     NUMBER;
    v_DATE          DATE;
    v_SCHEDULE_TYPE_NAME VARCHAR2(32);
    v_SCHEDULE_CODE CHAR(2);
    v_STATEMENT_TYPE_ID NUMBER; --YSP 3/29/2007
    v_COUNT     NUMBER;

BEGIN

   UT.DEBUG_TRACE('MAIN begin: p_schedule_type = '||p_schedule_type);
   g_PROC_NAME := 'CDI_ACCEPT_SETTL_LOAD.MAIN';
   g_STEP_NAME := 'START MAIN Process';
   g_REPORT    := '';

   g_PID    := Plog.LOG_PROCESS_START('CDI_ACCEPT_SETTL_LOAD.MAIN');
   g_RESULT := Plog.c_SEV_OK;
   p_Status := Ga.SUCCESS;

   g_PRES   := Plog.LOG_PROCESS_EVENT(g_PID,
                                    Plog.c_SEV_OK,
                                    g_PROC_NAME,
                                    g_STEP_NAME,
                                    'CDI_ACCEPT_SETTLEMENT_LOAD.MAIN',
                                    'Start Competitive and non-Competitive Data import Start Date '||p_BEGIN_DATE || '  End Date '||p_END_DATE);

   g_STEP_NAME := 'Define Statement Type ID';
   BEGIN
       SELECT A.SETTLEMENT_TYPE_NAME,A.SERVICE_CODE,B.STATEMENT_TYPE_ID
         INTO v_SCHEDULE_TYPE_NAME,v_SCHEDULE_CODE,v_STATEMENT_TYPE_ID
       FROM SETTLEMENT_TYPE A, STATEMENT_TYPE B
       WHERE SETTLEMENT_TYPE_ORDER = TO_NUMBER(p_SCHEDULE_TYPE) AND
         UPPER(STATEMENT_TYPE_NAME) = UPPER(A.SETTLEMENT_TYPE_NAME);
   EXCEPTION WHEN OTHERS THEN
       RAISE;
   END;

   --UT.DEBUG_TRACE('MAIN: v_schedule_type = '||v_schedule_CODE||' v_STATEMENT_TYPE_ID='||v_STATEMENT_TYPE_ID);
   g_STEP_NAME := 'CHECK POLR SHARE RATIO';
   FOR C2 IN
   ( SELECT DISTINCT POLR_TYPE FROM CDI_ACCEPT_LOAD
     WHERE LOAD_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
   LOOP
       SELECT COUNT(POLR_TYPE) INTO v_COUNT
       FROM BGE_SUPPLIER_VIEW
       WHERE p_BEGIN_DATE BETWEEN POWER_FLOW_START AND NVL(POWER_FLOW_END, p_END_DATE );

       IF v_COUNT = 0 THEN
          RAISE_APPLICATION_ERROR(-20002, C2.POLR_TYPE || ' Exists in Settlement Load but not in BGE_SUPPLIER_VIEW table for date range ');
       END IF;

   END LOOP;

   g_STEP_NAME := 'Define SHARE_OF_LOAD COLUMN IN BGE_SUPPLIER_VIEW';
   FOR C1 IN
   (
        SELECT POLR_TYPE, ROUND(SUM(SHARE_OF_LOAD),5) VAL
        FROM BGE_SUPPLIER_VIEW
        WHERE p_BEGIN_DATE BETWEEN POWER_FLOW_START AND NVL(POWER_FLOW_END, p_END_DATE )
        GROUP BY POLR_TYPE
   )
   LOOP

        IF C1.VAL <> 1 THEN
            RAISE_APPLICATION_ERROR(-20002,' SHARE_OF_LOAD COLUMN IN BGE_SUPPLIER_VIEW DOES NOT SUM TO 1.00000 FOR POLR_TYPE '||C1.POLR_TYPE||' VAL '||C1.VAL);
            RETURN;
        END IF;

    END LOOP;

   --EXECUTE IMMEDIATE 'TRUNCATE TABLE TRACE';
   COMMIT;

   g_STEP_NAME := 'GET_COMP_DATA';
   GET_COMPETITIVE_DATA(v_SCHEDULE_TYPE_NAME,v_SCHEDULE_CODE,v_STATEMENT_TYPE_ID, p_BEGIN_DATE, p_END_DATE, p_STATUS);

   g_STEP_NAME := 'GET_DEFAULT_DATA';
   GET_NON_COMPETITIVE_DATA(v_SCHEDULE_TYPE_NAME, v_SCHEDULE_CODE, v_STATEMENT_TYPE_ID,p_BEGIN_DATE, p_END_DATE, p_STATUS);

   g_STEP_NAME := 'COMMIT';
   COMMIT;

   --INSERT INTO TEMP_METER_EXT VALUES ('FINISH TIME FOR ACCEPT LOAD IS   '||UT.TRACE_DATE(SYSDATE)); COMMIT;
   --**** UNCOMMENT LATER - YSP
   G_SOURCE := 'SCH TYPE NAME = '||v_SCHEDULE_TYPE_NAME||','||
                ' SCHEDULE TCODE = '||v_SCHEDULE_CODE||','||
                ' STMT TYPE = '||v_STATEMENT_TYPE_ID||','||
                ' BEGIN DATE = '||p_BEGIN_DATE||','||
                ' END DATE = '||p_END_DATE;

   g_STEP_NAME := 'Call ACCEPT_OBLIGATION';
   CDI_CREATE_SCHEDULES.ACCEPT_OBLIGATION(v_SCHEDULE_TYPE_NAME,v_SCHEDULE_CODE,v_STATEMENT_TYPE_ID, p_BEGIN_DATE, p_END_DATE,P_STATUS_SCH);

   p_STATUS := p_STATUS_SCH;
   IF p_STATUS != GA.SUCCESS THEN
    RAISE_APPLICATION_ERROR(-20000,'Error: CDI_CREATE_SCHEDULES returned status = '||P_status);
   END IF;

   --SELECT DECODE (UPPER(SUBSTR(p_SCHEDULE_TYPE,1,1)),'2',3,'1',2, 1/0) INTO v_COUNT
   SELECT DECODE (UPPER(SUBSTR(p_SCHEDULE_TYPE,1,1)),'2',3,'1',2, v_STATEMENT_TYPE_ID) INTO v_COUNT
   FROM DUAL;

   --UT.DEBUG_TRACE(v_COUNT);
   --UT.DEBUG_TRACE('MAIN: before calling GET_POLR_eSCHEDULE_DATA p_schedule_type = '||p_schedule_type);
   g_STEP_NAME := 'Call GET_POLR_ESCHEDULE_DATA';
   IF v_COUNT > 0 then
      CDI_REPORT_JAM.GET_POLR_ESCHEDULE_DATA
      (
      p_BEGIN_DATE,
      p_END_DATE,
      v_COUNT
      );

   g_STEP_NAME := 'END';
   END IF;

   g_REPORT := g_REPORT  || 'FINISED Process';
   --p_STATUS := g_RESULT;
  -- p_MESSAGE := DEFAULT_PROCESS_MESSAGE(g_RESULT);
   g_PRES := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, SUBSTR(SQLERRM,1,64), g_REPORT);

EXCEPTION
   WHEN OTHERS THEN
      -- g_PRES := Plog.LOG_PROCESS_EVENT(g_PID, Plog.c_SEV_ERROR, g_PROC_NAME, g_STEP_NAME, g_SOURCE, SQLERRM, 'ERROR in CDI_ACCEPT_SETTLEMENT_LOAD.MAIN');
      -- g_RESULT := GREATEST(g_RESULT, Plog.c_SEV_ERROR);
      HANDLE_EXCEPTION(SQLCODE,SQLERRM);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20002,'ERROR IN ACCEPT SETTLEMENT DATA PLEASE CHECK PROCESS LOG  '||SQLERRM);

END MAIN;

PROCEDURE PJM_ROUND_ESCHEDULE
(
    p_SCHEDULE_TYPE IN NUMBER,
    p_SCHEDULE_STATE IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
) AS

    v_BEGIN_DATE    DATE;
    v_END_DATE      DATE;
    v_CONTRACT      VARCHAR2(64);
    v_CONTRACT_NAME VARCHAR2(64);
    v_DATE          DATE := p_BEGIN_DATE;
    v_LOAD_VAL      NUMBER(14,4);
    v_SCHEDULE_VAL  NUMBER(14,4);
    v_DIFF          NUMBER(14,4);
    v_COUNT         PLS_INTEGER;
    v_CONTRACT_ID   NUMBER(9);
    v_ROW_ID        ROWID;
    v_BOLMAX        BOOLEAN;
    v_ROUND         NUMBER;

BEGIN

       -- START LOGGING --
   g_PROC_NAME := 'PJM_ROUND_ESCHEDULE';
   g_STEP_NAME := 'START MAIN_LOAD';
   g_REPORT    := '';

   g_PID    := Plog.LOG_PROCESS_START('PJM_ROUND_ESCHEDULE',p_BEGIN_DATE,p_END_DATE,p_SCHEDULE_TYPE);
   g_RESULT := Plog.c_SEV_OK;
    UT.CUT_DAY_INTERVAL_RANGE(1, p_BEGIN_DATE, p_END_DATE, 'EDT', 60, v_BEGIN_DATE, v_END_DATE);

    g_STEP_NAME := 'CHECK CONTRACT';
     BEGIN
        SELECT TRIM(VALUE) INTO v_CONTRACT
        FROM SYSTEM_DICTIONARY
        WHERE MODULE = 'Scheduling'
        AND UPPER(KEY1) = 'PJM EXPORT'
        AND SETTING_NAME = 'Rounding Correction Contract ID';
     EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,'Rounding Correction Contract ID NOT AVAILABLE PLEASE ASSIGN');
     END;

     g_STEP_NAME := 'CHECK CONTRACT';
     BEGIN
        SELECT TO_NUMBER(TRIM(VALUE)) INTO v_ROUND
        FROM SYSTEM_DICTIONARY
        WHERE MODULE = 'Scheduling'
        AND UPPER(KEY1) = 'PJM EXPORT'
        AND SETTING_NAME = 'Rounding Correction Max. Value (MW)';
     EXCEPTION
        WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR(-20002,'Rounding Correction Max. Value (MW) ID NOT AVAILABLE PLEASE ASSIGN');
     END;


     g_STEP_NAME := 'CHECK CONTRACT_ID';
     SELECT COUNT(CONTRACT_ID) INTO v_COUNT
     FROM TP_CONTRACT_NUMBER
     WHERE CONTRACT_NUMBER = v_CONTRACT;

     g_STEP_NAME := 'CHECK ESCHEDULE';
     IF v_COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20002,'TP_CONTRACT_ID NOT AVAILABLE PLEASE ASSIGN');
     END IF;


     v_DATE     := v_BEGIN_DATE;

      g_STEP_NAME := 'CHECK PJM_ROUND_ESCHEDULE';

         WHILE v_DATE <= v_END_DATE LOOP

              BEGIN
                 SELECT ROUND(LOAD_VAL,3) INTO v_LOAD_VAL
                 FROM   AREA A, AREA_LOAD AL
                 WHERE  A.AREA_NAME     = c_LOAD_NAME
                 AND    AL.AREA_ID      = A.AREA_ID
                 AND    AL.AS_OF_DATE   = c_LOW_DATE
                 AND    AL.CASE_ID      = 1
                 AND    AL.LOAD_CODE    = 'A'
                 AND    AL.LOAD_DATE    = v_DATE;
              EXCEPTION
                WHEN OTHERS THEN
                    RAISE_APPLICATION_ERROR(-20002,'SYSTEM LOAD NOT AVAILABLE FOR '||FROM_CUT_AS_HED(v_DATE, LOCAL_TIME_ZONE));
              END;

              BEGIN
                SELECT ROUND(SUM(B.AMOUNT),3) INTO v_SCHEDULE_VAL
                FROM INTERCHANGE_TRANSACTION A, IT_SCHEDULE B, TP_CONTRACT_NUMBER C, SYSTEM_DATE_TIME SDT
                WHERE A.MODEL_ID = 1
                AND B.TRANSACTION_ID       = A.TRANSACTION_ID
                AND B.SCHEDULE_TYPE        = p_SCHEDULE_TYPE
                AND B.SCHEDULE_STATE       = g_INTERNAL_STATE
                AND B.SCHEDULE_DATE        = v_DATE
                AND A.CONTRACT_ID          = C.CONTRACT_ID
                AND UPPER(C.CONTRACT_NAME)  NOT LIKE '%_ALM'
                AND A.TRANSACTION_TYPE = 'Load'
                AND A.IS_EXPORT_SCHEDULE   = 1
                AND SDT.TIME_ZONE           = c_DEFAULT_TIME_ZONE
                AND SDT.DATA_INTERVAL_TYPE  = c_DATA_INTERVAL_TYPE
                AND SDT.DAY_TYPE            = c_DAY_TYPE
                AND SDT.CUT_DATE            = B.SCHEDULE_DATE
                AND SDT.LOCAL_DAY_TRUNC_DATE BETWEEN C.BEGIN_DATE AND NVL(C.END_DATE,  SDT.LOCAL_DAY_TRUNC_DATE);


              EXCEPTION
                WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR(-20002,'SCHEDULES NOT AVAILABLE FOR '||FROM_CUT_AS_HED(v_DATE, LOCAL_TIME_ZONE));
              END;

              v_DIFF := ABS(v_LOAD_VAL - v_SCHEDULE_VAL);

              IF  v_DIFF > v_ROUND THEN
                RAISE_APPLICATION_ERROR(-20002,'DIFFERENCE BETWEEN LOAD AND SCHEDULES IS MORE THAN '||v_ROUND||' Value is =>'||v_DIFF||' FOR '||FROM_CUT_AS_HED(v_DATE, LOCAL_TIME_ZONE));
              END IF;

              v_DIFF := ROUND(v_LOAD_VAL - v_SCHEDULE_VAL,3);

              v_BOLMAX := TRUE;


               FOR C1 IN
               ( --query the entire schedule pool for this hour for only those transactions part of rounding contract
                 SELECT *
                 FROM IT_SCHEDULE
                 WHERE SCHEDULE_TYPE  = p_SCHEDULE_TYPE
                 AND   SCHEDULE_STATE = g_INTERNAL_STATE
                 AND   SCHEDULE_DATE  = v_DATE
                 AND AMOUNT =
                 (   -- determine max amount of all round contract transactions
                     SELECT MAX(AMOUNT)
                     FROM IT_SCHEDULE
                     WHERE SCHEDULE_TYPE  = p_SCHEDULE_TYPE
                     AND   SCHEDULE_STATE = g_INTERNAL_STATE
                     AND   SCHEDULE_DATE  = v_DATE
                     AND   TRANSACTION_ID
                     IN
                  (   -- get list of only those transactions part of rounding contract currently configured
                      SELECT A.TRANSACTION_ID FROM INTERCHANGE_TRANSACTION A, TP_CONTRACT_NUMBER B
                      WHERE B.CONTRACT_NUMBER = v_CONTRACT
                      AND A.CONTRACT_ID = B.CONTRACT_ID
                  )
                 )
                 AND   TRANSACTION_ID
                 IN
                 (   -- get list of only those transactions part of rounding contract currently configured
                     SELECT A.TRANSACTION_ID FROM INTERCHANGE_TRANSACTION A, TP_CONTRACT_NUMBER B
                     WHERE B.CONTRACT_NUMBER = v_CONTRACT
                       AND A.CONTRACT_ID = B.CONTRACT_ID
                 )

               )

               LOOP

                   IF v_BOLMAX THEN

                       SELECT B.CONTRACT_NAME INTO v_CONTRACT_NAME
                       FROM INTERCHANGE_TRANSACTION A, TP_CONTRACT_NUMBER B
                       WHERE A.TRANSACTION_ID = C1.TRANSACTION_ID
                       AND   A.CONTRACT_ID    = B.CONTRACT_ID;

                       IF UPPER(v_CONTRACT_NAME) LIKE '%ALM%' THEN
                          RAISE_APPLICATION_ERROR(-20002,'CONTRACT ID '||v_CONTRACT|| ' HAS AN ALM CONTRACT '||v_CONTRACT_NAME);
                       END IF;

                       UPDATE IT_SCHEDULE
                       SET AMOUNT   = AMOUNT + v_DIFF
                       WHERE TRANSACTION_ID = C1.TRANSACTION_ID
                       AND   SCHEDULE_TYPE  = C1.SCHEDULE_TYPE
                       AND   SCHEDULE_STATE = SCHEDULE_STATE
                       AND   SCHEDULE_DATE  = v_DATE;

                       v_BOLMAX := FALSE;
                   END IF;


               END LOOP;

              v_DATE := v_DATE + 1/24;
         END LOOP;

     COMMIT;

  g_STEP_NAME := 'END';
   g_REPORT := g_REPORT  || 'FINISED Process';
   g_PRES := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, SUBSTR(SQLERRM,1,64), g_REPORT);

EXCEPTION
   WHEN OTHERS THEN
      g_PRES := Plog.LOG_PROCESS_EVENT(g_PID, Plog.c_SEV_ERROR, g_PROC_NAME, g_STEP_NAME, g_SOURCE, SQLERRM, 'ERROR in PJM_ROUND_ESCHEDULE');
      g_RESULT := GREATEST(g_RESULT, Plog.c_SEV_ERROR);
      g_PRES := Plog.LOG_PROCESS_END(g_PID, g_RESULT, SQLCODE, SQLERRM, g_REPORT);
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20002,'ERROR IN PJM_ROUND_ESCHEDULE DATA PLEASE CHECK PROCESS LOG  '||SQLERRM);


END PJM_ROUND_ESCHEDULE;

END  CDI_ACCEPT_SETTLEMENT_LOAD;
/
