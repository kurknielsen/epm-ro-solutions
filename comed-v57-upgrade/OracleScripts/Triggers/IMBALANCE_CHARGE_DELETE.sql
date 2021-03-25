CREATE OR REPLACE TRIGGER IMBALANCE_CHARGE_DELETE
	AFTER DELETE ON IMBALANCE_CHARGE
	FOR EACH ROW
BEGIN
	DELETE IMBALANCE_CHARGE_BAND
	WHERE CHARGE_ID = :old.CHARGE_ID
		AND CHARGE_DATE = :old.CHARGE_DATE;
END IMBALANCE_CHARGE_DELETE;
/
