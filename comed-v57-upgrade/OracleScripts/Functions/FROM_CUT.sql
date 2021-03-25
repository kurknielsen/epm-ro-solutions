CREATE OR REPLACE FUNCTION FROM_CUT
	(
	p_DATE DATE,
	p_TIME_ZONE VARCHAR
	)
	RETURN DATE IS
--Revision: $Revision: 1.21 $

--c	Answer a local date converted from a CUT date for the specified time zone.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM
--c		the last Sunday in October (fall back) has two 2:00 AM hours

v_TIME_ZONE VARCHAR(3);
v_LOCAL_DATE DATE;
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_STD_TIME_ZONE VARCHAR(3);
BEGIN

	v_TIME_ZONE := UPPER(p_TIME_ZONE);
	v_STD_TIME_ZONE := STD_TIME_ZONE(v_TIME_ZONE);

	v_LOCAL_DATE := FROM_TZ(CAST(p_DATE AS TIMESTAMP), RO_TZ_OFFSET(GA.CUT_TIME_ZONE)) AT TIME ZONE RO_TZ_OFFSET(v_STD_TIME_ZONE);

-- If standard time dates then answer the hour-ending date.
	IF v_TIME_ZONE = v_STD_TIME_ZONE THEN
		RETURN v_LOCAL_DATE;
	END IF;

--  Calculate the begin and end of DST in terms of standard time.
	v_BEGIN_DATE := DST_SPRING_AHEAD_DATE(v_LOCAL_DATE);
	v_END_DATE := DST_FALL_BACK_DATE(v_LOCAL_DATE);


-- Switch the time zone setting to standard time when not in the daylight savings time period.
	IF NOT (v_LOCAL_DATE >= v_BEGIN_DATE AND v_LOCAL_DATE < v_END_DATE)  THEN
	   v_TIME_ZONE := v_STD_TIME_ZONE;
	END IF;

	IF v_LOCAL_DATE = v_END_DATE THEN
	   v_LOCAL_DATE := ADD_SECONDS_TO_DATE(v_LOCAL_DATE,1);
	END IF;

	RETURN FROM_TZ(CAST(v_LOCAL_DATE AS TIMESTAMP), RO_TZ_OFFSET(v_STD_TIME_ZONE)) AT TIME ZONE RO_TZ_OFFSET(v_TIME_ZONE);
END FROM_CUT;
/
