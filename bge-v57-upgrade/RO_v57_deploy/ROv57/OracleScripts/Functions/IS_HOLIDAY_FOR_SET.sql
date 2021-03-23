CREATE OR REPLACE FUNCTION IS_HOLIDAY_FOR_SET
	(
	p_DATE IN DATE,
	p_HOLIDAY_SET_ID IN NUMBER := 0
	) RETURN NUMBER IS
--Revision: $Revision: 1.2 $

-- Answer true if the specified date is a holiday; otherwise answer false.

v_COUNT NUMBER;

BEGIN

	--Holidays are ignored for faster processing by setting this GA swithch.
	IF NOT GA.ENABLE_HOLIDAYS THEN
		RETURN 0;
	END IF;

	IF NOT p_HOLIDAY_SET_ID = 0 THEN
		SELECT COUNT(1)
		INTO v_COUNT
		FROM HOLIDAY_SCHEDULE B, HOLIDAY_OBSERVANCE C
		WHERE B.HOLIDAY_SET_ID = p_HOLIDAY_SET_ID
			AND C.HOLIDAY_ID = B.HOLIDAY_ID
			AND C.HOLIDAY_DATE = p_DATE;
	ELSE
		SELECT COUNT(1)
		INTO v_COUNT
		FROM HOLIDAY_OBSERVANCE
		WHERE HOLIDAY_DATE = p_DATE;
	END IF;

	RETURN CASE WHEN v_COUNT > 0 THEN 1 ELSE 0 END;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;

END IS_HOLIDAY_FOR_SET;
/
