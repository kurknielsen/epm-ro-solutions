CREATE OR REPLACE FUNCTION BEGIN_HOUR_ENDING_GMT_DAY
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR
	) RETURN DATE IS
--Revision: $Revision: 1.17 $
	
--c Deprecated function - replaced by BEGIN_HOUR_ENDING_CUT_DAY.

BEGIN

	RETURN BEGIN_HOUR_ENDING_CUT_DAY(p_DATE, p_TIME_ZONE);
	
END BEGIN_HOUR_ENDING_GMT_DAY;
/

