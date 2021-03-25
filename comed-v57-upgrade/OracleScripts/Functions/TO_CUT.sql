CREATE OR REPLACE FUNCTION TO_CUT
	(
	p_DATE DATE,
	p_TIME_ZONE CHAR
	)
	RETURN DATE IS
--Revision: $Revision: 1.21 $

--c	Answer a CUT date converted from a local date and time zone.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM
--c		the last Sunday in October (fall back) has two 2:00 AM hours
--c		DST is denoted as 2:00:00, STD is denoted as 2:00:01

v_TIME_ZONE CHAR(3);
v_DATE DATE;
BEGIN

	v_TIME_ZONE := UPPER(p_TIME_ZONE);

--c If a DST time zone that is not not currently in the DST period then make it standard time

	IF v_TIME_ZONE = DST_TIME_ZONE(v_TIME_ZONE) AND NOT IS_IN_DST_TIME_PERIOD(p_DATE) THEN
		v_TIME_ZONE := STD_TIME_ZONE(v_TIME_ZONE);
	END IF;

	v_DATE := FROM_TZ(CAST(p_DATE AS TIMESTAMP), RO_TZ_OFFSET(v_TIME_ZONE)) AT TIME ZONE RO_TZ_OFFSET(GA.CUT_TIME_ZONE);

	IF TO_NUMBER(TO_CHAR(v_DATE,'SS')) = 1 THEN
		v_DATE := v_DATE - 0.00001;
	END IF;

	RETURN v_DATE;

END TO_CUT;
/
