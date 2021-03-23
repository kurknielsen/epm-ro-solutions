CREATE OR REPLACE FUNCTION TO_HED
	(
	p_DATE IN DATE,
	p_FORMAT IN VARCHAR := NULL
	)
	RETURN VARCHAR IS
--Revision: $Revision: 1.26 $

-- Answer a formatted date and time string representing an interval ending date

v_DATE_TIME VARCHAR(32);
v_DATE DATE := p_DATE;
v_BOUNDARY_DATE BOOLEAN;

BEGIN

-- Determine if the date falls on a day boundary.

	v_BOUNDARY_DATE := TO_CHAR(p_DATE, 'HH24:MI:SS') = '00:00:00';

	-- If a boundary day then subtract a second from the date to get the day ocurrence to be the same.
    	IF v_BOUNDARY_DATE THEN
    		v_DATE := v_DATE - .00001;
    	END IF;

	IF p_FORMAT IS NOT NULL AND p_FORMAT NOT IN('HH', 'MI5', 'MI10', 'MI15', 'MI30') THEN
			v_DATE_TIME := TO_CHAR(TRUNC(v_DATE, p_FORMAT),'YYYY-MM-DD      ');
	ELSE

		IF v_BOUNDARY_DATE THEN
			v_DATE_TIME := TO_CHAR(v_DATE,'YYYY-MM-DD ') || '24:00';
		ELSIF p_FORMAT IS NULL OR p_FORMAT = 'HH' THEN
			IF TO_CHAR(v_DATE,'MI') = '00' THEN
				v_DATE_TIME :=  TO_CHAR(TRUNC(v_DATE, 'HH24'), 'YYYY-MM-DD HH24:MI');
			ELSIF TO_CHAR(v_DATE, 'HH24') = '23' THEN
				v_DATE_TIME := TO_CHAR(v_DATE, 'YYYY-MM-DD ') || '24:00';
			ELSE
				v_DATE_TIME :=  TO_CHAR(TRUNC(v_DATE, 'HH24') + 1/24, 'YYYY-MM-DD HH24:MI');
			END IF;
		ELSIF p_FORMAT = 'MI30' THEN
			IF TO_CHAR(v_DATE,'MI') = '00' THEN
				v_DATE_TIME := TO_CHAR(v_DATE, 'YYYY-MM-DD HH24:MI');
			ELSIF TO_NUMBER(TO_CHAR(v_DATE,'MI')) <= 30 THEN
				v_DATE_TIME :=  TO_CHAR(v_DATE, 'YYYY-MM-DD HH24:') || '30';
			ELSE
				IF TO_CHAR(v_DATE, 'HH24') = '23' THEN
					v_DATE_TIME := TO_CHAR(v_DATE, 'YYYY-MM-DD ') || '24:00';
				ELSE
					v_DATE_TIME :=  TO_CHAR(v_DATE + 1/24, 'YYYY-MM-DD HH24:') || '00';
				END IF;
			END IF;
		ELSE
			v_DATE_TIME :=  TO_CHAR(v_DATE, 'YYYY-MM-DD HH24:MI');
		END IF;
	END IF;

	RETURN v_DATE_TIME;

END TO_HED;
/
