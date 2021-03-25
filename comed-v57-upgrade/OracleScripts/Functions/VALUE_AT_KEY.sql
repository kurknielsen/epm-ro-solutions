CREATE OR REPLACE FUNCTION VALUE_AT_KEY
	(
	p_KEY IN VARCHAR
	) RETURN VARCHAR IS
--Revision: $Revision: 1.21 $

-- DEPRECATED 9/27/2004 Use GET_DICTIONARY_VALUE for current function.
--	Answer the value associated with the key.

BEGIN
	RETURN GET_DICTIONARY_VALUE(p_KEY,0,'?','?','?','?',1);
END VALUE_AT_KEY;
/
