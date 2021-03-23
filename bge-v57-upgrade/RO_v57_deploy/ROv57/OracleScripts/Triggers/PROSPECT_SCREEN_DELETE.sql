CREATE OR REPLACE TRIGGER PROSPECT_SCREEN_DELETE
	AFTER DELETE ON PROSPECT_SCREEN
	FOR EACH ROW
BEGIN
	DELETE PROSPECT
	WHERE SCREEN_ID = :old.SCREEN_ID;
	DELETE PROSPECT_SCREEN_EVALUATION
	WHERE SCREEN_ID = :old.SCREEN_ID;
END PROSPECT_SCREEN_DELETE;
/
