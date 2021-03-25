CREATE OR REPLACE FUNCTION IS_IN_DST_TIME_PERIOD
	(
	p_DATE DATE
	)
	RETURN BOOLEAN IS

--Revision: $Revision: 1.17 $

--c	Answer TRUE if a date falls within the DEFINED daylight savings time period.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM
--c		the last Sunday in October (fall back) has two 2:00 AM hours

BEGIN

	RETURN (p_DATE BETWEEN DST_SPRING_AHEAD_DATE(p_DATE) AND DST_FALL_BACK_DATE(p_DATE));

END IS_IN_DST_TIME_PERIOD;
/

