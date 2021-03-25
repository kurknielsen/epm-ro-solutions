CREATE OR REPLACE FUNCTION CAN_DELETE
	(
	p_DOMAIN_NAME IN VARCHAR
	) RETURN BOOLEAN IS
--Revision: $Revision: 1.18 $
--	Answer TRUE if the user can write to/from the specified domain; otherwise answer FALSE.
-- Access Codes: S - Select, U - update, D - delete
v_ACTION_NAME SYSTEM_ACTION.ACTION_NAME%TYPE;
BEGIN
	v_ACTION_NAME := 'Delete ' || UPPER(p_DOMAIN_NAME);
	RETURN SD.GET_ACTION_IS_ALLOWED(v_ACTION_NAME);
END CAN_DELETE;
/
