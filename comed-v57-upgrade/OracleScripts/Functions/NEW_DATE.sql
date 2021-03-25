CREATE OR REPLACE FUNCTION NEW_DATE
	(
	p_DATE IN DATE,
	p_HOUR IN NUMBER
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $

--c	Answer a new date created from the specified date and hour of the day

v_DATE DATE;
v_HOUR NUMBER;

BEGIN

	v_HOUR := MOD(p_HOUR,24);
	v_DATE := TRUNC(p_DATE) + (p_HOUR / 24);
	RETURN (TO_DATE(TO_CHAR(v_DATE,'DD-MON-YYYY ') || TO_CHAR(v_HOUR),'DD-MON-YYYY HH24'));

END NEW_DATE;
/


















