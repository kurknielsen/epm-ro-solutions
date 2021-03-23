CREATE OR REPLACE PACKAGE BODY DATE_UTIL IS
----------------------------------------------------------------------------------------------------
-- How far from Sunday do we get when we do TRUNC(DATE,'DY')?
c_SUNDAY_OFFSET CONSTANT PLS_INTEGER := DATE '2007-09-30' - TRUNC(DATE '2007-09-30', 'DY');
-- How far from zero do we get when we do TO_CHAR(DATE,'D') where DATE is the start of the week
c_WEEK_START_OFFS CONSTANT PLS_INTEGER := TO_NUMBER(TO_CHAR(TRUNC(DATE '2007-09-30', 'DY'), 'D'));

-- Table of info for intervals
TYPE t_DATE_INFO IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(16);
g_INTERVAL_LENGTHS 	t_DATE_INFO;
g_INTERVAL_ORD		t_DATE_INFO;
TYPE t_NAMES IS TABLE OF VARCHAR2(16) INDEX BY PLS_INTEGER;
g_INTERVAL_NAMES	t_NAMEs;
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.15 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION WEEK_TRUNC
	(
	p_DATE IN DATE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	) RETURN DATE IS
v_WEEK_BEGIN VARCHAR2(32) := NVL(UPPER(p_WEEK_BEGIN),c_WEEK_BEGIN_SUNDAY);
v_FIRST_DAY NUMBER(1);
v_OFFSET_FROM_SUNDAY BOOLEAN := TRUE;
BEGIN
	-- determine start of week (0 through 6, sunday=0, monday=1, etc...)
	CASE v_WEEK_BEGIN
	WHEN c_WEEK_BEGIN_SUNDAY THEN
		v_FIRST_DAY := 0;
	WHEN c_WEEK_BEGIN_MONDAY THEN
		v_FIRST_DAY := 1;
	WHEN c_WEEK_BEGIN_TUESDAY THEN
		v_FIRST_DAY := 2;
	WHEN c_WEEK_BEGIN_WEDNESDAY THEN
		v_FIRST_DAY := 3;
	WHEN c_WEEK_BEGIN_THURSDAY THEN
		v_FIRST_DAY := 4;
	WHEN c_WEEK_BEGIN_FRIDAY THEN
		v_FIRST_DAY := 5;
	WHEN c_WEEK_BEGIN_SATURDAY THEN
		v_FIRST_DAY := 6;
	-- these two will not be in terms of offset from Sunday - instead they are offsets from locale's beginning of week
	WHEN c_WEEK_BEGIN_FIRST_OF_YEAR THEN
		v_FIRST_DAY := TO_NUMBER(TO_CHAR(TRUNC(p_DATE,'YY'),'D'))-c_WEEK_START_OFFS;
		v_OFFSET_FROM_SUNDAY := FALSE;
	WHEN c_WEEK_BEGIN_FIRST_OF_MONTH THEN
		v_FIRST_DAY := TO_NUMBER(TO_CHAR(TRUNC(p_DATE,'MM'),'D'))-c_WEEK_START_OFFS;
		v_OFFSET_FROM_SUNDAY := FALSE;
	ELSE
		-- unknown? this value will indicate using plain ol' TRUNC(DATE,'DY')
		v_FIRST_DAY := 0;
		v_OFFSET_FROM_SUNDAY := FALSE;
	END CASE;

	IF v_OFFSET_FROM_SUNDAY THEN
		-- translate this to be an offset from locale week begin vs. from Sunday
		v_FIRST_DAY := MOD(v_FIRST_DAY+c_SUNDAY_OFFSET, 7);
	END IF;
	-- trunc to given day of week
	RETURN TRUNC(p_DATE-v_FIRST_DAY,c_ABBR_WEEK)+v_FIRST_DAY;
END WEEK_TRUNC;
---------------------------------------------------------------------------------------------------
FUNCTION GET_START_DATE
	(
    p_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE IS
v_START_DATE DATE := TRUNC(p_DATE);
BEGIN
	IF p_INTERVAL_ABBR = c_ABBR_5MIN THEN
    	v_START_DATE := v_START_DATE + 5/1440;
    ELSIF p_INTERVAL_ABBR = c_ABBR_10MIN THEN
    	v_START_DATE := v_START_DATE + 10/1440;
    ELSIF p_INTERVAL_ABBR = c_ABBR_15MIN THEN
    	v_START_DATE := v_START_DATE + 15/1440;
    ELSIF p_INTERVAL_ABBR = c_ABBR_20MIN THEN
    	v_START_DATE := v_START_DATE + 20/1440;
    ELSIF p_INTERVAL_ABBR = c_ABBR_30MIN THEN
    	v_START_DATE := v_START_DATE + 30/1440;
    ELSIF NVL(p_INTERVAL_ABBR,c_ABBR_HOUR) = c_ABBR_HOUR THEN
    	v_START_DATE := v_START_DATE + 1/24;
    ELSE -- day and up are a second past midnight
		v_START_DATE := BEGIN_DATE_FOR_INTERVAL(v_START_DATE,p_INTERVAL_ABBR,p_WEEK_BEGIN) + 1/86400;
	END IF;
    RETURN v_START_DATE;
END GET_START_DATE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_END_DATE
	(
    p_BEGIN_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE IS
v_DATE DATE := p_BEGIN_DATE;
BEGIN
	IF p_INTERVAL_ABBR = c_ABBR_5MIN THEN
    	v_DATE := v_DATE + 5/1440 - 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_10MIN THEN
    	v_DATE := v_DATE + 10/1440 - 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_15MIN THEN
    	v_DATE := v_DATE + 15/1440 - 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_20MIN THEN
    	v_DATE := v_DATE + 20/1440 - 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_30MIN THEN
    	v_DATE := v_DATE + 30/1440 - 1/86400;
    ELSIF NVL(p_INTERVAL_ABBR,c_ABBR_HOUR) = c_ABBR_HOUR THEN
    	v_DATE := v_DATE + 1/24 - 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_WEEK THEN
    	v_DATE := TRUNC(END_DATE_FOR_INTERVAL(v_DATE,p_INTERVAL_ABBR,p_WEEK_BEGIN)+1);
    ELSIF p_INTERVAL_ABBR = c_ABBR_MONTH THEN
    	v_DATE := TRUNC(ADD_MONTHS(v_DATE,1));
    ELSIF p_INTERVAL_ABBR = c_ABBR_QUARTER THEN
    	v_DATE := TRUNC(ADD_MONTHS(v_DATE,3));
    ELSIF p_INTERVAL_ABBR = c_ABBR_YEAR THEN
    	v_DATE := TRUNC(ADD_MONTHS(v_DATE,12));
    ELSE --else assume day interval
    	v_DATE := TRUNC(v_DATE+1);
	END IF;
    RETURN v_DATE;
END GET_INTERVAL_END_DATE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_BEGIN_DATE
	(
    p_END_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE IS
v_DATE DATE := p_END_DATE;
BEGIN
	IF p_INTERVAL_ABBR = c_ABBR_5MIN THEN
    	v_DATE := v_DATE - 5/1440 + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_10MIN THEN
    	v_DATE := v_DATE - 10/1440 + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_15MIN THEN
    	v_DATE := v_DATE - 15/1440 + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_20MIN THEN
    	v_DATE := v_DATE - 20/1440 + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_30MIN THEN
    	v_DATE := v_DATE - 30/1440 + 1/86400;
    ELSIF NVL(p_INTERVAL_ABBR,c_ABBR_HOUR) = c_ABBR_HOUR THEN
    	v_DATE := v_DATE - 1/24 + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_WEEK THEN
    	v_DATE := BEGIN_DATE_FOR_INTERVAL(v_DATE-1/86400,p_INTERVAL_ABBR,p_WEEK_BEGIN) + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_MONTH THEN
    	v_DATE := TRUNC(ADD_MONTHS(v_DATE,-1)) + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_QUARTER THEN
    	v_DATE := TRUNC(ADD_MONTHS(v_DATE,-3)) + 1/86400;
    ELSIF p_INTERVAL_ABBR = c_ABBR_YEAR THEN
    	v_DATE := TRUNC(ADD_MONTHS(v_DATE,-12)) + 1/86400;
    ELSE --else assume day interval
    	v_DATE := TRUNC(v_DATE-1) + 1/86400;
	END IF;
    RETURN v_DATE;
END GET_INTERVAL_BEGIN_DATE;
---------------------------------------------------------------------------------------------------
FUNCTION ADVANCE_WEEK
	(
	p_DATE IN DATE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL,
	p_AMOUNT IN PLS_INTEGER := 1
	) RETURN DATE IS
v_D1 DATE;
v_D2 DATE;
BEGIN
	IF UPPER(SUBSTR(p_WEEK_BEGIN,1,5)) = 'FIRST' THEN
		-- see how long this week really is (could be less than 7 days if at the
		-- end of the month or end of the year)
		v_D1 := BEGIN_DATE_FOR_INTERVAL(p_DATE, 'Week', p_WEEK_BEGIN);
		v_D2 := v_D1;
		FOR i IN 1..ABS(p_AMOUNT) LOOP
			IF SIGN(p_AMOUNT) = -1 THEN
				-- back up one week
				v_D2 := BEGIN_DATE_FOR_INTERVAL(v_D2-1, 'Week', p_WEEK_BEGIN);
			ELSE
				-- increment by one week
				v_D2 := END_DATE_FOR_INTERVAL(v_D2, 'Week', p_WEEK_BEGIN)+1;
			END IF;
		END LOOP;
		RETURN p_DATE + (v_D2-v_D1);
	ELSE
		RETURN p_DATE + 7*p_AMOUNT;
	END IF;
END ADVANCE_WEEK;
---------------------------------------------------------------------------------------------------
FUNCTION ADVANCE_DATE
	(
	p_DATE IN DATE,
	p_INTERVAL IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL,
	p_AMOUNT IN PLS_INTEGER := 1
	) RETURN DATE IS
v_LEN PLS_INTEGER := g_INTERVAL_LENGTHS(NVL(UPPER(GET_INTERVAL_ABBREVIATION(p_INTERVAL)),c_ABBR_HOUR));
BEGIN
	IF v_LEN >= 0 THEN
		RETURN p_DATE + v_LEN*p_AMOUNT/1440;

	-- day and week are indicated by negative values: -1 and -7 respectively
	ELSIF v_LEN > -10 THEN
		-- week is handled special because 'week begin' setting can influence length of week
		IF v_LEN = -7 THEN
			RETURN ADVANCE_WEEK(p_DATE, p_WEEK_BEGIN, p_AMOUNT);
		ELSE
			RETURN p_DATE - v_LEN*p_AMOUNT;
		END IF;

	-- month, quarter, and year intervals are indicated by negative values:
	-- -10,-30, and -120 respectively
    ELSE -- v_MIN <= -10
		RETURN ADD_MONTHS(p_DATE, -v_LEN*p_AMOUNT/10);

	END IF;
END ADVANCE_DATE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_NUMBER_OF_MINUTES
	(
    p_INTERVAL IN VARCHAR2,
    p_DATE IN DATE := CONSTANTS.LOW_DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN NUMBER IS
v_INT VARCHAR2(4) := NVL(UPPER(GET_INTERVAL_ABBREVIATION(p_INTERVAL)),c_ABBR_HOUR);
v_LEN PLS_INTEGER := g_INTERVAL_LENGTHS(v_INT);
v_DATE1 DATE;
v_DATE2 DATE;
BEGIN
	IF v_LEN > 0 THEN
		RETURN v_LEN;

    -- day and greater intervals require special logic since they may vary in length
    -- depending on time zone (whether DST is observed or not)

	-- day and week are indicated by negative values: -1 and -7 respectively
	ELSIF v_LEN > -10 THEN
    	v_DATE1 := TRUNC(p_DATE, 'DD');
		IF v_LEN = -7 THEN
			-- handle weeks special since 'week begin' can influence length
			v_DATE2 := ADVANCE_WEEK(v_DATE1, p_WEEK_BEGIN);
		ELSE
	        v_DATE2 := v_DATE1-v_LEN;
		END IF;
        v_DATE1 := TO_CUT(v_DATE1, p_TIME_ZONE);
        v_DATE2 := TO_CUT(v_DATE2, p_TIME_ZONE);
    	RETURN (v_DATE2-v_DATE1)*24*60;

	-- month, quarter, and year intervals are indicated by negative values:
	-- -10,-30, and -120 respectively
    ELSE -- v_MIN <= -10
    	v_DATE1 := TRUNC(p_DATE, v_INT);
        v_DATE2 := ADD_MONTHS(v_DATE1,-v_LEN/10);
        v_DATE1 := TO_CUT(v_DATE1, p_TIME_ZONE);
        v_DATE2 := TO_CUT(v_DATE2, p_TIME_ZONE);
    	RETURN (v_DATE2-v_DATE1)*24*60;
  	END IF;
END GET_NUMBER_OF_MINUTES;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_DIVISOR
	(
    p_SRC_INTERVAL IN VARCHAR2,
    p_TRG_INTERVAL IN VARCHAR2,
    p_DATE IN DATE := CONSTANTS.LOW_DATE,
	p_TIME_ZONE IN VARCHAR2 := GA.LOCAL_TIME_ZONE,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN NUMBER IS
BEGIN
	-- Get ratio of one interval over the other. The date parameter is required because some
    -- intervals vary in length - like months.
	RETURN GET_NUMBER_OF_MINUTES(p_SRC_INTERVAL,p_DATE,p_TIME_ZONE,p_WEEK_BEGIN) /
			GET_NUMBER_OF_MINUTES(p_TRG_INTERVAL,p_DATE,p_TIME_ZONE,p_WEEK_BEGIN);
END GET_INTERVAL_DIVISOR;
---------------------------------------------------------------------------------------------------
FUNCTION HED_TRUNC
	(
    p_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE IS
BEGIN
	RETURN HED_TRUNC(p_DATE, p_INTERVAL_ABBR, p_WEEK_BEGIN, FALSE);
END HED_TRUNC;
---------------------------------------------------------------------------------------------------
FUNCTION HED_TRUNC
	(
    p_DATE IN DATE,
    p_INTERVAL_ABBR IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2,
	p_SCHEDULING_DATES IN BOOLEAN
    ) RETURN DATE IS
v_NUM_MIN NUMBER;
v_MIN PLS_INTEGER;
v_SEC PLS_INTEGER;
BEGIN
	IF SUBSTR(p_INTERVAL_ABBR,1,2) = 'MI' OR NVL(p_INTERVAL_ABBR,c_ABBR_HOUR) = c_ABBR_HOUR THEN
    	IF NVL(p_INTERVAL_ABBR,c_ABBR_HOUR) = c_ABBR_HOUR THEN
        	v_NUM_MIN := 60;
        ELSIF p_INTERVAL_ABBR = c_ABBR_30MIN THEN
        	v_NUM_MIN := 30;
        ELSIF p_INTERVAL_ABBR = c_ABBR_20MIN THEN
        	v_NUM_MIN := 20;
        ELSIF p_INTERVAL_ABBR = c_ABBR_15MIN THEN
        	v_NUM_MIN := 15;
        ELSIF p_INTERVAL_ABBR = c_ABBR_10MIN THEN
        	v_NUM_MIN := 10;
        ELSIF p_INTERVAL_ABBR = c_ABBR_5MIN THEN
        	v_NUM_MIN := 5;
        END IF;
        v_MIN := TO_NUMBER(TO_CHAR(p_DATE,'MI'));
        v_MIN := v_MIN MOD v_NUM_MIN;
		v_SEC := TO_NUMBER(TO_CHAR(p_DATE,'SS'));
        IF v_MIN = 0 AND v_SEC = 0 THEN
        	RETURN p_DATE;
        ELSE
        	RETURN TRUNC(p_DATE,'MI') + (v_NUM_MIN-v_MIN)/(24*60);
        END IF;
    ELSIF p_INTERVAL_ABBR = c_ABBR_WEEK THEN
		RETURN WEEK_TRUNC(p_DATE-1/86400,p_WEEK_BEGIN) + CASE WHEN p_SCHEDULING_DATES THEN 1/86400 ELSE 0 END;
	ELSE
    	RETURN TRUNC(p_DATE-1/86400,p_INTERVAL_ABBR) + CASE WHEN p_SCHEDULING_DATES THEN 1/86400 ELSE 0 END;
		END IF;
END HED_TRUNC;
---------------------------------------------------------------------------------------------------
FUNCTION PROPER_TRUNC_DATE
	(
    p_CUT_DATE IN DATE,
    p_INTERVAL1 IN VARCHAR2,
    p_INTERVAL2 IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2 := NULL,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE IS
v_INT1 VARCHAR2(4) := NVL(GET_INTERVAL_ABBREVIATION(p_INTERVAL1),c_ABBR_HOUR);
v_INT2 VARCHAR2(4) := NVL(GET_INTERVAL_ABBREVIATION(p_INTERVAL2),c_ABBR_HOUR);
v_DATE DATE;
BEGIN
	-- p_INTERVAL1 is the interval of p_DATE - so if its sub-daily then
    -- we must time-zone convert it before truncating
	IF p_TIME_ZONE IS NULL OR v_INT1 IN (c_ABBR_DAY, c_ABBR_WEEK, c_ABBR_MONTH, c_ABBR_QUARTER, c_ABBR_YEAR) THEN
    	v_DATE := p_CUT_DATE;
    ELSE
    	v_DATE := FROM_CUT(p_CUT_DATE,p_TIME_ZONE);
    END IF;

	IF INTERVAL_ORD(v_INT1) > INTERVAL_ORD(v_INT2) THEN
		v_DATE := HED_TRUNC(v_DATE, v_INT1, p_WEEK_BEGIN);
	ELSE
		v_DATE := HED_TRUNC(v_DATE, v_INT2, p_WEEK_BEGIN);
	END IF;

	RETURN v_DATE;
END PROPER_TRUNC_DATE;
---------------------------------------------------------------------------------------------------
FUNCTION INTERVAL_ORD
	(
	p_INTERVAL IN VARCHAR2
    ) RETURN NUMBER IS
v_INT_ABBR VARCHAR2(4) := NVL(UPPER(GET_INTERVAL_ABBREVIATION(p_INTERVAL)),c_ABBR_HOUR);
BEGIN
	-- PBM - 10/17 - This change is merged in from the 4.1.2 branch. Change originally made by Shruthi.
	-- This was hand editted due to the fact that this file was split into 2 files in the 4.1.4 branch.
	IF g_INTERVAL_ORD.EXISTS(v_INT_ABBR) THEN
		RETURN g_INTERVAL_ORD(v_INT_ABBR);
	ELSE
		RETURN 0; -- ???
	END IF;
END INTERVAL_ORD;
---------------------------------------------------------------------------------------------------
FUNCTION INTERVAL_NAME
	(
	p_INTERVAL_ORD IN NUMBER
    ) RETURN VARCHAR2 IS
BEGIN
	IF g_INTERVAL_NAMES.EXISTS(p_INTERVAL_ORD) THEN
		RETURN g_INTERVAL_NAMES(p_INTERVAL_ORD);
	ELSE
		RETURN NULL;
	END IF;
END INTERVAL_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION BEGIN_DATE_FOR_INTERVAL (
	p_DATE IN DATE,
    p_INTERVAL IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE IS
v_INTERVAL VARCHAR2(4) := GET_INTERVAL_ABBREVIATION(p_INTERVAL);
BEGIN
	IF v_INTERVAL = c_ABBR_MONTH THEN
    	-- interval begins on first of month
    	RETURN TRUNC(p_DATE, 'MM');
    ELSIF v_INTERVAL = c_ABBR_DAY THEN
    	-- truncate to day for daily interval
    	RETURN TRUNC(p_DATE);
    ELSIF v_INTERVAL = c_ABBR_WEEK THEN
		RETURN WEEK_TRUNC(p_DATE, p_WEEK_BEGIN);
    ELSIF v_INTERVAL = c_ABBR_YEAR THEN
    	-- interval begins on first of year
    	RETURN TRUNC(p_DATE, 'YY');
    ELSIF v_INTERVAL = c_ABBR_QUARTER THEN
    	-- interval begins on first of quarter
    	RETURN TRUNC(p_DATE, 'Q');
    ELSE
    	-- unrecognized? use daily
    	RETURN TRUNC(p_DATE);
    END IF;
END BEGIN_DATE_FOR_INTERVAL;
---------------------------------------------------------------------------------------------------
FUNCTION END_DATE_FOR_INTERVAL (
	p_BEGIN_DATE IN DATE,
    p_INTERVAL IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2 := NULL
    ) RETURN DATE IS
v_INTERVAL VARCHAR2(4) := GET_INTERVAL_ABBREVIATION(p_INTERVAL);
v_WEEK_BEGIN VARCHAR2(32) := NVL(UPPER(p_WEEK_BEGIN),c_WEEK_BEGIN_SUNDAY);
v_LAST_DAY DATE;
BEGIN
	IF v_INTERVAL = c_ABBR_MONTH THEN
    	-- return last day of month
        RETURN ADD_MONTHS(p_BEGIN_DATE,1)-1;
    ELSIF v_INTERVAL = c_ABBR_DAY THEN
    	-- begin and end for one day interval
    	RETURN p_BEGIN_DATE;
    ELSIF v_INTERVAL = c_ABBR_WEEK THEN
    	-- six days away for weekly interval
        IF v_WEEK_BEGIN = c_WEEK_BEGIN_FIRST_OF_YEAR THEN
        	v_LAST_DAY := ADD_MONTHS(TRUNC(p_BEGIN_DATE,'YY'),12)-1;
            IF p_BEGIN_DATE+6 > v_LAST_DAY THEN
            	RETURN v_LAST_DAY;
            END IF;
        ELSIF v_WEEK_BEGIN = c_WEEK_BEGIN_FIRST_OF_MONTH THEN
        	v_LAST_DAY := ADD_MONTHS(TRUNC(p_BEGIN_DATE,'MM'),1)-1;
            IF p_BEGIN_DATE+6 > v_LAST_DAY THEN
            	RETURN v_LAST_DAY;
            END IF;
		END IF;
	   	RETURN p_BEGIN_DATE+6;
    ELSIF v_INTERVAL = c_ABBR_YEAR THEN
    	-- interval ends on last of year
        RETURN ADD_MONTHS(p_BEGIN_DATE,12)-1;
    ELSIF v_INTERVAL = c_ABBR_QUARTER THEN
    	-- interval ends on last of quarter (every three months)
        RETURN ADD_MONTHS(p_BEGIN_DATE,3)-1;
    ELSE
    	-- unrecognized? use daily
    	RETURN p_BEGIN_DATE;
    END IF;
END END_DATE_FOR_INTERVAL;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ORA_TRUNC_INTERVAL
	(
    p_INTERVAL IN VARCHAR2
    ) RETURN VARCHAR2 IS
BEGIN
	RETURN NVL(SUBSTR(GET_INTERVAL_ABBREVIATION(p_INTERVAL),1,2),c_ABBR_HOUR);
END GET_ORA_TRUNC_INTERVAL;
---------------------------------------------------------------------------------------------------
FUNCTION IS_SUB_DAILY
	(
	p_INTERVAL IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	RETURN INTERVAL_ORD(p_INTERVAL) < c_ORD_DAY;
END IS_SUB_DAILY;
---------------------------------------------------------------------------------------------------
FUNCTION IS_SUB_DAILY_NUM
	(
	p_INTERVAL IN VARCHAR2
	) RETURN NUMBER IS
BEGIN
	RETURN UT.NUMBER_FROM_BOOLEAN(IS_SUB_DAILY(p_INTERVAL));
END IS_SUB_DAILY_NUM;
---------------------------------------------------------------------------------------------------
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
	) AS
v_INT VARCHAR2(4) := GET_INTERVAL_ABBREVIATION(p_INTERVAL);
v_DATE DATE := HED_TRUNC(p_DATE_TIME, v_INT, p_WEEK_BEGIN, TRUE);
BEGIN
	IF IS_SUB_DAILY(v_INT) THEN
		p_BEGIN_DATE := GET_INTERVAL_BEGIN_DATE(v_DATE, v_INT, p_WEEK_BEGIN);
		p_END_DATE := v_DATE;
	ELSE
		p_BEGIN_DATE := v_DATE;
		p_END_DATE := GET_INTERVAL_END_DATE(v_DATE, v_INT, p_WEEK_BEGIN);
	END IF;
END GET_DATE_RANGE;
---------------------------------------------------------------------------------------------------
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
	) AS
DUMMY DATE;
BEGIN

	IF IS_SUB_DAILY(p_INTERVAL) THEN
		GET_DATE_RANGE(p_BEGIN_DAY, p_INTERVAL, p_EXPANDED_BEGIN_DAY, DUMMY, p_WEEK_BEGIN);
		GET_DATE_RANGE(p_END_DAY, p_INTERVAL, DUMMY, p_EXPANDED_END_DAY, p_WEEK_BEGIN);
	ELSE
		GET_DATE_RANGE(TRUNC(p_BEGIN_DAY) + 1/86400, p_INTERVAL, p_EXPANDED_BEGIN_DAY, DUMMY, p_WEEK_BEGIN);
		GET_DATE_RANGE(TRUNC(p_END_DAY) + 1/86400, p_INTERVAL, DUMMY, p_EXPANDED_END_DAY, p_WEEK_BEGIN);
		p_EXPANDED_END_DAY := p_EXPANDED_END_DAY - 1;
	END IF;

END EXPAND_DAY_RANGE_FOR_INTERVAL;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_FOR_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_RTN INTERCHANGE_TRANSACTION.TRANSACTION_INTERVAL%TYPE;
BEGIN
	SELECT TRANSACTION_INTERVAL INTO v_RTN FROM INTERCHANGE_TRANSACTION WHERE TRANSACTION_ID = p_TRANSACTION_ID;
	RETURN v_RTN;
END GET_INTERVAL_FOR_TRANSACTION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_FOR_MARKET_PRICE
	(
	p_MARKET_PRICE_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_RTN MARKET_PRICE.MARKET_PRICE_INTERVAL%TYPE;
BEGIN
	SELECT MARKET_PRICE_INTERVAL INTO v_RTN FROM MARKET_PRICE WHERE MARKET_PRICE_ID = p_MARKET_PRICE_ID;
	RETURN v_RTN;
END GET_INTERVAL_FOR_MARKET_PRICE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_FOR_MEAS_SOURCE
	(
	p_MEASUREMENT_SOURCE_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_RTN MEASUREMENT_SOURCE.MEASUREMENT_SOURCE_INTERVAL%TYPE;
BEGIN
	SELECT MEASUREMENT_SOURCE_INTERVAL INTO v_RTN FROM MEASUREMENT_SOURCE WHERE MEASUREMENT_SOURCE_ID = p_MEASUREMENT_SOURCE_ID;
	RETURN v_RTN;
END GET_INTERVAL_FOR_MEAS_SOURCE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_FOR_PSE_STATEMENT
	(
	p_PSE_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_RTN PURCHASING_SELLING_ENTITY.STATEMENT_INTERVAL%TYPE;
BEGIN
	SELECT STATEMENT_INTERVAL INTO v_RTN FROM PURCHASING_SELLING_ENTITY WHERE PSE_ID = p_PSE_ID;
	RETURN v_RTN;
END GET_INTERVAL_FOR_PSE_STATEMENT;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_FOR_CALC_PROCESS
	(
	p_CALC_PROCESS_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_RTN CALCULATION_PROCESS.PROCESS_INTERVAL%TYPE;
BEGIN
	SELECT PROCESS_INTERVAL INTO v_RTN FROM CALCULATION_PROCESS WHERE CALC_PROCESS_ID = p_CALC_PROCESS_ID;
	RETURN v_RTN;
END GET_INTERVAL_FOR_CALC_PROCESS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_FOR_TRAIT_GROUP
	(
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_RTN TRANSACTION_TRAIT_GROUP.TRAIT_GROUP_INTERVAL%TYPE;
BEGIN
	SELECT TRAIT_GROUP_INTERVAL INTO v_RTN FROM TRANSACTION_TRAIT_GROUP WHERE TRAIT_GROUP_ID = p_TRAIT_GROUP_ID;
	IF v_RTN = TG.g_OFFER_INTERVAL THEN
		v_RTN := MM.GET_BID_OFFER_INTERVAL(p_TRANSACTION_ID);
	END IF;
	RETURN v_RTN;
END GET_INTERVAL_FOR_TRAIT_GROUP;
---------------------------------------------------------------------------------------------------
-- Return the larger of the two intervals.
FUNCTION GET_LARGER_INTERVAL
	(
	p_INTERVAL1 IN VARCHAR2,
	p_INTERVAL2 IN VARCHAR2
	) RETURN VARCHAR2 IS
	v_INTERVAL_NUM1 NUMBER;
	v_INTERVAL_NUM2 NUMBER;
	v_RTN VARCHAR2(32);
BEGIN
	v_INTERVAL_NUM1 := GET_INTERVAL_NUMBER(p_INTERVAL1);
	v_INTERVAL_NUM2 := GET_INTERVAL_NUMBER(p_INTERVAL2);
	IF v_INTERVAL_NUM1 >= v_INTERVAL_NUM2 THEN
		v_RTN :=  p_INTERVAL1;
	ELSE
		v_RTN := p_INTERVAL2;
	END IF;
	RETURN GET_INTERVAL_ABBREVIATION(v_RTN);
END GET_LARGER_INTERVAL;
---------------------------------------------------------------------------------------------------
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
	) RETURN DATE IS

	v_PROC_INTERVAL			VARCHAR2(8) := NVL(GET_INTERVAL_ABBREVIATION(p_PROCESS_INTERVAL),'HH');
	v_INTERVAL				VARCHAR2(32) := NVL(GET_LARGER_INTERVAL(GET_INTERVAL_ABBREVIATION(p_DATA_INTERVAL), v_PROC_INTERVAL),'HH');
	v_DATE					DATE := p_CUT_DATE;

BEGIN

	-- if the incoming data date is sub-daily but the process interval is daily-or-greater, we
	-- must time-zone convert the date to local time
	IF IS_SUB_DAILY(p_DATA_INTERVAL) AND NOT IS_SUB_DAILY(p_PROCESS_INTERVAL) THEN
		v_DATE := FROM_CUT(p_CUT_DATE, p_TIME_ZONE);
	END IF;

	v_DATE := HED_TRUNC(v_DATE, v_INTERVAL, p_WEEK_BEGIN, p_SCHEDULING_DATES);

	IF IS_SUB_DAILY(v_INTERVAL) AND v_INTERVAL <> v_PROC_INTERVAL THEN
		-- when both intervals are sub-daily and the process interval is the smaller one, we now must find the first process
		-- interval in the data interval and return it. For example: Data = Hour, Process = 15 Minute, Date = 4:00. At this point
		-- we'll have 4:00 after call to HED_TRUNC. We want the first 15 minute interval therein though: 3:15.
		v_DATE := GET_INTERVAL_BEGIN_DATE(v_DATE, v_INTERVAL, p_WEEK_BEGIN); -- get starting second of the data interval
		v_DATE := GET_INTERVAL_END_DATE(v_DATE, v_PROC_INTERVAL, p_WEEK_BEGIN); -- find corresponding interval-ending date for process interval
	END IF;

	RETURN v_DATE;

END GET_PROCESS_BEGIN_DATE;
---------------------------------------------------------------------------------------------------
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
	) RETURN DATE IS

	v_PROC_INTERVAL			VARCHAR2(8) := NVL(GET_INTERVAL_ABBREVIATION(p_PROCESS_INTERVAL),'HH');
	v_INTERVAL				VARCHAR2(32) := NVL(GET_LARGER_INTERVAL(GET_INTERVAL_ABBREVIATION(p_DATA_INTERVAL), v_PROC_INTERVAL),'HH');
	v_DATE					DATE := p_CUT_DATE;

BEGIN

	-- if the incoming data date is sub-daily but the process interval is daily-or-greater, we
	-- must time-zone convert the date to local time
	IF IS_SUB_DAILY(p_DATA_INTERVAL) AND NOT IS_SUB_DAILY(p_PROCESS_INTERVAL) THEN
		v_DATE := FROM_CUT(p_CUT_DATE, p_TIME_ZONE);
	END IF;

	v_DATE := HED_TRUNC(v_DATE, v_INTERVAL, p_WEEK_BEGIN, p_SCHEDULING_DATES);

	IF NOT IS_SUB_DAILY(v_INTERVAL) AND v_INTERVAL <> v_PROC_INTERVAL THEN
		-- if data interval is greater than process interval and is daily-or-greater then make
		-- sure end date is set to last day of the data interval. For example: Data = Month, Process = Day, Date = 1/1/2009.
		-- At this point we have 1/1/2009. But we want process end date to be 1/31/2009 - last day of the data interval.
		v_DATE := GET_INTERVAL_END_DATE(v_DATE, v_INTERVAL, p_WEEK_BEGIN); -- get interval end timestamp
		v_DATE := GET_INTERVAL_BEGIN_DATE(v_DATE, 'DD', p_WEEK_BEGIN); -- get start timestamp for that day
	END IF;

	RETURN v_DATE;

END GET_PROCESS_END_DATE;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_DATA_INTERVAL_INFO
	(
	p_TABLE_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_CRITERIA IN UT.STRING_MAP,
	p_INTERVAL OUT VARCHAR2,
	p_USE_SCHEDULING_DATES OUT BOOLEAN
	) AS
BEGIN
	IF p_TABLE_NAME = 'BILLING_STATEMENT' THEN
		-- Entity ID is a PSE - get its statement interval
		p_INTERVAL := GET_INTERVAL_FOR_PSE_STATEMENT(p_ENTITY_ID);
		p_USE_SCHEDULING_DATES := FALSE;
	ELSIF p_TABLE_NAME = 'CALCULATION_RUN' THEN
		-- Entity ID is a Calculation Process - get its interval
		p_INTERVAL := GET_INTERVAL_FOR_CALC_PROCESS(p_ENTITY_ID);
		p_USE_SCHEDULING_DATES := TRUE;
	ELSIF p_TABLE_NAME = 'IT_SCHEDULE' THEN
		-- Entity ID is an Interchange Transaction - get its interval
		p_INTERVAL := GET_INTERVAL_FOR_TRANSACTION(p_ENTITY_ID);
		p_USE_SCHEDULING_DATES := TRUE;
	ELSIF p_TABLE_NAME = 'MARKET_PRICE_VALUE' THEN
		-- Entity ID is a Market Price - get its interval
		p_INTERVAL := GET_INTERVAL_FOR_MARKET_PRICE(p_ENTITY_ID);
		p_USE_SCHEDULING_DATES := FALSE;
	ELSIF p_TABLE_NAME = 'MEASUREMENT_SOURCE_VALUE' THEN
		-- Entity ID is a Market Price - get its interval
		p_INTERVAL := GET_INTERVAL_FOR_MEAS_SOURCE(p_ENTITY_ID);
		p_USE_SCHEDULING_DATES := TRUE;
	ELSIF p_TABLE_NAME = 'TX_SUB_STATION_METER_PT_VALUE' THEN
		p_INTERVAL := 'Hour';
		p_USE_SCHEDULING_DATES := TRUE; -- since interval is always hour, this really doesn't matter
	ELSIF p_TABLE_NAME = 'IT_TRAIT_SCHEDULE' THEN
		-- Entity ID is an Interchange Transaction - but we need to get the trait group's interval
		-- and then fallback on transaction's offer interval if needed
		IF p_CRITERIA.EXISTS('TRAIT_GROUP_ID') THEN
			p_INTERVAL := GET_INTERVAL_FOR_TRAIT_GROUP(p_CRITERIA('TRAIT_GROUP_ID'), p_ENTITY_ID);
			p_USE_SCHEDULING_DATES := TRUE;
		ELSE
			-- no trait group? raise exception
			ERRS.RAISE_BAD_ARGUMENT('Table Name', p_TABLE_NAME, 'To determine interval of data in this table requires criteria to specify TRAIT_GROUP_ID');
		END IF;
	ELSE
		-- not one of these known tables? raise exception
		ERRS.RAISE_BAD_ARGUMENT('Table Name', p_TABLE_NAME, 'Cannot determine interval of data in this table');
	END IF;
END GET_DATA_INTERVAL_INFO;
---------------------------------------------------------------------------------------------------
PROCEDURE CUT_DATE_RANGE_SCHEDULING
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR,
	p_DATA_INTERVAL IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS
BEGIN
	IF INTERVAL_IS_ATLEAST_DAILY(p_DATA_INTERVAL) THEN
		p_CUT_BEGIN_DATE := TRUNC(p_BEGIN_DATE) + 1/86400;
		p_CUT_END_DATE := TRUNC(p_END_DATE) + 1/86400;
	ELSE
		UT.CUT_DATE_RANGE(CONSTANTS.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, p_INTERVAL, p_DATA_INTERVAL, p_CUT_BEGIN_DATE, p_CUT_END_DATE);
	END IF;
END CUT_DATE_RANGE_SCHEDULING;
---------------------------------------------------------------------------------------------------
FUNCTION IS_ANNIVERSARY_IN_PERIOD
	(
	p_TARGET_DATE IN DATE,
	p_PERIOD_BEGIN_DATE IN DATE,
	p_PERIOD_END_DATE IN DATE
	) RETURN BOOLEAN IS

BEGIN

	IF GET_ANNIVERSARY_IN_PERIOD(p_TARGET_DATE, p_PERIOD_BEGIN_DATE, p_PERIOD_END_DATE) IS NULL THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;

END IS_ANNIVERSARY_IN_PERIOD;
---------------------------------------------------------------------------------------------------
-- Returns NULL if anniversary does NOT fall within specified period.
-- Otherwise, returns the anniversary of p_INTIIAL_DATE that does fall within period.
FUNCTION GET_ANNIVERSARY_IN_PERIOD
	(
	p_TARGET_DATE IN DATE,
	p_PERIOD_BEGIN_DATE IN DATE,
	p_PERIOD_END_DATE IN DATE
	) RETURN DATE IS

	v_YR1 PLS_INTEGER;
    v_YR2 PLS_INTEGER;
    v_D   DATE;

	----
	-- GET THE INTIAL DATE IN THE TARGET YEAR
	FUNCTION GET_ANNIVERSARY
		  (
		  p_INITIAL_DATE IN DATE,
		  p_TARGET_YEAR  IN PLS_INTEGER
		  ) RETURN DATE IS

		v_MMDD VARCHAR2(4) := TO_CHAR(p_INITIAL_DATE, 'mmdd');

	BEGIN
		 IF v_MMDD = '0229' THEN -- handle leap day to return 2/28 on non-leap-years
				 RETURN TO_DATE('0301' || p_TARGET_YEAR, 'mmddyyyy') - 1;
		  ELSE
				 RETURN TO_DATE(v_MMDD || p_TARGET_YEAR, 'mmddyyyy');
		  END IF;
	END GET_ANNIVERSARY;
	----
	-- RETURN THE YEAR OF THE DATE
	FUNCTION GET_YEAR(p_DATE IN DATE) RETURN PLS_INTEGER IS
	BEGIN
		  RETURN TO_NUMBER(TO_CHAR(p_DATE, 'yyyy'));
	END GET_YEAR;

BEGIN

	-- A DATE CAN'T HAVE IT'S ANNIVERSARY IN THE TARGET PERIOD IF IT IS ALREADY CONTAINED WITH SAID TARGET PERIOD
	IF p_TARGET_DATE BETWEEN p_PERIOD_BEGIN_DATE AND p_PERIOD_END_DATE THEN
		RETURN NULL;
	END IF;

	v_YR1 := GET_YEAR(p_PERIOD_BEGIN_DATE);
    v_YR2 := GET_YEAR(p_PERIOD_END_DATE);

    v_D := GET_ANNIVERSARY(p_TARGET_DATE, v_YR1);

    IF v_D BETWEEN p_PERIOD_BEGIN_DATE AND p_PERIOD_END_DATE THEN
		RETURN v_D;
    ELSIF v_YR2 > v_YR1 THEN
		v_D := GET_ANNIVERSARY(p_TARGET_DATE, v_YR2);

		IF v_D BETWEEN p_PERIOD_BEGIN_DATE AND p_PERIOD_END_DATE THEN
			RETURN v_D;
		END IF;
	END IF;

    RETURN NULL;
END GET_ANNIVERSARY_IN_PERIOD;
---------------------------------------------------------------------------------------------------
FUNCTION DATES_IN_INTERVAL_RANGE
	(
	p_RANGE_BEGIN IN DATE,
	p_RANGE_END IN DATE,
	p_INTERVAL IN VARCHAR2
	) RETURN DATE_COLLECTION PIPELINED IS


	v_HED_BEGIN DATE := HED_TRUNC(p_RANGE_BEGIN,
								GET_INTERVAL_ABBREVIATION(p_INTERVAL));
	v_HED_END DATE := HED_TRUNC(p_RANGE_END,
								GET_INTERVAL_ABBREVIATION(p_INTERVAL));
	v_DATE DATE := v_HED_BEGIN;

	v_IS_SUB_DAILY BOOLEAN := IS_SUB_DAILY(p_INTERVAL);

BEGIN -- HED_TRUNK

	WHILE (v_DATE < v_HED_END AND v_IS_SUB_DAILY)
		 OR (v_DATE <= v_HED_END AND NOT v_IS_SUB_DAILY) LOOP
		v_DATE := ADVANCE_DATE(v_DATE, p_INTERVAL);
		PIPE ROW(v_DATE);
	END LOOP;

	RETURN;

END DATES_IN_INTERVAL_RANGE;
---------------------------------------------------------------------------------------------------
FUNCTION TO_CHAR_ISO(p_CUT_DATE DATE) RETURN VARCHAR2 IS
v_OFFSET VARCHAR2(8);
BEGIN
	SELECT Z.STANDARD_TIME_ZONE_OFFSET INTO v_OFFSET
	FROM SYSTEM_TIME_ZONE Z
	WHERE TIME_ZONE = CUT_TIME_ZONE();

  	RETURN TO_CHAR(p_CUT_DATE, 'YYYY-MM-DD') || 'T' || TO_CHAR(p_CUT_DATE, 'HH24:MI:SS') || v_OFFSET;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.RAISE(MSGCODES.c_ERR_MISSING_TZ_OFFSET, 'Time Zone = ' || CUT_TIME_ZONE());
END TO_CHAR_ISO;
---------------------------------------------------------------------------------------------------
FUNCTION TO_CHAR_ISO_AS_GMT(p_CUT_DATE DATE) RETURN VARCHAR2 IS
v_GMT_DATE DATE;

BEGIN
 v_GMT_DATE := FROM_TZ(CAST(p_CUT_DATE AS TIMESTAMP), RO_TZ_OFFSET(GA.CUT_TIME_ZONE)) AT TIME ZONE 'GMT';

  RETURN TO_CHAR(v_GMT_DATE, 'YYYY-MM-DD') || 'T' || TO_CHAR(v_GMT_DATE, 'HH24:MI:SS') || 'Z';
END TO_CHAR_ISO_AS_GMT;
---------------------------------------------------------------------------------------------------
FUNCTION GET_PROFILE_INTERVAL_NAME(p_PROFILE_INTERVAL IN NUMBER) RETURN VARCHAR2 IS
BEGIN
	-- Get the interval name from the profile interval num.
	RETURN CASE p_PROFILE_INTERVAL
		WHEN 1 THEN c_NAME_DAY
		WHEN 24 THEN c_NAME_HOUR
		WHEN 48 THEN c_NAME_30MIN
		WHEN 72 THEN c_NAME_20MIN
		WHEN 96 THEN c_NAME_15MIN
		WHEN 144 THEN c_NAME_10MIN
		WHEN 288 THEN c_NAME_5MIN
		ELSE NULL
	END;

END GET_PROFILE_INTERVAL_NAME;
--------------------------------------------------------------------------------
FUNCTION TO_DATE_FROM_ISO
	(
	p_DATE_STRING IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2
	) RETURN DATE IS

	v_TIMESTAMP_STRING   VARCHAR2(100) := NULL;
	v_TIMESTAMP_TZ       TIMESTAMP WITH TIME ZONE;
	v_TIMESTAMP_DATE     DATE := NULL;
  
BEGIN
	--LOGS.LOG_INFO('p_DATE_STRING => "' || p_DATE_STRING || '"'
			   --|| ' p_TIME_ZONE => "' || p_TIME_ZONE || '"');
	v_TIMESTAMP_STRING := REPLACE(REPLACE(p_DATE_STRING,'T',' '),'Z','');
	--LOGS.LOG_INFO('v_TIMESTAMP_STRING: "' || v_TIMESTAMP_STRING || '"');
	v_TIMESTAMP_TZ := TO_TIMESTAMP_TZ(v_TIMESTAMP_STRING, 'YYYY-MM-DD HH24:MI:SSXFFTZH:TZM');
	v_TIMESTAMP_DATE := CAST(v_TIMESTAMP_TZ AT TIME ZONE '-0:00' AS DATE);

	RETURN FROM_TZ(CAST(v_TIMESTAMP_DATE AS TIMESTAMP), 'GMT') AT TIME ZONE RO_TZ_OFFSET(p_TIME_ZONE);

END TO_DATE_FROM_ISO;
--------------------------------------------------------------------------------
FUNCTION TO_CUT_DATE_FROM_ISO
	(
	p_DATE_STRING IN VARCHAR2
	) RETURN DATE IS

BEGIN

	RETURN TO_DATE_FROM_ISO(p_DATE_STRING, CUT_TIME_ZONE);

END TO_CUT_DATE_FROM_ISO;
---------------------------------------------------------------------------------------------------
FUNCTION SET_DATE_YEAR
	(
	p_DATE IN DATE,
	p_YEAR IN NUMBER
	) RETURN DATE IS

	v_YEAR_DIFF NUMBER(4) := p_YEAR - TO_NUMBER(TO_CHAR(p_DATE, 'YYYY'));

BEGIN

	RETURN ADD_MONTHS(p_DATE, v_YEAR_DIFF*12);

END SET_DATE_YEAR;
---------------------------------------------------------------------------------------------------
PROCEDURE TRANSFORM_COLLECTION_FOR_DST
	(
	p_COLLECTION IN NUMBER_COLLECTION,
	p_COLLECTION_DST_TYPE IN NUMBER,
	p_TARGET_DST_TYPE IN NUMBER,
	p_INTERVAL IN VARCHAR2,
	p_TRANSFORMED_COLLECTION OUT NUMBER_COLLECTION
	) AS

	v_INTERVAL_DIVISOR NUMBER(3) := DATE_UTIL.GET_INTERVAL_DIVISOR(DATE_UTIL.c_NAME_DAY, p_INTERVAL);

BEGIN

    -- TAKE THE INCOMING NUMBER_COLLECTION, A TABLE OF INTERVALS WHOSE SIZE IS DICTATED
    -- BY THE INTERVAL (p_INTERVAL) AND SOURCE DST TYPE (COLLECTION_DST_TYPE) AND TRANSFORM IT INTO
    -- AN OUTGOING NUMBER_COLLECTION WHOSE SIZE IS DICTATED BY THE TARGET DAY'S DST_TYPE
    -- THIS TRANSFORMATION IS DONE USING THE DST_INTERVAL_MAP
	SELECT COLL.VAL
	BULK COLLECT INTO p_TRANSFORMED_COLLECTION
	FROM (SELECT ROWNUM/v_INTERVAL_DIVISOR AS SRC_INTVL,
			x.COLUMN_VALUE AS VAL
		  FROM TABLE(CAST(p_COLLECTION AS NUMBER_COLLECTION)) x) COLL,
		  DST_INTERVAL_MAP DIM
	WHERE DIM.SRC_DST_TYPE = p_COLLECTION_DST_TYPE
		AND DIM.TGT_DST_TYPE = p_TARGET_DST_TYPE
		AND DIM.INTERVAL = p_INTERVAL
		AND DIM.SRC_INTERVAL = COLL.SRC_INTVL
	ORDER BY DIM.TGT_INTERVAL;

END TRANSFORM_COLLECTION_FOR_DST;
---------------------------------------------------------------------------------------------------
PROCEDURE TRANSFORM_NUMBER_TBL_FOR_DST
	(
	p_SRC_TABLE IN GA.NUMBER_TABLE,
	p_TABLE_DST_TYPE IN NUMBER,
	p_TARGET_DST_TYPE IN NUMBER,
	p_INTERVAL IN VARCHAR2,
	p_TRANSFORMED_TABLE OUT GA.NUMBER_TABLE
	) AS

	v_COLLECTION NUMBER_COLLECTION;

BEGIN

	UT.CONVERT_NUM_TBL_TO_COLLECTION(p_SRC_TABLE,
									v_COLLECTION);

	TRANSFORM_COLLECTION_FOR_DST(v_COLLECTION,
								p_TABLE_DST_TYPE,
								p_TARGET_DST_TYPE,
								p_INTERVAL,
								v_COLLECTION);

	UT.CONVERT_COLLECTION_TO_NUM_TBL(v_COLLECTION,
									p_TRANSFORMED_TABLE);

END TRANSFORM_NUMBER_TBL_FOR_DST;
---------------------------------------------------------------------------------------------------
FUNCTION IS_FALL_BACK_DATE(p_LOCAL_DATE IN DATE) RETURN NUMBER AS
	v_MONTH NUMBER(2) := EXTRACT(MONTH FROM p_LOCAL_DATE);
BEGIN
	IF v_MONTH IN (10, 11) THEN
		IF TRUNC(p_LOCAL_DATE) = TRUNC(DST_FALL_BACK_DATE(p_LOCAL_DATE)) THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	ELSE
		RETURN 0;
	END IF;
END IS_FALL_BACK_DATE;
---------------------------------------------------------------------------------------------------
FUNCTION IS_SPRING_AHEAD_DATE(p_LOCAL_DATE IN DATE) RETURN NUMBER AS
	v_MONTH NUMBER(2) := EXTRACT(MONTH FROM p_LOCAL_DATE);
BEGIN
	IF v_MONTH IN (3, 4) THEN
		IF TRUNC(p_LOCAL_DATE) = TRUNC(DST_SPRING_AHEAD_DATE(p_LOCAL_DATE)) THEN
			RETURN 1;
		ELSE
			RETURN 0;
		END IF;
	ELSE
		RETURN 0;
	END IF;
END IS_SPRING_AHEAD_DATE;
---------------------------------------------------------------------------------------------------
/*
Function:GET_ORDINAL_NUMBER_LOCAL_DATE
		 This function returns the ordinal number for passed in local-date.
		 Extra hour should at FALL_BACK should return 25.
		 Extra sub-hours at FALL_BACK should return 49 and 50 for ½ hourly, and 97, 98, 99 and 100 for ¼ hourly.
		 Missing hour at SPRING_AHEAD should return 1.
		 Missing sub-hours at SPRING_AHEAD should return ordinal numbers for HE 1.
*/

FUNCTION GET_ORDINAL_NUMBER_LOCAL_DATE
(
   p_LOCAL_DATE 			IN DATE,
   p_LOCAL_DATE_INTERVAL  	IN VARCHAR2 DEFAULT CONSTANTS.INTERVAL_HOUR
) RETURN INTEGER
IS
   v_RETURN 				INTEGER;
   b_IS_DST_FALL_BACK_HOUR		BOOLEAN;
   b_IS_DST_SPRING_AHEAD_DAY	BOOLEAN;

   v_HOUR	INTEGER;
   v_MINUTE	INTEGER;

   k_15_MIN_MULTIPLIER CONSTANT INTEGER := 4;
   k_30_MIN_MULTIPLIER CONSTANT INTEGER := 2;

   k_1_SEC CONSTANT NUMBER := (1/86400);
   k_1_HR  CONSTANT NUMBER := (1/24);

   TYPE t_HOURS_IN_INTERVAL IS TABLE OF INTEGER INDEX BY VARCHAR2(32);
   g_HOURS_IN_INTERVAL t_HOURS_IN_INTERVAL;
BEGIN
   -- Validate the INTERVAL specified
   ASSERT(p_LOCAL_DATE IS NOT NULL, 'Date cannot be empty');
   ASSERT(p_LOCAL_DATE_INTERVAL IN (CONSTANTS.INTERVAL_HOUR, CONSTANTS.INTERVAL_30_MINUTE, CONSTANTS.INTERVAL_15_MINUTE,
                                    CONSTANTS.INTERVAL_DAY, CONSTANTS.INTERVAL_WEEK, CONSTANTS.INTERVAL_QUARTER,
									CONSTANTS.INTERVAL_YEAR),
		  'Pivoting Date Interval specified is invalid');

   -- Is this at DAY, WEEK, MONTH, QUARTER, YEAR level?
   IF p_LOCAL_DATE_INTERVAL NOT IN (CONSTANTS.INTERVAL_HOUR, CONSTANTS.INTERVAL_30_MINUTE, CONSTANTS.INTERVAL_15_MINUTE) THEN
      -- Shortcircuit and return immediately
      v_RETURN := 1;
   ELSE
      g_HOURS_IN_INTERVAL(CONSTANTS.INTERVAL_HOUR)      := 24;
	  g_HOURS_IN_INTERVAL(CONSTANTS.INTERVAL_15_MINUTE) := 96;
	  g_HOURS_IN_INTERVAL(CONSTANTS.INTERVAL_30_MINUTE) := 48;

	  -- Determine if it is fall-back "hour" and if it is spring-ahead "day"
      b_IS_DST_FALL_BACK_HOUR    := CASE WHEN EXTRACT(SECOND FROM CAST(p_LOCAL_DATE AS TIMESTAMP)) = 1 THEN TRUE ELSE FALSE END;
	  b_IS_DST_SPRING_AHEAD_DAY  := SYS.DIUTIL.INT_TO_BOOL(IS_SPRING_AHEAD_DATE(p_LOCAL_DATE));

      -- Hour and Minute in LOCAL_TIME
      v_HOUR   := EXTRACT(HOUR FROM CAST(p_LOCAL_DATE AS TIMESTAMP));
      v_MINUTE := EXTRACT(MINUTE FROM CAST(p_LOCAL_DATE AS TIMESTAMP));

	  -- If it is the -th hour of the next day, treat it as 24 HOUR
	  IF v_MINUTE = 0 AND v_HOUR = 0 THEN
         v_HOUR := 24;
      END IF;

	  IF b_IS_DST_FALL_BACK_HOUR AND p_LOCAL_DATE_INTERVAL = CONSTANTS.INTERVAL_HOUR THEN
	     -- Do DST_FALL_BACK call
	     v_RETURN := 25;
	  ELSIF b_IS_DST_FALL_BACK_HOUR AND p_LOCAL_DATE_INTERVAL = CONSTANTS.INTERVAL_15_MINUTE THEN
	     -- Do DST_FALL_BACK call
		 IF v_MINUTE = 0 THEN
		    v_RETURN := 100; -- This is extra hour
		 ELSIF v_MINUTE IN (15, 30, 45) THEN
		    v_RETURN := (24 * k_15_MIN_MULTIPLIER) + (v_MINUTE / 15); -- These are sub-hourlies of extra hour
		 END IF;
	  ELSIF b_IS_DST_FALL_BACK_HOUR AND p_LOCAL_DATE_INTERVAL = CONSTANTS.INTERVAL_30_MINUTE THEN
	     -- Do DST_FALL_BACK call
		 IF v_MINUTE = 0 THEN
		   v_RETURN := 50; -- This is extra hour
		 ELSIF v_MINUTE = 30 THEN
		   v_RETURN := 49;
		 END IF;
	  ELSIF b_IS_DST_SPRING_AHEAD_DAY AND v_HOUR = 2 AND v_MINUTE = 0 AND p_LOCAL_DATE_INTERVAL = CONSTANTS.INTERVAL_HOUR THEN
	     -- Do DST_SPRING_AHEAD call
	  	 v_RETURN := 1;
	  ELSIF b_IS_DST_SPRING_AHEAD_DAY AND v_HOUR BETWEEN 1 AND 2 AND p_LOCAL_DATE_INTERVAL = CONSTANTS.INTERVAL_15_MINUTE THEN
	  	 -- Do DST_SPRING_AHEAD call
		 IF v_HOUR BETWEEN 1 AND 2 AND v_MINUTE = 0 THEN
		    v_RETURN := 4; -- This is extra hour
		 ELSIF v_HOUR = 1 AND v_MINUTE IN (15, 30, 45) THEN
		    v_RETURN := 4;
		 ELSIF v_HOUR = 2 AND v_MINUTE IN (15, 30, 45) THEN
		 	v_RETURN := CEIL((p_LOCAL_DATE - TRUNC(p_LOCAL_DATE)) * g_HOURS_IN_INTERVAL(p_LOCAL_DATE_INTERVAL));
		 END IF;
	  ELSIF v_HOUR <> 24 THEN
	     v_RETURN := CEIL((p_LOCAL_DATE - TRUNC(p_LOCAL_DATE)) * g_HOURS_IN_INTERVAL(p_LOCAL_DATE_INTERVAL));
	  ELSE
	     v_RETURN := g_HOURS_IN_INTERVAL(p_LOCAL_DATE_INTERVAL);
	  END IF;
   END IF;

   RETURN v_RETURN;
END GET_ORDINAL_NUMBER_LOCAL_DATE;
---------------------------------------------------------------------------------------------------

BEGIN
	g_INTERVAL_ORD(c_ABBR_5MIN) := c_ORD_5MIN;
	g_INTERVAL_ORD(c_ABBR_10MIN) := c_ORD_10MIN;
	g_INTERVAL_ORD(c_ABBR_15MIN) := c_ORD_15MIN;
	g_INTERVAL_ORD(c_ABBR_20MIN) := c_ORD_20MIN;
	g_INTERVAL_ORD(c_ABBR_30MIN) := c_ORD_30MIN;
	g_INTERVAL_ORD(c_ABBR_HOUR) := c_ORD_HOUR;
	g_INTERVAL_ORD(c_ABBR_DAY) := c_ORD_DAY;
	g_INTERVAL_ORD(c_ABBR_WEEK) := c_ORD_WEEK;
	g_INTERVAL_ORD(c_ABBR_MONTH) := c_ORD_MONTH;
	g_INTERVAL_ORD(c_ABBR_QUARTER) := c_ORD_QUARTER;
	g_INTERVAL_ORD(c_ABBR_YEAR) := c_ORD_YEAR;

	g_INTERVAL_NAMES(c_ORD_5MIN) := c_NAME_5MIN;
	g_INTERVAL_NAMES(c_ORD_10MIN) := c_NAME_10MIN;
	g_INTERVAL_NAMES(c_ORD_15MIN) := c_NAME_15MIN;
	g_INTERVAL_NAMES(c_ORD_20MIN) := c_NAME_20MIN;
	g_INTERVAL_NAMES(c_ORD_30MIN) := c_NAME_30MIN;
	g_INTERVAL_NAMES(c_ORD_HOUR) := c_NAME_HOUR;
	g_INTERVAL_NAMES(c_ORD_DAY) := c_NAME_DAY;
	g_INTERVAL_NAMES(c_ORD_WEEK) := c_NAME_WEEK;
	g_INTERVAL_NAMES(c_ORD_MONTH) := c_NAME_MONTH;
	g_INTERVAL_NAMES(c_ORD_QUARTER) := c_NAME_QUARTER;
	g_INTERVAL_NAMES(c_ORD_YEAR) := c_NAME_YEAR;

	-- lengths are stored as minutes when positive, as days*-1 when negative but greater than -10,
	-- and as months*-10 when negative and less than or equal to -10
	g_INTERVAL_LENGTHS(c_ABBR_5MIN) := 5;
	g_INTERVAL_LENGTHS(c_ABBR_10MIN) := 10;
	g_INTERVAL_LENGTHS(c_ABBR_15MIN) := 15;
	g_INTERVAL_LENGTHS(c_ABBR_20MIN) := 20;
	g_INTERVAL_LENGTHS(c_ABBR_30MIN) := 30;
	g_INTERVAL_LENGTHS(c_ABBR_HOUR) := 60;
	g_INTERVAL_LENGTHS(c_ABBR_DAY) := -1;
	g_INTERVAL_LENGTHS(c_ABBR_WEEK) := -7;
	g_INTERVAL_LENGTHS(c_ABBR_MONTH) := -10;
	g_INTERVAL_LENGTHS(c_ABBR_QUARTER) := -30;
	g_INTERVAL_LENGTHS(c_ABBR_YEAR) := -120;
END DATE_UTIL;
/
