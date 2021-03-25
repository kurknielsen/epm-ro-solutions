PROMPT Sync'ing TDIE_ACCOUNT with ACCOUNT...

BEGIN
	-- Seed "low date" as received date for each account
	MERGE INTO TDIE_ACCOUNT T
	USING (SELECT A.ACCOUNT_ID, CONSTANTS.LOW_DATE as LAST_READING_RCV_DATE
			FROM ACCOUNT A) S
	ON (T.ACCOUNT_ID = S.ACCOUNT_ID)
	WHEN NOT MATCHED THEN
		INSERT (T.ACCOUNT_ID, T.LAST_READING_RCV_DATE)
		VALUES (S.ACCOUNT_ID, S.LAST_READING_RCV_DATE);		
END;
/


PROMPT Trigger on insert into ACCOUNT...

CREATE OR REPLACE TRIGGER TDIE_ACCOUNT_INSERT
	AFTER INSERT ON ACCOUNT
	FOR EACH ROW
BEGIN
	-- Seed received date for new accounts
	INSERT INTO TDIE_ACCOUNT (ACCOUNT_ID, LAST_READING_RCV_DATE)
	VALUES (:new.ACCOUNT_ID, CONSTANTS.LOW_DATE);
END;
/

