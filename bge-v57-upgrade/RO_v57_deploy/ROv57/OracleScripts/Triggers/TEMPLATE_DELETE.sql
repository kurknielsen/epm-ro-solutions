CREATE OR REPLACE TRIGGER TEMPLATE_DELETE
	AFTER DELETE ON TEMPLATE
	FOR EACH ROW

DECLARE
BEGIN
	IF :old.TEMPLATE_ID < 100 THEN
		ERRS.RAISE(MSGCODES.c_ERR_PRIVILEGES, :old.TEMPLATE_NAME || ' is a system Template which cannot be deleted.');
	END IF;
	UPDATE COMPONENT SET TEMPLATE_ID = 0 WHERE TEMPLATE_ID = :old.TEMPLATE_ID;
	UPDATE LOAD_PROFILE SET PROFILE_TEMPLATE_ID = 0 WHERE PROFILE_TEMPLATE_ID = :old.TEMPLATE_ID;
END TEMPLATE_DELETE;
/
