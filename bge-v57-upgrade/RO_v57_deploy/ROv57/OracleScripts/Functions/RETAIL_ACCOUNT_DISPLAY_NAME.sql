CREATE OR REPLACE FUNCTION RETAIL_ACCOUNT_DISPLAY_NAME
--Revision: $Revision: 1.16 $
	(
	p_ACCOUNT_ID IN NUMBER
	) RETURN VARCHAR IS

-- Answer the name used to identify a Retail Account.  Installation may override base behavior.

v_DISPLAY_NAME VARCHAR(64) := 'No Display Name Found';

BEGIN

	SELECT ACCOUNT_NAME
	INTO v_DISPLAY_NAME
	FROM ACCOUNT
	WHERE ACCOUNT_ID = p_ACCOUNT_ID;

	RETURN v_DISPLAY_NAME;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN v_DISPLAY_NAME;
		WHEN OTHERS THEN
			RAISE;

END RETAIL_ACCOUNT_DISPLAY_NAME;
/

