CREATE OR REPLACE FUNCTION MAX_DATA_LENGTH
	(
	p_TABLE_NAME IN VARCHAR,
	p_COLUMN_NAME IN VARCHAR
	)
	RETURN NUMBER IS
--Revision: $Revision: 1.12 $

-- Answer the max data length of the given column in the given table.
-- This is not fast, so only use it to set variables, not in a loop or SQL statement.

v_MAX_DATA_LENGTH NUMBER;

BEGIN

	SELECT DATA_LENGTH
	INTO v_MAX_DATA_LENGTH 
	FROM USER_TAB_COLUMNS 
	WHERE TABLE_NAME = p_TABLE_NAME
	  AND COLUMN_NAME = p_COLUMN_NAME;
	  
	RETURN v_MAX_DATA_LENGTH;

END MAX_DATA_LENGTH;
/
