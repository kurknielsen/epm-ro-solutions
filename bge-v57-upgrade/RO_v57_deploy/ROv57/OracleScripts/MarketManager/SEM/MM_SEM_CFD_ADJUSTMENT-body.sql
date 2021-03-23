CREATE OR REPLACE PACKAGE BODY MM_SEM_CFD_ADJUSTMENT
AS
/*============================================================================*
 *   PACKAGE BODY                                                             *
 *============================================================================*/
 
/*----------------------------------------------------------------------------*
 *   PRIVATE VARIABLES                                                        *
 *----------------------------------------------------------------------------*/
   c_LOW_DATE                       CONSTANT DATE           := LOW_DATE;
   c_TIME_ZONE                      CONSTANT CHAR(3)        := 'EDT';
   
/*============================================================================*
 *   PROCEDURES AND FUNCTIONS                                                 *
 *============================================================================*/
 
/*----------------------------------------------------------------------------*
 *   WHAT_VERSION                                                             *
 *----------------------------------------------------------------------------*/
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;

/*----------------------------------------------------------------------------*
 *   GET_ADJUSTMENT_TYPE_FILTER                                               *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_ADJUSTMENT_TYPE_FILTER(p_CURSOR OUT SYS_REFCURSOR) IS
BEGIN
   OPEN p_CURSOR FOR
      SELECT c_ADJ_TYPE_CC FROM DUAL 
      UNION ALL
      SELECT c_ADJ_TYPE_DIFF FROM DUAL;
END GET_ADJUSTMENT_TYPE_FILTER;

/*----------------------------------------------------------------------------*
 *   GET_ADJUSTMENT_STATUS_FILTER                                             *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_ADJUSTMENT_STATUS_FILTER(p_CURSOR OUT SYS_REFCURSOR) IS
BEGIN
   OPEN p_CURSOR FOR
      SELECT '<ALL>' FROM DUAL 
      UNION ALL
      SELECT c_ADJ_STATUS_PENDING FROM DUAL 
      UNION ALL
      SELECT c_ADJ_STATUS_ACCEPTED FROM DUAL 
      UNION ALL
      SELECT c_ADJ_STATUS_REJECTED FROM DUAL;
END GET_ADJUSTMENT_STATUS_FILTER;

/*----------------------------------------------------------------------------*
 *   GET_ADJUSTMENT_STATUSES                                                  *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_ADJUSTMENT_STATUSES(p_CURSOR OUT SYS_REFCURSOR) IS
BEGIN
   OPEN p_CURSOR FOR
      SELECT c_ADJ_STATUS_PENDING FROM DUAL 
      UNION ALL
      SELECT c_ADJ_STATUS_ACCEPTED FROM DUAL 
      UNION ALL
      SELECT c_ADJ_STATUS_REJECTED FROM DUAL;
END GET_ADJUSTMENT_STATUSES;

/*----------------------------------------------------------------------------*
 *   GET_TRANSACTION_ID_FILTER                                                *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_TRANSACTION_ID_FILTER(p_CURSOR OUT SYS_REFCURSOR) IS
BEGIN
   OPEN p_CURSOR FOR
      SELECT TRANSACTION_NAME AS ADJ_TRANSACTION_NAME, TRANSACTION_ID AS ADJ_TRANSACTION_ID
      FROM INTERCHANGE_TRANSACTION A, INTERCHANGE_CONTRACT C
      WHERE A.CONTRACT_ID = C.CONTRACT_ID
         AND C.CONTRACT_TYPE IN (MM_SEM_CFD_UTIL.k_CONTRACT_TYPE_DIRECTED, MM_SEM_CFD_UTIL.k_CONTRACT_TYPE_NON_DIRECTED)
      ORDER BY UPPER(A.TRANSACTION_NAME);
END GET_TRANSACTION_ID_FILTER;

/*----------------------------------------------------------------------------*
 *   GET_COUNTERPARTY_ID_FILTER                                               *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_COUNTERPARTY_ID_FILTER(p_CURSOR OUT SYS_REFCURSOR) IS
   v_STATUS NUMBER;
BEGIN
	MM_SEM_CFD_UI.GET_CP_FOR_TYPE_FILTER
	(
		MM_SEM_CFD_UTIL.k_ALL_TXT_FILTER,
		MM_SEM_CFD_UTIL.k_ALL_TXT_FILTER,
		NULL,
		v_STATUS,
		p_CURSOR
	);
END GET_COUNTERPARTY_ID_FILTER;
/*----------------------------------------------------------------------------*
 *   GET_CURRENCY_FOR_TRADE                                                       *
 *----------------------------------------------------------------------------*/
FUNCTION GET_CURRENCY_FOR_TRADE
(
	p_TRANSACTION_ID IN NUMBER
) RETURN VARCHAR2
IS
v_CURRENCY SEM_CFD_CONTRACT.CURRENCY%TYPE;
BEGIN

	SELECT SEMC.CURRENCY INTO v_CURRENCY
	FROM INTERCHANGE_TRANSACTION T,
		SEM_CFD_CONTRACT SEMC
	WHERE T.TRANSACTION_ID = p_TRANSACTION_ID
		AND T.CONTRACT_ID = SEMC.CONTRACT_ID;

	RETURN v_CURRENCY;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;

END;
/*----------------------------------------------------------------------------*
 *   GET_ADJUSTMENT_RPT                                                       *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_ADJUSTMENT_RPT
(
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_STATEMENT_TYPE IN NUMBER,
   p_ADJUSTMENT_TYPE_FILTER IN VARCHAR2, 
   p_TRANSACTION_ID_FILTER IN NUMBER, 
   p_REFERENCE_DATE_FILTER IN DATE, 
   p_ADJUSTMENT_STATUS_FILTER IN VARCHAR2, 
   p_ADJUSTMENT_CATEGORY_FILTER IN VARCHAR2,
   p_COUNTERPARTY_ID_FILTER IN NUMBER,
   p_RESTRICT_DATES_FILTER IN NUMBER,
   p_CURSOR OUT SYS_REFCURSOR
) IS
BEGIN

   OPEN p_CURSOR FOR 
      SELECT 
         ROWIDTOCHAR(A.ROWID) AS RECORD_ID,
         A.ADJUSTMENT_TYPE, 
         A.TRANSACTION_ID AS ADJ_TRANSACTION_ID, 
         --B.TRANSACTION_NAME,
         A.REFERENCE_DATE, 
         A.STATEMENT_TYPE_ID, 
         A.ADJUSTMENT_STATUS, 
         A.ADJUSTMENT_CATEGORY, 
         A.ADJUSTMENT_TEXT, 
         A.SUGGESTED_AMOUNT, 
         A.PAYMENT_SHORTFALL_AMOUNT, 
         A.APPLY_SHORTFALL_TO_CC, 
         A.APPLY_SUGGESTED_TO_INVOICE, 
         A.CREATE_DATE, 
         A.LAST_UPDATE_DATE, 
         A.LAST_UPDATED_BY
      FROM SEM_CFD_ADJUSTMENT A, INTERCHANGE_TRANSACTION B
      WHERE A.TRANSACTION_ID = B.TRANSACTION_ID
         AND A.STATEMENT_TYPE_ID = p_STATEMENT_TYPE
         AND A.ADJUSTMENT_TYPE = p_ADJUSTMENT_TYPE_FILTER
         AND (p_ADJUSTMENT_STATUS_FILTER = MM_SEM_CFD_UTIL.k_ALL_TXT_FILTER OR A.ADJUSTMENT_STATUS = p_ADJUSTMENT_STATUS_FILTER)
         AND (p_COUNTERPARTY_ID_FILTER = MM_SEM_CFD_UTIL.k_ALL_INT_FILTER OR B.PURCHASER_ID = p_COUNTERPARTY_ID_FILTER OR B.SELLER_ID = p_COUNTERPARTY_ID_FILTER)
         AND (p_RESTRICT_DATES_FILTER = 0 OR A.REFERENCE_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
      ORDER BY B.TRANSACTION_NAME, A.REFERENCE_DATE;
         
END GET_ADJUSTMENT_RPT;

/*----------------------------------------------------------------------------*
 *   PUT_CFD_ADJUSTMENT                                                       *
 *----------------------------------------------------------------------------*/
PROCEDURE PUT_CFD_ADJUSTMENT
(
   p_RECORD_ID IN VARCHAR2,
   p_ADJUSTMENT_TYPE IN VARCHAR2, 
   p_ADJUSTMENT_TYPE_FILTER IN VARCHAR2,
   p_ADJ_TRANSACTION_ID IN NUMBER, 
   p_REFERENCE_DATE IN DATE, 
   p_STATEMENT_TYPE IN NUMBER, 
   p_ADJUSTMENT_STATUS IN VARCHAR2, 
   p_ADJUSTMENT_CATEGORY IN VARCHAR2, 
   p_ADJUSTMENT_TEXT IN VARCHAR2, 
   p_SUGGESTED_AMOUNT IN NUMBER, 
   p_PAYMENT_SHORTFALL_AMOUNT IN NUMBER, 
   p_APPLY_SHORTFALL_TO_CC IN NUMBER, 
   p_APPLY_SUGGESTED_TO_INVOICE IN NUMBER,
   p_STATUS OUT NUMBER,
   p_MESSAGE OUT VARCHAR2
) IS

   -- LOCAL VARIABLES --
   v_OS_USER       VARCHAR2(128) := SECURITY_CONTROLS.CURRENT_USER;
   
BEGIN

   p_STATUS := GA.SUCCESS;
   IF p_RECORD_ID IS NULL THEN
      INSERT INTO SEM_CFD_ADJUSTMENT
      (
         ADJUSTMENT_TYPE, 
         TRANSACTION_ID, 
         REFERENCE_DATE, 
         STATEMENT_TYPE_ID, 
         ADJUSTMENT_STATUS, 
         ADJUSTMENT_CATEGORY, 
         ADJUSTMENT_TEXT, 
         SUGGESTED_AMOUNT, 
         PAYMENT_SHORTFALL_AMOUNT, 
         APPLY_SHORTFALL_TO_CC, 
         APPLY_SUGGESTED_TO_INVOICE, 
         CREATE_DATE, 
         LAST_UPDATE_DATE, 
         LAST_UPDATED_BY
      )
      VALUES
      (
         p_ADJUSTMENT_TYPE_FILTER, 
         p_ADJ_TRANSACTION_ID, 
         TRUNC(p_REFERENCE_DATE, 'MM'), 
         p_STATEMENT_TYPE, 
         p_ADJUSTMENT_STATUS, 
         p_ADJUSTMENT_CATEGORY, 
         p_ADJUSTMENT_TEXT, 
         p_SUGGESTED_AMOUNT, 
         p_PAYMENT_SHORTFALL_AMOUNT, 
         NVL(p_APPLY_SHORTFALL_TO_CC,0), 
         NVL(p_APPLY_SUGGESTED_TO_INVOICE,0), 
         SYSDATE, 
         SYSDATE, 
         v_OS_USER
      );
   ELSE
      UPDATE SEM_CFD_ADJUSTMENT SET
         ADJUSTMENT_TYPE = p_ADJUSTMENT_TYPE, 
         TRANSACTION_ID = p_ADJ_TRANSACTION_ID, 
         REFERENCE_DATE = TRUNC(p_REFERENCE_DATE, 'MM'), 
         STATEMENT_TYPE_ID = p_STATEMENT_TYPE, 
         ADJUSTMENT_STATUS = p_ADJUSTMENT_STATUS, 
         ADJUSTMENT_CATEGORY = p_ADJUSTMENT_CATEGORY, 
         ADJUSTMENT_TEXT = p_ADJUSTMENT_TEXT, 
         SUGGESTED_AMOUNT = p_SUGGESTED_AMOUNT, 
         PAYMENT_SHORTFALL_AMOUNT = p_PAYMENT_SHORTFALL_AMOUNT, 
         APPLY_SHORTFALL_TO_CC = p_APPLY_SHORTFALL_TO_CC, 
         APPLY_SUGGESTED_TO_INVOICE = p_APPLY_SUGGESTED_TO_INVOICE, 
         LAST_UPDATE_DATE = SYSDATE, 
         LAST_UPDATED_BY = v_OS_USER
      WHERE ROWID = CHARTOROWID(p_RECORD_ID);
   END IF;
         
END PUT_CFD_ADJUSTMENT;

/*----------------------------------------------------------------------------*
 *   PUT_CFD_ADJUSTMENT                                                       *
 *----------------------------------------------------------------------------*/
PROCEDURE PUT_ADJUSTMENT_TEXT
(
	p_ADJUSTMENT_TYPE IN VARCHAR2,
	p_TRANSACTION_ID IN NUMBER,
	p_REFERENCE_DATE IN DATE,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_ADJUSTMENT_TEXT IN VARCHAR2
) IS
	v_STATUS NUMBER;
	v_MESSAGE VARCHAR2(4000);
--Shortcut PUT procedure for storing just the dispute text that Credit Cover uses.
BEGIN
	
	--Update text if the record exists.
     UPDATE SEM_CFD_ADJUSTMENT SET
         ADJUSTMENT_TEXT = p_ADJUSTMENT_TEXT, 
         LAST_UPDATE_DATE = SYSDATE, 
         LAST_UPDATED_BY = SECURITY_CONTROLS.CURRENT_USER
      WHERE ADJUSTMENT_TYPE = p_ADJUSTMENT_TYPE
			AND TRANSACTION_ID = p_TRANSACTION_ID
			AND REFERENCE_DATE = p_REFERENCE_DATE
			AND STATEMENT_TYPE_ID = p_STATEMENT_TYPE_ID;
	
	--Insert a record if one did not exist.
	IF SQL%NOTFOUND THEN
		--This procedure never sets status or message... so we are ignoring them here.
		PUT_CFD_ADJUSTMENT(NULL, p_ADJUSTMENT_TYPE, p_ADJUSTMENT_TYPE, p_TRANSACTION_ID, p_REFERENCE_DATE, p_STATEMENT_TYPE_ID,
			c_ADJ_STATUS_PENDING, NULL, p_ADJUSTMENT_TEXT, 0, 0, 0, 0, v_STATUS, v_MESSAGE);
	END IF;

END PUT_ADJUSTMENT_TEXT;
/*----------------------------------------------------------------------------*
 *   DELETE_CFD_ADJUSTMENT                                                    *
 *----------------------------------------------------------------------------*/
PROCEDURE DELETE_CFD_ADJUSTMENT
(
   p_RECORD_ID IN VARCHAR2,
   p_STATUS OUT NUMBER,
   p_MESSAGE OUT VARCHAR2
) IS
BEGIN 
   p_STATUS := GA.SUCCESS;
   DELETE FROM SEM_CFD_ADJUSTMENT WHERE ROWID = CHARTOROWID(p_RECORD_ID);
END DELETE_CFD_ADJUSTMENT;

END MM_SEM_CFD_ADJUSTMENT; 
/
