CREATE OR REPLACE FUNCTION ALIGN_DATE_BY_INTERVAL
	(
	p_DATE IN DATE,
	p_INTERVALS_PER_DAY IN NUMBER
	) RETURN DATE IS
--Revision: $Revision: 1.13 $

-- Answer DATE aligned to the proper period-ending interval, based on intervals per day.
-- For daily intervals the date is TRUNC'd to the day.
-- For sub-daily intervals, subtract 1 second from p_DATE,
-- to get midnight into the proper period-ending day.
-- This makes intervals zero-based, and aligns sub-hourly intervals with their ending hour,
-- by putting the on-hour date into the same hour as the preceding sub-hourly dates.

v_DATE DATE;
v_1SECOND NUMBER := (1/86400);

BEGIN

	IF p_INTERVALS_PER_DAY > 1 THEN
		v_DATE := p_DATE - v_1SECOND;
	ELSE
		v_DATE := TRUNC(p_DATE);
	END IF;

	RETURN v_DATE;

END ALIGN_DATE_BY_INTERVAL;
/

