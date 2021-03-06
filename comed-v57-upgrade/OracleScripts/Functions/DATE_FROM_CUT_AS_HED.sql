CREATE OR REPLACE FUNCTION DATE_FROM_CUT_AS_HED
	(
	p_DATE DATE,
	p_TIME_ZONE CHAR,
    p_DATA_INTERVAL VARCHAR,
	p_FORMAT VARCHAR := NULL,
	p_MODEL_ID NUMBER := GA.ELECTRIC_MODEL,
	p_DAY_TYPE NUMBER := GA.STANDARD
	)
	RETURN VARCHAR IS
--Revision: $Revision: 1.2 $
BEGIN
   
if p_DATA_INTERVAL = '?' then
    RETURN SUBSTR(TRIM(from_cut_as_hed(p_date, p_time_zone, p_format, p_MODEL_ID, p_day_type, p_data_interval)), 0, 10);
else
    RETURN TO_CHAR(TRUNC(FROM_CUT(p_DATE-1/86400,p_TIME_ZONE),p_DATA_INTERVAL),'YYYY-MM-DD      ');
end if;

END DATE_FROM_CUT_AS_HED;
/
