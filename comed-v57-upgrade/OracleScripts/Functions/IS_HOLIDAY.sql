CREATE OR REPLACE FUNCTION IS_HOLIDAY
(
	p_DATE IN DATE,
	p_EDC_ID IN NUMBER DEFAULT 0
	) RETURN BOOLEAN DETERMINISTIC IS
	
--Revision: $Revision: 1.21 $

-- Answer true if the specified date is a holiday; otherwise answer false.

v_COUNT NUMBER;

BEGIN

	--Holidays are ignored for faster processing by setting this GA swithch.
	IF NOT GA.ENABLE_HOLIDAYS THEN 
		RETURN FALSE; 
	END IF;

	IF NOT p_EDC_ID = 0 THEN
		SELECT COUNT(1)
		INTO v_COUNT
		FROM ENERGY_DISTRIBUTION_COMPANY A, HOLIDAY_SCHEDULE B, HOLIDAY_OBSERVANCE C
		WHERE A.EDC_ID = p_EDC_ID
			AND B.HOLIDAY_SET_ID = A.EDC_HOLIDAY_SET_ID
			AND C.HOLIDAY_ID = B.HOLIDAY_ID
			AND C.HOLIDAY_DATE = p_DATE;
	ELSE
		SELECT COUNT(1)
		INTO v_COUNT
		FROM HOLIDAY_OBSERVANCE
		WHERE HOLIDAY_DATE = p_DATE;
	END IF;
	
	RETURN v_COUNT > 0;
	
EXCEPTION
	WHEN OTHERS THEN
		RETURN FALSE;
		
END IS_HOLIDAY;
/

