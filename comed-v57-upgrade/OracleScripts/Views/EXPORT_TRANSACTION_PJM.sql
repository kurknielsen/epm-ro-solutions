CREATE OR REPLACE VIEW EXPORT_TRANSACTION_PJM ( TRANSACTION_ID, 
SCHEDULE_TYPE, SCHEDULE_STATE, SCHEDULE_DATE, AS_OF_DATE, AMOUNT, 
CONTRACT_NUMBER, CONTRACT_NAME ) AS
SELECT A.TRANSACTION_ID,
	C.SCHEDULE_TYPE,
	C.SCHEDULE_STATE,
	C.SCHEDULE_DATE,
	C.AS_OF_DATE,
	C.AMOUNT,
	B.CONTRACT_NUMBER,
	B.CONTRACT_NAME
FROM INTERCHANGE_TRANSACTION A,
	TP_CONTRACT_NUMBER B,
	IT_SCHEDULE C
WHERE B.CONTRACT_ID = A.CONTRACT_ID
	AND C.TRANSACTION_ID = A.TRANSACTION_ID
	AND C.SCHEDULE_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE,HIGH_DATE);
