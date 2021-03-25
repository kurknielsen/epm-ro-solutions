CREATE OR REPLACE PACKAGE BODY MM_NYISO_BIDPOST IS

	-- the trait categories are to be used for reports
	g_TRAIT_CATEGORY_LOAD CONSTANT VARCHAR2(32) := 'NYISO: Load';
	g_TRAIT_CATEGORY_GEN CONSTANT VARCHAR2(32) := 'NYISO: Gen';
	g_TRAIT_CATEGORY_VIRTUAL CONSTANT VARCHAR2(32) := 'NYISO: Virtual';

	g_TRAN_TYPE_LOAD CONSTANT VARCHAR2(32) := 'Load';
	g_TRAN_TYPE_GEN CONSTANT VARCHAR2(32) := 'Gen';

	g_LOAD_TYPE_VL CONSTANT NUMBER(1) := 1;
	g_LOAD_TYPE_VS CONSTANT NUMBER(1) := 2;
	g_LOAD_TYPE_PL CONSTANT NUMBER(1) := 3;

	g_QUERY_TYPE_ALL CONSTANT NUMBER(1) := 0;
	g_QUERY_TYPE_VL CONSTANT NUMBER(1) := 1;
	g_QUERY_TYPE_VS CONSTANT NUMBER(1) := 2;
	g_QUERY_TYPE_PL CONSTANT NUMBER(1) := 3;

	g_NODE_TYPE_BUS CONSTANT VARCHAR(32) := 'Bus';
	g_NODE_TYPE_AGG CONSTANT VARCHAR(32) := 'Aggregate';
	g_NODE_TYPE_GEN CONSTANT VARCHAR(32) := 'Generator';

	g_ET_QUERY_PHYSICAL_LOAD VARCHAR(64) := 'Query Physical and Virtual Load Bids';
	g_ET_SUBMIT_PHYSICAL_LOAD VARCHAR(64) := 'Submit Physical and Virtual Load Bids';

	NEWLINE CONSTANT VARCHAR2(2) := CHR(13);
	--g_RVW_STATUS_PENDING CONSTANT VARCHAR2(16) := 'Pending';
	g_RVW_STATUS_ACCEPTED CONSTANT VARCHAR2(16) := 'Accepted';

	--g_SUBMIT_STATUS_PENDING CONSTANT VARCHAR2(16) := 'Pending';
	--g_SUBMIT_STATUS_SUBMITTED CONSTANT VARCHAR2(16) := 'Submitted';
	--g_SUBMIT_STATUS_FAILED CONSTANT VARCHAR2(16) := 'Rejected';

	--g_MKT_STATUS_PENDING CONSTANT VARCHAR2(16) := 'Pending';
	--g_MKT_STATUS_ACCEPTED CONSTANT VARCHAR2(16) := 'Accepted';
	--g_MKT_STATUS_REJECTED CONSTANT VARCHAR2(16) := 'Rejected';

	TYPE DATE_RANGE_RECORD IS RECORD(
		TRANSACTION_ID NUMBER,
		BEGIN_DATE     DATE,
		END_DATE       DATE);
	TYPE DATE_RANGE_TYPE IS TABLE OF DATE_RANGE_RECORD INDEX BY BINARY_INTEGER;

	TYPE DATE_PAIRS_TYPE IS RECORD(
		BEGIN_DATE DATE,
		END_DATE   DATE);
	TYPE DATE_TABLE_TYPE IS TABLE OF DATE_PAIRS_TYPE INDEX BY BINARY_INTEGER;

	TYPE t_TRAITS IS VARRAY(32) OF VARCHAR2(32);

/*	g_GENERATOR_TRAITS t_TRAITS := t_TRAITS(
		MM_NYISO_UTIL.g_TG_UPPER_OPERATING_LIMIT,
		MM_NYISO_UTIL.g_TG_EMERGENCY_OPERATING_LIMIT,
		MM_NYISO_UTIL.g_TG_STARTUP_COST,
		MM_NYISO_UTIL.g_TG_BID_SCHEDULE_TYPE_ID,
		MM_NYISO_UTIL.g_TG_SELF_COMMITTED_MW_00,
		MM_NYISO_UTIL.g_TG_SELF_COMMITTED_MW_15,
		MM_NYISO_UTIL.g_TG_SELF_COMMITTED_MW_30,
		MM_NYISO_UTIL.g_TG_SELF_COMMITTED_MW_45,
		MM_NYISO_UTIL.g_TG_FIXED_MIN_GENERATION_MW,
		MM_NYISO_UTIL.g_TG_FIXED_MIN_GENERATION_COST,
		MM_NYISO_UTIL.g_TG_DISPATCH_MW,
		MM_NYISO_UTIL.g_TG_10_MIN_NON_SYNC_COST,
		MM_NYISO_UTIL.g_TG_10_MIN_SPINNING_COST,
		MM_NYISO_UTIL.g_TG_30_MIN_NON_SYNC_COST,
		MM_NYISO_UTIL.g_TG_30_MIN_SPINNING_COST,
		MM_NYISO_UTIL.g_TG_REGULATION_MW,
		MM_NYISO_UTIL.g_TG_REGULATION_COST);*/

	-- IDT is not using interruptible information
	-- commented out so it will not display

	g_LOAD_TRAITS t_TRAITS := t_TRAITS(
		MM_NYISO_UTIL.g_TG_FORECAST_MW,
		MM_NYISO_UTIL.g_TG_FIXED_MW,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_1,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_1,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_2,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_2,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_3,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_3,
		--MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_TYPE,
		--MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_FIXED,
		--MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_CAPPED,
		MM_NYISO_UTIL.g_TG_TRANSACTION_BID_ID);

	g_LOAD_TRAITS_VIRTUAL t_TRAITS := t_TRAITS(
		MM_NYISO_UTIL.g_TG_PRICE_CAP_1,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_1,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_2,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_2,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_3,
		MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_3,
		MM_NYISO_UTIL.g_TG_TRANSACTION_BID_ID);

-----------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_TRAITS_FOR_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_REPORT_TYPE IN VARCHAR2,
	p_TRAIT_GROUP_FILTER IN VARCHAR2,
	p_INTERVAL IN VARCHAR2,
	p_WORK_ID OUT NUMBER
	) AS

	v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
	v_TRAITS t_TRAITS;

BEGIN
		UT.GET_RTO_WORK_ID(p_WORK_ID);

		-- NYISO types of bids are:
		--
		-- Physical Load Bid
		-- Virtual Load Bid
		-- Virtual Supply Bid
		-- Generator Bid
		-- Bilateral Transaction Bid
		--
		-- 'Physical' or 'Virtual' and 'Load' or 'Gen'

		SELECT * INTO v_TRANSACTION
		FROM INTERCHANGE_TRANSACTION
		WHERE TRANSACTION_ID = p_TRANSACTION_ID;

		--dbms_output.put_line (v_TRANSACTION.TRANSACTION_TYPE || ',' || v_TRANSACTION.TRANSACTION_NAME);


		CASE
		WHEN v_TRANSACTION.TRANSACTION_TYPE = g_TRAN_TYPE_LOAD
			AND v_TRANSACTION.TRANSACTION_NAME LIKE '%Virtual Bid' THEN
			-- virtual load bid

			v_TRAITS := g_LOAD_TRAITS_VIRTUAL;

			FOR i IN 1 .. v_TRAITS.COUNT
			LOOP
				INSERT INTO RTO_WORK(WORK_ID, WORK_SEQ, WORK_XID)
				VALUES(p_WORK_ID, 1, v_TRAITS(i));
			END LOOP;

    	WHEN v_TRANSACTION.TRANSACTION_TYPE = g_TRAN_TYPE_LOAD
			AND v_TRANSACTION.TRANSACTION_NAME LIKE '%Physical Bid' THEN
			-- physical load bid

			v_TRAITS := g_LOAD_TRAITS;

			FOR i IN 1 .. v_TRAITS.COUNT
			LOOP
				INSERT INTO RTO_WORK(WORK_ID, WORK_SEQ, WORK_XID)
				VALUES(p_WORK_ID, 1, v_TRAITS(i));
			END LOOP;


		WHEN v_TRANSACTION.TRANSACTION_TYPE = g_TRAN_TYPE_GEN
			AND v_TRANSACTION.TRANSACTION_NAME LIKE '%Virtual Bid' THEN
			-- virtual supply bid

			v_TRAITS := g_LOAD_TRAITS_VIRTUAL;

			FOR i IN 1 .. v_TRAITS.COUNT
			LOOP
				INSERT INTO RTO_WORK(WORK_ID, WORK_SEQ, WORK_XID)
				VALUES(p_WORK_ID, 1, v_TRAITS(i));
			END LOOP;

		ELSE
			-- everything else
			INSERT INTO RTO_WORK(WORK_ID, WORK_SEQ, WORK_XID)
			SELECT p_WORK_ID, B.TRAIT_INDEX, A.TRAIT_GROUP_ID
			FROM TRANSACTION_TRAIT_GROUP A, TRANSACTION_TRAIT B
			WHERE (A.SC_ID = -1 OR A.SC_ID = v_TRANSACTION.SC_ID)
				AND v_TRANSACTION.TRAIT_CATEGORY LIKE A.TRAIT_CATEGORY
				AND (A.TRAIT_GROUP_TYPE = '%' OR A.TRAIT_GROUP_TYPE LIKE p_TRAIT_GROUP_FILTER)
				AND B.TRAIT_GROUP_ID = A.TRAIT_GROUP_ID;

		END CASE;

END GET_TRAITS_FOR_TRANSACTION;
----------------------------------------------------------------------------------------------------
--- populate the load table for one day for the transaction
PROCEDURE POPULATE_LOAD_TABLE
(
    p_RECORDS IN OUT NOCOPY MEX_NY_PHYSICAL_LOAD_TBL,
    p_TRANSACTION_ID IN NUMBER,
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
) AS

v_RECORD MEX_NY_PHYSICAL_LOAD;
v_TRAIT_GROUP_ID IT_TRAIT_SCHEDULE.TRAIT_GROUP_ID%TYPE;
v_TRAIT_INDEX IT_TRAIT_SCHEDULE.TRAIT_INDEX%TYPE;
v_TRAIT_VALUE IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;
v_TRAIT_SET IT_TRAIT_SCHEDULE.SET_NUMBER%TYPE;
v_START_DATE DATE;
v_END_DATE DATE;
v_NULL_RECORD MEX_NY_PHYSICAL_LOAD := MEX_NY_PHYSICAL_LOAD
    		(NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    		 NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,
    		 NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
    		);

CURSOR cur IS
	SELECT i.SCHEDULE_DATE, i.TRAIT_GROUP_ID, i.TRAIT_INDEX, i.SET_NUMBER, i.TRAIT_VAL, s.EXTERNAL_IDENTIFIER
	FROM IT_TRAIT_SCHEDULE i, INTERCHANGE_TRANSACTION t, SERVICE_POINT s
	WHERE i.TRANSACTION_ID = p_TRANSACTION_ID
	AND t.TRANSACTION_ID = p_TRANSACTION_ID
	AND i.SCHEDULE_STATE = 1
	AND t.POD_ID = s.SERVICE_POINT_ID
	AND SCHEDULE_DATE BETWEEN v_START_DATE AND v_END_DATE
	ORDER BY SCHEDULE_DATE, TRAIT_GROUP_ID, SET_NUMBER;

BEGIN

		-- assumes input date range is standard hour ending


    		v_START_DATE := p_BEGIN_DATE;
			v_END_DATE := p_END_DATE;
    		v_RECORD := v_NULL_RECORD;

        	--dbms_output.put_line(to_char(p_TRANSACTION_ID) || ',' ||
			--to_char(v_START_DATE, 'mm/dd/yyyy HH24:MI') || ',' ||
			--to_char(v_END_DATE, 'mm/dd/yyyy HH24:MI') );

    		FOR r IN cur LOOP

        		-- when date changes then add to collection and start new record
        		IF v_RECORD.LOAD_DATE IS NOT NULL THEN
        			IF v_RECORD.LOAD_DATE != r.SCHEDULE_DATE THEN
            			-- save last record
            		    p_RECORDS.EXTEND;
                		p_RECORDS(p_RECORDS.LAST) := v_RECORD;
            			-- start a new record
            			v_RECORD := v_NULL_RECORD;
        			END IF;
        		END IF;

        		IF v_RECORD.LOAD_DATE IS NULL THEN
        			v_RECORD.LOAD_NID := r.EXTERNAL_IDENTIFIER;
            		v_RECORD.LOAD_DATE := r.SCHEDULE_DATE;
        		END IF;

        		v_TRAIT_GROUP_ID := r.trait_group_id;
				v_TRAIT_INDEX := r.trait_index;
        		v_TRAIT_SET := r.set_number;
        		v_TRAIT_VALUE := r.trait_val;

        		CASE
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_FORECAST_MW THEN
        			v_RECORD.FORECAST_MW := v_TRAIT_VALUE;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_FIXED_MW THEN
        			v_RECORD.FIXED_MW := v_TRAIT_VALUE;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_PRICE_CAP_1 THEN
					IF v_TRAIT_INDEX = MM_NYISO_UTIL.g_TT_COST THEN
        				v_RECORD.PRICE_CAP_1_DOLLAR := v_TRAIT_VALUE;
					ELSE
						v_RECORD.PRICE_CAP_1_MW := v_TRAIT_VALUE;
        			END IF;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_PRICE_CAP_2 THEN
					IF v_TRAIT_INDEX = MM_NYISO_UTIL.g_TT_COST THEN
        				v_RECORD.PRICE_CAP_2_DOLLAR := v_TRAIT_VALUE;
					ELSE
						v_RECORD.PRICE_CAP_2_MW := v_TRAIT_VALUE;
        			END IF;
				WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_PRICE_CAP_3 THEN
					IF v_TRAIT_INDEX = MM_NYISO_UTIL.g_TT_COST THEN
        				v_RECORD.PRICE_CAP_3_DOLLAR := v_TRAIT_VALUE;
					ELSE
						v_RECORD.PRICE_CAP_3_MW := v_TRAIT_VALUE;
        			END IF;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_TYPE THEN
        			v_RECORD.INTERRUPTIBLE_TYPE := v_TRAIT_VALUE;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_FIXED
					AND v_TRAIT_INDEX = MM_NYISO_UTIL.g_TT_MW THEN
        			v_RECORD.INTERRUPTIBLE_FIXED_MW := v_TRAIT_VALUE;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_FIXED
					AND v_TRAIT_INDEX = MM_NYISO_UTIL.g_TT_COST THEN
        			v_RECORD.INTERRUPTIBLE_FIXED_COST := v_TRAIT_VALUE;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_CAPPED
					AND v_TRAIT_INDEX = MM_NYISO_UTIL.g_TT_MW THEN
        			v_RECORD.INTERRUPTIBLE_CAPPED_MW := v_TRAIT_VALUE;
        		WHEN v_TRAIT_GROUP_ID = MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_CAPPED
					AND v_TRAIT_INDEX = MM_NYISO_UTIL.g_TT_COST THEN
        			v_RECORD.INTERRUPTIBLE_CAPPED_COST := v_TRAIT_VALUE;
        		ELSE
        			NULL;
        		END CASE;
            		--dbms_output.put_line (to_char(p_BEGIN_DATE,'mm/dd/yyyy HH24:MI:SS') || ',' || to_char(v_TRAIT_VALUE));
    		END LOOP;

    		-- last record
    		IF v_RECORD.LOAD_DATE IS NOT NULL THEN
    		    p_RECORDS.EXTEND;
        		p_RECORDS(p_RECORDS.LAST) := v_RECORD;
    		END IF;


END POPULATE_LOAD_TABLE;
-------------------------------------------------------------------------------------
PROCEDURE UPDATE_TRAIT_SCHEDULE_STATUS
	(
	p_DATE			IN DATE,
	p_TXN_ID		IN NUMBER,
	p_SUBMIT_STATUS IN VARCHAR2,
	p_MARKET_STATUS IN VARCHAR2,
	p_PROCESS_MESSAGE IN VARCHAR2
	) AS

BEGIN
/*	IF NOT SD.GET_ENTITY_IS_ALLOWED(SD.g_ACTION_BAO_UPDATE, p_TXN_ID) THEN
		RAISE TG.INSUFFICIENT_PRIVILEGES;
	END IF;*/

	UPDATE IT_TRAIT_SCHEDULE_STATUS
	SET     SUBMIT_STATUS = p_SUBMIT_STATUS,
            SUBMIT_DATE = SYSDATE,
            SUBMITTED_BY_ID = SECURITY_CONTROLS.CURRENT_USER_ID,
            MARKET_STATUS = p_MARKET_STATUS,
            MARKET_STATUS_DATE = SYSDATE,
			PROCESS_MESSAGE = p_PROCESS_MESSAGE
	WHERE TRANSACTION_ID = P_TXN_ID
	AND SCHEDULE_DATE = p_DATE;

	EXCEPTION WHEN OTHERS THEN
		NULL;

END UPDATE_TRAIT_SCHEDULE_STATUS;

	----------------------------------------------------------------------------
	PROCEDURE SEND_FAKE_REQUEST(p_REQUEST_TEXT  IN CLOB,
															p_RESPONSE_TEXT IN OUT NOCOPY CLOB) IS
		l_RESPONSE_CLOB  CLOB;
		l_MSG            VARCHAR2(1000);
		l_REQUEST_LINES  GA.BIG_STRING_TABLE;
		l_REQUEST_HEADER GA.STRING_TABLE;
		l_TOGGLE         BOOLEAN := FALSE;
	BEGIN
		DBMS_LOB.CREATETEMPORARY(l_RESPONSE_CLOB, TRUE);
		DBMS_LOB.OPEN(l_RESPONSE_CLOB, DBMS_LOB.LOB_READWRITE);

		-- parse the request (it's delimited by newlines)
		UT.TOKENS_FROM_BIG_STRING(p_REQUEST_TEXT, NEWLINE, l_REQUEST_LINES);

		-- parse the request header (it's delimited by ampersands)
		UT.TOKENS_FROM_STRING(l_REQUEST_LINES(l_REQUEST_LINES.FIRST),
													'&',
													l_REQUEST_HEADER);

		-- add the header to the response (date, bid type, number of records)
		l_MSG := TO_CHAR(SYSDATE, 'MM/DD/YYYY HH24:MI') || NEWLINE;
		l_MSG := l_MSG || l_REQUEST_HEADER(l_REQUEST_HEADER.FIRST) || NEWLINE;
		l_MSG := l_MSG || l_REQUEST_HEADER(l_REQUEST_HEADER.LAST - 1) ||
						 NEWLINE;
		DBMS_LOB.WRITEAPPEND(l_RESPONSE_CLOB, LENGTH(l_MSG), l_MSG);

		-- add the bid id, bid status, and message to each submission, and add to response
		FOR i IN l_REQUEST_LINES.FIRST + 1 .. l_REQUEST_LINES.LAST LOOP
			-- handle empty records (blank lines in the input)
			IF l_REQUEST_LINES(i) IS NOT NULL THEN
				DBMS_LOB.WRITEAPPEND(l_RESPONSE_CLOB,
														 LENGTH(l_REQUEST_LINES(i)),
														 l_REQUEST_LINES(i));
				IF l_TOGGLE THEN
					l_MSG := TO_CHAR(i + 1000) ||
									 ',VALIDATION FAILED,VALIDATION FAILED MESSAGE GOES HERE';
				ELSE
					l_MSG := TO_CHAR(i + 1000) || ',VALIDATION SUCCEEDED,';
				END IF;
				l_TOGGLE := NOT l_TOGGLE;
				l_MSG    := l_MSG || NEWLINE;
				DBMS_LOB.WRITEAPPEND(l_RESPONSE_CLOB, LENGTH(l_MSG), l_MSG);
			END IF;
		END LOOP;

		-- add the submission + extra to the request
		p_RESPONSE_TEXT := l_RESPONSE_CLOB;
	END;

--------------------------------------------------------------------------------------
/*
This function takes in a begin date, and end date, a pl/sql table of submitted hours,
a bid offer id and a transaction id. It filters the pl/sql table of submitted hours
returns a pl/sql table with only the hours whose bid offer status is 'Accepted' based
on their bid offer id, transaction id and the particular time stamp.
Karan Chopra  */
----------------------------------------------------------------------------------------

FUNCTION FILTER_SUBMIT_HOURS(p_BEGIN_DATE     IN DATE,
															 p_END_DATE       IN DATE,
															 p_SUBMIT_HOURS   IN GA.ID_TABLE,
															 p_TRANSACTION_ID IN NUMBER) RETURN GA.ID_TABLE IS

		l_FILTERED_HOURS GA.ID_TABLE;
		l_SUBMIT_DATE    DATE;
		l_STATUS         VARCHAR2(16);
		l_SUBMIT_INDEX   BINARY_INTEGER := p_SUBMIT_HOURS.FIRST;
		l_FILTERED_INDEX BINARY_INTEGER := 1;

BEGIN

		-- Looping through each submitted hour
		-- assumes standard hour ending

		WHILE (p_SUBMIT_HOURS.EXISTS(l_SUBMIT_INDEX)) LOOP

			-- Creating the submit date based on the begin date and the hour value
			-- but the array is composed of 1 or 0 so must use the index
			IF p_SUBMIT_HOURS(l_SUBMIT_INDEX)  = 1 THEN

			l_SUBMIT_DATE := p_BEGIN_DATE + l_SUBMIT_INDEX/24;

			BEGIN

				-- Getting the bid offer status for that hour for the particular bid offer id
				-- for the specific transaction id
				-- the ITS.SCHEDULE_DATE is in CUT TIME
				SELECT ITS.REVIEW_STATUS
					INTO l_STATUS
					FROM IT_TRAIT_SCHEDULE_STATUS ITS
				   WHERE ITS.TRANSACTION_ID = p_TRANSACTION_ID
				     AND ITS.SCHEDULE_DATE = l_SUBMIT_DATE;

				-- Checking if the status is null
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					l_STATUS := NULL;

			END;
			--dbms_output.put_line(to_char(l_SUBMIT_DATE,'mm/dd/yyyy HH24:MI') || ',' || l_STATUS);
			-- If the status is 'Accepted' then add it to the table to be returned
			IF (NVL(l_STATUS, '') = g_RVW_STATUS_ACCEPTED) THEN
				l_FILTERED_HOURS(l_FILTERED_INDEX) := l_SUBMIT_INDEX;
				l_FILTERED_INDEX := l_FILTERED_INDEX + 1;
			END IF;

			END IF;

			l_SUBMIT_INDEX := p_SUBMIT_HOURS.NEXT(l_SUBMIT_INDEX);

		END LOOP;

		RETURN l_FILTERED_HOURS;

END;

/*----------------------------------------------------------------------------------
-- This function takes in the Begin Date, End Date and the Bid Submit Hours. It
-- generates Begin and End Date and time pairs for the hours submitted for each day
-- within the specified date range
-- Karan Chopra
10-May-2004, jbc: fix to Bug 6145 (load bids don't have duration). Added a
conditional to the innermost WHILE loop to just add the hour to the list if the
action type is for load bids.
----------------------------------------------------------------------------------*/
FUNCTION GET_DATE_PAIRS(p_BEGIN_DATE     IN DATE,
									p_END_DATE       IN DATE,
									p_SUBMIT_HOURS   IN VARCHAR2,
									p_TRANSACTION_ID IN NUMBER) RETURN DATE_TABLE_TYPE IS

l_SUBMIT_HOURS       VARCHAR2(2000);
l_HOURS_TEMP         GA.ID_TABLE;
l_SUBMIT_HOURS_TABLE GA.ID_TABLE;
l_CURR_DATE          DATE := p_BEGIN_DATE;
l_CURR_DATE_CUT		 DATE;
l_DATE_INDEX         BINARY_INTEGER := 1;
l_HOURS_INDEX        BINARY_INTEGER;

p_DATE_TABLE DATE_TABLE_TYPE;
v_TEST_DATE DATE;
v_TIME_ZONE VARCHAR2(3);
v_BEGIN_DATE_CUT DATE; -- standard hour ending
v_END_DATE_CUT DATE; -- standard hour ending

BEGIN

    -- the p_SUBMIT_HOURS is formatted as a comma seperated string or 1 or 0
    -- there may be 23, 24, or 25 values in it.
    -- when using DST:
    -- for the spring ahead day, ignore the third value if there are 24 values
    -- on the spring ahead day there are 23 hours
    -- on the fall back day there are 25 hours

    -- Removes the quotes around the numbers in the string
    l_SUBMIT_HOURS := REPLACE(p_SUBMIT_HOURS, '''', '');

    -- Creates a temporary table that has all the submitted hours
    UT.IDS_FROM_STRING(l_SUBMIT_HOURS, ',', l_HOURS_TEMP);
      -- Get TimeZone from the User_Preferences

    SP.GET_TIME_ZONE(v_TIME_ZONE);

    IF v_TIME_ZONE = DST_TIME_ZONE(v_TIME_ZONE) THEN
    		v_TEST_DATE := TRUNC(p_BEGIN_DATE);

    		IF v_TEST_DATE = TRUNC(DST_FALL_BACK_DATE(p_BEGIN_DATE)) THEN
    			-- should have 25 values
    			IF NOT l_HOURS_TEMP.COUNT = 25 THEN
    				NULL; -- error, but ignore
    			END IF;
    		ELSIF v_TEST_DATE = TRUNC(DST_SPRING_AHEAD_DATE(p_BEGIN_DATE)) THEN
    			-- should have 23 or 24 values
                IF l_HOURS_TEMP.COUNT = 24 THEN
    				-- remove third value spring ahead SKIP hour
    				l_HOURS_TEMP.DELETE(3);
    				NULL;
                ELSIF NOT l_HOURS_TEMP.COUNT = 23 THEN
                	NULL; -- error, but ignore
                END IF;
    		END IF;
    END IF;

    -- convert to standard hour ending time for filter_submit_hours
    v_BEGIN_DATE_CUT := TO_CUT(p_BEGIN_DATE, MEX_NYISO.g_NYISO_TIME_ZONE);
    v_END_DATE_CUT := TO_CUT(p_END_DATE, MEX_NYISO.g_NYISO_TIME_ZONE);

    -- Removing hours that for which the bid offer submit status is not set
    -- to 'Accepted' and storing them in the l_SUBMIT_HOURS_TABLE
    l_SUBMIT_HOURS_TABLE := FILTER_SUBMIT_HOURS(v_BEGIN_DATE_CUT,
    								v_END_DATE_CUT,
    								l_HOURS_TEMP,
    								p_TRANSACTION_ID);

    -- l_SUBMIT_HOURS_TABLE is a set of flags per hour

    -- Checking if the table of submitted hours is empty
    IF (l_SUBMIT_HOURS_TABLE.FIRST IS NULL) THEN
    RETURN p_DATE_TABLE;
    END IF;

    -- looping for each day in the date range, midnight local time
    WHILE (l_CURR_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) LOOP

    l_HOURS_INDEX := l_SUBMIT_HOURS_TABLE.FIRST;
    -- Adding the first time for the day as a begin date
    -- after converting to CUT
    l_CURR_DATE_CUT := TO_CUT(l_CURR_DATE, MEX_NYISO.g_NYISO_TIME_ZONE);

    p_DATE_TABLE(l_DATE_INDEX).BEGIN_DATE := l_CURR_DATE_CUT + (l_HOURS_INDEX / 24);

    WHILE (l_HOURS_INDEX != l_SUBMIT_HOURS_TABLE.LAST) LOOP
    -- looping for each hour that was submitted
    --IF p_ACTION = 'NYISO: Load Bid' THEN
    	-- load bids need a record for each hour in the bid submission range
    	p_DATE_TABLE(l_DATE_INDEX) .END_DATE := p_DATE_TABLE(l_DATE_INDEX).BEGIN_DATE;
    	l_DATE_INDEX := l_DATE_INDEX + 1;
    	l_HOURS_INDEX := l_SUBMIT_HOURS_TABLE.NEXT(l_HOURS_INDEX);
    	p_DATE_TABLE(l_DATE_INDEX) .BEGIN_DATE := l_CURR_DATE_CUT +	(l_HOURS_INDEX / 24);
    /*				ELSE
    	-- generation bids take a duration, so we figure out start and
    	-- end dates based on consecutive hours in the submit hours list.
    	IF ((l_SUBMIT_HOURS_TABLE(l_HOURS_INDEX) + 1) !=
    		 l_SUBMIT_HOURS_TABLE(l_SUBMIT_HOURS_TABLE.NEXT(l_HOURS_INDEX))) THEN
    		p_DATE_TABLE(l_DATE_INDEX) .END_DATE := l_CURR_DATE + (l_HOURS_INDEX / 24);
    		l_DATE_INDEX := l_DATE_INDEX + 1;
    		l_HOURS_INDEX := l_SUBMIT_HOURS_TABLE.NEXT(l_HOURS_INDEX);
    		p_DATE_TABLE(l_DATE_INDEX) .BEGIN_DATE := l_CURR_DATE +	(l_HOURS_INDEX / 24);
    	ELSE
    		l_HOURS_INDEX := l_SUBMIT_HOURS_TABLE.NEXT(l_HOURS_INDEX);
    	END IF;
    END IF;*/
    END LOOP;

    p_DATE_TABLE(l_DATE_INDEX) .END_DATE := l_CURR_DATE_CUT + (l_HOURS_INDEX/ 24);

    l_DATE_INDEX := l_DATE_INDEX + 1;
    l_CURR_DATE  := l_CURR_DATE + 1;

    END LOOP;

RETURN p_DATE_TABLE;

END;

/*-----------------------------------------------------------------------------------------------
-- This Procedure takes in Transaction IDs that are in a pl/sql table (GA.STRING_TABLE),
-- Bid Offer ID, A Begin Date, An End Date, A list of submitted hours, Action and returns
-- a pl/sql table with each record having a Trasaction Id and a Begin and End Date associated
-- with this Transaction Id that will represent the Begin and End Dates for a Bid Submission.
-- Karan Chopra.
-----------------------------------------------------------------------------------------------*/
FUNCTION GET_DATE_RANGE(p_TRANSACTION_IDS_LIST IN GA.STRING_TABLE,
													p_BEGIN_DATE     IN DATE,
													p_END_DATE       IN DATE,
													p_SUBMIT_HOURS   IN VARCHAR2)
		RETURN DATE_RANGE_TYPE IS

		l_DATE_PAIRS        DATE_TABLE_TYPE;
		l_TRANSACTION_INDEX BINARY_INTEGER := p_TRANSACTION_IDS_LIST.FIRST;
		l_DATE_PAIRS_INDEX  BINARY_INTEGER;
		l_DATE_RANGE_INDEX  BINARY_INTEGER := 1;
		p_DATE_RANGE_TABLE  DATE_RANGE_TYPE;
BEGIN

		-- LOOP OVER EACH TRANSACTION ID
		WHILE (p_TRANSACTION_IDS_LIST.EXISTS(l_TRANSACTION_INDEX)) LOOP

			-- The GET_DATE_PAIRS procedure obtains the begin and end date pairs for the hours
			-- that were submitted. These are stored in the l_DATE_PAIRS pl/sql table

			-- input date range, midnight local time
			-- output list dates are in CUT time
			l_DATE_PAIRS := GET_DATE_PAIRS(p_BEGIN_DATE,
										 p_END_DATE,
										 p_SUBMIT_HOURS,
										 TO_NUMBER(p_TRANSACTION_IDS_LIST(l_TRANSACTION_INDEX)));

			l_DATE_PAIRS_INDEX := l_DATE_PAIRS.FIRST;

			-- LOOP OVER EACH DATE PAIR OF THE HOURS SUBMITTED
			-- these dates are in CUT time

			WHILE (l_DATE_PAIRS.EXISTS(l_DATE_PAIRS_INDEX)) LOOP

                p_DATE_RANGE_TABLE(l_DATE_RANGE_INDEX).TRANSACTION_ID := TO_NUMBER(p_TRANSACTION_IDS_LIST(l_TRANSACTION_INDEX));
                p_DATE_RANGE_TABLE(l_DATE_RANGE_INDEX) .BEGIN_DATE := l_DATE_PAIRS(l_DATE_PAIRS_INDEX).BEGIN_DATE;
                p_DATE_RANGE_TABLE(l_DATE_RANGE_INDEX) .END_DATE   := l_DATE_PAIRS(l_DATE_PAIRS_INDEX).END_DATE;

                l_DATE_RANGE_INDEX := l_DATE_RANGE_INDEX + 1;
				l_DATE_PAIRS_INDEX := l_DATE_PAIRS.NEXT(l_DATE_PAIRS_INDEX);

			END LOOP;

			l_TRANSACTION_INDEX := p_TRANSACTION_IDS_LIST.NEXT(l_TRANSACTION_INDEX);

		END LOOP;

		RETURN p_DATE_RANGE_TABLE;
END;
----------------------------------------------------------------------------------
FUNCTION GET_NODE_TYPE (p_NODE_NAME VARCHAR2) RETURN VARCHAR2
AS
BEGIN

	IF p_NODE_NAME LIKE '%REFERENCE' THEN
		RETURN g_NODE_TYPE_BUS;
	ELSIF p_NODE_NAME LIKE ('%^_VL^_%') ESCAPE '^' THEN
		RETURN g_NODE_TYPE_AGG;
	ELSIF p_NODE_NAME LIKE ('%^_VS^_%') ESCAPE '^' THEN
		RETURN g_NODE_TYPE_AGG;
	ELSE
		RETURN g_NODE_TYPE_GEN;
	END IF;

END GET_NODE_TYPE;
----------------------------------------------------------------------------------
FUNCTION GET_LOAD_TYPE (p_NODE_NAME VARCHAR2) RETURN NUMBER
AS
BEGIN

	IF p_NODE_NAME LIKE ('%^_VL^_%') ESCAPE '^' THEN
		RETURN g_LOAD_TYPE_VL;
	ELSIF p_NODE_NAME LIKE ('%^_VS^_%') ESCAPE '^' THEN
		RETURN g_LOAD_TYPE_VS;
	ELSE
		RETURN g_LOAD_TYPE_PL;
	END IF;

END GET_LOAD_TYPE;
----------------------------------------------------------------------------------
FUNCTION GET_QUERY_TYPE (p_ACTION VARCHAR2) RETURN NUMBER
AS

BEGIN

	-- QUERY PHYSICAL AND VIRTUAL LOAD BIDS
	-- QUERY PHYSICAL AND VIRTUAL LOAD BIDS TO INTERNAL

	-- supported but not planning on using:
	-- QUERY VIRTUAL LOAD BIDS
	-- QUERY VIRTUAL SUPPLY BIDS
	-- QUERY PHYSICAL LOAD BIDS

	-- also works with SUBMIT instead of QUERY

	IF p_ACTION LIKE '% PHYSICAL AND VIRTUAL %' THEN
		RETURN g_QUERY_TYPE_ALL;
	ELSIF p_ACTION LIKE '% VIRTUAL LOAD %' THEN
		RETURN g_QUERY_TYPE_VL;
	ELSIF p_ACTION LIKE '% VIRTUAL SUPPLY %' THEN
		RETURN g_QUERY_TYPE_VS;
	ELSE
		RETURN g_QUERY_TYPE_PL;
	END IF;

END GET_QUERY_TYPE;
-------------------------------------------------------------------------------------------------------------
FUNCTION CREATE_TRANSACTION_NAME (
    p_EXT_IDENTIFIER IN VARCHAR2,
	p_CONTRACT_NAME IN VARCHAR2,
	p_IS_PHYSICAL IN BOOLEAN,
	p_CREATE_SERVICE IN BOOLEAN,
	p_SERVICE_POINT_NAME IN SERVICE_POINT.SERVICE_POINT_NAME%TYPE,
	p_SERVICE_POINT_ID OUT SERVICE_POINT.SERVICE_POINT_ID%TYPE,
	p_TRANSACTION_ALIAS OUT INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS%TYPE,
	p_TRANSACTION_IDENT OUT INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE
) RETURN INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE IS

	v_TRANSACTION_ALIAS    INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS%TYPE;
    v_TRANSACTION_NAME     INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
	v_TRANSACTION_IDENT    INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE;
	v_TYPE        VARCHAR2(12);

BEGIN

	-- external identifier max length is 32 bytes
    -- NAME and IDENTIFIER are 64 long
    -- ALIAS is 32 long

    -- use external_id to find service zone name and id
	-- p_EXT_IDENTIFIER is the PTID
	BEGIN
    SELECT SP.SERVICE_POINT_ID
      INTO p_SERVICE_POINT_ID
      FROM SERVICE_POINT SP
     WHERE SP.EXTERNAL_IDENTIFIER = p_EXT_IDENTIFIER;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN

		-- add the service point
		IF p_CREATE_SERVICE = TRUE THEN

    		IO.PUT_SERVICE_POINT(
        	o_OID => p_SERVICE_POINT_ID,
        	p_SERVICE_POINT_NAME => p_SERVICE_POINT_NAME,
        	p_SERVICE_POINT_ALIAS => p_SERVICE_POINT_NAME,
        	p_SERVICE_POINT_DESC => p_SERVICE_POINT_NAME,
        	p_SERVICE_POINT_ID => 0,
        	p_SERVICE_POINT_TYPE  => 'Retail',
        	p_TP_ID => NULL,
        	p_CA_ID => NULL,
        	p_EDC_ID => NULL,
        	p_ROLLUP_ID  => NULL,
        	p_SERVICE_REGION_ID => NULL,
        	p_SERVICE_AREA_ID => NULL,
        	p_SERVICE_ZONE_ID => NULL,
        	p_TIME_ZONE => 'Eastern',
        	p_LATITUDE => NULL,
        	p_LONGITUDE => NULL,
        	p_EXTERNAL_IDENTIFIER => p_EXT_IDENTIFIER,
        	p_IS_INTERCONNECT => NULL,
        	p_NODE_TYPE => GET_NODE_TYPE(p_SERVICE_POINT_NAME),
        	p_SERVICE_POINT_NERC_CODE => NULL,
			p_PIPELINE_ID => 0,
			p_MILE_MARKER => 0
        	);

		ELSE
			RETURN NULL;
		END IF;

	END;

	IF p_IS_PHYSICAL = TRUE THEN
		v_TYPE := 'Physical Bid';
	ELSE
		v_TYPE := 'Virtual Bid';
	END IF;

    v_TRANSACTION_NAME := p_CONTRACT_NAME || ': ' || p_SERVICE_POINT_NAME || ': ' || v_TYPE;
    v_TRANSACTION_ALIAS := p_SERVICE_POINT_NAME;
	v_TRANSACTION_IDENT := p_CONTRACT_NAME || ': ' || p_SERVICE_POINT_NAME;

	p_TRANSACTION_ALIAS := v_TRANSACTION_ALIAS;
	p_TRANSACTION_IDENT := v_TRANSACTION_IDENT;
	RETURN v_TRANSACTION_NAME;

EXCEPTION
    WHEN OTHERS THEN
		RETURN NULL;
END CREATE_TRANSACTION_NAME;

----------------------------------------------------------------------------------------------------
--
-- MARKET_TYPES:
--
FUNCTION GET_IT_TRANSACTION_ID(
	p_EXT_IDENTIFIER IN VARCHAR2,
	p_SERVICE_POINT_NAME IN VARCHAR2,
	p_CONTRACT_NAME IN VARCHAR2,
	p_TRANSACTION_TYPE   IN INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE,
	p_TRAIT_CATEGORY     IN INTERCHANGE_TRANSACTION.TRAIT_CATEGORY%TYPE,
	p_IS_PHYSICAL IN BOOLEAN,
	p_CREATE_SERVICE IN BOOLEAN
	) RETURN NUMBER IS

	--v_SERVICE_POINT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
	v_SERVICE_POINT_ID   SERVICE_POINT.SERVICE_POINT_ID%TYPE;
    v_TRANSACTION_ID     INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_TRANSACTION_NAME   INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE; -- 64
	v_TRANSACTION_ALIAS  INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS%TYPE; -- 32
	v_TRANSACTION_IDENT  INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE; -- 64
	v_IS_FIRM            INTERCHANGE_TRANSACTION.IS_FIRM%TYPE;
	v_CONTRACT_ID        INTERCHANGE_TRANSACTION.CONTRACT_ID%TYPE := 0;
	v_COMMODITY_ID       IT_COMMODITY.COMMODITY_ID%TYPE;
	v_PRICE_INTERVAL     VARCHAR2(9);

BEGIN

	v_CONTRACT_ID := MM_NYISO_UTIL.GET_NYISO_CONTRACT_ID(p_CONTRACT_NAME);
	IF v_CONTRACT_ID IS NULL THEN
    	ERRS.LOG_AND_RAISE('Missing NYISO contract.');
		RETURN NULL;
    END IF;

    -- use MM_NYISO.g_REALTIMEINTEGRATED for hour
    v_PRICE_INTERVAL := MM_NYISO_UTIL.GET_PRICE_INTERVAL(MM_NYISO_UTIL.g_REALTIMEINTEGRATED);

    -- using external_identifier = p_INTERFACE_NAME as a service point lookup
    -- generate a unique name and alias, return service point name and id too
	-- service point name is also passed in to allow creation of a new service point
    v_TRANSACTION_NAME := CREATE_TRANSACTION_NAME
    	(p_EXT_IDENTIFIER, p_CONTRACT_NAME, p_IS_PHYSICAL, p_CREATE_SERVICE, p_SERVICE_POINT_NAME,
    	v_SERVICE_POINT_ID, v_TRANSACTION_ALIAS, v_TRANSACTION_IDENT);

	IF v_TRANSACTION_NAME IS NOT NULL THEN

        -- we need the commodity_id , if no record add one

        v_COMMODITY_ID := MM_NYISO_UTIL.GET_COMMODITY_ID(MM_NYISO_UTIL.g_DAYAHEAD,NOT(p_IS_PHYSICAL));

        IF v_COMMODITY_ID = -1 THEN
        	v_COMMODITY_ID := 0;
        END IF;

    BEGIN
        -- look for existing ID
        SELECT TRANSACTION_ID
        INTO v_TRANSACTION_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_TYPE = p_TRANSACTION_TYPE
		AND CONTRACT_ID = v_CONTRACT_ID
		AND POD_ID = v_SERVICE_POINT_ID
		AND COMMODITY_ID = v_COMMODITY_ID
		AND SC_ID = MM_NYISO_UTIL.G_NYISO_SC_ID
		AND IS_BID_OFFER = 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        v_TRANSACTION_ID := 0;
    END;

	IF v_TRANSACTION_ID = 0 THEN
	  --create a new transaction

        BEGIN

		  v_IS_FIRM := 0;

		  -- return existing ID matching on P_TRANSACTION_NAME or create new
           EM.PUT_TRANSACTION(O_OID => V_TRANSACTION_ID,
                                P_TRANSACTION_NAME       => v_TRANSACTION_NAME,
                                P_TRANSACTION_ALIAS      => v_TRANSACTION_ALIAS,
                                P_TRANSACTION_DESC       => 'Bid at ' || v_TRANSACTION_NAME,
                                P_TRANSACTION_ID         => 0,
								p_TRANSACTION_STATUS	 => 'Active',
                                P_TRANSACTION_TYPE       => p_TRANSACTION_TYPE,
                                P_TRANSACTION_IDENTIFIER => v_TRANSACTION_IDENT,
                                p_IS_FIRM                => v_IS_FIRM,
                                p_IS_IMPORT_SCHEDULE     => 0,
                                p_IS_EXPORT_SCHEDULE     => 0,
                                P_IS_BALANCE_TRANSACTION => 0,
                                p_IS_BID_OFFER           => 1,
                                P_IS_EXCLUDE_FROM_POSITION => 0,
                                P_IS_IMPORT_EXPORT       => 0,
                                p_IS_DISPATCHABLE        => 0,
                                P_TRANSACTION_INTERVAL   => v_PRICE_INTERVAL,
                                P_EXTERNAL_INTERVAL      => '?',
                                P_ETAG_CODE              => '?',
                                p_BEGIN_DATE             => TO_DATE('01/01/2000','MM/DD/YYYY'),
                                p_END_DATE               => TO_DATE('12/31/2020','MM/DD/YYYY'),
                                p_PURCHASER_ID           => 0,
                                p_SELLER_ID              => 0,
                                p_CONTRACT_ID            => v_CONTRACT_ID,
                                p_SC_ID                  => MM_NYISO_UTIL.G_NYISO_SC_ID,
                                p_POR_ID                 => 0,
                                p_POD_ID                 => v_SERVICE_POINT_ID,
                                P_COMMODITY_ID           => v_COMMODITY_ID,
                                P_SERVICE_TYPE_ID        => 0,
                                P_TX_TRANSACTION_ID      => 0,
                                P_PATH_ID                => 0,
                                P_LINK_TRANSACTION_ID    => 0,
                                P_EDC_ID                 => 0,
                                P_PSE_ID                 => 0,
                                P_ESP_ID                 => 0,
                                P_POOL_ID                => 0,
                                P_SCHEDULE_GROUP_ID      => 0,
                                P_MARKET_PRICE_ID        => 0,
                                P_ZOR_ID                 => 0,
                                P_ZOD_ID                 => 0,
                                P_SOURCE_ID              => 0,
                                P_SINK_ID                => 0,
                                P_RESOURCE_ID            => 0,
                                P_AGREEMENT_TYPE         => '?',
                                P_APPROVAL_TYPE          => '?',
                                P_LOSS_OPTION            => '?',
                                P_TRAIT_CATEGORY         => p_TRAIT_CATEGORY,
                                --P_MODEL_ID               => 1,
                                P_TP_ID                  => 0
                                );

        COMMIT;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            -- no service point, so no market price
            V_TRANSACTION_ID := NULL;
            END;
        END IF;
    END IF;

    RETURN V_TRANSACTION_ID;

EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END GET_IT_TRANSACTION_ID;
--------------------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_TYPE
( p_LOAD_TYPE VARCHAR2
) RETURN INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE AS

v_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
BEGIN

	-- no support for generator or bilateral transactions yet (purchase and sale)

	IF p_LOAD_TYPE = g_LOAD_TYPE_VS THEN
		v_TYPE := g_TRAN_TYPE_GEN;
	ELSE
		v_TYPE := g_TRAN_TYPE_LOAD;
	END IF;

	RETURN v_TYPE;
END GET_TRANSACTION_TYPE;
--------------------------------------------------------------------------------------------
FUNCTION GET_TRAIT_CATEGORY
( p_LOAD_TYPE NUMBER
) RETURN INTERCHANGE_TRANSACTION.TRAIT_CATEGORY%TYPE AS

v_TYPE INTERCHANGE_TRANSACTION.TRAIT_CATEGORY%TYPE := '%';

BEGIN

	-- no support for generrator or bilateral transactions yet (purchase and sale)

	IF p_LOAD_TYPE = g_LOAD_TYPE_PL THEN
		v_TYPE := g_TRAIT_CATEGORY_LOAD;
	ELSE
		v_TYPE := g_TRAIT_CATEGORY_VIRTUAL;
	END IF;

	RETURN v_TYPE;
END GET_TRAIT_CATEGORY;
--------------------------------------------------------------------------------------------

PROCEDURE IMPORT_LOAD
(
	p_CRED 		  IN mex_credentials,
	p_RECORDS     IN MEX_NY_PHYSICAL_LOAD_TBL,
	p_CREATE_SERVICE IN BOOLEAN,
	p_ACTION 	IN VARCHAR2,
	p_STATUS      OUT NUMBER,
	p_LOGGER      IN OUT NOCOPY mm_logger_adapter
) IS
	v_DATE DATE;
	v_CUT_DATE DATE;
	v_TRANSACTION_ID NUMBER;
	v_STATE NUMBER;
	v_TYPE NUMBER := 0;
	v_EXT_IDENTIFIER VARCHAR2(64);
	v_CONTRACT_NAME VARCHAR2(32);
	v_TOTAL_MW NUMBER;
	v_TEMP_MW NUMBER;
	v_IS_PHYSICAL BOOLEAN;
	v_TO_INTERNAL BOOLEAN := FALSE;
	v_LOAD_TYPE NUMBER(1);
	v_QUERY_TYPE NUMBER(1);
	v_IDX BINARY_INTEGER;
BEGIN
    -- put p_RECORDS into the database
	SAVEPOINT BEFORE_IMPORT;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do
	v_IDX := p_RECORDS.FIRST;
	-- assumes that all the data is for this one contract
	-- retail_office_iso_password.iso_name matches the
	-- interchange_contract.contract_alias
	v_CONTRACT_NAME := p_CRED.EXTERNAL_ACCOUNT_NAME;
	v_QUERY_TYPE := GET_QUERY_TYPE(UPPER(p_ACTION));
	IF UPPER(p_ACTION) LIKE 'QUERY%TO INTERNAL' THEN v_TO_INTERNAL := TRUE; END IF;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
			-- a physical load must have a non-null forecast MW value.
			-- also a virtual load bus name will have _VL_ in it.
			-- a virtual supply bus name will have _VS_ in it.
			IF p_RECORDS(v_IDX).FORECAST_MW IS NULL THEN
				v_IS_PHYSICAL := FALSE;
			ELSE
				v_IS_PHYSICAL := TRUE;
			END IF;

			v_LOAD_TYPE := GET_LOAD_TYPE(p_RECORDS(v_IDX).LOAD_NAME);
			-- three load types types:  Virtual Load, Virtual Supply, Physical Load

			IF  (v_QUERY_TYPE = g_QUERY_TYPE_ALL) OR
				(v_LOAD_TYPE = g_LOAD_TYPE_VL AND v_QUERY_TYPE = g_QUERY_TYPE_VL) OR
				(v_LOAD_TYPE = g_LOAD_TYPE_VS AND v_QUERY_TYPE = g_QUERY_TYPE_VS) OR
				(v_LOAD_TYPE = g_LOAD_TYPE_PL AND v_QUERY_TYPE = g_QUERY_TYPE_PL) THEN

    			-- date is in standard hour ending
    			v_CUT_DATE := p_RECORDS(v_IDX).LOAD_DATE;

    			-- but TG assumes local time is used so convert
    			v_DATE := FROM_CUT(v_CUT_DATE, MEX_NYISO.g_NYISO_TIME_ZONE);
    			-- lookup transaction id here and assign to v_TRANSACTION_ID
    			v_EXT_IDENTIFIER := to_char(p_RECORDS(v_IDX).LOAD_NID); -- service_point.external_identifier such as 24008
    			v_TRANSACTION_ID := GET_IT_TRANSACTION_ID(v_EXT_IDENTIFIER, p_RECORDS(v_IDX).LOAD_NAME, v_CONTRACT_NAME,
    				GET_TRANSACTION_TYPE(v_LOAD_TYPE), GET_TRAIT_CATEGORY(v_LOAD_TYPE),
    				v_IS_PHYSICAL, p_CREATE_SERVICE);

    			FOR j IN 1 .. 2 LOOP

        			IF j = 1 THEN
        		    	v_STATE := GA.EXTERNAL_STATE;
        			ELSE
        				IF v_TO_INTERNAL = FALSE THEN
        					EXIT;
        				ELSE
        					v_STATE := GA.INTERNAL_STATE;
        				END IF;
        			END IF;

        			-- if non-schedule value write to it_trait_schedule.trait_val
        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_FORECAST_MW,
            			1, 1, p_RECORDS(v_IDX).FORECAST_MW,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_FIXED_MW,
            			1, 1, p_RECORDS(v_iDX).FIXED_MW,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_PRICE_CAP_1,
            			1, 1, p_RECORDS(v_IDX).PRICE_CAP_1_MW,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_1,
            			1, 1, p_RECORDS(v_IDX).PRICE_CAP_1_DOLLAR,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_PRICE_CAP_2,
            			1, 1, p_RECORDS(v_IDX).PRICE_CAP_2_MW,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_2,
            			1, 1, p_RECORDS(v_IDX).PRICE_CAP_2_DOLLAR,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_PRICE_CAP_3,
            			1, 1, p_RECORDS(v_IDX).PRICE_CAP_3_MW,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			TG.PUT_IT_TRAIT_SCHEDULE(
            			v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_PRICE_CAP_PRICE_3,
            			1, 1, p_RECORDS(v_IDX).PRICE_CAP_3_DOLLAR,
            			MEX_NYISO.g_NYISO_TIME_ZONE);

        			-- Not used by IDT yet
                    TG.PUT_IT_TRAIT_SCHEDULE(
                        v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_TYPE,
                        1, 1, p_RECORDS(v_IDX).INTERRUPTIBLE_TYPE,
                        MEX_NYISO.g_NYISO_TIME_ZONE);

                    -- Not used by IDT yet
                    TG.PUT_IT_TRAIT_SCHEDULE(
                        v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_FIXED,
                        1, MM_NYISO_UTIL.g_TT_MW, p_RECORDS(v_IDX).INTERRUPTIBLE_FIXED_MW,
                        MEX_NYISO.g_NYISO_TIME_ZONE);

                    -- Not used by IDT yet
                    TG.PUT_IT_TRAIT_SCHEDULE(
                        v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_FIXED,
                        1, MM_NYISO_UTIL.g_TT_COST, p_RECORDS(v_IDX).INTERRUPTIBLE_FIXED_COST,
                        MEX_NYISO.g_NYISO_TIME_ZONE);

                    -- Not used by IDT yet
                    TG.PUT_IT_TRAIT_SCHEDULE(
                        v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_CAPPED,
                        1, MM_NYISO_UTIL.g_TT_MW, p_RECORDS(v_IDX).INTERRUPTIBLE_CAPPED_MW,
                        MEX_NYISO.g_NYISO_TIME_ZONE);

                    -- Not used by IDT yet
                    TG.PUT_IT_TRAIT_SCHEDULE(
                        v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_INTERRUPTIBLE_CAPPED,
                        1, MM_NYISO_UTIL.g_TT_COST, p_RECORDS(v_IDX).INTERRUPTIBLE_CAPPED_COST,
                        MEX_NYISO.g_NYISO_TIME_ZONE);


                    -- if bid id the save it to trait schedule (and log?)
                    TG.PUT_IT_TRAIT_SCHEDULE(
                        v_TRANSACTION_ID, v_STATE, v_TYPE, v_DATE, MM_NYISO_UTIL.g_TG_LOAD_BID_ID,
                        1, 1, p_RECORDS(v_IDX).BID_NID,
                        MEX_NYISO.g_NYISO_TIME_ZONE);

                END LOOP; -- for external and internal states

    			-- if scheduled values then write to it_schedule.quantity

    			-- sum up fixed and capped only when bid is accepted
    			IF UPPER(p_RECORDS(v_IDX).BID_STATUS) = 'BID ACCEPTED' THEN
        			v_TOTAL_MW := 0;

					BEGIN
        				v_TEMP_MW := TO_NUMBER(p_RECORDS(v_IDX).FIXED_MW);
        			EXCEPTION WHEN OTHERS THEN NULL;
        			END;

    				IF v_TEMP_MW IS NOT NULL THEN
    					v_TOTAL_MW := v_TEMP_MW;
    				END IF;

        			BEGIN
        				v_TEMP_MW := TO_NUMBER(p_RECORDS(v_IDX).SCHED_PRICE_CAPPED);
        			EXCEPTION WHEN OTHERS THEN NULL;
        			END;

    				IF v_TEMP_MW IS NOT NULL THEN
    					v_TOTAL_MW := v_TOTAL_MW + v_TEMP_MW;
    				END IF;
    			ELSE
    				v_TOTAL_MW := NULL;
    			END IF;
    			-- GA.INTERNAL_STATE

    			-- use cut date here and on status
    			/*IT.PUT_IT_SCHEDULE(v_TRANSACTION_ID, GA.SCHEDULE_TYPE_PRELIM, v_CUT_DATE, v_CUT_DATE, v_TOTAL_MW, NULL, p_STATUS);
                IT.PUT_IT_SCHEDULE(v_TRANSACTION_ID, GA.SCHEDULE_TYPE_FORECAST, v_CUT_DATE, v_CUT_DATE, v_TOTAL_MW, NULL, p_STATUS);
                IT.PUT_IT_SCHEDULE(v_TRANSACTION_ID, GA.SCHEDULE_TYPE_FINAL, v_CUT_DATE, v_CUT_DATE, v_CUT_DATE, NULL, p_STATUS);*/

    			--New schedules types: Uninvoiced, Initial, 4 Month, 12 Month
    			MM_NYISO_UTIL.PUT_SCHEDULE_VALUE(v_TRANSACTION_ID, v_CUT_DATE,v_TOTAL_MW);



    			-- Not used by IDT yet
    			--p_RECORDS(v_IDX).SCHED_INTERRUPTIBLE_FIXED
    			--p_RECORDS(v_IDX).SCHED_INTERRUPTIBLE_CAPPED

    			-- if bid status then write to it_trait_schedule_status.market_status
    			--p_RECORDS(v_IDX).BID_STATUS;
    			-- if message then write to it_trait_schedule_status.process_message
    			--p_RECORDS(v_IDX).MESSAGE;

    			UPDATE_TRAIT_SCHEDULE_STATUS(v_CUT_DATE, v_TRANSACTION_ID, NULL, p_RECORDS(v_IDX).BID_STATUS, p_RECORDS(v_IDX).MESSAGE );

			END IF; -- null TID
			COMMIT;
			SAVEPOINT BEFORE_IMPORT;
			v_IDX := p_RECORDS.NEXT(v_IDX);
		END LOOP;

EXCEPTION
  WHEN OTHERS THEN
  	ROLLBACK TO BEFORE_IMPORT;
    P_STATUS  := SQLCODE;
    p_LOGGER.LOG_ERROR('MM_NYISO_BIDPOST.IMPORT_LOAD: ' || SQLERRM);

END IMPORT_LOAD;
--------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_PHYSICAL_LOAD(p_CRED		 IN mex_credentials,
							   p_RECORDS     IN MEX_NY_PHYSICAL_LOAD_TBL,
							   p_ACTION      IN VARCHAR2,
							   p_LOGGER	 	IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
	p_RECORDS_OUT MEX_NY_PHYSICAL_LOAD_TBL;
	v_STATUS NUMBER;
BEGIN
	v_STATUS := GA.SUCCESS;
	-- first submit
	MEX_NYISO_BIDPOST.SUBMIT_PHYSICAL_LOAD(p_CRED 		 => p_CRED,
										   p_RECORDS_IN  => p_RECORDS,
										   p_RECORDS_OUT => p_RECORDS_OUT,
										   p_LOGGER 	 => p_LOGGER,
										   p_STATUS		 => v_STATUS);
	IF v_STATUS = GA.SUCCESS THEN
		-- then import
		IMPORT_LOAD(p_CRED,
					p_RECORDS_OUT,
					TRUE, -- create service
					UPPER(p_ACTION),
					v_STATUS,
					p_LOGGER);
	END IF;

END SUBMIT_PHYSICAL_LOAD;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_PHYSICAL_LOAD
(
    p_CRED          IN mex_credentials,
    p_DATE          IN DATE,
    p_EXCHANGE_TYPE IN VARCHAR2,
	p_STATUS        OUT NUMBER,
    p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    p_RECORDS MEX_NY_PHYSICAL_LOAD_TBL;

BEGIN
    -- first query
    MEX_NYISO_BIDPOST.FETCH_PHYSICAL_LOAD(p_DATE, p_CRED, p_RECORDS, p_STATUS, p_LOGGER);

    ERRS.VALIDATE_STATUS('MEX_NYISO_BIDPOST.FETCH_PHYSICAL_LOAD', p_STATUS);
    IMPORT_LOAD(p_CRED, p_RECORDS, TRUE, p_EXCHANGE_TYPE, p_STATUS, p_LOGGER);


END QUERY_PHYSICAL_LOAD;
-------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE    IN DATE,
	p_END_DATE      IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR2,
	p_LOG_TYPE 		IN NUMBER,
	p_TRACE_ON 		IN NUMBER,
	p_STATUS        OUT NUMBER,
	p_MESSAGE       OUT VARCHAR2) IS

	v_DATE 		DATE;
	v_CREDS     MM_CREDENTIALS_SET;
	v_CRED		MEX_CREDENTIALS;
	v_LOGGER    MM_LOGGER_ADAPTER;
	v_DUMMY     VARCHAR2(512);
BEGIN
	BEGIN
		MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID    => EC.ES_NYISO,
						 p_PROCESS_NAME          => 'NYISO:BIDPOST',
						 p_EXCHANGE_NAME         => p_EXCHANGE_TYPE,
						 p_LOG_TYPE              => p_LOG_TYPE,
						 p_TRACE_ON              => p_TRACE_ON,
						 p_CREDENTIALS           => v_CREDS,
						 p_LOGGER                => v_LOGGER);

     EXCEPTION
       WHEN NO_DATA_FOUND THEN
            v_LOGGER  := MM_UTIL.GET_LOGGER(EC.ES_NYISO,
                                            '%',
                                            p_EXCHANGE_TYPE,
                                            p_EXCHANGE_TYPE,
                                            NULL,
                                            NULL);
            p_MESSAGE := 'No external credentials available: ' ;
            v_LOGGER.LOG_ERROR(p_MESSAGE);
            p_STATUS := SQLCODE;
            v_CREDS := NULL;
	END;

    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	-- no credentials? we can proceed w/out if we are in test mode - otherwise, fail
	IF NOT v_CREDS.HAS_NEXT THEN
		p_STATUS := GA.GENERAL_EXCEPTION;
		p_MESSAGE := 'No credentials found for NYISO. Nothing can be downloaded';
		v_LOGGER.LOG_WARN(p_MESSAGE);

		IF NOT MM_NYISO_UTIL.g_TEST THEN
			MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);
			RETURN;
		END IF;
	END IF;

	IF p_EXCHANGE_TYPE = g_ET_QUERY_PHYSICAL_LOAD THEN
		IF v_CREDS IS NOT NULL THEN
			WHILE v_CREDS.HAS_NEXT LOOP
				v_CRED := v_CREDS.GET_NEXT;
				-- must have an iso_account_name to find the contract
				IF v_CREDS.LOGGER.EXTERNAL_ACCOUNT_NAME IS NOT NULL THEN
					v_DATE := p_BEGIN_DATE;

					WHILE v_DATE <= p_END_DATE LOOP
    					QUERY_PHYSICAL_LOAD(v_CRED, v_DATE, p_EXCHANGE_TYPE, p_STATUS, v_LOGGER);
						v_DATE := v_DATE + 1; -- next day
					END LOOP;
				END IF;
			END LOOP;
		END IF;
	ELSE
		p_STATUS  := GA.GENERAL_EXCEPTION;
        p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
        v_LOGGER.LOG_ERROR(p_MESSAGE);
	END IF;

	p_MESSAGE := v_LOGGER.GET_END_MESSAGE();
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
        p_STATUS  := SQLCODE;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

END MARKET_EXCHANGE;
------------------------------------------------------------------------------------
PROCEDURE MARKET_SUBMIT
	(
	   p_BEGIN_DATE      IN DATE,
       p_END_DATE        IN DATE,
       p_EXCHANGE_TYPE   IN VARCHAR2,
       p_ENTITY_LIST 	 IN VARCHAR2,
       p_ENTITY_LIST_DELIMITER IN CHAR,
       p_SUBMIT_HOURS    IN VARCHAR2,
       p_TIME_ZONE       IN VARCHAR2,
	   p_LOG_TYPE		 IN NUMBER,
	   p_TRACE_ON		 IN NUMBER,
       p_STATUS          OUT NUMBER,
       p_MESSAGE         OUT VARCHAR2) IS
    p_RECORDS    MEX_NY_PHYSICAL_LOAD_TBL;
    v_BEGIN_DATE DATE;
	v_END_DATE DATE;

    v_TRANSACTION_IDS    VARCHAR2(2000);
    v_TXN_STRING_TABLE   GA.STRING_TABLE;
    v_INDEX              BINARY_INTEGER;
    v_TRANSACTION_ID     NUMBER(9);

	v_CRED				MEX_CREDENTIALS;
	v_EXTERNAL_ACCOUNT_NAME	VARCHAR2(100);
	v_LOGGER 			MM_LOGGER_ADAPTER;
	v_DUMMY_MESSAGE VARCHAR2(4000);
BEGIN
	p_STATUS := GA.SUCCESS;

	MM_UTIL.INIT_MEX(	p_EXTERNAL_SYSTEM_ID    => EC.ES_NYISO,
						p_EXTERNAL_ACCOUNT_NAME => NULL,
						 p_PROCESS_NAME          => p_EXCHANGE_TYPE,
						 p_EXCHANGE_NAME         => p_EXCHANGE_TYPE,
						 p_LOG_TYPE              => p_LOG_TYPE,
						 p_TRACE_ON              => p_TRACE_ON,
						 p_CREDENTIALS           => v_CRED,
						 p_LOGGER                => v_LOGGER);

    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

    -- p_MKT_APP and p_TIME_ZONE are not used
    -- parse out the transaction ids into a table
    v_TRANSACTION_IDS := REPLACE(p_ENTITY_LIST, '''', '');
    UT.TOKENS_FROM_STRING(v_TRANSACTION_IDS, p_ENTITY_LIST_DELIMITER, v_TXN_STRING_TABLE);
    v_INDEX := v_TXN_STRING_TABLE.FIRST;

    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_dATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	IF p_EXCHANGE_TYPE = g_ET_SUBMIT_PHYSICAL_LOAD THEN
    --LOOP OVER TRANSACTIONS
    LOOP
        v_TRANSACTION_ID := TO_NUMBER(v_TXN_STRING_TABLE(v_INDEX));
        v_EXTERNAL_ACCOUNT_NAME := MM_UTIL.GET_EXT_ACCOUNT_FOR_TXN(v_TRANSACTION_ID, EC.ES_NYISO);

		IF v_EXTERNAL_ACCOUNT_NAME IS NOT NULL THEN
				MM_UTIL.INIT_MEX (EC.ES_NYISO, v_EXTERNAL_ACCOUNT_NAME, 'NYISO:BIDPOST', p_EXCHANGE_TYPE, p_LOG_TYPE,  p_TRACE_ON, v_CRED, v_LOGGER);

				-- initialize p_RECORDS
				p_RECORDS := MEX_NY_PHYSICAL_LOAD_TBL();

				-- multi-day per transaction
				-- POPULATE_LOAD_TABLE assumes date range is standard hour ending
				POPULATE_LOAD_TABLE(p_RECORDS,
									v_TRANSACTION_ID,
									v_BEGIN_DATE,
									v_END_DATE);

				SUBMIT_PHYSICAL_LOAD(v_CRED,
									 p_RECORDS,
									 UPPER(p_EXCHANGE_TYPE),
									 v_LOGGER);


			  EXIT WHEN v_INDEX = v_TXN_STRING_TABLE.LAST;
			  v_INDEX := v_TXN_STRING_TABLE.NEXT(v_INDEX);
		END IF;
		END LOOP; -- OVER TRANSACTIONS
	ELSE
		p_STATUS := -1;
		p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
		v_LOGGER.LOG_ERROR(p_MESSAGE);
	END IF;

    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := SQLERRM;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

END MARKET_SUBMIT;
--------------------------------------------------------------------------------------

END MM_NYISO_BIDPOST;
/
