CREATE OR REPLACE FUNCTION ADVANCE_DATE
	(
	p_DATE DATE,
	p_INTERVAL VARCHAR
	)
	RETURN DATE IS
--Revision: $Revision: 1.25 $

-- Answer a new date that is a specified interval later in time

BEGIN
	RETURN DATE_UTIL.ADVANCE_DATE(p_DATE, p_INTERVAL);
END ADVANCE_DATE;
/
