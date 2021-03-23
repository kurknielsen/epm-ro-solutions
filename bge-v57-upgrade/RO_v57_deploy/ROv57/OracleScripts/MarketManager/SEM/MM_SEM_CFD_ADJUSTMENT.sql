CREATE OR REPLACE PACKAGE MM_SEM_CFD_ADJUSTMENT
AS
-- $Revision: 1.3 $

/*============================================================================*
 *                                DESCRIPTION                                 *
 *============================================================================*
 *                                                                            *
 * This package contains reports and calculations for CfD Disputes            *
 * in SEM Irish market.                                                       *
 *                                                                            *
 *----------------------------------------------------------------------------*/

/*============================================================================*
 *                            MAINTENANCE HISTORY                             *
 *============================================================================*
 *    DATE    | AUTHOR |                    DESCRIPTION                       *
 *============================================================================*
 * 04/11/2008 | AB     | INITIAL RELEASE                                      *
 *----------------------------------------------------------------------------*
 * 04/18/2008 | AH     |  Reference Date truncated to monthly value           *
 *----------------------------------------------------------------------------*
 * 04/23/2008 | AH     |  Added GET_CURRENCY_FOR_TRADE function               *
 *============================================================================*/

/*----------------------------------------------------------------------------*
 *   TYPE DECLARATIONS                                                        *
 *----------------------------------------------------------------------------*/
 
/*----------------------------------------------------------------------------*
 *   CONSTANTS                                                                *
 *----------------------------------------------------------------------------*/

   c_ADJ_TYPE_CC                    CONSTANT VARCHAR2(16) := 'Credit Cover';
   c_ADJ_TYPE_DIFF                  CONSTANT VARCHAR2(16) := 'Diff Payment';
   
   c_ADJ_STATUS_PENDING             CONSTANT VARCHAR2(16) := 'Pending';   
   c_ADJ_STATUS_ACCEPTED            CONSTANT VARCHAR2(16) := 'Accepted';
   c_ADJ_STATUS_REJECTED            CONSTANT VARCHAR2(16) := 'Rejected';

/*----------------------------------------------------------------------------*
 *   EXCEPTIONS                                                               *
 *----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*
 *   PUBLIC PROCEDURES                                                        *
 *----------------------------------------------------------------------------*/

FUNCTION WHAT_VERSION RETURN VARCHAR2;

FUNCTION GET_CURRENCY_FOR_TRADE
(
	p_TRANSACTION_ID IN NUMBER
) RETURN VARCHAR2;

PROCEDURE GET_ADJUSTMENT_TYPE_FILTER(p_CURSOR OUT SYS_REFCURSOR);

PROCEDURE GET_ADJUSTMENT_STATUS_FILTER(p_CURSOR OUT SYS_REFCURSOR);

PROCEDURE GET_ADJUSTMENT_STATUSES(p_CURSOR OUT SYS_REFCURSOR);

PROCEDURE GET_COUNTERPARTY_ID_FILTER(p_CURSOR OUT SYS_REFCURSOR);

PROCEDURE GET_TRANSACTION_ID_FILTER(p_CURSOR OUT SYS_REFCURSOR);

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
);
                    

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
);
                
PROCEDURE PUT_ADJUSTMENT_TEXT
(
	p_ADJUSTMENT_TYPE IN VARCHAR2,
	p_TRANSACTION_ID IN NUMBER,
	p_REFERENCE_DATE IN DATE,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_ADJUSTMENT_TEXT IN VARCHAR2
);

PROCEDURE DELETE_CFD_ADJUSTMENT
(
   p_RECORD_ID IN VARCHAR2,
   p_STATUS OUT NUMBER,
   p_MESSAGE OUT VARCHAR2
);
   
END MM_SEM_CFD_ADJUSTMENT; 
/