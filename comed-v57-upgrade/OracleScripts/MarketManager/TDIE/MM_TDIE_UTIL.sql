CREATE OR REPLACE PACKAGE MM_TDIE_UTIL IS
--------------------------------------------------------------------------------
-- Created : 09/30/2009 15:25
-- Purpose : Utility Routines for the Market Messages
-- $Revision: 1.17 $
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Global Package Constants
--------------------------------------------------------------------------------
g_CSV_DATE_FORMAT      CONSTANT VARCHAR2(8)  := 'YYYYMMDD';
g_XML_DATE_FORMAT      CONSTANT VARCHAR2(10) := 'YYYY-MM-DD';
g_XML_TIMESTAMP_FORMAT CONSTANT VARCHAR2(32) := 'YYYY-MM-DD HH24:MI:SS.FFTZH:TZM';

-- Dist.Co. aliases
c_ESBN_ALIAS	CONSTANT VARCHAR2(32) := 'ESBN';
c_NIE_ALIAS  	CONSTANT VARCHAR2(32) := 'NIE';

g_ESBN_SC_ID           CONSTANT NUMBER(9)    := EI.GET_ID_FROM_ALIAS(c_ESBN_ALIAS, EC.ED_SC);
g_ESBN_EDC_ID          CONSTANT NUMBER(9)    := EI.GET_ID_FROM_ALIAS(c_ESBN_ALIAS, EC.ED_EDC);
g_NIE_SC_ID            CONSTANT NUMBER(9)    := EI.GET_ID_FROM_ALIAS(c_NIE_ALIAS, EC.ED_SC);
g_NIE_EDC_ID           CONSTANT NUMBER(9)    := EI.GET_ID_FROM_ALIAS(c_NIE_ALIAS, EC.ED_EDC);

g_TDIE_STATEMENT_TYPE_PREFIX CONSTANT VARCHAR2(10) := 'T' || CONSTANTS.AMPERSAND || 'D IE ';
g_TDIE_INDICATIVE_ST         CONSTANT NUMBER(9) := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('P', EC.ED_STATEMENT_TYPE, EC.ES_TDIE);
g_TDIE_INITIAL_ST            CONSTANT NUMBER(9) := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('F', EC.ED_STATEMENT_TYPE, EC.ES_TDIE);
g_TDIE_TXN_END_DATE          CONSTANT DATE := TO_DATE(NVL(GET_DICTIONARY_VALUE('TDIE Txn End Date', CONSTANTS.GLOBAL_MODEL, 'MarketExchange',
																			'TDIE','Settings'),'2020-12-31'), 'YYYY-MM-DD');

g_USAGE_FACTOR_TYPE_ACTUAL CONSTANT VARCHAR2(1) := 'A';
g_USAGE_FACTOR_TYPE_ESTIMATED CONSTANT VARCHAR2(1) := 'E';

c_STATIC_DATA_DATE_THRESHOLD	CONSTANT PLS_INTEGER := TO_NUMBER(NVL(GET_DICTIONARY_VALUE('Static Data Date Threshold', CONSTANTS.GLOBAL_MODEL,
																			'MarketExchange', 'TDIE','Settings'),'1'));

g_TZ	 CONSTANT VARCHAR2(3) := 'EDT';

g_EG_DUOS_GROUP CONSTANT VARCHAR2(32) := 'Distribution Group';
g_EG_TUOS_GROUP CONSTANT VARCHAR2(32) := 'Transmission Group';

c_MIC_ANCILLARY_SERVICE_NAME CONSTANT VARCHAR2(3) := 'MIC';

-- Jurisdictions
c_TDIE_JURISDICTION_ROI CONSTANT VARCHAR2(3) := 'ROI';
c_TDIE_JURISDICTION_NI  CONSTANT VARCHAR2(2) := 'NI';

-- Invoice SENDER names
c_TDIE_TUOS_ROI_SENDER CONSTANT VARCHAR2(32) := 'EirGrid';
c_TDIE_TUOS_NI_SENDER  CONSTANT VARCHAR2(32) := 'SONI';
c_TDIE_DUOS_ROI_SENDER CONSTANT VARCHAR2(32) := 'DSO';
c_TDIE_DUOS_NI_SENDER  CONSTANT VARCHAR2(32) := 'TDO';
c_TDIE_UOS_SENDER      CONSTANT VARCHAR2(32) := 'NIE T' || CONSTANTS.AMPERSAND || 'D';
c_TDIE_CCL_SENDER      CONSTANT VARCHAR2(32) := 'CCL';
c_TDIE_SSS_SENDER      CONSTANT VARCHAR2(32) := 'SSS';
c_TDIE_PSO_NI_SENDER   CONSTANT VARCHAR2(32) := 'PSO (NI)';
c_TDIE_PSO_ROI_SENDER  CONSTANT VARCHAR2(32) := 'PSO (ROI)';

-- Invoice SENDER PSE Ids
c_TDIE_TUOS_ROI_SENDER_PSE_ID 	CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_TUOS_ROI_SENDER, EC.ED_PSE);
c_TDIE_TUOS_NI_SENDER_PSE_ID 	CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_TUOS_NI_SENDER, EC.ED_PSE);
c_TDIE_DUOS_ROI_SENDER_PSE_ID 	CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_DUOS_ROI_SENDER, EC.ED_PSE);
c_TDIE_DUOS_NI_SENDER_PSE_ID 	CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_UOS_SENDER, EC.ED_PSE);
c_TDIE_UOS_SENDER_PSE_ID 	    CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_UOS_SENDER, EC.ED_PSE);

c_TDIE_CCL_SENDER_PSE_ID        CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_CCL_SENDER, EC.ED_PSE);
c_TDIE_SSS_SENDER_PSE_ID        CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_SSS_SENDER, EC.ED_PSE);
c_TDIE_PSO_NI_SENDER_PSE_ID     CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_PSO_NI_SENDER, EC.ED_PSE);
c_TDIE_PSO_ROI_SENDER_PSE_ID    CONSTANT NUMBER(9) := EI.GET_ID_FROM_ALIAS(c_TDIE_PSO_ROI_SENDER, EC.ED_PSE);

-- External System ID Types
c_TDIE_EXTERNAL_TYPE_DUOS CONSTANT VARCHAR2(4) := 'DUOS';
c_TDIE_EXTERNAL_TYPE_TUOS CONSTANT VARCHAR2(4) := 'TUOS';
c_TDIE_EXTERNAL_TYPE_UOS  CONSTANT VARCHAR2(4) := 'UOS';
c_TDIE_EXTERNAL_TYPE_DUOS_NI  CONSTANT VARCHAR2(7) := 'DUOS NI';

-- Timeslot codes
c_TDIE_TIMESLOT_CODE_DAY 	CONSTANT VARCHAR2(4) := '00D';
c_TDIE_TIMESLOT_CODE_NIGHT 	CONSTANT VARCHAR2(4) := '00N';
c_TDIE_TIMESLOT_CODE_24H 	CONSTANT VARCHAR2(4) := '24H';
c_TDIE_TIMESLOT_CODE_D01 	CONSTANT VARCHAR2(4) := 'D01';
c_TDIE_TIMESLOT_CODE_D02 	CONSTANT VARCHAR2(4) := 'D02';
c_TDIE_TIMESLOT_CODE_N01 	CONSTANT VARCHAR2(4) := 'N01';
c_TDIE_TIMESLOT_CODE_N02 	CONSTANT VARCHAR2(4) := 'N02';
c_TDIE_TIMESLOT_CODE_N03 	CONSTANT VARCHAR2(4) := 'N03';
c_TDIE_TIMESLOT_CODE_N04 	CONSTANT VARCHAR2(4) := 'N04';
c_TDIE_TIMESLOT_CODE_HT1 	CONSTANT VARCHAR2(4) := 'HT1';
c_TDIE_TIMESLOT_CODE_HT2 	CONSTANT VARCHAR2(4) := 'HT2';
c_TDIE_TIMESLOT_CODE_HT3 	CONSTANT VARCHAR2(4) := 'HT3';
c_TDIE_TIMESLOT_CODE_W01 	CONSTANT VARCHAR2(4) := 'W01';
c_TDIE_TIMESLOT_CODE_W02 	CONSTANT VARCHAR2(4) := 'W02';
c_TDIE_TIMESLOT_CODE_FR1 	CONSTANT VARCHAR2(4) := 'FR1';
c_TDIE_TIMESLOT_CODE_FR2 	CONSTANT VARCHAR2(4) := 'FR2';
c_TDIE_TIMESLOT_CODE_FR3 	CONSTANT VARCHAR2(4) := 'FR3';
c_TDIE_TIMESLOT_CODE_FR4 	CONSTANT VARCHAR2(4) := 'FR4';
c_TDIE_TIMESLOT_CODE_KP5 	CONSTANT VARCHAR2(4) := 'KP5';
c_TDIE_TIMESLOT_CODE_KP6 	CONSTANT VARCHAR2(4) := 'KP6';
c_TDIE_TIMESLOT_CODE_KP7 	CONSTANT VARCHAR2(4) := 'KP7';
c_TDIE_TIMESLOT_CODE_KP8 	CONSTANT VARCHAR2(4) := 'KP8';
c_TDIE_TIMESLOT_CODE_R21 	CONSTANT VARCHAR2(4) := 'R21';
c_TDIE_TIMESLOT_CODE_R22 	CONSTANT VARCHAR2(4) := 'R22';
c_TDIE_TIMESLOT_CODE_R23 	CONSTANT VARCHAR2(4) := 'R23';
c_TDIE_TIMESLOT_CODE_R24 	CONSTANT VARCHAR2(4) := 'R24';
c_TDIE_TIMESLOT_CODE_R25 	CONSTANT VARCHAR2(4) := 'R25';
c_TDIE_TIMESLOT_CODE_R26 	CONSTANT VARCHAR2(4) := 'R26';
c_TDIE_TIMESLOT_CODE_SMO 	CONSTANT VARCHAR2(4) := 'SMO';
c_TDIE_TIMESLOT_CODE_SNF 	CONSTANT VARCHAR2(4) := 'SNF';
c_TDIE_TIMESLOT_CODE_SDJ 	CONSTANT VARCHAR2(4) := 'SDJ';
c_TDIE_TIMESLOT_CODE_PNF 	CONSTANT VARCHAR2(4) := 'PNF';
c_TDIE_TIMESLOT_CODE_PDJ 	CONSTANT VARCHAR2(4) := 'PDJ';
c_TDIE_TIMESLOT_CODE_SEW 	CONSTANT VARCHAR2(4) := 'SEW';
c_TDIE_TIMESLOT_CODE_SNT 	CONSTANT VARCHAR2(4) := 'SNT';
c_TDIE_TIMESLOT_CODE_ANY	CONSTANT VARCHAR2(7) := 'Anytime';


-- DUOS Charge Names
c_ROI_DUOS_DAYNGHT_ENERGY_CHRG  CONSTANT VARCHAR2(64) := 'Day/Night Energy Charge';
c_ROI_DUOS_24H_ENERGY_CHRG 		CONSTANT VARCHAR2(64) := '24 HR Energy Charge';
c_ROI_DUOS_STANDING_CHRG 		CONSTANT VARCHAR2(64) := 'Standing Charge';
c_ROI_DUOS_CAPACITY_CHRG 		CONSTANT VARCHAR2(64) := 'Capacity Charge';
c_ROI_DUOS_MIC_CHRG				CONSTANT VARCHAR2(64) := 'Mic Surcharge';
c_ROI_DUOS_POWER_FACTOR_CHRG	CONSTANT VARCHAR2(64) := 'Power Factor Surcharge';
c_ROI_DUOS_VAT_CHRG				CONSTANT VARCHAR2(64) := 'DUOS VAT';
c_ROI_TUOS_VAT_CHRG				CONSTANT VARCHAR2(64) := 'TUOS VAT';

-- DUOS NI Charge Names
c_NI_DUOS_STANDING_CHRG			CONSTANT VARCHAR2(64) := 'SC';
c_NI_DUOS_CSC_CHRG				CONSTANT VARCHAR2(64) := 'CSC';
c_NI_DUOS_REAC_CHRG				CONSTANT VARCHAR2(64) := 'REAC';
c_NI_DUOS_UNMETERED_CHRG		CONSTANT VARCHAR2(64) := 'UNMETERED';
c_NI_DUOS_MIC_CHRG        		CONSTANT VARCHAR2(64) := 'MIC';
c_NI_DUOS_OTHER_CHRG			CONSTANT VARCHAR2(64) := 'KWH';

-- System Action for Imports
g_ACTION_IMPORT_TDIE CONSTANT VARCHAR2(32) := 'Import TDIE Files';
c_ACTION_RUN_ANY_VALIDATION CONSTANT VARCHAR2(36) := 'Run Any IE T' || CONSTANTS.AMPERSAND || 'D Invoice Validation';
c_ACTION_RUN_ANY_SETTLEMENT CONSTANT VARCHAR2(36) := 'Run Any IE T' || CONSTANTS.AMPERSAND || 'D Financial Settlement';

-- Entity Attribute
g_EA_CCL_RELIEF_PCT CONSTANT VARCHAR2(32) := 'CCL Relief Percentage';
--------------------------------------------------------------------------------
-- Standard function to return the version of the package.
FUNCTION WHAT_VERSION RETURN VARCHAR;

--------------------------------------------------------------------------------
-- Retrieve the Transaction ID for the SEM Net Demand transaction for the
-- specified supplier unit. A new transaction and a new service point will be
-- created if they do not already exist.
FUNCTION GET_SEM_NET_DEMAND_TRANSACTION
	(
	p_SUPPLIER_UNIT IN VARCHAR2
	) RETURN NUMBER;

--------------------------------------------------------------------------------
-- Determine the SEM SU service point ID for the specified generator
-- service point ID for the specified schedule date. Note that schedule
-- date is a half-hourly or quarter-hourly CUT date/time. The actual
-- operation date will be determined (using the TDIE time zone), and
-- then the mapping will looked up based on that operation date.
-- %param p_GENERATOR_ID	The ID of the generator
-- %param p_SCHEDULE_DATE	A scheduling interval. The mapping
--					returned must be effective for this
--					interval.
-- %return				The corresponding SU service point ID for
--					the specified generator
FUNCTION GET_SUPPLY_UNIT_FOR_GENERATOR
	(
	p_GENERATOR_ID IN NUMBER,
	p_SCHEDULE_DATE IN DATE
	) RETURN NUMBER;

--------------------------------------------------------------------------------
-- Convert a market message UOM_CODE to an internal UNIT_OF_MEASUREMENT value:
--  K3  -> kVArh
--  KVA -> kVA
--  KWH -> kWh
--  KWT -> kW
--  KVR -> kVAr
--  MWH -> MWh
FUNCTION CONVERT_UOM_CODE(p_UOM_CODE IN VARCHAR2) RETURN VARCHAR2;

FUNCTION JURISDICTION_FOR_SENDER_PSE(p_SENDER_PSE_ID NUMBER) RETURN VARCHAR2;
FUNCTION JURISDICTION_FOR_SENDER_CID(p_SENDER_CID VARCHAR2) RETURN VARCHAR2;
FUNCTION GET_SENDER_PSE_ID(p_SENDER_CID VARCHAR2) RETURN NUMBER;
FUNCTION SENDER_CID_IS_TUOS(p_SENDER_CID VARCHAR2) RETURN BOOLEAN;
FUNCTION SENDER_CID_IS_DUOS(p_SENDER_CID VARCHAR2) RETURN BOOLEAN;
FUNCTION SENDER_PSE_IS_TUOS(p_SENDER_PSE_ID NUMBER) RETURN BOOLEAN;
FUNCTION SENDER_PSE_IS_DUOS(p_SENDER_PSE_ID NUMBER) RETURN BOOLEAN;
FUNCTION GET_TYPE_FOR_SENDER_CID(p_SENDER_CID VARCHAR2) RETURN VARCHAR2;

FUNCTION GET_EDC_ID_FOR_JURISDICTION(p_JURISDICTION VARCHAR2) RETURN NUMBER;

FUNCTION VERIFY_STATIC_DATA_DURATION(p_COUNT IN PLS_INTEGER, p_EXPECTED IN PLS_INTEGER) RETURN BOOLEAN;

FUNCTION VERIFY_SERVICE_LOCATION_METER
	(
	p_MPRN IN VARCHAR2,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN BOOLEAN;

FUNCTION VERIFY_SERVICE_LOCATION_METER
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN BOOLEAN;

--------------------------------------------------------------------------------
-- This function gets the RO/MO Meter Id for the associated TDIE MPRN and SN.
-- The Meter may be further defined by the associated TIMESLOT_CODE
FUNCTION GET_METER_ID
	(
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_SERIAL_NUMBER IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIMESLOT_CODE IN VARCHAR2 := NULL,
  	p_GENERATOR_UNITID IN VARCHAR2 := NULL
	) RETURN NUMBER;

FUNCTION GET_METER_ID
	(
    p_MPRN IN VARCHAR2,
    p_SERIAL_NUMBER IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIMESLOT_CODE IN VARCHAR2,
  	p_GENERATOR_UNITID IN VARCHAR2 := NULL
	) RETURN NUMBER;

-- Returns true if the specified message type code corresponds to a supported
-- QH/HH 3XX message type code (341 or 342)
FUNCTION IS_QH_HH_3XX_MESSAGE
	(
    p_MESSAGE_TYPE_CODE IN VARCHAR2
	) RETURN BOOLEAN;

-- Returns true if the specified message type code corresponds to a supported
-- NQH/NHH 3XX message type code (300, 306, 307, 310, 320, 332, etc...)
FUNCTION IS_NQH_NHH_3XX_MESSAGE
	(
    p_MESSAGE_TYPE_CODE IN VARCHAR2
	) RETURN BOOLEAN;

-- Returns TRUE if METER_ID exists
FUNCTION METER_EXISTS
	(
    p_MPRN IN VARCHAR2,
    p_SERIAL_NUMBER IN VARCHAR2
	) RETURN BOOLEAN;

END MM_TDIE_UTIL;
/