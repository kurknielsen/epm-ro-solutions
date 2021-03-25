CREATE OR REPLACE TYPE SERVICE_MODEL_TYPE AS OBJECT  
(  
--Revision: $Revision: 1.25 $
  ACCOUNT_BEGIN_DATE DATE,
  ACCOUNT_END_DATE DATE,
  EDC_BEGIN_DATE DATE,
  EDC_END_DATE DATE,
  ESP_BEGIN_DATE DATE,
  ESP_END_DATE DATE,
  PSE_BEGIN_DATE DATE,
  PSE_END_DATE DATE,
  SERVICE_LOCATION_BEGIN_DATE DATE,
  SERVICE_LOCATION_END_DATE DATE,
  METER_BEGIN_DATE DATE,
  METER_END_DATE DATE,
  ACCOUNT_ID NUMBER(9),
  SERVICE_LOCATION_ID NUMBER(9),
  METER_ID NUMBER(9),
  AGGREGATE_ID NUMBER(9),
  EDC_ID NUMBER(9),
  HOLIDAY_SET_ID NUMBER(9),
  ESP_ID NUMBER(9),
  POOL_ID NUMBER(9),
  PSE_ID NUMBER(9),
  SERVICE_POINT_ID NUMBER(9),
  STATION_ID NUMBER(9),
  IS_EXTERNAL_FORECAST NUMBER(1),
  IS_UFE_PARTICIPANT NUMBER(1),
  IS_CREATE_SETTLEMENT_PROFILE NUMBER(1),
  IS_WHOLESALE NUMBER(1),
  METER_TYPE CHAR(1),
  ACCOUNT_NAME VARCHAR(128),
  ACCOUNT_EXTERNAL_IDENTIFIER VARCHAR(64),
  METER_NAME VARCHAR(128),
  METER_EXTERNAL_IDENTIFIER VARCHAR(128),
  ACCOUNT_SERVICE_ID NUMBER(9),
  PROVIDER_SERVICE_ID NUMBER(9)
);
/
CREATE OR REPLACE TYPE SERVICE_MODEL_TABLE IS TABLE OF SERVICE_MODEL_TYPE;
/