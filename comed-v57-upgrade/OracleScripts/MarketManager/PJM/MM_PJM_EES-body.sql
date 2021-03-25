create or replace package body MM_PJM_EES is

  g_PARAMETER_MAP MEX_Util.PARAMETER_MAP;
  g_TIME_ZONE CONSTANT 			 VARCHAR2(3)  := 'EST';

---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;

---------------------------------------------------------------------------------------------------

FUNCTION GET_TRANSACTION_NAME(p_TRANSACTION_ID IN NUMBER) RETURN VARCHAR2 IS
	v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
BEGIN
	SELECT T.TRANSACTION_NAME
		INTO v_TRANSACTION_NAME
		FROM INTERCHANGE_TRANSACTION T
	 WHERE T.TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN v_TRANSACTION_NAME;
END;

----------------------------------------------------------------------------------------------------

FUNCTION GET_TRANSACTION_PATH(p_TRANSACTION_ID IN NUMBER) RETURN VARCHAR2 IS
	v_CA_POR_NAME CONTROL_AREA.CA_NAME%TYPE;
	v_CA_POD_NAME CONTROL_AREA.CA_NAME%TYPE;
	v_PATH        CONTROL_AREA.CA_NAME%TYPE;
BEGIN
	SELECT CA_POR.CA_NAME, CA_POD.CA_NAME
		INTO v_CA_POR_NAME, v_CA_POD_NAME
		FROM SERVICE_POINT           POR,
				 SERVICE_POINT           POD,
				 CONTROL_AREA            CA_POR,
				 CONTROL_AREA            CA_POD,
				 INTERCHANGE_TRANSACTION ITS
	 WHERE ITS.TRANSACTION_ID = p_TRANSACTION_ID
		 AND ITS.POR_ID = POR.SERVICE_POINT_ID
		 AND ITS.POD_ID = POD.SERVICE_POINT_ID
		 AND POR.CA_ID = CA_POR.CA_ID
		 AND POD.CA_ID = CA_POD.CA_ID;

	IF v_CA_POD_NAME != 'PJM' AND v_CA_POR_NAME != 'PJM' THEN
		-- wheel-through
		v_PATH := v_CA_POR_NAME || '-PJM-' || v_CA_POD_NAME;
	ELSE
		v_PATH := v_CA_POR_NAME || '-' || v_CA_POD_NAME;
	END IF;
	RETURN v_PATH;
EXCEPTION
	WHEN OTHERS THEN
		-- likely data misconfigured, where POD or POR don't have control areas
		v_PATH := NULL;
		RETURN v_PATH;
		-- LOG SOMETHING HERE!!!!
END;

----------------------------------------------------------------------------------------------------

PROCEDURE SUBMIT_RAMP_RESERVATION
	(
	p_CRED		   IN mex_credentials,
	pTransactionID IN NUMBER,
	pStartDate     IN DATE,
	pEndDate       IN DATE,
	p_LOG_ONLY	   IN NUMBER,
	p_STATUS       OUT NUMBER,
	p_MESSAGE      OUT VARCHAR2,
	p_LOGGER	   IN OUT mm_logger_adapter
	) IS

	CURSOR cSchedule IS
		SELECT ITS.SCHEDULE_DATE, ITS.AMOUNT, ITS.PRICE
			FROM IT_SCHEDULE ITS
		 WHERE ITS.TRANSACTION_ID = pTransactionID
			 AND ITS.SCHEDULE_TYPE = 1
			 AND ITS.SCHEDULE_STATE = 1
			 AND ITS.SCHEDULE_DATE BETWEEN pStartDate AND pEndDate + 1 / 24;
	scheduleRecord MEX_PJM_SPARSE_PROFILE;
	scheduleTable  MEX_PJM_SPARSE_PROFILE_TBL := MEX_PJM_SPARSE_PROFILE_TBL();

	bAddRecord  BOOLEAN := FALSE;
	v_RECORDS   MEX_PJM_EES_RAMPRES_TBL;

BEGIN
	p_STATUS    := GA.SUCCESS;

	-- get the sparse schedule data for this transaction
	FOR rec IN cSchedule LOOP
		bAddRecord := FALSE;
		-- first record always gets added, then any time the price or quantity change
		IF scheduleTable.COUNT = 0 THEN
			bAddRecord := TRUE;
		ELSIF rec.amount != scheduleRecord.QUANTITY OR rec.price != scheduleRecord.PRICE THEN
			bAddRecord := TRUE;
		END IF;

		IF bAddRecord = TRUE THEN
			-- update the previous row's stop date with the current schedule date
			IF scheduleTable.COUNT > 0 THEN
				scheduleTable(scheduleTable.LAST).BEGIN_DATE := rec.SCHEDULE_DATE - 1 / 24;
			END IF;
			scheduleRecord := MEX_PJM_SPARSE_PROFILE(BEGIN_DATE => rec.SCHEDULE_DATE,
												END_DATE   => rec.SCHEDULE_DATE,
												QUANTITY   => rec.AMOUNT,
												PRICE      => rec.PRICE);
			scheduleTable.EXTEND;
			scheduleTable(scheduleTable.LAST) := scheduleRecord;
		END IF;
	END LOOP;
	-- update the last record with the correct stop date
	scheduleTable(scheduleTable.LAST).END_DATE := pEndDate;

	v_RECORDS := MEX_PJM_EES_RAMPRES_TBL();
	v_RECORDS.EXTEND();
	v_RECORDS(v_RECORDS.LAST()) := MEX_PJM_EES_RAMPRES(PJM_ID           => NULL,
			RESERVATION_NAME => GET_TRANSACTION_NAME(pTransactionID),
			OUTSIDE_ID       => NULL,
			PATH             => GET_TRANSACTION_PATH(pTransactionID),
			REALTIME_PROFILE => scheduleTable);


	MEX_PJM_EES.SUBMIT_TAG_RESERVATION(g_PARAMETER_MAP, pStartDate, pEndDate, v_RECORDS, p_LOGGER,p_CRED, 1, p_STATUS, p_MESSAGE);
	IF p_STATUS >= 0 THEN
		NULL; -- IMPORT_PORTFOLIOS(v_RECORDS, p_STATUS, p_MESSAGE);
	END IF;


EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := 'ERROR OCCURED IN MM_PJM_EES.SUBMIT_RAMP_RESERVATION: ' || SQLERRM;
		p_STATUS  := SQLCODE;
END SUBMIT_RAMP_RESERVATION;
----------------------------------------------------------------------------------------------------
FUNCTION GET_PJM_SC_ID RETURN NUMBER IS
BEGIN
  RETURN ID.ID_FOR_SC('PJM');
END GET_PJM_SC_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_COMMODITY_ID RETURN NUMBER IS
BEGIN
	RETURN MM_PJM_UTIL.GET_COMMODITY_ID(MM_PJM_UTIL.g_COMM_RT_ENERGY);
END GET_COMMODITY_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_TXN_ID_FROM_ETAG_CODE
	(
	p_ETAG_CODE IN VARCHAR2,
	p_TXN_IDENT IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CONTRACT_ID IN NUMBER,
	p_COMMODITY_ID IN NUMBER,
	p_SC_ID IN NUMBER,
	p_ISO_ACCT_NAME IN VARCHAR2,
	p_TRANSACTION_ID OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

 v_TXN_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
 v_TXN_ALIAS INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS%TYPE;


BEGIN

  --Try to find the transanction
  SELECT TRANSACTION_ID
    INTO p_TRANSACTION_ID
    FROM INTERCHANGE_TRANSACTION
   WHERE ETAG_CODE = p_ETAG_CODE
     AND CONTRACT_ID = p_CONTRACT_ID
     AND TRANSACTION_IDENTIFIER = p_TXN_IDENT;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    --Create transaction name as:  <ISO_ACCT_NAME>:<ETAG_ID>
    v_TXN_NAME := p_ISO_ACCT_NAME || ':' || p_ETAG_CODE;
    --Alias is first 32 chars
    v_TXN_ALIAS:= SUBSTR(v_TXN_NAME,1,32);

    --Create the transaction
    EM.PUT_TRANSACTION(p_TRANSACTION_ID, -- o_oid
                       v_TXN_NAME, -- p_transaction_name
                       v_TXN_ALIAS, -- p_transaction_alias
                       'Transaction created by MarketManager via EES/Tag-Resevation report', -- p_transaction_desc
                       0, -- p_transaction_id
					   'Active', -- p_transaction_Status
                       'Purchase', -- p_transaction_type
                       p_TXN_IDENT, -- p_transaction_identifier
                       0, -- p_is_firm
                       0, -- p_is_import_schedule
                       0, -- p_is_export_schedule
                       0, -- p_is_balance_transaction
                       1, -- p_is_bid_offer
                       0, -- p_is_exclude_from_position
                       1, -- p_is_import_export
                       0, -- p_is_dispatchable
                       'Hour', -- p_transaction_interval
                       'Hour', -- p_external_interval
                       p_ETAG_CODE, -- p_etag_code
                       p_BEGIN_DATE, -- p_begin_date
                       p_END_DATE, -- p_end_date
                       0, -- p_purchaser_id
                       0, -- p_seller_id
                       p_CONTRACT_ID, -- p_contract_id
                       p_SC_ID, -- p_sc_id
                       0, -- p_por_id
                       0, -- p_pod_id
                       p_COMMODITY_ID, -- p_commodity_id
                       0, -- p_service_type_id
                       0, -- p_tx_transaction_id
                       0, -- p_path_id
                       0, -- p_link_transaction_id
                       0, -- p_edc_id
                       0, -- p_pse_id
                       0, -- p_esp_id
                       0, -- p_pool_id
                       0, -- p_schedule_group_id
                       0, -- p_market_price_id
                       0, -- p_zor_id
                       0, -- p_zod_id
                       0, -- p_source_id
                       0, -- p_sink_id
                       0, -- p_resource_id
                       NULL, -- p_agreement_type
                       NULL, -- p_approval_type
                       NULL, -- p_loss_option
                       NULL, -- p_trait_category
                       0 -- p_tp_id
                       );

  WHEN OTHERS THEN
    RAISE;
END GET_TXN_ID_FROM_ETAG_CODE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_TXN_ID_FROM_EXT_IDENT
	(
	p_EXT_IDENTIFIER IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CONTRACT_ID IN NUMBER,
	p_COMMODITY_ID IN NUMBER,
	p_SC_ID IN NUMBER,
	p_TRANSACTION_ID OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

BEGIN

  --Try to find the transanction
  SELECT TRANSACTION_ID
    INTO p_TRANSACTION_ID
    FROM INTERCHANGE_TRANSACTION
   WHERE TRANSACTION_IDENTIFIER = p_EXT_IDENTIFIER
     AND CONTRACT_ID = p_CONTRACT_ID;

EXCEPTION
  WHEN NO_DATA_FOUND THEN

    --Create the transaction
    EM.PUT_TRANSACTION(p_TRANSACTION_ID, -- o_oid
                       '?', -- p_transaction_name
                       '?', -- p_transaction_alias
                       'Transaction created by MarketManager via EES/Two Settlement report', -- p_transaction_desc
                       0, -- p_transaction_id
					   'Active', -- p_transaction_status
                       'Purchase', -- p_transaction_type
                       p_EXT_IDENTIFIER, -- p_transaction_identifier
                       0, -- p_is_firm
                       0, -- p_is_import_schedule
                       0, -- p_is_export_schedule
                       0, -- p_is_balance_transaction
                       1, -- p_is_bid_offer
                       0, -- p_is_exclude_from_position
                       1, -- p_is_import_export
                       0, -- p_is_dispatchable
                       'Hour', -- p_transaction_interval
                       'Hour', -- p_external_interval
                       0, -- p_etag_code
                       p_BEGIN_DATE, -- p_begin_date
                       p_END_DATE, -- p_end_date
                       0, -- p_purchaser_id
                       0, -- p_seller_id
                       p_CONTRACT_ID, -- p_contract_id
                       p_SC_ID, -- p_sc_id
                       0, -- p_por_id
                       0, -- p_pod_id
                       p_COMMODITY_ID, -- p_commodity_id
                       0, -- p_service_type_id
                       0, -- p_tx_transaction_id
                       0, -- p_path_id
                       0, -- p_link_transaction_id
                       0, -- p_edc_id
                       0, -- p_pse_id
                       0, -- p_esp_id
                       0, -- p_pool_id
                       0, -- p_schedule_group_id
                       0, -- p_market_price_id
                       0, -- p_zor_id
                       0, -- p_zod_id
                       0, -- p_source_id
                       0, -- p_sink_id
                       0, -- p_resource_id
                       NULL, -- p_agreement_type
                       NULL, -- p_approval_type
                       NULL, -- p_loss_option
                       NULL, -- p_trait_category
                       0 -- p_tp_id
                       );

  WHEN OTHERS THEN
    RAISE;
END GET_TXN_ID_FROM_EXT_IDENT;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_RESERVATION_DATA
	(
	p_RECORDS IN MEX_PJM_EES_TAGRES_TBL,
	p_CONTRACT_ID IN NUMBER,
	p_ISO_ACCT_NAME IN VARCHAR2,
	p_COPY_INTERNAL IN BOOLEAN,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

  v_REC            MEX_PJM_EES_TAGRES;
  i                BINARY_INTEGER;
  v_TRANSACTION_ID NUMBER(9);
  v_COMMODITY_ID   NUMBER(9) := GET_COMMODITY_ID;
  v_SC_ID          NUMBER(9) := GET_PJM_SC_ID;

  --v_RAMP_RES_NAME       INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE;
  v_OASIS_ATTRIBUTE_ID  NUMBER(9);
  v_ENTITY_DOMAIN_ALIAS VARCHAR2(11) := 'TRANSACTION';
  v_SCHEDULE_DATE       DATE;
  v_INTERVAL_BEGIN_DATE DATE;
  v_INTERVAL_END_DATE   DATE;

BEGIN

  P_STATUS := GA.SUCCESS;

  --Loop over each record
  FOR i IN p_RECORDS.FIRST .. p_RECORDS.LAST LOOP
    v_REC                 := p_RECORDS(i);
    v_INTERVAL_BEGIN_DATE := v_REC.startDate;
    v_INTERVAL_END_DATE   := v_REC.stopDate;

    --Get the Transaction_ID based on TAG_ID
    GET_TXN_ID_FROM_ETAG_CODE(v_REC.tagID,
                              v_REC.rampResName,
                              v_REC.startDate,
                              v_REC.stopDate,
                              p_CONTRACT_ID,
                              v_COMMODITY_ID,
                              v_SC_ID,
                              p_ISO_ACCT_NAME,
                              v_TRANSACTION_ID,
                              p_MESSAGE);

    --Create an entity-attribute based on oasis_id
    ID.ID_FOR_ENTITY_ATTRIBUTE('OASIS_ID',
                               v_ENTITY_DOMAIN_ALIAS,
                               'String',
                               TRUE,
                               v_OASIS_ATTRIBUTE_ID);

    IF NOT v_REC.oasisID IS NULL THEN
      SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID,
                                       v_OASIS_ATTRIBUTE_ID,
                                       v_REC.startDate,
                                       NULL,
                                       v_REC.oasisID,
                                       v_TRANSACTION_ID,
                                       v_OASIS_ATTRIBUTE_ID,
                                       v_REC.startDate,
                                       p_STATUS);
    END IF;

    --Save data in the BID_OFFER_STATUS table
    v_SCHEDULE_DATE := v_INTERVAL_BEGIN_DATE;
    WHILE v_SCHEDULE_DATE <= v_INTERVAL_END_DATE LOOP
      BO.PUT_BID_OFFER_SET(p_TRANSACTION_ID => v_TRANSACTION_ID,
                           p_BID_OFFER_ID   => 0,
                           p_SCHEDULE_STATE => GA.EXTERNAL_STATE, -- EXTERNAL STATE
                           p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                           p_SET_NUMBER     => 1,
                           p_PRICE          => NULL,
                           p_QUANTITY       => v_REC.actualMW,
                           p_OFFER_STATUS   => UPPER(SUBSTR(v_REC.rampResStatus,1,1)),
                           p_TIME_ZONE      => g_TIME_ZONE,
                           p_STATUS         => p_STATUS);

      IF p_COPY_INTERNAL THEN
        BO.PUT_BID_OFFER_SET(p_TRANSACTION_ID => v_TRANSACTION_ID,
                             p_BID_OFFER_ID   => 0,
                             p_SCHEDULE_STATE => GA.INTERNAL_STATE, -- INTERNAL STATE
                             p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                             p_SET_NUMBER     => 1,
                             p_PRICE          => NULL,
                             p_QUANTITY       => v_REC.actualMW,
                             p_OFFER_STATUS   => UPPER(SUBSTR(v_REC.rampResStatus,1,1)),
                             p_TIME_ZONE      => g_TIME_ZONE,
                             p_STATUS         => p_STATUS);
      END IF;

      v_SCHEDULE_DATE := v_SCHEDULE_DATE + 1 / 24;

    END LOOP;
  END LOOP;

  EXCEPTION
  WHEN OTHERS THEN
    p_MESSAGE := 'Error in MM_PJM_EES.PUT_RESERVATION_DATA: ' ||
                 SQLERRM;
    p_STATUS  := SQLCODE;

END PUT_RESERVATION_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_SETTLEMENT_DATA
	(
	p_RECORDS IN MEX_PJM_EES_TWOSETTLE_TBL,
	p_CONTRACT_ID IN NUMBER,
	p_COPY_INTERNAL IN BOOLEAN,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

  v_REC            MEX_PJM_EES_TWOSETTLE;
  i                BINARY_INTEGER;
  v_TRANSACTION_ID NUMBER(9);
  v_COMMODITY_ID   NUMBER(9) := GET_COMMODITY_ID;
  v_SC_ID          NUMBER(9) := GET_PJM_SC_ID;

  v_OASIS_ATTRIBUTE_ID  NUMBER(9);
  v_ENTITY_DOMAIN_ALIAS VARCHAR2(11) := 'TRANSACTION';
  v_SCHEDULE_DATE       DATE;
  v_INTERVAL_BEGIN_DATE DATE;
  v_INTERVAL_END_DATE   DATE;
  v_AS_OF_DATE          DATE := LOW_DATE;

BEGIN

  P_STATUS := GA.SUCCESS;

  --Loop over each record
  FOR i IN p_RECORDS.FIRST .. p_RECORDS.LAST LOOP
    v_REC                 := p_RECORDS(i);
    v_INTERVAL_BEGIN_DATE := v_REC.startDate;
    v_INTERVAL_END_DATE   := v_REC.stopDate;

    --Get the Transaction_ID based on TAG_ID
    GET_TXN_ID_FROM_EXT_IDENT(TO_CHAR(v_REC.oasisID),
                              v_REC.startDate,
                              v_REC.stopDate,
                              p_CONTRACT_ID,
                              v_COMMODITY_ID,
                              v_SC_ID,
                              v_TRANSACTION_ID,
                              p_MESSAGE);

    --Create an entity-attribute based on oasis_id
    ID.ID_FOR_ENTITY_ATTRIBUTE('OASIS_ID',
                               v_ENTITY_DOMAIN_ALIAS,
                               'String',
                               TRUE,
                               v_OASIS_ATTRIBUTE_ID);

    IF NOT v_REC.oasisID IS NULL THEN
      SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID,
                                       v_OASIS_ATTRIBUTE_ID,
                                       v_REC.startDate,
                                       NULL,
                                       v_REC.oasisID,
                                       v_TRANSACTION_ID,
                                       v_OASIS_ATTRIBUTE_ID,
                                       v_REC.startDate,
                                       p_STATUS);
    END IF;

    --Save data in the IT_SCHEDULE table
    v_SCHEDULE_DATE := v_INTERVAL_BEGIN_DATE;

    WHILE v_SCHEDULE_DATE <= v_INTERVAL_END_DATE LOOP
      --data gets copied into IT_SCHEDULE table only if MW have cleared
      IF NOT v_REC.clearedMW IS NULL THEN
        -- Always put with external state
        ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                           GA.SCHEDULE_TYPE_FORECAST,
                           GA.EXTERNAL_STATE,
                           v_SCHEDULE_DATE,
                           v_AS_OF_DATE,
                           v_REC.clearedMW,
                           NULL,
                           P_STATUS);

        IF p_COPY_INTERNAL THEN
          --put with internal state
          ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TRANSACTION_ID,
                             p_SCHEDULE_TYPE  => GA.SCHEDULE_TYPE_FORECAST,
                             p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                             p_AS_OF_DATE     => v_AS_OF_DATE,
                             p_AMOUNT         => v_REC.clearedMW,
                             p_PRICE          => NULL,
                             p_STATUS         => p_STATUS);
        END IF;
      END IF;

      v_SCHEDULE_DATE := v_SCHEDULE_DATE + 1 / 24;

    END LOOP;
  END LOOP;

  EXCEPTION
  WHEN OTHERS THEN
    p_MESSAGE := 'Error in MM_PJM_EES.PUT_SETTLEMENT_DATA: ' ||
                 SQLERRM;
    p_STATUS  := SQLCODE;

END PUT_SETTLEMENT_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_RESERVATION_REPORTS
	(
	p_CRED	IN mex_credentials,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_COPY_INTERNAL IN BOOLEAN,
	p_LOG_ONLY IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
	) AS

  v_RECORDS     MEX_PJM_EES_TAGRES_TBL;

  v_CONTRACT_ID INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;
  v_PROCESS_NAME VARCHAR2(70);
BEGIN
	IF p_COPY_INTERNAL THEN
       v_PROCESS_NAME := 'Query Reservation To Internal';
  	ELSE
       v_PROCESS_NAME := 'Query Reservation';
  	END IF;

	p_LOGGER.EXCHANGE_NAME := v_PROCESS_NAME;
	MEX_PJM_EES.FETCH_TAG_RES_REPORT(p_BEGIN_DATE => p_BEGIN_DATE,
								 p_END_DATE   => p_END_DATE,
								 p_LOGGER => p_LOGGER,
								 p_CRED => p_CRED,
								 p_LOG_ONLY => p_LOG_ONLY,
								 p_RECORDS    => v_RECORDS,
								 p_STATUS     => p_STATUS,
								 p_MESSAGE    => p_MESSAGE);

	IF p_STATUS = MEX_SWITCHBOARD.c_Status_Success THEN
		--Get contract_id based on external credentials
		v_CONTRACT_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_ENTITY_IDENTIFIER =>
				 p_CRED.EXTERNAL_ACCOUNT_NAME,
				 p_ENTITY_DOMAIN_ID => EC.ED_INTERCHANGE_CONTRACT,
				 p_EXTERNAL_SYSTEM_ID => EC.ES_PJM);
		--Save report data into Bid_Offer_Status table
		PUT_RESERVATION_DATA(v_RECORDS,
					   v_CONTRACT_ID,
					   p_CRED.EXTERNAL_ACCOUNT_NAME,
					   p_COPY_INTERNAL,
					   p_STATUS,
					   p_MESSAGE);

	END IF;

EXCEPTION
  WHEN OTHERS THEN
    p_MESSAGE := 'Error in MM_PJM_EES.IMPORT_RESERVATION_REPORTS: ' || SQLERRM;
    p_STATUS  := SQLCODE;

END IMPORT_RESERVATION_REPORTS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TWO_SETTLEMENT_REPORTS
	(
	p_CRED IN mex_credentials,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_COPY_INTERNAL IN BOOLEAN,
	p_LOG_ONLY IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR,
	p_LOGGER IN OUT mm_logger_adapter
	) AS

  v_RECORDS     MEX_PJM_EES_TWOSETTLE_TBL;
  v_CONTRACT_ID INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;
  v_PROCESS_NAME VARCHAR2(70);
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
  	IF p_COPY_INTERNAL THEN
       v_PROCESS_NAME := 'Query Two Settlement To Internal';
  	ELSE
       v_PROCESS_NAME := 'Query Two Settlement';
  	END IF;

	p_LOGGER.EXCHANGE_NAME := v_PROCESS_NAME;

	MEX_PJM_EES.FETCH_TWO_SETTLEMENT_REPORT(p_BEGIN_DATE => p_BEGIN_DATE,
				p_END_DATE   => p_END_DATE,
				p_LOGGER => p_LOGGER,
				p_CRED => p_CRED,
				p_LOG_ONLY => p_LOG_ONLY,
				p_RECORDS    => v_RECORDS,
				p_STATUS     => p_STATUS,
				p_MESSAGE    => p_MESSAGE);

	IF p_STATUS = MEX_SWITCHBOARD.c_Status_Success THEN
		v_CONTRACT_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_ENTITY_IDENTIFIER =>
				 p_CRED.EXTERNAL_ACCOUNT_NAME,
				 p_ENTITY_DOMAIN_ID => EC.ED_INTERCHANGE_CONTRACT,
				 p_EXTERNAL_SYSTEM_ID => EC.ES_PJM);      --Save report
	--Save report data into Bid_Offer_Status table
	PUT_SETTLEMENT_DATA(v_RECORDS,
					  v_CONTRACT_ID,
					  p_COPY_INTERNAL,
					  p_STATUS,
					  p_MESSAGE);
	END IF;

EXCEPTION
  WHEN OTHERS THEN
    p_MESSAGE := 'Error in MM_PJM_EES.IMPORT_TWO_SETTLEMENT_REPORTS: ' ||
                 SQLERRM;
    p_STATUS  := SQLCODE;

END IMPORT_TWO_SETTLEMENT_REPORTS;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER := 0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

  v_CREDS         MM_CREDENTIALS_SET;
  v_CRED          MEX_CREDENTIALS;
  v_LOGGER        MM_LOGGER_ADAPTER;
  v_LOG_ONLY	  NUMBER;
BEGIN
    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
	v_LOG_ONLY := NVL(p_LOG_ONLY, 0);

	MM_UTIL.INIT_MEX(EC.ES_PJM,
                         'PJM:EES',
                         p_EXCHANGE_TYPE,
                         p_LOG_TYPE,
                         p_TRACE_ON,
                         v_CREDS,
                         v_LOGGER);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	WHILE v_CREDS.HAS_NEXT LOOP
		v_CRED := v_CREDS.GET_NEXT;

		  IF UPPER(p_EXCHANGE_TYPE) = UPPER(g_ET_QUERY_TWO_SETTLEMENT) THEN
			IMPORT_TWO_SETTLEMENT_REPORTS(v_CRED,
										  p_BEGIN_DATE,
										  p_END_DATE,
										  FALSE,
										  v_LOG_ONLY,
										  p_STATUS,
										  p_MESSAGE,
										  v_LOGGER);

		  ELSIF UPPER(p_EXCHANGE_TYPE) = UPPER(g_ET_QUERY_TWO_SETTL_TO_INTERN) THEN
			IMPORT_TWO_SETTLEMENT_REPORTS(v_CRED,
										  p_BEGIN_DATE,
										  p_END_DATE,
										  TRUE,
										  v_LOG_ONLY,
										  p_STATUS,
										  p_MESSAGE,
										  v_LOGGER);

		  ELSIF UPPER(p_EXCHANGE_TYPE) = UPPER(g_ET_QUERY_RESERVATION) THEN
			IMPORT_RESERVATION_REPORTS(v_CRED,
									   p_BEGIN_DATE,
									   p_END_DATE,
									   FALSE,
									   v_LOG_ONLY,
									   p_STATUS,
									   p_MESSAGE,
									   v_LOGGER);

		  ELSIF UPPER(p_EXCHANGE_TYPE) = UPPER(g_ET_QUERY_RESERV_TO_INTER ) THEN
			IMPORT_RESERVATION_REPORTS(v_CRED,
									   p_BEGIN_DATE,
									   p_END_DATE,
									   TRUE,
									   v_LOG_ONLY,
									   p_STATUS,
									   p_MESSAGE,
									   v_LOGGER);

		  ELSE
			p_STATUS := -1;
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
			v_LOGGER.LOG_ERROR(p_MESSAGE);
			EXIT;
		  END IF;
	END LOOP;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
----------------------------------------------------------------------------------------------------
end MM_PJM_EES;
/
