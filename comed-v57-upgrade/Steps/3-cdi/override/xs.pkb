CREATE OR REPLACE PACKAGE BODY XS AS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.112 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SYSTEM_LOAD
    (
	p_REQUEST_TYPE IN CHAR,
	p_SYSTEM_LOAD_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_REQUESTOR IN VARCHAR,
	p_STATUS OUT NUMBER
	) AS

-- Import the areas that comprise a system load.
-- Stub procedure, project specific implementation.
-- Request type is either Forecast or Actual.

v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

    p_STATUS := GA.SUCCESS;
	UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

END IMPORT_SYSTEM_LOAD;
---------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ENROLLMENT
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER
	) AS

-- Import the areas that comprise a system load.
-- Stub procedure, project specific implementation.
-- Request type is either Forecast or Actual.

v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

    p_STATUS := GA.SUCCESS;
	UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

END IMPORT_ENROLLMENT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SAMPLE_INTERVAL_USAGE
	(
	p_SAMPLE_NAME IN VARCHAR,
	p_METER_NUMBER IN VARCHAR,
	p_ACCOUNT_NUMBER IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer interval usage for the specified sample over the specified time interval.

v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

    p_STATUS := GA.SUCCESS;
	UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

END GET_SAMPLE_INTERVAL_USAGE;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SAMPLE_INTERVAL_USAGE
	(
	p_SAMPLE_NAME IN VARCHAR,
	p_METER_NUMBER IN VARCHAR,
	p_ACCOUNT_NUMBER IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_USAGE IN OUT NOCOPY USAGE_TABLE
	) AS

-- Answer interval usage for the specified sample over the specified time interval.

v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

    p_STATUS := GA.SUCCESS;
	UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

END GET_SAMPLE_INTERVAL_USAGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXPORT_MARKET_PRICES
	(
	p_MARKET_PRICE_IDS IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER
	) AS

-- Export market price data.

v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

    p_STATUS := GA.SUCCESS;
	UT.CUT_DATE_RANGE(p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

END EXPORT_MARKET_PRICES;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_EXTERNAL_BILLED_USAGE
	(
	p_METER_EXTERNAL_IDENTIFIER IN VARCHAR,
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer the bill usage for the specified meter over the specified time interval,
-- retrieved from an external database source.  Begin and End dates are specified as CUT dates.
-- p_CURSOR contains the meter identifier, begin date, end date, bill usage and
-- meters read values ordered by begin date.
-- This procedure is overriden by an installation defined process to retrieve external data.

BEGIN

    p_STATUS := GA.SUCCESS;

END GET_EXTERNAL_BILLED_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_EXTERNAL_INTERVAL_USAGE
	(
	p_METER_EXTERNAL_IDENTIFIER IN VARCHAR,
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer the interval usage for the specified meter over the specified time interval,
-- retrieved from an external database source.  Begin and End dates are specified as CUT dates.
-- p_CURSOR contains the meter identifier, usage date, and usage value ordered by usage date.
-- This procedure is overriden by an installation defined process to retrieve external data.

BEGIN

    p_STATUS := GA.SUCCESS;

END GET_EXTERNAL_INTERVAL_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPORT_TRANSACTION
	(
	p_OPERATION IN VARCHAR,
	p_TRANSACTION_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER
	) AS

-- Handle an import or export request for transaction schedules.
-- This is a stub procedure that is installation dependent.
-- Operation is either "IMPORT" OR "EXPORT".

BEGIN

    p_STATUS := GA.SUCCESS;

	EXCEPTION
		WHEN OTHERS THEN
			p_STATUS := SQLCODE;

END IMPORT_EXPORT_TRANSACTION;
----------------------------------------------------------------------------------------------------
PROCEDURE EXPORT_BILLING (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATEMENT_TYPE IN NUMBER,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_TIME_ZONE VARCHAR2(5) := 'EST';
FATAL_ERROR EXCEPTION;

BEGIN
   LOGS.LOG_INFO('Start XS.EXPORT_BILLING for BEGIN=' || TO_CHAR(p_BEGIN_DATE, 'DD-MM-YY HH24:MI:SS') ||
			' END=' || TO_CHAR(p_END_DATE, 'DD-MM-YY HH24:MI:SS'));
   COMMIT;
END EXPORT_BILLING;
--------------------------------------------------------------------------------------------------
PROCEDURE CACHE_USAGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END CACHE_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CACHE_USAGE
	(
	p_ESP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END CACHE_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CACHE_USAGE
	(
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END CACHE_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CACHE_USAGE
	(
	p_SERVICE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END CACHE_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE CACHE_CONSUMPTION
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END CACHE_CONSUMPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE CACHE_CONSUMPTION
	(
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END CACHE_CONSUMPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE CACHE_INTERVAL_CONSUMPTION
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END CACHE_INTERVAL_CONSUMPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE RELEASE_CACHE AS
BEGIN
	NULL;
END RELEASE_CACHE;
--------------------------------------------------------------------------------------------------
PROCEDURE RELEASE_USAGE AS
BEGIN
	NULL;
END RELEASE_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE RELEASE_USAGE
	(
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) AS

BEGIN
  NULL;
END RELEASE_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE RELEASE_USAGE
	(
	p_SERVICE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) AS

BEGIN
  NULL;
END RELEASE_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE RELEASE_CONSUMPTION AS
BEGIN
	NULL;
END RELEASE_CONSUMPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE RELEASE_CONSUMPTION
	(
	p_ACCOUNT_ID IN NUMBER,
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_AGGREGATE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) AS

BEGIN
	NULL;
END RELEASE_CONSUMPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE RELEASE_INTERVAL_CONSUMPTION AS
BEGIN
	NULL;
END RELEASE_INTERVAL_CONSUMPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE AGGREGATE_CONSUMPTION
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END AGGREGATE_CONSUMPTION;
----------------------------------------------------------------------------------------------------
PROCEDURE RUN_CACHE_REQUEST
	(
	p_REQUEST_TYPE IN VARCHAR,
	p_INTERVAL_USAGE IN NUMBER,
	p_PERIOD_CONSUMPTION IN NUMBER,
	p_AGGREGATE_CONSUMPTION IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_RUN_NOW IN NUMBER,
	p_RUN_AT IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END RUN_CACHE_REQUEST;
----------------------------------------------------------------------------------------------------
PROCEDURE POST_ALLOCATION_REQUEST
	(
	p_EDC_ID IN NUMBER,
	p_ACCOUNT_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_INPUT_AS_OF_DATE IN DATE,
	p_OUTPUT_AS_OF_DATE IN DATE,
	p_APPLY_UFE IN NUMBER,
	p_REQUESTOR IN VARCHAR,
	p_TRACE_ON IN NUMBER,
	p_STATUS OUT NUMBER
	) AS

BEGIN

  p_STATUS := GA.SUCCESS;

END POST_ALLOCATION_REQUEST;
----------------------------------------------------------------------------------------------------
PROCEDURE RUN_ANCILLARY_SERVICES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SERVICE_IDS IN VARCHAR,
	p_TRACE_ON IN NUMBER,
	p_STATUS OUT NUMBER
	) AS

BEGIN

   p_STATUS := GA.SUCCESS;

END RUN_ANCILLARY_SERVICES;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_ACCOUNT_USAGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_ACCOUNT_IDENT IN ACCOUNT_IDENT_TABLE,
	p_ACCOUNT_USAGE IN OUT ACCOUNT_USAGE_TABLE,
	p_STATUS OUT NUMBER
	) AS

-- Answer the usage for the specified accounts over the specified service period
-- retrieved from an external database source.
-- p_ACCOUNT_IDENT contains the account external identifier and the account internal id.
-- p_ACCOUNT_USAGE contains the account internal id, usage date, and associated usage value.
-- p_STATUS contains the status of the overall execution of the request.
-- This procedure is overridden by an installation-defined process to retrieve external data.

BEGIN

    p_STATUS := GA.SUCCESS;

END GET_ACCOUNT_USAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_SERVICE_VALIDATION
	(
	p_REQUEST_TYPE IN VARCHAR,
	p_SERVICE_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SERVICE_IDENT IN SERVICE_IDENT_TABLE,
	p_SERVICE_VALIDATION IN OUT SERVICE_VALIDATION_TABLE,
	p_STATUS OUT NUMBER
	) AS

-- Answer the usage for the specified accounts for the specified validation request type and service date
-- retrieved from an external database source.

-- p_REQUEST_TYPE values consist of the following letter codes:
--		H - Historical, same day type in most recent year,
--		A - Average, average of same day type in four week period in most recent year,
--		R - Recent, most recent day type in most recent year.
--		Note that multiple comma delimited letter codes can be specified.
-- p_SERVICE_IDENT contains the account external identifier and the account internal ids.
-- p_SERVICE_VALIDATION contains the account internal ids, service date, and associated usage values.
-- p_STATUS contains the status of the overall execution of the request.
-- This procedure is overridden by an installation-defined process to retrieve external data.

BEGIN

    p_STATUS := GA.SUCCESS;

END GET_SERVICE_VALIDATION;
----------------------------------------------------------------------------------------------------
PROCEDURE CALCULATE_WEATHER_PARAMETER
	(
	p_STATION_ID IN NUMBER,
	p_PARAMETER_ID IN NUMBER,
	p_PARAMETER_CATEGORY IN VARCHAR,
	p_PARAMETER_CODE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

-- Perform any post-processing on Weather Parameters requiring caculation.

BEGIN

    p_STATUS := GA.SUCCESS;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;

END CALCULATE_WEATHER_PARAMETER;
----------------------------------------------------------------------------------------------------
PROCEDURE PUBLISH_OBLIGATION
	(
	p_REQUEST_TYPE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_CAST_AS_OF_DATE IN DATE,
	p_TRACE_ON IN NUMBER,
	p_STATUS OUT NUMBER
	) AS

BEGIN

	p_STATUS := GA.SUCCESS;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;

END PUBLISH_OBLIGATION;

----------------------------------------------------------------------------------------------------
PROCEDURE PUT_EXTERNAL_METER_DATA
	(
	p_METER_IDENTIFIER IN VARCHAR,
	p_AS_OF_DATE IN DATE,
	p_MACHINE_NAME IN VARCHAR,
	p_USER_NAME IN VARCHAR,
	p_METER_VALUES IN VARCHAR,
	p_STATUS OUT NUMBER
	) AS

BEGIN

    p_STATUS := GA.SUCCESS;

END PUT_EXTERNAL_METER_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SUB_STATIONS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_SRC_AS_OF_DATE IN DATE,
	p_TRG_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

BEGIN

    p_STATUS := GA.SUCCESS;

END IMPORT_SUB_STATIONS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_PRIOR_CHARGE_ID
	(
	p_BILLING_STATEMENT IN BILLING_STATEMENT%ROWTYPE
	) RETURN NUMBER IS

-- Answer the CHARGE_ID associated with a prior statement type.

v_CHARGE_ID BILLING_STATEMENT.CHARGE_ID%TYPE;

BEGIN

	IF GA.VERSION_STATEMENT THEN
		SELECT CHARGE_ID
		INTO v_CHARGE_ID
		FROM BILLING_STATEMENT A
		WHERE ENTITY_ID = p_BILLING_STATEMENT.ENTITY_ID
			AND PRODUCT_ID = p_BILLING_STATEMENT.PRODUCT_ID
			AND COMPONENT_ID = p_BILLING_STATEMENT.COMPONENT_ID
			AND STATEMENT_TYPE = p_BILLING_STATEMENT.STATEMENT_TYPE - 1
			AND STATEMENT_STATE = p_BILLING_STATEMENT.STATEMENT_STATE
			AND STATEMENT_DATE = p_BILLING_STATEMENT.STATEMENT_DATE
			AND AS_OF_DATE =
				(SELECT MAX(AS_OF_DATE)
				FROM BILLING_STATEMENT
				WHERE ENTITY_ID = A.ENTITY_ID
					AND PRODUCT_ID = A.PRODUCT_ID
					AND COMPONENT_ID = A.COMPONENT_ID
					AND STATEMENT_TYPE = A.STATEMENT_TYPE
					AND STATEMENT_STATE = A.STATEMENT_STATE
					AND STATEMENT_DATE = A.STATEMENT_DATE
					AND AS_OF_DATE <= p_BILLING_STATEMENT.AS_OF_DATE);
	ELSE
		SELECT CHARGE_ID
		INTO v_CHARGE_ID
		FROM BILLING_STATEMENT A
		WHERE ENTITY_ID = p_BILLING_STATEMENT.ENTITY_ID
			AND PRODUCT_ID = p_BILLING_STATEMENT.PRODUCT_ID
			AND COMPONENT_ID = p_BILLING_STATEMENT.COMPONENT_ID
			AND STATEMENT_TYPE = p_BILLING_STATEMENT.STATEMENT_TYPE - 1
			AND STATEMENT_STATE = p_BILLING_STATEMENT.STATEMENT_STATE
			AND STATEMENT_DATE = p_BILLING_STATEMENT.STATEMENT_DATE
			AND AS_OF_DATE = LOW_DATE;
	END IF;

	RETURN v_CHARGE_ID;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END GET_PRIOR_CHARGE_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_PRIOR_CHARGE_ID
	(
	p_CHARGE_ID IN NUMBER
	) RETURN NUMBER IS

-- Answer the CHARGE_ID associated with a prior statement type.

v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;

BEGIN

	SELECT * INTO v_BILLING_STATEMENT FROM BILLING_STATEMENT WHERE CHARGE_ID = p_CHARGE_ID;

	RETURN GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END GET_PRIOR_CHARGE_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE COMPUTE_COMPONENT_CHARGES
	(
	p_CONTRACT_ID IN NUMBER,
	p_SCHEDULE_TYPE IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_CHARGE_ID IN NUMBER,
	p_COMPONENT IN COMPONENT%ROWTYPE,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
    p_ENTITY_ID IN NUMBER
	) AS

v_PRIOR_CHARGE_ID NUMBER;

BEGIN
	-- Compute charges for billing statement. Just populate billing determinant
	-- drill-down tables

	v_PRIOR_CHARGE_ID := GET_PRIOR_CHARGE_ID(p_CHARGE_ID);

END COMPUTE_COMPONENT_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_COMPONENT_CHARGES
	(
	p_BILLING_STATEMENT IN OUT BILLING_STATEMENT%ROWTYPE,
	p_WRITE_BILLING_STATEMENT OUT BOOLEAN
	) AS
BEGIN
	-- After COMPUTE_COMPONENT_CHARGES is called, this is called to sum the
	-- values from the drill-down tables into the BILLING_STATEMENT row. If
	-- no data is available, set p_WRITE_BILLING_STATEMENT to FALSE,
	-- otherwise set it to TRUE.

	p_WRITE_BILLING_STATEMENT := FALSE;

END;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_TAXED_COMPONENT_CHARGES
	(
	p_WORK_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_CHARGE_ID IN NUMBER,
	p_SOMETHING_DONE OUT BOOLEAN
	) AS
BEGIN

	-- For calculating tax details for an external charge component, this
	-- function must be written (unless the tax component itself is also
	-- external). This function should set p_SOMETHING_DONE to FALSE if
	-- no operation is performed for the given component ID / charge ID.
	-- If p_SOMETHING_DONE is TRUE, then this routine is expected to have
	-- inserted charge details into RTO_WORK: WORK_ID = p_WORK_ID, WORK_XID =
	-- p_CHARGE_ID, WORK_DATE = CHARGE DATE, and WORK_DATA = SUM(CHARGE AMOUNTS)
	-- for CHARGE DATE.

	p_SOMETHING_DONE := FALSE;

END PUT_TAXED_COMPONENT_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_CHARGE_DETAIL
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
    p_CHARGE_VIEW_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_WORK_ID IN NUMBER,
	p_TIME_ZONE IN VARCHAR,
	p_AS_OF_DATE IN DATE,
	p_BAND_KEYWORD OUT VARCHAR,
	p_HAS_SUBTOTALS OUT NUMBER,
    p_SHOW_BILL_AMOUNT IN NUMBER,
    p_SHOW_CHARGE_AMOUNT IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

v_CHARGE_TYPE VARCHAR(32);

BEGIN
	-- Get details for drill-down into a component. If the returned cursor has
	-- "bands" make sure the corresponding fields are all adjacent, all begin
	-- with p_BAND_KEYWORD, and a column exists called p_BAND_KEYWORD||'_NUMBER';
	-- otherwise set p_BAND_KEYWORD to empty string. If the cursor only has
	-- sub-totals (i.e. more than one row per charge date), then set
	-- p_HAS_SUBTOTALS to 1.
	--
	-- If SHOW_BILL_AMOUNT is zero, then any fields with bill quantities and amounts
	-- should be all null. If SHOW_CHARGE_AMOUNT is zero, then any fields with charge
	-- quantities and amounts should be all null. The grid configuration can then be
	-- setup so that these columns are all hide when null - and the UI will then
	-- properly respect the settings of the Show Bill Amounts and Show Charge Amounts
	-- checkboxes.

	p_STATUS := GA.SUCCESS;
	SELECT CHARGE_TYPE INTO v_CHARGE_TYPE
	FROM COMPONENT
	WHERE COMPONENT_ID = p_COMPONENT_ID;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;

END GET_CHARGE_DETAIL;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_CHARGE_KEY_COLUMNS
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
    p_CHARGE_VIEW_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_KEY_COLUMNS OUT VARCHAR,
	p_STATUS OUT NUMBER
	) AS
BEGIN

	-- Set p_KEY_COLUMNS to the primary key of the determinants table for the specified
	-- charge. This will typically just be 'CHARGE_DATE'. The column names must correspond
	-- to column names in the query returned by GET_CHARGE_DETAIL (above) - they are used
	-- for comparison of determinants. When the list contains more than one column, they
	-- should be delimited by commas.

	p_STATUS := GA.SUCCESS;
	p_KEY_COLUMNS := 'CHARGE_DATE';

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;

END GET_CHARGE_KEY_COLUMNS;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_DISPUTE_AMOUNT
	(
	p_CALLING_MODULE IN VARCHAR2,
	p_MODEL_ID IN NUMBER,
	p_CHARGE_VIEW_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_PRODUCT_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_STATEMENT_STATE IN NUMBER,
	p_STATEMENT_DATE IN DATE,
	p_STATEMENT_END_DATE IN DATE,
	p_DISPUTE_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_CHARGE_AMOUNT OUT NUMBER,
	p_BILL_AMOUNT OUT NUMBER
	) AS
BEGIN
	-- Query sum of charge and bill amounts for specified charge. The DISPUTE_DATE
	-- parameter will already be in CUT. The query will need to join to BILLING_STATEMENT
	-- to get CHARGE_ID because there is a date range vs. a single statement date.
	p_CHARGE_AMOUNT := NULL;
	p_BILL_AMOUNT := NULL;
END GET_DISPUTE_AMOUNT;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_CHARGE_MAX_BANDS
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_PSE_ID IN NUMBER,
	p_PRODUCT_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_STATEMENT_TYPE IN VARCHAR,
	p_STATEMENT_STATE IN NUMBER,
	p_TIME_ZONE IN VARCHAR,
	p_AS_OF_DATE IN DATE,
	p_BAND_KEYWORD IN VARCHAR,
	p_NUM_BANDS OUT NUMBER
	) AS

v_CHARGE_TYPE VARCHAR(32);

BEGIN
	-- If the BAND_KEYWORD is set for charge details for an external charge, then the GUI calls
	-- this routine to determine the maximum number of bands in a given time period. That way
	-- it can construct the grid columns correctly (it creates the grid columns, including those
	-- corresponding to the bands, first - then populates the data)

	SELECT CHARGE_TYPE INTO v_CHARGE_TYPE
	FROM COMPONENT
	WHERE COMPONENT_ID = p_COMPONENT_ID;

EXCEPTION
	WHEN OTHERS THEN
		p_NUM_BANDS := 0;

END GET_CHARGE_MAX_BANDS;
----------------------------------------------------------------------------------------------------
FUNCTION COMPONENT_IS_TX_CHARGE
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER
    ) RETURN NUMBER IS
BEGIN
	-- if specified component is a Transmission-type charge (i.e. participates in special
    -- transmission charge report of Billing Export report) then this needs to return 1.
    -- otherwise return 0

    RETURN 0;

END COMPONENT_IS_TX_CHARGE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_TX_SERVICE_TYPE
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER
    ) RETURN VARCHAR IS
BEGIN
	-- if specified component is a Transmission-type charge (i.e. participates in special
    -- transmission charge report of Billing Export report) then this needs to be implemented
    -- to determine what service type to use - there are 7 choices:
    --   'None'
    --	 'Schedule 1'
    --	 'Schedule 2'
    --	 'Schedule 3'
    -- 	 'Schedule 4'
    -- 	 'Schedule 5'
    -- 	 'Schedule 6'

	RETURN 'None';

END GET_TX_SERVICE_TYPE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_TX_CHARGES_FOR_REPORT
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_PSE_ID IN NUMBER,
	p_PRODUCT_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR,
	p_AS_OF_DATE IN DATE,
    p_CHARGE_ID IN NUMBER
    ) AS
BEGIN
	-- use the p_CHARGE_ID to fill TRANSMISSION_CHARGE table - this data is then used to put data into the
    -- special Transmission Charge report of Billing Export report...
    -- simply copy all charge-level detail data to TRANSMISSION_CHARGE table.
    -- leave column CHARGE_INTERVAL blank, or optionally include NOTES there

    NULL; -- do nothing by default

END GET_TX_CHARGES_FOR_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_CHARGES_FOR_REPORT
	(
	p_CALLING_MODULE IN VARCHAR,
	p_MODEL_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_PSE_ID IN NUMBER,
	p_PRODUCT_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_STATEMENT_TYPE IN NUMBER,
	p_STATEMENT_STATE IN NUMBER,
	p_TIME_ZONE IN VARCHAR,
	p_AS_OF_DATE IN DATE,
    p_COMPONENT_NAME OUT VARCHAR,
    p_USE_NORMAL_DETAIL OUT NUMBER,
    p_HEADER_ROWS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
    ) AS
BEGIN
	-- return a recordset that has a single string field - the string should be
    -- pipe-delimited and will represent the billing export report representation
    -- of an external charge.
    -- set p_USE_NORMAL_DETAIL to 1 if the report should use the normal drill-down
    -- details, or set it to zero and populate p_CURSOR with the details.
    -- p_HEADER_ROWS indicates how many of the first few rows of p_CURSOR are just
    -- header rows.
    -- set p_COMPONENT_NAME to override the default (which is simply the component's
    -- name)

    p_USE_NORMAL_DETAIL := 1; -- do nothing - use regular drill-down by default

END GET_CHARGES_FOR_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_INVOICE_LINE_ITEMS
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_STATEMENT_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
    p_LINE_ITEM_OPTION IN VARCHAR2,
	p_AS_OF_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	-- return recordset of invoice line items in p_CURSOR. So that the fetches don't yield
	-- oracle errors, the columns of the recordset need to be (are expected to be):
	--	  ENTITY_ID				pse or bill-party ID (should be non-zero)
	--	  PRODUCT_ID			product id or 0
	--	  COMPONENT_ID			component id or 0
	--	  ACCOUNT_SERVICE_ID	account service id or 0
    --	  OTHER_ID				any other ID info you'll need to unroll this line item
    --	  OTHER_DATA			any other data you'll need to unroll this line item
	--	  LINE_ITEM_NAME		the name of the line item
	--	  LINE_ITEM_CATEGORY	the category for the line item
	--	  LINE_ITEM_QUANTITY	a total quantity or null
	--	  LINE_ITEM_RATE		a price/rate or null
	--	  LINE_ITEM_AMOUNT		the line item dollar amount (pse id, line item name, and this are the most important)
	--	  LINE_ITEM_BILL_AMOUNT	should be current amount - prior period amount...
    --    DEFAULT_DISPLAY		the default display amount - should be 'CHARGE' or 'BILL' or leave NULL
    --    STATEMENT_TYPE		the statement type for this line item - can leave NULL
    --    BEGIN_DATE			the begin date for this line item - can leave NULL
    --    END_DATE				the end date for this line item - can leave NULL
	-- p_ENTITY_ID will be a pse id, pool id, or bill party id (depends on p_ENTITY_TYPE) - or it could be
	-- -1 to indicate all pses/billparties.

	p_STATUS := -1; -- non-zero status indicates p_CURSOR never opened

END GET_INVOICE_LINE_ITEMS;
----------------------------------------------------------------------------------------------------
PROCEDURE UNROLL_INVOICE_LINE_ITEM
	(
    p_ENTITY_ID IN NUMBER,
    p_ENTITY_TYPE IN VARCHAR2,
    p_AS_OF_DATE IN DATE,
    p_INVOICE_LINE_ITEM IN INVOICE_LINE_ITEM%ROWTYPE,
    p_PRODUCT_COMPONENT_PAIRS OUT VARCHAR2
	) AS
BEGIN
	-- If invoice line items use a custom roll-up (that uses above procedure)
    -- this procedure is for unrolling items for invoice validation. If
    -- the invoice line item roll-up breaks up billing statement detail
    -- so that a single product-component statement result may be split up
    -- between more than one line item, then unrolling is not possible - in
    -- that case, set the outbound parameter to NULL and return. If
    -- unrolling can be done, then this routine is responsible for it: Just
    -- populate the outbound parameter (p_PRODUCT_COMPONENT_PAIRS) and return.
    -- The parameter is a string with semi-colon delimited set of pairs - the
    -- pairs are product id, comma, component id. Example:
    --    123,141;123,142;123,143;124,144
    -- The above example means that this line item encompasses billing statement
    -- results for two products (IDs 123 and 124), three components with the first
    -- and one component with the last.

    p_PRODUCT_COMPONENT_PAIRS := NULL;

END UNROLL_INVOICE_LINE_ITEM;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_INVOICE_REPORT_RECORDS
	(
    p_INVOICE_CATEGORY IN VARCHAR,
    p_INVOICE_ID IN NUMBER,
	p_STATUS OUT NUMBER,
    p_SOMETHING_DONE IN OUT BOOLEAN,
	p_CURSOR IN OUT GA.REFCURSOR
    ) AS

BEGIN
	-- return recordset of all line item detail that Crystal Report needs to render invoice report,
    -- to use default dataset, set p_SOMETHING_DONE to False

    p_SOMETHING_DONE := FALSE;

END GET_INVOICE_REPORT_RECORDS;
----------------------------------------------------------------------------------------------------
PROCEDURE DATA_EXCHANGE_ENTITY_LIST
	(
	p_REQUEST_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR,
	p_MODULE_NAME IN VARCHAR,
	p_ENTITY_LABEL OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	--p_ENTITY_LABEL := 'My Entity Type'; --(Don"t forget this part!)
	OPEN p_CURSOR FOR SELECT NULL FROM DUAL;

END DATA_EXCHANGE_ENTITY_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE DATA_EXCHANGE
	(
	p_REQUEST_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR,
	p_MODULE_NAME IN VARCHAR,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS
BEGIN
		-- MarketManager doesn't implement this exchange type
		p_STATUS := 1; -- non-zero will cause UI to display message
		p_MESSAGE := 'Exchange Type '''||p_EXCHANGE_TYPE||''' is not implemented';

END DATA_EXCHANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE DATA_IMPORT_CHUNK
	(
	p_REQUEST_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_DATA_EXCHANGE_NAME IN VARCHAR,
	p_MODULE_NAME IN VARCHAR,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_IMPORT_FILE_PATH IN VARCHAR,
	p_IMPORT_FILE IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS
v_RECORD_DELIM VARCHAR2(16);
v_CHUNKS STRING_COLLECTION := STRING_COLLECTION();
v_CHUNK VARCHAR(4000);
v_NEXT_LINE VARCHAR(4000);
v_LAST_TIME NUMBER;
v_LENGTH NUMBER;
v_END_POS NUMBER;
v_END_POS2 NUMBER;
v_BEGIN_POS NUMBER := 1;
v_END_CHAR VARCHAR2(1);
v_CHAR VARCHAR2(1);
v_IDX NUMBER;
BEGIN
	v_RECORD_DELIM := NVL(GET_DICTIONARY_VALUE(p_DATA_EXCHANGE_NAME,0,'Data Import','Delimiter'), '~');

	v_LENGTH := DBMS_LOB.GETLENGTH(p_IMPORT_FILE);
	WHILE v_BEGIN_POS <= v_LENGTH LOOP
		v_END_POS := DBMS_LOB.INSTR(p_IMPORT_FILE, CHR(10), v_BEGIN_POS);
		v_END_POS2 := DBMS_LOB.INSTR(p_IMPORT_FILE, CHR(13), v_BEGIN_POS);
		-- determine which character we found - or, if we found both, which one
		-- comes first
		IF v_END_POS2 BETWEEN v_BEGIN_POS AND v_END_POS
			OR v_BEGIN_POS BETWEEN v_END_POS AND v_END_POS2
		THEN
			v_END_POS := v_END_POS2;
			v_END_CHAR := CHR(13);
		ELSE
			v_END_CHAR := CHR(10);
		END IF;

		-- Get the next line
		IF v_END_POS < v_BEGIN_POS THEN
			-- End of the Clob
			v_NEXT_LINE := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_IMPORT_FILE, 4000, v_BEGIN_POS)));
			v_END_POS := v_LENGTH;
		ELSE
			v_NEXT_LINE := TRIM(DBMS_LOB.SUBSTR(p_IMPORT_FILE, v_END_POS - v_BEGIN_POS, v_BEGIN_POS));
			v_CHAR := DBMS_LOB.SUBSTR(p_IMPORT_FILE, 1, v_END_POS+1);
			IF v_CHAR IN (CHR(10),CHR(13)) AND v_CHAR <> v_END_CHAR THEN
				v_END_POS := v_END_POS+1;
			END IF;
		END IF;

		-- If less than max chunk size, add the new line to the chunk
        IF (LENGTH(v_CHUNK) + LENGTH(v_NEXT_LINE) + 1) < 4000 THEN
			IF v_CHUNK IS NOT NULL THEN
				v_CHUNK := v_CHUNK || v_RECORD_DELIM;
			END IF;
			v_CHUNK := v_CHUNK || v_NEXT_LINE;
		ELSE
			-- We have reached the max chunk size (4000). Add to list and begin new chunk.
			v_CHUNKS.EXTEND();
			v_CHUNKS(v_CHUNKS.LAST) := v_CHUNK;
			v_CHUNK := v_NEXT_LINE;
		END IF;

		v_BEGIN_POS := v_END_POS + 1;
	END LOOP;

	-- Get Last Chunk
	IF LENGTH(v_CHUNK) > 0 THEN
		v_CHUNKS.EXTEND();
		v_CHUNKS(v_CHUNKS.LAST) := v_CHUNK;
	END IF;

	-- Loop over all the Chunks and call XS.DATA_IMPORT
	v_IDX := v_CHUNKS.FIRST;
	WHILE v_IDX IS NOT NULL LOOP

		v_CHUNK := v_CHUNKS(v_IDX);
		v_LAST_TIME := CASE WHEN v_IDX = v_CHUNKS.LAST THEN 1 ELSE 0 END;

		-- IMPORT THE CHUNK
		IF p_DATA_EXCHANGE_NAME = 'INSERT_CUSTOM_ACTION_HERE' THEN
			-- CUSTOM PROCEDURES GO HERE
			NULL;
		ELSE
			XS.DATA_IMPORT(p_REQUEST_TYPE,
						   p_BEGIN_DATE,
						   p_END_DATE,
						   p_AS_OF_DATE,
						   p_DATA_EXCHANGE_NAME,
						   p_MODULE_NAME,
						   p_ENTITY_LIST,
						   p_ENTITY_LIST_DELIMITER,
						   v_RECORD_DELIM,
						   v_CHUNK,
						   p_IMPORT_FILE_PATH,
						   v_LAST_TIME,
						   p_STATUS,
						   p_MESSAGE);

			ERRS.VALIDATE_STATUS('XS.DATA_IMPORT', p_STATUS, p_MESSAGE);
		END IF;
		v_IDX := v_CHUNKS.NEXT(v_IDX);
	END LOOP;

END DATA_IMPORT_CHUNK;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_DEFAULT_SYSTEM_ACTION
	(
	p_CONTEXT_ID IN NUMBER,
    p_CONTEXT_TYPE IN VARCHAR,
	p_ACTION_TYPE IN VARCHAR,
    p_MODULE_NAME IN VARCHAR,
	p_ACTION_ID OUT NUMBER,
    p_STATUS OUT NUMBER
	) AS

BEGIN

	--If this is a Transaction type, delegate to MM.
	IF p_CONTEXT_TYPE = 'TRANSACTION' AND p_CONTEXT_ID > 0 THEN
		GET_DEFAULT_SYSTEM_ACTION(p_CONTEXT_ID, p_CONTEXT_TYPE, p_ACTION_TYPE, p_MODULE_NAME, p_ACTION_ID, p_STATUS);
	ELSE
		--See if the CONTEXT_TYPE is infact an Action Name.
		IF p_CONTEXT_TYPE IS NOT NULL AND LENGTH(p_CONTEXT_TYPE) > 1 THEN
			BEGIN
				SELECT ACTION_ID INTO p_ACTION_ID FROM SYSTEM_ACTION WHERE ACTION_NAME = TRIM(p_CONTEXT_TYPE);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
    p_ACTION_ID := 140;
			END;
		ELSE
		    p_ACTION_ID := 140;
		END IF;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		--This is not that important.  Just do some default thing and eat the error.
		p_ACTION_ID := 140;

END GET_DEFAULT_SYSTEM_ACTION;
----------------------------------------------------------------------------------------------------
PROCEDURE DATA_IMPORT
	(
	p_REQUEST_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR,
	p_MODULE_NAME IN VARCHAR,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_RECORD_DELIMITER IN CHAR,
	p_RECORDS IN VARCHAR,
	p_FILE_PATH IN VARCHAR,
	p_LAST_TIME IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS
BEGIN
		-- MarketManager doesn't implement this exchange type
		p_STATUS := 0; -- non-zero will cause UI to display message
		p_MESSAGE := 'Exchange Type '''||p_EXCHANGE_TYPE||''' is not implemented';
END DATA_IMPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE DATA_EXPORT
	(
	p_REQUEST_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR,
	p_MODULE_NAME IN VARCHAR,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
    p_FILE OUT CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS

BEGIN
		-- MarketManager doesn't implement this exchange type
		p_STATUS := 1; -- non-zero will cause UI to display message
		p_MESSAGE := 'Exchange Type '''||p_EXCHANGE_TYPE||''' is not implemented';
END DATA_EXPORT;

----------------------------------------------------------------------------------------------------
PROCEDURE BID_OFFER_SUBMIT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ACTION IN VARCHAR,
	p_IS_TEST_MODE IN NUMBER,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_SUBMIT_HOURS IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS
BEGIN
		p_STATUS := 1; -- non-zero will cause UI to display message
		p_MESSAGE := 'Action '''||p_ACTION||''' is not implemented';
END BID_OFFER_SUBMIT;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_BID_OFFER_SUBMIT_WARNING
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ACTION IN VARCHAR,
	p_IS_TEST_MODE IN NUMBER,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_SUBMIT_HOURS IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR,
	p_CONTINUE_BUTTON_CAPTION OUT VARCHAR,
	p_CANCEL_BUTTON_CAPTION OUT VARCHAR,
	p_MUST_CANCEL_SUBMIT OUT NUMBER
	) AS
-- Custom data checking before a market submit from the Bid/Offer Action Dialog.
-- If p_STATUS is zero, the submit will occur as usual.
-- If p_STATUS is nonzero, an exception dialog with the specified message
--		will be shown to the user.
-- If p_MUST_CANCEL_SUBMIT is flagged as 1, then the user will not be
--		allowed to continue with the submission.  (This flag is only checked if
--		the status is nonzero.)
-- p_CONTINUE_BUTTON_CAPTION and p_CANCEL_BUTTON_CAPTION will set
-- 		the captions on the corresponding buttons on the dialog.

BEGIN
	    p_STATUS := GA.SUCCESS;
		p_CONTINUE_BUTTON_CAPTION := 'Continue';
		p_CANCEL_BUTTON_CAPTION := 'Cancel';
		p_MUST_CANCEL_SUBMIT := 0;

END GET_BID_OFFER_SUBMIT_WARNING;
----------------------------------------------------------------------------------------------------
/*
  'Thu June 9, 2005 02:54:09. - sb - Function to check for errors in data submited by bids AND Checking that time does not exceed 24 and start<=end (Bugzilla ID 8551)
  Custom checks on Bid AND Offers data on submit
*/

PROCEDURE GET_BID_OFFER_FILL_WARNING
    (
	p_TRANSACTION_ID IN NUMBER,
	p_BID_OFFER_ID IN NUMBER,
	p_SCHEDULE_STATE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_EXPIRATION_DATE IN DATE,
	p_DAY_NAME IN CHAR,
	p_BEGIN_HOUR IN NUMBER,
	p_END_HOUR IN NUMBER,
	p_PRICE_QUANTITY_PAIRS IN VARCHAR,
	p_TEMPLATE_NAME IN VARCHAR,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_CONTINUE_BUTTON_CAPTION OUT VARCHAR,
	p_CANCEL_BUTTON_CAPTION OUT VARCHAR,
	p_MUST_CANCEL_SUBMIT OUT NUMBER
 	 ) AS

-- Retun warnings if errors are found in data
BEGIN

  p_MUST_CANCEL_SUBMIT := 0;
  p_CONTINUE_BUTTON_CAPTION := 'Continue';
  p_CANCEL_BUTTON_CAPTION := 'OK';

END GET_BID_OFFER_FILL_WARNING;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_SCHEDULING_REPORT
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
    p_REPORT_FILTERS IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN

    p_STATUS := GA.SUCCESS;
    OPEN p_CURSOR FOR
    	SELECT NULL "Report Not Found" FROM DUAL WHERE 0=1;

END GET_SCHEDULING_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_CAST_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_REQUEST_TYPE IN CHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_SCENARIO_ID IN NUMBER,
    p_NOTUSED_ID1 IN NUMBER,
    p_NOTUSED_ID2 IN NUMBER,
	p_REPORT_NAME IN VARCHAR2,
    p_REPORT_FILTERS IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

--Answer a cursor to display on the Reports tab
--in Forecasting or Settlement.
BEGIN

    p_STATUS := GA.SUCCESS;

END GET_CAST_REPORT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_DB_SYSDATE
	(
	p_TIME_ZONE IN VARCHAR,
	p_SYSDATE OUT DATE
	) AS

--Answer the sysdate from the VB, optionally converted
--to local time zone.  VB will perform no conversions
--on this date.
BEGIN

    p_SYSDATE := SYSDATE;

END GET_DB_SYSDATE;
---------------------------------------------------------------------------------------------------
PROCEDURE PJM_EXPORT_DATA_MISC
	(
	p_SCHEDULE_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_AS_OF_DATE IN DATE,
--@@Begin Implementation Override --
	p_CURSOR IN OUT GA.REFCURSOR,
--@@End Implementation Override --
	p_SOMETHING_DONE IN OUT BOOLEAN
	) AS

--v_CURSOR  GA.REFCURSOR := p_CURSOR;
BEGIN
	p_SOMETHING_DONE := FALSE;
	-- set this to TRUE if you do anything w/ p_CURSOR
--@@Begin Implementation Override --
   IF p_SCHEDULE_TYPE = 3 THEN
     Cdi_C.PJM_EXPORT_DATA
       (p_CURSOR,
        p_BEGIN_DATE,
        p_SOMETHING_DONE
       );
   END IF;
--@@End Implementation Override --
END;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ANC_SVC_TOTAL_ALLOCATION
	(
	p_ANCILLARY_SERVICE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE
	) RETURN NUMBER IS

-- Answer the total for the given Ancillary Service Id and Begin Date.
-- This total will govern the GUI entry into the ANCILLARY_SERVICE_ALLOCATION table.
-- The GUI can be found in Forecasting, Ancillary Service Tab, Contribution Tab.
-- It is recommended to store this number in as an Entity Attribute of the Ancillary Service.
v_TOTAL NUMBER;
BEGIN

	RETURN v_TOTAL;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END GET_ANC_SVC_TOTAL_ALLOCATION;
---------------------------------------------------------------------------------------------------

PROCEDURE PUT_ANC_SVC_TOTAL_ALLOCATION
	(
	p_ANCILLARY_SERVICE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_TOTAL_VAL IN NUMBER
	) AS

-- Store the total for the given Ancillary Service Id and Begin Date.
-- See GET_ANC_SVC_TOTAL_ALLOCATION for more details.
BEGIN

	  NULL;

EXCEPTION
	WHEN OTHERS THEN
		RAISE;
END PUT_ANC_SVC_TOTAL_ALLOCATION;
---------------------------------------------------------------------------------------------------
PROCEDURE SEED_ANC_SVC_ALLOCATION_NAMES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER
	) AS

--Seed the ANCILLARY_SERVICE_ALLOCATION table with names for a new date range. --use either a previous date range, or direct rateclass/strata query or whatever is needed.

--Insert a record for each name for each ancillary service, for example
-- 	FOR v_ALLOCATION_NAMES IN c_ALLOCATION_NAMES LOOP
-- 		INSERT INTO ANCILLARY_SERVICE_ALLOCATION
-- 			(
-- 			ANCILLARY_SERVICE_ID,
-- 			ALLOCATION_NAME,
-- 			BEGIN_DATE,
-- 			END_DATE
-- 			)
-- 		VALUES
-- 			(
-- 			v_ALLOCATION_NAMES.ANCILLARY_SERVICE_ID,
-- 			v_ALLOCATION_NAMES.ALLOCATION_NAME,
-- 			p_BEGIN_DATE,
-- 			v_END_DATE
-- 			);
-- 	END LOOP;
BEGIN

    p_STATUS := GA.SUCCESS;

END SEED_ANC_SVC_ALLOCATION_NAMES;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_GAS_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_REPORT_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_REPORT_NAME IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN

     p_STATUS := GA.SUCCESS;

END GET_GAS_REPORT;
---------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_USAGE_FACTOR
	(
	p_CALENDAR_ID IN NUMBER,
	p_ACCOUNT_ID IN NUMBER,
	p_METER_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ACTUAL_USAGE IN NUMBER,
	p_FACTOR_IS_SEASONAL IN CHAR,
	p_YEARS_TO_APPLY IN NUMBER
	) AS

BEGIN

	  NULL;

EXCEPTION
	WHEN OTHERS THEN
		RAISE;
END UPDATE_USAGE_FACTOR;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOM_FORMULA_FUNCTION_DATES
	(
    p_FUNCTION_NAME IN VARCHAR2,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_OUT_BEGIN_DATE OUT DATE,
    p_OUT_END_DATE OUT DATE
    ) AS
BEGIN
	-- You can add your own 'functions' to the list of functions for Formula Rate Structure components.
    -- The things you can override are the function (i.e. what is "select"ed and the date range.
    -- Implement this function to override date range
    p_OUT_BEGIN_DATE := p_BEGIN_DATE;
    p_OUT_END_DATE := p_END_DATE;
END CUSTOM_FORMULA_FUNCTION_DATES;
---------------------------------------------------------------------------------------------------
PROCEDURE CUSTOM_FORMULA_FUNCTION_SELECT
	(
    p_FUNCTION_NAME IN VARCHAR2,
    p_COLUMN_NAME IN VARCHAR2,
    p_OUT_SELECT OUT VARCHAR2
    ) AS
BEGIN
	-- You can add your own 'functions' to the list of functions for Formula Rate Structure components.
    -- The things you can override are the function (i.e. what is "select"ed and the date range.
    -- Implement this function to override the select - include the word "select" as the first word
    -- of the select clause.
    p_OUT_SELECT := NULL;
END CUSTOM_FORMULA_FUNCTION_SELECT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_PROFILING_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_REPORT_NAME IN VARCHAR,
	p_OPTIONAL_PARAMETER IN VARCHAR,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_INTERVAL_FORMAT IN VARCHAR,
	p_PROFILE_ID IN NUMBER,
	p_TEMPLATE_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

--Answer a cursor to display on the Reports tab
--in LoadProfiling.

v_CUSTOMER_ID NUMBER;

BEGIN

    p_STATUS := GA.SUCCESS;

    v_CUSTOMER_ID := TO_NUMBER(p_OPTIONAL_PARAMETER);

    IF UPPER(p_REPORT_NAME) = 'EDIT USAGE DATA' THEN
        OPEN p_CURSOR FOR
        	SELECT  *
            FROM CUSTOMER_CONSUMPTION C
            WHERE CUSTOMER_ID = v_CUSTOMER_ID
            AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
            AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
            AND C.CONSUMPTION_CODE = C.CONSUMPTION_CODE;
    ELSE
        OPEN p_CURSOR FOR
        	SELECT  'XS.GET_PROFILING_REPORT' "Procedure" FROM DUAL;
    END IF;

END GET_PROFILING_REPORT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_LOAD_PROFILING_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_REPORT_TYPE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_PROFILE_ID IN NUMBER,
	p_SEASON_DAY_TYPE_NUM IN NUMBER,
	p_NOTUSED_ID IN NUMBER,
	p_REPORT_NAME IN VARCHAR2,
	p_FILTERS IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

v_TOKENS GA.STRING_TABLE;
v_FILTERS GA.STRING_TABLE;
v_INDEX_FILTERS BINARY_INTEGER;
v_INDEX_TOKENS BINARY_INTEGER;


BEGIN

    p_STATUS := GA.SUCCESS;

    IF UPPER(p_REPORT_NAME) = 'EDIT CUSTOMER CONSUMPTION' THEN
        DECLARE
            v_CUSTOMER_ID NUMBER(9) := 0;
            v_CONSUMPTION_CODE CHAR(1) := 'A';
            v_SHOW_DUPLICATES NUMBER(1) := 0;

        BEGIN

            UT.TOKENS_FROM_STRING(NVL(p_FILTERS,''),'|',v_FILTERS);
            IF v_FILTERS.COUNT > 0 THEN
         		FOR v_INDEX_FILTERS IN v_FILTERS.FIRST..v_FILTERS.LAST LOOP
        			IF LENGTH(v_FILTERS(v_INDEX_FILTERS)) > 0 THEN
                    UT.TOKENS_FROM_STRING(v_FILTERS(v_INDEX_FILTERS),';',v_TOKENS);
        				IF v_TOKENS(1) = 'CUSTOMER_ID' THEN
                           v_CUSTOMER_ID := TO_NUMBER(v_TOKENS(2));
                        ELSIF v_TOKENS(1) = 'CONSUMPTION_CODE' THEN
                           v_CONSUMPTION_CODE := SUBSTR(v_TOKENS(2),1,1);
                        ELSIF v_TOKENS(1) = 'SHOW_DUPLICATES' THEN
                           v_SHOW_DUPLICATES := TO_NUMBER(v_TOKENS(2));
                        END IF;
        			END IF;
        		END LOOP;
            END IF;

            IF v_SHOW_DUPLICATES = 0 THEN
                OPEN p_CURSOR FOR
                	SELECT *
                    FROM CUSTOMER_CONSUMPTION C
                    WHERE C.CUSTOMER_ID = v_CUSTOMER_ID  --26749 --
                    AND C.BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
                    AND C.END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
                    AND (v_CONSUMPTION_CODE = '<' OR C.CONSUMPTION_CODE = v_CONSUMPTION_CODE)
                    ORDER BY C.CUSTOMER_ID, C.BEGIN_DATE;
            ELSE
                OPEN p_CURSOR FOR
                	SELECT *
                    FROM CUSTOMER_CONSUMPTION C,
                            (SELECT CUSTOMER_ID, BEGIN_DATE
                            FROM CUSTOMER_CONSUMPTION
                            WHERE CUSTOMER_ID = v_CUSTOMER_ID
                            AND BEGIN_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
                            AND END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
                            GROUP BY CUSTOMER_ID, BEGIN_DATE
                            HAVING COUNT(1) > 1) X
                    WHERE C.CUSTOMER_ID = X.CUSTOMER_ID
                    AND C.BEGIN_DATE  = X.BEGIN_DATE
                    AND C.END_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
                    AND (v_CONSUMPTION_CODE = '<' OR C.CONSUMPTION_CODE = v_CONSUMPTION_CODE)
                    ORDER BY C.CUSTOMER_ID, C.BEGIN_DATE;

            END IF;
        END;

    ELSE
        OPEN p_CURSOR FOR
        	SELECT  'XS.GET_LOAD_PROFILING_REPORT' "Procedure" FROM DUAL;
    END IF;

END GET_LOAD_PROFILING_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_CUSTOMER_CONSUMPTION
	(
	p_OLD_CUSTOMER_ID IN NUMBER,
	p_OLD_BEGIN_DATE IN DATE,
	p_OLD_END_DATE IN DATE,
	p_OLD_BILL_CODE IN CHAR,
	p_OLD_CONSUMPTION_CODE IN CHAR,
	p_OLD_RECEIVED_DATE  IN DATE,
	p_END_DATE IN DATE,
	p_CONSUMPTION_CODE IN CHAR,
	p_IGNORE_CONSUMPTION IN NUMBER,
	p_STATUS OUT NUMBER
	) AS

-- Update changed fields in CUSTOMER_CONSUMPTION table

BEGIN

    p_STATUS := GA.SUCCESS;

    UPDATE CUSTOMER_CONSUMPTION
    SET
        CONSUMPTION_CODE = UPPER(p_CONSUMPTION_CODE),
        END_DATE = p_END_DATE,
        IGNORE_CONSUMPTION = p_IGNORE_CONSUMPTION
	 WHERE
        CUSTOMER_ID = p_OLD_CUSTOMER_ID
        AND BEGIN_DATE = p_OLD_BEGIN_DATE
        AND END_DATE = p_OLD_END_DATE
        AND UPPER(BILL_CODE) = UPPER(p_OLD_BILL_CODE)
        AND UPPER(CONSUMPTION_CODE) = UPPER(p_OLD_CONSUMPTION_CODE)
        AND RECEIVED_DATE = p_OLD_RECEIVED_DATE
        ;


	EXCEPTION
	    WHEN OTHERS THEN
		    p_STATUS := SQLCODE;

END UPDATE_CUSTOMER_CONSUMPTION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_QUOTE_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_REPORT_TYPE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_QUOTE_ID IN NUMBER,
	p_POS_EVALUATION_ID IN NUMBER,
	p_SCREEN_ID IN NUMBER,
	p_REPORT_NAME IN VARCHAR2,
	p_FILTERS IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

--Answer a cursor to display on the Reports tab
--in QuoteManagement.
BEGIN

    p_STATUS := GA.SUCCESS;
    OPEN p_CURSOR FOR
    	SELECT  'XS.GET_QUOTE_REPORT' "Procedure" FROM DUAL;

END GET_QUOTE_REPORT;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SCHEDULER_TREE_FIELDS
	(
	p_SYSTEM_VIEW_NAME IN VARCHAR2,
	p_REPORT_NAME IN VARCHAR2,
	p_SQL_SELECT OUT VARCHAR2,
	p_SQL_FROM OUT VARCHAR2,
	p_SQL_WHERE OUT VARCHAR2
    ) AS
BEGIN
	-- You must specify three fields in p_SQL_SELECT. They should look like
	-- a select clause without the 'select' keyword. You may reference any field
	-- of INTERCHANGE_TRANSACTION table via table alias 'A' and a field of
	-- IT_STATUS tabl via table alias 'B'.
	-- If you do not need three fields (i.e. custom hierarchy does not have all
	-- three hierarchy levels) then use NULLs in the select clause - but you
	-- must specify exactly 3 fields.
	-- You do not need to specify TRANSACTION_ID or TRANSACTION_NAME - those will
	-- be added to the query automatically.
	-- The columns selected must have unique names and they cannot be any of the
	-- following values: TRANSACTION_NAME, TRANSACTION_ID, TRANSACTION_IS_ACTIVE.
	-- If using NULLs to pad the required 3 columns, give the columns aliases
	-- so that they have unique names.
	--
	-- The p_SQL_FROM parameter is optional. If you need to join in any tables
	-- for your custom tree then specify the tables here. You may not specify
	-- a table with an alias of 'A', 'B', or 'IDS' since those will be specified
	-- automatically (as INTERCHANGE_TRANSACTION, IT_STATUS, etc...). This should be
	-- a normal from clause but without the 'from' keyword.
	--
	-- If you do need p_SQL_FROM then you will probably need p_SQL_WHERE to
	-- specify the join conditions. If you do not need p_SQL_FROM you may still
	-- use p_SQL_WHERE for filter capabilities (since GET_SCHEDULER_TREE_FILTER
	-- below will not be called for standard Scheduler and Bids/Offers trees).
	-- This should be a normal where clause but without the 'where' keyword. Also,
	-- if all conditions are combined via OR (instead of AND) then you should
	-- surround the entire clause in parentheses.
	NULL;
END GET_SCHEDULER_TREE_FIELDS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_SCHEDULER_TREE_FILTER
	(
	p_SYSTEM_VIEW_NAME IN VARCHAR2,
	p_REPORT_NAME IN VARCHAR2,
	p_SQL_FROM OUT VARCHAR2,
	p_SQL_WHERE OUT VARCHAR2
    ) AS
BEGIN
	-- If you want a particular system view or report to get a filtered tree
	-- (showing only certain transactions) then you can do so here. Specify an
	-- optional from clause (that should use neither any single letter table
	-- aliases nor should it use the table alias 'IDS').
	-- You can also specify the optional where clause to join in any tables added
	-- in the from clause and also to provide filtering of which transactions
	-- will show up in the tree.
	NULL;
END GET_SCHEDULER_TREE_FILTER;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_MARKET_PRICE_TREE
	(
	p_INTERVAL IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
    ) AS
-- Answer a cursor with a market price tree hierarchy. The hierarchy must be four levels deep with
-- Market Prices at the bottom. Use Interval to filter market prices.
-- If fewer levels are required, the extra levels should be returned as "null"

-- The columns of the returned cursor should look like the following where the top three hierarchy
-- levels are just strings that are displayed in the nodes of those levels of the tree:
--        <Hierarchy Top Level>,
--        <Hierarchy Second Level>,
--        <Hierarchy Third Level>,
--        MARKET_PRICE.MARKET_PRICE_NAME,
--        MARKET_PRICE.MARKET_PRICE_ID
BEGIN
	p_STATUS := GA.SUCCESS;
    -- must override this to select a valid hierarchy into cursor
    OPEN p_CURSOR FOR
    	SELECT NULL FROM DUAL;
END GET_MARKET_PRICE_TREE;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_PROFILE_FROM_TO_DATES
	(
	p_PROFILE_ID IN NUMBER,
	p_TIME_ZONE IN VARCHAR,
	p_AS_OF_DATE IN DATE,
	p_FROM_DATE OUT DATE,
	p_TO_DATE OUT DATE,
	p_STATUS OUT NUMBER
	) AS

v_IS_EXTERNAL_PROFILE NUMBER := 0;
v_INTERVALS_PER_DAY NUMBER := 0;
v_ADJUST NUMBER(6,5) := 1/86400;	--Hourly default: 1 sec Adjustment to get midnite into proper HED day (for Hourly profiles)
v_STD_TIME_ZONE VARCHAR2(8);

-- Answer the BEGIN and END dates for the specified Profile

BEGIN

	p_STATUS := GA.SUCCESS;

    p_FROM_DATE := LOW_DATE;
    p_TO_DATE := LOW_DATE;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		p_STATUS := GA.NO_DATA_FOUND;
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		RAISE;
END GET_PROFILE_FROM_TO_DATES;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_LOAD_PROFILE_POINTS
	(
	p_PROFILE_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ALL_DATES IN NUMBER := 0,
	p_TIME_ZONE IN VARCHAR,
	p_AS_OF_DATE IN DATE,
	p_POINT_INDEX IN NUMBER := 1,  --g_DEFAULT_POINT_INDEX,
	p_ALL_INDEXES IN NUMBER := 0,
	p_DAY_SELECTION IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

-- Answer the PROFILE_POINTS for the specified Profile

v_INTERVALS_PER_DAY NUMBER := 24;
v_MODEL_ID NUMBER := GA.ELECTRIC_MODEL;        --Default. Will be set by PROFILE_INTERVAL
v_STD_TIME_ZONE VARCHAR2(8);
v_BEGIN_DATE DATE;
v_END_DATE DATE;

BEGIN

	p_STATUS := GA.SUCCESS;


EXCEPTION
	WHEN NO_DATA_FOUND THEN
		p_STATUS := GA.NO_DATA_FOUND;
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		RAISE;
END GET_LOAD_PROFILE_POINTS;
---------------------------------------------------------------------------------------------------
FUNCTION PROFILE_POINT_FOR_INDEX
	(
	p_PROFILE_ID IN NUMBER,
	p_POINT_INDEX IN NUMBER,
	p_POINT_DATE IN DATE,
	p_AS_OF_DATE IN DATE
	) RETURN NUMBER IS

v_POINT_VAL NUMBER;

BEGIN

		RETURN 0;   --g_NOT_ASSIGNED;


EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;   --g_NOT_ASSIGNED;

END PROFILE_POINT_FOR_INDEX;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_DAY_TYPE_PROFILE_POINTS
	(
	p_CAST_CONTEXT IN CAST_CONTEXT_TYPE,
	p_PROFILE_ID IN NUMBER,
	p_HISTORICAL_BEGIN_DATE IN DATE,
	p_HISTORICAL_END_DATE IN DATE,
	p_PROFILE_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_PROFILE_POINT IN OUT NOCOPY PROFILE_POINT_TABLE
	) AS

v_SECOND NUMBER(6,5);

BEGIN

	p_PROFILE_POINT := NULL;

END GET_DAY_TYPE_PROFILE_POINTS;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_PROFILE_POINTS_TABLE
	(
	p_PROFILE_ID IN NUMBER,
	p_POINT_INDEX IN NUMBER,
	p_CUT_HISTORICAL_BEGIN_DATE IN DATE,
	p_CUT_HISTORICAL_END_DATE IN DATE,
	p_PROFILE_AS_OF_DATE IN DATE,
	p_PROFILE_POINT IN OUT NOCOPY PROFILE_POINT_TABLE
	) AS

BEGIN

	p_PROFILE_POINT := NULL;

END GET_PROFILE_POINTS_TABLE;
----------------------------------------------------------------------------------------------------
PROCEDURE DAY_PROFILE
	(
	p_PROFILE_ID IN NUMBER,
	p_POINT_INDEX IN NUMBER := 1,  --g_DEFAULT_POINT_INDEX,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
	p_PROFILE_AS_OF_DATE IN DATE,
    p_INTERVAL_DIVISOR IN NUMBER,
	p_PROFILE IN OUT NOCOPY GA.NUMBER_TABLE
	) AS

-- Answer the day profile in effect for the specified forecast date

BEGIN

-- Extract the point value associated with each point hour.
	NULL;

END DAY_PROFILE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_PB_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_POSITION_TYPE IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_REPORT_NAME IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
    ) AS
BEGIN

     p_STATUS := GA.SUCCESS;

END GET_PB_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE BID_OFFER_TRANSACTION_LIST
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ACTION IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
    ) AS
v_SOMETHING_DONE BOOLEAN;
BEGIN
	p_STATUS := 1; -- non-zero will cause UI to display message
END BID_OFFER_TRANSACTION_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE LOAD_BALANCING_BALANCE_ALL
	(
    p_TRANSACTION_ID IN NUMBER,
    p_STATEMENT_TYPE IN NUMBER,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_AS_OF_DATE IN DATE,
    p_TIME_ZONE IN VARCHAR,
    p_STATUS OUT NUMBER
    ) AS
BEGIN
	-- Perform custom load balancing for all supplies for the
    -- specified transaction

	p_STATUS := GA.SUCCESS;

END LOAD_BALANCING_BALANCE_ALL;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_GAS_DELIVERY_REPORT
	(
	p_MODEL_ID IN NUMBER,
	p_REPORT_TYPE IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_ID_1 IN NUMBER,
	p_ID_2 IN NUMBER,
	p_ID_3 IN NUMBER,
	p_REPORT_NAME IN VARCHAR2,
	p_FILTERS IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

--Answer a cursor to display on the Reports tab
--in Gas Delivery.
BEGIN

    p_STATUS := GA.SUCCESS;
    OPEN p_CURSOR FOR
    	SELECT  'XS.GET_GAS_DELIVERY_REPORT' "Procedure" FROM DUAL;

END GET_GAS_DELIVERY_REPORT;
---------------------------------------------------------------------------------------------------
PROCEDURE INVOICE_EMAIL_MESSAGE_BODY
	(
	p_CALLING_MODULE IN VARCHAR2,
	p_MODEL_ID IN NUMBER,
	p_ENTITY_IDs IN ID_TABLE,
	p_EMAIL IN OUT NOCOPY ML.EMAIL_REC,
	p_SOMETHING_DONE OUT BOOLEAN
	) AS
BEGIN
	-- Set p_SOMETHING_DONE to TRUE if a custom message body is added here. Otherwise,
	-- a default body will be added.
	-- Use ML routines to add the message body (you can use add_attachment or begin_attachment,
	-- write*, end_attachment).
	p_SOMETHING_DONE := FALSE;
END INVOICE_EMAIL_MESSAGE_BODY;
---------------------------------------------------------------------------------------------------
PROCEDURE INVOICE_EMAIL_ADD_ATTACHMENTS
	(
	p_CALLING_MODULE IN VARCHAR2,
	p_MODEL_ID IN NUMBER,
	p_ENTITY_IDs IN ID_TABLE,
	p_EMAIL IN OUT NOCOPY ML.EMAIL_REC
	) AS
BEGIN
	-- Use the ML routines to add any additional attachments to the e-mail
	NULL;
END INVOICE_EMAIL_ADD_ATTACHMENTS;
---------------------------------------------------------------------------------------------------
PROCEDURE DEAL_EVAL_GET_TRANSACTIONS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SOMETHING_DONE OUT BOOLEAN,
	p_IDs OUT ID_TABLE
	) AS
BEGIN
	-- need to customize the transactions shown in the Deal Evaluation screen of Load Balancing?
	-- Implement this hook to populate p_IDs - then set p_SOMETHING_DONE = TRUE.
	p_SOMETHING_DONE := FALSE;
END DEAL_EVAL_GET_TRANSACTIONS;
---------------------------------------------------------------------------------------------------
PROCEDURE BEFORE_DEAL_EVAL_COMMIT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is committed?
	-- Implement this hook
	NULL;
END BEFORE_DEAL_EVAL_COMMIT;
---------------------------------------------------------------------------------------------------
PROCEDURE BEFORE_DEAL_EVAL_UNDO
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is rolled back?
	-- Implement this hook
	NULL;
END BEFORE_DEAL_EVAL_UNDO;
---------------------------------------------------------------------------------------------------
PROCEDURE BEFORE_DEAL_EVAL_REJECT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is rejected?
	-- Implement this hook
	NULL;
END BEFORE_DEAL_EVAL_REJECT;
---------------------------------------------------------------------------------------------------
PROCEDURE BEFORE_DEAL_EVAL_RESTORE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is restored (opposite of rejected)?
	-- Implement this hook
	NULL;
END BEFORE_DEAL_EVAL_RESTORE;
---------------------------------------------------------------------------------------------------
PROCEDURE AFTER_DEAL_EVAL_COMMIT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is committed?
	-- Implement this hook
	NULL;
END AFTER_DEAL_EVAL_COMMIT;
---------------------------------------------------------------------------------------------------
PROCEDURE AFTER_DEAL_EVAL_UNDO
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is rolled back (undone - opposite of committed)?
	-- Implement this hook
	NULL;
END AFTER_DEAL_EVAL_UNDO;
---------------------------------------------------------------------------------------------------
PROCEDURE AFTER_DEAL_EVAL_REJECT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is rejected?
	-- Implement this hook
	NULL;
END AFTER_DEAL_EVAL_REJECT;
---------------------------------------------------------------------------------------------------
PROCEDURE AFTER_DEAL_EVAL_RESTORE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER
	) AS
BEGIN
	-- need to add other processing for when a deal is restored (opposite of rejected)?
	-- Implement this hook
	NULL;
END AFTER_DEAL_EVAL_RESTORE;
---------------------------------------------------------------------------------------------------
PROCEDURE DEAL_EVAL_GET_DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_IDs IN ID_TABLE,
	p_SOMETHING_DONE OUT BOOLEAN,
	p_OUT_BEGIN_DATE OUT DATE,
	p_OUT_END_DATE OUT DATE
	) AS
BEGIN
	-- need to customize the begin and end date/times of the evaluation for selected supplies?
	-- Implement this hook and set the out-bound begin and end dates - and set p_SOMETHING_DONE = TRUE.
	--
	-- Use LB.GET_DEAL_EVAL_DATE_RANGE to get default date range (in case date range should pretty much
	-- match default date range but with some tweaks).

	p_SOMETHING_DONE := FALSE;
END DEAL_EVAL_GET_DATE_RANGE;
---------------------------------------------------------------------------------------------------
PROCEDURE DEAL_EVAL_PERFORM_EVAL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_AS_OF_DATE IN DATE,
	p_SCHEDULE_TYPE IN NUMBER,
	p_TIME_ZONE IN VARCHAR2,
	p_LOAD_TRANSACTION_ID IN NUMBER,
	p_DYNAMIC_TRANSACTION_ID IN NUMBER,
	p_SUPPLY_TRANSACTION_ID IN NUMBER,
	p_OPTION_ID IN NUMBER,
	p_SOMETHING_DONE OUT BOOLEAN
	) AS
BEGIN
	-- need to customize the actual evaluation of a supply deal?
	-- Implement this hook (should populate BALANCE_TRANSACTION_SCHEDULE table with OPTION_ID = p_OPTION_ID)
	-- and set p_SOMETHING_DONE = TRUE.
	--
	-- Use LB.DEFAULT_EVALUATION to perform a standard deal evaluation (in case evaluation should be pretty much
	-- standard, but with pre or post-processing).

	p_SOMETHING_DONE := FALSE;
END DEAL_EVAL_PERFORM_EVAL;
---------------------------------------------------------------------------------------------------
PROCEDURE CAN_DELETE_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_CAN_DELETE OUT BOOLEAN
	) AS
BEGIN
  -- PUT ANY BUSINESS RULES GOVERNING THE DELETION OF INTERCHANGE_TRANSACTIONs here.

	p_CAN_DELETE := TRUE;
END CAN_DELETE_TRANSACTION;
---------------------------------------------------------------------------------------------------
PROCEDURE PRE_MARKET_EXCHANGE
    (
    p_EXTERNAL_SYSTEM_ID IN NUMBER,
    p_EXCHANGE_NAME IN VARCHAR2,
	p_OTHER_PARAMS IN UT.STRING_MAP,
    p_CONTENTS IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) AS
BEGIN

	-- Implement this hook
	NULL;

END PRE_MARKET_EXCHANGE;
---------------------------------------------------------------------------------------------------
PROCEDURE POST_MARKET_EXCHANGE
    (
    p_EXTERNAL_SYSTEM_ID IN NUMBER,
    p_EXCHANGE_NAME IN VARCHAR2,
	p_OTHER_PARAMS IN UT.STRING_MAP,
    p_CONTENTS IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) AS
BEGIN

	-- Implement this hook
	NULL;

END POST_MARKET_EXCHANGE;
---------------------------------------------------------------------------------------------------
PROCEDURE AFTER_ACCEPT_VPPS_TO_SCHEDULES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_SERVICE_CODE IN CHAR,
	p_IS_EXTERNAL IN NUMBER,
	p_VPP_IDs IN NUMBER_COLLECTION
	) AS
BEGIN

	-- Implement this hook
	NULL;

END AFTER_ACCEPT_VPPS_TO_SCHEDULES;
---------------------------------------------------------------------------------------------------
PROCEDURE PROXY_USAGE_PROFILE
	(
	p_FORECAST_DATE IN DATE,
	p_PROXY_DAY_METHOD_ID IN NUMBER,
	p_ACCOUNT_SERVICE_ID IN NUMBER,
	p_PROVIDER_SERVICE_ID IN NUMBER,
	p_CANDIDATE_DATES IN DATE_COLLECTION, -- ORDERED BY DELTA, ASCENDING
	p_HAS_PROXY_PROFILE OUT BOOLEAN,
	p_PROFILE_SOURCE_DATE OUT DATE,
	p_PROFILE IN OUT NOCOPY GA.NUMBER_TABLE
	) AS

BEGIN
	-- Implement this hook
	p_HAS_PROXY_PROFILE := FALSE;
	NULL;

END PROXY_USAGE_PROFILE;
---------------------------------------------------------------------------------------------------
PROCEDURE PRE_ACCOUNT_SYNC
	(
	p_IS_FULL_SYNC IN NUMBER := 0,
	p_BEGIN_DATE IN DATE := NULL
	) AS
BEGIN
	-- Implement this hook
	NULL;
END PRE_ACCOUNT_SYNC;
---------------------------------------------------------------------------------------------------
PROCEDURE POST_ACCOUNT_SYNC
	(
	p_IS_FULL_SYNC IN NUMBER := 0,
	p_BEGIN_DATE IN DATE := NULL
	) AS
BEGIN
	-- Implement this hook
	NULL;
END POST_ACCOUNT_SYNC;
---------------------------------------------------------------------------------------------------
PROCEDURE PRE_PROCESS_BILL_CASE
(
	p_BILL_CASE_ID		IN BILL_CASE.BILL_CASE_ID%TYPE
) AS
BEGIN
	-- Implement this hook
	LOGS.LOG_DEBUG('Procedure: PRE_PROCESS_BILL_CASE');
	LOGS.LOG_DEBUG('Bill Case ID: ' || p_BILL_CASE_ID);
END PRE_PROCESS_BILL_CASE;
---------------------------------------------------------------------------------------------------
PROCEDURE PRE_GENERATE_BILL_CASE_RESULTS
(
	p_BILL_CASE_ID		IN BILL_CASE.BILL_CASE_ID%TYPE
) AS
BEGIN
	-- Implement this hook
	LOGS.LOG_DEBUG('Procedure: PRE_GENERATE_BILL_CASE_RESULTS');
	LOGS.LOG_DEBUG('Bill Case ID: ' || p_BILL_CASE_ID);
END PRE_GENERATE_BILL_CASE_RESULTS;
---------------------------------------------------------------------------------------------------
PROCEDURE POST_PROCESS_BILL_CASE
(
	p_BILL_CASE_ID		IN BILL_CASE.BILL_CASE_ID%TYPE
) AS
BEGIN
	-- Implement this hook
	LOGS.LOG_DEBUG('Procedure: POST_PROCESS_BILL_CASE');
	LOGS.LOG_DEBUG('Bill Case ID: ' || p_BILL_CASE_ID);
END POST_PROCESS_BILL_CASE;
END XS;
/

