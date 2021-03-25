CREATE OR REPLACE FUNCTION DATE_TIME_AS_CUT
	(
	p_DATE IN VARCHAR,
	p_TIME IN VARCHAR,
	p_TIME_ZONE IN CHAR,
    p_NULL_TIME_AS_DAY IN NUMBER := 0
	) RETURN DATE IS
--Revision: $Revision: 1.19 $

--c	Answer a CUT date converted from a local date and time string representation.

v_TIME_ZONE CHAR(3);
v_SUFFIX CHAR(1);
v_DATE DATE;
v_TIME VARCHAR(16);
v_NOT_DST_CHANGE_DAY BOOLEAN;

BEGIN

	v_TIME := LTRIM(RTRIM(p_TIME));
	v_TIME_ZONE := LTRIM(RTRIM(p_TIME_ZONE));
	v_SUFFIX := SUBSTR(v_TIME,LENGTH(v_TIME));
	IF v_SUFFIX IN ('d','s') THEN
		v_TIME := SUBSTR(v_TIME, 1, LENGTH(v_TIME) - 1);
		IF v_SUFFIX = 'd' THEN
			v_TIME_ZONE := DST_TIME_ZONE(v_TIME_ZONE);
		ELSE
			IF SUBSTR(v_TIME,3,2) = '::' THEN
				v_TIME := SUBSTR(v_TIME,1,3) || SUBSTR(v_TIME,5);
			END IF;
			v_TIME_ZONE := STD_TIME_ZONE(v_TIME_ZONE);
		END IF;
		v_NOT_DST_CHANGE_DAY := FALSE;
	ELSE
		v_NOT_DST_CHANGE_DAY := TRUE;
	END IF;
	v_DATE := FROM_HED(LTRIM(RTRIM(p_DATE)), v_TIME);
	IF v_NOT_DST_CHANGE_DAY AND NOT IS_IN_DST_TIME_PERIOD(v_DATE) THEN
			v_TIME_ZONE := STD_TIME_ZONE(v_TIME_ZONE);
		END IF;
    IF p_NULL_TIME_AS_DAY = 1 AND v_TIME IS NULL THEN
    	RETURN v_DATE;
    ELSE
		RETURN TO_CUT(v_DATE,v_TIME_ZONE);
    END IF;

END DATE_TIME_AS_CUT;
/
