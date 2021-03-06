CREATE OR REPLACE VIEW EXPORT_FORECAST_CIN_GENCO (THE_DATE, STANDARD_OFFER, DEFAULT_SUPPLY, BUG, THE_AS_OF_DATE) AS
	SELECT C.LOAD_DATE "THE_DATE",
		ROUND(SUM(DECODE (B.SUPPLY_TYPE, 'S',(LOAD_VAL + UFE_LOAD_VAL), 0)),3) "STANDARD_OFFER",
		ROUND(SUM(DECODE (B.SUPPLY_TYPE, 'D',(LOAD_VAL + UFE_LOAD_VAL), 0)),3) "DEFAULT_SUPPLY",
		ROUND(SUM(DECODE (B.IS_BUG, 1, (LOAD_VAL + UFE_LOAD_VAL), 0)),3) "BUG",
		A.AS_OF_DATE "THE_AS_OF_DATE"
	FROM SERVICE_OBLIGATION A, SERVICE_DELIVERY B, SERVICE_OBLIGATION_LOAD C
	WHERE A.MODEL_ID = 1
		AND A.SCENARIO_ID = 1
		AND B.SERVICE_DELIVERY_ID = A.SERVICE_DELIVERY_ID 
		AND B.IS_WHOLESALE = 0
		AND C.SERVICE_OBLIGATION_ID = A.SERVICE_OBLIGATION_ID
		AND C.SERVICE_CODE = 'F'
		AND C.LOAD_CODE = '1'
	GROUP BY C.LOAD_DATE, A.AS_OF_DATE;
