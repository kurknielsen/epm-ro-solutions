SET DEFINE OFF	
-- Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries
-- DELETE SYSTEM_LABEL; 
DECLARE
-----------------------------------
	PROCEDURE INSERT_SYSTEM_LABEL
		(
		p_MODEL_ID IN NUMBER,
		p_MODULE IN VARCHAR,
		p_KEY1 IN VARCHAR,
		p_KEY2 IN VARCHAR,
		p_KEY3 IN VARCHAR,
		p_POSITION IN NUMBER,
		p_VALUE IN VARCHAR,
		p_CODE IN VARCHAR,
		p_IS_DEFAULT IN NUMBER,
		p_IS_HIDDEN IN NUMBER
		) AS
	BEGIN
        
	    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) 
                           VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_POSITION, p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN	NULL;
			WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_LABEL;
-----------------------------------
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

    DELETE FROM SYSTEM_LABEL WHERE MODULE = 'Scheduling' AND KEY1 = 'Bids And Offers' AND KEY2 = 'Action' AND KEY3 = 'List' AND VALUE LIKE 'ERCOT: %';
    
    --Transaction Types
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 5, 'LSELoad', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 6, 'Requirement', NULL, 0, NULL);
    INSERT_SYSTEM_LABEL(1,'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 7, 'Market Result', NULL, 0, NULL);
    
	
	INSERT_SYSTEM_DICTIONARY('LOAD EXTRACT DOWNLOAD URL', 'https://tml.ercot.com/tibco/MIDPage?folder_id=10001459', 0, 'MarketExchange', 'ERCOT','EXTRACT','?');
	INSERT_SYSTEM_DICTIONARY('LOAD EXTRACT PAGE URL', 'https://tml.ercot.com/tibco/MIDPage?folder_id=10001540', 0, 'MarketExchange', 'ERCOT','EXTRACT','?');
	INSERT_SYSTEM_DICTIONARY('LOAD EXTRACT BASE URL', 'https://tml.ercot.com/contentproxy/', 0, 'MarketExchange', 'ERCOT','EXTRACT','?');

	INSERT_SYSTEM_DICTIONARY('LMP BASE URL', 'http://www.ercot.com/pubreports/Public/Market%20Shadow%20Prices%20Extract/', 0, 'MarketExchange', 'ERCOT','LMP','?');
	INSERT_SYSTEM_DICTIONARY('LMP HIST BASE URL', 'https://pi.ercot.com/contentproxy/publicList?folder_id=10001892', 0, 'MarketExchange', 'ERCOT','LMP','?');
	INSERT_SYSTEM_DICTIONARY('ANC BASE URL', 'http://www.ercot.com/pubreports/Public/DayAhead%20Report/', 0, 'MarketExchange', 'ERCOT','LMP','?');
	INSERT_SYSTEM_DICTIONARY('ANC HIST BASE URL', 'https://pi.ercot.com/contentproxy/publicList?folder_id=10001730', 0, 'MarketExchange', 'ERCOT','LMP','?');


	INSERT_SYSTEM_DICTIONARY('INTIAL BASE URL', 'http://www.ercot.com/mktinfo/settlements/markettotals/initial/', 0, 'MarketExchange', 'ERCOT','SETTLEMENT','?');
	INSERT_SYSTEM_DICTIONARY('FINAL BASE URL', 'http://www.ercot.com/mktinfo/settlements/markettotals/final/', 0, 'MarketExchange', 'ERCOT','SETTLEMENT','?');
	INSERT_SYSTEM_DICTIONARY('TRUEUP BASE URL', 'http://www.ercot.com/mktinfo/settlements/markettotals/trueup/', 0, 'MarketExchange', 'ERCOT','SETTLEMENT','?');
    
END;
/
-- save changes to database
COMMIT;
SET DEFINE ON	
--Reset
