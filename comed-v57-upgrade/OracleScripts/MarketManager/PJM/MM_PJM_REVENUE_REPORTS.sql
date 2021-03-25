CREATE OR REPLACE PACKAGE MM_PJM_REVENUE_REPORTS IS

	-- Author  : LDUMITRIU
	-- Created : 09/11/2006 16:38:15

-- $Revision: 1.10 $

TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

FUNCTION GET_FTR_MARKET_PRICE_TYPE
	(
	p_POINT_OR_ZONE IN VARCHAR2
	) RETURN VARCHAR2;

PROCEDURE GET_TRADE_BY_CONTRACT_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_PSE_ID IN NUMBER,
	p_CONTRACT_CID IN VARCHAR2,
	p_SOURCE_CURVE_NAME IN VARCHAR2,
	p_BY_ZONE IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_GEN_REV_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_ROLLUP_TO IN VARCHAR2 := 'Month',
	p_INCLUDE_SUPPLY IN NUMBER,
	p_INCLUDE_MONPOWER IN NUMBER,
	p_RESOURCE_NAME IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_FTR_BY_PATH_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_INCLUDE_SUPPLY IN NUMBER,
	p_INCLUDE_MONPOWER IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_FTR_BY_PATH_DETAIL_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_ROLLUP_TO IN VARCHAR2 := 'Day',
	p_INCLUDE_SUPPLY IN NUMBER,
	p_INCLUDE_MONPOWER IN NUMBER,
	p_SOURCE_NAME IN VARCHAR2,
	p_SINK_NAME IN VARCHAR2,
	p_PARTICIPANT IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_FTR_BY_ACCT_DAY_RPT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
    p_STATEMENT_TYPE IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_FTR_BY_ACCT_HOUR_RPT
	(
	p_TIME_ZONE IN VARCHAR2,
	p_CURR_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_ALLOWED_PJM_ACCTS(p_STATUS OUT NUMBER, p_CURSOR IN OUT REF_CURSOR);

END MM_PJM_REVENUE_REPORTS;
/