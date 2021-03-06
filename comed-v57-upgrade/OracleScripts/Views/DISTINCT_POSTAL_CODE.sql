CREATE OR REPLACE VIEW DISTINCT_POSTAL_CODE ( POSTAL_CODE
 ) AS 
SELECT DISTINCT NVL(DISPLAY_NAME,GEOGRAPHY_NAME)
FROM GEOGRAPHY
WHERE UPPER(GEOGRAPHY_TYPE) = 'POSTAL CODE';
