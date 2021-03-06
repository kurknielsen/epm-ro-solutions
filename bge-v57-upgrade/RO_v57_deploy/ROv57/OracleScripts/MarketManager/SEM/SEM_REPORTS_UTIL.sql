CREATE OR REPLACE PACKAGE SEM_REPORTS_UTIL IS
	-- $Revision: 1.13 $

/*----------------------------------------------------------------------------*
 *   TYPES                                                                    *
 *----------------------------------------------------------------------------*/
TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE GET_RESOURCE
	(
	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_IC_RESOURCE
	(
	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
	);
	
PROCEDURE GET_IC_RESOURCE_OFF_CAP
	(
	p_INCLUDE_ALL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
	
PROCEDURE GET_RESOURCE_TYPE
	(
	p_RESOURCE_ID VARCHAR2,
	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_FUEL_TYPE
	(
	p_RESOURCE_ID VARCHAR2,
	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_UNDER_TEST
	(
	p_RESOURCE_ID VARCHAR2,
	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_SCHEDULE_TYPE
	(
	p_RESOURCE_ID VARCHAR2,
	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_IDT_CHG_SCHED_TYPE
    (
    p_RESOURCE_ID VARCHAR2,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
    );

PROCEDURE GET_PSE
	(
	p_STATUS OUT NUMBER,
    p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_PSE_IC_NOMS(p_STATUS OUT NUMBER, p_CURSOR IN OUT REF_CURSOR);

PROCEDURE GP_VARIABLE_TYPES
	(
	p_REPORT_TYPE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GP_RESOURCE_NAMES
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE SETTLEMENT_REPORT_TYPES
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE SETTLEMENT_MARKET_TYPES
	(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE STATEMENT_IDENTIFIERS
	(
	p_GET_PIR_ONLY IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_GATE_WINDOW_TYPE
	(
	p_INCLUDE_ALL IN NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);
	
PROCEDURE GET_GATE_WINDOW_TYPE_OFF_CAP
	(
  	p_INCLUDE_ALL IN NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);	

PROCEDURE GET_GEN_IT_TRAIT_OFFER
	(
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_IU_IT_TRAIT_OFFER
	(
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE GET_IDT_SCHEDULE_AS_RUN_TYPE
	(
   p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE INTERCONNECTOR_DETAILS_GET_PSE
(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
);

END SEM_REPORTS_UTIL;
/
