CREATE OR REPLACE FUNCTION FROM_GMT
	(
	p_DATE DATE,
	p_TIME_ZONE CHAR
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $
	
--c Deprecated function - replaced by FROM_CUT.
--c	Answer a local date converted from a GMT date for the specified time zone.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM
--c		the last Sunday in October (fall back) has two 2:00 AM hours


BEGIN

	RETURN FROM_CUT(p_DATE, p_TIME_ZONE);
	
END FROM_GMT;
/

