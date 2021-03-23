CREATE OR REPLACE FUNCTION GET_DATA_INTERVAL_TYPE
	(
	p_INTERVAL IN VARCHAR2
	)
	RETURN NUMBER IS
--Revision: $Revision: 1.6 $

--c	Answer 1 (hourly or below) or 2 (daily or above) depending on the type of the interval.

BEGIN

	IF INTERVAL_IS_ATLEAST_DAILY(p_INTERVAL) THEN
		RETURN 2;
	ELSE
		RETURN 1;
	END IF;

END GET_DATA_INTERVAL_TYPE;
/
