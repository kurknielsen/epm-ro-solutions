CREATE OR REPLACE VIEW METER_LOSS_FACTOR_INFO ( METER_ID, 
LOSS_FACTOR_ID, BEGIN_DATE, END_DATE, ENTRY_DATE, 
LOSS_FACTOR_NAME ) AS 
SELECT M.METER_ID, M.LOSS_FACTOR_ID, M.BEGIN_DATE, M.END_DATE, M.ENTRY_DATE, L.LOSS_FACTOR_NAME
FROM METER_LOSS_FACTOR M, LOSS_FACTOR L
WHERE M.LOSS_FACTOR_ID = L.LOSS_FACTOR_ID;
