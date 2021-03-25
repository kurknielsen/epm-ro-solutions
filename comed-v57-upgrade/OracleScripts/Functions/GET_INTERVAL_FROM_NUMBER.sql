CREATE OR REPLACE FUNCTION GET_INTERVAL_FROM_NUMBER
	(
	p_INTERVAL_NUMBER IN NUMBER
	)
	RETURN VARCHAR2 IS
--Revision: $Revision: 1.2 $

--c	Return a number representing the interval.  A lower number represents a smaller interval.
--c This function can be used to compare intervals.
v_INTERVAL_ABBR VARCHAR2(4);
BEGIN

	IF P_INTERVAL_NUMBER = 5 THEN
		v_INTERVAL_ABBR := 'MI5';
	ELSIF P_INTERVAL_NUMBER = 10  THEN
		v_INTERVAL_ABBR := 'MI10';
	ELSIF P_INTERVAL_NUMBER = 15  THEN
		v_INTERVAL_ABBR := 'MI15';
	ELSIF P_INTERVAL_NUMBER = 20  THEN
		v_INTERVAL_ABBR := 'MI20';
	ELSIF P_INTERVAL_NUMBER = 25  THEN
		v_INTERVAL_ABBR := 'MI30';
	ELSIF P_INTERVAL_NUMBER = 30 THEN
		v_INTERVAL_ABBR := 'HH';
	ELSIF P_INTERVAL_NUMBER = 35 THEN
		v_INTERVAL_ABBR := 'DD';
	ELSIF P_INTERVAL_NUMBER = 40 THEN
		v_INTERVAL_ABBR := 'DY';
	ELSIF P_INTERVAL_NUMBER = 45 THEN
		v_INTERVAL_ABBR := 'MM';
	ELSIF P_INTERVAL_NUMBER = 50 THEN
		v_INTERVAL_ABBR := 'Q';
	ELSIF P_INTERVAL_NUMBER = 55 THEN
		v_INTERVAL_ABBR := 'YY';
	ELSE
		v_INTERVAL_ABBR := 'HH';
	END IF;

	RETURN v_INTERVAL_ABBR;


END GET_INTERVAL_FROM_NUMBER;
/
