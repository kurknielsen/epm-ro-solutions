CREATE OR REPLACE PACKAGE BODY MM_PJM_ESCHED IS

    -- Author  : KCHOPRA
    -- Created : 12/4/2004 5:43:02 PM
    -- Purpose :

g_DEBUG_EXCHANGES VARCHAR2(8) := 'FALSE';

g_SCHEDULES_RPTTYPE VARCHAR2(32) := 'schedules';
g_SCHEDULES_RPTNAME VARCHAR2(32) := '';
g_CONTRACTS_RPTTYPE VARCHAR2(32) := 'contracts';
g_CONTRACTS_RPTNAME VARCHAR2(32) := '';

g_SCHEDULE_IMPORT_TYPE NUMBER(9) := 1; -- import schedules into forecast/external
g_SCHEDULE_IMPORT_STATE NUMBER(1) := 2;

-- column numbers in Schedules CSV file
g_SCHEDULES_CONF_BEGIN NUMBER(2) := 14;
g_SCHEDULES_CONF_END NUMBER(2) := 38;
g_SCHEDULES_PEND_BEGIN NUMBER(2) := 39;
g_SCHEDULES_PEND_END NUMBER(2) := 63;

g_PJM_TIMEZONE CONSTANT CHAR(3) := 'EST';

g_SCHEDULE_PENDING CONSTANT CHAR(1) := 'P';
g_SCHEDULE_CONFIRMED CONSTANT CHAR(1) := 'C';

g_RVW_STATUS_ACCEPTED CONSTANT VARCHAR2(16):= 'Accepted';
g_SUBMIT_STATUS_PENDING CONSTANT VARCHAR2(16):= 'Pending';
g_SUBMIT_STATUS_SUBMITTED CONSTANT VARCHAR2(16):= 'Submitted';
g_SUBMIT_STATUS_FAILED CONSTANT VARCHAR2(16):= 'Rejected';
g_MKT_STATUS_PENDING CONSTANT VARCHAR2(16):= 'Pending';
g_MKT_STATUS_ACCEPTED CONSTANT VARCHAR2(16):= 'Accepted';
g_MKT_STATUS_REJECTED CONSTANT VARCHAR2(16):= 'Rejected';
g_SCHEDULE_NORMAL_DAY CONSTANT VARCHAR2(16) := 'Normal';
g_SCHEDULE_LONG_DAY CONSTANT VARCHAR2(16) := 'Long';
g_SCHEDULE_SHORT_DAY CONSTANT VARCHAR2(16) := 'Short';

g_TXN_TYPE_PURCHASE CONSTANT VARCHAR2(16) := 'Purchase';
g_TXN_TYPE_SALE CONSTANT VARCHAR2(16) := 'Sale';

g_TXN_APPR_TYPE_PURCHASER CONSTANT VARCHAR2(16) := 'Purchaser';
g_TXN_APPR_TYPE_SELLER CONSTANT VARCHAR2(16) := 'Seller';

--g_PJM_SC_ID SC.SC_ID%TYPE;
g_HIGH_DATE DATE := HIGH_DATE;

-- initialized in package init code
g_ESCHED_ATTR ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;
g_USE_RT_DAILY_TX_ATTR ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;

-- used when querying eSchedule schedules - if this is true, then populate bid/offer
-- quantity with schedule MW. if it's false, only update IT_SCHEDULE.
g_UPDATE_ESCHED_TRAITS BOOLEAN := FALSE;


----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
/*
	12-mar-2009, jbc:
	This is a pass-through procedure to MM_UTIL.PUT_TRANSACTION; it just wraps that in an error
	handler to catch trying to create the same transaction again.
*/
PROCEDURE PUT_TRANSACTION(o_OID OUT NUMBER,
						  p_INTERCHANGE_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE,
						  p_SCHEDULE_STATE IN NUMBER,
						  p_TRANSACTION_STATUS IN VARCHAR2 --JUST PASS NULL FOR EXTERNAL (WILL BE IGNORED)
						  ) AS
BEGIN
	MM_UTIL.PUT_TRANSACTION(o_OID, p_INTERCHANGE_TRANSACTION, p_SCHEDULE_STATE,	p_TRANSACTION_STATUS);
EXCEPTION
	WHEN MSGCODES.e_ERR_DUP_ENTRY THEN
		ERRS.LOG_AND_CONTINUE(UT.GET_FULL_ERRM, p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
END PUT_TRANSACTION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERCHANGE_CONTRACT(p_ISO_ACCOUNT_NAME IN VARCHAR2) RETURN NUMBER IS
	v_ID NUMBER := NULL;
BEGIN
	v_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_ISO_ACCOUNT_NAME, EC.ED_INTERCHANGE_CONTRACT, EC.ES_PJM, 'Default');
	RETURN v_ID;
END GET_INTERCHANGE_CONTRACT;
----------------------------------------------------------------------------------------------------
/*
  Returns the external identifier of this PSE given its PSE_ID.
  For a PJM PSE, this will be of the form PJM-<id>.
*/
FUNCTION GET_PSE_PJM_ID(p_ID IN PSE.PSE_ID%TYPE) RETURN PSE.PSE_EXTERNAL_IDENTIFIER%TYPE IS
	v_ID       PSE.PSE_EXTERNAL_IDENTIFIER%TYPE;
BEGIN
	-- this may change to use the new MARKET_PARTICIPANT_NAME field on PSE
  -- check contracts download after change to make sure it still works
	BEGIN
		SELECT PSE.PSE_EXTERNAL_IDENTIFIER INTO v_ID FROM PSE WHERE PSE.PSE_ID = p_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
      v_ID := NULL;
			LOGS.LOG_WARN('No PSE found with ID ' || p_ID);
	END;

	RETURN v_ID;
END GET_PSE_PJM_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_SERVICE_POINT
	(
	p_SERVICE_POINT_NAME IN VARCHAR2
	) RETURN NUMBER IS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	RETURN MM_PJM_UTIL.ID_FOR_SERVICE_POINT_NAME(p_SERVICE_POINT_NAME);
END GET_SERVICE_POINT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_IS_TXN_CHANGED
  (
  p_TXN_ROW IN INTERCHANGE_TRANSACTION%ROWTYPE
  ) RETURN BINARY_INTEGER IS
v_TXN_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE; 
BEGIN

    SELECT TRANSACTION_ID
    INTO v_TXN_ID
    FROM INTERCHANGE_TRANSACTION I
    WHERE I.TRANSACTION_NAME = p_TXN_ROW.TRANSACTION_NAME
    AND I.TRANSACTION_ALIAS = p_TXN_ROW.TRANSACTION_ALIAS
    AND I.TRANSACTION_IDENTIFIER = p_TXN_ROW.TRANSACTION_IDENTIFIER    
    AND I.TRANSACTION_TYPE = p_TXN_ROW.TRANSACTION_TYPE
    AND I.BEGIN_DATE = p_TXN_ROW.BEGIN_DATE
    AND I.END_DATE = p_TXN_ROW.END_DATE
    AND I.SELLER_ID = p_TXN_ROW.SELLER_ID
    AND I.PURCHASER_ID = p_TXN_ROW.PURCHASER_ID
    AND I.SOURCE_ID = p_TXN_ROW.SOURCE_ID
    AND I.SINK_ID = p_TXN_ROW.SINK_ID
    AND I.POR_ID = p_TXN_ROW.POR_ID
    AND I.POD_ID = p_TXN_ROW.POD_ID
    AND I.TRANSACTION_INTERVAL = p_TXN_ROW.TRANSACTION_INTERVAL
    AND I.EXTERNAL_INTERVAL = p_TXN_ROW.EXTERNAL_INTERVAL
    AND I.IS_BID_OFFER = p_TXN_ROW.IS_BID_OFFER
    AND I.IS_IMPORT_EXPORT = p_TXN_ROW.IS_IMPORT_EXPORT
    AND I.SC_ID = p_TXN_ROW.SC_ID
    AND I.AGREEMENT_TYPE = p_TXN_ROW.AGREEMENT_TYPE
    AND I.COMMODITY_ID = p_TXN_ROW.COMMODITY_ID
    AND I.CONTRACT_ID = p_TXN_ROW.CONTRACT_ID;
    
    IF v_TXN_ID = p_TXN_ROW.TRANSACTION_ID THEN
        RETURN 0;
    ELSE
        RETURN 1;
    END IF;                
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 1;
END GET_IS_TXN_CHANGED;           
-------------------------------------------------------------------------------------
FUNCTION GET_PSE_FROM_OBJECT_MAP(p_ORG_NAME IN VARCHAR2) RETURN NUMBER IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_PJM_ID NUMBER := NULL;
	v_PSE_ID PSE.PSE_ID%TYPE;
BEGIN
	-- get the PJM org ID from the object map
	BEGIN
  /*
		SELECT POM.OBJECT_VALUE
			INTO v_PJM_ID
			FROM PJM_OBJECT_MAP POM
		 WHERE POM.OBJECT_TYPE = 'PSE'
			 AND UPPER(POM.OBJECT_NAME) = UPPER(p_ORG_NAME);
  */
		SELECT P.ORG_ID
			INTO v_PJM_ID
			FROM PJM_ESCHED_COMPANY P
		 WHERE UPPER(P.SHORT_NAME) = UPPER(p_ORG_NAME);

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
      v_PJM_ID := 0;
			ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_WARN, p_EXTRA_MESSAGE => 'No PJM Org ID found with name ' || p_ORG_NAME || ', try downloading latest eSchedules Company modeling data.');
	END;

  IF v_PJM_ID != 0 THEN
	-- look up the PSE id based on the PJM org ID
	v_PSE_ID := MM_PJM_UTIL.GET_PSE(v_PJM_ID, NULL);

	IF v_PSE_ID IS NULL THEN
		-- create the PSE
		-- fix bug 9020 by using EDT for the time zone rather than NULL.
		IO.PUT_PSE(o_OID                       => v_PSE_ID,
							 p_PSE_NAME                  => p_ORG_NAME,
							 p_PSE_ALIAS                 => p_ORG_NAME,
							 p_PSE_DESC                  => 'Created via eSchedule contract import',
							 p_PSE_ID                    => 0,
							 p_PSE_NERC_CODE             => NULL,
							 p_PSE_STATUS                => 'Active',
							 p_PSE_DUNS_NUMBER           => NULL,
							 p_PSE_BANK                  => NULL,
							 p_PSE_ACH_NUMBER            => NULL,
							 p_PSE_TYPE                  => NULL,
							 p_PSE_EXTERNAL_IDENTIFIER   => 'PJM-' || v_PJM_ID,
							 p_PSE_IS_RETAIL_AGGREGATOR  => NULL,
							 p_PSE_IS_BACKUP_GENERATION  => NULL,
							 p_PSE_EXCLUDE_LOAD_SCHEDULE => NULL,
							 p_IS_BILLING_ENTITY         => NULL,
							 p_TIME_ZONE                 => 'EDT',
							 p_STATEMENT_INTERVAL        => NULL,
							 p_INVOICE_INTERVAL          => NULL,
							 p_WEEK_BEGIN                => NULL,
							 p_INVOICE_LINE_ITEM_OPTION  => NULL,
							 p_SCHEDULE_NAME_PREFIX => NULL,
							 p_SCHEDULE_FORMAT => NULL,
							 p_SCHEDULE_INTERVAL => NULL,
							 p_LOAD_ROUNDING_PREFERENCE => NULL,
							 p_LOSS_ROUNDING_PREFERENCE => NULL,
							 p_CREATE_TX_LOSS_SCHEDULE => NULL,
							 p_CREATE_DX_LOSS_SCHEDULE => NULL,
							 p_CREATE_UFE_SCHEDULE => NULL,
							 p_MINIMUM_SCHEDULE_AMT => NULL,
							 p_INVOICE_EMAIL_SUBJECT => NULL,
							 p_INVOICE_EMAIL_PRIORITY => NULL,
							 p_INVOICE_EMAIL_BODY => NULL,
							 p_INVOICE_EMAIL_BODY_MIME_TYPE => NULL);

		COMMIT;
	END IF;
  ELSE
      v_PSE_ID := 0;
  END IF;

	RETURN v_PSE_ID;
END GET_PSE_FROM_OBJECT_MAP;
----------------------------------------------------------------------------------------------------
/*
  31-mar-2005, jbc: this routine got ripped off from mm_pjm_util. I
  hardwired it to only consider the contract number as the
  external id of the transaction, plus added the external credential
  as a parameter, since the eschedule transaction identifier is
  actually PJM-<PSE PJM ID>-<contract number>.
*/
FUNCTION GET_TRANSACTION_ID
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_TRANSACTION_IDENTIFIER IN VARCHAR2,
	p_SERVICE_DATE IN DATE,
	p_IS_RT_DAILY_TX_REPORT IN NUMBER
	) RETURN NUMBER IS

v_TX_ID NUMBER(9) := -1;
v_CONTRACT_ID NUMBER(9);
v_ATTRIBUTE_VAL VARCHAR2(1) := CASE p_IS_RT_DAILY_TX_REPORT WHEN 1 THEN '1' ELSE '0' END;

BEGIN

	v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_EXTERNAL_ACCOUNT_NAME);

	BEGIN
		--First try finding a Transaction based on the Populate from RTDailyTx Report Flag.
		SELECT TRANSACTION_ID
			INTO v_TX_ID
			FROM INTERCHANGE_TRANSACTION ITX, TEMPORAL_ENTITY_ATTRIBUTE TEA
		 WHERE p_SERVICE_DATE BETWEEN ITX.BEGIN_DATE AND NVL(ITX.END_DATE, g_HIGH_DATE)
			 AND ITX.TRANSACTION_IDENTIFIER = p_TRANSACTION_IDENTIFIER
			 AND ITX.CONTRACT_ID = v_CONTRACT_ID
			 AND TEA.OWNER_ENTITY_ID = ITX.TRANSACTION_ID
			 AND TEA.ATTRIBUTE_ID = g_USE_RT_DAILY_TX_ATTR
			 AND p_SERVICE_DATE BETWEEN TEA.BEGIN_DATE AND NVL(TEA.END_DATE, g_HIGH_DATE)
			 AND NVL(TEA.ATTRIBUTE_VAL,'0') = v_ATTRIBUTE_VAL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--If there was no Transaction based on the flag, and this is the RT Daily Tx
			--Report, then we just give up.  If this is not the RT Daily Tx Report,
			--then go ahead and look for one that is missing the attribute.
			IF p_IS_RT_DAILY_TX_REPORT = 0 THEN
    				SELECT TRANSACTION_ID
    					INTO v_TX_ID
    					FROM INTERCHANGE_TRANSACTION ITX
    				WHERE p_SERVICE_DATE BETWEEN ITX.BEGIN_DATE AND NVL(ITX.END_DATE, g_HIGH_DATE)
    					 AND ITX.TRANSACTION_IDENTIFIER = p_TRANSACTION_IDENTIFIER
    					 AND ITX.CONTRACT_ID = v_CONTRACT_ID
    					 AND NOT EXISTS (SELECT 1 FROM TEMPORAL_ENTITY_ATTRIBUTE WHERE OWNER_ENTITY_ID = ITX.TRANSACTION_ID AND ATTRIBUTE_ID = g_USE_RT_DAILY_TX_ATTR AND p_SERVICE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, g_HIGH_DATE));

			END IF;
        END;

	RETURN v_TX_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_WARN, p_EXTRA_MESSAGE => 'iso acct: ' || p_EXTERNAL_ACCOUNT_NAME || ', txn identifier: ' || p_TRANSACTION_IDENTIFIER);
		RETURN - 1;
END GET_TRANSACTION_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_TXN_ID_FOR_LOAD_W_WO_LOSS
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_TRANSACTION_IDENTIFIER IN VARCHAR2,
	p_SERVICE_DATE IN DATE,
    p_TRANS_TYPE IN VARCHAR2,
	p_CREATE_LPL_IF_NOT_FOUND IN BOOLEAN
	) RETURN NUMBER IS

v_TX_ID NUMBER(9) := -1;
v_CONTRACT_ID NUMBER(9);
v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
v_LOAD_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
BEGIN

	v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_EXTERNAL_ACCOUNT_NAME);

    IF p_TRANS_TYPE IS NULL OR UPPER(p_TRANS_TYPE) = 'LOAD WITHOUT LOSSES' THEN
        --this is the bilateral imported from exchedules schedules and must already exist
        SELECT TRANSACTION_ID
	    INTO v_TX_ID
	    FROM INTERCHANGE_TRANSACTION ITX
        WHERE p_SERVICE_DATE BETWEEN ITX.BEGIN_DATE AND NVL(ITX.END_DATE, g_HIGH_DATE)
	    AND ITX.TRANSACTION_IDENTIFIER = p_TRANSACTION_IDENTIFIER
	    AND ITX.CONTRACT_ID = v_CONTRACT_ID;
    ELSIF UPPER(p_TRANS_TYPE) = 'LOAD WITH LOSSES' THEN
        BEGIN
            SELECT TRANSACTION_ID
         INTO v_TX_ID
         FROM INTERCHANGE_TRANSACTION ITX
            WHERE p_SERVICE_DATE BETWEEN ITX.BEGIN_DATE AND NVL(ITX.END_DATE, g_HIGH_DATE)
         AND ITX.TRANSACTION_IDENTIFIER = p_TRANSACTION_IDENTIFIER || 'LPL'
         AND ITX.CONTRACT_ID = v_CONTRACT_ID
            AND UPPER(ITX.TRANSACTION_TYPE) = 'LOAD PLUS LOSSES';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
				IF p_CREATE_LPL_IF_NOT_FOUND THEN
	                --create the Load Plus Losses transaction if not found
	                SELECT * INTO v_LOAD_TRANSACTION
	                FROM INTERCHANGE_TRANSACTION ITX
	                WHERE ITX.CONTRACT_ID = v_CONTRACT_ID
	                AND ITX.TRANSACTION_IDENTIFIER = p_TRANSACTION_IDENTIFIER
	                AND p_SERVICE_DATE BETWEEN ITX.BEGIN_DATE AND NVL(ITX.END_DATE, g_HIGH_DATE);

	                ID.ID_FOR_COMMODITY('RealTime Energy', FALSE, v_TRANSACTION.COMMODITY_ID);
	                v_TRANSACTION.TRANSACTION_ID := 0;
	                v_TRANSACTION.Transaction_Type := 'Load Plus Losses';
	                v_TRANSACTION.TRANSACTION_IDENTIFIER := p_TRANSACTION_IDENTIFIER || 'LPL';
	                v_TRANSACTION.TRANSACTION_DESC := 'Created by MarketManager on ' || UT.TRACE_DATE(SYSDATE) || ' by ESchedule.';
	                v_TRANSACTION.SC_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM); --MM_PJM_UTIL.g_PJM_SC_ID;
	                v_TRANSACTION.TRANSACTION_INTERVAL := 'Hour';
	                v_TRANSACTION.RESOURCE_ID := 0;
	                v_TRANSACTION.CONTRACT_ID := v_CONTRACT_ID;
	                v_TRANSACTION.TRANSACTION_NAME := REPLACE(v_LOAD_TRANSACTION.Transaction_Name,
	                                                            p_TRANSACTION_IDENTIFIER,
	                                                            p_TRANSACTION_IDENTIFIER || 'LPL');
	                v_TRANSACTION.Transaction_Alias := v_LOAD_TRANSACTION.Transaction_Alias || 'LPL';
	                v_TRANSACTION.Agreement_Type := v_LOAD_TRANSACTION.Agreement_Type;
	                v_TRANSACTION.Is_Bid_Offer := v_LOAD_TRANSACTION.Is_Bid_Offer;
	                v_TRANSACTION.Por_Id := v_LOAD_TRANSACTION.Por_Id;
	                v_TRANSACTION.Pod_Id := v_LOAD_TRANSACTION.Pod_Id;
	                v_TRANSACTION.Seller_Id := v_LOAD_TRANSACTION.Seller_Id;
	                v_TRANSACTION.Purchaser_Id := v_LOAD_TRANSACTION.Purchaser_Id;
	                v_TRANSACTION.Is_Import_Export := v_LOAD_TRANSACTION.Is_Import_Export;
	                v_TRANSACTION.Is_Firm := v_LOAD_TRANSACTION.Is_Firm;
	                v_TRANSACTION.Begin_Date := v_LOAD_TRANSACTION.Begin_Date;
	                v_TRANSACTION.End_Date := v_LOAD_TRANSACTION.End_Date;

	                PUT_TRANSACTION(v_TX_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');
				--If CREATE_LPL_IF_NOT_FOUND is set to False, just return NULL for the ID of the LPL txn.
				ELSE
					v_TX_ID := NULL;
				END IF;
        END;
    END IF;

	RETURN v_TX_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_WARN, p_EXTRA_MESSAGE => 'iso acct: ' || p_EXTERNAL_ACCOUNT_NAME || ', txn identifier: ' || p_TRANSACTION_IDENTIFIER);
		RETURN - 1;
END GET_TXN_ID_FOR_LOAD_W_WO_LOSS;
----------------------------------------------------------------------------------------------------
FUNCTION GET_RT_NET_INTERCHANGE_TX_ID
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_TXN_TYPE IN VARCHAR2,
	p_TXN_NAME_PREFIX IN VARCHAR2,
	p_SERVICE_DATE IN DATE
	) RETURN NUMBER IS

	v_TX_ID NUMBER(9) := -1;
	v_CONTRACT_ID NUMBER(9);
	v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
	v_CONTRACT_NAME INTERCHANGE_CONTRACT.CONTRACT_NAME%TYPE;
	v_COMMODITY_ID NUMBER(9):= MM_PJM_UTIL.GET_COMMODITY_ID(MM_PJM_UTIL.g_COMM_RT_ENERGY);
BEGIN

	v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_EXTERNAL_ACCOUNT_NAME);
	SELECT CONTRACT_NAME INTO v_CONTRACT_NAME FROM INTERCHANGE_CONTRACT WHERE CONTRACT_ID = v_CONTRACT_ID;

	BEGIN
		--First try finding a Transaction based on the Contract, SC, and Type.
		SELECT TRANSACTION_ID
			INTO v_TX_ID
			FROM INTERCHANGE_TRANSACTION ITX
		WHERE ITX.CONTRACT_ID = v_CONTRACT_ID
			AND ITX.SC_ID = EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM) --MM_PJM_UTIL.g_PJM_SC_ID
			AND ITX.TRANSACTION_TYPE = p_TXN_TYPE;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			--Create it if it did not exist.
			v_TRANSACTION.TRANSACTION_ID := 0;
			v_TRANSACTION.TRANSACTION_NAME := p_TXN_NAME_PREFIX || v_CONTRACT_NAME;
			v_TRANSACTION.TRANSACTION_DESC := 'Created by PJM Real-Time Daily Transaction Report Download on ' || UT.TRACE_DATE(SYSDATE) || '.';
			v_TRANSACTION.TRANSACTION_TYPE := p_TXN_TYPE;
			v_TRANSACTION.TRANSACTION_IDENTIFIER := v_TRANSACTION.TRANSACTION_NAME;
			v_TRANSACTION.TRANSACTION_INTERVAL := 'Hour';
			v_TRANSACTION.BEGIN_DATE := TRUNC(p_SERVICE_DATE,'YYYY');
			v_TRANSACTION.END_DATE := ADD_MONTHS(TRUNC(p_SERVICE_DATE,'YYYY'), 120) - 1;
			v_TRANSACTION.CONTRACT_ID := v_CONTRACT_ID;
			v_TRANSACTION.SC_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM); --MM_PJM_UTIL.g_PJM_SC_ID;
			v_TRANSACTION.COMMODITY_ID := v_COMMODITY_ID;

			PUT_TRANSACTION(v_TX_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');
	END;

	RETURN v_TX_ID;

END GET_RT_NET_INTERCHANGE_TX_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_TX_ID
  (
  p_EXT_ID IN VARCHAR2,
  p_TRANS_TYPE IN VARCHAR2 := 'Market Result',
  p_NAME IN VARCHAR2 := NULL,
  p_INTERVAL IN VARCHAR2 := 'Hour',
  p_COMMODITY_ID IN NUMBER := 0,
  p_CONTRACT_ID IN NUMBER := 0,
  p_ZOD_ID IN NUMBER := 0,
  p_SERVICE_POINT_ID IN NUMBER := 0,
  p_POOL_ID IN NUMBER := 0,
  p_SELLER_ID IN NUMBER := 0,
  p_DESC IN VARCHAR2 DEFAULT NULL
  ) RETURN NUMBER IS

  v_ID NUMBER;
  v_SC NUMBER(9);
  v_SUFFIX VARCHAR2(32) := '';
  v_TMP VARCHAR2(32);
  v_NAME VARCHAR2(64);
  v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
  v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

BEGIN
	IF p_EXT_ID IS NULL THEN
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_TYPE = p_TRANS_TYPE
            AND CONTRACT_ID = p_CONTRACT_ID
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID)
            AND (p_ZOD_ID = 0 OR ZOD_ID = p_ZOD_ID);
	ELSE
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_IDENTIFIER = p_EXT_ID
            AND (p_CONTRACT_ID = 0 OR CONTRACT_ID = p_CONTRACT_ID)
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID)
            AND (p_ZOD_ID = 0 OR ZOD_ID = p_ZOD_ID);
	END IF;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_NAME := NVL(p_NAME,p_EXT_ID);

        SELECT SC_ID
        INTO v_SC
        FROM SCHEDULE_COORDINATOR
        WHERE SC_NAME = 'PJM';

		IF p_CONTRACT_ID <> 0 THEN
    	    SELECT ': '||CONTRACT_NAME
	        INTO v_TMP
	        FROM INTERCHANGE_CONTRACT
	        WHERE CONTRACT_ID = p_CONTRACT_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
		END IF;
        IF p_SELLER_ID <> 0 THEN
    	    SELECT ': '||PSE_NAME
	        INTO v_TMP
	        FROM PURCHASING_SELLING_ENTITY
	        WHERE PSE_ID = p_SELLER_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
        END IF;
        IF p_POOL_ID <> 0 THEN
    	    SELECT ': '||POOL_NAME
	        INTO v_TMP
	        FROM POOL
	        WHERE POOL_ID = p_POOL_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
        END IF;
        IF p_SERVICE_POINT_ID <> 0 THEN
    	    SELECT ': '||SERVICE_POINT_NAME
	        INTO v_TMP
	        FROM SERVICE_POINT
	        WHERE SERVICE_POINT_ID = p_SERVICE_POINT_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
        END IF;

	--create the transaction

    	v_TRANSACTION.TRANSACTION_ID := 0;
        v_TRANSACTION.TRANSACTION_NAME := SUBSTR(v_NAME||v_SUFFIX,1,64);
        v_TRANSACTION.TRANSACTION_ALIAS := SUBSTR(v_NAME||v_SUFFIX,1,32);
        IF p_DESC IS NULL THEN
            v_TRANSACTION.TRANSACTION_DESC := v_NAME||v_SUFFIX;
        ELSE
            v_TRANSACTION.TRANSACTION_DESC := p_DESC;
        END IF;
        v_TRANSACTION.TRANSACTION_TYPE := p_TRANS_TYPE;
        v_TRANSACTION.TRANSACTION_IDENTIFIER := p_EXT_ID;
        v_TRANSACTION.TRANSACTION_INTERVAL := p_INTERVAL;
        v_TRANSACTION.BEGIN_DATE := TO_DATE('1/1/2000','MM/DD/YYYY');
        v_TRANSACTION.END_DATE := TO_DATE('12/31/2020','MM/DD/YYYY');
        v_TRANSACTION.SELLER_ID := p_SELLER_ID;
        v_TRANSACTION.CONTRACT_ID := p_CONTRACT_ID;
        v_TRANSACTION.SC_ID := v_SC;
        v_TRANSACTION.POD_ID := p_SERVICE_POINT_ID;
        v_TRANSACTION.POOL_ID := p_POOL_ID;
        v_TRANSACTION.ZOD_ID := p_ZOD_ID;
        v_TRANSACTION.COMMODITY_ID := p_COMMODITY_ID;

		PUT_TRANSACTION(v_TRANSACTION_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');

		RETURN v_TRANSACTION_ID;
END GET_TX_ID;
------------------------------------------------------------------------------------
FUNCTION ESCHED_W_WO_LOSSES_HAS_RUN
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_TRANSACTION_IDENTIFIER IN NUMBER,
	p_SERVICE_DATE IN DATE
	) RETURN BOOLEAN IS
	--This function returns true if the esched_w_wo_losses report has already
	--run for this date for this transaction, or false if it has not.
	v_RTN BOOLEAN;
	v_W_WO_LOSSES_HAS_RUN NUMBER := 0;
	v_LPL_TXN_ID NUMBER;
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
BEGIN
	-- Get the LPL Transaction ID.
	v_LPL_TXN_ID := GET_TXN_ID_FOR_LOAD_W_WO_LOSS(p_EXTERNAL_ACCOUNT_NAME,
		p_TRANSACTION_IDENTIFIER,
		p_SERVICE_DATE,
		'LOAD WITH LOSSES',
		FALSE);

	-- If there was not one, then we definitely know it hasn't run.
	IF v_LPL_TXN_ID IS NULL	THEN
		v_RTN := FALSE;
	-- If there was one, we need to see if it has any data for this date.
	ELSE
		UT.CUT_DATE_RANGE(1, p_SERVICE_DATE, p_SERVICE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

		SELECT CASE WHEN SUM(AMOUNT) IS NULL THEN 0 ELSE 1 END
		INTO v_W_WO_LOSSES_HAS_RUN
		FROM IT_SCHEDULE ITS
		WHERE ITS.TRANSACTION_ID = v_LPL_TXN_ID
			AND ITS.SCHEDULE_TYPE = 1
			AND ITS.SCHEDULE_STATE = 1
			AND ITS.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

		v_RTN := CASE v_W_WO_LOSSES_HAS_RUN WHEN 1 THEN TRUE ELSE FALSE END;
	END IF;

	RETURN v_RTN;

END ESCHED_W_WO_LOSSES_HAS_RUN;
---------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_LOAD_W_LOSSES_DATES
    (
    p_SERVICE_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_TRANS_IDENT IN VARCHAR2
    ) AS
v_TX_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_CURRENT_END_DATE DATE;
BEGIN

    SELECT TRANSACTION_ID
    INTO v_TX_ID
    FROM INTERCHANGE_TRANSACTION ITX
    WHERE ITX.TRANSACTION_IDENTIFIER = p_TRANS_IDENT || 'LPL'
    AND ITX.CONTRACT_ID = p_CONTRACT_ID
    AND UPPER(ITX.TRANSACTION_TYPE) = 'LOAD PLUS LOSSES';

    SELECT END_DATE 
    INTO v_CURRENT_END_DATE
    FROM INTERCHANGE_TRANSACTION
    WHERE TRANSACTION_ID = v_TX_ID;
    
    IF TRUNC(v_CURRENT_END_DATE) <> TRUNC(p_SERVICE_DATE) THEN

        UPDATE INTERCHANGE_TRANSACTION
        SET END_DATE = p_SERVICE_DATE
        WHERE TRANSACTION_ID = v_TX_ID;
        
    END IF;        

EXCEPTION
    WHEN NO_DATA_FOUND THEN
    --there may be no Load Plus Losses transaction for this PJM contract
        NULL;
END UPDATE_LOAD_W_LOSSES_DATES;
--------------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULE_VALUE
    (
    p_TX_ID IN NUMBER,
    p_SCHED_DATE IN DATE,
    p_AMOUNT NUMBER,
    p_PRICE NUMBER := NULL,
    p_TO_INTERNAL BOOLEAN := TRUE
    ) AS
v_STATUS NUMBER;
v_IDX BINARY_INTEGER;

BEGIN


    FOR v_IDX IN 1..MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
        IF p_TO_INTERNAL THEN
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                               p_SCHEDULE_TYPE => MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(v_IDX),
                               p_SCHEDULE_STATE => 1,
                               p_SCHEDULE_DATE => p_SCHED_DATE,
                               p_AS_OF_DATE => SYSDATE,
                               p_AMOUNT => p_AMOUNT,
                               p_PRICE => p_PRICE,
                               p_STATUS => v_STATUS);
        END IF;
        ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                           p_SCHEDULE_TYPE => MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(v_IDX),
                           p_SCHEDULE_STATE => 2,
                           p_SCHEDULE_DATE => p_SCHED_DATE,
                           p_AS_OF_DATE => SYSDATE,
                           p_AMOUNT => p_AMOUNT,
                           p_PRICE => p_PRICE,
                           p_STATUS => v_STATUS);
    END LOOP;

END PUT_SCHEDULE_VALUE;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULE_FOR_HOUR
	(
	p_TRANSACTION_ID IN NUMBER,
	p_ROLL_FORWARD_TXN_ID IN NUMBER,
	p_SCHEDULE_DATE IN DATE,
	p_AMOUNT IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
BEGIN

		ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID,
	                   g_SCHEDULE_IMPORT_TYPE,
	                   g_SCHEDULE_IMPORT_STATE,
	                   p_SCHEDULE_DATE,
	                   SYSDATE,
	                   p_AMOUNT,
	                   NULL,
	                   p_STATUS);

		-- 15-mar-2005, jbc: copy to internal side also
		ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID,
	                   g_SCHEDULE_IMPORT_TYPE,
	                   GA.INTERNAL_STATE,
	                   p_SCHEDULE_DATE,
	                   SYSDATE,
	                   p_AMOUNT,
	                   NULL,
	                   p_STATUS);

		-- Roll Forward Confirmed DA Schedules into RT.
		IF p_ROLL_FORWARD_TXN_ID > 0 THEN
			ITJ.PUT_IT_SCHEDULE(p_ROLL_FORWARD_TXN_ID,
		                   g_SCHEDULE_IMPORT_TYPE,
		                   GA.INTERNAL_STATE,
		                   p_SCHEDULE_DATE,
		                   SYSDATE,
		                   p_AMOUNT,
		                   NULL,
		                   p_STATUS);
		END IF;


	--03-june-2005, LD: populate BID_OFFER_SET internal and external
	--with confirmed or pending vals (internal only if flag is set due to action).
	--Do not copy RT roll-forwards into Bid Offer Set.
	IF g_UPDATE_ESCHED_TRAITS = TRUE THEN
	    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
	    BO.PUT_BID_OFFER_SET(p_TRANSACTION_ID,
	                     0,
	                     GA.INTERNAL_STATE,
	                     p_SCHEDULE_DATE,
	                     g_SCHEDULE_IMPORT_TYPE, --Forecast
	                     NULL,
	                     p_AMOUNT,
	                     'P', --NOT USED
	                     g_PJM_TIMEZONE,
	                     p_STATUS);
	END IF;

	-- always update the external traits
	BO.PUT_BID_OFFER_SET(p_TRANSACTION_ID,
	                     0,
	                     GA.EXTERNAL_STATE,
	                     p_SCHEDULE_DATE,
	                     g_SCHEDULE_IMPORT_TYPE, --Forecast
	                     NULL,
	                     p_AMOUNT,
	                     'P', --NOT USED
	                     g_PJM_TIMEZONE,
	                     p_STATUS);
	SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

END PUT_SCHEDULE_FOR_HOUR;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULE_FOR_DAY
	(
	p_COLUMNS IN PARSE_UTIL.STRING_TABLE,
	p_TRANSACTION_ID IN NUMBER,
	p_ROLL_FORWARD_TXN_ID IN NUMBER,
	p_DATE IN DATE,
    p_DAY_TYPE IN VARCHAR2
	) AS

	v_VALUE           VARCHAR2(16);
	v_DATE            DATE;
	v_STATUS          NUMBER;
	v_SELLER_STATUS   VARCHAR2(1);
	v_BUYER_STATUS    VARCHAR2(1);
	v_SCHEDULE_STATUS VARCHAR2(1);
    v_MAX_HOUR        NUMBER;

BEGIN
	--determine the status of the schedule: Confirmed or Pending
	v_SELLER_STATUS := p_COLUMNS(4);
	v_BUYER_STATUS  := p_COLUMNS(6);

	IF UPPER(v_SELLER_STATUS) = g_SCHEDULE_CONFIRMED AND
		UPPER(v_BUYER_STATUS) = g_SCHEDULE_CONFIRMED THEN
		v_SCHEDULE_STATUS := g_SCHEDULE_CONFIRMED;
	ELSE
		v_SCHEDULE_STATUS := g_SCHEDULE_PENDING;
		IF p_DATE BETWEEN TRUNC(SYSDATE, 'DD') - 6 AND TRUNC(SYSDATE, 'DD') THEN
			MM_UTIL.POST_UNCONFIRMED_SCHED_ALARM('PJM', p_TRANSACTION_ID, p_DATE);
		END IF;
	END IF;

    IF p_DAY_TYPE = g_SCHEDULE_LONG_DAY THEN
        v_MAX_HOUR := 25;
	ELSE
        v_MAX_HOUR := 24;
	END IF;

	-- columns 14 to 38 are confirmed entries, 39 to 63 are pending
	FOR v_HOUR IN 1 .. v_MAX_HOUR LOOP
        -- on the short day, there is no hour 3
        IF (p_DAY_TYPE = g_SCHEDULE_NORMAL_DAY) OR (p_DAY_TYPE = g_SCHEDULE_LONG_DAY) OR (p_DAY_TYPE = g_SCHEDULE_SHORT_DAY AND v_HOUR <> 3)THEN
    		IF NVL(LENGTH(p_COLUMNS(v_HOUR + g_SCHEDULES_CONF_BEGIN - 1)), 0) > 0 THEN
    			v_VALUE := p_COLUMNS(v_HOUR + g_SCHEDULES_CONF_BEGIN - 1);
    		ELSIF NVL(LENGTH(p_COLUMNS(v_HOUR + g_SCHEDULES_PEND_BEGIN - 1)), 0) > 0 THEN
    			v_VALUE := p_COLUMNS(v_HOUR + g_SCHEDULES_PEND_BEGIN - 1);
    		ELSE
    			v_VALUE := NULL;
    		END IF;

    		-- put schedule value
    		IF NOT v_VALUE IS NULL THEN
                IF p_DAY_TYPE = g_SCHEDULE_LONG_DAY AND v_HOUR = 25 THEN
				-- 25th hour represents the second hour-two
				v_DATE := p_DATE + 2 / 24 + (1 / (24 * 60 * 60));
                ELSIF p_DAY_TYPE = g_SCHEDULE_SHORT_DAY AND v_HOUR = 2 THEN
                    -- file skips hour 3, but for storing in RO as Hour-Ending
    				-- we skip hour 2
    				v_DATE := p_DATE + (v_HOUR + 1) / 24;
                ELSE
    			    v_DATE := p_DATE + v_HOUR / 24;
                END IF;
    			v_DATE := TO_CUT_WITH_OPTIONS(v_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
    			PUT_SCHEDULE_FOR_HOUR(p_TRANSACTION_ID, p_ROLL_FORWARD_TXN_ID, v_DATE, TO_NUMBER(v_VALUE), v_STATUS);
    	    END IF;
        END IF;
	END LOOP;
END PUT_SCHEDULE_FOR_DAY;
----------------------------------------------------------------------------------------------------
FUNCTION PUT_SCHEDULE_CSV_LINE
	(
	p_EXTERNAL_ACCOUNT_NAME in VARCHAR2,
	p_CSV_LINE IN VARCHAR2,
	p_NO_CONTRACTS IN OUT NOCOPY PARSE_UTIL.STRING_TABLE
	) RETURN BOOLEAN IS

	v_COLUMNS PARSE_UTIL.STRING_TABLE;
	v_CONTRACT_NUMBER VARCHAR2(32);
	v_SERVICE_DATE DATE;
	v_TRANSACTION_ID NUMBER(9);
	v_TX_BEGIN_DATE DATE;
	v_TX_END_DATE DATE;
	v_INDEX BINARY_INTEGER;
	v_NUM_HOURS NUMBER(2);
	v_ROLL_FORWARD_TXN_ID NUMBER(9) := 0;
	v_MARKET_TYPE VARCHAR2(32);
BEGIN
	PARSE_UTIL.TOKENS_FROM_STRING(p_CSV_LINE, ',', v_COLUMNS);
	v_CONTRACT_NUMBER := v_COLUMNS(1);
	v_SERVICE_DATE    := TO_DATE(v_COLUMNS(2), 'DD-MON-YY');

	-- We might not have an external credential if we are importing from a file.
	IF p_EXTERNAL_ACCOUNT_NAME IS NULL THEN
	    v_TRANSACTION_ID := MM_PJM_UTIL.GET_TRANSACTION_ID(v_CONTRACT_NUMBER,v_SERVICE_DATE);
	ELSE
		v_TRANSACTION_ID := GET_TRANSACTION_ID(p_EXTERNAL_ACCOUNT_NAME, v_CONTRACT_NUMBER, v_SERVICE_DATE, 0);
	END IF;

	IF v_TRANSACTION_ID <= 0 THEN
		-- see if this contract number is already in list
		v_INDEX := p_NO_CONTRACTS.FIRST;
		WHILE p_NO_CONTRACTS.EXISTS(v_INDEX) LOOP
			IF p_NO_CONTRACTS(v_INDEX) = v_CONTRACT_NUMBER THEN
				RETURN FALSE; -- already there? nothing more to do
			END IF;
			v_INDEX := p_NO_CONTRACTS.NEXT(v_INDEX);
		END LOOP;
		-- not already there? then record contract number
		p_NO_CONTRACTS(p_NO_CONTRACTS.COUNT) := v_CONTRACT_NUMBER;
		RETURN FALSE;
	ELSE
		-- If the w_wo_losses report has already overwritten this transaction for this day,
		-- we do not want to overwrite it again.
		-- We know whether w_wo_losses has done this by looking up the LPL transaction
		-- that corresponds to the current one.  If it has data for this day, we
		-- do not want to write any eSchedule data.
		IF ESCHED_W_WO_LOSSES_HAS_RUN(p_EXTERNAL_ACCOUNT_NAME, v_CONTRACT_NUMBER, v_SERVICE_DATE) THEN
			RETURN TRUE;
		END IF;

		-- extend transaction's date range if necessary
		SELECT BEGIN_DATE, END_DATE, B.MARKET_TYPE
		INTO v_TX_BEGIN_DATE, v_TX_END_DATE, v_MARKET_TYPE
		FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
		WHERE TRANSACTION_ID = v_TRANSACTION_ID
			AND A.COMMODITY_ID = B.COMMODITY_ID;

		IF v_TX_BEGIN_DATE > v_SERVICE_DATE THEN
			UPDATE INTERCHANGE_TRANSACTION
			SET BEGIN_DATE = v_SERVICE_DATE
			WHERE TRANSACTION_ID = v_TRANSACTION_ID;
		END IF;
		IF v_TX_END_DATE < v_SERVICE_DATE THEN
			UPDATE INTERCHANGE_TRANSACTION
			SET END_DATE = v_SERVICE_DATE
			WHERE TRANSACTION_ID = v_TRANSACTION_ID;
		END IF;

		-- If this is a DayAhead Transaction, get its RT counterpart.
		IF v_MARKET_TYPE = MM_PJM_UTIL.g_DAYAHEAD THEN
			-- We might not have an external credential if we are importing from a file.
			IF p_EXTERNAL_ACCOUNT_NAME IS NULL THEN
			    v_ROLL_FORWARD_TXN_ID := MM_PJM_UTIL.GET_TRANSACTION_ID(v_CONTRACT_NUMBER || 'RT',v_SERVICE_DATE);
			ELSE
				v_ROLL_FORWARD_TXN_ID := GET_TRANSACTION_ID(p_EXTERNAL_ACCOUNT_NAME, v_CONTRACT_NUMBER || 'RT', v_SERVICE_DATE, 0);
			END IF;

			IF v_ROLL_FORWARD_TXN_ID <= 0 THEN
				v_ROLL_FORWARD_TXN_ID := 0;
			END IF;
		END IF;

		-- determine how long the day is
		IF NVL(LENGTH(v_COLUMNS(g_SCHEDULES_CONF_END)), 0) > 0 OR
			 NVL(LENGTH(v_COLUMNS(g_SCHEDULES_PEND_END)), 0) > 0 THEN
			v_NUM_HOURS := 25; -- 25 entries indicates long DST day
		ELSIF NVL(LENGTH(v_COLUMNS(g_SCHEDULES_CONF_END - 1)), 0) = 0 AND
					NVL(LENGTH(v_COLUMNS(g_SCHEDULES_PEND_END - 1)), 0) = 0 THEN
			v_NUM_HOURS := 23; -- 24th missing? then perhaps it's short DST day
		ELSE
			v_NUM_HOURS := 24;
		END IF;
		IF v_SERVICE_DATE = TRUNC(DST_FALL_BACK_DATE(v_SERVICE_DATE)) OR v_NUM_HOURS > 24 THEN
			PUT_SCHEDULE_FOR_DAY(v_COLUMNS, v_TRANSACTION_ID, v_ROLL_FORWARD_TXN_ID, v_SERVICE_DATE, g_SCHEDULE_LONG_DAY);
		ELSIF v_SERVICE_DATE = TRUNC(DST_SPRING_AHEAD_DATE(v_SERVICE_DATE)) AND v_NUM_HOURS < 24 THEN
			PUT_SCHEDULE_FOR_DAY(v_COLUMNS, v_TRANSACTION_ID, v_ROLL_FORWARD_TXN_ID, v_SERVICE_DATE,g_SCHEDULE_SHORT_DAY);
		ELSE
			PUT_SCHEDULE_FOR_DAY(v_COLUMNS, v_TRANSACTION_ID, v_ROLL_FORWARD_TXN_ID, v_SERVICE_DATE, g_SCHEDULE_NORMAL_DAY);
		END IF;
		RETURN TRUE;
	END IF;
END PUT_SCHEDULE_CSV_LINE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULES
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER  IN OUT mm_logger_adapter
	) AS

v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_NO_CONTRACTS PARSE_UTIL.STRING_TABLE;
v_REC_COUNT NUMBER := 0;
v_REC_NO_COUNT NUMBER := 0;
v_INDEX BINARY_INTEGER;

BEGIN
	p_STATUS := GA.SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
	v_INDEX := v_LINES.NEXT(v_LINES.FIRST); -- first line is just header, so start with second line
	-- import one line at a time
	WHILE v_LINES.EXISTS(v_INDEX) LOOP
		IF LENGTH(v_LINES(v_INDEX)) > 0 THEN
			IF PUT_SCHEDULE_CSV_LINE(p_EXTERNAL_ACCOUNT_NAME, v_LINES(v_INDEX), v_NO_CONTRACTS) THEN
				v_REC_COUNT := v_REC_COUNT + 1;
			ELSE
				v_REC_NO_COUNT := v_REC_NO_COUNT + 1;
			END IF;
		END IF;

		v_INDEX := v_LINES.NEXT(v_INDEX);
	END LOOP;

	IF v_REC_COUNT > 0 THEN
		-- we've imported at least one schedule
		COMMIT;
	END IF;

	-- build report of what happened
	p_LOGGER.LOG_INFO(TO_CHAR(v_REC_COUNT) || ' records imported');
	IF v_REC_NO_COUNT > 0 THEN
		p_STATUS := 1;
		p_MESSAGE := p_MESSAGE || CHR(10) || TO_CHAR(v_REC_NO_COUNT) ||	' records _not_ imported';
		v_INDEX   := v_NO_CONTRACTS.FIRST;
		p_MESSAGE := p_MESSAGE || CHR(10) || 'Contract Numbers not found: ';
		WHILE v_NO_CONTRACTS.EXISTS(v_INDEX) LOOP
			IF v_INDEX <> v_NO_CONTRACTS.FIRST THEN
				p_MESSAGE := p_MESSAGE || ', ';
			END IF;
			p_MESSAGE := p_MESSAGE || v_NO_CONTRACTS(v_INDEX);
			v_INDEX   := v_NO_CONTRACTS.NEXT(v_INDEX);
		END LOOP;

		LOGS.LOG_ERROR(p_MESSAGE);
	END IF;

EXCEPTION
	WHEN OTHERS THEN
	p_STATUS  := SQLCODE;
	p_MESSAGE := p_MESSAGE || 'ERROR OCCURED IN MM_PJM_ESCHED.IMPORT_SCHEDULES: ' || UT.GET_FULL_ERRM;
END IMPORT_SCHEDULES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULES
	(
	p_CRED IN mex_credentials,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOG_ONLY IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER  IN OUT mm_logger_adapter
	) AS
	v_CLOB CLOB;
	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
	v_RECORDS MEX_PJM_ESCHED_SCHEDULE_TBL;
BEGIN
	p_STATUS := GA.SUCCESS;

	IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_ESCHED_ATTR, p_CRED.EXTERNAL_ACCOUNT_NAME) THEN

		v_PARAMS(MEX_PJM.c_Report_Type) := g_SCHEDULES_RPTTYPE;
		v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
		MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS, 'esched', -- p_REQUEST_APP
							p_LOGGER,
							p_CRED,
							p_BEGIN_DATE,
							p_END_DATE,
							'download',  -- p_REQUEST_DIR
							v_CLOB,
							p_STATUS,
							p_MESSAGE,
							p_LOG_ONLY );
		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
			IMPORT_SCHEDULES(p_CRED.EXTERNAL_ACCOUNT_NAME, v_CLOB, p_STATUS, p_MESSAGE, p_LOGGER);
		END IF;
	END IF;

END IMPORT_SCHEDULES;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_RECON_DATA(p_RECORDS IN MEX_PJM_RECON_DATA_TBL,
                            p_ISO_NAME IN VARCHAR2,
                            p_STATUS OUT NUMBER,
                            p_MESSAGE OUT VARCHAR2) AS

v_HOUR NUMBER;
v_DATE DATE;
v_RECON_AMT NUMBER;
v_LAST_CONTRACT_ID VARCHAR2(32) := 0;
v_SCHED_CONTRACT_ID VARCHAR2(32);
v_CONTRACT_ID NUMBER(9);
v_INDEX          BINARY_INTEGER;
v_TRANSACTION_ID NUMBER;
v_RECON_TRANSACTION_ID NUMBER;
v_FORECAST_AMT NUMBER;
v_PSE_NAME VARCHAR2(64);
v_COMMODITY_ID NUMBER(9);
v_POD_ID INTERCHANGE_TRANSACTION.POD_ID%TYPE;

BEGIN
    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP
        v_SCHED_CONTRACT_ID := p_RECORDS(v_INDEX).ContractID;
        v_DATE        := p_RECORDS(v_INDEX).ReconDate;
        v_HOUR        := p_RECORDS(v_INDEX).EndHour;
        v_RECON_AMT   := NVL(p_RECORDS(v_INDEX).ReconAmount, 0);

        --get billing entity from external credential
        v_CONTRACT_ID := GET_INTERCHANGE_CONTRACT(p_ISO_NAME);
        SELECT P.PSE_NAME INTO v_PSE_NAME
        FROM PURCHASING_SELLING_ENTITY P, INTERCHANGE_CONTRACT C
        WHERE C.CONTRACT_ID = v_CONTRACT_ID
        AND P.PSE_ID = C.BILLING_ENTITY_ID;

		IF v_SCHED_CONTRACT_ID <> v_LAST_CONTRACT_ID THEN
				-- get transaction IDs for putting data
					-- for normal transaction
            --v_TRANSACTION_ID := MM_PJM_UTIL.GET_TRANSACTION_ID(v_CONTRACT_ID, v_DATE);
            v_TRANSACTION_ID := GET_TX_ID(v_SCHED_CONTRACT_ID,NULL,NULL,
                                            NULL, NULL, v_CONTRACT_ID);

            SELECT POD_ID INTO v_POD_ID FROM INTERCHANGE_TRANSACTION
            WHERE TRANSACTION_ID = v_TRANSACTION_ID;


            v_LAST_CONTRACT_ID := v_SCHED_CONTRACT_ID;

			/*	IF v_TRANSACTION_ID = -1 THEN
					v_TRANSACTION_ID := NULL;
				END IF;
					-- and for special 'recon' transaction
            	BEGIN
                    SELECT IT.TRANSACTION_ID
                      INTO v_RECON_TRANSACTION_ID
                      FROM INTERCHANGE_TRANSACTION IT
                     WHERE UPPER(IT.TRANSACTION_IDENTIFIER) = ('PJM-RECON: ' || v_CONTRACT_ID);
            	EXCEPTION
            		WHEN NO_DATA_FOUND THEN
            			v_RECON_TRANSACTION_ID := NULL;
            	END;*/
		END IF;

        ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_COMMODITY_ID);

        v_RECON_TRANSACTION_ID := GET_TX_ID('PJM-RECON: ' || v_SCHED_CONTRACT_ID,
                                  'ReconciledMW',
                                  'Reconciliation MW: ' || v_SCHED_CONTRACT_ID,
                                  'Hour',
                                  v_COMMODITY_ID,
                                  v_CONTRACT_ID, 0,
                                  v_POD_ID);


        IF TRUNC(v_DATE) = TRUNC(DST_SPRING_AHEAD_DATE(v_DATE)) THEN
            IF v_HOUR = 2 THEN
		        v_HOUR := 3; -- in RO we skip hour 2 of the spring-ahead date - PJM skips hour 3
	        ELSIF v_HOUR = 3 THEN
		        v_DATE := NULL; -- skip 3rd hour
	        END IF;
        END IF;

        IF v_DATE IS NOT NULL THEN
            IF v_HOUR = 25 THEN
                -- 25th hour represents the second hour-two
                v_DATE := v_DATE + 2 / 24 + (1 / (24 * 60 * 60));
            ELSE
                v_DATE := v_DATE + v_HOUR / 24;
            END IF;
            v_DATE := TO_CUT(v_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE);

	/*			-- Put value + Forecast into Final statement type
				If v_TRANSACTION_ID is not null Then
                    --               get the forecast value

                    SELECT NVL(SUM(ITS.AMOUNT), 0)
                      INTO v_FORECAST_AMT
                      FROM IT_SCHEDULE ITS
                     WHERE ITS.TRANSACTION_ID = v_TRANSACTION_ID
                       AND ITS.SCHEDULE_TYPE = 1
                       AND ITS.SCHEDULE_STATE = MM_PJM_UTIL.g_EXTERNAL_STATE
                       AND ITS.SCHEDULE_DATE = v_DATE
                       AND ITS.AS_OF_DATE =
                           (SELECT MAX(AS_OF_DATE)
                              FROM IT_SCHEDULE
                             WHERE TRANSACTION_ID = ITS.TRANSACTION_ID
                               AND SCHEDULE_TYPE = ITS.SCHEDULE_TYPE
                               AND SCHEDULE_STATE = ITS.SCHEDULE_STATE
                               AND SCHEDULE_DATE = ITS.SCHEDULE_DATE);
                    -- INSERTING FINAL VALUE (IE. SUM OF FORECAST AND RECONCILED VALUES)
                    ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                                       3, -- SCHEDULE TYPE
                                       MM_PJM_UTIL.g_EXTERNAL_STATE, -- SCHEDULE STATE
                                       v_DATE,
                                       SYSDATE, --AS OF DATE
                                       v_FORECAST_AMT + v_RECON_AMT,
                                       NULL,
                                       p_STATUS);
				END IF;*/

                    -- INSERTING RECONCILED VALUE ONLY FOR BOTH INTERNAL AND EXTERNAL STATES
                IF v_RECON_TRANSACTION_ID IS NOT NULL THEN
                    PUT_SCHEDULE_VALUE(v_RECON_TRANSACTION_ID, v_DATE, v_RECON_AMT);

				END IF;
			END IF;

            v_INDEX := p_RECORDS.NEXT(v_INDEX);

        END LOOP;

        COMMIT;

END PUT_RECON_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_RECON_DATA(p_CRED       IN MEX_CREDENTIALS,
							p_BEGIN_DATE IN DATE,
                            p_END_DATE   IN DATE,
                            p_LOG_ONLY	 IN NUMBER,
							p_STATUS     OUT NUMBER,
                            p_MESSAGE    OUT VARCHAR2,
							p_LOGGER	 IN OUT mm_logger_adapter) AS
    v_RECORDS 		MEX_PJM_RECON_DATA_TBL;
    v_RECONCIL_LAG 	BINARY_INTEGER;
    v_BEGIN_DATE 	DATE;
    v_END_DATE 		DATE;
    v_CONTRACT_ID 	NUMBER;

BEGIN
    p_STATUS := GA.SUCCESS;
    IF p_STATUS < 0 THEN
        RETURN;
    END IF;

-- first grab the eSchedule values - these are the basis for
-- reconciliation so we want to make sure they are up to date
--IMPORT_SCHEDULES(p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE);
    --IF p_STATUS < 0 THEN
        --RETURN;
    --END IF;
    IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_ESCHED_ATTR, p_CRED.EXTERNAL_ACCOUNT_NAME) THEN
        IF p_END_DATE = LOW_DATE THEN
            --GET CONTRACT FROM CREDENTIALS
            v_CONTRACT_ID := GET_INTERCHANGE_CONTRACT(p_CRED.EXTERNAL_ACCOUNT_NAME);
            v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
            IF v_RECONCIL_LAG = 0 THEN v_RECONCIL_LAG := 3; END IF;
            v_BEGIN_DATE := TRUNC(p_BEGIN_DATE, 'MM') - NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_END_DATE := LAST_DAY(v_BEGIN_DATE);
        ELSE
            v_BEGIN_DATE := p_END_DATE;
            v_END_DATE := p_END_DATE;
        END IF;

        MEX_PJM_ESCHED.FETCH_RECON_DATA(v_BEGIN_DATE,
                                    v_END_DATE,
									p_CRED,
									p_LOGGER,
									p_LOG_ONLY,
                                    v_RECORDS,
                                    p_STATUS,
                                    p_MESSAGE);
        IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
            -- put the reconciled values in the database
            PUT_RECON_DATA(v_RECORDS, p_CRED.EXTERNAL_ACCOUNT_NAME, p_STATUS, p_MESSAGE);
        END IF;
    END IF;

END IMPORT_RECON_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_REAL_TIME_DAILY_TX_MSRS
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_RECORDS IN MEX_PJM_DAILY_TX_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_HOUR           NUMBER;
	v_DATE           DATE;
	v_AMT      		 NUMBER;
	v_INDEX          BINARY_INTEGER;
	v_TRANSACTION_ID NUMBER;
	v_TRANSACTION_TYPE VARCHAR2(16);

BEGIN

	v_INDEX := p_RECORDS.FIRST;

	WHILE p_RECORDS.EXISTS(v_INDEX) LOOP
       	-- for now, we are only interested in extracting inadvertant and 500kv losses
		v_TRANSACTION_ID := NULL;
			--Bring this data in if the Transaction already exists.
        IF p_RECORDS(v_INDEX).TRANSACTION_TYPE LIKE '%eMTR Allocated EHV Losses%' THEN
        BEGIN
        	SELECT IT.TRANSACTION_ID
        	 INTO v_TRANSACTION_ID
        	 FROM INTERCHANGE_TRANSACTION IT,
        	      SCHEDULE_COORDINATOR    SC
        	WHERE IT.TRANSACTION_TYPE = '500kV Losses'
        	  AND SC.SC_EXTERNAL_IDENTIFIER = 'PJM'
        	  AND IT.SC_ID = SC.SC_ID;
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
        		v_TRANSACTION_ID := NULL;
        END;
        --Bring in Adj Net Metered Interchange.
        ELSIF p_RECORDS(v_INDEX).TRANSACTION_TYPE LIKE '%Adjusted Net Metered Interchange%' THEN
        v_TRANSACTION_ID := GET_RT_NET_INTERCHANGE_TX_ID(p_EXTERNAL_ACCOUNT_NAME,
        	'Adj Net Mtrd Int',
        	'PJM Adj Net Metered Interchange: ',
        	p_RECORDS(v_INDEX).TRANSACTION_DATE);
			IF v_TRANSACTION_ID <= 0 THEN v_TRANSACTION_ID := NULL; END IF;

		--Bring in the Real-Time Net Interchange.
		ELSIF p_RECORDS(v_INDEX).TRANSACTION_TYPE = 'RT Net Interchange' THEN
			v_TRANSACTION_ID := GET_RT_NET_INTERCHANGE_TX_ID(p_EXTERNAL_ACCOUNT_NAME,
				'Net Interchange',
				'PJM Real-Time Net Interchange: ',
				p_RECORDS(v_INDEX).TRANSACTION_DATE);
			IF v_TRANSACTION_ID <= 0 THEN v_TRANSACTION_ID := NULL; END IF;
		ELSE --TRANSACTION_TYPE is not null
			--If we have credentials to identify our contract, and if our Transaction
			--has the PopulateFromRTDailyTx Attribute set to TRUE, then we want
			--to populate IT_SCHEDULE from the RTDailyTx report rather than eSchedule.
			IF p_RECORDS(v_INDEX).TRANSACTION_ID IS NOT NULL AND p_EXTERNAL_ACCOUNT_NAME IS NOT NULL THEN
				v_TRANSACTION_ID := GET_TRANSACTION_ID(p_EXTERNAL_ACCOUNT_NAME, p_RECORDS(v_INDEX).TRANSACTION_ID, p_RECORDS(v_INDEX).TRANSACTION_DATE, 1);
				IF v_TRANSACTION_ID <= 0 THEN v_TRANSACTION_ID := NULL; END IF;
			END IF;
		END IF;

		IF V_TRANSACTION_ID IS NOT NULL THEN

			v_DATE  := p_RECORDS(v_INDEX).TRANSACTION_DATE;
			v_HOUR  := p_RECORDS(v_INDEX).HOUR_ENDING;

			SELECT TRANSACTION_TYPE INTO v_TRANSACTION_TYPE
			FROM INTERCHANGE_TRANSACTION
			WHERE TRANSACTION_ID = v_TRANSACTION_ID;

			IF v_TRANSACTION_TYPE = 'Purchase' THEN
				v_AMT   := ABS(p_RECORDS(v_INDEX).Amount);
			ELSE
				v_AMT   := p_RECORDS(v_INDEX).Amount;
			END IF;

	    	IF TRUNC(v_DATE) = TRUNC(DST_SPRING_AHEAD_DATE(v_DATE)) THEN
				IF v_HOUR = 2 THEN
					v_HOUR := 3; -- in RO we skip hour 2 of the spring-ahead date - PJM skips hour 3
				ELSIF v_HOUR = 3 THEN
					v_DATE := NULL; -- skip 3rd hour
				END IF;
			END IF;

			IF v_DATE IS NOT NULL THEN
				IF v_HOUR = 25 THEN
					-- 25th hour represents the second hour-two
					v_DATE := v_DATE + 2 / 24 + (1 / (24 * 60 * 60));
				ELSE
					v_DATE := v_DATE + v_HOUR / 24;
				END IF;
				v_DATE := TO_CUT(v_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE);

   				-- put into both internal and external state

				ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                                      1, -- SCHEDULE TYPE
                                      MM_PJM_UTIL.g_EXTERNAL_STATE, -- SCHEDULE STATE
                                      v_DATE,
                                      SYSDATE, --AS OF DATE
                                      v_AMT,
                                      NULL,
                                      p_STATUS);
				ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                                      1, -- SCHEDULE TYPE
                                      MM_PJM_UTIL.g_INTERNAL_STATE, -- SCHEDULE STATE
                                      v_DATE,
                                      SYSDATE, --AS OF DATE
                                      v_AMT,
                                      NULL,
                                      p_STATUS);
			END IF;

		END IF;

		v_INDEX := p_RECORDS.NEXT(v_INDEX);

	END LOOP;

	COMMIT;

END PUT_REAL_TIME_DAILY_TX_MSRS;
-----------------------------------------------------------------------------------------------------
PROCEDURE PUT_REAL_TIME_DAILY_TX
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_RECORDS IN MEX_PJM_DAILY_TX_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_HOUR           NUMBER;
	v_DATE           DATE;
	v_AMT      		 NUMBER;
	v_INDEX          BINARY_INTEGER;
	v_TRANSACTION_ID NUMBER;
	v_TRANSACTION_TYPE VARCHAR2(16);

BEGIN

	v_INDEX := p_RECORDS.FIRST;

	WHILE p_RECORDS.EXISTS(v_INDEX) LOOP
       	-- for now, we are only interested in extracting inadvertant and 500kv losses
		v_TRANSACTION_ID := NULL;
		IF p_RECORDS(v_INDEX).TRANSACTION_TYPE IS NULL THEN
			--Bring this data in if the Transaction already exists.
			IF UPPER(p_RECORDS(v_INDEX).TRANSACTION_ID) LIKE '%ALLOCATED 500KV LOSS%' THEN
				BEGIN
					SELECT IT.TRANSACTION_ID
					 INTO v_TRANSACTION_ID
					 FROM INTERCHANGE_TRANSACTION IT,
					      SCHEDULE_COORDINATOR    SC
					WHERE IT.TRANSACTION_TYPE = '500kV Losses'
					  AND SC.SC_EXTERNAL_IDENTIFIER = 'PJM'
					  AND IT.SC_ID = SC.SC_ID;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						v_TRANSACTION_ID := NULL;
				END;
			--Bring this data in if the Transaction already exists.
			ELSIF Upper(p_RECORDS(v_INDEX).TRANSACTION_ID) like '%ALLOCATED INADVERT%' THEN
				BEGIN
					SELECT IT.TRANSACTION_ID
					INTO v_TRANSACTION_ID
					FROM INTERCHANGE_TRANSACTION IT,
						SCHEDULE_COORDINATOR    SC
					WHERE IT.TRANSACTION_TYPE = 'Net Inadvertant'
						AND SC.SC_EXTERNAL_IDENTIFIER = 'PJM'
						AND IT.SC_ID = SC.SC_ID;
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						v_TRANSACTION_ID := NULL;
				END;
			--Bring in Adj Net Metered Interchange.
			ELSIF UPPER(p_RECORDS(v_INDEX).TRANSACTION_ID) LIKE '%ADJ NET METERED INTERCHANGE%' THEN
				v_TRANSACTION_ID := GET_RT_NET_INTERCHANGE_TX_ID(p_EXTERNAL_ACCOUNT_NAME,
					'Adj Net Mtrd Int',
					'PJM Adj Net Metered Interchange: ',
					p_RECORDS(v_INDEX).TRANSACTION_DATE);
				IF v_TRANSACTION_ID <= 0 THEN v_TRANSACTION_ID := NULL; END IF;
			END IF;
		--Bring in the Real-Time Net Interchange.
		ELSIF p_RECORDS(v_INDEX).TRANSACTION_TYPE = 'REAL-TIME NET INTERCHANGE' THEN
			v_TRANSACTION_ID := GET_RT_NET_INTERCHANGE_TX_ID(p_EXTERNAL_ACCOUNT_NAME,
				'Net Interchange',
				'PJM Real-Time Net Interchange: ',
				p_RECORDS(v_INDEX).TRANSACTION_DATE);
			IF v_TRANSACTION_ID <= 0 THEN v_TRANSACTION_ID := NULL; END IF;
		ELSE --TRANSACTION_TYPE is not null
			--If we have credentials to identify our contract, and if our Transaction
			--has the PopulateFromRTDailyTx Attribute set to TRUE, then we want
			--to populate IT_SCHEDULE from the RTDailyTx report rather than eSchedule.
			IF p_RECORDS(v_INDEX).TRANSACTION_ID IS NOT NULL AND p_EXTERNAL_ACCOUNT_NAME IS NOT NULL THEN
				v_TRANSACTION_ID := GET_TRANSACTION_ID(p_EXTERNAL_ACCOUNT_NAME, p_RECORDS(v_INDEX).TRANSACTION_ID, p_RECORDS(v_INDEX).TRANSACTION_DATE, 1);
				IF v_TRANSACTION_ID <= 0 THEN v_TRANSACTION_ID := NULL; END IF;
			END IF;
		END IF;

		IF V_TRANSACTION_ID IS NOT NULL THEN

			v_DATE  := p_RECORDS(v_INDEX).TRANSACTION_DATE;
			v_HOUR  := p_RECORDS(v_INDEX).HOUR_ENDING;

			SELECT TRANSACTION_TYPE INTO v_TRANSACTION_TYPE
			FROM INTERCHANGE_TRANSACTION
			WHERE TRANSACTION_ID = v_TRANSACTION_ID;

			IF v_TRANSACTION_TYPE = 'Purchase' THEN
				v_AMT   := ABS(p_RECORDS(v_INDEX).Amount);
			ELSE
				v_AMT   := p_RECORDS(v_INDEX).Amount;
			END IF;

	    	IF TRUNC(v_DATE) = TRUNC(DST_SPRING_AHEAD_DATE(v_DATE)) THEN
				IF v_HOUR = 2 THEN
					v_HOUR := 3; -- in RO we skip hour 2 of the spring-ahead date - PJM skips hour 3
				ELSIF v_HOUR = 3 THEN
					v_DATE := NULL; -- skip 3rd hour
				END IF;
			END IF;

			IF v_DATE IS NOT NULL THEN
				IF v_HOUR = 25 THEN
					-- 25th hour represents the second hour-two
					v_DATE := v_DATE + 2 / 24 + (1 / (24 * 60 * 60));
				ELSE
					v_DATE := v_DATE + v_HOUR / 24;
				END IF;
				v_DATE := TO_CUT(v_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE);

   				-- put into both internal and external state

				ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                                      1, -- SCHEDULE TYPE
                                      MM_PJM_UTIL.g_EXTERNAL_STATE, -- SCHEDULE STATE
                                      v_DATE,
                                      SYSDATE, --AS OF DATE
                                      v_AMT,
                                      NULL,
                                      p_STATUS);
				ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                                      1, -- SCHEDULE TYPE
                                      MM_PJM_UTIL.g_INTERNAL_STATE, -- SCHEDULE STATE
                                      v_DATE,
                                      SYSDATE, --AS OF DATE
                                      v_AMT,
                                      NULL,
                                      p_STATUS);
			END IF;

		END IF;

		v_INDEX := p_RECORDS.NEXT(v_INDEX);

	END LOOP;

	COMMIT;

END PUT_REAL_TIME_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ESCHED_W_WO_LOSSES
	(
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
    p_RECORDS IN MEX_PJM_DAILY_TX_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

v_HOUR NUMBER;
v_DATE DATE;
v_TRANSACTION_ID NUMBER;
v_IDX BINARY_INTEGER;

BEGIN
    v_IDX := p_RECORDS.FIRST;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP

        v_TRANSACTION_ID := GET_TXN_ID_FOR_LOAD_W_WO_LOSS(p_EXTERNAL_ACCOUNT_NAME,
                                                p_RECORDS(v_IDX).TRANSACTION_ID,
                                                p_RECORDS(v_IDX).TRANSACTION_DATE,
                                                NVL(p_RECORDS(v_IDX).STATUS,'LOAD WITHOUT LOSSES'),
												TRUE);
        IF v_TRANSACTION_ID <= 0 THEN v_TRANSACTION_ID := NULL; END IF;
            IF v_TRANSACTION_ID IS NOT NULL THEN
                v_DATE  := p_RECORDS(v_IDX).TRANSACTION_DATE;
                v_HOUR  := p_RECORDS(v_IDX).HOUR_ENDING;

		    	IF TRUNC(v_DATE) = TRUNC(DST_SPRING_AHEAD_DATE(v_DATE)) THEN
					IF v_HOUR = 2 THEN
						v_HOUR := 3; -- in RO we skip hour 2 of the spring-ahead date - PJM skips hour 3
					ELSIF v_HOUR = 3 THEN
						v_DATE := NULL; -- skip 3rd hour
					END IF;
				END IF;

				IF v_DATE IS NOT NULL THEN
                    IF v_HOUR = 25 THEN
                        -- 25th hour represents the second hour-two
                        v_DATE := v_DATE + 2 / 24 + (1 / (24 * 60 * 60));
                    ELSE
                        v_DATE := v_DATE + v_HOUR / 24;
                    END IF;
                    v_DATE := TO_CUT(v_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE);

    				-- put into both internal and external state

                    ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                                       1, -- SCHEDULE TYPE
                                       MM_PJM_UTIL.g_EXTERNAL_STATE, -- SCHEDULE STATE
                                       v_DATE,
                                       SYSDATE,
                                       p_RECORDS(v_IDX).Amount,
                                       NULL,
                                       p_STATUS);
                    ITJ.PUT_IT_SCHEDULE(v_TRANSACTION_ID,
                                       1, -- SCHEDULE TYPE
                                       MM_PJM_UTIL.g_INTERNAL_STATE, -- SCHEDULE STATE
                                       v_DATE,
                                       SYSDATE,
                                       p_RECORDS(v_IDX).Amount,
                                       NULL,
                                       p_STATUS);
				END IF;

			END IF;

            v_IDX := p_RECORDS.NEXT(v_IDX);

        END LOOP;

        COMMIT;

END IMPORT_ESCHED_W_WO_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REAL_TIME_DAILY_TX_MSRS(p_CRED   IN MEX_CREDENTIALS,
								p_BEGIN_DATE IN DATE,
                                p_END_DATE   IN DATE,
								p_LOG_ONLY		IN NUMBER,
                                p_STATUS     OUT NUMBER,
                                p_MESSAGE    OUT VARCHAR2,
								p_LOGGER     IN OUT   MM_LOGGER_ADAPTER) AS
	v_RECORDS MEX_PJM_DAILY_TX_TBL;

BEGIN
	MEX_PJM_ESCHED.FETCH_REAL_TIME_DAILY_TX_MSRS(p_BEGIN_DATE,
                                				p_END_DATE,
                                				p_CRED,
                                				p_LOGGER,
                                				p_LOG_ONLY,
                                				v_RECORDS,
                                				p_STATUS,
                                				p_MESSAGE);
	IF p_STATUS = GA.SUCCESS THEN
		PUT_REAL_TIME_DAILY_TX_MSRS(p_CRED.EXTERNAL_ACCOUNT_NAME, v_RECORDS, p_STATUS, p_MESSAGE);
	END IF;

END IMPORT_REAL_TIME_DAILY_TX_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REAL_TIME_DAILY_TX_BOTH
    (
    p_CRED   IN MEX_CREDENTIALS,
	p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_LOG_ONLY		IN NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2,
    p_LOGGER     IN OUT   MM_LOGGER_ADAPTER
    ) AS
	v_RECORDS MEX_PJM_DAILY_TX_TBL;

BEGIN
	MEX_PJM_ESCHED.FETCH_REAL_TIME_DAILY_TX_MSRS(p_BEGIN_DATE,
                                				p_END_DATE,
                                				p_CRED,
                                				p_LOGGER,
                                				p_LOG_ONLY,
                                				v_RECORDS,
                                				p_STATUS,
                                				p_MESSAGE);
	IF p_STATUS = GA.SUCCESS THEN
		PUT_REAL_TIME_DAILY_TX_MSRS(p_CRED.EXTERNAL_ACCOUNT_NAME, v_RECORDS, p_STATUS, p_MESSAGE);
        MM_PJM_SETTLEMENT_MSRS.IMPORT_RT_DAILY_TX(v_RECORDS, p_STATUS);
	END IF;

END IMPORT_REAL_TIME_DAILY_TX_BOTH;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REAL_TIME_DAILY_TX(p_CRED   IN MEX_CREDENTIALS,
								p_BEGIN_DATE IN DATE,
                                p_END_DATE   IN DATE,
								p_LOG_ONLY		IN NUMBER,
                                p_STATUS     OUT NUMBER,
                                p_MESSAGE    OUT VARCHAR2,
								p_LOGGER     IN OUT   MM_LOGGER_ADAPTER) AS
	v_RECORDS MEX_PJM_DAILY_TX_TBL;

BEGIN
	MEX_PJM_ESCHED.FETCH_REAL_TIME_DAILY_TX(p_BEGIN_DATE,
				p_END_DATE,
				p_CRED,
				p_LOGGER,
				p_LOG_ONLY,
				v_RECORDS,
				p_STATUS,
				p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		PUT_REAL_TIME_DAILY_TX(p_CRED.EXTERNAL_ACCOUNT_NAME, v_RECORDS, p_STATUS, p_MESSAGE);
	END IF;

END IMPORT_REAL_TIME_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REAL_TIME_DAILY_TX(p_CSV IN CLOB,
	p_STATUS     OUT NUMBER,
	p_MESSAGE    OUT VARCHAR2) AS

    v_RECORDS MEX_PJM_DAILY_TX_TBL;
BEGIN
	MEX_PJM_ESCHED.PARSE_REAL_TIME_DAILY_TX(p_CSV,
	                           v_RECORDS,
	                           p_STATUS,
	                           p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		-- put the reconciled values in the database
		PUT_REAL_TIME_DAILY_TX(NULL, v_RECORDS, p_STATUS, p_MESSAGE);
	END IF;

END IMPORT_REAL_TIME_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REAL_TIME_DAILY_TX_MSRS
    (
    p_CSV IN CLOB,
	p_STATUS     OUT NUMBER,
	p_MESSAGE    OUT VARCHAR2
    ) AS
v_RECORDS MEX_PJM_DAILY_TX_TBL;
BEGIN
	MEX_PJM_ESCHED.PARSE_REAL_TIME_DAILY_TX_MSRS
                                (
                                p_CSV,
	                            v_RECORDS,
	                            p_STATUS,
	                            p_MESSAGE);
	IF p_STATUS = GA.SUCCESS THEN
		PUT_REAL_TIME_DAILY_TX_MSRS(NULL, v_RECORDS, p_STATUS, p_MESSAGE);
	END IF;

END IMPORT_REAL_TIME_DAILY_TX_MSRS;
-----------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CONTRACTS
	(
	p_RECORDS       IN MEX_ESCHED_CONTRACT_TBL,
	p_EXTERNAL_ACCOUNT_NAME	IN VARCHAR2,
	p_COPY_INTERNAL IN BOOLEAN,
	p_STATUS        OUT NUMBER,
	p_MESSAGE       OUT VARCHAR2
	) AS

	v_TX_ROW INTERCHANGE_TRANSACTION%ROWTYPE;
	v_IDX BINARY_INTEGER;
	v_PSE_ID PSE.PSE_ID%TYPE;
	v_PSE_NAME PSE.PSE_NAME%TYPE;
	v_TX_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	v_TX_STATUS INTERCHANGE_TRANSACTION_STATUS.TRANSACTION_STATUS_NAME%TYPE;
	v_IS_DAYAHEAD BOOLEAN;
    v_TXN_CHANGED BINARY_INTEGER := 0;
    v_IS_ACTIVE NUMBER(1);
    v_IT_STATUS_ROW IT_STATUS%ROWTYPE;
    v_TXN_CREATED BOOLEAN;
	
	-- given an eSchedule contract ID, return the transaction ID
	-- having that contract ID as the transaction identifier.
	FUNCTION GET_TXN_ID(p_TXN_ROW IN INTERCHANGE_TRANSACTION%ROWTYPE)
	RETURN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE IS
		v_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	BEGIN
		SELECT TRANSACTION_ID
		INTO v_ID
		FROM INTERCHANGE_TRANSACTION
		WHERE TRANSACTION_IDENTIFIER = p_TXN_ROW.Transaction_Identifier
			AND CONTRACT_ID = p_TXN_ROW.CONTRACT_ID;
		RETURN v_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
    WHEN TOO_MANY_ROWS THEN
		ERRS.LOG_AND_CONTINUE(p_EXTRA_MESSAGE => 'Get txn ID for acct ' || p_EXTERNAL_ACCOUNT_NAME || ', contract ' || p_TXN_ROW.Transaction_Identifier);
      RETURN 0;
	END GET_TXN_ID;

	PROCEDURE SET_NAME_AND_IDENT_INFO
		(
		p_TRANSACTION IN OUT INTERCHANGE_TRANSACTION%ROWTYPE,
		p_IS_RT_COPY_OF_DA_CONTRACT IN BOOLEAN
		) AS
		v_CONTRACT_NUMBER VARCHAR2(64);
	BEGIN
		-- Add an RT if we are rolling forward a true DA Contract to RT.
		IF p_IS_RT_COPY_OF_DA_CONTRACT THEN
			v_CONTRACT_NUMBER := p_RECORDS(v_IDX).CONTRACT_ID || 'RT';
		ELSE
			v_CONTRACT_NUMBER := p_RECORDS(v_IDX).CONTRACT_ID;
		END IF;

		p_TRANSACTION.TRANSACTION_NAME  := v_PSE_NAME || ':' || v_CONTRACT_NUMBER || ':' || NVL(p_RECORDS(v_IDX).CONTRACT_NAME, '');
		p_TRANSACTION.TRANSACTION_ALIAS := v_PSE_NAME || ':' || v_CONTRACT_NUMBER;
		p_TRANSACTION.TRANSACTION_IDENTIFIER := v_CONTRACT_NUMBER;
	END SET_NAME_AND_IDENT_INFO;

BEGIN
	p_STATUS := GA.SUCCESS;

	-- get the PSE id based on the external credentials
	v_PSE_ID := MM_PJM_UTIL.GET_PSE(p_EXTERNAL_ACCOUNT_NAME);
	IF v_PSE_ID IS NULL THEN
		LOGS.LOG_ERROR('No PSE found with name ' || p_EXTERNAL_ACCOUNT_NAME);
		p_STATUS  := GA.NO_DATA_FOUND;
		p_MESSAGE := 'No PSE found for ' || p_EXTERNAL_ACCOUNT_NAME || ', check App Event Log ' ||
		             'and Exchange Log';
		RETURN;
	END IF;

	SELECT PSE_NAME INTO v_PSE_NAME FROM PSE WHERE PSE_ID = v_PSE_ID;
	v_IDX := p_RECORDS.FIRST();

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('IMPORTING CONTRACT NUMBER ' || p_RECORDS(v_IDX).CONTRACT_ID);
		END IF;

		SET_NAME_AND_IDENT_INFO(v_TX_ROW, FALSE);
		v_TXN_CREATED := FALSE;

		-- because we can have a system where we're managing both sides of a bilateral,
		-- the transaction external identifier needs to include the relevant PSE's PJM ID
		-- as well as the PJM contract ID
		v_TX_ROW.BEGIN_DATE             := p_RECORDS(v_IDX).START_DATE;
		v_TX_ROW.SELLER_ID              := GET_PSE_FROM_OBJECT_MAP(p_RECORDS(v_IDX).SELLER_NAME);
		v_TX_ROW.PURCHASER_ID           := GET_PSE_FROM_OBJECT_MAP(p_RECORDS(v_IDX).BUYER_NAME);
		v_TX_ROW.SOURCE_ID              := GET_SERVICE_POINT(p_RECORDS(v_IDX).SOURCE);
		v_TX_ROW.SINK_ID                := GET_SERVICE_POINT(p_RECORDS(v_IDX).SINK);
		v_TX_ROW.POR_ID                 := v_TX_ROW.SOURCE_ID;
		v_TX_ROW.POD_ID                 := v_TX_ROW.SINK_ID;
		v_TX_ROW.TRANSACTION_INTERVAL   := 'Hour';
		v_TX_ROW.EXTERNAL_INTERVAL      := 'Hour';
		v_TX_ROW.IS_BID_OFFER           := 1;
		v_TX_ROW.IS_IMPORT_EXPORT       := 0;
		v_TX_ROW.SC_ID                  := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM); --MM_PJM_UTIL.g_PJM_SC_ID;
		v_TX_ROW.Agreement_Type := p_RECORDS(v_IDX).SERVICE_TYPE;

		-- note that MEX can truncate the comment if it's greater than 256 chars long
		v_TX_ROW.TRANSACTION_DESC       := p_RECORDS(v_IDX).COMMENTS;

		IF p_RECORDS(v_IDX).CONFIRMED_STOP_DATE IS NULL THEN
			v_TX_ROW.END_DATE := p_RECORDS(v_IDX).PENDING_STOP_DATE;
		ELSIF p_RECORDS(v_IDX).PENDING_STOP_DATE IS NULL THEN
			v_TX_ROW.END_DATE := p_RECORDS(v_IDX).CONFIRMED_STOP_DATE;
			-- if there's no pending date, then this contract is confirmed by both sides
			v_TX_STATUS := 'Approved';
		ELSE
			IF p_RECORDS(v_IDX).CONFIRMED_STOP_DATE > p_RECORDS(v_IDX).PENDING_STOP_DATE THEN
				v_TX_ROW.END_DATE := p_RECORDS(v_IDX).CONFIRMED_STOP_DATE;
			ELSE
				v_TX_ROW.END_DATE := p_RECORDS(v_IDX).PENDING_STOP_DATE;
			END IF;
		END IF;

		IF p_RECORDS(v_IDX).DAY_AHEAD_FLAG = 'YES' THEN
			v_IS_DAYAHEAD := TRUE;
			v_TX_ROW.COMMODITY_ID := MM_PJM_UTIL.GET_COMMODITY_ID(MM_PJM_UTIL.g_COMM_DA_ENERGY);
		ELSE
			v_IS_DAYAHEAD := FALSE;
			v_TX_ROW.COMMODITY_ID := MM_PJM_UTIL.GET_COMMODITY_ID(MM_PJM_UTIL.g_COMM_RT_ENERGY);
		END IF;

		IF v_TX_ROW.SELLER_ID = v_PSE_ID THEN
			v_TX_ROW.TRANSACTION_TYPE := g_TXN_TYPE_SALE;
		ELSE
			v_TX_ROW.TRANSACTION_TYPE := g_TXN_TYPE_PURCHASE;
		END IF;

		v_TX_ROW.CONTRACT_ID := GET_INTERCHANGE_CONTRACT(p_EXTERNAL_ACCOUNT_NAME);

		-- if there's a non-null pending stop date, then the contract needs confirmation
		-- by "me" or the counterparty (CP). As near as I can figure out, here's the business rules:
		-- approval required by me if:
		--   I am seller and last seller update is null
		--   I am buyer and last buyer update is null
		--   last buyer update and last seller update are NOT null:
		--      I am seller and last seller update < last buyer update
		--      I am buyer and last buyer update < last seller update
		-- Otherwise, CP approval is required.
		-- Note that we've taken care of the case where no approval is required already.
		IF p_RECORDS(v_IDX).PENDING_STOP_DATE IS NOT NULL THEN
			IF p_RECORDS(v_IDX).SELLER_UPDATE_TIME IS NULL AND v_TX_ROW.Seller_Id = v_PSE_ID THEN
				v_TX_STATUS := 'Requires Apvl';
			ELSIF p_RECORDS(v_IDX).BUYER_UPDATE_TIME IS NULL AND v_TX_ROW.Purchaser_Id = v_PSE_ID THEN
				v_TX_STATUS := 'Requires Apvl';
			ELSIF v_TX_ROW.Seller_Id = v_PSE_ID AND p_RECORDS(v_IDX).SELLER_UPDATE_TIME < p_RECORDS(v_IDX).BUYER_UPDATE_TIME THEN
				v_TX_STATUS := 'Requires Apvl';
			ELSIF v_TX_ROW.Purchaser_Id = v_PSE_ID AND p_RECORDS(v_IDX).BUYER_UPDATE_TIME < p_RECORDS(v_IDX).SELLER_UPDATE_TIME THEN
				v_TX_STATUS := 'Requires Apvl';
			ELSE
				v_TX_STATUS := 'Pending CP Apvl';
			END IF;
			-- post a notification that the contract hasn't been confirmed
			ALERTS.TRIGGER_ALERTS(g_UNCONFIRMED_CONTRACT_ALERT, LOGS.c_Level_Notice, v_TX_ROW.TRANSACTION_NAME || ' is not confirmed');
		END IF;


		v_TX_ROW.TRANSACTION_ID := GET_TXN_ID(v_TX_ROW);
        IF v_TX_ROW.TRANSACTION_ID <> 0 THEN 
            v_TXN_CHANGED := GET_IS_TXN_CHANGED(v_TX_ROW); 
        END IF;                      
 
        --CN only create or update the transaction if it needs to be created or it changed       
       IF v_TX_ROW.TRANSACTION_ID = 0 OR v_TXN_CHANGED = 1 THEN
            -- Always store the main transaction to the external side (INTERCHANGE_TRANSACTION_EXT).
		    PUT_TRANSACTION(o_OID                 => v_TX_ID,
                            p_INTERCHANGE_TRANSACTION => v_TX_ROW,
                            p_SCHEDULE_STATE          => 2,
                            p_TRANSACTION_STATUS      => v_TX_STATUS);
            v_TXN_CREATED := TRUE;                                          
        END IF;                                

		-- If it is approved, or we specified to copy to internal,
		-- then store it to the internal side (INTERCHANGE_TRANSACTION) as well.
		IF p_COPY_INTERNAL OR v_TX_STATUS = 'Approved' THEN
            --CN only create or update the transaction if it needs to be created or it changed       
            IF v_TX_ROW.TRANSACTION_ID = 0 OR v_TXN_CHANGED = 1 THEN
			    PUT_TRANSACTION(o_OID               => v_TX_ID,
                              p_INTERCHANGE_TRANSACTION => v_TX_ROW,
                              p_SCHEDULE_STATE          => 1,
                              p_TRANSACTION_STATUS      => v_TX_STATUS);                              
  
            END IF; 
             --CN Update staus of transaction, if status has changed but nothing else changed
             --This is done as part of put_transaction but now that is not called if tranaction has not changed
            IF v_TXN_CHANGED = 0 AND v_TXN_CREATED = FALSE THEN
            	BEGIN
    	        SELECT TRANSACTION_IS_ACTIVE INTO v_IS_ACTIVE
                FROM INTERCHANGE_TRANSACTION_STATUS
                WHERE TRANSACTION_STATUS_NAME = v_TX_STATUS;
             EXCEPTION
    	        WHEN OTHERS THEN
        	        v_IS_ACTIVE := 0;
                END;
                SELECT *
                INTO v_IT_STATUS_ROW
                FROM IT_STATUS
                WHERE TRANSACTION_ID = v_TX_ROW.TRANSACTION_ID;
	            IF (v_IT_STATUS_ROW.TRANSACTION_STATUS_NAME <> v_TX_STATUS) OR
                    (v_IT_STATUS_ROW.TRANSACTION_IS_ACTIVE <> v_IS_ACTIVE) THEN   
                    ITJ.PUT_IT_STATUS(v_TX_ROW.TRANSACTION_ID,SYSDATE,v_TX_STATUS,v_IS_ACTIVE,P_STATUS);
                END IF;
       
            END IF;                                  
		END IF;

		-- If it is approved, and it is a DA Transaction
		-- then create a RT Transaction and store it as well.
		IF v_TX_STATUS = 'Approved' AND v_IS_DAYAHEAD THEN

			--Reset the ident info, commodity, and is_bid_offer flag for RT Txn.
			SET_NAME_AND_IDENT_INFO(v_TX_ROW, TRUE);
			v_TX_ROW.COMMODITY_ID := MM_PJM_UTIL.GET_COMMODITY_ID(MM_PJM_UTIL.g_COMM_RT_ENERGY);
			v_TX_ROW.IS_BID_OFFER := 0;

			v_TX_ROW.TRANSACTION_ID := GET_TXN_ID(v_TX_ROW);
            IF v_TX_ROW.TRANSACTION_ID <> 0 THEN 
                v_TXN_CHANGED := GET_IS_TXN_CHANGED(v_TX_ROW); 
            END IF;  
             --CN only create or update the transaction if it needs to be created or it changed       
            IF v_TX_ROW.TRANSACTION_ID = 0 OR v_TXN_CHANGED = 1 THEN
			    PUT_TRANSACTION(o_OID               => v_TX_ID,
                              p_INTERCHANGE_TRANSACTION => v_TX_ROW,
                              p_SCHEDULE_STATE          => 1,
                              p_TRANSACTION_STATUS      => v_TX_STATUS);                              
 
            END IF; 
             --CN Update staus of transaction, if status has changed but nothing else changed
              --This is done as part of put_transaction but now that is not called if tranaction has not changed
            IF v_TXN_CHANGED = 0 AND v_TXN_CREATED = FALSE THEN
            	BEGIN
    	        SELECT TRANSACTION_IS_ACTIVE INTO v_IS_ACTIVE
                FROM INTERCHANGE_TRANSACTION_STATUS
                WHERE TRANSACTION_STATUS_NAME = v_TX_STATUS;
             EXCEPTION
    	        WHEN OTHERS THEN
        	        v_IS_ACTIVE := 0;
                END;
                SELECT *
                INTO v_IT_STATUS_ROW
                FROM IT_STATUS
                WHERE TRANSACTION_ID = v_TX_ROW.TRANSACTION_ID;
                
                IF (v_IT_STATUS_ROW.TRANSACTION_STATUS_NAME <> v_TX_STATUS) OR
                    (v_IT_STATUS_ROW.TRANSACTION_IS_ACTIVE <> v_IS_ACTIVE) THEN              
	                ITJ.PUT_IT_STATUS(v_TX_ROW.TRANSACTION_ID,SYSDATE,v_TX_STATUS,v_IS_ACTIVE,P_STATUS);      
                END IF;                    
            END IF;                                     
		END IF;

        --update corresponding Load Plus Losses txn end date, if there is a corresponding LPL txn.
        UPDATE_LOAD_W_LOSSES_DATES(v_TX_ROW.END_DATE,
                                    v_TX_ROW.CONTRACT_ID,
                                    v_TX_ROW.TRANSACTION_IDENTIFIER);


		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := p_MESSAGE || 'ERROR OCCURED IN MM_PJM_ESCHED.IMPORT_CONTRACTS: ' || UT.GET_FULL_ERRM;
END IMPORT_CONTRACTS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CONTRACTS
	(
	p_CRED          IN MEX_CREDENTIALS,
	p_BEGIN_DATE    IN DATE,
	p_END_DATE      IN DATE,
	p_COPY_INTERNAL IN BOOLEAN,
	p_LOG_ONLY		IN NUMBER,
	p_STATUS        OUT NUMBER,
	p_MESSAGE       OUT VARCHAR2,
	p_LOGGER        IN OUT MM_LOGGER_ADAPTER
	) AS
   	v_RECORDS   MEX_ESCHED_CONTRACT_TBL;
    v_DATE      DATE;

BEGIN
  p_STATUS := GA.SUCCESS;

  -- because eSchedule only returns contracts that are active over the entire
  -- begin and end date range if we pass in those 2 dates, we get the contracts
  -- a single day at a time to prevent missing any.
  -- We also use >= rather than just > get all the days, and fix bug 9211.
  IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_ESCHED_ATTR, p_CRED.EXTERNAL_ACCOUNT_NAME) THEN
	  v_DATE := TRUNC(p_BEGIN_DATE, 'DD');
	  WHILE p_END_DATE >= v_DATE LOOP
		  MEX_PJM_ESCHED.FETCH_CONTRACTS(v_DATE,
										 v_DATE,
										 p_CRED,
										 p_LOGGER,
										 p_LOG_ONLY,
										 v_RECORDS,
										 p_STATUS,
										 p_MESSAGE);
		  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
			IMPORT_CONTRACTS(v_RECORDS, p_CRED.EXTERNAL_ACCOUNT_NAME,p_COPY_INTERNAL,p_STATUS, p_MESSAGE);
		  END IF;
		v_DATE := v_DATE + 1;
	  END LOOP;
  END IF;

END IMPORT_CONTRACTS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_COMPANIES(p_RECORDS   IN MEX_PJM_ESCHED_COMPANY_TBL,
													 p_STATUS    OUT NUMBER,
													 p_MESSAGE   OUT VARCHAR2) AS
	v_IDX     BINARY_INTEGER;
	v_ORG_ID PJM_OBJECT_MAP.OBJECT_VALUE%TYPE;
BEGIN
	p_STATUS := GA.SUCCESS;

	v_IDX := p_RECORDS.FIRST();
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		BEGIN
			SELECT POM.OBJECT_VALUE
				INTO v_ORG_ID
				FROM PJM_OBJECT_MAP POM
			 WHERE POM.OBJECT_VALUE = p_RECORDS(v_IDX).ORG_ID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
        BEGIN
				INSERT INTO PJM_OBJECT_MAP
					(OBJECT_TYPE, OBJECT_NAME, OBJECT_VALUE)
				VALUES
					('PSE', p_RECORDS(v_IDX).SHORT_NAME, TO_NUMBER(p_RECORDS(v_IDX).ORG_ID));
		    EXCEPTION
          WHEN OTHERS THEN
             -- freakin' FERC shows up twice; may be others
             NULL;
        END;
    END;
		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	v_IDX := p_RECORDS.FIRST();
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
    	UPDATE PJM_ESCHED_COMPANY
    		 SET PARTICIPANT_NAME = p_RECORDS(v_IDX).PARTICIPANT_NAME, SHORT_NAME = p_RECORDS(v_IDX).SHORT_NAME
    	 WHERE ORG_ID = p_RECORDS(v_IDX).ORG_ID;

    	IF SQL%NOTFOUND THEN
    		INSERT INTO PJM_ESCHED_COMPANY
    			(ORG_ID, PARTICIPANT_NAME, SHORT_NAME)
    		VALUES
    			(p_RECORDS(v_IDX).ORG_ID,
				p_RECORDS(v_IDX).PARTICIPANT_NAME,
				p_RECORDS(v_IDX).SHORT_NAME);
    	END IF;
		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	COMMIT;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := p_MESSAGE || 'ERROR OCCURED IN MM_PJM_ESCHED.IMPORT_COMPANIES: ' || UT.GET_FULL_ERRM;
END IMPORT_COMPANIES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_COMPANIES(p_CSV     IN CLOB,
													 p_STATUS  OUT NUMBER,
													 p_MESSAGE OUT VARCHAR2) AS
	v_RECORDS MEX_PJM_ESCHED_COMPANY_TBL;
BEGIN
  p_STATUS := GA.SUCCESS;
	MEX_PJM_ESCHED.PARSE_COMPANIES(p_CSV, v_RECORDS, p_STATUS, p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_COMPANIES(v_RECORDS, p_STATUS, p_MESSAGE);
	END IF;
END IMPORT_COMPANIES;
----------------------------------------------------------------------------------------------------
  PROCEDURE IMPORT_COMPANIES(p_CRED		 IN mex_credentials,
  							p_BEGIN_DATE IN DATE,
							p_END_DATE   IN DATE,
							p_LOG_ONLY		IN NUMBER,
							p_STATUS     OUT NUMBER,
							p_MESSAGE    OUT VARCHAR2,
							p_LOGGER	IN OUT mm_logger_adapter
							) AS
	v_RECORDS MEX_PJM_ESCHED_COMPANY_TBL;
BEGIN
  p_STATUS := GA.SUCCESS;

	IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_ESCHED_ATTR, p_CRED.EXTERNAL_ACCOUNT_NAME) THEN
		MEX_PJM_ESCHED.FETCH_COMPANIES(p_BEGIN_DATE,
								 p_END_DATE,
								 p_CRED,
								 p_LOGGER,
								 p_LOG_ONLY,
								 v_RECORDS,
								 p_STATUS,
								 p_MESSAGE);
		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
			IMPORT_COMPANIES(v_RECORDS, p_STATUS, p_MESSAGE);
		END IF;
	END IF;

END IMPORT_COMPANIES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ESCHED_W_WO_LOSSES_MSRS
    (
	p_CRED		 IN mex_credentials,
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
	p_LOG_ONLY	 IN NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2,
	p_LOGGER	 IN OUT mm_logger_adapter
    ) AS
	v_RECORDS   	MEX_PJM_DAILY_TX_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;

	IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_ESCHED_ATTR, p_CRED.EXTERNAL_ACCOUNT_NAME) THEN
		MEX_PJM_ESCHED.FETCH_ESCHED_W_WO_LOSSES_MSRS(p_BEGIN_DATE,
												p_END_DATE,
												p_CRED,
												p_LOGGER,
												p_LOG_ONLY,
												v_RECORDS,
												p_STATUS,
												p_MESSAGE);
		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
			IMPORT_ESCHED_W_WO_LOSSES(p_CRED.EXTERNAL_ACCOUNT_NAME, v_RECORDS,p_STATUS,p_MESSAGE);
		END IF;
	END IF;
END IMPORT_ESCHED_W_WO_LOSSES_MSRS;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ESCHED_W_WO_LOSSES
    (
	p_CRED		 IN mex_credentials,
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
	p_LOG_ONLY	 IN NUMBER,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2,
	p_LOGGER	 IN OUT mm_logger_adapter
    ) AS
	v_RECORDS   	MEX_PJM_DAILY_TX_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;

	IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_ESCHED_ATTR, p_CRED.EXTERNAL_ACCOUNT_NAME) THEN
		MEX_PJM_ESCHED.FETCH_ESCHED_W_WO_LOSSES(p_BEGIN_DATE,
												p_END_DATE,
												p_CRED,
												p_LOGGER,
												p_LOG_ONLY,
												v_RECORDS,
												p_STATUS,
												p_MESSAGE);
		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
			IMPORT_ESCHED_W_WO_LOSSES(p_CRED.EXTERNAL_ACCOUNT_NAME, v_RECORDS,p_STATUS,p_MESSAGE);
		END IF;
	END IF;
END IMPORT_ESCHED_W_WO_LOSSES;
--------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_ESCHEDULE_FILE(p_CRED	   IN mex_credentials,
									pBeginDate in Date,
									pEndDate in Date,
									pFileToUpload in Clob,
									pLogOnly in Number,
									pStatus out Number,
									pMessage out VarChar2,
									p_LOGGER IN OUT mm_logger_adapter) AS
	v_RESP CLOB;

	v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
  	pStatus := GA.SUCCESS;
	v_PARAMS(MEX_PJM.c_Report_Type) := 'Submit-eSchedule';
  	v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;

  	MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
  								'esched', -- p_REQUEST_APP
			   					p_LOGGER,
								p_CRED,
								pBeginDate,
								pEndDate,
                    			'upload',  -- p_REQUEST_DIR
                    		    v_RESP,
								pStatus,
								pMessage,
								'html',
								pFileToUpload,
								pLogOnly);
	-- prettify response so its more legible to a user
    pSTATUS := 1;
    pMESSAGE := DBMS_LOB.SUBSTR(PARSE_UTIL.HTML_RESPONSE_TO_TEXT(v_RESP),32767,1);
	DBMS_LOB.FREETEMPORARY(v_RESP);

	END SUBMIT_ESCHEDULE_FILE;
    ----------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_ESCHEDULE
  (
  p_CRED			IN mex_credentials,
  p_TRANSACTION_ID 	IN NUMBER,
  p_BEGIN_DATE 		IN DATE,
  p_END_DATE 		IN DATE,
  p_LOG_ONLY 		IN NUMBER,
  p_STATUS 			OUT NUMBER,
  p_MESSAGE 		OUT VARCHAR2,
  p_LOGGER			IN OUT mm_logger_adapter
  ) AS

v_CLOB CLOB;
v_LOC NUMBER;
v_ROW_DATA VARCHAR2(500);
v_TRANS_ID VARCHAR2(32);
v_START_HR NUMBER(2);
v_STOP_HR NUMBER(2);
v_DATE DATE;
v_TRANSACTION_ID BID_OFFER_SET.TRANSACTION_ID%TYPE;
v_QUANTITY NUMBER;
v_CUT_FROM DATE;
v_CUT_TO DATE;
v_SPRING_AHEAD_DAY BOOLEAN;

CURSOR c_BID_OFFERS(v_TRANSACTION_ID IN NUMBER, v_DATE_START IN DATE, v_DATE_END IN DATE) IS
    SELECT TO_HED_AS_DATE(FROM_CUT(SCHEDULE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE)) "DATE", QUANTITY
    FROM BID_OFFER_SET
    WHERE TRANSACTION_ID = v_TRANSACTION_ID
    AND SET_NUMBER = 1
    AND SCHEDULE_STATE = GA.INTERNAL_STATE --1
	AND SCHEDULE_DATE
    BETWEEN v_DATE_START
    AND v_DATE_END
    ORDER BY SCHEDULE_DATE;

BEGIN
  p_STATUS := GA.SUCCESS;

  DBMS_LOB.CREATETEMPORARY(v_CLOB, TRUE);
  DBMS_LOB.OPEN(v_CLOB, DBMS_LOB.LOB_READWRITE);

  SELECT TRANSACTION_IDENTIFIER
  INTO v_TRANS_ID
  FROM INTERCHANGE_TRANSACTION
  WHERE TRANSACTION_ID = p_TRANSACTION_ID;

  IF INSTR(v_TRANS_ID,'PJM-') > 0 THEN
    v_LOC := INSTR(v_TRANS_ID, '-');
    v_TRANS_ID := SUBSTR(v_TRANS_ID, v_LOC + 1);
    v_LOC := INSTR(v_TRANS_ID, '-');
    v_TRANS_ID := SUBSTR(v_TRANS_ID, v_LOC + 1);
  END IF;

  v_DATE := p_BEGIN_DATE;

 WHILE v_DATE <= p_END_DATE LOOP

	UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                      v_DATE,
                                      v_DATE,
                                      MM_PJM_UTIL.g_PJM_TIME_ZONE,
                                      60,
                                      v_CUT_FROM,
                                      v_CUT_TO);

    -- if quantity for each hour is zero or no data, leave out entire day
    BEGIN
    SELECT SUM(QUANTITY)
    INTO v_QUANTITY
    FROM BID_OFFER_SET
    WHERE TRANSACTION_ID = p_TRANSACTION_ID
    AND SET_NUMBER = 1
    AND SCHEDULE_STATE = GA.INTERNAL_STATE
    AND SCHEDULE_DATE
    BETWEEN v_CUT_FROM AND v_CUT_TO;
    EXCEPTION
             WHEN NO_DATA_FOUND THEN NULL;
    END;

    IF v_QUANTITY = 0 OR v_QUANTITY IS NULL THEN
      v_DATE := v_DATE + 1;
    ELSE


      v_ROW_DATA := '*INTSCH*' || CHR(13) || CHR(10);

      DBMS_LOB.WRITEAPPEND(v_CLOB, LENGTH(v_ROW_DATA), v_ROW_DATA);
      v_ROW_DATA := v_TRANS_ID || CHR(13) || CHR(10);
      DBMS_LOB.WRITEAPPEND(v_CLOB, LENGTH(v_ROW_DATA), v_ROW_DATA);
      v_ROW_DATA := TO_CHAR(v_DATE, 'MM/DD/YYYY') || CHR(13) || CHR(10);
      DBMS_LOB.WRITEAPPEND(v_CLOB, LENGTH(v_ROW_DATA), v_ROW_DATA);
      v_ROW_DATA := TO_CHAR(v_DATE, 'MM/DD/YYYY')|| CHR(13) || CHR(10);
      DBMS_LOB.WRITEAPPEND(v_CLOB, LENGTH(v_ROW_DATA), v_ROW_DATA);

	   FOR v_BID_OFFERS IN c_BID_OFFERS(p_TRANSACTION_ID, v_CUT_FROM, v_CUT_TO) LOOP

            IF TRUNC(v_BID_OFFERS.DATE) = TRUNC(DST_SPRING_AHEAD_DATE(V_BID_OFFERS.DATE)) THEN
                    v_SPRING_AHEAD_DAY := TRUE;
            ELSE
                v_SPRING_AHEAD_DAY := FALSE;
            END IF;

        --dst fall-back
        IF TO_CHAR(v_BID_OFFERS.DATE, 'HH24:MI:SS') = '02:00:01' THEN
          v_START_HR := 24;
          v_STOP_HR := 25;

            --for spring ahead, submit for hour 1-2; doc says on that date, hour 2-3 ignored
            ELSIF v_SPRING_AHEAD_DAY = TRUE AND TO_CHAR(v_BID_OFFERS.DATE, 'HH24:MI:SS') = '03:00:00' THEN
                    v_START_HR := 1;
                    v_STOP_HR := 2;

        --conversion for last hour
        ELSIF TO_CHAR(v_BID_OFFERS.DATE, 'HH24:MI:SS') = '23:59:59' THEN
          v_START_HR := 23;
          v_STOP_HR := 24;
        ELSE
          v_STOP_HR := TO_NUMBER(TO_CHAR(v_BID_OFFERS.DATE, 'HH24'));
          v_START_HR := v_STOP_HR - 1;
        END IF;

            v_ROW_DATA :=  v_START_HR || '-' || v_STOP_HR || ' ' || v_BID_OFFERS.QUANTITY || CHR(13) || CHR(10);
            DBMS_LOB.WRITEAPPEND(v_CLOB, LENGTH(v_ROW_DATA), v_ROW_DATA);

      END LOOP;
      v_DATE := v_DATE + 1;
    END IF;
  END LOOP;
  DBMS_LOB.CLOSE(v_CLOB);

	MEX_PJM_ESCHED.SUBMIT_ESCHEDULE(p_BEGIN_DATE,
				  p_END_DATE,
				  p_LOG_ONLY,
				  p_CRED,
				   p_LOGGER,
				   v_CLOB,
				   p_STATUS,
				   p_MESSAGE);

  DBMS_LOB.FREETEMPORARY(V_CLOB);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := p_MESSAGE || 'ERROR OCCURED IN MM_PJM_ESCHED.SUBMIT_ESCHEDULE: ' ||
									 UT.GET_FULL_ERRM;

END SUBMIT_ESCHEDULE;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_SUBMIT_TRANSACTION_LIST
	(
	p_BEGIN_DATE 	IN DATE,
	p_END_DATE 		IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR2,
	p_STATUS 		OUT NUMBER,
	p_CURSOR 		IN OUT REF_CURSOR) AS

BEGIN
	p_STATUS := GA.SUCCESS;

	--get list of bilaterals
	OPEN p_CURSOR FOR
		SELECT TRANSACTION_NAME, TRANSACTION_ID
		FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
		WHERE IS_BID_OFFER = 1
			AND IS_IMPORT_EXPORT = 0
			AND SC_ID = EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM) --g_PJM_SC_ID
			AND TRANSACTION_TYPE IN (g_TXN_TYPE_PURCHASE, g_TXN_TYPE_SALE)
			AND B.COMMODITY_ID = A.COMMODITY_ID
			AND B.COMMODITY_TYPE = 'Energy'
		ORDER BY 1;

END MARKET_SUBMIT_TRANSACTION_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE SYSTEM_ACTION_USES_HOURS
	(
    p_ACTION IN VARCHAR2,
	p_SHOW_HOURS OUT NUMBER
    ) AS
BEGIN
	p_SHOW_HOURS := 0;
END SYSTEM_ACTION_USES_HOURS;
----------------------------------------------------------------------------------------------------

PROCEDURE UPDATE_BID_OFFER_STATUS(p_TRANSACTION_ID IN NUMBER,
																		p_BEGIN_DATE     IN DATE,
																		p_END_DATE       IN DATE,
																		p_TIME_ZONE      IN VARCHAR2,
																		p_SUBMIT_STATUS  IN VARCHAR2,
																		p_MARKET_STATUS  IN VARCHAR2) AS

		v_BEGIN_DATE DATE;
		v_END_DATE   DATE;
	BEGIN

		UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE,
											v_BEGIN_DATE, v_END_DATE);

		UPDATE IT_TRAIT_SCHEDULE_STATUS
			 SET SUBMIT_STATUS      = p_SUBMIT_STATUS,
					 SUBMIT_DATE        = SYSDATE,
					 MARKET_STATUS      = p_MARKET_STATUS,
					 MARKET_STATUS_DATE = SYSDATE
		 WHERE TRANSACTION_ID = p_TRANSACTION_ID AND
					 SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

END UPDATE_BID_OFFER_STATUS;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_SUBMIT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR2,
	p_LOG_ONLY IN NUMBER :=0,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_SUBMIT_HOURS IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2,
	p_LOG_TYPE IN NUMBER,
	p_TRACE_ON	IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_TRANSACTION_IDS VARCHAR2(2000);
	v_TXN_STRING_TABLE GA.STRING_TABLE;
	v_INDEX BINARY_INTEGER;
	v_TRANSACTION_ID NUMBER(9);
	v_TIME_ZONE VARCHAR2(3) := p_TIME_ZONE;
	v_EXTERNAL_ACCOUNT_NAME VARCHAR2(100);
	v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;

    v_CRED MEX_CREDENTIALS;
    v_LOGGER MM_LOGGER_ADAPTER;
	v_LOG_ONLY NUMBER:= NVL(p_LOG_ONLY, 0);
	v_STATUS_REC MM_PJM_UTIL.t_STATUS;
	v_DUMMY_MESSAGE VARCHAR2(4000);

BEGIN
	p_STATUS := GA.SUCCESS;
	v_STATUS_REC.SUCCEEDED := 0;
	v_STATUS_REC.REJECTED := 0;
	v_STATUS_REC.ERROR := 0;

	--Init MEX to get a logger, but we reset the credentials for each Transaction.
	MM_UTIL.INIT_MEX (EC.ES_PJM, NULL, 'PJM:ESCHEDULE', p_EXCHANGE_TYPE, p_LOG_TYPE, p_TRACE_ON, v_CRED, v_LOGGER);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	v_TRANSACTION_IDS := REPLACE(p_ENTITY_LIST, '''', '');
	UT.TOKENS_FROM_STRING(v_TRANSACTION_IDS, p_ENTITY_LIST_DELIMITER, v_TXN_STRING_TABLE);
	v_INDEX := v_TXN_STRING_TABLE.FIRST;

	--The only action currently supported is submitting eSchedules.
	IF p_EXCHANGE_TYPE = g_ET_SUBMIT_SCHEDULE THEN
		--LOOP OVER TRANSACTIONS
		LOOP
			v_TRANSACTION_ID := TO_NUMBER(v_TXN_STRING_TABLE(v_INDEX));

			-- get the external credentials for this transaction
			v_EXTERNAL_ACCOUNT_NAME := MM_UTIL.GET_EXT_ACCOUNT_FOR_TXN(v_TRANSACTION_ID, EC.ES_PJM);

			--UPDATE SUBMIT STATUS TO PENDING.
			IF v_LOG_ONLY = 0 THEN
				UPDATE_BID_OFFER_STATUS(v_TRANSACTION_ID, p_BEGIN_DATE, p_END_DATE, v_TIME_ZONE, g_SUBMIT_STATUS_PENDING, g_MKT_STATUS_PENDING);
			END IF;

			IF v_EXTERNAL_ACCOUNT_NAME IS NOT NULL THEN
				MM_UTIL.INIT_MEX (EC.ES_PJM, v_EXTERNAL_ACCOUNT_NAME, 'PJM:ESCHEDULE', p_EXCHANGE_TYPE, p_LOG_TYPE,  p_TRACE_ON, v_CRED, v_LOGGER);
				SUBMIT_ESCHEDULE(v_CRED, v_TRANSACTION_ID, p_BEGIN_DATE, p_END_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			END IF;

			-- set the submit status for success or failure based on status code returned
			-- from submit_schedule
			IF INSTR(UPPER(p_MESSAGE),'SUCCESSFULLY UPLOADED') > 0 THEN
				v_STATUS_REC.SUCCEEDED := v_STATUS_REC.SUCCEEDED + 1;
				UPDATE_BID_OFFER_STATUS(v_TRANSACTION_ID,
									p_BEGIN_DATE,
									p_END_DATE,
									v_TIME_ZONE,
									g_SUBMIT_STATUS_SUBMITTED,
									g_MKT_STATUS_ACCEPTED);
			ELSE
				v_STATUS_REC.REJECTED := v_STATUS_REC.REJECTED + 1;
				SELECT TRANSACTION_NAME INTO v_TRANSACTION_NAME FROM INTERCHANGE_TRANSACTION WHERE TRANSACTION_ID = v_TRANSACTION_ID;
				v_LOGGER.LOG_ERROR('Submit Schedule was not successful for Transaction "' || v_TRANSACTION_NAME || '"');
				UPDATE_BID_OFFER_STATUS(v_TRANSACTION_ID,
									p_BEGIN_DATE,
									p_END_DATE,
									v_TIME_ZONE,
									g_SUBMIT_STATUS_FAILED,
									g_MKT_STATUS_REJECTED);
			END IF;

			EXIT WHEN v_INDEX = v_TXN_STRING_TABLE.LAST;
			v_INDEX := v_TXN_STRING_TABLE.NEXT(v_INDEX);
		END LOOP; -- OVER TRANSACTIONS;

		-- run the query immediately after the action
		IF NVL(GET_DICTIONARY_VALUE('QueryAfterSubmit', 0, 'MarketExchange'), 0) = 1 THEN
			IMPORT_SCHEDULES(v_CRED, p_BEGIN_DATE, p_END_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			IF p_STATUS <> MEX_SWITCHBOARD.c_Status_Success THEN
				SELECT TRANSACTION_NAME INTO v_TRANSACTION_NAME FROM INTERCHANGE_TRANSACTION WHERE TRANSACTION_ID = v_TRANSACTION_ID;
				v_LOGGER.LOG_ERROR('Unable to Query Schedules after Submit for Transaction "' || v_TRANSACTION_NAME || '"');
			END IF;
		END IF;

		p_MESSAGE := MM_PJM_UTIL.GET_STATUS_MESSAGE(v_STATUS_REC, 'submitted', 'eSchedules');

	ELSE
		p_STATUS := -1;
		p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
		v_LOGGER.LOG_ERROR(p_MESSAGE);
	END IF;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := UT.GET_FULL_ERRM;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_SUBMIT;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	P_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

v_CREDS mm_credentials_set;
v_CRED	mex_credentials;
v_LOGGER mm_logger_adapter;
v_LOG_ONLY NUMBER;
BEGIN
	p_STATUS := GA.SUCCESS;
	v_LOG_ONLY := NVL(p_LOG_ONLY,0);

	MM_UTIL.INIT_MEX (EC.ES_PJM, 	-- The market code
					 'PJM:ESCHEDULE:' || p_EXCHANGE_TYPE,
					 p_EXCHANGE_TYPE,
					 p_LOG_TYPE,
					 p_TRACE_ON,
					 v_CREDS,
					 v_LOGGER);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	WHILE v_CREDS.HAS_NEXT LOOP
		v_CRED := v_CREDS.GET_NEXT;

		CASE p_EXCHANGE_TYPE
			WHEN g_ET_QUERY_COMPANIES THEN
				IMPORT_COMPANIES(v_CRED, p_BEGIN_DATE, p_END_DATE,v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
				EXIT; -- SAME FOR ALL ACCOUNTS
			WHEN g_ET_QUERY_CONTRACTS THEN
				IMPORT_CONTRACTS(v_CRED, p_BEGIN_DATE, p_END_DATE, FALSE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			WHEN g_ET_QUERY_CONTR_TO_INTER THEN
				IMPORT_CONTRACTS(v_CRED, p_BEGIN_DATE, p_END_DATE, TRUE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			WHEN g_ET_QUERY_SCHEDULES THEN
				g_UPDATE_ESCHED_TRAITS := FALSE;
				IMPORT_SCHEDULES(v_CRED, p_BEGIN_DATE, p_END_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			WHEN g_ET_QUERY_SCHED_TO_INTER THEN
				g_UPDATE_ESCHED_TRAITS := TRUE;
				IMPORT_SCHEDULES(v_CRED, p_BEGIN_DATE, p_END_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			WHEN g_ET_QUERY_RECON_DATA THEN
				IF p_ENTITY_LIST = 'From Settlement' THEN
					IMPORT_RECON_DATA(v_CRED, p_BEGIN_DATE, LOW_DATE,v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
				ELSE
					IMPORT_RECON_DATA(v_CRED, p_BEGIN_DATE, p_END_DATE,v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
				END IF;
			WHEN g_ET_QUERY_RL_TIME_DAILY_TXNS THEN
				IMPORT_REAL_TIME_DAILY_TX_MSRS(v_CRED, p_BEGIN_DATE, p_END_DATE,v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
			WHEN g_ET_QUERY_LOAD THEN
				IMPORT_ESCHED_W_WO_LOSSES_MSRS(v_CRED, p_BEGIN_DATE, p_END_DATE,v_LOG_ONLY, p_STATUS,p_MESSAGE, v_LOGGER);
			ELSE
				p_STATUS := -1;
				p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
				v_LOGGER.LOG_ERROR(p_MESSAGE);
				EXIT;
		END CASE;
	END LOOP;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
	g_UPDATE_ESCHED_TRAITS := FALSE;

EXCEPTION
	WHEN OTHERS THEN
		-- 22-mar-2007, jbc: why was this here?
		--ROLLBACK;
    	p_STATUS := SQLCODE;
        p_MESSAGE := UT.GET_FULL_ERRM;
		g_UPDATE_ESCHED_TRAITS := FALSE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
----------------------------------------------------------------------------------------------------
  PROCEDURE MARKET_IMPORT_CLOB
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE         	IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_FILE_PATH					IN VARCHAR2, 		-- For logging Purposes.
	p_IMPORT_FILE				IN OUT NOCOPY CLOB, -- File to be imported
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE					IN NUMBER,
	p_TRACE_ON					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

	v_CRED	mex_credentials;
	v_LOGGER mm_logger_adapter;
	v_LOG_ONLY NUMBER;
BEGIN
	v_LOG_ONLY := NVL(p_LOG_ONLY, 0);
	MM_UTIL.INIT_MEX (EC.ES_PJM, 	-- The market code
					 NULL,
					 'PJM:ESCHEDULE',
					 p_EXCHANGE_TYPE,
					 p_LOG_TYPE,
					 p_TRACE_ON,
					 v_CRED,
					 v_LOGGER);

	MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

	CASE p_EXCHANGE_TYPE
		WHEN g_ET_UPLOAD_FILE THEN
			SUBMIT_ESCHEDULE_FILE(v_CRED, p_BEGIN_DATE, p_END_DATE, p_IMPORT_FILE,v_LOG_ONLY, p_STATUS, p_MESSAGE,v_LOGGER);
		WHEN g_ET_IMPORT_SCHEDULES_CSV THEN
			IMPORT_SCHEDULES (NULL, p_IMPORT_FILE,p_STATUS, p_MESSAGE, v_LOGGER);
		--WHEN 'IMPORT RECONCILIATION CSV' THEN
			--IMPORT_RECON_DATA (p_REQUEST_CLOB, p_STATUS, p_MESSAGE);
		WHEN g_ET_IMPORT_RL_TIME_DAILY_CSV THEN
			IMPORT_REAL_TIME_DAILY_TX (p_IMPORT_FILE,p_STATUS, p_MESSAGE);
		WHEN g_ET_QUERY_COMPANIES_FROM_FILE THEN
			IMPORT_COMPANIES(p_IMPORT_FILE, p_STATUS,p_MESSAGE);
		ELSE
			p_STATUS := -1;
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
			v_LOGGER.LOG_ERROR(p_MESSAGE);
	END CASE;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		-- 22-mar-2007, jbc: why was this here?
		--ROLLBACK;
    	p_STATUS := SQLCODE;
        p_MESSAGE := UT.GET_FULL_ERRM;
		g_UPDATE_ESCHED_TRAITS := FALSE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_IMPORT_CLOB;
-----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_SUBMIT_WARNING(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR,
	p_LOG_ONLY IN NUMBER,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_SUBMIT_HOURS IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_SOMETHING_DONE OUT BOOLEAN,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR,
	p_CONTINUE_BUTTON_CAPTION OUT VARCHAR,
	p_CANCEL_BUTTON_CAPTION OUT VARCHAR,
	p_MUST_CANCEL_SUBMIT OUT NUMBER) AS

	v_TRANS_LIST VARCHAR2(4000);
	v_TRANSACTION_IDS VARCHAR2(2000);
	v_TXN_STRING_TABLE GA.STRING_TABLE;
	v_INDEX BINARY_INTEGER;
	v_TXN_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	v_TXN_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
    v_DATE DATE;
	v_CUT_FROM DATE;
    v_CUT_TO DATE;
    v_QUANTITY NUMBER;

    CURSOR TXN_CON_CURSOR (v_TXN_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE) IS
    SELECT IT.TRANSACTION_NAME
    FROM INTERCHANGE_TRANSACTION IT, INTERCHANGE_CONTRACT IC
    WHERE IT.TRANSACTION_ID = v_TXN_ID
    AND IC.BILLING_ENTITY_ID <> 0
    AND IC.CONTRACT_ID = IT.CONTRACT_ID
    AND ((IT.PURCHASER_ID = IC.BILLING_ENTITY_ID AND IT.APPROVAL_TYPE != g_TXN_APPR_TYPE_PURCHASER)
    OR  (IT.SELLER_ID = IC.BILLING_ENTITY_ID AND IT.APPROVAL_TYPE != g_TXN_APPR_TYPE_SELLER));

    TXN_CON_RECORD TXN_CON_CURSOR%ROWTYPE;


BEGIN

	-- defaults
	p_SOMETHING_DONE := FALSE;
	p_STATUS := GA.SUCCESS;
	p_MUST_CANCEL_SUBMIT := 0;

    v_TRANS_LIST := '';

	-- prepare the list of transactions for use by the cursor
    v_TRANSACTION_IDS := p_ENTITY_LIST;
    v_TRANSACTION_IDS := REPLACE(v_TRANSACTION_IDS, p_ENTITY_LIST_DELIMITER, ', ');

    UT.TOKENS_FROM_STRING(v_TRANSACTION_IDS, ',', v_TXN_STRING_TABLE);
    v_INDEX := v_TXN_STRING_TABLE.FIRST;

	-- loop over transactions
	LOOP
			v_TXN_ID := TO_NUMBER(v_TXN_STRING_TABLE(v_INDEX));

    		-- check for errors on all transactions for each iso account name
            OPEN TXN_CON_CURSOR (v_TXN_ID);

            LOOP
            FETCH TXN_CON_CURSOR INTO TXN_CON_RECORD;
            EXIT WHEN TXN_CON_CURSOR%NOTFOUND;
                -- add transaction name to list
                IF v_TRANS_LIST IS NOT NULL THEN
                	v_TRANS_LIST := v_TRANS_LIST || ', ' || CHR(13) || TXN_CON_RECORD.TRANSACTION_NAME;
                ELSE
                	v_TRANS_LIST := CHR(13) || TXN_CON_RECORD.TRANSACTION_NAME;
                END IF;
            END LOOP;

            CLOSE TXN_CON_CURSOR;

	EXIT WHEN v_INDEX = v_TXN_STRING_TABLE.LAST;
    v_INDEX := v_TXN_STRING_TABLE.NEXT(v_INDEX);
	END LOOP;


    IF LENGTH(v_TRANS_LIST) > 0 THEN
			NULL;
			/*
    	p_SOMETHING_DONE := TRUE;
    	p_STATUS := -1;
    	p_MESSAGE := 'The contract type does not match the transaction approval type (Purchaser or Seller) for the following transactions: ' || v_TRANS_LIST;
      p_MUST_CANCEL_SUBMIT :=1;
			*/
    ELSE

        v_DATE := p_BEGIN_DATE;
        -- loop over date range
        LOOP
            v_CUT_FROM := TO_CUT(v_DATE + 1/24, p_TIME_ZONE); -- hour ending
            v_CUT_TO := TO_CUT(v_DATE+1, p_TIME_ZONE);

            --dbms_output.put_line(to_char(v_cut_from,'mm/dd/yyyy HH24 MI:ss') || ',' || to_char(v_cut_to,'mm/dd/yyyy HH24:MI:ss'));

            v_INDEX := v_TXN_STRING_TABLE.FIRST;
        	-- loop over transactions
        	LOOP

              v_TXN_ID := TO_NUMBER(v_TXN_STRING_TABLE(v_INDEX));

              -- if quantity for each hour of the day is zero or no data found, report it
              BEGIN
              SELECT SUM(QUANTITY)
              INTO v_QUANTITY
              FROM BID_OFFER_SET
              WHERE TRANSACTION_ID = v_TXN_ID
              AND SET_NUMBER = 1
              AND SCHEDULE_STATE = GA.INTERNAL_STATE
              AND SCHEDULE_DATE
              BETWEEN v_CUT_FROM AND v_CUT_TO;
              EXCEPTION
                       WHEN OTHERS THEN NULL;
              END;

              IF v_QUANTITY = 0 OR v_QUANTITY IS NULL THEN
                BEGIN
                SELECT TRANSACTION_NAME
                INTO v_TXN_NAME
                FROM INTERCHANGE_TRANSACTION
                WHERE TRANSACTION_ID = v_TXN_ID;
                EXCEPTION
                         WHEN OTHERS THEN NULL;
                END;
                -- add transaction name and date to list
                IF v_TRANS_LIST IS NOT NULL THEN
                	v_TRANS_LIST := v_TRANS_LIST || ', ' || CHR(13) || v_TXN_NAME || ' (' || TO_CHAR(v_DATE, 'MM/DD/YYYY') || ')';
                ELSE
                	v_TRANS_LIST := CHR(13) || v_TXN_NAME || ' (' || TO_CHAR(v_DATE, 'MM/DD/YYYY') || ')';
                END IF;
              END IF;

            EXIT WHEN v_INDEX = v_TXN_STRING_TABLE.LAST;
            v_INDEX := v_TXN_STRING_TABLE.NEXT(v_INDEX);
        	END LOOP;  -- loopin' on the transaction

        EXIT WHEN v_DATE >= p_END_DATE;
        v_DATE := v_DATE +1;
        END LOOP;  -- loopin' on the date

        IF LENGTH(v_TRANS_LIST) > 0 THEN
        	p_SOMETHING_DONE := TRUE;
        	p_STATUS := -1;
        	p_MESSAGE := 'Zero or null value days exist for the following transactions: ' || v_TRANS_LIST;
            -- warning only
        END IF;

    END IF;

END MARKET_SUBMIT_WARNING;
----------------------------------------------------------------------------------------------------
BEGIN
  BEGIN
	  ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eSchedules', EC.ED_INTERCHANGE_CONTRACT, 'String', FALSE, g_ESCHED_ATTR);
	  ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: PopulateFromRTDailyTx', EC.ED_TRANSACTION, 'Boolean', FALSE, g_USE_RT_DAILY_TX_ATTR);
  EXCEPTION WHEN OTHERS THEN
  	  NULL;
  END;
END MM_PJM_ESCHED;
/