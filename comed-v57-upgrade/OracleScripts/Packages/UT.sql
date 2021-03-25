CREATE OR REPLACE PACKAGE UT AS
--Revision $Revision: 1.98 $

-- Utility Package

TYPE POINT IS RECORD(X NUMBER, Y NUMBER);
TYPE POINTS IS TABLE OF POINT INDEX BY BINARY_INTEGER;
TYPE STRING_MAP IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(256);

c_EMPTY_MAP STRING_MAP;

-- Structure holds pertinent info for a message definition
TYPE MSG_DEF IS RECORD (
	MESSAGE_ID		MESSAGE_DEFINITION.MESSAGE_ID%TYPE,
	MESSAGE_TYPE	MESSAGE_DEFINITION.MESSAGE_TYPE%TYPE,
	MESSAGE_NUMBER	MESSAGE_DEFINITION.MESSAGE_NUMBER%TYPE,
	MESSAGE_TEXT	MESSAGE_DEFINITION.MESSAGE_TEXT%TYPE
);


FUNCTION WHAT_VERSION RETURN VARCHAR;

FUNCTION CUSTOM_TO_NUMBER
	(
	p_VALUE IN VARCHAR2
	) RETURN NUMBER;

PROCEDURE TOKENS_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT GA.STRING_TABLE
	);

PROCEDURE TOKENS_FROM_STRING_TO_NUMBERS
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_NUMBER_TABLE OUT GA.NUMBER_TABLE
	);

PROCEDURE TOKENS_FROM_BIG_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_BIG_STRING_TABLE OUT GA.BIG_STRING_TABLE
	);

PROCEDURE IDS_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_ID_TABLE IN OUT GA.ID_TABLE
	);

PROCEDURE LOCAL_DATE_AND_TIME_TO_CUT
	(
	p_DATE IN VARCHAR,
	p_TIME IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_DATE OUT DATE
	);

PROCEDURE LOCAL_DATE_AND_TIME_TO_GMT
	(
	p_DATE IN VARCHAR,
	p_TIME IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_GMT_DATE OUT DATE
	);

PROCEDURE LOCAL_DAY_TO_CUT
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_DATE OUT DATE
	);

PROCEDURE LOCAL_DAY_TO_GMT
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_GMT_DATE OUT DATE
	);

FUNCTION GET_INCUMBENT_ENTITY_TYPE  RETURN INCUMBENT_ENTITY.INCUMBENT_TYPE%TYPE;

PROCEDURE GET_INCUMBENT_ENTITY
	(
	p_INCUMBENT_TYPE OUT VARCHAR,
	p_INCUMBENT_NAME OUT VARCHAR,
	p_INCUMBENT_ALIAS OUT VARCHAR,
	p_INCUMBENT_ID OUT NUMBER
	);

PROCEDURE SET_INCUMBENT_ENTITY
	(
	p_INCUMBENT_TYPE IN VARCHAR,
	p_INCUMBENT_ID IN NUMBER
	);

FUNCTION TRACE_DATE
	(
	p_DATE IN DATE
	) RETURN VARCHAR;

FUNCTION TRACE_BOOLEAN
	(
	p_BOOLEAN IN BOOLEAN
	) RETURN CHAR;

-- DEPRECATED!!! Do not call this method. Use the LOGS Package.
-- Method changed 2/20/2008 due to the new Processes/Logging API.
-- Remains for backward compatibility only.
PROCEDURE DEBUG_TRACE
	(
	p_STATEMENT IN VARCHAR
	);

-- DEPRECATED!!! Do not call this method. Use the LOGS Package.
-- Method changed 2/20/2008 due to the new Processes/Logging API.
-- Remains for backward compatibility only.
PROCEDURE TRUNCATE_TRACE;

-- DEPRECATED!!! Do not call this method. Use the LOGS Package.
-- Method changed 2/20/2008 due to the new Processes/Logging API.
-- Remains for backward compatibility only.
PROCEDURE GET_TRACE
	(
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE TRACE_TABLE
	(
	p_NAME IN VARCHAR,
	p_TABLE IN GA.NUMBER_TABLE
	);

 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_MINUTES IN NUMBER,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_SERVICE_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE CUT_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE CUT_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_SERVICE_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE CUT_DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE CUT_DATE_RANGE
	(
	p_SERVICE_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE CUT_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE CUT_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR,
	p_DATA_INTERVAL IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

PROCEDURE DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR := '',
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE SCENARIO_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_SCENARIO_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR := '',
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATA IN VARCHAR
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATE IN DATE
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER,
	p_WORK_DATE IN DATE,
	p_WORK_DATA IN VARCHAR
	);

PROCEDURE POST_RTO_WORK_DATE_RANGE
	(
	p_WORK_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_MINUTE_INTERVAL IN NUMBER
	);

PROCEDURE POST_RTO_WORK_DATE_RANGE
	(
	p_WORK_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR
	);

PROCEDURE PURGE_RTO_WORK
	(
	p_WORK_ID IN NUMBER
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATA IN VARCHAR,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATE IN DATE,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	);

PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER,
	p_WORK_DATE IN DATE,
	p_WORK_DATA IN VARCHAR,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	);

PROCEDURE PURGE_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	);

PROCEDURE GET_RTO_WORK_ID
	(
	p_WORK_ID OUT NUMBER
	);

FUNCTION GET_DROP_CLOB RETURN CLOB;

PROCEDURE CUT_ON_PEAK_HOURS
	(
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_HOUR OUT NUMBER,
	p_CUT_END_HOUR OUT NUMBER
	);

PROCEDURE LIN_REG
	(
	p_POINTS IN UT.POINTS,
	p_ALPHA OUT NUMBER,
	p_BETA OUT NUMBER,
	p_N OUT NUMBER,
	p_R2 OUT NUMBER,
	p_X_MIN OUT NUMBER,
	p_X_MAX OUT NUMBER,
	p_X_MEAN OUT NUMBER,
	p_Y_MIN OUT NUMBER,
	p_Y_MAX OUT NUMBER,
	p_Y_MEAN OUT NUMBER,
	p_X_ZERO OUT NUMBER,
	p_Y_ZERO OUT NUMBER
	);

PROCEDURE LIN_REG
	(
	p_POINTS IN UT.POINTS,
	p_ALPHA OUT NUMBER,
	p_BETA OUT NUMBER,
	p_N OUT NUMBER,
	p_R2 OUT NUMBER,
	p_X_MIN OUT NUMBER,
	p_X_MAX OUT NUMBER,
	p_Y_MIN OUT NUMBER,
	p_Y_MAX OUT NUMBER,
	p_X_ZERO OUT NUMBER,
	p_Y_ZERO OUT NUMBER
	);

PROCEDURE STD_DEV
	(
	p_OBS IN GA.NUMBER_TABLE,
	p_N OUT NUMBER,
	p_MEAN OUT NUMBER,
	p_STD OUT NUMBER,
	p_STD1 OUT NUMBER,
	p_STD2 OUT NUMBER,
	p_STD3 OUT NUMBER
	);

PROCEDURE GET_SYSTEM_LABELS
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_ALL_INCUMBENT_ENTITIES
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE MVAR_REG
	(
	p_N IN NUMBER, -- Number Of Observations
	p_M IN NUMBER, -- Number Of Independent Varaibles
	p_X IN GA.NUMBER_TABLE, -- Independent Variable(X) Values (N,M) Array
	p_Y IN GA.NUMBER_TABLE, -- Dependent Variable(Y) Values
	p_B IN OUT GA.NUMBER_TABLE, -- X Coefficients
	p_T IN OUT GA.NUMBER_TABLE, -- T Statistic
	p_R IN OUT NUMBER, -- R2 Statistic
	p_TSTAT_CRITICAL IN OUT NUMBER, -- T Statistic Critical
	p_ELAPSED_TIME IN OUT PLS_INTEGER
	);

PROCEDURE MVAR_REG_TEST;

PROCEDURE APPEND
	(
    p_SRC_ARRAY IN GA.NUMBER_TABLE,
    p_DEST_ARRAY IN OUT NOCOPY GA.NUMBER_TABLE
    );

PROCEDURE DUMP_CLOB_TO_RTO_WORK
	(
    p_CLOB IN CLOB,
    p_WORK_ID IN NUMBER
    );

PROCEDURE NEXT_TOKEN
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_INDEX IN BINARY_INTEGER,
	p_EOF OUT BOOLEAN,
	p_TOKEN OUT VARCHAR
	);

PROCEDURE STRING_TABLE_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	);

PROCEDURE STRING_COLLECTION_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_COLL OUT STRING_COLLECTION
	);

PROCEDURE ID_TABLE_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_ID_TABLE OUT ID_TABLE
	);

PROCEDURE NUMBER_COLL_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_NUMS OUT NUMBER_COLLECTION
	);

PROCEDURE NUMBER_COLL_FROM_ID_TABLE
	(
	p_ID_TABLE IN ID_TABLE,
	p_NUMS OUT NUMBER_COLLECTION
	);

PROCEDURE ID_TABLE_FROM_NUMBER_COLL
	(
	p_NUMS IN NUMBER_COLLECTION,
	p_ID_TABLE OUT ID_TABLE
	);

FUNCTION GET_LITERAL_FOR_NUMBER(p_VALUE IN NUMBER) RETURN VARCHAR2;

FUNCTION GET_LITERAL_FOR_STRING(p_VALUE IN VARCHAR2) RETURN VARCHAR2;

FUNCTION GET_LITERAL_FOR_DATE(p_VALUE IN DATE) RETURN VARCHAR2;

FUNCTION GET_LITERAL_FOR_NUMBER_COLL(p_VALUES IN NUMBER_COLLECTION) RETURN VARCHAR2;

FUNCTION GET_LITERAL_FOR_STRING_COLL(p_VALUES IN STRING_COLLECTION) RETURN VARCHAR2;

FUNCTION GET_LITERAL_FOR_DATE_COLL(p_VALUES IN DATE_COLLECTION) RETURN VARCHAR2;

FUNCTION STRING_COLLECTION_CONTAINS
	(
	p_VALS IN STRING_COLLECTION,
	p_VAL IN VARCHAR2,
	p_CASE_SENSITIVE IN BOOLEAN := TRUE
 	) RETURN BOOLEAN;

FUNCTION NUMBER_COLLECTION_CONTAINS
	(
	p_VALS IN NUMBER_COLLECTION,
	p_VAL IN NUMBER
	) RETURN BOOLEAN;

FUNCTION ID_TABLE_CONTAINS
	(
	p_VALS IN ID_TABLE,
	p_VAL IN NUMBER
	) RETURN BOOLEAN;

-- Invoking this procedure sets off a stop-watch.
-- %raises none
PROCEDURE TIMER_START;

-- Invoking this function gets the elapsed time of the stop-watch (DEFAULT in seconds).
-- %returns PLS_INTEGER
-- %raises none
FUNCTION TIMER_GET_ELAPSED RETURN NUMBER;

-- This function returns a script that will re-generate all types in the database.
-- This is often needed for re-creating the types since they sometimes fail to import
-- due to the way Oracle tracks them by OID insteaed of by owner+name.
FUNCTION EXPORT_TYPES RETURN CLOB;

---------------------------------------------------------------------------------
-- Align date ranges for temporal data for the specified table, only for the rows
-- with the specified key columns. The list of key columns should identify *all*
-- columns in the primary/unique key other than the begin date.
--
-- Value parameters must be PL/SQL literals - use the GET_LITERAL_FOR_* functions
-- in this package to create them
--
-- This routine just tidies up end dates so that there are no overlapping date ranges.
--
-- A System Dictionary flag is examined to determine if gaps are allowed in the date ranges:
--    Global -> System -> Temporal Data -> Allow Data Range Gaps -> {table name}
-- The default value is true. If it is set to false, then gaps are eliminated by extending
-- the end dates of rows up to the subsequent row's begin date.
-- Before using the default value of true, a fallback dictionary entry is examined:
--    Global -> System -> Temporal Data -> Allow Data Range Gaps -> %
---------------------------------------------------------------------------------
PROCEDURE ALIGN_DATE_RANGES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_COL_NAME1 IN VARCHAR2,
	p_COL_VALUE1 IN VARCHAR2,
	p_COL_NAME2 IN VARCHAR2 := NULL,
	p_COL_VALUE2 IN VARCHAR2 := NULL,
	p_COL_NAME3 IN VARCHAR2 := NULL,
	p_COL_VALUE3 IN VARCHAR2 := NULL,
	p_COL_NAME4 IN VARCHAR2 := NULL,
	p_COL_VALUE4 IN VARCHAR2 := NULL,
	p_COL_NAME5 IN VARCHAR2 := NULL,
	p_COL_VALUE5 IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);

---------------------------------------------------------------------------------
-- Same as above except that column names and values are passed in as a MAP instead of
-- as pairs of parameters.
---------------------------------------------------------------------------------
PROCEDURE ALIGN_DATE_RANGES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_KEY_COLUMNS IN STRING_MAP,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);
---------------------------------------------------------------------------------
PROCEDURE ALIGN_DATES_BY_SECOND
  (
  p_TABLE_NAME IN VARCHAR2,
	p_KEY_COLUMNS IN STRING_MAP,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
  );
---------------------------------------------------------------------------------
-- Align date ranges for temporal data for the specified table, for all rows. The
-- list of key columns should identify *all* columns in the primary/unique key other
-- than the begin date. This list of columns is used to determine the distinct sets of
-- key values (excluding begin date). ALIGN_DATE_RANGES is then called for each of
-- these sets of values.
--
-- This routine just tidies up end dates so that there are no overlapping date ranges.
---------------------------------------------------------------------------------
PROCEDURE ALIGN_ALL_DATE_RANGES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_COL_NAME1 IN VARCHAR2,
	p_COL_NAME2 IN VARCHAR2 := NULL,
	p_COL_NAME3 IN VARCHAR2 := NULL,
	p_COL_NAME4 IN VARCHAR2 := NULL,
	p_COL_NAME5 IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);

---------------------------------------------------------------------------------
-- Same as above except that column names are passed in as a COLLECTION instead of
-- as a sequence of parameters.
---------------------------------------------------------------------------------
PROCEDURE ALIGN_ALL_DATE_RANGES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_KEY_COLUMNS IN STRING_COLLECTION,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);

---------------------------------------------------------------------------------
-- Put a row into a temporal data table. This routine performs consistent handling
-- of temporal data to result in the most compact set of rows possible. Rows that
-- are obsoleted by the specified data (i.e. their date range is contained wholly
-- within the new date range) will be deleted. If the new row has the same data as
-- the existing rows for adjacent date ranges, they will be merged into as few rows
-- as possible. If p_NULL_END_DATE_IS_HIGH_DATE is false, then a NULL end date means
-- "don't care". This means the new date range ends with the next range's begin date
-- or never ends (HIGH_DATE) if there is no next range. If p_NULL_END_DATE_IS_HIGH_DATE
-- is true, however, then a NULL end date is treated as if it were HIGH_DATE.
--
-- p_UPDATE_ENTRY_DATE should be set to true if the table has an ENTRY_DATE column.
--
-- Value parameters must be PL/SQL literals - use the GET_LITERAL_FOR_* functions
-- in this package to create them
--
-- This routine calls ALIGN_DATE_RANGE when done to tidy up end dates.
---------------------------------------------------------------------------------
PROCEDURE PUT_TEMPORAL_DATA
	(
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_NULL_END_IS_HIGH_DATE IN BOOLEAN,
	p_UPDATE_ENTRY_DATE IN BOOLEAN,
	p_COL_NAME1 IN VARCHAR2,
	p_COL_VALUE1 IN VARCHAR2,
	p_COL_IS_KEY1 IN BOOLEAN := FALSE,
	p_COL_NAME2 IN VARCHAR2 := NULL,
	p_COL_VALUE2 IN VARCHAR2 := NULL,
	p_COL_IS_KEY2 IN BOOLEAN := FALSE,
	p_COL_NAME3 IN VARCHAR2 := NULL,
	p_COL_VALUE3 IN VARCHAR2 := NULL,
	p_COL_IS_KEY3 IN BOOLEAN := FALSE,
	p_COL_NAME4 IN VARCHAR2 := NULL,
	p_COL_VALUE4 IN VARCHAR2 := NULL,
	p_COL_IS_KEY4 IN BOOLEAN := FALSE,
	p_COL_NAME5 IN VARCHAR2 := NULL,
	p_COL_VALUE5 IN VARCHAR2 := NULL,
	p_COL_IS_KEY5 IN BOOLEAN := FALSE,
	p_TABLE_ID_NAME IN VARCHAR2 := NULL,
	p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL,
    p_EXTEND_DATE_RANGE IN BOOLEAN := TRUE
	);

---------------------------------------------------------------------------------
-- Same as above except that column names and values are passed in as MAPs instead of
-- as sets of parameters.
---------------------------------------------------------------------------------
PROCEDURE PUT_TEMPORAL_DATA
	(
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_NULL_END_IS_HIGH_DATE IN BOOLEAN,
	p_UPDATE_ENTRY_DATE IN BOOLEAN,
	p_KEY_COLUMNS IN STRING_MAP,
	p_DATA_COLUMNS IN STRING_MAP,
	p_TABLE_ID_NAME IN VARCHAR2 := NULL,
	p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL,
    p_EXTEND_DATE_RANGE IN BOOLEAN := TRUE
	);

---------------------------------------------------------------------------------
-- Put a row into a temporal data table. This routine performs consistent handling
-- of temporal data when entered from the UI. It is different than PUT_TEMPORAL_DATA
-- above in that it will not try to compact rows or delete obselete rows. This is
-- because it could surprise a user, after updating the date range of one row
-- or entering a new row, to see rows suddenly deleted/adjusted after poking the
-- Save button. So this method tries to preserve the existing data to the extent
-- possible.
--
-- Another key difference between this method and PUT_TEMPORAL_DATA is that this
-- method allows primary key columns to be modified. This is something that should
-- only happen when a user is changing rows in a grid in the UI.
--
-- Note that the columns' old values are only needed for key columns. You can safely
-- pass NULL for non-key columns.
--
-- p_UPDATE_ENTRY_DATE should be set to true if the table has an ENTRY_DATE column.
--
-- Value parameters must be PL/SQL literals - use the GET_LITERAL_FOR_* functions
-- in this package to create them
--
-- This routine calls ALIGN_DATE_RANGE when done to tidy up end dates.
---------------------------------------------------------------------------------
PROCEDURE PUT_TEMPORAL_DATA_UI
	(
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BEGIN_DATE IN DATE,
	p_UPDATE_ENTRY_DATE IN BOOLEAN,
	p_COL_NAME1 IN VARCHAR2,
	p_COL_NEW_VALUE1 IN VARCHAR2,
	p_COL_OLD_VALUE1 IN VARCHAR2 := NULL,
	p_COL_IS_KEY1 IN BOOLEAN := FALSE,
	p_COL_NAME2 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE2 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE2 IN VARCHAR2 := NULL,
	p_COL_IS_KEY2 IN BOOLEAN := FALSE,
	p_COL_NAME3 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE3 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE3 IN VARCHAR2 := NULL,
	p_COL_IS_KEY3 IN BOOLEAN := FALSE,
	p_COL_NAME4 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE4 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE4 IN VARCHAR2 := NULL,
	p_COL_IS_KEY4 IN BOOLEAN := FALSE,
	p_COL_NAME5 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE5 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE5 IN VARCHAR2 := NULL,
	p_COL_IS_KEY5 IN BOOLEAN := FALSE,
	p_TABLE_ID_NAME IN VARCHAR2 := NULL,
	p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);

---------------------------------------------------------------------------------
-- Same as above except that column names and values are passed in as MAPs instead of
-- as sets of parameters.
---------------------------------------------------------------------------------
PROCEDURE PUT_TEMPORAL_DATA_UI
	(
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BEGIN_DATE IN DATE,
	p_UPDATE_ENTRY_DATE IN BOOLEAN,
	p_KEY_COLUMNS_NEW IN STRING_MAP,
	p_KEY_COLUMNS_OLD IN STRING_MAP,
	p_DATA_COLUMNS IN STRING_MAP,
	p_TABLE_ID_NAME IN VARCHAR2 := NULL,
	p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);

---------------------------------------------------------------------------------
-- This procedure is a variation on the PUT_TEMPORAL_DATA_UI procedure above
-- the difference with this one is that it handles inputing data at the partial
-- day interval meening that it can handle dates being entered at an hourly time
-- instead
--
---------------------------------------------------------------------------------
PROCEDURE PUT_TEMPORAL_DATA_UI_SUBDAY
	(
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BEGIN_DATE IN DATE,
	p_UPDATE_ENTRY_DATE IN BOOLEAN,
	p_COL_NAME1 IN VARCHAR2,
	p_COL_NEW_VALUE1 IN VARCHAR2,
	p_COL_OLD_VALUE1 IN VARCHAR2 := NULL,
	p_COL_IS_KEY1 IN BOOLEAN := FALSE,
	p_COL_NAME2 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE2 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE2 IN VARCHAR2 := NULL,
	p_COL_IS_KEY2 IN BOOLEAN := FALSE,
	p_COL_NAME3 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE3 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE3 IN VARCHAR2 := NULL,
	p_COL_IS_KEY3 IN BOOLEAN := FALSE,
	p_COL_NAME4 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE4 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE4 IN VARCHAR2 := NULL,
	p_COL_IS_KEY4 IN BOOLEAN := FALSE,
	p_COL_NAME5 IN VARCHAR2 := NULL,
	p_COL_NEW_VALUE5 IN VARCHAR2 := NULL,
	p_COL_OLD_VALUE5 IN VARCHAR2 := NULL,
	p_COL_IS_KEY5 IN BOOLEAN := FALSE,
	p_TABLE_ID_NAME IN VARCHAR2 := NULL,
	p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);
---------------------------------------------------------------------------------
-- Same as above except that column names and values are passed in as MAPs instead of
-- as sets of parameters.
---------------------------------------------------------------------------------
PROCEDURE PUT_TEMPORAL_DATA_UI_SUBDAY
	(
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OLD_BEGIN_DATE IN DATE,
	p_UPDATE_ENTRY_DATE IN BOOLEAN,
	p_KEY_COLUMNS_NEW IN STRING_MAP,
	p_KEY_COLUMNS_OLD IN STRING_MAP,
	p_DATA_COLUMNS IN STRING_MAP,
	p_TABLE_ID_NAME IN VARCHAR2 := NULL,
	p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	P_WEEK_BEGIN IN VARCHAR2 := NULL
	);
---------------------------------------------------------------------------------
-- Generates a CLOB that contains the default GET, PUT, and DELETE procedures for
-- a sub-tab grid based on a specified table.
---------------------------------------------------------------------------------
FUNCTION CREATE_EM_ROUTINES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_SUB_TAB_NAME IN VARCHAR2 := NULL,
	p_CONSTRAINT_NAME IN VARCHAR2 := NULL,
	p_UNEDITABLE_KEYS IN STRING_COLLECTION := NULL,
	p_MODULE_NAME IN VARCHAR2 := NULL,
	p_ENTITY_ID_COL1 IN VARCHAR2 := NULL,
	p_ENTITY_DOMAIN_ID1 IN NUMBER := NULL,
	p_ENTITY_ID_COL2 IN VARCHAR2 := NULL,
	p_ENTITY_DOMAIN_ID2 IN NUMBER := NULL,
	p_ENTITY_ID_COL3 IN VARCHAR2 := NULL,
	p_ENTITY_DOMAIN_ID3 IN NUMBER := NULL,
	p_ENTITY_ID_COL4 IN VARCHAR2 := NULL,
	p_ENTITY_DOMAIN_ID4 IN NUMBER := NULL,
	p_TABLE_ID_NAME IN VARCHAR2 := NULL,
	p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
	) RETURN CLOB;

-- Get full error message that includes error stack trace
FUNCTION GET_FULL_ERRM RETURN VARCHAR2;

-- Get a message definition based on the specified message code
PROCEDURE GET_MESSAGE_DEFINITION
	(
	p_MESSAGE_CODE IN VARCHAR2,
	p_MSG_DEF OUT MSG_DEF
	);

-- Converts a string to a boolean value. The resulting boolean will be FALSE if the
-- first character of the string is '0', 'N', or 'F'
FUNCTION BOOLEAN_FROM_STRING
	(
	p_STRING IN VARCHAR2
	) RETURN BOOLEAN;
-- Converts a boolean to a number value. False is zero, true is one.
FUNCTION NUMBER_FROM_BOOLEAN
	(
	p_BOOL IN BOOLEAN
	) RETURN NUMBER;
-- and vice versa: number to boolean (returns true if parameter is non-null and non-zero)
FUNCTION BOOLEAN_FROM_NUMBER
	(
	p_NUM IN NUMBER
	) RETURN BOOLEAN;

-- Generates a CLOB that is the MSGCODES Package Spec based on all the current
-- Messages defined in the MESSAGE_DEFINITION table.
FUNCTION GENERATE_MSGCODES RETURN CLOB;

-- Invokes DBMS_SESSION.IS_SESSION_ALIVE and returns a number instead of boolean so
-- it can be used from SQL
FUNCTION IS_SESSION_ALIVE(p_SESSION_ID VARCHAR2) RETURN NUMBER;

PROCEDURE GET_STORED_PROC_PARAMETERS
	(
	p_PACKAGE_NAME IN VARCHAR,
	p_PROCEDURE_NAME IN VARCHAR,
	p_OVERLOAD_INDEX IN NUMBER,
	p_PARAM_TABLE OUT STORED_PROC_PARAMETER_TABLE
	);

PROCEDURE GET_STORED_PROC_PARAMETERS
	(
	p_PACKAGE_AND_PROC_NAME IN VARCHAR2,
	p_OVERLOAD_INDEX IN NUMBER,
	p_PARAM_TABLE OUT STORED_PROC_PARAMETER_TABLE
	);

PROCEDURE GET_STORED_PROC_OVERLOAD_COUNT
	(
	p_PACKAGE_NAME IN VARCHAR,
	p_PROCEDURE_NAME IN VARCHAR,
	p_COUNT OUT NUMBER
	);

FUNCTION GENERATE_JOB_NAME
	(
	p_USER_ID IN NUMBER
	)RETURN VARCHAR2;

g_SUCCESS_MESSAGE VARCHAR2(200) := 'All types were successfully generated.';

-- Convert a map into a string. Each key/value pair will be delimited by
-- specified string and each entry in the map is further delimited by
-- specified string.
FUNCTION MAP_TO_STRING
	(
	p_MAP IN UT.STRING_MAP,
	p_PAIR_DELIM IN VARCHAR2,
	p_ENTRY_DELIM IN VARCHAR2
	) RETURN VARCHAR2;

-- Convert list of keys in a map to a string. The values will be
-- delimited by specified string.
FUNCTION MAP_TO_KEYS_STRING
	(
	p_MAP IN UT.STRING_MAP,
	p_ENTRY_DELIM IN VARCHAR2
	) RETURN VARCHAR2;

-- Convert list of values in a map to a string. The values will be
-- delimited by specified string.
FUNCTION MAP_TO_VALS_STRING
	(
	p_MAP IN UT.STRING_MAP,
	p_ENTRY_DELIM IN VARCHAR2
	) RETURN VARCHAR2;

-- Convert a map into a WHERE clause string. This is similar to
-- invoking the following:
--    UT.MAP_TO_STRING(p_CRITERIA, ' = ', ' AND ')
-- The main difference is that MAP_TO_WHERE_CLAUSE is smart enough
-- to recognize NULL l-values and use "IS NULL" in resulting string.
-- Also, this one will prefix column names with a table alias if
-- one is specified.
FUNCTION MAP_TO_WHERE_CLAUSE
	(
	p_CRITERIA IN UT.STRING_MAP,
	p_TBL_ALIAS IN VARCHAR2 := NULL
	) RETURN VARCHAR2;

-- Convert a map into an update clause string. This is equivalent
-- to invoking the following:
--    UT.MAP_TO_STRING(p_CRITERIA, ' = ', ', ');
FUNCTION MAP_TO_UPDATE_CLAUSE
	(
	p_CRITERIA IN UT.STRING_MAP
	) RETURN VARCHAR2;

-- Convert a map into a list of column names for an insert statement.
-- This is equivalent to invoking the following:
--    UT.MAP_TO_KEYS_STRING(p_CRITERIA, ', ');
FUNCTION MAP_TO_INSERT_NAMES
	(
	p_CRITERIA IN UT.STRING_MAP
	) RETURN VARCHAR2;

-- Convert a map into a list of column values for an insert statement.
-- This is equivalent to invoking the following:
--    UT.MAP_TO_VALS_STRING(p_CRITERIA, ', ');
FUNCTION MAP_TO_INSERT_VALS
	(
	p_CRITERIA IN UT.STRING_MAP
	) RETURN VARCHAR2;

FUNCTION GET_FK_REF_DETAILS_FROM_ERRM
	(
	p_SQLERRM IN VARCHAR2, -- SQL ERROR MESSAGE
	p_ENTITY_DOMAIN_ID IN NUMBER, -- THE DOMAIN OF THE ENTITY
	p_ENTITY_ID IN VARCHAR2 -- THE ENTITY THAT STILL HAS CHILD REFERENCES
	) RETURN VARCHAR2;

-- TAKES IN A LIST OF (POTENTIALLY) NON DISTINCT NUMBERS AND RETURNS A DISTINCT COLLECTION
PROCEDURE CREATE_DISTINCT_NUM_COLLECTION
	(
	p_NUM_COLLECTION IN NUMBER_COLLECTION,
	p_DISTINCT_NUM_COLLECTION OUT NUMBER_COLLECTION
	);

-- TAKES IN A LIST OF (POTENTIALLY) NON DISTINCT STRINGS AND RETURNS A DISTINCT COLLECTION
PROCEDURE CREATE_DISTINCT_STRING_COLL
	(
	p_STRING_COLLECTION IN STRING_COLLECTION,
	p_DISTINCT_STRING_COLLECTION OUT STRING_COLLECTION
	);

PROCEDURE GET_DATE_COLLECTION_MIN_MAX
	(
	p_DATE_COLL IN DATE_COLLECTION,
	p_MIN_DATE OUT DATE,
	p_MAX_DATE OUT DATE
	);

PROCEDURE GET_DATE_COLL_COLL_MIN_MAX
	(
	p_DATE_COLL_COLL IN DATE_COLLECTION_COLLECTION,
	p_MIN_DATE OUT DATE,
	p_MAX_DATE OUT DATE
	);
    
FUNCTION CUT_DATE_COLL
    (
    p_DATE_COLL IN DATE_COLLECTION,
    p_TIME_ZONE IN VARCHAR2
    ) RETURN DATE_COLLECTION;
    
FUNCTION CUT_DATE_COLL_COLL
    (
    p_DATE_COLL_COLL IN DATE_COLLECTION_COLLECTION,
    p_TIME_ZONE IN VARCHAR2
    ) RETURN DATE_COLLECTION_COLLECTION;

PROCEDURE CONVERT_ID_TABLE_TO_NUM_COLL
	(
	p_ID_TABLE IN ID_TABLE,
	p_NUM_COLL OUT NUMBER_COLLECTION
	);

FUNCTION NEW_NUMBER_COLLECTION
	(
	p_LENGTH IN NUMBER := 0,
	p_FILL_VALUE IN NUMBER := NULL
	) RETURN NUMBER_COLLECTION;

FUNCTION NEW_STRING_COLLECTION
	(
	p_LENGTH IN NUMBER := 0,
	p_FILL_VALUE IN STRING := NULL
	) RETURN STRING_COLLECTION;

FUNCTION NEW_DATE_COLLECTION
	(
	p_LENGTH IN NUMBER := 0,
	p_FILL_VALUE IN DATE := NULL
	) RETURN DATE_COLLECTION;

FUNCTION CONVERT_FLT_TABLE_TO_NUM_TABLE
	(
	p_FLOAT_TBL IN GA.FLOAT_TABLE
	) RETURN GA.NUMBER_TABLE;

-- Generates a CLOB that defines indexes on all un-indexed foreign keys.
-- The System Label table can be used to enumerate tables to ignore (i.e.
-- skip all foreign key references from a given table)
FUNCTION NEW_FOREIGN_KEY_INDEXES RETURN CLOB;

PROCEDURE DUMMY(p_IMPORT_FILE IN OUT BLOB, p_IMPORT_FILE_PATH IN OUT VARCHAR2);

FUNCTION CONVERT_UNIT_OF_MEASURE
	(
	p_FROM_UOM	IN VARCHAR2,
	p_QUANTITY	IN NUMBER,
	p_TO_UOM	IN VARCHAR2
	) RETURN NUMBER;

FUNCTION CAN_CONVERT
    (
    p_FROM_UOM IN VARCHAR2,
    p_TO_UOM IN VARCHAR2
    ) RETURN BOOLEAN;

FUNCTION GET_CONVERSION_FACTOR
    (
    p_FROM_UOM IN VARCHAR2,
    p_TO_UOM IN VARCHAR2,
    p_INTERVAL IN VARCHAR2
    ) RETURN NUMBER;

PROCEDURE CONVERT_NUM_TBL_TO_COLLECTION
	(
	p_TABLE IN GA.NUMBER_TABLE,
	p_COLLECTION OUT NUMBER_COLLECTION
	);

PROCEDURE CONVERT_COLLECTION_TO_NUM_TBL
	(
	p_COLLECTION IN NUMBER_COLLECTION,
	p_TABLE OUT GA.NUMBER_TABLE
	);

PROCEDURE PRINT_CLOB
    (
    p_CLOB IN CLOB
    );

FUNCTION GET_RATE_FOR_PERCENT_STRING
    (
    p_PERCENT_TEXT IN VARCHAR2
    ) RETURN NUMBER;

PROCEDURE COPY_TEMPORAL_DATA
    (
    p_TABLE_NAME IN VARCHAR2,
    p_SRC_BEGIN_DATE IN DATE,
    p_SRC_END_DATE IN DATE,
    p_SRC_KEY_COLUMNS IN STRING_MAP,
    p_TGT_BEGIN_DATE IN DATE,
    p_TGT_END_DATE IN DATE,
    p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
    );

-- Remove all entries for this key set in the given date range.
-- Any entries that span the entire date range will be split into two.
PROCEDURE DELETE_TEMPORAL_DATA
    (
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_KEY_COLUMNS IN STRING_MAP,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
    );

PROCEDURE DELETE_TEMPORAL_DATA
	(
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_KEY_COL_NAME1 IN VARCHAR2,
	p_KEY_COL_VALUE1 IN VARCHAR2,
	p_KEY_COL_NAME2 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE2 IN VARCHAR2 := NULL,
	p_KEY_COL_NAME3 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE3 IN VARCHAR2 := NULL,
	p_KEY_COL_NAME4 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE4 IN VARCHAR2 := NULL,
	p_KEY_COL_NAME5 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE5 IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
	);

-- Copy Temporal Data copies the data for one keyset/ date range into another.
-- This will fail if any existing entries are in the target date range.
PROCEDURE COPY_TEMPORAL_DATA
	(
	p_TABLE_NAME IN VARCHAR2,
    p_SRC_BEGIN_DATE IN DATE,
    p_SRC_END_DATE IN DATE,
    p_TGT_BEGIN_DATE IN DATE,
    p_TGT_END_DATE IN DATE,
	p_KEY_COL_NAME1 IN VARCHAR2,
	p_KEY_COL_VALUE1 IN VARCHAR2,
	p_KEY_COL_NAME2 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE2 IN VARCHAR2 := NULL,
	p_KEY_COL_NAME3 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE3 IN VARCHAR2 := NULL,
	p_KEY_COL_NAME4 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE4 IN VARCHAR2 := NULL,
	p_KEY_COL_NAME5 IN VARCHAR2 := NULL,
	p_KEY_COL_VALUE5 IN VARCHAR2 := NULL,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
	);

-- This will recurse through "NO ACTION" foreign key references to *forcibly*
-- delete specified data by forcing a cascade-delete of child/referring records.
-- Use with *extreme caution*.
PROCEDURE FORCIBLY_DELETE(
	p_TABLE_NAME	IN VARCHAR2,
	p_COL_NAME1		IN VARCHAR2,
	p_COL_VALUE1	IN VARCHAR2,
	p_COL_NAME2		IN VARCHAR2 := NULL,
	p_COL_VALUE2	IN VARCHAR2 := NULL,
	p_COL_NAME3		IN VARCHAR2 := NULL,
	p_COL_VALUE3	IN VARCHAR2 := NULL,
	p_COL_NAME4		IN VARCHAR2 := NULL,
	p_COL_VALUE4	IN VARCHAR2 := NULL,
	p_COL_NAME5		IN VARCHAR2 := NULL,
	p_COL_VALUE5	IN VARCHAR2 := NULL
	);
PROCEDURE FORCIBLY_DELETE(
	p_TABLE_NAME	IN VARCHAR2,
	p_COLUMNS		IN UT.STRING_MAP
	);

-- Utility POSIX like functions...isDate, isAlpha, isNumber, etc.

FUNCTION IS_NUMBER (p_NUMBER IN VARCHAR2)
RETURN BOOLEAN;

PROCEDURE MONITOR_PROCESS_PROGRESS(
	p_PROCESS_ID		IN 	NUMBER,
	p_PROGRESS_PERCENT	OUT	NUMBER,
	p_PROCESS_STATE		OUT	VARCHAR,
	p_STATUS			OUT	NUMBER
	);

PROCEDURE TERMINATE_PROCESS(
	p_PROCESS_ID		IN 	NUMBER,
	p_STATUS			OUT	NUMBER
	);

END UT;
/
