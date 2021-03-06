CREATE OR REPLACE VIEW PHYSICAL_POSITION_POD ( NAME, 
ID, SCHEDULE_TYPE, SCHEDULE_DATE ) AS SELECT DISTINCT C.SERVICE_POINT_NAME "NAME",  
		C.SERVICE_POINT_ID "ID",  
		B.SCHEDULE_TYPE,  
		TRUNC(B.SCHEDULE_DATE) "SCHEDULE_DATE" 
	FROM INTERCHANGE_TRANSACTION A,  
		IT_SCHEDULE B,  
		SERVICE_POINT C  
	WHERE A.TRANSACTION_ID = B.TRANSACTION_ID  
		AND A.POD_ID > 0  
		AND A.POD_ID = C.SERVICE_POINT_ID;

