CREATE OR REPLACE VIEW EXTERNAL_METER_ENTITY ( ENTITY_NAME, 
ENTITY_ALIAS, ENTITY_ID ) AS 
SELECT
	METER_NAME "ENTITY_NAME",
	METER_ALIAS "ENTITY_ALIAS",
	METER_ID "ENTITY_ID"
FROM METER M, ACCOUNT_STATUS_NAME A
WHERE METER_ID > 0
	AND M.METER_STATUS = A.STATUS_NAME
	AND A.IS_ACTIVE = 1
	AND IS_EXTERNAL_INTERVAL_USAGE = 1;
