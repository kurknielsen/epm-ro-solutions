CREATE OR REPLACE PACKAGE MM_MISO_LMP IS
-- $Revision: 1.7 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE PUT_MARKET_PRICE_LMP
    (
    p_PRICE_DATE IN DATE,
    p_LOCATION_NAME IN VARCHAR2,
    p_MARKET_PRICE_TYPE IN VARCHAR2,
    p_MARKET_PRICE_ABBR IN VARCHAR2,
    p_MARKET_TYPE IN VARCHAR2,
    p_INTERVAL IN VARCHAR2,
    p_PRICE IN NUMBER,    
    p_ERROR_MESSAGE OUT VARCHAR2
    );

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_LOG_ONLY					IN NUMBER := 0,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

	g_ET_QRY_DA_LMP CONSTANT VARCHAR2(50) :='Query Day Ahead LMP';
    g_ET_QRY_RT_LMP CONSTANT VARCHAR2(50) :='Query Real Time LMP';

END MM_MISO_LMP;
/