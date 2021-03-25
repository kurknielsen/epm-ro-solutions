CREATE OR REPLACE PACKAGE MEX_PJM_ERPM IS

  -- Author  : CNAVALTA
  -- Created : 6/6/2007 2:26:03 PM
  -- Purpose : Handle Fetch and Parse of eRM reports
-- $Revision: 1.5 $

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE FETCH_NETWK_SERV_PK_LD
    (
    p_CRED	IN mex_credentials,
	p_LOG_ONLY IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_COMPANY_NAME IN VARCHAR2,
    p_RECORDS OUT MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter);

PROCEDURE FETCH_CAPACITY_OBLIGATION
    (
    p_CRED IN mex_credentials,
	p_LOG_ONLY IN NUMBER,
    p_BEGIN_DATE IN DATE,
	p_COMPANY_NAME IN VARCHAR2,
    p_RECORDS OUT MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter);

PROCEDURE PARSE_NETWK_SERV_PK_LD
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS IN OUT NOCOPY MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    );

PROCEDURE PARSE_CAPACITY_OBLIG
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS IN OUT NOCOPY MEX_PJM_ECAP_LOAD_OBL_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    );

END MEX_PJM_ERPM;
/