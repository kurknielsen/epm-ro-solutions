CREATE OR REPLACE FUNCTION DATE_DAY_NAME
	(
	p_DATE IN DATE,
	p_EDC_ID IN NUMBER DEFAULT 0
	) RETURN CHAR DETERMINISTIC IS
--Revision: $Revision: 1.19 $

-- Answer the day name for the specified date.

BEGIN

    IF IS_HOLIDAY(p_DATE, p_EDC_ID) THEN
        RETURN 'Hol';
	ELSE
        RETURN TO_CHAR(p_DATE,'Dy');
	END IF;

END DATE_DAY_NAME;
/

