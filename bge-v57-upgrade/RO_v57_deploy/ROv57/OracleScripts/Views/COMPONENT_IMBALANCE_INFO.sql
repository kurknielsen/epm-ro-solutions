CREATE OR REPLACE VIEW COMPONENT_IMBALANCE_INFO ( COMPONENT_ID, 
BEGIN_DATE, END_DATE, SERVICE_POINT_ID, UNDER_UNDER_PRICE_ID, 
UNDER_OVER_PRICE_ID, IMBALANCE_TYPE, ACCUMULATION_PERIOD, OVER_UNDER_PRICE_ID, 
OVER_OVER_PRICE_ID, IS_PERCENT, IS_PRORATE, SETTLEMENT_AGENT, 
BAND_ID, ENTRY_DATE, SERVICE_POINT_NAME, UNDER_UNDER_PRICE_NAME,  
UNDER_OVER_PRICE_NAME, OVER_UNDER_PRICE_NAME, OVER_OVER_PRICE_NAME, BASE_COMPONENT_ID, BASE_LIMIT_ID ) AS SELECT I.COMPONENT_ID, I.BEGIN_DATE, I.END_DATE, I.SERVICE_POINT_ID,
        I.UNDER_UNDER_PRICE_ID, I.UNDER_OVER_PRICE_ID, T.IMBALANCE_TYPE, T.ACCUMULATION_PERIOD,
        I.OVER_UNDER_PRICE_ID, I.OVER_OVER_PRICE_ID, I.IS_PERCENT, I.IS_PRORATE,
        I.SETTLEMENT_AGENT, I.IMBALANCE_ID, I.ENTRY_DATE, S.SERVICE_POINT_NAME,
        A.MARKET_PRICE_NAME AS UNDER_UNDER_PRICE_NAME,
        B.MARKET_PRICE_NAME AS UNDER_OVER_PRICE_NAME,
        C.MARKET_PRICE_NAME AS OVER_UNDER_PRICE_NAME,
        D.MARKET_PRICE_NAME AS OVER_OVER_PRICE_NAME,
		T.BASE_COMPONENT_ID, T.BASE_LIMIT_ID
FROM COMPONENT_IMBALANCE I, COMPONENT T, SERVICE_POINT S, MARKET_PRICE A, MARKET_PRICE B,
		MARKET_PRICE C, MARKET_PRICE D
WHERE I.COMPONENT_ID = T.COMPONENT_ID
	AND I.SERVICE_POINT_ID = S.SERVICE_POINT_ID(+)
	AND I.UNDER_UNDER_PRICE_ID = A.MARKET_PRICE_ID(+)
	AND I.UNDER_OVER_PRICE_ID = B.MARKET_PRICE_ID(+)
	AND I.OVER_UNDER_PRICE_ID = C.MARKET_PRICE_ID(+)
	AND I.OVER_OVER_PRICE_ID = D.MARKET_PRICE_ID(+);