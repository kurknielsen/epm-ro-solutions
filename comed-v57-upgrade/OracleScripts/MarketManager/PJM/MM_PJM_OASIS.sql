CREATE OR REPLACE PACKAGE MM_PJM_OASIS IS
	-- $Revision: 1.9 $
  -- Author  : AHUSSAIN
  -- Created : 9/21/2006 4:22:10 PM
  -- Purpose :
	TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

PROCEDURE LOAD_FORECAST_REPORT
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_LAST_UPDATE_DATE OUT DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_LAST_UPDATE_DATE(p_LAST_UPDATE_DATE OUT DATE);

  g_ET_QUERY_LOAD_FORECAST VARCHAR2(20) := 'Query Load Forecast';
  g_ET_QUERY_OP_RESV_RATES VARCHAR2(20) := 'Query OP Resv Rates';

END MM_PJM_OASIS;
/