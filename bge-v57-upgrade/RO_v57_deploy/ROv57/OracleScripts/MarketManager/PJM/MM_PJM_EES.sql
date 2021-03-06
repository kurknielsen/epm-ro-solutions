CREATE OR REPLACE PACKAGE MM_PJM_EES IS
-- $Revision: 1.13 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE SUBMIT_RAMP_RESERVATION
	(
	p_CRED		   IN mex_credentials,
	pTransactionID IN NUMBER,
	pStartDate     IN DATE,
	pEndDate       IN DATE,
	p_LOG_ONLY	   IN NUMBER,
	p_STATUS       OUT NUMBER,
	p_MESSAGE      OUT VARCHAR2,
	p_LOGGER	   IN OUT mm_logger_adapter
	);


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

g_FAILURE CONSTANT NUMBER(1) := 3;

  g_ET_QUERY_TWO_SETTLEMENT 	 VARCHAR2(20) := 'Query Two Settlement';
  g_ET_QUERY_TWO_SETTL_TO_INTERN VARCHAR2(50) := 'Query Two Settlement To Internal';
  g_ET_QUERY_RESERVATION 		 VARCHAR2(30) := 'Query Reservation';
  g_ET_QUERY_RESERV_TO_INTER     VARCHAR2(50) := 'Query Reservation To Internal';


END MM_PJM_EES;
/