CREATE OR REPLACE PACKAGE GA AS
--Revision $Revision: 1.96 $

-- Global Area package.

-- Types
TYPE STRING_TABLE IS TABLE OF VARCHAR(256) INDEX BY BINARY_INTEGER;
TYPE BIG_STRING_TABLE IS TABLE OF VARCHAR(4000) INDEX BY BINARY_INTEGER;
TYPE NUMBER_TABLE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE ID_TABLE IS TABLE OF NUMBER(9) INDEX BY BINARY_INTEGER;
TYPE COUNT_TABLE IS TABLE OF NUMBER(6) INDEX BY BINARY_INTEGER;
TYPE DATE_TABLE IS TABLE OF DATE INDEX BY BINARY_INTEGER;
TYPE BOOLEAN_TABLE IS TABLE OF BOOLEAN INDEX BY BINARY_INTEGER;
TYPE BYTE_TABLE IS TABLE OF CHAR(1) INDEX BY BINARY_INTEGER;
TYPE FACTOR_TABLE IS TABLE OF NUMBER(20,8) INDEX BY BINARY_INTEGER;
TYPE FLOAT_TABLE IS TABLE OF NUMBER(20,8) INDEX BY BINARY_INTEGER;
-- This should be used instead of SYS_REFCURSOR to work-around oracle bug
-- that causes ORA-06504 exception in PL/SQL code when using SYS_REFCURSOR
TYPE REFCURSOR IS REF CURSOR;

-- International Name of SUNDAY
g_SUN CONSTANT VARCHAR2(16) := TO_CHAR(DATE '2006-01-01', 'DY');
g_SUNDAY CONSTANT VARCHAR2(16) := TO_CHAR(DATE '2006-01-01', 'DAY');

-- Exception Code Constants
SUCCESS CONSTANT NUMBER := 0;
DUPLICATE_ENTITY CONSTANT NUMBER := -1;
INSUFFICIENT_PRIVILEGES CONSTANT NUMBER := -2;
NO_DATA_FOUND CONSTANT NUMBER := -3;
EMPTY_TABLE CONSTANT NUMBER := -4;
INVALID_INTERNAL_ID CONSTANT NUMBER := -5;
CATEGORY_IN_USE CONSTANT NUMBER := -6;
TOO_MANY_ROWS CONSTANT NUMBER := -7;
INVALID_DATE_RANGE CONSTANT NUMBER := -8;
GENERAL_EXCEPTION CONSTANT NUMBER := -9;
NO_SYSTEM_DATE_TIME CONSTANT NUMBER := -10;
EMPTY_STRING CONSTANT CHAR(1) := ' ';
UNDEFINED_ATTRIBUTE CONSTANT CHAR(1) := '?';

-- Load Code Constants Used in Service Load and Service Obligation Load tables.
STANDARD CONSTANT CHAR(1) := '1';
WEEK_DAY CONSTANT CHAR(1) := '2';
WEEK_END CONSTANT CHAR(1) := '3';
EXTERNAL CONSTANT CHAR(1) := '4';
PRIOR_PERIOD CONSTANT CHAR(1) := '5';
ADJUSTMENT CONSTANT CHAR(1) := '6';
ANY_DAY CONSTANT CHAR(1) := '7';
-- Service Code Constants Used in Service Load and Service Obligation Load tables.
FORECAST_SERVICE CONSTANT CHAR(1) := 'F';
BACKCAST_SERVICE CONSTANT CHAR(1) := 'B';
ACTUAL_SERVICE CONSTANT CHAR(1) := 'A';
HISTORICAL_SERVICE CONSTANT CHAR(1) := 'H';
-- Bill Code Constants Used in Service and Customer Consumption tables.
BILL_CONSUMPTION CONSTANT CHAR(1) := 'B';
CANCEL_CONSUMPTION CONSTANT CHAR(1) := 'C';
REBILL_CONSUMPTION CONSTANT CHAR(1) := 'R';
NOBILL_CONSUMPTION CONSTANT CHAR(1) := 'N';
-- Consumption Code Constants Used in Service and Customer Consumption tables.
FORECAST_CONSUMPTION CONSTANT CHAR(1) := 'F';
PRELIMINARY_CONSUMPTION CONSTANT CHAR(1) := 'P';
ACTUAL_CONSUMPTION CONSTANT CHAR(1) := 'A';
HISTORICAL_CONSUMPTION CONSTANT CHAR(1) := 'H';

-- Global Constants.
GLOBAL_MODEL CONSTANT NUMBER(1) := 0;
ELECTRIC_MODEL CONSTANT NUMBER(1) := 1;
GAS_MODEL CONSTANT NUMBER(1) := 2;
STANDARD_MODE CONSTANT NUMBER(1) := 0;
STATEMENT_MODE CONSTANT NUMBER(1) := 1;
ACCOUNT_GROUP_MODE CONSTANT NUMBER(1) := 2;
ANCILLARY_SERVICE_MODE CONSTANT NUMBER(1) := 3;
HOUR_MODE CONSTANT NUMBER(1) := 0;
DAY_MODE CONSTANT NUMBER(2) := 1;
WEEK_MODE CONSTANT NUMBER(2) := 2;
MONTH_MODE CONSTANT NUMBER(2) := 3;
REVENUE_STATE CONSTANT NUMBER(1) := 1;
COST_STATE CONSTANT NUMBER(1) := 2;
BILLING_STATE CONSTANT NUMBER(1) := 3;
BASE_SCENARIO_ID CONSTANT NUMBER(1) := 1;
BASE_CASE_ID CONSTANT NUMBER(1) := 1;
HOUR_DIVISOR CONSTANT NUMBER := 1/24;

--Scheduling constants
INTERNAL_STATE CONSTANT NUMBER(1) := 1;
EXTERNAL_STATE CONSTANT NUMBER(1) := 2;
SCHEDULE_TYPE_FORECAST CONSTANT NUMBER(1) := 1;
SCHEDULE_TYPE_PRELIM CONSTANT NUMBER(1) := 2;
SCHEDULE_TYPE_FINAL CONSTANT NUMBER(1) := 3;
COMMITTED_OPTION_ID CONSTANT NUMBER(1) := 0;


-- Customer System Configuration...

LOCAL_TIME_ZONE CONSTANT VARCHAR2(4) := GA_UTIL.LOAD_STRING('General','Local Time Zone','EDT',3,4); -- value returned from function of the same name
CUT_TIME_ZONE CONSTANT VARCHAR2(4) := GA_UTIL.LOAD_STRING('General','CUT Time Zone','EST',3,4);   -- value returned from function of the same name

CUSTOMER_USAGE_WRF_MIN_POINTS CONSTANT NUMBER(2) := GA_UTIL.LOAD_NUMBER('Profiling','Customer Usage WRF Min.Points',5,0); -- The minimum number of meter reads (points) required to calculate a Customer Usage WRF, below which the default is applied.
WIND_CHILL_TEMP_THRESHOLD CONSTANT NUMBER(3) := GA_UTIL.LOAD_NUMBER('Profiling','Wind Chill Temp.Threshold',0); -- The threshold value used in the Temperature check.
DST_SPRING_AHEAD_OPTION CONSTANT CHAR(1) := GA_UTIL.LOAD_STRING('General','DST Spring-Ahead Option','A',STRING_COLLECTION('A','B','C')); -- Conversion from a 24 hour pattern to a 23 hour pattern: A-Ignore hour 2:00 AM, B-Ignore hour 3:00 AM, C-Ignore hour 24:00 PM.
DST_FALL_BACK_OPTION CONSTANT CHAR(1) := GA_UTIL.LOAD_STRING('General','DST Fall-Back Option','A',STRING_COLLECTION('A','B')); -- Conversion from a 24 hour pattern to a 25 hour pattern: A-repeat hour 2:00 AM, B-Use first 24 hours and supply a zero for hour 25.
SINGLE_TX_SERVICE_POINT_ID CONSTANT NUMBER(9) := GA_UTIL.LOAD_NUMBER('Forecast/Settlement','Single Service Point ID', 0, 0); -- Single TX Service Point ID Option, used with ENABLE_SINGLE_TX_SERVICE_POINT.
AGGREGATE_BILLED_USAGE_OPTION CONSTANT CHAR(3) := GA_UTIL.LOAD_STRING('Forecast/Settlement','Aggregate Billed Usage Option','ENR',STRING_COLLECTION('ENR','SVC')); -- Aggregate Billed Usage Has Two Display options: 'ENR' joins with the Aggregate_Account_Service table, 'SVC' joins with the Service table.

DEFAULT_MODEL CONSTANT NUMBER(1) := GA_UTIL.LOAD_NUMBER('General','Default Model', 1, 1, 2); -- The installation deployment model at the Customer site: 1 - Electric, 2 - Gas;
INVOICE_LINE_ITEM_OPTION CONSTANT CHAR(1) := GA_UTIL.LOAD_STRING('Billing','Invoice Line Item Option','2',STRING_COLLECTION('1','2','3','4','X')); -- Create Invoices with either Product (1), Product-Component (2) , or Account-Service Location-Meter-Product-Component (3) as line items
CAST_COMMIT_THRESHOLD CONSTANT NUMBER(4) := GA_UTIL.LOAD_NUMBER('Forecast/Settlement','Cast Commit Threshold',6,0);  -- If The number of days in a Cast is greater than the Threshold value then an Incremental Commit will be performed after processing each day.

ENFORCE_UNIQUE_NAMES CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('General','Enforce Unique Names',TRUE); -- Accounts, Service Locations, and Meters have unique names
USE_LOAD_PROFILE_STANDARD_DAY CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Profiling','Use Load Profile Standard Day',TRUE); -- Historical Load Profile uses a standard day (ST/DT)
USAGE_FACTOR_PER_UNIT_OPTION CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Usage Factor Per Unit Option',TRUE); -- Account and meter usage factors are treated as per unit; otherwise as a percent
USE_INTERVAL_USAGE_IN_BACKCAST CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Use Interval Usage in Backcast',TRUE); -- Use actual usage if available for the backcast day for interval metered accounts in lieu of profiled usage in backcast.
ENABLE_EXTERNAL_METER_ACCESS CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable External Meter Access',FALSE); -- Enable access to external meter data (interval and consumption)
ENABLE_PRODUCTION_PROFILE_MSG CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Non-Production Profile Message',TRUE); -- Post a message to the app event log for non-production profiles in Forecast/Backcast.
ENFORCE_PRODUCTION_PROFILE_USE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enforce Production Profile Use',TRUE); -- Only use load profiles with a status of production in Forecast/Backcast.
ENABLE_SUPPLY_SCHEDULE_TYPES CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Scheduling','Enable Supply Schedule Types',TRUE); -- Enable Supply (Purchase, Sale, Generation, Pass-Thru) Schedules to allow Schedule Types (Forecast, Preliminary, Final).
APPLY_PRIOR_BILL_CHARGES CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Billing','Apply Prior Bill Charges',TRUE); -- Enable calculation of Bill amounts alongside Charge amounts (Bill amounts = Charge amount - Prior Period Charge amount).
ENABLE_ESP_POOL_ASSIGNMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable ESP-Pool Assignment',TRUE); -- Enable the assignment and use of ESPs to Pools; otherwise default assignment to Not Assigned.
ENABLE_PSE_ESP_ASSIGNMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable PSE-ESP Assignment',TRUE); -- Enable the assignment and use of PSEs to ESPs; otherwise default assignment to Not Assigned.
ENABLE_BACKCAST_ADJ_SCHEDULES CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Backcast Adj.Schedules',FALSE); -- Enable the creation of Backcast  Adjustment Load Schedules.
ENABLE_SYSTEM_UFE_LOAD_CHECK CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable System UFE Load Check',FALSE); -- Enable the check for the presence of System Load used in the UFE calculations.
ENABLE_WIND_CHILL_TEMP_CHECK CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Profiling','Enable Wind-Chill Temp.Check',FALSE); -- Enable the check for Temperature values above a specified threshold within a day, to determine whether the  Wind Chill calculation is to be performed.
ENABLE_ZERO_MINIMUM_SCHEDULE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Zero Minimum Schedule',FALSE); -- Enable a Schedule amount to be zero and not subject to the EDC Minimum Schedule amount.
ENABLE_NON_AGG_UFE_SETTLEMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Non-Agg.UFE Settlement',TRUE); -- Enable a Non-Aggregate Account to participate in the UFE calculations for Preliminary and Final Settlement (based upon their UFE Participation attribute).
ENABLE_AGG_POST_ESP_ASSIGNMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Agg.Post-ESP Assignment',FALSE); -- Enable Post ESP Assignments i.e. create Aggregate Account ESP entries when necessary.
ENABLE_SERVICE_RETENTION CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Service Retention',TRUE); -- Enable the retention (non-deletion) of service records when prior-period service enrollment changes are made.
ENABLE_RTM_PROCESS_MODE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable RTM Process Mode',FALSE); -- Enable the Retail Transaction Manager processing mode.
ENABLE_CUSTOMER_MODEL CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Customer','Enable Customer Model',FALSE); -- Enable the representation and processing of the Customer Model.
ENABLE_CUSTOMER_CAST CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Customer','Enable Customer Cast',FALSE); -- Enable the Customer Model to Perform Customer Forecast, Backcast, Usage Allocation, and Charge Application.
ENABLE_LOAD_SCHEDULE_DELETE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Load Schedule Delete',TRUE);-- Enable the deletion of Load Schedules prior to Accepting a new set of Load Schedules.
ENABLE_SCHED_GROUP_ASSIGNMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Sched.Group Assignment',TRUE);-- Enable the assignment and use of Schedule Groups; otherwise default assignment to Not Assigned.
ENABLE_SINGLE_TX_SERVICE_POINT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Single Service Point',FALSE);-- Enable the assignment and use of a single TX Service Point assignment.
ENABLE_WEATHER_INDEX_SAVE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Profiling','Enable Weather Index Save Calcs',TRUE);  -- Enable the saving of the Effective Temperature Calculation used with Weather-Indexed Profiles.
ENABLE_IN_FILL_AGG_ENROLLMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Zero-Fill Agg.Enrollment ',TRUE); -- Enables the filling of zero enrollment values for user entry
ENABLE_CONSUMPTION_END_DATE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Consumption End Date',TRUE); -- Enable the Use of the Service Consumption Period End Date as the Effective Date of the Rate; Otherwise Use the Consumption Period Begin Date.
ENABLE_SCHEDULE_GROSS_UP CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Schedule Gross Up',FALSE); -- Enable the Gross-Up of Week-Day and Week-End Long-Term Forecast Schedules derived from Patterns; Otherwise Use the Pattern as is.
ENABLE_REVERSE_SIGN_INVOICES CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Billing','Enable Reverse Sign Invoices',FALSE); -- Reverse the sign of charge amounts and quantities when generating invoices?
ENABLE_ACTUAL_LOSSES_RECALC CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Actual Losses Recalc.',FALSE); -- Enable the recalculation of Actual Service Losses for Non-Aggregate Accounts during the Settlement Process.
ENABLE_AGGREGATE_POOL_MODEL CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Aggregate Pool Model',FALSE); -- Enable the use of the Aggregate Pool Model where PSE and ESP relationships are not directly tied to individual Accounts.
ENABLE_CALENDAR_TRIGGERS CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Profiling','Enable Calendar Triggers',TRUE); -- Enable the triggers on Calendar Profile Library Post, Calendar Profile Post, and Calendar Adjustment Post to fire.
CSB_IS_SUBDAILY CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('General','CSB Is Subdaily', FALSE);

-- Version Control Configuration...
VERSION_AREA_LOAD CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Area Load',FALSE); -- Enable Area Load to accomodate versions.
VERSION_PROFILE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Profile',FALSE); -- Enable Load Profiles to accomodate versions.
VERSION_FORECAST CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Forecast',FALSE); -- Enable Forecast Usage to accomodate versions.
VERSION_BACKCAST CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Backcast',FALSE); -- Enable Backcast Usage to accomodate versions.
VERSION_ACTUAL CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Actual',FALSE); -- Enable Actual Usage to accomodate versions.
VERSION_SCHEDULE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Schedule',FALSE); -- Enable Schedules to accomodate versions.
VERSION_STATEMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Statement',FALSE); -- Enable Billing Statements to accomodate versions.
VERSION_MARKET_PRICE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Market Price',FALSE); -- Enable Market Prices to accomodate versions.
VERSION_AGGREGATE_ACCOUNT_SVC CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Aggregate Account Service',FALSE); -- Enable Aggregate Account Service to accomodate versions.
VERSION_AGGREGATE_ANCILARY_SVC CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Aggregate Ancillary Service',FALSE); -- Enable Aggregate Ancillary Service to accomodate versions.
VERSION_SHADOW_SETTLEMENT CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Shadow Settlement',FALSE);  -- Enable Shadow Settlement to accomodate versions.
VERSION_CONSUMPTION CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Consumption',FALSE); -- Enable Consumption to accomodate versions.
VERSION_CUSTOMER_USAGE_WRF CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Version','Version Customer Usage WRF',FALSE); -- Enable Customer Usage WRF to accomodate versions.

-- Performance tuning options --
/*
 * Enable caching of profiles in memory when running Forecast or Backcast.
 * Set to TRUE if you have many accounts using very few profiles.
 * Set to FALSE if you have a very large number of accounts using mostly distinct profiles.
 */
ENABLE_RUNTIME_PROFILE_CACHE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Run-Time Profile Cache',TRUE);

ENABLE_IS_WHOLESALE_LOOKUP CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Is Wholesale Lookup',TRUE); -- If set to FALSE, CX.GET_IS_WHOLESALE will always return FALSE --
ENABLE_HOLIDAYS CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('General','Enable Holidays',TRUE); -- If set to FALSE, IS_HOLIDAY will always return FALSE --

/**
 * Set to ENABLE to allow the Forecast/Backcast engine only accumulate Service Obligation data
 *  and not save detail-level data; detail-level data is then done on-demand in UI procedures.
 */
CAST_SUMMARY_ONLY_MODE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Summary Only Mode',FALSE);

/**
 * Set to TRUE to allow Proxy Day Forecast data to come from the XS.PROXY_USAGE_PROFILE procedure, otherwise it
 * will not be called.
 */
ENABLE_EXTERNAL_PROXY_DATA CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','External Proxy Day Data',FALSE);

/*
 * Enable periodic write of SERVICE_LOAD cache in Forecast and Backcast.
 * Works in conjunction with CAST_CACHE_FLUSH_THRESHOLD.
 * Set to TRUE if SERVICE_LOAD caching exceeds PGA upper memory limit.
 */
ENABLE_CAST_CACHE_FLUSH CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Cast Cache Flush',TRUE);

/*
 * Number of SERVICE_LOAD records to cache in Forecast and Backcast.
 * Works in conjunction with ENABLE_CAST_CACHE_FLUSH.
 * Set to non-zero number if SERVICE_LOAD caching exceeds PGA upper memory limit.
 */
CAST_CACHE_FLUSH_THRESHOLD CONSTANT INTEGER := GA_UTIL.LOAD_NUMBER('Forecast/Settlement','Cast Cache Flush Threshold',10000,0);

/*
 * Determines whether the SERVICE_STATE_DELETE trigger will
 * delete external forecast data.
 * Set to true if the external forecast data should be deleted with the
 * rest of the forecast.
 */
ENABLE_EXTERNAL_CAST_DELETE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable External Cast Delete',FALSE);

/*
 * Enable/Disable storing of the customer service load
 * for the forecast or backcast
 */
STORE_CUST_SVC_LOAD_FORECAST     CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Customer','Store Customer Service Load Forecast',FALSE);
STORE_CUST_SVC_LOAD_BACKCAST     CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Customer','Store Customer Service Load Backcast',TRUE);

/*
 * Enable/Disable logic that deals with UFE participation
 * Set to FALSE, if no UFE needed
 */
ENABLE_RESET_UFE_PARTICIPATION CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Reset UFE Participation',TRUE);

/*
 * If you always use the same EDC Loss Factor value, set the
 * ENABLE_... constant to TRUE, and set the constant value you want to use
 * in the CONST_... constant below.  This is a performance improvement.
 */
ENABLE_CONST_EDC_LOSS_FACTOR CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Forecast/Settlement','Enable Constant EDC Loss Factor',FALSE);
CONST_EDC_LOSS_FACTOR_VALUE CONSTANT VARCHAR2(16) := GA_UTIL.LOAD_STRING('Forecast/Settlement','Constant EDC Loss Factor Value','EDC'); -- how to validate this setting? what are possible options?

/**
 * If this site is using Direct-Oracle-Login mode - where each user actually
 * has their own Oracle schema with grants to the main application schema.
 */
DIRECT_ORACLE_LOGIN_MODE CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Security','Direct-Oracle-Login Mode',FALSE);

/**
 * Should log-on and log-off events generate application event log entries?
 */
EVENT_LOG_FOR_LOGON_LOGOFF CONSTANT BOOLEAN := GA_UTIL.LOAD_BOOLEAN('Security','Log Events for Logon/Logoff',TRUE);

/**
 * Enable Audit Trail for certain types of processes
 */
AUDIT_PROCESSES CONSTANT BOOLEAN := FALSE;
AUDIT_USER_SESSIONS CONSTANT BOOLEAN := TRUE;

-- Unit of Measurement values used by the service-level result tables.
GAS_UNIT_OF_MEASURMENT CONSTANT VARCHAR2(16) := GA_UTIL.LOAD_STRING('General','Gas Unit of Measurement','thm');
ELECTRIC_UNIT_OF_MEASURMENT CONSTANT VARCHAR2(16) := GA_UTIL.LOAD_STRING('General','Electric Unit of Measurement','kwh');
DEFAULT_UNIT_OF_MEASUREMENT CONSTANT VARCHAR2(16) := CASE WHEN DEFAULT_MODEL = GAS_MODEL THEN GAS_UNIT_OF_MEASURMENT ELSE ELECTRIC_UNIT_OF_MEASURMENT END;

-- Unit of Measurement values used by the aggregated accepted schedule-level results.
GAS_SCHED_UNIT_OF_MEASURMENT CONSTANT VARCHAR2(16) := GA_UTIL.LOAD_STRING('General','Gas Unit of Measurement - Schedules','Dth');
ELEC_SCHED_UNIT_OF_MEASURMENT CONSTANT VARCHAR2(16) := GA_UTIL.LOAD_STRING('General','Electric Unit of Measurement - Schedules','Mwh');
DEF_SCHED_UNIT_OF_MEASUREMENT CONSTANT VARCHAR2(16) := CASE WHEN DEFAULT_MODEL = GAS_MODEL THEN GAS_SCHED_UNIT_OF_MEASURMENT ELSE ELEC_SCHED_UNIT_OF_MEASURMENT END;

DETERMINANT_DATE_THRESHOLD CONSTANT NUMBER(9) := GA_UTIL.LOAD_NUMBER('Financial Settlement', 'Retail Determinant Date Threshold', 0);

FUNCTION WHAT_VERSION RETURN VARCHAR2;

END GA;
/
