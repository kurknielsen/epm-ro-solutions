CREATE OR REPLACE FUNCTION BEGIN_HOUR_ENDING_CUT_DAY
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_MINUTES IN NUMBER DEFAULT 60
	) RETURN DATE IS
--Revision: $Revision: 1.19 $
	v_FIRST_INTERVAL DATE := ADD_MINUTES_TO_DATE(TRUNC(p_DATE), p_MINUTES);
BEGIN

	-- IF OUR FIRST INTERVAL IS ACTUALLY THE SPRING AHEAD HOUR, SKIP AN HOUR, THAT IS NOT
	-- A VALID DATE TO HAND TO TO_CUT
	IF DST_TIME_ZONE(p_TIME_ZONE) = p_TIME_ZONE AND v_FIRST_INTERVAL = DST_SPRING_AHEAD_DATE(v_FIRST_INTERVAL) THEN
		v_FIRST_INTERVAL := v_FIRST_INTERVAL + 1/24;
	END IF;	

	RETURN TO_CUT(v_FIRST_INTERVAL, p_TIME_ZONE);
END BEGIN_HOUR_ENDING_CUT_DAY;
/

