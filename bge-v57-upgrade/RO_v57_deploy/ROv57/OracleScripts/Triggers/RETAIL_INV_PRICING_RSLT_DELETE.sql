CREATE OR REPLACE TRIGGER RETAIL_INV_PRICING_RSLT_DELETE
	AFTER DELETE ON RETAIL_INVOICE_PRICING_RESULT
	FOR EACH ROW
BEGIN
	-- clean up child records
	DELETE FORMULA_CHARGE_ITERATOR_NAME WHERE CHARGE_ID = :old.FML_CHARGE_ID;
END RETAIL_INV_PRICING_RSLT_DELETE;
/
