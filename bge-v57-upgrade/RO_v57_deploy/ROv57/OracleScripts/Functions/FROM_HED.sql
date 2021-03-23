CREATE OR REPLACE FUNCTION FROM_HED
	(
	p_DATE IN VARCHAR,
	p_TIME IN VARCHAR
	)
	RETURN DATE IS
--Revision: $Revision: 1.19 $

--c Answer a date from an hour ending date and time string format
--c Date format: YYYY-MM-DD.
--c Time format: HH24:MI.

v_DATE_TIME VARCHAR(32);
v_DATE DATE;
v_HOUR NUMBER(2);
v_MIN NUMBER(2);
v_TIME VARCHAR(8);

BEGIN

	IF p_TIME IS NULL OR LENGTH(p_TIME) = 0 THEN
		RETURN ADD_SECONDS_TO_DATE(TO_DATE(p_DATE, 'YYYY-MM-DD'), 1);
	END IF;

	v_TIME := LTRIM(RTRIM(p_TIME));
	IF NOT INSTR(v_TIME,':') = 3 THEN -- Assume missing leading zero or space.
	   v_TIME := '0' || v_TIME;
      END IF;

	v_HOUR := TO_NUMBER(SUBSTR(v_TIME,1,2));
	v_MIN := TO_NUMBER(SUBSTR(v_TIME,4,2));

	IF (v_HOUR < 1 AND v_MIN = 0) OR v_HOUR > 24 THEN
		ERRS.RAISE(MSGCODES.c_ERR_INVALID_DATE, 'INVALID FROM_HED TIME SPECIFICATION - VALID HOUR RANGE 1-24');
	END IF;

	IF v_HOUR = 24 THEN
		v_DATE := TO_DATE(p_DATE || '00:' || SUBSTR(v_TIME,4,2),'YYYY-MM-DDHH24:MI') + 1;
	ELSE
		v_DATE := TO_DATE(p_DATE || v_TIME, 'YYYY-MM-DDHH24:MI');
	END IF;

	RETURN v_DATE;

END FROM_HED;
/