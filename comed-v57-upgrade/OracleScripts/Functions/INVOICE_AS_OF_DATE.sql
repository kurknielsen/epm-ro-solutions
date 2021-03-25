CREATE OR REPLACE FUNCTION INVOICE_AS_OF_DATE
	(
	p_ENTITY_ID IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_STATEMENT_STATE IN NUMBER,
	p_INVOICE_DATE IN DATE,
	p_AS_OF_DATE IN DATE
	) RETURN DATE IS
--Revision: $Revision: 1.20 $

-- Answer the maximun as of date that is less than or equal to the argument as of date.

v_AS_OF_DATE DATE := LOW_DATE;

BEGIN

	IF GA.VERSION_STATEMENT THEN
		SELECT MAX(AS_OF_DATE)
		INTO v_AS_OF_DATE
		FROM INVOICE
		WHERE ENTITY_ID = p_ENTITY_ID
			AND STATEMENT_TYPE = p_STATEMENT_TYPE
			AND STATEMENT_STATE = p_STATEMENT_STATE
			AND BEGIN_DATE <= p_INVOICE_DATE
            AND END_DATE >= p_INVOICE_DATE
			AND AS_OF_DATE <= p_AS_OF_DATE;
	END IF;

	RETURN v_AS_OF_DATE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN v_AS_OF_DATE;
		WHEN OTHERS THEN
			RAISE;

END INVOICE_AS_OF_DATE;
/