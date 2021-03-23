CREATE OR REPLACE PACKAGE BODY UT AS
----------------------------------------------------------------------------------------------------
TYPE OID_TBL IS TABLE OF NUMBER(1) INDEX BY BINARY_INTEGER;

g_TIMING_START PLS_INTEGER;
g_TIMING_NOW   PLS_INTEGER;

-- Cache of message definitions
TYPE MSG_DEF_CACHE IS TABLE OF MSG_DEF INDEX BY VARCHAR2(12);
g_MSG_DEF_CACHE MSG_DEF_CACHE;

----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.29 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
/*----------------------------------------------------------------------------*
 *   TIMER_START                                                              *
 *----------------------------------------------------------------------------*/
PROCEDURE TIMER_START IS
BEGIN
   g_TIMING_START := DBMS_UTILITY.GET_TIME;
END TIMER_START;

/*----------------------------------------------------------------------------*
 *   TIMER_GET_ELAPSED                                                        *
 *----------------------------------------------------------------------------*/
FUNCTION TIMER_GET_ELAPSED RETURN NUMBER IS
BEGIN
   g_TIMING_NOW := DBMS_UTILITY.GET_TIME;

   RETURN ABS(g_TIMING_NOW - g_TIMING_START)/100;
END TIMER_GET_ELAPSED;

---------------------------------------------------------------------------------------------------
FUNCTION GET_SCENARIO_RUN_MODE
	(
	p_SCENARIO_ID IN NUMBER
	)  RETURN NUMBER IS

v_RUN_MODE NUMBER(1);

BEGIN

	SELECT NVL(RUN_MODE, GA.HOUR_MODE)
	INTO v_RUN_MODE
	FROM LOAD_FORECAST_SCENARIO
	WHERE SCENARIO_ID = p_SCENARIO_ID;

	RETURN v_RUN_MODE;

EXCEPTION
	WHEN OTHERS THEN
		RETURN GA.HOUR_MODE;

END GET_SCENARIO_RUN_MODE;
---------------------------------------------------------------------------------------------------
FUNCTION CUSTOM_TO_NUMBER
	(
	p_VALUE IN VARCHAR2
	) RETURN NUMBER IS

v_NUMBER NUMBER;
BEGIN

	v_NUMBER := TO_NUMBER(p_VALUE);

	RETURN v_NUMBER;
EXCEPTION
	WHEN VALUE_ERROR THEN
		RETURN NULL;

END CUSTOM_TO_NUMBER;
---------------------------------------------------------------------------------------------------

PROCEDURE TOKENS_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT GA.STRING_TABLE
	) AS

v_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;
v_LENGTH NUMBER;
v_TOKEN VARCHAR(256);
v_LOOP_COUNTER NUMBER;

BEGIN

-- If the argument string is empty then exit the procedure

	IF LTRIM(RTRIM(p_STRING)) IS NULL THEN
		RETURN;
	END IF;

	v_LENGTH := LENGTH(p_STRING);
	v_LOOP_COUNTER := 0;

	LOOP
		v_END_POS := INSTR(p_STRING, p_DELIMITER, v_BEGIN_POS);
		IF v_END_POS = 0 THEN
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS)));
			v_END_POS := v_LENGTH;
		ELSE
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
		END IF;
		v_COUNT := v_COUNT + 1;
		p_STRING_TABLE(v_COUNT) := v_TOKEN;
		v_BEGIN_POS := v_END_POS + 1;
		v_LOOP_COUNTER := v_LOOP_COUNTER + 1;
		IF v_LOOP_COUNTER > 10000 THEN
			ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
		END IF;
		EXIT WHEN v_BEGIN_POS > v_LENGTH;
	END LOOP;

-- If the argument string is terminated with the delimiter then append a null string token to the table

	IF SUBSTR(p_STRING, v_LENGTH) = p_DELIMITER THEN
		v_COUNT := v_COUNT + 1;
		p_STRING_TABLE(v_COUNT) := NULL;
	END IF;

	EXCEPTION
	    WHEN VALUE_ERROR THEN
			ERRS.RAISE(MSGCODES.c_ERR_GENERAL,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
				|| ',TOKEN=' || v_TOKEN
				|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
				|| ',END_POS=' || TO_CHAR(v_END_POS)
				|| ',LENGTH=' || TO_CHAR(v_LENGTH));

END TOKENS_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE TOKENS_FROM_STRING_TO_NUMBERS
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_NUMBER_TABLE OUT GA.NUMBER_TABLE
	) AS

v_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;
v_LENGTH NUMBER;
v_TOKEN VARCHAR(256);
v_LOOP_COUNTER NUMBER;

BEGIN

-- If the argument string is empty then exit the procedure

	IF LTRIM(RTRIM(p_STRING)) IS NULL THEN
		RETURN;
	END IF;

	v_LENGTH := LENGTH(p_STRING);
	v_LOOP_COUNTER := 0;

	LOOP
		v_END_POS := INSTR(p_STRING, p_DELIMITER, v_BEGIN_POS);
		IF v_END_POS = 0 THEN
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS)));
			v_END_POS := v_LENGTH;
		ELSE
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
		END IF;
		v_COUNT := v_COUNT + 1;
		p_NUMBER_TABLE(v_COUNT) :=TO_NUMBER(v_TOKEN);
		v_BEGIN_POS := v_END_POS + 1;
		v_LOOP_COUNTER := v_LOOP_COUNTER + 1;
		IF v_LOOP_COUNTER > 10000 THEN
			ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
		END IF;
		EXIT WHEN v_BEGIN_POS > v_LENGTH;
	END LOOP;

-- If the argument string is terminated with the delimiter then append a null string token to the table

	IF SUBSTR(p_STRING, v_LENGTH) = p_DELIMITER THEN
		v_COUNT := v_COUNT + 1;
		p_NUMBER_TABLE(v_COUNT) := NULL;
	END IF;

	EXCEPTION
	    WHEN VALUE_ERROR THEN
			ERRS.RAISE(MSGCODES.c_ERR_GENERAL,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
				|| ',TOKEN=' || v_TOKEN
				|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
				|| ',END_POS=' || TO_CHAR(v_END_POS)
				|| ',LENGTH=' || TO_CHAR(v_LENGTH));

END TOKENS_FROM_STRING_TO_NUMBERS;
----------------------------------------------------------------------------------------------------
PROCEDURE TOKENS_FROM_BIG_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_BIG_STRING_TABLE OUT GA.BIG_STRING_TABLE
	) AS

v_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;
v_LENGTH NUMBER;
v_TOKEN VARCHAR(4000);
v_LOOP_COUNTER NUMBER;

BEGIN

-- If the argument string is empty then exit the procedure

	IF LTRIM(RTRIM(p_STRING)) IS NULL THEN
		RETURN;
	END IF;

	v_LENGTH := LENGTH(p_STRING);
	v_LOOP_COUNTER := 0;

	LOOP
		v_END_POS := INSTR(p_STRING, p_DELIMITER, v_BEGIN_POS);
		IF v_END_POS = 0 THEN
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS)));
			v_END_POS := v_LENGTH;
		ELSE
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
		END IF;
		v_COUNT := v_COUNT + 1;
		p_BIG_STRING_TABLE(v_COUNT) := v_TOKEN;
		v_BEGIN_POS := v_END_POS + 1;
		v_LOOP_COUNTER := v_LOOP_COUNTER + 1;
		IF v_LOOP_COUNTER > 10000 THEN
			ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
		END IF;
		EXIT WHEN v_BEGIN_POS > v_LENGTH;
	END LOOP;

-- If the argument string is terminated with the delimiter then append a null string token to the table

	IF SUBSTR(p_STRING, v_LENGTH) = p_DELIMITER THEN
		v_COUNT := v_COUNT + 1;
		p_BIG_STRING_TABLE(v_COUNT) := NULL;
	END IF;

	EXCEPTION
	    WHEN VALUE_ERROR THEN
			ERRS.RAISE(MSGCODES.c_ERR_GENERAL,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
				|| ',TOKEN=' || v_TOKEN
				|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
				|| ',END_POS=' || TO_CHAR(v_END_POS)
				|| ',LENGTH=' || TO_CHAR(v_LENGTH));

END TOKENS_FROM_BIG_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE IDS_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_ID_TABLE IN OUT GA.ID_TABLE
	) AS

v_STRING_TABLE GA.STRING_TABLE;
v_INDEX BINARY_INTEGER;

BEGIN

    TOKENS_FROM_STRING(p_STRING, p_DELIMITER, v_STRING_TABLE);
	v_INDEX := v_STRING_TABLE.FIRST;
	WHILE v_STRING_TABLE.EXISTS(v_INDEX) LOOP
		p_ID_TABLE(v_INDEX) := TO_NUMBER(v_STRING_TABLE(v_INDEX));
		v_INDEX := v_STRING_TABLE.NEXT(v_INDEX);
	END LOOP;

END IDS_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCAL_DATE_AND_TIME_TO_CUT
	(
	p_DATE IN VARCHAR,
	p_TIME IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_DATE OUT DATE
	) AS

--c	Answer the CUT date derived from date and time stings for the specified local time zone.
--c	The time string can consist of a 'd' or 's' suffix indicating a DST transition day and the
--c	associated time period: 'd' - Daylight Savings Time, 's' - Standard Time

v_TIME_ZONE VARCHAR(3);
v_SUFFIX CHAR(1);
v_TIME VARCHAR(10);
v_DST_TRANSITION_DAY BOOLEAN;
v_LOCAL_DATE DATE;

BEGIN
	v_TIME := LTRIM(RTRIM(p_TIME));
	v_TIME_ZONE := LTRIM(RTRIM(p_TIME_ZONE));
	v_SUFFIX := SUBSTR(v_TIME,LENGTH(v_TIME));
	IF v_SUFFIX IN ('d','s') THEN
		v_TIME := SUBSTR(v_TIME, 1, LENGTH(v_TIME) - 1);
		IF v_SUFFIX = 'd' THEN
			v_TIME_ZONE := DST_TIME_ZONE(v_TIME_ZONE);
		ELSE
			v_TIME_ZONE := STD_TIME_ZONE(v_TIME_ZONE);
		END IF;
		v_DST_TRANSITION_DAY := TRUE;
	ELSE
		v_DST_TRANSITION_DAY := FALSE;
	END IF;

	v_LOCAL_DATE := FROM_HED(LTRIM(RTRIM(p_DATE)), v_TIME);

	IF NOT v_DST_TRANSITION_DAY AND NOT IS_IN_DST_TIME_PERIOD(v_LOCAL_DATE) THEN
		v_TIME_ZONE := STD_TIME_ZONE(v_TIME_ZONE);
	END IF;

	p_CUT_DATE := TO_CUT(v_LOCAL_DATE, v_TIME_ZONE);

END LOCAL_DATE_AND_TIME_TO_CUT;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCAL_DATE_AND_TIME_TO_GMT
	(
	p_DATE IN VARCHAR,
	p_TIME IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_GMT_DATE OUT DATE
	) AS

--c Deprecated function.
--c	Answer the GMT date derived from date and time stings for the specified local time zone.
--c	The time string can consist of a 'd' or 's' suffix indicating a DST transition day and the
--c	associated time period: 'd' - Daylight Savings Time, 's' - Standard Time

BEGIN

	LOCAL_DATE_AND_TIME_TO_CUT(p_DATE, p_TIME, p_TIME_ZONE, p_GMT_DATE);

END LOCAL_DATE_AND_TIME_TO_GMT;
---------------------------------------------------------------------------------------------------
PROCEDURE LOCAL_DAY_TO_CUT
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_DATE OUT DATE
	) AS

--c	Answer a CUT day date derived from the specified date and local time zone accounting for DST.

v_LOCAL_DAY DATE;
v_TIME_ZONE VARCHAR(3);

BEGIN

	v_LOCAL_DAY := TRUNC(p_DATE);
	IF p_TIME_ZONE = DST_TIME_ZONE(p_TIME_ZONE) THEN
		IF IS_IN_DST_TIME_PERIOD(v_LOCAL_DAY) THEN
			v_TIME_ZONE := DST_TIME_ZONE(p_TIME_ZONE);
		ELSE
			v_TIME_ZONE := STD_TIME_ZONE(p_TIME_ZONE);
		END IF;
	END IF;

	p_CUT_DATE := TO_CUT(v_LOCAL_DAY, v_TIME_ZONE);

END LOCAL_DAY_TO_CUT;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCAL_DAY_TO_GMT
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_GMT_DATE OUT DATE
	) AS

--c Deprecated function.
--c	Answer a GMT day date derived from the specified date and local time zone accounting for DST.

BEGIN

    LOCAL_DAY_TO_GMT(p_DATE, p_TIME_ZONE, p_GMT_DATE);

END LOCAL_DAY_TO_GMT;
---------------------------------------------------------------------------------------------------
FUNCTION GET_INCUMBENT_ENTITY_TYPE  RETURN INCUMBENT_ENTITY.INCUMBENT_TYPE%TYPE IS

v_INCUMBENT_TYPE INCUMBENT_ENTITY.INCUMBENT_TYPE%TYPE;

BEGIN

	SELECT UPPER(INCUMBENT_TYPE)
	INTO v_INCUMBENT_TYPE
	FROM INCUMBENT_ENTITY;

	RETURN v_INCUMBENT_TYPE;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'EDC';

END GET_INCUMBENT_ENTITY_TYPE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_INCUMBENT_ENTITY
	(
	p_INCUMBENT_TYPE OUT VARCHAR,
	p_INCUMBENT_NAME OUT VARCHAR,
	p_INCUMBENT_ALIAS OUT VARCHAR,
	p_INCUMBENT_ID OUT NUMBER
	) AS

BEGIN

	SELECT UPPER(INCUMBENT_TYPE), INCUMBENT_ID
	INTO p_INCUMBENT_TYPE, p_INCUMBENT_ID
	FROM INCUMBENT_ENTITY;

	IF p_INCUMBENT_TYPE = 'ESP' THEN
		SELECT ENTITY_NAME,ENTITY_ALIAS
		INTO p_INCUMBENT_NAME, p_INCUMBENT_ALIAS
		FROM ESP_ENTITY
		WHERE ENTITY_ID = p_INCUMBENT_ID;
	END IF;

	IF p_INCUMBENT_TYPE = 'EDC' THEN
		SELECT ENTITY_NAME, ENTITY_ALIAS
		INTO p_INCUMBENT_NAME, p_INCUMBENT_ALIAS
		FROM EDC_ENTITY
		WHERE ENTITY_ID = p_INCUMBENT_ID;
	END IF;

	EXCEPTION
	    WHEN NO_DATA_FOUND THEN
			p_INCUMBENT_TYPE := 'Unk';
			p_INCUMBENT_NAME := 'Unknown';
			p_INCUMBENT_ALIAS := 'Unknown';
			p_INCUMBENT_ID := 0;
		WHEN OTHERS THEN
			RAISE;

END GET_INCUMBENT_ENTITY;
----------------------------------------------------------------------------------------------------
PROCEDURE SET_INCUMBENT_ENTITY
	(
	p_INCUMBENT_TYPE IN VARCHAR,
	p_INCUMBENT_ID IN NUMBER
	) AS

BEGIN

	SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_UPDATE_INCUMBENT_ENT);

	DELETE INCUMBENT_ENTITY;

	INSERT INTO INCUMBENT_ENTITY(INCUMBENT_TYPE, INCUMBENT_ID)
		VALUES(UPPER(LTRIM(RTRIM(p_INCUMBENT_TYPE))), p_INCUMBENT_ID);

END SET_INCUMBENT_ENTITY;
----------------------------------------------------------------------------------------------------
FUNCTION TRACE_DATE
	(
	p_DATE IN DATE
	) RETURN VARCHAR IS
BEGIN
	RETURN TO_CHAR(p_DATE, 'DD-MON-YYYY HH24:MI:SS');
END TRACE_DATE;
----------------------------------------------------------------------------------------------------
FUNCTION TRACE_BOOLEAN
	(
	p_BOOLEAN IN BOOLEAN
	) RETURN CHAR IS
BEGIN
	IF p_BOOLEAN THEN
		RETURN 'Y';
	ELSE
		RETURN 'N';
	END IF;
END TRACE_BOOLEAN;
----------------------------------------------------------------------------------------------------
-- DEPRECATED!!! Do not call this method. Use the LOGS Package.
-- Method changed 2/20/2008 due to the new Processes/Logging API.
-- Remains for backward compatibility only.
PROCEDURE DEBUG_TRACE
	(
	p_STATEMENT IN VARCHAR
	) AS
BEGIN
	LOGS.LOG_DEBUG(p_STATEMENT);
END DEBUG_TRACE;
----------------------------------------------------------------------------------------------------
PROCEDURE TRUNCATE_TABLE
	(
	p_TABLE_NAME IN VARCHAR
	) AS

v_CURSOR NUMBER;
DUMMY INTEGER;

BEGIN

	v_CURSOR := DBMS_SQL.OPEN_CURSOR;
	DBMS_SQL.PARSE(v_CURSOR, 'TRUNCATE TABLE ' || p_TABLE_NAME, DBMS_SQL.NATIVE);
	DUMMY := DBMS_SQL.EXECUTE(v_CURSOR);
	DBMS_SQL.CLOSE_CURSOR(v_CURSOR);

	EXCEPTION
		WHEN OTHERS THEN
		DBMS_SQL.CLOSE_CURSOR(v_CURSOR);
		RAISE;

END TRUNCATE_TABLE;
----------------------------------------------------------------------------------------------------
-- DEPRECATED!!! Do not call this method. Use the LOGS Package.
-- Method changed 2/20/2008 due to the new Processes/Logging API.
-- Remains for backward compatibility only.
PROCEDURE TRUNCATE_TRACE AS
BEGIN
	-- Do Nothing. No longer necessary to truncate the log tables since they are segmented by process.
	NULL;
END TRUNCATE_TRACE;
----------------------------------------------------------------------------------------------------
-- DEPRECATED!!! Do not call this method. Use the LOGS Package.
-- Method changed 2/20/2008 due to the new Processes/Logging API.
-- Remains for backward compatibility only.
PROCEDURE GET_TRACE
	(
	p_CURSOR IN OUT GA.REFCURSOR
	) AS
v_PROCESS_ID PROCESS_LOG.PROCESS_ID%TYPE;
BEGIN
	-- Get the most recent child process id
	SELECT MAX(PROCESS_ID)
	INTO v_PROCESS_ID
	FROM (SELECT PROCESS_ID
		  FROM PROCESS_LOG
		  WHERE PARENT_PROCESS_ID = LOGS.CURRENT_PROCESS_ID
	      -- order to get most recent process first
		  ORDER BY PROCESS_START_TIME DESC, PROCESS_ID DESC)
	WHERE ROWNUM=1;

	OPEN p_CURSOR FOR
		  SELECT A.EVENT_TEXT
		  FROM (SELECT T.PROCESS_ID, T.EVENT_ID, T.EVENT_TIMESTAMP, T.EVENT_TEXT
			    FROM PROCESS_LOG_TRACE T
			    WHERE T.PROCESS_ID = v_PROCESS_ID
			    UNION ALL
			    SELECT T.PROCESS_ID, T.EVENT_ID, T.EVENT_TIMESTAMP, T.EVENT_TEXT
			    FROM PROCESS_LOG_TEMP_TRACE T
			    WHERE T.PROCESS_ID = v_PROCESS_ID) A
		  ORDER BY A.EVENT_TIMESTAMP, A.EVENT_ID;
END GET_TRACE;
----------------------------------------------------------------------------------------------------
PROCEDURE TRACE_TABLE
	(
	p_NAME IN VARCHAR,
	p_TABLE IN GA.NUMBER_TABLE
	) AS

v_INDEX BINARY_INTEGER;

BEGIN

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		FOR v_INDEX IN p_TABLE.FIRST..p_TABLE.LAST LOOP
			IF v_INDEX =  p_TABLE.FIRST THEN
				LOGS.LOG_DEBUG_DETAIL('TRACE: ' || p_NAME);
				LOGS.LOG_DEBUG_DETAIL('COUNT=' || TO_CHAR(p_TABLE.COUNT));
				LOGS.LOG_DEBUG_DETAIL('<value>@<index>');
			END IF;
			IF p_TABLE.EXISTS(v_INDEX) THEN
				LOGS.LOG_DEBUG_DETAIL(TO_CHAR(p_TABLE(v_INDEX)) || '@' || TO_CHAR(v_INDEX));
			END IF;
		END LOOP;
	END IF;

END TRACE_TABLE;
---------------------------------------------------------------------------------------------------
 PROCEDURE CUT_DAY_INTERVAL_RANGE_GAS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Answer a begin and end cut day interval range that inclusively covers the specified begin and end dates

BEGIN

	p_CUT_BEGIN_DATE := TRUNC(p_BEGIN_DATE);
	p_CUT_END_DATE := ADD_SECONDS_TO_DATE(TRUNC(p_END_DATE) + 1, -1);

END CUT_DAY_INTERVAL_RANGE_GAS;
----------------------------------------------------------------------------------------------------
 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_MINUTES IN NUMBER,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Use this function only when looping over a range of dates.  See also CUT_DATE_RANGE.
-- Answer a begin and end cut day interval range that inclusively covers the specified begin and end dates
BEGIN

	IF p_MODEL_ID = GA.ELECTRIC_MODEL THEN
		p_CUT_BEGIN_DATE := TO_CUT(ADD_MINUTES_TO_DATE(TRUNC(p_BEGIN_DATE), p_MINUTES), p_TIME_ZONE);
		p_CUT_END_DATE := TO_CUT(TRUNC(p_END_DATE) + 1, p_TIME_ZONE);
	ELSE
		CUT_DAY_INTERVAL_RANGE_GAS(p_BEGIN_DATE, p_END_DATE, p_CUT_BEGIN_DATE, p_CUT_END_DATE);
	END IF;

END CUT_DAY_INTERVAL_RANGE;
----------------------------------------------------------------------------------------------------
 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Use this function only when looping over a range of dates.  See also CUT_DATE_RANGE.
-- Answer a begin and end cut day interval range that inclusively covers the specified begin and end dates
BEGIN

	IF p_MODEL_ID = GA.ELECTRIC_MODEL THEN
	   IF INTERVAL_IS_ATLEAST_DAILY(p_INTERVAL) THEN
	   	  p_CUT_BEGIN_DATE := TRUNC(p_BEGIN_DATE, p_INTERVAL);
		  p_CUT_END_DATE := ADVANCE_DATE(TRUNC(p_END_DATE, p_INTERVAL), p_INTERVAL) - 1;
	   ELSE
		  p_CUT_BEGIN_DATE := TO_CUT(ADVANCE_DATE(TRUNC(p_BEGIN_DATE), p_INTERVAL), p_TIME_ZONE);
		  p_CUT_END_DATE := TO_CUT(TRUNC(p_END_DATE) + 1, p_TIME_ZONE);
	   END IF;
	ELSE
		CUT_DAY_INTERVAL_RANGE_GAS(p_BEGIN_DATE, p_END_DATE, p_CUT_BEGIN_DATE, p_CUT_END_DATE);
	END IF;

END CUT_DAY_INTERVAL_RANGE;
----------------------------------------------------------------------------------------------------
 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Use this function only when looping over a range of dates.  See also CUT_DATE_RANGE.
-- Answer a begin and end cut day interval range that inclusively covers the specified begin and end dates

BEGIN

	CUT_DAY_INTERVAL_RANGE(p_MODEL_ID, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, 60, p_CUT_BEGIN_DATE, p_CUT_END_DATE);

END CUT_DAY_INTERVAL_RANGE;
----------------------------------------------------------------------------------------------------
 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- **Deprecated** Use a function where you pass in the model id.
-- Use this function only when looping over a range of dates.  See also CUT_DATE_RANGE.
-- Answer a begin and end cut day interval range that inclusively covers the specified begin and end dates

BEGIN

	CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, 60, p_CUT_BEGIN_DATE, p_CUT_END_DATE);

END CUT_DAY_INTERVAL_RANGE;
----------------------------------------------------------------------------------------------------
 PROCEDURE CUT_DAY_INTERVAL_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_SERVICE_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Use this function only when looping over a range of dates.  See also CUT_DATE_RANGE.
-- Answer a begin and end cut day interval range that inclusively covers the specified begin and end dates

BEGIN

	CUT_DAY_INTERVAL_RANGE(p_MODEL_ID, p_SERVICE_DATE, p_SERVICE_DATE, p_TIME_ZONE, 60, p_CUT_BEGIN_DATE, p_CUT_END_DATE);

END CUT_DAY_INTERVAL_RANGE;
----------------------------------------------------------------------------------------------------
 PROCEDURE CUT_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Use this function only when doing a SELECT between two dates.  See also CUT_DAY_INTERVAL_RANGE.

-- Answer a begin and end cut date range that inclusively covers the specified begin and end dates.
-- The cut begin date is hour ending 1 am (local time zone) cast to the system cut time zone.
-- The cut end date is 1 second shy of the hour ending 1 am (local time zone) cast to the system cut time zone.
-- If not the electric model then treat the interval in terms of days.
BEGIN

	IF p_MODEL_ID = GA.ELECTRIC_MODEL THEN
		p_CUT_BEGIN_DATE := ADD_SECONDS_TO_DATE(TO_CUT(TRUNC(p_BEGIN_DATE), p_TIME_ZONE), 1);
		p_CUT_END_DATE := TO_CUT(TRUNC(p_END_DATE) + 1, p_TIME_ZONE);
	ELSE
		p_CUT_BEGIN_DATE := TRUNC(p_BEGIN_DATE);
		p_CUT_END_DATE := TRUNC(p_END_DATE);
	END IF;

END CUT_DATE_RANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CUT_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_SERVICE_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Use this function only when doing a SELECT between two dates.  See also CUT_DAY_INTERVAL_RANGE.

BEGIN

	CUT_DATE_RANGE(p_MODEL_ID, p_SERVICE_DATE, p_SERVICE_DATE, p_TIME_ZONE, p_CUT_BEGIN_DATE, p_CUT_END_DATE);

END CUT_DATE_RANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CUT_DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- **Deprecated** Use one where you pass in the model id.
-- Use this function only when doing a SELECT between two dates.  See also CUT_DAY_INTERVAL_RANGE.

BEGIN

	CUT_DATE_RANGE(GA.DEFAULT_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, p_CUT_BEGIN_DATE, p_CUT_END_DATE);

END CUT_DATE_RANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CUT_DATE_RANGE
	(
	p_SERVICE_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- **Deprecated** Use one where you pass in the model id.
-- Use this function only when doing a SELECT between two dates.  See also CUT_DAY_INTERVAL_RANGE.

BEGIN

	CUT_DATE_RANGE(GA.DEFAULT_MODEL, p_SERVICE_DATE, p_SERVICE_DATE, p_TIME_ZONE, p_CUT_BEGIN_DATE, p_CUT_END_DATE);

END CUT_DATE_RANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CUT_DATE_RANGE
	(
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR,
	p_CUT_BEGIN_DATE IN OUT DATE,
	p_CUT_END_DATE IN OUT DATE
	) AS

-- Use this function only when doing a SELECT between two dates.  See also CUT_DAY_INTERVAL_RANGE.

-- Answer a begin and end cut date range that inclusively covers the specified begin and end dates.
-- The cut begin date is hour ending 1 am (local time zone) cast to the system cut time zone.
-- The cut end date is 1 second shy of the hour ending 1 am (local time zone) cast to the system cut time zone.
-- Electric Interval specification is hour or sub-hour, Gas is day.
BEGIN
	 CUT_DATE_RANGE(p_MODEL_ID, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, p_INTERVAL, NULL, p_CUT_BEGIN_DATE, p_CUT_END_DATE);

END CUT_DATE_RANGE;
----------------------------------------------------------------------------------------------------
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
	) AS


-- Use this function only when doing a SELECT between two dates.  See also CUT_DAY_INTERVAL_RANGE.

-- p_DATA_INTERVAL is the expected interval of the data.  If it is daily or higher, then we won't shift to time zone.

-- Answer a begin and end cut date range that inclusively covers the specified begin and end dates.
-- The cut begin date is hour ending 1 am (local time zone) cast to the system cut time zone.
-- The cut end date is 1 second shy of the hour ending 1 am (local time zone) cast to the system cut time zone.
-- Electric Interval specification is hour or sub-hour, Gas is day.
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_INTERVAL VARCHAR(16);
BEGIN


	--MI INTERVALS AREN'T RECOGNIZED BY ORACLE.
	IF SUBSTR(p_INTERVAL,1,2) = 'MI' OR p_INTERVAL IS NULL THEN
		v_INTERVAL := 'DD';
	ELSE
		v_INTERVAL := p_INTERVAL;
	END IF;

	--APPLY TIME ZONE CHANGES FOR ELECTRIC.
	IF p_MODEL_ID = GA.ELECTRIC_MODEL THEN
		v_BEGIN_DATE := TRUNC(p_BEGIN_DATE, v_INTERVAL);
		v_END_DATE := ADVANCE_DATE(TRUNC(p_END_DATE, v_INTERVAL), v_INTERVAL) - 1;
		IF NOT INTERVAL_IS_ATLEAST_DAILY(p_DATA_INTERVAL) THEN
		   CUT_DATE_RANGE(v_BEGIN_DATE, v_END_DATE, p_TIME_ZONE, p_CUT_BEGIN_DATE, p_CUT_END_DATE);
		ELSE
		   p_CUT_BEGIN_DATE := v_BEGIN_DATE;
		   p_CUT_END_DATE := v_END_DATE;
		END IF;
	ELSE
		p_CUT_BEGIN_DATE := TRUNC(p_BEGIN_DATE, v_INTERVAL);
		p_CUT_END_DATE := ADVANCE_DATE(TRUNC(p_END_DATE, v_INTERVAL), v_INTERVAL) - 1/86400;
	END IF;

END CUT_DATE_RANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN VARCHAR := '',
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer a date range of local date and times.

v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_DATE_WORK_ID NUMBER;

BEGIN

	p_STATUS := GA.SUCCESS;
	UT.GET_RTO_WORK_ID(v_DATE_WORK_ID);

	IF p_INTERVAL IS NULL OR SUBSTR(p_INTERVAL,1,2) = 'MI' THEN
		UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
	ELSE
		v_BEGIN_DATE := TRUNC(p_BEGIN_DATE);
		v_END_DATE := TRUNC(p_END_DATE);
	END IF;

	UT.POST_RTO_WORK_DATE_RANGE(v_DATE_WORK_ID, v_BEGIN_DATE, v_END_DATE, p_INTERVAL);

	IF p_INTERVAL IS NULL OR SUBSTR(p_INTERVAL,1,2) = 'MI' THEN
		OPEN p_CURSOR FOR
			SELECT FROM_CUT_AS_HED(WORK_DATE, p_TIME_ZONE, p_INTERVAL) FROM RTO_WORK WHERE WORK_ID = v_DATE_WORK_ID ORDER BY 1;
	ELSE
		OPEN p_CURSOR FOR
			SELECT TO_CHAR(WORK_DATE,'YYYY-MM-DD ') FROM RTO_WORK WHERE WORK_ID = v_DATE_WORK_ID ORDER BY 1;
	END IF;

	UT.PURGE_RTO_WORK(v_DATE_WORK_ID);

	EXCEPTION
	    WHEN OTHERS THEN
			UT.PURGE_RTO_WORK(v_DATE_WORK_ID);
		    p_STATUS := SQLCODE;

END DATE_RANGE;
---------------------------------------------------------------------------------------------------
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
	) AS

-- Answer a date range of local date and times.

v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_CUT_BEGIN_DATE DATE;
v_CUT_END_DATE DATE;
v_STRINGS STRING_TABLE := STRING_TABLE();
v_RUN_MODE NUMBER(1) := GET_SCENARIO_RUN_MODE(p_SCENARIO_ID);
v_MINUTES NUMBER(2);
v_COUNT PLS_INTEGER := 0;
v_TIME_ZONE CHAR(3) := STD_TIME_ZONE(p_TIME_ZONE);

BEGIN

	IF v_RUN_MODE IN (GA.HOUR_MODE, GA.DAY_MODE) THEN
		DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, p_INTERVAL, p_STATUS, p_CURSOR);
		RETURN;
	END IF;

	p_STATUS := GA.SUCCESS;

	IF v_RUN_MODE = GA.WEEK_MODE THEN
		v_BEGIN_DATE := TRUNC(p_BEGIN_DATE, 'DAY');
		v_END_DATE := TRUNC(p_END_DATE, 'DAY') + 6;
	ELSE
		v_BEGIN_DATE := TRUNC(p_BEGIN_DATE, 'MONTH');
		v_END_DATE := LAST_DAY(p_END_DATE);
	END IF;

	WHILE v_BEGIN_DATE <= v_END_DATE LOOP

		IF p_INTERVAL IS NULL OR SUBSTR(p_INTERVAL,1,2) = 'MI' THEN
			SELECT DECODE(p_INTERVAL, 'MI15', 15, 'MI30', 30, 60) INTO v_MINUTES FROM DUAL;
			UT.CUT_DAY_INTERVAL_RANGE(p_MODEL_ID, v_BEGIN_DATE, v_BEGIN_DATE, v_TIME_ZONE, v_MINUTES, v_CUT_BEGIN_DATE, v_CUT_END_DATE);
			WHILE v_CUT_BEGIN_DATE <= v_CUT_END_DATE LOOP
				v_STRINGS.EXTEND;
				v_STRINGS(v_STRINGS.LAST) := STRING_TYPE(FROM_CUT_AS_HED(v_CUT_BEGIN_DATE, v_TIME_ZONE, p_INTERVAL, p_MODEL_ID, GA.WEEK_DAY));
				v_STRINGS.EXTEND;
				v_STRINGS(v_STRINGS.LAST) := STRING_TYPE(FROM_CUT_AS_HED(v_CUT_BEGIN_DATE, v_TIME_ZONE, p_INTERVAL, p_MODEL_ID, GA.WEEK_END));
				v_COUNT := v_COUNT + 1;
				IF v_COUNT > 10000 THEN
					ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
				END IF;
				v_CUT_BEGIN_DATE := ADD_MINUTES_TO_DATE(v_CUT_BEGIN_DATE, v_MINUTES);
			END LOOP;
		ELSE
			v_STRINGS.EXTEND;
			v_STRINGS(v_STRINGS.LAST) := STRING_TYPE(FROM_CUT_AS_HED(v_BEGIN_DATE, v_TIME_ZONE, p_INTERVAL, p_MODEL_ID, GA.WEEK_DAY, p_INTERVAL));
			v_STRINGS.EXTEND;
			v_STRINGS(v_STRINGS.LAST) := STRING_TYPE(FROM_CUT_AS_HED(v_BEGIN_DATE, v_TIME_ZONE, p_INTERVAL, p_MODEL_ID, GA.WEEK_END, p_INTERVAL));
		END IF;

		IF v_RUN_MODE = GA.WEEK_MODE THEN
			v_BEGIN_DATE := v_BEGIN_DATE + 7;
		ELSE
			v_BEGIN_DATE := LAST_DAY(v_BEGIN_DATE) + 1;
		END IF;
	END LOOP;

	OPEN p_CURSOR FOR
		SELECT A.STRING_VAL FROM TABLE(CAST(v_STRINGS AS STRING_TABLE)) A ORDER BY 1;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;

END SCENARIO_DATE_RANGE;
---------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATA IN VARCHAR
	) AS

BEGIN

    INSERT INTO RTO_WORK (
	    WORK_ID,
		WORK_SEQ,
		WORK_XID,
		WORK_DATE,
		WORK_DATA)
	VALUES (
	    p_WORK_ID,
		p_WORK_SEQ,
		NULL,
		NULL,
		p_WORK_DATA);

	EXCEPTION
	    WHEN OTHERS THEN
		    RAISE;

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER
	) AS

BEGIN

    INSERT INTO RTO_WORK (
	    WORK_ID,
		WORK_SEQ,
		WORK_XID,
		WORK_DATE,
		WORK_DATA)
	VALUES (
	    p_WORK_ID,
		p_WORK_SEQ,
		p_WORK_XID,
		NULL,
		NULL);

	EXCEPTION
	    WHEN OTHERS THEN
		    RAISE;

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATE IN DATE
	) AS

BEGIN

    INSERT INTO RTO_WORK (
	    WORK_ID,
		WORK_SEQ,
		WORK_XID,
		WORK_DATE,
		WORK_DATA)
	VALUES (
	    p_WORK_ID,
		p_WORK_SEQ,
		NULL,
		p_WORK_DATE,
		NULL);

	EXCEPTION
	    WHEN OTHERS THEN
		    RAISE;

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER,
	p_WORK_DATE IN DATE,
	p_WORK_DATA IN VARCHAR
	) AS

BEGIN

    INSERT INTO RTO_WORK (
	    WORK_ID,
		WORK_SEQ,
		WORK_XID,
		WORK_DATE,
		WORK_DATA)
	VALUES (
	    p_WORK_ID,
		p_WORK_SEQ,
		p_WORK_XID,
		p_WORK_DATE,
		p_WORK_DATA);

	EXCEPTION
	    WHEN OTHERS THEN
		    RAISE;

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK_DATE_RANGE
	(
	p_WORK_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_MINUTE_INTERVAL IN NUMBER
	) AS

v_DATE DATE;
v_INDEX NUMBER := 1;

BEGIN

	v_DATE := p_BEGIN_DATE;
	WHILE v_DATE <= p_END_DATE LOOP
		POST_RTO_WORK(p_WORK_ID, v_INDEX, v_DATE);
		v_DATE := ADD_MINUTES_TO_DATE(v_DATE, p_MINUTE_INTERVAL);
		v_INDEX := v_INDEX + 1;
	END LOOP;

END POST_RTO_WORK_DATE_RANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK_DATE_RANGE
	(
	p_WORK_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR
	) AS

v_DATE DATE;
v_INDEX NUMBER := 1;
v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

--HANDLE HOURLY AND SUBHOURLY INTERVALS
	IF p_INTERVAL IS NULL THEN --HOURLY INTERVAL
		v_BEGIN_DATE := ADD_MINUTES_TO_DATE(TRUNC(p_BEGIN_DATE,'HH'), 60);
		POST_RTO_WORK_DATE_RANGE(p_WORK_ID, v_BEGIN_DATE, p_END_DATE, 60);
		RETURN;
	ELSIF p_INTERVAL = 'MI30' THEN
		v_BEGIN_DATE := ADD_MINUTES_TO_DATE(TRUNC(p_BEGIN_DATE,'HH'), 30);
		POST_RTO_WORK_DATE_RANGE(p_WORK_ID, v_BEGIN_DATE, p_END_DATE, 30);
		RETURN;
	ELSIF p_INTERVAL = 'MI15' THEN
		v_BEGIN_DATE := ADD_MINUTES_TO_DATE(TRUNC(p_BEGIN_DATE,'HH'), 15);
		POST_RTO_WORK_DATE_RANGE(p_WORK_ID, v_BEGIN_DATE, p_END_DATE, 15);
		RETURN;
	ELSIF p_INTERVAL = 'MI10' THEN
		v_BEGIN_DATE := ADD_MINUTES_TO_DATE(TRUNC(p_BEGIN_DATE,'HH'), 10);
		POST_RTO_WORK_DATE_RANGE(p_WORK_ID, v_BEGIN_DATE, p_END_DATE, 10);
		RETURN;
	ELSIF p_INTERVAL = 'MI5' THEN
		v_BEGIN_DATE := ADD_MINUTES_TO_DATE(TRUNC(p_BEGIN_DATE,'HH'), 5);
		POST_RTO_WORK_DATE_RANGE(p_WORK_ID, v_BEGIN_DATE, p_END_DATE, 5);
		RETURN;
	END IF;

--HANDLE INTERVALS DAILY AND ABOVE.
	v_BEGIN_DATE := TRUNC(p_BEGIN_DATE,p_INTERVAL);
	v_END_DATE := TRUNC(p_END_DATE,p_INTERVAL);

	v_DATE := v_BEGIN_DATE;
	WHILE v_DATE <= v_END_DATE LOOP
		POST_RTO_WORK(p_WORK_ID, v_INDEX, v_DATE);
		v_DATE := ADVANCE_DATE(v_DATE, p_INTERVAL);
		v_INDEX := v_INDEX + 1;
	END LOOP;

END POST_RTO_WORK_DATE_RANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PURGE_RTO_WORK
	(
	p_WORK_ID IN NUMBER
	) AS

BEGIN

	IF NVL(p_WORK_ID,-1) >= 0 THEN
		DELETE RTO_WORK WHERE WORK_ID = p_WORK_ID;
	END IF;

END PURGE_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATA IN VARCHAR,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	) AS

BEGIN

	p_RTO_WORK.EXTEND;
	p_RTO_WORK(p_RTO_WORK.LAST) := RTO_WORK_TYPE(p_WORK_ID, p_WORK_SEQ, NULL, NULL, p_WORK_DATA);

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	) AS

BEGIN

	p_RTO_WORK.EXTEND;
	p_RTO_WORK(p_RTO_WORK.LAST) := RTO_WORK_TYPE(p_WORK_ID, p_WORK_SEQ, p_WORK_XID, NULL, NULL);

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_DATE IN DATE,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	) AS

BEGIN

	p_RTO_WORK.EXTEND;
	p_RTO_WORK(p_RTO_WORK.LAST) := RTO_WORK_TYPE(p_WORK_ID, p_WORK_SEQ, NULL, p_WORK_DATE, NULL);

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_WORK_SEQ IN NUMBER,
	p_WORK_XID IN NUMBER,
	p_WORK_DATE IN DATE,
	p_WORK_DATA IN VARCHAR,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	) AS

BEGIN

	p_RTO_WORK.EXTEND;
	p_RTO_WORK(p_RTO_WORK.LAST) := RTO_WORK_TYPE(p_WORK_ID, p_WORK_SEQ, p_WORK_XID, p_WORK_DATE, p_WORK_DATA);

END POST_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE PURGE_RTO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_RTO_WORK IN OUT NOCOPY RTO_WORK_TABLE
	) AS

BEGIN

	p_RTO_WORK.DELETE;

END PURGE_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_RTO_WORK_ID
	(
	p_WORK_ID OUT NUMBER
	) AS

BEGIN

    SELECT WID.NEXTVAL INTO p_WORK_ID FROM DUAL;

	EXCEPTION
	    WHEN OTHERS THEN
		    RAISE;

END GET_RTO_WORK_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_DROP_CLOB RETURN CLOB IS PRAGMA AUTONOMOUS_TRANSACTION;

	v_DROP_ORDER PLS_INTEGER := 1;

	v_TEMP_DROP_ORDER RTO_WORK.WORK_SEQ%TYPE;
	v_TEMP_TYPE_NAME RTO_WORK.WORK_DATA%TYPE;

	v_WORK_ID NUMBER(9);

	v_RET CLOB := EMPTY_CLOB;
-------------------
	PROCEDURE APPEND(p_STR IN VARCHAR2) IS
	BEGIN
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(p_STR || UTL_TCP.CRLF), p_STR || UTL_TCP.CRLF);
	END APPEND;
-------------------
	PROCEDURE APPEND_EMPTY_LINE IS
	BEGIN
		APPEND('');
	END APPEND_EMPTY_LINE;
-------------------
BEGIN
	UT.GET_RTO_WORK_ID(v_WORK_ID);

	INSERT INTO RTO_WORK(WORK_ID,WORK_DATA,WORK_SEQ)
	SELECT v_WORK_ID, TYPE_NAME, null
	FROM USER_TYPES;

	--Update the table based on dependency
	LOOP
		UPDATE (SELECT v_WORK_ID,A.WORK_DATA, A.WORK_SEQ
				FROM RTO_WORK A
				WHERE A.WORK_ID = v_WORK_ID
					AND	WORK_SEQ IS NULL
					AND NOT EXISTS (SELECT 1
								  FROM USER_DEPENDENCIES B, RTO_WORK C
								  WHERE B.TYPE IN ('TYPE','TYPE BODY')
								  	AND B.NAME = A.WORK_DATA
									AND B.REFERENCED_OWNER = USER
									AND B.REFERENCED_TYPE = 'TYPE'
									AND B.REFERENCED_NAME = C.WORK_DATA
									AND B.REFERENCED_NAME != A.WORK_DATA
									AND C.WORK_SEQ IS NULL
									AND C.WORK_ID = v_WORK_ID)
				)
		SET WORK_SEQ = v_DROP_ORDER;

		-- DONE WHEN NO MORE ROWS CAN BE UPDATED
		EXIT WHEN SQL%NOTFOUND;

		v_DROP_ORDER := v_DROP_ORDER+1;
	END LOOP;

	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
	DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);
	DBMS_LOB.WRITEAPPEND(v_RET, 2, '--');
	APPEND(WHAT_VERSION);
	APPEND_EMPTY_LINE;
	DBMS_LOB.WRITEAPPEND(v_RET, 25, '-- Script creation date: ');
	DBMS_LOB.WRITEAPPEND(v_RET, 9, SYSDATE);
	APPEND_EMPTY_LINE;
	APPEND('-- NOTE for drop.sql: This script must be run in an RO schema (not one with MINT/MEX types)');
	APPEND('-- NOTE for drop_all_objects.sql: This script must be run in a schema built with MINT/MEX');
	APPEND_EMPTY_LINE;
	APPEND_EMPTY_LINE;

	FOR v_REC IN (SELECT UNIQUE WORK_ID, WORK_DATA, WORK_SEQ
					FROM RTO_WORK
					ORDER BY WORK_SEQ DESC, WORK_DATA ASC) LOOP
		v_TEMP_TYPE_NAME := v_REC.WORK_DATA;

 		DBMS_LOB.WRITEAPPEND(v_RET, 10, 'DROP TYPE ');
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_TEMP_TYPE_NAME), v_TEMP_TYPE_NAME);
		DBMS_LOB.WRITEAPPEND(v_RET, 1, ';');
		APPEND_EMPTY_LINE;
	END LOOP;

	UT.PURGE_RTO_WORK(v_WORK_ID);

	COMMIT; --Necessary for the pragma autonomous_transaction.
	RETURN v_RET;

END GET_DROP_CLOB;
----------------------------------------------------------------------------------------------------
PROCEDURE CUT_ON_PEAK_HOURS
	(
	p_TIME_ZONE IN VARCHAR,
	p_CUT_BEGIN_HOUR OUT NUMBER,
	p_CUT_END_HOUR OUT NUMBER
	) AS

-- ANSWER THE BEGIN AND END HOURS OF THE ON PEAK PERIOD CONVERTED INTO CUT.
-- THESE VALUES CAN BE ADDED TO A DATE TO GIVE THE PROPER TIME.
-- NEGATIVE VALUES CORRESPOND TO THE PREVIOUS DAY (CURRENT DAY MINUS THOSE HOURS).
	v_PLAIN_DATE DATE;
	v_LOCAL_BEGIN_HOUR NUMBER(2);
	v_LOCAL_END_HOUR NUMBER(2);

BEGIN
	v_PLAIN_DATE := TRUNC(SYSDATE);

    v_LOCAL_BEGIN_HOUR := NVL(GET_DICTIONARY_VALUE('Begin_Hour',0,'On_Peak','?','?','?',0),7);
    v_LOCAL_END_HOUR := NVL(GET_DICTIONARY_VALUE('End_Hour',0,'On_Peak','?','?','?',0),22);

	p_CUT_BEGIN_HOUR := 24 * (TO_CUT(ADD_HOURS_TO_DATE(v_PLAIN_DATE,v_LOCAL_BEGIN_HOUR),p_TIME_ZONE) - v_PLAIN_DATE);
	p_CUT_END_HOUR := 24 * (TO_CUT(ADD_HOURS_TO_DATE(v_PLAIN_DATE,v_LOCAL_END_HOUR),p_TIME_ZONE) - v_PLAIN_DATE);

END CUT_ON_PEAK_HOURS;
----------------------------------------------------------------------------------------------------
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
	) AS

-- Perform a least squares linear regression of Y on X using the specified set of X,Y points
-- to determine the Alpha and Beta characteristics accordining to the linear equation Y = Alpha + Beta * X
-- X is the independent variable.
-- Y is the dependent variable.
-- The min and max are the range associated with the independent variable
--
-- Beta = (N * SUM(X*Y) - (SUM(X) * SUM(Y))) / (N * SUM(POWER(X,2)) - POWER(SUM(X),2))
-- Alpha = (SUM(Y) - (Beta * SUM(X))) / N

v_INDEX BINARY_INTEGER;
v_SUM_Y NUMBER := 0;
v_SUM_X NUMBER := 0;
v_SUM_Y2 NUMBER := 0;
v_SUM_X2 NUMBER := 0;
v_SUM_XY NUMBER := 0;
v_SUM_SQ_Y NUMBER := 0;
v_SUM_SQ_X NUMBER := 0;

BEGIN

	p_N := 0;
	p_X_MIN := 9999999;
	p_X_MAX := -9999999;
	p_X_MEAN := 0;
	p_Y_MIN := 9999999;
	p_Y_MAX := -9999999;
	p_Y_MEAN := 0;
	p_X_ZERO := 0;
	p_Y_ZERO := 0;

	FOR v_INDEX IN p_POINTS.FIRST..p_POINTS.LAST LOOP
		IF p_POINTS.EXISTS(v_INDEX) THEN
			p_N := p_N + 1;
			v_SUM_Y := v_SUM_Y + p_POINTS(v_INDEX).Y;
			v_SUM_X := v_SUM_X + p_POINTS(v_INDEX).X;
			v_SUM_Y2 := v_SUM_Y2 + POWER(p_POINTS(v_INDEX).Y,2);
			v_SUM_X2 := v_SUM_X2 + POWER(p_POINTS(v_INDEX).X,2);
			v_SUM_XY := v_SUM_XY + p_POINTS(v_INDEX).X * p_POINTS(v_INDEX).Y;
			p_X_MIN := LEAST(p_X_MIN, p_POINTS(v_INDEX).X);
			p_X_MAX := GREATEST(p_X_MAX, p_POINTS(v_INDEX).X);
			p_Y_MIN := LEAST(p_Y_MIN, p_POINTS(v_INDEX).Y);
			p_Y_MAX := GREATEST(p_Y_MAX, p_POINTS(v_INDEX).Y);
			IF p_POINTS(v_INDEX).X = 0 THEN p_Y_ZERO :=  p_X_ZERO + 1; END IF;
			IF p_POINTS(v_INDEX).Y = 0 THEN p_Y_ZERO :=  p_Y_ZERO + 1; END IF;
		END IF;
	END LOOP;

	IF p_N > 0 THEN
		p_Y_MEAN := v_SUM_Y / p_N;
		p_X_MEAN := v_SUM_X / p_N;
	END IF;

	FOR v_INDEX IN p_POINTS.FIRST..p_POINTS.LAST LOOP
		IF p_POINTS.EXISTS(v_INDEX) THEN
			v_SUM_SQ_Y := v_SUM_SQ_Y + POWER(p_POINTS(v_INDEX).Y - p_Y_MEAN, 2);
			v_SUM_SQ_X := v_SUM_SQ_X + POWER(p_POINTS(v_INDEX).X - p_X_MEAN, 2);
		END IF;
	END LOOP;

	BEGIN
		p_BETA := ((p_N * v_SUM_XY) - (v_SUM_X * v_SUM_Y)) / ((p_N * v_SUM_X2) - POWER(v_SUM_X,2));
		p_ALPHA := (v_SUM_Y - (p_BETA * v_SUM_X)) / p_N;
		p_R2 := (POWER(p_BETA, 2) * v_SUM_SQ_X) / v_SUM_SQ_Y;
	EXCEPTION
		WHEN OTHERS THEN
			p_BETA := 0;
			p_ALPHA := 0;
			p_R2 := 0;
	END;

EXCEPTION
	WHEN OTHERS THEN
		RAISE;

END LIN_REG;
----------------------------------------------------------------------------------------------------
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
	) AS

v_X_MEAN NUMBER;
v_Y_MEAN NUMBER;

BEGIN

	LIN_REG(p_POINTS, p_ALPHA, p_BETA, p_N, p_R2, p_X_MIN, p_X_MAX, v_X_MEAN, p_Y_MIN, p_Y_MAX, v_Y_MEAN, p_X_ZERO, p_Y_ZERO);

END LIN_REG;
----------------------------------------------------------------------------------------------------
PROCEDURE STD_DEV
	(
	p_OBS IN GA.NUMBER_TABLE,
	p_N OUT NUMBER,
	p_MEAN OUT NUMBER,
	p_STD OUT NUMBER,
	p_STD1 OUT NUMBER,
	p_STD2 OUT NUMBER,
	p_STD3 OUT NUMBER
	) AS

-- Calculate the Standard Deviation of a set of Observations.

v_INDEX BINARY_INTEGER;
v_SUM NUMBER := 0;
v_SUM_SQ NUMBER := 0;
v_STD2 NUMBER;
v_STD3 NUMBER;

BEGIN

	p_N := 0;
	p_MEAN := 0;
	p_STD := 0;
	p_STD1 := 0;
	p_STD2 := 0;
	p_STD3 := 0;

	FOR v_INDEX IN p_OBS.FIRST..p_OBS.LAST LOOP
		IF p_OBS.EXISTS(v_INDEX) THEN
			p_N := p_N + 1;
			v_SUM := v_SUM + p_OBS(v_INDEX);
		END IF;
	END LOOP;

	IF p_N > 0 THEN
		p_MEAN := v_SUM / p_N;
	END IF;

	FOR v_INDEX IN p_OBS.FIRST..p_OBS.LAST LOOP
		IF p_OBS.EXISTS(v_INDEX) THEN
			v_SUM_SQ := v_SUM_SQ + POWER(p_OBS(v_INDEX) - p_MEAN, 2);
		END IF;
	END LOOP;

	IF p_N > 1 THEN
		p_STD := SQRT(v_SUM_SQ / (p_N - 1));
		v_STD2 := p_STD * 2.0;
		v_STD3 := p_STD * 3.0;
		FOR v_INDEX IN p_OBS.FIRST..p_OBS.LAST LOOP
			IF p_OBS.EXISTS(v_INDEX) THEN
				IF p_OBS(v_INDEX) > p_STD THEN
					p_STD1 := p_STD1 + 1;
				ELSIF p_OBS(v_INDEX) > v_STD2 THEN
					p_STD2 := p_STD2 + 1;
				ELSIF p_OBS(v_INDEX) > v_STD3 THEN
					p_STD3 := p_STD3 + 1;
				END IF;
			END IF;
		END LOOP;
	END IF;

-- DBMS_OUTPUT.PUT_LINE('N=' || TO_CHAR(p_N));
-- DBMS_OUTPUT.PUT_LINE('MEAN=' || TO_CHAR(p_MEAN));
-- DBMS_OUTPUT.PUT_LINE('STD='  || TO_CHAR(p_STD));
-- DBMS_OUTPUT.PUT_LINE('STD1=' || TO_CHAR(p_STD1));
-- DBMS_OUTPUT.PUT_LINE('STD2=' || TO_CHAR(p_STD2));
-- DBMS_OUTPUT.PUT_LINE('STD3=' || TO_CHAR(p_STD3));

END STD_DEV;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_SYSTEM_LABELS
	(
	p_MODEL_ID IN NUMBER,
	p_MODULE IN VARCHAR,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

--c DEPRECATED 9/19/2002 Use GET_SYSTEM_LABELS in SP for current procedure.

c_Wildcard CHAR(2) := '??';

-- Answer a the values from the SYSTEM_LABEL tables matching the given keys or wildcards.

BEGIN

   p_STATUS := GA.SUCCESS;
	OPEN p_CURSOR FOR
		  SELECT VALUE, NVL(IS_DEFAULT,0) AS IS_DEFAULT, NVL(IS_HIDDEN,0) AS IS_HIDDEN, POSITION
		  FROM SYSTEM_LABEL
		  WHERE (MODEL_ID = 0 OR MODEL_ID = p_MODEL_ID)
		  	  AND UPPER(MODULE) = UPPER(LTRIM(RTRIM(p_MODULE)))
        	  AND UPPER(KEY1) = UPPER(LTRIM(RTRIM(DECODE(p_KEY1,c_Wildcard,KEY1,p_KEY1))))
        	  AND UPPER(KEY2) = UPPER(LTRIM(RTRIM(DECODE(p_KEY2,c_Wildcard,KEY2,p_KEY2))))
        	  AND UPPER(KEY3) = UPPER(LTRIM(RTRIM(DECODE(p_KEY3,c_Wildcard,KEY3,p_KEY3))))
    		  AND (IS_HIDDEN = 0 or IS_HIDDEN is NULL)
		  ORDER BY POSITION;

	EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

END GET_SYSTEM_LABELS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ALL_INCUMBENT_ENTITIES
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer all incumbent entities stored in SYSTEM_LABEL table.

BEGIN

	p_STATUS := GA.SUCCESS;

	IF GET_INCUMBENT_ENTITY_TYPE = 'EDC' THEN
		OPEN p_CURSOR FOR
			  SELECT B.EDC_NAME "INCUMBENT_NAME", A.INCUMBENT_ID
			  FROM(
				  SELECT TO_NUMBER(VALUE) "INCUMBENT_ID"
				  FROM SYSTEM_LABEL
				  WHERE MODEL_ID = 0
				  	  AND MODULE = 'Global'
					  AND KEY1 = 'Incumbent'
					  AND KEY2 = '?' AND KEY3 = '?') A,
			  ENERGY_DISTRIBUTION_COMPANY B
			  WHERE A.INCUMBENT_ID = B.EDC_ID
			  ORDER BY 2;
	ELSE
		OPEN p_CURSOR FOR
			  SELECT B.ESP_NAME "INCUMBENT_NAME", A.INCUMBENT_ID
			  FROM(
				  SELECT TO_NUMBER(VALUE) "INCUMBENT_ID"
				  FROM SYSTEM_LABEL
				  WHERE MODEL_ID = 0
				  	  AND MODULE = 'Global'
					  AND KEY1 = 'Incumbent'
					  AND KEY2 = '?' AND KEY3 = '?') A,
			  ENERGY_SERVICE_PROVIDER B
			  WHERE A.INCUMBENT_ID = B.ESP_ID
			  ORDER BY 2;
	END IF;


	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS := SQLCODE;

END GET_ALL_INCUMBENT_ENTITIES;
----------------------------------------------------------------------------------------------------
FUNCTION TSTAT_CRITICAL
	(
	p_OBSERVATIONS IN NUMBER,
	p_VARIABLES IN NUMBER,
	p_THRESHOLD IN NUMBER DEFAULT 0
	) RETURN NUMBER IS

v_TSTAT_CRITICAL NUMBER := 0;
v_DEGREES_OF_FREEDOM NUMBER(6);
v_A NUMBER;
v_B NUMBER;
v_C NUMBER;
v_F NUMBER;
v_K NUMBER;
v_U NUMBER;
v_X NUMBER;
v_OLD_A NUMBER;
v_I BINARY_INTEGER;
v_J BINARY_INTEGER;

BEGIN

	v_DEGREES_OF_FREEDOM := TRUNC(ABS(p_OBSERVATIONS - ((p_VARIABLES - 1) + 1)));

	IF v_DEGREES_OF_FREEDOM = 0 THEN
		RETURN v_TSTAT_CRITICAL;
	END IF;

	v_C := 1;
	IF (v_DEGREES_OF_FREEDOM / 2) = TRUNC(v_DEGREES_OF_FREEDOM / 2) THEN
		v_J := v_DEGREES_OF_FREEDOM / 2 - 1;
		v_K := (v_DEGREES_OF_FREEDOM + 1) / 2;
		FOR v_I IN 1..v_J LOOP
			v_C := v_C * (v_K - 1) / v_I;
		END LOOP;
		v_C := v_C * 0.5 / SQRT(v_DEGREES_OF_FREEDOM);
	ELSE
		v_J := (v_DEGREES_OF_FREEDOM - 1) / 2;
		FOR v_I IN 1..v_J LOOP
			v_C := v_C * v_I / (v_DEGREES_OF_FREEDOM / 2 - v_I);
		END LOOP;
		v_C := v_C / (SQRT(v_DEGREES_OF_FREEDOM) * 3.14159);
	END IF;

	v_B := -(v_DEGREES_OF_FREEDOM + 1) / 2;
	v_A := 0.5;
	v_C := v_C / 100;

	IF p_THRESHOLD <> 0 THEN
		v_K := p_THRESHOLD;
	ELSE
		v_K := 0.95;
	END IF;

	v_X := -0.005;

	FOR v_I IN 1..500 LOOP
		v_X := v_X + 0.01;
		v_F := POWER(1+ v_X * v_X / v_DEGREES_OF_FREEDOM, v_B);
		v_A := v_A + v_C * v_F;
		IF v_A > v_K THEN
			EXIT;
		END IF;
		v_OLD_A := v_A;
	END LOOP;

	v_U := v_X - 0.005;
	IF (v_A - v_OLD_A) = 0 THEN
		v_TSTAT_CRITICAL := 0;
	ELSE
		v_TSTAT_CRITICAL := ((v_K - v_OLD_A) / (v_A - v_OLD_A)) / 100 + v_U;
	END IF;

	RETURN v_TSTAT_CRITICAL;

END TSTAT_CRITICAL;
----------------------------------------------------------------------------------------------------
PROCEDURE MVAR_REG
	(
	p_N IN NUMBER, -- Number Of Observations
	p_M IN NUMBER, -- Number Of Independent Variables
	p_X IN GA.NUMBER_TABLE, -- Independent Variable(X) Values (N,M) Array
	p_Y IN GA.NUMBER_TABLE, -- Dependent Variable(Y) Values
	p_B IN OUT GA.NUMBER_TABLE, -- X Coefficients
	p_T IN OUT GA.NUMBER_TABLE, -- T Statistic
	p_R IN OUT NUMBER, -- R2 Statistic
	p_TSTAT_CRITICAL IN OUT NUMBER, -- T Statistic Critical
	p_ELAPSED_TIME IN OUT PLS_INTEGER
	) AS

-- Modified: wjc Oct-31-2003 - Added several checks for zero (or almost) to match VB regression.

v_I BINARY_INTEGER;
v_J BINARY_INTEGER;
v_K BINARY_INTEGER;
v_IJ BINARY_INTEGER;
v_IK BINARY_INTEGER;
v_IM BINARY_INTEGER;
v_JM BINARY_INTEGER;
v_KM BINARY_INTEGER;
v_IMM BINARY_INTEGER;
v_IN BINARY_INTEGER;
v_JN BINARY_INTEGER;
v_M2 NUMBER;
v_Z2 NUMBER;
v_Z5 NUMBER;
v_Z6 NUMBER;
v_S NUMBER;
v_S2 NUMBER;
v_S4 NUMBER;
v_YBAR NUMBER;
v_Z GA.NUMBER_TABLE; -- Z(M * 2,M)
v_C GA.NUMBER_TABLE; -- C(M,M)
v_D GA.NUMBER_TABLE; -- D(M,N)
v_E GA.NUMBER_TABLE; -- E(N)
v_YHAT GA.NUMBER_TABLE; -- YHAT(N)
v_IND_VAR_HAS_DATA GA.BOOLEAN_TABLE; -- Flag(M) indicating independent variable is not all zeroes
v_VALUE NUMBER;
v_PREV_VALUE NUMBER;
v_SMALL NUMBER := 0.000000000001;  -- Small number for comparisons with numbers close to zero.
v_R2_VALID BOOLEAN;
v_ADD_STATS BOOLEAN;

BEGIN

-- Calculate X transpose times X.

	p_ELAPSED_TIME := DBMS_UTILITY.GET_TIME;

   	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('MVAR_REG');
		LOGS.LOG_DEBUG_DETAIL('N=' || TO_CHAR(p_N));
		LOGS.LOG_DEBUG_DETAIL('M=' || TO_CHAR(p_M));
        DECLARE
        	v_INDEX BINARY_INTEGER;
		BEGIN
			FOR v_INDEX IN p_X.FIRST..p_X.LAST LOOP
				IF v_INDEX = p_X.FIRST THEN
					LOGS.LOG_DEBUG_DETAIL('X=');
					LOGS.LOG_DEBUG_DETAIL('  COUNT=' || TO_CHAR(p_X.COUNT));
					LOGS.LOG_DEBUG_DETAIL('  <value>@<index>');
				END IF;
				IF p_X.EXISTS(v_INDEX) THEN
					LOGS.LOG_DEBUG_DETAIL('  ' || TO_CHAR(p_X(v_INDEX)) || '@' || TO_CHAR(v_INDEX));
				END IF;
			END LOOP;
		END;
        DECLARE
        	v_INDEX BINARY_INTEGER;
		BEGIN
			FOR v_INDEX IN p_Y.FIRST..p_Y.LAST LOOP
				IF v_INDEX = p_Y.FIRST THEN
					LOGS.LOG_DEBUG_DETAIL('X=');
					LOGS.LOG_DEBUG_DETAIL('  COUNT=' || TO_CHAR(p_Y.COUNT));
					LOGS.LOG_DEBUG_DETAIL('  <value>@<index>');
				END IF;
				IF p_Y.EXISTS(v_INDEX) THEN
					LOGS.LOG_DEBUG_DETAIL('  ' || TO_CHAR(p_Y(v_INDEX)) || '@' || TO_CHAR(v_INDEX));
				END IF;
			END LOOP;
		END;
		LOGS.LOG_DEBUG_DETAIL('Calculate X transpose times X.');
	END IF;

-- Start with calculation of X transpose times X.

	FOR v_I IN 1..p_M LOOP
		v_IND_VAR_HAS_DATA(v_I) := FALSE;
        v_PREV_VALUE := 0;
        v_IM := (v_I - 1) * p_M;   --Multiply just once in outer loop - wjc Oct-02-2003
        FOR v_J IN 1..p_M LOOP
			v_Z2 := 0;
			FOR v_K IN 1..p_N LOOP
				v_KM := (v_K - 1) * p_M;   --Multiply just once
                v_VALUE := p_X((v_KM) + v_I);         -- X(K,I)
                IF v_VALUE <> v_PREV_VALUE THEN        -- Added to match VB regression - wjc Oct-31-2003
                   v_IND_VAR_HAS_DATA(v_I) := TRUE;   -- Found non-zero data for this independent var
                END IF;
                v_Z2 := v_Z2 + v_VALUE * p_X((v_KM) + v_J); -- Z2 := Z2 + X(K,I) * X(K,J);
                v_PREV_VALUE := v_VALUE;
			END LOOP; -- Next K;
    		v_Z(v_IM + v_J) := v_Z2; -- Z(I,J) := Z2;  -- Calculate in M*M cells
		END LOOP; -- Next J;
	END LOOP; -- Next I;

-- Calculate the Inverse of X'X into C.

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Calculate the Inverse of X*X into C');
	END IF;

    v_M2 := p_M + p_M;
	FOR v_I IN p_M + 1..v_M2 LOOP  --Use precalculated M*2
		v_IM := (v_I - 1) * p_M;   --Multiply just once in outer loop - wjc Oct-02-2003
        --Extend v_Z for 2nd set of M*M cells
		FOR v_J IN 1..p_M LOOP
			v_Z(v_IM + v_J) := 0; -- Z(I,J) := 0;
		END LOOP; -- Next J;

        v_Z(v_IM + (v_I - p_M)) := 1; -- Z(I,I-M) := 1; --Set diagonal = 1
	END LOOP; -- Next I;

	FOR v_J IN 1..p_M LOOP
		v_JM := (v_J - 1) * p_M;   --Multiply just once
		v_Z5 := v_Z(v_JM + v_J); -- Z(J,J);
		IF ABS(v_Z5) < v_SMALL THEN v_Z5 := 1; END IF;  -- Added to Avoid Division by (almost) Zero - wjc Oct-31-2003
		FOR v_I IN 1..v_M2 LOOP  --Use precalculated M*2
			v_IJ := ((v_I - 1) * p_M) + v_J;
			v_Z(v_IJ) := v_Z(v_IJ) / v_Z5; -- Z(I,J) / Z5;
		END LOOP; -- Next I;
		FOR v_K IN 1..p_M LOOP
			IF v_K <> v_J THEN
    			v_Z6 := v_Z(v_JM + v_K); -- Z(J,K);
				FOR v_I IN 1..v_M2 LOOP  --Use precalculated M*2
					IF ABS(v_Z6) > v_SMALL THEN     --Only multiply non-zero Z6   -- Added to match VB regression - wjc Oct-31-2003
                        v_IM := (v_I - 1) * p_M;   --Multiply just once
                        v_IJ := v_IM + v_J;
    					v_IK := v_IM + v_K;
    					v_Z(v_IK) := v_Z(v_IK) - v_Z(v_IJ) * v_Z6; -- Z(I,K) := Z(I,K) - Z(I,J) * Z6;
                    END IF;
				END LOOP; -- Next I;
			END IF;
		END LOOP; -- Next K;
	END LOOP; -- Next J;

-- C Represents  X'X Inverse.

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Collect C');
	END IF;

	FOR v_I IN 1..p_M LOOP
		v_IM := (v_I - 1) * p_M;   --Multiply just once in outer loop - wjc Oct-02-2003
		v_IMM := (v_I + p_M - 1) * p_M;   --Multiply just once in outer loop - wjc Oct-02-2003
		FOR v_J IN 1..p_M LOOP
			v_C(v_IM + v_J) := v_Z(v_IMM + v_J) ; -- C(I,J) := Z(I+M,J) := 0;
		END LOOP; -- Next J;
	END LOOP; -- Next I;

-- D Represents  X'X Inverse Times X'.

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Collect D');
	END IF;

	FOR v_I IN 1..p_M LOOP
		v_IM := (v_I - 1) * p_M;   --Multiply just once in outer loop - wjc Oct-02-2003
		v_IN := (v_I - 1) * p_N;   --Multiply just once in outer loop - wjc Oct-02-2003
		FOR v_J IN 1..p_N LOOP
			v_JM := (v_J - 1) * p_M;   --Multiply just once
            v_Z2 := 0;
			FOR v_K IN 1..p_M LOOP
				v_Z2 := v_Z2 + v_C(v_IM + v_K) * p_X(v_JM + v_K); -- Z2 := Z2 + C(I,K) * X(J,K);
			END LOOP; -- Next K;
			v_D(v_IN + v_J) := v_Z2; -- D(I,J) := Z2;  --Note: D is dimensioned by # of observations
		END LOOP; -- Next J;
	END LOOP; -- Next I;

-- B Represents the Coefficients of the Regression.

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Collect B');
	END IF;

	FOR v_J IN 1..p_M LOOP
		p_B(v_J) := 0;
        v_JN := (v_J - 1) * p_N;   --Multiply just once
		FOR v_I IN 1..p_N LOOP
			p_B(v_J) := p_B(v_J) + v_D(v_JN + v_I) * p_Y(v_I); -- B(J) := B(J) + D(J,I) * Y(I);
		END LOOP; -- Next I;
	END LOOP; -- Next J;

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Generate Statistics');
	END IF;

	v_S2 := 0;
	FOR v_I IN 1..p_N LOOP
		v_Z2 := 0;
		v_IM := (v_I - 1) * p_M;   --Multiply just once in outer loop - wjc Oct-02-2003
		FOR v_J IN 1..p_M LOOP
			v_Z2 := v_Z2 + p_X(v_IM + v_J) * p_B(v_J); -- Z2 := Z2 + X(I,J) * B(J);
		END LOOP; -- Next J;
		v_YHAT(v_I) := v_Z2; -- Estimated Value for Y.
		v_E(v_I) := p_Y(v_I) - v_YHAT(v_I);
		v_S2 := v_S2 + v_E(v_I) * v_E(v_I);
	END LOOP; -- Next I;

    IF p_N - p_M = 0 THEN
    	v_S := SQRT(v_S2);
    ELSE
		v_S := SQRT(v_S2 / ABS(p_N - p_M)); -- Estimate of Standard Deviation.
    END IF;

	v_YBAR := 0;
	FOR v_I IN 1..p_N LOOP
		v_YBAR := v_YBAR + p_Y(v_I);
	END LOOP; -- Next I;
	v_YBAR := v_YBAR / p_N; -- Average Value of Y.

	-- R Squared.
    v_S4 := 0;
	FOR v_I IN 1..p_N LOOP
		v_S4 := v_S4 + POWER(p_Y(v_I) - v_YBAR, 2);
	END LOOP; -- Next I;
    IF ABS(v_S4) < v_SMALL THEN    --Avoid divide by (almost) zero - wjc Oct-31-2003
    	p_R := 1 - v_S2;
    ELSE
    	p_R := 1 - v_S2 / v_S4; -- R Squared.
    END IF;

	-- T STAT
	FOR v_I IN 1..p_M LOOP
        v_S4 := v_S * SQRT(v_C(((v_I - 1) * p_M) + v_I));
        IF ABS(v_S4) < v_SMALL THEN    --Avoid divide by (almost) zero - wjc Oct-31-2003
    		p_T(v_I) := p_B(v_I);
        ELSE
    		p_T(v_I) := p_B(v_I) / v_S4;	-- T STAT
        END IF;
	END LOOP; -- Next I;

	-- If results are not valid, set to zero.  -- Added to match VB regression - wjc Oct-31-2003
    v_ADD_STATS := TRUE;
    v_R2_VALID := (ABS(p_R) <= 1);
    FOR v_I IN 1..p_M LOOP
        IF NOT v_IND_VAR_HAS_DATA(v_I) OR NOT v_R2_VALID THEN
           p_B(v_I) := 0;
           p_T(v_I) := 0;
           v_ADD_STATS := FALSE;
        END IF;
	END LOOP; -- Next I;

    IF v_ADD_STATS AND v_R2_VALID THEN
    	p_TSTAT_CRITICAL := TSTAT_CRITICAL(p_N, p_M);
    ELSE
    	p_R := 0;
    	p_TSTAT_CRITICAL := 0;
    END IF;

	p_ELAPSED_TIME := DBMS_UTILITY.GET_TIME - p_ELAPSED_TIME;

END MVAR_REG;
----------------------------------------------------------------------------------------------------
PROCEDURE MVAR_REG_TEST AS

v_N NUMBER; -- Number Of Observations
v_M NUMBER; -- Number Of Independent Varaibles
v_X GA.NUMBER_TABLE; -- Independent Variable(X) Values (N,M) Array
v_Y GA.NUMBER_TABLE; -- Dependent Variable(Y) Values
v_B GA.NUMBER_TABLE; -- X Coefficients
v_T GA.NUMBER_TABLE; -- T Statistic
v_R NUMBER; -- R2 Statistic
v_TSTAT_CRITICAL NUMBER;
v_INDEX BINARY_INTEGER;
v_ELAPSED_TIME PLS_INTEGER;

BEGIN

	v_N := 8;
	v_M := 3;

-- Ice Cream Demand
	v_Y(1) := 52;
	v_Y(2) := 72;
	v_Y(3) := 78;
	v_Y(4) := 109;
	v_Y(5) := 57;
	v_Y(6) := 128;
	v_Y(7) := 95;
	v_Y(8) := 116;
-- Income
	v_X(1) := 1;
	v_X(4) := 1;
	v_X(7) := 1;
	v_X(10) := 1;
	v_X(13) := 1;
	v_X(16) := 1;
	v_X(19) := 1;
	v_X(22) := 1;
-- Temperature
	v_X(2) := 4;
	v_X(5) := 7;
	v_X(8) := 7;
	v_X(11) := 12;
	v_X(14) := 4;
	v_X(17) := 15;
	v_X(20) := 12;
	v_X(23) := 15;
-- Constant
	v_X(3) := 10;
	v_X(6) := 12;
	v_X(9) := 16;
	v_X(12) := 15;
	v_X(15) := 15;
	v_X(18) := 16;
	v_X(21) := 9;
	v_X(24) := 10;

	MVAR_REG(v_N, v_M, v_X, v_Y, v_B, v_T, v_R, v_TSTAT_CRITICAL, v_ELAPSED_TIME);

	DBMS_OUTPUT.PUT_LINE('Coefficients');
	v_INDEX := v_B.FIRST;
	WHILE v_INDEX <= v_B.LAST LOOP
		DBMS_OUTPUT.PUT_LINE('B(' || TO_CHAR(v_INDEX) || ')=' || TO_CHAR(v_B(v_INDEX)));
		v_INDEX := v_B.NEXT(v_INDEX);
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('T-Statistics');
	v_INDEX := v_T.FIRST;
	WHILE v_INDEX <= v_T.LAST LOOP
		DBMS_OUTPUT.PUT_LINE('T(' || TO_CHAR(v_INDEX) || ')=' || TO_CHAR(v_T(v_INDEX)));
		v_INDEX := v_T.NEXT(v_INDEX);
	END LOOP;

	DBMS_OUTPUT.PUT_LINE('R2=' || TO_CHAR(v_R));
	DBMS_OUTPUT.PUT_LINE('TSTAT_CRITICAL=' || TO_CHAR(v_TSTAT_CRITICAL));
	DBMS_OUTPUT.PUT_LINE('ELAPSED_TIME=' || TO_CHAR(v_ELAPSED_TIME));

END MVAR_REG_TEST;
----------------------------------------------------------------------------------------------------
PROCEDURE APPEND
	(
    p_SRC_ARRAY IN GA.NUMBER_TABLE,
    p_DEST_ARRAY IN OUT NOCOPY GA.NUMBER_TABLE
    ) AS
v_INDEX BINARY_INTEGER;
BEGIN
	IF p_SRC_ARRAY.COUNT = 0 THEN
    	RETURN;
    END IF;

	v_INDEX := p_SRC_ARRAY.FIRST;
    LOOP
    	IF p_DEST_ARRAY.COUNT = 0 THEN
        	p_DEST_ARRAY(1) := p_SRC_ARRAY(v_INDEX);
		ELSE
	        p_DEST_ARRAY(p_DEST_ARRAY.LAST+1) := p_SRC_ARRAY(v_INDEX);
        END IF;
    	IF v_INDEX = p_SRC_ARRAY.LAST THEN EXIT; END IF;
        v_INDEX := p_SRC_ARRAY.NEXT(v_INDEX);
    END LOOP;
END APPEND;
----------------------------------------------------------------------------------------------------
PROCEDURE DUMP_CLOB_TO_RTO_WORK
	(
    p_CLOB IN CLOB,
    p_WORK_ID IN NUMBER
    ) AS
v_TEMP NUMBER;
v_CLOB_LEN NUMBER := DBMS_LOB.GETLENGTH(p_CLOB);
v_CLOB_POS NUMBER := 1;
v_CLOB_END1 NUMBER;
v_CLOB_END2 NUMBER;
v_SEQ NUMBER := 0;
v_READ_LEN NUMBER;
v_TEXT RTO_WORK.WORK_DATA%TYPE;
BEGIN
	WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
    	-- find line break character(s)
    	v_CLOB_END1 := DBMS_LOB.INSTR(p_CLOB, CHR(10), v_CLOB_POS);
    	v_CLOB_END2 := DBMS_LOB.INSTR(p_CLOB, CHR(13), v_CLOB_POS);
        IF v_CLOB_END1 = 0 THEN v_CLOB_END1 := v_CLOB_END2; END IF;
        IF v_CLOB_END2 = 0 THEN v_CLOB_END2 := v_CLOB_END1; END IF;
        -- no line break? then set end positions to end of clob
        IF v_CLOB_END1 = 0 THEN
        	v_CLOB_END1 := v_CLOB_LEN+1;
        	v_CLOB_END2 := v_CLOB_LEN+1;
        END IF;
        -- make sure that end1 is the first linebreak character (in case of two: "\r\n") and end2 is second
        IF v_CLOB_END1 > v_CLOB_END2 THEN
        	v_TEMP := v_CLOB_END1;
            v_CLOB_END1 := v_CLOB_END2;
            v_CLOB_END2 := v_TEMP;
        END IF;
        v_READ_LEN := v_CLOB_END1-v_CLOB_POS;
        IF v_READ_LEN > 0 THEN
        	-- if line is too long, just grab first 256 characters of it, and line-wrap
        	IF v_READ_LEN > 256 THEN
            	v_READ_LEN := 256;
                v_CLOB_END2 := v_CLOB_POS+v_READ_LEN-1;
            END IF;
            v_TEXT := DBMS_LOB.SUBSTR(p_CLOB,v_READ_LEN,v_CLOB_POS);
            -- push to RTO_WORK
            UT.POST_RTO_WORK(p_WORK_ID, v_SEQ, v_TEXT);
            v_SEQ := v_SEQ+1;
		ELSE
            -- push blank line to RTO_WORK
            UT.POST_RTO_WORK(p_WORK_ID, v_SEQ, '');
            v_SEQ := v_SEQ+1;
        END IF;
        v_CLOB_POS := v_CLOB_END2+1; -- on to the next line
    END LOOP;
END DUMP_CLOB_TO_RTO_WORK;
----------------------------------------------------------------------------------------------------
PROCEDURE NEXT_TOKEN
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_INDEX IN BINARY_INTEGER,
	p_EOF OUT BOOLEAN,
	p_TOKEN OUT VARCHAR
	) AS

v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;

--p_INDEX IS A ONE-BASED INDEX.
BEGIN

	--THESE DEFAULTS WILL BE RETURNED IF A PROPER TOKEN IS NOT FOUND.
	p_EOF := TRUE;
	p_TOKEN := NULL;

	--TRY TO FIND A PROPER TOKEN.
	IF NOT LTRIM(RTRIM(p_STRING)) IS NULL THEN
		v_BEGIN_POS := INSTR(p_DELIMITER || p_STRING, p_DELIMITER, 1, p_INDEX);
		v_END_POS := INSTR(p_STRING || p_DELIMITER, p_DELIMITER, 1, p_INDEX);
		IF v_END_POS > 0 AND v_BEGIN_POS > 0 THEN
			p_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
			p_EOF := FALSE;
		END IF;
	END IF;

END NEXT_TOKEN;
----------------------------------------------------------------------------------------------------
PROCEDURE STRING_TABLE_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	) AS

v_INDEX BINARY_INTEGER := 1;
v_TOKEN VARCHAR(256);
v_EOF BOOLEAN;
BEGIN

	p_STRING_TABLE := STRING_TABLE();

	LOOP
		NEXT_TOKEN(p_STRING, p_DELIMITER, v_INDEX, v_EOF, v_TOKEN);
		EXIT WHEN v_EOF;
		p_STRING_TABLE.EXTEND();
		p_STRING_TABLE(v_INDEX) := STRING_TYPE(v_TOKEN);
		v_INDEX := v_INDEX + 1;
	END LOOP;

END STRING_TABLE_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE STRING_COLLECTION_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_COLL OUT STRING_COLLECTION
	) AS
v_INDEX BINARY_INTEGER := 1;
v_TOKEN VARCHAR(256);
v_EOF BOOLEAN;
BEGIN

	p_STRING_COLL := STRING_COLLECTION();

	LOOP
		NEXT_TOKEN(p_STRING, p_DELIMITER, v_INDEX, v_EOF, v_TOKEN);
		EXIT WHEN v_EOF;
		p_STRING_COLL.EXTEND();
		p_STRING_COLL(v_INDEX) := v_TOKEN;
		v_INDEX := v_INDEX + 1;
	END LOOP;

END STRING_COLLECTION_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE ID_TABLE_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_ID_TABLE OUT ID_TABLE
	) AS

v_INDEX BINARY_INTEGER := 1;
v_TOKEN VARCHAR(256);
v_EOF BOOLEAN;
BEGIN

	p_ID_TABLE := ID_TABLE();

	LOOP
		NEXT_TOKEN(p_STRING, p_DELIMITER, v_INDEX, v_EOF, v_TOKEN);
		EXIT WHEN v_EOF;
		p_ID_TABLE.EXTEND();
		p_ID_TABLE(v_INDEX) := ID_TYPE(TO_NUMBER(v_TOKEN));
		v_INDEX := v_INDEX + 1;
	END LOOP;

END ID_TABLE_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE NUMBER_COLL_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_NUMS OUT NUMBER_COLLECTION
	) AS

v_INDEX BINARY_INTEGER := 1;
v_TOKEN VARCHAR(256);
v_EOF BOOLEAN;
BEGIN
	p_NUMS := NUMBER_COLLECTION();
	LOOP
		NEXT_TOKEN(p_STRING, p_DELIMITER, v_INDEX, v_EOF, v_TOKEN);
		EXIT WHEN v_EOF;
		p_NUMS.EXTEND();
		p_NUMS(p_NUMS.LAST) := TO_NUMBER(v_TOKEN);
		v_INDEX := v_INDEX + 1;
	END LOOP;
END NUMBER_COLL_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE NUMBER_COLL_FROM_ID_TABLE
	(
	p_ID_TABLE IN ID_TABLE,
	p_NUMS OUT NUMBER_COLLECTION
	) AS
v_IDX PLS_INTEGER;
BEGIN
	p_NUMS := NUMBER_COLLECTION();
	v_IDX := p_ID_TABLE.FIRST;
	WHILE p_ID_TABLE.EXISTS(v_IDX) LOOP
		p_NUMS.EXTEND();
		p_NUMS(p_NUMS.LAST) := p_ID_TABLE(v_IDX).ID;
		v_IDX := p_ID_TABLE.NEXT(v_IDX);
	END LOOP;
END NUMBER_COLL_FROM_ID_TABLE;
----------------------------------------------------------------------------------------------------
PROCEDURE ID_TABLE_FROM_NUMBER_COLL
	(
	p_NUMS IN NUMBER_COLLECTION,
	p_ID_TABLE OUT ID_TABLE
	) AS
v_IDX PLS_INTEGER;
BEGIN
	p_ID_TABLE := ID_TABLE();
	v_IDX := p_NUMS.FIRST;
	WHILE p_NUMS.EXISTS(v_IDX) LOOP
		p_ID_TABLE.EXTEND();
		p_ID_TABLE(p_ID_TABLE.LAST) := ID_TYPE(p_NUMS(v_IDX));
		v_IDX := p_NUMS.NEXT(v_IDX);
	END LOOP;
END ID_TABLE_FROM_NUMBER_COLL;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LITERAL_FOR_NUMBER(p_VALUE IN NUMBER) RETURN VARCHAR2 IS
-- take a numeric value and return a string that represents it as a PL/SQL literal
BEGIN
	IF p_VALUE IS NULL THEN
		RETURN CONSTANTS.LITERAL_NULL;
	ELSE
		RETURN TO_CHAR(p_VALUE);
	END IF;
END GET_LITERAL_FOR_NUMBER;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LITERAL_FOR_STRING(p_VALUE IN VARCHAR2) RETURN VARCHAR2 IS
-- take a string value and return a string that represents it as a PL/SQL literal
BEGIN
	RETURN ''''||REPLACE(p_VALUE,'''','''''')||'''';
END GET_LITERAL_FOR_STRING;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LITERAL_FOR_DATE(p_VALUE IN DATE) RETURN VARCHAR2 IS
-- take a date value and return a string that represents it as a PL/SQL literal
BEGIN
	IF p_VALUE IS NULL THEN
		RETURN CONSTANTS.LITERAL_NULL;
	ELSE
		RETURN '(DATE '''||TO_CHAR(p_VALUE,'YYYY-MM-DD')||''' + INTERVAL '''||TO_CHAR(p_VALUE,'HH24')||''' HOUR + '
				||'INTERVAL '''||TO_CHAR(p_VALUE,'MI')||''' MINUTE + INTERVAL '''||TO_CHAR(p_VALUE,'SS')||''' SECOND)';
	END IF;
END GET_LITERAL_FOR_DATE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LITERAL_FOR_NUMBER_COLL(p_VALUES IN NUMBER_COLLECTION) RETURN VARCHAR2 IS
-- take a numeric list and return a string that represents it as a PL/SQL literal
v_RET VARCHAR2(32767);
v_IDX PLS_INTEGER;
v_FIRST BOOLEAN;
BEGIN
	IF p_VALUES IS NULL THEN
		RETURN CONSTANTS.LITERAL_NULL;
	ELSE
		v_RET := 'NUMBER_COLLECTION(';
		v_IDX := p_VALUES.FIRST;
		v_FIRST := TRUE;
		WHILE p_VALUES.EXISTS(v_IDX) LOOP
			IF v_FIRST THEN
				v_FIRST := FALSE;
			ELSE
				v_RET := v_RET||', ';
			END IF;
			v_RET := v_RET||GET_LITERAL_FOR_NUMBER(p_VALUES(v_IDX));
			v_IDX := p_VALUES.NEXT(v_IDX);
		END LOOP;
		v_RET := v_RET||')';
		RETURN v_RET;
	END IF;
END GET_LITERAL_FOR_NUMBER_COLL;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LITERAL_FOR_STRING_COLL(p_VALUES IN STRING_COLLECTION) RETURN VARCHAR2 IS
-- take a string list and return a string that represents it as a PL/SQL literal
v_RET VARCHAR2(32767);
v_IDX PLS_INTEGER;
v_FIRST BOOLEAN;
BEGIN
	IF p_VALUES IS NULL THEN
		RETURN CONSTANTS.LITERAL_NULL;
	ELSE
		v_RET := 'STRING_COLLECTION(';
		v_IDX := p_VALUES.FIRST;
		v_FIRST := TRUE;
		WHILE p_VALUES.EXISTS(v_IDX) LOOP
			IF v_FIRST THEN
				v_FIRST := FALSE;
			ELSE
				v_RET := v_RET||', ';
			END IF;
			v_RET := v_RET||GET_LITERAL_FOR_STRING(p_VALUES(v_IDX));
			v_IDX := p_VALUES.NEXT(v_IDX);
		END LOOP;
		v_RET := v_RET||')';
		RETURN v_RET;
	END IF;
END GET_LITERAL_FOR_STRING_COLL;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LITERAL_FOR_DATE_COLL(p_VALUES IN DATE_COLLECTION) RETURN VARCHAR2 IS
-- take a date list and return a string that represents it as a PL/SQL literal
v_RET VARCHAR2(32767);
v_IDX PLS_INTEGER;
v_FIRST BOOLEAN;
BEGIN
	IF p_VALUES IS NULL THEN
		RETURN CONSTANTS.LITERAL_NULL;
	ELSE
		v_RET := 'DATE_COLLECTION(';
		v_IDX := p_VALUES.FIRST;
		v_FIRST := TRUE;
		WHILE p_VALUES.EXISTS(v_IDX) LOOP
			IF v_FIRST THEN
				v_FIRST := FALSE;
			ELSE
				v_RET := v_RET||', ';
			END IF;
			v_RET := v_RET||GET_LITERAL_FOR_DATE(p_VALUES(v_IDX));
			v_IDX := p_VALUES.NEXT(v_IDX);
		END LOOP;
		v_RET := v_RET||')';
		RETURN v_RET;
	END IF;
END GET_LITERAL_FOR_DATE_COLL;
----------------------------------------------------------------------------------------------------
FUNCTION STRING_COLLECTION_CONTAINS
	(
	p_VALS IN STRING_COLLECTION,
	p_VAL IN VARCHAR2,
	p_CASE_SENSITIVE IN BOOLEAN := TRUE
	) RETURN BOOLEAN 
IS
	v_KEY_SET			STRING_COLLECTION := STRING_COLLECTION(p_VAL);
	v_CLONE_COLLECTION	STRING_COLLECTION := STRING_COLLECTION();
	v_COMPARISON_RESULT STRING_COLLECTION := STRING_COLLECTION();
	v_RETURN 			BOOLEAN := FALSE;
BEGIN
	-- Is this case-insensitive
	IF NOT p_CASE_SENSITIVE THEN
		FOR I IN 1..p_VALS.COUNT LOOP
			v_CLONE_COLLECTION.EXTEND(1);
			v_CLONE_COLLECTION(I) := UPPER(p_VALS(I));			
		END LOOP;
		v_KEY_SET(1) := UPPER(p_VAL);
	ELSE
		v_CLONE_COLLECTION := p_VALS;
	END IF;
	-- Does this element exist?
	v_COMPARISON_RESULT := v_KEY_SET MULTISET INTERSECT v_CLONE_COLLECTION;
	-- if so set the flag
	IF v_COMPARISON_RESULT.COUNT > 0 THEN
		v_RETURN := TRUE;
	END IF;	
	-- Return
	RETURN v_RETURN;
END STRING_COLLECTION_CONTAINS;
----------------------------------------------------------------------------------------------------
FUNCTION NUMBER_COLLECTION_CONTAINS
	(
	p_VALS IN NUMBER_COLLECTION,
	p_VAL IN NUMBER
	) RETURN BOOLEAN IS
v_IDX PLS_INTEGER;
BEGIN
	v_IDX := p_VALS.FIRST;
	WHILE p_VALS.EXISTS(v_IDX) LOOP
		IF p_VALS(v_IDX) = p_VAL THEN
			RETURN TRUE;
		END IF;
		v_IDX := p_VALS.NEXT(v_IDX);
	END LOOP;
	RETURN FALSE;
END NUMBER_COLLECTION_CONTAINS;
----------------------------------------------------------------------------------------------------
FUNCTION ID_TABLE_CONTAINS
	(
	p_VALS IN ID_TABLE,
	p_VAL IN NUMBER
	) RETURN BOOLEAN IS
v_IDX PLS_INTEGER;
BEGIN
	v_IDX := p_VALS.FIRST;
	WHILE p_VALS.EXISTS(v_IDX) LOOP
		IF p_VALS(v_IDX).ID = p_VAL THEN
			RETURN TRUE;
		END IF;
		v_IDX := p_VALS.NEXT(v_IDX);
	END LOOP;
	RETURN FALSE;
END ID_TABLE_CONTAINS;
---------------------------------------------------------------------------------------------------
PROCEDURE ADD_SOURCE
(
p_TYPE_NAME IN VARCHAR2,
p_FILE IN OUT NOCOPY CLOB
) AS

	k_SPACES VARCHAR2(100) := '                                                                                                ';

	-- this query will eliminate trailing empty lines and also has a field, BLANK_START, that
	-- indicates whether (and where) this line has a large number of spaces - which typically
	-- happens between the "TYPE XXX" and the "AS {OBJECT|TABLE...}" parts of the first line
    CURSOR c_SRC(p_TYPE IN VARCHAR2) IS
        SELECT TEXT, LINE, INSTR(TEXT,k_SPACES) as BLANK_START
        FROM (SELECT S.TEXT, S.LINE, MAX(S.LINE) OVER (PARTITION BY 1) as LINE_COUNT,
            	MAX(CASE WHEN TRIM(REPLACE(REPLACE(REPLACE(S.TEXT,CHR(13),NULL),CHR(10),NULL),CHR(9),NULL)) IS NULL THEN NULL ELSE S.LINE END) OVER (PARTITION BY 1) as MAX_LINE
            FROM USER_SOURCE S
            WHERE S.NAME = p_TYPE_NAME
            	  AND S.TYPE = p_TYPE)
        	WHERE LINE <= MAX_LINE
            ORDER BY LINE ASC;

    v_HAS_BODY BINARY_INTEGER;

	PROCEDURE WRITE_IT(p_TYPE IN VARCHAR2) AS
    v_LINE VARCHAR2(32000);
	BEGIN

    	v_LINE := 'CREATE OR REPLACE ';
    	DBMS_LOB.WRITEAPPEND(p_FILE, LENGTH(v_LINE), v_LINE);

    	FOR v_SRC IN c_SRC(p_TYPE) LOOP
			IF v_SRC.LINE = 1 AND v_SRC.BLANK_START > 0 THEN
				-- eliminate huge number of spaces found in the first line
				v_LINE := RTRIM(SUBSTR(v_SRC.TEXT,1,v_SRC.BLANK_START))||' '||LTRIM(SUBSTR(v_SRC.TEXT,v_SRC.BLANK_START));
			ELSE
				v_LINE := v_SRC.TEXT;
			END IF;

    		-- convert all newline-conventions to consistently be CRLF
    		v_LINE := REPLACE(REPLACE(v_LINE,CHR(10),NULL),CHR(13),NULL)||UTL_TCP.CRLF;
			DBMS_LOB.WRITEAPPEND(p_FILE, LENGTH(v_LINE), v_LINE);
    	END LOOP;

    	v_LINE := '/'||UTL_TCP.CRLF||UTL_TCP.CRLF;
    	DBMS_LOB.WRITEAPPEND(p_FILE, LENGTH(v_LINE), v_LINE);

	END WRITE_IT;

BEGIN

	DBMS_LOB.OPEN(p_FILE, DBMS_LOB.LOB_READWRITE);

	WRITE_IT('TYPE');

	SELECT COUNT(1)
	INTO v_HAS_BODY
	FROM USER_OBJECTS
	WHERE OBJECT_TYPE = 'TYPE BODY'
		AND OBJECT_NAME = p_TYPE_NAME;

	IF v_HAS_BODY > 0 THEN
		WRITE_IT('TYPE BODY');
  	END IF;

	DBMS_LOB.CLOSE(p_FILE);

EXCEPTION
	WHEN OTHERS THEN
        IF DBMS_LOB.ISOPEN(p_FILE)<>0 THEN
	        DBMS_LOB.CLOSE(p_FILE);
        END IF;
		DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		RAISE;
END ADD_SOURCE;
---------------------------------------------------------------------------------------------------
PROCEDURE GENERATE
(
	p_OID IN NUMBER,
	p_TYPE_NAME IN VARCHAR2,
	p_FILE IN OUT NOCOPY CLOB,
	p_COMPLETED IN OUT NOCOPY OID_TBL
) AS

CURSOR c_DEPENDS IS
SELECT D.REFERENCED_NAME, O.OBJECT_ID
FROM USER_DEPENDENCIES D, USER_OBJECTS O
WHERE D.name = p_TYPE_NAME
	AND D.TYPE IN ('TYPE', 'TYPE BODY')
	AND D.REFERENCED_TYPE IN ('TYPE', 'TYPE BODY')
	AND D.REFERENCED_NAME != D.name
	AND O.OBJECT_NAME = D.REFERENCED_NAME
	AND O.OBJECT_TYPE = 'TYPE';

BEGIN

	-- OBJECT ALREADY EXISTS, SKIP IT
	IF p_COMPLETED.EXISTS(p_OID) THEN
		RETURN;
	END IF;

	-- ADD DEPENDENCIES FIRST
	FOR v_DEPENDS IN c_DEPENDS LOOP
		GENERATE(v_DEPENDS.OBJECT_ID, v_DEPENDS.REFERENCED_NAME, p_FILE, p_COMPLETED);
	END LOOP;

	ADD_SOURCE(p_TYPE_NAME, p_FILE);
	p_COMPLETED(p_OID) := 1;

END GENERATE;
---------------------------------------------------------------------------------------------------
FUNCTION EXPORT_TYPES RETURN CLOB
 AS

CURSOR c_TYPES IS
SELECT T.OBJECT_NAME, T.OBJECT_ID
FROM USER_OBJECTS T
WHERE T.OBJECT_TYPE = 'TYPE';

v_TYPE c_TYPES%ROWTYPE;
v_COMPLETED OID_TBL;
v_RET CLOB;

BEGIN

	v_COMPLETED.DELETE();

	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);

	FOR v_TYPE IN c_TYPES LOOP
		GENERATE(v_TYPE.OBJECT_ID, v_TYPE.OBJECT_NAME, v_RET, v_COMPLETED);
	END LOOP;

	RETURN v_RET;

EXCEPTION
	WHEN OTHERS THEN
		IF v_RET IS NOT NULL THEN
			IF DBMS_LOB.ISOPEN(v_RET)<>0 THEN
				DBMS_LOB.CLOSE(v_RET);
			END IF;
			DBMS_LOB.FREETEMPORARY(v_RET);
		END IF;
		DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		RAISE;
END EXPORT_TYPES;
---------------------------------------------------------------------------------------------------
FUNCTION BUILD_JOIN_CLAUSE
	(
	p_COL_NAME IN VARCHAR2,
	p_VALUE IN VARCHAR2
	) RETURN VARCHAR2 IS

	v_CLAUSE VARCHAR2(500);
BEGIN

	IF UPPER(p_VALUE) IN (CONSTANTS.LITERAL_NULL, CONSTANTS.LITERAL_EMTPY_STRING) THEN
		v_CLAUSE := p_COL_NAME || ' IS NULL';
	ELSE
		v_CLAUSE := p_COL_NAME || ' = ' || p_VALUE;
	END IF;

	RETURN v_CLAUSE;
END BUILD_JOIN_CLAUSE;
---------------------------------------------------------------------------------------------------
FUNCTION ALLOW_DATE_RANGE_GAPS
	(
	p_TABLE_NAME IN VARCHAR2
	) RETURN BOOLEAN IS
v_VAL VARCHAR2(512);
BEGIN
	v_VAL := GET_DICTIONARY_VALUE(p_TABLE_NAME, 0, 'System', 'Temporal Data', 'Allow Date Range Gaps');
	IF v_VAL IS NULL THEN
		-- fall back to a default value if table name is not present in the dictionary
		v_VAL := GET_DICTIONARY_VALUE('%', 0, 'System', 'Temporal Data', 'Allow Date Range Gaps');
	END IF;
	-- allowed values for *false* are '0', 'n'|'no', and 'f'|'false'
	RETURN UPPER(SUBSTR(NVL(v_VAL,'Y'),1,1)) NOT IN ('0','N','F');
END ALLOW_DATE_RANGE_GAPS;
---------------------------------------------------------------------------------------------------
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
	) AS
v_KEY_COLUMNS STRING_MAP;
BEGIN
	IF p_COL_NAME1 IS NOT NULL THEN
		v_KEY_COLUMNS(p_COL_NAME1) := p_COL_VALUE1;
	END IF;
	IF p_COL_NAME2 IS NOT NULL THEN
		v_KEY_COLUMNS(p_COL_NAME2) := p_COL_VALUE2;
	END IF;
	IF p_COL_NAME3 IS NOT NULL THEN
		v_KEY_COLUMNS(p_COL_NAME3) := p_COL_VALUE3;
	END IF;
	IF p_COL_NAME4 IS NOT NULL THEN
		v_KEY_COLUMNS(p_COL_NAME4) := p_COL_VALUE4;
	END IF;
	IF p_COL_NAME5 IS NOT NULL THEN
		v_KEY_COLUMNS(p_COL_NAME5) := p_COL_VALUE5;
	END IF;

	ALIGN_DATE_RANGES(p_TABLE_NAME, v_KEY_COLUMNS, p_BEGIN_DATE_NAME, p_END_DATE_NAME,
						p_INTERVAL, p_WEEK_BEGIN);
END ALIGN_DATE_RANGES;
---------------------------------------------------------------------------------------------------
PROCEDURE ALIGN_DATE_RANGES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_KEY_COLUMNS IN STRING_MAP,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	) AS
v_INITIAL BOOLEAN := TRUE;
v_SQL VARCHAR2(32767);
v_DML VARCHAR2(32767);
v_WHERE VARCHAR2(32767) := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS);
v_END_DATE DATE;
c_CURSOR GA.REFCURSOR;
v_REC_BEGIN_DATE DATE;
v_REC_END_DATE DATE;
v_ALLOW_GAPS BOOLEAN := ALLOW_DATE_RANGE_GAPS(p_TABLE_NAME);
BEGIN
	-- construct the query
	v_SQL :=  'SELECT '||p_BEGIN_DATE_NAME||' AS BEGIN_DATE, '
					   ||p_END_DATE_NAME||' AS END_DATE '
				||' FROM '||p_TABLE_NAME;
	IF v_WHERE IS NOT NULL THEN
		v_SQL := v_SQL||' WHERE '||v_WHERE;
	END IF;
	v_SQL := v_SQL||' ORDER BY BEGIN_DATE DESC';

	-- loop over all date ranges, adjusting end dates so that there are
	-- no gaps between the first begin date and the last end date
	OPEN c_CURSOR FOR v_SQL;
	LOOP
		FETCH c_CURSOR INTO v_REC_BEGIN_DATE, v_REC_END_DATE;
		EXIT WHEN c_CURSOR%NOTFOUND;

		v_REC_END_DATE := NVL(v_REC_END_DATE,CONSTANTS.HIGH_DATE);

		IF v_INITIAL THEN
			v_END_DATE := v_REC_END_DATE;
			v_INITIAL := FALSE;
		END IF;

		IF v_ALLOW_GAPS THEN
			v_END_DATE := LEAST(v_END_DATE, v_REC_END_DATE);
		END IF;

		-- only update if the field needs to change
		IF v_REC_END_DATE <> v_END_DATE THEN
			IF v_END_DATE = CONSTANTS.HIGH_DATE THEN
				v_END_DATE := NULL;
			END IF;

			IF v_DML IS NULL THEN
				-- construct the update statement to adjust the end date
				-- if we haven't already done so (only need to do this once
				-- because the only changes from invocation to invocation are
				-- the bind variables)
				v_DML := 'UPDATE '||p_TABLE_NAME
						||' SET '||p_END_DATE_NAME||' = :1'
						||' WHERE '||p_BEGIN_DATE_NAME||' = :2';
				IF v_WHERE IS NOT NULL THEN
					v_DML := v_DML||' AND '||v_WHERE;
				END IF;

				IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
					LOGS.LOG_DEBUG_DETAIL('Aligning Temporal Data Date Ranges. SQL: '||SUBSTR(v_DML,1,3800));
				END IF;
			END IF;

			-- update the record
   			EXECUTE IMMEDIATE v_DML USING v_END_DATE, v_REC_BEGIN_DATE;
		END IF;

		-- decrement record begin date back to the prior interval
		v_END_DATE := DATE_UTIL.ADVANCE_DATE(v_REC_BEGIN_DATE,p_INTERVAL,p_WEEK_BEGIN,-1);
	END LOOP;
	CLOSE c_CURSOR;
END ALIGN_DATE_RANGES;
---------------------------------------------------------------------------------------------------
PROCEDURE ALIGN_DATES_BY_SECOND
	(
	p_TABLE_NAME IN VARCHAR2,
	p_KEY_COLUMNS IN STRING_MAP,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
	) AS
v_INITIAL BOOLEAN := TRUE;
v_SQL VARCHAR2(32767);
v_DML VARCHAR2(32767);
v_WHERE VARCHAR2(32767) := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS);
v_END_DATE DATE;
c_CURSOR GA.REFCURSOR;
v_REC_BEGIN_DATE DATE;
v_REC_END_DATE DATE;
v_SECOND NUMBER;
BEGIN
 -- initialize constant
 v_SECOND := 1/86400;
	-- construct the query
	v_SQL :=  'SELECT '||p_BEGIN_DATE_NAME||' AS BEGIN_DATE, '
					   ||p_END_DATE_NAME||' AS END_DATE '
				||' FROM '||p_TABLE_NAME;
	IF v_WHERE IS NOT NULL THEN
		v_SQL := v_SQL||' WHERE '||v_WHERE;
	END IF;
	v_SQL := v_SQL||' ORDER BY BEGIN_DATE DESC';
  

	-- loop over all date ranges, adjusting end dates so that there are
	-- no gaps between the first begin date and the last end date
	OPEN c_CURSOR FOR v_SQL;
	LOOP
		FETCH c_CURSOR INTO v_REC_BEGIN_DATE, v_REC_END_DATE;
		EXIT WHEN c_CURSOR%NOTFOUND;

		v_REC_END_DATE := NVL(v_REC_END_DATE,CONSTANTS.HIGH_DATE);

		IF v_INITIAL THEN
			v_END_DATE := v_REC_END_DATE;
			v_INITIAL := FALSE;
		END IF;

		-- only update if the field needs to change
		IF v_REC_END_DATE <> v_END_DATE THEN
			IF v_END_DATE = CONSTANTS.HIGH_DATE THEN
				v_END_DATE := NULL;
			END IF;
      
      IF v_END_DATE > v_REC_END_DATE THEN
        v_END_DATE := v_REC_END_DATE;
      END IF;

			IF v_DML IS NULL THEN
				-- construct the update statement to adjust the end date
				-- if we haven't already done so (only need to do this once
				-- because the only changes from invocation to invocation are
				-- the bind variables)
				v_DML := 'UPDATE '||p_TABLE_NAME
						||' SET '||p_END_DATE_NAME||' = :1'
						||' WHERE '||p_BEGIN_DATE_NAME||' = :2';
				IF v_WHERE IS NOT NULL THEN
					v_DML := v_DML||' AND '||v_WHERE;
				END IF;

				IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
					LOGS.LOG_DEBUG_DETAIL('Aligning Temporal Data Date Ranges. SQL: '||SUBSTR(v_DML,1,3800));
				END IF;
			END IF;

			-- update the record
   			EXECUTE IMMEDIATE v_DML USING v_END_DATE, v_REC_BEGIN_DATE;
        v_DML := NULL;
		END IF;

		-- decrement record begin date back to the prior interval
		v_END_DATE := v_REC_BEGIN_DATE - v_SECOND;
	END LOOP;
	CLOSE c_CURSOR;
END ALIGN_DATES_BY_SECOND;
---------------------------------------------------------------------------------------------------
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
	) AS
v_KEY_COLUMNS STRING_COLLECTION := STRING_COLLECTION();
BEGIN
	IF p_COL_NAME1 IS NOT NULL THEN
		v_KEY_COLUMNS.EXTEND;
		v_KEY_COLUMNS(v_KEY_COLUMNS.LAST) := p_COL_NAME1;
	END IF;
	IF p_COL_NAME2 IS NOT NULL THEN
		v_KEY_COLUMNS.EXTEND;
		v_KEY_COLUMNS(v_KEY_COLUMNS.LAST) := p_COL_NAME2;
	END IF;
	IF p_COL_NAME3 IS NOT NULL THEN
		v_KEY_COLUMNS.EXTEND;
		v_KEY_COLUMNS(v_KEY_COLUMNS.LAST) := p_COL_NAME3;
	END IF;
	IF p_COL_NAME4 IS NOT NULL THEN
		v_KEY_COLUMNS.EXTEND;
		v_KEY_COLUMNS(v_KEY_COLUMNS.LAST) := p_COL_NAME4;
	END IF;
	IF p_COL_NAME5 IS NOT NULL THEN
		v_KEY_COLUMNS.EXTEND;
		v_KEY_COLUMNS(v_KEY_COLUMNS.LAST) := p_COL_NAME5;
	END IF;

	ALIGN_ALL_DATE_RANGES(p_TABLE_NAME, v_KEY_COLUMNS, p_BEGIN_DATE_NAME, p_END_DATE_NAME,
							p_INTERVAL, p_WEEK_BEGIN);
END ALIGN_ALL_DATE_RANGES;
---------------------------------------------------------------------------------------------------
PROCEDURE ALIGN_ALL_DATE_RANGES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_KEY_COLUMNS IN STRING_COLLECTION,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE',
	p_INTERVAL IN VARCHAR2 := 'Day',
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	) AS
v_KEY_TYPES STRING_MAP;
v_SQL VARCHAR2(32767);
v_FIRST BOOLEAN;
v_KEY_VALS STRING_COLLECTION;
v_KEYS STRING_MAP;
v_IDX BINARY_INTEGER;
c_CURSOR GA.REFCURSOR;
BEGIN
	IF p_KEY_COLUMNS.COUNT = 0 THEN
		ALIGN_DATE_RANGES(p_TABLE_NAME, c_EMPTY_MAP, p_BEGIN_DATE_NAME, p_END_DATE_NAME);
	ELSE
    	-- Get the types of the key columns. This will be used so we know what
    	-- form of GET_LITERAL_FOR_* to call to translate values into PL/SQL literals
    	FOR v_COL IN (SELECT C.COLUMN_NAME,
    						CASE WHEN C.DATA_TYPE LIKE '%CHAR%' THEN 'STRING' ELSE C.DATA_TYPE END as DATA_TYPE
    				  FROM TABLE(CAST(p_KEY_COLUMNS AS STRING_COLLECTION)) K,
    				  		USER_TAB_COLS C
    				  WHERE C.TABLE_NAME = p_TABLE_NAME
    				  	AND C.COLUMN_NAME = K.COLUMN_VALUE) LOOP
    		v_KEY_TYPES(v_COL.COLUMN_NAME) := v_COL.DATA_TYPE;
    	END LOOP;

    	-- query for distinct sets of key values
    	v_SQL := 'SELECT STRING_COLLECTION(';
		v_FIRST := TRUE;
		v_IDX := p_KEY_COLUMNS.FIRST;
		WHILE p_KEY_COLUMNS.EXISTS(v_IDX) LOOP
			IF v_FIRST THEN
				v_FIRST := FALSE;
			ELSE
				v_SQL := v_SQL||',';
			END IF;
			v_SQL := v_SQL||' UT.GET_LITERAL_FOR_'||v_KEY_TYPES(p_KEY_COLUMNS(v_IDX))||'('||p_KEY_COLUMNS(v_IDX)||')';
			v_IDX := p_KEY_COLUMNS.NEXT(v_IDX);
		END LOOP;
		v_SQL := v_SQL||') FROM (SELECT DISTINCT ';
		v_FIRST := TRUE;
		v_IDX := p_KEY_COLUMNS.FIRST;
		WHILE p_KEY_COLUMNS.EXISTS(v_IDX) LOOP
			IF v_FIRST THEN
				v_FIRST := FALSE;
			ELSE
				v_SQL := v_SQL||',';
			END IF;
			v_SQL := v_SQL||p_KEY_COLUMNS(v_IDX);
			v_IDX := p_KEY_COLUMNS.NEXT(v_IDX);
		END LOOP;
		v_SQL := v_SQL||' FROM '||p_TABLE_NAME||')';

		OPEN c_CURSOR FOR v_SQL;
		-- for each distinct key set, align the date ranges
		LOOP
			FETCH c_CURSOR INTO v_KEY_VALS;
			EXIT WHEN c_CURSOR%NOTFOUND;

			v_KEYS.DELETE;
    		v_IDX := p_KEY_COLUMNS.FIRST;
    		WHILE p_KEY_COLUMNS.EXISTS(v_IDX) LOOP
				-- build map of column names to PL/SQL literal values
				v_KEYS(p_KEY_COLUMNS(v_IDX)) := v_KEY_VALS(v_IDX);
    			v_IDX := p_KEY_COLUMNS.NEXT(v_IDX);
    		END LOOP;

			ALIGN_DATE_RANGES(p_TABLE_NAME, v_KEYS, p_BEGIN_DATE_NAME, p_END_DATE_NAME, p_INTERVAL, p_WEEK_BEGIN);
		END LOOP;
		CLOSE c_CURSOR;
	END IF;
END ALIGN_ALL_DATE_RANGES;
---------------------------------------------------------------------------------------------------
FUNCTION COMBINE_LISTS(p_L1 IN VARCHAR2, p_L2 IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
	-- use delimiter if/when both sets have names
	IF p_L1 IS NOT NULL AND p_L2 IS NOT NULL THEN
		RETURN p_L1||', '||p_L2;
	ELSIF p_L2 IS NOT NULL THEN
		RETURN p_L2;
	ELSE
		RETURN p_L1;
	END IF;
END COMBINE_LISTS;

---------------------------------------------------------------------------------------------------

PROCEDURE CONTRACT_DATE_RANGE
(
    p_TABLE_NAME        IN VARCHAR2,
    p_BEGIN_DATE        IN DATE,
    p_END_DATE          IN DATE,
    p_UPDATE_ENTRY_DATE IN BOOLEAN,
    p_KEY_COLUMNS       IN STRING_MAP,
    p_DATA_COLUMNS      IN STRING_MAP,
    p_TABLE_ID_NAME     IN VARCHAR2 := NULL,
    p_TABLE_ID_SEQUENCE IN VARCHAR2 := NULL,
    p_BEGIN_DATE_NAME   IN VARCHAR2 := 'BEGIN_DATE',
    p_END_DATE_NAME     IN VARCHAR2 := 'END_DATE'
)  
AS    
    v_SQL            VARCHAR2(32767);
    v_WHERE_KEY_COLS VARCHAR2(32767) := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS);
    v_WHERE          VARCHAR2(32767);
    v_NAMES          VARCHAR2(32767);
    v_VALS           VARCHAR2(32767);

BEGIN

    -- DELETE intersecting rows with same data
    
    v_SQL := 'DELETE FROM ' ||p_TABLE_NAME || ' 
               WHERE NVL(' || p_END_DATE_NAME || ', :HIGH_DATE) >= :SYNC_BEGIN_DATE 
                 AND ' || p_BEGIN_DATE_NAME || ' <= :SYNC_END_DATE ';
                               	
    IF v_WHERE_KEY_COLS IS NOT NULL THEN
        v_SQL := v_SQL||' AND '|| v_WHERE_KEY_COLS;
    END IF;
    
    v_WHERE := MAP_TO_WHERE_CLAUSE(p_DATA_COLUMNS);
    IF v_WHERE IS NOT NULL THEN
        v_SQL := v_SQL||' AND '||v_WHERE;
    END IF;
    
    IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
        LOGS.LOG_DEBUG_DETAIL('Deleting Temporal Data record. SQL: '||SUBSTR(v_SQL,1,3800));
    END IF;

    BEGIN
        EXECUTE IMMEDIATE v_SQL USING CONSTANTS.HIGH_DATE, p_BEGIN_DATE, NVL(p_END_DATE, CONSTANTS.HIGH_DATE);
    END;
        
    -- INSERT new row IF replacing old rows (with same data) 
    
    IF SQL%ROWCOUNT > 0 THEN      
        
        v_NAMES := COMBINE_LISTS(MAP_TO_INSERT_NAMES(p_KEY_COLUMNS), MAP_TO_INSERT_NAMES(p_DATA_COLUMNS));
        v_VALS := COMBINE_LISTS(MAP_TO_INSERT_VALS(p_KEY_COLUMNS), MAP_TO_INSERT_VALS(p_DATA_COLUMNS));
        
        v_SQL := 'INSERT INTO ' || p_TABLE_NAME || ' ('||p_BEGIN_DATE_NAME||', '||p_END_DATE_NAME;
        IF p_UPDATE_ENTRY_DATE THEN
            v_SQL := v_SQL||', ENTRY_DATE';
        END IF;
        
        -- rows have their own IDs? then we need to insert those values, too
        IF p_TABLE_ID_NAME IS NOT NULL THEN
            v_SQL := v_SQL ||', ' || p_TABLE_ID_NAME;
        END IF;

        -- extract column names
        IF v_NAMES IS NOT NULL AND v_VALS IS NOT NULL THEN
            v_SQL := v_SQL ||', '|| v_NAMES;
        END IF;

        -- rows have their own IDs? use the specified sequence to produce new IDs
        IF p_TABLE_ID_NAME IS NOT NULL THEN
            v_SQL := v_SQL ||', '|| NVL(p_TABLE_ID_SEQUENCE,'OID') || '.NEXTVAL';
        END IF;
        
        -- provide values for insert 
        v_SQL := v_SQL || ') VALUES (:SYNC_BEGIN_DATE, :v_SYNC_END_DATE ';
        IF p_UPDATE_ENTRY_DATE THEN
            v_SQL := v_SQL ||', SYSDATE, ';
        END IF;
        
        IF v_NAMES IS NOT NULL AND v_VALS IS NOT NULL THEN
            v_SQL := v_SQL || v_VALS || ')';
        END IF;
        
        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
            LOGS.LOG_DEBUG_DETAIL('Inserting Temporal Data record. SQL: ' || SUBSTR(v_SQL,1,3800));
        END IF;
        
        EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE, p_END_DATE;    
        
    END IF;
    
END;
---------------------------------------------------------------------------------------------------
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
	) AS
v_KEY_COLUMNS STRING_MAP;
v_DATA_COLUMNS STRING_MAP;
BEGIN
	IF p_COL_NAME1 IS NOT NULL THEN
		IF p_COL_IS_KEY1 THEN
			v_KEY_COLUMNS(p_COL_NAME1) := p_COL_VALUE1;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME1) := p_COL_VALUE1;
		END IF;
	END IF;

	IF p_COL_NAME2 IS NOT NULL THEN
		IF p_COL_IS_KEY2 THEN
			v_KEY_COLUMNS(p_COL_NAME2) := p_COL_VALUE2;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME2) := p_COL_VALUE2;
		END IF;
	END IF;

	IF p_COL_NAME3 IS NOT NULL THEN
		IF p_COL_IS_KEY3 THEN
			v_KEY_COLUMNS(p_COL_NAME3) := p_COL_VALUE3;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME3) := p_COL_VALUE3;
		END IF;
	END IF;

	IF p_COL_NAME4 IS NOT NULL THEN
		IF p_COL_IS_KEY4 THEN
			v_KEY_COLUMNS(p_COL_NAME4) := p_COL_VALUE4;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME4) := p_COL_VALUE4;
		END IF;
	END IF;

	IF p_COL_NAME5 IS NOT NULL THEN
		IF p_COL_IS_KEY5 THEN
			v_KEY_COLUMNS(p_COL_NAME5) := p_COL_VALUE5;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME5) := p_COL_VALUE5;
		END IF;
	END IF;

	PUT_TEMPORAL_DATA(p_TABLE_NAME, p_BEGIN_DATE, p_END_DATE, p_NULL_END_IS_HIGH_DATE, p_UPDATE_ENTRY_DATE,
					v_KEY_COLUMNS, v_DATA_COLUMNS, p_TABLE_ID_NAME, p_TABLE_ID_SEQUENCE,
					p_BEGIN_DATE_NAME, p_END_DATE_NAME, p_INTERVAL, p_WEEK_BEGIN,p_EXTEND_DATE_RANGE);
END PUT_TEMPORAL_DATA;
---------------------------------------------------------------------------------------------------
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
	) AS
v_BEGIN_DATE DATE := p_BEGIN_DATE;
v_END_DATE DATE := p_END_DATE;
v_END_DATE_IS_HIGH_DATE BOOLEAN;
v_INC	NUMBER;
v_SQL VARCHAR2(32767);
v_WHERE_K VARCHAR2(32767) := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS);
v_WHERE VARCHAR2(32767);
v_NAMES VARCHAR2(32767);
v_VALS VARCHAR2(32767);
v_WHOLLY_CONTAINED BOOLEAN := TRUE;
v_CONTAINER_BEGIN_DATE DATE;
v_OL1_BEGIN_DATE DATE;
v_OL1_END_DATE DATE;
v_OL1_FOUND BOOLEAN := TRUE;
v_OL2_BEGIN_DATE DATE;
v_OL2_END_DATE DATE;
v_OL2_FOUND BOOLEAN := TRUE;
BEGIN

    IF NOT p_EXTEND_DATE_RANGE THEN
    
        -- if sync record intersects current date range(s) for same data replace current record(s) with sync record
        -- once the same data record(s) are removed and replaced with the new date range the logic can continue
        -- on in normal fashion adjusting other date ranges accordingly. Once we no longer need to expand date
        -- ranges this procedure should be refactored accordingly

        CONTRACT_DATE_RANGE(p_TABLE_NAME,       
                        p_BEGIN_DATE,       
                        p_END_DATE,         
                        p_UPDATE_ENTRY_DATE,
                        p_KEY_COLUMNS,      
                        p_DATA_COLUMNS,     
                        p_TABLE_ID_NAME,    
                        p_TABLE_ID_SEQUENCE,
                        p_BEGIN_DATE_NAME,  
                        p_END_DATE_NAME);
    END IF;
    
    -- compute the distance from specified end date to subsequent interval
    IF v_END_DATE IS NULL THEN
        v_END_DATE_IS_HIGH_DATE := p_NULL_END_IS_HIGH_DATE;
    ELSE
        v_END_DATE_IS_HIGH_DATE := v_END_DATE = CONSTANTS.HIGH_DATE;
        IF NOT v_END_DATE_IS_HIGH_DATE THEN
            v_INC := DATE_UTIL.ADVANCE_DATE(v_END_DATE,p_INTERVAL,p_WEEK_BEGIN) - v_END_DATE;
        END IF;
    END IF;

    -- if the new row is the same data as an existing row with overlapping date ranges, then
    -- get the new date range (which will merge the overlapping ranges into one large range).
    v_SQL := 'SELECT '||p_BEGIN_DATE_NAME||', '||p_END_DATE_NAME
                ||' FROM '||p_TABLE_NAME
                ||' WHERE :1 BETWEEN '||p_BEGIN_DATE_NAME||' AND NVL('||p_END_DATE_NAME||', :HIGH_DATE)';
    IF v_WHERE_K IS NOT NULL THEN
        v_SQL := v_SQL||' AND '||v_WHERE_K;
    END IF;
    -- we're checking for rows with same data, so put data columns into where clause
    v_WHERE := MAP_TO_WHERE_CLAUSE(p_DATA_COLUMNS);
    IF v_WHERE IS NOT NULL THEN
        v_SQL := v_SQL||' AND '||v_WHERE;
    END IF;

    -- check for earlier overlapping row (one that includes p_BEGIN_DATE)
    IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
        LOGS.LOG_DEBUG_DETAIL('Querying Temporal Data for prior overlapping record. SQL: '||SUBSTR(v_SQL,1,3800));
    END IF;
    BEGIN
        EXECUTE IMMEDIATE v_SQL INTO v_OL1_BEGIN_DATE, v_OL1_END_DATE USING v_BEGIN_DATE, CONSTANTS.HIGH_DATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_OL1_FOUND := FALSE;
    END;

    -- check for later overlapping row (one that includes p_END_DATE)
    IF v_END_DATE IS NULL AND NOT v_END_DATE_IS_HIGH_DATE THEN
        -- no end date specified, but we're *not* treating nulls as high_date?
        -- end date? then just use results from first query
        v_OL2_FOUND := v_OL1_FOUND;
        v_OL2_BEGIN_DATE := v_OL1_BEGIN_DATE;
        v_OL2_END_DATE := v_OL1_END_DATE;
    ELSE
        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
            LOGS.LOG_DEBUG_DETAIL('Querying Temporal Data for subsequent overlapping record. SQL: '||SUBSTR(v_SQL,1,3800));
        END IF;
        BEGIN
            EXECUTE IMMEDIATE v_SQL INTO v_OL2_BEGIN_DATE, v_OL2_END_DATE USING NVL(v_END_DATE,CONSTANTS.HIGH_DATE), CONSTANTS.HIGH_DATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_OL2_FOUND := FALSE;
        END;
    END IF;
    
    -- Otherwise, extend the date range to include the existing rows so as to avoid
    -- inserting rows with adjacent date ranges and identical data.
    IF v_OL1_FOUND THEN
        v_BEGIN_DATE := v_OL1_BEGIN_DATE;
    END IF;
    IF v_OL2_FOUND THEN
        v_END_DATE := v_OL2_END_DATE;
    END IF;

    IF v_END_DATE IS NULL AND NOT p_NULL_END_IS_HIGH_DATE THEN
        -- don't adjust other rows - just insert this one w/ NULL end date and then adjust end date
        -- as needed - which happens to be what the UI behavior is
        PUT_TEMPORAL_DATA_UI(p_TABLE_NAME, v_BEGIN_DATE, v_END_DATE, v_BEGIN_DATE, p_UPDATE_ENTRY_DATE,
                     p_KEY_COLUMNS, p_KEY_COLUMNS, p_DATA_COLUMNS, p_TABLE_ID_NAME, p_TABLE_ID_SEQUENCE,
                     p_BEGIN_DATE_NAME, p_END_DATE_NAME, p_INTERVAL, p_WEEK_BEGIN);
        RETURN;
    END IF;

    -- build list of column names and values - used below
    v_NAMES := COMBINE_LISTS(MAP_TO_INSERT_NAMES(p_KEY_COLUMNS), MAP_TO_INSERT_NAMES(p_DATA_COLUMNS));
    v_VALS := COMBINE_LISTS(MAP_TO_INSERT_VALS(p_KEY_COLUMNS), MAP_TO_INSERT_VALS(p_DATA_COLUMNS));

    IF NOT v_END_DATE_IS_HIGH_DATE THEN
        -- Is this new record is wholly contained in the date range of an existing row?

        -- build the query to determine this
        v_SQL := 'SELECT '||p_BEGIN_DATE_NAME
                    ||' FROM '||p_TABLE_NAME
                    ||' WHERE '||p_BEGIN_DATE_NAME||'< :1 AND NVL('||p_END_DATE_NAME||',:HIGH_DATE) > :2';
        IF v_WHERE_K IS NOT NULL THEN
            v_SQL := v_SQL||' AND '||v_WHERE_K;
        END IF;

        -- query!
        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
            LOGS.LOG_DEBUG_DETAIL('Querying Temporal Data to see if new record is wholly contained in existing record. SQL: '||SUBSTR(v_SQL,1,3800));
        END IF;

        BEGIN
            EXECUTE IMMEDIATE v_SQL INTO v_CONTAINER_BEGIN_DATE USING v_BEGIN_DATE, CONSTANTS.HIGH_DATE, v_END_DATE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_WHOLLY_CONTAINED := FALSE;
        END;
    ELSE
        -- can't be wholly contained in another record if we go all the way to HIGH_DATE
        v_WHOLLY_CONTAINED := FALSE;
    END IF;

    IF v_WHOLLY_CONTAINED THEN
        -- split the existing record by adding an additional record with the same values that extends
        -- from new row's end date + 1 through the existing record's end date

        -- build the statement to insert the record
        v_SQL := 'INSERT INTO '||p_TABLE_NAME||' ('||p_BEGIN_DATE_NAME||', '||p_END_DATE_NAME;
        IF p_UPDATE_ENTRY_DATE THEN
            v_SQL := v_SQL||', ENTRY_DATE';
        END IF;
        -- rows have their own IDs? then we need to insert those values, too
        IF p_TABLE_ID_NAME IS NOT NULL THEN
            v_SQL := v_SQL||', '||p_TABLE_ID_NAME;
        END IF;

        -- extract column names
        IF v_NAMES IS NOT NULL THEN
            v_SQL := v_SQL||', '||v_NAMES;
        END IF;

        v_SQL := v_SQL||') SELECT :1, '||p_END_DATE_NAME;
        IF p_UPDATE_ENTRY_DATE THEN
            v_SQL := v_SQL||', ENTRY_DATE';
        END IF;
        -- rows have their own IDs? use the specified sequence to produce new IDs
        IF p_TABLE_ID_NAME IS NOT NULL THEN
            v_SQL := v_SQL||', '||NVL(p_TABLE_ID_SEQUENCE,'OID')||'.NEXTVAL';
        END IF;

        -- extract column names
        IF v_NAMES IS NOT NULL THEN
            v_SQL := v_SQL||', '||v_NAMES;
        END IF;

        v_SQL := v_SQL||' FROM '||p_TABLE_NAME
                        ||' WHERE '||p_BEGIN_DATE_NAME||' = :2';
        IF v_WHERE_K IS NOT NULL THEN
            v_SQL := v_SQL||' AND '||v_WHERE_K;
        END IF;

        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
            LOGS.LOG_DEBUG_DETAIL('Splitting Temporal Data record. SQL: '||SUBSTR(v_SQL,1,3800));
        END IF;
        EXECUTE IMMEDIATE v_SQL USING v_END_DATE+v_INC, v_CONTAINER_BEGIN_DATE;
    ELSE
        -- build the statement to delete rows wholly contained in this new row's date range
        v_SQL := 'DELETE FROM '||p_TABLE_NAME;

        v_SQL := v_SQL||' WHERE '||p_BEGIN_DATE_NAME||' >= :1 AND NVL('||p_END_DATE_NAME||',:HIGH_DATE) <= :2';
        IF v_WHERE_K IS NOT NULL THEN
            v_SQL := v_SQL||' AND '||v_WHERE_K;
        END IF;

        -- delete!
        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
            LOGS.LOG_DEBUG_DETAIL('Deleting Temporal Data records wholly within/overwritten by new record. SQL: '||SUBSTR(v_SQL,1,3800));
        END IF;
        EXECUTE IMMEDIATE v_SQL USING v_BEGIN_DATE, CONSTANTS.HIGH_DATE, NVL(v_END_DATE, CONSTANTS.HIGH_DATE);

        -- if new record's end date is HIGH_DATE then there can be no trailing row,
        -- but if it's not HIGH_DATE, then ...
        IF NOT v_END_DATE_IS_HIGH_DATE THEN
            -- build the statement to update the trailing, overlapping row's begin date
            -- to be beyond the new row's end date
            v_SQL := 'UPDATE '||p_TABLE_NAME||' T1'
                        ||' SET '||p_BEGIN_DATE_NAME||' = :1';

            -- correlated sub-query to find the trailing, overlapping row
            v_SQL := v_SQL||' WHERE '||p_BEGIN_DATE_NAME||' = (SELECT MIN(T2.'||p_BEGIN_DATE_NAME||')'
                                                            ||' FROM '||p_TABLE_NAME||' T2'
                                                            ||' WHERE T2.'||p_BEGIN_DATE_NAME||' BETWEEN :2 AND :3';
            v_WHERE := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS, 'T2');
            IF v_WHERE IS NOT NULL THEN
                v_SQL := v_SQL||' AND '||v_WHERE;
            END IF;
            v_SQL := v_SQL||')'; -- end sub-query
            -- now finish the update's WHERE clause
            IF v_WHERE_K IS NOT NULL THEN
                v_SQL := v_SQL||' AND '||v_WHERE_K;
            END IF;

            -- update!
            IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
                LOGS.LOG_DEBUG_DETAIL('Updating Temporal Data record so subsequent record has correct begin date. SQL: '||SUBSTR(v_SQL,1,3800));
            END IF;
            EXECUTE IMMEDIATE v_SQL USING v_END_DATE+v_INC, v_BEGIN_DATE, v_END_DATE;
        END IF;
    END IF;

    -- build the statement to insert the new record
    v_SQL := 'INSERT INTO '||p_TABLE_NAME||' (BEGIN_DATE, END_DATE';
    IF p_UPDATE_ENTRY_DATE THEN
        v_SQL := v_SQL||', ENTRY_DATE';
    END IF;
    -- rows have their own IDs? then we need to insert that value, too
    IF p_TABLE_ID_NAME IS NOT NULL THEN
        v_SQL := v_SQL||', '||p_TABLE_ID_NAME;
    END IF;

    -- extract column names
    IF v_NAMES IS NOT NULL THEN
        v_SQL := v_SQL||', '||v_NAMES;
    END IF;

    v_SQL := v_SQL||') VALUES (:1, :2';
    IF p_UPDATE_ENTRY_DATE THEN
        v_SQL := v_SQL||', SYSDATE';
    END IF;
    -- rows have their own IDs? use the specified sequence to produce new ID
    IF p_TABLE_ID_NAME IS NOT NULL THEN
        v_SQL := v_SQL||', '||NVL(p_TABLE_ID_SEQUENCE,'OID')||'.NEXTVAL';
    END IF;

    -- extract column values
    IF v_NAMES IS NOT NULL THEN
        v_SQL := v_SQL||', '||v_VALS;
    END IF;

    v_SQL := v_SQL||')';

    IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
        LOGS.LOG_DEBUG_DETAIL('Inserting Temporal Data. SQL: '||SUBSTR(v_SQL,1,3800));
    END IF;
    EXECUTE IMMEDIATE v_SQL USING v_BEGIN_DATE, v_END_DATE;
   

	ALIGN_DATE_RANGES(p_TABLE_NAME, p_KEY_COLUMNS, p_BEGIN_DATE_NAME, p_END_DATE_NAME, p_INTERVAL, p_WEEK_BEGIN);
END PUT_TEMPORAL_DATA;
---------------------------------------------------------------------------------------------------
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
	) AS
v_KEY_COLUMNS_NEW STRING_MAP;
v_KEY_COLUMNS_OLD STRING_MAP;
v_DATA_COLUMNS STRING_MAP;
BEGIN
	IF p_COL_NAME1 IS NOT NULL THEN
		IF p_COL_IS_KEY1 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME1) := p_COL_NEW_VALUE1;
			v_KEY_COLUMNS_OLD(p_COL_NAME1) := p_COL_OLD_VALUE1;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME1) := p_COL_NEW_VALUE1;
		END IF;
	END IF;

	IF p_COL_NAME2 IS NOT NULL THEN
		IF p_COL_IS_KEY2 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME2) := p_COL_NEW_VALUE2;
			v_KEY_COLUMNS_OLD(p_COL_NAME2) := p_COL_OLD_VALUE2;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME2) := p_COL_NEW_VALUE2;
		END IF;
	END IF;

	IF p_COL_NAME3 IS NOT NULL THEN
		IF p_COL_IS_KEY3 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME3) := p_COL_NEW_VALUE3;
			v_KEY_COLUMNS_OLD(p_COL_NAME3) := p_COL_OLD_VALUE3;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME3) := p_COL_NEW_VALUE3;
		END IF;
	END IF;

	IF p_COL_NAME4 IS NOT NULL THEN
		IF p_COL_IS_KEY4 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME4) := p_COL_NEW_VALUE4;
			v_KEY_COLUMNS_OLD(p_COL_NAME4) := p_COL_OLD_VALUE4;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME4) := p_COL_NEW_VALUE4;
		END IF;
	END IF;

	IF p_COL_NAME5 IS NOT NULL THEN
		IF p_COL_IS_KEY5 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME5) := p_COL_NEW_VALUE5;
			v_KEY_COLUMNS_OLD(p_COL_NAME5) := p_COL_OLD_VALUE5;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME5) := p_COL_NEW_VALUE5;
		END IF;
	END IF;

	PUT_TEMPORAL_DATA_UI(p_TABLE_NAME, p_BEGIN_DATE, p_END_DATE, p_OLD_BEGIN_DATE, p_UPDATE_ENTRY_DATE,
						 v_KEY_COLUMNS_NEW, v_KEY_COLUMNS_OLD, v_DATA_COLUMNS,
						 p_TABLE_ID_NAME, p_TABLE_ID_SEQUENCE,
						 p_BEGIN_DATE_NAME, p_END_DATE_NAME, p_INTERVAL, p_WEEK_BEGIN);
END PUT_TEMPORAL_DATA_UI;
---------------------------------------------------------------------------------------------------
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
	) AS
v_SQL VARCHAR2(32767);
v_TEMP VARCHAR2(32767);
v_COL_NAME VARCHAR2(32);
v_KEY_CHANGED BOOLEAN := FALSE;
BEGIN
	-- see if the sets of keys are the same
	v_COL_NAME := p_KEY_COLUMNS_NEW.FIRST;
	WHILE p_KEY_COLUMNS_NEW.EXISTS(v_COL_NAME) LOOP
		IF p_KEY_COLUMNS_OLD(v_COL_NAME) <> p_KEY_COLUMNS_NEW(v_COL_NAME) THEN
			v_KEY_CHANGED := TRUE;
			EXIT;
		END IF;
		v_COL_NAME := p_KEY_COLUMNS_NEW.NEXT(v_COL_NAME);
	END LOOP;

	-- build the update statement
	v_SQL := 'UPDATE '||p_TABLE_NAME
				||' SET '||p_BEGIN_DATE_NAME||' = :1,'
						 ||p_END_DATE_NAME||' = :2';

	IF v_KEY_CHANGED THEN
		-- key values changed? then include them in the SET clause
		v_TEMP := MAP_TO_UPDATE_CLAUSE(p_KEY_COLUMNS_NEW);
		IF v_TEMP IS NOT NULL THEN
			v_SQL := v_SQL||', '||v_TEMP;
		END IF;
	END IF;

	v_TEMP := MAP_TO_UPDATE_CLAUSE(p_DATA_COLUMNS);
	IF v_TEMP IS NOT NULL THEN
		v_SQL := v_SQL||', '||v_TEMP;
	END IF;

	IF p_UPDATE_ENTRY_DATE THEN
		v_SQL := v_SQL||', ENTRY_DATE = SYSDATE';
	END IF;

	v_SQL := v_SQL||' WHERE '||p_BEGIN_DATE_NAME||' = :3';
	v_TEMP := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS_OLD);
	IF v_TEMP IS NOT NULL THEN
		v_SQL := v_SQL||' AND '||v_TEMP;
	END IF;

	-- update!
	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Updating Temporal Data. SQL: '||SUBSTR(v_SQL,1,3800));
	END IF;
	EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE, p_END_DATE, p_OLD_BEGIN_DATE;

	-- no row to update? then perform an insert
	IF SQL%NOTFOUND THEN
		-- build the insert statement
		v_SQL := 'INSERT INTO '||p_TABLE_NAME||' (BEGIN_DATE, END_DATE';
		IF p_UPDATE_ENTRY_DATE THEN
			v_SQL := v_SQL||', ENTRY_DATE';
		END IF;
		-- rows have their own IDs? then we need to insert that value, too
		IF p_TABLE_ID_NAME IS NOT NULL THEN
			v_SQL := v_SQL||', '||p_TABLE_ID_NAME;
		END IF;

		-- extract column names
		v_TEMP := COMBINE_LISTS(MAP_TO_INSERT_NAMES(p_KEY_COLUMNS_NEW), MAP_TO_INSERT_NAMES(p_DATA_COLUMNS));
		IF v_TEMP IS NOT NULL THEN
			v_SQL := v_SQL||', '||v_TEMP;
		END IF;

		v_SQL := v_SQL||') VALUES (:1, :2';
		IF p_UPDATE_ENTRY_DATE THEN
			v_SQL := v_SQL||', SYSDATE';
		END IF;
		-- rows have their own IDs? use the specified sequence to produce new ID
		IF p_TABLE_ID_NAME IS NOT NULL THEN
			v_SQL := v_SQL||', '||NVL(p_TABLE_ID_SEQUENCE,'OID')||'.NEXTVAL';
		END IF;

		v_TEMP := COMBINE_LISTS(MAP_TO_INSERT_VALS(p_KEY_COLUMNS_NEW), MAP_TO_INSERT_VALS(p_DATA_COLUMNS));
		IF v_TEMP IS NOT NULL THEN
			v_SQL := v_SQL||', '||v_TEMP;
		END IF;

		v_SQL := v_SQL||')';

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Inserting Temporal Data. SQL: '||SUBSTR(v_SQL,1,3800));
		END IF;
		EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE, p_END_DATE;
	END IF;

	IF v_KEY_CHANGED THEN
		-- must re-align dates for old keys if the key values changed
		ALIGN_DATE_RANGES(p_TABLE_NAME, p_KEY_COLUMNS_OLD, p_BEGIN_DATE_NAME, p_END_DATE_NAME, p_INTERVAL, p_WEEK_BEGIN);
	END IF;
	ALIGN_DATE_RANGES(p_TABLE_NAME, p_KEY_COLUMNS_NEW, p_BEGIN_DATE_NAME, p_END_DATE_NAME, p_INTERVAL, p_WEEK_BEGIN);
END PUT_TEMPORAL_DATA_UI;
---------------------------------------------------------------------------------------------------
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
	) AS
v_KEY_COLUMNS_NEW STRING_MAP;
v_KEY_COLUMNS_OLD STRING_MAP;
v_DATA_COLUMNS STRING_MAP;
BEGIN
	IF p_COL_NAME1 IS NOT NULL THEN
		IF p_COL_IS_KEY1 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME1) := p_COL_NEW_VALUE1;
			v_KEY_COLUMNS_OLD(p_COL_NAME1) := p_COL_OLD_VALUE1;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME1) := p_COL_NEW_VALUE1;
		END IF;
	END IF;

	IF p_COL_NAME2 IS NOT NULL THEN
		IF p_COL_IS_KEY2 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME2) := p_COL_NEW_VALUE2;
			v_KEY_COLUMNS_OLD(p_COL_NAME2) := p_COL_OLD_VALUE2;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME2) := p_COL_NEW_VALUE2;
		END IF;
	END IF;

	IF p_COL_NAME3 IS NOT NULL THEN
		IF p_COL_IS_KEY3 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME3) := p_COL_NEW_VALUE3;
			v_KEY_COLUMNS_OLD(p_COL_NAME3) := p_COL_OLD_VALUE3;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME3) := p_COL_NEW_VALUE3;
		END IF;
	END IF;

	IF p_COL_NAME4 IS NOT NULL THEN
		IF p_COL_IS_KEY4 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME4) := p_COL_NEW_VALUE4;
			v_KEY_COLUMNS_OLD(p_COL_NAME4) := p_COL_OLD_VALUE4;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME4) := p_COL_NEW_VALUE4;
		END IF;
	END IF;

	IF p_COL_NAME5 IS NOT NULL THEN
		IF p_COL_IS_KEY5 THEN
			v_KEY_COLUMNS_NEW(p_COL_NAME5) := p_COL_NEW_VALUE5;
			v_KEY_COLUMNS_OLD(p_COL_NAME5) := p_COL_OLD_VALUE5;
		ELSE
			v_DATA_COLUMNS(p_COL_NAME5) := p_COL_NEW_VALUE5;
		END IF;
	END IF;

	PUT_TEMPORAL_DATA_UI_SUBDAY(p_TABLE_NAME, p_BEGIN_DATE, p_END_DATE, p_OLD_BEGIN_DATE, p_UPDATE_ENTRY_DATE,
						 v_KEY_COLUMNS_NEW, v_KEY_COLUMNS_OLD, v_DATA_COLUMNS,
						 p_TABLE_ID_NAME, p_TABLE_ID_SEQUENCE,
						 P_BEGIN_DATE_NAME, P_END_DATE_NAME, P_INTERVAL, P_WEEK_BEGIN);
END PUT_TEMPORAL_DATA_UI_SUBDAY;
----------------------------------------------------------------------------------
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
	p_WEEK_BEGIN IN VARCHAR2 := NULL
	) AS
v_SQL VARCHAR2(32767);
v_TEMP VARCHAR2(32767);
v_COL_NAME VARCHAR2(32);
v_KEY_CHANGED BOOLEAN := FALSE;
BEGIN

    IF p_BEGIN_DATE >= p_END_DATE THEN
        ERRS.RAISE_BAD_DATE_RANGE(p_BEGIN_DATE, p_END_DATE);
    END IF;
	-- see if the sets of keys are the same
	v_COL_NAME := p_KEY_COLUMNS_NEW.FIRST;
	WHILE p_KEY_COLUMNS_NEW.EXISTS(v_COL_NAME) LOOP
		IF p_KEY_COLUMNS_OLD(v_COL_NAME) <> p_KEY_COLUMNS_NEW(v_COL_NAME) THEN
			v_KEY_CHANGED := TRUE;
			EXIT;
		END IF;
		v_COL_NAME := p_KEY_COLUMNS_NEW.NEXT(v_COL_NAME);
	END LOOP;

	-- build the update statement
	v_SQL := 'UPDATE '||p_TABLE_NAME
				||' SET '||p_BEGIN_DATE_NAME||' = :1,'
						 ||p_END_DATE_NAME||' = :2';

	IF v_KEY_CHANGED THEN
		-- key values changed? then include them in the SET clause
		v_TEMP := MAP_TO_UPDATE_CLAUSE(p_KEY_COLUMNS_NEW);
		IF v_TEMP IS NOT NULL THEN
			v_SQL := v_SQL||', '||v_TEMP;
		END IF;
	END IF;

	v_TEMP := MAP_TO_UPDATE_CLAUSE(p_DATA_COLUMNS);
	IF v_TEMP IS NOT NULL THEN
		v_SQL := v_SQL||', '||v_TEMP;
	END IF;

	IF p_UPDATE_ENTRY_DATE THEN
		v_SQL := v_SQL||', ENTRY_DATE = SYSDATE';
	END IF;

	v_SQL := v_SQL||' WHERE '||p_BEGIN_DATE_NAME||' = :3';
	v_TEMP := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS_OLD);
	IF v_TEMP IS NOT NULL THEN
		v_SQL := v_SQL||' AND '||v_TEMP;
	END IF;

	-- update!
	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Updating Temporal Data. SQL: '||SUBSTR(v_SQL,1,3800));
	END IF;
	EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE + 1/86400, p_END_DATE, p_OLD_BEGIN_DATE;  -- must add a second when updating to be consistant with insert

	-- no row to update? then perform an insert
	IF SQL%NOTFOUND THEN
		-- build the insert statement
		v_SQL := 'INSERT INTO '||p_TABLE_NAME||' (BEGIN_DATE, END_DATE';
		IF p_UPDATE_ENTRY_DATE THEN
			v_SQL := v_SQL||', ENTRY_DATE';
		END IF;
		-- rows have their own IDs? then we need to insert that value, too
		IF p_TABLE_ID_NAME IS NOT NULL THEN
			v_SQL := v_SQL||', '||p_TABLE_ID_NAME;
		END IF;

		-- extract column names
		v_TEMP := COMBINE_LISTS(MAP_TO_INSERT_NAMES(p_KEY_COLUMNS_NEW), MAP_TO_INSERT_NAMES(p_DATA_COLUMNS));
		IF v_TEMP IS NOT NULL THEN
			v_SQL := v_SQL||', '||v_TEMP;
		END IF;

		v_SQL := v_SQL||') VALUES (:1, :2';
		IF p_UPDATE_ENTRY_DATE THEN
			v_SQL := v_SQL||', SYSDATE';
		END IF;
		-- rows have their own IDs? use the specified sequence to produce new ID
		IF p_TABLE_ID_NAME IS NOT NULL THEN
			v_SQL := v_SQL||', '||NVL(p_TABLE_ID_SEQUENCE,'OID')||'.NEXTVAL';
		END IF;

		v_TEMP := COMBINE_LISTS(MAP_TO_INSERT_VALS(p_KEY_COLUMNS_NEW), MAP_TO_INSERT_VALS(p_DATA_COLUMNS));
		IF v_TEMP IS NOT NULL THEN
			v_SQL := v_SQL||', '||v_TEMP;
		END IF;

		v_SQL := v_SQL||')';

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Inserting Temporal Data. SQL: '||SUBSTR(v_SQL,1,3800));
		END IF;
		EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE + 1/86400, p_END_DATE; -- Store + 1 second for correct calculation
	END IF;

  IF v_KEY_CHANGED THEN
		-- must re-align dates for old keys if the key values changed
		ALIGN_DATES_BY_SECOND(p_TABLE_NAME, p_KEY_COLUMNS_OLD, p_BEGIN_DATE_NAME, p_END_DATE_NAME);
	END IF;
	ALIGN_DATES_BY_SECOND(p_TABLE_NAME, p_KEY_COLUMNS_NEW, p_BEGIN_DATE_NAME, p_END_DATE_NAME);
  
END PUT_TEMPORAL_DATA_UI_SUBDAY;
---------------------------------------------------------------------------------------------------
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
	) AS

v_KEY_COLUMNS STRING_MAP;

BEGIN
	IF p_KEY_COL_NAME1 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME1) := p_KEY_COL_VALUE1;
	END IF;

	IF p_KEY_COL_NAME2 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME2) := p_KEY_COL_VALUE2;
	END IF;

    IF p_KEY_COL_NAME3 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME3) := p_KEY_COL_VALUE3;
	END IF;

    IF p_KEY_COL_NAME4 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME4) := p_KEY_COL_VALUE4;
	END IF;

    IF p_KEY_COL_NAME5 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME5) := p_KEY_COL_VALUE5;
	END IF;

	COPY_TEMPORAL_DATA(p_TABLE_NAME,p_SRC_BEGIN_DATE,p_SRC_END_DATE,v_KEY_COLUMNS,p_TGT_BEGIN_DATE,p_TGT_END_DATE,p_BEGIN_DATE_NAME,p_END_DATE_NAME);
END COPY_TEMPORAL_DATA;
---------------------------------------------------------------------------------------------------
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
    ) AS

    v_SQL VARCHAR2(32767);
    v_WHERE_K VARCHAR2(32767) := MAP_TO_WHERE_CLAUSE(p_SRC_KEY_COLUMNS);

    v_COLUMN_LIST VARCHAR2(32767);

    v_TEST PLS_INTEGER;

BEGIN

    -- TEST TO MAKE SURE THIS DATE RANGE IS CLEAR
    v_SQL := 'SELECT 1 FROM ' || p_TABLE_NAME || ' WHERE ' || p_BEGIN_DATE_NAME ||
                '<= :2 AND NVL(' || p_END_DATE_NAME || ',HIGH_DATE) >= :1';

    IF v_WHERE_K IS NOT NULL THEN
        v_SQL := v_SQL||' AND '||v_WHERE_K;
    END IF;

    IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
        LOGS.LOG_DEBUG_DETAIL('Testing to make sure Temporal Data is clear for copying. SQL: '||SUBSTR(v_SQL,1,3800));
    END IF;

    BEGIN
        EXECUTE IMMEDIATE v_SQL INTO v_TEST USING p_TGT_BEGIN_DATE, p_TGT_END_DATE;

        ERRS.RAISE_BAD_DATE_RANGE(p_TGT_BEGIN_DATE, p_TGT_END_DATE,
            'Cannot copy data into the target date range supplied in the table ' || p_TABLE_NAME ||
            '.  Data already exists for this date range.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL; -- EXPECTED, MEANS NO DATA IS IN THE TARGET DATE RANGE
    END;

    FOR v_REC IN (SELECT UTC.COLUMN_NAME
                    FROM USER_TAB_COLS UTC
                    WHERE UTC.TABLE_NAME = p_TABLE_NAME
                        AND UTC.COLUMN_NAME NOT IN (p_BEGIN_DATE_NAME, p_END_DATE_NAME)) LOOP
        v_COLUMN_LIST := v_COLUMN_LIST || v_REC.COLUMN_NAME || ', ';
    END LOOP;

    v_SQL := 'INSERT INTO ' || p_TABLE_NAME || '(' || v_COLUMN_LIST || p_BEGIN_DATE_NAME
        || ', ' || p_END_DATE_NAME || ') SELECT ' || v_COLUMN_LIST || ' :1, :2 FROM ' || p_TABLE_NAME
        || ' WHERE ' || p_BEGIN_DATE_NAME || ' = :3 AND ' || p_END_DATE_NAME || ' = :4';

    IF v_WHERE_K IS NOT NULL THEN
        v_SQL := v_SQL||' AND '||v_WHERE_K;
    END IF;

    IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
        LOGS.LOG_DEBUG_DETAIL('Copying Temporal Data. SQL: '||SUBSTR(v_SQL,1,3800));
    END IF;

    EXECUTE IMMEDIATE v_SQL USING p_TGT_BEGIN_DATE, p_TGT_END_DATE, p_SRC_BEGIN_DATE, p_SRC_END_DATE;

END COPY_TEMPORAL_DATA;
---------------------------------------------------------------------------------------------------
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
	) AS

v_KEY_COLUMNS STRING_MAP;

BEGIN
	IF p_KEY_COL_NAME1 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME1) := p_KEY_COL_VALUE1;
	END IF;

	IF p_KEY_COL_NAME2 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME2) := p_KEY_COL_VALUE2;
	END IF;

    IF p_KEY_COL_NAME3 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME3) := p_KEY_COL_VALUE3;
	END IF;

    IF p_KEY_COL_NAME4 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME4) := p_KEY_COL_VALUE4;
	END IF;

    IF p_KEY_COL_NAME5 IS NOT NULL THEN
		v_KEY_COLUMNS(p_KEY_COL_NAME5) := p_KEY_COL_VALUE5;
	END IF;

	DELETE_TEMPORAL_DATA(p_TABLE_NAME,p_BEGIN_DATE,p_END_DATE,v_KEY_COLUMNS,p_BEGIN_DATE_NAME,p_END_DATE_NAME);
END DELETE_TEMPORAL_DATA;
---------------------------------------------------------------------------------------------------
PROCEDURE DELETE_TEMPORAL_DATA
    (
	p_TABLE_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_KEY_COLUMNS IN STRING_MAP,
	p_BEGIN_DATE_NAME IN VARCHAR2 := 'BEGIN_DATE',
	p_END_DATE_NAME IN VARCHAR2 := 'END_DATE'
    ) AS

    v_SQL VARCHAR2(32767);
    v_WHERE_K VARCHAR2(32767) := MAP_TO_WHERE_CLAUSE(p_KEY_COLUMNS);

    v_END_DATE DATE := NVL(p_END_DATE, CONSTANTS.HIGH_DATE);

    v_WHOLLY_CONTAINED BOOLEAN;
    v_CONTAINING_BEGIN DATE;
    v_CONTAINING_END DATE;

BEGIN

    -- LOOK TO SEE IF WE'RE WHOLLY CONTAINED IN ANOTHER RECORD
    IF v_END_DATE <> CONSTANTS.HIGH_DATE THEN
        v_SQL := 'SELECT ' || p_BEGIN_DATE_NAME || ', ' || p_END_DATE_NAME
            || ' FROM ' || p_TABLE_NAME || ' WHERE ' || p_BEGIN_DATE_NAME || ' < :1 AND NVL( '
            || p_END_DATE_NAME || ',HIGH_DATE) > :2';

        IF v_WHERE_K IS NOT NULL THEN
            v_SQL := v_SQL||' AND '||v_WHERE_K;
        END IF;

        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		    LOGS.LOG_DEBUG_DETAIL('Querying Temporal Data -- containing date range. SQL: '||SUBSTR(v_SQL,1,3800));
	    END IF;

        BEGIN
			EXECUTE IMMEDIATE v_SQL INTO v_CONTAINING_BEGIN, v_CONTAINING_END USING p_BEGIN_DATE, v_END_DATE;

            v_WHOLLY_CONTAINED := TRUE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_WHOLLY_CONTAINED := FALSE;
		END;
    END IF;

    IF v_WHOLLY_CONTAINED THEN
       -- FIRST, UPDATE THE CONTAINING DATE RANGE TO CREATE THE BEFORE RECORD, THEN WE'LL COPY IT INTO THE AFTER RECORD
       v_SQL := 'UPDATE ' || p_TABLE_NAME || ' SET ' || p_END_DATE_NAME || ' = :1 WHERE ' || p_BEGIN_DATE_NAME || ' < :2'
            || ' AND NVL(' || p_END_DATE_NAME || ', HIGH_DATE) > :3';

       IF v_WHERE_K IS NOT NULL THEN
            v_SQL := v_SQL||' AND '||v_WHERE_K;
        END IF;

        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
            LOGS.LOG_DEBUG_DETAIL('Updating Temporal Data -- wholly containing date range, truncating to before. SQL: '||SUBSTR(v_SQL,1,3800));
        END IF;

        EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE - 1,
                                        p_BEGIN_DATE, v_END_DATE;


        -- NOW, COPY THIS RECORD INTO THE AFTER DATE RANGE
        COPY_TEMPORAL_DATA(p_TABLE_NAME, v_CONTAINING_BEGIN, p_BEGIN_DATE-1, p_KEY_COLUMNS, p_END_DATE+1,
            v_CONTAINING_END, p_BEGIN_DATE_NAME, p_END_DATE_NAME);
    ELSE
        -- OTHERWISE, TRUNCATE RECORDS EXTENDING INTO THIS DATE RANGE AND DELETE ANY CONTAINED WITHIN IT
        -- FIRST, UPDATE ANY RECORDS WHICH OVERLAP THIS DATE RANGE ON THE BEGINNING
        v_SQL := 'UPDATE ' || p_TABLE_NAME || ' SET ' || p_END_DATE_NAME || ' = :1 WHERE ' || p_BEGIN_DATE_NAME || ' < :2'
            || ' AND NVL(' || p_END_DATE_NAME || ', HIGH_DATE) <= :3';

        IF v_WHERE_K IS NOT NULL THEN
            v_SQL := v_SQL||' AND '||v_WHERE_K;
        END IF;

        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
            LOGS.LOG_DEBUG_DETAIL('Updating Temporal Data -- overlapping on begin date. SQL: '||SUBSTR(v_SQL,1,3800));
        END IF;

        EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE - 1,
                                        p_BEGIN_DATE, v_END_DATE;

        IF p_END_DATE IS NOT NULL THEN -- DON'T BOTH IF END_DATE = HIGH_DATE
            -- NEXT, UPDATE ANY RECORDS WHICH  OVERLAP THIS DATE RANGE ON THE END
            v_SQL := 'UPDATE ' || p_TABLE_NAME || ' SET ' || p_BEGIN_DATE_NAME || ' = :1 WHERE ' || p_BEGIN_DATE_NAME
                || ' >= :2' || ' AND NVL(' || p_END_DATE_NAME || ', HIGH_DATE) > :3';

            IF v_WHERE_K IS NOT NULL THEN
                v_SQL := v_SQL||' AND '||v_WHERE_K;
            END IF;

            IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
                LOGS.LOG_DEBUG_DETAIL('Updating Temporal Data -- overlapping on end date. SQL: '||SUBSTR(v_SQL,1,3800));
            END IF;
            EXECUTE IMMEDIATE v_SQL USING p_END_DATE + 1,
                                            p_BEGIN_DATE, p_END_DATE;
        END IF;

        -- FINALLY, DELETE ANY RECORDS WHICH ARE WHOLLY CONTAINED WITHIN THE GIVEN DATE RANGE
        v_SQL := 'DELETE FROM ' || p_TABLE_NAME || ' WHERE ' || p_BEGIN_DATE_NAME || ' >= :1 AND NVL(' || p_END_DATE_NAME || ', HIGH_DATE)'
            || ' <= :2';

        IF v_WHERE_K IS NOT NULL THEN
            v_SQL := v_SQL||' AND '||v_WHERE_K;
        END IF;

        IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
                LOGS.LOG_DEBUG_DETAIL('Updating Temporal Data -- deleting contained date ranges. SQL: '||SUBSTR(v_SQL,1,3800));
        END IF;
        EXECUTE IMMEDIATE v_SQL USING p_BEGIN_DATE, v_END_DATE;
    END IF;


END DELETE_TEMPORAL_DATA;
---------------------------------------------------------------------------------------------------
-- Get full error message that includes error stack trace
FUNCTION GET_FULL_ERRM RETURN VARCHAR2
IS
BEGIN
	RETURN SQLERRM || UTL_TCP.CRLF || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END GET_FULL_ERRM;
---------------------------------------------------------------------------------------------------
-- Get a message definition based on the specified message code
PROCEDURE GET_MESSAGE_DEFINITION
	(
	p_MESSAGE_CODE IN VARCHAR2,
	p_MSG_DEF OUT MSG_DEF
	) AS
v_POS		PLS_INTEGER;
v_MSG_TYPE	MESSAGE_DEFINITION.MESSAGE_TYPE%TYPE;
v_MSG_NUM	MESSAGE_DEFINITION.MESSAGE_NUMBER%TYPE;
BEGIN
	IF g_MSG_DEF_CACHE.EXISTS(p_MESSAGE_CODE) THEN
		p_MSG_DEF := g_MSG_DEF_CACHE(p_MESSAGE_CODE);
		RETURN; -- got it!
	ELSE
		v_POS := INSTR(p_MESSAGE_CODE, '-');
		IF v_POS-1 <= 6 THEN -- longer than six is not a valid message type
			BEGIN
				v_MSG_TYPE := SUBSTR(p_MESSAGE_CODE,1,v_POS-1);
				-- When testing, this throws VALUE_ERROR if string is invalid in
				-- PL/SQL context. Changing to SQL context (i.e. using SELECT INTO
				-- instead of PL/SQL assignment) causes it to throw INVALID_NUMBER.
				-- Just in case, we'll catch both below - so if Oracle changes things
				-- to make the two cases consistent, we'll still be covered
				v_MSG_NUM := TO_NUMBER(SUBSTR(p_MESSAGE_CODE,v_POS+1), 'FM00009');

				IF (v_MSG_TYPE <> 'ORA') OR (v_MSG_TYPE = 'ORA' AND v_MSG_NUM BETWEEN 20000 AND 29999) THEN
					SELECT MESSAGE_ID, MESSAGE_TYPE, MESSAGE_NUMBER, MESSAGE_TEXT
					INTO p_MSG_DEF
					FROM MESSAGE_DEFINITION
					WHERE MESSAGE_TYPE = v_MSG_TYPE
						AND MESSAGE_NUMBER = v_MSG_NUM;

					g_MSG_DEF_CACHE(p_MESSAGE_CODE) := p_MSG_DEF;
					RETURN; -- got it!
				END IF;

			EXCEPTION
				WHEN INVALID_NUMBER THEN
					ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
					-- deal with it in the next section - default output to NULL
				WHEN VALUE_ERROR THEN
					ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
					-- deal with it in the next section - default output to NULL
				WHEN NO_DATA_FOUND THEN
					ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
					-- deal with it in the next section - default output to NULL
			END;
		END IF;
	END IF;

	-- haven't returned yet? then there is no such message definition.
	-- set everything to NULL
	p_MSG_DEF.MESSAGE_ID := NULL;
	p_MSG_DEF.MESSAGE_TYPE := NULL;
	p_MSG_DEF.MESSAGE_NUMBER := NULL;
	p_MSG_DEF.MESSAGE_TEXT := NULL;

END GET_MESSAGE_DEFINITION;
---------------------------------------------------------------------------------------------------
FUNCTION BOOLEAN_FROM_STRING
	(
	p_STRING IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	RETURN UPPER(SUBSTR(p_STRING,1,1)) NOT IN ('0','N','F');
END BOOLEAN_FROM_STRING;
---------------------------------------------------------------------------------------------------
FUNCTION NUMBER_FROM_BOOLEAN
	(
	p_BOOL IN BOOLEAN
	) RETURN NUMBER IS
BEGIN
	RETURN CASE WHEN p_BOOL THEN 1 ELSE 0 END;
END NUMBER_FROM_BOOLEAN;
---------------------------------------------------------------------------------------------------
FUNCTION BOOLEAN_FROM_NUMBER
	(
	p_NUM IN NUMBER
	) RETURN BOOLEAN IS
BEGIN
	RETURN NVL(p_NUM,0) <> 0;
END BOOLEAN_FROM_NUMBER;
---------------------------------------------------------------------------------------------------
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
	) RETURN CLOB IS
v_RET CLOB;
v_ID_COLUMNS STRING_COLLECTION := STRING_COLLECTION();
v_DOMAINS STRING_COLLECTION := STRING_COLLECTION();
v_CONSTRAINT_COLS STRING_COLLECTION;
v_COLUMNS STRING_COLLECTION := STRING_COLLECTION();
v_COLUMN_TYPES STRING_MAP;
v_UNEDITABLE_KEYS STRING_COLLECTION;
v_SUB_TAB_NAME VARCHAR2(64);
v_CONSTRAINT_NAME VARCHAR2(30);
v_IDX PLS_INTEGER;
v_TYPE VARCHAR2(16);
v_FIRST BOOLEAN;
v_PREFIX VARCHAR2(8);

	-- GET_DOMAIN_ALIAS expects either the domain id or the table and column names
	-- (in which case it will be determined dynamically)
	FUNCTION GET_DOMAIN_ALIAS
		(
		p_TABLE_NAME IN VARCHAR2,
		p_COLUMN_NAME IN VARCHAR2,
		p_DOMAIN_ID IN NUMBER
		) RETURN VARCHAR2 IS
	v_RET ENTITY_DOMAIN.ENTITY_DOMAIN_TABLE_ALIAS%TYPE;
	v_DOMAIN_ID NUMBER(9);
	BEGIN
		IF p_DOMAIN_ID IS NOT NULL THEN
			BEGIN
				SELECT ENTITY_DOMAIN_TABLE_ALIAS
				INTO v_RET
				FROM ENTITY_DOMAIN
				WHERE ENTITY_DOMAIN_ID = p_DOMAIN_ID;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'Entity_Domain with Entity_Domain_Id = ' || p_DOMAIN_ID);
			END;
		ELSE
			v_DOMAIN_ID := ENTITY_UTIL.GET_REFERRED_DOMAIN_ID(p_COLUMN_NAME, p_TABLE_NAME);

			IF v_DOMAIN_ID IS NOT NULL THEN
				SELECT ENTITY_DOMAIN_TABLE_ALIAS
				INTO v_RET
				FROM ENTITY_DOMAIN
				WHERE ENTITY_DOMAIN_ID = v_DOMAIN_ID;
			END IF;
		END IF;

		RETURN v_RET;
	END GET_DOMAIN_ALIAS;

	PROCEDURE PUT(p_TEXT IN VARCHAR2 := NULL, p_NEWLINE IN BOOLEAN := TRUE) AS
	v_TEXT VARCHAR2(32767) := CASE WHEN p_NEWLINE THEN p_TEXT||UTL_TCP.CRLF ELSE p_TEXT END;
	BEGIN
		IF v_TEXT IS NULL THEN
			RETURN;
		END IF;
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_TEXT), v_TEXT);
	END PUT;

	PROCEDURE PUT_SEP IS
	BEGIN
		FOR v_I IN 1..80 LOOP
			PUT('-',FALSE);
		END LOOP;
		PUT;
	END PUT_SEP;

	FUNCTION IS_IN(p_COL IN VARCHAR2, p_COLLECTION IN STRING_COLLECTION) RETURN BOOLEAN IS
		v_JDX PLS_INTEGER;
	BEGIN
		v_JDX := p_COLLECTION.FIRST;
		WHILE p_COLLECTION.EXISTS(v_JDX) LOOP
			IF p_COLLECTION(v_JDX) = p_COL THEN
				RETURN TRUE;
			END IF;
			v_JDX := p_COLLECTION.NEXT(v_JDX);
		END LOOP;
		RETURN FALSE;
	END IS_IN;

BEGIN
	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
	DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);

	-- Some analysis first:

	-- Sub-tab name
	IF p_SUB_TAB_NAME IS NULL THEN
		v_SUB_TAB_NAME := p_TABLE_NAME;
		DBMS_OUTPUT.PUT_LINE('Using '||v_SUB_TAB_NAME||' as sub-tab name');
	ELSE
		v_SUB_TAB_NAME := p_SUB_TAB_NAME;
	END IF;

	-- Constraint name
	IF p_CONSTRAINT_NAME IS NULL THEN
		-- find the right constraint
		BEGIN
			SELECT A.INDEX_NAME
			INTO v_CONSTRAINT_NAME
			FROM USER_IND_COLUMNS A, USER_INDEXES B
			WHERE B.TABLE_NAME = p_TABLE_NAME
				AND B.UNIQUENESS = 'UNIQUE'
				AND A.INDEX_NAME = B.INDEX_NAME
				AND (A.COLUMN_NAME = p_BEGIN_DATE_NAME OR p_BEGIN_DATE_NAME IS NULL)
				AND (A.COLUMN_NAME <> p_TABLE_ID_NAME OR p_TABLE_ID_NAME IS NULL)
				AND ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				ERRS.RAISE(MSGCODES.c_ERR_GENERAL,'Specified table does not appear to have a suitable unique index');
		END;
		DBMS_OUTPUT.PUT_LINE('Using constraint '||v_CONSTRAINT_NAME);
	ELSE
		v_CONSTRAINT_NAME := p_CONSTRAINT_NAME;
	END IF;

	-- TODO use ERRS api in generated code

	-- Security info
	IF p_MODULE_NAME IS NULL THEN
		-- require at least one ID - we'll have to determine what it is based on first column of constraint
		IF p_ENTITY_ID_COL1 IS NULL THEN
			v_ID_COLUMNS.EXTEND;
			BEGIN
				SELECT COLUMN_NAME
				INTO v_ID_COLUMNS(v_ID_COLUMNS.LAST)
				FROM USER_IND_COLUMNS
				WHERE TABLE_NAME = p_TABLE_NAME
					AND INDEX_NAME = v_CONSTRAINT_NAME
					AND COLUMN_POSITION = (SELECT MIN(COLUMN_POSITION)
										   FROM USER_IND_COLUMNS
										   WHERE TABLE_NAME = p_TABLE_NAME
												AND INDEX_NAME = v_CONSTRAINT_NAME
												AND COLUMN_NAME LIKE '%_ID');
				v_DOMAINS.EXTEND;
				v_DOMAINS(v_DOMAINS.LAST) := GET_DOMAIN_ALIAS(p_TABLE_NAME, v_ID_COLUMNS(v_ID_COLUMNS.LAST), p_ENTITY_DOMAIN_ID1);
				DBMS_OUTPUT.PUT_LINE('Using '||v_ID_COLUMNS(v_ID_COLUMNS.LAST)||' as entity ID for table');
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'USER_INDEX_COLUMN with INDEX_NAME = "' || v_CONSTRAINT_NAME || '" and TABLE_NAME = "' || p_TABLE_NAME || '"');
			END;
		ELSE
			-- build list of columns based on input parameters
			v_ID_COLUMNS.EXTEND;
			v_ID_COLUMNS(v_ID_COLUMNS.LAST) := p_ENTITY_ID_COL1;
			v_DOMAINS.EXTEND;
			v_DOMAINS(v_DOMAINS.LAST) := GET_DOMAIN_ALIAS(p_TABLE_NAME, p_ENTITY_ID_COL1, p_ENTITY_DOMAIN_ID1);
			IF p_ENTITY_ID_COL2 IS NOT NULL THEN
				v_ID_COLUMNS.EXTEND;
				v_ID_COLUMNS(v_ID_COLUMNS.LAST) := p_ENTITY_ID_COL2;
				v_DOMAINS.EXTEND;
				v_DOMAINS(v_DOMAINS.LAST) := GET_DOMAIN_ALIAS(p_TABLE_NAME, p_ENTITY_ID_COL2, p_ENTITY_DOMAIN_ID2);
				IF p_ENTITY_ID_COL3 IS NOT NULL THEN
					v_ID_COLUMNS.EXTEND;
					v_ID_COLUMNS(v_ID_COLUMNS.LAST) := p_ENTITY_ID_COL3;
					v_DOMAINS.EXTEND;
					v_DOMAINS(v_DOMAINS.LAST) := GET_DOMAIN_ALIAS(p_TABLE_NAME, p_ENTITY_ID_COL3, p_ENTITY_DOMAIN_ID3);
					IF p_ENTITY_ID_COL4 IS NOT NULL THEN
						v_ID_COLUMNS.EXTEND;
						v_ID_COLUMNS(v_ID_COLUMNS.LAST) := p_ENTITY_ID_COL4;
						v_DOMAINS.EXTEND;
						v_DOMAINS(v_DOMAINS.LAST) := GET_DOMAIN_ALIAS(p_TABLE_NAME, p_ENTITY_ID_COL4, p_ENTITY_DOMAIN_ID4);
					END IF;
				END IF;
			END IF;
		END IF;
		DBMS_OUTPUT.PUT_LINE('Using data-level security with '||v_ID_COLUMNS.COUNT||' columns');
	ELSE
		DBMS_OUTPUT.PUT_LINE('Using module-level security instead of data-level security');
	END IF;

	-- determine set of un-modifiable keys
	IF p_UNEDITABLE_KEYS IS NULL THEN
		v_UNEDITABLE_KEYS := STRING_COLLECTION();
		IF v_ID_COLUMNS.COUNT > 0 THEN
			DBMS_OUTPUT.PUT_LINE('Assuming '||v_ID_COLUMNS(v_ID_COLUMNS.FIRST)||' cannot be modified from PUT procedure');
			v_UNEDITABLE_KEYS.EXTEND;
			v_UNEDITABLE_KEYS(v_UNEDITABLE_KEYS.LAST) := v_ID_COLUMNS(v_ID_COLUMNS.FIRST);
		ELSE
			DBMS_OUTPUT.PUT_LINE('Assuming all key columns can be modified from PUT procedure');
		END IF;
	ELSE
		v_UNEDITABLE_KEYS := p_UNEDITABLE_KEYS;
	END IF;

	-- Get constraint columns
	SELECT COLUMN_NAME
	BULK COLLECT INTO v_CONSTRAINT_COLS
	FROM USER_IND_COLUMNS
	WHERE TABLE_NAME = p_TABLE_NAME
		AND INDEX_NAME = v_CONSTRAINT_NAME
	ORDER BY COLUMN_POSITION;

	-- and other columns, too
	FOR v_REC IN (SELECT COLUMN_NAME, DATA_TYPE
					FROM USER_TAB_COLS
						WHERE TABLE_NAME = p_TABLE_NAME
						ORDER BY COLUMN_ID) LOOP
		v_COLUMNS.EXTEND;
		v_COLUMNS(v_COLUMNS.LAST) := v_REC.COLUMN_NAME;
		v_COLUMN_TYPES(v_REC.COLUMN_NAME) := v_REC.DATA_TYPE;
	END LOOP;

---------- NOW WRITE SOME CODE: First the GET procedure
	DBMS_OUTPUT.PUT_LINE('Generating code for EM.'||v_SUB_TAB_NAME||'S');

	PUT_SEP;
	PUT('-'||'- Put this procedure in the EM package');
	PUT_SEP;
	PUT('PROCEDURE '||v_SUB_TAB_NAME||'S');
	PUT('    (');
	-- in parameters
	v_IDX := v_UNEDITABLE_KEYS.FIRST;
	WHILE v_UNEDITABLE_KEYS.EXISTS(v_IDX) LOOP
		PUT('    p_'||v_UNEDITABLE_KEYS(v_IDX)||' IN '||v_COLUMN_TYPES(v_UNEDITABLE_KEYS(v_IDX))||',');
		v_IDX := v_UNEDITABLE_KEYS.NEXT(v_IDX);
	END LOOP;
	PUT('    p_CURSOR OUT GA.REFCURSOR');
	PUT('    ) AS');
	PUT('BEGIN');
	-- security
	IF p_MODULE_NAME IS NULL THEN
		IF v_ID_COLUMNS.COUNT > 0 THEN
			PUT('-'||'- Data-Level Security');
			PUT('    SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT, p_'||v_ID_COLUMNS(v_ID_COLUMNS.FIRST)||', EC.ED_'||v_DOMAINS(v_ID_COLUMNS.FIRST)||');');
		END IF;
	ELSE
		PUT('    IF NOT CAN_READ('''||p_MODULE_NAME||''') THEN');
		PUT('        ERRS.RAISE_NO_READ_MODULE('''||p_MODULE_NAME||''');');
		PUT('    END IF;');
	END IF;
	PUT;
	PUT('    OPEN p_CURSOR FOR');
	PUT('        SELECT ', FALSE);
	v_FIRST := TRUE;
	v_IDX := v_COLUMNS.FIRST;
	WHILE v_COLUMNS.EXISTS(v_IDX) LOOP
		IF NOT v_FIRST THEN
			PUT(','); PUT('            ',FALSE);
		ELSE
			v_FIRST := FALSE;
		END IF;
		PUT(v_COLUMNS(v_IDX), FALSE);
		v_IDX := v_COLUMNS.NEXT(v_IDX);
	END LOOP;
	PUT;
	PUT('        FROM '||p_TABLE_NAME);
	PUT('        WHERE ', FALSE);
	v_FIRST := TRUE;
	v_IDX := v_UNEDITABLE_KEYS.FIRST;
	WHILE v_UNEDITABLE_KEYS.EXISTS(v_IDX) LOOP
		IF NOT v_FIRST THEN
			PUT('            AND ', FALSE);
		ELSE
			v_FIRST := FALSE;
		END IF;
		PUT(v_UNEDITABLE_KEYS(v_IDX)||' = p_'||v_UNEDITABLE_KEYS(v_IDX));
		v_IDX := v_UNEDITABLE_KEYS.NEXT(v_IDX);
	END LOOP;
	PUT('        ORDER BY ', FALSE);
	v_FIRST := TRUE;
	v_IDX := v_CONSTRAINT_COLS.FIRST;
	WHILE v_CONSTRAINT_COLS.EXISTS(v_IDX) LOOP
		IF NOT IS_IN(v_CONSTRAINT_COLS(v_IDX), v_UNEDITABLE_KEYS) THEN
			IF NOT v_FIRST THEN
				PUT(','); PUT('            ',FALSE);
			ELSE
				v_FIRST := FALSE;
			END IF;
			PUT(v_CONSTRAINT_COLS(v_IDX), FALSE);
		END IF;
		v_IDX := v_CONSTRAINT_COLS.NEXT(v_IDX);
	END LOOP;
	PUT(';');
	PUT;
	PUT('END '||v_SUB_TAB_NAME||'S;');

---------- WRITE SOME MORE CODE: Now write the PUT procedure
	DBMS_OUTPUT.PUT_LINE('Generating code for EM.PUT_'||v_SUB_TAB_NAME);

	PUT_SEP;
	PUT('-'||'- Put this procedure in the EM package');
	PUT_SEP;
	PUT('PROCEDURE PUT_'||v_SUB_TAB_NAME);
	PUT('    (');
	-- in parameters
	v_FIRST := TRUE;
	v_IDX := v_COLUMNS.FIRST;
	WHILE v_COLUMNS.EXISTS(v_IDX) LOOP
		 -- skip entry date field and, if this is a temporal table, we don't need table's ID value either
		IF v_COLUMNS(v_IDX) <> 'ENTRY_DATE' AND (p_BEGIN_DATE_NAME IS NULL OR
												v_COLUMNS(v_IDX) <> NVL(p_TABLE_ID_NAME,'?')) THEN
			IF NOT v_FIRST THEN
				PUT(',');
			ELSE
				v_FIRST := FALSE;
			END IF;
			PUT('    p_'||v_COLUMNS(v_IDX)||' IN '||v_COLUMN_TYPES(v_COLUMNS(v_IDX)),FALSE);
		END IF;
		v_IDX := v_COLUMNS.NEXT(v_IDX);
	END LOOP;
	-- if we have a table ID value and this is not a temporal table then use the ID for updates
	IF p_TABLE_ID_NAME IS NOT NULL AND p_BEGIN_DATE_NAME IS NULL THEN
			IF NOT v_FIRST THEN
				PUT(',');
			END IF;
			PUT('    p_'||p_TABLE_ID_NAME||' IN '||p_TABLE_ID_NAME);
	-- otherwise, use "old" values of modifiable key columns for updates
	ELSE
		v_IDX := v_CONSTRAINT_COLS.FIRST;
		WHILE v_CONSTRAINT_COLS.EXISTS(v_IDX) LOOP
			IF NOT IS_IN(v_CONSTRAINT_COLS(v_IDX), v_UNEDITABLE_KEYS) THEN
				IF NOT v_FIRST THEN
					PUT(',');
				ELSE
					v_FIRST := FALSE;
				END IF;
				PUT('    p_OLD_'||v_CONSTRAINT_COLS(v_IDX)||' IN '||v_COLUMN_TYPES(v_CONSTRAINT_COLS(v_IDX)),FALSE);
			END IF;
			v_IDX := v_CONSTRAINT_COLS.NEXT(v_IDX);
		END LOOP;
		PUT; -- final newline
	END IF;
	PUT('    ) AS');
	-- temporal data? then declare some structures that we'll need to use
	IF p_BEGIN_DATE_NAME IS NOT NULL THEN
		PUT('v_KEY_NEW UT.STRING_MAP;');
		PUT('v_KEY_OLD UT.STRING_MAP;');
		PUT('v_DATA UT.STRING_MAP;');
	END IF;
	PUT('BEGIN');
	-- security
	IF p_MODULE_NAME IS NULL THEN
		IF v_ID_COLUMNS.COUNT > 0 THEN
			PUT('-'||'- Data-Level Security');
			v_IDX := v_ID_COLUMNS.FIRST;
			WHILE v_ID_COLUMNS.EXISTS(v_IDX) LOOP
				PUT('    SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT, p_'||v_ID_COLUMNS(v_IDX)||', EC.ED_'||v_DOMAINS(v_IDX)||');');
				IF NOT IS_IN(v_ID_COLUMNS(v_IDX), v_UNEDITABLE_KEYS) THEN
					PUT('    SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT, p_OLD_'||v_ID_COLUMNS(v_IDX)||', EC.ED_'||v_DOMAINS(v_IDX)||');');
				END IF;
				v_IDX := v_ID_COLUMNS.NEXT(v_IDX);
			END LOOP;
		END IF;
	ELSE
		PUT('    IF NOT CAN_WRITE('''||p_MODULE_NAME||''') THEN');
		PUT('        ERRS.RAISE_NO_WRITE_MODULE('''||p_MODULE_NAME||''');');
		PUT('    END IF;');
	END IF;
	PUT;
	IF p_BEGIN_DATE_NAME IS NOT NULL THEN
		-- prepare and call UT.PUT_TEMPORAL_DATA_UI
		v_IDX := v_CONSTRAINT_COLS.FIRST;
		WHILE v_CONSTRAINT_COLS.EXISTS(v_IDX) LOOP
			IF v_CONSTRAINT_COLS(v_IDX) NOT IN (p_BEGIN_DATE_NAME, p_END_DATE_NAME, 'ENTRY_DATE', NVL(p_TABLE_ID_NAME,'?')) THEN
				v_TYPE := v_COLUMN_TYPES(v_CONSTRAINT_COLS(v_IDX));
				IF v_TYPE LIKE '%CHAR%' THEN
					v_TYPE := 'STRING';
				END IF;
				PUT('    v_KEY_NEW('||UT.GET_LITERAL_FOR_STRING(v_CONSTRAINT_COLS(v_IDX))||') := UT.GET_LITERAL_FOR_'||v_TYPE||'(p_'||v_CONSTRAINT_COLS(v_IDX)||');');
				IF IS_IN(v_CONSTRAINT_COLS(v_IDX), v_UNEDITABLE_KEYS) THEN
					PUT('    v_KEY_OLD('||UT.GET_LITERAL_FOR_STRING(v_CONSTRAINT_COLS(v_IDX))||') := UT.GET_LITERAL_FOR_'||v_TYPE||'(p_'||v_CONSTRAINT_COLS(v_IDX)||');');
				ELSE
					PUT('    v_KEY_OLD('||UT.GET_LITERAL_FOR_STRING(v_CONSTRAINT_COLS(v_IDX))||') := UT.GET_LITERAL_FOR_'||v_TYPE||'(p_OLD_'||v_CONSTRAINT_COLS(v_IDX)||');');
				END IF;
			END IF;
			v_IDX := v_CONSTRAINT_COLS.NEXT(v_IDX);
		END LOOP;
		v_IDX := v_COLUMNS.FIRST;
		WHILE v_COLUMNS.EXISTS(v_IDX) LOOP
			IF v_COLUMNS(v_IDX) NOT IN (p_BEGIN_DATE_NAME, p_END_DATE_NAME, 'ENTRY_DATE', NVL(p_TABLE_ID_NAME,'?'))
					AND NOT IS_IN(v_COLUMNS(v_IDX), v_CONSTRAINT_COLS) THEN
				v_TYPE := v_COLUMN_TYPES(v_COLUMNS(v_IDX));
				IF v_TYPE LIKE '%CHAR%' THEN
					v_TYPE := 'STRING';
				END IF;
				PUT('    v_DATA('||UT.GET_LITERAL_FOR_STRING(v_COLUMNS(v_IDX))||') := UT.GET_LITERAL_FOR_'||v_TYPE||'(p_'||v_COLUMNS(v_IDX)||');');
			END IF;
			v_IDX := v_COLUMNS.NEXT(v_IDX);
		END LOOP;
		PUT;
		PUT('    UT.PUT_TEMPORAL_DATA_UI('||UT.GET_LITERAL_FOR_STRING(p_TABLE_NAME)||',');
		PUT('                            p_'||p_BEGIN_DATE_NAME||',');
		PUT('                            p_'||p_END_DATE_NAME||',');
		PUT('                            p_OLD_'||p_BEGIN_DATE_NAME||',');
		IF IS_IN('ENTRY_DATE',v_COLUMNS) THEN
			PUT('                            TRUE,');
		ELSE
			PUT('                            FALSE,');
		END IF;
		PUT('                            v_KEY_NEW,');
		PUT('                            v_KEY_OLD,');
		PUT('                            v_DATA,');
		PUT('                            '||UT.GET_LITERAL_FOR_STRING(p_TABLE_ID_NAME)||',');
		PUT('                            '||UT.GET_LITERAL_FOR_STRING(p_TABLE_ID_SEQUENCE)||',');
		PUT('                            '||UT.GET_LITERAL_FOR_STRING(p_BEGIN_DATE_NAME)||',');
		PUT('                            '||UT.GET_LITERAL_FOR_STRING(p_END_DATE_NAME));
		PUT('                            );');
	ELSE
		-- No BEGIN_DATE column means this is not a temporal table, so do simple DML
		NULL;--TODO
		PUT('    UPDATE '||p_TABLE_NAME||' SET');
		v_FIRST := TRUE;
		v_IDX := v_COLUMNS.FIRST;
		WHILE v_COLUMNS.EXISTS(v_IDX) LOOP
			IF NOT IS_IN(v_COLUMNS(v_IDX), v_UNEDITABLE_KEYS) AND v_COLUMNS(v_IDX) <> NVL(p_TABLE_ID_NAME,'?') THEN
				IF NOT v_FIRST THEN
					PUT(',');
				ELSE
					v_FIRST := FALSE;
				END IF;
				IF v_COLUMNS(v_IDX) = 'ENTRY_DATE' THEN
					PUT('        '||v_COLUMNS(v_IDX)||' = SYSDATE',FALSE);
				ELSE
					PUT('        '||v_COLUMNS(v_IDX)||' = p_'||v_COLUMNS(v_IDX),FALSE);
				END IF;
			END IF;
			v_IDX := v_COLUMNS.NEXT(v_IDX);
		END LOOP;
		PUT; -- final newline
		PUT('    WHERE ', FALSE);
		IF p_TABLE_ID_NAME IS NOT NULL THEN
			-- update by ID
			PUT(p_TABLE_ID_NAME||' = p_'||p_TABLE_ID_NAME||';');
		ELSE
			-- update by unique key values
			v_FIRST := TRUE;
			v_IDX := v_CONSTRAINT_COLS.FIRST;
			WHILE v_CONSTRAINT_COLS.EXISTS(v_IDX) LOOP
				IF NOT v_FIRST THEN
					PUT; PUT('        AND ', FALSE);
				ELSE
					v_FIRST := FALSE;
				END IF;
				IF IS_IN(v_CONSTRAINT_COLS(v_IDX), v_UNEDITABLE_KEYS) THEN
					PUT(v_CONSTRAINT_COLS(v_IDX)||' = p_'||v_CONSTRAINT_COLS(v_IDX),FALSE);
				ELSE
					PUT(v_CONSTRAINT_COLS(v_IDX)||' = p_OLD_'||v_CONSTRAINT_COLS(v_IDX),FALSE);
				END IF;
				v_IDX := v_CONSTRAINT_COLS.NEXT(v_IDX);
			END LOOP;
			PUT(';');
		END IF;
		PUT;
		PUT('    IF SQL%NOTFOUND THEN');
		PUT('        INSERT INTO '||p_TABLE_NAME||' (');
		v_FIRST := TRUE;
		v_IDX := v_COLUMNS.FIRST;
		WHILE v_COLUMNS.EXISTS(v_IDX) LOOP
			IF NOT v_FIRST THEN
				PUT(',');
			ELSE
				v_FIRST := FALSE;
			END IF;
			PUT('            '||v_COLUMNS(v_IDX),FALSE);
			v_IDX := v_COLUMNS.NEXT(v_IDX);
		END LOOP;
		PUT(')');
		PUT('        VALUES (');
		v_FIRST := TRUE;
		v_IDX := v_COLUMNS.FIRST;
		WHILE v_COLUMNS.EXISTS(v_IDX) LOOP
			IF NOT v_FIRST THEN
				PUT(',');
			ELSE
				v_FIRST := FALSE;
			END IF;
			IF v_COLUMNS(v_IDX) = 'ENTRY_DATE' THEN
				PUT('            SYSDATE',FALSE);
			ELSIF v_COLUMNS(v_IDX) = NVL(p_TABLE_ID_NAME,'?') THEN
				PUT('            '||NVL(p_TABLE_ID_SEQUENCE,'OID')||'.NEXTVAL',FALSE);
			ELSE
				PUT('            p_'||v_COLUMNS(v_IDX),FALSE);
			END IF;
			v_IDX := v_COLUMNS.NEXT(v_IDX);
		END LOOP;
		PUT(');');
		PUT('    END IF;');
	END IF;
	PUT;
	PUT('END PUT_'||v_SUB_TAB_NAME||';');

---------- WRITE SOME MORE CODE: Finally write the DELETE procedure
	DBMS_OUTPUT.PUT_LINE('Generating code for DX.REMOVE_'||v_SUB_TAB_NAME);

	PUT_SEP;
	PUT('-'||'- Put this procedure in the DX package');
	PUT_SEP;
	PUT('PROCEDURE REMOVE_'||v_SUB_TAB_NAME);
	PUT('    (');
	-- in parameters
	IF p_TABLE_ID_NAME IS NOT NULL THEN
		-- delete by table's ID value
		PUT('    p_'||p_TABLE_ID_NAME||' IN '||v_COLUMN_TYPES(p_TABLE_ID_NAME));
	ELSE
		-- delete by unique key values
		v_FIRST := TRUE;
		v_IDX := v_CONSTRAINT_COLS.FIRST;
		WHILE v_CONSTRAINT_COLS.EXISTS(v_IDX) LOOP
			IF v_CONSTRAINT_COLS(v_IDX) <> 'ENTRY_DATE' THEN -- skip entry date field
				IF NOT v_FIRST THEN
					PUT(',');
				ELSE
					v_FIRST := FALSE;
				END IF;
				PUT('    p_'||v_CONSTRAINT_COLS(v_IDX)||' IN '||v_COLUMN_TYPES(v_CONSTRAINT_COLS(v_IDX)),FALSE);
			END IF;
			v_IDX := v_CONSTRAINT_COLS.NEXT(v_IDX);
		END LOOP;
		PUT; -- final newline
	END IF;
	PUT('    ) AS');
	-- if we are just getting a table ID value and are doing data-level security, we'll need to query some
	-- entity IDs from the table - so define the record we'll use
	IF p_TABLE_ID_NAME IS NOT NULL AND p_MODULE_NAME IS NULL AND v_ID_COLUMNS.COUNT > 0 THEN
		PUT('v_REC '||p_TABLE_NAME||'%ROWTYPE;');
	END IF;
	PUT('BEGIN');
	-- security
	IF p_MODULE_NAME IS NULL THEN
		IF v_ID_COLUMNS.COUNT > 0 THEN
			IF p_TABLE_ID_NAME IS NOT NULL THEN
				v_PREFIX := 'v_REC.';
				PUT('    BEGIN');
				PUT('        SELECT * INTO v_REC');
				PUT('        FROM '||p_TABLE_NAME);
				PUT('        WHERE '||p_TABLE_ID_NAME||' = p_'||p_TABLE_ID_NAME||';');
				PUT('    EXCEPTION');
				PUT('        WHEN NO_DATA_FOUND THEN');
				PUT('            RETURN; -'||'- return successfully since there is nothing to delete');
				PUT('    END;');
				PUT;
			ELSE
				v_PREFIX := 'p_';
			END IF;
			PUT('-'||'- Data-Level Security');
			v_IDX := v_ID_COLUMNS.FIRST;
			WHILE v_ID_COLUMNS.EXISTS(v_IDX) LOOP
				PUT('    SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT, '||v_PREFIX||v_ID_COLUMNS(v_IDX)||', EC.ED_'||v_DOMAINS(v_IDX)||');');
				v_IDX := v_ID_COLUMNS.NEXT(v_IDX);
			END LOOP;
		END IF;
	ELSE
		PUT('    IF NOT CAN_DELETE('''||p_MODULE_NAME||''') THEN');
		PUT('        ERRS.RAISE_NO_DELETE_MODULE('''||p_MODULE_NAME||''');');
		PUT('    END IF;');
	END IF;

	PUT;
	PUT('    DELETE '||p_TABLE_NAME);
	PUT('    WHERE ', FALSE);
	IF p_TABLE_ID_NAME IS NOT NULL THEN
		-- delete by table's ID value
		PUT(p_TABLE_ID_NAME||' = p_'||p_TABLE_ID_NAME||';');
	ELSE
		v_FIRST := TRUE;
		v_IDX := v_CONSTRAINT_COLS.FIRST;
		WHILE v_CONSTRAINT_COLS.EXISTS(v_IDX) LOOP
			IF NOT v_FIRST THEN
				PUT; PUT('        AND ', FALSE);
			ELSE
				v_FIRST := FALSE;
			END IF;
			PUT(v_CONSTRAINT_COLS(v_IDX)||' = p_'||v_CONSTRAINT_COLS(v_IDX),FALSE);
			v_IDX := v_CONSTRAINT_COLS.NEXT(v_IDX);
		END LOOP;
		PUT(';');
	END IF;

	PUT;
	PUT('END REMOVE_'||v_SUB_TAB_NAME||';');
	PUT_SEP;

	-- done
	DBMS_LOB.CLOSE(v_RET);
	RETURN v_RET;
END CREATE_EM_ROUTINES;
---------------------------------------------------------------------------------------------------
FUNCTION GENERATE_MSGCODES RETURN CLOB IS

	v_RET CLOB;

	CURSOR c_MESSAGE_DEFINITIONS IS
		SELECT CASE MESSAGE_TYPE WHEN 'ORA' THEN 0 ELSE 1 END "ORA_ORDER",
			MESSAGE_TYPE,
			MESSAGE_NUMBER,
			MESSAGE_IDENT
		FROM MESSAGE_DEFINITION
		ORDER BY 1,2,3;

	v_PREV_TYPE MESSAGE_DEFINITION.MESSAGE_TYPE%TYPE := 'DUMMY';

	PROCEDURE APPEND(p_STR IN VARCHAR2) IS
	BEGIN
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(p_STR || UTL_TCP.CRLF), p_STR || UTL_TCP.CRLF);
	END APPEND;

	PROCEDURE APPEND_EMPTY_LINE IS
	BEGIN
		APPEND('');
	END APPEND_EMPTY_LINE;

	PROCEDURE APPEND_DO_NOT_EDIT_BLOCK IS
	BEGIN
		APPEND_EMPTY_LINE;
		APPEND('--This package contains an AUTO-GENERATED set of Constants for working with Message Definitions.');
		APPEND('--Do not edit it directly.');
		APPEND('--To get a copy of the package that is in sync with your Message Definition table,');
		APPEND('--  call UT.GENERATE_MSGCODES');		
		APPEND_EMPTY_LINE;
	END APPEND_DO_NOT_EDIT_BLOCK;
BEGIN

	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
	DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);

	APPEND('CREATE OR REPLACE PACKAGE MSGCODES AS');
	APPEND('--Revision $Revision: 1.29 $');	
	
	APPEND_DO_NOT_EDIT_BLOCK;
	
	APPEND('FUNCTION WHAT_VERSION RETURN VARCHAR2;');

	FOR v_MD IN c_MESSAGE_DEFINITIONS LOOP
		IF v_PREV_TYPE <> v_MD.MESSAGE_TYPE THEN
			APPEND_EMPTY_LINE;
			APPEND('	--============================================');
			APPEND('	-- ' || v_MD.MESSAGE_TYPE || ' Message Constants:');
			APPEND('	--============================================');
			v_PREV_TYPE := v_MD.MESSAGE_TYPE;
		END IF;

		APPEND('	c_' || v_MD.MESSAGE_IDENT || ' CONSTANT VARCHAR2(12) := ''' || v_MD.MESSAGE_TYPE || '-' || TRIM(TO_CHAR(v_MD.MESSAGE_NUMBER, '00000')) || ''';');

		IF v_MD.MESSAGE_TYPE = 'ORA' THEN
			APPEND('		n_' || v_MD.MESSAGE_IDENT || ' CONSTANT PLS_INTEGER := ' || -v_MD.MESSAGE_NUMBER || ';');
			APPEND('		e_' || v_MD.MESSAGE_IDENT || ' EXCEPTION;');
			APPEND('		PRAGMA EXCEPTION_INIT(e_' || v_MD.MESSAGE_IDENT || ', ' || -v_MD.MESSAGE_NUMBER || ');');
		END IF;
	END LOOP;

	APPEND_DO_NOT_EDIT_BLOCK;

	APPEND('END MSGCODES;');
	APPEND('/');
	APPEND_EMPTY_LINE;
	
	APPEND('CREATE OR REPLACE PACKAGE BODY MSGCODES AS');
	APPEND('FUNCTION WHAT_VERSION RETURN VARCHAR2 IS');
	APPEND('BEGIN');
	APPEND('	RETURN ''$Revision: 1.29 $'';');
	APPEND('END WHAT_VERSION;');
	APPEND('END MSGCODES;');
	APPEND('/');
	APPEND_EMPTY_LINE;


	DBMS_LOB.CLOSE(v_RET);
	RETURN v_RET;

END GENERATE_MSGCODES;
---------------------------------------------------------------------------------------------------
FUNCTION IS_SESSION_ALIVE(p_SESSION_ID VARCHAR2) RETURN NUMBER AS

BEGIN
	RETURN UT.NUMBER_FROM_BOOLEAN(DBMS_SESSION.IS_SESSION_ALIVE(p_SESSION_ID));
EXCEPTION
	WHEN ERRS.e_INVALID_SESSION_ID THEN
		RETURN 0; -- invalid session ID? then return that the session is not alive
END IS_SESSION_ALIVE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_STORED_PROC_PARAMETERS
	(
	p_PACKAGE_NAME IN VARCHAR,
	p_PROCEDURE_NAME IN VARCHAR,
	p_OVERLOAD_INDEX IN NUMBER,
	p_PARAM_TABLE OUT STORED_PROC_PARAMETER_TABLE
	) AS
v_PACKAGE_NAME VARCHAR2(32) := p_PACKAGE_NAME;
v_PROCEDURE_NAME VARCHAR2(32) := p_PROCEDURE_NAME;
v_COUNT BINARY_INTEGER;
v_OWNER VARCHAR2(32) := USER;
BEGIN

	p_PARAM_TABLE := STORED_PROC_PARAMETER_TABLE();

	IF p_PACKAGE_NAME IS NOT NULL THEN
        -- find owner name
        SELECT COUNT(*)
        INTO v_COUNT
        FROM ALL_OBJECTS O
        WHERE O.OWNER = v_OWNER
            AND O.OBJECT_NAME = UPPER(p_PACKAGE_NAME)
            AND O.OBJECT_TYPE = 'PACKAGE'
            AND EXISTS (SELECT A.OBJECT_ID FROM ALL_ARGUMENTS A WHERE A.OWNER = v_OWNER AND A.OBJECT_ID = O.OBJECT_ID);

        -- don't own it? see if it is a synonym
        IF v_COUNT = 0 THEN
            BEGIN
                SELECT TABLE_OWNER, TABLE_NAME
                INTO v_OWNER, v_PACKAGE_NAME
                FROM ALL_SYNONYMS
                WHERE OWNER = USER
                    AND SYNONYM_NAME = UPPER(p_PACKAGE_NAME);
            EXCEPTION WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
                v_OWNER := USER;
                v_PACKAGE_NAME := p_PACKAGE_NAME;
            END;
        END IF;

		SELECT STORED_PROC_PARAMETER_TYPE(NVL(A.ARGUMENT_NAME,'*return-value*'),
			A.IN_OUT,
			A.DATA_TYPE,
			A.TYPE_NAME, --SUCH AS STRING_COLLECTION, NUMBER_COLLECTION
			A.POSITION)
		BULK COLLECT INTO p_PARAM_TABLE
		FROM ALL_OBJECTS O, ALL_ARGUMENTS A
		WHERE O.OWNER = v_OWNER
			AND O.OBJECT_NAME = UPPER(v_PACKAGE_NAME)
			AND O.OBJECT_TYPE = 'PACKAGE'
			AND A.OWNER = v_OWNER
			AND A.OBJECT_ID = O.OBJECT_ID
			AND A.OBJECT_NAME = UPPER(p_PROCEDURE_NAME)
			AND A.PACKAGE_NAME = UPPER(v_PACKAGE_NAME)
			AND NVL(A.OVERLOAD,0) = p_OVERLOAD_INDEX
			-- Procedures with no parameters have a dummy entry in
			-- this view. We want to exclude those dummy entries
			-- and can identify them by their NULL data type
			AND A.DATA_TYPE IS NOT NULL
			-- We do not want nested types to show up as multiple parameters
			AND A.DATA_LEVEL = 0
		ORDER BY A.POSITION;
	ELSE
        -- find owner name
        SELECT COUNT(*)
        INTO v_COUNT
        FROM ALL_OBJECTS O
        WHERE O.OWNER = v_OWNER
            AND O.OBJECT_NAME = UPPER(p_PROCEDURE_NAME)
            AND O.OBJECT_TYPE IN ('PROCEDURE','FUNCTION')
            AND EXISTS (SELECT A.OBJECT_ID FROM ALL_ARGUMENTS A WHERE A.OWNER = v_OWNER AND A.OBJECT_ID = O.OBJECT_ID);

        -- don't own it? see if it is a synonym
        IF v_COUNT = 0 THEN
            BEGIN
                SELECT TABLE_OWNER, TABLE_NAME
                INTO v_OWNER, v_PROCEDURE_NAME
                FROM ALL_SYNONYMS
                WHERE OWNER = USER
	                AND SYNONYM_NAME = UPPER(p_PROCEDURE_NAME);
            EXCEPTION WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
                v_OWNER := USER;
                v_PROCEDURE_NAME := p_PROCEDURE_NAME;
            END;
        END IF;

		SELECT STORED_PROC_PARAMETER_TYPE(NVL(A.ARGUMENT_NAME,'*return-value*'),
			A.IN_OUT,
			A.DATA_TYPE,
			A.TYPE_NAME, --SUCH AS STRING_COLLECTION, NUMBER_COLLECTION
			A.POSITION)
		BULK COLLECT INTO p_PARAM_TABLE
		FROM ALL_OBJECTS O, ALL_ARGUMENTS A
		WHERE O.OWNER = v_OWNER
			AND O.OBJECT_NAME = UPPER(v_PROCEDURE_NAME)
			AND O.OBJECT_TYPE IN ('PROCEDURE','FUNCTION')
			AND A.OWNER = v_OWNER
			AND A.OBJECT_ID = O.OBJECT_ID
			AND A.OBJECT_NAME = UPPER(v_PROCEDURE_NAME)
			AND A.PACKAGE_NAME IS NULL
			AND NVL(A.OVERLOAD,0) = p_OVERLOAD_INDEX
			-- Procedures with no parameters have a dummy entry in
			-- this view. We want to exclude those dummy entries
			-- and can identify them by their NULL data type
			AND A.DATA_TYPE IS NOT NULL
			-- We do not want nested types to show up as multiple parameters
			AND A.DATA_LEVEL = 0
		ORDER BY A.POSITION;
	END IF;

END GET_STORED_PROC_PARAMETERS;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_STORED_PROC_PARAMETERS
	(
	p_PACKAGE_AND_PROC_NAME IN VARCHAR2,
	p_OVERLOAD_INDEX IN NUMBER,
	p_PARAM_TABLE OUT STORED_PROC_PARAMETER_TABLE
	) AS
	v_PACKAGE_NAME VARCHAR2(30) := NULL;
	v_PROCEDURE_NAME VARCHAR2(30) := NULL;
	v_POS BINARY_INTEGER;
BEGIN
	v_POS := INSTR(p_PACKAGE_AND_PROC_NAME, '.');
	IF v_POS > 0 THEN
		v_PACKAGE_NAME := SUBSTR(p_PACKAGE_AND_PROC_NAME, 1, v_POS-1);
		v_PROCEDURE_NAME := SUBSTR(p_PACKAGE_AND_PROC_NAME, v_POS+1);
	ELSE
		v_PROCEDURE_NAME := p_PACKAGE_AND_PROC_NAME;
	END IF;

	GET_STORED_PROC_PARAMETERS(v_PACKAGE_NAME, v_PROCEDURE_NAME, p_OVERLOAD_INDEX, p_PARAM_TABLE);

END GET_STORED_PROC_PARAMETERS;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_STORED_PROC_OVERLOAD_COUNT
	(
	p_PACKAGE_NAME IN VARCHAR,
	p_PROCEDURE_NAME IN VARCHAR,
	p_COUNT OUT NUMBER
	) AS
v_PACKAGE_NAME VARCHAR2(32) := p_PACKAGE_NAME;
v_PROCEDURE_NAME VARCHAR2(32) := p_PROCEDURE_NAME;
v_COUNT BINARY_INTEGER;
v_OWNER VARCHAR2(32) := USER;
BEGIN
	IF p_PACKAGE_NAME IS NOT NULL THEN
        -- find owner name
        SELECT COUNT(*)
        INTO v_COUNT
        FROM ALL_OBJECTS O
        WHERE O.OWNER = v_OWNER
            AND O.OBJECT_NAME = UPPER(p_PACKAGE_NAME)
            AND O.OBJECT_TYPE = 'PACKAGE'
            AND EXISTS (SELECT A.OBJECT_ID FROM ALL_ARGUMENTS A WHERE A.OWNER = v_OWNER AND A.OBJECT_ID = O.OBJECT_ID);

        -- don't own it? see if it is a synonym
        IF v_COUNT = 0 THEN
            BEGIN
                SELECT TABLE_OWNER, TABLE_NAME
                INTO v_OWNER, v_PACKAGE_NAME
                FROM ALL_SYNONYMS
                WHERE OWNER = USER
                    AND SYNONYM_NAME = UPPER(p_PACKAGE_NAME);
            EXCEPTION WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
                v_OWNER := USER;
                v_PACKAGE_NAME := p_PACKAGE_NAME;
            END;
        END IF;


        SELECT NVL(MAX(OVERLOAD),0)
		INTO p_COUNT
        FROM ALL_OBJECTS O, ALL_ARGUMENTS A
        WHERE O.OWNER = v_OWNER
            AND O.OBJECT_NAME = UPPER(v_PACKAGE_NAME)
            AND O.OBJECT_TYPE = 'PACKAGE'
            AND A.OWNER = v_OWNER
            AND A.OBJECT_ID = O.OBJECT_ID
            AND A.OBJECT_NAME = UPPER(p_PROCEDURE_NAME)
            AND A.PACKAGE_NAME = UPPER(v_PACKAGE_NAME);
	ELSE
        -- find owner name
        SELECT COUNT(*)
        INTO v_COUNT
        FROM ALL_OBJECTS O
        WHERE O.OWNER = v_OWNER
            AND O.OBJECT_NAME = UPPER(p_PROCEDURE_NAME)
            AND O.OBJECT_TYPE IN ('PROCEDURE','FUNCTION')
            AND EXISTS (SELECT A.OBJECT_ID FROM ALL_ARGUMENTS A WHERE A.OWNER = v_OWNER AND A.OBJECT_ID = O.OBJECT_ID);

        -- don't own it? see if it is a synonym
        IF v_COUNT = 0 THEN
            BEGIN
                SELECT TABLE_OWNER, TABLE_NAME
                INTO v_OWNER, v_PROCEDURE_NAME
                FROM ALL_SYNONYMS
                WHERE OWNER = USER
	                AND SYNONYM_NAME = UPPER(p_PROCEDURE_NAME);
            EXCEPTION WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
                v_OWNER := USER;
                v_PROCEDURE_NAME := p_PROCEDURE_NAME;
            END;
        END IF;

        SELECT NVL(MAX(OVERLOAD),0)
		INTO p_COUNT
        FROM ALL_OBJECTS O, ALL_ARGUMENTS A
        WHERE O.OWNER = v_OWNER
            AND O.OBJECT_NAME = UPPER(v_PROCEDURE_NAME)
            AND O.OBJECT_TYPE IN ('PROCEDURE','FUNCTION')
            AND A.OWNER = v_OWNER
            AND A.OBJECT_ID = O.OBJECT_ID
            AND A.OBJECT_NAME = UPPER(v_PROCEDURE_NAME)
            AND A.PACKAGE_NAME IS NULL;
	END IF;

END GET_STORED_PROC_OVERLOAD_COUNT;
----------------------------------------------------------------------------------------------------
-- Generates a Job Name for use with DBMS_SCHEDULER.
-- User specified by USER_ID must exist in the system at the time this function is called.
-- Job Name is in the form <UserName>#<OracleJobSequence>.
FUNCTION GENERATE_JOB_NAME
	(
	p_USER_ID IN NUMBER
	)RETURN VARCHAR2 IS
	v_USER_NAME APPLICATION_USER.USER_NAME%TYPE;
	v_JOB_PREFIX VARCHAR2(30);
	v_RTN VARCHAR2(30);
BEGIN
	SELECT USER_NAME INTO v_USER_NAME FROM APPLICATION_USER WHERE USER_ID = p_USER_ID;

	--Job name identifiers must start with a letter - prefix with 'A' if necessary
	v_JOB_PREFIX := REGEXP_REPLACE(v_USER_NAME, '^([^[:alpha:]])', 'A\1');
	--This can be a max of 18 characters, and may not end in a number.
	--Further, it can only include alphanumeric characters, dollars, pound signs
	-- and underscores. Any other characters will be replaced with '$'
	v_JOB_PREFIX := REGEXP_REPLACE(SUBSTR(v_JOB_PREFIX,1,17), '[^[:alnum:]$#_]', '$')||'#';

	v_RTN := DBMS_SCHEDULER.GENERATE_JOB_NAME(v_JOB_PREFIX);
	RETURN UPPER(v_RTN);

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.RAISE_BAD_ARGUMENT('USER_ID', p_USER_ID, 'Could not generate job name for user.');

END GENERATE_JOB_NAME;
FUNCTION MAP_TO_STRING
	(
	p_MAP IN UT.STRING_MAP,
	p_PAIR_DELIM IN VARCHAR2,
	p_ENTRY_DELIM IN VARCHAR2
	) RETURN VARCHAR2 IS
v_RET	VARCHAR2(32767);
v_KEY	VARCHAR2(32);
BEGIN
	v_KEY := p_MAP.FIRST;
	WHILE p_MAP.EXISTS(v_KEY) LOOP
		IF v_RET IS NOT NULL THEN
			v_RET := v_RET||p_ENTRY_DELIM;
		END IF;
		v_RET := v_RET||v_KEY||p_PAIR_DELIM||p_MAP(v_KEY);
		-- onto the next column
		v_KEY := p_MAP.NEXT(v_KEY);
	END LOOP;

	RETURN v_RET;
END MAP_TO_STRING;
----------------------------------------------------------------------------------------------------
FUNCTION MAP_TO_KEYS_STRING
	(
	p_MAP IN UT.STRING_MAP,
	p_ENTRY_DELIM IN VARCHAR2
	) RETURN VARCHAR2 IS
v_RET	VARCHAR2(32767);
v_KEY	VARCHAR2(32);
BEGIN
	v_KEY := p_MAP.FIRST;
	WHILE p_MAP.EXISTS(v_KEY) LOOP
		IF v_RET IS NOT NULL THEN
			v_RET := v_RET||p_ENTRY_DELIM;
		END IF;
		v_RET := v_RET||v_KEY;
		-- onto the next column
		v_KEY := p_MAP.NEXT(v_KEY);
	END LOOP;

	RETURN v_RET;
END MAP_TO_KEYS_STRING;
----------------------------------------------------------------------------------------------------
FUNCTION MAP_TO_VALS_STRING
	(
	p_MAP IN UT.STRING_MAP,
	p_ENTRY_DELIM IN VARCHAR2
	) RETURN VARCHAR2 IS
v_RET	VARCHAR2(32767);
v_KEY	VARCHAR2(32);
BEGIN
	v_KEY := p_MAP.FIRST;
	WHILE p_MAP.EXISTS(v_KEY) LOOP
		IF v_RET IS NOT NULL THEN
			v_RET := v_RET||p_ENTRY_DELIM;
		END IF;
		v_RET := v_RET||p_MAP(v_KEY);
		-- onto the next column
		v_KEY := p_MAP.NEXT(v_KEY);
	END LOOP;

	RETURN v_RET;
END MAP_TO_VALS_STRING;
----------------------------------------------------------------------------------------------------
FUNCTION MAP_TO_WHERE_CLAUSE
	(
	p_CRITERIA IN UT.STRING_MAP,
	p_TBL_ALIAS IN VARCHAR2 := NULL
	) RETURN VARCHAR2 IS
v_WHERE	VARCHAR2(32767);
v_COL	VARCHAR2(32);
v_TBL_ALIAS VARCHAR2(31) := CASE WHEN p_TBL_ALIAS IS NOT NULL THEN p_TBL_ALIAS||'.' ELSE NULL END;
BEGIN
	v_COL := p_CRITERIA.FIRST;
	WHILE p_CRITERIA.EXISTS(v_COL) LOOP
		IF v_WHERE IS NOT NULL THEN
			v_WHERE := v_WHERE||' AND ';
		END IF;
		v_WHERE := v_WHERE||v_TBL_ALIAS||BUILD_JOIN_CLAUSE(v_COL, p_CRITERIA(v_COL));
		-- onto the next column
		v_COL := p_CRITERIA.NEXT(v_COL);
	END LOOP;

	RETURN v_WHERE;
END MAP_TO_WHERE_CLAUSE;
----------------------------------------------------------------------------------------------------
FUNCTION MAP_TO_UPDATE_CLAUSE
	(
	p_CRITERIA IN UT.STRING_MAP
	) RETURN VARCHAR2 IS
BEGIN
	RETURN MAP_TO_STRING(p_CRITERIA, ' = ', ', ');
END MAP_TO_UPDATE_CLAUSE;
----------------------------------------------------------------------------------------------------
FUNCTION MAP_TO_INSERT_NAMES
	(
	p_CRITERIA IN UT.STRING_MAP
	) RETURN VARCHAR2 IS
BEGIN
	RETURN MAP_TO_KEYS_STRING(p_CRITERIA, ', ');
END MAP_TO_INSERT_NAMES;
----------------------------------------------------------------------------------------------------
FUNCTION MAP_TO_INSERT_VALS
	(
	p_CRITERIA IN UT.STRING_MAP
	) RETURN VARCHAR2 IS
BEGIN
	RETURN MAP_TO_VALS_STRING(p_CRITERIA, ', ');
END MAP_TO_INSERT_VALS;
----------------------------------------------------------------------------------------------------
FUNCTION GET_FK_REF_DETAILS_FROM_ERRM
	(
	p_SQLERRM IN VARCHAR2, -- SQL ERROR MESSAGE
	p_ENTITY_DOMAIN_ID IN NUMBER, -- THE DOMAIN OF THE ENTITY
	p_ENTITY_ID IN VARCHAR2 -- THE ENTITY THAT STILL HAS CHILD REFERENCES
	) RETURN VARCHAR2 AS

	v_TABLE_DB_NAME VARCHAR2(64);
	v_REFERRED_COLUMN_NAME VARCHAR2(64);
	v_ENTITY_COL_NAME VARCHAR2(64);

	v_DATE1_COLUMN_NAME VARCHAR2(64);
	v_DATE2_COLUMN_NAME VARCHAR2(64);
	v_SQL VARCHAR2(1000);

	v_BEGIN_PARAN NUMBER(9);
	v_END_PARAN NUMBER(9);
	v_CONSTRAINT_NAME VARCHAR2(100);

	v_REF_TABLE SYSTEM_TABLE.TABLE_NAME%TYPE;
	v_REF_ENTITY_DOMAIN_ID NUMBER(9);
	v_REF_ENTITY_ID NUMBER_COLLECTION := NUMBER_COLLECTION();
	v_REF_ENTITY_COUNT NUMBER(9);

	v_MIN_BEGIN_DATE DATE;
	v_MAX_BEGIN_DATE DATE;

	v_COUNT NUMBER(9);
	v_MSG_PREFIX VARCHAR2(500);
	v_MESSAGE VARCHAR2(4000);

	v_NO_REF_ENTITIES BOOLEAN := FALSE;
	v_REF_REC_TYPE VARCHAR(8);
	v_REF_REC_TYPES VARCHAR(8);
BEGIN

	-- The foreign key name is given in the paranthesis in the error message
	v_BEGIN_PARAN := INSTR(p_SQLERRM, '(')+1;
	v_END_PARAN := INSTR(p_SQLERRM, ')');

	-- The foreign key's format is TALBE_NAME.FK_NAME
	v_CONSTRAINT_NAME := SUBSTR(p_SQLERRM, v_BEGIN_PARAN, v_END_PARAN-v_BEGIN_PARAN);
	v_CONSTRAINT_NAME := SUBSTR(v_CONSTRAINT_NAME, INSTR(v_CONSTRAINT_NAME, '.')+1);

	-- GET THE REFERENCED COLUMN FOR THE FOREIGN KEY (ASSUMED TO BE THE PRIMARY COLUMN ID).
	-- THIS ASSUMES A SINGLE COLUMN PRIMARY KEY AS THE REFERENCED COLUMN, THIS IS NOT
	-- NECESSARILY THE CASE PER ORACLE, BUT IT IS OUR STANDARD FOR PRODUCT CODE
	SELECT UC.TABLE_NAME, UCC.COLUMN_NAME INTO v_TABLE_DB_NAME, v_REFERRED_COLUMN_NAME
	FROM USER_CONSTRAINTS UC,
		USER_CONS_COLUMNS UCC
	WHERE UC.OWNER = USER
		AND UC.CONSTRAINT_NAME = v_CONSTRAINT_NAME
		AND UC.CONSTRAINT_TYPE = 'R'
		AND UC.R_OWNER = USER
		AND UCC.OWNER = USER
		AND UCC.CONSTRAINT_NAME = UC.CONSTRAINT_NAME
		AND UCC.TABLE_NAME = UC.TABLE_NAME
		AND UCC.POSITION = 1;

	BEGIN

		-- Look at System Table to get a nicely formatted table name.  If it has an entity domain
		-- we can look up the referencing entity
		SELECT ST.TABLE_NAME || '(' || v_TABLE_DB_NAME || ')', ST.ENTITY_DOMAIN_ID,
			ST.ENTITY_ID_COLUMN_NAME, ST.DATE1_COLUMN_NAME, ST.DATE2_COLUMN_NAME
		INTO v_REF_TABLE, v_REF_ENTITY_DOMAIN_ID, v_ENTITY_COL_NAME, v_DATE1_COLUMN_NAME, v_DATE2_COLUMN_NAME
		FROM SYSTEM_TABLE ST
		WHERE ST.DB_TABLE_NAME = v_TABLE_DB_NAME;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_REF_TABLE := v_TABLE_DB_NAME;

			SELECT MAX(NI.PRIMARY_ID_COLUMN), MAX(ED.ENTITY_DOMAIN_ID)
			  INTO v_ENTITY_COL_NAME, v_REF_ENTITY_DOMAIN_ID
			  FROM NERO_TABLE_PROPERTY_INDEX NI, ENTITY_DOMAIN ED
			 WHERE NI.TABLE_NAME = v_TABLE_DB_NAME
			   AND ED.ENTITY_DOMAIN_TABLE = v_TABLE_DB_NAME
			   AND MOD(ED.ENTITY_DOMAIN_ID, 10) = 0;

	END;

	IF (v_REFERRED_COLUMN_NAME = v_ENTITY_COL_NAME OR v_REF_ENTITY_DOMAIN_ID IS NULL) THEN

		v_SQL := 'SELECT COUNT(' || v_REFERRED_COLUMN_NAME || ') FROM ' || v_TABLE_DB_NAME ||
				' WHERE ' || v_REFERRED_COLUMN_NAME || ' = ' || p_ENTITY_ID;

		EXECUTE IMMEDIATE v_SQL INTO v_REF_ENTITY_COUNT;

		v_NO_REF_ENTITIES := TRUE;

	ElSIF NVL(v_REF_ENTITY_DOMAIN_ID, CONSTANTS.NOT_ASSIGNED) <> CONSTANTS.NOT_ASSIGNED THEN
		-- We have a entity domain for the system table, look up the IDs of the restricing
		-- entities
		v_SQL := 'SELECT DISTINCT ' || v_ENTITY_COL_NAME || ' FROM ' || v_TABLE_DB_NAME ||
					' WHERE ' || v_REFERRED_COLUMN_NAME || ' = ' || p_ENTITY_ID;

		EXECUTE IMMEDIATE v_SQL BULK COLLECT INTO v_REF_ENTITY_ID;

		v_REF_ENTITY_COUNT := v_REF_ENTITY_ID.COUNT;
	END IF;

	IF v_DATE1_COLUMN_NAME IS NOT NULL THEN
		v_SQL := 'SELECT MIN(' || v_DATE1_COLUMN_NAME || '), MAX('|| v_DATE1_COLUMN_NAME
			|| ') FROM ' || v_TABLE_DB_NAME
			|| ' WHERE ' || v_REFERRED_COLUMN_NAME || ' = ' || p_ENTITY_ID;

		EXECUTE IMMEDIATE v_SQL INTO v_MIN_BEGIN_DATE, v_MAX_BEGIN_DATE;
	END IF;

	-- Build the message
    IF p_ENTITY_DOMAIN_ID IS NOT NULL THEN
        v_MSG_PREFIX := TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_ID,
                                                 p_ENTITY_DOMAIN_ID,
                                                 TRUE);
    ELSE
        v_MSG_PREFIX := 'The record';
    END IF;

	-- Get number of referencing entities that can be displayed on the error message
	v_COUNT := NVL(GET_DICTIONARY_VALUE('Referencing Entities Threshold', 0, 'Entity Manager'),5);

	IF v_NO_REF_ENTITIES THEN
		v_REF_REC_TYPE := 'record';
		v_REF_REC_TYPES := 'records';
	ELSE
		v_REF_REC_TYPE := 'entity';
		v_REF_REC_TYPES := 'entities';
	END IF;

    v_MESSAGE := v_MSG_PREFIX ||
                 ' cannot be deleted.  It is referenced by ' ||
                 v_REF_ENTITY_COUNT || ' ' || CASE v_REF_ENTITY_COUNT WHEN 1 THEN v_REF_REC_TYPE
				 ELSE v_REF_REC_TYPES END || ' in child table: ' ||
                 v_REF_TABLE ;

	-- Add dates if required
    IF v_MIN_BEGIN_DATE IS NOT NULL THEN
        v_MESSAGE := v_MESSAGE || ' during the period: ' ||
                     TEXT_UTIL.TO_CHAR_DATE(v_MIN_BEGIN_DATE) || ' and ' ||
                     TEXT_UTIL.TO_CHAR_DATE(v_MAX_BEGIN_DATE) || '.';
	ELSE
		 v_MESSAGE := v_MESSAGE || '.';
    END IF;

	IF v_NO_REF_ENTITIES = FALSE THEN
	-- Build entity list or post it to logs
		IF v_REF_ENTITY_COUNT <= v_COUNT THEN
			v_MESSAGE := v_MESSAGE || '<br><br> Referencing ' || CASE v_REF_ENTITY_COUNT WHEN 1 THEN 'entity'
						ELSE 'entities' END || ': ' ||
						TEXT_UTIL.TO_CHAR_ENTITY_LIST(v_REF_ENTITY_ID,
													   v_REF_ENTITY_DOMAIN_ID,
													   FALSE,
													   FALSE);
		ELSE
			v_MESSAGE := v_MESSAGE || ' See Process log for more details.';
			LOGS.LOG_ERROR('Delete ' || TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_ID,
													 p_ENTITY_DOMAIN_ID,
													 TRUE));
			LOGS.POST_EVENT_DETAILS('Entity List in ' || v_REF_TABLE,
							CONSTANTS.MIME_TYPE_TEXT,
							TEXT_UTIL.TO_CLOB_ENTITY_LIST(v_REF_ENTITY_ID,v_REF_ENTITY_DOMAIN_ID));
		END IF;
	END IF;

	RETURN v_MESSAGE;

END GET_FK_REF_DETAILS_FROM_ERRM;
----------------------------------------------------------------------------------------------------
-- TAKES IN A LIST OF (POTENTIALLY) NON DISTINCT NUMBERS AND RETURNS A DISTINCT COLLECTION
PROCEDURE CREATE_DISTINCT_NUM_COLLECTION
(
	p_NUM_COLLECTION IN NUMBER_COLLECTION,
	p_DISTINCT_NUM_COLLECTION OUT NUMBER_COLLECTION
) AS

BEGIN

	SELECT DISTINCT NUM_COL.COLUMN_VALUE
	BULK COLLECT INTO p_DISTINCT_NUM_COLLECTION
	FROM TABLE(CAST(p_NUM_COLLECTION AS NUMBER_COLLECTION)) NUM_COL;

END CREATE_DISTINCT_NUM_COLLECTION;
----------------------------------------------------------------------------------------------------
PROCEDURE CREATE_DISTINCT_STRING_COLL
	(
	p_STRING_COLLECTION IN STRING_COLLECTION,
	p_DISTINCT_STRING_COLLECTION OUT STRING_COLLECTION
	) AS

BEGIN

	SELECT DISTINCT STR_COL.COLUMN_VALUE
	BULK COLLECT INTO p_DISTINCT_STRING_COLLECTION
	FROM TABLE(CAST(p_STRING_COLLECTION AS STRING_COLLECTION)) STR_COL;

END CREATE_DISTINCT_STRING_COLL;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_DATE_COLLECTION_MIN_MAX
	(
	p_DATE_COLL IN DATE_COLLECTION,
	p_MIN_DATE OUT DATE,
	p_MAX_DATE OUT DATE
	) AS

BEGIN

	SELECT MIN(X.COLUMN_VALUE), MAX(X.COLUMN_VALUE)
	INTO p_MIN_DATE, p_MAX_DATE
	FROM TABLE(CAST(p_DATE_COLL AS DATE_COLLECTION)) X;

END GET_DATE_COLLECTION_MIN_MAX;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_DATE_COLL_COLL_MIN_MAX
	(
	p_DATE_COLL_COLL IN DATE_COLLECTION_COLLECTION,
	p_MIN_DATE OUT DATE,
	p_MAX_DATE OUT DATE
	) AS

	v_MIN DATE;
	v_MAX DATE;

BEGIN

	FOR v_IDX IN 1..p_DATE_COLL_COLL.COUNT LOOP
		UT.GET_DATE_COLLECTION_MIN_MAX(p_DATE_COLL_COLL(v_IDX),
										v_MIN,
										v_MAX);

		IF v_MIN < NVL(p_MIN_DATE, CONSTANTS.HIGH_DATE) THEN
			p_MIN_DATE := v_MIN;
		END IF;

		IF v_MAX > NVL(p_MAX_DATE, CONSTANTS.LOW_DATE) THEN
			p_MAX_DATE := v_MAX;
		END IF;
	END LOOP;

END GET_DATE_COLL_COLL_MIN_MAX;
----------------------------------------------------------------------------------------------------
PROCEDURE CONVERT_ID_TABLE_TO_NUM_COLL
	(
	p_ID_TABLE IN ID_TABLE,
	p_NUM_COLL OUT NUMBER_COLLECTION
	) AS

	v_IDX NUMBER;

BEGIN

	p_NUM_COLL := NUMBER_COLLECTION();

	FOR v_IDX IN 1..p_ID_TABLE.LAST LOOP
		p_NUM_COLL.EXTEND();
		p_NUM_COLL(v_IDX) := p_ID_TABLE(v_IDX).ID;
	END LOOP;

END CONVERT_ID_TABLE_TO_NUM_COLL;
----------------------------------------------------------------------------------------------------
FUNCTION NEW_NUMBER_COLLECTION
	(
	p_LENGTH IN NUMBER := 0,
	p_FILL_VALUE IN NUMBER := NULL
	) RETURN NUMBER_COLLECTION AS
v_NUMBER_COLLECTION NUMBER_COLLECTION;
BEGIN
	v_NUMBER_COLLECTION := NUMBER_COLLECTION();
	FOR v_IDX IN 1..p_LENGTH LOOP
		v_NUMBER_COLLECTION.EXTEND();
		v_NUMBER_COLLECTION(v_IDX) := p_FILL_VALUE;
	END LOOP;
	RETURN v_NUMBER_COLLECTION;
END NEW_NUMBER_COLLECTION;
----------------------------------------------------------------------------------------------------
FUNCTION NEW_STRING_COLLECTION
	(
	p_LENGTH IN NUMBER := 0,
	p_FILL_VALUE IN STRING := NULL
	) RETURN STRING_COLLECTION AS
v_STRING_COLLECTION STRING_COLLECTION;
BEGIN
	v_STRING_COLLECTION := STRING_COLLECTION();
	FOR v_IDX IN 1..p_LENGTH LOOP
		v_STRING_COLLECTION.EXTEND();
		v_STRING_COLLECTION(v_IDX) := p_FILL_VALUE;
	END LOOP;
	RETURN v_STRING_COLLECTION;
END NEW_STRING_COLLECTION;
----------------------------------------------------------------------------------------------------
FUNCTION NEW_DATE_COLLECTION
	(
	p_LENGTH IN NUMBER := 0,
	p_FILL_VALUE IN DATE := NULL
	) RETURN DATE_COLLECTION AS
v_DATE_COLLECTION DATE_COLLECTION;
BEGIN
	v_DATE_COLLECTION := DATE_COLLECTION();
	FOR v_IDX IN 1..p_LENGTH LOOP
		v_DATE_COLLECTION.EXTEND();
		v_DATE_COLLECTION(v_IDX) := p_FILL_VALUE;
	END LOOP;
	RETURN v_DATE_COLLECTION;
END NEW_DATE_COLLECTION;
----------------------------------------------------------------------------------------------------
FUNCTION CUT_DATE_COLL
    (
    p_DATE_COLL IN DATE_COLLECTION,
    p_TIME_ZONE IN VARCHAR2
    ) RETURN DATE_COLLECTION AS
    v_CUT_DATE_COLL DATE_COLLECTION;
BEGIN
    IF p_DATE_COLL IS NULL THEN
        RETURN NULL;
    END IF;

    v_CUT_DATE_COLL := DATE_COLLECTION();
    
    FOR v_IDX IN 1..p_DATE_COLL.COUNT LOOP
        v_CUT_DATE_COLL.EXTEND();
        v_CUT_DATE_COLL(v_IDX) := TO_CUT(p_DATE_COLL(v_IDX), p_TIME_ZONE);
    END LOOP;
    
    RETURN v_CUT_DATE_COLL;
END CUT_DATE_COLL;
----------------------------------------------------------------------------------------------------
FUNCTION CUT_DATE_COLL_COLL
    (
    p_DATE_COLL_COLL IN DATE_COLLECTION_COLLECTION,
    p_TIME_ZONE IN VARCHAR2
    ) RETURN DATE_COLLECTION_COLLECTION AS
    v_CUT_DATE_COLL_COLL DATE_COLLECTION_COLLECTION;
BEGIN
    IF p_DATE_COLL_COLL IS NULL THEN
        RETURN NULL;
    END IF;

    v_CUT_DATE_COLL_COLL := DATE_COLLECTION_COLLECTION();
    
    FOR v_IDX IN 1..p_DATE_COLL_COLL.COUNT LOOP
        v_CUT_DATE_COLL_COLL.EXTEND();
        
        IF p_DATE_COLL_COLL(v_IDX) IS NULL THEN
            v_CUT_DATE_COLL_COLL(v_IDX) := NULL;
        ELSE
            v_CUT_DATE_COLL_COLL(v_IDX) := DATE_COLLECTION();
            
            FOR v_IDX2 IN 1..p_DATE_COLL_COLL(v_IDX).COUNT LOOP
                v_CUT_DATE_COLL_COLL(v_IDX).EXTEND();
                v_CUT_DATE_COLL_COLL(v_IDX)(v_IDX2) := TO_CUT(p_DATE_COLL_COLL(v_IDX)(v_IDX2), p_TIME_ZONE);
            END LOOP;
        END IF;
    END LOOP;
    
    RETURN v_CUT_DATE_COLL_COLL;
END CUT_DATE_COLL_COLL;
----------------------------------------------------------------------------------------------------
FUNCTION CONVERT_FLT_TABLE_TO_NUM_TABLE
	(
	p_FLOAT_TBL IN GA.FLOAT_TABLE
	) RETURN GA.NUMBER_TABLE IS

	v_IDX PLS_INTEGER;
	v_RETURN GA.NUMBER_TABLE;

BEGIN

	FOR v_IDX IN 1..p_FLOAT_TBL.LAST LOOP
		v_RETURN(v_IDX) := p_FLOAT_TBL(v_IDX);
	END LOOP;

	RETURN v_RETURN;

END CONVERT_FLT_TABLE_TO_NUM_TABLE;
----------------------------------------------------------------------------------------------------
FUNCTION NEW_FOREIGN_KEY_INDEXES RETURN CLOB IS
	v_COL_STR				VARCHAR2(32767);
	v_COL_COUNT             BINARY_INTEGER;
	v_INDEXED_COL_COUNT     BINARY_INTEGER;
	v_RET					CLOB;
	CURSOR cur_CONSTRAINTS IS
		-- gather all foreign key constraints
		SELECT C.CONSTRAINT_NAME, C.TABLE_NAME
		FROM USER_CONSTRAINTS C
		WHERE C.CONSTRAINT_TYPE = 'R'
			-- exclude constraints that are configured to be ignored
			-- via system settings
			AND NOT EXISTS (SELECT 1
							FROM SYSTEM_LABEL SL
							WHERE SL.MODEL_ID = 0
								AND SL.MODULE = 'System'
								AND SL.KEY1 = 'Tools'
								AND SL.KEY2 = 'Foreign Keys'
								AND SL.KEY3 = 'Ignore Tables'
								AND SL.VALUE = C.TABLE_NAME)
			AND NOT EXISTS (SELECT 1
							FROM SYSTEM_LABEL SL
							WHERE SL.MODEL_ID = 0
								AND SL.MODULE = 'System'
								AND SL.KEY1 = 'Tools'
								AND SL.KEY2 = 'Foreign Keys'
								AND SL.KEY3 = 'Ignore Constraints'
								AND SL.VALUE = C.CONSTRAINT_NAME)
		ORDER BY C.TABLE_NAME, C.CONSTRAINT_NAME;
	--====================================================================
	PROCEDURE PUT_LINE(p_LINE IN VARCHAR2 := NULL) AS
	BEGIN
		IF p_LINE IS NOT NULL THEN
			DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(p_LINE), p_LINE);
		END IF;
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(UTL_TCP.CRLF), UTL_TCP.CRLF);
	END PUT_LINE;
	--====================================================================
BEGIN
	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
	DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);

	-- now find all un-indexed constraints
	FOR v_CONSTRAINT IN cur_CONSTRAINTS LOOP

		SELECT COUNT(1)
		INTO v_COL_COUNT
		FROM USER_CONS_COLUMNS
		WHERE CONSTRAINT_NAME = v_CONSTRAINT.CONSTRAINT_NAME
			AND TABLE_NAME = v_CONSTRAINT.TABLE_NAME;

		BEGIN
			-- find out if any existing index already includes fields of the foreign key
			SELECT CNT
			INTO V_INDEXED_COL_COUNT
			FROM (SELECT COUNT(1) AS CNT, I.INDEX_NAME
					FROM USER_CONS_COLUMNS CC, USER_INDEXES I, USER_IND_COLUMNS IC
					WHERE CC.CONSTRAINT_NAME = v_CONSTRAINT.CONSTRAINT_NAME
						AND CC.TABLE_NAME = v_CONSTRAINT.TABLE_NAME
						AND I.TABLE_NAME = v_CONSTRAINT.TABLE_NAME
						AND IC.INDEX_NAME = I.INDEX_NAME
						AND IC.COLUMN_NAME = CC.COLUMN_NAME
					GROUP BY I.INDEX_NAME
					HAVING MIN(IC.COLUMN_POSITION) = 1 AND MAX(IC.COLUMN_POSITION) = v_COL_COUNT
					ORDER BY CNT DESC)
			WHERE ROWNUM=1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				V_INDEXED_COL_COUNT := 0;
		END;

		IF V_INDEXED_COL_COUNT < V_COL_COUNT THEN
			-- Needs an index
			PUT_LINE('/*==============================================================*/');
			PUT_LINE('/* INDEX: '||V_CONSTRAINT.CONSTRAINT_NAME||LPAD('*/',56-LENGTH(V_CONSTRAINT.CONSTRAINT_NAME),' '));
			PUT_LINE('/*==============================================================*/');
			PUT_LINE('CREATE INDEX '||V_CONSTRAINT.CONSTRAINT_NAME||' ON '||V_CONSTRAINT.TABLE_NAME||' (');
			V_COL_STR := NULL;
			FOR V_FK_COL IN (SELECT C.COLUMN_NAME
							 FROM USER_CONS_COLUMNS C
							 WHERE C.CONSTRAINT_NAME = V_CONSTRAINT.CONSTRAINT_NAME
								AND C.TABLE_NAME = V_CONSTRAINT.TABLE_NAME
							 ORDER BY C.POSITION) LOOP
				IF V_COL_STR IS NOT NULL THEN
					V_COL_STR := V_COL_STR||', ';
				END IF;
				V_COL_STR := V_COL_STR||V_FK_COL.COLUMN_NAME||' ASC';
			END LOOP;
			PUT_LINE('   '||V_COL_STR);
			PUT_LINE(')');
			PUT_LINE('STORAGE');
			PUT_LINE('(');
			PUT_LINE('    INITIAL 64K');
			PUT_LINE('    NEXT 64K');
			PUT_LINE('    PCTINCREASE 0');
			PUT_LINE(')');
			PUT_LINE('TABLESPACE NERO_INDEX');
			PUT_LINE('/');
			PUT_LINE;
			PUT_LINE;
		END IF;
	END LOOP;

	DBMS_LOB.CLOSE(v_RET);
	RETURN v_RET;
END;
-------------------------------------------------------------------------------
FUNCTION CONVERT_UNIT_OF_MEASURE
	(
	p_FROM_UOM	IN VARCHAR2,
	p_QUANTITY	IN NUMBER,
	p_TO_UOM	IN VARCHAR2
	) RETURN NUMBER IS
v_RET	NUMBER := p_QUANTITY;
BEGIN
	IF UPPER(p_FROM_UOM) IN ('KW','KWH','KVAR','KVARH','KVA','KVAH')
			AND UPPER(p_TO_UOM) = 'M'||UPPER(SUBSTR(p_FROM_UOM,2)) THEN
		-- kilo to mega
		v_RET := p_QUANTITY/1000;
	ELSIF UPPER(p_FROM_UOM) IN ('MW','MWH','MVAR','MVARH','MVA','MVAH')
			AND UPPER(p_TO_UOM) = 'K'||UPPER(SUBSTR(p_FROM_UOM,2)) THEN
		-- vice versa: mega to kilo
		v_RET := p_QUANTITY*1000;
	ELSIF UPPER(p_FROM_UOM) = 'THM' AND UPPER(p_TO_UOM) = 'DTH' THEN
		-- therms to decatherms
		v_RET := p_QUANTITY/10;
	ELSIF UPPER(p_FROM_UOM) = 'DTH' AND UPPER(p_TO_UOM) = 'THM' THEN
		-- vice versa: decatherms to therms
		v_RET := p_QUANTITY*10;
	ELSIF UPPER(p_FROM_UOM) <> UPPER(p_TO_UOM) AND LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Unable to convert '||p_QUANTITY||' '||p_FROM_UOM||' to '||p_TO_UOM);
	END IF;

	IF p_QUANTITY <> v_RET AND LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Converted '||p_QUANTITY||' '||p_FROM_UOM||' -> '||v_RET||' '||p_TO_UOM);
	END IF;

	RETURN v_RET;
END CONVERT_UNIT_OF_MEASURE;
----------------------------------------------------------------------------------------------------
FUNCTION CAN_CONVERT
    (
    p_FROM_UOM IN VARCHAR2,
    p_TO_UOM IN VARCHAR2
    ) RETURN BOOLEAN IS

BEGIN

    IF p_FROM_UOM = p_TO_UOM THEN
        RETURN TRUE;
    END IF;

    IF p_FROM_UOM IN ('KWH','KW','MW','MWH') AND
        p_TO_UOM IN ('KWH','KW','MW','MWH') THEN
        RETURN TRUE;
    END IF;

    IF p_FROM_UOM IN ('DTH', 'THM') AND p_TO_UOM IN ('DTH', 'THM') THEN
        RETURN TRUE;
    END IF;

    RETURN FALSE;

END CAN_CONVERT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_CONVERSION_FACTOR
    (
    p_FROM_UOM IN VARCHAR2,
    p_TO_UOM IN VARCHAR2,
    p_INTERVAL IN VARCHAR2
    ) RETURN NUMBER IS

    v_FROM_UOM VARCHAR2(32) := UPPER(p_FROM_UOM);
    v_TO_UOM VARCHAR2(32) := UPPER(p_TO_UOM);

    v_RESULT NUMBER := 1;
BEGIN
    IF NOT CAN_CONVERT(v_FROM_UOM,v_TO_UOM) THEN
        ERRS.RAISE_BAD_ARGUMENT('FROM UOM / TO UOM', v_FROM_UOM || ' / ' || v_TO_UOM,
            'Conversion from ' || v_FROM_UOM || ' to ' || v_TO_UOM || ' is not supported.');
    END IF;

    IF v_FROM_UOM = v_TO_UOM THEN
        RETURN 1;
    END IF;

    IF v_FROM_UOM = 'DTH' AND v_TO_UOM = 'THM' THEN
        RETURN 1/10;
    END IF;

    IF v_FROM_UOM = 'THM' AND v_TO_UOM = 'DTH' THEN
        RETURN 10;
    END IF;

    -- HAS TO HAVE AN SI PREFIX OF 'K' OR 'M' AT THIS POINT (only units we support at this point are KWH, KW, MWH, MW
    IF v_FROM_UOM IN ('MWH', 'MW') AND v_TO_UOM IN ('KW','KWH') THEN
        v_RESULT := 1000;
    ELSIF v_FROM_UOM IN ('KW','KWH') AND v_TO_UOM IN ('MW','MWH') THEN
        v_RESULT := 1/1000;
    END IF;

    IF SUBSTR(v_TO_UOM,2) = SUBSTR(v_FROM_UOM,2) || 'H' THEN
        v_RESULT := v_RESULT * DATE_UTIL.GET_INTERVAL_DIVISOR(CONSTANTS.INTERVAL_HOUR, p_INTERVAL);

    ELSIF SUBSTR(v_TO_UOM,2) || 'H' = SUBSTR(v_FROM_UOM,2) THEN
        v_RESULT := v_RESULT * 1/DATE_UTIL.GET_INTERVAL_DIVISOR(CONSTANTS.INTERVAL_HOUR, p_INTERVAL);
    END IF;

    RETURN v_RESULT;
END GET_CONVERSION_FACTOR;
----------------------------------------------------------------------------------------------------
PROCEDURE DUMMY(p_IMPORT_FILE IN OUT BLOB, p_IMPORT_FILE_PATH IN OUT VARCHAR2) AS BEGIN NULL; END;
----------------------------------------------------------------------------------------------------
PROCEDURE CONVERT_NUM_TBL_TO_COLLECTION
	(
	p_TABLE IN GA.NUMBER_TABLE,
	p_COLLECTION OUT NUMBER_COLLECTION
	) AS

BEGIN

	p_COLLECTION := NUMBER_COLLECTION();

	FOR v_IDX IN p_TABLE.FIRST..p_TABLE.LAST LOOP
		IF p_TABLE.EXISTS(v_IDX) THEN
			p_COLLECTION.EXTEND();
			p_COLLECTION(p_COLLECTION.LAST) := p_TABLE(v_IDX);
		END IF;
	END LOOP;

END CONVERT_NUM_TBL_TO_COLLECTION;
----------------------------------------------------------------------------------------------------
PROCEDURE CONVERT_COLLECTION_TO_NUM_TBL
	(
	p_COLLECTION IN NUMBER_COLLECTION,
	p_TABLE OUT GA.NUMBER_TABLE
	) AS

BEGIN

	FOR v_IDX IN 1..p_COLLECTION.COUNT LOOP
		p_TABLE(v_IDX) := p_COLLECTION(v_IDX);
	END LOOP;

END CONVERT_COLLECTION_TO_NUM_TBL;
----------------------------------------------------------------------------------------------------
PROCEDURE PRINT_CLOB
    (
    p_CLOB IN CLOB
    ) AS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;

BEGIN

    IF p_CLOB IS NULL THEN
        RETURN;
    END IF;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);

    FOR v_IDX IN v_LINES.FIRST .. v_LINES.LAST LOOP
        DBMS_OUTPUT.PUT_LINE(v_LINES(v_IDX));
    END LOOP;

END PRINT_CLOB;
----------------------------------------------------------------------------------------------------
FUNCTION GET_RATE_FOR_PERCENT_STRING
    (
    p_PERCENT_TEXT IN VARCHAR2
    ) RETURN NUMBER AS
    v_RATE_TEXT VARCHAR2(256);
    v_RATE NUMBER := NULL;
BEGIN

    IF TRIM(p_PERCENT_TEXT) IS NULL THEN
        RETURN NULL;
    END IF;

    v_RATE_TEXT := TRIM(p_PERCENT_TEXT);

    -- EXPECT A STRING IN THE FORMAT #%, ALL OTHERS ARE NOT VALID, JUST RETURN NULL
    IF SUBSTR(v_RATE_TEXT, LENGTH(v_RATE_TEXT), 1) = '%' THEN
        BEGIN
            v_RATE := TO_NUMBER(SUBSTR(v_RATE_TEXT,1,LENGTH(v_RATE_TEXT)-1))/100;
        EXCEPTION
            WHEN ERRS.e_NUM_VALUE_ERR THEN
                v_RATE := NULL;
        END;
    END IF;

    RETURN v_RATE;

END GET_RATE_FOR_PERCENT_STRING;
----------------------------------------------------------------------------------------------------
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
	) AS

	v_MAP	UT.STRING_MAP;

BEGIN

	IF p_COL_NAME1 IS NOT NULL THEN
		v_MAP(p_COL_NAME1) := p_COL_VALUE1;
	END IF;

	IF p_COL_NAME2 IS NOT NULL THEN
		v_MAP(p_COL_NAME2) := p_COL_VALUE2;
	END IF;

	IF p_COL_NAME3 IS NOT NULL THEN
		v_MAP(p_COL_NAME3) := p_COL_VALUE3;
	END IF;

	IF p_COL_NAME4 IS NOT NULL THEN
		v_MAP(p_COL_NAME4) := p_COL_VALUE4;
	END IF;

	IF p_COL_NAME5 IS NOT NULL THEN
		v_MAP(p_COL_NAME5) := p_COL_VALUE5;
	END IF;

	FORCIBLY_DELETE(p_TABLE_NAME, v_MAP);

END FORCIBLY_DELETE;
----------------------------------------------------------------------------------------------------
PROCEDURE FORCIBLY_DELETE(
	p_TABLE_NAME	IN VARCHAR2,
	p_COLUMNS		IN UT.STRING_MAP
	) AS

	------------------------------------
	-- Types

	-- A foreign key constraint
	TYPE t_FK IS RECORD (
		TABLE_NAME		VARCHAR2(30),
		COLUMN_NAMES	STRING_COLLECTION
	);
	-- List of foreign keys
	TYPE t_FK_LIST IS TABLE OF t_FK;

	-- A primary/key constraint definition. It includes
	-- the constraint columns and a list of referring
	-- foreign keys
	TYPE t_CONSTRAINT_INFO IS RECORD (
		COL_NAMES		STRING_COLLECTION,
		FOREIGN_KEYS	t_FK_LIST
	);

	-- map of primary/key constraints (key is the constraint name)
	TYPE t_CONSTRAINTS	IS TABLE OF t_CONSTRAINT_INFO INDEX BY VARCHAR2(61);

	-- map of column types in the table (key is the column name)
	TYPE t_COL_TYPES	IS TABLE OF VARCHAR2(6) INDEX BY VARCHAR2(30);

	-- Variables
	v_NUM_FKs		PLS_INTEGER;
	v_CONSTRAINTS	t_CONSTRAINTS;
	v_COLUMN_TYPES	t_COL_TYPES;
	v_COLUMNS		STRING_COLLECTION;
	v_IDX			PLS_INTEGER;
	v_TMP_COLS		STRING_COLLECTION;
	v_CUR_CONS		VARCHAR2(61);
	v_ROW_MAP		UT.STRING_MAP;
	v_RECURSE_MAP	UT.STRING_MAP;

	v_SQL			VARCHAR2(4000);
	v_WHERE			VARCHAR2(4000);

	v_ROW_COUNT		PLS_INTEGER;
	cur_RECS		GA.REFCURSOR;

BEGIN

	-- first build metadata about constraints
	v_COLUMNS := STRING_COLLECTION();
	v_NUM_FKs := 0;

	FOR v_CONS IN (SELECT OWNER||'.'||CONSTRAINT_NAME as FULL_CONSTRAINT_NAME,
						OWNER, CONSTRAINT_NAME
					FROM USER_CONSTRAINTS
					-- identify all primary/unique keys, which could
					-- be referenced by foreign keys
					WHERE TABLE_NAME = p_TABLE_NAME
						AND CONSTRAINT_TYPE IN ('U','P')) LOOP

		-- first build list of column names for the constraint
		v_TMP_COLS := STRING_COLLECTION();
		FOR v_CONS_COL IN (SELECT T.COLUMN_NAME,
								CASE WHEN T.DATA_TYPE LIKE '%CHAR%' THEN 'STRING'
									 WHEN T.DATA_TYPE = 'NUMBER' THEN 'NUMBER'
									 WHEN T.DATA_TYPE = 'DATE' THEN 'DATE'
									 ELSE '?' -- uh oh
									 END as TYPE
							FROM USER_CONS_COLUMNS C,
								USER_TAB_COLUMNS T
							WHERE C.OWNER = v_CONS.OWNER
								AND C.CONSTRAINT_NAME = v_CONS.CONSTRAINT_NAME
								AND T.TABLE_NAME = p_TABLE_NAME
								AND T.COLUMN_NAME = C.COLUMN_NAME
							ORDER BY C.POSITION) LOOP

			v_TMP_COLS.EXTEND();
			v_TMP_COLS(v_TMP_COLS.LAST) := v_CONS_COL.COLUMN_NAME;

			-- track distinct columns referenced by these constraints in
			-- the v_COLUMNS collection and store column types in map
			IF NOT v_COLUMN_TYPES.EXISTS(v_CONS_COL.COLUMN_NAME) THEN
				v_COLUMN_TYPES(v_CONS_COL.COLUMN_NAME) := v_CONS_COL.TYPE;
				v_COLUMNS.EXTEND();
				v_COLUMNS(v_COLUMNS.LAST) := v_CONS_COL.COLUMN_NAME;
			END IF;

		END LOOP;

		v_CONSTRAINTS(v_CONS.FULL_CONSTRAINT_NAME).COL_NAMES := v_TMP_COLS;

		-- now fetch definitions of referencing keys
		v_CONSTRAINTS(v_CONS.FULL_CONSTRAINT_NAME).FOREIGN_KEYS := t_FK_LIST();
		FOR v_REF_FK IN (SELECT TABLE_NAME, OWNER, CONSTRAINT_NAME
						  FROM USER_CONSTRAINTS
						  WHERE CONSTRAINT_TYPE = 'R'
						  	AND R_OWNER = v_CONS.OWNER
							AND R_CONSTRAINT_NAME = v_CONS.CONSTRAINT_NAME
							-- SET NULL and CASCADE keys clean themselves up
							-- but NO ACTION constraints are the ones we
							-- must explicitly "force" clean-up/deletion
							AND DELETE_RULE = 'NO ACTION') LOOP

			v_CONSTRAINTS(v_CONS.FULL_CONSTRAINT_NAME).FOREIGN_KEYS.EXTEND();
			v_IDX := v_CONSTRAINTS(v_CONS.FULL_CONSTRAINT_NAME).FOREIGN_KEYS.LAST;

			v_CONSTRAINTS(v_CONS.FULL_CONSTRAINT_NAME).FOREIGN_KEYS(v_IDX).TABLE_NAME := v_REF_FK.TABLE_NAME;

			-- now build list of columns for this constraint
			v_TMP_COLS := STRING_COLLECTION();
			FOR v_FK_COL IN (SELECT COLUMN_NAME
								FROM USER_CONS_COLUMNS
								WHERE OWNER = v_REF_FK.OWNER
									AND CONSTRAINT_NAME = v_REF_FK.CONSTRAINT_NAME
								ORDER BY POSITION) LOOP

				v_TMP_COLS.EXTEND();
				v_TMP_COLS(v_TMP_COLS.LAST) := v_FK_COL.COLUMN_NAME;

			END LOOP;

			v_CONSTRAINTS(v_CONS.FULL_CONSTRAINT_NAME).FOREIGN_KEYS(v_IDX).COLUMN_NAMES := v_TMP_COLS;
			v_NUM_FKs := v_NUM_FKs+1;

		END LOOP;

	END LOOP;

	-- Criteria for rows in specified table that we're deleting
	v_WHERE := UT.MAP_TO_WHERE_CLAUSE(p_COLUMNS);

	IF v_NUM_FKs = 0 THEN
		-- indicator to issue delete statement - no need to recurse since there
		-- are no referencing foreign keys
		v_ROW_COUNT := -1;

	ELSE
		-- Now build the list of rows that we're deleting

		FOR v_IDX IN v_COLUMNS.FIRST..v_COLUMNS.LAST LOOP
			IF v_SQL IS NOT NULL THEN
				v_SQL := v_SQL || ', ';
			END IF;
			v_SQL := v_SQL || 'UT.GET_LITERAL_FOR_' || v_COLUMN_TYPES(v_COLUMNS(v_IDX)) || '(' || v_COLUMNS(v_IDX) || ')';
		END LOOP;

		v_SQL := 'SELECT STRING_COLLECTION(' || v_SQL || ') FROM ' || p_TABLE_NAME;
		v_SQL := v_SQL || CASE WHEN v_WHERE IS NULL THEN NULL ELSE ' WHERE '||v_WHERE END;
		v_SQL := v_SQL || ' FOR UPDATE';

		-- Loop through the list and clean-up child entries
		v_ROW_COUNT := 0;
		OPEN cur_RECS FOR v_SQL;
		LOOP
			FETCH cur_RECS INTO v_TMP_COLS;
			EXIT WHEN cur_RECS%NOTFOUND;

			-- build a map that represents the current row/record
			v_ROW_MAP := UT.c_EMPTY_MAP; -- first reset
			FOR v_IDX IN v_COLUMNS.FIRST..v_COLUMNS.LAST LOOP
				v_ROW_MAP(v_COLUMNS(v_IDX)) := v_TMP_COLS(v_IDX);
			END LOOP;

			-- now, for each foreign key, forcibly delete referencing records
			v_CUR_CONS := v_CONSTRAINTS.FIRST;
			WHILE v_CONSTRAINTS.EXISTS(v_CUR_CONS) LOOP

				-- if any foreign keys referencing this constraint, recurse
				IF v_CONSTRAINTS(v_CUR_CONS).FOREIGN_KEYS.COUNT > 0 THEN

					FOR v_JDX IN v_CONSTRAINTS(v_CUR_CONS).FOREIGN_KEYS.FIRST..v_CONSTRAINTS(v_CUR_CONS).FOREIGN_KEYS.LAST LOOP

						v_RECURSE_MAP := UT.c_EMPTY_MAP; -- reset
						FOR v_KDX IN v_CONSTRAINTS(v_CUR_CONS).COL_NAMES.FIRST..v_CONSTRAINTS(v_CUR_CONS).COL_NAMES.FIRST LOOP
							v_RECURSE_MAP(v_CONSTRAINTS(v_CUR_CONS).FOREIGN_KEYS(v_JDX).COLUMN_NAMES(v_KDX)) := v_ROW_MAP(v_CONSTRAINTS(v_CUR_CONS).COL_NAMES(v_KDX));
						END LOOP;

						FORCIBLY_DELETE(v_CONSTRAINTS(v_CUR_CONS).FOREIGN_KEYS(v_JDX).TABLE_NAME, v_RECURSE_MAP);
					END LOOP;

				END IF;

				v_CUR_CONS := v_CONSTRAINTS.NEXT(v_CUR_CONS);
			END LOOP;

			v_ROW_COUNT := v_ROW_COUNT+1;
		END LOOP;

		CLOSE cur_RECS;

	END IF;

	-- Finally, delete the rows
	IF v_ROW_COUNT <> 0 THEN
		v_SQL := 'DELETE ' || p_TABLE_NAME || CASE WHEN v_WHERE IS NULL THEN NULL ELSE ' WHERE '||v_WHERE END;
		EXECUTE IMMEDIATE v_SQL;
	END IF;

END FORCIBLY_DELETE;
----------------------------------------------------------------------------------------------------
FUNCTION IS_NUMBER (p_NUMBER IN VARCHAR2)
RETURN BOOLEAN
IS
  v_NUMBER NUMBER;
  v_RET  BOOLEAN := TRUE;
BEGIN
  BEGIN
	 v_NUMBER := TO_NUMBER(p_NUMBER);
  EXCEPTION
	 WHEN OTHERS THEN
	 v_RET := FALSE;
  END;

  RETURN v_RET;
END IS_NUMBER;
----------------------------------------------------------------------------------------------------
-- This function was removed in an earlier version of the package body.
-- The VB code, when trying to poll the status of the job, was failing.
-- So we are putting in place this mock-up procedure.
PROCEDURE MONITOR_PROCESS_PROGRESS(
	p_PROCESS_ID		IN 	NUMBER,
	p_PROGRESS_PERCENT	OUT	NUMBER,
	p_PROCESS_STATE		OUT	VARCHAR,
	p_STATUS			OUT	NUMBER
	) AS
BEGIN
	p_PROGRESS_PERCENT	:=	0;
	p_PROCESS_STATE		:=	'Job Scheduling Complete';
	p_STATUS			:=	0;
END MONITOR_PROCESS_PROGRESS;
----------------------------------------------------------------------------------------------------
-- This function was removed in an earlier version of the package body.
-- The VB code, when trying to terminate the job, was failing.
-- So we are putting in place this mock-up procedure.
PROCEDURE TERMINATE_PROCESS(
	p_PROCESS_ID		IN 	NUMBER,
	p_STATUS			OUT	NUMBER
	) AS
BEGIN
	p_STATUS	:=	0;
END TERMINATE_PROCESS;
----------------------------------------------------------------------------------------------------
END UT;
/
