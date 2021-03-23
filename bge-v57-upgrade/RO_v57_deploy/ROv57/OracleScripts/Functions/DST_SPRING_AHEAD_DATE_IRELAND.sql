CREATE OR REPLACE FUNCTION DST_SPRING_AHEAD_DATE(p_DATE DATE) RETURN DATE IS
--Revision: $Revision: 1.2 $
   /*
   * CAUTION : This modified API is valid only for Ireland  (RSA)
   *
   */

   --c   Answer the defined daylight savings time period begin day.
   --c   For daylight savings time the following applies:
   --c      the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM
   --c      the last Sunday in October (fall back) has two 2:00 AM hours
   --c --c Beginning in 2007, DST will begin on the second Sunday of March and end the first Sunday of November.

BEGIN

   -- RSA -- 03/13/2007 -- Modified for Irish Summer Time (IST) - observance of DST --
   -- RSA -- In Ireland, the LAST SUNDAY of March and October connote beginning and end of DST respectively.
   -- RSA -- In March, after 00:59:59, it is 02:00:00 and In October, after 01:59:59, it is 01:00:00

   RETURN NEXT_DAY(TRUNC(p_DATE, 'YEAR') + INTERVAL '0-2' YEAR TO
                            MONTH + INTERVAL '23 1:0:0' DAY TO SECOND,
                   DATE_CONST.k_SUNDAY);

   /*IF p_DATE >= TO_DATE('1/1/2007','MM/DD/YYYY') THEN
      RETURN (NEXT_DAY(TO_DATE('3/7/' || TO_CHAR(p_DATE,'YYYY') || ' 02','MM/DD/YYYY HH24'),GA.g_SUNDAY));
   ELSE
      RETURN (NEXT_DAY(TO_DATE('3/31/' || TO_CHAR(p_DATE,'YYYY') || ' 02','MM/DD/YYYY HH24'),GA.g_SUNDAY));
   END IF;*/
END DST_SPRING_AHEAD_DATE;
/
