CREATE OR REPLACE FUNCTION WEEK_DAYS_IN_RANGE
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN NUMBER IS
--Revision: $Revision: 1.15 $

--c	Answer the number of weekdays in the given range of dates (inclusive).

v_DATE DATE;
v_WK_DAY NUMBER;
v_WEEK_DAYS NUMBER;

BEGIN

	v_DATE := p_BEGIN_DATE;
	v_WEEK_DAYS := 0;

	-- Loop over the days of the period and count the weekdays.
	WHILE v_DATE <= p_END_DATE LOOP
		SELECT DECODE(TO_CHAR(v_DATE,'DY'),'SAT',0,'SUN',0,1) INTO v_WK_DAY FROM DUAL;
		v_WEEK_DAYS := v_WEEK_DAYS + v_WK_DAY;
		v_DATE := v_DATE + 1;
	END LOOP;

	RETURN v_WEEK_DAYS;

END WEEK_DAYS_IN_RANGE;
/
