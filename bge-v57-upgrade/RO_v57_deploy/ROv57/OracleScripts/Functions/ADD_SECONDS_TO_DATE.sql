CREATE OR REPLACE FUNCTION ADD_SECONDS_TO_DATE
	(
	p_DATE DATE,
	p_SECONDS NUMBER
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $

--c	Answer a new date that is the specified seconds later (or earlier if < 0) in time.

BEGIN

	RETURN p_DATE + (p_SECONDS / 86400);

END ADD_SECONDS_TO_DATE;
/

