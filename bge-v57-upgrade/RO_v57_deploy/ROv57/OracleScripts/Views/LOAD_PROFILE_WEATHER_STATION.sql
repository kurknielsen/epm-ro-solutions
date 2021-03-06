CREATE OR REPLACE VIEW LOAD_PROFILE_WEATHER_STATION ( PROFILE_ID, 
WEATHER_STATION_ID ) AS SELECT E.PROFILE_ID, A.WEATHER_STATION_ID 
FROM SERVICE_LOCATION A, 
ACCOUNT_SERVICE_LOCATION B, 
ACCOUNT_CALENDAR C, 
CALENDAR_PROFILE D, 
LOAD_PROFILE E 
WHERE A.SERVICE_LOCATION_ID = B.SERVICE_LOCATION_ID 
AND B.ACCOUNT_ID = C.ACCOUNT_ID 
AND C.CALENDAR_ID = D.CALENDAR_ID 
AND D.PROFILE_ID = E.PROFILE_ID;

