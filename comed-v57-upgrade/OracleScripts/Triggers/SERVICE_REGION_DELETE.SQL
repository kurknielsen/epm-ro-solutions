CREATE OR REPLACE TRIGGER SERVICE_REGION_DELETE
	AFTER DELETE ON SERVICE_REGION
	FOR EACH ROW
BEGIN
	UPDATE SERVICE_POINT SET SERVICE_REGION_ID = 0 WHERE SERVICE_REGION_ID = :old.SERVICE_REGION_ID;
END SERVICE_REGION_DELETE;
/

