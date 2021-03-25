CREATE OR REPLACE VIEW EXPORT_TRANSACTION_MEC ( TRANSACTION_ID, 
SCHEDULE_TYPE, SCHEDULE_DATE, AMOUNT, POR, 
POD, PURCHASER_NAME ) AS SELECT  
	 A.TRANSACTION_ID,  
	 A.SCHEDULE_TYPE,  
	 A.SCHEDULE_DATE,  
	 A.AMOUNT,  
	 C.SERVICE_POINT_NAME,  
	 D.SERVICE_POINT_NAME,  
	 E.PSE_NAME  
FROM IT_SCHEDULE A,  
	 INTERCHANGE_TRANSACTION B,  
	 SERVICE_POINT C,  
	 SERVICE_POINT D,  
	 PURCHASING_SELLING_ENTITY E  
WHERE A.TRANSACTION_ID = B.TRANSACTION_ID  
  AND B.POR_ID = C.SERVICE_POINT_ID  
  AND B.POD_ID = D.SERVICE_POINT_ID  
  AND E.PSE_ID = B.PURCHASER_ID;
