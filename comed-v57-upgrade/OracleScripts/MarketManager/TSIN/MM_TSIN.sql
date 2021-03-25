CREATE OR REPLACE PACKAGE MM_TSIN IS
-- $Revision: 1.4 $

    -- AUTHOR  : LDUMITRIU
    -- CREATED : 02/06/2008 11:32:01
    -- PURPOSE : DOWNLOAD THE TSIN DATA

-------------------------------------------------------------------------
-- Market_exchange constant
g_ET_DOWNLOAD_TSIN_DATA CONSTANT VARCHAR2(32) := 'Download TSIN Data';

-------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2;

    PROCEDURE MARKET_EXCHANGE
(
    p_BEGIN_DATE            IN DATE,
    p_END_DATE              IN DATE,
    p_EXCHANGE_TYPE         IN VARCHAR2,
    p_LOG_TYPE              IN NUMBER,
    p_TRACE_ON              IN NUMBER,
    p_STATUS                OUT NUMBER,
    p_MESSAGE               OUT VARCHAR2
);
-------------------------------------------------------------------------
END MM_TSIN;
/