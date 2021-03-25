CREATE OR REPLACE TRIGGER SYSTEM_OBJECT_ATTRIBUTE_UPDATE
	AFTER INSERT OR UPDATE OR DELETE
	ON SYSTEM_OBJECT_ATTRIBUTE
	FOR EACH ROW
BEGIN
	IF DELETING THEN
		UPDATE SYSTEM_OBJECT
		SET IS_MODIFIED = 1
		WHERE OBJECT_ID = :old.OBJECT_ID;
	ELSIF INSERTING
			OR :new.ATTRIBUTE_VAL <> :old.ATTRIBUTE_VAL
			OR :new.ATTRIBUTE_ID <> :old.ATTRIBUTE_ID THEN
		UPDATE SYSTEM_OBJECT
		SET IS_MODIFIED = 1
		WHERE OBJECT_ID = :new.OBJECT_ID;
	END IF;
	
-- If there is an error that the table is mutating, it would be because we are
-- trying to delete a System Object, which deletes its Attributes, and then this
-- trigger is trying to update the System Object that is being deleted.
-- We just want to ignore this error.
EXCEPTION
	WHEN ERRS.e_TABLE_IS_MUTATING THEN
		NULL;
	
END SYSTEM_OBJECT_ATTRIBUTE_UPDATE;
/
