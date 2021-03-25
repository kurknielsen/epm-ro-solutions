CREATE OR REPLACE PACKAGE DATE_UTIL IS
--Revision $Revision: 1.8 $

  -- Author  : JHUMPHRIES
  -- Created : 1/22/2008 1:33:28 PM
  -- Purpose : Utility functions for dealing with CUT dates and intervals

-- ordinal values for intervals
c_ORD_5MIN CONSTANT PLS_INTEGER := 1;
c_ORD_10MIN CONSTANT PLS_INTEGER := 2;
c_ORD_15MIN CONSTANT PLS_INTEGER := 3;
c_ORD_20MIN CONSTANT PLS_INTEGER := 4;
c_ORD_30MIN CONSTANT PLS_INTEGER := 5;
c_ORD_HOUR CONSTANT PLS_INTEGER := 6;
c_ORD_DAY CONSTANT PLS_INTEGER := 7;
c_ORD_WEEK CONSTANT PLS_INTEGER := 8;
c_ORD_MONTH CONSTANT PLS_INTEGER := 9;
c_ORD_QUARTER CONSTANT PLS_INTEGER := 10;
c_ORD_YEAR CONSTANT PLS_INTEGER := 11;

-- Proper abbreviations for intervals - note that NULL is synonymous with 'HH'
-- except in Oracle's TRUNC function
c_ABBR_5MIN CONSTANT VARCHAR2(16) := 'MI5';
c_ABBR_10MIN CONSTANT VARCHAR2(16) := 'MI10';
c_ABBR_15MIN CONSTANT VARCHAR2(16) := 'MI15';
c_ABBR_20MIN CONSTANT VARCHAR2(16) := 'MI20';
c_ABBR_30MIN CONSTANT VARCHAR2(16) := 'MI30';
c_ABBR_HOUR CONSTANT VARCHAR2(16) := 'HH';
c_ABBR_DAY CONSTANT VARCHAR2(16) := 'DD';
c_ABBR_WEEK CONSTANT VARCHAR2(16) := 'DY';
c_ABBR_MONTH CONSTANT VARCHAR2(16) := 'MM';
c_ABBR_QUARTER CONSTANT VARCHAR2(16) := 'Q';
c_ABBR_YEAR CONSTANT VARCHAR2(16) := 'YY';

-- Proper names for intervals - these are the names that are stored in the database
-- as entity intervals.
c_NAME_5MIN CONSTANT VARCHAR2(16) := '5 Minute';
c_NAME_10MIN CONSTANT VARCHAR2(16) := '10 Minute';
c_NAME_15MIN CONSTANT VARCHAR2(16) := '15 Minute';
c_NAME_20MIN CONSTANT VARCHAR2(16) := '20 Minute';
c_NAME_30MIN CONSTANT VARCHAR2(16) := '30 Minute';
c_NAME_HOUR CONSTANT VARCHAR2(16) := 'Hour';
c_NAME_DAY CONSTANT VARCHAR2(16) := 'Day';
c_NAME_WEEK CONSTANT VARCHAR2(16) := 'Week';
c_NAME_MONTH CONSTANT VARCHAR2(16) := 'Month';
c_NAME_QUARTER CONSTANT VARCHAR2(16) := 'Quarter';
c_NAME_YEAR CONSTANT VARCHAR2(16) := 'Year';


c_WEEK_BEGIN_SUNDAY CONSTANT VARCHAR2(16) := 'SUNDAY';
c_WEEK_BEGIN_MONDAY CONSTANT VARCHAR2(16) := 'MONDAY';
c_WEEK_BEGIN_TUESDAY CONSTANT VARCHAR2(16) := 'TUESDAY';
c_WEEK_BEGIN_WEDNESDAY CONSTANT VARCHAR2(16) := 'WEDNESDAY';
c_WEEK_BEGIN_THURSDAY CONSTANT VARCHAR2(16) := 'THURSDAY';
c_WEEK_BEGIN_FRIDAY CONSTANT VARCHAR2(16) := 'FRIDAY';
c_WEEK_BEGIN_SATURDAY CONSTANT VARCHAR2(16) := 'SATURDAY';
c_WEEK_BEGIN_FIRST_OF_YEAR CONSTANT VARCHAR2(16) := 'FIRST OF YEAR';
c_WEEK_BEGIN_FIRST_OF_MONTH CONSTANT VARCHAR2(16) := 'FIRST OF MONTH';

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- Truncate a date to the week. This is smarter than TRUNC(p_DATE, 'DY') because it is
-- safe for international use. It does not depend on NLS settings and will return a Sunday
-- unless a parameter value is specified for p_WEEK_BEGIN.
FUNCTION WEEK_TRUNC
	(
	p_DATE IN DATE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	) RETURN DATE;


-- Get first interval of the day in local time. p_DATE is a day, and p_INTERVAL_ABBR must
-- be the interval abbreviation (see GET_INTERVAL_ABBREVIATION).
FUNCTION GET_START_DATE
	(
    p_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE;

-- Get last second for an interval. p_BEGIN_DATE is the first second of the interval, and
-- p_INTERVAL_ABBR must be the interval abbreviation (see GET_INTERVAL_ABBREVIATION).
FUNCTION GET_INTERVAL_END_DATE
	(
    p_BEGIN_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE;
-- Get first second for an interval. p_END_DATE is the last second of the interval, and
-- p_INTERVAL_ABBR must be the interval abbreviation (see GET_INTERVAL_ABBREVIATION).
FUNCTION GET_INTERVAL_BEGIN_DATE
	(
    p_END_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE;

-- Advance a date that is of a specified interval.
FUNCTION ADVANCE_DATE
	(
	p_DATE IN DATE,
	p_INTERVAL IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL,
	p_AMOUNT IN PLS_INTEGER := 1
	) RETURN DATE;

-- Get number of minutes in the specified interval. p_DATE and p_TIME_ZONE are needed for
-- intervals whose length is dependent on which interval (months and greater) or dependent on the
-- time zone (day and greater could differ in duration between standard and DST-observing time zones)
FUNCTION GET_NUMBER_OF_MINUTES
	(
    p_INTERVAL IN VARCHAR2,
    p_DATE IN DATE := CONSTANTS.LOW_DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN NUMBER;

-- Get a divisor for spreading interval data to smaller interval. For instance, a source interval
-- of 'hour' and target interval of '15 minute' yields a divisor of 4. You would divide the hourly
-- value by 4 to spread it to 15 minute intervals. The p_DATE and p_TIME_ZONE are needed for
-- intervals whose length is dependent on which interval (months and greater) or dependent on the
-- time zone (day and greater could differ in duration between standard and DST-observing time zones)
FUNCTION GET_INTERVAL_DIVISOR
	(
    p_SRC_INTERVAL IN VARCHAR2,
    p_TRG_INTERVAL IN VARCHAR2,
    p_DATE IN DATE := CONSTANTS.LOW_DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN NUMBER;

-- Hour-Ending TRUNC. This is similar to Oracle's TRUNC with two exceptions:
--   Sub-hourly intervals supported (MI5, MI10, MI15, MI30) and work
--   If p_SCHEDULING_DATES is TRUE then the resulting value will represent one second past midnight
--     whenever p_INTERVAL_ABBR indicates an interval of Day or greater
--   Midnight is considered HE 24 - so HED_TRUNC(DATE '2007-02-01', 'DD') yields DATE '2007-01-31'
FUNCTION HED_TRUNC
	(
    p_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2,
	p_SCHEDULING_DATES IN BOOLEAN
    ) RETURN DATE;
-- This version can be called from SQL
FUNCTION HED_TRUNC
	(
    p_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE;

-- Provides a truncated date that is appropriate for comparing dates of differing intervals.
-- This can be used to detect if one interval belongs to another (or is contained by another).
-- Simply PROPER_TRUNC_DATE both dates passing the two intervals and see if the resulting dates
-- are equal.
FUNCTION PROPER_TRUNC_DATE
	(
    p_CUT_DATE IN DATE,
    p_INTERVAL1 IN VARCHAR2,
    p_INTERVAL2 IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2 := NULL,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE;

-- Gets an ordinal value for the specified interval. The greater the ordinal value, the larger
-- the interval. 5 Minute is the smallest interval; Year is the biggest.
FUNCTION INTERVAL_ORD
	(
	p_INTERVAL IN VARCHAR2
    ) RETURN NUMBER;

-- Gets the interval name that corresponds to the specified ordinal value.
FUNCTION INTERVAL_NAME
	(
	p_INTERVAL_ORD IN NUMBER
    ) RETURN VARCHAR2;

-- Get the begin date for an interval and candidate date. Interval must be daily or greater.
FUNCTION BEGIN_DATE_FOR_INTERVAL (
	p_DATE IN DATE,
    p_INTERVAL IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE;

-- Get the end date for an interval and begin date. Interval must be daily or greater.
FUNCTION END_DATE_FOR_INTERVAL (
	p_BEGIN_DATE IN DATE,
    p_INTERVAL IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE;

-- Get a string that is compatible with Oracle's TRUNC function. Note that Oracle's TRUNC
-- function will not work properly if the specified interval is sub-hourly.
FUNCTION GET_ORA_TRUNC_INTERVAL
	(
    p_INTERVAL IN VARCHAR2
    ) RETURN VARCHAR2;

-- Determine whether or not the specified interval is sub-daily (i.e. hourly or sub-hourly).
-- This distinction is often important since sub-daily values are stored in time-zone-dependent
-- interval-ending format; daily and greater values are stored in time-zone-independent interval-
-- beginning format.
FUNCTION IS_SUB_DAILY
	(
	p_INTERVAL IN VARCHAR2
	) RETURN BOOLEAN;
FUNCTION IS_SUB_DAILY_NUM
	(
	p_INTERVAL IN VARCHAR2
	) RETURN NUMBER;

-- Determine the begin and end time-stamps that cover the specified interval. p_DATE_TIME is
-- a date/time that is in the desired interval. On return, p_BEGIN_DATE <= p_DATE_TIME and
-- p_END_DATE >= p_DATE_TIME
PROCEDURE GET_DATE_RANGE
	(
	p_DATE_TIME IN DATE,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE OUT DATE,
	p_END_DATE OUT DATE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);

-- Expand a date range to fully cover the specified interval.
-- Returns Truncated Dates representing the beginning and end day of the range.
PROCEDURE EXPAND_DAY_RANGE_FOR_INTERVAL
	(
	p_BEGIN_DAY IN DATE,
	p_END_DAY IN DATE,
	p_INTERVAL IN VARCHAR2,
	p_EXPANDED_BEGIN_DAY OUT DATE,
	p_EXPANDED_END_DAY OUT DATE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	);

--Return the Interval defined for the specified Transaction
FUNCTION GET_INTERVAL_FOR_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN VARCHAR2;

--Return the Interval defined for the specified Market Price
FUNCTION GET_INTERVAL_FOR_MARKET_PRICE
	(
	p_MARKET_PRICE_ID IN NUMBER
	) RETURN VARCHAR2;

--Return the Interval defined for the specified Measurement Source
FUNCTION GET_INTERVAL_FOR_MEAS_SOURCE
	(
	p_MEASUREMENT_SOURCE_ID IN NUMBER
	) RETURN VARCHAR2;

--Return the Statement Interval defined for the specified PSE
FUNCTION GET_INTERVAL_FOR_PSE_STATEMENT
	(
	p_PSE_ID IN NUMBER
	) RETURN VARCHAR2;

--Return the Interval defined for the specified Calculation Process
FUNCTION GET_INTERVAL_FOR_CALC_PROCESS
	(
	p_CALC_PROCESS_ID IN NUMBER
	) RETURN VARCHAR2;

--Return the Interval defined for the specified Trait Group and Transaction
FUNCTION GET_INTERVAL_FOR_TRAIT_GROUP
	(
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER
	) RETURN VARCHAR2;

-- Return the Begin Date that should be used in a process
--   based on the largest specified interval.
FUNCTION GET_PROCESS_BEGIN_DATE
	(
	p_DATA_INTERVAL IN VARCHAR2,
	p_PROCESS_INTERVAL IN VARCHAR2,
	p_CUT_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_SCHEDULING_DATES IN BOOLEAN,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	) RETURN DATE;

-- Return the End Date that should be used in a process
--   based on the largest specified interval.
FUNCTION GET_PROCESS_END_DATE
	(
	p_DATA_INTERVAL IN VARCHAR2,
	p_PROCESS_INTERVAL IN VARCHAR2,
	p_CUT_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_SCHEDULING_DATES IN BOOLEAN,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	) RETURN DATE;

-- Return the interval and whether or not we use "Scheduling" dates for the
-- specified table data.
PROCEDURE GET_DATA_INTERVAL_INFO
	(
	p_TABLE_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_CRITERIA IN UT.STRING_MAP,
	p_INTERVAL OUT VARCHAR2,
	p_USE_SCHEDULING_DATES OUT BOOLEAN
	);

-- Return a cut date range for a query using "Scheduling" dates.
PROCEDURE CUT_DATE_RANGE_SCHEDULING
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR,
	p_DATA_INTERVAL IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	);

FUNCTION TO_CHAR_ISO(p_CUT_DATE DATE) RETURN VARCHAR2;
FUNCTION TO_CHAR_ISO_AS_GMT(p_CUT_DATE DATE) RETURN VARCHAR2;

FUNCTION GET_ANNIVERSARY_IN_PERIOD
	(
	p_TARGET_DATE IN DATE,
	p_PERIOD_BEGIN_DATE IN DATE,
	p_PERIOD_END_DATE IN DATE
	) RETURN DATE;

FUNCTION IS_ANNIVERSARY_IN_PERIOD
	(
	p_TARGET_DATE IN DATE,
	p_PERIOD_BEGIN_DATE IN DATE,
	p_PERIOD_END_DATE IN DATE
	) RETURN BOOLEAN;

FUNCTION DATES_IN_INTERVAL_RANGE
	(
	p_RANGE_BEGIN IN DATE,
	p_RANGE_END IN DATE,
	p_INTERVAL IN VARCHAR2
	) RETURN DATE_COLLECTION PIPELINED;

-- Return the Interval Name for a given Profile Interval number, such as would be
-- found in the LOAD_PROFILE.PROFILE_INTERVAL field.
FUNCTION GET_PROFILE_INTERVAL_NAME(p_PROFILE_INTERVAL IN NUMBER) RETURN VARCHAR2;

-- Return the CUT_DATE from the ISO Timestamp with timezone
-- Timestamp format for string YYYY-MM-DDTHH24:MI:SSXFFTZH:TZM (ISO 8601 standard)
-- The function will strip out the T and Z from the input string.
FUNCTION TO_CUT_DATE_FROM_ISO(p_DATE_STRING IN VARCHAR2) RETURN DATE;

-- Return the Date from the ISO Timestamp with timezone
-- Timestamp format for string YYYY-MM-DDTHH24:MI:SSXFFTZH:TZM (ISO 8601 standard)
-- The function will strip out the T and Z from the input string.
FUNCTION TO_DATE_FROM_ISO(p_DATE_STRING IN VARCHAR2, p_TIME_ZONE IN VARCHAR2) RETURN DATE;

-- TAKES THE GIVEN YEAR AND JUST CHANGES ITS YEAR TO THE GIVEN ONE
FUNCTION SET_DATE_YEAR(p_DATE IN DATE, p_YEAR IN NUMBER) RETURN DATE;

PROCEDURE TRANSFORM_COLLECTION_FOR_DST
	(
	p_COLLECTION IN NUMBER_COLLECTION,
	p_COLLECTION_DST_TYPE IN NUMBER,
	p_TARGET_DST_TYPE IN NUMBER,	
	p_INTERVAL IN VARCHAR2,
	p_TRANSFORMED_COLLECTION OUT NUMBER_COLLECTION
	);
	
PROCEDURE TRANSFORM_NUMBER_TBL_FOR_DST
	(
	p_SRC_TABLE IN GA.NUMBER_TABLE,
	p_TABLE_DST_TYPE IN NUMBER,
	p_TARGET_DST_TYPE IN NUMBER,	
	p_INTERVAL IN VARCHAR2,
	p_TRANSFORMED_TABLE OUT GA.NUMBER_TABLE
	);

FUNCTION IS_SPRING_AHEAD_DATE(p_LOCAL_DATE IN DATE) RETURN NUMBER;

FUNCTION IS_FALL_BACK_DATE(p_LOCAL_DATE IN DATE) RETURN NUMBER;	

FUNCTION GET_ORDINAL_NUMBER_LOCAL_DATE
(
   p_LOCAL_DATE 			IN DATE,
   p_LOCAL_DATE_INTERVAL  	IN VARCHAR2 DEFAULT CONSTANTS.INTERVAL_HOUR
) RETURN INTEGER;

END DATE_UTIL;
/
