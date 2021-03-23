CREATE OR REPLACE PACKAGE CDI_STORE_PLC_DETAIL
AS

/*============================================================================*
 * DESCRIPTION *
 *============================================================================*
 * *
 * This package contains a set of procedures that perform a polr processing*
 * for all Bill Account/ Service Point and Premise into RetailOffice
 * *
 *----------------------------------------------------------------------------*/

/*============================================================================*
 * MAINTENANCE HISTORY *
 *============================================================================*
 * DATE | AUTHOR | DESCRIPTION *
 *============================================================================*
 * 2/05/2007 | JAM | INITIAL RELEASE *
 *----------------------------------------------------------------------------*
 * 3/27/2007 | JAM | SECOND RELEASE *
 *----------------------------------------------------------------------------*
 * *
 *----------------------------------------------------------------------------*
 * *
 *----------------------------------------------------------------------------*
 * *
 *----------------------------------------------------------------------------*
 * *
 *============================================================================*/
 /* This package will be call during the Polar ICAP run for either the detail run
 which is a standalone process that only loads ICAP values into the CDI_PLC_LOAD table
 or the production run which can be done for a date range in the future and calls the
 INC/DEC process
/*----------------------------------------------------------------------------*
 * CONSTANTS *
 *----------------------------------------------------------------------------*/

 -- GENERIC --
 c_LOW_DATE CONSTANT DATE := TO_DATE('01/01/1900','MM/DD/YYYY');
 c_HIGH_DATE CONSTANT DATE := TO_DATE('12/30/9999','MM/DD/YYYY');

 -- ICAP VALUES
 c_ICAP_VALUE CONSTANT VARCHAR2(16) := 'ICAP';
 c_NET_VALUE CONSTANT VARCHAR2(16) := 'Network Service';

 c_CRLF CONSTANT VARCHAR2(2) := CHR(13)||CHR(10);

 -- CDI FLAGS --
 c_CDI_IS_AGGREGATE CONSTANT CHAR(1) := 'Y';

 c_VERY_SMALL_NUMBER CONSTANT NUMBER := 0.00000001;
 c_DEFAULT_TIME_ZONE CONSTANT VARCHAR2(16) := 'EDT';
 c_COMMA CONSTANT CHAR(1) := ',';

 -- SAFETY THRESHOLDS --
 c_MIN_I_ACCOUNTS CONSTANT NUMBER := 1; -- MINIMUM NUMBER OF HOURLIES --
 c_MIN_A_ACCOUNTS CONSTANT NUMBER := 0; -- MIN OF RC/STRATA COMB --

/*----------------------------------------------------------------------------*
 * TYPE DECLARATIONS *
 *----------------------------------------------------------------------------*/

 TYPE REF_CURSOR IS REF CURSOR;

/*----------------------------------------------------------------------------*
 * EXCEPTIONS *
 *----------------------------------------------------------------------------*/

 e_SOME_RO_EXCEPTION EXCEPTION;
 e_TOO_FEW_RECORDS EXCEPTION;

/*----------------------------------------------------------------------------*
 * PUBLIC PROCEDURES *
 *----------------------------------------------------------------------------*/

 PROCEDURE MAIN
 (
 p_BEGIN_DATE IN DATE,
 p_END_DATE IN DATE,
 p_VALUE IN NUMBER,
 p_STATUS OUT NUMBER
 );

 PROCEDURE GET_INIT_BID_BLOCK_SIZE
(
 p_BEGIN_DATE IN DATE,
 p_END_DATE IN DATE
);
 PROCEDURE GET_INIT_BID_BLOCK_SIZE_NEW
(
 p_BEGIN_DATE IN DATE,
 p_END_DATE IN DATE
);

 PROCEDURE GET_INIT_BID_BLOCK_SIZE_PRX
(
 p_BEGIN_DATE IN DATE,
 p_END_DATE IN DATE
);

g_BGE CONSTANT VARCHAR2(16) := 'BGE';
END CDI_STORE_PLC_DETAIL;
/

