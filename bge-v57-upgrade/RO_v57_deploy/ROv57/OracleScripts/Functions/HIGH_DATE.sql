CREATE OR REPLACE FUNCTION HIGH_DATE RETURN DATE DETERMINISTIC IS
--Revision: $Revision: 1.19 $
BEGIN
	RETURN CONSTANTS.HIGH_DATE;
END HIGH_DATE;
/
