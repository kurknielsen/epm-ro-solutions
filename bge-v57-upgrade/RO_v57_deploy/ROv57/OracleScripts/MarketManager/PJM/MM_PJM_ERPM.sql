CREATE OR REPLACE PACKAGE MM_PJM_ERPM IS

  -- Author  : CNAVALTA
  -- Created : 6/6/2007 2:09:29 PM
  -- Purpose : Handle eRM interactions with MarketManager
-- $Revision: 1.6 $
FUNCTION WHAT_VERSION RETURN VARCHAR;

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

g_ET_QUERY_NSPL 		  VARCHAR2(20):= 'Query NSPL';
g_ET_QUERY_CAPACITY_OBLIG VARCHAR2(40) := 'Query Capacity Obligation';

END MM_PJM_ERPM;
/