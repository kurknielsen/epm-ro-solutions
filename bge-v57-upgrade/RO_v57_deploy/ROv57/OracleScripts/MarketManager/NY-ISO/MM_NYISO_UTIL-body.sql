CREATE OR REPLACE PACKAGE BODY MM_NYISO_UTIL IS

----------------------------------------------------------------------------------------------------

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_SC_ID RETURN NUMBER IS

v_SC_ID NUMBER;

BEGIN
  -- Initialization
  SELECT SC_ID
    INTO v_SC_ID
    FROM SCHEDULE_COORDINATOR
   WHERE SC_NAME = 'NYISO';

   RETURN v_SC_ID;

EXCEPTION
  WHEN OTHERS THEN

    IO.PUT_SC(v_SC_ID,
	 'NYISO', 'NYISO', '?', 0,
	 '?', '?', 'Active', 'NYISO',
	 '?', 'Service Point', 'Hour',
	 'None',  'None', 0, 0, 0, 0, 0.000);

	 If v_SC_ID != -1 THEN
	 	COMMIT;
	 END IF;

  RETURN v_SC_ID;

END GET_SC_ID;

----------------------------------------------------------------------------------------------------

FUNCTION GET_COMMODITY_ID(p_MARKET_TYPE IN VARCHAR2, p_IS_VIRTUAL IN BOOLEAN := FALSE) RETURN NUMBER IS

v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE := 0;
v_ALIAS IT_COMMODITY.COMMODITY_ALIAS%TYPE;
v_NAME IT_COMMODITY.COMMODITY_NAME%TYPE;
v_MARKET_TYPE IT_COMMODITY.MARKET_TYPE%TYPE;
v_COMMODITY_TYPE IT_COMMODITY.COMMODITY_TYPE%TYPE;
v_COMMODITY_UNIT IT_COMMODITY.COMMODITY_UNIT%TYPE;
c_COM_TYPE_ENERGY CONSTANT VARCHAR2(6) := 'Energy';
c_COM_TYPE_TRANS  CONSTANT VARCHAR2(12) := 'Transmission';
v_IS_VIRTUAL      NUMBER(1);

BEGIN

	-- translate market types to various types of commodity

	IF p_MARKET_TYPE = g_XFER_CAP_DA THEN
		v_MARKET_TYPE := g_DAYAHEAD;
		v_COMMODITY_TYPE := c_COM_TYPE_TRANS;
	ELSIF p_MARKET_TYPE = g_XFER_CAP_HA THEN
		v_MARKET_TYPE := g_HOURAHEAD;
		v_COMMODITY_TYPE := c_COM_TYPE_TRANS;
	ELSIF p_MARKET_TYPE = g_DAYAHEAD THEN
		IF p_IS_VIRTUAL THEN
			v_MARKET_TYPE := g_VIRTUAL;
		ELSE
			v_MARKET_TYPE := g_DAYAHEAD;
		END IF;
		v_COMMODITY_TYPE := c_COM_TYPE_ENERGY;
	ELSE
		v_MARKET_TYPE := g_REALTIME;
		v_COMMODITY_TYPE := c_COM_TYPE_ENERGY;
	END IF;

	v_NAME := v_MARKET_TYPE || ' ' || v_COMMODITY_TYPE;

    IF p_MARKET_TYPE = g_XFER_CAP_HA OR
        p_MARKET_TYPE = g_XFER_CAP_DA THEN
        --v_COMMODITY_UNIT := 'MW';
        v_ALIAS := v_NAME;
    ELSIF p_MARKET_TYPE = g_DAYAHEAD THEN
    	-- alias is the lookup key
		IF p_IS_VIRTUAL THEN
			v_ALIAS := 'VR';
		ELSE
			v_ALIAS := 'DA';
		END IF;
    ELSE
		-- alias is the lookup key
    	v_ALIAS := 'RT';
		--v_ALIAS := v_NAME;
    END IF;

    SELECT COMMODITY_ID
    INTO v_COMMODITY_ID
    FROM IT_COMMODITY
	WHERE COMMODITY_ALIAS = v_ALIAS;        --WHERE COMMODITY_NAME = v_NAME;

	RETURN v_COMMODITY_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
	BEGIN

	    v_COMMODITY_UNIT := 'MWH'; -- default
		IF p_IS_VIRTUAL THEN
			v_IS_VIRTUAL := 1;
		ELSE
			v_IS_VIRTUAL := 0;
		END IF;

		IO.PUT_IT_COMMODITY(
		o_OID => v_COMMODITY_ID,
		p_COMMODITY_NAME => v_NAME,
		p_COMMODITY_ALIAS => v_ALIAS,     -- lookup key
		p_COMMODITY_DESC => v_NAME,
		p_COMMODITY_ID => 0,
		p_COMMODITY_TYPE => v_COMMODITY_TYPE,
		p_COMMODITY_UNIT => v_COMMODITY_UNIT,
		p_COMMODITY_UNIT_FORMAT => '?',
		p_COMMODITY_PRICE_UNIT => 'Dollars',
		p_COMMODITY_PRICE_FORMAT => '?',
		p_IS_VIRTUAL => v_IS_VIRTUAL,      --0
		p_MARKET_TYPE => v_MARKET_TYPE
		);

	END;

	RETURN v_COMMODITY_ID;

END GET_COMMODITY_ID;

----------------------------------------------------------------------------------------------------
-- for loads there will not be DAYAHEAD values
FUNCTION GET_PRICE_INTERVAL(p_MARKET_TYPE IN VARCHAR2) RETURN VARCHAR2 IS

	v_PRICE_INTERVAL VARCHAR2(9);

BEGIN
    CASE p_MARKET_TYPE
	WHEN g_DAYAHEAD THEN
		v_PRICE_INTERVAL := 'Hour';
	WHEN g_HOURAHEAD THEN
		v_PRICE_INTERVAL := '15 Minute';
	WHEN g_REALTIME THEN
		v_PRICE_INTERVAL := '5 Minute';
	WHEN g_REALTIMEINTEGRATED THEN
		v_PRICE_INTERVAL := 'Hour';
	WHEN g_MKT_RESULT THEN
		v_PRICE_INTERVAL := 'Hour';
	END CASE;

	RETURN v_PRICE_INTERVAL;

END GET_PRICE_INTERVAL;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULE_VALUE(p_TX_ID       IN NUMBER,
							 p_SCHED_DATE  IN DATE,
							 p_AMOUNT      NUMBER,
							 p_PRICE       NUMBER := NULL) AS

	v_STATUS NUMBER;
	v_IDX    BINARY_INTEGER;

BEGIN

	--Update the schedule types (Uninvoiced, Initial, 4 Month, 12 Month)
	FOR v_IDX IN 1 .. g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP

		ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
						   p_SCHEDULE_TYPE  => g_STATEMENT_TYPE_ID_ARRAY(v_IDX),
						   p_SCHEDULE_STATE => GA.INTERNAL_STATE,
						   p_SCHEDULE_DATE  => p_SCHED_DATE,
						   p_AS_OF_DATE     => SYSDATE,
						   p_AMOUNT         => p_AMOUNT,
						   p_PRICE          => p_PRICE,
						   p_STATUS         => v_STATUS);

	END LOOP;

END PUT_SCHEDULE_VALUE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_NODE_TYPE(p_NODE_NAME VARCHAR2) RETURN VARCHAR2 AS
BEGIN

	IF p_NODE_NAME LIKE '%REFERENCE' THEN
		RETURN g_NODE_TYPE_BUS;
	ELSIF p_NODE_NAME LIKE ('%^_VL^_%') ESCAPE '^' THEN
		RETURN g_NODE_TYPE_AGG;
	ELSIF p_NODE_NAME LIKE ('%^_VS^_%') ESCAPE '^' THEN
		RETURN g_NODE_TYPE_AGG;
	ELSE
		RETURN g_NODE_TYPE_GEN;
	END IF;

END GET_NODE_TYPE;
---------------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_PRICE_VALUE
	(
	p_MARKET_PRICE_ID IN NUMBER,
	p_PRICE_DATE      IN DATE,
	p_PRICE_CODE      IN CHAR,
	p_PRICE           IN NUMBER,
	p_PRICE_BASIS     IN NUMBER,
	p_STATUS          OUT NUMBER,
	p_LOGGER		  IN OUT NOCOPY MM_LOGGER_ADAPTER
	) AS

	v_MESSAGE VARCHAR2(1024);
BEGIN

	p_STATUS              := GA.SUCCESS;
	MM_UTIL.PUT_MARKET_PRICE_VALUE(p_MARKET_PRICE_ID,
         							p_PRICE_DATE,
									p_PRICE_CODE,
									p_PRICE,
									p_PRICE_BASIS,
									p_STATUS,
									v_MESSAGE);
	IF p_STATUS <> GA.SUCCESS THEN
		p_LOGGER.LOG_ERROR(v_MESSAGE);
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
		p_STATUS              := SQLCODE;
		p_LOGGER.LOG_ERROR('Error Inserting Market Price Value for market price id:'  || p_MARKET_PRICE_ID);

END PUT_MARKET_PRICE_VALUE;
---------------------------------------------------------------------------------------------
FUNCTION GET_NYISO_CONTRACT_ID(p_ACCOUNT_NAME IN VARCHAR2) RETURN NUMBER IS
v_IDs NUMBER_COLLECTION;

BEGIN

	-- query for the contract IDs
    v_IDs := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(p_ACCOUNT_NAME, EC.ED_INTERCHANGE_CONTRACT, EC.ES_NYISO);
	IF v_IDs.COUNT > 0 THEN -- are any NYISO contracts in the system?
        RETURN v_IDs(v_IDs.FIRST);
    ELSE
        RETURN NULL;
    END IF;

END GET_NYISO_CONTRACT_ID;
---------------------------------------------------------------------------------------------


BEGIN
	-- Initialization
	BEGIN
		g_TEST := TO_NUMBER(NVL(GET_DICTIONARY_VALUE('Test Mode',0,'MarketExchange','NYISO'),'0'))<>0;
	EXCEPTION
		WHEN OTHERS THEN
			g_TEST := FALSE;
	END;

	g_NYISO_SC_ID := GET_SC_ID;
	IF g_NYISO_SC_ID = -1 THEN
		MM_NYISO_UTIL.g_NYISO_SC_ID := 0;
	END IF;

	FOR v_ARRAY_INDEX IN 1 .. g_STATEMENT_TYPE_ARRAY.COUNT LOOP
		g_STATEMENT_TYPE_ID_ARRAY.EXTEND();
		/*SELECT S.STATEMENT_TYPE_ID
           INTO g_STATEMENT_TYPE_ID_ARRAY(v_ARRAY_INDEX)
           FROM STATEMENT_TYPE S
        WHERE S.STATEMENT_TYPE_ALIAS LIKE g_STATEMENT_TYPE_ARRAY(v_ARRAY_INDEX) || '%';*/

		--Get the statement type Id based on the Statement Type entity attribute
		SELECT TEA.OWNER_ENTITY_ID
		  INTO g_STATEMENT_TYPE_ID_ARRAY(v_ARRAY_INDEX)
		  FROM TEMPORAL_ENTITY_ATTRIBUTE TEA
		 WHERE TEA.ATTRIBUTE_ID IN
			   (SELECT EA.ATTRIBUTE_ID
				  FROM ENTITY_ATTRIBUTE EA
				 WHERE EA.ATTRIBUTE_NAME = 'NYISO')
		   AND TEA.ATTRIBUTE_VAL = g_STATEMENT_TYPE_ARRAY(v_ARRAY_INDEX);

	END LOOP;
END MM_NYISO_UTIL;
/
