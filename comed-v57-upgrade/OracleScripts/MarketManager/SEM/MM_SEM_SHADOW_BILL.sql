CREATE OR REPLACE PACKAGE "MM_SEM_SHADOW_BILL" IS
--Revision: $Revision: 1.29 $
  -- Author  : CNAVALTA
  -- Created : 8/29/2007 8:38:06 AM
  -- Purpose : contains functions used in shadow settlement

FUNCTION WHAT_VERSION RETURN VARCHAR;

c_INSTR_INTER_IGNORE CONSTANT VARCHAR2(6) := 'IGNORE';
c_INSTR_INTER_ZERO CONSTANT VARCHAR2(4) := 'ZERO';
c_INSTR_INTER_NON_ZERO CONSTANT VARCHAR2(8) := 'NON-ZERO';
c_DAILY_AVG CONSTANT VARCHAR2(2) := 'DA';

FUNCTION GET_MONTHLY_AVG_MAX_IMPORT_CAP
(
	p_PSE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE
) RETURN NUMBER;

FUNCTION GET_TLAF
    (
    p_DATE IN DATE,
    p_SERVICE_POINT IN VARCHAR2,
    p_BILLING_ENTITY IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_CURRENCY
    (
    p_PSE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE,
	p_IS_PARTICIPANT_PSE IN NUMBER DEFAULT 0
    ) RETURN NUMBER;

FUNCTION GET_FIXED_MO_CHARGE
    (
   p_DATE IN DATE,
    p_BILL_ENTITY IN NUMBER,
    p_COMPONENT_ID IN NUMBER,
    p_SERVICE_POINT IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_INTERCONNECT IN NUMBER
    ) RETURN NUMBER;

FUNCTION GET_CAP_PAY_PRICE_FACT
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_EA IN NUMBER,
    p_MSQ IN NUMBER,
    p_SMP IN NUMBER,
    p_VOLL IN NUMBER,
    p_CPPF IN NUMBER,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_CAP_PAY_PRICE_FACT_IU
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_EA IN NUMBER,
    p_MSQ IN NUMBER,
    p_SMP IN NUMBER,
    p_VOLL IN NUMBER,
    p_CPPF IN NUMBER,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_DISPATCH_OFFER_PRICE
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_DQ IN NUMBER,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_DISPATCH_OFFER_PRICE_IU
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_DQ IN NUMBER,
    p_TXN_TYPE IN VARCHAR2,
	p_AGREEMENT_TYPE IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

FUNCTION GET_NO_LOAD_COST
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_MAX_WARM_TIME
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_MAX_HOT_TIME
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_START_UP_COST
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2,
    p_WARMTH_STATE IN BINARY_INTEGER
    ) RETURN NUMBER;

FUNCTION GET_HOURS_DOWN
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2,
    p_MAX_TIME_WARM IN NUMBER,
    p_SCHED_TYPE IN NUMBER,
    p_COMMODITY IN VARCHAR2,
	p_BILLING_ENTITY IN NUMBER := NULL,
	p_STATEMENT_DATE IN DATE := NULL
    ) RETURN NUMBER;

FUNCTION GET_COST_CORRECTION
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2,
    p_QTY IN NUMBER,
	p_IS_INTERCONNECTOR IN NUMBER := 0,
	p_AGREEMENT_TYPE 	IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

FUNCTION GET_COST_CORRECTION_IU
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2,
    p_QTY IN NUMBER,
	p_AGREEMENT_TYPE IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

FUNCTION GET_REGISTERED_CAPACITY
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_AVGFRQ
    (
    p_DATE IN DATE
    ) RETURN NUMBER;

FUNCTION GET_NORFRQ
    (
    p_DATE IN DATE
    ) RETURN NUMBER;

FUNCTION GET_TAX_RATE
    (
	p_STATEMENT_DATE IN DATE,
    p_PSE_ID IN NUMBER,
	p_IS_PARTICIPANT_PSE IN NUMBER DEFAULT 0
    ) RETURN NUMBER;

FUNCTION GET_TESTING_TARIFF
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_COMPONENT_ID IN NUMBER
    ) RETURN NUMBER;

FUNCTION GET_SUM_OF_CHARGES
    (
    p_DATE IN DATE,
    p_COMPONENT_CAT IN VARCHAR2,
    p_BILLING_ENTITY IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER;

FUNCTION GET_IS_UNIT_UNDER_TEST
    (
    p_DATE IN DATE,
    p_SERV_POINT IN VARCHAR2,
    p_TXN_TYPE IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_RATE_PRIOR_DAY
    (
    p_DATE IN DATE,
    p_EXT_ID IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_IS_SUPPLIER_UNIT
    (
    p_DATE IN DATE,
    p_SERVICE_POINT IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION CALC_TOTAL_MWPEX(p_DATE IN DATE,
						  p_PSE_ID IN PSE.PSE_ID%TYPE,
						  p_PRODUCT_ID IN PRODUCT.PRODUCT_ID%TYPE,
						  p_COMPONENT_ID IN COMPONENT.COMPONENT_ID%TYPE,
						  p_STATEMENT_TYPE IN STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE,
						  p_SERVICE_POINT_NAME IN VARCHAR2,
						  p_MWPEX_UH_CURR IN NUMBER) RETURN NUMBER;

FUNCTION GET_FMOC_PUBLICATION_DATE
    (
    p_STATEMENT_TYPE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE
    ) RETURN DATE;

FUNCTION GET_ENERGY_STATEMENT_TYPE
    (
	p_MARKET IN VARCHAR2,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE
    ) RETURN NUMBER;

FUNCTION GET_NDLF
    (
	p_MARKET IN VARCHAR2,
	p_SERVICE_POINT IN VARCHAR2,
	p_STATEMENT_TYPE_ID IN NUMBER,
    p_SCHEDULE_DATE IN DATE,
	p_STATEMENT_DATE IN DATE
    ) RETURN NUMBER;

PROCEDURE GET_CROSS_BORDER_DATA
    (
    p_STATEMENT_TYPE IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_BILLING_ENTITY_ID IN NUMBER,
    p_CHARGE_TYPE IN VARCHAR2 := NULL,
    p_PROPORTION_TAXED OUT NUMBER,
    p_TAX_RATE OUT NUMBER
    );

FUNCTION GET_INSTRUCTION_INTER
    (
    p_PART_PSE_ID IN NUMBER,
    p_GEN_UNIT_ID IN NUMBER,
    p_INSTRUCTION_TIMESTAMP IN DATE,
    p_INSTRUCTION_CODE IN VARCHAR2,
    p_COMBINATION_CODE IN VARCHAR2,
    p_DISPATCH_VALUE IN NUMBER
    ) RETURN VARCHAR2;

FUNCTION GET_EXCHANGE_RATE(
  p_BILL_ENTITY_ID  IN NUMBER,
  p_DATE            IN DATE,
  p_MARKET_PRICE_ID IN NUMBER
  ) RETURN NUMBER;

FUNCTION GET_MSQ
    (
	p_IS_INTERCONNECT IN NUMBER,
	p_SERVICE_POINT IN VARCHAR2,
	p_STATEMENT_TYPE_ID IN NUMBER,
    p_SCHEDULE_DATE IN DATE,
	p_STATEMENT_DATE IN DATE,
	p_AGREEMENT_TYPE IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

FUNCTION GET_PIR_VALUE
    (
	p_VARIABLE_TYPE IN VARCHAR2,
	p_BILLING_ENTITY_ID IN NUMBER,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_VARIABLE_NAME IN VARCHAR2 := NULL,
	p_SERVICE_POINT IN VARCHAR2 := NULL
    ) RETURN NUMBER;

FUNCTION GET_RMVIP
    (
	p_SERVICE_POINT IN VARCHAR2,
	p_STATEMENT_DATE IN DATE
    ) RETURN NUMBER;

FUNCTION GET_NDA
    (
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_SERVICE_POINT IN VARCHAR2
    ) RETURN NUMBER;

FUNCTION GET_JURISDICTION(p_BILLING_ENTITY_ID IN NUMBER, p_STATEMENT_DATE IN DATE) RETURN VARCHAR2;

FUNCTION GET_GATE_WINDOW
    (
    p_CUT_DATE IN DATE
    ) RETURN IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;

-- PRIVATE METHODS EXPOSED FOR UNIT TESTING
$if $$UNIT_TEST_MODE = 1 $then

PROCEDURE GET_SETTLEMENT_PSE_INFORMATION
    (
    p_PSE_ID IN NUMBER,
    p_IS_MARKET_OPERATOR OUT BOOLEAN,
    p_MARKET_NAME OUT VARCHAR2,
    p_PARTICIPANT_PSE_ID OUT NUMBER
    );

FUNCTION GET_TAX_ATTRIBUTE
    (
    p_JURISDICTION IN VARCHAR2,
    p_IS_MARKET_OPERATOR IN BOOLEAN,
    p_PART_PSE_UNIT_TYPE IN VARCHAR2,
    p_USE_CROSS_BORDER IN BOOLEAN
    ) RETURN VARCHAR2;

FUNCTION GET_GP_VAR_TYPE
    (
    p_MARKET_NAME IN VARCHAR2,
    p_PSE_UNIT_TYPE IN VARCHAR2,
    p_CHARGE_TYPE IN VARCHAR2 := NULL
    ) RETURN VARCHAR2;

FUNCTION GET_BEST_AVAIL_TXN_ID
(
	p_REF_GATE_WINDOW     IN  EXTERNAL_SYSTEM_IDENTIFIER.EXTERNAL_IDENTIFIER%TYPE,
	p_TXN_TYPE            IN  VARCHAR2,
	p_SERV_POINT          IN  VARCHAR2,
	p_DATE                IN  DATE
) RETURN NUMBER;
$end

END MM_SEM_SHADOW_BILL;
/