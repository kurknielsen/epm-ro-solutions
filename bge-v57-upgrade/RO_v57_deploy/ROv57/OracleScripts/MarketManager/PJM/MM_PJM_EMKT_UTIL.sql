CREATE OR REPLACE PACKAGE MM_PJM_EMKT_UTIL IS
-- $Revision: 1.9 $

TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

FUNCTION GET_RESOURCE_FOR_PJM_PNODEID
   (
   p_PJM_PNODEID IN VARCHAR2
   ) RETURN SUPPLY_RESOURCE%ROWTYPE;

PROCEDURE GET_TRANSACTION_ID
	(
	p_ISO_ACCOUNT_NAME IN VARCHAR2,
	p_PNODE_IDENT IN VARCHAR2,
	p_TRANSACTION_TYPE IN VARCHAR2,
	p_COMMODITY_NAME IN VARCHAR2,
	p_IS_IMPORT_EXPORT IN NUMBER,
	p_IS_FIRM IN NUMBER,
	p_CREATE_IF_NOT_FOUND IN BOOLEAN,
	p_TRANSACTION_ID OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2,
	p_SCHEDULE_NUMBER IN NUMBER DEFAULT 1,
    p_PJM_GEN_TXN_TYPE IN VARCHAR2 DEFAULT NULL,
    p_TIER_TYPE IN VARCHAR2 DEFAULT NULL,
    p_TXN_DESC IN VARCHAR2 DEFAULT NULL
	);

PROCEDURE PUT_MARKET_RESULTS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_SCHEDULE_DATE  IN DATE,
	p_SCHEDULE_STATE IN NUMBER,
	p_PRICE IN NUMBER,
	p_AMOUNT IN NUMBER,
	p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE  OUT VARCHAR2
	);

FUNCTION GET_IT_TRAIT_SCHEDULE
	(
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER,
	p_SCHEDULE_STATE IN NUMBER,
	p_SCHEDULE_DATE IN DATE,
	p_TRAIT_INDEX IN NUMBER := 1,
	p_SET_NUMBER IN NUMBER := 1,
	p_CONVERT_TO_BOOL IN BOOLEAN := FALSE
	) RETURN VARCHAR2;

FUNCTION GET_GEN_PORTFOLIO_NAME
	(
	p_ISO_ACCOUNT_NAME IN VARCHAR2
	) RETURN VARCHAR2;

g_PJM_GEN_UNIT_DATA_TXN_TYPE VARCHAR(32) := 'Unit Data';
g_PJM_GEN_SCHEDULE_TXN_TYPE VARCHAR(32) := 'Schedule';
g_PJM_GEN_REGULATION_TXN_TYPE VARCHAR(32) := 'Regulation';
g_PJM_GEN_SPIN_RES_TXN_TYPE VARCHAR(32) := 'Spinning Reserve';

g_PJM_TIME_ZONE CONSTANT VARCHAR2(3) := 'EDT';

-- initialized in package init code
g_EMKT_GEN_ATTR ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;
g_EMKT_LOAD_ATTR ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;

g_SUBMIT_MODE_DAILY CONSTANT NUMBER(1) := 1;
g_SUBMIT_MODE_ALL_HOURS CONSTANT NUMBER(1) := 2;
g_SUBMIT_MODE_SOME_HOURS CONSTANT NUMBER(1) := 3;
g_SUBMIT_MODE_NO_DATES CONSTANT NUMBER(1) := 4;
g_ALL_HOURS CONSTANT VARCHAR2(128) := '01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24';

END MM_PJM_EMKT_UTIL;
/