CREATE OR REPLACE PACKAGE MEX_ERCOT_LMP IS
-- $Revision: 1.8 $

	-- AUTHOR  : LDUMITRIU
	-- CREATED : 5/2/2006 4:50:27 PM
	-- PURPOSE :

FUNCTION WHAT_VERSION RETURN VARCHAR2;

	PROCEDURE FETCH_HIST_PAGE(p_CRED	   IN mex_credentials,
						  p_PRICE_TYPE IN VARCHAR2,
						  p_BEGIN_DATE IN DATE,
						  p_END_DATE   IN DATE,
						  p_LOG_ONLY   IN NUMBER,
						  p_FILE_LIST  OUT PARSE_UTIL.BIG_STRING_TABLE_MP,
						  p_STATUS     OUT NUMBER,
						  p_MESSAGE    OUT VARCHAR2,
						  p_LOGGER	   IN OUT mm_logger_adapter);

	PROCEDURE FETCH_MKT_CLEARING_PRICE(p_CRED	   IN mex_credentials,
								   p_FILE_NAME   IN VARCHAR2,
								   p_LOG_ONLY    IN NUMBER,
								   p_WORK_ID     OUT NUMBER,
								   p_STATUS      OUT NUMBER,
								   p_MESSAGE     OUT VARCHAR2,
								   p_LOGGER	   IN OUT mm_logger_adapter);

	PROCEDURE FETCH_ANCILLARY_SERVICE(p_CRED		IN mex_credentials,
								  p_FILE_NAME   IN VARCHAR2,
								  p_LOG_ONLY    IN NUMBER,
								  p_RECORDS     OUT MEX_ERCOT_ANCILLARY_SERV_TBL,
								  p_STATUS      OUT NUMBER,
								  p_MESSAGE     OUT VARCHAR2,
								  p_LOGGER		IN OUT mm_logger_adapter);



	--NEEDED URLs WHEN DOWNLOADING MARKET PRICES AND ANCILLARY SERVICES
	--g_LMP_HIST_BASE_URL CONSTANT VARCHAR2(100) := 'http://www.ercot.com/publicrmc/pubreportexplorer.asp?report=Market%20Shadow%20Prices%20Extract';
	g_LMP_MKT_PRICE     CONSTANT VARCHAR2(3) := 'LMP';

	--g_ANC_HIST_BASE_URL CONSTANT VARCHAR2(100) := 'http://www.ercot.com/publicrmc/pubreportexplorer.asp?report=DayAhead%20Report';
    g_ANC_MKT_PRICE     CONSTANT VARCHAR2(10) := 'ANCILLARY';

END MEX_ERCOT_LMP;
/