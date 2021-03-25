CREATE OR REPLACE TRIGGER VERSION_DELETE
	BEFORE DELETE ON VERSION
	FOR EACH ROW

DECLARE

v_DOMAIN CHAR(3) := UPPER(SUBSTR(:old.VERSION_DOMAIN,1,3));

BEGIN

	IF :old.VERSION_ID <= -100 THEN
		ERRS.RAISE(MSGCODES.c_ERR_PRIVILEGES, :old.VERSION_NAME || ' is a system Version which cannot be deleted.');
	END IF;

	IF v_DOMAIN = 'PRO' THEN
		IF NOT CAN_DELETE('PROFILING') THEN
			ERRS.RAISE_NO_DELETE_MODULE(v_DOMAIN);
		END IF;
		DELETE LOAD_PROFILE_POINT WHERE AS_OF_DATE = :old.AS_OF_DATE;
		DELETE LOAD_PROFILE_STATISTICS WHERE AS_OF_DATE = :old.AS_OF_DATE;
		DELETE LOAD_PROFILE_WRF WHERE AS_OF_DATE = :old.AS_OF_DATE;
	ELSIF v_DOMAIN IN ('FOR','BAC','USA') THEN
		IF NOT ((v_DOMAIN = 'FOR' AND CAN_DELETE('FORECASTING')) OR (v_DOMAIN IN ('BAC','USA') AND CAN_DELETE('SETTLEMENT')))THEN
			ERRS.RAISE_NO_DELETE_MODULE(v_DOMAIN);
		END IF;
		DELETE SERVICE WHERE AS_OF_DATE = :old.AS_OF_DATE;
		DELETE SERVICE_OBLIGATION WHERE AS_OF_DATE = :old.AS_OF_DATE;
		DELETE EDC_SYSTEM_UFE_LOAD WHERE AS_OF_DATE = :old.AS_OF_DATE;
	ELSIF v_DOMAIN = 'SCH' THEN
		IF NOT CAN_DELETE('SCHEDULING') THEN
			ERRS.RAISE_NO_DELETE_MODULE(v_DOMAIN);
		END IF;
		DELETE IT_SCHEDULE WHERE AS_OF_DATE = :old.AS_OF_DATE;
	ELSIF v_DOMAIN = 'STA' THEN
		IF NOT CAN_DELETE('BILLING') THEN
			ERRS.RAISE_NO_DELETE_MODULE(v_DOMAIN);
		END IF;
		DELETE BILLING_STATEMENT WHERE AS_OF_DATE = :old.AS_OF_DATE;
		DELETE INVOICE WHERE AS_OF_DATE = :old.AS_OF_DATE;
	END IF;
END VERSION_DELETE;
/
