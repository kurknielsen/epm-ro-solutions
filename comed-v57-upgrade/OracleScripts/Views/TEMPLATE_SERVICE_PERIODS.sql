CREATE OR REPLACE VIEW TEMPLATE_SERVICE_PERIODS ( PERIOD_NAME, 
PERIOD_ID, SERVICE_ID ) AS 
SELECT DISTINCT
	A.PERIOD_NAME,
	A.PERIOD_ID,
	B.SERVICE_ID
FROM PERIOD A,
	TX_SERVICE B,
	SEASON_TEMPLATE C
WHERE B.TEMPLATE_ID = C.TEMPLATE_ID
	AND C.PERIOD_ID = A.PERIOD_ID;