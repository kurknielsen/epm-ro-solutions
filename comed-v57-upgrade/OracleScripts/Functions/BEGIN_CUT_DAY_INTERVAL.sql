CREATE OR REPLACE FUNCTION BEGIN_CUT_DAY_INTERVAL
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_MINUTES IN NUMBER DEFAULT 60
	) RETURN DATE IS
--Revision: $Revision: 1.15 $
BEGIN
	RETURN (TO_CUT(ADD_MINUTES_TO_DATE(TRUNC(p_DATE), p_MINUTES), p_TIME_ZONE));
END BEGIN_CUT_DAY_INTERVAL;
/

