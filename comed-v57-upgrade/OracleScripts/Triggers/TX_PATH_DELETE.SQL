CREATE OR REPLACE TRIGGER TX_PATH_DELETE
	AFTER DELETE ON TX_PATH
	FOR EACH ROW
BEGIN
	DELETE FROM TX_PATH_SEGMENT WHERE PATH_ID = :old.PATH_ID;
	UPDATE INTERCHANGE_TRANSACTION SET PATH_ID = 0 WHERE PATH_ID = :old.PATH_ID;
END TX_PATH_DELETE;
/

