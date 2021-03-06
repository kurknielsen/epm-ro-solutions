DROP INDEX AK2_IT_ASSIGNMENT;
DROP INDEX AK2_IT_ASSIGNMENT_OPTION;
DROP INDEX AK_IT_ASSIGNMENT;
DROP INDEX AK_IT_ASSIGNMENT_OPTION;
DROP INDEX AK_IT_TRAIT_SCHEDULE;
DROP INDEX AK_SYSTEM_DATE_TIME;
DROP INDEX CALENDAR_IX01;
DROP INDEX ENTITY_AUDIT_TRAIL_IX01;
DROP INDEX INTERCHANGE_TRANSACTION_IX01;

DROP TRIGGER ACCOUNT_DELETE;
DROP TRIGGER ADDRESS_DELETE;
DROP TRIGGER CATEGORY_DELETE;
DROP TRIGGER COMPONENT_FORMULA_ITERATOR_DEL;
DROP TRIGGER CONTACT_DELETE;
DROP TRIGGER CONTRACT_PRODUCT_DELETE;
DROP TRIGGER CONTRACT_PRODUCT_UPDATE;
DROP TRIGGER CONTRACT_PROD_COMPONENT_UPDATE;
DROP TRIGGER FORMULA_CHARGE_DELETE;
DROP TRIGGER INTERCHANGE_CONTRACT_UPDATE;
DROP TRIGGER INTERCHANGE_TRANSACTION_DELETE;
DROP TRIGGER IT_DELIVERY_SCHEDULE_DELETE;
DROP TRIGGER LOSS_FACTOR_DELETE;
DROP TRIGGER LOSS_FACTOR_MODEL_DELETE;
DROP TRIGGER MARKET_PRICE_DELETE;
DROP TRIGGER PIPELINE_POINT_DELETE;
DROP TRIGGER PRODUCT_COMPONENT_DELETE;
DROP TRIGGER SCHEDULER_DELETE;
DROP TRIGGER SEASON_DELETE;
DROP TRIGGER SERVICE_CONSUMPTION_DELETE;
DROP TRIGGER SUB_STATION_DELETE;
DROP TRIGGER SUB_STATION_METER_DELETE;
DROP TRIGGER SYSTEM_REALM_UPDATE;
DROP TRIGGER TRANSPORTATION_LEG_POST;
DROP TRIGGER TRANSPORTATION_LEG_UPDATE;
DROP TRIGGER USAGE_WRF_TEMPLATE_DELETE;
DROP TRIGGER ZAU_COMPONENT_COINCIDENT_PK_D;
DROP TRIGGER ZAU_COMPONENT_COINCIDENT_PK_I;
DROP TRIGGER ZAU_COMPONENT_COINCIDENT_PK_U;
DROP TRIGGER ZAU_INTERCHANGE_TRANSACTION_D;
DROP TRIGGER ZAU_INTERCHANGE_TRANSACTION_I;
DROP TRIGGER ZAU_INTERCHANGE_TRANSACTION_U;
DROP TRIGGER ZAU_IT_SCHEDULE_D;
DROP TRIGGER ZAU_IT_SCHEDULE_I;
DROP TRIGGER ZAU_IT_SCHEDULE_U;
DROP TRIGGER ZAU_IT_STATUS_D;
DROP TRIGGER ZAU_IT_STATUS_I;
DROP TRIGGER ZAU_IT_STATUS_U;
DROP TRIGGER ZAU_IT_TRAIT_SCHEDULE_D;
DROP TRIGGER ZAU_IT_TRAIT_SCHEDULE_I;
DROP TRIGGER ZAU_IT_TRAIT_SCHEDULE_U;
DROP TRIGGER ZAU_MARKET_PRICE_VALUE_D;
DROP TRIGGER ZAU_MARKET_PRICE_VALUE_I;
DROP TRIGGER ZAU_MARKET_PRICE_VALUE_U;

DROP VIEW ACCOUNT_SERVICE_BILL_TREE;
DROP VIEW ADDRESS_DOMAIN;
DROP VIEW ADDRESS_ENTITY;
DROP VIEW CITY_GATE_DOMAIN;
DROP VIEW CITY_GATE_ENTITY;
DROP VIEW CONTRACT_PRODUCT_INFO;
DROP VIEW CONTRACT_PROD_COMPONENT_INFO;
DROP VIEW EDC_COMPONENT;
DROP VIEW INTERCHANGE_CONTRACT_COMPONENT;
DROP VIEW MARKET_PATH_DOMAIN;
DROP VIEW MARKET_PATH_ENTITY;
DROP VIEW MARKET_SEGMENT_DOMAIN;
DROP VIEW MARKET_SEGMENT_ENTITY;
DROP VIEW PHYSICAL_SEGMENT_DOMAIN;
DROP VIEW PHYSICAL_SEGMENT_ENTITY;
DROP VIEW PIPELINE_POINT_DOMAIN;
DROP VIEW PIPELINE_POINT_ENTITY;
DROP VIEW PIPELINE_SEGMENT_DOMAIN;
DROP VIEW PIPELINE_SEGMENT_ENTITY;
DROP VIEW PIPELINE_ZONE_DOMAIN;
DROP VIEW PIPELINE_ZONE_ENTITY;
DROP VIEW PSE_COMPONENT;
DROP VIEW RESOURCE_DOMAIN;
DROP VIEW RESOURCE_ENTITY;
DROP VIEW SALES_REP_DOMAIN;
DROP VIEW SALES_REP_ENTITY;
DROP VIEW SCHEDULER_DOMAIN;
DROP VIEW SCHEDULER_ENTITY;
DROP VIEW SHIPPER_DOMAIN;
DROP VIEW SHIPPER_ENTITY;
DROP VIEW STORAGE_DOMAIN;
DROP VIEW STORAGE_ENTITY;
DROP VIEW SYSTEM_REALM_TYPE_DOMAIN;
DROP VIEW SYSTEM_REALM_TYPE_ENTITY;
DROP VIEW TRANSPORTATION_PATH_DOMAIN;
DROP VIEW TRANSPORTATION_PATH_ENTITY;
DROP VIEW TX_SEGMENT_COMPONENT;
DROP VIEW TX_SERVICE_POINT_COMPONENT;
DROP VIEW TX_SERVICE_TYPE_COMPONENT;
DROP VIEW TX_SUB_STATION_COMPONENT;
DROP VIEW TX_SUB_STATION_METER_COMPONENT;

DROP TABLE ACCOUNT_SALES_REP CASCADE CONSTRAINTS PURGE;
DROP TABLE ADDRESS CASCADE CONSTRAINTS PURGE;
DROP TABLE APP_EVENT_LOG CASCADE CONSTRAINTS PURGE;
DROP TABLE CITY_GATE CASCADE CONSTRAINTS PURGE;
DROP TABLE COMPONENT_FORMULA_ITERATOR_COL CASCADE CONSTRAINTS PURGE;
DROP TABLE CONTRACT_PRODUCT CASCADE CONSTRAINTS PURGE;
DROP TABLE ENTITY_AUDIT_TRAIL CASCADE CONSTRAINTS PURGE;
DROP TABLE INVOICE_REPORT_TEMPLATE CASCADE CONSTRAINTS PURGE;
DROP TABLE IT_CUSTOM_VIEW CASCADE CONSTRAINTS PURGE;
DROP TABLE IT_CUSTOM_VIEW_FILTERS CASCADE CONSTRAINTS PURGE;
DROP TABLE IT_DELIVERY_PATH_SCHEDULE CASCADE CONSTRAINTS PURGE;
DROP TABLE IT_DELIVERY_SCHEDULE CASCADE CONSTRAINTS PURGE;
DROP TABLE IT_TRANSPORTATION_PATH CASCADE CONSTRAINTS PURGE;
DROP TABLE MARKET_PATH CASCADE CONSTRAINTS PURGE;
DROP TABLE MARKET_SEGMENT CASCADE CONSTRAINTS PURGE;
DROP TABLE METER_STATUS CASCADE CONSTRAINTS PURGE;
DROP TABLE MKT_PATH_MKT_SEG CASCADE CONSTRAINTS PURGE;
DROP TABLE MKT_SEG_PHYS_SEG CASCADE CONSTRAINTS PURGE;
DROP TABLE PHYSICAL_SEGMENT CASCADE CONSTRAINTS PURGE;
DROP TABLE PIPELINE_POINT CASCADE CONSTRAINTS PURGE;
DROP TABLE PIPELINE_SEGMENT CASCADE CONSTRAINTS PURGE;
DROP TABLE PIPELINE_SEGMENT_FUEL CASCADE CONSTRAINTS PURGE;
DROP TABLE PIPELINE_ZONE CASCADE CONSTRAINTS PURGE;
DROP TABLE PROCESS_MONITOR CASCADE CONSTRAINTS PURGE;
DROP TABLE PROCESSES CASCADE CONSTRAINTS PURGE;
DROP TABLE PROCESS_EVENTS CASCADE CONSTRAINTS PURGE;

DROP TABLE SALES_REP CASCADE CONSTRAINTS PURGE;
DROP TABLE SCHEDULER CASCADE CONSTRAINTS PURGE;
DROP TABLE SCHEDULE_UPLOAD_FORMAT CASCADE CONSTRAINTS PURGE;
DROP TABLE SCHEDULING_VIEW_CONFIG CASCADE CONSTRAINTS PURGE;
DROP TABLE SERVICE_CONTRACT_NOTE CASCADE CONSTRAINTS PURGE;
DROP TABLE SERVICE_POINT_CITY_GATE CASCADE CONSTRAINTS PURGE;
DROP TABLE SHIPPER CASCADE CONSTRAINTS PURGE;
DROP TABLE STORAGE_FACILITY CASCADE CONSTRAINTS PURGE;
DROP TABLE STORAGE_PERIOD CASCADE CONSTRAINTS PURGE;
DROP TABLE STORAGE_PERIOD_FUEL CASCADE CONSTRAINTS PURGE;
DROP TABLE SYSTEM_REALM_TYPE CASCADE CONSTRAINTS PURGE;
DROP TABLE TRANSPORTATION_LEG CASCADE CONSTRAINTS PURGE;
DROP TABLE TRANSPORTATION_PATH CASCADE CONSTRAINTS PURGE;
DROP TABLE TX_SUB_STATION_METER_VALUE CASCADE CONSTRAINTS PURGE;
DROP TABLE IT_ASSIGNMENT_OPTION CASCADE CONSTRAINTS PURGE;
DROP TABLE TRACE;

DROP TYPE SEASON_TEMPLATE_PERIOD_TABLE;
DROP TYPE VARIABLE_TABLE;

DROP TYPE SEASON_TEMPLATE_PERIOD_TYPE FORCE;
DROP TYPE VARIABLE_TYPE FORCE;

DROP SYNONYM METER_BANK;
DROP SYNONYM METER_POINT;

DROP PACKAGE AU;
DROP PACKAGE BS;
DROP PACKAGE EL;
DROP PACKAGE GB;
DROP PACKAGE GD;
DROP PACKAGE HT;
DROP PACKAGE IT;
DROP PACKAGE LF;
DROP PACKAGE PB;
DROP PACKAGE RN;
DROP PACKAGE ZBUILD_BILLING_TAB_OBJECTS;
DROP PACKAGE ZBUILD_ENTITY_MANAGER_OBJECTS;
DROP PACKAGE ZBUILD_SCHEDULING_OBJECTS;

DROP PROCEDURE COMPILE_PACKAGES;

DROP FUNCTION DATE_IS_WITHIN_PERIOD;
DROP FUNCTION TEMPLATE_PERIOD_FOR_DATE;

DROP SEQUENCE DID;
DROP SEQUENCE PID;
