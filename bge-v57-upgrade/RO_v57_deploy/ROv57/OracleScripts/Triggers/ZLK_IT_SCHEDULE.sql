CREATE OR REPLACE TRIGGER ZLK_IT_SCHEDULE
	BEFORE INSERT OR DELETE OR UPDATE
	ON IT_SCHEDULE
	FOR EACH ROW
DECLARE
	v_LOCK_STATE CHAR(1);
BEGIN
	IF UPDATING THEN
	
		-- attempts to set LOCK_STATE to NULL will silently do nothing
		:new.LOCK_STATE := NVL(:new.LOCK_STATE, :old.LOCK_STATE);
	
		-- did key columns change? If so, we need to check old and new
		-- lock states
		IF NOT ((:new.TRANSACTION_ID IS NULL AND :old.TRANSACTION_ID IS NULL) OR :new.TRANSACTION_ID = :old.TRANSACTION_ID) OR
		   NOT ((:new.SCHEDULE_TYPE IS NULL AND :old.SCHEDULE_TYPE IS NULL) OR :new.SCHEDULE_TYPE = :old.SCHEDULE_TYPE) OR
		   NOT ((:new.SCHEDULE_STATE IS NULL AND :old.SCHEDULE_STATE IS NULL) OR :new.SCHEDULE_STATE = :old.SCHEDULE_STATE) OR
		   NOT ((:new.SCHEDULE_DATE IS NULL AND :old.SCHEDULE_DATE IS NULL) OR :new.SCHEDULE_DATE = :old.SCHEDULE_DATE) THEN
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:old.LOCK_STATE);
		
			-- query for new lock state
			SELECT MIN(LOCK_STATE)
			INTO v_LOCK_STATE
			FROM IT_SCHEDULE_LOCK_SUMMARY
			WHERE TRANSACTION_ID = :new.TRANSACTION_ID
				  AND SCHEDULE_TYPE = :new.SCHEDULE_TYPE
				  AND SCHEDULE_STATE = :new.SCHEDULE_STATE
				  AND BEGIN_DATE <= :new.SCHEDULE_DATE
				  AND END_DATE >= :new.SCHEDULE_DATE;
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(v_LOCK_STATE);
			:new.LOCK_STATE := NVL(v_LOCK_STATE,'U');
		
		-- only do something if this is not a no-op update
		ELSIF NOT ((:new.AMOUNT IS NULL AND :old.AMOUNT IS NULL) OR :new.AMOUNT = :old.AMOUNT) OR
			  NOT ((:new.PRICE IS NULL AND :old.PRICE IS NULL) OR :new.PRICE = :old.PRICE) THEN
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:new.LOCK_STATE);
		
		END IF;
		
	ELSIF INSERTING THEN
	
		-- query for lock state
		SELECT MIN(LOCK_STATE)
		INTO v_LOCK_STATE
		FROM IT_SCHEDULE_LOCK_SUMMARY
		WHERE TRANSACTION_ID = :new.TRANSACTION_ID
			  AND SCHEDULE_TYPE = :new.SCHEDULE_TYPE
			  AND SCHEDULE_STATE = :new.SCHEDULE_STATE
			  AND BEGIN_DATE <= :new.SCHEDULE_DATE
			  AND END_DATE >= :new.SCHEDULE_DATE;
	
		SECURITY_CONTROLS.ENFORCE_LOCK_STATE(v_LOCK_STATE);
		:new.LOCK_STATE := NVL(v_LOCK_STATE,'U');
	
	ELSE -- must be DELETING
	
		SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:old.LOCK_STATE);
	
	END IF;

END ZLK_IT_SCHEDULE;
/
