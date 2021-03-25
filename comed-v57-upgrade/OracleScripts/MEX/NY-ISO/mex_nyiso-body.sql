CREATE OR REPLACE PACKAGE BODY MEX_NYISO IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION PACKAGE_NAME RETURN VARCHAR IS
BEGIN
     RETURN 'MEX_NYISO';
END PACKAGE_NAME;
----------------------------------------------------------------------------------------------------
-- answer a string based on a date format, time zone, and source string
-- output NYISO 25:00 format for fall repeat hour
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

  BEGIN

	-- input date is in hour ending, standard time
	-- output time string is in hour beginning, local time
	v_TIME_ZONE := UPPER(p_TIME_ZONE);

	-- convert to local time
    v_DATE := FROM_CUT(p_DATE, v_TIME_ZONE);

	-- check if this is the repeat hour
	v_REPEAT_HOUR:= TO_NUMBER(TO_CHAR(v_DATE,'SS'));

	IF v_REPEAT_HOUR = 1 THEN
		-- subtract second
		v_DATE := v_DATE - 1/86400;
	END IF;

	-- adjust to 'hour beginning' used by NYISO
	v_DATE := v_DATE - p_INTERVAL_MINUTES/1440;

	v_DATE_STR := TO_CHAR(v_DATE, p_DATE_FORMAT);

	-- handle hour 25
	IF v_REPEAT_HOUR = 1 THEN
    	v_DATE_STR := REPLACE(v_DATE_STR, ' 01:', ' 25:');
	END IF;

  	RETURN v_DATE_STR;

  END FROM_CUT_TO_STRING;
	---------------------------------------------------------------------------------------------------
  -- answer a cut date from a string based on a date format, time zone, and source string
  -- handle NYISO 25:00 format for fall repeat hour
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
	v_HOUR25 BOOLEAN := FALSE;

  BEGIN

	-- input time string is in hour beginning, local time
	-- when interval is 60
	-- or hour ending, local time with interval is not 60
	-- output time is in hour ending, standard time
    -- p_INTERVAL_MINUTES indicates end interval width to add to get HE

	v_TIME_ZONE := UPPER(p_TIME_ZONE);
	v_DATE_STR := p_DATE;

	-- handle hour 25 which is the third hour of the day (standard time)
	IF INSTR(v_DATE_STR, ' 25:') > 0 THEN
		v_DATE_STR := REPLACE(v_DATE_STR, ' 25:', ' 01:');
		v_HOUR25 := TRUE;
	END IF;

    v_DATE := TO_DATE(v_DATE_STR, p_DATE_FORMAT); -- local time

    IF SUBSTR(p_TIME_ZONE,2,2) = 'DT'  THEN
        -- handle special case for 2AM, treat as standard time
        IF v_DATE = DST_FALL_BACK_DATE(TRUNC(v_DATE)) THEN
			v_DATE := v_DATE + 1/86000; -- add one second
        END IF;
	END IF;

	-- If this is a DST time but not currently in the DST period then make it standard time
    v_DATE := TO_CUT(v_DATE, v_TIME_ZONE);

    -- add an hour when needed
    IF v_HOUR25 THEN
    	v_DATE := v_DATE + 1/24;
    END IF;

    -- adjust to 'hour ending'
    v_DATE := v_DATE + p_INTERVAL_MINUTES/1440;

  	RETURN v_DATE;

  END TO_CUT_FROM_STRING;
  ----------------------------------------------------------------------------------------------------
  -- based on the action and date provided, build a proper URL used to access the public NYISO site
  --
	PROCEDURE BUILD_PUBLIC_URL
	(
		p_DATE         IN DATE,
		p_IS_ZIP_FILE  IN BOOLEAN,
		p_REQUEST_TYPE IN VARCHAR2,
		p_REQUEST_URL  OUT VARCHAR2,
		p_STATUS       OUT NUMBER,
		p_LOGGER       IN OUT NOCOPY MM_LOGGER_ADAPTER
	) IS

		v_FILE_NAME     VARCHAR2(255);
		v_DATE_STRING   VARCHAR2(12);
		v_BASE_URL      SYSTEM_DICTIONARY.VALUE%TYPE;
		v_KEY2          SYSTEM_DICTIONARY.KEY2%TYPE;
		v_FILE_EXTENION VARCHAR2(4) := '.csv';
		v_FILE_SUFFIX   VARCHAR2(4);

	BEGIN


		p_STATUS := MEX_UTIL.g_SUCCESS;
		p_LOGGER.LOG_INFO('Build Public URL for ' || p_REQUEST_TYPE);
		v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMMDD');

		-- LOAD
		IF p_REQUEST_TYPE = MEX_NYISO.g_ISO_LOAD THEN
			-- ISO LOAD
			--http://mis.nyiso.com/public/csv/isolf/
			v_FILE_NAME := 'isolf';
			v_KEY2      := 'LOAD';
		ELSIF p_REQUEST_TYPE = MEX_NYISO.g_RT_ACTUAL_LOAD THEN
			-- REAL TIME ACTUAL
			--http://mis.nyiso.com/public/csv/pal/
			v_FILE_NAME := 'pal';
			v_KEY2      := 'LOAD';
		ELSIF p_REQUEST_TYPE = MEX_NYISO.g_INTEGRATED_RT_ACTUAL_LOAD THEN
			-- INTEGRATED RTA
			--http://mis.nyiso.com/public/csv/palIntegrated/
			v_FILE_NAME := 'palIntegrated';
			v_KEY2      := 'LOAD';
		-- LBMP
		ELSIF p_REQUEST_TYPE IN
			  (MEX_NYISO.g_DA_LBMP_ZONAL,
			   MEX_NYISO.g_DA_LBMP_GEN,
			   MEX_NYISO.g_DA_LBMP_BUS,
			   MEX_NYISO.g_INTEGRATED_RT_LBMP_ZONAL,
			   MEX_NYISO.g_INTEGRATED_RT_LBMP_GEN,
			   MEX_NYISO.g_INTEGRATED_RT_LBMP_BUS,
			   MEX_NYISO.g_BHA_LBMP_ZONAL,
			   MEX_NYISO.g_BHA_LBMP_GEN,
			   MEX_NYISO.g_BHA_LBMP_BUS,
			   MEX_NYISO.g_BHA_LBMP_BUS) THEN
	    
			IF p_IS_ZIP_FILE THEN
				v_FILE_EXTENION := '.zip';
				v_FILE_SUFFIX   := '_csv';
			ELSE
				v_FILE_SUFFIX := NULL;
			END IF;
	    
			v_KEY2 := 'LBMP';
	    
			CASE p_REQUEST_TYPE
				WHEN MEX_NYISO.g_DA_LBMP_ZONAL THEN
					v_FILE_NAME := 'damlbmp_zone';
				WHEN MEX_NYISO.g_DA_LBMP_GEN THEN
					v_FILE_NAME := 'damlbmp_gen';
				WHEN MEX_NYISO.g_DA_LBMP_BUS THEN
					v_FILE_NAME := 'damlbmp_gen_refbus';
				WHEN MEX_NYISO.g_INTEGRATED_RT_LBMP_ZONAL THEN
					v_FILE_NAME := 'rtlbmp_zone';
				WHEN MEX_NYISO.g_INTEGRATED_RT_LBMP_GEN THEN
					v_FILE_NAME := 'rtlbmp_gen';
				WHEN MEX_NYISO.g_INTEGRATED_RT_LBMP_BUS THEN
					v_FILE_NAME := 'rtlbmp_gen_refbus';
				WHEN MEX_NYISO.g_BHA_LBMP_ZONAL THEN
					v_FILE_NAME := 'hamlbmp_zone';
				WHEN MEX_NYISO.g_BHA_LBMP_GEN THEN
					v_FILE_NAME := 'hamlbmp_gen';
				WHEN MEX_NYISO.g_BHA_LBMP_BUS THEN
					v_FILE_NAME := 'hamlbmp_gen_refbus';
				ELSE
					v_FILE_NAME := 'invalid_action';
			END CASE;
	    
		-- ATC/TTC
		ELSIF p_REQUEST_TYPE = MEX_NYISO.g_ATC_TTC THEN
			v_FILE_NAME := 'atc_ttc';
			v_KEY2      := 'TC';
		ELSE
			v_FILE_NAME := 'INVALID_ACTION';
			p_LOGGER.LOG_ERROR('Invalid public action: ' || p_REQUEST_TYPE);
			p_STATUS := MEX_UTIL.g_FAILURE;
		END IF;

		v_FILE_NAME := v_DATE_STRING || v_FILE_NAME || v_FILE_SUFFIX ||  v_FILE_EXTENION;
		v_BASE_URL    := GET_DICTIONARY_VALUE('URL',
											  0,
											  'MarketExchange',
											  'NYISO',
											  v_KEY2,
											  p_REQUEST_TYPE);
		p_REQUEST_URL := v_BASE_URL || v_FILE_NAME;
		p_LOGGER.LOG_DEBUG('Public URL: ' || p_REQUEST_URL);
		
	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS := SQLCODE;
			p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.IMPORT_PRICE_NODES: ' || SQLERRM);
	END BUILD_PUBLIC_URL;
------------------------------------------------------------------------------------------
END MEX_NYISO;
/
