CREATE OR REPLACE PACKAGE MM_OASIS_COMPARE IS
-- $Revision: 1.12 $

-- Load Balancing

TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE ETAG_TXN_OASIS_LISTING_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TRANSACTION_FILTER IN VARCHAR2,
	p_OASIS_FILTER IN VARCHAR2,
	p_ETAG_FILTER IN VARCHAR2,
	p_PURCHASER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE PUT_ETAG_TXN_OASIS_LISTING_RPT
	(
	p_ENERGY_TRANSACTION_ID IN NUMBER,
	p_ETAG_IDENT IN VARCHAR2,
	p_OLD_ETAG_ID IN VARCHAR2,
	p_STATUS OUT NUMBER
	);

PROCEDURE ENERGY_BALANCE_RPT_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_POR_ID IN NUMBER,
	p_POD_ID IN NUMBER,
	p_TRANSACTION_STATUS IN VARCHAR2,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE ENERGY_BALANCE_RPT_DETAIL
	(
	p_ENERGY_TRANSACTION_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_AS_OF_DATE IN DATE,
	p_TP_ID IN NUMBER,
	p_POR_ID IN NUMBER,
	p_TXN_POR_ID IN NUMBER,
	p_POD_ID IN NUMBER,
	p_TXN_POD_ID IN NUMBER,
	p_TXN_SOURCE_ID IN NUMBER,
	p_PURCHASER_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);

PROCEDURE CAPACITY_ASSIGN_RPT_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TP_ID IN NUMBER,
	p_POR_ID IN NUMBER,
	p_POD_ID IN NUMBER,
	p_SOURCE_ID IN NUMBER,
	p_PURCHASER_ID IN NUMBER,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE CAPACITY_ASSIGN_RPT_DETAIL
	(
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
    p_SCHEDULE_TYPE IN NUMBER,
    p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);

PROCEDURE PUT_BALANCE_REPORT_DETAIL
	(
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_ENERGY_TRANSACTION_ID IN NUMBER,
	p_SCHEDULE_TYPE IN NUMBER,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
    p_SCHEDULE_DATE IN VARCHAR,
    p_SCHEDULE_TIME IN VARCHAR,
    p_DISP_SCHEDULED IN NUMBER,
    p_ASSIGNED_AMOUNT IN NUMBER,
	p_IS_FIXED IN NUMBER,
	p_UPDATE_ENERGY IN NUMBER,
	p_ENERGY_AMOUNT IN NUMBER,
	p_STATUS OUT NUMBER
	);

g_STATUS_CONFIRMED VARCHAR2(32) := 'CONFIRMED';

g_OASIS_ASSIGNMENT_TYPE VARCHAR2(32) := 'OASISCompare';
g_ALL NUMBER(2) := -1;
g_ALL_CHAR VARCHAR2(8) := '<All>';
g_SAME_AS_TXN NUMBER(2) := -2;
g_ENERGY_TXN_COMMODITY_ID NUMBER(9) := 2;


END MM_OASIS_COMPARE;
/