CREATE OR REPLACE PROCEDURE PUT_VALUE_AT_KEY
	(
	p_KEY IN VARCHAR,
	p_VALUE IN VARCHAR
	) AS
--Revision: $Revision: 1.23 $

-- DEPRECATED 9/27/2004 Use PUT_DICTIONARY_KEY for current procedure.

BEGIN
	PUT_DICTIONARY_VALUE(p_KEY,p_VALUE);
END PUT_VALUE_AT_KEY;
/
