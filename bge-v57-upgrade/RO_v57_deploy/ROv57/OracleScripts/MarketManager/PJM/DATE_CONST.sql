CREATE OR REPLACE PACKAGE DATE_CONST AS
-- $Revision: 1.3 $
/* Author   : Rex S. Arul (Entire Code Generated by Perl)
   Dated    : Wed Mar  7 18:51:13 2007
   Script   : GenerateDateConstPackage.pl
   Purpose  : To use constant literals without hard-coding so that
              APIs will work anywhere in the world, free from NLS fears.

   Example  : Instead of using NEXT_DAY function like:
                 NEXT_DAY(SYSDATE, 'SUNDAY');
              You must use:
                 NEXT_DAY(SYSDATE, DATE_CONST.g_SUNDAY);
*/
k_SUN CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-01', 'Dy');
k_SUNDAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-01', 'Day');
k_MON CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-02', 'Dy');
k_MONDAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-02', 'Day');
k_TUE CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-03', 'Dy');
k_TUESDAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-03', 'Day');
k_WED CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-04', 'Dy');
k_WEDNESDAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-04', 'Day');
k_THU CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-05', 'Dy');
k_THURSDAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-05', 'Day');
k_FRI CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-06', 'Dy');
k_FRIDAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-06', 'Day');
k_SAT CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-07', 'Dy');
k_SATURDAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-07', 'Day');

 -------------------------------------------------------------------

k_JAN CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-01-01', 'Mon');
k_JANUARY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-01-01', 'Month');
k_FEB CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-02-01', 'Mon');
k_FEBRUARY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-02-01', 'Month');
k_MAR CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-03-01', 'Mon');
k_MARCH CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-03-01', 'Month');
k_APR CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-04-01', 'Mon');
k_APRIL CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-04-01', 'Month');
k_MAY CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-05-01', 'Mon');
k_MAY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-05-01', 'Month');
k_JUN CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-06-01', 'Mon');
k_JUNE CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-06-01', 'Month');
k_JUL CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-07-01', 'Mon');
k_JULY CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-07-01', 'Month');
k_AUG CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-08-01', 'Mon');
k_AUGUST CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-08-01', 'Month');
k_SEP CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-09-01', 'Mon');
k_SEPTEMBER CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-09-01', 'Month');
k_OCT CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-10-01', 'Mon');
k_OCTOBER CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-10-01', 'Month');
k_NOV CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-11-01', 'Mon');
k_NOVEMBER CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-11-01', 'Month');
k_DEC CONSTANT VARCHAR2(3 CHAR) := TO_CHAR(DATE '2006-12-01', 'Mon');
k_DECEMBER CONSTANT VARCHAR2(32 CHAR) := TO_CHAR(DATE '2006-12-01', 'Month');


FUNCTION WHAT_VERSION RETURN VARCHAR2;

END DATE_CONST;
/
CREATE OR REPLACE PACKAGE BODY DATE_CONST AS

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;

END DATE_CONST;
/