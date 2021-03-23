CREATE OR REPLACE VIEW ACCOUNT_METER_EDC_FORECAST ( SCENARIO_ID, 
EDC_ID, FORECAST_DATE, FORECAST_VAL ) AS 
SELECT  
	C.SCENARIO_ID,
	A.EDC_ID,
	C.FORECAST_DATE,
	C.FORECAST_VAL
FROM ACCOUNT_EDC A,
	ACCOUNT_SERVICE_LOCATION_METER B,
	METER_FORECAST C
WHERE A.ACCOUNT_ID = B.ACCOUNT_ID
	AND B.METER_ID = C.METER_ID;