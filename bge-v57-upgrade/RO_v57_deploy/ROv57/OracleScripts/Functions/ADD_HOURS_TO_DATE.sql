CREATE OR REPLACE FUNCTION ADD_HOURS_TO_DATE
	(
	p_DATE DATE,
	p_HOURS NUMBER
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $

--c	Answer a new date that is the specified hours later in time.

BEGIN

	RETURN p_DATE + (p_HOURS/24);

END ADD_HOURS_TO_DATE;
/

