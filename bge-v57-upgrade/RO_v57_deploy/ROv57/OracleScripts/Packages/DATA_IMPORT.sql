CREATE OR REPLACE PACKAGE DATA_IMPORT IS
-- $Revision: 1.16 $

DEFAULT_DATE_FORMAT VARCHAR2(64);

MARKET_PRICE_IMPORT_OPTION CONSTANT VARCHAR2(32) := 'Market Prices';
ACCOUNT_DATA_IMPORT_OPTION CONSTANT VARCHAR2(32) := 'Account Data';
INTVL_METERD_USAGE_DATA CONSTANT VARCHAR2(32) := 'Interval Metered Usage';
INTVL_METERD_USAGE_DATA_EXT CONSTANT VARCHAR2(50) := 'Interval Metered Usage -- External Identifiers';
NON_INTVL_METERD_USAGE_DATA CONSTANT VARCHAR2(32) := 'Non-Interval Metered Usage';
NON_INTVL_MTR_USG_DATA_EXT CONSTANT VARCHAR2(60) := 'Non-Interval Metered Usage -- External Identifiers';
WEATHER_DATA_IMPORT_OPTION CONSTANT VARCHAR2(32) := 'Weather (Rows)';
LOAD_PROFILE_IMPORT_OPTION CONSTANT VARCHAR2(32) := 'Load Profile';
TX_NETWORK_IMPORT_OPTION CONSTANT VARCHAR2(32) := 'Transmission Network';
INTVL_METERED_CHANNEL_DATA CONSTANT VARCHAR2(32) := 'Interval Metered Channel Data';
INTVL_METERED_CHANNEL_DATA_EXT CONSTANT VARCHAR2(64) := 'Interval Metered Channel Data -- External Identifiers';
ACCOUNT_SYNC_OPTION CONSTANT VARCHAR2(64) := 'Account Sync';
ACCOUNT_SYNC_FULL_OPTION CONSTANT VARCHAR2(64) := 'Account Sync (Full)';
NON_INTVL_MTR_DATA_SYNC_OPTION CONSTANT VARCHAR2(32) := 'Non-Interval Metered Data Sync';
SERVICE_LOAD_SYNC_OPTION CONSTANT VARCHAR2(64) := 'Interval Metered Data Sync';

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- MAIN PROCEDURE CALLED BY STANDARD DATA IMPORTS
-- IT CALLS THE APPROPRIATE IMPORT BASED ON THE
-- SELECTED ENTITY TYPE
PROCEDURE STANDARD_IMPORT
	(
	p_BEGIN_DATE DATE,
    p_END_DATE DATE,
	p_IMPORT_FILE IN CLOB,
	p_IMPORT_FILE_PATH IN VARCHAR2,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN VARCHAR2,
	p_DELIMITER IN VARCHAR2,
	p_PROCESS_STATUS OUT NUMBER,
	p_PROCESS_ID OUT VARCHAR2,
    p_MESSAGE OUT VARCHAR2,
    p_TRACE_ON IN NUMBER := 0
	);

-- IMPORT_DATE ATTEMPST TO PARSE THE GIVEN DATE_STRING INTO A DATE USING THE
-- FORMAT GIVEN IF THE DATE CAN'T BE PARSED IMPORT_DATE LOGS AN ERROR
-- (USING IMPORT_INFO W/ p_LINE AS AN ATTACHMENT.), IT THEN SETS p_SUCCESS TO FALSE AND
-- RETURNS NULL
FUNCTION IMPORT_DATE
	(
	p_DATE_STRING IN VARCHAR2,
	p_DATE_FORMAT IN VARCHAR2,
	p_IMPORT_INFO IN VARCHAR2,
	p_SUCCESS IN OUT BOOLEAN
	) RETURN DATE;

FUNCTION IMPORT_DATE_TIME
	(
	p_DATE_STRING IN VARCHAR2,
	p_DATE_FORMAT IN VARCHAR2,
	p_TIME_FORMAT IN VARCHAR2,
	p_IMPORT_INFO IN VARCHAR2,
	p_SUCCESS IN OUT BOOLEAN
	) RETURN DATE;

-- IMPORT_NUMBER ATTEMPTS TO PARSE THE GIVEN NUM_STRING INTO A NUMBER
-- IF THE NUMBER CAN'T BE PARSED IMPORT_NUMBER LOGS AN ERROR (USING IMPORT_INFO
-- W/ p_LINE AS AN ATTACHMENT), IT THEN SET p_SUCESS TO FALSE AND RETURN NULL
FUNCTION IMPORT_NUMBER
	(
	p_NUM_STRING IN VARCHAR2,
	p_IMPORT_INFO IN VARCHAR2,
	p_SUCCESS IN OUT BOOLEAN
	) RETURN NUMBER;

PROCEDURE STANDARD_DATA_IMPORT_OPTIONS
	(
	p_CURSOR OUT GA.REFCURSOR,
	p_LABEL OUT VARCHAR
	);

PROCEDURE LOG_IMPORT_ERROR
	(
	p_EVENT_TEXT IN VARCHAR2,
	p_SUCCESS IN OUT BOOLEAN,
	p_PROC_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL,
	p_SQLERRM IN VARCHAR2 := NULL
	);

PROCEDURE LOG_IMPORT_WARN
	(
	p_EVENT_TEXT IN VARCHAR2,
	p_PROC_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL
	);

PROCEDURE PUT_CALENDAR_PROFILE
	(
	p_CALENDAR_ID IN NUMBER,
	p_PROFILE_ID IN NUMBER
	);

PROCEDURE PUT_CALENDAR_PROFILE_LIBRARY
	(
	p_CALENDAR_ID IN NUMBER,
	p_PROFILE_LIBRARY_ID IN NUMBER
	);

-- AGGREGATES A GIVEN METER
PROCEDURE AGGREGATE_CHANNEL_DATA
	(
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_SERVICE_DATE IN DATE,
	p_METER_CODE IN CHAR,
	p_INTERVAL_ABBREVIATION IN VARCHAR2,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SUCCESS IN OUT BOOLEAN,
	p_DELETE_FIRST IN NUMBER := 0,
	p_UNIT_OF_MEASURE IN VARCHAR2 := GA.DEFAULT_UNIT_OF_MEASUREMENT,
	p_SCALE_FACTOR IN NUMBER := 1.0,
    p_SKIP_PROCESSING_LOSS_FACTOR IN BOOLEAN:= FALSE
	);

$if $$UNIT_TEST_MODE = 1 $then

PROCEDURE SERVICE_LOAD_SYNC_IMPORT
	(
	p_LINE      IN VARCHAR2,
	p_DELIMITER IN VARCHAR2,
	p_SUCCESS   IN OUT BOOLEAN
	);

PROCEDURE LOAD_WRF_PROFILE
	(
	p_LINE      IN VARCHAR2,
	p_DELIMITER IN VARCHAR2,
	p_SUCCESS   IN OUT BOOLEAN
	);

PROCEDURE TX_NETWORK_IMPORT
	(
	p_LINE      IN VARCHAR2,
	p_DELIMITER IN VARCHAR2,
	p_SUCCESS   IN OUT BOOLEAN
	);  
$end

END DATA_IMPORT;
/
