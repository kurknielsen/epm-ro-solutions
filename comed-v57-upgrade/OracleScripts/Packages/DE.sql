CREATE OR REPLACE PACKAGE DE AS
-- Revision: $Revision: 1.33 $

-- Delete Entity package

-- NOTE: This package is AUTO-GENERATED

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE DEL_ACCOUNT
	(
	p_ACCOUNT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_ACCOUNT_GROUP
	(
	p_ACCOUNT_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_ANCILLARY_SERVICE
	(
	p_ANCILLARY_SERVICE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_AREA
	(
	p_AREA_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_BILL_CYCLE
	(
	p_BILL_CYCLE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_BILL_PARTY
	(
	p_BILL_PARTY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_BREAKPOINT
	(
	p_BREAKPOINT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CA
	(
	p_CA_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CALC_PROCESS
	(
	p_CALC_PROCESS_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CALENDAR
	(
	p_CALENDAR_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CASE_LABEL
	(
	p_CASE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CATEGORY
	(
	p_CATEGORY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_COMPONENT
	(
	p_COMPONENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CONDITIONAL_FORMAT
	(
	p_CONDITIONAL_FORMAT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CONTACT
	(
	p_CONTACT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CONTRACT
	(
	p_CONTRACT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CONTRACT_LIMIT
	(
	p_LIMIT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_CUSTOMER
	(
	p_CUSTOMER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_DER
	(
	p_DER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_DER_TYPE
	(
	p_DER_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_DR_EVENT
	(
	p_EVENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_EDC
	(
	p_EDC_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_ENTITY_DOMAIN
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_ENTITY_GROUP
	(
	p_ENTITY_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_ESP
	(
	p_ESP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_ETAG
	(
	p_ETAG_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_EXTERNAL_SYSTEM
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_EXTERNAL_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_GEOGRAPHY
	(
	p_GEOGRAPHY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_GROWTH_PATTERN
	(
	p_PATTERN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_HEAT_RATE_CURVE
	(
	p_HEAT_RATE_CURVE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_HOLIDAY
	(
	p_HOLIDAY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_HOLIDAY_SET
	(
	p_HOLIDAY_SET_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_INTERCHANGE_CONTRACT
	(
	p_CONTRACT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_INVOICE_GROUP
	(
	p_INVOICE_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_IT_COMMODITY
	(
	p_COMMODITY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_LOAD_PROFILE
	(
	p_PROFILE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_LOAD_PROFILE_LIBRARY
	(
	p_PROFILE_LIBRARY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_LOAD_PROFILE_SET
	(
	p_PROFILE_SET_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_LOSS_FACTOR
	(
	p_LOSS_FACTOR_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_MARKET_PRICE
	(
	p_MARKET_PRICE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_MEASUREMENT_SOURCE
	(
	p_MEASUREMENT_SOURCE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_METER
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_MRSP
	(
	p_MRSP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_OASIS_NODE
	(
	p_OASIS_NODE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PATH
	(
	p_PATH_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PERIOD
	(
	p_PERIOD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PIPELINE
	(
	p_PIPELINE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_POOL
	(
	p_POOL_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PORTFOLIO
	(
	p_PORTFOLIO_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_POSITION_EVALUATION
	(
	p_EVALUATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PRODUCT
	(
	p_PRODUCT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PROGRAM
	(
	p_PROGRAM_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PROSPECT_SCREEN
	(
	p_SCREEN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PROXY_DAY_METHOD
	(
	p_PROXY_DAY_METHOD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_PSE
	(
	p_PSE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_QUOTE_REQUEST
	(
	p_QUOTE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_REACTOR_PROCEDURE
	(
	p_REACTOR_PROCEDURE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_RESOURCE_GROUP
	(
	p_RESOURCE_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_ROLLUP
	(
	p_ROLLUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SC
	(
	p_SC_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SCENARIO
	(
	p_SCENARIO_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SCHEDULE_GROUP
	(
	p_SCHEDULE_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SEASON
	(
	p_SEASON_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SEGMENT
	(
	p_SEGMENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SERVICE_AREA
	(
	p_SERVICE_AREA_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SERVICE_LOCATION
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SERVICE_POINT
	(
	p_SERVICE_POINT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SERVICE_REGION
	(
	p_SERVICE_REGION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SERVICE_TYPE
	(
	p_SERVICE_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SERVICE_ZONE
	(
	p_SERVICE_ZONE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SETTLEMENT_TYPE
	(
	p_SETTLEMENT_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_STATEMENT_TYPE
	(
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SUB_STATION
	(
	p_SUB_STATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SUB_STATION_METER
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SUB_STATION_METER_POINT
	(
	p_METER_POINT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SUPPLY_RESOURCE
	(
	p_RESOURCE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SYSTEM_ACTION
	(
	p_ACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SYSTEM_ALERT
	(
	p_ALERT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SYSTEM_EVENT
	(
	p_EVENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SYSTEM_LOAD
	(
	p_SYSTEM_LOAD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SYSTEM_REALM
	(
	p_REALM_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_SYSTEM_TABLE
	(
	p_TABLE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_TEMPLATE
	(
	p_TEMPLATE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_TP
	(
	p_TP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_TRANSACTION_TRAIT_GROUP
	(
	p_TRAIT_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_TX_FEEDER
	(
	p_FEEDER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_TX_FEEDER_SEGMENT
	(
	p_FEEDER_SEGMENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_USAGE_WRF
	(
	p_WRF_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_VPP
	(
	p_VPP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_WEATHER_PARAMETER
	(
	p_PARAMETER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

PROCEDURE DEL_WEATHER_STATION
	(
	p_STATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);


END DE;
/

CREATE OR REPLACE PACKAGE BODY DE AS
---------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.33 $';
END WHAT_VERSION;
---------------------------------------------------------------------
PROCEDURE DEL_ACCOUNT
	(
	p_ACCOUNT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ACCOUNT_ID, EC.ED_ACCOUNT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ACCOUNT
    WHERE ACCOUNT_ID = p_ACCOUNT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_ACCOUNT,
                                                                        p_ACCOUNT_ID));

END DEL_ACCOUNT;
---------------------------------------------------------------------
PROCEDURE DEL_ACCOUNT_GROUP
	(
	p_ACCOUNT_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ACCOUNT_GROUP_ID, EC.ED_ACCOUNT_GROUP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ACCOUNT_GROUP
    WHERE ACCOUNT_GROUP_ID = p_ACCOUNT_GROUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_ACCOUNT_GROUP,
                                                                        p_ACCOUNT_GROUP_ID));

END DEL_ACCOUNT_GROUP;
---------------------------------------------------------------------
PROCEDURE DEL_ANCILLARY_SERVICE
	(
	p_ANCILLARY_SERVICE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ANCILLARY_SERVICE_ID, EC.ED_ANCILLARY_SERVICE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ANCILLARY_SERVICE
    WHERE ANCILLARY_SERVICE_ID = p_ANCILLARY_SERVICE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_ANCILLARY_SERVICE,
                                                                        p_ANCILLARY_SERVICE_ID));

END DEL_ANCILLARY_SERVICE;
---------------------------------------------------------------------
PROCEDURE DEL_AREA
	(
	p_AREA_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_AREA_ID, EC.ED_AREA);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM AREA
    WHERE AREA_ID = p_AREA_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_AREA,
                                                                        p_AREA_ID));

END DEL_AREA;
---------------------------------------------------------------------
PROCEDURE DEL_BILL_CYCLE
	(
	p_BILL_CYCLE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_BILL_CYCLE_ID, EC.ED_BILL_CYCLE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM BILL_CYCLE
    WHERE BILL_CYCLE_ID = p_BILL_CYCLE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_BILL_CYCLE,
                                                                        p_BILL_CYCLE_ID));

END DEL_BILL_CYCLE;
---------------------------------------------------------------------
PROCEDURE DEL_BILL_PARTY
	(
	p_BILL_PARTY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_BILL_PARTY_ID, EC.ED_BILL_PARTY);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM BILL_PARTY
    WHERE BILL_PARTY_ID = p_BILL_PARTY_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_BILL_PARTY,
                                                                        p_BILL_PARTY_ID));

END DEL_BILL_PARTY;
---------------------------------------------------------------------
PROCEDURE DEL_BREAKPOINT
	(
	p_BREAKPOINT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	-- Make sure user has access
	IF NOT CAN_DELETE('Data Setup') THEN
        ERRS.RAISE_NO_DELETE_MODULE('Data Setup');
	END IF;
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM BREAKPOINT
    WHERE BREAKPOINT_ID = p_BREAKPOINT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    
												
             ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
																					NULL,
																					p_BREAKPOINT_ID));

END DEL_BREAKPOINT;
---------------------------------------------------------------------
PROCEDURE DEL_CA
	(
	p_CA_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CA_ID, EC.ED_CA);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CONTROL_AREA
    WHERE CA_ID = p_CA_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CA,
                                                                        p_CA_ID));

END DEL_CA;
---------------------------------------------------------------------
PROCEDURE DEL_CALC_PROCESS
	(
	p_CALC_PROCESS_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CALC_PROCESS_ID, EC.ED_CALC_PROCESS);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CALCULATION_PROCESS
    WHERE CALC_PROCESS_ID = p_CALC_PROCESS_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CALC_PROCESS,
                                                                        p_CALC_PROCESS_ID));

END DEL_CALC_PROCESS;
---------------------------------------------------------------------
PROCEDURE DEL_CALENDAR
	(
	p_CALENDAR_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CALENDAR_ID, EC.ED_CALENDAR);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CALENDAR
    WHERE CALENDAR_ID = p_CALENDAR_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CALENDAR,
                                                                        p_CALENDAR_ID));

END DEL_CALENDAR;
---------------------------------------------------------------------
PROCEDURE DEL_CASE_LABEL
	(
	p_CASE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CASE_ID, EC.ED_CASE_LABEL);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CASE_LABEL
    WHERE CASE_ID = p_CASE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CASE_LABEL,
                                                                        p_CASE_ID));

END DEL_CASE_LABEL;
---------------------------------------------------------------------
PROCEDURE DEL_CATEGORY
	(
	p_CATEGORY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CATEGORY_ID, EC.ED_CATEGORY);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CATEGORY
    WHERE CATEGORY_ID = p_CATEGORY_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CATEGORY,
                                                                        p_CATEGORY_ID));

END DEL_CATEGORY;
---------------------------------------------------------------------
PROCEDURE DEL_COMPONENT
	(
	p_COMPONENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_COMPONENT_ID, EC.ED_COMPONENT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM COMPONENT
    WHERE COMPONENT_ID = p_COMPONENT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_COMPONENT,
                                                                        p_COMPONENT_ID));

END DEL_COMPONENT;
---------------------------------------------------------------------
PROCEDURE DEL_CONDITIONAL_FORMAT
	(
	p_CONDITIONAL_FORMAT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CONDITIONAL_FORMAT_ID, EC.ED_CONDITIONAL_FORMAT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CONDITIONAL_FORMAT
    WHERE CONDITIONAL_FORMAT_ID = p_CONDITIONAL_FORMAT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CONDITIONAL_FORMAT,
                                                                        p_CONDITIONAL_FORMAT_ID));

END DEL_CONDITIONAL_FORMAT;
---------------------------------------------------------------------
PROCEDURE DEL_CONTACT
	(
	p_CONTACT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CONTACT_ID, EC.ED_CONTACT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CONTACT
    WHERE CONTACT_ID = p_CONTACT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CONTACT,
                                                                        p_CONTACT_ID));

END DEL_CONTACT;
---------------------------------------------------------------------
PROCEDURE DEL_CONTRACT
	(
	p_CONTRACT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CONTRACT_ID, EC.ED_CONTRACT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SERVICE_CONTRACT
    WHERE CONTRACT_ID = p_CONTRACT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CONTRACT,
                                                                        p_CONTRACT_ID));

END DEL_CONTRACT;
---------------------------------------------------------------------
PROCEDURE DEL_CONTRACT_LIMIT
	(
	p_LIMIT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_LIMIT_ID, EC.ED_CONTRACT_LIMIT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CONTRACT_LIMIT
    WHERE LIMIT_ID = p_LIMIT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CONTRACT_LIMIT,
                                                                        p_LIMIT_ID));

END DEL_CONTRACT_LIMIT;
---------------------------------------------------------------------
PROCEDURE DEL_CUSTOMER
	(
	p_CUSTOMER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CUSTOMER_ID, EC.ED_CUSTOMER);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM CUSTOMER
    WHERE CUSTOMER_ID = p_CUSTOMER_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_CUSTOMER,
                                                                        p_CUSTOMER_ID));

END DEL_CUSTOMER;
---------------------------------------------------------------------
PROCEDURE DEL_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_DATA_LOCK_GROUP_ID, EC.ED_DATA_LOCK_GROUP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM DATA_LOCK_GROUP
    WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_DATA_LOCK_GROUP,
                                                                        p_DATA_LOCK_GROUP_ID));

END DEL_DATA_LOCK_GROUP;
---------------------------------------------------------------------
PROCEDURE DEL_DER
	(
	p_DER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_DER_ID, EC.ED_DER);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM DISTRIBUTED_ENERGY_RESOURCE
    WHERE DER_ID = p_DER_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_DER,
                                                                        p_DER_ID));

END DEL_DER;
---------------------------------------------------------------------
PROCEDURE DEL_DER_TYPE
	(
	p_DER_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_DER_TYPE_ID, EC.ED_DER_TYPE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM DER_TYPE
    WHERE DER_TYPE_ID = p_DER_TYPE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_DER_TYPE,
                                                                        p_DER_TYPE_ID));

END DEL_DER_TYPE;
---------------------------------------------------------------------
PROCEDURE DEL_DR_EVENT
	(
	p_EVENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_EVENT_ID, EC.ED_DR_EVENT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM DR_EVENT
    WHERE EVENT_ID = p_EVENT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_DR_EVENT,
                                                                        p_EVENT_ID));

END DEL_DR_EVENT;
---------------------------------------------------------------------
PROCEDURE DEL_EDC
	(
	p_EDC_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_EDC_ID, EC.ED_EDC);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ENERGY_DISTRIBUTION_COMPANY
    WHERE EDC_ID = p_EDC_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_EDC,
                                                                        p_EDC_ID));

END DEL_EDC;
---------------------------------------------------------------------
PROCEDURE DEL_ENTITY_DOMAIN
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ENTITY_DOMAIN_ID, EC.ED_ENTITY_DOMAIN);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ENTITY_DOMAIN
    WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_ENTITY_DOMAIN,
                                                                        p_ENTITY_DOMAIN_ID));

END DEL_ENTITY_DOMAIN;
---------------------------------------------------------------------
PROCEDURE DEL_ENTITY_GROUP
	(
	p_ENTITY_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ENTITY_GROUP_ID, EC.ED_ENTITY_GROUP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ENTITY_GROUP
    WHERE ENTITY_GROUP_ID = p_ENTITY_GROUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_ENTITY_GROUP,
                                                                        p_ENTITY_GROUP_ID));

END DEL_ENTITY_GROUP;
---------------------------------------------------------------------
PROCEDURE DEL_ESP
	(
	p_ESP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ESP_ID, EC.ED_ESP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ENERGY_SERVICE_PROVIDER
    WHERE ESP_ID = p_ESP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_ESP,
                                                                        p_ESP_ID));

END DEL_ESP;
---------------------------------------------------------------------
PROCEDURE DEL_ETAG
	(
	p_ETAG_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ETAG_ID, EC.ED_ETAG);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM ETAG
    WHERE ETAG_ID = p_ETAG_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_ETAG,
                                                                        p_ETAG_ID));

END DEL_ETAG;
---------------------------------------------------------------------
PROCEDURE DEL_EXTERNAL_SYSTEM
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_EXTERNAL_SYSTEM_ID, EC.ED_EXTERNAL_SYSTEM);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM EXTERNAL_SYSTEM
    WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_EXTERNAL_SYSTEM,
                                                                        p_EXTERNAL_SYSTEM_ID));

END DEL_EXTERNAL_SYSTEM;
---------------------------------------------------------------------
PROCEDURE DEL_EXTERNAL_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_TRANSACTION_ID, EC.ED_EXTERNAL_TRANSACTION);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM INTERCHANGE_TRANSACTION_EXT
    WHERE TRANSACTION_ID = p_TRANSACTION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_EXTERNAL_TRANSACTION,
                                                                        p_TRANSACTION_ID));

END DEL_EXTERNAL_TRANSACTION;
---------------------------------------------------------------------
PROCEDURE DEL_GEOGRAPHY
	(
	p_GEOGRAPHY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_GEOGRAPHY_ID, EC.ED_GEOGRAPHY);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM GEOGRAPHY
    WHERE GEOGRAPHY_ID = p_GEOGRAPHY_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_GEOGRAPHY,
                                                                        p_GEOGRAPHY_ID));

END DEL_GEOGRAPHY;
---------------------------------------------------------------------
PROCEDURE DEL_GROWTH_PATTERN
	(
	p_PATTERN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PATTERN_ID, EC.ED_GROWTH_PATTERN);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM GROWTH_PATTERN
    WHERE PATTERN_ID = p_PATTERN_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_GROWTH_PATTERN,
                                                                        p_PATTERN_ID));

END DEL_GROWTH_PATTERN;
---------------------------------------------------------------------
PROCEDURE DEL_HEAT_RATE_CURVE
	(
	p_HEAT_RATE_CURVE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_HEAT_RATE_CURVE_ID, EC.ED_HEAT_RATE_CURVE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM HEAT_RATE_CURVE
    WHERE HEAT_RATE_CURVE_ID = p_HEAT_RATE_CURVE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_HEAT_RATE_CURVE,
                                                                        p_HEAT_RATE_CURVE_ID));

END DEL_HEAT_RATE_CURVE;
---------------------------------------------------------------------
PROCEDURE DEL_HOLIDAY
	(
	p_HOLIDAY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_HOLIDAY_ID, EC.ED_HOLIDAY);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM HOLIDAY
    WHERE HOLIDAY_ID = p_HOLIDAY_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_HOLIDAY,
                                                                        p_HOLIDAY_ID));

END DEL_HOLIDAY;
---------------------------------------------------------------------
PROCEDURE DEL_HOLIDAY_SET
	(
	p_HOLIDAY_SET_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_HOLIDAY_SET_ID, EC.ED_HOLIDAY_SET);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM HOLIDAY_SET
    WHERE HOLIDAY_SET_ID = p_HOLIDAY_SET_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_HOLIDAY_SET,
                                                                        p_HOLIDAY_SET_ID));

END DEL_HOLIDAY_SET;
---------------------------------------------------------------------
PROCEDURE DEL_INTERCHANGE_CONTRACT
	(
	p_CONTRACT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_CONTRACT_ID, EC.ED_INTERCHANGE_CONTRACT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM INTERCHANGE_CONTRACT
    WHERE CONTRACT_ID = p_CONTRACT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_INTERCHANGE_CONTRACT,
                                                                        p_CONTRACT_ID));

END DEL_INTERCHANGE_CONTRACT;
---------------------------------------------------------------------
PROCEDURE DEL_INVOICE_GROUP
	(
	p_INVOICE_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_INVOICE_GROUP_ID, EC.ED_INVOICE_GROUP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM INVOICE_GROUP
    WHERE INVOICE_GROUP_ID = p_INVOICE_GROUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_INVOICE_GROUP,
                                                                        p_INVOICE_GROUP_ID));

END DEL_INVOICE_GROUP;
---------------------------------------------------------------------
PROCEDURE DEL_IT_COMMODITY
	(
	p_COMMODITY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_COMMODITY_ID, EC.ED_IT_COMMODITY);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM IT_COMMODITY
    WHERE COMMODITY_ID = p_COMMODITY_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_IT_COMMODITY,
                                                                        p_COMMODITY_ID));

END DEL_IT_COMMODITY;
---------------------------------------------------------------------
PROCEDURE DEL_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_JOB_THREAD_ID, EC.ED_JOB_THREAD);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM JOB_THREAD
    WHERE JOB_THREAD_ID = p_JOB_THREAD_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_JOB_THREAD,
                                                                        p_JOB_THREAD_ID));

END DEL_JOB_THREAD;
---------------------------------------------------------------------
PROCEDURE DEL_LOAD_PROFILE
	(
	p_PROFILE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PROFILE_ID, EC.ED_LOAD_PROFILE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM LOAD_PROFILE
    WHERE PROFILE_ID = p_PROFILE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_LOAD_PROFILE,
                                                                        p_PROFILE_ID));

END DEL_LOAD_PROFILE;
---------------------------------------------------------------------
PROCEDURE DEL_LOAD_PROFILE_LIBRARY
	(
	p_PROFILE_LIBRARY_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PROFILE_LIBRARY_ID, EC.ED_LOAD_PROFILE_LIBRARY);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM LOAD_PROFILE_LIBRARY
    WHERE PROFILE_LIBRARY_ID = p_PROFILE_LIBRARY_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_LOAD_PROFILE_LIBRARY,
                                                                        p_PROFILE_LIBRARY_ID));

END DEL_LOAD_PROFILE_LIBRARY;
---------------------------------------------------------------------
PROCEDURE DEL_LOAD_PROFILE_SET
	(
	p_PROFILE_SET_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	-- Make sure user has access
	IF NOT CAN_DELETE('Data Setup') THEN
        ERRS.RAISE_NO_DELETE_MODULE('Data Setup');
	END IF;
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM LOAD_PROFILE_SET
    WHERE PROFILE_SET_ID = p_PROFILE_SET_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    
												
             ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
																					NULL,
																					p_PROFILE_SET_ID));

END DEL_LOAD_PROFILE_SET;
---------------------------------------------------------------------
PROCEDURE DEL_LOSS_FACTOR
	(
	p_LOSS_FACTOR_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_LOSS_FACTOR_ID, EC.ED_LOSS_FACTOR);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM LOSS_FACTOR
    WHERE LOSS_FACTOR_ID = p_LOSS_FACTOR_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_LOSS_FACTOR,
                                                                        p_LOSS_FACTOR_ID));

END DEL_LOSS_FACTOR;
---------------------------------------------------------------------
PROCEDURE DEL_MARKET_PRICE
	(
	p_MARKET_PRICE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_MARKET_PRICE_ID, EC.ED_MARKET_PRICE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM MARKET_PRICE
    WHERE MARKET_PRICE_ID = p_MARKET_PRICE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_MARKET_PRICE,
                                                                        p_MARKET_PRICE_ID));

END DEL_MARKET_PRICE;
---------------------------------------------------------------------
PROCEDURE DEL_MEASUREMENT_SOURCE
	(
	p_MEASUREMENT_SOURCE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_MEASUREMENT_SOURCE_ID, EC.ED_MEASUREMENT_SOURCE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM MEASUREMENT_SOURCE
    WHERE MEASUREMENT_SOURCE_ID = p_MEASUREMENT_SOURCE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_MEASUREMENT_SOURCE,
                                                                        p_MEASUREMENT_SOURCE_ID));

END DEL_MEASUREMENT_SOURCE;
---------------------------------------------------------------------
PROCEDURE DEL_METER
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_METER_ID, EC.ED_METER);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM METER
    WHERE METER_ID = p_METER_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_METER,
                                                                        p_METER_ID));

END DEL_METER;
---------------------------------------------------------------------
PROCEDURE DEL_MRSP
	(
	p_MRSP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_MRSP_ID, EC.ED_MRSP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM METER_READING_SERVICE_PROVIDER
    WHERE MRSP_ID = p_MRSP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_MRSP,
                                                                        p_MRSP_ID));

END DEL_MRSP;
---------------------------------------------------------------------
PROCEDURE DEL_OASIS_NODE
	(
	p_OASIS_NODE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_OASIS_NODE_ID, EC.ED_OASIS_NODE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM OASIS_NODE
    WHERE OASIS_NODE_ID = p_OASIS_NODE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_OASIS_NODE,
                                                                        p_OASIS_NODE_ID));

END DEL_OASIS_NODE;
---------------------------------------------------------------------
PROCEDURE DEL_PATH
	(
	p_PATH_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PATH_ID, EC.ED_PATH);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_PATH
    WHERE PATH_ID = p_PATH_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PATH,
                                                                        p_PATH_ID));

END DEL_PATH;
---------------------------------------------------------------------
PROCEDURE DEL_PERIOD
	(
	p_PERIOD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PERIOD_ID, EC.ED_PERIOD);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PERIOD
    WHERE PERIOD_ID = p_PERIOD_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PERIOD,
                                                                        p_PERIOD_ID));

END DEL_PERIOD;
---------------------------------------------------------------------
PROCEDURE DEL_PIPELINE
	(
	p_PIPELINE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PIPELINE_ID, EC.ED_PIPELINE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PIPELINE
    WHERE PIPELINE_ID = p_PIPELINE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PIPELINE,
                                                                        p_PIPELINE_ID));

END DEL_PIPELINE;
---------------------------------------------------------------------
PROCEDURE DEL_POOL
	(
	p_POOL_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_POOL_ID, EC.ED_POOL);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM POOL
    WHERE POOL_ID = p_POOL_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_POOL,
                                                                        p_POOL_ID));

END DEL_POOL;
---------------------------------------------------------------------
PROCEDURE DEL_PORTFOLIO
	(
	p_PORTFOLIO_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PORTFOLIO_ID, EC.ED_PORTFOLIO);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PORTFOLIO
    WHERE PORTFOLIO_ID = p_PORTFOLIO_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PORTFOLIO,
                                                                        p_PORTFOLIO_ID));

END DEL_PORTFOLIO;
---------------------------------------------------------------------
PROCEDURE DEL_POSITION_EVALUATION
	(
	p_EVALUATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	-- Make sure user has access
	IF NOT CAN_DELETE('Data Setup') THEN
        ERRS.RAISE_NO_DELETE_MODULE('Data Setup');
	END IF;
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM POSITION_ANALYSIS_EVALUATION
    WHERE EVALUATION_ID = p_EVALUATION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    
												
             ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
																					NULL,
																					p_EVALUATION_ID));

END DEL_POSITION_EVALUATION;
---------------------------------------------------------------------
PROCEDURE DEL_PRODUCT
	(
	p_PRODUCT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PRODUCT_ID, EC.ED_PRODUCT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PRODUCT
    WHERE PRODUCT_ID = p_PRODUCT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PRODUCT,
                                                                        p_PRODUCT_ID));

END DEL_PRODUCT;
---------------------------------------------------------------------
PROCEDURE DEL_PROGRAM
	(
	p_PROGRAM_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PROGRAM_ID, EC.ED_PROGRAM);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PROGRAM
    WHERE PROGRAM_ID = p_PROGRAM_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PROGRAM,
                                                                        p_PROGRAM_ID));

END DEL_PROGRAM;
---------------------------------------------------------------------
PROCEDURE DEL_PROSPECT_SCREEN
	(
	p_SCREEN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	-- Make sure user has access
	IF NOT CAN_DELETE('Data Setup') THEN
        ERRS.RAISE_NO_DELETE_MODULE('Data Setup');
	END IF;
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PROSPECT_SCREEN
    WHERE SCREEN_ID = p_SCREEN_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    
												
             ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
																					NULL,
																					p_SCREEN_ID));

END DEL_PROSPECT_SCREEN;
---------------------------------------------------------------------
PROCEDURE DEL_PROXY_DAY_METHOD
	(
	p_PROXY_DAY_METHOD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PROXY_DAY_METHOD_ID, EC.ED_PROXY_DAY_METHOD);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PROXY_DAY_METHOD
    WHERE PROXY_DAY_METHOD_ID = p_PROXY_DAY_METHOD_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PROXY_DAY_METHOD,
                                                                        p_PROXY_DAY_METHOD_ID));

END DEL_PROXY_DAY_METHOD;
---------------------------------------------------------------------
PROCEDURE DEL_PSE
	(
	p_PSE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PSE_ID, EC.ED_PSE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM PURCHASING_SELLING_ENTITY
    WHERE PSE_ID = p_PSE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_PSE,
                                                                        p_PSE_ID));

END DEL_PSE;
---------------------------------------------------------------------
PROCEDURE DEL_QUOTE_REQUEST
	(
	p_QUOTE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_QUOTE_ID, EC.ED_QUOTE_REQUEST);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM QUOTE_REQUEST
    WHERE QUOTE_ID = p_QUOTE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_QUOTE_REQUEST,
                                                                        p_QUOTE_ID));

END DEL_QUOTE_REQUEST;
---------------------------------------------------------------------
PROCEDURE DEL_REACTOR_PROCEDURE
	(
	p_REACTOR_PROCEDURE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_REACTOR_PROCEDURE_ID, EC.ED_REACTOR_PROCEDURE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM REACTOR_PROCEDURE
    WHERE REACTOR_PROCEDURE_ID = p_REACTOR_PROCEDURE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_REACTOR_PROCEDURE,
                                                                        p_REACTOR_PROCEDURE_ID));

END DEL_REACTOR_PROCEDURE;
---------------------------------------------------------------------
PROCEDURE DEL_RESOURCE_GROUP
	(
	p_RESOURCE_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_RESOURCE_GROUP_ID, EC.ED_RESOURCE_GROUP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SUPPLY_RESOURCE_GROUP
    WHERE RESOURCE_GROUP_ID = p_RESOURCE_GROUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_RESOURCE_GROUP,
                                                                        p_RESOURCE_GROUP_ID));

END DEL_RESOURCE_GROUP;
---------------------------------------------------------------------
PROCEDURE DEL_ROLLUP
	(
	p_ROLLUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	-- Make sure user has access
	IF NOT CAN_DELETE('Data Setup') THEN
        ERRS.RAISE_NO_DELETE_MODULE('Data Setup');
	END IF;
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM RTO_ROLLUP
    WHERE ROLLUP_ID = p_ROLLUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    
												
             ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
																					NULL,
																					p_ROLLUP_ID));

END DEL_ROLLUP;
---------------------------------------------------------------------
PROCEDURE DEL_SC
	(
	p_SC_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SC_ID, EC.ED_SC);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SCHEDULE_COORDINATOR
    WHERE SC_ID = p_SC_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SC,
                                                                        p_SC_ID));

END DEL_SC;
---------------------------------------------------------------------
PROCEDURE DEL_SCENARIO
	(
	p_SCENARIO_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SCENARIO_ID, EC.ED_SCENARIO);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SCENARIO
    WHERE SCENARIO_ID = p_SCENARIO_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SCENARIO,
                                                                        p_SCENARIO_ID));

END DEL_SCENARIO;
---------------------------------------------------------------------
PROCEDURE DEL_SCHEDULE_GROUP
	(
	p_SCHEDULE_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SCHEDULE_GROUP_ID, EC.ED_SCHEDULE_GROUP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SCHEDULE_GROUP
    WHERE SCHEDULE_GROUP_ID = p_SCHEDULE_GROUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SCHEDULE_GROUP,
                                                                        p_SCHEDULE_GROUP_ID));

END DEL_SCHEDULE_GROUP;
---------------------------------------------------------------------
PROCEDURE DEL_SEASON
	(
	p_SEASON_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SEASON_ID, EC.ED_SEASON);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SEASON
    WHERE SEASON_ID = p_SEASON_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SEASON,
                                                                        p_SEASON_ID));

END DEL_SEASON;
---------------------------------------------------------------------
PROCEDURE DEL_SEGMENT
	(
	p_SEGMENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SEGMENT_ID, EC.ED_SEGMENT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_SEGMENT
    WHERE SEGMENT_ID = p_SEGMENT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SEGMENT,
                                                                        p_SEGMENT_ID));

END DEL_SEGMENT;
---------------------------------------------------------------------
PROCEDURE DEL_SERVICE_AREA
	(
	p_SERVICE_AREA_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SERVICE_AREA_ID, EC.ED_SERVICE_AREA);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SERVICE_AREA
    WHERE SERVICE_AREA_ID = p_SERVICE_AREA_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SERVICE_AREA,
                                                                        p_SERVICE_AREA_ID));

END DEL_SERVICE_AREA;
---------------------------------------------------------------------
PROCEDURE DEL_SERVICE_LOCATION
	(
	p_SERVICE_LOCATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SERVICE_LOCATION_ID, EC.ED_SERVICE_LOCATION);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SERVICE_LOCATION
    WHERE SERVICE_LOCATION_ID = p_SERVICE_LOCATION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SERVICE_LOCATION,
                                                                        p_SERVICE_LOCATION_ID));

END DEL_SERVICE_LOCATION;
---------------------------------------------------------------------
PROCEDURE DEL_SERVICE_POINT
	(
	p_SERVICE_POINT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SERVICE_POINT_ID, EC.ED_SERVICE_POINT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SERVICE_POINT
    WHERE SERVICE_POINT_ID = p_SERVICE_POINT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SERVICE_POINT,
                                                                        p_SERVICE_POINT_ID));

END DEL_SERVICE_POINT;
---------------------------------------------------------------------
PROCEDURE DEL_SERVICE_REGION
	(
	p_SERVICE_REGION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SERVICE_REGION_ID, EC.ED_SERVICE_REGION);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SERVICE_REGION
    WHERE SERVICE_REGION_ID = p_SERVICE_REGION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SERVICE_REGION,
                                                                        p_SERVICE_REGION_ID));

END DEL_SERVICE_REGION;
---------------------------------------------------------------------
PROCEDURE DEL_SERVICE_TYPE
	(
	p_SERVICE_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SERVICE_TYPE_ID, EC.ED_SERVICE_TYPE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_SERVICE_TYPE
    WHERE SERVICE_TYPE_ID = p_SERVICE_TYPE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SERVICE_TYPE,
                                                                        p_SERVICE_TYPE_ID));

END DEL_SERVICE_TYPE;
---------------------------------------------------------------------
PROCEDURE DEL_SERVICE_ZONE
	(
	p_SERVICE_ZONE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SERVICE_ZONE_ID, EC.ED_SERVICE_ZONE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SERVICE_ZONE
    WHERE SERVICE_ZONE_ID = p_SERVICE_ZONE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SERVICE_ZONE,
                                                                        p_SERVICE_ZONE_ID));

END DEL_SERVICE_ZONE;
---------------------------------------------------------------------
PROCEDURE DEL_SETTLEMENT_TYPE
	(
	p_SETTLEMENT_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SETTLEMENT_TYPE_ID, EC.ED_SETTLEMENT_TYPE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SETTLEMENT_TYPE
    WHERE SETTLEMENT_TYPE_ID = p_SETTLEMENT_TYPE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SETTLEMENT_TYPE,
                                                                        p_SETTLEMENT_TYPE_ID));

END DEL_SETTLEMENT_TYPE;
---------------------------------------------------------------------
PROCEDURE DEL_STATEMENT_TYPE
	(
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_STATEMENT_TYPE_ID, EC.ED_STATEMENT_TYPE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM STATEMENT_TYPE
    WHERE STATEMENT_TYPE_ID = p_STATEMENT_TYPE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_STATEMENT_TYPE,
                                                                        p_STATEMENT_TYPE_ID));

END DEL_STATEMENT_TYPE;
---------------------------------------------------------------------
PROCEDURE DEL_SUB_STATION
	(
	p_SUB_STATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SUB_STATION_ID, EC.ED_SUB_STATION);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_SUB_STATION
    WHERE SUB_STATION_ID = p_SUB_STATION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SUB_STATION,
                                                                        p_SUB_STATION_ID));

END DEL_SUB_STATION;
---------------------------------------------------------------------
PROCEDURE DEL_SUB_STATION_METER
	(
	p_METER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_METER_ID, EC.ED_SUB_STATION_METER);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_SUB_STATION_METER
    WHERE METER_ID = p_METER_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SUB_STATION_METER,
                                                                        p_METER_ID));

END DEL_SUB_STATION_METER;
---------------------------------------------------------------------
PROCEDURE DEL_SUB_STATION_METER_POINT
	(
	p_METER_POINT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_METER_POINT_ID, EC.ED_SUB_STATION_METER_POINT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_SUB_STATION_METER_POINT
    WHERE METER_POINT_ID = p_METER_POINT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SUB_STATION_METER_POINT,
                                                                        p_METER_POINT_ID));

END DEL_SUB_STATION_METER_POINT;
---------------------------------------------------------------------
PROCEDURE DEL_SUPPLY_RESOURCE
	(
	p_RESOURCE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_RESOURCE_ID, EC.ED_SUPPLY_RESOURCE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SUPPLY_RESOURCE
    WHERE RESOURCE_ID = p_RESOURCE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SUPPLY_RESOURCE,
                                                                        p_RESOURCE_ID));

END DEL_SUPPLY_RESOURCE;
---------------------------------------------------------------------
PROCEDURE DEL_SYSTEM_ACTION
	(
	p_ACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ACTION_ID, EC.ED_SYSTEM_ACTION);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SYSTEM_ACTION
    WHERE ACTION_ID = p_ACTION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SYSTEM_ACTION,
                                                                        p_ACTION_ID));

END DEL_SYSTEM_ACTION;
---------------------------------------------------------------------
PROCEDURE DEL_SYSTEM_ALERT
	(
	p_ALERT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_ALERT_ID, EC.ED_SYSTEM_ALERT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SYSTEM_ALERT
    WHERE ALERT_ID = p_ALERT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SYSTEM_ALERT,
                                                                        p_ALERT_ID));

END DEL_SYSTEM_ALERT;
---------------------------------------------------------------------
PROCEDURE DEL_SYSTEM_EVENT
	(
	p_EVENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_EVENT_ID, EC.ED_SYSTEM_EVENT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SYSTEM_EVENT
    WHERE EVENT_ID = p_EVENT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SYSTEM_EVENT,
                                                                        p_EVENT_ID));

END DEL_SYSTEM_EVENT;
---------------------------------------------------------------------
PROCEDURE DEL_SYSTEM_LOAD
	(
	p_SYSTEM_LOAD_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_SYSTEM_LOAD_ID, EC.ED_SYSTEM_LOAD);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SYSTEM_LOAD
    WHERE SYSTEM_LOAD_ID = p_SYSTEM_LOAD_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SYSTEM_LOAD,
                                                                        p_SYSTEM_LOAD_ID));

END DEL_SYSTEM_LOAD;
---------------------------------------------------------------------
PROCEDURE DEL_SYSTEM_REALM
	(
	p_REALM_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_REALM_ID, EC.ED_SYSTEM_REALM);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SYSTEM_REALM
    WHERE REALM_ID = p_REALM_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SYSTEM_REALM,
                                                                        p_REALM_ID));

END DEL_SYSTEM_REALM;
---------------------------------------------------------------------
PROCEDURE DEL_SYSTEM_TABLE
	(
	p_TABLE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_TABLE_ID, EC.ED_SYSTEM_TABLE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM SYSTEM_TABLE
    WHERE TABLE_ID = p_TABLE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_SYSTEM_TABLE,
                                                                        p_TABLE_ID));

END DEL_SYSTEM_TABLE;
---------------------------------------------------------------------
PROCEDURE DEL_TEMPLATE
	(
	p_TEMPLATE_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_TEMPLATE_ID, EC.ED_TEMPLATE);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TEMPLATE
    WHERE TEMPLATE_ID = p_TEMPLATE_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_TEMPLATE,
                                                                        p_TEMPLATE_ID));

END DEL_TEMPLATE;
---------------------------------------------------------------------
PROCEDURE DEL_TP
	(
	p_TP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_TP_ID, EC.ED_TP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TRANSMISSION_PROVIDER
    WHERE TP_ID = p_TP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_TP,
                                                                        p_TP_ID));

END DEL_TP;
---------------------------------------------------------------------
PROCEDURE DEL_TRANSACTION
	(
	p_TRANSACTION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_TRANSACTION_ID, EC.ED_TRANSACTION);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM INTERCHANGE_TRANSACTION
    WHERE TRANSACTION_ID = p_TRANSACTION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_TRANSACTION,
                                                                        p_TRANSACTION_ID));

END DEL_TRANSACTION;
---------------------------------------------------------------------
PROCEDURE DEL_TRANSACTION_TRAIT_GROUP
	(
	p_TRAIT_GROUP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_TRAIT_GROUP_ID, EC.ED_TRANSACTION_TRAIT_GROUP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TRANSACTION_TRAIT_GROUP
    WHERE TRAIT_GROUP_ID = p_TRAIT_GROUP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_TRANSACTION_TRAIT_GROUP,
                                                                        p_TRAIT_GROUP_ID));

END DEL_TRANSACTION_TRAIT_GROUP;
---------------------------------------------------------------------
PROCEDURE DEL_TX_FEEDER
	(
	p_FEEDER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_FEEDER_ID, EC.ED_TX_FEEDER);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_FEEDER
    WHERE FEEDER_ID = p_FEEDER_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_TX_FEEDER,
                                                                        p_FEEDER_ID));

END DEL_TX_FEEDER;
---------------------------------------------------------------------
PROCEDURE DEL_TX_FEEDER_SEGMENT
	(
	p_FEEDER_SEGMENT_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_FEEDER_SEGMENT_ID, EC.ED_TX_FEEDER_SEGMENT);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM TX_FEEDER_SEGMENT
    WHERE FEEDER_SEGMENT_ID = p_FEEDER_SEGMENT_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_TX_FEEDER_SEGMENT,
                                                                        p_FEEDER_SEGMENT_ID));

END DEL_TX_FEEDER_SEGMENT;
---------------------------------------------------------------------
PROCEDURE DEL_USAGE_WRF
	(
	p_WRF_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	-- Make sure user has access
	IF NOT CAN_DELETE('Data Setup') THEN
        ERRS.RAISE_NO_DELETE_MODULE('Data Setup');
	END IF;
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM USAGE_WRF
    WHERE WRF_ID = p_WRF_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    
												
             ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
																					NULL,
																					p_WRF_ID));

END DEL_USAGE_WRF;
---------------------------------------------------------------------
PROCEDURE DEL_VPP
	(
	p_VPP_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_VPP_ID, EC.ED_VPP);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM VIRTUAL_POWER_PLANT
    WHERE VPP_ID = p_VPP_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_VPP,
                                                                        p_VPP_ID));

END DEL_VPP;
---------------------------------------------------------------------
PROCEDURE DEL_WEATHER_PARAMETER
	(
	p_PARAMETER_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_PARAMETER_ID, EC.ED_WEATHER_PARAMETER);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM WEATHER_PARAMETER
    WHERE PARAMETER_ID = p_PARAMETER_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_WEATHER_PARAMETER,
                                                                        p_PARAMETER_ID));

END DEL_WEATHER_PARAMETER;
---------------------------------------------------------------------
PROCEDURE DEL_WEATHER_STATION
	(
	p_STATION_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
-- Delete the specified entity
    
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_DELETE_ENT, p_STATION_ID, EC.ED_WEATHER_STATION);
    
    p_STATUS := GA.SUCCESS;
   
    DELETE FROM WEATHER_STATION
    WHERE STATION_ID = p_STATION_ID;
    
EXCEPTION
    WHEN ERRS.e_CHILD_RECORD_FOUND THEN
    

            ERRS.RAISE(MSGCODES.c_ERR_CHILD_TABLE, UT.GET_FK_REF_DETAILS_FROM_ERRM(SQLERRM,
                                                                        EC.ED_WEATHER_STATION,
                                                                        p_STATION_ID));

END DEL_WEATHER_STATION;
---------------------------------------------------------------------
END DE;
/
