CREATE OR REPLACE FUNCTION FROM_CUT_AS_HED
	(
	p_DATE DATE,
	p_TIME_ZONE CHAR,
	p_FORMAT VARCHAR := NULL,
	p_MODEL_ID NUMBER := GA.ELECTRIC_MODEL,
	p_DAY_TYPE NUMBER := GA.STANDARD,
	p_DATA_INTERVAL VARCHAR := NULL
	)
	RETURN VARCHAR IS
--Revision: $Revision: 1.37 $

--c	Answer a local date converted from a CUT date for the specified time zone.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM.
--c		the last Sunday in October (fall back) has two 2:00 AM hours.
--c The date string is an hour ending date with an optional DST/STD indicator.
--c The Data Interval is the expected interval of the data.  If MODEL_ID = 2, then this
--c	    will probably be ignored and the data will be assumed to be daily, but if MODEL_ID = 1,
--c     then you can use this to say the data should be daily or higher, and this function will
--c		then not shift the date around for time zone changes and dst.

v_TIME_ZONE CHAR(3);
v_STD_TIME_ZONE CHAR(3);
v_SUFFIX CHAR(1);
v_LOCAL_DATE DATE;
v_IS_DAYLIGHT_SAVINGS BOOLEAN;
v_IS_TIME_CHANGE_DAY BOOLEAN;
v_DATE_STRING VARCHAR(32);

BEGIN

    --IF THIS IS GAS, JUST TRUNCATE TO THE INTERVAL.  TIME ZONES NOT NECESSARY.
	IF p_MODEL_ID = GA.GAS_MODEL AND (p_FORMAT IS NOT NULL) AND (SUBSTR(p_FORMAT,1,2) <> 'MI') THEN
		v_DATE_STRING := TO_CHAR(TRUNC(p_DATE,p_FORMAT),'YYYY-MM-DD');
	--IF THE DATA IS DAILY OR GREATER, TRUNCATE TO THE INTERVAL.  TIME ZONES NOT NECESSARY.
	ELSIF INTERVAL_IS_ATLEAST_DAILY(p_DATA_INTERVAL) THEN
		v_DATE_STRING := TO_CHAR(TRUNC(p_DATE,p_FORMAT),'YYYY-MM-DD      ');
	ELSE

		v_TIME_ZONE := UPPER(p_TIME_ZONE);
		v_STD_TIME_ZONE := STD_TIME_ZONE(v_TIME_ZONE);
		v_LOCAL_DATE := FROM_CUT(p_DATE, v_STD_TIME_ZONE);

	-- If Standard Time dates then answer the hour-ending date.
		IF v_TIME_ZONE = v_STD_TIME_ZONE THEN
			v_DATE_STRING := TO_HED(v_LOCAL_DATE, p_FORMAT);
		ELSE

	-- If the local date has a sub-hourly specification then move it to the next hour.
			IF TO_NUMBER(TO_CHAR(v_LOCAL_DATE,'MI')) <> 0 AND (p_FORMAT IS NULL OR p_FORMAT = 'HH') THEN
				v_LOCAL_DATE := TRUNC(ADD_HOURS_TO_DATE(v_LOCAL_DATE,1), 'HH');
			END IF;

	-- If Daylight Savings Time date the analyze to determine where the date is in the year.
	 		DAYLIGHT_SAVINGS_TIME(v_LOCAL_DATE, v_IS_DAYLIGHT_SAVINGS, v_IS_TIME_CHANGE_DAY);

	-- Switch the time zone setting to standard time when not in the daylight savings time period.
			IF NOT v_IS_DAYLIGHT_SAVINGS THEN
				v_TIME_ZONE := v_STD_TIME_ZONE;
			END IF;

	-- For Daylight Savings change days (spring and fall) indicate in what time period the hour falls.
		 	IF v_IS_TIME_CHANGE_DAY THEN
	 			IF v_IS_DAYLIGHT_SAVINGS THEN
	 				v_SUFFIX := 'd';
				ELSE
	 				v_SUFFIX := 's';
	 			END IF;
		 	ELSE
				v_SUFFIX := ' ';
			END IF;

			IF p_FORMAT IS NOT NULL AND p_FORMAT NOT IN('HH', 'MI5', 'MI10', 'MI15', 'MI30') THEN
				-- for intervals greater than an hour (daily and up) ignore TZs
				v_SUFFIX := ' ';
				v_DATE_STRING := TO_HED(p_DATE, p_FORMAT);
			ELSE
        v_DATE_STRING := TO_HED(FROM_TZ(CAST(p_DATE AS TIMESTAMP), RO_TZ_OFFSET(CUT_TIME_ZONE)) AT TIME ZONE RO_TZ_OFFSET(v_TIME_ZONE), p_FORMAT) || v_SUFFIX;
       END IF;

	-- Flag the second 1:00-1:59 AM intervals in October with an extra ':' for sub-hourly to achieve proper sort order.
	-- The final AND condition was added due to bug 16243; the logic here was executed on the spring-forward day instead
	-- of just on the fall-back day as intended. If DST ever starts after July instead of March/April, we're in trouble.
			IF v_IS_TIME_CHANGE_DAY AND 
				SUBSTR(v_DATE_STRING,12,2) = LPAD(to_char(DST_FALL_BACK_DATE(p_DATE), 'HH24'),2,'0') AND 
				TO_NUMBER(SUBSTR(v_DATE_STRING,6,2))>7 THEN
				IF  v_SUFFIX = 'd'  THEN
					IF p_FORMAT IS NULL OR p_FORMAT = 'HH' THEN
						v_DATE_STRING := SUBSTR(v_DATE_STRING,1,12) || TO_CHAR(TO_NUMBER(TO_CHAR(DST_FALL_BACK_DATE(p_DATE), 'HH24'))-1) || SUBSTR(v_DATE_STRING,14,3) || 's';
					ELSIF SUBSTR(p_FORMAT,1,2) = 'MI' THEN
						v_DATE_STRING := SUBSTR(v_DATE_STRING,1,12) || TO_CHAR(TO_NUMBER(TO_CHAR(DST_FALL_BACK_DATE(p_DATE), 'HH24'))-1) || ':'|| SUBSTR(v_DATE_STRING,14,3) || 's';
					END IF;
				END IF;
			END IF;
		END IF;
	END IF;

	IF p_DAY_TYPE = GA.STANDARD THEN
		RETURN  v_DATE_STRING;
	ELSIF p_DAY_TYPE = GA.WEEK_DAY THEN
		RETURN SUBSTR(v_DATE_STRING,1,10) || ' WD ' || SUBSTR(v_DATE_STRING,12);
	ELSIF p_DAY_TYPE = GA.WEEK_END THEN
		RETURN SUBSTR(v_DATE_STRING,1,10) || ' WE ' || SUBSTR(v_DATE_STRING,12);
	ELSIF p_DAY_TYPE = GA.ANY_DAY THEN
		RETURN SUBSTR(v_DATE_STRING,1,10) || ' ANY ' || SUBSTR(v_DATE_STRING,12);
	ELSE
		RETURN v_DATE_STRING;
	END IF;

END FROM_CUT_AS_HED;
/
