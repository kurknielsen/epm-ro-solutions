CREATE OR REPLACE FUNCTION HOLIDAY_DAY_TYPE
	(
	p_FORECAST_DATE IN DATE,
	p_HISTORICAL_YEAR IN VARCHAR,
	p_EDC_ID IN NUMBER DEFAULT 0
	) RETURN DATE IS
	
-- Revision: $Revision: 1.18 $

-- Answer a date that represents a historical holiday if the forecast day is a holiday.
-- Otherwise answer null.

v_HISTORICAL_HOLIDAY_DATE DATE := NULL;

BEGIN

	IF NOT p_EDC_ID = 0 THEN
		SELECT A.HOLIDAY_DATE
		INTO v_HISTORICAL_HOLIDAY_DATE
		FROM HOLIDAY_OBSERVANCE A
		WHERE A.HOLIDAY_ID =
			(SELECT C.HOLIDAY_ID
			FROM ENERGY_DISTRIBUTION_COMPANY A, HOLIDAY_SCHEDULE B, HOLIDAY_OBSERVANCE C
			WHERE A.EDC_ID = p_EDC_ID
				AND B.HOLIDAY_SET_ID = A.EDC_HOLIDAY_SET_ID
				AND C.HOLIDAY_ID = B.HOLIDAY_ID
				AND C.HOLIDAY_DATE = p_FORECAST_DATE)
			AND A.HOLIDAY_YEAR = TO_NUMBER(p_HISTORICAL_YEAR);
	ELSE	
		SELECT A.HOLIDAY_DATE
		INTO v_HISTORICAL_HOLIDAY_DATE
		FROM HOLIDAY_OBSERVANCE A
		WHERE A.HOLIDAY_ID =
	    	(SELECT HOLIDAY_ID
			FROM HOLIDAY_OBSERVANCE
			WHERE HOLIDAY_DATE = p_FORECAST_DATE
			    AND ROWNUM = 1)
			AND A.HOLIDAY_YEAR = TO_NUMBER(p_HISTORICAL_YEAR);
	END IF;

	RETURN v_HISTORICAL_HOLIDAY_DATE;

EXCEPTION
	WHEN OTHERS THEN
		RETURN NULL;
END HOLIDAY_DAY_TYPE;
/

