DECLARE
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
	v_POSITION NUMBER;
	v_COUNT NUMBER;
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

	    -- already have that value in table, so we can safely skip it
	    IF v_COUNT > 0 THEN RETURN; END IF;

	    -- determine proper position that won't collide w/ existing entry
	    SELECT NVL(MAX(POSITION),-1)+1
	    INTO v_POSITION
	    FROM SYSTEM_LABEL
	    WHERE MODEL_ID = p_MODEL_ID
		AND MODULE = p_MODULE
		AND KEY1 = p_KEY1
		AND KEY2 = p_KEY2
		AND KEY3 = p_KEY3;

	    INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, v_POSITION, p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN	NULL;
			WHEN OTHERS THEN	RAISE;
	END INSERT_SYSTEM_LABEL;
BEGIN

	-- Meter Channel Units
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Unit','?',1,'KVARH',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Unit','?',2,'KVA',NULL,0,0);
	INSERT_SYSTEM_LABEL(0,'Entity Manager','Meter Channel','Unit','?',3,'MWH',NULL,0,0);

	-- Sender PSEs
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','SENDER_CID','?',1,'EirGrid',1,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','SENDER_CID','?',2,'DSO',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','SENDER_CID','?',3,'NIE T' || CONSTANTS.AMPERSAND || 'D',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','SENDER_CID','?',4,'SONI',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','SENDER_CID','?',5,'TDO',0,0,0);
	
	-- Backing Sheets
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','Invoice Backing Sheets','?',1,'DUoS (ROI)',1,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','Invoice Backing Sheets','?',2,'TUoS (ROI)',2,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','Invoice Backing Sheets','?',3,'UoS',3,0,1);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','Invoice Backing Sheets','?',4,'DUoS (NI)',4,0,0);
	
	-- TUOS Tariff Codes to Ignore (treat as Adjustments)
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','TUoS','Adjustment Tariff Codes',1,'DSMC',1,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','TUoS','Adjustment Tariff Codes',2,'ATS-T',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','TUoS','Adjustment Tariff Codes',3,'ATS-D',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','TUoS','Adjustment Tariff Codes',4,'COP1',0,0,0);
	
	-- NI DUoS Groups
    INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',0,'T01',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',1,'T02',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',2,'T03',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',3,'T04',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',4,'T05',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',5,'T10',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',6,'T10A',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',7,'T20',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',8,'T20A',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',9,'T30',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',10,'T30A',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',11,'T50',0,0,0);
	INSERT_SYSTEM_LABEL(0,'MarketExchange','TDIE','NI DUOS Groups','?',12,'T71',0,0,0);
COMMIT;
END;
/

