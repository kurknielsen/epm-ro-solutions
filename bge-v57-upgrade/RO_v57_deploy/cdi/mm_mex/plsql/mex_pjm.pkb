CREATE OR REPLACE PACKAGE BODY MEX_PJM IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE RUN_PJM_BROWSERLESS
	(
	p_PARAMETER_MAP IN OUT NOCOPY MEX_Util.Parameter_Map,
	p_REQUEST_APP IN VARCHAR2,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_CRED IN MEX_CREDENTIALS,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_REQUEST_DIR IN VARCHAR2,
	p_CLOB_RESPONSE OUT CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_REQUEST_EXT IN VARCHAR2 DEFAULT 'text/xml',
	p_REQUEST_CLOB IN CLOB DEFAULT NULL,
	p_LOG_ONLY IN NUMBER DEFAULT 0
	) AS

	v_RESULT MEX_RESULT;
    v_SANDBOX BOOLEAN;
    v_DEBUG	  BOOLEAN;
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	v_SANDBOX := NVL(GET_DICTIONARY_VALUE('Sandbox',0,'MarketExchange','PJM','Browserless',p_REQUEST_APP),0) = '1';
   v_DEBUG := NVL(GET_DICTIONARY_VALUE('Debug',0,'MarketExchange','PJM','powermeter',p_REQUEST_APP),0) = '1';

	p_PARAMETER_MAP(c_ACTION) := p_REQUEST_DIR;
	IF TRUNC(p_BEGIN_DATE) = TRUNC(p_END_DATE) THEN
    	p_PARAMETER_MAP(c_DATE) := TO_CHAR(p_BEGIN_DATE,'MM/DD/YYYY');
    ELSE
        p_PARAMETER_MAP(c_START) := TO_CHAR(p_BEGIN_DATE, 'MM/DD/YYYY');
        p_PARAMETER_MAP(c_STOP) := TO_CHAR(p_END_DATE, 'MM/DD/YYYY');
    END IF;
    IF v_SANDBOX THEN
    	p_PARAMETER_MAP(c_SANDBOX) := 'true';
    ELSE
    	p_PARAMETER_MAP(c_SANDBOX) := 'false';
	END IF;
    IF v_DEBUG THEN
        p_PARAMETER_MAP(c_DEBUG) := 'true';
    ELSE
    	p_PARAMETER_MAP(c_DEBUG) := 'false';
	END IF;

	v_RESULT := mex_switchboard.Invoke(p_Market => 'pjmbrowserless',
							p_Action => p_REQUEST_APP,
							p_Logger => p_LOGGER,
							p_Cred => p_CRED,
							p_Parms => p_PARAMETER_MAP,
							p_Request_ContentType => p_REQUEST_EXT,
							p_REQUEST => p_REQUEST_CLOB ,
							p_Request_Binary => NULL,
							p_Log_Only => p_LOG_ONLY);

	p_STATUS  := v_RESULT.STATUS_CODE;
    IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
  		p_CLOB_RESPONSE:= NULL;
		p_MESSAGE := 'Download unsuccessful. Status = '|| p_STATUS;
    ELSE
	    p_CLOB_RESPONSE:= v_RESULT.RESPONSE;
        P_MESSAGE := 'Download complete';
    END IF;
END RUN_PJM_BROWSERLESS;
---------------------------------------------------------------------------------------
  FUNCTION SAFE_STRING(P_XML       IN XMLTYPE,
                       P_XPATH     IN VARCHAR2,
                       P_NAMESPACE IN VARCHAR2 := NULL) RETURN VARCHAR2 IS
    --RETURN TEXT FOR A PATH OR NULL IF IT DOESN'T EXIST.
    V_XMLTMP XMLTYPE;
  BEGIN
    V_XMLTMP := XMLTYPE.EXTRACT(P_XML, P_XPATH, P_NAMESPACE);
    IF V_XMLTMP IS NULL THEN
      RETURN NULL;
    ELSE
      RETURN V_XMLTMP.GETSTRINGVAL();
    END IF;
  END SAFE_STRING;
----------------------------------------------------------------------------------------
PROCEDURE RUN_PJM_ACTION(P_CRED                IN mex_credentials,
                           P_ACTION            IN VARCHAR2,
                           P_LOG_ONLY          IN BINARY_INTEGER,
                           P_XML_REQUEST_BODY  IN XMLTYPE,
                           P_PJM_NAMESPACE     IN VARCHAR2,
                           P_MARKET            IN VARCHAR2,
                           P_XML_RESPONSE_BODY OUT XMLTYPE,
                           P_STATUS            OUT NUMBER,
                           P_ERROR_MESSAGE     OUT VARCHAR2,
                           P_LOGGER            IN OUT mm_logger_adapter) AS
  BEGIN

    MEX_PJM.RUN_PJM_ACTION(P_CRED => P_CRED,
                           P_ACTION => P_ACTION,
                           P_LOG_ONLY => P_LOG_ONLY,
                           P_XML_REQUEST_BODY => P_XML_REQUEST_BODY,
                           P_PJM_NAMESPACE => P_PJM_NAMESPACE,
                           P_MARKET => P_MARKET,
                           P_TOKEN_ID => NULL,
                           P_XML_RESPONSE_BODY => P_XML_RESPONSE_BODY,
                           P_STATUS => P_STATUS,
                           P_ERROR_MESSAGE => P_ERROR_MESSAGE,
                           P_LOGGER => P_LOGGER);

  END RUN_PJM_ACTION;
----------------------------------------------------------------------------------------
  PROCEDURE RUN_PJM_ACTION(P_CRED			   IN mex_credentials,
						   P_ACTION			   IN VARCHAR2,
  						   P_LOG_ONLY		   IN BINARY_INTEGER,
                           P_XML_REQUEST_BODY  IN XMLTYPE,
						   P_PJM_NAMESPACE     IN VARCHAR2,
						   P_MARKET			   IN VARCHAR2,
						   P_TOKEN_ID          IN VARCHAR2,
                           P_XML_RESPONSE_BODY OUT XMLTYPE,
						   P_STATUS			   OUT NUMBER,
                           P_ERROR_MESSAGE     OUT VARCHAR2,
						   P_LOGGER			   IN OUT mm_logger_adapter) AS

    V_PJM_ERROR_XML     XMLTYPE;
    V_PJM_ERROR_CODE    VARCHAR2(32);
    V_PJM_ERROR_MESSAGE VARCHAR2(2000);
    V_PJM_ERROR_LINE    VARCHAR2(32);
    V_RESULT       MEX_RESULT;
    V_REQUEST_CLOB CLOB := NULL;
	V_PARMS MEX_UTIL.PARAMETER_MAP;
	v_SANDBOX NUMBER(1);
	v_URL VARCHAR2(2000);

  BEGIN
	DBMS_LOB.CREATETEMPORARY(v_REQUEST_CLOB, TRUE);
    DBMS_LOB.OPEN(v_REQUEST_CLOB, DBMS_LOB.LOB_READWRITE);
    -- Add this XML to the request CLOB
    DBMS_LOB.APPEND(v_REQUEST_CLOB, P_XML_REQUEST_BODY.GETCLOBVAL());
    DBMS_LOB.CLOSE(v_REQUEST_CLOB);

	IF P_TOKEN_ID IS NOT NULL THEN

		IF P_ACTION = 'query' THEN
			v_URL := '/marketsgateway/xml/query';
		ELSE
			v_URL := '/marketsgateway/xml/submit';
		END IF;

		v_SANDBOX := NVL(GET_DICTIONARY_VALUE('Use Sandbox',0,'MarketExchange','PJM','MarketsGateway','?'),0);

		IF v_SANDBOX = 1 THEN
			v_URL := NVL(GET_DICTIONARY_VALUE('Sandbox URL',0,'MarketExchange','PJM','MarketsGateway','?'),0) || v_URL;
			v_PARMS('MEX-REQUEST-HEADER-Cookie') := 'pjmauthtrain=' || P_TOKEN_ID;
		ELSE
			v_URL := NVL(GET_DICTIONARY_VALUE('Production URL',0,'MarketExchange','PJM','MarketsGateway','?'),0) || v_URL;
			v_PARMS('MEX-REQUEST-HEADER-Cookie') := 'pjmauth=' || P_TOKEN_ID;
		END IF;
    END IF;

	v_PARMS('url') := v_URL;

	V_RESULT := Mex_Switchboard.Invoke(P_Market => P_MARKET,
						 p_Action => P_ACTION,
						 p_Logger => P_LOGGER,
						 p_Cred => P_CRED,
						 p_PARMS => v_PARMS,
						 p_Request_ContentType => 'text/xml',
						 p_Request => V_REQUEST_CLOB,
						 p_Log_Only => P_LOG_ONLY);


	p_STATUS  := v_RESULT.STATUS_CODE;
    IF V_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
      P_XML_RESPONSE_BODY := NULL;
    ELSE
	  P_XML_RESPONSE_BODY := XMLTYPE.CREATEXML(V_RESULT.RESPONSE);
      --IF ERROR OCCURED FROM PJM PARSING, LOG IT AND RETURN ERROR.
      V_PJM_ERROR_XML := P_XML_RESPONSE_BODY.EXTRACT('/descendant::Error',
                                                     P_PJM_NAMESPACE);
      IF (V_PJM_ERROR_XML IS NOT NULL) THEN

        V_PJM_ERROR_CODE    := SAFE_STRING(V_PJM_ERROR_XML,
                                           'Error/Code/text()',
                                           P_PJM_NAMESPACE);
        V_PJM_ERROR_MESSAGE := SAFE_STRING(V_PJM_ERROR_XML,
                                           'Error/Text/text()',
                                           P_PJM_NAMESPACE);
        V_PJM_ERROR_LINE    := SAFE_STRING(V_PJM_ERROR_XML,
                                           'Error/Line/text()',
                                           P_PJM_NAMESPACE);

        P_ERROR_MESSAGE := V_PJM_ERROR_CODE || ' ' || V_PJM_ERROR_MESSAGE || ' ' ||
                           V_PJM_ERROR_LINE;

		P_LOGGER.LOG_EXCHANGE_ERROR('Parse Errors: ' || P_ERROR_MESSAGE);

		P_XML_RESPONSE_BODY := NULL;
        --LOG A SUCCESS IF NO ERROR.
      END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_ERROR_MESSAGE := 'MEX_PJM.RUN_PJM_ACTION: ' || SQLERRM;
	  P_STATUS := SQLCODE;
  END RUN_PJM_ACTION;
----------------------------------------------------------------------------------------------------
PROCEDURE RUN_PJM_AUTHENTICATE
(
    p_CRED IN MEX_CREDENTIALS,
    p_LOG_ONLY IN BINARY_INTEGER,
    p_LOGGER IN OUT MM_LOGGER_ADAPTER,
    p_TOKEN_ID OUT VARCHAR2
) AS

    v_RESULT MEX_RESULT;
    v_REQUEST CONSTANT CLOB := TO_CLOB('{}');
    v_RESPONSE CLOB;
    v_START BINARY_INTEGER;
    v_END BINARY_INTEGER;
    v_PARAMETER_MAP MEX_UTIL.PARAMETER_MAP;
	v_SANDBOX NUMBER(1);
    v_URL VARCHAR2(2000);

BEGIN

	v_SANDBOX := NVL(GET_DICTIONARY_VALUE('Use Sandbox',0,'MarketExchange','PJM','MarketsGateway','?'),0);

    IF v_SANDBOX = 1 THEN
      v_URL := NVL(GET_DICTIONARY_VALUE('Sandbox URL',0,'MarketExchange','PJM','SSO','?'),0);
    ELSE
      v_URL := NVL(GET_DICTIONARY_VALUE('Production URL',0,'MarketExchange','PJM','SSO','?'),0);
    END IF;

    v_PARAMETER_MAP('url') := v_URL;

    v_PARAMETER_MAP('MEX-REQUEST-HEADER-X-OpenAM-Username') := p_CRED.USERNAME;
    v_PARAMETER_MAP('MEX-REQUEST-HEADER-X-OpenAM-Password') := SECURITY_CONTROLS.DECODE(p_CRED.PASSWORD);

    v_RESULT := MEX_SWITCHBOARD.INVOKE(p_MARKET => 'pjmsso',
                                       p_ACTION => 'authenticate',
                                       p_LOGGER => p_LOGGER,
                                       p_CRED => p_CRED,
                                       p_PARMS => v_PARAMETER_MAP,
                                       p_REQUEST_CONTENTTYPE => 'application/json',
                                       p_REQUEST => v_REQUEST,
                                       p_LOG_ONLY => p_LOG_ONLY);

    IF v_RESULT.STATUS_CODE <> MEX_SWITCHBOARD.c_Status_Success THEN
        p_TOKEN_ID := NULL;
        RETURN;
    ELSE
        v_RESPONSE := v_RESULT.RESPONSE;
        v_START := INSTR(v_RESPONSE, 'tokenId');
        v_START := INSTR(v_RESPONSE, '"', v_START, 2) + 1;
        v_END := INSTR(v_RESPONSE, '"', v_START);
        p_TOKEN_ID := SUBSTR(v_RESPONSE, v_START, v_END-v_START);
    END IF;

END RUN_PJM_AUTHENTICATE;
----------------------------------------------------------------------------------------------------
END MEX_PJM;
/
