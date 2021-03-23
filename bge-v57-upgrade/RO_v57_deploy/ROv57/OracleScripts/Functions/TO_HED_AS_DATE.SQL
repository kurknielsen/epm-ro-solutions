CREATE OR REPLACE FUNCTION TO_HED_AS_DATE
	(
	p_DATE IN DATE
	)
	RETURN DATE IS
--Revision: $Revision: 1.18 $

-- Handle the hour ending date problem where the 24:00 hour is specified as 00:00 of the next day.
-- For this situation back the date up by 1 second so that it is associated with the correct day.

BEGIN

	IF p_DATE = TRUNC(p_DATE) THEN
		RETURN p_DATE-1/86400;
	ELSE
		RETURN p_DATE;
	END IF;

END TO_HED_AS_DATE;
/
