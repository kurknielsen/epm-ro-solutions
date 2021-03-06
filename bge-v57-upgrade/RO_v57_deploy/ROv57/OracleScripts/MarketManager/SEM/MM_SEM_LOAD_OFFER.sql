CREATE OR REPLACE PACKAGE MM_SEM_LOAD_OFFER IS
-- $Revision: 1.8 $

  -- Author  : JHUMPHRIES
  -- Created : 4/3/2007 12:52:18 PM
  -- Purpose : Build XML pieces of submission, query, and cancellation of Load Bids

FUNCTION WHAT_VERSION RETURN VARCHAR2;

FUNCTION CREATE_SUBMISSION_XML
	(
	p_DATE IN DATE,
	p_TRANSACTION_ID IN NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN XMLTYPE;

FUNCTION CREATE_QUERY_XML
	(
	p_DATE IN DATE,
	p_TRANSACTION_ID IN NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN XMLTYPE;

FUNCTION GET_TRANSACTION_IDs
	(
	p_DATE IN DATE,
	p_ACCOUNT_NAME IN VARCHAR2,
	p_GATE_WINDOW IN VARCHAR2,
	p_RESPONSE IN XMLTYPE
	) RETURN NUMBER_COLLECTION;

FUNCTION PARSE_QUERY_XML
	(
	p_TRANSACTION_IDs IN NUMBER_COLLECTION,
	p_DATE IN DATE,
	p_RESPONSE IN XMLTYPE,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN VARCHAR2;

FUNCTION PARSE_SUBMISSION_RESPONSE_XML
	(
	p_TRANSACTION_IDs IN NUMBER_COLLECTION,
	p_DATE IN DATE,
	p_RESPONSE IN XMLTYPE,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN VARCHAR2;

k_FMT_ISO_DATE  CONSTANT VARCHAR2(12) := 'YYYY-MM-DD';
k_VERSION_NO    CONSTANT VARCHAR2(3) := '1.0';
k_STANDING_FLAG CONSTANT VARCHAR2(6) := 'FALSE';
k_1_SEC         CONSTANT INTERVAL DAY TO SECOND := INTERVAL '1' SECOND;
k_XML_NODE_NAME VARCHAR2(32) := 'sem_load_offer';

END MM_SEM_LOAD_OFFER;
/
