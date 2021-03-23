CREATE OR REPLACE FUNCTION AS_DAY
	(
	p_DATE IN DATE
	)
	RETURN VARCHAR IS
--Revision: $Revision: 1.17 $

--c	Answer a formatted date and time string representing a day

BEGIN

	RETURN TO_CHAR(TRUNC(p_DATE),'MM-DD-YYYY      ');

END AS_DAY;
/

