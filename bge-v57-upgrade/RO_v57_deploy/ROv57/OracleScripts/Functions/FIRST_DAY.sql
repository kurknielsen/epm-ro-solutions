CREATE OR REPLACE FUNCTION FIRST_DAY
	(
	p_DATE DATE
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $

--c	Answer the first day of the month in the date specified.

BEGIN

	RETURN LAST_DAY(ADD_MONTHS(TRUNC(p_DATE),-1)) + 1;



END FIRST_DAY;


/


