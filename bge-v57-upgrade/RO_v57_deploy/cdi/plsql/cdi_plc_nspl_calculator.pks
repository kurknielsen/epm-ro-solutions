CREATE OR REPLACE PACKAGE CDI_PLC_NSPL_CALCULATOR AS

PROCEDURE SUBMIT_BACKGROUND_JOB(p_TASK_NAME IN VARCHAR2, p_ANCILLARY_SERVICE_ID IN NUMBER, p_PLAN_YEAR IN VARCHAR2, p_MESSAGE OUT VARCHAR2);

PROCEDURE GET_TOLERANCE_FILTER(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_VOLTAGE_FILTER(p_ANCILLARY_SERVICE_ID IN NUMBER, p_RATE_CLASS IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_RATE_CLASS_FILTER(p_ANCILLARY_SERVICE_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_TAG_FILTER(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_PLAN_YEARS(p_ANCILLARY_SERVICE_ID IN NUMBER, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_ANCILLARY_SERVICE_FILTER(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_PLC_NSPL_PEAK(p_ANCILLARY_SERVICE_ID IN NUMBER, p_PLAN_YEAR IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_PLC_NSPL_PEAK
   (
   p_ANCILLARY_SERVICE_ID IN NUMBER,
   p_PLAN_YEAR            IN VARCHAR2,
   p_AREA_ID              IN NUMBER,
   p_PEAK_DAY             IN DATE,
   p_PEAK_HOUR            IN SMALLINT,
   p_PEAK_VALUE           IN NUMBER,
   p_ENTRY_ROWID          IN VARCHAR2
   );

PROCEDURE CUT_PLC_NSPL_PEAK
   (
   p_ANCILLARY_SERVICE_ID IN NUMBER,
   p_AREA_ID              IN NUMBER,
   p_BEGIN_DATE           IN DATE,
   p_END_DATE             IN DATE,
   p_PEAK_DAY             IN DATE,
   p_PEAK_HOUR            IN SMALLINT
   );

PROCEDURE GET_STATISTICS
   (
   p_ANCILLARY_SERVICE_ID IN NUMBER,
   p_RATE_CLASS           IN VARCHAR2,
   p_VOLTAGE_LEVEL        IN VARCHAR2,
   p_TOLERANCE            IN NUMBER,
   p_STATUS              OUT NUMBER,
   p_MESSAGE             OUT VARCHAR2,
   p_CURSOR              OUT GA.REFCURSOR
   );

PROCEDURE GET_STATISTICS_DETAIL
   (
   p_ANCILLARY_SERVICE_ID IN NUMBER,
   p_RATE_CLASS           IN VARCHAR2,
   p_VOLTAGE_LEVEL        IN VARCHAR2,
   p_TOLERANCE            IN NUMBER,
   p_STATUS              OUT NUMBER,
   p_MESSAGE             OUT VARCHAR2,
   p_CURSOR              OUT GA.REFCURSOR
   );

PROCEDURE GET_PLC_BUILDUPS(p_CURSOR IN OUT GA.REFCURSOR);

PROCEDURE GET_NSPL_BUILDUPS(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_TICKETS(p_FILTER_TAG IN VARCHAR2, p_FILTER_CUSTOMER IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_ALM_ADD_BACKS(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_POLR_TO_PLC_MAP(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_POLR_TO_PLC_MAP
   (
   p_PLC_BEGIN_DATE  IN DATE,
   p_PLC_END_DATE    IN DATE,
   p_POLR_BEGIN_DATE IN DATE,
   p_POLR_END_DATE   IN DATE,
   p_ENTRY_ROWID     IN VARCHAR2
   );

PROCEDURE CUT_POLR_TO_PLC_MAP(p_ENTRY_ROWID IN VARCHAR2);

PROCEDURE GET_PLC_WEATHER_NORMAL_FACTOR(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_PLC_WEATHER_NORMAL_FACTOR
   (
   p_RATE_CLASS    IN VARCHAR2,
   p_VOLTAGE_LEVEL IN VARCHAR2,
   p_FACTOR        IN NUMBER,
   p_ENTRY_ROWID   IN VARCHAR2
   );

PROCEDURE CUT_PLC_WEATHER_NORMAL_FACTOR(p_ENTRY_ROWID IN VARCHAR2);

PROCEDURE COMPUTE_ANNUAL_PLC_NSPL(p_ANCILLARY_SERVICE_ID IN NUMBER, p_PLAN_YEAR IN VARCHAR2);

PROCEDURE IMPORT_ALM_ADD_BACK_FILE
   (
   p_IMPORT_FILE      IN CLOB,
   p_IMPORT_FILE_PATH IN VARCHAR2,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   );

PROCEDURE CALCULATE_TICKETS
   (
   p_ANCILLARY_SERVICE_ID IN NUMBER,
   p_PLAN_YEAR            IN VARCHAR2,
   p_STATUS              OUT NUMBER,
   p_MESSAGE             OUT VARCHAR2
   );

END CDI_PLC_NSPL_CALCULATOR;
/