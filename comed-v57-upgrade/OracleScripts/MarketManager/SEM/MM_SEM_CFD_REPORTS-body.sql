CREATE OR REPLACE PACKAGE BODY MM_SEM_CFD_REPORTS IS

	-- Private type declarations
	  
	-- Private constant declarations
	c_ALL_TXT_FILTER CONSTANT VARCHAR2(16)   := '<ALL>';

	-- Private variable declarations

	-- Function and procedure implementations

	-- Initialization

	-- Function and procedure implementations
	--------------------------------------------------------------------------------
	FUNCTION WHAT_VERSION RETURN VARCHAR IS
	BEGIN
		RETURN '$Revision: 1.1 $';
	END WHAT_VERSION;
	--------------------------------------------------------------------------------
	PROCEDURE GET_JURISDICTION
	(
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	) AS

	BEGIN
		p_STATUS := GA.SUCCESS;

		OPEN p_CURSOR FOR
			SELECT c_ALL_TXT_FILTER AS "VALUE" FROM DUAL
			UNION ALL
			SELECT DISTINCT S.VALUE
			FROM SYSTEM_LABEL S
			WHERE MODEL_ID = 0
			  AND UPPER(MODULE) = UPPER('MarketExchange')
			  AND UPPER(KEY1) = UPPER('SEM')
			  AND UPPER(KEY2) = UPPER('CFD Jurisdiction')
			  AND NVL(IS_HIDDEN,0) = 0
			ORDER BY 1;
	END;
	--------------------------------------------------------------------------------
	PROCEDURE GET_SUMMARY_OF_TRADES_RPT
	(
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_CONTRACT_IDS IN VARCHAR2,
		p_CURRENCY_FILTER IN VARCHAR2,
		p_JURISDICTION_FILTER IN VARCHAR2,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	) AS
		v_BEGIN_DATE DATE;
		v_END_DATE DATE;
		v_CONTRACT_IDS ID_TABLE;
		v_MIN_INTERVAL_NUMBER NUMBER := GET_INTERVAL_NUMBER('MI30');
		v_IDs NUMBER_COLLECTION;
	BEGIN
		p_STATUS := GA.SUCCESS;

		UT.CUT_DATE_RANGE(TRUNC(p_BEGIN_DATE, 'MM'), LAST_DAY(p_END_DATE), MM_SEM_UTIL.g_TZ, v_BEGIN_DATE, v_END_DATE); 
		
		UT.ID_TABLE_FROM_STRING(p_CONTRACT_IDS, ',', v_CONTRACT_IDS);

		v_IDs := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_SETTLEMENT_F, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_SETTLEMENT);

		OPEN p_CURSOR FOR
			SELECT TRADE_NAME, 
				TRADE_NUMBER,
				TRADE_TYPE,
				CURRENCY,
				JURISDICTION,
				MONTH_STR,
				MONTH_NAME,
				CASE ROW_TYPE WHEN 1 THEN CONTRACT_LEVEL
						WHEN 2 THEN STRIKE_PRICE
						WHEN 3 THEN CONTRACT_VOLUME
						WHEN 4 THEN CONTRACT_COST END AS DATA_VALUE,
				CASE ROW_TYPE WHEN 1 THEN 'Contract Level (MW)'
						WHEN 2 THEN 'Strike Price (Currency/MWh)'
						WHEN 3 THEN 'Contract Volume (MWh)'
						WHEN 4 THEN 'Contract Income (Cost) at Strike Price (MWh)' END AS DATA_TYPE,
				ROW_TYPE,
				-- Calculate the Weighted Avg Unit Price for the entire date range
				(SELECT (CASE WHEN X.BILLING_ENTITY_ID = X.PURCHASER_ID THEN -1 ELSE 1 END) * SUM(S.PRICE * S.AMOUNT)/SUM(S.AMOUNT)
				 FROM IT_SCHEDULE S
				 WHERE S.TRANSACTION_ID = X.TRANSACTION_ID
					AND S.SCHEDULE_TYPE = v_IDs(v_IDs.FIRST)
					AND S.SCHEDULE_STATE = 1
					AND S.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE) AS WEIGHTED_AVG_STRIKE_PRICE
			FROM
				(SELECT T.TRANSACTION_ID,
					T.TRANSACTION_NAME AS TRADE_NAME,					
					T.TRANSACTION_ALIAS AS TRADE_NUMBER,
					C.BILLING_ENTITY_ID,
					C.PURCHASER_ID,
					T.AGREEMENT_TYPE AS TRADE_TYPE,
					CURRENCY,
					JURISDICTION,
					TO_CHAR(SDT.LOCAL_MONTH_TRUNC_DATE, 'YYYY-MM-DD') MONTH_STR,	
					TO_CHAR(SDT.LOCAL_MONTH_TRUNC_DATE, 'Mon YY') "MONTH_NAME",
					-- If the Billing Entity is the Purchaser, the values should be negative
					-- If the Billing Entity is the Seller, the values should be positive
					(CASE WHEN C.BILLING_ENTITY_ID = C.PURCHASER_ID THEN -1 ELSE 1 END) * AVG(S.AMOUNT) AS CONTRACT_LEVEL,
					(CASE WHEN C.BILLING_ENTITY_ID = C.PURCHASER_ID THEN -1 ELSE 1 END) * AVG(S.PRICE) AS STRIKE_PRICE, 
					(CASE WHEN C.BILLING_ENTITY_ID = C.PURCHASER_ID THEN -1 ELSE 1 END) * SUM(S.AMOUNT * 0.5) AS CONTRACT_VOLUME,
					(CASE WHEN C.BILLING_ENTITY_ID = C.PURCHASER_ID THEN -1 ELSE 1 END) * SUM(S.PRICE * S.AMOUNT * 0.5) AS CONTRACT_COST
				FROM TABLE(CAST(v_CONTRACT_IDS AS ID_TABLE)) X,
					INTERCHANGE_CONTRACT C,
					SEM_CFD_CONTRACT SEMC,
					INTERCHANGE_TRANSACTION T,				
					IT_SCHEDULE S,
					SYSTEM_DATE_TIME SDT
				WHERE C.CONTRACT_ID = X.ID
					AND SEMC.CONTRACT_ID = C.CONTRACT_ID
					AND (p_CURRENCY_FILTER = c_ALL_TXT_FILTER OR SEMC.CURRENCY = p_CURRENCY_FILTER)
					AND (p_JURISDICTION_FILTER = c_ALL_TXT_FILTER OR SEMC.JURISDICTION = p_JURISDICTION_FILTER)
					AND T.CONTRACT_ID = C.CONTRACT_ID
					AND S.TRANSACTION_ID = T.TRANSACTION_ID				
					AND S.SCHEDULE_TYPE = v_IDs(v_IDs.FIRST)
					AND S.SCHEDULE_STATE = 1
					AND SDT.CUT_DATE = S.SCHEDULE_DATE
					AND SDT.TIME_ZONE = MM_SEM_UTIL.g_TZ
					AND SDT.DATA_INTERVAL_TYPE = 1
					AND SDT.DAY_TYPE = '1'
					AND SDT.CUT_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
					AND SDT.MINIMUM_INTERVAL_NUMBER >= v_MIN_INTERVAL_NUMBER 
				GROUP BY T.TRANSACTION_ID,
					T.TRANSACTION_NAME,	
					T.TRANSACTION_ALIAS,
					C.BILLING_ENTITY_ID,
					C.PURCHASER_ID,
					SDT.LOCAL_MONTH_TRUNC_DATE, 
					T.AGREEMENT_TYPE,
					CURRENCY,
					JURISDICTION,
					C.BILLING_ENTITY_ID,
					C.PURCHASER_ID
				ORDER BY T.TRANSACTION_NAME,
					T.TRANSACTION_ALIAS, 
					SDT.LOCAL_MONTH_TRUNC_DATE,
					T.AGREEMENT_TYPE,
					CURRENCY,
					JURISDICTION) X,
				(SELECT LEVEL "ROW_TYPE" FROM DUAL CONNECT BY LEVEL <= 4);
	END;
END MM_SEM_CFD_REPORTS;
/
