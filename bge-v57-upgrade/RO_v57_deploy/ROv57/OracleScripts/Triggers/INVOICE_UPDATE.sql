CREATE OR REPLACE TRIGGER INVOICE_UPDATE
	BEFORE INSERT OR UPDATE ON INVOICE
	FOR EACH ROW
BEGIN
	IF NOT GA.VERSION_STATEMENT THEN
		:new.AS_OF_DATE := LOW_DATE;
	END IF;

	IF UPDATING THEN
		IF NVL(:old.APPROVED_BY_ID,-1) <> NVL(:new.APPROVED_BY_ID,-1) THEN
			-- changing 'approved by'? then leave it alone
			RETURN;
		END IF;

		IF UPPER(NVL(:new.INVOICE_STATUS,'?')) LIKE '%SENT%' THEN
			-- just marking status as sent? then leave it alone
			RETURN;
		END IF;

		-- otherwise, something changed, so we need to revoke approval and 
		-- reset last_sent_by_id
		:new.APPROVED_BY_ID := NULL;
		:new.LAST_SENT_BY_ID := NULL;
	END IF;
END INVOICE_UPDATE;
/
