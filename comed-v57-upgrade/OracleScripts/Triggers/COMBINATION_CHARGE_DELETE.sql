CREATE OR REPLACE TRIGGER COMBINATION_CHARGE_DELETE
	AFTER DELETE ON COMBINATION_CHARGE
	FOR EACH ROW
BEGIN
	--DELETE COMBINATION_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	-- cannot do above delete because it will cause table is mutating error - 
	-- instead, mark the charge ID in RTO_WORK and use another (non-row) trigger to clean up
	INSERT INTO RTO_WORK (WORK_ID, WORK_XID) VALUES (-9876, :old.COMBINED_CHARGE_ID);

	DELETE ACCOUNT_SERVICE_CHARGE WHERE CHARGE_ID IN(:old.COMBINED_CHARGE_ID,-:old.COMBINED_CHARGE_ID);
	DELETE BILLING_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE CONVERSION_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE ENTITY_ATTRIBUTE_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE FORMULA_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE FTR_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE IMBALANCE_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE LMP_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE OPER_PROFIT_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE TAX_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
	DELETE TRANSMISSION_CHARGE WHERE CHARGE_ID = :old.COMBINED_CHARGE_ID;
END COMBINATION_CHARGE_DELETE;
/

CREATE OR REPLACE TRIGGER COMBINATION_CHARGE_DELETE2
	AFTER DELETE ON COMBINATION_CHARGE
DECLARE
v_WORK_IDs ID_TABLE := ID_TABLE();
BEGIN
	DELETE RTO_WORK
	WHERE WORK_ID = -9876
	RETURNING ID_TYPE(WORK_XID)
	BULK COLLECT INTO v_WORK_IDs;

	IF v_WORK_IDs.COUNT > 0 THEN
		DELETE COMBINATION_CHARGE
		WHERE CHARGE_ID IN
			(SELECT X.ID FROM TABLE(CAST(v_WORK_IDs AS ID_TABLE)) X);
	END IF;
END COMBINATION_CHARGE_DELETE2;
/