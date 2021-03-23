CREATE OR REPLACE TRIGGER SRVCE_LOC_AGGRGTN_SYNC_ROW
	BEFORE UPDATE OR INSERT ON SERVICE_LOCATION  
	FOR EACH ROW
BEGIN
	IF ACCOUNTS_METERS.g_SRVCE_LOC_USE_TRIGGER THEN
		IF NVL(:NEW.FEEDER_SEGMENT_ID, CONSTANTS.NULL_ID) != NVL(:OLD.FEEDER_SEGMENT_ID, CONSTANTS.NULL_ID)
				OR NVL(:NEW.FEEDER_ID, CONSTANTS.NULL_ID) != NVL(:OLD.FEEDER_ID, CONSTANTS.NULL_ID) 
				OR NVL(:NEW.SUB_STATION_ID, CONSTANTS.NULL_ID) != NVL(:OLD.SUB_STATION_ID, CONSTANTS.NULL_ID) 
				OR NVL(:NEW.SERVICE_POINT_ID, CONSTANTS.NULL_ID) != NVL(:OLD.SERVICE_POINT_ID, CONSTANTS.NULL_ID) 
				OR NVL(:NEW.SERVICE_ZONE_ID, CONSTANTS.NULL_ID) != NVL(:OLD.SERVICE_ZONE_ID, CONSTANTS.NULL_ID) THEN
			INSERT INTO RTO_WORK(WORK_ID, WORK_XID) 
			VALUES(CONSTANTS.SRVCE_LOC_AGGRGTN_SYNC_WORK_ID, :NEW.SERVICE_LOCATION_ID);
		END IF;
	END IF;

END SRVCE_LOC_AGGRGTN_SYNC_ROW;
/
