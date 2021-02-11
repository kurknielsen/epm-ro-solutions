CREATE OR REPLACE VIEW CDI_COMED_PLC_NSPL_SCHEDULE$ AS
SELECT A.TRANSACTION_ID                                                             "TRANSACTION_ID",
   A.TRANSACTION_NAME                                                               "TRANSACTION_NAME",
   CASE WHEN SUBSTR (TRANSACTION_IDENTIFIER, 1, 1) = 'P' THEN 'PLC' ELSE 'NSPL' END "SERVICE_TYPE",
   B.SCHEDULE_GROUP_NAME                                                            "SUPPLIER_TYPE",
   C.PSE_ALIAS                                                                      "SUPPLIER_NAME",
   D.CONTRACT_NAME                                                                  "PJM_SHORT_NAME",
   TRUNC(E.SCHEDULE_DATE)                                                           "SCHEDULE_DATE",
   MAX(CASE WHEN E.SCHEDULE_STATE = 1 THEN E.AMOUNT ELSE NULL END)                  "INTERNAL_AMOUNT",
   MAX(CASE WHEN E.SCHEDULE_STATE = 2 THEN E.AMOUNT ELSE NULL END)                  "EXTERNAL_AMOUNT"
FROM INTERCHANGE_TRANSACTION      A
   JOIN SCHEDULE_GROUP            B ON B.SCHEDULE_GROUP_ID = A.SCHEDULE_GROUP_ID AND B.SCHEDULE_GROUP_NAME = 'EGS'
   JOIN PURCHASING_SELLING_ENTITY C ON C.PSE_ID = A.PSE_ID
   JOIN TP_CONTRACT_NUMBER        D ON D.CONTRACT_ID = A.CONTRACT_ID
   JOIN IT_SCHEDULE               E ON E.TRANSACTION_ID = A.TRANSACTION_ID AND E.SCHEDULE_TYPE = 3 AND E.SCHEDULE_STATE IN(1,2) AND E.SCHEDULE_DATE BETWEEN D.BEGIN_DATE AND NVL(D.END_DATE+(1/86400), TO_DATE('12/31/9999','MM/DD/YYYY'))
WHERE A.TRANSACTION_TYPE = 'Ancillary'
   AND A.TRANSACTION_IDENTIFIER IN ('Peak Load Capacity', 'Network Service Peak Load')
GROUP BY A.TRANSACTION_ID, A.TRANSACTION_NAME, CASE WHEN SUBSTR(TRANSACTION_IDENTIFIER,1,1) = 'P' THEN 'PLC' ELSE 'NSPL' END, B.SCHEDULE_GROUP_NAME, C.PSE_ALIAS, D.CONTRACT_NAME, TRUNC(E.SCHEDULE_DATE);
