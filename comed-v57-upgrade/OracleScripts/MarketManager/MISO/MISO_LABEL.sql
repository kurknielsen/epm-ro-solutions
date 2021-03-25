SET DEFINE OFF	
--Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries
-- DELETE SYSTEM_LABEL; 

DECLARE
	v_SYSTEM_DICT_INDEX NUMBER(3) := 10;


	PROCEDURE INSERT_SYSTEM_LABEL
		(
		p_MODEL_ID IN NUMBER,
		p_MODULE IN VARCHAR,
		p_KEY1 IN VARCHAR,
		p_KEY2 IN VARCHAR,
		p_KEY3 IN VARCHAR,
		p_VALUE IN VARCHAR,
		p_CODE IN VARCHAR,
		p_IS_DEFAULT IN NUMBER,
		p_IS_HIDDEN IN NUMBER,
		p_INCLUDE_TEST IN NUMBER,
		p_SKIP_PREFIX IN NUMBER := 0
		) AS
	v_COUNT NUMBER(1);
	v_SYSTEM_LABEL_INDEX NUMBER(3);
	v_PREFIX VARCHAR2(6) := CASE p_SKIP_PREFIX WHEN 0 THEN 'MISO: ' ELSE '' END;
	BEGIN

	    SELECT COUNT(VALUE)
	    INTO v_COUNT
	    FROM SYSTEM_LABEL
	    WHERE MODEL_ID = p_MODEL_ID
		AND MODULE = p_MODULE
		AND KEY1 = p_KEY1
		AND KEY2 = p_KEY2
		AND KEY3 = p_KEY3
		AND VALUE = p_VALUE;

	    IF v_COUNT > 0 THEN RETURN; END IF;

	    SELECT NVL(MAX(POSITION),0)+1
	    INTO v_SYSTEM_LABEL_INDEX
	    FROM SYSTEM_LABEL
	    WHERE MODEL_ID = p_MODEL_ID
		AND MODULE = p_MODULE
		AND KEY1 = p_KEY1
		AND KEY2 = p_KEY2
		AND KEY3 = p_KEY3;

		--Standard MISO: entry
	    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) 
		VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, v_SYSTEM_LABEL_INDEX, v_PREFIX || p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
		v_SYSTEM_LABEL_INDEX := v_SYSTEM_LABEL_INDEX + 1;

		--MISO: TEST entry
		IF p_INCLUDE_TEST = 1 THEN
	    	INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) 
			VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, v_SYSTEM_LABEL_INDEX, v_PREFIX || 'TEST ' || p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
		END IF;

		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN	NULL;
			WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_LABEL;
	------------------------------------
		PROCEDURE INSERT_SYSTEM_DICTIONARY
		(
		p_SETTING_NAME IN VARCHAR2,
		p_VALUE IN VARCHAR2,
		p_MODEL_ID IN NUMBER := 0,
		p_MODULE IN VARCHAR2 := '?',
		p_KEY1 IN VARCHAR2 := '?',
		p_KEY2 IN VARCHAR2 := '?',
		p_KEY3 IN VARCHAR2 := '?'
		) AS
	--USED IN INITIAL POPULATION VIA SCRIPT
	v_OLD_VAL VARCHAR2(512);
	BEGIN

	v_OLD_VAL := GET_DICTIONARY_VALUE(p_SETTING_NAME, p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3);
	IF v_OLD_VAL IS NULL THEN
		-- don't overwrite existing entry
		PUT_DICTIONARY_VALUE(p_SETTING_NAME, p_VALUE, p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3);
	END IF;

	EXCEPTION
	        WHEN DUP_VAL_ON_INDEX THEN	NULL;
        	WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_DICTIONARY;
	------------------------------------
BEGIN

	DELETE FROM SYSTEM_LABEL WHERE MODULE = 'Scheduling' AND KEY1 = 'Bids And Offers' AND KEY2 = 'Action' AND KEY3 = 'List' AND VALUE LIKE 'MISO: %';
	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Action', 'List', 'FinSchedule', NULL, 0, 0, 1); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Action', 'List', 'VirtualBid', NULL, 0, 0, 1); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Action', 'List', 'VirtualOffer', NULL, 0, 0, 1); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Action', 'List', 'PriceSensitiveDemandBid',NULL,  0, 0, 1); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Action', 'List', 'FixedDemandBid', NULL, 0, 0, 1); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Action', 'List', 'ScheduleOffer', NULL, 0, 0, 1); 
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'Bids And Offers', 'Action', 'List', 'UpdateScheduleOffer', NULL, 0, 0, 1); 

	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'FTR Alloc Factor', NULL, 0, 0, 0, 1);	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Market Result', NULL, 0, 0, 0, 1);	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'NI Dist Factor', NULL, 0, 0, 0, 1);	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'LP Loss Dist', NULL, 0, 0, 0, 1);	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Asset Loss Dist', NULL, 0, 0, 0, 1);	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Ratio Load-Share', NULL, 0, 0, 0, 1);	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'UD Exempt Flag', NULL, 0, 0, 0, 1);	
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Dispatch Instr.', NULL, 0, 0, 0, 1);	

	INSERT_SYSTEM_DICTIONARY('URL', 'http://www.midwestmarket.org/mkt_reports', 0, 'MarketExchange', 'MISO','LMP','LMP File');

END;
/

-- save changes to database
COMMIT;
SET DEFINE ON	
--Reset
