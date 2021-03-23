CREATE OR REPLACE PACKAGE BODY MM_SEM_CFD_UTIL IS

-------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
	RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
--------------------------------------------------------------------------------
FUNCTION PUT_MARKET_PRICE(p_PRICE_NAME IN MARKET_PRICE.MARKET_PRICE_NAME%TYPE,
						  p_PRICE_DATE IN MARKET_PRICE_VALUE.PRICE_DATE%TYPE,
						  p_PRICE IN MARKET_PRICE_VALUE.PRICE%TYPE) RETURN NUMBER IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_PRICE_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
	v_STATUS NUMBER;
	v_ERROR_MESSAGE VARCHAR2(256);
BEGIN
	-- look up the price ID
	ID.ID_FOR_MARKET_PRICE(p_PRICE_NAME, FALSE, v_PRICE_ID);
	IF v_PRICE_ID <= 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'No market price found for name ' || p_PRICE_NAME);
	END IF;
	MM_UTIL.PUT_MARKET_PRICE_VALUE(p_MARKET_PRICE_ID => v_PRICE_ID,
								   p_PRICE_DATE      => p_PRICE_DATE,
								   p_PRICE_CODE      => 'A',
								   p_PRICE           => p_PRICE,
								   p_PRICE_BASIS     => NULL,
								   p_STATUS          => v_STATUS,
								   p_ERROR_MESSAGE   => v_ERROR_MESSAGE);
	IF v_STATUS != GA.SUCCESS THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot store price value ' || p_PRICE || ' for date ' ||
				TO_CHAR(p_PRICE_DATE, 'DD-MON-YYYY HH24:MI') || ' for  Market Price Name: "' ||
				p_PRICE_NAME || '"');
	END IF;
	COMMIT;
	RETURN NULL;
END PUT_MARKET_PRICE;
-------------------------------------------------------------------------------------------

END MM_SEM_CFD_UTIL;
/
