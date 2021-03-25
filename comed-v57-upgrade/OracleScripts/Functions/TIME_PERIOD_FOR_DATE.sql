CREATE OR REPLACE FUNCTION TIME_PERIOD_FOR_DATE
	(
	p_DATE DATE
	)
	RETURN CHAR IS
--Revision: $Revision: 1.17 $

--c	Answer a 2 character string that indicates the following:
--c 	'S ' - Standard time in effect (non-transition date)
--c 	'S*' - Standard time in effect (transition date)
--c		'D ' - Daylight Savings time in effect (non-transition date)
--c		'D*' - Daylight Savings time in effect (transition date)

v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_DAY DATE;
v_TIME CHAR(1);
v_TRANSITION CHAR(1);

BEGIN

	v_BEGIN_DATE := DST_SPRING_AHEAD_DATE(p_DATE);
	v_END_DATE := DST_FALL_BACK_DATE(p_DATE);

	v_DAY := TRUNC(p_DATE);
	
	IF p_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE THEN
		v_TIME := 'D';
	ELSE
		v_TIME := 'S';
	END IF;

	IF v_DAY = TRUNC(v_BEGIN_DATE) OR v_DAY = TRUNC(v_END_DATE) THEN
		v_TRANSITION := '*';	
	ELSE
		v_TRANSITION := ' ';	
	END IF;

	RETURN v_TIME || v_TRANSITION;
	
END TIME_PERIOD_FOR_DATE;



/

