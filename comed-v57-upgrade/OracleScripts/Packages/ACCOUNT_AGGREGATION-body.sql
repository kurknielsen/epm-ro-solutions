CREATE OR REPLACE PACKAGE BODY ACCOUNT_AGGREGATION IS
--------------------------------------------------------------------------------
c_AGGREGATE_ACCOUNT_NAME_SEP CONSTANT VARCHAR2(2) := ':';
--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.2 $';
END WHAT_VERSION;

---------------------------------------------------------------------------------------------------
-- This procedure will delete the current Sub-Aggregate to Aggregate account relationships.
-- Relationships are recreated depending on the present parameters.
--------------------------------------------------------------------------------
PROCEDURE DEL_CURRENT_SUB_AGG_AGGREGATES(
   p_ACCOUNT_IDs IN NUMBER_COLLECTION,
   p_EDC_IDs     IN NUMBER_COLLECTION,
   p_ESP_ID      IN NUMBER,
   p_BEGIN_DATE  IN DATE,
   p_END_DATE    IN DATE) 
AS
  -- WE ADD 1 TO THE p_END_DATE, SO SUBTRACT ONE FOR HIGH_DATE
  v_END_DATE DATE := CASE 
                        WHEN NVL(p_END_DATE,CONSTANTS.HIGH_DATE) = CONSTANTS.HIGH_DATE THEN 
                             CONSTANTS.HIGH_DATE-1 
                        ELSE 
                             p_END_DATE 
                      END;
BEGIN
    LOGS.LOG_DEBUG(p_EVENT_TEXT => 'Get the current Sub-Aggregate to Aggregate relationships');

	DELETE FROM ACCOUNT_SUB_AGG_AGGREGATION ASAA
	WHERE EXISTS (SELECT 1
				   FROM (SELECT COLUMN_VALUE AS ACCOUNT_ID
						   FROM TABLE(CAST(p_ACCOUNT_IDs AS NUMBER_COLLECTION))) X,
					     ACCOUNT A,
					     AGGREGATE_ACCOUNT_ESP AAE,
					     ACCOUNT_EDC AE
				   WHERE X.ACCOUNT_ID IN (A.ACCOUNT_ID, CONSTANTS.ALL_ID)
				     AND A.ACCOUNT_ID = ASAA.ACCOUNT_ID
				     AND A.IS_SUB_AGGREGATE = 1
				     AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.C_ACCT_MODEL_OPTION_ACCOUNT
				     AND ASAA.AGGREGATE_ID = AAE.AGGREGATE_ID
				     AND ASAA.BEGIN_DATE <= v_END_DATE
				     AND NVL(ASAA.END_DATE, v_END_DATE) >= p_BEGIN_DATE 
				     AND AAE.ACCOUNT_ID = AE.ACCOUNT_ID
				     AND AE.EDC_ID IN (SELECT COLUMN_VALUE
										 FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)))
				     AND p_ESP_ID IN (AAE.ESP_ID, CONSTANTS.ALL_ID));

	DELETE FROM METER_SUB_AGG_AGGREGATION MSAA
	WHERE EXISTS (SELECT 1
				   FROM (SELECT COLUMN_VALUE AS ACCOUNT_ID
						   FROM TABLE(CAST(p_ACCOUNT_IDs AS NUMBER_COLLECTION))) X,
					     ACCOUNT A,
					     AGGREGATE_ACCOUNT_ESP AAE,
					     ACCOUNT_EDC AE,
					     ACCOUNT_SERVICE_LOCATION ASL,
					     SERVICE_LOCATION_METER SLM,
					     METER M
				   WHERE X.ACCOUNT_ID IN (A.ACCOUNT_ID, CONSTANTS.ALL_ID)
				     AND A.IS_SUB_AGGREGATE = 1
				     AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.C_ACCT_MODEL_OPTION_METER
				     AND MSAA.AGGREGATE_ID = AAE.AGGREGATE_ID
				     AND MSAA.BEGIN_DATE <= v_END_DATE
				     AND NVL(MSAA.END_DATE, v_END_DATE) >= p_BEGIN_DATE
				     AND AAE.ACCOUNT_ID = AE.ACCOUNT_ID
				     AND AE.EDC_ID IN (SELECT COLUMN_VALUE
										 FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)))
				     AND p_ESP_ID IN (AAE.ESP_ID, CONSTANTS.ALL_ID)
				     AND ASL.ACCOUNT_ID = A.ACCOUNT_ID
				     AND ASL.BEGIN_DATE <= v_END_DATE
				     AND NVL(ASL.END_DATE,v_END_DATE) >= p_BEGIN_DATE
				     AND SLM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
				     AND SLM.BEGIN_DATE <= v_END_DATE
				     AND NVL(SLM.END_DATE,v_END_DATE) >= p_BEGIN_DATE
				     AND M.METER_ID = SLM.METER_ID
				     AND M.METER_TYPE IN (ACCOUNTS_METERS.c_METER_TYPE_INTERVAL,
									      ACCOUNTS_METERS.c_METER_TYPE_PERIOD)
				     AND MSAA.METER_ID = M.METER_ID);

   LOGS.LOG_DEBUG(p_EVENT_TEXT => 'Done.');
END DEL_CURRENT_SUB_AGG_AGGREGATES;
--------------------------------------------------------------------------------
PROCEDURE ENSURE_ACCOUNT_ESP
    (
    p_AGGREGATE_ACCOUNT_ID IN NUMBER,
    p_ESP_ID IN NUMBER,
    p_POOL_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) AS

    v_TEST PLS_INTEGER;

    v_AGG_ID NUMBER(9);

BEGIN

    -- IS THERE AN ASSIGNMENT THAT INCLUDES THE DATE RANGE TOTALLY?
    -- UT.PUT_TEMPORAL_DATA includes this check, but this is intended to
    -- bypass the dynamic sql to speed up this procedure
    SELECT COUNT(1)
    INTO v_TEST
    FROM AGGREGATE_ACCOUNT_ESP AE
    WHERE AE.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID
        AND AE.ESP_ID = p_ESP_ID
        AND AE.POOL_ID = p_POOL_ID
        AND AE.BEGIN_DATE <= p_BEGIN_DATE
        AND NVL(AE.END_DATE,CONSTANTS.HIGH_DATE) >= p_END_DATE;

   IF v_TEST = 0 THEN

        SELECT MAX(AE.AGGREGATE_ID)
        INTO v_AGG_ID
        FROM AGGREGATE_ACCOUNT_ESP AE
        WHERE AE.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID
            AND AE.ESP_ID = p_ESP_ID
            AND AE.POOL_ID = p_POOL_ID;

        IF v_AGG_ID IS NULL THEN
            SELECT OID.NEXTVAL
            INTO v_AGG_ID
            FROM DUAL;
        END IF;


        UT.PUT_TEMPORAL_DATA('AGGREGATE_ACCOUNT_ESP',
                            p_BEGIN_DATE,
                            p_END_DATE,
                            TRUE,
                            TRUE,
                            'ACCOUNT_ID',
                            p_AGGREGATE_ACCOUNT_ID,
                            TRUE,
                            'ESP_ID',
                            p_ESP_ID,
                            TRUE,
                            'POOL_ID',
                            p_POOL_ID,
                            TRUE,
                            'AGGREGATE_ID',
                            v_AGG_ID,
                            FALSE);

   END IF;


END ENSURE_ACCOUNT_ESP;
--------------------------------------------------------------------------------
PROCEDURE ENSURE_SUB_AGG_AGGREGATION
    (
    p_ENTITY_ID IN NUMBER,
    p_ENTITY_TYPE IN VARCHAR2,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_AGG_ACCOUNT_ID IN NUMBER,
    p_ESP_ID IN NUMBER,
    p_POOL_ID IN NUMBER
    ) AS

    v_AGG_ID NUMBER(9);
    v_TEST PLS_INTEGER;

BEGIN

    ASSERT(UPPER(NVL(p_ENTITY_TYPE,'X')) IN ('METER','ACCOUNT'),
        'Entity Type must be Account or Meter.', MSGCODES.c_ERR_ARGUMENT);

    ASSERT(p_AGG_ACCOUNT_ID IS NOT NULL,
        'An aggregate account must be supplied.', MSGCODES.c_ERR_ARGUMENT);

    ASSERT(p_ESP_ID IS NOT NULL,
        'An ESP must be supplied.', MSGCODES.c_ERR_ARGUMENT);

    ASSERT(p_POOL_ID IS NOT NULL,
        'A pool must be supplied.', MSGCODES.c_ERR_ARGUMENT);

    -- FIND A CORRESPONDING AGGREGATE_ACCOUNT_ESP RECORD
    SELECT MIN(AAE.AGGREGATE_ID)
    INTO v_AGG_ID
    FROM AGGREGATE_ACCOUNT_ESP AAE
    WHERE AAE.ACCOUNT_ID = p_AGG_ACCOUNT_ID
        AND AAE.ESP_ID = p_ESP_ID
        AND AAE.POOL_ID = p_POOL_ID
        AND AAE.BEGIN_DATE <= p_BEGIN_DATE
        AND NVL(AAE.END_DATE,HIGH_DATE) >= p_END_DATE;

    IF v_AGG_ID IS NULL THEN
            ERRS.RAISE_BAD_ARGUMENT('BEGIN_DATE->END_DATE: AGG_ACCOUNT/ESP/POOL',
                TEXT_UTIL.TO_CHAR_DATE_RANGE(p_BEGIN_DATE,p_END_DATE) || ':'
                || TEXT_UTIL.TO_CHAR_ENTITY(p_AGG_ACCOUNT_ID,EC.ED_ACCOUNT)
                || '/' || TEXT_UTIL.TO_CHAR_ENTITY(p_ESP_ID,EC.ED_ESP)
                || '/' || TEXT_UTIL.TO_CHAR_ENTITY(p_POOL_ID,EC.ED_POOL),
                'The supplied aggregate account is not assigned to the given esp and pool for the date range '
                || 'specified.');
    END IF;

    IF UPPER(p_ENTITY_TYPE) = 'ACCOUNT' THEN
        -- IS THERE AN ASSIGNMENT THAT INCLUDES THE DATE RANGE TOTALLY?
        -- UT.PUT_TEMPORAL_DATA includes this check, but this is intended to
        -- bypass the dynamic sql to speed up this procedure
        SELECT COUNT(1)
        INTO v_TEST
        FROM ACCOUNT_SUB_AGG_AGGREGATION A
        WHERE A.ACCOUNT_ID = p_ENTITY_ID
            AND A.AGGREGATE_ID = v_AGG_ID
            AND A.BEGIN_DATE <= p_BEGIN_DATE
            AND NVL(A.END_DATE,CONSTANTS.HIGH_DATE) >= p_END_DATE;
            
        IF v_TEST = 0 THEN
            UT.PUT_TEMPORAL_DATA('ACCOUNT_SUB_AGG_AGGREGATION',
                            p_BEGIN_DATE,
                            p_END_DATE,
                            TRUE,
                            TRUE,
                            'ACCOUNT_ID',
                            p_ENTITY_ID,
                            TRUE,
                            'AGGREGATE_ID',
                            v_AGG_ID,
                            FALSE);
        END IF;
    ELSE
        -- IS THERE AN ASSIGNMENT THAT INCLUDES THE DATE RANGE TOTALLY?
        -- UT.PUT_TEMPORAL_DATA includes this check, but this is intended to
        -- bypass the dynamic sql to speed up this procedure
        SELECT COUNT(1)
        INTO v_TEST
        FROM METER_SUB_AGG_AGGREGATION M
        WHERE M.METER_ID = p_ENTITY_ID
            AND M.AGGREGATE_ID = v_AGG_ID
            AND M.BEGIN_DATE <= p_BEGIN_DATE
            AND NVL(M.END_DATE,CONSTANTS.HIGH_DATE) >= p_END_DATE;
                            
        IF v_TEST = 0 THEN
            UT.PUT_TEMPORAL_DATA('METER_SUB_AGG_AGGREGATION',
                            p_BEGIN_DATE,
                            p_END_DATE,
                            TRUE,
                            TRUE,
                            'METER_ID',
                            p_ENTITY_ID,
                            TRUE,
                            'AGGREGATE_ID',
                            v_AGG_ID,
                            FALSE);
        END IF;
    END IF;

END ENSURE_SUB_AGG_AGGREGATION;
--------------------------------------------------------------------------------
PROCEDURE RUN_AGGREGATION_IMPL
    (
    p_ACCOUNT_IDs IN NUMBER_COLLECTION,
    p_EDC_IDs IN NUMBER_COLLECTION,
    p_ESP_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_RESET_DATES IN NUMBER,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_ACCT_AGG_ATT_ID NUMBER(9);

    v_TARGET_PARAMS UT.STRING_MAP;

    v_ACCOUNT_ID NUMBER(9);

    -- HIGH DATE MINUS ONE USED IN THE QUERY WHERE WE ADD 1 TO THE END DATE TO MAKE SURE
    -- WE DON'T ACCIDENTALLY GO OUT OF THE VALID DATE RANGE
    v_HD_MINUS_ONE DATE := HIGH_DATE - 1;

    v_METER_IDS NUMBER_COLLECTION;
    v_METER_ID NUMBER(9);

    -- WE ADD 1 TO THE p_END_DATE, SO SUBTRACT ONE FOR HIGH_DATE
    v_END_DATE DATE := CASE WHEN NVL(p_END_DATE,CONSTANTS.HIGH_DATE) = CONSTANTS.HIGH_DATE THEN CONSTANTS.HIGH_DATE-1 ELSE p_END_DATE END;

    v_TEST PLS_INTEGER;
  v_NUM_ACCOUNTS NUMBER(9) := 0;
  v_ACCOUNT_INDEX NUMBER(9) := 1;

  v_ACCOUNT_IDS NUMBER_COLLECTION := p_ACCOUNT_IDS;
BEGIN

    ASSERT(p_ACCOUNT_IDs IS NOT NULL AND p_ACCOUNT_IDs.COUNT > 0, 'At least one Account must be specified to RUN_AGGREGATION', MSGCODES.c_ERR_ARGUMENT);

    SELECT COUNT(1)
    INTO v_TEST
    FROM TABLE(CAST(p_ACCOUNT_IDs AS NUMBER_COLLECTION)) X
    WHERE X.COLUMN_VALUE = CONSTANTS.ALL_ID;

    IF v_TEST > 0 AND p_ACCOUNT_IDs.COUNT > 1 THEN
        ERRS.RAISE_BAD_ARGUMENT('ACCOUNT_IDS',TEXT_UTIL.TO_CHAR_ENTITY_LIST(p_ACCOUNT_IDs,EC.ED_ACCOUNT),
            'The Account ID list cannot have any other items if it contains the "All" ID (' || CONSTANTS.ALL_ID || ').');
    END IF;

    SAVEPOINT BEFORE_AGGREGATION;
    LOGS.START_PROCESS('Account Aggregation', p_BEGIN_DATE, v_END_DATE, p_TRACE_ON => p_TRACE_ON);

    LOGS.SET_PROCESS_TARGET_PARAMETER('EDCs',TEXT_UTIL.TO_CHAR_ENTITY_LIST(p_EDC_IDs, EC.ED_EDC));
    LOGS.SET_PROCESS_TARGET_PARAMETER('ESP',CASE WHEN p_ESP_ID = CONSTANTS.ALL_ID THEN 'All' ELSE TEXT_UTIL.TO_CHAR_ENTITY(p_ESP_ID, EC.ED_ESP) END);
    LOGS.SET_PROCESS_TARGET_PARAMETER('RESET_DATES',p_RESET_DATES);

    ID.ID_FOR_ENTITY_ATTRIBUTE(ACCOUNTS_METERS.c_AGGREGATION_GROUP_ENT_ATTR, EC.ED_ACCOUNT, 'String', FALSE, v_ACCT_AGG_ATT_ID);

  IF p_ACCOUNT_IDs.COUNT = 1 AND p_ACCOUNT_IDs(1) = CONSTANTS.ALL_ID THEN
    -- All Accounts, need to fetch the number of accounts for progress tracking
    SELECT COUNT(DISTINCT A.ACCOUNT_NAME)
    INTO v_NUM_ACCOUNTS
    FROM ACCOUNT A,
      ACCOUNT_EDC EDC,
      ACCOUNT_ESP ESP,
      ACCOUNT_STATUS S,
      ACCOUNT_STATUS_NAME ASN
    WHERE A.ACCOUNT_MODEL_OPTION IN (ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER,
                     ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT)
      AND A.IS_SUB_AGGREGATE = 1
      AND A.MODEL_ID IS NOT NULL AND A.MODEL_ID IN (GA.GAS_MODEL, GA.ELECTRIC_MODEL)
      AND EDC.ACCOUNT_ID = A.ACCOUNT_ID
      AND EDC.EDC_ID IN (SELECT COLUMN_VALUE FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)))
      AND ESP.ACCOUNT_ID = A.ACCOUNT_ID
      AND p_ESP_ID IN (ESP.ESP_ID, CONSTANTS.ALL_ID)
      AND S.ACCOUNT_ID = A.ACCOUNT_ID
      AND ASN.STATUS_NAME = S.STATUS_NAME
      AND ASN.IS_ACTIVE = 1
      AND GREATEST(EDC.BEGIN_DATE,ESP.BEGIN_DATE,p_BEGIN_DATE,S.BEGIN_DATE)
       <= LEAST(NVL(EDC.END_DATE,v_END_DATE),NVL(ESP.END_DATE,v_END_DATE),
          NVL(S.END_DATE,v_END_DATE),v_END_DATE);
  ELSE
    v_ACCOUNT_IDs  := SET (p_ACCOUNT_IDs); -- get the unique ACCOUNT_IDs
      v_NUM_ACCOUNTS := v_ACCOUNT_IDs.COUNT;
  END IF;

  LOGS.INIT_PROCESS_PROGRESS(p_TOTAL_WORK => v_NUM_ACCOUNTS);
 
  -- Pre-process call to delete current Sub-Aggregate to Aggregate relationships.
  -- Relationships are recreated depending on the present parameters.  
  DEL_CURRENT_SUB_AGG_AGGREGATES(v_ACCOUNT_IDs,
                                 p_EDC_IDs,
                                 p_ESP_ID,
                                 p_BEGIN_DATE,
                                 p_END_DATE);

  FOR v_ACCT_REC IN (
                    $IF $$UNIT_TEST_MODE=1 $THEN
                        SELECT ACCOUNT_ID, ACCOUNT_MODEL_OPTION FROM(
                    $END
                        SELECT DISTINCT A.ACCOUNT_ID, A.ACCOUNT_MODEL_OPTION, A.ACCOUNT_NAME
                        FROM ACCOUNT A,
                            TABLE(CAST(p_ACCOUNT_IDs AS NUMBER_COLLECTION)) X,
                            ACCOUNT_EDC EDC,
                            ACCOUNT_ESP ESP,
                            ACCOUNT_STATUS S,
                            ACCOUNT_STATUS_NAME ASN
                        WHERE X.COLUMN_VALUE IN (A.ACCOUNT_ID, CONSTANTS.ALL_ID)
                            AND A.ACCOUNT_MODEL_OPTION IN (ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER,
                                                            ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT)
                            AND A.IS_SUB_AGGREGATE = 1
                            AND A.MODEL_ID IS NOT NULL AND A.MODEL_ID IN (GA.GAS_MODEL, GA.ELECTRIC_MODEL)
                            AND EDC.ACCOUNT_ID = A.ACCOUNT_ID
                            AND EDC.EDC_ID IN (SELECT COLUMN_VALUE FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)))
                            AND ESP.ACCOUNT_ID = A.ACCOUNT_ID
                            AND p_ESP_ID IN (ESP.ESP_ID, CONSTANTS.ALL_ID)
                            AND S.ACCOUNT_ID = A.ACCOUNT_ID
                            AND ASN.STATUS_NAME = S.STATUS_NAME
                            AND ASN.IS_ACTIVE = 1

                            AND GREATEST(EDC.BEGIN_DATE,ESP.BEGIN_DATE,p_BEGIN_DATE,S.BEGIN_DATE)
                             <= LEAST(NVL(EDC.END_DATE,v_END_DATE),NVL(ESP.END_DATE,v_END_DATE),
                                    NVL(S.END_DATE,v_END_DATE),v_END_DATE)
                        $IF $$UNIT_TEST_MODE=1 $THEN
                            ) ORDER BY ACCOUNT_NAME
                        $END
                        ) LOOP

    LOGS.UPDATE_PROCESS_PROGRESS(NULL, p_PROGRESS_DESCRIPTION => 'Processing Account ' || v_ACCOUNT_INDEX || ' of ' || v_NUM_ACCOUNTS || ': ' || EI.GET_ENTITY_IDENTIFIER(EC.ED_ACCOUNT, v_ACCT_REC.ACCOUNT_ID, 1));

        -- TO SIMPLIFY THE QUERIES (AS MUCH AS IS POSSIBLE) WE HAVE SEPERATE LOOPS FOR THE ACCOUNT MODELED AND METER MODELED ACCOUNTS
        FOR v_REC IN (WITH ALF AS
                        /* ALL OPTIONAL SUB TABLES NEED TO USE THIS COMPLICATED SUBQUERY TO ENSURE THAT WE HAVE PHANTOM
                           NULL ROWS WHICH REPRESENT WHERE THIS ACCOUNT DOES NOT HAVE AN OPTION SPECIFIED, THEY HAVE TO BE
                           OUTER-JOINED TO ACCOUNT TO ENSURE THAT EACH ACCOUNT HAS AT LEAST ONE OPTIONAL SUB-TABLE ROW
                           (WHERE THAT ROW WILL BE p_BEGIN_DATE, v_END_DATE, NULL (FOR WHATEVER OPTIONAL COLUMNS) */
                        (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)  /* SWITCH = -1, FIRST OF THE SET OF 3,
                                                                                                        LAG GETS THE PREVIOUS ROW'S END DATE + 1,
                                                                                                        I.E. THE START OF THE 'NO ASSIGNMENT' ROW
                                                                                                        PRIOR TO THIS ASSIGNMENT ROW */
                                                    OVER (PARTITION BY LF.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                WHEN C.SWTCH = 0 THEN BEGIN_DATE  /* SWITCH = 0, THE ACTUAL ASSIGNMENT ROW */
                                ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE, /* SWITCH = 1, THE 'NO ASSIGNMENT' ROW AFTER
                                                                                                    THIS ASSIGNMENT, WHICH BEGINS AFTER THE END OF THIS
                                                                                                    ASSIGNMENT */
                           NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1 /* SWITCH = -1, NO ASSIGMENT PRIOR TO THIS ASSIGNMENT, WHICH ENDS THE DAY
                                                                            BEFORE THIS ASSIGNMENT STARTS */
                                WHEN C.SWTCH = 0 THEN END_DATE /* THIS ASSIGNMENT */
                                ELSE LEAD(BEGIN_DATE-1, 1, NULL)  /* SWITCH = 1, 'NO ASSIGNMENT' AFTER THIS ASSIGNMENT, WHICH ENDS THE DAY BEFORE
                                                                    THE NEXT ASSIGNMENT STARTS */
                                                    OVER (PARTITION BY LF.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                END), v_END_DATE) AS END_DATE,
                          A.ACCOUNT_ID,
                          (CASE WHEN C.SWTCH = 0 THEN LF.LOSS_FACTOR_ID ELSE NULL END) AS LOSS_FACTOR_ID
                        FROM ACCOUNT A, ACCOUNT_LOSS_FACTOR LF, (SELECT -1 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                        WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                            AND A.ACCOUNT_ID = LF.ACCOUNT_ID (+)
                            AND LF.CASE_ID (+) = GA.BASE_CASE_ID
                            AND LF.BEGIN_DATE (+) <= v_END_DATE
                            AND NVL(LF.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                        /* ACCOUNT SCHEDULE GROUP */
                        ASG AS
                        (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                    OVER (PARTITION BY SG.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                           NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                WHEN C.SWTCH = 0 THEN END_DATE
                                ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                    OVER (PARTITION BY SG.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                END), v_END_DATE) AS END_DATE,
                          A.ACCOUNT_ID,
                          (CASE WHEN C.SWTCH = 0 THEN SG.SCHEDULE_GROUP_ID ELSE NULL END) AS SCHEDULE_GROUP_ID
                        FROM ACCOUNT A, ACCOUNT_SCHEDULE_GROUP SG, (SELECT -1 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                        WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                            AND A.ACCOUNT_ID = SG.ACCOUNT_ID (+)
                            AND SG.BEGIN_DATE (+) <= v_END_DATE
                            AND NVL(SG.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                       /* ACCOUNT PRODUCT - REVENUE */
                       ARP AS
                       (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                    OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                           NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                WHEN C.SWTCH = 0 THEN END_DATE
                                ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                    OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                END), v_END_DATE) AS END_DATE,
                          A.ACCOUNT_ID,
                          (CASE WHEN C.SWTCH = 0 THEN AP.PRODUCT_ID ELSE NULL END) AS REVENUE_PRODUCT_ID
                        FROM ACCOUNT A, ACCOUNT_PRODUCT AP, (SELECT -1 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                        WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                            AND A.ACCOUNT_ID = AP.ACCOUNT_ID (+)
                            AND AP.BEGIN_DATE (+) <= v_END_DATE
                            AND NVL(AP.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE
                            AND UPPER(AP.PRODUCT_TYPE (+)) = 'R'
                            AND AP.CASE_ID (+) = GA.BASE_CASE_ID),


                       /* ACCOUNT PRODUCT - COST */
                       ACP AS
                       (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                    OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                           NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                WHEN C.SWTCH = 0 THEN END_DATE
                                ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                    OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                END), v_END_DATE) AS END_DATE,
                          A.ACCOUNT_ID,
                          (CASE WHEN C.SWTCH = 0 THEN AP.PRODUCT_ID ELSE NULL END) AS COST_PRODUCT_ID
                        FROM ACCOUNT A, ACCOUNT_PRODUCT AP, (SELECT -1 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                        WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                            AND A.ACCOUNT_ID = AP.ACCOUNT_ID (+)
                            AND AP.BEGIN_DATE (+) <= v_END_DATE
                            AND NVL(AP.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE
                            AND UPPER(AP.PRODUCT_TYPE (+)) = 'C'
                            AND AP.CASE_ID (+) = GA.BASE_CASE_ID),


                       /* ACCOUNT BILL CYCLE */
                       ABC AS
                       (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                    OVER (PARTITION BY BC.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                           NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                WHEN C.SWTCH = 0 THEN END_DATE
                                ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                    OVER (PARTITION BY BC.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                END), v_END_DATE) AS END_DATE,
                          A.ACCOUNT_ID,
                          (CASE WHEN C.SWTCH = 0 THEN BC.BILL_CYCLE_ID ELSE NULL END) AS BILL_CYCLE_ID
                        FROM ACCOUNT A, ACCOUNT_BILL_CYCLE BC, (SELECT -1 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                        WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                            AND A.ACCOUNT_ID = BC.ACCOUNT_ID (+)
                            AND BC.BEGIN_DATE (+) <= v_END_DATE
                            AND NVL(BC.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                       /* TEMPORAL ENTITY ATTRIBUTE - AGGREGATION GROUP */
                       AAG AS
                       (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                    OVER (PARTITION BY A.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                           NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                WHEN C.SWTCH = 0 THEN END_DATE
                                ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                    OVER (PARTITION BY A.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                END), v_END_DATE) AS END_DATE,
                          A.ACCOUNT_ID,
                          (CASE WHEN C.SWTCH = 0 THEN TEA.ATTRIBUTE_VAL ELSE NULL END) AS AGGREGATION_GROUP
                        FROM ACCOUNT A, TEMPORAL_ENTITY_ATTRIBUTE TEA, (SELECT -1 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                        WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                            AND A.ACCOUNT_ID = TEA.OWNER_ENTITY_ID (+)
                            AND TEA.ATTRIBUTE_ID (+) = v_ACCT_AGG_ATT_ID
                            AND TEA.ENTITY_DOMAIN_ID (+) = EC.ED_ACCOUNT
                            AND TEA.BEGIN_DATE (+) <= v_END_DATE
                            AND NVL(TEA.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                       /* ACCOUNT TOU USAGE FACTOR */
                       ATOU AS
                       (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                    OVER (PARTITION BY TUF.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                           NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                WHEN C.SWTCH = 0 THEN END_DATE
                                ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                    OVER (PARTITION BY TUF.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                END), v_END_DATE) AS END_DATE,
                          A.ACCOUNT_ID,
                          (CASE WHEN C.SWTCH = 0 THEN TUF.TEMPLATE_ID ELSE NULL END) AS TEMPLATE_ID
                        FROM ACCOUNT A, ACCOUNT_TOU_USAGE_FACTOR TUF, (SELECT -1 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                        UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                        WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                            AND A.ACCOUNT_ID = TUF.ACCOUNT_ID (+)
                            AND TUF.BEGIN_DATE (+) <= v_END_DATE
                            AND NVL(TUF.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE)


                      SELECT A.ACCOUNT_ID,
                            EDC.EDC_ID,
                            EDC.EDC_RATE_CLASS,
                            EDC.EDC_STRATA,
                            ESP.ESP_ID,
                            ESP.POOL_ID,
                            CAL.CALENDAR_ID,
                            UPPER(SUBSTR(A.ACCOUNT_METER_TYPE,1,1)) AS ACCOUNT_METER_TYPE,
                            A.MODEL_ID,
                            NVL(ALF.LOSS_FACTOR_ID, CONSTANTS.NOT_ASSIGNED) AS LOSS_FACTOR_ID,
                            NVL(CASE WHEN NVL(SP.SERVICE_POINT_ID,CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED
                                    THEN SL.SERVICE_ZONE_ID
                                    ELSE SP.SERVICE_ZONE_ID END,CONSTANTS.NOT_ASSIGNED) AS SERVICE_ZONE_ID,
                            NVL(SL.SERVICE_POINT_ID,CONSTANTS.NOT_ASSIGNED) AS SERVICE_POINT_ID,
                            NVL(SL.WEATHER_STATION_ID,CONSTANTS.NOT_ASSIGNED) AS WEATHER_STATION_ID,
                            NVL(ASG.SCHEDULE_GROUP_ID,CONSTANTS.NOT_ASSIGNED) AS SCHEDULE_GROUP_ID,
                            NVL(ARP.REVENUE_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED) AS REVENUE_PRODUCT_ID,
                            NVL(ACP.COST_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED) AS COST_PRODUCT_ID,
                            NVL(ABC.BILL_CYCLE_ID,CONSTANTS.NOT_ASSIGNED) AS BILL_CYCLE_ID,
                            NVL(ATOU.TEMPLATE_ID,CONSTANTS.NOT_ASSIGNED) AS TOU_TEMPLATE_ID,
                            AAG.AGGREGATION_GROUP,

                            GREATEST(EDC.BEGIN_DATE,CAL.BEGIN_DATE,ALF.BEGIN_DATE,AST.BEGIN_DATE,ASL.BEGIN_DATE,
                                     ASG.BEGIN_DATE,ARP.BEGIN_DATE,ABC.BEGIN_DATE,ACP.BEGIN_DATE,
                                     AAG.BEGIN_DATE,ATOU.BEGIN_DATE,ESP.BEGIN_DATE,p_BEGIN_DATE) AS BEGIN_DATE,

                            LEAST(NVL(EDC.END_DATE,v_END_DATE),NVL(CAL.END_DATE,v_END_DATE),ALF.END_DATE,
                                    NVL(AST.END_DATE,v_END_DATE),NVL(ASL.END_DATE,v_END_DATE),ASG.END_DATE,
                                    ARP.END_DATE,ABC.END_DATE,ACP.END_DATE,AAG.END_DATE,ATOU.END_DATE,
                                    NVL(ESP.END_DATE,v_END_DATE)) AS END_DATE
                      FROM ACCOUNT A,
                            ACCOUNT_EDC EDC,
                            ACCOUNT_CALENDAR CAL,
                            ACCOUNT_ESP ESP,
                            ALF,
                            ACCOUNT_STATUS AST,
                            ACCOUNT_STATUS_NAME STAT,
                            ACCOUNT_SERVICE_LOCATION ASL,
                            SERVICE_LOCATION SL,
                            SERVICE_POINT SP,
                            ASG,
                            ARP,
                            ABC,
                            ACP,
                            AAG,
                            ATOU
                      WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                        AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT
                        AND A.ACCOUNT_METER_TYPE IN (ACCOUNTS_METERS.c_METER_TYPE_INTERVAL, ACCOUNTS_METERS.c_METER_TYPE_PERIOD)
                        AND EDC.ACCOUNT_ID = A.ACCOUNT_ID
                        AND EDC.EDC_ID IN (SELECT X.COLUMN_VALUE FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)) X)
                        AND ESP.ACCOUNT_ID = A.ACCOUNT_ID
                        AND p_ESP_ID IN (CONSTANTS.ALL_ID, ESP.ESP_ID)
                        AND CAL.ACCOUNT_ID = A.ACCOUNT_ID
                        AND CAL.CALENDAR_TYPE = 'Forecast'
                        AND CAL.CASE_ID = GA.BASE_CASE_ID
                        AND ALF.ACCOUNT_ID = A.ACCOUNT_ID
                        AND AST.ACCOUNT_ID = A.ACCOUNT_ID
                        AND STAT.STATUS_NAME = AST.STATUS_NAME
                        AND STAT.IS_ACTIVE = 1
                        AND ASL.ACCOUNT_ID = A.ACCOUNT_ID
                        AND SL.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
                        AND SP.SERVICE_POINT_ID (+) = SL.SERVICE_POINT_ID
                        AND ASG.ACCOUNT_ID = A.ACCOUNT_ID
                        AND ARP.ACCOUNT_ID = A.ACCOUNT_ID
                        AND ABC.ACCOUNT_ID = A.ACCOUNT_ID
                        AND ACP.ACCOUNT_ID = A.ACCOUNT_ID
                        AND AAG.ACCOUNT_ID = A.ACCOUNT_ID
                        AND ATOU.ACCOUNT_ID = A.ACCOUNT_ID
                        /* Since all of these sub-tablse together determine an Account's assignment, we have to include
                        * all sub tables' date range in the query */
                        AND GREATEST(EDC.BEGIN_DATE,CAL.BEGIN_DATE,ALF.BEGIN_DATE,AST.BEGIN_DATE,ASL.BEGIN_DATE,
                                     ASG.BEGIN_DATE,ARP.BEGIN_DATE,ABC.BEGIN_DATE,ACP.BEGIN_DATE,
                                     AAG.BEGIN_DATE,ATOU.BEGIN_DATE,ESP.BEGIN_DATE,p_BEGIN_DATE) <=
                           LEAST(NVL(EDC.END_DATE,v_END_DATE),NVL(CAL.END_DATE,v_END_DATE),ALF.END_DATE,
                                    NVL(AST.END_DATE,v_END_DATE),NVL(ASL.END_DATE,v_END_DATE),ASG.END_DATE,
                                    ARP.END_DATE,ABC.END_DATE,ACP.END_DATE,AAG.END_DATE,ATOU.END_DATE,
                                    NVL(ESP.END_DATE,v_END_DATE),v_END_DATE)) LOOP

            LOGS.LOG_DEBUG('For date range ' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_REC.BEGIN_DATE,v_REC.END_DATE) || ', ' ||
                                'ACCOUNT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCT_REC.ACCOUNT_ID, EC.ED_ACCOUNT) || ', ' ||
                                'EDC: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.EDC_ID, EC.ED_EDC) || ', ' ||
                                'EDC STRATA: ' || v_REC.EDC_STRATA || ', ' ||
                                'EDC RATE CLASS: ' || v_REC.EDC_RATE_CLASS || ', ' ||
                                'CALENDAR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.CALENDAR_ID, EC.ED_CALENDAR) || ', ' ||
                                'METER TYPE: ' || v_REC.ACCOUNT_METER_TYPE || ', ' ||
                                'MODEL: ' || CASE WHEN v_REC.MODEL_ID = GA.GAS_MODEL THEN 'Gas' ELSE 'Electric' END || ', ' ||
                                'LOSS FACTOR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.LOSS_FACTOR_ID, EC.ED_LOSS_FACTOR) || ', ' ||
                                'SERVICE ZONE: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SERVICE_ZONE_ID, EC.ED_SERVICE_ZONE) || ', ' ||
                                'SERVICE POINT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SERVICE_POINT_ID, EC.ED_SERVICE_POINT) || ', ' ||
                                'WEATHER STATION: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.WEATHER_STATION_ID, EC.ED_WEATHER_STATION) || ', ' ||
                                'SCHEDULE GROUP: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SCHEDULE_GROUP_ID, EC.ED_SCHEDULE_GROUP) || ', ' ||
                                'REVENUE PRODUCT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.REVENUE_PRODUCT_ID, EC.ED_PRODUCT) || ', ' ||
                                'COST PRODUCT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.COST_PRODUCT_ID, EC.ED_PRODUCT) || ', ' ||
                                'BILL CYCLE: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.BILL_CYCLE_ID, EC.ED_BILL_CYCLE) || ', ' ||
                                'TEMPLATE: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.TOU_TEMPLATE_ID, EC.ED_TEMPLATE) || ', ' ||
                                'AGGREGATION GROUP: ' || v_REC.AGGREGATION_GROUP);

           v_ACCOUNT_ID := ENSURE_AGGREGATE_ACCOUNT(v_REC.EDC_ID,
                                                    v_REC.CALENDAR_ID,
                                                    v_REC.ACCOUNT_METER_TYPE,
                                                    v_REC.MODEL_ID,
                                                    v_REC.SERVICE_POINT_ID,
                                                    v_REC.SERVICE_ZONE_ID,
                                                    v_REC.SCHEDULE_GROUP_ID,
                                                    v_REC.WEATHER_STATION_ID,
                                                    v_REC.LOSS_FACTOR_ID,
                                                    v_REC.REVENUE_PRODUCT_ID,
                                                    v_REC.COST_PRODUCT_ID,
                                                    v_REC.TOU_TEMPLATE_ID,
                                                    v_REC.BILL_CYCLE_ID,
                                                    v_REC.EDC_RATE_CLASS,
                                                    v_REC.EDC_STRATA,
                                                    v_REC.AGGREGATION_GROUP,
                                                    p_RESET_DATES);


            -- MAKE SURE THE AGGREGATE ACCOUNT IS ASSIGNED TO THAT ESP FOR THE DATE RANGE
            ENSURE_ACCOUNT_ESP(v_ACCOUNT_ID,v_REC.ESP_ID,v_REC.POOL_ID,v_REC.BEGIN_DATE,v_REC.END_DATE);
            ENSURE_SUB_AGG_AGGREGATION(v_ACCT_REC.ACCOUNT_ID,ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT,v_REC.BEGIN_DATE,v_REC.END_DATE,v_ACCOUNT_ID,
                                        v_REC.ESP_ID,v_REC.POOL_ID);

            LOGS.LOG_DEBUG('Account for static data: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT));

        END LOOP;


        IF v_ACCT_REC.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER THEN

            SELECT DISTINCT M.METER_ID
            BULK COLLECT INTO v_METER_IDS
            FROM ACCOUNT A,
                ACCOUNT_SERVICE_LOCATION ASL,
                SERVICE_LOCATION_METER SLM,
                METER M
            WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER
                AND ASL.ACCOUNT_ID = A.ACCOUNT_ID
                AND ASL.BEGIN_DATE < v_END_DATE
                AND NVL(ASL.END_DATE,CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                AND SLM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
                AND SLM.BEGIN_DATE < v_END_DATE
                AND NVL(SLM.END_DATE,CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                AND M.METER_ID = SLM.METER_ID
                AND M.METER_TYPE IN (ACCOUNTS_METERS.c_METER_TYPE_INTERVAL, ACCOUNTS_METERS.c_METER_TYPE_PERIOD);

        END IF;

        IF v_ACCT_REC.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER
            AND v_METER_IDS IS NOT NULL AND v_METER_IDS.COUNT > 0 THEN

            FOR v_MTR_IDX IN v_METER_IDS.FIRST..v_METER_IDS.LAST LOOP
                v_METER_ID := v_METER_IDS(v_MTR_IDX);
                -- NOW METER-MODELED ACCOUNTS
                FOR v_REC IN (WITH MLF AS
                                /* ALL OPTIONAL SUB TABLES NEED TO USE THIS COMPLICATED SUBQUERY TO ENSURE THAT WE HAVE PHANTOM
                                   NULL ROWS WHICH REPRESENT WHERE THIS ACCOUNT DOES NOT HAVE AN OPTION SPECIFIED, THEY HAVE TO BE
                                   OUTER-JOINED TO ACCOUNT TO ENSURE THAT EACH ACCOUNT HAS AT LEAST ONE OPTIONAL SUB-TABLE ROW
                                   (WHERE THAT ROW WILL BE p_BEGIN_DATE, HIGH_DATE, NULL (FOR WHATEVER OPTIONAL COLUMNS) */
                                (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                            OVER (PARTITION BY LF.METER_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                        ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                                   NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                        WHEN C.SWTCH = 0 THEN END_DATE
                                        ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                            OVER (PARTITION BY LF.METER_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        END), v_END_DATE) AS END_DATE,
                                  M.METER_ID,
                                  (CASE WHEN C.SWTCH = 0 THEN LF.LOSS_FACTOR_ID ELSE NULL END) AS LOSS_FACTOR_ID
                                FROM METER M, METER_LOSS_FACTOR LF, (SELECT -1 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                                WHERE M.METER_ID = v_METER_ID
                                    AND M.METER_ID = LF.METER_ID (+)
                                    AND LF.CASE_ID (+) = GA.BASE_CASE_ID
                                    AND LF.BEGIN_DATE (+) <= v_END_DATE
                                    AND NVL(LF.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                                /* METER SCHEDULE GROUP */
                                MSG AS
                                (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                            OVER (PARTITION BY SG.METER_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                        ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                                   NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                        WHEN C.SWTCH = 0 THEN END_DATE
                                        ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                            OVER (PARTITION BY SG.METER_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        END), v_END_DATE) AS END_DATE,
                                  M.METER_ID,
                                  (CASE WHEN C.SWTCH = 0 THEN SG.SCHEDULE_GROUP_ID ELSE NULL END) AS SCHEDULE_GROUP_ID
                                FROM METER M, METER_SCHEDULE_GROUP SG, (SELECT -1 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                                WHERE M.METER_ID = v_METER_ID
                                    AND M.METER_ID = SG.METER_ID (+)
                                    AND SG.BEGIN_DATE (+) <= v_END_DATE
                                    AND NVL(SG.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                                /* ACCOUNT PRODUCT - REVENUE */
                               ARP AS
                               (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                            OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                        ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                                   NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                        WHEN C.SWTCH = 0 THEN END_DATE
                                        ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                            OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        END), v_END_DATE) AS END_DATE,
                                  A.ACCOUNT_ID,
                                  (CASE WHEN C.SWTCH = 0 THEN AP.PRODUCT_ID ELSE NULL END) AS REVENUE_PRODUCT_ID
                                FROM ACCOUNT A, ACCOUNT_PRODUCT AP, (SELECT -1 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                                WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                                    AND A.ACCOUNT_ID = AP.ACCOUNT_ID (+)
                                    AND AP.BEGIN_DATE (+) <= v_END_DATE
                                    AND NVL(AP.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE
                                    AND UPPER(AP.PRODUCT_TYPE (+)) = 'R'
                                    AND AP.CASE_ID (+) = GA.BASE_CASE_ID),

                               /* ACCOUNT PRODUCT - REVENUE */
                               ACP AS
                               (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                            OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                        ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                                   NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                        WHEN C.SWTCH = 0 THEN END_DATE
                                        ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                            OVER (PARTITION BY AP.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        END), v_END_DATE) AS END_DATE,
                                  A.ACCOUNT_ID,
                                  (CASE WHEN C.SWTCH = 0 THEN AP.PRODUCT_ID ELSE NULL END) AS COST_PRODUCT_ID
                                FROM ACCOUNT A, ACCOUNT_PRODUCT AP, (SELECT -1 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                                WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                                    AND A.ACCOUNT_ID = AP.ACCOUNT_ID (+)
                                    AND AP.BEGIN_DATE (+) <= v_END_DATE
                                    AND NVL(AP.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE
                                    AND UPPER(AP.PRODUCT_TYPE (+)) = 'C'
                                    AND AP.CASE_ID (+) = GA.BASE_CASE_ID),


                               /* ACCOUNT BILL CYCLE*/
                               ABC AS
                               (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                            OVER (PARTITION BY BC.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                        ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                                   NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                        WHEN C.SWTCH = 0 THEN END_DATE
                                        ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                            OVER (PARTITION BY BC.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        END), v_END_DATE) AS END_DATE,
                                  A.ACCOUNT_ID,
                                  (CASE WHEN C.SWTCH = 0 THEN BC.BILL_CYCLE_ID ELSE NULL END) AS BILL_CYCLE_ID
                                FROM ACCOUNT A, ACCOUNT_BILL_CYCLE BC, (SELECT -1 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                                WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                                    AND A.ACCOUNT_ID = BC.ACCOUNT_ID (+)
                                    AND BC.BEGIN_DATE (+) <= v_END_DATE
                                    AND NVL(BC.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                               /* TEMPORAL ENTITY ATTRIBUTE -- AGGREGATION GROUP */
                               AAG AS
                               (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                            OVER (PARTITION BY A.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                        ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                                   NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                        WHEN C.SWTCH = 0 THEN END_DATE
                                        ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                            OVER (PARTITION BY A.ACCOUNT_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        END), v_END_DATE) AS END_DATE,
                                  A.ACCOUNT_ID,
                                  (CASE WHEN C.SWTCH = 0 THEN TEA.ATTRIBUTE_VAL ELSE NULL END) AS AGGREGATION_GROUP
                                FROM ACCOUNT A, TEMPORAL_ENTITY_ATTRIBUTE TEA, (SELECT -1 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                                WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                                    AND A.ACCOUNT_ID = TEA.OWNER_ENTITY_ID (+)
                                    AND TEA.ATTRIBUTE_ID (+) = v_ACCT_AGG_ATT_ID
                                    AND TEA.ENTITY_DOMAIN_ID (+) = EC.ED_ACCOUNT
                                    AND TEA.BEGIN_DATE (+) <= v_END_DATE
                                    AND NVL(TEA.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE),


                               MTOU AS
                               (SELECT DISTINCT NVL((CASE WHEN C.SWTCH = -1 THEN LAG(END_DATE+1, 1, NULL)
                                                            OVER (PARTITION BY TUF.METER_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        WHEN C.SWTCH = 0 THEN BEGIN_DATE
                                        ELSE NVL(LEAST(END_DATE,v_HD_MINUS_ONE),v_END_DATE)+1 END),p_BEGIN_DATE) AS BEGIN_DATE,
                                   NVL((CASE WHEN C.SWTCH = -1 THEN BEGIN_DATE-1
                                        WHEN C.SWTCH = 0 THEN END_DATE
                                        ELSE LEAD(BEGIN_DATE-1, 1, NULL)
                                                            OVER (PARTITION BY TUF.METER_ID ORDER BY BEGIN_DATE, END_DATE, C.SWTCH)
                                        END), v_END_DATE) AS END_DATE,
                                  M.METER_ID,
                                  (CASE WHEN C.SWTCH = 0 THEN TUF.TEMPLATE_ID ELSE NULL END) AS TEMPLATE_ID
                                FROM METER M, METER_TOU_USAGE_FACTOR TUF, (SELECT -1 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 0 AS SWTCH FROM DUAL
                                                                UNION ALL SELECT 1 AS SWTCH FROM DUAL) C
                                WHERE M.METER_ID = v_METER_ID
                                    AND M.METER_ID = TUF.METER_ID (+)
                                    AND TUF.BEGIN_DATE (+) <= v_END_DATE
                                    AND NVL(TUF.END_DATE (+), v_END_DATE) >= p_BEGIN_DATE)


                              SELECT A.ACCOUNT_ID,
                                    M.METER_ID,
                                    EDC.EDC_ID,
                                    EDC.EDC_RATE_CLASS,
                                    EDC.EDC_STRATA,
                                    ESP.ESP_ID,
                                    ESP.POOL_ID,
                                    CAL.CALENDAR_ID,
                                    UPPER(SUBSTR(M.METER_TYPE,1,1)) AS METER_TYPE,
                                    A.MODEL_ID,
                                    NVL(MLF.LOSS_FACTOR_ID, CONSTANTS.NOT_ASSIGNED) AS LOSS_FACTOR_ID,
                                    NVL(CASE WHEN NVL(SP.SERVICE_POINT_ID,CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED
                                            THEN SL.SERVICE_ZONE_ID
                                            ELSE SP.SERVICE_ZONE_ID END,CONSTANTS.NOT_ASSIGNED) AS SERVICE_ZONE_ID,
                                    NVL(SL.SERVICE_POINT_ID,CONSTANTS.NOT_ASSIGNED) AS SERVICE_POINT_ID,
                                    NVL(SL.WEATHER_STATION_ID,CONSTANTS.NOT_ASSIGNED) AS WEATHER_STATION_ID,
                                    NVL(MSG.SCHEDULE_GROUP_ID,CONSTANTS.NOT_ASSIGNED) AS SCHEDULE_GROUP_ID,
                                    NVL(ARP.REVENUE_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED) AS REVENUE_PRODUCT_ID,
                                    NVL(ACP.COST_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED) AS COST_PRODUCT_ID,
                                    NVL(ABC.BILL_CYCLE_ID,CONSTANTS.NOT_ASSIGNED) AS BILL_CYCLE_ID,
                                    NVL(MTOU.TEMPLATE_ID,CONSTANTS.NOT_ASSIGNED) AS TOU_TEMPLATE_ID,
                                    AAG.AGGREGATION_GROUP,

                                    GREATEST(ASL.BEGIN_DATE, SLM.BEGIN_DATE,CAL.BEGIN_DATE,EDC.BEGIN_DATE,
                                             MLF.BEGIN_DATE,AST.BEGIN_DATE,MSG.BEGIN_DATE,ARP.BEGIN_DATE,
                                             ABC.BEGIN_DATE,ACP.BEGIN_DATE,AAG.BEGIN_DATE,MTOU.BEGIN_DATE,
                                             ESP.BEGIN_DATE,p_BEGIN_DATE) AS BEGIN_DATE,

                                    LEAST(NVL(ASL.END_DATE,v_END_DATE),NVL(SLM.END_DATE,v_END_DATE),
                                            NVL(CAL.END_DATE,v_END_DATE),NVL(EDC.END_DATE,v_END_DATE),
                                            MLF.END_DATE,NVL(AST.END_DATE,v_END_DATE),
                                            MSG.END_DATE,ARP.END_DATE,ABC.END_DATE,ACP.END_DATE,
                                            AAG.END_DATE,MTOU.END_DATE,NVL(ESP.END_DATE,v_END_DATE),v_END_DATE) AS END_DATE

                              FROM ACCOUNT A,
                                    ACCOUNT_SERVICE_LOCATION ASL,
                                    SERVICE_LOCATION_METER SLM,
                                    SERVICE_LOCATION SL,
                                    METER M,
                                    SERVICE_POINT SP,
                                    ACCOUNT_STATUS AST,
                                    ACCOUNT_STATUS_NAME STAT,
                                    ACCOUNT_EDC EDC,
                                    ACCOUNT_ESP ESP,
                                    METER_CALENDAR CAL,
                                    MLF,
                                    MSG,
                                    ARP,
                                    ABC,
                                    ACP,
                                    AAG,
                                    MTOU
                              WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
                                AND ASL.ACCOUNT_ID = A.ACCOUNT_ID
                                AND SLM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
                                AND SLM.METER_ID = v_METER_ID
                                AND M.METER_ID = SLM.METER_ID
                                AND EDC.ACCOUNT_ID = A.ACCOUNT_ID
                                AND EDC.EDC_ID IN (SELECT X.COLUMN_VALUE FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)) X)
                                AND ESP.ACCOUNT_ID = A.ACCOUNT_ID
                                AND p_ESP_ID IN (CONSTANTS.ALL_ID, ESP.ESP_ID)
                                AND CAL.METER_ID = M.METER_ID
                                AND CAL.CALENDAR_TYPE = 'Forecast'
                                AND CAL.CASE_ID = GA.BASE_CASE_ID
                                AND MLF.METER_ID = M.METER_ID
                                AND AST.ACCOUNT_ID = A.ACCOUNT_ID
                                AND STAT.STATUS_NAME = AST.STATUS_NAME
                                AND STAT.IS_ACTIVE = 1
                                AND SL.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
                                AND SP.SERVICE_POINT_ID (+) = SL.SERVICE_POINT_ID
                                AND MSG.METER_ID = M.METER_ID
                                AND ARP.ACCOUNT_ID = A.ACCOUNT_ID
                                AND ABC.ACCOUNT_ID = A.ACCOUNT_ID
                                AND ACP.ACCOUNT_ID = A.ACCOUNT_ID
                                AND AAG.ACCOUNT_ID = A.ACCOUNT_ID
                                AND MTOU.METER_ID = M.METER_ID
                                AND GREATEST(ASL.BEGIN_DATE, SLM.BEGIN_DATE,CAL.BEGIN_DATE,EDC.BEGIN_DATE,
                                             MLF.BEGIN_DATE,AST.BEGIN_DATE,MSG.BEGIN_DATE,ARP.BEGIN_DATE,
                                             ABC.BEGIN_DATE,ACP.BEGIN_DATE,AAG.BEGIN_DATE,MTOU.BEGIN_DATE,
                                             ESP.BEGIN_DATE,p_BEGIN_DATE) <=
                                    LEAST(NVL(ASL.END_DATE,v_END_DATE),NVL(SLM.END_DATE,v_END_DATE),
                                            NVL(CAL.END_DATE,v_END_DATE),NVL(EDC.END_DATE,v_END_DATE),
                                            MLF.END_DATE,NVL(AST.END_DATE,v_END_DATE),
                                            MSG.END_DATE,ARP.END_DATE,ABC.END_DATE,ACP.END_DATE,
                                            AAG.END_DATE,MTOU.END_DATE,NVL(ESP.END_DATE,v_END_DATE),v_END_DATE)) LOOP

                    LOGS.LOG_DEBUG('For date range ' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_REC.BEGIN_DATE,v_REC.END_DATE) || ', ' ||
                                        'ACCOUNT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCT_REC.ACCOUNT_ID, EC.ED_ACCOUNT) || ', ' ||
                                        'METER: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.METER_ID, EC.ED_METER) || ', ' ||
                                        'EDC: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.EDC_ID, EC.ED_EDC) || ', ' ||
                                        'EDC STRATA: ' || v_REC.EDC_STRATA || ', ' ||
                                        'EDC RATE CLASS: ' || v_REC.EDC_RATE_CLASS || ', ' ||
                                        'CALENDAR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.CALENDAR_ID, EC.ED_CALENDAR) || ', ' ||
                                        'METER TYPE: ' || v_REC.METER_TYPE || ', ' ||
                                        'MODEL: ' || CASE WHEN v_REC.MODEL_ID = GA.GAS_MODEL THEN 'Gas' ELSE 'Electric' END || ', ' ||
                                        'LOSS FACTOR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.LOSS_FACTOR_ID, EC.ED_LOSS_FACTOR) || ', ' ||
                                        'SERVICE ZONE: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SERVICE_ZONE_ID, EC.ED_SERVICE_ZONE) || ', ' ||
                                        'SERVICE POINT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SERVICE_POINT_ID, EC.ED_SERVICE_POINT) || ', ' ||
                                        'WEATHER STATION: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.WEATHER_STATION_ID, EC.ED_WEATHER_STATION) || ', ' ||
                                        'SCHEDULE GROUP: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SCHEDULE_GROUP_ID, EC.ED_SCHEDULE_GROUP) || ', ' ||
                                        'REVENUE PRODUCT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.REVENUE_PRODUCT_ID, EC.ED_PRODUCT) || ', ' ||
                                        'COST PRODUCT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.COST_PRODUCT_ID, EC.ED_PRODUCT) || ', ' ||
                                        'BILL CYCLE: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.BILL_CYCLE_ID, EC.ED_BILL_CYCLE) || ', ' ||
                                        'TEMPLATE: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.TOU_TEMPLATE_ID, EC.ED_TEMPLATE) || ', ' ||
                                        'AGGREGATION GROUP: ' || v_REC.AGGREGATION_GROUP);

                     v_ACCOUNT_ID := ENSURE_AGGREGATE_ACCOUNT(v_REC.EDC_ID,
                                                            v_REC.CALENDAR_ID,
                                                            v_REC.METER_TYPE,
                                                            V_REC.MODEL_ID,
                                                            v_REC.SERVICE_POINT_ID,
                                                            v_REC.SERVICE_ZONE_ID,
                                                            v_REC.SCHEDULE_GROUP_ID,
                                                            v_REC.WEATHER_STATION_ID,
                                                            v_REC.LOSS_FACTOR_ID,
                                                            v_REC.REVENUE_PRODUCT_ID,
                                                            v_REC.COST_PRODUCT_ID,
                                                            v_REC.TOU_TEMPLATE_ID,
                                                            v_REC.BILL_CYCLE_ID,
                                                            v_REC.EDC_RATE_CLASS,
                                                            v_REC.EDC_STRATA,
                                                            v_REC.AGGREGATION_GROUP,
                                                            p_RESET_DATES);

                    ENSURE_ACCOUNT_ESP(v_ACCOUNT_ID,v_REC.ESP_ID,v_REC.POOL_ID,v_REC.BEGIN_DATE,v_REC.END_DATE);
                    ENSURE_SUB_AGG_AGGREGATION(v_REC.METER_ID,ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER,v_REC.BEGIN_DATE,v_REC.END_DATE,v_ACCOUNT_ID,
                                                v_REC.ESP_ID,v_REC.POOL_ID);

                    LOGS.LOG_DEBUG('Account for static data: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT));
                END LOOP;
            END LOOP;
        END IF;

    LOGS.INCREMENT_PROCESS_PROGRESS;
    v_ACCOUNT_INDEX := v_ACCOUNT_INDEX + 1;
    END LOOP;


    p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;

    COMMIT;
    LOGS.STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);

EXCEPTION
    WHEN OTHERS THEN
        ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'BEFORE_AGGREGATION');
END RUN_AGGREGATION_IMPL;
--------------------------------------------------------------------------------
PROCEDURE RUN_AGGREGATION
    (
    p_EDC_IDs IN NUMBER_COLLECTION,
    p_ESP_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_RESET_DATES IN NUMBER,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
   v_EDC_IDS NUMBER_COLLECTION := NUMBER_COLLECTION();
BEGIN
   -- Fix to original requirement of not selecting any EDC implies <ALL> EDCs
   -- This latter part of the fix is to suppress the GUI bug/issue in that it
   -- passes 1 EDC_ID of value 0, when no EDC is selected
   IF P_EDC_IDS IS NULL OR P_EDC_IDS.COUNT = 0 OR (p_EDC_IDS.COUNT = 1 AND p_EDC_IDS(1) = 0) THEN
        SELECT EDC_ID
        BULK COLLECT INTO v_EDC_IDS
        FROM EDC
        WHERE EDC.EDC_ID <> 0;
  ELSE
      v_EDC_IDS := p_EDC_IDS;
    END IF;

    RUN_AGGREGATION_IMPL(NUMBER_COLLECTION(CONSTANTS.ALL_ID),
                                    v_EDC_IDs,
                                    p_ESP_ID,
                                    p_BEGIN_DATE,
                                    p_END_DATE,
                                    p_RESET_DATES,
                                    p_TRACE_ON,
                                    p_PROCESS_ID,
                                    p_PROCESS_STATUS,
                                    p_MESSAGE);

END RUN_AGGREGATION;
--------------------------------------------------------------------------------
PROCEDURE RESET_AGGREGATE_ACCOUNT_DATES
  (
  p_AGGREGATE_ACCOUNT_ID IN NUMBER,
  p_SERVICE_LOCATION_ID  IN NUMBER,
  p_EDC_ID               IN NUMBER,
  p_CALENDAR_ID          IN NUMBER,
  p_SCHEDULE_GROUP_ID    IN NUMBER := NULL,
  p_LOSS_FACTOR_ID       IN NUMBER := NULL,
  p_REVENUE_PRODUCT_ID   IN NUMBER := NULL,
  p_COST_PRODUCT_ID      IN NUMBER := NULL,
  p_TOU_TEMPLATE_ID      IN NUMBER := NULL,
  p_BILL_CYCLE_ID        IN NUMBER := NULL,
  p_EDC_RATE_CLASS       IN VARCHAR2 := NULL,
  p_EDC_STRATA           IN VARCHAR2 := NULL,
  p_AGGREGATION_GROUP    IN VARCHAR2 := NULL
  ) AS
v_AGG_GROUP_ENTITY_ATT_ID ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;
BEGIN

  -- ACCOUNT_STATUS, Required
  DELETE FROM ACCOUNT_STATUS X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  ACCOUNTS_METERS.PUT_ACCOUNT_STATUS(p_AGGREGATE_ACCOUNT_ID, CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, 'Active', NULL);

  -- ACCOUNT_SERVICE_LOCATION, Optional
  DELETE FROM ACCOUNT_SERVICE_LOCATION X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  IF NVL(p_SERVICE_LOCATION_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
      UT.PUT_TEMPORAL_DATA('ACCOUNT_SERVICE_LOCATION',
                            CONSTANTS.LOW_DATE,
                            CONSTANTS.HIGH_DATE,
                            TRUE,
                            TRUE,
                            'ACCOUNT_ID',
                            p_AGGREGATE_ACCOUNT_ID,
                            TRUE,
                            'SERVICE_LOCATION_ID',
                            p_SERVICE_LOCATION_ID,
                            TRUE);
  END IF;

  -- ACCOUNT_EDC, Required
  DELETE FROM ACCOUNT_EDC X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  ACCOUNTS_METERS.PUT_ACCOUNT_EDC(p_AGGREGATE_ACCOUNT_ID, p_EDC_ID, CONSTANTS.LOW_DATE, NULL, p_EDC_RATE_CLASS, p_EDC_STRATA, CONSTANTS.HIGH_DATE, NULL, NULL);

  -- ACCOUNT_CALENDAR, Required
  DELETE FROM ACCOUNT_CALENDAR X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  ACCOUNTS_METERS.PUT_ACCOUNT_CALENDAR(p_AGGREGATE_ACCOUNT_ID, GA.BASE_CASE_ID, 'Forecast', CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, p_CALENDAR_ID, NULL, NULL, NULL);

  -- ACCOUNT_SCHEDULE_GROUP, Optional
  DELETE FROM ACCOUNT_SCHEDULE_GROUP X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  IF NVL(p_SCHEDULE_GROUP_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    ACCOUNTS_METERS.PUT_ACCOUNT_SCHEDULE_GROUP(p_AGGREGATE_ACCOUNT_ID, p_SCHEDULE_GROUP_ID, CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, NULL);
  END IF;

  -- ACCOUNT_LOSS_FACTOR, Optional
  DELETE FROM ACCOUNT_LOSS_FACTOR X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  IF NVL(p_LOSS_FACTOR_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    ACCOUNTS_METERS.PUT_ACCOUNT_LOSS_FACTOR(p_AGGREGATE_ACCOUNT_ID, GA.BASE_CASE_ID, p_LOSS_FACTOR_ID, CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, NULL, NULL);
  END IF;

  -- ACCOUNT_PRODUCT, Optional
  DELETE FROM ACCOUNT_PRODUCT X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  -- Revenue
  IF NVL(p_REVENUE_PRODUCT_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    ACCOUNTS_METERS.PUT_ACCOUNT_PRODUCT(GA.BASE_CASE_ID, p_AGGREGATE_ACCOUNT_ID, p_REVENUE_PRODUCT_ID, ACCOUNTS_METERS.c_PRODUCT_TYPE_REVENUE, CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, NULL, NULL, NULL);
  END IF;

  -- Cost
  IF NVL(p_COST_PRODUCT_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    ACCOUNTS_METERS.PUT_ACCOUNT_PRODUCT(GA.BASE_CASE_ID, p_AGGREGATE_ACCOUNT_ID, p_COST_PRODUCT_ID, ACCOUNTS_METERS.c_PRODUCT_TYPE_COST, CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, NULL, NULL, NULL);
  END IF;

  -- ACCOUNT_TOU_USAGE_FACTOR, Optional
  DELETE FROM ACCOUNT_TOU_USAGE_FACTOR X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  IF NVL(p_TOU_TEMPLATE_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    ACCOUNTS_METERS.PUT_ACCOUNT_TOU_USAGE_FACTOR(p_AGGREGATE_ACCOUNT_ID, GA.BASE_CASE_ID, CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, p_TOU_TEMPLATE_ID, NULL, NULL);
  END IF;

  -- ACCOUNT_BILL_CYCLE, Optional
  DELETE FROM ACCOUNT_BILL_CYCLE X
  WHERE X.ACCOUNT_ID = p_AGGREGATE_ACCOUNT_ID;

  IF NVL(p_BILL_CYCLE_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    ACCOUNTS_METERS.PUT_ACCOUNT_BILL_CYCLE(p_AGGREGATE_ACCOUNT_ID, p_BILL_CYCLE_ID, UT.GET_INCUMBENT_ENTITY_TYPE(), CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, NULL);
  END IF;

  ID.ID_FOR_ENTITY_ATTRIBUTE(ACCOUNTS_METERS.c_AGGREGATION_GROUP_ENT_ATTR, EC.ED_ACCOUNT, 'String', FALSE, v_AGG_GROUP_ENTITY_ATT_ID);

  -- AGGREGATION GROUP
  DELETE FROM TEMPORAL_ENTITY_ATTRIBUTE X
  WHERE X.OWNER_ENTITY_ID = p_AGGREGATE_ACCOUNT_ID
    AND X.ATTRIBUTE_ID = v_AGG_GROUP_ENTITY_ATT_ID
    AND X.ENTITY_DOMAIN_ID = EC.ED_ACCOUNT;

  IF p_AGGREGATION_GROUP IS NOT NULL THEN
    EM.PUT_ENTITY_ATTRIBUTE_VALUE(EC.ED_ACCOUNT, p_AGGREGATE_ACCOUNT_ID, v_AGG_GROUP_ENTITY_ATT_ID, CONSTANTS.LOW_DATE, CONSTANTS.HIGH_DATE, p_AGGREGATION_GROUP, NULL, NULL, NULL);
  END IF;

END RESET_AGGREGATE_ACCOUNT_DATES;
-------------------------------------------------------------------------------------
FUNCTION GET_AGGREGATE_ACCOUNT_NAME
  (
  p_EDC_ID              IN NUMBER,
  p_CALENDAR_ID         IN NUMBER,
  p_METER_TYPE          IN VARCHAR2,
  p_MODEL_ID        IN NUMBER,
  p_SERVICE_POINT_ID    IN NUMBER := NULL,
  p_SERVICE_ZONE_ID     IN NUMBER := NULL,
  p_SCHEDULE_GROUP_ID   IN NUMBER := NULL,
  p_WEATHER_STATION_ID  IN NUMBER := NULL,
  p_LOSS_FACTOR_ID      IN NUMBER := NULL,
  p_REVENUE_PRODUCT_ID  IN NUMBER := NULL,
  p_COST_PRODUCT_ID     IN NUMBER := NULL,
  p_TOU_TEMPLATE_ID     IN NUMBER := NULL,
  p_BILL_CYCLE_ID       IN NUMBER := NULL,
  p_EDC_RATE_CLASS      IN VARCHAR2 := NULL,
  p_EDC_STRATA          IN VARCHAR2 := NULL,
  p_AGGREGATION_GROUP   IN VARCHAR2 := NULL
  ) RETURN VARCHAR2 AS
v_AGGREGATE_ACCOUNT_NAME VARCHAR2(4000);
BEGIN
  -- EDC, required, use Alias
  v_AGGREGATE_ACCOUNT_NAME := EI.GET_ENTITY_ALIAS(EC.ED_EDC, p_EDC_ID);

  -- Service Point, optional, use Name
  IF NVL(p_SERVICE_POINT_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_NAME(EC.ED_SERVICE_POINT, p_SERVICE_POINT_ID);
  -- Service Zone, optional if Service Point is NOT_ASSIGNED, use Name
  ELSIF NVL(p_SERVICE_ZONE_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_NAME(EC.ED_SERVICE_ZONE, p_SERVICE_ZONE_ID);
  END IF;

  -- Schedule Group, optional, use Name
  IF NVL(p_SCHEDULE_GROUP_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_NAME(EC.ED_SCHEDULE_GROUP, p_SCHEDULE_GROUP_ID);
  END IF;

  -- Calendar, required, use Alias
  v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_ALIAS(EC.ED_CALENDAR, p_CALENDAR_ID);

  -- Weather Station, optional, use Name
  IF NVL(p_WEATHER_STATION_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_ALIAS(EC.ED_WEATHER_STATION, p_WEATHER_STATION_ID);
  END IF;

  -- Loss Factor, optional, use Alias
  IF NVL(p_LOSS_FACTOR_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_ALIAS(EC.ED_LOSS_FACTOR, p_LOSS_FACTOR_ID);
  END IF;

  -- EDC Rate Class, optional, use value passed in
  IF p_EDC_RATE_CLASS IS NOT NULL THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || p_EDC_RATE_CLASS;
  END IF;

  -- EDC Strata, optional, use value passed in
  IF p_EDC_STRATA IS NOT NULL THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || p_EDC_STRATA;
  END IF;

  -- Revenue Product, optional, use Alias
  IF NVL(p_REVENUE_PRODUCT_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_ALIAS(EC.ED_PRODUCT, p_REVENUE_PRODUCT_ID);
  END IF;

  -- Cost Product, optional, use Alias
  IF NVL(p_COST_PRODUCT_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_ALIAS(EC.ED_PRODUCT, p_COST_PRODUCT_ID);
  END IF;

  -- Meter Type, required, use value passed in
  v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || p_METER_TYPE;

  -- TOU Template, optional, use Name
  IF NVL(p_TOU_TEMPLATE_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_NAME(EC.ED_TEMPLATE, p_TOU_TEMPLATE_ID);
  END IF;

  -- Bill Cycle, optional, use Name
  IF NVL(p_BILL_CYCLE_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || EI.GET_ENTITY_NAME(EC.ED_BILL_CYCLE, p_BILL_CYCLE_ID);
  END IF;

  -- Aggregation Group (Custom Attribute), optional, use value passed in
  IF p_AGGREGATION_GROUP IS NOT NULL THEN
    v_AGGREGATE_ACCOUNT_NAME := v_AGGREGATE_ACCOUNT_NAME || c_AGGREGATE_ACCOUNT_NAME_SEP || p_AGGREGATION_GROUP;
  END IF;

  -- Truncate the field
  v_AGGREGATE_ACCOUNT_NAME := SUBSTR(v_AGGREGATE_ACCOUNT_NAME, 1, 128);

  -- Resolve any conflicts due to the truncated name
  v_AGGREGATE_ACCOUNT_NAME := ENTITY_UTIL.RESOLVE_ENTITY_NAME_CONFLICT(v_AGGREGATE_ACCOUNT_NAME,EC.ED_ACCOUNT);

  RETURN v_AGGREGATE_ACCOUNT_NAME;
END GET_AGGREGATE_ACCOUNT_NAME;
-------------------------------------------------------------------------------------
FUNCTION GET_AGGREGATE_SVC_LOC_NAME
  (
  p_SERVICE_POINT_ID    IN NUMBER := NULL,
  p_SERVICE_ZONE_ID     IN NUMBER := NULL,
  p_WEATHER_STATION_ID  IN NUMBER := NULL
  ) RETURN VARCHAR2 AS
v_SERVICE_LOCATION_NAME   VARCHAR2(4000);
BEGIN
  v_SERVICE_LOCATION_NAME := 'Agg.Svc.Loc';

  -- Service Point, optional, use Name
  IF NVL(p_SERVICE_POINT_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_SERVICE_LOCATION_NAME := v_SERVICE_LOCATION_NAME || '.' || EI.GET_ENTITY_NAME(EC.ED_SERVICE_POINT, p_SERVICE_POINT_ID);
  END IF;

  -- Service Zone, optional, use Name
  IF NVL(p_SERVICE_ZONE_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_SERVICE_LOCATION_NAME := v_SERVICE_LOCATION_NAME || '.' || EI.GET_ENTITY_NAME(EC.ED_SERVICE_ZONE, p_SERVICE_ZONE_ID);
  END IF;

  -- Weather Station, optional, use Name
  IF NVL(p_WEATHER_STATION_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
    v_SERVICE_LOCATION_NAME := v_SERVICE_LOCATION_NAME || '.' || EI.GET_ENTITY_ALIAS(EC.ED_WEATHER_STATION, p_WEATHER_STATION_ID);
  END IF;

  -- Truncate the field
  v_SERVICE_LOCATION_NAME := SUBSTR(v_SERVICE_LOCATION_NAME, 1, 32);

  -- Resolve any conflicts due to the truncated name
  v_SERVICE_LOCATION_NAME := ENTITY_UTIL.RESOLVE_ENTITY_NAME_CONFLICT(v_SERVICE_LOCATION_NAME,EC.ED_SERVICE_LOCATION);

  RETURN v_SERVICE_LOCATION_NAME;
END GET_AGGREGATE_SVC_LOC_NAME;
-------------------------------------------------------------------------------------
PROCEDURE CREATE_AGGREGATE_ACCOUNT
  (
  p_AGGREGATE_ACCOUNT_ID OUT NUMBER,
  p_SERVICE_LOCATION_ID  OUT NUMBER,
  p_EDC_ID               IN NUMBER,
  p_CALENDAR_ID          IN NUMBER,
  p_METER_TYPE           IN VARCHAR2,
  p_MODEL_ID         IN NUMBER,
  p_SERVICE_POINT_ID     IN NUMBER := NULL,
  p_SERVICE_ZONE_ID      IN NUMBER := NULL,
  p_SCHEDULE_GROUP_ID    IN NUMBER := NULL,
  p_WEATHER_STATION_ID   IN NUMBER := NULL,
  p_LOSS_FACTOR_ID       IN NUMBER := NULL,
  p_REVENUE_PRODUCT_ID   IN NUMBER := NULL,
  p_COST_PRODUCT_ID      IN NUMBER := NULL,
  p_TOU_TEMPLATE_ID      IN NUMBER := NULL,
  p_BILL_CYCLE_ID        IN NUMBER := NULL,
  p_EDC_RATE_CLASS       IN VARCHAR2 := NULL,
  p_EDC_STRATA           IN VARCHAR2 := NULL,
  p_AGGREGATION_GROUP    IN VARCHAR2 := NULL
  ) AS
v_AGGREGATE_ACCOUNT_NAME ACCOUNT.ACCOUNT_NAME%TYPE;
v_SERVICE_LOCATION_NAME   SERVICE_LOCATION.SERVICE_LOCATION_NAME%TYPE;
v_MESSAGE          VARCHAR2(4000);
BEGIN
  -- Get the new Account Name
  v_AGGREGATE_ACCOUNT_NAME := GET_AGGREGATE_ACCOUNT_NAME(p_EDC_ID,p_CALENDAR_ID,p_METER_TYPE,p_MODEL_ID,p_SERVICE_POINT_ID,p_SERVICE_ZONE_ID,p_SCHEDULE_GROUP_ID,p_WEATHER_STATION_ID,p_LOSS_FACTOR_ID,p_REVENUE_PRODUCT_ID,p_COST_PRODUCT_ID,p_TOU_TEMPLATE_ID,p_BILL_CYCLE_ID,p_EDC_RATE_CLASS,p_EDC_STRATA,p_AGGREGATION_GROUP);

  -- Insert the new Aggregate Account
  ACCOUNTS_METERS.PUT_ACCOUNT(p_AGGREGATE_ACCOUNT_ID,
    v_AGGREGATE_ACCOUNT_NAME,
    NULL, -- ACCOUNT_ALIAS
    NULL, -- ACCOUNT_DESCRIPTION
    0,
    NULL, --ACCOUNT_DUNS_NUMBER,
    NULL, --ACCOUNT_EXTERNAL_IDENTIFIER,
    ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE, --ACCOUNT_MODEL_OPTION,
    NULL, --ACCOUNT_SIC_CODE,
    CASE
      WHEN p_METER_TYPE = CONSTANTS.METER_TYPE_INTERVAL THEN
        'Interval'
      WHEN p_METER_TYPE = CONSTANTS.METER_TYPE_PERIOD THEN
        'Period'
    END,
    NULL, --ACCOUNT_METER_EXT_IDENTIFIER,
    NULL, --ACCOUNT_DISPLAY_NAME,
    NULL, --ACCOUNT_BILL_OPTION,
    NULL, --ACCOUNT_ROLLUP_ID,
    0, --IS_EXTERNAL_INTERVAL_USAGE,
    0, --IS_EXTERNAL_BILLED_USAGE,
    1, --IS_AGGREGATE_ACCOUNT,
    0, --IS_UFE_PARTICIPANT,
    0, --IS_CREATE_SETTLEMENT_PROFILE,
    0, --IS_EXTERNAL_FORECAST,
    0, --IS_SUB_AGGREGATE,
    0, --TX_SERVICE_TYPE_ID,
    CASE
      WHEN NVL(p_TOU_TEMPLATE_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
        1
      ELSE
        0
    END, --use_tou_usage_factor
    p_MODEL_ID);

    -- Generate a name of the Service Location
    v_SERVICE_LOCATION_NAME := GET_AGGREGATE_SVC_LOC_NAME(p_SERVICE_POINT_ID,p_SERVICE_ZONE_ID,p_WEATHER_STATION_ID);

    -- Look up existing Service Location
    BEGIN
        SELECT X.SERVICE_LOCATION_ID
        INTO p_SERVICE_LOCATION_ID
        FROM SERVICE_LOCATION X
        WHERE X.SERVICE_LOCATION_NAME LIKE 'Agg.Svc.Loc%'
          AND (NVL(p_SERVICE_POINT_ID,CONSTANTS.NOT_ASSIGNED) = X.SERVICE_POINT_ID)
          AND (NVL(p_SERVICE_ZONE_ID,CONSTANTS.NOT_ASSIGNED) = X.SERVICE_ZONE_ID)
          AND (NVL(p_WEATHER_STATION_ID,CONSTANTS.NOT_ASSIGNED) = X.WEATHER_STATION_ID)
          AND ROWNUM = 1; -- IF SOMEHOW, A SECOND SERVICE LOCATION IS CREATE (E.G. BY THE USER) JUST PICK THE FIRST ONE
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            p_SERVICE_LOCATION_ID := 0;
    END;

    -- Create the Service Location
    ACCOUNTS_METERS.PUT_SERVICE_LOCATION(p_SERVICE_LOCATION_ID,
                p_AGGREGATE_ACCOUNT_ID,
                CONSTANTS.LOW_DATE, --OLD_SL_BEGIN_DATE,
                CONSTANTS.LOW_DATE, --SL_BEGIN_DATE,
                CONSTANTS.HIGH_DATE, --SL_END_DATE,
                NULL, --EDC_IDENTIFIER,
                NULL, --ESP_IDENTIFIER,
                v_SERVICE_LOCATION_NAME,
                NULL, -- SERVICE_LOCATION_ALIAS
                NULL, -- SERVICE_LOCATION_DESC
                p_SERVICE_LOCATION_ID, --SERVICE_LOCATION_ID,
                NULL, --LATITUDE,
                NULL, --LONGITUDE,
                NULL, --TIME_ZONE,
                v_SERVICE_LOCATION_NAME, --EXTERNAL_IDENTIFIER,
                NVL(p_SERVICE_POINT_ID, CONSTANTS.NOT_ASSIGNED), --SERVICE_POINT_ID,
                NVL(p_WEATHER_STATION_ID, CONSTANTS.NOT_ASSIGNED), --WEATHER_STATION_ID,
                NULL, --STREET,
                NULL, --STREET2,
                NULL, --CITY,
                NULL, --STATE_CODE,
                NULL, --POSTAL_CODE,
                NULL, --COUNTRY_CODE,
                NULL, --SQUARE_FOOTAGE,
                NULL, --ANNUAL_CONSUMPTION,
                NULL, --SUMMER_CONSUMPTION,
                NVL(p_SERVICE_ZONE_ID, CONSTANTS.NOT_ASSIGNED), --SERVICE_ZONE_ID,
                NULL, --SUB_STATION_ID,
                NULL, --FEEDER_ID,
                NULL, --FEEDER_SEGMENT_ID,
                v_MESSAGE); --MESSAGE

  -- Add Aggregation data to the table
  INSERT INTO ACCOUNT_AGGREGATE_STATIC_DATA
    (AGGREGATE_ACCOUNT_ID,
    SERVICE_LOCATION_ID,
    EDC_ID,
    SERVICE_POINT_ID,
    SERVICE_ZONE_ID,
    SCHEDULE_GROUP_ID,
    CALENDAR_ID,
    WEATHER_STATION_ID,
    LOSS_FACTOR_ID,
    EDC_RATE_CLASS,
    EDC_STRATA,
    REVENUE_PRODUCT_ID,
    COST_PRODUCT_ID,
    METER_TYPE,
    MODEL_ID,
    TOU_TEMPLATE_ID,
    BILL_CYCLE_ID,
    AGGREGATION_GROUP)
  VALUES
    (p_AGGREGATE_ACCOUNT_ID,
    p_SERVICE_LOCATION_ID,
    p_EDC_ID,
    NVL(p_SERVICE_POINT_ID,CONSTANTS.NOT_ASSIGNED),
    NVL(p_SERVICE_ZONE_ID,CONSTANTS.NOT_ASSIGNED),
    NVL(p_SCHEDULE_GROUP_ID,CONSTANTS.NOT_ASSIGNED),
    NVL(p_CALENDAR_ID,CONSTANTS.NOT_ASSIGNED),
    NVL(p_WEATHER_STATION_ID,CONSTANTS.NOT_ASSIGNED),
    NVL(p_LOSS_FACTOR_ID,CONSTANTS.NOT_ASSIGNED),
    p_EDC_RATE_CLASS,
    p_EDC_STRATA,
    NVL(p_REVENUE_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED),
    NVL(p_COST_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED),
    p_METER_TYPE,
    p_MODEL_ID,
    NVL(p_TOU_TEMPLATE_ID,CONSTANTS.NOT_ASSIGNED),
    NVL(p_BILL_CYCLE_ID,CONSTANTS.NOT_ASSIGNED),
    p_AGGREGATION_GROUP);

END CREATE_AGGREGATE_ACCOUNT;
-------------------------------------------------------------------------------------
FUNCTION ENSURE_AGGREGATE_ACCOUNT
  (
  p_EDC_ID              IN NUMBER,
  p_CALENDAR_ID         IN NUMBER,
  p_METER_TYPE          IN VARCHAR2,
  p_MODEL_ID        IN NUMBER,
  p_SERVICE_POINT_ID    IN NUMBER := NULL,
  p_SERVICE_ZONE_ID     IN NUMBER := NULL,
  p_SCHEDULE_GROUP_ID   IN NUMBER := NULL,
  p_WEATHER_STATION_ID  IN NUMBER := NULL,
  p_LOSS_FACTOR_ID      IN NUMBER := NULL,
  p_REVENUE_PRODUCT_ID  IN NUMBER := NULL,
  p_COST_PRODUCT_ID     IN NUMBER := NULL,
  p_TOU_TEMPLATE_ID     IN NUMBER := NULL,
  p_BILL_CYCLE_ID       IN NUMBER := NULL,
  p_EDC_RATE_CLASS      IN VARCHAR2 := NULL,
  p_EDC_STRATA          IN VARCHAR2 := NULL,
  p_AGGREGATION_GROUP   IN VARCHAR2 := NULL,
  p_RESET_DATES         IN NUMBER := 1
  ) RETURN NUMBER AS
v_AGGREGATE_ACCOUNT_ID   ACCOUNT.ACCOUNT_ID%TYPE;
v_SERVICE_LOCATION_ID   SERVICE_LOCATION.SERVICE_LOCATION_ID%TYPE;
v_RESET_DATES        NUMBER := 1;
BEGIN
  -- Validation
  ASSERT(NVL(p_EDC_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
       'EDC Id must be non-null and greater than 0. Id = ' || p_EDC_ID,
       MSGCODES.c_ERR_ARGUMENT);
  ASSERT(NVL(p_CALENDAR_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
       'Calendar Id must be non-null and greater than 0. Id = ' || p_CALENDAR_ID,
       MSGCODES.c_ERR_ARGUMENT);
  ASSERT(NVL(p_METER_TYPE,CONSTANTS.NOT_ASSIGNED_STRING) IN (CONSTANTS.METER_TYPE_INTERVAL, CONSTANTS.METER_TYPE_PERIOD),
       'Meter Type must be ' || CONSTANTS.METER_TYPE_INTERVAL || ' or ' || CONSTANTS.METER_TYPE_PERIOD || '. Meter Type = ' || p_METER_TYPE,
       MSGCODES.c_ERR_ARGUMENT);
    ASSERT(NVL(p_MODEL_ID,CONSTANTS.NOT_ASSIGNED) IN (CONSTANTS.ELECTRIC_MODEL, CONSTANTS.GAS_MODEL),
       'Model Id  must be ' || CONSTANTS.ELECTRIC_MODEL || ' or ' || CONSTANTS.GAS_MODEL || '. Id = ' || p_MODEL_ID,
       MSGCODES.c_ERR_ARGUMENT);

  v_RESET_DATES := NVL(p_RESET_DATES, 1);

  -- Look for existing Aggregate Account
  BEGIN
    SELECT A.AGGREGATE_ACCOUNT_ID, A.SERVICE_LOCATION_ID
    INTO v_AGGREGATE_ACCOUNT_ID, v_SERVICE_LOCATION_ID
    FROM ACCOUNT_AGGREGATE_STATIC_DATA A
    WHERE A.EDC_ID = p_EDC_ID
      AND A.CALENDAR_ID = p_CALENDAR_ID
      AND A.METER_TYPE = p_METER_TYPE
          AND A.MODEL_ID = p_MODEL_ID
      AND (NVL(p_SERVICE_POINT_ID,CONSTANTS.NOT_ASSIGNED) = A.SERVICE_POINT_ID)
      AND (NVL(p_SERVICE_ZONE_ID,CONSTANTS.NOT_ASSIGNED) = A.SERVICE_ZONE_ID)
      AND (NVL(p_SCHEDULE_GROUP_ID,CONSTANTS.NOT_ASSIGNED) = A.SCHEDULE_GROUP_ID)
      AND (NVL(p_WEATHER_STATION_ID,CONSTANTS.NOT_ASSIGNED) = A.WEATHER_STATION_ID)
      AND (NVL(p_LOSS_FACTOR_ID,CONSTANTS.NOT_ASSIGNED) = A.LOSS_FACTOR_ID)
      AND ((p_EDC_RATE_CLASS IS NULL AND A.EDC_RATE_CLASS IS NULL)
      OR A.EDC_RATE_CLASS = p_EDC_RATE_CLASS)
      AND ((p_EDC_STRATA IS NULL AND A.EDC_STRATA IS NULL)
      OR EDC_STRATA = p_EDC_STRATA)
      AND (NVL(p_REVENUE_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED) = A.REVENUE_PRODUCT_ID)
      AND (NVL(p_COST_PRODUCT_ID,CONSTANTS.NOT_ASSIGNED) = A.COST_PRODUCT_ID)
      AND (NVL(p_TOU_TEMPLATE_ID,CONSTANTS.NOT_ASSIGNED) = A.TOU_TEMPLATE_ID)
      AND (NVL(p_BILL_CYCLE_ID,CONSTANTS.NOT_ASSIGNED) = A.BILL_CYCLE_ID)
      AND ((p_AGGREGATION_GROUP IS NULL AND A.AGGREGATION_GROUP IS NULL)
      OR A.AGGREGATION_GROUP = p_AGGREGATION_GROUP);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_RESET_DATES := 1;
      CREATE_AGGREGATE_ACCOUNT(v_AGGREGATE_ACCOUNT_ID,v_SERVICE_LOCATION_ID,p_EDC_ID,p_CALENDAR_ID,p_METER_TYPE,p_MODEL_ID,p_SERVICE_POINT_ID,p_SERVICE_ZONE_ID,p_SCHEDULE_GROUP_ID,p_WEATHER_STATION_ID,p_LOSS_FACTOR_ID,p_REVENUE_PRODUCT_ID,p_COST_PRODUCT_ID,p_TOU_TEMPLATE_ID,p_BILL_CYCLE_ID,p_EDC_RATE_CLASS,p_EDC_STRATA,p_AGGREGATION_GROUP);
  END;

  IF v_RESET_DATES = 1 THEN
    RESET_AGGREGATE_ACCOUNT_DATES(v_AGGREGATE_ACCOUNT_ID,v_SERVICE_LOCATION_ID,p_EDC_ID,p_CALENDAR_ID,p_SCHEDULE_GROUP_ID,p_LOSS_FACTOR_ID,p_REVENUE_PRODUCT_ID,p_COST_PRODUCT_ID,p_TOU_TEMPLATE_ID,p_BILL_CYCLE_ID,p_EDC_RATE_CLASS,p_EDC_STRATA,p_AGGREGATION_GROUP);
  END IF;

  RETURN v_AGGREGATE_ACCOUNT_ID;

END ENSURE_AGGREGATE_ACCOUNT;
--------------------------------------------------------------------------------
PROCEDURE GET_ACCOUNT_AGGREGATIONS
    (
    p_EDC_ID IN NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    ) AS

BEGIN

    OPEN p_CURSOR FOR
    SELECT A.ACCOUNT_ID,
        A.ACCOUNT_NAME,
        EDC.EDC_NAME,
        EDC.EDC_ALIAS,
        AG.EDC_RATE_CLASS,
        AG.EDC_STRATA,
        C.CALENDAR_NAME,
        C.CALENDAR_ALIAS,
        AG.METER_TYPE,
        CASE WHEN AG.MODEL_ID = GA.GAS_MODEL THEN 'Gas' ELSE 'Electric' END AS MODEL,
        SP.SERVICE_POINT_NAME,
        SP.SERVICE_POINT_ALIAS,
        SZ.SERVICE_ZONE_NAME,
        SZ.SERVICE_ZONE_ALIAS,
        SG.SCHEDULE_GROUP_NAME,
        SG.SCHEDULE_GROUP_ALIAS,
        WS.STATION_NAME,
        WS.STATION_ALIAS,
        LF.LOSS_FACTOR_NAME,
        LF.LOSS_FACTOR_ALIAS,
        RP.PRODUCT_NAME AS REVENUE_PRODUCT,
        RP.PRODUCT_ALIAS AS REVENUE_PRODUCT_ALIAS,
        CP.PRODUCT_NAME AS COST_PRODUCT,
        CP.PRODUCT_ALIAS AS COST_PRODUCT_ALIAS,
        T.TEMPLATE_NAME,
        T.TEMPLATE_ALIAS,
        BC.BILL_CYCLE_NAME,
        BC.BILL_CYCLE_ALIAS,
        AG.AGGREGATION_GROUP
    FROM ACCOUNT_AGGREGATE_STATIC_DATA AG,
        ACCOUNT A,
        ENERGY_DISTRIBUTION_COMPANY EDC,
        SERVICE_POINT SP,
        SERVICE_ZONE SZ,
        SCHEDULE_GROUP SG,
        CALENDAR C,
        WEATHER_STATION WS,
        LOSS_FACTOR LF,
        PRODUCT RP,
        PRODUCT CP,
        TEMPLATE T,
        BILL_CYCLE BC
    WHERE A.ACCOUNT_ID = AG.AGGREGATE_ACCOUNT_ID
        AND EDC.EDC_ID = AG.EDC_ID
        AND (EDC.EDC_ID = p_EDC_ID OR p_EDC_ID = CONSTANTS.ALL_ID)
        AND SP.SERVICE_POINT_ID = AG.SERVICE_POINT_ID
        AND SZ.SERVICE_ZONE_ID = AG.SERVICE_ZONE_ID
        AND SG.SCHEDULE_GROUP_ID = AG.SCHEDULE_GROUP_ID
        AND C.CALENDAR_ID = AG.CALENDAR_ID
        AND WS.STATION_ID = AG.WEATHER_STATION_ID
        AND LF.LOSS_FACTOR_ID = AG.LOSS_FACTOR_ID
        AND RP.PRODUCT_ID = AG.REVENUE_PRODUCT_ID
        AND CP.PRODUCT_ID = AG.COST_PRODUCT_ID
        AND T.TEMPLATE_ID = AG.TOU_TEMPLATE_ID
        AND BC.BILL_CYCLE_ID = AG.BILL_CYCLE_ID
   ORDER BY A.ACCOUNT_NAME;

END GET_ACCOUNT_AGGREGATIONS;
--------------------------------------------------------------------------------------------
PROCEDURE DEL_AGG_ACCOUNT_ENROLLMENT 
	(
	p_BEGIN_DATE IN DATE, 
	p_END_DATE IN DATE
	) AS
BEGIN

 -- (SP BUG 28654) Fixed a problem with extraneous data being left in the Aggregate_Account_service table
      DELETE
      FROM AGGREGATE_ACCOUNT_SERVICE AAS
      WHERE SERVICE_DATE BETWEEN p_BEGIN_DATE and p_END_DATE 
        AND NOT EXISTS
          (SELECT 1
          FROM TABLE(CAST(DATE_UTIL.DATES_IN_INTERVAL_RANGE(p_BEGIN_DATE, p_END_DATE, CONSTANTS.INTERVAL_DAY) AS DATE_COLLECTION)) D,
              AGGREGATE_ACCOUNT_ESP AAE,
              ACCOUNT_EDC AEDC,
              ACCOUNT_SUB_AGG_AGGREGATION ASA   
          WHERE AEDC.ACCOUNT_ID = AAE.ACCOUNT_ID
          AND ASA.AGGREGATE_ID = AAE.AGGREGATE_ID
          AND D.COLUMN_VALUE BETWEEN AAE.BEGIN_DATE AND NVL(AAE.END_DATE, CONSTANTS.HIGH_DATE)
          AND D.COLUMN_VALUE BETWEEN AEDC.BEGIN_DATE AND NVL(AEDC.END_DATE, CONSTANTS.HIGH_DATE)
          AND D.COLUMN_VALUE BETWEEN ASA.BEGIN_DATE AND NVL(ASA.END_DATE, CONSTANTS.HIGH_DATE)
          AND (AAS.AGGREGATE_ID = AAE.AGGREGATE_ID AND AAS.SERVICE_DATE = D.COLUMN_VALUE AND AAS.CASE_ID = GA.BASE_CASE_ID)
          );

END DEL_AGG_ACCOUNT_ENROLLMENT;
--------------------------------------------------------------------------------------------
PROCEDURE CAL_AGG_ACCOUNT_ENROLLMENT
    (
    p_BEGIN_DATE DATE,
    p_END_DATE DATE,
    p_EDC_ID NUMBER,
    p_ESP_ID NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
    v_DEFAULT_AVG_USAGE_FACTOR NUMBER;
BEGIN
    SAVEPOINT BEFORE_CAL_AGG_ACC_ENROLLMENT;

    LOGS.START_PROCESS('Calculate Aggregate Account Enrollment', p_BEGIN_DATE, p_END_DATE);
    LOGS.SET_PROCESS_TARGET_PARAMETER('EDC',CASE WHEN p_EDC_ID = CONSTANTS.ALL_ID THEN 'All' ELSE TEXT_UTIL.TO_CHAR_ENTITY(p_EDC_ID, EC.ED_EDC) END);
    LOGS.SET_PROCESS_TARGET_PARAMETER('ESP',CASE WHEN p_ESP_ID = CONSTANTS.ALL_ID THEN 'All' ELSE TEXT_UTIL.TO_CHAR_ENTITY(p_ESP_ID, EC.ED_ESP) END);

    v_DEFAULT_AVG_USAGE_FACTOR := TO_NUMBER(GET_DICTIONARY_VALUE('Default Average Usage Factor',
                                                        GA.STANDARD_MODE,
                                                        'Load Management'));
    
   DEL_AGG_ACCOUNT_ENROLLMENT(p_BEGIN_DATE, p_END_DATE);

    MERGE INTO AGGREGATE_ACCOUNT_SERVICE AAS
    USING (
        SELECT X.AGGREGATE_ID,
            X.SERVICE_DATE,
            COUNT(X.SERVICE_METER_ID) AS SERVICE_ACCOUNTS,
            COUNT(X.SERVICE_ACCOUNT_ID) AS ENROLLED_ACCOUNTS,
            CASE WHEN COUNT(X.SERVICE_METER_ID) > 0 AND SUM(X.USAGE_FACTOR) IS NULL
                THEN v_DEFAULT_AVG_USAGE_FACTOR
                ELSE AVG(X.USAGE_FACTOR) END USAGE_FACTOR
        FROM (-- Account model
             SELECT AGG.AGGREGATE_ID,
                AGG.SERVICE_DATE,
                AGG.ACCOUNT_ID AS SERVICE_ACCOUNT_ID,
                AGG.ACCOUNT_ID AS SERVICE_METER_ID,
                AUF.FACTOR_VAL AS USAGE_FACTOR
            FROM (SELECT AAE.AGGREGATE_ID, D.COLUMN_VALUE AS SERVICE_DATE, ASA.ACCOUNT_ID
                FROM TABLE(CAST(DATE_UTIL.DATES_IN_INTERVAL_RANGE(p_BEGIN_DATE, p_END_DATE, CONSTANTS.INTERVAL_DAY) AS DATE_COLLECTION)) D,
                    AGGREGATE_ACCOUNT_ESP AAE,
                    ACCOUNT_EDC AEDC,
                    ACCOUNT_SUB_AGG_AGGREGATION ASA
                WHERE D.COLUMN_VALUE BETWEEN AAE.BEGIN_DATE AND NVL(AAE.END_DATE, CONSTANTS.HIGH_DATE)
                    AND (AAE.ESP_ID = p_ESP_ID OR CONSTANTS.ALL_ID = p_ESP_ID)
                    AND AEDC.ACCOUNT_ID = AAE.ACCOUNT_ID
                    AND D.COLUMN_VALUE BETWEEN AEDC.BEGIN_DATE AND NVL(AEDC.END_DATE, CONSTANTS.HIGH_DATE)
                    AND (AEDC.EDC_ID = p_EDC_ID OR CONSTANTS.ALL_ID = p_EDC_ID)
                    AND ASA.AGGREGATE_ID = AAE.AGGREGATE_ID
                    AND D.COLUMN_VALUE BETWEEN ASA.BEGIN_DATE AND NVL(ASA.END_DATE, CONSTANTS.HIGH_DATE)) AGG,
                ACCOUNT_USAGE_FACTOR AUF
            WHERE AUF.ACCOUNT_ID(+) = AGG.ACCOUNT_ID
                AND AUF.CASE_ID(+) = GA.BASE_CASE_ID
                AND AGG.SERVICE_DATE BETWEEN AUF.BEGIN_DATE(+) AND NVL(AUF.END_DATE(+), CONSTANTS.HIGH_DATE)
            UNION ALL
            -- Meter Model
            SELECT AGG.AGGREGATE_ID,
                AGG.SERVICE_DATE,
                CASE WHEN AGG.METER_ID = AGG.FIRST_METER THEN AGG.ACCOUNT_ID ELSE NULL END AS SERVICE_ACCOUNT_ID,
                AGG.METER_ID AS SERVICE_METER_ID,
                MUF.FACTOR_VAL AS USAGE_FACTOR
            FROM (SELECT AAE.AGGREGATE_ID, D.COLUMN_VALUE AS SERVICE_DATE, ASL.ACCOUNT_ID, MSA.METER_ID, FIRST_VALUE(MSA.METER_ID) OVER (PARTITION BY ASL.ACCOUNT_ID ORDER BY MSA.METER_ID ASC) AS FIRST_METER
                FROM TABLE(CAST(DATE_UTIL.DATES_IN_INTERVAL_RANGE(p_BEGIN_DATE, p_END_DATE, CONSTANTS.INTERVAL_DAY) AS DATE_COLLECTION)) D,
                    AGGREGATE_ACCOUNT_ESP AAE,
                    ACCOUNT_EDC AEDC,
                    METER_SUB_AGG_AGGREGATION MSA,
                    ACCOUNT_SERVICE_LOCATION ASL,
                    SERVICE_LOCATION_METER SLM
                WHERE D.COLUMN_VALUE BETWEEN AAE.BEGIN_DATE AND NVL(AAE.END_DATE, CONSTANTS.HIGH_DATE)
                    AND (AAE.ESP_ID = p_ESP_ID OR CONSTANTS.ALL_ID = p_ESP_ID)
                    AND AEDC.ACCOUNT_ID = AAE.ACCOUNT_ID
                    AND D.COLUMN_VALUE BETWEEN AEDC.BEGIN_DATE AND NVL(AEDC.END_DATE, CONSTANTS.HIGH_DATE)
                    AND (AEDC.EDC_ID = p_EDC_ID OR CONSTANTS.ALL_ID = p_EDC_ID)
                    AND MSA.AGGREGATE_ID = AAE.AGGREGATE_ID
                    AND D.COLUMN_VALUE BETWEEN MSA.BEGIN_DATE AND NVL(MSA.END_DATE, CONSTANTS.HIGH_DATE)
                    AND SLM.METER_ID = MSA.METER_ID
                    AND D.COLUMN_VALUE BETWEEN SLM.BEGIN_DATE AND NVL(SLM.END_DATE, CONSTANTS.HIGH_DATE)
                    AND ASL.SERVICE_LOCATION_ID = SLM.SERVICE_LOCATION_ID
                    AND D.COLUMN_VALUE BETWEEN SLM.BEGIN_DATE AND NVL(SLM.END_DATE, CONSTANTS.HIGH_DATE)) AGG,
                METER_USAGE_FACTOR MUF
            WHERE MUF.METER_ID(+) = AGG.METER_ID
                AND MUF.CASE_ID(+) = GA.BASE_CASE_ID
                AND AGG.SERVICE_DATE BETWEEN MUF.BEGIN_DATE(+) AND NVL(MUF.END_DATE(+), CONSTANTS.HIGH_DATE)
            ) X
        GROUP BY X.AGGREGATE_ID, X.SERVICE_DATE) VAL
    ON (AAS.CASE_ID = GA.BASE_CASE_ID
        AND AAS.AGGREGATE_ID = VAL.AGGREGATE_ID
        AND AAS.SERVICE_DATE = VAL.SERVICE_DATE
        AND AAS.AS_OF_DATE = CONSTANTS.LOW_DATE)
    WHEN MATCHED THEN
        UPDATE SET AAS.SERVICE_ACCOUNTS = VAL.SERVICE_ACCOUNTS, AAS.USAGE_FACTOR = VAL.USAGE_FACTOR, AAS.ENROLLED_ACCOUNTS = VAL.ENROLLED_ACCOUNTS
    WHEN NOT MATCHED THEN
        INSERT VALUES (GA.BASE_CASE_ID, VAL.AGGREGATE_ID, VAL.SERVICE_DATE, CONSTANTS.LOW_DATE, VAL.SERVICE_ACCOUNTS, VAL.ENROLLED_ACCOUNTS, VAL.USAGE_FACTOR);

    p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;
    LOGS.STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);
    COMMIT;
EXCEPTION
      WHEN OTHERS THEN
    ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'BEFORE_CAL_AGG_ACC_ENROLLMENT');
END CAL_AGG_ACCOUNT_ENROLLMENT;
--------------------------------------------------------------------------------
PROCEDURE CAL_AGG_ACCOUNT_SERVICE_CONS
    (
    p_BEGIN_DATE DATE,
    p_END_DATE DATE,
    p_EDC_ID NUMBER,
    p_ESP_ID NUMBER,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_CONSUMPTION_ID NUMBER(9);

BEGIN
    SAVEPOINT BEFORE_CAL_AGG_ACCOUNT_SC;

    LOGS.START_PROCESS('Calculate Aggregate Account Service Consumption', p_BEGIN_DATE, p_END_DATE, p_TRACE_ON => p_TRACE_ON);
    LOGS.SET_PROCESS_TARGET_PARAMETER('EDC',CASE WHEN p_EDC_ID = CONSTANTS.ALL_ID THEN CONSTANTS.ALL_STRING ELSE TEXT_UTIL.TO_CHAR_ENTITY(p_EDC_ID, EC.ED_EDC) END);
    LOGS.SET_PROCESS_TARGET_PARAMETER('ESP',CASE WHEN p_ESP_ID = CONSTANTS.ALL_ID THEN CONSTANTS.ALL_STRING ELSE TEXT_UTIL.TO_CHAR_ENTITY(p_ESP_ID, EC.ED_ESP) END);

    -- FIRST, DELETE ALL OVERLAPPING SERVICE_CONSUMPTION RECORDS
    -- FOR THIS DATE RANGE / EDC / ESP
    DELETE FROM SERVICE_CONSUMPTION SC
    WHERE SC.BEGIN_DATE <= p_END_DATE
      AND SC.END_DATE >= p_BEGIN_DATE
      AND SC.SERVICE_ID IN (
              SELECT S.SERVICE_ID
              FROM ACCOUNT_SERVICE ASER,
                   SERVICE S,
                   PROVIDER_SERVICE PS
              WHERE NVL(ASER.AGGREGATE_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
                AND ASER.ACCOUNT_SERVICE_ID = S.ACCOUNT_SERVICE_ID
                AND S.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
                AND p_ESP_ID IN (PS.ESP_ID, CONSTANTS.ALL_ID)
                AND p_EDC_ID IN (PS.EDC_ID, CONSTANTS.ALL_ID)
          )
    ;
        
    
    FOR v_REC IN (SELECT C.AGGREGATE_ID,
                        C.ACCOUNT_ID,
                        C.SERVICE_LOCATION_ID,
                        C.SCENARIO_ID,
                        C.BEGIN_DATE,
                        C.END_DATE,
                        C.BILL_CODE,
                        C.CONSUMPTION_CODE,
                        C.TEMPLATE_ID,
                        C.PERIOD_ID,
                        C.UNIT_OF_MEASUREMENT,
                        C.BILL_CYCLE_MONTH,
                        SUM(C.BILLED_USAGE) AS BILLED_USAGE,
                        SUM(C.BILLED_DEMAND) AS BILLED_DEMAND,
                        SUM(C.METERED_USAGE) AS METERED_USAGE,
                        SUM(C.METERED_DEMAND) AS METERED_DEMAND,
                        SUM(C.METERS_READ) AS METERS_READ
                            -- INCLUDE SERVICE_ID IN THE SUB-QUERY AND USE UNION
                            -- SINCE IT'S POSSIBLE TO HAVE THE SAME SERVICE_CONSUMPTION
                            -- RECORD CAN BE PICKED TWICE IF IT OVERLAPS TWO
                            -- SUB_AGG_AGGREAGTION RECORDS THAT ARE BOTH WITHIN THE DATE RANGE
                            -- INCLUDING SERVICE_ID GETS US THE FULL PK OF SERVICE_CONSUMPTION
                            -- AND USING UNION GETS US THE DISTINCT SET
                  FROM (SELECT ASUB.AGGREGATE_ID,
                               ASL.ACCOUNT_ID,
                               ASL.SERVICE_LOCATION_ID,
                               S.SERVICE_ID,
                               S.SCENARIO_ID,
                               SC.BEGIN_DATE,
                               SC.END_DATE,
                               SC.BILL_CODE,
                               SC.CONSUMPTION_CODE,
                               SC.TEMPLATE_ID,
                               SC.PERIOD_ID,
                               SC.UNIT_OF_MEASUREMENT,
                               SC.BILL_CYCLE_MONTH,
                               SC.BILLED_USAGE,
                               SC.BILLED_DEMAND,
                               SC.METERED_USAGE,
                               SC.METERED_DEMAND,
                               SC.METERS_READ
                  FROM SERVICE S,
                        SERVICE_CONSUMPTION SC,
                        ACCOUNT_SERVICE A,
                        ACCOUNT_SUB_AGG_AGGREGATION ASUB,
                        AGGREGATE_ACCOUNT_ESP AAE,
                        ACCOUNT_EDC AE,
                        ACCOUNT_SERVICE_LOCATION ASL
                  WHERE ASUB.BEGIN_DATE <= p_END_DATE
                    AND NVL(ASUB.END_DATE,CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                    AND AAE.AGGREGATE_ID = ASUB.AGGREGATE_ID
                    AND p_ESP_ID IN (AAE.ESP_ID, CONSTANTS.ALL_ID)
                    AND AE.ACCOUNT_ID = AAE.ACCOUNT_ID
                    AND p_EDC_ID IN (AE.EDC_ID, CONSTANTS.ALL_ID)
                    AND A.ACCOUNT_ID = ASUB.ACCOUNT_ID
                    AND S.ACCOUNT_SERVICE_ID = A.ACCOUNT_SERVICE_ID
                    AND SC.SERVICE_ID = S.SERVICE_ID
                    AND SC.BEGIN_DATE <= LEAST(p_END_DATE, NVL(ASUB.END_DATE,CONSTANTS.HIGH_DATE))
                    AND SC.END_DATE >= GREATEST(p_BEGIN_DATE, ASUB.BEGIN_DATE)
                    AND NVL(SC.IGNORE_CONSUMPTION,0) = 0
                    AND ASL.ACCOUNT_ID = AAE.ACCOUNT_ID
                    AND SC.END_DATE BETWEEN ASL.BEGIN_DATE AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE)

           UNION

                  SELECT MSUB.AGGREGATE_ID,
                               ASL.ACCOUNT_ID,
                               ASL.SERVICE_LOCATION_ID,
                               S.SERVICE_ID,
                               S.SCENARIO_ID,
                               SC.BEGIN_DATE,
                               SC.END_DATE,
                               SC.BILL_CODE,
                               SC.CONSUMPTION_CODE,
                               SC.TEMPLATE_ID,
                               SC.PERIOD_ID,
                               SC.UNIT_OF_MEASUREMENT,
                               SC.BILL_CYCLE_MONTH,
                               SC.BILLED_USAGE,
                               SC.BILLED_DEMAND,
                               SC.METERED_USAGE,
                               SC.METERED_DEMAND,
                               SC.METERS_READ
                  FROM SERVICE S,
                        SERVICE_CONSUMPTION SC,
                        ACCOUNT_SERVICE A,
                        METER_SUB_AGG_AGGREGATION MSUB,
                        AGGREGATE_ACCOUNT_ESP AAE,
                        ACCOUNT_EDC AE,
                        ACCOUNT_SERVICE_LOCATION ASL
                  WHERE MSUB.BEGIN_DATE <= p_END_DATE
                    AND NVL(MSUB.END_DATE,CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                    AND AAE.AGGREGATE_ID = MSUB.AGGREGATE_ID
                    AND p_ESP_ID IN (AAE.ESP_ID, CONSTANTS.ALL_ID)
                    AND AE.ACCOUNT_ID = AAE.ACCOUNT_ID
                    AND p_EDC_ID IN (AE.EDC_ID, CONSTANTS.ALL_ID)
                    AND A.METER_ID = MSUB.METER_ID
                    AND S.ACCOUNT_SERVICE_ID = A.ACCOUNT_SERVICE_ID
                    AND SC.SERVICE_ID = S.SERVICE_ID
                    AND SC.BEGIN_DATE <= LEAST(p_END_DATE, NVL(MSUB.END_DATE,CONSTANTS.HIGH_DATE))
                    AND SC.END_DATE >= GREATEST(p_BEGIN_DATE, MSUB.BEGIN_DATE)
                    AND NVL(SC.IGNORE_CONSUMPTION,0) = 0
                    AND ASL.ACCOUNT_ID = AAE.ACCOUNT_ID
                    AND SC.END_DATE BETWEEN ASL.BEGIN_DATE AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE)) C
           GROUP BY C.ACCOUNT_ID, C.SERVICE_LOCATION_ID, C.AGGREGATE_ID, C.SCENARIO_ID, C.BEGIN_DATE,
                C.END_DATE, C.BILL_CODE, C.CONSUMPTION_CODE, C.TEMPLATE_ID, C.PERIOD_ID,
                C.UNIT_OF_MEASUREMENT, C.BILL_CYCLE_MONTH ) LOOP

            MS.PUT_SERVICE_CONSUMPTION(v_REC.SCENARIO_ID,
                                       v_REC.ACCOUNT_ID,
                                       v_REC.SERVICE_LOCATION_ID,
                                       CONSTANTS.NOT_ASSIGNED, -- METER_ID
                                        v_REC.BEGIN_DATE,
                                        v_REC.END_DATE,
                                        v_REC.BILL_CODE,
                                        v_REC.CONSUMPTION_CODE,
                                        CASE WHEN v_REC.BILL_CYCLE_MONTH IS NULL
                                            THEN SYSDATE
                                            ELSE LAST_DAY(v_REC.BILL_CYCLE_MONTH) END,
                                        v_REC.TEMPLATE_ID,
                                        v_REC.PERIOD_ID,
                                        v_REC.UNIT_OF_MEASUREMENT,
                                        'P', -- METER TYPE
                                        NULL, -- METER READING
                                        v_REC.BILLED_USAGE,
                                        v_REC.BILLED_DEMAND,
                                        v_REC.METERED_USAGE,
                                        v_REC.METERED_DEMAND,
                                        v_REC.METERS_READ,
                                        NULL, -- CONVERSION FACTOR
                                        0, -- IGNORE CONSUMPTION
                                        v_REC.BILL_CYCLE_MONTH,
                                        NULL, -- BILL PROCESSED DATE
                                        v_REC.BEGIN_DATE, -- READ BEGIN DATE
                                        v_REC.END_DATE, -- READ END DATE
                                        v_CONSUMPTION_ID,
                                        TRUE, -- PERFORM VALIDATION
                                        v_REC.AGGREGATE_ID);
    END LOOP;

    COMMIT;
    p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;
    LOGS.STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);

EXCEPTION
    WHEN OTHERS THEN
    ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'BEFORE_CAL_AGG_ACCOUNT_SC');
END CAL_AGG_ACCOUNT_SERVICE_CONS;
------------------------------------------------------------------------------
FUNCTION ENSURE_AGGREGATE_ACCOUNT_SIMPL
  (
  p_EDC_ID              IN NUMBER,
  p_CALENDAR_ID         IN NUMBER,
  p_METER_TYPE          IN VARCHAR2,
  p_MODEL_ID        IN NUMBER,
  p_SCHEDULE_GROUP_ID   IN NUMBER,
  p_WEATHER_STATION_ID  IN NUMBER,
  p_LOSS_FACTOR_ID      IN NUMBER,
  p_EDC_RATE_CLASS      IN VARCHAR2,
  p_EDC_STRATA          IN VARCHAR2,
  p_AGGREGATION_GROUP   IN VARCHAR2,
  p_RESET_DATES         IN NUMBER := 1
  ) RETURN NUMBER AS
v_AGGREGATE_ACCOUNT_ID   ACCOUNT.ACCOUNT_ID%TYPE;
v_SERVICE_LOCATION_ID   SERVICE_LOCATION.SERVICE_LOCATION_ID%TYPE;
v_RESET_DATES        NUMBER := 1;
BEGIN
  -- Validation
  ASSERT(NVL(p_EDC_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
       'EDC Id must be non-null and greater than 0. Id = ' || p_EDC_ID,
       MSGCODES.c_ERR_ARGUMENT);
  ASSERT(NVL(p_CALENDAR_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
       'Calendar Id must be non-null and greater than 0. Id = ' || p_CALENDAR_ID,
       MSGCODES.c_ERR_ARGUMENT);
  ASSERT(NVL(p_METER_TYPE,CONSTANTS.NOT_ASSIGNED_STRING) IN (CONSTANTS.METER_TYPE_INTERVAL, CONSTANTS.METER_TYPE_PERIOD),
       'Meter Type must be ' || CONSTANTS.METER_TYPE_INTERVAL || ' or ' || CONSTANTS.METER_TYPE_PERIOD || '. Meter Type = ' || p_METER_TYPE,
       MSGCODES.c_ERR_ARGUMENT);
    ASSERT(NVL(p_MODEL_ID,CONSTANTS.NOT_ASSIGNED) IN (CONSTANTS.ELECTRIC_MODEL, CONSTANTS.GAS_MODEL),
       'Model Id  must be ' || CONSTANTS.ELECTRIC_MODEL || ' or ' || CONSTANTS.GAS_MODEL || '. Id = ' || p_MODEL_ID,
       MSGCODES.c_ERR_ARGUMENT);
   ASSERT(NVL(p_SCHEDULE_GROUP_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
       'Schedule Group Id must be non-null and greater than 0. Id = ' || p_SCHEDULE_GROUP_ID,
       MSGCODES.c_ERR_ARGUMENT);
   ASSERT(NVL(p_WEATHER_STATION_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
       'Weather Station Id must be non-null and greater than 0. Id = ' || p_WEATHER_STATION_ID,
       MSGCODES.c_ERR_ARGUMENT);
   ASSERT(NVL(p_LOSS_FACTOR_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
       'Loss Factor Id must be non-null and greater than 0. Id = ' || p_LOSS_FACTOR_ID,
       MSGCODES.c_ERR_ARGUMENT);
  ASSERT(p_EDC_RATE_CLASS IS NOT NULL,
       'EDC Rate Class must be non-null. EDC Rate Class = ' || p_EDC_RATE_CLASS,
       MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_EDC_STRATA IS NOT NULL,
       'EDC Strata must be non-null. EDC Strata = ' || p_EDC_STRATA,
       MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_AGGREGATION_GROUP IS NOT NULL,
       'Aggregation Group must be non-null. Aggregation Group = ' || p_AGGREGATION_GROUP,
       MSGCODES.c_ERR_ARGUMENT);


  v_RESET_DATES := NVL(p_RESET_DATES, 1);

  -- Look for existing Aggregate Account
  BEGIN
    SELECT A.AGGREGATE_ACCOUNT_ID, A.SERVICE_LOCATION_ID
    INTO v_AGGREGATE_ACCOUNT_ID, v_SERVICE_LOCATION_ID
    FROM ACCOUNT_AGGREGATE_STATIC_DATA A
    WHERE A.EDC_ID = p_EDC_ID
      AND A.CALENDAR_ID = p_CALENDAR_ID
      AND A.METER_TYPE = p_METER_TYPE
          AND A.MODEL_ID = p_MODEL_ID
      AND p_SCHEDULE_GROUP_ID = A.SCHEDULE_GROUP_ID
      AND p_WEATHER_STATION_ID = A.WEATHER_STATION_ID
      AND p_LOSS_FACTOR_ID = A.LOSS_FACTOR_ID
      AND A.EDC_RATE_CLASS = p_EDC_RATE_CLASS
      AND EDC_STRATA = p_EDC_STRATA
      AND A.AGGREGATION_GROUP = p_AGGREGATION_GROUP;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_RESET_DATES := 1;
      CREATE_AGGREGATE_ACCOUNT(v_AGGREGATE_ACCOUNT_ID,v_SERVICE_LOCATION_ID,p_EDC_ID,p_CALENDAR_ID,p_METER_TYPE,p_MODEL_ID,NULL,NULL,p_SCHEDULE_GROUP_ID,p_WEATHER_STATION_ID,p_LOSS_FACTOR_ID,NULL,NULL,NULL,NULL,p_EDC_RATE_CLASS,p_EDC_STRATA,p_AGGREGATION_GROUP);
  END;

  IF v_RESET_DATES = 1 THEN
    RESET_AGGREGATE_ACCOUNT_DATES(v_AGGREGATE_ACCOUNT_ID,v_SERVICE_LOCATION_ID,p_EDC_ID,p_CALENDAR_ID,p_SCHEDULE_GROUP_ID,p_LOSS_FACTOR_ID,NULL,NULL,NULL,NULL,p_EDC_RATE_CLASS,p_EDC_STRATA,p_AGGREGATION_GROUP);
  END IF;

  RETURN v_AGGREGATE_ACCOUNT_ID;

END ENSURE_AGGREGATE_ACCOUNT_SIMPL;
-------------------------------------------------------------------------------
PROCEDURE RUN_AGGREGATION_IMPL_SIMPLE
    (
    p_ACCOUNT_IDs IN NUMBER_COLLECTION,
    p_EDC_IDs IN NUMBER_COLLECTION,
    p_ESP_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_RESET_DATES IN NUMBER,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_ACCT_AGG_ATT_ID NUMBER(9);

    v_TARGET_PARAMS UT.STRING_MAP;

    v_ACCOUNT_ID NUMBER(9);

    -- HIGH DATE MINUS ONE USED IN THE QUERY WHERE WE ADD 1 TO THE END DATE TO MAKE SURE
    -- WE DON'T ACCIDENTALLY GO OUT OF THE VALID DATE RANGE
    v_HD_MINUS_ONE DATE := HIGH_DATE - 1;

    v_METER_IDS NUMBER_COLLECTION;
    v_METER_ID NUMBER(9);

    -- WE ADD 1 TO THE p_END_DATE, SO SUBTRACT ONE FOR HIGH_DATE
    v_END_DATE DATE := CASE WHEN NVL(p_END_DATE,CONSTANTS.HIGH_DATE) = CONSTANTS.HIGH_DATE THEN CONSTANTS.HIGH_DATE-1 ELSE p_END_DATE END;

    v_TEST PLS_INTEGER;
  v_NUM_ACCOUNTS NUMBER(9) := 0;
  v_ACCOUNT_INDEX NUMBER(9) := 1;

  v_ACCOUNT_IDS NUMBER_COLLECTION := p_ACCOUNT_IDS;
  
    TYPE t_EDC_TBL IS TABLE OF RTO_WORK%ROWTYPE;
    v_EDC_TBL t_EDC_TBL := t_EDC_TBL();
    v_WORK_ID INTEGER;
  
  v_HIGH_DATE DATE := CONSTANTS.HIGH_DATE;
BEGIN
    SAVEPOINT BEFORE_AGGREGATION;
    LOGS.START_PROCESS('Account Aggregation(Simple)', p_BEGIN_DATE, v_END_DATE, p_TRACE_ON => p_TRACE_ON);

  -- At least 1 account should be specified to run
   ASSERT(p_ACCOUNT_IDs IS NOT NULL AND p_ACCOUNT_IDs.COUNT > 0, 'At least one Account must be specified to RUN_AGGREGATION', MSGCODES.c_ERR_ARGUMENT);
  -- At least 1 EDC must be specified to run
  ASSERT(p_EDC_IDs IS NOT NULL AND p_EDC_IDs.COUNT > 0, 'At least one EDC must be specified to RUN_AGGREGATION', MSGCODES.c_ERR_ARGUMENT);

    SELECT COUNT(1)
    INTO v_TEST
    FROM TABLE(CAST(p_ACCOUNT_IDs AS NUMBER_COLLECTION)) X
    WHERE X.COLUMN_VALUE = CONSTANTS.ALL_ID;

    IF v_TEST > 0 AND p_ACCOUNT_IDs.COUNT > 1 THEN
        ERRS.RAISE_BAD_ARGUMENT('ACCOUNT_IDS',TEXT_UTIL.TO_CHAR_ENTITY_LIST(p_ACCOUNT_IDs,EC.ED_ACCOUNT),
            'The Account ID list cannot have any other items if it contains the "All" ID (' || CONSTANTS.ALL_ID || ').');
    END IF;
  
    LOGS.SET_PROCESS_TARGET_PARAMETER('EDCs',TEXT_UTIL.TO_CHAR_ENTITY_LIST(p_EDC_IDs, EC.ED_EDC));
    LOGS.SET_PROCESS_TARGET_PARAMETER('ESP',CASE WHEN p_ESP_ID = CONSTANTS.ALL_ID THEN 'All' ELSE TEXT_UTIL.TO_CHAR_ENTITY(p_ESP_ID, EC.ED_ESP) END);
    LOGS.SET_PROCESS_TARGET_PARAMETER('RESET_DATES',p_RESET_DATES);

    ID.ID_FOR_ENTITY_ATTRIBUTE(ACCOUNTS_METERS.c_AGGREGATION_GROUP_ENT_ATTR, EC.ED_ACCOUNT, 'String', FALSE, v_ACCT_AGG_ATT_ID);

  IF p_ACCOUNT_IDs.COUNT = 1 AND p_ACCOUNT_IDs(1) = CONSTANTS.ALL_ID THEN
    -- All Accounts, need to fetch the number of accounts for progress tracking
    SELECT COUNT(DISTINCT A.ACCOUNT_NAME)
    INTO v_NUM_ACCOUNTS
    FROM ACCOUNT A,
      ACCOUNT_EDC EDC,
      ACCOUNT_ESP ESP,
      ACCOUNT_STATUS S,
      ACCOUNT_STATUS_NAME ASN
    WHERE A.ACCOUNT_MODEL_OPTION IN (ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER,
                     ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT)
      AND A.IS_SUB_AGGREGATE = 1
      AND A.MODEL_ID IS NOT NULL AND A.MODEL_ID IN (GA.GAS_MODEL, GA.ELECTRIC_MODEL)
      AND EDC.ACCOUNT_ID = A.ACCOUNT_ID
      AND EDC.EDC_ID IN (SELECT COLUMN_VALUE FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)))
      AND ESP.ACCOUNT_ID = A.ACCOUNT_ID
      AND p_ESP_ID IN (ESP.ESP_ID, CONSTANTS.ALL_ID)
      AND S.ACCOUNT_ID = A.ACCOUNT_ID
      AND ASN.STATUS_NAME = S.STATUS_NAME
      AND ASN.IS_ACTIVE = 1
      AND GREATEST(EDC.BEGIN_DATE,ESP.BEGIN_DATE,p_BEGIN_DATE,S.BEGIN_DATE)
       <= LEAST(NVL(EDC.END_DATE,v_END_DATE),NVL(ESP.END_DATE,v_END_DATE),
          NVL(S.END_DATE,v_END_DATE),v_END_DATE);
  ELSE
    v_ACCOUNT_IDs  := SET (p_ACCOUNT_IDs); -- get the unique ACCOUNT_IDs
      v_NUM_ACCOUNTS := v_ACCOUNT_IDs.COUNT;
  END IF;

  LOGS.INIT_PROCESS_PROGRESS(p_TOTAL_WORK => v_NUM_ACCOUNTS);
 
  -- Pre-process call to delete current Sub-Aggregate to Aggregate relationships.
  -- Relationships are recreated depending on the present parameters.
  DEL_CURRENT_SUB_AGG_AGGREGATES(v_ACCOUNT_IDs,
                                 p_EDC_IDs,
                                 p_ESP_ID,
                                 p_BEGIN_DATE,
                                 p_END_DATE);
   
  -- list of EDCs straight from the NUMBER_COLLECTION. For performance reasons RTO_WORK table used
  UT.GET_RTO_WORK_ID(v_WORK_ID);
  FOR I IN 1..p_EDC_IDS.COUNT LOOP
     v_EDC_TBL.EXTEND(1);
     v_EDC_TBL(I).WORK_ID := v_WORK_ID;
     v_EDC_TBL(I).WORK_SEQ := NULL;
     v_EDC_TBL(I).WORK_XID  := p_EDC_IDS(I);
     v_EDC_TBL(I).WORK_DATE := NULL;
     v_EDC_TBL(I).WORK_DATA := NULL;
     v_EDC_TBL(I).WORK_DATA2 := NULL;     
  END LOOP;  
  FORALL I IN 1..v_EDC_TBL.COUNT
      INSERT INTO RTO_WORK VALUES v_EDC_TBL(I);

    -- Main OUTER cursor loop   
  FOR v_ACCT_REC IN (
             $IF $$UNIT_TEST_MODE=1 $THEN
               SELECT ACCOUNT_ID, ACCOUNT_MODEL_OPTION, ACCOUNT_NAME, ACCOUNT_METER_TYPE, MODEL_ID FROM(
             $END
                        SELECT DISTINCT A.ACCOUNT_ID, A.ACCOUNT_MODEL_OPTION, A.ACCOUNT_NAME, A.ACCOUNT_METER_TYPE, A.MODEL_ID
                        FROM ACCOUNT A,
                            TABLE(CAST(p_ACCOUNT_IDs AS NUMBER_COLLECTION)) X,
                            ACCOUNT_EDC EDC,
                            ACCOUNT_ESP ESP,
                            ACCOUNT_STATUS S,
                            ACCOUNT_STATUS_NAME ASN
                        WHERE X.COLUMN_VALUE IN (A.ACCOUNT_ID, CONSTANTS.ALL_ID)
                            AND A.ACCOUNT_MODEL_OPTION IN (ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER,
                                                           ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT)
                            AND A.IS_SUB_AGGREGATE = 1
                            AND A.MODEL_ID IS NOT NULL AND A.MODEL_ID IN (GA.GAS_MODEL, GA.ELECTRIC_MODEL)
                            AND EDC.ACCOUNT_ID = A.ACCOUNT_ID
                            AND EDC.EDC_ID IN (SELECT COLUMN_VALUE FROM TABLE(CAST(p_EDC_IDs AS NUMBER_COLLECTION)))
                            AND ESP.ACCOUNT_ID = A.ACCOUNT_ID
                            AND p_ESP_ID IN (ESP.ESP_ID, CONSTANTS.ALL_ID)
                            AND S.ACCOUNT_ID = A.ACCOUNT_ID
                            AND ASN.STATUS_NAME = S.STATUS_NAME
                            AND ASN.IS_ACTIVE = 1

                            AND GREATEST(EDC.BEGIN_DATE,ESP.BEGIN_DATE,p_BEGIN_DATE,S.BEGIN_DATE)
                             <= LEAST(NVL(EDC.END_DATE,v_END_DATE),NVL(ESP.END_DATE,v_END_DATE),
                                    NVL(S.END_DATE,v_END_DATE),v_END_DATE)
                        $IF $$UNIT_TEST_MODE=1 $THEN
                            ) ORDER BY ACCOUNT_NAME
                        $END
                      ) LOOP

    LOGS.UPDATE_PROCESS_PROGRESS(NULL, p_PROGRESS_DESCRIPTION => 'Processing Account ' || v_ACCOUNT_INDEX || ' of ' || v_NUM_ACCOUNTS || ': ' || EI.GET_ENTITY_IDENTIFIER(EC.ED_ACCOUNT, v_ACCT_REC.ACCOUNT_ID, 1));

        -- TO SIMPLIFY THE QUERIES (AS MUCH AS IS POSSIBLE) WE HAVE SEPARATE LOOPS FOR THE ACCOUNT MODELED AND METER MODELED ACCOUNTS
    IF v_ACCT_REC.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT AND
       v_ACCT_REC.ACCOUNT_METER_TYPE IN (ACCOUNTS_METERS.c_METER_TYPE_INTERVAL, ACCOUNTS_METERS.c_METER_TYPE_PERIOD) THEN
       FOR v_REC IN (
					WITH AST AS (SELECT *
								 FROM ACCOUNT_STATUS A, ACCOUNT_STATUS_NAME B
								 WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
								 AND A.STATUS_NAME = B.STATUS_NAME
								 AND B.IS_ACTIVE = 1),
						  -- Change - Add inline view
						  AEDC AS ( SELECT *
									FROM ACCOUNT_EDC A, 
										 RTO_WORK RW
									WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
									AND RW.WORK_ID = v_WORK_ID
									AND A.EDC_ID = RW.WORK_XID)
											SELECT  /*+ ORDERED */ v_ACCT_REC.ACCOUNT_ID,
																  AEDC.EDC_ID,
																  AEDC.EDC_RATE_CLASS,
																  AEDC.EDC_STRATA,
																  AESP.ESP_ID,
																  AESP.POOL_ID,
																  ACAL.CALENDAR_ID,
																  UPPER(SUBSTR(v_ACCT_REC.ACCOUNT_METER_TYPE,1,1)) AS ACCOUNT_METER_TYPE,
																  v_ACCT_REC.MODEL_ID MODEL_ID,
																  ALF.LOSS_FACTOR_ID,
																  SL.WEATHER_STATION_ID,
																  ASG.SCHEDULE_GROUP_ID,
																  TEA.ATTRIBUTE_VAL AGGREGATION_GROUP,
																  GREATEST(p_BEGIN_DATE,
																		   AEDC.BEGIN_DATE,
																		   ACAL.BEGIN_DATE,
																		   ASG.BEGIN_DATE,
																		   ALF.BEGIN_DATE,
																		   AESP.BEGIN_DATE,
																		   ASL.BEGIN_DATE,
																		   TEA.BEGIN_DATE) BEGIN_DATE,
																  LEAST(v_END_DATE,
																		NVL(AEDC.END_DATE, v_HIGH_DATE),
																		NVL(ACAL.END_DATE, v_HIGH_DATE),
																		NVL(ASG.END_DATE,  v_HIGH_DATE),
																		NVL(ALF.END_DATE,  v_HIGH_DATE),
																		NVL(AESP.END_DATE, v_HIGH_DATE),
																		NVL(ASL.END_DATE,  v_HIGH_DATE),
																		NVL(TEA.END_DATE,  v_HIGH_DATE)) END_DATE
											FROM  -- Change - Table order
												  AST,							  
												  AEDC,
												  ACCOUNT_CALENDAR ACAL,
												  ACCOUNT_SCHEDULE_GROUP ASG,
												  ACCOUNT_LOSS_FACTOR ALF,
												  ACCOUNT_ESP AESP,							  
												  ACCOUNT_SERVICE_LOCATION ASL,
												  SERVICE_LOCATION SL,
												  TEMPORAL_ENTITY_ATTRIBUTE TEA
											WHERE AST.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
												  AND AST.BEGIN_DATE <= v_END_DATE -- v_END
												  AND NVL(AST.END_DATE, v_HIGH_DATE) >= p_BEGIN_DATE -- v_BEGIN							  
												  -- Change - Add additional where clause
												  AND AEDC.ACCOUNT_ID = AST.ACCOUNT_ID							  
												  AND AEDC.BEGIN_DATE <= LEAST(v_END_DATE,  NVL(AST.END_DATE, v_HIGH_DATE)) -- Needs v_END and v_BEGIN in every LEAST/GREATEST
												  AND NVL(AEDC.END_DATE, v_HIGH_DATE) >= GREATEST(p_BEGIN_DATE,AST.BEGIN_DATE)							  
												  AND ACAL.ACCOUNT_ID = AEDC.ACCOUNT_ID
												  AND ACAL.CASE_ID = GA.BASE_CASE_ID
												  AND ACAL.CALENDAR_TYPE = 'Forecast'
												  AND ACAL.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE)) -- Needs v_END and v_BEGIN in every LEAST/GREATEST
												  AND NVL(ACAL.END_DATE, v_HIGH_DATE) >= GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE)
												  AND ASG.ACCOUNT_ID = ACAL.ACCOUNT_ID
												  AND ASG.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(ACAL.END_DATE, v_HIGH_DATE))
												  AND NVL(ASG.END_DATE, v_HIGH_DATE)  >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE,ACAL.BEGIN_DATE)
												  AND ALF.ACCOUNT_ID = ASG.ACCOUNT_ID
												  AND ALF.CASE_ID = GA.BASE_CASE_ID
												  AND ALF.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(ACAL.END_DATE, v_HIGH_DATE), NVL(ASG.END_DATE, v_HIGH_DATE))
												  AND NVL(ALF.END_DATE, v_HIGH_DATE) >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE,ACAL.BEGIN_DATE,ASG.BEGIN_DATE)
												  AND AESP.ACCOUNT_ID = ALF.ACCOUNT_ID
												  AND AESP.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE),NVL(ACAL.END_DATE, v_HIGH_DATE), NVL(ASG.END_DATE, v_HIGH_DATE), NVL(ALF.END_DATE, v_HIGH_DATE))
												  AND NVL(AESP.END_DATE, v_HIGH_DATE) >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE,ACAL.BEGIN_DATE,ASG.BEGIN_DATE,ALF.BEGIN_DATE)
												  AND p_ESP_ID IN (CONSTANTS.ALL_ID, AESP.ESP_ID)
												  AND ASL.ACCOUNT_ID = AESP.ACCOUNT_ID
												  AND ASL.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE),NVL(ACAL.END_DATE, v_HIGH_DATE),NVL(ASG.END_DATE, v_HIGH_DATE), NVL(ALF.END_DATE, v_HIGH_DATE), NVL(AESP.END_DATE, v_HIGH_DATE))
												  AND NVL(ASL.END_DATE, v_HIGH_DATE) >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE,ACAL.BEGIN_DATE,ASG.BEGIN_DATE,ALF.BEGIN_DATE, AESP.BEGIN_DATE)
												  AND ASL.SERVICE_LOCATION_ID = SL.SERVICE_LOCATION_ID
												  AND TEA.OWNER_ENTITY_ID = AESP.ACCOUNT_ID
												  AND TEA.ENTITY_DOMAIN_ID = EC.ED_ACCOUNT
												  AND TEA.ATTRIBUTE_ID = v_ACCT_AGG_ATT_ID
												  AND TEA.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(ACAL.END_DATE, v_HIGH_DATE), NVL(ASG.END_DATE, v_HIGH_DATE), NVL(ALF.END_DATE, v_HIGH_DATE), NVL(AESP.END_DATE, v_HIGH_DATE), NVL(ASL.END_DATE, v_HIGH_DATE))
												  AND NVL(TEA.END_DATE, v_HIGH_DATE) >= GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE,ACAL.BEGIN_DATE,ASG.BEGIN_DATE,ALF.BEGIN_DATE, AESP.BEGIN_DATE, ASL.BEGIN_DATE)
												  -- As per FSpec - if mandatory parameters aren't present, continue silently
												  -- without raising any errors or warnings
												  AND TRIM(TEA.ATTRIBUTE_VAL) IS NOT NULL
												  AND TRIM(AEDC.EDC_STRATA) IS NOT NULL
												  AND TRIM(AEDC.EDC_RATE_CLASS) IS NOT NULL
												  AND NVL(ALF.LOSS_FACTOR_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
												  AND NVL(SL.WEATHER_STATION_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
												  AND NVL(ACAL.CALENDAR_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
												  AND NVL(ASG.SCHEDULE_GROUP_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
												  AND NVL(AEDC.EDC_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
       ) LOOP

        LOGS.LOG_DEBUG('For date range ' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_REC.BEGIN_DATE,v_REC.END_DATE) || ', ' ||
                   'ACCOUNT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCT_REC.ACCOUNT_ID, EC.ED_ACCOUNT) || ', ' ||
                   'EDC: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.EDC_ID, EC.ED_EDC) || ', ' ||
                   'EDC STRATA: ' || v_REC.EDC_STRATA || ', ' ||
                   'EDC RATE CLASS: ' || v_REC.EDC_RATE_CLASS || ', ' ||
                   'CALENDAR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.CALENDAR_ID, EC.ED_CALENDAR) || ', ' ||
                   'METER TYPE: ' || v_REC.ACCOUNT_METER_TYPE || ', ' ||
                   'MODEL: ' || CASE WHEN v_REC.MODEL_ID = GA.GAS_MODEL THEN 'Gas' ELSE 'Electric' END || ', ' ||
                   'LOSS FACTOR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.LOSS_FACTOR_ID, EC.ED_LOSS_FACTOR) || ', ' ||
                   'WEATHER STATION: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.WEATHER_STATION_ID, EC.ED_WEATHER_STATION) || ', ' ||
                   'SCHEDULE GROUP: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SCHEDULE_GROUP_ID, EC.ED_SCHEDULE_GROUP) || ', ' ||
                   'AGGREGATION GROUP: ' || v_REC.AGGREGATION_GROUP);                  

         v_ACCOUNT_ID := ENSURE_AGGREGATE_ACCOUNT_SIMPL(v_REC.EDC_ID,
                              v_REC.CALENDAR_ID,
                              v_REC.ACCOUNT_METER_TYPE,
                              v_REC.MODEL_ID,
                              v_REC.SCHEDULE_GROUP_ID,
                              v_REC.WEATHER_STATION_ID,
                              v_REC.LOSS_FACTOR_ID,
                              v_REC.EDC_RATE_CLASS,
                              v_REC.EDC_STRATA,
                              v_REC.AGGREGATION_GROUP,
                              p_RESET_DATES);


          -- MAKE SURE THE AGGREGATE ACCOUNT IS ASSIGNED TO THAT ESP FOR THE DATE RANGE
          ENSURE_ACCOUNT_ESP(v_ACCOUNT_ID,v_REC.ESP_ID,v_REC.POOL_ID,v_REC.BEGIN_DATE,v_REC.END_DATE);
          ENSURE_SUB_AGG_AGGREGATION(v_ACCT_REC.ACCOUNT_ID,ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT,v_REC.BEGIN_DATE,v_REC.END_DATE,v_ACCOUNT_ID,
                        v_REC.ESP_ID,v_REC.POOL_ID);

          LOGS.LOG_DEBUG('Account for static data: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT));
       END LOOP; -- ACCOUNT MODELED sub-aggregate accounts aggregation

       -- ELSE, if this is METER-MODELED sub-aggregate account
       ELSIF v_ACCT_REC.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER THEN
         SELECT DISTINCT M.METER_ID
         BULK COLLECT INTO v_METER_IDS
         FROM ACCOUNT A,
           ACCOUNT_SERVICE_LOCATION ASL,
           SERVICE_LOCATION_METER SLM,
           METER M
         WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
           AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER
           AND ASL.ACCOUNT_ID = A.ACCOUNT_ID
           AND ASL.BEGIN_DATE < v_END_DATE
           AND NVL(ASL.END_DATE,CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
           AND SLM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
           AND SLM.BEGIN_DATE < v_END_DATE
           AND NVL(SLM.END_DATE,CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
           AND M.METER_ID = SLM.METER_ID
           AND M.METER_TYPE IN (ACCOUNTS_METERS.c_METER_TYPE_INTERVAL, ACCOUNTS_METERS.c_METER_TYPE_PERIOD);

       END IF; -- MAIN IF LOOP that bifurcates ACCOUNT v. METER modeled

       -- If this is METER MODELED acct and does have METERS to work on, then...
       IF v_ACCT_REC.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER AND 
          v_METER_IDS IS NOT NULL AND v_METER_IDS.COUNT > 0 THEN
         
         -- Loop around the METERs within the collection
         FOR v_MTR_IDX IN v_METER_IDS.FIRST..v_METER_IDS.LAST LOOP
           v_METER_ID := v_METER_IDS(v_MTR_IDX);
           -- NOW METER-MODELED ACCOUNTS
           FOR v_REC IN (
                 WITH AST AS (
							SELECT *
							FROM ACCOUNT_STATUS A, ACCOUNT_STATUS_NAME B
							WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
							AND a.STATUS_NAME = B.STATUS_NAME
							AND B.IS_ACTIVE = 1),
					AEDC AS (SELECT *
							 FROM ACCOUNT_EDC A, 
								  RTO_WORK RW
							 WHERE A.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
							 AND RW.WORK_ID = v_WORK_ID
							 AND A.EDC_ID = RW.WORK_XID)							 
							  SELECT /*+ ORDERED */ v_ACCT_REC.ACCOUNT_ID,
									 AEDC.EDC_ID,
									 AEDC.EDC_RATE_CLASS,
									 AEDC.EDC_STRATA,					  
									 AESP.ESP_ID,
									 AESP.POOL_ID,
									 M.METER_ID,
									 MCAL.CALENDAR_ID,
									 UPPER(SUBSTR(M.METER_TYPE,1,1)) AS METER_TYPE,
									 v_ACCT_REC.MODEL_ID MODEL_ID,
									 MLF.LOSS_FACTOR_ID,
									 SL.WEATHER_STATION_ID,
									 MSG.SCHEDULE_GROUP_ID,
									 TEA.ATTRIBUTE_VAL AGGREGATION_GROUP,
									 GREATEST(p_BEGIN_DATE,
											  AEDC.BEGIN_DATE,
											  MCAL.BEGIN_DATE,
											  MSG.BEGIN_DATE,
											  MLF.BEGIN_DATE,
											  AESP.BEGIN_DATE,
											  ASL.BEGIN_DATE,
											  TEA.BEGIN_DATE) BEGIN_DATE,
									LEAST(v_END_DATE,
										  NVL(AEDC.END_DATE, v_HIGH_DATE),
										  NVL(MCAL.END_DATE, v_HIGH_DATE),
										  NVL(MSG.END_DATE,  v_HIGH_DATE),
										  NVL(MLF.END_DATE,  v_HIGH_DATE),
										  NVL(AESP.END_DATE, v_HIGH_DATE),
										  NVL(ASL.END_DATE,  v_HIGH_DATE),
										  NVL(TEA.END_DATE,  v_HIGH_DATE)) END_DATE
								 FROM -- CHANGE - TABLE ORDER
									  AST,
									  AEDC,
									  METER M,
									  METER_CALENDAR MCAL,					     
									  METER_SCHEDULE_GROUP MSG,
									  METER_LOSS_FACTOR MLF,					  
									  SERVICE_LOCATION_METER SLM,		
									  ACCOUNT_SERVICE_LOCATION ASL,	 
									  SERVICE_LOCATION SL,		
									  ACCOUNT_ESP AESP,					  			  
									  TEMPORAL_ENTITY_ATTRIBUTE TEA
							  WHERE AST.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
									AND AST.BEGIN_DATE <= v_END_DATE
									AND NVL(AST.END_DATE, v_HIGH_DATE) >= p_BEGIN_DATE			   
									-- NEW WHERE CLAUSE
									AND AEDC.ACCOUNT_ID = AST.ACCOUNT_ID
									AND AEDC.BEGIN_DATE <= LEAST(v_END_DATE,  NVL(AST.END_DATE, v_HIGH_DATE)) -- Needs v_END and v_BEGIN in every LEAST/GREATEST
									AND NVL(AEDC.END_DATE, v_HIGH_DATE) >= GREATEST(p_BEGIN_DATE,AST.BEGIN_DATE)
									-- MCAL
									AND M.METER_ID = v_METER_ID
									AND MCAL.METER_ID = M.METER_ID
									AND MCAL.CALENDAR_TYPE = 'Forecast'
									AND MCAL.CASE_ID = GA.BASE_CASE_ID
									AND MCAL.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE)) -- Needs v_END and v_BEGIN in every LEAST/GREATEST
									AND NVL(MCAL.END_DATE, v_HIGH_DATE) >= GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE)
									-- MSG					  
									AND MSG.METER_ID = MCAL.METER_ID
									AND MSG.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(MCAL.END_DATE, v_HIGH_DATE))
									AND NVL(MSG.END_DATE, v_HIGH_DATE) >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE, MCAL.BEGIN_DATE)
									-- MLF
									AND MLF.METER_ID = MSG.METER_ID
									AND MLF.CASE_ID = GA.BASE_CASE_ID
									AND MLF.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(MCAL.END_DATE, v_HIGH_DATE), NVL(MSG.END_DATE, v_HIGH_DATE))
									AND NVL(MLF.END_DATE, v_HIGH_DATE) >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE, MCAL.BEGIN_DATE,MSG.BEGIN_DATE)
									-- SLM
									AND SLM.METER_ID = MLF.METER_ID
									AND SLM.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(MCAL.END_DATE, v_HIGH_DATE), NVL(MSG.END_DATE, v_HIGH_DATE),  NVL(MLF.END_DATE, v_HIGH_DATE))
									AND NVL(SLM.END_DATE, v_HIGH_DATE) >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE, MCAL.BEGIN_DATE,MSG.BEGIN_DATE, MLF.BEGIN_DATE)
									-- ASL
									AND ASL.ACCOUNT_ID = v_ACCT_REC.ACCOUNT_ID
									AND ASL.SERVICE_LOCATION_ID = SLM.SERVICE_LOCATION_ID
									AND ASL.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(MCAL.END_DATE, v_HIGH_DATE), NVL(MSG.END_DATE, v_HIGH_DATE),  NVL(MLF.END_DATE, v_HIGH_DATE), NVL(SLM.END_DATE, v_HIGH_DATE))
									AND NVL(ASL.END_DATE, v_HIGH_DATE) >= GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE, MCAL.BEGIN_DATE,MSG.BEGIN_DATE, MLF.BEGIN_DATE, SLM.BEGIN_DATE)
									AND ASL.SERVICE_LOCATION_ID = SL.SERVICE_LOCATION_ID
									-- AESP
									AND AESP.ACCOUNT_ID = ASL.ACCOUNT_ID
									AND AESP.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(MCAL.END_DATE, v_HIGH_DATE), NVL(MSG.END_DATE, v_HIGH_DATE),  NVL(MLF.END_DATE, v_HIGH_DATE), NVL(SLM.END_DATE, v_HIGH_DATE), NVL(ASL.END_DATE, v_HIGH_DATE))
									AND NVL(AESP.END_DATE, v_HIGH_DATE) >=  GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE, MCAL.BEGIN_DATE,MSG.BEGIN_DATE, MLF.BEGIN_DATE, SLM.BEGIN_DATE, ASL.BEGIN_DATE)
									AND p_ESP_ID IN (-1, AESP.ESP_ID)			        
									-- TEA
									AND TEA.OWNER_ENTITY_ID = AESP.ACCOUNT_ID
									AND TEA.ENTITY_DOMAIN_ID = EC.ED_ACCOUNT
									AND TEA.ATTRIBUTE_ID = v_ACCT_AGG_ATT_ID
									AND TEA.BEGIN_DATE <= LEAST(v_END_DATE, NVL(AEDC.END_DATE, v_HIGH_DATE), NVL(AST.END_DATE, v_HIGH_DATE), NVL(MCAL.END_DATE, v_HIGH_DATE), NVL(MSG.END_DATE, v_HIGH_DATE),  NVL(MLF.END_DATE, v_HIGH_DATE), NVL(SLM.END_DATE, v_HIGH_DATE), NVL(ASL.END_DATE, v_HIGH_DATE), NVL(AESP.END_DATE, v_HIGH_DATE))
									AND NVL(TEA.END_DATE, v_HIGH_DATE) >= GREATEST(p_BEGIN_DATE,AEDC.BEGIN_DATE, AST.BEGIN_DATE, MCAL.BEGIN_DATE,MSG.BEGIN_DATE, MLF.BEGIN_DATE, SLM.BEGIN_DATE, ASL.BEGIN_DATE, AESP.BEGIN_DATE)
									-- not null
									AND TRIM(TEA.ATTRIBUTE_VAL) IS NOT NULL
									AND TRIM(AEDC.EDC_STRATA) IS NOT NULL
									AND TRIM(AEDC.EDC_RATE_CLASS) IS NOT NULL
									AND NVL(MLF.LOSS_FACTOR_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
									AND NVL(SL.WEATHER_STATION_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
									AND NVL(MCAL.CALENDAR_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
									AND NVL(MSG.SCHEDULE_GROUP_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
									AND NVL(AEDC.EDC_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED
                              ) LOOP

             LOGS.LOG_DEBUG('For date range ' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_REC.BEGIN_DATE,v_REC.END_DATE) || ', ' ||
                       'ACCOUNT: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCT_REC.ACCOUNT_ID, EC.ED_ACCOUNT) || ', ' ||
                       'METER: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.METER_ID, EC.ED_METER) || ', ' ||
                       'EDC: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.EDC_ID, EC.ED_EDC) || ', ' ||
                       'EDC STRATA: ' || v_REC.EDC_STRATA || ', ' ||
                       'EDC RATE CLASS: ' || v_REC.EDC_RATE_CLASS || ', ' ||
                       'CALENDAR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.CALENDAR_ID, EC.ED_CALENDAR) || ', ' ||
                       'METER TYPE: ' || v_REC.METER_TYPE || ', ' ||
                       'MODEL: ' || CASE WHEN v_REC.MODEL_ID = GA.GAS_MODEL THEN 'Gas' ELSE 'Electric' END || ', ' ||
                       'LOSS FACTOR: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.LOSS_FACTOR_ID, EC.ED_LOSS_FACTOR) || ', ' ||
                       'WEATHER STATION: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.WEATHER_STATION_ID, EC.ED_WEATHER_STATION) || ', ' ||
                       'SCHEDULE GROUP: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_REC.SCHEDULE_GROUP_ID, EC.ED_SCHEDULE_GROUP) || ', ' ||
                       'AGGREGATION GROUP: ' || v_REC.AGGREGATION_GROUP);

            v_ACCOUNT_ID := ENSURE_AGGREGATE_ACCOUNT_SIMPL(v_REC.EDC_ID,
                                 v_REC.CALENDAR_ID,
                                 v_REC.METER_TYPE,
                                 V_REC.MODEL_ID,
                                 v_REC.SCHEDULE_GROUP_ID,
                                 v_REC.WEATHER_STATION_ID,
                                 v_REC.LOSS_FACTOR_ID,
                                 v_REC.EDC_RATE_CLASS,
                                 v_REC.EDC_STRATA,
                                 v_REC.AGGREGATION_GROUP,
                                 p_RESET_DATES);

             ENSURE_ACCOUNT_ESP(v_ACCOUNT_ID,v_REC.ESP_ID,v_REC.POOL_ID,v_REC.BEGIN_DATE,v_REC.END_DATE);
             ENSURE_SUB_AGG_AGGREGATION(v_REC.METER_ID,ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER,v_REC.BEGIN_DATE,v_REC.END_DATE,v_ACCOUNT_ID,
                           v_REC.ESP_ID,v_REC.POOL_ID);

             LOGS.LOG_DEBUG('Account for static data: ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT));

           END LOOP;
         END LOOP;
       END IF;

       LOGS.INCREMENT_PROCESS_PROGRESS;
       v_ACCOUNT_INDEX := v_ACCOUNT_INDEX + 1;
     END LOOP;

    UT.PURGE_RTO_WORK(P_WORK_ID => v_WORK_ID);

    p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;

    COMMIT;
    LOGS.STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);

EXCEPTION
    WHEN OTHERS THEN
        ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'BEFORE_AGGREGATION');
END RUN_AGGREGATION_IMPL_SIMPLE;
--------------------------------------------------------------------------------
PROCEDURE RUN_TRANSACTIONAL_AGGREGATION
    (
    p_ACCOUNT_IDs IN NUMBER_COLLECTION,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_RESET_DATES IN NUMBER,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_EDC_IDS NUMBER_COLLECTION;

BEGIN

    SELECT EDC.EDC_ID
    BULK COLLECT INTO v_EDC_IDS
    FROM ENERGY_DISTRIBUTION_COMPANY EDC
    WHERE EDC.EDC_ID <> CONSTANTS.NOT_ASSIGNED;

    RUN_AGGREGATION_IMPL_SIMPLE(p_ACCOUNT_IDs, v_EDC_IDS, CONSTANTS.ALL_ID, p_BEGIN_DATE, p_END_DATE, p_RESET_DATES, p_TRACE_ON,

        p_PROCESS_ID, p_PROCESS_STATUS, p_MESSAGE);

END RUN_TRANSACTIONAL_AGGREGATION;
--------------------------------------------------------------------------------
PROCEDURE RUN_AGGREGATION_SIMPLE
    (
    p_EDC_IDs IN NUMBER_COLLECTION,
    p_ESP_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_RESET_DATES IN NUMBER,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
   v_EDC_IDS NUMBER_COLLECTION := NUMBER_COLLECTION();
BEGIN
   -- Fix to original requirement of not selecting any EDC implies <ALL> EDCs
   -- This latter part of the fix is to suppress the GUI bug/issue in that it
   -- passes 1 EDC_ID of value 0, when no EDC is selected
   IF P_EDC_IDS IS NULL OR P_EDC_IDS.COUNT = 0 OR (p_EDC_IDS.COUNT = 1 AND p_EDC_IDS(1) = 0) THEN
        SELECT EDC_ID
        BULK COLLECT INTO v_EDC_IDS
        FROM EDC
        WHERE EDC.EDC_ID <> 0;
  ELSE
      v_EDC_IDS := p_EDC_IDS;
    END IF;


    RUN_AGGREGATION_IMPL_SIMPLE(NUMBER_COLLECTION(CONSTANTS.ALL_ID),
                                    v_EDC_IDs,
                                    p_ESP_ID,
                                    p_BEGIN_DATE,
                                    p_END_DATE,
                                    p_RESET_DATES,
                                    p_TRACE_ON,
                                    p_PROCESS_ID,
                                    p_PROCESS_STATUS,
                                    p_MESSAGE);

END RUN_AGGREGATION_SIMPLE;
--------------------------------------------------------------------------------
END ACCOUNT_AGGREGATION;
/
