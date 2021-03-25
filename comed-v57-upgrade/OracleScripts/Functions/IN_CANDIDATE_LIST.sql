CREATE OR REPLACE FUNCTION IN_CANDIDATE_LIST
	(
	p_ID IN NUMBER,
	p_LIST IN VARCHAR,
	p_DELIMITER IN CHAR DEFAULT ','
	) RETURN NUMBER IS

--Revision: $Revision: 1.17 $

-- Determine if an ID number is contained in a candiadte list.
-- If the ID is contained in the list, answer the id; otherwise answer NULL.

BEGIN

	IF INSTR(p_DELIMITER || p_LIST  || p_DELIMITER, p_DELIMITER || TO_CHAR(p_ID) || p_DELIMITER) > 0 THEN
	    RETURN p_ID;
	ELSE
	    RETURN NULL;
	END IF;

END IN_CANDIDATE_LIST;
/

