CREATE OR REPLACE TRIGGER QUOTE_CALENDAR_PRODUCT_DELETE
	AFTER DELETE ON QUOTE_CALENDAR_PRODUCT
	FOR EACH ROW
BEGIN
	DELETE QUOTE_COMPONENT_POSITION
	WHERE QUOTE_ID = :old.QUOTE_ID
	  AND QUOTE_SCENARIO = :old.QUOTE_SCENARIO;
	DELETE QUOTE_COMPONENT
	WHERE QUOTE_ID = :old.QUOTE_ID
	  AND QUOTE_SCENARIO = :old.QUOTE_SCENARIO;
END QUOTE_CALENDAR_PRODUCT_DELETE;
/

