CREATE OR REPLACE PACKAGE MM_MISO_PSS IS
-- $Revision: 1.7 $

  -- Author  : LDUMITRIU
  -- Created : 02/23/2006 11:30:31 AM
  -- Purpose :

  -- Public type declarations


FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE QUERY_PSS_SCHEDULE_BIDS(p_CRED      IN mex_credentials,
								  p_BEGIN_DATE    IN DATE,
								  p_END_DATE      IN DATE,
								  p_LOG_ONLY      IN NUMBER,
								  p_STATUS        OUT NUMBER,
								  p_ERROR_MESSAGE OUT VARCHAR2,
								  p_LOGGER IN OUT mm_logger_adapter);

   g_DATE_TIME_FORMAT CONSTANT VARCHAR2(32) := 'yyyy-mm-dd"T"hh24:mi:ss';
	/*g_MISO_PSS_NAMESPACE CONSTANT VARCHAR2(64) := 'xmlns="https://marketpssweb.midwestiso.org/"';
    g_MISO_PSS_NAMESPACE_NAME CONSTANT VARCHAR2(64) := 'https://marketpssweb.midwestiso.org';*/
END MM_MISO_PSS;
/