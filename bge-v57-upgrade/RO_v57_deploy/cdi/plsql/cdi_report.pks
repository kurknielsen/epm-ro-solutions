CREATE OR REPLACE PACKAGE CDI_REPORT AS

PROCEDURE GET_YES_NO_FILTER(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_TARIFF_FILTER
   (
   p_IDR_STATUS IN VARCHAR2,
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_SUPPLIER_FILTER(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_BGE_MASTER_ACCOUNT
   (
   p_BEGIN_DATE       IN DATE,
   p_END_DATE         IN DATE,
   p_IDR_STATUS       IN VARCHAR2,
   p_FILTER_TARIFF    IN VARCHAR2,
   p_FILTER_SUPPLIER  IN VARCHAR2,
   p_FILTER_CUSTOMER  IN VARCHAR2,
   p_CURSOR          OUT GA.REFCURSOR,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   );

PROCEDURE GET_BGE_CI_STAGING 
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );
   
PROCEDURE PUT_BGE_CI_STAGING
   (
   p_BILL_ACCOUNT      IN BGE_CI_STAGING.BILL_ACCOUNT%TYPE,
   p_SERVICE_POINT     IN BGE_CI_STAGING.SERVICE_POINT%TYPE,
   p_PREMISE_NUMBER    IN BGE_CI_STAGING.PREMISE_NUMBER%TYPE,
   p_TARIFF_CODE       IN BGE_CI_STAGING.TARIFF_CODE%TYPE,
   p_NODE              IN BGE_CI_STAGING.NODE%TYPE,
   p_POLR_ID           IN BGE_CI_STAGING.POLR_ID%TYPE,
   p_POLR_TYPE         IN BGE_CI_STAGING.POLR_TYPE%TYPE,
   p_SUPPLIER          IN BGE_CI_STAGING.SUPPLIER%TYPE,
   p_CITY_COUNTY_CODE  IN BGE_CI_STAGING.CITY_COUNTY_CODE%TYPE,
   p_EFFECTIVE_DATE    IN BGE_CI_STAGING.EFFECTIVE_DATE%TYPE,
   p_TERMINATION_DATE  IN BGE_CI_STAGING.TERMINATION_DATE%TYPE,
   p_SPECIAL_NOTATION  IN BGE_CI_STAGING.SPECIAL_NOTATION%TYPE,
   p_STATUS_INDICATION IN BGE_CI_STAGING.STATUS_INDICATION%TYPE,
   p_IDR_STATUS        IN BGE_CI_STAGING.IDR_STATUS%TYPE,
   p_PROCESS_ROW       IN BGE_CI_STAGING.PROCESS_ROW%TYPE,
   p_ERROR_MESSAGE     IN BGE_CI_STAGING.ERROR_MESSAGE%TYPE,
   p_OSUSER            IN BGE_CI_STAGING.OSUSER%TYPE,
   p_PROCESS_DATE      IN BGE_CI_STAGING.PROCESS_DATE%TYPE,
   p_RTO_ACCOUNT_ID    IN BGE_CI_STAGING.RTO_ACCOUNT_ID%TYPE,
   p_RPT_ID            IN VARCHAR2,
   p_STATUS           OUT NUMBER,
   p_MESSAGE          OUT VARCHAR2
   );

PROCEDURE CUT_BGE_CI_STAGING(p_RPT_ID IN VARCHAR2, p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2);

PROCEDURE VALIDATE_CI_RECORDS(p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2);

PROCEDURE GET_BGE_IGNORE_ACCOUNT
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE PUT_BGE_IGNORE_ACCOUNT
   (
   p_ROW_ID         IN VARCHAR2,
   p_BILL_ACCOUNT   IN NUMBER,
   p_SERVICE_POINT  IN NUMBER,
   p_PREMISE_NUMBER IN NUMBER,
   p_STATUS        OUT NUMBER,
   p_MESSAGE       OUT VARCHAR2
   );

PROCEDURE CUT_BGE_IGNORE_ACCOUNT
   (
   p_ROW_ID         IN VARCHAR2,
   p_BILL_ACCOUNT   IN NUMBER,
   p_SERVICE_POINT  IN NUMBER,
   p_PREMISE_NUMBER IN NUMBER,
   p_STATUS        OUT NUMBER,
   p_MESSAGE       OUT VARCHAR2
   );

PROCEDURE GET_PBS_CUSTOMER
   (  
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_MV90_HOURLY_DEMAND(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE, p_ACCOUNT_IDENTIFIER IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_SUPPLIER_CONTRACT
   (
   p_BEGIN_DATE   IN DATE,
   p_END_DATE     IN DATE,
   p_PROCESS_CODE IN VARCHAR2,
   p_STATUS      OUT NUMBER,
   p_MESSAGE     OUT VARCHAR2,
   p_CURSOR      OUT GA.REFCURSOR
   );

PROCEDURE PUT_SUPPLIER_CONTRACT
   (
   p_SUPPLIER_TYPE    IN VARCHAR2,
   p_SUPPLIER_ID      IN VARCHAR2,
   p_POLR_TYPE        IN VARCHAR2,
   p_PJM_SHORT        IN VARCHAR2,
   p_PJM_BASE_ID      IN NUMBER,
   p_PJM_INC_SHORT    IN VARCHAR2,
   p_PJM_INC_INC_ID   IN NUMBER,
   p_PJM_ALM_ID       IN NUMBER,
   p_BASE_BLOCK_SIZE  IN NUMBER,
   p_NUMBER_OF_BLOCKS IN NUMBER,
   p_SHARE_OF_LOAD    IN NUMBER,
   p_INC_DEC_START    IN DATE,
   p_INC_MW           IN NUMBER,
   p_DEC_MW           IN NUMBER,
   p_POWER_FLOW_START IN DATE,
   p_POWER_FLOW_END   IN DATE,
   p_PROCESS_RECORD   IN CHAR,
   p_ENTRY_ROWID      IN VARCHAR2,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   );

PROCEDURE CUT_SUPPLIER_CONTRACT
   (
   p_SUPPLIER_ID      IN VARCHAR2,
   p_POWER_FLOW_START IN DATE,
   p_POWER_FLOW_END   IN DATE,
   p_ENTRY_ROWID      IN VARCHAR2,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   );

PROCEDURE GET_TARIFF_CODES
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE PUT_TARIFF_CODE
   (
   p_SOS              IN VARCHAR2,
   p_DELIVERY_SERVICE IN VARCHAR2,
   p_HOURLY_SERVICE   IN VARCHAR2,
   p_SPECIAL_NOTATION IN VARCHAR2, 
   p_PROFILE          IN VARCHAR2, 
   p_REPORTED_SEGMENT IN VARCHAR2, 
   p_VOLTAGE_CLASS    IN VARCHAR2, 
   p_POLR_TYPE        IN VARCHAR2,
   p_EFFECTIVE_DATE   IN DATE,
   p_METER_TYPE       IN VARCHAR2, 
   p_PROCESS_DATE     IN DATE, 
   p_END_DATE         IN DATE,
   p_ENTRY_ROWID      IN VARCHAR2,
   p_STATUS          OUT NUMBER,
   p_MESSAGE         OUT VARCHAR2
   );

PROCEDURE CUT_TARIFF_CODE
   (
   p_ENTRY_ROWID IN VARCHAR2,
   p_STATUS     OUT NUMBER,
   p_MESSAGE    OUT VARCHAR2
   );

PROCEDURE GET_ESCHEDULE
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_SUB_STATION_FILTER(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_PLC_NSPL_DATA
   (
   p_BEGIN_DATE     IN DATE,
   p_END_DATE       IN DATE,
   p_BILL_ACCOUNT   IN VARCHAR2,
   p_SERVICE_POINT  IN VARCHAR2,
   p_PREMISE_NUMBER IN VARCHAR2,
   p_SERVICE_TYPE   IN VARCHAR2,
   p_STATUS        OUT NUMBER,
   p_MESSAGE       OUT VARCHAR2,
   p_CURSOR        OUT GA.REFCURSOR
   );

PROCEDURE PUT_PLC_NSPL_DATA
   (
   p_RPT_ID         IN VARCHAR2,
   p_TAG_VAL        IN NUMBER,
   p_STATUS        OUT NUMBER,
   p_MESSAGE       OUT VARCHAR2
   );

PROCEDURE CUT_PLC_NSPL_DATA(p_RPT_ID IN VARCHAR2, p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2);

PROCEDURE GET_POLR_NETWORK_RECON_FACTOR
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_DAILY_PLC_LOAD
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_POLR_TYPES(p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_POLR_TYPE
   (
   p_ROW_ID    IN VARCHAR2,
   p_POLR_ID   IN NUMBER,
   p_POLR_TYPE IN VARCHAR2,
   p_STATUS   OUT NUMBER,
   p_MESSAGE  OUT VARCHAR2
   );
   
PROCEDURE CUT_POLR_TYPE(p_ROW_ID IN VARCHAR2, p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2);

PROCEDURE GET_POLR_RFP_TICKETS
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_POLR_ACCEPTED_LOAD
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_POLR_INC_DEC_NOTIFICATION
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_POLR_PJM_SHORT_NAME_FILTER(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_POLR_PJM_SHORT_NAME_EMAIL
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE PUT_POLR_PJM_SHORT_NAME_EMAIL
   (
   p_PJM_SHORT          IN VARCHAR2,
   p_PJM_BASE_ID        IN NUMBER,
   p_BEGIN_DATE         IN DATE,
   p_END_DATE           IN DATE,
   p_EMAIL_DISTRIBUTION IN VARCHAR2,
   p_RPT_ID             IN VARCHAR2,
   p_STATUS            OUT NUMBER,
   p_MESSAGE           OUT VARCHAR2
   );

PROCEDURE CUT_POLR_PJM_SHORT_NAME_EMAIL(p_RPT_ID IN VARCHAR2, p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2);

PROCEDURE GET_POLR_ESCHEDULE
   (
   p_BEGIN_DATE    IN DATE,
   p_END_DATE      IN DATE,
   p_SCHEDULE_TYPE IN VARCHAR2,
   p_STATUS       OUT NUMBER,
   p_MESSAGE      OUT VARCHAR2,
   p_CURSOR       OUT GA.REFCURSOR
   );

PROCEDURE SEND_POLR_ESCHEDULE_EMAIL
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2
   );

PROCEDURE GET_POLR_7DAY_AHEAD_PLC
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE SEND_POLR_7DAY_AHEAD_PLC_EMAIL
   (
   p_BEGIN_DATE IN  DATE,
   p_END_DATE   IN  DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2
   );

PROCEDURE GET_USAGE_ESP_FILTER(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_USAGE_TARIFF_FILTER(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_USAGE_BEFORE_IMPORT
   (
   p_BEGIN_DATE      IN DATE,
   p_END_DATE        IN DATE,
   p_FILTER_SUPPLIER IN VARCHAR2,
   p_FILTER_ACCOUNT  IN VARCHAR2,
   p_FILTER_TARIFF   IN VARCHAR2,
   p_STATUS         OUT NUMBER,
   p_MESSAGE        OUT VARCHAR2,
   p_CURSOR         OUT GA.REFCURSOR
   );

PROCEDURE GET_INVALID_CODE_FILTER(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_VALID_PERIOD_USAGE
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_INVALID_PERIOD_USAGE
   (
   p_BEGIN_DATE      IN DATE,
   p_END_DATE        IN DATE,
   p_FILTER_CUSTOMER IN VARCHAR2,
   p_FILTER_CODE     IN VARCHAR2,
   p_STATUS         OUT NUMBER,
   p_MESSAGE        OUT VARCHAR2,
   p_CURSOR         OUT GA.REFCURSOR
   );

PROCEDURE PUT_INVALID_PERIOD_USAGE
   (
   p_BILL_ACCOUNT  IN NUMBER,
   p_SERVICE_POINT IN NUMBER,
   p_BEGIN_DATE    IN DATE,
   p_END_DATE      IN DATE,
   p_BILLED_USAGE  IN NUMBER,
   p_BILLED_KW     IN NUMBER,
   p_READ_CODE     IN VARCHAR2,
   p_TIME_PERIOD   IN VARCHAR2,
   p_RPT_ID        IN VARCHAR2,
   p_STATUS       OUT NUMBER,
   p_MESSAGE      OUT VARCHAR2
   );

PROCEDURE CUT_INVALID_PERIOD_USAGE(p_RPT_ID IN VARCHAR2, p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2);

PROCEDURE GET_WEIGHTED_USAGE_FACTOR
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_STATUS    OUT NUMBER,
   p_MESSAGE   OUT VARCHAR2,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_STAGED_INTERVAL_USAGE(p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_POSTED_SERVICE_LOAD_MASTER
   (
   p_ACCOUNT_IDENTIFIER IN VARCHAR2,
   p_BEGIN_DATE         IN DATE,
   p_END_DATE           IN DATE,
   p_CURSOR            OUT GA.REFCURSOR
   );

PROCEDURE GET_POSTED_SERVICE_LOAD_DETAIL
   (
   p_SERVICE_ID IN NUMBER,
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_AMI_SA_SETTLEMENT_SUMMARY(p_SETTLEMENT_MONTH IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_AMI_SA_SETTLEMENT_DETAIL(p_SETTLEMENT_MONTH IN DATE, p_SERVICE_DATE IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE GET_PLC_NSPL_INITIAL
   (
   p_SERVICE_YEAR          IN DATE,
   p_SERVICE_TYPE          IN VARCHAR2,
   p_FILTER_BILL_ACCOUNT   IN VARCHAR2,
   p_FILTER_SERVICE_POINT  IN VARCHAR2,
   p_FILTER_PREMISE_NUMBER IN VARCHAR2,
   p_CURSOR               OUT GA.REFCURSOR
   );

PROCEDURE PUT_PLC_NSPL_INITIAL
   (
   p_BILL_ACCOUNT       IN VARCHAR2,
   p_SERVICE_POINT      IN VARCHAR2,
   p_PREMISE_NUMBER     IN VARCHAR2, 
   p_PEAK_DATE          IN DATE,
   p_POINT_VAL          IN NUMBER,
   p_ENTRY_SERVICE_TYPE IN VARCHAR2
   );

PROCEDURE CUT_PLC_NSPL_INITIAL
   (
   p_BILL_ACCOUNT       IN VARCHAR2,
   p_SERVICE_POINT      IN VARCHAR2,
   p_PREMISE_NUMBER     IN VARCHAR2, 
   p_PEAK_DATE          IN DATE,
   p_ENTRY_SERVICE_TYPE IN VARCHAR2
   );

PROCEDURE MISSING_METER_READ_SUMMARY
   (
   p_BEGIN_DATE   IN DATE,
   p_END_DATE     IN DATE,
   p_SHOW_MISSING IN NUMBER,
   p_CURSOR      OUT GA.REFCURSOR
   );

PROCEDURE MISSING_METER_READ_DETAIL
   (
   p_BEGIN_DATE   IN DATE,
   p_END_DATE     IN DATE,
   p_ACCOUNT_NAME IN VARCHAR2,
   p_SERVICE_ID   IN NUMBER,
   p_CURSOR      OUT GA.REFCURSOR
   );

PROCEDURE MISSING_METER_READ_OVERVIEW
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_CURSOR    OUT GA.REFCURSOR
   );

PROCEDURE GET_POLR_DUE_DILIGENCE
   (
   p_BEGIN_DATE  IN DATE,
   p_END_DATE    IN DATE,
   p_REPORT_TYPE IN VARCHAR2,
   p_CURSOR     OUT GA.REFCURSOR
   );

PROCEDURE GET_CHANNEL_GAPS
   (
   p_BEGIN_DATE   IN DATE,
   p_END_DATE     IN DATE,
   p_SHOW_MISSING IN NUMBER,
   p_CURSOR      OUT GA.REFCURSOR
   );

PROCEDURE GET_PERIOD_METER_SUMMARY
   (
   p_BEGIN_DATE     IN DATE,
   p_END_DATE       IN DATE,
   p_GAP_COUNT     OUT VARCHAR2,
   p_OVERLAP_COUNT OUT VARCHAR2,
   p_CURSOR        OUT GA.REFCURSOR
   );

PROCEDURE GET_PERIOD_METER_DETAIL
   (
   p_BEGIN_DATE    IN DATE,
   p_END_DATE      IN DATE,
   p_BILL_ACCOUNT  IN VARCHAR2,
   p_SERVICE_POINT IN VARCHAR2,
   p_CURSOR       OUT GA.REFCURSOR
   );

PROCEDURE GET_COMMUNITY_SOLAR_ALLOCATION(p_BEGIN_DATE IN DATE, p_END_DATE IN DATE, p_CURSOR OUT GA.REFCURSOR);

PROCEDURE PUT_COMMUNITY_SOLAR_ALLOCATION
   (
   p_POLR_TYPE      IN VARCHAR2,
   p_BEGIN_DATE     IN DATE,
   p_END_DATE       IN DATE,
   p_ALLOCATION_PCT IN NUMBER,
   p_ENTRY_ROWID    IN VARCHAR2
   );
   
PROCEDURE CUT_COMMUNITY_SOLAR_ALLOCATION(p_ENTRY_ROWID IN VARCHAR2);

PROCEDURE GET_ICAP_ALLOCATIONS
   (
   p_ANCILLARY_SERVICE_ID IN NUMBER,
   p_BEGIN_DATE           IN DATE,
   p_END_DATE             IN DATE,
   p_AREA_ID              IN NUMBER,
   p_CURSOR              OUT GA.REFCURSOR
   );

PROCEDURE GET_AGG_ENROLLMENT_DETAILS
   (
   p_TIME_ZONE           IN VARCHAR2,
   p_BEGIN_DATE          IN DATE,
   p_END_DATE            IN DATE,
   p_ENROLLMENT_CASE_ID  IN NUMBER,
   p_FILTER_MODEL_ID     IN NUMBER,
   p_FILTER_SC_ID        IN NUMBER,
   p_SHOW_FILTER_SC_ID   IN NUMBER,
   p_FILTER_EDC_ID       IN NUMBER,
   p_SHOW_FILTER_EDC_ID  IN NUMBER,
   p_FILTER_ESP_ID       IN NUMBER,
   p_FILTER_PSE_ID       IN NUMBER,
   p_SHOW_FILTER_PSE_ID  IN NUMBER,
   p_FILTER_POOL_ID      IN NUMBER,
   p_SHOW_USAGE_FACTORS  IN NUMBER,
   p_SHOW_WEIGHTED_COUNT IN NUMBER,
   p_CURSOR             OUT GA.REFCURSOR
   );

PROCEDURE PUT_AGG_ENROLLMENT_DETAILS
   (
   p_LOCAL_DATE         IN DATE,
   p_ENROLLMENT_CASE_ID IN NUMBER,
   p_AGGREGATE_ID       IN NUMBER,
   p_AGG_COUNT          IN NUMBER,
   p_USAGE_FACTOR       IN NUMBER,
   p_STATUS            OUT NUMBER
   );

PROCEDURE GET_SYSTEM_SUMMARY
   (
   p_BEGIN_DATE        IN DATE,
   p_END_DATE          IN DATE,
   p_RUN_TYPE_ID       IN NUMBER,
   p_TIME_ZONE         IN VARCHAR2,
   p_INTERVAL          IN VARCHAR2,
   p_MODEL_ID          IN NUMBER,
   p_EDC_ID            IN NUMBER,
   p_CURSOR            OUT GA.REFCURSOR
   );

END CDI_REPORT;
/
