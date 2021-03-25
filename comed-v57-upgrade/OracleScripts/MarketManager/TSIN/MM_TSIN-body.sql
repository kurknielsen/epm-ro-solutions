CREATE OR REPLACE PACKAGE BODY MM_TSIN IS

-----------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TSIN_DATA
(
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
    p_LOGGER  IN OUT MM_LOGGER_ADAPTER
) IS

BEGIN
    p_STATUS := GA.SUCCESS;

    MEX_TSIN.FETCH_TSIN_DATA(p_STATUS, p_MESSAGE, p_LOGGER);
	
	IF p_STATUS = GA.SUCCESS THEN
      p_LOGGER.LOG_INFO('TSIN Data successfully downloaded!');
    END IF;

    --There is no MM side for this import

EXCEPTION
    WHEN OTHERS THEN
        p_MESSAGE := SQLERRM;
        p_STATUS  := SQLCODE;
END IMPORT_TSIN_DATA;
------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
(
    p_BEGIN_DATE            IN DATE,
    p_END_DATE              IN DATE,
    p_EXCHANGE_TYPE         IN VARCHAR2,
    p_LOG_TYPE              IN NUMBER,
    p_TRACE_ON              IN NUMBER,
    p_STATUS                OUT NUMBER,
    p_MESSAGE               OUT VARCHAR2
) AS

    v_CRED     MEX_CREDENTIALS;
    v_LOGGER   MM_LOGGER_ADAPTER;

BEGIN
    p_STATUS   := GA.SUCCESS;
   
    MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID    =>EC.ES_TSIN,
                     p_EXTERNAL_ACCOUNT_NAME => NULL,
                     p_PROCESS_NAME          => g_ET_DOWNLOAD_TSIN_DATA,
                     p_EXCHANGE_NAME         => g_ET_DOWNLOAD_TSIN_DATA,
                     p_LOG_TYPE              => p_LOG_TYPE,
                     p_TRACE_ON              => p_TRACE_ON,
                     p_CREDENTIALS           => v_CRED,
                     p_LOGGER                => v_LOGGER,
                     p_IS_PUBLIC             => TRUE);
    
    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

    IF p_EXCHANGE_TYPE = g_ET_DOWNLOAD_TSIN_DATA THEN
        IMPORT_TSIN_DATA(p_STATUS, p_MESSAGE, v_LOGGER);
    ELSE
        p_STATUS  := -1;
        p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
        v_LOGGER.LOG_ERROR(p_MESSAGE);
    END IF;

    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
    WHEN OTHERS THEN
        p_MESSAGE := SQLERRM;
        p_STATUS  := SQLCODE;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
		
END MARKET_EXCHANGE;
--------------------------------------------------------------------------------
END MM_TSIN;
/
