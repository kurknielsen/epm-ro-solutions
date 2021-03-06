CREATE OR REPLACE FUNCTION SHADOW_SETTLEMENT_AS_OF_DATE
	(
	p_EDC_ID IN NUMBER,
	p_ESP_ID IN NUMBER,
	p_SETTLEMENT_CODE IN CHAR,
	p_SETTLEMENT_DATE IN DATE,
	p_AS_OF_DATE IN DATE
	) RETURN DATE IS
--Revision: $Revision: 1.17 $

-- Answer the maximun as of date that is less than or equal to the argument as of date.

v_AS_OF_DATE DATE := LOW_DATE;

BEGIN

	IF GA.VERSION_SHADOW_SETTLEMENT THEN
		SELECT MAX(AS_OF_DATE)
		INTO v_AS_OF_DATE
		FROM SHADOW_SETTLEMENT
		WHERE EDC_ID = p_EDC_ID
			AND ESP_ID = p_ESP_ID
			AND SETTLEMENT_CODE = p_SETTLEMENT_CODE
			AND SETTLEMENT_DATE = p_SETTLEMENT_DATE
			AND AS_OF_DATE <= p_AS_OF_DATE;
	END IF;

	RETURN v_AS_OF_DATE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN v_AS_OF_DATE;
		WHEN OTHERS THEN
			RAISE;

END SHADOW_SETTLEMENT_AS_OF_DATE;
/

