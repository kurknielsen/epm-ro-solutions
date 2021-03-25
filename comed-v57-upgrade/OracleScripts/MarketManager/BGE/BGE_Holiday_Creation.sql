--Holiday Population Script for BGE.
DECLARE
	--Set these constants to change the range of the population.
	--Easter Lookup currently holds only from 1999 to 2020.  Add more Easter lookup dates if necessary.
	c_BEGIN_YEAR CONSTANT NUMBER(4) := 1999;
	c_END_YEAR CONSTANT NUMBER(4) := 2006;

	--Create a lookup for Easter dates
	TYPE DATE_LOOKUP IS TABLE OF DATE INDEX BY BINARY_INTEGER;
	v_EASTER_LOOKUP DATE_LOOKUP;
	
	--The following holidays are not recognized by the HOLIDAY_OBSERVANCE_DAY function.
	c_HOL_PRESIDENTS_DAY CONSTANT VARCHAR2(16) := 'PresidentsDay';
	c_HOL_GOOD_FRIDAY CONSTANT VARCHAR2(16) := 'GoodFriday';
	
	v_HOLIDAY_SET_ID NUMBER(9);
	
	PROCEDURE GET_HOLIDAY_SET
		(
		p_HOLIDAY_SET_NAME IN VARCHAR2,
		p_EDC_NAME IN VARCHAR2
		) AS
		--Get the Holiday Set ID, and create it if it does not exist.
		--Also, associate the Holiday Set with the EDC.
		v_EDC_ID NUMBER(9);
	BEGIN 
		BEGIN
			SELECT HOLIDAY_SET_ID
			INTO v_HOLIDAY_SET_ID
			FROM HOLIDAY_SET
			WHERE HOLIDAY_SET_NAME = p_HOLIDAY_SET_NAME;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				IO.PUT_HOLIDAY_SET(v_HOLIDAY_SET_ID, p_HOLIDAY_SET_NAME, NULL, NULL, 0);
		END;
		
		ID.ID_FOR_EDC(p_EDC_NAME, TRUE, v_EDC_ID);
		UPDATE ENERGY_DISTRIBUTION_COMPANY
		SET EDC_HOLIDAY_SET_ID = v_HOLIDAY_SET_ID
		WHERE EDC_ID = v_EDC_ID
			AND NOT EDC_HOLIDAY_SET_ID = v_HOLIDAY_SET_ID;
	
	END GET_HOLIDAY_SET;
	
	PROCEDURE POPULATE_EASTER_LOOKUP AS
	BEGIN
		v_EASTER_LOOKUP(1999) := '4-APR-1999';
		v_EASTER_LOOKUP(2000) := '23-APR-2000';
		v_EASTER_LOOKUP(2001) := '15-APR-2001';
		v_EASTER_LOOKUP(2002) := '31-MAR-2002';
		v_EASTER_LOOKUP(2003) := '20-APR-2003';
		v_EASTER_LOOKUP(2004) := '11-APR-2004';
		v_EASTER_LOOKUP(2005) := '27-MAR-2005';
		v_EASTER_LOOKUP(2006) := '16-APR-2006';
		v_EASTER_LOOKUP(2007) := '8-APR-2007';
		v_EASTER_LOOKUP(2008) := '23-MAR-2008';
		v_EASTER_LOOKUP(2009) := '12-APR-2009';
		v_EASTER_LOOKUP(2010) := '4-APR-2010';
		v_EASTER_LOOKUP(2011) := '24-APR-2011';
		v_EASTER_LOOKUP(2012) := '8-APR-2012';
		v_EASTER_LOOKUP(2013) := '31-MAR-2013';
		v_EASTER_LOOKUP(2014) := '20-APR-2014';
		v_EASTER_LOOKUP(2015) := '5-APR-2015';
		v_EASTER_LOOKUP(2016) := '27-MAR-2016';
		v_EASTER_LOOKUP(2017) := '16-APR-2017';
		v_EASTER_LOOKUP(2018) := '1-APR-2018';
		v_EASTER_LOOKUP(2019) := '21-APR-2019';
		v_EASTER_LOOKUP(2020) := '12-APR-2020';
	END POPULATE_EASTER_LOOKUP;
	
	PROCEDURE ADD_HOLIDAY_OBSERVANCES
		(
		p_HOLIDAY_NAME IN VARCHAR2, 
		p_HOLIDAY_IDENTIFIER IN VARCHAR2
		) AS
		v_HOLIDAY_ID NUMBER(9);
		v_HOLIDAY_DATE DATE;
		v_YEAR NUMBER;
	BEGIN
		--Create the holiday and add it to the Holiday Set
		ID.ID_FOR_HOLIDAY(p_HOLIDAY_NAME, v_HOLIDAY_ID);
		
		BEGIN
			INSERT INTO HOLIDAY_SCHEDULE(HOLIDAY_SET_ID, HOLIDAY_ID, ENTRY_DATE)
			VALUES(v_HOLIDAY_SET_ID, v_HOLIDAY_ID, SYSDATE);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
		
		--Add the observances.
		FOR v_YEAR IN c_BEGIN_YEAR .. c_END_YEAR LOOP
			IF p_HOLIDAY_IDENTIFIER = c_HOL_PRESIDENTS_DAY THEN
				--Third Monday in February
				v_HOLIDAY_DATE := NEXT_DAY(TO_DATE('14-FEB-' || v_YEAR,'DD-MON-YYYY'),'MONDAY');
			ELSIF p_HOLIDAY_IDENTIFIER = c_HOL_GOOD_FRIDAY THEN
				v_HOLIDAY_DATE := v_EASTER_LOOKUP(v_YEAR) - 2;
			ELSE
				v_HOLIDAY_DATE := HOLIDAY_OBSERVANCE_DAY(p_HOLIDAY_IDENTIFIER, v_YEAR);
			END IF;
			DBMS_OUTPUT.PUT_LINE('PUTTING HOLIDAY=' || p_HOLIDAY_NAME || ' YEAR=' || v_YEAR || ' DATE=' || TO_CHAR(v_HOLIDAY_DATE));
			SP.PUT_HOLIDAY_OBSERVANCE(v_HOLIDAY_ID, v_YEAR, v_HOLIDAY_DATE);
		END LOOP;
		
	END ADD_HOLIDAY_OBSERVANCES;

BEGIN
--Get the BGE Holiday Set.  Create if it does not exist.  Associate with specified EDC.  Create EDC if it does not exist.
	GET_HOLIDAY_SET('BGE Holiday Set', 'BGE');

--Holiday Creation : New Year's Day, President's Day, Good Friday, Memorial Day, 
--Independence Day, Labor Day, Thanksgiving, Christmas, and the Monday following such of these as fall on Sunday.
--Set the c_BEGIN_YEAR and c_END_YEAR constants at the top of the script to control the range of years.
	
--Easter Lookup currently holds only from 1999 to 2020.  Add more dates if necessary.
	POPULATE_EASTER_LOOKUP;

--Create the holidays and their dates within the date range.
--Associate them with the BGE Holidays Holiday Set.
	ADD_HOLIDAY_OBSERVANCES('New Years Day', 'US New Years Day'); 
	ADD_HOLIDAY_OBSERVANCES('Presidents Day', c_HOL_PRESIDENTS_DAY);
	ADD_HOLIDAY_OBSERVANCES('Good Friday', c_HOL_GOOD_FRIDAY);
	ADD_HOLIDAY_OBSERVANCES('Memorial Day', 'US Memorial');
	ADD_HOLIDAY_OBSERVANCES('Independence Day','US Independence Day'); 
	ADD_HOLIDAY_OBSERVANCES('Labor Day', 'US Labor');
	ADD_HOLIDAY_OBSERVANCES('Thanksgiving', 'US Thanksgiving');
	ADD_HOLIDAY_OBSERVANCES('Christmas', 'US Christmas');

	COMMIT;
END;

-- Future Enhancement: Algorithm for calculating Easter Sunday:
-- Gauss's algorithm
-- 
-- This algorithm for calculating the date of Easter Sunday was first presented by the mathematician Carl Friedrich Gauss.
-- 
-- The number of the year is denoted by Y; mod denotes the remainder of integer division (e.g. 13 mod 5 = 3; see modular arithmetic). Calculate first a, b and c:
-- 
--     a = Y mod 19
--     b = Y mod 4
--     c = Y mod 7
-- 
-- Then calculate
-- 
--     d = (19a + M) mod 30
--     e = (2b + 4c + 6d + N) mod 7
-- 
-- For the Julian calendar (used in eastern churches) M = 15 and N = 6, and for the Gregorian calendar (used in western churches) M and N are from the following table:
-- 
--   Years     M   N
-- 1583-1699  22   2
-- 1700-1799  23   3
-- 1800-1899  23   4
-- 1900-2099  24   5
-- 2100-2199  24   6
-- 2200-2299  25   0
-- 
-- If d + e < 10 then Easter is on the (d + e + 22)th of March, and is otherwise on the (d + e - 9)th of April.
-- 
-- The following exceptions must be taken into account:
-- 
--     * If the date given by the formula is the 26th of April, Easter is on the 19th of April.
--     * If the date given by the formula is the 25th of April, with d = 28, e = 6, and a > 10, Easter is on the 18th of April.
