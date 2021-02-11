CREATE OR REPLACE PACKAGE BODY CDI_MULTI_ACCOUNT_REPORTS AS

--------------------------------------------------------
PROCEDURE INTERPRET_RUN_TYPE
    (
    p_RUN_TYPE_ID IN NUMBER,
    p_SERVICE_CODE OUT VARCHAR2,
    p_SCENARIO_ID OUT NUMBER
    ) AS

BEGIN

    ASSERT(NVL(p_RUN_TYPE_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
        'An invalid value for RUN_TYPE_ID was specified: ' || p_RUN_TYPE_ID, MSGCODES.c_ERR_ARGUMENT);

    IF p_RUN_TYPE_ID < 0 THEN
        SELECT ST.SERVICE_CODE, ST.SCENARIO_ID
        INTO p_SERVICE_CODE, p_SCENARIO_ID
        FROM SETTLEMENT_TYPE ST
        WHERE ST.SETTLEMENT_TYPE_ID = (p_RUN_TYPE_ID * -1);
    ELSE
        p_SERVICE_CODE := GA.FORECAST_SERVICE;
        p_SCENARIO_ID := p_RUN_TYPE_ID;
    END IF;

END INTERPRET_RUN_TYPE;
---------------------------------------------------------------------------------------------------

  PROCEDURE POOL_ESP_ACCOUNT_TREE
 (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_CURSOR OUT GA.REFCURSOR
 ) AS
  BEGIN
  OPEN p_CURSOR FOR
  SELECT EDC.EDC_ID, EDC_NAME, PSE.PSE_ID, PSE_NAME, ESP.ESP_ID, ESP_NAME, POOL.POOL_ID, POOL_NAME, A.ACCOUNT_ID, A.ACCOUNT_MODEL_OPTION, 0 AS AGGREGATE_ID, s.service_id, ACCOUNT_NAME, 1 SORT_ORDER
  from account a, account_esp aesp, account_edc aedc, pse_esp pe, edc, pse, esp, pool, account_service a_s, provider_service p_s, service_delivery s_d, service s
  where a.account_id = aesp.account_id
    and a.is_sub_aggregate = 0
    and a.model_id = 1
    and aesp.begin_date <= p_END_DATE
    and nvl(aesp.end_date,high_date) >= p_BEGIN_DATE
    and a.account_id = aedc.account_id
    AND AEDC.BEGIN_DATE <= P_END_DATE
    and nvl(aedc.end_date,high_date) >= p_BEGIN_DATE
    and aesp.esp_id = pe.esp_id
    and pe.begin_date <= p_END_DATE
    and nvl(pe.end_date,high_date) >= p_BEGIN_DATE
    and aesp.esp_id = esp.esp_id
    and aesp.pool_id = pool.pool_id
    and pe.pse_id = pse.pse_id
    AND AEDC.EDC_ID = EDC.EDC_ID
    AND A_S.ACCOUNT_ID = A.ACCOUNT_ID
    AND P_S.EDC_ID = EDC.EDC_ID
    AND P_S.PSE_ID = PSE.PSE_ID
    AND P_S.ESP_ID = ESP.ESP_ID
    and S_D.POOL_ID = POOL.POOL_ID
    -- and S_D.is_aggregate_pool = 0
    AND S.ACCOUNT_SERVICE_ID = A_S.ACCOUNT_SERVICE_ID
    and s.provider_service_id = P_S.provider_service_id
    and S.SERVICE_DELIVERY_ID = S_D.SERVICE_DELIVERY_ID
    and S.SERVICE_ID in (select SS.SERVICE_ID
                           from SERVICE_STATE SS
                           where SS.SERVICE_DATE between P_BEGIN_DATE and P_END_DATE)
  union all
    select distinct EDC.EDC_ID, EDC_NAME, PSE.PSE_ID, PSE_NAME, ESP.ESP_ID, ESP_NAME, POOL.POOL_ID, POOL_NAME,  AESP.AGGREGATE_ID AS ACCOUNT_ID,
            a.ACCOUNT_MODEL_OPTION, AESP.AGGREGATE_ID, S.SERVICE_ID, ACCOUNT_NAME, 0 SORT_ORDER
  from account a, aggregate_account_esp aesp, account_edc aedc, pse_esp pe, edc, pse, esp, pool, account_service a_s, provider_service p_s, service_delivery s_d, service s
  where a.account_id = aesp.account_id
    and a.is_sub_aggregate = 0
    and a.model_id = 1
    and aesp.begin_date <= p_END_DATE
    and nvl(aesp.end_date,high_date) >= p_BEGIN_DATE
    and a.account_id = aedc.account_id
    and aedc.begin_date <= p_END_DATE
    and nvl(aedc.end_date,high_date) >= p_BEGIN_DATE
    and aesp.esp_id = pe.esp_id
    and pe.begin_date <= p_END_DATE
    and nvl(pe.end_date,high_date) >= p_BEGIN_DATE
    and aesp.esp_id = esp.esp_id
    and aesp.pool_id = pool.pool_id
    and pe.pse_id = pse.pse_id
    and aedc.edc_id = edc.edc_id
    AND A_S.ACCOUNT_ID = A.ACCOUNT_ID
    and A_S.AGGREGATE_ID = AESP.AGGREGATE_ID
    AND P_S.EDC_ID = EDC.EDC_ID
    AND P_S.PSE_ID = PSE.PSE_ID
    AND P_S.ESP_ID = ESP.ESP_ID
    and S_D.POOL_ID = POOL.POOL_ID
    -- and S_D.is_aggregate_pool = 0
    AND S.ACCOUNT_SERVICE_ID = A_S.ACCOUNT_SERVICE_ID
    AND S.PROVIDER_SERVICE_ID = P_S.PROVIDER_SERVICE_ID
    and S.SERVICE_DELIVERY_ID = S_D.SERVICE_DELIVERY_ID
    and S.SERVICE_ID in (select SS.SERVICE_ID
                           from SERVICE_STATE SS
                           where SS.SERVICE_DATE between P_BEGIN_DATE and P_END_DATE)
  ORDER BY 2, 4, 6, 8, 10, 14, 13;

  END POOL_ESP_ACCOUNT_TREE;
---------------------------------------------------------------------------------------------------
  PROCEDURE GET_MULTI_ACCOUNT_DETAILS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_EDC_ID            IN NUMBER_COLLECTION,
    p_PSE_ID            IN NUMBER_COLLECTION,
    p_ESP_ID            IN NUMBER_COLLECTION,
    p_POOL_ID           IN NUMBER_COLLECTION,
    p_ACCOUNT_ID        IN NUMBER_COLLECTION,
    P_AGGREGATE_ID      IN NUMBER_COLLECTION,
    p_SERVICE_ID        IN NUMBER_COLLECTION,
    P_UOM               OUT VARCHAR2,
    P_CURSOR            OUT GA.REFCURSOR,
    P_MESSAGE           OUT VARCHAR2
    ) AS

  /* CREATE TABLE CDI_MULTI_ACCOUNT_SELECTION_GT
  (EDC_ID NUMBER, PSE_ID NUMBER(9), ESP_ID NUMBER(9), POOL_ID NUMBER(9), ACCOUNT_ID NUMBER(9), AGGREGATE_ID NUMBER(9), SERVICE_ID NUMBER(9)  );
  MAKE THIS A TEMPORARY TABLE SO YOU DON'T HAVE TO DELETE AT END*/

  /* the p_AGGREGATE_ID collection does not pass a collection of aggregate ids, instead the SERVICE_ID is used to look up the load */

v_EDC_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ESP_ID NUMBER(9);
v_POOL_ID NUMBER(9);
V_AGGREGATE_ID NUMBER(9);
V_ACCOUNT_ID NUMBER(9);
v_SERVICE_ID NUMBER(9);

v_SERVICE_CODE CHAR(1);
v_SCENARIO_ID NUMBER(9);

v_BEGIN DATE;
v_END DATE;
v_CUT_BEGIN_DATE DATE;
v_CUT_END_DATE DATE;

v_SHOW_W NUMBER(1) := 0;
v_SHOW_WO NUMBER(1) := 0;
v_SHOW_DETAILS NUMBER(1) := 0;

v_CNT NUMBER(9) := 0;
v_SVC_CNT NUMBER(9) := 0;
v_ACCT_CNT NUMBER(9) := 0;
v_AGG_CNT NUMBER(9) := 0;
v_EDC NUMBER(1) := 0;
v_PSE NUMBER(1) := 0;
v_ESP NUMBER(1) := 0;
v_POOL NUMBER(1) := 0;
v_ACCOUNT NUMBER(1) := 0;
V_AGGREGATE NUMBER(1) := 0;
v_SERVICE NUMBER(1) := 0;
v_AGG_POOL VARCHAR2(1) := 'A';

BEGIN

--    p_UOM := CASE WHEN p_MODEL_ID = GA.ELECTRIC_MODEL THEN GA.ELEC_SCHED_UNIT_OF_MEASURMENT
--                    WHEN p_MODEL_ID = GA.GAS_MODEL THEN GA.GAS_SCHED_UNIT_OF_MEASURMENT
--                    ELSE '?' END;

   DELETE FROM CDI_MULTI_ACCOUNT_SELECTION_GT;

    ASSERT(p_INTERVAL IS NOT NULL, 'A null value was given for INTERVAL, this field must be non-null.',
        MSGCODES.c_ERR_ARGUMENT);

    ASSERT(NVL(p_DISPLAY_TYPE, c_SERVICE_WITH_LOSSES) IN (c_SERVICE_WITH_LOSSES, c_SERVICE_WO_LOSSES, c_SERVICE_WITH_DETAILS), 'An invalid option for Display Type was given.'
        || '  Display Type must be '''|| c_SERVICE_WITH_LOSSES || ''', ''' || c_SERVICE_WO_LOSSES || ''' or ''' ||
        c_SERVICE_WITH_DETAILS || '''.  Actual value = ' || p_DISPLAY_TYPE, MSGCODES.c_ERR_ARGUMENT);

    CASE WHEN NVL(p_DISPLAY_TYPE,c_SERVICE_WITH_LOSSES) = c_SERVICE_WITH_LOSSES THEN
          v_SHOW_W := 1;
      WHEN NVL(p_DISPLAY_TYPE,c_SERVICE_WITH_LOSSES) = c_SERVICE_WO_LOSSES THEN
          v_SHOW_WO := 1;
      ELSE
          v_SHOW_W := 1;
          v_SHOW_WO := 1;
          v_SHOW_DETAILS := 1;
    END CASE;


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

    IF p_ACCOUNT_ID IS NULL THEN -- SUMMARY LEVEL QUERY

        IF p_EDC_ID IS NULL THEN
           v_EDC := 0;
        ELSE
           v_CNT := p_EDC_ID.COUNT;
           v_EDC := 1;
        END IF;

        IF p_PSE_ID IS NULL THEN
              v_PSE := 0;
        ELSE
            v_CNT := p_PSE_ID.COUNT;
            v_PSE := 1;
        END IF;

        IF p_ESP_ID IS NULL THEN
           v_ESP := 0;
        ELSE
           v_CNT := p_ESP_ID.COUNT;
           v_ESP := 1;
        END IF;

        IF p_POOL_ID IS NULL THEN
              v_POOL := 0;
        ELSE
           v_CNT := p_POOL_ID.COUNT;
           v_POOL := 1;
        END IF;

        IF V_CNT > 0 THEN
          for V_IDX in 1..V_CNT LOOP
            IF v_EDC = 1 THEN v_EDC_ID := p_EDC_ID(V_IDX); ELSE v_EDC_ID := -1; END IF;
            IF v_PSE = 1 THEN v_PSE_ID := p_PSE_ID(V_IDX); ELSE v_PSE_ID := -1; END IF;
            IF v_ESP = 1 THEN v_ESP_ID := p_ESP_ID(V_IDX); ELSE v_ESP_ID := -1; END IF;
            IF V_POOL = 1 THEN V_POOL_ID := P_POOL_ID(V_IDX); ELSE V_POOL_ID := -1; END IF;
            v_ACCOUNT_ID := 0;
            V_AGGREGATE_ID := 0;
            v_SERVICE_ID := 0;

            INSERT INTO CDI_MULTI_ACCOUNT_SELECTION_GT VALUES (
              v_EDC_ID, v_PSE_ID, v_ESP_ID, v_POOL_ID, v_ACCOUNT_ID, v_AGGREGATE_ID, v_SERVICE_ID);

          END LOOP;

          OPEN p_CURSOR FOR
          SELECT Q.DT,
                 Q.EDC_ID,
                 Q.EDC_NAME,
                 Q.PSE_ID,
                 Q.PSE_NAME,
                 Q.ESP_ID,
                 Q.ESP_NAME,
                 Q.POOL_ID,
                 Q.POOL_NAME,
                 NULL as SERVICE_ID,
                 NULL AS ACCOUNT_NAME,
                 CASE WHEN v_SHOW_W = 1 THEN SUM(Q.WITH_LOSSES) ELSE NULL END AS WITH_LOSSES,
                 CASE WHEN v_SHOW_WO = 1 THEN SUM(Q.WITHOUT_LOSSES) ELSE NULL END AS WITHOUT_LOSSES,
                 CASE WHEN v_SHOW_DETAILS = 1 THEN SUM(Q.TX_LOSS_VAL) ELSE NULL END AS TX_LOSS_VAL,
                 CASE WHEN v_SHOW_DETAILS = 1 THEN SUM(Q.DX_LOSS_VAL) ELSE NULL END AS DX_LOSS_VAL,
                 CASE WHEN v_SHOW_DETAILS = 1 THEN SUM(Q.UFE_LOAD_VAL) ELSE NULL END AS UE_LOSS_VAL
            FROM
             (SELECT TRIM(CASE p_INTERVAL
                           WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                           WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                           WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                           WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                           WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                           WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                           WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                           WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS DT,
                  SDT.CUT_DATE,
                  X.EDC_ID,
                  EDC.EDC_NAME,
                  X.PSE_ID,
                  PSE.PSE_NAME,
                  X.ESP_ID,
                  ESP.ESP_NAME,
                  X.POOL_ID,
                  POOL.POOL_NAME,
                  X.LOAD_VAL AS WITHOUT_LOSSES,
                  X.LOAD_VAL +  X.TX_LOSS_VAL + X.DX_LOSS_VAL + X.UFE_LOAD_VAL AS WITH_LOSSES,
                  X.TX_LOSS_VAL,
                  X.DX_LOSS_VAL,
                  X.UFE_LOAD_VAL
                FROM
                 (SELECT CDI.EDC_ID, CDI.PSE_ID, CDI.ESP_ID, CDI.POOL_ID, SOL.LOAD_DATE, SUM(SOL.LOAD_VAL) LOAD_VAL, SUM(SOL.TX_LOSS_VAL) TX_LOSS_VAL, SUM(SOL.DX_LOSS_VAL) DX_LOSS_VAL, SUM(SOL.UFE_LOAD_VAL) UFE_LOAD_VAL
                    FROM SERVICE_OBLIGATION SO, SERVICE_OBLIGATION_LOAD SOL, PROVIDER_SERVICE PS, SERVICE_DELIVERY SD, CDI_MULTI_ACCOUNT_SELECTION_GT CDI
                   WHERE SO.MODEL_ID = 1
                     AND SO.SCENARIO_ID = v_SCENARIO_ID
                     AND SO.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
                     AND SO.SERVICE_DELIVERY_ID = SD.SERVICE_DELIVERY_ID
                     AND (CDI.EDC_ID = -1 OR CDI.EDC_ID = PS.EDC_ID)
                     AND (CDI.PSE_ID = -1 OR CDI.PSE_ID = PS.PSE_ID)
                     AND (CDI.ESP_ID = -1 OR CDI.ESP_ID = PS.ESP_ID)
                     AND (CDI.POOL_ID = -1  OR
                          (CDI.POOL_ID = SD.POOL_ID OR  SD.POOL_ID IN  (SELECT SUB_POOL_ID FROM  POOL_SUB_POOL WHERE POOL_ID = CDI.POOL_ID)))
                     AND SOL.SERVICE_OBLIGATION_ID = SO.SERVICE_OBLIGATION_ID
                     AND SOL.LOAD_CODE = GA.STANDARD
                     AND ((SO.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SOL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE)
                       OR (SO.MODEL_ID = CONSTANTS.GAS_MODEL AND SOL.LOAD_DATE BETWEEN v_BEGIN AND v_END))
                     AND SOL.SERVICE_CODE = v_SERVICE_CODE
                   GROUP BY CDI.EDC_ID, CDI.PSE_ID, CDI.ESP_ID, CDI.POOL_ID, SOL.LOAD_DATE
                 ) X,
                  SYSTEM_DATE_TIME SDT,
                  ENERGY_DISTRIBUTION_COMPANY EDC,
                  PURCHASING_SELLING_ENTITY PSE,
                  ENERGY_SERVICE_PROVIDER ESP,
                  POOL
                WHERE SDT.TIME_ZONE = p_TIME_ZONE
                  AND SDT.DAY_TYPE = GA.STANDARD
                  AND 1 IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
                  AND 1 = SDT.DATA_INTERVAL_TYPE
                  AND X.LOAD_DATE  = SDT.CUT_DATE
                  AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                        AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
                  AND EDC.EDC_ID (+) = X.EDC_ID
                  AND PSE.PSE_ID (+) = X.PSE_ID
                  AND ESP.ESP_ID (+) = X.ESP_ID
                  AND POOL.POOL_ID (+) = X.POOL_ID) Q
            GROUP BY Q.DT, Q.EDC_ID, Q.EDC_NAME, Q.PSE_ID, Q.PSE_NAME, Q.ESP_ID, Q.ESP_NAME, Q.POOL_ID, Q.POOL_NAME
            ORDER BY 1, 3, 5, 7, 9;

        ELSE
          OPEN P_CURSOR FOR    SELECT NULL FROM DUAL;
        END IF;

    ELSE -- ACCOUNT LEVEL QUERY

       IF p_ACCOUNT_ID IS NULL THEN
          V_ACCOUNT := 0;
       ELSE
          v_ACCT_CNT := p_ACCOUNT_ID.COUNT;
          V_ACCOUNT := 1;
       END IF;

       IF p_PSE_ID IS NULL THEN  v_PSE_ID := -1; END IF;
       IF p_ESP_ID IS NULL THEN  v_ESP_ID := -1; END IF;

       FOR V_IDX in 1..v_ACCT_CNT LOOP

            INSERT INTO CDI_MULTI_ACCOUNT_SELECTION_GT VALUES
              (0,
                CASE WHEN v_PSE_ID <> -1 THEN 0 ELSE v_PSE_ID END,
                CASE WHEN v_ESP_ID <> -1 THEN 0 ELSE v_ESP_ID END,
                -1, p_ACCOUNT_ID(v_IDX),0,111  );

       END LOOP;

       OPEN p_CURSOR FOR
            SELECT L.DT,
                ACCOUNT_ID,
                ESP_NAME,
                ESP_ID,
                POOL_NAME,
                POOL_ID,
                ACCOUNT_NAME,
                SERVICE_ID,
                SUM(L.WITH_LOSSES) AS WITH_LOSSES,
                SUM(L.WITHOUT_LOSSES) AS WITHOUT_LOSSES,
                SUM(L.TX_LOSS_VAL) AS TX_LOSS_VAL,
                SUM(L.DX_LOSS_VAL) AS DX_LOSS_VAL,
                SUM(L.UE_LOSS_VAL) AS UE_LOSS_VAL
            FROM (SELECT TRIM(CASE p_INTERVAL
                                WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS DT,
                    SDT.CUT_DATE,
                    SERVICE_ID,
                    ACCOUNT_ID,
                    ESP_NAME,
                    ESP_ID,
                    POOL_NAME,
                    POOL_ID,
                    ACCOUNT_NAME,
                    CASE WHEN v_SHOW_W = 1 THEN X.LOAD_VAL+X.TX_LOSS_VAL+X.DX_LOSS_VAL+X.UE_LOSS_VAL ELSE NULL END AS WITH_LOSSES,
                    CASE WHEN v_SHOW_WO = 1 THEN X.LOAD_VAL ELSE NULL END AS WITHOUT_LOSSES,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.TX_LOSS_VAL ELSE NULL END AS TX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.DX_LOSS_VAL ELSE NULL END AS DX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.UE_LOSS_VAL ELSE NULL END AS UE_LOSS_VAL
                FROM
                  (
                    SELECT AA.LOAD_DATE, 1, DECODE(AA.AGGREGATE_ID,0,AA.ACCOUNT_ID,AA.AGGREGATE_ID) AS ACCOUNT_ID, AA.ACCOUNT_NAME, AGGREGATE_ID, -1 ESP_ID, -1 POOL_ID,
                    NULL ESP_NAME, NULL POOL_NAME, AA.LOAD_VAL, AA.TX_LOSS_VAL, DX_LOSS_VAL, UE_LOSS_VAL, AA.ACCOUNT_ID SERVICE_ID
                   FROM
                    (SELECT (ASRV.ACCOUNT_ID) ACCOUNT_ID,(ASRV.AGGREGATE_ID) AGGREGATE_ID,(A.ACCOUNT_NAME) ACCOUNT_NAME,
                            SL.LOAD_DATE LOAD_DATE, SUM(SL.LOAD_VAL) LOAD_VAL, SUM(SL.TX_LOSS_VAL) TX_LOSS_VAL,
                            SUM(SL.DX_LOSS_VAL) DX_LOSS_VAL, SUM(SL.UE_LOSS_VAL) UE_LOSS_VAL
                     FROM SERVICE S,  ACCOUNT_SERVICE ASRV,  ACCOUNT A,  SERVICE_LOAD SL,
                          CDI_MULTI_ACCOUNT_SELECTION_GT C,
                          PROVIDER_SERVICE PSRV,  SERVICE_DELIVERY DSRV,ESP, POOL
                      WHERE (ASRV.ACCOUNT_ID = C.ACCOUNT_ID OR ASRV.AGGREGATE_ID = C.ACCOUNT_ID)
                        AND  ASRV.ACCOUNT_SERVICE_ID = S.ACCOUNT_SERVICE_ID
                        AND PSRV.PROVIDER_SERVICE_ID = S.PROVIDER_SERVICE_ID
                        AND DSRV.SERVICE_DELIVERY_ID = S.SERVICE_DELIVERY_ID
                        AND SL.SERVICE_ID = S.SERVICE_ID
                        AND SL.SERVICE_CODE = v_SERVICE_CODE
                        AND SL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE
                        AND PSRV.ESP_ID = ESP.ESP_ID
                        AND DSRV.POOL_ID = POOL.POOL_ID
                        AND ASRV.ACCOUNT_ID = A.ACCOUNT_ID
                        GROUP BY ASRV.ACCOUNT_ID, ASRV.AGGREGATE_ID, A.ACCOUNT_NAME,  SL.LOAD_DATE ) AA
                 ) X,
                     SYSTEM_DATE_TIME SDT
                    WHERE SDT.TIME_ZONE = p_TIME_ZONE
                        AND SDT.DAY_TYPE = GA.STANDARD
                        AND 1 = SDT.DATA_INTERVAL_TYPE
                        --AND X.LOAD_DATE(+) = SDT.CUT_DATE
                        AND X.LOAD_DATE = SDT.CUT_DATE
                        AND SDT.CUT_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE) L
            GROUP BY L.DT, ACCOUNT_ID, L.SERVICE_ID, L.ESP_NAME, L.ESP_ID, L.POOL_NAME, L.POOL_ID, L.ACCOUNT_NAME
            ORDER BY L.ACCOUNT_NAME, L.DT, L.ESP_NAME, L.POOL_NAME;

    END IF; -- if SUMMARY

   COMMIT;

  END GET_MULTI_ACCOUNT_DETAILS;
--------------------------------------------------------

PROCEDURE GET_LOAD_COMPARISON_M
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_SERVICE_ID        IN NUMBER,
    p_RUN_TYPE_A_ID     IN NUMBER,
    p_RUN_TYPE_B_ID     IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_ENTITY_TYPE       IN VARCHAR2,
    p_ENTITY_ID         IN NUMBER,
    p_ACCOUNT_ID        IN NUMBER,
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_METER_ID          IN NUMBER,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_UOM               OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS

    v_SERVICE_CODE_A SERVICE_LOAD.SERVICE_CODE%TYPE;
    v_SCENARIO_ID_A SERVICE.SCENARIO_ID%TYPE;
    v_SERVICE_CODE_B SERVICE_LOAD.SERVICE_CODE%TYPE;
    v_SCENARIO_ID_B SERVICE.SCENARIO_ID%TYPE;

    v_BEGIN DATE;
    v_END DATE;

    v_CUT_BEGIN_DATE DATE;
    V_CUT_END_DATE DATE;
    p_MAX_ACCOUNTS NUMBER := 100;

BEGIN

    IF p_INTERVAL NOT IN (CONSTANTS.INTERVAL_15_MINUTE, CONSTANTS.INTERVAL_30_MINUTE, CONSTANTS.INTERVAL_HOUR, CONSTANTS.INTERVAL_DAY) THEN
        v_BEGIN := DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_BEGIN_DATE,p_INTERVAL);
        v_END := DATE_UTIL.END_DATE_FOR_INTERVAL(DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_END_DATE,p_INTERVAL),p_INTERVAL);
    ELSE
        v_BEGIN := p_BEGIN_DATE;
        v_END := p_END_DATE;
    END IF;

    SP.CHECK_SYSTEM_DATE_TIME(p_TIME_ZONE,v_BEGIN,v_END);
    INTERPRET_RUN_TYPE(p_RUN_TYPE_A_ID,v_SERVICE_CODE_A,v_SCENARIO_ID_A);
    INTERPRET_RUN_TYPE(p_RUN_TYPE_B_ID,v_SERVICE_CODE_B,v_SCENARIO_ID_B);
    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,v_BEGIN,v_END,p_TIME_ZONE,v_CUT_BEGIN_DATE,v_CUT_END_DATE);

    p_UOM := CASE WHEN p_SERVICE_ID = GA.ELECTRIC_MODEL THEN GA.ELECTRIC_UNIT_OF_MEASURMENT
                  WHEN p_SERVICE_ID = GA.GAS_MODEL THEN GA.GAS_UNIT_OF_MEASURMENT END;

  OPEN P_CURSOR FOR
    WITH BASE AS (
    SELECT LOAD_DATE,
         ACCOUNT_NAME,
         LOAD_VAL_A,
         LOAD_VAL_B,
         (LOAD_VAL_A-LOAD_VAL_B) DIFF,
         CASE WHEN LOAD_VAL_A = 0 THEN NULL ELSE (100 * (LOAD_VAL_A - LOAD_VAL_B) / LOAD_VAL_A) END PERC_DIFF
    FROM (
      SELECT CASE p_INTERVAL
             WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END AS LOAD_DATE,
           ACCOUNT_NAME,
           SUM(LOAD_VAL_A) LOAD_VAL_A,
           SUM(LOAD_VAL_B) LOAD_VAL_B
      FROM (
        SELECT LOAD_DATE, ACCOUNT_NAME, LOAD_VAL_A, LOAD_VAL_B
        FROM (
          SELECT SL.LOAD_DATE LOAD_DATE,
               A.ACCOUNT_NAME,
               SUM(SL.LOAD_VAL) +
                 CASE WHEN p_DISPLAY_TYPE = c_SERVICE_WITH_LOSSES THEN
                   SUM(SL.TX_LOSS_VAL)+SUM(SL.DX_LOSS_VAL)+SUM(SL.UE_LOSS_VAL)
                 ELSE 0
                 END LOAD_VAL_A
          FROM SERVICE_LOAD SL,
             SERVICE S,
             ACCOUNT_SERVICE ASE,
             ACCOUNT A
          WHERE SL.SERVICE_CODE = v_SERVICE_CODE_A
            AND SL.LOAD_DATE BETWEEN
                CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
              AND
                CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
            AND SL.SERVICE_ID = S.SERVICE_ID
            AND S.MODEL_ID = p_SERVICE_ID
            AND S.SCENARIO_ID = v_SCENARIO_ID_A
            AND S.ACCOUNT_SERVICE_ID = ASE.ACCOUNT_SERVICE_ID
            AND ASE.ACCOUNT_ID = A.ACCOUNT_ID
                      AND ((ASE.ACCOUNT_ID = p_ACCOUNT_ID AND p_ENTITY_TYPE = 'ACCOUNT')
                                OR (ASE.SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID AND p_ENTITY_TYPE = 'SERVICE_LOCATION')
                                OR (ASE.METER_ID = p_METER_ID AND p_ENTITY_TYPE = 'METER'))
          GROUP BY LOAD_DATE, ACCOUNT_NAME
          ORDER BY LOAD_DATE
        ) A FULL OUTER JOIN (
          SELECT SL.LOAD_DATE LOAD_DATE,
               A.ACCOUNT_NAME,
               SUM(SL.LOAD_VAL) +
                 CASE WHEN p_DISPLAY_TYPE = c_SERVICE_WITH_LOSSES THEN
                   SUM(SL.TX_LOSS_VAL)+SUM(SL.DX_LOSS_VAL)+SUM(SL.UE_LOSS_VAL)
                 ELSE 0
                 END LOAD_VAL_B
          FROM SERVICE_LOAD SL,
             SERVICE S,
             ACCOUNT_SERVICE ASE,
             ACCOUNT A
          WHERE SL.SERVICE_CODE = v_SERVICE_CODE_B
            AND SL.LOAD_DATE BETWEEN
                CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
              AND
                CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
            AND SL.SERVICE_ID = S.SERVICE_ID
            AND S.MODEL_ID = p_SERVICE_ID
            AND S.SCENARIO_ID = v_SCENARIO_ID_B
            AND S.ACCOUNT_SERVICE_ID = ASE.ACCOUNT_SERVICE_ID
            AND ASE.ACCOUNT_ID = A.ACCOUNT_ID
                      AND ((ASE.ACCOUNT_ID = p_ACCOUNT_ID AND p_ENTITY_TYPE = 'ACCOUNT')
                                OR (ASE.SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID AND p_ENTITY_TYPE = 'SERVICE_LOCATION')
                                OR (ASE.METER_ID = p_METER_ID AND p_ENTITY_TYPE = 'METER'))
          GROUP BY LOAD_DATE, ACCOUNT_NAME
          ORDER BY LOAD_DATE
        ) B
        USING(LOAD_DATE, ACCOUNT_NAME)
        ORDER BY LOAD_DATE
      ) SLA RIGHT JOIN SYSTEM_DATE_TIME SDT ON SLA.LOAD_DATE = SDT.CUT_DATE
      WHERE SDT.TIME_ZONE = p_TIME_ZONE
        AND SDT.DATA_INTERVAL_TYPE = p_SERVICE_ID
        AND SDT.CUT_DATE BETWEEN
            CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
          AND
            CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
        AND SDT.DAY_TYPE = GA.STANDARD
        AND ACCOUNT_NAME IS NOT NULL
      GROUP BY CASE p_INTERVAL
             WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END,
           ACCOUNT_NAME
      ORDER BY CASE p_INTERVAL
             WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
             WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END,
           ACCOUNT_NAME
    )
  ), DATES AS (
      SELECT COUNT(DISTINCT LOAD_DATE) ROW_COUNT
    FROM BASE
  ), MAPE_CALC AS (
      SELECT ACCOUNT_NAME,
             'MAPE: ' || ROUND(SUM(ABS(PERC_DIFF))/MAX(ROW_COUNT),4) MAPE
      FROM BASE,
         DATES
      GROUP BY ACCOUNT_NAME
  ), ACCOUNT_RANKINGS AS (
      SELECT ACCOUNT_NAME,
           RANK() OVER (ORDER BY DIFF_SUM DESC NULLS LAST, ACCOUNT_NAME NULLS LAST) AS RANKING
    FROM (
      SELECT ACCOUNT_NAME,
           ABS(SUM(DIFF)) DIFF_SUM
      FROM BASE
      GROUP BY ACCOUNT_NAME
    )
  )
  SELECT B.LOAD_DATE,
       B.ACCOUNT_NAME,
       MC.MAPE,
       B.LOAD_VAL_A,
       B.LOAD_VAL_B,
       B.DIFF,
       B.PERC_DIFF
  FROM BASE B,
       MAPE_CALC MC,
     ACCOUNT_RANKINGS AR
  WHERE B.ACCOUNT_NAME = MC.ACCOUNT_NAME(+)
    AND B.ACCOUNT_NAME = AR.ACCOUNT_NAME(+)
    AND (NVL(p_MAX_ACCOUNTS, CONSTANTS.ALL_ID) = CONSTANTS.ALL_ID OR AR.RANKING <= p_MAX_ACCOUNTS)
  ORDER BY LOAD_DATE, ACCOUNT_NAME
  ;

END GET_LOAD_COMPARISON_M;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_MULTI_ACCOUNT_STATS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_EDC_ID                   IN NUMBER_COLLECTION,
    p_PSE_ID                  IN NUMBER_COLLECTION,
    p_ESP_ID                   IN NUMBER_COLLECTION,
    p_POOL_ID                  IN NUMBER_COLLECTION,
    p_ACCOUNT_ID        IN NUMBER_COLLECTION,
    p_AGGREGATE_ID      IN NUMBER_COLLECTION,
    p_CURSOR                OUT GA.REFCURSOR
    ) AS

  /* CREATE TABLE CDI_MULTI_ACCOUNT_SELECTION_GT
  (EDC_ID NUMBER, PSE_ID NUMBER(9), ESP_ID NUMBER(9), POOL_ID NUMBER(9), ACCOUNT_ID NUMBER(9), AGGREGATE_ID NUMBER(9)  );
  MAKE THIS A TEMPORARY TABLE SO YOU DON'T HAVE TO DELETE AT END*/
v_EDC_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ESP_ID NUMBER(9);
v_POOL_ID NUMBER(9);
v_AGGREGATE_ID NUMBER(9);
v_ACCOUNT_ID NUMBER(9);

v_SERVICE_CODE CHAR(1);
v_SCENARIO_ID NUMBER(9);

v_BEGIN DATE;
v_END DATE;
v_CUT_BEGIN_DATE DATE;
v_CUT_END_DATE DATE;

v_SHOW_W NUMBER(1) := 0;
v_SHOW_WO NUMBER(1) := 0;
v_SHOW_DETAILS NUMBER(1) := 0;

v_CNT NUMBER(1) := 0;
v_EDC NUMBER(1) := 0;
v_PSE NUMBER(1) := 0;
v_ESP NUMBER(1) := 0;
v_POOL NUMBER(1) := 0;
v_ACCOUNT NUMBER(1) := 0;
v_AGGREGATE NUMBER(1) := 0;

BEGIN

    ASSERT(p_INTERVAL IS NOT NULL, 'A null value was given for INTERVAL, this field must be non-null.',
        MSGCODES.c_ERR_ARGUMENT);

    ASSERT(NVL(p_DISPLAY_TYPE, c_SERVICE_WITH_LOSSES) IN (c_SERVICE_WITH_LOSSES, c_SERVICE_WO_LOSSES, c_SERVICE_WITH_DETAILS), 'An invalid option for Display Type was given.'
        || '  Display Type must be '''|| c_SERVICE_WITH_LOSSES || ''', ''' || c_SERVICE_WO_LOSSES || ''' or ''' ||
        c_SERVICE_WITH_DETAILS || '''.  Actual value = ' || p_DISPLAY_TYPE, MSGCODES.c_ERR_ARGUMENT);

    CASE WHEN NVL(p_DISPLAY_TYPE,c_SERVICE_WITH_LOSSES) = c_SERVICE_WITH_LOSSES THEN
          v_SHOW_W := 1;
      WHEN NVL(p_DISPLAY_TYPE,c_SERVICE_WITH_LOSSES) = c_SERVICE_WO_LOSSES THEN
          v_SHOW_WO := 1;
      ELSE
          v_SHOW_W := 1;
          v_SHOW_WO := 1;
          v_SHOW_DETAILS := 1;
    END CASE;

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

    IF p_EDC_ID IS NULL THEN
          v_EDC := 0;
    ELSE
          v_CNT := p_EDC_ID.COUNT;
          v_EDC := 1;
    END IF;

    IF p_PSE_ID IS NULL THEN
          v_PSE := 0;
    ELSE
          v_CNT := p_PSE_ID.COUNT;
          v_PSE := 1;
    END IF;

    IF p_ESP_ID IS NULL THEN
          v_ESP := 0;
    ELSE
          v_CNT := p_ESP_ID.COUNT;
          v_ESP := 1;
    END IF;

    IF p_POOL_ID IS NULL THEN
          v_POOL := 0;
    ELSE
          v_CNT := p_POOL_ID.COUNT;
          v_POOL := 1;
    END IF;

    IF p_ACCOUNT_ID IS NULL THEN
          v_ACCOUNT := 0;
    ELSE
          v_CNT := p_ACCOUNT_ID.COUNT;
          v_ACCOUNT := 1;
    END IF;

    IF p_AGGREGATE_ID IS NULL THEN
          v_AGGREGATE := 0;
    ELSE
          v_CNT := p_AGGREGATE_ID.COUNT;
          v_AGGREGATE := 1;
    END IF;

    IF v_CNT > 0 THEN
       FOR v_IDX IN 1..v_CNT LOOP
            IF v_EDC = 1 THEN v_EDC_ID := p_EDC_ID(V_IDX); ELSE v_EDC_ID := -1; END IF;
            IF v_PSE = 1 THEN v_PSE_ID := p_PSE_ID(V_IDX); ELSE v_PSE_ID := -1; END IF;
            IF v_ESP = 1 THEN v_ESP_ID := p_ESP_ID(V_IDX); ELSE v_ESP_ID := -1; END IF;
            IF v_POOL = 1 THEN v_POOL_ID := p_POOL_ID(V_IDX); ELSE v_POOL_ID := -1; END IF;
            IF v_ACCOUNT = 1 THEN v_ACCOUNT_ID := p_ACCOUNT_ID(V_IDX); ELSE v_ACCOUNT_ID := 0; END IF;
            IF v_AGGREGATE = 1 THEN v_AGGREGATE_ID := p_AGGREGATE_ID(V_IDX); ELSE v_AGGREGATE_ID := 0; END IF;

            INSERT INTO CDI_MULTI_ACCOUNT_SELECTION_GT VALUES (
              v_EDC_ID, v_PSE_ID, v_ESP_ID, v_POOL_ID, v_ACCOUNT_ID, v_AGGREGATE_ID, 0);
          END LOOP;
    END IF;


    IF p_ACCOUNT_ID IS NULL THEN
          -- handle subtotals based on the selected folder

        IF v_CNT > 0 THEN
          OPEN p_CURSOR FOR
          SELECT Q.DT,
                 Q.EDC_ID,
                 Q.EDC_NAME,
                 Q.PSE_ID,
                 Q.PSE_NAME,
                 Q.ESP_ID,
                 Q.ESP_NAME,
                 Q.POOL_ID,
                 Q.POOL_NAME,
                 NULL AS ACCOUNT_NAME,
                 CASE WHEN v_SHOW_W = 1 THEN SUM(Q.WITH_LOSSES) ELSE NULL END AS WITH_LOSSES,
                 CASE WHEN v_SHOW_WO = 1 THEN SUM(Q.WITHOUT_LOSSES) ELSE NULL END AS WITHOUT_LOSSES,
                 CASE WHEN V_SHOW_DETAILS = 1 THEN SUM(Q.TX_LOSS_VAL) ELSE NULL END AS TX_LOSS_VAL,
                 CASE WHEN V_SHOW_DETAILS = 1 THEN SUM(Q.DX_LOSS_VAL) ELSE NULL END AS DX_LOSS_VAL,
                 CASE WHEN v_SHOW_DETAILS = 1 THEN SUM(Q.UFE_LOAD_VAL) ELSE NULL END AS UE_LOSS_VAL,
                 MAX(Q.WITH_LOSSES) AS PEAK,
                 ROUND(AVG(Q.WITH_LOSSES),4) AS AVERAGE,
                 ROUND(AVG(Q.WITH_LOSSES)/MAX(Q.WITH_LOSSES),2)*100 AS LOAD_FACTOR,
                 SUM(Q.WITH_LOSSES) AS TOTAL_LOAD,
                 SUM(Q.WITH_LOSSES * IS_ON_PEAK) AS ON_PEAK,
                 SUM(Q.WITH_LOSSES * (-1*(IS_ON_PEAK-1))) AS OFF_PEAK
            FROM (SELECT TRIM(CASE p_INTERVAL
                              WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                              WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                              WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                              WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                              WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                              WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                              WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                              WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS DT,
                  SDT.CUT_DATE,
                  SDT.IS_ON_PEAK,
                  X.EDC_ID,
                  EDC.EDC_NAME,
                  X.PSE_ID,
                  PSE.PSE_NAME,
                  X.ESP_ID,
                  ESP.ESP_NAME,
                  X.POOL_ID,
                  POOL.POOL_NAME,
                  X.LOAD_VAL AS WITHOUT_LOSSES,
                  X.LOAD_VAL +  X.TX_LOSS_VAL + X.DX_LOSS_VAL + X.UFE_LOAD_VAL AS WITH_LOSSES,
                  X.TX_LOSS_VAL,
                  X.DX_LOSS_VAL,
                  X.UFE_LOAD_VAL
                FROM (SELECT CDI.EDC_ID, CDI.PSE_ID, CDI.ESP_ID, CDI.POOL_ID,
                        SOL.LOAD_DATE, SOL.LOAD_VAL, SOL.TX_LOSS_VAL, SOL.DX_LOSS_VAL, SOL.UFE_LOAD_VAL
                      FROM SERVICE_OBLIGATION SO,
                        SERVICE_OBLIGATION_LOAD SOL,
                        PROVIDER_SERVICE PS,
                        SERVICE_DELIVERY SD,
                        CDI_MULTI_ACCOUNT_SELECTION_GT CDI
                      WHERE SO.MODEL_ID = 1
                        AND SO.SCENARIO_ID = v_SCENARIO_ID
                        AND SO.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
                        AND SO.SERVICE_DELIVERY_ID = SD.SERVICE_DELIVERY_ID
                        AND (CDI.EDC_ID = -1 OR CDI.EDC_ID = PS.EDC_ID)
                        AND (CDI.PSE_ID = -1 OR CDI.PSE_ID = PS.PSE_ID)
                        AND (CDI.ESP_ID = -1 OR CDI.ESP_ID = PS.ESP_ID)
                        AND (CDI.POOL_ID = -1 OR CDI.POOL_ID = SD.POOL_ID)
                        AND SOL.SERVICE_OBLIGATION_ID = SO.SERVICE_OBLIGATION_ID
                        AND SOL.LOAD_CODE = GA.STANDARD
                        AND ((SO.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SOL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE)
                          OR (SO.MODEL_ID = CONSTANTS.GAS_MODEL AND SOL.LOAD_DATE BETWEEN v_BEGIN AND v_END))
                        AND SOL.SERVICE_CODE = v_SERVICE_CODE) X,
                  SYSTEM_DATE_TIME SDT,
                  ENERGY_DISTRIBUTION_COMPANY EDC,
                  PURCHASING_SELLING_ENTITY PSE,
                  ENERGY_SERVICE_PROVIDER ESP,
                  POOL
                WHERE SDT.TIME_ZONE = p_TIME_ZONE
                  AND SDT.DAY_TYPE = GA.STANDARD
                  AND 1 IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
                  AND 1 = SDT.DATA_INTERVAL_TYPE
                  AND X.LOAD_DATE = SDT.CUT_DATE
                  AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                        AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
                  AND EDC.EDC_ID (+) = X.EDC_ID
                  AND PSE.PSE_ID (+) = X.PSE_ID
                  AND ESP.ESP_ID (+) = X.ESP_ID
                  AND POOL.POOL_ID (+) = X.POOL_ID) Q
            GROUP BY Q.DT, Q.EDC_ID, Q.EDC_NAME, Q.PSE_ID, Q.PSE_NAME, Q.ESP_ID, Q.ESP_NAME, Q.POOL_ID, Q.POOL_NAME
            ORDER BY 1, 3, 5, 7, 9;

         ELSE
          OPEN p_CURSOR FOR    SELECT NULL FROM DUAL;
        END IF;

    ELSE

      OPEN p_CURSOR FOR
            SELECT L.DT,
                ACCOUNT_ID,
                ACCOUNT_NAME,
                SUM(L.WITH_LOSSES) AS WITH_LOSSES,
                SUM(L.WITHOUT_LOSSES) AS WITHOUT_LOSSES,
                SUM(L.TX_LOSS_VAL) AS TX_LOSS_VAL,
                SUM(L.DX_LOSS_VAL) AS DX_LOSS_VAL,
                SUM(L.UE_LOSS_VAL) AS UE_LOSS_VAL,
                MAX(L.WITH_LOSSES) AS PEAK,
                ROUND(AVG(L.WITH_LOSSES),4) AS AVERAGE,
                ROUND(AVG(L.WITH_LOSSES)/MAX(L.WITH_LOSSES),2)*100 AS LOAD_FACTOR,
                SUM(L.WITH_LOSSES) AS TOTAL_LOAD,
                SUM(L.WITH_LOSSES * IS_ON_PEAK) AS ON_PEAK,
                SUM(L.WITH_LOSSES * (-1*(IS_ON_PEAK-1))) AS OFF_PEAK
            FROM (SELECT TRIM(CASE p_INTERVAL
                                WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                                WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS DT,
                    SDT.CUT_DATE,
                    SDT.IS_ON_PEAK,
                    SERVICE_ID,
                    ACCOUNT_ID,
                    ACCOUNT_NAME,
                    CASE WHEN v_SHOW_W = 1 THEN X.LOAD_VAL+X.TX_LOSS_VAL+X.DX_LOSS_VAL+X.UE_LOSS_VAL ELSE NULL END AS WITH_LOSSES,
                    CASE WHEN v_SHOW_WO = 1 THEN X.LOAD_VAL ELSE NULL END AS WITHOUT_LOSSES,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.TX_LOSS_VAL ELSE NULL END AS TX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.DX_LOSS_VAL ELSE NULL END AS DX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.UE_LOSS_VAL ELSE NULL END AS UE_LOSS_VAL
                FROM (SELECT SL.LOAD_DATE,
                        S.MODEL_ID,
                        ASRV.ACCOUNT_ID,
                        A.ACCOUNT_NAME,
                        ASRV.AGGREGATE_ID,
                        SL.LOAD_VAL,
                        SL.TX_LOSS_VAL,
                        SL.DX_LOSS_VAL,
                        SL.UE_LOSS_VAL,
                        S.SERVICE_ID
                    FROM SERVICE S,
                        ACCOUNT_SERVICE ASRV,
                        SERVICE_LOAD SL,
                        ACCOUNT A,
                        CDI_MULTI_ACCOUNT_SELECTION_GT C
                    WHERE S.MODEL_ID = 1
                        AND S.SCENARIO_ID = v_SCENARIO_ID
                        AND S.AS_OF_DATE = CONSTANTS.LOW_DATE
                        AND ASRV.ACCOUNT_SERVICE_ID = S.ACCOUNT_SERVICE_ID
                        AND ASRV.ACCOUNT_ID = C.ACCOUNT_ID
                        AND (ASRV.AGGREGATE_ID = C.AGGREGATE_ID OR (C.AGGREGATE_ID = 0 AND A.ACCOUNT_MODEL_OPTION = 'Aggregate'))
                        AND SL.SERVICE_ID = S.SERVICE_ID
                        AND SL.SERVICE_CODE = v_SERVICE_CODE
                        AND SL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE
                        AND ASRV.ACCOUNT_ID = A.ACCOUNT_ID
                                                ) X,
                        SYSTEM_DATE_TIME SDT
                    WHERE SDT.TIME_ZONE = p_TIME_ZONE
                        AND SDT.DAY_TYPE = GA.STANDARD
                        AND 1 = SDT.DATA_INTERVAL_TYPE
                        AND X.LOAD_DATE = SDT.CUT_DATE
                        AND SDT.CUT_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE) L
            GROUP BY L.DT, ACCOUNT_ID, L.SERVICE_ID, L.ACCOUNT_NAME
            ORDER BY L.DT, L.ACCOUNT_NAME;

      END IF; -- IF NULL p_ACCOUNT_ID SELECTION
      DELETE FROM CDI_MULTI_ACCOUNT_SELECTION_GT;
      COMMIT;
END GET_MULTI_ACCOUNT_STATS;

END CDI_MULTI_ACCOUNT_REPORTS;
/
