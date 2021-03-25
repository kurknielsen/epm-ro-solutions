CREATE OR REPLACE PACKAGE SEM_SETTLEMENT_COMP IS

  -- Author  : AHUSSAIN
  -- Created : 2/13/2008 4:13:47 PM
  -- Purpose : Package for Settlement variance and validation reports
  -- Revision: $Revision: 1.18 $
TYPE REF_CURSOR IS REF CURSOR;

g_STMT_TYPE_BEST_AVAILABLE CONSTANT NUMBER(1) := -2;
g_STMT_VAL_RPT_TYPE_CHG_AMOUNT CONSTANT VARCHAR2(32) := 'Charge Amount';
g_STMT_VAL_RPT_TYPE_ENERGY_VOL CONSTANT VARCHAR2(32) := 'Energy Volume';
g_STMT_VAL_DETAIL_TYPE_STMT CONSTANT VARCHAR2(32) := 'Statement';
g_STMT_VAL_DETAIL_TYPE_PIR CONSTANT VARCHAR2(32) := 'PIR';
g_STMT_VAL_DETAIL_TYPE_TDIE CONSTANT VARCHAR2(32) := 'TDIE';
g_STMT_VAL_DETAIL_TYPE_INT CONSTANT VARCHAR2(32) := 'Internal';
g_STMT_VAL_DETAIL_TYPE_300 CONSTANT VARCHAR2(32) := '300';
g_STMT_VAL_DETAIL_TYPE_341 CONSTANT VARCHAR2(32) := '341';
g_STMT_VAL_DETAIL_TYPE_342 CONSTANT VARCHAR2(32) := '342';
g_STMT_VAL_DETAIL_TYPE_591 CONSTANT VARCHAR2(32) := '591';
g_STMT_VAL_DETAIL_TYPE_595 CONSTANT VARCHAR2(32) := '595';
g_STMT_VAL_DETAIL_TYPE_596 CONSTANT VARCHAR2(32) := '596';
g_STMT_VAL_DETAIL_TYPE_598 CONSTANT VARCHAR2(32) := '598';
-------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR;
-------------------------------------------------------------------------------
PROCEDURE GET_PARTICIPANTS
(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------------------------------------------------
PROCEDURE GET_STATEMENT_COMPARISON_ITEMS
(
	p_PARTICIPANT_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------------------------------------------------
PROCEDURE GET_INVOICE_COMPARISON_ITEMS
(
	p_PARTICIPANT_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------------------------------------------------
PROCEDURE GET_SCHED_COMP_STATEMENT_TYPE
(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------------------------------------------------
PROCEDURE GET_TOLERANCE_COMPARISON_ITEMS
(
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------------------------------------------------
PROCEDURE GET_ERROR_TOLERANCE_RPT
(
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
);
--------------------------------------------------------------------------------
PROCEDURE PUT_ERROR_TOLERANCE
(
	p_PSE_ID IN NUMBER,
	p_COMPARISON_ITEM IN VARCHAR2,
	p_STATEMENT_TYPE1_ID IN NUMBER,
	p_STATEMENT_STATE1_ID IN NUMBER,
	p_STATEMENT_TYPE2_ID IN NUMBER,
	p_STATEMENT_STATE2_ID IN NUMBER,
	p_ABSOLUTE_ERROR_TOLERANCE IN NUMBER,
	p_RELATIVE_ERROR_TOLERANCE IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
);
------------------------------------------------------------------------------
PROCEDURE DELETE_ERROR_TOLERANCE
(
	p_PSE_ID IN NUMBER,
	p_COMPARISON_ITEM IN VARCHAR2,
	p_STATEMENT_TYPE1_ID IN NUMBER,
	p_STATEMENT_STATE1_ID IN NUMBER,
	p_STATEMENT_TYPE2_ID IN NUMBER,
	p_STATEMENT_STATE2_ID IN NUMBER,
	p_STATUS OUT NUMBER
);
--------------------------------------------------------------------------------
PROCEDURE GET_STATEMENT_COMPARISON_RPT
(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_PARTICIPANT_ID IN NUMBER,
	p_COMPARISON_ITEM IN VARCHAR2,
	p_COMP_FROM_STATEMENT_TYPE_ID IN NUMBER,
	p_COMP_TO_STATEMENT_TYPE_ID IN NUMBER,
	p_COMP_FROM_STATEMENT_STATE IN NUMBER,
	p_COMP_TO_STATEMENT_STATE IN NUMBER,
	p_VIOLATIONS_ONLY IN NUMBER DEFAULT 0,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR,
	p_MESSAGE OUT VARCHAR2
);
--------------------------------------------------------------------------------
PROCEDURE GET_INVOICE_COMPARISON_RPT
(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_PARTICIPANT_ID IN NUMBER,
	p_COMPARISON_ITEM IN VARCHAR2,
	p_COMP_FROM_STATEMENT_TYPE_ID IN NUMBER,
	p_COMP_TO_STATEMENT_TYPE_ID IN NUMBER,
	p_COMP_FROM_STATEMENT_STATE IN NUMBER,
	p_COMP_TO_STATEMENT_STATE IN NUMBER,
	p_VIOLATIONS_ONLY IN NUMBER DEFAULT 0,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
);
--------------------------------------------------------------------------------
FUNCTION GET_BILLING_ENTITY
(
	p_PARTICIPANT_PSE_ID NUMBER,
	p_COMPONENT VARCHAR2
) RETURN NUMBER;
--------------------------------------------------------------------------------
FUNCTION GET_ABSOLUTE_ERROR
(
	p_COMPARE_FROM_VALUE NUMBER,
	p_COMPARE_TO_VALUE NUMBER
) RETURN NUMBER;
--------------------------------------------------------------------------------
FUNCTION GET_RELATIVE_ERROR
(
	p_COMPARE_FROM_VALUE NUMBER,
	p_COMPARE_TO_VALUE NUMBER
) RETURN NUMBER;
--------------------------------------------------------------------------------
PROCEDURE RAISE_VARIANCE_ALERTS
(
	p_OPERATING_DAY IN DATE,
	p_COMPARISON_TYPE IN VARCHAR2,
	p_STATUS OUT NUMBER
);
--------------------------------------------------------------------------------
-- Used by the Participant filter on Settlement Validation report
PROCEDURE SUPPLIER_PARTICIPANT_LIST
(
	p_BEGIN_DATE DATE,
	p_END_DATE DATE,
	p_CURSOR IN OUT GA.REFCURSOR
);
---------------------------------------------------------------------------------
-- Used by the Supplier filter on Settlement Validation report
PROCEDURE SUPPLIER_UNIT_LIST
(
	p_BEGIN_DATE DATE,
	p_END_DATE DATE,
	p_PARTICIPANT_ID NUMBER,
	p_CURSOR OUT GA.REFCURSOR
);
---------------------------------------------------------------------------------
-- Used by the Component filter on Settlement Validation report
PROCEDURE COMPONENT_LIST
(
	p_PARTICIPANT_ID NUMBER,
	p_BEGIN_DATE DATE,
	p_END_DATE DATE,
	p_CURSOR IN OUT GA.REFCURSOR
);
---------------------------------------------------------------------------------
-- Returns the invoice period and statement dates for a given date range
-- and Market - Energy or Capacity and used in the Settlement Validation report
FUNCTION GET_STATEMENT_DATES
(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_MARKET_TYPE IN VARCHAR2
)
RETURN STATEMENT_DATE_TABLE PIPELINED;
---------------------------------------------------------------------------------
-- Used by the Statement filter on Settlement Validation report
PROCEDURE STATEMENT_TYPE_LIST
(
	p_CURSOR IN OUT GA.REFCURSOR
);
---------------------------------------------------------------------------------
-- Gets Statement, PIR, TDIE, Internal and corresponding Amount/Volume differences
-- for the Summary grid on the Settlement Validation report
PROCEDURE SEM_COMP_SUMMARY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_PARTICIPANT_ID IN NUMBER,
	p_STATEMENT_TYPE_ID IN NUMBER, -- Initial, Indicative or Best Available
	p_COMPONENT IN VARCHAR2, -- Component Name or <All>
	p_ENABLE_TOLERANCE IN NUMBER,
	p_PIR_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_TDIE_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_INTERNAL_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_REPORT_TYPE IN VARCHAR2, -- 'Charge Amount' or 'Energy Volume'
	p_CURSOR IN OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);
---------------------------------------------------------------------------------
-- Gets daily Statement, PIR, TDIE, Internal and corresponding Amount/Volume differences
-- for the Details grid on the Settlement Validation report
PROCEDURE SEM_COMP_DETAILS
	(
	p_INVOICE_BEGIN_DATE IN DATE,
	p_INVOICE_END_DATE IN DATE,
	p_ENTITY_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_REPORT_TYPE IN VARCHAR2, --'Charge Amount' or 'Energy Volume'
	p_CURSOR IN OUT GA.REFCURSOR
	);
---------------------------------------------------------------------------------
-- Utility function for finding the Run Indicator for a specified Statement Date
-- and Market
FUNCTION DETERMINE_SLMT_RUN_INDICATOR
	(
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE,
	p_MARKET_TYPE IN VARCHAR2, -- 'EN' or 'CA'
    p_JURISDICTION IN VARCHAR2 -- 'ROI' or 'NIE'
	) RETURN VARCHAR2;
---------------------------------------------------------------------------------
-- Gets the Charge Amount details on the drill-downs for the Settlement Validation report
PROCEDURE CHARGE_AMOUNT_INTERVAL_DETAILS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR2, -- '30 Minute' or 'Day'
	p_PARTICIPANT_ID IN NUMBER,
	p_STMT_TYPE IN NUMBER,
	p_COMPONENT IN VARCHAR2,
	p_SUPPLIER_UNIT IN VARCHAR2, -- Supplier Unit or '<All>'
	p_ENABLE_TOLERANCE IN NUMBER,
	p_PIR_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_TDIE_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_INTERNAL_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);
---------------------------------------------------------------------------------
-- Gets the Energy Volume details on the drill-downs for the Settlement Validation report
PROCEDURE ENERGY_VOLUME_INTERVAL_DETAILS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR2, -- '30 Minute' or 'Day'
	p_PARTICIPANT_ID IN NUMBER,
	p_STMT_TYPE IN NUMBER,
	p_COMPONENT_NAME IN VARCHAR2,
	p_SUPPLIER_UNIT IN VARCHAR2, -- Supplier Unit or '<All>'
	p_ENABLE_TOLERANCE IN NUMBER,
	p_TDIE_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_INTERNAL_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);
---------------------------------------------------------------------------------
-- Gets the IE T&D Volume details on the drill-downs for the Settlement Validation report
PROCEDURE TDIE_VOLUME_INTERVAL_DETAILS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR2, -- '30 Minute' or 'Day'
	p_PARTICIPANT_ID IN NUMBER,
	p_STMT_TYPE IN NUMBER,
	p_COMPONENT_NAME IN VARCHAR2,
	p_SUPPLIER_UNIT IN VARCHAR2, -- Supplier Unit or '<All>'
	p_ENABLE_TOLERANCE IN NUMBER,
	p_INVL_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_NON_INVL_PCT_TOLERANCE_DIFF IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);
---------------------------------------------------------------------------------
PROCEDURE PUT_TDIE_UNDER_REVIEW
	(
	p_TDIE_ID_595 IN NUMBER,
	p_UNDER_REVIEW_595 IN NUMBER,
	p_JURISDICTION_595 IN VARCHAR2,
	p_TDIE_ID_591 IN NUMBER,
	p_UNDER_REVIEW_591 IN NUMBER,
	p_JURISDICTION_591 IN VARCHAR2,
	p_CUT_SCHEDULE_DATE IN DATE
	);
---------------------------------------------------------------------------------
PROCEDURE NON_PART_GEN_VOLUME_DETAILS
	(
    p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR2, -- '30 Minute' or 'Day'
	p_PARTICIPANT_ID IN NUMBER,
	p_STMT_TYPE IN NUMBER,
	p_COMPONENT_NAME IN VARCHAR2,
	p_SUPPLIER_UNIT IN VARCHAR2, -- Supplier Unit or '<All>'
    p_CURSOR OUT GA.REFCURSOR
	);
---------------------------------------------------------------------------------
PROCEDURE CACHE_SCHEDULE_DETAILS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_PARTICIPANT_ID IN NUMBER,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_SUPPLIER_UNIT IN VARCHAR2,-- Supplier Unit or '<All>'
	p_DETAIL_TYPE IN VARCHAR2 -- 300,341 and 342
	);
---------------------------------------------------------------------------------
-- For the report validating the NDLFESU with MGR Determinants
-- Will be used by the UI and perform various functions
PROCEDURE NDLFESU_VALIDATION_DETAILS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INTERVAL IN VARCHAR2, -- '30 Minute','Week','Day','Month'
	p_STATEMENT_TYPE_ID IN NUMBER,
    p_TIME_ZONE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	);
---------------------------------------------------------------------------------
END SEM_SETTLEMENT_COMP;
/