CREATE OR REPLACE VIEW ACCOUNT_BILLED_USAGE_SUMMARY AS 
SELECT A.ACCOUNT_NAME,
	B.ACCOUNT_ID,
	B.BEGIN_DATE,
	B.END_DATE,
	NVL(B.BILLED_USAGE,0),
	NVL(B.METERED_USAGE,0),
	NVL(B.BILLED_DEMAND,0),
	NVL(B.METERED_DEMAND,0),
	B.ENTRY_DATE
FROM RETAIL_ACCOUNT A,
	ACCOUNT_BILLED_USAGE B
WHERE A.ACCOUNT_ID = B.ACCOUNT_ID;