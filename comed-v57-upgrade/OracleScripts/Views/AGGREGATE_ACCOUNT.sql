CREATE OR REPLACE VIEW AGGREGATE_ACCOUNT ( ACCOUNT_NAME, 
ACCOUNT_ID, SERVICE_DATE, SERVICE_ACCOUNTS ) AS 
SELECT  
	A.ACCOUNT_NAME,
	B.ACCOUNT_ID,
	B.SERVICE_DATE,
	B.SERVICE_ACCOUNTS
FROM RETAIL_ACCOUNT A,
	AGGREGATE_ACCOUNTS_SERVED B
WHERE A.ACCOUNT_ID = B.ACCOUNT_ID;