CREATE OR REPLACE FUNCTION END_CUT_DAY_INTERVAL
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR
	) RETURN DATE IS
--Revision: $Revision: 1.14 $
BEGIN
	RETURN (TO_CUT(TRUNC(p_DATE) + 1, p_TIME_ZONE));
END END_CUT_DAY_INTERVAL;
/

