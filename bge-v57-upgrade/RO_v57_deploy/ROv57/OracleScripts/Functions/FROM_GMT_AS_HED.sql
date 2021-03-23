CREATE OR REPLACE FUNCTION FROM_GMT_AS_HED
	(
	p_DATE DATE,
	p_TIME_ZONE CHAR,
	p_FORMAT VARCHAR := NULL
	)
	RETURN VARCHAR IS
--Revision: $Revision: 1.17 $

--c Deprecated function - replaced by FROM_CUT_AS_HED.
--c	Answer a local date converted from a GMT date for the specified time zone.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM.
--c		the last Sunday in October (fall back) has two 2:00 AM hours.
--c The date string is an hour ending date with an optional DST/STD indicator.

BEGIN

    RETURN FROM_CUT_AS_HED(p_DATE, p_TIME_ZONE, p_FORMAT);
	
END FROM_GMT_AS_HED;
/

