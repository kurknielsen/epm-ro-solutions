CREATE OR REPLACE PACKAGE MM_OASIS IS
-- $Revision: 1.30 $
	TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

PROCEDURE MARKET_EXCHANGE_ENTITY_LIST
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR,
	p_ENTITY_LABEL OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);

PROCEDURE MARKET_SUBMIT
	(
	   p_BEGIN_DATE      IN DATE,
       p_END_DATE        IN DATE,
       p_EXCHANGE_TYPE   IN VARCHAR2,
       p_LOG_ONLY	    IN NUMBER,
       p_ENTITY_LIST 	 IN VARCHAR2,
       p_ENTITY_LIST_DELIMITER IN CHAR,
       p_SUBMIT_HOURS    IN VARCHAR2,
       p_TIME_ZONE       IN VARCHAR2,
	   p_LOG_TYPE		 IN NUMBER,
	   p_TRACE_ON		 IN NUMBER,
       p_STATUS          OUT NUMBER,
       p_MESSAGE         OUT VARCHAR2);


PROCEDURE CREATE_TXN
	(
	p_TRANSACTION_NAME IN OUT VARCHAR2,
	p_TRANSACTION_IDENT IN VARCHAR2,
	p_DEAL_REF IN OUT VARCHAR2,
	p_SELLER_CODE IN VARCHAR2,
	p_CUSTOMER_CODE IN VARCHAR2,
	p_SOURCE IN VARCHAR2,
	p_SINK IN VARCHAR2,
	p_POD IN VARCHAR2,
	p_POR IN VARCHAR2,
	p_TRANSACTION_INTERVAL IN VARCHAR2,
	p_TP_CODE IN VARCHAR2,
	p_TP_ID	IN NUMBER,
	p_START_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TRANSACTION_ID OUT NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER);

PROCEDURE MARKET_SUBMIT_TRANSACTION_LIST
	(
	p_BEGIN_DATE 	IN DATE,
	p_END_DATE 		IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR2,
	p_LOG_TYPE		IN NUMBER,
	p_TRACE_ON		IN NUMBER,
	p_STATUS 		OUT NUMBER,
	p_CURSOR 		IN OUT REF_CURSOR);

FUNCTION IS_SUPPORTED_EXCHANGE_TYPE
	(
	p_MKT_APP IN VARCHAR2,
	p_EXCHANGE_TYPE IN VARCHAR2
	) RETURN BOOLEAN;

FUNCTION GET_BID_OFFER_INTERVAL
	(
	p_TRANSACTION IN INTERCHANGE_TRANSACTION%ROWTYPE
	) RETURN VARCHAR2;

PROCEDURE GET_STATUS_NOTIFICATIONS
	(
	p_PROVIDER_CODE IN VARCHAR2,
	p_LOG_TYPE     IN NUMBER,
    p_TRACE_ON     IN NUMBER,
	p_STATUS        OUT NUMBER,
	p_MESSAGE       OUT VARCHAR2
	);

g_TRANSCUST_CONFIRM CONSTANT VARCHAR2(16) := 'CONFIRMED';
g_TRANSCUST_WITHDRAW CONSTANT VARCHAR2(16) := 'WITHDRAWN';

g_EA_TS_CLASS CONSTANT VARCHAR2(16) := 'TS CLASS';
g_EA_TS_TYPE CONSTANT VARCHAR2(16) := 'TS TYPE';
g_EA_TS_PERIOD CONSTANT VARCHAR2(16) := 'TS PERIOD';
g_EA_TS_WINDOW CONSTANT VARCHAR2(16) := 'TS WINDOW';
g_EA_TS_SUBCLASS CONSTANT VARCHAR2(16) := 'TS SUBCLASS';
g_EA_RELATED_REF CONSTANT VARCHAR2(16) := 'RELATED REF';

g_ACTION_SUB_TRANSREQUEST CONSTANT VARCHAR2(32) := 'Submit Purchase Request';
g_ACTION_SUB_TRANSCUST_CONF CONSTANT VARCHAR2(32) := 'Confirm Purchase';
g_ACTION_SUB_TRANSCUST_WITH CONSTANT VARCHAR2(32) := 'Withdraw Purchase';
g_ACTION_QUE_TRANSSTATUS CONSTANT VARCHAR2(32) := 'Query Status';
g_ACTION_QUE_LIST CONSTANT VARCHAR2(32) := 'Query List';

g_SCHEDULE_TYPE CONSTANT NUMBER(9) := 2;

g_STATUS_ALERT_NAME CONSTANT VARCHAR2(32) := 'OASIS Status Change';
g_STATUS_MESSAGES CONSTANT VARCHAR2(32) := 'oasis.status';
END MM_OASIS;
/