CREATE OR REPLACE PACKAGE RETAIL_DETERMINANTS IS

  -- $Revision: 1.41 $
  -- Author  : JHUMPHRIES
  -- Created : 12/4/2009 1:40:04 PM
  -- Purpose : Supports access of retail determinants via DETERMINANT_ACCESSOR objects

-- Constants for determinant status values
c_STATUS_OK			CONSTANT PLS_INTEGER := 0;
c_STATUS_MISSING	CONSTANT PLS_INTEGER := 1;
c_STATUS_PARTIAL	CONSTANT PLS_INTEGER := 2;


-- Constants for loss adjustment types
c_ADJ_TYPE_NONE		CONSTANT PLS_INTEGER := 0;
c_ADJ_TYPE_LOSSES	CONSTANT PLS_INTEGER := 1;
c_ADJ_TYPE_LOSS_UFE	CONSTANT PLS_INTEGER := 2;
c_ADJ_TYPE_MTR_PT_LOSSES CONSTANT PLS_INTEGER :=3;

-- Constants for meter channel operation codes
c_OPERATION_CODE_ADD          CONSTANT CHAR := 'A';
c_OPERATION_CODE_SUBTRACT     CONSTANT CHAR := 'S';
c_OPERATION_CODE_NONE         CONSTANT CHAR := 'N';

FUNCTION WHAT_VERSION RETURN VARCHAR2;

FUNCTION IS_SUB_DAILY
	(
	p_INTERVAL IN VARCHAR2
	) RETURN BOOLEAN;

FUNCTION GET_NUMBER_OF_INTERVALS
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN PLS_INTEGER;

PROCEDURE DETERMINANT_ACCESSOR_DATES
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_DET_BEGIN_DATE OUT DATE,
	p_DET_END_DATE OUT DATE
	);

--=============================================================
-- Create new account accessors
FUNCTION GET_ACCT_DETERMINANT_ACCESSOR
	(
	p_ACCOUNT_ID			IN NUMBER,
	p_SERVICE_LOCATION_ID	IN NUMBER,
	p_METER_ID				IN NUMBER,
	p_AGGREGATE_ID			IN NUMBER,
	p_SERVICE_CODE			IN CHAR,
	p_SCENARIO_ID			IN NUMBER,
	p_TIME_ZONE				IN VARCHAR2,
    p_ESP_ID                IN NUMBER := NULL
	) RETURN ACCOUNT_DETERMINANT_ACCESSOR;

FUNCTION GET_ACCT_DETERMINANT_ACCESSOR
	(
	p_ACCOUNT_SERVICE_ID	IN NUMBER,
	p_SERVICE_CODE			IN CHAR,
	p_SCENARIO_ID			IN NUMBER,
	p_TIME_ZONE				IN VARCHAR2
	) RETURN ACCOUNT_DETERMINANT_ACCESSOR;

FUNCTION GET_METER_TYPE_TEMPLATE_ID
	(
	p_ACCESSOR IN ACCOUNT_DETERMINANT_ACCESSOR,
	p_DATE IN DATE
	) RETURN NUMBER;

FUNCTION GET_ACTIVE_SERVICES
	(
	p_ACCESSOR IN ACCOUNT_DETERMINANT_ACCESSOR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_DATES_ARE_CUT IN BOOLEAN := FALSE,
	p_TIME_ZONE IN VARCHAR2 := NULL
	) RETURN NUMBER_COLLECTION;

--=============================================================
-- Create new schedule accessors
FUNCTION GET_POD_DETERMINANT_ACCESSOR
	(
	p_SERVICE_POINT_ID	IN NUMBER,
	p_PSE_ID			IN NUMBER,
	p_METER_TYPE		IN VARCHAR2,
	p_STATEMENT_TYPE_ID	IN NUMBER,
	p_TIME_ZONE			IN VARCHAR2
	) RETURN POD_DETERMINANT_ACCESSOR;

--=============================================================
-- Create new tax accessors
FUNCTION GET_TAX_DETERMINANT_ACCESSOR
    (
    p_TIME_ZONE        IN VARCHAR2
    ) RETURN TAX_DETERMINANT_ACCESSOR;

FUNCTION GET_ACTIVE_TRANSACTIONS
	(
	p_ACCESSOR IN POD_DETERMINANT_ACCESSOR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_DATES_ARE_CUT IN BOOLEAN := FALSE,
	p_TIME_ZONE IN VARCHAR2 := NULL
	) RETURN NUMBER_COLLECTION;

--=============================================================
-- For implementing DETERMINANT_ACCESSOR.GET_PEAK_DETERMINANT

-- Returns the single maximum/peak determinant value. This is used by Peak
-- Demand components and used in evaluating block/tier ranges for Demand Hours
-- components. When determinants are non-interval data, the “demand” reading is
-- used, not the “energy” reading.
-- %param p_ACCESSOR		The account determinant accessor on whose behalf the
--							determinants are queried.
-- %param p_INTERVAL		When this value is ‘Meter Period’, non-interval data
--							will be used if available. Otherwise, if it is ‘Day’
--							or greater, the date range is expected to be a span
--							of days; but if it is sub-daily the date range is
--							expected to be in CUT time.
-- %param p_BEGIN_DATE		The begin date of the bill period.
-- %param p_END_DATE		The end date of the bill period.
-- %param p_UOM				The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID		If not NULL, only retrieve results for a particular
--							time of use period.
-- %param p_PERIOD_ID		Required if p_TEMPLATE_ID is not NULL. Identifies
--							from which time of use period to query determinants.
-- %param p_LOSS_ADJ_TYPE	Type of loss-adjustment, if any, to apply to
--							determinants. This currently only applies to interval
--							metered usage for retail account determinants.
-- %param p_INTEGRATION_INTERVAL  An optional parameter that specifies the number
--                      of intervals to integrate together before selecting
--                      peak interval. For example, if the data was 15 minute
--                      and the peak was determined by Averaging the data every 30
--                      minutes then you would specify a value of '30 Minute'. This only
--                      applies to sub-daily data.
-- %param p_RETURN_VALUE	The result peak value.
-- %param p_RETURN_STATUS	The status of the determinants used to find the
--							result value: 0 = OK, 1 = Missing (result will be 0),
--							or 2 = Partial. Partial for interval data means that
--							data did not exist for the full date range; for non-
--							interval data, it means that period records that span
--							the entire date range were not found.
PROCEDURE GET_PEAK_DETERMINANT
	(
	p_ACCESSOR IN OUT NOCOPY ACCOUNT_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEFAULT_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTEGRATION_INTERVAL IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	);

-- Returns the single maximum/peak determinant value. This is used by Peak
-- Demand components and used in evaluating block/tier ranges for Demand Hours
-- components.
-- %param p_ACCESSOR		The service point determinant accessor on whose
--							behalf the determinants are queried.
-- %param p_INTERVAL		If this value is ‘Day’ or greater, the date range is
--							expected to be a span of days; but if it is sub-daily
--							the date range is expected to be in CUT time.
-- %param p_BEGIN_DATE		The begin date of the bill period.
-- %param p_END_DATE		The end date of the bill period.
-- %param p_UOM				The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID		If not NULL, only retrieve results for a particular
--							time of use period.
-- %param p_PERIOD_ID		Required if p_TEMPLATE_ID is not NULL. Identifies
--							from which time of use period to query determinants.
-- %param p_LOSS_ADJ_TYPE	Type of loss-adjustment, if any, to apply to
--							determinants. This currently only applies to interval
--							metered usage for retail account determinants.
-- %param p_RETURN_VALUE	The result peak value.
-- %param p_RETURN_STATUS	The status of the determinants used to find the
--							result value: 0 = OK, 1 = Missing (result will be 0),
--							or 2 = Partial.
PROCEDURE GET_PEAK_DETERMINANT
	(
	p_ACCESSOR IN OUT NOCOPY POD_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEF_SCHED_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTEGRATION_INTERVAL IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	);

--=============================================================
-- For implementing DETERMINANT_ACCESSOR.GET_SUM_DETERMINANTS

-- Returns the sum of determinant values. This is used by most components
-- including all of the following charge types: Energy, Commodity, Demand
-- Hours, Transportation, Transmission, and Distribution. When determinants are
-- non-interval data, the “energy” reading is used, not the “demand” reading.
-- %param p_ACCESSOR				The account determinant accessor on whose behalf the
--									determinants are queried.
-- %param p_INTERVAL				When this value is ‘Meter Period’, non-interval data
--									will be used if available. Otherwise, if it is ‘Day’
--									or greater, the date range is expected to be a span
--									of days; but if it is sub-daily the date range is
--									expected to be in CUT time.
-- %param p_BEGIN_DATE				The begin date of the bill period.
-- %param p_END_DATE				The end date of the bill period.
-- %param p_UOM						The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID				If not NULL, only retrieve results for a particular
--									time of use period.
-- %param p_PERIOD_ID				Required if p_TEMPLATE_ID is not NULL. Identifies
--									from which time of use period to query determinants.
-- %param p_LOSS_ADJ_TYPE			Type of loss-adjustment, if any, to apply to
--									determinants. This currently only applies to interval
--									metered usage for retail account determinants.
-- %parm p_INTERVAL_MINIMUM_QTY		If Zero should be used as Minimum Quantity at Interval level.
--									'Use Zero As Min Interval Qty', then this value is passed. Else NULL.
--									Cannot be used for 'Block'/'Tiered' Rate Structures or 'Demand Hours' Charge Type
--									or Interval other than 'Meter Period'
-- %param p_RETURN_VALUE			The result sum value.
-- %param p_RETURN_STATUS			The status of the determinants used to find the
--									result value: 0 = OK, 1 = Missing (result will be 0),
--									or 2 = Partial. Partial for interval data means that
--									data did not exist for the full date range; for non-
--									interval data, it means that period records that span
--									the entire date range were not found.
PROCEDURE GET_SUM_DETERMINANTS
	(
	p_ACCESSOR IN OUT NOCOPY ACCOUNT_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEFAULT_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTERVAL_MINIMUM_QTY IN NUMBER := NULL,
	p_OPERATION_CODE IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	);

-- Returns the sum of determinant values. This is used by most components
-- including all of the following charge types: Energy, Commodity, Demand
-- Hours, Transportation, Transmission, and Distribution. When determinants are
-- non-interval data, the “energy” reading is used, not the “demand” reading.
-- %param p_ACCESSOR		The service point determinant accessor on whose
--							behalf the determinants are queried.
-- %param p_INTERVAL		If this value is ‘Day’ or greater, the date range is
--							expected to be a span of days; but if it is sub-daily
--							the date range is expected to be in CUT time.
-- %param p_BEGIN_DATE		The begin date of the bill period.
-- %param p_END_DATE		The end date of the bill period.
-- %param p_UOM				The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID		If not NULL, only retrieve results for a particular
--							time of use period.
-- %param p_PERIOD_ID		Required if p_TEMPLATE_ID is not NULL. Identifies
--							from which time of use period to query determinants.
-- %param p_LOSS_ADJ_TYPE	Type of loss-adjustment, if any, to apply to
--						determinants. This currently only applies to interval
--						metered usage for retail account determinants.
-- %param p_RETURN_VALUE	The result sum value.
-- %param p_RETURN_STATUS	The status of the determinants used to find the
--							result value: 0 = OK, 1 = Missing (result will be 0),
--							or 2 = Partial.
PROCEDURE GET_SUM_DETERMINANTS
	(
	p_ACCESSOR IN OUT NOCOPY POD_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEF_SCHED_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_OPERATION_CODE IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	);

-- Returns the average interval count of TX Substation Meter Point values. "Account"
-- Accessors (via Entity_Type = "Account" on the Component) will access this API.
-- No other accessor is supported.
-- %param p_ACCESSOR		The Account Determinant Accessor on whose
--							behalf the determinants are queried.
-- %param p_INVOICE_LINE_BEGIN_DATE		The begin date of the bill period.
-- %param p_INVOICE_LINE_END_DATE		The end date of the bill period.
-- %param p_UOM				The unit of measurement of the determinants to query.
-- %param p_QUALITY_CODE	Any String-Value for the Quality Code
-- %param p_STATUS_CODE		String-Value. Corresponds to Statement Types in the system.
--							from which time of use period to query determinants.
-- %param p_DATE_RANGE_ INTERVAL		If this value is ‘Day’ or greater, the date range is
--							expected to be a span of days; but if it is sub-daily
--							the date range is expected to be in CUT time.
-- %param p_RETURN_VALUE	The result sum value.
-- %param p_RETURN_STATUS	The status of the determinants used to find the
--							result value: 0 = OK will be passed always
PROCEDURE GET_AVERAGE_INTERVAL_COUNT
	(
	p_ACCESSOR 					IN OUT NOCOPY ACCOUNT_DETERMINANT_ACCESSOR,
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_UOM 						IN VARCHAR2 := NULL,
	p_QUALITY_CODE 				IN VARCHAR2 := NULL,
	p_STATUS_CODE 				IN VARCHAR2 := NULL,
	p_DATE_RANGE_INTERVAL		IN VARCHAR2 := NULL,
	p_RETURN_VALUE 				OUT NUMBER,
	p_RETURN_STATUS 			OUT PLS_INTEGER
	);

$IF $$UNIT_TEST_MODE = 1 $THEN
PROCEDURE INT_COUNT_VALIDATE_INPUTS
(
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_DATE_RANGE_INTERVAL 		IN VARCHAR2
);

PROCEDURE INT_COUNT_CUT_DATE_RANGE
(
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_DATE_RANGE_INTERVAL 		IN VARCHAR2,
	p_CUT_BEGIN_DATE			OUT DATE,
	p_CUT_END_DATE				OUT DATE
);

FUNCTION INT_COUNT_RESULT
(
	p_METER_ID					IN METER.METER_ID%TYPE,
	p_BEGIN_DATE 				IN DATE,
	p_END_DATE					IN DATE,
	p_UOM						IN VARCHAR2,
	p_QUALITY_CODE				IN VARCHAR2,
	p_STATUS_CODE				IN VARCHAR2,
	p_TIME_ZONE					IN VARCHAR2,
	p_SERVICE_CODE				IN VARCHAR2
)RETURN NUMBER;
$END

END RETAIL_DETERMINANTS;
/
CREATE OR REPLACE PACKAGE BODY RETAIL_DETERMINANTS IS
-------------------------------------------------------------------------------
-- Package variables
-------------------------------------------------------------------------------

c_ALL_HOLIDAY_SET   CONSTANT HOLIDAY_SET.HOLIDAY_SET_ID%TYPE := CONSTANTS.ALL_HOLIDAYS_HOLIDAY_SET;
c_NOT_ASSIGNED      CONSTANT NUMBER := CONSTANTS.NOT_ASSIGNED;
c_HIGH_DATE         CONSTANT DATE := CONSTANTS.HIGH_DATE;

-- The types of caches that can contain results
c_CACHE_TABLE_PERIOD	CONSTANT PLS_INTEGER := 0;
c_CACHE_TABLE_INTERVAL	CONSTANT PLS_INTEGER := 1;
c_CACHE_TABLE_BOTH		CONSTANT PLS_INTEGER := 2;

-- The type of data in the cache tables
g_CACHE_TYPE			PLS_INTEGER;
c_CACHE_TYPE_ACCOUNT	CONSTANT PLS_INTEGER := 0;
c_CACHE_TYPE_POD		CONSTANT PLS_INTEGER := 1;

-- Constants for p_OVERLAP_MODE of POPULATE_PERIOD_CACHE method
c_OVERLAP_MODE_ALL		CONSTANT PLS_INTEGER := 0;
c_OVERLAP_MODE_BEGIN	CONSTANT PLS_INTEGER := 1;
c_OVERLAP_MODE_END		CONSTANT PLS_INTEGER := 2;

-- Information about period data that is cached
TYPE t_DATE_RANGE IS RECORD (BEGIN_DATE DATE, END_DATE DATE);
TYPE t_PERIOD_CACHE IS TABLE OF t_DATE_RANGE INDEX BY VARCHAR2(40);
-- Cache structure:
-- Key   = Service ID, UOM, and Template ID
-- Value = Date range of entries in the cache
g_PERIOD_CACHE_DEF		t_PERIOD_CACHE;

-- Information about interval data that is cached
TYPE t_TEMPLATE_SET IS TABLE OF BINARY_INTEGER INDEX BY BINARY_INTEGER;
TYPE t_INTERVAL_CACHE IS TABLE OF t_TEMPLATE_SET INDEX BY VARCHAR2(40);
-- Cache structure:
-- Key   = Service ID *OR* Transaction ID, UOM, and Day
-- Value = Map of cached templates:
--         Key   = Template ID
--         Value = Status for this entry - OK, Missig, Partial, or NULL
g_INTERVAL_CACHE_DEF	t_INTERVAL_CACHE;

-- Granularity of interval cache - comes from GET_INTERVAL_NUMBER for data interval -
-- tracks interval granularity by UOM for Account cache, but single granularity for
-- POD/Transaction cache.
TYPE t_CACHE_GRAN IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(16);
g_INTERVAL_CACHE_GRAN	t_CACHE_GRAN;
c_POD_CACHE_GRAN_KEY	CONSTANT VARCHAR2(16) := '*'; -- POD/Transaction cache uses single granularity

-- Information (like data interval) for objects represented by the cache
TYPE t_OBJECT_INFO IS RECORD (METER_TYPE VARCHAR2(16), INTERVAL VARCHAR2(16), INTERVAL_ORD PLS_INTEGER, EDC_HOLIDAY_SET_ID NUMBER(9,0));
TYPE t_OBJECT_INFO_CACHE IS TABLE OF t_OBJECT_INFO INDEX BY BINARY_INTEGER;

g_OBJECT_INFO_CACHE		t_OBJECT_INFO_CACHE;

-- For performance of GET_ACTIVE_SERVICES and GET_ACTIVE_TRANSACTIONS to
-- avoid redundant re-querying of IDs
g_PREV_ACTIVE_BEGIN_DATE	DATE;
g_PREV_ACTIVE_END_DATE		DATE;
g_PREV_ACTIVE_TXNS			NUMBER_COLLECTION;
g_PREV_ACTIVE_SVC_WORK_ID	RTO_WORK.WORK_ID%TYPE; -- more complex than list of txn IDs

-- Values that track what data is in the cache
--------- When g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT
g_LAST_ACCOUNT_ID	NUMBER(9);
g_LAST_SVC_LOC_ID	NUMBER(9);
g_LAST_METER_ID		NUMBER(9);
g_LAST_AGGREGATE_ID	NUMBER(9);
g_LAST_SCENARIO_ID	NUMBER(9);
g_LAST_SERVICE_CODE	CHAR(1);
g_LAST_TIME_ZONE	VARCHAR2(16);
g_LAST_SVC_WORK_ID	NUMBER(9);

g_LAST_METER_TYPE_TEMPLATE_ID	NUMBER(9);
g_LAST_METER_TYPE_EFF_DATE		DATE;

--------- When g_CACHE_TYPE = c_CACHE_TYPE_POD
g_LAST_SERVICE_POINT_ID		NUMBER(9);
g_LAST_PSE_ID				NUMBER(9);
g_LAST_STATEMENT_TYPE_ID	NUMBER(9);
g_LAST_METER_TYPE			VARCHAR2(16);
-- g_LAST_TIME_ZONE	is also used for c_CACHE_TYPE_POD

-- For performance of IS_SUB_DAILY function don't re-examine interval repeatedly - cache previous values
g_PREV_INTERVAL		VARCHAR2(16);
g_PREV_SUB_DAILY	BOOLEAN;
-------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
	RETURN '$Revision: 1.41 $';
END WHAT_VERSION;
-----------------------------------------------------------------------------------
FUNCTION GET_ACCOUNT_EDC_HOLIDAY_SET_ID (
   p_ACCOUNT_ID     IN NUMBER,
   p_EFFECTIVE_DATE IN DATE)
RETURN NUMBER
IS
   v_HOLIDAY_SET_ID    NUMBER := c_ALL_HOLIDAY_SET;
BEGIN

SELECT EDC.EDC_HOLIDAY_SET_ID
  INTO v_HOLIDAY_SET_ID
  FROM ACCOUNT_EDC                 AE,
       ENERGY_DISTRIBUTION_COMPANY EDC
 WHERE AE.ACCOUNT_ID = p_ACCOUNT_ID
   AND p_EFFECTIVE_DATE BETWEEN AE.BEGIN_DATE AND NVL(AE.END_DATE, c_HIGH_DATE)
   AND AE.EDC_ID = EDC.EDC_ID;

   IF NVL(v_HOLIDAY_SET_ID,c_NOT_ASSIGNED) = c_NOT_ASSIGNED THEN
     v_HOLIDAY_SET_ID := c_ALL_HOLIDAY_SET;
   END IF;

   RETURN v_HOLIDAY_SET_ID;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN c_ALL_HOLIDAY_SET;
   WHEN OTHERS THEN
      RETURN c_ALL_HOLIDAY_SET;
END GET_ACCOUNT_EDC_HOLIDAY_SET_ID;
-----------------------------------------------------------------------------------
FUNCTION GET_POD_EDC_HOLIDAY_SET_ID (
   p_SERVICE_POINT_ID IN NUMBER)
RETURN NUMBER
IS
   v_HOLIDAY_SET_ID    NUMBER := NULL;
BEGIN

  SELECT EDC.EDC_HOLIDAY_SET_ID
    INTO v_HOLIDAY_SET_ID
    FROM SERVICE_POINT               SP,
         ENERGY_DISTRIBUTION_COMPANY EDC
   WHERE SP.SERVICE_POINT_ID    = p_SERVICE_POINT_ID
     AND SP.EDC_ID              = EDC.EDC_ID;

   IF NVL(v_HOLIDAY_SET_ID,c_NOT_ASSIGNED) = c_NOT_ASSIGNED THEN
     v_HOLIDAY_SET_ID := c_ALL_HOLIDAY_SET;
   END IF;

   RETURN v_HOLIDAY_SET_ID;

EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN c_ALL_HOLIDAY_SET;
   WHEN OTHERS THEN
      RETURN c_ALL_HOLIDAY_SET;
END GET_POD_EDC_HOLIDAY_SET_ID;
-------------------------------------------------------------------------------
FUNCTION IS_VALID_INTEGRATION_INTERVAL
(
   p_FORMAT_STRING IN VARCHAR2
)RETURN BOOLEAN
IS
BEGIN
   RETURN UPPER(p_FORMAT_STRING) IN (UPPER(DATE_UTIL.c_NAME_15MIN), UPPER(DATE_UTIL.c_NAME_30MIN), UPPER(DATE_UTIL.c_NAME_HOUR));
END IS_VALID_INTEGRATION_INTERVAL;
-------------------------------------------------------------------------------
FUNCTION GET_NUM_OF_SUBDAILY_INTERVALS
(
   p_FORMAT_STRING IN VARCHAR2
)RETURN NUMBER
IS
   v_INTERVAL_ABBREVIATION VARCHAR2(16) := GET_INTERVAL_ABBREVIATION(p_FORMAT_STRING);
BEGIN
   CASE
	  WHEN v_INTERVAL_ABBREVIATION = 'MI15' THEN RETURN 96;
	  WHEN v_INTERVAL_ABBREVIATION = 'MI30' THEN RETURN 48;
	  WHEN v_INTERVAL_ABBREVIATION = 'HH' THEN RETURN 24;
	  WHEN v_INTERVAL_ABBREVIATION = '' THEN RETURN 24;
	  WHEN v_INTERVAL_ABBREVIATION IS NULL THEN RETURN 24;
	  WHEN v_INTERVAL_ABBREVIATION = 'MI5' THEN RETURN 288;
	  WHEN v_INTERVAL_ABBREVIATION = 'MI10' THEN RETURN 144;
	  WHEN v_INTERVAL_ABBREVIATION = 'MI20' THEN RETURN 72;
   ELSE
      ERRS.RAISE(MSGCODES.C_ERR_ARGUMENT);
   END CASE;

END GET_NUM_OF_SUBDAILY_INTERVALS;
-------------------------------------------------------------------------------
FUNCTION INTERVAL_CACHE_GRAN
	(
	p_UOM IN VARCHAR2
	) RETURN PLS_INTEGER IS
v_KEY VARCHAR2(16) := UPPER(p_UOM);
BEGIN
	IF g_INTERVAL_CACHE_GRAN.EXISTS(v_KEY) THEN
		RETURN g_INTERVAL_CACHE_GRAN(v_KEY);
	ELSE
		RETURN NULL;
	END IF;
END INTERVAL_CACHE_GRAN;
-------------------------------------------------------------------------------
PROCEDURE UPDATE_INTERVAL_CACHE_GRAN
	(
	p_UOM IN VARCHAR2,
	p_INTERVAL_ORD IN PLS_INTEGER
	) AS
v_KEY VARCHAR2(16) := UPPER(p_UOM);
BEGIN
	IF NOT g_INTERVAL_CACHE_GRAN.EXISTS(v_KEY) THEN
		g_INTERVAL_CACHE_GRAN(v_KEY) := p_INTERVAL_ORD;
	ELSIF g_INTERVAL_CACHE_GRAN(v_KEY) IS NULL OR g_INTERVAL_CACHE_GRAN(v_KEY) > p_INTERVAL_ORD THEN
		g_INTERVAL_CACHE_GRAN(v_KEY) := p_INTERVAL_ORD;
	END IF;
END UPDATE_INTERVAL_CACHE_GRAN;
-------------------------------------------------------------------------------
PROCEDURE TRACE_CACHE IS

v_ID	PLS_INTEGER;
v_KEY	VARCHAR2(40);
v_ROW1	VARCHAR2(4000);
v_ROW2	VARCHAR2(4000);

	-- for printing fixed width columns in trace output
	PROCEDURE PRINT_COLUMN(p_VAL IN VARCHAR2, p_LEN IN PLS_INTEGER, p_ROW IN OUT NOCOPY VARCHAR2) IS
	v_LEN PLS_INTEGER;
	BEGIN
		p_ROW := p_ROW||p_VAL;
		v_LEN := p_LEN - LENGTH(p_VAL);
		IF v_LEN > 0 THEN
			FOR I IN 1..v_LEN LOOP
				p_ROW := p_ROW||' ';
			END LOOP;
		END IF;
	END PRINT_COLUMN;
BEGIN

	LOGS.LOG_DEBUG_MORE_DETAIL('========================');
	LOGS.LOG_DEBUG_MORE_DETAIL('Cache object info');
	LOGS.LOG_DEBUG_MORE_DETAIL('========================');
	v_ROW1 := NULL;
	v_ROW2 := NULL;
	-- dump the package-var structure
	PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN 'Meter ID' ELSE 'Transaction ID' END, 16, v_ROW1);
	PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN '--------' ELSE '--------------' END, 16, v_ROW2);
	IF g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN
		PRINT_COLUMN('Meter Type', 16, v_ROW1);
		PRINT_COLUMN('----------', 16, v_ROW2);
	END IF;
	PRINT_COLUMN('Interval', 16, v_ROW1);
	PRINT_COLUMN('--------', 16, v_ROW2);
	PRINT_COLUMN('Interval Ord', 16, v_ROW1);
	PRINT_COLUMN('------------', 16, v_ROW2);
	LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
	LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW2);

	v_ID := g_OBJECT_INFO_CACHE.FIRST;
	WHILE g_OBJECT_INFO_CACHE.EXISTS(v_ID) LOOP
		v_ROW1 := NULL;

		PRINT_COLUMN(v_ID, 16, v_ROW1); -- Meter ID / Transaction ID
		IF g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN
			PRINT_COLUMN(g_OBJECT_INFO_CACHE(v_ID).METER_TYPE, 16, v_ROW1); -- Meter Type
		END IF;
		PRINT_COLUMN(g_OBJECT_INFO_CACHE(v_ID).INTERVAL, 16, v_ROW1); -- Interval
		PRINT_COLUMN(g_OBJECT_INFO_CACHE(v_ID).INTERVAL_ORD, 16, v_ROW1); -- Interval Ord

		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
		v_ID := g_OBJECT_INFO_CACHE.NEXT(v_ID);
	END LOOP;

	LOGS.LOG_DEBUG_MORE_DETAIL('========================');
	LOGS.LOG_DEBUG_MORE_DETAIL('Interval cache');
	LOGS.LOG_DEBUG_MORE_DETAIL('========================');
	-- Cache granularity info
	IF g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN
		-- Account cache can have different granularity by UOM
		v_ROW1 := NULL;
		v_ROW2 := NULL;
		PRINT_COLUMN('UOM', 16, v_ROW1);
		PRINT_COLUMN('---', 16, v_ROW2);
		PRINT_COLUMN('Granularity', 16, v_ROW1);
		PRINT_COLUMN('-----------', 16, v_ROW2);
		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW2);

		v_KEY := g_INTERVAL_CACHE_GRAN.FIRST;
		WHILE g_INTERVAL_CACHE_GRAN.EXISTS(v_KEY) LOOP
			v_ROW1 := NULL;

			PRINT_COLUMN(v_KEY, 16, v_ROW1); -- UOM
			PRINT_COLUMN(g_INTERVAL_CACHE_GRAN(v_KEY), 16, v_ROW1); -- Granularity

			LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
			v_KEY := g_INTERVAL_CACHE_GRAN.NEXT(v_KEY);
		END LOOP;
	ELSE
		-- POD cache just has a single granularity
		IF g_INTERVAL_CACHE_GRAN.EXISTS(c_POD_CACHE_GRAN_KEY) THEN
			LOGS.LOG_DEBUG_MORE_DETAIL('Cache granularity: '||g_INTERVAL_CACHE_GRAN(c_POD_CACHE_GRAN_KEY));
		ELSE
			LOGS.LOG_DEBUG_MORE_DETAIL('Cache granularity: '); -- NULL granularity
		END IF;
	END IF;
	-- dump the package-var structure
	v_ROW1 := NULL;
	v_ROW2 := NULL;
	PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN 'Service ID' ELSE 'Transaction ID' END||': UOM : Date(YYYYMMDD)', 40, v_ROW1);
	PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN '----------' ELSE '--------------' END||'----------------------', 40, v_ROW2);
	PRINT_COLUMN('Template ID', 16, v_ROW1);
	PRINT_COLUMN('----------', 16, v_ROW2);
	PRINT_COLUMN('Status', 16, v_ROW1);
	PRINT_COLUMN('------', 16, v_ROW2);
	LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
	LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW2);

	v_KEY := g_INTERVAL_CACHE_DEF.FIRST;
	WHILE g_INTERVAL_CACHE_DEF.EXISTS(v_KEY) LOOP
		v_ROW1 := NULL;

		PRINT_COLUMN(v_KEY, 40, v_ROW1); -- Service ID / Transaction ID : UOM : Date

		v_ID := g_INTERVAL_CACHE_DEF(v_KEY).FIRST;
		WHILE g_INTERVAL_CACHE_DEF(v_KEY).EXISTS(v_ID) LOOP

			PRINT_COLUMN(v_ID, 16, v_ROW1); -- Template ID
			PRINT_COLUMN(g_INTERVAL_CACHE_DEF(v_KEY)(v_ID), 16, v_ROW1); -- Status

			v_ID := g_INTERVAL_CACHE_DEF(v_KEY).NEXT(v_ID);
		END LOOP;
		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
		v_KEY := g_INTERVAL_CACHE_DEF.NEXT(v_KEY);
	END LOOP;
	-- now dump the temp table contents
	v_ROW1 := NULL;
	v_ROW2 := NULL;
	PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN 'Service ID' ELSE 'Transaction ID' END, 16, v_ROW1);
	PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN '----------' ELSE '--------------' END, 16, v_ROW2);
	PRINT_COLUMN('UOM', 16, v_ROW1);
	PRINT_COLUMN('---', 16, v_ROW2);
	PRINT_COLUMN('Template ID', 16, v_ROW1);
	PRINT_COLUMN('----------', 16, v_ROW2);
	PRINT_COLUMN('Date', 20, v_ROW1);
	PRINT_COLUMN('----', 20, v_ROW2);
	PRINT_COLUMN('Period ID', 16, v_ROW1);
	PRINT_COLUMN('---------', 16, v_ROW2);
	PRINT_COLUMN('Operation Code', 16, v_ROW1);
	PRINT_COLUMN('--------------', 16, v_ROW2);
	PRINT_COLUMN('Value', 16, v_ROW1);
	PRINT_COLUMN('-----', 16, v_ROW2);
	PRINT_COLUMN('Losses', 16, v_ROW1);
	PRINT_COLUMN('------', 16, v_ROW2);
	PRINT_COLUMN('UFE', 16, v_ROW1);
	PRINT_COLUMN('---', 16, v_ROW2);
	LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
	LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW2);

	FOR v_REC IN (SELECT * FROM DETERMINANT_CACHE_INTERVAL ORDER BY OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, OPERATION_CODE) LOOP
		v_ROW1 := NULL;

		PRINT_COLUMN(v_REC.OBJECT_ID, 16, v_ROW1); -- Meter ID / Transaction ID
		PRINT_COLUMN(v_REC.UOM, 16, v_ROW1); -- UOM
		PRINT_COLUMN(v_REC.TEMPLATE_ID, 16, v_ROW1); -- Template ID
		-- show time if cache granularity is sub-daily
		PRINT_COLUMN(CASE WHEN INTERVAL_CACHE_GRAN(v_REC.UOM) < DATE_UTIL.c_ORD_DAY THEN TEXT_UTIL.TO_CHAR_TIME(v_REC.LOAD_DATE) ELSE TEXT_UTIL.TO_CHAR_DATE(v_REC.LOAD_DATE) END, 20, v_ROW1); -- Date
		PRINT_COLUMN(v_REC.PERIOD_ID, 16, v_ROW1); -- Period ID
		PRINT_COLUMN(NVL(v_REC.OPERATION_CODE, 'NULL'), 16, v_ROW1);
		PRINT_COLUMN(v_REC.LOAD_VAL, 16, v_ROW1); -- Value
		PRINT_COLUMN(v_REC.LOSS_VAL, 16, v_ROW1); -- Losses
		PRINT_COLUMN(v_REC.UFE_VAL, 16, v_ROW1); -- UFE

		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
	END LOOP;

	-- only account cache uses period cache table
	IF g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN
		LOGS.LOG_DEBUG_MORE_DETAIL('========================');
		LOGS.LOG_DEBUG_MORE_DETAIL('Period cache');
		LOGS.LOG_DEBUG_MORE_DETAIL('========================');
		-- dump the package-var structure
		v_ROW1 := NULL;
		v_ROW2 := NULL;
		PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN 'Meter ID' ELSE 'Transaction ID' END||': UOM : Template ID', 40, v_ROW1);
		PRINT_COLUMN(CASE WHEN g_CACHE_TYPE = c_CACHE_TYPE_ACCOUNT THEN '--------' ELSE '--------------' END||'-------------------', 40, v_ROW2);
		PRINT_COLUMN('Begin Date', 16, v_ROW1);
		PRINT_COLUMN('----------', 16, v_ROW2);
		PRINT_COLUMN('End Date', 16, v_ROW1);
		PRINT_COLUMN('---------', 16, v_ROW2);
		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW2);

		v_KEY := g_PERIOD_CACHE_DEF.FIRST;
		WHILE g_PERIOD_CACHE_DEF.EXISTS(v_KEY) LOOP
			v_ROW1 := NULL;

			PRINT_COLUMN(v_KEY, 40, v_ROW1); -- Service ID : UOM : Template ID
			PRINT_COLUMN(TEXT_UTIL.TO_CHAR_DATE(g_PERIOD_CACHE_DEF(v_KEY).BEGIN_DATE), 16, v_ROW1); -- Begin Date
			PRINT_COLUMN(TEXT_UTIL.TO_CHAR_DATE(g_PERIOD_CACHE_DEF(v_KEY).END_DATE), 16, v_ROW1); -- End Date

			LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
			v_KEY := g_PERIOD_CACHE_DEF.NEXT(v_KEY);
		END LOOP;
		-- now dump the temp table contents
		v_ROW1 := NULL;
		v_ROW2 := NULL;
		PRINT_COLUMN('Meter ID', 16, v_ROW1);
		PRINT_COLUMN('--------', 16, v_ROW2);
		PRINT_COLUMN('UOM', 16, v_ROW1);
		PRINT_COLUMN('---', 16, v_ROW2);
		PRINT_COLUMN('Template ID', 16, v_ROW1);
		PRINT_COLUMN('----------', 16, v_ROW2);
		PRINT_COLUMN('Period ID', 16, v_ROW1);
		PRINT_COLUMN('---------', 16, v_ROW2);
		PRINT_COLUMN('Begin Date', 16, v_ROW1);
		PRINT_COLUMN('----------', 16, v_ROW2);
		PRINT_COLUMN('End Date', 16, v_ROW1);
		PRINT_COLUMN('--------', 16, v_ROW2);
		PRINT_COLUMN('Energy', 16, v_ROW1);
		PRINT_COLUMN('------', 16, v_ROW2);
		PRINT_COLUMN('Demand', 16, v_ROW1);
		PRINT_COLUMN('------', 16, v_ROW2);
		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
		LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW2);

		FOR v_REC IN (SELECT * FROM DETERMINANT_CACHE_PERIOD ORDER BY OBJECT_ID, UOM, TEMPLATE_ID, PERIOD_ID, BEGIN_DATE) LOOP
			v_ROW1 := NULL;

			PRINT_COLUMN(v_REC.OBJECT_ID, 16, v_ROW1); -- Meter ID
			PRINT_COLUMN(v_REC.UOM, 16, v_ROW1); -- UOM
			PRINT_COLUMN(v_REC.TEMPLATE_ID, 16, v_ROW1); -- Template ID
			PRINT_COLUMN(v_REC.PERIOD_ID, 16, v_ROW1); -- Period ID
			PRINT_COLUMN(TEXT_UTIL.TO_CHAR_DATE(v_REC.BEGIN_DATE), 16, v_ROW1); -- Begin Date
			PRINT_COLUMN(TEXT_UTIL.TO_CHAR_DATE(v_REC.END_DATE), 16, v_ROW1); -- End Date
			PRINT_COLUMN(v_REC.ENERGY, 16, v_ROW1); -- Energy
			PRINT_COLUMN(v_REC.DEMAND, 16, v_ROW1); -- Demand

			LOGS.LOG_DEBUG_MORE_DETAIL(v_ROW1);
		END LOOP;
	END IF;

END TRACE_CACHE;
-------------------------------------------------------------------------------
FUNCTION IS_SUB_DAILY
	(
	p_INTERVAL IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	-- this is likely to be called repeatedly, so re-use last value if it's the same (which it typically will be)
	IF g_PREV_INTERVAL IS NULL OR p_INTERVAL <> g_PREV_INTERVAL THEN
		g_PREV_INTERVAL := p_INTERVAL;
		-- 'Meter Period' is only applicable for billing/pricing so is not supported/known by DATE_UTIL APIs
		g_PREV_SUB_DAILY := p_INTERVAL <> 'Meter Period' AND DATE_UTIL.IS_SUB_DAILY(p_INTERVAL);
	END IF;
	RETURN g_PREV_SUB_DAILY;
END IS_SUB_DAILY;
-------------------------------------------------------------------------------
FUNCTION GET_NUMBER_OF_INTERVALS
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN PLS_INTEGER IS
BEGIN
	IF p_INTERVAL = 'Meter Period' THEN
		RETURN 1;
	ELSIF IS_SUB_DAILY(p_INTERVAL) THEN
		-- Like determinant accessor methods, a sub-daily interval means that dates represent
		-- proper interval in CUT time
		RETURN DATE_UTIL.GET_INTERVAL_DIVISOR('Day', p_INTERVAL) * (p_END_DATE - p_BEGIN_DATE + 1/86400);
	ELSE
		CASE p_INTERVAL
		WHEN 'Day' THEN
			RETURN p_END_DATE - p_BEGIN_DATE + 1;
		WHEN 'Week' THEN
			RETURN (p_END_DATE - p_BEGIN_DATE + 1) / 7;
		WHEN 'Month' THEN
			RETURN MONTHS_BETWEEN(p_BEGIN_DATE, p_END_DATE+1);
		WHEN 'Quarter' THEN
			RETURN MONTHS_BETWEEN(p_BEGIN_DATE, p_END_DATE+1) / 3;
		WHEN 'Year' THEN
			RETURN MONTHS_BETWEEN(p_BEGIN_DATE, p_END_DATE+1) / 12;
		END CASE;
	END IF;

END GET_NUMBER_OF_INTERVALS;
-------------------------------------------------------------------------------
PROCEDURE DETERMINANT_ACCESSOR_DATES
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_DET_BEGIN_DATE OUT DATE,
	p_DET_END_DATE OUT DATE
	) AS
BEGIN
	IF IS_SUB_DAILY(p_INTERVAL) THEN
		UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, p_DET_BEGIN_DATE, p_DET_END_DATE);
	ELSE
		p_DET_BEGIN_DATE := p_BEGIN_DATE;
		p_DET_END_DATE := p_END_DATE;
	END IF;
END DETERMINANT_ACCESSOR_DATES;
-------------------------------------------------------------------------------
PROCEDURE INTERVAL_QUERY_DATE_RANGE
	(
	p_UOM IN VARCHAR2,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_QUERY_BEGIN_DATE OUT DATE,
	p_QUERY_END_DATE OUT DATE
	) AS
BEGIN
	-- cache granularity is sub-daily but specified interval is not? then
	-- convert incoming dates to CUT dates
	IF INTERVAL_CACHE_GRAN(p_UOM) < DATE_UTIL.c_ORD_DAY AND NOT IS_SUB_DAILY(p_INTERVAL) THEN
		UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE,
							p_TIME_ZONE, p_QUERY_BEGIN_DATE, p_QUERY_END_DATE);

	-- vice versa: if cache granularity is daily or greater but specified interval
	-- is sbu-daily, convert *from* CUT dates
	ELSIF INTERVAL_CACHE_GRAN(p_UOM) >= DATE_UTIL.c_ORD_DAY AND IS_SUB_DAILY(p_INTERVAL) THEN
		p_QUERY_BEGIN_DATE := TRUNC(FROM_CUT(p_BEGIN_DATE, p_TIME_ZONE)-1/86400);
		p_QUERY_END_DATE := TRUNC(FROM_CUT(p_END_DATE, p_TIME_ZONE)-1/86400);

	-- Else, intervals are compatible - no conversions needed
	ELSE
		p_QUERY_BEGIN_DATE := p_BEGIN_DATE;
		p_QUERY_END_DATE := p_END_DATE;
	END IF;
END INTERVAL_QUERY_DATE_RANGE;
-------------------------------------------------------------------------------
PROCEDURE DAY_RANGE
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DAY OUT DATE,
	p_END_DAY OUT DATE
	) AS
BEGIN
	IF IS_SUB_DAILY(p_INTERVAL) THEN
		p_BEGIN_DAY := TRUNC(FROM_CUT(p_BEGIN_DATE, p_TIME_ZONE)-1/86400);
		p_END_DAY := TRUNC(FROM_CUT(p_END_DATE, p_TIME_ZONE)-1/86400);
	ELSE
		p_BEGIN_DAY := p_BEGIN_DATE;
		p_END_DAY := p_END_DATE;
	END IF;
END DAY_RANGE;
-------------------------------------------------------------------------------
FUNCTION INTERVAL_CACHE_KEY
	(
	p_METER_ID IN NUMBER,
	p_UOM IN VARCHAR2,
	p_DATE IN DATE,
	p_OPERATION_CODE IN VARCHAR2 := NULL
	) RETURN VARCHAR2 IS
BEGIN
	RETURN p_METER_ID||':'||p_UOM||':'||TO_CHAR(p_DATE, 'YYYYMMDD')||':'||p_OPERATION_CODE;
END INTERVAL_CACHE_KEY;
-------------------------------------------------------------------------------
FUNCTION PERIOD_CACHE_KEY
	(
	p_METER_ID IN NUMBER,
	p_UOM IN VARCHAR2,
	p_TEMPLATE_ID IN NUMBER
	) RETURN VARCHAR2 IS
BEGIN
	RETURN p_METER_ID||':'||p_UOM||':'||p_TEMPLATE_ID;
END PERIOD_CACHE_KEY;
-------------------------------------------------------------------------------
FUNCTION COPY_INTERVAL_CACHE
	(
	p_METER_ID IN NUMBER,
	p_UOM IN VARCHAR2,
	p_FROM_TEMPLATE_ID IN NUMBER,
	p_TO_TEMPLATE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_OPERATION_CODE IN VARCHAR2 := NULL
	) RETURN PLS_INTEGER IS
-- All DML (to cache tables) is done in autonomous transaction since this could be called
-- from SQL (like from a formula)
PRAGMA AUTONOMOUS_TRANSACTION;
v_RET	PLS_INTEGER;
v_EDC_HOLIDAY_SET_ID NUMBER := NVL(g_OBJECT_INFO_CACHE(p_METER_ID).EDC_HOLIDAY_SET_ID,c_ALL_HOLIDAY_SET);
BEGIN
  IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_MORE_DETAIL('Copying interval data for Meter ID = '||p_METER_ID||', UOM = '||p_UOM||', '
								||TEXT_UTIL.TO_CHAR_TIME(p_BEGIN_DATE)||' -> '||TEXT_UTIL.TO_CHAR_TIME(p_END_DATE)
								||' '||p_TIME_ZONE||' from '||TEXT_UTIL.TO_CHAR_ENTITY(p_FROM_TEMPLATE_ID,EC.ED_TEMPLATE)
								||' to '||TEXT_UTIL.TO_CHAR_ENTITY(p_FROM_TEMPLATE_ID,EC.ED_TEMPLATE));
	END IF;

	IF p_TO_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED THEN
		-- no need to identify periods
		INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL)
		SELECT p_METER_ID, p_UOM, p_TO_TEMPLATE_ID, LOAD_DATE, NULL, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL
		FROM DETERMINANT_CACHE_INTERVAL
		WHERE OBJECT_ID = p_METER_ID
			AND UOM = p_UOM
			AND TEMPLATE_ID = p_FROM_TEMPLATE_ID
			AND LOAD_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
			AND ((p_OPERATION_CODE IS NULL AND OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND OPERATION_CODE = p_OPERATION_CODE));

		v_RET := SQL%ROWCOUNT;
		COMMIT;
		RETURN v_RET;
	ELSE
		-- use TEMPLATE_DATES tables/structures to re-identify periods for this day
		INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL)
		SELECT p_METER_ID, p_UOM, p_TO_TEMPLATE_ID, DCI.LOAD_DATE, TDP.PERIOD_ID, OPERATION_CODE, DCI.LOAD_VAL, DCI.LOSS_VAL, DCI.UFE_VAL
		FROM DETERMINANT_CACHE_INTERVAL DCI,
			TEMPLATE_DATES TD,
			TEMPLATE_DAY_TYPE_PERIOD TDP
		WHERE DCI.OBJECT_ID = p_METER_ID
			AND DCI.UOM = p_UOM
			AND DCI.TEMPLATE_ID = p_FROM_TEMPLATE_ID
			AND DCI.LOAD_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
			AND TD.TIME_ZONE = p_TIME_ZONE
			AND TD.TEMPLATE_ID = p_TO_TEMPLATE_ID
			AND TD.HOLIDAY_SET_ID = v_EDC_HOLIDAY_SET_ID
			AND TD.CUT_BEGIN_DATE < DCI.LOAD_DATE
			AND TD.CUT_END_DATE >= DCI.LOAD_DATE
			AND TDP.DAY_TYPE_ID = TD.DAY_TYPE_ID
			AND TDP.TIME_STAMP = DCI.LOAD_DATE - TD.CUT_BEGIN_DATE
			AND ((p_OPERATION_CODE IS NULL AND OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND OPERATION_CODE = p_OPERATION_CODE));

		v_RET := SQL%ROWCOUNT;
		COMMIT;
		RETURN v_RET;
	END IF;
END COPY_INTERVAL_CACHE;
-------------------------------------------------------------------------------
FUNCTION GET_INTVL_DETERMINANT_STATUS
	(
	p_METER_ID			IN NUMBER,
	p_SERVICE_INTERVAL	IN VARCHAR2,
	p_UOM				IN VARCHAR2,
	p_TEMPLATE_ID		IN VARCHAR2,
	p_BEGIN_DATE		IN DATE,
	p_END_DATE			IN DATE,
	p_TIME_ZONE			IN VARCHAR2,
	p_OPERATION_CODE 	IN VARCHAR2 := NULL
	) RETURN PLS_INTEGER IS
v_DATE 			DATE;
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_EXPECTED		NUMBER;
v_FOUND			NUMBER;
v_KEY			VARCHAR2(40);
v_RET			PLS_INTEGER;
v_STAT			PLS_INTEGER;
BEGIN
	v_RET := NULL;
	-- Check each day in the specified date range
	v_DATE := p_BEGIN_DATE;
	WHILE v_DATE <= p_END_DATE LOOP
		v_KEY := INTERVAL_CACHE_KEY(p_METER_ID, p_UOM, v_DATE, p_OPERATION_CODE);
		v_STAT := g_INTERVAL_CACHE_DEF(v_KEY)(p_TEMPLATE_ID);
		IF v_STAT IS NULL THEN
			-- get the status of the cache for this day if it isn't stored already
			DETERMINANT_ACCESSOR_DATES(p_SERVICE_INTERVAL, v_DATE, v_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
			v_EXPECTED := GET_NUMBER_OF_INTERVALS(p_SERVICE_INTERVAL, v_BEGIN_DATE, v_END_DATE);
			-- see how many entries we have
			SELECT COUNT(1)
			INTO v_FOUND
			FROM DETERMINANT_CACHE_INTERVAL
			WHERE OBJECT_ID = p_METER_ID
				AND UOM = p_UOM
				AND TEMPLATE_ID = p_TEMPLATE_ID
				AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
				AND (p_OPERATION_CODE IS NULL AND OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND OPERATION_CODE = p_OPERATION_CODE)
                AND ROWNUM <= v_EXPECTED;
			-- interpret results
			IF NVL(v_FOUND,0) = 0 THEN
				v_STAT := c_STATUS_MISSING;
			ELSIF v_FOUND < v_EXPECTED THEN
				v_STAT := c_STATUS_PARTIAL;
			ELSE
				v_STAT := c_STATUS_OK;
			END IF;
			g_INTERVAL_CACHE_DEF(v_KEY)(p_TEMPLATE_ID) := v_STAT;
            IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
    		  LOGS.LOG_DEBUG_DETAIL('p_SERVICE_INTERVAL = '|| p_SERVICE_INTERVAL);
              LOGS.LOG_DEBUG_DETAIL('v_EXPECTED = '|| to_char(v_EXPECTED));
            END IF;
		END IF;
		-- combine status for this day with return value
		IF v_RET IS NULL THEN
			v_RET := v_STAT;
		ELSIF v_RET <> c_STATUS_PARTIAL AND v_RET <> v_STAT THEN
			v_RET := c_STATUS_PARTIAL;
		END IF;

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Interval cache for '||TEXT_UTIL.TO_CHAR_DATE(v_DATE)
										||' ('||TEXT_UTIL.TO_CHAR_TIME(v_BEGIN_DATE)||'  -> '||TEXT_UTIL.TO_CHAR_TIME(v_END_DATE)||')'
										||' status = '||v_STAT||' (combined status so far = '||v_RET||')');
		END IF;

		-- on to the next day
		v_DATE := v_DATE+1;
	END LOOP;
	-- Done!
	RETURN v_RET;
END GET_INTVL_DETERMINANT_STATUS;
-------------------------------------------------------------------------------
PROCEDURE CLEAR_CACHE IS
-- All DML (to cache tables) is done in autonomous transaction since this could be called
-- from SQL (like from a formula)
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_MORE_DETAIL('Clearing retail determinants caches...');
	END IF;
	-- clear package variable structures and temp tables
	g_OBJECT_INFO_CACHE.DELETE;
	DELETE DETERMINANT_CACHE_PERIOD;
	g_PERIOD_CACHE_DEF.DELETE;
	DELETE DETERMINANT_CACHE_INTERVAL;
	g_INTERVAL_CACHE_DEF.DELETE;
	g_INTERVAL_CACHE_GRAN.DELETE;
	g_PREV_ACTIVE_BEGIN_DATE := NULL;
	g_PREV_ACTIVE_END_DATE := NULL;
	IF g_PREV_ACTIVE_SVC_WORK_ID IS NOT NULL THEN
		UT.PURGE_RTO_WORK(g_PREV_ACTIVE_SVC_WORK_ID);
	END IF;
	g_PREV_ACTIVE_TXNS := NULL;
	COMMIT;
END CLEAR_CACHE;
-------------------------------------------------------------------------------
FUNCTION GET_ACCT_DETERMINANT_ACCESSOR
	(
	p_ACCOUNT_ID			IN NUMBER,
	p_SERVICE_LOCATION_ID	IN NUMBER,
	p_METER_ID				IN NUMBER,
	p_AGGREGATE_ID			IN NUMBER,
	p_SERVICE_CODE			IN CHAR,
	p_SCENARIO_ID			IN NUMBER,
	p_TIME_ZONE				IN VARCHAR2,
    p_ESP_ID                IN NUMBER := NULL
	) RETURN ACCOUNT_DETERMINANT_ACCESSOR IS
BEGIN

	RETURN ACCOUNT_DETERMINANT_ACCESSOR(
						p_ACCOUNT_ID,
						p_SERVICE_LOCATION_ID,
						p_METER_ID,
						p_AGGREGATE_ID,
						p_SERVICE_CODE,
						p_TIME_ZONE,
						p_SCENARIO_ID,
                        p_ESP_ID
						);

END GET_ACCT_DETERMINANT_ACCESSOR;
-------------------------------------------------------------------------------
FUNCTION GET_ACCT_DETERMINANT_ACCESSOR
	(
	p_ACCOUNT_SERVICE_ID	IN NUMBER,
	p_SERVICE_CODE			IN CHAR,
	p_SCENARIO_ID			IN NUMBER,
	p_TIME_ZONE				IN VARCHAR2
	) RETURN ACCOUNT_DETERMINANT_ACCESSOR IS

v_ACCOUNT_ID			NUMBER(9);
v_SERVICE_LOCATION_ID	NUMBER(9);
v_METER_ID				NUMBER(9);
v_AGGREGATE_ID			NUMBER(9);

BEGIN

	SELECT ACCOUNT_ID, SERVICE_LOCATION_ID, METER_ID, AGGREGATE_ID
	INTO v_ACCOUNT_ID, v_SERVICE_LOCATION_ID, v_METER_ID, v_AGGREGATE_ID
	FROM ACCOUNT_SERVICE
	WHERE ACCOUNT_SERVICE_ID = p_ACCOUNT_SERVICE_ID;

	RETURN GET_ACCT_DETERMINANT_ACCESSOR(
						v_ACCOUNT_ID,
						v_SERVICE_LOCATION_ID,
						v_METER_ID,
						v_AGGREGATE_ID,
						p_SERVICE_CODE,
						p_SCENARIO_ID,
						p_TIME_ZONE,
                        NULL
						);

END GET_ACCT_DETERMINANT_ACCESSOR;
-------------------------------------------------------------------------------
PROCEDURE INIT
	(
	p_ACCESSOR IN ACCOUNT_DETERMINANT_ACCESSOR
	) AS

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
	IF g_CACHE_TYPE IS NULL OR g_CACHE_TYPE <> c_CACHE_TYPE_ACCOUNT OR
		g_LAST_ACCOUNT_ID <> p_ACCESSOR.ACCOUNT_ID OR g_LAST_SVC_LOC_ID <> p_ACCESSOR.SERVICE_LOCATION_ID OR
		g_LAST_METER_ID <> p_ACCESSOR.METER_ID OR g_LAST_AGGREGATE_ID <> p_ACCESSOR.AGGREGATE_ID OR
		g_LAST_SCENARIO_ID <> p_ACCESSOR.SCENARIO_ID OR g_LAST_SERVICE_CODE <> p_ACCESSOR.SERVICE_CODE OR
		g_LAST_TIME_ZONE <> p_ACCESSOR.TIME_ZONE THEN

		-- Different accessor than last used? clear the cache and reset package variables
		g_CACHE_TYPE := c_CACHE_TYPE_ACCOUNT;

		CLEAR_CACHE;

		g_LAST_ACCOUNT_ID := p_ACCESSOR.ACCOUNT_ID;
		g_LAST_SVC_LOC_ID := p_ACCESSOR.SERVICE_LOCATION_ID;
		g_LAST_METER_ID := p_ACCESSOR.METER_ID;
		g_LAST_AGGREGATE_ID := p_ACCESSOR.AGGREGATE_ID;
		g_LAST_SCENARIO_ID := p_ACCESSOR.SCENARIO_ID;
		g_LAST_SERVICE_CODE := p_ACCESSOR.SERVICE_CODE;
		g_LAST_TIME_ZONE := p_ACCESSOR.TIME_ZONE;
		IF g_LAST_SVC_WORK_ID IS NULL THEN
			UT.GET_RTO_WORK_ID(g_LAST_SVC_WORK_ID);
		ELSE
			UT.PURGE_RTO_WORK(g_LAST_SVC_WORK_ID);
		END IF;
		-- save IDs to work temp table
		INSERT INTO RTO_WORK (WORK_ID, WORK_XID)
		SELECT g_LAST_SVC_WORK_ID, IDs.COLUMN_VALUE
		FROM TABLE(CAST(p_ACCESSOR.SERVICE_IDs as NUMBER_COLLECTION)) IDs;

		g_LAST_METER_TYPE_EFF_DATE := NULL;

		IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_MORE_DETAIL('Initializing for account accessor...');
			LOGS.LOG_DEBUG_MORE_DETAIL('  Account ID = '||p_ACCESSOR.ACCOUNT_ID||' ('||TEXT_UTIL.TO_CHAR_ENTITY(p_ACCESSOR.ACCOUNT_ID,EC.ED_ACCOUNT));
			LOGS.LOG_DEBUG_MORE_DETAIL('  Service Location ID = '||p_ACCESSOR.SERVICE_LOCATION_ID||' ('||TEXT_UTIL.TO_CHAR_ENTITY(p_ACCESSOR.SERVICE_LOCATION_ID,EC.ED_SERVICE_LOCATION));
			LOGS.LOG_DEBUG_MORE_DETAIL('  Meter ID = '||p_ACCESSOR.METER_ID||' ('||TEXT_UTIL.TO_CHAR_ENTITY(p_ACCESSOR.METER_ID,EC.ED_METER));
			LOGS.LOG_DEBUG_MORE_DETAIL('  Aggregate ID = '||p_ACCESSOR.AGGREGATE_ID);
			LOGS.LOG_DEBUG_MORE_DETAIL('  Service Code = '||p_ACCESSOR.SERVICE_CODE);
			LOGS.LOG_DEBUG_MORE_DETAIL('  Scenario ID = '||p_ACCESSOR.SCENARIO_ID||' ('||TEXT_UTIL.TO_CHAR_ENTITY(p_ACCESSOR.SCENARIO_ID,EC.ED_SCENARIO));
			LOGS.LOG_DEBUG_MORE_DETAIL('  Time Zone = '||p_ACCESSOR.TIME_ZONE);
		END IF;
	END IF;

	COMMIT;
END INIT;
-------------------------------------------------------------------------------
FUNCTION GET_METER_TYPE_TEMPLATE_ID
	(
	p_ACCESSOR IN ACCOUNT_DETERMINANT_ACCESSOR,
	p_DATE IN DATE
	) RETURN NUMBER IS

v_ACCT_MODEL	ACCOUNT.ACCOUNT_MODEL_OPTION%TYPE;
v_TEMPLATE_ID1	NUMBER(9);
v_TEMPLATE_ID2	NUMBER(9);
v_COUNT_NO_TOU	NUMBER(9);

BEGIN

	INIT(p_ACCESSOR);

	-- If stored value is for wrong effective date, then query for the effective template ID
	IF g_LAST_METER_TYPE_EFF_DATE IS NULL OR g_LAST_METER_TYPE_EFF_DATE <> p_DATE THEN

		g_LAST_METER_TYPE_EFF_DATE := p_DATE;

		-- What is account's model?
		SELECT ACCOUNT_MODEL_OPTION
		INTO v_ACCT_MODEL
		FROM ACCOUNT
		WHERE ACCOUNT_ID = g_LAST_ACCOUNT_ID;

		IF SUBSTR(v_ACCT_MODEL,1,1) = 'M' THEN
			IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
				LOGS.LOG_DEBUG_DETAIL('Determine TOU usage factor template IDs for meter-modelled services...');
			END IF;
			-- Meter model
			SELECT MIN(TEMPLATE_ID), MAX(TEMPLATE_ID), SUM(CASE WHEN TEMPLATE_ID IS NULL THEN 1 ELSE 0 END)
			INTO v_TEMPLATE_ID1, v_TEMPLATE_ID2, v_COUNT_NO_TOU
			FROM (SELECT CASE WHEN M.USE_TOU_USAGE_FACTOR = 1 THEN TOU.TEMPLATE_ID ELSE NULL END as TEMPLATE_ID
					FROM ACCOUNT_SERVICE_LOCATION ASL,
						SERVICE_LOCATION_METER SLM,
						METER M,
						ACCOUNT_STATUS_NAME SN,
						METER_TOU_USAGE_FACTOR TOU
					WHERE ASL.ACCOUNT_ID = g_LAST_ACCOUNT_ID
						AND g_LAST_SVC_LOC_ID IN (ASL.SERVICE_LOCATION_ID, CONSTANTS.NOT_ASSIGNED)
						AND p_DATE BETWEEN ASL.BEGIN_DATE AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE)
						AND SLM.SERVICE_LOCATION_ID = ASL.SERVICE_LOCATION_ID
						AND g_LAST_METER_ID IN (SLM.METER_ID, CONSTANTS.NOT_ASSIGNED)
						AND p_DATE BETWEEN SLM.BEGIN_DATE AND NVL(SLM.END_DATE, CONSTANTS.HIGH_DATE)
						AND M.METER_ID = SLM.METER_ID
						AND SN.STATUS_NAME = M.METER_STATUS
						AND SN.IS_ACTIVE = 1 -- only consider active meters
						AND TOU.METER_ID(+) = M.METER_ID
						AND TOU.BEGIN_DATE(+) <= p_DATE
						AND NVL(TOU.END_DATE(+), CONSTANTS.HIGH_DATE) >= p_DATE);

			IF v_TEMPLATE_ID1 IS NULL THEN
				-- no TOU template IDs
				g_LAST_METER_TYPE_TEMPLATE_ID := NULL;
			ELSIF v_TEMPLATE_ID1 = v_TEMPLATE_ID2 AND v_COUNT_NO_TOU = 0 THEN
				-- all the same template ID
				g_LAST_METER_TYPE_TEMPLATE_ID := v_TEMPLATE_ID1;
			ELSE
				-- various template IDs
				g_LAST_METER_TYPE_TEMPLATE_ID := CONSTANTS.ALL_ID;
			END IF;

		ELSIF SUBSTR(v_ACCT_MODEL,1,2) = 'AC' THEN
			IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
				LOGS.LOG_DEBUG_DETAIL('Determine TOU usage factor template IDs for account-modelled services...');
			END IF;
			-- Account model
			SELECT CASE WHEN A.USE_TOU_USAGE_FACTOR = 1 THEN TOU.TEMPLATE_ID ELSE NULL END
			INTO g_LAST_METER_TYPE_TEMPLATE_ID
			FROM ACCOUNT A,
				ACCOUNT_TOU_USAGE_FACTOR TOU
			WHERE A.ACCOUNT_ID = g_LAST_ACCOUNT_ID
				AND TOU.ACCOUNT_ID(+) = A.ACCOUNT_ID
				AND TOU.BEGIN_DATE(+) <= p_DATE
				AND NVL(TOU.END_DATE(+), CONSTANTS.HIGH_DATE) >= p_DATE;

		ELSE
			IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
				LOGS.LOG_DEBUG_DETAIL('Cannot determine TOU usage factor template IDs for aggregate-modelled services!');
			END IF;
			-- Aggregate model accounts do not support TOU usage factors
			g_LAST_METER_TYPE_TEMPLATE_ID := NULL;

		END IF;

	END IF;

	-- Return stored value
	RETURN g_LAST_METER_TYPE_TEMPLATE_ID;

END GET_METER_TYPE_TEMPLATE_ID;
-------------------------------------------------------------------------------
PROCEDURE STORE_OBJECT_INFO_FOR_METER
	(
	p_METER_ID IN NUMBER,
	p_SERVICE_DATE IN DATE,
   p_EDC_HOLIDAY_SET_ID IN NUMBER
	) IS
v_ACCOUNT_ID	ACCOUNT.ACCOUNT_ID%TYPE;
v_MODEL_OPTION	CHAR(1);
BEGIN

	-- Determine meter type
	SELECT DISTINCT UPPER(SUBSTR(A.ACCOUNT_MODEL_OPTION,1,1)),
		CASE WHEN UPPER(SUBSTR(A.ACCOUNT_MODEL_OPTION,1,1)) = 'M' THEN
					M.METER_TYPE
				ELSE
					A.ACCOUNT_METER_TYPE
				END,
		ASVC.ACCOUNT_ID,
      p_EDC_HOLIDAY_SET_ID
	INTO v_MODEL_OPTION,
		g_OBJECT_INFO_CACHE(p_METER_ID).METER_TYPE,
		v_ACCOUNT_ID,
      g_OBJECT_INFO_CACHE(p_METER_ID).EDC_HOLIDAY_SET_ID
	FROM RTO_WORK R,
		SERVICE S,
		ACCOUNT_SERVICE ASVC,
		ACCOUNT A,
		METER M
	WHERE R.WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID
		AND R.WORK_XID = p_METER_ID
		AND S.SERVICE_ID = R.WORK_SEQ
		AND ASVC.ACCOUNT_SERVICE_ID = S.ACCOUNT_SERVICE_ID
		AND A.ACCOUNT_ID = ASVC.ACCOUNT_ID
		AND M.METER_ID(+) = ASVC.METER_ID;

	-- And interval
	IF v_MODEL_OPTION = 'M' THEN
		g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL := FP.GET_INTERVAL_FOR_METER(p_METER_ID, p_SERVICE_DATE);
	ELSE
		g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL := FP.GET_INTERVAL_FOR_ACCOUNT(v_ACCOUNT_ID, p_SERVICE_DATE);
	END IF;

	g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL_ORD := DATE_UTIL.INTERVAL_ORD(g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL);

END STORE_OBJECT_INFO_FOR_METER;
-------------------------------------------------------------------------------
FUNCTION GET_SVC_UOM_CONVERSION_FACTOR
	(
	p_UOM IN VARCHAR2,
	p_ALT_UOM IN VARCHAR2,
	p_INTERVAL_ORD IN NUMBER
	) RETURN NUMBER IS
v_RET		NUMBER := 1;
v_INTERVAL	VARCHAR2(16);
-- strip suffixes from UOMs
v_UOM		VARCHAR2(16) := CASE SUBSTR(p_UOM,LENGTH(p_UOM))
								WHEN '*' THEN SUBSTR(p_UOM,1,LENGTH(p_UOM)-1)
								ELSE p_UOM
								END;
v_ALT_UOM	VARCHAR2(16) := CASE SUBSTR(p_ALT_UOM,LENGTH(p_ALT_UOM))
								WHEN '*' THEN SUBSTR(p_ALT_UOM,1,LENGTH(p_ALT_UOM)-1)
								ELSE p_ALT_UOM
								END;
BEGIN
	v_INTERVAL := DATE_UTIL.INTERVAL_NAME(p_INTERVAL_ORD);
	-- NOTE: must be able to compute conversion factor for all UOM pairs supported
	-- by GET_SVC_ALTERNATE_UOM below
	IF v_UOM = v_ALT_UOM||'H' THEN
		v_RET := 1/ DATE_UTIL.GET_INTERVAL_DIVISOR('Hour', v_INTERVAL);
	ELSIF v_ALT_UOM = v_UOM||'H' THEN
		v_RET := DATE_UTIL.GET_INTERVAL_DIVISOR('Hour', v_INTERVAL);
	ELSIF SUBSTR(v_UOM,1,1) = 'M' AND v_ALT_UOM = 'K'||SUBSTR(v_UOM,2) THEN
		v_RET := 1/1000;
	ELSIF v_UOM = 'DTH' AND v_ALT_UOM = 'THM' THEN
		v_RET := 1/10;
	END IF;

	IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_MORE_DETAIL('Calculating '||p_UOM||' as '||p_ALT_UOM||' * '||v_RET);
	END IF;

	-- Done
	RETURN v_RET;
END GET_SVC_UOM_CONVERSION_FACTOR;
-------------------------------------------------------------------------------
FUNCTION GET_SVC_ALTERNATE_UOM
	(
	p_UOM IN VARCHAR2,
	p_IN_SEARCH_OF IN VARCHAR2 -- e.g. p_UOM = 'KWH', p_IN_SEARCH_OF = 'KW' means that we
								-- are now caching 'KWH' UOM data to derive 'KW' UOM data.
	) RETURN VARCHAR2 IS
v_RET	VARCHAR2(16);
BEGIN
	-- Use p_IN_SEARCH_OF to prevent infinite circular recursion
	CASE p_UOM
	-- NOTE: must also make sure that GET_SVC_UOM_CONVERSION_FACTOR can compute conversion
	-- factor if any other UOM pairs are added to this CASE statement!
	WHEN 'KW' THEN
		v_RET := 'KWH';
	WHEN 'KWH' THEN
		v_RET := 'KW';
	WHEN 'KVAR' THEN
		v_RET := 'KVARH';
	WHEN 'KVARH' THEN
		v_RET := 'KVAR';
	WHEN 'KVA' THEN
		v_RET := 'KVAH';
	WHEN 'KVAH' THEN
		v_RET := 'KVA';
	WHEN 'MW' THEN
		v_RET := 'KW';
	WHEN 'MWH' THEN
		v_RET := 'KWH';
	WHEN 'MVAR' THEN
		v_RET := 'KVAR';
	WHEN 'MVARH' THEN
		v_RET := 'KVARH';
	WHEN 'MVA' THEN
		v_RET := 'KVA';
	WHEN 'MVAH' THEN
		v_RET := 'KVAH';
	WHEN 'DTH' THEN
		v_RET := 'THM';
	-- handle special suffix for loss adjustments (means data must be sourced
	-- from SERVICE_LOAD instead of TX_SUB_STATION_METER_PT_VALUE)
	WHEN 'KW*' THEN
		v_RET := 'KWH';
	WHEN 'MW*' THEN
		v_RET := 'KW*';
	WHEN 'MWH*' THEN
		v_RET := 'MWH';
	ELSE
		-- cannot convert
		v_RET := NULL;
	END CASE;

	IF UPPER(v_RET) = UPPER(p_IN_SEARCH_OF) THEN
		v_RET := NULL; -- avoid circular recursion
	END IF;

	IF v_RET IS NOT NULL AND LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_MORE_DETAIL('Querying for '||p_UOM||'. Re-querying for '||v_RET);
	END IF;

	-- Done
	RETURN v_RET;
END GET_SVC_ALTERNATE_UOM;
-------------------------------------------------------------------------------
-- Forward declaration to support circular nature of POPULATE_PERIOD_CACHE
-- and CACHE_SVC_PERIOD_DETERMINANTS.
-- See full function below.
FUNCTION CACHE_SVC_PERIOD_DETERMINANTS
	(
	p_METER_IDS		IN NUMBER_COLLECTION,
	p_SERVICE_CODE	IN CHAR,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_UOM			IN VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_IN_SEARCH_OF	IN VARCHAR2 := NULL
	) RETURN PLS_INTEGER;
-------------------------------------------------------------------------------
-- Queries data from SERVICE_CONSUMPTION and inserts into the period
-- determinant cache table.
-- %param p_METER_ID		The Meter ID whose non-interval data is being cached.
--							Will be zero for account or aggregate modeled services.
-- %param p_SERVICE_CODE	The Service Code of non-interval data being
--							cached.
-- %param p_BEGIN_DATE		The begin day of the bill period.
-- %param p_END_DATE		The end day of the bill period.
-- %param p_OVERLAP_MODE	A three-way setting that indicates how begin and end
--							date are interpreted: 0 means get all records that
--							overlap the date range, 1 means get all records whose
--							BEGIN_DATE field is between the date range, and 2
--							means get all records whose END_DATE field is between
--							the date range.
-- %param p_UOM				The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID		If not Not Assigned, only retrieve results for a particular
--							time of use template.
-- %param p_IN_SEARCH_OF	If we are populating this UOM for the purpose of calculating/
--							deriving another, this will be the other UOM. This is needed
--							to prevent infinite recursion (No KW? Calc KW from KWH. No KWH?
--							Calc KWH from KW. No KW? etc...)
FUNCTION POPULATE_PERIOD_CACHE
	(
	p_METER_IDS		IN NUMBER_COLLECTION,
	p_SERVICE_CODE	IN CHAR,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_OVERLAP_MODE	IN PLS_INTEGER,
	p_UOM			IN VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_IN_SEARCH_OF	IN VARCHAR2
	) RETURN PLS_INTEGER IS
-- All DML (to cache tables) is done in autonomous transaction since this could be called
-- from SQL (like from a formula)
PRAGMA AUTONOMOUS_TRANSACTION;

v_CONS_CODE	SERVICE_CONSUMPTION.CONSUMPTION_CODE%TYPE;
v_COUNT		PLS_INTEGER;

BEGIN
	-- Consumption code is the same as service code - except for backcast/preliminary
	IF p_SERVICE_CODE = GA.BACKCAST_SERVICE THEN
		v_CONS_CODE := GA.PRELIMINARY_CONSUMPTION;
	ELSE
		v_CONS_CODE := p_SERVICE_CODE;
	END IF;

	-- fetch records from SERVICE_CONSUMPTION table
	INSERT INTO DETERMINANT_CACHE_PERIOD (OBJECT_ID, UOM, TEMPLATE_ID,	PERIOD_ID,
										  BEGIN_DATE, END_DATE, ENERGY, DEMAND)
	SELECT p_METER_IDS(p_METER_IDS.FIRST), p_UOM, p_TEMPLATE_ID,
			CASE WHEN p_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED THEN CONSTANTS.NOT_ASSIGNED ELSE SC.PERIOD_ID END,
			SC.BEGIN_DATE, SC.END_DATE,
			SUM(CASE BILL_CODE WHEN 'C' THEN -1 ELSE 1 END * SC.BILLED_USAGE),
			SUM(CASE BILL_CODE WHEN 'C' THEN -1 ELSE 1 END * SC.BILLED_DEMAND)
	FROM RTO_WORK R,
		SERVICE_CONSUMPTION SC
	WHERE R.WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID
		AND R.WORK_XID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
		AND SC.SERVICE_ID = R.WORK_SEQ
		AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
				-- all overlapping entries
			 	AND SC.BEGIN_DATE <= p_END_DATE
				AND SC.END_DATE >= p_BEGIN_DATE)
			OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
				-- only dates where begin date in the range
				AND SC.BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
			OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
				-- only dates where end date in the range
				AND SC.END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) )
		AND SC.CONSUMPTION_CODE = v_CONS_CODE
		AND (SC.TEMPLATE_ID = p_TEMPLATE_ID OR p_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED)
		AND UPPER(SC.UNIT_OF_MEASUREMENT) = p_UOM
		AND NVL(SC.IGNORE_CONSUMPTION,0) = 0
	GROUP BY SC.PERIOD_ID, SC.BEGIN_DATE, SC.END_DATE;

	IF SQL%ROWCOUNT > 0 THEN
		-- found records - return the count
		v_COUNT := SQL%ROWCOUNT;
		COMMIT;
		RETURN v_COUNT;
	ELSE
		-- found no records? try to calculate this UOM from others
		IF p_UOM IN ('KW', 'KVAR', 'KVA') THEN
			-- often, the UOM of the consumption record is the integrated measure
			-- (KWH or KVARH respectively) and DEMAND has the peak instantaneous
			-- (whereas ENERGY has the actual integrated measurement)
			v_COUNT := CACHE_SVC_PERIOD_DETERMINANTS(p_METER_IDS, p_SERVICE_CODE,
													p_BEGIN_DATE, p_END_DATE,
													p_UOM||'H', p_TEMPLATE_ID,
													p_UOM);
			-- so just copy from integrated measure where DEMAND field is non-null
			-- and non-zero
			INSERT INTO DETERMINANT_CACHE_PERIOD (OBJECT_ID, UOM, TEMPLATE_ID,	PERIOD_ID,
												  BEGIN_DATE, END_DATE, ENERGY, DEMAND)
			SELECT p_METER_IDS(p_METER_IDS.FIRST), p_UOM, p_TEMPLATE_ID, PERIOD_ID,
				BEGIN_DATE, END_DATE, ENERGY, DEMAND
			FROM DETERMINANT_CACHE_PERIOD
			WHERE OBJECT_ID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
				AND UOM = UPPER(p_UOM||'H')
				AND TEMPLATE_ID = p_TEMPLATE_ID
				AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
						-- all overlapping entries
						AND BEGIN_DATE <= p_END_DATE
						AND END_DATE >= p_BEGIN_DATE)
					OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
						-- only dates where begin date in the range
						AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
					OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
						-- only dates where end date in the range
						AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) )
				AND NVL(DEMAND,0) <> 0;

			IF SQL%ROWCOUNT > 0 OR p_UOM <> 'KVA' THEN
				v_COUNT := v_COUNT + SQL%ROWCOUNT;
				COMMIT;
				RETURN v_COUNT;
			ELSE
				-- still nothing? try to compute KVA via formula
				v_COUNT := v_COUNT+CACHE_SVC_PERIOD_DETERMINANTS(p_METER_IDS, p_SERVICE_CODE,
																p_BEGIN_DATE, p_END_DATE,
																'KW', p_TEMPLATE_ID,
																p_UOM);
				v_COUNT := v_COUNT+CACHE_SVC_PERIOD_DETERMINANTS(p_METER_IDS, p_SERVICE_CODE,
																p_BEGIN_DATE, p_END_DATE,
																'KWH', p_TEMPLATE_ID,
																p_UOM);
				-- KVA.DEMAND = KW.DEMAND * KVAH.ENERGY / KWH.ENERGY
				INSERT INTO DETERMINANT_CACHE_PERIOD (OBJECT_ID, UOM, TEMPLATE_ID,	PERIOD_ID,
													  BEGIN_DATE, END_DATE, ENERGY, DEMAND)
				SELECT p_METER_IDS(p_METER_IDS.FIRST), p_UOM, p_TEMPLATE_ID, A.PERIOD_ID,
					A.BEGIN_DATE, A.END_DATE, NULL,	CASE WHEN C.KWH = 0 THEN NULL ELSE A.KW * B.KVAH / C.KWH END -- don't divide by zero
				FROM (SELECT PERIOD_ID, BEGIN_DATE, END_DATE, MAX(DEMAND) as KW
				  	  FROM DETERMINANT_CACHE_PERIOD
				  	  WHERE OBJECT_ID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
						AND UOM = 'KW'
						AND TEMPLATE_ID = p_TEMPLATE_ID
						AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
								-- all overlapping entries
								AND BEGIN_DATE <= p_END_DATE
								AND END_DATE >= p_BEGIN_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
								-- only dates where begin date in the range
								AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
								-- only dates where end date in the range
								AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) )
					  GROUP BY PERIOD_ID, BEGIN_DATE, END_DATE) A,
					(SELECT PERIOD_ID, BEGIN_DATE, END_DATE, SUM(ENERGY) as KVAH
				  	  FROM DETERMINANT_CACHE_PERIOD
				  	  WHERE OBJECT_ID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
						AND UOM = 'KVAH'
						AND TEMPLATE_ID = p_TEMPLATE_ID
						AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
								-- all overlapping entries
								AND BEGIN_DATE <= p_END_DATE
								AND END_DATE >= p_BEGIN_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
								-- only dates where begin date in the range
								AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
								-- only dates where end date in the range
								AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) )
					  GROUP BY PERIOD_ID, BEGIN_DATE, END_DATE) B,
					(SELECT PERIOD_ID, BEGIN_DATE, END_DATE, SUM(ENERGY) as KWH
				  	  FROM DETERMINANT_CACHE_PERIOD
				  	  WHERE OBJECT_ID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
						AND UOM = 'KWH'
						AND TEMPLATE_ID = p_TEMPLATE_ID
						AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
								-- all overlapping entries
								AND BEGIN_DATE <= p_END_DATE
								AND END_DATE >= p_BEGIN_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
								-- only dates where begin date in the range
								AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
								-- only dates where end date in the range
								AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) )
					  GROUP BY PERIOD_ID, BEGIN_DATE, END_DATE) C
				WHERE B.PERIOD_ID = A.PERIOD_ID
					AND B.BEGIN_DATE = A.BEGIN_DATE
					AND B.END_DATE = A.END_DATE
					AND C.PERIOD_ID = A.PERIOD_ID
					AND C.BEGIN_DATE = A.BEGIN_DATE
					AND C.END_DATE = A.END_DATE;

				v_COUNT := v_COUNT + SQL%ROWCOUNT;
				COMMIT;
				RETURN v_COUNT;
			END IF;

		ELSIF p_UOM = 'KVAH' THEN
			-- try to compute KVAH via formula
			v_COUNT := CACHE_SVC_PERIOD_DETERMINANTS(p_METER_IDS, p_SERVICE_CODE,
															p_BEGIN_DATE, p_END_DATE,
															'KWH', p_TEMPLATE_ID,
															p_UOM);
			v_COUNT := v_COUNT+CACHE_SVC_PERIOD_DETERMINANTS(p_METER_IDS, p_SERVICE_CODE,
															p_BEGIN_DATE, p_END_DATE,
															'KVARH', p_TEMPLATE_ID,
															p_UOM);
			-- KVAH.ENERGY = SQRT ( KWH.ENERGY^2 + KVARH.ENERGY^2 )
			INSERT INTO DETERMINANT_CACHE_PERIOD (OBJECT_ID, UOM, TEMPLATE_ID,	PERIOD_ID,
												  BEGIN_DATE, END_DATE, ENERGY, DEMAND)
			SELECT p_METER_IDS(p_METER_IDS.FIRST), p_UOM, p_TEMPLATE_ID, A.PERIOD_ID,
				A.BEGIN_DATE, A.END_DATE, SQRT( A.KWH*A.KWH + B.KVARH*B.KVARH ), NULL
			FROM (SELECT PERIOD_ID, BEGIN_DATE, END_DATE, SUM(ENERGY) as KWH
				  FROM DETERMINANT_CACHE_PERIOD
				  WHERE OBJECT_ID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
					AND UOM = 'KWH'
					AND TEMPLATE_ID = p_TEMPLATE_ID
					AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
							-- all overlapping entries
							AND BEGIN_DATE <= p_END_DATE
							AND END_DATE >= p_BEGIN_DATE)
						OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
							-- only dates where begin date in the range
							AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
						OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
							-- only dates where end date in the range
							AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) )
				  	GROUP BY PERIOD_ID, BEGIN_DATE, END_DATE) A,
				 (SELECT PERIOD_ID, BEGIN_DATE, END_DATE, SUM(ENERGY) as KVARH
				  FROM DETERMINANT_CACHE_PERIOD
				  WHERE OBJECT_ID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
					AND UOM = 'KVARH'
					AND TEMPLATE_ID = p_TEMPLATE_ID
					AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
							-- all overlapping entries
							AND BEGIN_DATE <= p_END_DATE
							AND END_DATE >= p_BEGIN_DATE)
						OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
							-- only dates where begin date in the range
							AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
						OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
							-- only dates where end date in the range
							AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) )
				  	GROUP BY PERIOD_ID, BEGIN_DATE, END_DATE) B
			WHERE B.PERIOD_ID = A.PERIOD_ID
				AND B.BEGIN_DATE = A.BEGIN_DATE
				AND B.END_DATE = A.END_DATE;

			v_COUNT := v_COUNT + SQL%ROWCOUNT;
			COMMIT;
			RETURN v_COUNT;

		ELSE
			DECLARE
				v_UOM	VARCHAR2(16);
				v_SCALE	NUMBER;
			BEGIN
				v_UOM := GET_SVC_ALTERNATE_UOM(p_UOM, p_IN_SEARCH_OF);

				IF v_UOM IS NOT NULL THEN
					v_COUNT := CACHE_SVC_PERIOD_DETERMINANTS(p_METER_IDS, p_SERVICE_CODE,
															p_BEGIN_DATE, p_END_DATE,
															v_UOM, p_TEMPLATE_ID,
															p_UOM);
					v_SCALE := GET_SVC_UOM_CONVERSION_FACTOR(p_UOM, v_UOM, g_OBJECT_INFO_CACHE(p_METER_IDS(p_METER_IDS.FIRST)).INTERVAL_ORD);
					-- Convert
					INSERT INTO DETERMINANT_CACHE_PERIOD (OBJECT_ID, UOM, TEMPLATE_ID,	PERIOD_ID,
														  BEGIN_DATE, END_DATE, ENERGY, DEMAND)
					SELECT p_METER_IDS(p_METER_IDS.FIRST), p_UOM, p_TEMPLATE_ID, PERIOD_ID,
						BEGIN_DATE, END_DATE, ENERGY * v_SCALE, DEMAND * v_SCALE
					FROM DETERMINANT_CACHE_PERIOD
					WHERE OBJECT_ID IN (SELECT ID.COLUMN_VALUE FROM TABLE(p_METER_IDS) ID)
						AND UOM = UPPER(v_UOM)
						AND TEMPLATE_ID = p_TEMPLATE_ID
						AND ( (p_OVERLAP_MODE = c_OVERLAP_MODE_ALL
								-- all overlapping entries
								AND BEGIN_DATE <= p_END_DATE
								AND END_DATE >= p_BEGIN_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_BEGIN
								-- only dates where begin date in the range
								AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
							OR (p_OVERLAP_MODE = c_OVERLAP_MODE_END
								-- only dates where end date in the range
								AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE) );

					v_COUNT := v_COUNT + SQL%ROWCOUNT;
					COMMIT;
					RETURN v_COUNT;

				ELSE
					-- can't calculate it - nothing we can do
					COMMIT;
					RETURN 0;

				END IF;
			END;
		END IF;
	END IF;

END POPULATE_PERIOD_CACHE;
-------------------------------------------------------------------------------
-- Queries data from SERVICE_CONSUMPTION and inserts into the period
-- determinant cache table if necessary.
-- %param p_METER_ID		The Meter ID whose non-interval data is being cached.
--							Will be zero for account or aggregate modeled services.
-- %param p_SERVICE_CODE	The Service Code of non-interval data being
--							cached.
-- %param p_BEGIN_DATE		The begin day of the bill period.
-- %param p_END_DATE		The end day of the bill period.
-- %param p_UOM				The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID		If not Not Assigned, only retrieve results for a particular
--							time of use template.
-- %param p_IN_SEARCH_OF	If we are populating this UOM for the purpose of calculating/
--							deriving another, this will be the other UOM. This is needed
--							to prevent infinite recursion (No KW? Calc KW from KWH. No KWH?
--							Calc KWH from KW. No KW? etc...)
-- %return					Count of records stored in the cache table.
FUNCTION CACHE_SVC_PERIOD_DETERMINANTS
	(
	p_METER_IDS		IN NUMBER_COLLECTION,
	p_SERVICE_CODE	IN CHAR,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_UOM			IN VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_IN_SEARCH_OF	IN VARCHAR2 := NULL
	) RETURN PLS_INTEGER IS

v_KEY	VARCHAR2(40);
v_RET	PLS_INTEGER;

BEGIN

	v_KEY := PERIOD_CACHE_KEY(p_METER_IDS(p_METER_IDS.FIRST), p_UOM, p_TEMPLATE_ID);

	-- nothing in cache?
	IF NOT g_PERIOD_CACHE_DEF.EXISTS(v_KEY) THEN
		v_RET := POPULATE_PERIOD_CACHE(p_METER_IDS, p_SERVICE_CODE,
									p_BEGIN_DATE, p_END_DATE,
									c_OVERLAP_MODE_ALL, p_UOM, p_TEMPLATE_ID,
									p_IN_SEARCH_OF);

		g_PERIOD_CACHE_DEF(v_KEY).BEGIN_DATE := p_BEGIN_DATE;
		g_PERIOD_CACHE_DEF(v_KEY).END_DATE := p_END_DATE;
	ELSE
		-- got something in cache - make sure it is complete
		v_RET := 0;

		-- missing some data after existing cached records?
		IF p_END_DATE > g_PERIOD_CACHE_DEF(v_KEY).END_DATE THEN
			v_RET := v_RET+POPULATE_PERIOD_CACHE(p_METER_IDS, p_SERVICE_CODE,
												g_PERIOD_CACHE_DEF(v_KEY).END_DATE+1, p_END_DATE,
												c_OVERLAP_MODE_BEGIN, p_UOM, p_TEMPLATE_ID,
												p_IN_SEARCH_OF);

			g_PERIOD_CACHE_DEF(v_KEY).END_DATE := p_END_DATE;
		END IF;

		-- missing some data before existing cached records?
		IF p_BEGIN_DATE < g_PERIOD_CACHE_DEF(v_KEY).BEGIN_DATE THEN
			v_RET := v_RET+POPULATE_PERIOD_CACHE(p_METER_IDS, p_SERVICE_CODE,
												p_BEGIN_DATE, g_PERIOD_CACHE_DEF(v_KEY).BEGIN_DATE-1,
												c_OVERLAP_MODE_END, p_UOM, p_TEMPLATE_ID,
												p_IN_SEARCH_OF);

			g_PERIOD_CACHE_DEF(v_KEY).BEGIN_DATE := p_BEGIN_DATE;
		END IF;
	END IF;

	RETURN v_RET;

END CACHE_SVC_PERIOD_DETERMINANTS;
-------------------------------------------------------------------------------
-- Checks the status of period determinants. Populates period cache table if
-- necessary.
-- %param p_METER_ID		The Meter ID whose non-interval data is being cached.
--							Will be zero for account or aggregate modeled services.
-- %param p_SERVICE_CODE	The Service Code of non-interval data being
--							cached.
-- %param p_BEGIN_DATE		The begin day of the bill period.
-- %param p_END_DATE		The end day of the bill period.
-- %param p_UOM				The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID		If not Not Assigned, only retrieve results for a particular
--							time of use template.
-- %param p_PERIOD_ID		If neither this nor p_TEMPLATE_ID is Not Assigned,
--							check data for specified TOU period.
-- %return					The status of the determinants used to find the
--							result value: 0 = OK, 1 = Missing (result will be 0),
--							or 2 = Partial. Partial for non-interval data means
--							that period records that span the entire date range
--							were not found.
FUNCTION CHECK_SVC_PERIOD_DETERMINANTS
	(
	p_METER_IDS		IN NUMBER_COLLECTION,
	p_SERVICE_CODE	IN CHAR,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_UOM			IN VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_PERIOD_ID		IN NUMBER
	) RETURN PLS_INTEGER IS

v_DETERMINANT_COUNT NUMBER;
v_DUMMY				PLS_INTEGER;

BEGIN
	-- Make sure data is cached to temp table
	v_DUMMY := CACHE_SVC_PERIOD_DETERMINANTS(p_METER_IDS, p_SERVICE_CODE,
										p_BEGIN_DATE, p_END_DATE, p_UOM, p_TEMPLATE_ID);

	IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		TRACE_CACHE;
	END IF;

	SELECT COUNT(1)
	INTO v_DETERMINANT_COUNT
	FROM DETERMINANT_CACHE_PERIOD
  WHERE OBJECT_ID IN (SELECT B.COLUMN_VALUE FROM TABLE(p_METER_IDS) B) 
		AND UOM = p_UOM
		AND TEMPLATE_ID = p_TEMPLATE_ID
		AND (TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
		AND BEGIN_DATE BETWEEN (p_BEGIN_DATE - GA.DETERMINANT_DATE_THRESHOLD) AND p_END_DATE
		AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE;

	IF v_DETERMINANT_COUNT = 0 THEN
		RETURN c_STATUS_MISSING;
	END IF;

	-- if we get here, it means we have records spanning full date range
	RETURN c_STATUS_OK;
END CHECK_SVC_PERIOD_DETERMINANTS;
-------------------------------------------------------------------------------
-- Forward declaration to support circular nature of POPULATE_INTERVAL_CACHE
-- and CACHE_SVC_INTVL_DETERMINANTS.
-- See full function below.
FUNCTION CACHE_SVC_INTVL_DETERMINANTS
	(
	p_METER_ID			IN NUMBER,
	p_SERVICE_CODE		IN CHAR,
	p_TIME_ZONE			IN VARCHAR2,
	p_BEGIN_DATE		IN DATE,
	p_END_DATE			IN DATE,
	p_UOM				IN VARCHAR2,
	p_TEMPLATE_ID		IN NUMBER,
	p_IN_SEARCH_OF		IN VARCHAR2 := NULL,
	p_OPERATION_CODE 	IN VARCHAR2
	) RETURN PLS_INTEGER;

-------------------------------------------------------------------------------
-- Populate the DETERMINANT_CACHE_INTERVAL table from the TX_SUB_STATION_METER_POINT
-- and TX_SUB_STATION_METER_PT_VALUE (NON-AGGregated vs. SERVICE_LOAD) for the
-- specified parameters when there is no TOU template.
-- %param p_METER_ID         The Meter ID whose interval data is being cached.
-- %param p_SERVICE_CODE     The Service Code of interval data being cached.
-- %param p_UOM              The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID      TOU Template to identify interval data with Period IDs.
-- %param p_OPERATION_CODE   Operation Code to filter on (e.g., NULL, 'A', 'S')
-- %param p_BEGIN_DATE       The begin day of the bill period.
-- %param p_END_DATE         The end day of the bill period.
-------------------------------------------------------------------------------
PROCEDURE POP_INTVL_CACHE_NOTMPL_NONAGG
  (
  p_METER_ID            IN NUMBER,
  p_SERVICE_CODE        IN CHAR,
  p_UOM                 IN VARCHAR2,
  p_TEMPLATE_ID         IN NUMBER,
  p_OPERATION_CODE      IN VARCHAR2,
  p_BEGIN_DATE          IN DATE,
  p_END_DATE            IN DATE
  ) IS
BEGIN
  INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL)
  SELECT p_METER_ID, p_UOM, p_TEMPLATE_ID, MPV.METER_DATE, NULL, p_OPERATION_CODE,
       NVL(SUM(MPV.METER_VAL * CASE MP.OPERATION_CODE WHEN c_OPERATION_CODE_ADD THEN 1.0 ELSE -1.0 END),0),
       NVL(SUM(MPV.LOSS_VAL * CASE MP.OPERATION_CODE WHEN c_OPERATION_CODE_ADD THEN 1.0 ELSE -1.0 END),0),
       0
  FROM TX_SUB_STATION_METER_POINT MP,
       TX_SUB_STATION_METER_PT_VALUE MPV
  WHERE MP.RETAIL_METER_ID = p_METER_ID
    AND UPPER(MP.UOM) = p_UOM
    AND ((p_OPERATION_CODE IS NULL AND NVL(MP.OPERATION_CODE,'N') <> 'N') OR (p_OPERATION_CODE IS NOT NULL AND NVL(MP.OPERATION_CODE,'N') <> 'N' AND MP.OPERATION_CODE = p_OPERATION_CODE))
    AND MPV.METER_POINT_ID = MP.METER_POINT_ID
    AND MPV.MEASUREMENT_SOURCE_ID = CONSTANTS.NOT_ASSIGNED
    AND MPV.METER_CODE = p_SERVICE_CODE
    AND MPV.METER_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
  GROUP BY MPV.METER_DATE;
END POP_INTVL_CACHE_NOTMPL_NONAGG;

-------------------------------------------------------------------------------
-- Populate the DETERMINANT_CACHE_INTERVAL table from the TX_SUB_STATION_METER_POINT
-- and TX_SUB_STATION_METER_PT_VALUE (NON-AGGregated vs. SERVICE_LOAD) for the
-- specified parameters when there is a TOU template.
-- %param p_METER_ID               The Meter ID whose interval data is being cached.
-- %param p_SERVICE_CODE           The Service Code of interval data being cached.
-- %param p_TIME_ZONE				       The time zone, used to define which intervals
--									               comprise a day.
-- %param p_UOM                    The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID            TOU Template to identify interval data with Period IDs.
-- %param p_OPERATION_CODE         Operation Code to filter on (e.g., NULL, 'A', 'S')
-- %param p_BEGIN_DATE             The begin day of the bill period.
-- %param p_END_DATE               The end day of the bill period.
-- %param p_EDC_HOLIDAY_SET_ID     Holiday set ID
-------------------------------------------------------------------------------
PROCEDURE POP_INTVL_CACHE_TMPL_NONAGG
  (
  p_METER_ID                       IN NUMBER,
  p_SERVICE_CODE                   IN CHAR,
  p_TIME_ZONE                      IN VARCHAR2,
  p_UOM                            IN VARCHAR2,
  p_TEMPLATE_ID                    IN NUMBER,
  p_OPERATION_CODE                 IN VARCHAR2,
  p_BEGIN_DATE                     IN DATE,
  p_END_DATE                       IN DATE,
  p_EDC_HOLIDAY_SET_ID             IN NUMBER
  ) IS
BEGIN
  INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL)
  SELECT p_METER_ID, p_UOM, p_TEMPLATE_ID, MPV.METER_DATE, TDP.PERIOD_ID, p_OPERATION_CODE,
       NVL(SUM(MPV.METER_VAL * CASE MP.OPERATION_CODE WHEN c_OPERATION_CODE_ADD THEN 1.0 ELSE -1.0 END),0),
       NVL(SUM(MPV.LOSS_VAL * CASE MP.OPERATION_CODE WHEN c_OPERATION_CODE_ADD THEN 1.0 ELSE -1.0 END),0),
        0
  FROM TX_SUB_STATION_METER_POINT MP,
    TX_SUB_STATION_METER_PT_VALUE MPV,
    TEMPLATE_DATES TD,
    TEMPLATE_DAY_TYPE_PERIOD TDP
  WHERE MP.RETAIL_METER_ID = p_METER_ID
    AND UPPER(MP.UOM) = p_UOM
    AND ((p_OPERATION_CODE IS NULL AND NVL(MP.OPERATION_CODE,'N') <> 'N') OR (p_OPERATION_CODE IS NOT NULL AND NVL(MP.OPERATION_CODE,'N') <> 'N' AND MP.OPERATION_CODE = p_OPERATION_CODE))
    AND MPV.METER_POINT_ID = MP.METER_POINT_ID
    AND MPV.MEASUREMENT_SOURCE_ID = CONSTANTS.NOT_ASSIGNED
    AND MPV.METER_CODE = p_SERVICE_CODE
    AND MPV.METER_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
    AND TD.TIME_ZONE = p_TIME_ZONE
    AND TD.TEMPLATE_ID = p_TEMPLATE_ID
    AND TD.HOLIDAY_SET_ID = p_EDC_HOLIDAY_SET_ID
    AND TD.CUT_BEGIN_DATE < MPV.METER_DATE
    AND TD.CUT_END_DATE >= MPV.METER_DATE
    AND TDP.DAY_TYPE_ID = TD.DAY_TYPE_ID
    AND TDP.TIME_STAMP = MPV.METER_DATE - TD.CUT_BEGIN_DATE
  GROUP BY MPV.METER_DATE, TDP.PERIOD_ID;
END POP_INTVL_CACHE_TMPL_NONAGG;

-------------------------------------------------------------------------------
-- Queries data from SERVICE_LOAD and inserts into the interval
-- determinant cache table.
-- %param p_METER_ID				The Meter ID whose interval data is being cached.
--									Will be zero for account or aggregate modeled services.
-- %param p_SERVICE_CODE			The Service Code of interval data being cached.
-- %param p_TIME_ZONE				The time zone, used to define which intervals
--									comprise a day.
-- %param p_BEGIN_DATE				The begin day of the bill period.
-- %param p_END_DATE				The end day of the bill period.
-- %param p_UOM						The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID				If not Not Assigned, use specified TOU Template to identify
--									interval data with Period IDs.
-- %param p_IN_SEARCH_OF			If we are populating this UOM for the purpose of calculating/
--									deriving another, this will be the other UOM. This is needed
--									to prevent infinite recursion (No KW? Calc KW from KWH. No KWH?
--									Calc KWH from KW. No KW? etc...)
-- %return							Count of records stored in the cache table.
FUNCTION POPULATE_INTERVAL_CACHE
	(
	p_METER_ID		IN NUMBER,
	p_SERVICE_CODE	IN CHAR,
	p_TIME_ZONE		IN VARCHAR2,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_UOM			IN VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_IN_SEARCH_OF	IN VARCHAR2,
	p_OPERATION_CODE IN VARCHAR2
	) RETURN PLS_INTEGER IS
-- All DML (to cache tables) is done in autonomous transaction since this could be called
-- from SQL (like from a formula)
PRAGMA AUTONOMOUS_TRANSACTION;

-- suffix on UOM means data must come from SERVICE_LOAD instead of TX_SUB_STATION_METER_PT_VALUE
v_SKIP_CHANNELS	BOOLEAN := SUBSTR(p_UOM,LENGTH(p_UOM)) = '*';

v_BEGIN_DATE	      DATE;
v_END_DATE		      DATE;
v_CHANNEL_COUNT	   PLS_INTEGER;
v_COUNT			      PLS_INTEGER;
v_SCALE			      NUMBER;
v_ORD			         PLS_INTEGER;
v_EDC_HOLIDAY_SET_ID NUMBER := NVL(g_OBJECT_INFO_CACHE(p_METER_ID).EDC_HOLIDAY_SET_ID,c_ALL_HOLIDAY_SET);
BEGIN
	-- Determine proper date range for query
	DETERMINANT_ACCESSOR_DATES(g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL,
								p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	IF p_UOM = UPPER(GA.DEFAULT_UNIT_OF_MEASUREMENT) THEN
		-- make sure interval cache granularity for this UOM is in-sync with this
		-- service's interval
		UPDATE_INTERVAL_CACHE_GRAN(p_UOM, g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL_ORD);

		IF p_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED THEN
			-- no need to identify periods
			IF p_OPERATION_CODE IS NULL THEN
				INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL)
				SELECT p_METER_ID, p_UOM, p_TEMPLATE_ID, SL.LOAD_DATE, NULL, p_OPERATION_CODE, NvL(SUM(SL.LOAD_VAL),0), NVL(SUM(SL.TX_LOSS_VAL+SL.DX_LOSS_VAL),0), NVL(SUM(SL.UE_LOSS_VAL),0)
				FROM RTO_WORK R,
					SERVICE_LOAD SL
				WHERE R.WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID
					AND R.WORK_XID = p_METER_ID
					AND SL.SERVICE_ID = R.WORK_SEQ
					AND SERVICE_CODE = p_SERVICE_CODE
					AND LOAD_CODE = GA.STANDARD
					AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
				GROUP BY SL.LOAD_DATE;
			ELSE
				POP_INTVL_CACHE_NOTMPL_NONAGG(p_METER_ID, p_SERVICE_CODE, p_UOM, p_TEMPLATE_ID, p_OPERATION_CODE, v_BEGIN_DATE, v_END_DATE);
			END IF;

			v_COUNT := SQL%ROWCOUNT;
			COMMIT;
			RETURN v_COUNT;
		ELSE -- using template
			-- identify periods for specified template using TEMPLATE_DATES tables/structures
			IF p_OPERATION_CODE IS NULL THEN
				INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, LOAD_VAL, LOSS_VAL, UFE_VAL)
				SELECT p_METER_ID, p_UOM, p_TEMPLATE_ID, SL.LOAD_DATE, TDP.PERIOD_ID, NVL(SUM(SL.LOAD_VAL),0), NVL(SUM(SL.TX_LOSS_VAL+SL.DX_LOSS_VAL),0), NVL(SUM(SL.UE_LOSS_VAL),0)
				FROM RTO_WORK R,
					SERVICE_LOAD SL,
					TEMPLATE_DATES TD,
					TEMPLATE_DAY_TYPE_PERIOD TDP
				WHERE R.WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID
					AND R.WORK_XID = p_METER_ID
					AND SL.SERVICE_ID = R.WORK_SEQ
					AND SL.SERVICE_CODE = p_SERVICE_CODE
					AND SL.LOAD_CODE = GA.STANDARD
					AND SL.LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
					AND TD.TIME_ZONE = p_TIME_ZONE
					AND TD.TEMPLATE_ID = p_TEMPLATE_ID
					AND TD.HOLIDAY_SET_ID = v_EDC_HOLIDAY_SET_ID
					AND TD.CUT_BEGIN_DATE < SL.LOAD_DATE
					AND TD.CUT_END_DATE >= SL.LOAD_DATE
					AND TDP.DAY_TYPE_ID = TD.DAY_TYPE_ID
					AND TDP.TIME_STAMP = SL.LOAD_DATE - TD.CUT_BEGIN_DATE
				GROUP BY SL.LOAD_DATE, TDP.PERIOD_ID;
			ELSE
				POP_INTVL_CACHE_TMPL_NONAGG(p_METER_ID, p_SERVICE_CODE, p_TIME_ZONE, p_UOM, p_TEMPLATE_ID, p_OPERATION_CODE, v_BEGIN_DATE, v_END_DATE, v_EDC_HOLIDAY_SET_ID);
			END IF;

			v_COUNT := SQL%ROWCOUNT;
			COMMIT;
			RETURN v_COUNT;
		END IF;
	ELSE -- not default UOM
		-- Look at channels with specified UOM if meter-modeled
		IF p_METER_ID <> CONSTANTS.NOT_ASSIGNED AND NOT v_SKIP_CHANNELS THEN
			SELECT COUNT(1), MIN(DATE_UTIL.INTERVAL_ORD(MP.METER_POINT_INTERVAL))
			INTO v_CHANNEL_COUNT, v_ORD
			FROM TX_SUB_STATION_METER_POINT MP
			WHERE MP.RETAIL_METER_ID = p_METER_ID
				AND UPPER(MP.UOM) = p_UOM
				AND NVL(MP.OPERATION_CODE,'N') <> 'N';
		ELSE
			v_CHANNEL_COUNT := 0; -- not meter-modeled? no channels
		END IF;

    IF v_CHANNEL_COUNT > 0 THEN
			-- make sure interval cache granularity for this UOM is in-sync with the
			-- actual channel intervals
			UPDATE_INTERVAL_CACHE_GRAN(p_UOM, v_ORD);

			-- have channels - cache data for those channels
			IF p_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED THEN
				-- no need to identify periods
				POP_INTVL_CACHE_NOTMPL_NONAGG(p_METER_ID, p_SERVICE_CODE, p_UOM, p_TEMPLATE_ID, p_OPERATION_CODE, v_BEGIN_DATE, v_END_DATE);

				v_COUNT := SQL%ROWCOUNT;
				COMMIT;
				RETURN v_COUNT;
			ELSE
				-- identify periods for specified template using TEMPLATE_DATES tables/structures
				POP_INTVL_CACHE_TMPL_NONAGG(p_METER_ID, p_SERVICE_CODE, p_TIME_ZONE, p_UOM, p_TEMPLATE_ID, p_OPERATION_CODE, v_BEGIN_DATE, v_END_DATE, v_EDC_HOLIDAY_SET_ID);

				v_COUNT := SQL%ROWCOUNT;
				COMMIT;
				RETURN v_COUNT;
			END IF;
		ELSE
			-- no channels? try to calculate values for this UOM from other channels then
			IF p_UOM = 'KVAH' THEN
				v_COUNT := CACHE_SVC_INTVL_DETERMINANTS(p_METER_ID, p_SERVICE_CODE, p_TIME_ZONE, p_BEGIN_DATE, p_END_DATE, 'KWH', p_TEMPLATE_ID, p_UOM, p_OPERATION_CODE);
				v_COUNT := v_COUNT+CACHE_SVC_INTVL_DETERMINANTS(p_METER_ID, p_SERVICE_CODE, p_TIME_ZONE, p_BEGIN_DATE, p_END_DATE, 'KVARH', p_TEMPLATE_ID, p_UOM, p_OPERATION_CODE);

				-- make sure interval cache granularity for this UOM is in-sync with the
				-- actual source channel intervals
				UPDATE_INTERVAL_CACHE_GRAN(p_UOM, INTERVAL_CACHE_GRAN('KWH'));
				UPDATE_INTERVAL_CACHE_GRAN(p_UOM, INTERVAL_CACHE_GRAN('KVARH'));

				-- Calculate KVAH from KWH and KVARH:
				-- KVAH = SQRT ( KWH^2 + KVARH^2 )
				INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL)
				SELECT p_METER_ID, p_UOM, p_TEMPLATE_ID, A.LOAD_DATE, A.PERIOD_ID, A.OPERATION_CODE,
					SQRT(A.LOAD_VAL*A.LOAD_VAL + B.LOAD_VAL*B.LOAD_VAL) * CASE NVL(A.OPERATION_CODE,c_OPERATION_CODE_ADD) WHEN c_OPERATION_CODE_ADD THEN 1.0 ELSE -1.0 END,
					-- compute KVA w/ losses and store delta in loss value
					SQRT((A.LOAD_VAL+A.LOSS_VAL)*(A.LOAD_VAL+A.LOSS_VAL) + (B.LOAD_VAL+B.LOSS_VAL)*(B.LOAD_VAL+B.LOSS_VAL)) - SQRT(A.LOAD_VAL*A.LOAD_VAL + B.LOAD_VAL*B.LOAD_VAL),
					-- ditto for UFE value
					SQRT((A.LOAD_VAL+A.LOSS_VAL+A.UFE_VAL)*(A.LOAD_VAL+A.LOSS_VAL+A.UFE_VAL) + (B.LOAD_VAL+B.LOSS_VAL+B.UFE_VAL)*(B.LOAD_VAL+B.LOSS_VAL+B.UFE_VAL)) - SQRT((A.LOAD_VAL+A.LOSS_VAL)*(A.LOAD_VAL+A.LOSS_VAL) + (B.LOAD_VAL+B.LOSS_VAL)*(B.LOAD_VAL+B.LOSS_VAL))
				FROM DETERMINANT_CACHE_INTERVAL A,
					DETERMINANT_CACHE_INTERVAL B
				WHERE A.OBJECT_ID = p_METER_ID
					AND A.UOM = 'KWH'
					AND A.TEMPLATE_ID = p_TEMPLATE_ID
					AND A.LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
					AND B.OBJECT_ID = p_METER_ID
					AND B.UOM = 'KVARH'
					AND B.TEMPLATE_ID = p_TEMPLATE_ID
					AND B.LOAD_DATE = A.LOAD_DATE
					AND ((p_OPERATION_CODE IS NULL AND A.OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND A.OPERATION_CODE = p_OPERATION_CODE))
					AND ((p_OPERATION_CODE IS NULL AND B.OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND B.OPERATION_CODE = p_OPERATION_CODE));

				v_COUNT := v_COUNT + SQL%ROWCOUNT;
				COMMIT;
				RETURN v_COUNT;

			ELSE
				DECLARE
					v_UOM			VARCHAR2(16);
					v_INTERVAL_ORD	NUMBER;
				BEGIN
					v_UOM := GET_SVC_ALTERNATE_UOM(p_UOM, p_IN_SEARCH_OF);

					IF v_UOM IS NOT NULL THEN
						v_COUNT := CACHE_SVC_INTVL_DETERMINANTS(p_METER_ID, p_SERVICE_CODE, p_TIME_ZONE, p_BEGIN_DATE, p_END_DATE, v_UOM, p_TEMPLATE_ID, p_UOM, p_OPERATION_CODE);

						-- make sure interval cache granularity for this UOM is in-sync with the
						-- actual source channel intervals
						v_INTERVAL_ORD := INTERVAL_CACHE_GRAN(v_UOM);
						UPDATE_INTERVAL_CACHE_GRAN(p_UOM, v_INTERVAL_ORD);

						-- compute conversion factor
						v_SCALE := GET_SVC_UOM_CONVERSION_FACTOR(p_UOM, v_UOM, v_INTERVAL_ORD);

						-- Convert
						INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL, LOSS_VAL, UFE_VAL)
						SELECT p_METER_ID, p_UOM, p_TEMPLATE_ID, LOAD_DATE, PERIOD_ID, OPERATION_CODE, LOAD_VAL * v_SCALE, LOSS_VAL * v_SCALE, UFE_VAL * v_SCALE
						FROM DETERMINANT_CACHE_INTERVAL
						WHERE OBJECT_ID = p_METER_ID
							AND UOM = UPPER(v_UOM)
							AND TEMPLATE_ID = p_TEMPLATE_ID
							AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
							AND ((p_OPERATION_CODE IS NULL AND OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND OPERATION_CODE = p_OPERATION_CODE));

						v_COUNT := v_COUNT + SQL%ROWCOUNT;
						COMMIT;
						RETURN v_COUNT;

					ELSE
						-- can't calculate it - nothing we can do
						COMMIT;
						RETURN 0;

					END IF;
				END;
			END IF;
		END IF;
	END IF;
END POPULATE_INTERVAL_CACHE;
-------------------------------------------------------------------------------
-- Queries data from SERVICE_LOAD and inserts into the interval
-- determinant cache table if necessary.
-- %param p_METER_ID				The Meter ID whose interval data is being cached.
--									Will be zero for account or aggregate modeled services.
-- %param p_SERVICE_CODE			The Service Code of interval data being cached.
-- %param p_TIME_ZONE				The time zone, used to define which intervals
--									comprise a day.
-- %param p_BEGIN_DATE				The begin day of the bill period.
-- %param p_END_DATE				The end day of the bill period.
-- %param p_UOM						The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID				If not Not Assigned, use specified TOU Template to identify
--									interval data with Period IDs.
-- %param p_IN_SEARCH_OF			If we are populating this UOM for the purpose of calculating/
--									deriving another, this will be the other UOM. This is needed
--									to prevent infinite recursion (No KW? Calc KW from KWH. No KWH?
--									Calc KWH from KW. No KW? etc...)
-- %return							Count of records stored in the cache table.
FUNCTION CACHE_SVC_INTVL_DETERMINANTS
	(
	p_METER_ID		IN NUMBER,
	p_SERVICE_CODE	IN CHAR,
	p_TIME_ZONE		IN VARCHAR2,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_UOM			IN VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_IN_SEARCH_OF	IN VARCHAR2 := NULL,
	p_OPERATION_CODE IN VARCHAR2
	) RETURN PLS_INTEGER IS

v_START_DATE_TO_CACHE	DATE;
v_DATE					DATE;
v_KEY					VARCHAR2(40);
v_BEGIN_DATE			DATE;
v_END_DATE				DATE;
v_RECORDS_STORED		PLS_INTEGER := 0;

	------------------------------------------------------------------------
	-- populate temp tables through specified date and update
	-- package structures
	PROCEDURE POPULATE_CACHE(p_THROUGH_DATE IN DATE) AS
	v_DATE	DATE;
	v_KEY	VARCHAR2(40);
	BEGIN
		v_RECORDS_STORED := v_RECORDS_STORED +
							POPULATE_INTERVAL_CACHE(p_METER_ID, p_SERVICE_CODE, p_TIME_ZONE,
												v_START_DATE_TO_CACHE, p_THROUGH_DATE, p_UOM,
												p_TEMPLATE_ID, p_IN_SEARCH_OF, p_OPERATION_CODE);
		v_DATE := v_START_DATE_TO_CACHE;
		WHILE v_DATE <= p_THROUGH_DATE LOOP
			-- make sure we have an entry in the cache def
			v_KEY := INTERVAL_CACHE_KEY(p_METER_ID, p_UOM, v_DATE, p_OPERATION_CODE);
			g_INTERVAL_CACHE_DEF(v_KEY)(p_TEMPLATE_ID) := NULL;
			v_DATE := v_DATE+1;
		END LOOP;
		v_START_DATE_TO_CACHE := NULL;
	END POPULATE_CACHE;
	------------------------------------------------------------------------
BEGIN
	v_START_DATE_TO_CACHE := NULL;
	-- Loop over each day
	v_DATE := p_BEGIN_DATE;
	WHILE v_DATE <= p_END_DATE LOOP
		v_KEY := INTERVAL_CACHE_KEY(p_METER_ID, p_UOM, v_DATE, p_OPERATION_CODE);
		-- missing?
		IF NOT g_INTERVAL_CACHE_DEF.EXISTS(v_KEY) THEN
			-- setup date range to store to cache
			IF v_START_DATE_TO_CACHE IS NULL THEN
				v_START_DATE_TO_CACHE := v_DATE;
			END IF;
		ELSE
			-- flush range of missing days to the temp table
			IF v_START_DATE_TO_CACHE IS NOT NULL THEN
				POPULATE_CACHE(v_DATE-1);
			END IF;
			-- populated for correct template?
			IF NOT g_INTERVAL_CACHE_DEF(v_KEY).EXISTS(p_TEMPLATE_ID) THEN
				-- if not, copy data from another template (use first template in the cache def)
				DETERMINANT_ACCESSOR_DATES(g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL,
											v_DATE, v_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
        v_RECORDS_STORED := v_RECORDS_STORED + COPY_INTERVAL_CACHE(p_METER_ID, p_UOM,
																	g_INTERVAL_CACHE_DEF(v_KEY).FIRST, p_TEMPLATE_ID,
																	v_BEGIN_DATE, v_END_DATE, p_TIME_ZONE, p_OPERATION_CODE);
				-- store an entry for this template
				g_INTERVAL_CACHE_DEF(v_KEY)(p_TEMPLATE_ID) := g_INTERVAL_CACHE_DEF(v_KEY)(g_INTERVAL_CACHE_DEF(v_KEY).FIRST);
			END IF;
		END IF;
		v_DATE := v_DATE+1;
	END LOOP;
	-- Flush final range of missing days to the temp table
	IF v_START_DATE_TO_CACHE IS NOT NULL THEN
		POPULATE_CACHE(p_END_DATE);
	END IF;
	-- return the number of records inserted into the cache
	RETURN v_RECORDS_STORED;
END CACHE_SVC_INTVL_DETERMINANTS;
-------------------------------------------------------------------------------
-- Checks the status of interval determinants. Populates interval cache table
-- if necessary.
-- %param p_METER_ID				The Meter ID whose interval data is being cached.
--									Will be zero for account or aggregate modeled services.
-- %param p_SERVICE_CODE			The Service Code of interval data being cached.
-- %param p_TIME_ZONE				The time zone, used to define which intervals
--									comprise a day.
-- %param p_BEGIN_DATE				The begin day of the bill period.
-- %param p_END_DATE				The end day of the bill period.
-- %param p_UOM						The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID				If not Not Assigned, use specified TOU Template to identify
--									interval data with Period IDs.
-- %return							The status of the determinants used to find the
--									result value: 0 = OK, 1 = Missing (result will be 0),
--									or 2 = Partial. Partial for interval data means that
--									data did not exist for the full date range.
FUNCTION CHECK_SVC_INTVL_DETERMINANTS
	(
	p_METER_ID		IN NUMBER,
	p_SERVICE_CODE	IN CHAR,
	p_TIME_ZONE		IN VARCHAR2,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_UOM			IN VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_OPERATION_CODE IN VARCHAR2
	) RETURN PLS_INTEGER IS

v_DUMMY	PLS_INTEGER;

BEGIN
	-- Make sure data is cached to temp table
	v_DUMMY := CACHE_SVC_INTVL_DETERMINANTS(p_METER_ID, p_SERVICE_CODE, p_TIME_ZONE,
											p_BEGIN_DATE, p_END_DATE, p_UOM, p_TEMPLATE_ID, NULL, p_OPERATION_CODE);

	IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		TRACE_CACHE;
	END IF;

	-- Examine the cache package variable structures and/or temp table to ascertain status of the determinants
	RETURN GET_INTVL_DETERMINANT_STATUS(p_METER_ID, g_OBJECT_INFO_CACHE(p_METER_ID).INTERVAL, p_UOM, p_TEMPLATE_ID, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, p_OPERATION_CODE);

END CHECK_SVC_INTVL_DETERMINANTS;
-------------------------------------------------------------------------------
PROCEDURE GET_ACTIVE_SERVICES_INTERNAL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_DATES_ARE_CUT IN BOOLEAN,
	p_TIME_ZONE IN VARCHAR2
	) AS

PRAGMA AUTONOMOUS_TRANSACTION;

v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_CSB_IS_SUBDAILY CONSTANT NUMBER(1) := CASE WHEN GA.CSB_IS_SUBDAILY THEN 1 ELSE 0 END;

BEGIN

	-- Determine proper dates to use for query
	IF p_DATES_ARE_CUT THEN
		v_BEGIN_DATE := TRUNC(FROM_CUT(p_BEGIN_DATE, p_TIME_ZONE)-1/86400);
		v_END_DATE := TRUNC(FROM_CUT(p_END_DATE, p_TIME_ZONE)-1/86400);
	ELSE
		v_BEGIN_DATE := p_BEGIN_DATE;
		v_END_DATE := p_END_DATE;
	END IF;

	-- for performance, do not re-query IDs if unnecessary
	IF v_BEGIN_DATE = g_PREV_ACTIVE_BEGIN_DATE AND v_END_DATE = g_PREV_ACTIVE_END_DATE THEN
		RETURN;
	END IF;

	-- reset our package variables
	g_PREV_ACTIVE_BEGIN_DATE := v_BEGIN_DATE;
	g_PREV_ACTIVE_END_DATE := V_END_DATE;

	IF g_PREV_ACTIVE_SVC_WORK_ID IS NULL THEN
		UT.GET_RTO_WORK_ID(g_PREV_ACTIVE_SVC_WORK_ID);
	ELSE
		-- clean it up for the next round
		UT.PURGE_RTO_WORK(g_PREV_ACTIVE_SVC_WORK_ID);
	END IF;

	-- and populate work table with IDs
	INSERT INTO RTO_WORK (WORK_ID, WORK_XID, WORK_SEQ)
	SELECT /*+ ordered index(s pk_service) use_nl(asl) index(asl pk_account_service_location) */
		DISTINCT g_PREV_ACTIVE_SVC_WORK_ID,
				NVL(ASVC.METER_ID, CONSTANTS.NOT_ASSIGNED),
				S.SERVICE_ID
	FROM RTO_WORK W,
		SERVICE S,
		ACCOUNT_SERVICE ASVC,
		ACCOUNT_STATUS AST,
		ACCOUNT_STATUS_NAME ASTN,
		ACCOUNT_SERVICE_LOCATION ASL,
		ACCOUNT A
	WHERE W.WORK_ID = g_LAST_SVC_WORK_ID
		AND S.SERVICE_ID = W.WORK_XID
		AND ASVC.ACCOUNT_SERVICE_ID = S.ACCOUNT_SERVICE_ID
		AND AST.ACCOUNT_ID = ASVC.ACCOUNT_ID
        AND (
            (v_CSB_IS_SUBDAILY = 1 AND TRUNC(FROM_CUT(AST.BEGIN_DATE, NVL(p_TIME_ZONE, NVL(g_LAST_TIME_ZONE, GA.LOCAL_TIME_ZONE)))-1/86400) <= g_PREV_ACTIVE_END_DATE)
            OR
            (v_CSB_IS_SUBDAILY = 0 AND AST.BEGIN_DATE <= g_PREV_ACTIVE_END_DATE)
            )
		AND NVL(AST.END_DATE, CONSTANTS.HIGH_DATE) >= g_PREV_ACTIVE_BEGIN_DATE
		AND ASTN.STATUS_NAME = AST.STATUS_NAME
		AND ASTN.IS_ACTIVE = 1
		AND ASL.ACCOUNT_ID = ASVC.ACCOUNT_ID
		AND ASL.SERVICE_LOCATION_ID = ASVC.SERVICE_LOCATION_ID
		AND ASL.BEGIN_DATE <= g_PREV_ACTIVE_END_DATE
		AND NVL(ASL.END_DATE, CONSTANTS.HIGH_DATE) >= g_PREV_ACTIVE_BEGIN_DATE
		AND A.ACCOUNT_ID = ASVC.ACCOUNT_ID
		-- make sure meter is active and valid if this is a meter-modeled account
		AND EXISTS (SELECT 1
					FROM DUAL
					WHERE UPPER(SUBSTR(A.ACCOUNT_MODEL_OPTION,1,1)) <> 'M'
						AND NVL(ASVC.METER_ID, CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED
					UNION ALL
					SELECT 1
					FROM METER M,
						ACCOUNT_STATUS_NAME MSTN,
						SERVICE_LOCATION_METER SLM
					WHERE UPPER(SUBSTR(A.ACCOUNT_MODEL_OPTION,1,1)) = 'M'
						AND M.METER_ID = ASVC.METER_ID
						AND MSTN.STATUS_NAME = M.METER_STATUS
						AND MSTN.IS_ACTIVE = 1
						AND SLM.SERVICE_LOCATION_ID = ASVC.SERVICE_LOCATION_ID
						AND SLM.METER_ID = ASVC.METER_ID
						AND SLM.BEGIN_DATE <= g_PREV_ACTIVE_END_DATE
						AND NVL(SLM.END_DATE, CONSTANTS.HIGH_DATE) >= g_PREV_ACTIVE_BEGIN_DATE);

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Active service IDs for '||TEXT_UTIL.TO_CHAR_DATE(v_BEGIN_DATE)||' -> '||TEXT_UTIL.TO_CHAR_DATE(v_END_DATE)||' :');
		FOR v_REC IN (SELECT R.WORK_XID as METER_ID, R.WORK_SEQ as SERVICE_ID
						FROM RTO_WORK R
						WHERE WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID) LOOP
			LOGS.LOG_DEBUG_DETAIL('  '||v_REC.SERVICE_ID||' (Meter = '||v_REC.METER_ID||')');
		END LOOP;
		LOGS.LOG_DEBUG_DETAIL('End active service IDs');
	END IF;

	COMMIT;

END GET_ACTIVE_SERVICES_INTERNAL;
-------------------------------------------------------------------------------
FUNCTION GET_ACTIVE_SERVICES
	(
	p_ACCESSOR IN ACCOUNT_DETERMINANT_ACCESSOR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_DATES_ARE_CUT IN BOOLEAN := FALSE,
	p_TIME_ZONE IN VARCHAR2 := NULL
	) RETURN NUMBER_COLLECTION IS

	v_RET	NUMBER_COLLECTION := NUMBER_COLLECTION();

BEGIN
	-- Since this is public, we need to make sure package variables are in proper
	-- state before proceeding
	INIT(p_ACCESSOR);
	GET_ACTIVE_SERVICES_INTERNAL(p_BEGIN_DATE, p_END_DATE, p_DATES_ARE_CUT, p_TIME_ZONE);

	-- query service ID list from work table
	SELECT WORK_SEQ -- SERVICE_ID
	BULK COLLECT INTO v_RET
	FROM RTO_WORK
	WHERE WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID;
	-- done
	RETURN v_RET;
END GET_ACTIVE_SERVICES;
-------------------------------------------------------------------------------
-- Retrieves UOM for the cache -- which will have '*' suffix if data must come
-- from SERVICE_LOAD instead of from TX_SUB_STATION_METER_PT_VALUE
-- (only applies to retail account determinants)
FUNCTION GET_INTVL_CACHE_UOM
	(
	p_UOM			IN VARCHAR2,
	p_LOSS_ADJ_TYPE	IN NUMBER
	) RETURN VARCHAR2 AS
BEGIN
	-- units that can be converted from KWH and that need to be adjusted for
	-- losses get special suffix to tell caching logic to only look at SERVICE_LOAD
	-- (which has loss values) and not at channel data
	IF p_UOM IN ('KW', 'MW', 'MWH') AND p_LOSS_ADJ_TYPE IN(c_ADJ_TYPE_LOSS_UFE, c_ADJ_TYPE_LOSSES) THEN
		RETURN p_UOM||'*';
	ELSE
		RETURN p_UOM;
	END IF;
END GET_INTVL_CACHE_UOM;
-------------------------------------------------------------------------------
-- Checks determinants for specified determinant accessor. Caches data in
-- temporary tables if/when not already cached. Returns the determinant status.
-- %param p_ACCESSOR				The account determinant accessor on whose behalf the
--									determinants are queried.
-- %param p_INTERVAL				When this value is ‘Meter Period’, non-interval data
--									will be cached/checked if applicable.
-- %param p_BEGIN_DATE				The begin day of the bill period.
-- %param p_END_DATE				The end day of the bill period.
-- %param p_UOM						The unit of measurement of the determinants to query.
--									May be modified to indicate particular UOM in cache to use.
-- %param p_TEMPLATE_ID				If not Not Assigned, only retrieve results for a particular
--									time of use template.
-- %param p_PERIOD_ID				If neither this nor p_TEMPLATE_ID is Not Assigned, only
--									retrieve results for a particular time of use period.
-- %param p_LOSS_ADJ_TYPE			Type of loss-adjustment, if any, to apply to
--									determinants. This currently only applies to interval
--									metered usage for retail account determinants.
-- %param p_RETURN_STATUS			The status of the determinants used to find the
--									result value: 0 = OK, 1 = Missing (result will be 0),
--									or 2 = Partial. Partial for interval data means that
--									data did not exist for the full date range; for non-
--									interval data, it means that period records that span
--									the entire date range were not found.
-- %param p_CACHE_TABLE				From which cache table(s) must the determinants be
--									queried. If all service IDs for this accessor are
--									non-interval metered and the specified interval is 'Meter
--									Period' this will be 0. If all service IDs for this accessor are
--									interval metered or if the specified interval is *not*
--									'Meter Period' this will be 1. Otherwise, this will be 2
--									(to indicate that both period *and* interval cache tables
--									must be used).
PROCEDURE CHECK_ACCOUNT_DETERMINANTS
	(
	p_ACCESSOR		IN OUT NOCOPY ACCOUNT_DETERMINANT_ACCESSOR,
	p_INTERVAL		IN VARCHAR2,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_UOM			IN OUT VARCHAR2,
	p_TEMPLATE_ID	IN NUMBER,
	p_PERIOD_ID		IN NUMBER,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_OPERATION_CODE IN VARCHAR2 := NULL,
	p_RETURN_STATUS	OUT PLS_INTEGER,
	p_CACHE_TABLE	OUT PLS_INTEGER
	) AS

v_EFF_DATE		        DATE;
v_DET_STATUS	        PLS_INTEGER;
v_BEGIN_DAY		        DATE;
v_END_DAY		        DATE;
v_EDC_HOLIDAY_SET_ID   NUMBER(9,0) := c_NOT_ASSIGNED;
v_METER_IDS            NUMBER_COLLECTION := NUMBER_COLLECTION();
v_COUNT                NUMBER:=1;
v_IS_PERIOD            BOOLEAN:=TRUE;

BEGIN

	GET_ACTIVE_SERVICES_INTERNAL(p_BEGIN_DATE, p_END_DATE,
								IS_SUB_DAILY(p_INTERVAL), p_ACCESSOR.TIME_ZONE);
	p_RETURN_STATUS := NULL;
	p_CACHE_TABLE := NULL;

   -- determine interval for service ID using the period end date
   IF IS_SUB_DAILY(p_INTERVAL) THEN
      v_EFF_DATE := TRUNC(FROM_CUT(p_END_DATE, p_ACCESSOR.TIME_ZONE)-1/86400);
   ELSE
      v_EFF_DATE := p_END_DATE;
   END IF;

   v_EDC_HOLIDAY_SET_ID := GET_ACCOUNT_EDC_HOLIDAY_SET_ID(p_ACCOUNT_ID => p_ACCESSOR.ACCOUNT_ID,
                                                          p_EFFECTIVE_DATE => v_EFF_DATE);
  
  --Get the meter ids
  FOR v_REC IN (SELECT DISTINCT WORK_XID as METER_ID
					FROM RTO_WORK
					WHERE WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID) LOOP
          
          IF NOT g_OBJECT_INFO_CACHE.EXISTS(v_REC.METER_ID) THEN
			       STORE_OBJECT_INFO_FOR_METER(v_REC.METER_ID,
                                     v_EFF_DATE,
                                     v_EDC_HOLIDAY_SET_ID);
          END IF;   
          v_METER_IDS.Extend;                           
          v_METER_IDS(v_COUNT) := v_REC.METER_ID;
          v_COUNT := v_COUNT + 1;
          v_IS_PERIOD := v_IS_PERIOD AND g_OBJECT_INFO_CACHE(v_REC.METER_ID).METER_TYPE = 'Period';
  
  END LOOP;
  IF v_METER_IDS.FIRST IS NULL 
    THEN p_RETURN_STATUS := c_STATUS_MISSING;
         RETURN;
  END IF;       
  --Check it this component is DG6 and is period metered
  --If so we want to look at all the meters at the same time
  IF p_ACCESSOR.COMPONENT_NAME like 'DG6%MIC Surcharge' AND v_IS_PERIOD AND p_INTERVAL = 'Meter Period' THEN 
      v_DET_STATUS := CHECK_SVC_PERIOD_DETERMINANTS(v_METER_IDS, p_ACCESSOR.SERVICE_CODE,
														p_BEGIN_DATE, p_END_DATE, p_UOM,
														p_TEMPLATE_ID, p_PERIOD_ID);
			-- Period cache table includes results
			IF p_CACHE_TABLE IS NULL THEN
				p_CACHE_TABLE := c_CACHE_TABLE_PERIOD;
			ELSIF p_CACHE_TABLE = c_CACHE_TABLE_INTERVAL THEN
				p_CACHE_TABLE := c_CACHE_TABLE_BOTH;
			END IF;
  
     -- Update return status to reflect status of this service ID
		 IF p_RETURN_STATUS IS NULL THEN
			  p_RETURN_STATUS := v_DET_STATUS;
		 ELSIF p_RETURN_STATUS <> c_STATUS_PARTIAL AND p_RETURN_STATUS <> v_DET_STATUS THEN
			  p_RETURN_STATUS := c_STATUS_PARTIAL;
		 END IF;
  --Not DG6 and period metered, so we look at the meters one at a time   
  ELSE
    -- now loop through all services and check each one
    FOR v_REC IN (SELECT DISTINCT WORK_XID as METER_ID
            FROM RTO_WORK
            WHERE WORK_ID = g_PREV_ACTIVE_SVC_WORK_ID) LOOP


      -- Check the appropriate cache
      IF g_OBJECT_INFO_CACHE(v_REC.METER_ID).METER_TYPE = 'Period' AND p_INTERVAL = 'Meter Period' THEN
        v_DET_STATUS := CHECK_SVC_PERIOD_DETERMINANTS(NUMBER_COLLECTION(v_REC.METER_ID), p_ACCESSOR.SERVICE_CODE,
                              p_BEGIN_DATE, p_END_DATE, p_UOM,
                              p_TEMPLATE_ID, p_PERIOD_ID);
        -- Period cache table includes results
        IF p_CACHE_TABLE IS NULL THEN
          p_CACHE_TABLE := c_CACHE_TABLE_PERIOD;
        ELSIF p_CACHE_TABLE = c_CACHE_TABLE_INTERVAL THEN
          p_CACHE_TABLE := c_CACHE_TABLE_BOTH;
        END IF;

      ELSE
        -- Checking whole days
        DAY_RANGE(p_INTERVAL, p_BEGIN_DATE, p_END_DATE, p_ACCESSOR.TIME_ZONE, v_BEGIN_DAY, v_END_DAY);
        v_DET_STATUS := CHECK_SVC_INTVL_DETERMINANTS(v_REC.METER_ID, p_ACCESSOR.SERVICE_CODE,
                              p_ACCESSOR.TIME_ZONE, v_BEGIN_DAY, v_END_DAY,
                              -- look-up appropriate UOM for interval cache
                              GET_INTVL_CACHE_UOM(p_UOM,p_LOSS_ADJ_TYPE),
                              p_TEMPLATE_ID, p_OPERATION_CODE);
        -- Interval cache table includes results
        IF p_CACHE_TABLE IS NULL THEN
          p_CACHE_TABLE := c_CACHE_TABLE_INTERVAL;
        ELSIF p_CACHE_TABLE = c_CACHE_TABLE_PERIOD THEN
          p_CACHE_TABLE := c_CACHE_TABLE_BOTH;
        END IF;
      END IF;

      -- Update return status to reflect status of this service ID
      IF p_RETURN_STATUS IS NULL THEN
        p_RETURN_STATUS := v_DET_STATUS;
      ELSIF p_RETURN_STATUS <> c_STATUS_PARTIAL AND p_RETURN_STATUS <> v_DET_STATUS THEN
        p_RETURN_STATUS := c_STATUS_PARTIAL;
      END IF;

    END LOOP;
  
  END IF;
	p_RETURN_STATUS := NVL(p_RETURN_STATUS, c_STATUS_MISSING); -- no services? then missing determinants

END CHECK_ACCOUNT_DETERMINANTS;
-------------------------------------------------------------------------------
PROCEDURE GET_PEAK_DETERMINANT
	(
	p_ACCESSOR IN OUT NOCOPY ACCOUNT_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEFAULT_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTEGRATION_INTERVAL IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	) IS

v_CACHE_TABLE	PLS_INTEGER;
v_TEMPLATE_ID	TEMPLATE.TEMPLATE_ID%TYPE := NVL(p_TEMPLATE_ID, CONSTANTS.NOT_ASSIGNED);
v_UOM			VARCHAR2(32) := UPPER(p_UOM);
v_LOSS_ADJ_TYPE	NUMBER(1) := NVL(p_LOSS_ADJ_TYPE, c_ADJ_TYPE_NONE);
v_INTVL_UOM		VARCHAR2(32) := GET_INTVL_CACHE_UOM(v_UOM,v_LOSS_ADJ_TYPE); -- look for correct UOM in cache
v_PERIOD_VAL	NUMBER;
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_INTERVAL_VAL	NUMBER;
v_TO_INTERVAL_COUNT INTEGER;
v_ACCOUNT_ESPS  ACCOUNT_ESP_TABLE := ACCOUNT_ESP_TABLE();
BEGIN

	INIT(p_ACCESSOR);

	CHECK_ACCOUNT_DETERMINANTS(p_ACCESSOR, p_INTERVAL, p_BEGIN_DATE, p_END_DATE,
							v_UOM, v_TEMPLATE_ID, p_PERIOD_ID, v_LOSS_ADJ_TYPE, NULL,
							p_RETURN_STATUS, v_CACHE_TABLE);

	IF p_RETURN_STATUS = c_STATUS_MISSING THEN
		p_RETURN_VALUE := 0;
		RETURN;
	END IF;

	-- If there are results in period cache, get them
	IF v_CACHE_TABLE <> c_CACHE_TABLE_INTERVAL THEN
		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Querying period cache for '||TEXT_UTIL.TO_CHAR_DATE(p_BEGIN_DATE)||' ->'
									||TEXT_UTIL.TO_CHAR_DATE(p_END_DATE)||', UOM = '||v_UOM
									||', Template = '||TEXT_UTIL.TO_CHAR_ENTITY(v_TEMPLATE_ID,EC.ED_TEMPLATE)
									||', Period = '||TEXT_UTIL.TO_CHAR_ENTITY(p_PERIOD_ID,EC.ED_PERIOD));
		END IF;

		SELECT SUM(PEAK)
		INTO v_PERIOD_VAL
		FROM (SELECT MAX(DEMAND) as PEAK
				FROM DETERMINANT_CACHE_PERIOD
				WHERE UOM = v_UOM
					AND TEMPLATE_ID = v_TEMPLATE_ID
					AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
					AND BEGIN_DATE BETWEEN (p_BEGIN_DATE - GA.DETERMINANT_DATE_THRESHOLD) AND p_END_DATE
					AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
				GROUP BY OBJECT_ID);

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Peak value = '||v_PERIOD_VAL);
		END IF;
	END IF;

	-- If there are results in interval cache, get those as well
	IF v_CACHE_TABLE <> c_CACHE_TABLE_PERIOD THEN
		-- Get proper date range for query
		INTERVAL_QUERY_DATE_RANGE(v_INTVL_UOM, p_INTERVAL, p_BEGIN_DATE, p_END_DATE, p_ACCESSOR.TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Querying interval cache for '||TEXT_UTIL.TO_CHAR_TIME(v_BEGIN_DATE)||' ->'
									||TEXT_UTIL.TO_CHAR_TIME(v_END_DATE)||', UOM = '||v_INTVL_UOM
									||', Template = '||TEXT_UTIL.TO_CHAR_ENTITY(v_TEMPLATE_ID,EC.ED_TEMPLATE)
									||', Period = '||TEXT_UTIL.TO_CHAR_ENTITY(p_PERIOD_ID,EC.ED_PERIOD));
		END IF;

		IF (IS_VALID_INTEGRATION_INTERVAL(p_INTEGRATION_INTERVAL) AND (p_INTEGRATION_INTERVAL IS NOT NULL) AND (IS_SUB_DAILY(p_INTEGRATION_INTERVAL))) THEN
		    -- Get the number of intervals in the day for the p_INTEGRATION_INTERVAL
			v_TO_INTERVAL_COUNT := GET_NUM_OF_SUBDAILY_INTERVALS(p_INTEGRATION_INTERVAL);

			-- F55.U09 -- To support ACCOUNT_STATUS Subdaily
			IF GA.CSB_IS_SUBDAILY THEN
				-- Identify the ESP that should be part of this call for the invoice_line_item
			   SELECT ACCOUNT_ESP_TYPE(
			   						  A.ACCOUNT_ID,
									  A.ESP_ID,
									  A.POOL_ID,
									  A.BEGIN_DATE,
									  A.END_DATE,
									  A.ESP_ACCOUNT_NUMBER,
									  A.ENTRY_DATE
					  )
			   BULK COLLECT INTO v_ACCOUNT_ESPs
			   FROM
				(
					SELECT AESP.ACCOUNT_ID,
					  AESP.ESP_ID,
					  AESP.POOL_ID,
					  GREATEST(AESP.BEGIN_DATE, v_BEGIN_DATE)  AS BEGIN_DATE,
					  LEAST(NVL(AESP.END_DATE, v_END_DATE), v_END_DATE) AS END_DATE,
					  AESP.ESP_ACCOUNT_NUMBER,
					  AESP.ENTRY_DATE
					FROM ACCOUNT_ESP AESP
					WHERE AESP.ACCOUNT_ID = p_ACCESSOR.ACCOUNT_ID
                      AND AESP.ESP_ID = p_ACCESSOR.ESP_ID
					  AND AESP.BEGIN_DATE <= v_END_DATE
					  AND NVL(AESP.END_DATE, v_END_DATE) >= v_BEGIN_DATE
				)A;

				-- Integrate the interval data based on the Grouping Number
				-- We only support integrating the peak values when the interval is sub-daily.
				SELECT MAX(TOTAL)
				INTO v_INTERVAL_VAL
				FROM (SELECT AVG(LOAD_VAL
							 + CASE WHEN v_LOSS_ADJ_TYPE > 0 THEN LOSS_VAL ELSE 0 END
							 + CASE WHEN v_LOSS_ADJ_TYPE > 1 THEN UFE_VAL ELSE 0 END) as TOTAL, INTEGRAND_GROUPING
						FROM (SELECT LOAD_VAL,
									 LOSS_VAL,
									 UFE_VAL,
									 LOAD_DATE,
									 CEIL((LOAD_DATE - p_BEGIN_DATE) * v_TO_INTERVAL_COUNT) AS INTEGRAND_GROUPING
						FROM DETERMINANT_CACHE_INTERVAL, ACCOUNT_STATUS B, TABLE(CAST(v_ACCOUNT_ESPS AS ACCOUNT_ESP_TABLE)) C
						WHERE UOM = v_INTVL_UOM
							AND TEMPLATE_ID = v_TEMPLATE_ID
							AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
							AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
							AND p_ACCESSOR.ACCOUNT_ID = B.ACCOUNT_ID
							AND B.STATUS_NAME = 'Active'
		                	AND LOAD_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE)
							AND p_ACCESSOR.ACCOUNT_ID = C.ACCOUNT_ID									 -- Join with ACCOUNT_ESP
							AND p_ACCESSOR.ESP_ID = C.ESP_ID									         -- Join with ACCOUNT_ESP
							AND LOAD_DATE BETWEEN C.BEGIN_DATE AND NVL(C.END_DATE, CONSTANTS.HIGH_DATE)  -- Join with ACCOUNT_ESP
						)
						GROUP BY INTEGRAND_GROUPING);
			ELSE -- this is Daily
				-- Integrate the interval data based on the Grouping Number
				-- We only support integrating the peak values when the interval is sub-daily.
				SELECT MAX(TOTAL)
				INTO v_INTERVAL_VAL
				FROM (SELECT AVG(LOAD_VAL
							 + CASE WHEN v_LOSS_ADJ_TYPE > 0 THEN LOSS_VAL ELSE 0 END
							 + CASE WHEN v_LOSS_ADJ_TYPE > 1 THEN UFE_VAL ELSE 0 END) as TOTAL, INTEGRAND_GROUPING
						FROM (SELECT LOAD_VAL,
									 LOSS_VAL,
									 UFE_VAL,
									 LOAD_DATE,
									 CEIL((LOAD_DATE - p_BEGIN_DATE) * v_TO_INTERVAL_COUNT) AS INTEGRAND_GROUPING
						FROM DETERMINANT_CACHE_INTERVAL
						WHERE UOM = v_INTVL_UOM
							AND TEMPLATE_ID = v_TEMPLATE_ID
							AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
							AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE)
						GROUP BY INTEGRAND_GROUPING);
			END IF;
		ELSE
			-- F55.U09 -- To support ACCOUNT_STATUS Subdaily
			IF GA.CSB_IS_SUBDAILY THEN
				-- Identify the ESP that should be part of this call for the invoice_line_item
			   SELECT ACCOUNT_ESP_TYPE(
			   						  A.ACCOUNT_ID,
									  A.ESP_ID,
									  A.POOL_ID,
									  A.BEGIN_DATE,
									  A.END_DATE,
									  A.ESP_ACCOUNT_NUMBER,
									  A.ENTRY_DATE
					  )
			   BULK COLLECT INTO v_ACCOUNT_ESPs
			   FROM
				(
					SELECT AESP.ACCOUNT_ID,
					  AESP.ESP_ID,
					  AESP.POOL_ID,
					  GREATEST(AESP.BEGIN_DATE, v_BEGIN_DATE)  AS BEGIN_DATE,
					  LEAST(NVL(AESP.END_DATE, v_END_DATE), v_END_DATE) AS END_DATE,
					  AESP.ESP_ACCOUNT_NUMBER,
					  AESP.ENTRY_DATE
					FROM ACCOUNT_ESP AESP
					WHERE AESP.ACCOUNT_ID = p_ACCESSOR.ACCOUNT_ID
                      AND AESP.ESP_ID = p_ACCESSOR.ESP_ID
					  AND AESP.BEGIN_DATE <= v_END_DATE
					  AND NVL(AESP.END_DATE, v_END_DATE) >= v_BEGIN_DATE
				)A;

				-- Just get the peak
				SELECT MAX(TOTAL)
				INTO v_INTERVAL_VAL
				FROM (SELECT SUM(LOAD_VAL
								 + CASE WHEN v_LOSS_ADJ_TYPE > 0 THEN LOSS_VAL ELSE 0 END
								 + CASE WHEN v_LOSS_ADJ_TYPE > 1 THEN UFE_VAL ELSE 0 END) as TOTAL
						FROM DETERMINANT_CACHE_INTERVAL, ACCOUNT_STATUS B, TABLE(CAST(v_ACCOUNT_ESPS AS ACCOUNT_ESP_TABLE)) C
						WHERE UOM = v_INTVL_UOM
						  AND TEMPLATE_ID = v_TEMPLATE_ID
						  AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
						  AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
						  AND p_ACCESSOR.ACCOUNT_ID = B.ACCOUNT_ID
						  AND B.STATUS_NAME = 'Active'
						  AND LOAD_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE)
						  AND p_ACCESSOR.ACCOUNT_ID = C.ACCOUNT_ID									-- Join with ACCOUNT_ESP
						  AND p_ACCESSOR.ESP_ID = C.ESP_ID       									-- Join with ACCOUNT_ESP
						  AND LOAD_DATE BETWEEN C.BEGIN_DATE AND NVL(C.END_DATE, CONSTANTS.HIGH_DATE)
						GROUP BY LOAD_DATE
						);
			ELSE -- This is daily
				-- Just get the peak
				SELECT MAX(TOTAL)
				INTO v_INTERVAL_VAL
				FROM (SELECT SUM(LOAD_VAL
								 + CASE WHEN v_LOSS_ADJ_TYPE > 0 THEN LOSS_VAL ELSE 0 END
								 + CASE WHEN v_LOSS_ADJ_TYPE > 1 THEN UFE_VAL ELSE 0 END) as TOTAL
						FROM DETERMINANT_CACHE_INTERVAL
						WHERE UOM = v_INTVL_UOM
							AND TEMPLATE_ID = v_TEMPLATE_ID
							AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
							AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
						GROUP BY LOAD_DATE);
			END IF;
		END IF;

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Peak value = '||v_INTERVAL_VAL);
		END IF;
	END IF;

	-- Return the sum of these two values
	p_RETURN_VALUE := NVL(v_PERIOD_VAL,0) + NVL(v_INTERVAL_VAL,0);

END GET_PEAK_DETERMINANT;
-------------------------------------------------------------------------------
PROCEDURE GET_SUM_DETERMINANTS
	(
	p_ACCESSOR IN OUT NOCOPY ACCOUNT_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEFAULT_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTERVAL_MINIMUM_QTY IN NUMBER := NULL,
	p_OPERATION_CODE IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	) IS

v_CACHE_TABLE	PLS_INTEGER;
v_TEMPLATE_ID	TEMPLATE.TEMPLATE_ID%TYPE := NVL(p_TEMPLATE_ID, CONSTANTS.NOT_ASSIGNED);
v_UOM			VARCHAR2(32) := UPPER(p_UOM);
v_LOSS_ADJ_TYPE	NUMBER(1) := NVL(p_LOSS_ADJ_TYPE, c_ADJ_TYPE_NONE);
v_INTVL_UOM		VARCHAR2(32) := GET_INTVL_CACHE_UOM(v_UOM,v_LOSS_ADJ_TYPE); -- look for correct UOM in cache
v_PERIOD_VAL	NUMBER;
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_INTERVAL_VAL	NUMBER;
v_LOAD_BEGIN_DATE 	DATE;
v_LOAD_END_DATE 	DATE;
v_ACCOUNT_ESPS  ACCOUNT_ESP_TABLE := ACCOUNT_ESP_TABLE();

BEGIN
	INIT(p_ACCESSOR);

	CHECK_ACCOUNT_DETERMINANTS(p_ACCESSOR, p_INTERVAL, p_BEGIN_DATE, p_END_DATE,
							v_UOM, v_TEMPLATE_ID, p_PERIOD_ID, v_LOSS_ADJ_TYPE, p_OPERATION_CODE,
							p_RETURN_STATUS, v_CACHE_TABLE);

	IF p_RETURN_STATUS = c_STATUS_MISSING THEN
		p_RETURN_VALUE := 0;
		RETURN;
	END IF;

	-- If there are results in period cache, get them
	IF v_CACHE_TABLE <> c_CACHE_TABLE_INTERVAL THEN
		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Querying period cache for '||TEXT_UTIL.TO_CHAR_DATE(p_BEGIN_DATE)||' ->'
									||TEXT_UTIL.TO_CHAR_DATE(p_END_DATE)||', UOM = '||v_UOM
									||', Template = '||TEXT_UTIL.TO_CHAR_ENTITY(v_TEMPLATE_ID,EC.ED_TEMPLATE)
									||', Period = '||TEXT_UTIL.TO_CHAR_ENTITY(p_PERIOD_ID,EC.ED_PERIOD));
		END IF;

		SELECT SUM(ENERGY)
		INTO v_PERIOD_VAL
		FROM DETERMINANT_CACHE_PERIOD
		WHERE UOM = v_UOM
			AND TEMPLATE_ID = v_TEMPLATE_ID
			AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
			AND BEGIN_DATE BETWEEN (p_BEGIN_DATE - GA.DETERMINANT_DATE_THRESHOLD) AND p_END_DATE
			AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE;

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Sum value = '||v_PERIOD_VAL);
		END IF;
	END IF;

	-- If there are results in interval cache, get those as well
	IF v_CACHE_TABLE <> c_CACHE_TABLE_PERIOD THEN
		-- Get proper date range for query
		INTERVAL_QUERY_DATE_RANGE(v_INTVL_UOM, p_INTERVAL, p_BEGIN_DATE, p_END_DATE, p_ACCESSOR.TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Querying interval cache for '||TEXT_UTIL.TO_CHAR_TIME(v_BEGIN_DATE)||' ->'
									||TEXT_UTIL.TO_CHAR_TIME(v_END_DATE)||', UOM = '||v_INTVL_UOM
									||', Template = '||TEXT_UTIL.TO_CHAR_ENTITY(v_TEMPLATE_ID,EC.ED_TEMPLATE)
									||', Period = '||TEXT_UTIL.TO_CHAR_ENTITY(p_PERIOD_ID,EC.ED_PERIOD)
									||', OperationCode = '||p_OPERATION_CODE);
			LOGS.LOG_DEBUG_DETAIL('Interval Minimum Quantity = ' || p_INTERVAL_MINIMUM_QTY);

		    LOGS.LOG_DEBUG_DETAIL('ACCOUNT_ID (from the ACCOUNT_DETERMINANT_ACCESSOR) = ' || p_ACCESSOR.ACCOUNT_ID);
		    LOGS.LOG_DEBUG_DETAIL('ESP_ID (from the ACCOUNT_DETERMINANT_ACCESSOR) = ' || p_ACCESSOR.ESP_ID);
		END IF;

		-- F55.U09 -- To support ACCOUNT_STATUS Subdaily
		IF GA.CSB_IS_SUBDAILY THEN
           -- Identify the ESP that should be part of this call for the invoice_line_item
           SELECT ACCOUNT_ESP_TYPE(
                                  A.ACCOUNT_ID,
                                  A.ESP_ID,
                                  A.POOL_ID,
                                  A.BEGIN_DATE,
                                  A.END_DATE,
                                  A.ESP_ACCOUNT_NUMBER,
                                  A.ENTRY_DATE
                  )
           BULK COLLECT INTO v_ACCOUNT_ESPs
           FROM
            (
                SELECT AESP.ACCOUNT_ID,
                  AESP.ESP_ID,
                  AESP.POOL_ID,
                  GREATEST(AESP.BEGIN_DATE, v_BEGIN_DATE)  AS BEGIN_DATE,
                  LEAST(NVL(AESP.END_DATE, v_END_DATE), v_END_DATE) AS END_DATE,
                  AESP.ESP_ACCOUNT_NUMBER,
                  AESP.ENTRY_DATE
                FROM ACCOUNT_ESP AESP
                WHERE AESP.ACCOUNT_ID = p_ACCESSOR.ACCOUNT_ID
                  AND AESP.ESP_ID = p_ACCESSOR.ESP_ID
                  AND AESP.BEGIN_DATE <= v_END_DATE
                  AND NVL(AESP.END_DATE, v_END_DATE) >= v_BEGIN_DATE
            )A;


			LOGS.LOG_DEBUG_DETAIL('CSB is Subdaily. Determinant cache date-range will be constricted.');
			LOGS.LOG_DEBUG_DETAIL('ACCOUNT_ID (from the ACCOUNT_DETERMINANT_ACCESSOR) = ' || p_ACCESSOR.ACCOUNT_ID);

			SELECT CASE
						WHEN p_INTERVAL_MINIMUM_QTY IS NOT NULL THEN
							SUM(GREATEST(LOAD_VAL
									+ CASE WHEN v_LOSS_ADJ_TYPE <> c_ADJ_TYPE_NONE AND p_OPERATION_CODE IS NULL THEN LOSS_VAL ELSE 0 END
									+ CASE WHEN v_LOSS_ADJ_TYPE = c_ADJ_TYPE_LOSS_UFE AND p_OPERATION_CODE IS NULL THEN UFE_VAL ELSE 0 END
								   ,p_INTERVAL_MINIMUM_QTY))
						ELSE
							SUM(LOAD_VAL
								+ CASE WHEN v_LOSS_ADJ_TYPE <> c_ADJ_TYPE_NONE AND p_OPERATION_CODE IS NULL THEN LOSS_VAL ELSE 0 END
								+ CASE WHEN v_LOSS_ADJ_TYPE = c_ADJ_TYPE_LOSS_UFE AND p_OPERATION_CODE IS NULL THEN UFE_VAL ELSE 0 END)
						END,
					MIN(LOAD_DATE), MAX(LOAD_DATE)
			INTO v_INTERVAL_VAL, v_LOAD_BEGIN_DATE, v_LOAD_END_DATE
			FROM DETERMINANT_CACHE_INTERVAL, ACCOUNT_STATUS B, TABLE(CAST(v_ACCOUNT_ESPS AS ACCOUNT_ESP_TABLE)) c
			WHERE UOM = v_INTVL_UOM
				AND TEMPLATE_ID = v_TEMPLATE_ID
				AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
				AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
				AND ((p_OPERATION_CODE IS NULL AND OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND OPERATION_CODE = p_OPERATION_CODE))
				AND p_ACCESSOR.ACCOUNT_ID = B.ACCOUNT_ID
				AND B.STATUS_NAME = 'Active'
				AND LOAD_DATE BETWEEN B.BEGIN_DATE AND NVL(B.END_DATE, CONSTANTS.HIGH_DATE)
				AND p_ACCESSOR.ACCOUNT_ID = C.ACCOUNT_ID
                AND p_ACCESSOR.ESP_ID = C.ESP_ID
				-- Join with the ACCOUNT_ESP
				AND LOAD_DATE BETWEEN C.BEGIN_DATE AND C.END_DATE;


			LOGS.LOG_DEBUG_DETAIL('DETERMINANT_CACHE_INTERVAL LOAD_BEGIN_DATE = ' || TEXT_UTIL.TO_CHAR_TIME(v_LOAD_BEGIN_DATE) ||
								  ' and LOAD_END_DATE = ' || TEXT_UTIL.TO_CHAR_TIME(v_LOAD_END_DATE));
		ELSE -- this is Daily
			SELECT CASE
						WHEN p_INTERVAL_MINIMUM_QTY IS NOT NULL THEN
							SUM(GREATEST(LOAD_VAL
									+ CASE WHEN v_LOSS_ADJ_TYPE <> c_ADJ_TYPE_NONE AND p_OPERATION_CODE IS NULL THEN LOSS_VAL ELSE 0 END
									+ CASE WHEN v_LOSS_ADJ_TYPE = c_ADJ_TYPE_MTR_PT_LOSSES AND p_OPERATION_CODE IS NOT NULL THEN LOSS_VAL ELSE 0 END
									+ CASE WHEN v_LOSS_ADJ_TYPE = c_ADJ_TYPE_LOSS_UFE AND p_OPERATION_CODE IS NULL THEN UFE_VAL ELSE 0 END
								   ,p_INTERVAL_MINIMUM_QTY))
						ELSE
							SUM(LOAD_VAL
								+ CASE WHEN v_LOSS_ADJ_TYPE <> c_ADJ_TYPE_NONE AND p_OPERATION_CODE IS NULL THEN LOSS_VAL ELSE 0 END
								+ CASE WHEN v_LOSS_ADJ_TYPE = c_ADJ_TYPE_MTR_PT_LOSSES AND p_OPERATION_CODE IS NOT NULL THEN LOSS_VAL ELSE 0 END
								+ CASE WHEN v_LOSS_ADJ_TYPE = c_ADJ_TYPE_LOSS_UFE AND p_OPERATION_CODE IS NULL THEN UFE_VAL ELSE 0 END)
						END
			INTO v_INTERVAL_VAL
			FROM DETERMINANT_CACHE_INTERVAL
			WHERE UOM = v_INTVL_UOM
				AND TEMPLATE_ID = v_TEMPLATE_ID
				AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
				AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
				AND ((p_OPERATION_CODE IS NULL AND OPERATION_CODE IS NULL) OR (p_OPERATION_CODE IS NOT NULL AND OPERATION_CODE = p_OPERATION_CODE));
		END IF;

		IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_DETAIL('Sum value = '||v_INTERVAL_VAL);
		END IF;

	END IF;

	-- Return the sum of these two values
	p_RETURN_VALUE := NVL(v_PERIOD_VAL,0) + NVL(v_INTERVAL_VAL,0);

END GET_SUM_DETERMINANTS;
-------------------------------------------------------------------------------
FUNCTION GET_POD_DETERMINANT_ACCESSOR
	(
	p_SERVICE_POINT_ID	IN NUMBER,
	p_PSE_ID			IN NUMBER,
	p_METER_TYPE		IN VARCHAR2,
	p_STATEMENT_TYPE_ID	IN NUMBER,
	p_TIME_ZONE			IN VARCHAR2
	) RETURN POD_DETERMINANT_ACCESSOR IS
BEGIN

	RETURN POD_DETERMINANT_ACCESSOR(
						p_SERVICE_POINT_ID,
						p_PSE_ID,
						p_METER_TYPE,
						p_STATEMENT_TYPE_ID,
						p_TIME_ZONE
						);

END GET_POD_DETERMINANT_ACCESSOR;
-------------------------------------------------------------------------------
PROCEDURE INIT
	(
	p_ACCESSOR IN POD_DETERMINANT_ACCESSOR
	) AS
BEGIN
	IF g_CACHE_TYPE IS NULL OR g_CACHE_TYPE <> c_CACHE_TYPE_POD OR
		g_LAST_SERVICE_POINT_ID <> p_ACCESSOR.SERVICE_POINT_ID OR g_LAST_PSE_ID <> p_ACCESSOR.PSE_ID OR
		g_LAST_METER_TYPE <> p_ACCESSOR.METER_TYPE OR g_LAST_STATEMENT_TYPE_ID <> p_ACCESSOR.STATEMENT_TYPE_ID OR
		g_LAST_TIME_ZONE <> p_ACCESSOR.TIME_ZONE THEN

		-- Different accessor than last used? clear the cache and reset package variables
		g_CACHE_TYPE := c_CACHE_TYPE_POD;

		CLEAR_CACHE;

		g_LAST_SERVICE_POINT_ID := p_ACCESSOR.SERVICE_POINT_ID;
		g_LAST_PSE_ID := p_ACCESSOR.PSE_ID;
		g_LAST_METER_TYPE := p_ACCESSOR.METER_TYPE;
		g_LAST_STATEMENT_TYPE_ID := p_ACCESSOR.STATEMENT_TYPE_ID;
		g_LAST_TIME_ZONE := p_ACCESSOR.TIME_ZONE;
		g_LAST_SVC_WORK_ID	:= NULL;

		IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
			LOGS.LOG_DEBUG_MORE_DETAIL('Initializing for POD accessor...');
			LOGS.LOG_DEBUG_MORE_DETAIL('  Service Point ID = '||p_ACCESSOR.SERVICE_POINT_ID||' ('||TEXT_UTIL.TO_CHAR_ENTITY(p_ACCESSOR.SERVICE_POINT_ID,EC.ED_SERVICE_POINT));
			LOGS.LOG_DEBUG_MORE_DETAIL('  PSE ID = '||p_ACCESSOR.PSE_ID||' ('||TEXT_UTIL.TO_CHAR_ENTITY(p_ACCESSOR.PSE_ID,EC.ED_PSE));
			LOGS.LOG_DEBUG_MORE_DETAIL('  Meter Type = '||p_ACCESSOR.METER_TYPE);
			LOGS.LOG_DEBUG_MORE_DETAIL('  Statement TYpe ID = '||p_ACCESSOR.STATEMENT_TYPE_ID||' ('||TEXT_UTIL.TO_CHAR_ENTITY(p_ACCESSOR.STATEMENT_TYPE_ID,EC.ED_STATEMENT_TYPE));
			LOGS.LOG_DEBUG_MORE_DETAIL('  Time Zone = '||p_ACCESSOR.TIME_ZONE);
		END IF;

	END IF;
END INIT;
-------------------------------------------------------------------------------
PROCEDURE STORE_OBJECT_INFO_FOR_TXN
	(
	p_TRANSACTION_ID IN NUMBER,
   p_EDC_HOLIDAY_SET_ID IN NUMBER
	) IS
BEGIN

	-- Set interval info
	SELECT TRANSACTION_INTERVAL,
          p_EDC_HOLIDAY_SET_ID
	  INTO g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL,
          g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).EDC_HOLIDAY_SET_ID
	  FROM INTERCHANGE_TRANSACTION
	 WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL_ORD := DATE_UTIL.INTERVAL_ORD(g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL);

END STORE_OBJECT_INFO_FOR_TXN;
-------------------------------------------------------------------------------
PROCEDURE GET_TXN_UOM_CONVERSION_FACTOR
	(
	p_UOM IN VARCHAR2,
	p_INTERVAL IN VARCHAR2,
	p_NEW_UOM OUT VARCHAR2,
	p_SCALE_FACTOR OUT NUMBER
	) AS
BEGIN
	-- Try to find conversion factors to "typical" schedule units of measure - to MWH and DTH
	-- Don't go the other way (like converting MWH to MW) since that could cause problems
	-- with infinite recursion in POPULATE_INTERVAL_CACHE_TXN where it uses circular recursion
	-- in an attempt to calculate/derive additional units of measure.
	CASE p_UOM
	WHEN 'MW' THEN
		p_NEW_UOM := 'MWH';
		p_SCALE_FACTOR := DATE_UTIL.GET_INTERVAL_DIVISOR('Hour', p_INTERVAL);
	WHEN 'KWH' THEN
		p_NEW_UOM := 'MWH';
		p_SCALE_FACTOR := 1000;
	WHEN 'KW' THEN
		p_NEW_UOM := 'MWH';
		p_SCALE_FACTOR := 1000 * DATE_UTIL.GET_INTERVAL_DIVISOR('Hour', p_INTERVAL);
	WHEN 'THM' THEN
		p_NEW_UOM := 'DTH';
		p_SCALE_FACTOR := 10;
	WHEN 'TH' THEN -- alias of Thm - this abbreviation is generally improper as
					-- it could be confused with thermie (<> therm)
		p_NEW_UOM := 'DTH';
		p_SCALE_FACTOR := 10;
	ELSE
		-- cannot convert
		p_NEW_UOM := NULL;
	END CASE;
END GET_TXN_UOM_CONVERSION_FACTOR;
-------------------------------------------------------------------------------
-- Forward declaration to support circular nature of POPULATE_INTERVAL_CACHE_TXN
-- and CACHE_TRANSACTION_DETERMINANTS.
-- See full function below.
FUNCTION CACHE_TRANSACTION_DETERMINANTS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2,
	p_TEMPLATE_ID IN NUMBER
	) RETURN PLS_INTEGER;
-------------------------------------------------------------------------------
-- Queries data from IT_SCHEDULE and inserts into the interval
-- determinant cache table.
-- %param p_TRANSACTION_ID		The Transaction ID whose interval data is being
--								cached.
-- %param p_STATEMENT_TYPE_ID	The Statement Type of interval data being
--								cached.
-- %param p_TIME_ZONE			The time zone, used to define which intervals
--								comprise a day.
-- %param p_BEGIN_DATE			The begin day of the bill period.
-- %param p_END_DATE			The end day of the bill period.
-- %param p_UOM					The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID			If not NULL, use specified TOU Template to identify
--								interval data with Period IDs.
-- %return						Count of records stored in the cache table.
FUNCTION POPULATE_INTERVAL_CACHE_TXN
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2,
	p_TEMPLATE_ID IN NUMBER
	) RETURN PLS_INTEGER IS
-- All DML (to cache tables) is done in autonomous transaction since this could be called
-- from SQL (like from a formula)
PRAGMA AUTONOMOUS_TRANSACTION;

v_BEGIN_DATE	      DATE;
v_END_DATE		      DATE;
v_COUNT			      PLS_INTEGER;
v_SCALE			      NUMBER;
v_EDC_HOLIDAY_SET_ID NUMBER := NVL(g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).EDC_HOLIDAY_SET_ID,c_ALL_HOLIDAY_SET);

BEGIN
	-- Determine proper date range for query
	DETERMINANT_ACCESSOR_DATES(g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL,
								p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	IF p_UOM = UPPER(GA.DEF_SCHED_UNIT_OF_MEASUREMENT) THEN
		IF p_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED THEN
			-- no need to identify periods
			INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, LOAD_VAL, LOSS_VAL, UFE_VAL)
			SELECT p_TRANSACTION_ID, p_UOM, p_TEMPLATE_ID, SCHEDULE_DATE, NULL, NVL(AMOUNT,0), 0, 0
			FROM IT_SCHEDULE
			WHERE TRANSACTION_ID = p_TRANSACTION_ID
				AND SCHEDULE_TYPE = p_STATEMENT_TYPE_ID
				AND SCHEDULE_STATE = GA.INTERNAL_STATE
				AND AS_OF_DATE = CONSTANTS.LOW_DATE -- versioning not supported
				-- add one second since Scheduling stores day values as 1-sec past midnight
				AND SCHEDULE_DATE BETWEEN v_BEGIN_DATE+1/86400 AND v_END_DATE+1/86400;

			v_COUNT := SQL%ROWCOUNT;
			COMMIT;
			RETURN v_COUNT;
		ELSE
			-- identify periods for specified template using TEMPLATE_DATES tables/structures
			INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, LOAD_VAL, LOSS_VAL, UFE_VAL)
			SELECT p_TRANSACTION_ID, p_UOM, p_TEMPLATE_ID, ITS.SCHEDULE_DATE, TDP.PERIOD_ID, NVL(ITS.AMOUNT,0), 0, 0
			FROM IT_SCHEDULE ITS,
				TEMPLATE_DATES TD,
				TEMPLATE_DAY_TYPE_PERIOD TDP
			WHERE ITS.TRANSACTION_ID = p_TRANSACTION_ID
				AND ITS.SCHEDULE_TYPE = p_STATEMENT_TYPE_ID
				AND ITS.SCHEDULE_STATE = GA.INTERNAL_STATE
				AND ITS.AS_OF_DATE = CONSTANTS.LOW_DATE -- versioning not supported
				-- add one second since Scheduling stores day values as 1-sec past midnight
				AND ITS.SCHEDULE_DATE BETWEEN v_BEGIN_DATE+1/86400 AND v_END_DATE+1/86400
				AND TD.TIME_ZONE = p_TIME_ZONE
				AND TD.TEMPLATE_ID = p_TEMPLATE_ID
				AND TD.HOLIDAY_SET_ID = v_EDC_HOLIDAY_SET_ID
				AND TD.CUT_BEGIN_DATE < ITS.SCHEDULE_DATE
				AND TD.CUT_END_DATE >= ITS.SCHEDULE_DATE
				AND TDP.DAY_TYPE_ID = TD.DAY_TYPE_ID
				AND TDP.TIME_STAMP = ITS.SCHEDULE_DATE - TD.CUT_BEGIN_DATE;

			v_COUNT := SQL%ROWCOUNT;
			COMMIT;
			RETURN v_COUNT;
		END IF;

	-- can we calculate specified unit of measure?
	ELSE
		DECLARE
			v_UOM	VARCHAR2(16);
		BEGIN
			GET_TXN_UOM_CONVERSION_FACTOR(p_UOM, g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL, v_UOM, v_SCALE);

			IF v_UOM IS NOT NULL THEN
				v_COUNT := CACHE_TRANSACTION_DETERMINANTS(p_TRANSACTION_ID, p_STATEMENT_TYPE_ID, p_TIME_ZONE, p_BEGIN_DATE, p_END_DATE, v_UOM, p_TEMPLATE_ID);
				-- Convert
				INSERT INTO DETERMINANT_CACHE_INTERVAL (OBJECT_ID, UOM, TEMPLATE_ID, LOAD_DATE, PERIOD_ID, LOAD_VAL, LOSS_VAL, UFE_VAL)
				SELECT p_TRANSACTION_ID, p_UOM, p_TEMPLATE_ID, LOAD_DATE, PERIOD_ID, LOAD_VAL * v_SCALE, LOSS_VAL * v_SCALE, UFE_VAL * v_SCALE
				FROM DETERMINANT_CACHE_INTERVAL
				WHERE OBJECT_ID = p_TRANSACTION_ID
					AND UOM = UPPER(v_UOM)
					AND TEMPLATE_ID = p_TEMPLATE_ID
					AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

				v_COUNT := v_COUNT + SQL%ROWCOUNT;
				COMMIT;
				RETURN v_COUNT;

			ELSE
				-- can't calculate it - nothing we can do
				COMMIT;
				RETURN 0;

			END IF;
		END;
	END IF;
END POPULATE_INTERVAL_CACHE_TXN;
-------------------------------------------------------------------------------
-- Queries data from IT_SCHEDULE and inserts into the interval
-- determinant cache table if necessary.
-- %param p_TRANSACTION_ID		The Transaction ID whose interval data is being
--								cached.
-- %param p_STATEMENT_TYPE_ID	The Statement Type of interval data being
--								cached.
-- %param p_TIME_ZONE			The time zone, used to define which intervals
--								comprise a day.
-- %param p_BEGIN_DATE			The begin day of the bill period.
-- %param p_END_DATE			The end day of the bill period.
-- %param p_UOM					The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID			If not NULL, use specified TOU Template to identify
--								interval data with Period IDs.
-- %return						Count of records stored in the cache table.
FUNCTION CACHE_TRANSACTION_DETERMINANTS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2,
	p_TEMPLATE_ID IN NUMBER
	) RETURN PLS_INTEGER IS

v_START_DATE_TO_CACHE	DATE;
v_DATE					DATE;
v_KEY					VARCHAR2(40);
v_BEGIN_DATE			DATE;
v_END_DATE				DATE;
v_RECORDS_STORED		PLS_INTEGER := 0;

	------------------------------------------------------------------------
	-- populate temp tables through specified date and update
	-- package structures
	PROCEDURE POPULATE_CACHE(p_THROUGH_DATE IN DATE) AS
	v_DATE	DATE;
	v_KEY	VARCHAR2(40);
	v_ORD	PLS_INTEGER := g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL_ORD;
	BEGIN
		v_RECORDS_STORED := v_RECORDS_STORED +
							POPULATE_INTERVAL_CACHE_TXN(p_TRANSACTION_ID, p_STATEMENT_TYPE_ID, p_TIME_ZONE,
												v_START_DATE_TO_CACHE, p_THROUGH_DATE, p_UOM, p_TEMPLATE_ID);
		v_DATE := v_START_DATE_TO_CACHE;
		WHILE v_DATE <= p_THROUGH_DATE LOOP
			-- make sure we have an entry in the cache def
			v_KEY := INTERVAL_CACHE_KEY(p_TRANSACTION_ID, p_UOM, v_DATE);
			g_INTERVAL_CACHE_DEF(v_KEY)(p_TEMPLATE_ID) := NULL;
			v_DATE := v_DATE+1;
		END LOOP;
		v_START_DATE_TO_CACHE := NULL;
		-- make sure cache granularity is up-to-date
		UPDATE_INTERVAL_CACHE_GRAN(c_POD_CACHE_GRAN_KEY, v_ORD);
	END POPULATE_CACHE;
	------------------------------------------------------------------------
BEGIN
	v_START_DATE_TO_CACHE := NULL;
	-- Loop over each day
	v_DATE := p_BEGIN_DATE;
	WHILE v_DATE <= p_END_DATE LOOP
		v_KEY := INTERVAL_CACHE_KEY(p_TRANSACTION_ID, p_UOM, v_DATE);
		-- missing?
		IF NOT g_INTERVAL_CACHE_DEF.EXISTS(v_KEY) THEN
			-- setup date range to store to cache
			IF v_START_DATE_TO_CACHE IS NULL THEN
				v_START_DATE_TO_CACHE := v_DATE;
			END IF;
		ELSE
			-- flush range of missing days to the temp table
			IF v_START_DATE_TO_CACHE IS NOT NULL THEN
				POPULATE_CACHE(v_DATE-1);
			END IF;
			-- populated for correct template?
			IF NOT g_INTERVAL_CACHE_DEF(v_KEY).EXISTS(p_TEMPLATE_ID) THEN
				-- if not, copy data from another template (use first template in the cache def)
				DETERMINANT_ACCESSOR_DATES(g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL,
											v_DATE, v_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
				v_RECORDS_STORED := v_RECORDS_STORED + COPY_INTERVAL_CACHE(p_TRANSACTION_ID, p_UOM,
																	g_INTERVAL_CACHE_DEF(v_KEY).FIRST, p_TEMPLATE_ID,
																	v_BEGIN_DATE, v_END_DATE, p_TIME_ZONE);
				-- store an entry for this template
				g_INTERVAL_CACHE_DEF(v_KEY)(p_TEMPLATE_ID) := g_INTERVAL_CACHE_DEF(v_KEY)(g_INTERVAL_CACHE_DEF(v_KEY).FIRST);
			END IF;
		END IF;
		v_DATE := v_DATE+1;
	END LOOP;
	-- Flush final range of missing days to the temp table
	IF v_START_DATE_TO_CACHE IS NOT NULL THEN
		POPULATE_CACHE(p_END_DATE);
	END IF;
	-- return the number of records inserted into the cache
	RETURN v_RECORDS_STORED;
END CACHE_TRANSACTION_DETERMINANTS;
-------------------------------------------------------------------------------
-- Checks determinants for specified transaction. Caches data in
-- temporary tables if/when not already cached. Returns the determinant status.
-- %param p_TRANSACTION_ID		The Transaction ID whose interval data is being
--								cached.
-- %param p_STATEMENT_TYPE_ID	The Statement Type of interval data being
--				 				cached.
-- %param p_TIME_ZONE			The time zone, used to define which intervals
--								comprise a day.
-- %param p_BEGIN_DATE			The begin day of the bill period.
-- %param p_END_DATE			The end day of the bill period.
-- %param p_UOM					The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID			If not NULL, only retrieve results for a particular
--								time of use period.
-- %return						The status of the determinants used to find the
--								result value: 0 = OK, 1 = Missing (result will be 0),
--								or 2 = Partial
FUNCTION CHECK_TRANSACTION_DETERMINANTS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2,
	p_TEMPLATE_ID IN NUMBER
	) RETURN PLS_INTEGER IS

v_DUMMY	PLS_INTEGER;

BEGIN
	-- Make sure data is cached to temp table
	v_DUMMY := CACHE_TRANSACTION_DETERMINANTS(p_TRANSACTION_ID, p_STATEMENT_TYPE_ID, p_TIME_ZONE,
											p_BEGIN_DATE, p_END_DATE, p_UOM, p_TEMPLATE_ID);

	IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		TRACE_CACHE;
	END IF;

	-- Examine the cache package variable structures and/or temp table to ascertain status of the determinants
	RETURN GET_INTVL_DETERMINANT_STATUS(p_TRANSACTION_ID, g_OBJECT_INFO_CACHE(p_TRANSACTION_ID).INTERVAL, p_UOM, p_TEMPLATE_ID, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE);

END CHECK_TRANSACTION_DETERMINANTS;
-------------------------------------------------------------------------------
FUNCTION GET_ACTIVE_TRNSCTIONS_INTERNAL
	(
	p_ACCESSOR IN POD_DETERMINANT_ACCESSOR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_DATES_ARE_CUT IN BOOLEAN,
	p_TIME_ZONE IN VARCHAR2
	) RETURN NUMBER_COLLECTION IS
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_IDX			PLS_INTEGER;
BEGIN
	-- Determine proper dates to use for query
	IF p_DATES_ARE_CUT THEN
		v_BEGIN_DATE := TRUNC(FROM_CUT(p_BEGIN_DATE, p_TIME_ZONE)-1/86400);
		v_END_DATE := TRUNC(FROM_CUT(p_END_DATE, p_TIME_ZONE)-1/86400);
	ELSE
		v_BEGIN_DATE := p_BEGIN_DATE;
		v_END_DATE := p_END_DATE;
	END IF;

	-- for performance, do not re-query IDs if unnecessary
	IF v_BEGIN_DATE = g_PREV_ACTIVE_BEGIN_DATE AND v_END_DATE = g_PREV_ACTIVE_END_DATE THEN
		RETURN g_PREV_ACTIVE_TXNS;
	END IF;

	g_PREV_ACTIVE_BEGIN_DATE := v_BEGIN_DATE;
	g_PREV_ACTIVE_END_DATE := V_END_DATE;
	-- only include Transaction IDs that are active/valid for the specified date range
	SELECT IT.TRANSACTION_ID
	BULK COLLECT INTO g_PREV_ACTIVE_TXNS
	FROM TABLE(CAST(p_ACCESSOR.TRANSACTION_IDs as NUMBER_COLLECTION)) IDs,
		INTERCHANGE_TRANSACTION IT
	WHERE IT.TRANSACTION_ID = IDs.COLUMN_VALUE
		AND IT.BEGIN_DATE <= g_PREV_ACTIVE_END_DATE
		AND IT.END_DATE >= g_PREV_ACTIVE_BEGIN_DATE;

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Active transactions for '||TEXT_UTIL.TO_CHAR_DATE(v_BEGIN_DATE)||' -> '||TEXT_UTIL.TO_CHAR_DATE(v_END_DATE)||' :');
		v_IDX := g_PREV_ACTIVE_TXNS.FIRST;
		WHILE g_PREV_ACTIVE_TXNS.EXISTS(v_IDX) LOOP
			LOGS.LOG_DEBUG_DETAIL('  '||TEXT_UTIL.TO_CHAR_ENTITY(g_PREV_ACTIVE_TXNS(v_IDX), EC.ED_TRANSACTION)||' (ID='||g_PREV_ACTIVE_TXNS(v_IDX)||')');
			v_IDX := g_PREV_ACTIVE_TXNS.NEXT(v_IDX);
		END LOOP;
		LOGS.LOG_DEBUG_DETAIL('End active transactions');
	END IF;

	-- Got 'em
	RETURN g_PREV_ACTIVE_TXNS;
END GET_ACTIVE_TRNSCTIONS_INTERNAL;
-------------------------------------------------------------------------------
FUNCTION GET_ACTIVE_TRANSACTIONS
	(
	p_ACCESSOR IN POD_DETERMINANT_ACCESSOR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_DATES_ARE_CUT IN BOOLEAN := FALSE,
	p_TIME_ZONE IN VARCHAR2 := NULL
	) RETURN NUMBER_COLLECTION IS
BEGIN
	-- Since this is public, we need to make sure package variables are in proper
	-- state before proceeding
	INIT(p_ACCESSOR);
	RETURN GET_ACTIVE_TRNSCTIONS_INTERNAL(p_ACCESSOR, p_BEGIN_DATE, p_END_DATE, p_DATES_ARE_CUT, p_TIME_ZONE);
END GET_ACTIVE_TRANSACTIONS;
-------------------------------------------------------------------------------
-- Checks determinants for specified determinant accessor. Caches data in
-- temporary tables if/when not already cached. Returns the determinant status.
-- %param p_ACCESSOR	The service point determinant accessor on whose
--						behalf the determinants are queried.
-- %param p_INTERVAL	The interval of the component for which data is queried
-- %param p_BEGIN_DATE	The begin day of the bill period.
-- %param p_END_DATE	The end day of the bill period.
-- %param p_UOM			The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID	If not NULL, only retrieve results for a particular
--						time of use period.
-- %return				The status of the determinants used to find the
--						result value: 0 = OK, 1 = Missing (result will be 0),
--						or 2 = Partial
FUNCTION CHECK_POD_DETERMINANTS
	(
	p_ACCESSOR IN OUT NOCOPY POD_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2,
	p_TEMPLATE_ID IN NUMBER
	) RETURN PLS_INTEGER IS

v_TRANSACTIONS		     NUMBER_COLLECTION;
v_IDX				        PLS_INTEGER;
v_TRANSACTION_ID	     INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_DET_STATUS		     PLS_INTEGER;
v_BEGIN_DAY			     DATE;
v_END_DAY			     DATE;
v_RET				        PLS_INTEGER;
v_EDC_HOLIDAY_SET_ID   NUMBER(9,0) := c_NOT_ASSIGNED;
BEGIN

	v_TRANSACTIONS := GET_ACTIVE_TRNSCTIONS_INTERNAL(p_ACCESSOR, p_BEGIN_DATE, p_END_DATE,
													IS_SUB_DAILY(p_INTERVAL), p_ACCESSOR.TIME_ZONE);
	v_RET := NULL;

   v_EDC_HOLIDAY_SET_ID := GET_POD_EDC_HOLIDAY_SET_ID(p_ACCESSOR.SERVICE_POINT_ID);

	-- now loop through all transactions and check each one
	v_IDX := v_TRANSACTIONS.FIRST;
	WHILE v_TRANSACTIONS.EXISTS(v_IDX) LOOP
		v_TRANSACTION_ID := v_TRANSACTIONS(v_IDX);

		IF NOT g_OBJECT_INFO_CACHE.EXISTS(v_TRANSACTION_ID) THEN
			STORE_OBJECT_INFO_FOR_TXN(v_TRANSACTION_ID,v_EDC_HOLIDAY_SET_ID);
		END IF;

		-- Checking whole days
      DAY_RANGE(p_INTERVAL, p_BEGIN_DATE, p_END_DATE, p_ACCESSOR.TIME_ZONE, v_BEGIN_DAY, v_END_DAY);
		v_DET_STATUS := CHECK_TRANSACTION_DETERMINANTS(v_TRANSACTION_ID, p_ACCESSOR.STATEMENT_TYPE_ID,
													p_ACCESSOR.TIME_ZONE, v_BEGIN_DAY, v_END_DAY,
													p_UOM, p_TEMPLATE_ID);

		-- Update return status to reflect status of this service ID
		IF v_RET IS NULL THEN
			v_RET := v_DET_STATUS;
		ELSIF v_RET <> c_STATUS_PARTIAL AND v_RET <> v_DET_STATUS THEN
			v_RET := c_STATUS_PARTIAL;
		END IF;

		v_IDX := v_TRANSACTIONS.NEXT(v_IDX);
	END LOOP;

	RETURN NVL(v_RET, c_STATUS_MISSING); -- no transactions? then missing determinants

END CHECK_POD_DETERMINANTS;
-------------------------------------------------------------------------------
PROCEDURE GET_PEAK_DETERMINANT
	(
	p_ACCESSOR IN OUT NOCOPY POD_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEF_SCHED_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTEGRATION_INTERVAL IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	) IS

v_TEMPLATE_ID	TEMPLATE.TEMPLATE_ID%TYPE := NVL(p_TEMPLATE_ID, CONSTANTS.NOT_ASSIGNED);
v_UOM			VARCHAR2(32) := UPPER(p_UOM);
v_LOSS_ADJ_TYPE	NUMBER(1) := NVL(p_LOSS_ADJ_TYPE, c_ADJ_TYPE_NONE);
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_INTERVAL_VAL	NUMBER;
v_TO_INTERVAL_COUNT INTEGER;
BEGIN

	INIT(p_ACCESSOR);

	p_RETURN_STATUS := CHECK_POD_DETERMINANTS(p_ACCESSOR, p_INTERVAL, p_BEGIN_DATE, p_END_DATE,
												v_UOM, v_TEMPLATE_ID);

	IF p_RETURN_STATUS = c_STATUS_MISSING THEN
		p_RETURN_VALUE := 0;
		RETURN;
	END IF;

	-- Get proper date range for query
	INTERVAL_QUERY_DATE_RANGE(c_POD_CACHE_GRAN_KEY, p_INTERVAL, p_BEGIN_DATE, p_END_DATE, p_ACCESSOR.TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Querying interval cache for '||TEXT_UTIL.TO_CHAR_TIME(v_BEGIN_DATE)||' ->'
								||TEXT_UTIL.TO_CHAR_TIME(v_END_DATE)||', UOM = '||v_UOM
								||', Template = '||TEXT_UTIL.TO_CHAR_ENTITY(v_TEMPLATE_ID,EC.ED_TEMPLATE)
								||', Period = '||TEXT_UTIL.TO_CHAR_ENTITY(p_PERIOD_ID,EC.ED_PERIOD));
	END IF;

	IF IS_VALID_INTEGRATION_INTERVAL(p_INTEGRATION_INTERVAL) AND (p_INTEGRATION_INTERVAL IS NOT NULL) AND (IS_SUB_DAILY(p_INTEGRATION_INTERVAL)) THEN
	    -- Get the number of intervals in the day for the p_INTEGRATION_INTERVAL
		v_TO_INTERVAL_COUNT := GET_NUM_OF_SUBDAILY_INTERVALS(p_INTEGRATION_INTERVAL);

		-- Integrate the interval data based on the Grouping Number
		-- We only support integrating the peak values when the interval is sub-daily.
		SELECT MAX(TOTAL)
		INTO v_INTERVAL_VAL
		FROM (
            SELECT AVG(LOAD_VAL
		  		   + CASE WHEN v_LOSS_ADJ_TYPE > 0 THEN LOSS_VAL ELSE 0 END
				   + CASE WHEN v_LOSS_ADJ_TYPE > 1 THEN UFE_VAL ELSE 0 END) as TOTAL, INTEGRAND_GROUPING
			FROM (
                SELECT LOAD_VAL,
                       LOSS_VAL,
                       UFE_VAL,
                       LOAD_DATE,
                       CEIL((LOAD_DATE - p_BEGIN_DATE) * v_TO_INTERVAL_COUNT) AS INTEGRAND_GROUPING
				FROM DETERMINANT_CACHE_INTERVAL
				WHERE UOM = v_UOM
                  AND TEMPLATE_ID = v_TEMPLATE_ID
                  AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
                  AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE)
				GROUP BY INTEGRAND_GROUPING);
	ELSE
		-- Just get the peak
        SELECT MAX(TOTAL)
        INTO v_INTERVAL_VAL
        FROM (SELECT SUM(LOAD_VAL
                         + CASE WHEN v_LOSS_ADJ_TYPE > 0 THEN LOSS_VAL ELSE 0 END
                         + CASE WHEN v_LOSS_ADJ_TYPE > 1 THEN UFE_VAL ELSE 0 END) as TOTAL
                FROM DETERMINANT_CACHE_INTERVAL
                WHERE UOM = v_UOM
                  AND TEMPLATE_ID = v_TEMPLATE_ID
                  AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
                  AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
                GROUP BY LOAD_DATE);
	END IF;

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Peak value = '||v_INTERVAL_VAL);
	END IF;

	-- Done!
	p_RETURN_VALUE := NVL(v_INTERVAL_VAL,0);

END GET_PEAK_DETERMINANT;
-------------------------------------------------------------------------------
PROCEDURE GET_SUM_DETERMINANTS
	(
	p_ACCESSOR IN OUT NOCOPY POD_DETERMINANT_ACCESSOR,
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := GA.DEF_SCHED_UNIT_OF_MEASUREMENT,
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_OPERATION_CODE IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	) IS

v_TEMPLATE_ID	TEMPLATE.TEMPLATE_ID%TYPE := NVL(p_TEMPLATE_ID, CONSTANTS.NOT_ASSIGNED);
v_UOM			VARCHAR2(32) := UPPER(p_UOM);
v_LOSS_ADJ_TYPE	NUMBER(1) := NVL(p_LOSS_ADJ_TYPE, c_ADJ_TYPE_NONE);
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_INTERVAL_VAL	NUMBER;

BEGIN

	INIT(p_ACCESSOR);

	p_RETURN_STATUS := CHECK_POD_DETERMINANTS(p_ACCESSOR, p_INTERVAL, p_BEGIN_DATE, p_END_DATE,
												v_UOM, v_TEMPLATE_ID);

	IF p_RETURN_STATUS = c_STATUS_MISSING THEN
		p_RETURN_VALUE := 0;
		RETURN;
	END IF;

	-- Get proper date range for query
	INTERVAL_QUERY_DATE_RANGE(c_POD_CACHE_GRAN_KEY, p_INTERVAL, p_BEGIN_DATE, p_END_DATE, p_ACCESSOR.TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Querying interval cache for '||TEXT_UTIL.TO_CHAR_TIME(v_BEGIN_DATE)||' ->'
								||TEXT_UTIL.TO_CHAR_TIME(v_END_DATE)||', UOM = '||v_UOM
								||', Template = '||TEXT_UTIL.TO_CHAR_ENTITY(v_TEMPLATE_ID,EC.ED_TEMPLATE)
								||', Period = '||TEXT_UTIL.TO_CHAR_ENTITY(p_PERIOD_ID,EC.ED_PERIOD));
	END IF;

	SELECT SUM(LOAD_VAL
			  + CASE WHEN v_LOSS_ADJ_TYPE > 0 THEN LOSS_VAL ELSE 0 END
			  + CASE WHEN v_LOSS_ADJ_TYPE > 1 THEN UFE_VAL ELSE 0 END)
	INTO v_INTERVAL_VAL
	FROM DETERMINANT_CACHE_INTERVAL
	WHERE UOM = v_UOM
		AND TEMPLATE_ID = v_TEMPLATE_ID
		AND (v_TEMPLATE_ID = CONSTANTS.NOT_ASSIGNED OR PERIOD_ID = p_PERIOD_ID)
		AND LOAD_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('Sum value = '||v_INTERVAL_VAL);
	END IF;

	-- Done!
	p_RETURN_VALUE := NVL(v_INTERVAL_VAL,0);

END GET_SUM_DETERMINANTS;
-------------------------------------------------------------------------------
FUNCTION GET_TAX_DETERMINANT_ACCESSOR
    (
    p_TIME_ZONE        IN VARCHAR2
    ) RETURN TAX_DETERMINANT_ACCESSOR IS

BEGIN

  	RETURN TAX_DETERMINANT_ACCESSOR(p_TIME_ZONE);

END GET_TAX_DETERMINANT_ACCESSOR;
-------------------------------------------------------------------------------
PROCEDURE INT_COUNT_VALIDATE_INPUTS
(
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_DATE_RANGE_INTERVAL 		IN VARCHAR2
) IS
BEGIN
	-- VALIDATE THE DATE-RANGE
	IF p_INVOICE_LINE_BEGIN_DATE > p_INVOICE_LINE_END_DATE THEN
		ERRS.RAISE_BAD_DATE_RANGE(p_INVOICE_LINE_BEGIN_DATE, p_INVOICE_LINE_END_DATE,
								  'Invalid Date Range: Begin date can not be greater than end date.');
	END IF;
	-- VALIDATE INTERVAL
	ASSERT(P_DATE_RANGE_INTERVAL IN (DATE_UTIL.c_ABBR_5MIN, DATE_UTIL.C_ABBR_10MIN, DATE_UTIL.C_ABBR_15MIN,
									 DATE_UTIL.C_ABBR_20MIN, DATE_UTIL.C_ABBR_30MIN, DATE_UTIL.C_ABBR_HOUR,
									 DATE_UTIL.C_ABBR_DAY, DATE_UTIL.C_ABBR_WEEK, DATE_UTIL.C_ABBR_MONTH,
									 DATE_UTIL.C_ABBR_QUARTER, DATE_UTIL.C_ABBR_YEAR),
									 'Invalid INTERVAL: ' || P_DATE_RANGE_INTERVAL);
END INT_COUNT_VALIDATE_INPUTS;
-------------------------------------------------------------------------------
PROCEDURE INT_COUNT_CUT_DATE_RANGE
(
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_DATE_RANGE_INTERVAL 		IN VARCHAR2,
	p_CUT_BEGIN_DATE			OUT DATE,
	p_CUT_END_DATE				OUT DATE
) IS
BEGIN
	-- SET THE CUT_DATE RANGE FOR THE QUERY
	IF DATE_UTIL.IS_SUB_DAILY(p_DATE_RANGE_INTERVAL) THEN
		-- THIS IS SUB-DAILY
		p_CUT_BEGIN_DATE 	:= P_INVOICE_LINE_BEGIN_DATE;
		p_CUT_END_DATE		:= P_INVOICE_LINE_END_DATE;
	ELSE
		-- THIS IS DAILY OR MORE
		UT.CUT_DATE_RANGE(GA.DEFAULT_MODEL, P_INVOICE_LINE_BEGIN_DATE, P_INVOICE_LINE_END_DATE, GA.LOCAL_TIME_ZONE,
						  p_CUT_BEGIN_DATE, p_CUT_END_DATE);
	END IF;
END INT_COUNT_CUT_DATE_RANGE;
-------------------------------------------------------------------------------
FUNCTION INT_COUNT_RESULT
(
	p_METER_ID					IN METER.METER_ID%TYPE,
	p_BEGIN_DATE 				IN DATE,
	p_END_DATE					IN DATE,
	p_UOM						IN VARCHAR2,
	p_QUALITY_CODE				IN VARCHAR2,
	p_STATUS_CODE				IN VARCHAR2,
	p_TIME_ZONE					IN VARCHAR2,
	p_SERVICE_CODE				IN VARCHAR2
)RETURN NUMBER
IS
	v_RETURN_VALUE	NUMBER := 0;
	TYPE t_MPV_REC IS RECORD
	(
		METER_POINT_ID 		NUMBER(9),
		COUNT_METER_POINTS	PLS_INTEGER
	);

	TYPE t_MPV_RECS IS TABLE OF t_MPV_REC;
	v_MPV_RECS t_MPV_RECS := t_MPV_RECS();

	v_TOTAL_METER_PT_COUNT PLS_INTEGER := 0;
BEGIN
	-- Get the count(*) per Meter_Point_Id
	SELECT MPV.METER_POINT_ID, COUNT(*)
	BULK COLLECT INTO v_MPV_RECS
	FROM TX_SUB_STATION_METER_POINT MP,
		 TX_SUB_STATION_METER_PT_VALUE MPV
	WHERE MP.RETAIL_METER_ID = p_METER_ID -- Should be Retail_Meter_Id
	AND   ((p_UOM IS NULL AND MP.UOM IS NULL) OR UPPER(MP.UOM) LIKE UPPER(p_UOM))
	AND   MP.METER_POINT_ID = MPV.METER_POINT_ID
	AND	  MPV.MEASUREMENT_SOURCE_ID = CONSTANTS.NOT_ASSIGNED							-- For now, "N/A:
	AND	  MPV.METER_CODE = p_SERVICE_CODE												-- "A" (Actual)
	AND	  MPV.METER_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE 							-- this is already in CUT_DATE
	-- Wildcard '%' means everything, including NULL
	AND	  ((p_QUALITY_CODE IS NULL AND MPV.METER_VAL_QUAL_CODE 	   IS NULL) OR NVL(MPV.METER_VAL_QUAL_CODE, '%') 	LIKE p_QUALITY_CODE)
	AND	  ((p_STATUS_CODE  IS NULL AND MPV.TRUNCATED_VAL_QUAL_CODE IS NULL) OR NVL(MPV.TRUNCATED_VAL_QUAL_CODE, '%')LIKE p_STATUS_CODE)
	GROUP BY MPV.METER_POINT_ID;

	-- This is to average the count, if multiple meter_points are assigned for a meter.
	FOR I IN 1..v_MPV_RECS.COUNT LOOP
		v_TOTAL_METER_PT_COUNT := v_TOTAL_METER_PT_COUNT + v_MPV_RECS(I).COUNT_METER_POINTS;
	END LOOP;

	-- If no data existed, we want to avoid divide-by-zero error
	v_RETURN_VALUE := v_TOTAL_METER_PT_COUNT / CASE WHEN v_MPV_RECS.COUNT = 0 THEN 1 ELSE v_MPV_RECS.COUNT END;

	RETURN v_RETURN_VALUE;
END INT_COUNT_RESULT;
-------------------------------------------------------------------------------
PROCEDURE GET_AVERAGE_INTERVAL_COUNT
	(
	p_ACCESSOR 					IN OUT NOCOPY ACCOUNT_DETERMINANT_ACCESSOR,
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_UOM 						IN VARCHAR2 := NULL,
	p_QUALITY_CODE 				IN VARCHAR2 := NULL,
	p_STATUS_CODE 				IN VARCHAR2 := NULL,
	p_DATE_RANGE_INTERVAL		IN VARCHAR2 := NULL,
	p_RETURN_VALUE 				OUT NUMBER,
	p_RETURN_STATUS 			OUT PLS_INTEGER
	)
IS
	v_CUT_BEGIN_DATE 				DATE;
	v_CUT_END_DATE	 				DATE;
	v_NORMALIZED_INTERVAL_ABBREV	VARCHAR2(16);
BEGIN
	-- Get the Normalized Interval Abbreviation, which could either be configured as "MI15" or "15 Minute" etc.
	-- If it is 'Hour' or 'HH', it is returning NULL
	v_NORMALIZED_INTERVAL_ABBREV := NVL(GET_INTERVAL_ABBREVIATION(TRIM(p_DATE_RANGE_INTERVAL)), 'HH');
	-- Validate the inputs
	INT_COUNT_VALIDATE_INPUTS(p_INVOICE_LINE_BEGIN_DATE, p_INVOICE_LINE_END_DATE, v_NORMALIZED_INTERVAL_ABBREV);
	-- Align the Cut Date Range for the Query
	INT_COUNT_CUT_DATE_RANGE(p_INVOICE_LINE_BEGIN_DATE, p_INVOICE_LINE_END_DATE, v_NORMALIZED_INTERVAL_ABBREV, v_CUT_BEGIN_DATE, v_CUT_END_DATE);

	-- Initialize the accessor
	INIT(p_ACCESSOR);

	-- Get the Interval Count
	p_RETURN_VALUE := INT_COUNT_RESULT( p_ACCESSOR.METER_ID, v_CUT_BEGIN_DATE, v_CUT_END_DATE, p_UOM, p_QUALITY_CODE,
										p_STATUS_CODE, p_ACCESSOR.TIME_ZONE,
										p_ACCESSOR.SERVICE_CODE);

	p_RETURN_VALUE := NVL(p_RETURN_VALUE, 0);
	p_RETURN_STATUS:= 0;
END GET_AVERAGE_INTERVAL_COUNT;
-------------------------------------------------------------------------------
END RETAIL_DETERMINANTS;

/
