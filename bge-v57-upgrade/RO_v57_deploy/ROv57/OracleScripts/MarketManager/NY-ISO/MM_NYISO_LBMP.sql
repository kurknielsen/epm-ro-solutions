CREATE OR REPLACE PACKAGE MM_NYISO_LBMP IS
-- $Revision: 1.13 $

  -- Author  : VGODYN
  -- Created : 9/8/2005 4:04:29 PM
  -- Purpose : Interface for NYISO LMP IMPORT using MEX_NYISO

FUNCTION WHAT_VERSION RETURN VARCHAR2;

	PROCEDURE MARKET_EXCHANGE
	(
		p_BEGIN_DATE    IN DATE,
		p_END_DATE      IN DATE,
		p_EXCHANGE_TYPE IN VARCHAR2,
		p_ENTITY_LIST 	IN VARCHAR2,
		p_LOG_TYPE      IN NUMBER,
		p_TRACE_ON      IN NUMBER,
		p_STATUS        OUT NUMBER,
		p_MESSAGE       OUT VARCHAR2
	);

	PROCEDURE GET_ENTITY_LIST_FOR_LBMP
	(
		p_CURSOR OUT SYS_REFCURSOR
	);

	 --	Market_exchange constant
	g_ET_QUERY_DAY_AHEAD_LMP VARCHAR2(20) := 'Query DA LBMP';
	g_ET_QUERY_REAL_TIME_LMP VARCHAR2(20) := 'Query RT LBMP';
	g_ET_QUERY_REAL_TIME_INT_LMP VARCHAR2(20) := 'Query RTI LBMP';
	g_ET_QUERY_PRICE_NODES VARCHAR(18):= 'Query Price Nodes';
	g_ET_QUERY_ARCHIEVE_LBMP VARCHAR(32):= 'Query Archive LBMP';


END MM_NYISO_LBMP;
/