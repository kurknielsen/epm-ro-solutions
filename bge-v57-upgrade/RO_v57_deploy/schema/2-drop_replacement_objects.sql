DROP PACKAGE AN;
DROP PACKAGE BO;
DROP PACKAGE BSJ;
DROP PACKAGE CA;
DROP PACKAGE CD;
DROP PACKAGE CR;
DROP PACKAGE CS;
DROP PACKAGE CU;
DROP PACKAGE CX;
DROP PACKAGE DE;
DROP PACKAGE DX;
DROP PACKAGE EM;
DROP PACKAGE EN;
DROP PACKAGE EX;
DROP PACKAGE FL;
DROP PACKAGE FP;
DROP PACKAGE FS;
DROP PACKAGE FW;
DROP PACKAGE GA;
DROP PACKAGE IA;
DROP PACKAGE ID;
DROP PACKAGE IO;
DROP PACKAGE ITJ;
DROP PACKAGE LB;
DROP PACKAGE LI;
DROP PACKAGE MEX_UTIL;
DROP PACKAGE ML;
DROP PACKAGE MM;
DROP PACKAGE MS;
DROP PACKAGE PC;
DROP PACKAGE PF;
DROP PACKAGE PI;
DROP PACKAGE PLOG;
DROP PACKAGE PM;
DROP PACKAGE PR;
DROP PACKAGE QC;
DROP PACKAGE QI;
DROP PACKAGE QM;
DROP PACKAGE RA;
DROP PACKAGE RO;
DROP PACKAGE RS;
DROP PACKAGE RX;
DROP PACKAGE SA;
DROP PACKAGE SD;
DROP PACKAGE SO;
DROP PACKAGE SP;
DROP PACKAGE ST;
DROP PACKAGE TG;
DROP PACKAGE TM;
DROP PACKAGE UT;
DROP PACKAGE WR;
DROP PACKAGE WRF_UI;
DROP PACKAGE XS;

DROP FUNCTION ADD_HOURS_TO_DATE;
DROP FUNCTION ADD_MINUTES_TO_DATE;
DROP FUNCTION ADD_SECONDS_TO_DATE;
DROP FUNCTION ADVANCE_DATE;
DROP FUNCTION AGGREGATE_ACCOUNT_AS_OF_DATE;
DROP FUNCTION ALIGN_DATE_BY_INTERVAL;
DROP FUNCTION AREA_LOAD_AS_OF_DATE;
DROP FUNCTION AS_DAY;
DROP FUNCTION AS_HOUR_ENDING_DATE;
DROP FUNCTION BEGIN_CUT_DAY_INTERVAL;
DROP FUNCTION BEGIN_HOUR_ENDING_CUT_DAY;
DROP FUNCTION BEGIN_HOUR_ENDING_GMT_DAY;
DROP FUNCTION CAN_DELETE;
DROP FUNCTION CAN_READ;
DROP FUNCTION CAN_WRITE;
DROP FUNCTION CORRECTED_AS_OF_DATE;
DROP FUNCTION CURRENT_VERSION_DATE;
DROP FUNCTION CUT_DATE_BETWEEN;
DROP FUNCTION CUT_TIME_ZONE;
DROP FUNCTION DATE_DAY_NAME;
DROP FUNCTION DATE_FROM_CUT_AS_HED;
DROP FUNCTION DATE_IS_WITHIN_SEASON;
DROP FUNCTION DATE_TIME_AS_CUT;
DROP FUNCTION DECODE_DATE;
DROP FUNCTION DECODE_TIME_ZONE;
DROP FUNCTION DST_FALL_BACK_DATE;
DROP FUNCTION DST_SPRING_AHEAD_DATE;
DROP FUNCTION DST_TIME_ZONE;
DROP FUNCTION EDC_IMBALANCE_AS_OF_DATE;
DROP FUNCTION ENCODE_DATE;
DROP FUNCTION END_CUT_DAY_INTERVAL;
DROP FUNCTION END_HOUR_ENDING_CUT_DAY;
DROP FUNCTION END_HOUR_ENDING_GMT_DAY;
DROP FUNCTION ENTITY_NAME_FROM_IDS;
DROP FUNCTION ENTITY_NAME_FROM_ID_TABLE;
DROP FUNCTION FIRST_DAY;
DROP FUNCTION FROM_CUT;
DROP FUNCTION FROM_CUT_AS_HED;
DROP FUNCTION FROM_GMT;
DROP FUNCTION FROM_GMT_AS_HED;
DROP FUNCTION FROM_HED;
DROP FUNCTION GET_DATA_INTERVAL_TYPE;
DROP FUNCTION GET_DICTIONARY_VALUE;
DROP FUNCTION GET_INTERVAL_ABBREVIATION;
DROP FUNCTION GET_INTERVAL_NUMBER;
DROP FUNCTION HAS_ACCESS_CHAR;
DROP FUNCTION HIGH_DATE;
DROP FUNCTION HOLIDAY_DAY_TYPE;
DROP FUNCTION HOLIDAY_OBSERVANCE_DAY;
DROP FUNCTION INTERVAL_IS_ATLEAST_DAILY;
DROP FUNCTION INVOICE_AS_OF_DATE;
DROP FUNCTION IN_CANDIDATE_LIST;
DROP FUNCTION IS_DAY_INTERVAL_OF_TYPE;
DROP FUNCTION IS_HOLIDAY;
DROP FUNCTION IS_HOLIDAY_FOR_SET;
DROP FUNCTION IS_IN_DST_TIME_PERIOD;
DROP FUNCTION IT_STATUS_AS_OF_DATE;
DROP FUNCTION LOCAL_TIME_ZONE;
DROP FUNCTION LOW_DATE;
DROP FUNCTION MAKE_TAG;
DROP FUNCTION MARKET_PRICE_AS_OF_DATE;
DROP FUNCTION MAX_DATA_LENGTH;
DROP FUNCTION MODEL_VALUE_AT_KEY;
DROP FUNCTION NEW_DATE;
DROP FUNCTION NULL_DATE;
DROP FUNCTION NUM_METER_ASSIGNMENTS;
DROP FUNCTION NUM_SERVICE_LOC_ASSIGNMENTS;
DROP FUNCTION OFF_PEAK_HOLIDAY;
DROP FUNCTION PEAK_TYPE;
DROP FUNCTION PROFILE_POINT_AS_OF_DATE;
DROP FUNCTION PROFILE_STATISTICS_AS_OF_DATE;
DROP FUNCTION PROFILE_WRF_AS_OF_DATE;
DROP FUNCTION RETAIL_ACCOUNT_DISPLAY_NAME;
DROP FUNCTION SCHEDULE_AS_OF_DATE;
DROP FUNCTION SEASON_INTERSECTS_SEASON;
DROP FUNCTION SHADOW_SETTLEMENT_AS_OF_DATE;
DROP FUNCTION STATEMENT_AS_OF_DATE;
DROP FUNCTION STD_TIME_ZONE;
DROP FUNCTION TEMPLATE_BEGIN_DATE;
DROP FUNCTION TIME_FROM_CUT_AS_HED;
DROP FUNCTION TIME_PERIOD_FOR_DATE;
DROP FUNCTION TIME_ZONE_FOR_DAY;
DROP FUNCTION TO_CUT;
DROP FUNCTION TO_CUT_WITH_OPTIONS;
DROP FUNCTION TO_GMT;
DROP FUNCTION TO_HED;
DROP FUNCTION TO_HED_AS_DATE;
DROP FUNCTION VALUE_AT_KEY;
DROP FUNCTION VALUE_AT_KEY_3;
DROP FUNCTION WEEK_DAYS_IN_RANGE;

DROP PROCEDURE BEGIN_END_START_STOP_RANGE;
DROP PROCEDURE DAYLIGHT_SAVINGS_TIME;
DROP PROCEDURE DECODE_TAG;
DROP PROCEDURE ENCODE_TAG;
DROP PROCEDURE GET_ACCOUNT_DISPLAY_NAME;
DROP PROCEDURE GET_ADMIN_ACCESS_CODE;
DROP PROCEDURE GET_CUT_TIME_ZONE;
DROP PROCEDURE GET_DICTIONARY_SETTING_VALUE;
DROP PROCEDURE GET_ENTITY;
DROP PROCEDURE GET_MODEL_VALUE_AT_KEY;
DROP PROCEDURE GET_VALUE_AT_KEY;
DROP PROCEDURE GET_VALUE_AT_KEY_3;
DROP PROCEDURE NUM_DAY_TYPES_IN_MONTH;
DROP PROCEDURE POST_APP_EVENT;
DROP PROCEDURE POST_TO_APP_EVENT_LOG;
DROP PROCEDURE PUT_DICTIONARY_VALUE;
DROP PROCEDURE PUT_MODEL_VALUE_AT_KEY;
DROP PROCEDURE PUT_VALUE_AT_KEY;
DROP PROCEDURE PUT_VALUE_AT_KEY_3;
DROP PROCEDURE TRANSLATE_OLD_DICTIONARY_KEYS;

DROP TYPE ACCOUNT_CALENDAR_SYNC_TABLE;
DROP TYPE ACCOUNT_EDC_SYNC_TABLE;
DROP TYPE ACCOUNT_ESP_SERVICE_TABLE;
DROP TYPE ACCOUNT_ESP_TABLE;
DROP TYPE ACCOUNT_IDENT_TABLE;
DROP TYPE ACCOUNT_LOSS_FACTOR_SYNC_TABLE;
DROP TYPE ACCOUNT_SERVICE_TABLE;
DROP TYPE ACCOUNT_SYNC_TABLE;
DROP TYPE ACCOUNT_USAGE_TABLE;
DROP TYPE ACCOUNT_USG_FACTOR_SYNC_TABLE;
DROP TYPE AGGREGATE_ACCOUNT_GROWTH_TABLE;
DROP TYPE AGGREGATE_CUSTOMER_TABLE;
DROP TYPE AGGREGATE_SERVICE_SYNC_TABLE;
DROP TYPE AGG_RESULTS_TABLE;
DROP TYPE ALLOCATION_CANDIDATE_TABLE;
DROP TYPE ANCILLARY_SERVICE_SYNC_TABLE;
DROP TYPE ANCILLARY_WORK_TABLE;
DROP TYPE AREA_LOAD_SYNC_TABLE;
DROP TYPE BID_OFFER_COMPOSITE_TABLE;
DROP TYPE BID_OFFER_HOURS_TABLE;
DROP TYPE BID_OFFER_RAMP_TABLE;
DROP TYPE BID_OFFER_REASON_TABLE;
DROP TYPE BID_OFFER_SET_TABLE;
DROP TYPE BIG_STRING_TABLE;
DROP TYPE BILLING_SUMMARY_RECORD_TABLE;
DROP TYPE BLOB_COLLECTION;
DROP TYPE CAPACITY_RELEASE_TABLE;
DROP TYPE CAPACITY_REPORT_TEMP_TABLE;
DROP TYPE CAST_TABLE;
DROP TYPE CHARGE_COMPONENT_TABLE;
DROP TYPE CLOB_CHUNK_TABLE;
DROP TYPE COLUMN_TABLE;
DROP TYPE CONSUMPTION_TABLE;
DROP TYPE CONTRACT_SCHEDULE_TABLE;
DROP TYPE CUSTOMER_ATTRIBUTE_TABLE;
DROP TYPE DATE_COLLECTION FORCE;
DROP TYPE DATE_COLLECTION_COLLECTION FORCE;
DROP TYPE DATE_RANGE_TABLE;
DROP TYPE DELIVERY_POSITION_TABLE;
DROP TYPE DELIVERY_SCHEDULE_TABLE;
DROP TYPE DETERMINANT_TABLE;
DROP TYPE DISPUTE_DETAIL_TABLE;
DROP TYPE ENROLLMENT_SUMMARY_TABLE;
DROP TYPE ENTITY_SELECTION_TABLE;
DROP TYPE ENTITY_SERVICE_LOCATION_TABLE;
DROP TYPE ENTITY_SUBTAB_COLS_TABLE;
DROP TYPE ENTITY_XREF_TABLE;
DROP TYPE ESP_SYNC_TABLE;
DROP TYPE EVENT_TABLE;
DROP TYPE EXT_FORECAST_IDENT_TABLE;
DROP TYPE EXT_FORECAST_SYNC_TABLE;
DROP TYPE FORWARD_TABLE;
DROP TYPE HOLIDAY_OBSERVANCE_SYNC_TABLE;
DROP TYPE IDENT_TABLE;
DROP TYPE ID_SET_COLLECTION;
DROP TYPE ID_TABLE;
DROP TYPE IMBALANCE_POSITION_TABLE;
DROP TYPE IMBALANCE_SCHEDULE_TABLE;
DROP TYPE IMBALANCE_TRANSACTION_TABLE;
DROP TYPE INVOICE_LINE_ITEM_FORMAT_TABLE;
DROP TYPE INVOICE_LINE_ITEM_TABLE;
DROP TYPE INVOICE_VALID_RECORD_TABLE;
DROP TYPE LOAD_OBLIGATION_TABLE;
DROP TYPE LOAD_RESULT_DATA_TABLE;
DROP TYPE LOSS_FACTOR_PATTERN_TABLE;
DROP TYPE LOSS_FACTOR_SYNC_TABLE;
DROP TYPE MAP_ENTRY_TABLE FORCE;
DROP TYPE METER_SERVICE_TABLE;
DROP TYPE MEX_CERTIFICATE_TBL FORCE;
DROP TYPE MEX_COOKIE_TBL FORCE;
DROP TYPE MEX_CREDENTIALS_TBL FORCE;
DROP TYPE NUMBER_COLLECTION FORCE;
DROP TYPE NUMBER_COLLECTION_COLLECTION;
DROP TYPE PATH_FUEL_TABLE;
DROP TYPE POSITION_ANALYSIS_LOAD_TABLE;
DROP TYPE POSITION_DETAIL_TABLE;
DROP TYPE PRICE_QUANTITY_SUMMARY_TABLE FORCE;
DROP TYPE PRICING_RESULT_TABLE FORCE;
DROP TYPE PROFILERECORDTABLE;
DROP TYPE PROFILE_POINT_TABLE;
DROP TYPE PROJECTION_PATTERN_TABLE;
DROP TYPE PROJECTION_TABLE;
DROP TYPE PROVIDER_POSITION_TABLE;
DROP TYPE RTO_WORK_BIG_TABLE;
DROP TYPE RTO_WORK_TABLE;
DROP TYPE SCHEDULE_COMPARE_TABLE;
DROP TYPE SCHEDULE_STATE_TABLE;
DROP TYPE SEASON_TEMPLATE_DEF_TABLE;
DROP TYPE SERVICE_COMPONENT_TABLE;
DROP TYPE SERVICE_CONSUMPTION_TABLE;
DROP TYPE SERVICE_IDENT_TABLE;
DROP TYPE SERVICE_MODEL_TABLE;
DROP TYPE SERVICE_OBLIGATION_LOAD_TABLE;
DROP TYPE SERVICE_PROFILE_INFO_TABLE;
DROP TYPE SERVICE_STATEMENT_TABLE;
DROP TYPE SERVICE_SYNC_TABLE;
DROP TYPE SERVICE_USAGE_TABLE;
DROP TYPE SERVICE_VALIDATION_TABLE;
DROP TYPE STATION_PARAMETER_SYNC_TABLE;
DROP TYPE STATION_PARAMETER_TABLE;
DROP TYPE STORAGE_FUEL_TABLE;
DROP TYPE STORAGE_SCHEDULE_TABLE;
DROP TYPE STORED_PROC_PARAMETER_TABLE;
DROP TYPE STRING_COLLECTION FORCE;
DROP TYPE STRING_COLLECTION_COLLECTION;
DROP TYPE STRING_TABLE;
DROP TYPE SYSTEM_OBJECT_PRIV_INFO_TBL;
DROP TYPE TAX_TABLE;
DROP TYPE TEMPLATE_PARAMETER_TABLE;
DROP TYPE TIERED_RATE_TABLE;
DROP TYPE TOU_TABLE;
DROP TYPE USAGE_ALLOCATION_TABLE;
DROP TYPE USAGE_TABLE;
DROP TYPE WRF_OBSERVATION_TABLE;
DROP TYPE WRF_SEASON_BREAKPOINT_TABLE;

DROP TYPE MEX_COOKIE FORCE;
DROP TYPE MEX_CREDENTIALS FORCE;
DROP TYPE MEX_RESULT FORCE;
DROP TYPE MEX_LOGGER FORCE;
DROP TYPE MM_LOGGER_ADAPTER FORCE;
DROP TYPE PRICING_RESULT FORCE;
DROP TYPE DETERMINANT_ACCESSOR FORCE;
DROP TYPE TIME_SERIES_TYPE FORCE;
DROP TYPE TRANSPOSED_VALUES_TYPE FORCE;