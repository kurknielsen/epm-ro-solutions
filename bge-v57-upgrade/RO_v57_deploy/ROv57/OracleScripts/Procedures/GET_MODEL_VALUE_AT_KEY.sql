CREATE OR REPLACE PROCEDURE GET_MODEL_VALUE_AT_KEY
	(
	p_MODEL_ID IN NUMBER,
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_MATCH_CASE IN NUMBER := 0,
	p_VALUE OUT VARCHAR
	) AS
--Revision: $Revision: 1.16 $

BEGIN

	p_VALUE := MODEL_VALUE_AT_KEY(p_MODEL_ID, p_KEY1, p_KEY2, p_KEY3, p_MATCH_CASE);

	EXCEPTION
		WHEN OTHERS THEN
			RAISE;

END GET_MODEL_VALUE_AT_KEY;
/
