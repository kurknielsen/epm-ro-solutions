CREATE OR REPLACE TYPE DETERMINANT_ACCESSOR AS OBJECT
(
-- $Revision: 1.12 $
-- Author  : JHUMPHRIES
-- Created : 12/4/2009 11:52:28 AM
-- Purpose : Interface for accessing determinants for use by RETAIL_PRICING package

TIME_ZONE			VARCHAR2(16),
TAXED_COMPONENTS	PRICING_RESULT_TABLE,
COMPONENT_NAME VARCHAR2(256),
-------------------------------------------------------------------------------

-- Returns a table of taxable pricing results. By default, all parameters are
-- ignored and the entire contents of the TAXED_COMPONENTS field are returned.
-- This method can be overridden to provide more sophisticated behavior if
-- necessary.
-- %param p_BEGIN_DATE			The begin date of the bill period.
-- %param p_END_DATE			The end date of the bill period.
-- %param p_SERVICE_POINT_ID	The service point associated with the Tax
--								component. This can be used to filter
--								results so that only applicable charges are
--								returned.
MEMBER FUNCTION GET_TAXABLE_CHARGES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_SERVICE_POINT_ID IN NUMBER
	) RETURN PRICING_RESULT_TABLE,

-- Adds a taxable pricing result to the determinant’s internal collection of
-- taxable results (to the TAX_COMPONENTS field).
-- %param p_PRICING_RESULT		The result of a taxable component to add.
MEMBER PROCEDURE ADD_TAXABLE_CHARGE
	(
	p_PRICING_RESULT IN PRICING_RESULT
	),

-- Clears this determinant’s internal collection of taxable charges (the
-- TAX_COMPONENTS field).
MEMBER PROCEDURE CLEAR_TAXABLE_CHARGES,

-- Returns the single maximum/peak determinant value. This is used by Peak
-- Demand components and used in evaluating block/tier ranges for Demand Hours
-- components. When determinants are non-interval data, the “demand” reading is
-- used, not the “energy” reading.
-- %param p_INTERVAL	When this value is ‘Meter Period’, non-interval data
--						will be used if available. Otherwise, if it is ‘Day’
--						or greater, the date range is expected to be a span
--						of days; but if it is sub-daily the date range is
--						expected to be in CUT time.
-- %param p_BEGIN_DATE	The begin date of the bill period.
-- %param p_END_DATE	The end date of the bill period.
-- %param p_UOM			The unit of measurement of the determinants to query.
-- %param p_TEMPLATE_ID	If not NULL, only retrieve results for a particular
--						time of use period.
-- %param p_PERIOD_ID	Required if p_TEMPLATE_ID is not NULL. Identifies
--						from which time of use period to query determinants.
-- %param p_LOSS_ADJ_TYPE	Type of loss-adjustment, if any, to apply to
--						determinants. This currently only applies to interval
--						metered usage for retail account determinants.
-- %param p_INTEGRATION_INTERVAL  An optional parameter that specifies the number
--                      of intervals to integrate together before selecting
--                      peak interval. For example, if the data was 15 minute
--                      and the peak was determined by Averaging the data every 30
--                      minutes then you would specify a value of '30 Minute'. This only
--                      applies to sub-daily data.
-- %param p_RETURN_VALUE	The result peak value.
-- %param p_RETURN_STATUS	The status of the determinants used to find the
--						result value: 0 = OK, 1 = Missing (result will be 0),
--						or 2 = Partial. Partial for interval data means that
--						data did not exist for the full date range; for non-
--						interval data, it means that period records that span
--						the entire date range were not found.
MEMBER PROCEDURE GET_PEAK_DETERMINANT
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := NULL, -- NULL interpreted as GA.DEFAULT_UNIT_OF_MEASUREMENT
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTEGRATION_INTERVAL IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	),

-- Returns the sum of determinant values. This is used by most components
-- including all of the following charge types: Energy, Commodity, Demand
-- Hours, Transportation, Transmission, and Distribution. When determinants are
-- non-interval data, the “energy” reading is used, not the “demand” reading.
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
MEMBER PROCEDURE GET_SUM_DETERMINANTS
	(
	p_INTERVAL IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_UOM IN VARCHAR2 := NULL, -- NULL interpreted as GA.DEFAULT_UNIT_OF_MEASUREMENT
	p_TEMPLATE_ID IN NUMBER := NULL,
	p_PERIOD_ID IN NUMBER := NULL,
	p_LOSS_ADJ_TYPE IN NUMBER := NULL,
	p_INTERVAL_MINIMUM_QTY IN NUMBER := NULL,
	p_OPERATION_CODE IN VARCHAR2 := NULL,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	),

-- Returns the effective ancillary service value. This is used by several
-- standard charge types: Power Factor, Capacity, and Excess Capacity
-- Surcharge.
-- %param p_DATE			The effective date for which to query (should
--							be the end date of the bill period).
-- %param p_ANCILLARY_SERVICE_ID	The ancillary service whose value is queried.
-- %param p_RETURN_VALUE	The result effective value.
-- %param p_RETURN_STATUS	The status of the determinants used to find
--							the result value: 0 = OK or 1 = Missing
--							(result will be 0).
MEMBER PROCEDURE GET_EFFECTIVE_ANC_SVC
	(
	p_DATE IN DATE,
	p_ANCILLARY_SERVICE_ID IN NUMBER,
	p_RETURN_VALUE OUT NUMBER,
	p_RETURN_STATUS OUT PLS_INTEGER
	),

-- Returns the “meter type” as a TOU Template ID.
-- %param p_DATE	The effective date for which to query (should
--					be the end date of the bill period).
-- %return			The result Template ID, NULL if there is no
--					meter type/Template ID, or -1 if there are
--					multiple Template IDs (like a meter-modeled
--					account with meters associated with more than
--					one template).
MEMBER FUNCTION GET_METER_TYPE_TEMPLATE_ID
	(
	p_DATE IN DATE
	) RETURN NUMBER,

-- Gets formula context values for this accessor.
-- %return	The mappings for this accessor
MEMBER FUNCTION GET_FORMULA_CONTEXTS RETURN MAP_ENTRY_TABLE,

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
MEMBER PROCEDURE GET_AVERAGE_INTERVAL_COUNT
	(
	p_INVOICE_LINE_BEGIN_DATE 	IN DATE,
	p_INVOICE_LINE_END_DATE 	IN DATE,
	p_UOM 						IN VARCHAR2 := NULL,
	p_QUALITY_CODE 				IN VARCHAR2 := NULL,
	p_STATUS_CODE 				IN VARCHAR2 := NULL,
	p_DATE_RANGE_INTERVAL		IN VARCHAR2 := NULL,
	p_RETURN_VALUE 				OUT NUMBER,
	p_RETURN_STATUS 			OUT PLS_INTEGER
	)

) NOT FINAL;
/
