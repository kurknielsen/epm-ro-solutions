SET DEFINE OFF	

-- Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries

DECLARE
	v_ADMIN_ID NUMBER(9);

	------------------------------------
	PROCEDURE INSERT_SYSTEM_LABEL
		(
		p_MODEL_ID IN NUMBER,
		p_MODULE IN VARCHAR,
		p_KEY1 IN VARCHAR,
		p_KEY2 IN VARCHAR,
		p_KEY3 IN VARCHAR,
		p_VALUE IN VARCHAR,
		p_CODE IN VARCHAR
		) AS
	v_COUNT NUMBER(1);
	v_SYSTEM_LABEL_INDEX NUMBER(3);
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

		INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) 
			VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, v_SYSTEM_LABEL_INDEX, p_VALUE, p_CODE, 0, 0);
    
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

	INSERT_SYSTEM_DICTIONARY('URL', 'http://www.nerc.net/tsin/registry/Active/', 0, 'MarketExchange', 'TSIN');

END;
/

-- save changes to database
COMMIT;

SET DEFINE ON	
--Reset
