CREATE OR REPLACE TRIGGER INVOICE_LINE_ITEM_BEFORE
	BEFORE DELETE OR INSERT OR UPDATE ON INVOICE_LINE_ITEM
	FOR EACH ROW

DECLARE
v_INVOICE_STATUS VARCHAR2(32);
BEGIN
	-- fail if the invoice is closed
    BEGIN
		IF INSERTING THEN
			SELECT INVOICE_STATUS INTO v_INVOICE_STATUS
			FROM INVOICE
			WHERE INVOICE_ID = :new.INVOICE_ID;
		ELSE
			SELECT INVOICE_STATUS INTO v_INVOICE_STATUS
			FROM INVOICE
			WHERE INVOICE_ID = :old.INVOICE_ID;
		END IF;
	EXCEPTION
		WHEN OTHERS THEN
        	v_INVOICE_STATUS := 'NONE'; -- errors may indicate that the
            							-- INVOICE table is mutating - in which
	        							  -- case, ignore error and allow the update/insert/delete
	END;
    
	IF UPPER(SUBSTR(v_INVOICE_STATUS,1,6)) = 'CLOSED' THEN
		-- invoice is closed, so cancel this operation with an exception
		ERRS.RAISE(MSGCODES.c_ERR_INVOICE_CLOSED);
	END IF;
END INVOICE_LINE_ITEM_BEFORE;
/
