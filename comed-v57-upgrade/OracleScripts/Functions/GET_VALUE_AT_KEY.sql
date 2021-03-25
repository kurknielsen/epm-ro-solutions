CREATE OR REPLACE FUNCTION GET_VALUE_AT_KEY
	(
	p_KEY IN VARCHAR
	) RETURN VARCHAR IS
--Revision: $Revision: 1.18 $

--c	Answer he value associated with the key.

v_VALUE SYSTEM_DICTIONARY.VALUE%TYPE;

BEGIN

	SELECT VALUE
	INTO v_VALUE
	FROM SYSTEM_DICTIONARY
	WHERE MODEL_ID = 0
		AND KEY1 = p_KEY
		AND KEY2 = '?'
		AND KEY3 = '?';

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_VALUE := NULL;
		WHEN OTHERS THEN
			RAISE;
	RETURN v_VALUE;

END GET_VALUE_AT_KEY;
/

