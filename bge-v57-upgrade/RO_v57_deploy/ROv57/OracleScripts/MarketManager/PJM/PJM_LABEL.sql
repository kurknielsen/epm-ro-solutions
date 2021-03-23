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

	-- Corrected Node Name for DAYTON is DAY.
	PUT_DICTIONARY_VALUE('DAYTON', 'DAY', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
     --Corrected Node Names for FTR Zonal LMPs
    PUT_DICTIONARY_VALUE('AECO_ZONE', 'AECO', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('AEP_ZONE', 'AEP', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('APS_ZONE', 'APS', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('BGE_ZONE', 'BGE', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('COMED_ZONE', 'COMED', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('DAY_ZONE', 'DAY', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('DOM_ZONE', 'DOM', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('DPL_ZONE', 'DPL', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('DUQ_ZONE', 'DUQ', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('JCPL_ZONE', 'JCPL', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('METED_ZONE', 'METED', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('PECO_ZONE', 'PECO', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('PENELEC_ZONE', 'PENELEC', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('PEPCO_ZONE', 'PEPCO', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('PPL_ZONE', 'PPL', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('PSEG_ZONE', 'PSEG', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');
    PUT_DICTIONARY_VALUE('RECO_ZONE', 'RECO', 1, 'MarketExchange', 'PJM', 'Corrected NodeName');

	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'FTR Alloc Factor', NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Market Result', NULL);
    INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Load Plus Losses', NULL);
    INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Derated Loss', NULL); 
    
    INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Market Price Type', 'FTR Zonal LMP', NULL);
    INSERT_SYSTEM_LABEL(1, 'Product', 'Component', 'Combo List', 'Market Price Type', 'Energy Component', NULL);
/*
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Peak Load', NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Cap.Obligation', NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'NSPL', NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'FPPL', NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Net Inadvertant', NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', '500kV Losses', NULL);
	INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 'Meter Corrects.', NULL);
*/
	
	-- update with URL to actual page
	INSERT_SYSTEM_DICTIONARY('URL', 'http://oasis.pjm.com/doc/projload.txt', 0, 'MarketExchange', 'PJM', 'OASIS', 'LoadForecast');
	INSERT_SYSTEM_DICTIONARY('Is Test Mode', '0', 0, 'MarketExchange', 'PJM');
	INSERT_SYSTEM_DICTIONARY('Update Status In Test Mode', '0', 0, 'MarketExchange', 'PJM');
	INSERT_SYSTEM_DICTIONARY('Use Price-Sensitive Demand Bids', '0', 0, 'MarketExchange', 'PJM');
	INSERT_SYSTEM_DICTIONARY('Datetime Format', 'DD-MON-YYYY HH24:MI:SS', 0, 'MarketExchange', 'PJM');
	INSERT_SYSTEM_DICTIONARY('Sandbox', '0', 0, 'MarketExchange', 'PJM', 'Browserless', 'ees');
	INSERT_SYSTEM_DICTIONARY('Debug', '0', 0, 'MarketExchange', 'PJM', 'Browserless', 'ees');
	INSERT_SYSTEM_DICTIONARY('Sandbox', '0', 0, 'MarketExchange', 'PJM', 'Browserless', 'esched');
	INSERT_SYSTEM_DICTIONARY('Debug', '0', 0, 'MarketExchange', 'PJM', 'Browserless', 'esched');
	INSERT_SYSTEM_DICTIONARY('Sandbox', '0', 0, 'MarketExchange', 'PJM', 'Browserless', 'powermeter');
	INSERT_SYSTEM_DICTIONARY('Production URL', 'https://sso.pjm.com/access/authenticate/', 0, 'MarketExchange', 'PJM', 'SSO', '?');
	INSERT_SYSTEM_DICTIONARY('Sandbox URL', 'https://ssotrain.pjm.com/access/authenticate/', 0, 'MarketExchange', 'PJM', 'SSO', '?');
	INSERT_SYSTEM_DICTIONARY('Use Sandbox', '1', 0, 'MarketExchange', 'PJM', 'MarketsGateway', '?');
	INSERT_SYSTEM_DICTIONARY('Production URL', 'https://marketsgateway.pjm.com', 0, 'MarketExchange', 'PJM', 'MarketsGateway', '?');
	INSERT_SYSTEM_DICTIONARY('Sandbox URL', 'https://marketsgatewaytrain.pjm.com', 0, 'MarketExchange', 'PJM', 'MarketsGateway', '?');
    INSERT_SYSTEM_DICTIONARY('MSRS Report Version', 'Latest', 0, 'MarketExchange', 'PJM');	

	INSERT_SYSTEM_DICTIONARY('URL', 'ftp://ftp.pjm.com/pub/market_system_data/ftrzone/', 0, 'MarketExchange', 'PJM','LMP','FTR ZONAL LMP');
	INSERT_SYSTEM_DICTIONARY('URL', 'http://www.pjm.com/pub/account', 0, 'MarketExchange', 'PJM','LMP','LMP');
	INSERT_SYSTEM_DICTIONARY('URL', 'ftp://ftp.pjm.com/pub/account/oper-reserve-rates/monthly/', 0, 'MarketExchange', 'PJM', 'OASIS', 'OpResvRates');


END;
/

-- save changes to database
COMMIT;

SET DEFINE ON	
--Reset
