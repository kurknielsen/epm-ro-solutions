CREATE OR REPLACE PACKAGE BODY CDI_STORE_PLC_DETAIL AS
g_PID                        Plog.t_PROCESS_DESCRIPTOR;
g_PRES                      Plog.t_PLOG_RESULT;
g_RESULT                    Plog.t_SEVERITY_CODE;
g_REPORT                    VARCHAR2(1024);
g_SOURCE                    VARCHAR2(1024);
g_PROC_NAME                VARCHAR2(64);
g_STEP_NAME                VARCHAR2(256);

g_PLC_INT_LIST            PLC_INT_TABLE;
g_PLC_AGGR_LIST           PLC_AGGR_TABLE;
g_PLC_INC_DEC_LIST        PLC_INC_DEC_TABLE;

g_INSIDE_RO                BOOLEAN;
g_USEFUL_LINE_COUNT        PLS_INTEGER := 0;
g_GB_VERSION               VARCHAR2(64);

PROCEDURE HANDLE_EXCEPTION(p_SQLCODE IN NUMBER, p_SQLERRM IN VARCHAR2) IS
BEGIN
   IF g_INSIDE_RO THEN
      g_PRES := Plog.LOG_PROCESS_EVENT(g_PID, Plog.c_SEV_ABORT, g_PROC_NAME, g_STEP_NAME, g_SOURCE, p_SQLERRM, 'UNHANDLED EXCEPTION');
   END IF;
   g_PRES := Plog.LOG_PROCESS_EVENT(g_PID, Plog.c_SEV_ABORT, g_PROC_NAME, g_STEP_NAME, g_SOURCE, p_SQLERRM, 'PROCESS EXCEPTION');
   g_PRES := Plog.LOG_PROCESS_END(g_PID, Plog.c_SEV_ABORT, p_SQLCODE, p_SQLERRM,'PROCESS EXCEPTION. CHECK PROCESS_EVENTS FOR DETAILS. '||g_REPORT);
END HANDLE_EXCEPTION;

FUNCTION DEFAULT_PROCESS_MESSAGE(p_STATUS IN NUMBER) RETURN VARCHAR2 IS
BEGIN
   RETURN
      CASE p_STATUS
         WHEN Plog.c_SEV_OK THEN 'Normal, successful completion'
         WHEN Plog.c_SEV_WARNING THEN 'Warnings encountered - check process log for details'
         WHEN Plog.c_SEV_ERROR THEN 'Errors encountered - check process log for details'
         ELSE 'PROBLEMS ENCOUNTERED - CHECK PROCESS LOG FOR DETAILS'
      END;
END DEFAULT_PROCESS_MESSAGE;

PROCEDURE GET_INIT_BID_BLOCK_SIZE
(
    p_BEGIN_DATE    IN DATE,
    p_END_DATE      IN DATE
)
IS

  v_BLOCK_SIZE   NUMBER(14,3);

  v_BEGIN_DATE   DATE := TRUNC(p_BEGIN_DATE);
  c_BEGIN_DATE   DATE := v_BEGIN_DATE - 1;

  CURSOR v_POLR_TYPE IS
    SELECT POLR_TYPE, SUM(ICAP_VALUE) AS ICAP_VALUE
    FROM CDI_PLC_LOAD
    WHERE PLC_DATE = v_BEGIN_DATE
    AND RFT_TICKET_NUMBER  IS NOT NULL
    GROUP BY POLR_TYPE;

BEGIN
   LOGS.LOG_DEBUG('GET_INIT_BID_BLOCK_SIZE Entry');

   g_PROC_NAME := 'CDI_STORE_PLC_DETAIL.GET_INIT_BID_BLOCK_SIZE';
   g_STEP_NAME := 'INITIALIZATION';
   g_REPORT    := '';
   g_PID       := Plog.LOG_PROCESS_START('GET_INIT_BID_BLOCK_SIZE');
   g_RESULT    := Plog.c_SEV_OK;
   g_STEP_NAME := 'DELETE';

   DELETE FROM CDI_BID_BLOCK_HIST
   WHERE EFFECTIVE_DATE  = c_BEGIN_DATE;
   LOGS.LOG_DEBUG('Delete CDI_BID_BLOCK_HIST Records: ' || TO_CHAR(SQL%ROWCOUNT));

  g_STEP_NAME := 'INSERT BASE BID BLOCK SIZE';

   INSERT INTO CDI_BID_BLOCK_HIST
   (
      RFP_ID,
      POLR_TYPE,
      BASE_BLOCK_SIZE,
      EFFECTIVE_DATE,
      STOP_DATE
   )
   SELECT
        SUPPLIER_ID,
        POLR_TYPE ,
        BASE_BLOCK_SIZE,
        c_BEGIN_DATE,
        POWER_FLOW_END - 1
   FROM BGE_SUPPLIER_VIEW
   WHERE INC_DEC_START = v_BEGIN_DATE
   AND BASE_BLOCK_SIZE IS NOT NULL;
   LOGS.LOG_DEBUG('Insert CDI_BID_BLOCK_HIST Records: ' || TO_CHAR(SQL%ROWCOUNT));

  g_STEP_NAME := 'LOOP TRHOUGH POLR_TYPES';
   FOR c_POLR_TYPE IN v_POLR_TYPE LOOP
            LOGS.LOG_DEBUG('POLR_TYPE: ' || c_POLR_TYPE.POLR_TYPE);
            g_STEP_NAME := 'LOOP TRHOUGH POLR_TYPES-RFP';
            FOR c_RFP IN
                (
                    SELECT
                        A.SUPPLIER_ID,
                        A.BASE_BLOCK_SIZE,
                        A.NUMBER_OF_BLOCKS,
                        A.SHARE_OF_LOAD,
                        A.INC_DEC_START,
                        A.POWER_FLOW_END
                    FROM BGE_SUPPLIER_VIEW A
                    WHERE POLR_TYPE   = c_POLR_TYPE.POLR_TYPE
                    AND INC_DEC_START = v_BEGIN_DATE
                    AND NOT EXISTS
                    (
                        SELECT 1 FROM CDI_BID_BLOCK_HIST AA
                        WHERE AA.RFP_ID = A.SUPPLIER_ID
                        AND   AA.POLR_TYPE = A.POLR_TYPE
                        AND AA.BASE_BLOCK_SIZE IS NOT NULL
                    )
                    ORDER BY A.SUPPLIER_ID, A.INC_DEC_START,  A.POWER_FLOW_END
                )  LOOP

                     LOGS.LOG_DEBUG('BLOCK_SIZE: ' || TO_CHAR(v_BLOCK_SIZE));
                     g_STEP_NAME := 'CALC. DYNAMIC BLOCK SIZE';
                    --jab  v_BLOCK_SIZE :=  (c_POLR_TYPE.ICAP_VALUE * c_RFP.SHARE_OF_LOAD)/NVL(c_RFP.NUMBER_OF_BLOCKS,1);

                     v_BLOCK_SIZE :=  (c_POLR_TYPE.ICAP_VALUE * c_RFP.SHARE_OF_LOAD) / c_RFP.NUMBER_OF_BLOCKS;

                     g_STEP_NAME := 'INSERT DYNAMIC SIZE';


                   INSERT INTO CDI_BID_BLOCK_HIST
                   (
                        RFP_ID,
                        POLR_TYPE,
                        BASE_BLOCK_SIZE,
                        EFFECTIVE_DATE,
                        STOP_DATE
                   )
                   VALUES
                   (
                        c_RFP.SUPPLIER_ID,
                        c_POLR_TYPE.POLR_TYPE,
                        v_BLOCK_SIZE,
                        c_BEGIN_DATE,
                        c_RFP.POWER_FLOW_END - 1
                   );

            END LOOP;

        END LOOP;

       g_STEP_NAME := 'COMMIT';
      COMMIT;
      LOGS.LOG_DEBUG('GET_INIT_BID_BLOCK_SIZE Exit');

   g_STEP_NAME := 'END';

  -- g_PRES := Plog.UPDATE_PROCESS_PROGRESS(g_PID, 3, 'DONE');
 --  g_PRES := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, SQLERRM, g_REPORT);

   --p_STATUS  := NULL; --g_RESULT;
   g_REPORT  := 'RECORDS PROCESSED';
 --  p_MESSAGE := 'SUCCESS';
   g_PRES    := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, 'SUCCESS', g_REPORT);


EXCEPTION
   WHEN OTHERS THEN
      HANDLE_EXCEPTION(SQLCODE, SQLERRM);
      ROLLBACK;
      RAISE;
END GET_INIT_BID_BLOCK_SIZE;

PROCEDURE GET_INIT_BID_BLOCK_SIZE_NEW
(
    p_BEGIN_DATE    IN DATE,
    p_END_DATE      IN DATE
)
IS

  v_BLOCK_SIZE   NUMBER(14,3);

  v_BEGIN_DATE   DATE := TRUNC(p_BEGIN_DATE);
  v_end_date     DATE := TRUNC(p_end_DATE);
BEGIN
   g_PROC_NAME := 'CDI_STORE_PLC_DETAIL.GET_INIT_BID_BLOCK_SIZE';
   g_STEP_NAME := 'INITIALIZATION';
   g_REPORT    := '';
   g_PID       := Plog.LOG_PROCESS_START('GET_INIT_BID_BLOCK_SIZE');
   g_RESULT    := Plog.c_SEV_OK;

   g_STEP_NAME := 'DELETE';

   DELETE FROM CDI_BID_BLOCK_HIST
   WHERE EFFECTIVE_DATE  between v_BEGIN_DATE-1  and v_end_date -1;

  g_STEP_NAME := 'INSERT BASE BID BLOCK SIZE';

   INSERT INTO CDI_BID_BLOCK_HIST
   (
      RFP_ID,
      POLR_TYPE,
      BASE_BLOCK_SIZE,
      EFFECTIVE_DATE,
      STOP_DATE
   )
   SELECT
        SUPPLIER_ID,
        POLR_TYPE ,
        BASE_BLOCK_SIZE,
        INC_DEC_START -1,
        POWER_FLOW_END - 1
   FROM BGE_SUPPLIER_VIEW
   WHERE INC_DEC_START between v_BEGIN_DATE   and v_end_date
   AND BASE_BLOCK_SIZE IS NOT NULL;


  INSERT INTO CDI_BID_BLOCK_HIST
                   (
                        RFP_ID,
                        POLR_TYPE,
                        BASE_BLOCK_SIZE,
                        EFFECTIVE_DATE,
                        STOP_DATE
                   )
     (
        SELECT SUPPLIER_ID,
               main.POLR_TYPE,
             -- jab   (ICAP_VALUE * SHARE_OF_LOAD)/NVL(NUMBER_OF_BLOCKS,1) v_BLOCK_SIZE,
               (ICAP_VALUE * SHARE_OF_LOAD) v_BLOCK_SIZE,
                INC_DEC_START - 1 v_start_date  ,
               POWER_FLOW_END - 1
        FROM
          (
            SELECT POLR_TYPE,
                   SUM(ICAP_VALUE) AS ICAP_VALUE,
                   my_date.BEGIN_DATE
            FROM CDI_PLC_LOAD cdi_p,
                  (
                    SELECT  trunc(v_BEGIN_DATE + LEVEL-1) + LEVEL-1 begin_date
                    FROM    DUAL
                    CONNECT BY LEVEL <=(v_end_date - v_BEGIN_DATE) +1
                  ) my_date
            WHERE cdi_p.PLC_DATE = my_date.BEGIN_DATE
            AND   cdi_p.RFT_TICKET_NUMBER  IS NOT NULL

            GROUP BY POLR_TYPE,
                     my_date.BEGIN_DATE
          )  main,
           (
                 SELECT
                        A.SUPPLIER_ID,
                        A.BASE_BLOCK_SIZE,
                        A.NUMBER_OF_BLOCKS,
                        A.SHARE_OF_LOAD,
                        A.INC_DEC_START,
                        A.POWER_FLOW_END,
                        A.POLR_TYPE
                    FROM   BGE_SUPPLIER_VIEW A
                    WHERE  A.INC_DEC_START between v_BEGIN_DATE  and v_end_date
                    AND NOT EXISTS
                    (
                        SELECT 1 FROM CDI_BID_BLOCK_HIST AA
                        WHERE AA.RFP_ID = A.SUPPLIER_ID
                        AND   AA.POLR_TYPE = A.POLR_TYPE
                        AND AA.BASE_BLOCK_SIZE IS NOT NULL
                    )
          ) supp
          WHERE main.polr_type      = supp.polr_type
          AND   main.begin_date     = supp.INC_DEC_START
      );


    g_STEP_NAME := 'COMMIT';
    COMMIT;

    g_STEP_NAME := 'END';

    g_REPORT  := 'RECORDS PROCESSED';
    g_PRES    := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, 'SUCCESS', g_REPORT);


EXCEPTION
   WHEN OTHERS THEN
      HANDLE_EXCEPTION(SQLCODE, SQLERRM);
      ROLLBACK;
      RAISE;
END GET_INIT_BID_BLOCK_SIZE_NEW;

PROCEDURE GET_INIT_BID_BLOCK_SIZE_PRX
(
    p_BEGIN_DATE    IN DATE,
    p_END_DATE      IN DATE
)
IS

  v_BLOCK_SIZE   NUMBER(14,3);

  v_BEGIN_DATE   DATE := TRUNC(p_BEGIN_DATE);
  c_BEGIN_DATE   DATE := v_BEGIN_DATE - 1;

  CURSOR v_POLR_TYPE IS
    SELECT POLR_TYPE, SUM(ICAP_VALUE) AS ICAP_VALUE
    FROM CDI_PLC_LOAD
    WHERE PLC_DATE = v_BEGIN_DATE
    AND   POLR_TYPE = 'PRX'
    AND RFT_TICKET_NUMBER  IS NOT NULL
    GROUP BY POLR_TYPE;

BEGIN

   g_PROC_NAME := 'CDI_STORE_PLC_DETAIL.GET_INIT_BID_BLOCK_SIZE';
   g_STEP_NAME := 'INITIALIZATION';
   g_REPORT    := '';
   g_PID       := Plog.LOG_PROCESS_START('GET_INIT_BID_BLOCK_SIZE');
   g_RESULT    := Plog.c_SEV_OK;
   g_STEP_NAME := 'DELETE';

   DELETE FROM CDI_BID_BLOCK_HIST
   WHERE EFFECTIVE_DATE  = c_BEGIN_DATE
   AND   POLR_TYPE = 'PRX';

  g_STEP_NAME := 'INSERT BASE BID BLOCK SIZE';

   INSERT INTO CDI_BID_BLOCK_HIST
   (
      RFP_ID,
      POLR_TYPE,
      BASE_BLOCK_SIZE,
      EFFECTIVE_DATE,
      STOP_DATE
   )
   SELECT
        SUPPLIER_ID,
        POLR_TYPE ,
        BASE_BLOCK_SIZE,
        c_BEGIN_DATE,
        POWER_FLOW_END - 1
   FROM BGE_SUPPLIER_VIEW
   WHERE INC_DEC_START = v_BEGIN_DATE
   AND   POLR_TYPE = 'PRX'
   AND   BASE_BLOCK_SIZE IS NOT NULL;

  g_STEP_NAME := 'LOOP TRHOUGH POLR_TYPES';
   FOR c_POLR_TYPE IN v_POLR_TYPE LOOP

            g_STEP_NAME := 'LOOP TRHOUGH POLR_TYPES-RFP';
            FOR c_RFP IN
                (
                    SELECT
                        A.SUPPLIER_ID,
                        A.BASE_BLOCK_SIZE,
                        A.NUMBER_OF_BLOCKS,
                        A.SHARE_OF_LOAD,
                        A.INC_DEC_START,
                        A.POWER_FLOW_END
                    FROM BGE_SUPPLIER_VIEW A
                    WHERE POLR_TYPE   = c_POLR_TYPE.POLR_TYPE
                    AND   POLR_TYPE = 'PRX'
                    AND INC_DEC_START = v_BEGIN_DATE
                    AND NOT EXISTS
                    (
                        SELECT 1 FROM CDI_BID_BLOCK_HIST AA
                        WHERE AA.RFP_ID = A.SUPPLIER_ID
                        AND   AA.POLR_TYPE = A.POLR_TYPE
                        AND AA.BASE_BLOCK_SIZE IS NOT NULL
                    )
                    ORDER BY A.SUPPLIER_ID, A.INC_DEC_START,  A.POWER_FLOW_END
                )  LOOP

                     g_STEP_NAME := 'CALC. DYNAMIC BLOCK SIZE';
                    -- jab  v_BLOCK_SIZE :=  (c_POLR_TYPE.ICAP_VALUE * c_RFP.SHARE_OF_LOAD)/NVL(c_RFP.NUMBER_OF_BLOCKS,1);

                     v_BLOCK_SIZE :=  (c_POLR_TYPE.ICAP_VALUE * c_RFP.SHARE_OF_LOAD) ;

                     g_STEP_NAME := 'INSERT DYNAMIC SIZE';


                   INSERT INTO CDI_BID_BLOCK_HIST
                   (
                        RFP_ID,
                        POLR_TYPE,
                        BASE_BLOCK_SIZE,
                        EFFECTIVE_DATE,
                        STOP_DATE
                   )
                   VALUES
                   (
                        c_RFP.SUPPLIER_ID,
                        c_POLR_TYPE.POLR_TYPE,
                        v_BLOCK_SIZE,
                        c_BEGIN_DATE,
                        c_RFP.POWER_FLOW_END - 1
                   );

            END LOOP;

        END LOOP;
   COMMIT;
   g_REPORT  := 'RECORDS PROCESSED';
   g_PRES    := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, 'SUCCESS', g_REPORT);
EXCEPTION
   WHEN OTHERS THEN
      HANDLE_EXCEPTION(SQLCODE, SQLERRM);
      ROLLBACK;
      RAISE;
END GET_INIT_BID_BLOCK_SIZE_PRX;

PROCEDURE GET_COMPETITIVE_POLR
(
    p_BEGIN_DATE    IN  DATE,
    p_END_DATE      IN  DATE,
    p_ICAP_VALUE    IN  NUMBER,
    p_NSPL_VALUE    IN  NUMBER
)
IS

    v_ICAP_VALUE    NUMBER;
    v_NET_VALUE     NUMBER;
    v_DATE          DATE;


BEGIN

   g_PROC_NAME := 'CDI_STORE_PLC_DETAIL.GET_COMPETITIVE_POLR';

   g_STEP_NAME := 'UPDATE COMP INT DATA';
   v_DATE := p_BEGIN_DATE;


   WHILE v_DATE <= p_END_DATE LOOP

        MERGE INTO CDI_PLC_LOAD CPL
            USING
            (
              SELECT PLC_DATE, ESP_ID, PSE_ID, CONTRACT_NAME, POLR_TYPE,
                     VOLTAGE_CLASS, REPORTED_SEGMENT, TICKET_NUMBER, PLC_BAND,
                     SUM(ICAP_VALUE) ICAP_VALUE, SUM(NSPL_VALUE) NSPL_VALUE
              FROM
              (
                  SELECT
                        v_DATE PLC_DATE,
                        B.ESP_ID,
                        F.PSE_ID,
                        G.CONTRACT_NAME,
                        D.POLR_TYPE,
                        D.VOLTAGE_CLASS,
                        D.REPORTED_SEGMENT,
                        NULL TICKET_NUMBER,
                        D.PLC_BAND,
                        SUM(CASE WHEN A.ANCILLARY_SERVICE_ID = p_ICAP_VALUE THEN A.SERVICE_VAL END) ICAP_VALUE,
                        SUM(CASE WHEN A.ANCILLARY_SERVICE_ID = p_NSPL_VALUE THEN A.SERVICE_VAL END) NSPL_VALUE
                    FROM    AGGREGATE_ANCILLARY_SERVICE A, AGGREGATE_ACCOUNT_ESP B, ENERGY_SERVICE_PROVIDER C, POOL D,
                             INTERCHANGE_CONTRACT E, PURCHASING_SELLING_ENTITY F,  TP_CONTRACT_NUMBER G, PSE_ESP H , ACCOUNT_EDC I
                    WHERE   A.AGGREGATE_ID    = B.AGGREGATE_ID
                    AND     B.ESP_ID        = C.ESP_ID
                    AND     B.POOL_ID       = D.POOL_ID
                    AND     B.ESP_ID        = H.ESP_ID
                    AND     H.PSE_ID        = F.PSE_ID
                    AND     E.CONTRACT_NAME = F.PSE_NAME
                    AND     I.ACCOUNT_ID    = B.ACCOUNT_ID
                    AND     E.CONTRACT_ID   = G.CONTRACT_ID
                    AND     UPPER(E.CONTRACT_NAME) NOT LIKE '%ALM%'
                    AND     A.SERVICE_DATE = v_DATE
                    AND     v_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN E.BEGIN_DATE AND NVL(E.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN G.BEGIN_DATE AND NVL(G.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN H.BEGIN_DATE AND NVL(H.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN I.BEGIN_DATE AND NVL(I.END_DATE, v_DATE)
                    GROUP BY  v_DATE,
                        B.ESP_ID,
                        F.PSE_ID,
                        G.CONTRACT_NAME,
                        D.POLR_TYPE,
                        D.VOLTAGE_CLASS,
                        D.REPORTED_SEGMENT ,
                        D.PLC_BAND
                  UNION
                   SELECT
                        v_DATE PLC_DATE,
                        B.ESP_ID,
                        F.PSE_ID,
                        G.CONTRACT_NAME,
                        D.POLR_TYPE,
                        D.VOLTAGE_CLASS,
                        D.REPORTED_SEGMENT,
                        NULL TICKET_NUMBER,
                        D.PLC_BAND,
                        SUM(CASE WHEN A.ANCILLARY_SERVICE_ID = p_ICAP_VALUE THEN A.SERVICE_VAL END) ICAP_VALUE,
                        SUM(CASE WHEN A.ANCILLARY_SERVICE_ID = p_NSPL_VALUE THEN A.SERVICE_VAL END) NSPL_VALUE
                    FROM    ACCOUNT_ANCILLARY_SERVICE A, ACCOUNT_ESP B, ENERGY_SERVICE_PROVIDER C, POOL D,
                            INTERCHANGE_CONTRACT E, PURCHASING_SELLING_ENTITY F,  TP_CONTRACT_NUMBER G, PSE_ESP H, ACCOUNT_EDC I
                    WHERE   A.ACCOUNT_ID    = B.ACCOUNT_ID
                    AND     B.ESP_ID        = C.ESP_ID
                    AND     B.POOL_ID       = D.POOL_ID
                    AND     B.ESP_ID        = H.ESP_ID
                    AND     H.PSE_ID        = F.PSE_ID
                    AND     E.CONTRACT_NAME = F.PSE_NAME
                    AND     I.ACCOUNT_ID    = B.ACCOUNT_ID
                    AND     E.CONTRACT_ID   = G.CONTRACT_ID
                    AND     UPPER(E.CONTRACT_NAME) NOT LIKE '%ALM%'
                    AND     v_DATE BETWEEN A.BEGIN_DATE AND NVL(A.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN E.BEGIN_DATE AND NVL(E.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN G.BEGIN_DATE AND NVL(G.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN H.BEGIN_DATE AND NVL(H.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN I.BEGIN_DATE AND NVL(I.END_DATE, v_DATE)
                    GROUP BY
                        v_DATE ,
                        B.ESP_ID,
                        F.PSE_ID,
                        G.CONTRACT_NAME,
                        D.POLR_TYPE,
                        D.VOLTAGE_CLASS,
                        D.REPORTED_SEGMENT,
                        D.PLC_BAND
               )
               GROUP BY
                    PLC_DATE, ESP_ID, PSE_ID, CONTRACT_NAME, POLR_TYPE,
                    VOLTAGE_CLASS, REPORTED_SEGMENT, TICKET_NUMBER, PLC_BAND
            )temp
              ON
              (
                trunc(temp.PLC_DATE)                = trunc(CPL.PLC_DATE)
                AND temp.ESP_ID                     = CPL.ESP_ID
                AND temp.PSE_ID                     = CPL.PSE_ID
                AND NVL(temp.CONTRACT_NAME,'A')     = NVL(CPL.PJM_SHORT_NAME, 'A')
                AND NVL(temp.POLR_TYPE,'B')         = NVL(CPL.POLR_TYPE, 'B')
                AND NVL(temp.VOLTAGE_CLASS, 'C')    = NVL(CPL.VOLTAGE_CLASS, 'C')
                AND NVL(temp.REPORTED_SEGMENT, 'D') = NVL(CPL.REPORTED_SEGMENT, 'D')
                AND NVL(temp.TICKET_NUMBER, 'E')    = NVL(CPL.RFT_TICKET_NUMBER, 'E')
                AND NVL(temp.PLC_BAND, 'F')         = NVL(CPL.PLC_BAND, 'F')
              )
              WHEN MATCHED THEN UPDATE SET CPL.ICAP_VALUE = temp.ICAP_VALUE,
                                            CPL.NSPL_VALUE = temp.NSPL_VALUE
              WHEN NOT MATCHED THEN
                    INSERT VALUES
                    (
                        temp.PLC_DATE,
                        temp.ESP_ID,
                        temp.PSE_ID,
                        temp.CONTRACT_NAME,
                        temp.POLR_TYPE,
                        temp.VOLTAGE_CLASS,
                        temp.REPORTED_SEGMENT,
                        NULL,
                        temp.PLC_BAND,
                        temp.ICAP_VALUE,
                        temp.NSPL_VALUE
                     );


         v_DATE  := v_DATE + 1;


      END LOOP;

   g_STEP_NAME := 'END GET_COMPETITIVE_POLR';

END GET_COMPETITIVE_POLR;

PROCEDURE GET_NON_COMPETITIVE_POLR
(
    p_BEGIN_DATE    IN  DATE,
    p_END_DATE      IN  DATE,
    p_ICAP_VALUE    IN  NUMBER,
    p_NSPL_VALUE    IN  NUMBER
)
IS

    v_ICAP_VALUE    NUMBER;
    v_NET_VALUE     NUMBER;
    v_DATE          DATE;


BEGIN
   g_PROC_NAME := 'CDI_STORE_PLC_DETAIL.GET_NON_COMPETITIVE_POLR';
   g_STEP_NAME := 'UPDATE GET_NON_COMPETITIVE_POLR';
   v_DATE := p_BEGIN_DATE;

   WHILE v_DATE  <= p_END_DATE LOOP

        FOR c_POLR IN
            (
                SELECT PLC_DATE, ESP_ID, PSE_ID,  POLR_TYPE,
                        VOLTAGE_CLASS, REPORTED_SEGMENT, TICKET_NUMBER, PLC_BAND,
                        SUM(ICAP_VALUE) ICAP_VALUE, SUM(NSPL_VALUE) NSPL_VALUE
                FROM
                (
                    SELECT  v_DATE PLC_DATE, B.ESP_ID, F.PSE_ID,  D.POLR_TYPE,
                       D.VOLTAGE_CLASS, D.REPORTED_SEGMENT, NULL TICKET_NUMBER, D.PLC_BAND,
                    SUM(CASE WHEN A.ANCILLARY_SERVICE_ID = p_ICAP_VALUE THEN A.SERVICE_VAL END) ICAP_VALUE,
                    SUM(CASE WHEN A.ANCILLARY_SERVICE_ID = p_NSPL_VALUE THEN A.SERVICE_VAL END) NSPL_VALUE
                    FROM    AGGREGATE_ANCILLARY_SERVICE A, AGGREGATE_ACCOUNT_ESP B, ENERGY_SERVICE_PROVIDER C, POOL D,
                              PURCHASING_SELLING_ENTITY F,   PSE_ESP H, ACCOUNT_EDC I
                    WHERE   UPPER(C.ESP_NAME) = 'DEFAULT'
                    AND     A.AGGREGATE_ID    = B.AGGREGATE_ID
                    AND     B.ESP_ID        = C.ESP_ID
                    AND     B.POOL_ID       = D.POOL_ID
                    AND     B.ESP_ID        = H.ESP_ID
                    AND     H.PSE_ID        = F.PSE_ID
                    AND     A.SERVICE_DATE  = v_DATE
                    AND     B.ACCOUNT_ID    = I.ACCOUNT_ID
                    AND     v_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN I.BEGIN_DATE AND NVL(I.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN H.BEGIN_DATE AND NVL(H.END_DATE, v_DATE)
                    GROUP BY v_DATE, B.ESP_ID, F.PSE_ID,  D.POLR_TYPE,
                       D.VOLTAGE_CLASS, D.REPORTED_SEGMENT, D.PLC_BAND
                UNION
                   SELECT  v_DATE PLC_DATE, B.ESP_ID, F.PSE_ID, D.POLR_TYPE,
                           D.VOLTAGE_CLASS, D.REPORTED_SEGMENT, NULL TICKET_NUMBER, D.PLC_BAND,
                       SUM( CASE WHEN A.ANCILLARY_SERVICE_ID = p_ICAP_VALUE THEN A.SERVICE_VAL END) ICAP_VALUE,
                       SUM( CASE WHEN A.ANCILLARY_SERVICE_ID = p_NSPL_VALUE THEN A.SERVICE_VAL END) NSPL_VALUE
                    FROM    ACCOUNT_ANCILLARY_SERVICE A, ACCOUNT_ESP B, ENERGY_SERVICE_PROVIDER C, POOL D,
                              PURCHASING_SELLING_ENTITY F,   PSE_ESP H, ACCOUNT_EDC  I
                    WHERE   UPPER(C.ESP_NAME) = 'DEFAULT'
                    AND     A.ACCOUNT_ID    = B.ACCOUNT_ID
                    AND     B.ESP_ID        = C.ESP_ID
                    AND     B.POOL_ID       = D.POOL_ID
                    AND     B.ESP_ID        = H.ESP_ID
                    AND     H.PSE_ID        = F.PSE_ID
                    AND     B.ACCOUNT_ID    = I.ACCOUNT_ID
                    AND     v_DATE BETWEEN A.BEGIN_DATE AND NVL(A.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN H.BEGIN_DATE AND NVL(H.END_DATE, v_DATE)
                    AND     v_DATE BETWEEN I.BEGIN_DATE AND NVL(I.END_DATE, v_DATE)
                    GROUP BY  v_DATE, B.ESP_ID, F.PSE_ID, D.POLR_TYPE,
                           D.VOLTAGE_CLASS, D.REPORTED_SEGMENT, D.PLC_BAND
               )
               GROUP BY
                    PLC_DATE, ESP_ID, PSE_ID, POLR_TYPE,
                    VOLTAGE_CLASS, REPORTED_SEGMENT, TICKET_NUMBER, PLC_BAND
            ) LOOP


                  INSERT INTO CDI_PLC_LOAD
                  (
                    PLC_DATE,
                    ESP_ID,
                    PSE_ID,
                    PJM_SHORT_NAME,
                    POLR_TYPE,
                    VOLTAGE_CLASS,
                    REPORTED_SEGMENT,
                    RFT_TICKET_NUMBER,
                    PLC_BAND,
                    ICAP_VALUE,
                    NSPL_VALUE
                  )
                   SELECT
                        v_DATE,
                        c_POLR.ESP_ID,
                        c_POLR.PSE_ID,
                        A.PJM_SHORT,
                        c_POLR.POLR_TYPE,
                        c_POLR.VOLTAGE_CLASS,
                        c_POLR.REPORTED_SEGMENT,
                        A.SUPPLIER_ID,
                        c_POLR.PLC_BAND,
                        SUM(c_POLR.ICAP_VALUE * A.SHARE_OF_LOAD),
                        SUM(c_POLR.NSPL_VALUE* A.SHARE_OF_LOAD)
                    FROM BGE_SUPPLIER_VIEW A
                        WHERE A.POLR_TYPE = c_POLR.POLR_TYPE
                        AND   v_DATE BETWEEN A.POWER_FLOW_START AND A.POWER_FLOW_END
                    GROUP BY
                        v_DATE,
                        c_POLR.ESP_ID,
                        c_POLR.PSE_ID,
                        A.PJM_SHORT,
                        c_POLR.POLR_TYPE,
                        c_POLR.VOLTAGE_CLASS,
                        c_POLR.REPORTED_SEGMENT,
                        A.SUPPLIER_ID,
                        c_POLR.PLC_BAND;
            END LOOP;
       v_DATE := v_DATE + 1;
  END LOOP;
END GET_NON_COMPETITIVE_POLR;

PROCEDURE PUT_INC_DEC
(
    p_BEGIN_DATE    IN  DATE,
    p_END_DATE      IN  DATE
)
IS

  -- LOCAL VARIABLES --
  v_BASE_SIZE_PRL   NUMBER(14,3);
  v_BASE_SIZE_PRX   NUMBER(14,3);
  v_BASE_SIZE       NUMBER(14,3);
  v_TOLERANCE       NUMBER(14,3);
  v_BASE_PERCENT    NUMBER(9,7);
  v_INC_PERCENT     NUMBER(9,7);
  v_DEDUCTION       NUMBER(14,3);
  v_DEDUCTION_PRL   NUMBER(14,3);
  v_DEDUCTION_PRX   NUMBER(14,3);
  v_ADJ             NUMBER(14,3);
  v_ADJ_PRL         NUMBER(14,3);
  v_ADJ_PRX         NUMBER(14,3);
  v_RES_PERCENT     NUMBER;
  v_INC_LABEL       VARCHAR(1);
  v_DEC_LABEL       VARCHAR(1);
  v_STORE_BASE_SIZE NUMBER(14,3);
  v_PRX_PERCENT_DEC NUMBER;
  v_PRL_PERCENT_DEC NUMBER;
  v_PRX_PERCENT_INC NUMBER;
  v_PRL_PERCENT_INC NUMBER;
  v_number_blocks   NUMBER;
  v_INC_MW          NUMBER := to_number(get_dictionary_value('INC_MW',
                                          0,
                                          'Settlement',
                                          'INC_DEC', --Synch Foward Days',
                                          '?',
                                          '?',
                                          0));
  v_DEC_MW          NUMBER := to_number(get_dictionary_value('DEC_MW',
                                          0,
                                          'Settlement',
                                          'INC_DEC', --Synch Foward Days',
                                          '?',
                                          '?',
                                          0));



  CURSOR v_POLR_TYPE IS
         SELECT MAIN.*
         FROM
         (
         SELECT PLC_DATE,
                DECODE(A.POLR_TYPE,'PRL','PRC','PRX', 'PRC',A.POLR_TYPE) POLR_TYPE,
                SUM(ICAP_VALUE) ICAP_VALUE,
                SUM(NSPL_VALUE) NSPL_VALUE,
                SUM(CASE WHEN POLR_TYPE IN ('PRL') THEN ICAP_VALUE ELSE 0 END) ICAP_VALUE_PRL,
                SUM(CASE WHEN POLR_TYPE IN ('PRL') THEN NSPL_VALUE ELSE 0 END) NSPL_VALUE_PRL,
                SUM(CASE WHEN POLR_TYPE IN ('PRX') THEN ICAP_VALUE ELSE 0 END) ICAP_VALUE_PRX,
                SUM(CASE WHEN POLR_TYPE IN ('PRX') THEN NSPL_VALUE ELSE 0 END) NSPL_VALUE_PRX
         FROM   CDI_PLC_LOAD a
         WHERE  PLC_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
         AND    RFT_TICKET_NUMBER IS NOT NULL
        -- and     RFT_TICKET_NUMBER <> 'CCG08TR2T1X12A'
       --  and    A.POLR_TYPE IN('PRL','PRX')
         GROUP BY PLC_DATE,
                 DECODE(A.POLR_TYPE,'PRL','PRC','PRX', 'PRC',A.POLR_TYPE) --POLR_TYPE
         ) MAIN
         ORDER BY PLC_DATE, POLR_TYPE;
c_DATE_FORMAT VARCHAR2(16) := 'MM/DD/YYYY';
BEGIN
   LOGS.LOG_INFO('System Settings INC_MW: ' || TO_CHAR(v_INC_MW) || ', DEC_MW: ' || TO_CHAR(v_DEC_MW));
   FOR c_POLR_TYPE IN v_POLR_TYPE LOOP
      LOGS.LOG_DEBUG('PLC_DATE: ' || TO_CHAR(c_POLR_TYPE.PLC_DATE, c_DATE_FORMAT) || ', POLR_TYPE: ' || c_POLR_TYPE.POLR_TYPE || ', ICAP_VALUE: ' || TO_CHAR(c_POLR_TYPE.ICAP_VALUE) || ', NSPL_VALUE: ' || TO_CHAR(c_POLR_TYPE.NSPL_VALUE) || ', ICAP_VALUE_PRL: ' || TO_CHAR(c_POLR_TYPE.ICAP_VALUE_PRL) || ', NSPL_VALUE_PRL: ' || TO_CHAR(c_POLR_TYPE.NSPL_VALUE_PRL) || ', ICAP_VALUE_PRX: ' || TO_CHAR(c_POLR_TYPE.ICAP_VALUE_PRX) || ', NSPL_VALUE_PRX: ' || TO_CHAR(c_POLR_TYPE.NSPL_VALUE_PRX));
        FOR v_DATA IN
            (SELECT distinct   case when polr_type = 'PRC' then BASE_BLOCK_SIZE_PRL/ decode(NUMBER_OF_BLOCKS_PRl,0,1,NUMBER_OF_BLOCKS_PRl) + (BASE_BLOCK_SIZE_PRx/ decode(NUMBER_OF_BLOCKS_PRX,0,1,NUMBER_OF_BLOCKS_PRX) ) + INC_MW else BASE_BLOCK_SIZE end BASE_BLOCK_SIZE2
             ,case when polr_type = 'PRC' then SHARE_OF_LOAD_PRL/ decode(NUMBER_OF_BLOCKS_PRl,0,1,NUMBER_OF_BLOCKS_PRl) + (SHARE_OF_LOAD_PRx/ decode(NUMBER_OF_BLOCKS_PRX,0,1,NUMBER_OF_BLOCKS_PRX) ) else SHARE_OF_LOAD2 end SHARE_OF_LOAD
                                                               ,main.*
             from
                  (
                      SELECT
                            A.RFT_TICKET_NUMBER RFP_TICKET_NUMBER,
                            DECODE(B.POLR_TYPE,'PRL','PRC','PRX', 'PRC',B.POLR_TYPE) POLR_TYPE,
                            A.PLC_DATE,
                            A.PJM_SHORT_NAME,
                            B.PJM_INC_SHORT,
                            sum(B.NUMBER_OF_BLOCKS) NUMBER_OF_BLOCKS,
                            MAX(B.NUMBER_OF_BLOCKS) MAX_NUMBER_OF_BLOCKS,
                            avg(B.INC_MW * 1000) INC_MW,
                            avg(B.DEC_MW * 1000) DEC_MW,
                            sum(C.BASE_BLOCK_SIZE) BASE_BLOCK_SIZE,
                            C.EFFECTIVE_DATE,
                            B.POWER_FLOW_END,
                            sum(B.SHARE_OF_LOAD) SHARE_OF_LOAD2,
                            SUM(A.ICAP_VALUE) AS ICAP_VALUE,
                            SUM(A.NSPL_VALUE) AS NSPL_VALUE ,
                            SUM(CASE WHEN c.POLR_TYPE = 'PRL'  THEN  C.BASE_BLOCK_SIZE ELSE 0 END ) BASE_BLOCK_SIZE_PRL,
                            SUM(CASE WHEN c.POLR_TYPE = 'PRX'  THEN  C.BASE_BLOCK_SIZE ELSE 0 END ) BASE_BLOCK_SIZE_PRX,
                            SUM(CASE WHEN b.POLR_TYPE = 'PRL'  THEN  B.NUMBER_OF_BLOCKS ELSE 0 END ) NUMBER_OF_BLOCKS_PRL,
                            SUM(CASE WHEN b.POLR_TYPE = 'PRX'  THEN  B.NUMBER_OF_BLOCKS ELSE 0 END ) NUMBER_OF_BLOCKS_PRX,
                            SUM(CASE WHEN b.POLR_TYPE = 'PRL'  THEN  B.SHARE_OF_LOAD ELSE 0 END ) SHARE_OF_LOAD_PRL,
                            SUM(CASE WHEN b.POLR_TYPE = 'PRX'  THEN  B.SHARE_OF_LOAD ELSE 0 END ) SHARE_OF_LOAD_PRX,
                            AVG(CASE WHEN b.POLR_TYPE = 'PRX'  THEN  B.DEC_MW * 1000  ELSE null END ) DEC_MW_PRX,
                            AVG(CASE WHEN b.POLR_TYPE = 'PRL'  THEN  B.DEC_MW * 1000  ELSE null END ) DEC_MW_PRL,
                            AVG(CASE WHEN b.POLR_TYPE = 'PRX'  THEN  B.INC_MW * 1000  ELSE null END ) INC_MW_PRX,
                            AVG(CASE WHEN b.POLR_TYPE = 'PRL'  THEN  B.INC_MW * 1000  ELSE null END ) INC_MW_PRL,
                            SUM(CASE WHEN c.POLR_TYPE = 'PRL'  THEN  C.BASE_BLOCK_SIZE - B.DEC_MW * 1000 ELSE 0 END ) dec_BASE_BLOCK_SIZE_PRL,
                            SUM(CASE WHEN c.POLR_TYPE = 'PRX'  THEN  C.BASE_BLOCK_SIZE - B.DEC_MW * 1000 ELSE 0 END ) dec_BASE_BLOCK_SIZE_PRX

                      FROM 
                            (select PLC_DATE,
                                    DECODE(A2.POLR_TYPE,'PRL','PRC','PRX', 'PRC',A2.POLR_TYPE) POLR_TYPE,
                                    A2.RFT_TICKET_NUMBER,
                                    A2.PJM_SHORT_NAME,
                                    SUM(A2.ICAP_VALUE) AS ICAP_VALUE,
                                    SUM(A2.NSPL_VALUE) AS NSPL_VALUE
                             from CDI_PLC_LOAD a2
                             where DECODE(A2.POLR_TYPE,'PRL','PRC','PRX', 'PRC',A2.POLR_TYPE) = c_POLR_TYPE.POLR_TYPE
                             group by PLC_DATE,
                                      DECODE(A2.POLR_TYPE,'PRL','PRC','PRX', 'PRC',A2.POLR_TYPE), --POLR_TYPE,
                                      A2.RFT_TICKET_NUMBER,
                                      A2.PJM_SHORT_NAME
                             ) A,
                            BGE_SUPPLIER_VIEW B,
                            CDI_BID_BLOCK_HIST C
                      WHERE A.PLC_DATE          = c_POLR_TYPE.PLC_DATE
                      AND   A.POLR_TYPE         = c_POLR_TYPE.POLR_TYPE
                      and   DECODE(B.POLR_TYPE,'PRL','PRC','PRX', 'PRC',B.POLR_TYPE) = A.POLR_TYPE
                      and   DECODE(C.POLR_TYPE,'PRL','PRC','PRX', 'PRC',C.POLR_TYPE) = A.POLR_TYPE
                      AND   C.POLR_TYPE         = B.POLR_TYPE
                      AND   A.RFT_TICKET_NUMBER = B.SUPPLIER_ID
                      AND   B.PJM_INC_SHORT IS NOT NULL
                      AND   C.RFP_ID = B.SUPPLIER_ID
                      AND   C.POLR_TYPE = B.POLR_TYPE
                      AND   c_POLR_TYPE.PLC_DATE BETWEEN  B.INC_DEC_START AND NVL(B.POWER_FLOW_END, c_POLR_TYPE.PLC_DATE)
                      AND   c_POLR_TYPE.PLC_DATE  BETWEEN  C.EFFECTIVE_DATE /*+ 1/(24*60)*/  AND NVL(C.STOP_DATE, c_POLR_TYPE.PLC_DATE ) --@@Oracle Bug??--
                      GROUP BY
                              A.RFT_TICKET_NUMBER,
                              DECODE(b.POLR_TYPE,'PRL','PRC','PRX', 'PRC',b.POLR_TYPE) , --A.POLR_TYPE,
                              A.PLC_DATE,
                              A.PJM_SHORT_NAME,
                              B.PJM_INC_SHORT,
                              C.EFFECTIVE_DATE,
                              B.POWER_FLOW_END
                  ) MAIN
                ORDER BY  RFP_TICKET_NUMBER, POLR_TYPE
          ) LOOP




             IF   v_DATA.POLR_TYPE = 'PRC' THEN
               BEGIN
                       SELECT SUM(AGG_BLOCK_ADJUSTMENT),
                              SUM(CASE WHEN  A.POLR_TYPE =  'PRL' THEN
                                             AGG_BLOCK_ADJUSTMENT
                                       ELSE
                                             0
                                       END
                                  ),
                              SUM(CASE WHEN  A.POLR_TYPE =  'PRX' THEN
                                             AGG_BLOCK_ADJUSTMENT
                                       ELSE
                                             0
                                       END
                                  )
                       INTO   v_ADJ,
                              v_ADJ_PRL,
                              v_ADJ_PRX
                       FROM  CDI_PLC_ANNUAL_ADJUST A
                       WHERE RFP_TICKET     = v_DATA.RFP_TICKET_NUMBER
                       AND   PJM_SHORT_NAME = v_DATA.PJM_SHORT_NAME
                       AND   A.POLR_TYPE    IN ('PRL','PRX')
                       AND   v_DATA.PLC_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, v_DATA.PLC_DATE);
               EXCEPTION
               WHEN OTHERS THEN
                    v_ADJ := 0;
                    v_ADJ_PRL :=0;
                    v_ADJ_PRX:=0;
               END;

               v_TOLERANCE     :=  v_DATA.BASE_BLOCK_SIZE_PRL + v_DATA.BASE_BLOCK_SIZE_PRX ;
               v_DEDUCTION     :=  v_DATA.BASE_BLOCK_SIZE_PRL + v_DATA.BASE_BLOCK_SIZE_PRX ;
               v_PRX_PERCENT_DEC := (v_DATA.BASE_BLOCK_SIZE_PRX/(v_DATA.BASE_BLOCK_SIZE_PRL + v_DATA.BASE_BLOCK_SIZE_PRX)) ;
               v_PRL_PERCENT_DEC := (v_DATA.BASE_BLOCK_SIZE_PRL/(v_DATA.BASE_BLOCK_SIZE_PRL + v_DATA.BASE_BLOCK_SIZE_PRX)) ;
               v_BASE_SIZE_PRL :=  case when v_DATA.NUMBER_OF_BLOCKS_PRL <> 0 THEN ((c_POLR_TYPE.ICAP_VALUE_PRL * v_DATA.SHARE_OF_LOAD_PRL) ) + nvl(v_ADJ_PRL,0) ELSE 0 END;
               v_BASE_SIZE_PRX :=  case when v_DATA.NUMBER_OF_BLOCKS_PRX <> 0 THEN ((c_POLR_TYPE.ICAP_VALUE_PRX * v_DATA.SHARE_OF_LOAD_PRX) ) + nvl(v_ADJ_PRX,0) ELSE 0 END;
               v_BASE_SIZE := v_BASE_SIZE_PRL + v_BASE_SIZE_PRX;
             ELSE
                BEGIN
                       SELECT AGG_BLOCK_ADJUSTMENT INTO v_ADJ
                       FROM   CDI_PLC_ANNUAL_ADJUST A
                       WHERE  RFP_TICKET     = v_DATA.RFP_TICKET_NUMBER
                       AND    PJM_SHORT_NAME = v_DATA.PJM_SHORT_NAME
                       AND   POLR_TYPE      = v_DATA.POLR_TYPE
                       AND   v_DATA.PLC_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, v_DATA.PLC_DATE);
                EXCEPTION
                  WHEN OTHERS THEN
                     v_ADJ := 0;
                END;
                v_TOLERANCE :=  v_DATA.BASE_BLOCK_SIZE;
                v_DEDUCTION :=  v_DATA.BASE_BLOCK_SIZE ;
                v_BASE_SIZE :=  ((c_POLR_TYPE.ICAP_VALUE * v_DATA.SHARE_OF_LOAD)) + v_ADJ;
             END IF;
             v_BASE_SIZE     :=  v_BASE_SIZE/v_data.MAX_NUMBER_OF_BLOCKS;
             v_BASE_SIZE_PRX :=  v_BASE_SIZE_PRX /v_data.MAX_NUMBER_OF_BLOCKS;
             v_BASE_SIZE_PRL :=  v_BASE_SIZE_PRL /v_data.MAX_NUMBER_OF_BLOCKS;
             LOGS.LOG_DEBUG('ICAP_VALUE: ' || TO_CHAR(c_POLR_TYPE.ICAP_VALUE) || ', SHARE_OF_LOAD: ' || TO_CHAR(v_DATA.SHARE_OF_LOAD) || ', ADJ: ' || TO_CHAR(v_ADJ) || ', MAX_NUMBER_OF_BLOCKS: ' || TO_CHAR(v_data.MAX_NUMBER_OF_BLOCKS) || ', BASE_SIZE: ' || TO_CHAR(v_BASE_SIZE) || ', TOLERANCE: ' || TO_CHAR(v_TOLERANCE) || ', DEDUCTION: ' || TO_CHAR(v_DEDUCTION) || ', BASE_SIZE_PRL: ' || TO_CHAR(v_BASE_SIZE_PRL) || ', BASE_SIZE_PRX: ' || TO_CHAR(v_BASE_SIZE_PRX));
             IF v_BASE_SIZE > (v_TOLERANCE + v_INC_MW) THEN
                v_TOLERANCE := v_TOLERANCE + v_INC_MW ;
                v_BASE_PERCENT :=  (v_TOLERANCE / v_BASE_SIZE);
                v_INC_PERCENT  :=  1 - v_BASE_PERCENT;
                LOGS.LOG_DEBUG('Increment Mode BASE_PERCENT: ' || TO_CHAR(v_BASE_PERCENT) || ', INC_PERCENT: ' || TO_CHAR(v_INC_PERCENT));
                INSERT INTO CDI_PLC_LOAD
                (
                    PLC_DATE,
                    ESP_ID,
                    PSE_ID,
                    PJM_SHORT_NAME,
                    POLR_TYPE,
                    VOLTAGE_CLASS,
                    REPORTED_SEGMENT,
                    RFT_TICKET_NUMBER,
                    PLC_BAND,
                    ICAP_VALUE,
                    NSPL_VALUE
                 )
                      SELECT distinct
                             CPL1.PLC_DATE,
                             CPL1.ESP_ID,
                             CPL1.PSE_ID,
                             v_DATA.PJM_INC_SHORT,
                             CPL1.POLR_TYPE,
                             CPL1.VOLTAGE_CLASS,
                             CPL1.REPORTED_SEGMENT,
                              CPL1.RFT_TICKET_NUMBER,
                             CPL1.PLC_BAND,
                             CPL1.ICAP_VALUE *   v_INC_PERCENT  ICAP_VALUE ,
                             CPL1.NSPL_VALUE *   v_INC_PERCENT  NSPL_VALUE
                        FROM CDI_PLC_LOAD CPL1
                        WHERE CPL1.PLC_DATE          = v_DATA.PLC_DATE
                        AND   CPL1.RFT_TICKET_NUMBER = v_DATA.RFP_TICKET_NUMBER
                        AND   CPL1.PJM_SHORT_NAME    = v_DATA.PJM_SHORT_NAME
                        AND   DECODE(CPL1.POLR_TYPE,'PRL','PRC','PRX', 'PRC',CPL1.POLR_TYPE) = v_DATA.POLR_TYPE;

                UPDATE CDI_PLC_LOAD CPL SET
                                            CPL.ICAP_VALUE  = CPL.ICAP_VALUE * v_BASE_PERCENT ,
                                            CPL.NSPL_VALUE  = CPL.NSPL_VALUE * v_BASE_PERCENT
                WHERE CPL.PLC_DATE               = v_DATA.PLC_DATE
                AND CPL.RFT_TICKET_NUMBER        = v_DATA.RFP_TICKET_NUMBER
                AND NVL(CPL.PJM_SHORT_NAME, 'B') = NVL(v_DATA.PJM_SHORT_NAME, 'B')
                AND DECODE(NVL(CPL.POLR_TYPE, 'A'),'PRL','PRC','PRX', 'PRC',NVL(CPL.POLR_TYPE, 'A')) = NVL(v_DATA.POLR_TYPE, 'A');

                v_INC_LABEL := 'Y';
                v_DEC_LABEL := 'N';

            ELSIF v_BASE_SIZE < (v_DEDUCTION - v_DEC_MW) THEN
                LOGS.LOG_DEBUG('Decrement Mode');
                g_STEP_NAME := 'DEC OCCURRED';

                v_DEDUCTION := v_DEDUCTION - v_DEC_MW * FLOOR((v_DEDUCTION - v_BASE_SIZE)/v_DEC_MW);

                UPDATE  CDI_BID_BLOCK_HIST SET STOP_DATE      = v_DATA.PLC_DATE - 1,
                                               EFFECTIVE_DATE = LEAST(v_DATA.EFFECTIVE_DATE, v_DATA.PLC_DATE - 2)
                WHERE RFP_ID = v_DATA.RFP_TICKET_NUMBER
                and   DECODE(POLR_TYPE,'PRL','PRC','PRX', 'PRC',POLR_TYPE) = v_DATA.POLR_TYPE
                AND   EFFECTIVE_DATE = v_DATA.EFFECTIVE_DATE;


               IF   v_DATA.POLR_TYPE = 'PRC' THEN


                     INSERT INTO CDI_BID_BLOCK_HIST
                    (
                      RFP_ID,
                      POLR_TYPE,
                      BASE_BLOCK_SIZE,
                      EFFECTIVE_DATE,
                      STOP_DATE
                     )
                     VALUES
                     (
                       v_DATA.RFP_TICKET_NUMBER,
                       'PRL',
                       v_DEDUCTION * v_PRL_PERCENT_DEC, --v_DEDUCTION_PRL,
                       v_DATA.PLC_DATE,
                       GREATEST(v_DATA.PLC_DATE + 1, v_DATA.POWER_FLOW_END)
                     );

                     INSERT INTO CDI_BID_BLOCK_HIST
                    (
                      RFP_ID,
                      POLR_TYPE,
                      BASE_BLOCK_SIZE,
                      EFFECTIVE_DATE,
                      STOP_DATE
                     )
                     VALUES
                     (
                       v_DATA.RFP_TICKET_NUMBER,
                       'PRX',
                       v_DEDUCTION * v_PRX_PERCENT_DEC, --v_DEDUCTION_PRX,
                       v_DATA.PLC_DATE,
                       GREATEST(v_DATA.PLC_DATE + 1, v_DATA.POWER_FLOW_END)
                     );
              ELSE
                     INSERT INTO CDI_BID_BLOCK_HIST
                    (
                      RFP_ID,
                      POLR_TYPE,
                      BASE_BLOCK_SIZE,
                      EFFECTIVE_DATE,
                      STOP_DATE
                     )
                     VALUES
                     (
                       v_DATA.RFP_TICKET_NUMBER,
                       v_DATA.POLR_TYPE,
                       v_DEDUCTION ,
                       v_DATA.PLC_DATE,
                       GREATEST(v_DATA.PLC_DATE + 1, v_DATA.POWER_FLOW_END)
                     );

              END IF;

                v_BASE_PERCENT := 1;
                v_INC_PERCENT  := 0;

                v_INC_LABEL := 'N';
                v_DEC_LABEL := 'Y';
            ELSE
               LOGS.LOG_DEBUG('Normal Mode');
                g_STEP_NAME := 'ELSE PROCESS';
                v_BASE_PERCENT := 1;
                v_INC_PERCENT  := 0;

                v_INC_LABEL := 'N';
                v_DEC_LABEL := 'N';
             END IF;

             IF   v_DATA.POLR_TYPE = 'PRC' THEN
                    IF v_DATA.BASE_BLOCK_SIZE_PRX <> 0 and v_BASE_SIZE_PRX <> 0 THEN
                        INSERT INTO CDI_INC_DEC_EVENT_HIST
                        (
                            RFP_TICKET,
                            PJM_SHORT_NAME,
                            POLR_TYPE,
                            BASE_BLOCK_SIZE,
                            NEW_BLOCK_SIZE,
                            INC,
                            DEC,
                            PLC_DATE
                        )
                        VALUES
                        (
                            v_DATA.RFP_TICKET_NUMBER,
                            v_DATA.PJM_SHORT_NAME,
                            'PRX',
                            v_DATA.BASE_BLOCK_SIZE_PRX ,
                            v_BASE_SIZE_PRX , -- jab *  CASE WHEN v_INC_LABEL = 'Y' THEN (v_DATA.BASE_BLOCK_SIZE / v_BASE_SIZE) ELSE 1 END, --v_BASE_PERCENT,
                            v_INC_LABEL,
                            v_DEC_LABEL,
                            v_DATA.PLC_DATE
                        );
                    END IF;
                    IF v_DATA.BASE_BLOCK_SIZE_PRL <> 0 and v_BASE_SIZE_PRL <> 0 THEN
                        INSERT INTO CDI_INC_DEC_EVENT_HIST
                        (
                            RFP_TICKET,
                            PJM_SHORT_NAME,
                            POLR_TYPE,
                            BASE_BLOCK_SIZE,
                            NEW_BLOCK_SIZE ,
                            INC,
                            DEC,
                            PLC_DATE
                        )
                        VALUES
                        (
                            v_DATA.RFP_TICKET_NUMBER,
                            v_DATA.PJM_SHORT_NAME,
                            'PRL',
                            v_DATA.BASE_BLOCK_SIZE_PRL ,
                            v_BASE_SIZE_PRL, --jab  * CASE WHEN v_INC_LABEL = 'Y' THEN (v_DATA.BASE_BLOCK_SIZE / v_BASE_SIZE) ELSE 1 END, --v_BASE_PERCENT,
                            v_INC_LABEL,
                            v_DEC_LABEL,
                            v_DATA.PLC_DATE
                        );
                     END IF;
                ELSE
                        INSERT INTO CDI_INC_DEC_EVENT_HIST
                        (
                            RFP_TICKET,
                            PJM_SHORT_NAME,
                            POLR_TYPE,
                            BASE_BLOCK_SIZE,
                            NEW_BLOCK_SIZE,
                            INC,
                            DEC,
                            PLC_DATE
                        )
                        VALUES
                        (
                            v_DATA.RFP_TICKET_NUMBER,
                            v_DATA.PJM_SHORT_NAME,
                            v_DATA.POLR_TYPE,
                            v_DATA.BASE_BLOCK_SIZE,
                            v_BASE_SIZE,
                            v_INC_LABEL,
                            v_DEC_LABEL,
                            v_DATA.PLC_DATE
                        );
              END IF;
         DBMS_OUTPUT.PUT_LINE('TOLERANCE: ' || TO_CHAR(v_TOLERANCE) || ', DEDUCTION: ' || TO_CHAR(v_DEDUCTION) || ', PRX_PERCENT_DEC: ' || TO_CHAR(ROUND(v_PRX_PERCENT_DEC,6)) || ', PRL_PERCENT_DEC: ' || TO_CHAR(ROUND(v_PRL_PERCENT_DEC,6)) || ', BASE_SIZE_PRL: ' || TO_CHAR(v_BASE_SIZE_PRL) || ', BASE_SIZE_PRX: ' || TO_CHAR(v_BASE_SIZE_PRX) || ', BASE_SIZE: ' || TO_CHAR(v_BASE_SIZE) || ', BASE_PERCENT: ' || TO_CHAR(v_BASE_PERCENT) || ', INC_PERCENT: ' || TO_CHAR(v_INC_PERCENT) || ', INC_LABEL: ' || v_INC_LABEL || ', DEC_LABEL: ' || v_DEC_LABEL);
            MERGE INTO CDI_BASE_LOAD_ALLOC CBLA
                USING
                (
                      SELECT
                        v_DATA.PLC_DATE  PLC_DATE,
                        v_DATA.RFP_TICKET_NUMBER RFP_TICKET,
                        v_DATA.POLR_TYPE  POLR_TYPE,
                         case when v_INC_LABEL = 'N'  THEN 1 else v_TOLERANCE/v_BASE_SIZE end  B_PERCENT
                      FROM DUAL
                      WHERE v_DATA.POLR_TYPE <> 'PRC'
                      UNION ALL
                      SELECT
                        v_DATA.PLC_DATE  PLC_DATE,
                        v_DATA.RFP_TICKET_NUMBER RFP_TICKET,
                        'PRX' POLR_TYPE,
                        case when v_INC_LABEL = 'N'  THEN 1 else v_TOLERANCE/v_BASE_SIZE end  B_PERCENT
                      FROM DUAL
                      where  v_DATA.POLR_TYPE = 'PRC'
                      UNION ALL
                      SELECT
                        v_DATA.PLC_DATE  PLC_DATE,
                        v_DATA.RFP_TICKET_NUMBER RFP_TICKET,
                        'PRL' POLR_TYPE,
                       case when v_INC_LABEL = 'N'  THEN 1 else v_TOLERANCE/v_BASE_SIZE end  B_PERCENT
                      FROM DUAL
                      where v_DATA.POLR_TYPE = 'PRC'
                )temp
                ON
                (
                        temp.PLC_DATE    = CBLA.PLC_DATE
                    AND temp.RFP_TICKET  = CBLA.RFP_TICKET
                    AND temp.POLR_TYPE   = CBLA.POLR_TYPE
                )
                WHEN MATCHED THEN UPDATE SET CBLA.BASE_LOAD_FACTOR = temp.B_PERCENT
                WHEN NOT MATCHED THEN
                    INSERT VALUES
                    (
                        temp.PLC_DATE,
                        temp.RFP_TICKET,
                        temp.POLR_TYPE,
                        temp.B_PERCENT
                    );
          END LOOP;
   END LOOP;

END PUT_INC_DEC;

PROCEDURE MAIN
   (
   p_BEGIN_DATE IN  DATE,
   p_END_DATE   IN  DATE,
   p_VALUE      IN  NUMBER,
   p_STATUS     OUT NUMBER
   ) AS
v_BEGIN_DATE    DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE      DATE := TRUNC(GREATEST(p_BEGIN_DATE, p_END_DATE));
v_ICAP_VALUE    NUMBER;
v_NET_VALUE     NUMBER;
v_DATE          DATE;
BEGIN

   g_PID := PLOG.LOG_PROCESS_START('CDI_STORE_PLC_DETAIL');
   
   BEGIN
      SELECT ANCILLARY_SERVICE_ID INTO v_ICAP_VALUE FROM ANCILLARY_SERVICE WHERE ANCILLARY_SERVICE_NAME =  c_ICAP_VALUE;
   EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'ICAP ANCILLARY ID NOT FOUND PLEASE CREATE');
   END;

   BEGIN
      SELECT ANCILLARY_SERVICE_ID INTO v_NET_VALUE FROM ANCILLARY_SERVICE  WHERE ANCILLARY_SERVICE_NAME =  c_NET_VALUE;
   EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20010, 'TX ANCILLARY ID NOT FOUND PLEASE CREATE');
   END;

   DELETE CDI_PLC_LOAD WHERE PLC_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;
   DELETE CDI_BASE_LOAD_ALLOC WHERE PLC_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;
   DELETE CDI_INC_DEC_EVENT_HIST WHERE PLC_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;
   v_DATE := v_BEGIN_DATE;

   GET_COMPETITIVE_POLR(v_BEGIN_DATE, v_END_DATE, v_ICAP_VALUE, v_NET_VALUE);
   GET_NON_COMPETITIVE_POLR(v_BEGIN_DATE, v_END_DATE, v_ICAP_VALUE, v_NET_VALUE);

    IF p_VALUE <> 1 THEN
       DELETE CDI_INC_DEC_EVENT_HIST WHERE PLC_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;
       PUT_INC_DEC(v_BEGIN_DATE, v_END_DATE);
    END IF;

   g_PRES := Plog.UPDATE_PROCESS_PROGRESS(g_PID, 3, 'DONE');
   g_PRES := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, SQLERRM, g_REPORT);

EXCEPTION
   WHEN OTHERS THEN
      HANDLE_EXCEPTION(SQLCODE, SQLERRM);
      ROLLBACK;
      RAISE;

END MAIN;

END  CDI_STORE_PLC_DETAIL;
/

