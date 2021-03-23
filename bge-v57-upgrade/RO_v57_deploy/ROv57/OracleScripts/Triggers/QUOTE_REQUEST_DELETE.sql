CREATE OR REPLACE TRIGGER QUOTE_REQUEST_DELETE
	AFTER DELETE ON QUOTE_REQUEST
	FOR EACH ROW
BEGIN
	DELETE QUOTE_CALENDAR_PRODUCT
	WHERE QUOTE_ID = :old.QUOTE_ID;
END QUOTE_CALENDAR_PRODUCT_DELETE;
/
