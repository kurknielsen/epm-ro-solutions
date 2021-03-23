CREATE OR REPLACE PACKAGE BODY MM_TDIE_IMPORTS IS
--------------------------------------------------------------------------------
-- Created : 09/28/2009 15:25
-- Purpose : Download Market Messages
-- $Revision: 1.14 $
--------------------------------------------------------------------------------
c_REGISTER_STATUS_VALID CONSTANT VARCHAR2(4) := 'VVAK';

c_REGISTER_NODE_TYPE_NEW		CONSTANT TDIE_300_REGISTER.REGISTER_NODE_TYPE%TYPE := 'New';
c_REGISTER_NODE_TYPE_RETAINED	CONSTANT TDIE_300_REGISTER.REGISTER_NODE_TYPE%TYPE := 'Retained';
c_REGISTER_NODE_TYPE_REMOVED	CONSTANT TDIE_300_REGISTER.REGISTER_NODE_TYPE%TYPE := 'Removed';

c_MIM591_NQHAGGREGATION         CONSTANT VARCHAR2(30) := 'MIM591_NQHAggregation';
c_MIM595_QHIMPORTAGGREGATION    CONSTANT VARCHAR2(30) := 'MIM595_QHImportAggregation';
c_MIM591_NONINTERVALAGG         CONSTANT VARCHAR2(50) := 'MIM591_NonIntervalAggregation';
c_MIM595_INTERVALIMPAGG         CONSTANT VARCHAR2(50) := 'MIM595_IntervalImportAggregation';

--------------------------------------------------------------------------------
--                PACKAGE TYPES, CONSTANTS AND VARIABLES
--------------------------------------------------------------------------------
-- XML File Message Header Type
TYPE t_MESSAGE_HEADER IS RECORD(
   MARKET_TIMESTAMP  DATE,
   MESSAGE_TYPE_CODE VARCHAR2(5),
   RECIPIENT_ID      VARCHAR2(3),
   SENDER_ID         VARCHAR2(3),
   SUPPLIER_ID       VARCHAR2(3),
   TX_REF_NUMBER     VARCHAR2(36),
   VERSION_NUMBER    VARCHAR2(9),
   SUPPLIER_MPID     VARCHAR2(3));

$IF $$UNIT_TEST_MODE  <> 1 OR $$UNIT_TEST_MODE IS NULL $THEN
-- CSV File Message Header Type
TYPE t_NIE_HEADER IS RECORD(
   TITLE             VARCHAR2(218),
   SUPPLIER_ID       VARCHAR2(3),
   SETTLEMENT_DATE   DATE,
   SETTLEMENT_TYPE   VARCHAR2(4),
   AGGREGATION_TYPE  VARCHAR2(8),
   RUN_VERSION       NUMBER(9),
   REPORT_DATE       DATE);
$END

-- CSV File Message Detail Header Type
TYPE t_NIE_DETAIL_HEADER IS RECORD(
   UNIT_ID                  VARCHAR2(16),
   LOAD_PROFILE             VARCHAR2(16),
   LINE_LOSS_FACTOR_ID      VARCHAR2(16),
   LINE_LOSS_INDICATOR      VARCHAR2(1),
   IMP_EXP_INDICATOR        VARCHAR2(6),
   METER_VALUE_INDICATOR    VARCHAR2(3),
   UOS_TARIFF               VARCHAR2(16),
   AGG_CODE                 VARCHAR2(1),
   METER_CONFIGURATION_CODE VARCHAR2(16),
   TIME_SLOT                VARCHAR2(16));

-- Types used in processing 34X interval-meter data
TYPE TDIE_34X_AGGREGATION IS RECORD
(
	TDIE_MPRN_CHANNEL_ID NUMBER(9),
	ACCOUNT_ID NUMBER(9),
	SERVICE_LOCATION_ID NUMBER(9),
	METER_ID NUMBER(9),
	METER_POINT_ID NUMBER(9),
	METERING_INTERVAL NUMBER(6),
	UOM VARCHAR2(16)
);

TYPE TDIE_34X_AGGREGATION_TBL IS TABLE OF TDIE_34X_AGGREGATION;


g_MIME_TYPE_XML        		CONSTANT VARCHAR2(32) := CONSTANTS.MIME_TYPE_XML;
g_MIME_TYPE_CSV        		CONSTANT VARCHAR2(32) := CONSTANTS.MIME_TYPE_CSV;
g_CSV_DATE_FORMAT      		CONSTANT VARCHAR2(8)  := MM_TDIE_UTIL.g_CSV_DATE_FORMAT;
g_XML_DATE_FORMAT      		CONSTANT VARCHAR2(10) := MM_TDIE_UTIL.g_XML_DATE_FORMAT;
g_DBG_DATETIME_FORMAT  		CONSTANT VARCHAR2(25) := 'MM-DD-YYYY HH24:MI:SS';
g_ACTION_DEL           		CONSTANT VARCHAR2(3)  := 'DEL';
g_ACTION_INS           		CONSTANT VARCHAR2(3)  := 'INS';
g_CRLF                 		CONSTANT VARCHAR2(10) := UTL_TCP.CRLF;
g_SUCCESS              		CONSTANT NUMBER       := GA.SUCCESS;
g_FAILURE              		CONSTANT NUMBER       := 1; -- No Constant Exists.
g_INTERNAL_STATE		  	CONSTANT NUMBER(1)    := CONSTANTS.INTERNAL_STATE;
g_LOW_DATE             		CONSTANT DATE         := CONSTANTS.LOW_DATE;
g_NI_HARMONISATION_VERSION	TDIE_MESSAGE.VERSION_NUMBER%TYPE;

--------------------------------------------------------------------------------
--                  PRIVATE PROCEDURES AND FUNCTIONS
--------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
PROCEDURE GET_VALIDATION_DATE_RANGE
    (
    p_PREVIOUS_READ_DATE IN DATE,
    p_READ_OR_MSG_DATE IN DATE,
    p_BEGIN_DATE OUT DATE,
    p_END_DATE OUT DATE
    ) AS

BEGIN

    p_BEGIN_DATE := NVL(p_PREVIOUS_READ_DATE+1, p_READ_OR_MSG_DATE);
    p_END_DATE := p_READ_OR_MSG_DATE;

END GET_VALIDATION_DATE_RANGE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_EARN_SERVICE_POINT_ID(
   p_UNIT_ID      IN VARCHAR2,
   p_IS_NIE       IN BOOLEAN,
   p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
   ) RETURN NUMBER IS

   V_SP_ID       NUMBER(9);
   v_GEN_NAME    VARCHAR2(32);

BEGIN

   IF p_IS_NIE THEN
      v_GEN_NAME := p_UNIT_ID || ' (NI NPG)';
   ELSE
      v_GEN_NAME := p_UNIT_ID;
   END IF;

   RETURN EI.GET_ID_FROM_IDENTIFIER_EXTSYS(v_GEN_NAME,
                                               EC.ED_SERVICE_POINT,
                                               EC.ES_TDIE,
                                               EI.g_DEFAULT_IDENTIFIER_TYPE
                                               );

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		IF p_CREATE_IF_NOT_FOUND THEN
			-- Create the service point
			BEGIN
				SAVEPOINT BEFORE_CREATE;

				IO.PUT_SERVICE_POINT(V_SP_ID, -- ID
					 v_GEN_NAME, -- NAME
					 NULL, -- ALIAS
					 NULL, -- DESC
					 0, -- 0 == CREATE NEW
					 'Generation',  -- SERVICE_POINT_TYPE
					 NULL, -- TP_ID
					 NULL, -- CA_ID
					 NULL, -- EDC_ID
					 NULL, -- ROLLUP_ID
					 NULL, -- SERVICE_REGION_ID
					 NULL, -- SERVICE_AREA_ID
					 NULL, -- SERVICE_ZONE_ID
					 MM_SEM_UTIL.g_TZ, -- TIME_ZONE
					 NULL, -- LATITUDE
					 NULL, -- LONGITUDE
					 v_GEN_NAME, -- EXTERNAL_IDENTIFIER
					 NULL, -- IS_INTERCONNECT
					 NULL, -- NODE_TYPE
					 NULL, -- SERVICE_POINT_NERC_CODE
					 NULL, -- PIPELINE_ID
					 NULL); -- MILE_MARKER

				EM.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_TDIE, EC.ED_SERVICE_POINT, V_SP_ID,
						EI.g_DEFAULT_IDENTIFIER_TYPE, v_GEN_NAME, EI.g_DEFAULT_IDENTIFIER_TYPE);

				RETURN v_SP_ID;

			EXCEPTION
				WHEN OTHERS THEN
					ERRS.LOG_AND_RAISE(p_SAVEPOINT_NAME => 'BEFORE_CREATE');
			END;

		ELSE
			ERRS.LOG_AND_RAISE;
		END IF;

END GET_EARN_SERVICE_POINT_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_EARN_TRANSACTION_ID(
   p_SERVICE_POINT_ID    IN NUMBER,
   p_IS_NIE      		 IN BOOLEAN,
   p_TRANSACTION_NAME	 IN VARCHAR2,
   p_TRANSACTION_IDENTIFIER IN VARCHAR2,
   p_MESSAGE_DATE		 IN DATE := SYSDATE,
   p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
   ) RETURN NUMBER IS

   v_ID          NUMBER(9);
   v_COUNT_TXNS  NUMBER;
   v_GEN_NAME    VARCHAR2(32);
   v_COMM_ID	 NUMBER(9);

BEGIN
	v_COMM_ID := EI.GET_ID_FROM_ALIAS('Energy', EC.ED_IT_COMMODITY);

   	SELECT MAX(IT.TRANSACTION_ID), COUNT(IT.TRANSACTION_ID)
	INTO v_ID, v_COUNT_TXNS
    FROM INTERCHANGE_TRANSACTION IT
    WHERE IT.POD_ID = p_SERVICE_POINT_ID
		AND IT.TRANSACTION_TYPE = 'Generation'
		AND IT.COMMODITY_ID = v_COMM_ID;

   IF v_COUNT_TXNS > 1 THEN

      ERRS.RAISE(MSGCODES.c_ERR_TOO_MANY_ENTRIES, 'More than one transaction was found for Generation Unit: '
         || TEXT_UTIL.TO_CHAR_ENTITY(p_SERVICE_POINT_ID, EC.ED_SERVICE_POINT));

   END IF;

   IF v_ID IS NULL AND NOT p_CREATE_IF_NOT_FOUND THEN

      ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'No transaction was found for Generation Unit: '
         || TEXT_UTIL.TO_CHAR_ENTITY(p_SERVICE_POINT_ID, EC.ED_SERVICE_POINT));

   ELSIF v_ID IS NULL THEN
		v_GEN_NAME := ENTITY_UTIL.RESOLVE_ENTITY_NAME_CONFLICT(p_TRANSACTION_NAME, EC.ED_TRANSACTION);

		IO.PUT_TRANSACTION(v_ID, -- TRANSACTION ID
                  v_GEN_NAME,  -- TRANSACTION NAME
                  NULL, -- TRANSACTION ALIAS
                  NULL, -- DESC
                  0, -- 0 == CREATE NEW
                  'Generation', -- TYPE
                  NULL, -- CODE
                  p_TRANSACTION_IDENTIFIER, -- IDENTIFIER
                  NULL, -- IS_FIRM
                  NULL, -- IS_IMPORT_SCHEDULE
                  NULL, -- IS_EXPORT_SCHEDULE
                  NULL, -- IS_BALANCE_TRANSACTION
                  NULL, -- IS_BID_OFFER
                  NULL, -- IS_EXCLUDE_FROM_POSITION
                  NULL, -- IS_IMPORT_EXPORT
                  NULL, -- IS_DISPATCHABLE
                  CASE WHEN p_IS_NIE THEN '30 Minute' ELSE '15 Minute' END, -- INTERVAL
                  NULL, -- EXTERNAL_INTERVAL
                  NULL, -- ETAG_CODE
                  TRUNC(LEAST(p_MESSAGE_DATE, SYSDATE), 'YY'), -- JAN 1 OF CURRENT YEAR OR
				  												-- MESSAGE YEAR, WHICHEVER IS FIRST
                  MM_TDIE_UTIL.g_TDIE_TXN_END_DATE, -- END_DATE
                  NULL, -- PURACHASER_ID
                  NULL, -- SELLER_ID
                  NULL, -- CONTRACT_ID
                  CASE WHEN p_IS_NIE THEN
                     MM_TDIE_UTIL.g_NIE_SC_ID
                  ELSE
                     MM_TDIE_UTIL.g_ESBN_SC_ID
                  END, -- SC_ID
                  NULL, -- POR_ID
                  p_SERVICE_POINT_ID, -- POD_ID
                  v_COMM_ID, -- COMMODITY
                  NULL, -- SERVICE_TYPE
                  NULL, -- TX_TXN_ID
                  NULL, -- PATH_ID
                  NULL, -- LINK_TXN_ID
                  NULL, -- EDC_ID
                  NULL, -- PSE_ID
                  NULL, -- ESP_ID
                  NULL, -- POOL_ID
                  NULL, -- SCHEDULE_GROUP_ID
                  NULL, -- MARKET_PRICE_ID
                  NULL, -- ZOR_ID
                  NULL, -- ZOD_ID
     				NULL, -- SOURCE_ID
					NULL, -- SINK_ID
					NULL, -- RESOURCE_ID
					NULL, -- AGGREMENT_TYPE
					NULL, -- APPROVAL_TYPE,
					NULL, -- LOSS_OPTION
					NULL, --TRAIT_CATEGORY
					NULL); -- TP_ID
	END IF;

	RETURN v_ID;
END GET_EARN_TRANSACTION_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_FOR_MPRN
	(
	p_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IS_VALID IN OUT BOOLEAN
	) RETURN NUMBER IS

	v_RETURN NUMBER(9);

BEGIN

	v_RETURN := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_IDENTIFIER, p_ENTITY_DOMAIN_ID, EC.ES_TDIE, EI.g_DEFAULT_IDENTIFIER_TYPE,
					1);

	IF v_RETURN IS NULL THEN
		LOGS.LOG_ERROR('No ' || TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_DOMAIN_ID, EC.ED_ENTITY_DOMAIN)
			|| ' was found for identifier ' || p_IDENTIFIER);
		p_IS_VALID := FALSE;
	END IF;

	RETURN v_RETURN;

END GET_ENTITY_FOR_MPRN;
----------------------------------------------------------------------------------------------------
FUNCTION GET_EARN_TRANSACTION_ID(
   p_UNIT_ID      IN VARCHAR2,
   p_IS_NIE       IN BOOLEAN,
   p_MESSAGE_DATE IN DATE,
   p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
   ) RETURN NUMBER IS

   v_SP_ID 	NUMBER(9);
   v_TXN_NAME VARCHAR2(64);
BEGIN
	v_SP_ID := GET_EARN_SERVICE_POINT_ID(p_UNIT_ID, p_IS_NIE, p_CREATE_IF_NOT_FOUND);

	v_TXN_NAME := EI.GET_ENTITY_NAME(EC.ED_SERVICE_POINT, v_SP_ID) ||CASE WHEN p_IS_NIE THEN NULL
														ELSE ' (' || p_UNIT_ID || ')' END;
    RETURN GET_EARN_TRANSACTION_ID(v_SP_ID,
									p_IS_NIE,
									v_TXN_NAME,
									v_TXN_NAME,
									p_MESSAGE_DATE,
									p_CREATE_IF_NOT_FOUND);
END GET_EARN_TRANSACTION_ID;
--------------------------------------------------------------------------------
FUNCTION IS_NI_HARMONISATION_VERSION
(
  p_VERSION_NUMBER  IN VARCHAR2,
  p_MESSAGE_TYPE_CODE IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER IS
BEGIN
   /* -- Check if the normal version information is obtained from the "NI Schema Version"
  IF g_NI_HARMONISATION_VERSION IS NULL THEN
    -- If above is NULL, then try the specific MessageTypeCode related version
    g_NI_HARMONISATION_VERSION := GET_DICTIONARY_VALUE(p_SETTING_NAME => 'NI Schema Version' || ' ' || p_MESSAGE_TYPE_CODE
                           ,p_MODEL_ID    => 0
                           ,p_MODULE    => 'MarketExchange'
                           ,p_KEY1      => 'TDIE'
                           ,p_KEY2      => 'Harmonisation');
  END IF;

  IF TRIM(p_VERSION_NUMBER) = TRIM(g_NI_HARMONISATION_VERSION) THEN
    RETURN 1;
  ELSE
    RETURN 0;
  END IF;*/
  --09/24/2015 [SFDC 337315] Non Harmonized versions are no longer supported
  --09/24/2015 [SFDC 337315] Assume that all versions are harmonized
  RETURN 1;
END IS_NI_HARMONISATION_VERSION;
--------------------------------------------------------------------------------
FUNCTION GET_JURISDICTION_FOR_IMPORTS(p_RECIPIENT_CID IN VARCHAR2) RETURN VARCHAR2 IS
v_NI_COUNT NUMBER := 0;
v_ROI_COUNT NUMBER := 0;
v_JURISDICTION VARCHAR2(4);
BEGIN
	-- We are using the list of Recipients in order to determine the Jurisdiction.
    -- The assumption is that we should never have the same Recipient ID in multiple Jurisdictions.
    -- We verified this against the list of Recipients in the NI Harmonisation documentation.
    SELECT COUNT(1)
    INTO v_NI_COUNT
    FROM SYSTEM_LABEL
    WHERE MODEL_ID = 0
    AND MODULE = 'MarketExchange'
    AND KEY1 = 'TDIE'
    AND KEY2 = 'Recipient List'
    AND KEY3 = 'NI'
    AND NVL(IS_HIDDEN,0) = 0
    AND VALUE = p_RECIPIENT_CID;

    IF v_NI_COUNT = 0 THEN
		SELECT COUNT(1)
        INTO v_ROI_COUNT
        FROM SYSTEM_LABEL
        WHERE MODEL_ID = 0
        AND MODULE = 'MarketExchange'
        AND KEY1 = 'TDIE'
        AND KEY2 = 'Recipient List'
        AND KEY3 = 'ROI'
        AND NVL(IS_HIDDEN,0) = 0
        AND VALUE = p_RECIPIENT_CID;

        IF v_ROI_COUNT = 0 THEN
		    -- The customer must set up this list of Recipients ahead of time.
            ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'Recipient ID ' || p_RECIPIENT_CID || ' was not found in System Settings (Global->MarketExchange->TDIE->Recipient List).');
        ELSE
			-- found it in ROI!
            v_JURISDICTION := MM_TDIE_UTIL.c_TDIE_JURISDICTION_ROI;
        END IF;
    ELSE
		-- found it in NI!
        v_JURISDICTION := MM_TDIE_UTIL.c_TDIE_JURISDICTION_NI;
    END IF;

    RETURN v_JURISDICTION;
END GET_JURISDICTION_FOR_IMPORTS;
--------------------------------------------------------------------------------
FUNCTION DETERMINE_STATEMENT_TYPE (
	p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2,
	p_SETTLEMENT_DATE          IN DATE,
	p_SEM_STATEMENT_TYPE	   IN BOOLEAN
	) RETURN NUMBER IS

	v_ST_ID          NUMBER(9);
	v_REV_INDICATOR  VARCHAR2(32);
	-- TODO: This v_NEXT_SAT is different than SEM_SETTLEMENT_COMP.DETERMINE_SLMT_RUN_INDICATOR
	v_NEXT_SAT       DATE := TRUNC(NEXT_DAY(FROM_CUT(p_SETTLEMENT_DATE, 'EDT') - 1, 'SAT'));
    v_REV_NUM        VARCHAR2(10) := NULL;
	v_STATEMENT_TYPE VARCHAR2(1);

BEGIN

	IF p_SETTLEMENT_RUN_INDICATOR IN ('10', 'D+1') THEN
		v_STATEMENT_TYPE := 'P'; -- INDICATIVE
	ELSIF p_SETTLEMENT_RUN_INDICATOR IN ('20', 'D+4') THEN
		v_STATEMENT_TYPE := 'F'; -- INITIAL
	ELSE
    	BEGIN
    		SELECT FIRST_VALUE(C.RUN_IDENTIFIER) OVER (ORDER BY C.PUBLICATION_DATE)
      		INTO v_REV_INDICATOR
    		FROM SEM_SETTLEMENT_CALENDAR C
    		WHERE C.MARKET = MM_SEM_SETTLEMENT_CALENDAR.c_MARKET_ENERGY
    		  AND C.PUBLICATION_TYPE = MM_SEM_SETTLEMENT_CALENDAR.c_PUBLICATION_TYPE_INVOICE -- TODO: Is this correct?
    		  AND C.END_DATE = v_NEXT_SAT
    		  AND C.RUN_TYPE = CASE WHEN p_SETTLEMENT_RUN_INDICATOR IN ('30', 'M+4') THEN MM_SEM_SETTLEMENT_CALENDAR.c_RUN_TYPE_M4
                                    WHEN p_SETTLEMENT_RUN_INDICATOR IN ('40', 'M+13') THEN MM_SEM_SETTLEMENT_CALENDAR.c_RUN_TYPE_M13
                                    WHEN p_SETTLEMENT_RUN_INDICATOR IN ('50', 'ADHOC') THEN MM_SEM_SETTLEMENT_CALENDAR.c_RUN_TYPE_ADHOC
    						   END;

    	EXCEPTION WHEN NO_DATA_FOUND THEN
    		ERRS.RAISE(MSGCODES.c_ERR_GENERAL, 'No revision calendar entry found for run indicator ' || p_SETTLEMENT_RUN_INDICATOR
    			|| ' on settlement date ' || TEXT_UTIL.TO_CHAR_DATE(p_SETTLEMENT_DATE) || '.');
    	END;

    	v_STATEMENT_TYPE := UPPER(SUBSTR(v_REV_INDICATOR, 1, 1));
    	v_REV_NUM := REGEXP_SUBSTR(v_REV_INDICATOR, '([0-9]+)');
	END IF;

	v_ST_ID := MM_UTIL.DETERMINE_STATEMENT_TYPE(v_STATEMENT_TYPE, v_REV_NUM,
					CASE WHEN p_SEM_STATEMENT_TYPE THEN EC.ES_SEM ELSE EC.ES_TDIE END, -- which external system?
					CASE WHEN p_SEM_STATEMENT_TYPE -- SEM uses a custom external identifier type
						THEN MM_SEM_UTIL.g_STATEMENT_TYPE_SETTLEMENT
						ELSE EI.g_DEFAULT_IDENTIFIER_TYPE END,
					CASE WHEN p_SEM_STATEMENT_TYPE -- USE THE T&D prefix only when TDIE statement type
						THEN NULL
						ELSE MM_TDIE_UTIL.g_TDIE_STATEMENT_TYPE_PREFIX END);


	RETURN v_ST_ID;

END DETERMINE_STATEMENT_TYPE;
--------------------------------------------------------------------------------
-- This is a private function to format the given table record into a string.
FUNCTION TO_CHAR_TDIE_MSG(
   p_REC     IN TDIE_MESSAGE%ROWTYPE,
   p_ACTION  IN VARCHAR2
   ) RETURN VARCHAR2 IS

   v_RETURN    VARCHAR2(2000) := NULL;
BEGIN

   CASE p_ACTION
      WHEN g_ACTION_DEL THEN
         v_RETURN := 'MESSAGE_TYPE_CODE        = '||p_REC.MESSAGE_TYPE_CODE||', '||g_CRLF
                   ||'LOCATION_ID              = '||p_REC.LOCATION_ID||', '||g_CRLF
                   ||'SETTLEMENT_RUN_INDICATOR = '||p_REC.SETTLEMENT_RUN_INDICATOR||', '||g_CRLF
                   ||'MESSAGE_DATE             = '||TO_CHAR(p_REC.MESSAGE_DATE,g_DBG_DATETIME_FORMAT)||'.';

      WHEN g_ACTION_INS THEN
         v_RETURN := 'TDIE_ID                  = '||TO_CHAR(p_REC.TDIE_ID)||', '||g_CRLF
                   ||'MESSAGE_TYPE_CODE        = '||p_REC.MESSAGE_TYPE_CODE||', '||g_CRLF
                   ||'LOCATION_ID              = '||p_REC.LOCATION_ID||', '||g_CRLF
                   ||'SETTLEMENT_RUN_INDICATOR = '||p_REC.SETTLEMENT_RUN_INDICATOR||', '||g_CRLF
                   ||'MESSAGE_DATE             = '||TO_CHAR(p_REC.MESSAGE_DATE,g_DBG_DATETIME_FORMAT)||g_CRLF
                   ||'END_PERIOD_TIME          = '||TO_CHAR(p_REC.END_PERIOD_TIME,g_DBG_DATETIME_FORMAT)||g_CRLF
                   ||'MARKET_TIMESTAMP         = '||TO_CHAR(p_REC.MARKET_TIMESTAMP,g_DBG_DATETIME_FORMAT)||g_CRLF
                   ||'RECIPIENT_ID             = '||p_REC.RECIPIENT_ID||', '||g_CRLF
                   ||'SENDER_ID                = '||p_REC.SENDER_ID||', '||g_CRLF
                   ||'TX_REF_NUMBER            = '||p_REC.TX_REF_NUMBER||', '||g_CRLF
                   ||'SSAC                     = '||p_REC.SSAC||', '||g_CRLF
                   ||'PERCENT_CONS_ACT         = '||TO_CHAR(p_REC.PERCENT_CONS_ACT)||', '||g_CRLF
                   ||'PERCENT_MPRN_EST         = '||TO_CHAR(p_REC.PERCENT_MPRN_EST)||', '||g_CRLF
                   ||'SUPPLIER_MPID            = '||p_REC.SUPPLIER_MPID||', '||g_CRLF
                   ||'PROCESS_ID               = '||TO_CHAR(p_REC.PROCESS_ID)||'.';

      ELSE
         -- Throw invalid action warning.
         v_RETURN := NULL;
   END CASE;--CASE p_ACTION

   RETURN v_RETURN;
END TO_CHAR_TDIE_MSG;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_AGG_CONSUMPTION ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_AGG_CONS(
   p_REC     IN TDIE_AGG_CONSUMPTION%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_ID                   = '||TO_CHAR(p_REC.TDIE_ID)||', '||g_CRLF
        ||'INTERVAL_PERIOD_TIMESTAMP = '||TO_CHAR(p_REC.INTERVAL_PERIOD_TIMESTAMP,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'AGGREGATED_CONSUMPTION    = '||TO_CHAR(p_REC.AGGREGATED_CONSUMPTION)||', '||g_CRLF
        ||'LA_AGGREGATED_CONSUMPTION = '||TO_CHAR(p_REC.LA_AGGREGATED_CONSUMPTION)||', '||g_CRLF
        ||'UNDER_REVIEW              = '||TO_CHAR(p_REC.UNDER_REVIEW)||'.';
END TO_CHAR_TDIE_AGG_CONS;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_AGG_CONSUMPTION_DLF ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_AGG_CONS_DLF(
   p_REC     IN TDIE_AGG_CONSUMPTION_DLF%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_DETAIL_ID    = '||TO_CHAR(p_REC.TDIE_DETAIL_ID)||', '||g_CRLF
        ||'TDIE_ID           = '||TO_CHAR(p_REC.TDIE_ID)||', '||g_CRLF
        ||'DLF_CODE          = '||p_REC.DLF_CODE||', '||g_CRLF
        ||'LOAD_PROFILE_CODE = '||p_REC.LOAD_PROFILE_CODE||', '||g_CRLF
        ||'MPRN_TALLY        = '||TO_CHAR(p_REC.MPRN_TALLY)||'.';
END TO_CHAR_TDIE_AGG_CONS_DLF;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_AGG_CONSUMPTION_DLF_DTL ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_AGG_CONS_DLF_DTL(
   p_REC     IN TDIE_AGG_CONSUMPTION_DLF_DTL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_DETAIL_ID            = '||TO_CHAR(p_REC.TDIE_DETAIL_ID)||', '||g_CRLF
        ||'INTERVAL_PERIOD_TIMESTAMP = '||TO_CHAR(p_REC.INTERVAL_PERIOD_TIMESTAMP,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'AGGREGATED_CONSUMPTION    = '||TO_CHAR(p_REC.AGGREGATED_CONSUMPTION)||', '||g_CRLF
        ||'LA_AGGREGATED_CONSUMPTION = '||TO_CHAR(p_REC.LA_AGGREGATED_CONSUMPTION)||'.';
END TO_CHAR_TDIE_AGG_CONS_DLF_DTL;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_SMO_CONSUMPTION ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_SMO_CONSUMPTION(
   p_REC     IN TDIE_SMO_CONSUMPTION%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_ID             = '||TO_CHAR(p_REC.TDIE_ID)||', '||g_CRLF
        ||'START_TIME          = '||TO_CHAR(p_REC.START_TIME,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'END_TIME            = '||TO_CHAR(p_REC.END_TIME,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'MEASURED_QUANTITY   = '||TO_CHAR(p_REC.MEASURED_QUANTITY)||', '||g_CRLF
        ||'QUERY_FLAG          = '||TO_CHAR(p_REC.QUERY_FLAG)||', '||g_CRLF
        ||'READING_DATA_STATUS = '||TO_CHAR(p_REC.READING_DATA_STATUS)||', '||g_CRLF
        ||'READING_NUMBER      = '||TO_CHAR(p_REC.READING_NUMBER)||'.';
END;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_AGG_GENERATION ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_AGG_GENERATION(
   p_REC     IN TDIE_AGG_GENERATION%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_ID                   = '||TO_CHAR(p_REC.TDIE_ID)||', '||g_CRLF
        ||'INTERVAL_PERIOD_TIMESTAMP = '||TO_CHAR(p_REC.INTERVAL_PERIOD_TIMESTAMP,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'METERED_GENERATION        = '||TO_CHAR(p_REC.METERED_GENERATION)||', '||g_CRLF
        ||'LA_METERED_GENERATION     = '||TO_CHAR(p_REC.LA_METERED_GENERATION)||'.';
END TO_CHAR_TDIE_AGG_GENERATION;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_NIETD ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_NIETD(
   p_REC     IN TDIE_NIETD%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_DETAIL_ID           = '||TO_CHAR(p_REC.TDIE_DETAIL_ID)||', '||g_CRLF
        ||'TDIE_ID                  = '||TO_CHAR(p_REC.TDIE_ID)||', '||g_CRLF
        ||'LOAD_PROFILE             = '||p_REC.LOAD_PROFILE||', '||g_CRLF
        ||'LINE_LOSS_FACTOR_ID      = '||p_REC.LINE_LOSS_FACTOR_ID||', '||g_CRLF
        ||'LINE_LOSS_INDICATOR      = '||p_REC.LINE_LOSS_INDICATOR||', '||g_CRLF
        ||'IMP_EXP_INDICATOR        = '||p_REC.IMP_EXP_INDICATOR||', '||g_CRLF
        ||'METER_VALUE_INDICATOR    = '||p_REC.METER_VALUE_INDICATOR||', '||g_CRLF
        ||'UOS_TARIFF               = '||p_REC.UOS_TARIFF||', '||g_CRLF
        ||'METER_CONFIGURATION_CODE = '||p_REC.METER_CONFIGURATION_CODE||', '||g_CRLF
        ||'TIME_SLOT                = '||p_REC.TIME_SLOT||'.';
END;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_NIETD_DETAIL ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_NIETD_DETAIL(
   p_REC     IN TDIE_NIETD_DETAIL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_DETAIL_ID    = '||TO_CHAR(p_REC.TDIE_DETAIL_ID)||', '||g_CRLF
        ||'SCHEDULE_DATE     = '||TO_CHAR(p_REC.SCHEDULE_DATE,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'ENERGY_TYPE       = '||p_REC.ENERGY_TYPE||', '||g_CRLF
        ||'ENERGY            = '||TO_CHAR(p_REC.ENERGY)||', '||g_CRLF
        ||'ACT_EST_INDICATOR = '||p_REC.ACT_EST_INDICATOR||'.';
END TO_CHAR_TDIE_NIETD_DETAIL;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_34X_MPRN ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_34X_MPRN(
   p_REC     IN TDIE_34X_MPRN%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_MPRN_MSG_ID  = '||TO_CHAR(p_REC.TDIE_MPRN_MSG_ID)||', '||g_CRLF
        ||'MPRN              = '||p_REC.MPRN||', '||g_CRLF
        ||'READ_DATE         = '||TO_CHAR(p_REC.READ_DATE,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'MARKET_TIMESTAMP  = '||TO_CHAR(p_REC.MARKET_TIMESTAMP,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'MESSAGE_TYPE_CODE = '||p_REC.MESSAGE_TYPE_CODE||', '||g_CRLF
        ||'TX_REF_NUMBER     = '||p_REC.TX_REF_NUMBER||', '||g_CRLF
        ||'RECIPIENT_CID     = '||p_REC.RECIPIENT_CID||', '||g_CRLF
        ||'SENDER_CID        = '||p_REC.SENDER_CID||', '||g_CRLF
        ||'SUPPLIER_MPID     = '||p_REC.SUPPLIER_MPID||', '||g_CRLF
        ||'VERSION_NUMBER    = '||p_REC.VERSION_NUMBER||', '||g_CRLF
        ||'PROCESS_ID        = '||TO_CHAR(p_REC.PROCESS_ID)||'.';
END TO_CHAR_TDIE_34X_MPRN;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_34X_MPRN_CHANNEL ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_34X_MPRN_CHANNEL(
   p_REC     IN TDIE_34X_MPRN_CHANNEL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_MPRN_CHANNEL_ID = '||TO_CHAR(p_REC.TDIE_MPRN_CHANNEL_ID)||', '||g_CRLF
        ||'TDIE_MPRN_MSG_ID     = '||TO_CHAR(p_REC.TDIE_MPRN_MSG_ID)||', '||g_CRLF
        ||'METER_CATEGORY_CODE  = '||p_REC.METER_CATEGORY_CODE||', '||g_CRLF
        ||'SERIAL_NUMBER        = '||p_REC.SERIAL_NUMBER||', '||g_CRLF
        ||'METERING_INTERVAL    = '||TO_CHAR(p_REC.METERING_INTERVAL)||', '||g_CRLF
        ||'REGISTER_TYPE_CODE   = '||p_REC.REGISTER_TYPE_CODE||', '||g_CRLF
        ||'UOM_CODE             = '||p_REC.UOM_CODE||'.';
END TO_CHAR_TDIE_34X_MPRN_CHANNEL;

--------------------------------------------------------------------------------
-- Private function that converts a TDIE_34X_INTERVAL ROWTYPE to a string.
FUNCTION TO_CHAR_TDIE_34X_INTERVAL(
   p_REC     IN TDIE_34X_INTERVAL%ROWTYPE
   ) RETURN VARCHAR2 IS
BEGIN
   RETURN 'TDIE_MPRN_CHANNEL_ID      = '||TO_CHAR(p_REC.TDIE_MPRN_CHANNEL_ID)||', '||g_CRLF
        ||'INTERVAL_PERIOD_TIMESTAMP = '||TO_CHAR(p_REC.INTERVAL_PERIOD_TIMESTAMP,g_DBG_DATETIME_FORMAT)||', '||g_CRLF
        ||'INTERVAL_STATUS_CODE      = '||p_REC.INTERVAL_STATUS_CODE||', '||g_CRLF
        ||'INTERVAL_VALUE            = '||TO_CHAR(p_REC.INTERVAL_VALUE)||'.';
END TO_CHAR_TDIE_34X_INTERVAL;

--------------------------------------------------------------------------------
FUNCTION DEL_TDIE_MESSAGE (
   p_REC IN TDIE_MESSAGE%ROWTYPE
   ) RETURN NUMBER IS

   v_RETURN                 NUMBER(1) := 0;
   v_CHK_MARKET_TIMESTAMP   TDIE_MESSAGE.MARKET_TIMESTAMP%TYPE;

BEGIN
   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_MSG(p_REC, g_ACTION_DEL));
   END IF;

   BEGIN
      SELECT TM.MARKET_TIMESTAMP
        INTO v_CHK_MARKET_TIMESTAMP
        FROM TDIE_MESSAGE TM
       WHERE TM.MESSAGE_TYPE_CODE        = p_REC.MESSAGE_TYPE_CODE
         AND TM.LOCATION_ID              = p_REC.LOCATION_ID
         AND TM.SETTLEMENT_RUN_INDICATOR = p_REC.SETTLEMENT_RUN_INDICATOR
         AND TM.MESSAGE_DATE             = p_REC.MESSAGE_DATE;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_RETURN := g_SUCCESS;
         GOTO DELETE_END;
   END;

   -- If the value exists with an older MARKET_TIMESTAMP then delete the record
   -- (this will also delete cascade all child records. If the value is newer,
   -- the log a warning message and skip the import.
   IF v_CHK_MARKET_TIMESTAMP <= p_REC.MARKET_TIMESTAMP THEN
      -- Process the delete.
      DELETE FROM TDIE_MESSAGE TM
       WHERE TM.MESSAGE_TYPE_CODE        = p_REC.MESSAGE_TYPE_CODE
         AND TM.LOCATION_ID              = p_REC.LOCATION_ID
         AND TM.SETTLEMENT_RUN_INDICATOR = p_REC.SETTLEMENT_RUN_INDICATOR
         AND TM.MESSAGE_DATE             = p_REC.MESSAGE_DATE;

      v_RETURN := g_SUCCESS;

   ELSE
      -- Dont process the delete.
      v_RETURN := g_FAILURE;
      LOGS.LOG_WARN(p_EVENT_TEXT => 'Existing data in the database is newer than the file being load.');

   END IF;--IF v_CHK_MARKET_TIMESTAMP <= p_REC.MARKET_TIMESTAMP THEN

   <<DELETE_END>>

   RETURN v_RETURN;

END DEL_TDIE_MESSAGE;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_MESSAGE (
   p_REC IN TDIE_MESSAGE%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_ID IS NOT NULL, 'The TDIE_MESSAGE record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_MSG(p_REC, g_ACTION_INS));
   END IF;

   INSERT INTO TDIE_MESSAGE (TDIE_ID,
                             MESSAGE_TYPE_CODE,
                             LOCATION_ID,
                             SETTLEMENT_RUN_INDICATOR,
                             MESSAGE_DATE,
                             END_PERIOD_TIME,
                             MARKET_TIMESTAMP,
                             RECIPIENT_ID,
                             SENDER_ID,
                             TX_REF_NUMBER,
                             VERSION_NUMBER,
                             SSAC,
                             PERCENT_CONS_ACT,
                             PERCENT_MPRN_EST,
                             SUPPLIER_MPID,
                             PROCESS_ID)
      VALUES (p_REC.TDIE_ID,
              p_REC.MESSAGE_TYPE_CODE,
              p_REC.LOCATION_ID,
              p_REC.SETTLEMENT_RUN_INDICATOR,
              p_REC.MESSAGE_DATE,
              p_REC.END_PERIOD_TIME,
              p_REC.MARKET_TIMESTAMP,
              p_REC.RECIPIENT_ID,
              p_REC.SENDER_ID,
              p_REC.TX_REF_NUMBER,
              p_REC.VERSION_NUMBER,
              p_REC.SSAC,
              p_REC.PERCENT_CONS_ACT,
              p_REC.PERCENT_MPRN_EST,
              p_REC.SUPPLIER_MPID,
              p_REC.PROCESS_ID);

END INS_TDIE_MESSAGE;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_AGG_CONS (
   p_REC IN TDIE_AGG_CONSUMPTION%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_ID IS NOT NULL, 'The TDIE_AGG_CONSUMPTION record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_AGG_CONS(p_REC));
   END IF;

   INSERT INTO TDIE_AGG_CONSUMPTION (TDIE_ID,
                                     INTERVAL_PERIOD_TIMESTAMP,
                                     AGGREGATED_CONSUMPTION,
                                     LA_AGGREGATED_CONSUMPTION,
                                     UNDER_REVIEW)
      VALUES (p_REC.TDIE_ID,
              p_REC.INTERVAL_PERIOD_TIMESTAMP,
              p_REC.AGGREGATED_CONSUMPTION,
              p_REC.LA_AGGREGATED_CONSUMPTION,
              p_REC.UNDER_REVIEW);

END INS_TDIE_AGG_CONS;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_AGG_CONS_DLF (
   p_REC IN TDIE_AGG_CONSUMPTION_DLF%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_DETAIL_ID IS NOT NULL, 'The TDIE_AGG_CONSUMPTION_DLF record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_AGG_CONS_DLF(p_REC));
   END IF;

   INSERT INTO TDIE_AGG_CONSUMPTION_DLF (TDIE_DETAIL_ID,
                                         TDIE_ID,
                                         DLF_CODE,
                                         LOAD_PROFILE_CODE,
                                         MPRN_TALLY)
      VALUES (p_REC.TDIE_DETAIL_ID,
              p_REC.TDIE_ID,
              p_REC.DLF_CODE,
              p_REC.LOAD_PROFILE_CODE,
              p_REC.MPRN_TALLY);

END INS_TDIE_AGG_CONS_DLF;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_AGG_CONS_DLF_DTL (
   p_REC IN TDIE_AGG_CONSUMPTION_DLF_DTL%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_DETAIL_ID IS NOT NULL, 'The TDIE_AGG_CONSUMPTION_DLF_DTL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_AGG_CONS_DLF_DTL(p_REC));
   END IF;

   INSERT INTO TDIE_AGG_CONSUMPTION_DLF_DTL (TDIE_DETAIL_ID,
                                             INTERVAL_PERIOD_TIMESTAMP,
                                             AGGREGATED_CONSUMPTION,
                                             LA_AGGREGATED_CONSUMPTION)
      VALUES (p_REC.TDIE_DETAIL_ID,
              p_REC.INTERVAL_PERIOD_TIMESTAMP,
              p_REC.AGGREGATED_CONSUMPTION,
              p_REC.LA_AGGREGATED_CONSUMPTION);

END INS_TDIE_AGG_CONS_DLF_DTL;


--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_SMO_CONSUMPTION (
   p_REC IN TDIE_SMO_CONSUMPTION%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_ID IS NOT NULL, 'The TDIE_SMO_CONSUMPTION record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_SMO_CONSUMPTION(p_REC));
   END IF;

   INSERT INTO TDIE_SMO_CONSUMPTION (TDIE_ID,
                                     START_TIME,
                                     END_TIME,
                                     MEASURED_QUANTITY,
                                     QUERY_FLAG,
                                     READING_DATA_STATUS,
                                     READING_NUMBER,
									 NIEP)
      VALUES (p_REC.TDIE_ID,
              p_REC.START_TIME,
              p_REC.END_TIME,
              p_REC.MEASURED_QUANTITY,
              p_REC.QUERY_FLAG,
              p_REC.READING_DATA_STATUS,
              p_REC.READING_NUMBER,
			  p_REC.NIEP);

END INS_TDIE_SMO_CONSUMPTION;


--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_AGG_GENERATION (
   p_REC IN TDIE_AGG_GENERATION%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_ID IS NOT NULL, 'The TDIE_AGG_GENERATION record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_AGG_GENERATION(p_REC));
   END IF;

   INSERT INTO TDIE_AGG_GENERATION (TDIE_ID,
                                    INTERVAL_PERIOD_TIMESTAMP,
                                    METERED_GENERATION,
                                    LA_METERED_GENERATION)
      VALUES (p_REC.TDIE_ID,
              p_REC.INTERVAL_PERIOD_TIMESTAMP,
              p_REC.METERED_GENERATION,
              p_REC.LA_METERED_GENERATION);

END INS_TDIE_AGG_GENERATION;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_NIETD (
   p_REC IN TDIE_NIETD%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_DETAIL_ID IS NOT NULL, 'The TDIE_NIETD record must not be null.', MSGCODES.c_ERR_ARGUMENT);

   IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_NIETD(p_REC));
   END IF;

   INSERT INTO TDIE_NIETD (TDIE_DETAIL_ID,
                           TDIE_ID,
                           LOAD_PROFILE,
                           LINE_LOSS_FACTOR_ID,
                           LINE_LOSS_INDICATOR,
                           IMP_EXP_INDICATOR,
                           METER_VALUE_INDICATOR,
                           UOS_TARIFF,
                           AGG_CODE,
                           METER_CONFIGURATION_CODE,
                           TIME_SLOT)
      VALUES (p_REC.TDIE_DETAIL_ID,
              p_REC.TDIE_ID,
              p_REC.LOAD_PROFILE,
              p_REC.LINE_LOSS_FACTOR_ID,
              p_REC.LINE_LOSS_INDICATOR,
              p_REC.IMP_EXP_INDICATOR,
              p_REC.METER_VALUE_INDICATOR,
              p_REC.UOS_TARIFF,
              p_REC.AGG_CODE,
              p_REC.METER_CONFIGURATION_CODE,
              p_REC.TIME_SLOT);

END INS_TDIE_NIETD;


--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_NIETD_DETAIL (
   p_REC IN TDIE_NIETD_DETAIL%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_DETAIL_ID IS NOT NULL, 'The TDIE_NIETD_DETAIL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_NIETD_DETAIL(p_REC));
	END IF;

   INSERT INTO TDIE_NIETD_DETAIL (TDIE_DETAIL_ID,
                                  SCHEDULE_DATE,
                                  ENERGY_TYPE,
                                  ENERGY,
                                  ACT_EST_INDICATOR)
      VALUES (p_REC.TDIE_DETAIL_ID,
              p_REC.SCHEDULE_DATE,
              p_REC.ENERGY_TYPE,
              p_REC.ENERGY,
              p_REC.ACT_EST_INDICATOR);

END INS_TDIE_NIETD_DETAIL;

--------------------------------------------------------------------------------
PROCEDURE DEL_TDIE_34X_MPRN (
   p_REC IN TDIE_34X_MPRN%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_MPRN_MSG_ID IS NOT NULL, 'The TDIE_34X_MPRN record must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_34X_MPRN(p_REC));
	END IF;

   BEGIN
      DELETE FROM TDIE_34X_MPRN M
       WHERE M.MPRN             = p_REC.MPRN
         AND M.READ_DATE        = p_REC.READ_DATE
         AND M.MARKET_TIMESTAMP = p_REC.MARKET_TIMESTAMP
         AND M.GENERATOR_UNITID = p_REC.GENERATOR_UNITID;
      EXCEPTION
      WHEN NO_DATA_FOUND THEN
         -- DO NOTHING
         NULL;
   END;

END DEL_TDIE_34X_MPRN;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_34X_MPRN (
   p_REC IN TDIE_34X_MPRN%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_MPRN_MSG_ID IS NOT NULL, 'The TDIE_34X_MPRN record must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_34X_MPRN(p_REC));
	END IF;

   INSERT INTO TDIE_34X_MPRN (TDIE_MPRN_MSG_ID,
                              MPRN,
                              READ_DATE,
                              MARKET_TIMESTAMP,
                              MESSAGE_TYPE_CODE,
                              TX_REF_NUMBER,
                              RECIPIENT_CID,
                              SENDER_CID,
                              SUPPLIER_MPID,
                              VERSION_NUMBER,
							  GENERATOR_MPID,
							  GENERATOR_UNITID,
							  TRANSFORMER_LOSS_FACTOR,
							  ALERT_FLAG,
							  READING_REPLACEMENT_VER_NUM,
                              PROCESS_ID)
      VALUES (p_REC.TDIE_MPRN_MSG_ID,
              p_REC.MPRN,
              p_REC.READ_DATE,
              p_REC.MARKET_TIMESTAMP,
              p_REC.MESSAGE_TYPE_CODE,
              p_REC.TX_REF_NUMBER,
              p_REC.RECIPIENT_CID,
              p_REC.SENDER_CID,
              p_REC.SUPPLIER_MPID,
              p_REC.VERSION_NUMBER,
			  p_REC.GENERATOR_MPID,
			  p_REC.GENERATOR_UNITID,
              p_REC.TRANSFORMER_LOSS_FACTOR,
              p_REC.ALERT_FLAG,
              p_REC.READING_REPLACEMENT_VER_NUM,
              p_REC.PROCESS_ID);

END INS_TDIE_34X_MPRN;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_34X_MPRN_CHANNEL (
   p_REC IN TDIE_34X_MPRN_CHANNEL%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_MPRN_CHANNEL_ID IS NOT NULL, 'The TDIE_34X_MPRN_CHANNEL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_34X_MPRN_CHANNEL(p_REC));
	END IF;

   INSERT INTO TDIE_34X_MPRN_CHANNEL (TDIE_MPRN_CHANNEL_ID,
                                      TDIE_MPRN_MSG_ID,
                                      METER_CATEGORY_CODE,
                                      SERIAL_NUMBER,
                                      METERING_INTERVAL,
                                      REGISTER_TYPE_CODE,
                                      UOM_CODE)
      VALUES (p_REC.TDIE_MPRN_CHANNEL_ID,
              p_REC.TDIE_MPRN_MSG_ID,
              p_REC.METER_CATEGORY_CODE,
              p_REC.SERIAL_NUMBER,
              p_REC.METERING_INTERVAL,
              p_REC.REGISTER_TYPE_CODE,
              p_REC.UOM_CODE);

END INS_TDIE_34X_MPRN_CHANNEL;

--------------------------------------------------------------------------------
PROCEDURE INS_TDIE_34X_INTERVAL (
   p_REC IN TDIE_34X_INTERVAL%ROWTYPE
   ) IS
BEGIN
   ASSERT(p_REC.TDIE_MPRN_CHANNEL_ID IS NOT NULL, 'The TDIE_34X_INTERVAL record must not be null.', MSGCODES.c_ERR_ARGUMENT);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('p_REC = '||TO_CHAR_TDIE_34X_INTERVAL(p_REC));
	END IF;

   INSERT INTO TDIE_34X_INTERVAL (TDIE_MPRN_CHANNEL_ID,
                                  INTERVAL_PERIOD_TIMESTAMP,
                                  INTERVAL_STATUS_CODE,
                                  INTERVAL_VALUE,
								  NET_ACTIVE_DEMAND_VALUE)
      VALUES (p_REC.TDIE_MPRN_CHANNEL_ID,
              p_REC.INTERVAL_PERIOD_TIMESTAMP,
              p_REC.INTERVAL_STATUS_CODE,
              p_REC.INTERVAL_VALUE,
			  p_REC.NET_ACTIVE_DEMAND_VALUE);

END INS_TDIE_34X_INTERVAL;

--------------------------------------------------------------------------------
-- This private function will determine the file extension from the import file path
--------------------------------------------------------------------------------
FUNCTION GET_FILE_TYPE
   (
   p_IMPORT_FILE_PATH IN VARCHAR2
   )
   RETURN VARCHAR2 IS

   v_RETURN    VARCHAR2(32);
BEGIN

   v_RETURN := CASE
                   WHEN INSTR(UPPER(p_IMPORT_FILE_PATH),'.XML') > 0 THEN
                      g_MIME_TYPE_XML
                    WHEN INSTR(UPPER(p_IMPORT_FILE_PATH),'.CSV') > 0 THEN
                      g_MIME_TYPE_CSV
                    ELSE
                      NULL
                END;

   IF v_RETURN IS NULL THEN
      ERRS.RAISE(MSGCODES.c_ERR_DATA_IMPORT , 'Invalid file type being processed. Must be and .XML or .CSV file.'||
                          ' p_IMPORT_FILE_PATH = '||p_IMPORT_FILE_PATH);
   ELSE
      RETURN v_RETURN;
   END IF;

END GET_FILE_TYPE;


--------------------------------------------------------------------------------
-- This private function will format the t_MESSAGE_HEADER record into a string.
--------------------------------------------------------------------------------
FUNCTION TO_CHAR_NIE_HEADER
   (
   p_NIE_HEADER  IN t_NIE_HEADER
   )
   RETURN VARCHAR2 IS
BEGIN
   RETURN   'TITLE            = '||p_NIE_HEADER.TITLE||CHR(10)
          ||'SUPPLIER_ID      = '||p_NIE_HEADER.SUPPLIER_ID||CHR(10)
          ||'SETTLEMENT_DATE  = '||TEXT_UTIL.TO_CHAR_DATE(p_NIE_HEADER.SETTLEMENT_DATE)||CHR(10)
          ||'SETTLEMENT_TYPE  = '||p_NIE_HEADER.SETTLEMENT_TYPE||CHR(10)
          ||'AGGREGATION_TYPE = '||p_NIE_HEADER.AGGREGATION_TYPE||CHR(10)
          ||'RUN_VERSION      = '||TO_CHAR(p_NIE_HEADER.RUN_VERSION)||CHR(10)
          ||'REPORT_DATE      = '||TEXT_UTIL.TO_CHAR_DATE(p_NIE_HEADER.REPORT_DATE)||CHR(10);
END TO_CHAR_NIE_HEADER;

--------------------------------------------------------------------------------
-- This private function will use an CSV query to parse the MessageHeader CSV
-- element from the inbound CLOB. It will return a type that represents the
-- MessageHeader CSV element.
--------------------------------------------------------------------------------
FUNCTION GET_CSV_MSG_HEADER
   (
   p_IMPORT_FILE IN CLOB
   )
   RETURN t_NIE_HEADER IS

   v_NIE_HEADER        t_NIE_HEADER;
   v_LINES             PARSE_UTIL.BIG_STRING_TABLE_MP;
   v_HEADER_ELEMENTS   PARSE_UTIL.STRING_TABLE;

BEGIN

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_IMPORT_FILE, v_LINES);

   PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(1), ',', v_HEADER_ELEMENTS);

   -- Get the header information from the CSV file.
   v_NIE_HEADER.TITLE            := v_HEADER_ELEMENTS(1);
   v_NIE_HEADER.SUPPLIER_ID      := v_HEADER_ELEMENTS(2);
   v_NIE_HEADER.SETTLEMENT_DATE  := TO_DATE(v_HEADER_ELEMENTS(3), g_CSV_DATE_FORMAT);
   v_NIE_HEADER.SETTLEMENT_TYPE  := v_HEADER_ELEMENTS(4);
   v_NIE_HEADER.AGGREGATION_TYPE := v_HEADER_ELEMENTS(5);
   v_NIE_HEADER.RUN_VERSION      := TO_NUMBER(v_HEADER_ELEMENTS(6));
   v_NIE_HEADER.REPORT_DATE      := TO_DATE(v_HEADER_ELEMENTS(7), g_CSV_DATE_FORMAT);

   RETURN v_NIE_HEADER;
END GET_CSV_MSG_HEADER;


--------------------------------------------------------------------------------
-- This private function will format the t_MESSAGE_HEADER record into a string.
--------------------------------------------------------------------------------
FUNCTION TO_CHAR_MSG_HEADER
   (
   p_MESSAGE_HEADER  IN t_MESSAGE_HEADER
   )
   RETURN VARCHAR2 IS
BEGIN
   RETURN   'MARKET_TIMESTAMP  = '||TEXT_UTIL.TO_CHAR_DATE(p_MESSAGE_HEADER.MARKET_TIMESTAMP)||CHR(10)
          ||'MESSAGE_TYPE_CODE = '||p_MESSAGE_HEADER.MESSAGE_TYPE_CODE||CHR(10)
          ||'RECIPIENT_ID      = '||p_MESSAGE_HEADER.RECIPIENT_ID||CHR(10)
          ||'SENDER_ID         = '||p_MESSAGE_HEADER.SENDER_ID||CHR(10)
          ||'TX_REF_NUMBER     = '||p_MESSAGE_HEADER.TX_REF_NUMBER||CHR(10)
          ||'VERSION_NUMBER    = '||p_MESSAGE_HEADER.VERSION_NUMBER||CHR(10)
		  ||'SUPPLIER_MPID     = '||p_MESSAGE_HEADER.SUPPLIER_MPID||CHR(10);
END TO_CHAR_MSG_HEADER;

--------------------------------------------------------------------------------
-- This private function will use an XML query to parse the MessageHeader XML
-- element from the inbound CLOB. It will return a type that represents the
-- MessageHeader XML element.
--------------------------------------------------------------------------------
FUNCTION GET_XML_MSG_HEADER
   (
   p_IMPORT_FILE IN CLOB
   )
   RETURN t_MESSAGE_HEADER IS

   v_MESSAGE_HEADER     t_MESSAGE_HEADER;
   v_XML                XMLTYPE;

BEGIN

   v_XML := PARSE_UTIL.CREATE_XML_SAFE(p_IMPORT_FILE);

   SELECT DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(T), '//@MarketTimestamp'), 'GMT') AS MARKET_TIMESTAMP,
          EXTRACTVALUE(VALUE(T), '//@MessageTypeCode') AS MESSAGE_TYPE_CODE,
          EXTRACTVALUE(VALUE(T), '//@RecipientID')     AS RECIPIENT_ID,
          EXTRACTVALUE(VALUE(T), '//@SenderID')        AS SENDER_ID,
          EXTRACTVALUE(VALUE(T), '//@TxRefNbr')        AS TX_REF_NUMBER,
          EXTRACTVALUE(VALUE(T), '//@VersionNumber')   AS VERSION_NUMBER,
 		    EXTRACTVALUE(VALUE(T), '//@SupplierMPID')   AS SUPPLIER_MPID
     INTO v_MESSAGE_HEADER.MARKET_TIMESTAMP,
          v_MESSAGE_HEADER.MESSAGE_TYPE_CODE,
          v_MESSAGE_HEADER.RECIPIENT_ID,
          v_MESSAGE_HEADER.SENDER_ID,
          v_MESSAGE_HEADER.TX_REF_NUMBER,
          v_MESSAGE_HEADER.VERSION_NUMBER,
          v_MESSAGE_HEADER.SUPPLIER_MPID
     FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML, '/descendant::*[self::ieXMLDocument or self::niXMLDocument]/MessageHeader'))) T;

   RETURN v_MESSAGE_HEADER;

END GET_XML_MSG_HEADER;
--------------------------------------------------------------------------------
FUNCTION GET_500_XML_MPRN_NODE_NAME
	(
    p_MESSAGE_HEADER  IN t_MESSAGE_HEADER
	) RETURN VARCHAR2 AS

v_XML_NODE_NAME                 VARCHAR2(512);
v_VERSION_UPDATED               NUMBER(1);
v_MESSAGE_CODE_TYPE             TDIE_MESSAGE.MESSAGE_TYPE_CODE%TYPE;

BEGIN

    v_VERSION_UPDATED := IS_NI_HARMONISATION_VERSION(p_MESSAGE_HEADER.VERSION_NUMBER, p_MESSAGE_HEADER.MESSAGE_TYPE_CODE);

    v_MESSAGE_CODE_TYPE := p_MESSAGE_HEADER.MESSAGE_TYPE_CODE;

    CASE v_MESSAGE_CODE_TYPE
        WHEN '591' THEN
            CASE v_VERSION_UPDATED
                WHEN 0 THEN
                    v_XML_NODE_NAME := c_MIM591_NQHAGGREGATION;
                WHEN 1 THEN
                    v_XML_NODE_NAME := c_MIM591_NONINTERVALAGG;
            END CASE;
        WHEN '595' THEN
            CASE v_VERSION_UPDATED
                WHEN 0 THEN
                    v_XML_NODE_NAME := c_MIM595_QHIMPORTAGGREGATION;
                WHEN 1 THEN
                    v_XML_NODE_NAME := c_MIM595_INTERVALIMPAGG;
            END CASE;
        ELSE
            ERRS.RAISE_BAD_ARGUMENT('MESSAGE_TYPE_CODE', v_MESSAGE_CODE_TYPE);
    END CASE;

	RETURN v_XML_NODE_NAME;
END GET_500_XML_MPRN_NODE_NAME;
--------------------------------------------------------------------------------
-- We need to deduce the interval length from the timestamps in the xml
-- Assumptions:
--   1. There are at least two elements in the path
--   2. The SettlementInterval attribute defines the order and that
--      SettlementInterval 2 is immediately after SettlementInterval 1
-- Get the difference in minutes between the timestamps between the first two intervals in the xml
-- This offset will be used to add to the timestamp since the timestamp uses
-- interval beginning convention whereas we store using interval ending convention
PROCEDURE GET_INTERVAL_OFFSET
(
    p_XML_MESSAGE IN XMLTYPE,
	p_XML_PATH IN VARCHAR2,
	p_INTERVAL_OFFSET OUT NUMBER
) IS
BEGIN
	WITH XMLTABLE AS (
        SELECT DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(XMLTABLE), '//@IntervalPeriodTimestamp'), 'GMT') INTERVAL_PERIOD_TIMESTAMP,
			TO_NUMBER(EXTRACTVALUE(VALUE(XMLTABLE), '//@SettlementInterval')) SETTLEMENT_INTERVAL
	    FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, p_XML_PATH))) XMLTABLE
	)
	SELECT (X2.INTERVAL_PERIOD_TIMESTAMP - X1.INTERVAL_PERIOD_TIMESTAMP)*1440
	INTO p_INTERVAL_OFFSET
	FROM XMLTABLE X1,
		 XMLTABLE X2
	WHERE X1.SETTLEMENT_INTERVAL = 1
	  AND X2.SETTLEMENT_INTERVAL = 2;
END GET_INTERVAL_OFFSET;
--------------------------------------------------------------------------------
-- This procedure will be responsible for processing both the 591 and 595 XML
-- messages.
PROCEDURE IMPORT_XML_591_595
   (
   p_MESSAGE_HEADER  IN t_MESSAGE_HEADER,
   p_IMPORT_FILE     IN CLOB
   ) IS

   v_XML_MESSAGE                          XMLTYPE;
   v_XML_ELEMENT_NAME                     VARCHAR2(64);
   v_TDIE_MESSAGE_REC                     TDIE_MESSAGE%ROWTYPE;
   v_TDIE_AGG_CONSUMPTION_REC             TDIE_AGG_CONSUMPTION%ROWTYPE;
   v_TDIE_AGG_CONS_DLF_REC                TDIE_AGG_CONSUMPTION_DLF%ROWTYPE;
   v_TDIE_AGG_CONS_DLF_DTL_REC            TDIE_AGG_CONSUMPTION_DLF_DTL%ROWTYPE;

   v_ADDL_AGG_INFO_ELEMENT_NAME VARCHAR2(100);

   v_INTERVAL_OFFSET NUMBER(2) := 15;

   -----------------------------------------------------------------------------
   -- This cursor is used to process the Aggregated Consumption Messages.
   CURSOR c_AGG_CONSUMPTION(
      p_XML_MESSAGE IN XMLTYPE,
      p_XML_ELEMENT IN VARCHAR2
      ) IS
   SELECT (DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(AC), '//@IntervalPeriodTimestamp'), 'GMT') + v_INTERVAL_OFFSET/1440) AS INTERVAL_PERIOD_TIMESTAMP,
          TO_NUMBER(EXTRACTVALUE(VALUE(AC), '//@AggregatedConsumption'))             AS AGGREGATED_CONSUMPTION,
          TO_NUMBER(EXTRACTVALUE(VALUE(AC), '//@LossAdjustedAggregatedConsumption')) AS LA_AGGREGATED_CONSUMPTION
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, '//ieXMLDocument/'||p_XML_ELEMENT||'/AggregatedConsumption'))) AC;


   -----------------------------------------------------------------------------
   -- This cursor is used to process the Aggregated Consumption
   -- Distribution Loss Factor
   CURSOR c_AGG_CONSUMPTION_DLF(
      p_XML_MESSAGE IN XMLTYPE,
      p_XML_ELEMENT IN VARCHAR2,
      p_ADDL_AGG_INFO_ELEMENT_NAME IN VARCHAR2
      ) IS
   SELECT TDIE_DETAIL_ID.NEXTVAL                              AS TDIE_DETAIL_ID,
          v_TDIE_MESSAGE_REC.TDIE_ID                          AS TDIE_ID,
          EXTRACTVALUE(VALUE(ACD), '//@DLF_Code')             AS DLF_CODE,
          EXTRACTVALUE(VALUE(ACD), '//@LoadProfileCode')      AS LOAD_PROFILE_CODE,
          TO_NUMBER(EXTRACTVALUE(VALUE(ACD), '//@MPRNTally')) AS MPRN_TALLY,
         (EXTRACT(VALUE(ACD), './*'))                         AS o_XML
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, '//ieXMLDocument/'||p_XML_ELEMENT)))  MSG,
          TABLE(XMLSEQUENCE(EXTRACT(VALUE(MSG), p_ADDL_AGG_INFO_ELEMENT_NAME)))  ACD;

   -----------------------------------------------------------------------------
   -- This cursor is used to process the Aggregated Consumption
   -- Distribution Loss Factor Details
   CURSOR c_AGG_CONSUMPTION_DLF_DTL(
      p_XML_MESSAGE IN XMLTYPE,
      p_ADDL_AGG_INFO_ELEMENT_NAME IN VARCHAR2
      ) IS
   SELECT (DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(MSG), '//@IntervalPeriodTimestamp'), 'GMT') + v_INTERVAL_OFFSET/1440) AS INTERVAL_PERIOD_TIMESTAMP,
          TO_NUMBER(EXTRACTVALUE(VALUE(MSG), '//@AggregatedConsumption'))                        AS AGGREGATED_CONSUMPTION,
          TO_NUMBER(EXTRACTVALUE(VALUE(MSG), '//@LossAdjustedAggregatedConsumption'))            AS LA_AGGREGATED_CONSUMPTION
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, p_ADDL_AGG_INFO_ELEMENT_NAME || '/AdditionalAggregationConsumption')))  MSG;


BEGIN
   -- Assuming if the market timestamp attribute of the message header record
   -- is NULL then the entire record is NULL.
   ASSERT(p_MESSAGE_HEADER.MARKET_TIMESTAMP IS NOT NULL, 'The message header must not be null.', MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

   v_XML_MESSAGE := PARSE_UTIL.CREATE_XML_SAFE(p_IMPORT_FILE);

   v_XML_ELEMENT_NAME := GET_500_XML_MPRN_NODE_NAME(p_MESSAGE_HEADER);

   GET_INTERVAL_OFFSET(v_XML_MESSAGE, '//ieXMLDocument/'||v_XML_ELEMENT_NAME||'/AggregatedConsumption', v_INTERVAL_OFFSET);

   v_ADDL_AGG_INFO_ELEMENT_NAME := CASE p_MESSAGE_HEADER.MESSAGE_TYPE_CODE
                            WHEN '591' THEN
                               '//AdditionalAggregationInformation'
                            WHEN '595' THEN
                               '//AdditionalAggregationinformation'
                            ELSE
                               NULL
                         END;--CASE p_MESSAGE_HEADER.MESSAGE_TYPE_CODE

   -----------------------------------------------------------------------------
   -- Populate the TDIE_MESSAGE table record. This will be used to check for
   -- existing data and to insert the parent record for new data.
   SELECT TDIE_ID.NEXTVAL                                                    AS TDIE_ID,
          p_MESSAGE_HEADER.MESSAGE_TYPE_CODE                                 AS MESSAGE_TYPE_CODE,
          EXTRACTVALUE(VALUE(T), '//@SupplierUnitID')                        AS UNIT_ID,
          EXTRACTVALUE(VALUE(T), '//@SettlementRunIndicator')                AS SETTLEMENT_RUN_INDICATOR,
          TO_DATE(EXTRACTVALUE(VALUE(T), '//@SettlementDate'), g_XML_DATE_FORMAT) AS SETTLEMENT_DATE,
          NULL                                                               AS END_PERIOD_TIME,
          p_MESSAGE_HEADER.MARKET_TIMESTAMP                                  AS MARKET_TIMESTAMP,
          p_MESSAGE_HEADER.RECIPIENT_ID                                      AS RECIPIENT_ID,
          p_MESSAGE_HEADER.SENDER_ID                                         AS SENDER_ID,
          p_MESSAGE_HEADER.TX_REF_NUMBER                                     AS TX_REF_NUMBER,
          p_MESSAGE_HEADER.VERSION_NUMBER                                    AS VERSION_NUMBER,
          EXTRACTVALUE(VALUE(T), '//@SSAC')                                  AS SSAC,
          TO_NUMBER(EXTRACTVALUE(VALUE(T), '//@PercntConsAct'))              AS PERCENT_CONS_ACT,
          TO_NUMBER(EXTRACTVALUE(VALUE(T), '//@PercntMPRNEst'))              AS PERCENT_MPRN_EST,
          EXTRACTVALUE(VALUE(T), '//@SupplierMPID')                          AS SUPPLIER_MPID,
          LOGS.CURRENT_PROCESS_ID                                            AS PROCESS_ID
     INTO v_TDIE_MESSAGE_REC.TDIE_ID,
          v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE,
          v_TDIE_MESSAGE_REC.LOCATION_ID,
          v_TDIE_MESSAGE_REC.SETTLEMENT_RUN_INDICATOR,
          v_TDIE_MESSAGE_REC.MESSAGE_DATE,
          v_TDIE_MESSAGE_REC.END_PERIOD_TIME,
          v_TDIE_MESSAGE_REC.MARKET_TIMESTAMP,
          v_TDIE_MESSAGE_REC.RECIPIENT_ID,
          v_TDIE_MESSAGE_REC.SENDER_ID,
          v_TDIE_MESSAGE_REC.TX_REF_NUMBER,
          v_TDIE_MESSAGE_REC.VERSION_NUMBER,
          v_TDIE_MESSAGE_REC.SSAC,
          v_TDIE_MESSAGE_REC.PERCENT_CONS_ACT,
          v_TDIE_MESSAGE_REC.PERCENT_MPRN_EST,
          v_TDIE_MESSAGE_REC.SUPPLIER_MPID,
          v_TDIE_MESSAGE_REC.PROCESS_ID
     FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_MESSAGE, '//ieXMLDocument/'||v_XML_ELEMENT_NAME))) T;

   IF DEL_TDIE_MESSAGE(v_TDIE_MESSAGE_REC) = g_SUCCESS THEN
      INS_TDIE_MESSAGE(v_TDIE_MESSAGE_REC);
   ELSE
      -- If the delete was not sucessful then skip the import of message.
      GOTO IMPORT_XML_591_595_END;
   END IF;

   -----------------------------------------------------------------------------
   -- Assign values to TDIE_AGG_CONSUMPTION record type.
   -- Insert the all the records into the table.
   FOR AC IN c_AGG_CONSUMPTION (v_XML_MESSAGE,
                                v_XML_ELEMENT_NAME) LOOP

      v_TDIE_AGG_CONSUMPTION_REC.TDIE_ID                   := v_TDIE_MESSAGE_REC.TDIE_ID;
      v_TDIE_AGG_CONSUMPTION_REC.INTERVAL_PERIOD_TIMESTAMP := AC.INTERVAL_PERIOD_TIMESTAMP;
      v_TDIE_AGG_CONSUMPTION_REC.AGGREGATED_CONSUMPTION    := AC.AGGREGATED_CONSUMPTION;
      v_TDIE_AGG_CONSUMPTION_REC.LA_AGGREGATED_CONSUMPTION := AC.LA_AGGREGATED_CONSUMPTION;
      v_TDIE_AGG_CONSUMPTION_REC.UNDER_REVIEW              := NULL;

      INS_TDIE_AGG_CONS(v_TDIE_AGG_CONSUMPTION_REC);

   END LOOP;--FOR AC IN c_AGG_CONSUMPTION

   -----------------------------------------------------------------------------
   -- These nested loops will populate the TDIE_AGG_CONSUMPTION_DLF and
   -- TDIE_AGG_CONSUMPTION_DLF_DTL tables.
   --
   -- TDIE_AGG_CONSUMPTION_DLF:     Update to 12 Additional Elements
   -- TDIE_AGG_CONSUMPTION_DLF_DTL: 92, 96, or 100 for each profile code.
   v_TDIE_AGG_CONS_DLF_REC := NULL;
   FOR ACD IN c_AGG_CONSUMPTION_DLF(v_XML_MESSAGE,
                                    v_XML_ELEMENT_NAME,
                                    v_ADDL_AGG_INFO_ELEMENT_NAME) LOOP

      -- Process the parent into the table TDIE_AGG_CONSUMPTION_DLF.
      v_TDIE_AGG_CONS_DLF_REC.TDIE_DETAIL_ID    := ACD.TDIE_DETAIL_ID;
      v_TDIE_AGG_CONS_DLF_REC.TDIE_ID           := ACD.TDIE_ID;
      v_TDIE_AGG_CONS_DLF_REC.DLF_CODE          := ACD.DLF_CODE;
      v_TDIE_AGG_CONS_DLF_REC.LOAD_PROFILE_CODE := ACD.LOAD_PROFILE_CODE;
      v_TDIE_AGG_CONS_DLF_REC.MPRN_TALLY        := ACD.MPRN_TALLY;

      INS_TDIE_AGG_CONS_DLF(v_TDIE_AGG_CONS_DLF_REC);

	  IF v_XML_ELEMENT_NAME = c_MIM591_NQHAGGREGATION AND v_TDIE_AGG_CONS_DLF_REC.LOAD_PROFILE_CODE IS NOT NULL THEN
		  -- Insert Load Profile COde into System_Label
	      SP.ENSURE_SYSTEM_LABELS(0, 'Scheduling', 'TDIE','Load Profile Codes','ROI-NQH',
	  	       v_TDIE_AGG_CONS_DLF_REC.LOAD_PROFILE_CODE, NULL, 0, 0);
	  END IF;

      v_TDIE_AGG_CONS_DLF_DTL_REC := NULL;
      FOR ACDD IN c_AGG_CONSUMPTION_DLF_DTL(ACD.o_XML, v_ADDL_AGG_INFO_ELEMENT_NAME) LOOP

         -- Process the child records into the table TDIE_AGG_CONSUMPTION_DLF_DTL.
         v_TDIE_AGG_CONS_DLF_DTL_REC.TDIE_DETAIL_ID            := v_TDIE_AGG_CONS_DLF_REC.TDIE_DETAIL_ID;
         v_TDIE_AGG_CONS_DLF_DTL_REC.INTERVAL_PERIOD_TIMESTAMP := ACDD.INTERVAL_PERIOD_TIMESTAMP;
         v_TDIE_AGG_CONS_DLF_DTL_REC.AGGREGATED_CONSUMPTION    := ACDD.AGGREGATED_CONSUMPTION;
         v_TDIE_AGG_CONS_DLF_DTL_REC.LA_AGGREGATED_CONSUMPTION := ACDD.LA_AGGREGATED_CONSUMPTION;

         INS_TDIE_AGG_CONS_DLF_DTL(v_TDIE_AGG_CONS_DLF_DTL_REC);

      END LOOP;--FOR ACD IN c_AGG_CONSUMPTION_DLF_DTL

   END LOOP;--FOR ACD IN c_AGG_CONSUMPTION_DLF

   <<IMPORT_XML_591_595_END>>
   NULL;

END IMPORT_XML_591_595;

--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the 596 XML messages.
-- NOTE: This file uses a half-hour interval as opposed to the 15-min interval
-- used in the 591, 595, and 598 messages.
PROCEDURE IMPORT_XML_596
   (
   p_MESSAGE_HEADER  IN t_MESSAGE_HEADER,
   p_IMPORT_FILE     IN CLOB,
   p_PROCESS_IMPORT IN NUMBER
   ) IS

   v_XML_MESSAGE               XMLTYPE;
   v_TDIE_MESSAGE_REC          TDIE_MESSAGE%ROWTYPE;
   v_TDIE_SMO_CONSUMPTION_REC  TDIE_SMO_CONSUMPTION%ROWTYPE;

   -----------------------------------------------------------------------------
   -- This cursor is used to process the SMO Consumption Messages.
   CURSOR c_SMO_CONSUMPTION(
      p_XML_MESSAGE IN XMLTYPE
      ) IS
   SELECT DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(SMO), '//@StartTime'), 'GMT') AS START_TIME,
          DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(SMO), '//@EndTime'), 'GMT')   AS END_TIME,
          TO_NUMBER(EXTRACTVALUE(VALUE(SMO), '//@MeasuredQuantity'))      AS MEASURED_QUANTITY,
          TO_NUMBER(EXTRACTVALUE(VALUE(SMO), '//@QueryFlag'))             AS QUERY_FLAG,
          TO_NUMBER(EXTRACTVALUE(VALUE(SMO), '//@ReadingDataStatus'))     AS READING_DATA_STATUS,
          TO_NUMBER(EXTRACTVALUE(VALUE(SMO), '//@ReadingNumber'))         AS READING_NUMBER,
		  TO_NUMBER(EXTRACTVALUE(VALUE(SMO), '//@NIEP'))				  AS NIEP
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, '//ieXMLDocument/MIM596_SupplierCopySMO/AggregatedQuantity'))) SMO;

BEGIN
   -- Assuming if the market timestamp attribute of the message header record
   -- is NULL then the entire record is NULL.
   ASSERT(p_MESSAGE_HEADER.MARKET_TIMESTAMP IS NOT NULL, 'The message header must not be null.', MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

   v_XML_MESSAGE := PARSE_UTIL.CREATE_XML_SAFE(p_IMPORT_FILE);

   -----------------------------------------------------------------------------
   -- Populate the TDIE_MESSAGE table record. This will be used to check for
   -- existing data and to insert the parent record for new data.
   SELECT TDIE_ID.NEXTVAL                                                          AS TDIE_ID,
          p_MESSAGE_HEADER.MESSAGE_TYPE_CODE                                       AS MESSAGE_TYPE_CODE,
          EXTRACTVALUE(VALUE(T), '//@SupplierUnitID')                              AS UNIT_ID,
          EXTRACTVALUE(VALUE(T), '//@SettlementRunIndicator')                      AS SETTLEMENT_RUN_INDICATOR,
          DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(T), '//@StartPeriodTime'), 'GMT') AS SETTLEMENT_DATE,
          DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(T), '//@EndPeriodTime'), 'GMT')   AS END_PERIOD_TIME,
          p_MESSAGE_HEADER.MARKET_TIMESTAMP                                        AS MARKET_TIMESTAMP,
          p_MESSAGE_HEADER.RECIPIENT_ID                                            AS RECIPIENT_ID,
          p_MESSAGE_HEADER.SENDER_ID                                               AS SENDER_ID,
          p_MESSAGE_HEADER.TX_REF_NUMBER                                           AS TX_REF_NUMBER,
          p_MESSAGE_HEADER.VERSION_NUMBER                                          AS VERSION_NUMBER,
          NULL                                                                     AS SSAC,
          NULL                                                                     AS PERCENT_CONS_ACT,
          NULL                                                                     AS PERCENT_MPRN_EST,
          NULL                                                                     AS SUPPLIER_MPID,
          LOGS.CURRENT_PROCESS_ID                                                  AS PROCESS_ID
     INTO v_TDIE_MESSAGE_REC.TDIE_ID,
          v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE,
          v_TDIE_MESSAGE_REC.LOCATION_ID,
          v_TDIE_MESSAGE_REC.SETTLEMENT_RUN_INDICATOR,
          v_TDIE_MESSAGE_REC.MESSAGE_DATE,
          v_TDIE_MESSAGE_REC.END_PERIOD_TIME,
          v_TDIE_MESSAGE_REC.MARKET_TIMESTAMP,
          v_TDIE_MESSAGE_REC.RECIPIENT_ID,
          v_TDIE_MESSAGE_REC.SENDER_ID,
          v_TDIE_MESSAGE_REC.TX_REF_NUMBER,
          v_TDIE_MESSAGE_REC.VERSION_NUMBER,
          v_TDIE_MESSAGE_REC.SSAC,
          v_TDIE_MESSAGE_REC.PERCENT_CONS_ACT,
          v_TDIE_MESSAGE_REC.PERCENT_MPRN_EST,
          v_TDIE_MESSAGE_REC.SUPPLIER_MPID,
          v_TDIE_MESSAGE_REC.PROCESS_ID
     FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_MESSAGE, '//ieXMLDocument/MIM596_SupplierCopySMO'))) T;

   IF DEL_TDIE_MESSAGE(v_TDIE_MESSAGE_REC) = g_SUCCESS THEN
      INS_TDIE_MESSAGE(v_TDIE_MESSAGE_REC);
   ELSE
      -- If the delete was not sucessful then skip the import of message.
      GOTO IMPORT_XML_596_END;
   END IF;

   -----------------------------------------------------------------------------
   -- Assign values to TDIE_SMO_CONSUMPTION record type.
   -- Insert the all the records into the table.
   FOR SC IN c_SMO_CONSUMPTION (v_XML_MESSAGE) LOOP

      v_TDIE_SMO_CONSUMPTION_REC.TDIE_ID             := v_TDIE_MESSAGE_REC.TDIE_ID;
      v_TDIE_SMO_CONSUMPTION_REC.START_TIME          := SC.START_TIME;
      v_TDIE_SMO_CONSUMPTION_REC.END_TIME            := SC.END_TIME;
      v_TDIE_SMO_CONSUMPTION_REC.MEASURED_QUANTITY   := SC.MEASURED_QUANTITY;
      v_TDIE_SMO_CONSUMPTION_REC.QUERY_FLAG          := SC.QUERY_FLAG;
      v_TDIE_SMO_CONSUMPTION_REC.READING_DATA_STATUS := SC.READING_DATA_STATUS;
      v_TDIE_SMO_CONSUMPTION_REC.READING_NUMBER      := SC.READING_NUMBER;
	  v_TDIE_SMO_CONSUMPTION_REC.NIEP				 := SC.NIEP;

      INS_TDIE_SMO_CONSUMPTION(v_TDIE_SMO_CONSUMPTION_REC);

   END LOOP;--FOR SC IN c_SMO_CONSUMPTION

   <<IMPORT_XML_596_END>>
   IF p_PROCESS_IMPORT = 1 THEN
      PROCESS_596(v_TDIE_MESSAGE_REC.TDIE_ID);
   END IF;

END IMPORT_XML_596;

--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the 598 XML messages.
PROCEDURE IMPORT_XML_598
   (
   p_MESSAGE_HEADER  IN t_MESSAGE_HEADER,
   p_IMPORT_FILE     IN CLOB,
   p_PROCESS_IMPORT IN NUMBER
   ) IS

   v_XML_MESSAGE               XMLTYPE;
   v_TDIE_MESSAGE_REC          TDIE_MESSAGE%ROWTYPE;
   v_TDIE_AGG_GENERATION_REC   TDIE_AGG_GENERATION%ROWTYPE;
   v_INTERVAL_OFFSET           NUMBER;

   -----------------------------------------------------------------------------
   -- This cursor is used to process the SMO Consumption Messages.
   CURSOR c_AGG_GENERATION(
      p_XML_MESSAGE IN XMLTYPE
      ) IS
   SELECT (DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(AG), '//@IntervalPeriodTimestamp'), 'GMT') + v_INTERVAL_OFFSET/1440) AS INTERVAL_PERIOD_TIMESTAMP,
          TO_NUMBER(EXTRACTVALUE(VALUE(AG), '//@GenerationUnitMeteredGeneration'))              AS METERED_GENERATION,
          TO_NUMBER(EXTRACTVALUE(VALUE(AG), '//@LossAdjustedGenerationUnitMeteredGeneration'))  AS LA_METERED_GENERATION
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, '//ieXMLDocument/MIM598_NonPatGUAggregation/MeteredGenerationInfo'))) AG;

BEGIN
   -- Assuming if the market timestamp attribute of the message header record
   -- is NULL then the entire record is NULL.
   ASSERT(p_MESSAGE_HEADER.MARKET_TIMESTAMP IS NOT NULL, 'The message header must not be null.', MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

   v_XML_MESSAGE := PARSE_UTIL.CREATE_XML_SAFE(p_IMPORT_FILE);

   GET_INTERVAL_OFFSET(v_XML_MESSAGE, '//ieXMLDocument/MIM598_NonPatGUAggregation/MeteredGenerationInfo', v_INTERVAL_OFFSET);

   -----------------------------------------------------------------------------
   -- Populate the TDIE_MESSAGE table record. This will be used to check for
   -- existing data and to insert the parent record for new data.
   SELECT TDIE_ID.NEXTVAL                                                          AS TDIE_ID,
          p_MESSAGE_HEADER.MESSAGE_TYPE_CODE                                       AS MESSAGE_TYPE_CODE,
          EXTRACTVALUE(VALUE(T), '//@GenerationUnitID')                            AS UNIT_ID,
          EXTRACTVALUE(VALUE(T), '//@SettlementRunIndicator')                      AS SETTLEMENT_RUN_INDICATOR,
          TO_DATE(EXTRACTVALUE(VALUE(T), '//@SettlementDate'), g_XML_DATE_FORMAT)  AS SETTLEMENT_DATE,
          NULL                                                                     AS END_PERIOD_TIME,
          p_MESSAGE_HEADER.MARKET_TIMESTAMP                                        AS MARKET_TIMESTAMP,
          p_MESSAGE_HEADER.RECIPIENT_ID                                            AS RECIPIENT_ID,
          p_MESSAGE_HEADER.SENDER_ID                                               AS SENDER_ID,
          p_MESSAGE_HEADER.TX_REF_NUMBER                                           AS TX_REF_NUMBER,
          p_MESSAGE_HEADER.VERSION_NUMBER                                          AS VERSION_NUMBER,
          NULL                                                                     AS SSAC,
          NULL                                                                     AS PERCENT_CONS_ACT,
          NULL                                                                     AS PERCENT_MPRN_EST,
          NULL                                                                     AS SUPPLIER_MPID,
          LOGS.CURRENT_PROCESS_ID                                                  AS PROCESS_ID
     INTO v_TDIE_MESSAGE_REC.TDIE_ID,
          v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE,
          v_TDIE_MESSAGE_REC.LOCATION_ID,
          v_TDIE_MESSAGE_REC.SETTLEMENT_RUN_INDICATOR,
          v_TDIE_MESSAGE_REC.MESSAGE_DATE,
          v_TDIE_MESSAGE_REC.END_PERIOD_TIME,
          v_TDIE_MESSAGE_REC.MARKET_TIMESTAMP,
          v_TDIE_MESSAGE_REC.RECIPIENT_ID,
          v_TDIE_MESSAGE_REC.SENDER_ID,
          v_TDIE_MESSAGE_REC.TX_REF_NUMBER,
          v_TDIE_MESSAGE_REC.VERSION_NUMBER,
          v_TDIE_MESSAGE_REC.SSAC,
          v_TDIE_MESSAGE_REC.PERCENT_CONS_ACT,
          v_TDIE_MESSAGE_REC.PERCENT_MPRN_EST,
          v_TDIE_MESSAGE_REC.SUPPLIER_MPID,
          v_TDIE_MESSAGE_REC.PROCESS_ID
     FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_MESSAGE, '//ieXMLDocument/MIM598_NonPatGUAggregation'))) T;

   IF DEL_TDIE_MESSAGE(v_TDIE_MESSAGE_REC) = g_SUCCESS THEN
      INS_TDIE_MESSAGE(v_TDIE_MESSAGE_REC);
   ELSE
      -- If the delete was not sucessful then skip the import of message.
      GOTO IMPORT_XML_598_END;
   END IF;

   -----------------------------------------------------------------------------
   -- Assign values to TDIE_SMO_CONSUMPTION record type.
   -- Insert the all the records into the table.
   FOR AG IN c_AGG_GENERATION (v_XML_MESSAGE) LOOP

      v_TDIE_AGG_GENERATION_REC.TDIE_ID                   := v_TDIE_MESSAGE_REC.TDIE_ID;
      v_TDIE_AGG_GENERATION_REC.INTERVAL_PERIOD_TIMESTAMP := AG.INTERVAL_PERIOD_TIMESTAMP;
      v_TDIE_AGG_GENERATION_REC.METERED_GENERATION        := AG.METERED_GENERATION;
      v_TDIE_AGG_GENERATION_REC.LA_METERED_GENERATION     := AG.LA_METERED_GENERATION;

      INS_TDIE_AGG_GENERATION(v_TDIE_AGG_GENERATION_REC);

   END LOOP;--FOR SC IN c_SMO_CONSUMPTION

   <<IMPORT_XML_598_END>>
   IF p_PROCESS_IMPORT = 1 THEN
      PROCESS_598(v_TDIE_MESSAGE_REC.TDIE_ID);
   END IF;

END IMPORT_XML_598;

--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the NIE Participant Aggregation
-- Report CSV file. This procedure will use the PARSE_UTIL library to handle the
-- CSV parsing.
PROCEDURE IMPORT_CSV_NIE59X
   (
   p_MESSAGE_HEADER  IN t_NIE_HEADER,
   p_IMPORT_FILE     IN CLOB,
   p_PROCESS_IMPORT  IN NUMBER,
   p_FROM_SEM      	IN NUMBER DEFAULT 0
   ) IS

   c_SKIP_RECORD    CONSTANT VARCHAR2(4) := 'SKIP';
   c_UMS_RECORD		CONSTANT VARCHAR2(3) := 'UMS'; -- BZ 27277 - Indicator for UMS record
   i                         BINARY_INTEGER := 1; -- used as an index for TDIE_NIETD loop.
   j                         BINARY_INTEGER := 0; -- used as an index for TDIE_NIETD_DETAIL loop.
   k						        BINARY_INTEGER;
   v_INTERVAL                NUMBER := 0; -- used to calculate the data offset for TDIE_NIETD_DETAIL loop.
   v_NIE_HEADER              t_NIE_HEADER := p_MESSAGE_HEADER;
   v_NIE_DETAIL_HEADER       t_NIE_DETAIL_HEADER;
   v_TDIE_MESSAGE_REC        TDIE_MESSAGE%ROWTYPE;
   v_TDIE_NIETD_REC          TDIE_NIETD%ROWTYPE;
   V_TDIE_NIETD_DETAIL_REC   TDIE_NIETD_DETAIL%ROWTYPE;
   v_LINES                   PARSE_UTIL.BIG_STRING_TABLE_MP;
   v_LINE_ELEMENTS           PARSE_UTIL.STRING_TABLE;
   v_TDIE_IDs				     NUMBER_COLLECTION := NUMBER_COLLECTION();
   v_FROM_SEM                NUMBER := NVL(p_FROM_SEM, 0);

BEGIN
   -- Assuming if the market timestamp attribute of the message header record
   -- is NULL then the entire record is NULL.
   ASSERT(p_MESSAGE_HEADER.TITLE IS NOT NULL, 'The message header must not be null.', MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_IMPORT_FILE, v_LINES);

   i := v_LINES.FIRST + 1; -- skip over line one since it is header data that is used above
   WHILE i < v_LINES.LAST LOOP
      --------------------------------------------------------------------------
      -- TDIE_MESSAGE   Processing
      --------------------------------------------------------------------------

      -- This is the NIE DETAIL HEADER Record (i)
      PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(i), ',', v_LINE_ELEMENTS);

      -- Get the header information from the CSV file.
      v_NIE_DETAIL_HEADER.UNIT_ID                  := v_LINE_ELEMENTS(1);
      v_NIE_DETAIL_HEADER.LOAD_PROFILE             := v_LINE_ELEMENTS(2);
      v_NIE_DETAIL_HEADER.LINE_LOSS_FACTOR_ID      := v_LINE_ELEMENTS(3);
      v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR      := v_LINE_ELEMENTS(4);
      v_NIE_DETAIL_HEADER.IMP_EXP_INDICATOR        := v_LINE_ELEMENTS(5);
      v_NIE_DETAIL_HEADER.METER_VALUE_INDICATOR    := v_LINE_ELEMENTS(6);
      v_NIE_DETAIL_HEADER.UOS_TARIFF               := v_LINE_ELEMENTS(7);
      v_NIE_DETAIL_HEADER.AGG_CODE                 := v_LINE_ELEMENTS(8);
      v_NIE_DETAIL_HEADER.METER_CONFIGURATION_CODE := v_LINE_ELEMENTS(9);
      v_NIE_DETAIL_HEADER.TIME_SLOT                := v_LINE_ELEMENTS(10);

      -----------------------------------------------------------------------------
      -- Populate the TDIE_MESSAGE table record. This will be used to check for
      -- existing data and to insert the parent record for new data.
	  v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE :=
					CASE
						WHEN v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR   = 'Y'      AND
							 v_NIE_DETAIL_HEADER.IMP_EXP_INDICATOR     = 'IMPORT' AND
							 v_NIE_DETAIL_HEADER.METER_VALUE_INDICATOR = 'NHH'   THEN
							 'N591'
						WHEN v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR   = 'Y'      AND
							 v_NIE_DETAIL_HEADER.IMP_EXP_INDICATOR     = 'IMPORT' AND
							 v_NIE_DETAIL_HEADER.METER_VALUE_INDICATOR = 'HH'   THEN
							 'N595'
						WHEN v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR   = 'Y'       AND
							 v_NIE_DETAIL_HEADER.IMP_EXP_INDICATOR     = 'EXPORT' THEN
							 'N598'
						-- BZ 27277 -- Tolerate presence of UMS for Y and IMPORT
						WHEN v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR   = 'Y'      AND
						     v_NIE_DETAIL_HEADER.IMP_EXP_INDICATOR     = 'IMPORT' AND
							 v_NIE_DETAIL_HEADER.METER_VALUE_INDICATOR NOT IN ('HH', 'NHH') THEN
							c_UMS_RECORD
						WHEN v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR   = 'N' THEN
							c_SKIP_RECORD
						ELSE
							-- Will Throw an Error
							NULL
					 END;

      -- Log and error if the MESSAGE_TYPE_CODE could not be determined.
      IF v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE IS NULL THEN
            ERRS.RAISE(MSGCODES.c_ERR_DATA_IMPORT,
                       'Invalid MESSAGE_TYPE_CODE.'||g_CRLF
                     ||'LINE_LOSS_INDICATOR   = '||v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR||', '||g_CRLF
                     ||'IMP_EXP_INDICATOR     = '||v_NIE_DETAIL_HEADER.IMP_EXP_INDICATOR||', '||g_CRLF
                     ||'METER_VALUE_INDICATOR = '||v_NIE_DETAIL_HEADER.METER_VALUE_INDICATOR||g_CRLF);
      -- BZ 27277 -- Tolerate presence of UMS for Y and IMPORT
	  ELSIF v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE = c_UMS_RECORD THEN
	        LOGS.LOG_WARN(p_EVENT_TEXT => 'Line ' || i || ': unrecognized meter value indicator '||
			                              v_NIE_DETAIL_HEADER.METER_VALUE_INDICATOR ||
										  ' (expected HH/NHH). Record skipped.');
		    GOTO END_TDIE_MESSAGE;
      ELSIF v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE = c_SKIP_RECORD THEN
            GOTO END_TDIE_MESSAGE;
      END IF;

	  v_TDIE_MESSAGE_REC.LOCATION_ID := v_NIE_DETAIL_HEADER.UNIT_ID;
	  v_TDIE_MESSAGE_REC.SETTLEMENT_RUN_INDICATOR := v_NIE_HEADER.SETTLEMENT_TYPE;
	  v_TDIE_MESSAGE_REC.MESSAGE_DATE := v_NIE_HEADER.SETTLEMENT_DATE;
	  v_TDIE_MESSAGE_REC.MARKET_TIMESTAMP := v_NIE_HEADER.REPORT_DATE;
      v_TDIE_MESSAGE_REC.RECIPIENT_ID := v_NIE_HEADER.SUPPLIER_ID;

	  -- Re-use TDIE ID if we've already created an entry
	  SELECT MAX(TDIE_ID)
	  INTO v_TDIE_MESSAGE_REC.TDIE_ID
	  FROM TDIE_MESSAGE TM,
	  		-- set of IDs we've already created
	  		TABLE(CAST(v_TDIE_IDs as NUMBER_COLLECTION)) IDs
	  WHERE TM.TDIE_ID = IDs.COLUMN_VALUE
	  	AND TM.MESSAGE_TYPE_CODE = v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE
		AND TM.LOCATION_ID = v_TDIE_MESSAGE_REC.LOCATION_ID
		AND TM.SETTLEMENT_RUN_INDICATOR = v_TDIE_MESSAGE_REC.SETTLEMENT_RUN_INDICATOR
	  	AND TM.MESSAGE_DATE = v_TDIE_MESSAGE_REC.MESSAGE_DATE;

	  -- If we don't have a record, then generate a new one
	  IF v_TDIE_MESSAGE_REC.TDIE_ID IS NULL THEN

		  -- Delete existing data first - unless it is newer
		  IF DEL_TDIE_MESSAGE(v_TDIE_MESSAGE_REC) = g_SUCCESS THEN
			 -- Get new ID
		     SELECT TDIE_ID.NEXTVAL INTO v_TDIE_MESSAGE_REC.TDIE_ID FROM DUAL;
			 -- Insert row
			 INS_TDIE_MESSAGE(v_TDIE_MESSAGE_REC);
			 -- And add to list of created record IDs
			 v_TDIE_IDs.EXTEND;
			 v_TDIE_IDs(v_TDIE_IDs.LAST) := v_TDIE_MESSAGE_REC.TDIE_ID;
		  ELSE
			 -- If the delete was not sucessful then skip the import of this set of rows
			 GOTO IMPORT_CSV_NIE59X_END;
		  END IF;

	  END IF;

      --------------------------------------------------------------------------
      -- TDIE_NIETD   Processing
      --------------------------------------------------------------------------
      SELECT TDIE_DETAIL_ID.NEXTVAL                       AS TDIE_DETAIL_ID,
             v_TDIE_MESSAGE_REC.TDIE_ID                   AS TDIE_ID,
             v_NIE_DETAIL_HEADER.LOAD_PROFILE             AS LOAD_PROFILE,
             v_NIE_DETAIL_HEADER.LINE_LOSS_FACTOR_ID      AS LINE_LOSS_FACTOR_ID,
             v_NIE_DETAIL_HEADER.LINE_LOSS_INDICATOR      AS LINE_LOSS_INDICATOR,
             v_NIE_DETAIL_HEADER.IMP_EXP_INDICATOR        AS IMP_EXP_INDICATOR,
             v_NIE_DETAIL_HEADER.METER_VALUE_INDICATOR    AS METER_VALUE_INDICATOR,
             v_NIE_DETAIL_HEADER.UOS_TARIFF               AS UOS_TARIFF,
             v_NIE_DETAIL_HEADER.AGG_CODE                 AS AGG_CODE,
             v_NIE_DETAIL_HEADER.METER_CONFIGURATION_CODE AS METER_CONFIGURATION_CODE,
             v_NIE_DETAIL_HEADER.TIME_SLOT                AS TIME_SLOT
        INTO
            v_TDIE_NIETD_REC.TDIE_DETAIL_ID,
            v_TDIE_NIETD_REC.TDIE_ID,
            v_TDIE_NIETD_REC.LOAD_PROFILE,
            v_TDIE_NIETD_REC.LINE_LOSS_FACTOR_ID,
            v_TDIE_NIETD_REC.LINE_LOSS_INDICATOR,
            v_TDIE_NIETD_REC.IMP_EXP_INDICATOR,
            v_TDIE_NIETD_REC.METER_VALUE_INDICATOR,
            v_TDIE_NIETD_REC.UOS_TARIFF,
            v_TDIE_NIETD_REC.AGG_CODE,
            v_TDIE_NIETD_REC.METER_CONFIGURATION_CODE,
            v_TDIE_NIETD_REC.TIME_SLOT
        FROM DUAL;

	  -- Check if LOAD_PROFILE, LOSS Factor or UOS Tariff Code exists in system label, if not create a new one
	  SP.ENSURE_SYSTEM_LABELS(0, 'Scheduling', 'TDIE','Load Profile Codes','NI-'
	  		|| CASE v_TDIE_MESSAGE_REC.MESSAGE_TYPE_CODE WHEN 'N591' THEN 'NHH' WHEN 'N595' THEN 'HH' WHEN 'N598' THEN 'Gen' END,
	  		v_TDIE_NIETD_REC.LOAD_PROFILE, NULL, 0, 0);
	  SP.ENSURE_SYSTEM_LABELS(0, 'Scheduling', 'TDIE', 'Loss Factor Codes', 'NI',
			v_TDIE_NIETD_REC.LINE_LOSS_FACTOR_ID, NULL, 0, 0);
	  SP.ENSURE_SYSTEM_LABELS(0, 'Scheduling', 'TDIE', 'UOS Tariff Codes', 'NI',
	  		v_TDIE_NIETD_REC.UOS_TARIFF, NULL, 0, 0);

      INS_TDIE_NIETD(v_TDIE_NIETD_REC);

      ------------------------------------------------------------------------------
      -- TDIE_NIETD_DETAIL   Processing (i+1 = Period Energy and i+2 = Spill Energy)
      ------------------------------------------------------------------------------
	  k := 1;
	  WHILE k <= 2 LOOP

		  PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(i+k), ',', v_LINE_ELEMENTS);

      j := v_LINE_ELEMENTS.FIRST;
      v_INTERVAL := 0;
      WHILE j <= v_LINE_ELEMENTS.LAST LOOP
         -- Calculate the date based on the interval offset.
         -- Assuming 30min Intervals for the data.
         SELECT v_TDIE_NIETD_REC.TDIE_DETAIL_ID                    AS TDIE_DETAIL_ID,
                GET_CSV_FILE_SCHEDULE_DATE(v_TDIE_MESSAGE_REC.MESSAGE_DATE, v_INTERVAL) AS SCHEDULE_DATE,
					CASE WHEN (k = 2) THEN 'S' ELSE 'P' END     AS ENERGY_TYPE, -- BZ 27981 -- MOD(i+k,2)=0 is the bug. Replaced to k=2
                TO_NUMBER(v_LINE_ELEMENTS(j))                      AS ENERGY,
                v_LINE_ELEMENTS(j+1)                               AS ACT_EST_INDICATOR
           INTO v_TDIE_NIETD_DETAIL_REC.TDIE_DETAIL_ID,
                V_TDIE_NIETD_DETAIL_REC.SCHEDULE_DATE,
                V_TDIE_NIETD_DETAIL_REC.ENERGY_TYPE,
                V_TDIE_NIETD_DETAIL_REC.ENERGY,
                V_TDIE_NIETD_DETAIL_REC.ACT_EST_INDICATOR
           FROM DUAL;

         INS_TDIE_NIETD_DETAIL(v_TDIE_NIETD_DETAIL_REC);

         j:=j+2;-- processing in pairs.
         v_INTERVAL := v_INTERVAL + 1;
      END LOOP;--WHILE j <= v_LINE_ELEMENTS.LAST LOOP

	  k := k+1;
	  END LOOP;

      <<END_TDIE_MESSAGE>>
      i:=i+3; -- moves the index by 3 rows.

   END LOOP;--WHILE i <= v_LINES.LAST LOOP

   <<IMPORT_CSV_NIE59X_END>>

   IF p_PROCESS_IMPORT = 1 THEN

      PROCESS_NIE_NET_DEMAND(p_RECIPIENT_ID => v_TDIE_MESSAGE_REC.RECIPIENT_ID,
                             p_BEGIN_DATE   => v_TDIE_MESSAGE_REC.MESSAGE_DATE,
                             p_END_DATE     => v_TDIE_MESSAGE_REC.END_PERIOD_TIME,
                             p_SETTLEMENT_RUN_INDICATOR => v_TDIE_MESSAGE_REC.SETTLEMENT_RUN_INDICATOR,
                             p_FROM_SEM     => v_FROM_SEM);

      IF v_FROM_SEM = 0 THEN

        PROCESS_NIE_GENERATION(p_RECIPIENT_ID => v_TDIE_MESSAGE_REC.RECIPIENT_ID,
                               p_BEGIN_DATE => v_TDIE_MESSAGE_REC.MESSAGE_DATE,
                               p_END_DATE => v_TDIE_MESSAGE_REC.END_PERIOD_TIME,
                               p_SETTLEMENT_RUN_INDICATOR => v_TDIE_MESSAGE_REC.SETTLEMENT_RUN_INDICATOR);

      END IF;

   END IF;

END IMPORT_CSV_NIE59X;
--------------------------------------------------------------------------------
FUNCTION GET_300_XML_MPRN_NODE_NAME
	(
    p_MESSAGE_CODE_TYPE IN VARCHAR2,
    p_VERSION_UPDATED 	IN NUMBER
	) RETURN VARCHAR2 AS
v_XML_NODE_NAME VARCHAR2(512);
BEGIN
	CASE p_MESSAGE_CODE_TYPE
		WHEN '300' THEN
			CASE p_VERSION_UPDATED
				WHEN 0 THEN
					v_XML_NODE_NAME := '/MIM300_ValidatedNQHReadingsScheduled';
				WHEN 1 THEN
					v_XML_NODE_NAME := '/MIM300_ValidatedNonIntervalReadingsScheduled';
			END CASE;
		WHEN '300S' THEN
			CASE p_VERSION_UPDATED
				WHEN 0 THEN
					v_XML_NODE_NAME := '/MIM300S_ValidatedNQHReadingsSpecial';
				WHEN 1 THEN
					v_XML_NODE_NAME := '/MIM300S_ValidatedNonIntervalReadingsSpecial';
			END CASE;
		WHEN '300W' THEN
			CASE p_VERSION_UPDATED
				WHEN 0 THEN
					v_XML_NODE_NAME := '/MIM300W_WithdrawnNQHReadings';
				WHEN 1 THEN
					v_XML_NODE_NAME := '/MIM300W_WithdrawnNonIntervalReadings';
			END CASE;
		WHEN '305' THEN
			v_XML_NODE_NAME := '/MIM305_NonSettlementEstimates';
		WHEN '306' THEN
			v_XML_NODE_NAME := '/MIM306_MeterPointStatusChangeConfirmationDeEnergisation';
		WHEN '306W' THEN
			v_XML_NODE_NAME := '/MIM306W_MeterPointstatusChangeDeenergisationWithdrawnRead';
		WHEN '307' THEN
			v_XML_NODE_NAME := '/MIM307_MeterPointStatusChangeConfirmationEnergisation';
		WHEN '307W' THEN
			v_XML_NODE_NAME := '/MIM307W_MeterPointStatusChangeEnergisationWithdrawnRead';
		WHEN '310' THEN
			v_XML_NODE_NAME := '/MIM310_ValidatedCoSReading';
		WHEN '310W' THEN
			v_XML_NODE_NAME := '/MIM310W_WithdrawnCoSReading';
		WHEN '320' THEN
			v_XML_NODE_NAME := '/MIM320_ValidatedCoSReading';
		WHEN '320W' THEN
			v_XML_NODE_NAME := '/MIM320W_WithdrawnCoSReading';
		WHEN '332' THEN
			CASE p_VERSION_UPDATED
				WHEN 0 THEN
			v_XML_NODE_NAME := '/MIM332_NQHTechnicalMeterDetails';
				WHEN 1 THEN
					v_XML_NODE_NAME := '/MIM332_NonIntervalTechnicalMeterDetails';
			END CASE;
		WHEN '332W' THEN
			CASE p_VERSION_UPDATED
				WHEN 0 THEN
			v_XML_NODE_NAME := '/MIM332W_WithdrawnReadNQHMeterTechnicalDetails';
				WHEN 1 THEN
					v_XML_NODE_NAME := '/MIM332W_WithdrawnReadNonIntervalMeterTechnicalDetails';
			END CASE;
		WHEN 'N300' THEN
			v_XML_NODE_NAME := '/NIE300_ValidatedNHHReadingsScheduled';
		WHEN 'N300S' THEN
			v_XML_NODE_NAME := '/NIE300S_ValidatedNHHReadingsSpecial';
		WHEN 'N300W' THEN
			v_XML_NODE_NAME := '/NIE300W_WithdrawnNHHReadings';
		WHEN 'N306' THEN
			v_XML_NODE_NAME := '/NIE306_MeterPointStatusChangeConfirmationDeEnergisation';
		WHEN 'N307' THEN
			v_XML_NODE_NAME := '/NIE307_MeterPointStatusChangeConfirmationEnergisation';
		WHEN 'N310' THEN
			v_XML_NODE_NAME := '/NIE310_ValidatedCoSReading';
		WHEN 'N320' THEN
			v_XML_NODE_NAME := '/NIE320_ValidatedCoSReading';
		WHEN 'N332' THEN
			v_XML_NODE_NAME := '/NIE332_NHHTechnicalMeterDetails';
		ELSE
			ERRS.RAISE_BAD_ARGUMENT('MESSAGE_TYPE_CODE', p_MESSAGE_CODE_TYPE);
	END CASE;
	RETURN v_XML_NODE_NAME;
END GET_300_XML_MPRN_NODE_NAME;
--------------------------------------------------------------------------------
-- This function returns the XPATH string used to locate the MPRN node in a 300 series message.
FUNCTION GET_300_XML_MPRN_PATH(p_MESSAGE_CODE_TYPE IN VARCHAR2
							  ,p_VERSION_UPDATED IN NUMBER
							  )
RETURN VARCHAR2 AS
	v_XML_PATH VARCHAR2(512);
BEGIN
	IF SUBSTR(p_MESSAGE_CODE_TYPE,1,1) = 'N' THEN
		v_XML_PATH := '/niXMLDocument';
	ELSE
		v_XML_PATH := '/ieXMLDocument';
	END IF;
	RETURN v_XML_PATH || GET_300_XML_MPRN_NODE_NAME(p_MESSAGE_CODE_TYPE, p_VERSION_UPDATED);
END GET_300_XML_MPRN_PATH;
--------------------------------------------------------------------------------
-- This procedure will be responsible for processing the following XML messages:
-- 300, 300S, 305, 306, 307, 310, 300W, 306W, 307W, 310W, 320W, 332W, 320, 332, N300, N306, N307, N310, N300S, N300W, N320, N332
PROCEDURE IMPORT_XML_300
   (
   p_MESSAGE_HEADER  IN t_MESSAGE_HEADER,
   p_IMPORT_FILE     IN CLOB,
   p_TDIE_ID	     OUT NUMBER
   ) IS

	v_TDIE_MESSAGE TDIE_MESSAGE%ROWTYPE;
	v_CURRENT_MARKET_TIMESTAMP 	TDIE_MESSAGE.MARKET_TIMESTAMP%TYPE;
	v_XML_MESSAGE 				XMLTYPE;
	v_XML_MPRN_PATH 			VARCHAR2(512);
	v_XML_REG_PATH				VARCHAR2(512);
    v_JURISDICTION              VARCHAR2(4);
	v_VERSION_UPDATED			NUMBER(1);

	v_TDIE_300_MPRN_REC        TDIE_300_MPRN%ROWTYPE;

	TYPE t_METER_TYPE IS RECORD (
		XML_PATH			VARCHAR2(512),
		REGISTER_NODE_TYPE	VARCHAR2(16)
	);
	TYPE t_METER_TYPE_TBL IS TABLE of t_METER_TYPE;
	v_METER_TYPES			t_METER_TYPE_TBL := t_METER_TYPE_TBL();

	CURSOR c_METERS
		(
		p_XML_MESSAGE IN XMLTYPE,
		p_XML_ELEMENT_NAME IN VARCHAR2
		) IS
		SELECT EXTRACTVALUE(VALUE(T), '//@SerialNumber') AS SERIAL_NUMBER,
			EXTRACTVALUE(VALUE(T), '//@MeterCategoryCode') AS METER_CATEGORY_CODE,
			EXTRACTVALUE(VALUE(T), '//@MeterLocationCode') AS METER_LOCATION_CODE,
			EXTRACTVALUE(VALUE(T), '//@ExchangedMeterReference') AS EXCHANGED_METER_REFERENCE,
			VALUE(T) AS XML_OBJECT
		FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, p_XML_ELEMENT_NAME))) T;

	CURSOR c_REGISTERS
		(
		p_XML_MESSAGE IN XMLTYPE,
		p_XML_ELEMENT_NAME IN VARCHAR2
		) IS
		SELECT EXTRACTVALUE(VALUE(T), '//@TimeslotCode') 				AS TIMESLOT_CODE,
			   EXTRACTVALUE(VALUE(T), '//@UOM_Code') 					AS UOM_CODE,
			   TO_DATE(EXTRACTVALUE(VALUE(T), '//@PreviousReadDate'),
			   		MM_TDIE_UTIL.g_XML_DATE_FORMAT) 					AS PREVIOUS_READ_DATE,
			   EXTRACTVALUE(VALUE(T), '//@MeterRegisterSequence') 		AS METER_REGISTER_SEQUENCE,
			   EXTRACTVALUE(VALUE(T),
				   CASE
				   		WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N310' THEN
							'//@ReadReasonCodeGrpB'
				   		WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N300' THEN
							'//@ReadReasonCodeGrpD'
						WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N300S' THEN
							'//@ReadReasonCodeGrpE'
						WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N306' THEN
							'//@ReadReasonCodeGrpF'
						WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N307' THEN
							'//@ReadReasonCodeGrpG'
						WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N320' THEN
							'//@ReadReasonCodeGrpB'
						WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N332' THEN
							'//@ReadReasonCodeGrpI'
						ELSE
							'//@ReadReasonCode'
				   END) AS READ_REASON_CODE,
			   EXTRACTVALUE(VALUE(T),
			      CASE
				  		WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N310' THEN
							'//@ReadStatusCodeGrpA'
				  		WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N307' THEN
							'//@ReadStatusCodeGrpB'
						ELSE
							'//@ReadStatusCode'
				  END) AS READ_STATUS_CODE,
			   EXTRACTVALUE(VALUE(T),
				   CASE
				   		WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('N300S','N306','N332') THEN
							'//@ReadTypeCodeGrpB'
						WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N307' THEN
							'//@ReadTypeCodeGrpC'
						ELSE
							'//@ReadTypeCode'
				   END) AS READ_TYPE_CODE,
			   EXTRACTVALUE(VALUE(T), '//@RegisterTypeCode') 			AS REGISTER_TYPE_CODE,
			   EXTRACTVALUE(VALUE(T), '//@MeterMultiplier') 			AS METER_MULTIPLIER,
			   EXTRACTVALUE(VALUE(T), '//@PreDecimalDetails')			AS PRE_DECIMAL_DETAILS,
			   EXTRACTVALUE(VALUE(T), '//@PostDecimalDetails') 			AS POST_DECIMAL_DETAILS,
			   EXTRACTVALUE(VALUE(T), '//@Consumption') 				AS CONSUMPTION,
			   EXTRACTVALUE(VALUE(T), '//@ReadingValue') 				AS READING_VALUE,
			   EXTRACTVALUE(VALUE(T), '//@AnnualisedActualConsumption') AS ANNUALISED_ACTUAL_CONSUMPTION,
			   EXTRACTVALUE(VALUE(T), '//@EstimatedUsageFactor') 		AS ESTIMATED_USAGE_FACTOR
		FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, p_XML_ELEMENT_NAME))) T;



BEGIN

	v_VERSION_UPDATED := IS_NI_HARMONISATION_VERSION(p_MESSAGE_HEADER.VERSION_NUMBER, p_MESSAGE_HEADER.MESSAGE_TYPE_CODE);

	v_XML_MPRN_PATH := GET_300_XML_MPRN_PATH(p_MESSAGE_HEADER.MESSAGE_TYPE_CODE, v_VERSION_UPDATED);

   	v_XML_MESSAGE := PARSE_UTIL.CREATE_XML_SAFE(p_IMPORT_FILE);

	SELECT NULL AS TDIE_ID,
		   p_MESSAGE_HEADER.MESSAGE_TYPE_CODE AS MESSAGE_TYPE_CODE,
		   EXTRACTVALUE(VALUE(T), '//@MPRN') AS LOCATION_ID,
		   NULL AS SETTLEMENT_RUN_INDICATOR,
		   TO_DATE(EXTRACTVALUE(VALUE(T),
				CASE
					-- Full path required because 'EffectiveFromDate' exists on other child nodes.
					WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('306','306W','307','307W','N306','N307','332','332W','N332') THEN
						GET_300_XML_MPRN_NODE_NAME(p_MESSAGE_HEADER.MESSAGE_TYPE_CODE, v_VERSION_UPDATED) || '/@EffectiveFromDate'
					ELSE
						'//@ReadDate'
				END), MM_TDIE_UTIL.g_XML_DATE_FORMAT) AS MESSAGE_DATE,
		   NULL AS END_PERIOD_TIME,
		   p_MESSAGE_HEADER.MARKET_TIMESTAMP AS MARKET_TIMESTAMP,
		   p_MESSAGE_HEADER.RECIPIENT_ID AS RECIPIENT_ID,
		   p_MESSAGE_HEADER.SENDER_ID AS SENDER_ID,
		   p_MESSAGE_HEADER.TX_REF_NUMBER AS TX_REF_NUMBER,
		   p_MESSAGE_HEADER.VERSION_NUMBER AS VERSION_NUMBER,
		   NULL AS SSAC,
		   NULL AS PERCENT_CONS_ACT,
		   NULL AS PERCENT_MPRN_EST,
		   p_MESSAGE_HEADER.SUPPLIER_MPID AS SUPPLIER_MPID,
		   NULL AS PROCESS_ID
		INTO v_TDIE_MESSAGE
		FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_MESSAGE, v_XML_MPRN_PATH))) T;

	v_JURISDICTION := GET_JURISDICTION_FOR_IMPORTS(v_TDIE_MESSAGE.RECIPIENT_ID);

    -- Check to see if we have an existing record with a greater MARKET_TIMESTAMP
    SELECT MAX(T.MARKET_TIMESTAMP)
	INTO v_CURRENT_MARKET_TIMESTAMP
	FROM TDIE_MESSAGE T
	WHERE T.MESSAGE_TYPE_CODE = v_TDIE_MESSAGE.MESSAGE_TYPE_CODE
	AND T.LOCATION_ID = v_TDIE_MESSAGE.LOCATION_ID
	AND T.MESSAGE_DATE = v_TDIE_MESSAGE.MESSAGE_DATE
	AND T.RECIPIENT_ID = v_TDIE_MESSAGE.RECIPIENT_ID
	AND T.SENDER_ID = v_TDIE_MESSAGE.SENDER_ID;

	IF v_CURRENT_MARKET_TIMESTAMP IS NOT NULL AND v_CURRENT_MARKET_TIMESTAMP > v_TDIE_MESSAGE.MARKET_TIMESTAMP THEN
		-- Do not import any records.
		ERRS.RAISE(MSGCODES.c_ERR_DUP_ENTRY, 'A file import already exists with a MARKET_TIMESTAMP that is newer than the one in this file. The existing MARKET_TIMESTAMP = '
		 	|| TEXT_UTIL.TO_CHAR_DATE(v_CURRENT_MARKET_TIMESTAMP) || '. The files MARKET_TIMESTAMP = ' || v_TDIE_MESSAGE.MARKET_TIMESTAMP);
	END IF;

	-- Delete any existing records forcing a delete on all child tables.
	DELETE FROM TDIE_MESSAGE T
	WHERE T.MESSAGE_TYPE_CODE = v_TDIE_MESSAGE.MESSAGE_TYPE_CODE
	AND T.LOCATION_ID = v_TDIE_MESSAGE.LOCATION_ID
	AND T.MESSAGE_DATE = v_TDIE_MESSAGE.MESSAGE_DATE
	AND T.RECIPIENT_ID = v_TDIE_MESSAGE.RECIPIENT_ID
	AND T.SENDER_ID = v_TDIE_MESSAGE.SENDER_ID;

	SELECT TDIE_ID.NEXTVAL INTO p_TDIE_ID FROM DUAL;

-- Handle inserting a new record in TDIE_MESSAGE based on the MessageHeader and MPRN details
	INSERT INTO TDIE_MESSAGE
		(TDIE_ID,
		 MESSAGE_TYPE_CODE,
		 LOCATION_ID,
		 MESSAGE_DATE,
		 MARKET_TIMESTAMP,
		 RECIPIENT_ID,
		 SENDER_ID,
		 TX_REF_NUMBER,
		 VERSION_NUMBER,
		 SUPPLIER_MPID,
		 PROCESS_ID)
	VALUES
		(p_TDIE_ID,
		 v_TDIE_MESSAGE.MESSAGE_TYPE_CODE,
		 v_TDIE_MESSAGE.LOCATION_ID,
		 v_TDIE_MESSAGE.MESSAGE_DATE,
		 v_TDIE_MESSAGE.MARKET_TIMESTAMP,
		 v_TDIE_MESSAGE.RECIPIENT_ID,
		 v_TDIE_MESSAGE.SENDER_ID,
		 v_TDIE_MESSAGE.TX_REF_NUMBER,
		 v_TDIE_MESSAGE.VERSION_NUMBER,
		 v_TDIE_MESSAGE.SUPPLIER_MPID,
		 LOGS.CURRENT_PROCESS_ID
		);

-- Handle inserting a new record into TDIE_300_MPRN	based on the MPRN details in the message
   SELECT p_TDIE_ID,
		EXTRACTVALUE(VALUE(T), '//@DUOS_Group') AS DUOS_GROUP,
		EXTRACTVALUE(VALUE(T), '//@LoadProfileCode') AS LOAD_PROFILE_CODE,
		EXTRACTVALUE(VALUE(T),
			CASE
				WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N307' THEN
					'//@MeterPointStatusCodeGrpA'
				WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('N300','N300S','N300W','N310','N320') THEN
					'//@MeterPointStatusCodeGrpC'
				WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N306' THEN
					'//@MeterPointStatusCodeGrpE'
				WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N332' THEN
					'//@MeterPointStatusCodeGrpF'
				ELSE
					'//@MeterPointStatusCode'
			END) AS METER_POINT_STATUS_CODE,
		EXTRACTVALUE(VALUE(T), '//@MeterConfigurationCode') AS METER_CONFIGURATION_CODE,
		EXTRACTVALUE(VALUE(T), '//@MPBusinessReference') AS MP_BUSINESS_REFERENCE,
		EXTRACTVALUE(VALUE(T), '//@NetworksReferenceNumber') AS NETWORKS_REFERENCE_NUMBER,
		EXTRACTVALUE(VALUE(T), '//@WithdrawalReasonCode') AS WITHDRAWAL_REASON_CODE,
		EXTRACTVALUE(VALUE(T), '//@NoReadCode') AS NO_READ_CODE,
		EXTRACTVALUE(VALUE(T), '//@DebitReEst') AS DEBIT_REESTIMATION,
		EXTRACTVALUE(VALUE(T), '//@KeypadPremisesNumber') AS KEYPAD_PREMISES_NUMBER,
		EXTRACTVALUE(VALUE(T), '//@TariffConfigurationCode') AS TARIFF_CONFIGURATION_CODE
   INTO v_TDIE_300_MPRN_REC.TDIE_ID,
		v_TDIE_300_MPRN_REC.DUOS_GROUP,
		v_TDIE_300_MPRN_REC.LOAD_PROFILE_CODE,
		v_TDIE_300_MPRN_REC.METER_POINT_STATUS_CODE,
		v_TDIE_300_MPRN_REC.METER_CONFIGURATION_CODE,
		v_TDIE_300_MPRN_REC.MP_BUSINESS_REFERENCE,
		v_TDIE_300_MPRN_REC.NETWORKS_REFERENCE_NUMBER,
		v_TDIE_300_MPRN_REC.WITHDRAWAL_REASON_CODE,
		v_TDIE_300_MPRN_REC.NO_READ_CODE,
		v_TDIE_300_MPRN_REC.DEBIT_REESTIMATION,
		v_TDIE_300_MPRN_REC.KEYPAD_PREMISES_NUMBER,
		v_TDIE_300_MPRN_REC.TARIFF_CONFIGURATION_CODE
	FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_MESSAGE, v_XML_MPRN_PATH))) T;

	INSERT INTO TDIE_300_MPRN VALUES v_TDIE_300_MPRN_REC;

	 IF v_TDIE_300_MPRN_REC.LOAD_PROFILE_CODE IS NOT NULL THEN
		-- Insert Load Profile COde into System_Label
		SP.ENSURE_SYSTEM_LABELS(0, 'Scheduling', 'TDIE','Load Profile Codes',
			CASE WHEN SUBSTR(p_MESSAGE_HEADER.MESSAGE_TYPE_CODE,1,1)='N' OR (v_JURISDICTION = MM_TDIE_UTIL.c_TDIE_JURISDICTION_NI)
				 THEN 'NI-NHH'
				 ELSE 'ROI-NQH'
			END,
			v_TDIE_300_MPRN_REC.LOAD_PROFILE_CODE, NULL, 0, 0);
	 END IF;

	 -- Insert DUOS Groups into System_Label
	 SP.ENSURE_SYSTEM_LABELS(0, 'Scheduling', 'TDIE','DUOS Groups',
		CASE WHEN SUBSTR(p_MESSAGE_HEADER.MESSAGE_TYPE_CODE,1,1)='N' OR (v_JURISDICTION = MM_TDIE_UTIL.c_TDIE_JURISDICTION_NI)
			 THEN 'NI'
			 ELSE 'ROI'
		END,
	    v_TDIE_300_MPRN_REC.DUOS_GROUP, NULL, 0, 0);

	-- Handle inserting new records into TDIE_300_USAGE_FACTOR table based on the UsageFactors elements in the message
	IF p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('300','300S','305','306','307','310','320','332') THEN
		INSERT INTO TDIE_300_USAGE_FACTOR
		   (TDIE_ID,
			TIMESLOT_CODE,
			EFFECTIVE_FROM_DATE,
			USAGE_FACTOR_TYPE,
			USAGE_FACTOR)
		SELECT p_TDIE_ID,
			EXTRACTVALUE(VALUE(T), '//@TimeslotCode'),
			TO_DATE(EXTRACTVALUE(VALUE(T), '//@EffectiveFromDate'), MM_TDIE_UTIL.g_XML_DATE_FORMAT),
			CASE
				WHEN EXTRACTVALUE(VALUE(T), '//@EstimatedUsageFactor') IS NOT NULL THEN
					MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ESTIMATED
				WHEN EXTRACTVALUE(VALUE(T), '//@ActualUsageFactor') IS NOT NULL THEN
					MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ACTUAL
			END,
			CASE
				WHEN EXTRACTVALUE(VALUE(T), '//@EstimatedUsageFactor') IS NOT NULL THEN
					EXTRACTVALUE(VALUE(T), '//@EstimatedUsageFactor')
				WHEN EXTRACTVALUE(VALUE(T), '//@ActualUsageFactor') IS NOT NULL THEN
					EXTRACTVALUE(VALUE(T), '//@ActualUsageFactor')
			END
		FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_MESSAGE, v_XML_MPRN_PATH || '/UsageFactors'))) T;
	END IF;

	-- Determine types of meter/register nodes:
	--- 332 has three types
	IF p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('332', '332W', 'N332') THEN
		v_METER_TYPES.DELETE;
		v_METER_TYPES.EXTEND;
		v_METER_TYPES(v_METER_TYPES.LAST).XML_PATH := '/NewMeterRegisters';
		v_METER_TYPES(v_METER_TYPES.LAST).REGISTER_NODE_TYPE := c_REGISTER_NODE_TYPE_NEW;
		v_METER_TYPES.EXTEND;
		v_METER_TYPES(v_METER_TYPES.LAST).XML_PATH := '/RetainedMeterRegisters';
		v_METER_TYPES(v_METER_TYPES.LAST).REGISTER_NODE_TYPE := c_REGISTER_NODE_TYPE_RETAINED;
		v_METER_TYPES.EXTEND;
		v_METER_TYPES(v_METER_TYPES.LAST).XML_PATH := '/RemovedMeterRegisters';
		v_METER_TYPES(v_METER_TYPES.LAST).REGISTER_NODE_TYPE := c_REGISTER_NODE_TYPE_REMOVED;
	ELSE

		v_METER_TYPES.DELETE;
		v_METER_TYPES.EXTEND;
		v_METER_TYPES(v_METER_TYPES.LAST).XML_PATH := '/MeterID';

		IF p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('307','N307','320','N320') THEN
			-- New --> No Consumption, Process Only Estimated UF
			v_METER_TYPES(v_METER_TYPES.LAST).REGISTER_NODE_TYPE := c_REGISTER_NODE_TYPE_NEW;
        ELSIF p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('310','N310') THEN
			-- Removed --> Process Consumption, Process Only Actual UF
			v_METER_TYPES(v_METER_TYPES.LAST).REGISTER_NODE_TYPE := c_REGISTER_NODE_TYPE_REMOVED;
		ELSE
			-- Process All
			v_METER_TYPES(v_METER_TYPES.LAST).REGISTER_NODE_TYPE := c_REGISTER_NODE_TYPE_RETAINED;
		END IF;
	END IF;

-- Handle Meters and Registers
	FOR i IN v_METER_TYPES.FIRST..v_METER_TYPES.LAST LOOP

		FOR v_METER IN c_METERS(v_XML_MESSAGE, v_XML_MPRN_PATH||v_METER_TYPES(i).XML_PATH) LOOP

			-- merge instead of insert because there could be duplicates: example, if
			-- 332 references same serial number in new meter registers and retained meter
			-- registers nodes.
			MERGE INTO TDIE_300_METER M
			USING (SELECT p_TDIE_ID as TDIE_ID,
							v_METER.SERIAL_NUMBER as SERIAL_NUMBER,
							v_METER.METER_CATEGORY_CODE as METER_CATEGORY_CODE,
							v_METER.METER_LOCATION_CODE as METER_LOCATION_CODE,
							v_METER.EXCHANGED_METER_REFERENCE AS EXCHANGED_METER_REFERENCE
						FROM DUAL) D
			ON (M.TDIE_ID = D.TDIE_ID
				AND M.SERIAL_NUMBER = D.SERIAL_NUMBER)
			WHEN MATCHED THEN
				UPDATE SET M.METER_CATEGORY_CODE = D.METER_CATEGORY_CODE,
							M.METER_LOCATION_CODE = D.METER_LOCATION_CODE,
							M.EXCHANGED_METER_REFERENCE = D.EXCHANGED_METER_REFERENCE
			WHEN NOT MATCHED THEN
				INSERT (M.TDIE_ID, M.SERIAL_NUMBER, M.METER_CATEGORY_CODE, M.METER_LOCATION_CODE, M.EXCHANGED_METER_REFERENCE)
				VALUES (D.TDIE_ID, D.SERIAL_NUMBER, D.METER_CATEGORY_CODE, D.METER_LOCATION_CODE, D.EXCHANGED_METER_REFERENCE);

			v_XML_REG_PATH := v_METER_TYPES(i).XML_PATH||'/RegisterLevelInfo';

			-- Handle Registers
			FOR v_REGISTER IN c_REGISTERS(v_METER.XML_OBJECT,
									   		v_XML_REG_PATH) LOOP

				INSERT INTO TDIE_300_REGISTER
					(TDIE_ID,
					 SERIAL_NUMBER,
					 TIMESLOT_CODE,
					 UOM_CODE,
					 PREVIOUS_READ_DATE,
					 METER_REGISTER_SEQUENCE,
					 READ_REASON_CODE,
					 READ_STATUS_CODE,
					 READ_TYPE_CODE,
					 REGISTER_TYPE_CODE,
					 METER_MULTIPLIER,
					 PRE_DECIMAL_DETAILS,
					 POST_DECIMAL_DETAILS,
					 CONSUMPTION,
					 READING_VALUE,
					 ANNUALISED_ACTUAL_CONSUMPTION,
					 ESTIMATED_USAGE_FACTOR,
					 REGISTER_NODE_TYPE)
				VALUES
					(p_TDIE_ID,
					 v_METER.SERIAL_NUMBER,
					 v_REGISTER.TIMESLOT_CODE,
					 v_REGISTER.UOM_CODE,
					 v_REGISTER.PREVIOUS_READ_DATE,
					 v_REGISTER.METER_REGISTER_SEQUENCE,
					 v_REGISTER.READ_REASON_CODE,
					 v_REGISTER.READ_STATUS_CODE,
					 v_REGISTER.READ_TYPE_CODE,
					 v_REGISTER.REGISTER_TYPE_CODE,
					 v_REGISTER.METER_MULTIPLIER,
					 v_REGISTER.PRE_DECIMAL_DETAILS,
					 v_REGISTER.POST_DECIMAL_DETAILS,
					 v_REGISTER.CONSUMPTION,
					 v_REGISTER.READING_VALUE,
					 v_REGISTER.ANNUALISED_ACTUAL_CONSUMPTION,
					 v_REGISTER.ESTIMATED_USAGE_FACTOR,
					 v_METER_TYPES(i).REGISTER_NODE_TYPE);

			END LOOP;

		END LOOP;

	END LOOP;

END IMPORT_XML_300;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_TDIE_300_EXCEPTION
	(
	p_TDIE_ID IN NUMBER,
	p_MESSAGE_CODE IN VARCHAR2,
	p_EXTRA_MESSAGE_TEXT IN VARCHAR2,
	p_IGNORE_ERROR IN NUMBER := 0
	) AS
BEGIN

	LOGS.LOG_ERROR(p_EVENT_TEXT => p_EXTRA_MESSAGE_TEXT,
		p_MESSAGE_CODE => p_MESSAGE_CODE);

	MERGE INTO TDIE_300_EXCEPTION T
	USING (SELECT p_TDIE_ID AS TDIE_ID,
				  LOGS.LAST_EVENT_ID() AS EVENT_ID,
				  p_IGNORE_ERROR AS IGNORE_ERROR
	  	   FROM DUAL) S
	ON (T.TDIE_ID = S.TDIE_ID)
	WHEN MATCHED THEN
	  UPDATE SET T.EVENT_ID = S.EVENT_ID,
	  			 T.IGNORE_ERROR = p_IGNORE_ERROR
	WHEN NOT MATCHED THEN
	  INSERT (T.TDIE_ID, T.EVENT_ID, T.IGNORE_ERROR)
	  VALUES (S.TDIE_ID, S.EVENT_ID, S.IGNORE_ERROR);

END PUT_TDIE_300_EXCEPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_MPRN
    (
    p_TDIE_ID IN NUMBER,
    p_ACCOUNT_ID OUT NUMBER,
    p_SERVICE_LOCATION_ID OUT NUMBER
    ) AS

    v_TDIE_MESSAGE TDIE_MESSAGE%ROWTYPE;

BEGIN

    SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

    BEGIN
		p_ACCOUNT_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(v_TDIE_MESSAGE.LOCATION_ID, EC.ED_ACCOUNT, EC.ES_TDIE);
	EXCEPTION
		WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
			ERRS.RAISE(MSGCODES.c_ERR_MISSING_MPRN, 'Account not found. MPRN=' || v_TDIE_MESSAGE.LOCATION_ID);
	END;

	BEGIN
		p_SERVICE_LOCATION_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(v_TDIE_MESSAGE.LOCATION_ID, EC.ED_SERVICE_LOCATION, EC.ES_TDIE);
	EXCEPTION
		WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
			ERRS.RAISE(MSGCODES.c_ERR_MISSING_MPRN, 'Service Location not found. MPRN=' || v_TDIE_MESSAGE.LOCATION_ID);
	END;

END GET_MPRN;
----------------------------------------------------------------------------------------------------
PROCEDURE VALIDATE_MPRN
    (
    p_TDIE_ID 				IN NUMBER,
    p_ACCOUNT_ID 			OUT NUMBER,
    p_SERVICE_LOCATION_ID 	OUT NUMBER
    ) AS

    v_TDIE_MESSAGE TDIE_MESSAGE%ROWTYPE;
v_TDIE_300_MPRN TDIE_300_MPRN%ROWTYPE;
v_MIN_PREV_READ_DATE DATE;
v_BEGIN_DATE		DATE;
v_END_DATE          DATE;
v_COUNT				PLS_INTEGER;
v_EXPECTED			PLS_INTEGER;
v_MIN_EDC_ID		NUMBER(9);
v_MAX_EDC_ID		NUMBER(9);
v_EXPECTED_EDC_ID	NUMBER(9);
v_MODEL_OPTION		ACCOUNT.ACCOUNT_MODEL_OPTION%TYPE;
v_ENTITY_GROUP_ID ENTITY_GROUP.ENTITY_GROUP_ID%TYPE;
v_JURISDICTION      VARCHAR2(4);

v_DUOS_VALID_BEGIN DATE;
v_DUOS_VALID_END DATE;

BEGIN

    SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

	SELECT * INTO v_TDIE_300_MPRN FROM TDIE_300_MPRN T WHERE T.TDIE_ID = p_TDIE_ID;

	SELECT MIN(A.PREVIOUS_READ_DATE)
	INTO v_MIN_PREV_READ_DATE
	    FROM TDIE_300_REGISTER A
	    WHERE A.TDIE_ID = p_TDIE_ID;

    GET_VALIDATION_DATE_RANGE(v_MIN_PREV_READ_DATE,
                            v_TDIE_MESSAGE.MESSAGE_DATE,
                            v_BEGIN_DATE,
                            v_END_DATE);

	GET_MPRN(p_TDIE_ID, p_ACCOUNT_ID, p_SERVICE_LOCATION_ID);

	-- total number of days in this period
	v_EXPECTED := v_END_DATE - v_BEGIN_DATE + 1;

	-- Validate ACCOUNT Model Option
	SELECT A.ACCOUNT_MODEL_OPTION
	INTO v_MODEL_OPTION
		FROM ACCOUNT A
	WHERE A.ACCOUNT_ID = p_ACCOUNT_ID;
	-- make sure it's what we expect
	ASSERT(v_MODEL_OPTION = 'Meter',
			'Invalid Account. Account is not a "Meter" modelled. MPRN=' || v_TDIE_MESSAGE.LOCATION_ID,
			MSGCODES.c_ERR_MISSING_MPRN);

	-- Validate ACCOUNT_STATUS
	SELECT SUM(LEAST(NVL(A.END_DATE,CONSTANTS.HIGH_DATE),v_END_DATE)
				- GREATEST(A.BEGIN_DATE,v_BEGIN_DATE) + 1) -- total span of days
	INTO v_COUNT
	FROM ACCOUNT_STATUS A, ACCOUNT_STATUS_NAME N
		WHERE A.ACCOUNT_ID = p_ACCOUNT_ID
		AND A.BEGIN_DATE <= v_END_DATE
		AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= v_BEGIN_DATE
		AND A.STATUS_NAME = N.STATUS_NAME
		AND N.IS_ACTIVE = 1;
	-- make sure relationships span entire range
	ASSERT(MM_TDIE_UTIL.VERIFY_STATIC_DATA_DURATION(v_COUNT,v_EXPECTED),
			'Account Status not found. MPRN=' || v_TDIE_MESSAGE.LOCATION_ID
				|| ', Date Range=' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_BEGIN_DATE,v_END_DATE),
			MSGCODES.c_ERR_MISSING_MPRN);

	-- Validate ACCOUNT_ESP
	SELECT SUM(LEAST(NVL(A.END_DATE,CONSTANTS.HIGH_DATE),v_END_DATE)
				- GREATEST(A.BEGIN_DATE,v_BEGIN_DATE) + 1) -- total span of days
	INTO v_COUNT
		FROM ACCOUNT_ESP A
		WHERE A.ACCOUNT_ID = p_ACCOUNT_ID
		AND A.BEGIN_DATE <= v_END_DATE
		AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= v_BEGIN_DATE;
	-- make sure relationships span entire range
	ASSERT(MM_TDIE_UTIL.VERIFY_STATIC_DATA_DURATION(v_COUNT,v_EXPECTED),
			'Account/ESP record not found. MPRN=' || v_TDIE_MESSAGE.LOCATION_ID
				|| ', Date Range=' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_BEGIN_DATE,v_END_DATE),
			MSGCODES.c_ERR_MISSING_MPRN);

	-- Validate ACCOUNT_EDC
    v_JURISDICTION := GET_JURISDICTION_FOR_IMPORTS(v_TDIE_MESSAGE.RECIPIENT_ID);

	v_EXPECTED_EDC_ID := CASE
                            WHEN SUBSTR(v_TDIE_MESSAGE.MESSAGE_TYPE_CODE,1,1) = 'N' OR v_JURISDICTION = MM_TDIE_UTIL.c_TDIE_JURISDICTION_NI THEN
							    MM_TDIE_UTIL.g_NIE_EDC_ID
							ELSE
								MM_TDIE_UTIL.g_ESBN_EDC_ID
							END;
	-- query for actual account relationship(s)
	SELECT SUM(LEAST(NVL(A.END_DATE,CONSTANTS.HIGH_DATE),v_END_DATE)
				- GREATEST(A.BEGIN_DATE,v_BEGIN_DATE) + 1), -- total span of days
			MIN(A.EDC_ID), MAX(A.EDC_ID)
	INTO v_COUNT, v_MIN_EDC_ID, v_MAX_EDC_ID
		FROM ACCOUNT_EDC A
		WHERE A.ACCOUNT_ID = p_ACCOUNT_ID
		AND A.BEGIN_DATE <= v_END_DATE
		AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= v_BEGIN_DATE;
	-- make sure relationships span entire range
	ASSERT(MM_TDIE_UTIL.VERIFY_STATIC_DATA_DURATION(v_COUNT,v_EXPECTED),
			'Account/EDC record not found. MPRN=' || v_TDIE_MESSAGE.LOCATION_ID
				|| ', Date Range=' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_BEGIN_DATE,v_END_DATE),
			MSGCODES.c_ERR_MISSING_MPRN);
	-- make sure relationship is correct per message jurisdiction
	ASSERT(v_MIN_EDC_ID = v_EXPECTED_EDC_ID AND v_MAX_EDC_ID = v_EXPECTED_EDC_ID,
			'Account/EDC record invalid - expecting '||TEXT_UTIL.TO_CHAR_ENTITY(v_EXPECTED_EDC_ID,EC.ED_EDC)
				|| ' for MPRN=' || v_TDIE_MESSAGE.LOCATION_ID
				|| ', Date Range=' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_BEGIN_DATE,v_END_DATE),
			MSGCODES.c_ERR_MISSING_MPRN);

	-- Validate DUOS_GROUP
	BEGIN
		SELECT E.ENTITY_GROUP_ID
		INTO v_ENTITY_GROUP_ID
		FROM ENTITY_GROUP E
		WHERE E.ENTITY_GROUP_NAME = v_TDIE_300_MPRN.DUOS_GROUP
		AND E.GROUP_CATEGORY = MM_TDIE_UTIL.g_EG_DUOS_GROUP;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			ERRS.RAISE(MSGCODES.c_ERR_MISSING_NQH_STATIC_DATA, 'Entity Group not found. DUOS_GROUP=' || v_TDIE_300_MPRN.DUOS_GROUP);
	END;


    -- FOR 332s, JUST VALIDATE DUOS GROUP FOR THE MESSAGE DATE, BUT SINCE THE MESSAGE DATE CAN BE OFF, WE BUILD IN THE
    -- THRESHOLD
    v_DUOS_VALID_BEGIN := CASE WHEN v_TDIE_MESSAGE.MESSAGE_TYPE_CODE IN ('332', 'N332', '332W') THEN
                                v_TDIE_MESSAGE.MESSAGE_DATE - MM_TDIE_UTIL.c_STATIC_DATA_DATE_THRESHOLD ELSE v_BEGIN_DATE END;
    v_DUOS_VALID_END := CASE WHEN v_TDIE_MESSAGE.MESSAGE_TYPE_CODE IN ('332', 'N332', '332W') THEN
                                v_TDIE_MESSAGE.MESSAGE_DATE + MM_TDIE_UTIL.c_STATIC_DATA_DATE_THRESHOLD ELSE v_END_DATE END;
    -- Validate DUOS_GROUP membership
	IF NOT SD.IS_MEMBER_OF_ENTITY_GROUP(p_ACCOUNT_ID, v_ENTITY_GROUP_ID, v_DUOS_VALID_BEGIN, v_DUOS_VALID_END, TRUE) THEN
		ERRS.RAISE(MSGCODES.c_ERR_MISSING_NQH_STATIC_DATA, 'Account/Entity Group not found. DUOS Group='
			|| v_TDIE_300_MPRN.DUOS_GROUP || ', Date Range=' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_BEGIN_DATE,v_TDIE_MESSAGE.MESSAGE_DATE));
	END IF;

	-- Validate SERVICE_LOCATION / ACCOUNT assignment
	SELECT SUM(LEAST(NVL(A.END_DATE,CONSTANTS.HIGH_DATE),v_END_DATE)
				- GREATEST(A.BEGIN_DATE,v_BEGIN_DATE) + 1) -- total span of days
	INTO v_COUNT
	FROM ACCOUNT_SERVICE_LOCATION A
	WHERE A.ACCOUNT_ID = p_ACCOUNT_ID
		AND A.SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID
		AND A.BEGIN_DATE <= v_END_DATE
		AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= v_BEGIN_DATE;
	-- make sure relationships span entire range
	ASSERT(MM_TDIE_UTIL.VERIFY_STATIC_DATA_DURATION(v_COUNT,v_EXPECTED),
			'Account/Service Location not found. MPRN=' || v_TDIE_MESSAGE.LOCATION_ID
				|| ', Date Range=' || TEXT_UTIL.TO_CHAR_DATE_RANGE(v_BEGIN_DATE,v_END_DATE),
			MSGCODES.c_ERR_MISSING_MPRN);

END VALIDATE_MPRN;
----------------------------------------------------------------------------------------------------
FUNCTION GET_SERVICE_ID
	(
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_READ_DATE IN DATE
	) RETURN NUMBER AS

v_ACCOUNT_SERVICE_ID NUMBER(9);
v_PROVIDER_SERVICE_ID NUMBER(9);
v_SERVICE_ID NUMBER(9);
v_SERVICE_DELIVERY_ID NUMBER(9);
v_ACCOUNT_MODEL_ID NUMBER(1);

BEGIN
	BEGIN
		SELECT MODEL_ID
		INTO v_ACCOUNT_MODEL_ID
		FROM ACCOUNT
		WHERE ACCOUNT_ID = p_ACCOUNT_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'ACCOUNT_ID = ' || p_ACCOUNT_ID);
	END;

	ASSERT(v_ACCOUNT_MODEL_ID IS NOT NULL, 'Invalid Account MODEL_ID. MODEL_ID must be non-null.');
	ASSERT(v_ACCOUNT_MODEL_ID IN (CONSTANTS.ELECTRIC_MODEL, CONSTANTS.GAS_MODEL), 'Invalid Account MODEL_ID. MODEL_ID must be set to Gas or Electric.');

	CS.GET_ACCOUNT_SERVICE_ID(p_ACCOUNT_ID,p_SERVICE_LOCATION_ID,p_METER_ID,CONSTANTS.NOT_ASSIGNED,v_ACCOUNT_SERVICE_ID);
	v_PROVIDER_SERVICE_ID := CS.GET_PROVIDER_SERVICE_ID(v_ACCOUNT_SERVICE_ID,p_READ_DATE);
	CS.GET_SERVICE_DELIVERY_ID(v_ACCOUNT_SERVICE_ID, v_PROVIDER_SERVICE_ID, p_READ_DATE, v_SERVICE_DELIVERY_ID);
	v_SERVICE_ID := CS.GET_SERVICE_ID(v_ACCOUNT_MODEL_ID,GA.BASE_SCENARIO_ID,CONSTANTS.LOW_DATE,v_PROVIDER_SERVICE_ID,v_ACCOUNT_SERVICE_ID,v_SERVICE_DELIVERY_ID);
	RETURN v_SERVICE_ID;
END GET_SERVICE_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_METER_ID
    (
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_SERIAL_NUMBER IN VARCHAR2,
    p_TIMESLOT_CODE IN VARCHAR2,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) RETURN NUMBER IS

    v_METER_ID METER.METER_ID%TYPE;
BEGIN
    v_METER_ID := MM_TDIE_UTIL.GET_METER_ID(p_SERVICE_LOCATION_ID, p_SERIAL_NUMBER, p_BEGIN_DATE, p_END_DATE, p_TIMESLOT_CODE);

    RETURN v_METER_ID;
EXCEPTION
    WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
        ERRS.RAISE(MSGCODES.c_ERR_MISSING_SERIAL_NUMBER, 'Serial Number not found. SERIAL_NUMBER=' || p_SERIAL_NUMBER);
END GET_METER_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_METER_ID
    (
    p_MPRN IN VARCHAR2,
    p_SERIAL_NUMBER IN VARCHAR2,
    p_TIMESLOT_CODE IN VARCHAR2,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) RETURN NUMBER IS

    v_METER_ID METER.METER_ID%TYPE;
BEGIN
    v_METER_ID := MM_TDIE_UTIL.GET_METER_ID(p_MPRN, p_SERIAL_NUMBER, p_BEGIN_DATE, p_END_DATE, p_TIMESLOT_CODE);

    RETURN v_METER_ID;
EXCEPTION
    WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
        ERRS.RAISE(MSGCODES.c_ERR_MISSING_SERIAL_NUMBER, 'Serial Number not found. SERIAL_NUMBER=' || p_SERIAL_NUMBER);
END GET_METER_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE VALIDATE_METER
	(
	p_TDIE_ID 				IN NUMBER,
	p_SERVICE_LOCATION_ID 	IN NUMBER,
	p_SERIAL_NUMBER 		IN VARCHAR2,
	p_BEGIN_DATE 			IN DATE,
	p_END_DATE 				IN DATE,
	p_TIMESLOT_CODE 		IN VARCHAR2,
	p_METER_ID 				OUT NUMBER
	) AS

v_TEMP				NUMBER(9);
v_MESSAGE_TYPE_CODE TDIE_MESSAGE.MESSAGE_TYPE_CODE%TYPE;
v_LOAD_PROFILE_CODE TDIE_300_MPRN.LOAD_PROFILE_CODE%TYPE;
v_METER_STAT		PLS_INTEGER;
v_COUNT				PLS_INTEGER;
v_TOTAL_COUNT		PLS_INTEGER;
v_MESSAGE_DATE      TDIE_MESSAGE.MESSAGE_DATE%TYPE;
v_LP_BEGIN          DATE;
v_LP_END            DATE;
v_LP_EXPECTED       PLS_INTEGER;
	--==============================================
	FUNCTION QUERY_CALENDAR_DAYS
		(
		p_CALENDAR_TYPE	IN VARCHAR2,
		p_CALENDAR_CODE	IN VARCHAR2
		) RETURN PLS_INTEGER AS

	v_RET PLS_INTEGER;

	BEGIN
		SELECT NVL(SUM(LEAST(NVL(A.END_DATE,CONSTANTS.HIGH_DATE),v_LP_END)
					- GREATEST(A.BEGIN_DATE,v_LP_BEGIN) + 1),0) -- total span of days
		INTO v_RET
		FROM METER_CALENDAR A
		WHERE A.CASE_ID = GA.BASE_CASE_ID
		  AND A.METER_ID = p_METER_ID
		  AND SUBSTR(A.CALENDAR_TYPE,1,1) = p_CALENDAR_TYPE
		  AND A.BEGIN_DATE <= v_LP_END
		  AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= v_LP_BEGIN
		  AND EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_CALENDAR,A.CALENDAR_ID,EC.ES_TDIE) LIKE p_CALENDAR_CODE;

		RETURN v_RET;

	EXCEPTION
		WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
			-- exception raised in call to EI.GET_ENTITY_IDENTIFIER_EXTSYS indicates an
			-- invalid Calendar ID
			RETURN NULL;
	END QUERY_CALENDAR_DAYS;
	--==============================================
	PROCEDURE QUERY_CALENDAR_DAYS
		(
		p_CALENDAR_TYPE IN VARCHAR2
		) AS
	BEGIN
		-- Count days in which the specified load profile code is assigned
		v_COUNT := QUERY_CALENDAR_DAYS(p_CALENDAR_TYPE, v_LOAD_PROFILE_CODE);
		-- As well as count of all assignments (which could differ from load profile code if the assignment is incorrect)
		v_TOTAL_COUNT := QUERY_CALENDAR_DAYS(p_CALENDAR_TYPE, '%');
	END QUERY_CALENDAR_DAYS;
	--==============================================
	BEGIN
	p_METER_ID := GET_METER_ID(p_SERVICE_LOCATION_ID, p_SERIAL_NUMBER, p_TIMESLOT_CODE, p_BEGIN_DATE, p_END_DATE);

	-- Validate METER_TYPE = 'Period'
	BEGIN
		SELECT A.METER_ID
		INTO v_TEMP
		FROM METER A
		WHERE A.METER_ID = p_METER_ID
		  AND A.METER_TYPE = 'Period';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			ERRS.RAISE(MSGCODES.c_ERR_MISSING_SERIAL_NUMBER, 'Invalid Meter ('||TEXT_UTIL.TO_CHAR_ENTITY(p_METER_ID, EC.ED_METER)||'). Meter Type is not "Period". SERIAL_NUMBER=' || p_SERIAL_NUMBER);
	END;

	-- Validate SERVICE_LOCATION / METER assignment
	-- make sure relationships span entire range
	ASSERT(MM_TDIE_UTIL.VERIFY_SERVICE_LOCATION_METER(p_SERVICE_LOCATION_ID, p_METER_ID, p_BEGIN_DATE, p_END_DATE),
			'Service Location/Meter not found. SERIAL_NUMBER=' || p_SERIAL_NUMBER
				|| ',BEGIN_DATE=' || p_BEGIN_DATE || ',END_DATE=' || p_END_DATE,
			MSGCODES.c_ERR_MISSING_SERIAL_NUMBER);

	-- Get the MESSAGE_TYPE_CODE, MESSAGE_DATE, and LOAD_PROFILE_CODE for this message
	SELECT T.MESSAGE_TYPE_CODE, T.MESSAGE_DATE, M.LOAD_PROFILE_CODE,
		-- if any registers for this serial number are new or retained, then consider meter
		-- to be new or retained. compute status as removed (zero) if and only if all
		-- registers are marked as removed
		MAX(CASE R.REGISTER_NODE_TYPE WHEN c_REGISTER_NODE_TYPE_REMOVED THEN 0
									  WHEN c_REGISTER_NODE_TYPE_NEW THEN 1
									  ELSE 2
									  END) as METER_NODE_TYPE
	INTO v_MESSAGE_TYPE_CODE, v_MESSAGE_DATE, v_LOAD_PROFILE_CODE, v_METER_STAT
	FROM TDIE_MESSAGE T,
		TDIE_300_MPRN M,
		TDIE_300_REGISTER R
	WHERE T.TDIE_ID = p_TDIE_ID
		AND M.TDIE_ID = p_TDIE_ID
		AND R.TDIE_ID = p_TDIE_ID
		AND R.SERIAL_NUMBER = p_SERIAL_NUMBER
	GROUP BY T.MESSAGE_TYPE_CODE, T.MESSAGE_DATE, M.LOAD_PROFILE_CODE;

	-- Next step is to validate the Load Profile Code (which maps to meter's calendar assignment).
	-- We do NOT perform this check for a few different situations:
	--  * NI messages do not indicate load profile code. So we only validate this for ROI messages.
	--  * Do not validate this field if it is missing from the XML file. For example, 305 messages
	--    do not indicate a load profile code so we don't validate this in those cases.
	--  * Removed meters in 332 messages do not get validated. These meters could be legitimately
	--    associated with a different load profile code since the 332 only indicates data as of the
	--    change. So new and/or retained meters should be validated, but removed meters might have
	--    been associated with a different profile code that isn't in the XML message.
	IF SUBSTR(v_MESSAGE_TYPE_CODE, 1,1) <> 'N' AND v_LOAD_PROFILE_CODE IS NOT NULL AND
		(v_MESSAGE_TYPE_CODE NOT IN ('332', 'N332', '332W') OR v_METER_STAT <> 0) THEN

		-- ONLY VALIDATE THE LP ASSIGNMENT FOR 332s ON THE MESSAGE DATE, BUT SINCE
		-- MESSAGE DATE HAS A HISTORY OF BEING OFF BY A COUPLE OF DAYS, GIVE IT A
		-- THRESHOLD BUT ONLY LOOK FOR ONE DAY'S ASSIGNMENT
		v_LP_BEGIN := CASE WHEN v_MESSAGE_TYPE_CODE IN ('332', 'N332', '332W')
			THEN v_MESSAGE_DATE - MM_TDIE_UTIL.c_STATIC_DATA_DATE_THRESHOLD
			ELSE p_BEGIN_DATE END;
		v_LP_END := CASE WHEN v_MESSAGE_TYPE_CODE IN ('332', 'N332', '332W')
			THEN v_MESSAGE_DATE + MM_TDIE_UTIL.c_STATIC_DATA_DATE_THRESHOLD
			ELSE p_END_DATE END;

		v_LP_EXPECTED := CASE WHEN v_MESSAGE_TYPE_CODE IN ('332', 'N332', '332W') THEN 1 ELSE v_LP_END - v_LP_BEGIN + 1 END;

		-- Start with backcast calendar assignments
		QUERY_CALENDAR_DAYS('B');
		IF v_TOTAL_COUNT = 0 THEN
			-- fall back to forecast calendar assignments
			QUERY_CALENDAR_DAYS('F');
		END IF;

		-- make sure relationships span entire range
		ASSERT(MM_TDIE_UTIL.VERIFY_STATIC_DATA_DURATION(v_TOTAL_COUNT,v_LP_EXPECTED),
					'Meter/Calendar not found. Meter ='
						|| TEXT_UTIL.TO_CHAR_ENTITY(p_METER_ID, EC.ED_METER)
						|| ', Date Range = '||TEXT_UTIL.TO_CHAR_DATE_RANGE(p_BEGIN_DATE, p_END_DATE),
					MSGCODES.c_ERR_MISSING_NQH_STATIC_DATA);

		-- make sure relationship is correct
			ASSERT(MM_TDIE_UTIL.VERIFY_STATIC_DATA_DURATION(v_COUNT,v_LP_EXPECTED),
					'Meter''s associated Calendar does not have the '
						|| 'expected profile code: ' || v_LOAD_PROFILE_CODE || '. Meter ='
						|| TEXT_UTIL.TO_CHAR_ENTITY(p_METER_ID, EC.ED_METER)
						|| ', Date Range = '||TEXT_UTIL.TO_CHAR_DATE_RANGE(p_BEGIN_DATE, p_END_DATE),
					MSGCODES.c_ERR_MISSING_NQH_STATIC_DATA);

	END IF;

END VALIDATE_METER;
----------------------------------------------------------------------------------------------------
PROCEDURE VALIDATE_TIMESLOT_CODE
	(
	p_TIMESLOT_CODE IN VARCHAR2,
	p_PERIOD_ID OUT NUMBER,
	p_TEMPLATE_ID OUT NUMBER
	) AS
v_TEMP NUMBER(9);
BEGIN
	-- Validate PERIOD
	BEGIN
		p_PERIOD_ID := EI.GET_ID_FROM_ALIAS(p_TIMESLOT_CODE, EC.ED_PERIOD);
	EXCEPTION
		WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
			ERRS.RAISE(MSGCODES.c_ERR_MISSING_NQH_STATIC_DATA, 'Period not found. TIMESLOT_CODE = ' || p_TIMESLOT_CODE);
	END;

	-- Determine the number of assigned Templates
	SELECT COUNT(DISTINCT A.TEMPLATE_ID)
	INTO v_TEMP
	FROM SEASON_TEMPLATE A
	WHERE A.PERIOD_ID = p_PERIOD_ID;

	-- Validate TEMPLATE_ID
	SELECT MIN(A.TEMPLATE_ID)
	INTO p_TEMPLATE_ID
	FROM SEASON_TEMPLATE A
	WHERE A.PERIOD_ID = p_PERIOD_ID;

	IF p_TEMPLATE_ID IS NULL THEN
		ERRS.RAISE(MSGCODES.c_ERR_MISSING_NQH_STATIC_DATA, 'Template not found. TIMESLOT_CODE = ' || p_TIMESLOT_CODE);
	ELSIF v_TEMP > 1 THEN
		LOGS.LOG_WARN('The Period, '|| p_TIMESLOT_CODE
			|| ', is assigned to more than one Template. The following Template will be used: '
			|| TEXT_UTIL.TO_CHAR_ENTITY(p_TEMPLATE_ID, EC.ED_TEMPLATE));
	END IF;

END VALIDATE_TIMESLOT_CODE;
----------------------------------------------------------------------------------------------------
PROCEDURE VALIDATE_SERIAL_NUM_TEMPLATES(p_TDIE_ID IN NUMBER) AS
	v_LAST_METER_ID      METER.METER_ID%TYPE;
	v_METER_ID		 	 METER.METER_ID%TYPE;
	v_PERIOD_ID          PERIOD.PERIOD_ID%TYPE;
	v_TEMPLATE_ID        TEMPLATE.TEMPLATE_ID%TYPE;
	v_LAST_TEMPLATE_ID   TEMPLATE.TEMPLATE_ID%TYPE;
	v_LAST_REG_NODE_TYPE TDIE_300_REGISTER.REGISTER_NODE_TYPE%TYPE;

    v_BEGIN              DATE;
    v_END                DATE;
BEGIN

	FOR v_REC IN (SELECT M.LOCATION_ID,
				   R.TIMESLOT_CODE,
            	   R.SERIAL_NUMBER,
            	   R.REGISTER_NODE_TYPE,
				   M.MESSAGE_DATE,
				   R.PREVIOUS_READ_DATE
            FROM TDIE_MESSAGE M,TDIE_300_REGISTER R
            WHERE M.TDIE_ID = p_TDIE_ID
			  AND R.TDIE_ID = M.TDIE_ID
              AND R.UOM_CODE = 'KWH'
            ORDER BY R.SERIAL_NUMBER, R.REGISTER_NODE_TYPE, R.METER_REGISTER_SEQUENCE) LOOP

		GET_VALIDATION_DATE_RANGE(v_REC.PREVIOUS_READ_DATE,
								v_REC.MESSAGE_DATE,
								v_BEGIN,
								v_END);

		BEGIN
			v_METER_ID := GET_METER_ID(v_REC.LOCATION_ID, v_REC.SERIAL_NUMBER,
										v_REC.TIMESLOT_CODE, v_BEGIN, v_END);
		EXCEPTION
			WHEN MSGCODES.e_ERR_MISSING_SERIAL_NUMBER THEN
				IF v_REC.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_NEW THEN
				-- FOR NEW REGISTERS, THIS ESTIMATED USAGE FACTOR WILL JUST BE IGNORED
				-- SO DON'T RAISE AN EXCEPTION ABOUT THIS VALIDATION
					ERRS.LOG_AND_RAISE();
				END IF;
		END;

		VALIDATE_TIMESLOT_CODE(v_REC.TIMESLOT_CODE, v_PERIOD_ID, v_TEMPLATE_ID);

		IF v_LAST_TEMPLATE_ID IS NOT NULL
				AND v_TEMPLATE_ID <> v_LAST_TEMPLATE_ID
				AND v_METER_ID = v_LAST_METER_ID
				AND v_REC.REGISTER_NODE_TYPE = v_LAST_REG_NODE_TYPE THEN
			-- Raise validation error if any time slot codes for this meter map to periods that are not associated with this same TOU template
			ERRS.RAISE(MSGCODES.c_ERR_MISSING_SERIAL_NUMBER,
					   'The SERIAL_NUMBER in the file contains TIMESLOT_CODEs that belong to more than one TOU Template. SERIAL_NUMBER: ' ||
					   v_REC.SERIAL_NUMBER);
		END IF;

		v_LAST_TEMPLATE_ID := v_TEMPLATE_ID;
		v_LAST_METER_ID := v_METER_ID;
		v_LAST_REG_NODE_TYPE := v_REC.REGISTER_NODE_TYPE;

	END LOOP;
END VALIDATE_SERIAL_NUM_TEMPLATES;
----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_300_NIE_USAGE_FACTOR(p_TDIE_ID IN NUMBER) AS

	v_METER_ID		 	 METER.METER_ID%TYPE;
	v_PERIOD_ID          PERIOD.PERIOD_ID%TYPE;
	v_TEMPLATE_ID        TEMPLATE.TEMPLATE_ID%TYPE;
	v_CUR_TOU_USAGE_FACTOR_ID   	METER_TOU_USAGE_FACTOR.TOU_USAGE_FACTOR_ID%TYPE;
	v_TDIE_MESSAGE 					TDIE_MESSAGE%ROWTYPE;
	v_MIN_PREVIOUS_READ_DATE        DATE;

    v_BEGIN_DATE                    DATE;
    v_END_DATE                      DATE;

BEGIN
	-- Get the original message to determine the ReadDate
	SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

	VALIDATE_SERIAL_NUM_TEMPLATES(p_TDIE_ID);

	-- Loop over all combinations of meters and register node types
	FOR v_METER IN (SELECT R.SERIAL_NUMBER,
						R.REGISTER_NODE_TYPE,
						R.TIMESLOT_CODE
					FROM TDIE_300_REGISTER R
					WHERE R.TDIE_ID = p_TDIE_ID
						AND R.UOM_CODE = 'KWH') LOOP
			BEGIN
    			-- Create Estimated Usage Factor with ReadDate + 1
    			-- First check for an existing usage factor (no estimated UFs for removed
    			-- registers though)
    			IF v_METER.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_REMOVED THEN

    				-- validate meter ID for estimated usage factors
    				v_METER_ID := MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, v_METER.SERIAL_NUMBER, v_TDIE_MESSAGE.MESSAGE_DATE+1, v_TDIE_MESSAGE.MESSAGE_DATE+1, v_METER.TIMESLOT_CODE);

    				VALIDATE_TIMESLOT_CODE(v_METER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);

    				SELECT MAX(A.TOU_USAGE_FACTOR_ID)
    				INTO v_CUR_TOU_USAGE_FACTOR_ID
    				FROM METER_TOU_USAGE_FACTOR A
    				WHERE A.METER_ID = v_METER_ID
    				  AND A.CASE_ID = GA.BASE_CASE_ID
    				  AND A.BEGIN_DATE = v_TDIE_MESSAGE.MESSAGE_DATE + 1;

    				-- Only insert into the usage factor if it doesn't already exist.
    				IF v_CUR_TOU_USAGE_FACTOR_ID IS NULL THEN
						-- all meters need to be set this way - so set it just in case it's not
    					UPDATE METER M
                		SET M.USE_TOU_USAGE_FACTOR = 1
                		WHERE M.METER_ID = v_METER_ID;

						-- get parent ID for period usage factors
						v_CUR_TOU_USAGE_FACTOR_ID := ACCOUNTS_METERS.INSERT_METER_TOU_USAGE_FACTOR(
															v_TDIE_MESSAGE.MESSAGE_DATE + 1,
															NULL,
															v_METER_ID,
															v_TEMPLATE_ID
															);

    					-- Loop over each TIMESLOT_CODE and enter data into METER_TOU_USAGE_FACTOR_PERIOD
    					FOR v_REGISTER IN (SELECT TIMESLOT_CODE,
                                                CASE WHEN v_TDIE_MESSAGE.MESSAGE_TYPE_CODE = 'N306'
                                                    THEN 0 ELSE SUM(ESTIMATED_USAGE_FACTOR) END as ESTIMATED_USAGE_FACTOR
    									   FROM TDIE_300_REGISTER R
    									   WHERE R.TDIE_ID = p_TDIE_ID
    										 AND v_METER_ID = MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, R.SERIAL_NUMBER, v_TDIE_MESSAGE.MESSAGE_DATE+1, v_TDIE_MESSAGE.MESSAGE_DATE+1, R.TIMESLOT_CODE)
    										 AND R.UOM_CODE = 'KWH'
    										 -- just grab rows with matching register node types
    										 AND R.REGISTER_NODE_TYPE = v_METER.REGISTER_NODE_TYPE
    										GROUP BY TIMESLOT_CODE) LOOP
    						VALIDATE_TIMESLOT_CODE(v_REGISTER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);
    						INSERT INTO METER_TOU_USAGE_FACTOR_PERIOD
    						   (TOU_USAGE_FACTOR_ID, PERIOD_ID, FACTOR_VAL, ENTRY_DATE)
    						 VALUES
    						   (v_CUR_TOU_USAGE_FACTOR_ID, v_PERIOD_ID, v_REGISTER.ESTIMATED_USAGE_FACTOR, SYSDATE);
    					END LOOP;
    				END IF;
    			END IF;
			EXCEPTION
				WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
				    -- BZ 27470 -- Check if METER_ID exists for any period by not including date-range. This could be a "terminated" meter
					IF MM_TDIE_UTIL.METER_EXISTS(v_TDIE_MESSAGE.LOCATION_ID, v_METER.SERIAL_NUMBER) THEN
						-- Continue to log a Warning
						LOGS.LOG_WARN(	p_EVENT_TEXT => 'Serial Number='||v_METER.SERIAL_NUMBER||', MPRN='||v_TDIE_MESSAGE.LOCATION_ID||', Date Range='||(v_TDIE_MESSAGE.MESSAGE_DATE+1)||' -> '||(v_TDIE_MESSAGE.MESSAGE_DATE+1),
									   p_MESSAGE_CODE => MSGCODES.c_TDIE_EST_USAGE_FACT_NOT_IMP);
					ELSE
						-- Raise an Error
				        ERRS.RAISE(MSGCODES.c_ERR_MISSING_SERIAL_NUMBER, 'Serial Number not found. SERIAL_NUMBER='||v_METER.SERIAL_NUMBER||', MPRN='||v_TDIE_MESSAGE.LOCATION_ID);
					END IF;
			END;

			-- We cannot enter an Actual Usage Factor for N320 and N332 new meters b/c we don't have a PreviousReadDate,
			-- so exclude them
			IF v_METER.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_NEW THEN

				-- Create Actual Usage Factor with Begin Date = Min(PreviousReadDate), End Date = ReadDate

				SELECT MIN(A.PREVIOUS_READ_DATE)
				INTO v_MIN_PREVIOUS_READ_DATE
				FROM TDIE_300_REGISTER A
				WHERE A.TDIE_ID = p_TDIE_ID
				  AND A.SERIAL_NUMBER = v_METER.SERIAL_NUMBER;

                GET_VALIDATION_DATE_RANGE(v_MIN_PREVIOUS_READ_DATE,
                                        v_TDIE_MESSAGE.MESSAGE_DATE,
                                        v_BEGIN_DATE,
                                        v_END_DATE);

		        v_METER_ID := MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, v_METER.SERIAL_NUMBER, v_BEGIN_DATE, v_END_DATE, v_METER.TIMESLOT_CODE);

				VALIDATE_TIMESLOT_CODE(v_METER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);

				-- all meters need to be set this way - so set it just in case it's not
				UPDATE METER M
        		SET M.USE_TOU_USAGE_FACTOR = 1
        		WHERE M.METER_ID = v_METER_ID;

				-- get parent ID for period usage factors
				v_CUR_TOU_USAGE_FACTOR_ID := ACCOUNTS_METERS.INSERT_METER_TOU_USAGE_FACTOR(
													v_MIN_PREVIOUS_READ_DATE + 1,
													v_TDIE_MESSAGE.MESSAGE_DATE,
													v_METER_ID,
													v_TEMPLATE_ID
													);

				FOR v_REGISTER IN (SELECT TIMESLOT_CODE, SUM(ESTIMATED_USAGE_FACTOR) as ESTIMATED_USAGE_FACTOR
								   FROM TDIE_300_REGISTER R
								   WHERE R.TDIE_ID = p_TDIE_ID
									 AND v_METER_ID = MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, R.SERIAL_NUMBER, v_BEGIN_DATE, v_END_DATE, R.TIMESLOT_CODE)
									 AND R.UOM_CODE = 'KWH'
									 -- just grab rows with matching register node types
									 AND R.REGISTER_NODE_TYPE = v_METER.REGISTER_NODE_TYPE
									GROUP BY TIMESLOT_CODE) LOOP
					VALIDATE_TIMESLOT_CODE(v_REGISTER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);
					INSERT INTO METER_TOU_USAGE_FACTOR_PERIOD
					   (TOU_USAGE_FACTOR_ID, PERIOD_ID, FACTOR_VAL, ENTRY_DATE)
					 VALUES
					   (v_CUR_TOU_USAGE_FACTOR_ID, v_PERIOD_ID, v_REGISTER.ESTIMATED_USAGE_FACTOR, SYSDATE);
				END LOOP;
			END IF;
	END LOOP;
END PROCESS_300_NIE_USAGE_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_300_ROI_USAGE_FACTOR(p_TDIE_ID IN NUMBER) AS

	v_METER_ID						METER.METER_ID%TYPE;
	v_PERIOD_ID						PERIOD.PERIOD_ID%TYPE;
	v_TEMPLATE_ID					TEMPLATE.TEMPLATE_ID%TYPE;
	v_LAST_FROM_DATE				DATE;
	v_END_DATE						DATE;
	v_IS_ACTUAL_USAGE_FACTOR 		BOOLEAN;
	v_EFFECTIVE_USAGE_FACTOR 		TDIE_300_USAGE_FACTOR.USAGE_FACTOR%TYPE;
	v_IDX 							NUMBER(9);
	v_CUR_TOU_USAGE_FACTOR_ID   	METER_TOU_USAGE_FACTOR.TOU_USAGE_FACTOR_ID%TYPE;
	v_TDIE_MESSAGE 					TDIE_MESSAGE%ROWTYPE;
	v_SERIAL_NUMBERS				STRING_COLLECTION;
	v_KEY							VARCHAR2(32);
	v_METER_IDX						NUMBER(9);

	TYPE t_300_USAGE_FACTOR_DETAIL IS RECORD
	(
		TIMESLOT_CODE TDIE_300_USAGE_FACTOR.TIMESLOT_CODE%TYPE,
		USAGE_FACTOR_TYPE TDIE_300_USAGE_FACTOR.USAGE_FACTOR_TYPE%TYPE,
		USAGE_FACTOR TDIE_300_USAGE_FACTOR.USAGE_FACTOR%TYPE
	);

	TYPE t_300_USAGE_FACTOR_DETAILS IS TABLE OF t_300_USAGE_FACTOR_DETAIL;

	TYPE t_USAGE_FACTOR_DETAILS_BY_MTR IS TABLE OF t_300_USAGE_FACTOR_DETAILS INDEX BY BINARY_INTEGER;

	v_USAGE_FACTOR_DETAILS_BY_MTR t_USAGE_FACTOR_DETAILS_BY_MTR;

	TYPE t_TOTAL_CONSUMPTION_REC IS RECORD
	(
		CONSUMPTION	NUMBER(15,3),
		METER_COUNT	PLS_INTEGER
	);
	TYPE t_TOTAL_CONSUMPTION_MAP IS TABLE OF t_TOTAL_CONSUMPTION_REC INDEX BY VARCHAR2(16);

	v_TOTAL_CONSUMPTION_MAP t_TOTAL_CONSUMPTION_MAP;
BEGIN
	-- Get the original message to determine if this is 300,320,or 332
	SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

	VALIDATE_SERIAL_NUM_TEMPLATES(p_TDIE_ID);

	-- Determine sum of consumption for all meters by time slot code
	--	Track consumption differently for applying Actual and Estimated usage factors
	--  since 332 can have some meters that do not apply to one or other
	FOR v_TOTAL_TIMESLOT_CONSUMPTION IN (SELECT MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ACTUAL||':'||R.TIMESLOT_CODE as KEY,
											  NVL(SUM(R.CONSUMPTION),0) as TOTAL_CONSUMPTION,
											  COUNT(DISTINCT R.SERIAL_NUMBER) as METER_COUNT
										  FROM TDIE_300_REGISTER R
										  WHERE R.TDIE_ID = p_TDIE_ID
											  AND R.UOM_CODE = 'KWH'
											  -- actual usage factors do not apply to
											  -- new registers
											  AND R.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_NEW
										  GROUP BY R.TIMESLOT_CODE
										  UNION ALL
										  SELECT MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ESTIMATED||':'||R.TIMESLOT_CODE as KEY,
										  	  NVL(SUM(R.CONSUMPTION),0) as TOTAL_CONSUMPTION,
											  COUNT(DISTINCT R.SERIAL_NUMBER) as METER_COUNT
										  FROM TDIE_300_REGISTER R
										  WHERE R.TDIE_ID = p_TDIE_ID
											  AND R.UOM_CODE = 'KWH'
											  -- estimated usage factors do not apply to
											  -- nemoved registers
											  AND R.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_REMOVED
										  GROUP BY R.TIMESLOT_CODE) LOOP
	  v_TOTAL_CONSUMPTION_MAP(v_TOTAL_TIMESLOT_CONSUMPTION.KEY).CONSUMPTION := v_TOTAL_TIMESLOT_CONSUMPTION.TOTAL_CONSUMPTION;
	  v_TOTAL_CONSUMPTION_MAP(v_TOTAL_TIMESLOT_CONSUMPTION.KEY).METER_COUNT := v_TOTAL_TIMESLOT_CONSUMPTION.METER_COUNT;
	END LOOP;

	IF v_TDIE_MESSAGE.MESSAGE_TYPE_CODE IN ('300','300S','306','307','310','320','332') THEN
		SELECT M.SERIAL_NUMBER
		BULK COLLECT INTO v_SERIAL_NUMBERS
		FROM TDIE_300_METER M
		WHERE M.TDIE_ID = p_TDIE_ID;
	ELSE
		LOGS.LOG_ERROR('Could not process the Usage Factors. Unknown MESSAGE_TYP_CODE = ' || v_TDIE_MESSAGE.MESSAGE_TYPE_CODE);
		RETURN;
	END IF;

	IF v_SERIAL_NUMBERS.COUNT = 0 THEN
		LOGS.LOG_ERROR('Could not process the Usage Factors. No meter serial numbers found');
		RETURN;
	END IF;

	-- Loop over each meter in the file
	FOR v_SN_IDX IN v_SERIAL_NUMBERS.FIRST..v_SERIAL_NUMBERS.LAST LOOP

		-- reset for this meter
		v_LAST_FROM_DATE := NULL;

		-- Loop over all distinct usage factor effective dates in descending order
		FOR v_UF_DATES IN (SELECT DISTINCT A.EFFECTIVE_FROM_DATE,
											A.USAGE_FACTOR_TYPE
						   FROM TDIE_300_USAGE_FACTOR A
						   WHERE A.TDIE_ID = p_TDIE_ID
						   -- also order by usage factor type in descending order
						   -- so we'd process E first and then overwrite with A
						   -- (actual) in unlikely event that we have both for
						   -- a given date range
						   ORDER BY 1 DESC, 2 DESC) LOOP

            BEGIN
                -- figure out date range
                IF v_LAST_FROM_DATE IS NULL THEN
                	IF v_UF_DATES.USAGE_FACTOR_TYPE = 'A' THEN
                		--Actual Usage Factor when LAST_FROM_DATE is null indicates that this import did not have any estimated UF (ie. 310)
                		-- Use Read Date instead (equivalent of last Estimated UF date - 1)
                		v_END_DATE := v_TDIE_MESSAGE.MESSAGE_DATE;
                	ELSE
                		-- initialize to no end date - last usage factor is effective from
                		-- stated from date with no end
                		v_END_DATE := NULL;
                	END IF;
                ELSIF v_LAST_FROM_DATE <> v_UF_DATES.EFFECTIVE_FROM_DATE THEN
                	-- no effective date? set end date to previous effective from date-1
                	-- so that will encompass the days between dates (since the cursor
                	-- is sorted with dates in descending order)
                	v_END_DATE := v_LAST_FROM_DATE-1;
                END IF;

                -- Reset local "actual usage factor" flag and other variables
                v_IS_ACTUAL_USAGE_FACTOR := FALSE;
                v_EFFECTIVE_USAGE_FACTOR := NULL;
                v_USAGE_FACTOR_DETAILS_BY_MTR.DELETE();
                v_IDX := 1;

                -- Loop over all periods associated with TOU template
                FOR v_TDIE_300_REGISTER IN (SELECT TIMESLOT_CODE,
                									SUM(CONSUMPTION) as CONSUMPTION
                							  FROM TDIE_300_REGISTER R
                							  WHERE R.TDIE_ID = p_TDIE_ID
                								  AND R.SERIAL_NUMBER = v_SERIAL_NUMBERS(v_SN_IDX)
                								  AND R.UOM_CODE = 'KWH'
                								  -- exclude "new" nodes from actual usage factors
                								  AND (v_UF_DATES.USAGE_FACTOR_TYPE <> MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ACTUAL
                										OR R.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_NEW)
                								  -- and exclude "removed" nodes from estimated
                								  AND (v_UF_DATES.USAGE_FACTOR_TYPE <> MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ESTIMATED
                										OR R.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_REMOVED)
                							  GROUP BY TIMESLOT_CODE) LOOP

                	VALIDATE_TIMESLOT_CODE(v_TDIE_300_REGISTER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);

                	v_METER_ID := MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, v_SERIAL_NUMBERS(v_SN_IDX),
                							v_UF_DATES.EFFECTIVE_FROM_DATE, NVL(v_END_DATE,v_UF_DATES.EFFECTIVE_FROM_DATE), v_TDIE_300_REGISTER.TIMESLOT_CODE);

	               	-- Query "effective" usage factor for this time slot code and date from message
                	SELECT MAX(F.USAGE_FACTOR)
                	INTO v_EFFECTIVE_USAGE_FACTOR
                	FROM TDIE_300_USAGE_FACTOR F
                	WHERE F.TDIE_ID = p_TDIE_ID
                	  AND F.USAGE_FACTOR_TYPE = v_UF_DATES.USAGE_FACTOR_TYPE
                	  AND F.TIMESLOT_CODE = v_TDIE_300_REGISTER.TIMESLOT_CODE
                	  AND F.EFFECTIVE_FROM_DATE = (SELECT MAX(X.EFFECTIVE_FROM_DATE)
                								   FROM TDIE_300_USAGE_FACTOR X
                								   WHERE X.TDIE_ID = F.TDIE_ID
                								   AND X.TIMESLOT_CODE = F.TIMESLOT_CODE
                								   AND X.USAGE_FACTOR_TYPE = v_UF_DATES.USAGE_FACTOR_TYPE
                								   AND X.EFFECTIVE_FROM_DATE <= v_UF_DATES.EFFECTIVE_FROM_DATE);

                	IF v_EFFECTIVE_USAGE_FACTOR IS NULL THEN
                		-- If "effective" usage factor is NOT found, query for effective usage factor for period
                		-- and date from METER_TOU_USAGE_FACTOR_PERIOD
                		SELECT MAX(B.FACTOR_VAL)
                		INTO v_EFFECTIVE_USAGE_FACTOR
                		FROM METER_TOU_USAGE_FACTOR A,
                			 METER_TOU_USAGE_FACTOR_PERIOD B
                		WHERE A.TOU_USAGE_FACTOR_ID = B.TOU_USAGE_FACTOR_ID
                		  AND A.METER_ID = v_METER_ID
                		  AND A.CASE_ID = GA.BASE_CASE_ID
                		  AND A.TEMPLATE_ID = v_TEMPLATE_ID
                		  AND B.PERIOD_ID = v_PERIOD_ID
                		  AND A.BEGIN_DATE = (SELECT MAX(X.BEGIN_DATE)
                								   FROM METER_TOU_USAGE_FACTOR X
                								   WHERE X.METER_ID = v_METER_ID
                								   AND X.CASE_ID = GA.BASE_CASE_ID
                								   AND X.TEMPLATE_ID = v_TEMPLATE_ID
                								   AND X.BEGIN_DATE <= v_UF_DATES.EFFECTIVE_FROM_DATE);

                		-- Assume this is not an actual usage factor - don't overwrite anything
                		v_IS_ACTUAL_USAGE_FACTOR := FALSE;
                	END IF;

                	IF v_EFFECTIVE_USAGE_FACTOR IS NOT NULL THEN
                		-- If "effective" usage factor IS found and it is Actual then set "actual usage factor" flag.
                		IF v_UF_DATES.USAGE_FACTOR_TYPE = MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ACTUAL THEN
                			v_IS_ACTUAL_USAGE_FACTOR := TRUE;
                		END IF;

						IF NOT v_USAGE_FACTOR_DETAILS_BY_MTR.EXISTS(v_METER_ID) THEN
							v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_ID) := t_300_USAGE_FACTOR_DETAILS();
						END IF;
                		-- Store period and meter usage factor into structure, compute weighted usage factor value
                		v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_ID).EXTEND();
                		v_IDX := v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_ID).COUNT();
                		v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_ID)(v_IDX).TIMESLOT_CODE := v_TDIE_300_REGISTER.TIMESLOT_CODE;
                		v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_ID)(v_IDX).USAGE_FACTOR_TYPE := v_UF_DATES.USAGE_FACTOR_TYPE;

                		v_KEY := v_UF_DATES.USAGE_FACTOR_TYPE||':'||v_TDIE_300_REGISTER.TIMESLOT_CODE;
                		IF v_TOTAL_CONSUMPTION_MAP(v_KEY).CONSUMPTION <> 0 THEN
                			-- compute weighted usage factor value based on all meters
                			v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_ID)(v_IDX).USAGE_FACTOR := v_EFFECTIVE_USAGE_FACTOR *
                				(v_TDIE_300_REGISTER.CONSUMPTION/v_TOTAL_CONSUMPTION_MAP(v_KEY).CONSUMPTION);
                		ELSE
                			-- evenly allocate usage factor when total consumption is zero to avoid divide-by-zero
                			v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_ID)(v_IDX).USAGE_FACTOR := v_EFFECTIVE_USAGE_FACTOR / v_TOTAL_CONSUMPTION_MAP(v_KEY).METER_COUNT;
                		END IF;

                	END IF;
                END LOOP;
                -- End loop over periods

                IF v_USAGE_FACTOR_DETAILS_BY_MTR.COUNT > 0 THEN -- nothing to do if we identified no timeslot codes in file
                											-- this can happen when a meter has no kwh registers in the file
                	v_METER_IDX := v_USAGE_FACTOR_DETAILS_BY_MTR.FIRST;
                	WHILE v_METER_IDX IS NOT NULL LOOP

    					-- Get the template for this meter, looking at the first timeslot code should work
    					VALIDATE_TIMESLOT_CODE(v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_IDX)(1).TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);

    					-- Reset variable
    					v_CUR_TOU_USAGE_FACTOR_ID := NULL;

    					-- If not "actual usage factor" then query for existing record
    					-- in METER_TOU_USAGE_FACTOR for begin date = current effective date
    					IF NOT v_IS_ACTUAL_USAGE_FACTOR THEN
    						-- Check for an existing usage factor
    						SELECT MAX(A.TOU_USAGE_FACTOR_ID)
    						INTO v_CUR_TOU_USAGE_FACTOR_ID
    						FROM METER_TOU_USAGE_FACTOR A
    						WHERE A.METER_ID = v_METER_IDX
    						  AND A.CASE_ID = GA.BASE_CASE_ID
    						  AND A.BEGIN_DATE = v_UF_DATES.EFFECTIVE_FROM_DATE;
    					END IF;

    					-- Only insert into the usage factor if this is an Actual Usage Factor
    					-- or it is an Estimate and it doesn't already exist.
    					IF v_IS_ACTUAL_USAGE_FACTOR OR v_CUR_TOU_USAGE_FACTOR_ID IS NULL THEN
							-- all meters need to be set this way - so set it just in case it's not
    						UPDATE METER M
    						SET M.USE_TOU_USAGE_FACTOR = 1
    						WHERE M.METER_ID = v_METER_IDX;

							-- get parent ID for period usage factors
							v_CUR_TOU_USAGE_FACTOR_ID := ACCOUNTS_METERS.INSERT_METER_TOU_USAGE_FACTOR(
																TRUNC(v_UF_DATES.EFFECTIVE_FROM_DATE),
																TRUNC(v_END_DATE),
																v_METER_IDX,
																v_TEMPLATE_ID
																);

    						-- Loop over each period in structure
    						FOR v_IDX IN v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_IDX).FIRST..v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_IDX).LAST LOOP
    							VALIDATE_TIMESLOT_CODE(v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_IDX)(v_IDX).TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);
    							INSERT INTO METER_TOU_USAGE_FACTOR_PERIOD
    							   (TOU_USAGE_FACTOR_ID, PERIOD_ID, FACTOR_VAL, ENTRY_DATE)
    							 VALUES
    							   (v_CUR_TOU_USAGE_FACTOR_ID, v_PERIOD_ID, v_USAGE_FACTOR_DETAILS_BY_MTR(v_METER_IDX)(v_IDX).USAGE_FACTOR, SYSDATE);
    						END LOOP; -- End Loop
    					END IF;

	    				v_METER_IDX := v_USAGE_FACTOR_DETAILS_BY_MTR.NEXT(v_METER_IDX);
    				END LOOP; -- End loop over UF Details by Meter

						END IF;

			EXCEPTION
					WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
						IF v_UF_DATES.USAGE_FACTOR_TYPE = MM_TDIE_UTIL.g_USAGE_FACTOR_TYPE_ESTIMATED AND MM_TDIE_UTIL.METER_EXISTS(v_TDIE_MESSAGE.LOCATION_ID, v_SERIAL_NUMBERS(v_SN_IDX)) THEN
							LOGS.LOG_WARN(	p_EVENT_TEXT => 'Serial Number='||v_SERIAL_NUMBERS(v_SN_IDX)||', MPRN='||v_TDIE_MESSAGE.LOCATION_ID||', Date Range='||v_UF_DATES.EFFECTIVE_FROM_DATE||' -> '||NVL(v_END_DATE,v_UF_DATES.EFFECTIVE_FROM_DATE),
											p_MESSAGE_CODE => MSGCODES.c_TDIE_EST_USAGE_FACT_NOT_IMP);
						ELSE
							-- let exception propagate if we were processing an actual usage factor
					        ERRS.RAISE(MSGCODES.c_ERR_MISSING_SERIAL_NUMBER, 'Serial Number not found. SERIAL_NUMBER='||v_SERIAL_NUMBERS(v_SN_IDX)||', MPRN='||v_TDIE_MESSAGE.LOCATION_ID);
						END IF;
			END;

			-- Set local "end date" variable to current effective date minus one day
			v_LAST_FROM_DATE := v_UF_DATES.EFFECTIVE_FROM_DATE;

		END LOOP; -- End loop over effective dates
	END LOOP; -- End loop over meters
END PROCESS_300_ROI_USAGE_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_ACCT_LAST_READ_RCV_DATE
	(
	p_ACCOUNT_ID IN NUMBER,
	p_LAST_READING_RCV_DATE IN DATE
	) AS
	v_COUNT NUMBER;
BEGIN
	SELECT COUNT(1) INTO v_COUNT
	FROM TDIE_ACCOUNT WHERE ACCOUNT_ID = p_ACCOUNT_ID;
	IF v_COUNT > 0 THEN
		UPDATE TDIE_ACCOUNT
		SET LAST_READING_RCV_DATE = GREATEST(p_LAST_READING_RCV_DATE, LAST_READING_RCV_DATE)
		WHERE ACCOUNT_ID = p_ACCOUNT_ID;
	ELSE
		INSERT INTO TDIE_ACCOUNT(ACCOUNT_ID, LAST_READING_RCV_DATE)
		VALUES (p_ACCOUNT_ID, p_LAST_READING_RCV_DATE);
	END IF;

END PUT_ACCT_LAST_READ_RCV_DATE;
----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_300_NORMAL(p_TDIE_ID IN NUMBER) AS

	v_TDIE_MESSAGE 		    TDIE_MESSAGE%ROWTYPE;
	v_ACCOUNT_ID 			ACCOUNT.ACCOUNT_ID%TYPE;
	v_SERVICE_LOCATION_ID 	SERVICE_LOCATION.SERVICE_LOCATION_ID%TYPE;
	v_METER_ID				METER.METER_ID%TYPE;
	v_PERIOD_ID				PERIOD.PERIOD_ID%TYPE;
	v_TEMPLATE_ID			TEMPLATE.TEMPLATE_ID%TYPE;
	v_METER_TYPE			CHAR(1);

	v_LAST_SERIAL_NUMBER 	TDIE_300_REGISTER.SERIAL_NUMBER%TYPE;
	v_LAST_UOM_CODE			TDIE_300_REGISTER.UOM_CODE%TYPE;
	v_LAST_TIMESLOT_CODE	TDIE_300_REGISTER.TIMESLOT_CODE%TYPE;
	v_READ_DATE				DATE;

    v_BEGIN_VALIDATION      DATE;
    v_END_VALIDATION        DATE;

    v_CONSUMPTION_ID        SERVICE_CONSUMPTION.CONSUMPTION_ID%TYPE;

	-- 332 could have multiple reads - actual and estimated for adjacent periods
	-- so we process dates in descending order: first read is previous read date
	-- to message date, next read is its previous read date up to the first read's
	-- previous read date, etc...
	CURSOR c_REGISTERS IS
		SELECT A.LOCATION_ID AS MPRN,
			   A.MESSAGE_DATE AS READ_DATE,
			   B.SERIAL_NUMBER,
		       B.PREVIOUS_READ_DATE,
		       B.UOM_CODE,
		       B.TIMESLOT_CODE,
			   -- instantaneous UOM? use MAX. volumetric UOM? use SUM.
		       CASE WHEN B.UOM_CODE IN ('KWT','KVR','KVA') THEN MAX(B.CONSUMPTION) ELSE SUM(B.CONSUMPTION) END AS CONSUMPTION,
			   MIN(B.READING_VALUE) KEEP (DENSE_RANK FIRST ORDER BY B.REGISTER_TYPE_CODE) AS READING_VALUE,
		       SUM(B.ANNUALISED_ACTUAL_CONSUMPTION) AS ANNUALISED_ACTUAL_CONSUMPTION,
		       SUM(B.ESTIMATED_USAGE_FACTOR) AS ESTIMATED_USAGE_FACTOR,
			   B.REGISTER_NODE_TYPE
		FROM TDIE_MESSAGE A,
			 TDIE_300_REGISTER B
		WHERE A.TDIE_ID = p_TDIE_ID
		  AND A.TDIE_ID = B.TDIE_ID
		  AND (INSTR(A.MESSAGE_TYPE_CODE, 'W') = 0)
		GROUP BY A.LOCATION_ID, A.MESSAGE_DATE, B.SERIAL_NUMBER, B.UOM_CODE, B.TIMESLOT_CODE, B.PREVIOUS_READ_DATE, B.REGISTER_NODE_TYPE
		-- process most recent consumption reads first
		ORDER BY B.SERIAL_NUMBER, B.UOM_CODE, B.TIMESLOT_CODE, B.PREVIOUS_READ_DATE DESC;
BEGIN
	SAVEPOINT PROCESS_300_IMPORT;

	MS.PURGE_CALENDAR_PROFILE_VALUE; -- F6.U24 related

	SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

	VALIDATE_MPRN(p_TDIE_ID,v_ACCOUNT_ID,v_SERVICE_LOCATION_ID);

	IF v_ACCOUNT_ID IS NOT NULL AND v_SERVICE_LOCATION_ID IS NOT NULL THEN

		-- Keep track of the metered accounts
		PUT_ACCT_LAST_READ_RCV_DATE(v_ACCOUNT_ID, v_TDIE_MESSAGE.MARKET_TIMESTAMP);

		VALIDATE_SERIAL_NUM_TEMPLATES(p_TDIE_ID);

		-- Loop over all the Register data in the file and update SERVICE_CONSUMPTION
		FOR v_REGISTER IN c_REGISTERS LOOP

			-- different register than previous row?
			IF v_LAST_SERIAL_NUMBER IS NULL
					OR v_REGISTER.SERIAL_NUMBER <> v_LAST_SERIAL_NUMBER
					OR v_REGISTER.UOM_CODE <> v_LAST_UOM_CODE
					OR v_REGISTER.TIMESLOT_CODE <> v_LAST_TIMESLOT_CODE THEN
				-- reset read date to the message date and process the
				-- records for this row, starting with most recent first
				-- (thanks to cursor ordering)
				v_READ_DATE := v_TDIE_MESSAGE.MESSAGE_DATE;
			END IF;

			-- Only process Consumption for registers that have a REGISTER_NODE_TYPE that is not 'New'.
			-- REGISTER_NODE_TYPE is set during import in the IMPORT_XML_300 procedure.
			-- 'New' register node types are set for:
			--   -the New registers of a 332 message
			--   -all registers of a 320 message
			IF v_REGISTER.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_NEW THEN

                GET_VALIDATION_DATE_RANGE(v_REGISTER.PREVIOUS_READ_DATE,
                                        v_REGISTER.READ_DATE,
                                        v_BEGIN_VALIDATION,
                                        v_END_VALIDATION);

				-- Validate Meter if we haven't already
				VALIDATE_METER(p_TDIE_ID, v_SERVICE_LOCATION_ID,
					v_REGISTER.SERIAL_NUMBER,
					v_BEGIN_VALIDATION,
					v_END_VALIDATION,
					v_REGISTER.TIMESLOT_CODE,
					v_METER_ID);

				-- Validate Time_slot_code
				VALIDATE_TIMESLOT_CODE(v_REGISTER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);

                v_METER_TYPE := CS.GET_METER_TYPE(v_ACCOUNT_ID, v_METER_ID);

                ASSERT(v_REGISTER.UOM_CODE IS NOT NULL AND v_REGISTER.UOM_CODE IN ('KWH','K3','KWT','KVR','KVA'),'Invalid UOM_CODE found: ' || v_REGISTER.UOM_CODE);

                MS.PUT_SERVICE_CONSUMPTION(GA.BASE_SCENARIO_ID,
                                            v_ACCOUNT_ID,
                                            v_SERVICE_LOCATION_ID,
                                            v_METER_ID,
                                            v_REGISTER.PREVIOUS_READ_DATE+1,
                                            NVL(v_READ_DATE, v_TDIE_MESSAGE.MESSAGE_DATE), --bz.26539
                                            GA.BILL_CONSUMPTION,
                                            GA.ACTUAL_CONSUMPTION,
                                            CONSTANTS.LOW_DATE,
                                            v_TEMPLATE_ID,
                                            v_PERIOD_ID,
                                            MM_TDIE_UTIL.CONVERT_UOM_CODE(v_REGISTER.UOM_CODE),
                                            v_METER_TYPE,
                                            NULL,
                                            CASE WHEN v_REGISTER.UOM_CODE IN ('KWH', 'K3') THEN
                                                v_REGISTER.CONSUMPTION
                                            ELSE
                                                NULL
                                            END,
                                            CASE WHEN v_REGISTER.UOM_CODE IN ('KWT','KVR','KVA') THEN
                                              v_REGISTER.CONSUMPTION
                                            ELSE
                                              NULL
                                            END,
                                            CASE WHEN v_REGISTER.UOM_CODE IN ('KWH', 'K3') THEN
                                              v_REGISTER.CONSUMPTION
                                            ELSE
                                              NULL
                                            END,
                                            CASE WHEN v_REGISTER.UOM_CODE IN ('KWT','KVR','KVA') THEN
                                              v_REGISTER.CONSUMPTION
                                            ELSE
                                              NULL
                                            END,
                                            NULL,
                                            NULL,
                                            0,
                                            NULL,
                                            NULL,
                                            v_REGISTER.PREVIOUS_READ_DATE+1,
                                            v_READ_DATE,
                                            v_CONSUMPTION_ID,
                                            FALSE);
 			END IF;

			v_LAST_SERIAL_NUMBER := v_REGISTER.SERIAL_NUMBER;
			v_LAST_UOM_CODE := v_REGISTER.UOM_CODE;
			v_LAST_TIMESLOT_CODE := v_REGISTER.TIMESLOT_CODE;
			-- if same register, next row in cursor, is previous read
			v_READ_DATE := v_REGISTER.PREVIOUS_READ_DATE;
		END LOOP;

        IF v_TDIE_MESSAGE.MESSAGE_TYPE_CODE <> '305' THEN
            IF SUBSTR(v_TDIE_MESSAGE.MESSAGE_TYPE_CODE,1,1) = 'N' THEN
                PROCESS_300_NIE_USAGE_FACTOR(p_TDIE_ID);
            ELSE
                PROCESS_300_ROI_USAGE_FACTOR(p_TDIE_ID);
            END IF;
        END IF;

	END IF;

EXCEPTION
		WHEN MSGCODES.e_ERR_MISSING_MPRN OR
			 MSGCODES.e_ERR_MISSING_NQH_STATIC_DATA OR
			 MSGCODES.e_ERR_MISSING_SERIAL_NUMBER THEN

			ERRS.ROLLBACK_TO(p_SAVEPOINT_NAME => 'PROCESS_300_IMPORT');
			PUT_TDIE_300_EXCEPTION(p_TDIE_ID, SQLCODE, SQLERRM);
END PROCESS_300_NORMAL;
----------------------------------------------------------------------------------------------------
FUNCTION GET_WITHDRAWN_CASE_ID RETURN NUMBER AS
v_ID NUMBER(9);
BEGIN
	BEGIN
		v_ID := EI.GET_ID_FROM_ALIAS('Withdrawn',EC.ED_CASE_LABEL);
	EXCEPTION
		WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
			IO.PUT_CASE_LABEL(v_ID,'Withdrawn','Withdrawn','Generated by MM_TDIE_IMPORTS.',0,NULL);
	END;
	RETURN v_ID;
END GET_WITHDRAWN_CASE_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE WITHDRAW_300_ROI_USAGE_FACTOR(p_TDIE_ID IN NUMBER) AS
	v_PERIOD_ID						PERIOD.PERIOD_ID%TYPE;
	v_TEMPLATE_ID					TEMPLATE.TEMPLATE_ID%TYPE;
	v_TOU_USAGE_FACTOR_ID   	    METER_TOU_USAGE_FACTOR.TOU_USAGE_FACTOR_ID%TYPE;
	v_TDIE_MESSAGE 					TDIE_MESSAGE%ROWTYPE;
	v_WITHDRAWN_CASE_ID 			NUMBER(9) := GET_WITHDRAWN_CASE_ID();

BEGIN
	-- Get the original message to determine if this is 300,305,306,307,310,320,or 332
	SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

	-- Loop over each meter in the file
	FOR v_METER IN (SELECT R.SERIAL_NUMBER,
						   MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, R.SERIAL_NUMBER, R.PREVIOUS_READ_DATE + 1,  v_TDIE_MESSAGE.MESSAGE_DATE, R.TIMESLOT_CODE) AS METER_ID,
						   MIN(R.TIMESLOT_CODE) AS TIMESLOT_CODE
					 FROM TDIE_300_REGISTER R
					 WHERE R.TDIE_ID = p_TDIE_ID
					   AND R.UOM_CODE = 'KWH'
					   AND R.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_NEW
				     GROUP BY R.SERIAL_NUMBER, MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, R.SERIAL_NUMBER, R.PREVIOUS_READ_DATE + 1,  v_TDIE_MESSAGE.MESSAGE_DATE, R.TIMESLOT_CODE)) LOOP

		-- Determine which TOU Template this
		VALIDATE_TIMESLOT_CODE(v_METER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);

		-- Loop over all distinct usage factor effective dates in descending order
		FOR v_UF_DATES IN (SELECT DISTINCT A.EFFECTIVE_FROM_DATE AS EFFECTIVE_FROM_DATE
						   FROM TDIE_300_USAGE_FACTOR A
						   WHERE A.TDIE_ID = p_TDIE_ID
						     AND A.USAGE_FACTOR_TYPE = 'A' -- PBM - Per discussion during T-Spec, Only withdraw Actuals
						   ORDER BY 1 DESC) LOOP

	        SELECT MAX(A.TOU_USAGE_FACTOR_ID)
			INTO v_TOU_USAGE_FACTOR_ID
			FROM METER_TOU_USAGE_FACTOR A
			WHERE A.METER_ID = v_METER.METER_ID
			  AND A.CASE_ID = GA.BASE_CASE_ID
			  AND A.TEMPLATE_ID = v_TEMPLATE_ID
			  AND A.BEGIN_DATE = v_UF_DATES.EFFECTIVE_FROM_DATE;

			IF v_TOU_USAGE_FACTOR_ID IS NOT NULL THEN
				-- Delete any existing Withdrawn Case
				DELETE FROM METER_TOU_USAGE_FACTOR A
				WHERE A.METER_ID = v_METER.METER_ID
				  AND A.CASE_ID = v_WITHDRAWN_CASE_ID
				  AND A.TEMPLATE_ID = v_TEMPLATE_ID
				  AND A.BEGIN_DATE = v_UF_DATES.EFFECTIVE_FROM_DATE;

				UPDATE METER_TOU_USAGE_FACTOR A
				SET A.CASE_ID = v_WITHDRAWN_CASE_ID
				WHERE A.TOU_USAGE_FACTOR_ID = v_TOU_USAGE_FACTOR_ID;

			END IF;

		END LOOP;
		-- End loop over effective dates

		UT.ALIGN_DATE_RANGES('METER_TOU_USAGE_FACTOR',
					'CASE_ID',
					UT.GET_LITERAL_FOR_NUMBER(GA.BASE_CASE_ID),
					'METER_ID',
					UT.GET_LITERAL_FOR_NUMBER(v_METER.METER_ID));
	END LOOP;
	-- End loop over meters
END WITHDRAW_300_ROI_USAGE_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE WITHDRAW_300_NIE_USAGE_FACTOR(p_TDIE_ID IN NUMBER) AS
	v_PERIOD_ID						PERIOD.PERIOD_ID%TYPE;
	v_TEMPLATE_ID					TEMPLATE.TEMPLATE_ID%TYPE;
	v_TOU_USAGE_FACTOR_ID   	    METER_TOU_USAGE_FACTOR.TOU_USAGE_FACTOR_ID%TYPE;
	v_TDIE_MESSAGE 					TDIE_MESSAGE%ROWTYPE;
	v_WITHDRAWN_CASE_ID 			NUMBER(9) := GET_WITHDRAWN_CASE_ID();
BEGIN
	-- Get the original message to determine if this is 300,320,or 332
	SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

	-- Loop over each meter in the file
	FOR v_METER IN (SELECT R.SERIAL_NUMBER,
						   MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, R.SERIAL_NUMBER, v_TDIE_MESSAGE.MESSAGE_DATE,  v_TDIE_MESSAGE.MESSAGE_DATE, R.TIMESLOT_CODE) AS METER_ID,
						   MIN(R.TIMESLOT_CODE) AS TIMESLOT_CODE
					 FROM TDIE_300_REGISTER R
					 WHERE R.TDIE_ID = p_TDIE_ID
					   AND R.UOM_CODE = 'KWH'
					   AND R.REGISTER_NODE_TYPE <> c_REGISTER_NODE_TYPE_NEW
				     GROUP BY R.SERIAL_NUMBER, MM_TDIE_UTIL.GET_METER_ID(v_TDIE_MESSAGE.LOCATION_ID, R.SERIAL_NUMBER, v_TDIE_MESSAGE.MESSAGE_DATE,  v_TDIE_MESSAGE.MESSAGE_DATE, R.TIMESLOT_CODE)) LOOP

		-- Determine which TOU Template this
		VALIDATE_TIMESLOT_CODE(v_METER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);

		SELECT MAX(A.TOU_USAGE_FACTOR_ID)
		INTO v_TOU_USAGE_FACTOR_ID
		FROM METER_TOU_USAGE_FACTOR A
		WHERE A.METER_ID = v_METER.METER_ID
		  AND A.CASE_ID = GA.BASE_CASE_ID
		  AND A.TEMPLATE_ID = v_TEMPLATE_ID
		  AND A.END_DATE = v_TDIE_MESSAGE.MESSAGE_DATE;

		IF v_TOU_USAGE_FACTOR_ID IS NOT NULL THEN
			-- Delete any existing Withdrawn Case
			DELETE FROM METER_TOU_USAGE_FACTOR A
			WHERE A.METER_ID = v_METER.METER_ID
			  AND A.CASE_ID = v_WITHDRAWN_CASE_ID
			  AND A.TEMPLATE_ID = v_TEMPLATE_ID
			  AND A.END_DATE = v_TDIE_MESSAGE.MESSAGE_DATE;

			UPDATE METER_TOU_USAGE_FACTOR A
			SET A.CASE_ID = v_WITHDRAWN_CASE_ID
			WHERE A.TOU_USAGE_FACTOR_ID = v_TOU_USAGE_FACTOR_ID;

		END IF;

		UT.ALIGN_DATE_RANGES('METER_TOU_USAGE_FACTOR',
					'CASE_ID',
					UT.GET_LITERAL_FOR_NUMBER(GA.BASE_CASE_ID),
					'METER_ID',
					UT.GET_LITERAL_FOR_NUMBER(v_METER.METER_ID));
	END LOOP;
	-- End loop over meters
END WITHDRAW_300_NIE_USAGE_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE WITHDRAW_USAGE_FACTOR
	(
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE
	) AS
v_TOU_USAGE_FACTOR_ID METER_TOU_USAGE_FACTOR.TOU_USAGE_FACTOR_ID%TYPE;
v_WITHDRAWN_CASE_ID NUMBER(9) := GET_WITHDRAWN_CASE_ID();
BEGIN

	SELECT MAX(A.TOU_USAGE_FACTOR_ID)
	INTO v_TOU_USAGE_FACTOR_ID
	FROM METER_TOU_USAGE_FACTOR A
	WHERE A.METER_ID = p_METER_ID
	  AND A.CASE_ID = GA.BASE_CASE_ID
	  AND A.BEGIN_DATE = TRUNC(p_BEGIN_DATE);

	IF v_TOU_USAGE_FACTOR_ID IS NOT NULL THEN
		-- Delete any existing Withdrawn Case
		DELETE FROM METER_TOU_USAGE_FACTOR A
		WHERE A.METER_ID = p_METER_ID
		  AND A.CASE_ID = v_WITHDRAWN_CASE_ID
		  AND A.BEGIN_DATE = TRUNC(p_BEGIN_DATE);

		UPDATE METER_TOU_USAGE_FACTOR A
		SET A.CASE_ID = v_WITHDRAWN_CASE_ID
		WHERE A.TOU_USAGE_FACTOR_ID = v_TOU_USAGE_FACTOR_ID;

		UT.ALIGN_DATE_RANGES('METER_TOU_USAGE_FACTOR',
			'CASE_ID',
			UT.GET_LITERAL_FOR_NUMBER(GA.BASE_CASE_ID),
			'METER_ID',
			UT.GET_LITERAL_FOR_NUMBER(p_METER_ID));

	ELSE
		LOGS.LOG_WARN('Could not find a matching METER_TOU_USAGE_FACTOR to withdraw');
	END IF;

END WITHDRAW_USAGE_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_300_WITHDRAWAL(P_TDIE_ID IN NUMBER) AS
	v_TEMP					NUMBER(9);
	v_TDIE_300_MESSAGE 	    TDIE_MESSAGE%ROWTYPE;
	v_TDIE_300_MPRN 		TDIE_300_MPRN%ROWTYPE;
	v_ACCOUNT_ID 			ACCOUNT.ACCOUNT_ID%TYPE;
	v_SERVICE_LOCATION_ID 	SERVICE_LOCATION.SERVICE_LOCATION_ID%TYPE;
	v_METER_ID				METER.METER_ID%TYPE;
	v_SERVICE_ID			SERVICE.SERVICE_ID%TYPE;
	v_PERIOD_ID				PERIOD.PERIOD_ID%TYPE;
	v_TEMPLATE_ID			TEMPLATE.TEMPLATE_ID%TYPE;
	v_ORIG_MSG_TYPE_CODE	VARCHAR2(64);
	v_TYPE_CODES			STRING_COLLECTION;

    v_BEGIN_VALIDATION      DATE;
    v_END_VALIDATION        DATE;

	v_JURISDICTION          VARCHAR2(4);

	CURSOR c_REGISTERS (p_CUR_TDIE_ID IN NUMBER) IS
		SELECT A.TDIE_ID,
		       A.LOCATION_ID AS MPRN,
			   A.MESSAGE_DATE AS READ_DATE,
			   B.SERIAL_NUMBER,
		       MIN(B.PREVIOUS_READ_DATE) AS PREVIOUS_READ_DATE,
		       B.UOM_CODE,
		       B.TIMESLOT_CODE
		FROM TDIE_MESSAGE A,
			 TDIE_300_REGISTER B
		WHERE A.TDIE_ID = p_CUR_TDIE_ID
		  AND A.TDIE_ID = B.TDIE_ID
          AND B.REGISTER_TYPE_CODE <> c_REGISTER_NODE_TYPE_NEW
		GROUP BY A.TDIE_ID,
		       	 A.LOCATION_ID,
				 A.MESSAGE_DATE,
				 B.SERIAL_NUMBER,
				 B.UOM_CODE,
		       	 B.TIMESLOT_CODE;
BEGIN
	SAVEPOINT PROCESS_300W_IMPORT;

	SELECT * INTO v_TDIE_300_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;
	SELECT * INTO v_TDIE_300_MPRN FROM TDIE_300_MPRN T WHERE T.TDIE_ID = P_TDIE_ID;

	v_JURISDICTION := GET_JURISDICTION_FOR_IMPORTS(v_TDIE_300_MESSAGE.RECIPIENT_ID);

    -- If it is an ROI message try to find a matching 300 message for this file
	IF SUBSTR(v_TDIE_300_MESSAGE.MESSAGE_TYPE_CODE, 1,1) <> 'N'
	        AND v_TDIE_300_MPRN.NETWORKS_REFERENCE_NUMBER IS NOT NULL THEN

		-- Get the correct MESSAGE_TYPE_CODE to withdraw
		IF v_TDIE_300_MESSAGE.MESSAGE_TYPE_CODE = '300W' THEN
			v_ORIG_MSG_TYPE_CODE := '300, 300S, or 305';
			v_TYPE_CODES := STRING_COLLECTION('300', '300S', '305');
		ELSE
			v_ORIG_MSG_TYPE_CODE := SUBSTR(v_TDIE_300_MESSAGE.MESSAGE_TYPE_CODE, 1, 3);
			v_TYPE_CODES := STRING_COLLECTION(v_ORIG_MSG_TYPE_CODE);
		END IF;

		BEGIN
            SELECT T.*
			INTO v_TDIE_300_MESSAGE
			FROM TDIE_MESSAGE T,
				 TDIE_300_MPRN M
			WHERE T.TDIE_ID = M.TDIE_ID
			  AND T.LOCATION_ID = v_TDIE_300_MESSAGE.LOCATION_ID
			  AND T.MESSAGE_TYPE_CODE IN (SELECT X.COLUMN_VALUE FROM TABLE (CAST (v_TYPE_CODES AS STRING_COLLECTION)) X)
			  AND M.NETWORKS_REFERENCE_NUMBER = v_TDIE_300_MPRN.NETWORKS_REFERENCE_NUMBER;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- Could not find a message to withdraw
                -- If this is a new ES NI message, we could be trying to withdraw and old message, revert to the old logic
                IF v_JURISDICTION = MM_TDIE_UTIL.c_TDIE_JURISDICTION_NI THEN
                    -- Set the MESSAGE_TYPE_CODE to 'N*' so that the remaining logic will treat this like the old NI withdrawals
                    v_TDIE_300_MESSAGE.MESSAGE_TYPE_CODE := 'N' || v_TDIE_300_MESSAGE.MESSAGE_TYPE_CODE;
                ELSE
					-- This is the old ROI logic
                    PUT_TDIE_300_EXCEPTION(p_TDIE_ID,MSGCODES.c_ERR_NO_SUCH_ENTRY,'No matching ' || v_ORIG_MSG_TYPE_CODE || ' message for NETWORKS_REFERENCE_NUMBER='
                        || v_TDIE_300_MPRN.NETWORKS_REFERENCE_NUMBER);
                    RETURN;
                END IF;
			WHEN TOO_MANY_ROWS THEN
				PUT_TDIE_300_EXCEPTION(p_TDIE_ID,MSGCODES.c_ERR_TOO_MANY_ENTRIES,'More than one matching ' || v_ORIG_MSG_TYPE_CODE || ' message was found for NETWORKS_REFERENCE_NUMBER='
					|| v_TDIE_300_MPRN.NETWORKS_REFERENCE_NUMBER);
				RETURN;
		END;

		-- Check to see if the message that we are withdrawing has an exception, if so log an error and exit
		SELECT MAX(T.TDIE_ID)
		INTO v_TEMP
		FROM TDIE_300_EXCEPTION T
		WHERE T.TDIE_ID = v_TDIE_300_MESSAGE.TDIE_ID;

		IF v_TEMP IS NOT NULL THEN
			LOGS.LOG_ERROR('Matching ' || v_ORIG_MSG_TYPE_CODE || ' message contains an error in TDIE_300_EXCEPTION for NETWORKS_REFERENCE_NUMBER='
					|| v_TDIE_300_MPRN.NETWORKS_REFERENCE_NUMBER);
				RETURN;
		END IF;
	END IF;

	-- Validate Account and Service Location
	GET_MPRN(v_TDIE_300_MESSAGE.TDIE_ID,v_ACCOUNT_ID,v_SERVICE_LOCATION_ID);

	FOR v_REGISTER IN c_REGISTERS(v_TDIE_300_MESSAGE.TDIE_ID) LOOP

        GET_VALIDATION_DATE_RANGE(v_REGISTER.PREVIOUS_READ_DATE,
                                    v_REGISTER.READ_DATE,
                                    v_BEGIN_VALIDATION,
                                    v_END_VALIDATION);

		-- Validate Meter
        v_METER_ID := GET_METER_ID(v_SERVICE_LOCATION_ID,
                    v_REGISTER.SERIAL_NUMBER,
                    v_REGISTER.TIMESLOT_CODE,
                    v_BEGIN_VALIDATION,
                    v_END_VALIDATION);

        -- Validate Time_slot_code
		VALIDATE_TIMESLOT_CODE(v_REGISTER.TIMESLOT_CODE,v_PERIOD_ID,v_TEMPLATE_ID);
		-- Get Service Id
		v_SERVICE_ID := GET_SERVICE_ID(v_ACCOUNT_ID,v_SERVICE_LOCATION_ID,v_METER_ID,v_TDIE_300_MESSAGE.MESSAGE_DATE);

		IF v_SERVICE_ID IS NOT NULL THEN
			UPDATE SERVICE_CONSUMPTION
			SET IGNORE_CONSUMPTION = 1
			WHERE SERVICE_ID = v_SERVICE_ID
			  AND (v_REGISTER.PREVIOUS_READ_DATE IS NULL OR BEGIN_DATE = v_REGISTER.PREVIOUS_READ_DATE+1)
			  AND END_DATE = v_TDIE_300_MESSAGE.MESSAGE_DATE
			  AND BILL_CODE = GA.BILL_CONSUMPTION
			  AND CONSUMPTION_CODE = GA.ACTUAL_CONSUMPTION
			  AND RECEIVED_DATE = CONSTANTS.LOW_DATE
			  AND TEMPLATE_ID = v_TEMPLATE_ID
			  AND PERIOD_ID = v_PERIOD_ID
			  AND UNIT_OF_MEASUREMENT = MM_TDIE_UTIL.CONVERT_UOM_CODE(v_REGISTER.UOM_CODE);
		ELSE
			ERRS.RAISE(MSGCODES.c_ERR_MISSING_SERIAL_NUMBER, 'SERVICE_ID not found. SERIAL_NUMBER=' || v_REGISTER.SERIAL_NUMBER
				|| 'READ_DATE=' || v_TDIE_300_MESSAGE.MESSAGE_DATE);
		END IF;
	END LOOP;

	IF v_TDIE_300_MESSAGE.MESSAGE_TYPE_CODE IN ('300','300S','305','306','307','310','320','332') THEN
        WITHDRAW_300_ROI_USAGE_FACTOR(v_TDIE_300_MESSAGE.TDIE_ID);
	ELSIF SUBSTR(v_TDIE_300_MESSAGE.MESSAGE_TYPE_CODE, 1,1) = 'N' THEN
        WITHDRAW_300_NIE_USAGE_FACTOR(p_TDIE_ID);
	END IF;

EXCEPTION
		WHEN MSGCODES.e_ERR_MISSING_MPRN OR
			 MSGCODES.e_ERR_MISSING_NQH_STATIC_DATA OR
			 MSGCODES.e_ERR_MISSING_SERIAL_NUMBER THEN
			ERRS.ROLLBACK_TO(p_SAVEPOINT_NAME => 'PROCESS_300W_IMPORT');
			PUT_TDIE_300_EXCEPTION(p_TDIE_ID, SQLCODE, SQLERRM);
END PROCESS_300_WITHDRAWAL;
----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_300(p_TDIE_ID IN NUMBER) AS
	v_TDIE_MESSAGE TDIE_MESSAGE%ROWTYPE;
BEGIN
	-- clear out old exception first
	DELETE TDIE_300_EXCEPTION WHERE TDIE_ID = p_TDIE_ID;

	SELECT * INTO v_TDIE_MESSAGE FROM TDIE_MESSAGE T WHERE T.TDIE_ID = p_TDIE_ID;

	-- Process the raw data
	IF SUBSTR(v_TDIE_MESSAGE.MESSAGE_TYPE_CODE, -1, 1) = 'W' THEN
		PROCESS_300_WITHDRAWAL(p_TDIE_ID);
    ELSE
		PROCESS_300_NORMAL(p_TDIE_ID);
	END IF;
END PROCESS_300;
--------------------------------------------------------------------------------
-- This procedure will be responsible for processing all the 341, 342, and N341
-- XML messages.
PROCEDURE IMPORT_XML_34X
   (
   p_MESSAGE_HEADER  IN t_MESSAGE_HEADER,
   p_IMPORT_FILE     IN CLOB,
   p_PROCESS_IMPORT  IN NUMBER
   ) IS
   c_MIM341                      CONSTANT VARCHAR2(100):= '/descendant::*[self::MIM341_QHMeterDailyReadings or self::MIM341_ImportQHMeterDailyReadings]/*';
   c_NIESMIM341					 CONSTANT VARCHAR2(100):= 'MIM341_ImportIntervalMeterDailyReadings';
   c_MIM342                      CONSTANT VARCHAR2(50) := 'MIM342_ExportQHMeterDailyReadings';
   c_NIESMIM342					 CONSTANT VARCHAR2(100):= 'MIM342_ExportIntervalMeterDailyReadings';
   c_N341                        CONSTANT VARCHAR2(50) := 'NIE341_HHMeterReadings';
   v_XML_MESSAGE                          XMLTYPE;
   v_XML_ELEMENT_NAME                     VARCHAR2(100);
   v_TDIE_34X_MPRN_REC                    TDIE_34X_MPRN%ROWTYPE;
   v_TDIE_34X_MPRN_CHANNEL_REC            TDIE_34X_MPRN_CHANNEL%ROWTYPE;
   v_TDIE_34X_INTERVAL_REC                TDIE_34X_INTERVAL%ROWTYPE;
   v_INTERVAL_PERIOD_TIMESTAMP 		 	  DATE;
   v_ADD_AN_HOUR						BOOLEAN := FALSE;
   v_IS_NI_HARMONISATION_VERSION		  NUMBER(1);
   -----------------------------------------------------------------------------
   -- This cursor is used to process the 34X MPRN Messages.
   CURSOR c_34X_MPRN(
      p_XML_MESSAGE IN XMLTYPE,
      p_XML_ELEMENT IN VARCHAR2
      ) IS
   SELECT EXTRACTVALUE(VALUE(MPRN), '//@MPRN')                AS MPRN,
          TO_DATE(EXTRACTVALUE(VALUE(MPRN), '//@ReadDate'), g_XML_DATE_FORMAT)  AS READ_DATE,
          p_MESSAGE_HEADER.MESSAGE_TYPE_CODE                  AS MESSAGE_TYPE_CODE,
          p_MESSAGE_HEADER.MARKET_TIMESTAMP                   AS MARKET_TIMESTAMP,
          p_MESSAGE_HEADER.TX_REF_NUMBER                      AS TX_REF_NUMBER,
          TDIE_ID.NEXTVAL                                     AS TDIE_MPRN_MSG_ID,
          p_MESSAGE_HEADER.RECIPIENT_ID                       AS RECIPIENT_CID,
          p_MESSAGE_HEADER.SENDER_ID                          AS SENDER_CID,
          p_MESSAGE_HEADER.SUPPLIER_ID                        AS SUPPLIER_MPID,
          p_MESSAGE_HEADER.VERSION_NUMBER                     AS VERSION_NUMBER,
		  EXTRACTVALUE(VALUE(MPRN), '//@GeneratorMPID') 		AS GENERATOR_MPID,
		  EXTRACTVALUE(VALUE(MPRN), '//@GenerationUnitID') 		AS GENERATOR_UNITID,
		  EXTRACTVALUE(VALUE(MPRN), '//@TransformerLossFactor') AS TRANSFORMER_LOSS_FACTOR,
		  EXTRACTVALUE(VALUE(MPRN), '//@AlertFlag') 			AS ALERT_FLAG,
		  EXTRACTVALUE(VALUE(MPRN), '//@ReadingReplacementVersionNumber') 	AS READING_REPLACEMENT_VER_NUM,
         (EXTRACT(VALUE(MPRN), './*'))                        AS o_CHANNEL_XML
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, '/descendant::*[self::ieXMLDocument or self::niXMLDocument]/'||p_XML_ELEMENT)))  MSG,
          TABLE(XMLSEQUENCE(EXTRACT(VALUE(MSG), '//MPRNLevelInfo')))  MPRN;

   -----------------------------------------------------------------------------
   -- This cursor is used to process the channel information for the message elements.
   CURSOR c_34X_CHANNEL(
      p_XML_MESSAGE IN XMLTYPE,
      p_MPRN        IN TDIE_34X_MPRN%ROWTYPE
      ) IS
   SELECT TDIE_ID.NEXTVAL                                             AS TDIE_MPRN_CHANNEL_ID,
          p_MPRN.TDIE_MPRN_MSG_ID                                     AS TDIE_MPRN_MSG_ID,
          (CASE WHEN SUBSTR(p_MESSAGE_HEADER.MESSAGE_TYPE_CODE,1,1) = 'N' THEN
                NULL -- not present here
             ELSE
                EXTRACTVALUE(VALUE(MSG), '//@MeterCategoryCode')
           END)                                                       AS METER_CATEGORY_CODE,
          (CASE WHEN SUBSTR(p_MESSAGE_HEADER.MESSAGE_TYPE_CODE,1,1) = 'N' THEN
                p_MPRN.MPRN -- not present here - use MPRN
             ELSE
                EXTRACTVALUE(VALUE(MSG), '//@SerialNumber')
           END)                                                       AS SERIAL_NUMBER,
          TO_NUMBER(EXTRACTVALUE(VALUE(CHNL), '//@MeteringInterval')) AS METERING_INTERVAL,
          (CASE WHEN SUBSTR(p_MESSAGE_HEADER.MESSAGE_TYPE_CODE,1,1) = 'N' THEN
                EXTRACTVALUE(VALUE(CHNL), '//@RegisterTypeCodeGrpA')
             ELSE
                EXTRACTVALUE(VALUE(CHNL), '//@RegisterTypeCode')
           END)                                                       AS REGISTER_TYPE_CODE,
          EXTRACTVALUE(VALUE(CHNL), '//@UOM_Code')                    AS UOM_CODE,
          (EXTRACT(VALUE(CHNL), './*'))                               AS o_INTERVAL_XML
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, '//MPRNLevelInfo/MeterID')))  MSG,
          TABLE(XMLSEQUENCE(EXTRACT(VALUE(MSG), '//ChannelInfo'))) CHNL;

   -----------------------------------------------------------------------------
   -- This cursor is used to process the interval information for the channel elements.
   CURSOR c_34X_INTERVAL(
      p_XML_MESSAGE IN XMLTYPE,
	  p_METERING_INTERVAL IN NUMBER
      ) IS
   SELECT (DATE_UTIL.TO_DATE_FROM_ISO(EXTRACTVALUE(VALUE(MSG), '//@IntervalPeriodTimestamp'), 'GMT')
   			+ (p_METERING_INTERVAL/1440)) AS INTERVAL_PERIOD_TIMESTAMP,
          -----------------------------------------
          (CASE
              WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('341','342') THEN
			  	   CASE v_IS_NI_HARMONISATION_VERSION
				   		WHEN 1 THEN EXTRACTVALUE(VALUE(MSG), '//@IntervalStatusCode')
						ELSE EXTRACTVALUE(VALUE(MSG), '//@QHIntervalStatusCode')
						END
              WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N341' THEN
                 EXTRACTVALUE(VALUE(MSG), '//@HHIntervalStatusCode')
              ELSE
                 NULL
          END) AS INTERVAL_STATUS_CODE,
          -----------------------------------------
         (CASE
              WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE IN ('341','342') THEN
			  	   CASE v_IS_NI_HARMONISATION_VERSION
				   	   WHEN 1 THEN TO_NUMBER(EXTRACTVALUE(VALUE(MSG), '//@IntervalValue'))
					   ELSE TO_NUMBER(EXTRACTVALUE(VALUE(MSG), '//@QHIntervalValue'))
					   END
              WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N341' THEN
                 TO_NUMBER(EXTRACTVALUE(VALUE(MSG), '//@HHIntervalValue'))
              ELSE
                 NULL
          END) AS INTERVAL_VALUE,
		  TO_NUMBER(EXTRACTVALUE(VALUE(MSG), '//@NetActiveDemandValue')) AS NET_ACTIVE_DEMAND_VALUE
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_MESSAGE, '//ChannelInfo/IntervalInfo')))  MSG;

BEGIN
   -- Assuming if the market timestamp attribute of the message header record
   -- is NULL then the entire record is NULL.
   ASSERT(p_MESSAGE_HEADER.MARKET_TIMESTAMP IS NOT NULL, 'The message header must not be null.', MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);

   v_IS_NI_HARMONISATION_VERSION := IS_NI_HARMONISATION_VERSION(p_MESSAGE_HEADER.VERSION_NUMBER);

   v_XML_ELEMENT_NAME := CASE
                            WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = '341' THEN
								 CASE v_IS_NI_HARMONISATION_VERSION
                               		 WHEN 1 THEN c_NIESMIM341
							   		 ELSE c_MIM341
									 END
                            WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = '342' THEN
								 CASE v_IS_NI_HARMONISATION_VERSION
                               		 WHEN 1 THEN c_NIESMIM342
							   		 ELSE c_MIM342
									 END
                            WHEN p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N341' THEN
                               c_N341
                            ELSE
                               NULL
                         END;--CASE p_MESSAGE_HEADER.MESSAGE_TYPE_CODE

   v_XML_MESSAGE := PARSE_UTIL.CREATE_XML_SAFE(p_IMPORT_FILE);

   -----------------------------------------------------------------------------
   -- Assign values to TDIE_34X_MPRN record type.
   -- Insert the all the records into the table.
   v_TDIE_34X_MPRN_REC := NULL;
   FOR M IN c_34X_MPRN (v_XML_MESSAGE,
                        v_XML_ELEMENT_NAME) LOOP

      v_TDIE_34X_MPRN_REC.TDIE_MPRN_MSG_ID  := M.TDIE_MPRN_MSG_ID;
      v_TDIE_34X_MPRN_REC.MPRN              := M.MPRN;
      v_TDIE_34X_MPRN_REC.READ_DATE         := M.READ_DATE;
      v_TDIE_34X_MPRN_REC.MARKET_TIMESTAMP  := M.MARKET_TIMESTAMP;
      v_TDIE_34X_MPRN_REC.MESSAGE_TYPE_CODE := M.MESSAGE_TYPE_CODE;
      v_TDIE_34X_MPRN_REC.TX_REF_NUMBER     := M.TX_REF_NUMBER;
      v_TDIE_34X_MPRN_REC.RECIPIENT_CID     := M.RECIPIENT_CID;
      v_TDIE_34X_MPRN_REC.SENDER_CID        := M.SENDER_CID;
      v_TDIE_34X_MPRN_REC.SUPPLIER_MPID     := M.SUPPLIER_MPID;
      v_TDIE_34X_MPRN_REC.VERSION_NUMBER    := M.VERSION_NUMBER;
      v_TDIE_34X_MPRN_REC.GENERATOR_MPID    			:= M.GENERATOR_MPID;
      v_TDIE_34X_MPRN_REC.GENERATOR_UNITID				:= M.GENERATOR_UNITID;
      v_TDIE_34X_MPRN_REC.TRANSFORMER_LOSS_FACTOR		:= M.TRANSFORMER_LOSS_FACTOR;
      v_TDIE_34X_MPRN_REC.ALERT_FLAG    				:= M.ALERT_FLAG;
      v_TDIE_34X_MPRN_REC.READING_REPLACEMENT_VER_NUM	:= M.READING_REPLACEMENT_VER_NUM;
      v_TDIE_34X_MPRN_REC.PROCESS_ID        := LOGS.CURRENT_PROCESS_ID;

      -- The data model supports a cascade delete for the 34x Messages.
      -- This will ensure if the exact same file is processed more than once
      -- that the existing data will be overwritten by the incomming data.
      DEL_TDIE_34X_MPRN(v_TDIE_34X_MPRN_REC);

      INS_TDIE_34X_MPRN(v_TDIE_34X_MPRN_REC);

      --------------------------------------------------------------------------
      -- Process all the CHANNEL records associated with each MPRN record.
      v_TDIE_34X_MPRN_CHANNEL_REC := NULL;
      FOR C IN c_34X_CHANNEL (M.o_CHANNEL_XML,
                              v_TDIE_34X_MPRN_REC) LOOP

         v_TDIE_34X_MPRN_CHANNEL_REC.TDIE_MPRN_CHANNEL_ID := C.TDIE_MPRN_CHANNEL_ID;
         v_TDIE_34X_MPRN_CHANNEL_REC.TDIE_MPRN_MSG_ID     := C.TDIE_MPRN_MSG_ID;
         v_TDIE_34X_MPRN_CHANNEL_REC.METER_CATEGORY_CODE  := C.METER_CATEGORY_CODE;
         v_TDIE_34X_MPRN_CHANNEL_REC.SERIAL_NUMBER        := C.SERIAL_NUMBER;
         v_TDIE_34X_MPRN_CHANNEL_REC.METERING_INTERVAL    := C.METERING_INTERVAL;
         v_TDIE_34X_MPRN_CHANNEL_REC.REGISTER_TYPE_CODE   := C.REGISTER_TYPE_CODE;
         v_TDIE_34X_MPRN_CHANNEL_REC.UOM_CODE             := C.UOM_CODE;

         INS_TDIE_34X_MPRN_CHANNEL(v_TDIE_34X_MPRN_CHANNEL_REC);

         --------------------------------------------------------------------------
         -- Process all the INTERVAL records associated with each CHANNEL record.
         v_TDIE_34X_INTERVAL_REC := NULL;
         FOR I IN c_34X_INTERVAL (C.o_INTERVAL_XML, v_TDIE_34X_MPRN_CHANNEL_REC.METERING_INTERVAL) LOOP

		 	-- If message type code is 341 or 342
		   v_INTERVAL_PERIOD_TIMESTAMP := I.INTERVAL_PERIOD_TIMESTAMP;

           -- jbc, 1-jun-2012: fix for bz 30502 (bad assumption that N34x ES files would keep
		   -- doing the same bogus Z-based timestamp)
           IF p_MESSAGE_HEADER.MESSAGE_TYPE_CODE = 'N341' THEN

		   		-- The N341 comes in at local time, so we have to get the CUT time from that
			   	v_INTERVAL_PERIOD_TIMESTAMP := TO_CUT(v_INTERVAL_PERIOD_TIMESTAMP,  MM_SEM_UTIL.g_TZ);

				-- Add an hour if we are in the transition period
				IF v_ADD_AN_HOUR = TRUE THEN
					v_INTERVAL_PERIOD_TIMESTAMP := v_INTERVAL_PERIOD_TIMESTAMP + 1/24;
				END IF;

				-- Check if we should add an hour to the transition hour
				-- Start adding after we see the first fall back date
				IF (I.INTERVAL_PERIOD_TIMESTAMP = DST_FALL_BACK_DATE(I.INTERVAL_PERIOD_TIMESTAMP) AND v_ADD_AN_HOUR = FALSE) THEN
					v_ADD_AN_HOUR := TRUE;
				-- Stop adding when we hit see the fall back date again
				ELSIF (I.INTERVAL_PERIOD_TIMESTAMP = DST_FALL_BACK_DATE(I.INTERVAL_PERIOD_TIMESTAMP) AND v_ADD_AN_HOUR = TRUE) THEN
					v_ADD_AN_HOUR := FALSE;
				END IF;

		   END IF;

			v_TDIE_34X_INTERVAL_REC.TDIE_MPRN_CHANNEL_ID      := C.TDIE_MPRN_CHANNEL_ID;
			v_TDIE_34X_INTERVAL_REC.INTERVAL_PERIOD_TIMESTAMP := v_INTERVAL_PERIOD_TIMESTAMP;
			v_TDIE_34X_INTERVAL_REC.INTERVAL_STATUS_CODE      := I.INTERVAL_STATUS_CODE;
			v_TDIE_34X_INTERVAL_REC.INTERVAL_VALUE            := I.INTERVAL_VALUE;
			v_TDIE_34X_INTERVAL_REC.NET_ACTIVE_DEMAND_VALUE   := I.NET_ACTIVE_DEMAND_VALUE;

			INS_TDIE_34X_INTERVAL(v_TDIE_34X_INTERVAL_REC);

         END LOOP;-- FOR I IN c_34X_INTERVAL
		 v_ADD_AN_HOUR := FALSE;
      END LOOP;--FOR C IN c_34X_CHANNEL

	IF p_PROCESS_IMPORT = 1 THEN
		PROCESS_34X_MPRN(M.TDIE_MPRN_MSG_ID);
	END IF;
   END LOOP;--FOR M IN c_34X_MPRN

END IMPORT_XML_34X;

--------------------------------------------------------------------------------
-- This procedure performs all of the work required to process the imported
-- message file.
PROCEDURE HANDLE_IMPORTS
    (
    p_IMPORT_FILE    IN CLOB,
    p_IMPORT_TYPE    IN VARCHAR2,
    p_PROCESS_IMPORT IN NUMBER DEFAULT 1,
    p_FROM_SEM       IN NUMBER DEFAULT 0
    ) IS

    v_TDIE_ID               TDIE_MESSAGE.TDIE_ID%TYPE;
    v_XML_MSG_HEADER        t_MESSAGE_HEADER;
    v_CSV_MSG_HEADER        t_NIE_HEADER;
BEGIN
   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);
   ASSERT(p_IMPORT_TYPE IS NOT NULL, 'The import type must not be null.', MSGCODES.c_ERR_ARGUMENT);

   SD.VERIFY_ACTION_IS_ALLOWED(MM_TDIE_UTIL.g_ACTION_IMPORT_TDIE);

   -- Populate the header record based on file type.
   CASE p_IMPORT_TYPE
      WHEN g_MIME_TYPE_XML THEN
         v_XML_MSG_HEADER := GET_XML_MSG_HEADER(p_IMPORT_FILE);
      WHEN g_MIME_TYPE_CSV THEN
         v_CSV_MSG_HEADER := GET_CSV_MSG_HEADER(p_IMPORT_FILE);
      ELSE
         ERRS.RAISE(MSGCODES.c_ERR_DATA_IMPORT, 'Invalid file type being processed. Must be and .XML or .CSV file.');
   END CASE;--CASE p_IMPORT_TYPE

   -----------------------------------------------------------------------------
   -- Based on the message file type and the message type code
   -- call the appropriate import message routine.
   CASE
      --------------------------------------------------------------------------
	 -- Process both all 300s except 341,342 (XML file)
	 WHEN p_IMPORT_TYPE = g_MIME_TYPE_XML AND
	 	  MM_TDIE_UTIL.IS_NQH_NHH_3XX_MESSAGE(v_XML_MSG_HEADER.MESSAGE_TYPE_CODE) THEN

	 	-- Import the file
		IMPORT_XML_300(v_XML_MSG_HEADER, p_IMPORT_FILE, v_TDIE_ID);
	    IF NVL(p_PROCESS_IMPORT,1) = 1 THEN
			PROCESS_300(v_TDIE_ID);
		END IF;
	  --------------------------------------------------------------------------
      -- Process both the 591 and 595 market messages (XML file)
      WHEN p_IMPORT_TYPE = g_MIME_TYPE_XML AND
           v_XML_MSG_HEADER.MESSAGE_TYPE_CODE IN ('591','595') THEN

         IMPORT_XML_591_595(v_XML_MSG_HEADER,
                            p_IMPORT_FILE);

      --------------------------------------------------------------------------
      -- Process 596 market messages (XML file)
      WHEN p_IMPORT_TYPE = g_MIME_TYPE_XML AND
           v_XML_MSG_HEADER.MESSAGE_TYPE_CODE = '596' THEN

         IMPORT_XML_596(v_XML_MSG_HEADER,
                        p_IMPORT_FILE,
                        p_PROCESS_IMPORT);

      --------------------------------------------------------------------------
      -- Process 598 market messages (XML file)
      WHEN p_IMPORT_TYPE = g_MIME_TYPE_XML AND
           v_XML_MSG_HEADER.MESSAGE_TYPE_CODE = '598' THEN

         IMPORT_XML_598(v_XML_MSG_HEADER,
                        p_IMPORT_FILE,
                        p_PROCESS_IMPORT);

      --------------------------------------------------------------------------
      -- Process 59x market messages (CSV file)
      WHEN p_IMPORT_TYPE = g_MIME_TYPE_CSV THEN

         IMPORT_CSV_NIE59x(v_CSV_MSG_HEADER,
                           p_IMPORT_FILE,
                           p_PROCESS_IMPORT,
                           p_FROM_SEM);

      --------------------------------------------------------------------------
      -- Process 341, 342, N341 market messages (XML file)
      WHEN p_IMPORT_TYPE = g_MIME_TYPE_XML AND
	 	  MM_TDIE_UTIL.IS_QH_HH_3XX_MESSAGE(v_XML_MSG_HEADER.MESSAGE_TYPE_CODE) THEN

         IMPORT_XML_34X(v_XML_MSG_HEADER,
                        p_IMPORT_FILE,
						p_PROCESS_IMPORT);

      --------------------------------------------------------------------------
      ELSE
      	ERRS.RAISE(MSGCODES.c_ERR_DATA_IMPORT, 'Invalid file type being processed.');
   END CASE;--CASE p_IMPORT_TYPE
END HANDLE_IMPORTS;



--------------------------------------------------------------------------------
--                PUBLIC PROCEDURES AND FUNCTIONS
--------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
FUNCTION GET_CSV_FILE_SCHEDULE_DATE(
   p_MSG_SCHEDULE_DATE     IN DATE,
   p_MSG_INTERVAL_POSITION IN NUMBER
   ) RETURN DATE IS

   v_RETURN_DATE               DATE;

BEGIN
   IF p_MSG_SCHEDULE_DATE IS NULL THEN
      v_RETURN_DATE := NULL;
      GOTO RETURN_END;
   END IF;

   v_RETURN_DATE := TO_CUT(p_MSG_SCHEDULE_DATE, MM_TDIE_UTIL.g_TZ)
                    + ((p_MSG_INTERVAL_POSITION + 1)/48);-- Always 30min.

   <<RETURN_END>>

   RETURN v_RETURN_DATE;

END GET_CSV_FILE_SCHEDULE_DATE;



--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
   RETURN '$Revision: 1.14 $';
END WHAT_VERSION;

--------------------------------------------------------------------------------
PROCEDURE IMPORT
   (
   p_IMPORT_FILE		   IN CLOB,
   p_IMPORT_FILE_PATH	IN VARCHAR2,
   p_TRACE_ON			   IN NUMBER,
   p_PROCESS_IMPORT		IN NUMBER DEFAULT 1,
   p_FROM_SEM      		IN NUMBER DEFAULT 0,
   p_PROCESS_ID			OUT VARCHAR2,
   p_PROCESS_STATUS   	OUT NUMBER,
   p_MESSAGE          	OUT VARCHAR2
   ) IS

   v_FILE_TYPE       VARCHAR2(32);

BEGIN

   BEGIN
	   SAVEPOINT TDIE_IMPORTS_MAIN;

	   LOGS.START_PROCESS('Import IE T' || CONSTANTS.AMPERSAND || 'D Market Messages',p_TRACE_ON => p_TRACE_ON);

	   ASSERT(p_IMPORT_FILE IS NOT NULL, 'The import file must not be null.', MSGCODES.c_ERR_ARGUMENT);
	   ASSERT(p_IMPORT_FILE_PATH IS NOT NULL, 'The import file path must not be null.', MSGCODES.c_ERR_ARGUMENT);
	   SD.VERIFY_ACTION_IS_ALLOWED(MM_TDIE_UTIL.g_ACTION_IMPORT_TDIE);

	   LOGS.SET_PROCESS_TARGET_PARAMETER('IMPORT_FILE_PATH', p_IMPORT_FILE_PATH);
	   LOGS.SET_PROCESS_TARGET_PARAMETER('PROCESS_IMPORT', TO_CHAR(p_PROCESS_IMPORT));

	   v_FILE_TYPE := GET_FILE_TYPE(p_IMPORT_FILE_PATH);

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_INFO_MORE_DETAIL(p_EVENT_TEXT => 'TDIE File Import Contents (see attachment)');
			LOGS.POST_EVENT_DETAILS(p_DETAIL_TYPE => 'FILE IMPORT',
								  p_CONTENT_TYPE => v_FILE_TYPE,
								  p_CONTENTS => p_IMPORT_FILE);
		END IF;

		HANDLE_IMPORTS(p_IMPORT_FILE,
					      v_FILE_TYPE,
					      p_PROCESS_IMPORT,
                     p_FROM_SEM);

		p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;
		LOGS.STOP_PROCESS(p_MESSAGE,p_PROCESS_STATUS);
		COMMIT;

	EXCEPTION
	   WHEN OTHERS THEN
			ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'TDIE_IMPORTS_MAIN');
	END;

END IMPORT;

--------------------------------------------------------------------------------
PROCEDURE IMPORT
   (
   p_IMPORT_FILE		   IN CLOB,
   p_IMPORT_FILE_PATH	IN VARCHAR2,
   p_TRACE_ON			   IN NUMBER,
   p_PROCESS_IMPORT		IN NUMBER DEFAULT 1,
   p_PROCESS_ID			OUT VARCHAR2,
   p_PROCESS_STATUS   	OUT NUMBER,
   p_MESSAGE          	OUT VARCHAR2
   ) IS

   v_FROM_SEM      		NUMBER := 0;

BEGIN

   IMPORT(
     p_IMPORT_FILE,
     p_IMPORT_FILE_PATH,
     p_TRACE_ON,
     p_PROCESS_IMPORT,
     v_FROM_SEM,
     p_PROCESS_ID,
     p_PROCESS_STATUS,
     p_MESSAGE);

END IMPORT;

--------------------------------------------------------------------------------
PROCEDURE IMPORT_CSV_NIE59X_SEM
   (
   p_IMPORT_FILE		   IN CLOB,
   p_IMPORT_FILE_PATH	IN VARCHAR2,
   p_TRACE_ON			   IN NUMBER,
   p_PROCESS_IMPORT		IN NUMBER DEFAULT 1,
   p_PROCESS_ID			OUT VARCHAR2,
   p_PROCESS_STATUS   	OUT NUMBER,
   p_MESSAGE          	OUT VARCHAR2
   ) IS

   v_FROM_SEM      		NUMBER := 1;

BEGIN

   IMPORT(
     p_IMPORT_FILE,
     p_IMPORT_FILE_PATH,
     p_TRACE_ON,
     p_PROCESS_IMPORT,
     v_FROM_SEM,
     p_PROCESS_ID,
     p_PROCESS_STATUS,
     p_MESSAGE);

END IMPORT_CSV_NIE59X_SEM;

--------------------------------------------------------------------------------
PROCEDURE FETCH_IMPORT_FILES
   (
   p_TRACE_ON 		IN NUMBER,
   p_PROCESS_ID		OUT VARCHAR2,
   p_PROCESS_STATUS	OUT NUMBER,
   p_MESSAGE        OUT VARCHAR2
   ) IS

   v_LOGGER          MM_LOGGER_ADAPTER;
   v_MEX_RESULT      MEX_RESULT;

BEGIN
   SAVEPOINT FETCH_IMPORT_FILES_MAIN;

   LOGS.START_PROCESS('Fetch IE T' || CONSTANTS.AMPERSAND || 'D Market Message Files',
   						p_EVENT_LEVEL => LEAST(LOGS.CURRENT_LOG_LEVEL,
												CASE p_TRACE_ON
												WHEN 1 THEN LOGS.c_LEVEL_DEBUG
												WHEN 2 THEN LOGS.c_LEVEL_ALL
												ELSE LOGS.c_LEVEL_FATAL
												END)
						);

   v_LOGGER := MEX_SWITCHBOARD.GET_LOGGER(p_EXTERNAL_SYSTEM_ID    => NULL,
                                          p_EXTERNAL_ACCOUNT_NAME => NULL,
                                          p_PROCESS_NAME          => NULL,
                                          p_EXCHANGE_NAME         => NULL,
                                          p_LOG_TYPE              => NULL,
                                          p_TRACE_ON              => p_TRACE_ON);

   LOOP
      v_MEX_RESULT := MEX_SWITCHBOARD.DEQUEUEMESSAGE(p_MESSAGE_CATEGORY  => 'TDIEImport',
                                                     p_LOGGER            => v_LOGGER);

      EXIT WHEN v_MEX_RESULT.STATUS_CODE <> MEX_SWITCHBOARD.c_STATUS_SUCCESS;

      BEGIN
         HANDLE_IMPORTS(p_IMPORT_FILE    => v_MEX_RESULT.RESPONSE,
                        p_IMPORT_TYPE    => v_MEX_RESULT.RESPONSE_CONTENTTYPE,
                        p_PROCESS_IMPORT => 1);
      EXCEPTION
         WHEN OTHERS THEN
            ERRS.LOG_AND_CONTINUE(p_SAVEPOINT_NAME => 'FETCH_IMPORT_FILES_MAIN');
			LOGS.POST_EVENT_DETAILS('Failed import file.', v_MEX_RESULT.RESPONSE_CONTENTTYPE, v_MEX_RESULT.RESPONSE);
            v_MEX_RESULT := MEX_SWITCHBOARD.ENQUEUEMESSAGE(p_MESSAGE_CATEGORY    => 'TDIEImportErrors',
                                                           p_LOGGER              => v_LOGGER,
                                                           p_REQUEST_CONTENTTYPE => v_MEX_RESULT.RESPONSE_CONTENTTYPE,
                                                           p_REQUEST             => v_MEX_RESULT.RESPONSE);
      END;

      COMMIT;
      SAVEPOINT FETCH_IMPORT_FILES_MAIN;

   END LOOP;--WHILE v_MEX_RESULT.STATUS_CODE...

	p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;
	LOGS.STOP_PROCESS(p_MESSAGE,p_PROCESS_STATUS);

EXCEPTION
   WHEN OTHERS THEN
		ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'FETCH_IMPORT_FILES_MAIN');

END FETCH_IMPORT_FILES;

----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_598(p_TDIE_ID IN NUMBER) AS

   v_SP_ID	NUMBER(9);

BEGIN

   FOR v_REC IN (SELECT TM.TDIE_ID,
                        TM.MESSAGE_DATE,
                        TM.LOCATION_ID,
                        TM.SETTLEMENT_RUN_INDICATOR
                   FROM TDIE_MESSAGE TM
                  WHERE TM.TDIE_ID = p_TDIE_ID
                    AND TM.MESSAGE_TYPE_CODE = '598') LOOP

		v_SP_ID := GET_EARN_SERVICE_POINT_ID(v_REC.LOCATION_ID, FALSE, TRUE);

   END LOOP;--FOR v_REC IN (...

END PROCESS_598;

----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_596(p_TDIE_ID IN NUMBER) AS

   v_ST_ID  NUMBER(9);
   v_IT_ID  NUMBER(9);
   v_STATUS NUMBER(9);

BEGIN

   FOR v_REC IN (SELECT TM.TDIE_ID,
                        TM.MESSAGE_DATE,
                        TM.LOCATION_ID,
                        TM.SETTLEMENT_RUN_INDICATOR
                   FROM TDIE_MESSAGE TM
                  WHERE TM.TDIE_ID = p_TDIE_ID
                    AND TM.MESSAGE_TYPE_CODE = '596') LOOP

      v_IT_ID := MM_TDIE_UTIL.GET_SEM_NET_DEMAND_TRANSACTION(v_REC.LOCATION_ID);

      v_ST_ID := DETERMINE_STATEMENT_TYPE(v_REC.SETTLEMENT_RUN_INDICATOR,
                                          v_REC.MESSAGE_DATE,
										  FALSE);

      FOR v_SMO_REC IN (SELECT TSC.MEASURED_QUANTITY,
                               TSC.END_TIME
                          FROM TDIE_SMO_CONSUMPTION TSC
                         WHERE TSC.TDIE_ID = v_REC.TDIE_ID) LOOP

         ITJ.PUT_IT_SCHEDULE(v_IT_ID,
                             v_ST_ID,
                             g_INTERNAL_STATE,
                             v_SMO_REC.END_TIME,
                             g_LOW_DATE,
                             v_SMO_REC.MEASURED_QUANTITY,
                             NULL,
                             v_STATUS);

         ERRS.VALIDATE_STATUS('ITJ.PUT_IT_SCHEDULE', v_STATUS);

      END LOOP;--FOR v_SMO_REC IN (...

   END LOOP;--FOR v_REC IN (...

END PROCESS_596;

----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_NIE_NET_DEMAND
  (
   p_RECIPIENT_ID             IN VARCHAR2,
   p_BEGIN_DATE               IN DATE,
   p_END_DATE                 IN DATE,
   p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2,
   p_FROM_SEM      	         IN NUMBER DEFAULT 0
   ) AS

   v_ST_ID  NUMBER(9);
   v_IT_ID  NUMBER(9);
   v_STATUS NUMBER(9);

BEGIN

   FOR v_REC IN (SELECT DISTINCT
                        TM.LOCATION_ID,
                        TM.MESSAGE_DATE
                   FROM TDIE_MESSAGE TM
                  WHERE TM.RECIPIENT_ID = p_RECIPIENT_ID
                    AND TM.MESSAGE_DATE BETWEEN p_BEGIN_DATE
                                            AND NVL(p_END_DATE, (p_BEGIN_DATE+1))
                    AND TM.SETTLEMENT_RUN_INDICATOR = p_SETTLEMENT_RUN_INDICATOR
                    AND TM.MESSAGE_TYPE_CODE IN ('N591', 'N595', 'N598')) LOOP

      v_IT_ID := MM_TDIE_UTIL.GET_SEM_NET_DEMAND_TRANSACTION(v_REC.LOCATION_ID);

      IF p_FROM_SEM = 1 THEN
        v_ST_ID := DETERMINE_STATEMENT_TYPE(p_SETTLEMENT_RUN_INDICATOR,
                                            v_REC.MESSAGE_DATE,
                                            TRUE);
      ELSE
        v_ST_ID := DETERMINE_STATEMENT_TYPE(p_SETTLEMENT_RUN_INDICATOR,
                                            v_REC.MESSAGE_DATE,
                                            FALSE);
      END IF;

      FOR V_NIETD_REC IN (SELECT TND.SCHEDULE_DATE,
                                 SUM(CASE
                                         WHEN TM.MESSAGE_TYPE_CODE = 'N598' THEN
                                          -TND.ENERGY
                                         ELSE
                                          TND.ENERGY
                                      END) AS ENERGY
                            FROM TDIE_MESSAGE      TM,
                                 TDIE_NIETD        TN,
                                 TDIE_NIETD_DETAIL TND
                           WHERE TM.RECIPIENT_ID             = p_RECIPIENT_ID
						   	 AND TM.LOCATION_ID              = v_REC.LOCATION_ID
                             AND TM.MESSAGE_DATE             = v_REC.MESSAGE_DATE
                             AND TM.SETTLEMENT_RUN_INDICATOR = p_SETTLEMENT_RUN_INDICATOR
                             AND TN.TDIE_ID                  = TM.TDIE_ID
                             AND TND.TDIE_DETAIL_ID          = TN.TDIE_DETAIL_ID
							 AND TND.ENERGY_TYPE			 = 'P'
                           GROUP BY TND.SCHEDULE_DATE) LOOP

         ITJ.PUT_IT_SCHEDULE(v_IT_ID,
                             v_ST_ID,
                             g_INTERNAL_STATE,
                             v_NIETD_REC.SCHEDULE_DATE,
                             g_LOW_DATE,
                             v_NIETD_REC.ENERGY,
                             NULL,
                             v_STATUS);

         ERRS.VALIDATE_STATUS('ITJ.PUT_IT_SCHEDULE', V_STATUS);

      END LOOP;--FOR V_NIETD_REC IN (...

   END LOOP;--FOR v_REC IN (...

END PROCESS_NIE_NET_DEMAND;
----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_NIE_GENERATION(
   p_RECIPIENT_ID             IN VARCHAR2,
   p_BEGIN_DATE               IN DATE,
   p_END_DATE                 IN DATE,
   p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2
   ) AS

   v_ST_ID  NUMBER(9);
   v_IT_ID  NUMBER(9);
   v_STATUS NUMBER(9);

BEGIN

   FOR V_REC IN (SELECT TM.LOCATION_ID,
                        TM.MESSAGE_DATE,
                        TM.TDIE_ID
                   FROM TDIE_MESSAGE TM
                  WHERE TM.RECIPIENT_ID = p_RECIPIENT_ID
                    AND TM.MESSAGE_DATE BETWEEN p_BEGIN_DATE
                                            AND NVL(p_END_DATE, (p_BEGIN_DATE+1))
                    AND TM.SETTLEMENT_RUN_INDICATOR = p_SETTLEMENT_RUN_INDICATOR
                    AND TM.MESSAGE_TYPE_CODE = 'N598') LOOP
      v_IT_ID := GET_EARN_TRANSACTION_ID(v_REC.LOCATION_ID, TRUE, v_REC.MESSAGE_DATE);

      v_ST_ID := DETERMINE_STATEMENT_TYPE(p_SETTLEMENT_RUN_INDICATOR,
                                          v_REC.MESSAGE_DATE,
										  TRUE);

      FOR v_NIETD_REC IN (SELECT TND.SCHEDULE_DATE,
                                 SUM(TND.ENERGY) ENERGY  -- BZ 27981 -- Sum-up the N598s, if multiple entries exist in file
                            FROM TDIE_NIETD_DETAIL TND,
                                 TDIE_NIETD TD
                           WHERE TD.TDIE_ID         = v_REC.TDIE_ID
                             AND TND.TDIE_DETAIL_ID = TD.TDIE_DETAIL_ID
                             AND TND.ENERGY_TYPE    = 'P'
							 GROUP BY TND.SCHEDULE_DATE	-- BZ 27981 -- Sum-up the N598s, if multiple entries exist in file
							 ORDER BY TND.SCHEDULE_DATE -- BZ 27981 -- Sum-up the N598s, if multiple entries exist in file
							 ) LOOP
         ITJ.PUT_IT_SCHEDULE(v_IT_ID,
                             v_ST_ID,
                             g_INTERNAL_STATE,
                             v_NIETD_REC.SCHEDULE_DATE,
                             g_LOW_DATE,
                             v_NIETD_REC.ENERGY,
                             NULL,
                             v_STATUS);

         ERRS.VALIDATE_STATUS('ITJ.PUT_IT_SCHEDULE', v_STATUS);

      END LOOP;--FOR v_NIETD_REC IN (...

   END LOOP;--FOR V_REC IN (...

END PROCESS_NIE_GENERATION;
----------------------------------------------------------------------------------------------------
PROCEDURE DELETE_TDIE_34X_EXCEPTION
	(
	p_TDIE_MPRN_MSG_ID IN NUMBER
	) AS

BEGIN

	DELETE FROM TDIE_34X_EXCEPTION EXP
	WHERE EXP.TDIE_MPRN_MSG_ID = p_TDIE_MPRN_MSG_ID;

END DELETE_TDIE_34X_EXCEPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_TDIE_34X_EXCEPTION
	(
	p_TDIE_MPRN_MSG_ID IN NUMBER,
	p_EVENT_ID IN NUMBER,
	p_IGNORE IN NUMBER := 0
	) AS

BEGIN

	MERGE INTO TDIE_34X_EXCEPTION TGT
	USING (SELECT p_TDIE_MPRN_MSG_ID AS MSG_ID,
			p_EVENT_ID AS EVENT_ID,
			p_IGNORE AS IGNORE_ERROR
		   FROM DUAL) SRC
	ON (TGT.TDIE_MPRN_MSG_ID  = SRC.MSG_ID)
	WHEN MATCHED THEN
		UPDATE SET TGT.IGNORE_ERROR = SRC.IGNORE_ERROR, TGT.EVENT_ID = SRC.EVENT_ID
	WHEN NOT MATCHED THEN
		INSERT VALUES (SRC.MSG_ID, SRC.EVENT_ID, SRC.IGNORE_ERROR);

END PUT_TDIE_34X_EXCEPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_34X_MPRN
	(
	p_TDIE_MPRN_MSG_ID IN NUMBER
	) AS

	v_CHANNELS TDIE_34X_AGGREGATION_TBL := TDIE_34X_AGGREGATION_TBL();
	v_CHANNEL TDIE_34X_AGGREGATION;

	v_IS_VALID BOOLEAN := TRUE;

	v_ACCOUNT_ID NUMBER(9);
	v_SL_ID NUMBER(9);
	v_MTR_ID NUMBER(9);
	v_CHAN_ID NUMBER(9);

	v_MPRN				TDIE_34X_MPRN.MPRN%TYPE;
	v_MESSAGE_TYPE_CODE	TDIE_34X_MPRN.MESSAGE_TYPE_CODE%TYPE;
	v_READ_DATE			DATE;
	v_MARKET_TIMESTAMP	TDIE_34X_MPRN.MARKET_TIMESTAMP%TYPE;

	v_TEST NUMBER;

	v_METER_SERIAL VARCHAR2(32);
	v_METER_TYPE METER.METER_TYPE%TYPE;

	v_CHANNEL_UOM TX_SUB_STATION_METER_POINT.UOM%TYPE;
	v_CHANNEL_OP_CODE TX_SUB_STATION_METER_POINT.OPERATION_CODE%TYPE;
	v_EXP_UOM TX_SUB_STATION_METER_POINT.UOM%TYPE;
	v_EXP_OP_CODE TX_SUB_STATION_METER_POINT.OPERATION_CODE%TYPE;

	v_CUT_BEGIN DATE;
	v_CUT_END DATE;

	v_HAVE_KWH BOOLEAN := FALSE;
	v_KW_TO_KWH_SCALE NUMBER;

	v_PERIOD_ID NUMBER(9);
	v_TEMPLATE_ID NUMBER(9);

    v_VALUE SYSTEM_DICTIONARY.VALUE%TYPE;
    v_SKIP_PROCESSING_LOSS_FACTOR BOOLEAN;

	v_VERSION_NUMBER TDIE_34X_MPRN.VERSION_NUMBER%TYPE;

 v_RECIPIENT_CID VARCHAR2(3);

	PROCEDURE UPDATE_METER_TOU_USG_FACTOR
		(
		p_METER_ID_TO_UPDATE IN NUMBER,
		p_READ_DATE IN DATE
		) AS
	BEGIN
		-- Update the TOU_USAGE_FACTOR flag on the METER
		UPDATE METER
		SET USE_TOU_USAGE_FACTOR = 1
		WHERE METER_ID = p_METER_ID_TO_UPDATE;

		UT.PUT_TEMPORAL_DATA('METER_TOU_USAGE_FACTOR', -- Insert a record for the date
			p_READ_DATE,		   -- of the report using Day/Night Template
			p_READ_DATE,
			TRUE,
			TRUE,
			'METER_ID',
			UT.GET_LITERAL_FOR_NUMBER(p_METER_ID_TO_UPDATE),
			TRUE,
			'CASE_ID',
			GA.BASE_CASE_ID,
			FALSE,
			'TEMPLATE_ID',
			UT.GET_LITERAL_FOR_NUMBER(v_TEMPLATE_ID),
			FALSE,
			p_TABLE_ID_NAME => 'TOU_USAGE_FACTOR_ID',
			p_TABLE_ID_SEQUENCE => 'OID');

	END UPDATE_METER_TOU_USG_FACTOR;

BEGIN

	SAVEPOINT PRIOR_PROCESS_34X_MPRN;

	-- clear out old exception first
	DELETE_TDIE_34X_EXCEPTION(p_TDIE_MPRN_MSG_ID);

	-- Fetch the Template_ID associated with the Day Period	for use with UPDATE_METER_TOU_USG_FACTOR
	VALIDATE_TIMESLOT_CODE('00D', v_PERIOD_ID, v_TEMPLATE_ID);

	SELECT MP.MPRN, MP.READ_DATE, MP.MARKET_TIMESTAMP, MP.MESSAGE_TYPE_CODE, MP.VERSION_NUMBER, MP.RECIPIENT_CID
	INTO v_MPRN, v_READ_DATE, v_MARKET_TIMESTAMP, v_MESSAGE_TYPE_CODE, v_VERSION_NUMBER, v_RECIPIENT_CID
	FROM TDIE_34X_MPRN MP
	WHERE MP.TDIE_MPRN_MSG_ID = p_TDIE_MPRN_MSG_ID;

	v_KW_TO_KWH_SCALE := CASE WHEN GET_JURISDICTION_FOR_IMPORTS(v_RECIPIENT_CID) = MM_TDIE_UTIL.c_TDIE_JURISDICTION_NI THEN
								   0.5 -- half-hourly for NI
								ELSE
								   0.25 -- quarter-hourly for ROI
								END;

 $if $$UNIT_TEST_MODE = 1 $THEN
    IF UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_MM_TDIE_IMPORTS_300.T_PROCESS_34X_MPRN%' THEN
        INSERT INTO RTO_WORK(WORK_DATA)
        SELECT 'MPRN=' || v_MPRN || ',' ||
            'MESSAGE_TYPE_CODE=' || v_MESSAGE_TYPE_CODE || ',' ||
            'VERSION_NUMBER=' || v_VERSION_NUMBER || ',' ||
            'RECIPIENT_CID=' || v_RECIPIENT_CID || ',' ||
            'KW_TO_KWH_SCALE=' || TO_CHAR(v_KW_TO_KWH_SCALE)
        FROM DUAL;
        RETURN;
    END IF;
 $end

	v_ACCOUNT_ID := GET_ENTITY_FOR_MPRN(v_MPRN,
											EC.ED_ACCOUNT,
											v_IS_VALID);

	v_SL_ID := GET_ENTITY_FOR_MPRN(v_MPRN,
									EC.ED_SERVICE_LOCATION,
									v_IS_VALID);

	IF v_ACCOUNT_ID IS NOT NULL THEN
		-- VALIDATE THAT THE ACCOUNT IS ACTIVE AND HAS AN EDC AND ESP RELATIONSHIP ON READ DATE
		SELECT NVL(MAX(STAT.IS_ACTIVE),0) INTO v_TEST
		FROM ACCOUNT_STATUS ACS,
			ACCOUNT_STATUS_NAME STAT
		WHERE ACS.ACCOUNT_ID = v_ACCOUNT_ID
			AND v_READ_DATE BETWEEN ACS.BEGIN_DATE AND NVL(ACS.END_DATE, CONSTANTS.HIGH_DATE)
			AND STAT.STATUS_NAME = ACS.STATUS_NAME;

		IF v_TEST <= 0 THEN
			LOGS.LOG_ERROR('Account ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT)
					|| ' (MPRN: ' || v_MPRN || ') is not active on read date '
					|| TEXT_UTIL.TO_CHAR_DATE(v_READ_DATE) || '.');
		END IF;

		SELECT COUNT(1) INTO v_TEST
		FROM ACCOUNT_EDC EDC
		WHERE EDC.ACCOUNT_ID = v_ACCOUNT_ID
			AND v_READ_DATE BETWEEN EDC.BEGIN_DATE AND NVL(EDC.END_DATE, CONSTANTS.HIGH_DATE);

		IF v_TEST <= 0 THEN
			LOGS.LOG_ERROR('Account ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT)
					|| ' (MPRN: ' || v_MPRN || ') does not have an associated EDC on read date '
					|| TEXT_UTIL.TO_CHAR_DATE(v_READ_DATE) || '.');
		END IF;

		SELECT COUNT(1) INTO v_TEST
		FROM ACCOUNT_ESP ESP
		WHERE ESP.ACCOUNT_ID = v_ACCOUNT_ID
			AND v_READ_DATE BETWEEN ESP.BEGIN_DATE AND NVL(ESP.END_DATE, CONSTANTS.HIGH_DATE);

		IF v_TEST <= 0 THEN
			LOGS.LOG_ERROR('Account ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT)
					|| ' (MPRN: ' || v_MPRN || ') does not have an associated ESP on read date '
					|| TEXT_UTIL.TO_CHAR_DATE(v_READ_DATE) || '.');
		END IF;

		IF v_SL_ID IS NOT NULL THEN
		-- HAVE BOTH ACCOUNT AND SERVICE LOCATION, VALIDATE THEIR RELATIONSHIP ON THIS
		-- DATE
			SELECT COUNT(1) INTO v_TEST
			FROM ACCOUNT_SERVICE_LOCATION ASL
			WHERE ASL.ACCOUNT_ID = v_ACCOUNT_ID
				AND ASL.SERVICE_LOCATION_ID = v_SL_ID
				AND v_READ_DATE BETWEEN ASL.BEGIN_DATE AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE);

			IF v_TEST <= 0 THEN
				LOGS.LOG_ERROR('Account ' || TEXT_UTIL.TO_CHAR_ENTITY(v_ACCOUNT_ID, EC.ED_ACCOUNT)
					|| ' (MPRN: ' || v_MPRN || ') does not have a relationship with service location '
					|| TEXT_UTIL.TO_CHAR_ENTITY(v_SL_ID, EC.ED_SERVICE_LOCATION) || ' on read date '
					|| TEXT_UTIL.TO_CHAR_DATE(v_READ_DATE) || '.');
				v_IS_VALID := FALSE;
			END IF;
		END IF;

		-- Keep track of the metered accounts
		PUT_ACCT_LAST_READ_RCV_DATE(v_ACCOUNT_ID, v_MARKET_TIMESTAMP);

	END IF;

    --DON'T VALIDATE METERS/CHANNELS IF SERVICE LOCATION WASN'T VALIDATED
    IF v_SL_ID IS NOT NULL THEN
        FOR v_CHAN_REC IN (SELECT MP.MPRN, MP.READ_DATE, MP.MARKET_TIMESTAMP, MP.GENERATOR_UNITID, MP.MESSAGE_TYPE_CODE,
                                CHAN.REGISTER_TYPE_CODE, CHAN.METERING_INTERVAL, CHAN.UOM_CODE,
                                CHAN.TDIE_MPRN_CHANNEL_ID,	
                                --MP.GENERATOR_UNITID || '-' || CHAN.TDIE_MPRN_CHANNEL_ID AS TDIE_MPRN_CHANNEL_ID,
                                CHAN.SERIAL_NUMBER AS METER_SERIAL
                            FROM TDIE_34X_MPRN MP,
                                TDIE_34X_MPRN_CHANNEL CHAN
                            WHERE MP.TDIE_MPRN_MSG_ID = p_TDIE_MPRN_MSG_ID
                                AND CHAN.TDIE_MPRN_MSG_ID = MP.TDIE_MPRN_MSG_ID
                            ORDER BY CHAN.SERIAL_NUMBER) LOOP

            -- NEW METER?  VALIDATE IT
            IF v_METER_SERIAL IS NULL OR v_METER_SERIAL <> v_CHAN_REC.METER_SERIAL THEN
                v_METER_SERIAL := v_CHAN_REC.METER_SERIAL;

                BEGIN
                    v_MTR_ID := MM_TDIE_UTIL.GET_METER_ID(v_SL_ID, v_METER_SERIAL, v_READ_DATE, v_READ_DATE, NULL, v_CHAN_REC.GENERATOR_UNITID);
                EXCEPTION
                    WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
                        LOGS.LOG_ERROR('No ' || TEXT_UTIL.TO_CHAR_ENTITY(EC.ED_METER, EC.ED_ENTITY_DOMAIN)
			                || ' was found for identifier ' || v_METER_SERIAL
							|| ' on meter date ' || TEXT_UTIL.TO_CHAR_DATE(v_READ_DATE));
                        v_IS_VALID := FALSE;
                    WHEN MSGCODES.e_ERR_TOO_MANY_ENTRIES THEN
                        LOGS.LOG_ERROR('More than one ' || TEXT_UTIL.TO_CHAR_ENTITY(EC.ED_METER, EC.ED_ENTITY_DOMAIN)
			                || ' was found for identifier ' || v_METER_SERIAL
							|| ' on meter date ' || TEXT_UTIL.TO_CHAR_DATE(v_READ_DATE));
                        v_IS_VALID := FALSE;
                END;

                IF v_MTR_ID IS NOT NULL THEN
                    SELECT M.METER_TYPE INTO v_METER_TYPE
                    FROM METER M
                    WHERE M.METER_ID = v_MTR_ID;

                    IF NVL(v_METER_TYPE, 'Period') <> 'Interval' THEN
                        LOGS.LOG_ERROR('Meter ' || TEXT_UTIL.TO_CHAR_ENTITY(v_MTR_ID, EC.ED_METER)
                            || ' has a meter type of ' || NVL(v_METER_TYPE,'NULL') || ', but a type of ''Interval'' '
                            || 'is required.');
                        v_IS_VALID := FALSE;
                    END IF;

                    IF v_SL_ID IS NOT NULL THEN
                    -- HAVE BOTH ACCOUNT AND SERVICE LOCATION, VALIDATE THEIR RELATIONSHIP ON THIS
                    -- DATE
                        SELECT COUNT(1) INTO v_TEST
                        FROM SERVICE_LOCATION_METER SLM
                        WHERE SLM.SERVICE_LOCATION_ID = v_SL_ID
                            AND SLM.METER_ID = v_MTR_ID
                            AND v_READ_DATE BETWEEN SLM.BEGIN_DATE AND NVL(SLM.END_DATE, CONSTANTS.HIGH_DATE);

                        IF v_TEST <= 0 THEN
                            LOGS.LOG_ERROR('Service Location ' || TEXT_UTIL.TO_CHAR_ENTITY(v_SL_ID, EC.ED_SERVICE_LOCATION)
                                || ' (MPRN: ' || v_MPRN || ') does not have a relationship with meter '
                                || TEXT_UTIL.TO_CHAR_ENTITY(v_MTR_ID, EC.ED_METER) || ' (Serial Number: '
                                || v_METER_SERIAL || ') on read date '
                                || TEXT_UTIL.TO_CHAR_DATE(v_READ_DATE) || '.');
                            v_IS_VALID := FALSE;
                        END IF;
                    END IF;
                END IF;
            END IF;

            -- DONE VALIDATING THE METER, NOW VALIDATE CHANNELS (ONLY IF METER WAS FOUND)
            -- CHANNELS AREN'T UNIQUE WITHOUT THEIR RETAIL METER ID
            IF v_MTR_ID IS NOT NULL THEN
                BEGIN
                    SELECT PT.METER_POINT_ID, PT.UOM, PT.OPERATION_CODE INTO v_CHAN_ID, v_CHANNEL_UOM, v_CHANNEL_OP_CODE
                    FROM TX_SUB_STATION_METER_POINT PT
                    WHERE PT.METER_POINT_NAME = v_CHAN_REC.REGISTER_TYPE_CODE
                        AND PT.RETAIL_METER_ID = v_MTR_ID;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        LOGS.LOG_ERROR('There is no channel named ' || v_CHAN_REC.REGISTER_TYPE_CODE || ' belonging to '
                                || ' meter ' || TEXT_UTIL.TO_CHAR_ENTITY(v_MTR_ID, EC.ED_METER) || '.');
                        v_CHAN_ID := NULL;
                        v_IS_VALID := FALSE;
                END;
                
                IF v_CHAN_ID IS NOT NULL THEN
                    -- VALIDATE ATTRIBUTES ON THE CHANNEL
                    SELECT MAX(DT.VALUE) INTO v_EXP_OP_CODE
                    FROM SYSTEM_DICTIONARY DT
                    WHERE DT.MODEL_ID = 0
                        AND DT.MODULE = 'MarketExchange'
                        AND DT.KEY1 = 'TDIE'
                        AND DT.KEY2 = 'RegisterTypeCodeMapping'
                        AND dt.KEY3 = '?'
                        AND DT.SETTING_NAME = v_CHAN_REC.REGISTER_TYPE_CODE;

                    v_EXP_UOM := MM_TDIE_UTIL.CONVERT_UOM_CODE(v_CHAN_REC.UOM_CODE);

                    IF v_EXP_OP_CODE IS NULL THEN
                        LOGS.LOG_ERROR('Register Type Code ' || v_CHAN_REC.REGISTER_TYPE_CODE || ' is unrecognized; '
                            || ' the op code could not be determined for the channel.');
                        v_IS_VALID := FALSE;
                    END IF;

                    IF v_EXP_OP_CODE IS NOT NULL AND v_EXP_OP_CODE <> v_CHANNEL_OP_CODE THEN
                        LOGS.LOG_ERROR('Channel ' || TEXT_UTIL.TO_CHAR_ENTITY(v_CHAN_ID, EC.ED_SUB_STATION_METER_POINT)
                            || ' belonging to meter ' || TEXT_UTIL.TO_CHAR_ENTITY(v_MTR_ID, EC.ED_METER)
                            || ' does not have the expected op code of ' || v_EXP_OP_CODE);
                        v_IS_VALID := FALSE;
                    END IF;

                    IF v_EXP_UOM <> NVL(v_CHANNEL_UOM, 'NULL') THEN
                        LOGS.LOG_ERROR('Channel ' || TEXT_UTIL.TO_CHAR_ENTITY(v_CHAN_ID, EC.ED_SUB_STATION_METER_POINT)
                            || ' belonging to meter ' || TEXT_UTIL.TO_CHAR_ENTITY(v_MTR_ID, EC.ED_METER)
                            || ' does not have the expected UOM of ' || v_EXP_UOM);
                        v_IS_VALID := FALSE;
                    END IF;
                END IF;
            END IF;

            v_CHANNEL.TDIE_MPRN_CHANNEL_ID := v_CHAN_REC.TDIE_MPRN_CHANNEL_ID;
            v_CHANNEL.ACCOUNT_ID := v_ACCOUNT_ID;
            v_CHANNEL.SERVICE_LOCATION_ID := v_SL_ID;
            v_CHANNEL.METER_ID := v_MTR_ID;
            v_CHANNEL.METER_POINT_ID := v_CHAN_ID;
            v_CHANNEL.METERING_INTERVAL := v_CHAN_REC.METERING_INTERVAL;
			v_CHANNEL.UOM := v_CHAN_REC.UOM_CODE;

            v_CHANNELS.EXTEND();
            v_CHANNELS(v_CHANNELS.LAST) := v_CHANNEL;
        END LOOP;
    ELSE
        v_IS_VALID := FALSE;
    END IF;


    SP.GET_SYSTEM_DICTIONARY_VALUE(GA.STANDARD_MODE,
                                'MarketExchange',
                                'TDIE',
                                'Settings',
                                '?',
                                'Skip Processing Of Losses For Import Of Actual Meter Data',
                                v_VALUE);

    v_SKIP_PROCESSING_LOSS_FACTOR := CASE WHEN v_VALUE = '1' THEN TRUE ELSE FALSE END;
	IF v_IS_VALID THEN
		UT.CUT_DATE_RANGE(GA.DEFAULT_MODEL, v_READ_DATE, v_READ_DATE, MM_TDIE_UTIL.g_TZ, v_CUT_BEGIN, v_CUT_END);
		v_MTR_ID := NULL;

		FOR v_IDX IN 1..v_CHANNELS.LAST LOOP
			v_CHANNEL := v_CHANNELS(v_IDX);

			IF v_MTR_ID IS NULL THEN
				v_MTR_ID := v_CHANNEL.METER_ID;
			ELSIF v_MTR_ID <> v_CHANNEL.METER_ID THEN
				-- WE'RE NOW ON THE NEXT METER, AGGREGATE THE LAST ONE
				DATA_IMPORT.AGGREGATE_CHANNEL_DATA(v_CHANNEL.ACCOUNT_ID,
												v_CHANNEL.SERVICE_LOCATION_ID,
												v_MTR_ID,
												v_READ_DATE,
												CONSTANTS.CODE_ACTUAL,
												CASE v_CHANNEL.METERING_INTERVAL WHEN 15 THEN 'MI15'
													WHEN 30 THEN 'MI30' END,
												v_CUT_BEGIN,
												v_CUT_END,
												v_MARKET_TIMESTAMP,
												v_IS_VALID,
												1,
												CASE WHEN v_HAVE_KWH THEN 'KWH' ELSE 'KW' END,
												CASE WHEN v_HAVE_KWH THEN 1.0 ELSE v_KW_TO_KWH_SCALE END,
                                                v_SKIP_PROCESSING_LOSS_FACTOR);
				-- Set up Day/Night template for ROI interval meters
				UPDATE_METER_TOU_USG_FACTOR(v_MTR_ID, v_READ_DATE);
				v_MTR_ID := v_CHANNEL.METER_ID;
				v_HAVE_KWH := FALSE; -- reset for next meter
			END IF;

			-- CLEAR OUT DATA ON READ_DATE
			DELETE FROM TX_SUB_STATION_METER_PT_VALUE VAL
			WHERE VAL.METER_POINT_ID = v_CHANNEL.METER_POINT_ID
				AND VAL.MEASUREMENT_SOURCE_ID = CONSTANTS.NOT_ASSIGNED
				AND VAL.METER_CODE = CONSTANTS.CODE_ACTUAL
				AND VAL.METER_DATE BETWEEN v_CUT_BEGIN AND v_CUT_END;

			-- NOW INSERT
			INSERT INTO TX_SUB_STATION_METER_PT_VALUE (METER_POINT_ID, MEASUREMENT_SOURCE_ID, METER_CODE,
					METER_DATE, METER_VAL, ENTRY_DATE )
			SELECT v_CHANNEL.METER_POINT_ID, CONSTANTS.NOT_ASSIGNED, CONSTANTS.CODE_ACTUAL, IT.INTERVAL_PERIOD_TIMESTAMP,
				IT.INTERVAL_VALUE, SYSDATE
			FROM TDIE_34X_INTERVAL IT
			WHERE IT.TDIE_MPRN_CHANNEL_ID = v_CHANNEL.TDIE_MPRN_CHANNEL_ID
				-- only include reads with "valid" status
				AND IT.INTERVAL_STATUS_CODE = c_REGISTER_STATUS_VALID;

			IF v_CHANNEL.UOM = 'KWH' THEN
				v_HAVE_KWH := TRUE; -- found kwh
			END IF;
		END LOOP;

		-- AGGREGATE CHANNEL DATA AND UPDATE METER TOU FLAG FOR THE LAST METER (v_MTR_ID)
		UPDATE_METER_TOU_USG_FACTOR(v_MTR_ID, v_READ_DATE);
		DATA_IMPORT.AGGREGATE_CHANNEL_DATA(v_CHANNEL.ACCOUNT_ID,
											v_CHANNEL.SERVICE_LOCATION_ID,
											v_MTR_ID,
											v_READ_DATE,
											CONSTANTS.CODE_ACTUAL,
											CASE v_CHANNEL.METERING_INTERVAL WHEN 15 THEN 'MI15'
												WHEN 30 THEN 'MI30' END,
											v_CUT_BEGIN,
											v_CUT_END,
											v_MARKET_TIMESTAMP,
											v_IS_VALID,
											1,
											CASE WHEN v_HAVE_KWH THEN 'KWH' ELSE 'KW' END,
											CASE WHEN v_HAVE_KWH THEN 1.0 ELSE v_KW_TO_KWH_SCALE END,
                                            v_SKIP_PROCESSING_LOSS_FACTOR);
	END IF;

	IF NOT v_IS_VALID THEN
		ERRS.ROLLBACK_TO('PRIOR_PROCESS_34X_MPRN');
		PUT_TDIE_34X_EXCEPTION(p_TDIE_MPRN_MSG_ID,
								LOGS.LAST_EVENT_ID);
	END IF;

END PROCESS_34X_MPRN;
--------------------------------------------------------------------------------
BEGIN
	g_NI_HARMONISATION_VERSION := GET_DICTIONARY_VALUE(p_SETTING_NAME	=> 'NI Schema Version'
											   		  ,p_MODEL_ID 		=> 0
											   		  ,p_MODULE 		=> 'MarketExchange'
											   		  ,p_KEY1			=> 'TDIE'
											   		  ,p_KEY2			=> 'Harmonisation');
END MM_TDIE_IMPORTS;
/
