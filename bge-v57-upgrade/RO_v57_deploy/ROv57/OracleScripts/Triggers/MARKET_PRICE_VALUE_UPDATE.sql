CREATE OR REPLACE TRIGGER MARKET_PRICE_VALUE_UPDATE 
	BEFORE INSERT OR UPDATE ON MARKET_PRICE_VALUE 
	FOR EACH ROW 
BEGIN 
	IF NOT GA.VERSION_MARKET_PRICE THEN
		:new.AS_OF_DATE := LOW_DATE; 
	END IF; 
END MARKET_PRICE_VALUE_UPDATE;
/ 
