CREATE OR REPLACE FUNCTION DST_SPRING_AHEAD_DATE
	(
	p_DATE DATE
	)
	RETURN DATE IS
--Revision: $Revision: 1.18 $

--c	Answer the defined daylight savings time period begin day.
--c	For daylight savings time the following applies:
--c		the first Sunday in April (spring ahead) does not have a 2:00 AM hour, it becomes 3:00 AM
--c		the last Sunday in October (fall back) has two 2:00 AM hours
--c --c Beginning in 2007, DST will begin on the second Sunday of March and end the first Sunday of November. 

BEGIN

	IF p_DATE >= TO_DATE('1/1/2007','MM/DD/YYYY') THEN
		RETURN (NEXT_DAY(TO_DATE('3/7/' || TO_CHAR(p_DATE,'YYYY') || ' 02','MM/DD/YYYY HH24'),GA.g_SUNDAY));
	ELSE
		RETURN (NEXT_DAY(TO_DATE('3/31/' || TO_CHAR(p_DATE,'YYYY') || ' 02','MM/DD/YYYY HH24'),GA.g_SUNDAY));
	END IF;
END DST_SPRING_AHEAD_DATE;
/

