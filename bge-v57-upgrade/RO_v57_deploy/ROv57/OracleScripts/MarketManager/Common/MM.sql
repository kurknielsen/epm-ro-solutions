CREATE OR REPLACE PACKAGE MM AS

--Market Manager Interface package
-- $Revision: 1.58 $

FUNCTION WHAT_VERSION RETURN VARCHAR;

TYPE REF_CURSOR IS REF CURSOR;

PROCEDURE MARKET_MESSAGE_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_SCHEDULE_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_NOTUSED_ID1 IN NUMBER,
    p_NOTUSED_ID2 IN NUMBER,
    p_NOTUSED_ID3 IN NUMBER,
	p_REPORT_NAME IN VARCHAR2,
	p_MARKET_OPERATOR IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE DISPATCH_SUMMARY_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_SCHEDULE_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_NOTUSED_ID1 IN NUMBER,
    p_NOTUSED_ID2 IN NUMBER,
    p_NOTUSED_ID3 IN NUMBER,
	p_REPORT_NAME IN VARCHAR2,
	p_SC_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE UNAPPROVED_EXT_BILATERALS
  (
  p_MODEL_ID      IN NUMBER,
  p_SCHEDULE_TYPE IN NUMBER,
  p_BEGIN_DATE    IN DATE,
  p_END_DATE      IN DATE,
  p_AS_OF_DATE    IN DATE,
  p_TIME_ZONE     IN VARCHAR2,
  p_NOTUSED_ID1   IN NUMBER,
  p_NOTUSED_ID2   IN NUMBER,
  p_NOTUSED_ID3   IN NUMBER,
  p_REPORT_NAME   IN VARCHAR2,
  p_SC_ID         IN NUMBER,
  p_STATUS        OUT NUMBER,
  p_CURSOR        IN OUT REF_CURSOR
  );

PROCEDURE UNAPPROVED_BILATERALS_RPT
  (
  p_MODEL_ID         IN NUMBER,
  p_SCHEDULE_TYPE    IN NUMBER,
  p_BEGIN_DATE       IN DATE,
  p_END_DATE         IN DATE,
  p_AS_OF_DATE       IN DATE,
  p_TIME_ZONE        IN VARCHAR2,
  p_NOTUSED_ID1      IN NUMBER,
  p_NOTUSED_ID2      IN NUMBER,
  p_NOTUSED_ID3      IN NUMBER,
  p_REPORT_NAME      IN VARCHAR2,
  p_SC_ID            IN NUMBER,
  p_STATUS           OUT NUMBER,
  p_CURSOR           IN OUT REF_CURSOR
  );

PROCEDURE BILAT_CONTRACT_VALIDAT_RPT
	(
	p_MODEL_ID IN NUMBER,
	p_SCHEDULE_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR2,
    p_NOTUSED_ID1 IN NUMBER,
    p_NOTUSED_ID2 IN NUMBER,
    p_NOTUSED_ID3 IN NUMBER,
	p_REPORT_NAME IN VARCHAR2,
	p_SC_ID IN NUMBER,
	p_COUNTER_PARTY_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE PUT_BILAT_CONTRACT_VALIDAT_RPT
	(
	p_TRANSACTION_ID_INT IN NUMBER,
	p_TRANSACTION_ID_EXT IN NUMBER,
	p_OVERRIDE_INTERNAL IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE BILAT_CONTRACT_DRILL_DOWN
	(
	p_TRANSACTION_ID_INT IN NUMBER,
	p_TRANSACTION_ID_EXT IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE MARKET_MESSAGE_REPORT
	(
	p_MODEL_ID      IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER,
    p_BEGIN_DATE    IN DATE,
    p_END_DATE      IN DATE,
    p_AS_OF_DATE    IN DATE,
    p_TIME_ZONE     IN VARCHAR2,
    p_NOTUSED_ID1   IN NUMBER,
    p_NOTUSED_ID2   IN NUMBER,
    p_NOTUSED_ID3   IN NUMBER,
    p_REPORT_NAME   IN VARCHAR2,
    p_SC_ID         IN NUMBER,
    p_STATUS        OUT NUMBER,
    p_CURSOR        IN OUT REF_CURSOR
	);

PROCEDURE GET_AGREEMENT_TYPE_LIST
	(
	p_TRANSACTION_TYPE IN VARCHAR2,
	p_IS_IMPORT_EXPORT IN NUMBER,
	p_SC_ID IN NUMBER,
	p_COMMODITY_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);


PROCEDURE SYSTEM_ACTION_USES_HOURS
	(
    p_ACTION IN VARCHAR2,
	p_SHOW_HOURS OUT NUMBER
    );


FUNCTION GET_BID_OFFER_INTERVAL
	(
	p_TRANSACTION IN INTERCHANGE_TRANSACTION%ROWTYPE
	) RETURN VARCHAR2;

FUNCTION GET_BID_OFFER_INTERVAL
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN VARCHAR2;

PROCEDURE GET_TRAITS_FOR_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_REPORT_TYPE IN VARCHAR2,
	p_TRAIT_GROUP_FILTER IN VARCHAR2,
	p_INTERVAL IN VARCHAR2,
	p_WORK_ID OUT NUMBER
	);

FUNCTION GET_DEFAULT_NUMBER_OF_SETS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_TRAIT_GROUP_ID IN NUMBER
	) RETURN NUMBER;

PROCEDURE GET_AFFECTED_DATE_RANGE
	(
	p_TRANSACTION_ID IN NUMBER,
	p_CUT_DATE IN OUT DATE,
	p_IS_SUB_DAILY IN BOOLEAN,
	p_BEGIN_DATE OUT DATE,
	p_END_DATE OUT DATE
	);

PROCEDURE GET_DEFAULT_SYSTEM_ACTION
	(
	p_CONTEXT_ID IN NUMBER,
	p_CONTEXT_TYPE IN VARCHAR,
	p_ACTION_TYPE IN VARCHAR,
	p_MODULE_NAME IN VARCHAR,
	p_ACTION_ID OUT NUMBER,
	p_STATUS OUT NUMBER
	);

FUNCTION TRAIT_AFFECTS_STATUS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRAIT_INDEX IN NUMBER
	) RETURN BOOLEAN;

FUNCTION NO_OP_UPDATE_AFFECTS_STATUS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRAIT_INDEX IN NUMBER
	) RETURN BOOLEAN;

PROCEDURE GET_MARKET_MESSAGES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_MARKET_OPERATOR IN VARCHAR2,
	p_MESSAGE_SOURCE IN VARCHAR2,
	p_MESSAGE_DESTINATION IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);

PROCEDURE MKT_MSG_OPERATORS
	(
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);

PROCEDURE MKT_MSG_SOURCES
	(
	p_MARKET_OPERATOR IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);

PROCEDURE MKT_MSG_DESTINATIONS
	(
	p_MARKET_OPERATOR IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	);



g_ALL NUMBER(2) := 1;
g_ALL_STRING VARCHAR2(8) := '<ALL>';

END MM;
/