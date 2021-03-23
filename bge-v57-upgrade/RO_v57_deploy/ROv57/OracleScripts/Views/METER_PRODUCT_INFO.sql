CREATE OR REPLACE VIEW METER_PRODUCT_INFO ( METER_ID, 
PRODUCT_ID, BEGIN_DATE, END_DATE, PRODUCT_TYPE, 
ENTRY_DATE, PRODUCT_NAME ) AS SELECT M.METER_ID, M.PRODUCT_ID, M.BEGIN_DATE, M.END_DATE, M.PRODUCT_TYPE, M.ENTRY_DATE, P.PRODUCT_NAME 
FROM METER_PRODUCT M, PRODUCT P 
WHERE M.PRODUCT_ID = P.PRODUCT_ID;
