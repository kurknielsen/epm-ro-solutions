CREATE OR REPLACE PACKAGE MM_NYISO AS
-- $Revision: 1.42 $

-- NYISO-specific Market Manager procedures



TYPE REF_CURSOR IS REF CURSOR;


FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE BID_OFFER_TRANSACTION_LIST
	(
	p_MKT_APP IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ACTION IN VARCHAR2,
	p_SOMETHING_DONE OUT BOOLEAN,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
    );

PROCEDURE SYSTEM_ACTION_USES_HOURS
	(
    p_MKT_APP IN VARCHAR2,
    p_ACTION IN VARCHAR2,
	p_SHOW_HOURS OUT NUMBER
    );

FUNCTION IS_SUPPORTED_EXCHANGE_TYPE
	(
	p_MKT_APP IN VARCHAR2,
	p_EXCHANGE_TYPE IN VARCHAR2
	) RETURN BOOLEAN;

FUNCTION GET_BID_OFFER_INTERVAL
	(
	p_TRANSACTION IN INTERCHANGE_TRANSACTION%ROWTYPE
	) RETURN VARCHAR2;

PROCEDURE GET_TRAITS_FOR_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_REPORT_TYPE IN VARCHAR2,
	p_TRAIT_GROUP_FILTER IN VARCHAR2,
	p_INTERVAL IN VARCHAR2,
	p_WORK_ID OUT NUMBER
	);

PROCEDURE NYISO_PTID_RPT
	(
        p_STATUS OUT NUMBER,
        p_CURSOR IN OUT REF_CURSOR
    );

PROCEDURE PUT_NYISO_PTID_RPT
	(
        p_PTID_NAME IN VARCHAR2,
        p_PTID_TYPE IN VARCHAR2,
		p_PTID IN VARCHAR2,
        p_ADD_SVC_POINT IN NUMBER,
        p_STATUS OUT NUMBER
    );

FUNCTION GET_NODE_TYPE
  (
    p_NODE_NAME VARCHAR2,
    p_NODE_TYPE VARCHAR2
  ) RETURN VARCHAR2;
END MM_NYISO;
/