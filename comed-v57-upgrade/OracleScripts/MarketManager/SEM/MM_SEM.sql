CREATE OR REPLACE PACKAGE MM_SEM AS
    /**
    * Overriding package to MM for SEM specific overrides
    *
    * %author  Rex Arul
    * $Revision: 1.12 $
    * %history 2007-03-30 -- Initial Release
    */

	FUNCTION WHAT_VERSION RETURN VARCHAR;

    -- This overriding procedure will return the traits associated with an Interchange Transaction and
    -- is normally invoked by MM package. Please see {%link MM} package.
    -- %param p_TRANSACTION_ID Transaction ID of Interchange Transaction.
    -- %param p_REPORT_TYPE Report Type.
    -- %param p_TRAIT_GROUP_FILTER Trait Group Filter. Please see {%link TRANSACTION_TRAIT_GROUP} table.
    -- %param p_INTERVAL Is it '30 Minute', 'Day' etc.
    -- %param p_WORK_ID Work ID of the {%lINK RTO_WORK} table. This is an OUT param.
    -- %raise None.
    PROCEDURE GET_TRAITS_FOR_TRANSACTION
    (
        p_TRANSACTION_ID     IN NUMBER,
        p_REPORT_TYPE        IN VARCHAR2,
        p_TRAIT_GROUP_FILTER IN VARCHAR2,
        p_INTERVAL           IN VARCHAR2,
        p_WORK_ID            OUT NUMBER
    );

    -- This is an overriding function that will return the Bid Offer Interval like ('Day', '30 Minute', etc.) and
    -- normally invoked by MM package. Please see {%link MM} package.
    -- %param p_TRANSACTION Entire row of {%link INTERCHANGE_TRANSACTION}.
    -- %return Returns the interval as say 'Day', '30 Minute' etc.
    -- %raise None.
    FUNCTION GET_BID_OFFER_INTERVAL(p_TRANSACTION IN INTERCHANGE_TRANSACTION%ROWTYPE)
        RETURN VARCHAR2;

PROCEDURE GET_AFFECTED_DATE_RANGE
	(
	p_TRANSACTION_ID IN NUMBER,
	p_CUT_DATE IN OUT DATE,
	p_IS_SUB_DAILY IN BOOLEAN,
	p_BEGIN_DATE OUT DATE,
	p_END_DATE OUT DATE
	);
FUNCTION TRAIT_AFFECTS_STATUS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRAIT_INDEX IN NUMBER
	) RETURN BOOLEAN;

PROCEDURE GET_IT_TRAIT_OFFER_MGT_GEN
	(
	p_BEGIN_DATE			IN	DATE,
	p_END_DATE				IN	DATE,
	p_TIME_ZONE 			IN	VARCHAR2,
	p_GENERATOR_IDS			IN	NUMBER_COLLECTION,
	p_GATE_WINDOW_IDS		IN	NUMBER_COLLECTION,
	p_STATUS			   OUT	NUMBER,
	p_CURSOR			   OUT	GA.REFCURSOR
	);

PROCEDURE GET_IT_TRAIT_OFFER_MGT_DET_GEN
	(
	p_TRANSACTION_ID		IN	NUMBER,
	p_CUT_DATE_SCHEDULING	IN	DATE,
	p_TIME_ZONE 			IN	VARCHAR2,
	p_STATUS			   OUT	NUMBER,
	p_CURSOR			   OUT	GA.REFCURSOR
	);

PROCEDURE PUT_IT_TRAIT_OFFER_MGT_GEN
	(
	p_TRANSACTION_ID 		IN NUMBER,
	p_CUT_DATE_SCHEDULING 	IN DATE,
	p_TRAIT_GROUP_ID 		IN NUMBER,
	p_TRAIT_INDEX 			IN NUMBER,
	p_SET_NUMBER 			IN NUMBER,
	p_TRAIT_VAL 			IN VARCHAR2
	);

PROCEDURE IT_TRAIT_OFFER_MGT_GEN_ACCEPT
	(
	p_TRANSACTION_ID		IN NUMBER,
	p_CUT_DATE_SCHEDULING	IN DATE
	);

PROCEDURE IT_TRAIT_OFFER_ACCEPT
	(
	p_TRANSACTION_ID 		IN NUMBER,
	p_CUT_DATE_SCHEDULING 	IN DATE_COLLECTION
	);

PROCEDURE PUT_IT_TRAIT_SCHED_DETAIL_RPT
	(
	p_TRANSACTION_ID		IN NUMBER,
	p_SCHEDULE_STATE		IN NUMBER,
	p_SCHEDULE_TYPE			IN NUMBER,
	p_CUT_DATE_SCHEDULING	IN DATE,
	p_TRAIT_GROUP_ID		IN NUMBER,
	p_TRAIT_INDEX			IN NUMBER,
	p_SET_NUMBER			IN NUMBER,
	p_TRAIT_VAL				IN VARCHAR,
	p_REASON_FOR_CHANGE		IN VARCHAR2,
	p_OTHER_REASON			IN VARCHAR2,
	p_PROCESS_MESSAGE		IN VARCHAR2
	);

PROCEDURE GET_IT_TRAIT_OFFER_MGT_IU
	(
	p_BEGIN_DATE			IN	DATE,
	p_END_DATE				IN	DATE,
	p_TIME_ZONE 			IN	VARCHAR2,
	p_INTERCONNECTOR_IDS	IN	NUMBER_COLLECTION,
	p_GATE_WINDOW_IDS		IN	NUMBER_COLLECTION,
	p_DATE_OFFSET			IN	NUMBER,
	p_SCHEDULE_TYPE			IN	NUMBER,
	p_SCHEDULE_STATE		IN	NUMBER,
	p_INTERVAL				IN	VARCHAR2,
	p_STATUS			   OUT	NUMBER,
	p_CURSOR			   OUT	GA.REFCURSOR
	);

PROCEDURE GET_OFFER_SUBMISSION_STATUS
  (
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_TIME_ZONE IN VARCHAR2,
  p_GATE_WINDOW_ID IN NUMBER,
  p_RESOURCE_TYPE IN VARCHAR2, -- Generators or Interconnectors
  p_CURSOR OUT GA.REFCURSOR
  );

PROCEDURE COMBINED_OFFERS_SUBMIT
  (
  p_BEGIN_DATE IN DATE,
  p_END_DATE IN DATE,
  p_TRANSACTION_IDS IN NUMBER_COLLECTION,
  p_LOG_TYPE IN NUMBER,
  p_TRACE_ON IN NUMBER,
  p_STATUS OUT NUMBER,
  p_MESSAGE OUT VARCHAR2
  );

PROCEDURE GET_EXCLUDED_BIDS
  (
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_TIME_ZONE IN VARCHAR2,
   p_INTERCONNECTOR_IDS IN NUMBER_COLLECTION,
   p_GATE_WINDOW_IDS IN NUMBER_COLLECTION,
   p_CURSOR OUT GA.REFCURSOR
  );

    /*----------------------------------------------------------------------------*
    *   TYPES                                                                     *
    *----------------------------------------------------------------------------*/
    -- This type is an associative-array to hold Interval Values for Transaction Types.
    TYPE t_INTERVAL_TYPE IS TABLE OF VARCHAR2(12) INDEX BY VARCHAR2(64);

    /*----------------------------------------------------------------------------*
    *   GLOBAL VARIABLES                                                          *
    *----------------------------------------------------------------------------*/
    -- Variable of {%link t_INTERVAL_TYPE}.
    g_INTERVAL_TBL t_INTERVAL_TYPE;

    /*----------------------------------------------------------------------------*
    *   CONSTANTS                                                                *
    *----------------------------------------------------------------------------*/
    -- Verbose constant
    k_NOMINATION CONSTANT VARCHAR2(64) := 'Nomination';
    -- Verbose constant
    k_GENERATION CONSTANT VARCHAR2(64) := 'Generation';
    -- Verbose constant
    k_LOAD CONSTANT VARCHAR2(64) := 'Load';
    -- Verbose constant
    k_DEFAULT CONSTANT VARCHAR2(64) := 'Default';

	g_SECOND CONSTANT NUMBER(6,5) :=  .00001;

	g_OFFER_INTERVAL CONSTANT VARCHAR2(7) := '<Offer>';

    g_OFFER_UI_GENERATORS CONSTANT VARCHAR2(16) := 'Generators';
    g_OFFER_UI_INTERCONNECTORS CONSTANT VARCHAR2(16) := 'Interconnectors';
END MM_SEM;
/
