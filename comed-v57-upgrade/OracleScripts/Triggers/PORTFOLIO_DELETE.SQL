CREATE OR REPLACE TRIGGER PORTFOLIO_DELETE
	AFTER DELETE ON PORTFOLIO
	FOR EACH ROW
BEGIN
	DELETE PORTFOLIO_SERVICE_POINT WHERE PORTFOLIO_ID = :old.PORTFOLIO_ID;
END PORTFOLIO_DELETE;
/
