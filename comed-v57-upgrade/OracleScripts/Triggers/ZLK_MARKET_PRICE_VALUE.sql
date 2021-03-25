CREATE OR REPLACE TRIGGER ZLK_MARKET_PRICE_VALUE
	BEFORE INSERT OR DELETE OR UPDATE
	ON MARKET_PRICE_VALUE
	FOR EACH ROW
DECLARE
	v_LOCK_STATE CHAR(1);
BEGIN
	IF UPDATING THEN
	
		-- attempts to set LOCK_STATE to NULL will silently do nothing
		:new.LOCK_STATE := NVL(:new.LOCK_STATE, :old.LOCK_STATE);
	
		-- did key columns change? If so, we need to check old and new
		-- lock states
		IF NOT ((:new.MARKET_PRICE_ID IS NULL AND :old.MARKET_PRICE_ID IS NULL) OR :new.MARKET_PRICE_ID = :old.MARKET_PRICE_ID) OR
		   NOT ((:new.PRICE_CODE IS NULL AND :old.PRICE_CODE IS NULL) OR :new.PRICE_CODE = :old.PRICE_CODE) OR
		   NOT ((:new.PRICE_DATE IS NULL AND :old.PRICE_DATE IS NULL) OR :new.PRICE_DATE = :old.PRICE_DATE) THEN
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:old.LOCK_STATE);
		
			-- query for new lock state
			SELECT MIN(LOCK_STATE)
			INTO v_LOCK_STATE
			FROM MARKET_PRICE_VAL_LOCK_SUMMARY
			WHERE MARKET_PRICE_ID = :new.MARKET_PRICE_ID
				  AND PRICE_CODE = :new.PRICE_CODE
				  AND BEGIN_DATE <= :new.PRICE_DATE
				  AND END_DATE >= :new.PRICE_DATE;
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(v_LOCK_STATE);
			:new.LOCK_STATE := NVL(v_LOCK_STATE,'U');
		
		-- only do something if this is not a no-op update
		ELSIF NOT ((:new.PRICE_BASIS IS NULL AND :old.PRICE_BASIS IS NULL) OR :new.PRICE_BASIS = :old.PRICE_BASIS) OR
			  NOT ((:new.PRICE IS NULL AND :old.PRICE IS NULL) OR :new.PRICE = :old.PRICE) THEN
		
			SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:new.LOCK_STATE);
		
		END IF;
		
	ELSIF INSERTING THEN
	
		-- query for lock state
		SELECT MIN(LOCK_STATE)
		INTO v_LOCK_STATE
		FROM MARKET_PRICE_VAL_LOCK_SUMMARY
		WHERE MARKET_PRICE_ID = :new.MARKET_PRICE_ID
			  AND PRICE_CODE = :new.PRICE_CODE
			  AND BEGIN_DATE <= :new.PRICE_DATE
			  AND END_DATE >= :new.PRICE_DATE;
	
		SECURITY_CONTROLS.ENFORCE_LOCK_STATE(v_LOCK_STATE);
		:new.LOCK_STATE := NVL(v_LOCK_STATE,'U');
	
	ELSE -- must be DELETING
	
		SECURITY_CONTROLS.ENFORCE_LOCK_STATE(:old.LOCK_STATE);
	
	END IF;

END ZLK_MARKET_PRICE_VALUE;
/