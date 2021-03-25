CREATE OR REPLACE PACKAGE LOAD_MANAGEMENT_UI IS
-- $Revision: 1.50 $

c_SERVICE_WITH_LOSSES  CONSTANT VARCHAR2(12) := 'With Losses';
c_SERVICE_WO_LOSSES    CONSTANT VARCHAR2(15) := 'Without Losses';
c_SERVICE_WITH_DETAILS CONSTANT VARCHAR2(15) := 'Loss Details';

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE RUN_TYPES_LIST(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE ESP_FOR_PSE_LIST
    (
    p_PSE_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_CURSOR OUT GA.REFCURSOR
    );

PROCEDURE EDC_FOR_SC_LIST
    (
    p_SC_ID IN NUMBER,
    p_CURSOR OUT GA.REFCURSOR
    );

PROCEDURE GET_SERVICE_SUMMARY
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_RUN_TYPE_ID       IN NUMBER,
    p_TIME_ZONE         IN VARCHAR2,
    p_INTERVAL          IN VARCHAR2,
    p_MODEL_ID          IN NUMBER,
    p_SC_ID             IN NUMBER,
    p_SHOW_SC_ID        IN NUMBER,
    p_EDC_ID            IN NUMBER,
    p_SHOW_EDC_ID       IN NUMBER,
    p_ESP_ID            IN NUMBER,
    p_SHOW_ESP_ID       IN NUMBER,
    p_PSE_ID            IN NUMBER,
    p_SHOW_PSE_ID       IN NUMBER,
    p_POOL_ID           IN NUMBER,
    p_SHOW_POOL_ID      IN NUMBER,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    );

PROCEDURE CAST_ENTITY_LIST
    (
    p_MODEL_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_SEARCH_STRING IN VARCHAR2,
    p_SEARCH_OPTION IN VARCHAR2,
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_ENTITY_DOMAIN_NAME OUT VARCHAR2,
    p_CURSOR OUT GA.REFCURSOR
    );

PROCEDURE RUN_CAST_SERVICE_REQUEST
    (
    p_FILTER_MODEL_ID IN NUMBER,
    p_RUN_TYPE_ID IN NUMBER,
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_ENTITY_IDS IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_ACCEPT_INTO_SCHEDULES IN NUMBER,
    p_SCHEDULE_STATEMENT_TYPE_ID IN NUMBER,
    p_APPLY_USAGE_FACTOR IN NUMBER := 1,
    p_APPLY_UFE IN NUMBER := 1,
	p_TRACE_ON IN NUMBER := 0,
	p_PROCESS_ID OUT VARCHAR2,
	p_PROCESS_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    );

PROCEDURE GET_ACCOUNT_ENROLLMENT_SUMMARY
    (
    p_TIME_ZONE             IN VARCHAR2,
    p_BEGIN_DATE            IN DATE,
    p_END_DATE              IN DATE,
    p_ENROLLMENT_CASE_ID    IN NUMBER,
    p_FILTER_MODEL_ID       IN NUMBER,
    p_FILTER_SC_ID          IN NUMBER,
    p_SHOW_FILTER_SC_ID     IN NUMBER,
    p_FILTER_EDC_ID         IN NUMBER,
    p_SHOW_FILTER_EDC_ID    IN NUMBER,
    p_FILTER_ESP_ID         IN NUMBER,
    p_SHOW_FILTER_ESP_ID    IN NUMBER,
    p_FILTER_PSE_ID         IN NUMBER,
    p_SHOW_FILTER_PSE_ID    IN NUMBER,
    p_FILTER_POOL_ID        IN NUMBER,
    p_SHOW_FILTER_POOL_ID   IN NUMBER,
    p_SHOW_DETAILS          IN NUMBER,
    p_CURSOR                OUT GA.REFCURSOR
    );

PROCEDURE GET_LOAD_DETAILS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_ENTITY_TYPE       IN VARCHAR2,
    p_ENTITY_ID         IN NUMBER,
    p_ACCOUNT_ID        IN NUMBER,
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_METER_ID          IN NUMBER,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_UOM               OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    );

PROCEDURE GET_LOAD_DTLS_BY_ENTITY_ATTB
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_ATTRIBUTE_ID      IN VARCHAR2,
    p_ATTRIBUTE_VAL     IN VARCHAR2,
    p_SHOW_DETAILS      IN NUMBER,
    p_SUB_AGG_ACCT_SEARCH_BY IN VARCHAR2, -- By Name, By External Identifier
    p_SUB_AGG_ACCT_SEARCH_STRING IN VARCHAR2, -- Null or Search String
    p_UOM               OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    );

PROCEDURE ENTITY_ATTRIBUTE_LIST
    (
    p_CURSOR OUT GA.REFCURSOR
    );

PROCEDURE ENTITY_ATTRIBUTE_VAL_LIST
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_ATTRIBUTE_ID      IN VARCHAR2,
    p_ATTRIBUTE_SEARCH_STRING IN VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    );

PROCEDURE SUMMARY_ACCEPT_SCHEDULES
    (
    p_BEGIN_DATE        			IN DATE,
    p_END_DATE          			IN DATE,
    p_RUN_TYPE_ID       			IN NUMBER,
    p_MODEL_ID          			IN NUMBER,
    p_SCHEDULE_STATEMENT_TYPE_ID 	IN NUMBER,
    p_TRACE_ON 						IN NUMBER,
    p_PROCESS_ID 					OUT VARCHAR2,
    p_PROCESS_STATUS 				OUT NUMBER,
    p_MESSAGE 						OUT VARCHAR2
    );

PROCEDURE GET_SERVICE_STATE_DETAILS
	(
	p_BEGIN_DATE          IN DATE,
	p_END_DATE            IN DATE,
	p_RUN_TYPE_ID         IN NUMBER,
	p_ACCOUNT_ID          IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID            IN NUMBER,
	p_ESP_ID              IN NUMBER,
	p_POOL_ID             IN NUMBER,
	p_CURSOR              OUT GA.REFCURSOR
	);

PROCEDURE INTERPRET_RUN_TYPE
    (
    p_RUN_TYPE_ID IN NUMBER,
    p_SERVICE_CODE OUT VARCHAR2,
    p_SCENARIO_ID OUT NUMBER
    );

PROCEDURE GET_SYSTEM_LOAD
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_CASE_LABEL        IN VARCHAR2,
    p_INTERVAL          IN VARCHAR2,
    p_SYSTEM_LOAD_ID    IN NUMBER,
    p_AREA_LOAD         IN STRING_COLLECTION,
    p_FORECAST_FILTER   IN NUMBER,
    p_ACTUAL_FILTER     IN NUMBER,
    p_DIFFERENCE_FILTER IN NUMBER,
    p_MAPE_FILTER       IN NUMBER,
    p_TIME_ZONE         IN VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    );

PROCEDURE PUT_SYSTEM_LOAD
    (
    p_CUT_DATE        IN date,
    p_AREA_NAME       IN VARCHAR2,
    p_CASE_LABEL      IN VARCHAR2,
    p_INTERVAL        IN VARCHAR2,
    p_FORECAST        IN NUMBER,
    p_ACTUAL          IN NUMBER,
    p_TIME_ZONE       IN VARCHAR2,
    p_VISIBLE         IN NUMBER
    ) ;

PROCEDURE GET_COMPARISON_SUMMARY
    (
    p_BEGIN_DATE          IN DATE,
    p_END_DATE            IN DATE,
    p_RUN_TYPE_A_ID       IN NUMBER,
    p_RUN_TYPE_B_ID       IN NUMBER,
    p_TIME_ZONE           IN VARCHAR2,
    p_INTERVAL            IN VARCHAR2,
    p_MODEL_ID            IN NUMBER,
    p_FILTER_SC_ID        IN NUMBER,
    p_SHOW_FILTER_SC_ID   IN NUMBER,
    p_FILTER_EDC_ID       IN NUMBER,
    p_SHOW_FILTER_EDC_ID  IN NUMBER,
    p_FILTER_ESP_ID       IN NUMBER,
    p_SHOW_FILTER_ESP_ID  IN NUMBER,
    p_FILTER_PSE_ID       IN NUMBER,
    p_SHOW_FILTER_PSE_ID  IN NUMBER,
    p_FILTER_POOL_ID      IN NUMBER,
    p_SHOW_FILTER_POOL_ID IN NUMBER,
    p_DISPLAY_TYPE        IN VARCHAR2,
    p_CURSOR              OUT GA.REFCURSOR
    );

PROCEDURE GET_COMPARISON_DETAILS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_SERVICE_ID        IN NUMBER,
    p_RUN_TYPE_A_ID     IN NUMBER,
    p_RUN_TYPE_B_ID     IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_SC_ID             IN NUMBER,
	p_FILTER_SC_ID      IN NUMBER,
    p_EDC_ID            IN NUMBER,
    p_FILTER_EDC_ID     IN NUMBER,
    p_ESP_ID            IN NUMBER,
    p_FILTER_ESP_ID     IN NUMBER,
    p_PSE_ID            IN NUMBER,
    p_FILTER_PSE_ID     IN NUMBER,
    p_POOL_ID           IN NUMBER,
    p_FILTER_POOL_ID    IN NUMBER,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_MAX_ACCOUNTS      IN NUMBER,
    p_UOM               OUT VARCHAR2,
    p_RUN_TYPE_A        OUT VARCHAR2,
    p_RUN_TYPE_B        OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    );
    
PROCEDURE GET_COMPARISON_DETAILS_AGG_MET
    (
    p_BEGIN_DATE         IN DATE,
    p_END_DATE           IN DATE,
    p_TIME_ZONE          IN VARCHAR2,
    p_RUN_TYPE_A_ID      IN NUMBER,
    p_RUN_TYPE_B_ID      IN NUMBER,
    p_ACCOUNT_ID         IN NUMBER,
    p_ACCOUNT_NAME       IN VARCHAR2,
    p_ESP_ID             IN NUMBER,
    p_FILTER_ESP_ID      IN NUMBER,
    p_POOL_ID            IN NUMBER,
    p_FILTER_POOL_ID     IN NUMBER,
    p_MAX_ACCOUNTS       IN NUMBER,
    p_ACCOUNT_NAME_LABEL OUT VARCHAR2,
    p_CURSOR             OUT GA.REFCURSOR
    );

PROCEDURE GET_AGGR_CONSUMPTION_SUMMARY
	(
	p_MODEL_ID           IN NUMBER,
	p_SETTLEMENT_TYPE_ID IN NUMBER,
	p_EDC_ID             IN NUMBER,
	p_ESP_ID             IN NUMBER,
	p_BEGIN_DATE         IN DATE,
	p_END_DATE           IN DATE,
	p_THRESHOLD          IN NUMBER,
	p_STATUS             OUT NUMBER,
	p_CURSOR             IN OUT GA.REFCURSOR
	);

PROCEDURE GET_AGGR_CONSUMPTION_DETAILS
    (
	p_MODEL_ID           IN NUMBER,
	p_SETTLEMENT_TYPE_ID IN NUMBER,
	p_EDC_ID             IN NUMBER,
	p_ESP_ID             IN NUMBER,
	p_ACCOUNT_ID         IN NUMBER,
	p_SERVICE_DATE       IN DATE,
	p_STATUS             OUT NUMBER,
	p_CURSOR             IN OUT GA.REFCURSOR
	);
    
PROCEDURE ENTITY_DOMAINS_FROM_LIST
    (
    p_ENTITY_TYPES IN VARCHAR2,
    p_INCLUDE_ALL IN NUMBER,
    p_CURSOR OUT GA.REFCURSOR
    );

PROCEDURE RUN_CAST_HANDLER
    (
    p_FILTER_MODEL_ID IN NUMBER,
    p_RUN_TYPE_ID IN NUMBER,
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_ENTITY_IDS IN NUMBER_COLLECTION,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_ACCEPT_INTO_SCHEDULES IN NUMBER,
    p_SCHEDULE_STATEMENT_TYPE_ID IN NUMBER,
    p_APPLY_USAGE_FACTOR IN NUMBER := 1,
    p_APPLY_UFE IN NUMBER := 1,
    p_TRACE_ON IN NUMBER := 0,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    );
    
PROCEDURE INT_AGG_ACCT_LIST
    (
    p_CURSOR OUT GA.REFCURSOR
    );
    
PROCEDURE ESP_FOR_AGG_ACCT_LIST
    (
    p_AGG_ACCT_ID IN NUMBER,
    p_CURSOR OUT GA.REFCURSOR
    );
    
PROCEDURE POOL_FOR_AGG_ACCT_LIST
    (
    p_AGG_ACCT_ID IN NUMBER,
    p_CURSOR OUT GA.REFCURSOR
    );
    
PROCEDURE GET_AGGR_DETAILS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_AGG_ACCT_ID       IN NUMBER,
    p_ESP_ID            IN NUMBER_COLLECTION,
    p_POOL_ID           IN NUMBER_COLLECTION,
    p_LIMIT_BY          IN VARCHAR2,
    p_LIMIT_VALUE       IN VARCHAR2,
    p_ACCOUNT_LABEL     OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    );
    
FUNCTION ENABLE_AGG_DET_DRILL
    (
    p_ACCOUNT_ID        IN NUMBER
    ) RETURN NUMBER;

$if $$UNIT_TEST_MODE = 1 $then

FUNCTION DETERMINE_SCHED_STATEMENT_TYPE
    (
    p_RUN_TYPE_ID IN NUMBER,
    p_STATEMENT_TYPE_ID IN NUMBER
    ) RETURN NUMBER;

PROCEDURE ACCEPT_CAST_INTO_SCHEDULES
    (
    p_FILTER_MODEL_ID IN NUMBER,
    p_REQUEST_TYPE IN VARCHAR2,
    p_SCENARIO_ID IN NUMBER,
    p_ACCEPT_STATEMENT_TYPE_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    );
    
PROCEDURE GET_AGGR_DETAILS_ESP_POOL
    (
    p_AGG_ACCT_ID       IN NUMBER,
    p_ESP_ID            IN NUMBER_COLLECTION,
    p_POOL_ID           IN NUMBER_COLLECTION,
    p_ESP_EXT_IDENTS    OUT VARCHAR2,
    p_POOL_EXT_IDENTS   OUT VARCHAR2
    );
    
PROCEDURE GET_AGGR_DETAILS_CUR
    (
    p_XML_CLOB IN CLOB,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_INTERVAL IN VARCHAR2,
    p_CURSOR OUT GA.REFCURSOR
    );

$end

END LOAD_MANAGEMENT_UI;
/
CREATE OR REPLACE PACKAGE BODY LOAD_MANAGEMENT_UI IS

c_SEARCH_BY_NAME VARCHAR2(32) := 'Account''s Name';
c_SEARCH_BY_EXT_IDENT VARCHAR2(32) := 'Account''s External Identifier';

--------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.50 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE RUN_TYPES_LIST(p_CURSOR OUT GA.REFCURSOR) AS

BEGIN

    OPEN p_CURSOR FOR
    SELECT '<HTML><B>Please Select</B></HTML>' AS RUN_TYPE_NAME,
        CONSTANTS.NOT_ASSIGNED AS RUN_TYPE_ID
    FROM DUAL
    UNION ALL
    SELECT '<HTML><B>Forecast:</B></HTML>' AS RUN_TYPE_NAME,
        CONSTANTS.NOT_ASSIGNED AS RUN_TYPE_ID
    FROM DUAL
    UNION ALL
    SELECT *
    FROM (
        SELECT '   ' || S.SCENARIO_NAME AS RUN_TYPE_NAME,
            S.SCENARIO_ID AS RUN_TYPE_ID
        FROM (SELECT SCENARIO_ID, SCENARIO_NAME, (CASE WHEN SCENARIO_ID = GA.BASE_SCENARIO_ID THEN 1 ELSE 0 END) AS ORD
              FROM SCENARIO
              WHERE SCENARIO_CATEGORY IN (CONSTANTS.CASE_CATEGORY_ALL, CONSTANTS.SCENARIO_LOAD_FORECAST) )S
        ORDER BY S.ORD DESC, S.SCENARIO_NAME
        )
    UNION ALL
    SELECT '<HTML><B>Settlement:</B></HTML>' AS RUN_TYPE_NAME,
        CONSTANTS.NOT_ASSIGNED AS RUN_TYPE_ID
    FROM DUAL
    UNION ALL
    SELECT *
    FROM (
        SELECT '   ' || ST.SETTLEMENT_TYPE_NAME AS RUN_TYPE_NAME,
            (ST.SETTLEMENT_TYPE_ID * -1) AS RUN_TYPE_ID
        FROM SETTLEMENT_TYPE ST
        ORDER BY ST.SETTLEMENT_TYPE_ORDER, ST.SETTLEMENT_TYPE_NAME
        );

END RUN_TYPES_LIST;
--------------------------------------------------------
PROCEDURE ESP_FOR_PSE_LIST
    (
    p_PSE_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_CURSOR OUT GA.REFCURSOR
    ) AS

BEGIN

    IF NVL(p_PSE_ID, CONSTANTS.ALL_ID) = CONSTANTS.ALL_ID THEN
        OPEN p_CURSOR FOR
        SELECT ESP.ESP_ID, ESP.ESP_NAME
        FROM ENERGY_SERVICE_PROVIDER ESP
        ORDER BY ESP_NAME;
    ELSE
        OPEN p_CURSOR FOR
        SELECT DISTINCT ESP.ESP_ID, ESP.ESP_NAME
        FROM ENERGY_SERVICE_PROVIDER ESP,
            PSE_ESP PE
        WHERE p_PSE_ID = PE.PSE_ID
            AND p_BEGIN_DATE <= NVL(PE.END_DATE,CONSTANTS.HIGH_DATE)
            AND p_END_DATE >= PE.BEGIN_DATE
            AND ESP.ESP_ID = PE.ESP_ID
        ORDER BY ESP_NAME;
    END IF;

END ESP_FOR_PSE_LIST;
--------------------------------------------------------
PROCEDURE EDC_FOR_SC_LIST
    (
    p_SC_ID IN NUMBER,
    p_CURSOR OUT GA.REFCURSOR
    ) AS

BEGIN

    OPEN p_CURSOR FOR
    SELECT EDC.EDC_ID, EDC.EDC_NAME
    FROM ENERGY_DISTRIBUTION_COMPANY EDC
    WHERE NVL(p_SC_ID,CONSTANTS.ALL_ID) IN (CONSTANTS.ALL_ID,EDC.EDC_SC_ID)
    ORDER BY EDC_NAME;

END EDC_FOR_SC_LIST;
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
--------------------------------------------------------
PROCEDURE GET_SERVICE_SUMMARY
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_RUN_TYPE_ID       IN NUMBER,
    p_TIME_ZONE         IN VARCHAR2,
    p_INTERVAL          IN VARCHAR2,
    p_MODEL_ID          IN NUMBER,
    p_SC_ID             IN NUMBER,
    p_SHOW_SC_ID        IN NUMBER,
    p_EDC_ID            IN NUMBER,
    p_SHOW_EDC_ID       IN NUMBER,
    p_ESP_ID            IN NUMBER,
    p_SHOW_ESP_ID       IN NUMBER,
    p_PSE_ID            IN NUMBER,
    p_SHOW_PSE_ID       IN NUMBER,
    p_POOL_ID           IN NUMBER,
    p_SHOW_POOL_ID      IN NUMBER,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS

    v_EDC_ID NUMBER(9) := NVL(p_EDC_ID, CONSTANTS.ALL_ID);
    v_SHOW_EDC_ID NUMBER(1) := NVL(p_SHOW_EDC_ID, 0);

    v_SC_ID NUMBER(9) := NVL(p_SC_ID, CONSTANTS.ALL_ID);
    v_SHOW_SC_ID NUMBER(1) := NVL(p_SHOW_SC_ID, 0);

    v_ESP_ID NUMBER(9) := NVL(p_ESP_ID, CONSTANTS.ALL_ID);
    v_SHOW_ESP_ID NUMBER(1) := NVL(p_SHOW_ESP_ID, 0);

    v_PSE_ID NUMBER(9) := NVL(p_PSE_ID, CONSTANTS.ALL_ID);
    v_SHOW_PSE_ID NUMBER(1) := NVL(p_SHOW_PSE_ID, 0);

    v_POOL_ID NUMBER(9) := NVL(p_POOL_ID, CONSTANTS.ALL_ID);
    v_SHOW_POOL_ID NUMBER(1) := NVL(p_SHOW_POOL_ID, 0);

    v_MODEL_ID NUMBER(9) := NVL(p_MODEL_ID,GA.DEFAULT_MODEL);
    v_SHOW_MODEL_ID NUMBER(1) := CASE WHEN p_MODEL_ID IS NULL THEN 0 ELSE 1 END;

    v_SERVICE_CODE CHAR(1);
    v_SCENARIO_ID NUMBER(9);

    v_BEGIN DATE;
    v_END DATE;

    v_CUT_BEGIN_DATE DATE;
    v_CUT_END_DATE DATE;

    v_SHOW_W NUMBER(1) := 0;
    v_SHOW_WO NUMBER(1) := 0;
    v_SHOW_DETAILS NUMBER(1) := 0;

    v_VALID_DATA_INTERVAL_TYPES NUMBER_COLLECTION;

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

    OPEN p_CURSOR FOR
    SELECT Q.DT,
           Q.SERVICE,
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
           SUM(Q.WITH_LOSSES) AS WITH_LOSSES,
           SUM(Q.WITHOUT_LOSSES) AS WITHOUT_LOSSES,
           SUM(Q.TX_LOSS_VAL) AS TX_LOSS_VAL,
           SUM(Q.DX_LOSS_VAL) AS DX_LOSS_VAL,
           SUM(Q.UFE_LOSS_VAL) AS UFE_LOSS_VAL
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
            CASE WHEN v_SHOW_MODEL_ID = 0 THEN NULL ELSE (CASE WHEN X.MODEL_ID = CONSTANTS.ELECTRIC_MODEL THEN 'Electric' WHEN X.MODEL_ID = CONSTANTS.GAS_MODEL THEN 'Gas' ELSE NULL END) END AS SERVICE,
            CASE WHEN v_SHOW_SC_ID = 0 THEN NULL ELSE X.SC_ID END AS SC_ID,
            CASE WHEN v_SHOW_SC_ID = 0 THEN NULL ELSE X.SC_NAME END AS SC_NAME,
            CASE WHEN v_SHOW_EDC_ID = 0 THEN NULL ELSE X.EDC_ID END AS EDC_ID,
            CASE WHEN v_SHOW_EDC_ID = 0 THEN NULL ELSE X.EDC_NAME END AS EDC_NAME,
            CASE WHEN v_SHOW_PSE_ID = 0 THEN NULL ELSE X.PSE_ID END AS PSE_ID,
            CASE WHEN v_SHOW_PSE_ID = 0 THEN NULL ELSE X.PSE_NAME END AS PSE_NAME,
            CASE WHEN v_SHOW_ESP_ID = 0 THEN NULL ELSE X.ESP_ID END AS ESP_ID,
            CASE WHEN v_SHOW_ESP_ID = 0 THEN NULL ELSE X.ESP_NAME END AS ESP_NAME,
            CASE WHEN v_SHOW_POOL_ID = 0 THEN NULL ELSE X.POOL_ID END AS POOL_ID,
            CASE WHEN v_SHOW_POOL_ID = 0 THEN NULL ELSE X.POOL_NAME END AS POOL_NAME,
            CASE WHEN v_SHOW_W = 1 THEN X.LOAD_VAL+X.TX_LOSS_VAL+X.DX_LOSS_VAL+X.UFE_LOAD_VAL ELSE NULL END AS WITH_LOSSES,
            CASE WHEN v_SHOW_WO = 1 THEN X.LOAD_VAL ELSE NULL END AS WITHOUT_LOSSES,
            CASE WHEN v_SHOW_DETAILS = 1 THEN X.TX_LOSS_VAL ELSE NULL END AS TX_LOSS_VAL,
            CASE WHEN v_SHOW_DETAILS = 1 THEN X.DX_LOSS_VAL ELSE NULL END AS DX_LOSS_VAL,
            CASE WHEN v_SHOW_DETAILS = 1 THEN X.UFE_LOAD_VAL ELSE NULL END AS UFE_LOSS_VAL
        FROM (SELECT SO.MODEL_ID,
                    SOL.LOAD_DATE,
                    SOL.LOAD_VAL,
                    SOL.TX_LOSS_VAL,
                    SOL.DX_LOSS_VAL,
                    SOL.UFE_LOAD_VAL,
                    PSE.PSE_ID,
                    PSE.PSE_NAME,
                    SC.SC_ID,
                    SC.SC_NAME,
                    P.POOL_ID,
                    P.POOL_NAME,
                    ESP.ESP_ID,
                    ESP.ESP_NAME,
                    EDC.EDC_ID,
                    EDC.EDC_NAME
             FROM SERVICE_OBLIGATION SO,
                SERVICE_OBLIGATION_LOAD SOL,
                PROVIDER_SERVICE PS,
                SERVICE_DELIVERY SD,
                PURCHASING_SELLING_ENTITY PSE,
                POOL P,
                SCHEDULE_COORDINATOR SC,
                ENERGY_DISTRIBUTION_COMPANY EDC,
                ENERGY_SERVICE_PROVIDER ESP
             WHERE v_EDC_ID IN (CONSTANTS.ALL_ID, EDC.EDC_ID)
                AND v_ESP_ID IN (CONSTANTS.ALL_ID, ESP.ESP_ID)
                AND v_PSE_ID IN (CONSTANTS.ALL_ID,PS.PSE_ID)
                AND v_POOL_ID IN (CONSTANTS.ALL_ID,SD.POOL_ID)
                AND v_SC_ID IN (CONSTANTS.ALL_ID,SD.SC_ID)
                AND v_MODEL_ID IN (CONSTANTS.ALL_ID,SO.MODEL_ID)
                AND SOL.SERVICE_CODE = v_SERVICE_CODE
                AND SO.SCENARIO_ID = v_SCENARIO_ID
                AND P.POOL_ID = SD.POOL_ID
                AND PSE.PSE_ID = PS.PSE_ID
                AND EDC.EDC_ID = PS.EDC_ID
                AND ESP.ESP_ID = PS.ESP_ID
                AND SC.SC_ID = SD.SC_ID
                AND SOL.LOAD_CODE = GA.STANDARD
                AND SO.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
                AND SO.SERVICE_DELIVERY_ID = SD.SERVICE_DELIVERY_ID
                AND SOL.SERVICE_OBLIGATION_ID = SO.SERVICE_OBLIGATION_ID
                AND ((SO.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SOL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE)
                    OR (SO.MODEL_ID = CONSTANTS.GAS_MODEL AND SOL.LOAD_DATE BETWEEN v_BEGIN AND v_END))) X,
            SYSTEM_DATE_TIME SDT
        WHERE SDT.TIME_ZONE = p_TIME_ZONE
            AND SDT.DAY_TYPE = GA.STANDARD
            AND v_MODEL_ID IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
            AND X.MODEL_ID (+) = SDT.DATA_INTERVAL_TYPE
            AND X.LOAD_DATE (+) = SDT.CUT_DATE
            AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                  AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END) Q
     GROUP BY Q.DT, Q.SERVICE, Q.SC_ID, Q.SC_NAME, Q.EDC_ID, Q.EDC_NAME, Q.PSE_ID, Q.PSE_NAME, Q.ESP_ID, Q.ESP_NAME, Q.POOL_ID, Q.POOL_NAME
     ORDER BY Q.DT, Q.SERVICE, Q.SC_NAME, Q.EDC_NAME, Q.PSE_NAME, Q.ESP_NAME, Q.POOL_NAME;

END GET_SERVICE_SUMMARY;
-----------------------------------------------------------------------------------------------------
PROCEDURE CAST_ENTITY_LIST
    (
    p_MODEL_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_SEARCH_STRING IN VARCHAR2,
    p_SEARCH_OPTION IN VARCHAR2,
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_ENTITY_DOMAIN_NAME OUT VARCHAR2,
    p_CURSOR OUT GA.REFCURSOR
    ) AS
    v_SEARCH_STRING VARCHAR2(1024);
BEGIN
    v_SEARCH_STRING := UPPER(GUI_UTIL.FIX_SEARCH_STRING(p_SEARCH_STRING));

    IF p_ENTITY_DOMAIN_ID = CONSTANTS.ALL_ID THEN
        p_ENTITY_DOMAIN_NAME := CONSTANTS.ALL_STRING;
        OPEN p_CURSOR FOR
            SELECT 'All active entities selected' AS ENTITY_NAME,
                NULL AS ENTITY_ID,
                NULL AS ENTITY_ALIAS,
                NULL AS SELECTED
            FROM DUAL;
        RETURN;
    ELSE
        p_ENTITY_DOMAIN_NAME := EI.GET_ENTITY_NAME(EC.ED_ENTITY_DOMAIN, p_ENTITY_DOMAIN_ID);
        IF p_ENTITY_DOMAIN_ID = EC.ED_EDC THEN
            OPEN p_CURSOR FOR
                SELECT EDC_NAME AS ENTITY_NAME,
                        EDC_ID AS ENTITY_ID,
                        EDC_ALIAS AS ENTITY_ALIAS,
                        0 AS SELECTED
                FROM ENERGY_DISTRIBUTION_COMPANY
                WHERE ((p_SEARCH_OPTION = CONSTANTS.SEARCH_OPTION_BY_NAME AND UPPER(EDC_NAME) LIKE NVL(v_SEARCH_STRING, '%'))
                        OR (p_SEARCH_OPTION = CONSTANTS.SEARCH_OPTION_BY_ALIAS AND UPPER(EDC_ALIAS) LIKE NVL(v_SEARCH_STRING, '%')))
                        AND EDC_ID <> CONSTANTS.NOT_ASSIGNED
                ORDER BY DECODE(p_SEARCH_OPTION, CONSTANTS.SEARCH_OPTION_BY_ALIAS, EDC_ALIAS, EDC_NAME);
        ELSIF p_ENTITY_DOMAIN_ID = EC.ED_ESP THEN
            OPEN p_CURSOR FOR
                SELECT ESP_NAME AS ENTITY_NAME,
                        ESP_ID AS ENTITY_ID,
                        ESP_ALIAS AS ENTITY_ALIAS,
                        0 AS SELECTED
                FROM ENERGY_SERVICE_PROVIDER
                WHERE ((p_SEARCH_OPTION = CONSTANTS.SEARCH_OPTION_BY_NAME AND UPPER(ESP_NAME) LIKE NVL(v_SEARCH_STRING, '%'))
                        OR (p_SEARCH_OPTION = CONSTANTS.SEARCH_OPTION_BY_ALIAS AND UPPER(ESP_ALIAS) LIKE NVL(v_SEARCH_STRING, '%')))
                        AND ESP_ID <> CONSTANTS.NOT_ASSIGNED
                ORDER BY DECODE(p_SEARCH_OPTION, CONSTANTS.SEARCH_OPTION_BY_ALIAS, ESP_ALIAS, ESP_NAME);
        ELSIF p_ENTITY_DOMAIN_ID = EC.ED_ACCOUNT THEN
            OPEN p_CURSOR FOR
                SELECT DISTINCT A.ACCOUNT_NAME AS ENTITY_NAME,
                        A.ACCOUNT_ID AS ENTITY_ID,
                        A.ACCOUNT_ALIAS AS ENTITY_ALIAS,
                        0 AS SELECTED
                FROM ACCOUNT A, ACCOUNT_STATUS S, ACCOUNT_STATUS_NAME N
                WHERE (A.MODEL_ID = NVL(p_MODEL_ID, GA.DEFAULT_MODEL) OR CONSTANTS.ALL_ID = NVL(p_MODEL_ID, GA.DEFAULT_MODEL))
                        AND ((p_SEARCH_OPTION = CONSTANTS.SEARCH_OPTION_BY_NAME AND UPPER(ACCOUNT_NAME) LIKE NVL(v_SEARCH_STRING, '%'))
                            OR (p_SEARCH_OPTION = CONSTANTS.SEARCH_OPTION_BY_ALIAS AND UPPER(ACCOUNT_ALIAS) LIKE NVL(v_SEARCH_STRING, '%')))
                        AND S.ACCOUNT_ID = A.ACCOUNT_ID
                        AND S.BEGIN_DATE <= p_END_DATE
                        AND NVL(S.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                        AND N.STATUS_NAME = S.STATUS_NAME
                        AND N.IS_ACTIVE = 1
                ORDER BY DECODE(p_SEARCH_OPTION, CONSTANTS.SEARCH_OPTION_BY_ALIAS, ACCOUNT_ALIAS, ACCOUNT_NAME);
        END IF;
    END IF;
END CAST_ENTITY_LIST;
-----------------------------------------------------------------------------------------------------
FUNCTION DETERMINE_SCHED_STATEMENT_TYPE
    (
    p_RUN_TYPE_ID IN NUMBER,
    p_STATEMENT_TYPE_ID IN NUMBER
    ) RETURN NUMBER IS

    v_RESULT NUMBER(9);

BEGIN

    ASSERT(NVL(p_RUN_TYPE_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED,
        'An invalid value for RUN_TYPE_ID was specified: ' || p_RUN_TYPE_ID, MSGCODES.c_ERR_ARGUMENT);

    ASSERT(NVL(p_STATEMENT_TYPE_ID,CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED OR p_RUN_TYPE_ID < 0,
        'A target schedule statement type must be given for accepting load data when the Run Type is a forecast scenario.',
        MSGCODES.c_ERR_ARGUMENT);

    IF p_RUN_TYPE_ID < 0 THEN
        SELECT ST.STATEMENT_TYPE_ID
        INTO v_RESULT
        FROM SETTLEMENT_TYPE ST
        WHERE ST.SETTLEMENT_TYPE_ID = -1*p_RUN_TYPE_ID;

        RETURN v_RESULT;
    ELSE
        RETURN p_STATEMENT_TYPE_ID;
    END IF;

END DETERMINE_SCHED_STATEMENT_TYPE;
-----------------------------------------------------------------------------------------------------
PROCEDURE ACCEPT_CAST_INTO_SCHEDULES
    (
    p_FILTER_MODEL_ID IN NUMBER,
    p_REQUEST_TYPE IN VARCHAR2,
    p_SCENARIO_ID IN NUMBER,
    p_ACCEPT_STATEMENT_TYPE_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_TRACE_ON IN NUMBER,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_EXCLUDE_UFE_ALLOCATION NUMBER(1);
    v_EXCLUDE_ZERO_SCHEDULES NUMBER(1);

    v_STATUS NUMBER;

BEGIN



    v_EXCLUDE_UFE_ALLOCATION := UT.NUMBER_FROM_BOOLEAN(UT.BOOLEAN_FROM_STRING(GET_DICTIONARY_VALUE('Exclude UFE values',
                                                                            GA.GLOBAL_MODEL,
                                                                            'Scheduling',
                                                                            'Accept Into Schedules')));

    v_EXCLUDE_ZERO_SCHEDULES := UT.NUMBER_FROM_BOOLEAN(UT.BOOLEAN_FROM_STRING(GET_DICTIONARY_VALUE('Exclude Zero Schedules',
                                                                            GA.GLOBAL_MODEL,
                                                                            'Scheduling',
                                                                            'Accept Into Schedules')));


    LOGS.START_PROCESS(p_PROCESS_NAME => 'Accept Summary Load Data into Schedules',
                        p_TARGET_BEGIN_DATE => p_BEGIN_DATE,
                        p_TARGET_END_DATE => p_END_DATE,
                        p_TRACE_ON => p_TRACE_ON);

    LOGS.SET_PROCESS_TARGET_PARAMETER('Service', CASE WHEN NVL(p_FILTER_MODEL_ID,GA.DEFAULT_MODEL) = GA.ELECTRIC_MODEL THEN 'Electric' ELSE 'Gas' END);
    LOGS.SET_PROCESS_TARGET_PARAMETER('Request Type', p_REQUEST_TYPE);
    LOGS.SET_PROCESS_TARGET_PARAMETER('Scenario', TEXT_UTIL.TO_CHAR_ENTITY(p_SCENARIO_ID,EC.ED_SCENARIO));
    LOGS.SET_PROCESS_TARGET_PARAMETER('Schedule Statment Type', TEXT_UTIL.TO_CHAR_ENTITY(p_ACCEPT_STATEMENT_TYPE_ID,EC.ED_STATEMENT_TYPE));

    RS.CREATE_LOAD_OBLIGATION(p_REQUEST_TYPE,
                            NVL(p_FILTER_MODEL_ID,GA.DEFAULT_MODEL),
                            p_SCENARIO_ID,
                            0,
                            p_BEGIN_DATE,
                            p_END_DATE,
                            LOW_DATE,
                            v_EXCLUDE_UFE_ALLOCATION,
                            v_EXCLUDE_ZERO_SCHEDULES,
                            p_TRACE_ON,
                            v_STATUS);

   RS.ACCEPT_INCUMBENT_OBLIGATION_EX(p_REQUEST_TYPE,
                                  p_ACCEPT_STATEMENT_TYPE_ID,
                                  NVL(p_FILTER_MODEL_ID,GA.DEFAULT_MODEL),
                                  p_SCENARIO_ID,
                                  p_BEGIN_DATE,
                                  p_END_DATE,
                                  LOW_DATE,
                                  LOW_DATE,
                                  p_TRACE_ON,
                                  v_STATUS);

   p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;
   LOGS.STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);

EXCEPTION
    WHEN OTHERS THEN
        ERRS.ABORT_PROCESS;
END ACCEPT_CAST_INTO_SCHEDULES;
------------------------------------------------------------------------------
PROCEDURE SUMMARY_ACCEPT_SCHEDULES
    (
    p_BEGIN_DATE        			IN DATE,
    p_END_DATE          			IN DATE,
    p_RUN_TYPE_ID       			IN NUMBER,
    p_MODEL_ID          			IN NUMBER,
    p_SCHEDULE_STATEMENT_TYPE_ID 	IN NUMBER,
    p_TRACE_ON 						IN NUMBER,
    p_PROCESS_ID 					OUT VARCHAR2,
    p_PROCESS_STATUS 				OUT NUMBER,
    p_MESSAGE 						OUT VARCHAR2
    ) AS
    v_REQUEST_TYPE					SETTLEMENT_TYPE.SERVICE_CODE%TYPE;
    v_SCENARIO_ID					SCENARIO.SCENARIO_ID%TYPE;
    v_STATEMENT_TYPE_ID STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
BEGIN
   -- First Interpret the Run Type
   INTERPRET_RUN_TYPE(p_RUN_TYPE_ID, v_REQUEST_TYPE, v_SCENARIO_ID);

   -- Get the actual STATEMENT_TYPE_ID for call to ACCEPT schedules
   v_STATEMENT_TYPE_ID := DETERMINE_SCHED_STATEMENT_TYPE(p_RUN_TYPE_ID, p_SCHEDULE_STATEMENT_TYPE_ID);

   -- Call the ACCEPT_CAST_INTO_SCHEDULES api
   ACCEPT_CAST_INTO_SCHEDULES(p_MODEL_ID,
   							  v_REQUEST_TYPE,
                              v_SCENARIO_ID,
                              v_STATEMENT_TYPE_ID,
                              p_BEGIN_DATE,
                              p_END_DATE,
                              p_TRACE_ON,
                              p_PROCESS_ID,
                              p_PROCESS_STATUS,
                              p_MESSAGE
                             );

END SUMMARY_ACCEPT_SCHEDULES;
--------------------------------------------------------
PROCEDURE RUN_CAST_SERVICE_REQUEST
    (
    p_FILTER_MODEL_ID IN NUMBER,
    p_RUN_TYPE_ID IN NUMBER,
    p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_IDS IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_ACCEPT_INTO_SCHEDULES IN NUMBER,
    p_SCHEDULE_STATEMENT_TYPE_ID IN NUMBER,
    p_APPLY_USAGE_FACTOR IN NUMBER := 1,
    p_APPLY_UFE IN NUMBER := 1,
	p_TRACE_ON IN NUMBER := 0,
	p_PROCESS_ID OUT VARCHAR2,
	p_PROCESS_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    )
AS
    v_REQUEST_TYPE CHAR;
    v_SCENARIO_ID NUMBER;
    v_MODEL_IDS NUMBER_COLLECTION;
    v_IDX NUMBER;

    v_STATUS NUMBER(9);

    v_ACCEPT_STATEMENT_TYPE_ID NUMBER(9);
BEGIN
    INTERPRET_RUN_TYPE(p_RUN_TYPE_ID, v_REQUEST_TYPE, v_SCENARIO_ID);

    IF NVL(p_ACCEPT_INTO_SCHEDULES,0) = 1 THEN
        v_ACCEPT_STATEMENT_TYPE_ID := DETERMINE_SCHED_STATEMENT_TYPE(p_RUN_TYPE_ID, p_SCHEDULE_STATEMENT_TYPE_ID);

        ASSERT(NVL(p_FILTER_MODEL_ID,GA.DEFAULT_MODEL) <> CONSTANTS.ALL_ID, 'Load Data cannot be accepted into schedules for both service types.');
    END IF;

    -- Populate the collection of model ids
    IF p_FILTER_MODEL_ID = CONSTANTS.ALL_ID THEN
        v_MODEL_IDS := NUMBER_COLLECTION(GA.ELECTRIC_MODEL, GA.GAS_MODEL);
    ELSIF p_FILTER_MODEL_ID IS NULL THEN
        v_MODEL_IDS := NUMBER_COLLECTION(GA.DEFAULT_MODEL);
    ELSE
        v_MODEL_IDS := NUMBER_COLLECTION(p_FILTER_MODEL_ID);
    END IF;

    v_IDX := v_MODEL_IDS.FIRST;
    WHILE V_IDX IS NOT NULL
    LOOP

        IF p_ENTITY_DOMAIN_ID = CONSTANTS.ALL_ID THEN
            FS.CAST_SERVICE_REQUEST(v_REQUEST_TYPE, --p_REQUEST_TYPE
                                    GA.STANDARD_MODE, --p_REQUEST_MODE
                                    v_SCENARIO_ID, --p_SCENARIO_ID
                                    v_MODEL_IDS(v_IDX), --p_MODEL_ID
                                    p_PROCESS_ID, --p_PROCESS_ID
                                    CONSTANTS.ALL_ID, --p_EDC_ID
                                    CONSTANTS.ALL_ID, --p_ESP_ID
                                    CONSTANTS.ALL_ID, --p_ACCOUNT_ID
                                    p_BEGIN_DATE, --p_BEGIN_DATE
                                    p_END_DATE, --p_END_DATE
                                    SYSDATE, --p_INPUT_AS_OF_DATE
                                    CONSTANTS.LOW_DATE, --p_OUTPUT_AS_OF_DATE
                                    p_BEGIN_DATE, --p_PROFILE_BEGIN_DATE
                                    CONSTANTS.LOW_DATE, --p_PROFILE_AS_OF_DATE
                                    p_APPLY_USAGE_FACTOR, --p_APPLY_USAGE_FACTOR
                                    p_APPLY_UFE, --p_APPLY_UFE
                                    0, --p_APPLY_UFE_OTHER
                                    0, --p_APPLY_EXTERNAL_FORECAST
                                    SECURITY_CONTROLS.CURRENT_USER, --p_REQUESTOR
                                    p_TRACE_ON, --p_TRACE_ON
                                    p_PROCESS_STATUS, --p_STATUS
                                    p_MESSAGE); --p_MESSAGE
        ELSE
            FOR c_IDS IN (SELECT CASE WHEN p_ENTITY_DOMAIN_ID = EC.ED_EDC THEN IDS.COLUMN_VALUE ELSE CONSTANTS.ALL_ID END AS EDC_ID,
                            CASE WHEN p_ENTITY_DOMAIN_ID = EC.ED_ESP THEN IDS.COLUMN_VALUE ELSE CONSTANTS.ALL_ID END AS ESP_ID,
                            CASE WHEN p_ENTITY_DOMAIN_ID = EC.ED_ACCOUNT THEN IDS.COLUMN_VALUE ELSE CONSTANTS.ALL_ID END AS ACCOUNT_ID
                            FROM TABLE(CAST(p_ENTITY_IDS AS NUMBER_COLLECTION)) IDS)
            LOOP
                FS.CAST_SERVICE_REQUEST(v_REQUEST_TYPE, --p_REQUEST_TYPE
                                        GA.STANDARD_MODE, --p_REQUEST_MODE
                                        v_SCENARIO_ID, --p_SCENARIO_ID
                                        v_MODEL_IDS(v_IDX), --p_MODEL_ID
                                        p_PROCESS_ID, --p_PROCESS_ID
                                        c_IDS.EDC_ID, --p_EDC_ID
                                        c_IDS.ESP_ID, --p_ESP_ID
                                        c_IDS.ACCOUNT_ID, --p_ACCOUNT_ID
                                        p_BEGIN_DATE, --p_BEGIN_DATE
                                        p_END_DATE, --p_END_DATE
                                        SYSDATE, --p_INPUT_AS_OF_DATE
                                        CONSTANTS.LOW_DATE, --p_OUTPUT_AS_OF_DATE
                                        p_BEGIN_DATE, --p_PROFILE_BEGIN_DATE
                                        CONSTANTS.LOW_DATE, --p_PROFILE_AS_OF_DATE
                                        p_APPLY_USAGE_FACTOR, --p_APPLY_USAGE_FACTOR
                                        p_APPLY_UFE, --p_APPLY_UFE
                                        0, --p_APPLY_UFE_OTHER
                                        0, --p_APPLY_EXTERNAL_FORECAST
                                        SECURITY_CONTROLS.CURRENT_USER, --p_REQUESTOR
                                        p_TRACE_ON, --p_TRACE_ON
                                        p_PROCESS_STATUS, --p_STATUS
                                        p_MESSAGE); --p_MESSAGE
            END LOOP;

			-- Roll-up to summary level when running individual accounts (unless we're running in
			-- summary only mode)
			IF p_ENTITY_DOMAIN_ID = EC.ED_ACCOUNT AND NOT GA.CAST_SUMMARY_ONLY_MODE THEN
                FS.CAST_SERVICE_REQUEST(v_REQUEST_TYPE, --p_REQUEST_TYPE
                                        GA.STANDARD_MODE, --p_REQUEST_MODE
                                        v_SCENARIO_ID, --p_SCENARIO_ID
                                        v_MODEL_IDS(v_IDX), --p_MODEL_ID
                                        p_PROCESS_ID, --p_PROCESS_ID
                                        CONSTANTS.ALL_ID, --p_EDC_ID
                                        CONSTANTS.ALL_ID, --p_ESP_ID
                                        -FS.g_SUMMARY_ONLY, --p_ACCOUNT_ID
                                        p_BEGIN_DATE, --p_BEGIN_DATE
                                        p_END_DATE, --p_END_DATE
                                        SYSDATE, --p_INPUT_AS_OF_DATE
                                        CONSTANTS.LOW_DATE, --p_OUTPUT_AS_OF_DATE
                                        p_BEGIN_DATE, --p_PROFILE_BEGIN_DATE
                                        CONSTANTS.LOW_DATE, --p_PROFILE_AS_OF_DATE
                                        p_APPLY_USAGE_FACTOR, --p_APPLY_USAGE_FACTOR
                                        p_APPLY_UFE, --p_APPLY_UFE
                                        0, --p_APPLY_UFE_OTHER
                                        0, --p_APPLY_EXTERNAL_FORECAST
                                        SECURITY_CONTROLS.CURRENT_USER, --p_REQUESTOR
                                        p_TRACE_ON, --p_TRACE_ON
                                        p_PROCESS_STATUS, --p_STATUS
                                        p_MESSAGE); --p_MESSAGE			END IF;
			END IF;

		END IF;

		v_IDX := v_MODEL_IDS.NEXT(V_IDX);
    END LOOP;

    IF NVL(p_ACCEPT_INTO_SCHEDULES,0) = 1 THEN
        ACCEPT_CAST_INTO_SCHEDULES(p_FILTER_MODEL_ID,
                                   v_REQUEST_TYPE,
                                   v_SCENARIO_ID,
                                   v_ACCEPT_STATEMENT_TYPE_ID,
                                   p_BEGIN_DATE,
                                   p_END_DATE,
                                   p_TRACE_ON,
                                   p_PROCESS_ID,
                                   p_PROCESS_STATUS,
                                   p_MESSAGE);
    END IF;

END RUN_CAST_SERVICE_REQUEST;
--------------------------------------------------------
PROCEDURE GET_ACCOUNT_ENROLLMENT_SUMMARY
    (
    p_TIME_ZONE             IN VARCHAR2,
    p_BEGIN_DATE            IN DATE,
    p_END_DATE              IN DATE,
    p_ENROLLMENT_CASE_ID    IN NUMBER,
    p_FILTER_MODEL_ID       IN NUMBER,
    p_FILTER_SC_ID          IN NUMBER,
    p_SHOW_FILTER_SC_ID     IN NUMBER,
    p_FILTER_EDC_ID         IN NUMBER,
    p_SHOW_FILTER_EDC_ID    IN NUMBER,
    p_FILTER_ESP_ID         IN NUMBER,
    p_SHOW_FILTER_ESP_ID    IN NUMBER,
    p_FILTER_PSE_ID         IN NUMBER,
    p_SHOW_FILTER_PSE_ID    IN NUMBER,
    p_FILTER_POOL_ID        IN NUMBER,
    p_SHOW_FILTER_POOL_ID   IN NUMBER,
    p_SHOW_DETAILS          IN NUMBER,
    p_CURSOR                OUT GA.REFCURSOR
    ) AS

    v_EDC_ID NUMBER(9) := NVL(p_FILTER_EDC_ID, CONSTANTS.ALL_ID);
    v_SHOW_EDC_ID NUMBER(1) := NVL(p_SHOW_FILTER_EDC_ID, 0);

    v_SC_ID NUMBER(9) := NVL(p_FILTER_SC_ID, CONSTANTS.ALL_ID);
    v_SHOW_SC_ID NUMBER(1) := NVL(p_SHOW_FILTER_SC_ID, 0);

    v_ESP_ID NUMBER(9) := NVL(p_FILTER_ESP_ID, CONSTANTS.ALL_ID);
    v_SHOW_ESP_ID NUMBER(1) := NVL(p_SHOW_FILTER_ESP_ID, 0);

    v_PSE_ID NUMBER(9) := NVL(p_FILTER_PSE_ID, CONSTANTS.ALL_ID);
    v_SHOW_PSE_ID NUMBER(1) := NVL(p_SHOW_FILTER_PSE_ID, 0);

    v_POOL_ID NUMBER(9) := NVL(p_FILTER_POOL_ID, CONSTANTS.ALL_ID);
    v_SHOW_POOL_ID NUMBER(1) := NVL(p_SHOW_FILTER_POOL_ID, 0);

    v_MODEL_ID NUMBER(9) := NVL(p_FILTER_MODEL_ID,GA.DEFAULT_MODEL);
    v_SHOW_MODEL_ID NUMBER(1) := CASE WHEN p_FILTER_MODEL_ID IS NULL THEN 0 ELSE 1 END;

    v_MIN_INTERVAL_NUM NUMBER := GET_INTERVAL_NUMBER(CONSTANTS.INTERVAL_DAY);

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
        Q.ESP_ID,
        Q.ESP_NAME,
        Q.PSE_ID,
        Q.PSE_NAME,
        Q.POOL_ID,
        Q.POOL_NAME,
        Q.MODEL,
        Q.COLUMN_MODEL_ID,
        SUM(Q.TOTAL_COUNT) AS TOTAL_COUNT,
        SUM(Q.AGG_COUNT) AS AGG_COUNT,
        SUM(Q.NON_AGG_COUNT) AS NON_AGG_COUNT
    FROM (SELECT DATA.LOCAL_DATE,
            DATA.LOCAL_DAY_TRUNC_DATE,
            CASE WHEN v_SHOW_SC_ID = 1 THEN SC.SC_ID ELSE CONSTANTS.ALL_ID END SC_ID,
            CASE WHEN v_SHOW_SC_ID = 1 THEN SC.SC_NAME ELSE NULL END SC_NAME,
            CASE WHEN v_SHOW_EDC_ID = 1 THEN EDC.EDC_ID ELSE CONSTANTS.ALL_ID END EDC_ID,
            CASE WHEN v_SHOW_EDC_ID = 1 THEN EDC.EDC_NAME ELSE NULL END EDC_NAME,
            CASE WHEN v_SHOW_ESP_ID = 1 THEN ESP.ESP_ID ELSE CONSTANTS.ALL_ID END ESP_ID,
            CASE WHEN v_SHOW_ESP_ID = 1 THEN ESP.ESP_NAME ELSE NULL END ESP_NAME,
            CASE WHEN v_SHOW_MODEL_ID = 1 THEN (CASE WHEN DATA.MODEL_ID = CONSTANTS.ELECTRIC_MODEL THEN 'Electric' ELSE 'Gas' END)
                ELSE NULL END AS MODEL,
            CASE WHEN v_SHOW_MODEL_ID = 1 THEN DATA.MODEL_ID ELSE GA.DEFAULT_MODEL END AS COLUMN_MODEL_ID,
            CASE WHEN v_SHOW_PSE_ID = 1 THEN PSE.PSE_ID ELSE CONSTANTS.ALL_ID END PSE_ID,
            CASE WHEN v_SHOW_PSE_ID = 1 THEN PSE.PSE_NAME ELSE NULL END PSE_NAME,
            CASE WHEN v_SHOW_POOL_ID = 1 THEN P.POOL_ID ELSE CONSTANTS.ALL_ID END POOL_ID,
            CASE WHEN v_SHOW_POOL_ID = 1 THEN P.POOL_NAME ELSE NULL END POOL_NAME,
            CASE WHEN P.POOL_ID IS NULL THEN NULL ELSE (NVL(DATA.AGG_COUNT,0) + NVL(DATA.NON_AGG_COUNT,0)) END AS TOTAL_COUNT,
            CASE WHEN P.POOL_ID IS NULL THEN NULL ELSE (CASE WHEN p_SHOW_DETAILS = 1 THEN NVL(DATA.AGG_COUNT,0) ELSE NULL END) END AS AGG_COUNT,
            CASE WHEN P.POOL_ID IS NULL THEN NULL ELSE (CASE WHEN p_SHOW_DETAILS = 1 THEN NVL(DATA.NON_AGG_COUNT,0) ELSE NULL END) END AS NON_AGG_COUNT
        FROM (SELECT SDT.LOCAL_DATE,
                    SDT.LOCAL_DAY_TRUNC_DATE,
                    D.NON_AGG_COUNT,
                    D.AGG_COUNT,
                    D.EDC_ID,
                    D.PSE_ID,
                    D.ESP_ID,
                    D.POOL_ID,
                    D.EDC_SC_ID,
                    D.MODEL_ID
              FROM (SELECT SDT.LOCAL_DATE,
                        COUNT(A.ACCOUNT_ID) AS NON_AGG_COUNT,
                        0 AS AGG_COUNT,
                        EDC.EDC_ID,
                        PE.PSE_ID,
                        AESP.ESP_ID,
                        AESP.POOL_ID,
                        EDC.EDC_SC_ID,
                        NVL(A.MODEL_ID, GA.DEFAULT_MODEL) AS MODEL_ID
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
                    0 AS NON_AGG_COUNT,
                    SUM(AAS.ENROLLED_ACCOUNTS) AS AGG_COUNT,
                    EDC.EDC_ID,
                    PE.PSE_ID,
                    AESP.ESP_ID,
                    AESP.POOL_ID,
                    EDC.EDC_SC_ID,
                    NVL(A.MODEL_ID, GA.DEFAULT_MODEL) AS MODEL_ID
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
                    EDC.EDC_SC_ID, PE.PSE_ID, NVL(A.MODEL_ID, GA.DEFAULT_MODEL)) D,
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
        Q.COLUMN_MODEL_ID
    ORDER BY Q.LOCAL_DATE,
            Q.MODEL,
            Q.SC_NAME,
            Q.EDC_NAME,
            Q.ESP_NAME,
            Q.PSE_NAME,
            Q.POOL_NAME;

END GET_ACCOUNT_ENROLLMENT_SUMMARY;
--------------------------------------------------------
PROCEDURE GET_LOAD_DETAILS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_ENTITY_TYPE       IN VARCHAR2,
    p_ENTITY_ID         IN NUMBER,
    p_ACCOUNT_ID        IN NUMBER,
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_METER_ID          IN NUMBER,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_UOM               OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    )
AS
    v_MODEL_ID NUMBER(9);
    v_ACCOUNT_MODEL_OPTION ACCOUNT.ACCOUNT_MODEL_OPTION%TYPE;
	v_IS_SUB_AGGREGATE ACCOUNT.IS_SUB_AGGREGATE%TYPE;
    v_SERVICE_CODE CHAR(1);
    v_SCENARIO_ID NUMBER(9);

    v_BEGIN DATE;
    v_END DATE;

    v_CUT_BEGIN_DATE DATE;
    v_CUT_END_DATE DATE;

    v_SHOW_W NUMBER(1) := 0;
    v_SHOW_WO NUMBER(1) := 0;
    v_SHOW_DETAILS NUMBER(1) := 0;
BEGIN
    IF p_ENTITY_ID < 0 OR p_ENTITY_ID IS NULL THEN
       	OPEN p_CURSOR FOR
		    SELECT NULL	FROM DUAL;
        RETURN;
    END IF;

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

    -- Get Account's Model Id and Model Option
    SELECT A.MODEL_ID, A.ACCOUNT_MODEL_OPTION, A.IS_SUB_AGGREGATE
    INTO v_MODEL_ID, v_ACCOUNT_MODEL_OPTION, v_IS_SUB_AGGREGATE
    FROM ACCOUNT A
    WHERE A.ACCOUNT_ID = p_ACCOUNT_ID;

    p_UOM := CASE WHEN v_MODEL_ID = GA.ELECTRIC_MODEL THEN GA.ELECTRIC_UNIT_OF_MEASURMENT
                    WHEN v_MODEL_ID = GA.GAS_MODEL THEN GA.GAS_UNIT_OF_MEASURMENT END;

    IF v_IS_SUB_AGGREGATE = 1 THEN
		-- Call ENSURE_SERVICE_DETAILS for each Aggregate Id
		FOR v_REC IN (-- Account Aggregations
					  SELECT C.ACCOUNT_ID AS AGG_ACCOUNT_ID,
							 A.ACCOUNT_ID AS SUB_AGG_ACCOUNT_ID,
							 B.AGGREGATE_ID,
							 GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AS BEGIN_DATE,
							 LEAST(p_END_DATE, NVL(B.END_DATE, CONSTANTS.HIGH_DATE)) AS END_DATE
					  FROM ACCOUNT A,
						   ACCOUNT_SUB_AGG_AGGREGATION B,
						   AGGREGATE_ACCOUNT_ESP C
					  WHERE C.AGGREGATE_ID = B.AGGREGATE_ID
					  AND B.ACCOUNT_ID = A.ACCOUNT_ID
					  AND B.BEGIN_DATE <= p_END_DATE
					  AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
					  AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT
					  AND A.ACCOUNT_ID = p_ACCOUNT_ID
					  UNION
					  -- Meter Aggregations
					  SELECT C.ACCOUNT_ID AS AGG_ACCOUNT_ID,
							 A.ACCOUNT_ID AS SUB_AGG_ACCOUNT_ID,
							 --M.METER_ID AS METER_ID,
							 --M.METER_NAME AS METER_NAME,
							 B.AGGREGATE_ID,
							 GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AS BEGIN_DATE,
							 LEAST(p_END_DATE, B.END_DATE) AS END_DATE
					  FROM ACCOUNT A,
						   ACCOUNT_SERVICE_LOCATION ASL,
						   SERVICE_LOCATION_METER SM,
						   METER_SUB_AGG_AGGREGATION B,
						   AGGREGATE_ACCOUNT_ESP C
					  WHERE C.AGGREGATE_ID = B.AGGREGATE_ID
					  AND B.METER_ID = SM.METER_ID
					  AND (NVL(p_METER_ID,CONSTANTS.ALL_ID) = CONSTANTS.ALL_ID OR SM.METER_ID = p_METER_ID)
					  AND SM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
					  AND SM.BEGIN_DATE <= p_END_DATE
					  AND NVL(SM.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
					  AND ASL.ACCOUNT_ID = A.ACCOUNT_ID
					  AND ASL.BEGIN_DATE <= p_END_DATE
					  AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
					  AND B.BEGIN_DATE <= p_END_DATE
					  AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
					  AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER
					  AND A.ACCOUNT_ID = p_ACCOUNT_ID) LOOP
			FS.ENSURE_SERVICE_DETAILS(v_SERVICE_CODE,
									  v_MODEL_ID,
									  v_SCENARIO_ID,
									  CONSTANTS.ALL_ID,
									  CONSTANTS.ALL_ID,
									  NUMBER_COLLECTION(v_REC.AGG_ACCOUNT_ID),
									  v_REC.BEGIN_DATE,
									  v_REC.END_DATE,
									  CONSTANTS.LOW_DATE);
		END LOOP;
	ELSE
		FS.ENSURE_SERVICE_DETAILS(v_SERVICE_CODE,
								  v_MODEL_ID,
								  v_SCENARIO_ID,
								  CONSTANTS.ALL_ID,
								  CONSTANTS.ALL_ID,
								  NUMBER_COLLECTION(p_ACCOUNT_ID),
								  p_BEGIN_DATE,
								  p_END_DATE,
								  CONSTANTS.LOW_DATE);
	END IF;

    IF v_ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE THEN
        OPEN p_CURSOR FOR
            SELECT L.DT,
                p_ACCOUNT_ID AS ACCOUNT_ID,
                NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED) AS METER_ID,
                ESP_NAME,
				ESP_ID,
                POOL_NAME,
				POOL_ID,
                ENTITY_NAME,
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
                    X.ACCOUNT_ID,
                    X.METER_ID,
                    ESP_NAME,
					ESP_ID,
                    POOL_NAME,
					POOL_ID,
                    NULL AS ENTITY_NAME,
                    CASE WHEN v_SHOW_W = 1 THEN X.LOAD_VAL+X.TX_LOSS_VAL+X.DX_LOSS_VAL+X.UE_LOSS_VAL ELSE NULL END AS WITH_LOSSES,
                    CASE WHEN v_SHOW_WO = 1 THEN X.LOAD_VAL ELSE NULL END AS WITHOUT_LOSSES,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.TX_LOSS_VAL ELSE NULL END AS TX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.DX_LOSS_VAL ELSE NULL END AS DX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.UE_LOSS_VAL ELSE NULL END AS UE_LOSS_VAL
                FROM (SELECT SL.LOAD_DATE,
                        S.MODEL_ID,
                        ASRV.ACCOUNT_ID,
                        ASRV.SERVICE_LOCATION_ID,
                        ASRV.METER_ID,
                        ESP.ESP_NAME,
						ESP.ESP_ID,
                        P.POOL_NAME,
						P.POOL_ID,
                        ASRV.AGGREGATE_ID,
                        SL.LOAD_VAL,
                        SL.TX_LOSS_VAL,
                        SL.DX_LOSS_VAL,
                        SL.UE_LOSS_VAL
                    FROM SERVICE S,
                        ACCOUNT_SERVICE ASRV,
                        SERVICE_LOAD SL,
                        AGGREGATE_ACCOUNT_ESP AAE,
                        ENERGY_SERVICE_PROVIDER ESP,
                        POOL P
                    WHERE S.MODEL_ID = v_MODEL_ID
                        AND S.SCENARIO_ID = v_SCENARIO_ID
                        AND S.AS_OF_DATE = CONSTANTS.LOW_DATE
                        AND ASRV.ACCOUNT_SERVICE_ID = S.ACCOUNT_SERVICE_ID
                        AND ((ASRV.ACCOUNT_ID = p_ACCOUNT_ID AND p_ENTITY_TYPE = 'ACCOUNT')
                                OR (ASRV.SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID AND p_ENTITY_TYPE = 'SERVICE_LOCATION')
                                OR (ASRV.METER_ID = p_METER_ID AND p_ENTITY_TYPE = 'METER'))
                        AND SL.SERVICE_ID = S.SERVICE_ID
                        AND SL.SERVICE_CODE = v_SERVICE_CODE
                        AND ((S.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE)
                                OR (S.MODEL_ID = CONSTANTS.GAS_MODEL AND SL.LOAD_DATE BETWEEN v_BEGIN AND v_END))
                        AND AAE.AGGREGATE_ID = ASRV.AGGREGATE_ID
                        AND ESP.ESP_ID = AAE.ESP_ID
                        AND P.POOL_ID = AAE.POOL_ID) X,
                        SYSTEM_DATE_TIME SDT
                    WHERE SDT.TIME_ZONE = p_TIME_ZONE
                        AND SDT.DAY_TYPE = GA.STANDARD
                        AND v_MODEL_ID IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
                        AND X.MODEL_ID (+) = SDT.DATA_INTERVAL_TYPE
                        AND X.LOAD_DATE (+) = SDT.CUT_DATE
                        AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                              AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END) L
            GROUP BY L.DT, ACCOUNT_ID, NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED), L.ESP_NAME, L.ESP_ID, L.POOL_NAME, L.POOL_ID, L.ENTITY_NAME
            ORDER BY L.DT, L.ESP_NAME, L.POOL_NAME;
	ELSIF v_IS_SUB_AGGREGATE = 1 THEN

		OPEN p_CURSOR FOR
            SELECT L.DT,
                p_ACCOUNT_ID AS ACCOUNT_ID,
                NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED) AS METER_ID,
                ESP_NAME,
				NVL(ESP_ID, CONSTANTS.NOT_ASSIGNED) AS ESP_ID,
                POOL_NAME,
				NVL(POOL_ID, CONSTANTS.NOT_ASSIGNED) AS POOL_ID,
                ENTITY_NAME,
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
                    X.ACCOUNT_ID,
                    X.METER_ID,
                    NULL AS ESP_NAME,
					NULL AS ESP_ID,
                    NULL AS POOL_NAME,
					NULL AS POOL_ID,
                    CASE WHEN p_ENTITY_TYPE = 'ACCOUNT' THEN X.ACCOUNT_NAME
                        WHEN p_ENTITY_TYPE = 'SERVICE_LOCATION' THEN X.SERVICE_LOCATION_NAME
                        WHEN p_ENTITY_TYPE = 'METER' THEN X.METER_NAME
                    END AS ENTITY_NAME,
                    CASE WHEN v_SHOW_W = 1 THEN X.LOAD_VAL+X.TX_LOSS_VAL+X.DX_LOSS_VAL+X.UE_LOSS_VAL ELSE NULL END AS WITH_LOSSES,
                    CASE WHEN v_SHOW_WO = 1 THEN X.LOAD_VAL ELSE NULL END AS WITHOUT_LOSSES,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.TX_LOSS_VAL ELSE NULL END AS TX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.DX_LOSS_VAL ELSE NULL END AS DX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.UE_LOSS_VAL ELSE NULL END AS UE_LOSS_VAL
                FROM (-- Get Ajusted Load Data for the Aggregate Accounts
					  SELECT SL.LOAD_DATE,
							X.MODEL_ID,
							X.ACCOUNT_ID,
							X.ACCOUNT_NAME,
							p_SERVICE_LOCATION_ID AS SERVICE_LOCATION_ID,
							CASE WHEN p_SERVICE_LOCATION_ID IS NULL THEN NULL ELSE EI.GET_ENTITY_NAME(EC.ED_SERVICE_LOCATION, p_SERVICE_LOCATION_ID) END AS SERVICE_LOCATION_NAME,
							p_METER_ID AS METER_ID,
							X.METER_NAME AS METER_NAME,
							X.AGGREGATE_ID AS AGGREGATE_ID,
							SL.LOAD_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) AS LOAD_VAL,
							SL.TX_LOSS_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) AS TX_LOSS_VAL,
							SL.DX_LOSS_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) AS DX_LOSS_VAL,
							SL.UE_LOSS_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) AS UE_LOSS_VAL
						FROM SERVICE_LOAD SL,
							 -- Get the Agg Account Service State information including Sub Aggregate UF
							 (SELECT X.*,
							         UF.FACTOR_VAL AS SUB_AGG_USAGE_FACTOR
							  FROM ACCOUNT_USAGE_FACTOR UF,
								  -- Get the Sub Aggregate Account, Aggregate Id, and Service State information by Service Date
								  (SELECT A.ACCOUNT_ID,
										 A.ACCOUNT_NAME,
										 NULL AS METER_ID,
										 NULL AS METER_NAME,
										 B.AGGREGATE_ID,
										 C.MODEL_ID,
										 C.SERVICE_ID,
										 D.SERVICE_DATE,
										 D.USAGE_FACTOR AS AVERAGE_USAGE_FACTOR,
										 D.SERVICE_ACCOUNTS
								   FROM ACCOUNT A,
									   ACCOUNT_SUB_AGG_AGGREGATION B,
									   SERVICE C,
									   SERVICE_STATE D,
									   ACCOUNT_SERVICE E
								   WHERE C.ACCOUNT_SERVICE_ID = E.ACCOUNT_SERVICE_ID
								     AND C.AS_OF_DATE = CONSTANTS.LOW_DATE
								     AND C.SCENARIO_ID = v_SCENARIO_ID
								     AND C.MODEL_ID = v_MODEL_ID
								     AND C.SERVICE_ID = D.SERVICE_ID
								     AND D.SERVICE_CODE = v_SERVICE_CODE
								     AND D.SERVICE_DATE BETWEEN GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AND LEAST(p_END_DATE, NVL(B.END_DATE, CONSTANTS.HIGH_DATE))
								     AND E.AGGREGATE_ID = B.AGGREGATE_ID
								     AND B.ACCOUNT_ID = A.ACCOUNT_ID
								     AND B.BEGIN_DATE <= p_END_DATE
								     AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
								     AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT
								     AND A.ACCOUNT_ID = p_ACCOUNT_ID) X
							  WHERE UF.ACCOUNT_ID (+) = X.ACCOUNT_ID
							    AND UF.CASE_ID (+) = GA.BASE_CASE_ID
							    AND X.SERVICE_DATE BETWEEN UF.BEGIN_DATE (+) AND NVL(UF.END_DATE (+), CONSTANTS.HIGH_DATE)
							UNION
							-- Meter Version
							SELECT X.*,
							       UF.FACTOR_VAL AS SUB_AGG_USAGE_FACTOR
							FROM METER_USAGE_FACTOR UF,
								  -- Get the Sub Aggregate Meter, Aggregate Id, and Service State information by Service Date
								  (SELECT A.ACCOUNT_ID,
										 A.ACCOUNT_NAME,
										 M.METER_ID AS METER_ID,
										 M.METER_NAME AS METER_NAME,
										 B.AGGREGATE_ID,
										 C.MODEL_ID,
										 C.SERVICE_ID,
										 D.SERVICE_DATE,
										 D.USAGE_FACTOR AS AVERAGE_USAGE_FACTOR,
										 D.SERVICE_ACCOUNTS
								  FROM ACCOUNT A,
									   ACCOUNT_SERVICE_LOCATION ASL,
									   SERVICE_LOCATION_METER SM,
									   METER_SUB_AGG_AGGREGATION B,
									   METER M,
									   SERVICE C,
									   SERVICE_STATE D,
									   ACCOUNT_SERVICE E
								  WHERE C.ACCOUNT_SERVICE_ID = E.ACCOUNT_SERVICE_ID
								  AND C.AS_OF_DATE = CONSTANTS.LOW_DATE
								  AND C.SCENARIO_ID = v_SCENARIO_ID
								  AND C.MODEL_ID = v_MODEL_ID
								  AND C.SERVICE_ID = D.SERVICE_ID
								  AND D.SERVICE_CODE = v_SERVICE_CODE
								  AND D.SERVICE_DATE BETWEEN GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AND LEAST(p_END_DATE, NVL(B.END_DATE, CONSTANTS.HIGH_DATE))
								  AND E.AGGREGATE_ID = B.AGGREGATE_ID
								  AND B.METER_ID = M.METER_ID
								  AND (NVL(p_METER_ID,CONSTANTS.ALL_ID) = CONSTANTS.ALL_ID OR M.METER_ID = p_METER_ID)
								  AND M.METER_ID = SM.METER_ID
								  AND SM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
								  AND SM.BEGIN_DATE <= p_END_DATE
								  AND NVL(SM.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
								  AND ASL.ACCOUNT_ID = A.ACCOUNT_ID
								  AND ASL.BEGIN_DATE <= p_END_DATE
								  AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
								  AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER
								  AND A.ACCOUNT_ID = p_ACCOUNT_ID) X
							WHERE UF.METER_ID (+) = X.METER_ID
							  AND UF.CASE_ID (+) = GA.BASE_CASE_ID
							  AND X.SERVICE_DATE BETWEEN UF.BEGIN_DATE (+) AND NVL(UF.END_DATE (+), CONSTANTS.HIGH_DATE)
							  ) X
						WHERE SL.SERVICE_ID = X.SERVICE_ID
						  AND SL.SERVICE_CODE = v_SERVICE_CODE
						  AND ((X.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SL.LOAD_DATE BETWEEN ADD_SECONDS_TO_DATE(TO_CUT(TRUNC(X.SERVICE_DATE), p_TIME_ZONE), 1) AND TO_CUT(TRUNC(X.SERVICE_DATE) + 1, p_TIME_ZONE))
									OR (X.MODEL_ID = CONSTANTS.GAS_MODEL AND SL.LOAD_DATE = TRUNC(X.SERVICE_DATE)))) X,
                        SYSTEM_DATE_TIME SDT
                    WHERE SDT.TIME_ZONE = p_TIME_ZONE
                        AND SDT.DAY_TYPE = GA.STANDARD
                        AND v_MODEL_ID IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
                        AND X.MODEL_ID (+) = SDT.DATA_INTERVAL_TYPE
                        AND X.LOAD_DATE (+) = SDT.CUT_DATE
                        AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                              AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END) L
            GROUP BY L.DT, ACCOUNT_ID, NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED), L.ESP_NAME, NVL(ESP_ID, CONSTANTS.NOT_ASSIGNED), L.POOL_NAME, NVL(POOL_ID, CONSTANTS.NOT_ASSIGNED), L.ENTITY_NAME
            ORDER BY L.DT, L.ENTITY_NAME;

	ELSE
        OPEN p_CURSOR FOR
            SELECT L.DT,
                p_ACCOUNT_ID AS ACCOUNT_ID,
                NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED) AS METER_ID,
                ESP_NAME,
				NVL(ESP_ID, CONSTANTS.NOT_ASSIGNED) AS ESP_ID,
                POOL_NAME,
				NVL(POOL_ID, CONSTANTS.NOT_ASSIGNED) AS POOL_ID,
                ENTITY_NAME,
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
                    X.ACCOUNT_ID,
                    X.METER_ID,
                    NULL AS ESP_NAME,
					NULL AS ESP_ID,
                    NULL AS POOL_NAME,
					NULL AS POOL_ID,
                    CASE WHEN p_ENTITY_TYPE = 'ACCOUNT' THEN X.ACCOUNT_NAME
                        WHEN p_ENTITY_TYPE = 'SERVICE_LOCATION' THEN X.SERVICE_LOCATION_NAME
                        WHEN p_ENTITY_TYPE = 'METER' THEN X.METER_NAME
                    END AS ENTITY_NAME,
                    CASE WHEN v_SHOW_W = 1 THEN X.LOAD_VAL+X.TX_LOSS_VAL+X.DX_LOSS_VAL+X.UE_LOSS_VAL ELSE NULL END AS WITH_LOSSES,
                    CASE WHEN v_SHOW_WO = 1 THEN X.LOAD_VAL ELSE NULL END AS WITHOUT_LOSSES,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.TX_LOSS_VAL ELSE NULL END AS TX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.DX_LOSS_VAL ELSE NULL END AS DX_LOSS_VAL,
                    CASE WHEN v_SHOW_DETAILS = 1 THEN X.UE_LOSS_VAL ELSE NULL END AS UE_LOSS_VAL
                FROM (SELECT SL.LOAD_DATE,
                        S.MODEL_ID,
                        ASRV.ACCOUNT_ID,
                        A.ACCOUNT_NAME,
                        ASRV.SERVICE_LOCATION_ID,
                        SLOC.SERVICE_LOCATION_NAME,
                        ASRV.METER_ID,
                        M.METER_NAME,
                        ASRV.AGGREGATE_ID,
                        SL.LOAD_VAL,
                        SL.TX_LOSS_VAL,
                        SL.DX_LOSS_VAL,
                        SL.UE_LOSS_VAL
                    FROM SERVICE S,
                        ACCOUNT_SERVICE ASRV,
                        SERVICE_LOAD SL,
                        ACCOUNT A,
                        SERVICE_LOCATION SLOC,
                        METER M
                    WHERE S.MODEL_ID = v_MODEL_ID
                        AND S.SCENARIO_ID = v_SCENARIO_ID
                        AND S.AS_OF_DATE = CONSTANTS.LOW_DATE
                        AND ASRV.ACCOUNT_SERVICE_ID = S.ACCOUNT_SERVICE_ID
                        AND ((ASRV.ACCOUNT_ID = p_ACCOUNT_ID AND p_ENTITY_TYPE = 'ACCOUNT')
                                OR (ASRV.SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID AND p_ENTITY_TYPE = 'SERVICE_LOCATION')
                                OR (ASRV.METER_ID = p_METER_ID AND p_ENTITY_TYPE = 'METER'))
                        AND SL.SERVICE_ID = S.SERVICE_ID
                        AND SL.SERVICE_CODE = v_SERVICE_CODE
                        AND ((S.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE)
                                OR (S.MODEL_ID = CONSTANTS.GAS_MODEL AND SL.LOAD_DATE BETWEEN v_BEGIN AND v_END))
                        AND A.ACCOUNT_ID(+) = NVL(ASRV.ACCOUNT_ID, p_ACCOUNT_ID)
                        AND SLOC.SERVICE_LOCATION_ID(+) = NVL(ASRV.SERVICE_LOCATION_ID, p_SERVICE_LOCATION_ID)
                        AND M.METER_ID(+) = NVL(ASRV.METER_ID, p_METER_ID)) X,
                        SYSTEM_DATE_TIME SDT
                    WHERE SDT.TIME_ZONE = p_TIME_ZONE
                        AND SDT.DAY_TYPE = GA.STANDARD
                        AND v_MODEL_ID IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
                        AND X.MODEL_ID (+) = SDT.DATA_INTERVAL_TYPE
                        AND X.LOAD_DATE (+) = SDT.CUT_DATE
                        AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                              AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END) L
            GROUP BY L.DT, ACCOUNT_ID, NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED), L.ESP_NAME, NVL(ESP_ID, CONSTANTS.NOT_ASSIGNED), L.POOL_NAME, NVL(POOL_ID, CONSTANTS.NOT_ASSIGNED), L.ENTITY_NAME
            ORDER BY L.DT, L.ENTITY_NAME;
        END IF;
END GET_LOAD_DETAILS;
--------------------------------------------------------
PROCEDURE GET_SERVICE_STATE_DETAILS
	(
	p_BEGIN_DATE          IN DATE,
	p_END_DATE            IN DATE,
	p_RUN_TYPE_ID         IN NUMBER,
	p_ACCOUNT_ID          IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID            IN NUMBER,
	p_ESP_ID              IN NUMBER,
	p_POOL_ID             IN NUMBER,
	p_CURSOR              OUT GA.REFCURSOR
	) AS

v_TIME_ZONE VARCHAR2(16);
v_SERVICE_CODE CHAR(1);
v_SCENARIO_ID NUMBER(9);
v_AGGREGATE_ID NUMBER(9);

BEGIN
	INTERPRET_RUN_TYPE(p_RUN_TYPE_ID,v_SERVICE_CODE,v_SCENARIO_ID);

	v_TIME_ZONE := LOCAL_TIME_ZONE;

	-- If ESP_ID and POOL_ID are provided then we are dealing with an Aggregate Account
	-- Get the Aggregate Id to use when joining on ACCOUNT_SERVICE
	IF NVL(p_ESP_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
		SELECT MAX(E.AGGREGATE_ID)
		INTO v_AGGREGATE_ID
		FROM AGGREGATE_ACCOUNT_ESP E
		WHERE E.ACCOUNT_ID = p_ACCOUNT_ID
		AND E.ESP_ID = p_ESP_ID
		AND E.POOL_ID = NVL(p_POOL_ID, CONSTANTS.NOT_ASSIGNED);
	END IF;

	OPEN p_CURSOR FOR
		SELECT X.*,
			   SDT.LOCAL_DATE
		FROM (SELECT SS.SERVICE_DATE,
					   SL.SERVICE_LOCATION_ID,
					   CASE WHEN A.ACCOUNT_MODEL_OPTION = 'Meter'
							 AND NVL(p_SERVICE_LOCATION_ID, CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED
							 AND NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED THEN
								 SL.SERVICE_LOCATION_NAME
							ELSE NULL END as SERVICE_LOCATION_NAME,
					   M.METER_ID,
					   CASE WHEN A.ACCOUNT_MODEL_OPTION = 'Meter'
							 AND NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED THEN
								 M.METER_NAME
							ELSE NULL END as METER_NAME,
					   SS.IS_UFE_PARTICIPANT,
					   CASE WHEN SS.SERVICE_ACCOUNTS = 1 AND SS.IS_AGGREGATE_ACCOUNT = 0 THEN NULL ELSE SS.SERVICE_ACCOUNTS END as METER_COUNT,
					   CASE WHEN SS.METER_TYPE = CONSTANTS.METER_TYPE_INTERVAL THEN ACCOUNTS_METERS.c_METER_TYPE_INTERVAL
							WHEN SS.METER_TYPE = CONSTANTS.METER_TYPE_PERIOD THEN ACCOUNTS_METERS.c_METER_TYPE_PERIOD
							ELSE SS.METER_TYPE END as METER_TYPE,
					   SS.IS_EXTERNAL_FORECAST,
					   SS.IS_AGGREGATE_ACCOUNT,
					   SS.IS_AGGREGATE_POOL,
					   QC.EXPAND_SVC_STATE_PROFILE_TYPE(SS.PROFILE_TYPE) as PROFILE_TYPE,
					   SS.PROFILE_SOURCE_DATE,
					   SS.PROXY_DAY_METHOD_ID,
					   PDM.PROXY_DAY_METHOD_NAME,
					   SS.USAGE_FACTOR,
					   SS.SERVICE_INTERVALS
				FROM ACCOUNT_SERVICE ASVC,
					 SERVICE S,
					 SERVICE_STATE SS,
					 SERVICE_LOCATION SL,
					 METER M,
					 ACCOUNT A,
					 PROXY_DAY_METHOD PDM
				WHERE ASVC.ACCOUNT_ID = p_ACCOUNT_ID
				  AND (NVL(p_SERVICE_LOCATION_ID, CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED OR ASVC.SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID)
				  AND (NVL(p_METER_ID, CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED OR ASVC.METER_ID = p_METER_ID)
				  AND A.ACCOUNT_ID = ASVC.ACCOUNT_ID
				  AND SL.SERVICE_LOCATION_ID = NVL(ASVC.SERVICE_LOCATION_ID, CONSTANTS.NOT_ASSIGNED)
				  AND M.METER_ID = NVL(ASVC.METER_ID, CONSTANTS.NOT_ASSIGNED)
				  AND (v_AGGREGATE_ID IS NULL OR v_AGGREGATE_ID = ASVC.AGGREGATE_ID)
				  AND S.ACCOUNT_SERVICE_ID = ASVC.ACCOUNT_SERVICE_ID
				  AND S.SCENARIO_ID = v_SCENARIO_ID
				  AND SS.SERVICE_ID = S.SERVICE_ID
				  AND SS.SERVICE_CODE = v_SERVICE_CODE
				  AND SS.SERVICE_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
				  AND PDM.PROXY_DAY_METHOD_ID (+) = SS.PROXY_DAY_METHOD_ID) X,
			  SYSTEM_DATE_TIME SDT
		WHERE X.SERVICE_DATE (+) = SDT.LOCAL_DATE
		  -- 1 = Sub-Daily, 2 = Daily and greater. Use 2 for only daily data.
		  AND SDT.DATA_INTERVAL_TYPE = '2'
		  -- Maps to GA.STANDARD & SERVICE_LOAD.LOAD_CODE. Use 1 for Standard.
		  AND SDT.DAY_TYPE = 1
		  AND SDT.TIME_ZONE = LOCAL_TIME_ZONE
		  AND SDT.LOCAL_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
		ORDER BY LOCAL_DATE, SERVICE_LOCATION_NAME, METER_NAME;


END GET_SERVICE_STATE_DETAILS;
--------------------------------------------------------
PROCEDURE ENTITY_ATTRIBUTE_LIST
    (
    p_CURSOR OUT GA.REFCURSOR
    ) AS
BEGIN
    OPEN p_CURSOR FOR
        SELECT E.ATTRIBUTE_ID, E.ATTRIBUTE_NAME
        FROM ENTITY_ATTRIBUTE E
        WHERE E.ENTITY_DOMAIN_ID = EC.ED_ACCOUNT
        ORDER BY E.ATTRIBUTE_NAME;
END ENTITY_ATTRIBUTE_LIST;
--------------------------------------------------------
PROCEDURE ENTITY_ATTRIBUTE_VAL_LIST
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_ATTRIBUTE_ID      IN VARCHAR2,
    p_ATTRIBUTE_SEARCH_STRING IN VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS
BEGIN
    OPEN p_CURSOR FOR
        SELECT DISTINCT E.ATTRIBUTE_VAL
        FROM TEMPORAL_ENTITY_ATTRIBUTE E
        WHERE E.BEGIN_DATE <= p_END_DATE
            AND NVL(E.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
            AND E.ENTITY_DOMAIN_ID = EC.ED_ACCOUNT
            AND E.ATTRIBUTE_ID = p_ATTRIBUTE_ID
            AND UPPER(E.ATTRIBUTE_VAL) LIKE GUI_UTIL.FIX_SEARCH_STRING(UPPER(p_ATTRIBUTE_SEARCH_STRING))
        ORDER BY E.ATTRIBUTE_VAL;
END ENTITY_ATTRIBUTE_VAL_LIST;
--------------------------------------------------------
PROCEDURE GET_LOAD_DTLS_BY_ENTITY_ATTB
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_ATTRIBUTE_ID      IN VARCHAR2,
    p_ATTRIBUTE_VAL     IN VARCHAR2,
    p_SHOW_DETAILS      IN NUMBER,
    p_SUB_AGG_ACCT_SEARCH_BY IN VARCHAR2, -- By Name, By External Identifier
    p_SUB_AGG_ACCT_SEARCH_STRING IN VARCHAR2, -- Null or Search String
    p_UOM               OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS
    v_SERVICE_CODE CHAR(1);
    v_SCENARIO_ID NUMBER(9);

    v_BEGIN DATE;
    v_END DATE;

    v_CUT_BEGIN_DATE DATE;
    v_CUT_END_DATE DATE;

    v_ACCT_SUB_AGG_ACCT_IDs NUMBER_COLLECTION;
    v_METER_SUB_AGG_ACCT_IDs NUMBER_COLLECTION;

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

    p_UOM := CASE WHEN GA.DEFAULT_MODEL = GA.ELECTRIC_MODEL THEN GA.ELECTRIC_UNIT_OF_MEASURMENT
                    WHEN GA.DEFAULT_MODEL = GA.GAS_MODEL THEN GA.GAS_UNIT_OF_MEASURMENT END;

   -- Get the list of matching Account modeled Sub-Aggregate accounts
    SELECT A.ACCOUNT_ID
    BULK COLLECT INTO v_ACCT_SUB_AGG_ACCT_IDs
    FROM TEMPORAL_ENTITY_ATTRIBUTE T,
        ACCOUNT A
    WHERE T.BEGIN_DATE <= p_END_DATE
        AND NVL(T.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
        AND T.ATTRIBUTE_ID = p_ATTRIBUTE_ID
        AND T.ENTITY_DOMAIN_ID = EC.ED_ACCOUNT
        AND T.ATTRIBUTE_VAL = p_ATTRIBUTE_VAL
        AND A.ACCOUNT_ID = T.OWNER_ENTITY_ID
        AND A.IS_SUB_AGGREGATE = 1
        AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_ACCOUNT
        AND (((p_SHOW_DETAILS = 1 AND p_SUB_AGG_ACCT_SEARCH_BY = c_SEARCH_BY_NAME AND UPPER(A.ACCOUNT_NAME) LIKE UPPER(GUI_UTIL.FIX_SEARCH_STRING(p_SUB_AGG_ACCT_SEARCH_STRING)))
            OR (p_SHOW_DETAILS = 1 AND p_SUB_AGG_ACCT_SEARCH_BY = c_SEARCH_BY_EXT_IDENT AND UPPER(A.ACCOUNT_EXTERNAL_IDENTIFIER) LIKE UPPER(GUI_UTIL.FIX_SEARCH_STRING(p_SUB_AGG_ACCT_SEARCH_STRING))))
            OR p_SHOW_DETAILS = 0);

    -- Get the list of matching Meter modeled Sub-Aggregate accounts
    SELECT A.ACCOUNT_ID
    BULK COLLECT INTO v_METER_SUB_AGG_ACCT_IDs
    FROM TEMPORAL_ENTITY_ATTRIBUTE T,
        ACCOUNT A
    WHERE T.BEGIN_DATE <= p_END_DATE
        AND NVL(T.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
        AND T.ATTRIBUTE_ID = p_ATTRIBUTE_ID
        AND T.ENTITY_DOMAIN_ID = EC.ED_ACCOUNT
        AND T.ATTRIBUTE_VAL = p_ATTRIBUTE_VAL
        AND A.ACCOUNT_ID = T.OWNER_ENTITY_ID
        AND A.IS_SUB_AGGREGATE = 1
        AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_METER
        AND (((p_SHOW_DETAILS = 1 AND p_SUB_AGG_ACCT_SEARCH_BY = c_SEARCH_BY_NAME AND UPPER(A.ACCOUNT_NAME) LIKE UPPER(GUI_UTIL.FIX_SEARCH_STRING(p_SUB_AGG_ACCT_SEARCH_STRING)))
            OR (p_SHOW_DETAILS = 1 AND p_SUB_AGG_ACCT_SEARCH_BY = c_SEARCH_BY_EXT_IDENT AND UPPER(A.ACCOUNT_EXTERNAL_IDENTIFIER) LIKE UPPER(GUI_UTIL.FIX_SEARCH_STRING(p_SUB_AGG_ACCT_SEARCH_STRING))))
            OR p_SHOW_DETAILS = 0);

    -- Call ENSURE_SERVICE_DETAILS for each Aggregate Id
    FOR v_REC IN (-- Account Aggregations
                  SELECT C.ACCOUNT_ID AS AGG_ACCOUNT_ID,
                         IDS.COLUMN_VALUE AS SUB_AGG_ACCOUNT_ID,
                         B.AGGREGATE_ID,
                         GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AS BEGIN_DATE,
                         LEAST(p_END_DATE, NVL(B.END_DATE, CONSTANTS.HIGH_DATE)) AS END_DATE
                  FROM AGGREGATE_ACCOUNT_ESP C,
                       ACCOUNT_SUB_AGG_AGGREGATION B,
                       TABLE(CAST(v_ACCT_SUB_AGG_ACCT_IDs AS NUMBER_COLLECTION)) IDS
                  WHERE C.AGGREGATE_ID = B.AGGREGATE_ID
                      AND B.BEGIN_DATE <= p_END_DATE
                      AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                      AND B.ACCOUNT_ID = IDS.COLUMN_VALUE
                  UNION
                  -- Meter Aggregations
                  SELECT C.ACCOUNT_ID AS AGG_ACCOUNT_ID,
                         IDS.COLUMN_VALUE AS SUB_AGG_ACCOUNT_ID,
                         B.AGGREGATE_ID,
                         GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AS BEGIN_DATE,
                         LEAST(p_END_DATE, B.END_DATE) AS END_DATE
                  FROM ACCOUNT_SERVICE_LOCATION ASL,
                       SERVICE_LOCATION_METER SM,
                       METER_SUB_AGG_AGGREGATION B,
                       AGGREGATE_ACCOUNT_ESP C,
                       TABLE(CAST(v_METER_SUB_AGG_ACCT_IDs AS NUMBER_COLLECTION)) IDS
                  WHERE C.AGGREGATE_ID = B.AGGREGATE_ID
                  AND B.METER_ID = SM.METER_ID
                  AND SM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
                  AND SM.BEGIN_DATE <= p_END_DATE
                  AND NVL(SM.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                  AND ASL.BEGIN_DATE <= p_END_DATE
                  AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                  AND B.BEGIN_DATE <= p_END_DATE
                  AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                  AND ASL.ACCOUNT_ID = IDS.COLUMN_VALUE) LOOP
        FS.ENSURE_SERVICE_DETAILS(v_SERVICE_CODE,
                                  GA.DEFAULT_MODEL,
                                  v_SCENARIO_ID,
                                  CONSTANTS.ALL_ID,
                                  CONSTANTS.ALL_ID,
                                  NUMBER_COLLECTION(v_REC.AGG_ACCOUNT_ID),
                                  v_REC.BEGIN_DATE,
                                  v_REC.END_DATE,
                                  CONSTANTS.LOW_DATE);
    END LOOP;

    OPEN p_CURSOR FOR
        WITH LOAD_DETAILS_BY_SUB_AGG_ACCTS AS
        (
        SELECT TRIM(CASE p_INTERVAL
                        WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS DT,
            SDT.CUT_DATE,
            X.ACCOUNT_ID,
            X.LOAD_VAL+X.TX_LOSS_VAL+X.DX_LOSS_VAL+X.UE_LOSS_VAL AS WITH_LOSSES
        FROM (-- Get Ajusted Load Data for the Aggregate Accounts
              SELECT SL.LOAD_DATE,
                    X.MODEL_ID,
                    X.ACCOUNT_ID,
                    CASE WHEN X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS = 0 THEN NULL ELSE SL.LOAD_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) END AS LOAD_VAL,
                    CASE WHEN X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS = 0 THEN NULL ELSE SL.TX_LOSS_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) END AS TX_LOSS_VAL,
                    CASE WHEN X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS = 0 THEN NULL ELSE SL.DX_LOSS_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) END AS DX_LOSS_VAL,
                    CASE WHEN X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS = 0 THEN NULL ELSE SL.UE_LOSS_VAL * (NVL(X.SUB_AGG_USAGE_FACTOR,X.AVERAGE_USAGE_FACTOR)/(X.AVERAGE_USAGE_FACTOR*X.SERVICE_ACCOUNTS)) END AS UE_LOSS_VAL
                FROM SERVICE_LOAD SL,
                     -- Get the Agg Account Service State information including Sub Aggregate UF
                     (SELECT X.*,
                             UF.FACTOR_VAL AS SUB_AGG_USAGE_FACTOR
                      FROM ACCOUNT_USAGE_FACTOR UF,
                          -- Get the Sub Aggregate Account, Aggregate Id, and Service State information by Service Date
                          (SELECT B.ACCOUNT_ID,
                                 NULL AS METER_ID,
                                 C.MODEL_ID,
                                 C.SERVICE_ID,
                                 D.SERVICE_DATE,
                                 D.USAGE_FACTOR AS AVERAGE_USAGE_FACTOR,
                                 D.SERVICE_ACCOUNTS
                           FROM SERVICE C,
                               SERVICE_STATE D,
                               ACCOUNT_SERVICE E,
                               ACCOUNT_SUB_AGG_AGGREGATION B,
                               TABLE(CAST(v_ACCT_SUB_AGG_ACCT_IDs  AS NUMBER_COLLECTION)) IDS
                           WHERE C.ACCOUNT_SERVICE_ID = E.ACCOUNT_SERVICE_ID
                             AND C.AS_OF_DATE = CONSTANTS.LOW_DATE
                             AND C.SCENARIO_ID = v_SCENARIO_ID
                             AND C.MODEL_ID = GA.DEFAULT_MODEL
                             AND C.SERVICE_ID = D.SERVICE_ID
                             AND D.SERVICE_CODE = v_SERVICE_CODE
                             AND D.SERVICE_DATE BETWEEN GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AND LEAST(p_END_DATE, NVL(B.END_DATE, CONSTANTS.HIGH_DATE))
                             AND B.ACCOUNT_ID = IDS.COLUMN_VALUE
                             AND B.BEGIN_DATE <= p_END_DATE
                             AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                             AND E.AGGREGATE_ID = B.AGGREGATE_ID) X
                      WHERE UF.ACCOUNT_ID (+) = X.ACCOUNT_ID
                        AND UF.CASE_ID (+) = GA.BASE_CASE_ID
                        AND X.SERVICE_DATE BETWEEN UF.BEGIN_DATE (+) AND NVL(UF.END_DATE (+), CONSTANTS.HIGH_DATE)
                    UNION
                    -- Meter Version
                    SELECT X.*,
                           UF.FACTOR_VAL AS SUB_AGG_USAGE_FACTOR
                    FROM METER_USAGE_FACTOR UF,
                          -- Get the Sub Aggregate Meter, Aggregate Id, and Service State information by Service Date
                          (SELECT ASL.ACCOUNT_ID,
                                 SM.METER_ID AS METER_ID,
                                 C.MODEL_ID,
                                 C.SERVICE_ID,
                                 D.SERVICE_DATE,
                                 D.USAGE_FACTOR AS AVERAGE_USAGE_FACTOR,
                                 D.SERVICE_ACCOUNTS
                          FROM SERVICE C,
                               SERVICE_STATE D,
                               ACCOUNT_SERVICE E,
                               SERVICE_LOCATION_METER SM,
                               METER_SUB_AGG_AGGREGATION B,
                               ACCOUNT_SERVICE_LOCATION ASL,
                               TABLE(CAST(v_METER_SUB_AGG_ACCT_IDs  AS NUMBER_COLLECTION)) IDS
                          WHERE C.ACCOUNT_SERVICE_ID = E.ACCOUNT_SERVICE_ID
                              AND C.AS_OF_DATE = CONSTANTS.LOW_DATE
                              AND C.SCENARIO_ID = v_SCENARIO_ID
                              AND C.MODEL_ID = GA.DEFAULT_MODEL
                              AND C.SERVICE_ID = D.SERVICE_ID
                              AND D.SERVICE_CODE = v_SERVICE_CODE
                              AND D.SERVICE_DATE BETWEEN GREATEST(p_BEGIN_DATE, B.BEGIN_DATE) AND LEAST(p_END_DATE, NVL(B.END_DATE, CONSTANTS.HIGH_DATE))
                              AND E.AGGREGATE_ID = B.AGGREGATE_ID
                              AND B.METER_ID = SM.METER_ID
                              AND SM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
                              AND SM.BEGIN_DATE <= p_END_DATE
                              AND NVL(SM.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
                              AND ASL.ACCOUNT_ID = IDS.COLUMN_VALUE
                              AND ASL.BEGIN_DATE <= p_END_DATE
                              AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE) X
                    WHERE UF.METER_ID (+) = X.METER_ID
                      AND UF.CASE_ID (+) = GA.BASE_CASE_ID
                      AND X.SERVICE_DATE BETWEEN UF.BEGIN_DATE (+) AND NVL(UF.END_DATE (+), CONSTANTS.HIGH_DATE)
                      ) X
                WHERE SL.SERVICE_ID = X.SERVICE_ID
                  AND SL.SERVICE_CODE = v_SERVICE_CODE
                  AND ((X.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SL.LOAD_DATE BETWEEN ADD_SECONDS_TO_DATE(TO_CUT(TRUNC(X.SERVICE_DATE), p_TIME_ZONE), 1) AND TO_CUT(TRUNC(X.SERVICE_DATE) + 1, p_TIME_ZONE))
                            OR (X.MODEL_ID = CONSTANTS.GAS_MODEL AND SL.LOAD_DATE = TRUNC(X.SERVICE_DATE)))) X,
                SYSTEM_DATE_TIME SDT
            WHERE SDT.TIME_ZONE = p_TIME_ZONE
                AND SDT.DAY_TYPE = GA.STANDARD
                AND GA.DEFAULT_MODEL IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
                AND X.MODEL_ID (+) = SDT.DATA_INTERVAL_TYPE
                AND X.LOAD_DATE (+) = SDT.CUT_DATE
                AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                      AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
        )
        -- Show Details
        SELECT L.DT,
            L.ACCOUNT_ID,
            CASE WHEN p_SUB_AGG_ACCT_SEARCH_BY = c_SEARCH_BY_NAME THEN A.ACCOUNT_NAME ELSE A.ACCOUNT_EXTERNAL_IDENTIFIER END AS ACCOUNT_IDENT,
            SUM(L.WITH_LOSSES) AS WITH_LOSSES
        FROM LOAD_DETAILS_BY_SUB_AGG_ACCTS L,
            ACCOUNT A
        WHERE p_SHOW_DETAILS = 1
            AND A.ACCOUNT_ID(+) = L.ACCOUNT_ID
        GROUP BY L.DT, L.ACCOUNT_ID, CASE WHEN p_SUB_AGG_ACCT_SEARCH_BY = c_SEARCH_BY_NAME THEN A.ACCOUNT_NAME ELSE A.ACCOUNT_EXTERNAL_IDENTIFIER END
        UNION ALL
        -- Do not Show Details
        SELECT L.DT,
            NULL AS ACCOUNT_ID,
            NULL AS ACCOUNT_IDENT,
            SUM(L.WITH_LOSSES) AS TOTAL
        FROM LOAD_DETAILS_BY_SUB_AGG_ACCTS L
        WHERE p_SHOW_DETAILS = 0
        GROUP BY L.DT
        ORDER BY DT, ACCOUNT_IDENT;

END GET_LOAD_DTLS_BY_ENTITY_ATTB;
--------------------------------------------------------
PROCEDURE GET_SYSTEM_LOAD
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_CASE_LABEL        IN VARCHAR2,
    p_INTERVAL          IN VARCHAR2,
    p_SYSTEM_LOAD_ID    IN NUMBER,
    p_AREA_LOAD         IN STRING_COLLECTION,
    p_FORECAST_FILTER   IN NUMBER,
    p_ACTUAL_FILTER     IN NUMBER,
    p_DIFFERENCE_FILTER IN NUMBER,
    p_MAPE_FILTER       IN NUMBER,
    p_TIME_ZONE         IN VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS
    v_NEED_NET NUMBER;
    v_BEGIN DATE;
    v_END DATE;
    v_CUT_BEGIN DATE;
    v_CUT_END DATE;
    v_CUT_DAY_BEGIN DATE;
    v_CUT_DAY_END DATE;
BEGIN

    --Get correct date for interval type
    ASSERT(p_INTERVAL IS NOT NULL, 'A null value was given for INTERVAL, this field must be non-null.',
        MSGCODES.c_ERR_ARGUMENT);
    IF p_INTERVAL NOT IN (CONSTANTS.INTERVAL_15_MINUTE, CONSTANTS.INTERVAL_30_MINUTE, CONSTANTS.INTERVAL_HOUR) THEN
        v_BEGIN := DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_BEGIN_DATE,p_INTERVAL);
        v_END := DATE_UTIL.END_DATE_FOR_INTERVAL(DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_END_DATE,p_INTERVAL),p_INTERVAL);
    ELSE
        v_BEGIN := p_BEGIN_DATE;
        v_END := p_END_DATE;
    END IF;

    SP.CHECK_SYSTEM_DATE_TIME(p_TIME_ZONE,v_BEGIN,v_END);
    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,v_BEGIN,v_END,p_TIME_ZONE, GET_INTERVAL_ABBREVIATION(p_INTERVAL),GET_INTERVAL_ABBREVIATION(p_INTERVAL), v_CUT_BEGIN,v_CUT_END);
    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,v_BEGIN,v_END,p_TIME_ZONE, v_CUT_DAY_BEGIN,v_CUT_DAY_END);

    --Get Cursor
         OPEN p_CURSOR FOR
         WITH
				--Locates all Load data for the selected areas
               LOAD AS(
                    SELECT AL.LOAD_VAL,
                           A.AREA_NAME,
                           AL.AREA_ID,
                           AL.LOAD_DATE,
                           AL.LOAD_CODE,
                           CASE WHEN SLA.OPERATION_CODE = 'S' THEN -1 ELSE 1 END AS AREA_TYPE,
                           A.AREA_INTERVAL
                    FROM AREA_LOAD AL,
                         SYSTEM_LOAD_AREA SLA,
                         CASE_LABEL C,
                         AREA A,
                         TABLE(CAST(p_AREA_LOAD AS STRING_COLLECTION)) ALI
                    WHERE
                        C.CASE_NAME = p_CASE_LABEL AND
                        DATE_UTIL.INTERVAL_ORD(A.AREA_INTERVAL)<= DATE_UTIL.INTERVAL_ORD(p_INTERVAL)AND
                        SLA.AREA_ID = A.AREA_ID AND
                        SLA.SYSTEM_LOAD_ID = p_SYSTEM_LOAD_ID AND
                        ALI.COLUMN_VALUE IN( A.AREA_NAME, CONSTANTS.ALL_STRING) AND
                        AL.CASE_ID = C.CASE_ID AND
                        AL.AREA_ID = A.AREA_ID AND
                        AL.AS_OF_DATE = LOW_DATE AND
                        AL.LOAD_CODE IN ('A', 'F') AND
                        AL.LOAD_DATE >= least(v_BEGIN, v_CUT_DAY_BEGIN, v_CUT_BEGIN) AND
                        AL.LOAD_DATE <= greatest(v_END, v_CUT_DAY_END, v_CUT_END)

               ),
				X AS (
               SELECT TRIM(CASE p_INTERVAL
                        WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_DAY THEN TO_CHAR(SDT.CUT_DATE, 'YYYY-MM-DD')
                        WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS LOAD_DATE,
					 AL1.LOAD_VAL AS ACTUAL,
                     AL2.LOAD_VAL AS FORECAST,
                     NVL(AL1.AREA_TYPE,AL2.AREA_TYPE) AS AREA_TYPE,
                     NVL(AL1.AREA_NAME,AL2.AREA_NAME) AS AREA_NAME,
                     SDT.CUT_DATE
               FROM SYSTEM_DATE_TIME SDT,
                    (SELECT * FROM LOAD WHERE LOAD_CODE = CONSTANTS.CODE_ACTUAL) AL1
                     FULL OUTER JOIN
                     (SELECT * FROM LOAD WHERE LOAD_CODE = CONSTANTS.CODE_FORECAST) AL2
                     ON AL1.AREA_ID = AL2.AREA_ID AND
                        AL1.LOAD_DATE = AL2.LOAD_DATE
                WHERE NVL(AL1.AREA_INTERVAL,AL2.AREA_INTERVAL) = CONSTANTS.INTERVAL_DAY AND
                     NVL(AL1.AREA_NAME,AL2.AREA_NAME) IS NOT NULL
                     AND SDT.CUT_DATE_SCHEDULING = NVL(AL1.LOAD_DATE,AL2.LOAD_DATE)
                     AND SDT.TIME_ZONE = p_TIME_ZONE
				     AND SDT.DAY_TYPE = GA.STANDARD
					 AND CONSTANTS.GAS_MODEL = SDT.DATA_INTERVAL_TYPE
					 AND SDT.CUT_DATE >= v_BEGIN
                     AND SDT.CUT_DATE <= v_END

                 UNION
                  SELECT TRIM(CASE p_INTERVAL
                        WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END) AS LOAD_DATE,
					 AL1.LOAD_VAL AS ACTUAL,
                     AL2.LOAD_VAL AS FORECAST,
                     NVL(AL1.AREA_TYPE,AL2.AREA_TYPE) AS AREA_TYPE,
                     NVL(AL1.AREA_NAME,AL2.AREA_NAME) AS AREA_NAME,
                     SDT.CUT_DATE
               FROM SYSTEM_DATE_TIME SDT,
                    (SELECT * FROM LOAD WHERE LOAD_CODE = CONSTANTS.CODE_ACTUAL) AL1
                     FULL OUTER JOIN
                     (SELECT * FROM LOAD WHERE LOAD_CODE = CONSTANTS.CODE_FORECAST) AL2
                     ON AL1.AREA_ID = AL2.AREA_ID AND
                        AL1.LOAD_DATE = AL2.LOAD_DATE
               WHERE NVL(AL1.AREA_INTERVAL,AL2.AREA_INTERVAL) != CONSTANTS.INTERVAL_DAY AND
                     NVL(AL1.AREA_NAME,AL2.AREA_NAME) IS NOT NULL
                     AND SDT.CUT_DATE_SCHEDULING = NVL(AL1.LOAD_DATE,AL2.LOAD_DATE)
                     AND SDT.TIME_ZONE = p_TIME_ZONE
				     AND SDT.DAY_TYPE = GA.STANDARD
					 AND CONSTANTS.ELECTRIC_MODEL = SDT.DATA_INTERVAL_TYPE
					 AND ((SDT.CUT_DATE >= least(v_CUT_DAY_BEGIN, v_CUT_BEGIN)
					 AND SDT.CUT_DATE <= greatest(v_CUT_DAY_END, v_CUT_END)
					 AND GET_INTERVAL_NUMBER(p_INTERVAL) != 35 )
								OR (SDT.CUT_DATE >= v_CUT_DAY_BEGIN AND SDT.CUT_DATE <= v_CUT_DAY_END AND GET_INTERVAL_NUMBER(p_INTERVAL) = 35) )
                     ),
				BASE AS (
					SELECT  X.LOAD_DATE AS LOAD_DATE,
							SUM(X.FORECAST) AS FORECAST,
							SUM(X.ACTUAL) AS ACTUAL,
							CASE WHEN SUM(X.ACTUAL) IS NULL AND  SUM(X.FORECAST) IS NULL
								THEN NULL ELSE  NVL(SUM(X.ACTUAL),0)- NVL(SUM(X.FORECAST),0) END AS DIFFERENCE,
							CASE WHEN NVL(SUM(X.ACTUAL),0)!= 0
								THEN 100*(SUM(X.ACTUAL)- SUM(X.FORECAST) )/ SUM(X.ACTUAL)  ELSE NULL END AS MAPE,
							MAX(X.AREA_TYPE) AS AREA_TYPE,
							X.AREA_NAME AS AREA_NAME
					FROM X
					GROUP BY X.AREA_NAME, X.LOAD_DATE),
				--Distinct Area Names
				DA AS (
					SELECT distinct AREA_NAME
					FROM BASE
					WHERE AREA_NAME IS NOT NULL),
				--List of Dates that fall into date range
				DATES AS (
					SELECT (TRIM(CASE p_INTERVAL
                        WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                        WHEN CONSTANTS.INTERVAL_DAY THEN  TO_CHAR(SDT.CUT_DATE, 'YYYY-MM-DD')
                        WHEN CONSTANTS.INTERVAL_WEEK THEN TO_CHAR(SDT.CUT_DATE, 'YYYY-MM-DD')
                        WHEN CONSTANTS.INTERVAL_MONTH THEN TO_CHAR(SDT.CUT_DATE, 'YYYY-MM-DD')
                        WHEN CONSTANTS.INTERVAL_QUARTER THEN TO_CHAR(SDT.CUT_DATE, 'YYYY-MM-DD')
                        WHEN CONSTANTS.INTERVAL_YEAR THEN TO_CHAR(SDT.CUT_DATE, 'YYYY-MM-DD') ELSE NULL END) )AS LOAD_DATE,
                     SDT.CUT_DATE AS CUT_DATE,
							DA.AREA_NAME AS AREA_NAME
               FROM SYSTEM_DATE_TIME SDT, DA
               WHERE AREA_NAME IS NOT NULL AND
                     SDT.TIME_ZONE = p_TIME_ZONE AND
                     SDT.DAY_TYPE = GA.STANDARD AND
                     CONSTANTS.ELECTRIC_MODEL = SDT.DATA_INTERVAL_TYPE AND
                     SDT.CUT_DATE BETWEEN v_CUT_BEGIN AND  v_CUT_END AND
							MINIMUM_INTERVAL_NUMBER >= GET_INTERVAL_NUMBER(p_INTERVAL)),

				--Row Count
				C AS(
					SELECT COUNT(DISTINCT DATES.LOAD_DATE) AS A
					FROM DATES),
				--Area Count
				A AS(
					SELECT COUNT (DA.AREA_NAME) AS A
					FROM DA),
				--MAPE Average
				MA AS(
					SELECT BASE.AREA_NAME AS AREA,
							SUM(ABS(BASE.MAPE))/MAX(C.A) AS MAPE
					FROM BASE, C
					GROUP BY BASE.AREA_NAME ),
				--Base Net
				NET AS (
					SELECT BASE.LOAD_DATE AS LOAD_DATE,
                     ' ' ||SL.SYSTEM_LOAD_NAME || ' (Net)' AS AREA_NAME,
                     SUM(BASE.FORECAST * BASE.AREA_TYPE) AS FORECAST,
                     SUM(BASE.ACTUAL*BASE.AREA_TYPE) AS ACTUAL,
                     CASE WHEN SUM(BASE.FORECAST * BASE.AREA_TYPE) IS NULL AND SUM(BASE.ACTUAL*BASE.AREA_TYPE) IS NULL
                        THEN NULL ELSE  NVL(SUM(BASE.ACTUAL*BASE.AREA_TYPE),0) - NVL(SUM(BASE.FORECAST * BASE.AREA_TYPE),0) END AS DIFFERENCE,
                     CASE WHEN NVL(SUM(BASE.ACTUAL*BASE.AREA_TYPE),0) != 0
                        THEN 100*(SUM(BASE.ACTUAL*BASE.AREA_TYPE) - SUM(BASE.FORECAST * BASE.AREA_TYPE))/SUM(BASE.ACTUAL*BASE.AREA_TYPE) ELSE NULL END AS MAPE
               FROM BASE, SYSTEM_LOAD SL
               WHERE SL.SYSTEM_LOAD_ID = p_SYSTEM_LOAD_ID
               GROUP BY BASE.LOAD_DATE, SL.SYSTEM_LOAD_NAME),
				--Net MAPE Average
				NMA AS(
					SELECT SUM(ABS(NET.MAPE))/MAX(C.A) AS MAPE
					FROM NET, C )

			--Main Query
			--Individual areas
         SELECT DATES.LOAD_DATE AS LOAD_DATE,
               DATES.CUT_DATE AS CUT_DATE,
               DATES.AREA_NAME AS AREA_NAME,
               CASE WHEN p_FORECAST_FILTER = 1 THEN BASE.FORECAST ELSE NULL END AS FORECAST,
               CASE WHEN p_ACTUAL_FILTER = 1 THEN BASE.ACTUAL ELSE NULL END AS ACTUAL,
               CASE WHEN p_DIFFERENCE_FILTER = 1 THEN BASE.DIFFERENCE ELSE NULL END AS DIFFERENCE,
               CASE WHEN p_MAPE_FILTER = 1 THEN BASE.MAPE ELSE NULL END AS MAPE ,
               'MAPE: ' || ROUND(MA.MAPE, 2) AS AVG_MAPE,
               p_FORECAST_FILTER + 2*p_ACTUAL_FILTER AS VISIBLE
         FROM BASE, DATES, MA
         WHERE DATES.AREA_NAME  = MA.AREA AND
                DATES.AREA_NAME = BASE.AREA_NAME(+) AND
                DATES.LOAD_DATE = BASE.LOAD_DATE(+)
         UNION
         --Net of all selected areas
         SELECT NET.LOAD_DATE AS LOAD_DATE,
                NULL AS CUT_DATE,
                NET.AREA_NAME AS AREA_NAME,
                CASE WHEN p_FORECAST_FILTER = 1 THEN NET.FORECAST ELSE NULL END AS FORECAST,
                CASE WHEN p_ACTUAL_FILTER = 1THEN NET.ACTUAL ELSE NULL END AS ACTUAL,
                CASE WHEN p_DIFFERENCE_FILTER = 1 THEN NET.DIFFERENCE ELSE NULL END AS DIFFERENCE,
                CASE WHEN p_MAPE_FILTER = 1 THEN NET.MAPE ELSE NULL END AS MAPE,
                'MAPE: ' || ROUND(NMA.MAPE, 2) AS AVG_MAPE,
               p_FORECAST_FILTER + 2*p_ACTUAL_FILTER AS VISIBLE
         FROM NET, NMA, A
         WHERE A.A >1 -- Make sure more than one area was selected
         ORDER BY AREA_NAME, LOAD_DATE;



END GET_SYSTEM_LOAD;
--------------------------------------------------------
PROCEDURE PUT_SYSTEM_LOAD
    (
    p_CUT_DATE        IN date,
    p_AREA_NAME       IN VARCHAR2,
    p_CASE_LABEL      IN VARCHAR2,
    p_INTERVAL        IN VARCHAR2,
    p_FORECAST        IN NUMBER,
    p_ACTUAL          IN NUMBER,
    p_TIME_ZONE       IN VARCHAR2,
    p_VISIBLE         IN NUMBER
    ) AS
    v_AREA_ID        AREA.AREA_ID%TYPE;
    v_AREA_INTERVAL  AREA.AREA_INTERVAL%TYPE;
    v_CASE_ID        CASE_LABEL.CASE_ID%TYPE;
    v_DATE           DATE;
BEGIN
    --Make sure that the data is not from the Net columns
    IF p_AREA_NAME NOT LIKE ' %(Net)' THEN

        SELECT AREA_ID, AREA_INTERVAL
        INTO V_AREA_ID, v_AREA_INTERVAL
        FROM AREA
        WHERE AREA_NAME = p_AREA_NAME;


        ASSERT(v_AREA_INTERVAL = p_INTERVAL,
             'To save changes, the interval filter must match the interval of the changed area.',
             MSGCODES.c_ERR_ROW_NOT_EDITABLE);

        SELECT CASE_ID
        INTO v_CASE_ID
        FROM CASE_LABEL
        WHERE CASE_NAME = p_CASE_LABEL;


        IF p_INTERVAL = CONSTANTS.INTERVAL_DAY THEN
            SELECT CUT_DATE_SCHEDULING
            INTO v_DATE
            FROM SYSTEM_DATE_TIME
            WHERE CUT_DATE = p_CUT_DATE
                  AND DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL;
       ELSE
            v_DATE := p_CUT_DATE;
        END IF;

        --Update/Insert Forecast Data
        --p_VISIBLE = 1 means that FORECAST is visible in the UI
        --p_VISIBLE = 3 means both FORECAST and ACTUAL are visible in the UI
        IF p_VISIBLE = 1 OR p_VISIBLE = 3  THEN

            MERGE INTO AREA_LOAD AL
            USING (SELECT p_FORECAST AS FORECAST, SYSDATE AS AS_OF_DATE FROM DUAL) SRC
            ON (AREA_ID = v_AREA_ID
                  AND CASE_ID = v_CASE_ID
                  AND LOAD_DATE = v_DATE
                  AND LOAD_CODE = CONSTANTS.CODE_FORECAST)
            WHEN MATCHED
                THEN UPDATE
                        SET LOAD_VAL= SRC.FORECAST,
                            AS_OF_DATE = SRC.AS_OF_DATE
            WHEN NOT MATCHED
                THEN INSERT (CASE_ID, AREA_ID, LOAD_CODE, LOAD_DATE, AS_OF_DATE, LOAD_VAL)
                        VALUES(v_CASE_ID, v_AREA_ID, CONSTANTS.CODE_FORECAST, v_DATE, SRC.AS_OF_DATE, SRC.FORECAST);
         ELSE NULL; END IF;

         --Update/Insert Actual Data
         --p_VISIBLE = 2 means that ACTUAL is visible in the UI
         --p_VISIBLE = 3 means both FORECAST and ACTUAL are visible in the UI
         IF p_VISIBLE IN ( 2,3) THEN

            MERGE INTO AREA_LOAD AL
            USING (SELECT p_ACTUAL AS ACTUAL, SYSDATE AS AS_OF_DATE FROM DUAL) SRC
            ON (AREA_ID = v_AREA_ID
                  AND CASE_ID = v_CASE_ID
                  AND LOAD_DATE = v_DATE
                  AND LOAD_CODE = CONSTANTS.CODE_ACTUAL)
            WHEN MATCHED
                THEN UPDATE
                        SET LOAD_VAL= SRC.ACTUAL,
                            AS_OF_DATE = SRC.AS_OF_DATE
            WHEN NOT MATCHED
                THEN INSERT (CASE_ID, AREA_ID, LOAD_CODE, LOAD_DATE, AS_OF_DATE, LOAD_VAL)
                        VALUES(v_CASE_ID, v_AREA_ID, CONSTANTS.CODE_ACTUAL, v_DATE, SRC.AS_OF_DATE, SRC.ACTUAL);

         ELSE NULL; END IF;

     ELSE NULL; END IF;

END PUT_SYSTEM_LOAD;
--------------------------------------------------------
PROCEDURE GET_COMPARISON_SUMMARY
    (
    p_BEGIN_DATE          IN DATE,
    p_END_DATE            IN DATE,
    p_RUN_TYPE_A_ID       IN NUMBER,
    p_RUN_TYPE_B_ID       IN NUMBER,
    p_TIME_ZONE           IN VARCHAR2,
    p_INTERVAL            IN VARCHAR2,
    p_MODEL_ID            IN NUMBER,
    p_FILTER_SC_ID        IN NUMBER,
    p_SHOW_FILTER_SC_ID   IN NUMBER,
    p_FILTER_EDC_ID       IN NUMBER,
    p_SHOW_FILTER_EDC_ID  IN NUMBER,
    p_FILTER_ESP_ID       IN NUMBER,
    p_SHOW_FILTER_ESP_ID  IN NUMBER,
    p_FILTER_PSE_ID       IN NUMBER,
    p_SHOW_FILTER_PSE_ID  IN NUMBER,
    p_FILTER_POOL_ID      IN NUMBER,
    p_SHOW_FILTER_POOL_ID IN NUMBER,
    p_DISPLAY_TYPE        IN VARCHAR2,
    p_CURSOR              OUT GA.REFCURSOR
    ) AS

    v_EDC_ID NUMBER(9) := NVL(p_FILTER_EDC_ID, CONSTANTS.ALL_ID);
    v_SHOW_EDC_ID NUMBER(1) := NVL(p_SHOW_FILTER_EDC_ID, 0);

    v_SC_ID NUMBER(9) := NVL(p_FILTER_SC_ID, CONSTANTS.ALL_ID);
    v_SHOW_SC_ID NUMBER(1) := NVL(p_SHOW_FILTER_SC_ID, 0);

    v_ESP_ID NUMBER(9) := NVL(p_FILTER_ESP_ID, CONSTANTS.ALL_ID);
    v_SHOW_ESP_ID NUMBER(1) := NVL(p_SHOW_FILTER_ESP_ID, 0);

    v_PSE_ID NUMBER(9) := NVL(p_FILTER_PSE_ID, CONSTANTS.ALL_ID);
    v_SHOW_PSE_ID NUMBER(1) := NVL(p_SHOW_FILTER_PSE_ID, 0);

    v_POOL_ID NUMBER(9) := NVL(p_FILTER_POOL_ID, CONSTANTS.ALL_ID);
    v_SHOW_POOL_ID NUMBER(1) := NVL(p_SHOW_FILTER_POOL_ID, 0);

    v_MODEL_ID NUMBER(9) := NVL(p_MODEL_ID,GA.DEFAULT_MODEL);
    v_SHOW_MODEL_ID NUMBER(1) := CASE WHEN p_MODEL_ID IS NULL THEN 0 ELSE 1 END;

    v_SERVICE_CODE_A CHAR(1);
    v_SCENARIO_ID_A NUMBER(9);

    v_SERVICE_CODE_B CHAR(1);
    v_SCENARIO_ID_B NUMBER(9);

    v_BEGIN DATE;
    v_END DATE;

    v_CUT_BEGIN_DATE DATE;
    v_CUT_END_DATE DATE;

    v_SHOW_W NUMBER(1) := 0;
    v_SHOW_WO NUMBER(1) := 0;

BEGIN

    ASSERT(p_INTERVAL IS NOT NULL, 'A null value was given for INTERVAL, this field must be non-null.',
        MSGCODES.c_ERR_ARGUMENT);

    ASSERT(NVL(p_DISPLAY_TYPE, c_SERVICE_WITH_LOSSES) IN (c_SERVICE_WITH_LOSSES, c_SERVICE_WO_LOSSES), 'An invalid option for Display Type was given.'
        || '  Display Type must be '''|| c_SERVICE_WITH_LOSSES || ''' OR ''' || c_SERVICE_WO_LOSSES ||
        '''.  Actual value = ' || p_DISPLAY_TYPE, MSGCODES.c_ERR_ARGUMENT);

    CASE WHEN NVL(p_DISPLAY_TYPE,c_SERVICE_WITH_LOSSES) = c_SERVICE_WITH_LOSSES THEN
            v_SHOW_W := 1;
        WHEN NVL(p_DISPLAY_TYPE,c_SERVICE_WITH_LOSSES) = c_SERVICE_WO_LOSSES THEN
            v_SHOW_WO := 1;
    END CASE;

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

    OPEN p_CURSOR FOR
    WITH BASE AS
    (SELECT Q.DT,
	       Q.SERVICE_ID,
           Q.SERVICE,
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
           SUM(Q.VAL_A) AS VAL_A,
           SUM(Q.VAL_B) AS VAL_B,
           CASE WHEN SUM(Q.VAL_A) IS NOT NULL AND SUM(Q.VAL_B) IS NOT NULL THEN NVL(SUM (Q.VAL_A), 0)-NVL(SUM(Q.VAL_B),0) ELSE NULL END AS DIFFERENCE,
           CASE SUM(Q.VAL_A)WHEN 0 THEN NULL ELSE 100*(SUM(Q.VAL_A)-SUM(Q.VAL_B))/SUM(Q.VAL_A) END AS DIFF_PERCENT
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
			CASE WHEN v_SHOW_MODEL_ID = 0 THEN NULL ELSE V.MODEL_ID END AS SERVICE_ID,
            CASE WHEN v_SHOW_MODEL_ID = 0 THEN NULL ELSE (CASE WHEN V.MODEL_ID = CONSTANTS.ELECTRIC_MODEL THEN 'Electric' WHEN V.MODEL_ID = CONSTANTS.GAS_MODEL THEN 'Gas' ELSE NULL END) END AS SERVICE,
            CASE WHEN v_SHOW_SC_ID = 0 THEN NULL ELSE V.SC_ID END AS SC_ID,
            CASE WHEN v_SHOW_SC_ID = 0 THEN NULL ELSE V.SC_NAME END AS SC_NAME,
            CASE WHEN v_SHOW_EDC_ID = 0 THEN NULL ELSE V.EDC_ID END AS EDC_ID,
            CASE WHEN v_SHOW_EDC_ID = 0 THEN NULL ELSE V.EDC_NAME END AS EDC_NAME,
            CASE WHEN v_SHOW_PSE_ID = 0 THEN NULL ELSE V.PSE_ID END AS PSE_ID,
            CASE WHEN v_SHOW_PSE_ID = 0 THEN NULL ELSE V.PSE_NAME END AS PSE_NAME,
            CASE WHEN v_SHOW_ESP_ID = 0 THEN NULL ELSE V.ESP_ID END AS ESP_ID,
            CASE WHEN v_SHOW_ESP_ID = 0 THEN NULL ELSE V.ESP_NAME END AS ESP_NAME,
            CASE WHEN v_SHOW_POOL_ID = 0 THEN NULL ELSE V.POOL_ID END AS POOL_ID,
            CASE WHEN v_SHOW_POOL_ID = 0 THEN NULL ELSE V.POOL_NAME END AS POOL_NAME,
            CASE WHEN v_SHOW_W = 1 THEN V.LOAD_VAL_A+V.TX_LOSS_VAL_A+V.DX_LOSS_VAL_A+V.UFE_LOAD_VAL_A WHEN v_SHOW_WO = 1 THEN V.LOAD_VAL_A ELSE NULL END AS VAL_A,
            CASE WHEN v_SHOW_W = 1 THEN V.LOAD_VAL_B+V.TX_LOSS_VAL_B+V.DX_LOSS_VAL_B+V.UFE_LOAD_VAL_B WHEN v_SHOW_WO = 1 THEN V.LOAD_VAL_B ELSE NULL END AS VAL_B

        FROM (SELECT NVL(X.MODEL_ID, Y.MODEL_ID) AS MODEL_ID,
                    NVL(X.LOAD_DATE, Y.LOAD_DATE) AS LOAD_DATE,
                    X.LOAD_VAL AS LOAD_VAL_A,
                    X.TX_LOSS_VAL AS TX_LOSS_VAL_A,
                    X.DX_LOSS_VAL AS DX_LOSS_VAL_A,
                    X.UFE_LOAD_VAL AS UFE_LOAD_VAL_A,
                    Y.LOAD_VAL AS LOAD_VAL_B,
                    Y.TX_LOSS_VAL AS TX_LOSS_VAL_B,
                    Y.DX_LOSS_VAL AS DX_LOSS_VAL_B,
                    Y.UFE_LOAD_VAL AS UFE_LOAD_VAL_B,
                    NVL(X.PSE_ID, Y.PSE_ID) AS PSE_ID,
                    NVL(X.PSE_NAME, Y.PSE_NAME) AS PSE_NAME,
                    NVL(X.ESP_ID, Y.ESP_ID) AS ESP_ID,
                    NVL(X.ESP_NAME, Y.ESP_NAME) AS ESP_NAME,
                    NVL(X.EDC_ID, Y.EDC_ID) AS EDC_ID,
                    NVL(X.EDC_NAME, Y.EDC_NAME) AS EDC_NAME,
                    NVL(X.POOL_ID, Y.POOL_ID) AS POOL_ID,
                    NVL(X.POOL_NAME, Y.POOL_NAME) AS POOL_NAME,
                    NVL(X.SC_ID, Y.SC_ID) AS SC_ID,
                    NVL(X.SC_NAME, Y.SC_NAME) AS SC_NAME
                FROM (SELECT SO.MODEL_ID,
                    SOL.LOAD_DATE,
                    SOL.LOAD_VAL,
                    SOL.TX_LOSS_VAL,
                    SOL.DX_LOSS_VAL,
                    SOL.UFE_LOAD_VAL,
                    PSE.PSE_ID,
                    PSE.PSE_NAME,
                    SC.SC_ID,
                    SC.SC_NAME,
                    P.POOL_ID,
                    P.POOL_NAME,
                    ESP.ESP_ID,
                    ESP.ESP_NAME,
                    EDC.EDC_ID,
                    EDC.EDC_NAME
             FROM SERVICE_OBLIGATION SO,
                SERVICE_OBLIGATION_LOAD SOL,
                PROVIDER_SERVICE PS,
                SERVICE_DELIVERY SD,
                PURCHASING_SELLING_ENTITY PSE,
                POOL P,
                SCHEDULE_COORDINATOR SC,
                ENERGY_DISTRIBUTION_COMPANY EDC,
                ENERGY_SERVICE_PROVIDER ESP
             WHERE v_EDC_ID IN (CONSTANTS.ALL_ID, EDC.EDC_ID)
                AND v_ESP_ID IN (CONSTANTS.ALL_ID, ESP.ESP_ID)
                AND v_PSE_ID IN (CONSTANTS.ALL_ID,PS.PSE_ID)
                AND v_POOL_ID IN (CONSTANTS.ALL_ID,SD.POOL_ID)
                AND v_SC_ID IN (CONSTANTS.ALL_ID,SD.SC_ID)
                AND v_MODEL_ID IN (CONSTANTS.ALL_ID,SO.MODEL_ID)
                AND SOL.SERVICE_CODE = v_SERVICE_CODE_A
                AND SO.SCENARIO_ID = v_SCENARIO_ID_A
                AND P.POOL_ID = SD.POOL_ID
                AND PSE.PSE_ID = PS.PSE_ID
                AND EDC.EDC_ID = PS.EDC_ID
                AND ESP.ESP_ID = PS.ESP_ID
                AND SC.SC_ID = SD.SC_ID
                AND SOL.LOAD_CODE = GA.STANDARD
                AND SO.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
                AND SO.SERVICE_DELIVERY_ID = SD.SERVICE_DELIVERY_ID
                AND SOL.SERVICE_OBLIGATION_ID = SO.SERVICE_OBLIGATION_ID
                AND ((SO.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SOL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE)
                    OR (SO.MODEL_ID = CONSTANTS.GAS_MODEL AND SOL.LOAD_DATE BETWEEN v_BEGIN AND v_END))) X
                FULL OUTER JOIN
           (SELECT SO.MODEL_ID,
                    SOL.LOAD_DATE,
                    SOL.LOAD_VAL,
                    SOL.TX_LOSS_VAL,
                    SOL.DX_LOSS_VAL,
                    SOL.UFE_LOAD_VAL,
                    PSE.PSE_ID,
                    PSE.PSE_NAME,
                    SC.SC_ID,
                    SC.SC_NAME,
                    P.POOL_ID,
                    P.POOL_NAME,
                    ESP.ESP_ID,
                    ESP.ESP_NAME,
                    EDC.EDC_ID,
                    EDC.EDC_NAME
             FROM SERVICE_OBLIGATION SO,
                SERVICE_OBLIGATION_LOAD SOL,
                PROVIDER_SERVICE PS,
                SERVICE_DELIVERY SD,
                PURCHASING_SELLING_ENTITY PSE,
                POOL P,
                SCHEDULE_COORDINATOR SC,
                ENERGY_DISTRIBUTION_COMPANY EDC,
                ENERGY_SERVICE_PROVIDER ESP
             WHERE v_EDC_ID IN (CONSTANTS.ALL_ID, EDC.EDC_ID)
                AND v_ESP_ID IN (CONSTANTS.ALL_ID, ESP.ESP_ID)
                AND v_PSE_ID IN (CONSTANTS.ALL_ID,PS.PSE_ID)
                AND v_POOL_ID IN (CONSTANTS.ALL_ID,SD.POOL_ID)
                AND v_SC_ID IN (CONSTANTS.ALL_ID,SD.SC_ID)
                AND v_MODEL_ID IN (CONSTANTS.ALL_ID,SO.MODEL_ID)
                AND SOL.SERVICE_CODE = v_SERVICE_CODE_B
                AND SO.SCENARIO_ID = v_SCENARIO_ID_B
                AND P.POOL_ID = SD.POOL_ID
                AND PSE.PSE_ID = PS.PSE_ID
                AND EDC.EDC_ID = PS.EDC_ID
                AND ESP.ESP_ID = PS.ESP_ID
                AND SC.SC_ID = SD.SC_ID
                AND SOL.LOAD_CODE = GA.STANDARD
                AND SO.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
                AND SO.SERVICE_DELIVERY_ID = SD.SERVICE_DELIVERY_ID
                AND SOL.SERVICE_OBLIGATION_ID = SO.SERVICE_OBLIGATION_ID
                AND ((SO.MODEL_ID = CONSTANTS.ELECTRIC_MODEL AND SOL.LOAD_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE)
                    OR (SO.MODEL_ID = CONSTANTS.GAS_MODEL AND SOL.LOAD_DATE BETWEEN v_BEGIN AND v_END))) Y
                    ON X.MODEL_ID = Y.MODEL_ID AND
                       X.LOAD_DATE = Y.LOAD_DATE AND
                       X.PSE_ID = Y.PSE_ID AND
                       X.PSE_NAME = Y.PSE_NAME AND
                       X.SC_ID = Y.SC_ID AND
                       X.SC_NAME = Y.SC_NAME AND
                       X.POOL_ID = Y.POOL_ID AND
                       X.POOL_NAME = Y.POOL_NAME AND
                       X.ESP_ID = Y.ESP_ID AND
                       X.ESP_NAME = Y.ESP_NAME AND
                       X.EDC_ID = Y.EDC_ID AND
                       X.EDC_NAME = Y.EDC_NAME) V,
            SYSTEM_DATE_TIME SDT
        WHERE SDT.TIME_ZONE = p_TIME_ZONE
            AND SDT.DAY_TYPE = GA.STANDARD
            AND v_MODEL_ID IN (SDT.DATA_INTERVAL_TYPE,CONSTANTS.ALL_ID)
            AND V.MODEL_ID (+) = SDT.DATA_INTERVAL_TYPE
            AND V.LOAD_DATE (+) = SDT.CUT_DATE
            AND SDT.CUT_DATE BETWEEN CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
                                  AND CASE WHEN SDT.DATA_INTERVAL_TYPE = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END) Q
     GROUP BY Q.DT, Q.SERVICE_ID, Q.SERVICE, Q.SC_ID, Q.SC_NAME, Q.EDC_ID, Q.EDC_NAME, Q.PSE_ID, Q.PSE_NAME, Q.ESP_ID, Q.ESP_NAME, Q.POOL_ID, Q.POOL_NAME)
     ,
     DATES AS
     (SELECT COUNT(DISTINCT DT) AS ROW_COUNT FROM BASE),
     MAPE_CALC AS
     (SELECT BASE.SERVICE_ID,
	         BASE.SERVICE,
		     BASE.SC_ID,
		     BASE.SC_NAME,
		     BASE.EDC_ID,
		     BASE.EDC_NAME,
		     BASE.PSE_ID,
		     BASE.PSE_NAME,
		     BASE.ESP_ID,
		     BASE.ESP_NAME,
		     BASE.POOL_ID,
		     BASE.POOL_NAME,
		     SUM(ABS(BASE.DIFF_PERCENT))/MAX(DATES.ROW_COUNT) AS MAPE
      FROM BASE, DATES
      GROUP BY BASE.SERVICE_ID, BASE.SERVICE, BASE.SC_ID, BASE.SC_NAME, BASE.EDC_ID, BASE.EDC_NAME,
      BASE.PSE_ID, BASE.PSE_NAME, BASE.ESP_ID, BASE.ESP_NAME, BASE.POOL_ID, BASE.POOL_NAME)
     SELECT BASE.DT,
           BASE.SERVICE_ID,
		   BASE.SERVICE,
           BASE.SC_ID,
           BASE.SC_NAME,
           BASE.EDC_ID,
           BASE.EDC_NAME,
           BASE.PSE_ID,
           BASE.PSE_NAME,
           BASE.ESP_ID,
           BASE.ESP_NAME,
           BASE.POOL_ID,
           BASE.POOL_NAME,
           'MAPE: ' || ROUND(MAPE_CALC.MAPE, 4) AS MAPE,
           BASE.VAL_A,
           BASE.VAL_B,
           BASE.DIFFERENCE,
           BASE.DIFF_PERCENT
     FROM BASE, MAPE_CALC
     WHERE NVL(BASE.SERVICE_ID, -1) = NVL(MAPE_CALC.SERVICE_ID, -1) AND
	       NVL(BASE.SERVICE,'NULL') = NVL(MAPE_CALC.SERVICE, 'NULL') AND
           NVL(BASE.SC_ID, -1) = NVL(MAPE_CALC.SC_ID,-1) AND
           NVL(BASE.SC_NAME, 'NULL') = NVL(MAPE_CALC.SC_NAME, 'NULL') AND
           NVL(BASE.EDC_ID, -1) = NVL(MAPE_CALC.EDC_ID, -1) AND
           NVL(BASE.EDC_NAME,'NULL') = NVL(MAPE_CALC.EDC_NAME,'NULL') AND
           NVL(BASE.PSE_ID, -1) = NVL(MAPE_CALC.PSE_ID, -1) AND
           NVL(BASE.PSE_NAME,'NULL') = NVL(MAPE_CALC.PSE_NAME,'NULL') AND
           NVL(BASE.ESP_ID, -1) = NVL(MAPE_CALC.ESP_ID, -1) AND
           NVL(BASE.ESP_NAME,'NULL') = NVL(MAPE_CALC.ESP_NAME,'NULL') AND
           NVL(BASE.POOL_ID, -1) = NVL(MAPE_CALC.POOL_ID, -1) AND
           NVL(BASE.POOL_NAME,'NULL') = NVL(MAPE_CALC.POOL_NAME,'NULL')
     ORDER BY BASE.DT, BASE.SERVICE_ID, BASE.SERVICE, BASE.SC_NAME, BASE.EDC_NAME, BASE.PSE_NAME, BASE.ESP_NAME, BASE.POOL_NAME;

END GET_COMPARISON_SUMMARY;
--------------------------------------------------------
FUNCTION GET_RUN_TYPE_NAME
    (
    p_RUN_TYPE_ID IN NUMBER
    ) RETURN VARCHAR2 AS
    
    v_RUN_TYPE VARCHAR2(32);
    
BEGIN

    IF p_RUN_TYPE_ID < 0 THEN
        SELECT ST.SETTLEMENT_TYPE_NAME
        INTO v_RUN_TYPE
        FROM SETTLEMENT_TYPE ST
        WHERE ST.SETTLEMENT_TYPE_ID = (p_RUN_TYPE_ID * -1);
    ELSE
        SELECT S.SCENARIO_NAME
        INTO v_RUN_TYPE
        FROM SCENARIO S
        WHERE S.SCENARIO_ID = p_RUN_TYPE_ID;
    END IF;
    
    RETURN v_RUN_TYPE;
    
END GET_RUN_TYPE_NAME;
--------------------------------------------------------
PROCEDURE GET_COMPARISON_DETAILS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_SERVICE_ID        IN NUMBER,
    p_RUN_TYPE_A_ID     IN NUMBER,
    p_RUN_TYPE_B_ID     IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_SC_ID             IN NUMBER,
	p_FILTER_SC_ID      IN NUMBER,
    p_EDC_ID            IN NUMBER,
    p_FILTER_EDC_ID     IN NUMBER,
    p_ESP_ID            IN NUMBER,
    p_FILTER_ESP_ID     IN NUMBER,
    p_PSE_ID            IN NUMBER,
    p_FILTER_PSE_ID     IN NUMBER,
    p_POOL_ID           IN NUMBER,
    p_FILTER_POOL_ID    IN NUMBER,
    p_DISPLAY_TYPE      IN VARCHAR2,
    p_MAX_ACCOUNTS      IN NUMBER,
    p_UOM               OUT VARCHAR2,
    p_RUN_TYPE_A        OUT VARCHAR2,
    p_RUN_TYPE_B        OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS

    v_SERVICE_CODE_A SERVICE_LOAD.SERVICE_CODE%TYPE;
    v_SCENARIO_ID_A SERVICE.SCENARIO_ID%TYPE;

    v_SERVICE_CODE_B SERVICE_LOAD.SERVICE_CODE%TYPE;
    v_SCENARIO_ID_B SERVICE.SCENARIO_ID%TYPE;

    v_BEGIN DATE;
    v_END DATE;

    v_CUT_BEGIN_DATE DATE;
    v_CUT_END_DATE DATE;

	v_SC_ID SCHEDULE_COORDINATOR.SC_ID%TYPE;
	v_EDC_ID ENERGY_DISTRIBUTION_COMPANY.EDC_ID%TYPE;
	v_PSE_ID PURCHASING_SELLING_ENTITY.PSE_ID%TYPE;
	v_ESP_ID ENERGY_SERVICE_PROVIDER.ESP_ID%TYPE;
	v_POOL_ID POOL.POOL_ID%TYPE;
    
    v_ESP_NAME ESP.ESP_NAME%TYPE;
    v_POOL_NAME POOL.POOL_NAME%TYPE;

BEGIN

    v_SC_ID := NVL(p_SC_ID, p_FILTER_SC_ID);
	v_EDC_ID := NVL(p_EDC_ID, p_FILTER_EDC_ID);
	v_PSE_ID := NVL(p_PSE_ID, p_FILTER_PSE_ID);
	v_ESP_ID := NVL(p_ESP_ID, p_FILTER_ESP_ID);
	v_POOL_ID := NVL(p_POOL_ID, p_FILTER_POOL_ID);
    
    IF v_ESP_ID <> CONSTANTS.ALL_ID THEN
        v_ESP_NAME := EI.GET_ENTITY_NAME(EC.ED_ESP, v_ESP_ID);
    END IF;
    IF v_POOL_ID <> CONSTANTS.ALL_ID THEN
        v_POOL_NAME := EI.GET_ENTITY_NAME(EC.ED_POOL, v_POOL_ID);
    END IF;

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
    p_RUN_TYPE_A := GET_RUN_TYPE_NAME(p_RUN_TYPE_A_ID);
    p_RUN_TYPE_B := GET_RUN_TYPE_NAME(p_RUN_TYPE_B_ID);
    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,v_BEGIN,v_END,p_TIME_ZONE,v_CUT_BEGIN_DATE,v_CUT_END_DATE);

    p_UOM := CASE WHEN p_SERVICE_ID = GA.ELECTRIC_MODEL THEN GA.ELECTRIC_UNIT_OF_MEASURMENT
                  WHEN p_SERVICE_ID = GA.GAS_MODEL THEN GA.GAS_UNIT_OF_MEASURMENT END;

	OPEN p_CURSOR FOR
	WITH BASE AS (
		SELECT LOAD_DATE,
			   ACCOUNT_ID,
               ACCOUNT_NAME,
			   LOAD_VAL_A,
			   LOAD_VAL_B,
			   (LOAD_VAL_A-LOAD_VAL_B) DIFF,
               CASE WHEN INTERVAL_COUNT = 0 THEN NULL ELSE ROUND(PERC_DIFF/INTERVAL_COUNT,4) END MAPE
		FROM (
			SELECT CASE p_INTERVAL
					   WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END AS LOAD_DATE,
				   ACCOUNT_ID,
                   ACCOUNT_NAME,
				   SUM(LOAD_VAL_A) LOAD_VAL_A,
				   SUM(LOAD_VAL_B) LOAD_VAL_B,
                   SUM(PERC_DIFF) PERC_DIFF,
                   COUNT(LOAD_DATE) INTERVAL_COUNT
			FROM (
				SELECT LOAD_DATE, 
                       ACCOUNT_ID,
                       ACCOUNT_NAME, 
                       LOAD_VAL_A, 
                       LOAD_VAL_B,
                       CASE WHEN LOAD_VAL_A = 0 THEN NULL ELSE ABS(100 * (LOAD_VAL_A - LOAD_VAL_B) / LOAD_VAL_A) END PERC_DIFF
				FROM (
					SELECT SL.LOAD_DATE LOAD_DATE,
                           A.ACCOUNT_ID,
                           A.ACCOUNT_NAME,
						   SUM(SL.LOAD_VAL) +
							   CASE WHEN p_DISPLAY_TYPE = c_SERVICE_WITH_LOSSES THEN
								   SUM(SL.TX_LOSS_VAL)+SUM(SL.DX_LOSS_VAL)+SUM(SL.UE_LOSS_VAL)
							   ELSE 0
							   END LOAD_VAL_A
					FROM SERVICE_LOAD SL,
						 SERVICE S,
						 PROVIDER_SERVICE PS,
						 ACCOUNT_SERVICE ASE,
						 (
                             SELECT ACCOUNT_ID,
                                    (
                                        ACCOUNT_NAME 
                                        || 
                                        CASE 
                                            WHEN ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE AND v_ESP_NAME IS NOT NULL THEN
                                                ':' || v_ESP_NAME
                                            ELSE
                                                ''
                                        END 
                                        ||
                                        CASE 
                                            WHEN ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE AND v_POOL_NAME IS NOT NULL THEN
                                                ':' || v_POOL_NAME
                                            ELSE
                                                ''
                                        END 
                                    ) AS ACCOUNT_NAME,
                                    IS_SUB_AGGREGATE,
                                    ACCOUNT_MODEL_OPTION
                             FROM ACCOUNT
                         ) A,
						 SERVICE_DELIVERY SD
					WHERE SL.SERVICE_CODE = v_SERVICE_CODE_A
					  AND SL.LOAD_DATE BETWEEN
							  CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
						  AND
							  CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
					  AND SL.SERVICE_ID = S.SERVICE_ID
					  AND S.MODEL_ID = p_SERVICE_ID
					  AND S.SCENARIO_ID = v_SCENARIO_ID_A
					  AND S.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
					  AND (v_EDC_ID = CONSTANTS.ALL_ID OR PS.EDC_ID = v_EDC_ID)
					  AND (v_ESP_ID = CONSTANTS.ALL_ID OR PS.ESP_ID = v_ESP_ID)
					  AND (v_PSE_ID = CONSTANTS.ALL_ID OR PS.PSE_ID = v_PSE_ID)
					  AND S.ACCOUNT_SERVICE_ID = ASE.ACCOUNT_SERVICE_ID
					  AND ASE.ACCOUNT_ID = A.ACCOUNT_ID
					  AND A.IS_SUB_AGGREGATE = 0
					  AND S.SERVICE_DELIVERY_ID = SD.SERVICE_DELIVERY_ID
					  AND (v_SC_ID = CONSTANTS.ALL_ID OR SD.SC_ID = v_SC_ID)
					  AND (v_POOL_ID = CONSTANTS.ALL_ID OR SD.POOL_ID = v_POOL_ID)
                      
                      AND 1 = CASE 
                              WHEN A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE THEN
                                  CASE 
                                  WHEN ASE.AGGREGATE_ID IN (                           
                                      SELECT AGGREGATE_ID
                                      FROM AGGREGATE_ACCOUNT_ESP AAE
                                      WHERE AAE.ACCOUNT_ID = A.ACCOUNT_ID
                                        AND (v_ESP_ID = CONSTANTS.ALL_ID OR AAE.ESP_ID = v_ESP_ID)
                                        AND (v_POOL_ID = CONSTANTS.ALL_ID OR AAE.POOL_ID = v_POOL_ID)
                                        AND p_BEGIN_DATE <= AAE.END_DATE
                                        AND p_END_DATE >= AAE.BEGIN_DATE
                                   ) THEN 1
                                   ELSE 2
                                   END
                               ELSE 1
                               END
                          
					GROUP BY LOAD_DATE, A.ACCOUNT_ID, ACCOUNT_NAME
					ORDER BY LOAD_DATE
				) A FULL OUTER JOIN (
					SELECT SL.LOAD_DATE LOAD_DATE,
                           A.ACCOUNT_ID,
						   A.ACCOUNT_NAME,
						   SUM(SL.LOAD_VAL) +
							   CASE WHEN p_DISPLAY_TYPE = c_SERVICE_WITH_LOSSES THEN
								   SUM(SL.TX_LOSS_VAL)+SUM(SL.DX_LOSS_VAL)+SUM(SL.UE_LOSS_VAL)
							   ELSE 0
							   END LOAD_VAL_B
					FROM SERVICE_LOAD SL,
						 SERVICE S,
						 PROVIDER_SERVICE PS,
						 ACCOUNT_SERVICE ASE,
						 (
                             SELECT ACCOUNT_ID,
                                    (
                                        ACCOUNT_NAME 
                                        || 
                                        CASE 
                                            WHEN ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE AND v_ESP_NAME IS NOT NULL THEN
                                                ':' || v_ESP_NAME
                                            ELSE
                                                ''
                                        END 
                                        ||
                                        CASE 
                                            WHEN ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE AND v_POOL_NAME IS NOT NULL THEN
                                                ':' || v_POOL_NAME
                                            ELSE
                                                ''
                                        END 
                                    ) AS ACCOUNT_NAME,
                                    IS_SUB_AGGREGATE,
                                    ACCOUNT_MODEL_OPTION
                             FROM ACCOUNT
                         ) A,
						 SERVICE_DELIVERY SD
					WHERE SL.SERVICE_CODE = v_SERVICE_CODE_B
					  AND SL.LOAD_DATE BETWEEN
							  CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
						  AND
							  CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
					  AND SL.SERVICE_ID = S.SERVICE_ID
					  AND S.MODEL_ID = p_SERVICE_ID
					  AND S.SCENARIO_ID = v_SCENARIO_ID_B
					  AND S.PROVIDER_SERVICE_ID = PS.PROVIDER_SERVICE_ID
					  AND (v_EDC_ID = CONSTANTS.ALL_ID OR PS.EDC_ID = v_EDC_ID)
					  AND (v_ESP_ID = CONSTANTS.ALL_ID OR PS.ESP_ID = v_ESP_ID)
					  AND (v_PSE_ID = CONSTANTS.ALL_ID OR PS.PSE_ID = v_PSE_ID)
					  AND S.ACCOUNT_SERVICE_ID = ASE.ACCOUNT_SERVICE_ID
					  AND ASE.ACCOUNT_ID = A.ACCOUNT_ID
					  AND A.IS_SUB_AGGREGATE = 0
					  AND S.SERVICE_DELIVERY_ID = SD.SERVICE_DELIVERY_ID
					  AND (v_SC_ID = CONSTANTS.ALL_ID OR SD.SC_ID = v_SC_ID)
					  AND (v_POOL_ID = CONSTANTS.ALL_ID OR SD.POOL_ID = v_POOL_ID)
                      
                      AND 1 = CASE 
                              WHEN A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE THEN
                                  CASE 
                                  WHEN ASE.AGGREGATE_ID IN (                           
                                      SELECT AGGREGATE_ID
                                      FROM AGGREGATE_ACCOUNT_ESP AAE
                                      WHERE AAE.ACCOUNT_ID = A.ACCOUNT_ID
                                        AND (v_ESP_ID = CONSTANTS.ALL_ID OR AAE.ESP_ID = v_ESP_ID)
                                        AND (v_POOL_ID = CONSTANTS.ALL_ID OR AAE.POOL_ID = v_POOL_ID)
                                        AND p_BEGIN_DATE <= AAE.END_DATE
                                        AND p_END_DATE >= AAE.BEGIN_DATE
                                   ) THEN 1
                                   ELSE 2
                                   END
                               ELSE 1
                               END
                               
					GROUP BY LOAD_DATE, A.ACCOUNT_ID, ACCOUNT_NAME
					ORDER BY LOAD_DATE
				) B
				USING(LOAD_DATE, ACCOUNT_ID, ACCOUNT_NAME)
				ORDER BY LOAD_DATE
			) SLA RIGHT JOIN SYSTEM_DATE_TIME SDT ON SLA.LOAD_DATE = SDT.CUT_DATE
			WHERE SDT.TIME_ZONE = p_TIME_ZONE
			  AND SDT.DATA_INTERVAL_TYPE = p_SERVICE_ID
			  AND SDT.CUT_DATE BETWEEN
					  CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_BEGIN ELSE v_CUT_BEGIN_DATE END
				  AND
					  CASE WHEN p_SERVICE_ID = CONSTANTS.GAS_MODEL THEN v_END ELSE v_CUT_END_DATE END
			  AND SDT.DAY_TYPE = GA.STANDARD
			GROUP BY CASE p_INTERVAL
					   WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END,
					 ACCOUNT_ID, ACCOUNT_NAME
			ORDER BY CASE p_INTERVAL
					   WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
					   WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL END,
					 ACCOUNT_NAME
		)
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
           B.ACCOUNT_ID,
		   B.ACCOUNT_NAME,
		   B.LOAD_VAL_A,
		   B.LOAD_VAL_B,
		   B.DIFF,
		   B.MAPE
	FROM BASE B,
		 ACCOUNT_RANKINGS AR
	WHERE B.ACCOUNT_NAME = AR.ACCOUNT_NAME
	  AND (NVL(p_MAX_ACCOUNTS, CONSTANTS.ALL_ID) = CONSTANTS.ALL_ID OR AR.RANKING <= p_MAX_ACCOUNTS)
	ORDER BY LOAD_DATE, ACCOUNT_NAME
	;

END GET_COMPARISON_DETAILS;
--------------------------------------------------------
PROCEDURE GET_AGGR_CONSUMPTION_SUMMARY
	(
	p_MODEL_ID           IN NUMBER,
	p_SETTLEMENT_TYPE_ID IN NUMBER,
	p_EDC_ID             IN NUMBER,
	p_ESP_ID             IN NUMBER,
	p_BEGIN_DATE         IN DATE,
	p_END_DATE           IN DATE,
	p_THRESHOLD          IN NUMBER,
	p_STATUS             OUT NUMBER,
	p_CURSOR             IN OUT GA.REFCURSOR
	) AS

	v_SCENARIO_ID SERVICE.SCENARIO_ID%TYPE;

BEGIN

    IF p_THRESHOLD < 0 THEN
	    ERRS.RAISE(MSGCODES.c_ERR_ARGUMENT,
					'Threshold Percent must be >=0.');
	END IF;

    SELECT ST.SCENARIO_ID
    INTO v_SCENARIO_ID
    FROM SETTLEMENT_TYPE ST
    WHERE ST.SETTLEMENT_TYPE_ID = p_SETTLEMENT_TYPE_ID;

    QC.AGGREGATE_METERED_USAGE(p_REQUEST_TYPE => 'B', -- 'B'=Settlement module; only used for access rights check
						       p_MODEL_ID => p_MODEL_ID,
							   p_SCENARIO_ID => v_SCENARIO_ID,
							   p_EDC_ID => p_EDC_ID,
							   p_ESP_ID => p_ESP_ID,
							   p_BEGIN_DATE => p_BEGIN_DATE,
							   p_END_DATE => p_END_DATE,
							   p_AS_OF_DATE => CONSTANTS.LOW_DATE,
							   p_THRESHOLD => p_THRESHOLD,
							   p_USE_ACCOUNT_LIST => 0,
							   p_ACCOUNT_LIST => NULL,
							   p_STATUS => p_STATUS,
							   p_CURSOR => p_CURSOR);

END GET_AGGR_CONSUMPTION_SUMMARY;
--------------------------------------------------------
PROCEDURE GET_AGGR_CONSUMPTION_DETAILS
    (
	p_MODEL_ID           IN NUMBER,
	p_SETTLEMENT_TYPE_ID IN NUMBER,
	p_EDC_ID             IN NUMBER,
	p_ESP_ID             IN NUMBER,
	p_ACCOUNT_ID         IN NUMBER,
	p_SERVICE_DATE       IN DATE,
	p_STATUS             OUT NUMBER,
	p_CURSOR             IN OUT GA.REFCURSOR
	) AS

	v_SCENARIO_ID SERVICE.SCENARIO_ID%TYPE;

BEGIN

    SELECT ST.SCENARIO_ID
    INTO v_SCENARIO_ID
    FROM SETTLEMENT_TYPE ST
    WHERE ST.SETTLEMENT_TYPE_ID = p_SETTLEMENT_TYPE_ID;

    QC.PERIOD_BILLED_USAGE_DETAIL(p_REQUEST_TYPE => 'B', -- 'B'=Settlement module; only used for access rights check
                                  p_MODEL_ID => p_MODEL_ID,
                                  p_SCENARIO_ID => v_SCENARIO_ID,
                                  p_EDC_ID => p_EDC_ID,
                                  p_ESP_ID => p_ESP_ID,
                                  p_ACCOUNT_ID => p_ACCOUNT_ID,
                                  p_SERVICE_DATE => p_SERVICE_DATE,
                                  p_AS_OF_DATE => CONSTANTS.LOW_DATE,
                                  p_CONSUMPTION_CODE => '<', -- first character of <All>
                                  p_STATUS => p_STATUS,
                                  p_CURSOR => p_CURSOR);

END GET_AGGR_CONSUMPTION_DETAILS;
-------------------------------------------------------------
-------------------------------------------------------------
--The Run Screen needs to be able to support both MDR backend
--and non-MDR backend. These are wrappers for current UI
--procedures on the Run Screen to allow it to handle both.
-------------------------------------------------------------
-------------------------------------------------------------
--Wrapper for the Run Screen's "Run For" filter
-------------------------------------------------------------
PROCEDURE ENTITY_DOMAINS_FROM_LIST
      (
      p_ENTITY_TYPES IN VARCHAR2,
      p_INCLUDE_ALL IN NUMBER,
      p_CURSOR OUT GA.REFCURSOR
      ) AS

BEGIN

  --When using MDR, we only want to run for all 
  IF UPPER(get_dictionary_value('MDR Backend',0, 'System', 'GA Settings', 'General')) = 'TRUE' THEN
    GUI_UTIL.ENTITY_DOMAINS_FROM_LIST(null, 1, p_CURSOR);
  --When not using MDR, we want to be able to run for the entities
  --specified in the UI 
  ELSE 
    GUI_UTIL.ENTITY_DOMAINS_FROM_LIST(p_ENTITY_TYPES, p_INCLUDE_ALL, p_CURSOR);
  END IF;
  
END ENTITY_DOMAINS_FROM_LIST;
-------------------------------------------------------------
--Wrapper for the Run Screen's "Run" Button
-------------------------------------------------------------
PROCEDURE RUN_CAST_HANDLER
    (
    p_FILTER_MODEL_ID IN NUMBER,
    p_RUN_TYPE_ID IN NUMBER,
    p_ENTITY_DOMAIN_ID IN NUMBER,
      p_ENTITY_IDS IN NUMBER_COLLECTION,
      p_BEGIN_DATE IN DATE,
      p_END_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_ACCEPT_INTO_SCHEDULES IN NUMBER,
    p_SCHEDULE_STATEMENT_TYPE_ID IN NUMBER,
    p_APPLY_USAGE_FACTOR IN NUMBER := 1,
    p_APPLY_UFE IN NUMBER := 1,
    p_TRACE_ON IN NUMBER := 0,
    p_PROCESS_ID OUT VARCHAR2,
    p_PROCESS_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    )
AS
    v_REQUEST_TYPE CHAR;
    v_SCENARIO_ID NUMBER;
    v_IDX NUMBER;
    v_ACCEPT_STATEMENT_TYPE_ID NUMBER(9);
BEGIN
  --When using MDR, we want to use data already in the system as well
  --as run the xCast for MDR
  IF UPPER(get_dictionary_value('MDR Backend',0, 'System', 'GA Settings', 'General')) = 'TRUE' THEN
    MDM.RUN_XCAST(p_BEGIN_DATE,
                  p_END_DATE, 
                  p_TIME_ZONE, 
                  p_RUN_TYPE_ID,
                  p_FILTER_MODEL_ID,
                  p_ACCEPT_INTO_SCHEDULES,
                  p_SCHEDULE_STATEMENT_TYPE_ID,
                  p_APPLY_USAGE_FACTOR,
                  p_APPLY_UFE,
                  p_TRACE_ON);
                  
    IF NVL(p_ACCEPT_INTO_SCHEDULES,0) = 1 THEN
      v_ACCEPT_STATEMENT_TYPE_ID := DETERMINE_SCHED_STATEMENT_TYPE(p_RUN_TYPE_ID, p_SCHEDULE_STATEMENT_TYPE_ID);

      ASSERT(NVL(p_FILTER_MODEL_ID,GA.DEFAULT_MODEL) <> CONSTANTS.ALL_ID, 'Load Data cannot be accepted into schedules for both service types.');
      
      INTERPRET_RUN_TYPE(p_RUN_TYPE_ID, v_REQUEST_TYPE, v_SCENARIO_ID);
      ACCEPT_CAST_INTO_SCHEDULES(p_FILTER_MODEL_ID,
                                   v_REQUEST_TYPE,
                                   v_SCENARIO_ID,
                                   v_ACCEPT_STATEMENT_TYPE_ID,
                                   p_BEGIN_DATE,
                                   p_END_DATE,
                                   p_TRACE_ON,
                                   p_PROCESS_ID,
                                   p_PROCESS_STATUS,
                                   p_MESSAGE);
    END IF;
  --Otherwise, just use RO system
  ELSE 
    RUN_CAST_SERVICE_REQUEST( p_FILTER_MODEL_ID,
                              p_RUN_TYPE_ID,
                              p_ENTITY_DOMAIN_ID,
                              p_ENTITY_IDS,
                              p_BEGIN_DATE,
                              p_END_DATE,
                              p_ACCEPT_INTO_SCHEDULES,
                              p_SCHEDULE_STATEMENT_TYPE_ID,
                              p_APPLY_USAGE_FACTOR,
                              p_APPLY_UFE,
                              p_TRACE_ON,
                              p_PROCESS_ID,
                              p_PROCESS_STATUS,
                              p_MESSAGE);
  END IF;
END RUN_CAST_HANDLER;
----------------------------------------------------------------------------------------------------    
PROCEDURE INT_AGG_ACCT_LIST
    (
    p_CURSOR OUT GA.REFCURSOR
    )
AS
BEGIN

    OPEN p_CURSOR FOR
    SELECT A.ACCOUNT_NAME,
           A.ACCOUNT_ID
    FROM ACCOUNT A
    WHERE A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE
      AND A.ACCOUNT_METER_TYPE = ACCOUNTS_METERS.c_METER_TYPE_INTERVAL
      AND NVL(A.ACCOUNT_EXTERNAL_IDENTIFIER, CONSTANTS.UNDEFINED_ATTRIBUTE) <> CONSTANTS.UNDEFINED_ATTRIBUTE
    ORDER BY A.ACCOUNT_NAME;

END INT_AGG_ACCT_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE ESP_FOR_AGG_ACCT_LIST
    (
    p_AGG_ACCT_ID IN NUMBER,
    p_CURSOR OUT GA.REFCURSOR
    )
AS
BEGIN

    OPEN p_CURSOR FOR
    SELECT DISTINCT ESP.ESP_NAME,
           ESP.ESP_ID
    FROM AGGREGATE_ACCOUNT_ESP AAE,
         ESP
    WHERE AAE.ACCOUNT_ID = p_AGG_ACCT_ID
      AND AAE.ESP_ID = ESP.ESP_ID
      AND NVL(ESP.ESP_EXTERNAL_IDENTIFIER, CONSTANTS.UNDEFINED_ATTRIBUTE) <> CONSTANTS.UNDEFINED_ATTRIBUTE
    ORDER BY ESP_NAME;

END ESP_FOR_AGG_ACCT_LIST;
----------------------------------------------------------------------------------------------------    
PROCEDURE POOL_FOR_AGG_ACCT_LIST
    (
    p_AGG_ACCT_ID IN NUMBER,
    p_CURSOR OUT GA.REFCURSOR
    )
AS
BEGIN

    OPEN p_CURSOR FOR
    SELECT DISTINCT POOL.POOL_NAME,
           POOL.POOL_ID
    FROM AGGREGATE_ACCOUNT_ESP AAE,
         POOL
    WHERE AAE.ACCOUNT_ID = p_AGG_ACCT_ID
      AND AAE.POOL_ID = POOL.POOL_ID
      AND NVL(POOL.POOL_EXTERNAL_IDENTIFIER, CONSTANTS.UNDEFINED_ATTRIBUTE) <> CONSTANTS.UNDEFINED_ATTRIBUTE
    ORDER BY POOL_NAME;
      
END POOL_FOR_AGG_ACCT_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_AGGR_DETAILS_ESP_POOL
    (
    p_AGG_ACCT_ID       IN NUMBER,
    p_ESP_ID            IN NUMBER_COLLECTION,
    p_POOL_ID           IN NUMBER_COLLECTION,
    p_ESP_EXT_IDENTS    OUT VARCHAR2,
    p_POOL_EXT_IDENTS   OUT VARCHAR2
    ) AS
    
    v_ESP_IDS NUMBER_COLLECTION := p_ESP_ID;
    v_POOL_IDS NUMBER_COLLECTION := p_POOL_ID;
    v_CURSOR GA.REFCURSOR;
    v_ESP_NAME ESP.ESP_NAME%TYPE;
    v_ESP_ID ESP.ESP_ID%TYPE;
    v_POOL_NAME POOL.POOL_NAME%TYPE;
    v_POOL_ID POOL.POOL_ID%TYPE;
    
BEGIN
    
    IF UT.NUMBER_COLLECTION_CONTAINS(p_ESP_ID, CONSTANTS.ALL_ID) THEN
        v_ESP_IDS := NUMBER_COLLECTION();
        ESP_FOR_AGG_ACCT_LIST(p_AGG_ACCT_ID, v_CURSOR);
        LOOP
            FETCH v_CURSOR INTO v_ESP_NAME, v_ESP_ID;
            EXIT WHEN v_CURSOR%NOTFOUND;
            
            v_ESP_IDS.EXTEND();
            v_ESP_IDS(v_ESP_IDS.LAST) := v_ESP_ID;
        END LOOP;
    END IF;
    FOR v_IDX IN v_ESP_IDS.FIRST..v_ESP_IDS.LAST LOOP
        IF v_ESP_IDS(v_IDX) <> CONSTANTS.ALL_ID THEN
            p_ESP_EXT_IDENTS := p_ESP_EXT_IDENTS || EI.GET_ENTITY_IDENTIFIER(EC.ED_ESP, v_ESP_IDS(v_IDX), 1);
            IF v_IDX < v_ESP_IDS.LAST THEN
                p_ESP_EXT_IDENTS := p_ESP_EXT_IDENTS || ',';
            END IF;
        END IF;
    END LOOP;
    
    IF UT.NUMBER_COLLECTION_CONTAINS(p_POOL_ID, CONSTANTS.ALL_ID) THEN
        v_POOL_IDS := NUMBER_COLLECTION();
        POOL_FOR_AGG_ACCT_LIST(p_AGG_ACCT_ID, v_CURSOR);
        LOOP
            FETCH v_CURSOR INTO v_POOL_NAME, v_POOL_ID;
            EXIT WHEN v_CURSOR%NOTFOUND;
            
            v_POOL_IDS.EXTEND();
            v_POOL_IDS(v_POOL_IDS.LAST) := v_POOL_ID;
        END LOOP;
    END IF;
    FOR v_IDX IN v_POOL_IDS.FIRST..v_POOL_IDS.LAST LOOP
        IF v_POOL_IDS(v_IDX) <> CONSTANTS.ALL_ID THEN
            p_POOL_EXT_IDENTS := p_POOL_EXT_IDENTS || EI.GET_ENTITY_IDENTIFIER(EC.ED_POOL, v_POOL_IDS(v_IDX), 1);
            IF v_IDX < v_POOL_IDS.LAST THEN
                p_POOL_EXT_IDENTS := p_POOL_EXT_IDENTS || ',';
            END IF;
        END IF;
    END LOOP;
    
END GET_AGGR_DETAILS_ESP_POOL;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_AGGR_DETAILS_MDR
    (
    p_RUN_TYPE IN VARCHAR2,
    p_BEGIN_DATE_STR IN VARCHAR2,
    p_END_DATE_STR IN VARCHAR2,
    p_TIME_ZONE IN VARCHAR2,
    p_AGG_ACCOUNT_IDENTIFIER IN VARCHAR2,
    p_ESP_EXT_IDENTS IN VARCHAR2,
    p_POOL_EXT_IDENTS IN VARCHAR2,
    p_INTERVAL IN VARCHAR2,
    p_LIMIT_BY IN VARCHAR2,
    p_LIMIT_VALUE IN VARCHAR2,
    p_XML_CLOB OUT CLOB
    ) AS
    
    v_CRED     MEX_CREDENTIALS;
    v_LOGGER   MM_LOGGER_ADAPTER;
    v_RESULT   MEX_RESULT;
    v_MESSAGE  VARCHAR2(4000);
    v_STATUS   NUMBER;
    v_PARAMS   MEX_UTIL.PARAMETER_MAP;
    
BEGIN

    MEX_SWITCHBOARD.INIT_MEX(0, NULL, 'MDR:  Get Aggregation Details', 'Get Aggregation Details', null, 0, v_CRED, v_LOGGER);
    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
    v_LOGGER.LOG_START;
    v_PARAMS := MEX_SWITCHBOARD.C_EMPTY_PARAMETER_MAP;
    v_PARAMS('runType') := CD.URL_ENCODE(p_RUN_TYPE);
    v_PARAMS('startDate') := p_BEGIN_DATE_STR;
    v_PARAMS('endDate') := p_END_DATE_STR;
    v_PARAMS('timeZone') := p_TIME_ZONE;
    v_PARAMS('aggAccount') := CD.URL_ENCODE(p_AGG_ACCOUNT_IDENTIFIER);
    v_PARAMS('esps') := CD.URL_ENCODE(p_ESP_EXT_IDENTS);
    v_PARAMS('pools') := CD.URL_ENCODE(p_POOL_EXT_IDENTS);
    v_PARAMS('interval') := CD.URL_ENCODE(p_INTERVAL);
    v_PARAMS('filterType') := p_LIMIT_BY;
    v_PARAMS('filterValue') := CD.URL_ENCODE(p_LIMIT_VALUE);
    v_RESULT := MEX_SWITCHBOARD.INVOKE(p_MARKET => 'mdr',
                                       p_ACTION => 'getAggDetails',
                                       p_LOGGER => v_LOGGER,
                                       p_CRED => v_CRED,
                                       p_PARMS => v_PARAMS);

    IF v_RESULT.STATUS_CODE = MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
        p_XML_CLOB := v_RESULT.RESPONSE;
    END IF;

    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
    v_LOGGER.LOG_STOP(v_STATUS, v_MESSAGE);
    v_MESSAGE := v_LOGGER.GET_END_MESSAGE;

EXCEPTION
    WHEN OTHERS THEN
        v_STATUS  := SQLCODE;
        v_MESSAGE := UT.GET_FULL_ERRM;
        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
        IF v_LOGGER IS NOT NULL THEN
            v_LOGGER.LOG_STOP(v_STATUS, v_MESSAGE);
            v_MESSAGE := v_LOGGER.GET_END_MESSAGE;
        END IF;
        ERRS.RAISE(v_STATUS, v_MESSAGE);
END GET_AGGR_DETAILS_MDR;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_AGGR_DETAILS_CUR
    (
    p_XML_CLOB IN CLOB,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_INTERVAL IN VARCHAR2,
    p_CURSOR OUT GA.REFCURSOR
    ) AS
    
    v_XML  XMLTYPE;
    v_CUT_BEGIN_DATE DATE;
    v_CUT_END_DATE DATE;
    
BEGIN
    
    v_XML := PARSE_UTIL.CREATE_XML_SAFE(p_XML_CLOB);

    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_CUT_BEGIN_DATE, v_CUT_END_DATE);

    OPEN p_CURSOR FOR
    WITH X AS (
        SELECT EXTRACTVALUE(VALUE(T), '//aggDetails/meterReference') AS METER_NAME,
               DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(T), '//aggDetails/timePeriodChar')) AS CUT_DATE,
               EXTRACTVALUE(VALUE(T), '//aggDetails/value') AS VALUE
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML, '/collection/aggDetails'))) T
    )
    SELECT DT,
           METER_NAME,
           SUM(VALUE) AS VALUE
    FROM (
        SELECT (CASE p_INTERVAL
                WHEN CONSTANTS.INTERVAL_15_MINUTE THEN SDT.MI15_YYYY_MM_DD
                WHEN CONSTANTS.INTERVAL_30_MINUTE THEN SDT.MI30_YYYY_MM_DD
                WHEN CONSTANTS.INTERVAL_HOUR THEN SDT.HOUR_YYYY_MM_DD
                WHEN CONSTANTS.INTERVAL_DAY THEN SDT.DAY_YYYY_MM_DD
                WHEN CONSTANTS.INTERVAL_WEEK THEN SDT.WEEK_YYYY_MM_DD
                WHEN CONSTANTS.INTERVAL_MONTH THEN SDT.MONTH_YYYY_MM_DD
                WHEN CONSTANTS.INTERVAL_QUARTER THEN SDT.QUARTER_YYYY_MM_DD
                WHEN CONSTANTS.INTERVAL_YEAR THEN SDT.YEAR_YYYY_MM_DD ELSE NULL 
                END) AS DT,
               X.METER_NAME,
               X.VALUE
        FROM SYSTEM_DATE_TIME SDT,
             X
        WHERE SDT.TIME_ZONE = p_TIME_ZONE
          AND SDT.DATA_INTERVAL_TYPE = 1
          AND SDT.DAY_TYPE = GA.STANDARD
          AND SDT.CUT_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE
          AND SDT.CUT_DATE = X.CUT_DATE (+)
    )
    GROUP BY DT, METER_NAME
    ORDER BY METER_NAME, DT;
    
END GET_AGGR_DETAILS_CUR;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_AGGR_DETAILS
    (
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_TIME_ZONE         IN VARCHAR2,
    p_RUN_TYPE_ID       IN NUMBER,
    p_INTERVAL          IN VARCHAR2,
    p_AGG_ACCT_ID       IN NUMBER,
    p_ESP_ID            IN NUMBER_COLLECTION,
    p_POOL_ID           IN NUMBER_COLLECTION,
    p_LIMIT_BY          IN VARCHAR2,
    p_LIMIT_VALUE       IN VARCHAR2,
    p_ACCOUNT_LABEL     OUT VARCHAR2,
    p_CURSOR            OUT GA.REFCURSOR
    ) AS
    
    v_BEGIN DATE;
    v_END DATE;
    v_RUN_TYPE VARCHAR2(200);
    v_BEGIN_DATE_STR CONSTANT VARCHAR2(16) := TO_CHAR(p_BEGIN_DATE, 'YYYY-MM-DD');
    v_END_DATE_STR CONSTANT VARCHAR2(16) := TO_CHAR(p_END_DATE, 'YYYY-MM-DD');
    v_AGG_ACCOUNT_IDENTIFIER CONSTANT ACCOUNT.ACCOUNT_EXTERNAL_IDENTIFIER%TYPE := EI.GET_ENTITY_IDENTIFIER(EC.ED_ACCOUNT, p_AGG_ACCT_ID, 1);
    v_ESP_EXT_IDENTS VARCHAR2(4000);
    v_POOL_EXT_IDENTS VARCHAR2(4000);
    v_XML_CLOB CLOB;
    v_LIMIT_BY VARCHAR2(16);
    v_LIMIT_VALUE VARCHAR2(128);
    v_LIMIT_VALUE_NUM NUMBER;
    
BEGIN

    p_ACCOUNT_LABEL := EI.GET_ENTITY_NAME(EC.ED_ACCOUNT, p_AGG_ACCT_ID, 1);

    IF p_INTERVAL NOT IN (CONSTANTS.INTERVAL_15_MINUTE, CONSTANTS.INTERVAL_30_MINUTE, CONSTANTS.INTERVAL_HOUR, CONSTANTS.INTERVAL_DAY) THEN
        v_BEGIN := DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_BEGIN_DATE,p_INTERVAL);
        v_END := DATE_UTIL.END_DATE_FOR_INTERVAL(DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(p_END_DATE,p_INTERVAL),p_INTERVAL);
    ELSE
        v_BEGIN := p_BEGIN_DATE;
        v_END := p_END_DATE;
    END IF;
    SP.CHECK_SYSTEM_DATE_TIME(p_TIME_ZONE, v_BEGIN, v_END);
    
    v_LIMIT_VALUE := p_LIMIT_VALUE;
    IF p_LIMIT_BY = 'Meter Name' THEN
        v_LIMIT_BY := 'meter';
        IF v_LIMIT_VALUE IS NULL OR v_LIMIT_VALUE = '' THEN            
            v_LIMIT_VALUE := '%';
        END IF;
    ELSE
        v_LIMIT_BY := 'percentile';
        IF v_LIMIT_VALUE IS NULL OR v_LIMIT_VALUE = '' THEN
            v_LIMIT_VALUE := '0';
        ELSE
            BEGIN
                v_LIMIT_VALUE_NUM := TO_NUMBER(v_LIMIT_VALUE);
                IF v_LIMIT_VALUE_NUM < 0 OR v_LIMIT_VALUE_NUM > 100 THEN
                    ERRS.RAISE(MSGCODES.c_ERR_ARGUMENT);
                END IF;
            EXCEPTION WHEN OTHERS THEN
                ERRS.RAISE(MSGCODES.c_ERR_ARGUMENT, 'Percentile value must be a number between 0 and 100 inclusive.');
            END;        
        END IF;
    END IF;

    v_RUN_TYPE := GET_RUN_TYPE_NAME(p_RUN_TYPE_ID);
    
    GET_AGGR_DETAILS_ESP_POOL(p_AGG_ACCT_ID, p_ESP_ID, p_POOL_ID, v_ESP_EXT_IDENTS, v_POOL_EXT_IDENTS);
    
    GET_AGGR_DETAILS_MDR(v_RUN_TYPE, 
                         v_BEGIN_DATE_STR, 
                         v_END_DATE_STR, 
                         p_TIME_ZONE, 
                         v_AGG_ACCOUNT_IDENTIFIER,
                         v_ESP_EXT_IDENTS,
                         v_POOL_EXT_IDENTS,
                         p_INTERVAL,
                         v_LIMIT_BY,
                         v_LIMIT_VALUE,
                         v_XML_CLOB);
                         
    GET_AGGR_DETAILS_CUR(v_XML_CLOB, v_BEGIN, v_END, p_TIME_ZONE, p_INTERVAL, p_CURSOR);

END GET_AGGR_DETAILS;
----------------------------------------------------------------------------------------------------    
FUNCTION ENABLE_AGG_DET_DRILL
    (
    p_ACCOUNT_ID IN NUMBER
    ) RETURN NUMBER AS
    
    v_COUNT NUMBER;
    
BEGIN

    SELECT COUNT(1)
    INTO v_COUNT
    FROM ACCOUNT A
    WHERE A.ACCOUNT_ID = p_ACCOUNT_ID
      AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE
      AND A.ACCOUNT_METER_TYPE = ACCOUNTS_METERS.c_METER_TYPE_INTERVAL
      AND NVL(A.ACCOUNT_EXTERNAL_IDENTIFIER, CONSTANTS.UNDEFINED_ATTRIBUTE) <> CONSTANTS.UNDEFINED_ATTRIBUTE;
      
    RETURN v_COUNT;
    
END ENABLE_AGG_DET_DRILL;
---------------------------------------------------------------------------------------------------- 
PROCEDURE NULL_CURSOR
    (
	p_CURSOR OUT GA.REFCURSOR
	) AS

BEGIN

	OPEN p_CURSOR FOR
		SELECT NULL FROM DUAL;

END NULL_CURSOR;
---------------------------------------------------------------------------------------------------- 
PROCEDURE GET_COMP_DET_AGG_MET_MDR
    (
    p_RUN_TYPE_A IN VARCHAR2,
    p_RUN_TYPE_B IN VARCHAR2,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_AGG_ACCOUNT_IDENTIFIER IN VARCHAR2,
    p_ESP_EXT_IDENTS IN VARCHAR2,
    p_POOL_EXT_IDENTS IN VARCHAR2,
    p_LIMIT IN VARCHAR2,
    p_XML_CLOB OUT CLOB
    ) AS
    
    v_CRED     MEX_CREDENTIALS;
    v_LOGGER   MM_LOGGER_ADAPTER;
    v_RESULT   MEX_RESULT;
    v_MESSAGE  VARCHAR2(4000);
    v_STATUS   NUMBER;
    v_PARAMS   MEX_UTIL.PARAMETER_MAP;
    
BEGIN

    MEX_SWITCHBOARD.INIT_MEX(0, NULL, 'MDR:  Get Aggregation Details Comparison', 'Get Aggregation Details Comparison', null, 0, v_CRED, v_LOGGER);
    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
    v_LOGGER.LOG_START;
    v_PARAMS := MEX_SWITCHBOARD.C_EMPTY_PARAMETER_MAP;
    v_PARAMS('runTypeA') := CD.URL_ENCODE(p_RUN_TYPE_A);
    v_PARAMS('runTypeB') := CD.URL_ENCODE(p_RUN_TYPE_B);
    v_PARAMS('startDate') := TO_CHAR(p_BEGIN_DATE, 'YYYY-MM-DD');
    v_PARAMS('endDate') := TO_CHAR(p_END_DATE, 'YYYY-MM-DD');
    v_PARAMS('timezone') := p_TIME_ZONE;
    v_PARAMS('aggAccount') := CD.URL_ENCODE(p_AGG_ACCOUNT_IDENTIFIER);
    v_PARAMS('esps') := CD.URL_ENCODE(p_ESP_EXT_IDENTS);
    v_PARAMS('pools') := CD.URL_ENCODE(p_POOL_EXT_IDENTS);
    v_PARAMS('limit') := p_LIMIT;
    v_RESULT := MEX_SWITCHBOARD.INVOKE(p_MARKET => 'mdr',
                                       p_ACTION => 'getAggDetailsComparison',
                                       p_LOGGER => v_LOGGER,
                                       p_CRED => v_CRED,
                                       p_PARMS => v_PARAMS);

    IF v_RESULT.STATUS_CODE = MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
        p_XML_CLOB := v_RESULT.RESPONSE;
    END IF;

    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
    v_LOGGER.LOG_STOP(v_STATUS, v_MESSAGE);
    v_MESSAGE := v_LOGGER.GET_END_MESSAGE;

EXCEPTION
    WHEN OTHERS THEN
        v_STATUS  := SQLCODE;
        v_MESSAGE := UT.GET_FULL_ERRM;
        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
        IF v_LOGGER IS NOT NULL THEN
            v_LOGGER.LOG_STOP(v_STATUS, v_MESSAGE);
            v_MESSAGE := v_LOGGER.GET_END_MESSAGE;
        END IF;
        ERRS.RAISE(v_STATUS, v_MESSAGE);
END GET_COMP_DET_AGG_MET_MDR;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_COMP_DET_AGG_MET_CUR
    (
    p_XML_CLOB IN CLOB,
    p_CURSOR OUT GA.REFCURSOR
    ) AS
    
    v_XML XMLTYPE;
    
BEGIN
    
    v_XML := PARSE_UTIL.CREATE_XML_SAFE(p_XML_CLOB);
    
    OPEN p_CURSOR FOR
    SELECT EXTRACTVALUE(VALUE(T), '//aggComparison/meterReference') AS METER_NAME,
           EXTRACTVALUE(VALUE(T), '//aggComparison/aValue') AS RUN_TYPE_A_VALUE,
           EXTRACTVALUE(VALUE(T), '//aggComparison/bValue') AS RUN_TYPE_B_VALUE,
           EXTRACTVALUE(VALUE(T), '//aggComparison/diff') AS DIFF,
           EXTRACTVALUE(VALUE(T), '//aggComparison/mape') AS MAPE
    FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML, '/collection/aggComparison'))) T;
    
END GET_COMP_DET_AGG_MET_CUR;
----------------------------------------------------------------------------------------------------
$if $$UNIT_TEST_MODE = 1 $then
PROCEDURE GET_COMP_DET_AGG_MET_MDR_T
(
p_RUN_TYPE_A IN VARCHAR2,
p_RUN_TYPE_B IN VARCHAR2,
p_BEGIN_DATE IN DATE,
p_END_DATE IN DATE,
p_TIME_ZONE IN VARCHAR2,
p_AGG_ACCOUNT_IDENTIFIER IN VARCHAR2,
p_ESP_EXT_IDENTS IN VARCHAR2,
p_POOL_EXT_IDENTS IN VARCHAR2,
p_LIMIT IN VARCHAR2,
p_XML_CLOB OUT CLOB
) AS
BEGIN
    ASSERT(p_RUN_TYPE_A = 'Base', 'Run Type A not as expected');
    ASSERT(p_RUN_TYPE_B = 'Final', 'Run Type B not as expected');
    ASSERT(p_BEGIN_DATE = DATE '2015-01-01', 'Begin Date not as expected');
    ASSERT(p_END_DATE = DATE '2015-01-01', 'End Date not as expected');
    ASSERT(p_TIME_ZONE = 'EDT', 'Time Zone not as expected');
    ASSERT(p_AGG_ACCOUNT_IDENTIFIER = 'EDC1:RC1:FC1:HH:LF1:SG1:AG1', 'Agg Account Identifier not as expected');
    ASSERT(p_ESP_EXT_IDENTS = 'ESP1', 'ESP External Identifiers not as expected');
    ASSERT(p_POOL_EXT_IDENTS = 'P1', 'Pool External Identifiers not as expected');
    ASSERT(p_LIMIT = 'ALL', 'Limit not as expected');

    p_XML_CLOB := '<?xml version="1.0" encoding="UTF-8"?>
                    <collection>
                       <aggComparison>
                          <meterReference>meter1</meterReference>
                          <aValue>23.0000</aValue>
                          <bValue>300.0000</bValue>
                          <diff>-277.0000</diff>
                          <mape>1150.0000</mape>
                       </aggComparison>
                       <aggComparison>
                          <meterReference>meter2</meterReference>
                          <aValue>46.0000</aValue>
                          <bValue>300.0000</bValue>
                          <diff>-254.0000</diff>
                          <mape>527.0833</mape>
                       </aggComparison>
                    </collection>';
END GET_COMP_DET_AGG_MET_MDR_T;
$end
----------------------------------------------------------------------------------------------------
PROCEDURE GET_COMPARISON_DETAILS_AGG_MET
    (
    p_BEGIN_DATE         IN DATE,
    p_END_DATE           IN DATE,
    p_TIME_ZONE          IN VARCHAR2,
    p_RUN_TYPE_A_ID      IN NUMBER,
    p_RUN_TYPE_B_ID      IN NUMBER,
    p_ACCOUNT_ID         IN NUMBER,
    p_ACCOUNT_NAME       IN VARCHAR2,
    p_ESP_ID             IN NUMBER,
    p_FILTER_ESP_ID      IN NUMBER,
    p_POOL_ID            IN NUMBER,
    p_FILTER_POOL_ID     IN NUMBER,
    p_MAX_ACCOUNTS       IN NUMBER,
    p_ACCOUNT_NAME_LABEL OUT VARCHAR2,
    p_CURSOR             OUT GA.REFCURSOR
    ) AS
    
    v_RUN_TYPE_A VARCHAR2(200);
    v_RUN_TYPE_B VARCHAR2(200);
    v_LIMIT VARCHAR2(8);
    v_XML_CLOB CLOB;
	v_ESP_ID ENERGY_SERVICE_PROVIDER.ESP_ID%TYPE;
	v_POOL_ID POOL.POOL_ID%TYPE;
    v_AGG_ACCT_EXTERNAL_IDENTIFIER ACCOUNT.ACCOUNT_EXTERNAL_IDENTIFIER%TYPE;
    v_ESP_ID_NUM_COLL NUMBER_COLLECTION := NUMBER_COLLECTION();
    v_POOL_ID_NUM_COLL NUMBER_COLLECTION := NUMBER_COLLECTION();
    v_ESP_EXT_IDENTS VARCHAR2(4000);
    v_POOL_EXT_IDENTS VARCHAR2(4000);
    
BEGIN
    
    IF MDM.GET_MDR_BACKEND_SETTING() <> 'TRUE' THEN
        NULL_CURSOR(p_CURSOR);
        RETURN;
    END IF;
    
    BEGIN
        SELECT A.ACCOUNT_EXTERNAL_IDENTIFIER
        INTO v_AGG_ACCT_EXTERNAL_IDENTIFIER
        FROM ACCOUNT A
        WHERE A.ACCOUNT_ID = p_ACCOUNT_ID
          AND A.ACCOUNT_MODEL_OPTION = ACCOUNTS_METERS.c_ACCT_MODEL_OPTION_AGGREGATE
          AND A.ACCOUNT_METER_TYPE = ACCOUNTS_METERS.c_METER_TYPE_INTERVAL
          AND NVL(A.ACCOUNT_EXTERNAL_IDENTIFIER, CONSTANTS.UNDEFINED_ATTRIBUTE) <> CONSTANTS.UNDEFINED_ATTRIBUTE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL_CURSOR(p_CURSOR);
            RETURN;
    END;
    
    p_ACCOUNT_NAME_LABEL := p_ACCOUNT_NAME;

    v_RUN_TYPE_A := GET_RUN_TYPE_NAME(p_RUN_TYPE_A_ID);
    v_RUN_TYPE_B := GET_RUN_TYPE_NAME(p_RUN_TYPE_B_ID);
    
    IF p_MAX_ACCOUNTS = CONSTANTS.ALL_ID THEN
        v_LIMIT := 'ALL';
    ELSE
        v_LIMIT := TO_CHAR(p_MAX_ACCOUNTS);
    END IF;
    
	v_ESP_ID := NVL(p_ESP_ID, p_FILTER_ESP_ID);
	v_POOL_ID := NVL(p_POOL_ID, p_FILTER_POOL_ID);
    v_ESP_ID_NUM_COLL.EXTEND();
    v_ESP_ID_NUM_COLL(v_ESP_ID_NUM_COLL.LAST) := v_ESP_ID;
    v_POOL_ID_NUM_COLL.EXTEND();
    v_POOL_ID_NUM_COLL(v_POOL_ID_NUM_COLL.LAST) := v_POOL_ID;
    GET_AGGR_DETAILS_ESP_POOL(p_ACCOUNT_ID, v_ESP_ID_NUM_COLL, v_POOL_ID_NUM_COLL, v_ESP_EXT_IDENTS, v_POOL_EXT_IDENTS);
    
    $if $$UNIT_TEST_MODE = 1 $then
    GET_COMP_DET_AGG_MET_MDR_T(v_RUN_TYPE_A, v_RUN_TYPE_B, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_AGG_ACCT_EXTERNAL_IDENTIFIER, v_ESP_EXT_IDENTS, v_POOL_EXT_IDENTS, v_LIMIT, v_XML_CLOB);    
    $else
    GET_COMP_DET_AGG_MET_MDR(v_RUN_TYPE_A, v_RUN_TYPE_B, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_AGG_ACCT_EXTERNAL_IDENTIFIER, v_ESP_EXT_IDENTS, v_POOL_EXT_IDENTS, v_LIMIT, v_XML_CLOB);
    $end
    
    GET_COMP_DET_AGG_MET_CUR(v_XML_CLOB, p_CURSOR);

END GET_COMPARISON_DETAILS_AGG_MET;  
----------------------------------------------------------------------------------------------------
END LOAD_MANAGEMENT_UI;
/
