CREATE OR REPLACE TRIGGER TX_FEEDER_SL_SYNC
	AFTER UPDATE ON TX_FEEDER
	FOR EACH ROW
DECLARE
	v_SERVICE_ZONE_ID NUMBER(9);
BEGIN
	IF NVL(:NEW.SUB_STATION_ID, CONSTANTS.NULL_ID) != NVL(:OLD.SUB_STATION_ID, CONSTANTS.NULL_ID) THEN

		SELECT TSS.SERVICE_ZONE_ID
			INTO v_SERVICE_ZONE_ID
		FROM TX_SUB_STATION TSS
		WHERE TSS.SUB_STATION_ID = :NEW.SUB_STATION_ID;

		ACCOUNTS_METERS.g_SRVCE_LOC_USE_TRIGGER := FALSE;

		UPDATE SERVICE_LOCATION
		SET SUB_STATION_ID = :NEW.SUB_STATION_ID,
			SERVICE_ZONE_ID = v_SERVICE_ZONE_ID
		WHERE FEEDER_ID = :NEW.FEEDER_ID;

		ACCOUNTS_METERS.g_SRVCE_LOC_USE_TRIGGER := TRUE;

	END IF;
	
EXCEPTION
	WHEN OTHERS THEN
		ACCOUNTS_METERS.g_SRVCE_LOC_USE_TRIGGER := TRUE;
		ERRS.LOG_AND_RAISE();
	
END TX_FEEDER_SL_SYNC;
/