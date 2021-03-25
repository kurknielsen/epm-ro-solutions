CREATE OR REPLACE FUNCTION CONSUMPTION_AS_OF_DATE
	(
	p_SERVICE_ID IN NUMBER,
	p_BEGIN_DATE DATE,
	p_END_DATE DATE,
	p_AS_OF_DATE IN DATE
	) RETURN DATE IS
--Revision: $Revision: 1.17 $

-- Answer the maximun as of date that is less than or equal to the argument as of date.

v_AS_OF_DATE DATE := LOW_DATE;

BEGIN

	IF GA.ENABLE_VERSION_CONSUMPTION THEN
		SELECT MAX(AS_OF_DATE)
		INTO v_AS_OF_DATE
		FROM CONSUMPTION
		WHERE SERVICE_ID = p_SERVICE_ID
			AND BEGIN_DATE = p_BEGIN_DATE
			AND END_DATE = p_END_DATE
			AND AS_OF_DATE <= p_AS_OF_DATE;
	END IF;
	
	RETURN v_AS_OF_DATE;
	
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN v_AS_OF_DATE;
		WHEN OTHERS THEN
			RAISE;

END CONSUMPTION_AS_OF_DATE;
/

