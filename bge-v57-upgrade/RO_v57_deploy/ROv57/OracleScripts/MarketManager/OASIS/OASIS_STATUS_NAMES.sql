DECLARE
	PROCEDURE ADD_STATUS
		(
		p_STATUS_NAME IN VARCHAR2,
		p_IS_ACTIVE IN NUMBER
		) AS
	BEGIN
		INSERT INTO INTERCHANGE_TRANSACTION_STATUS (TRANSACTION_STATUS_NAME,TRANSACTION_IS_ACTIVE) 
		VALUES (p_STATUS_NAME, p_IS_ACTIVE);
	EXCEPTION WHEN OTHERS THEN 
		NULL;
	END ADD_STATUS;
BEGIN
	ADD_STATUS('NEW',1);
	ADD_STATUS('QUEUED',1);
	ADD_STATUS('RECEIVED',1);
	ADD_STATUS('STUDY',1);
	ADD_STATUS('COUNTEROFFER',0);
	ADD_STATUS('REBID',0);
	ADD_STATUS('ACCEPTED',1);
	ADD_STATUS('INVALID',0);
	ADD_STATUS('REFUSED',0);
	ADD_STATUS('DECLINED',0);
	ADD_STATUS('SUPERSEDED',0);
	ADD_STATUS('RETRACTED',0);
	ADD_STATUS('WITHDRAWN',0);
	ADD_STATUS('CONFIRMED',1);
	ADD_STATUS('ANNULLED',0);
	ADD_STATUS('DISPLACED',0);
	
	COMMIT;
END;
/
