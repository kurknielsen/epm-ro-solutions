CREATE OR REPLACE FUNCTION TO_GMT
	(
	p_DATE DATE,
	p_TIME_ZONE CHAR,
	p_IS_FALL_BACK_HOUR CHAR DEFAULT 'N'
	)
	RETURN DATE IS
	
--Revision: $Revision: 1.17 $

--c Depricated function - replaced by TO_CUT.
--c	Answer a GMT date converted from a local date and time zone.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM.
--c		the last Sunday in October (fall back) has two 2:00 AM hours.

BEGIN

	RETURN TO_CUT(p_DATE, p_TIME_ZONE);

END TO_GMT;
/

