CREATE OR REPLACE TRIGGER PROSPECT_DELETE
	AFTER DELETE ON PROSPECT
	FOR EACH ROW
BEGIN
	DELETE PROSPECT_CONSUMPTION
	WHERE PROSPECT_ID = :old.PROSPECT_ID;
	DELETE PROSPECT_EVALUATION
	WHERE PROSPECT_ID = :old.PROSPECT_ID;
END PROSPECT_DELETE;
/

