CREATE OR REPLACE TRIGGER ZLK_CALCULATION_RUN
	BEFORE INSERT OR DELETE OR UPDATE
	ON CALCULATION_RUN
	FOR EACH ROW
DECLARE
	v_LOCK_STATE CHAR(1);
BEGIN
	IF UPDATING THEN
	
		-- attempts to set LOCK_STATE to NULL will silently do nothing
		:new.LOCK_STATE := NVL(:new.LOCK_STATE, :old.LOCK_STATE);
	
		-- did key columns change? If so, we need to check old and new
		-- lock states
		IF NOT ((:new.CALC_PROCESS_ID IS NULL AND :old.CALC_PROCESS_ID IS NULL) OR :new.CALC_PROCESS_ID = :old.CALC_PROCESS_ID) OR
		   NOT ((:new.STATEMENT_TYPE_ID IS NULL AND :old.STATEMENT_TYPE_ID IS NULL) OR :new.STATEMENT_TYPE_ID = :old.STATEMENT_TYPE_ID) OR
		   NOT ((:new.CONTEXT_ENTITY_ID IS NULL AND :old.CONTEXT_ENTITY_ID IS NULL) OR :new.CONTEXT_ENTITY_ID = :old.CONTEXT_ENTITY_ID) OR
		   NOT ((:new.RUN_DATE IS NULL AND :old.RUN_DATE IS NULL) OR :new.RUN_DATE = :old.RUN_DATE) THEN
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:old.LOCK_STATE);
		
			-- query for new lock state
			SELECT MIN(LOCK_STATE)
			INTO v_LOCK_STATE
			FROM CALCULATION_RUN_LOCK_SUMMARY
			WHERE CALC_PROCESS_ID = :new.CALC_PROCESS_ID
				  AND STATEMENT_TYPE_ID = :new.STATEMENT_TYPE_ID
				  AND CONTEXT_ENTITY_ID = :new.CONTEXT_ENTITY_ID
				  AND BEGIN_DATE <= :new.RUN_DATE
				  AND END_DATE >= :new.RUN_DATE;
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(v_LOCK_STATE);
			:new.LOCK_STATE := NVL(v_LOCK_STATE,'U');
		
		-- only do something if this is not a no-op update
		ELSIF NOT ((:new.CALC_RUN_ID IS NULL AND :old.CALC_RUN_ID IS NULL) OR :new.CALC_RUN_ID = :old.CALC_RUN_ID) OR
			  NOT ((:new.START_TIME IS NULL AND :old.START_TIME IS NULL) OR :new.START_TIME = :old.START_TIME) OR
			  NOT ((:new.END_TIME IS NULL AND :old.END_TIME IS NULL) OR :new.END_TIME = :old.END_TIME) OR
			  NOT ((:new.PROCESS_ID IS NULL AND :old.PROCESS_ID IS NULL) OR :new.PROCESS_ID = :old.PROCESS_ID) THEN
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:new.LOCK_STATE);

		END IF;
		
	ELSIF INSERTING THEN
	
		-- query for lock state
		SELECT MIN(LOCK_STATE)
		INTO v_LOCK_STATE
		FROM CALCULATION_RUN_LOCK_SUMMARY
		WHERE CALC_PROCESS_ID = :new.CALC_PROCESS_ID
			  AND STATEMENT_TYPE_ID = :new.STATEMENT_TYPE_ID
			  AND CONTEXT_ENTITY_ID = :new.CONTEXT_ENTITY_ID
			  AND BEGIN_DATE <= :new.RUN_DATE
			  AND END_DATE >= :new.RUN_DATE;
	
		SECURITY_CONTROLS.ENFORCE_LOCK_STATE(v_LOCK_STATE);
		:new.LOCK_STATE := NVL(v_LOCK_STATE,'U');
	
	ELSE -- must be DELETING
	
		SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:old.LOCK_STATE);
	
	END IF;

END ZLK_CALCULATION_RUN;
/