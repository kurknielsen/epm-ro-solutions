CREATE OR REPLACE PACKAGE MEX_PJM_EMKT IS
-- $Revision: 1.36 $

  G_DATE_TIME_FORMAT CONSTANT VARCHAR2(32) := 'yyyy-mm-dd"T"hh24:mi:ss".000"';
  G_DATE_FORMAT      CONSTANT VARCHAR2(16) := 'YYYY-MM-DD';

  g_LOC_TYPE_PORTFOLIO CONSTANT VARCHAR2(32) := 'PORTFOLIONAME';
  g_LOC_TYPE_LOCATION CONSTANT VARCHAR2(32) := 'LOCATIONNAME';
  g_LOC_TYPE_ALL CONSTANT VARCHAR2(32) := 'ALL';

FUNCTION WHAT_VERSION RETURN VARCHAR2;

  FUNCTION GET_DATE(p_DATE IN DATE)
    RETURN VARCHAR2;
  FUNCTION GET_HOUR(p_DATE IN DATE)
    RETURN VARCHAR2;
  FUNCTION GET_ISDUPLICATE(p_DATE IN DATE)
    RETURN VARCHAR2;


  -----------------------------------------------------------------------------------------
  PROCEDURE PARSE_PORTFOLIOS(P_XML_RESPONSE IN XMLTYPE,
                             P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_PORTFOLIO_TBL,
                             P_STATUS       OUT NUMBER,
                             P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_PORTFOLIOS(P_PORTFOLIO_NAME  IN VARCHAR2,
								 P_CRED			 IN mex_credentials,
								 P_LOG_ONLY		 IN BINARY_INTEGER,
                                 P_RECORDS       OUT MEX_PJM_EMKT_PORTFOLIO_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_DISTRIBUTION(P_XML_RESPONSE IN XMLTYPE,
                               P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_DISTRIBUTION_TBL,
                               P_STATUS       OUT NUMBER,
                               P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_DISTRIBUTION(P_CRED          IN mex_credentials,
  							   P_LOG_ONLY      IN BINARY_INTEGER,
  							   P_LOCATION_TYPE IN VARCHAR2,
							   P_LOCATION_NAME IN VARCHAR2,
							   P_REQUEST_DATE  IN DATE,
                               P_RECORDS       OUT MEX_PJM_EMKT_DISTRIBUTION_TBL,
                               P_STATUS        OUT NUMBER,
                               P_MESSAGE       OUT VARCHAR2,
							   P_LOGGER		   IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------

  PROCEDURE PARSE_SPIN_RESERVE_RES(P_XML_RESPONSE IN XMLTYPE,
                                   P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RSV_RES_TBL,
                                   P_STATUS       OUT NUMBER,
                                   P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_SPIN_RESERVE_RES(P_CRED		   IN  mex_credentials,
  								   P_LOG_ONLY	   IN  BINARY_INTEGER,
								   P_REQUEST_DATE  IN  DATE,
								   P_RECORDS       OUT MEX_PJM_EMKT_SPIN_RSV_RES_TBL,
                                   P_STATUS        OUT NUMBER,
                                   P_MESSAGE       OUT VARCHAR2,
								   P_LOGGER		   IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPIN_RESERVE_BIL(P_XML_RESPONSE IN XMLTYPE,
                                   P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RSV_BIL_TBL,
                                   P_STATUS       OUT NUMBER,
                                   P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_SPIN_RESERVE_BIL(P_CRED		   IN  mex_credentials,
  								   P_LOG_ONLY	   IN  BINARY_INTEGER,
  								   P_REQUEST_DATE  IN  DATE,
                                   P_RECORDS       OUT MEX_PJM_EMKT_SPIN_RSV_BIL_TBL,
                                   P_STATUS        OUT NUMBER,
                                   P_MESSAGE       OUT VARCHAR2,
								   P_LOGGER		   IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_HOURLY_LMP(P_XML_RESPONSE IN XMLTYPE,
                             P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_HOURLY_LMP_TBL,
                             P_STATUS       OUT NUMBER,
                             P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_HOURLY_LMP(P_CRED			 IN mex_credentials,
							 P_LOG_ONLY		 IN BINARY_INTEGER,
							 P_BEGIN_DATE	 IN DATE,
  							 P_END_DATE		 IN DATE,
							 P_RECORDS       OUT MEX_PJM_EMKT_HOURLY_LMP_TBL,
                             P_STATUS        OUT NUMBER,
                             P_MESSAGE       OUT VARCHAR2,
							 P_LOGGER		 IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_DEMAND_SUMMARY(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_DEMAND_SUMM_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_DEMAND_SUMMARY(P_CRED			 IN mex_credentials,
								 P_LOG_ONLY		 IN BINARY_INTEGER,
								 P_BEGIN_DATE	 IN DATE,
  								 P_END_DATE		 IN DATE,
                                 P_RECORDS       OUT MEX_PJM_EMKT_DEMAND_SUMM_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_ANCILLARY_SERV(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_ANCILLAR_SERV_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_ANCILLARY_SERV(p_CRED			 IN	 mex_credentials,
							   p_LOG_ONLY		 IN  BINARY_INTEGER,
							   p_REQUEST_DATE	 IN  DATE,
							   p_RECORDS       OUT MEX_PJM_EMKT_ANCILLAR_SERV_TBL,
							   p_STATUS        OUT NUMBER,
							   p_MESSAGE       OUT VARCHAR2,
							   p_LOGGER		   IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_MESSAGES(P_XML_RESPONSE IN XMLTYPE,
                           P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_MESSAGES_TBL,
                           P_STATUS       OUT NUMBER,
                           P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_MESSAGES(P_CRED			 IN mex_credentials,
								 P_LOG_ONLY		 IN BINARY_INTEGER,
                                 P_RECORDS       OUT MEX_PJM_EMKT_MESSAGES_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_MARKET_RESULTS(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_MKT_RESULTS_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_MARKET_RESULTS(p_CRED				IN mex_credentials,
  								 p_LOG_ONLY			IN BINARY_INTEGER,
  								 p_REQUEST_DATE 	IN DATE,
								 p_EMKT_GEN			IN NUMBER := 0,
								 p_EMKT_LOAD		IN NUMBER := 0,
                                 p_GEN_LOCATION_TYPE IN VARCHAR2,
								 p_GEN_LOCATION_NAME IN VARCHAR2,
								 p_LOAD_LOCATION_TYPE IN VARCHAR2,
								 p_LOAD_LOCATION_NAME IN VARCHAR2,
                                 p_RECORDS       OUT MEX_PJM_EMKT_MKT_RESULTS_TBL,
                                 p_STATUS        OUT NUMBER,
                                 p_MESSAGE       OUT VARCHAR2,
								 p_LOGGER		 IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_NODE_LIST(P_XML_RESPONSE IN XMLTYPE,
                            P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_NODE_TBL,
                            p_IS_BID_NODES IN BOOLEAN,
                            P_STATUS       OUT NUMBER,
                            P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_NODE_LIST(P_CRED			IN mex_credentials,
  							P_LOG_ONLY		IN BINARY_INTEGER,
							P_NODE_TYPE		IN VARCHAR2,
							P_BEGIN_DATE	iN DATE,
							P_END_DATE		IN DATE,
  							P_RECORDS       OUT MEX_PJM_EMKT_NODE_TBL,
							P_STATUS        OUT NUMBER,
							P_MESSAGE       OUT VARCHAR2,
							P_LOGGER		IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPIN_RESERVE_OFFER(P_XML_RESPONSE IN XMLTYPE,
                                     P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RES_OFF_TBL,
                                     P_STATUS       OUT NUMBER,
                                     P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_SPIN_RESERVE_OFFER(p_CRED		   IN mex_credentials,
								   p_LOG_ONLY	   IN BINARY_INTEGER,
								   p_LOCATION_TYPE IN VARCHAR2,
								   p_LOCATION_NAME IN VARCHAR2,
								   p_REQUEST_DATE  IN DATE,
								   p_RECORDS       OUT MEX_PJM_EMKT_SPIN_RES_OFF_TBL,
								   p_STATUS        OUT NUMBER,
								   p_MESSAGE       OUT VARCHAR2,
								   p_LOGGER 	   IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPIN_RESERVE_UPDATE(P_XML_RESPONSE IN XMLTYPE,
                                      P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RES_UPD_TBL,
                                      P_STATUS       OUT NUMBER,
                                      P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_SPIN_RESERVE_UPDATE(p_CRED		  IN mex_credentials,
									  p_LOG_ONLY	  IN BINARY_INTEGER,
									  p_LOCATION_TYPE IN VARCHAR2,
									  p_LOCATION_NAME IN VARCHAR2,
									  p_REQUEST_DATE  IN DATE,
                                      p_RECORDS       OUT MEX_PJM_EMKT_SPIN_RES_UPD_TBL,
                                      p_STATUS        OUT NUMBER,
                                      p_MESSAGE       OUT VARCHAR2,
									  p_LOGGER		  IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPREG_AWARD(P_XML_RESPONSE IN XMLTYPE,
                                     P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RES_AWAR_TBL,
                                     P_STATUS       OUT NUMBER,
                                     P_MESSAGE      OUT VARCHAR2);

  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_UNIT_UPDATES(P_XML_RESPONSE IN XMLTYPE,
                               P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_UNIT_UPDATES_TBL,
                               P_STATUS       OUT NUMBER,
                               P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_UNIT_UPDATES(P_CRED          IN mex_credentials,
  							   P_LOG_ONLY      IN BINARY_INTEGER,
  							   P_LOCATION_TYPE IN VARCHAR2,
							   P_LOCATION_NAME IN VARCHAR2,
							   P_REQUEST_DATE  IN DATE,
                               P_RECORDS       OUT MEX_PJM_EMKT_UNIT_UPDATES_TBL,
                               P_STATUS        OUT NUMBER,
                               P_MESSAGE       OUT VARCHAR2,
							   P_LOGGER		   IN OUT mm_logger_adapter);
  -------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_REGULATION_OFFER(p_CRED		  IN mex_credentials,
  							  	   p_LOG_ONLY	  IN BINARY_INTEGER,
								   p_LOCATION_TYPE IN VARCHAR2,
								   p_LOCATION_NAME IN VARCHAR2,
								   p_REQUEST_DATE  IN DATE,
                                   p_RECORDS       OUT MEX_PJM_EMKT_REG_OFFER_TBL,
                                   p_STATUS        OUT NUMBER,
                                   p_MESSAGE       OUT VARCHAR2,
								   p_LOGGER		  IN OUT mm_logger_adapter);

  PROCEDURE FETCH_REGULATION_UPDATE(p_CRED			IN mex_credentials,
  									p_LOG_ONLY		IN BINARY_INTEGER,
  									p_LOCATION_TYPE IN VARCHAR2,
  									p_LOCATION_NAME IN VARCHAR2,
									p_REQUEST_DATE  IN DATE,
                                    p_RECORDS       OUT MEX_PJM_EMKT_REG_UPDATE_TBL,
                                    p_STATUS        OUT NUMBER,
                                    p_MESSAGE       OUT VARCHAR2,
									p_LOGGER		IN OUT mm_logger_adapter);

  PROCEDURE FETCH_SPREG_AWARD(p_CRED		  IN mex_credentials,
  							  p_LOG_ONLY	  IN BINARY_INTEGER,
							  p_LOCATION_TYPE IN VARCHAR2,
							  p_LOCATION_NAME IN VARCHAR2,
							  p_REQUEST_DATE  IN DATE,
							  p_RECORDS       OUT MEX_PJM_EMKT_SPIN_RES_AWAR_TBL,
							  p_STATUS        OUT NUMBER,
							  p_MESSAGE       OUT VARCHAR2,
							  p_LOGGER		  IN OUT mm_logger_adapter);

  PROCEDURE FETCH_REGULATION_RESULTS(p_CRED		  IN mex_credentials,
  							  		 p_LOG_ONLY	  IN BINARY_INTEGER,
									 p_REQUEST_DATE  IN DATE,
                                     p_RECORDS       OUT MEX_PJM_EMKT_REG_RESULTS_TBL,
                                     p_STATUS        OUT NUMBER,
                                     p_MESSAGE       OUT VARCHAR2,
									 p_LOGGER		 IN OUT mm_logger_adapter);

  PROCEDURE FETCH_REGULATION_BILATERAL(p_CRED		  IN mex_credentials,
  							  		   p_LOG_ONLY	  IN BINARY_INTEGER,
									   p_REQUEST_DATE  IN  DATE,
                                       p_RECORDS       OUT MEX_PJM_EMKT_REG_BILATERAL_TBL,
                                       p_STATUS        OUT NUMBER,
                                       p_MESSAGE       OUT VARCHAR2,
									   p_LOGGER		   IN OUT mm_logger_adapter);

  PROCEDURE FETCH_UNIT_SCHEDULES(p_CRED			 IN mex_credentials,
  								 p_LOG_ONLY		 IN BINARY_INTEGER,
  								 p_LOCATION_TYPE IN VARCHAR2,
  								 p_LOCATION_NAME IN VARCHAR2,
                                 p_RECORDS       OUT MEX_PJM_EMKT_UNIT_SCHED_TBL,
                                 p_STATUS        OUT NUMBER,
                                 p_MESSAGE       OUT VARCHAR2,
								 p_LOGGER		 IN OUT mm_logger_adapter);

  PROCEDURE FETCH_UNIT_DETAIL(p_CRED		  IN mex_credentials,
  							  p_LOG_ONLY	  IN BINARY_INTEGER,
							  p_LOCATION_TYPE IN VARCHAR2,
  							  p_LOCATION_NAME IN VARCHAR2,
							  p_REQUEST_DATE  IN DATE,
                              p_RECORDS       OUT MEX_PJM_EMKT_UNIT_DETAIL_TBL,
                              p_STATUS        OUT NUMBER,
                              p_MESSAGE       OUT VARCHAR2,
							  p_LOGGER		  IN OUT mm_logger_adapter);

  PROCEDURE FETCH_SCHEDULE_DETAIL(P_CRED          IN mex_credentials,
  							   	  P_LOG_ONLY      IN BINARY_INTEGER,
								  P_LOCATION_TYPE IN VARCHAR2,
								  P_LOCATION_NAME IN VARCHAR2,
								  P_REQUEST_DATE  IN DATE,
                                  P_RECORDS       OUT MEX_PJM_EMKT_SCHED_DETAIL_TBL,
                                  P_STATUS        OUT NUMBER,
                                  P_MESSAGE       OUT VARCHAR2,
								  p_LOGGER		  IN OUT mm_logger_adapter);

  PROCEDURE PARSE_SCHEDULE_SELECTION(P_XML_RESPONSE IN XMLTYPE,
                                     P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SCHED_SEL_TBL,
                                     P_STATUS       OUT NUMBER,
                                     P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_SCHEDULE_SELECTION(P_CRED          IN mex_credentials,
  									 P_LOG_ONLY      IN BINARY_INTEGER,
									 P_LOCATION_TYPE IN VARCHAR2,
									 P_LOCATION_NAME IN VARCHAR2,
									 P_REQUEST_DATE  IN DATE,
									 P_RECORDS       OUT MEX_PJM_EMKT_SCHED_SEL_TBL,
									 P_STATUS        OUT NUMBER,
									 P_MESSAGE       OUT VARCHAR2,
									 P_LOGGER		 IN OUT mm_logger_adapter);

  PROCEDURE PARSE_SCHEDULE_OFFER(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SCHED_OFFER_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2);

  PROCEDURE FETCH_SCHEDULE_OFFER(P_CRED          IN mex_credentials,
  							   	 P_LOG_ONLY      IN BINARY_INTEGER,
  							     P_LOCATION_TYPE IN VARCHAR2,
								 P_LOCATION_NAME IN VARCHAR2,
								 P_REQUEST_DATE  IN DATE,
                                 P_RECORDS       OUT MEX_PJM_EMKT_SCHED_OFFER_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter);

  PROCEDURE FETCH_PRICE_SENSITIVE_DEMAND(P_CRED          IN mex_credentials,
  							   			  P_LOG_ONLY      IN BINARY_INTEGER,
										  P_LOCATION_TYPE IN VARCHAR2,
										  P_LOCATION_NAME IN VARCHAR2,
										  P_REQUEST_DATE  IN DATE,
										  P_RECORDS       OUT MEX_PJM_EMKT_PRICE_SEN_DMD_TBL,
										  P_STATUS        OUT NUMBER,
										  P_MESSAGE       OUT VARCHAR2,
										  P_LOGGER		  IN OUT mm_logger_adapter);

  PROCEDURE FETCH_VIRTUAL_BIDS(p_CRED 		 IN mex_credentials,
								 p_LOG_ONLY		 IN BINARY_INTEGER,
								 p_LOCATION_TYPE IN VARCHAR2,
								 p_LOCATION_NAME IN VARCHAR2,
								 p_REQUEST_DATE  IN DATE,
								 p_RECORDS       OUT MEX_PJM_EMKT_VIRTUAL_BIDS_TBL,
								 p_STATUS        OUT NUMBER,
								 p_MESSAGE       OUT VARCHAR2,
								 p_LOGGER		 IN OUT mm_logger_adapter);

  PROCEDURE FETCH_FIXED_DEMAND(P_CRED          IN mex_credentials,
  							   P_LOG_ONLY      IN BINARY_INTEGER,
  							   P_LOCATION_TYPE IN VARCHAR2,
							   P_LOCATION_NAME IN VARCHAR2,
							   P_REQUEST_DATE  IN DATE,
                               P_RECORDS       OUT MEX_PJM_EMKT_FIXED_DEMAND_TBL,
                               P_STATUS        OUT NUMBER,
                               P_MESSAGE       OUT VARCHAR2,
							   P_LOGGER			IN OUT mm_logger_adapter);

  PROCEDURE PARSE_REGULATION_OFFER(P_XML_RESPONSE IN XMLTYPE,
                                   P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_OFFER_TBL,
                                   P_STATUS       OUT NUMBER,
                                   P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_REGULATION_UPDATE(P_XML_RESPONSE IN XMLTYPE,
                                    P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_UPDATE_TBL,
                                    P_STATUS       OUT NUMBER,
                                    P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_REGULATION_AWARD(P_XML_RESPONSE IN XMLTYPE,
                                   P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_AWARD_TBL,
                                   P_STATUS       OUT NUMBER,
                                   P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_REGULATION_RESULTS(P_XML_RESPONSE IN XMLTYPE,
                                     P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_RESULTS_TBL,
                                     P_STATUS       OUT NUMBER,
                                     P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_REGULATION_BILATERAL(P_XML_RESPONSE IN XMLTYPE,
                                       P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_BILATERAL_TBL,
                                       P_STATUS       OUT NUMBER,
                                       P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_UNIT_SCHEDULES(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_UNIT_SCHED_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_UNIT_DETAIL(P_XML_RESPONSE IN XMLTYPE,
                              P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_UNIT_DETAIL_TBL,
                              P_STATUS       OUT NUMBER,
                              P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_SCHEDULE_DETAIL(P_XML_RESPONSE IN XMLTYPE,
                                  P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SCHED_DETAIL_TBL,
                                  P_STATUS       OUT NUMBER,
                                  P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_PRICE_SENSITIVE_DEMAND(P_XML_RESPONSE IN XMLTYPE,
                                         P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_PRICE_SEN_DMD_TBL,
                                         P_STATUS       OUT NUMBER,
                                         P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_VIRTUAL_BIDS(P_XML_RESPONSE IN XMLTYPE,
                               P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_VIRTUAL_BIDS_TBL,
                               P_STATUS       OUT NUMBER,
                               P_MESSAGE      OUT VARCHAR2);

  PROCEDURE PARSE_FIXED_DEMAND(P_XML_RESPONSE IN XMLTYPE,
                               P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_FIXED_DEMAND_TBL,
                               P_STATUS       OUT NUMBER,
                               P_MESSAGE      OUT VARCHAR2);

  PROCEDURE GETX_SUBMIT_FIXED_DEMAND(p_RECORDS       IN MEX_PJM_EMKT_FIXED_DEMAND_TBL,
                                     p_SUBMIT_XML    OUT XMLTYPE,
                                     p_STATUS        OUT NUMBER,
                                     p_MESSAGE       OUT VARCHAR2);

  PROCEDURE PARSE_DEMAND_BIDS(P_XML_RESPONSE IN XMLTYPE,
  														P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_DEMAND_BID_TBL,
  														P_STATUS       OUT NUMBER,
  														P_MESSAGE      OUT VARCHAR2);

  PROCEDURE GETX_QUERY_DEMAND_BIDS(p_LOCATION_TYPE IN VARCHAR2,
  								   p_LOCATION_NAME IN VARCHAR2,
								   p_BEGIN_DATE	   IN DATE,
								   p_END_DATE	   IN DATE,
								   p_XML_REQUEST_BODY OUT XMLTYPE,
								   p_STATUS           OUT NUMBER,
								   p_MESSAGE          OUT VARCHAR2);

  PROCEDURE FETCH_DEMAND_BIDS(P_CRED          IN mex_credentials,
  							  P_LOG_ONLY      IN BINARY_INTEGER,
							  P_LOCATION_TYPE IN VARCHAR2,
							  P_LOCATION_NAME IN VARCHAR2,
							  P_BEGIN_DATE    IN DATE,
							  P_END_DATE      IN DATE,
							  P_RECORDS       OUT MEX_PJM_EMKT_DEMAND_BID_TBL,
							  P_STATUS        OUT NUMBER,
							  P_MESSAGE       OUT VARCHAR2,
							  P_LOGGER		  IN OUT mm_logger_adapter);

  PROCEDURE GETX_SUBMIT_PRICE_SENS_DEMAND(p_RECORDS       IN MEX_PJM_EMKT_PRICE_SEN_DMD_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);

 PROCEDURE GETX_SUBMIT_SCHEDULE_OFFER(p_RECORDS       IN MEX_PJM_EMKT_SCHED_OFFER_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);
 PROCEDURE GETX_SUBMIT_SCHEDULE_SELECTION(p_RECORDS       IN MEX_PJM_EMKT_SCHED_SEL_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);

 PROCEDURE GETX_SUBMIT_UNIT_UPDATE(p_RECORDS       IN MEX_PJM_EMKT_UNIT_UPDATES_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);
 PROCEDURE GETX_SUBMIT_SCHEDULE_DETAIL(p_RECORDS       IN MEX_PJM_EMKT_SCHED_DETAIL_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);
 PROCEDURE GETX_SUBMIT_UNIT_DETAIL(p_RECORDS       IN MEX_PJM_EMKT_UNIT_DETAIL_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);

  PROCEDURE GETX_SUBMIT_SPIN_OFFER(p_RECORDS       IN MEX_PJM_EMKT_SPIN_RES_OFF_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);
  PROCEDURE GETX_SUBMIT_SPIN_UPDATE(p_RECORDS       IN MEX_PJM_EMKT_SPIN_RES_UPD_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);
  PROCEDURE GETX_SUBMIT_REG_OFFER(p_RECORDS       IN MEX_PJM_EMKT_REG_OFFER_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);
  PROCEDURE GETX_SUBMIT_REG_UPDATE(p_RECORDS       IN MEX_PJM_EMKT_REG_UPDATE_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);

  PROCEDURE RUN_PJM_SUBMIT(P_CRED			  IN mex_credentials,
						  P_LOG_ONLY		  IN BINARY_INTEGER,
                          P_XML_REQUEST_BODY  IN XMLTYPE,
                          P_XML_RESPONSE_BODY OUT XMLTYPE,
						  P_STATUS			  OUT NUMBER,
                          P_ERROR_MESSAGE     OUT VARCHAR2,
						  P_LOGGER			  IN OUT mm_logger_adapter);

  PROCEDURE GETX_SUBMIT_VIRTUAL_BID(p_RECORDS       IN MEX_PJM_EMKT_VIRTUAL_BIDS_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2);

  PROCEDURE FETCH_RESPONSE_FOR_TRANSACTION(p_CRED          IN mex_credentials,
  							   			   p_LOG_ONLY      IN BINARY_INTEGER,
										   p_TRANSACTION_ID   IN VARCHAR2,
                                           p_XML_RESPONSE  OUT XMLTYPE,
                                           p_STATUS        OUT NUMBER,
                                           p_MESSAGE       OUT VARCHAR2,
										   p_LOGGER		   IN OUT mm_logger_adapter);
                                           
PROCEDURE PARSE_PARAMETER_LIMITS
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_PARAM_LIMIT_TBL,
    p_STATUS       OUT NUMBER,
    p_MESSAGE      OUT VARCHAR2
    );
    
PROCEDURE FETCH_PARAMETER_LIMITS
    (
    p_CRED			 IN MEX_CREDENTIALS,
    p_REQUEST_DATE  IN DATE,
    p_LOG_ONLY		 IN BINARY_INTEGER,
    p_RECORDS       OUT MEX_PJM_EMKT_PARAM_LIMIT_TBL,
    p_STATUS        OUT NUMBER,
    p_MESSAGE       OUT VARCHAR2,
    p_LOGGER		IN OUT mm_logger_adapter
    );                                               
END MEX_PJM_EMKT;
/