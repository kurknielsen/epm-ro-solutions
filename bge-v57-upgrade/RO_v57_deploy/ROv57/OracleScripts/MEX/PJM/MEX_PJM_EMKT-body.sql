CREATE OR REPLACE PACKAGE BODY MEX_PJM_EMKT IS

  G_PJM_EMKT_NAMESPACE      VARCHAR2(64) := 'xmlns="http://emkt.pjm.com/emkt/xml"';
  G_PJM_EMKT_NAMESPACE_NAME CONSTANT VARCHAR2(64) := 'http://emkt.pjm.com/emkt/xml';
  
  G_PJM_EMKT_MKT CONSTANT VARCHAR2(8) := 'pjmemkt';
  G_PJM_MKTGW_MKT CONSTANT VARCHAR2(20) := 'pjmmarketsgateway';
  g_PJM_TIME_ZONE CONSTANT VARCHAR2(3) := 'EDT';
  g_DST_SPRING_AHEAD_OPTION CONSTANT CHAR := 'B';

  ---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.2 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
  FUNCTION DUPLICATE_DATE(p_DATE IN DATE, p_ISDUPLICATE IN VARCHAR2)
    RETURN DATE IS
    v_CUT_DATE DATE;
  BEGIN
    v_CUT_DATE := p_DATE + CASE UPPER(p_ISDUPLICATE) WHEN 'TRUE' THEN 1/86400 ELSE 0 END;
    RETURN v_CUT_DATE;
  END DUPLICATE_DATE;
  ---------------------------------------------------------------------------------------------------
  FUNCTION GET_EXT_ID_FOR_RESOURCE_NAME(P_RESOURCE_NAME IN NUMBER)
    RETURN VARCHAR2 IS
    V_EXT_ID SERVICE_POINT.EXTERNAL_IDENTIFIER%TYPE;
  BEGIN
    SELECT S.EXTERNAL_IDENTIFIER
      INTO V_EXT_ID
      FROM SERVICE_POINT S, SUPPLY_RESOURCE R
     WHERE R.RESOURCE_NAME = P_RESOURCE_NAME
       AND R.SERVICE_POINT_ID = S.SERVICE_POINT_ID;

    RETURN V_EXT_ID;
  END GET_EXT_ID_FOR_RESOURCE_NAME;
  -----------------------------------------------------------------------
  FUNCTION GET_EXT_ID_FOR_TEMPLATE_NAME(P_TEMPLATE_NAME IN VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN SUBSTR(P_TEMPLATE_NAME, 1, INSTR(P_TEMPLATE_NAME, ' ', -1));
  END GET_EXT_ID_FOR_TEMPLATE_NAME;
  -----------------------------------------------------------------------
  FUNCTION GET_SCHEDULE_FOR_TEMPLATE_NAME(P_TEMPLATE_NAME IN VARCHAR2)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN SUBSTR(P_TEMPLATE_NAME, INSTR(P_TEMPLATE_NAME, ' ', -1));
  END GET_SCHEDULE_FOR_TEMPLATE_NAME;
  ----------------------------------------------------------------------------------------
  FUNCTION GET_DATE(p_DATE IN DATE)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN TO_CHAR(TRUNC(FROM_CUT(p_DATE,g_PJM_TIME_ZONE)-1/86400),'YYYY-MM-DD');
  END GET_DATE;
  ----------------------------------------------------------------------------------------
  FUNCTION GET_HOUR(p_DATE IN DATE)
    RETURN VARCHAR2 IS
v_HOUR VARCHAR2(2);   
BEGIN 
  v_HOUR := REPLACE(TO_CHAR(FROM_CUT(p_DATE,g_PJM_TIME_ZONE),'HH24'),'00','24');
	
	--During the Spring transition, at 2 AM, clocks are adjusted to read 3 AM. Technically, this takes
	-- place just before the clock strikes 2 AM. As a result, the hour-ending at 3 AM, called 03, never
	-- occurs and this hour-ending interval is skipped. The hour-ending intervals of the day during the
	-- spring transition day read like: 01, 02, 04, 05, etc
	IF TRUNC(p_DATE, 'DD') = TRUNC(DST_SPRING_AHEAD_DATE(p_DATE), 'DD') AND v_HOUR = '03' THEN
		RETURN '02';
	END IF;
	RETURN v_HOUR;
END GET_HOUR;
  ----------------------------------------------------------------------------------------
  FUNCTION GET_ISDUPLICATE(p_DATE IN DATE)
    RETURN VARCHAR2 IS
  BEGIN
    RETURN (CASE (TO_NUMBER(TO_CHAR(FROM_CUT(p_DATE,g_PJM_TIME_ZONE),'SS'))) WHEN 1 THEN 'true' ELSE 'false' END);
  END GET_ISDUPLICATE;
  ----------------------------------------------------------------------------------------
FUNCTION GETX_LOC_PORT_FRAG
	(
	p_LOCATION_TYPE IN VARCHAR2,
	p_LOCATION_NAME IN VARCHAR2
	)
  	RETURN XMLTYPE IS

	v_XML XMLTYPE;
	v_LOCATION_TYPE VARCHAR2(256);

BEGIN
	--IT IS NOT VALID TO QUERY "ALL" PORTFOLIOS OR LOCATIONS.  IT'S JUST "ALL".
	IF UPPER(p_LOCATION_NAME) = 'ALL' THEN
		v_LOCATION_TYPE := 'All';
	ELSE
		v_LOCATION_TYPE := p_LOCATION_TYPE;
	END IF;

	SELECT CASE v_LOCATION_TYPE
		WHEN g_LOC_TYPE_PORTFOLIO
			THEN XMLELEMENT("PortfolioName", p_LOCATION_NAME)
		WHEN g_LOC_TYPE_LOCATION
			THEN XMLELEMENT("LocationName", p_LOCATION_NAME)
		ELSE
			XMLELEMENT("All", NULL)
		END
	INTO v_XML
	FROM DUAL;

	RETURN v_XML;

END GETX_LOC_PORT_FRAG;
----------------------------------------------------------------------------------------
  PROCEDURE RUN_PJM_QUERY(P_CRED			  IN mex_credentials,
						  P_LOG_ONLY		  IN BINARY_INTEGER,
                          P_XML_REQUEST_BODY  IN XMLTYPE,
                          P_XML_RESPONSE_BODY OUT XMLTYPE,
						  P_STATUS			  OUT NUMBER,
                          P_ERROR_MESSAGE     OUT VARCHAR2,
						  P_LOGGER			  IN OUT mm_logger_adapter) AS
	v_TOKEN_ID VARCHAR2(1000);
  BEGIN
	
	IF INSTR(LOGS.CURRENT_PROCESS_NAME,':MktGW:') <> 0 THEN
		MEX_PJM.RUN_PJM_AUTHENTICATE(P_CRED => P_CRED,
									 P_LOG_ONLY => P_LOG_ONLY,
                                     P_LOGGER => P_LOGGER,
                                     P_TOKEN_ID => v_TOKEN_ID);
		MEX_PJM.RUN_PJM_ACTION(P_CRED,
				   'query',
				   P_LOG_ONLY,
                   P_XML_REQUEST_BODY,
				   G_PJM_EMKT_NAMESPACE,
				   G_PJM_MKTGW_MKT,
				   v_TOKEN_ID,
                   P_XML_RESPONSE_BODY,
				   P_STATUS,
                   P_ERROR_MESSAGE,
				   P_LOGGER);
	ELSE 
	MEX_PJM.RUN_PJM_ACTION(P_CRED,
				   'query',
				   P_LOG_ONLY,
                   P_XML_REQUEST_BODY,
				   G_PJM_EMKT_NAMESPACE,
				   G_PJM_EMKT_MKT,
                   P_XML_RESPONSE_BODY,
				   P_STATUS,
                   P_ERROR_MESSAGE,
				   P_LOGGER);
	END IF;
	
  EXCEPTION
    WHEN OTHERS THEN
      P_ERROR_MESSAGE := 'MEX_PJM_EMKT.RUN_PJM_QUERY: ' || SQLERRM;
	  P_STATUS		  := SQLCODE;
  END RUN_PJM_QUERY;
 -------------------------------------------------------------------------------------
  PROCEDURE RUN_PJM_QUERY_BY_TRANSACTION(P_CRED			  IN mex_credentials,
						  P_LOG_ONLY		  IN BINARY_INTEGER,
                          P_XML_REQUEST_BODY  IN XMLTYPE,
                          P_XML_RESPONSE_BODY OUT XMLTYPE,
						  P_STATUS			  OUT NUMBER,
                          P_ERROR_MESSAGE     OUT VARCHAR2,
						  P_LOGGER			  IN OUT mm_logger_adapter) AS
  BEGIN
    MEX_PJM.RUN_PJM_ACTION(P_CRED,
				   'querybytransaction',
				   P_LOG_ONLY,
                   P_XML_REQUEST_BODY,
				   G_PJM_EMKT_NAMESPACE,
				   G_PJM_EMKT_MKT,
                   P_XML_RESPONSE_BODY,
				   P_STATUS,
                   P_ERROR_MESSAGE,
				   P_LOGGER);
  EXCEPTION
    WHEN OTHERS THEN
      P_ERROR_MESSAGE := 'MEX_PJM_EMKT.RUN_PJM_QUERY_BY_TRANSACTION: ' || SQLERRM;
	  P_STATUS		  := SQLCODE;
  END RUN_PJM_QUERY_BY_TRANSACTION;
  -------------------------------------------------------------------------------------
  PROCEDURE RUN_PJM_SUBMIT(P_CRED			  IN mex_credentials,
						  P_LOG_ONLY		  IN BINARY_INTEGER,
                          P_XML_REQUEST_BODY  IN XMLTYPE,
                          P_XML_RESPONSE_BODY OUT XMLTYPE,
						  P_STATUS			  OUT NUMBER,
                          P_ERROR_MESSAGE     OUT VARCHAR2,
						  P_LOGGER			  IN OUT mm_logger_adapter) AS

    v_XML_REQUEST          XMLTYPE;
    v_XML_RESPONSE         XMLTYPE;
    v_PJM_TRANSACTION_CODE XMLTYPE;
	v_TOKEN_ID VARCHAR2(1000);
  BEGIN
	
    --Append the SubmitRequest tag.
    SELECT XMLELEMENT("SubmitRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      p_XML_REQUEST_BODY)
      INTO v_XML_REQUEST
      FROM DUAL;
	  
	IF INSTR(LOGS.CURRENT_PROCESS_NAME,':MktGW:') <> 0 THEN
		MEX_PJM.RUN_PJM_AUTHENTICATE(P_CRED => P_CRED,
									 P_LOG_ONLY => P_LOG_ONLY,
                                     P_LOGGER => P_LOGGER,
                                     P_TOKEN_ID => v_TOKEN_ID);

		MEX_PJM.RUN_PJM_ACTION(P_CRED,
						'submit',
						P_LOG_ONLY,
						v_XML_REQUEST,
						G_PJM_EMKT_NAMESPACE,
						G_PJM_MKTGW_MKT,
						v_TOKEN_ID,
						p_XML_RESPONSE_BODY,
						P_STATUS,
						p_ERROR_MESSAGE,
						P_LOGGER);
						
	ELSE
		MEX_PJM.RUN_PJM_ACTION(P_CRED,
						'submit',
						P_LOG_ONLY,
						v_XML_REQUEST,
						G_PJM_EMKT_NAMESPACE,
						G_PJM_EMKT_MKT,
						p_XML_RESPONSE_BODY,
						P_STATUS,
						p_ERROR_MESSAGE,
						P_LOGGER);
	END IF;

	--Log the transaction code.
	IF NOT v_XML_RESPONSE IS NULL THEN
		v_PJM_TRANSACTION_CODE := v_XML_RESPONSE.EXTRACT('/SubmitResponse/Success/TransactionID/text()', g_PJM_EMKT_NAMESPACE);

		IF NOT v_PJM_TRANSACTION_CODE IS NULL THEN
			p_LOGGER.LOG_EXCHANGE_IDENTIFIER(v_PJM_TRANSACTION_CODE.GETSTRINGVAL());
		END IF;
	END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_ERROR_MESSAGE := 'MEX_PJM_EMKT.RUN_PJM_SUBMIT: ' || SQLERRM;
	  P_STATUS		  := SQLCODE;
  END RUN_PJM_SUBMIT;
  -------------------------------------------------------------------------------------

  PROCEDURE PARSE_HOURLY_LMP(P_XML_RESPONSE IN XMLTYPE,
                             P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_HOURLY_LMP_TBL,
                             P_STATUS       OUT NUMBER,
                             P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(U), '/MarketPrices/@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "DAY",
             EXTRACTVALUE(VALUE(U), '/MarketPrices/@location', G_PJM_EMKT_NAMESPACE) "LOCATION_NAME",
             EXTRACTVALUE(VALUE(U), '/MarketPrices/@type', G_PJM_EMKT_NAMESPACE) "RESOURCE_TYPE",
             EXTRACTVALUE(VALUE(V), '/MarketPricesHourly/@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
             EXTRACTVALUE(VALUE(V), '/MarketPricesHourly/LMP', G_PJM_EMKT_NAMESPACE) "LMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//MarketPrices',
                                       G_PJM_EMKT_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),
                                       '//MarketPricesHourly',
                                       G_PJM_EMKT_NAMESPACE))) V;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_HOURLY_LMP(V_XML.DAY,
                                                           V_XML.LOCATION_NAME,
                                                           v_XML.RESOURCE_TYPE,
                                                           V_XML.HOUR,
                                                           V_XML.LMP);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_HOURLY_LMP: ' || SQLERRM;
  END PARSE_HOURLY_LMP;
  ---------------------------------------------------------------------------------------
	PROCEDURE GETX_QUERY_HOURLY_LMP(p_BEGIN_DATE	   IN DATE,
									p_END_DATE		   IN DATE,
									p_XML_REQUEST_BODY OUT XMLTYPE,
									p_STATUS           OUT NUMBER,
									p_MESSAGE          OUT VARCHAR2) AS

	BEGIN
		p_STATUS := MEX_UTIL.G_SUCCESS;

		SELECT XMLELEMENT("QueryRequest",
											XMLATTRIBUTES(g_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
											XMLAGG(XMLELEMENT("QueryMarketPrices",
																				XMLATTRIBUTES(TO_CHAR(T.LOCAL_DATE,
																															'YYYY-MM-DD') AS "day",
																											'Generation' AS "type"),
																				XMLELEMENT("All"))),
											XMLAGG(XMLELEMENT("QueryMarketPrices",
																				XMLATTRIBUTES(TO_CHAR(T.LOCAL_DATE,
																															'YYYY-MM-DD') AS "day",
																											'Demand' AS "type"),
																				XMLELEMENT("All")))
                                        )
			INTO p_XML_REQUEST_BODY
			FROM SYSTEM_DATE_TIME T
		 WHERE T.TIME_ZONE = 'EDT'
			 AND T.DATA_INTERVAL_TYPE = 1
			 AND T.DAY_TYPE = 1
			 AND T.LOCAL_DATE BETWEEN
					 TRUNC(p_BEGIN_DATE, 'DD') AND
					 TRUNC(p_END_DATE, 'DD')
			 AND T.LOCAL_DATE = TRUNC(T.LOCAL_DATE, 'DD')
		 ORDER BY T.LOCAL_DATE;

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_HOURLY_LMP: ' || SQLERRM;
	END GETX_QUERY_HOURLY_LMP;
  ---------------------------------------------------------------------------------------
  PROCEDURE FETCH_HOURLY_LMP(P_CRED			 IN mex_credentials,
							 P_LOG_ONLY		 IN BINARY_INTEGER,
							 P_BEGIN_DATE	 IN DATE,
  							 P_END_DATE		 IN DATE,
							 P_RECORDS       OUT MEX_PJM_EMKT_HOURLY_LMP_TBL,
                             P_STATUS        OUT NUMBER,
                             P_MESSAGE       OUT VARCHAR2,
							 P_LOGGER		 IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_HOURLY_LMP_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    -- SEND A REQUEST DATE?
    GETX_QUERY_HOURLY_LMP(P_BEGIN_DATE,
						  P_END_DATE,
                          V_XML_REQUEST,
                          P_STATUS,
                          P_MESSAGE);

    --SENDING THE XML REQUEST
    --FIX EXT_ID ETC. AND GET NAMESPACE, QUERY URL ETC. ONLY IN MEX
    --AND OUT OF MM.
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(P_CRED,
				    P_LOG_ONLY,
					V_XML_REQUEST,
					V_XML_RESPONSE,
					P_STATUS,
					P_MESSAGE,
					P_LOGGER);

      IF P_MESSAGE IS NULL THEN
        PARSE_HOURLY_LMP(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_HOURLY_LMP: ' || SQLERRM;
  END FETCH_HOURLY_LMP;
  ---------------------------------------------------------------------------------------
  PROCEDURE PARSE_DEMAND_SUMMARY(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_DEMAND_SUMM_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/DemandSummary/@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "DAY",
             EXTRACTVALUE(VALUE(U), '/DemandSummaryHourly/@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
             EXTRACTVALUE(VALUE(V), '/DemandSummarySet/ForecastMW', G_PJM_EMKT_NAMESPACE) "FORECAST_MW",
             EXTRACTVALUE(VALUE(V), '/DemandSummarySet/DemandBidMW', G_PJM_EMKT_NAMESPACE) "DEMAND_BID_MW",
             EXTRACTVALUE(VALUE(V), '/DemandSummarySet/ReserveMW', G_PJM_EMKT_NAMESPACE) "RESERVE_MW",
             EXTRACTVALUE(VALUE(V), '/DemandSummarySet/Area', G_PJM_EMKT_NAMESPACE) "AREA"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//DemandSummary',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//DemandSummaryHourly',
                                       G_PJM_EMKT_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),
                                       '//DemandSummarySet',
                                       G_PJM_EMKT_NAMESPACE))) V;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_DEMAND_SUMM(V_XML.DAY,
                                                            V_XML.HOUR,
                                                            V_XML.FORECAST_MW,
                                                            V_XML.DEMAND_BID_MW,
                                                            V_XML.RESERVE_MW,
                                                            V_XML.AREA);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_DEMAND_SUMMARY: ' ||
                   SQLERRM;
  END PARSE_DEMAND_SUMMARY;
  ---------------------------------------------------------------------------------------
	PROCEDURE GETX_QUERY_DEMAND_SUMMARY(P_BEGIN_DATE	IN DATE,
										P_END_DATE		IN DATE,
										P_XML_REQUEST_BODY OUT XMLTYPE,
										P_STATUS           OUT NUMBER,
										P_MESSAGE          OUT VARCHAR2) AS
		v_XML_DATES xmlsequencetype := xmlsequencetype();
		I           BINARY_INTEGER;
		v_DATE      DATE;
		v_END_DATE  DATE;
	BEGIN
		P_STATUS := MEX_UTIL.G_SUCCESS;

		v_DATE     := P_BEGIN_DATE;
		v_END_DATE := P_END_DATE;
		I          := 1;
		LOOP
			v_XML_DATES.EXTEND();
			SELECT XMLELEMENT("QueryDemandSummary",
												XMLATTRIBUTES(TO_CHAR(v_DATE, g_DATE_FORMAT) AS "day"))
				INTO v_XML_DATES(I)
				FROM DUAL;
			v_DATE := v_DATE + 1;
			I      := I + 1;
			EXIT WHEN v_DATE > v_END_DATE;
		END LOOP;

		SELECT XMLELEMENT("QueryRequest",
											XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
											XMLCONCAT(v_XML_DATES))
			INTO P_XML_REQUEST_BODY
			FROM DUAL;

	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_DEMAND_SUMMARY: ' || SQLERRM;
	END GETX_QUERY_DEMAND_SUMMARY;
  ------------------------------------------------------------------------------------------
  PROCEDURE FETCH_DEMAND_SUMMARY(P_CRED			 IN mex_credentials,
								 P_LOG_ONLY		 IN BINARY_INTEGER,
								 P_BEGIN_DATE	 IN DATE,
  								 P_END_DATE		 IN DATE,
                                 P_RECORDS       OUT MEX_PJM_EMKT_DEMAND_SUMM_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_DEMAND_SUMM_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_DEMAND_SUMMARY(P_BEGIN_DATE,
							  P_END_DATE,
                              V_XML_REQUEST,
                              P_STATUS,
                              P_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
	  RUN_PJM_QUERY(P_CRED,
				    P_LOG_ONLY,
					V_XML_REQUEST,
					V_XML_RESPONSE,
					P_STATUS,
					P_MESSAGE,
					P_LOGGER);

      IF P_MESSAGE IS NULL THEN
        PARSE_DEMAND_SUMMARY(V_XML_RESPONSE,
                             P_RECORDS,
                             P_STATUS,
                             P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_DEMAND_SUMMARY: ' ||
                   SQLERRM;
  END FETCH_DEMAND_SUMMARY;

  ---------------------------------------------------------------------------------------
PROCEDURE PARSE_PORTFOLIOS(P_XML_RESPONSE IN XMLTYPE,
													 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_PORTFOLIO_TBL,
													 P_STATUS       OUT NUMBER,
													 P_MESSAGE      OUT VARCHAR2) AS

	CURSOR C_XML IS
		SELECT EXTRACTVALUE(VALUE(U), '/Portfolio/@name', G_PJM_EMKT_NAMESPACE) "PORTFOLIO_NAME",
					 EXTRACTVALUE(VALUE(V), '/Location/@name', G_PJM_EMKT_NAMESPACE) "LOCATION_NAME",
					 EXTRACTVALUE(VALUE(V), '/Location/@type', G_PJM_EMKT_NAMESPACE) "LOCATION_TYPE"
			FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, '//Portfolios', G_PJM_EMKT_NAMESPACE))) T,
					 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//Portfolio', G_PJM_EMKT_NAMESPACE))) U,
					 TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//Location', G_PJM_EMKT_NAMESPACE))) V;

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	FOR V_XML IN C_XML LOOP
		P_RECORDS.EXTEND();
		P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_PORTFOLIO(V_XML.PORTFOLIO_NAME,
																												V_XML.LOCATION_NAME,
																												V_XML.LOCATION_TYPE);

	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		P_STATUS  := SQLCODE;
		P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_PORTFOLIOS: ' || SQLERRM;
END PARSE_PORTFOLIOS;
  ---------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_PORTFOLIOS(P_PORTFOLIO_NAME    IN VARCHAR2,
                                  P_XML_REQUEST_BODY OUT XMLTYPE,
                                  P_STATUS           OUT NUMBER,
                                  P_MESSAGE          OUT VARCHAR2) AS
    V_PORTFOLIO_NAME VARCHAR2(32);
    V_XML_FRAGMENT   XMLTYPE;
  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    IF P_PORTFOLIO_NAME IS NULL OR
       P_PORTFOLIO_NAME = 'All' THEN
      V_PORTFOLIO_NAME := 'All';
    ELSE
      V_PORTFOLIO_NAME := P_PORTFOLIO_NAME;
    END IF;

    IF V_PORTFOLIO_NAME = 'All' THEN
      SELECT XMLELEMENT("All") INTO V_XML_FRAGMENT FROM DUAL;
    ELSE
      SELECT XMLELEMENT("PortfolioName", V_PORTFOLIO_NAME)
        INTO V_XML_FRAGMENT
        FROM DUAL;
    END IF;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryPortfolios", V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_PORTFOLIOS: ' ||
                   SQLERRM;
  END GETX_QUERY_PORTFOLIOS;
  -------------------------------------------------------------------------------------
PROCEDURE GETX_QUERY_PARAM_LIMITS
    (    
    p_REQUEST_DATE  IN DATE,
    p_XML_REQUEST_BODY OUT XMLTYPE,
    p_STATUS           OUT NUMBER,
    p_MESSAGE          OUT VARCHAR2
    ) AS

v_XML_FRAGMENT  XMLTYPE;

BEGIN
    p_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(NULL, g_LOC_TYPE_ALL);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryUnitParameterLimit",
                                 XMLATTRIBUTES(p_REQUEST_DATE AS "day"),
                                 v_XML_FRAGMENT))
      INTO p_XML_REQUEST_BODY
      FROM DUAL;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_PARAM_LIMITS: ' || SQLERRM;
END GETX_QUERY_PARAM_LIMITS;
----------------------------------------------------------------------------  
  -- note that p_PARAMETER_MAP
	PROCEDURE FETCH_PORTFOLIOS(P_PORTFOLIO_NAME  IN VARCHAR2,
								 P_CRED			 IN mex_credentials,
								 P_LOG_ONLY		 IN BINARY_INTEGER,
                                 P_RECORDS       OUT MEX_PJM_EMKT_PORTFOLIO_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter) AS

		V_XML_REQUEST  XMLTYPE;
		V_XML_RESPONSE XMLTYPE;
	BEGIN
		P_RECORDS := MEX_PJM_EMKT_PORTFOLIO_TBL();
		P_STATUS  := MEX_UTIL.G_SUCCESS;

		---BUILD XML REQUEST
		GETX_QUERY_PORTFOLIOS(P_PORTFOLIO_NAME, V_XML_REQUEST, P_STATUS, P_MESSAGE);

		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		    RUN_PJM_QUERY(P_CRED,
						P_LOG_ONLY,
						V_XML_REQUEST,
						V_XML_RESPONSE,
						P_STATUS,
						P_MESSAGE,
						P_LOGGER);

			IF P_MESSAGE IS NULL THEN
				PARSE_PORTFOLIOS(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);
			END IF;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_PORTFOLIOS: ' || SQLERRM;
	END FETCH_PORTFOLIOS;
  ---------------------------------------------------------------------------------------
  PROCEDURE PARSE_MESSAGES(P_XML_RESPONSE IN XMLTYPE,
                           P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_MESSAGES_TBL,
                           P_STATUS       OUT NUMBER,
                           P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT EXTRACTVALUE(VALUE(U), '//@realm', G_PJM_EMKT_NAMESPACE) "MESSAGE_REALM",
             TO_DATE(EXTRACTVALUE(VALUE(U),
                                  '//EffectiveTime',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_TIME_FORMAT) "EFFECTIVE_TIME",
             TO_DATE(EXTRACTVALUE(VALUE(U),
                                  '//TerminationTime',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_TIME_FORMAT) "TERMINATION_TIME",
             EXTRACTVALUE(VALUE(U), '//Priority', G_PJM_EMKT_NAMESPACE) "MESSAGE_PRIORITY",
             EXTRACTVALUE(VALUE(U), '//Text', G_PJM_EMKT_NAMESPACE) "MESSAGE_TEXT"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//MessageSet',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//Message',
                                       G_PJM_EMKT_NAMESPACE))) U;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_MESSAGES(V_XML.MESSAGE_REALM,
                                                         V_XML.EFFECTIVE_TIME,
                                                         V_XML.TERMINATION_TIME,
                                                         V_XML.MESSAGE_PRIORITY,
                                                         V_XML.MESSAGE_TEXT);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_MESSAGES: ' || SQLERRM;
  END PARSE_MESSAGES;
  ---------------------------------------------------------------------------------------
	PROCEDURE GETX_QUERY_MESSAGES(P_XML_REQUEST_BODY OUT XMLTYPE,
																P_STATUS           OUT NUMBER,
																P_MESSAGE          OUT VARCHAR2) AS
	BEGIN
		P_STATUS := MEX_UTIL.G_SUCCESS;

		SELECT XMLELEMENT("QueryRequest",
											XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
											XMLELEMENT("QueryMessages"))
			INTO P_XML_REQUEST_BODY
			FROM DUAL;

	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_MESSAGES: ' || SQLERRM;
	END GETX_QUERY_MESSAGES;
  ------------------------------------------------------------------------------------------------
PROCEDURE PARSE_PARAMETER_LIMITS
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_PARAM_LIMIT_TBL,
    p_STATUS       OUT NUMBER,
    p_MESSAGE      OUT VARCHAR2
    ) AS
v_LIMIT_DESC VARCHAR2(256);    

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(LIMITSET),
                                  '//@day',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "DAY",
            EXTRACTVALUE(VALUE(LIMITS), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",                  
            EXTRACTVALUE(VALUE(LIMITS), '//MinimumRuntimeLimit', G_PJM_EMKT_NAMESPACE) "MIN_RUNTIME",
            EXTRACTVALUE(VALUE(LIMITS), '//MinimumDowntimeLimit', G_PJM_EMKT_NAMESPACE) "MIN_DOWNTIME",
            EXTRACTVALUE(VALUE(LIMITS), '//MaximumDailyStartsLimit', G_PJM_EMKT_NAMESPACE) "DAILY_STARTS",
            EXTRACTVALUE(VALUE(LIMITS), '//MaximumWeeklyStartsLimit', G_PJM_EMKT_NAMESPACE) "WEEKLY_STARTS",  
            EXTRACTVALUE(VALUE(LIMITS), '//TurnDownRatioLimit', G_PJM_EMKT_NAMESPACE) "TURNDOWN",           
            EXTRACTVALUE(VALUE(LIMITS), '//LimitDescription', G_PJM_EMKT_NAMESPACE) "LIMIT_DESC"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,'//UnitParameterLimitSet',
                                       G_PJM_EMKT_NAMESPACE))) LIMITSET,
            TABLE(XMLSEQUENCE(EXTRACT(VALUE(LIMITSET),
                                       '//UnitParameterLimits',
                                       G_PJM_EMKT_NAMESPACE))) LIMITS;

BEGIN  
    p_STATUS  := MEX_UTIL.G_SUCCESS;
 
    FOR v_XML IN c_XML LOOP
        --Limit Description can have a new line, get rid of it
        IF INSTR(v_XML.LIMIT_DESC, CHR(10)) > 0 THEN
            v_LIMIT_DESC := REPLACE(v_XML.LIMIT_DESC, CHR(10), ' ');
            --Limit Description can have excess white space, get rid of it
            WHILE INSTR(v_LIMIT_DESC,'  ') > 0 LOOP
                v_LIMIT_DESC := REPLACE(v_LIMIT_DESC, '  ', ' ');
            END LOOP;
        ELSE
            v_LIMIT_DESC := v_XML.LIMIT_DESC;
        END IF;                            
    
      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_EMKT_PARAM_LIMIT(v_XML.DAY,
                                                             v_XML.LOCATION,
                                                             v_XML.MIN_RUNTIME,
                                                             v_XML.MIN_DOWNTIME,
                                                             v_XML.DAILY_STARTS,
                                                             v_XML.WEEKLY_STARTS,
                                                             v_XML.TURNDOWN,
                                                             v_LIMIT_DESC);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_PARAMETER_LIMITS: ' ||
                   SQLERRM;
END PARSE_PARAMETER_LIMITS;
-------------------------------------------------------------------------------------------------  
PROCEDURE FETCH_PARAMETER_LIMITS
    (
    p_CRED			 IN MEX_CREDENTIALS,
    p_REQUEST_DATE  IN DATE,
    p_LOG_ONLY		 IN BINARY_INTEGER,
    p_RECORDS       OUT MEX_PJM_EMKT_PARAM_LIMIT_TBL,
    p_STATUS        OUT NUMBER,
    p_MESSAGE       OUT VARCHAR2,
    p_LOGGER		IN OUT mm_logger_adapter
    ) AS

v_XML_REQUEST  XMLTYPE;
v_XML_RESPONSE XMLTYPE;
BEGIN

    p_RECORDS := MEX_PJM_EMKT_PARAM_LIMIT_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_PARAM_LIMITS(p_REQUEST_DATE,
                        v_XML_REQUEST,
                        p_STATUS,
                        p_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		RUN_PJM_QUERY(p_CRED,
					p_LOG_ONLY,
					v_XML_REQUEST,
					v_XML_RESPONSE,
					p_STATUS,
					p_MESSAGE,
					p_LOGGER);


        IF P_MESSAGE IS NULL THEN
            PARSE_PARAMETER_LIMITS(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_PARAMETER_LIMITS: ' || SQLERRM;
END FETCH_PARAMETER_LIMITS;
---------------------------------------------------------------------------------------

  PROCEDURE FETCH_MESSAGES(P_CRED			 IN mex_credentials,
								 P_LOG_ONLY		 IN BINARY_INTEGER,
                                 P_RECORDS       OUT MEX_PJM_EMKT_MESSAGES_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_MESSAGES_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_MESSAGES(V_XML_REQUEST,
                        P_STATUS,
                        P_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		RUN_PJM_QUERY(P_CRED,
					P_LOG_ONLY,
					V_XML_REQUEST,
					V_XML_RESPONSE,
					P_STATUS,
					P_MESSAGE,
					P_LOGGER);


      IF P_MESSAGE IS NULL THEN
        PARSE_MESSAGES(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_MESSAGES: ' || SQLERRM;
  END FETCH_MESSAGES;

  ---------------------------------------------------------------------------------------
  PROCEDURE PARSE_MARKET_RESULTS(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_MKT_RESULTS_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/MarketResults/@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DAY",
             EXTRACTVALUE(VALUE(T), '/MarketResults/@type', G_PJM_EMKT_NAMESPACE) "RESOURCE_TYPE",
             EXTRACTVALUE(VALUE(T), '/MarketResults/@location', G_PJM_EMKT_NAMESPACE) "LOCATION_NAME",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/@hour', G_PJM_EMKT_NAMESPACE) "RESPONSE_HOUR",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/@isDuplicateHour', G_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/ClearedMW', G_PJM_EMKT_NAMESPACE) "AMOUNT",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/ClearedIncMW', G_PJM_EMKT_NAMESPACE) "INC_AMOUNT",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/ClearedDecMW', G_PJM_EMKT_NAMESPACE) "DEC_AMOUNT",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/ClearedPrice', G_PJM_EMKT_NAMESPACE) "PRICE",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/PriceCapped', G_PJM_EMKT_NAMESPACE) "PRICE_CAPPED",
             EXTRACTVALUE(VALUE(V), '/MarketResultsHourly/Schedule', G_PJM_EMKT_NAMESPACE) "SCHEDULE_ID"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//MarketResults',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//MarketResultsHourly',
                                       G_PJM_EMKT_NAMESPACE))) V;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_MKT_RESULTS(TO_CUT_WITH_OPTIONS(DUPLICATE_DATE(V_XML.RESPONSE_DAY + TO_NUMBER(V_XML.RESPONSE_HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION),
                                                           V_XML.LOCATION_NAME,
                                                           0,
                                                           v_XML.RESOURCE_TYPE,
                                                           TO_NUMBER(V_XML.AMOUNT),
                                                           TO_NUMBER(V_XML.INC_AMOUNT),
                                                           TO_NUMBER(V_XML.DEC_AMOUNT),
                                                           TO_NUMBER(V_XML.PRICE),
														   CASE UPPER(V_XML.PRICE_CAPPED) WHEN 'TRUE' THEN 1 ELSE 0 END,
                                                           V_XML.SCHEDULE_ID);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_MARKET_RESULTS: ' ||
                   SQLERRM;
  END PARSE_MARKET_RESULTS;
  ---------------------------------------------------------------------------------------
	PROCEDURE PARSE_NODE_LIST(P_XML_RESPONSE IN XMLTYPE,
														P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_NODE_TBL,
														p_IS_BID_NODES IN BOOLEAN,
														P_STATUS       OUT NUMBER,
														P_MESSAGE      OUT VARCHAR2) AS

		v_NODES VARCHAR2(32);
		v_NODE  VARCHAR2(32);

		CURSOR C_XML IS
			SELECT EXTRACTVALUE(VALUE(U), '//NodeName', G_PJM_EMKT_NAMESPACE) "NODENAME",
						 EXTRACTVALUE(VALUE(U), '//NodeType', G_PJM_EMKT_NAMESPACE) "NODETYPE",
						 EXTRACTVALUE(VALUE(U), '//PnodeID', G_PJM_EMKT_NAMESPACE) "PNODEID",
						 EXTRACTVALUE(VALUE(U), '//CanSubmitFixed', G_PJM_EMKT_NAMESPACE) "CANSUBMITFIXED",
						 EXTRACTVALUE(VALUE(U), '//CanSubmitPriceSensitive', G_PJM_EMKT_NAMESPACE) "CANSUBMITPRICESENSITIVE",
						 EXTRACTVALUE(VALUE(U), '//CanSubmitIncrement', G_PJM_EMKT_NAMESPACE) "CANSUBMITINCREMENT",
						 EXTRACTVALUE(VALUE(U), '//CanSubmitDecrement', G_PJM_EMKT_NAMESPACE) "CANSUBMITDECREMENT"
				FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, v_NODES, G_PJM_EMKT_NAMESPACE))) T,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), v_NODE, G_PJM_EMKT_NAMESPACE))) U;

	BEGIN
		p_STATUS := MEX_UTIL.g_SUCCESS;

		IF p_IS_BID_NODES = TRUE THEN
			v_NODES := '//BidNodes';
			v_NODE  := '//BidNode';
		ELSE
			v_NODES := '//NodeList';
			v_NODE  := '//Node';
		END IF;

		FOR V_XML IN C_XML LOOP
			P_RECORDS.EXTEND();
			P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_NODE(V_XML.NODENAME,
																										 V_XML.NODETYPE,
																										 V_XML.PNODEID,
																									   CASE V_XML.CANSUBMITFIXED WHEN 'true' THEN 1 ELSE 0 END,
																										 CASE V_XML.CANSUBMITPRICESENSITIVE WHEN 'true' THEN 1 ELSE 0 END,
																										 CASE V_XML.CANSUBMITINCREMENT WHEN 'true' THEN 1 ELSE 0 END,
																										 CASE V_XML.CANSUBMITDECREMENT WHEN 'true' THEN 1 ELSE 0 END);
		END LOOP;

	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_NODE_LIST: ' || SQLERRM;
	END PARSE_NODE_LIST;
  ---------------------------------------------------------------------------------------
	PROCEDURE GETX_QUERY_NODE_LIST(P_NODE_TYPE		IN VARCHAR2,
								   P_BEGIN_DATE		IN DATE,
								   P_END_DATE		IN DATE,
								   P_XML_REQUEST_BODY OUT XMLTYPE,
								   P_STATUS           OUT NUMBER,
								   P_MESSAGE          OUT VARCHAR2) AS
		v_XML_DATES xmlsequencetype := xmlsequencetype();
		I           BINARY_INTEGER;
		v_DATE      DATE;
		v_END_DATE  DATE;
	BEGIN
		P_STATUS := MEX_UTIL.G_SUCCESS;

		-- note that bid nodes only doesn't need a date
		IF P_NODE_TYPE = 'BidNodes' THEN
			SELECT XMLELEMENT("QueryRequest",
												XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
												XMLELEMENT("QueryBidNodes"))
				INTO P_XML_REQUEST_BODY
				FROM DUAL;
		ELSE
			v_DATE     := P_BEGIN_DATE;
			v_END_DATE := P_END_DATE;
			I          := 1;
			LOOP
				v_XML_DATES.EXTEND();
				SELECT XMLELEMENT("QueryNodeList",
													XMLATTRIBUTES(TO_CHAR(v_DATE, g_DATE_FORMAT) AS "day"))
					INTO v_XML_DATES(I)
					FROM DUAL;
				v_DATE := v_DATE + 1;
				I      := I + 1;
				EXIT WHEN v_DATE > v_END_DATE;
			END LOOP;

			SELECT XMLELEMENT("QueryRequest",
												XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
												XMLCONCAT(v_XML_DATES))
				INTO P_XML_REQUEST_BODY
				FROM DUAL;
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_NODE_LIST: ' || SQLERRM;
	END GETX_QUERY_NODE_LIST;
  ------------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_NODE_LIST(P_CRED			IN mex_credentials,
  							P_LOG_ONLY		IN BINARY_INTEGER,
							P_NODE_TYPE		IN VARCHAR2,
							P_BEGIN_DATE	iN DATE,
							P_END_DATE		IN DATE,
  							P_RECORDS       OUT MEX_PJM_EMKT_NODE_TBL,
							P_STATUS        OUT NUMBER,
							P_MESSAGE       OUT VARCHAR2,
							P_LOGGER		IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
    v_IS_BID_NODES BOOLEAN;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_NODE_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;


    ---BUILD XML REQUEST
    -- SEND A REQUEST DATE?
    GETX_QUERY_NODE_LIST(P_NODE_TYPE,
						 P_BEGIN_DATE,
						 P_END_DATE,
                         V_XML_REQUEST,
                         P_STATUS,
                         P_MESSAGE);


    --SENDING THE XML REQUEST
    --FIX EXT_ID ETC. AND GET NAMESPACE, QUERY URL ETC. ONLY IN MEX
    --AND OUT OF MM.
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IF P_NODE_TYPE = 'BidNodes' THEN
        v_IS_BID_NODES := TRUE;
      ELSE
        v_IS_BID_NODES := FALSE;
      END IF;
      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

      IF P_MESSAGE IS NULL THEN
        PARSE_NODE_LIST(V_XML_RESPONSE, P_RECORDS, v_IS_BID_NODES, P_STATUS, P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_NODE_LIST: ' || SQLERRM;
  END FETCH_NODE_LIST;
  ----------------------------------------------------------------------------------------
  PROCEDURE PARSE_DISTRIBUTION(P_XML_RESPONSE IN XMLTYPE,
                               P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_DISTRIBUTION_TBL,
                               P_STATUS       OUT NUMBER,
                               P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(U), '//@location', G_PJM_EMKT_NAMESPACE) "AGGREGATE_LOCATION",
             EXTRACTVALUE(VALUE(V), '//@location', G_PJM_EMKT_NAMESPACE) "BUS_LOCATION",
             EXTRACTVALUE(VALUE(V), '//@factor', G_PJM_EMKT_NAMESPACE) "FACTOR"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//DistributionFactors',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//AggregateNode',
                                       G_PJM_EMKT_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),
                                       '//BusNode',
                                       G_PJM_EMKT_NAMESPACE))) V;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_DISTRIBUTION(V_XML.RESPONSE_DATE,
                                                             V_XML.AGGREGATE_LOCATION,
                                                             V_XML.BUS_LOCATION,
                                                             V_XML.FACTOR);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_DISTRIBUTION: ' || SQLERRM;
  END PARSE_DISTRIBUTION;
  ---------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPIN_RESERVE_RES(P_XML_RESPONSE IN XMLTYPE,
                                   P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RSV_RES_TBL,
                                   P_STATUS       OUT NUMBER,
                                   P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(RESULTS),
                                  '//@day',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(RESULTS_HOURLY),
                          '//@hour',
                          G_PJM_EMKT_NAMESPACE) "RESPONSE_HOUR",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//SPMCP',
                          G_PJM_EMKT_NAMESPACE) "MCP",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//RequiredMW',
                          G_PJM_EMKT_NAMESPACE) "REQUIRED_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//Tier1MW',
                          G_PJM_EMKT_NAMESPACE) "TIER_ONE_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//Tier2MW',
                          G_PJM_EMKT_NAMESPACE) "TIER_TWO_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//SelfScheduledMW',
                          G_PJM_EMKT_NAMESPACE) "SELF_SCHEDULED_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//Tier2AssignedMW',
                          G_PJM_EMKT_NAMESPACE) "TIER_TWO_ASSIGNED_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//TotalMW',
                          G_PJM_EMKT_NAMESPACE) "TOTAL_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//DeficiencyMW',
                          G_PJM_EMKT_NAMESPACE) "DEFICIENCY_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//AreaName',
                          G_PJM_EMKT_NAMESPACE) "AREA_NAME"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//SpinReserveResults',
                                       G_PJM_EMKT_NAMESPACE))) RESULTS,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(RESULTS),
                                       '//SpinReserveResultsHourly',
                                       G_PJM_EMKT_NAMESPACE))) RESULTS_HOURLY,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(RESULTS_HOURLY),
                                       '//SpinReserveResultsByArea',
                                       G_PJM_EMKT_NAMESPACE))) RESULTS_AREA;

  BEGIN
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SPIN_RSV_RES(V_XML.RESPONSE_DATE,
                                                             V_XML.RESPONSE_HOUR,
                                                             V_XML.MCP,
                                                             V_XML.REQUIRED_MW,
                                                             V_XML.TIER_ONE_MW,
                                                             V_XML.TIER_TWO_MW,
                                                             V_XML.SELF_SCHEDULED_MW,
                                                             V_XML.TIER_TWO_ASSIGNED_MW,
                                                             V_XML.TOTAL_MW,
                                                             V_XML.DEFICIENCY_MW,
                                                             V_XML.AREA_NAME);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SPIN_RESERVE_RES: ' ||
                   SQLERRM;
  END PARSE_SPIN_RESERVE_RES;
  ---------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPIN_RESERVE_BIL(P_XML_RESPONSE IN XMLTYPE,
                                   P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RSV_BIL_TBL,
                                   P_STATUS       OUT NUMBER,
                                   P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(BILATERALS),
                                  '//@day',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "DAY",
             EXTRACTVALUE(VALUE(SCHEDULE), '//@Buyer', G_PJM_EMKT_NAMESPACE) "BUYER",
             EXTRACTVALUE(VALUE(SCHEDULE),
                          '//@Seller',
                          G_PJM_EMKT_NAMESPACE) "SELLER",
             EXTRACTVALUE(VALUE(SCHEDULE), '//MW', G_PJM_EMKT_NAMESPACE) "MW",
             EXTRACTVALUE(VALUE(SCHEDULE),
                          '//StartTime',
                          G_PJM_EMKT_NAMESPACE) "START_DATE",
             EXTRACTVALUE(VALUE(SCHEDULE),
                          '//StopTime',
                          G_PJM_EMKT_NAMESPACE) "END_DATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//SpinReserveBilaterals',
                                       G_PJM_EMKT_NAMESPACE))) BILATERALS,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(BILATERALS),
                                       '//SpinBilateralSchedule',
                                       G_PJM_EMKT_NAMESPACE))) SCHEDULE;

  BEGIN
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SPIN_RSV_BIL(V_XML.DAY,
                                                             V_XML.SELLER,
                                                             V_XML.BUYER,
                                                             V_XML.MW,
                                                             V_XML.START_DATE,
                                                             V_XML.END_DATE);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SPIN_RESERVE_BIL: ' ||
                   SQLERRM;
  END PARSE_SPIN_RESERVE_BIL;
  ---------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPREG_AWARD(P_XML_RESPONSE IN XMLTYPE,
                                     P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RES_AWAR_TBL,
                                     P_STATUS       OUT NUMBER,
                                     P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(AWARD),
                                  '//@day',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(AWARD), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//@hour',
                          G_PJM_EMKT_NAMESPACE) "RESPONSE_HOUR",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//SpinOfferMW',
                          G_PJM_EMKT_NAMESPACE) "SPIN_OFFER",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//RegOfferMW',
                          G_PJM_EMKT_NAMESPACE) "REG_OFFER",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//Tier1MW',
                          G_PJM_EMKT_NAMESPACE) "TIER_ONE_MW",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//Tier2MW',
                          G_PJM_EMKT_NAMESPACE) "TIER_TWO_MW",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//SelfScheduledMW',
                          G_PJM_EMKT_NAMESPACE) "SELF_SCHEDULED_MW",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//RegAwardedMW',
                          G_PJM_EMKT_NAMESPACE) "REG_AWARD"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//SPREGAward',
                                       G_PJM_EMKT_NAMESPACE))) AWARD,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(AWARD),
                                       '//SPREGAwardHourly',
                                       G_PJM_EMKT_NAMESPACE))) AWARD_HOURLY;

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SPIN_RES_AWARD(v_XML.RESPONSE_DATE,
                                                               v_XML.LOCATION,
                                                               v_XML.RESPONSE_HOUR,
                                                               v_XML.SPIN_OFFER,
                                                               v_XML.REG_OFFER,
                                                               v_XML.TIER_ONE_MW,
                                                               v_XML.TIER_TWO_MW,
                                                               v_XML.SELF_SCHEDULED_MW,
                                                               v_XML.REG_AWARD);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SPREG_AWARD: ' ||
                   SQLERRM;
  END PARSE_SPREG_AWARD;
  ---------------------------------------------------------------------------------------
  PROCEDURE PARSE_SPIN_RESERVE_UPDATE(P_XML_RESPONSE IN XMLTYPE,
                                      P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RES_UPD_TBL,
                                      P_STATUS       OUT NUMBER,
                                      P_MESSAGE      OUT VARCHAR2) AS

	CURSOR C_XML IS
		SELECT TO_DATE(EXTRACTVALUE(VALUE(SPIN_RES_UPDATE), '//@day', G_PJM_EMKT_NAMESPACE),
				G_DATE_FORMAT) "RESPONSE_DATE",
			EXTRACTVALUE(VALUE(SPIN_RES_UPDATE), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//@isDuplicateHour', G_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE),'//OfferMW', G_PJM_EMKT_NAMESPACE) "QUANTITY",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE),'//SpinMAX', G_PJM_EMKT_NAMESPACE) "SPIN_MAX_MW",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE),'//Unavailable',G_PJM_EMKT_NAMESPACE) "UNAVAILABLE",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE),'//SelfScheduledMW', G_PJM_EMKT_NAMESPACE) "SELF_SCHEDULED_MW"
		FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,'//SpinningReserveUpdate', G_PJM_EMKT_NAMESPACE))) SPIN_RES_UPDATE,
			TABLE(XMLSEQUENCE(EXTRACT(VALUE(SPIN_RES_UPDATE), '//SpinningReserveUpdateHourly', G_PJM_EMKT_NAMESPACE))) HOURLY_UPDATE;

  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SPIN_RES_UPD(TO_CUT_WITH_OPTIONS(DUPLICATE_DATE(V_XML.RESPONSE_DATE + TO_NUMBER(V_XML.HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION),
                                                             V_XML.LOCATION,
                                                             TO_NUMBER(V_XML.QUANTITY),
                                                             TO_NUMBER(V_XML.SPIN_MAX_MW),
                                                             V_XML.UNAVAILABLE,
                                                             TO_NUMBER(V_XML.SELF_SCHEDULED_MW));
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SPIN_RESERVE_UPDATE: ' || SQLERRM;
  END PARSE_SPIN_RESERVE_UPDATE;
  ---------------------------------------------------------------------------------------
PROCEDURE PARSE_SPIN_RESERVE_OFFER(p_XML_RESPONSE IN XMLTYPE,
                                     p_RECORDS IN OUT NOCOPY MEX_PJM_EMKT_SPIN_RES_OFF_TBL,
                                     p_STATUS OUT NUMBER,
                                     p_MESSAGE OUT VARCHAR2) AS

CURSOR C_XML IS
	SELECT TO_DATE(EXTRACTVALUE(VALUE(SPIN_RES_OFFER),
		    '//@day', G_PJM_EMKT_NAMESPACE), G_DATE_FORMAT) "RESPONSE_DATE",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//OfferMW', G_PJM_EMKT_NAMESPACE) "QUANTITY",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//OfferPrice', G_PJM_EMKT_NAMESPACE) "PRICE",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//CondenseAvailable', G_PJM_EMKT_NAMESPACE) "CONDENSE_AVAILABLE",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//CondenseStartupCost', G_PJM_EMKT_NAMESPACE) "COND_STARTUP_COST",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//CondenseEnergyUsage', G_PJM_EMKT_NAMESPACE) "COND_ENERGY_USAGE",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//CondenseToGenCost', G_PJM_EMKT_NAMESPACE) "COND_TO_GEN_COST",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//SpinAsCondenser', G_PJM_EMKT_NAMESPACE) "SPIN_AS_CONDENSER",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//FullLoadHeatRate', G_PJM_EMKT_NAMESPACE) "FULL_LOAD_HR",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//ReducedLoadHeatRate', G_PJM_EMKT_NAMESPACE) "REDUCED_LOAD_HR",
		EXTRACTVALUE(VALUE(SPIN_RES_OFFER), '//VOMRate', G_PJM_EMKT_NAMESPACE) "VOM_RATE"
	FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, '//SpinningReserveOffer', G_PJM_EMKT_NAMESPACE))) SPIN_RES_OFFER;

BEGIN
	p_STATUS  := MEX_UTIL.G_SUCCESS;
	FOR v_XML IN c_XML LOOP
		p_RECORDS.EXTEND();
		p_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SPIN_RES_OFF(v_XML.RESPONSE_DATE,
			v_XML.LOCATION,
			TO_NUMBER(v_XML.QUANTITY),
			TO_NUMBER(v_XML.PRICE),
			v_XML.CONDENSE_AVAILABLE,
			v_XML.COND_STARTUP_COST,
			v_XML.COND_ENERGY_USAGE,
			v_XML.COND_TO_GEN_COST,
			v_XML.SPIN_AS_CONDENSER,
			v_XML.FULL_LOAD_HR,
			v_XML.REDUCED_LOAD_HR,
			v_XML.VOM_RATE);
	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		P_STATUS  := SQLCODE;
		P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SPIN_RESERVE_OFFER: ' || SQLERRM;
END PARSE_SPIN_RESERVE_OFFER;
---------------------------------------------------------------------------------------
PROCEDURE PARSE_ANCILLARY_SERV(p_XML_RESPONSE IN XMLTYPE,
                                 p_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_ANCILLAR_SERV_TBL,
                                 p_STATUS       OUT NUMBER,
                                 p_MESSAGE      OUT VARCHAR2) AS

    CURSOR c_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', G_PJM_EMKT_NAMESPACE), g_DATE_FORMAT) "DAY",
             EXTRACTVALUE(VALUE(U), '//@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
             EXTRACTVALUE(VALUE(V), '//SPMCP', G_PJM_EMKT_NAMESPACE) "SPMCP",
             EXTRACTVALUE(VALUE(V), '//RMCP', G_PJM_EMKT_NAMESPACE) "RMCP",
             EXTRACTVALUE(VALUE(V), '//Area', G_PJM_EMKT_NAMESPACE) "AREA",
             EXTRACTVALUE(VALUE(V), '//ReserveZone', G_PJM_EMKT_NAMESPACE) "RESERVE_ZONE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//ASMarketPrices',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//ASMarketPricesHourly',
                                       G_PJM_EMKT_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),
                                       '//ASMarketPrice',
                                       G_PJM_EMKT_NAMESPACE))) V;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    FOR v_XML IN C_XML LOOP
      p_RECORDS.EXTEND();
      p_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_ANCILLAR_SERV(v_XML.DAY,
                                                              TO_NUMBER(v_XML.HOUR),
                                                              TO_NUMBER(v_XML.SPMCP),
                                                              TO_NUMBER(v_XML.RMCP),
                                                              v_XML.AREA,
                                                              v_XML.RESERVE_ZONE);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_ANCILLARY_SERV: ' ||
                   SQLERRM;
END PARSE_ANCILLARY_SERV;
---------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_DISTRIBUTION(P_LOCATION_TYPE IN VARCHAR2,
									P_LOCATION_NAME IN VARCHAR2,
									P_REQUEST_DATE  IN DATE,
                                    P_XML_REQUEST_BODY OUT XMLTYPE,
                                    P_STATUS           OUT NUMBER,
                                    P_MESSAGE          OUT VARCHAR2) AS
    V_XML_FRAGMENT  XMLTYPE;

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

    ---RequestDate as parameter???
    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryDistributionFactors",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS
                                               "day"),
                                 V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_DISTRIBUTION: ' ||
                   SQLERRM;
  END GETX_QUERY_DISTRIBUTION;
  ---------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SPIN_RESERVE_RES(P_REQUEST_DATE     IN  DATE,
                                        P_XML_REQUEST_BODY OUT XMLTYPE,
                                        P_STATUS           OUT NUMBER,
                                        P_MESSAGE          OUT VARCHAR2) AS

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QuerySpinReserveResults",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS
                                               "day")))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SPIN_RESERVE_RES: ' ||
                   SQLERRM;
  END GETX_QUERY_SPIN_RESERVE_RES;
  ---------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SPIN_RESERVE_BIL(P_REQUEST_DATE     IN  DATE,
                                        P_XML_REQUEST_BODY OUT XMLTYPE,
                                        P_STATUS           OUT NUMBER,
                                        P_MESSAGE          OUT VARCHAR2) AS

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QuerySpinReserveBilaterals",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS
                                               "day")))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SPIN_RESERVE_BIL: ' ||
                   SQLERRM;
  END GETX_QUERY_SPIN_RESERVE_BIL;
  ---------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_ANCILLARY_SERV(P_REQUEST_DATE	 IN  DATE,
                                      P_XML_REQUEST_BODY OUT XMLTYPE,
                                      P_STATUS           OUT NUMBER,
                                      P_MESSAGE          OUT VARCHAR2) AS

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryASMarketPrices",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS
                                               "day")))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_ANCILLARY_SERV: ' ||
                   SQLERRM;
  END GETX_QUERY_ANCILLARY_SERV;
  ------------------------------------------------------------------------------------------
 PROCEDURE GETX_QUERY_MARKET_RESULTS
 	(
	p_REQUEST_DATE 		IN DATE,
	p_EMKT_GEN			IN NUMBER := 0,
	p_EMKT_LOAD			IN NUMBER := 0,
	p_GEN_LOCATION_TYPE IN VARCHAR2,
	p_GEN_LOCATION_NAME IN VARCHAR2,
	p_LOAD_LOCATION_TYPE IN VARCHAR2,
	p_LOAD_LOCATION_NAME IN VARCHAR2,
	p_XML_REQUEST_BODY OUT XMLTYPE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_GEN_XML_FRAGMENT  XMLTYPE;
	v_LOAD_XML_FRAGMENT XMLTYPE;
	v_VIRTUAL_XML_FRAGMENT XMLTYPE;
 BEGIN
	 P_STATUS := MEX_UTIL.G_SUCCESS;

	v_GEN_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_GEN_LOCATION_TYPE, p_GEN_LOCATION_NAME);
	v_LOAD_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOAD_LOCATION_TYPE, p_LOAD_LOCATION_NAME);
	v_VIRTUAL_XML_FRAGMENT := GETX_LOC_PORT_FRAG('ALL','ALL');

	SELECT XMLELEMENT("QueryRequest",
		XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
		--Query All Virtuals All the Time
		XMLELEMENT("QueryMarketResults",
			XMLATTRIBUTES('Virtual' AS "type", TO_CHAR(p_REQUEST_DATE, g_DATE_FORMAT) AS "day"),
			v_VIRTUAL_XML_FRAGMENT),
		--Query Generation if the Parameter Map tells us to, for the specified Gen Location or Portfolio.
		CASE p_EMKT_GEN WHEN 1 THEN
			XMLELEMENT("QueryMarketResults",
				XMLATTRIBUTES('Generation' AS "type", TO_CHAR(p_REQUEST_DATE, g_DATE_FORMAT) AS "day"),
				v_GEN_XML_FRAGMENT)
		ELSE NULL END,
		--Query Demand if the Parameter Map tells us to, for the specified Load Location or Portfolio.
		CASE p_EMKT_LOAD WHEN 1 THEN
			XMLELEMENT("QueryMarketResults",
				XMLATTRIBUTES('Demand' AS "type", TO_CHAR(p_REQUEST_DATE, g_DATE_FORMAT) AS "day"),
				v_LOAD_XML_FRAGMENT)
		ELSE NULL END,
		--Query Load Response if the Parameter Map tells us to, for the specified Load Location or Portfolio.
		CASE p_EMKT_LOAD WHEN 1 THEN
			XMLELEMENT("QueryMarketResults",
				XMLATTRIBUTES('LoadResponse' AS "type", TO_CHAR(p_REQUEST_DATE, g_DATE_FORMAT) AS "day"),
				v_LOAD_XML_FRAGMENT)
		ELSE NULL END)
	INTO P_XML_REQUEST_BODY
	FROM DUAL;

 EXCEPTION
	 WHEN OTHERS THEN
		 P_STATUS  := SQLCODE;
		 P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_MARKET_RESULTS: ' || SQLERRM;
 END GETX_QUERY_MARKET_RESULTS;
  ------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SPIN_RESERVE_OFFER(p_LOCATION_TYPE IN VARCHAR2,
  										  p_LOCATION_NAME IN VARCHAR2,
										  p_REQUEST_DATE  IN DATE,
                                          P_XML_REQUEST_BODY OUT XMLTYPE,
                                          P_STATUS           OUT NUMBER,
                                          P_MESSAGE          OUT VARCHAR2) AS
    V_XML_FRAGMENT  XMLTYPE;

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QuerySpinningReserveOffer",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
                                 V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SPIN_RESERVE_OFFER: ' ||
                   SQLERRM;
  END GETX_QUERY_SPIN_RESERVE_OFFER;
  ---------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SPIN_RESERVE_UPDATE(p_LOCATION_TYPE IN VARCHAR2,
										   p_LOCATION_NAME IN VARCHAR2,
										   p_REQUEST_DATE  IN DATE,
                                           P_XML_REQUEST_BODY OUT XMLTYPE,
                                           P_STATUS           OUT NUMBER,
                                           P_MESSAGE          OUT VARCHAR2) AS
    V_XML_FRAGMENT  XMLTYPE;

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QuerySpinningReserveUpdate",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
                                 V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SPIN_RESERVE_UPDATE: ' ||
                   SQLERRM;
  END GETX_QUERY_SPIN_RESERVE_UPDATE;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SPREG_AWARD(p_LOCATION_TYPE IN VARCHAR2,
								   p_LOCATION_NAME IN VARCHAR2,
								   p_REQUEST_DATE  IN DATE,
								   P_XML_REQUEST_BODY OUT XMLTYPE,
								   P_STATUS           OUT NUMBER,
								   P_MESSAGE          OUT VARCHAR2) AS
    V_XML_FRAGMENT  XMLTYPE;

  BEGIN
	P_STATUS := MEX_UTIL.G_SUCCESS;
	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

	SELECT XMLELEMENT("QueryRequest", XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
		XMLELEMENT("QuerySPREGAward",
		XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
		v_XML_FRAGMENT))
	INTO P_XML_REQUEST_BODY
	FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SPIN_RESERVE_AWARD: ' ||
                   SQLERRM;
  END GETX_QUERY_SPREG_AWARD;
  -----------------------------------------------------------------------------------------------------

  PROCEDURE FETCH_DISTRIBUTION(P_CRED          IN mex_credentials,
  							   P_LOG_ONLY      IN BINARY_INTEGER,
  							   P_LOCATION_TYPE IN VARCHAR2,
							   P_LOCATION_NAME IN VARCHAR2,
							   P_REQUEST_DATE  IN DATE,
                               P_RECORDS       OUT MEX_PJM_EMKT_DISTRIBUTION_TBL,
                               P_STATUS        OUT NUMBER,
                               P_MESSAGE       OUT VARCHAR2,
							   P_LOGGER		   IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_DISTRIBUTION_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_DISTRIBUTION(P_LOCATION_TYPE,
							P_LOCATION_NAME,
							P_REQUEST_DATE,
                            V_XML_REQUEST,
                            P_STATUS,
                            P_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

      IF P_MESSAGE IS NULL THEN
        PARSE_DISTRIBUTION(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_DISTRIBUTION: ' || SQLERRM;
  END FETCH_DISTRIBUTION;
  ---------------------------------------------------------------------------------------
  PROCEDURE FETCH_SPIN_RESERVE_RES(P_CRED		   IN  mex_credentials,
  								   P_LOG_ONLY	   IN  BINARY_INTEGER,
								   P_REQUEST_DATE  IN  DATE,
								   P_RECORDS       OUT MEX_PJM_EMKT_SPIN_RSV_RES_TBL,
                                   P_STATUS        OUT NUMBER,
                                   P_MESSAGE       OUT VARCHAR2,
								   P_LOGGER		   IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_SPIN_RSV_RES_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    -- SEND A REQUEST DATE?
    GETX_QUERY_SPIN_RESERVE_RES(P_REQUEST_DATE,
                                V_XML_REQUEST,
                                P_STATUS,
                                P_MESSAGE);

    --SENDING THE XML REQUEST
    --FIX EXT_ID ETC. AND GET NAMESPACE, QUERY URL ETC. ONLY IN MEX
    --AND OUT OF MM.
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

      IF P_MESSAGE IS NULL THEN
        PARSE_SPIN_RESERVE_RES(V_XML_RESPONSE,
                               P_RECORDS,
                               P_STATUS,
                               P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SPIN_RESERVE_RES: ' ||
                   SQLERRM;
  END FETCH_SPIN_RESERVE_RES;
  ---------------------------------------------------------------------------------------
  PROCEDURE FETCH_SPIN_RESERVE_BIL(P_CRED		   IN  mex_credentials,
  								   P_LOG_ONLY	   IN  BINARY_INTEGER,
  								   P_REQUEST_DATE  IN  DATE,
                                   P_RECORDS       OUT MEX_PJM_EMKT_SPIN_RSV_BIL_TBL,
                                   P_STATUS        OUT NUMBER,
                                   P_MESSAGE       OUT VARCHAR2,
								   P_LOGGER		   IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_SPIN_RSV_BIL_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    -- SEND A REQUEST DATE?
    GETX_QUERY_SPIN_RESERVE_BIL(P_REQUEST_DATE,
                                V_XML_REQUEST,
                                P_STATUS,
                                P_MESSAGE);

    --SENDING THE XML REQUEST
    --FIX EXT_ID ETC. AND GET NAMESPACE, QUERY URL ETC. ONLY IN MEX
    --AND OUT OF MM.
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

      IF P_MESSAGE IS NULL THEN
        PARSE_SPIN_RESERVE_BIL(V_XML_RESPONSE,
                               P_RECORDS,
                               P_STATUS,
                               P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SPIN_RESERVE_BIL: ' ||
                   SQLERRM;
  END FETCH_SPIN_RESERVE_BIL;

---------------------------------------------------------------------------------------
PROCEDURE FETCH_ANCILLARY_SERV(p_CRED			 IN	 mex_credentials,
							   p_LOG_ONLY		 IN  BINARY_INTEGER,
							   p_REQUEST_DATE	 IN  DATE,
							   p_RECORDS       OUT MEX_PJM_EMKT_ANCILLAR_SERV_TBL,
							   p_STATUS        OUT NUMBER,
							   p_MESSAGE       OUT VARCHAR2,
							   p_LOGGER		   IN OUT mm_logger_adapter) AS

v_XML_REQUEST  XMLTYPE;
v_XML_RESPONSE XMLTYPE;
BEGIN

    p_RECORDS := MEX_PJM_EMKT_ANCILLAR_SERV_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_ANCILLARY_SERV(p_REQUEST_DATE,
                              v_XML_REQUEST,
                              p_STATUS,
                             p_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

      IF p_MESSAGE IS NULL THEN
        PARSE_ANCILLARY_SERV(v_XML_RESPONSE,
                             p_RECORDS,
                             p_STATUS,
                             p_MESSAGE);
      END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_ANCILLARY_SERV: ' ||
                   SQLERRM;
END FETCH_ANCILLARY_SERV;
---------------------------------------------------------------------------------------
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
								 p_LOGGER		 IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_MKT_RESULTS_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_MARKET_RESULTS(p_REQUEST_DATE,
							  p_EMKT_GEN,
							  p_EMKT_LOAD,
	                          p_GEN_LOCATION_TYPE,
							  p_GEN_LOCATION_NAME,
							  p_LOAD_LOCATION_TYPE,
							  p_LOAD_LOCATION_NAME,
                              v_XML_REQUEST,
                              P_STATUS,
                              P_MESSAGE);

    --SENDING THE XML REQUEST
    --FIX EXT_ID ETC. AND GET NAMESPACE, QUERY URL ETC. ONLY IN MEX
    --AND OUT OF MM.
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, P_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

      IF p_MESSAGE IS NULL THEN
        PARSE_MARKET_RESULTS(v_XML_RESPONSE,
                             p_RECORDS,
                             p_STATUS,
                             p_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_MARKET_RESULTS: ' ||
                   SQLERRM;
  END FETCH_MARKET_RESULTS;

  ---------------------------------------------------------------------------------------
PROCEDURE FETCH_SPIN_RESERVE_OFFER(p_CRED		   IN mex_credentials,
								   p_LOG_ONLY	   IN BINARY_INTEGER,
								   p_LOCATION_TYPE IN VARCHAR2,
								   p_LOCATION_NAME IN VARCHAR2,
								   p_REQUEST_DATE  IN DATE,
								   p_RECORDS       OUT MEX_PJM_EMKT_SPIN_RES_OFF_TBL,
								   p_STATUS        OUT NUMBER,
								   p_MESSAGE       OUT VARCHAR2,
								   p_LOGGER 	   IN OUT mm_logger_adapter) AS

v_XML_REQUEST  XMLTYPE;
v_XML_RESPONSE XMLTYPE;
BEGIN

    p_RECORDS := MEX_PJM_EMKT_SPIN_RES_OFF_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_SPIN_RESERVE_OFFER(p_LOCATION_TYPE, p_LOCATION_NAME, p_REQUEST_DATE,
                                  v_XML_REQUEST,
                                  p_STATUS, p_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

      IF P_MESSAGE IS NULL THEN
        PARSE_SPIN_RESERVE_OFFER(v_XML_RESPONSE,
                                 p_RECORDS,
                                 p_STATUS,
                                 p_MESSAGE);
      END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SPIN_RESERVE_OFFER: ' ||
                   SQLERRM;
END FETCH_SPIN_RESERVE_OFFER;
----------------------------------------------------------------------------------
  PROCEDURE FETCH_SPIN_RESERVE_UPDATE(p_CRED		  IN mex_credentials,
									  p_LOG_ONLY	  IN BINARY_INTEGER,
									  p_LOCATION_TYPE IN VARCHAR2,
									  p_LOCATION_NAME IN VARCHAR2,
									  p_REQUEST_DATE  IN DATE,
                                      p_RECORDS       OUT MEX_PJM_EMKT_SPIN_RES_UPD_TBL,
                                      p_STATUS        OUT NUMBER,
                                      p_MESSAGE       OUT VARCHAR2,
									  p_LOGGER		  IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_SPIN_RES_UPD_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    -- SEND A REQUEST DATE?
    GETX_QUERY_SPIN_RESERVE_UPDATE(p_LOCATION_TYPE,
								   p_LOCATION_NAME,
								   p_REQUEST_DATE,
                                   v_XML_REQUEST,
                                   p_STATUS,
                                   p_MESSAGE);

    --SENDING THE XML REQUEST
    --FIX EXT_ID ETC. AND GET NAMESPACE, QUERY URL ETC. ONLY IN MEX
    --AND OUT OF MM.
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

      IF p_MESSAGE IS NULL THEN
        PARSE_SPIN_RESERVE_UPDATE(v_XML_RESPONSE,
                                  p_RECORDS,
                                  p_STATUS,
                                  p_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SPIN_RESERVE_UPDATE: ' || SQLERRM;
  END FETCH_SPIN_RESERVE_UPDATE;
  --------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_SPREG_AWARD(p_CRED		  IN mex_credentials,
  							  p_LOG_ONLY	  IN BINARY_INTEGER,
							  p_LOCATION_TYPE IN VARCHAR2,
							  p_LOCATION_NAME IN VARCHAR2,
							  p_REQUEST_DATE  IN DATE,
							  p_RECORDS       OUT MEX_PJM_EMKT_SPIN_RES_AWAR_TBL,
							  p_STATUS        OUT NUMBER,
							  p_MESSAGE       OUT VARCHAR2,
							  p_LOGGER		  IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_SPIN_RES_AWAR_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    -- SEND A REQUEST DATE?
    GETX_QUERY_SPREG_AWARD(p_LOCATION_TYPE,
						   p_LOCATION_NAME,
						   p_REQUEST_DATE,
						   v_XML_REQUEST,
						   p_STATUS,
						   p_MESSAGE);

    --SENDING THE XML REQUEST
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

      IF p_MESSAGE IS NULL THEN
        PARSE_SPREG_AWARD(v_XML_RESPONSE,
                            p_RECORDS,
                            p_STATUS,
                            p_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SPREG_AWARD: ' ||
                   SQLERRM;
  END FETCH_SPREG_AWARD;
  -------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_REGULATION_OFFER(p_XML_RESPONSE IN XMLTYPE,
                                   p_RECORDS IN OUT NOCOPY MEX_PJM_EMKT_REG_OFFER_TBL,
                                   p_STATUS OUT NUMBER,
                                   p_MESSAGE OUT VARCHAR2) AS

CURSOR c_XML IS
	SELECT TO_DATE(EXTRACTVALUE(VALUE(REG_OFFER), '//@day', G_PJM_EMKT_NAMESPACE), G_DATE_FORMAT) "RESPONSE_DATE",
		EXTRACTVALUE(VALUE(REG_OFFER), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
		EXTRACTVALUE(VALUE(REG_OFFER), '//OfferMW', G_PJM_EMKT_NAMESPACE) "QUANTITY",
		EXTRACTVALUE(VALUE(REG_OFFER), '//OfferPrice', G_PJM_EMKT_NAMESPACE) "PRICE",
		EXTRACTVALUE(VALUE(REG_OFFER), '//Unavailable', G_PJM_EMKT_NAMESPACE) "UNAVAILABLE",
		EXTRACTVALUE(VALUE(REG_OFFER), '//SelfScheduled', G_PJM_EMKT_NAMESPACE) "SELF_SCHEDULED",
		EXTRACTVALUE(VALUE(REG_OFFER), '//MinimumMW', G_PJM_EMKT_NAMESPACE) "MINIMUM_MW"
	FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,'//RegulationOffer', G_PJM_EMKT_NAMESPACE))) REG_OFFER;

BEGIN
	p_STATUS := GA.SUCCESS;

	FOR v_XML IN c_XML LOOP
		p_RECORDS.EXTEND();
		p_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_REG_OFFER(v_XML.RESPONSE_DATE,
			v_XML.LOCATION,
			TO_NUMBER(v_XML.QUANTITY),
			TO_NUMBER(v_XML.PRICE),
			v_XML.UNAVAILABLE,
			v_XML.SELF_SCHEDULED,
			v_XML.MINIMUM_MW);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_REGULATION_OFFER: ' || SQLERRM;
END PARSE_REGULATION_OFFER;
---------------------------------------------------------------------------------------
PROCEDURE GETX_QUERY_REGULATION_OFFER
    (
    p_LOCATION_TYPE IN VARCHAR2,
	p_LOCATION_NAME IN VARCHAR2,
	p_REQUEST_DATE  IN DATE,
    p_XML_REQUEST_BODY OUT XMLTYPE,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS
	v_XML_FRAGMENT  XMLTYPE;
BEGIN
    p_STATUS := MEX_UTIL.G_SUCCESS;


	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

	SELECT XMLELEMENT("QueryRequest",
		XMLATTRIBUTES(g_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
		XMLELEMENT("QueryRegulationOffer",
			XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
			v_XML_FRAGMENT))
	INTO p_XML_REQUEST_BODY
	FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_REGULATION_OFFER: ' ||
                   SQLERRM;
  END GETX_QUERY_REGULATION_OFFER;
  -------------------------------------------------------------------------------------
  PROCEDURE FETCH_REGULATION_OFFER(p_CRED		  IN mex_credentials,
  							  	   p_LOG_ONLY	  IN BINARY_INTEGER,
								   p_LOCATION_TYPE IN VARCHAR2,
								   p_LOCATION_NAME IN VARCHAR2,
								   p_REQUEST_DATE  IN DATE,
                                   p_RECORDS       OUT MEX_PJM_EMKT_REG_OFFER_TBL,
                                   p_STATUS        OUT NUMBER,
                                   p_MESSAGE       OUT VARCHAR2,
								   p_LOGGER		  IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_REG_OFFER_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_REGULATION_OFFER(p_LOCATION_TYPE,
						   		p_LOCATION_NAME,
						   		p_REQUEST_DATE,
                                v_XML_REQUEST,
                                p_STATUS,
                                p_MESSAGE);

    --SENDING THE XML REQUEST
	RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

    PARSE_REGULATION_OFFER(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_REGULATION_OFFER: ' ||
                   SQLERRM;
  END FETCH_REGULATION_OFFER;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_REGULATION_UPDATE(P_XML_RESPONSE IN XMLTYPE,
                                    P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_UPDATE_TBL,
                                    P_STATUS       OUT NUMBER,
                                    P_MESSAGE      OUT VARCHAR2) AS

	CURSOR C_XML IS
		SELECT TO_DATE(EXTRACTVALUE(VALUE(REGULATION_UPDATE), '//@day', G_PJM_EMKT_NAMESPACE),
				G_DATE_FORMAT) "RESPONSE_DATE",
			EXTRACTVALUE(VALUE(REGULATION_UPDATE), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//@isDuplicateHour', G_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//MW', G_PJM_EMKT_NAMESPACE) "QUANTITY",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//Unavailable', G_PJM_EMKT_NAMESPACE) "UNAVAILABLE",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//Spilling', G_PJM_EMKT_NAMESPACE) "SPILLING",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//SelfScheduled', G_PJM_EMKT_NAMESPACE) "SELF_SCHEDULED",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//RegulationLimits//@minMW', G_PJM_EMKT_NAMESPACE) "LIMIT_MIN_MW",
			EXTRACTVALUE(VALUE(HOURLY_UPDATE), '//RegulationLimits//@maxMW', G_PJM_EMKT_NAMESPACE) "LIMIT_MAX_MW"
		FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, '//RegulationUpdate', G_PJM_EMKT_NAMESPACE))) REGULATION_UPDATE,
			TABLE(XMLSEQUENCE(EXTRACT(VALUE(REGULATION_UPDATE), '//RegulationUpdateHourly', G_PJM_EMKT_NAMESPACE))) HOURLY_UPDATE;

  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_REG_UPDATE(TO_CUT_WITH_OPTIONS(DUPLICATE_DATE(V_XML.RESPONSE_DATE + TO_NUMBER(V_XML.HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION),
                                                           V_XML.LOCATION,
                                                           TO_NUMBER(V_XML.QUANTITY),
														   V_XML.UNAVAILABLE,
                                                           V_XML.SPILLING,
                                                           V_XML.SELF_SCHEDULED,
                                                           TO_NUMBER(V_XML.LIMIT_MAX_MW),
                                                           TO_NUMBER(V_XML.LIMIT_MIN_MW));
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_REGULATION_UPDATE: ' || SQLERRM;
  END PARSE_REGULATION_UPDATE;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_REGULATION_UPDATE(p_LOCATION_TYPE IN VARCHAR2,
  										 p_LOCATION_NAME IN VARCHAR2,
										 p_REQUEST_DATE  IN DATE,
                                         P_XML_REQUEST_BODY OUT XMLTYPE,
                                         P_STATUS           OUT NUMBER,
                                         P_MESSAGE          OUT VARCHAR2) AS

	v_XML_FRAGMENT  XMLTYPE;

BEGIN
	P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

	SELECT XMLELEMENT("QueryRequest",
		XMLATTRIBUTES(g_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
		XMLELEMENT("QueryRegulationUpdate",
			XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
			v_XML_FRAGMENT))
	INTO p_XML_REQUEST_BODY
	FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_REGULATION_UPDATE: ' ||
                   SQLERRM;
  END GETX_QUERY_REGULATION_UPDATE;
  ------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_REGULATION_UPDATE(p_CRED			IN mex_credentials,
  									p_LOG_ONLY		IN BINARY_INTEGER,
  									p_LOCATION_TYPE IN VARCHAR2,
  									p_LOCATION_NAME IN VARCHAR2,
									p_REQUEST_DATE  IN DATE,
                                    p_RECORDS       OUT MEX_PJM_EMKT_REG_UPDATE_TBL,
                                    p_STATUS        OUT NUMBER,
                                    p_MESSAGE       OUT VARCHAR2,
									p_LOGGER		IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_REG_UPDATE_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_REGULATION_UPDATE(p_LOCATION_TYPE, p_LOCATION_NAME, p_REQUEST_DATE,
                                 v_XML_REQUEST,
                                 p_STATUS,
                                 p_MESSAGE);

    --SENDING THE XML REQUEST
	  RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);


    PARSE_REGULATION_UPDATE(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_REGULATION_UPDATE: ' ||
                   SQLERRM;
  END FETCH_REGULATION_UPDATE;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_REGULATION_AWARD(P_XML_RESPONSE IN XMLTYPE,
                                   P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_AWARD_TBL,
                                   P_STATUS       OUT NUMBER,
                                   P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(AWARD),
                                  '//@day',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(AWARD), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//@hour',
                          G_PJM_EMKT_NAMESPACE) "RESPONSE_HOUR",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//RegOfferMW',
                          G_PJM_EMKT_NAMESPACE) "QUANTITY",
             EXTRACTVALUE(VALUE(AWARD_HOURLY),
                          '//RegAwardedMW',
                          G_PJM_EMKT_NAMESPACE) "REG_AWARDED_MW"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//SPREGAward',
                                       G_PJM_EMKT_NAMESPACE))) AWARD,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(AWARD),
                                       '//SPREGAwardHourly',
                                       G_PJM_EMKT_NAMESPACE))) AWARD_HOURLY;

  BEGIN
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_REG_AWARD(V_XML.RESPONSE_DATE,
                                                          V_XML.LOCATION,
                                                          V_XML.RESPONSE_HOUR,
                                                          V_XML.QUANTITY,
                                                          V_XML.REG_AWARDED_MW);

    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_REGULATION_AWARD: ' ||
                   SQLERRM;
  END PARSE_REGULATION_AWARD;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_REGULATION_RESULTS(P_XML_RESPONSE IN XMLTYPE,
                                     P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_RESULTS_TBL,
                                     P_STATUS       OUT NUMBER,
                                     P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(RESULTS),
                                  '//@day',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(RESULTS_HOURLY),
                          '//@hour',
                          G_PJM_EMKT_NAMESPACE) "RESPONSE_HOUR",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//RMCP',
                          G_PJM_EMKT_NAMESPACE) "MCP",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//SelfScheduledMW',
                          G_PJM_EMKT_NAMESPACE) "SELF_SCHEDULED_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//ProcuredMW',
                          G_PJM_EMKT_NAMESPACE) "PROCURED_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//TotalMW',
                          G_PJM_EMKT_NAMESPACE) "TOTAL_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//RequiredMW',
                          G_PJM_EMKT_NAMESPACE) "REQUIRED_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//DeficiencyMW',
                          G_PJM_EMKT_NAMESPACE) "DEFICIENCY_MW",
             EXTRACTVALUE(VALUE(RESULTS_AREA),
                          '//AreaName',
                          G_PJM_EMKT_NAMESPACE) "AREA_NAME"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//RegulationResults',
                                       G_PJM_EMKT_NAMESPACE))) RESULTS,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(RESULTS),
                                       '//RegulationResultsHourly',
                                       G_PJM_EMKT_NAMESPACE))) RESULTS_HOURLY,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(RESULTS_HOURLY),
                                       '//RegulationResultsByArea',
                                       G_PJM_EMKT_NAMESPACE))) RESULTS_AREA;

  BEGIN
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_REG_RESULTS(V_XML.RESPONSE_DATE,
                                                            V_XML.RESPONSE_HOUR,
                                                            V_XML.MCP,
                                                            V_XML.SELF_SCHEDULED_MW,
                                                            V_XML.PROCURED_MW,
                                                            V_XML.TOTAL_MW,
                                                            V_XML.REQUIRED_MW,
                                                            V_XML.DEFICIENCY_MW,
                                                            V_XML.AREA_NAME);

    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_REGULATION_RESULTS: ' ||
                   SQLERRM;
  END PARSE_REGULATION_RESULTS;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_REGULATION_RESULTS(p_REQUEST_DATE  IN DATE,
                                          P_XML_REQUEST_BODY OUT XMLTYPE,
                                          P_STATUS           OUT NUMBER,
                                          P_MESSAGE          OUT VARCHAR2) AS

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryRegulationResults",
                                 XMLATTRIBUTES(TO_CHAR(p_REQUEST_DATE,
                                                       G_DATE_FORMAT) AS
                                               "day")))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_REGULATION_RESULTS: ' ||
                   SQLERRM;
  END GETX_QUERY_REGULATION_RESULTS;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_REGULATION_RESULTS(p_CRED		  IN mex_credentials,
  							  		 p_LOG_ONLY	  IN BINARY_INTEGER,
									 p_REQUEST_DATE  IN DATE,
                                     p_RECORDS       OUT MEX_PJM_EMKT_REG_RESULTS_TBL,
                                     p_STATUS        OUT NUMBER,
                                     p_MESSAGE       OUT VARCHAR2,
									 p_LOGGER		 IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_REG_RESULTS_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_REGULATION_RESULTS(p_REQUEST_DATE,
                                  v_XML_REQUEST,
                                  p_STATUS,
                                  p_MESSAGE);

    --SENDING THE XML REQUEST
    --FIX EXT_ID ETC. AND GET NAMESPACE, QUERY URL ETC. ONLY IN MEX
    --AND OUT OF MM.
	RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

    PARSE_REGULATION_RESULTS(v_XML_RESPONSE,
                             p_RECORDS,
                             p_STATUS,
                             p_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_REGULATION_RESULTS: ' ||
                   SQLERRM;
  END FETCH_REGULATION_RESULTS;
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_REGULATION_BILATERAL(P_XML_RESPONSE IN XMLTYPE,
                                       P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_REG_BILATERAL_TBL,
                                       P_STATUS       OUT NUMBER,
                                       P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(REG_BILATS),
                                  '//@day',
                                  G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "DAY",
             EXTRACTVALUE(VALUE(SCHEDULE), '//@Buyer', G_PJM_EMKT_NAMESPACE) "SELLER",
             EXTRACTVALUE(VALUE(SCHEDULE),
                          '//@Seller',
                          G_PJM_EMKT_NAMESPACE) "BUYER",
             EXTRACTVALUE(VALUE(SCHEDULE), '//MW', G_PJM_EMKT_NAMESPACE) "MW",
             EXTRACTVALUE(VALUE(SCHEDULE),
                          '//StartTime',
                          G_PJM_EMKT_NAMESPACE) "START_DATE",
             EXTRACTVALUE(VALUE(SCHEDULE),
                          '//StopTime',
                          G_PJM_EMKT_NAMESPACE) "END_DATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//RegulationBilaterals',
                                       G_PJM_EMKT_NAMESPACE))) REG_BILATS,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(REG_BILATS),
                                       '//BilateralSchedule',
                                       G_PJM_EMKT_NAMESPACE))) SCHEDULE;

  BEGIN
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_REG_BILATERAL(V_XML.DAY,
                                                              V_XML.SELLER,
                                                              V_XML.BUYER,
                                                              V_XML.MW,
                                                              V_XML.START_DATE,
                                                              V_XML.END_DATE);

    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_REGULATION_BILATERAL: ' ||
                   SQLERRM;
  END PARSE_REGULATION_BILATERAL;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_REG_BILATERAL(p_REQUEST_DATE  IN DATE,
                                     P_XML_REQUEST_BODY OUT XMLTYPE,
                                     P_STATUS           OUT NUMBER,
                                     P_MESSAGE          OUT VARCHAR2) AS

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryRegulationBilaterals",
                                 XMLATTRIBUTES(TO_CHAR(p_REQUEST_DATE,
                                                       G_DATE_FORMAT) AS
                                               "day")))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_REGULATION_BILATERAL: ' ||
                   SQLERRM;
  END GETX_QUERY_REG_BILATERAL;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_REGULATION_BILATERAL(p_CRED		  IN mex_credentials,
  							  		   p_LOG_ONLY	  IN BINARY_INTEGER,
									   p_REQUEST_DATE  IN  DATE,
                                       p_RECORDS       OUT MEX_PJM_EMKT_REG_BILATERAL_TBL,
                                       p_STATUS        OUT NUMBER,
                                       p_MESSAGE       OUT VARCHAR2,
									   p_LOGGER		   IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_REG_BILATERAL_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_REG_BILATERAL(p_REQUEST_DATE,
                             v_XML_REQUEST,
                             p_STATUS,
                             p_MESSAGE);

    --SENDING THE XML REQUEST
    RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

    PARSE_REGULATION_BILATERAL(v_XML_RESPONSE,
                               p_RECORDS,
                               p_STATUS,
                               p_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_REGULATION_BILATERAL: ' ||
                   SQLERRM;
  END FETCH_REGULATION_BILATERAL;
  ------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_UNIT_SCHEDULES(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_UNIT_SCHED_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2) AS



    CURSOR C_XML IS
      SELECT EXTRACTVALUE(VALUE(T), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION_NAME",
             EXTRACTVALUE(VALUE(U), '//@schedule', G_PJM_EMKT_NAMESPACE) "SCHEDULE_NUMBER",
             EXTRACTVALUE(VALUE(U), '//ScheduleName', G_PJM_EMKT_NAMESPACE) "SCHEDULE_NAME",
             EXTRACTVALUE(VALUE(U),
                          '//ScheduleDescription',
                          G_PJM_EMKT_NAMESPACE) "SCHEDULE_DESCRIPTION"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//UnitSchedules',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//UnitSchedule',
                                       G_PJM_EMKT_NAMESPACE))) U;
  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_UNIT_SCHED(V_XML.LOCATION_NAME,
                                                           V_XML.SCHEDULE_NUMBER,
                                                           V_XML.SCHEDULE_NAME,
                                                           V_XML.SCHEDULE_DESCRIPTION);

    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_UNIT_SCHEDULES: ' ||
                   SQLERRM;
  END PARSE_UNIT_SCHEDULES;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_UNIT_SCHEDULES(p_LOCATION_TYPE IN VARCHAR2,
  									  p_LOCATION_NAME IN VARCHAR2,
                                      P_XML_REQUEST_BODY OUT XMLTYPE,
                                      P_STATUS           OUT NUMBER,
                                      P_MESSAGE          OUT VARCHAR2) AS

    V_XML_FRAGMENT XMLTYPE;
  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    -- the request XML will vary depending on the location type
	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

    --GENERATE THE REQUEST XML.
    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryUnitSchedules", V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_UNIT_SCHEDULES: ' ||
                   SQLERRM;
  END GETX_QUERY_UNIT_SCHEDULES;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_UNIT_SCHEDULES(p_CRED			 IN mex_credentials,
  								 p_LOG_ONLY		 IN BINARY_INTEGER,
  								 p_LOCATION_TYPE IN VARCHAR2,
  								 p_LOCATION_NAME IN VARCHAR2,
                                 p_RECORDS       OUT MEX_PJM_EMKT_UNIT_SCHED_TBL,
                                 p_STATUS        OUT NUMBER,
                                 p_MESSAGE       OUT VARCHAR2,
								 p_LOGGER		 IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_UNIT_SCHED_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_UNIT_SCHEDULES(p_LOCATION_TYPE, p_LOCATION_NAME,
                              v_XML_REQUEST,
                              p_STATUS,
                              p_MESSAGE);

--UT.DEBUG_TRACE('FETCH_UNIT_SCHEDULES: ' || v_XML_REQUEST.GETSTRINGVAL());

    --SENDING THE XML REQUEST
    RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

    PARSE_UNIT_SCHEDULES(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_UNIT_SCHEDULES: ' ||
                   SQLERRM;
  END FETCH_UNIT_SCHEDULES;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_UNIT_DETAIL(P_XML_RESPONSE IN XMLTYPE,
                              P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_UNIT_DETAIL_TBL,
                              P_STATUS       OUT NUMBER,
                              P_MESSAGE      OUT VARCHAR2) AS


    CURSOR C_XML IS
      SELECT EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             TO_DATE(EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/@day', G_PJM_EMKT_NAMESPACE), G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultCommitStatus', G_PJM_EMKT_NAMESPACE) "COMMITSTATUS",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/FixedGen', G_PJM_EMKT_NAMESPACE) "FIXEDGEN",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CondenseAvailable', G_PJM_EMKT_NAMESPACE) "CONDENSEAVAILABLE",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CondenseStartupCost', G_PJM_EMKT_NAMESPACE) "CONDENSESTARTUPCOST",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CondenseEnergyUsage', G_PJM_EMKT_NAMESPACE) "CONDENSEENERGYUSAGE",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CondenseNotification', G_PJM_EMKT_NAMESPACE) "CONDENSENOTIFICATION",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CondenseHourlyCost', G_PJM_EMKT_NAMESPACE) "CONDENSEHOURLYCOST",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultRampRate', G_PJM_EMKT_NAMESPACE) "DEFAULTRAMPRATE",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Economic/@minMW', G_PJM_EMKT_NAMESPACE) "MINECONOMICLIMIT",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Economic/@maxMW', G_PJM_EMKT_NAMESPACE) "MAXECONOMICLIMIT",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Emergency/@minMW', G_PJM_EMKT_NAMESPACE) "MINEMERGENCYLIMIT",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Emergency/@maxMW', G_PJM_EMKT_NAMESPACE) "MAXEMERGENCYLIMIT",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Regulation/@minMW', G_PJM_EMKT_NAMESPACE) "MINREGULATIONLIMIT",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Regulation/@maxMW', G_PJM_EMKT_NAMESPACE) "MAXREGULATIONLIMIT",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Spinning/@maxMW', G_PJM_EMKT_NAMESPACE) "MAXSPINNINGLIMIT",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Temperature/EconomicRange/Low/@MW', G_PJM_EMKT_NAMESPACE) "LOWECONOMICTEMPRANGEMW",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EconomicRange/Low/@temperature', G_PJM_EMKT_NAMESPACE) "LOWECONOMICTEMPRANGETEMP",
             EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultLimits/Temperature/EconomicRange/Middle/@MW', G_PJM_EMKT_NAMESPACE) "MIDECONOMICTEMPRANGEMW",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EconomicRange/Middle/@temperature', G_PJM_EMKT_NAMESPACE) "MIDECONOMICTEMPRANGETEMP",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EconomicRange/High/@MW', G_PJM_EMKT_NAMESPACE) "HIGHECONOMICTEMPRANGEMW",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EconomicRange/High/@temperature', G_PJM_EMKT_NAMESPACE) "HIGHECONOMICTEMPRANGETEMP",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EmergencyRange/Low/@MW', G_PJM_EMKT_NAMESPACE) "LOWEMERGENCYTEMPRANGEMW",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EmergencyRange/Low/@temperature', G_PJM_EMKT_NAMESPACE) "LOWEMERGENCYTEMPRANGETEMP",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EmergencyRange/Middle/@MW', G_PJM_EMKT_NAMESPACE) "MIDEMERGENCYTEMPRANGEMW",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EmergencyRange/Middle/@temperature', G_PJM_EMKT_NAMESPACE) "MIDEMERGENCYTEMPRANGETEMP",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EmergencyRange/High/@MW', G_PJM_EMKT_NAMESPACE) "HIGHEMERGENCYTEMPRANGEMW",
             EXTRACTVALUE(VALUE(UNIT_DETAILS),
                          '/UnitDetail/DefaultLimits/Temperature/EmergencyRange/High/@temperature', G_PJM_EMKT_NAMESPACE) "HIGHEMERGENCYTEMPRANGETEMP",
             EXTRACT(VALUE(UNIT_DETAILS), '/UnitDetail/DefaultStartupCosts', G_PJM_EMKT_NAMESPACE) "DEFAULTSTARTUPCOST",
             EXTRACT(VALUE(UNIT_DETAILS), '/UnitDetail/EnergyRampRateCurve', G_PJM_EMKT_NAMESPACE) "ENERGYRAMPRATECURVE",
             EXTRACT(VALUE(UNIT_DETAILS), '/UnitDetail/SpinRampRateCurve', G_PJM_EMKT_NAMESPACE) "SPINRAMPRATECURVE",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CombinedCycleParameters/MinTimeBetweenStartups', G_PJM_EMKT_NAMESPACE) "CC_MIN_TIME_BETWEEN",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CombinedCycleParameters/AllowSimpleCycle', G_PJM_EMKT_NAMESPACE) "CC_ALLOW_SIMPLE_CYCLE",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/CombinedCycleParameters/CombinedCycleFactor', G_PJM_EMKT_NAMESPACE) "CC_FACTOR",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/PumpStorageParameters/PumpingFactor', G_PJM_EMKT_NAMESPACE) "PS_PUMPING_FACTOR",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/PumpStorageParameters/InitialMWH', G_PJM_EMKT_NAMESPACE) "PS_INITIAL_MWH",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/PumpStorageParameters/FinalMWH', G_PJM_EMKT_NAMESPACE) "PS_FINAL_MWH",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/PumpStorageParameters/MaxMWH', G_PJM_EMKT_NAMESPACE) "PS_MAX_MWH",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/PumpStorageParameters/MinMWH', G_PJM_EMKT_NAMESPACE) "PS_MIN_MWH",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/PumpStorageLimits/MinGenMW', G_PJM_EMKT_NAMESPACE) "PS_MIN_GEN_MW",
			EXTRACTVALUE(VALUE(UNIT_DETAILS), '/UnitDetail/PumpStorageLimits/MinPumpMW', G_PJM_EMKT_NAMESPACE) "PS_MIN_PUMP_MW"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//UnitDetail',
                                       G_PJM_EMKT_NAMESPACE))) UNIT_DETAILS;

        CURSOR c_DEFAULTSTARTUPCOST(v_DEFAULTSTARTUPCOST_XML IN XMLTYPE) IS
         SELECT
        	 EXTRACTVALUE(VALUE(T),
                          '/DefaultStartupCosts/@interval', G_PJM_EMKT_NAMESPACE) "DEFAULTSTARTUPCOSTSINTERVAL",
             EXTRACTVALUE(VALUE(T),
                          '/DefaultStartupCosts/UseCostBasedStartup', G_PJM_EMKT_NAMESPACE) "USECOSTBASEDSTARTUP",
             EXTRACTVALUE(VALUE(T), '/DefaultStartupCosts/NoLoad', G_PJM_EMKT_NAMESPACE) "NOLOADCOST",
             EXTRACTVALUE(VALUE(T), '/DefaultStartupCosts/ColdStartup', G_PJM_EMKT_NAMESPACE) "COLDSTARTUPCOST",
             EXTRACTVALUE(VALUE(T),
                          '/DefaultStartupCosts/IntermediateStartup', G_PJM_EMKT_NAMESPACE) "INTERMEDIATESTARTUPCOST",
             EXTRACTVALUE(VALUE(T), '/DefaultStartupCosts/HotStartup', G_PJM_EMKT_NAMESPACE) "HOTSTARTUPCOST"
         FROM TABLE(XMLSEQUENCE(EXTRACT(v_DEFAULTSTARTUPCOST_XML,'/DefaultStartupCosts', G_PJM_EMKT_NAMESPACE))) T;

        CURSOR c_ENERGYRAMPRATECURVE(v_ENERGYRAMPRATECURVE_XML IN XMLTYPE) IS
         SELECT
        	EXTRACT(VALUE(T),'/RampRate/@MW', G_PJM_EMKT_NAMESPACE).getstringval() "ENERGYRAMPRATECURVEMW",
        	EXTRACT(VALUE(T),'/RampRate/@rate', G_PJM_EMKT_NAMESPACE).getstringval() "ENERGYRAMPRATECURVERATE"
         FROM TABLE(XMLSEQUENCE(EXTRACT(v_ENERGYRAMPRATECURVE_XML,'/EnergyRampRateCurve/RampRate', G_PJM_EMKT_NAMESPACE))) T;

        CURSOR c_SPINRAMPRATECURVE(v_SPINRAMPRATECURVE_XML IN XMLTYPE) IS
         SELECT
        	EXTRACTVALUE(VALUE(T),'/RampRate/@MW', G_PJM_EMKT_NAMESPACE) "SPINRAMPRATECURVEMW",
        	EXTRACTVALUE(VALUE(T),'/RampRate/@rate', G_PJM_EMKT_NAMESPACE) "SPINRAMPRATECURVERATE"
         FROM TABLE(XMLSEQUENCE(EXTRACT(v_SPINRAMPRATECURVE_XML,'/SpinRampRateCurve/RampRate', G_PJM_EMKT_NAMESPACE))) T;

         v_ER_RECORDS MEX_PJM_EMKT_UNIT_DTL_ER_TBL;
         v_SR_RECORDS MEX_PJM_EMKT_UNIT_DTL_SR_TBL;
         v_DSC_RECORDS MEX_PJM_EMKT_UNIT_DTL_DSC_TBL;

  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR V_XML IN C_XML LOOP
--                    UT.DEBUG_TRACE('GETX_QUERY_UNIT_DETAIL: ' || V_XML.ENERGYRAMPRATECURVE.getStringVal());

      v_DSC_RECORDS := MEX_PJM_EMKT_UNIT_DTL_DSC_TBL();
      FOR v_DSC_XML IN c_DEFAULTSTARTUPCOST(V_XML.DEFAULTSTARTUPCOST) LOOP
         IF v_DSC_XML.DEFAULTSTARTUPCOSTSINTERVAL IS NOT NULL THEN
           v_DSC_RECORDS.EXTEND();
           v_DSC_RECORDS(v_DSC_RECORDS.LAST) := MEX_PJM_EMKT_UNIT_DTL_DSC(
                                                            v_DSC_XML.DEFAULTSTARTUPCOSTSINTERVAL,
                                                            CASE UPPER(v_DSC_XML.USECOSTBASEDSTARTUP) WHEN 'TRUE' THEN 1 ELSE 0 END,
                                                            v_DSC_XML.NOLOADCOST,
                                                            v_DSC_XML.COLDSTARTUPCOST,
                                                            v_DSC_XML.INTERMEDIATESTARTUPCOST,
                                                            v_DSC_XML.HOTSTARTUPCOST
                                                            );
         END IF;
      END LOOP;

      v_ER_RECORDS := MEX_PJM_EMKT_UNIT_DTL_ER_TBL();
      FOR v_ER_XML IN c_ENERGYRAMPRATECURVE(V_XML.ENERGYRAMPRATECURVE) LOOP
         IF v_ER_XML.ENERGYRAMPRATECURVEMW IS NOT NULL THEN
           v_ER_RECORDS.EXTEND();
           v_ER_RECORDS(v_ER_RECORDS.LAST) := MEX_PJM_EMKT_UNIT_DTL_ER(
                                                            v_ER_XML.ENERGYRAMPRATECURVEMW,
                                                            v_ER_XML.ENERGYRAMPRATECURVERATE);
         END IF;
      END LOOP;

      v_SR_RECORDS := MEX_PJM_EMKT_UNIT_DTL_SR_TBL();
      FOR v_SR_XML IN c_SPINRAMPRATECURVE(V_XML.SPINRAMPRATECURVE) LOOP
         IF v_SR_XML.SPINRAMPRATECURVEMW IS NOT NULL THEN
           v_SR_RECORDS.EXTEND();
           v_SR_RECORDS(v_SR_RECORDS.LAST) := MEX_PJM_EMKT_UNIT_DTL_SR(
                                                            v_SR_XML.SPINRAMPRATECURVEMW,
                                                            v_SR_XML.SPINRAMPRATECURVERATE);
         END IF;
      END LOOP;

      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_UNIT_DETAIL(v_XML.RESPONSE_DATE, V_XML.LOCATION,
                                                            V_XML.COMMITSTATUS,
                                                            V_XML.FIXEDGEN,
                                                            V_XML.CONDENSEAVAILABLE,
                                                            TO_NUMBER(V_XML.CONDENSESTARTUPCOST),
                                                            TO_NUMBER(V_XML.CONDENSEENERGYUSAGE),
                                                            TO_NUMBER(V_XML.CONDENSENOTIFICATION),
                                                            TO_NUMBER(V_XML.CONDENSEHOURLYCOST),
                                                            TO_NUMBER(V_XML.DEFAULTRAMPRATE),
                                                            TO_NUMBER(V_XML.MINECONOMICLIMIT),
                                                            TO_NUMBER(V_XML.MAXECONOMICLIMIT),
                                                            TO_NUMBER(V_XML.MINEMERGENCYLIMIT),
                                                            TO_NUMBER(V_XML.MAXEMERGENCYLIMIT),
                                                            TO_NUMBER(V_XML.MINREGULATIONLIMIT),
                                                            TO_NUMBER(V_XML.MAXREGULATIONLIMIT),
                                                            TO_NUMBER(V_XML.MAXSPINNINGLIMIT),
                                                            TO_NUMBER(V_XML.LOWECONOMICTEMPRANGEMW),
                                                            TO_NUMBER(V_XML.LOWECONOMICTEMPRANGETEMP),
                                                            TO_NUMBER(V_XML.MIDECONOMICTEMPRANGEMW),
                                                            TO_NUMBER(V_XML.MIDECONOMICTEMPRANGETEMP),
                                                            TO_NUMBER(V_XML.HIGHECONOMICTEMPRANGEMW),
                                                            TO_NUMBER(V_XML.HIGHECONOMICTEMPRANGETEMP),
                                                            TO_NUMBER(V_XML.LOWEMERGENCYTEMPRANGEMW),
                                                            TO_NUMBER(V_XML.LOWEMERGENCYTEMPRANGETEMP),
                                                            TO_NUMBER(V_XML.MIDEMERGENCYTEMPRANGEMW),
                                                            TO_NUMBER(V_XML.MIDEMERGENCYTEMPRANGETEMP),
                                                            TO_NUMBER(V_XML.HIGHEMERGENCYTEMPRANGEMW),
                                                            TO_NUMBER(V_XML.HIGHEMERGENCYTEMPRANGETEMP),
                                                            v_ER_RECORDS,
                                                            v_SR_RECORDS,
                                                            v_DSC_RECORDS,
														TO_NUMBER(v_XML.CC_MIN_TIME_BETWEEN),
														v_XML.CC_ALLOW_SIMPLE_CYCLE,
														TO_NUMBER(v_XML.CC_FACTOR),
														TO_NUMBER(v_XML.PS_PUMPING_FACTOR),
														TO_NUMBER(v_XML.PS_INITIAL_MWH),
														TO_NUMBER(v_XML.PS_FINAL_MWH),
														TO_NUMBER(v_XML.PS_MAX_MWH),
														TO_NUMBER(v_XML.PS_MIN_MWH),
														TO_NUMBER(v_XML.PS_MIN_GEN_MW),
														TO_NUMBER(v_XML.PS_MIN_PUMP_MW)
															);
    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_UNIT_DETAIL: ' || SQLERRM;
  END PARSE_UNIT_DETAIL;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_UNIT_DETAIL(p_LOCATION_TYPE IN VARCHAR2,
  								   p_LOCATION_NAME IN VARCHAR2,
								   p_REQUEST_DATE  IN DATE,
                                   P_XML_REQUEST_BODY OUT XMLTYPE,
                                   P_STATUS           OUT NUMBER,
                                   P_MESSAGE          OUT VARCHAR2) AS

    V_XML_FRAGMENT  XMLTYPE;

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryUnitDetail",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
                                 V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_UNIT_DETAIL: ' ||
                   SQLERRM;
  END GETX_QUERY_UNIT_DETAIL;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_UNIT_DETAIL(p_CRED		  IN mex_credentials,
  							  p_LOG_ONLY	  IN BINARY_INTEGER,
							  p_LOCATION_TYPE IN VARCHAR2,
  							  p_LOCATION_NAME IN VARCHAR2,
							  p_REQUEST_DATE  IN DATE,
                              p_RECORDS       OUT MEX_PJM_EMKT_UNIT_DETAIL_TBL,
                              p_STATUS        OUT NUMBER,
                              p_MESSAGE       OUT VARCHAR2,
							  p_LOGGER		  IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
  BEGIN

    p_RECORDS := MEX_PJM_EMKT_UNIT_DETAIL_TBL();
    p_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_UNIT_DETAIL(p_LOCATION_TYPE,p_LOCATION_NAME,p_REQUEST_DATE,
                           v_XML_REQUEST,
                           p_STATUS,
                           p_MESSAGE);

    --SENDING THE XML REQUEST
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);


    PARSE_UNIT_DETAIL(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_UNIT_DETAIL: ' || SQLERRM;
  END FETCH_UNIT_DETAIL;
  -----------------------------------------------------------------------------------------------------
PROCEDURE GETX_SUBMIT_UNIT_DETAIL
	(
	p_RECORDS       IN MEX_PJM_EMKT_UNIT_DETAIL_TBL,
	p_SUBMIT_XML    OUT XMLTYPE,
	p_STATUS        OUT NUMBER,
	p_MESSAGE       OUT VARCHAR2
	) IS

BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;

	SELECT XMLELEMENT("UnitDetail",
		XMLATTRIBUTES(
			TO_CHAR(T.SCHEDULE_DAY,'YYYY-MM-DD') AS "day",
			T.LOCATION AS "location"
		),

		XMLELEMENT("DefaultCommitStatus", T.COMMITSTATUS),
		XMLELEMENT("FixedGen", T.FIXEDGEN),
		XMLELEMENT("DefaultLimits",
			XMLELEMENT("Economic",
				XMLATTRIBUTES(
				TO_CHAR(T.MINECONOMICLIMIT) AS "minMW",
				TO_CHAR(T.MAXECONOMICLIMIT) AS "maxMW"
				)),
			XMLELEMENT("Emergency",
				XMLATTRIBUTES(
				TO_CHAR(T.MINEMERGENCYLIMIT) AS "minMW",
				TO_CHAR(T.MAXEMERGENCYLIMIT) AS "maxMW"
				)),
			XMLELEMENT("Regulation",
				XMLATTRIBUTES(
				TO_CHAR(T.MINREGULATIONLIMIT) AS "minMW",
				TO_CHAR(T.MAXREGULATIONLIMIT) AS "maxMW"
				)),
			XMLELEMENT("Spinning",
				XMLATTRIBUTES(
				TO_CHAR(T.MAXSPINNINGLIMIT) AS "maxMW"
				)),
			CASE WHEN T.LOWECONOMICTEMPRANGEMW IS NULL AND T.LOWECONOMICTEMPRANGETEMP IS NULL
				AND T.MIDECONOMICTEMPRANGEMW IS NULL AND T.MIDECONOMICTEMPRANGETEMP IS NULL
				AND T.HIGHECONOMICTEMPRANGEMW IS NULL AND T.HIGHECONOMICTEMPRANGETEMP IS NULL
				AND T.LOWEMERGENCYTEMPRANGEMW IS NULL AND T.LOWEMERGENCYTEMPRANGETEMP IS NULL
				AND T.MIDEMERGENCYTEMPRANGEMW IS NULL AND T.MIDEMERGENCYTEMPRANGETEMP IS NULL
				AND T.HIGHEMERGENCYTEMPRANGEMW IS NULL AND T.HIGHEMERGENCYTEMPRANGETEMP IS NULL
			THEN NULL ELSE
			XMLELEMENT("Temperature",
				CASE WHEN T.LOWECONOMICTEMPRANGEMW IS NULL AND T.LOWECONOMICTEMPRANGETEMP IS NULL
					AND T.MIDECONOMICTEMPRANGEMW IS NULL AND T.MIDECONOMICTEMPRANGETEMP IS NULL
					AND T.HIGHECONOMICTEMPRANGEMW IS NULL AND T.HIGHECONOMICTEMPRANGETEMP IS NULL
				THEN NULL ELSE
				XMLELEMENT("EconomicRange",
					CASE WHEN T.LOWECONOMICTEMPRANGEMW IS NULL AND T.LOWECONOMICTEMPRANGETEMP IS NULL THEN NULL ELSE
					XMLELEMENT("Low",
						XMLATTRIBUTES(
						TO_CHAR(T.LOWECONOMICTEMPRANGEMW) AS "MW",
						TO_CHAR(T.LOWECONOMICTEMPRANGETEMP) AS "temperature"
						)) END,
					CASE WHEN T.MIDECONOMICTEMPRANGEMW IS NULL AND T.MIDECONOMICTEMPRANGETEMP IS NULL THEN NULL ELSE
					XMLELEMENT("Middle",
						XMLATTRIBUTES(
						TO_CHAR(T.MIDECONOMICTEMPRANGEMW) AS "MW",
						TO_CHAR(T.MIDECONOMICTEMPRANGETEMP) AS "temperature"
						)) END,
					CASE WHEN T.HIGHECONOMICTEMPRANGEMW IS NULL AND T.HIGHECONOMICTEMPRANGETEMP IS NULL THEN NULL ELSE
					XMLELEMENT("High",
						XMLATTRIBUTES(
						TO_CHAR(T.HIGHECONOMICTEMPRANGEMW) AS "MW",
						TO_CHAR(T.HIGHECONOMICTEMPRANGETEMP) AS "temperature"
						)) END
					) END,
				CASE WHEN T.LOWEMERGENCYTEMPRANGEMW IS NULL AND T.LOWEMERGENCYTEMPRANGETEMP IS NULL
					AND T.MIDEMERGENCYTEMPRANGEMW IS NULL AND T.MIDEMERGENCYTEMPRANGETEMP IS NULL
					AND T.HIGHEMERGENCYTEMPRANGEMW IS NULL AND T.HIGHEMERGENCYTEMPRANGETEMP IS NULL
				THEN NULL ELSE
				XMLELEMENT("EmergencyRange",
					CASE WHEN T.LOWEMERGENCYTEMPRANGEMW IS NULL AND T.LOWEMERGENCYTEMPRANGETEMP IS NULL THEN NULL ELSE
					XMLELEMENT("Low",
						XMLATTRIBUTES(
						TO_CHAR(T.LOWEMERGENCYTEMPRANGEMW) AS "MW",
						TO_CHAR(T.LOWEMERGENCYTEMPRANGETEMP) AS "temperature"
						)) END,
					CASE WHEN T.MIDEMERGENCYTEMPRANGEMW IS NULL AND T.MIDEMERGENCYTEMPRANGETEMP IS NULL THEN NULL ELSE
					XMLELEMENT("Middle",
						XMLATTRIBUTES(
						TO_CHAR(T.MIDEMERGENCYTEMPRANGEMW) AS "MW",
						TO_CHAR(T.MIDEMERGENCYTEMPRANGETEMP) AS "temperature"
						)) END,
					CASE WHEN T.HIGHEMERGENCYTEMPRANGEMW IS NULL AND T.HIGHEMERGENCYTEMPRANGETEMP IS NULL THEN NULL ELSE
					XMLELEMENT("High",
						XMLATTRIBUTES(
						TO_CHAR(T.HIGHEMERGENCYTEMPRANGEMW) AS "MW",
						TO_CHAR(T.HIGHEMERGENCYTEMPRANGETEMP) AS "temperature"
						)) END
				) END
			) END
		), --End Default Limits

		(SELECT XMLAGG(
			CASE WHEN DSC.USECOSTBASEDSTARTUP IS NULL AND DSC.NOLOADCOST IS NULL
				AND DSC.COLDSTARTUPCOST IS NULL AND DSC.INTERMEDIATESTARTUPCOST IS NULL
				AND DSC.HOTSTARTUPCOST IS NULL
			THEN NULL ELSE
			XMLELEMENT("DefaultStartupCosts",
				XMLATTRIBUTES(TO_CHAR(DSC.INTERVAL) AS "interval"),
				XMLFOREST(DSC.USECOSTBASEDSTARTUP AS "UseCostBasedStartup",
					DSC.NOLOADCOST AS "NoLoad",
					DSC.COLDSTARTUPCOST AS "ColdStartup",
					DSC.INTERMEDIATESTARTUPCOST AS "IntermediateStartup",
					DSC.HOTSTARTUPCOST AS "HotStartup")) END)
			FROM TABLE(T.DEFAULTSTARTUPCOSTS) DSC),

		XMLELEMENT("DefaultRampRate", T.DEFAULTRAMPRATE),

		XMLELEMENT("EnergyRampRateCurve",
			(SELECT XMLAGG(XMLELEMENT("RampRate",
				XMLATTRIBUTES(
					TO_CHAR(E.MW) AS "MW",
					TO_CHAR(E.RATE) AS "rate"
				)))
			FROM TABLE(T.ENERGYRAMPRATECURVE) E
		)),

		XMLELEMENT("SpinRampRateCurve",
			(SELECT XMLAGG(XMLELEMENT("RampRate",
				XMLATTRIBUTES(
					TO_CHAR(S.MW) AS "MW",
					TO_CHAR(S.RATE) AS "rate"
				)))
			FROM TABLE(T.SPINRAMPRATECURVE) S
		)),

		XMLELEMENT("CondenseAvailable", T.CONDENSEAVAILABLE),
		XMLELEMENT("CondenseStartupCost", T.CONDENSESTARTUPCOST),
		XMLELEMENT("CondenseEnergyUsage", T.CONDENSEENERGYUSAGE),
		XMLELEMENT("CondenseNotificationTime", T.CONDENSENOTIFICATION),
		XMLELEMENT("CondenseHourlyCost", T.CONDENSEHOURLYCOST),

		XMLELEMENT("CombinedCycleParameters",
			XMLFOREST(T.CC_MIN_TIME_BETWEEN AS "MinTimeBetweenStartups",
				T.CC_ALLOW_SIMPLE_CYCLE AS "AllowSimpleCycle",
				T.CC_FACTOR AS "CombinedCycleFactor")),
		XMLELEMENT("PumpStorageParameters",
			XMLFOREST(T.PS_PUMPING_FACTOR AS "PumpingFactor",
				T.PS_INITIAL_MWH AS "InitialMWH",
				T.PS_FINAL_MWH AS "FinalMWH",
				T.PS_MAX_MWH AS "MaxMWH",
				T.PS_MIN_MWH AS "MinMWH")),
		XMLELEMENT("PumpStorageLimits",
		XMLFOREST(T.PS_MIN_GEN_MW AS "MinGenMW",
			T.PS_MIN_PUMP_MW AS "MinPumpMW"))
	)
	INTO p_SUBMIT_XML
	FROM TABLE(p_RECORDS) T;

EXCEPTION
	WHEN OTHERS THEN
	P_STATUS  := SQLCODE;
	P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_UNIT_DETAIL: ' || SQLERRM;
END GETX_SUBMIT_UNIT_DETAIL;
-----------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_SCHEDULE_DETAIL(P_XML_RESPONSE IN XMLTYPE,
                                  P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SCHED_DETAIL_TBL,
                                  P_STATUS       OUT NUMBER,
                                  P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//@location',
                          G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//@schedule',
                          G_PJM_EMKT_NAMESPACE) "SCHEDULE_NUMBER",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//@day',
                          G_PJM_EMKT_NAMESPACE) "SCHEDULE_DAY",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Market',
                          G_PJM_EMKT_NAMESPACE) "MARKET_TYPE",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//EconomicLimits//@minMW',
                          G_PJM_EMKT_NAMESPACE) "ECONOMIC_MIN_MW",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//EconomicLimits//@maxMW',
                          G_PJM_EMKT_NAMESPACE) "ECONOMIC_MAX_MW",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//EmergencyLimits//@minMW',
                          G_PJM_EMKT_NAMESPACE) "EMERGENCY_MIN_MW",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//EmergencyLimits//@maxMW',
                          G_PJM_EMKT_NAMESPACE) "EMERGENCY_MAX_MW",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//UseStartupNoLoad',
                          G_PJM_EMKT_NAMESPACE) "USE_STARTUP_NO_LOAD",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//FuelTypes//Primary',
                          G_PJM_EMKT_NAMESPACE) "PRIMARY_FUEL",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS), '//FuelTypes//Sub', G_PJM_EMKT_NAMESPACE) "SECONDARY_FUEL",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//StartupCosts//NoLoadCost',
                          G_PJM_EMKT_NAMESPACE) "NO_LOAD_COST",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//StartupCosts//ColdStartupCost',
                          G_PJM_EMKT_NAMESPACE) "COLD_STARTUP_COST",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//StartupCosts//IntermediateStartupCost',
                          G_PJM_EMKT_NAMESPACE) "INTERMEDIATE_STARTUP_COST",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//StartupCosts//HotStartupCost',
                          G_PJM_EMKT_NAMESPACE) "HOT_STARTUP_COST",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//MinimumRuntime',
                          G_PJM_EMKT_NAMESPACE) "MINIMUM_RUNTIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//MaximumRuntime',
                          G_PJM_EMKT_NAMESPACE) "MAXIMUM_RUNTIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//MinimumDowntime',
                          G_PJM_EMKT_NAMESPACE) "MINIMUM_DOWNTIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//HotToColdTime',
                          G_PJM_EMKT_NAMESPACE) "HOT_TO_COLD__TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//HotToIntermediateTime',
                          G_PJM_EMKT_NAMESPACE) "HOT_TO_INTERMEDIATE__TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//ColdStartupTime',
                          G_PJM_EMKT_NAMESPACE) "COLD_STARTUP_TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//IntermediateStartupTime',
                          G_PJM_EMKT_NAMESPACE) "INTERMEDIATE_STARTUP_TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//HotStartupTime',
                          G_PJM_EMKT_NAMESPACE) "HOT_STARTUP_TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//ColdNotificationTime',
                          G_PJM_EMKT_NAMESPACE) "COLD_NOTIFICATION_TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//IntermediateNotificationTime',
                          G_PJM_EMKT_NAMESPACE) "INTERMEDIATE_NOTIFICATION_TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//HotNotificationTime',
                          G_PJM_EMKT_NAMESPACE) "HOT_NOTIFICATION_TIME",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//MaximumDailyStarts',
                          G_PJM_EMKT_NAMESPACE) "MAXIMUM_DAILY_STARTS",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//MaximumWeeklyStarts',
                          G_PJM_EMKT_NAMESPACE) "MAXIMUM_WEEKLY_STARTS",
             EXTRACTVALUE(VALUE(SCHEDULE_DETAILS),
                          '//Runtimes//MaximumWeeklyEnergy',
                          G_PJM_EMKT_NAMESPACE) "MAXIMUM_WEEKLY_ENERGY"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//ScheduleDetail',
                                       G_PJM_EMKT_NAMESPACE))) SCHEDULE_DETAILS;
/*             TABLE(XMLSEQUENCE(EXTRACT(VALUE(SCHEDULE_DETAILS),
                                       '//Runtimes',
                                       G_PJM_EMKT_NAMESPACE))) RUNTIMES,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(SCHEDULE_DETAILS),
                                       '//StartupCosts',
                                       G_PJM_EMKT_NAMESPACE))) STARTUP_COSTS,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(SCHEDULE_DETAILS),
                                       '//FuelTypes',
                                       G_PJM_EMKT_NAMESPACE))) FUEL_TYPES;*/

  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SCHED_DETAIL(V_XML.LOCATION,
                                                             TO_NUMBER(V_XML.SCHEDULE_NUMBER),
                                                             TO_DATE(V_XML.SCHEDULE_DAY,G_DATE_FORMAT),
                                                             V_XML.MARKET_TYPE,
                                                             TO_NUMBER(V_XML.ECONOMIC_MIN_MW),
                                                             TO_NUMBER(V_XML.ECONOMIC_MAX_MW),
                                                             TO_NUMBER(V_XML.EMERGENCY_MIN_MW),
                                                             TO_NUMBER(V_XML.EMERGENCY_MAX_MW),
                                                             V_XML.USE_STARTUP_NO_LOAD,
                                                             V_XML.PRIMARY_FUEL,
                                                             V_XML.SECONDARY_FUEL,
                                                             TO_NUMBER(V_XML.NO_LOAD_COST),
                                                             TO_NUMBER(V_XML.COLD_STARTUP_COST),
                                                             TO_NUMBER(V_XML.INTERMEDIATE_STARTUP_COST),
                                                             TO_NUMBER(V_XML.HOT_STARTUP_COST),
                                                             TO_NUMBER(V_XML.MINIMUM_RUNTIME),
                                                             TO_NUMBER(V_XML.MAXIMUM_RUNTIME),
                                                             TO_NUMBER(V_XML.MINIMUM_DOWNTIME),
                                                             TO_NUMBER(V_XML.HOT_TO_COLD__TIME),
                                                             TO_NUMBER(V_XML.HOT_TO_INTERMEDIATE__TIME),
                                                             TO_NUMBER(V_XML.COLD_STARTUP_TIME),
                                                             TO_NUMBER(V_XML.INTERMEDIATE_STARTUP_TIME),
                                                             TO_NUMBER(V_XML.HOT_STARTUP_TIME),
                                                             TO_NUMBER(V_XML.COLD_NOTIFICATION_TIME),
                                                             TO_NUMBER(V_XML.INTERMEDIATE_NOTIFICATION_TIME),
                                                             TO_NUMBER(V_XML.HOT_NOTIFICATION_TIME),
                                                             TO_NUMBER(V_XML.MAXIMUM_DAILY_STARTS),
                                                             TO_NUMBER(V_XML.MAXIMUM_WEEKLY_STARTS),
                                                             TO_NUMBER(V_XML.MAXIMUM_WEEKLY_ENERGY));

    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SCHEDULE_DETAIL: ' ||
                   SQLERRM;
  END PARSE_SCHEDULE_DETAIL;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SCHEDULE_DETAIL(p_LOCATION_TYPE IN VARCHAR2,
  									   p_LOCATION_NAME IN VARCHAR2,
									   p_REQUEST_DATE  IN DATE,
                                       P_XML_REQUEST_BODY OUT XMLTYPE,
                                       P_STATUS           OUT NUMBER,
                                       P_MESSAGE          OUT VARCHAR2) AS

    V_XML_FRAGMENT  XMLTYPE;

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    -- generate the request xml, parsing the template name into the schedule
    v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);
--UT.DEBUG_TRACE('GETX_QUERY_UNIT_UPDATES xmlvalue : ' || v_XML_FRAGMENT.getStringVal());
--UT.DEBUG_TRACE('GETX_QUERY_UNIT_UPDATES datevalue : ' || P_PARAMETER_MAP('RequestDate'));


    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryAllScheduleDetail",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
                                 V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SCHEDULE_DETAIL: ' ||
                   SQLERRM;
  END GETX_QUERY_SCHEDULE_DETAIL;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_SCHEDULE_DETAIL(p_RECORDS       IN MEX_PJM_EMKT_SCHED_DETAIL_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("ScheduleDetail",
                      XMLATTRIBUTES(TO_CHAR(TRUNC(T.SCHEDULE_DAY),'YYYY-MM-DD') AS "day",
                                    T.LOCATION AS "location",
                                    TO_CHAR(T.SCHEDULE_NUMBER) AS "schedule"
                                   ),
                           XMLELEMENT("Market", T.MARKET_TYPE),
                           XMLELEMENT("EconomicLimits",
                                    XMLATTRIBUTES(
                                                  T.ECONOMIC_MIN_MW AS "minMW",
                                                  T.ECONOMIC_MAX_MW AS "maxMW"
                                                 )),
                           XMLELEMENT("EmergencyLimits",
                                    XMLATTRIBUTES(
                                                  T.EMERGENCY_MIN_MW AS "minMW",
                                                  T.EMERGENCY_MAX_MW AS "maxMW"
                                                 )),
                           XMLELEMENT("Runtimes",
                                    XMLELEMENT("MinimumRuntime", T.MINIMUM_RUNTIME),
                                    XMLELEMENT("MaximumRuntime", T.MAXIMUM_RUNTIME),
                                    XMLELEMENT("MinimumDowntime", T.MINIMUM_DOWNTIME),
                                    XMLELEMENT("HotToColdTime", T.HOT_TO_COLD__TIME),
                                    XMLELEMENT("HotToIntermediateTime", T.HOT_TO_INTERMEDIATE__TIME),
                                    XMLELEMENT("ColdStartupTime", T.COLD_STARTUP_TIME),
                                    XMLELEMENT("IntermediateStartupTime", T.INTERMEDIATE_STARTUP_TIME),
                                    XMLELEMENT("HotStartupTime", T.HOT_STARTUP_TIME),
                                    XMLELEMENT("ColdNotificationTime", T.COLD_NOTIFICATION_TIME),
                                    XMLELEMENT("IntermediateNotificationTime", T.INTERMEDIATE_NOTIFICATION_TIME),
                                    XMLELEMENT("HotNotificationTime", T.HOT_NOTIFICATION_TIME),
                                    XMLELEMENT("MaximumDailyStarts", T.MAXIMUM_DAILY_STARTS),
                                    XMLELEMENT("MaximumWeeklyStarts", T.MAXIMUM_WEEKLY_STARTS),
                                    XMLELEMENT("MaximumWeeklyEnergy", T.MAXIMUM_WEEKLY_ENERGY)),
                           XMLELEMENT("UseStartupNoLoad", T.USE_STARTUP_NO_LOAD),
                           XMLELEMENT("StartupCosts",
                                    XMLELEMENT("NoLoadCost", T.NO_LOAD_COST),
                                    XMLELEMENT("ColdStartupCost", T.COLD_STARTUP_COST),
                                    XMLELEMENT("IntermediateStartupCost", T.INTERMEDIATE_STARTUP_COST),
                                    XMLELEMENT("HotStartupCost", T.HOT_STARTUP_COST)),
                           XMLELEMENT("FuelTypes",
                                    XMLELEMENT("Primary", T.PRIMARY_FUEL),
                                    XMLELEMENT("Sub", T.SECONDARY_FUEL))
                             )
      INTO p_SUBMIT_XML
      FROM TABLE(p_RECORDS) T;


  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_SCHEDULE_SELECTION: ' ||
                   SQLERRM;
  END GETX_SUBMIT_SCHEDULE_DETAIL;
  -----------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_SCHEDULE_DETAIL(P_CRED          IN mex_credentials,
  							   	  P_LOG_ONLY      IN BINARY_INTEGER,
								  P_LOCATION_TYPE IN VARCHAR2,
								  P_LOCATION_NAME IN VARCHAR2,
								  P_REQUEST_DATE  IN DATE,
                                  P_RECORDS       OUT MEX_PJM_EMKT_SCHED_DETAIL_TBL,
                                  P_STATUS        OUT NUMBER,
                                  P_MESSAGE       OUT VARCHAR2,
								  p_LOGGER		  IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_SCHED_DETAIL_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_SCHEDULE_DETAIL(P_LOCATION_TYPE,P_LOCATION_NAME,P_REQUEST_DATE,
                               V_XML_REQUEST,
                               P_STATUS,
                               P_MESSAGE);

    --SENDING THE XML REQUEST
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

    PARSE_SCHEDULE_DETAIL(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SCHEDULE_DETAIL: ' ||
                   SQLERRM;
  END FETCH_SCHEDULE_DETAIL;
  -----------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_VIRTUAL_BIDS(P_XML_RESPONSE IN XMLTYPE,
															 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_VIRTUAL_BIDS_TBL,
															 P_STATUS       OUT NUMBER,
															 P_MESSAGE      OUT VARCHAR2) AS

-- for whatever reason, this cursor throws ORA-22905 cannot access rows from a non-nested table item.
-- From the Oracle doc:
--    Cause: An attempt was made to access rows of an item whose type is not known at
--           parse time or that is not of a nested table type.
--    Action: Use CAST to cast the item to a nested table type.
/*		CURSOR C_XML IS
			SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/VirtualBid/@day', g_PJM_EMKT_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DATE",
						 EXTRACTVALUE(VALUE(T), '/VirtualBid/@location', g_PJM_EMKT_NAMESPACE) "LOCATION",
						 TO_NUMBER(EXTRACTVALUE(VALUE(U), '/VirtualBidHourly/@hour', g_PJM_EMKT_NAMESPACE)) "HOUR",
						 TO_NUMBER(EXTRACTVALUE(VALUE(V), '/BidSegment/@id', g_PJM_EMKT_NAMESPACE)) "SEGMENT_ID",
						 TO_NUMBER(EXTRACTVALUE(VALUE(V), '/BidSegment/MW', g_PJM_EMKT_NAMESPACE)) "QUANTITY",
						 TO_NUMBER(EXTRACTVALUE(VALUE(V), '/BidSegment/Price', g_PJM_EMKT_NAMESPACE)) "PRICE",
						 'INC' AS "INC_DEC_TYPE"
				FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, '//VirtualBid', g_PJM_EMKT_NAMESPACE))) T,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
																			 '//Increment/VirtualBidHourly',
																			 g_PJM_EMKT_NAMESPACE))) U,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//BidSegment', g_PJM_EMKT_NAMESPACE))) V
			UNION ALL
			SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/VirtualBid/@day', g_PJM_EMKT_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DATE",
						 EXTRACTVALUE(VALUE(T), '/VirtualBid/@location', g_PJM_EMKT_NAMESPACE) "LOCATION",
						 TO_NUMBER(EXTRACTVALUE(VALUE(W), '/VirtualBidHourly/@hour', g_PJM_EMKT_NAMESPACE)) "HOUR",
						 TO_NUMBER(EXTRACTVALUE(VALUE(X), '/BidSegment/@id', g_PJM_EMKT_NAMESPACE)) "SEGMENT_ID",
						 TO_NUMBER(EXTRACTVALUE(VALUE(X), '/BidSegment/MW', g_PJM_EMKT_NAMESPACE)) "QUANTITY",
						 TO_NUMBER(EXTRACTVALUE(VALUE(X), '/BidSegment/Price', g_PJM_EMKT_NAMESPACE)) "PRICE",
						 'DEC' AS "INC_DEC_TYPE"
				FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, '//VirtualBid', g_PJM_EMKT_NAMESPACE))) T,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
																			 '//Decrement/VirtualBidHourly',
																			 g_PJM_EMKT_NAMESPACE))) W,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(W), '//BidSegment', g_PJM_EMKT_NAMESPACE))) X
			 ORDER BY INC_DEC_TYPE, LOCATION, RESPONSE_DATE, HOUR, SEGMENT_ID;
*/
      CURSOR C_XML_INC IS
			SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/VirtualBid/@day', g_PJM_EMKT_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DATE",
						 EXTRACTVALUE(VALUE(T), '/VirtualBid/@location', g_PJM_EMKT_NAMESPACE) "LOCATION",
						 TO_NUMBER(EXTRACTVALUE(VALUE(U), '/VirtualBidHourly/@hour', g_PJM_EMKT_NAMESPACE)) "HOUR",
						 EXTRACTVALUE(VALUE(u), '/VirtualBidHourly/@isDuplicateHour', g_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
						 TO_NUMBER(EXTRACTVALUE(VALUE(V), '/BidSegment/@id', g_PJM_EMKT_NAMESPACE)) "SEGMENT_ID",
						 TO_NUMBER(EXTRACTVALUE(VALUE(V), '/BidSegment/MW', g_PJM_EMKT_NAMESPACE)) "QUANTITY",
						 TO_NUMBER(EXTRACTVALUE(VALUE(V), '/BidSegment/Price', g_PJM_EMKT_NAMESPACE)) "PRICE",
						 'INC' AS "INC_DEC_TYPE"
				FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, '//VirtualBid', g_PJM_EMKT_NAMESPACE))) T,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
																			 '//Increment/VirtualBidHourly',
																			 g_PJM_EMKT_NAMESPACE))) U,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//BidSegment', g_PJM_EMKT_NAMESPACE))) V
			 ORDER BY INC_DEC_TYPE, LOCATION, RESPONSE_DATE, HOUR, SEGMENT_ID;

      CURSOR C_XML_DEC IS
			SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/VirtualBid/@day', g_PJM_EMKT_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DATE",
						 EXTRACTVALUE(VALUE(T), '/VirtualBid/@location', g_PJM_EMKT_NAMESPACE) "LOCATION",
						 TO_NUMBER(EXTRACTVALUE(VALUE(W), '/VirtualBidHourly/@hour', g_PJM_EMKT_NAMESPACE)) "HOUR",
						 EXTRACTVALUE(VALUE(W), '/VirtualBidHourly/@isDuplicateHour', g_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
						 TO_NUMBER(EXTRACTVALUE(VALUE(X), '/BidSegment/@id', g_PJM_EMKT_NAMESPACE)) "SEGMENT_ID",
						 TO_NUMBER(EXTRACTVALUE(VALUE(X), '/BidSegment/MW', g_PJM_EMKT_NAMESPACE)) "QUANTITY",
						 TO_NUMBER(EXTRACTVALUE(VALUE(X), '/BidSegment/Price', g_PJM_EMKT_NAMESPACE)) "PRICE",
						 'DEC' AS "INC_DEC_TYPE"
				FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE, '//VirtualBid', g_PJM_EMKT_NAMESPACE))) T,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
																			 '//Decrement/VirtualBidHourly',
																			 g_PJM_EMKT_NAMESPACE))) W,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(W), '//BidSegment', g_PJM_EMKT_NAMESPACE))) X
			 ORDER BY INC_DEC_TYPE, LOCATION, RESPONSE_DATE, HOUR, SEGMENT_ID;


	BEGIN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		FOR V_XML IN C_XML_INC LOOP
			P_RECORDS.EXTEND();
			P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_VIRTUAL_BIDS(TO_CUT(DUPLICATE_DATE(V_XML.RESPONSE_DATE + TO_NUMBER(V_XML.HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE),
                                                                    V_XML.LOCATION,
                                                                    V_XML.SEGMENT_ID,
                                                                    V_XML.QUANTITY,
                                                                    V_XML.PRICE,
                                                                    V_XML.INC_DEC_TYPE);

		END LOOP;

		FOR V_XML IN C_XML_DEC LOOP
			P_RECORDS.EXTEND();
			P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_VIRTUAL_BIDS(TO_CUT(DUPLICATE_DATE(V_XML.RESPONSE_DATE + TO_NUMBER(V_XML.HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE),
                                                                    V_XML.LOCATION,
                                                                    V_XML.SEGMENT_ID,
                                                                    V_XML.QUANTITY,
                                                                    V_XML.PRICE,
                                                                    V_XML.INC_DEC_TYPE);

		END LOOP;

	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_VIRTUAL_BIDS: ' || SQLERRM;
	END PARSE_VIRTUAL_BIDS;
  ------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_VIRTUAL_BIDS(p_LOCATION_TYPE IN VARCHAR2,
  									p_LOCATION_NAME IN VARCHAR2,
									p_REQUEST_DATE  IN DATE,
                                    p_XML_REQUEST_BODY OUT XMLTYPE,
                                    p_STATUS           OUT NUMBER,
                                    p_MESSAGE          OUT VARCHAR2) AS

	v_XML_FRAGMENT XMLTYPE;

  BEGIN

    p_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryVirtualBid",
                                  XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT)
                                                AS "day"),
                                 V_XML_FRAGMENT))
      INTO p_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_VIRUAL_BIDS: ' ||
                   SQLERRM;
  END GETX_QUERY_VIRTUAL_BIDS;
  --------------------------------------------------------------------------------------------------------
	PROCEDURE FETCH_VIRTUAL_BIDS(p_CRED 		 IN mex_credentials,
								 p_LOG_ONLY		 IN BINARY_INTEGER,
								 p_LOCATION_TYPE IN VARCHAR2,
								 p_LOCATION_NAME IN VARCHAR2,
								 p_REQUEST_DATE  IN DATE,
								 p_RECORDS       OUT MEX_PJM_EMKT_VIRTUAL_BIDS_TBL,
								 p_STATUS        OUT NUMBER,
								 p_MESSAGE       OUT VARCHAR2,
								 p_LOGGER		 IN OUT mm_logger_adapter) AS

		v_XML_REQUEST  XMLTYPE;
		v_XML_RESPONSE XMLTYPE;
	BEGIN

		p_RECORDS := MEX_PJM_EMKT_VIRTUAL_BIDS_TBL();
		p_STATUS  := MEX_UTIL.G_SUCCESS;

		GETX_QUERY_VIRTUAL_BIDS(p_LOCATION_TYPE, p_LOCATION_NAME, p_REQUEST_DATE, v_XML_REQUEST, p_STATUS, p_MESSAGE);

		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		    RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);


			IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
				PARSE_VIRTUAL_BIDS(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);
			END IF;
		END IF;

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_VIRTUAL_BIDS: ' || SQLERRM;
	END FETCH_VIRTUAL_BIDS;
  ----------------------------------------------------------------------------------------------------------------------
	PROCEDURE PARSE_DEMAND_BIDS(P_XML_RESPONSE IN XMLTYPE,
															P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_DEMAND_BID_TBL,
															P_STATUS       OUT NUMBER,
															P_MESSAGE      OUT VARCHAR2) AS

		CURSOR c_FIXED IS
			SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/DemandBid/@day', G_PJM_EMKT_NAMESPACE),
										 G_DATE_FORMAT) RESPONSE_DATE,
						 EXTRACTVALUE(VALUE(T), '/DemandBid/@location', G_PJM_EMKT_NAMESPACE) LOCATION,
						 EXTRACTVALUE(VALUE(U), '/DemandBidHourly/@hour', G_PJM_EMKT_NAMESPACE) HOUR,
                         EXTRACTVALUE(VALUE(U), '/DemandBidHourly/@isDuplicateHour', G_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
						 EXTRACTVALUE(VALUE(U),
													'/DemandBidHourly/FixedDemand',
													G_PJM_EMKT_NAMESPACE) FIXED_DEMAND
				FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
																			 '//DemandBid',
																			 G_PJM_EMKT_NAMESPACE))) T,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
																			 '//DemandBidHourly',
																			 G_PJM_EMKT_NAMESPACE))) U;

		CURSOR c_PRICE_SENSITIVE IS
			SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/DemandBid/@day', G_PJM_EMKT_NAMESPACE),
										 G_DATE_FORMAT) RESPONSE_DATE,
						 EXTRACTVALUE(VALUE(T), '/DemandBid/@location', G_PJM_EMKT_NAMESPACE) LOCATION,
						 EXTRACTVALUE(VALUE(U), '/DemandBidHourly/@hour', G_PJM_EMKT_NAMESPACE) HOUR,
                         EXTRACTVALUE(VALUE(U), '/DemandBidHourly/@isDuplicateHour', G_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
						 EXTRACTVALUE(VALUE(V), '/BidSegment/@id', G_PJM_EMKT_NAMESPACE) SEGMENT_ID,
						 EXTRACTVALUE(VALUE(V), '/BidSegment/MW', G_PJM_EMKT_NAMESPACE) QUANTITY,
						 EXTRACTVALUE(VALUE(V), '/BidSegment/Price', G_PJM_EMKT_NAMESPACE) PRICE
				FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
																			 '//DemandBid',
																			 G_PJM_EMKT_NAMESPACE))) T,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
																			 '//DemandBidHourly',
																			 G_PJM_EMKT_NAMESPACE))) U,
						 TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),
																			 '//BidSegment',
																			 G_PJM_EMKT_NAMESPACE))) V;

	BEGIN
		p_STATUS := MEX_UTIL.g_SUCCESS;

		FOR V_XML IN c_FIXED LOOP
			P_RECORDS.EXTEND();
			P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_DEMAND_BID(TO_CUT_WITH_OPTIONS(DUPLICATE_DATE(V_XML.RESPONSE_DATE + TO_NUMBER(V_XML.HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION),
																	 V_XML.LOCATION,
																	 V_XML.HOUR,
																	 v_XML.FIXED_DEMAND,
																	 NULL,
																	 NULL,
																	 NULL);

		END LOOP;
		FOR V_XML IN c_PRICE_SENSITIVE LOOP
			P_RECORDS.EXTEND();
			P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_DEMAND_BID(TO_CUT_WITH_OPTIONS(DUPLICATE_DATE(V_XML.RESPONSE_DATE + TO_NUMBER(V_XML.HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION),
																													 V_XML.LOCATION,
																													 V_XML.HOUR,
																													 NULL,
																													 V_XML.SEGMENT_ID,
																													 V_XML.QUANTITY,
																													 V_XML.PRICE);

		END LOOP;
	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_DEMAND_BIDS: ' || SQLERRM;
	END PARSE_DEMAND_BIDS;
  ------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_DEMAND_BIDS(p_LOCATION_TYPE IN VARCHAR2,
  								   p_LOCATION_NAME IN VARCHAR2,
								   p_BEGIN_DATE	   IN DATE,
								   p_END_DATE	   IN DATE,
								   p_XML_REQUEST_BODY OUT XMLTYPE,
								   p_STATUS           OUT NUMBER,
								   p_MESSAGE          OUT VARCHAR2) AS

  	v_XML_FRAGMENT XMLTYPE;
  	v_XML_DATES    xmlsequencetype := xmlsequencetype();
  	I              BINARY_INTEGER;
  	v_DATE         DATE;
  	v_END_DATE     DATE;

  BEGIN
  	p_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

  	v_DATE     := p_BEGIN_DATE;
  	v_END_DATE := p_END_DATE;
  	I          := 1;
  	LOOP
  		v_XML_DATES.EXTEND();
  		SELECT XMLELEMENT("QueryDemandBid",
  											XMLATTRIBUTES(TO_CHAR(v_DATE, g_DATE_FORMAT) AS "day"),
                        V_XML_FRAGMENT)
  			INTO v_XML_DATES(I)
  			FROM DUAL;
  		v_DATE := v_DATE + 1;
  		I      := I + 1;
  		EXIT WHEN v_DATE > v_END_DATE;
  	END LOOP;

  	SELECT XMLELEMENT("QueryRequest",
  										XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
  										XMLCONCAT(v_XML_DATES))
  		INTO P_XML_REQUEST_BODY
  		FROM DUAL;

  EXCEPTION
  	WHEN OTHERS THEN
  		P_STATUS  := SQLCODE;
  		P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_DEMAND_BIDS: ' || SQLERRM;
  END GETX_QUERY_DEMAND_BIDS;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_DEMAND_BIDS(P_CRED          IN mex_credentials,
  							  P_LOG_ONLY      IN BINARY_INTEGER,
							  P_LOCATION_TYPE IN VARCHAR2,
							  P_LOCATION_NAME IN VARCHAR2,
							  P_BEGIN_DATE    IN DATE,
							  P_END_DATE      IN DATE,
							  P_RECORDS       OUT MEX_PJM_EMKT_DEMAND_BID_TBL,
							  P_STATUS        OUT NUMBER,
							  P_MESSAGE       OUT VARCHAR2,
							  P_LOGGER		  IN OUT mm_logger_adapter) AS

  	V_XML_REQUEST  XMLTYPE;
  	V_XML_RESPONSE XMLTYPE;

  BEGIN

  	P_RECORDS := MEX_PJM_EMKT_DEMAND_BID_TBL();
  	P_STATUS  := MEX_UTIL.G_SUCCESS;

  	GETX_QUERY_DEMAND_BIDS(P_LOCATION_TYPE, P_LOCATION_NAME, P_BEGIN_DATE, P_END_DATE, V_XML_REQUEST, P_STATUS, P_MESSAGE);

  	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
  		RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

  		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
  			PARSE_DEMAND_BIDS(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);
  		END IF;
  	END IF;

  EXCEPTION
  	WHEN OTHERS THEN
  		P_STATUS  := SQLCODE;
  		P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_DEMAND_BIDS: ' || SQLERRM;
  END FETCH_DEMAND_BIDS;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_PRICE_SENSITIVE_DEMAND(P_XML_RESPONSE IN XMLTYPE,
                                         P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_PRICE_SEN_DMD_TBL,
                                         P_STATUS       OUT NUMBER,
                                         P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/DemandBid/@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(T), '/DemandBid/@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(U), '/DemandBidHourly/@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
             EXTRACTVALUE(VALUE(V), '/BidSegment/@id', G_PJM_EMKT_NAMESPACE) "SEGMENT_ID",
             EXTRACTVALUE(VALUE(V), '/BidSegment/MW', G_PJM_EMKT_NAMESPACE) "QUANTITY",
             EXTRACTVALUE(VALUE(V), '/BidSegment/Price', G_PJM_EMKT_NAMESPACE) "PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//DemandBid',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//DemandBidHourly',
                                       G_PJM_EMKT_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),
                                       '//BidSegment',
                                       G_PJM_EMKT_NAMESPACE))) V;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_PRICE_SEN_DMD(V_XML.RESPONSE_DATE,
                                                              V_XML.LOCATION,
                                                              V_XML.HOUR,
                                                              V_XML.SEGMENT_ID,
                                                              V_XML.QUANTITY,
                                                              V_XML.PRICE);

    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_PRICE_SENSITIVE_DEMAND: ' ||
                   SQLERRM;
  END PARSE_PRICE_SENSITIVE_DEMAND;
  ------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_PRICE_SENSITIVE_DMD(P_LOCATION_TYPE IN VARCHAR2,
										   P_LOCATION_NAME IN VARCHAR2,
										   P_REQUEST_DATE  IN DATE,
                                           P_XML_REQUEST_BODY OUT XMLTYPE,
                                           P_STATUS           OUT NUMBER,
                                           P_MESSAGE          OUT VARCHAR2) AS

    V_XML_FRAGMENT XMLTYPE;

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(P_LOCATION_TYPE, P_LOCATION_NAME);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryDemandBid",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT)
                                                AS "day"),
                                 v_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_PRICE_SENSITIVE_DEMAND: ' ||
                   SQLERRM;
  END GETX_QUERY_PRICE_SENSITIVE_DMD;
  --------------------------------------------------------------------------------------------------------
   PROCEDURE FETCH_PRICE_SENSITIVE_DEMAND(P_CRED          IN mex_credentials,
  							   			  P_LOG_ONLY      IN BINARY_INTEGER,
										  P_LOCATION_TYPE IN VARCHAR2,
										  P_LOCATION_NAME IN VARCHAR2,
										  P_REQUEST_DATE  IN DATE,
										  P_RECORDS       OUT MEX_PJM_EMKT_PRICE_SEN_DMD_TBL,
										  P_STATUS        OUT NUMBER,
										  P_MESSAGE       OUT VARCHAR2,
										  P_LOGGER		  IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;

  BEGIN

    P_RECORDS := MEX_PJM_EMKT_PRICE_SEN_DMD_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_PRICE_SENSITIVE_DMD(P_LOCATION_TYPE, P_LOCATION_NAME, P_REQUEST_DATE,
                                   V_XML_REQUEST,
                                   P_STATUS,
                                   P_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

      IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    	PARSE_PRICE_SENSITIVE_DEMAND(V_XML_RESPONSE,
                                 P_RECORDS,
                                 P_STATUS,
                                 P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_PRICE_SENSITIVE_DEMAND: ' ||
                   SQLERRM;
  END FETCH_PRICE_SENSITIVE_DEMAND;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_FIXED_DEMAND(P_XML_RESPONSE IN XMLTYPE,
                               P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_FIXED_DEMAND_TBL,
                               P_STATUS       OUT NUMBER,
                               P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/DemandBid/@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(T), '/DemandBid/@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(U), '/DemandBidHourly/@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
             EXTRACTVALUE(VALUE(U), '/DemandBidHourly/FixedDemand', G_PJM_EMKT_NAMESPACE) "FIXED_DEMAND"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//DemandBid',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//DemandBidHourly',
                                       G_PJM_EMKT_NAMESPACE))) U;
  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_FIXED_DEMAND(V_XML.RESPONSE_DATE,
                                                             V_XML.LOCATION,
                                                             V_XML.HOUR,
                                                             V_XML.FIXED_DEMAND);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_FIXED_DEMAND: ' || SQLERRM;
  END PARSE_FIXED_DEMAND;
  ------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_FIXED_DEMAND(P_LOCATION_TYPE IN VARCHAR2,
  									P_LOCATION_NAME IN VARCHAR2,
									P_REQUEST_DATE  IN DATE,
                                    P_XML_REQUEST_BODY OUT XMLTYPE,
                                    P_STATUS           OUT NUMBER,
                                    P_MESSAGE          OUT VARCHAR2) AS

    V_XML_FRAGMENT XMLTYPE;

  BEGIN

    P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(P_LOCATION_TYPE, P_LOCATION_NAME);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryDemandBid",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT)
                                                AS "day"),
                                 v_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_FIXED_DEMAND: ' ||
                   SQLERRM;
  END GETX_QUERY_FIXED_DEMAND;

    ------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_BY_TRANSACTION_ID(P_TRANSACTION_ID   IN VARCHAR2,
                                         P_XML_REQUEST_BODY OUT XMLTYPE,
                                         P_STATUS           OUT NUMBER,
                                         P_MESSAGE          OUT VARCHAR2) AS

  BEGIN

    P_STATUS := MEX_UTIL.G_SUCCESS;

    SELECT XMLELEMENT("QueryByTransaction",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("TransactionID",P_TRANSACTION_ID))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_BY_TRANSACTION_ID: ' ||
                   SQLERRM;
  END GETX_QUERY_BY_TRANSACTION_ID;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_FIXED_DEMAND(P_CRED          IN mex_credentials,
  							   P_LOG_ONLY      IN BINARY_INTEGER,
  							   P_LOCATION_TYPE IN VARCHAR2,
							   P_LOCATION_NAME IN VARCHAR2,
							   P_REQUEST_DATE  IN DATE,
                               P_RECORDS       OUT MEX_PJM_EMKT_FIXED_DEMAND_TBL,
                               P_STATUS        OUT NUMBER,
                               P_MESSAGE       OUT VARCHAR2,
							   P_LOGGER			IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_FIXED_DEMAND_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_FIXED_DEMAND(P_LOCATION_TYPE,P_LOCATION_NAME, P_REQUEST_DATE,
                            V_XML_REQUEST,
                            P_STATUS,
                            P_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

      IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        PARSE_FIXED_DEMAND(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_FIXED_DEMAND: ' || SQLERRM;
  END FETCH_FIXED_DEMAND;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_RESPONSE_FOR_TRANSACTION(p_CRED          IN mex_credentials,
  							   			   p_LOG_ONLY      IN BINARY_INTEGER,
										   p_TRANSACTION_ID   IN VARCHAR2,
                                           p_XML_RESPONSE  OUT XMLTYPE,
                                           p_STATUS        OUT NUMBER,
                                           p_MESSAGE       OUT VARCHAR2,
										   p_LOGGER		   IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
  BEGIN

    p_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_BY_TRANSACTION_ID(P_TRANSACTION_ID,
                                 v_XML_REQUEST,
                                 p_STATUS,
                                 p_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, p_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);

    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_RESPONSE_FOR_TRANSACTION: ' || SQLERRM;
  END FETCH_RESPONSE_FOR_TRANSACTION;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_FIXED_DEMAND(p_RECORDS       IN MEX_PJM_EMKT_FIXED_DEMAND_TBL,
                                     p_SUBMIT_XML    OUT XMLTYPE,
                                     p_STATUS        OUT NUMBER,
                                     p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("DemandBid",
		XMLATTRIBUTES(MEX_PJM_EMKT.GET_DATE(T.RESPONSE_DATE) AS "day", T.LOCATION AS "location"),
			(XMLAGG
				(XMLELEMENT("DemandBidHourly",
					XMLATTRIBUTES(
						GET_HOUR(T.RESPONSE_DATE) AS "hour",
						GET_ISDUPLICATE(T.RESPONSE_DATE) AS "isDuplicateHour"
					),
					XMLELEMENT("FixedDemand", TO_CHAR(T.FIXED_DEMAND))
			))))
	INTO p_SUBMIT_XML
	FROM TABLE(p_RECORDS) T
	GROUP BY T.LOCATION,GET_DATE(T.RESPONSE_DATE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_FIXED_DEMAND: ' ||
                   SQLERRM;
  END GETX_SUBMIT_FIXED_DEMAND;
	----------------------------------------------------------------------------------------------------------------------
	PROCEDURE SUBMIT_FIXED_DEMAND(p_CRED			  IN mex_credentials,
								  p_LOG_ONLY		  IN BINARY_INTEGER,
								  p_RECORDS       IN MEX_PJM_EMKT_FIXED_DEMAND_TBL,
								  p_STATUS        OUT NUMBER,
								  p_MESSAGE       OUT VARCHAR2,
								  p_LOGGER		  IN OUT mm_logger_adapter) IS
    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;

  BEGIN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		GETX_SUBMIT_FIXED_DEMAND(p_RECORDS, v_XML_REQUEST, p_STATUS, p_MESSAGE);


    IF p_STATUS = 0 THEN
		  RUN_PJM_SUBMIT(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, P_STATUS, p_MESSAGE, p_LOGGER);
    END IF;

	EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EMKT.SUBMIT_FIXED_DEMAND: ' || SQLERRM;
	END SUBMIT_FIXED_DEMAND;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_PRICE_SENS_DEMAND(p_RECORDS       IN MEX_PJM_EMKT_PRICE_SEN_DMD_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("DemandBid",
			  XMLATTRIBUTES(GET_DATE(T.RESPONSE_DATE) AS "day", T.LOCATION AS "location"),
				   (SELECT XMLAGG(XMLELEMENT("DemandBidHourly",
						XMLATTRIBUTES(GET_HOUR(T.RESPONSE_DATE) AS "hour",
									  GET_ISDUPLICATE(T.RESPONSE_DATE) AS "isDuplicateHour"),
						XMLELEMENT("PriceSensitiveDemand",
						   XMLAGG(XMLELEMENT("BidSegment",
							  XMLATTRIBUTES(TO_CHAR(T.SEGMENT_ID) AS "id"),
								  XMLELEMENT("MW",TO_CHAR(T.QUANTITY)),
								  XMLELEMENT("Price",TO_CHAR(T.PRICE)))))))
											FROM TABLE(p_RECORDS) T GROUP BY GET_HOUR(T.RESPONSE_DATE), GET_ISDUPLICATE(T.RESPONSE_DATE))                      
			)
	INTO p_SUBMIT_XML
	FROM TABLE(p_RECORDS) T
	GROUP BY GET_DATE(T.RESPONSE_DATE), T.LOCATION;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_PRICE_SENS_DEMAND: ' ||
                   SQLERRM;
  END GETX_SUBMIT_PRICE_SENS_DEMAND;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE SUBMIT_PRICE_SENSIT_DEMAND_BID(p_CRED			  IN mex_credentials,
								  		   p_LOG_ONLY		  IN BINARY_INTEGER,
                                           p_RECORDS       IN MEX_PJM_EMKT_PRICE_SEN_DMD_TBL,
                                           p_STATUS        OUT NUMBER,
                                           p_MESSAGE       OUT VARCHAR2,
										   p_LOGGER		  IN OUT mm_logger_adapter) IS
    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    GETX_SUBMIT_PRICE_SENS_DEMAND(p_RECORDS,
                                  v_XML_REQUEST,
                                  p_STATUS,
                                  p_MESSAGE);


    IF p_STATUS = 0 THEN
      RUN_PJM_SUBMIT(p_CRED, p_LOG_ONLY,
                     v_XML_REQUEST,
                     v_XML_RESPONSE,
					 p_STATUS,
                     p_MESSAGE,
					 p_LOGGER);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.SUBMIT_PRICE_SENSIT_DEMAND_BID: ' ||
                   SQLERRM;
  END SUBMIT_PRICE_SENSIT_DEMAND_BID;
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE SUBMIT_VIRTUAL_BID(p_CRED			  IN mex_credentials,
							   p_LOG_ONLY		  IN BINARY_INTEGER,
                               p_XML_REQUEST   IN XMLTYPE,
                               p_STATUS        OUT NUMBER,
                               p_MESSAGE       OUT VARCHAR2,
							   p_LOGGER		  IN OUT mm_logger_adapter) IS
    v_XML_RESPONSE XMLTYPE;

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;


    RUN_PJM_SUBMIT(p_CRED, p_LOG_ONLY,
                   p_XML_REQUEST,
                   v_XML_RESPONSE,
				   p_STATUS,
                   p_MESSAGE,
				   p_LOGGER);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.SUBMIT_VIRTUAL_BID: ' || SQLERRM;
  END SUBMIT_VIRTUAL_BID;
  ------------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_UNIT_UPDATES(P_LOCATION_TYPE IN VARCHAR2,
  									P_LOCATION_NAME IN VARCHAR2,
									P_REQUEST_DATE  IN DATE,
                                    P_XML_REQUEST_BODY OUT XMLTYPE,
                                    P_STATUS           OUT NUMBER,
                                    P_MESSAGE          OUT VARCHAR2) AS

    V_XML_FRAGMENT  XMLTYPE;

  BEGIN
    P_STATUS := MEX_UTIL.G_SUCCESS;

	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(P_LOCATION_TYPE, P_LOCATION_NAME);

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryUnitUpdate",
                                 XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
                                 V_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_UNIT_UPDATES: ' ||
                   SQLERRM;
  END GETX_QUERY_UNIT_UPDATES;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_UNIT_UPDATES(P_XML_RESPONSE IN XMLTYPE,
                               P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_UNIT_UPDATES_TBL,
                               P_STATUS       OUT NUMBER,
                               P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(T), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(U), '//@hour', G_PJM_EMKT_NAMESPACE) "HOUR",
             EXTRACTVALUE(VALUE(U), '//@isDuplicateHour', G_PJM_EMKT_NAMESPACE) "ISDUPLICATEHOUR",
             EXTRACTVALUE(VALUE(U), '//EconomicLimits//@minMW',G_PJM_EMKT_NAMESPACE) "ECONOMIC_MIN_MW",
             EXTRACTVALUE(VALUE(U), '//EconomicLimits//@maxMW', G_PJM_EMKT_NAMESPACE) "ECONOMIC_MAX_MW",
             EXTRACTVALUE(VALUE(U), '//EmergencyLimits//@minMW', G_PJM_EMKT_NAMESPACE) "EMERGENCY_MIN_MW",
             EXTRACTVALUE(VALUE(U), '//EmergencyLimits//@maxMW', G_PJM_EMKT_NAMESPACE) "EMERGENCY_MAX_MW",
             EXTRACTVALUE(VALUE(U), '//CommitStatus', G_PJM_EMKT_NAMESPACE) "COMMIT_STATUS",
             EXTRACTVALUE(VALUE(U), '//FixedGen', G_PJM_EMKT_NAMESPACE) "FIXED_GEN",
             EXTRACTVALUE(VALUE(U), '//DefaultEconomicLimits//@minMW', G_PJM_EMKT_NAMESPACE) "DEF_ECONOMIC_MIN_MW",
             EXTRACTVALUE(VALUE(U), '//DefaultEconomicLimits//@maxMW', G_PJM_EMKT_NAMESPACE) "DEF_ECONOMIC_MAX_MW",
             EXTRACTVALUE(VALUE(U), '//DefaultEmergencyLimits//@minMW', G_PJM_EMKT_NAMESPACE) "DEF_EMERGENCY_MIN_MW",
             EXTRACTVALUE(VALUE(U), '//DefaultEmergencyLimits//@maxMW', G_PJM_EMKT_NAMESPACE) "DEF_EMERGENCY_MAX_MW",
			 EXTRACTVALUE(VALUE(U), '//NotificationTime', G_PJM_EMKT_NAMESPACE) "NOTIFICATION_TIME",
			 EXTRACTVALUE(VALUE(U), '//PumpStorageLimits/MinGenMW', G_PJM_EMKT_NAMESPACE) "PS_MIN_GEN_MW",
			 EXTRACTVALUE(VALUE(U), '//PumpStorageLimits/MinPumpMW', G_PJM_EMKT_NAMESPACE) "PS_MIN_PUMP_MW"
	FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,	'//UnitUpdate', G_PJM_EMKT_NAMESPACE))) T,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),	'//UnitUpdateHourly', G_PJM_EMKT_NAMESPACE))) U;

  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_UNIT_UPDATES(TO_CUT_WITH_OPTIONS(DUPLICATE_DATE(V_XML.RESPONSE_DATE + TO_NUMBER(V_XML.HOUR)/24,V_XML.ISDUPLICATEHOUR),g_PJM_TIME_ZONE, g_DST_SPRING_AHEAD_OPTION),
                                                             V_XML.LOCATION,
                                                             TO_NUMBER(V_XML.ECONOMIC_MIN_MW),
                                                             TO_NUMBER(V_XML.ECONOMIC_MAX_MW),
                                                             TO_NUMBER(V_XML.EMERGENCY_MIN_MW),
                                                             TO_NUMBER(V_XML.EMERGENCY_MAX_MW),
                                                             V_XML.COMMIT_STATUS,
                                                             CASE UPPER(V_XML.FIXED_GEN) WHEN 'TRUE' THEN 1 ELSE 0 END,
                                                             TO_NUMBER(V_XML.DEF_ECONOMIC_MIN_MW),
                                                             TO_NUMBER(V_XML.DEF_ECONOMIC_MAX_MW),
                                                             TO_NUMBER(V_XML.DEF_EMERGENCY_MIN_MW),
                                                             TO_NUMBER(V_XML.DEF_EMERGENCY_MAX_MW),
															 v_XML.NOTIFICATION_TIME,
															 v_XML.PS_MIN_GEN_MW,
															 v_XML.PS_MIN_PUMP_MW
                                                             );

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_UNIT_UPDATES: ' || SQLERRM;
  END PARSE_UNIT_UPDATES;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_UNIT_UPDATES(P_CRED          IN mex_credentials,
  							   P_LOG_ONLY      IN BINARY_INTEGER,
  							   P_LOCATION_TYPE IN VARCHAR2,
							   P_LOCATION_NAME IN VARCHAR2,
							   P_REQUEST_DATE  IN DATE,
                               P_RECORDS       OUT MEX_PJM_EMKT_UNIT_UPDATES_TBL,
                               P_STATUS        OUT NUMBER,
                               P_MESSAGE       OUT VARCHAR2,
							   P_LOGGER		   IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;
  BEGIN

    P_RECORDS := MEX_PJM_EMKT_UNIT_UPDATES_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_UNIT_UPDATES(P_LOCATION_TYPE,P_LOCATION_NAME, P_REQUEST_DATE,
                            V_XML_REQUEST,
                            P_STATUS,
                            P_MESSAGE);

    --SENDING THE XML REQUEST
      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

    PARSE_UNIT_UPDATES(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_UNIT_UPDATES: ' || SQLERRM;
  END FETCH_UNIT_UPDATES;
  ----------------------------------------------------------------------------------------------------------------------
 PROCEDURE GETX_SUBMIT_UNIT_UPDATE(p_RECORDS       IN MEX_PJM_EMKT_UNIT_UPDATES_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS
  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("UnitUpdate",
                      XMLATTRIBUTES(T.LOCATION AS "location",
                                    MEX_PJM_EMKT.GET_DATE(T.RESPONSE_DATE) AS "day"
                                   ),
                      (XMLAGG(XMLELEMENT("UnitUpdateHourly",
                                XMLATTRIBUTES(
                                              GET_HOUR(T.RESPONSE_DATE) AS "hour",
                                              GET_ISDUPLICATE(T.RESPONSE_DATE) AS "isDuplicateHour"
                                             ),
                                   XMLELEMENT("EconomicLimits",
                                      XMLATTRIBUTES(
                                                    TO_CHAR(T.ECONOMIC_MIN_MW) AS "minMW",
                                                    TO_CHAR(T.ECONOMIC_MAX_MW) AS "maxMW"
                                                   )),
                                   XMLELEMENT("EmergencyLimits",
                                      XMLATTRIBUTES(
                                                    TO_CHAR(T.EMERGENCY_MIN_MW) AS "minMW",
                                                    TO_CHAR(T.EMERGENCY_MAX_MW) AS "maxMW"
                                                   )),
                                   XMLELEMENT("CommitStatus", T.COMMIT_STATUS),
                                   XMLELEMENT("FixedGen", CASE T.FIXED_GEN WHEN 1 THEN 'TRUE' ELSE 'FALSE' END),
									XMLELEMENT("NotificationTime", T.NOTIFICATION_TIME),
									XMLELEMENT("PumpStorageLimits",
										XMLFOREST(T.PS_MIN_GEN_MW AS "MinGenMW",
											T.PS_MIN_PUMP_MW AS "MinPumpMW"))
                                   /*ORDER BY GET_HOUR(T.RESPONSE_DATE) */
                                ))
                          )
                          )
      INTO p_SUBMIT_XML
      FROM TABLE(p_RECORDS) T
      GROUP BY T.LOCATION,GET_DATE(T.RESPONSE_DATE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_UNIT_UPDATE: ' ||
                   SQLERRM;
  END GETX_SUBMIT_UNIT_UPDATE;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_VIRTUAL_BID(p_RECORDS       IN MEX_PJM_EMKT_VIRTUAL_BIDS_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("VirtualBid",
                      XMLATTRIBUTES(
                                    GET_DATE(T.RESPONSE_DATE) AS "day",
                                    T.LOCATION AS "location"
                                   ),
                      CASE UPPER(T.INC_DEC_TYPE) WHEN 'INC' THEN
                          XMLELEMENT("Increment",
                               (SELECT XMLAGG(XMLELEMENT("VirtualBidHourly",
                                    XMLATTRIBUTES(
                                                  GET_HOUR(T.RESPONSE_DATE) AS "hour",
                                                  GET_ISDUPLICATE(T.RESPONSE_DATE) AS "isDuplicateHour"
                                                 ),
                                       XMLAGG(XMLELEMENT("BidSegment",
                                          XMLATTRIBUTES(TO_CHAR(T.SEGMENT_ID) AS "id"),
                                              XMLELEMENT("MW",TO_CHAR(T.QUANTITY)),
                                              XMLELEMENT("Price",TO_CHAR(T.PRICE))))))
														FROM TABLE(p_RECORDS) T GROUP BY GET_HOUR(T.RESPONSE_DATE), GET_ISDUPLICATE(T.RESPONSE_DATE)))
                      ELSE
                          XMLELEMENT("Decrement",
                               (SELECT XMLAGG(XMLELEMENT("VirtualBidHourly",
                                    XMLATTRIBUTES(
                                                  GET_HOUR(T.RESPONSE_DATE) AS "hour",
                                                  GET_ISDUPLICATE(T.RESPONSE_DATE) AS "isDuplicateHour"
                                                 ),
                                       XMLAGG(XMLELEMENT("BidSegment",
                                          XMLATTRIBUTES(TO_CHAR(T.SEGMENT_ID) AS "id"),
                                              XMLELEMENT("MW",TO_CHAR(T.QUANTITY)),
                                              XMLELEMENT("Price",TO_CHAR(T.PRICE))))))
														FROM TABLE(p_RECORDS) T GROUP BY GET_HOUR(T.RESPONSE_DATE), GET_ISDUPLICATE(T.RESPONSE_DATE)))
                      END
          )
      INTO p_SUBMIT_XML
      FROM TABLE(p_RECORDS) T
	  GROUP BY GET_DATE(T.RESPONSE_DATE), T.LOCATION, T.INC_DEC_TYPE;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_VIRTUAL_BID: ' ||
                   SQLERRM;
  END GETX_SUBMIT_VIRTUAL_BID;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_SCHEDULE_OFFER(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SCHED_OFFER_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(T), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(T), '//@schedule', G_PJM_EMKT_NAMESPACE) "SCHEDULE_NUMBER",
             EXTRACTVALUE(VALUE(T), '//@slope', G_PJM_EMKT_NAMESPACE) "SLOPE",
             EXTRACTVALUE(VALUE(U), '//@MW', G_PJM_EMKT_NAMESPACE) "QUANTITY",
             EXTRACTVALUE(VALUE(U), '//@price', G_PJM_EMKT_NAMESPACE) "PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//ScheduleOffer',
                                       G_PJM_EMKT_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//OfferSegment',
                                       G_PJM_EMKT_NAMESPACE))) U;

  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SCHED_OFFER(V_XML.RESPONSE_DATE,
                                                            V_XML.SCHEDULE_NUMBER,
                                                            V_XML.LOCATION,
                                                            CASE UPPER(V_XML.SLOPE) WHEN 'TRUE' THEN 1 ELSE 0 END,
                                                            V_XML.QUANTITY,
                                                            V_XML.PRICE);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SCHEDULE_OFFER: ' ||
                   SQLERRM;
  END PARSE_SCHEDULE_OFFER;
----------------------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_SCHEDULE_SELECTION(P_XML_RESPONSE IN XMLTYPE,
                                 P_RECORDS      IN OUT NOCOPY MEX_PJM_EMKT_SCHED_SEL_TBL,
                                 P_STATUS       OUT NUMBER,
                                 P_MESSAGE      OUT VARCHAR2) AS

    CURSOR C_XML IS
      SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', G_PJM_EMKT_NAMESPACE),
                     G_DATE_FORMAT) "RESPONSE_DATE",
             EXTRACTVALUE(VALUE(T), '//@location', G_PJM_EMKT_NAMESPACE) "LOCATION",
             EXTRACTVALUE(VALUE(T), '//@schedule', G_PJM_EMKT_NAMESPACE) "SCHEDULE_NUMBER",
             EXTRACTVALUE(VALUE(T), '//Available', G_PJM_EMKT_NAMESPACE) "AVAILIBLE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(P_XML_RESPONSE,
                                       '//ScheduleSelection',
                                       G_PJM_EMKT_NAMESPACE))) T;

  BEGIN
    P_STATUS  := MEX_UTIL.G_SUCCESS;
    FOR V_XML IN C_XML LOOP
      P_RECORDS.EXTEND();
      P_RECORDS(P_RECORDS.LAST) := MEX_PJM_EMKT_SCHED_SEL(V_XML.RESPONSE_DATE,
                                                            V_XML.LOCATION,
                                                            TO_NUMBER(V_XML.SCHEDULE_NUMBER),
                                                            V_XML.AVAILIBLE);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.PARSE_SCHEDULE_SELECTION: ' ||
                   SQLERRM;
  END PARSE_SCHEDULE_SELECTION;
  ----------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SCHEDULE_OFFER(p_LOCATION_TYPE IN VARCHAR2,
  									  p_LOCATION_NAME IN VARCHAR2,
									  p_REQUEST_DATE  IN DATE,
                                      P_XML_REQUEST_BODY OUT XMLTYPE,
                                      P_STATUS           OUT NUMBER,
                                      P_MESSAGE          OUT VARCHAR2) AS

    v_XML_FRAGMENT XMLTYPE;

  BEGIN

    P_STATUS := MEX_UTIL.G_SUCCESS;

    -- the request XML will vary depending on the location type
	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);


    --GENERATE THE REQUEST XML.
    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryAllScheduleOffer",
					  	XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
						v_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SCHEDULE_OFFER: ' ||
                   SQLERRM;
  END GETX_QUERY_SCHEDULE_OFFER;
  ----------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_SCHEDULE_SELECTION(p_LOCATION_TYPE IN VARCHAR2,
  										  p_LOCATION_NAME IN VARCHAR2,
										  p_REQUEST_DATE  IN DATE,
										  P_XML_REQUEST_BODY OUT XMLTYPE,
										  P_STATUS           OUT NUMBER,
										  P_MESSAGE          OUT VARCHAR2) AS

    v_XML_FRAGMENT XMLTYPE;

  BEGIN

    P_STATUS := MEX_UTIL.G_SUCCESS;

    -- the request XML will vary depending on the location type
	v_XML_FRAGMENT := GETX_LOC_PORT_FRAG(p_LOCATION_TYPE, p_LOCATION_NAME);

    --GENERATE THE REQUEST XML.
    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(G_PJM_EMKT_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryAllScheduleSelection",
					  	XMLATTRIBUTES(to_Char(P_REQUEST_DATE, G_DATE_FORMAT) AS "day"),
						v_XML_FRAGMENT))
      INTO P_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_QUERY_SCHEDULE_SELECTION: ' ||
                   SQLERRM;
  END GETX_QUERY_SCHEDULE_SELECTION;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_SCHEDULE_OFFER(P_CRED          IN mex_credentials,
  							   	 P_LOG_ONLY      IN BINARY_INTEGER,
  							     P_LOCATION_TYPE IN VARCHAR2,
								 P_LOCATION_NAME IN VARCHAR2,
								 P_REQUEST_DATE  IN DATE,
                                 P_RECORDS       OUT MEX_PJM_EMKT_SCHED_OFFER_TBL,
                                 P_STATUS        OUT NUMBER,
                                 P_MESSAGE       OUT VARCHAR2,
								 P_LOGGER		 IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;

  BEGIN

    P_RECORDS := MEX_PJM_EMKT_SCHED_OFFER_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_SCHEDULE_OFFER(P_LOCATION_TYPE,
							  P_LOCATION_NAME,
							  P_REQUEST_DATE,
                              V_XML_REQUEST,
                              P_STATUS,
                              P_MESSAGE);

      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

    PARSE_SCHEDULE_OFFER(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SCHEDULE_OFFER: ' ||
                   SQLERRM;
  END FETCH_SCHEDULE_OFFER;
  ----------------------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_SCHEDULE_OFFER(p_RECORDS       IN MEX_PJM_EMKT_SCHED_OFFER_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("ScheduleOffer",
                      XMLATTRIBUTES(TO_CHAR(TRUNC(T.RESPONSE_DATE),'YYYY-MM-DD') AS "day",
                                    T.LOCATION AS "location",
                                    TO_CHAR(T.SCHEDULE_NUMBER) AS "schedule",
                                    CASE T.SLOPE WHEN 1 THEN 'TRUE' ELSE 'FALSE' END AS "slope"
                                   ),
                          (XMLAGG(XMLELEMENT("OfferSegment",
                             XMLATTRIBUTES(
                                           TO_CHAR(T.QUANTITY) AS "MW",
                                           TO_CHAR(T.PRICE) AS "price"
                                          )
                             ))
                          )
                          )
      INTO p_SUBMIT_XML
      FROM TABLE(p_RECORDS) T
      GROUP BY T.RESPONSE_DATE, T.LOCATION, T.SCHEDULE_NUMBER, T.SLOPE;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_SCHEDULE_OFFER: ' ||
                   SQLERRM;
  END GETX_SUBMIT_SCHEDULE_OFFER;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_SPIN_OFFER(p_RECORDS       IN MEX_PJM_EMKT_SPIN_RES_OFF_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	SELECT XMLELEMENT("SpinningReserveOffer",
		XMLATTRIBUTES(TO_CHAR(TRUNC(T.RESPONSE_DATE),'YYYY-MM-DD') AS "day", T.LOCATION AS "location"),
		XMLFOREST(T.QUANTITY AS "OfferMW",
			T.PRICE AS "OfferPrice",
			T.CONDENSE_AVAILABLE AS "CondenseAvailable",
			T.COND_STARTUP_COST AS "CondenseStartupCost",
 			T.COND_ENERGY_USAGE AS "CondenseEnergyUsage",
 			T.COND_TO_GEN_COST AS "CondenseToGenCost",
 			T.SPIN_AS_CONDENSER AS "SpinAsCondenser",
 			T.FULL_LOAD_HR AS "FullLoadHeatRate",
 			T.REDUCED_LOAD_HR AS "ReducedLoadHeatRate",
 			T.VOM_RATE AS "VOMRate")
			)
	INTO p_SUBMIT_XML
	FROM TABLE(p_RECORDS) T;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_SPIN_OFFER: ' || SQLERRM;
  END GETX_SUBMIT_SPIN_OFFER;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_SPIN_UPDATE(p_RECORDS       IN MEX_PJM_EMKT_SPIN_RES_UPD_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	SELECT XMLELEMENT("SpinningReserveUpdate",
		XMLATTRIBUTES(T.LOCATION AS "location", MEX_PJM_EMKT.GET_DATE(T.RESPONSE_DATE) AS "day"),
		(XMLAGG
			(XMLELEMENT("SpinningReserveUpdateHourly",
				XMLATTRIBUTES(
					GET_HOUR(T.RESPONSE_DATE) AS "hour",
					GET_ISDUPLICATE(T.RESPONSE_DATE) AS "isDuplicateHour"
				),
				XMLFOREST(T.QUANTITY AS "OfferMW",
					T.SPIN_MAX_MW AS "SpinMAX",
					T.UNAVAILABLE AS "Unavailable",
					T.SELF_SCHEDULED_MW AS "SelfScheduledMW")
		))))
	INTO p_SUBMIT_XML
	FROM TABLE(p_RECORDS) T
	GROUP BY T.LOCATION,GET_DATE(T.RESPONSE_DATE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_SPIN_UPDATE: ' || SQLERRM;
  END GETX_SUBMIT_SPIN_UPDATE;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_REG_OFFER(p_RECORDS       IN MEX_PJM_EMKT_REG_OFFER_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

	SELECT XMLELEMENT("RegulationOffer",
		XMLATTRIBUTES(TO_CHAR(TRUNC(T.RESPONSE_DATE),'YYYY-MM-DD') AS "day", T.LOCATION AS "location"),
		XMLFOREST(T.QUANTITY AS "OfferMW",
			T.PRICE AS "OfferPrice",
			T.UNAVAILABLE AS "Unavailable",
			T.SELF_SCHEDULED AS "SelfScheduled",
			T.MINIMUM_MW AS "MinimumMW"
			))
	INTO p_SUBMIT_XML
	FROM TABLE(p_RECORDS) T;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_REG_OFFER: ' || SQLERRM;
  END GETX_SUBMIT_REG_OFFER;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_REG_UPDATE(p_RECORDS       IN MEX_PJM_EMKT_REG_UPDATE_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    p_STATUS := MEX_UTIL.g_SUCCESS;

	SELECT XMLELEMENT("RegulationUpdate",
		XMLATTRIBUTES(T.LOCATION AS "location", MEX_PJM_EMKT.GET_DATE(T.RESPONSE_DATE) AS "day"),
		(XMLAGG
			(XMLELEMENT("RegulationUpdateHourly",
				XMLATTRIBUTES(
					GET_HOUR(T.RESPONSE_DATE) AS "hour",
					GET_ISDUPLICATE(T.RESPONSE_DATE) AS "isDuplicateHour"
				),
				XMLELEMENT("MW", T.QUANTITY),
				XMLELEMENT("RegulationLimits",
					XMLATTRIBUTES(T.LIMIT_MIN_MW AS "minMW", T.LIMIT_MAX_MW AS "maxMW")),
				XMLELEMENT("Unavailable", T.UNAVAILABLE),
				XMLELEMENT("SelfScheduled", T.SELF_SCHEDULED),
				XMLELEMENT("Spilling", T.SPILLING)
		))))
	INTO p_SUBMIT_XML
	FROM TABLE(p_RECORDS) T
	GROUP BY T.LOCATION,GET_DATE(T.RESPONSE_DATE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_REG_UPDATE: ' || SQLERRM;
  END GETX_SUBMIT_REG_UPDATE;
  --------------------------------------------------------------------------------------------------------
    PROCEDURE GETX_SUBMIT_SCHEDULE_SELECTION(p_RECORDS       IN MEX_PJM_EMKT_SCHED_SEL_TBL,
                                          p_SUBMIT_XML    OUT XMLTYPE,
                                          p_STATUS        OUT NUMBER,
                                          p_MESSAGE       OUT VARCHAR2) IS

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("ScheduleSelection",
                      XMLATTRIBUTES(TO_CHAR(TRUNC(T.RESPONSE_DATE),'YYYY-MM-DD') AS "day",
                                    T.LOCATION AS "location",
                                    TO_CHAR(T.SCHEDULE_NUMBER) AS "schedule"
                                   ),
                                   XMLELEMENT("Available", T.AVAILABLE)
                             )
      INTO p_SUBMIT_XML
      FROM TABLE(p_RECORDS) T;
      --GROUP BY T.RESPONSE_DATE, T.LOCATION, T.SCHEDULE_NUMBER;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.GETX_SUBMIT_SCHEDULE_SELECTION: ' ||
                   SQLERRM;
  END GETX_SUBMIT_SCHEDULE_SELECTION;
  --------------------------------------------------------------------------------------------------------
  PROCEDURE FETCH_SCHEDULE_SELECTION(P_CRED          IN mex_credentials,
  									 P_LOG_ONLY      IN BINARY_INTEGER,
									 P_LOCATION_TYPE IN VARCHAR2,
									 P_LOCATION_NAME IN VARCHAR2,
									 P_REQUEST_DATE  IN DATE,
									 P_RECORDS       OUT MEX_PJM_EMKT_SCHED_SEL_TBL,
									 P_STATUS        OUT NUMBER,
									 P_MESSAGE       OUT VARCHAR2,
									 P_LOGGER		 IN OUT mm_logger_adapter) AS

    V_XML_REQUEST  XMLTYPE;
    V_XML_RESPONSE XMLTYPE;

  BEGIN

    P_RECORDS := MEX_PJM_EMKT_SCHED_SEL_TBL();
    P_STATUS  := MEX_UTIL.G_SUCCESS;

    GETX_QUERY_SCHEDULE_SELECTION(P_LOCATION_TYPE,
								  P_LOCATION_NAME,
								  P_REQUEST_DATE,
								  V_XML_REQUEST,
								  P_STATUS,
								  P_MESSAGE);

      RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

    PARSE_SCHEDULE_SELECTION(V_XML_RESPONSE, P_RECORDS, P_STATUS, P_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in MEX_PJM_EMKT.FETCH_SCHEDULE_SELECTION: ' ||
                   SQLERRM;
  END FETCH_SCHEDULE_SELECTION;
  --------------------------------------------------------------------------------------------------------------
END MEX_PJM_EMKT;
/
