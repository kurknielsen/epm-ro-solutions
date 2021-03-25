CREATE OR REPLACE FUNCTION DST_SPRING_AHEAD_DATE(p_DATE DATE) RETURN DATE IS
   /*
   * CAUTION : This modified API is valid only for Central European Time (CET)
   *   In Germancy and Sweden, last Sunday in March after 01:59:59 it is 03:00:00 and 
   *   in October. after 02:59:59 it is 02:00:00
   */

BEGIN
        RETURN NEXT_DAY(TRUNC(p_DATE, 'YEAR') + INTERVAL '0-2' YEAR TO
                    MONTH + INTERVAL '23 2:0:0' DAY TO SECOND,
           GA.g_SUNDAY);
                   
END DST_SPRING_AHEAD_DATE;
/
