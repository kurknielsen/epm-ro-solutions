CREATE OR REPLACE TRIGGER GEOGRAPHY_DELETE
	AFTER DELETE ON GEOGRAPHY
	FOR EACH ROW
BEGIN
	--UPDATE GEOGRAPHY SET PARENT_GEOGRAPHY_ID = 0 WHERE PARENT_GEOGRAPHY_ID = :old.GEOGRAPHY_ID;
	-- cannot do above update because it will cause table is mutating error - 
	-- instead, mark the geography ID in RTO_WORK and use another (non-row) trigger to clean up
	INSERT INTO RTO_WORK (WORK_ID, WORK_XID) VALUES (-9874, :old.GEOGRAPHY_ID);
END GEOGRAPHY_DELETE;
/
CREATE OR REPLACE TRIGGER GEOGRAPHY_DELETE2
	AFTER DELETE ON GEOGRAPHY
DECLARE
v_WORK_IDs ID_TABLE := ID_TABLE();
BEGIN
	DELETE RTO_WORK
	WHERE WORK_ID = -9874
	RETURNING ID_TYPE(WORK_XID)
	BULK COLLECT INTO v_WORK_IDs;

	IF v_WORK_IDs.COUNT > 0 THEN
		UPDATE GEOGRAPHY
		SET PARENT_GEOGRAPHY_ID = 0
		WHERE PARENT_GEOGRAPHY_ID IN
			(SELECT X.ID FROM TABLE(CAST(v_WORK_IDs AS ID_TABLE)) X);
	END IF;
END GEOGRAPHY_DELETE2;
/
