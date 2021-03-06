CREATE OR REPLACE FUNCTION TIME_FROM_CUT_AS_HED
	(
	p_DATE DATE,
	p_TIME_ZONE CHAR,
    p_DATA_INTERVAL VARCHAR,
	p_FORMAT VARCHAR := NULL,
	p_MODEL_ID NUMBER := GA.ELECTRIC_MODEL,
	p_DAY_TYPE NUMBER := GA.STANDARD
	)
	RETURN VARCHAR IS
--Revision: $Revision: 1.3 $

BEGIN

if p_DATA_INTERVAL = '?' then
    RETURN SUBSTR(TRIM(FROM_CUT_AS_HED(p_date, p_time_zone, p_format, p_MODEL_ID, p_day_type, p_data_interval)), 11);
else
    RETURN NULL;
end if;

END TIME_FROM_CUT_AS_HED;
/
