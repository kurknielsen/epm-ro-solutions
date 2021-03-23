CREATE OR REPLACE VIEW SERVICE_LOCATION_METER_CHANNEL ( ACCOUNT_ID, 
SERVICE_LOCATION_BEGIN_DATE, SERVICE_LOCATION_END_DATE, SERVICE_LOCATION_NAME, SERVICE_LOCATION_ID, 
METER_BEGIN_DATE, METER_END_DATE, METER_NAME, METER_ID, 
METER_STATUS, METER_TYPE, CHANNEL_NUMBER, CHANNEL_ID, 
CHANNEL_UNIT, CHANNEL_STATUS ) AS 
SELECT A.ACCOUNT_ID,
	A.BEGIN_DATE "SERVICE_LOCATION_BEGIN_DATE",
	A.END_DATE "SERVICE_LOCATION_END_DATE",
	B.SERVICE_LOCATION_NAME,
	B.SERVICE_LOCATION_ID,
	C.BEGIN_DATE "METER_BEGIN_DATE",
	C.END_DATE "METER_END_DATE",
	D.METER_NAME,
	D.METER_ID,
	D.METER_STATUS,
	D.METER_TYPE,
	E.CHANNEL_NUMBER,
	E.CHANNEL_ID,
	E.CHANNEL_UNIT,
	E.CHANNEL_STATUS
FROM ACCOUNT_SERVICE_LOCATION A,
	SERVICE_LOCATION B,
	SERVICE_LOCATION_METER C,
	METER D,
	METER_CHANNEL E
WHERE A.SERVICE_LOCATION_ID = B.SERVICE_LOCATION_ID
	AND B.SERVICE_LOCATION_ID = C.SERVICE_LOCATION_ID
	AND C.METER_ID = D.METER_ID
	AND C.BEGIN_DATE BETWEEN A.BEGIN_DATE AND NVL(A.END_DATE, C.BEGIN_DATE)
	AND D.METER_ID = E.METER_ID;
