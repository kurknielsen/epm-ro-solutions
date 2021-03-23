
-- Capture The Content In The Target Tables To Be Migrated To Staging Tables --
-- Retain 13 Months of Load Profile Point Data
CREATE TABLE X_CALENDAR                AS SELECT * FROM CALENDAR                WHERE CALENDAR_ID IN (50243,50227,50284,50286,50263,50282,50294,50241,50257,50296);
CREATE TABLE X_CALENDAR_PROFILE        AS SELECT * FROM CALENDAR_PROFILE        WHERE CALENDAR_ID IN (50243,50227,50284,50286,50263,50282,50294,50241,50257,50296);
CREATE TABLE X_LOAD_PROFILE            AS SELECT * FROM LOAD_PROFILE            WHERE PROFILE_ID IN (SELECT PROFILE_ID FROM CALENDAR_PROFILE WHERE CALENDAR_ID IN (50243,50227,50284,50286,50263,50282,50294,50241,50257,50296));
CREATE TABLE X_LOAD_PROFILE_LIBRARY    AS SELECT * FROM LOAD_PROFILE_LIBRARY    WHERE PROFILE_LIBRARY_ID IN (SELECT DISTINCT PROFILE_LIBRARY_ID FROM LOAD_PROFILE WHERE PROFILE_ID IN (SELECT PROFILE_ID FROM CALENDAR_PROFILE WHERE CALENDAR_ID IN (50243,50227,50284,50286,50263,50282,50294,50241,50257,50296)));
CREATE TABLE X_LOAD_PROFILE_POINT      AS SELECT * FROM LOAD_PROFILE_POINT      WHERE PROFILE_ID IN (SELECT PROFILE_ID FROM LOAD_PROFILE WHERE PROFILE_ID IN (SELECT PROFILE_ID FROM CALENDAR_PROFILE WHERE CALENDAR_ID IN (50243,50227,50284,50286,50263,50282,50294,50241,50257,50296))) AND POINT_DATE >= TRUNC(ADD_MONTHS(CURRENT_DATE,-13),'MONTH') + CASE WHEN TRUNC(ADD_MONTHS(CURRENT_DATE,-13),'MONTH') BETWEEN TO_DATE('3/10/2019','MM/DD/YYYY') AND TO_DATE('11/3/2019','MM/DD/YYYY') THEN 0 ELSE 1/24 END;
CREATE TABLE X_LOAD_PROFILE_STATISTICS AS SELECT * FROM LOAD_PROFILE_STATISTICS WHERE PROFILE_ID IN (SELECT PROFILE_ID FROM LOAD_PROFILE WHERE PROFILE_ID IN (SELECT PROFILE_ID FROM CALENDAR_PROFILE WHERE CALENDAR_ID IN (50243,50227,50284,50286,50263,50282,50294,50241,50257,50296)));

-- Retain 13 Months of Market Price Data
CREATE TABLE X_MARKET_PRICE       AS SELECT * FROM MARKET_PRICE WHERE MARKET_PRICE_NAME IN ('BGE RT','BGE CONG','BGE LOSS','PJM System Energy Price');
CREATE TABLE X_MARKET_PRICE_VALUE AS SELECT * FROM MARKET_PRICE_VALUE WHERE MARKET_PRICE_ID IN (SELECT MARKET_PRICE_ID FROM MARKET_PRICE WHERE MARKET_PRICE_NAME IN ('BGE RT','BGE CONG','BGE LOSS','PJM System Energy Price')) AND PRICE_DATE >= TRUNC(ADD_MONTHS(CURRENT_DATE,-13),'MONTH') + CASE WHEN TRUNC(ADD_MONTHS(CURRENT_DATE,-13),'MONTH') BETWEEN TO_DATE('3/10/2019','MM/DD/YYYY') AND TO_DATE('11/3/2019','MM/DD/YYYY') THEN 0 ELSE 1/24 END;

-- Retain 13 Months of System Area Load Data
CREATE TABLE X_SYSTEM_LOAD      AS SELECT * FROM SYSTEM_LOAD WHERE SYSTEM_LOAD_ID > 0; 
CREATE TABLE X_AREA             AS SELECT * FROM AREA WHERE AREA_ID > 0;
CREATE TABLE X_SYSTEM_LOAD_AREA AS SELECT * FROM SYSTEM_LOAD_AREA;
CREATE TABLE X_AREA_LOAD        AS SELECT * FROM AREA_LOAD WHERE LOAD_DATE >= TRUNC(ADD_MONTHS(CURRENT_DATE,-13),'MONTH') + CASE WHEN TRUNC(ADD_MONTHS(CURRENT_DATE,-13),'MONTH') BETWEEN TO_DATE('3/10/2019','MM/DD/YYYY') AND TO_DATE('11/3/2019','MM/DD/YYYY') THEN 0 ELSE 1/24 END;

-- Retain 13 Months of Weather Data
CREATE TABLE X_WEATHER_STATION           AS SELECT * FROM WEATHER_STATION WHERE STATION_ID > 0;
CREATE TABLE X_WEATHER_PARAMETER         AS SELECT * FROM WEATHER_PARAMETER WHERE PARAMETER_ID > 0;
CREATE TABLE X_WEATHER_STATION_PARAMETER AS SELECT * FROM WEATHER_STATION_PARAMETER;
CREATE TABLE X_WEATHER_STATION_COMPOSITE AS SELECT * FROM WEATHER_STATION_COMPOSITE;
CREATE TABLE X_STATION_PARAMETER_VALUE   AS SELECT * FROM STATION_PARAMETER_VALUE WHERE PARAMETER_DATE >= TRUNC(ADD_MONTHS(CURRENT_DATE,-24),'MONTH') + CASE WHEN TRUNC(ADD_MONTHS(CURRENT_DATE,-24),'MONTH') BETWEEN TO_DATE('3/10/2019','MM/DD/YYYY') AND TO_DATE('11/3/2019','MM/DD/YYYY') OR TRUNC(ADD_MONTHS(CURRENT_DATE,-24),'MONTH') BETWEEN TO_DATE('3/11/2018','MM/DD/YYYY') AND TO_DATE('11/4/2018','MM/DD/YYYY')THEN 0 ELSE 1/24 END;

-- Loss Factors
CREATE TABLE X_LOSS_FACTOR         AS SELECT * FROM LOSS_FACTOR WHERE LOSS_FACTOR_ID > 0 AND LOSS_FACTOR_NAME NOT LIKE '% ALM %' AND LOSS_FACTOR_NAME <> 'Deration Loss Factor';
CREATE TABLE X_LOSS_FACTOR_MODEL   AS SELECT * FROM LOSS_FACTOR_MODEL WHERE LOSS_FACTOR_ID IN (SELECT LOSS_FACTOR_ID FROM X_LOSS_FACTOR);
CREATE TABLE X_LOSS_FACTOR_PATTERN AS SELECT * FROM LOSS_FACTOR_PATTERN WHERE PATTERN_ID IN (SELECT PATTERN_ID FROM X_LOSS_FACTOR_MODEL);

COLUMN TABLE_NAME   FORMAT A32
COLUMN EARLY_DATE FORMAT A32
COLUMN LATE_DATE FORMAT A32
COLUMN ENTRY_COUNT  FORMAT A16

SELECT 'X_AREA_LOAD' "TABLE_NAME", TO_CHAR(MIN(LOAD_DATE),'MM/DD/YYYY HH24:MI:SS') "EARLY_DATE", TO_CHAR(MAX(LOAD_DATE),'MM/DD/YYYY HH24:MI:SS') "LATE_DATE", TO_CHAR(COUNT(*)) "ENTRY_COUNT" FROM X_AREA_LOAD UNION
SELECT 'X_MARKET_PRICE_VALUE' "TABLE_NAME", TO_CHAR(MIN(PRICE_DATE),'MM/DD/YYYY HH24:MI:SS') "EARLY_DATE", TO_CHAR(MAX(PRICE_DATE),'MM/DD/YYYY HH24:MI:SS') "LATE_DATE", TO_CHAR(COUNT(*)) "ENTRY_COUNT" FROM X_MARKET_PRICE_VALUE UNION
SELECT 'X_LOAD_PROFILE_POINT' "TABLE_NAME", TO_CHAR(MIN(POINT_DATE),'MM/DD/YYYY HH24:MI:SS') "EARLY_DATE", TO_CHAR(MAX(POINT_DATE),'MM/DD/YYYY HH24:MI:SS') "LATE_DATE", TO_CHAR(COUNT(*)) "ENTRY_COUNT" FROM X_LOAD_PROFILE_POINT UNION
SELECT 'X_STATION_PARAMETER_VALUE' "TABLE_NAME", TO_CHAR(MIN(PARAMETER_DATE),'MM/DD/YYYY HH24:MI:SS') "EARLY_DATE", TO_CHAR(MAX(PARAMETER_DATE),'MM/DD/YYYY HH24:MI:SS') "LATE_DATE", TO_CHAR(COUNT(*)) "ENTRY_COUNT" FROM X_STATION_PARAMETER_VALUE;