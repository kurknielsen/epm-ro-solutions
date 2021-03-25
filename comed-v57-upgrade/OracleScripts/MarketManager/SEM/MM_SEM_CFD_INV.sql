CREATE OR REPLACE PACKAGE MM_SEM_CFD_INV IS

	-- Author  : AHUSSAIN
	-- Purpose : CfD Invoice
	-- Revision: $Revision: 1.3 $
	------------------------------------------------------------------------------
	FUNCTION WHAT_VERSION RETURN VARCHAR;
	------------------------------------------------------------------------------
	PROCEDURE GET_COUNTER_PARTY_FILTER
	(
		p_ENTITY_ID NUMBER,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);
	------------------------------------------------------------------------------
	PROCEDURE GET_CONTRACTS_FILTER
	(
	   p_COUNTERPARTY_ID_FILTER IN NUMBER,
	   p_STATUS OUT NUMBER,
	   p_CURSOR OUT SYS_REFCURSOR
	);
	------------------------------------------------------------------------------
	FUNCTION IS_BUSINESS_DAY
	(
		p_DATE IN DATE
	) RETURN NUMBER;
	-------------------------------------------------------------
	PROCEDURE GENERATE_MONTHLY_INVOICE
	(
		p_MONTH_ID IN NUMBER,
		p_CONTRACT_ID IN NUMBER,
		p_STATEMENT_TYPE IN NUMBER,
		p_STATUS OUT NUMBER,
		p_MESSAGE OUT VARCHAR2
	);
	---------------------------------------------------------------------------------------------------
	PROCEDURE GET_CFD_INVOICE
	(
		p_MONTH_ID IN NUMBER,
		p_STATEMENT_TYPE IN NUMBER,
		p_CONTRACT_ID IN NUMBER,
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT SYS_REFCURSOR
	);
	--------------------------------------------------------------------------------
	PROCEDURE UPDATE_CFD_INVOICE
	(
		p_SEM_CFD_INVOICE_ID IN NUMBER,
		p_INVOICE_NUMBER IN VARCHAR2,
		p_PAYMENT_DUE_DATE IN DATE,
		p_STATUS OUT NUMBER
	);
	--------------------------------------------------------------------------------
	PROCEDURE GET_MONTHLY_INVOICE_RPT
	(
		p_MONTH_ID IN NUMBER,
		p_CONTRACT_ID IN NUMBER,
		p_STATEMENT_TYPE IN NUMBER,
		p_REPORT_NAME IN VARCHAR2,
		p_SHOW_AS_CREDIT_NOTE IN NUMBER,
		p_CURSOR IN OUT SYS_REFCURSOR
	);
	------------------------------------------------------------------------------
	PROCEDURE GET_INVOICE_MONTH
	(
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_STATUS OUT NUMBER,
		p_CURSOR IN OUT SYS_REFCURSOR
	);
	------------------------------------------------------------------------------
	PROCEDURE GEN_INV_WARNING_MESSAGE
	(
		p_MONTH_ID IN NUMBER,
		p_CONTRACT_ID IN NUMBER,
		p_STATEMENT_TYPE IN NUMBER,
		p_WARNING_MESSAGE OUT VARCHAR2
	);
	------------------------------------------------------------------------------
	PROCEDURE GET_DISPUTE_DETAILS
	(
		p_TRANSACTION_ID NUMBER,
		p_MONTH DATE,
		p_STATEMENT_TYPE_ID SEM_CFD_ADJUSTMENT.STATEMENT_TYPE_ID%TYPE,
		p_IS_IN_DISPUTE IN OUT NUMBER,
		p_PAYMENT_SHORTFALL_AMOUNT IN OUT NUMBER,
		p_VAT_RATE IN OUT NUMBER
	);
END MM_SEM_CFD_INV;
/