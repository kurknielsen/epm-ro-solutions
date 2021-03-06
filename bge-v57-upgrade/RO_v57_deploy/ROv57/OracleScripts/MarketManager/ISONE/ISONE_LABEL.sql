SET DEFINE OFF	
-- Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries
-- DELETE SYSTEM_LABEL; 
DECLARE

        v_ADMIN_ID NUMBER(9);
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
	    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_POSITION, p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
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
		PUT_DICTIONARY_VALUE(p_SETTING_NAME, p_VALUE, p_MODEL_ID, p_MODULE, p_KEY1, p_KEY3, p_KEY3);
	END IF;

	EXCEPTION
	        WHEN DUP_VAL_ON_INDEX THEN	NULL;
        	WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_DICTIONARY;
	------------------------------------
	PROCEDURE INSERT_DATA_EXCHANGE_ACTION
		(
		p_MODULE IN VARCHAR2,
		p_MKT_APP IN VARCHAR2,
		p_ACTION_NAME IN VARCHAR2,
		p_IS_IMPORT IN BOOLEAN
		) AS
	v_NAME SYSTEM_ACTION.ACTION_NAME%TYPE;
	v_DISPLAY_NAME VARCHAR2(256);
	v_IMPORT_TYPE VARCHAR2(16);
	v_EXCHANGE_TYPE VARCHAR2(16);
	v_ID NUMBER;
	BEGIN
		IF p_MKT_APP IS NULL THEN
			v_DISPLAY_NAME := 'NE: '||p_ACTION_NAME;
		ELSE
			v_DISPLAY_NAME := 'NE: '||p_MKT_APP||': '||p_ACTION_NAME;
		END IF;
		v_NAME := SUBSTR(p_MODULE,1,5)||':NE:'||p_MKT_APP||':'||p_ACTION_NAME;
		IF p_IS_IMPORT THEN
			v_IMPORT_TYPE := 'File';
			v_EXCHANGE_TYPE := NULL;
		ELSE
			v_EXCHANGE_TYPE := 'Exchange';
			v_IMPORT_TYPE := NULL;
		END IF;

		v_ID := ID.ID_FOR_SYSTEM_ACTION(v_NAME);
		IF v_ID < 0 THEN v_ID := 0; END IF;
		IO.PUT_SYSTEM_ACTION(v_ID, v_NAME, SUBSTR(v_NAME,1,32), v_DISPLAY_NAME, v_ID, NULL, p_MODULE, 'Data Exchange',
					v_DISPLAY_NAME, v_IMPORT_TYPE, NULL, v_EXCHANGE_TYPE, NULL);
		EM.PUT_SYSTEM_ACTION_ROLE(v_ID, v_ADMIN_ID, 1, 0, 0, v_ID);
	END INSERT_DATA_EXCHANGE_ACTION;
	------------------------------------
	PROCEDURE INSERT_BID_OFFER_ACTION
		(
		p_MODULE IN VARCHAR2,
		p_MKT_APP IN VARCHAR2,
		p_ACTION_NAME IN VARCHAR2,
		p_IS_IMPORT IN BOOLEAN
		) AS
	v_NAME SYSTEM_ACTION.ACTION_NAME%TYPE;
	v_DISPLAY_NAME VARCHAR2(256);
	v_IMPORT_TYPE VARCHAR2(16);
	v_EXCHANGE_TYPE VARCHAR2(16);
	v_ID NUMBER;
	BEGIN
		IF p_MKT_APP IS NULL THEN
			v_DISPLAY_NAME := 'NE: '||p_ACTION_NAME;
		ELSE
			v_DISPLAY_NAME := 'NE: '||p_MKT_APP||': '||p_ACTION_NAME;
		END IF;
		v_NAME := SUBSTR(p_MODULE,1,5)||':NE:'||p_MKT_APP||':'||p_ACTION_NAME;
		IF p_IS_IMPORT THEN
			v_IMPORT_TYPE := 'File';
			v_EXCHANGE_TYPE := NULL;
		ELSE
			v_EXCHANGE_TYPE := 'Bid Offer';
			v_IMPORT_TYPE := NULL;
		END IF;

		v_ID := ID.ID_FOR_SYSTEM_ACTION(v_NAME);
		IF v_ID < 0 THEN v_ID := 0; END IF;
		IO.PUT_SYSTEM_ACTION(v_ID, v_NAME, SUBSTR(v_NAME,1,32), v_DISPLAY_NAME, v_ID, NULL, p_MODULE, 'Bid Offer',
					v_DISPLAY_NAME, v_IMPORT_TYPE, NULL, v_EXCHANGE_TYPE, NULL);
		EM.PUT_SYSTEM_ACTION_ROLE(v_ID, v_ADMIN_ID, 1, 0, 0, v_ID);
	END INSERT_BID_OFFER_ACTION;
	------------------------------------
BEGIN


    SELECT ROLE_ID INTO v_ADMIN_ID
    FROM RETAIL_OFFICE_ROLE WHERE ROLE_NAME = 'Administrator';
	
    DELETE FROM SYSTEM_LABEL WHERE MODULE = 'Scheduling' AND KEY1 = 'Bids And Offers' AND KEY2 = 'Action' AND KEY3 = 'List' AND VALUE LIKE 'NE: %';
    DELETE FROM SYSTEM_ACTION WHERE ACTION_DESC LIKE 'NE: %';

    -- Price Import
    INSERT_DATA_EXCHANGE_ACTION('Scheduling', 'LMP', 'Query Day-Ahead', FALSE);
    INSERT_DATA_EXCHANGE_ACTION('Scheduling', 'LMP', 'Query Real-Time', FALSE);
    INSERT_DATA_EXCHANGE_ACTION('Scheduling', 'LMP', 'Query Regulation Clearing Price', FALSE);

END;
/
-- save changes to database
COMMIT;
SET DEFINE ON	
--Reset
