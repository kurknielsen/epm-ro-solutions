DECLARE
    v_PROCESS_ID            VARCHAR2(12);
    v_PROCESS_STATUS        NUMBER;
    v_MESSAGE               VARCHAR2(2000);
    v_TZS                   STRING_COLLECTION := STRING_COLLECTION('EDT');
    g_TXN_ID                INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_IS_ACTIVE             NUMBER(1);
    v_CURR_TIMESTAMP        TIMESTAMP;
    v_TIME_IDX              NUMBER;
    v_BEGIN_DATE            DATE; 
    v_END_DATE              DATE ;
    v_BEGIN_CUT_DATE        DATE ;
    v_END_CUT_DATE          DATE ;
    v_TIME_ZONE             VARCHAR2(3);
    v_MIN_INTERVAL_NUMBER   NUMBER(2);
    v_TRAIT_VAL             VARCHAR2(32);
    c                       INTEGER;

    PROCEDURE PUT_INTERCHANGE_TRANSACTION
        (p_TRANSACTION_ID           IN  INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
         p_TRANSACTION_NAME         IN  INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE,
         p_TRANSACTION_TYPE         IN  INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE,
         p_TRANSACTION_IDENTIFIER   IN  INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE,
         p_IS_BID_OFFER             IN  INTERCHANGE_TRANSACTION.IS_BID_OFFER%TYPE,
         p_TRANSACTION_INTERVAL     IN  INTERCHANGE_TRANSACTION.TRANSACTION_INTERVAL%TYPE,
         p_BEGIN_DATE               IN  INTERCHANGE_TRANSACTION.BEGIN_DATE%TYPE,
         p_END_DATE                 IN  INTERCHANGE_TRANSACTION.END_DATE%TYPE,
         p_AGREEMENT_TYPE           IN  INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE,
         p_TRAIT_CATEGORY           IN  INTERCHANGE_TRANSACTION.TRAIT_CATEGORY%TYPE
        ) AS
        v_TXN_ID    INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    BEGIN
        -- Setup Interchange Transaction
        c := 0;
        SELECT COUNT(*)
          INTO c
          FROM INTERCHANGE_TRANSACTION T
         WHERE T.TRANSACTION_NAME = p_TRANSACTION_NAME;

        IF c = 0 THEN
            IF p_TRANSACTION_ID IS NOT NULL THEN
                v_TXN_ID := p_TRANSACTION_ID;
            ELSE
                SELECT OID.NEXTVAL INTO v_TXN_ID FROM DUAL;
            END IF;

            INSERT INTO INTERCHANGE_TRANSACTION 
                (TRANSACTION_ID, TRANSACTION_NAME, TRANSACTION_ALIAS, TRANSACTION_DESC, 
                 TRANSACTION_TYPE, TRANSACTION_CODE, TRANSACTION_IDENTIFIER, IS_FIRM, 
                 IS_IMPORT_SCHEDULE, IS_EXPORT_SCHEDULE, IS_BALANCE_TRANSACTION, IS_BID_OFFER, 
                 IS_EXCLUDE_FROM_POSITION, IS_IMPORT_EXPORT, IS_DISPATCHABLE, TRANSACTION_INTERVAL, 
                 EXTERNAL_INTERVAL, ETAG_CODE, BEGIN_DATE, END_DATE, PURCHASER_ID, SELLER_ID, 
                 CONTRACT_ID, SC_ID, POR_ID, POD_ID, COMMODITY_ID, SERVICE_TYPE_ID, 
                 TX_TRANSACTION_ID, PATH_ID, LINK_TRANSACTION_ID, EDC_ID, PSE_ID, ESP_ID, 
                 POOL_ID, SCHEDULE_GROUP_ID, MARKET_PRICE_ID, ZOR_ID, ZOD_ID, SOURCE_ID, SINK_ID, 
                 RESOURCE_ID, AGREEMENT_TYPE, APPROVAL_TYPE, LOSS_OPTION, TRAIT_CATEGORY, TP_ID, ENTRY_DATE)
            VALUES 
                (v_TXN_ID, p_TRANSACTION_NAME, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE,
                 p_TRANSACTION_TYPE, CONSTANTS.UNDEFINED_ATTRIBUTE, p_TRANSACTION_IDENTIFIER, 0,
                 0, 0, 0, p_IS_BID_OFFER,
                 0, 0, 0, p_TRANSACTION_INTERVAL,
                 CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE, p_BEGIN_DATE, p_END_DATE, 0, 0,
                 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0,
                 0, 0, 0, 0, 0, 0, 0,
                 0, p_AGREEMENT_TYPE, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE, p_TRAIT_CATEGORY, 0, SYSDATE);
        ELSE 
            SELECT TT.TRANSACTION_ID
              INTO v_TXN_ID
              FROM INTERCHANGE_TRANSACTION TT
             WHERE TT.TRANSACTION_NAME = p_TRANSACTION_NAME;
            
            UPDATE INTERCHANGE_TRANSACTION
               SET TRANSACTION_NAME = p_TRANSACTION_NAME,
                   TRANSACTION_ALIAS = CONSTANTS.UNDEFINED_ATTRIBUTE,
                   TRANSACTION_DESC = CONSTANTS.UNDEFINED_ATTRIBUTE,
                   TRANSACTION_TYPE = p_TRANSACTION_TYPE,
                   TRANSACTION_CODE = CONSTANTS.UNDEFINED_ATTRIBUTE,
                   TRANSACTION_IDENTIFIER = p_TRANSACTION_IDENTIFIER,
                   IS_FIRM = 0,
                   IS_IMPORT_SCHEDULE = 0,
                   IS_EXPORT_SCHEDULE = 0,
                   IS_BALANCE_TRANSACTION = 0,
                   IS_BID_OFFER = p_IS_BID_OFFER,
                   IS_EXCLUDE_FROM_POSITION = 0,
                   IS_IMPORT_EXPORT = 0,
                   IS_DISPATCHABLE = 0,
                   TRANSACTION_INTERVAL = p_TRANSACTION_INTERVAL,
                   EXTERNAL_INTERVAL = CONSTANTS.UNDEFINED_ATTRIBUTE,
                   ETAG_CODE = CONSTANTS.UNDEFINED_ATTRIBUTE,
                   BEGIN_DATE = p_BEGIN_DATE,
                   END_DATE = p_END_DATE,
                   PURCHASER_ID = 0,
                   SELLER_ID = 0,
                   CONTRACT_ID = 0,
                   SC_ID = 0,
                   POR_ID = 0,
                   POD_ID = 0,
                   COMMODITY_ID = 0,
                   SERVICE_TYPE_ID = 0,
                   TX_TRANSACTION_ID = 0,
                   PATH_ID = 0,
                   LINK_TRANSACTION_ID = 0,
                   EDC_ID = 0,
                   PSE_ID = 0,
                   ESP_ID = 0,
                   POOL_ID = 0,
                   SCHEDULE_GROUP_ID = 0,
                   MARKET_PRICE_ID = 0,
                   ZOR_ID = 0,
                   ZOD_ID = 0,
                   SOURCE_ID = 0,
                   SINK_ID = 0,
                   RESOURCE_ID = 0,
                   AGREEMENT_TYPE = p_AGREEMENT_TYPE,
                   APPROVAL_TYPE = CONSTANTS.UNDEFINED_ATTRIBUTE,
                   LOSS_OPTION = CONSTANTS.UNDEFINED_ATTRIBUTE,
                   TRAIT_CATEGORY = p_TRAIT_CATEGORY,
                   TP_ID = 0,
                   ENTRY_DATE = SYSDATE
             WHERE TRANSACTION_NAME = p_TRANSACTION_NAME
               AND TRANSACTION_ID = v_TXN_ID;
        END IF;

        -- Set the Transaction Status to Active
        BEGIN
            UPDATE IT_STATUS
               SET TRANSACTION_STATUS_NAME = 'Active',
                   TRANSACTION_IS_ACTIVE = 1
             WHERE TRANSACTION_ID = v_TXN_ID
               AND AS_OF_DATE = CONSTANTS.LOW_DATE;

            IF SQL%NOTFOUND THEN
                INSERT INTO IT_STATUS (
                    TRANSACTION_ID,
                    AS_OF_DATE,
                    TRANSACTION_STATUS_NAME,
                    TRANSACTION_IS_ACTIVE)
                VALUES (
                    v_TXN_ID,
                    CONSTANTS.LOW_DATE,
                    'Active',
                    1);
            END IF;
        END;
    END PUT_INTERCHANGE_TRANSACTION;
BEGIN
    SECURITY_CONTROLS.SET_CURRENT_USER('ventyxadmin');

    -----------------------------------------------
    -- Setup Gate Reference Interchange Transaction
    -----------------------------------------------
    g_TXN_ID := MM_SEM_UTIL.g_SEM_GATE_REF_TXN_ID;

    -- Setup System Date Time for 1900-01-01(Low Date)
    BEGIN
        SP.CHECK_SYSTEM_DATE_TIME(MM_SEM_UTIL.g_TZ, CONSTANTS.LOW_DATE, CONSTANTS.LOW_DATE);
    EXCEPTION
    WHEN OTHERS THEN
        POPULATE_SYSTEM_DATE_TIME.RUN(CONSTANTS.LOW_DATE,
                                      CONSTANTS.LOW_DATE,
                                      v_TZS,
                                      NULL,
                                      v_PROCESS_ID,
                                      v_PROCESS_STATUS,
                                      v_MESSAGE);
    END;

    PUT_INTERCHANGE_TRANSACTION(g_TXN_ID, MM_SEM_UTIL.c_TXN_NAME_GATE_REFERENCE, MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
                                MM_SEM_UTIL.c_TXN_NAME_GATE_REFERENCE, 1, DATE_UTIL.c_NAME_30MIN, CONSTANTS.LOW_DATE,
                                CONSTANTS.HIGH_DATE, CONSTANTS.UNDEFINED_ATTRIBUTE, 'Gate Reference');

    UPDATE TRANSACTION_TRAIT_GROUP X
       SET X.SC_ID = 0,
           X.TRAIT_GROUP_TYPE = CONSTANTS.UNDEFINED_ATTRIBUTE
     WHERE X.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_SEM_GATE_REFERENCE;

    -- Setup Trait Values
    v_BEGIN_DATE := CONSTANTS.LOW_DATE;
    v_END_DATE   := CONSTANTS.LOW_DATE;
    v_TIME_ZONE  := MM_SEM_UTIL.g_TZ;
    v_MIN_INTERVAL_NUMBER := GET_INTERVAL_NUMBER('MI30');
    
    SP.CHECK_SYSTEM_DATE_TIME(v_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
    UT.CUT_DATE_RANGE(v_BEGIN_DATE, v_END_DATE, v_TIME_ZONE, v_BEGIN_CUT_DATE, v_END_CUT_DATE);
    
    FOR v_CURSOR IN (
        SELECT SDT.CUT_DATE_SCHEDULING,
                     SDT.LOCAL_DATE
        FROM SYSTEM_DATE_TIME SDT
        WHERE SDT.TIME_ZONE = v_TIME_ZONE
            AND SDT.DATA_INTERVAL_TYPE = 1
            AND SDT.DAY_TYPE = '1'
            AND SDT.CUT_DATE BETWEEN v_BEGIN_CUT_DATE AND v_END_CUT_DATE
            AND SDT.MINIMUM_INTERVAL_NUMBER >= v_MIN_INTERVAL_NUMBER
    ) LOOP
        -- From 00:30 to 06:00, the trait value shall be WD1.
        -- From 18:30 to 24:00, the trait value shall be WD1.
        IF (v_CURSOR.LOCAL_DATE >= TIMESTAMP '1900-01-01 00:30:00' AND v_CURSOR.LOCAL_DATE <= TIMESTAMP '1900-01-01 06:00:00')
                OR 
             (v_CURSOR.LOCAL_DATE >= TIMESTAMP '1900-01-01 18:30:00' AND v_CURSOR.LOCAL_DATE <= TIMESTAMP '1900-01-02 00:00:00') THEN
             v_TRAIT_VAL := 'WD1';
        -- From 06:30 to 18:00, the trait value shall be EA2.
        ELSE
             v_TRAIT_VAL := 'EA2';
        END IF;

        TG.PUT_IT_TRAIT_SCHED_DETAIL_RPT(p_TRANSACTION_ID         => g_TXN_ID,
                                         p_SCHEDULE_STATE         => 1,
                                         p_SCHEDULE_TYPE          => 0,
                                         p_CUT_DATE_SCHEDULING    => v_CURSOR.CUT_DATE_SCHEDULING,
                                         p_TRAIT_GROUP_ID         => MM_SEM_UTIL.g_TG_SEM_GATE_REFERENCE,
                                         p_TRAIT_INDEX            => 1,
                                         p_SET_NUMBER             => 1,
                                         p_TRAIT_VAL              => v_TRAIT_VAL,
                                         p_REASON_FOR_CHANGE      => NULL,
                                         p_OTHER_REASON           => NULL,
                                         p_PROCESS_MESSAGE        => NULL);
    END LOOP;
    --------------------------------------------------------------------------------------------------------------

    -------------------------------------------------
    -- Setup Shadow Price EUR Interchange Transaction
    -------------------------------------------------
    PUT_INTERCHANGE_TRANSACTION(MM_SEM_UTIL.g_SHADOW_PRICE_EUR_TXN_ID, MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_EUR, MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
                                MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_EUR, 0, DATE_UTIL.c_NAME_30MIN, CONSTANTS.LOW_DATE,
                                CONSTANTS.HIGH_DATE, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE);
    --------------------------------------------------------------------------------------------------------------

    -------------------------------------------------
    -- Setup Shadow Price GBP Interchange Transaction
    -------------------------------------------------
    PUT_INTERCHANGE_TRANSACTION(MM_SEM_UTIL.g_SHADOW_PRICE_GBP_TXN_ID, MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_GBP, MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
                                MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_GBP, 0, DATE_UTIL.c_NAME_30MIN, CONSTANTS.LOW_DATE,
                                CONSTANTS.HIGH_DATE, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE);
    --------------------------------------------------------------------------------------------------------------

    -------------------------------------------------
    -- Setup SEM SMP - EUR Interchange Transaction
    -------------------------------------------------
    PUT_INTERCHANGE_TRANSACTION(MM_SEM_UTIL.g_SMP_EUR_TXN_ID, MM_SEM_UTIL.c_TXN_NAME_SMP_EUR, MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
                                MM_SEM_UTIL.c_TXN_NAME_SMP_EUR, 0, DATE_UTIL.c_NAME_30MIN, CONSTANTS.LOW_DATE,
                                CONSTANTS.HIGH_DATE, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE);
    --------------------------------------------------------------------------------------------------------------

    -------------------------------------------------
    -- Setup SEM SMP - GBP Interchange Transaction
    -------------------------------------------------
    PUT_INTERCHANGE_TRANSACTION(MM_SEM_UTIL.g_SMP_GBP_TXN_ID, MM_SEM_UTIL.c_TXN_NAME_SMP_GBP, MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
                                MM_SEM_UTIL.c_TXN_NAME_SMP_GBP, 0, DATE_UTIL.c_NAME_30MIN, CONSTANTS.LOW_DATE,
                                CONSTANTS.HIGH_DATE, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE);
    --------------------------------------------------------------------------------------------------------------
	
	-------------------------------------------------
    -- Setup SEM Average SMP EUR Interchange Transaction
    -------------------------------------------------
    PUT_INTERCHANGE_TRANSACTION(MM_SEM_UTIL.g_AVG_SMP_EUR_TXN_ID, MM_SEM_UTIL.c_TXN_NAME_AVG_SMP_EUR, MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
                                MM_SEM_UTIL.c_TXN_NAME_AVG_SMP_EUR, 0, DATE_UTIL.c_NAME_DAY, CONSTANTS.LOW_DATE,
                                CONSTANTS.HIGH_DATE, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE);
    --------------------------------------------------------------------------------------------------------------

    -------------------------------------------------
    -- Setup SEM Average SMP GBP Interchange Transaction
    -------------------------------------------------
    PUT_INTERCHANGE_TRANSACTION(MM_SEM_UTIL.g_AVG_SMP_GBP_TXN_ID, MM_SEM_UTIL.c_TXN_NAME_AVG_SMP_GBP, MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
                                MM_SEM_UTIL.c_TXN_NAME_AVG_SMP_GBP, 0, DATE_UTIL.c_NAME_DAY, CONSTANTS.LOW_DATE,
                                CONSTANTS.HIGH_DATE, CONSTANTS.UNDEFINED_ATTRIBUTE, CONSTANTS.UNDEFINED_ATTRIBUTE);
    --------------------------------------------------------------------------------------------------------------

    COMMIT;
END;
/