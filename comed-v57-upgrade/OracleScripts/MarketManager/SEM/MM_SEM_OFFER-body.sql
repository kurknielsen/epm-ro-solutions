
CREATE OR REPLACE PACKAGE BODY MM_SEM_OFFER IS
------------------------------------------------------------------------------

-- Types

TYPE t_XML_MAP IS TABLE OF XMLSequenceType INDEX BY VARCHAR2(64);
TYPE t_MAP_OF_XML_MAPS IS TABLE OF t_XML_MAP INDEX BY VARCHAR2(64);

TYPE t_ID_MAP IS TABLE OF NUMBER_COLLECTION INDEX BY VARCHAR2(64);
TYPE t_MAP_OF_ID_MAPS IS TABLE OF t_ID_MAP INDEX BY VARCHAR2(64);

TYPE t_NAME_MAP IS TABLE OF STRING_COLLECTION INDEX BY VARCHAR2(64);
TYPE t_MAP_OF_NAME_MAPS IS TABLE OF t_NAME_MAP INDEX BY VARCHAR2(64);

TYPE t_FLAG_MAP IS TABLE OF BOOLEAN INDEX BY VARCHAR2(64);
TYPE t_FLAG_TBL IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;

TYPE t_PROGRESS IS RECORD
(
SUCCEEDED PLS_INTEGER,
REJECTED PLS_INTEGER,
ERROR PLS_INTEGER
);

-- Registration maps used for delegating (via 'execute immediate')

g_TXN_TYPE_TO_PKG     UT.STRING_MAP;
g_XML_NODE_TO_PKG     UT.STRING_MAP;
g_XML_NODE_TO_TXN_TYPE  UT.STRING_MAP;
g_TXN_TYPE_TO_INT     UT.STRING_MAP;
g_IS_ONE_AT_A_TIME     t_FLAG_MAP;
g_NEEDS_RESET_FOR_PARSE  t_FLAG_MAP;
g_NEEDS_SEM_TXN_ID     t_FLAG_TBL;
g_MARKET_NODES      GA.STRING_TABLE;
g_CREATE_PROCS        GA.STRING_TABLE;
g_PROCESS_PROCS       GA.STRING_TABLE;
g_XPATH_ELEMENT_SEARCH  GA.STRING_TABLE;
g_XPATH_DATE_SEARCH    GA.STRING_TABLE;
g_ALERT_NAMES      GA.STRING_TABLE;

-- Constants

g_XPATH_TOP CONSTANT VARCHAR2(16) := '/bids_offers/';
g_XPATH_TXN_ID CONSTANT VARCHAR2(64) := g_XPATH_TOP||'processing_statistics/@transaction_id';
g_XPATH_ELEMENT_SEARCH_SUFFIX CONSTANT VARCHAR2(4) := '/*';
g_XPATH_DATE_ATTR_NAME CONSTANT VARCHAR2(16) := 'trading_date';

g_MODE CONSTANT VARCHAR2(16) := 'NORMAL';
g_APP_TYPE CONSTANT VARCHAR2(16) := 'DAM';

g_ACTION_SUBMIT CONSTANT PLS_INTEGER := 1;
g_ACTION_QUERY CONSTANT PLS_INTEGER := 2;
g_ACTION_SUBMIT_CANCEL CONSTANT PLS_INTEGER := 3;
g_ACTION_UUT_SUBMIT CONSTANT PLS_INTEGER := 4;
g_ACTION_UUT_QUERY CONSTANT PLS_INTEGER := 5;

g_GEN_PKG CONSTANT VARCHAR2(30) := 'MM_SEM_GEN_OFFER';
g_IC_PKG CONSTANT VARCHAR2(30) := 'MM_SEM_IC_OFFER';
g_LOAD_PKG CONSTANT VARCHAR2(30) := 'MM_SEM_LOAD_OFFER';
g_SRA_PKG CONSTANT VARCHAR2(30) := 'MM_SEM_SRA_OFFER';

-- Constant for Alert Type
g_ALERT_TYPE_OFFER VARCHAR2(32) := 'Offers';

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.19 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_TRANSACTION_INFO
  (
  p_TRANSACTION_ID IN NUMBER,
  p_TRANSACTION_NAME OUT VARCHAR2,
  p_TRANSACTION_TYPE OUT VARCHAR2
  ) AS
BEGIN
  SELECT TRANSACTION_NAME, TRANSACTION_TYPE
  INTO p_TRANSACTION_NAME, p_TRANSACTION_TYPE
  FROM INTERCHANGE_TRANSACTION
  WHERE TRANSACTION_ID = p_TRANSACTION_ID;
END GET_TRANSACTION_INFO;
------------------------------------------------------------------------------
FUNCTION GET_MESSAGE
  (
  p_REC IN t_PROGRESS,
  p_VERB_SUCCESS IN VARCHAR2 := 'processed',
  p_VERB_REJECT IN VARCHAR2 := 'rejected',
  p_VERB_ERROR IN VARCHAR2 := 'failed',
  p_TOTAL_WORD IN VARCHAR2 := 'total'
  ) RETURN VARCHAR2 IS
BEGIN
  RETURN (p_REC.SUCCEEDED+p_REC.REJECTED+p_REC.ERROR)||' '||p_TOTAL_WORD||' schedules.'||UTL_TCP.CRLF||
        p_REC.SUCCEEDED||' were successfully '||p_VERB_SUCCESS||'.'||UTL_TCP.CRLF||
        (p_REC.REJECTED+p_REC.ERROR)||' '||p_VERB_ERROR||', of which '||p_REC.REJECTED||' were '||p_VERB_REJECT||'.';
END GET_MESSAGE;
------------------------------------------------------------------------------
FUNCTION GET_MESSAGE
  (
  p_OP IN VARCHAR2,
  p_TXN_NAME IN VARCHAR2,
  p_DATE IN DATE,
  p_MESSAGE IN VARCHAR2
  ) RETURN VARCHAR2 IS
BEGIN
  RETURN p_OP||': "'||p_TXN_NAME||'" for '||TO_CHAR(p_DATE,MM_SEM_UTIL.g_DATE_FORMAT)||
      '. '||p_MESSAGE;
END GET_MESSAGE;
------------------------------------------------------------------------------
PROCEDURE PROCESS_ERRORS
  (
  p_TXN_NAMES IN STRING_COLLECTION,
  p_DATE IN DATE,
  p_MESSAGE IN VARCHAR2,
  p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
  p_VERB IN VARCHAR2 := 'ERROR'
  ) AS
v_IDX BINARY_INTEGER;
BEGIN
  v_IDX := p_TXN_NAMES.FIRST;
  WHILE p_TXN_NAMES.EXISTS(v_IDX) LOOP
    p_LOGGER.LOG_ERROR(GET_MESSAGE(p_VERB,p_TXN_NAMES(v_IDX),p_DATE,p_MESSAGE));
    v_IDX := p_TXN_NAMES.NEXT(v_IDX);
  END LOOP;
END PROCESS_ERRORS;
------------------------------------------------------------------------------
FUNCTION CHECK_STATUS
  (
  p_TXN_ID IN NUMBER,
  p_TXN_TYPE IN VARCHAR2,
  p_DATE IN DATE,
  p_REQUIRED_REVIEW_STATUS IN VARCHAR2
  ) RETURN BOOLEAN IS
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_EXPECTED_COUNT BINARY_INTEGER;
v_COUNT BINARY_INTEGER;
v_SECOND NUMBER;
BEGIN
  IF p_REQUIRED_REVIEW_STATUS IS NULL THEN
    -- means there is no required review status - so nothing to do
    RETURN TRUE;
  END IF;

  IF g_TXN_TYPE_TO_INT(p_TXN_TYPE) = 'Day' THEN
    v_BEGIN_DATE := TRUNC(p_DATE)+1/86400;
    v_END_DATE := v_BEGIN_DATE;
    v_EXPECTED_COUNT := 1;
    v_SECOND := 1;
  ELSE
    MM_SEM_UTIL.OFFER_DATE_RANGE(p_DATE, v_BEGIN_DATE, v_END_DATE);
    -- this expression will return 48 for most days,
    -- 46 for DST spring-ahead, and 50 for DST fall-back day.
    v_EXPECTED_COUNT := CEIL((v_END_DATE-v_BEGIN_DATE)*24)*2;
    v_SECOND := 0;
  END IF;

  SELECT COUNT(1)
  INTO v_COUNT
  FROM IT_TRAIT_SCHEDULE_STATUS
  WHERE TRANSACTION_ID = p_TXN_ID
    AND SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
    AND TO_NUMBER(TO_CHAR(SCHEDULE_DATE,'SS')) = v_SECOND
    AND REVIEW_STATUS = p_REQUIRED_REVIEW_STATUS;

  RETURN v_COUNT = v_EXPECTED_COUNT;
END CHECK_STATUS;
------------------------------------------------------------------------------
PROCEDURE SET_STATUS
  (
  p_TXN_ID IN NUMBER,
  p_TXN_TYPE IN VARCHAR2,
  p_DATE IN DATE,
  p_SUBMIT_STATUS IN VARCHAR2,
  p_MARKET_STATUS IN VARCHAR2,
  p_PROCESS_MESSAGE IN VARCHAR2 := NULL
  ) AS
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_SYSDATE DATE := SYSDATE;
BEGIN
  IF p_SUBMIT_STATUS IS NULL AND p_MARKET_STATUS IS NULL THEN
    -- both statuses are NULL? then nothing to do
    RETURN;
  END IF;

  IF g_TXN_TYPE_TO_INT(p_TXN_TYPE) = 'Day' THEN
    v_BEGIN_DATE := TRUNC(p_DATE)+1/86400;
    v_END_DATE := v_BEGIN_DATE;
  ELSE
    MM_SEM_UTIL.OFFER_DATE_RANGE(p_DATE, v_BEGIN_DATE, v_END_DATE);
  END IF;

  UPDATE IT_TRAIT_SCHEDULE_STATUS SET
        SUBMIT_STATUS = TRIM(NVL(p_SUBMIT_STATUS,SUBMIT_STATUS)),
        SUBMIT_DATE = CASE WHEN p_SUBMIT_STATUS IS NULL THEN SUBMIT_DATE ELSE v_SYSDATE END,
        SUBMITTED_BY_ID = CASE WHEN p_SUBMIT_STATUS IS NULL THEN SUBMITTED_BY_ID ELSE SECURITY_CONTROLS.CURRENT_USER_ID END,
        MARKET_STATUS = TRIM(NVL(p_MARKET_STATUS,MARKET_STATUS)),
        MARKET_STATUS_DATE = CASE WHEN p_MARKET_STATUS IS NULL THEN MARKET_STATUS_DATE ELSE v_SYSDATE END,
        PROCESS_MESSAGE = CASE WHEN p_MARKET_STATUS IS NULL THEN PROCESS_MESSAGE ELSE TRIM(p_PROCESS_MESSAGE) END,
        ENTRY_DATE = v_SYSDATE
  WHERE TRANSACTION_ID = p_TXN_ID
    AND SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

END SET_STATUS;
------------------------------------------------------------------------------
PROCEDURE SET_STATUS
  (
  p_TXN_IDs IN NUMBER_COLLECTION,
  p_TXN_TYPE IN VARCHAR2,
  p_DATE IN DATE,
  p_SUBMIT_STATUS IN VARCHAR2,
  p_MARKET_STATUS IN VARCHAR2,
  p_PROCESS_MESSAGE IN VARCHAR2 := NULL
  ) AS
v_IDX BINARY_INTEGER;
BEGIN
  v_IDX := p_TXN_IDs.FIRST;
  WHILE p_TXN_IDs.EXISTS(v_IDX) LOOP
    SET_STATUS(p_TXN_IDs(v_IDX), p_TXN_TYPE, p_DATE, p_SUBMIT_STATUS, p_MARKET_STATUS, p_PROCESS_MESSAGE);
    v_IDX := p_TXN_IDs.NEXT(v_IDX);
  END LOOP;
END SET_STATUS;
------------------------------------------------------------------------------
FUNCTION PROCESS_RESPONSE
  (
  p_ACCOUNT_NAME IN VARCHAR2,
  p_DATE IN DATE,
  p_RESPONSE IN XMLTYPE,
  p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
  p_ACTION IN PLS_INTEGER,
  p_MARKET_ACCEPTED_STATUS IN VARCHAR2,
  p_MARKET_REJECTED_STATUS IN VARCHAR2,
  p_MARKET_ERROR_STATUS IN VARCHAR2,
  p_STATUS OUT t_PROGRESS
  ) RETURN VARCHAR2 IS

v_SEM_TXN_ID VARCHAR2(32);
v_PKG_NAME VARCHAR2(30);
v_DATE DATE;
v_GATE_WINDOW VARCHAR2(32);

v_TXN_IDs NUMBER_COLLECTION;
v_TXN_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_TXN_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;

v_XML_DOC XMLDOM.DOMDocument;
v_XML_NODE VARCHAR2(64);

v_ERR_MSG VARCHAR2(4000);
v_COUNT BINARY_INTEGER := 0;
v_SQL VARCHAR2(4000);
v_IDX BINARY_INTEGER;

v_TOTAL_FAILURE_ERR_MESSAGE VARCHAR2(4000) := NULL;
v_XPATH_FOR_ERR_MESSAGE CONSTANT VARCHAR2(512) := '/bids_offers/messages/error|/bids_offers/messages/fatal|/bids_offers/market_submit/messages/error|/bids_offers/market_submit/messages/fatal';

CURSOR c_ELEMENTS IS
  SELECT VALUE(T) as VAL
  FROM TABLE(XMLSEQUENCE(EXTRACT(p_RESPONSE, g_XPATH_ELEMENT_SEARCH(p_ACTION)))) T;

v_PQ_PAIR_ERROR_RESPONSE   VARCHAR2(4000);
v_PQ_PAIR_ERROR_TRAILER    VARCHAR2(128) := '[Truncated. See Response for full details.]';
v_PQ_PAIR_ERROR_XPATH    VARCHAR2(128) := '/bids_offers/market_submit//pq_curve/messages/error';
BEGIN
  p_STATUS.SUCCEEDED := 0;
  p_STATUS.REJECTED := 0;
  p_STATUS.ERROR := 0;

  -- Conflate all the PQ PAIR errors from the response; truncate it if > 4,000 charas, if necessary, before logging
  v_PQ_PAIR_ERROR_RESPONSE := SUBSTR(TRIM(MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE,v_PQ_PAIR_ERROR_XPATH)), 1,
                     4000 - LENGTH(v_PQ_PAIR_ERROR_TRAILER) - 2) || v_PQ_PAIR_ERROR_TRAILER;


  v_TOTAL_FAILURE_ERR_MESSAGE := TRIM(MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE,v_XPATH_FOR_ERR_MESSAGE));
  IF v_TOTAL_FAILURE_ERR_MESSAGE IS NOT NULL THEN
    RETURN v_TOTAL_FAILURE_ERR_MESSAGE;
  END IF;

  -- grab some data out of enclosing XML tags
  SELECT EXTRACTVALUE(p_RESPONSE, g_XPATH_TXN_ID)
  INTO v_SEM_TXN_ID
  FROM DUAL;

  SELECT TO_DATE( EXTRACTVALUE(p_RESPONSE, g_XPATH_DATE_SEARCH(p_ACTION)), MM_SEM_UTIL.g_DATE_FORMAT )
  INTO v_DATE
  FROM DUAL;

  SELECT EXTRACTVALUE(p_RESPONSE, g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT)||'/@gate_window')
  INTO v_GATE_WINDOW
  FROM DUAL;

  -- reset packages if necessary
  v_PKG_NAME := g_NEEDS_RESET_FOR_PARSE.FIRST;
  WHILE g_NEEDS_RESET_FOR_PARSE.EXISTS(v_PKG_NAME) LOOP
    IF g_NEEDS_RESET_FOR_PARSE(v_PKG_NAME) THEN
      BEGIN
        EXECUTE IMMEDIATE
          'BEGIN
            '||v_PKG_NAME||'.RESET_FOR_PARSE;
            END;';
      EXCEPTION
        WHEN OTHERS THEN
          p_LOGGER.LOG_ERROR('Failed to reset package '||v_PKG_NAME||' for response parsing - '||MM_SEM_UTIL.ERROR_STACKTRACE);
      END;
    END IF;
    v_PKG_NAME := g_NEEDS_RESET_FOR_PARSE.NEXT(v_PKG_NAME);
  END LOOP;

  -- make sure date is correct (if p_DATE is NULL then ignore this check)
  IF NVL(p_DATE,v_DATE) <> v_DATE THEN
    p_LOGGER.LOG_ERROR('Submitted request for '||TO_CHAR(p_DATE,MM_SEM_UTIL.g_DATE_FORMAT)||' but received response for '||TO_CHAR(v_DATE,MM_SEM_UTIL.g_DATE_FORMAT));
  END IF;

  -- now process all response elements

  FOR v_ELEMENT IN c_ELEMENTS LOOP
    v_COUNT := v_COUNT+1;

    -- get XML node name
    v_XML_DOC := XMLDOM.newDomDocument(v_ELEMENT.VAL);
        v_XML_NODE := XMLDOM.getTagName( XMLDOM.getDocumentElement( v_XML_DOC ) );
    XMLDOM.freeDocument ( v_XML_DOC );

    -- delegate processing of this XML node
    v_TXN_IDs := NULL; -- reset current transaction IDs

    IF NOT g_XML_NODE_TO_PKG.EXISTS(v_XML_NODE) THEN
      p_LOGGER.LOG_ERROR('Encountered unsupported tag in SEM response in element #'||v_COUNT||': <'||v_XML_NODE||'>');
      p_STATUS.ERROR := p_STATUS.ERROR + 1;
    ELSE
      -- determine transaction type
      v_TXN_TYPE := g_XML_NODE_TO_TXN_TYPE(v_XML_NODE);

      -- find out the transaction IDs represented by this XML node
      v_SQL :=
        'DECLARE
          v_TXN_IDs NUMBER_COLLECTION;
         BEGIN
          v_TXN_IDs := '||g_XML_NODE_TO_PKG(v_XML_NODE)||'.GET_TRANSACTION_IDs(:dt,:acct,:gw,:xml);
          :txn := v_TXN_IDs;
        END;';
      p_LOGGER.LOG_DEBUG(v_SQL);
      BEGIN
        -- get the transaction IDs
        EXECUTE IMMEDIATE v_SQL
          USING IN v_DATE, IN p_ACCOUNT_NAME, IN v_GATE_WINDOW, IN v_ELEMENT.VAL, OUT v_TXN_IDs;
        -- check the output value
        IF v_TXN_IDs IS NULL THEN
          p_LOGGER.LOG_ERROR('Could not determine transaction IDs for element #'||v_COUNT||': <'||v_XML_NODE||'>');
          p_STATUS.ERROR := p_STATUS.ERROR + 1;
        ELSIF v_TXN_IDs.COUNT = 0 THEN
          p_LOGGER.LOG_ERROR('Could not determine transaction IDs for element #'||v_COUNT||': <'||v_XML_NODE||'>');
          p_STATUS.ERROR := p_STATUS.ERROR + 1;
          -- null collection to skip subsequent processing
          v_TXN_IDs := NULL;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          p_LOGGER.LOG_ERROR(MM_SEM_UTIL.ERROR_STACKTRACE);
          -- null collection to skip subsequent processing
          v_TXN_IDs := NULL;
      END;
    END IF;

    IF v_TXN_IDs IS NOT NULL THEN
      -- Import the data
      v_SQL :=
        'DECLARE
          v_TXN_IDs NUMBER_COLLECTION := :txn;
        BEGIN
          :err := '||g_XML_NODE_TO_PKG(v_XML_NODE)||'.'||g_PROCESS_PROCS(p_ACTION)||'(v_TXN_IDs,:dt,:xml,:log);
        END;';
      p_LOGGER.LOG_DEBUG(v_SQL);
      BEGIN
        EXECUTE IMMEDIATE v_SQL
          USING IN v_TXN_IDs, OUT v_ERR_MSG, IN v_DATE, IN v_ELEMENT.VAL, IN OUT p_LOGGER;

        -- update status and process counts
        IF TRIM(v_ERR_MSG) IS NOT NULL THEN
      -- Log the error response and increment the error
      p_LOGGER.LOG_ERROR(v_PQ_PAIR_ERROR_RESPONSE);
          -- set status as rejected
          SET_STATUS( v_TXN_IDs, v_TXN_TYPE, v_DATE, NULL, p_MARKET_REJECTED_STATUS, v_ERR_MSG);
          p_STATUS.REJECTED := p_STATUS.REJECTED + v_TXN_IDs.COUNT;
        ELSE
          -- set status as accepted!
          SET_STATUS(v_TXN_IDs, v_TXN_TYPE, v_DATE, NULL, p_MARKET_ACCEPTED_STATUS);
          p_STATUS.SUCCEEDED := p_STATUS.SUCCEEDED + v_TXN_IDs.COUNT;
        END IF;
      EXCEPTION
        WHEN OTHERS THEN
          SET_STATUS(v_TXN_IDs, v_TXN_TYPE, v_DATE, NULL, p_MARKET_ERROR_STATUS, MM_SEM_UTIL.ERROR_STACKTRACE);
          p_STATUS.ERROR := p_STATUS.ERROR + v_TXN_IDs.COUNT;
          v_TXN_IDs := NULL; -- set to null to skip subsequent step
      END;
    END IF;

    IF g_NEEDS_SEM_TXN_ID(p_ACTION) AND v_TXN_IDs IS NOT NULL THEN
      v_IDX := v_TXN_IDs.FIRST;
      WHILE v_TXN_IDs.EXISTS(v_IDX) LOOP
        v_TXN_NAME := ENTITY_NAME_FROM_IDS(EC.ED_TRANSACTION, v_TXN_IDs(v_IDX));
        -- save the SEM transaction ID if we need to
        BEGIN
          TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(v_TXN_IDs(v_IDX), GA.INTERNAL_STATE, 0, TRUNC(v_DATE)+1/86400,
                        MM_SEM_UTIL.g_TG_SEM_TXN_ID, 1, 1, v_SEM_TXN_ID);
        EXCEPTION
          WHEN OTHERS THEN
             p_LOGGER.LOG_WARN('Could not save SEM transaction_id ('||v_SEM_TXN_ID||') for "'||v_TXN_NAME||'". '||MM_SEM_UTIL.ERROR_STACKTRACE);
        END;

        IF p_ACTION = g_ACTION_UUT_SUBMIT THEN
            -- save the SEM transaction ID if we need to
            BEGIN
              TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(v_TXN_IDs(v_IDX), GA.INTERNAL_STATE, 0, TRUNC(v_DATE)+1/86400,
                            MM_SEM_UTIL.g_TG_GEN_UNDER_TEST, MM_SEM_UTIL.g_TI_TXN_ID, 1, v_SEM_TXN_ID);
            EXCEPTION
              WHEN OTHERS THEN
                 p_LOGGER.LOG_WARN('Could not save Unit Test transaction_id ('||v_SEM_TXN_ID||') for "'||v_TXN_NAME||'". '||MM_SEM_UTIL.ERROR_STACKTRACE);
            END;
         END IF;

        v_IDX := v_TXN_IDs.NEXT(v_IDX);
      END LOOP;
    END IF;

  END LOOP;

  -- No errors
  RETURN NULL;

END PROCESS_RESPONSE;
------------------------------------------------------------------------------
PROCEDURE SEND_REQUEST
  (
  p_REQUEST IN XMLTYPE,
  P_TXN_IDs IN NUMBER_COLLECTION,
  p_TXN_NAMES IN STRING_COLLECTION,
  p_TXN_TYPE IN VARCHAR2,
  p_ACCOUNT_NAME IN VARCHAR2,
  p_DATE IN DATE,
  p_CRED IN OUT NOCOPY MEX_CREDENTIALS,
  p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
  p_EXCHANGE_NAME_PROCESS IN VARCHAR2,
  p_ACTION IN PLS_INTEGER,
  p_PRIOR_SUBMIT_STATUS IN VARCHAR2,
  p_PRIOR_SUBMIT_MKT_STATUS IN VARCHAR2,
  p_POST_SUBMIT_STATUS IN VARCHAR2,
  p_POST_SUBMIT_ERROR_STATUS IN VARCHAR2,
  p_MARKET_ACCEPTED_STATUS IN VARCHAR2,
  p_MARKET_REJECTED_STATUS IN VARCHAR2,
  p_MARKET_ERROR_STATUS IN VARCHAR2,
  p_STATUS OUT t_PROGRESS
  ) AS
v_REQUEST_XML XMLTYPE;
v_REQUEST_CLOB  CLOB := NULL;
v_TAG  VARCHAR2(256);
v_RESULT MEX_RESULT;
v_REC t_PROGRESS;
v_ERROR_MESSAGE VARCHAR2(4000);
v_GATE_WINDOW INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;

BEGIN
  p_STATUS.SUCCEEDED := 0;
  p_STATUS.REJECTED := 0;
  p_STATUS.ERROR := 0;
  v_GATE_WINDOW := NULL;
  LOGS.LOG_INFO('p_ACCOUNT_NAME:'''|| (p_ACCOUNT_NAME) ||'');
  DBMS_LOB.CREATETEMPORARY(v_REQUEST_CLOB, TRUE);
  DBMS_LOB.OPEN(v_REQUEST_CLOB, DBMS_LOB.LOB_READWRITE);
  -- This tag is not in the XMLTYPE to prevent Oracle from trying to validate
  -- the doc against the specified XSD

  v_TAG := '<bids_offers xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="mint_sem.xsd">';
  DBMS_LOB.WRITEAPPEND(v_REQUEST_CLOB, LENGTH(v_TAG), v_TAG);
  -- Query for XML body
  IF (p_TXN_TYPE IN ('Generation', 'Nomination'))
  THEN
    v_GATE_WINDOW := MM_SEM_OFFER_UTIL.GET_GATE_WINDOW(p_TXN_IDs(1));
  END IF;

  IF (v_GATE_WINDOW IS NOT NULL AND (p_ACTION NOT IN  (g_ACTION_UUT_SUBMIT, g_ACTION_UUT_QUERY) )) THEN
       EXECUTE IMMEDIATE
      'SELECT XMLELEMENT ( "'||g_MARKET_NODES(p_ACTION)||'",
               XMLATTRIBUTES ( :g_APP_TYPE as "application_type",
                         TO_CHAR(:p_DATE,:g_DATE_FORMAT) as "trading_date",
                         :p_ACCOUNT_NAME as "participant_name",
                         :p_USERNAME as "user_name",
                         :g_MODE as "mode",
                         :v_GATE_WINDOW as "gate_window" ),
              :p_REQUEST
              )
      FROM DUAL'
    INTO v_REQUEST_XML
    USING g_APP_TYPE, p_DATE, MM_SEM_UTIL.g_DATE_FORMAT,
        p_ACCOUNT_NAME, p_CRED.USERNAME, g_MODE, v_GATE_WINDOW, p_REQUEST ;
   ELSE
     EXECUTE IMMEDIATE
    'SELECT XMLELEMENT ( "'||g_MARKET_NODES(p_ACTION)||'",
             XMLATTRIBUTES ( :g_APP_TYPE as "application_type",
                        TO_CHAR(:p_DATE,:g_DATE_FORMAT) as "trading_date",
                       :p_ACCOUNT_NAME as "participant_name",
                       :p_USERNAME as "user_name",
                       :g_MODE as "mode" ),
            :p_REQUEST
            )
    FROM DUAL'
  INTO v_REQUEST_XML
  USING g_APP_TYPE, p_DATE, MM_SEM_UTIL.g_DATE_FORMAT,
      p_ACCOUNT_NAME, p_CRED.USERNAME, g_MODE, p_REQUEST;
  END IF;


  -- Add this XML to the request CLOB
  DBMS_LOB.APPEND(v_REQUEST_CLOB, v_REQUEST_XML.GETCLOBVAL());
  -- And stick the trailing close-tag
  v_TAG := '</bids_offers>';
  DBMS_LOB.WRITEAPPEND(v_REQUEST_CLOB, LENGTH(v_TAG), v_TAG);
  DBMS_LOB.CLOSE(v_REQUEST_CLOB);


  IF MM_SEM_UTIL.g_TEST THEN
    -- just doing a test? then log the request and nothing else
    p_LOGGER.LOG_START('test.'||MM_SEM_UTIL.g_MEX_MARKET, MM_SEM_UTIL.g_MEX_ACTION_OFFERS);
    p_LOGGER.LOG_REQUEST(NULL, v_REQUEST_CLOB, 'text/xml');
    p_LOGGER.LOG_STOP(0, 'Success');
  ELSE

    -- set SUBMIT_STATUS to 'Pending'
    SET_STATUS(p_TXN_IDs, p_TXN_TYPE, p_DATE, p_PRIOR_SUBMIT_STATUS, p_PRIOR_SUBMIT_MKT_STATUS);

    -- submit !
    v_RESULT := MEX_Switchboard.Invoke(MM_SEM_UTIL.g_MEX_MARKET, MM_SEM_UTIL.g_MEX_ACTION_OFFERS,
                      p_LOGGER, p_CRED, p_REQUEST_CONTENTTYPE => 'text/xml', p_REQUEST => v_REQUEST_CLOB);

    IF v_RESULT.STATUS_CODE <> Mex_Switchboard.c_Status_Success THEN
        PROCESS_ERRORS(p_TXN_NAMES, p_DATE, Mex_Switchboard.GetErrorText(v_RESULT), p_LOGGER);
          p_STATUS.ERROR := p_STATUS.ERROR + p_TXN_IDs.COUNT;
          -- set SUBMIT_STATUS to 'Error'
      SET_STATUS(p_TXN_IDs, p_TXN_TYPE, p_DATE, p_POST_SUBMIT_ERROR_STATUS, NULL);
    ELSE
      p_LOGGER.EXCHANGE_NAME := p_EXCHANGE_NAME_PROCESS;

      -- set SUBMIT_STATUS to 'Submitted'
      SET_STATUS(p_TXN_IDs, p_TXN_TYPE, p_DATE, p_POST_SUBMIT_STATUS, NULL);
         BEGIN
        -- process the response
        v_ERROR_MESSAGE := PROCESS_RESPONSE(p_ACCOUNT_NAME, p_DATE, XMLTYPE(v_RESULT.RESPONSE),
                          p_LOGGER, p_ACTION,  p_MARKET_ACCEPTED_STATUS,
                          p_MARKET_REJECTED_STATUS, p_MARKET_ERROR_STATUS, v_REC);

        -- Check if there is any Total failure error message
        IF v_ERROR_MESSAGE IS NULL THEN
          p_STATUS.SUCCEEDED := p_STATUS.SUCCEEDED + v_REC.SUCCEEDED;
          p_STATUS.REJECTED := p_STATUS.REJECTED + v_REC.REJECTED;
          p_STATUS.ERROR := p_STATUS.ERROR + v_REC.ERROR;
        ELSE
          PROCESS_ERRORS(p_TXN_NAMES, p_DATE, v_ERROR_MESSAGE, p_LOGGER);
          p_STATUS.ERROR := p_STATUS.ERROR + p_TXN_IDs.COUNT;
          SET_STATUS(p_TXN_IDs, p_TXN_TYPE, p_DATE, NULL, p_MARKET_ERROR_STATUS, v_ERROR_MESSAGE);
        END IF;

         EXCEPTION
           WHEN OTHERS THEN
          PROCESS_ERRORS(p_TXN_NAMES, p_DATE, MM_SEM_UTIL.ERROR_STACKTRACE, p_LOGGER);
            p_STATUS.ERROR := p_STATUS.ERROR + p_TXN_IDs.COUNT;
          -- set MARKET_STATUS to 'Error'
          SET_STATUS(p_TXN_IDs, p_TXN_TYPE, p_DATE, NULL, p_MARKET_ERROR_STATUS, MM_SEM_UTIL.ERROR_STACKTRACE);
         END;
    END IF;
  END IF;

  -- free the CLOB
  IF v_REQUEST_CLOB IS NOT NULL THEN
    IF DBMS_LOB.ISOPEN(v_REQUEST_CLOB) <> 0 THEN
      DBMS_LOB.CLOSE(v_REQUEST_CLOB);
    END IF;
    DBMS_LOB.FREETEMPORARY(v_REQUEST_CLOB);
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    IF v_REQUEST_CLOB IS NOT NULL THEN
        IF DBMS_LOB.ISOPEN(v_REQUEST_CLOB) <> 0 THEN
          DBMS_LOB.CLOSE(v_REQUEST_CLOB);
        END IF;
      DBMS_LOB.FREETEMPORARY(v_REQUEST_CLOB);
    END IF;
    RAISE;
END SEND_REQUEST;
------------------------------------------------------------------------------
FUNCTION DOES_LIST_CONTAIN
  (
  p_IDs IN GA.ID_TABLE,
  p_ID IN NUMBER
  ) RETURN BOOLEAN IS
v_IDX BINARY_INTEGER;
BEGIN
  v_IDX := p_IDs.FIRST;
  WHILE p_IDs.EXISTS(v_IDX) LOOP
    IF p_IDs(v_IDX) = p_ID THEN
      -- found it!
      RETURN TRUE;
    END IF;
    v_IDX := p_IDs.NEXT(v_IDX);
  END LOOP;

  -- didn't find it
  RETURN FALSE;
END DOES_LIST_CONTAIN;
------------------------------------------------------------------------------
FUNCTION COUNT_ELEMENTS
  (
  p_MAP IN t_XML_MAP
  ) RETURN BINARY_INTEGER IS
v_RET BINARY_INTEGER := 0;
v_KEY VARCHAR2(64);
BEGIN
  v_KEY := p_MAP.FIRST;
  WHILE p_MAP.EXISTS(v_KEY) LOOP
    v_RET := v_RET + p_MAP(v_KEY).COUNT;
    v_KEY := p_MAP.NEXT(v_KEY);
  END LOOP;

  RETURN v_RET;
END COUNT_ELEMENTS;
------------------------------------------------------------------------------
PROCEDURE INVOKE
  (
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_ACTION IN PLS_INTEGER,
  p_REQUIRED_STATUS IN VARCHAR2,
  p_PRIOR_SUBMIT_STATUS IN VARCHAR2,
  p_PRIOR_SUBMIT_MKT_STATUS IN VARCHAR2,
  p_POST_SUBMIT_STATUS IN VARCHAR2,
  p_POST_SUBMIT_ERR_STATUS IN VARCHAR2,
  p_MARKET_ACCEPTED_STATUS IN VARCHAR2,
  p_MARKET_REJECTED_STATUS IN VARCHAR2,
  p_MARKET_ERROR_STATUS IN VARCHAR2,
  p_PROCESS_NAME IN VARCHAR2,
  p_EXCHANGE_NAME_SUBMIT IN VARCHAR2,
  p_EXCHANGE_NAME_PROCESS IN VARCHAR2,
  p_ALLOW_ALL_ID IN BOOLEAN,
  p_MESSAGE_VERB1 IN VARCHAR2,
  p_MESSAGE_VERB2 IN VARCHAR2,
  p_MESSAGE_TOTAL_WORD IN VARCHAR2,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
v_XML XMLTYPE;
v_XML_MAP t_MAP_OF_XML_MAPS; -- map of account names to (maps of transaction types to xml lists -- one xml per transaction)
v_TXN_ID_MAP t_MAP_OF_ID_MAPS; -- map of account names to (maps of transaction types to ID lists -- transaction IDs)
v_TXN_NAME_MAP t_MAP_OF_NAME_MAPS; -- map of account names to (maps of transaction types to name lists -- transaction names)

v_LOGGER MM_LOGGER_ADAPTER;
v_CRED MEX_CREDENTIALS;

v_IDs GA.ID_TABLE;
v_IDX BINARY_INTEGER;
v_JDX BINARY_INTEGER;
v_TXN_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_TXN_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
v_ACCOUNT_NAME VARCHAR2(64);
v_ADDED BOOLEAN;
v_DATE DATE;
v_TXN_IDs_SENT NUMBER_COLLECTION;
v_TXN_NAMES_SENT STRING_COLLECTION;
v_LIST_CONTAINS_ALL BOOLEAN := FALSE;

v_TXN_COUNT PLS_INTEGER := 0;
v_PROCESS_COUNT t_PROGRESS;
v_SUBMIT_COUNT t_PROGRESS;
v_REC t_PROGRESS;
v_DUMMY VARCHAR2(512);

BEGIN
  p_STATUS := GA.SUCCESS;
  v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM, NULL, p_PROCESS_NAME, p_EXCHANGE_NAME_SUBMIT, p_LOG_TYPE, p_TRACE_ON);
  MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);
  LOGS.LOG_INFO_MORE_DETAIL('p_ENTITY_LIST:'''|| p_ENTITY_LIST ||'''p_ENTITY_LIST_DELIMITER:'''|| p_ENTITY_LIST_DELIMITER ||'');

  -- initialize these records
  v_PROCESS_COUNT.SUCCEEDED := 0;
  v_PROCESS_COUNT.REJECTED := 0;
  v_PROCESS_COUNT.ERROR := 0;
  v_SUBMIT_COUNT.SUCCEEDED := 0;
  v_SUBMIT_COUNT.REJECTED := 0;
  v_SUBMIT_COUNT.ERROR := 0;

  UT.IDS_FROM_STRING(p_ENTITY_LIST, p_ENTITY_LIST_DELIMITER, v_IDs);

  v_DATE := TRUNC(p_BEGIN_DATE);
  WHILE v_DATE <= TRUNC(p_END_DATE) LOOP

    v_XML_MAP.DELETE;
    v_TXN_ID_MAP.DELETE;
    v_TXN_NAME_MAP.DELETE;

      v_IDX := v_IDs.FIRST;

    IF DOES_LIST_CONTAIN(v_IDs, MM_SEM_UTIL.g_ALL) AND p_ALLOW_ALL_ID THEN
      v_LIST_CONTAINS_ALL := TRUE;
      --------------------------------------------
      -- process ALL transaction for this request
      --------------------------------------------
      DECLARE
        v_XML_LISTS t_XML_MAP;
        v_AVAIL_ACCOUNTS STRING_COLLECTION;
      BEGIN
        v_TXN_TYPE := g_TXN_TYPE_TO_PKG.FIRST;

        WHILE g_TXN_TYPE_TO_PKG.EXISTS(v_TXN_TYPE) LOOP
          v_TXN_NAME := '<All '||v_TXN_TYPE||'>';

          -- dynamically delegate to package all XML pieces together
          EXECUTE IMMEDIATE
               'BEGIN
                 :xml := '||g_TXN_TYPE_TO_PKG(v_TXN_TYPE)||'.'||g_CREATE_PROCS(p_ACTION)||'(:dt,:id,:log);
                END;'
                USING OUT v_XML, IN v_DATE, IN MM_SEM_UTIL.g_ALL, IN OUT v_LOGGER;

                IF v_XML IS NOT NULL THEN
                    v_PROCESS_COUNT.SUCCEEDED := v_PROCESS_COUNT.SUCCEEDED + 1;
                    v_XML_LISTS(v_TXN_TYPE) := XMLSequenceType(v_XML);
                END IF;
          v_TXN_TYPE := g_TXN_TYPE_TO_PKG.NEXT(v_TXN_TYPE);
        END LOOP;

        -- now organize result set of XML entries into v_XML_MAP
        v_AVAIL_ACCOUNTS := SECURITY_CONTROLS.GET_AVAIL_EXTERNAL_ACCOUNTS(EC.ES_SEM);
        v_JDX := v_AVAIL_ACCOUNTS.FIRST;
        WHILE v_AVAIL_ACCOUNTS.EXISTS(v_JDX) LOOP
          v_XML_MAP(v_AVAIL_ACCOUNTS(v_JDX)) := v_XML_LISTS;
          v_JDX := v_AVAIL_ACCOUNTS.NEXT(v_JDX);
        END LOOP;

      EXCEPTION
        WHEN OTHERS THEN
              v_LOGGER.LOG_ERROR(GET_MESSAGE('ERROR', v_TXN_NAME, v_DATE, 'Creating submission XML - '||MM_SEM_UTIL.ERROR_STACKTRACE));
          v_XML := NULL;
          v_PROCESS_COUNT.ERROR := v_PROCESS_COUNT.ERROR + 1;
      END;
    ELSE
      ---------------------------------------------------
      -- process requested transactions for this request
      ---------------------------------------------------
          WHILE v_IDs.EXISTS(v_IDX) LOOP

          v_TXN_COUNT := v_TXN_COUNT+1;
            GET_TRANSACTION_INFO(v_IDs(v_IDX), v_TXN_NAME, v_TXN_TYPE);

               v_XML := NULL;

          IF CHECK_STATUS(v_IDs(v_IDX), v_TXN_TYPE, v_DATE, p_REQUIRED_STATUS) THEN
               -- process this transaction for submission
              BEGIN
            IF NOT g_TXN_TYPE_TO_PKG.EXISTS(v_TXN_TYPE) THEN
                      v_LOGGER.LOG_WARN(GET_MESSAGE('SKIPPING', v_TXN_NAME, v_DATE, 'Transactions with a type of "'||v_TXN_TYPE||'" cannot be '||p_MESSAGE_VERB2));
                  v_PROCESS_COUNT.REJECTED := v_PROCESS_COUNT.REJECTED + 1;
            ELSE
                EXECUTE IMMEDIATE
                    'BEGIN
                      :xml := '||g_TXN_TYPE_TO_PKG(v_TXN_TYPE)||'.'||g_CREATE_PROCS(p_ACTION)||'(:dt,:id,:log);
                     END;'
                     USING OUT v_XML, IN v_DATE, IN v_IDs(v_IDX), IN OUT v_LOGGER;
            END IF;

            IF v_XML IS NULL THEN
                      v_LOGGER.LOG_WARN(GET_MESSAGE('SKIPPING', v_TXN_NAME, v_DATE, 'Transaction cannot be '||p_MESSAGE_VERB2));
                  v_PROCESS_COUNT.REJECTED := v_PROCESS_COUNT.REJECTED + 1;
            END IF;

              EXCEPTION
                WHEN OTHERS THEN
                      v_LOGGER.LOG_ERROR(GET_MESSAGE('ERROR', v_TXN_NAME, v_DATE, 'Creating request XML - '||MM_SEM_UTIL.ERROR_STACKTRACE));
                  v_XML := NULL;
                  v_PROCESS_COUNT.ERROR := v_PROCESS_COUNT.ERROR + 1;
              END;
          ELSE
            -- transaction not approved - cannot submit!
                    v_LOGGER.LOG_WARN(GET_MESSAGE('SKIPPING', v_TXN_NAME, v_DATE, 'Transactions that are not '||p_REQUIRED_STATUS||' cannot be '||p_MESSAGE_VERB2));
                    v_PROCESS_COUNT.REJECTED := v_PROCESS_COUNT.REJECTED + 1;
          END IF;

            IF v_XML IS NOT NULL THEN
            v_PROCESS_COUNT.SUCCEEDED := v_PROCESS_COUNT.SUCCEEDED + 1;
              v_ACCOUNT_NAME := MM_SEM_UTIL.GET_EXTERNAL_ACCOUNT_NAME(v_IDs(v_IDX));
          v_ADDED := FALSE;
              IF v_XML_MAP.EXISTS(v_ACCOUNT_NAME) THEN
            IF v_XML_MAP(v_ACCOUNT_NAME).EXISTS(v_TXN_TYPE) THEN
                  -- append to existing lists
                  v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).EXTEND;
                  v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE)(v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).LAST) := v_XML;
                  v_TXN_ID_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).EXTEND;
                  v_TXN_ID_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE)(v_TXN_ID_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).LAST) := v_IDs(v_IDX);
                  v_TXN_NAME_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).EXTEND;
                  v_TXN_NAME_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE)(v_TXN_NAME_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).LAST) := v_TXN_NAME;
              v_ADDED := TRUE;
            END IF;
          END IF;
          IF NOT v_ADDED THEN
                -- create new lists with this one entry
                v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE) := XMLSequenceType(v_XML);
                v_TXN_ID_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE) := NUMBER_COLLECTION(v_IDs(v_IDX));
                 v_TXN_NAME_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE) := STRING_COLLECTION(v_TXN_NAME);
               END IF;
            END IF;

            v_IDX := v_IDs.NEXT(v_IDX);
          END LOOP;
    END IF;

    ----------------------------------------------------------------
    -- now that we've built all submission XML pieces - submit them!
    ----------------------------------------------------------------

    v_ACCOUNT_NAME := v_XML_MAP.FIRST;
    WHILE v_XML_MAP.EXISTS(v_ACCOUNT_NAME) LOOP
      BEGIN
        -- ignore the returned logger - we already have a logger we can use
        MM_UTIL.INIT_MEX(EC.ES_SEM, v_ACCOUNT_NAME, p_PROCESS_NAME, p_EXCHANGE_NAME_SUBMIT, p_LOG_TYPE, p_TRACE_ON, v_CRED, v_LOGGER);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          v_LOGGER.LOG_ERROR('No external credentials available for "'||v_ACCOUNT_NAME||'". '||COUNT_ELEMENTS(v_XML_MAP(v_ACCOUNT_NAME))||' schedules not submitted.');
          v_SUBMIT_COUNT.ERROR := v_SUBMIT_COUNT.ERROR + COUNT_ELEMENTS(v_XML_MAP(v_ACCOUNT_NAME));
          v_CRED := NULL;
      END;

      IF v_CRED IS NOT NULL OR MM_SEM_UTIL.g_TEST THEN -- no credentials? no need to proceed

          v_TXN_TYPE := v_XML_MAP(v_ACCOUNT_NAME).FIRST;
          WHILE v_XML_MAP(v_ACCOUNT_NAME).EXISTS(v_TXN_TYPE) LOOP

            IF NOT v_LIST_CONTAINS_ALL THEN
            IF g_IS_ONE_AT_A_TIME(v_TXN_TYPE) THEN
              v_JDX := v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).FIRST;
              WHILE v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).EXISTS(v_JDX) LOOP
                -- send one XML element at a time
                v_TXN_IDs_SENT := NUMBER_COLLECTION( v_TXN_ID_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE)(v_JDX) );
                v_TXN_NAMES_SENT := STRING_COLLECTION( v_TXN_NAME_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE)(v_JDX) );
                DECLARE
                  CURSOR c_XML_RECS IS
                    SELECT VALUE(T) as VAL
                    FROM TABLE(XMLSEQUENCE(EXTRACT( v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE)(v_JDX) ,'/*' ))) T;
                BEGIN
                  FOR v_XML_REC IN c_XML_RECS LOOP

                    SEND_REQUEST(v_XML_REC.VAL, v_TXN_IDs_SENT, v_TXN_NAMES_SENT, V_TXN_TYPE, v_ACCOUNT_NAME,
                           v_DATE, v_CRED, v_LOGGER, p_EXCHANGE_NAME_PROCESS,
                           p_ACTION, p_PRIOR_SUBMIT_STATUS, p_PRIOR_SUBMIT_MKT_STATUS,
                           p_POST_SUBMIT_STATUS, p_POST_SUBMIT_ERR_STATUS,
                           p_MARKET_ACCEPTED_STATUS, p_MARKET_REJECTED_STATUS, p_MARKET_ERROR_STATUS,
                           v_REC);
                    v_SUBMIT_COUNT.SUCCEEDED := v_SUBMIT_COUNT.SUCCEEDED + v_REC.SUCCEEDED;
                    v_SUBMIT_COUNT.REJECTED := v_SUBMIT_COUNT.REJECTED + v_REC.REJECTED;
                    v_SUBMIT_COUNT.ERROR := v_SUBMIT_COUNT.ERROR + v_REC.ERROR;
                  END LOOP;
                END;
                v_JDX := v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE).NEXT(v_JDX);
              END LOOP;
            ELSE
              -- send the whole XML in one shot
              SELECT XMLCONCAT(CAST(v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE) AS XMLSequenceType))
              INTO v_XML
              FROM DUAL;

              v_TXN_IDs_SENT := v_TXN_ID_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE);
              v_TXN_NAMES_SENT := v_TXN_NAME_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE);

              SEND_REQUEST(v_XML, v_TXN_IDs_SENT, v_TXN_NAMES_SENT, V_TXN_TYPE, v_ACCOUNT_NAME,
                     v_DATE, v_CRED, v_LOGGER, p_EXCHANGE_NAME_PROCESS,
                     p_ACTION, p_PRIOR_SUBMIT_STATUS, p_PRIOR_SUBMIT_MKT_STATUS,
                     p_POST_SUBMIT_STATUS, p_POST_SUBMIT_ERR_STATUS,
                     p_MARKET_ACCEPTED_STATUS, p_MARKET_REJECTED_STATUS, p_MARKET_ERROR_STATUS,
                     v_REC);
              v_SUBMIT_COUNT.SUCCEEDED := v_SUBMIT_COUNT.SUCCEEDED + v_REC.SUCCEEDED;
              v_SUBMIT_COUNT.REJECTED := v_SUBMIT_COUNT.REJECTED + v_REC.REJECTED;
              v_SUBMIT_COUNT.ERROR := v_SUBMIT_COUNT.ERROR + v_REC.ERROR;
            END IF;
          ELSE
              -- For '<ALL'> id, set the Transaction IDs send and Names collection to null
              SELECT XMLCONCAT(CAST(v_XML_MAP(v_ACCOUNT_NAME)(v_TXN_TYPE) AS XMLSequenceType))
              INTO v_XML
              FROM DUAL;

              v_TXN_IDs_SENT := NUMBER_COLLECTION();
              v_TXN_NAMES_SENT := STRING_COLLECTION();

              SEND_REQUEST(v_XML, v_TXN_IDs_SENT, v_TXN_NAMES_SENT, V_TXN_TYPE, v_ACCOUNT_NAME,
                     v_DATE, v_CRED, v_LOGGER, p_EXCHANGE_NAME_PROCESS,
                     p_ACTION, p_PRIOR_SUBMIT_STATUS, p_PRIOR_SUBMIT_MKT_STATUS,
                     p_POST_SUBMIT_STATUS, p_POST_SUBMIT_ERR_STATUS,
                     p_MARKET_ACCEPTED_STATUS, p_MARKET_REJECTED_STATUS, p_MARKET_ERROR_STATUS,
                     v_REC);
              v_SUBMIT_COUNT.SUCCEEDED := v_SUBMIT_COUNT.SUCCEEDED + v_REC.SUCCEEDED;
              v_SUBMIT_COUNT.REJECTED := v_SUBMIT_COUNT.REJECTED + v_REC.REJECTED;
              v_SUBMIT_COUNT.ERROR := v_SUBMIT_COUNT.ERROR + v_REC.ERROR;
          END IF;

            v_TXN_TYPE := v_XML_MAP(v_ACCOUNT_NAME).NEXT(v_TXN_TYPE);
          END LOOP;

      END IF;

      v_ACCOUNT_NAME := v_XML_MAP.NEXT(v_ACCOUNT_NAME);
    END LOOP;

    -- On to the next Day!
    v_DATE := v_DATE+1;
  END LOOP;

  -- Formulate log message for completion
  IF MM_SEM_UTIL.g_TEST THEN
        p_MESSAGE := 'Test completed - '||GET_MESSAGE(v_PROCESS_COUNT, p_MESSAGE_VERB1, 'skipped', 'had errors');
  ELSE
        p_MESSAGE := GET_MESSAGE(v_PROCESS_COUNT, p_MESSAGE_VERB1, 'skipped', 'had errors');
        p_MESSAGE := p_MESSAGE||UTL_TCP.CRLF||GET_MESSAGE(v_SUBMIT_COUNT, p_MESSAGE_VERB2, p_TOTAL_WORD => p_MESSAGE_TOTAL_WORD);
  END IF;
  MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);
  -- Done!

  -- Raise Alerts
  MM_SEM_UTIL.RAISE_ALERTS(p_TYPE => g_ALERT_TYPE_OFFER,
                           p_NAME => g_ALERT_NAMES(p_ACTION),
                           p_LOGGER => v_LOGGER,
                           p_MSG => p_MESSAGE);
EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);

    -- Raise Alerts
    MM_SEM_UTIL.RAISE_ALERTS(p_TYPE => g_ALERT_TYPE_OFFER,
                             p_NAME => g_ALERT_NAMES(p_ACTION),
                             p_LOGGER => v_LOGGER,
                             p_MSG => p_MESSAGE,
                            p_FATAL => TRUE);

END INVOKE;
------------------------------------------------------------------------------
PROCEDURE SUBMIT_OFFERS
  (
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
BEGIN

  INVOKE(p_ENTITY_LIST, p_ENTITY_LIST_DELIMITER, p_BEGIN_DATE, p_END_DATE,
      g_ACTION_SUBMIT, 'Accepted', 'Pending', ' ', 'Submitted', 'Error',
      'Accepted', 'Rejected', 'Error', 'Submit Offers', 'Submit Offers',
      'Process Submit Response', FALSE, 'processed for submission', 'submitted',
      'submitted', p_LOG_TYPE, p_TRACE_ON, p_STATUS, p_MESSAGE);
       LOGS.LOG_INFO_MORE_DETAIL('p_ENTITY_LIST:'''|| p_ENTITY_LIST ||'');
END SUBMIT_OFFERS;
------------------------------------------------------------------------------
PROCEDURE SUBMIT_SRA_CANCELLATION
  (
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
BEGIN

  INVOKE(p_ENTITY_LIST, p_ENTITY_LIST_DELIMITER, p_BEGIN_DATE, p_END_DATE,
      g_ACTION_SUBMIT_CANCEL, 'Accepted', 'Pending', ' ', 'Submitted', 'Error',
      'Accepted', 'Rejected', 'Error', 'Submit SRA Cancellation', 'Submit SRA Cancellation',
      'Process Submit Response', FALSE, 'processed for submission', 'submitted',
      'submitted', p_LOG_TYPE, p_TRACE_ON, p_STATUS, p_MESSAGE);
       LOGS.LOG_INFO_MORE_DETAIL('p_ENTITY_LIST:'''|| p_ENTITY_LIST ||'');
END SUBMIT_SRA_CANCELLATION;
------------------------------------------------------------------------------
PROCEDURE SUBMIT_UUT
  (
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
BEGIN
  INVOKE(p_ENTITY_LIST, p_ENTITY_LIST_DELIMITER, p_BEGIN_DATE, p_END_DATE,
      g_ACTION_UUT_SUBMIT, 'Accepted', 'Pending', ' ', 'Submitted', 'Error',
      'Accepted', 'Rejected', 'Error', 'Submit Unit Under Test', 'Submit Unit Under Test',
      'Process Submit Response', FALSE, 'processed for submission', 'submitted',
      'submitted', p_LOG_TYPE, p_TRACE_ON, p_STATUS, p_MESSAGE);
       LOGS.LOG_INFO_MORE_DETAIL('p_ENTITY_LIST:'''|| p_ENTITY_LIST ||'');
END SUBMIT_UUT;
------------------------------------------------------------------------------
PROCEDURE QUERY_OFFERS
  (
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
BEGIN
  INVOKE(p_ENTITY_LIST, p_ENTITY_LIST_DELIMITER, p_BEGIN_DATE, p_END_DATE,
      g_ACTION_QUERY, NULL, NULL, NULL, NULL, NULL,
      NULL, NULL, NULL, 'Query Offers', 'Query Offers',
      'Process Query Response', TRUE, 'processed for query', 'imported',
      'queried', p_LOG_TYPE, p_TRACE_ON, p_STATUS, p_MESSAGE);
END QUERY_OFFERS;
------------------------------------------------------------------------------
PROCEDURE QUERY_UUT
  (
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
BEGIN
  INVOKE(p_ENTITY_LIST, p_ENTITY_LIST_DELIMITER, p_BEGIN_DATE, p_END_DATE,
      g_ACTION_UUT_QUERY, NULL, NULL, NULL, NULL, NULL,
      NULL, NULL, NULL, 'Query Generator Unit Under Test', 'Query Generator Unit Under Test',
      'Process Query Response', TRUE, 'processed for query', 'imported',
      'queried', p_LOG_TYPE, p_TRACE_ON, p_STATUS, p_MESSAGE);
END QUERY_UUT;
------------------------------------------------------------------------------
PROCEDURE OFFER_ENTITY_LIST
  (
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_INCLUDE_ALL IN NUMBER,
  p_LABEL OUT VARCHAR2,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2,
  p_CURSOR OUT REF_CURSOR
  ) AS
BEGIN
  p_STATUS := GA.SUCCESS;

  p_LABEL := 'Transactions';

  OPEN p_CURSOR FOR
    SELECT '<ALL>' as TRANSACTION_NAME, MM_SEM_UTIL.g_ALL as TRANSACTION_ID
    FROM DUAL
    WHERE p_INCLUDE_ALL = 1
    UNION ALL
    SELECT *
    FROM (SELECT IT.TRANSACTION_NAME, IT.TRANSACTION_ID
              FROM INTERCHANGE_TRANSACTION IT
              WHERE IT.BEGIN_DATE <= p_END_DATE
                AND IT.END_DATE >= p_BEGIN_DATE
                AND IT.SC_ID = MM_SEM_UTIL.SEM_SC_ID
                AND IT.IS_BID_OFFER = 1
                AND IT.TRANSACTION_TYPE IN ('Generation','Nomination','Load','SRA')
              AND EXISTS (SELECT 1
                    FROM EXTERNAL_SYSTEM_IDENTIFIER ESI
                    WHERE ESI.EXTERNAL_SYSTEM_ID = EC.ES_SEM
                      AND ESI.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT
                      AND ESI.ENTITY_ID = IT.CONTRACT_ID)
              ORDER BY 1 ASC);
EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
END OFFER_ENTITY_LIST;
----------------------------------------------------------------------------
/*
** OFFER_ENTITY_LIST_GATE is similar to OFFER_ENTITY_LIST except it is used in retrieving
** transaction lists of bid requests except that it has specific requirement to return only
** certain types of transactions
*/
PROCEDURE OFFER_ENTITY_LIST_GATE
  (
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_INCLUDE_ALL IN NUMBER,
  p_GATE_WINDOW IN VARCHAR2,
  p_TRANSACTION_TYPE IN VARCHAR2,
  p_LABEL OUT VARCHAR2,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2,
  p_CURSOR OUT REF_CURSOR
  ) AS

  v_POD_ID VARCHAR2(5);
BEGIN
  p_STATUS := GA.SUCCESS;

  p_LABEL := 'Transactions';

  -- Determine the EXTENRAL_ID FRON TRANSACTION TYPE
  -- Nomination = "I_"
  -- Generation = "GU_"
  SELECT CASE(p_TRANSACTION_TYPE)
            WHEN 'Nomination'
            THEN 'I_%'
            WHEN 'Generation'
            THEN 'GU_%'
         END INTO v_POD_ID
  FROM DUAL;


  OPEN p_CURSOR FOR
     SELECT '<ALL>' as TRANSACTION_NAME, MM_SEM_UTIL.g_ALL as TRANSACTION_ID
    FROM DUAL
    WHERE p_INCLUDE_ALL = 1
    UNION ALL
    SELECT *
    FROM (
          SELECT  ESI2.EXTERNAL_IDENTIFIER || ' : ' || ESI1.EXTERNAL_IDENTIFIER AS TRANSACTION_NAME,
                  IT.TRANSACTION_ID
            FROM INTERCHANGE_TRANSACTION IT,
            SERVICE_POINT SP,
            SEM_SERVICE_POINT_PSE SSPP,
            PURCHASING_SELLING_ENTITY PSE,
            EXTERNAL_SYSTEM_IDENTIFIER ESI1,
            EXTERNAL_SYSTEM_IDENTIFIER ESI2,
            EXTERNAL_SYSTEM_IDENTIFIER ESI3
            WHERE
              SP.SERVICE_POINT_ID = IT.POD_ID
              AND SP.SERVICE_POINT_ID = SSPP.POD_ID(+)
              AND SSPP.PSE_ID = PSE.PSE_ID(+)
              AND IT.BEGIN_DATE <= p_END_DATE
              AND IT.END_DATE >= p_BEGIN_DATE
              AND IT.SC_ID = MM_SEM_UTIL.SEM_SC_ID
              AND IT.IS_BID_OFFER = 1
              AND IT.AGREEMENT_TYPE = p_GATE_WINDOW
              AND IT.TRANSACTION_TYPE = p_TRANSACTION_TYPE -- The Gate window has to have a Transaction type of Generation
              AND ESI1.EXTERNAL_SYSTEM_ID = EC.ES_SEM
              AND ESI1.ENTITY_DOMAIN_ID = EC.ED_SERVICE_POINT
              AND ESI1.ENTITY_ID = IT.POD_ID
              AND ESI1.EXTERNAL_IDENTIFIER LIKE v_POD_ID    --- The POD_ID is determined based on Transaction_Type
              AND ESI2.EXTERNAL_SYSTEM_ID = EC.ES_SEM
              AND ESI2.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT
              AND ESI2.ENTITY_ID = IT.CONTRACT_ID
              AND ESI3.EXTERNAL_SYSTEM_ID = EC.ES_SEM
              AND ESI3.ENTITY_DOMAIN_ID = EC.ED_PSE
              -- The PK is NULL is not correct
              AND (ESI3.ENTITY_ID = PSE.PSE_ID) 
              AND ((p_TRANSACTION_TYPE = 'Generation' AND ESI3.EXTERNAL_IDENTIFIER IS NOT NULL) OR
                    (p_TRANSACTION_TYPE != 'Generation'))
              ORDER BY 1, 2 ASC
              );


EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
END OFFER_ENTITY_LIST_GATE;
----------------------------------------------------------------------------
/*
** OFFER_ENTITY_LIST_GATE_UUT is similar to OFFER_ENTITY_LIST_GATE except it filters
** transaction lists only if the Unit under test is set for the entire begin and end date range
*/
PROCEDURE OFFER_ENTITY_LIST_GATE_UUT
  (
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_INCLUDE_ALL IN NUMBER,
  p_GATE_WINDOW IN VARCHAR2,
  p_TRANSACTION_TYPE IN VARCHAR2,
  p_LABEL OUT VARCHAR2,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2,
  p_CURSOR OUT REF_CURSOR
  ) AS

  v_POD_ID VARCHAR2(5);
BEGIN
  p_STATUS := GA.SUCCESS;

  p_LABEL := 'Transactions';

  -- Determine the EXTENRAL_ID FRON TRANSACTION TYPE
  -- Nomination = "I_"
  -- Generation = "GU_"
  SELECT CASE(p_TRANSACTION_TYPE)
            WHEN 'Nomination'
            THEN 'I_%'
            WHEN 'Generation'
            THEN 'GU_%'
         END INTO v_POD_ID
  FROM DUAL;

  OPEN p_CURSOR FOR
        SELECT '<ALL>' as TRANSACTION_NAME, MM_SEM_UTIL.g_ALL as TRANSACTION_ID
        FROM DUAL
        WHERE p_INCLUDE_ALL = 1
        UNION ALL
        SELECT *
        FROM (
              SELECT  ESI2.EXTERNAL_IDENTIFIER || ' : ' || ESI1.EXTERNAL_IDENTIFIER AS TRANSACTION_NAME,
                      IT.TRANSACTION_ID
                FROM (SELECT TXN.TRANSACTION_ID,
                         TXN.BEGIN_DATE,
                         TXN.END_DATE,
                         TXN.SC_ID,
                         TXN.IS_BID_OFFER,
                         TXN.AGREEMENT_TYPE,
                         TXN.TRANSACTION_TYPE,
                         TXN.CONTRACT_ID,
                         TXN.POD_ID,
                         MIN(NVL(S.TRAIT_VAL,0)) AS IS_UNDER_TEST
                        FROM (SELECT IT.TRANSACTION_ID,
                             IT.BEGIN_DATE,
                             IT.END_DATE,
                             IT.SC_ID,
                             IT.IS_BID_OFFER,
                             IT.AGREEMENT_TYPE,
                             IT.TRANSACTION_TYPE,
                             IT.CONTRACT_ID,
                             IT.POD_ID,
                             D.COLUMN_VALUE + 1/86400 AS SCHEDULE_DATE
                        FROM INTERCHANGE_TRANSACTION IT,
                             TABLE(CAST(DATE_UTIL.DATES_IN_INTERVAL_RANGE(p_BEGIN_DATE, p_END_DATE, 'Day') AS DATE_COLLECTION)) D
                        WHERE COLUMN_VALUE BETWEEN IT.BEGIN_DATE AND NVL(IT.END_DATE, CONSTANTS.HIGH_DATE)
                             AND IT.TRANSACTION_ID <> CONSTANTS.NOT_ASSIGNED) TXN,
                        IT_TRAIT_SCHEDULE S
                    WHERE S.TRANSACTION_ID(+) = TXN.TRANSACTION_ID
                         AND S.SCHEDULE_DATE(+) = TXN.SCHEDULE_DATE
                         -- TODO: More conditions for getting the correct trait value
                         -- internal vs external, statement_Type etc...
                         AND S.TRAIT_GROUP_ID(+) = MM_SEM_UTIL.g_TG_GEN_UNDER_TEST
                         AND S.TRAIT_INDEX(+) = MM_SEM_UTIL.g_TI_UNDER_TEST
                    GROUP BY TXN.TRANSACTION_ID, TXN.BEGIN_DATE,TXN.END_DATE,TXN.SC_ID,TXN.IS_BID_OFFER,TXN.AGREEMENT_TYPE,TXN.TRANSACTION_TYPE,TXN.CONTRACT_ID,TXN.POD_ID
                    ) IT,
                SERVICE_POINT SP,
                SEM_SERVICE_POINT_PSE SSPP,
                PURCHASING_SELLING_ENTITY PSE,
                EXTERNAL_SYSTEM_IDENTIFIER ESI1,
                EXTERNAL_SYSTEM_IDENTIFIER ESI2,
                EXTERNAL_SYSTEM_IDENTIFIER ESI3
                WHERE
                  SP.SERVICE_POINT_ID = IT.POD_ID
                  AND SP.SERVICE_POINT_ID = SSPP.POD_ID(+)
                  AND SSPP.PSE_ID = PSE.PSE_ID(+)
                  AND IT.IS_UNDER_TEST = 1
                  AND IT.BEGIN_DATE <= p_END_DATE
                  AND IT.END_DATE >= p_BEGIN_DATE
                  AND IT.SC_ID = MM_SEM_UTIL.SEM_SC_ID
                  AND IT.IS_BID_OFFER = 1
                  AND IT.AGREEMENT_TYPE = p_GATE_WINDOW
                  AND IT.TRANSACTION_TYPE = p_TRANSACTION_TYPE -- The Gate window has to have a Transaction type of Generation
                  AND ESI1.EXTERNAL_SYSTEM_ID = EC.ES_SEM
                  AND ESI1.ENTITY_DOMAIN_ID = EC.ED_SERVICE_POINT
                  AND ESI1.ENTITY_ID = IT.POD_ID
                  AND ESI1.EXTERNAL_IDENTIFIER LIKE v_POD_ID    --- The POD_ID is determined based on Transaction_Type
                  AND ESI2.EXTERNAL_SYSTEM_ID = EC.ES_SEM
                  AND ESI2.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT
                  AND ESI2.ENTITY_ID = IT.CONTRACT_ID
                  AND ESI3.EXTERNAL_SYSTEM_ID = EC.ES_SEM
                  AND ESI3.ENTITY_DOMAIN_ID = EC.ED_PSE
                  AND (ESI3.ENTITY_ID = PSE.PSE_ID OR PSE.PSE_ID IS NULL)
                  AND ((p_TRANSACTION_TYPE = 'Generation' AND ESI3.EXTERNAL_IDENTIFIER IS NOT NULL) OR
                        (p_TRANSACTION_TYPE != 'Generation'))
                  ORDER BY 1, 2 ASC
                  );
EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
END OFFER_ENTITY_LIST_GATE_UUT;
------------------------------------------------------------------------------
PROCEDURE SRA_OFFER_ENTITY_LIST
  (
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_INCLUDE_ALL IN NUMBER,
  p_CANCELLED IN NUMBER,
  p_LABEL OUT VARCHAR2,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2,
  p_CURSOR OUT GA.REFCURSOR
  ) AS
v_DATE DATE := TRUNC(p_BEGIN_DATE);
v_TRANSACTION_ID NUMBER;
v_TXNS ID_TABLE;
CURSOR c_TXNS IS
SELECT IT.TRANSACTION_NAME, IT.TRANSACTION_ID
              FROM INTERCHANGE_TRANSACTION IT
              WHERE IT.BEGIN_DATE <= p_END_DATE
                AND IT.END_DATE >= p_BEGIN_DATE
                AND IT.SC_ID = MM_SEM_UTIL.SEM_SC_ID
                AND IT.IS_BID_OFFER = 1
                AND IT.TRANSACTION_TYPE = ('SRA')
              AND EXISTS (SELECT 1
                    FROM EXTERNAL_SYSTEM_IDENTIFIER ESI
                    WHERE ESI.EXTERNAL_SYSTEM_ID = EC.ES_SEM
                      AND ESI.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT
                      AND ESI.ENTITY_ID = IT.CONTRACT_ID);
BEGIN
  p_STATUS := GA.SUCCESS;

  p_LABEL := 'SRA Transactions';

   v_TXNS := ID_TABLE();

   FOR v_TXN IN c_TXNS LOOP
       WHILE v_DATE <= TRUNC(p_END_DATE) LOOP
         BEGIN
           SELECT DISTINCT I.TRANSACTION_ID
             INTO v_TRANSACTION_ID
             FROM IT_TRAIT_SCHEDULE I, IT_TRAIT_SCHEDULE_STATUS S
            WHERE I.TRANSACTION_ID = v_TXN.Transaction_Id
              AND TRUNC(I.SCHEDULE_DATE) = v_DATE
              AND (I.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_SRA_VALIDITY_STATUS
                  --if cancelled has never been checked trait_index 2 will not be there
                  AND ((p_CANCELLED = 1 AND I.TRAIT_INDEX = 2 AND
                  I.TRAIT_VAL = p_CANCELLED) OR
                  (p_CANCELLED = 0 AND I.TRAIT_INDEX = 2 AND
                  I.TRAIT_VAL = p_CANCELLED) OR
                  (p_CANCELLED = 0 AND
                  2 NOT IN
                  (SELECT TRAIT_INDEX
                            FROM IT_TRAIT_SCHEDULE
                           WHERE TRANSACTION_ID = v_TXN.Transaction_Id
                             AND SCHEDULE_STATE = GA.INTERNAL_STATE
                             AND TRAIT_GROUP_ID =
                                 MM_SEM_UTIL.g_TG_SRA_VALIDITY_STATUS
                             AND TRUNC(SCHEDULE_DATE) = v_DATE)))
                  --Valdity Status trait group does not exist at all - Rejected or Cancelled never checked
                  OR (p_CANCELLED = 0 AND
                  MM_SEM_UTIL.g_TG_SRA_VALIDITY_STATUS NOT IN
                  (SELECT TRAIT_GROUP_ID
                          FROM IT_TRAIT_SCHEDULE
                         WHERE TRANSACTION_ID = v_TXN.Transaction_Id
                           AND SCHEDULE_STATE = GA.INTERNAL_STATE
                           AND TRUNC(SCHEDULE_DATE) = v_DATE)))
              AND I.SCHEDULE_STATE = GA.INTERNAL_STATE
              AND S.TRANSACTION_ID = I.TRANSACTION_ID
              AND S.SCHEDULE_DATE = I.SCHEDULE_DATE
              AND S.REVIEW_STATUS = 'Accepted';

         EXCEPTION
           WHEN NO_DATA_FOUND THEN
             v_TRANSACTION_ID := NULL;
             EXIT;
         END;
         v_DATE := v_DATE + 1;
     END LOOP;
     --Save valid transactions that are Accepted and = p_CANCELLED
     IF NOT v_TRANSACTION_ID IS NULL THEN
       v_TXNS.EXTEND;
       v_TXNS(v_TXNS.LAST) := ID_TYPE(v_TRANSACTION_ID);
     END IF;
     v_TRANSACTION_ID := NULL;
     v_DATE := TRUNC(p_BEGIN_DATE);
   END LOOP;

  OPEN p_CURSOR FOR
    SELECT '<ALL>' as TRANSACTION_NAME, MM_SEM_UTIL.g_ALL as TRANSACTION_ID
    FROM DUAL
    WHERE p_INCLUDE_ALL = 1
    UNION ALL
    SELECT *
    FROM (SELECT IT.TRANSACTION_NAME, IT.TRANSACTION_ID
              FROM INTERCHANGE_TRANSACTION IT, TABLE(CAST(v_TXNS AS ID_TABLE))X
              WHERE IT.TRANSACTION_ID = X.ID
              ORDER BY 1 ASC);
EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
END SRA_OFFER_ENTITY_LIST;
------------------------------------------------------------------------------
PROCEDURE IMPORT_OFFER_DATA_CLOB
  (
  p_IMPORT_FILE IN OUT NOCOPY CLOB,
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
v_LOGGER MM_LOGGER_ADAPTER;
v_STARTED BOOLEAN := FALSE;
v_REC t_PROGRESS;
BEGIN
  p_STATUS := GA.SUCCESS;

  IF INSTR(p_ENTITY_LIST,p_ENTITY_LIST_DELIMITER) <> 0 THEN
    p_STATUS := 1;
    p_MESSAGE := 'Please select only one market participant for this file';
    RETURN;
  END IF;

  v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM, NULL, 'Query Offers', NULL, p_LOG_TYPE, p_TRACE_ON);
  v_LOGGER.LOG_START;
  v_STARTED := TRUE;

  -- Do the work!
  p_MESSAGE := PROCESS_RESPONSE(p_ENTITY_LIST, NULL, XMLTYPE(p_IMPORT_FILE),
                  v_LOGGER, g_ACTION_QUERY, NULL, NULL, NULL, v_REC);
  IF p_MESSAGE IS NOT NULL THEN
      v_LOGGER.LOG_ERROR(p_MESSAGE);
      p_STATUS := 1;
  ELSE
      p_MESSAGE := GET_MESSAGE(v_REC, 'imported');
  END IF;
  v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
  -- Done!

EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
    IF v_STARTED THEN
      v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
    END IF;
END IMPORT_OFFER_DATA_CLOB;
------------------------------------------------------------------------------
PROCEDURE IMPORT_OFFER_DATA_CLOB_UUT
  (
  p_IMPORT_FILE IN OUT NOCOPY CLOB,
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
v_LOGGER MM_LOGGER_ADAPTER;
v_STARTED BOOLEAN := FALSE;
v_REC t_PROGRESS;
BEGIN
  p_STATUS := GA.SUCCESS;

  IF INSTR(p_ENTITY_LIST,p_ENTITY_LIST_DELIMITER) <> 0 THEN
    p_STATUS := 1;
    p_MESSAGE := 'Please select only one market participant for this file';
    RETURN;
  END IF;

  v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM, NULL, 'Import Offers Unit Under Test', NULL, p_LOG_TYPE, p_TRACE_ON);
  v_LOGGER.LOG_START;
  v_STARTED := TRUE;

  -- Do the work!
  p_MESSAGE := PROCESS_RESPONSE(p_ENTITY_LIST, NULL, XMLTYPE(p_IMPORT_FILE),
                  v_LOGGER, g_ACTION_UUT_QUERY, NULL, NULL, NULL, v_REC);
  IF p_MESSAGE IS NOT NULL THEN
      v_LOGGER.LOG_ERROR(p_MESSAGE);
      p_STATUS := 1;
  ELSE
      p_MESSAGE := GET_MESSAGE(v_REC, 'imported');
  END IF;
  v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
  -- Done!

EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
    IF v_STARTED THEN
      v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
    END IF;
END IMPORT_OFFER_DATA_CLOB_UUT;
------------------------------------------------------------------------------
PROCEDURE IMPORT_SUBMIT_RESPONSE_CLOB
  (
  p_IMPORT_FILE IN OUT NOCOPY CLOB,
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
v_LOGGER MM_LOGGER_ADAPTER;
v_STARTED BOOLEAN := FALSE;
v_REC t_PROGRESS;
BEGIN
  p_STATUS := GA.SUCCESS;

  IF INSTR(p_ENTITY_LIST,p_ENTITY_LIST_DELIMITER) <> 0 THEN
    p_STATUS := 1;
    p_MESSAGE := 'Please select only one market participant for this file';
    RETURN;
  END IF;

  v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM, NULL, 'Submit Offers', NULL, p_LOG_TYPE, p_TRACE_ON);
  v_LOGGER.LOG_START;
  v_STARTED := TRUE;

  -- Do the work!
  p_MESSAGE := PROCESS_RESPONSE(p_ENTITY_LIST, NULL, XMLTYPE(p_IMPORT_FILE),
                  v_LOGGER, g_ACTION_SUBMIT, 'Accepted', 'Rejected', 'Error', v_REC);
  IF p_MESSAGE IS NOT NULL THEN
      v_LOGGER.LOG_ERROR(p_MESSAGE);
      p_STATUS := 1;
  ELSE
      p_MESSAGE := GET_MESSAGE(v_REC, 'submitted');
  END IF;
  v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
  -- Done!

EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
    IF v_STARTED THEN
      v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
    END IF;
END IMPORT_SUBMIT_RESPONSE_CLOB;
------------------------------------------------------------------------------
PROCEDURE IMPORT_SUBMIT_RESP_CLOB_UUT
  (
  p_IMPORT_FILE IN OUT NOCOPY CLOB,
  p_ENTITY_LIST IN VARCHAR2,
  p_ENTITY_LIST_DELIMITER IN CHAR,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  ) AS
v_LOGGER MM_LOGGER_ADAPTER;
v_STARTED BOOLEAN := FALSE;
v_REC t_PROGRESS;
BEGIN
  p_STATUS := GA.SUCCESS;

  IF INSTR(p_ENTITY_LIST,p_ENTITY_LIST_DELIMITER) <> 0 THEN
    p_STATUS := 1;
    p_MESSAGE := 'Please select only one market participant for this file';
    RETURN;
  END IF;

  v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM, NULL, 'Submit Offers Unit Under Test', NULL, p_LOG_TYPE, p_TRACE_ON);
  v_LOGGER.LOG_START;
  v_STARTED := TRUE;

  -- Do the work!
  p_MESSAGE := PROCESS_RESPONSE(p_ENTITY_LIST, NULL, XMLTYPE(p_IMPORT_FILE),
                  v_LOGGER, g_ACTION_UUT_SUBMIT, 'Accepted', 'Rejected', 'Error', v_REC);
  IF p_MESSAGE IS NOT NULL THEN
      v_LOGGER.LOG_ERROR(p_MESSAGE);
      p_STATUS := 1;
  ELSE
      p_MESSAGE := GET_MESSAGE(v_REC, 'submitted');
  END IF;
  v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
  -- Done!

EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
    IF v_STARTED THEN
      v_LOGGER.LOG_STOP(p_STATUS, p_MESSAGE);
    END IF;
END IMPORT_SUBMIT_RESP_CLOB_UUT;
------------------------------------------------------------------------------
PROCEDURE IMPORT_ENTITY_LIST
  (
  p_ENTITY_LABEL OUT VARCHAR2,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2,
  p_CURSOR OUT REF_CURSOR
  ) AS
BEGIN
  p_STATUS := GA.SUCCESS;

  p_ENTITY_LABEL := 'Market Participants';

  SA.GET_EXTERNAL_ACCOUNT_LIST(EC.ES_SEM, p_CURSOR);

EXCEPTION
  WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
END IMPORT_ENTITY_LIST;
------------------------------------------------------------------------------
FUNCTION GET_NEEDS_RESET
  (
  p_PKG_NAME IN VARCHAR2
  ) RETURN BOOLEAN IS
v_RET NUMBER;
BEGIN
  SELECT COUNT(1)
  INTO v_RET
  FROM USER_PROCEDURES
  WHERE OBJECT_NAME = p_PKG_NAME
    AND PROCEDURE_NAME = 'RESET_FOR_PARSE';

  RETURN v_RET <> 0;
END GET_NEEDS_RESET;
------------------------------------------------------------------------------
BEGIN
  -- Initialize these maps so we know how to handle everything

  g_TXN_TYPE_TO_PKG('Generation') := g_GEN_PKG;
  g_TXN_TYPE_TO_PKG('Nomination') := g_IC_PKG;
  g_TXN_TYPE_TO_PKG('Load') := g_LOAD_PKG;
  g_TXN_TYPE_TO_PKG('SRA') := g_SRA_PKG;

  g_TXN_TYPE_TO_INT('Generation') := 'Day';
  g_TXN_TYPE_TO_INT('Nomination') := '30 Minute';
  g_TXN_TYPE_TO_INT('Load') := 'Day';
  g_TXN_TYPE_TO_INT('SRA') := 'Day';

  g_XML_NODE_TO_PKG('sem_gen_offer') := g_GEN_PKG;
  g_XML_NODE_TO_PKG('sem_interconnector_offer') := g_IC_PKG;
  g_XML_NODE_TO_PKG('sem_demand_offer') := g_LOAD_PKG;
  g_XML_NODE_TO_PKG('sem_settlement_reallocation') := g_SRA_PKG;
  g_XML_NODE_TO_PKG('sem_unit_under_test') := g_GEN_PKG;

  g_XML_NODE_TO_TXN_TYPE('sem_gen_offer') := 'Generation';
  g_XML_NODE_TO_TXN_TYPE('sem_interconnector_offer') := 'Nomination';
  g_XML_NODE_TO_TXN_TYPE('sem_demand_offer') := 'Load';
  g_XML_NODE_TO_TXN_TYPE('sem_settlement_reallocation') := 'SRA';
  g_XML_NODE_TO_TXN_TYPE('sem_unit_under_test') := 'Generation';

  g_IS_ONE_AT_A_TIME('Generation') := FALSE;
  g_IS_ONE_AT_A_TIME('Nomination') := FALSE;
  g_IS_ONE_AT_A_TIME('Load') := TRUE;
  g_IS_ONE_AT_A_TIME('SRA') := TRUE;

  g_NEEDS_SEM_TXN_ID(g_ACTION_SUBMIT) := TRUE;
  g_NEEDS_SEM_TXN_ID(g_ACTION_QUERY) := FALSE;
  g_NEEDS_SEM_TXN_ID(g_ACTION_SUBMIT_CANCEL) := TRUE;
  g_NEEDS_SEM_TXN_ID(g_ACTION_UUT_SUBMIT) := TRUE;
  g_NEEDS_SEM_TXN_ID(g_ACTION_UUT_QUERY) := FALSE;

  g_NEEDS_RESET_FOR_PARSE(g_GEN_PKG) := GET_NEEDS_RESET(g_GEN_PKG);
  g_NEEDS_RESET_FOR_PARSE(g_IC_PKG) := GET_NEEDS_RESET(g_IC_PKG);
  g_NEEDS_RESET_FOR_PARSE(g_LOAD_PKG) := GET_NEEDS_RESET(g_LOAD_PKG);
  g_NEEDS_RESET_FOR_PARSE(g_SRA_PKG) := GET_NEEDS_RESET(g_SRA_PKG);

  g_MARKET_NODES(g_ACTION_SUBMIT) := 'market_submit';
  g_MARKET_NODES(g_ACTION_QUERY) := 'market_query';
  g_MARKET_NODES(g_ACTION_SUBMIT_CANCEL) := 'market_cancel';
  g_MARKET_NODES(g_ACTION_UUT_SUBMIT) := 'market_submit';
  g_MARKET_NODES(g_ACTION_UUT_QUERY) := 'market_query';

  g_CREATE_PROCS(g_ACTION_SUBMIT) := 'CREATE_SUBMISSION_XML';
  g_CREATE_PROCS(g_ACTION_QUERY) := 'CREATE_QUERY_XML';
  g_CREATE_PROCS(g_ACTION_SUBMIT_CANCEL) := 'CREATE_CANCELLATION_XML';
  g_CREATE_PROCS(g_ACTION_UUT_SUBMIT) := 'CREATE_UUT_SUBMISSION_XML';
  g_CREATE_PROCS(g_ACTION_UUT_QUERY) := 'CREATE_UUT_QUERY_XML';

  g_PROCESS_PROCS(g_ACTION_SUBMIT) := 'PARSE_SUBMISSION_RESPONSE_XML';
  g_PROCESS_PROCS(g_ACTION_QUERY) := 'PARSE_QUERY_XML';
  g_PROCESS_PROCS(g_ACTION_SUBMIT_CANCEL) := 'PARSE_SUBMISSION_RESPONSE_XML';
  g_PROCESS_PROCS(g_ACTION_UUT_SUBMIT) := 'PARSE_UUT_SUBMISSION_RESP_XML';
  g_PROCESS_PROCS(g_ACTION_UUT_QUERY) := 'PARSE_UUT_QUERY_RESP_XML';

  g_XPATH_ELEMENT_SEARCH(g_ACTION_SUBMIT) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT)||g_XPATH_ELEMENT_SEARCH_SUFFIX;
  g_XPATH_ELEMENT_SEARCH(g_ACTION_QUERY) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT)||g_XPATH_ELEMENT_SEARCH_SUFFIX;
  g_XPATH_ELEMENT_SEARCH(g_ACTION_SUBMIT_CANCEL) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT_CANCEL)||g_XPATH_ELEMENT_SEARCH_SUFFIX;
  g_XPATH_ELEMENT_SEARCH(g_ACTION_UUT_SUBMIT) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT)||g_XPATH_ELEMENT_SEARCH_SUFFIX;
  g_XPATH_ELEMENT_SEARCH(g_ACTION_UUT_QUERY) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT)||g_XPATH_ELEMENT_SEARCH_SUFFIX;

  g_XPATH_DATE_SEARCH(g_ACTION_SUBMIT) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT)||'/@'||g_XPATH_DATE_ATTR_NAME;
  g_XPATH_DATE_SEARCH(g_ACTION_QUERY) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT)||'/@'||g_XPATH_DATE_ATTR_NAME;
  g_XPATH_DATE_SEARCH(g_ACTION_SUBMIT_CANCEL) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_SUBMIT_CANCEL)||'/@'||g_XPATH_DATE_ATTR_NAME;
  g_XPATH_DATE_SEARCH(g_ACTION_UUT_SUBMIT) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_UUT_SUBMIT)||'/@'||g_XPATH_DATE_ATTR_NAME;
  g_XPATH_DATE_SEARCH(g_ACTION_UUT_QUERY) := g_XPATH_TOP||g_MARKET_NODES(g_ACTION_UUT_SUBMIT)||'/@'||g_XPATH_DATE_ATTR_NAME;

  g_ALERT_NAMES(g_ACTION_SUBMIT) := 'Submit Offer';
  g_ALERT_NAMES(g_ACTION_QUERY) := 'Query Offer';
  g_ALERT_NAMES(g_ACTION_SUBMIT_CANCEL) := 'Submit SRA Cancellation';
  g_ALERT_NAMES(g_ACTION_UUT_SUBMIT) := 'Submit Unit Under Test';
  g_ALERT_NAMES(g_ACTION_UUT_QUERY) := 'Query Unit Under Test';


END MM_SEM_OFFER;
/
