CREATE OR REPLACE PACKAGE MM_SEM_CFD_UI IS

  -- Author  : AHUSSAIN
  -- Created : 10/10/2007 9:09:38 AM
  -- Purpose : CFD Management UI package
  -- $Revision: 1.6 $

	-- Public type declarations
	TYPE REF_CURSOR IS REF CURSOR;

	-- Public constant declarations

	-- Public variable declarations

	-- Public function and procedure declarations
	FUNCTION WHAT_VERSION RETURN VARCHAR;

	PROCEDURE GET_CONTRACTS
	(
		p_CONTRACT_TYPE IN VARCHAR,
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_COMPANY_NAMES
	(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_BUYERS
	(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_SELLERS
	(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_BILLING_ENTITIES
	(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_COMMODITIES
	(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	FUNCTION GET_CONTRACT_TYPE
	(
		p_CONTRACT_ID IN VARCHAR
	) RETURN VARCHAR2;

	PROCEDURE GET_FILL_TEMPLATES
	(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_CFD_MONTH
	(
		p_TXN_BEGIN_DATE IN DATE,
		p_TXN_END_DATE IN DATE,
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_ESTSEM_COEFF_QUARTERS
	(
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_PRODUCTS
	(
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT REF_CURSOR
	);

	PROCEDURE GET_DEAL_CAPTURE_INFO_RPT
	(
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_CONTRACT_TYPE IN VARCHAR2,
		p_TXN_TYPE_FROM_FILTER IN VARCHAR2,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT REF_CURSOR
	);

	PROCEDURE PUT_DEAL_CAPTURE_INFO_RPT
	(
		p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
		p_TXN_BEGIN_DATE IN DATE,
		p_TXN_END_DATE IN DATE,
		p_TXN_TYPE_FROM_FILTER IN VARCHAR2,
		p_TXN_TYPE_FROM_GRID IN VARCHAR2,
		p_CONTRACT_ID IN NUMBER,
		p_TRADE_NUMBER IN VARCHAR2,
		p_PRODUCT IN VARCHAR2,
		p_COMMODITY_ID IN NUMBER,
		p_DIFF_PMT_INDEX_MP_ID IN NUMBER,
		p_DIFF_PMT_SPARE_NUM_1 IN NUMBER,
		p_DIFF_PMT_SPARE_NUM_2 IN NUMBER,
		p_DIFF_PMT_SPARE_STR IN VARCHAR2,
		p_DIFF_PMT_VAT_TXN_ID IN NUMBER,
		p_CC_VAT_TXN_ID IN NUMBER,
		p_CC_PI_MP_ID IN NUMBER,
		p_CC_PERCENTAGE IN NUMBER,
		p_CC_INDEX_MP_ID IN NUMBER,
		p_M2M_INDEX_MP_ID IN NUMBER,
		p_NETTING_AGREEMENT_PERCENTAGE IN NUMBER,
		p_EXECUTION_DATE IN DATE,
		p_TRADER IN VARCHAR2,
		p_ADDITIONAL_AUTHORISER IN VARCHAR2,
		p_STATUS OUT NUMBER,
		p_MESSAGE OUT VARCHAR2
	);

	PROCEDURE DELETE_DEAL_CAPTURE_INFO_RPT
	(
		p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
		p_STATUS OUT NUMBER
	);

	PROCEDURE GET_CFD_TERMS_RPT
	(
		p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
		p_IS_MONTHLY_SHAPED IN INTERCHANGE_TRANSACTION.IS_FIRM%TYPE,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT REF_CURSOR
	);

	PROCEDURE PUT_CFD_TERMS_RPT
	(
		p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
		p_MONTH_ID IN NUMBER,
		p_FILL_TEMPLATE IN SEM_TRANSACTION_CFD_TERMS.FILL_TEMPLATE%TYPE,
		p_TEMPLATE_ORDER IN SEM_TRANSACTION_CFD_TERMS.TEMPLATE_ORDER%TYPE,
		p_CONTRACT_QUANTITY IN SEM_TRANSACTION_CFD_TERMS.CONTRACT_QUANTITY%TYPE,
		p_STRIKE_PRICE IN SEM_TRANSACTION_CFD_TERMS.STRIKE_PRICE%TYPE,
		p_OLD_FILL_TEMPLATE IN SEM_TRANSACTION_CFD_TERMS.FILL_TEMPLATE%TYPE,
		p_STATUS OUT NUMBER,
		p_MESSAGE OUT VARCHAR2
	);

	PROCEDURE DELETE_CFD_TERMS
	(
		p_TXN_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
		p_MONTH_ID IN NUMBER,
		p_FILL_TEMPLATE IN SEM_TRANSACTION_CFD_TERMS.FILL_TEMPLATE%TYPE,
		p_TEMPLATE_ORDER IN SEM_TRANSACTION_CFD_TERMS.TEMPLATE_ORDER%TYPE,
		p_STATUS OUT NUMBER
	);

	PROCEDURE APPLY_CFD_TERMS
	(
		p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
		p_STATUS OUT NUMBER
	);

	PROCEDURE GET_CFD_CONTRACTS_RPT
	(
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_RESTRICT_DATES_FILTER IN NUMBER,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT REF_CURSOR
	);

	PROCEDURE PUT_CFD_CONTRACT_RPT
	(
		p_CONTRACT_ID IN INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE,
		p_CONTRACT_NAME IN INTERCHANGE_CONTRACT.CONTRACT_NAME%TYPE,
		p_CONTRACT_NUMBER IN INTERCHANGE_CONTRACT.CONTRACT_ALIAS%TYPE,
		p_BUYER_ID IN INTERCHANGE_CONTRACT.PURCHASER_ID%TYPE,
		p_SELLER_ID IN INTERCHANGE_CONTRACT.SELLER_ID%TYPE,
		p_BILLING_ENTITY_ID IN INTERCHANGE_CONTRACT.BILLING_ENTITY_ID%TYPE,
		p_CONTRACT_TYPE IN INTERCHANGE_CONTRACT.CONTRACT_TYPE%TYPE,
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_AGREEMENT_TYPE IN INTERCHANGE_CONTRACT.AGREEMENT_TYPE%TYPE,
		p_CURRENCY IN VARCHAR2,
		p_JURISDICTION IN VARCHAR2,
		p_EXECUTION_DATE IN DATE,
		p_HEDGE_TYPE IN VARCHAR2,
		p_WD_TO_INVOICE IN NUMBER,
		p_WD_TO_PAY IN NUMBER,
		p_RECEIVABLES_CUTOFF_OPTION IN VARCHAR2,
		p_WD_TO_RECEIVABLES_CUTOFF IN NUMBER,
		p_CREDIT_COVER_REGIME IN VARCHAR2,
		p_MESSAGE OUT VARCHAR2
	);

	PROCEDURE DELETE_CFD_CONTRACT
	(
		p_CONTRACT_ID IN INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE,
		p_STATUS OUT NUMBER
	);

	PROCEDURE GET_ESTSMP_COEFFICIENT_RPT
	(
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT REF_CURSOR
	);

	PROCEDURE PUT_ESTSMP_COEFFICIENT_RPT
	(
		p_PRODUCT IN VARCHAR2,
		p_QUARTER_ID IN NUMBER,
		p_ALPHA IN NUMBER,
		p_BETA IN NUMBER,
		p_GAMMA IN NUMBER,
		p_DELTA IN NUMBER,
		p_EPSILON	IN NUMBER,
		p_ZETA IN NUMBER,
		p_ETA IN NUMBER,
		p_PI IN NUMBER,
		p_OLD_PRODUCT IN VARCHAR2,
		p_OLD_QUARTER_ID IN NUMBER,
		p_STATUS OUT NUMBER
	);

	PROCEDURE DELETE_ESTSMP_COEFFICIENT
	(
		p_PRODUCT IN VARCHAR2,
		p_QUARTER_ID IN NUMBER,
		p_STATUS OUT NUMBER
	);

	PROCEDURE GET_INDEX_PRICE_LIST
	(
		p_INTERVAL IN VARCHAR2,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);

	PROCEDURE GET_INDEX_PRICE_LIST_W_ESTSEM
	(
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);

	PROCEDURE GET_VAT_TXN_LIST
	(
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);

	PROCEDURE GET_AGREEMENT_FOR_TYPE_FILTER
	(
	   p_CONTRACT_TYPE_FILTER IN VARCHAR2,
	   p_CURSOR OUT SYS_REFCURSOR
	);

	PROCEDURE GET_CP_FOR_TYPE_FILTER
	(
		p_CONTRACT_TYPE_FILTER IN VARCHAR2,
		p_AGREEMENT_TYPE_FILTER IN VARCHAR2,
		p_REPORT_NAME IN VARCHAR2,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);

	PROCEDURE GET_CONTRACTS_FILTER
	(
		p_CONTRACT_TYPE_FILTER IN VARCHAR2,
		p_AGREEMENT_TYPE_FILTER IN VARCHAR2,
		p_COUNTERPARTY_ID_FILTER IN NUMBER,
		p_REPORT_NAME IN VARCHAR2,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);
END MM_SEM_CFD_UI;
/