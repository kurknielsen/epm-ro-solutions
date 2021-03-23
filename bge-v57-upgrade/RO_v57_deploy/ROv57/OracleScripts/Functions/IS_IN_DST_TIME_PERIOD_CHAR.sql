CREATE OR REPLACE FUNCTION IS_IN_DST_TIME_PERIOD_CHAR
  (
  p_DATE DATE
  )
  RETURN varchar2 IS


--c  Answer 'TRUE' if a date falls within the DEFINED daylight savings time period.
--c  For daylight savings time the following applies:
--c    the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM
--c    the last Sunday in October (fall back) has two 2:00 AM hours
v_RESULT VARCHAR2 (5);
BEGIN

  IF (p_DATE BETWEEN DST_SPRING_AHEAD_DATE(p_DATE) AND DST_FALL_BACK_DATE(p_DATE))
    THEN v_RESULT := 'TRUE';
  ELSE
    v_RESULT := 'FALSE';
  END IF;
  RETURN v_RESULT;

END IS_IN_DST_TIME_PERIOD_CHAR;
/

