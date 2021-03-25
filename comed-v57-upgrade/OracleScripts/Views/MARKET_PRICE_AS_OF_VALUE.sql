CREATE OR REPLACE FORCE VIEW MARKET_PRICE_AS_OF_VALUE
(MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, PRICE_BASIS, PRICE)
AS 
SELECT MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, PRICE_BASIS, PRICE
FROM MARKET_PRICE_VALUE A
WHERE A.AS_OF_DATE = (SELECT MAX(AS_OF_DATE) FROM MARKET_PRICE_VALUE WHERE MARKET_PRICE_ID = A.MARKET_PRICE_ID AND PRICE_CODE = A.PRICE_CODE AND PRICE_DATE = A.PRICE_DATE AND AS_OF_DATE <= SYSDATE);