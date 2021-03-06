ALTER TABLE MARKET_PRICE_VALUE DISABLE CONSTRAINT FK_MARKET_PRICE_VALUE;
DECLARE
v_ID NUMBER(9) := 101;
BEGIN
   INSERT INTO MARKET_PRICE(MARKET_PRICE_ID, MARKET_PRICE_NAME, MARKET_PRICE_ALIAS, MARKET_PRICE_DESC, MARKET_PRICE_TYPE, MARKET_PRICE_INTERVAL, MARKET_TYPE, COMMODITY_ID, SERVICE_POINT_TYPE, EXTERNAL_IDENTIFIER, EDC_ID, SC_ID, POD_ID, ZOD_ID, ENTRY_DATE)
   SELECT MARKET_PRICE_ID, MARKET_PRICE_NAME, MARKET_PRICE_ALIAS, MARKET_PRICE_DESC, MARKET_PRICE_TYPE, MARKET_PRICE_INTERVAL, MARKET_TYPE, COMMODITY_ID, SERVICE_POINT_TYPE, EXTERNAL_IDENTIFIER, 101 "EDC_ID", 101 "SC_ID", 101 "POD_ID", ZOD_ID, ENTRY_DATE FROM X_MARKET_PRICE;
   INSERT INTO MARKET_PRICE_VALUE(MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
   SELECT MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE FROM X_MARKET_PRICE_VALUE;
   FOR v_SELECT IN (SELECT MARKET_PRICE_ID FROM MARKET_PRICE WHERE MARKET_PRICE_ID > 0 ORDER BY MARKET_PRICE_NAME) LOOP
      UPDATE MARKET_PRICE_VALUE SET MARKET_PRICE_ID = v_ID WHERE MARKET_PRICE_ID = v_SELECT.MARKET_PRICE_ID;
      UPDATE MARKET_PRICE       SET MARKET_PRICE_ID = v_ID WHERE MARKET_PRICE_ID = v_SELECT.MARKET_PRICE_ID;
      v_ID := v_ID + 1;
   END LOOP;
   UPDATE MARKET_PRICE SET MARKET_PRICE_TYPE = 'Marginal Congestion Component', EXTERNAL_IDENTIFIER = SUBSTR(EXTERNAL_IDENTIFIER,1,5) WHERE MARKET_PRICE_NAME = 'BGE CONG';
   UPDATE MARKET_PRICE SET MARKET_PRICE_TYPE = 'Marginal Loss Component',       EXTERNAL_IDENTIFIER = SUBSTR(EXTERNAL_IDENTIFIER,1,5) WHERE MARKET_PRICE_NAME = 'BGE LOSS';
   UPDATE MARKET_PRICE SET MARKET_PRICE_TYPE = 'Energy Component' WHERE MARKET_PRICE_NAME = 'PJM System Energy Price';
   UPDATE MARKET_PRICE SET MARKET_TYPE = 'RealTime' WHERE MARKET_TYPE = 'Real-Time';
   COMMIT;
END;   
/
ALTER TABLE MARKET_PRICE_VALUE ENABLE CONSTRAINT FK_MARKET_PRICE_VALUE;
