CREATE OR REPLACE VIEW ACCOUNT_SERVICE_LOCATION_EDC ( ACCOUNT_NAME, 
					ACCOUNT_ID, ACCOUNT_MODEL_OPTION, BEGIN_DATE, END_DATE, 
					SERVICE_LOCATION_NAME, EDC_BEGIN_DATE, EDC_END_DATE, EDC_NAME, 
					EDC_ID ) AS
SELECT A.ACCOUNT_NAME,
	A.ACCOUNT_ID,
	A.ACCOUNT_MODEL_OPTION,
	C.BEGIN_DATE,
	C.END_DATE,
	DECODE(A.IS_AGGREGATE_ACCOUNT,1,'Aggregate Account', D.SERVICE_LOCATION_NAME),
	E.BEGIN_DATE "EDC_BEGIN_DATE",
	E.END_DATE "EDC_END_DATE",
	F.EDC_NAME,
	F.EDC_ID
FROM ACCOUNT A,
	ACCOUNT_STATUS B,
	ACCOUNT_SERVICE_LOCATION C,
	SERVICE_LOCATION D,
	ACCOUNT_EDC E,
	ENERGY_DISTRIBUTION_COMPANY F,
	ACCOUNT_STATUS_NAME G
WHERE B.ACCOUNT_ID = A.ACCOUNT_ID
	AND TRUNC(SYSDATE) BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, HIGH_DATE)
	AND G.STATUS_NAME = B.STATUS_NAME
	AND G.IS_ACTIVE = 1   
	AND C.ACCOUNT_ID = B.ACCOUNT_ID   
	AND D.SERVICE_LOCATION_ID = C.SERVICE_LOCATION_ID
	AND E.ACCOUNT_ID = C.ACCOUNT_ID
	AND F.EDC_ID = E.EDC_ID;
