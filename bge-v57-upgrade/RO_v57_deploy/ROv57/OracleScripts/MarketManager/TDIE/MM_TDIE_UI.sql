CREATE OR REPLACE PACKAGE MM_TDIE_UI IS

  -- Author  : SPANICKER
  -- Created : 9/28/2009 1:00:18 PM
  -- Purpose : This package will be used by the UI to present the Raw Data Viewer and Mapping Screens
  -- $Revision: 1.31 $

c_TYPE_591	CONSTANT VARCHAR2(3) := '591';
c_TYPE_595  CONSTANT VARCHAR2(3) := '595';
c_TYPE_596	CONSTANT VARCHAR2(3) := '596';
c_TYPE_598	CONSTANT VARCHAR2(3) := '598';
c_TYPE_N598	CONSTANT VARCHAR2(4) := 'N598';

c_PERIOD_ENERGY	CONSTANT VARCHAR2(1) := 'P';

c_JURISDICTION_ROI CONSTANT VARCHAR2(3) := 'ROI';
c_JURISDICTION_NI CONSTANT VARCHAR2(3) := 'NI';

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE ROI_GENERATOR_NAME_LIST
	(
	p_SUPPLIER_UNIT IN VARCHAR2,
   	p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE NIETD_MESSAGE_DETAILS
	(
	p_DEMAND_TYPE IN VARCHAR2,
	p_SUPPLIER_UNIT IN VARCHAR2,
	p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2,
	p_SHOW_DETAIL IN NUMBER,
	p_LOAD_PROFILE IN STRING_COLLECTION,
	p_LOSS_FACTOR IN STRING_COLLECTION,
	p_UOS_TARIFF IN STRING_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PUT_NIETD_UNDER_REVIEW
	(
	p_TDIE_ID IN NUMBER,
	p_CUT_SCHEDULE_DATE IN DATE,
	p_UNDER_REVIEW IN NUMBER
	);

PROCEDURE PUT_UNDER_REVIEW
	(
	p_TDIE_ID IN NUMBER,
	p_INTERVAL_PERIOD_TIMESTAMP IN DATE,
	p_UNDER_REVIEW IN NUMBER
	);

PROCEDURE ROI_59X_MESSAGE_DETAILS
	(
	p_FILE_TYPE IN VARCHAR2,
	p_SUPPLIER_UNIT IN VARCHAR2,
	p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2,
	p_GENERATOR_NAME IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_JURISDICTION IN VARCHAR2,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE SUPPLIER_UNIT_LIST
	(
	p_FILE_TYPE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_JURISDICTION IN VARCHAR2,
	p_CURSOR IN OUT GA.REFCURSOR
	);

FUNCTION GENERATOR_IS_MAPPED_TO_SU
	(
	p_GENERATOR_NAME IN VARCHAR2,
	p_SUPPLIER_UNIT IN VARCHAR2,
	p_DATE IN DATE
	) RETURN NUMBER;

PROCEDURE TDIE_3XX_MESSAGES
	(
	p_ERRORS_ONLY IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_METER_TYPE IN VARCHAR2,
	p_LOAD_PROFILE_CODE IN VARCHAR2,
	p_DUOS_GROUP IN VARCHAR2,
	p_SEARCH_STRING IN VARCHAR2,
	p_IS_NI_HARMONISATION_SCREEN IN VARCHAR2,
	p_CURSOR IN OUT GA.REFCURSOR,
	p_WARNING_MESSAGE OUT VARCHAR2
	);

PROCEDURE TDIE_3XX_SYSTEM_LABELS
	(
	p_MODEL_ID		  IN VARCHAR2,
	p_MODULE		  IN VARCHAR2,
	p_KEY1			  IN VARCHAR2,
	p_KEY2			  IN VARCHAR2,
	p_KEY3			  IN VARCHAR2,
	p_CURSOR          IN OUT GA.REFCURSOR
	);

PROCEDURE TDIE_3XX_MESSAGE_DETAILS
	(
	p_MESSAGE_TYPE_CODE IN VARCHAR2,
	p_TDIE_ID IN NUMBER,
	p_DETAIL_TYPE IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2,
	p_IS_NI_HARMONISATION_SCREEN IN VARCHAR2,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE IGNORE_3XX_EXCEPTIONS
	(
	p_MESSAGE_TYPE_CODE IN STRING_COLLECTION,
	p_TDIE_ID IN NUMBER_COLLECTION
	);

PROCEDURE PROCESS_3XX_MESSAGES
	(
	p_MESSAGE_TYPE_CODE IN STRING_COLLECTION,
	p_TDIE_ID IN NUMBER_COLLECTION,
	p_PROCESS_ID OUT VARCHAR2,
	p_PROCESS_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

PROCEDURE REPROCESS_3XX_MESSAGES
	(
	p_JURISDICTION IN VARCHAR2,
	p_METER_TYPE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_MARKET_TIMESTAMP IN DATE,
	p_PROCESS_ID OUT VARCHAR2,
	p_PROCESS_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);
-------------------------------------------------------------------------------
-- Read only report of the mapping between a EARN ID and the
-- associated MPRNs and Supplier Unit.
PROCEDURE EARN_ID_MPRN_SU_MAPPING(p_CURSOR IN OUT GA.REFCURSOR);

END MM_TDIE_UI;
/