CREATE OR REPLACE PACKAGE BODY MM_SEM_REPORTS IS

g_SEM_MKT_PRICE_CAP_E CONSTANT VARCHAR2(32) := 'MARKET_PRICE_CAP_EURO';
g_SEM_MKT_PRICE_CAP_P CONSTANT VARCHAR2(32) := 'MARKET_PRICE_CAP_POUND';
g_SEM_MKT_PRICE_FLOOR_E CONSTANT VARCHAR2(32) := 'MARKET_PRICE_FLOOR_EURO';
g_SEM_MKT_PRICE_FLOOR_P CONSTANT VARCHAR2(32) := 'MARKET_PRICE_FLOOR_POUND';

-- Constants for Alert Types
g_ALERT_TYPE_REPORT VARCHAR2(32) := 'Reports';
g_ALERT_TYPE_NOTIF VARCHAR2(32) := 'Notifications';

-- globals for MPUD5 switch
g_PARTICIPANT_ELEMENT VARCHAR2(32);
g_RESOURCE_ELEMENT VARCHAR2(32);
g_ORGANIZATION_ELEMENT VARCHAR2(32);
g_MKT_SCHED_DETAILS_QUANTITY VARCHAR2(32);

g_TLAF_REPORT_NAME CONSTANT VARCHAR2(64) := 'PUB_A_TransLossAdjustmentFactors';

-- as of 27.nov.2007, I haven't been able to find a field width definition for
-- the report names. The max so far is 44: PUB_D_RollingWindFcstAssumptionsJurisdiction.
-- Since we store this in the system dictionary, let's make life easy and just use that as the width
g_REPORT_NAME SYSTEM_DICTIONARY.VALUE%TYPE;
g_RUN_TYPE SYSTEM_DICTIONARY.VALUE%TYPE;
---------------------------------------------------------------------------------------------------------------------------------------------------------
FUNCTION PACKAGE_NAME RETURN VARCHAR IS
BEGIN
     RETURN 'MM_SEM_REPORTS';
END PACKAGE_NAME;
---------------------------------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.44 $';
END WHAT_VERSION;
------------------------------------------------------------------------------
FUNCTION GET_STATEMENT_TYPE
	(
	p_STATEMENT_TYPE_ID IN NUMBER,
	p_EXTSYS_STATEMENT_TYPE IN VARCHAR2
	) RETURN NUMBER IS
v_IDs NUMBER_COLLECTION;
v_EXTID EXTERNAL_SYSTEM_IDENTIFIER.EXTERNAL_IDENTIFIER%TYPE;
BEGIN

	IF NVL(p_STATEMENT_TYPE_ID,0) = 0 THEN
		-- no statement type specified?
		-- then look it up by external identifier using report's type
		v_IDs := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(p_EXTSYS_STATEMENT_TYPE, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);
		RETURN v_IDs(v_IDs.FIRST);
	ELSE
		-- statement type specified? verify that it is "compatible" with report's type
		v_EXTID := EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_STATEMENT_TYPE, p_STATEMENT_TYPE_ID, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_SETTLEMENT);
		IF v_EXTID LIKE p_EXTSYS_STATEMENT_TYPE||'%' THEN
			RETURN p_STATEMENT_TYPE_ID;
		ELSE
			-- not compatible - so just find an appropriate statement type
			RETURN GET_STATEMENT_TYPE(NULL, p_EXTSYS_STATEMENT_TYPE);
		END IF;
	END IF;
END GET_STATEMENT_TYPE;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MKT_PARTICIPANTS
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
	v_PSE_ID NUMBER(9);
  v_XML_REP    XMLTYPE;

    CURSOR C_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_ORGANIZATION_ELEMENT) "PARTICIPANT_NAME",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/START_DATE'),
                       'DD/MM/YYYY') "START_DATE",
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/END_DATE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/END_DATE'),
                            'DD/MM/YYYY')
               END "END_DATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;


BEGIN
		v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);
    p_LOGGER.EXCHANGE_NAME := 'Import Active Market Participants report';


    FOR v_XML IN c_XML LOOP
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID,
                                           TRUE,
                                           v_XML.PARTICIPANT_NAME);
    END LOOP;


EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Active Market Participants report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_MKT_PARTICIPANTS;
-------------------------------------------------------------------------------------------------------
FUNCTION CREATE_SERVICE_POINT
(
    p_RESOURCE_NAME   IN VARCHAR2,
    p_RESOURCE_TYPE   IN VARCHAR2,
    p_EFFECTIVE_DATE  IN VARCHAR2,
    p_EXPIRATION_DATE IN VARCHAR2,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_REPORT_NAME     IN VARCHAR2 :=NULL
) RETURN NUMBER IS
    v_POD_ID NUMBER(9);

BEGIN

    --Create the Service Point entity; save the external identifier; add an entry into the EXTERNAL_SYSTEM_IDENTIFIER
    p_LOGGER.EXCHANGE_NAME := p_REPORT_NAME || ' report - Create Service Point';
    v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(p_RESOURCE_NAME);

	IF v_POD_ID >0 THEN
    	RO.PUT_ENTITY_ATTRIBUTE(p_ATTRIBUTE_NAME   => 'Resource Type',
                            	p_ENTITY_DOMAIN_ID => EC.ED_SERVICE_POINT,
                            	p_OWNER_ENTITY_ID  => v_POD_ID,
                            	p_ATTRIBUTE_TYPE   => 'String',
                            	p_ATTRIBUTE_VAL    => p_RESOURCE_TYPE,
                            	p_BEGIN_DATE       => p_EFFECTIVE_DATE,
                            	p_END_DATE         => p_EXPIRATION_DATE);

		RETURN v_POD_ID;
	ELSE
		p_LOGGER.LOG_WARN('Service Point Entity Attribute not created for ' || p_RESOURCE_NAME);
	END IF;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating Service Points: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END CREATE_SERVICE_POINT;
--------------------------------------------------------------------------------------------------------
PROCEDURE SET_REPORT_NAME_FROM_XML(p_REPORT_XML IN XMLTYPE) IS
BEGIN
	SELECT EXTRACTVALUE(p_REPORT_XML, 'REPORT/REPORT_HEADER/HEADROW/REPORT_NAME') INTO g_REPORT_NAME FROM DUAL;
END SET_REPORT_NAME_FROM_XML;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TECH_OFFER_STD_UNITS(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) AS
	v_POD_ID            NUMBER(9);
	v_SCHEDULE_DATE     DATE;
    v_STATEMENT_TYPE_ID SEM_TECH_OFFER_STD_UNITS.STATEMENT_TYPE_ID%TYPE;
	v_XML_REP           XMLTYPE;
	v_RECORD_COUNT NUMBER(9) := 0;

	v_DEM_EVENT_ID NUMBER(9);
	v_GEN_EVENT_ID NUMBER(9);

	CURSOR c_XML IS
		SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') + 1 / 24 / 60 / 60 TRADE_DATE,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') JURISDICTION,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/FUEL_TYPE') FUEL_TYPE,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/PRIORITY_DISPATCH_YN') PRIORITY_DISPATCH_YN,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/PUMP_STORAGE_YN') PUMP_STORAGE_YN,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/ENERGY_LIMIT_YN') ENERGY_LIMIT_YN,
			   EXTRACTVALUE(VALUE(T), '//DATAROW/UNDER_TEST_YN') UNDER_TEST_YN,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/FIRM_ACCESS_QUANTITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/FIRM_ACCESS_QUANTITY')
               END FIRM_ACCESS_QUANTITY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/NON_FIRM_ACC_QUANTITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/NON_FIRM_ACC_QUANTITY')
               END NON_FIRM_ACC_QUANTITY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SHORT_TERM_MAXIMISATION_CAP')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SHORT_TERM_MAXIMISATION_CAP')
               END SHORT_TERM_MAXIMISATION_CAP,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_GENERATION')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_GENERATION')
               END MINIMUM_GENERATION,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_GENERATION')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_GENERATION')
               END MAXIMUM_GENERATION,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_ON_TIME')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_ON_TIME')
               END MINIMUM_ON_TIME,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_OFF_TIME')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_OFF_TIME')
               END MINIMUM_OFF_TIME,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_ON_TIME')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_ON_TIME')
               END MAXIMUM_ON_TIME,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/HOT_COOLING_BOUNDARY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/HOT_COOLING_BOUNDARY')
               END HOT_COOLING_BOUNDARY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/WARM_COOLING_BOUNDARY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/WARM_COOLING_BOUNDARY')
               END WARM_COOLING_BOUNDARY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SYNCHRONOUS_START_UP_TIME_HOT')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SYNCHRONOUS_START_UP_TIME_HOT')
               END SYNCHRONOUS_START_UP_TIME_HOT,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SYNCHRONOUS_START_UP_TIME_WARM')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SYNCHRONOUS_START_UP_TIME_WARM')
               END SYNCHRONOUS_START_UP_TIME_WARM,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SYNCHRONOUS_START_UP_TIME_COLD')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SYNCHRONOUS_START_UP_TIME_COLD')
               END SYNCHRONOUS_START_UP_TIME_COLD,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/BLOCK_LOAD_COLD')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/BLOCK_LOAD_COLD')
               END BLOCK_LOAD_COLD,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/BLOCK_LOAD_HOT')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/BLOCK_LOAD_HOT')
               END BLOCK_LOAD_HOT,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/BLOCK_LOAD_WARM')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/BLOCK_LOAD_WARM')
               END BLOCK_LOAD_WARM,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_COLD_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_COLD_1')
               END LOADING_RATE_COLD_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_COLD_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_COLD_2')
               END LOADING_RATE_COLD_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_COLD_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_COLD_3')
               END LOADING_RATE_COLD_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_COLD_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_COLD_1')
               END LOAD_UP_BREAK_POINT_COLD_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_COLD_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_COLD_2')
               END LOAD_UP_BREAK_POINT_COLD_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_HOT_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_HOT_1')
               END LOADING_RATE_HOT_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_HOT_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_HOT_2')
               END LOADING_RATE_HOT_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_HOT_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_HOT_3')
               END LOADING_RATE_HOT_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_HOT_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_HOT_1')
               END LOAD_UP_BREAK_POINT_HOT_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_HOT_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_HOT_2')
               END LOAD_UP_BREAK_POINT_HOT_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_WARM_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_WARM_1')
               END LOADING_RATE_WARM_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_WARM_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_WARM_2')
               END LOADING_RATE_WARM_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_WARM_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOADING_RATE_WARM_3')
               END LOADING_RATE_WARM_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_WARM_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_WARM_1')
               END LOAD_UP_BREAK_POINT_WARM_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_WARM_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_UP_BREAK_POINT_WARM_2')
               END LOAD_UP_BREAK_POINT_WARM_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_COLD_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_COLD_1')
               END SOAK_TIME_COLD_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_COLD_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_COLD_2')
               END SOAK_TIME_COLD_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_COLD_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_COLD_1')
               END SOAK_TIME_TRIGGER_POINT_COLD_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_COLD_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_COLD_2')
               END SOAK_TIME_TRIGGER_POINT_COLD_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_HOT_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_HOT_1')
               END SOAK_TIME_HOT_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_HOT_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_HOT_2')
               END SOAK_TIME_HOT_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_HOT_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_HOT_1')
               END SOAK_TIME_TRIGGER_POINT_HOT_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_HOT_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_HOT_2')
               END SOAK_TIME_TRIGGER_POINT_HOT_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_WARM_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_WARM_1')
               END SOAK_TIME_WARM_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_WARM_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_WARM_2')
               END SOAK_TIME_WARM_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_WARM_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_WARM_1')
               END SOAK_TIME_TRIGGER_POINT_WARM_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_WARM_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SOAK_TIME_TRIGGER_POINT_WARM_2')
               END SOAK_TIME_TRIGGER_POINT_WARM_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/END_POINT_OF_START_UP_PERIOD')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/END_POINT_OF_START_UP_PERIOD')
               END END_POINT_OF_START_UP_PERIOD,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_1')
               END RAMP_UP_RATE_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_2')
               END RAMP_UP_RATE_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_3')
               END RAMP_UP_RATE_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_4')
               END RAMP_UP_RATE_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_5')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE_5')
               END RAMP_UP_RATE_5,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_1')
               END RAMP_UP_BREAK_POINT_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_2')
               END RAMP_UP_BREAK_POINT_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_3')
               END RAMP_UP_BREAK_POINT_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_BREAK_POINT_4')
               END RAMP_UP_BREAK_POINT_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_1')
               END DWELL_TIME_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_2')
               END DWELL_TIME_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_3')
               END DWELL_TIME_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_POINT_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_POINT_1')
               END DWELL_TIME_TRIGGER_POINT_1,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_PT_1'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_PT_1')
               END DWELL_TIME_TRIGGER_PT_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_POINT_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_POINT_2')
               END DWELL_TIME_TRIGGER_POINT_2,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_PT_2'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_PT_2')
               END DWELL_TIME_TRIGGER_PT_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_POINT_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_POINT_3')
               END DWELL_TIME_TRIGGER_POINT_3,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_PT_3'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_TRIGGER_PT_3')
               END DWELL_TIME_TRIGGER_PT_3,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_1'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_1')
               END DWELL_TIME_DOWN_1,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_2'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_2')
               END DWELL_TIME_DOWN_2,
                CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_3'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_3')
               END DWELL_TIME_DOWN_3,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_TRIGGER_PT_1'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_TRIGGER_PT_1')
               END DWELL_TIME_DOWN_TRIGGER_PT_1,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_TRIGGER_PT_2'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_TRIGGER_PT_2')
               END DWELL_TIME_DOWN_TRIGGER_PT_2,
               CASE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_TRIGGER_PT_3'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DWELL_TIME_DOWN_TRIGGER_PT_3')
               END DWELL_TIME_DOWN_TRIGGER_PT_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_1')
               END RAMP_DOWN_RATE_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_2')
               END RAMP_DOWN_RATE_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_3')
               END RAMP_DOWN_RATE_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_4')
               END RAMP_DOWN_RATE_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_5')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE_5')
               END RAMP_DOWN_RATE_5,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_1')
               END RAMP_DOWN_BREAK_POINT_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_2')
               END RAMP_DOWN_BREAK_POINT_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_3')
               END RAMP_DOWN_BREAK_POINT_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_BREAK_POINT_4')
               END RAMP_DOWN_BREAK_POINT_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DELOADING_RATE_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DELOADING_RATE_1')
               END DELOADING_RATE_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DELOADING_RATE_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DELOADING_RATE_2')
               END DELOADING_RATE_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DELOAD_BREAK_POINT')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DELOAD_BREAK_POINT')
               END DELOAD_BREAK_POINT,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_STORAGE_CAPACITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_STORAGE_CAPACITY')
               END MAXIMUM_STORAGE_CAPACITY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_STORAGE_CAPACITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_STORAGE_CAPACITY')
               END MINIMUM_STORAGE_CAPACITY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PUMPING_LOAD_CAP')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PUMPING_LOAD_CAP')
               END PUMPING_LOAD_CAP,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/TARGET_RESERVOIR_LEVEL_PERCENT')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/TARGET_RESERVOIR_LEVEL_PERCENT')
               END TARGET_RESERVOIR_LEVEL_PERCENT,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/ENERGY_LIMIT_MWH')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/ENERGY_LIMIT_MWH')
               END ENERGY_LIMIT_MWH,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/ENERGY_LIMIT_FACTOR')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/ENERGY_LIMIT_FACTOR')
               END ENERGY_LIMIT_FACTOR,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/FIXED_UNIT_LOAD')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/FIXED_UNIT_LOAD')
               END FIXED_UNIT_LOAD,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/UNIT_LOAD_SCALAR')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/UNIT_LOAD_SCALAR')
               END UNIT_LOAD_SCALAR,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_RAMP_UP_RATE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_RAMP_UP_RATE')
               END MAXIMUM_RAMP_UP_RATE,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_RAMP_DOWN_RATE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_RAMP_DOWN_RATE')
               END MAXIMUM_RAMP_DOWN_RATE,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_DOWN_TIME')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_DOWN_TIME')
               END MINIMUM_DOWN_TIME,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_DOWN_TIME')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_DOWN_TIME')
               END MAXIMUM_DOWN_TIME
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    IF g_REPORT_NAME = 'PUB_D_TODStandardUnits' THEN
        v_DEM_EVENT_ID := NULL;
        v_GEN_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
    ELSE
        v_DEM_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
        v_GEN_EVENT_ID := NULL;
    END IF;

    IF g_RUN_TYPE IS NULL THEN
        v_STATEMENT_TYPE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
    ELSE
        v_STATEMENT_TYPE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(g_RUN_TYPE, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
    END IF;

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := v_XML.TRADE_DATE;

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        MERGE INTO SEM_TECH_OFFER_STD_UNITS S
        USING (SELECT v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_STATEMENT_TYPE_ID STATEMENT_TYPE_ID,
                      v_XML.RESOURCE_TYPE RESOURCE_TYPE,
                      v_XML.JURISDICTION JURISDICTION,
                      v_XML.FUEL_TYPE FUEL_TYPE,
                      v_XML.PRIORITY_DISPATCH_YN PRIORITY_DISPATCH_YN,
                      v_XML.PUMP_STORAGE_YN PUMP_STORAGE_YN,
                      v_XML.ENERGY_LIMIT_YN ENERGY_LIMIT_YN,
                      v_XML.UNDER_TEST_YN UNDER_TEST_YN,
                      v_XML.FIRM_ACCESS_QUANTITY FIRM_ACCESS_QUANTITY,
                      v_XML.NON_FIRM_ACC_QUANTITY NON_FIRM_ACC_QUANTITY,
                      v_XML.SHORT_TERM_MAXIMISATION_CAP SHORT_TERM_MAXIMISATION_CAP,
                      v_XML.MINIMUM_GENERATION MINIMUM_GENERATION,
                      v_XML.MAXIMUM_GENERATION MAXIMUM_GENERATION,
                      v_XML.MINIMUM_ON_TIME MINIMUM_ON_TIME,
                      v_XML.MINIMUM_OFF_TIME MINIMUM_OFF_TIME,
                      v_XML.MAXIMUM_ON_TIME MAXIMUM_ON_TIME,
                      v_XML.HOT_COOLING_BOUNDARY HOT_COOLING_BOUNDARY,
                      v_XML.WARM_COOLING_BOUNDARY WARM_COOLING_BOUNDARY,
                      v_XML.SYNCHRONOUS_START_UP_TIME_HOT SYNCHRONOUS_START_UP_TIME_HOT,
                      v_XML.SYNCHRONOUS_START_UP_TIME_WARM SYNCHRONOUS_START_UP_TIME_WARM,
                      v_XML.SYNCHRONOUS_START_UP_TIME_COLD SYNCHRONOUS_START_UP_TIME_COLD,
                      v_XML.BLOCK_LOAD_COLD BLOCK_LOAD_COLD,
                      v_XML.BLOCK_LOAD_HOT BLOCK_LOAD_HOT,
                      v_XML.BLOCK_LOAD_WARM BLOCK_LOAD_WARM,
                      v_XML.LOADING_RATE_COLD_1 LOADING_RATE_COLD_1,
                      v_XML.LOADING_RATE_COLD_2 LOADING_RATE_COLD_2,
                      v_XML.LOADING_RATE_COLD_3 LOADING_RATE_COLD_3,
                      v_XML.LOAD_UP_BREAK_POINT_COLD_1 LOAD_UP_BREAK_POINT_COLD_1,
                      v_XML.LOAD_UP_BREAK_POINT_COLD_2 LOAD_UP_BREAK_POINT_COLD_2,
                      v_XML.LOADING_RATE_HOT_1 LOADING_RATE_HOT_1,
                      v_XML.LOADING_RATE_HOT_2 LOADING_RATE_HOT_2,
                      v_XML.LOADING_RATE_HOT_3 LOADING_RATE_HOT_3,
                      v_XML.LOAD_UP_BREAK_POINT_HOT_1 LOAD_UP_BREAK_POINT_HOT_1,
                      v_XML.LOAD_UP_BREAK_POINT_HOT_2 LOAD_UP_BREAK_POINT_HOT_2,
                      v_XML.LOADING_RATE_WARM_1 LOADING_RATE_WARM_1,
                      v_XML.LOADING_RATE_WARM_2 LOADING_RATE_WARM_2,
                      v_XML.LOADING_RATE_WARM_3 LOADING_RATE_WARM_3,
                      v_XML.LOAD_UP_BREAK_POINT_WARM_1 LOAD_UP_BREAK_POINT_WARM_1,
                      v_XML.LOAD_UP_BREAK_POINT_WARM_2 LOAD_UP_BREAK_POINT_WARM_2,
                      v_XML.SOAK_TIME_COLD_1 SOAK_TIME_COLD_1,
                      v_XML.SOAK_TIME_COLD_2 SOAK_TIME_COLD_2,
                      v_XML.SOAK_TIME_TRIGGER_POINT_COLD_1 SOAK_TIME_TRIGGER_POINT_COLD_1,
                      v_XML.SOAK_TIME_TRIGGER_POINT_COLD_2 SOAK_TIME_TRIGGER_POINT_COLD_2,
                      v_XML.SOAK_TIME_HOT_1 SOAK_TIME_HOT_1,
                      v_XML.SOAK_TIME_HOT_2 SOAK_TIME_HOT_2,
                      v_XML.SOAK_TIME_TRIGGER_POINT_HOT_1 SOAK_TIME_TRIGGER_POINT_HOT_1,
                      v_XML.SOAK_TIME_TRIGGER_POINT_HOT_2 SOAK_TIME_TRIGGER_POINT_HOT_2,
                      v_XML.SOAK_TIME_WARM_1 SOAK_TIME_WARM_1,
                      v_XML.SOAK_TIME_WARM_2 SOAK_TIME_WARM_2,
                      v_XML.SOAK_TIME_TRIGGER_POINT_WARM_1 SOAK_TIME_TRIGGER_POINT_WARM_1,
                      v_XML.SOAK_TIME_TRIGGER_POINT_WARM_2 SOAK_TIME_TRIGGER_POINT_WARM_2,
                      v_XML.END_POINT_OF_START_UP_PERIOD END_POINT_OF_START_UP_PERIOD,
                      v_XML.RAMP_UP_RATE_1 RAMP_UP_RATE_1,
                      v_XML.RAMP_UP_RATE_2 RAMP_UP_RATE_2,
                      v_XML.RAMP_UP_RATE_3 RAMP_UP_RATE_3,
                      v_XML.RAMP_UP_RATE_4 RAMP_UP_RATE_4,
                      v_XML.RAMP_UP_RATE_5 RAMP_UP_RATE_5,
                      v_XML.RAMP_UP_BREAK_POINT_1 RAMP_UP_BREAK_POINT_1,
                      v_XML.RAMP_UP_BREAK_POINT_2 RAMP_UP_BREAK_POINT_2,
                      v_XML.RAMP_UP_BREAK_POINT_3 RAMP_UP_BREAK_POINT_3,
                      v_XML.RAMP_UP_BREAK_POINT_4 RAMP_UP_BREAK_POINT_4,
                      v_XML.DWELL_TIME_1 DWELL_TIME_1,
                      v_XML.DWELL_TIME_2 DWELL_TIME_2,
                      v_XML.DWELL_TIME_3 DWELL_TIME_3,
                      CASE WHEN v_XML.DWELL_TIME_TRIGGER_POINT_1 IS NULL THEN v_XML.DWELL_TIME_TRIGGER_PT_1 ELSE v_XML.DWELL_TIME_TRIGGER_POINT_1 END  DWELL_TIME_TRIGGER_POINT_1,
                      CASE WHEN v_XML.DWELL_TIME_TRIGGER_POINT_2 IS NULL THEN v_XML.DWELL_TIME_TRIGGER_PT_2 ELSE v_XML.DWELL_TIME_TRIGGER_POINT_2 END  DWELL_TIME_TRIGGER_POINT_2,
                      CASE WHEN v_XML.DWELL_TIME_TRIGGER_POINT_3 IS NULL THEN v_XML.DWELL_TIME_TRIGGER_PT_3 ELSE v_XML.DWELL_TIME_TRIGGER_POINT_3 END  DWELL_TIME_TRIGGER_POINT_3,
                      v_XML.DWELL_TIME_DOWN_1 DWELL_TIME_DOWN_1,
                      v_XML.DWELL_TIME_DOWN_2 DWELL_TIME_DOWN_2,
                      v_XML.DWELL_TIME_DOWN_3 DWELL_TIME_DOWN_3,
                      v_XML.DWELL_TIME_DOWN_TRIGGER_PT_1 DWELL_TIME_DOWN_TRIGGER_PT_1,
                      v_XML.DWELL_TIME_DOWN_TRIGGER_PT_2 DWELL_TIME_DOWN_TRIGGER_PT_2,
                      v_XML.DWELL_TIME_DOWN_TRIGGER_PT_3 DWELL_TIME_DOWN_TRIGGER_PT_3,
                      v_XML.RAMP_DOWN_RATE_1 RAMP_DOWN_RATE_1,
                      v_XML.RAMP_DOWN_RATE_2 RAMP_DOWN_RATE_2,
                      v_XML.RAMP_DOWN_RATE_3 RAMP_DOWN_RATE_3,
                      v_XML.RAMP_DOWN_RATE_4 RAMP_DOWN_RATE_4,
                      v_XML.RAMP_DOWN_RATE_5 RAMP_DOWN_RATE_5,
                      v_XML.RAMP_DOWN_BREAK_POINT_1 RAMP_DOWN_BREAK_POINT_1,
                      v_XML.RAMP_DOWN_BREAK_POINT_2 RAMP_DOWN_BREAK_POINT_2,
                      v_XML.RAMP_DOWN_BREAK_POINT_3 RAMP_DOWN_BREAK_POINT_3,
                      v_XML.RAMP_DOWN_BREAK_POINT_4 RAMP_DOWN_BREAK_POINT_4,
                      v_XML.DELOADING_RATE_1 DELOADING_RATE_1,
                      v_XML.DELOADING_RATE_2 DELOADING_RATE_2,
                      v_XML.DELOAD_BREAK_POINT DELOAD_BREAK_POINT,
                      v_XML.MAXIMUM_STORAGE_CAPACITY MAXIMUM_STORAGE_CAPACITY,
                      v_XML.MINIMUM_STORAGE_CAPACITY MINIMUM_STORAGE_CAPACITY,
                      v_XML.PUMPING_LOAD_CAP PUMPING_LOAD_CAP,
                      v_XML.TARGET_RESERVOIR_LEVEL_PERCENT TARGET_RESERVOIR_LEVEL_PERCENT,
                      v_XML.ENERGY_LIMIT_MWH ENERGY_LIMIT_MWH,
                      v_XML.ENERGY_LIMIT_FACTOR ENERGY_LIMIT_FACTOR,
                      v_XML.FIXED_UNIT_LOAD FIXED_UNIT_LOAD,
                      v_XML.UNIT_LOAD_SCALAR UNIT_LOAD_SCALAR,
                      v_XML.MAXIMUM_RAMP_UP_RATE MAXIMUM_RAMP_UP_RATE,
                      v_XML.MAXIMUM_RAMP_DOWN_RATE MAXIMUM_RAMP_DOWN_RATE,
                      v_XML.MINIMUM_DOWN_TIME MINIMUM_DOWN_TIME,
                      v_XML.MAXIMUM_DOWN_TIME MAXIMUM_DOWN_TIME,
                      v_GEN_EVENT_ID GEN_EVENT_ID,
                      v_DEM_EVENT_ID DEM_EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.STATEMENT_TYPE_ID = S.STATEMENT_TYPE_ID)
        WHEN MATCHED THEN
            UPDATE
            SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
                S.JURISDICTION = v_XML.JURISDICTION,
                S.FUEL_TYPE = v_XML.FUEL_TYPE,
                S.PRIORITY_DISPATCH_YN = v_XML.PRIORITY_DISPATCH_YN,
                S.PUMP_STORAGE_YN = v_XML.PUMP_STORAGE_YN,
                S.ENERGY_LIMIT_YN = v_XML.ENERGY_LIMIT_YN,
                S.UNDER_TEST_YN = v_XML.UNDER_TEST_YN,
                S.FIRM_ACCESS_QUANTITY = v_XML.FIRM_ACCESS_QUANTITY,
                S.NON_FIRM_ACC_QUANTITY = v_XML.NON_FIRM_ACC_QUANTITY,
                S.SHORT_TERM_MAXIMISATION_CAP = v_XML.SHORT_TERM_MAXIMISATION_CAP,
                S.MINIMUM_GENERATION = v_XML.MINIMUM_GENERATION,
                S.MAXIMUM_GENERATION = v_XML.MAXIMUM_GENERATION,
                S.MINIMUM_ON_TIME = v_XML.MINIMUM_ON_TIME,
                S.MINIMUM_OFF_TIME = v_XML.MINIMUM_OFF_TIME,
                S.MAXIMUM_ON_TIME = v_XML.MAXIMUM_ON_TIME,
                S.HOT_COOLING_BOUNDARY = v_XML.HOT_COOLING_BOUNDARY,
                S.WARM_COOLING_BOUNDARY = v_XML.WARM_COOLING_BOUNDARY,
                S.SYNCHRONOUS_START_UP_TIME_HOT = v_XML.SYNCHRONOUS_START_UP_TIME_HOT,
                S.SYNCHRONOUS_START_UP_TIME_WARM = v_XML.SYNCHRONOUS_START_UP_TIME_WARM,
                S.SYNCHRONOUS_START_UP_TIME_COLD = v_XML.SYNCHRONOUS_START_UP_TIME_COLD,
                S.BLOCK_LOAD_COLD = v_XML.BLOCK_LOAD_COLD,
                S.BLOCK_LOAD_HOT = v_XML.BLOCK_LOAD_HOT,
                S.BLOCK_LOAD_WARM = v_XML.BLOCK_LOAD_WARM,
                S.LOADING_RATE_COLD_1 = v_XML.LOADING_RATE_COLD_1,
                S.LOADING_RATE_COLD_2 = v_XML.LOADING_RATE_COLD_2,
                S.LOADING_RATE_COLD_3 = v_XML.LOADING_RATE_COLD_3,
                S.LOAD_UP_BREAK_POINT_COLD_1 = v_XML.LOAD_UP_BREAK_POINT_COLD_1,
                S.LOAD_UP_BREAK_POINT_COLD_2 = v_XML.LOAD_UP_BREAK_POINT_COLD_2,
                S.LOADING_RATE_HOT_1 = v_XML.LOADING_RATE_HOT_1,
                S.LOADING_RATE_HOT_2 = v_XML.LOADING_RATE_HOT_2,
                S.LOADING_RATE_HOT_3 = v_XML.LOADING_RATE_HOT_3,
                S.LOAD_UP_BREAK_POINT_HOT_1 = v_XML.LOAD_UP_BREAK_POINT_HOT_1,
                S.LOAD_UP_BREAK_POINT_HOT_2 = v_XML.LOAD_UP_BREAK_POINT_HOT_2,
                S.LOADING_RATE_WARM_1 = v_XML.LOADING_RATE_WARM_1,
                S.LOADING_RATE_WARM_2 = v_XML.LOADING_RATE_WARM_2,
                S.LOADING_RATE_WARM_3 = v_XML.LOADING_RATE_WARM_3,
                S.LOAD_UP_BREAK_POINT_WARM_1 = v_XML.LOAD_UP_BREAK_POINT_WARM_1,
                S.LOAD_UP_BREAK_POINT_WARM_2 = v_XML.LOAD_UP_BREAK_POINT_WARM_2,
                S.SOAK_TIME_COLD_1 = v_XML.SOAK_TIME_COLD_1,
                S.SOAK_TIME_COLD_2 = v_XML.SOAK_TIME_COLD_2,
                S.SOAK_TIME_TRIGGER_POINT_COLD_1 = v_XML.SOAK_TIME_TRIGGER_POINT_COLD_1,
                S.SOAK_TIME_TRIGGER_POINT_COLD_2 = v_XML.SOAK_TIME_TRIGGER_POINT_COLD_2,
                S.SOAK_TIME_HOT_1 = v_XML.SOAK_TIME_HOT_1,
                S.SOAK_TIME_HOT_2 = v_XML.SOAK_TIME_HOT_2,
                S.SOAK_TIME_TRIGGER_POINT_HOT_1 = v_XML.SOAK_TIME_TRIGGER_POINT_HOT_1,
                S.SOAK_TIME_TRIGGER_POINT_HOT_2 = v_XML.SOAK_TIME_TRIGGER_POINT_HOT_2,
                S.SOAK_TIME_WARM_1 = v_XML.SOAK_TIME_WARM_1,
                S.SOAK_TIME_WARM_2 = v_XML.SOAK_TIME_WARM_2,
                S.SOAK_TIME_TRIGGER_POINT_WARM_1 = v_XML.SOAK_TIME_TRIGGER_POINT_WARM_1,
                S.SOAK_TIME_TRIGGER_POINT_WARM_2 = v_XML.SOAK_TIME_TRIGGER_POINT_WARM_2,
                S.END_POINT_OF_START_UP_PERIOD = v_XML.END_POINT_OF_START_UP_PERIOD,
                S.RAMP_UP_RATE_1 = v_XML.RAMP_UP_RATE_1,
                S.RAMP_UP_RATE_2 = v_XML.RAMP_UP_RATE_2,
                S.RAMP_UP_RATE_3 = v_XML.RAMP_UP_RATE_3,
                S.RAMP_UP_RATE_4 = v_XML.RAMP_UP_RATE_4,
                S.RAMP_UP_RATE_5 = v_XML.RAMP_UP_RATE_5,
                S.RAMP_UP_BREAK_POINT_1 = v_XML.RAMP_UP_BREAK_POINT_1,
                S.RAMP_UP_BREAK_POINT_2 = v_XML.RAMP_UP_BREAK_POINT_2,
                S.RAMP_UP_BREAK_POINT_3 = v_XML.RAMP_UP_BREAK_POINT_3,
                S.RAMP_UP_BREAK_POINT_4 = v_XML.RAMP_UP_BREAK_POINT_4,
                S.DWELL_TIME_1 = v_XML.DWELL_TIME_1,
                S.DWELL_TIME_2 = v_XML.DWELL_TIME_2,
                S.DWELL_TIME_3 = v_XML.DWELL_TIME_3,
                S.DWELL_TIME_TRIGGER_POINT_1 = A.DWELL_TIME_TRIGGER_POINT_1,
                S.DWELL_TIME_TRIGGER_POINT_2 = A.DWELL_TIME_TRIGGER_POINT_2,
                S.DWELL_TIME_TRIGGER_POINT_3 = A.DWELL_TIME_TRIGGER_POINT_3,
                S.DWELL_TIME_DOWN_1 = v_XML.DWELL_TIME_DOWN_1,
                S.DWELL_TIME_DOWN_2 = v_XML.DWELL_TIME_DOWN_2,
                S.DWELL_TIME_DOWN_3 = v_XML.DWELL_TIME_DOWN_3,
                S.DWELL_TIME_DOWN_TRIGGER_PT_1 = v_XML.DWELL_TIME_DOWN_TRIGGER_PT_1,
                S.DWELL_TIME_DOWN_TRIGGER_PT_2 = v_XML.DWELL_TIME_DOWN_TRIGGER_PT_2,
                S.DWELL_TIME_DOWN_TRIGGER_PT_3 = v_XML.DWELL_TIME_DOWN_TRIGGER_PT_3,
                S.RAMP_DOWN_RATE_1 = v_XML.RAMP_DOWN_RATE_1,
                S.RAMP_DOWN_RATE_2 = v_XML.RAMP_DOWN_RATE_2,
                S.RAMP_DOWN_RATE_3 = v_XML.RAMP_DOWN_RATE_3,
                S.RAMP_DOWN_RATE_4 = v_XML.RAMP_DOWN_RATE_4,
                S.RAMP_DOWN_RATE_5 = v_XML.RAMP_DOWN_RATE_5,
                S.RAMP_DOWN_BREAK_POINT_1 = v_XML.RAMP_DOWN_BREAK_POINT_1,
                S.RAMP_DOWN_BREAK_POINT_2 = v_XML.RAMP_DOWN_BREAK_POINT_2,
                S.RAMP_DOWN_BREAK_POINT_3 = v_XML.RAMP_DOWN_BREAK_POINT_3,
                S.RAMP_DOWN_BREAK_POINT_4 = v_XML.RAMP_DOWN_BREAK_POINT_4,
                S.DELOADING_RATE_1 = v_XML.DELOADING_RATE_1,
                S.DELOADING_RATE_2 = v_XML.DELOADING_RATE_2,
                S.DELOAD_BREAK_POINT = v_XML.DELOAD_BREAK_POINT,
                S.MAXIMUM_STORAGE_CAPACITY = v_XML.MAXIMUM_STORAGE_CAPACITY,
                S.MINIMUM_STORAGE_CAPACITY = v_XML.MINIMUM_STORAGE_CAPACITY,
                S.PUMPING_LOAD_CAP = v_XML.PUMPING_LOAD_CAP,
                S.TARGET_RESERVOIR_LEVEL_PERCENT = v_XML.TARGET_RESERVOIR_LEVEL_PERCENT,
                S.ENERGY_LIMIT_MWH = v_XML.ENERGY_LIMIT_MWH,
                S.ENERGY_LIMIT_FACTOR = v_XML.ENERGY_LIMIT_FACTOR,
                S.FIXED_UNIT_LOAD = v_XML.FIXED_UNIT_LOAD,
                S.UNIT_LOAD_SCALAR = v_XML.UNIT_LOAD_SCALAR,
                S.MAXIMUM_RAMP_UP_RATE = v_XML.MAXIMUM_RAMP_UP_RATE,
                S.MAXIMUM_RAMP_DOWN_RATE = v_XML.MAXIMUM_RAMP_DOWN_RATE,
                S.MINIMUM_DOWN_TIME = v_XML.MINIMUM_DOWN_TIME,
                S.MAXIMUM_DOWN_TIME = v_XML.MAXIMUM_DOWN_TIME,
                S.GEN_EVENT_ID = v_GEN_EVENT_ID,
                S.DEM_EVENT_ID = v_DEM_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (POD_ID,
                 SCHEDULE_DATE,
                 STATEMENT_TYPE_ID,
                 RESOURCE_TYPE,
                 JURISDICTION,
                 FUEL_TYPE,
                 PRIORITY_DISPATCH_YN,
                 PUMP_STORAGE_YN,
                 ENERGY_LIMIT_YN,
                 UNDER_TEST_YN,
                 FIRM_ACCESS_QUANTITY,
                 NON_FIRM_ACC_QUANTITY,
                 SHORT_TERM_MAXIMISATION_CAP,
                 MINIMUM_GENERATION,
                 MAXIMUM_GENERATION,
                 MINIMUM_ON_TIME,
                 MINIMUM_OFF_TIME,
                 MAXIMUM_ON_TIME,
                 HOT_COOLING_BOUNDARY,
                 WARM_COOLING_BOUNDARY,
                 SYNCHRONOUS_START_UP_TIME_HOT,
                 SYNCHRONOUS_START_UP_TIME_WARM,
                 SYNCHRONOUS_START_UP_TIME_COLD,
                 BLOCK_LOAD_COLD,
                 BLOCK_LOAD_HOT,
                 BLOCK_LOAD_WARM,
                 LOADING_RATE_COLD_1,
                 LOADING_RATE_COLD_2,
                 LOADING_RATE_COLD_3,
                 LOAD_UP_BREAK_POINT_COLD_1,
                 LOAD_UP_BREAK_POINT_COLD_2,
                 LOADING_RATE_HOT_1,
                 LOADING_RATE_HOT_2,
                 LOADING_RATE_HOT_3,
                 LOAD_UP_BREAK_POINT_HOT_1,
                 LOAD_UP_BREAK_POINT_HOT_2,
                 LOADING_RATE_WARM_1,
                 LOADING_RATE_WARM_2,
                 LOADING_RATE_WARM_3,
                 LOAD_UP_BREAK_POINT_WARM_1,
                 LOAD_UP_BREAK_POINT_WARM_2,
                 SOAK_TIME_COLD_1,
                 SOAK_TIME_COLD_2,
                 SOAK_TIME_TRIGGER_POINT_COLD_1,
                 SOAK_TIME_TRIGGER_POINT_COLD_2,
                 SOAK_TIME_HOT_1,
                 SOAK_TIME_HOT_2,
                 SOAK_TIME_TRIGGER_POINT_HOT_1,
                 SOAK_TIME_TRIGGER_POINT_HOT_2,
                 SOAK_TIME_WARM_1,
                 SOAK_TIME_WARM_2,
                 SOAK_TIME_TRIGGER_POINT_WARM_1,
                 SOAK_TIME_TRIGGER_POINT_WARM_2,
                 END_POINT_OF_START_UP_PERIOD,
                 RAMP_UP_RATE_1,
                 RAMP_UP_RATE_2,
                 RAMP_UP_RATE_3,
                 RAMP_UP_RATE_4,
                 RAMP_UP_RATE_5,
                 RAMP_UP_BREAK_POINT_1,
                 RAMP_UP_BREAK_POINT_2,
                 RAMP_UP_BREAK_POINT_3,
                 RAMP_UP_BREAK_POINT_4,
                 DWELL_TIME_1,
                 DWELL_TIME_2,
                 DWELL_TIME_3,
                 DWELL_TIME_TRIGGER_POINT_1,
                 DWELL_TIME_TRIGGER_POINT_2,
                 DWELL_TIME_TRIGGER_POINT_3,
                 DWELL_TIME_DOWN_1,
                 DWELL_TIME_DOWN_2,
                 DWELL_TIME_DOWN_3,
                 DWELL_TIME_DOWN_TRIGGER_PT_1,
                 DWELL_TIME_DOWN_TRIGGER_PT_2,
                 DWELL_TIME_DOWN_TRIGGER_PT_3,
                 RAMP_DOWN_RATE_1,
                 RAMP_DOWN_RATE_2,
                 RAMP_DOWN_RATE_3,
                 RAMP_DOWN_RATE_4,
                 RAMP_DOWN_RATE_5,
                 RAMP_DOWN_BREAK_POINT_1,
                 RAMP_DOWN_BREAK_POINT_2,
                 RAMP_DOWN_BREAK_POINT_3,
                 RAMP_DOWN_BREAK_POINT_4,
                 DELOADING_RATE_1,
                 DELOADING_RATE_2,
                 DELOAD_BREAK_POINT,
                 MAXIMUM_STORAGE_CAPACITY,
                 MINIMUM_STORAGE_CAPACITY,
                 PUMPING_LOAD_CAP,
                 TARGET_RESERVOIR_LEVEL_PERCENT,
                 ENERGY_LIMIT_MWH,
                 ENERGY_LIMIT_FACTOR,
                 FIXED_UNIT_LOAD,
                 UNIT_LOAD_SCALAR,
                 MAXIMUM_RAMP_UP_RATE,
                 MAXIMUM_RAMP_DOWN_RATE,
                 MINIMUM_DOWN_TIME,
                 MAXIMUM_DOWN_TIME,
                 GEN_EVENT_ID,
                 DEM_EVENT_ID)
            VALUES
                (v_POD_ID,
                 v_SCHEDULE_DATE,
                 v_STATEMENT_TYPE_ID,
                 v_XML.RESOURCE_TYPE,
                 v_XML.JURISDICTION,
                 v_XML.FUEL_TYPE,
                 v_XML.PRIORITY_DISPATCH_YN,
                 v_XML.PUMP_STORAGE_YN,
                 v_XML.ENERGY_LIMIT_YN,
                 v_XML.UNDER_TEST_YN,
                 v_XML.FIRM_ACCESS_QUANTITY,
                 v_XML.NON_FIRM_ACC_QUANTITY,
                 v_XML.SHORT_TERM_MAXIMISATION_CAP,
                 v_XML.MINIMUM_GENERATION,
                 v_XML.MAXIMUM_GENERATION,
                 v_XML.MINIMUM_ON_TIME,
                 v_XML.MINIMUM_OFF_TIME,
                 v_XML.MAXIMUM_ON_TIME,
                 v_XML.HOT_COOLING_BOUNDARY,
                 v_XML.WARM_COOLING_BOUNDARY,
                 v_XML.SYNCHRONOUS_START_UP_TIME_HOT,
                 v_XML.SYNCHRONOUS_START_UP_TIME_WARM,
                 v_XML.SYNCHRONOUS_START_UP_TIME_COLD,
                 v_XML.BLOCK_LOAD_COLD,
                 v_XML.BLOCK_LOAD_HOT,
                 v_XML.BLOCK_LOAD_WARM,
                 v_XML.LOADING_RATE_COLD_1,
                 v_XML.LOADING_RATE_COLD_2,
                 v_XML.LOADING_RATE_COLD_3,
                 v_XML.LOAD_UP_BREAK_POINT_COLD_1,
                 v_XML.LOAD_UP_BREAK_POINT_COLD_2,
                 v_XML.LOADING_RATE_HOT_1,
                 v_XML.LOADING_RATE_HOT_2,
                 v_XML.LOADING_RATE_HOT_3,
                 v_XML.LOAD_UP_BREAK_POINT_HOT_1,
                 v_XML.LOAD_UP_BREAK_POINT_HOT_2,
                 v_XML.LOADING_RATE_WARM_1,
                 v_XML.LOADING_RATE_WARM_2,
                 v_XML.LOADING_RATE_WARM_3,
                 v_XML.LOAD_UP_BREAK_POINT_WARM_1,
                 v_XML.LOAD_UP_BREAK_POINT_WARM_2,
                 v_XML.SOAK_TIME_COLD_1,
                 v_XML.SOAK_TIME_COLD_2,
                 v_XML.SOAK_TIME_TRIGGER_POINT_COLD_1,
                 v_XML.SOAK_TIME_TRIGGER_POINT_COLD_2,
                 v_XML.SOAK_TIME_HOT_1,
                 v_XML.SOAK_TIME_HOT_2,
                 v_XML.SOAK_TIME_TRIGGER_POINT_HOT_1,
                 v_XML.SOAK_TIME_TRIGGER_POINT_HOT_2,
                 v_XML.SOAK_TIME_WARM_1,
                 v_XML.SOAK_TIME_WARM_2,
                 v_XML.SOAK_TIME_TRIGGER_POINT_WARM_1,
                 v_XML.SOAK_TIME_TRIGGER_POINT_WARM_2,
                 v_XML.END_POINT_OF_START_UP_PERIOD,
                 v_XML.RAMP_UP_RATE_1,
                 v_XML.RAMP_UP_RATE_2,
                 v_XML.RAMP_UP_RATE_3,
                 v_XML.RAMP_UP_RATE_4,
                 v_XML.RAMP_UP_RATE_5,
                 v_XML.RAMP_UP_BREAK_POINT_1,
                 v_XML.RAMP_UP_BREAK_POINT_2,
                 v_XML.RAMP_UP_BREAK_POINT_3,
                 v_XML.RAMP_UP_BREAK_POINT_4,
                 v_XML.DWELL_TIME_1,
                 v_XML.DWELL_TIME_2,
                 v_XML.DWELL_TIME_3,
                 A.DWELL_TIME_TRIGGER_POINT_1,
                 A.DWELL_TIME_TRIGGER_POINT_2,
                 A.DWELL_TIME_TRIGGER_POINT_3,
                 v_XML.DWELL_TIME_DOWN_1,
                 v_XML.DWELL_TIME_DOWN_2,
                 v_XML.DWELL_TIME_DOWN_3,
                 v_XML.DWELL_TIME_DOWN_TRIGGER_PT_1,
                 v_XML.DWELL_TIME_DOWN_TRIGGER_PT_2,
                 v_XML.DWELL_TIME_DOWN_TRIGGER_PT_3,
                 v_XML.RAMP_DOWN_RATE_1,
                 v_XML.RAMP_DOWN_RATE_2,
                 v_XML.RAMP_DOWN_RATE_3,
                 v_XML.RAMP_DOWN_RATE_4,
                 v_XML.RAMP_DOWN_RATE_5,
                 v_XML.RAMP_DOWN_BREAK_POINT_1,
                 v_XML.RAMP_DOWN_BREAK_POINT_2,
                 v_XML.RAMP_DOWN_BREAK_POINT_3,
                 v_XML.RAMP_DOWN_BREAK_POINT_4,
                 v_XML.DELOADING_RATE_1,
                 v_XML.DELOADING_RATE_2,
                 v_XML.DELOAD_BREAK_POINT,
                 v_XML.MAXIMUM_STORAGE_CAPACITY,
                 v_XML.MINIMUM_STORAGE_CAPACITY,
                 v_XML.PUMPING_LOAD_CAP,
                 v_XML.TARGET_RESERVOIR_LEVEL_PERCENT,
                 v_XML.ENERGY_LIMIT_MWH,
                 v_XML.ENERGY_LIMIT_FACTOR,
                 v_XML.FIXED_UNIT_LOAD,
                 v_XML.UNIT_LOAD_SCALAR,
                 v_XML.MAXIMUM_RAMP_UP_RATE,
                 v_XML.MAXIMUM_RAMP_DOWN_RATE,
                 v_XML.MINIMUM_DOWN_TIME,
                 v_XML.MAXIMUM_DOWN_TIME,
                 v_GEN_EVENT_ID,
                 v_DEM_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ' (possible offending record is ' || v_RECORD_COUNT-1 || '): ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_TECH_OFFER_STD_UNITS;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TECH_OFFER_FORECAST(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) AS
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT NUMBER(9) := 0;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE') TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
               NVL(TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE')), MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR) RUN_TYPE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') JURISDICTION,
               EXTRACTVALUE(VALUE(T), '//DATAROW/UNDER_TEST_YN') UNDER_TEST_YN,
                TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               EXTRACTVALUE(VALUE(T), '//DATAROW/FORECAST_AVAILABILITY') FORECAST_AVAILABILITY,
               EXTRACTVALUE(VALUE(T), '//DATAROW/FORECAST_MINIMUM_STABLE_GEN') FORECAST_MINIMUM_STABLE_GEN,
               EXTRACTVALUE(VALUE(T), '//DATAROW/FORECAST_MINIMUM_OUTPUT') FORECAST_MINIMUM_OUTPUT
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        MERGE INTO SEM_TECH_OFFER_FORECAST S
        USING (SELECT v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_XML.RESOURCE_TYPE,
					  v_XML.RUN_TYPE RUN_TYPE,
                      v_XML.JURISDICTION,
                      v_XML.UNDER_TEST_YN,
                      v_XML.FORECAST_AVAILABILITY,
                      v_XML.FORECAST_MINIMUM_STABLE_GEN,
                      v_XML.FORECAST_MINIMUM_OUTPUT,
                      p_LOGGER.LAST_EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.RUN_TYPE = S.RUN_TYPE)
        WHEN MATCHED THEN
            UPDATE
            SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
                S.JURISDICTION = v_XML.JURISDICTION,
                S.UNDER_TEST_YN = v_XML.UNDER_TEST_YN,
                S.FORECAST_AVAILABILITY = v_XML.FORECAST_AVAILABILITY,
                S.FORECAST_MINIMUM_STABLE_GEN = v_XML.FORECAST_MINIMUM_STABLE_GEN,
                S.FORECAST_MINIMUM_OUTPUT = v_XML.FORECAST_MINIMUM_OUTPUT,
                S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (POD_ID,
                 SCHEDULE_DATE,
				 RUN_TYPE,
                 RESOURCE_TYPE,
                 JURISDICTION,
                 UNDER_TEST_YN,
                 FORECAST_AVAILABILITY,
                 FORECAST_MINIMUM_STABLE_GEN,
                 FORECAST_MINIMUM_OUTPUT,
                 EVENT_ID)
            VALUES
                (v_POD_ID,
                 v_SCHEDULE_DATE,
				 v_XML.RUN_TYPE,
                 v_XML.RESOURCE_TYPE,
                 v_XML.JURISDICTION,
                 v_XML.UNDER_TEST_YN,
                 v_XML.FORECAST_AVAILABILITY,
                 v_XML.FORECAST_MINIMUM_STABLE_GEN,
                 v_XML.FORECAST_MINIMUM_OUTPUT,
                 p_LOGGER.LAST_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_TECH_OFFER_FORECAST;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_COMM_OFFER_STD_UNITS(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;

    v_DEM_EVENT_ID  NUMBER(9);
    v_GEN_EVENT_ID  NUMBER(9);
     v_SCHEDULE_TYPE NUMBER(9);

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') + 1 / 24 / 60 / 60 TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') JURISDICTION,
               EXTRACTVALUE(VALUE(T), '//DATAROW/FUEL_TYPE') FUEL_TYPE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/PRIORITY_DISPATCH_YN') PRIORITY_DISPATCH_YN,
               EXTRACTVALUE(VALUE(T), '//DATAROW/PUMP_STORAGE_YN') PUMP_STORAGE_YN,
               EXTRACTVALUE(VALUE(T), '//DATAROW/ENERGY_LIMIT_YN') ENERGY_LIMIT_YN,
               EXTRACTVALUE(VALUE(T), '//DATAROW/UNDER_TEST_YN') UNDER_TEST_YN,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_1')
               END PRICE_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_1')
               END QUANTITY_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_2')
               END PRICE_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_2')
               END QUANTITY_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_3')
               END PRICE_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_3')
               END QUANTITY_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_4')
               END PRICE_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_4')
               END QUANTITY_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_5')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_5')
               END PRICE_5,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_5')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_5')
               END QUANTITY_5,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_6')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_6')
               END PRICE_6,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_6')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_6')
               END QUANTITY_6,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_7')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_7')
               END PRICE_7,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_7')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_7')
               END QUANTITY_7,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_8')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_8')
               END PRICE_8,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_8')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_8')
               END QUANTITY_8,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_9')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_9')
               END PRICE_9,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_9')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_9')
               END QUANTITY_9,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_10')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_10')
               END PRICE_10,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_10')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_10')
               END QUANTITY_10,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/STARTUP_COST_HOT')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/STARTUP_COST_HOT')
               END STARTUP_COST_HOT,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/STARTUP_COST_WARM')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/STARTUP_COST_WARM')
               END STARTUP_COST_WARM,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/STARTUP_COST_COLD')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/STARTUP_COST_COLD')
               END STARTUP_COST_COLD,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/NO_LOAD_COST')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/NO_LOAD_COST')
               END NO_LOAD_COST,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/TARGET_RESV_LEVEL_MWH')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/TARGET_RESV_LEVEL_MWH')
               END TARGET_RESV_LEVEL_MWH,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PUMP_STORAGE_CYC_EFY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PUMP_STORAGE_CYC_EFY')
               END PUMP_STORAGE_CYC_EFY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SHUTDOWN_COST')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SHUTDOWN_COST')
               END SHUTDOWN_COST
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

  IF g_REPORT_NAME = 'PUB_D_CODStandardGenUnits' THEN
    v_DEM_EVENT_ID := NULL;
    v_GEN_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
  ELSE
    v_DEM_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
    v_GEN_EVENT_ID := NULL;
  END IF;

  IF g_RUN_TYPE IS NULL THEN
    v_SCHEDULE_TYPE := GET_STATEMENT_TYPE(NULL, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA);
  ELSIF g_RUN_TYPE = 'EA' THEN
    v_SCHEDULE_TYPE := GET_STATEMENT_TYPE(NULL, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA);
  ELSE
    v_SCHEDULE_TYPE := GET_STATEMENT_TYPE(NULL, g_RUN_TYPE);
  END IF;

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := v_XML.TRADE_DATE;

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        MERGE INTO SEM_COMM_OFFER_STD_UNITS S
        USING (SELECT v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                         v_SCHEDULE_TYPE AS SCHEDULE_TYPE,
                      v_XML.RESOURCE_TYPE,
                      v_XML.JURISDICTION JURISDICTION,
                      v_XML.FUEL_TYPE FUEL_TYPE,
                      v_XML.PRIORITY_DISPATCH_YN PRIORITY_DISPATCH_YN,
                      v_XML.PUMP_STORAGE_YN PUMP_STORAGE_YN,
                      v_XML.ENERGY_LIMIT_YN ENERGY_LIMIT_YN,
                      v_XML.UNDER_TEST_YN UNDER_TEST_YN,
                      v_XML.PRICE_1 PRICE_1,
                      v_XML.QUANTITY_1 QUANTITY_1,
                      v_XML.PRICE_2 PRICE_2,
                      v_XML.QUANTITY_2 QUANTITY_2,
                      v_XML.PRICE_3 PRICE_3,
                      v_XML.QUANTITY_3 QUANTITY_3,
                      v_XML.PRICE_4 PRICE_4,
                      v_XML.QUANTITY_4 QUANTITY_4,
                      v_XML.PRICE_5 PRICE_5,
                      v_XML.QUANTITY_5 QUANTITY_5,
                      v_XML.PRICE_6 PRICE_6,
                      v_XML.QUANTITY_6 QUANTITY_6,
                      v_XML.PRICE_7 PRICE_7,
                      v_XML.QUANTITY_7 QUANTITY_7,
                      v_XML.PRICE_8 PRICE_8,
                      v_XML.QUANTITY_8 QUANTITY_8,
                      v_XML.PRICE_9 PRICE_9,
                      v_XML.QUANTITY_9 QUANTITY_9,
                      v_XML.PRICE_10 PRICE_10,
                      v_XML.QUANTITY_10 QUANTITY_10,
                      v_XML.STARTUP_COST_HOT STARTUP_COST_HOT,
                      v_XML.STARTUP_COST_WARM STARTUP_COST_WARM,
                      v_XML.STARTUP_COST_COLD STARTUP_COST_COLD,
                      v_XML.NO_LOAD_COST NO_LOAD_COST,
                      v_XML.TARGET_RESV_LEVEL_MWH TARGET_RESV_LEVEL_MWH,
                      v_XML.PUMP_STORAGE_CYC_EFY PUMP_STORAGE_CYC_EFY,
                      v_XML.SHUTDOWN_COST SHUTDOWN_COST,
                      v_GEN_EVENT_ID GEN_EVENT_ID,
                      v_DEM_EVENT_ID DEM_EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.SCHEDULE_TYPE = S.SCHEDULE_TYPE)
        WHEN MATCHED THEN
            UPDATE
            SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
                S.JURISDICTION = v_XML.JURISDICTION,
                S.FUEL_TYPE = v_XML.FUEL_TYPE,
                S.PRIORITY_DISPATCH_YN = v_XML.PRIORITY_DISPATCH_YN,
                S.PUMP_STORAGE_YN = v_XML.PUMP_STORAGE_YN,
                S.ENERGY_LIMIT_YN = v_XML.ENERGY_LIMIT_YN,
                S.UNDER_TEST_YN = v_XML.UNDER_TEST_YN,
                S.PRICE_1 = v_XML.PRICE_1,
                S.QUANTITY_1 = v_XML.QUANTITY_1,
                S.PRICE_2 = v_XML.PRICE_2,
                S.QUANTITY_2 = v_XML.QUANTITY_2,
                S.PRICE_3 = v_XML.PRICE_3,
                S.QUANTITY_3 = v_XML.QUANTITY_3,
                S.PRICE_4 = v_XML.PRICE_4,
                S.QUANTITY_4 = v_XML.QUANTITY_4,
                S.PRICE_5 = v_XML.PRICE_5,
                S.QUANTITY_5 = v_XML.QUANTITY_5,
                S.PRICE_6 = v_XML.PRICE_6,
                S.QUANTITY_6 = v_XML.QUANTITY_6,
                S.PRICE_7 = v_XML.PRICE_7,
                S.QUANTITY_7 = v_XML.QUANTITY_7,
                S.PRICE_8 = v_XML.PRICE_8,
                S.QUANTITY_8 = v_XML.QUANTITY_8,
                S.PRICE_9 = v_XML.PRICE_9,
                S.QUANTITY_9 = v_XML.QUANTITY_9,
                S.PRICE_10 = v_XML.PRICE_10,
                S.QUANTITY_10 = v_XML.QUANTITY_10,
                S.STARTUP_COST_HOT = v_XML.STARTUP_COST_HOT,
                S.STARTUP_COST_WARM = v_XML.STARTUP_COST_WARM,
                S.STARTUP_COST_COLD = v_XML.STARTUP_COST_COLD,
                S.NO_LOAD_COST = v_XML.NO_LOAD_COST,
                S.TARGET_RESV_LEVEL_MWH = v_XML.TARGET_RESV_LEVEL_MWH,
                S.PUMP_STORAGE_CYC_EFY = v_XML.PUMP_STORAGE_CYC_EFY,
                S.SHUTDOWN_COST = v_XML.SHUTDOWN_COST,
                S.GEN_EVENT_ID = v_GEN_EVENT_ID,
                S.DEM_EVENT_ID = v_DEM_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (POD_ID,
                 SCHEDULE_DATE,
                  SCHEDULE_TYPE,
                 RESOURCE_TYPE,
                 JURISDICTION,
                 FUEL_TYPE,
                 PRIORITY_DISPATCH_YN,
                 PUMP_STORAGE_YN,
                 ENERGY_LIMIT_YN,
                 UNDER_TEST_YN,
                 PRICE_1,
                 QUANTITY_1,
                 PRICE_2,
                 QUANTITY_2,
                 PRICE_3,
                 QUANTITY_3,
                 PRICE_4,
                 QUANTITY_4,
                 PRICE_5,
                 QUANTITY_5,
                 PRICE_6,
                 QUANTITY_6,
                 PRICE_7,
                 QUANTITY_7,
                 PRICE_8,
                 QUANTITY_8,
                 PRICE_9,
                 QUANTITY_9,
                 PRICE_10,
                 QUANTITY_10,
                 STARTUP_COST_HOT,
                 STARTUP_COST_WARM,
                 STARTUP_COST_COLD,
                 NO_LOAD_COST,
                 TARGET_RESV_LEVEL_MWH,
                 PUMP_STORAGE_CYC_EFY,
                 SHUTDOWN_COST,
                 GEN_EVENT_ID,
                 DEM_EVENT_ID)
            VALUES
                (v_POD_ID,
                 v_SCHEDULE_DATE,
                  v_SCHEDULE_TYPE,
                 v_XML.RESOURCE_TYPE,
                 v_XML.JURISDICTION,
                 v_XML.FUEL_TYPE,
                 v_XML.PRIORITY_DISPATCH_YN,
                 v_XML.PUMP_STORAGE_YN,
                 v_XML.ENERGY_LIMIT_YN,
                 v_XML.UNDER_TEST_YN,
                 v_XML.PRICE_1,
                 v_XML.QUANTITY_1,
                 v_XML.PRICE_2,
                 v_XML.QUANTITY_2,
                 v_XML.PRICE_3,
                 v_XML.QUANTITY_3,
                 v_XML.PRICE_4,
                 v_XML.QUANTITY_4,
                 v_XML.PRICE_5,
                 v_XML.QUANTITY_5,
                 v_XML.PRICE_6,
                 v_XML.QUANTITY_6,
                 v_XML.PRICE_7,
                 v_XML.QUANTITY_7,
                 v_XML.PRICE_8,
                 v_XML.QUANTITY_8,
                 v_XML.PRICE_9,
                 v_XML.QUANTITY_9,
                 v_XML.PRICE_10,
                 v_XML.QUANTITY_10,
                 v_XML.STARTUP_COST_HOT,
                 v_XML.STARTUP_COST_WARM,
                 v_XML.STARTUP_COST_COLD,
                 v_XML.NO_LOAD_COST,
                 v_XML.TARGET_RESV_LEVEL_MWH,
                 v_XML.PUMP_STORAGE_CYC_EFY,
                 v_XML.SHUTDOWN_COST,
                 v_GEN_EVENT_ID,
                 v_DEM_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_COMM_OFFER_STD_UNITS;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_COMM_OFFER_IC(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;
    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') JURISDICTION,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               NVL(EXTRACTVALUE(VALUE(T), '//DATAROW/GATE_WINDOW'), MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR) GATE_WINDOW,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_1')
               END PRICE_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_1')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_1')
               END QUANTITY_1,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_2')
               END PRICE_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_2')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_2')
               END QUANTITY_2,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_3')
               END PRICE_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_3')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_3')
               END QUANTITY_3,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_4')
               END PRICE_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_4')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_4')
               END QUANTITY_4,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_5')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_5')
               END PRICE_5,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_5')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_5')
               END QUANTITY_5,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_6')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_6')
               END PRICE_6,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_6')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_6')
               END QUANTITY_6,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_7')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_7')
               END PRICE_7,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_7')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_7')
               END QUANTITY_7,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_8')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_8')
               END PRICE_8,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_8')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_8')
               END QUANTITY_8,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_9')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_9')
               END PRICE_9,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_9')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_9')
               END QUANTITY_9,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_10')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_10')
               END PRICE_10,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_10')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY_10')
               END QUANTITY_10,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_IU_IMPORT_CAPACITY_MW')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_IU_IMPORT_CAPACITY_MW')
               END MAXIMUM_IU_IMPORT_CAPACITY_MW,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_IU_EXPORT_CAPACITY_MW')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_IU_EXPORT_CAPACITY_MW')
               END MAXIMUM_IU_EXPORT_CAPACITY_MW
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

        --get POD_ID (this should always be MOYLE, at least until 2011 or so)
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        -- get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);

        MERGE INTO SEM_COMM_OFFER_IC S
        USING (SELECT v_PSE_ID PSE_ID,
                      v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_XML.GATE_WINDOW GATE_WINDOW,
                      v_XML.RESOURCE_TYPE,
                      v_XML.JURISDICTION,
                      v_XML.PRICE_1,
                      v_XML.QUANTITY_1,
                      v_XML.PRICE_2,
                      v_XML.QUANTITY_2,
                      v_XML.PRICE_3,
                      v_XML.QUANTITY_3,
                      v_XML.PRICE_4,
                      v_XML.QUANTITY_4,
                      v_XML.PRICE_5,
                      v_XML.QUANTITY_5,
                      v_XML.PRICE_6,
                      v_XML.QUANTITY_6,
                      v_XML.PRICE_7,
                      v_XML.QUANTITY_7,
                      v_XML.PRICE_8,
                      v_XML.QUANTITY_8,
                      v_XML.PRICE_9,
                      v_XML.QUANTITY_9,
                      v_XML.PRICE_10,
                      v_XML.QUANTITY_10,
                      v_XML.MAXIMUM_IU_IMPORT_CAPACITY_MW,
                      v_XML.MAXIMUM_IU_EXPORT_CAPACITY_MW,
                      p_LOGGER.LAST_EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.PSE_ID = S.PSE_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.GATE_WINDOW = S.GATE_WINDOW)
        WHEN MATCHED THEN
            UPDATE
            SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
                S.JURISDICTION = v_XML.JURISDICTION,
                S.PRICE_1 = v_XML.PRICE_1,
                S.QUANTITY_1 = v_XML.QUANTITY_1,
                S.PRICE_2 = v_XML.PRICE_2,
                S.QUANTITY_2 = v_XML.QUANTITY_2,
                S.PRICE_3 = v_XML.PRICE_3,
                S.QUANTITY_3 = v_XML.QUANTITY_3,
                S.PRICE_4 = v_XML.PRICE_4,
                S.QUANTITY_4 = v_XML.QUANTITY_4,
                S.PRICE_5 = v_XML.PRICE_5,
                S.QUANTITY_5 = v_XML.QUANTITY_5,
                S.PRICE_6 = v_XML.PRICE_6,
                S.QUANTITY_6 = v_XML.QUANTITY_6,
                S.PRICE_7 = v_XML.PRICE_7,
                S.QUANTITY_7 = v_XML.QUANTITY_7,
                S.PRICE_8 = v_XML.PRICE_8,
                S.QUANTITY_8 = v_XML.QUANTITY_8,
                S.PRICE_9 = v_XML.PRICE_9,
                S.QUANTITY_9 = v_XML.QUANTITY_9,
                S.PRICE_10 = v_XML.PRICE_10,
                S.QUANTITY_10 = v_XML.QUANTITY_10,
                S.MAXIMUM_IU_IMPORT_CAPACITY_MW = v_XML.MAXIMUM_IU_IMPORT_CAPACITY_MW,
                S.MAXIMUM_IU_EXPORT_CAPACITY_MW = v_XML.MAXIMUM_IU_EXPORT_CAPACITY_MW,
                S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (PSE_ID,
                 POD_ID,
                 SCHEDULE_DATE,
                 GATE_WINDOW,
                 RESOURCE_TYPE,
                 JURISDICTION,
                 PRICE_1,
                 QUANTITY_1,
                 PRICE_2,
                 QUANTITY_2,
                 PRICE_3,
                 QUANTITY_3,
                 PRICE_4,
                 QUANTITY_4,
                 PRICE_5,
                 QUANTITY_5,
                 PRICE_6,
                 QUANTITY_6,
                 PRICE_7,
                 QUANTITY_7,
                 PRICE_8,
                 QUANTITY_8,
                 PRICE_9,
                 QUANTITY_9,
                 PRICE_10,
                 QUANTITY_10,
                 MAXIMUM_IU_IMPORT_CAPACITY_MW,
                 MAXIMUM_IU_EXPORT_CAPACITY_MW,
                 EVENT_ID)
            VALUES
                (v_PSE_ID,
                 v_POD_ID,
                 v_SCHEDULE_DATE,
                 v_XML.GATE_WINDOW,
                 v_XML.RESOURCE_TYPE,
                 v_XML.JURISDICTION,
                 v_XML.PRICE_1,
                 v_XML.QUANTITY_1,
                 v_XML.PRICE_2,
                 v_XML.QUANTITY_2,
                 v_XML.PRICE_3,
                 v_XML.QUANTITY_3,
                 v_XML.PRICE_4,
                 v_XML.QUANTITY_4,
                 v_XML.PRICE_5,
                 v_XML.QUANTITY_5,
                 v_XML.PRICE_6,
                 v_XML.QUANTITY_6,
                 v_XML.PRICE_7,
                 v_XML.QUANTITY_7,
                 v_XML.PRICE_8,
                 v_XML.QUANTITY_8,
                 v_XML.PRICE_9,
                 v_XML.QUANTITY_9,
                 v_XML.PRICE_10,
                 v_XML.QUANTITY_10,
                 v_XML.MAXIMUM_IU_IMPORT_CAPACITY_MW,
                 v_XML.MAXIMUM_IU_EXPORT_CAPACITY_MW,
                 p_LOGGER.LAST_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_COMM_OFFER_IC;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NOM_PROFILE(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;

    v_DEM_EVENT_ID NUMBER(9);
    v_GEN_EVENT_ID NUMBER(9);
    v_RUN_TYPE     SEM_NOM_PROFILE.RUN_TYPE%TYPE;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE') TRADE_DATE,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') JURISDICTION,
               EXTRACTVALUE(VALUE(T), '//DATAROW/UNDER_TEST_YN') UNDER_TEST_YN,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/NOMINATED_QUANTITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/NOMINATED_QUANTITY')
               END NOMINATED_QUANTITY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DECREMENTAL_PRICE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/DECREMENTAL_PRICE')
               END DECREMENTAL_PRICE
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    IF g_REPORT_NAME = 'PUB_D_CommercialOfferDataGenNomProfiles' THEN
        v_DEM_EVENT_ID := NULL;
        v_GEN_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
    ELSE
        v_DEM_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
        v_GEN_EVENT_ID := NULL;
    END IF;

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        -- Run Type
        v_RUN_TYPE := NVL(g_RUN_TYPE, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR);

        MERGE INTO SEM_NOM_PROFILE S
        USING (SELECT v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_XML.RESOURCE_TYPE RESOURCE_TYPE,
                      v_RUN_TYPE RUN_TYPE,
                      v_XML.JURISDICTION JURISDICTION,
                      v_XML.UNDER_TEST_YN UNDER_TEST_YN,
                      v_XML.NOMINATED_QUANTITY NOMINATED_QUANTITY,
                      v_XML.DECREMENTAL_PRICE DECREMENTAL_PRICE,
                      v_GEN_EVENT_ID GEN_EVENT_ID,
                      v_DEM_EVENT_ID DEM_EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.RUN_TYPE = S.RUN_TYPE)
        WHEN MATCHED THEN
            UPDATE
            SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
                S.JURISDICTION = v_XML.JURISDICTION,
                S.UNDER_TEST_YN = v_XML.UNDER_TEST_YN,
                S.NOMINATED_QUANTITY = v_XML.NOMINATED_QUANTITY,
                S.DECREMENTAL_PRICE = v_XML.DECREMENTAL_PRICE,
                S.GEN_EVENT_ID = v_GEN_EVENT_ID,
                S.DEM_EVENT_ID = v_DEM_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (POD_ID,
                 SCHEDULE_DATE,
                 RUN_TYPE,
                 RESOURCE_TYPE,
                 JURISDICTION,
                 UNDER_TEST_YN,
                 NOMINATED_QUANTITY,
                 DECREMENTAL_PRICE,
                 GEN_EVENT_ID,
                 DEM_EVENT_ID)
            VALUES
                (v_POD_ID,
                 v_SCHEDULE_DATE,
                 v_RUN_TYPE,
                 v_XML.RESOURCE_TYPE,
                 v_XML.JURISDICTION,
                 v_XML.UNDER_TEST_YN,
                 v_XML.NOMINATED_QUANTITY,
                 v_XML.DECREMENTAL_PRICE,
                 v_GEN_EVENT_ID,
                 v_DEM_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_NOM_PROFILE;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_DEMAND_CTRL_DATA(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_TXN_ID           INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_SCHEDULE_TYPE_ID STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
    v_STATUS           NUMBER(9);
    v_SCHEDULE_DATE    DATE;
    v_XML_REP          XMLTYPE;
    v_RECORD_COUNT     NUMBER(9) := 0;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE') TRADE_DATE,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/ESTIMATE_DEMAND_REDUCTION_MW')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/ESTIMATE_DEMAND_REDUCTION_MW')
               END ESTIMATE_DEMAND_REDUCTION_MW
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    v_SCHEDULE_TYPE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INDIC_EP,
                                                           EC.ED_STATEMENT_TYPE,
                                                           EC.ES_SEM,
                                                           MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);

    v_TXN_ID := MM_SEM_UTIL.GET_DEMAND_CTRL_DATA_TXN(p_LOGGER);
    IF LOGS.GET_ERROR_COUNT() = 0 THEN
        FOR v_XML IN c_XML LOOP
            --calculate the SCHEDULE_DATE
            v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID,
                                p_SCHEDULE_TYPE  => v_SCHEDULE_TYPE_ID,
                                p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                                p_AS_OF_DATE     => LOW_DATE,
                                p_AMOUNT         => v_XML.ESTIMATE_DEMAND_REDUCTION_MW,
                                p_PRICE          => NULL,
                                p_STATUS         => v_STATUS);

            v_RECORD_COUNT := v_RECORD_COUNT + 1;
        END LOOP;
        p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
        COMMIT;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_DEMAND_CTRL_DATA;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OPS_SCHED(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') JURISDICTION,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SCHEDULE_MW')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SCHEDULE_MW')
               END SCHEDULE_MW,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/POST_TIME'), 'DD/MM/YYYY HH24:MI:SS') POST_TIME
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        -- get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);

        MERGE INTO SEM_OPS_SCHEDULE S
        USING (SELECT v_PSE_ID PSE_ID,
                      v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_XML.JURISDICTION,
                      v_XML.SCHEDULE_MW,
                      v_XML.POST_TIME,
                      p_LOGGER.LAST_EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.PSE_ID = S.PSE_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE)
        WHEN MATCHED THEN
            UPDATE
            SET S.JURISDICTION = v_XML.JURISDICTION,
                S.SCHEDULE_MW = v_XML.SCHEDULE_MW,
                S.POST_TIME = v_XML.POST_TIME,
                S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (PSE_ID, POD_ID, SCHEDULE_DATE, JURISDICTION, SCHEDULE_MW, POST_TIME, EVENT_ID)
            VALUES
                (v_PSE_ID, v_POD_ID, v_SCHEDULE_DATE, v_XML.JURISDICTION, v_XML.SCHEDULE_MW, v_XML.POST_TIME, p_LOGGER.LAST_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_OPS_SCHED;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SO_TRADES(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') + 1 / 24 / 60 / 60 TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_IMP_PRICE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_IMP_PRICE')
               END SO_INTERCON_IMP_PRICE,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_IMP_QUANTITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_IMP_QUANTITY')
               END SO_INTERCON_IMP_QUANTITY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_EXP_PRICE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_EXP_PRICE')
               END SO_INTERCON_EXP_PRICE,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_EXP_QUANTITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/SO_INTERCON_EXP_QUANTITY')
               END SO_INTERCON_EXP_QUANTITY
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        MERGE INTO SEM_SO_TRADES S
        USING (SELECT v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_XML.SO_INTERCON_IMP_PRICE SO_INTERCON_IMP_PRICE,
                      v_XML.SO_INTERCON_IMP_QUANTITY SO_INTERCON_IMP_QUANTITY,
                      v_XML.SO_INTERCON_EXP_PRICE SO_INTERCON_EXP_PRICE,
                      v_XML.SO_INTERCON_EXP_QUANTITY SO_INTERCON_EXP_QUANTITY,
                      p_LOGGER.LAST_EVENT_ID EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE)
        WHEN MATCHED THEN
            UPDATE
            SET S.SO_INTERCON_IMP_PRICE = A.SO_INTERCON_IMP_PRICE,
                S.SO_INTERCON_IMP_QUANTITY = A.SO_INTERCON_IMP_QUANTITY,
                S.SO_INTERCON_EXP_PRICE = A.SO_INTERCON_EXP_PRICE,
                S.SO_INTERCON_EXP_QUANTITY = A.SO_INTERCON_EXP_QUANTITY,
                S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (POD_ID,
                 SCHEDULE_DATE,
                 SO_INTERCON_EXP_QUANTITY,
                 SO_INTERCON_IMP_PRICE,
                 SO_INTERCON_IMP_QUANTITY,
                 SO_INTERCON_EXP_PRICE,
                 EVENT_ID)
            VALUES
                (v_POD_ID,
                 v_SCHEDULE_DATE,
                 v_XML.SO_INTERCON_EXP_QUANTITY,
                 v_XML.SO_INTERCON_IMP_PRICE,
                 v_XML.SO_INTERCON_IMP_QUANTITY,
                 v_XML.SO_INTERCON_EXP_PRICE,
                 p_LOGGER.LAST_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_SO_TRADES;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IC_OFFER_CAPACITY(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;
	v_RUN_TYPE 		VARCHAR2(3);

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') + 1 / 24 / 60 / 60 TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/AIC')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/AIC')
               END AIC,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/OICE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/OICE')
               END OICE,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/OICI')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/OICI')
               END OICI,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAX_EXPORT_ATC')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAX_EXPORT_ATC')
               END MAX_EXPORT_ATC,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MAX_IMPORT_ATC')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/MAX_IMPORT_ATC')
               END MAX_IMPORT_ATC
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';
    
    SELECT EXTRACTVALUE(v_XML_REP, 'REPORT/REPORT_HEADER/HEADROW/RUN_TYPE') INTO v_RUN_TYPE FROM DUAL;

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        MERGE INTO SEM_IC_OFFER_CAPACITY S
        USING (SELECT v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
					  v_RUN_TYPE RUN_TYPE,
                      v_XML.AIC AIC,
                      v_XML.OICE OICE,
                      v_XML.OICI OICI,
                      v_XML.MAX_EXPORT_ATC MAX_EXPORT_ATC,
                      v_XML.MAX_IMPORT_ATC MAX_IMPORT_ATC,
                      p_LOGGER.LAST_EVENT_ID EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.RUN_TYPE = S.RUN_TYPE)
        WHEN MATCHED THEN
            UPDATE
            SET S.AIC = A.AIC,
                S.OICE = A.OICE,
                S.OICI = A.OICI,
                S.MAX_EXPORT_ATC = A.MAX_EXPORT_ATC,
                S.MAX_IMPORT_ATC = A.MAX_IMPORT_ATC,
                S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (POD_ID,
                 SCHEDULE_DATE,
				 RUN_TYPE,
                 AIC,
                 OICE,
                 OICI,
                 MAX_EXPORT_ATC,
                 MAX_IMPORT_ATC,
                 EVENT_ID)
            VALUES
                (v_POD_ID,
                 v_SCHEDULE_DATE,
				 v_RUN_TYPE,
                 v_XML.AIC,
                 v_XML.OICE,
                 v_XML.OICI,
                 v_XML.MAX_EXPORT_ATC,
                 v_XML.MAX_IMPORT_ATC,
                 p_LOGGER.LAST_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_IC_OFFER_CAPACITY;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EN_LTD_TECH_CHAR(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') + 1/24/60/60 TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/REDECLARED_ENERGY_LIMIT')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/REDECLARED_ENERGY_LIMIT')
               END REDECLARED_ENERGY_LIMIT
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := v_XML.TRADE_DATE;

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        -- get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);

        MERGE INTO SEM_TECH_CHAR_EN_LTD S
        USING (SELECT v_PSE_ID PSE_ID,
                      v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_XML.RESOURCE_TYPE,
                      v_XML.REDECLARED_ENERGY_LIMIT,
                      p_LOGGER.LAST_EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.PSE_ID = S.PSE_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE)
        WHEN MATCHED THEN
            UPDATE
            SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
                S.REDECLARED_ENERGY_LIMIT = v_XML.REDECLARED_ENERGY_LIMIT,
                S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (PSE_ID, POD_ID, SCHEDULE_DATE, RESOURCE_TYPE, REDECLARED_ENERGY_LIMIT, EVENT_ID)
            VALUES
                (v_PSE_ID, v_POD_ID, v_SCHEDULE_DATE, v_XML.RESOURCE_TYPE, v_XML.REDECLARED_ENERGY_LIMIT, p_LOGGER.LAST_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_EN_LTD_TECH_CHAR;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_GEN_UNIT_TECH_CHAR(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;

    -- note that timestamp formats are different from MM_SEM_UTIL.g_TIMESTAMP_FORMAT
    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') + 1 / 24 / 60 / 60 TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/GMT_OFFSET')
                   WHEN '-' THEN
                    0
                   ELSE
                    TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/GMT_OFFSET'))
               END GMT_OFFSET,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EFF_TIME'), 'DD/MM/YYYY HH24:MI:SS') EFF_TIME,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/ISSUE_TIME'), 'DD/MM/YYYY HH24:MI:SS') ISSUE_TIME,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/OUTTURN_AVAILABILITY')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/OUTTURN_AVAILABILITY')
               END OUTTURN_AVAILABILITY,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/OUTTURN_MINIMUM_STABLE_GEN')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/OUTTURN_MINIMUM_STABLE_GEN')
               END OUTTURN_MINIMUM_STABLE_GEN,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/OUTTURN_MINIMUM_OUTPUT')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/OUTTURN_MINIMUM_OUTPUT')
               END OUTTURN_MINIMUM_OUTPUT
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := v_XML.TRADE_DATE;

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        -- get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);

        MERGE INTO SEM_TECH_CHAR_GEN S
        USING (SELECT v_PSE_ID PSE_ID,
                      v_POD_ID POD_ID,
                      v_SCHEDULE_DATE SCHEDULE_DATE,
                      v_XML.GMT_OFFSET GMT_OFFSET,
                      v_XML.EFF_TIME EFF_TIME,
                      v_XML.ISSUE_TIME ISSUE_TIME,
                      v_XML.RESOURCE_TYPE RESOURCE_TYPE,
                      v_XML.OUTTURN_AVAILABILITY OUTTURN_AVAILABILITY,
                      v_XML.OUTTURN_MINIMUM_STABLE_GEN OUTTURN_MINIMUM_STABLE_GEN,
                      v_XML.OUTTURN_MINIMUM_OUTPUT OUTTURN_MINIMUM_OUTPUT,
                      p_LOGGER.LAST_EVENT_ID EVENT_ID
               FROM DUAL) A
        ON (A.POD_ID = S.POD_ID AND A.PSE_ID = S.PSE_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.GMT_OFFSET = S.GMT_OFFSET AND A.EFF_TIME = S.EFF_TIME AND A.ISSUE_TIME = S.ISSUE_TIME)
        WHEN MATCHED THEN
            UPDATE
            SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
                S.OUTTURN_AVAILABILITY = v_XML.OUTTURN_AVAILABILITY,
                S.OUTTURN_MINIMUM_STABLE_GEN = v_XML.OUTTURN_MINIMUM_STABLE_GEN,
                S.OUTTURN_MINIMUM_OUTPUT = v_XML.OUTTURN_MINIMUM_OUTPUT,
                S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHEN NOT MATCHED THEN
            INSERT
                (PSE_ID,
                 POD_ID,
                 SCHEDULE_DATE,
                 GMT_OFFSET,
                 EFF_TIME,
                 ISSUE_TIME,
                 RESOURCE_TYPE,
                 OUTTURN_AVAILABILITY,
                 OUTTURN_MINIMUM_STABLE_GEN,
                 OUTTURN_MINIMUM_OUTPUT,
                 EVENT_ID)
            VALUES
                (v_PSE_ID,
                 v_POD_ID,
                 v_SCHEDULE_DATE,
                 v_XML.GMT_OFFSET,
                 v_XML.EFF_TIME,
                 v_XML.ISSUE_TIME,
                 v_XML.RESOURCE_TYPE,
                 v_XML.OUTTURN_AVAILABILITY,
                 v_XML.OUTTURN_MINIMUM_STABLE_GEN,
                 v_XML.OUTTURN_MINIMUM_OUTPUT,
                 p_LOGGER.LAST_EVENT_ID);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_GEN_UNIT_TECH_CHAR;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_METER_DETAIL_PUB(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT  NUMBER(9) := 0;

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') JURISDICTION,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/METERED_MW')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    EXTRACTVALUE(VALUE(T), '//DATAROW/METERED_MW')
               END METERED_MW,
               EXTRACTVALUE(VALUE(T), '//DATAROW/METER_TRANSMISSION_TYPE') METER_TRANSMISSION_TYPE
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

        -- get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);

        MERGE INTO SEM_METER_DETAILS_PUB S
        USING (SELECT v_PSE_ID PSE_ID,
                      v_POD_ID POD_ID,
            v_SCHEDULE_DATE SCHEDULE_DATE,
            v_XML.RESOURCE_TYPE,
            v_XML.JURISDICTION,
            v_XML.METERED_MW,
            v_XML.METER_TRANSMISSION_TYPE,
            p_LOGGER.LAST_EVENT_ID
         FROM DUAL) A
    ON (A.POD_ID = S.POD_ID AND A.PSE_ID = S.PSE_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE)
    WHEN MATCHED THEN
      UPDATE
      SET S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
        S.JURISDICTION = v_XML.JURISDICTION,
        S.METERED_MW = v_XML.METERED_MW,
        S.METER_TRANSMISSION_TYPE = v_XML.METER_TRANSMISSION_TYPE,
        S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
    WHEN NOT MATCHED THEN
      INSERT
        (PSE_ID, POD_ID, SCHEDULE_DATE, RESOURCE_TYPE, JURISDICTION, METERED_MW, METER_TRANSMISSION_TYPE, EVENT_ID)
      VALUES
        (v_PSE_ID, v_POD_ID, v_SCHEDULE_DATE, v_XML.RESOURCE_TYPE, v_XML.JURISDICTION, v_XML.METERED_MW, v_XML.METER_TRANSMISSION_TYPE, p_LOGGER.LAST_EVENT_ID);

    v_RECORD_COUNT := v_RECORD_COUNT + 1;
  END LOOP;
  p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END IMPORT_METER_DETAIL_PUB;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MKT_SCHED_DETAIL_PUB(p_IMPORT_FILE IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
  v_POD_ID        NUMBER(9);
  v_PSE_ID        NUMBER(9);
  v_SCHEDULE_DATE DATE;
  v_XML_REP       XMLTYPE;
  v_RECORD_COUNT  NUMBER(9) := 0;

  v_EX_ANTE_EVENT_ID    NUMBER(9) := NULL;
  v_INDICATIVE_EVENT_ID NUMBER(9) := NULL;
  v_INITIAL_EVENT_ID    NUMBER(9) := NULL;

  v_SCHEDULE_TYPE NUMBER(9);
  v_GATE_WINDOW_ID NUMBER(9);

  -- works for the two ex-post reports
  v_SCHED_QUANT_ELEMENT VARCHAR2(32) := 'SCHEDULE_QUANTITY';

  CURSOR c_XML IS
    SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') TRADE_DATE,
         EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
         EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
         EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') RESOURCE_TYPE,
         TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
         EXTRACTVALUE(VALUE(T), '//DATAROW/GATE_WINDOW') GATE_WINDOW,
         CASE EXTRACTVALUE(VALUE(T), '//DATAROW/' || v_SCHED_QUANT_ELEMENT)
           WHEN '-' THEN
          NULL
           ELSE
          EXTRACTVALUE(VALUE(T), '//DATAROW/' || v_SCHED_QUANT_ELEMENT)
         END SCHEDULE_QUANTITY,
         CASE NVL(EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_AVAILABILITY'),
                   EXTRACTVALUE(VALUE(T), '//DATAROW/ACTUAL_AVAIL'))
                   WHEN '-' THEN
                    NULL
                   ELSE
                    NVL(EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_AVAILABILITY'),
                        EXTRACTVALUE(VALUE(T), '//DATAROW/ACTUAL_AVAIL'))
               END MAXIMUM_AVAILABILITY,
         CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_GENERATION')
           WHEN '-' THEN
          NULL
           ELSE
          EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_GENERATION')
         END MINIMUM_GENERATION,
         CASE EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_OUTPUT')
           WHEN '-' THEN
          NULL
           ELSE
          EXTRACTVALUE(VALUE(T), '//DATAROW/MINIMUM_OUTPUT')
         END MINIMUM_OUTPUT,
         CASE NVL(EXTRACTVALUE(VALUE(T), '//DATAROW/ACTUAL_AVAILABILITY'),
                        EXTRACTVALUE(VALUE(T), '//DATAROW/AVAILABILITY_PROFILE'))
           WHEN '-' THEN
          NULL
           ELSE
          NVL(EXTRACTVALUE(VALUE(T), '//DATAROW/ACTUAL_AVAILABILITY'),
                        EXTRACTVALUE(VALUE(T), '//DATAROW/AVAILABILITY_PROFILE'))
         END ACTUAL_AVAILABILITY
    FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
  v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
  p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

  CASE g_REPORT_NAME
    WHEN 'PUB_D_ExAnteMktSchDetail' THEN
      v_EX_ANTE_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
      IF g_RUN_TYPE IS NULL THEN
        v_SCHEDULE_TYPE := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
      ELSE
        v_SCHEDULE_TYPE := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(g_RUN_TYPE, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
      END IF;
      v_SCHED_QUANT_ELEMENT := 'MSQ';
    WHEN 'PUB_D_ExPostMktSchDetail' THEN
      v_INDICATIVE_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
      v_SCHEDULE_TYPE := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_IND_ABR, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
    WHEN 'PUB_D_InitialExPostMktSchDetail' THEN
      v_INITIAL_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
      v_SCHEDULE_TYPE := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INI_ABR, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
    ELSE
      p_LOGGER.LOG_ERROR(g_REPORT_NAME || ' not recognized - how did I get here?');
  END CASE;

  FOR v_XML IN c_XML LOOP
    --calculate the SCHEDULE_DATE
    v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

    --get POD_ID
    v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

    --get GATE_WINDOW_ID
    v_GATE_WINDOW_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(NVL(v_XML.GATE_WINDOW, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR), EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_GATE_WINDOW);

    --get PSE_ID
    --For Inidicative and Initial ExPost PreIDT files there is no Participant Name in the file.
    --We assign it to the I_NIMOYLE Administrator.
    IF v_XML.PARTICIPANT_NAME IS NULL THEN
        SELECT PSE_ID
          INTO v_PSE_ID
          FROM SEM_SERVICE_POINT_PSE
         WHERE POD_ID = MM_SEM_UTIL.GET_SERVICE_POINT_ID(MM_SEM_UTIL.g_INTERCONNECT_I_NIMOYLE)
           AND v_SCHEDULE_DATE BETWEEN BEGIN_DATE AND NVL(END_DATE, CONSTANTS.HIGH_DATE);
    ELSE
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);
    END IF;

    MERGE INTO SEM_MKT_SCHED_DETAIL_PUB S
    USING (SELECT v_SCHEDULE_DATE SCHEDULE_DATE,
            v_POD_ID POD_ID,
            v_SCHEDULE_TYPE SCHEDULE_TYPE,
            v_GATE_WINDOW_ID GATE_WINDOW_ID,
            v_PSE_ID PSE_ID,
            v_XML.SCHEDULE_QUANTITY SCHEDULE_QUANTITY,
            v_XML.RESOURCE_TYPE RESOURCE_TYPE,
            v_XML.MAXIMUM_AVAILABILITY MAXIMUM_AVAILABILITY,
            v_XML.MINIMUM_GENERATION MINIMUM_GENERATION,
            v_XML.MINIMUM_OUTPUT MINIMUM_OUTPUT,
            v_XML.ACTUAL_AVAILABILITY ACTUAL_AVAILABILITY,
            v_EX_ANTE_EVENT_ID EX_ANTE_EVENT_ID,
            v_INDICATIVE_EVENT_ID INDICATIVE_EVENT_ID,
            v_INITIAL_EVENT_ID INITIAL_EVENT_ID
         FROM DUAL) A
    ON (A.POD_ID = S.POD_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.SCHEDULE_TYPE = S.SCHEDULE_TYPE AND A.GATE_WINDOW_ID = S.GATE_WINDOW_ID)
    WHEN MATCHED THEN
      UPDATE
      SET S.PSE_ID = v_PSE_ID,
        S.RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
        S.SCHEDULE_QUANTITY = v_XML.SCHEDULE_QUANTITY,
        S.MAXIMUM_AVAILABILITY = v_XML.MAXIMUM_AVAILABILITY,
        S.MINIMUM_GENERATION = v_XML.MINIMUM_GENERATION,
        S.MINIMUM_OUTPUT = v_XML.MINIMUM_OUTPUT,
        S.ACTUAL_AVAILABILITY = v_XML.ACTUAL_AVAILABILITY,
        S.EX_ANTE_EVENT_ID = v_EX_ANTE_EVENT_ID,
        S.INDICATIVE_EVENT_ID = v_INDICATIVE_EVENT_ID,
        S.INITIAL_EVENT_ID = v_INITIAL_EVENT_ID
    WHEN NOT MATCHED THEN
      INSERT
        (SCHEDULE_DATE,
         POD_ID,
         SCHEDULE_TYPE,
         GATE_WINDOW_ID,
         PSE_ID,
         RESOURCE_TYPE,
         SCHEDULE_QUANTITY,
         MAXIMUM_AVAILABILITY,
         MINIMUM_GENERATION,
         MINIMUM_OUTPUT,
         ACTUAL_AVAILABILITY,
         EX_ANTE_EVENT_ID,
         INDICATIVE_EVENT_ID,
         INITIAL_EVENT_ID)
      VALUES
        (v_SCHEDULE_DATE,
         v_POD_ID,
         v_SCHEDULE_TYPE,
         v_GATE_WINDOW_ID,
         v_PSE_ID,
         v_XML.RESOURCE_TYPE,
         v_XML.SCHEDULE_QUANTITY,
         v_XML.MAXIMUM_AVAILABILITY,
         v_XML.MINIMUM_GENERATION,
         v_XML.MINIMUM_OUTPUT,
         v_XML.ACTUAL_AVAILABILITY,
         v_EX_ANTE_EVENT_ID,
         v_INDICATIVE_EVENT_ID,
         v_INITIAL_EVENT_ID);

    v_RECORD_COUNT := v_RECORD_COUNT + 1;
  END LOOP;
  p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END IMPORT_MKT_SCHED_DETAIL_PUB;
--------------------------------------------------------------------------------------------
--this imports the Active MPUnits report
PROCEDURE IMPORT_UNITS
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_XML    XMLTYPE;
    v_POD_ID NUMBER(9);
    v_PSE_ID NUMBER(9);
  v_RPT_DATE DATE;
  v_ESP_ID NUMBER(9);
  -- note that unlike other reports with a resource, the PUB_ActiveMPUnits
  -- has always specified RESOURCE_NAME. So this is the one report that isn't
  -- affected by the RESOURCE_ID/RESOURCE_NAME switch in MPUD5.
    CURSOR C_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_ORGANIZATION_ELEMENT) "PARTICIPANT_NAME",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') "RESOURCE_NAME",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') "RESOURCE_TYPE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EFFECTIVE_DATE'),
                       'DD/MM/YYYY') "EFFECTIVE_DATE",
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/EXPIRATION_DATE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EXPIRATION_DATE'),
                            'DD/MM/YYYY')
               END "EXPIRATION_DATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;


BEGIN
    v_XML                  := XMLTYPE.CREATEXML(p_REPORT);
    p_LOGGER.EXCHANGE_NAME := 'Import Active MP Units report';

  -- grab the REPORT DATE from the head of XML
    SELECT TRUNC(TO_DATE(EXTRACTVALUE(v_XML,
                        'REPORT/REPORT_HEADER/HEADROW/RPT_DATE'), 'DD/MM/YYYY HH24:MI:SS'))
    INTO v_RPT_DATE
    FROM DUAL;

    FOR v_XML IN c_XML LOOP

          --get PSE_ID
        -- 2007-jul-25, jbc: first param GET_PSE_ID expects is ID, not name
    --v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE, v_XML.PARTICIPANT_NAME);


    IF (v_XML.RESOURCE_TYPE = 'SU' AND GUI_UTIL.IS_EXTERNAL_SYSTEM_ENABLED(EC.ES_TDIE) = 1) THEN
      -- get esp id
      v_ESP_ID := MM_SEM_UTIL.GET_ESP_ID(v_XML.RESOURCE_NAME, TRUE);

      --update/insert ESP_PSE table
      UT.PUT_TEMPORAL_DATA(p_TABLE_NAME => 'PSE_ESP',
                 p_BEGIN_DATE => v_RPT_DATE,
                 p_END_DATE => NULL,
                 p_NULL_END_IS_HIGH_DATE => TRUE,
                 p_UPDATE_ENTRY_DATE => TRUE,
                 p_COL_NAME1 => 'PSE_ID',
                 p_COL_VALUE1 => UT.GET_LITERAL_FOR_NUMBER(v_PSE_ID),
                 p_COL_IS_KEY1 => FALSE,
                 p_COL_NAME2 => 'ESP_ID',
                 p_COL_VALUE2 =>  UT.GET_LITERAL_FOR_NUMBER(v_ESP_ID),
                 p_COL_IS_KEY2 => TRUE);
    END IF;

    --get POD_ID
      v_POD_ID := CREATE_SERVICE_POINT(v_XML.RESOURCE_NAME,
                   v_XML.RESOURCE_TYPE,
                   v_XML.EFFECTIVE_DATE,
                   v_XML.EXPIRATION_DATE,
                   p_LOGGER,
                   'Import Active MP Units');
    --update/insert SEM_SERVICE_POINT_PSE table
    UT.PUT_TEMPORAL_DATA(p_TABLE_NAME => 'SEM_SERVICE_POINT_PSE',
               p_BEGIN_DATE => v_RPT_DATE,
               p_END_DATE => NULL,
               p_NULL_END_IS_HIGH_DATE => TRUE,
               p_UPDATE_ENTRY_DATE => TRUE,
               p_COL_NAME1 => 'PSE_ID',
               p_COL_VALUE1 => UT.GET_LITERAL_FOR_NUMBER(v_PSE_ID),
               p_COL_IS_KEY1 => FALSE,
               p_COL_NAME2 => 'POD_ID',
               p_COL_VALUE2 =>  UT.GET_LITERAL_FOR_NUMBER(v_POD_ID),
               p_COL_IS_KEY2 => TRUE);

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Active MP Units report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_UNITS;
--------------------------------------------------------------------------------------------------------
--this imports the Active Units report
PROCEDURE IMPORT_JUST_UNITS
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_XML    XMLTYPE;
    v_POD_ID NUMBER(9);
     v_RPT_DATE DATE;

  -- OK, I was wrong - the PUB_ActiveUnits report also always used RESOURCE_NAME,
  -- even in MPUD4.4. Now, I will say, MPUD 4.4 actually specifies the report as using
  -- REPORT_ID, but the reports that came out of market trials have REPORT_NAME. The
  -- cover note for the MPUD5 changes makes a tacit admission in this regard.
    CURSOR C_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') "RESOURCE_NAME",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') "RESOURCE_TYPE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EFFECTIVE_DATE'),
                       'DD/MM/YYYY') "EFFECTIVE_DATE",
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/EXPIRATION_DATE')
                   WHEN '-' THEN
                    NULL
                   ELSE
                    TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EXPIRATION_DATE'),
                            'DD/MM/YYYY')
               END "EXPIRATION_DATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    v_XML                  := XMLTYPE.CREATEXML(p_REPORT);
    p_LOGGER.EXCHANGE_NAME := 'Import Active Units report';

  -- grab the REPORT DATE from the head of XML
    SELECT TRUNC(TO_DATE(EXTRACTVALUE(v_XML,
                        'REPORT/REPORT_HEADER/HEADROW/RPT_DATE'), 'DD/MM/YYYY HH24:MI:SS'))
    INTO v_RPT_DATE
    FROM DUAL;

    FOR v_XML IN c_XML LOOP
       --get POD_ID
        v_POD_ID := CREATE_SERVICE_POINT(v_XML.RESOURCE_NAME,
                                         v_XML.RESOURCE_TYPE,
                                         v_XML.EFFECTIVE_DATE,
                                         v_XML.EXPIRATION_DATE,
                                         p_LOGGER,
                     'Import Active Units');
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Active Units report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_JUST_UNITS;
------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOAD_FORECAST
(
    p_REPORT       IN CLOB,
    p_PERIODICITY  IN VARCHAR2,     --YEARLY, MONTHLY, DAILY, DS, DA, DNWA, D1-ES, D4-ES, D15-ES
    p_LOGGER       IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_SCHEDULE_DATE DATE;
    v_EXCHANGE_NAME VARCHAR2(64);
    v_XML_REP       XMLTYPE;
    v_PUBLISHED_TRADE_DATE DATE;
    v_PERIODICITY_FLAG VARCHAR2(8);
    v_PERIODICITY      VARCHAR2(6);

  v_RECORD_COUNT  NUMBER(9) := 0;

    --Monthly / Daily files have FORECAST_MW field
    --Annualy file has LOAD_FORECAST field
    --Daily Load Forecast Summary has FORECAST_MW and NET_LOAD_FORECAST
    --Daily Actual Load Summary has ACTUAL_LOAD_MW

    CURSOR c_XML IS
        SELECT
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'),
                       'DD/MM/YYYY') TRADE_DATE,
               CASE WHEN EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') IS NULL THEN 'AGG' ELSE TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION')) END "JURISDICTION",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               CASE v_PERIODICITY_FLAG
                   WHEN 'Y' THEN      -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOAD_FORECAST')
                   WHEN 'DA' THEN
                    EXTRACTVALUE(VALUE(T), '//DATAROW/ACTUAL_LOAD_MW')
                   WHEN 'D1-ES' THEN
                     EXTRACTVALUE(VALUE(T), '//DATAROW/JESU_MW')
                   WHEN 'D4-ES' THEN
                     EXTRACTVALUE(VALUE(T), '//DATAROW/JESU_MW')
           WHEN 'D15-ES' THEN
                     EXTRACTVALUE(VALUE(T), CASE WHEN g_REPORT_NAME = 'PUB_D_JurisdictionErrorSupplyD15' THEN '//DATAROW/JESU_MW'
                                                WHEN g_REPORT_NAME = 'PUB_D_ResidualErrorVolumeD15' THEN '//DATAROW/REVLF_MWH' END)
                   ELSE
                     EXTRACTVALUE(VALUE(T), '//DATAROW/FORECAST_MW')
               END "LOAD_MW",
               CASE v_PERIODICITY_FLAG
                 WHEN 'DA' THEN
                  NULL
                WHEN 'D1-ES' THEN
                  NULL
                WHEN 'D4-ES' THEN
                  NULL
        WHEN 'D15-ES' THEN
                  NULL
                ELSE
                  EXTRACTVALUE(VALUE(T), '//DATAROW/ASSUMPTIONS')
               END AS "ASSUMPTIONS",
               CASE v_PERIODICITY_FLAG
                 WHEN 'DS' THEN
                  EXTRACTVALUE(VALUE(T), '//DATAROW/NET_LOAD_FORECAST')
                ELSE
                  NULL
               END AS "NET_MW",
               CASE v_PERIODICITY_FLAG
                 WHEN 'DA' THEN
                  EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE')
                ELSE
                  NULL
               END AS "RUN_TYPE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;


BEGIN
    v_XML_REP       := XMLTYPE.CREATEXML(p_REPORT);


    IF UPPER(p_PERIODICITY) IN ('DA','DS','DNWA', 'D1-ES', 'D4-ES', 'D15-ES') THEN
      v_PERIODICITY_FLAG := UPPER(p_PERIODICITY); --DS / DA   'Daily Load Forecast Summary' / Daily Actual Load Summary'
    ELSE
      v_PERIODICITY_FLAG := UPPER(SUBSTR(p_PERIODICITY, 1, 1)); --Y / M / D
    END IF;

    -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
    SELECT TO_DATE(extractValue(VALUE(T), '//TRADE_DATE'), 'YYYYMMDD')
    INTO v_PUBLISHED_TRADE_DATE
    FROM TABLE(xmlSequence(extract(v_XML_REP, '/REPORT/REPORT_HEADER/HEADROW[@num="1"]'))) T;

    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

    IF v_PERIODICITY_FLAG = 'Y' THEN
       v_PERIODICITY := 'A'; -- convert 'yearly' to 'annual'
    ELSE
       v_PERIODICITY := v_PERIODICITY_FLAG; -- M / D / DS / DA
    END IF;

    FOR v_XML IN c_XML LOOP
        IF v_PERIODICITY_FLAG = 'D' THEN
           -- RSA -- 04/24/2007 -- (D+1)-(D+4) fix
           IF (v_XML.TRADE_DATE - v_PUBLISHED_TRADE_DATE + 1) > 4 THEN
              MM_SEM_UTIL.RAISE_ERR(20000, 'XML File has information for days > (D+4). Probably invalid file data.');
           END IF;

           v_PERIODICITY := v_PERIODICITY_FLAG || TO_CHAR(v_XML.TRADE_DATE - v_PUBLISHED_TRADE_DATE + 1);
        ELSIF v_PERIODICITY_FLAG = 'DA' THEN
          v_PERIODICITY := v_PERIODICITY_FLAG || '-' || v_XML.RUN_TYPE;
        END IF;

        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);
    -- 6-sep-2007, jbc: for rolling 4-day forecast, offset schedule date back to publish date
    IF v_PERIODICITY_FLAG = 'D' THEN
      v_SCHEDULE_DATE := v_SCHEDULE_DATE - v_XML.TRADE_DATE + v_PUBLISHED_TRADE_DATE;
    END IF;

      UPDATE SEM_LOAD
         SET EVENT_ID = p_LOGGER.LAST_EVENT_ID,
             LOAD_MW = v_XML.LOAD_MW,
             NET_MW = v_XML.NET_MW,
             ASSUMPTIONS = v_XML.ASSUMPTIONS
       WHERE PERIODICITY   = v_PERIODICITY
         AND SCHEDULE_DATE = v_SCHEDULE_DATE
         AND JURISDICTION  = v_XML.JURISDICTION
         AND REPORT_NAME   = g_REPORT_NAME;

        IF SQL%NOTFOUND THEN
            INSERT INTO SEM_LOAD
                (EVENT_ID,
                 PERIODICITY,
                 SCHEDULE_DATE,
                 JURISDICTION,
                 LOAD_MW,
                 NET_MW,
                 ASSUMPTIONS,
                 REPORT_NAME)
            VALUES
                (p_LOGGER.LAST_EVENT_ID,
                 v_PERIODICITY,
                 v_SCHEDULE_DATE,
                 v_XML.JURISDICTION,
                 v_XML.LOAD_MW,
                 v_XML.NET_MW,
                 v_XML.ASSUMPTIONS,
                 g_REPORT_NAME);
        END IF;
    v_RECORD_COUNT := v_RECORD_COUNT + 1;
  END LOOP;
  p_LOGGER.LOG_INFO('Imported record count: ' || v_RECORD_COUNT);
  COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || v_EXCHANGE_NAME || ': ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_LOAD_FORECAST;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSS_FACTOR
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_SCHEDULE_DATE DATE;
    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_XML_REP       XMLTYPE;
    v_ROW_NUM       NUMBER;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/@num') "ROW_NUM",
              EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/LOSS_FACTOR') "LOSS_FACTOR"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;



BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Annual Transmission Loss Adjustment Factors report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    FOR v_XML IN c_XML LOOP
        v_ROW_NUM := v_XML.ROW_NUM;
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);
        --get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        UPDATE SEM_LOSS_FACTOR
        SET EVENT_ID = p_LOGGER.LAST_EVENT_ID, LOSS_FACTOR = v_XML.LOSS_FACTOR
        WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
        AND PSE_ID = v_PSE_ID
        AND POD_ID = v_POD_ID;

        IF SQL%NOTFOUND THEN
            --Try insert into SEM_LOSS_FACTOR table
            INSERT INTO SEM_LOSS_FACTOR
                (EVENT_ID, PSE_ID, POD_ID, SCHEDULE_DATE, LOSS_FACTOR)
            VALUES
                (p_LOGGER.LAST_EVENT_ID,
                 v_PSE_ID,
                 v_POD_ID,
                 v_SCHEDULE_DATE,
                 v_XML.LOSS_FACTOR);
        END IF;

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Annual Loss Adjustmet Factors' || 'ROW_NUM = ' || v_ROW_NUM || ',' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_LOSS_FACTOR;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IMPERFECTIONS_PRICE
(
    p_CLOB_RESPONSE IN CLOB,
    p_STATUS        OUT NUMBER,
    p_MESSAGE       OUT NUMBER
) AS

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/START_DATE'),
                       'DD/MM/YYYY') "START_DATE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/END_DATE'),
                       'DD/MM/YYYY') "END_DATE",
               EXTRACTVALUE(VALUE(T), '//DATAROW/IMPERFECTIONS_PRICE') "IMPERFECTIONS_PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_CLOB_RESPONSE),
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;


    v_MARKET_PRICE_ID     NUMBER(9);
    v_BEGIN_DATE          DATE;
    v_END_DATE            DATE;
    v_IMPERFECTIONS_PRICE NUMBER;
    v_CURRENT_DATE        DATE;
BEGIN
    p_STATUS := GA.SUCCESS;

    --create the Market Price entity
    v_MARKET_PRICE_ID := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Imperfections Price',
                                                         'Commodity Price',
                                                         'Day',
                                                         TRUE);

    FOR v_XML IN c_XML LOOP
        v_BEGIN_DATE          := v_XML.START_DATE;
        v_END_DATE            := v_XML.END_DATE;
        v_IMPERFECTIONS_PRICE := v_XML.IMPERFECTIONS_PRICE;
    END LOOP;

    --Loop over dates, and expand the value daily between START_DATE and END_DATE
    v_CURRENT_DATE := TRUNC(v_BEGIN_DATE);
    LOOP
        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID,
                                       v_CURRENT_DATE,
                                       'A',
                                       v_IMPERFECTIONS_PRICE,
                                       0,
                                       p_STATUS,
                                       p_MESSAGE);
        EXIT WHEN(v_CURRENT_DATE >= TRUNC(v_END_DATE));
        v_CURRENT_DATE := v_CURRENT_DATE + 1;
    END LOOP;


EXCEPTION
    WHEN OTHERS THEN
        P_STATUS  := SQLCODE;
        p_MESSAGE := PACKAGE_NAME || '.IMPORT_IMPERFECTIONS_PRICE: ' || SQLERRM;

END IMPORT_IMPERFECTIONS_PRICE;
------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MARKET_PRICE_PARAM
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_MKT_PRICE_ID_FLOOR_E  NUMBER(9);
    v_MKT_PRICE_ID_FLOOR_P  NUMBER(9);
    v_MKT_PRICE_ID_CAP_E    NUMBER(9);
    v_MKT_PRICE_ID_CAP_P    NUMBER(9);
    v_XML_BEGIN_DATE        DATE;
    v_XML_END_DATE          DATE;
    v_PRICE_BEGIN_DATE      DATE;
    v_PRICE_END_DATE        DATE;
    v_BEGIN_DATE            DATE;
    v_END_DATE              DATE;
    v_PRICE_FLOOR_E         NUMBER;
    v_PRICE_FLOOR_P         NUMBER;
    v_PRICE_CAP_E           NUMBER;
    v_PRICE_CAP_P           NUMBER;
    v_CURRENT_DATE          DATE;
    v_STATUS                NUMBER;
    v_MESSAGE               VARCHAR2(512);
    v_XML_REP               XMLTYPE;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/PARAMETER_NAME') "PARAMETER_NAME",
               EXTRACTVALUE(VALUE(T), '//DATAROW/PARAMETER_VALUE') "PARAMETER_VALUE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/START_DATE'),
                       'DD/MM/YYYY') "START_DATE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/END_DATE'),
                       'DD/MM/YYYY') "END_DATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;



BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Annual Market Price Parameters report';
    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);

    --create the Market Price entities
    v_MKT_PRICE_ID_FLOOR_E := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Market Price Floor Euro',
                                                               'Commodity Price',
                                                               'Day',
                                                               TRUE);
    v_MKT_PRICE_ID_FLOOR_P := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Market Price Floor Pound',
                                                               'Commodity Price',
                                                               'Day',
                                                               TRUE);
    v_MKT_PRICE_ID_CAP_E   := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Market Price Cap Euro',
                                                               'Commodity Price',
                                                               'Day',
                                                               TRUE);
    v_MKT_PRICE_ID_CAP_P   := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Market Price Cap Pound',
                                                               'Commodity Price',
                                                               'Day',
                                                               TRUE);

     --Calculate the begin date and end date for current year
     v_PRICE_BEGIN_DATE := TRUNC(SYSDATE, 'Y'); --begin of current year
     v_PRICE_END_DATE := ADD_MONTHS(v_PRICE_BEGIN_DATE, 12)-1; --end of current year

    --Collect all four market prices (MARKET_PRICE_CAP_EURO, MARKET_PRICE_CAP_POUND,
    -- MARKET_PRICE_FLOOR_EURO, MARKET_PRICE_FLOOR_POUND)
    FOR v_XML IN c_XML LOOP
        IF v_XML.PARAMETER_NAME = g_SEM_MKT_PRICE_CAP_E THEN
            v_PRICE_CAP_E := v_XML.PARAMETER_VALUE;
        ELSIF v_XML.PARAMETER_NAME = g_SEM_MKT_PRICE_CAP_P THEN
            v_PRICE_CAP_P := v_XML.PARAMETER_VALUE;
        ELSIF v_XML.PARAMETER_NAME = g_SEM_MKT_PRICE_FLOOR_E THEN
            v_PRICE_FLOOR_E := v_XML.PARAMETER_VALUE;
        ELSIF v_XML.PARAMETER_NAME = g_SEM_MKT_PRICE_FLOOR_P THEN
            v_PRICE_FLOOR_P := v_XML.PARAMETER_VALUE;
        END IF;
        --the market price begin_date and end_date should not change over the year
        --get the dates for the last market price and apply them for all foru market prices
        v_XML_BEGIN_DATE := v_XML.START_DATE;
        v_XML_END_DATE   := v_XML.END_DATE;
    END LOOP;

    --try to norrow down just for current year
    IF v_XML_BEGIN_DATE < v_PRICE_BEGIN_DATE THEN
      v_BEGIN_DATE := v_PRICE_BEGIN_DATE;
    ELSE
      v_BEGIN_DATE := v_XML_BEGIN_DATE;
    END IF;
    IF v_XML_END_DATE > v_PRICE_END_DATE THEN
      v_END_DATE := v_PRICE_END_DATE;
    ELSE
      v_END_DATE := v_XML_BEGIN_DATE;
    END IF;

    --Loop over dates for current year, and expand the value daily between START_DATE and END_DATE
    v_CURRENT_DATE := TRUNC(v_BEGIN_DATE);
    LOOP
        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_MKT_PRICE_ID_CAP_E,
                                       v_CURRENT_DATE,
                                       'A',
                                       v_PRICE_CAP_E,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);

        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_MKT_PRICE_ID_CAP_P,
                                       v_CURRENT_DATE,
                                       'A',
                                       v_PRICE_CAP_P,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);

         MM_UTIL.PUT_MARKET_PRICE_VALUE(v_MKT_PRICE_ID_FLOOR_P,
                                       v_CURRENT_DATE,
                                       'A',
                                       v_PRICE_FLOOR_P,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);

          MM_UTIL.PUT_MARKET_PRICE_VALUE(v_MKT_PRICE_ID_FLOOR_E,
                                       v_CURRENT_DATE,
                                       'A',
                                       v_PRICE_FLOOR_E,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);

        EXIT WHEN(v_CURRENT_DATE >= TRUNC(v_END_DATE));
        v_CURRENT_DATE := v_CURRENT_DATE + 1;
    END LOOP;


EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Annual Market Price Parameters report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_MARKET_PRICE_PARAM;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MKT_SCHED_SUMM_AS_TXN
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_XML_REP XMLTYPE;
    v_EFFECTIVE_RUN_TYPE VARCHAR2(8);
    v_TXN_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_SCHEDULE_TYPE_ID STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report as transactions.';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    -- Effective Run Type is applicable for pre-IDT reports
    CASE g_REPORT_NAME
        WHEN 'PUB_D_ExAnteMktSchSummary'
        THEN  v_EFFECTIVE_RUN_TYPE := NVL(CASE g_RUN_TYPE
                                        WHEN MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR
                                        THEN MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA
                                        ELSE g_RUN_TYPE END, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA);
        -- TODO: Ex-Post and Initial Ex-Post to be handled later
        ELSE RETURN;
    END CASE;

    --System Marginal Price Euro
    v_SCHEDULE_TYPE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(v_EFFECTIVE_RUN_TYPE,
                                                           EC.ED_STATEMENT_TYPE,
                                                           EC.ES_SEM,
                                                           MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
    IF v_SCHEDULE_TYPE_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the resolve Statement for Run Type:' || g_RUN_TYPE || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;

    v_TXN_ID := EI.GET_ID_FROM_IDENTIFIER(MM_SEM_UTIL.c_TXN_NAME_SMP_EUR, EC.ED_TRANSACTION);

    IF v_TXN_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the transaction - ' || MM_SEM_UTIL.c_TXN_NAME_SMP_EUR || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;

    MERGE INTO IT_SCHEDULE S
    USING (SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'E') E
    ON (S.TRANSACTION_ID = v_TXN_ID
       AND S.SCHEDULE_TYPE = v_SCHEDULE_TYPE_ID
       AND S.SCHEDULE_STATE = CONSTANTS.INTERNAL_STATE
       AND S.SCHEDULE_DATE = MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL)
       AND S.AS_OF_DATE = CONSTANTS.LOW_DATE)
    WHEN MATCHED THEN
       UPDATE SET S.AMOUNT = E.SMP
    WHEN NOT MATCHED THEN
        INSERT (TRANSACTION_ID,
           SCHEDULE_TYPE,
           SCHEDULE_STATE,
           SCHEDULE_DATE,
           AS_OF_DATE,
           AMOUNT)
        VALUES (v_TXN_ID,
           v_SCHEDULE_TYPE_ID,
           CONSTANTS.INTERNAL_STATE,
           MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL),
           CONSTANTS.LOW_DATE,
           E.SMP);

    --System Marginal Price GBP
    v_SCHEDULE_TYPE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(NVL(g_RUN_TYPE, v_EFFECTIVE_RUN_TYPE), EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
    IF v_SCHEDULE_TYPE_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the resolve Statement for Run Type:' || g_RUN_TYPE || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;

    v_TXN_ID := EI.GET_ID_FROM_IDENTIFIER(MM_SEM_UTIL.c_TXN_NAME_SMP_GBP, EC.ED_TRANSACTION);

    -- TODO: We do not need to search this way
    IF v_TXN_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the transaction - ' || MM_SEM_UTIL.c_TXN_NAME_SMP_GBP || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;


    MERGE INTO IT_SCHEDULE S
    USING (SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P') E
    ON (S.TRANSACTION_ID = v_TXN_ID
       AND S.SCHEDULE_TYPE = v_SCHEDULE_TYPE_ID
       AND S.SCHEDULE_STATE = CONSTANTS.INTERNAL_STATE
       AND S.SCHEDULE_DATE = MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL)
       AND S.AS_OF_DATE = CONSTANTS.LOW_DATE)
    WHEN MATCHED THEN
       UPDATE SET S.AMOUNT = E.SMP
    WHEN NOT MATCHED THEN
        INSERT (TRANSACTION_ID,
           SCHEDULE_TYPE,
           SCHEDULE_STATE,
           SCHEDULE_DATE,
           AS_OF_DATE,
           AMOUNT)
        VALUES (v_TXN_ID,
           v_SCHEDULE_TYPE_ID,
           CONSTANTS.INTERNAL_STATE,
           MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL),
           CONSTANTS.LOW_DATE,
           E.SMP);

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ' report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_MKT_SCHED_SUMM_AS_TXN;
------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MKT_SCHED_SUMMARY
(
    p_REPORT   IN CLOB,
    p_IMPORT_PARAM IN VARCHAR2,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER

) AS

    v_SCHEDULE_DATE          DATE;
    v_TXN_ID                 NUMBER(9);
    v_XML_REP                xmltype;
    v_STATUS                 NUMBER;
    v_SCHEDULE_TYPE_ID       NUMBER(9);
    v_SCHED_IDS              NUMBER_COLLECTION;
    v_EXTID_MKT_SCHED        EXTERNAL_SYSTEM_IDENTIFIER.EXTERNAL_IDENTIFIER%TYPE;
    v_SMP_PRICE_ID_EURO      NUMBER(9);
    v_SMP_PRICE_ID_POUND     NUMBER(9);
  v_EXANTE_SMP_PRICE_ID_EURO  NUMBER(9);
    v_EXANTE_SMP_PRICE_ID_POUND NUMBER(9);
  v_FILL_SETTLEMENT_SMP    BOOLEAN := FALSE;
    v_MESSAGE                VARCHAR2(512);
    v_EFFECTIVE_RUN_TYPE     STATEMENT_TYPE.STATEMENT_TYPE_NAME%TYPE;

    --ignore the prices that appear in the market schedule report
    --and get just the MW values . Filter either Pounds or Euro (the MW values are the same)
    -- LD -- 09/13/2007 - per MPUD v4.3 all three XML versions of this report (Ex-Ante, Indicative Ex-Post, Initial Ex-Post)
  --                    have the same field name for the schedule quantity values - AGGREGATED_MSQ.
  --                    So no need anymore to have separate cursors for it
  -- LD -- 06/27/2008 - Import the ex-ante SMP into two new market prices, "SEM:Ex-Ante System Marginal Price Euro" and "SEM:Ex-Ante System Marginal Price Pound";
  --                    Save the price values into all three price types (A, F, P).
  --                    Make the import of ex-ante SMP into the "standard" SMP be data-driven (BZ 16234)
    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/AGGREGATED_MSQ') "AGGREGATED_MSQ"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P';

    -- Cursor for Ex-Ante XML file for SMP in Pound
    CURSOR c_EA_POUND_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "POUND_SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P';

    -- Cursor for Ex-Ante XML file for SMP in Euro
    CURSOR c_EA_EURO_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "EURO_SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'E';

BEGIN

    p_LOGGER.EXCHANGE_NAME := 'Import ' || p_IMPORT_PARAM ||
                              ' Market Schedule Summary report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);
    v_EXTID_MKT_SCHED      := UPPER(p_IMPORT_PARAM);

    --get the id for schedule ids for each statement type external sytem ident
    IF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA) THEN
        v_EFFECTIVE_RUN_TYPE := NVL(CASE g_RUN_TYPE
                                        WHEN MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR
                                        THEN MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA
                                        ELSE g_RUN_TYPE END, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA);
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(v_EFFECTIVE_RUN_TYPE,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);

    ELSIF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INDIC_EP) THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INDIC_EP,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);


    ELSIF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INIT_EP) THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INIT_EP,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);
    END IF;

    --get Transaction ID
    v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(p_TRANSACTION_TYPE    => 'Market Results',
                                               p_RESOURCE_NAME       => NULL,
                                               p_CREATE_IF_NOT_FOUND => TRUE,
                                               p_TRANSACTION_NAME    => 'SEM-Market Schedule Summary',
                                               p_EXTERNAL_IDENTIFIER => NULL);

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);


        FOR I IN 1 .. v_SCHED_IDS.COUNT LOOP
            v_SCHEDULE_TYPE_ID := v_SCHED_IDS(I);
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID,
                                p_SCHEDULE_TYPE  => v_SCHEDULE_TYPE_ID,
                                p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                                p_AS_OF_DATE     => LOW_DATE,
                                p_AMOUNT         => v_XML.AGGREGATED_MSQ,
                                p_PRICE          => NULL,
                                p_STATUS         => v_STATUS);
        END LOOP;
    END LOOP;


    IF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA) THEN

      --get/create the Market Price entities
      v_EXANTE_SMP_PRICE_ID_EURO  := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Ex-Ante System Marginal Price Euro',
                                                              'Commodity Price',
                                                              '30 Minute',
                                                              TRUE);
      v_EXANTE_SMP_PRICE_ID_POUND := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Ex-Ante System Marginal Price Pound',
                                                              'Commodity Price',
                                                              '30 Minute',
                                                              TRUE);

    v_SMP_PRICE_ID_EURO  := MM_SEM_UTIL.GET_MARKET_PRICE_ID('System Marginal Price Euro',
                                                              'Commodity Price',
                                                              '30 Minute',
                                                              TRUE);
      v_SMP_PRICE_ID_POUND := MM_SEM_UTIL.GET_MARKET_PRICE_ID('System Marginal Price Pound',
                                                              'Commodity Price',
                                                              '30 Minute',
                                                              TRUE);
    --Populate the standard SMP if we do not have this setting
     v_FILL_SETTLEMENT_SMP := TO_NUMBER(NVL(GET_DICTIONARY_VALUE('UseExAnteSMPForInternalSMP',
                                                                 0,
                                   'MarketExchange',
                                   'SEM'),
                        1)) = 1;

      -- Process the Ex-Ante Market Schedule Summary XML file for SMP in Pounds
      FOR v_XML IN c_EA_POUND_XML LOOP
          --calculate the SCHEDULE_DATE
          v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                           v_XML.DELIVERY_HOUR,
                                                           v_XML.DELIVERY_INTERVAL);

    -- always populate 'A' price types for price "SEM:Ex-Ante System Marginal Price Pound"
    MM_UTIL.PUT_MARKET_PRICE_VALUE(v_EXANTE_SMP_PRICE_ID_POUND,
                   v_SCHEDULE_DATE,
                   'A',
                   v_XML.POUND_SMP,
                   0,
                   v_STATUS,
                   v_MESSAGE);

          -- The import of ex-ante SMP into the "standard" SMP is data driven;
      -- populate forecast price type only for price "SEM:System Marginal Price Pound"
      IF v_FILL_SETTLEMENT_SMP THEN
            MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_POUND,
                                         v_SCHEDULE_DATE,
                                         'F',
                                         v_XML.POUND_SMP,
                                         0,
                                         v_STATUS,
                                         v_MESSAGE);
      END IF;
      END LOOP;

      -- Process the Ex-Ante Market Schedule Summary XML file for SMP in Euros
      FOR v_XML IN c_EA_EURO_XML LOOP
          --calculate the SCHEDULE_DATE
          v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                           v_XML.DELIVERY_HOUR,
                                                           v_XML.DELIVERY_INTERVAL);

    -- always populate 'A' price types for price "SEM:Ex-Ante System Marginal Price Euro"
    MM_UTIL.PUT_MARKET_PRICE_VALUE(v_EXANTE_SMP_PRICE_ID_EURO,
                   v_SCHEDULE_DATE,
                   'A',
                   v_XML.EURO_SMP,
                   0,
                   v_STATUS,
                   v_MESSAGE);

          -- The import of ex-ante SMP into the "standard" SMP is data driven;
      -- populate forecast price type only for price "SEM:System Marginal Price Euro"
      IF v_FILL_SETTLEMENT_SMP THEN
            MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_EURO,
                                         v_SCHEDULE_DATE,
                                         'F',
                                         v_XML.EURO_SMP,
                                         0,
                                         v_STATUS,
                                         v_MESSAGE);
      END IF;
      END LOOP;
    END IF;

    IMPORT_MKT_SCHED_SUMM_AS_TXN(p_REPORT, p_LOGGER);

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || p_IMPORT_PARAM ||
                           ' Market Schedule Summary report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_MKT_SCHED_SUMMARY;
------------------------------------------------------------------------------------------
PROCEDURE IMPORT_GEN_FORECAST
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_SCHEDULE_DATE DATE;
    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_XML_REP       XMLTYPE;

    -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
    v_PUBLISHED_TRADE_DATE DATE;
    v_PERIODICITY  VARCHAR2(2);
    v_PERIODICITY_FLAG VARCHAR2(1) := 'D'; -- For Wind Fcst Assumptions it will always be 'D' - Daily

    CURSOR c_XML IS
        SELECT
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'),
                       'DD/MM/YYYY') TRADE_DATE,                      -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') "JURISDICTION",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/FORECAST_MW') "FORECAST_MW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/ASSUMPTIONS') "ASSUMPTIONS"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;



BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Rolling Wind Forecast ' || CONSTANTS.AMPERSAND || ' Assumptions report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
    SELECT TO_DATE(extractValue(VALUE(T), '//TRADE_DATE'), 'YYYYMMDD')
    INTO v_PUBLISHED_TRADE_DATE
    FROM TABLE(xmlSequence(extract(v_XML_REP, '/REPORT/REPORT_HEADER/HEADROW[@num="1"]'))) T;


    FOR v_XML IN c_XML LOOP
        -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
        IF TRIM(UPPER(v_PERIODICITY_FLAG)) = 'D' THEN
            -- RSA -- 04/24/2007 -- (D+1)-(D+4) fix
            IF (v_XML.TRADE_DATE - v_PUBLISHED_TRADE_DATE + 1) > 4 THEN
               MM_SEM_UTIL.RAISE_ERR(20000, 'XML File has information for days > (D+4). Probably invalid file data.');
            END IF;
           v_PERIODICITY := v_PERIODICITY_FLAG || TO_CHAR(v_XML.TRADE_DATE - v_PUBLISHED_TRADE_DATE + 1);
        END IF;

        --calculate the SCHEDULE_DATE
    -- 6-sep-2007, jbc: adjust schedule date to be relative to published trade date
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL) - v_XML.TRADE_DATE + v_PUBLISHED_TRADE_DATE;
        --get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        UPDATE SEM_GEN_FORECAST
        SET EVENT_ID = p_LOGGER.LAST_EVENT_ID,
            FORECAST_MW = v_XML.FORECAST_MW,
            ASSUMPTIONS = v_XML.ASSUMPTIONS--,
      -- 5-sep-2007, jbc: attempt to undo RSA changes (periodicity should be in where clause, as it's part of the index)
            --PERIODICITY = v_PERIODICITY     -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
        WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
        AND PSE_ID = v_PSE_ID
        AND POD_ID = v_POD_ID
        AND JURISDICTION = v_XML.JURISDICTION
    AND PERIODICITY = v_PERIODICITY;

        IF SQL%NOTFOUND THEN
            INSERT INTO SEM_GEN_FORECAST
                (EVENT_ID,
                 JURISDICTION,
                 PERIODICITY,            -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
                 PSE_ID,
                 POD_ID,
                 SCHEDULE_DATE,
                 FORECAST_MW,
                 ASSUMPTIONS)
            VALUES
                (p_LOGGER.LAST_EVENT_ID,
                 v_XML.JURISDICTION,
                 v_PERIODICITY,         -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
                 v_PSE_ID,
                 v_POD_ID,
                 v_SCHEDULE_DATE,
                 v_XML.FORECAST_MW,
                 v_XML.ASSUMPTIONS);
        END IF;
    END LOOP;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Rolling Wind Forecast ' || CONSTANTS.AMPERSAND || ' Assumptions report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_GEN_FORECAST;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_WIND_FORECAST_BY_JURIS
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;

    -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
    v_PUBLISHED_TRADE_DATE DATE;
    v_PERIODICITY  VARCHAR2(2);
    v_PERIODICITY_FLAG VARCHAR2(1) := 'D'; -- For Wind Fcst Assumptions it will always be 'D' - Daily

    CURSOR c_XML IS
        SELECT
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'),
                       'DD/MM/YYYY') TRADE_DATE,                      -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') "JURISDICTION",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/FORECAST_MW') "FORECAST_MW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/ASSUMPTIONS') "ASSUMPTIONS"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;



BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
    SELECT TO_DATE(extractValue(VALUE(T), '//TRADE_DATE'), 'YYYYMMDD')
    INTO v_PUBLISHED_TRADE_DATE
    FROM TABLE(xmlSequence(extract(v_XML_REP, '/REPORT/REPORT_HEADER/HEADROW[@num="1"]'))) T;


    FOR v_XML IN c_XML LOOP
        -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
        IF TRIM(UPPER(v_PERIODICITY_FLAG)) = 'D' THEN
            -- RSA -- 04/24/2007 -- (D+1)-(D+4) fix
            IF (v_XML.TRADE_DATE - v_PUBLISHED_TRADE_DATE + 1) > 4 THEN
               MM_SEM_UTIL.RAISE_ERR(20000, 'XML File has information for days > (D+4). Probably invalid file data.');
            END IF;
           v_PERIODICITY := v_PERIODICITY_FLAG || TO_CHAR(v_XML.TRADE_DATE - v_PUBLISHED_TRADE_DATE + 1);
        END IF;

        --calculate the SCHEDULE_DATE
    -- 6-sep-2007, jbc: adjust schedule date to be relative to published trade date
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL) - v_XML.TRADE_DATE + v_PUBLISHED_TRADE_DATE;

        UPDATE SEM_GEN_FORECAST_AGG
        SET EVENT_ID = p_LOGGER.LAST_EVENT_ID,
            FORECAST_MW = v_XML.FORECAST_MW,
            ASSUMPTIONS = v_XML.ASSUMPTIONS--,
      -- 5-sep-2007, jbc: attempt to undo RSA changes (periodicity should be in where clause, as it's part of the index)
            --PERIODICITY = v_PERIODICITY     -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
        WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
        AND JURISDICTION = v_XML.JURISDICTION
    AND PERIODICITY = v_PERIODICITY;

        IF SQL%NOTFOUND THEN
            INSERT INTO SEM_GEN_FORECAST_AGG
                (EVENT_ID,
                 JURISDICTION,
                 PERIODICITY,            -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
                 SCHEDULE_DATE,
                 FORECAST_MW,
                 ASSUMPTIONS)
            VALUES
                (p_LOGGER.LAST_EVENT_ID,
                 v_XML.JURISDICTION,
                 v_PERIODICITY,         -- RSA -- 04/20/2007 -- (D+1)-(D+4) fix
                 v_SCHEDULE_DATE,
                 v_XML.FORECAST_MW,
                 v_XML.ASSUMPTIONS);
        END IF;
    END LOOP;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Rolling Wind Forecast ' || CONSTANTS.AMPERSAND || ' Assumptions report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_WIND_FORECAST_BY_JURIS;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_INDIC_SMP
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_PRICE_DATE         DATE;
    v_SMP_PRICE_ID_EURO  NUMBER(9);
    v_SMP_PRICE_ID_POUND NUMBER(9);
    v_STATUS             NUMBER;
    v_MESSAGE            VARCHAR2(512);

    v_XML_REP XMLTYPE;

    --XML file has one more field RUN_TYPE that is not specified in MPUD v20
    --filter down for RUN_TYPE=EA;
    CURSOR c_EURO_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "EURO_SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'E'
        /*AND EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') = 'EA'*/;

    CURSOR c_POUND_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "POUND_SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P'
        /*AND EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') = 'EA'*/;

BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Daily Market Prices report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);


    --get/create the Market Price entities
    v_SMP_PRICE_ID_EURO  := MM_SEM_UTIL.GET_MARKET_PRICE_ID('System Marginal Price Euro',
                                                            'Commodity Price',
                                                            '30 Minute',
                                                            TRUE);
    v_SMP_PRICE_ID_POUND := MM_SEM_UTIL.GET_MARKET_PRICE_ID('System Marginal Price Pound',
                                                            'Commodity Price',
                                                            '30 Minute',
                                                            TRUE);

    --System Marginal Price Euro
    FOR v_XML IN c_EURO_SMP LOOP
        --calculate the SCHEDULE_DATE
        v_PRICE_DATE       := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                      v_XML.DELIVERY_HOUR,
                                                      v_XML.DELIVERY_INTERVAL);
        --v_PRICE_DATE := TO_CUT(v_DATE, MM_SEM_UTIL.g_TZ);

        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_EURO,
                                       v_PRICE_DATE,
                                       'P',
                                       v_XML.EURO_SMP,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);
    END LOOP;

    --System Marginal Price Pound
    FOR v_XML IN c_POUND_SMP LOOP
        --calculate the SCHEDULE_DATE
        v_PRICE_DATE       := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                      v_XML.DELIVERY_HOUR,
                                                      v_XML.DELIVERY_INTERVAL);
        --v_PRICE_DATE := TO_CUT(v_DATE, MM_SEM_UTIL.g_TZ);

        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_POUND,
                                       v_PRICE_DATE,
                                       'P',
                                       v_XML.POUND_SMP,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);
    END LOOP;


EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Indicative Market Prices report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_INDIC_SMP;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_INIT_SMP
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_PRICE_DATE         DATE;
    v_SMP_PRICE_ID_EURO  NUMBER(9);
    v_SMP_PRICE_ID_POUND NUMBER(9);
    v_STATUS             NUMBER;
    v_MESSAGE            VARCHAR2(512);

    v_XML_REP XMLTYPE;

    --no RUN_TYPE field in this XML file (the file is conform MPUD v20

    CURSOR c_EURO_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "EURO_SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'E';


    CURSOR c_POUND_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP') "POUND_SMP"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P';


BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Daily Initial Market Prices report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);


    --get/create the Market Price entities
    v_SMP_PRICE_ID_EURO  := MM_SEM_UTIL.GET_MARKET_PRICE_ID('System Marginal Price Euro',
                                                            'Commodity Price',
                                                            '30 Minute',
                                                            TRUE);
    v_SMP_PRICE_ID_POUND := MM_SEM_UTIL.GET_MARKET_PRICE_ID('System Marginal Price Pound',
                                                            'Commodity Price',
                                                            '30 Minute',
                                                            TRUE);

    --System Marginal Price Euro
    FOR v_XML IN c_EURO_SMP LOOP
        --calculate the SCHEDULE_DATE
        v_PRICE_DATE       := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                      v_XML.DELIVERY_HOUR,
                                                      v_XML.DELIVERY_INTERVAL);
        --v_PRICE_DATE := TO_CUT(v_DATE, MM_SEM_UTIL.g_TZ);

        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_EURO,
                                       v_PRICE_DATE,
                                       'A',
                                       v_XML.EURO_SMP,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);
    END LOOP;

    --System Marginal Price Pound
    FOR v_XML IN c_POUND_SMP LOOP
        --calculate the SCHEDULE_DATE
        v_PRICE_DATE       := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                      v_XML.DELIVERY_HOUR,
                                                      v_XML.DELIVERY_INTERVAL);
        --v_PRICE_DATE := TO_CUT(v_DATE, MM_SEM_UTIL.g_TZ);

        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_POUND,
                                       v_PRICE_DATE,
                                       'A',
                                       v_XML.POUND_SMP,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);
    END LOOP;


EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Initial Market Prices report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_INIT_SMP;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SHADOW_SMP_AS_TXN
(
    p_REPORT IN CLOB,
    p_REPORT_NAME IN VARCHAR2,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_XML_REP               XMLTYPE;
    v_EFFECTIVE_RUN_TYPE    VARCHAR2(8);
    v_TXN_ID                INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_SCHEDULE_TYPE_ID      STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
    c_SHADOW_PRICE_TXN_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE := 'SEM';
BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report as transactions.';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    -- Effective Run Type is applicable for pre-IDT reports
    CASE g_REPORT_NAME
        WHEN 'PUB_D_EAShadowPrices' THEN v_EFFECTIVE_RUN_TYPE := MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR;
        WHEN 'PUB_D_EPIndShadowPrices' THEN v_EFFECTIVE_RUN_TYPE := MM_SEM_UTIL.g_EXTID_MKT_SCHED_IND_ABR;
        WHEN 'PUB_D_EPInitShadowPrices' THEN v_EFFECTIVE_RUN_TYPE := MM_SEM_UTIL.g_EXTID_MKT_SCHED_INI_ABR;
    END CASE;

    v_SCHEDULE_TYPE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(NVL(g_RUN_TYPE, v_EFFECTIVE_RUN_TYPE), EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
    IF v_SCHEDULE_TYPE_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the resolve Statement for Run Type:' || g_RUN_TYPE || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;

    v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(p_TRANSACTION_TYPE       => c_SHADOW_PRICE_TXN_TYPE,
                                               p_CREATE_IF_NOT_FOUND    => FALSE,
                                               p_TRANSACTION_NAME       => MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_EUR,
                                               p_EXTERNAL_IDENTIFIER    => MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_EUR);
    IF v_TXN_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the transaction - ' || MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_EUR || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;

    -- System Marginal Price Euro
    MERGE INTO IT_SCHEDULE S
    USING (SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') AS DELIVERY_DATE,
                  EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') AS DELIVERY_HOUR,
                  EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') AS DELIVERY_INTERVAL,
                  EXTRACTVALUE(VALUE(T), '//DATAROW/SHADOW_PRICE') AS EURO_SMP
             FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
            WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'E') E
       ON (    S.TRANSACTION_ID = v_TXN_ID
           AND S.SCHEDULE_TYPE  = v_SCHEDULE_TYPE_ID
           AND S.SCHEDULE_STATE = CONSTANTS.INTERNAL_STATE
           AND S.SCHEDULE_DATE  = MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL)
           AND S.AS_OF_DATE     = CONSTANTS.LOW_DATE)
    WHEN MATCHED THEN
        UPDATE SET S.AMOUNT = E.EURO_SMP
    WHEN NOT MATCHED THEN
        INSERT (TRANSACTION_ID,
                SCHEDULE_TYPE,
                SCHEDULE_STATE,
                SCHEDULE_DATE,
                AS_OF_DATE,
                AMOUNT)
        VALUES (v_TXN_ID,
                v_SCHEDULE_TYPE_ID,
                CONSTANTS.INTERNAL_STATE,
                MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL),
                CONSTANTS.LOW_DATE,
                E.EURO_SMP);

    v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(p_TRANSACTION_TYPE    => c_SHADOW_PRICE_TXN_TYPE,
                                               p_CREATE_IF_NOT_FOUND => FALSE,
                                               p_TRANSACTION_NAME    => MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_GBP,
                                               p_EXTERNAL_IDENTIFIER => MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_GBP);
    IF v_TXN_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the transaction - ' || MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_GBP || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;

    -- System Marginal Price Pound
    MERGE INTO IT_SCHEDULE S
    USING (SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') AS DELIVERY_DATE,
                  EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') AS DELIVERY_HOUR,
                  EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') AS DELIVERY_INTERVAL,
                  EXTRACTVALUE(VALUE(T), '//DATAROW/SHADOW_PRICE') AS POUND_SMP
             FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
            WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P') E
       ON (    S.TRANSACTION_ID = v_TXN_ID
           AND S.SCHEDULE_TYPE = v_SCHEDULE_TYPE_ID
           AND S.SCHEDULE_STATE = CONSTANTS.INTERNAL_STATE
           AND S.SCHEDULE_DATE = MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL)
           AND S.AS_OF_DATE = CONSTANTS.LOW_DATE)
    WHEN MATCHED THEN
        UPDATE SET S.AMOUNT = E.POUND_SMP
    WHEN NOT MATCHED THEN
        INSERT (TRANSACTION_ID,
                SCHEDULE_TYPE,
                SCHEDULE_STATE,
                SCHEDULE_DATE,
                AS_OF_DATE,
                AMOUNT)
        VALUES (v_TXN_ID,
                v_SCHEDULE_TYPE_ID,
                CONSTANTS.INTERNAL_STATE,
                MM_SEM_UTIL.GET_SCHEDULE_DATE(E.DELIVERY_DATE, E.DELIVERY_HOUR, E.DELIVERY_INTERVAL),
                CONSTANTS.LOW_DATE,
                E.POUND_SMP);
EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ' report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_SHADOW_SMP_AS_TXN;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SHADOW_SMP
(
    p_REPORT IN CLOB,
    p_REPORT_NAME IN VARCHAR2,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_PRICE_DATE         DATE;
    v_SMP_PRICE_ID_EURO  NUMBER(9);
    v_SMP_PRICE_ID_POUND NUMBER(9);
    v_STATUS             NUMBER;
    v_MESSAGE            VARCHAR2(512);

    v_XML_REP XMLTYPE;
  v_PRICE_TYPE MARKET_PRICE.MARKET_PRICE_TYPE%TYPE;

    -- No RUN_TYPE field in this XML file (the file is conform MPUD v20
    CURSOR c_EURO_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SHADOW_PRICE') "EURO_SMP"
          FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'E';

    CURSOR c_POUND_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SHADOW_PRICE') "POUND_SMP"
          FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P';
BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report as Market price.';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

  CASE g_REPORT_NAME
    WHEN 'PUB_D_EAShadowPrices' THEN v_PRICE_TYPE := 'F';
        WHEN 'PUB_D_EAShadowPrices_EA' THEN v_PRICE_TYPE := 'F';
        WHEN 'PUB_D_EAShadowPrices_EA2' THEN v_PRICE_TYPE := 'F';
        WHEN 'PUB_D_EAShadowPrices_WD1' THEN v_PRICE_TYPE := 'F';
    WHEN 'PUB_D_EPIndShadowPrices' THEN v_PRICE_TYPE := 'P';
    WHEN 'PUB_D_EPInitShadowPrices' THEN v_PRICE_TYPE := 'A';
  END CASE;

    p_LOGGER.LOG_INFO('Report Name: ' || g_REPORT_NAME);

    -- Get/create the Market Price entities
    v_SMP_PRICE_ID_EURO  := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Shadow Price Euro',
                                                            'Commodity Price',
                                                            DATE_UTIL.c_NAME_30MIN,
                                                            TRUE);
    v_SMP_PRICE_ID_POUND := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Shadow Price GBP',
                                                            'Commodity Price',
                                                            DATE_UTIL.c_NAME_30MIN,
                                                            TRUE);

    --System Marginal Price Euro
    FOR v_XML IN c_EURO_SMP LOOP
        -- Calculate the SCHEDULE_DATE
        v_PRICE_DATE       := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                      v_XML.DELIVERY_HOUR,
                                                      v_XML.DELIVERY_INTERVAL);
        --v_PRICE_DATE := TO_CUT(v_DATE, MM_SEM_UTIL.g_TZ);

        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_EURO,
                                       v_PRICE_DATE,
                                       v_PRICE_TYPE,
                                       v_XML.EURO_SMP,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);
    END LOOP;

    --System Marginal Price Pound
    FOR v_XML IN c_POUND_SMP LOOP
        -- Calculate the SCHEDULE_DATE
        v_PRICE_DATE       := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                      v_XML.DELIVERY_HOUR,
                                                      v_XML.DELIVERY_INTERVAL);
        --v_PRICE_DATE := TO_CUT(v_DATE, MM_SEM_UTIL.g_TZ);

        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_POUND,
                                       v_PRICE_DATE,
                                       v_PRICE_TYPE,
                                       v_XML.POUND_SMP,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);
    END LOOP;

    IMPORT_SHADOW_SMP_AS_TXN(p_REPORT, p_REPORT_NAME, p_LOGGER);
EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ' report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_SHADOW_SMP;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_AVG_SMP_AS_TXN
(
	p_TRANSACTION_ID 	 IN NUMBER,
	p_STATEMENT_TYPE_ID  IN NUMBER,
	p_SCHEDULE_DATE		 IN DATE,
	p_PRICE_VALUE		 IN NUMBER,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_XML_REP               XMLTYPE;
    c_SHADOW_PRICE_TXN_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE := 'SEM';
BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report as transactions.';

    IF p_TRANSACTION_ID IS NULL THEN
      p_LOGGER.LOG_ERROR('Unable to find the transaction - ' || MM_SEM_UTIL.c_TXN_NAME_SHADOW_PRICE_EUR || ' when importing ' || g_REPORT_NAME || ' report.');
      RETURN;
    END IF;

    -- System Marginal Price Euro
    MERGE INTO IT_SCHEDULE S
    USING (SELECT 	p_TRANSACTION_ID	AS TRANSACTION_ID,
					p_STATEMENT_TYPE_ID AS SCHEDULE_TYPE,
					p_SCHEDULE_DATE 	AS SCHEDULE_DATE,
                  	p_PRICE_VALUE		AS PRICE_VALUE
		   FROM DUAL) A
       ON (    S.TRANSACTION_ID = A.TRANSACTION_ID
           AND S.SCHEDULE_TYPE  = A.SCHEDULE_TYPE
           AND S.SCHEDULE_STATE = CONSTANTS.INTERNAL_STATE
           AND S.SCHEDULE_DATE  = A.SCHEDULE_DATE
           AND S.AS_OF_DATE     = CONSTANTS.LOW_DATE)
    WHEN MATCHED THEN
        UPDATE SET S.AMOUNT = A.PRICE_VALUE
    WHEN NOT MATCHED THEN
        INSERT (TRANSACTION_ID,
                SCHEDULE_TYPE,
                SCHEDULE_STATE,
                SCHEDULE_DATE,
                AS_OF_DATE,
                AMOUNT)
        VALUES (A.TRANSACTION_ID,
                A.SCHEDULE_TYPE,
                CONSTANTS.INTERNAL_STATE,
                A.SCHEDULE_DATE,
                CONSTANTS.LOW_DATE,
                A.PRICE_VALUE);
EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ' report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_AVG_SMP_AS_TXN;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_AVG_SMP
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_SMP_PRICE_ID_EURO  NUMBER(9);
    v_SMP_PRICE_ID_POUND NUMBER(9);
    v_STATUS             NUMBER;
    v_MESSAGE            VARCHAR2(512);


    v_XML_REP XMLTYPE;

	TYPE t_RUN_TYPE_IDs IS TABLE OF NUMBER(9) INDEX BY VARCHAR2(16);
	v_RUN_TYPE_IDs t_RUN_TYPE_IDs;


    CURSOR c_EURO_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'),'DD/MM/YYYY') TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP_AVERAGE') "SMP_AVG_EURO",
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE')
                   WHEN 'EA' THEN   'F'
				   WHEN 'EA2' THEN  'F' 	-- post-IDT, EA2 is Forecast too
				   WHEN 'WD1' THEN  'F'		-- post-IDT, WD1 is Forecast too
                   WHEN 'EP1' THEN  'P'
                   WHEN 'EP2' THEN  'A'
                   ELSE NULL
               END "PRICE_CODE",
  		       EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') RUN_TYPE
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'E';


    CURSOR c_POUND_SMP IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'),'DD/MM/YYYY') TRADE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/SMP_AVERAGE') "SMP_AVG_POUND",
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE')
                   WHEN 'EA' THEN 'F'
				   WHEN 'EA2' THEN  'F' 	-- post-IDT, EA2 is Forecast too
				   WHEN 'WD1' THEN  'F'		-- post-IDT, WD1 is Forecast too
                   WHEN 'EP1' THEN 'P'
                   WHEN 'EP2' THEN 'A'
                   ELSE NULL
               END "PRICE_CODE",
			   EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') RUN_TYPE
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
        WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P';


	PROCEDURE LOAD_STATEMENT_TYPE_IDS
	IS
	BEGIN
		v_RUN_TYPE_IDs('EA')  := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('EA', EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
		v_RUN_TYPE_IDs('EA2') := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('EA2', EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
		v_RUN_TYPE_IDs('WD1') := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('WD1', EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
		v_RUN_TYPE_IDs('EP1') := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('EP1', EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
		v_RUN_TYPE_IDs('EP2') := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('EP2', EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);
	END LOAD_STATEMENT_TYPE_IDS;

	--  PUT_TO_AVG_SMP_TXN
    PROCEDURE PUT_TO_AVG_SMP_TXN
	(
		p_RUN_TYPE		IN VARCHAR2,
		p_TXN_NAME		IN VARCHAR2,
		p_TRADE_DATE	IN DATE,
		p_PRICE_VALUE	IN NUMBER,
		p_LOGGER		IN OUT MM_LOGGER_ADAPTER
	) IS
        v_TXN_ID                INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    BEGIN
         -- Load the Interchange Transaction data only if the STATEMENT_TYPE_ID is not null for the RUN_TYPE
         IF v_RUN_TYPE_IDs(p_RUN_TYPE) IS NULL THEN
         		p_LOGGER.LOG_ERROR('Unable to find the resolve Statement for Run Type:' || p_RUN_TYPE || ' when importing ' || g_REPORT_NAME || ' report.');
         ELSE
			-- Get the TRANSACTION_ID
			v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(	p_TRANSACTION_TYPE       => MM_SEM_UTIL.c_TXN_TYPE_MKT_RESULTS,
														p_CREATE_IF_NOT_FOUND    => FALSE,
														p_TRANSACTION_NAME       => p_TXN_NAME,
														p_EXTERNAL_IDENTIFIER    => p_TXN_NAME);
			-- Ready now to insert data
			IMPORT_AVG_SMP_AS_TXN(v_TXN_ID, v_RUN_TYPE_IDs(p_RUN_TYPE),  p_TRADE_DATE + (1/(24*60*60)),
								  p_PRICE_VALUE, p_LOGGER);
         END IF;
    END PUT_TO_AVG_SMP_TXN;
BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Daily Market Prices Averages report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

	-- Load the cache for STATEMENT_TYPE_ID
	LOAD_STATEMENT_TYPE_IDS;

    --get/create the Market Price entities
    v_SMP_PRICE_ID_EURO  := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Average System Marginal Price Euro',
                                                            'Commodity Price',
                                                            'Day',
                                                            TRUE);
    v_SMP_PRICE_ID_POUND := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Average System Marginal Price Pound',
                                                            'Commodity Price',
                                                            'Day',
                                                            TRUE);

    --Average SMP Euro
    FOR v_XML IN c_EURO_SMP LOOP
        IF v_XML.PRICE_CODE IS NOT NULL THEN
          MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_EURO,
                                         v_XML.TRADE_DATE,
                                         v_XML.PRICE_CODE,
                                         v_XML.SMP_AVG_EURO,
                                         0,
                                         v_STATUS,
                                         v_MESSAGE);
		   -- Put the MP values as Interchange Transaction Schedule Values -- This is for EUR
		   PUT_TO_AVG_SMP_TXN(v_XML.RUN_TYPE, MM_SEM_UTIL.c_TXN_NAME_AVG_SMP_EUR, v_XML.TRADE_DATE, v_XML.SMP_AVG_EURO, p_LOGGER);
        ELSE
          p_LOGGER.LOG_WARN('RUN_TYPE element does not match the expected type EA, EA2, WD1, EP1 or EP2 for TRADE_DATE:'
                            || v_XML.TRADE_DATE);
        END IF;
    END LOOP;

    --Average SMP Pound
    FOR v_XML IN c_POUND_SMP LOOP
        IF v_XML.PRICE_CODE IS NOT NULL THEN
          MM_UTIL.PUT_MARKET_PRICE_VALUE(v_SMP_PRICE_ID_POUND,
                                         v_XML.TRADE_DATE,
                                         v_XML.PRICE_CODE,
                                         v_XML.SMP_AVG_POUND,
                                         0,
                                         v_STATUS,
                                         v_MESSAGE);
			-- Put the MP values as Interchange Transaction Schedule Values -- This is for GBP
		   PUT_TO_AVG_SMP_TXN(v_XML.RUN_TYPE, MM_SEM_UTIL.c_TXN_NAME_AVG_SMP_GBP, v_XML.TRADE_DATE, v_XML.SMP_AVG_POUND, p_LOGGER);
        ELSE
          p_LOGGER.LOG_WARN('RUN_TYPE element does not match the expected type EA, EA2, WD1, EP1 or EP2 for TRADE_DATE:'
                            || v_XML.TRADE_DATE);
        END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Market Prices Averages report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_AVG_SMP;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_DAILY_ATC
(
    p_REPORT   IN CLOB,
    P_RUN_TYPE IN VARCHAR2,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_POD_ID        NUMBER(9);
    v_EXCHANGE_NAME VARCHAR2(64);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;

    -- If RUN_TYPE is null then importing Daily Inteconnector ATC;
    -- Otherwise importing the Revised version of Daily Inteconnector ATC file

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_IMPORT_MW') "MAX_IMPORT_MW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/MAXIMUM_EXPORT_MW') "MAX_EXPORT_MW"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN

    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);
    IF P_RUN_TYPE = 'None' THEN
        v_EXCHANGE_NAME := 'Import Daily Interconnector ATC report';
    ELSE
        v_EXCHANGE_NAME := 'Import Daily Interconnector ATC ' || P_RUN_TYPE ||
                           ' report';
    END IF;

    p_LOGGER.EXCHANGE_NAME := v_EXCHANGE_NAME;

    --Daily Inteconnector ATC report
    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        --try update
        IF P_RUN_TYPE = 'None' THEN
            UPDATE SEM_IC_DATA
            SET MAXIMUM_IMPORT_MW = v_XML.MAX_IMPORT_MW,
                MAXIMUM_EXPORT_MW = v_XML.MAX_EXPORT_MW,
                ATC_EVENT_ID   = p_LOGGER.LAST_EVENT_ID
            WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
              AND POD_ID = v_POD_ID
			  AND PSE_ID = CONSTANTS.NOT_ASSIGNED
			  AND RUN_TYPE = MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR;
        ELSE
            UPDATE SEM_IC_DATA
            SET REV_MAXIMUM_IMPORT_MW = v_XML.MAX_IMPORT_MW,
                REV_MAXIMUM_EXPORT_MW = v_XML.MAX_EXPORT_MW,
                REV_ATC_EVENT_ID   = p_LOGGER.LAST_EVENT_ID
            WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
              AND POD_ID = v_POD_ID
			  AND PSE_ID = CONSTANTS.NOT_ASSIGNED
			  AND RUN_TYPE = MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR;

        END IF;
            IF SQL%NOTFOUND THEN
                IF P_RUN_TYPE = 'None' THEN
                    INSERT INTO SEM_IC_DATA
                        (SCHEDULE_DATE,
                         POD_ID,
						 PSE_ID,
						 RUN_TYPE,
                         MAXIMUM_IMPORT_MW,
                         MAXIMUM_EXPORT_MW,
                         ATC_EVENT_ID)
                    VALUES
                        (v_SCHEDULE_DATE,
                         v_POD_ID,
			             CONSTANTS.NOT_ASSIGNED,
			             MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR,
                         v_XML.MAX_IMPORT_MW,
                         v_XML.MAX_EXPORT_MW,
                         p_LOGGER.LAST_EVENT_ID);
                ELSE
                    INSERT INTO SEM_IC_DATA
                        (SCHEDULE_DATE,
                         POD_ID,
						 PSE_ID,
						 RUN_TYPE,
                         REV_MAXIMUM_IMPORT_MW,
                         REV_MAXIMUM_EXPORT_MW,
                         REV_ATC_EVENT_ID)
                    VALUES
                        (v_SCHEDULE_DATE,
                         v_POD_ID,
			             CONSTANTS.NOT_ASSIGNED,
			             MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR,
                         v_XML.MAX_IMPORT_MW,
                         v_XML.MAX_EXPORT_MW,
                         p_LOGGER.LAST_EVENT_ID);
                END IF;

            END IF;
        END LOOP;


        COMMIT;

    EXCEPTION
WHEN OTHERS THEN
  IF P_RUN_TYPE = 'None' THEN
    p_LOGGER.LOG_ERROR('Error importing Import Daily Interconnector ATC report' ||
                               MM_SEM_UTIL.ERROR_STACKTRACE);
  ELSE
    p_LOGGER.LOG_ERROR('Error importing Import Daily Interconnector ATC ' ||
                               P_RUN_TYPE || ' report' ||
                               MM_SEM_UTIL.ERROR_STACKTRACE);
  END IF;
RAISE ;

END IMPORT_DAILY_ATC;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IC_FLOW
(
    p_REPORT   IN CLOB,
    P_RUN_TYPE IN VARCHAR2,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_POD_ID        NUMBER(9);
    v_EXCHANGE_NAME VARCHAR2(64);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;

    -- If RUN_TYPE is Indicative then importing the indicative version of the Inteconnector Flow and Residual Capacity
    -- Otherwise importing the Initial version of the same file

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/NET_FLOW') "NET_FLOW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESIDUAL_CAPACITY') "RESIDUAL_CAPACITY"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN

    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);
    v_EXCHANGE_NAME := 'Import IC Flows and Resid Capacity ' || P_RUN_TYPE || ' report';

    p_LOGGER.EXCHANGE_NAME := v_EXCHANGE_NAME;

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        --try update
        IF UPPER(p_RUN_TYPE) LIKE 'INDIC%' THEN
            UPDATE SEM_IC_DATA
            SET INDICATIVE_NET_FLOW = v_XML.NET_FLOW,
                INDICATIVE_RESIDUAL_CAPACITY = v_XML.RESIDUAL_CAPACITY,
                INDIC_EVENT_ID   = p_LOGGER.LAST_EVENT_ID
            WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
              AND POD_ID = v_POD_ID
			  AND PSE_ID = CONSTANTS.NOT_ASSIGNED
			  AND RUN_TYPE = MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR;

        ELSIF UPPER(p_RUN_TYPE) LIKE 'INIT%' THEN
            UPDATE SEM_IC_DATA
            SET INITIAL_NET_FLOW = v_XML.NET_FLOW,
                INITIAL_RESIDUAL_CAPACITY = v_XML.RESIDUAL_CAPACITY,
                INIT_EVENT_ID   = p_LOGGER.LAST_EVENT_ID
            WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
              AND POD_ID = v_POD_ID
			  AND PSE_ID = CONSTANTS.NOT_ASSIGNED
			  AND RUN_TYPE = MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR;

        END IF;
            IF SQL%NOTFOUND THEN
               IF UPPER(p_RUN_TYPE) LIKE 'INDIC%' THEN
                    INSERT INTO SEM_IC_DATA
                        (SCHEDULE_DATE,
                         POD_ID,
						 PSE_ID,
						 RUN_TYPE,
                         INDICATIVE_NET_FLOW,
                         INDICATIVE_RESIDUAL_CAPACITY,
                         INDIC_EVENT_ID)
                    VALUES
                        (v_SCHEDULE_DATE,
                         v_POD_ID,
						 CONSTANTS.NOT_ASSIGNED,
						 MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR,
                         v_XML.NET_FLOW,
                         v_XML.RESIDUAL_CAPACITY,
                         p_LOGGER.LAST_EVENT_ID);
                ELSIF UPPER(p_RUN_TYPE) LIKE 'INIT%' THEN
                    INSERT INTO SEM_IC_DATA
                        (SCHEDULE_DATE,
                         POD_ID,
						 PSE_ID,
						 RUN_TYPE,
                         INITIAL_NET_FLOW,
                         INITIAL_RESIDUAL_CAPACITY,
                         INIT_EVENT_ID)
                    VALUES
                        (v_SCHEDULE_DATE,
                         v_POD_ID,
						 CONSTANTS.NOT_ASSIGNED,
						 MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR,
                         v_XML.NET_FLOW,
                         v_XML.RESIDUAL_CAPACITY,
                         p_LOGGER.LAST_EVENT_ID);
                END IF;

            END IF;
        END LOOP;


        COMMIT;

    EXCEPTION
WHEN
OTHERS THEN p_LOGGER.LOG_ERROR('Error importing IC Flows and Resid Capacity ' ||
                               P_RUN_TYPE || ' report' ||
                               MM_SEM_UTIL.ERROR_STACKTRACE);
RAISE ;

END IMPORT_IC_FLOW;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IC_AGG_NOMIN
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_POD_ID        NUMBER(9);
    v_EXCHANGE_NAME VARCHAR2(64);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
	v_PARTICIPANT_NAME VARCHAR2(32);
	v_PSE_ID		PSE.PSE_ID%TYPE;


    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/UNIT_NOMINATION') "UNIT_NOMINATION"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN

    v_XML_REP       := XMLTYPE.CREATEXML(p_REPORT);
    v_EXCHANGE_NAME := 'Import Daily Aggregated IC User Nominations report';

    p_LOGGER.EXCHANGE_NAME := v_EXCHANGE_NAME;

	-- Get the PARTICIPANT_NAME from the XML Header
    SELECT EXTRACTVALUE(v_XML_REP, 'REPORT/REPORT_HEADER/HEADROW/' || g_PARTICIPANT_ELEMENT)
    INTO v_PARTICIPANT_NAME
    FROM DUAL;

	-- Get the PSE_ID
	v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_PARTICIPANT_NAME,
                                       TRUE);

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        --try update
        UPDATE SEM_IC_DATA
        SET UNIT_NOMINATION = v_XML.UNIT_NOMINATION,
            NOM_EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
        AND POD_ID = v_POD_ID
		AND PSE_ID = v_PSE_ID
		AND RUN_TYPE = NVL(g_RUN_TYPE, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR);

        IF SQL%NOTFOUND THEN
            INSERT INTO SEM_IC_DATA
                (SCHEDULE_DATE,
                 POD_ID,
				 PSE_ID,
				 RUN_TYPE,
                 UNIT_NOMINATION,
                 NOM_EVENT_ID)
            VALUES
                (v_SCHEDULE_DATE,
                 v_POD_ID,
				 v_PSE_ID,
				 NVL(g_RUN_TYPE, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR),
                 v_XML.UNIT_NOMINATION,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;
    END LOOP;


    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Aggregated IC User Nominations report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_IC_AGG_NOMIN;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IC_CAP_HOLDINGS(p_REPORT IN CLOB,
                 p_PERIODICITY IN VARCHAR2, --A, M, D, DA
                 p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) AS
  v_POD_ID           NUMBER(9);
  v_PSE_ID           NUMBER(9);
  v_EXCHANGE_NAME    VARCHAR2(64);
  v_SCHEDULE_DATE    DATE;
  v_XML_REP          XMLTYPE;
  v_PARTICIPANT_NAME VARCHAR2(32);

  -- 24-nov-2007, jbc: added check for '-' for INTERCONNECTOR_IMPORT_CAPACITY and
  -- INTERCONNECTOR_IMPORT_CAPACITY elements; return/store NULL when we get this. Fixes BZ 15098.
  CURSOR c_XML IS
    SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
         EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
         TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
         CASE EXTRACTVALUE(VALUE(T), '//DATAROW/INTERCONNECTOR_EXPORT_CAPACITY')
           WHEN '-' THEN
          NULL
           ELSE
          EXTRACTVALUE(VALUE(T), '//DATAROW/INTERCONNECTOR_EXPORT_CAPACITY')
         END "IC_EXPORT_CAPACITY",
         CASE EXTRACTVALUE(VALUE(T), '//DATAROW/INTERCONNECTOR_IMPORT_CAPACITY')
           WHEN '-' THEN
          NULL
           ELSE
          EXTRACTVALUE(VALUE(T), '//DATAROW/INTERCONNECTOR_IMPORT_CAPACITY')
         END "IC_IMPORT_CAPACITY"
    FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN

  v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);
  v_EXCHANGE_NAME        := 'Import Capacity Holdings - ' || p_PERIODICITY || ' report';
  p_LOGGER.EXCHANGE_NAME := v_EXCHANGE_NAME;

  -- this returns null if we're importing PUB_D_IntconnCapActHoldResults (which happens for MPUD4)
  SELECT EXTRACTVALUE(v_XML_REP, 'REPORT/REPORT_HEADER/HEADROW/PARTICIPANT_NAME')
  INTO v_PARTICIPANT_NAME
  FROM DUAL;

  FOR v_XML IN c_XML LOOP
    --calculate the SCHEDULE_DATE
    v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                             v_XML.DELIVERY_HOUR,
                             v_XML.DELIVERY_INTERVAL);
    --get PSE_ID from participant name in report header (MPUD5)
    -- or from body (MPUD4). Fixes BZ 15082.
    IF v_PARTICIPANT_NAME IS NULL THEN
      v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);
    ELSE
      v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_PARTICIPANT_NAME, TRUE);
    END IF;

    --get POD_ID
    v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

    --try update
    UPDATE SEM_IC_CAP_HOLDINGS
    SET IC_EXPORT_CAPACITY = v_XML.IC_EXPORT_CAPACITY,
      IC_IMPORT_CAPACITY = v_XML.IC_IMPORT_CAPACITY,
      EVENT_ID = p_LOGGER.LAST_EVENT_ID
    WHERE PERIODICITY = p_PERIODICITY
    AND SCHEDULE_DATE = v_SCHEDULE_DATE
    AND PSE_ID = v_PSE_ID
    AND POD_ID = v_POD_ID;

    IF SQL%NOTFOUND THEN
      --Try insert into SEM_IC_CAP_HOLDINGS table
      INSERT INTO SEM_IC_CAP_HOLDINGS
        (PERIODICITY,
         SCHEDULE_DATE,
         PSE_ID,
         POD_ID,
         IC_EXPORT_CAPACITY,
         IC_IMPORT_CAPACITY,
         EVENT_ID)
      VALUES
        (p_PERIODICITY,
         v_SCHEDULE_DATE,
         v_PSE_ID,
         v_POD_ID,
         v_XML.IC_EXPORT_CAPACITY,
         v_XML.IC_IMPORT_CAPACITY,
         p_LOGGER.LAST_EVENT_ID);
    END IF;

  END LOOP;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing Capacity Holdings - ' || p_PERIODICITY || ' report' ||
               MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;

END IMPORT_IC_CAP_HOLDINGS;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_DAY_EXCHANGE_RATE
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_EURO_POUND_PRICE_ID NUMBER(9);
    v_POUND_EURO_PRICE_ID NUMBER(9);
    v_STATUS              NUMBER;
    v_MESSAGE             VARCHAR2(512);

    v_XML_REP XMLTYPE;

    CURSOR c_XML IS
        SELECT X.TRADE_DATE, X.EURO_TO_POUND, Y.POUND_TO_EURO
        FROM (SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'),
                             'DD/MM/YYYY') TRADE_DATE,
                     EXTRACTVALUE(VALUE(T), '//DATAROW/EXCHANGE_RATE') EURO_TO_POUND
              FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                             'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
              WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/FROM_CURRENCY') = 'E'
              AND EXTRACTVALUE(VALUE(T), '//DATAROW/TO_CURRENCY') = 'P') X,
             (SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'),
                             'DD/MM/YYYY') TRADE_DATE,
                     EXTRACTVALUE(VALUE(T), '//DATAROW/EXCHANGE_RATE') POUND_TO_EURO
              FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                             'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
              WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/FROM_CURRENCY') = 'P'
              AND EXTRACTVALUE(VALUE(T), '//DATAROW/TO_CURRENCY') = 'E') Y
        WHERE X.TRADE_DATE = Y.TRADE_DATE;


BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Daily Exchange Rate';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);


    --get/create the Market Price entities
    v_EURO_POUND_PRICE_ID := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Trading Day Exchange Rate: Euro to Pound',
                                                             'Exchange Rate',
                                                             'Day',
                                                             TRUE);
    v_POUND_EURO_PRICE_ID := MM_SEM_UTIL.GET_MARKET_PRICE_ID('Trading Day Exchange Rate: Pound to Euro',
                                                             'Exchange Rate',
                                                             'Day',
                                                             TRUE);


    FOR v_XML IN c_XML LOOP
        --Exchange Rate Euro-to-Pound
        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_EURO_POUND_PRICE_ID,
                                       v_XML.TRADE_DATE,
                                       'A',
                                       v_XML.EURO_TO_POUND,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);


        --Exchange Rate Pound-to-Euro
        MM_UTIL.PUT_MARKET_PRICE_VALUE(v_POUND_EURO_PRICE_ID,
                                       v_XML.TRADE_DATE,
                                       'A',
                                       v_XML.POUND_TO_EURO,
                                       0,
                                       v_STATUS,
                                       v_MESSAGE);
    END LOOP;


EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Trading Day Exchange Rate report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_DAY_EXCHANGE_RATE;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSS_LOAD_PROBAB
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;
  v_PERIODICITY  VARCHAR2(6);

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
         CASE v_PERIODICITY
                   WHEN 'M' THEN
                    EXTRACTVALUE(VALUE(T), '//DATAROW/LOSS_OF_LOAD_PROBABILITY')
           WHEN 'D' THEN
                    EXTRACTVALUE(VALUE(T), '//DATAROW/EP_LOSS_OF_LOAD_PROBABILITY')
               END "LOSS_LOAD_PROB"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    CASE g_REPORT_NAME
    WHEN 'PUB_D_EPLossOfLoadProbability' THEN
      v_PERIODICITY := 'D';
      p_LOGGER.EXCHANGE_NAME := 'Import Daily Loss of Load Probability Forecast report';
    WHEN 'PUB_M_LossLoadProbabilityFcst' THEN
      v_PERIODICITY := 'M';
      p_LOGGER.EXCHANGE_NAME := 'Import Monthly Loss of Load Probability Forecast report';
  END CASE;


    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);

        MERGE INTO SEM_LOSS_LOAD_PROB_FORECAST S
        USING (SELECT v_SCHEDULE_DATE SCHEDULE_DATE,
                  v_XML.LOSS_LOAD_PROB LOSS_OF_LOAD_PROBABILITY,
            p_LOGGER.LAST_EVENT_ID EVENT_ID,
            v_PERIODICITY PERIODICITY
               FROM DUAL) A
        ON (A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.PERIODICITY = S.PERIODICITY)
        WHEN MATCHED THEN
            UPDATE
            SET S.EVENT_ID              = p_LOGGER.LAST_EVENT_ID,
                S.LOSS_OF_LOAD_PROBABILITY = v_XML.LOSS_LOAD_PROB
        WHEN NOT MATCHED THEN
            INSERT
                (SCHEDULE_DATE,
                 LOSS_OF_LOAD_PROBABILITY,
         EVENT_ID,
                 PERIODICITY)
            VALUES
                (v_SCHEDULE_DATE,
                 v_XML.LOSS_LOAD_PROB,
         p_LOGGER.LAST_EVENT_ID,
                 v_PERIODICITY);
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily and/or Monthly Loss of Load Probability Forecast, ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_LOSS_LOAD_PROBAB;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_DISPATCH_INSTR
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_PSE_ID        NUMBER(9);
    v_POD_ID        NUMBER(9);
    v_XML_REP       XMLTYPE;
    v_REPORT_TYPE   VARCHAR2(4);

    CURSOR c_XML IS
        SELECT TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T),
                                           '//DATAROW/INSTRUCTION_TIMESTAMP'),
                              'DD/MM/YYYY HH24:MI:SS'),MM_SEM_UTIL.g_TZ) INSTRUCTION_TIMESTAMP,
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DISPATCH_INSTRUCTION') "DISPATCH_INSTRUCTION",
               EXTRACTVALUE(VALUE(T), '//DATAROW/INSTRUCTION_CODE') "INSTRUCTION_CODE",
               EXTRACTVALUE(VALUE(T), '//DATAROW/INSTRUCTION_COMBINATION_CODE') "INSTRUCTION_COMBINATION_CODE",
               TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T),
                                           '//DATAROW/INSTRUCTION_ISSUE_TIME'),
                              'DD/MM/YYYY HH24:MI:SS'), MM_SEM_UTIL.g_TZ) INSTRUCTION_ISSUE_TIME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_UP_RATE') "RAMP_UP_RATE",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RAMP_DOWN_RATE') "RAMP_DOWN_RATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;



BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Daily Dispatch Instructions report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    IF g_REPORT_NAME = 'PUB_D_DispatchInstructions' THEN
       v_REPORT_TYPE := 'D+1';
    ELSIF g_REPORT_NAME = 'PUB_D_DispatchInstructionsD3' THEN
       v_REPORT_TYPE := 'D+3';
    END IF;

    FOR v_XML IN c_XML LOOP
        --get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

    -- 26-nov-2007, jbc: market issues instructions for different instruction codes and
    -- combination codes in the same issue time and timestamp, so we should include those
    -- fields in the WHERE clause here, rather than the SET clause. Fixes BZ 15099 and 15100
    -- (note that the latter has the inclusion of the INSTRUCTION_COMB_CODE field in SEM_DISPATCH_INSTR)
        UPDATE SEM_DISPATCH_INSTR
        SET DISPATCH_INSTRUCTION = CASE WHEN v_XML.DISPATCH_INSTRUCTION = '-' THEN NULL ELSE TO_NUMBER(v_XML.DISPATCH_INSTRUCTION) END,
            RAMP_UP_RATE           = CASE WHEN v_XML.RAMP_UP_RATE = '-' THEN NULL ELSE TO_NUMBER(v_XML.RAMP_UP_RATE) END,
            RAMP_DOWN_RATE         = CASE WHEN v_XML.RAMP_DOWN_RATE = '-' THEN NULL ELSE TO_NUMBER(v_XML.RAMP_DOWN_RATE) END,
            EVENT_ID            = p_LOGGER.LAST_EVENT_ID
        WHERE REPORT_TYPE = v_REPORT_TYPE
            AND PSE_ID = v_PSE_ID
            AND POD_ID = v_POD_ID
            AND INSTRUCTION_TIME_STAMP = v_XML.INSTRUCTION_TIMESTAMP
            AND INSTRUCTION_ISSUE_TIME = v_XML.INSTRUCTION_ISSUE_TIME
            AND INSTRUCTION_CODE = v_XML.INSTRUCTION_CODE
            AND INSTRUCTION_COMBINATION_CODE = NVL(v_XML.INSTRUCTION_COMBINATION_CODE,'-');

        IF SQL%NOTFOUND THEN
            --Try insert into SEM_DISPATCH_INSTR table
            INSERT INTO SEM_DISPATCH_INSTR
                (REPORT_TYPE,
                INSTRUCTION_ISSUE_TIME,
                INSTRUCTION_TIME_STAMP,
                PSE_ID,
                POD_ID,
                DISPATCH_INSTRUCTION,
                INSTRUCTION_CODE,
                INSTRUCTION_COMBINATION_CODE,
                RAMP_UP_RATE,
                RAMP_DOWN_RATE,
                EVENT_ID)
            VALUES
                (v_REPORT_TYPE,
                 v_XML.INSTRUCTION_ISSUE_TIME,
                 v_XML.INSTRUCTION_TIMESTAMP,
                 v_PSE_ID,
                 v_POD_ID,
                 CASE WHEN v_XML.DISPATCH_INSTRUCTION = '-' THEN NULL ELSE TO_NUMBER(v_XML.DISPATCH_INSTRUCTION) END,
                 v_XML.INSTRUCTION_CODE,
                 NVL(v_XML.INSTRUCTION_COMBINATION_CODE,'-'),
                 CASE WHEN v_XML.RAMP_UP_RATE = '-' THEN NULL ELSE TO_NUMBER(v_XML.RAMP_UP_RATE) END,
                 CASE WHEN v_XML.RAMP_DOWN_RATE = '-' THEN NULL ELSE TO_NUMBER(v_XML.RAMP_DOWN_RATE) END,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Dispatch Instructions, ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_DISPATCH_INSTR;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SETTL_CLASS_UPDATE
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_POD_ID           NUMBER(9);
    v_PSE_ID           NUMBER(9);
    v_XML_REP          XMLTYPE;
    -------------------------------
    v_ATTRIBUTE_ID     NUMBER(9);
    v_ATTRIBUTE_NAME   ENTITY_ATTRIBUTE.ATTRIBUTE_NAME%TYPE;
    v_ATTRIBUTE_TYPE   ENTITY_ATTRIBUTE.ATTRIBUTE_TYPE%TYPE;
    ---------------------------------
  v_TRADE_DATE DATE;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_NAME",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EFFECTIVE_DATE'), 'DD/MM/YYYY') EFFECTIVE_DATE,
                     CASE EXTRACTVALUE(VALUE(T), '//DATAROW/EXPIRATION_DATE')
                         WHEN '-' THEN
                          NULL
                         ELSE
                          TO_DATE(EXTRACTVALUE(VALUE(T),
                                               '//DATAROW/EXPIRATION_DATE'),
                                  'DD/MM/YYYY')
                     END "EXPIRATION_DATE",
                     EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') "SETTL_CLASS"
              FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                             'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Monthly Updates to Settlement Classes report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

  -- get TRADE DATE from the head of XML
  SELECT TRUNC(TO_DATE(EXTRACTVALUE(v_XML_REP, 'REPORT/REPORT_HEADER/HEADROW/TRADE_DATE'), 'YYYYMMDD'))
    INTO v_TRADE_DATE
    FROM DUAL;

    FOR v_XML IN c_XML LOOP

        --get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

    --update/insert SEM_SERVICE_POINT_PSE table
    UT.PUT_TEMPORAL_DATA(p_TABLE_NAME => 'SEM_SERVICE_POINT_PSE',
               p_BEGIN_DATE => v_TRADE_DATE,
               p_END_DATE => NULL,
               p_NULL_END_IS_HIGH_DATE => TRUE,
               p_UPDATE_ENTRY_DATE => TRUE,
               p_COL_NAME1 => 'PSE_ID',
               p_COL_VALUE1 => UT.GET_LITERAL_FOR_NUMBER(v_PSE_ID),
               p_COL_IS_KEY1 => FALSE,
               p_COL_NAME2 => 'POD_ID',
               p_COL_VALUE2 => UT.GET_LITERAL_FOR_NUMBER(v_POD_ID),
               p_COL_IS_KEY2 => TRUE);

        v_ATTRIBUTE_TYPE := 'String';
        ID.ID_FOR_ENTITY_ATTRIBUTE('Resource Type', EC.ED_SERVICE_POINT, v_ATTRIBUTE_TYPE, v_ATTRIBUTE_ID);

        IF v_ATTRIBUTE_ID <= 0 THEN
            RAISE_APPLICATION_ERROR(-20106,'COULD NOT GET ATTRIBUTE ID FOR: ' || v_ATTRIBUTE_NAME);
        END IF;

        RO.PUT_ENTITY_ATTRIBUTE(p_ATTRIBUTE_NAME   => 'Resource Type',
                              p_ENTITY_DOMAIN_ID => EC.ED_SERVICE_POINT,
                              p_OWNER_ENTITY_ID  => v_POD_ID,
                              p_ATTRIBUTE_TYPE   => v_ATTRIBUTE_TYPE,
                              p_ATTRIBUTE_VAL    => v_XML.SETTL_CLASS,
                              p_BEGIN_DATE       => v_XML.EFFECTIVE_DATE,
                              p_END_DATE         => v_XML.EXPIRATION_DATE);

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Monthly Updates to Settlement Classes, ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_SETTL_CLASS_UPDATE;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_GEN_OUTAGE_SCHED_SUMM
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_POD_ID  NUMBER(9);
    v_XML_REP XMLTYPE;
    v_ROW_NUM NUMBER;
    v_REPORT_SOURCE VARCHAR2(64) := 'Monthly Generator Outage Summary';

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/@num') "ROW_NUM",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/OUTAGE_REASON_FLAG') "OUTAGE_REASON_FLAG",
               TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/BEGIN_TIME'),'DD/MM/YYYY HH24:MI:SS'),MM_SEM_UTIL.g_TZ) "BEGIN_TIME",
               TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/END_TIME'),'DD/MM/YYYY HH24:MI:SS'),MM_SEM_UTIL.g_TZ) "END_TIME",
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DERATE_MW')
                         WHEN '-' THEN
                          NULL
                         ELSE
                          EXTRACTVALUE(VALUE(T), '//DATAROW/DERATE_MW')
                     END "DERATE_MW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/EQUIPMENT_STATUS') "EQUIPMENT_STATUS"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;


BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Monthly Generator Outage Summary report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    FOR v_XML IN c_XML LOOP
        v_ROW_NUM := v_XML.ROW_NUM;
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        UPDATE SEM_OUTAGE_SCHEDULE
        SET END_TIME           = v_XML.END_TIME,
            OUTAGE_REASON_FLAG = v_XML.OUTAGE_REASON_FLAG,
            DERATE_MW          = v_XML.DERATE_MW,
            EQUIPMENT_STATUS   = v_XML.EQUIPMENT_STATUS,
            EVENT_ID        = p_LOGGER.LAST_EVENT_ID
        WHERE POD_ID = v_POD_ID
        AND BEGIN_TIME = v_XML.BEGIN_TIME
        AND REPORT_SOURCE = v_REPORT_SOURCE;

        --Try insert into SEM_OUTAGE_SCHEDULE table
        IF SQL%NOTFOUND THEN

            INSERT INTO SEM_OUTAGE_SCHEDULE
                (REPORT_SOURCE,
                 POD_ID,
                 BEGIN_TIME,
                 END_TIME,
                 OUTAGE_REASON_FLAG,
                 DERATE_MW,
                 EQUIPMENT_STATUS,
                 EVENT_ID)
            VALUES
                (v_REPORT_SOURCE,
                 v_POD_ID,
                 v_XML.BEGIN_TIME,
                 v_XML.END_TIME,
                 v_XML.OUTAGE_REASON_FLAG,
                 v_XML.DERATE_MW,
                 v_XML.EQUIPMENT_STATUS,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Monthly Generator Outage Summary, ' || 'ROW_NUM = ' || v_ROW_NUM || ',' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_GEN_OUTAGE_SCHED_SUMM;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_GEN_OUTAGE_SCHED_ALL
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_POD_ID  NUMBER(9);
    v_ROW_NUM NUMBER;
    v_XML_REP XMLTYPE;
    v_REPORT_SOURCE VARCHAR2(64) := 'Monthly All Generator Outage Schedules';

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/@num') "ROW_NUM",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/OUTAGE_REASON_FLAG') "OUTAGE_REASON_FLAG",
               TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/BEGIN_TIME'),'DD/MM/YYYY HH24:MI:SS'),MM_SEM_UTIL.g_TZ) "BEGIN_TIME",
               TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/END_TIME'),'DD/MM/YYYY HH24:MI:SS'),MM_SEM_UTIL.g_TZ) "END_TIME"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;


BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Monthly All Generator Outage Schedules report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    FOR v_XML IN c_XML LOOP
        v_ROW_NUM := v_XML.ROW_NUM;
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        UPDATE SEM_OUTAGE_SCHEDULE
        SET END_TIME           = v_XML.END_TIME,
            OUTAGE_REASON_FLAG = v_XML.OUTAGE_REASON_FLAG,
            EVENT_ID        = p_LOGGER.LAST_EVENT_ID
        WHERE POD_ID = v_POD_ID
        AND BEGIN_TIME = v_XML.BEGIN_TIME
        AND REPORT_SOURCE = v_REPORT_SOURCE;

        --Try insert into SEM_OUTAGE_SCHEDULE table
        IF SQL%NOTFOUND THEN

            INSERT INTO SEM_OUTAGE_SCHEDULE
                (REPORT_SOURCE,
                 POD_ID,
                 BEGIN_TIME,
                 END_TIME,
                 OUTAGE_REASON_FLAG,
                 EVENT_ID)
            VALUES
                (v_REPORT_SOURCE,
                 v_POD_ID,
                 v_XML.BEGIN_TIME,
                 v_XML.END_TIME,
                 v_XML.OUTAGE_REASON_FLAG,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Monthly All Generator Outage Schedules, ' || 'ROW_NUM = ' || v_ROW_NUM || ',' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_GEN_OUTAGE_SCHED_ALL;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_GEN_OUTAGE_SCHED_PLAN
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_POD_ID  NUMBER(9);
    v_XML_REP XMLTYPE;
    v_ROW_NUM NUMBER;
    v_REPORT_SOURCE VARCHAR2(64) :='Monthly Planned Generator Outage Schedules';

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/@num') "ROW_NUM",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/BEGIN_TIME'),'DD/MM/YYYY HH24:MI:SS'),MM_SEM_UTIL.g_TZ) "BEGIN_TIME",
               TO_CUT(TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/END_TIME'),'DD/MM/YYYY HH24:MI:SS'),MM_SEM_UTIL.g_TZ) "END_TIME",
               CASE EXTRACTVALUE(VALUE(T), '//DATAROW/DERATE_MW')
                         WHEN '-' THEN
                          NULL
                         ELSE
                          EXTRACTVALUE(VALUE(T), '//DATAROW/DERATE_MW')
                     END "DERATE_MW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/EQUIPMENT_STATUS') "EQUIPMENT_STATUS"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import Monthly Planned Generator Outage Schedules report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);

    FOR v_XML IN c_XML LOOP
        v_ROW_NUM := v_XML.ROW_NUM;
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        UPDATE SEM_OUTAGE_SCHEDULE
        SET OUTAGE_REASON_FLAG = 'P',
            END_TIME         = v_XML.END_TIME,
            DERATE_MW        = v_XML.DERATE_MW,
            EQUIPMENT_STATUS = v_XML.EQUIPMENT_STATUS,
            EVENT_ID      = p_LOGGER.LAST_EVENT_ID
        WHERE POD_ID = v_POD_ID
        AND BEGIN_TIME = v_XML.BEGIN_TIME
        AND REPORT_SOURCE = v_REPORT_SOURCE;

        --Try insert into SEM_OUTAGE_SCHEDULE table
        IF SQL%NOTFOUND THEN
            INSERT INTO SEM_OUTAGE_SCHEDULE
                (REPORT_SOURCE,
                 POD_ID,
                 OUTAGE_REASON_FLAG,
                 BEGIN_TIME,
                 END_TIME,
                 DERATE_MW,
                 EQUIPMENT_STATUS,
                 EVENT_ID)
            VALUES
                (v_REPORT_SOURCE,
                 v_POD_ID,
                 'P',
                 v_XML.BEGIN_TIME,
                 v_XML.END_TIME,
                 v_XML.DERATE_MW,
                 v_XML.EQUIPMENT_STATUS,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Monthly Planned Generator Outage Schedules, ' || 'ROW_NUM = ' || v_ROW_NUM || ',' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_GEN_OUTAGE_SCHED_PLAN;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MKT_SCHED_DETAIL
(
    p_REPORT        IN CLOB,
    p_IMPORT_PARAM  IN VARCHAR2,
    p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER

) AS

    v_SCHEDULE_DATE         DATE;
    v_SEM_ACCOUNT_NAME      EXTERNAL_CREDENTIALS.EXTERNAL_ACCOUNT_NAME%TYPE;
    v_TXN_TYPE              INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_TXN_ID                NUMBER(9);
    v_XML_REP               XMLTYPE;
    v_STATUS                NUMBER;
    v_SCHEDULE_TYPE_ID      NUMBER(9);
    v_SCHED_IDS             NUMBER_COLLECTION := NUMBER_COLLECTION();
    v_EXTID_MKT_SCHED       EXTERNAL_SYSTEM_IDENTIFIER.EXTERNAL_IDENTIFIER%TYPE;
    v_RO_RESOURCE_TYPE      TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
    v_TRANSACTION_NAME      INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
    v_TRANSACTION_IDENT     INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE;
    v_EFFECTIVE_GATE_WINDOW INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;

    -- ignore the prices that appear in the market schedule report
    -- and get just the MW values . Filter either Pounds or Euro (the MW values are the same)
    -- the below cursor is for both Ex-Ante and Indicative Ex-Post XML files
    -- 21-nov-2007, jbc: added new logic to handle MPUD5 changes for the MW element,
    -- which changes from MSQ to SCHEDULE_QUANTITY. Fixes BZ 15077.
    -- 14-feb-2008, LD: change the code to handle the generator, interconnector and demand-side units.
    -- the interconnestor's MSQ will create/find a transaction of 'Nomination' type. Fixes BZ 15340
    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') "RESOURCE_TYPE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               CASE v_EXTID_MKT_SCHED
                   WHEN 'EX-ANTE' THEN
                       EXTRACTVALUE(VALUE(T), '//DATAROW/MSQ')
                   WHEN 'EA2' THEN
                       EXTRACTVALUE(VALUE(T), '//DATAROW/MSQ')
                   WHEN 'WD1' THEN
                       EXTRACTVALUE(VALUE(T), '//DATAROW/MSQ')
                   WHEN 'INDICATIVE EX-POST' THEN
                       EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_MKT_SCHED_DETAILS_QUANTITY)
                   ELSE
                       EXTRACTVALUE(VALUE(T), '//DATAROW/SCHEDULE_QUANTITY')
               END "SCHED_QUANT",
               EXTRACTVALUE(VALUE(T), '//DATAROW/GATE_WINDOW') "GATE_WINDOW"
          FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
         WHERE EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG') = 'P';

BEGIN

    p_LOGGER.EXCHANGE_NAME := 'Import ' || p_IMPORT_PARAM || ' Market Schedule Detail report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);
    v_EXTID_MKT_SCHED      := UPPER(p_IMPORT_PARAM);

    -- grab the account info from the headed of XML
    SELECT EXTRACTVALUE(v_XML_REP, 'REPORT/REPORT_HEADER/HEADROW/' || g_PARTICIPANT_ELEMENT)
      INTO v_SEM_ACCOUNT_NAME
      FROM DUAL;

    -- get the id for schedule ids for each statemetn type external sytem ident
    IF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA) THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);

    ELSIF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA2_ABR) THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA2_ABR,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);

    ELSIF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_WD1_ABR) THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_WD1_ABR,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_RUN_TYPE);

    ELSIF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INDIC_EP) THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INDIC_EP,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);

    ELSIF v_EXTID_MKT_SCHED LIKE UPPER(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INIT_EP) THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INIT_EP,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);
    END IF;

    FOR v_XML IN c_XML LOOP
        -- determine the Transaction_Type based on resource type
        v_TXN_TYPE := NULL;
        -- This Effective Gate Window will fall back on EA for Pre-IDT files.
        v_EFFECTIVE_GATE_WINDOW := NVL(v_XML.GATE_WINDOW, MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR);
        IF LENGTH(v_XML.RESOURCE_TYPE) = 4 THEN
            v_TXN_TYPE := MM_SEM_UTIL.c_TXN_TYPE_GENERATION;
            v_TRANSACTION_NAME := v_XML.RESOURCE_ID || ':Market Schedule:' || v_EFFECTIVE_GATE_WINDOW;
            v_TRANSACTION_IDENT := 'Market Schedule:' || v_XML.RESOURCE_ID || ':' || v_EFFECTIVE_GATE_WINDOW;
        ELSIF UPPER(v_XML.RESOURCE_TYPE) IN ('DU', 'SU') THEN
            v_TXN_TYPE := 'Load';
            v_TRANSACTION_NAME := v_XML.RESOURCE_ID || ':Market Schedule';
            v_TRANSACTION_IDENT := NVL(v_TXN_TYPE, 'Invalid txn. type') || ':' || v_XML.RESOURCE_ID;
        ELSIF UPPER(v_XML.RESOURCE_TYPE) = 'I' THEN
            v_TXN_TYPE := MM_SEM_UTIL.c_TXN_TYPE_NOMINATION;
            v_TRANSACTION_NAME := v_XML.RESOURCE_ID ||  ':Interconnector User Nomination:' || v_EFFECTIVE_GATE_WINDOW;
            v_TRANSACTION_IDENT := NVL(v_TXN_TYPE, 'Invalid txn. type') || ':' || v_XML.RESOURCE_ID || ':' || v_EFFECTIVE_GATE_WINDOW;
        ELSE
            p_LOGGER.LOG_WARN('Warning importing ' || p_IMPORT_PARAM ||
                              ' Market Schedule Detail report: No published Resource Type for '
                              || v_XML.RESOURCE_ID || ' unit.');
        END IF;

        v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(v_TXN_TYPE, v_XML.RESOURCE_ID, MM_SEM_UTIL.c_COMMODITY_ENERGY, v_EFFECTIVE_GATE_WINDOW);
        IF v_TXN_ID IS NULL THEN
            v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(p_TRANSACTION_TYPE    => v_TXN_TYPE,
                                                       p_RESOURCE_NAME       => v_XML.RESOURCE_ID,
                                                       p_CREATE_IF_NOT_FOUND => TRUE,
                                                       p_AGREEMENT_TYPE      => v_EFFECTIVE_GATE_WINDOW,
                                                       p_TRANSACTION_NAME    => v_TRANSACTION_NAME,
                                                       p_EXTERNAL_IDENTIFIER => v_TRANSACTION_IDENT,
                                                       p_ACCOUNT_NAME        => v_SEM_ACCOUNT_NAME);
        END IF;

        -- calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);

        -- check if the associated entity attribute of the ServicePoint matches the indicated ResourceType
        -- log a warning error if they do not match
        v_RO_RESOURCE_TYPE := MM_SEM_UTIL.GET_RESOURCE_TYPE(v_TXN_ID,TRUNC(v_SCHEDULE_DATE));
        IF v_RO_RESOURCE_TYPE <> v_XML.RESOURCE_TYPE THEN
          p_LOGGER.LOG_WARN('Warning importing ' || p_IMPORT_PARAM ||
                           ' Market Schedule Detail report: The published Resource Type ' || v_XML.RESOURCE_TYPE ||
                           ' for ' || v_XML.RESOURCE_ID || ' generator does not match the database value ' || v_RO_RESOURCE_TYPE);
        END IF;

        -- loop through the schedule type ids
        FOR I IN 1 .. v_SCHED_IDS.COUNT LOOP
            v_SCHEDULE_TYPE_ID := v_SCHED_IDS(I);
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID,
                                p_SCHEDULE_TYPE  => v_SCHEDULE_TYPE_ID,
                                p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                                p_AS_OF_DATE     => LOW_DATE,
                                p_AMOUNT         => v_XML.SCHED_QUANT,
                                p_PRICE          => NULL,
                                p_STATUS         => v_STATUS);

        END LOOP;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || p_IMPORT_PARAM ||
                           ' Market Schedule Detail report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_MKT_SCHED_DETAIL;
------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ACTUAL_SCHEDULES(p_REPORT IN CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) AS
  v_SCHEDULE_DATE          DATE;
  k_INDIC_ACT_RPT_NAME     VARCHAR2(32) := 'MP_D_IndicativeActualSchedules';
  k_WITHIN_DAY_RPT_NAME    VARCHAR2(32) := 'MP_D_WithinDayActualSchedules';
  v_INDIC_ACT_EVENT_ID  NUMBER(9);
  v_WITHIN_DAY_EVENT_ID NUMBER(9);
  v_RECORD_COUNT  NUMBER(9) := 0;

  v_POD_ID           NUMBER(9);
  v_XML_REP          xmltype;
  v_SCHEDULE_TYPE_ID NUMBER(9);
  v_SCHED_IDS        NUMBER_COLLECTION;

  CURSOR c_XML IS
    SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
         TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
         EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') "JURISDICTION",
         EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') "RESOURCE_TYPE",
         EXTRACTVALUE(VALUE(T), '//DATAROW/SCHEDULE_MW') "SCHEDULE_MW",
         TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/POST_TIME'), 'DD/MM/YYYY HH24:MI:SS') POST_TIME
    FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
  v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);

  p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

  --get the id for schedule id for the 'Indicative Actual' statement type external sytem ident
  CASE g_REPORT_NAME
    WHEN k_INDIC_ACT_RPT_NAME THEN
      v_INDIC_ACT_EVENT_ID  := p_LOGGER.LAST_EVENT_ID;
      v_WITHIN_DAY_EVENT_ID := NULL;
      v_SCHED_IDS              := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INDIC_A,
                                      EC.ED_STATEMENT_TYPE,
                                      EC.ES_SEM,
                                      MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);
    WHEN k_WITHIN_DAY_RPT_NAME THEN
      v_INDIC_ACT_EVENT_ID  := NULL;
      v_WITHIN_DAY_EVENT_ID := p_LOGGER.LAST_EVENT_ID;
      v_SCHED_IDS              := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_WN_DAY_ACT,
                                      EC.ED_STATEMENT_TYPE,
                                      EC.ES_SEM,
                                      MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);
    ELSE
      p_LOGGER.LOG_ERROR(g_REPORT_NAME || 'is not a recognized report name!');
  END CASE;

  FOR v_XML IN c_XML LOOP
    --calculate the SCHEDULE_DATE
    v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

    --get POD_ID
    v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

    --loop through the schedule type ids
    FOR I IN 1 .. v_SCHED_IDS.COUNT LOOP
      v_SCHEDULE_TYPE_ID := v_SCHED_IDS(I);

      UPDATE SEM_ACTUAL_SCHEDULES
      SET RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
        JURISDICTION = v_XML.JURISDICTION,
        SCHEDULE_MW = v_XML.SCHEDULE_MW,
        INDIC_ACT_EVENT_ID = v_INDIC_ACT_EVENT_ID,
        WITHIN_DAY_EVENT_ID = v_WITHIN_DAY_EVENT_ID
      WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
      AND POD_ID = v_POD_ID
      AND POST_TIME = v_XML.POST_TIME
      AND SCHEDULE_TYPE = v_SCHEDULE_TYPE_ID;

      IF SQL%NOTFOUND THEN
        INSERT INTO SEM_ACTUAL_SCHEDULES
          (SCHEDULE_DATE,
           POD_ID,
           SCHEDULE_TYPE,
           RESOURCE_TYPE,
           JURISDICTION,
           SCHEDULE_MW,
           POST_TIME,
           INDIC_ACT_EVENT_ID,
           WITHIN_DAY_EVENT_ID)
        VALUES
          (v_SCHEDULE_DATE,
           v_POD_ID,
           v_SCHEDULE_TYPE_ID,
           v_XML.RESOURCE_TYPE,
           v_XML.JURISDICTION,
           v_XML.SCHEDULE_MW,
           v_XML.POST_TIME,
           v_INDIC_ACT_EVENT_ID,
           v_WITHIN_DAY_EVENT_ID);
      END IF;

    END LOOP;
    v_RECORD_COUNT := v_RECORD_COUNT + 1;
  END LOOP;
  p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ' report: ' || MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END IMPORT_ACTUAL_SCHEDULES;
------------------------------------------------------------------------------------------
PROCEDURE IMPORT_INDIC_ACTUAL_SCHED
(
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER

) AS

    v_SCHEDULE_DATE    DATE;
    v_SEM_ACCOUNT_NAME EXTERNAL_CREDENTIALS.EXTERNAL_ACCOUNT_NAME%TYPE;
    v_POD_ID           NUMBER(9);
    v_TXN_TYPE         INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_TXN_ID           NUMBER(9);
    v_XML_REP          xmltype;
    v_STATUS           NUMBER;
    v_SCHEDULE_TYPE_ID NUMBER(9);
    v_SCHED_IDS        NUMBER_COLLECTION;
    v_RO_RESOURCE_TYPE TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;

    --ignore JURISDICTION, POST_TIME, TRADE_DATE
  -- 25-nov-2007, MPUD4 documents hour and interval as TRADE_*, but it's really
  -- the usual and expected DELIVERY_*. Found and fixed as part of testing for BZ 15082.
    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               --EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_HOUR') "TRADE_HOUR",
               --EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_INTERVAL') "TRADE_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SCHEDULE_MW') "SCHEDULE_MW"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN

    p_LOGGER.EXCHANGE_NAME := 'Import Daily Indicative Actual Schedules report';
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);


    -- grab the account info from the headed of XML
    SELECT EXTRACTVALUE(v_XML_REP,
                        'REPORT/REPORT_HEADER/HEADROW/' || g_PARTICIPANT_ELEMENT)
    INTO v_SEM_ACCOUNT_NAME
    FROM DUAL;

    --get the id for schedule id for the 'Indicative Actual' statement type external sytem ident
  v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_MKT_SCHED_INDIC_A,
                                                     EC.ED_STATEMENT_TYPE,
                                                     EC.ES_SEM,
                                                     MM_SEM_UTIL.g_STATEMENT_TYPE_MKT_SCHED);



    FOR v_XML IN c_XML LOOP
    --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);

    --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

    --get the associated entity attribute of the ServicePoint
      v_RO_RESOURCE_TYPE := RO.GET_ENTITY_ATTRIBUTE('Resource Type', EC.ED_SERVICE_POINT, v_POD_ID, TRUNC(v_SCHEDULE_DATE));

    --determine the Transaction_Type based on resource type
        IF LENGTH(v_RO_RESOURCE_TYPE) = 4 THEN
            v_TXN_TYPE := 'Generation';
        ELSIF LENGTH(v_RO_RESOURCE_TYPE) = 2 AND
              SUBSTR(UPPER(v_RO_RESOURCE_TYPE), 1, 1) = 'S' THEN
            v_TXN_TYPE := 'Load';
        END IF;

        --get Transaction ID
        v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(p_TRANSACTION_TYPE    => v_TXN_TYPE,
                                                   p_RESOURCE_NAME       => v_XML.RESOURCE_ID,
                                                   p_CREATE_IF_NOT_FOUND => TRUE,
                                                   p_TRANSACTION_NAME    => v_XML.RESOURCE_ID ||
                                                                            ':Market Schedule',
                                                   p_EXTERNAL_IDENTIFIER => NULL,
                                                   p_ACCOUNT_NAME        => v_SEM_ACCOUNT_NAME);


        --loop through the schedule type ids
        FOR I IN 1 .. v_SCHED_IDS.COUNT LOOP
            v_SCHEDULE_TYPE_ID := v_SCHED_IDS(I);
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID,
                                p_SCHEDULE_TYPE  => v_SCHEDULE_TYPE_ID,
                                p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                                p_AS_OF_DATE     => LOW_DATE,
                                p_AMOUNT         => v_XML.SCHEDULE_MW,
                                p_PRICE          => NULL,
                                p_STATUS         => v_STATUS);

        END LOOP;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Indicative Actual Schedules report: ' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_INDIC_ACTUAL_SCHED;
------------------------------------------------------------------------------------------
PROCEDURE IMPORT_METER_SUMMARY
(
    p_REPORT IN CLOB,
    p_RUN_TYPE IN VARCHAR2,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_XML_REP       XMLTYPE;
    v_REPORT_NAME   VARCHAR2(32);
    v_SCHEDULE_DATE DATE;

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/TOTAL_GENERATION') "TOTAL_GENERATION",
               EXTRACTVALUE(VALUE(T), '//DATAROW/TOTAL_LOAD') "TOTAL_LOAD"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN

    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);
    -- grab the account info from the headed of XML
    SELECT EXTRACTVALUE(v_XML_REP, 'REPORT/REPORT_HEADER/HEADROW/REPORT_NAME')
    INTO v_REPORT_NAME
    FROM DUAL;

    /*v_PERIODICITY          := SUBSTR(v_REPORT_NAME,
                                     INSTR(v_REPORT_NAME, 'D', 1, 3),
                                     2);*/
    p_LOGGER.EXCHANGE_NAME := 'Import Meter Data Summary - ' || p_RUN_TYPE ||
                              'report';

    FOR v_XML IN c_XML LOOP

        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);

        UPDATE SEM_METER_SUMMARY
        SET TOTAL_GEN   = v_XML.TOTAL_GENERATION,
            TOTAL_LOAD  = v_XML.TOTAL_LOAD,
            EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHERE PERIODICITY = p_RUN_TYPE
        AND SCHEDULE_DATE = v_SCHEDULE_DATE;

        IF SQL%NOTFOUND THEN
            --Try insert into SEM_METER_SUMMARY table
            INSERT INTO SEM_METER_SUMMARY
                (PERIODICITY,
                 SCHEDULE_DATE,
                 TOTAL_GEN,
                 TOTAL_LOAD,
                 EVENT_ID)
            VALUES
                (p_RUN_TYPE,
                 v_SCHEDULE_DATE,
                 v_XML.TOTAL_GENERATION,
                 v_XML.TOTAL_LOAD,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Meter Data Summary - ' ||
                           p_RUN_TYPE || 'report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_METER_SUMMARY;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_METER_DETAIL
(
    p_REPORT IN CLOB,
    p_RUN_TYPE IN VARCHAR2,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_XML_REP       XMLTYPE;
    v_REPORT_NAME   VARCHAR2(32);
    v_SCHEDULE_DATE DATE;
    v_POD_ID        NUMBER(9);

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_TYPE') "RESOURCE_TYPE",
               EXTRACTVALUE(VALUE(T), '//DATAROW/JURISDICTION') "JURISDICTION",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/METERED_MW') "METERED_MW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/METER_TRANSMISSION_TYPE') "METER_TRANSMISSION_TYPE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN

    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);
    -- grab the Periodicity info from the headed of XML
    SELECT EXTRACTVALUE(v_XML_REP, 'REPORT/REPORT_HEADER/HEADROW/REPORT_NAME')
    INTO v_REPORT_NAME
    FROM DUAL;

   /* v_PERIODICITY          := SUBSTR(v_REPORT_NAME,
                                     INSTR(v_REPORT_NAME, 'D', 1, 3),
                                     2);*/
    p_LOGGER.EXCHANGE_NAME := 'Import Meter Data Detail - ' || p_RUN_TYPE ||'report';

    FOR v_XML IN c_XML LOOP
        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);

        UPDATE SEM_METER_DETAIL
        SET JURISDICTION = v_XML.JURISDICTION,
            RESOURCE_TYPE = v_XML.RESOURCE_TYPE,
            METERED_MW   = v_XML.METERED_MW,
            METER_TRANSMISSION_TYPE  = v_XML.METER_TRANSMISSION_TYPE,
            EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHERE PERIODICITY = p_RUN_TYPE
        AND SCHEDULE_DATE = v_SCHEDULE_DATE
        AND POD_ID = v_POD_ID;

        IF SQL%NOTFOUND THEN
            --Try insert into SEM_METER_DETAIL table
            INSERT INTO SEM_METER_DETAIL
                (PERIODICITY,
                 SCHEDULE_DATE,
                 JURISDICTION,
                 POD_ID,
                 RESOURCE_TYPE,
                 METERED_MW,
                 METER_TRANSMISSION_TYPE,
                 EVENT_ID)
            VALUES
                (p_RUN_TYPE,
                 v_SCHEDULE_DATE,
                 v_XML.JURISDICTION,
                 v_POD_ID,
                 v_XML.RESOURCE_TYPE,
                 v_XML.METERED_MW,
                 v_XML.METER_TRANSMISSION_TYPE,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Meter Data Detail - ' ||
                           p_RUN_TYPE || 'report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_METER_DETAIL;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IC_NOMINATIONS
(
    p_REPORT   IN CLOB,
    p_RUN_TYPE_IDENT IN VARCHAR2,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_XML_REP          XMLTYPE;
    v_SCHEDULE_DATE    DATE;
    v_SEM_ACCOUNT_NAME EXTERNAL_CREDENTIALS.EXTERNAL_ACCOUNT_NAME%TYPE;
    v_TXN_ID           NUMBER(9);
    v_EXTID_MKT_SCHED  EXTERNAL_SYSTEM_IDENTIFIER.EXTERNAL_IDENTIFIER%TYPE;
    v_EFFECTIVE_GATE_WINDOW VARCHAR2(8);
    v_RUN_TYPE_SUFFIX    VARCHAR2(8);
    v_SCHED_IDS        NUMBER_COLLECTION := NUMBER_COLLECTION();
    v_SCHEDULE_TYPE_ID NUMBER(9);
    v_STATUS           NUMBER;
    v_IS_IDT_FILE      NUMBER(1) := 1;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE')) "RUN_TYPE",
               TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/GATE_WINDOW')) "GATE_WINDOW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/UNIT_NOMINATION') "UNIT_NOMINATION"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN

    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);
    p_LOGGER.EXCHANGE_NAME := 'Import IC User Nominations - ' || p_RUN_TYPE_IDENT || ' report';

    -- find if the
    SELECT CASE WHEN EXTRACTVALUE(v_XML_REP,'REPORT/REPORT_BODY/PAGE/DATAROW[@num="1"]/RUN_TYPE') IS NULL THEN 0 ELSE 1 END
    INTO v_IS_IDT_FILE FROM DUAL;

    v_EXTID_MKT_SCHED      := UPPER(p_RUN_TYPE_IDENT);
    p_LOGGER.LOG_INFO('v_EXTID_MKT_SCHED:' || v_EXTID_MKT_SCHED);

    -- grab the account info from the headed of XML
    SELECT EXTRACTVALUE(v_XML_REP,'REPORT/REPORT_HEADER/HEADROW/' || g_PARTICIPANT_ELEMENT)
    INTO v_SEM_ACCOUNT_NAME FROM DUAL;

    -- Move the v_EFFECTIVE_GATE_WINDOW from the IF..ELSIF.. loop to outside, here.
    v_EFFECTIVE_GATE_WINDOW := CASE WHEN v_IS_IDT_FILE = 0 THEN MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR ELSE '' END;

    --get the id for schedule ids for each statement type external system identifier
    IF  v_EXTID_MKT_SCHED = 'EX-ANTE' THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_EA,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
    ELSIF  v_EXTID_MKT_SCHED = 'EX-ANTE EA2' THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_EA2,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
    ELSIF  v_EXTID_MKT_SCHED = 'EX-ANTE WD1' THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_WD1,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
    ELSIF v_EXTID_MKT_SCHED = 'MODIFIED' THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_MOD,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
    ELSIF v_EXTID_MKT_SCHED = 'REVISED MODIFIED' THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_REV_MOD,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
    ELSIF v_EXTID_MKT_SCHED = 'INDICATIVE EX-POST' THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_INDIC_EP,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
    ELSIF v_EXTID_MKT_SCHED = 'INITIAL EX-POST' THEN
        v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_INIT_EP,
                                                         EC.ED_STATEMENT_TYPE,
                                                         EC.ES_SEM,
                                                         MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
    END IF;

     p_LOGGER.LOG_INFO(' v_SCHED_IDS Count' || v_SCHED_IDS.Count);

    FOR v_XML IN c_XML LOOP
        -- If there is a <RUN_TYPE> element in each <DATAROW> and it has values EA, EA2, or WD1 then..
        IF v_XML.RUN_TYPE IS NOT NULL THEN
            v_RUN_TYPE_SUFFIX := CASE WHEN v_XML.RUN_TYPE = MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR THEN '' ELSE ' ' || v_XML.RUN_TYPE END;

            IF v_EXTID_MKT_SCHED = 'MODIFIED' THEN
                v_SCHED_IDS.DELETE;
                v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_MOD || v_RUN_TYPE_SUFFIX,
                                                                 EC.ED_STATEMENT_TYPE,
                                                                 EC.ES_SEM,
                                                                 MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
            ELSIF v_EXTID_MKT_SCHED = 'REVISED MODIFIED' THEN
                v_SCHED_IDS.DELETE;
                v_SCHED_IDS := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(MM_SEM_UTIL.g_EXTID_USER_NOMS_REV_MOD || v_RUN_TYPE_SUFFIX,
                                                                 EC.ED_STATEMENT_TYPE,
                                                                 EC.ES_SEM,
                                                                 MM_SEM_UTIL.g_STATEMENT_TYPE_USER_NOMS);
            END IF;
        END IF;

        p_LOGGER.LOG_DEBUG('Creating transaction with following attributes:' || UTL_TCP.CRLF ||
                          ' Transaction Type: ' || 'Nomination' || UTL_TCP.CRLF ||
                          ' Resource Name: ' || v_XML.RESOURCE_ID || UTL_TCP.CRLF ||
                          ' Agreement Type: ' || NVL(v_XML.GATE_WINDOW, v_EFFECTIVE_GATE_WINDOW) || UTL_TCP.CRLF ||
                          ' Transaction Name: ' || v_XML.RESOURCE_ID || ':Interconnector User Nomination' ||
                                               NVL(v_XML.GATE_WINDOW, v_EFFECTIVE_GATE_WINDOW) || UTL_TCP.CRLF ||
                          ' External Identifier: ' || 'Nomination: ' || v_XML.RESOURCE_ID || NVL(v_XML.GATE_WINDOW, v_EFFECTIVE_GATE_WINDOW) || UTL_TCP.CRLF ||
                          ' Account Name: ' || v_SEM_ACCOUNT_NAME || UTL_TCP.CRLF ||
                          ' Is IDT File: ' || v_IS_IDT_FILE);

        v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(MM_SEM_UTIL.c_TXN_TYPE_NOMINATION, v_XML.RESOURCE_ID, MM_SEM_UTIL.c_COMMODITY_ENERGY, NVL(v_XML.GATE_WINDOW, v_EFFECTIVE_GATE_WINDOW));
        IF v_TXN_ID IS NULL THEN
            --get Transaction ID
            v_TXN_ID := MM_SEM_UTIL.GET_TRANSACTION_ID(p_TRANSACTION_TYPE    => MM_SEM_UTIL.c_TXN_TYPE_NOMINATION,
                                                       p_RESOURCE_NAME       => v_XML.RESOURCE_ID,
                                                       p_CREATE_IF_NOT_FOUND => TRUE,
                                                       p_AGREEMENT_TYPE => NVL(v_XML.GATE_WINDOW, v_EFFECTIVE_GATE_WINDOW),
                                                       p_TRANSACTION_NAME    => v_XML.RESOURCE_ID ||
                                                                                ':Interconnector User Nomination' || ':' ||
                                                                                NVL(v_XML.GATE_WINDOW, v_EFFECTIVE_GATE_WINDOW),
                                                       p_EXTERNAL_IDENTIFIER => 'Nomination: ' ||
                                                                                v_XML.RESOURCE_ID || ':' ||
                                                                                NVL(v_XML.GATE_WINDOW, v_EFFECTIVE_GATE_WINDOW),
                                                       p_ACCOUNT_NAME        => v_SEM_ACCOUNT_NAME);
        END IF;
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);

        --loop through the schedule type ids
        FOR I IN 1 .. v_SCHED_IDS.COUNT LOOP
            v_SCHEDULE_TYPE_ID := v_SCHED_IDS(I);
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => v_TXN_ID,
                                p_SCHEDULE_TYPE  => v_SCHEDULE_TYPE_ID,
                                p_SCHEDULE_STATE => GA.INTERNAL_STATE,
                                p_SCHEDULE_DATE  => v_SCHEDULE_DATE,
                                p_AS_OF_DATE     => LOW_DATE,
                                p_AMOUNT         => v_XML.UNIT_NOMINATION,
                                p_PRICE          => NULL,
                                p_STATUS         => v_STATUS);
        END LOOP;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Interconnector User Nominations - ' ||
                           p_RUN_TYPE_IDENT || 'report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_IC_NOMINATIONS;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IC_NOMINATIONS_PUB(p_IMPORT_FILE IN CLOB,
                  p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) AS

  v_PSE_ID        NUMBER(9);
  v_POD_ID        NUMBER(9);
  v_SCHEDULE_DATE DATE;
  v_XML_REP       XMLTYPE;
  v_RECORD_COUNT  NUMBER(9) := 0;

  CURSOR c_XML IS
    SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') TRADE_DATE,
         EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
         EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
         TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
         EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
         NVL(TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE')), MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR) RUN_TYPE,
         NVL(TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/GATE_WINDOW')), MM_SEM_UTIL.g_EXTID_MKT_SCHED_EA_ABR) GATE_WINDOW,
         EXTRACTVALUE(VALUE(T), '//DATAROW/UNIT_NOMINATION') UNIT_NOMINATION
    FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
  v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
  p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

  FOR v_XML IN c_XML LOOP
    --calculate the SCHEDULE_DATE
    v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                             v_XML.DELIVERY_HOUR,
                             v_XML.DELIVERY_INTERVAL);

    --get POD_ID
    v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_NAME, TRUE);

    -- get PSE_ID
    v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_NAME, TRUE);

    MERGE INTO SEM_IC_NOMINATIONS S
    USING (SELECT v_PSE_ID PSE_ID,
            v_POD_ID POD_ID,
            v_SCHEDULE_DATE SCHEDULE_DATE,
            v_XML.RUN_TYPE RUN_TYPE,
			v_XML.GATE_WINDOW GATE_WINDOW,
            v_XML.UNIT_NOMINATION UNIT_NOMINATION,
            p_LOGGER.LAST_EVENT_ID EVENT_ID
         FROM DUAL) A
    ON (A.POD_ID = S.POD_ID AND A.PSE_ID = S.PSE_ID AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND A.SCHEDULE_DATE = S.SCHEDULE_DATE AND
		A.RUN_TYPE = S.RUN_TYPE AND A.GATE_WINDOW = S.GATE_WINDOW)
    WHEN MATCHED THEN
      UPDATE
      SET S.UNIT_NOMINATION = v_XML.UNIT_NOMINATION, S.EVENT_ID = p_LOGGER.LAST_EVENT_ID
    WHEN NOT MATCHED THEN
      INSERT
        (PSE_ID, POD_ID, SCHEDULE_DATE, RUN_TYPE, GATE_WINDOW, UNIT_NOMINATION, EVENT_ID)
      VALUES
        (v_PSE_ID,
         v_POD_ID,
         v_SCHEDULE_DATE,
		 v_XML.RUN_TYPE,
		 v_XML.GATE_WINDOW,
         v_XML.UNIT_NOMINATION,
         p_LOGGER.LAST_EVENT_ID);

    v_RECORD_COUNT := v_RECORD_COUNT + 1;
  END LOOP;
  p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' ||
               MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END IMPORT_IC_NOMINATIONS_PUB;
--------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_INACTIVE_MKT_PART
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
  -- 21-nov-2007, jbc: deleted references to USER_NAME, SYSTEM_ID, and REQUEST_TYPE fields.
  -- these were removed in MPUD4.0 (but not caught until now). Fixes BZ 15072.
    v_XML_REP       XMLTYPE;
    v_PSE_ID        NUMBER(9);

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EFF_DATE'), 'DD/MM/YYYY') "EFF_DATE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/EXP_DATE'),'DD/MM/YYYY') "EXP_DATE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN

    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);

    p_LOGGER.EXCHANGE_NAME := 'Import List of Suspended/Terminated Market Participants report';

    FOR v_XML IN c_XML LOOP
        --get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);

        UPDATE SEM_INACTIVE_PART
        SET EXP_DATE   = v_XML.EXP_DATE,
            EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHERE PSE_ID = v_PSE_ID
        AND EFF_DATE = v_XML.EFF_DATE;

        IF SQL%NOTFOUND THEN
            --Try insert into SEM_INACTIVE_PART table
            INSERT INTO SEM_INACTIVE_PART
                (PSE_ID,
                 EFF_DATE,
                 EXP_DATE,
                 EVENT_ID)
            VALUES
                (v_PSE_ID,
                 v_XML.EFF_DATE,
                 v_XML.EXP_DATE,
                p_LOGGER.LAST_EVENT_ID);
        END IF;

    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing List of Suspended/Terminated Market Participants report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_INACTIVE_MKT_PART;
---------------------------------------------------------------------------------------
PROCEDURE IMPORT_MO_NOTIFICATIONS
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_XML_REP       XMLTYPE;
    v_TRADE_DATE    DATE;
    v_COUNT         BINARY_INTEGER;
    v_MESSAGE_ID    NUMBER(9);
    v_MESSAGE       VARCHAR2(500);


    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/ISSUE_DATE'), 'DD/MM/YYYY HH24:MI:SS') "ISSUE_DATE",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SEVERITY') "SEVERITY",
               EXTRACTVALUE(VALUE(T), '//DATAROW/MESSAGE') "MESSAGE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN

    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);

    p_LOGGER.EXCHANGE_NAME := 'Import Daily Market Operations Notifications report';

    -- grab the TRADE_DATE info from the header
    SELECT TO_DATE(EXTRACTVALUE(v_XML_REP,
                        'REPORT/REPORT_HEADER/HEADROW/TRADE_DATE'),'YYYYMMDD')
    INTO v_TRADE_DATE
    FROM DUAL;

    FOR v_XML IN c_XML LOOP
        --get PSE_ID
        --v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);

        --LOOKUP IN MEX_MESSAGES BASED ON ALL REPORT FIELDS ...
    -- 21-nov-2007, jbc: contrary to the above comment, we weren't doing the
    -- lookup based on ALL fields. Added clause for MESSAGE_TEXT, and fixed BZ 15076.
        SELECT COUNT(*)
          INTO v_COUNT
          FROM MEX_MESSAGE M
         WHERE M.MESSAGE_DATE = v_XML.ISSUE_DATE
           AND M.MARKET_OPERATOR = 'SEM'
           AND M.MESSAGE_REALM = v_XML.SEVERITY
           AND M.EFFECTIVE_DATE = v_TRADE_DATE
           AND M.TERMINATION_DATE = v_TRADE_DATE
           AND M.MESSAGE_SOURCE = 'SEM'
           AND M.MESSAGE_DESTINATION = v_XML.PARTICIPANT_ID
       AND M.MESSAGE_TEXT = v_XML.MESSAGE;

          IF v_COUNT = 0 THEN
            SELECT OID.NEXTVAL INTO v_MESSAGE_ID FROM DUAL;
            INSERT INTO MEX_MESSAGE
            VALUES
              (v_MESSAGE_ID, v_XML.ISSUE_DATE, 'SEM', v_XML.SEVERITY, NULL, v_TRADE_DATE, v_TRADE_DATE,
              'SEM', v_XML.PARTICIPANT_ID, v_XML.MESSAGE, SYSDATE);
          END IF;


          --Raise Alerts
          v_MESSAGE := 'Issue Date: ' || v_XML.ISSUE_DATE || UTL_TCP.CRLF ||
                       'TO: ' || v_XML.PARTICIPANT_ID || UTL_TCP.CRLF ||
                       'Severity: ' || v_XML.SEVERITY || UTL_TCP.CRLF ||
                       v_XML.MESSAGE;

          MM_SEM_UTIL.RAISE_ALERTS(p_TYPE => g_ALERT_TYPE_NOTIF,
                                   p_NAME => v_XML.SEVERITY,
                                   p_LOGGER => p_LOGGER,
                                   p_MSG => v_MESSAGE,
                                   p_FATAL => FALSE);


    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily Market Operations Notifications report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);

        RAISE;

END IMPORT_MO_NOTIFICATIONS;
---------------------------------------------------------------------------------------
PROCEDURE IMPORT_SYSTEM_FREQUENCY
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_XML_REP       XMLTYPE;
    v_PSE_ID        NUMBER(9);
    v_SCHEDULE_DATE DATE;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/NORMAL_FREQUENCY') "NORMAL_FREQUENCY",
               EXTRACTVALUE(VALUE(T), '//DATAROW/AVERAGE_FREQUENCY') "AVERAGE_FREQUENCY"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN

    v_XML_REP := XMLTYPE.CREATEXML(p_REPORT);

    p_LOGGER.EXCHANGE_NAME := 'Import Daily SO System Frequency report';

    FOR v_XML IN c_XML LOOP
        --get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);

        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);

        UPDATE SEM_SYSTEM_FREQUENCY
        SET NORMAL_FREQUENCY   = v_XML.NORMAL_FREQUENCY,
            AVERAGE_FREQUENCY = v_XML.AVERAGE_FREQUENCY,
            EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHERE PSE_ID = v_PSE_ID
        AND SCHEDULE_DATE = v_SCHEDULE_DATE;

        IF SQL%NOTFOUND THEN
            --Try insert into SEM_SYSTEM_FREQUNCY table
            INSERT INTO SEM_SYSTEM_FREQUENCY
                (PSE_ID,
                 SCHEDULE_DATE,
                 NORMAL_FREQUENCY,
                 AVERAGE_FREQUENCY,
                 EVENT_ID)
            VALUES
                (v_PSE_ID,
                 v_SCHEDULE_DATE,
                 v_XML.NORMAL_FREQUENCY,
                 v_XML.AVERAGE_FREQUENCY,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;
    END LOOP;

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Daily SO System Frequency report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;

END IMPORT_SYSTEM_FREQUENCY;
---------------------------------------------------------------------------------------
PROCEDURE IMPORT_AVAILABLE_CREDIT_COVER
  (
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS
  v_XML_REP XMLTYPE;
  v_ACC_ID SEM_CREDIT_ACC_SUMMARY.ACC_ID%TYPE;
  v_SCHEDULE_DATE SEM_CREDIT_ACC_INTERVAL.DELIVERY_DATE%TYPE;
  v_RECORD_COUNT NUMBER(9) := 0;
  CURSOR c_XML IS
    SELECT CASE
               WHEN TRIM(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADING_DAY')) = '-' THEN 1
               ELSE 0
           END IS_SUMMARY,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/BATCH_ID')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/BATCH_ID'))
           END BATCH_ID,
           TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/ACC_REPORT_TIME'), 'DD/MM/YYYY HH24:MI:SS') ACC_REPORT_TIME,
           EXTRACTVALUE(VALUE(T), '//DATAROW/CODE_PARTICIPANT_NAME') CODE_PARTICIPANT_NAME,
           TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') TRADE_DATE,
           EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') RUN_TYPE,
           EXTRACTVALUE(VALUE(T), '//DATAROW/REASON') REASON,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/ACC_BALANCE')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/ACC_BALANCE'))
           END ACC_BALANCE,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/ECPI_REPORT_ID')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/ECPI_REPORT_ID'))
           END ECPI_REPORT_ID,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/ECPI')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/ECPI'))
           END ECPI,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/RCC_REPORT_ID')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/RCC_REPORT_ID'))
           END RCC_REPORT_ID,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/POSTED_CREDIT_COVER')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/POSTED_CREDIT_COVER'))
           END POSTED_CREDIT_COVER,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/S_REQ_CREDIT_COVER')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/S_REQ_CREDIT_COVER'))
           END S_REQ_CREDIT_COVER,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/G_REQ_CREDIT_COVER')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/G_REQ_CREDIT_COVER'))
           END G_REQ_CREDIT_COVER,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/FIXED_CREDIT_COVER')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/FIXED_CREDIT_COVER'))
           END FIXED_CREDIT_COVER,
           TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/E_LAST_SETTLEDAY'), 'DD/MM/YYYY') E_LAST_SETTLEDAY,
           TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/C_LAST_SETTLEDAY'), 'DD/MM/YYYY') C_LAST_SETTLEDAY,
           EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
           EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
           EXTRACTVALUE(VALUE(T), '//DATAROW/TRADING_DAY') TRADING_DAY,
           EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE') DELIVERY_DATE,
           EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
           EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/ETEV')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/ETEV'))
           END ETEV,
           CASE EXTRACTVALUE(VALUE(T), '//DATAROW/CTEV')
               WHEN '-' THEN NULL
               ELSE TO_NUMBER(EXTRACTVALUE(VALUE(T), '//DATAROW/CTEV'))
           END CTEV
    FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T
    -- Order the cursor so that the summary row is the first row in the cursor
    ORDER BY IS_SUMMARY DESC, DELIVERY_DATE, DELIVERY_HOUR, DELIVERY_INTERVAL;

BEGIN
  v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);
  p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

  FOR v_XML IN c_XML LOOP
    -- Sub-daily data
    IF v_XML.IS_SUMMARY = 0  THEN
      v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(TO_DATE(v_XML.DELIVERY_DATE, 'DD/MM/YYYY'), v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

      IF v_ACC_ID IS NULL THEN
          p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' ||
                             'Unable to find the Summary Section in the XML file.');
      END IF;

      MERGE INTO SEM_CREDIT_ACC_INTERVAL SCI
      USING (SELECT v_ACC_ID AS ACC_ID,
               v_XML.PARTICIPANT_NAME PARTICIPANT_NAME,
               v_XML.RESOURCE_NAME RESOURCE_NAME,
               v_SCHEDULE_DATE DELIVERY_DATE,
               v_XML.ETEV ETEV,
               v_XML.CTEV CTEV
        FROM DUAL ) S
      ON (
        S.ACC_ID = SCI.ACC_ID AND
        UPPER(TRIM(S.PARTICIPANT_NAME)) = UPPER(TRIM(SCI.PARTICIPANT_NAME)) AND
        UPPER(TRIM(S.RESOURCE_NAME)) = UPPER(TRIM(SCI.RESOURCE_NAME)) AND
        S.DELIVERY_DATE = SCI.DELIVERY_DATE
      )
      WHEN MATCHED THEN
        UPDATE
        SET SCI.ETEV = S.ETEV,
            SCI.CTEV = S.CTEV
      WHEN NOT MATCHED THEN
        INSERT (
          ACC_ID,
          PARTICIPANT_NAME,
          RESOURCE_NAME,
          DELIVERY_DATE,
          ETEV,
          CTEV
        ) VALUES (
          S.ACC_ID,
          S.PARTICIPANT_NAME,
          S.RESOURCE_NAME,
          S.DELIVERY_DATE,
          S.ETEV,
          S.CTEV
        );
    -- Daily data
    ELSE
        MERGE INTO SEM_CREDIT_ACC_SUMMARY SCS
        USING (
          SELECT v_XML.BATCH_ID BATCH_ID,
                 v_XML.ACC_REPORT_TIME ACC_REPORT_TIME,
                 v_XML.CODE_PARTICIPANT_NAME CODE_PARTICIPANT_NAME,
                 v_XML.TRADE_DATE TRADE_DATE,
                 v_XML.RUN_TYPE RUN_TYPE,
                 v_XML.REASON REASON,
                 v_XML.ACC_BALANCE ACC_BALANCE,
                 v_XML.ECPI_REPORT_ID ECPI_REPORT_ID,
                 v_XML.ECPI ECPI,
                 v_XML.RCC_REPORT_ID RCC_REPORT_ID,
                 v_XML.POSTED_CREDIT_COVER POSTED_CREDIT_COVER,
                 v_XML.S_REQ_CREDIT_COVER S_REQ_CREDIT_COVER,
                 v_XML.G_REQ_CREDIT_COVER G_REQ_CREDIT_COVER,
                 v_XML.FIXED_CREDIT_COVER FIXED_CREDIT_COVER,
                 v_XML.E_LAST_SETTLEDAY E_LAST_SETTLEDAY,
                 v_XML.C_LAST_SETTLEDAY C_LAST_SETTLEDAY,
                 v_XML.ETEV ETEV,
                 v_XML.CTEV CTEV
          FROM DUAL) S
        ON (
          UPPER(TRIM(S.CODE_PARTICIPANT_NAME)) = UPPER(TRIM(SCS.CODE_PARTICIPANT_NAME)) AND
          S.TRADE_DATE = SCS.TRADE_DATE AND
          UPPER(TRIM(S.RUN_TYPE)) = UPPER(TRIM(SCS.RUN_TYPE))
        )
        WHEN MATCHED THEN
          UPDATE
          SET SCS.BATCH_ID = S.BATCH_ID,
              SCS.ACC_REPORT_TIME = S.ACC_REPORT_TIME,
              SCS.REASON = S.REASON,
              SCS.ACC_BALANCE = S.ACC_BALANCE,
              SCS.ECPI_REPORT_ID = S.ECPI_REPORT_ID,
              SCS.ECPI = S.ECPI,
              SCS.RCC_REPORT_ID = S.RCC_REPORT_ID,
              SCS.POSTED_CREDIT_COVER = S.POSTED_CREDIT_COVER,
              SCS.S_REQ_CREDIT_COVER = S.S_REQ_CREDIT_COVER,
              SCS.G_REQ_CREDIT_COVER = S.G_REQ_CREDIT_COVER,
              SCS.FIXED_CREDIT_COVER = S.FIXED_CREDIT_COVER,
              SCS.E_LAST_SETTLEDAY = S.E_LAST_SETTLEDAY,
              SCS.C_LAST_SETTLEDAY = S.C_LAST_SETTLEDAY,
              SCS.ETEV = S.ETEV,
              SCS.CTEV = S.CTEV
        WHEN NOT MATCHED THEN
          INSERT (
            ACC_ID,
            BATCH_ID,
            ACC_REPORT_TIME,
            CODE_PARTICIPANT_NAME,
            TRADE_DATE,
            RUN_TYPE,
            ACC_BALANCE,
            REASON,
            ECPI_REPORT_ID,
            ECPI,
            RCC_REPORT_ID,
            POSTED_CREDIT_COVER,
            S_REQ_CREDIT_COVER,
            G_REQ_CREDIT_COVER,
            FIXED_CREDIT_COVER,
            E_LAST_SETTLEDAY,
            C_LAST_SETTLEDAY,
            ETEV,
            CTEV
          ) VALUES (
            OID.NEXTVAL,
            S.BATCH_ID,
            S.ACC_REPORT_TIME,
            S.CODE_PARTICIPANT_NAME,
            S.TRADE_DATE,
            S.RUN_TYPE,
            S.ACC_BALANCE,
            S.REASON,
            S.ECPI_REPORT_ID,
            S.ECPI,
            S.RCC_REPORT_ID,
            S.POSTED_CREDIT_COVER,
            S.S_REQ_CREDIT_COVER,
            S.G_REQ_CREDIT_COVER,
            S.FIXED_CREDIT_COVER,
            S.E_LAST_SETTLEDAY,
            S.C_LAST_SETTLEDAY,
            S.ETEV,
            S.CTEV
          );

      -- Get the ACC_ID
      SELECT SCS.ACC_ID
      INTO v_ACC_ID
      FROM SEM_CREDIT_ACC_SUMMARY SCS
      WHERE SCS.TRADE_DATE = v_XML.TRADE_DATE
          AND UPPER(TRIM(SCS.RUN_TYPE)) = UPPER(TRIM(v_XML.RUN_TYPE))
          AND UPPER(TRIM(SCS.CODE_PARTICIPANT_NAME)) = UPPER(TRIM(v_XML.CODE_PARTICIPANT_NAME));

    END IF;
    v_RECORD_COUNT := v_RECORD_COUNT + 1;
  END LOOP;

  p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' ||
               MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END IMPORT_AVAILABLE_CREDIT_COVER;
---------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXCLUDED_BIDS
  (
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS
  v_XML_REP XMLTYPE;
  v_SCHEDULE_DATE SEM_EXCLUDED_BIDS.DELIVERY_DATE%TYPE;
  v_RECORD_COUNT NUMBER(9) := 0;
  CURSOR c_XML IS
    SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/PARTICIPANT_NAME') PARTICIPANT_NAME,
           EXTRACTVALUE(VALUE(T), '//DATAROW/RESOURCE_NAME') RESOURCE_NAME,
           EXTRACTVALUE(VALUE(T), '//DATAROW/GATE_WINDOW') GATE_WINDOW,
           TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY') DELIVERY_DATE,
           EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') DELIVERY_HOUR,
           EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') DELIVERY_INTERVAL,
           EXTRACTVALUE(VALUE(T), '//DATAROW/MAX_IMPORT_CAPACITY_MW') MAX_IMPORT_CAP,
           EXTRACTVALUE(VALUE(T), '//DATAROW/MAX_EXPORT_CAPACITY_MW') MAX_EXPORT_CAP,
           EXTRACTVALUE(VALUE(T), '//DATAROW/PQ_INDEX') PQ_INDEX,
           EXTRACTVALUE(VALUE(T), '//DATAROW/PRICE_VALUE') PRICE,
           EXTRACTVALUE(VALUE(T), '//DATAROW/QUANTITY') QUANTITY,
           EXTRACTVALUE(VALUE(T), '//DATAROW/EXCLUDED_FLAG') EXCLUDED_FLAG
    FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
BEGIN
  v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);
  p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';

  FOR v_XML IN c_XML LOOP
    v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE, v_XML.DELIVERY_HOUR, v_XML.DELIVERY_INTERVAL);

    MERGE INTO SEM_EXCLUDED_BIDS SEB
    USING (
      SELECT v_SCHEDULE_DATE DELIVERY_DATE,
             v_XML.GATE_WINDOW GATE_WINDOW,
             v_XML.PARTICIPANT_NAME PARTICIPANT_NAME,
             v_XML.RESOURCE_NAME RESOURCE_NAME,
             v_XML.PQ_INDEX PQ_INDEX
      FROM DUAL ) S
    ON (
      S.DELIVERY_DATE = SEB.DELIVERY_DATE AND
      S.GATE_WINDOW = SEB.GATE_WINDOW AND
      S.PARTICIPANT_NAME = SEB.PARTICIPANT_NAME AND
      S.RESOURCE_NAME = SEB.RESOURCE_NAME AND
      S.PQ_INDEX = SEB.PQ_INDEX
    )
    WHEN MATCHED THEN
      UPDATE
      SET SEB.MAX_IMPORT_CAP = v_XML.MAX_IMPORT_CAP,
          SEB.MAX_EXPORT_CAP = v_XML.MAX_EXPORT_CAP,
          SEB.PRICE = v_XML.PRICE,
          SEB.QUANTITY = v_XML.QUANTITY,
          SEB.EXCLUDED_FLAG = v_XML.EXCLUDED_FLAG
    WHEN NOT MATCHED THEN
      INSERT (
        DELIVERY_DATE,
        GATE_WINDOW,
        PARTICIPANT_NAME,
        RESOURCE_NAME,
        PQ_INDEX,
        MAX_IMPORT_CAP,
        MAX_EXPORT_CAP,
        PRICE,
        QUANTITY,
        EXCLUDED_FLAG
      ) VALUES (
        v_SCHEDULE_DATE,
        v_XML.GATE_WINDOW,
        v_XML.PARTICIPANT_NAME,
        v_XML.RESOURCE_NAME,
        v_XML.PQ_INDEX,
        v_XML.MAX_IMPORT_CAP,
        v_XML.MAX_EXPORT_CAP,
        v_XML.PRICE,
        v_XML.QUANTITY,
        v_XML.EXCLUDED_FLAG
      );

    v_RECORD_COUNT := v_RECORD_COUNT + 1;
  END LOOP;

  p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' ||
               MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END IMPORT_EXCLUDED_BIDS;
--------------------------------------------------------------------------------------------
PROCEDURE IMPORT_IC_NET_ACTUAL
(
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
    v_POD_ID        NUMBER(9);
    v_PSE_ID        NUMBER(9);
    v_EXCHANGE_NAME VARCHAR2(64);
    v_SCHEDULE_DATE DATE;
    v_XML_REP       XMLTYPE;


    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_PARTICIPANT_ELEMENT) "PARTICIPANT_ID",
               EXTRACTVALUE(VALUE(T), '//DATAROW/' || g_RESOURCE_ELEMENT) "RESOURCE_ID",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'),
                       'DD/MM/YYYY') DELIVERY_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR') "DELIVERY_HOUR",
               EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL') "DELIVERY_INTERVAL",
               EXTRACTVALUE(VALUE(T), '//DATAROW/SCHEDULE_MW') "SCHEDULE_MW",
               EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') "RUN_TYPE",
               EXTRACTVALUE(VALUE(T), '//DATAROW/GATE_WINDOW') "GATE_WINDOW"
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP,
                                       'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN

    v_XML_REP       := XMLTYPE.CREATEXML(p_REPORT);
    v_EXCHANGE_NAME := 'Import Interconnector Net Actual report';

    p_LOGGER.EXCHANGE_NAME := v_EXCHANGE_NAME;

    FOR v_XML IN c_XML LOOP
        --calculate the SCHEDULE_DATE
        v_SCHEDULE_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(v_XML.DELIVERY_DATE,
                                                         v_XML.DELIVERY_HOUR,
                                                         v_XML.DELIVERY_INTERVAL);
        --get PSE_ID
        v_PSE_ID := MM_SEM_UTIL.GET_PSE_ID(v_XML.PARTICIPANT_ID, TRUE);

        --get POD_ID
        v_POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(v_XML.RESOURCE_ID, TRUE);

        --try update
        UPDATE SEM_IC_NET_ACTUAL
        SET SCHEDULE_MW = v_XML.SCHEDULE_MW,
            EVENT_ID = p_LOGGER.LAST_EVENT_ID
        WHERE SCHEDULE_DATE = v_SCHEDULE_DATE
        AND POD_ID = v_POD_ID
        AND PSE_ID = v_PSE_ID
        AND RUN_TYPE = v_XML.RUN_TYPE
        AND GATE_WINDOW = v_XML.GATE_WINDOW;

        IF SQL%NOTFOUND THEN
            INSERT INTO SEM_IC_NET_ACTUAL
                (SCHEDULE_DATE,
                 PSE_ID,
                 POD_ID,
                 SCHEDULE_MW,
                 RUN_TYPE,
                 GATE_WINDOW,
                 EVENT_ID)
            VALUES
                (v_SCHEDULE_DATE,
                 v_PSE_ID,
                 v_POD_ID,
                 v_XML.SCHEDULE_MW,
                 v_XML.RUN_TYPE,
                 v_XML.GATE_WINDOW,
                 p_LOGGER.LAST_EVENT_ID);
        END IF;
    END LOOP;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing Interconnector Net Actual report' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_IC_NET_ACTUAL;
---------------------------------------------------------------------------------------
PROCEDURE IMPORT_TECH_OFFER_UNIT_DATA
  (
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS

BEGIN
    NULL;
END IMPORT_TECH_OFFER_UNIT_DATA;
---------------------------------------------------------------------------------
PROCEDURE IMPORT_WIND_GEN_AGG
  (
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS

BEGIN
    NULL;
END IMPORT_WIND_GEN_AGG;
---------------------------------------------------------------------------------
PROCEDURE IMPORT_MARKET_RESULTS
  (
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS
    v_XML_REP       XMLTYPE;
	c_HYPHEN	CONSTANT VARCHAR2(1) := '-';
    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') 	TRADE_DATE,
               MM_SEM_UTIL.GET_SCHEDULE_DATE(
			   		TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_DATE'), 'DD/MM/YYYY'),
               		EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_HOUR'),
               		EXTRACTVALUE(VALUE(T), '//DATAROW/DELIVERY_INTERVAL')
				) 																		SCHEDULE_DATE,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') 							RUN_TYPE,
               TO_NUMBER(DECODE(EXTRACTVALUE(VALUE(T), '//DATAROW/SYSTEM_LOAD'), c_HYPHEN, NULL, EXTRACTVALUE(VALUE(T), '//DATAROW/SYSTEM_LOAD'))) 				SYSTEM_LOAD,
			   TRIM(UPPER(EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG')))			CURRENCY_FLAG,
                CASE TRIM(UPPER(EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG')))
                   WHEN 'E' THEN
                    TO_NUMBER(DECODE(EXTRACTVALUE(VALUE(T), '//DATAROW/SMP'), c_HYPHEN, NULL,EXTRACTVALUE(VALUE(T), '//DATAROW/SMP')))
                   ELSE
                    NULL
               END 																		SMP_EURO,
               CASE TRIM(UPPER(EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG')))
                   WHEN 'P' THEN
                    TO_NUMBER(DECODE(EXTRACTVALUE(VALUE(T), '//DATAROW/SMP'), c_HYPHEN, NULL,EXTRACTVALUE(VALUE(T), '//DATAROW/SMP')))
                   ELSE
                    NULL
               END 																		SMP_GBP,
                CASE TRIM(UPPER(EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG')))
                   WHEN 'E' THEN
				   	TO_NUMBER(DECODE(EXTRACTVALUE(VALUE(T), '//DATAROW/LAMBDA'), c_HYPHEN, NULL,EXTRACTVALUE(VALUE(T), '//DATAROW/LAMBDA')))
                   ELSE
                    NULL
               END 																		LAMBDA_EURO,
               CASE TRIM(UPPER(EXTRACTVALUE(VALUE(T), '//DATAROW/CURRENCY_FLAG')))
                   WHEN 'P' THEN
                    TO_NUMBER(DECODE(EXTRACTVALUE(VALUE(T), '//DATAROW/LAMBDA'), c_HYPHEN, NULL,EXTRACTVALUE(VALUE(T), '//DATAROW/LAMBDA')))
                   ELSE
                    NULL
               END 																		LAMBDA_GBP
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;
	TYPE t_DATE IS TABLE OF SEM_MARKET_RESULTS.TRADE_DATE%TYPE;
	TYPE t_RUN_TYPE IS TABLE OF SEM_MARKET_RESULTS.RUN_TYPE%TYPE;
	TYPE t_NUMBER_VAL IS TABLE OF NUMBER;
	TYPE t_CURRENCY_FLAG IS TABLE OF VARCHAR2(1);

	v_TRADE_DATES t_DATE 	:= t_DATE();
	v_SCHEDULE_DATES t_DATE  := t_DATE();
	v_RUN_TYPES t_RUN_TYPE		:= t_RUN_TYPE();
	v_SYSTEM_LOADS t_NUMBER_VAL	:= t_NUMBER_VAL();
	v_SMP_EUROS	t_NUMBER_VAL	:= t_NUMBER_VAL();
	v_SMP_GBPS	t_NUMBER_VAL	:= t_NUMBER_VAL();
	v_LAMBDA_EUROS	t_NUMBER_VAL:= t_NUMBER_VAL();
	v_LAMBDA_GBPS	t_NUMBER_VAL:= t_NUMBER_VAL();
	v_CURRENCY_FLAGS t_CURRENCY_FLAG := t_CURRENCY_FLAG();


BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_REPORT);
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';
	-- Reason for the BULK COLLECT is for performance, besides the fact, that the SEM_MARKET_RESULTS table is
	-- having the TRADE_DATE, SCHEDULE_DATE, RUN_TYPE as the primary-key, whereas XML has 1 row each for GBP and EUR
	-- So we will do BULK COLLECT and then upsert EUR and then GBP to not cause one to overwrite the other and also
	-- to not raise any unique constraint errors
	-- Do a BULK COLLECT INTO
	OPEN c_XML;
	FETCH c_XML BULK COLLECT INTO  v_TRADE_DATES, v_SCHEDULE_DATES, v_RUN_TYPES, v_SYSTEM_LOADS, v_CURRENCY_FLAGS,
								   v_SMP_EUROS, v_SMP_GBPS, v_LAMBDA_EUROS, v_LAMBDA_GBPS;
	CLOSE c_XML;

	-- Do a 2-PASS BULK UPSERT -- EUROs first
	FORALL I IN v_TRADE_DATES.FIRST..v_TRADE_DATES.LAST
		MERGE INTO SEM_MARKET_RESULTS S
		USING (SELECT 	v_TRADE_DATES(I) 		TRADE_DATE,
						v_SCHEDULE_DATES(I)		SCHEDULE_DATE,
						v_RUN_TYPES(I)			RUN_TYPE,
						v_SYSTEM_LOADS(I)		SYSTEM_LOAD,
						v_SMP_EUROS(I)			SMP_EURO,
						v_LAMBDA_EUROS(I)		LAMBDA_EURO
			    FROM DUAL
				WHERE v_CURRENCY_FLAGS(I) = 'E'					-- for EURO
		)A
		ON(S.TRADE_DATE = A.TRADE_DATE AND S.SCHEDULE_DATE = A.SCHEDULE_DATE AND S.RUN_TYPE = A.RUN_TYPE)
		WHEN MATCHED THEN
			UPDATE SET 	S.SYSTEM_LOAD 	= v_SYSTEM_LOADS(I),
						S.SMP_EURO		= v_SMP_EUROS(I),
						S.LAMBDA_EURO	= v_LAMBDA_EUROS(I)
		WHEN NOT MATCHED THEN
			INSERT (
					S.TRADE_DATE,
					S.SCHEDULE_DATE,
					S.RUN_TYPE,
					S.SYSTEM_LOAD,
					S.SMP_EURO,
					S.LAMBDA_EURO
			)VALUES(
					A.TRADE_DATE,
					A.SCHEDULE_DATE,
					A.RUN_TYPE,
					A.SYSTEM_LOAD,
					A.SMP_EURO,
					A.LAMBDA_EURO
			);
	-- 2ND PASS BULK UPSERT -- For SMPs this time
	FORALL I IN v_TRADE_DATES.FIRST..v_TRADE_DATES.LAST
		MERGE INTO SEM_MARKET_RESULTS S
		 USING (SELECT 	v_TRADE_DATES(I) 		TRADE_DATE,
						v_SCHEDULE_DATES(I)		SCHEDULE_DATE,
						v_RUN_TYPES(I)			RUN_TYPE,
						v_SYSTEM_LOADS(I)		SYSTEM_LOAD,
						v_SMP_GBPS(I)			SMP_GBP,
						v_LAMBDA_GBPS(I)		LAMBDA_GBP
			    FROM DUAL
				WHERE v_CURRENCY_FLAGS(I) = 'P'						-- for GBP
		)A
		ON(S.TRADE_DATE = A.TRADE_DATE AND S.SCHEDULE_DATE = A.SCHEDULE_DATE AND S.RUN_TYPE = A.RUN_TYPE)
		WHEN MATCHED THEN
			UPDATE SET 	S.SYSTEM_LOAD 	= v_SYSTEM_LOADS(I),
						S.SMP_GBP		= v_SMP_GBPS(I),
						S.LAMBDA_GBP	= v_LAMBDA_GBPS(I)
		WHEN NOT MATCHED THEN
			INSERT (
					S.TRADE_DATE,
					S.SCHEDULE_DATE,
					S.RUN_TYPE,
					S.SYSTEM_LOAD,
					S.SMP_GBP,
					S.LAMBDA_GBP
			)VALUES(
					A.TRADE_DATE,
					A.SCHEDULE_DATE,
					A.RUN_TYPE,
					A.SYSTEM_LOAD,
					A.SMP_GBP,
					A.LAMBDA_GBP
			);

	-- Log the record count
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_TRADE_DATES.COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_MARKET_RESULTS;
---------------------------------------------------------------------------------
PROCEDURE KPI_GATE_INFO
  (
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS

BEGIN
    NULL;
END KPI_GATE_INFO;
---------------------------------------------------------------------------------
PROCEDURE IMPORT_KPI_SCHEDULES
  (
    p_REPORT   IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS

BEGIN
    NULL;
END IMPORT_KPI_SCHEDULES;
---------------------------------------------------------------------------------
PROCEDURE IMPORT_MSP_CANCEL
  (
    p_IMPORT_FILE IN CLOB,
    p_LOGGER   IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS
    v_XML_REP       XMLTYPE;
    v_RECORD_COUNT NUMBER(9) := 0;

    CURSOR c_XML IS
        SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/CANCELLATION_DATETIME'), 'DD/MM/YYYY HH24:MI:SS') CANCELLATION_DATETIME,
               EXTRACTVALUE(VALUE(T), '//DATAROW/RUN_TYPE') RUN_TYPE,
               TO_DATE(EXTRACTVALUE(VALUE(T), '//DATAROW/TRADE_DATE'), 'DD/MM/YYYY') TRADE_DATE
        FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_REP, 'REPORT/REPORT_BODY/PAGE/DATAROW'))) T;

BEGIN
    v_XML_REP              := XMLTYPE.CREATEXML(p_IMPORT_FILE);
    --p_LOGGER.EXCHANGE_NAME := 'Import ' || g_REPORT_NAME || ' report';
    p_LOGGER.EXCHANGE_NAME := 'Import ' || 'PUB_MSP_Cancel' || ' report';

    FOR v_XML IN c_XML LOOP
        MERGE INTO SEM_MSP_CANCELLATION S
        USING (SELECT v_XML.TRADE_DATE TRADE_DATE,
                      v_XML.RUN_TYPE RUN_TYPE
               FROM DUAL) A
        ON (A.TRADE_DATE = S.TRADE_DATE AND A.RUN_TYPE = S.RUN_TYPE)
        WHEN MATCHED THEN
            UPDATE
            SET S.CANCELLATION_DATETIME = v_XML.CANCELLATION_DATETIME
        WHEN NOT MATCHED THEN
            INSERT
                (TRADE_DATE,
                 RUN_TYPE,
                 CANCELLATION_DATETIME)
            VALUES
                (v_XML.TRADE_DATE,
                 v_XML.RUN_TYPE,
                 v_XML.CANCELLATION_DATETIME);

        v_RECORD_COUNT := v_RECORD_COUNT + 1;
    END LOOP;
    p_LOGGER.LOG_INFO('Datarows processed: ' || v_RECORD_COUNT);
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        --p_LOGGER.LOG_ERROR('Error importing ' || g_REPORT_NAME || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        p_LOGGER.LOG_ERROR('Error importing ' || 'PUB_MSP_Cancel' || ': ' || MM_SEM_UTIL.ERROR_STACKTRACE);
        RAISE;
END IMPORT_MSP_CANCEL;
---------------------------------------------------------------------------------
PROCEDURE SET_MPUD5_PARAMETERS(p_IMPORT_FILE IN OUT NOCOPY CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
  v_MPUD5_START SYSTEM_DICTIONARY.VALUE%TYPE;
  v_MPUD5_START_DATE DATE;
  v_RPT_DATE DATE;
BEGIN
  v_MPUD5_START := GET_DICTIONARY_VALUE('MPUD5 Start', 0, 'MarketExchange', 'SEM');
  BEGIN
    v_MPUD5_START_DATE := TO_DATE(v_MPUD5_START, 'YYYY-MM-DD');
  EXCEPTION WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('MPUD5 Start setting is invalid - check SEM System Settings for YYYY-MM-DD format.');
    RAISE;
  END;

  BEGIN
    SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//RPT_DATE'), 'DD/MM/YYYY HH24:MI:SS') RPT_DATE
    INTO v_RPT_DATE
    FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_IMPORT_FILE), 'REPORT/REPORT_HEADER/HEADROW'))) T;
  EXCEPTION WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Cannot extract <rpt_date> element from file - check XML format.');
    RAISE;
  END;

  IF v_MPUD5_START_DATE <= TRUNC(v_RPT_DATE, 'DD') THEN
    -- MPUD5 format
    g_PARTICIPANT_ELEMENT := 'PARTICIPANT_NAME';
    g_ORGANIZATION_ELEMENT := 'ORGANISATION_NAME';
    g_RESOURCE_ELEMENT := 'RESOURCE_NAME';
    -- for ex-post initial mkt sched details report
    g_MKT_SCHED_DETAILS_QUANTITY := 'SCHEDULE_QUANTITY';
  ELSE
    -- MPUD4 format
    g_PARTICIPANT_ELEMENT := 'PARTICIPANT_ID';
    g_ORGANIZATION_ELEMENT := 'PARTICIPANT_NAME';
    g_RESOURCE_ELEMENT := 'RESOURCE_ID';
    g_MKT_SCHED_DETAILS_QUANTITY := 'MSQ';
  END IF;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_LOGGER.LOG_ERROR('Cannot extract report name - check XML format');
    RAISE;
  WHEN OTHERS THEN
    RAISE;
END SET_MPUD5_PARAMETERS;
-------------------------------------------------------------------------------------------
PROCEDURE MPI_REPORT_NAME(p_IMPORT_FILE IN OUT NOCOPY CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
BEGIN
  SELECT EXTRACTVALUE(VALUE(T), '//REPORT_NAME') REPORT_NAME
  INTO g_REPORT_NAME
  FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_IMPORT_FILE), 'REPORT/REPORT_HEADER/HEADROW'))) T;

  p_LOGGER.LOG_INFO('Report name: ' || g_REPORT_NAME);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    p_LOGGER.LOG_ERROR('Cannot extract report name - check XML format.');
    RAISE;
  WHEN OTHERS THEN
    RAISE;
END MPI_REPORT_NAME;
-------------------------------------------------------------------------------------------
PROCEDURE MPI_RUN_TYPE(p_IMPORT_FILE IN OUT NOCOPY CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
BEGIN
  -- The Run type in the following IDT is not in the report header
  -- We need to query the first Report body for the Run Type
  IF g_REPORT_NAME = 'MP_D_ExPostIndIntconnNominations' OR g_REPORT_NAME = 'MP_D_ExPostInitIntconnNominations' THEN
      SELECT EXTRACTVALUE(VALUE(T), '//RUN_TYPE') RUN_TYPE
      INTO g_RUN_TYPE
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_IMPORT_FILE), 'REPORT/REPORT_BODY/PAGE/DATAROW[@num="1"]/RUN_TYPE'))) T;
  ELSE
      SELECT EXTRACTVALUE(VALUE(T), '//RUN_TYPE') RUN_TYPE
      INTO g_RUN_TYPE
      FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_IMPORT_FILE), 'REPORT/REPORT_HEADER/HEADROW'))) T;
  END IF;
  -- Report name is logged earlier, just log run type
  p_LOGGER.LOG_INFO('Run Type: ' || g_RUN_TYPE);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    g_RUN_TYPE := NULL;
  WHEN OTHERS THEN
    RAISE;
END MPI_RUN_TYPE;
-------------------------------------------------------------------------------------------
-- AUTOGENERATED CODE: DO NOT HAND EDIT!!!!
-- To regenerate this procedure, use the output from MM_SEM_UTIL.GEN_IMPORT_MPI_REPORT_PROC
PROCEDURE IMPORT_MPI_REPORT (
	p_MPI_REPORT_NAME IN SYSTEM_DICTIONARY.VALUE%TYPE,
	p_IMPORT_FILE IN OUT NOCOPY CLOB,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS
	v_IMPORT_PARM SYSTEM_DICTIONARY.VALUE%TYPE;
	v_KEY3_VALUE SYSTEM_DICTIONARY.VALUE%TYPE;
BEGIN
	-- get the run type (if it exists) from the file to get to the right system dictionary settings
	MPI_RUN_TYPE(p_IMPORT_FILE, p_LOGGER);
	IF g_RUN_TYPE IS NOT NULL THEN
		v_KEY3_VALUE := p_MPI_REPORT_NAME||'_'||g_RUN_TYPE;
	ELSE
		v_KEY3_VALUE := p_MPI_REPORT_NAME;
	END IF;
	SET_MPUD5_PARAMETERS(p_IMPORT_FILE, p_LOGGER);
	BEGIN
		SELECT VALUE INTO v_IMPORT_PARM
		FROM SYSTEM_DICTIONARY
		WHERE SETTING_NAME = 'import_param'
					AND KEY3=(
					SELECT KEY3
					FROM SYSTEM_DICTIONARY
					WHERE VALUE=v_KEY3_VALUE || '.xml');
	EXCEPTION WHEN OTHERS THEN
		v_IMPORT_PARM := NULL;
	END;
	CASE p_MPI_REPORT_NAME
		WHEN 'MP_D_AggIntconnUsrNominations' THEN IMPORT_IC_AGG_NOMIN(p_IMPORT_FILE, p_LOGGER);
		WHEN 'MP_D_AvailCreditCover' THEN IMPORT_AVAILABLE_CREDIT_COVER(p_IMPORT_FILE, p_LOGGER);
		WHEN 'MP_D_ExAnteIntconnNominations' THEN IMPORT_IC_NOMINATIONS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_ExAnteMktSchDetail' THEN IMPORT_MKT_SCHED_DETAIL(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_ExPostIndIntconnNominations' THEN IMPORT_IC_NOMINATIONS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_ExPostInitIntconnNominations' THEN IMPORT_IC_NOMINATIONS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_ExPostMktSchDetail' THEN IMPORT_MKT_SCHED_DETAIL(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_ExcludedBids' THEN IMPORT_EXCLUDED_BIDS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'MP_D_IndicativeActualSchedules' THEN IMPORT_INDIC_ACTUAL_SCHED(p_IMPORT_FILE, p_LOGGER);
		WHEN 'MP_D_InitialExPostMktSchDetail' THEN IMPORT_MKT_SCHED_DETAIL(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_IntconnCapActHoldResults' THEN IMPORT_IC_CAP_HOLDINGS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_IntconnModNominations' THEN IMPORT_IC_NOMINATIONS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_MeterDataDetailD1' THEN IMPORT_METER_DETAIL(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_MeterDataDetailD3' THEN IMPORT_METER_DETAIL(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_RevIntconnModNominations' THEN IMPORT_IC_NOMINATIONS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_RevIntconnModNominationsD4' THEN IMPORT_IC_NOMINATIONS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'MP_D_WithinDayActualSchedules' THEN IMPORT_ACTUAL_SCHEDULES(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_A_AggLoadFcst' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_A_LoadFcst' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_ActiveMPUnits' THEN IMPORT_UNITS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_ActiveMPs' THEN IMPORT_MKT_PARTICIPANTS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_ActiveUnits' THEN IMPORT_JUST_UNITS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ActualLoadSummary' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_AdvInfo' THEN IMPORT_MO_NOTIFICATIONS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_AggLoadFcst' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_AggRollingWindFcst' THEN IMPORT_WIND_GEN_AGG(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_CODInterconnectorUnits' THEN IMPORT_COMM_OFFER_IC(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_CODStandardDemUnits' THEN IMPORT_COMM_OFFER_STD_UNITS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_CODStandardGenUnits' THEN IMPORT_COMM_OFFER_STD_UNITS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_CommercialOfferDataDemNomProfiles' THEN IMPORT_NOM_PROFILE(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_CommercialOfferDataGenNomProfiles' THEN IMPORT_NOM_PROFILE(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_DemandControlData' THEN IMPORT_DEMAND_CTRL_DATA(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_DispatchInstructions' THEN IMPORT_DISPATCH_INSTR(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_DispatchInstructionsD3' THEN IMPORT_DISPATCH_INSTR(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_EAShadowPrices' THEN IMPORT_SHADOW_SMP(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_EPIndShadowPrices' THEN IMPORT_SHADOW_SMP(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_EPInitShadowPrices' THEN IMPORT_SHADOW_SMP(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_EPLossOfLoadProbability' THEN IMPORT_LOSS_LOAD_PROBAB(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_EnergyLimitedGenUnitTechChars' THEN IMPORT_EN_LTD_TECH_CHAR(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ExAnteIndicativeOpsScheduleDetails' THEN IMPORT_OPS_SCHED(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ExAnteMktResults' THEN IMPORT_MARKET_RESULTS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ExAnteMktSchDetail' THEN IMPORT_MKT_SCHED_DETAIL_PUB(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ExAnteMktSchSummary' THEN IMPORT_MKT_SCHED_SUMMARY(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_ExPostIndMktResults' THEN IMPORT_MARKET_RESULTS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ExPostInitActLoadSummary' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_ExPostInitMktResults' THEN IMPORT_MARKET_RESULTS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ExPostMktSchDetail' THEN IMPORT_MKT_SCHED_DETAIL_PUB(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ExPostMktSchSummary' THEN IMPORT_MKT_SCHED_SUMMARY(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_ExchangeRate' THEN IMPORT_DAY_EXCHANGE_RATE(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_GenUnitTechChars' THEN IMPORT_GEN_UNIT_TECH_CHAR(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_IndicativeMarketPrices' THEN IMPORT_INDIC_SMP(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_InitialExPostMktSchDetail' THEN IMPORT_MKT_SCHED_DETAIL_PUB(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_InitialExPostMktSchSummary' THEN IMPORT_MKT_SCHED_SUMMARY(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_InitialMarketPrices' THEN IMPORT_INIT_SMP(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_IntconnATCData' THEN IMPORT_DAILY_ATC(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_IntconnCapActHoldResults' THEN IMPORT_IC_CAP_HOLDINGS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_IntconnCapHoldResults' THEN IMPORT_IC_CAP_HOLDINGS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_IntconnNetActual' THEN IMPORT_IC_NET_ACTUAL(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_IntconnOfferCapacity' THEN IMPORT_IC_OFFER_CAPACITY(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_InterconnectorTrades' THEN IMPORT_SO_TRADES(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_JurisdictionErrorSupplyD1' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_JurisdictionErrorSupplyD15' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_JurisdictionErrorSupplyD4' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_KPI_GateInfo' THEN KPI_GATE_INFO(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_KPI_Schedules' THEN IMPORT_KPI_SCHEDULES(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_LoadFcstAssumptions' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_LoadFcstSummary' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_MarketPricesAverages' THEN IMPORT_AVG_SMP(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_MeterDataSummaryD1' THEN IMPORT_METER_SUMMARY(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_MeterDataSummaryD3' THEN IMPORT_METER_SUMMARY(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_PriceAffectingMeterData' THEN IMPORT_METER_DETAIL_PUB(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_ResidualErrorVolumeD15' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_RevIntconnATCData' THEN IMPORT_DAILY_ATC(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_D_RevIntconnModNominations' THEN IMPORT_IC_NOMINATIONS_PUB(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_RollingWindFcstAssumptions' THEN IMPORT_GEN_FORECAST(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_RollingWindFcstAssumptionsJurisdiction' THEN IMPORT_WIND_FORECAST_BY_JURIS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_SystemFrequency' THEN IMPORT_SYSTEM_FREQUENCY(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_TODDemandSideUnits' THEN IMPORT_TECH_OFFER_STD_UNITS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_TODForecastData' THEN IMPORT_TECH_OFFER_FORECAST(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_TODStandardUnits' THEN IMPORT_TECH_OFFER_STD_UNITS(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_D_TOD_UnitData' THEN IMPORT_TECH_OFFER_UNIT_DATA(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_IndicativeInterconnFlows' THEN IMPORT_IC_FLOW(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_InitialInterconnFlows' THEN IMPORT_IC_FLOW(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_MSP_Cancel' THEN IMPORT_MSP_CANCEL(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_M_AggLoadFcst' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_M_IntconnCapHoldResults' THEN IMPORT_IC_CAP_HOLDINGS(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_M_LoadFcstAssumptions' THEN IMPORT_LOAD_FORECAST(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);
		WHEN 'PUB_M_LossLoadProbabilityFcst' THEN IMPORT_LOSS_LOAD_PROBAB(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_M_SttlClassesUpdates' THEN IMPORT_SETTL_CLASS_UPDATE(p_IMPORT_FILE, p_LOGGER);
		WHEN 'PUB_SuspTermMPs' THEN IMPORT_INACTIVE_MKT_PART(p_IMPORT_FILE, p_LOGGER);
		-- you're not hand-editing this case statement, are you?
		ELSE p_LOGGER.LOG_ERROR(p_MPI_REPORT_NAME || ' is not a valid report name. Report cannot be loaded.');
	END CASE;
END IMPORT_MPI_REPORT;
----------------------------------------------------------------------------------------
PROCEDURE PARSE_TLAF
    (
    p_REPORT IN CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) 
AS
    v_LINES 	PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_ELEMENTS 	PARSE_UTIL.STRING_TABLE;
    v_IDX 		BINARY_INTEGER;
    v_REC_COUNT	BINARY_INTEGER := 0;
    v_REC SEM_TLAF_TEMP%ROWTYPE;
BEGIN
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_REPORT, v_LINES);
	v_IDX := v_LINES.FIRST;
	WHILE v_LINES.EXISTS(v_IDX) LOOP

		IF TRIM(v_LINES(v_IDX)) IS NOT NULL THEN -- ignore blank lines
      -- Verify report name on line#1
      IF v_IDX = 1 THEN
          IF INSTR(UPPER(v_LINES(v_IDX)), UPPER(g_TLAF_REPORT_NAME)) = 0 THEN
              p_LOGGER.LOG_ERROR('Invalid report name in the file header.' || UTL_TCP.CRLF ||
                                '<' || v_LINES(v_IDX) || '>');
              RETURN; 
           END IF;               
      ELSIF v_IDX >= 9 THEN 
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_ELEMENTS);

        v_REC.TRADE_DATE := TO_DATE(TRIM(v_ELEMENTS(1)), 'DD/MM/YYYY');
        v_REC.PSE_ID := MM_SEM_UTIL.GET_PSE_ID(TRIM(v_ELEMENTS(2)), TRUE, v_ELEMENTS(2));
        v_REC.POD_ID := MM_SEM_UTIL.GET_SERVICE_POINT_ID(TRIM(v_ELEMENTS(3)), TRUE);
        v_REC.DELIVERY_DATE := TO_DATE(TRIM(v_ELEMENTS(4)), 'DD/MM/YYYY');
        V_REC.DELIVERY_HOUR := TO_NUMBER(TRIM(v_ELEMENTS(5)));
        V_REC.DELIVERY_INTERVAL := TO_NUMBER(TRIM(v_ELEMENTS(6)));
        V_REC.LOSS_FACTOR := TO_NUMBER(TRIM(v_ELEMENTS(7)));
        
        INSERT INTO SEM_TLAF_TEMP VALUES v_REC;
        
        		v_REC_COUNT := v_REC_COUNT+1;
      END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
 p_LOGGER.LOG_DEBUG(v_REC_COUNT || ' lines parsed successfully.');
EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error parsing TLAF report on line ' || v_IDX || UTL_TCP.CRLF ||
               '<' || v_LINES(v_IDX) || '>' || UTL_TCP.CRLF ||        
               MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END PARSE_TLAF;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TLAF 
    (
    p_IMPORT_FILE IN OUT NOCOPY CLOB,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
    )
AS
BEGIN
    p_LOGGER.EXCHANGE_NAME := 'Import ' || g_TLAF_REPORT_NAME || ' report';

    PARSE_TLAF(p_IMPORT_FILE, p_LOGGER);
    MERGE INTO SEM_LOSS_FACTOR SLF
    USING (
      SELECT MM_SEM_UTIL.GET_SCHEDULE_DATE(DELIVERY_DATE, DELIVERY_HOUR, DELIVERY_INTERVAL) AS SCHEDULE_DATE,
            PSE_ID,
            POD_ID,            
            LOSS_FACTOR
      FROM SEM_TLAF_TEMP) S
    ON (
      S.SCHEDULE_DATE = SLF.SCHEDULE_DATE AND
      S.PSE_ID = SLF.PSE_ID AND
      S.POD_ID = SLF.POD_ID)
    WHEN MATCHED THEN
      UPDATE SET SLF.LOSS_FACTOR = S.LOSS_FACTOR
    WHEN NOT MATCHED THEN
      INSERT (
        SCHEDULE_DATE,
        PSE_ID,
        POD_ID,
        LOSS_FACTOR,
        EVENT_ID
      ) VALUES (
        S.SCHEDULE_DATE,
        S.PSE_ID,
        S.POD_ID,
        S.LOSS_FACTOR,
        NULL);
      COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Error importing TLAF report: ' ||
               MM_SEM_UTIL.ERROR_STACKTRACE);
    RAISE;
END IMPORT_TLAF;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TLAF_REPORT_CLOB (
    p_IMPORT_FILE_PATH   IN VARCHAR2,
    p_IMPORT_FILE IN OUT NOCOPY CLOB,
    p_LOG_TYPE    IN NUMBER,
    p_TRACE_ON    IN NUMBER,
    p_STATUS      OUT NUMBER,
    p_MESSAGE     OUT VARCHAR2) IS

  v_LOGGER  MM_LOGGER_ADAPTER;
  v_DUMMY   VARCHAR2(512);
  v_FILE_NAME VARCHAR2(64);
BEGIN
    --extract the file name out of the path
    v_FILE_NAME := PARSE_UTIL.FILE_NAME_FROM_PATH(p_FILE_PATH => p_IMPORT_FILE_PATH);
    v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM,
                                   NULL,
                                   'Import TLAF Report',
                                   'Import File:' || v_FILE_NAME,
                                   p_LOG_TYPE,
                                   p_TRACE_ON);
    MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

    -- import the report
    IF LOGS.GET_ERROR_COUNT() = 0 THEN
        IMPORT_TLAF(p_IMPORT_FILE, v_LOGGER);
    END IF;

    -- clean up
    p_STATUS := GA.SUCCESS;
    p_MESSAGE := 'Import TLAF Report Complete.';
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
    p_MESSAGE := p_MESSAGE || ' See Process Log for details.';
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS := SQLCODE;
        p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);
END IMPORT_TLAF_REPORT_CLOB; 
-------------------------------------------------------------------------------------------
PROCEDURE GET_REPORT_ATTRIBUTES
(
    p_INT_REP_NAME IN VARCHAR2,
    p_RECORDS      OUT SEM_REPORT_ATTR_TBL,
    p_STATUS       OUT NUMBER,
    p_MESSAGE      OUT VARCHAR2
) IS

    v_APP_TYPE        VARCHAR2(16);
    v_MODE            VARCHAR2(16);
    v_REQUEST_TYPE    VARCHAR2(16);
    v_ACTION          VARCHAR2(16);
    v_REPORT_TYPE     VARCHAR2(16);
    v_REPORT_SUB_TYPE VARCHAR2(16);
    v_PERIODICITY     VARCHAR2(16);
    v_REPORT_NAME     VARCHAR2(64);
    v_FILE_NAME       VARCHAR(128);
    v_ACCESS_CLASS    VARCHAR2(16);
    v_FILE_TYPE       VARCHAR2(16);
    v_VERS_NO         VARCHAR2(16);
    v_MESSAGES        VARCHAR2(6);
    v_REC_FOUND       BOOLEAN := FALSE;

    CURSOR c_REP_ATTR IS
        SELECT SETTING_NAME, VALUE
        FROM SYSTEM_DICTIONARY
        WHERE MODEL_ID = 0
        AND MODULE = 'MarketExchange'
        AND KEY1 = 'SEM'
        AND KEY2 = 'SMO Reports'
        AND KEY3 = p_INT_REP_NAME;

BEGIN

    --Loop over records
    FOR v_REC_DATA IN c_REP_ATTR LOOP

        CASE UPPER(v_REC_DATA.SETTING_NAME)
            WHEN 'ACCESS_CLASS' THEN
                v_ACCESS_CLASS := v_REC_DATA.VALUE;
            WHEN 'ACTION' THEN
                v_ACTION := v_REC_DATA.VALUE;
            WHEN 'APPLICATION_TYPE' THEN
                v_APP_TYPE := v_REC_DATA.VALUE;
            WHEN 'FILE_NAME' THEN
                v_FILE_NAME := v_REC_DATA.VALUE;
            WHEN 'FILE_TYPE' THEN
                v_FILE_TYPE := v_REC_DATA.VALUE;
            WHEN 'MODE' THEN
                v_MODE := v_REC_DATA.VALUE;
            WHEN 'PERIODICITY' THEN
                v_PERIODICITY := v_REC_DATA.VALUE;
            WHEN 'REPORT_NAME' THEN
                v_REPORT_NAME := v_REC_DATA.VALUE;
            WHEN 'REPORT_SUB_TYPE' THEN
                v_REPORT_SUB_TYPE := v_REC_DATA.VALUE;
            WHEN 'REPORT_TYPE' THEN
                v_REPORT_TYPE := v_REC_DATA.VALUE;
            WHEN 'REQUEST_TYPE' THEN
                v_REQUEST_TYPE := v_REC_DATA.VALUE;
            WHEN 'VERSION_NO' THEN
                v_VERS_NO := v_REC_DATA.VALUE;
            WHEN 'MULTIPLE_MESSAGES' THEN
                v_MESSAGES := v_REC_DATA.VALUE;
      WHEN 'IMPORT_PROCEDURE' THEN
        NULL;
      WHEN 'IMPORT_PARAM' THEN
        NULL;
            v_REC_FOUND := TRUE;
        END CASE;

    END LOOP;

    IF v_REC_FOUND = TRUE THEN
        p_RECORDS := SEM_REPORT_ATTR_TBL();
        p_RECORDS.EXTEND();
        p_RECORDS(p_RECORDS.LAST) := SEM_REPORT_ATTR(APPLICATION_TYPE => v_APP_TYPE,
                                                     REP_MODE         => v_MODE,
                                                     REQUEST_TYPE     => v_REQUEST_TYPE,
                                                     ACTION           => v_ACTION,
                                                     REPORT_TYPE      => v_REPORT_TYPE,
                                                     REPORT_SUB_TYPE  => v_REPORT_SUB_TYPE,
                                                     PERIODICITY      => v_PERIODICITY,
                                                     REPORT_NAME      => v_REPORT_NAME,
                                                     FILE_NAME        => v_FILE_NAME,
                                                     ACCESS_CLASS     => v_ACCESS_CLASS,
                                                     FILE_TYPE        => v_FILE_TYPE,
                                                     VERSION_NO       => v_VERS_NO,
                                                     MULTIPLE_MESSAGES => v_MESSAGES);
    END IF;


EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := PACKAGE_NAME || '.GET_REPORT_ATTRIBUTES: ' || SQLERRM;

END GET_REPORT_ATTRIBUTES;
---------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE BUILD_REPORT_REQUEST
(
    p_RECORDS          IN SEM_REPORT_ATTR_TBL,
    p_PARTICIPANT_NAME IN VARCHAR2,
    p_USER_NAME        IN VARCHAR2,
    p_TRADE_DATE       IN DATE,
    p_XML_REQUEST_BODY OUT XMLTYPE
) IS

    v_TRADE_DATE VARCHAR2(10);
    v_USER_NAME  VARCHAR2(32);


BEGIN

    v_TRADE_DATE := TO_CHAR(TRUNC(p_TRADE_DATE), 'YYYY-MM-DD');
    v_USER_NAME := NVL(p_USER_NAME, '?');

   --For Member Private reports the report_request tag has one more attribute: access_class="MP"
    --This attribute is missing for Public reports
    SELECT /*XMLELEMENT("file_exchange",
                     XMLATTRIBUTES(g_REPORTS_NS_XSI AS "xmlns:xsi",
                                    g_REPORTS_SCHEMA AS "xsi:noNamespaceSchemaLocation"),*/
                      XMLELEMENT("market_report",
                                 XMLATTRIBUTES(T.APPLICATION_TYPE AS
                                               "application_type",
                                               p_PARTICIPANT_NAME AS
                                               "participant_name",
                                               v_USER_NAME AS "user_name",
                                               T.REP_MODE AS "mode"),
                                 XMLELEMENT("report_request",
                                            XMLATTRIBUTES(T.REQUEST_TYPE AS "request_type",
                                                          T.ACTION AS "action",
                                                          T.REPORT_TYPE AS "report_type",
                                                          T.REPORT_SUB_TYPE AS "report_sub_type",
                                                          T.PERIODICITY AS "periodicity",
                                                          v_TRADE_DATE AS "trade_date",
                                                          T.REPORT_NAME AS "report_name",
                                                          CASE WHEN UPPER(T.REPORT_NAME) = UPPER(g_TLAF_REPORT_NAME) 
                                                              THEN REPLACE(T.FILE_NAME, 'MM', TO_CHAR(p_TRADE_DATE, 'MM'))
                                                              ELSE T.FILE_NAME 
                                                              END AS "file_name",
                                                          CASE UPPER(T.ACCESS_CLASS)
                                                            WHEN 'PUB' THEN NULL
                              ELSE T.ACCESS_CLASS
                                                          END AS "access_class",
                                                          T.FILE_TYPE AS "file_type",
                                                          T.VERSION_NO AS "version_no",
                                                          T.MULTIPLE_MESSAGES AS "multiple_messages")))
      INTO p_XML_REQUEST_BODY
      FROM TABLE(p_RECORDS) T;


END BUILD_REPORT_REQUEST;
--------------------------------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REPORT
(
    p_RECORDS       IN SEM_REPORT_ATTR_TBL,
    p_BEGIN_DATE    IN DATE,
    p_ACCOUNT       IN VARCHAR2,
    p_CRED          IN MEX_CREDENTIALS,
    p_RESPONSE_CLOB OUT CLOB,
    p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS


    v_RESULT       MEX_RESULT;
    v_REQUEST_XML  XMLTYPE;
    v_REQUEST_CLOB CLOB := NULL;
    v_TAG          VARCHAR2(256);


BEGIN

    DBMS_LOB.CREATETEMPORARY(v_REQUEST_CLOB, TRUE);
    DBMS_LOB.OPEN(v_REQUEST_CLOB, DBMS_LOB.LOB_READWRITE);

    -- This tag is not in the XMLTYPE to prevent Oracle from trying to validate
    -- the doc against the specified XSD
    v_TAG := '<file_exchange xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="mi_file_exchange_sem.xsd">';
    DBMS_LOB.WRITEAPPEND(v_REQUEST_CLOB, LENGTH(v_TAG), v_TAG);

    --Build the rest of the request
    BUILD_REPORT_REQUEST(p_RECORDS,
                         p_ACCOUNT,
                         p_CRED.USERNAME,
                         p_BEGIN_DATE,
                         v_REQUEST_XML);

    -- Add this XML to the request CLOB
    DBMS_LOB.APPEND(v_REQUEST_CLOB, v_REQUEST_XML.GETCLOBVAL());
    -- And stick the trailing close-tag
    v_TAG := '</file_exchange>';
    DBMS_LOB.WRITEAPPEND(v_REQUEST_CLOB, LENGTH(v_TAG), v_TAG);

    DBMS_LOB.CLOSE(v_REQUEST_CLOB);


    IF MM_SEM_UTIL.g_TEST THEN
        p_RESPONSE_CLOB := NULL;

        p_LOGGER.LOG_START('test.' || MM_SEM_UTIL.g_MEX_MARKET,
                           MM_SEM_UTIL.g_MEX_ACTION_REPORTS);
    p_LOGGER.LOG_REQUEST(NULL, v_REQUEST_CLOB, 'text/xml');
        p_LOGGER.LOG_STOP(0, 'Success');

    ELSE

        --Invoke the MEX Switchboard
        v_RESULT := MEX_SWITCHBOARD.Invoke(p_Market              => MM_SEM_UTIL.g_MEX_MARKET,
                                           p_Action              => MM_SEM_UTIL.g_MEX_ACTION_REPORTS,
                                           p_Logger              => p_LOGGER,
                                           p_Cred                => p_CRED,
                                           p_Request_ContentType => 'text/xml',
                                           p_Request             => v_REQUEST_CLOB);

        IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
            p_RESPONSE_CLOB := NULL; -- this indicates failure - MEX_Switchboard.Invoke will have already logged error message
        ELSE
            p_RESPONSE_CLOB := v_RESULT.RESPONSE;
        END IF;
    END IF;

    IF v_REQUEST_CLOB IS NOT NULL THEN
        IF DBMS_LOB.ISOPEN(v_REQUEST_CLOB) <> 0 THEN
            DBMS_LOB.CLOSE(v_REQUEST_CLOB);
        END IF;
        DBMS_LOB.FREETEMPORARY(v_REQUEST_CLOB);
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        IF v_REQUEST_CLOB IS NOT NULL THEN
            IF DBMS_LOB.ISOPEN(v_REQUEST_CLOB) <> 0 THEN
                DBMS_LOB.CLOSE(v_REQUEST_CLOB);
            END IF;
            DBMS_LOB.FREETEMPORARY(v_REQUEST_CLOB);
        END IF;


END FETCH_REPORT;
-------------------------------------------------------------------------------------------
PROCEDURE QUERY_REPORT
(
    p_BEGIN_DATE   IN DATE,
  p_END_DATE     IN DATE,
    p_INT_REP_NAME IN VARCHAR2,
    p_LOG_TYPE     IN NUMBER,
    p_TRACE_ON     IN NUMBER,
    p_STATUS       OUT NUMBER,
    p_MESSAGE      OUT VARCHAR2,
    P_RUN_TYPE     IN VARCHAR2 := NULL
) AS

    v_RECORDS       SEM_REPORT_ATTR_TBL;
    v_REC_DATA      SEM_REPORT_ATTR;
    v_RESPONSE_CLOB CLOB;
    v_LOGGER        MM_LOGGER_ADAPTER;
    --v_EVENT_ID   NUMBER(9);
    v_USE_ALL_ACCT  BOOLEAN := FALSE;
    v_ACCOUNT       VARCHAR2(64);
    v_CREDS         MM_CREDENTIALS_SET;
    v_CRED          MEX_CREDENTIALS;
    v_IDX           BINARY_INTEGER;
  v_CURRENT_DATE  DATE;
  v_DUMMY   VARCHAR2(512);

  v_PARMS UT.STRING_MAP;

BEGIN
  -- ignore the returned logger - we already have a logger we can use
  MM_UTIL.INIT_MEX(EC.ES_SEM,
           'Query SMO Report',
           p_INT_REP_NAME,
           p_LOG_TYPE,
           p_TRACE_ON,
           v_CREDS,
           v_LOGGER);
  MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

  -- no credentials? we can proceed w/out if we are in test mode - otherwise, fail
  IF NOT v_CREDS.HAS_NEXT THEN
    p_STATUS := GA.GENERAL_EXCEPTION;
    p_MESSAGE := 'No credentials found for SEM. Nothing can be downloaded';
    v_LOGGER.LOG_WARN(p_MESSAGE);

    IF NOT MM_SEM_UTIL.g_TEST THEN
      MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);
      RETURN;
    END IF;
  END IF;

    BEGIN
      --Get report attributes based on InternalReportName
      GET_REPORT_ATTRIBUTES(p_INT_REP_NAME, v_RECORDS, p_STATUS, p_MESSAGE);
      v_IDX         := v_RECORDS.FIRST();
      v_REC_DATA    := v_RECORDS(v_IDX);

    EXCEPTION
        WHEN COLLECTION_IS_NULL THEN
      p_STATUS := GA.GENERAL_EXCEPTION;
          p_MESSAGE := 'Check the Exchange type setting on action name <' || p_INT_REP_NAME || '> and ' || UTL_TCP.CRLF ||
                       'make sure it matches entry in System Settings located at Tools|Configurations.';
      MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);
          RETURN;
    END;

  -- add the report name to the parameter map
  v_PARMS('report_name') := v_REC_DATA.REPORT_NAME;

    --Set the flag for private reports
    IF v_REC_DATA.ACCESS_CLASS = 'MP' THEN
        v_USE_ALL_ACCT := TRUE;
    END IF;

  WHILE TRUE LOOP
    -- v_CREDS will be null if we are in Test mode and no credentials have been
    -- defined
    IF v_CREDS IS NOT NULL THEN
      EXIT WHEN NOT v_CREDS.HAS_NEXT;
      v_CRED    := v_CREDS.GET_NEXT;
      v_ACCOUNT := v_CRED.EXTERNAL_ACCOUNT_NAME;
      v_LOGGER.EXTERNAL_ACCOUNT_NAME := v_ACCOUNT;
    ELSE
      v_CRED    := NULL;
      v_ACCOUNT := '?';
      -- if we have no credentials, then make sure we exit the loop after
      -- the first go.
      v_USE_ALL_ACCT := FALSE;
    END IF;    
      
        v_CURRENT_DATE := CASE WHEN UPPER(p_INT_REP_NAME) = UPPER(g_TLAF_REPORT_NAME) 
                               THEN TRUNC(p_BEGIN_DATE, 'MM') -- Get first of the month
                               ELSE TRUNC(p_BEGIN_DATE) END;

        --Loop over dates
        WHILE v_CURRENT_DATE <= p_END_DATE LOOP

            v_LOGGER.LOG_INFO(TO_CHAR('Querying: ' || TO_CHAR(v_CURRENT_DATE,'YYYY-MM-DD')));
            FETCH_REPORT(v_RECORDS,
                   v_CURRENT_DATE,
                   v_ACCOUNT,
                   v_CRED,
                   v_RESPONSE_CLOB,
                   v_LOGGER);
            --v_EVENT_ID := v_LOGGER.LAST_EVENT_ID;
            IF v_RESPONSE_CLOB IS NOT NULL THEN
                IF p_INT_REP_NAME = g_TLAF_REPORT_NAME THEN
                    IMPORT_TLAF(v_RESPONSE_CLOB, v_LOGGER);
                ELSE                
                  v_RESPONSE_CLOB := PARSE_UTIL.REMOVE_DOCTYPE(v_RESPONSE_CLOB);
                  -- parse XML for report_name
                  MPI_REPORT_NAME(v_RESPONSE_CLOB, v_LOGGER);

                  -- import the report
                  IMPORT_MPI_REPORT(g_REPORT_NAME, v_RESPONSE_CLOB, v_LOGGER);
             END IF;
              -- post-process
              XS.POST_MARKET_EXCHANGE(EC.ES_SEM, v_LOGGER.EXCHANGE_NAME, v_PARMS, v_RESPONSE_CLOB, v_LOGGER);
            END IF;
            v_CURRENT_DATE :=  CASE WHEN UPPER(p_INT_REP_NAME) = UPPER(g_TLAF_REPORT_NAME) 
                               THEN ADD_MONTHS(v_CURRENT_DATE, 1) -- Add month
                               ELSE v_CURRENT_DATE + 1 END; -- Add Day
    END LOOP; --end over dates

    EXIT WHEN NOT v_USE_ALL_ACCT;
  END LOOP; --end over all market participants accounts

  p_STATUS := GA.SUCCESS;
  p_MESSAGE := v_LOGGER.GET_END_MESSAGE();
  MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

    --RAISE ALERT
  MM_SEM_UTIL.RAISE_ALERTS(p_TYPE => g_ALERT_TYPE_REPORT,
                             p_NAME => p_INT_REP_NAME,
                             p_LOGGER => v_LOGGER,
                             p_MSG => 'Complete Download of ' || p_INT_REP_NAME || ' report');

EXCEPTION
    WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;

    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);

        MM_SEM_UTIL.RAISE_ALERTS(p_TYPE => g_ALERT_TYPE_REPORT,
                               p_NAME => p_INT_REP_NAME,
                               p_LOGGER => v_LOGGER,
                               p_MSG => 'Fatal error while downloading ' || p_INT_REP_NAME || ' report',
                               p_FATAL => TRUE);
END QUERY_REPORT;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MPI_REPORT_CLOB (
    p_IMPORT_FILE_PATH   IN VARCHAR2,
  p_IMPORT_FILE IN OUT NOCOPY CLOB,
    p_LOG_TYPE    IN NUMBER,
    p_TRACE_ON    IN NUMBER,
    p_STATUS      OUT NUMBER,
    p_MESSAGE     OUT VARCHAR2) IS

  v_LOGGER  MM_LOGGER_ADAPTER;
  v_DUMMY   VARCHAR2(512);
  v_FILE_NAME VARCHAR2(64);
  v_IMPORT_FILE_NO_DOCTYPE CLOB;
BEGIN
  --extract the file name out of the path
  v_FILE_NAME := PARSE_UTIL.FILE_NAME_FROM_PATH(p_FILE_PATH => p_IMPORT_FILE_PATH);
    v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_SEM,
                                   NULL,
                                   'Import SMO Report',
                                   'Import File:' || v_FILE_NAME,
                                   p_LOG_TYPE,
                                   p_TRACE_ON);
  MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

  v_IMPORT_FILE_NO_DOCTYPE := PARSE_UTIL.REMOVE_DOCTYPE(p_IMPORT_FILE);
  -- parse XML for report_name and rpt_date elements
  MPI_REPORT_NAME(v_IMPORT_FILE_NO_DOCTYPE, v_LOGGER);

  -- import the report
  IF LOGS.GET_ERROR_COUNT() = 0 THEN
    IMPORT_MPI_REPORT(g_REPORT_NAME, v_IMPORT_FILE_NO_DOCTYPE, v_LOGGER);
  END IF;

  -- clean up
    p_STATUS := GA.SUCCESS;
  p_MESSAGE := 'Import SMO Report Complete.';
  MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
  p_MESSAGE := p_MESSAGE || ' See Process Log for details.';

EXCEPTION
    WHEN OTHERS THEN
    p_STATUS := SQLCODE;
    p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);

END IMPORT_MPI_REPORT_CLOB;
-------------------------------------------------------------------------------------------
END MM_SEM_REPORTS;
/
