CREATE OR REPLACE FUNCTION CDI_FROM_CUT_AS_STD(p_DATE DATE) RETURN VARCHAR2 AS
v_LOCAL_DATE DATE;
BEGIN
   v_LOCAL_DATE := NEW_TIME(p_DATE, GA.CUT_TIME_ZONE, UPPER(SUBSTR(GA.LOCAL_TIME_ZONE,1,1)) || 'ST');
   RETURN TO_CHAR(v_LOCAL_DATE-(1/(24*60*60)), 'MM/DD/YYYY') || ' ' || CASE WHEN TO_CHAR(v_LOCAL_DATE, 'HH24:MI') = '00:00' THEN '24:00' ELSE TO_CHAR(v_LOCAL_DATE, 'HH24:MI') END;
END CDI_FROM_CUT_AS_STD;
/
