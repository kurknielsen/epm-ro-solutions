CREATE OR REPLACE FUNCTION AGGREGATE_ACCOUNT_AS_OF_DATE
	(
	p_AGGREGATE_ID IN NUMBER,
	p_SERVICE_DATE DATE,
	p_AS_OF_DATE IN DATE
	) RETURN DATE IS
--Revision: $Revision: 1.17 $

-- Answer the maximun as of date that is less than or equal to the argument as of date.

v_AS_OF_DATE DATE := LOW_DATE;

BEGIN

	IF GA.VERSION_AGGREGATE_ACCOUNT_SVC THEN
		SELECT MAX(AS_OF_DATE)
		INTO v_AS_OF_DATE
		FROM AGGREGATE_ACCOUNT_SERVICE
		WHERE AGGREGATE_ID = p_AGGREGATE_ID
			AND SERVICE_DATE = p_SERVICE_DATE
			AND AS_OF_DATE <= p_AS_OF_DATE;
	END IF;

	RETURN v_AS_OF_DATE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN v_AS_OF_DATE;
		WHEN OTHERS THEN
			RAISE;

END AGGREGATE_ACCOUNT_AS_OF_DATE;
/
