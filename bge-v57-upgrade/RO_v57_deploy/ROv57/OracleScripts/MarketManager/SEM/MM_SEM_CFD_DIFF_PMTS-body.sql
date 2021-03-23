CREATE OR REPLACE PACKAGE BODY MM_SEM_CFD_DIFF_PMTS IS

	c_TIME_ZONE                      CONSTANT VARCHAR2(3) := 'EDT';
	c_CFD_PRODUCT_ID                 CONSTANT NUMBER := EI.GET_ID_FROM_NAME('CfD Products', EC.ED_PRODUCT);
	c_CFD_COMPONENT_ID               CONSTANT NUMBER := EI.GET_ID_FROM_NAME('CFD', EC.ED_COMPONENT);
	c_LOW_DATE                       CONSTANT DATE := DATE '1900-01-01';
	c_ALL_TXT_FILTER                 CONSTANT VARCHAR2(16)   := '<ALL>'; 
	c_ALL_INT_FILTER                 CONSTANT INTEGER        := -1;   
	c_STATEMENT_MONTH_DATE_FMT       CONSTANT VARCHAR2(16) := 'YYYY-MM-DD';
	c_VAT_SCHEDULE_TYPE_ID           CONSTANT NUMBER(1) := 3;
----------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------
PROCEDURE CACHE_DIFF_PAYMENTS_DETAILS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TRANSACTION_IDS IN NUMBER_COLLECTION,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_VAT_STYLE_FILTER IN VARCHAR2
	) AS
BEGIN

	--Clear out temp table.
	EXECUTE IMMEDIATE 'TRUNCATE TABLE SEM_CFD_DIFF_PMTS_TEMP DROP STORAGE';

	INSERT INTO SEM_CFD_DIFF_PMTS_TEMP
		(
		TRANSACTION_ID, 
		CHARGE_DATE, 
		TRANSACTION_NAME, 
		TRANSACTION_ALIAS, 
		LOCAL_DATE_STR, 
		LOCAL_MONTH, 
		LOCAL_DAY, 
		LOCAL_TIME, 
		CURRENCY, 
		VAT_RATE, 
		CONTRACT_LEVEL, 
		SMP, 
		STRIKE_PRICE, 
		COST_AT_SMP, 
		COST_AT_STRIKE_PRICE, 
		CHARGE_AMOUNT, 
		CONTRACT_LEVEL_2, 
		SMP_2, 
		STRIKE_PRICE_2, 
		COST_AT_SMP_2, 
		COST_AT_STRIKE_PRICE_2, 
		CHARGE_AMOUNT_2
		)
	SELECT TRANSACTION_ID,
		CHARGE_DATE,
		TRANSACTION_NAME,
		TRANSACTION_ALIAS,
		FROM_CUT_AS_HED(CHARGE_DATE, c_TIME_ZONE, 'MI30'), -- LOCAL_DATE_STR
		TRUNC(FROM_CUT(CHARGE_DATE, c_TIME_ZONE) - 1/86400, 'MM'), --LOCAL_MONTH
		TRUNC(FROM_CUT(CHARGE_DATE, c_TIME_ZONE) - 1/86400), -- LOCAL_DAY
		TIME_FROM_CUT_AS_HED(CHARGE_DATE, c_TIME_ZONE, 'MI30'), -- LOCAL_TIME
		CURRENCY,
		VAT_RATE,
		CONTRACT_LEVEL,
		SMP,
		STRIKE_PRICE,
		COST_AT_INDEX_MULT * SMP * CONTRACT_LEVEL, --COST_AT_SMP
		COST_AT_INDEX_MULT * STRIKE_PRICE * CONTRACT_LEVEL, --COST_AT_STRIKE_PRICE
		CHARGE_AMOUNT,
		OTHER_CONTRACT_LEVEL,
		OTHER_SMP,
		OTHER_STRIKE_PRICE,
		COST_AT_INDEX_MULT * OTHER_SMP * OTHER_CONTRACT_LEVEL, --COST_AT_SMP
		COST_AT_INDEX_MULT * OTHER_STRIKE_PRICE * OTHER_CONTRACT_LEVEL, --COST_AT_STRIKE_PRICE
		OTHER_CHARGE_AMOUNT
	FROM
		(
		SELECT T.TRANSACTION_ID,
			FC.CHARGE_DATE,
			T.TRANSACTION_NAME,
			T.TRANSACTION_ALIAS,
			SEMC.CURRENCY "CURRENCY",
			VAT.AMOUNT "VAT_RATE",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID THEN AMOUNT.VARIABLE_VAL ELSE NULL END) "CONTRACT_LEVEL",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID THEN SMP.VARIABLE_VAL ELSE NULL END) "SMP",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID THEN STRIKE_PRICE.VARIABLE_VAL ELSE NULL END) "STRIKE_PRICE",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID THEN FC.CHARGE_AMOUNT ELSE NULL END
				* CASE p_VAT_STYLE_FILTER WHEN 'Net' THEN 1 WHEN 'VAT' THEN VAT.AMOUNT ELSE 1 + VAT.AMOUNT END) "CHARGE_AMOUNT",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID_2 THEN AMOUNT.VARIABLE_VAL ELSE NULL END) "OTHER_CONTRACT_LEVEL",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID_2 THEN SMP.VARIABLE_VAL ELSE NULL END) "OTHER_SMP",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID_2 THEN STRIKE_PRICE.VARIABLE_VAL ELSE NULL END) "OTHER_STRIKE_PRICE",
			SUM(CASE WHEN B.STATEMENT_TYPE = p_STATEMENT_TYPE_ID_2 THEN FC.CHARGE_AMOUNT ELSE NULL END
				* CASE p_VAT_STYLE_FILTER WHEN 'Net' THEN 1 WHEN 'VAT' THEN VAT.AMOUNT ELSE 1 + VAT.AMOUNT END) "OTHER_CHARGE_AMOUNT",
			MAX(CASE WHEN C.BILLING_ENTITY_ID = C.PURCHASER_ID THEN -0.5 ELSE 0.5 END
				* CASE p_VAT_STYLE_FILTER WHEN 'Net' THEN 1 WHEN 'VAT' THEN VAT.AMOUNT ELSE 1 + VAT.AMOUNT END) "COST_AT_INDEX_MULT"
		FROM TABLE(CAST(p_TRANSACTION_IDS AS NUMBER_COLLECTION)) X,
			INTERCHANGE_TRANSACTION T, 
			INTERCHANGE_CONTRACT C,
			SEM_CFD_CONTRACT SEMC,
			SEM_CFD_DEAL SEMD,
			BILLING_STATEMENT B,
			FORMULA_CHARGE_ITERATOR FCI,
			FORMULA_CHARGE FC,
			FORMULA_CHARGE_VARIABLE STRIKE_PRICE,
			FORMULA_CHARGE_VARIABLE SMP,
			FORMULA_CHARGE_VARIABLE AMOUNT,
			IT_SCHEDULE VAT
		WHERE T.TRANSACTION_ID = X.COLUMN_VALUE
			AND C.CONTRACT_ID = T.CONTRACT_ID
			AND SEMC.CONTRACT_ID = C.CONTRACT_ID
			AND SEMD.TRANSACTION_ID = T.TRANSACTION_ID
			AND B.ENTITY_ID = C.BILLING_ENTITY_ID
			AND B.PRODUCT_ID = c_CFD_PRODUCT_ID
			AND B.COMPONENT_ID = c_CFD_COMPONENT_ID
			AND B.STATEMENT_TYPE IN (p_STATEMENT_TYPE_ID, p_STATEMENT_TYPE_ID_2)
			AND B.STATEMENT_STATE = GA.INTERNAL_STATE
			AND B.STATEMENT_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
			AND FCI.CHARGE_ID = B.CHARGE_ID
			AND FCI.ITERATOR2 = TO_CHAR(T.TRANSACTION_ID)
			AND FC.CHARGE_ID = B.CHARGE_ID
			AND FC.ITERATOR_ID = FCI.ITERATOR_ID
			AND STRIKE_PRICE.CHARGE_ID = FC.CHARGE_ID
			AND STRIKE_PRICE.ITERATOR_ID = FC.ITERATOR_ID
			AND STRIKE_PRICE.CHARGE_DATE = FC.CHARGE_DATE
			AND STRIKE_PRICE.VARIABLE_NAME = 'StrikePrice'
			AND SMP.CHARGE_ID = FC.CHARGE_ID
			AND SMP.ITERATOR_ID = FC.ITERATOR_ID
			AND SMP.CHARGE_DATE = FC.CHARGE_DATE
			AND SMP.VARIABLE_NAME = 'SMP'
			AND AMOUNT.CHARGE_ID = FC.CHARGE_ID
			AND AMOUNT.ITERATOR_ID = FC.ITERATOR_ID
			AND AMOUNT.CHARGE_DATE = FC.CHARGE_DATE
			AND AMOUNT.VARIABLE_NAME = 'ContractLevel'
			AND VAT.TRANSACTION_ID = SEMD.DIFF_PMT_VAT_TXN_ID
			AND VAT.SCHEDULE_TYPE = c_VAT_SCHEDULE_TYPE_ID
			AND VAT.SCHEDULE_STATE = GA.INTERNAL_STATE
			AND VAT.SCHEDULE_DATE = TRUNC(FROM_CUT(FC.CHARGE_DATE, c_TIME_ZONE) - 1/86400) + 1/86400
			AND VAT.AS_OF_DATE = c_LOW_DATE
		GROUP BY T.TRANSACTION_ID,
			FC.CHARGE_DATE,
			T.TRANSACTION_NAME,
			T.TRANSACTION_ALIAS,
			SEMC.CURRENCY,
			VAT.AMOUNT
		);

END CACHE_DIFF_PAYMENTS_DETAILS;
-------------------------------------------------------------
FUNCTION GET_FILTERED_TRANSACTION_IDS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CONTRACT_IDS IN VARCHAR2,
	p_CONTRACT_TYPE_FILTER IN VARCHAR2,
	p_AGREEMENT_TYPE_FILTER IN VARCHAR2,
	p_COUNTERPARTY_ID_FILTER IN NUMBER,
	p_CURRENCY_FILTER IN VARCHAR2
	) RETURN NUMBER_COLLECTION IS
	v_IDS NUMBER_COLLECTION;
	v_CONTRACT_IDS ID_TABLE;
BEGIN
	UT.ID_TABLE_FROM_STRING(p_CONTRACT_IDS, ',', v_CONTRACT_IDS);

	SELECT T.TRANSACTION_ID
	BULK COLLECT INTO v_IDS
	FROM TABLE(CAST(v_CONTRACT_IDS AS ID_TABLE)) X, 
		INTERCHANGE_TRANSACTION T, 
		INTERCHANGE_CONTRACT C,
		SEM_CFD_CONTRACT SEMC,
		SEM_CFD_DEAL SEMD
	 WHERE T.CONTRACT_ID = X.ID
		AND SEMC.CONTRACT_ID = C.CONTRACT_ID
		AND T.BEGIN_DATE <= p_END_DATE
		AND T.END_DATE >= p_BEGIN_DATE
		AND C.CONTRACT_ID = T.CONTRACT_ID
		AND SEMD.TRANSACTION_ID = T.TRANSACTION_ID
		AND (p_CONTRACT_TYPE_FILTER = c_ALL_TXT_FILTER OR C.CONTRACT_TYPE = p_CONTRACT_TYPE_FILTER)
		AND (p_AGREEMENT_TYPE_FILTER = c_ALL_TXT_FILTER OR C.AGREEMENT_TYPE = p_AGREEMENT_TYPE_FILTER)
		AND (p_COUNTERPARTY_ID_FILTER = c_ALL_INT_FILTER OR C.PURCHASER_ID = p_COUNTERPARTY_ID_FILTER OR C.SELLER_ID = p_COUNTERPARTY_ID_FILTER)
		AND (p_CURRENCY_FILTER = c_ALL_TXT_FILTER OR SEMC.CURRENCY = p_CURRENCY_FILTER);

	RETURN v_IDS;

END GET_FILTERED_TRANSACTION_IDS;
-------------------------------------------------------------
PROCEDURE GET_MONTHLY_INVOICE_DATA_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CONTRACT_IDS IN VARCHAR2,
	p_CONTRACT_TYPE_FILTER IN VARCHAR2,
	p_AGREEMENT_TYPE_FILTER IN VARCHAR2,
	p_COUNTERPARTY_ID_FILTER IN NUMBER,
	p_CURRENCY_FILTER IN VARCHAR2,
   	p_STATEMENT_TYPE IN NUMBER,
	p_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_SHOW_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_STATEMENT_TYPE_NAME_1 OUT VARCHAR2,
	p_STATEMENT_TYPE_NAME_2 OUT VARCHAR2,
	p_CURSOR IN OUT SYS_REFCURSOR
	) AS
	v_STATEMENT_TYPE_ID_2 NUMBER := CASE p_SHOW_STATEMENT_TYPE_ID_2 WHEN 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END;
	v_TRANSACTION_IDS NUMBER_COLLECTION;
BEGIN
	p_STATEMENT_TYPE_NAME_1 := EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, p_STATEMENT_TYPE);
	p_STATEMENT_TYPE_NAME_2 := CASE WHEN v_STATEMENT_TYPE_ID_2 > 0 THEN EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, v_STATEMENT_TYPE_ID_2) ELSE NULL END;
	v_TRANSACTION_IDS := GET_FILTERED_TRANSACTION_IDS(p_BEGIN_DATE,	p_END_DATE,	p_CONTRACT_IDS,	p_CONTRACT_TYPE_FILTER,	p_AGREEMENT_TYPE_FILTER, p_COUNTERPARTY_ID_FILTER, p_CURRENCY_FILTER);

	CACHE_DIFF_PAYMENTS_DETAILS(TRUNC(p_BEGIN_DATE,'MM'),
		LAST_DAY(p_END_DATE), 
		v_TRANSACTION_IDS, 
		p_STATEMENT_TYPE, 
		CASE WHEN p_SHOW_STATEMENT_TYPE_ID_2 = 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END, 
		'Net');

	OPEN p_CURSOR FOR
		SELECT TRANSACTION_NAME, TRANSACTION_ID, CURRENCY, STATEMENT_MONTH_STR, MONTH_NAME, VAT_RATE,
			ROW_TYPE,
			CASE ROW_TYPE WHEN 1 THEN p_STATEMENT_TYPE_NAME_1 WHEN 2 THEN p_STATEMENT_TYPE_NAME_2 ELSE p_STATEMENT_TYPE_NAME_1 || ' - ' || p_STATEMENT_TYPE_NAME_2 END "ST_NAME",
			CASE ROW_TYPE WHEN 1 THEN CHARGE_AMOUNT
				WHEN 2 THEN OTHER_CHARGE_AMOUNT
				WHEN 3 THEN CHARGE_AMOUNT - OTHER_CHARGE_AMOUNT END "RAW_AMOUNT"
		FROM
			(
			SELECT TRANSACTION_NAME, 
				TRANSACTION_ID, 
				CURRENCY,
				TO_CHAR(LOCAL_MONTH, 'YYYY-MM-DD') "STATEMENT_MONTH_STR",
				TO_CHAR(LOCAL_MONTH, 'Month YYYY') "MONTH_NAME",
				VAT_RATE,
				SUM(CHARGE_AMOUNT) "CHARGE_AMOUNT",
				SUM(CHARGE_AMOUNT_2) "OTHER_CHARGE_AMOUNT"
			FROM SEM_CFD_DIFF_PMTS_TEMP
			GROUP BY TRANSACTION_NAME, TRANSACTION_ID, CURRENCY, LOCAL_MONTH, VAT_RATE
			),
			(SELECT LEVEL "ROW_TYPE" FROM DUAL CONNECT BY LEVEL <= CASE p_SHOW_STATEMENT_TYPE_ID_2 WHEN 0 THEN 1 ELSE 3 END)
		ORDER BY TRANSACTION_NAME, STATEMENT_MONTH_STR;

END GET_MONTHLY_INVOICE_DATA_RPT;
-------------------------------------------------------------
PROCEDURE GET_DIFF_PAYMENTS_SUMMARY_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CONTRACT_IDS IN VARCHAR2,
	p_CONTRACT_TYPE_FILTER IN VARCHAR2,
	p_AGREEMENT_TYPE_FILTER IN VARCHAR2,
	p_COUNTERPARTY_ID_FILTER IN NUMBER,
	p_CURRENCY_FILTER IN VARCHAR2,
   	p_STATEMENT_TYPE IN NUMBER,
	p_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_SHOW_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_VAT_STYLE_FILTER IN VARCHAR2,
	p_STATEMENT_TYPE_NAME_1 OUT VARCHAR2,
	p_STATEMENT_TYPE_NAME_2 OUT VARCHAR2,
	p_CURSOR IN OUT SYS_REFCURSOR
	) AS
	v_STATEMENT_TYPE_ID_2 NUMBER := CASE p_SHOW_STATEMENT_TYPE_ID_2 WHEN 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END;
	v_TRANSACTION_IDS NUMBER_COLLECTION;
BEGIN
	p_STATEMENT_TYPE_NAME_1 := EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, p_STATEMENT_TYPE);
	p_STATEMENT_TYPE_NAME_2 := CASE WHEN v_STATEMENT_TYPE_ID_2 > 0 THEN EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, v_STATEMENT_TYPE_ID_2) ELSE NULL END;
	v_TRANSACTION_IDS := GET_FILTERED_TRANSACTION_IDS(p_BEGIN_DATE,	p_END_DATE,	p_CONTRACT_IDS,	p_CONTRACT_TYPE_FILTER,	p_AGREEMENT_TYPE_FILTER, p_COUNTERPARTY_ID_FILTER, p_CURRENCY_FILTER);

	CACHE_DIFF_PAYMENTS_DETAILS(TRUNC(p_BEGIN_DATE,'MM'),
		LAST_DAY(p_END_DATE), 
		v_TRANSACTION_IDS, 
		p_STATEMENT_TYPE, 
		CASE WHEN p_SHOW_STATEMENT_TYPE_ID_2 = 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END, 
		p_VAT_STYLE_FILTER);

--TODO: Add Dispute column.

	OPEN p_CURSOR FOR
		SELECT TRANSACTION_NAME, TRANSACTION_ID, CURRENCY, STATEMENT_MONTH_STR, MONTH_NAME,
			ROW_TYPE,
			CASE ROW_TYPE WHEN 1 THEN p_STATEMENT_TYPE_NAME_1 WHEN 2 THEN p_STATEMENT_TYPE_NAME_2 ELSE p_STATEMENT_TYPE_NAME_1 || ' - ' || p_STATEMENT_TYPE_NAME_2 END "ST_NAME",
			CASE ROW_TYPE WHEN 1 THEN CHARGE_AMOUNT
				WHEN 2 THEN CHARGE_AMOUNT_2
				WHEN 3 THEN CHARGE_AMOUNT - CHARGE_AMOUNT_2 END "RAW_AMOUNT"
		FROM
			(
			SELECT TRANSACTION_NAME, 
				TRANSACTION_ID, 
				CURRENCY,
				TO_CHAR(LOCAL_MONTH, 'YYYY-MM-DD') "STATEMENT_MONTH_STR",
				TO_CHAR(LOCAL_MONTH, 'Month YYYY') "MONTH_NAME",
				SUM(CHARGE_AMOUNT) "CHARGE_AMOUNT",
				SUM(CHARGE_AMOUNT_2) "CHARGE_AMOUNT_2"
			FROM SEM_CFD_DIFF_PMTS_TEMP
			GROUP BY TRANSACTION_NAME, TRANSACTION_ID, CURRENCY, LOCAL_MONTH
			),
			(SELECT LEVEL "ROW_TYPE" FROM DUAL CONNECT BY LEVEL <= CASE p_SHOW_STATEMENT_TYPE_ID_2 WHEN 0 THEN 1 ELSE 3 END)
		ORDER BY TRANSACTION_NAME, STATEMENT_MONTH_STR;

END GET_DIFF_PAYMENTS_SUMMARY_RPT;
-------------------------------------------------------------
PROCEDURE GET_DIFF_PAYMENTS_DETAIL_RPT
	(
	p_STATEMENT_MONTH_STR IN VARCHAR2,
	p_TRANSACTION_ID IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_SHOW_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_VAT_STYLE_FILTER IN VARCHAR2,
	p_STATEMENT_TYPE_NAME_1 OUT VARCHAR2,
	p_STATEMENT_TYPE_NAME_2 OUT VARCHAR2,
	p_CURSOR IN OUT SYS_REFCURSOR
	) AS
	v_STATEMENT_MONTH DATE := TO_DATE(p_STATEMENT_MONTH_STR, c_STATEMENT_MONTH_DATE_FMT);
	v_STATEMENT_TYPE_ID_2 NUMBER := CASE p_SHOW_STATEMENT_TYPE_ID_2 WHEN 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END;
BEGIN
	p_STATEMENT_TYPE_NAME_1 := EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, p_STATEMENT_TYPE);
	p_STATEMENT_TYPE_NAME_2 := CASE WHEN v_STATEMENT_TYPE_ID_2 > 0 THEN EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, v_STATEMENT_TYPE_ID_2) ELSE NULL END;
	
	CACHE_DIFF_PAYMENTS_DETAILS(TRUNC(v_STATEMENT_MONTH,'MM'),
		LAST_DAY(v_STATEMENT_MONTH), 
		NUMBER_COLLECTION(p_TRANSACTION_ID), 
		p_STATEMENT_TYPE, 
		CASE WHEN p_SHOW_STATEMENT_TYPE_ID_2 = 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END, 
		p_VAT_STYLE_FILTER);

	OPEN p_CURSOR FOR
		SELECT TRANSACTION_NAME, LOCAL_DATE_STR "LOCAL_DATE", ROW_TYPE,
			CASE ROW_TYPE WHEN 1 THEN p_STATEMENT_TYPE_NAME_1 WHEN 2 THEN p_STATEMENT_TYPE_NAME_2 ELSE p_STATEMENT_TYPE_NAME_1 || ' - ' || p_STATEMENT_TYPE_NAME_2 END "ST_NAME",
			CASE ROW_TYPE WHEN 1 THEN CHARGE_AMOUNT
				WHEN 2 THEN CHARGE_AMOUNT_2
				WHEN 3 THEN CHARGE_AMOUNT - CHARGE_AMOUNT_2 END "CHARGE_AMOUNT",
			CASE ROW_TYPE WHEN 1 THEN SMP
				WHEN 2 THEN SMP_2
				WHEN 3 THEN SMP - SMP_2 END "SMP",
			CASE ROW_TYPE WHEN 1 THEN STRIKE_PRICE
				WHEN 2 THEN STRIKE_PRICE_2
				WHEN 3 THEN STRIKE_PRICE - STRIKE_PRICE_2 END "STRIKE_PRICE",
			0.5* CASE ROW_TYPE WHEN 1 THEN CONTRACT_LEVEL
				WHEN 2 THEN CONTRACT_LEVEL_2
				WHEN 3 THEN CONTRACT_LEVEL - CONTRACT_LEVEL_2 END "CONTRACT_QUANTITY",
			CASE ROW_TYPE WHEN 1 THEN COST_AT_SMP
				WHEN 2 THEN COST_AT_SMP_2
				WHEN 3 THEN COST_AT_SMP - COST_AT_SMP_2 END "COST_AT_SMP",
			CASE ROW_TYPE WHEN 1 THEN COST_AT_STRIKE_PRICE
				WHEN 2 THEN COST_AT_STRIKE_PRICE_2
				WHEN 3 THEN COST_AT_STRIKE_PRICE - COST_AT_STRIKE_PRICE_2 END "COST_AT_STRIKE_PRICE"
		FROM SEM_CFD_DIFF_PMTS_TEMP,
		(SELECT LEVEL "ROW_TYPE" FROM DUAL CONNECT BY LEVEL <= CASE p_SHOW_STATEMENT_TYPE_ID_2 WHEN 0 THEN 1 ELSE 3 END )
		ORDER BY 1,2;

END GET_DIFF_PAYMENTS_DETAIL_RPT;
-------------------------------------------------------------
PROCEDURE GET_DIFF_PAYMENTS_MATRIX_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CONTRACT_IDS IN VARCHAR2,
	p_CONTRACT_TYPE_FILTER IN VARCHAR2,
	p_AGREEMENT_TYPE_FILTER IN VARCHAR2,
	p_COUNTERPARTY_ID_FILTER IN NUMBER,
	p_CURRENCY_FILTER IN VARCHAR2,
   	p_STATEMENT_TYPE IN NUMBER,
	p_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_SHOW_STATEMENT_TYPE_ID_2 IN NUMBER,
	p_MATRIX_TYPE_FILTER IN VARCHAR2,
	p_STATEMENT_TYPE_NAME_1 OUT VARCHAR2,
	p_STATEMENT_TYPE_NAME_2 OUT VARCHAR2,
	p_CURSOR IN OUT SYS_REFCURSOR
	) AS
	v_STATEMENT_TYPE_ID_2 NUMBER := CASE p_SHOW_STATEMENT_TYPE_ID_2 WHEN 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END;
	v_TRANSACTION_IDS NUMBER_COLLECTION;
	v_BEGIN_DATE DATE;
	v_END_DATE DATE;
	v_MIN_INTERVAL_NUMBER NUMBER := GET_INTERVAL_NUMBER('MI30');
BEGIN
	p_STATEMENT_TYPE_NAME_1 := EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, p_STATEMENT_TYPE);
	p_STATEMENT_TYPE_NAME_2 := CASE WHEN v_STATEMENT_TYPE_ID_2 > 0 THEN EI.GET_ENTITY_NAME(EC.ED_STATEMENT_TYPE, v_STATEMENT_TYPE_ID_2) ELSE NULL END;
	
	v_TRANSACTION_IDS := GET_FILTERED_TRANSACTION_IDS(p_BEGIN_DATE,	p_END_DATE,	p_CONTRACT_IDS,	p_CONTRACT_TYPE_FILTER,	p_AGREEMENT_TYPE_FILTER, p_COUNTERPARTY_ID_FILTER, p_CURRENCY_FILTER);
	UT.CUT_DATE_RANGE(TRUNC(p_BEGIN_DATE, 'DD'), TRUNC(p_END_DATE, 'DD'), MM_SEM_UTIL.g_TZ, v_BEGIN_DATE, v_END_DATE);

	CACHE_DIFF_PAYMENTS_DETAILS(TRUNC(p_BEGIN_DATE,'MM'),
		LAST_DAY(p_END_DATE), 
		v_TRANSACTION_IDS, 
		p_STATEMENT_TYPE, 
		CASE WHEN p_SHOW_STATEMENT_TYPE_ID_2 = 0 THEN NULL ELSE p_STATEMENT_TYPE_ID_2 END, 
		p_MATRIX_TYPE_FILTER);

	OPEN p_CURSOR FOR
		SELECT DAY_STR,
			CURRENCY,
			SUM(DECODE(HOUR_STR, '0030', AMOUNT)) "HR_0030",
			SUM(DECODE(HOUR_STR, '0100', AMOUNT)) "HR_0100",
			SUM(DECODE(HOUR_STR, '0130', AMOUNT)) "HR_0130",
			SUM(DECODE(HOUR_STR, '0200', AMOUNT)) "HR_0200",
			SUM(DECODE(HOUR_STR, '0230', AMOUNT)) "HR_0230",
			SUM(DECODE(HOUR_STR, '0300', AMOUNT)) "HR_0300",
			SUM(DECODE(HOUR_STR, '0330', AMOUNT)) "HR_0330",
			SUM(DECODE(HOUR_STR, '0400', AMOUNT)) "HR_0400",
			SUM(DECODE(HOUR_STR, '0430', AMOUNT)) "HR_0430",
			SUM(DECODE(HOUR_STR, '0500', AMOUNT)) "HR_0500",
			SUM(DECODE(HOUR_STR, '0530', AMOUNT)) "HR_0530",
			SUM(DECODE(HOUR_STR, '0600', AMOUNT)) "HR_0600",
			SUM(DECODE(HOUR_STR, '0630', AMOUNT)) "HR_0630",
			SUM(DECODE(HOUR_STR, '0700', AMOUNT)) "HR_0700",
			SUM(DECODE(HOUR_STR, '0730', AMOUNT)) "HR_0730",
			SUM(DECODE(HOUR_STR, '0800', AMOUNT)) "HR_0800",
			SUM(DECODE(HOUR_STR, '0830', AMOUNT)) "HR_0830",
			SUM(DECODE(HOUR_STR, '0900', AMOUNT)) "HR_0900",
			SUM(DECODE(HOUR_STR, '0930', AMOUNT)) "HR_0930",
			SUM(DECODE(HOUR_STR, '1000', AMOUNT)) "HR_1000",
			SUM(DECODE(HOUR_STR, '1030', AMOUNT)) "HR_1030",
			SUM(DECODE(HOUR_STR, '1100', AMOUNT)) "HR_1100",
			SUM(DECODE(HOUR_STR, '1130', AMOUNT)) "HR_1130",
			SUM(DECODE(HOUR_STR, '1200', AMOUNT)) "HR_1200",
			SUM(DECODE(HOUR_STR, '1230', AMOUNT)) "HR_1230",
			SUM(DECODE(HOUR_STR, '1300', AMOUNT)) "HR_1300",
			SUM(DECODE(HOUR_STR, '1330', AMOUNT)) "HR_1330",
			SUM(DECODE(HOUR_STR, '1400', AMOUNT)) "HR_1400",
			SUM(DECODE(HOUR_STR, '1430', AMOUNT)) "HR_1430",
			SUM(DECODE(HOUR_STR, '1500', AMOUNT)) "HR_1500",
			SUM(DECODE(HOUR_STR, '1530', AMOUNT)) "HR_1530",
			SUM(DECODE(HOUR_STR, '1600', AMOUNT)) "HR_1600",
			SUM(DECODE(HOUR_STR, '1630', AMOUNT)) "HR_1630",
			SUM(DECODE(HOUR_STR, '1700', AMOUNT)) "HR_1700",
			SUM(DECODE(HOUR_STR, '1730', AMOUNT)) "HR_1730",
			SUM(DECODE(HOUR_STR, '1800', AMOUNT)) "HR_1800",
			SUM(DECODE(HOUR_STR, '1830', AMOUNT)) "HR_1830",
			SUM(DECODE(HOUR_STR, '1900', AMOUNT)) "HR_1900",
			SUM(DECODE(HOUR_STR, '1930', AMOUNT)) "HR_1930",
			SUM(DECODE(HOUR_STR, '2000', AMOUNT)) "HR_2000",
			SUM(DECODE(HOUR_STR, '2030', AMOUNT)) "HR_2030",
			SUM(DECODE(HOUR_STR, '2100', AMOUNT)) "HR_2100",
			SUM(DECODE(HOUR_STR, '2130', AMOUNT)) "HR_2130",
			SUM(DECODE(HOUR_STR, '2200', AMOUNT)) "HR_2200",
			SUM(DECODE(HOUR_STR, '2230', AMOUNT)) "HR_2230",
			SUM(DECODE(HOUR_STR, '2300', AMOUNT)) "HR_2300",
			SUM(DECODE(HOUR_STR, '2330', AMOUNT)) "HR_2330",
			SUM(DECODE(HOUR_STR, '2400', AMOUNT)) "HR_2400",
			SUM(DECODE(HOUR_STR, '0130''', AMOUNT)) "HR_0130'",
			SUM(DECODE(HOUR_STR, '0200''', AMOUNT)) "HR_0200'"
		FROM (SELECT TRIM(SDT.DAY_YYYY_MM_DD) AS DAY_STR,
					CURRENCY,
					CASE
						-- For a 25 hour day, 48 values in chronological order but ignoring the repeated hour, 
						-- followed by two values representing the repeated hour.
						WHEN SDT.IS_DST_FALL_BACK_DAY = 1 AND TO_CHAR(LOCAL_DATE, 'SS') = '01' 
						 	THEN TO_CHAR(LOCAL_DATE,'HH24MI') || ''''
						-- For a 23 hour days, 2 values in chronological order, followed by two null or zero values 
						-- to represent the 'skipped' hour, followed by 44 values in chronological order,
						-- followed by two null or zero values.					
						 WHEN SDT.IS_DST_SPRING_AHEAD_DAY = 1 AND INSTR(SDT.NO_ROLLUP_YYYY_MM_DD, '02:00d') > 0
						 	THEN '0100'
						 ELSE CASE WHEN TO_CHAR(LOCAL_DATE,'HH24MI') = '0000' THEN '2400' ELSE TO_CHAR(LOCAL_DATE,'HH24MI') END
					END AS HOUR_STR,
					CASE WHEN p_MATRIX_TYPE_FILTER = 'Contract Volume' 
						 THEN NVL(CONTRACT_LEVEL, CONTRACT_LEVEL_2) * 0.5 * 1000 -- in kWh
						 ELSE NVL(CHARGE_AMOUNT, CHARGE_AMOUNT_2)
					END "AMOUNT"
			FROM SEM_CFD_DIFF_PMTS_TEMP,
				SYSTEM_DATE_TIME SDT
			WHERE SDT.CUT_DATE = CHARGE_DATE 
				AND SDT.TIME_ZONE = MM_SEM_UTIL.g_TZ
				AND SDT.DATA_INTERVAL_TYPE = 1
				AND SDT.DAY_TYPE = '1'
				AND SDT.CUT_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
				AND SDT.MINIMUM_INTERVAL_NUMBER >= v_MIN_INTERVAL_NUMBER)
		GROUP BY DAY_STR, CURRENCY
		ORDER BY 1,2;

END GET_DIFF_PAYMENTS_MATRIX_RPT;
-------------------------------------------------------------
END MM_SEM_CFD_DIFF_PMTS;
/
