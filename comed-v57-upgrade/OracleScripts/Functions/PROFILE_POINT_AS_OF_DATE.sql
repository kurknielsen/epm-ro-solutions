CREATE OR REPLACE FUNCTION PROFILE_POINT_AS_OF_DATE
	(
	p_PROFILE_ID IN NUMBER,
	p_POINT_INDEX IN NUMBER,
	p_POINT_DATE IN DATE,
	p_AS_OF_DATE IN DATE
	) RETURN DATE IS
--Revision: $Revision: 1.17 $

-- Answer the maximun as of date that is less than or equal to the argument as of date.

v_AS_OF_DATE DATE := LOW_DATE;

BEGIN

	IF GA.VERSION_PROFILE THEN
		SELECT MAX(AS_OF_DATE)
		INTO v_AS_OF_DATE
		FROM LOAD_PROFILE_POINT
		WHERE PROFILE_ID = p_PROFILE_ID
			AND POINT_INDEX = p_POINT_INDEX
			AND POINT_DATE = p_POINT_DATE
			AND AS_OF_DATE <= p_AS_OF_DATE;
	END IF;

	RETURN v_AS_OF_DATE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN v_AS_OF_DATE;
		WHEN OTHERS THEN
			RAISE;

END PROFILE_POINT_AS_OF_DATE;
/

