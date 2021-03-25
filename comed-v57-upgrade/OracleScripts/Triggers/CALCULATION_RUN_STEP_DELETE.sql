CREATE OR REPLACE TRIGGER CALCULATION_RUN_STEP_DELETE
	AFTER DELETE ON CALCULATION_RUN_STEP
	FOR EACH ROW
BEGIN
	-- clean up child records
	DELETE FORMULA_CHARGE_ITERATOR_NAME WHERE CHARGE_ID = :old.CHARGE_ID;
END CALCULATION_RUN_STEP_DELETE;
/