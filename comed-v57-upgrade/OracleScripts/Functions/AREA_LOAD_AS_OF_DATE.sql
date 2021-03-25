CREATE OR REPLACE FUNCTION AREA_LOAD_AS_OF_DATE
	(
	p_AREA_ID IN NUMBER,
	p_LOAD_CODE IN CHAR,
	p_LOAD_DATE DATE,
	p_AS_OF_DATE IN DATE
	) RETURN DATE IS
--Revision: $Revision: 1.19 $

-- Answer the maximun as of date that is less than or equal to the argument as of date.

v_AS_OF_DATE DATE := LOW_DATE;

BEGIN

	IF GA.VERSION_AREA_LOAD THEN
		SELECT MAX(AS_OF_DATE)
		INTO v_AS_OF_DATE
		FROM AREA_LOAD
		WHERE AREA_ID = p_AREA_ID
			AND LOAD_CODE = p_LOAD_CODE
			AND LOAD_DATE = p_LOAD_DATE
			AND AS_OF_DATE <= p_AS_OF_DATE;
	END IF;

	RETURN NVL(v_AS_OF_DATE, LOW_DATE);

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN v_AS_OF_DATE;
	WHEN OTHERS THEN
		RAISE;
END AREA_LOAD_AS_OF_DATE;
/

