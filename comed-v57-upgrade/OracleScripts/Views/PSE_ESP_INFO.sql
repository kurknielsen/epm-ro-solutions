CREATE OR REPLACE VIEW PSE_ESP_INFO ( ESP_ID, 
PSE_ID, BEGIN_DATE, END_DATE, ENTRY_DATE, 
PSE_NAME ) AS SELECT E.ESP_ID, E.PSE_ID, E.BEGIN_DATE, E.END_DATE, E.ENTRY_DATE, P.PSE_NAME
FROM PSE_ESP E, PURCHASING_SELLING_ENTITY P
WHERE E.PSE_ID = P.PSE_ID;

