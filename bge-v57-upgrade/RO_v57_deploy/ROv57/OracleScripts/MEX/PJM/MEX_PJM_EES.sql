CREATE OR REPLACE PACKAGE MEX_PJM_EES IS
-- $Revision: 1.8 $

g_DATE_TIME_ZONE_FORMAT CONSTANT VARCHAR2(32) := 'DY MON DD hh24:mi:ss "EDT" YYYY';
g_DATE_FORMAT           CONSTANT VARCHAR2(16) := 'MM/DD/YYYY';
-------------------------------------------------------------------------------------

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE FETCH_TWO_SETTLEMENT_REPORT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED IN MEX_CREDENTIALS,
	p_LOG_ONLY IN NUMBER,
	p_RECORDS OUT MEX_PJM_EES_TWOSETTLE_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

PROCEDURE SUBMIT_TAG_RESERVATION
	(
	p_PARAMETER_MAP IN OUT MEX_Util.Parameter_Map,
	p_BEGIN_DATE    IN DATE,
	p_END_DATE		IN DATE,
	p_RECORDS 		IN OUT MEX_PJM_EES_RAMPRES_TBL,
	p_LOGGER 		IN OUT MM_LOGGER_ADAPTER,
	p_CRED 			IN MEX_CREDENTIALS,
	p_LOG_ONLY		IN NUMBER,
	p_STATUS 		OUT NUMBER,
	p_MESSAGE 		OUT VARCHAR2
	) ;

PROCEDURE FETCH_TAG_RES_REPORT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED IN MEX_CREDENTIALS,
	p_LOG_ONLY IN NUMBER,
	p_RECORDS OUT MEX_PJM_EES_TAGRES_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

END MEX_PJM_EES;
/