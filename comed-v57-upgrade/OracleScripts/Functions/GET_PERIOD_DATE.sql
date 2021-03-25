CREATE OR REPLACE FUNCTION GET_PERIOD_DATE
	(
	p_DATE IN DATE
	) RETURN DATE IS
--Revision: $Revision: 1.2 $
v_DATE DATE := p_DATE;
----------------------------------------------------------------------------------------------------
    FUNCTION IS_LEAP_YEAR
    	(
    	p_DATE IN DATE
    	) RETURN BOOLEAN IS
    v_DATE DATE;
    BEGIN
    	v_DATE := TO_DATE('02/28/'||TO_CHAR(p_DATE,'YYYY'),'MM/DD/YYYY');
    	v_DATE := v_DATE+1;
    	-- if adding a day to Feb 28 still results in a day in february,
    	-- then this is a leap year
    	RETURN TO_NUMBER(TO_CHAR(v_DATE,'MM')) = 2;
    END IS_LEAP_YEAR;
----------------------------------------------------------------------------------------------------
BEGIN
	IF IS_LEAP_YEAR(v_DATE) THEN
		v_DATE := ADD_MONTHS(v_DATE,12);
	END IF;
	
	RETURN LOW_DATE + (v_DATE - TRUNC(v_DATE,'YY'));
END GET_PERIOD_DATE;
/
