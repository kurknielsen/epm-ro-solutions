CREATE OR REPLACE PACKAGE MEX_PJM_EFTR IS
  -- Market Exchange procedures for the PJM eFTR interface.
  -- These procedures can be called by both Monaco and MarketManager procedures,
  -- therefore this package should not reference any tables or procedures
  -- specific to MarketManager, RetailOffice, or Monaco.
  -- $Revision: 1.22 $

  TYPE REF_CURSOR IS REF CURSOR;

  FUNCTION WHAT_VERSION RETURN VARCHAR;

  PROCEDURE GET_AUCTION_MARKET_DATES(p_AUCTION_MARKET_NAME IN VARCHAR2,
                                     p_AUCTION_BEGIN_DATE  OUT DATE,
                                     p_AUCTION_END_DATE    OUT DATE,
                                     p_IS_ANNUAL           OUT BOOLEAN,
                                     p_STATUS              OUT NUMBER,
                                     p_MESSAGE             OUT VARCHAR2);

  PROCEDURE GET_AUCTION_MARKET_NAMES_LIST(p_BEGIN_DATE           IN DATE,
                                          p_END_DATE             IN DATE,
                                          p_DELIMITER            IN CHAR,
                                          p_AUCTION_MARKET_NAMES OUT VARCHAR2,
                                          p_STATUS               OUT NUMBER,
                                          p_MESSAGE              OUT VARCHAR2);

  PROCEDURE GET_AUCTION_MARKET_NAMES_TABLE(p_BEGIN_DATE           IN DATE,
                                           p_END_DATE             IN DATE,
                                           p_ENTITY_LIST          IN VARCHAR2,
                                           p_ENTITY_DELIMITER     IN CHAR,
                                           p_AUCTION_MARKET_NAMES OUT PARSE_UTIL.STRING_TABLE,
                                           p_STATUS               OUT NUMBER,
                                           p_MESSAGE              OUT VARCHAR2);

  PROCEDURE GETX_SUBMIT_QUOTES(p_RECORDS          IN MEX_PJM_FTR_QUOTES_TBL,
                               p_XML_REQUEST_BODY OUT XMLTYPE);

  PROCEDURE PARSE_MARKET_RESULTS(p_XML_RESPONSE IN XMLTYPE,
                                 p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_MARKET_RESULTS_TBL,
                                 p_STATUS       OUT NUMBER,
                                 p_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_FTR_QUOTES(p_XML_RESPONSE IN XMLTYPE,
                             p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_QUOTES_TBL,
                             p_STATUS       OUT NUMBER,
                             p_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_INITIAL_ARR(p_XML_RESPONSE IN XMLTYPE,
                              p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_INITIAL_ARR_TBL,
                              p_STATUS       OUT NUMBER,
                              p_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_PORTFOLIOS(p_XML_RESPONSE IN XMLTYPE,
                             p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_PORTFOLIOS_TBL,
                             p_STATUS       OUT NUMBER,
                             p_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_MARKET_INFO(p_XML_RESPONSE IN XMLTYPE,
                            p_STATUS       OUT NUMBER,
                            p_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_FTR_NODES(p_XML_RESPONSE IN XMLTYPE,
                            p_STATUS       OUT NUMBER,
                            p_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_CLEARED_FTRS(p_XML_RESPONSE IN XMLTYPE,
                               p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_CLEARED_TBL,
                               p_STATUS       OUT NUMBER,
                               p_MESSAGE      OUT VARCHAR2);

  PROCEDURE QUERY_MARKET_RESULTS(p_CRED          IN mex_credentials,
  								 p_LOG_ONLY      IN BINARY_INTEGER,
                                 p_RECORDS       OUT MEX_PJM_FTR_MARKET_RESULTS_TBL,
                                 p_STATUS        OUT NUMBER,
                                 p_MESSAGE       OUT VARCHAR2,
								 p_LOGGER		   IN OUT mm_logger_adapter);

  PROCEDURE QUERY_FTR_QUOTES(p_CRED			 IN	 mex_credentials,
						   p_LOG_ONLY		 IN  BINARY_INTEGER,
                           p_RECORDS       OUT MEX_PJM_FTR_QUOTES_TBL,
                           p_STATUS        OUT NUMBER,
                           p_MESSAGE       OUT VARCHAR2,
						   p_LOGGER		   IN OUT mm_logger_adapter);

  PROCEDURE QUERY_FTR_NODES(p_CRED			 IN	 mex_credentials,
					      p_LOG_ONLY		 IN  BINARY_INTEGER,
                          p_STATUS     OUT NUMBER,
                          p_MESSAGE    OUT VARCHAR2,
						  p_LOGGER		   IN OUT mm_logger_adapter);

  PROCEDURE QUERY_INITIAL_ARR(p_CRED			 IN	 mex_credentials,
  							  p_LOG_ONLY		 IN  BINARY_INTEGER,
                              p_RECORDS          OUT MEX_PJM_FTR_INITIAL_ARR_TBL,
                              p_STATUS           OUT NUMBER,
                              p_MESSAGE          OUT VARCHAR2,
							  p_LOGGER		   IN OUT mm_logger_adapter);

  PROCEDURE QUERY_CLEARED_FTRS(p_CRED			 IN	 mex_credentials,
							    p_LOG_ONLY		 IN  BINARY_INTEGER,
                          		p_RECORDS        OUT MEX_PJM_FTR_CLEARED_TBL,
                                p_STATUS         OUT NUMBER,
                                p_MESSAGE        OUT VARCHAR2,
								p_LOGGER		   IN OUT mm_logger_adapter);

 PROCEDURE QUERY_MARKET_INFO(p_CRED			 IN	 mex_credentials,
							p_LOG_ONLY		 IN  BINARY_INTEGER,
                            p_STATUS     OUT NUMBER,
                            p_MESSAGE    OUT VARCHAR2,
							p_LOGGER	 IN OUT mm_logger_adapter);

 PROCEDURE QUERY_MARKET_MESSAGES(p_CRED			 IN	 mex_credentials,
							    p_LOG_ONLY		 IN  BINARY_INTEGER,
								p_EFFECTIVE_DATE IN DATE,
                          		p_RECORDS    OUT MEX_PJM_FTR_MESSAGE_TBL,
                                p_STATUS     OUT NUMBER,
                                p_MESSAGE    OUT VARCHAR2,
								p_LOGGER		   IN OUT mm_logger_adapter);

  PROCEDURE GETX_QUERY_FTR_NODES(p_MARKET_NAMES     IN PARSE_UTIL.STRING_TABLE,
                               p_XML_REQUEST_BODY OUT XMLTYPE,
                               p_STATUS           OUT NUMBER,
                               p_MESSAGE          OUT VARCHAR2);

PROCEDURE QUERY_FTR_POSITION
    (
	p_CRED IN mex_credentials,
	p_LOG_ONLY IN BINARY_INTEGER,
    p_DATE IN DATE,
    p_RECORDS OUT MEX_PJM_FTR_POSITION_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
    );

PROCEDURE PARSE_FTR_POSITION
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS IN OUT NOCOPY MEX_PJM_FTR_POSITION_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    );

PROCEDURE PARSE_ARR_RESULTS
	(
	p_XML_RESPONSE IN XMLTYPE,
	p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_INITIAL_ARR_TBL,
	p_STATUS       OUT NUMBER,
	p_MESSAGE      OUT VARCHAR2
	);

PROCEDURE SUBMIT_FTR_QUOTES
	(
	p_CRED IN MEX_CREDENTIALS,
	p_RECORDS IN MEX_PJM_FTR_QUOTES_TBL,
	p_LOG_ONLY IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT MM_LOGGER_ADAPTER
	);

  g_SECOND             CONSTANT NUMBER(6, 5) := 1 / 86400;
  g_PJM_EFTR_TIMEZONE  CONSTANT CHAR(3) := 'EDT';
  g_FTR_NAMESPACE      CONSTANT VARCHAR2(64) := 'xmlns="http://eftr.pjm.com/ftr/xml"';
  g_FTR_NAMESPACE_NAME CONSTANT VARCHAR2(64) := 'http://eftr.pjm.com/ftr/xml';
  g_FTR_ON_PEAK_BEGIN  CONSTANT NUMBER(2) := 8;
  g_FTR_ON_PEAK_END    CONSTANT NUMBER(2) := 23;

  g_TRACE_ON NUMBER(1) := 0; --DEBUG TRACE
  g_ON       NUMBER(1) := 1;

  g_SUCCESS NUMBER(1) := 0;

END MEX_PJM_EFTR;
/
