CREATE OR REPLACE PACKAGE CDI_LOAD_PROFILE_UI AS

FUNCTION GET_SEASONS_FOR_TEMPLATE(p_TEMPLATE_ID IN NUMBER) RETURN VARCHAR2;

PROCEDURE GET_TYPICAL_DAY_RUN_TEMPLATE(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_TYPICAL_DAY_RUN_TEMPLATE(p_TEMPLATE_ID IN NUMBER, p_IS_SELECTED IN NUMBER);

PROCEDURE SELECT_ALL_TYPICAL_DAYS;

PROCEDURE DESELECT_ALL_TYPICAL_DAYS;

PROCEDURE GET_TYPICAL_DAY_RUN_ACCOUNT
   (
   p_RUN_MODE_ID IN NUMBER,
   p_ACCOUNT_FILTER IN VARCHAR2,
   p_ACCOUNT_FILTER_TYPE_ID IN NUMBER,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE PUT_TYPICAL_DAY_RUN_ACCOUNT(p_ACCOUNT_ID IN NUMBER, p_IS_SELECTED IN NUMBER, p_OLD_IS_SELECTED IN NUMBER);

PROCEDURE GET_TYPICAL_DAY_RUN_PROFILE(p_PROFILE_LIBRARY_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_TYPICAL_DAY_RUN_PROFILE(p_PROFILE_ID IN NUMBER, p_IS_SELECTED IN NUMBER, p_OLD_IS_SELECTED IN NUMBER);

PROCEDURE GET_TYPICAL_DAY_LIBRARY(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_TYPICAL_DAY_PROFILE(p_PROFILE_LIBRARY_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE CALC_TYPICAL_DAY_PROFILE
   (
   p_RUN_MODE_ID IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_TEMPLATES IN VARCHAR2,
   p_ACCOUNTS IN VARCHAR2,
   p_AUTO_APPLY IN NUMBER,
   p_ASSIGN_BEGIN_DATE IN DATE,
   p_LOG_LEVEL IN NUMBER
   );

PROCEDURE CALC_TYPICAL_DAY_PROFILE
   (
   p_TEMPLATES IN VARCHAR2,
   p_PROFILES IN VARCHAR2,
   p_PROFILE_PREFIX IN VARCHAR2,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_LOG_LEVEL IN NUMBER
   );

PROCEDURE RUN_CALC_ACCOUNT_TYPICAL_DAY
   (
   p_RUN_MODE_ID IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_AUTO_APPLY IN NUMBER,
   p_ASSIGN_BEGIN_DATE IN DATE,
   p_MESSAGE OUT VARCHAR2
   );

PROCEDURE RUN_CALC_PROFILE_TYPICAL_DAY
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_PROFILE_PREFIX IN VARCHAR,
   p_MESSAGE OUT VARCHAR2
   );

PROCEDURE ASSIGN_ACCOUNT_REFERENCE(p_MESSAGE OUT VARCHAR2);

PROCEDURE GET_HISTORICAL_PROFILE_LIBRARY(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_HISTORICAL_PROFILE_SUMMARY(p_PROFILE_LIBRARY_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_HOURLY_HISTORICAL_PROFILE
   (
   p_PROFILE_ID IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_DISPLAY_ZERO_LOAD IN NUMBER,
   p_USE_DATE_RANGE IN NUMBER,
   p_INTERVAL OUT VARCHAR2,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE GET_DAILY_HISTORICAL_PROFILE
   (
   p_PROFILE_ID IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_DISPLAY_ZERO_DAYS IN NUMBER,
   p_USE_DATE_RANGE IN NUMBER,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE PUT_DAILY_HISTORICAL_PROFILE
   (
   p_PROFILE_ID IN NUMBER,
   p_POINT_DAY IN DATE,
   p_HR_01 IN NUMBER,
   p_HR_02 IN NUMBER,
   p_HR_03 IN NUMBER,
   p_HR_04 IN NUMBER,
   p_HR_05 IN NUMBER,
   p_HR_06 IN NUMBER,
   p_HR_07 IN NUMBER,
   p_HR_08 IN NUMBER,
   p_HR_09 IN NUMBER,
   p_HR_10 IN NUMBER,
   p_HR_11 IN NUMBER,
   p_HR_12 IN NUMBER,
   p_HR_13 IN NUMBER,
   p_HR_14 IN NUMBER,
   p_HR_15 IN NUMBER,
   p_HR_16 IN NUMBER,
   p_HR_17 IN NUMBER,
   p_HR_18 IN NUMBER,
   p_HR_19 IN NUMBER,
   p_HR_20 IN NUMBER,
   p_HR_21 IN NUMBER,
   p_HR_22 IN NUMBER,
   p_HR_23 IN NUMBER,
   p_HR_24 IN NUMBER
   );

PROCEDURE FILTER_WEATHER_INDEX_LIBRARY(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE FILTER_WEATHER_INDEX_PROFILE(p_PROFILE_LIBRARY_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_WEATHER_INDEX_PROFILE
   (
   p_PROFILE_ID IN NUMBER,
   p_INDEX_LOWER_LIMIT IN NUMBER,
   p_INDEX_UPPER_LIMIT IN NUMBER,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE FILTER_LOAD_PROFILE_LIBRARY(p_FILTER_PROFILE_TYPE IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE FILTER_LOAD_PROFILE(p_FILTER_PROFILE_TYPE IN VARCHAR2, p_FILTER_PROFILE_LIBRARY_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_LOAD_PROFILE_POINT
   (
   p_FILTER_PROFILE_TYPE IN VARCHAR2,
   p_FILTER_PROFILE_ID IN NUMBER,
   p_FILTER_USE_DATE_RANGE IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_INTERVAL OUT VARCHAR2,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE PUT_LOAD_PROFILE_POINT
   (
   p_FILTER_PROFILE_TYPE IN VARCHAR2,
   p_PROFILE_ID IN NUMBER,
   p_POINT_INDEX IN NUMBER,
   p_POINT_DATE IN DATE,
   p_POINT_VAL IN NUMBER
   );

PROCEDURE FILTER_CALENDAR
   (
   p_CALENDAR_FILTER IN VARCHAR2,
   p_FILTER_LIBRARY_ASSIGNMENTS IN NUMBER,
   p_FILTER_PROFILE_ASSIGNMENTS IN NUMBER,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE GET_CALENDAR_PROFILE_LIBRARY(p_FILTER_CALENDAR_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_CALENDAR_PROFILE(p_FILTER_CALENDAR_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_LIBRARY_ASSIGN_CANDIDATES(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_PROFILE_ASSIGN_CANDIDATES(p_PROFILE_LIBRARY_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_CALENDAR_ASSIGNMENT
   (
   p_FILTER_CALENDAR_ID IN NUMBER,
   p_FILTER_USE_DATE_RANGE IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_LABEL_ASSIGNMENT_COVERAGE OUT VARCHAR2,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE PUT_CALENDAR_ASSIGNMENT
   (
   p_ENTRY_CALENDAR_ID IN NUMBER,
   p_ENTRY_LIBRARY_ID IN NUMBER,
   p_ENTRY_PROFILE_ID IN NUMBER,
   p_ENTRY_BEGIN_DATE IN DATE,
   p_ENTRY_END_DATE IN DATE,
   p_ASSIGN_BEGIN_DATE IN DATE,
   p_ASSIGN_END_DATE IN DATE
   );

PROCEDURE CUT_CALENDAR_ASSIGNMENT
   (
   p_ENTRY_CALENDAR_ID IN NUMBER,
   p_ENTRY_LIBRARY_ID IN NUMBER,
   p_ENTRY_PROFILE_ID IN NUMBER,
   p_ASSIGN_BEGIN_DATE IN DATE,
   p_ASSIGN_END_DATE IN DATE
   );

PROCEDURE GET_CALENDAR_ADJUSTMENT
   (
   p_FILTER_CALENDAR_ID IN NUMBER,
   p_FILTER_USE_DATE_RANGE IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_LABEL_ADJUSTMENT_COVERAGE OUT VARCHAR2,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE PUT_CALENDAR_ADJUSTMENT
   (
   p_ENTRY_CALENDAR_ID IN NUMBER,
   p_ENTRY_BEGIN_DATE IN DATE,
   p_ENTRY_END_DATE IN DATE,
   p_ADJUST_BEGIN_DATE IN DATE,
   p_ADJUST_END_DATE IN DATE,
   p_ADJUST_OPERATION IN VARCHAR2,
   p_ADJUST_VALUE IN NUMBER
   );

PROCEDURE CUT_CALENDAR_ADJUSTMENT
   (
   p_ENTRY_CALENDAR_ID IN NUMBER,
   p_ADJUST_BEGIN_DATE IN DATE,
   p_ADJUST_END_DATE IN DATE,
   p_ADJUST_OPERATION IN VARCHAR2
   );

PROCEDURE GET_CALENDAR_MANAGEMENT
   (
   p_CALENDAR_MANAGEMENT_TYPE IN VARCHAR2,
   p_FILTER_CALENDAR_ID IN NUMBER,
   p_LABEL_CALENDAR_NAME OUT VARCHAR2,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE PUT_CALENDAR_MANAGEMENT
   (
   p_CALENDAR_MANAGEMENT_TYPE IN VARCHAR2,
   p_CALENDAR_MANAGEMENT_ID   IN NUMBER,
   p_ENTRY_CALENDAR_ID        IN NUMBER,
   p_INCLUDE_ENTRY            IN NUMBER,
   p_PROFILE_LIBRARY_ID       IN NUMBER,
   p_PROFILE_ID               IN NUMBER,   
   p_ADJUSTMENT_OPERATION     IN VARCHAR2,
   p_ADJUSTMENT_VALUE         IN NUMBER,
   p_MONTH_JAN IN NUMBER,
   p_MONTH_FEB IN NUMBER,
   p_MONTH_MAR IN NUMBER,
   p_MONTH_APR IN NUMBER,
   p_MONTH_MAY IN NUMBER,
   p_MONTH_JUN IN NUMBER,
   p_MONTH_JUL IN NUMBER,
   p_MONTH_AUG IN NUMBER,
   p_MONTH_SEP IN NUMBER,
   p_MONTH_OCT IN NUMBER,
   p_MONTH_NOV IN NUMBER,
   p_MONTH_DEC IN NUMBER,
   p_DAY_MON   IN NUMBER,
   p_DAY_TUE   IN NUMBER,
   p_DAY_WED   IN NUMBER,
   p_DAY_THU   IN NUMBER,
   p_DAY_FRI   IN NUMBER,
   p_DAY_SAT   IN NUMBER,
   p_DAY_SUN   IN NUMBER,
   p_MESSAGE  OUT VARCHAR2
   );

PROCEDURE CUT_CALENDAR_MANAGEMENT(p_CALENDAR_MANAGEMENT_ID IN NUMBER);

PROCEDURE APPLY_CALENDAR_ASSIGNMENTS
   (
   p_ENTRY_CALENDAR_ID IN NUMBER,
   p_APPLY_BEGIN_DATE IN DATE,
   p_APPLY_END_DATE IN DATE,
   p_APPLY_DELETE IN NUMBER,
   p_MESSAGE OUT VARCHAR2
   );

PROCEDURE APPLY_CALENDAR_ADJUSTMENTS
   (
   p_ENTRY_CALENDAR_ID IN NUMBER,
   p_APPLY_BEGIN_DATE IN DATE,
   p_APPLY_END_DATE IN DATE,
   p_APPLY_DELETE IN NUMBER,
   p_MESSAGE OUT VARCHAR2
   );

PROCEDURE GENERATE_SETTLEMENT_PROFILES(p_BEGIN_DATE IN DATE DEFAULT NULL, p_END_DATE IN DATE DEFAULT NULL);

PROCEDURE FILTER_ACCOUNT(p_ACCOUNT_FILTER IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_PROFILE_ACCOUNT_REFERENCE(p_PROFILE_ID IN NUMBER, p_FILTER_ACCOUNT_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_PROFILE_ACCOUNT_REFERENCE
   (
   p_PROFILE_NAME IN VARCHAR2,
   p_ACCOUNT_NAME IN VARCHAR2,
   p_REFERENCE_PROFILE_ID IN NUMBER,
   p_REFERENCE_ACCOUNT_ID IN NUMBER,
   p_IS_ACCOUNT_REFERENCE IN NUMBER,
   p_MESSAGE OUT VARCHAR2
   );

PROCEDURE GET_LOCAL_PROFILE(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_SEASON_DAY_TYPE(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_WEATHER_STATION(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_PROFILE_LIBRARY(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_LOCAL_PROFILE_POINT
   (
   p_PROFILE_IDENTIFIER IN VARCHAR2,
   p_STATION_ID IN NUMBER,
   p_CURSOR OUT GA.REFCURSOR
   );

PROCEDURE EXPORT_LOAD_PROFILE_LIST(p_PROFILE_TYPE IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR, p_LABEL OUT VARCHAR2);

PROCEDURE EXPORT_LOAD_PROFILE
   (
   p_PROFILE_TYPE          IN VARCHAR2,  
   p_ENTITY_LIST           IN VARCHAR2,
   p_ENTITY_LIST_DELIMITER IN VARCHAR2,
   p_FILE                 OUT CLOB,
   p_STATUS               OUT NUMBER,
   p_MESSAGE              OUT VARCHAR2
   );

PROCEDURE GET_PROFILE_LIBRARY_ENTITY(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_PROFILE_LIBRARY_ENTITY
   (
   p_PROFILE_LIBRARY_ID    IN NUMBER,
   p_PROFILE_LIBRARY_NAME  IN VARCHAR2,
   p_PROFILE_LIBRARY_ALIAS IN VARCHAR2,
   p_PROFILE_LIBRARY_DESC  IN VARCHAR2
   );

PROCEDURE CUT_PROFILE_LIBRARY_ENTITY(p_PROFILE_LIBRARY_ID IN NUMBER);

PROCEDURE GET_PROFILE_LIBRARY_ASSIGNMENT(p_PROFILE_LIBRARY_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_PROFILE_LIBRARY_ASSIGNMENT(p_PROFILE_LIBRARY_ID IN NUMBER, p_PROFILE_ID IN NUMBER);

PROCEDURE CUT_PROFILE_LIBRARY_ASSIGNMENT(p_PROFILE_ID IN NUMBER);

END CDI_LOAD_PROFILE_UI;
/
