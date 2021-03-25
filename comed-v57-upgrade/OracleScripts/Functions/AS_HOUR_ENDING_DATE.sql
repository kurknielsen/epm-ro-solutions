CREATE OR REPLACE FUNCTION AS_HOUR_ENDING_DATE
	(
	p_DATE IN DATE
	)
	RETURN DATE IS
--Revision: $Revision: 1.17 $

--c	Answer an hour ending date where any minute specification is rolled forward

v_DATE DATE;

BEGIN

	v_DATE := TO_DATE(TO_CHAR(p_DATE,'MM-DD-YYYY HH24'),'MM-DD-YYYY HH24');
	IF TO_CHAR(p_DATE,'MI') > 0 THEN
		RETURN ADD_MINUTES_TO_DATE(v_DATE, 60);
	END IF;
	RETURN v_DATE;

END AS_HOUR_ENDING_DATE;
/

