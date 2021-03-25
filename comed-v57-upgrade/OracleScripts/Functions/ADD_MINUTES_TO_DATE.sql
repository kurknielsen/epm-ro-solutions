CREATE OR REPLACE FUNCTION ADD_MINUTES_TO_DATE
	(
	p_DATE DATE,
	p_MINUTES NUMBER
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $

--c	Answer a new date that is the specified minutes later in time.

BEGIN

	RETURN p_DATE + (p_MINUTES/1440);

END ADD_MINUTES_TO_DATE;
/

