CREATE OR REPLACE PACKAGE MEX_PJM_OASIS IS

  -- Author  : AHUSSAIN
  -- Created : 9/25/2006 9:22:09 AM
  -- Purpose :
  -- $Revision: 1.8 $

 g_PJM_TIME_ZONE CONSTANT VARCHAR2(3) := 'EDT';
 g_DST_SPRING_AHEAD_OPTION CONSTANT CHAR := 'B';

FUNCTION WHAT_VERSION RETURN VARCHAR2;

 PROCEDURE FETCH_LOAD_FORECAST(p_CRED				IN MEX_CREDENTIALS,
								p_LOG_ONLY			IN NUMBER,
                                p_RECORDS     OUT MEX_PJM_LOAD_TBL,
                                p_STATUS      OUT NUMBER,
                                p_MESSAGE     OUT VARCHAR2,
								p_LOGGER 			IN OUT NOCOPY MM_LOGGER_ADAPTER);

PROCEDURE FETCH_OP_RESV_RATES(p_CRED			IN MEX_CREDENTIALS,
							  P_LOG_ONLY		IN NUMBER,
							  p_DATE            IN DATE,
							  p_DA_RATE_RECORDS OUT PRICE_QUANTITY_SUMMARY_TABLE,
							  p_RT_RATE_RECORDS OUT PRICE_QUANTITY_SUMMARY_TABLE,
							  p_OP_RESV_RATES OUT MEX_PJM_OP_RES_RATES_TBL,
							  p_STATUS          OUT NUMBER,
							  p_MESSAGE         OUT VARCHAR2,
							  p_LOGGER 			IN OUT NOCOPY MM_LOGGER_ADAPTER);


PROCEDURE PARSE_OP_RESV_RATES_MSRS
    (
    p_RESPONSE_CLOB IN CLOB,
    p_RECORDS       OUT MEX_PJM_OP_RES_RATES_TBL,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
    );
END MEX_PJM_OASIS;
/