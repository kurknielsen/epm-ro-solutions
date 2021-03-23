CREATE OR REPLACE PACKAGE SP AS
--Revision $Revision: 1.115 $

-- SPECIAL IO HANDLING PACKAGE.

FUNCTION WHAT_VERSION RETURN VARCHAR;

-- USED BY PUT_LOAD_FORECAST_SCENARIO TO INDICATE THAT THE
-- METHOD SHOULD IGNORE THE ACCOUNT_STATUS_LIST
IGNORE_LIST CONSTANT VARCHAR2(16) := 'IGNORE_LIST';

PROCEDURE GET_HOLIDAY_OBSERVANCE
	(
	p_HOLIDAY_ID IN NUMBER,
	p_HOLIDAY_YEAR IN NUMBER,
	p_HOLIDAY_DATE OUT DATE
	);

PROCEDURE PUT_HOLIDAY_OBSERVANCE
	(
	p_HOLIDAY_ID IN NUMBER,
	p_HOLIDAY_YEAR IN NUMBER,
	p_HOLIDAY_DATE IN DATE
	);

PROCEDURE PUT_PHONE_NUMBER
	(
	o_OID OUT NUMBER,
	p_CONTACT_ID IN NUMBER,
	p_PHONE_TYPE IN VARCHAR2,
	p_PHONE_NUMBER IN VARCHAR2,
	p_OLD_PHONE_TYPE IN VARCHAR2
	);

PROCEDURE PUT_ENTITY_ATTRIBUTE
	(
	o_OID OUT NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ATTRIBUTE_NAME IN VARCHAR2,
	p_ATTRIBUTE_ID IN NUMBER,
	p_ATTRIBUTE_TYPE IN VARCHAR2,
	p_ATTRIBUTE_SHOW IN NUMBER
	);

PROCEDURE GET_ENTITY_ATTRIBUTE
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ATTRIBUTE_NAME IN VARCHAR2,
	p_ATTRIBUTE_ID OUT NUMBER,
	p_ATTRIBUTE_TYPE OUT VARCHAR2,
	p_ATTRIBUTE_SHOW OUT NUMBER
	);

PROCEDURE PUT_TEMPORAL_ENTITY_ATTRIBUTE
	(
	p_OWNER_ENTITY_ID IN NUMBER,
	p_ATTRIBUTE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ATTRIBUTE_VAL IN VARCHAR,
	p_OLD_OWNER_ENTITY_ID IN NUMBER,
	p_OLD_ATTRIBUTE_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_SP_TIME_ZONE
	(
	p_SERVICE_POINT_ID IN NUMBER,
	p_TIME_ZONE OUT VARCHAR
	);

PROCEDURE CREATE_US_HOLIDAYS
	(
	p_FROM_YEAR IN NUMBER,
	p_TO_YEAR IN NUMBER
	);

PROCEDURE ENTITY_ATTRIBUTE_ASSIGNMENTS
	(
	p_ENTITY_DOMAIN_ALIAS IN VARCHAR,
	p_ATTRIBUTE_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE ENTITY_ATTRIBUTES_BY_DOMAIN
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE CLEAR_PATH_PROVIDER
        (
        p_PATH_ID IN NUMBER
        );

PROCEDURE CLEAR_TRANSACTION_PATH
        (
        p_TRANSACTION_ID IN NUMBER
        );

PROCEDURE GET_PATH_PROVIDERS
        (
        p_PATH_ID IN NUMBER,
        p_STATUS OUT NUMBER,
        p_CURSOR IN OUT GA.REFCURSOR
        );

PROCEDURE GET_TRANSACTION_PATHS
        (
        p_TRANSACTION_ID IN NUMBER,
        p_STATUS OUT NUMBER,
        p_CURSOR IN OUT GA.REFCURSOR
        );

PROCEDURE PUT_PATH_PROVIDER
        (
        p_PATH_ID IN NUMBER,
        p_LEG_NBR IN NUMBER,
        p_CA_ID IN NUMBER,
        p_TP_ID IN NUMBER,
        p_PSE_ID IN NUMBER,
        p_TP_PRODUCT_CODE IN VARCHAR2,
        p_TP_PATH_NAME IN VARCHAR2,
        p_TP_ASSIGNMENT_REF IN VARCHAR2,
        p_TP_PRODUCT_LEVEL IN VARCHAR2,
        p_MISC_INFO IN VARCHAR2,
        p_MISC_REF IN VARCHAR2
        );

PROCEDURE PUT_TRANSACTION_PATH
        (
        p_TRANSACTION_ID IN NUMBER,
        p_LEG_NBR IN NUMBER,
        p_CA_ID IN NUMBER,
        p_TP_ID IN NUMBER,
        p_PSE_ID IN NUMBER,
        p_TP_PRODUCT_CODE IN VARCHAR2,
        p_TP_PATH_NAME IN VARCHAR2,
        p_TP_ASSIGNMENT_REF IN VARCHAR2,
        p_TP_PRODUCT_LEVEL IN VARCHAR2,
        p_MISC_INFO IN VARCHAR2,
        p_MISC_REF IN VARCHAR2
        );

PROCEDURE GET_VERSION_LIST
	(
	p_DOMAIN_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_VERSION_STATUSES
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_VERSION
	(
	o_OID OUT NUMBER,
	p_VERSION_DOMAIN IN VARCHAR2,
	p_VERSION_NAME IN VARCHAR2,
	p_VERSION_ALIAS IN VARCHAR2,
	p_VERSION_DESC IN VARCHAR2,
	p_VERSION_ID IN NUMBER,
	p_AS_OF_DATE IN DATE,
	p_UNTIL_DATE IN DATE,
	p_VERSION_STATUS IN VARCHAR2,
	p_VERSION_REQUESTOR IN VARCHAR2
	);

PROCEDURE VERSIONS
	(
	p_VERSION_DOMAIN IN VARCHAR2,
	p_FROM_DATE IN DATE,
	p_TO_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_CURRENT_VERSION
    (
	p_VERSION_DOMAIN IN VARCHAR2,
	p_VERSION_NAME OUT VARCHAR2,
	p_VERSION_ID OUT NUMBER,
	p_AS_OF_DATE OUT DATE,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_VERSIONID_FROM_ASOFDATE
	(
	p_VERSION_DOMAIN IN VARCHAR2,
	p_AS_OF_DATE IN OUT DATE,
	p_UNTIL_DATE OUT DATE,
	p_VERSION_ID OUT NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE FIND_ACCOUNTS
	(
	p_SEARCH_COLUMN IN VARCHAR2,
	p_SEARCH_STRING IN VARCHAR2,
	p_MATCH_CASE IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE DATA_EXCHANGE_TYPES
	(
	p_MODULE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE RTO_ROLLUPS
	(
	p_ROLLUP_CATEGORY IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_SYSTEM_DICTIONARY_VALUE
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_VALUE OUT VARCHAR2
	);

PROCEDURE SYSTEM_DICTIONARY_VALUES
	(
	p_MODEL_ID IN NUMBER,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE SYSTEM_DICTIONARY_VALUES_E
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_SYSTEM_DICTIONARY_VALUE
	(
	p_MODEL_ID IN NUMBER,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_VALUE IN VARCHAR,
	p_STATUS OUT VARCHAR
	);

PROCEDURE PUT_SYSTEM_DICTIONARY_VALUE_E
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_SETTING_NAME IN VARCHAR,
	p_VALUE IN VARCHAR,
	p_STATUS OUT VARCHAR
	);

PROCEDURE PUT_LINK
	(
	p_LINK_NAME IN VARCHAR,
	p_LINK_URL IN VARCHAR,
	p_OLD_LINK_NAME IN VARCHAR,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_DST_OPTIONS
	(
	p_DST_SPRING_AHEAD_OPTION OUT VARCHAR,
	p_DST_FALL_BACK_OPTION OUT VARCHAR
	);

PROCEDURE CASE_LABELS
	(
	p_CASE_CATEGORY IN VARCHAR2,
	p_INCLUDE_ALL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);
    
PROCEDURE CASE_LABELS_FILTERED
	(
	p_CASE_CATEGORY IN VARCHAR2,
	p_INCLUDE_ALL IN NUMBER,
    p_HIDE_NOT_ASSIGNED IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE SCENARIOS
	(
	p_SCENARIO_CATEGORY IN VARCHAR2,
	p_INCLUDE_ALL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE ACCOUNT_STATUSES
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

FUNCTION GET_SCENARIO_STATUS_LIST
	(
	p_SCENARIO_ID IN NUMBER
	) RETURN VARCHAR2;

PROCEDURE GET_LOAD_FORECAST_SCENARIO
	(
	p_SCENARIO_ID IN NUMBER,
	p_WEATHER_CASE_ID OUT NUMBER,
	p_AREA_LOAD_CASE_ID OUT NUMBER,
	p_ENROLLMENT_CASE_ID OUT NUMBER,
	p_CALENDAR_CASE_ID OUT NUMBER,
	p_USAGE_FACTOR_CASE_ID OUT NUMBER,
	p_GROWTH_FACTOR_CASE_ID OUT NUMBER,
	p_LOSS_FACTOR_CASE_ID OUT NUMBER,
	p_RUN_MODE OUT NUMBER,
	p_SCENARIO_USE_DAY_TYPE OUT NUMBER,
	p_ACCOUNT_STATUS_LIST OUT VARCHAR,
	p_STATUS OUT NUMBER
	);

PROCEDURE PUT_LOAD_FORECAST_SCENARIO
	(
	p_SCENARIO_ID IN NUMBER,
	p_WEATHER_CASE_ID IN NUMBER,
	p_AREA_LOAD_CASE_ID IN NUMBER,
	p_ENROLLMENT_CASE_ID IN NUMBER,
	p_CALENDAR_CASE_ID IN NUMBER,
	p_USAGE_FACTOR_CASE_ID IN NUMBER,
	p_GROWTH_FACTOR_CASE_ID IN NUMBER,
	p_LOSS_FACTOR_CASE_ID IN NUMBER,
	p_RUN_MODE IN NUMBER,
	p_SCENARIO_USE_DAY_TYPE IN NUMBER,
	p_ACCOUNT_STATUS_LIST IN VARCHAR,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_PHONE_NUMBER
    (
	p_CONTACT_ID IN NUMBER,
	p_PHONE_TYPE IN VARCHAR,
	p_PHONE_NUMBER OUT VARCHAR
	);

PROCEDURE GET_SYSTEM_LABELS
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_INCLUDE_HIDDEN IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);
--------------------------------------------------------------------------------
-- MCR 2009Oct07 10:18a
-- This procedure is only a wrapper for backwards compatibility no new code
-- should reference this one.  Call the one with the p_IGNORE_POSITION parameter.
-- This one will assume 0 for that parameter.
PROCEDURE GET_SYSTEM_LABEL_VALUES
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);
--------------------------------------------------------------------------------
-- Overloaded procedure call, the older definition will
-- be a pass through for backwards compatibility
PROCEDURE GET_SYSTEM_LABEL_VALUES_EX (
	p_MODEL_ID        IN NUMBER,
	p_MODULE          IN VARCHAR,
	p_KEY1            IN VARCHAR,
	p_KEY2            IN VARCHAR,
	p_KEY3            IN VARCHAR,
	p_STATUS             OUT NUMBER,
	p_CURSOR          IN OUT GA.REFCURSOR,
   p_IGNORE_POSITION IN NUMBER
	);

    PROCEDURE GET_SYSTEM_LABEL_VALUES_ALL
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);


PROCEDURE PUT_SYSTEM_LABELS
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_VALUE IN VARCHAR,
	p_POSITION IN NUMBER,
	p_IS_DEFAULT IN NUMBER,
	p_IS_HIDDEN IN NUMBER,
	p_STATUS OUT VARCHAR
	);

PROCEDURE PUT_SYSTEM_LABELS_WITH_CODE
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_VALUE IN VARCHAR,
	p_POSITION IN NUMBER,
	p_IS_DEFAULT IN NUMBER,
	p_IS_HIDDEN IN NUMBER,
	p_CODE IN VARCHAR,
	p_STATUS OUT VARCHAR
	);

PROCEDURE ENSURE_SYSTEM_LABELS
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_VALUE IN VARCHAR,
	p_POSITION IN NUMBER,
	p_IS_DEFAULT IN NUMBER,
	p_IS_HIDDEN IN NUMBER
	);

PROCEDURE GET_ENTITY_CONFIG_NODES
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_INCLUDE_HIDDEN IN NUMBER,
	p_OPTIONS IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_ENTITY_CONFIG_DICTIONARY
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_ENTITY_CONFIG_DICTIONARY
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_VALUE IN VARCHAR,
	p_STATUS OUT VARCHAR
	);

PROCEDURE  GET_MAX_COLUMN_WIDTH
	(
	p_TABLE_NAME IN VARCHAR,
	p_COLUMN_NAME IN VARCHAR,
    p_COLUMN_WIDTH OUT NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_CONTRACT_TEMPLATE
	(
    p_CONTRACT_ID IN NUMBER,
    p_PARAMETER_STRING OUT VARCHAR2,
    p_STATUS OUT NUMBER
    );

PROCEDURE GET_DEFAULT_SYSTEM_LABEL
	(
	p_MODEL_ID IN NUMBER,
    p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_MATCH_CASE IN NUMBER := 0,
	p_VALUE OUT VARCHAR2
    );

PROCEDURE GET_DEFAULT_SYSTEM_LABEL_CODE
	(
	p_MODEL_ID IN NUMBER,
    p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_MATCH_CASE IN NUMBER := 0,
	p_CODE OUT VARCHAR2
	);

PROCEDURE GET_SYSTEM_LABEL_VALUE_BY_CODE
	(
	p_MODEL_ID IN NUMBER,
    p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_CODE IN VARCHAR2,
	p_VALUE OUT VARCHAR2
	);

PROCEDURE GET_CRYSTAL_RPT_LIST_BY_VIEW
	(
    p_SYSTEM_VIEW_ID IN NUMBER,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    );

PROCEDURE GET_CRYSTAL_TEMPLATE_TYPE_STAT
	(
    p_REPORT_ID IN NUMBER,
	p_TEMPLATE_TYPE IN VARCHAR2,
    p_EXISTS OUT NUMBER,
    p_STATUS OUT NUMBER
	);

PROCEDURE GET_CRYSTAL_REPORT_LIST
	(
    p_MODEL_ID IN NUMBER,
    p_MODULE IN VARCHAR2,
    p_REPORT_TYPE IN VARCHAR2,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    );

PROCEDURE GET_CRYSTAL_REPORT_FILE
	(
    p_REPORT_ID IN NUMBER,
	p_TEMPLATE_TYPE IN VARCHAR2,
    p_GET_BLOB OUT BLOB,
    p_STATUS OUT NUMBER
    );

PROCEDURE GET_CRYSTAL_REPORT_TIMESTAMP
	(
    p_REPORT_ID IN NUMBER,
	p_TEMPLATE_TYPE IN VARCHAR2,
    p_TIMESTAMP OUT DATE,
    p_STATUS OUT NUMBER
    );

PROCEDURE PUT_CRYSTAL_REPORT_FILE
	(
    p_REPORT_ID IN NUMBER,
	p_TEMPLATE_TYPE IN VARCHAR2,
    P_CRYSTAL_REPORT_FILE IN BLOB,
    p_STATUS OUT NUMBER
    );

PROCEDURE IS_CRYSTAL_REPORT_FILE
	(
    p_REPORT_ID IN NUMBER,
    p_IS_CRYSTAL OUT NUMBER
    );

PROCEDURE IS_CRYSTAL_REPORT
	(
    p_REPORT_ID IN NUMBER,
    p_IS_CRYSTAL OUT NUMBER
    );

PROCEDURE GET_REPORT_TIMESTAMP
	(
    p_REPORT_ID IN VARCHAR2,
    p_TIMESTAMP OUT DATE,
    p_STATUS OUT NUMBER
    );

PROCEDURE GET_REPORT_TEMPLATE
	(
    p_REPORT_ID IN VARCHAR2,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    );

PROCEDURE PUT_REPORT_TEMPLATE
	(
    p_REPORT_ID IN VARCHAR2,
    p_DELETE_FIRST IN NUMBER,
    p_DATA IN VARCHAR,
    p_STATUS OUT NUMBER
    );

PROCEDURE REMOVE_CRYSTAL_REPORT_FILE
	(
    p_REPORT_ID IN NUMBER,
	p_TEMPLATE_TYPE IN VARCHAR2,
    p_STATUS OUT NUMBER
    );

PROCEDURE REMOVE_REPORT_TEMPLATE
	(
    p_REPORT_ID IN VARCHAR2,
    p_STATUS OUT NUMBER
    );

PROCEDURE CHECK_SYSTEM_DATE_TIME
	(
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DATE IN DATE := SYSDATE,
	p_END_DATE IN DATE := SYSDATE
	);

PROCEDURE SYSTEM_SETTINGS_TREE
	(
	p_CURSOR IN OUT GA.REFCURSOR,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_ALL_DICTIONARY_SETTINGS
	(
	p_CURSOR IN OUT GA.REFCURSOR,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_ALL_LABELS
	(
	p_CURSOR IN OUT GA.REFCURSOR,
	p_STATUS OUT NUMBER
	);

PROCEDURE PUT_SYSTEM_DICTIONARY
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_VALUE IN VARCHAR2,
	p_OLD_MODULE IN VARCHAR2,
	p_OLD_KEY1 IN VARCHAR2,
	p_OLD_KEY2 IN VARCHAR2,
	p_OLD_KEY3 IN VARCHAR2,
	p_OLD_SETTING_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE REMOVE_SYSTEM_DICTIONARY
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE PUT_SYSTEM_LABEL
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_POSITION IN NUMBER,
	p_VALUE IN VARCHAR2,
	p_CODE IN VARCHAR2,
	p_IS_DEFAULT IN NUMBER,
	p_IS_HIDDEN IN NUMBER,
	p_OLD_MODULE IN VARCHAR2,
	p_OLD_KEY1 IN VARCHAR2,
	p_OLD_KEY2 IN VARCHAR2,
	p_OLD_KEY3 IN VARCHAR2,
	p_OLD_POSITION IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE REMOVE_SYSTEM_LABEL
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_POSITION IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_USER_PREFERENCE
	(
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_VALUE OUT VARCHAR2
	);

PROCEDURE GET_USER_PREFERENCES
	(
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_USER_PREFERENCE
	(
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_VALUE IN VARCHAR2,
	p_OLD_MODULE IN VARCHAR2,
	p_OLD_KEY1 IN VARCHAR2,
	p_OLD_KEY2 IN VARCHAR2,
	p_OLD_KEY3 IN VARCHAR2,
	p_OLD_SETTING_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE PUT_USER_PREFERENCE_VALUE
	(
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_VALUE IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE REMOVE_USER_PREFERENCE
	(
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_SETTING_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE PUT_FILTER_PRESET
	(
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_VALUE IN VARCHAR2,
	p_OLD_MODULE IN VARCHAR2,
	p_OLD_KEY1 IN VARCHAR2,
	p_OLD_KEY2 IN VARCHAR2,
	p_OLD_VALUE IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE REMOVE_FILTER_PRESET
	(
	p_MODULE IN VARCHAR2,
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_VALUE IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE GET_TIME_ZONE_LIST
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_TIME_ZONE
	(
    p_TIME_ZONE OUT VARCHAR2
	);

PROCEDURE GET_DEFAULT_TIME_ZONE
	(
	p_TIME_ZONE OUT VARCHAR2
	);

PROCEDURE PUT_TIME_ZONE
	(
    p_TIME_ZONE IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE FALL_BACK_DATE
	(
	p_DATE IN DATE,
	p_FALL_BACK_DATE OUT DATE
	);

PROCEDURE SPRING_AHEAD_DATE
	(
	p_DATE IN DATE,
	p_SPRING_AHEAD_DATE OUT DATE
	);

PROCEDURE GET_DATABROWSER_DST_CONFIG
	(
	p_INTERVAL IN VARCHAR2,
	p_INTERVAL_NAME OUT VARCHAR2,
	p_INTERVAL_NUM OUT NUMBER,
	p_CONFIG_NAME OUT VARCHAR2,
	p_FALL_BACK_HOUR OUT NUMBER,
	p_SPRING_AHEAD_HOUR OUT NUMBER
	);

PROCEDURE IS_DST
	(
	p_TIME_ZONE IN VARCHAR2,
	p_IS_DST OUT NUMBER,
	p_STATUS OUT NUMBER
	);

-- Retrieve all message definitions
PROCEDURE GET_MESSAGE_DEFINITIONS
	(
	p_MESSAGE_TYPE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Retrieve the list of all message types currently in use
PROCEDURE LIST_MESSAGE_TYPES
	(
	p_INCLUDE_ALL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Save a message definition. If p_MESSAGE_NUMBER is NULL, then add a new message.
PROCEDURE PUT_MESSAGE_DEFINITION
	(
	p_MESSAGE_TYPE IN VARCHAR2,
	p_MESSAGE_NUMBER IN NUMBER,
	p_MESSAGE_IDENT	IN VARCHAR2,
	p_MESSAGE_TEXT IN VARCHAR2,
	p_MESSAGE_DESC IN VARCHAR2,
	p_MESSAGE_SOLUTION IN VARCHAR2
	);
-- Delete a message definition.
PROCEDURE REMOVE_MESSAGE_DEFINITION
	(
	p_MESSAGE_ID IN NUMBER
	);

PROCEDURE GET_SCHEDULE_TEMPLATES
    (
    p_STATUS OUT NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

FUNCTION GET_SCHEDULE_DATES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_TEMPLATE IN VARCHAR,
	p_BEGIN_HOUR IN NUMBER,
	p_END_HOUR IN NUMBER,
	p_INCLUDE_HOLIDAYS IN NUMBER,
	p_INTERVAL IN VARCHAR2, -- 5 Minute,10 Minute,15 Minute,30 Minute,Hour,Day,Week,Month,Quarter,Year
	p_USE_SCHEDULING_DATES IN NUMBER := 1,
	p_EDC_ID IN NUMBER := NULL -- used for determining which holiday set to use
	)
RETURN DATE_COLLECTION PIPELINED;

FUNCTION GET_CURRENT_USER_EMAIL_ADDR RETURN VARCHAR2;

FUNCTION SYSTEM_LABEL_CONTAINS
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_LABEL_VALUE IN VARCHAR2,
	p_IGNORE_CASE IN BOOLEAN := FALSE
	) RETURN BOOLEAN;

PROCEDURE CHECK_TEMPLATE_DATES
	(
	p_TEMPLATE_ID IN NUMBER,
	p_HOLIDAY_SET_ID IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	);

PROCEDURE CHECK_TEMPLATE_DATES
	(
	p_TEMPLATE_ID IN NUMBER_COLLECTION,
	p_HOLIDAY_SET_ID IN NUMBER_COLLECTION,
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	);

p_STATUS NUMBER;
g_ALL_STRING VARCHAR(16) := '<ALL>';
g_TIME_ZONE_PREFERENCE_SETTING VARCHAR2(12) := 'AppTimeZone';

g_DEFAULT_TEMPLATE_TYPE VARCHAR2(16) := '<Default>';

END SP;
/