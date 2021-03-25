CREATE OR REPLACE PACKAGE MM_ERCOT_EXTRACT IS
-- $Revision: 1.11 $

  -- Author  : CNAVALTA
  -- Created : 5/3/2006 10:40:19 AM
  -- Purpose : import Load Extract data

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

g_ET_IMPORT_LOAD_EXTRACT  VARCHAR2(20) :=	'Import Load Extract';
g_ET_IMPORT_ESIID_EXTRACT VARCHAR2(20):= 'Import ESIID Extract';
--Custom Attribute asscociated with the contract
g_CONTRACT_LSE_CODE_EA VARCHAR2(20) := 'ERCOT LSE Code';

END MM_ERCOT_EXTRACT; 
/