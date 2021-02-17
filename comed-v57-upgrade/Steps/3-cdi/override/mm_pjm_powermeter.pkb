CREATE OR REPLACE PACKAGE BODY MM_PJM_POWERMETER IS

g_INADVERTENT_CONTROL_AREA VARCHAR2(32); -- initialized below
g_INADVERTENT_OWNER VARCHAR2(32);

----------------------------------------------------------------------------------------------------
FUNCTION GET_PJM_METER_SOURCE_ID RETURN NUMBER IS
v_ID NUMBER;

BEGIN
    RETURN EI.GET_ID_FROM_ALIAS('PJM', EC.ED_MEASUREMENT_SOURCE);
EXCEPTION
    WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
        -- create if not found
        IO.PUT_MEASUREMENT_SOURCE(v_ID, 'PJM', 'PJM', 'Meter data imported from PJM',
                                0, NULL, 'Hour', NULL, LOW_DATE, NULL, EC.ES_PJM,
                                NULL, NULL, NULL, NULL);
        RETURN v_ID;

END GET_PJM_METER_SOURCE_ID;

----------------------------------------------------------------------------------------------------
PROCEDURE SET_METER_OWNER
    (
    p_METER_ID IN NUMBER,
    p_METER_OWNER IN VARCHAR2
    ) AS
v_OWNER_ID NUMBER;

BEGIN
    SELECT PSE_ID
    INTO v_OWNER_ID
    FROM PURCHASING_SELLING_ENTITY
    WHERE PSE_ID = EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_METER_OWNER, EC.ED_PSE, EC.ES_PJM, 'Long Name');


    UT.PUT_TEMPORAL_DATA('TX_SUB_STATION_METER_OWNER', LOW_DATE, NULL, TRUE, TRUE,
                        'METER_ID', UT.GET_LITERAL_FOR_NUMBER(p_METER_ID), TRUE,
                        'OWNER_ID', UT.GET_LITERAL_FOR_NUMBER(v_OWNER_ID), FALSE);
END SET_METER_OWNER;
----------------------------------------------------------------------------------------------------
FUNCTION GET_METER_POINT_ID
    (
    p_METER_ID IN NUMBER
    ) RETURN NUMBER IS
v_SOURCE_ID NUMBER := GET_PJM_METER_SOURCE_ID;
v_RET NUMBER;

BEGIN
    SELECT DISTINCT P.METER_POINT_ID
    INTO v_RET
    FROM TX_SUB_STATION_METER_POINT P, TX_SUB_STATION_METER_PT_SOURCE PS
    WHERE P.SUB_STATION_METER_ID = p_METER_ID
        AND PS.METER_POINT_ID = P.METER_POINT_ID
        AND PS.MEASUREMENT_SOURCE_ID = v_SOURCE_ID;


    RETURN v_RET;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, TEXT_UTIL.TO_CHAR_ENTITY(EC.ED_SUB_STATION_METER_POINT, EC.ED_ENTITY_DOMAIN)||' for '||
                                                    TEXT_UTIL.TO_CHAR_ENTITY(p_METER_ID, EC.ED_SUB_STATION_METER, TRUE)||' with '||
                                                    TEXT_UTIL.TO_CHAR_ENTITY(v_SOURCE_ID, EC.ED_MEASUREMENT_SOURCE, TRUE));

END GET_METER_POINT_ID;

----------------------------------------------------------------------------------------------------
PROCEDURE PUT_METER_VALUE
    (
    p_METER_ID IN NUMBER,
    p_DATE IN DATE,
    p_METER_VAL IN NUMBER
    ) AS
v_METER_POINT_ID NUMBER;
v_SOURCE_ID NUMBER := GET_PJM_METER_SOURCE_ID;
BEGIN
    v_METER_POINT_ID := GET_METER_POINT_ID(p_METER_ID);

    UPDATE TX_SUB_STATION_METER_PT_VALUE SET METER_VAL = p_METER_VAL
    WHERE METER_POINT_ID = v_METER_POINT_ID
    AND MEASUREMENT_SOURCE_ID = v_SOURCE_ID
    AND METER_CODE = CONSTANTS.CODE_ACTUAL
    AND METER_DATE = p_DATE;

    IF SQL%NOTFOUND THEN
         INSERT INTO TX_SUB_STATION_METER_PT_VALUE
             (METER_POINT_ID, MEASUREMENT_SOURCE_ID, METER_CODE, METER_DATE, METER_VAL)
        VALUES
             (v_METER_POINT_ID, v_SOURCE_ID, CONSTANTS.CODE_ACTUAL, p_DATE, p_METER_VAL);

    END IF;
END PUT_METER_VALUE;
----------------------------------------------------------------------------------
PROCEDURE IMPORT_XML
    (
   p_XML       IN XMLTYPE,
   p_PROCESS_STATUS     OUT NUMBER,
   p_MESSAGE            OUT VARCHAR2
    ) AS
v_REC_COUNT NUMBER := 0;
v_BAD_REC_COUNT NUMBER := 0;
v_SET_OF_IDS UT.STRING_MAP;
CURSOR c_METER_VALUES IS
SELECT
   M.METER_ID,
   M.METER_NAME,
   M.METER_OWNER,
   DATE_UTIL.TO_CUT_DATE_FROM_ISO(M.BEGIN_DATE) AS BEGIN_DATE,
   DATE_UTIL.TO_CUT_DATE_FROM_ISO(M.END_DATE) AS END_DATE,
   M.AMOUNT
 FROM(
    SELECT
         EXTRACTVALUE(VALUE(METER_ACCOUNT), '//meterAccount/meterAccountID') AS METER_ID,
         EXTRACTVALUE(VALUE(METER_ACCOUNT), '//meterAccount/meterAccountName') AS METER_NAME,
         EXTRACTVALUE(VALUE(METER_ACCOUNT), '//meterAccount/counterParty') AS METER_OWNER,
         EXTRACTVALUE(VALUE(MAHMV), '//startDate') AS BEGIN_DATE,
         EXTRACTVALUE(VALUE(MAHMV), '//endDate') AS END_DATE,
         EXTRACTVALUE(VALUE(MAHMV), '//mw') AS AMOUNT
  FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'MeterValues'))) METER_VALUES,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(METER_VALUES),'//meterAccount'))) METER_ACCOUNT,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(METER_ACCOUNT),'//hourlyMeterValues/intervalValue'))) MAHMV
    UNION
     SELECT 'Total Inadvertent' AS METER_ID,
        'Total Inadvertent' AS METER_NAME,
        'INADVERTENT' AS METER_OWNER,
        EXTRACTVALUE(VALUE(TI), '//startDate') AS BEGIN_DATE,
        EXTRACTVALUE(VALUE(TI), '//endDate') AS END_DATE,
        EXTRACTVALUE(VALUE(TI), '//mw') AS AMOUNT
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'MeterValues'))) METER_VALUES,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(METER_VALUES),'//totalInadvertent/area'))) TOTAL_INADVERTENT_AREA,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(TOTAL_INADVERTENT_AREA),'//intervalValues/intervalValue'))) TI) M;

 BEGIN
    -- now loop over data just dumped to work table and process
    FOR v_METER_VALUE IN c_METER_VALUES LOOP
        BEGIN
        PUT_METER_VALUE (EI.GET_ID_FROM_IDENTIFIER(v_METER_VALUE.METER_ID, EC.ED_SUB_STATION_METER, 1), v_METER_VALUE.END_DATE, v_METER_VALUE.AMOUNT);
        v_REC_COUNT := v_REC_COUNT+1;
        EXCEPTION
            WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
                -- only log one error per meter ID - not one per record
                IF NOT v_SET_OF_IDS.EXISTS(v_METER_VALUE.METER_ID) THEN
                    LOGS.LOG_DEBUG_MORE_DETAIL(v_METER_VALUE.METER_ID || ' - ' ||  v_METER_VALUE.METER_NAME || ' does not exist.');
                    v_SET_OF_IDs(v_METER_VALUE.METER_ID) := ' '; -- dummy value - key is all we are interested in
                END IF;

                v_BAD_REC_COUNT := v_BAD_REC_COUNT+1;

        END;

    END LOOP;

    p_PROCESS_STATUS := GA.SUCCESS;
    IF v_BAD_REC_COUNT > 0 THEN
         LOGS.LOG_DEBUG_MORE_DETAIL(TO_CHAR(v_BAD_REC_COUNT)||' records failed due to missing meters.');
    END IF;


EXCEPTION
    WHEN OTHERS THEN
        p_PROCESS_STATUS := SQLCODE;
        p_MESSAGE := UT.GET_FULL_ERRM;

END IMPORT_XML;
----------------------------------------------------------------------------------
PROCEDURE IMPORT_ALLOCATED_METER_VALUES
  (
    p_XML XMLTYPE,
    p_STATUS IN OUT NUMBER,
    p_MESSAGE IN OUT VARCHAR2
    ) AS
v_REC_COUNT NUMBER := 0;
v_BAD_REC_COUNT NUMBER := 0;
v_WORK_ID NUMBER(9);
v_ENTITY_NAME VARCHAR2(64);
v_TXN_ID_INADV NUMBER(9);
v_TXN_ID_DERAT NUMBER(9);
v_SET_OF_IDS UT.STRING_MAP;
CURSOR c_METER_VALUES IS
  SELECT EXTRACTVALUE(VALUE(T), '//meterAccountID') "METER_ID",
    EXTRACTVALUE(VALUE(T), '//meterAccountName') "METER_NAME",
    EXTRACTVALUE(VALUE(T), '//meterAccount/counterParty') "METER_OWNER",
    DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(U), '//startDate')) "BEGIN_DATE",
    DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(U), '//endDate')) "END_DATE",
    EXTRACTVALUE(VALUE(U), '//intervalValue/mw') "AMOUNT"
  FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT XML_DATA FROM MM_EMTR_XML_WORK WHERE WORK_ID = v_WORK_ID/*v_WORK_ID*/),'//meterAccount'))) T,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'//hourlyAllocatedValues/intervalValue'))) U
    ORDER BY 1,4;



CURSOR c_INADVERT_METER_VALUES IS
  SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "INADVERT_BEGIN_DATE",
    DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "INADVERT_END_DATE",
    EXTRACTVALUE(VALUE(V), '//ehvAreaName') "ENTITY_NAME",
    EXTRACTVALUE(VALUE(W), '//intervalValue/mw') "INADVERT_AMOUNT"
  FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT XML_DATA FROM MM_EMTR_XML_WORK WHERE WORK_ID = v_WORK_ID/*v_WORK_ID*/),'//shareLosses'))) V,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//area/intervalValues/intervalValue'))) W;



CURSOR c_DERATED_LOSS_VALUES IS
  SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "DERATED_BEGIN_DATE",
    DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "DERATED_END_DATE",
    EXTRACTVALUE(VALUE(W), '//mw') "DERATED_LOSS_AMOUNT"
  FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT XML_DATA FROM MM_EMTR_XML_WORK WHERE WORK_ID = v_WORK_ID/*v_WORK_ID*/),'//deratedLossAdjustment'))) V,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//intervalValue'))) W;



BEGIN
  UT.GET_RTO_WORK_ID(v_WORK_ID);

  -- dump info to work table (to work around oracle bug that throws exception when
  -- trying to open queries as cursors)
  INSERT INTO MM_EMTR_XML_WORK (WORK_ID, OWNER_DATA, CA_DATA, XML_DATA)
    VALUES (v_WORK_ID, g_INADVERTENT_OWNER, g_INADVERTENT_CONTROL_AREA, p_XML);



  -- now loop over data just dumped to work table and process
  FOR v_METER_VALUE IN c_METER_VALUES LOOP
    BEGIN
       PUT_METER_VALUE (EI.GET_ID_FROM_IDENTIFIER(v_METER_VALUE.METER_ID, EC.ED_SUB_STATION_METER, 1), v_METER_VALUE.END_DATE, v_METER_VALUE.AMOUNT);
       v_REC_COUNT := v_REC_COUNT+1;
       EXCEPTION
            WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
                -- only log one error per meter ID - not one per record
                IF NOT v_SET_OF_IDS.EXISTS(v_METER_VALUE.METER_ID) THEN
                     LOGS.LOG_DEBUG_MORE_DETAIL(v_METER_VALUE.METER_ID || ' - ' ||  v_METER_VALUE.METER_NAME || ' does not exist.');
                   v_SET_OF_IDs(v_METER_VALUE.METER_ID) := ' '; -- dummy value - key is all we are interested in
                END IF;
                v_BAD_REC_COUNT := v_BAD_REC_COUNT+1;
    END;
  END LOOP;




  FOR v_METER_VALUE IN c_INADVERT_METER_VALUES LOOP
      v_ENTITY_NAME := 'Inadvertent Meter Values - ' || v_METER_VALUE.ENTITY_NAME;
      v_TXN_ID_INADV := EI.GET_ID_FROM_NAME(v_ENTITY_NAME, EC.ED_TRANSACTION,1);
      IF v_TXN_ID_INADV IS NOT NULL THEN
        ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID_INADV,
                             p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FORECAST,
                             p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                             p_SCHEDULE_DATE => v_METER_VALUE.INADVERT_END_DATE,
                             p_AS_OF_DATE => LOW_DATE,
                             p_AMOUNT => v_METER_VALUE.INADVERT_AMOUNT,
                             p_PRICE => NULL,
                             p_STATUS => p_STATUS);
      ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL(v_ENTITY_NAME || ' transaction must exist to import shareLosses data.');
        EXIT;
      END IF;
  END LOOP;


  v_TXN_ID_DERAT := EI.GET_ID_FROM_NAME('Derated Loss Values', EC.ED_TRANSACTION,1);
  FOR v_METER_VALUE IN c_DERATED_LOSS_VALUES LOOP
      IF v_TXN_ID_DERAT IS NOT NULL THEN
        ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID_DERAT,
                             p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FORECAST,
                             p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                             p_SCHEDULE_DATE => v_METER_VALUE.DERATED_END_DATE,
                             p_AS_OF_DATE => LOW_DATE,
                             p_AMOUNT => v_METER_VALUE.DERATED_LOSS_AMOUNT,
                             p_PRICE => NULL,
                             p_STATUS => p_STATUS);
      ELSE
         LOGS.LOG_DEBUG_MORE_DETAIL('Derated Losses transaction must exist to import deratedLossAdjustmen data.');
         EXIT;
      END IF;
  END LOOP;



  --cleanup
  DELETE MM_EMTR_XML_WORK WHERE WORK_ID = v_WORK_ID/*v_WORK_ID*/;



  p_STATUS := GA.SUCCESS;

  IF v_BAD_REC_COUNT > 0 THEN
      LOGS.LOG_DEBUG_MORE_DETAIL(TO_CHAR(v_BAD_REC_COUNT)||' records failed due to missing meters.');
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    --cleanup
    DELETE MM_EMTR_XML_WORK WHERE WORK_ID = -1/*v_WORK_ID*/;


    p_STATUS := SQLCODE;
    p_MESSAGE := UT.GET_FULL_ERRM;

END IMPORT_ALLOCATED_METER_VALUES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOAD_SUBMISSION_DTL
    (
   p_XML           IN XMLTYPE,
   p_PROCESS_STATUS     OUT NUMBER,
   p_MESSAGE            OUT VARCHAR2
    )AS

v_LOAD_WO_LOSSES_ID NUMBER;
v_DAILY_W_LOSSES_ID NUMBER;
v_EOM_W_LOSSES_ID NUMBER;
v_ACTUAL_NMI_ID NUMBER;
v_TOTAL_GEN_ID NUMBER;
v_METER_ID NUMBER;


CURSOR c_LOAD_WO_LOSSES IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//loadWithoutLosses/intervalValue'))) W
    ORDER BY END_DATE;


CURSOR c_LOAD_W_LOSSES IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//loadWithLosses/intervalValue'))) W
    ORDER BY END_DATE;


CURSOR c_ACTUAL_NMI IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//actualNmi/intervalValue'))) W
    ORDER BY END_DATE;


CURSOR c_TOTAL_GEN IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//totalInternalGen/intervalValue'))) W
    ORDER BY END_DATE;


BEGIN
    p_MESSAGE := NULL;

    --Import without losses
    v_LOAD_WO_LOSSES_ID := EI.GET_ID_FROM_NAME('Final Daily eMTR Load Without Losses', EC.ED_TRANSACTION,1);
    IF v_LOAD_WO_LOSSES_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_LOAD_WO_LOSSES LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_LOAD_WO_LOSSES_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
        END LOOP;

    ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('Final Daily eMTR Load Without Losses transaction must exist to import loadWithoutLosses data.');

    END IF;


   --Import with losses
    v_DAILY_W_LOSSES_ID := EI.GET_ID_FROM_NAME('Final Daily eMTR Load With Losses', EC.ED_TRANSACTION,1);
    v_EOM_W_LOSSES_ID := EI.GET_ID_FROM_NAME('Final EOM eMTR Load With Losses', EC.ED_TRANSACTION,1);
    IF v_DAILY_W_LOSSES_ID IS NULL THEN
         LOGS.LOG_DEBUG_MORE_DETAIL('Final Daily eMTR Load With Losses transaction must exist to import loadWithLosses data.');
    END IF;

    IF v_EOM_W_LOSSES_ID IS NULL THEN
        LOGS.LOG_DEBUG_MORE_DETAIL('Final EOM eMTR Load With Losses transaction must exist to import loadWithLosses data.');
    END IF;

    FOR v_METER_VALUE IN c_LOAD_W_LOSSES LOOP
        IF v_DAILY_W_LOSSES_ID IS NOT NULL THEN
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_DAILY_W_LOSSES_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
        END IF;

        IF v_EOM_W_LOSSES_ID IS NOT NULL THEN
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_EOM_W_LOSSES_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
        END IF;

    END LOOP;


    --Import actual NMI
    v_ACTUAL_NMI_ID := EI.GET_ID_FROM_NAME('Final Daily PJM-PE Interchange', EC.ED_TRANSACTION,1);
    IF v_ACTUAL_NMI_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_ACTUAL_NMI LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_ACTUAL_NMI_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
        END LOOP;

    ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('Final Daily PJM-PE Interchange transaction must exist to import actualNmi data.');

    END IF;



    --Import total generation
    v_METER_ID := EI.GET_ID_FROM_NAME('eMTR Total Internal Gen', EC.ED_SUB_STATION_METER,1);
    IF v_METER_ID IS NULL THEN
       LOGS.LOG_DEBUG_MORE_DETAIL('Meter eMTR Total Internal Gen must exist to import meter volume data.');
    END IF;

    v_TOTAL_GEN_ID := EI.GET_ID_FROM_NAME('TOTAL_GEN', EC.ED_TRANSACTION,1);
    IF v_TOTAL_GEN_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_TOTAL_GEN LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_TOTAL_GEN_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
             ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_TOTAL_GEN_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
            IF v_METER_ID IS NOT NULL THEN
                PUT_METER_VALUE (v_METER_ID, v_METER_VALUE.END_DATE, v_METER_VALUE.LOAD_AMOUNT);
            END IF;
        END LOOP;
    ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('TOTAL_GEN transaction must exist to import totalInternalGen data.');

    END IF;
END IMPORT_LOAD_SUBMISSION_DTL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EOM_LOAD_WITH_LOSSES
    (
   p_XML           IN XMLTYPE,
   p_PROCESS_STATUS     OUT NUMBER,
   p_MESSAGE            OUT VARCHAR2
    )AS

v_EOM_W_LOSSES_ID NUMBER;

CURSOR c_LOAD_W_LOSSES IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//loadWithLosses/intervalValue'))) W
    ORDER BY END_DATE;

BEGIN
    p_MESSAGE := NULL;
    v_EOM_W_LOSSES_ID := EI.GET_ID_FROM_NAME('Final EOM eMTR Load With Losses', EC.ED_TRANSACTION,1);

    IF v_EOM_W_LOSSES_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_LOAD_W_LOSSES LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_EOM_W_LOSSES_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
        END LOOP;
    ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('Final EOM eMTR Load With Losses transaction must exist to import loadWithLosses data.');
    END IF;

END IMPORT_EOM_LOAD_WITH_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FINAL_ZONE_LOAD
   (
   p_XML           IN XMLTYPE,
   p_PROCESS_STATUS     OUT NUMBER,
   p_MESSAGE            OUT VARCHAR2
   )AS

v_LOAD_WO_LOSSES_ID NUMBER;
v_DAILY_W_LOSSES_ID NUMBER;
v_ACTUAL_NMI_ID NUMBER;
v_COUNT PLS_INTEGER := 0;

CURSOR c_LOAD_WO_LOSSES IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//loadWithoutLosses/intervalValue'))) W
    ORDER BY END_DATE;

CURSOR c_LOAD_W_LOSSES IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(V), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(V), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(V), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'//loadWithLosses/intervalValue')))V
    ORDER BY END_DATE;

CURSOR c_ACTUAL_NMI IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//actualNmi/intervalValue'))) W
    ORDER BY END_DATE;

BEGIN
    p_MESSAGE := NULL;

    --Import without losses
    v_LOAD_WO_LOSSES_ID := EI.GET_ID_FROM_NAME('Final Daily eMTR Load Without Losses', EC.ED_TRANSACTION,1);
    IF v_LOAD_WO_LOSSES_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_LOAD_WO_LOSSES LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_LOAD_WO_LOSSES_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
        END LOOP;
    ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('Final Daily eMTR Load Without Losses transaction must exist to import loadWithoutLosses data.');

    END IF;


   --Import with losses
    v_DAILY_W_LOSSES_ID := EI.GET_ID_FROM_NAME('Final Daily eMTR Load With Losses', EC.ED_TRANSACTION,1);
    IF v_DAILY_W_LOSSES_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_LOAD_W_LOSSES LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_DAILY_W_LOSSES_ID,
                                        p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                        p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                        p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                        p_AS_OF_DATE => CONSTANTS.LOW_DATE,
                                        p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                        p_PRICE => NULL,
                                        p_STATUS => p_PROCESS_STATUS);
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_DAILY_W_LOSSES_ID,
                                        p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                        p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                        p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                        p_AS_OF_DATE => CONSTANTS.LOW_DATE,
                                        p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                        p_PRICE => NULL,
                                        p_STATUS => p_PROCESS_STATUS);                                        
            IF p_PROCESS_STATUS = 0 THEN
               v_COUNT := v_COUNT + 1;
            ELSE
               LOGS.LOG_ERROR('ITJ.PUT_IT_SCHEDULE Non-Zero Return Status: ' || TO_CHAR(p_PROCESS_STATUS) || '.');
            END IF;                                        
        END LOOP;
    ELSE
         LOGS.LOG_DEBUG_MORE_DETAIL('Final Daily eMTR Load With Losses transaction must exist to import loadWithLosses data.');
    END IF;
    LOGS.LOG_INFO('Records Processed: '||TO_CHAR(v_COUNT));

    --Import actual NMI
    v_ACTUAL_NMI_ID := EI.GET_ID_FROM_NAME('Final Daily PJM-PE Interchange', EC.ED_TRANSACTION,1);
    IF v_ACTUAL_NMI_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_ACTUAL_NMI LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_ACTUAL_NMI_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
        END LOOP;

    ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('Final Daily PJM-PE Interchange transaction must exist to import actualNmi data.');
    END IF;

END IMPORT_FINAL_ZONE_LOAD;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TOTAL_GENERATION
    (
   p_XML           IN XMLTYPE,
   p_PROCESS_STATUS     OUT NUMBER,
   p_MESSAGE            OUT VARCHAR2
    )AS

v_TOTAL_GEN_ID NUMBER;
v_METER_ID NUMBER;

CURSOR c_TOTAL_GEN IS
    SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "START_DATE",
        DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "END_DATE",
        EXTRACTVALUE(VALUE(W), '//mw') "LOAD_AMOUNT"
    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'LoadSubmissionDetails')))V,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//totalInternalGen/intervalValue'))) W
    ORDER BY END_DATE;


BEGIN
    p_MESSAGE := NULL;

    --Import total generation
    v_METER_ID := EI.GET_ID_FROM_NAME('eMTR Total Internal Gen', EC.ED_SUB_STATION_METER,1);
    IF v_METER_ID IS NULL THEN
       LOGS.LOG_DEBUG_MORE_DETAIL('Meter eMTR Total Internal Gen must exist to import meter volume data.');
    END IF;

    v_TOTAL_GEN_ID := EI.GET_ID_FROM_NAME('TOTAL_GEN', EC.ED_TRANSACTION,1);
    IF v_TOTAL_GEN_ID IS NOT NULL THEN
        FOR v_METER_VALUE IN c_TOTAL_GEN LOOP
            ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_TOTAL_GEN_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
             ITJ.PUT_IT_SCHEDULE( p_TRANSACTION_ID => v_TOTAL_GEN_ID,
                                    p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                    p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                    p_SCHEDULE_DATE => v_METER_VALUE.END_DATE,
                                    p_AS_OF_DATE => LOW_DATE,
                                    p_AMOUNT => v_METER_VALUE.LOAD_AMOUNT,
                                    p_PRICE => NULL,
                                    p_STATUS => p_PROCESS_STATUS);
            IF v_METER_ID IS NOT NULL THEN
                PUT_METER_VALUE (v_METER_ID, v_METER_VALUE.END_DATE, v_METER_VALUE.LOAD_AMOUNT);
            END IF;
        END LOOP;
    ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('TOTAL_GEN transaction must exist to import totalInternalGen data.');

    END IF;

END IMPORT_TOTAL_GENERATION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_500KV_LOSSES
  (
    p_XML XMLTYPE,
    p_STATUS IN OUT NUMBER,
    p_MESSAGE IN OUT VARCHAR2
    ) AS

v_TXN_ID_INADV NUMBER(9);
v_COUNT PLS_INTEGER := 0;
CURSOR c_INADVERT_METER_VALUES IS
  SELECT DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//startDate')) "INADVERT_BEGIN_DATE",
    DATE_UTIL.TO_CUT_DATE_FROM_ISO(EXTRACTVALUE(VALUE(W), '//endDate')) "INADVERT_END_DATE",
    EXTRACTVALUE(VALUE(V), '//ehvAreaName') "ENTITY_NAME",
    EXTRACTVALUE(VALUE(W), '//intervalValue/mw') "INADVERT_AMOUNT"
  FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML,'//shareLosses'))) V,
    TABLE(XMLSEQUENCE(EXTRACT(VALUE(V),'//area/intervalValues/intervalValue'))) W;

BEGIN

  FOR v_METER_VALUE IN c_INADVERT_METER_VALUES LOOP
      v_TXN_ID_INADV := EI.GET_ID_FROM_NAME('500kV Losses', EC.ED_TRANSACTION,1);
      IF v_TXN_ID_INADV IS NOT NULL THEN
        ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID_INADV,
                             p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                             p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                             p_SCHEDULE_DATE => v_METER_VALUE.INADVERT_END_DATE,
                             p_AS_OF_DATE => LOW_DATE,
                             p_AMOUNT => v_METER_VALUE.INADVERT_AMOUNT,
                             p_PRICE => NULL,
                             p_STATUS => p_STATUS);
         IF p_STATUS = 0 THEN
            v_COUNT := v_COUNT + 1;
--@@Begin Implementation Override--
--@@Store 500KV Losses As External--           
           ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID_INADV,
                                p_SCHEDULE_TYPE => GA.SCHEDULE_TYPE_FINAL,
                                p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
                                p_SCHEDULE_DATE => v_METER_VALUE.INADVERT_END_DATE,
                                p_AS_OF_DATE => LOW_DATE,
                                p_AMOUNT => v_METER_VALUE.INADVERT_AMOUNT,
                                p_PRICE => NULL,
                                p_STATUS => p_STATUS);
--@@End Implementation Override--
         ELSE
            LOGS.LOG_ERROR('ITJ.PUT_IT_SCHEDULE Non-Zero Return Status: ' || TO_CHAR(p_STATUS) || '.');
         END IF;                                     
      ELSE
        LOGS.LOG_DEBUG_MORE_DETAIL('500kV Losses transaction must exist to import shareLosses data.');
        EXIT;
      END IF;
  END LOOP;
  LOGS.LOG_INFO('Records Processed: '||to_char(v_COUNT));
  p_STATUS := GA.SUCCESS;

EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := UT.GET_FULL_ERRM;

END IMPORT_500KV_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_POWERMETER
   (
   p_IMPORT_FILE      IN CLOB,
   p_IMPORT_FILE_PATH IN VARCHAR2,
   p_EXCHANGE_TYPE    IN VARCHAR2,
   p_TRACE_ON         IN NUMBER,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   ) AS

v_FILE_NAME VARCHAR2(64);
v_IMPORT_TYPE VARCHAR2(512);
v_XML XMLTYPE;

BEGIN
    LOGS.LOG_INFO('Import PJM Power Meter');
    v_FILE_NAME := PARSE_UTIL.FILE_NAME_FROM_PATH(p_FILE_PATH => p_IMPORT_FILE_PATH);
    BEGIN
        v_XML := PARSE_UTIL.CREATE_XML_SAFE(p_IMPORT_FILE);
        v_IMPORT_TYPE  := v_XML.getRootElement();
    EXCEPTION
        WHEN OTHERS THEN
        p_MESSAGE := p_MESSAGE ||'Invalid XML in file '||v_FILE_NAME || '.';
        ERRS.LOG_AND_RAISE(p_MESSAGE, LOGS.c_LEVEL_FATAL);
    END;
    LOGS.LOG_INFO('Import Type '||v_IMPORT_TYPE);
    CASE v_IMPORT_TYPE
        WHEN 'LoadSubmissionDetails' THEN
            CASE p_EXCHANGE_TYPE
                WHEN 'Import Power Meter File' THEN
                    IMPORT_LOAD_SUBMISSION_DTL(v_XML, p_STATUS, p_MESSAGE);
                WHEN 'Query Submissions' THEN
                    IMPORT_LOAD_SUBMISSION_DTL(v_XML, p_STATUS, p_MESSAGE);
                WHEN 'Query EOM Load With Losses' THEN
                    IMPORT_EOM_LOAD_WITH_LOSSES(v_XML, p_STATUS, p_MESSAGE);
                WHEN 'Query Final Zone Load' THEN
                    IMPORT_FINAL_ZONE_LOAD(v_XML, p_STATUS, p_MESSAGE);
                WHEN 'Query Total Generation' THEN
                    IMPORT_TOTAL_GENERATION(v_XML, p_STATUS, p_MESSAGE);
            END CASE;
        WHEN 'MeterValues' THEN
            IMPORT_XML(v_XML, p_STATUS, p_MESSAGE);
        WHEN 'MeterValueAllocation' THEN
            CASE p_EXCHANGE_TYPE
                WHEN 'Import Power Meter File' THEN
                    IMPORT_ALLOCATED_METER_VALUES(v_XML, p_STATUS, p_MESSAGE);
                WHEN 'Query Allocations' THEN
                    IMPORT_ALLOCATED_METER_VALUES(v_XML, p_STATUS, p_MESSAGE);
                WHEN 'Query 500kV Losses' THEN
                    IMPORT_500KV_LOSSES(v_XML, p_STATUS, p_MESSAGE);
            END CASE;
        ELSE
           p_MESSAGE := p_MESSAGE ||'Unable to recognize file '||v_FILE_NAME || ' as Power Meter XML.';
           LOGS.LOG_FATAL(p_MESSAGE);
    END CASE;
    LOGS.LOG_INFO('Import PJM Power Meter Complete');
EXCEPTION
    WHEN OTHERS THEN
        p_MESSAGE := 'Power Meter import failed. ' || p_MESSAGE;
        LOGS.LOG_FATAL(p_MESSAGE);
        LOGS.STOP_PROCESS(p_MESSAGE, p_STATUS);

END IMPORT_POWERMETER;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_POWERMETER
    (
    p_BEGIN_DATE                IN DATE,
    p_END_DATE                  IN DATE,
    p_EXCHANGE_TYPE             IN VARCHAR2,
    p_LOG_ONLY                  IN NUMBER :=0,
    p_LOG_TYPE                  IN NUMBER,
    p_TRACE_ON                  IN NUMBER,
    p_STATUS                    OUT NUMBER,
    p_MESSAGE                   OUT VARCHAR2) AS

    v_CREDS         MM_CREDENTIALS_SET;
    v_CRED          MEX_CREDENTIALS;
    v_LOGGER        MM_LOGGER_ADAPTER;
    v_LOG_ONLY      NUMBER;
    v_EMTR_ACCESS_ATTR_ID NUMBER(9);
    v_REQUEST_APP VARCHAR2(32);
    v_RESP_STRING CLOB := NULL;
    v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
    v_CURRENT_DAY DATE := TRUNC(p_BEGIN_DATE);

BEGIN
    p_STATUS := GA.SUCCESS;
    v_LOG_ONLY := NVL(p_LOG_ONLY,0);

    MM_UTIL.INIT_MEX(EC.ES_PJM,
                         'PJM:eMTR: ' || P_Exchange_Type, --@@Implementation Override --
                         p_EXCHANGE_TYPE,
                         p_LOG_TYPE,
                         p_TRACE_ON,
                         v_CREDS,
                         v_LOGGER);
    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);
    
    LOGS.SET_PROCESS_TARGET_PARAMETER('BEGIN_DATE', TO_CHAR(p_BEGIN_DATE,'yyyy-mm-dd'));
    LOGS.SET_PROCESS_TARGET_PARAMETER('END_DATE', TO_CHAR(p_END_DATE,'yyyy-mm-dd'));
    
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMTR', EC.ED_INTERCHANGE_CONTRACT, 'String', FALSE, v_EMTR_ACCESS_ATTR_ID);
    v_CURRENT_DAY := TRUNC(p_BEGIN_DATE);

    --Set params
    CASE p_EXCHANGE_TYPE
    WHEN 'Query Meter Values' THEN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'metervalues';
    WHEN 'Query Allocations' THEN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'allocations';
    WHEN 'Query 500kV Losses' THEN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'allocations';
    WHEN 'Query Submissions' THEN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'submissions';
    WHEN 'Query EOM Load With Losses' THEN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'submissions';
    WHEN 'Query Final Zone Load' THEN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'submissions';
    WHEN 'Query Total Generation' THEN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'submissions';
    ELSE
        p_STATUS := -1;
        p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
        v_LOGGER.LOG_ERROR(p_MESSAGE);
    END CASE;
    v_PARAMS(MEX_PJM.c_ACTION) := 'download';

    --Are we connecting to the sandbox? -- KN 11/2/2020: This is checked in MEX_PJM package.
    IF(NVL(GET_DICTIONARY_VALUE('Sandbox',0,'MarketExchange','PJM','Browserless', 'powermeter'),0)) = 1
        THEN v_REQUEST_APP := 'powermetersandbox';
    ELSE v_REQUEST_APP := 'powermeter';
    END IF;

    WHILE v_CREDS.HAS_NEXT LOOP
        v_CRED    := v_CREDS.GET_NEXT;
        IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(v_EMTR_ACCESS_ATTR_ID, v_CRED.EXTERNAL_ACCOUNT_NAME) THEN
            WHILE v_CURRENT_DAY <= TRUNC(p_END_DATE) LOOP
            MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                                    v_REQUEST_APP,
                                    v_LOGGER,
                                    v_CRED,
                                    v_CURRENT_DAY,
                                    v_CURRENT_DAY,
                                    'download',
                                    v_RESP_STRING,
                                    p_STATUS,
                                    p_MESSAGE,
                                    p_LOG_ONLY );
                IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
                    IMPORT_POWERMETER(v_RESP_STRING,
                                                p_EXCHANGE_TYPE,
                                                p_EXCHANGE_TYPE,
                                                p_TRACE_ON,
                                                p_STATUS,
                                                p_MESSAGE);
                END IF;
                IF NOT v_RESP_STRING IS NULL THEN
                    DBMS_LOB.FREETEMPORARY(v_RESP_STRING);
                END IF;
                v_CURRENT_DAY := v_CURRENT_DAY + 1;
            END LOOP;
        END IF;
    END LOOP;
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS := SQLCODE;
        p_MESSAGE := UT.GET_FULL_ERRM;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END QUERY_POWERMETER;
----------------------------------------------------------------------------------------------------
BEGIN
  g_INADVERTENT_CONTROL_AREA := NVL(GET_DICTIONARY_VALUE('Control Area Name',1,'MarketExchange','PJM','eMTR'), 'CE');
  g_INADVERTENT_OWNER := NVL(GET_DICTIONARY_VALUE('Owner Name',1,'MarketExchange','PJM','eMTR'), 'ComEd');
END MM_PJM_POWERMETER;
/
