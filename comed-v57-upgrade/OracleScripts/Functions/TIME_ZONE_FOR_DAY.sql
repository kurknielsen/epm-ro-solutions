CREATE OR REPLACE FUNCTION TIME_ZONE_FOR_DAY
	(
	p_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR
	)
	RETURN CHAR IS
--Revision: $Revision: 1.17 $

--c	Answer the time zone in effect for the specified day date and time zone encoding.
--c The time zone encoding is a time zone abbreviation and is interpreted as follows:
--c 	position 1 - time zone (Eastern,Central,Mountain,Pacific)
--c		position 2 - daylight savings observed in time zone (D=Daylight Savings,S=Standard)
--c		position 3 - not used, always T

BEGIN

	IF p_TIME_ZONE = STD_TIME_ZONE(p_TIME_ZONE) THEN
		RETURN p_TIME_ZONE;
	END IF;

	IF IS_IN_DST_TIME_PERIOD(TRUNC(p_DATE)) THEN
		RETURN DST_TIME_ZONE(p_TIME_ZONE);
	ELSE
		RETURN STD_TIME_ZONE(p_TIME_ZONE);
	END IF;

END TIME_ZONE_FOR_DAY;
/

