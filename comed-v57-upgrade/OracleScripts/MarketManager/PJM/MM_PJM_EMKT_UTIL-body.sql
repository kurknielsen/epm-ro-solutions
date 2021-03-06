CREATE OR REPLACE PACKAGE BODY MM_PJM_EMKT_UTIL IS
	g_EMKT_GEN_PORTFOLIO_ATTR NUMBER(9);
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_RESOURCE_FOR_PJM_PNODEID
   (
   p_PJM_PNODEID IN VARCHAR2
   ) RETURN SUPPLY_RESOURCE%ROWTYPE IS
   v_PNODEID_ATTRIBUTE_ID NUMBER;
   v_RESOURCE SUPPLY_RESOURCE%ROWTYPE;

   BEGIN
        ID.ID_FOR_ENTITY_ATTRIBUTE('PJM_PNODEID', EC.ED_SUPPLY_RESOURCE, 'String', TRUE, v_PNODEID_ATTRIBUTE_ID);

        SELECT
              SP.* INTO v_RESOURCE
        FROM
              TEMPORAL_ENTITY_ATTRIBUTE TEA,
              SUPPLY_RESOURCE SP
        WHERE
              TEA.ATTRIBUTE_VAL = p_PJM_PNODEID AND
              TEA.ATTRIBUTE_ID = v_PNODEID_ATTRIBUTE_ID AND
              TEA.OWNER_ENTITY_ID = SP.RESOURCE_ID;

        RETURN v_RESOURCE;
   EXCEPTION
   WHEN NO_DATA_FOUND THEN
        RETURN NULL;

   END GET_RESOURCE_FOR_PJM_PNODEID;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_TRANSACTION_ID
	(
	p_ISO_ACCOUNT_NAME IN VARCHAR2,
	p_PNODE_IDENT IN VARCHAR2,
	p_TRANSACTION_TYPE IN VARCHAR2,
	p_COMMODITY_NAME IN VARCHAR2,
	p_IS_IMPORT_EXPORT IN NUMBER,
	p_IS_FIRM IN NUMBER,
	p_CREATE_IF_NOT_FOUND IN BOOLEAN,
	p_TRANSACTION_ID OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2,
	p_SCHEDULE_NUMBER IN NUMBER DEFAULT 1,
	p_PJM_GEN_TXN_TYPE IN VARCHAR2 DEFAULT NULL,
	p_TIER_TYPE IN VARCHAR2 DEFAULT NULL,
    p_TXN_DESC IN VARCHAR2 DEFAULT NULL
	) AS

	v_RESOURCE SUPPLY_RESOURCE%ROWTYPE;
	v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
	v_SERVICE_POINT_ID NUMBER(9);
	v_CONTRACT_ID NUMBER(9);
	v_SERVICE_POINT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
	v_COMMODITY_ALIAS IT_COMMODITY.COMMODITY_ALIAS%TYPE;
	v_DEMAND_TYPE VARCHAR2(16);
    v_STATUS NUMBER;
    v_RESOURCE_ID NUMBER(9);
    v_PNODEID_ATTRIBUTE_ID NUMBER(9);
    v_PJM_GEN_TXN_ATTRIBUTE_ID NUMBER(9);

BEGIN

	--=================================
	-- Get RESOURCE and SERVICE_POINT
	--=================================
	-- If this is a DA Energy Generation transaction, then get a Resource and Service Point.
	-- Otherwise, just get the Service Point.
	IF p_TRANSACTION_TYPE = 'Generation' AND p_COMMODITY_NAME <> MM_PJM_UTIL.g_COMM_VIRTUAL THEN
		-- Check if the resource with attribite PJM_PNODEID exists for this node identifier
		-- If not create a resource with PJM_PNODEID set to this node id
		v_RESOURCE := GET_RESOURCE_FOR_PJM_PNODEID(p_PNODE_IDENT);
		IF v_RESOURCE.RESOURCE_ID IS NULL THEN
			IO.PUT_SUPPLY_RESOURCE(v_RESOURCE_ID, p_PNODE_IDENT, p_PNODE_IDENT, p_PNODE_IDENT, 0, 0, 0, 0);
			ID.ID_FOR_ENTITY_ATTRIBUTE('PJM_PNODEID', EC.ED_SUPPLY_RESOURCE, 'String', TRUE, v_PNODEID_ATTRIBUTE_ID);
			SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_RESOURCE_ID, v_PNODEID_ATTRIBUTE_ID, SYSDATE, NULL, p_PNODE_IDENT, v_RESOURCE_ID, v_PNODEID_ATTRIBUTE_ID, NULL, v_STATUS);
			v_SERVICE_POINT_ID := 0;

			LOGS.LOG_WARN('Update the resource name and service point for ' || p_PNODE_IDENT);
		ELSE
			v_SERVICE_POINT_ID := NVL(v_RESOURCE.SERVICE_POINT_ID,0);
		END IF;
	ELSE
		v_SERVICE_POINT_ID := MM_PJM_UTIL.ID_FOR_SERVICE_POINT_PNODE(p_PNODE_IDENT);
	END IF;

	v_CONTRACT_ID  := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCOUNT_NAME);

	--============================================
	-- CHECK IF TRANSACTION EXISTS.
	--============================================
	BEGIN
		--Generation Transactions use a different query.
		IF p_TRANSACTION_TYPE = 'Generation' AND p_COMMODITY_NAME <> MM_PJM_UTIL.g_COMM_VIRTUAL THEN
			SELECT T.TRANSACTION_ID
			INTO p_TRANSACTION_ID
			FROM PJM_GEN_TXNS_BY_TYPE T, IT_COMMODITY C
			WHERE C.COMMODITY_NAME = p_COMMODITY_NAME
				AND T.COMMODITY_ID = C.COMMODITY_ID
				AND T.TRANSACTION_IDENTIFIER = p_PNODE_IDENT
				AND T.TRANSACTION_TYPE = p_TRANSACTION_TYPE
				AND T.CONTRACT_ID = v_CONTRACT_ID
				AND T.IS_BID_OFFER = 1
				AND T.IS_FIRM = p_IS_FIRM
				AND T.IS_IMPORT_EXPORT = p_IS_IMPORT_EXPORT
				AND T.SC_ID = EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM) --MM_PJM_UTIL.g_PJM_SC_ID
				AND T.PJM_GEN_TXN_TYPE = p_PJM_GEN_TXN_TYPE
				AND T.AGREEMENT_TYPE = (CASE WHEN p_PJM_GEN_TXN_TYPE = g_PJM_GEN_SCHEDULE_TXN_TYPE
							THEN TO_CHAR(p_SCHEDULE_NUMBER) WHEN p_PJM_GEN_TXN_TYPE = g_PJM_GEN_SPIN_RES_TXN_TYPE
							THEN p_TIER_TYPE ELSE T.AGREEMENT_TYPE END);
		ELSE
			SELECT T.TRANSACTION_ID
			INTO p_TRANSACTION_ID
			FROM INTERCHANGE_TRANSACTION T, IT_COMMODITY C
			WHERE C.COMMODITY_NAME = p_COMMODITY_NAME
				AND T.COMMODITY_ID = C.COMMODITY_ID
				AND T.TRANSACTION_IDENTIFIER = p_PNODE_IDENT
				AND T.TRANSACTION_TYPE = p_TRANSACTION_TYPE
				AND T.CONTRACT_ID = v_CONTRACT_ID
				AND T.IS_BID_OFFER = 1
				AND T.IS_FIRM = p_IS_FIRM
				AND T.IS_IMPORT_EXPORT = p_IS_IMPORT_EXPORT
				AND T.SC_ID = EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM); --MM_PJM_UTIL.g_PJM_SC_ID;
		END IF;

	EXCEPTION
		WHEN MSGCODES.e_ERR_TOO_MANY_ENTRIES THEN
			p_ERROR_MESSAGE := 'Multiple ' || p_TRANSACTION_TYPE || ' Transactions exist: ISO ' || p_ISO_ACCOUNT_NAME || ', location ' || p_PNODE_IDENT;
		
	--============================================
	-- CREATE THE TRANSACTION IF IT WAS NOT FOUND.
	--============================================
		WHEN NO_DATA_FOUND THEN

			SELECT SERVICE_POINT_NAME INTO v_SERVICE_POINT_NAME FROM SERVICE_POINT WHERE SERVICE_POINT_ID = v_SERVICE_POINT_ID;
			ID.ID_FOR_COMMODITY(p_COMMODITY_NAME, FALSE, v_TRANSACTION.COMMODITY_ID);
			SELECT COMMODITY_ALIAS INTO v_COMMODITY_ALIAS FROM IT_COMMODITY WHERE COMMODITY_ID = v_TRANSACTION.COMMODITY_ID;

			IF NOT p_CREATE_IF_NOT_FOUND THEN
				LOGS.LOG_DEBUG('No ' || p_TRANSACTION_TYPE || ' ' || v_COMMODITY_ALIAS || ' Txn Found: ISO ' || p_ISO_ACCOUNT_NAME || ', location ' || v_SERVICE_POINT_NAME);
			ELSE

				-- VIRTUALS
				IF p_COMMODITY_NAME = MM_PJM_UTIL.g_COMM_VIRTUAL THEN
					v_TRANSACTION.TRANSACTION_NAME := p_ISO_ACCOUNT_NAME || ':' || v_SERVICE_POINT_NAME ||
						CASE p_TRANSACTION_TYPE WHEN 'Generation' THEN ' INC' ELSE ' DEC' END;
					v_TRANSACTION.TRAIT_CATEGORY := 'Virtual';

				-- GENERATION
				ELSIF p_TRANSACTION_TYPE = 'Generation' THEN
					v_RESOURCE := MM_PJM_EMKT_UTIL.GET_RESOURCE_FOR_PJM_PNODEID(p_PNODE_IDENT);
					v_TRANSACTION.TRAIT_CATEGORY := p_PJM_GEN_TXN_TYPE;

					CASE p_PJM_GEN_TXN_TYPE
					WHEN g_PJM_GEN_UNIT_DATA_TXN_TYPE THEN
						v_TRANSACTION.TRANSACTION_NAME := p_ISO_ACCOUNT_NAME || ':' || 'Gen' || ':' || v_RESOURCE.RESOURCE_NAME;
					WHEN g_PJM_GEN_SCHEDULE_TXN_TYPE THEN
						v_TRANSACTION.TRANSACTION_NAME := p_ISO_ACCOUNT_NAME || ':' || 'Gen' || ':' || v_RESOURCE.RESOURCE_NAME || ':' || p_SCHEDULE_NUMBER;
						v_TRANSACTION.AGREEMENT_TYPE := p_SCHEDULE_NUMBER;
					WHEN g_PJM_GEN_REGULATION_TXN_TYPE THEN
						v_TRANSACTION.TRANSACTION_NAME := p_ISO_ACCOUNT_NAME || ':' || 'Regulation' || ':' || v_RESOURCE.RESOURCE_NAME;
					WHEN g_PJM_GEN_SPIN_RES_TXN_TYPE THEN
						v_TRANSACTION.TRANSACTION_NAME := p_ISO_ACCOUNT_NAME || ':' || 'SpinReserve ' || p_TIER_TYPE || 'Award:' || v_RESOURCE.RESOURCE_NAME;
						v_TRANSACTION.AGREEMENT_TYPE := p_TIER_TYPE;
					END CASE;

				-- LOAD
				ELSE
					v_DEMAND_TYPE := CASE WHEN p_IS_FIRM = 1 THEN 'Fixed' ELSE 'Price-sens' END;
					v_TRANSACTION.TRANSACTION_NAME := p_ISO_ACCOUNT_NAME || ':' || v_SERVICE_POINT_NAME || ':' || v_DEMAND_TYPE || ':' || v_COMMODITY_ALIAS;
					v_TRANSACTION.SELLER_ID    := MM_PJM_UTIL.GET_PSE(p_ISO_ACCOUNT_NAME);
					v_TRANSACTION.PURCHASER_ID := ID.ID_FOR_PSE('PJM');
					v_TRANSACTION.TRAIT_CATEGORY := 'Demand';
				END IF;

				IF LOGS.IS_DEBUG_ENABLED THEN
					LOGS.LOG_DEBUG('Creating Transaction name=' || v_TRANSACTION.TRANSACTION_NAME);
				END IF;

				-- SET BEGIN DATE AND END DATE.
				SELECT IC.BEGIN_DATE, IC.END_DATE
				INTO v_TRANSACTION.BEGIN_DATE, v_TRANSACTION.END_DATE
				FROM INTERCHANGE_CONTRACT IC
				WHERE IC.CONTRACT_ID = v_CONTRACT_ID;

 				v_TRANSACTION.TRANSACTION_ID := 0;
 				v_TRANSACTION.SC_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM); --MM_PJM_UTIL.g_PJM_SC_ID;
 				v_TRANSACTION.IS_BID_OFFER := 1;
				v_TRANSACTION.POR_ID := v_SERVICE_POINT_ID;
 				v_TRANSACTION.POD_ID := v_SERVICE_POINT_ID;
 				v_TRANSACTION.TRANSACTION_INTERVAL := 'Hour';
 				v_TRANSACTION.CONTRACT_ID := v_CONTRACT_ID;
 				v_TRANSACTION.IS_IMPORT_EXPORT := p_IS_IMPORT_EXPORT;
				v_TRANSACTION.IS_FIRM := p_IS_FIRM;
				IF p_TXN_DESC IS NOT NULL THEN
                     v_TRANSACTION.TRANSACTION_DESC := p_TXN_DESC;
                ELSE
                    v_TRANSACTION.TRANSACTION_DESC := 'Created by MarketManager on ' || UT.TRACE_DATE(SYSDATE) || ' by EMKT.';
                END IF;
 				v_TRANSACTION.TRANSACTION_IDENTIFIER := p_PNODE_IDENT;
				v_TRANSACTION.TRANSACTION_TYPE := p_TRANSACTION_TYPE;
                v_TRANSACTION.RESOURCE_ID := NVL(v_RESOURCE.RESOURCE_ID,0);

				MM_UTIL.PUT_TRANSACTION(p_TRANSACTION_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');

				IF p_TRANSACTION_TYPE = 'Generation' AND p_COMMODITY_NAME <> MM_PJM_UTIL.g_COMM_VIRTUAL THEN
					ID.ID_FOR_ENTITY_ATTRIBUTE('PJM_GEN_TXN_TYPE', 'Transaction', 'String', TRUE, v_PJM_GEN_TXN_ATTRIBUTE_ID);
					SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(p_TRANSACTION_ID, v_PJM_GEN_TXN_ATTRIBUTE_ID, SYSDATE, NULL, p_PJM_GEN_TXN_TYPE, p_TRANSACTION_ID, v_PJM_GEN_TXN_ATTRIBUTE_ID, NULL, v_STATUS);
				END IF;

			END IF;

	END;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Transaction found or created: ID=' || TO_CHAR(p_TRANSACTION_ID) || ' error=' || NVL(p_ERROR_MESSAGE,'NONE'));
	END IF;

END GET_TRANSACTION_ID;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_RESULTS
	(
	p_TRANSACTION_ID IN NUMBER,
	p_SCHEDULE_DATE  IN DATE,
	p_SCHEDULE_STATE IN NUMBER,
	p_PRICE IN NUMBER,
	p_AMOUNT IN NUMBER,
	p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE  OUT VARCHAR2
	) AS

	v_AS_OF_DATE DATE := LOW_DATE; --ASSUME WE ARE NOT VERSIONING.
	I BINARY_INTEGER;
BEGIN

	p_STATUS := GA.SUCCESS;

	FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
		UPDATE IT_SCHEDULE
			 SET AMOUNT = NVL(p_AMOUNT, AMOUNT), PRICE = NVL(p_PRICE, PRICE)
			 WHERE TRANSACTION_ID = p_TRANSACTION_ID
				 AND SCHEDULE_TYPE = MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(I)
				 AND SCHEDULE_STATE = p_SCHEDULE_STATE
				 AND SCHEDULE_DATE = p_SCHEDULE_DATE
				 AND AS_OF_DATE = v_AS_OF_DATE;
		IF SQL%NOTFOUND THEN
			INSERT INTO IT_SCHEDULE
				(
				TRANSACTION_ID,
				SCHEDULE_TYPE,
				SCHEDULE_STATE,
				SCHEDULE_DATE,
				AS_OF_DATE,
				AMOUNT,
				PRICE
				)
			VALUES
				(
				p_TRANSACTION_ID,
				MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(I),
				p_SCHEDULE_STATE,
				p_SCHEDULE_DATE,
				v_AS_OF_DATE,
				p_AMOUNT,
				p_PRICE
				);
		END IF;
	END LOOP;

END PUT_MARKET_RESULTS;
-------------------------------------------------------------------------------------
FUNCTION GET_IT_TRAIT_SCHEDULE
	(
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRANSACTION_ID IN NUMBER,
	p_SCHEDULE_STATE IN NUMBER,
	p_SCHEDULE_DATE IN DATE,
	p_TRAIT_INDEX IN NUMBER := 1,
	p_SET_NUMBER IN NUMBER := 1,
	p_CONVERT_TO_BOOL IN BOOLEAN := FALSE
	) RETURN VARCHAR2 IS

	v_TRAIT_VAL IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE := NULL;
	v_SCHEDULE_DATE DATE;
	v_TRAIT_INTERVAL VARCHAR2(16);
BEGIN

	SELECT TRAIT_GROUP_INTERVAL
	INTO v_TRAIT_INTERVAL
	FROM TRANSACTION_TRAIT_GROUP
	WHERE TRAIT_GROUP_ID = p_TRAIT_GROUP_ID;

	v_SCHEDULE_DATE := CASE WHEN v_TRAIT_INTERVAL = 'Day' THEN TRUNC(p_SCHEDULE_DATE) + 1/86400 ELSE p_SCHEDULE_DATE END;

	BEGIN
		SELECT ITS.TRAIT_VAL INTO v_TRAIT_VAL
		FROM IT_TRAIT_SCHEDULE ITS
		WHERE ITS.TRANSACTION_ID = p_TRANSACTION_ID
			AND ITS.SCHEDULE_STATE = p_SCHEDULE_STATE
			AND ITS.SCHEDULE_DATE = v_SCHEDULE_DATE
			AND ITS.TRAIT_GROUP_ID = p_TRAIT_GROUP_ID
			AND ITS.TRAIT_INDEX = p_TRAIT_INDEX
			AND ITS.SET_NUMBER = p_SET_NUMBER
			AND ITS.STATEMENT_TYPE_ID = 0;
	EXCEPTION WHEN NO_DATA_FOUND THEN
		v_TRAIT_VAL := NULL;
	END;

	IF p_CONVERT_TO_BOOL THEN
		IF v_TRAIT_VAL = 0 OR v_TRAIT_VAL IS NULL THEN
			v_TRAIT_VAL := 'false';
		ELSE
			v_TRAIT_VAL := 'true';
		END IF;
	END IF;

	RETURN v_TRAIT_VAL;
END GET_IT_TRAIT_SCHEDULE;
 --------------------------------------------------------------------
FUNCTION GET_GEN_PORTFOLIO_NAME
	(
	p_ISO_ACCOUNT_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS
	v_CONTRACT_ID NUMBER(9);
	v_PORTFOLIO_NAME VARCHAR2(64);
BEGIN
-- Returns the proper Gen Portfolio for the given ISO account, or "ALL" if none is specified.
	v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCOUNT_NAME);

	SELECT CASE ATTRIBUTE_VAL WHEN '?' THEN 'ALL' ELSE NVL(ATTRIBUTE_VAL, 'ALL') END
	INTO v_PORTFOLIO_NAME
	FROM TEMPORAL_ENTITY_ATTRIBUTE
	WHERE OWNER_ENTITY_ID = v_CONTRACT_ID
		AND ATTRIBUTE_ID = g_EMKT_GEN_PORTFOLIO_ATTR;

	RETURN v_PORTFOLIO_NAME;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 'ALL';
END GET_GEN_PORTFOLIO_NAME;
 --------------------------------------------------------------------
BEGIN
  ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMKT Gen', 'INTERCHANGE_CONTRACT', 'String', TRUE, g_EMKT_GEN_ATTR);
  ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMKT Load', 'INTERCHANGE_CONTRACT', 'String', TRUE, g_EMKT_LOAD_ATTR);
  ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMKT Gen Portfolio', 'INTERCHANGE_CONTRACT', 'String', TRUE, g_EMKT_GEN_PORTFOLIO_ATTR);
END MM_PJM_EMKT_UTIL;
/
