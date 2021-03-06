CREATE OR REPLACE VIEW RETAIL_ACCOUNT AS SELECT * FROM ACCOUNT;

CREATE OR REPLACE VIEW PREMISE ( PREMISE_ID, 
PREMISE_NAME, PREMISE_ALIAS, PREMISE_DESC, LATITUDE, 
LONGITUDE, TIME_ZONE, EXTERNAL_IDENTIFIER, IS_EXTERNAL_BILLED_USAGE, 
IS_METER_ALLOCATION, SERVICE_POINT_ID, WEATHER_STATION_ID, 
BUSINESS_ROLLUP_ID, GEOGRAPHIC_ROLLUP_ID, ENTRY_DATE ) AS SELECT "SERVICE_LOCATION_ID","SERVICE_LOCATION_NAME","SERVICE_LOCATION_ALIAS","SERVICE_LOCATION_DESC","LATITUDE","LONGITUDE","TIME_ZONE","EXTERNAL_IDENTIFIER","IS_EXTERNAL_BILLED_USAGE","IS_METER_ALLOCATION","SERVICE_POINT_ID","WEATHER_STATION_ID","BUSINESS_ROLLUP_ID","GEOGRAPHIC_ROLLUP_ID","ENTRY_DATE" FROM SERVICE_LOCATION;
