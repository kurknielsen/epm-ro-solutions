CREATE OR REPLACE PACKAGE MEX_ISONE IS

  TYPE PARAMETER_MAP IS TABLE OF VARCHAR2(512) INDEX BY VARCHAR2(512);

  -- CONSTANTS ---
  g_INTERFACE_SN CONSTANT VARCHAR2(8) := 'ISONE'; -- for logging
  g_ISONE_TIME_ZONE CONSTANT CHAR(3) := 'EDT';
  g_DATE_TIME_FMT CONSTANT VARCHAR2(21) := 'YYYY-MM-DD HH24:MI'; -- for to_cut_from_string

  -- TYPES OF REQUESTS
  g_ISONE_QUERY_TYPE CONSTANT VARCHAR2(8) := 'QUERY';
  g_ISONE_SUBMIT_TYPE CONSTANT VARCHAR2(8) := 'SUBMIT';

  --
  -- load constants
  -- Use these constants to request the desired type of fetch for Load
  g_DA_LMP CONSTANT VARCHAR2(64) := 'DAY-AHEAD';
  g_RT_LMP CONSTANT VARCHAR2(64) := 'REAL-TIME';
  g_REG_CLR_PRICE CONSTANT VARCHAR2(64) := 'REGULATION CLEARING PRICE';

  PROCEDURE RUN_EXCHANGE(p_PARAMETER_MAP IN OUT MEX_HTTP.PARAMETER_MAP,
						 p_EXT_CREDS     IN EXTERNAL_CREDENTIAL,
						 p_MARKET        IN VARCHAR2,
						 p_ACTION        IN VARCHAR2,
						 p_LOG_MESSAGE   IN VARCHAR2,
						 p_CLOB_RESPONSE OUT CLOB,
						 p_STATUS        OUT NUMBER,
						 p_MESSAGE       OUT VARCHAR2);
                             
  FUNCTION FROM_CUT_TO_STRING
  	(
  	p_DATE        IN DATE,
  	p_TIME_ZONE   IN VARCHAR2,
    p_DATE_FORMAT IN VARCHAR2,
    p_INTERVAL_MINUTES IN NUMBER DEFAULT 60
  	)
  	RETURN VARCHAR2;
  
    FUNCTION TO_CUT_FROM_STRING
  	(
  	p_DATE        IN VARCHAR2,
  	p_TIME_ZONE   IN VARCHAR2,
    p_DATE_FORMAT IN VARCHAR2,
    p_INTERVAL_MINUTES IN NUMBER DEFAULT 60
  	)
  	RETURN DATE;

END MEX_ISONE;
/
CREATE OR REPLACE PACKAGE BODY MEX_ISONE IS


vPackageName CONSTANT VARCHAR2(50) := 'MEX_ISONE';

---------------------------------------------------------------------------------------------------
-- utility logic
---------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------
-- answer a string based on a date format, time zone, and source string
-- output ISONE 2X format for fall repeat hour
-- interval minutes is used to convert to HE.  If already HE use 0.
FUNCTION FROM_CUT_TO_STRING
  	(
  	p_DATE        IN DATE,
  	p_TIME_ZONE   IN VARCHAR2,
    p_DATE_FORMAT IN VARCHAR2,
	p_INTERVAL_MINUTES IN NUMBER
  	)
  	RETURN VARCHAR2 IS

    v_DATE DATE;
    v_DATE_STR VARCHAR2(32);
    v_TIME_ZONE CHAR(3);
    v_REPEAT_HOUR INTEGER;
	v_HOUR INTEGER;

BEGIN

	-- input date is in hour ending, standard time
	-- output time string is in hour beginning, local time
	v_TIME_ZONE := UPPER(p_TIME_ZONE);

	-- convert to local time
    v_DATE := FROM_CUT(p_DATE, v_TIME_ZONE);

	-- check if this is the repeat hour
	v_REPEAT_HOUR := TO_NUMBER(TO_CHAR(v_DATE,'SS'));

	IF v_REPEAT_HOUR = 1 THEN
		-- subtract second
		v_DATE := v_DATE - 1/86400;
	END IF;

	-- adjust to 'hour beginning' if specified
	v_DATE := v_DATE - p_INTERVAL_MINUTES/1440;

	-- check for midnight
	v_HOUR := TO_NUMBER(TO_CHAR(v_DATE,'SS'));

	-- previous day because 24 will replace 00 in the output
	IF v_HOUR = 0 THEN
		v_DATE := v_DATE - 1; -- subtract one day
	END IF;

	v_DATE_STR := TO_CHAR(v_DATE, p_DATE_FORMAT);

	-- handle hour 24
	IF v_HOUR = 0 THEN
		v_DATE_STR := REPLACE(v_DATE_STR, ' 00', ' 24');
	END IF;

	-- handle hour 2X
	IF v_REPEAT_HOUR = 1 THEN
    	v_DATE_STR := REPLACE(v_DATE_STR, ' 01', ' 02X');
	END IF;

  	RETURN v_DATE_STR;

END FROM_CUT_TO_STRING;
---------------------------------------------------------------------------------------------------
-- answer a cut date from a string based on a date format, time zone, and source string
-- handle ISONE 02X format for fall repeat hour
-- interval minutes is used to convert to HE.  If already HE use 0.
FUNCTION TO_CUT_FROM_STRING
  	(
  	p_DATE        IN VARCHAR2,
  	p_TIME_ZONE   IN VARCHAR2,
    p_DATE_FORMAT IN VARCHAR2,
	p_INTERVAL_MINUTES IN NUMBER
  	)
  	RETURN DATE IS

    v_DATE DATE;
    v_DATE_STR VARCHAR2(32);
    v_TIME_ZONE CHAR(3);
	v_HOUR2X BOOLEAN := FALSE;
	v_HOUR24 BOOLEAN := FALSE;

BEGIN

	-- input time string is in hour beginning, local time
	-- when interval is 60
	-- or hour ending, local time with interval is not 60
	-- output time is in hour ending, standard time
    -- p_INTERVAL_MINUTES indicates end interval width to add to get HE

	v_TIME_ZONE := UPPER(p_TIME_ZONE);
	v_DATE_STR := p_DATE;

	-- handle hour 24 which is the third hour of the day (standard time)
	IF INSTR(v_DATE_STR, ' 24') > 0 THEN
		v_DATE_STR := REPLACE(v_DATE_STR, ' 24', ' 00');
		v_HOUR24 := TRUE;
	END IF;

	-- handle hour 2X which is the third hour of the day (standard time)
	IF INSTR(v_DATE_STR, ' 02X') > 0 THEN
		v_DATE_STR := REPLACE(v_DATE_STR, ' 02X', ' 01');
		v_HOUR2X := TRUE;
	END IF;

    v_DATE := TO_DATE(v_DATE_STR, p_DATE_FORMAT); -- local time
	IF v_HOUR24 THEN
		v_DATE := v_DATE + 1;
	END IF;

    IF SUBSTR(p_TIME_ZONE,2,2) = 'DT'  THEN
        -- handle special case for 2AM, treat as standard time
        IF v_DATE = DST_FALL_BACK_DATE(TRUNC(v_DATE)) THEN
			v_DATE := v_DATE + 1/86000; -- add one second
        END IF;
	END IF;

	-- If this is a DST time but not currently in the DST period then make it standard time
    v_DATE := TO_CUT(v_DATE, v_TIME_ZONE);

    -- add an hour when needed
    IF v_HOUR2X THEN
    	v_DATE := v_DATE + 1/24;
    END IF;

    -- adjust to 'hour ending'
    v_DATE := v_DATE + p_INTERVAL_MINUTES/1440;

  	RETURN v_DATE;

END TO_CUT_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE RUN_EXCHANGE(p_PARAMETER_MAP IN OUT MEX_HTTP.PARAMETER_MAP,
							 p_EXT_CREDS     IN EXTERNAL_CREDENTIAL,
							 p_MARKET        IN VARCHAR2,
							 p_ACTION        IN VARCHAR2,
							 p_LOG_MESSAGE   IN VARCHAR2,
							 p_CLOB_RESPONSE OUT CLOB,
							 p_STATUS        OUT NUMBER,
							 p_MESSAGE       OUT VARCHAR2) AS

	v_CLOB_REQUEST CLOB;
	v_EXCHANGE_ID  NUMBER(9);

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	--MAKE THE REQUEST
	MEX_HTTP.SEND_REQUEST_QSTRING(p_PARAMETER_MAP,
								  p_EXT_CREDS,
								  NULL,
								  NULL,
								  p_MARKET,
								  p_ACTION,
								  v_CLOB_REQUEST,
								  p_CLOB_RESPONSE,
								  p_STATUS,
								  p_MESSAGE,
								  NULL);

	--LOG THE RESPONSE
	MEX_UTIL.PUT_EXCHANGE_LOG('ISONE',
							  'IN',
							  p_LOG_MESSAGE,
							  'Normal',
							  p_MESSAGE,
							  NULL,
							  NULL,
							  v_EXCHANGE_ID);

	MEX_UTIL.PUT_EXCHANGE_DETAILS(v_EXCHANGE_ID,
								  'ISONE',
								  v_CLOB_REQUEST,
								  'txt',
								  p_CLOB_RESPONSE,
								  'txt');
	COMMIT;

	IF INSTR(p_MESSAGE, 'HTTP Status = Not Found (404)') > 0 THEN
		POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_ISONE',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  'There is no filename avaliable for requested date.',
							  SECURITY_CONTROLS.CURRENT_USER);
		p_MESSAGE := 'File Not Found for requested date';
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		P_STATUS  := SQLCODE;
		P_MESSAGE := 'Error in MEX_ISONE.RUN_EXCHANGE:' || SQLERRM;

END RUN_EXCHANGE;

END MEX_ISONE;
/
