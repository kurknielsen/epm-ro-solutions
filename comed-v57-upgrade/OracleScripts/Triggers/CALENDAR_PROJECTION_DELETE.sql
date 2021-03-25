CREATE OR REPLACE TRIGGER CALENDAR_PROJECTION_DELETE
	AFTER DELETE ON CALENDAR_PROJECTION
	FOR EACH ROW
BEGIN
	DELETE PROJECTION_PATTERN WHERE PROJECTION_ID = :old.PROJECTION_ID;
END CALENDAR_PROJECTION_DELETE;
/