CREATE OR REPLACE VIEW ACCOUNT_METER_FORECAST ( ACCOUNT_ID, 
ACCOUNT_NAME, SERVICE_LOCATION_NAME, SERVICE_LOCATION_ID, METER_NAME, 
METER_ID, SCENARIO_ID, FORECAST_DATE, FORECAST_VAL
 ) AS 
SELECT A.ACCOUNT_ID, A.ACCOUNT_NAME, 
	C.SERVICE_LOCATION_NAME,
	C.SERVICE_LOCATION_ID,
	E.METER_NAME,
	F.METER_ID,
	F.SCENARIO_ID,
	F.FORECAST_DATE,
	F.FORECAST_VAL
FROM RETAIL_ACCOUNT A,
	ACCOUNT_SERVICE_LOCATION B,
	SERVICE_LOCATION C,
	SERVICE_LOCATION_METER D,
	METER E,
	METER_FORECAST F
WHERE F.METER_ID = E.METER_ID
	AND E.METER_ID = D.METER_ID
	AND D.SERVICE_LOCATION_ID = C.SERVICE_LOCATION_ID
	AND C.SERVICE_LOCATION_ID = B.SERVICE_LOCATION_ID
	AND D.BEGIN_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, D.BEGIN_DATE)
	AND B.ACCOUNT_ID = A.ACCOUNT_ID;
