CREATE OR REPLACE PACKAGE BODY MM_MISO_SETTLEMENT AS

---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '09112003.1';
END WHAT_VERSION;
-------------------------------------------------------------------------------------
FUNCTION ID_FOR_MISO_COMPONENT
	(
	p_CHARGE_TYPE_NAME IN VARCHAR2,
    p_CHARGE_TYPE_CODE IN VARCHAR2
	) RETURN NUMBER IS
v_COMPONENT_ID NUMBER(9);
BEGIN
  	SELECT COMPONENT_ID
      INTO v_COMPONENT_ID
      FROM COMPONENT
      WHERE UPPER(EXTERNAL_IDENTIFIER) = UPPER(p_CHARGE_TYPE_CODE);
	RETURN v_COMPONENT_ID;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
    	-- finally, create if not found
		SELECT OID.NEXTVAL INTO v_COMPONENT_ID FROM DUAL;
        INSERT INTO COMPONENT (COMPONENT_ID,
        	COMPONENT_NAME, COMPONENT_ALIAS, COMPONENT_DESC,
            EXTERNAL_IDENTIFIER,
            COMPONENT_ENTITY, MODEL_ID, RATE_STRUCTURE, CHARGE_TYPE,
            ENTRY_DATE)
		VALUES (
        	v_COMPONENT_ID,
            'MISO '||p_CHARGE_TYPE_CODE,
            p_CHARGE_TYPE_CODE,
            p_CHARGE_TYPE_CODE,
            p_CHARGE_TYPE_CODE,
            'PSE',
            1,
			'External', 'MISO', -- default for unknown charge
            SYSDATE
        );
		RETURN v_COMPONENT_ID;
--	    RETURN GA.NO_DATA_FOUND;
	WHEN OTHERS THEN
		RAISE;
END ID_FOR_MISO_COMPONENT;
---------------------------------------------------------------------------------------------------
FUNCTION ID_FOR_MISO_PRODUCT
	(
	p_ASSET_OWNER_NAME IN VARCHAR2,
	p_MARKET_ABBR IN VARCHAR2
	) RETURN NUMBER IS
v_PRODUCT_ID NUMBER(9);
BEGIN

	SELECT PRODUCT_ID
	INTO v_PRODUCT_ID
	FROM PRODUCT
	WHERE UPPER(PRODUCT_EXTERNAL_IDENTIFIER) =  UPPER(p_ASSET_OWNER_NAME || ' ' || p_MARKET_ABBR);

	RETURN v_PRODUCT_ID;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
    	-- create if not found
		SELECT OID.NEXTVAL INTO v_PRODUCT_ID FROM DUAL;
        INSERT INTO PRODUCT (PRODUCT_ID,
        	PRODUCT_NAME, PRODUCT_ALIAS, PRODUCT_DESC,
            PRODUCT_EXTERNAL_IDENTIFIER,
            BEGIN_DATE, END_DATE, PRODUCT_CATEGORY,
            ENTRY_DATE)
		VALUES (
        	v_PRODUCT_ID,
            'MISO '||p_ASSET_OWNER_NAME|| ' ' ||p_MARKET_ABBR,
            p_ASSET_OWNER_NAME|| ' ' ||p_MARKET_ABBR,
            p_ASSET_OWNER_NAME|| ' ' ||p_MARKET_ABBR,
            p_ASSET_OWNER_NAME|| ' ' ||p_MARKET_ABBR,
            TO_DATE('01-JAN-2004','DD-MON-YYYY'),
            TRUNC(ADD_MONTHS(SYSDATE,12*20),'MM'), -- out 20 years
            'Normal',
            SYSDATE
        );
		RETURN v_PRODUCT_ID;
--	    RETURN GA.NO_DATA_FOUND;
	WHEN OTHERS THEN
		RAISE;
END ID_FOR_MISO_PRODUCT;
---------------------------------------------------------------------------------------------------
FUNCTION ID_FOR_MISO_CONTRACT
	(
	p_ISO_SOURCE IN VARCHAR2
	) RETURN NUMBER AS
v_ID NUMBER;
BEGIN
	SELECT CONTRACT_ID
	INTO v_ID
	FROM INTERCHANGE_CONTRACT A
	WHERE A.CONTRACT_ALIAS = p_ISO_SOURCE AND ROWNUM = 1;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ID.ID_FOR_INTERCHANGE_CONTRACT('MISO', v_ID);
		RETURN v_ID;
END ID_FOR_MISO_CONTRACT;
---------------------------------------------------------------------------------------------------
FUNCTION ID_FOR_MISO_MP
	(
	p_ISO_SOURCE IN VARCHAR2
	) RETURN NUMBER AS
v_CONTRACT_ID NUMBER;
v_ID NUMBER;
BEGIN
	v_CONTRACT_ID := ID_FOR_MISO_CONTRACT(p_ISO_SOURCE);
	SELECT PSE_ID
	INTO v_ID
	FROM INTERCHANGE_CONTRACT A,
		PURCHASING_SELLING_ENTITY B
	WHERE A.CONTRACT_ID = v_CONTRACT_ID
		AND B.PSE_ID = A.BILLING_ENTITY_ID
		AND ROWNUM = 1;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN ID.ID_FOR_PSE_EXTERNAL_IDENTIFIER('MISO');
END ID_FOR_MISO_MP;
---------------------------------------------------------------------------------------------------
FUNCTION GET_SP_ID
	(
    p_SERVICE_POINT_ID IN NUMBER,
    p_SERVICE_POINT_XID IN VARCHAR2
    ) RETURN NUMBER IS
v_SP_ID NUMBER;
BEGIN
	-- if input isn't valid ID, then create a new service point
    IF NVL(p_SERVICE_POINT_ID,0) = 0 THEN
    	IF p_SERVICE_POINT_XID IS NULL THEN
        	v_SP_ID := 0;
		ELSE
			-- even though we have an invalid ID, try again in case this service point
			-- was already created during processing
			SELECT MAX(SERVICE_POINT_ID) INTO v_SP_ID
			FROM SERVICE_POINT
			WHERE EXTERNAL_IDENTIFIER = p_SERVICE_POINT_XID;

			IF v_SP_ID IS NULL THEN
		    	IO.PUT_SERVICE_POINT(v_SP_ID,p_SERVICE_POINT_XID,p_SERVICE_POINT_XID,p_SERVICE_POINT_XID,0,'Retail',0,0,0,0,0,0,0,'CST',NULL,NULL,p_SERVICE_POINT_XID,0,NULL,NULL,NULL,NULL);
			END IF;
		END IF;
    ELSE
	    v_SP_ID := p_SERVICE_POINT_ID;
    END IF;
    RETURN v_SP_ID;
END GET_SP_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_TX_ID
  (
  p_EXT_ID IN VARCHAR2,
  p_TRANS_TYPE IN VARCHAR2 := 'Market Result',
  p_NAME IN VARCHAR2 := NULL,
  p_INTERVAL IN VARCHAR2 := 'Hour',
  p_CONTRACT_ID IN NUMBER := 0,
  p_SERVICE_POINT_ID IN NUMBER := 0,
  p_POOL_ID IN NUMBER := 0,
  p_SELLER_ID IN NUMBER := 0
  ) RETURN NUMBER IS

  v_ID NUMBER;
  v_SC NUMBER(9);
  v_SUFFIX VARCHAR2(32) := '';
  v_TMP VARCHAR2(32);
  v_NAME VARCHAR2(64);

BEGIN
	IF p_EXT_ID IS NULL THEN
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_TYPE = p_TRANS_TYPE
            AND CONTRACT_ID = p_CONTRACT_ID
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID);
	ELSE
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_IDENTIFIER = p_EXT_ID
            AND (p_CONTRACT_ID = 0 OR CONTRACT_ID = p_CONTRACT_ID)
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID);
	END IF;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_NAME := NVL(p_NAME,p_EXT_ID);

        SELECT SC_ID
        INTO v_SC
        FROM SCHEDULE_COORDINATOR
        WHERE SC_NAME = 'MISO';

        IF p_SELLER_ID <> 0 THEN
    	    SELECT ': '||PSE_NAME
	        INTO v_TMP
	        FROM PURCHASING_SELLING_ENTITY
	        WHERE PSE_ID = p_SELLER_ID;
			v_SUFFIX := v_SUFFIX||v_TMP;
        END IF;
        IF p_POOL_ID <> 0 THEN
    	    SELECT ': '||POOL_NAME
	        INTO v_TMP
	        FROM POOL
	        WHERE POOL_ID = p_POOL_ID;
			v_SUFFIX := v_SUFFIX||v_TMP;
        END IF;
        IF p_SERVICE_POINT_ID <> 0 THEN
    	    SELECT ': '||SERVICE_POINT_NAME
	        INTO v_TMP
	        FROM SERVICE_POINT
	        WHERE SERVICE_POINT_ID = p_SERVICE_POINT_ID;
			v_SUFFIX := v_SUFFIX||v_TMP;
        END IF;

    	--create the transaction
    	EM.PUT_TRANSACTION(
            v_ID,					-- o_oid
            v_NAME||v_SUFFIX,		-- p_transaction_name
            SUBSTR(v_NAME||v_SUFFIX,1,32),  		-- p_transaction_alias
            v_NAME||v_SUFFIX,  	 	-- p_transaction_desc
            0,						-- p_transaction_id
			'Active',				-- p_transaction_Status
            p_TRANS_TYPE,			-- p_transaction_type
            p_EXT_ID,				-- p_transaction_identifier
            0,						-- p_is_firm
            0,						-- p_is_import_schedule
            0,						-- p_is_export_schedule
            0,						-- p_is_balance_transaction
            0,						-- p_is_bid_offer
            0,						-- p_is_exclude_from_position
            0,						-- p_is_import_export
            0,						-- p_is_dispatchable
            p_INTERVAL,				-- p_transaction_interval
            NULL,					-- p_external_interval
            NULL,					-- p_etag_code
            TO_DATE('1/1/2000','MM/DD/YYYY'),-- p_begin_date
            TO_DATE('12/31/2020','MM/DD/YYYY'),-- p_end_date
            0,						-- p_purchaser_id
            p_SELLER_ID,			-- p_seller_id
            p_CONTRACT_ID,			-- p_contract_id
            v_SC, 					-- p_sc_id
            0,						-- p_por_id
            p_SERVICE_POINT_ID,		-- p_pod_id
            0,						-- p_commodity_id
            0,						-- p_service_type_id
            0,						-- p_tx_transaction_id
            0,						-- p_path_id
            0,						-- p_link_transaction_id
            0,						-- p_edc_id
            0,						-- p_pse_id
            0,						-- p_esp_id
            p_POOL_ID,				-- p_pool_id
            0,						-- p_schedule_group_id
            0,						-- p_market_price_id
            0,						-- p_zor_id
            0,						-- p_zod_id
            0,						-- p_source_id
            0,						-- p_sink_id
            0,						-- p_resource_id
            NULL,					-- p_agreement_type
            NULL,					-- p_approval_type
            NULL,					-- p_loss_option
            NULL,					-- p_trait_category
            0						-- p_tp_id
            );
		RETURN v_ID;
END GET_TX_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_PRICE_ID
  (
  p_EXTERNAL_IDENTIFIER IN VARCHAR2,
  p_NAME IN VARCHAR2 := NULL,
  p_INTERVAL IN VARCHAR2 := 'Hour',
  p_PRICE_TYPE IN VARCHAR2 := 'User Defined'
  ) RETURN NUMBER IS

  v_ID NUMBER;
  v_SC NUMBER(9);
  v_NAME VARCHAR2(32);

BEGIN

    SELECT MARKET_PRICE_ID
    INTO v_ID
    FROM MARKET_PRICE
    WHERE EXTERNAL_IDENTIFIER = p_EXTERNAL_IDENTIFIER;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
        SELECT SC_ID
        INTO v_SC
        FROM SCHEDULE_COORDINATOR
        WHERE SC_NAME = 'MISO';

		v_NAME := NVL(p_NAME,p_EXTERNAL_IDENTIFIER);

    	--create the transaction
    	IO.PUT_MARKET_PRICE(
			v_ID,			-- o_oid
			v_NAME,			-- p_market_price_name
			v_NAME,			-- p_market_price_alias
			v_NAME,			-- p_market_price_desc
			0,				-- p_market_price_id
			p_PRICE_TYPE,	-- p_market_price_type
			p_INTERVAL,		-- p_market_price_interval
			NULL,			-- p_market_type
			0,				-- p_commodity_id
			NULL,			-- p_service_point_type
			p_EXTERNAL_IDENTIFIER,		-- p_external_identifier
			0,				-- p_edc_id
			v_SC,			-- p_sc_id
			0,				-- p_pod_id
			0				-- p_zod_id
			);
		RETURN v_ID;
END GET_PRICE_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_POOL_ID
	(
	p_EXT_ID IN VARCHAR2,
	p_NAME IN VARCHAR2 := NULL
	) RETURN NUMBER IS

  v_ID NUMBER;
  v_NAME VARCHAR2(32);

BEGIN

    SELECT POOL_ID
    INTO v_ID
    FROM POOL
    WHERE POOL_EXTERNAL_IDENTIFIER = p_EXT_ID;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_NAME := NVL(p_NAME,p_EXT_ID);

    	--create the transaction
    	IO.PUT_POOL(
			v_ID, 			--o_oid
			v_NAME,			--p_pool_name
			v_NAME,			--p_pool_alias
			v_NAME,			--p_pool_desc
			0,				--p_pool_id
			p_EXT_ID,		--p_pool_external_identifier
			'Active',		--p_pool_status
			NULL,			--p_pool_category
			0				--p_pool_exclude_load_schedule
			);
		RETURN v_ID;
END GET_POOL_ID;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULE_VALUE
  (
  p_TX_ID IN NUMBER,
  p_SCHED_DATE IN DATE,
  p_AMOUNT IN NUMBER,
  p_SCHED_TYPE IN NUMBER,
  p_PRICE NUMBER := NULL,
  p_TO_INTERNAL BOOLEAN := TRUE
  ) AS

  v_STATUS NUMBER;

  BEGIN

	IF p_TO_INTERNAL THEN
		ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                           p_SCHEDULE_TYPE => p_SCHED_TYPE,
                           p_SCHEDULE_STATE => 1,
                           p_SCHEDULE_DATE => p_SCHED_DATE,
                           p_AS_OF_DATE => SYSDATE,
                           p_AMOUNT => p_AMOUNT,
                           p_PRICE => p_PRICE,
                           p_STATUS => v_STATUS);
	END IF;
    ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                       p_SCHEDULE_TYPE => p_SCHED_TYPE,
                       p_SCHEDULE_STATE => 2,
                       p_SCHEDULE_DATE => p_SCHED_DATE,
                       p_AS_OF_DATE => SYSDATE,
                       p_AMOUNT => p_AMOUNT,
                       p_PRICE => p_PRICE,
                       p_STATUS => v_STATUS);


  END PUT_SCHEDULE_VALUE;
---------------------------------------------------------------------------------------------------

PROCEDURE PUT_MARKET_PRICE_VALUE(p_PRICE_ID IN NUMBER,
								 p_PRICE_CODE IN CHAR,
								 p_PRICE_DATE IN DATE,
								 p_PRICE IN NUMBER) AS
BEGIN
	MERGE INTO MARKET_PRICE_VALUE M
	USING (SELECT p_PRICE_ID MARKET_PRICE_ID,
				  p_PRICE_CODE PRICE_CODE,
				  p_PRICE_DATE PRICE_DATE,
				  DATE '1900-01-01' AS_OF_DATE,
				  p_PRICE PRICE
		   FROM DUAL) A
	ON (A.MARKET_PRICE_ID = M.MARKET_PRICE_ID AND A.PRICE_CODE = M.PRICE_CODE AND A.PRICE_DATE = M.PRICE_DATE AND A.AS_OF_DATE = M.AS_OF_DATE)
	WHEN MATCHED THEN
		UPDATE SET M.PRICE = p_PRICE
	WHEN NOT MATCHED THEN
		INSERT
			(MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
		VALUES
			(p_PRICE_ID, p_PRICE_CODE, p_PRICE_DATE, DATE '1900-01-01', NULL, p_PRICE);
END PUT_MARKET_PRICE_VALUE;
-------------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_MARKET_PRICE
	(p_MARKET_PRICE_TYPE IN VARCHAR2,
    p_MKT_TYPE IN VARCHAR2,
    p_MKT_TY_ABBR IN VARCHAR2,
    p_POD_ID IN NUMBER,
    p_POD_NAME IN VARCHAR2,
    p_PRICE_DATE IN DATE,
    p_PRICE IN NUMBER
    ) AS
v_MARKET_PRICE_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_EXTERNAL_IDENTIFIER MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
v_MKT_PRICE_TYPE_ABBR VARCHAR2(3);
BEGIN
 	BEGIN
        SELECT MARKET_PRICE_ID INTO v_MARKET_PRICE_ID
        FROM MARKET_PRICE
        WHERE MARKET_PRICE_TYPE = p_MARKET_PRICE_TYPE
        AND MARKET_TYPE = p_MKT_TYPE
        AND POD_ID = p_POD_ID
        AND MARKET_PRICE_INTERVAL = 'Hour';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
		CASE UPPER(p_MARKET_PRICE_TYPE)
			WHEN 'LOCATIONAL MARGINAL PRICE' THEN v_MKT_PRICE_TYPE_ABBR := 'LMP';
			WHEN 'MARGINAL CONGESTION COMPONENT' THEN v_MKT_PRICE_TYPE_ABBR := 'MCC';
			WHEN 'MARGINAL LOSS COMPONENT' THEN v_MKT_PRICE_TYPE_ABBR := 'MLC';
		END CASE;
		--create the market price
		v_EXTERNAL_IDENTIFIER := 'MISO:' || p_POD_NAME || ':' || v_MKT_PRICE_TYPE_ABBR || ':' || p_MKT_TY_ABBR;
		IO.PUT_MARKET_PRICE(v_MARKET_PRICE_ID,
							v_EXTERNAL_IDENTIFIER,
    						v_EXTERNAL_IDENTIFIER, -- ALIAS
							v_EXTERNAL_IDENTIFIER,
                        	0,
                            p_MARKET_PRICE_TYPE, -- MARKET_PRICE_TYPE
        					'Hour',  --MARKET_PRICE_INTERVAL
        					p_MKT_TYPE, --MARKET_TYPE
        					0,  -- COMMODITY_ID
        					'Point', -- SERVICE_POINT_TYPE
        					v_EXTERNAL_IDENTIFIER, -- EXTERNAL_IDENTIFIER
        					0, -- EDC_ID
        					MM_MISO_UTIL.GET_MISO_SC_ID, --SC_ID
        					p_POD_ID, -- POD_ID
        					0 -- ZOD_ID
         					);
	END;

    PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, 'A', p_PRICE_DATE, p_PRICE);

END UPDATE_MARKET_PRICE;

-------------------------------------------------------------------------------------------------------
PROCEDURE GET_MULTIPLE_VALUES_FOR_HOUR
	(
	p_IS_EXP_IMP IN NUMBER,
    p_DET_TYP1 IN VARCHAR2,
    p_DET_TYP2 IN IDENT_TABLE,
    p_NODE_ID IN VARCHAR2,
    p_CHARGE_HOUR IN NUMBER,
    p_WORK_ID IN NUMBER,
    p_AMT_L OUT NUMBER,
    p_AMT_G OUT NUMBER,
    p_AMT_P OUT NUMBER,
    p_AMT_S OUT NUMBER
    ) AS
v_DET_TYPE VARCHAR2(16);
BEGIN
	IF p_IS_EXP_IMP = 1 THEN
		v_DET_TYPE := g_AO_INTERVAL_DET;
	ELSE
		v_DET_TYPE := g_ASSET_INTERVAL_DET;
	END IF;

	-- extract the values for these determinant types, node, and hour
    SELECT NVL(SUM(CASE
    	    WHEN DET_TYP_ID = p_DET_TYP1 AND
					( (p_IS_EXP_IMP <> 1 AND VAL > 0) OR
				  	  (p_IS_EXP_IMP = 1 AND SNK_ND_ID IS NOT NULL) ) THEN
				VAL
    		ELSE
            	0
    		END), 0), -- "Load" or "Exports"
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID = p_DET_TYP1 AND
					( (p_IS_EXP_IMP <> 1 AND VAL < 0) OR
				  	  (p_IS_EXP_IMP = 1 AND SRC_ND_ID IS NOT NULL) ) THEN
				-- this expression means that we return +VAL if p_IS_EXP_IMP = 1 but -VAL if p_IS_EXP_IMP = 0
            	(p_IS_EXP_IMP*(2)-1)*VAL
    		ELSE
            	0
    		END), 0), -- "Generation" or "Imports"
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(p_DET_TYP2 AS IDENT_TABLE))) AND SNK_ND_ID IS NOT NULL THEN
            	VAL
    		ELSE
            	0
    		END), 0), -- "Purchases"
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(p_DET_TYP2 AS IDENT_TABLE))) AND SRC_ND_ID IS NOT NULL THEN
            	VAL
    		ELSE
            	0
    		END), 0) -- "Sales"
	INTO p_AMT_L, p_AMT_G, p_AMT_P, p_AMT_S
    FROM MISO_DET_WORK
	WHERE WORK_ID = p_WORK_ID
		AND DET_TYPE = v_DET_TYPE
		AND ((DET_TYP_ID = p_DET_TYP1
			AND ((p_IS_EXP_IMP <> 1 AND DP_ND_ID = p_NODE_ID)
				OR (p_IS_EXP_IMP = 1 AND NVL(SRC_ND_ID, SNK_ND_ID) = p_NODE_ID)))
			OR (DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(p_DET_TYP2 AS IDENT_TABLE)))
				AND NVL(SRC_ND_ID, SNK_ND_ID) = p_NODE_ID))
		AND INT_NUM = p_CHARGE_HOUR;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
    	p_AMT_L := NULL;
    	p_AMT_G := NULL;
    	p_AMT_P := NULL;
    	p_AMT_S := NULL;
END GET_MULTIPLE_VALUES_FOR_HOUR;
---------------------------------------------------------------------------------------------------
FUNCTION GET_VALUE_FOR_HOUR
	(
    p_DET_TYP_ID IN VARCHAR2,
    p_SRC_ND_ID IN VARCHAR2,
    p_SNK_ND_ID IN VARCHAR2,
    p_DP_ND_ID IN VARCHAR2,
    p_CHARGE_HOUR IN NUMBER,
    p_WORK_ID IN NUMBER,
	p_DET_TYPE IN VARCHAR2 := g_MKT_INTERVAL_DET,
	p_SUM IN BOOLEAN := FALSE
    ) RETURN NUMBER IS
v_RET_SUM NUMBER;
v_RET_AVG NUMBER;
BEGIN
	-- extract the value for this determinant type, node(s), and hour
	SELECT SUM(VAL), AVG(VAL)
	INTO v_RET_SUM, v_RET_AVG
	FROM MISO_DET_WORK
	WHERE WORK_ID = p_WORK_ID
		AND DET_TYPE LIKE p_DET_TYPE
		AND DET_TYP_ID = p_DET_TYP_ID
		AND NVL(SRC_ND_ID,'?') LIKE NVL(p_SRC_ND_ID,'%')
		AND NVL(SNK_ND_ID,'?') LIKE NVL(p_SNK_ND_ID,'%')
		AND NVL(DP_ND_ID,'?') LIKE NVL(p_DP_ND_ID,'%')
		AND INT_NUM = p_CHARGE_HOUR;

	IF p_SUM THEN
		RETURN v_RET_SUM;
	ELSE
		RETURN v_RET_AVG;
	END IF;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
    	RETURN NULL;
END GET_VALUE_FOR_HOUR;
---------------------------------------------------------------------------------------------------
FUNCTION GET_VALUE_FOR_HOUR
	(
    p_DET_TYP_IDENTS IN IDENT_TABLE,
    p_SRC_ND_ID IN VARCHAR2,
    p_SNK_ND_ID IN VARCHAR2,
    p_DP_ND_ID IN VARCHAR2,
    p_CHARGE_HOUR IN NUMBER,
    p_WORK_ID IN NUMBER,
	p_DET_TYPE IN VARCHAR2 := g_MKT_INTERVAL_DET,
	p_SUM IN BOOLEAN := FALSE
    ) RETURN NUMBER IS
v_RET_SUM NUMBER;
v_RET_AVG NUMBER;
BEGIN
	-- extract the value for this determinant type, node(s), and hour
	SELECT SUM(VAL), AVG(VAL)
	INTO v_RET_SUM, v_RET_AVG
	FROM MISO_DET_WORK
	WHERE WORK_ID = p_WORK_ID
		AND DET_TYPE LIKE p_DET_TYPE
		AND DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(p_DET_TYP_IDENTS AS IDENT_TABLE)))
		AND NVL(SRC_ND_ID,'?') LIKE NVL(p_SRC_ND_ID,'%')
		AND NVL(SNK_ND_ID,'?') LIKE NVL(p_SNK_ND_ID,'%')
		AND NVL(DP_ND_ID,'?') LIKE NVL(p_DP_ND_ID,'%')
		AND INT_NUM = p_CHARGE_HOUR;

	IF p_SUM THEN
		RETURN v_RET_SUM;
	ELSE
		RETURN v_RET_AVG;
	END IF;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
    	RETURN NULL;
END GET_VALUE_FOR_HOUR;
---------------------------------------------------------------------------------------------------
 FUNCTION GET_DET_TYP_IDENTS(p_MARKET_TYPE IN VARCHAR2) RETURN IDENT_TABLE IS
 	v_RET IDENT_TABLE;
 BEGIN
 	v_RET := IDENT_TABLE();
	IF p_MARKET_TYPE = '?' THEN
    	v_RET.EXTEND;
		v_RET(v_RET.LAST) := ident_type(NULL, p_MARKET_TYPE);
	ELSE
    	v_RET.EXTEND;
    	v_RET(v_RET.LAST) := ident_type(NULL, p_MARKET_TYPE || '_FIN');
    	v_RET.EXTEND;
    	v_RET(v_RET.LAST) := ident_type(NULL, p_MARKET_TYPE || '_GFACO');
    	v_RET.EXTEND;
    	v_RET(v_RET.LAST) := ident_type(NULL, p_MARKET_TYPE || '_GFAOB');
	END IF;
	RETURN v_RET;
 END;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_BILAT_LMP_CHARGE
	(
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_IS_DAY_AHEAD IN NUMBER,
    p_PRICE_TYPE IN VARCHAR2,
    p_WORK_ID IN NUMBER
    ) AS
v_IS_PURCHASE BOOLEAN;
v_SRC_ND_ID VARCHAR2(64);
v_SNK_ND_ID VARCHAR2(64);
v_DP_ND_ID VARCHAR2(64);
v_ND_ID1 VARCHAR2(64);
v_ND_ID2 VARCHAR2(64);
v_PRICE_TYP_ID VARCHAR2(32);

v_DET_TYP_IDENTS IDENT_TABLE;
v_OTHER_TYP_IDENTS IDENT_TABLE;

v_LMP_CHARGE LMP_CHARGE%ROWTYPE;
v_AMT NUMBER;
v_OTHER_AMT NUMBER;
v_MKT_TP VARCHAR2(16);
v_MARKET_TYPE_ABBR VARCHAR2(2);
v_MARKET_PRICE_TYPE VARCHAR2(32);

-- gather the distinct combinations of sources, delivery points, and sinks
CURSOR c_NODES IS
 SELECT A.SRC_NODE, B.SERVICE_POINT_ID "SRC_ID",
 		A.DP_NODE, C.SERVICE_POINT_ID "DP_ID",
 		A.SNK_NODE, D.SERVICE_POINT_ID "SNK_ID"
 FROM (SELECT DISTINCT SRC_ND_ID "SRC_NODE",
 					DP_ND_ID "DP_NODE",
 					SNK_ND_ID "SNK_NODE"
		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE IN (g_AO_INTERVAL_DET, g_ASSET_INTERVAL_DET)
			AND DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(v_DET_TYP_IDENTS AS IDENT_TABLE)))) A, -- = v_DET_TYP_ID) A,
     SERVICE_POINT B,
     SERVICE_POINT C,
     SERVICE_POINT D
 WHERE B.EXTERNAL_IDENTIFIER(+) = A.SRC_NODE
 	AND C.EXTERNAL_IDENTIFIER(+) = A.DP_NODE
 	AND D.EXTERNAL_IDENTIFIER(+) = A.SNK_NODE;

-- gather schedule volumes
CURSOR c_SCHED(p_SRC_ND_ID IN VARCHAR2, p_SNK_ND_ID IN VARCHAR2, p_DP_ND_ID IN VARCHAR2) IS
 SELECT CHARGE_HOUR,
 	NVL(SUM(QUANTITY),0) "QUANTITY"
 FROM (SELECT INT_NUM "CHARGE_HOUR", VAL "QUANTITY"
 		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE IN (g_AO_INTERVAL_DET, g_ASSET_INTERVAL_DET)
			--AND DET_TYP_ID = v_DET_TYP_ID
			AND DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(v_DET_TYP_IDENTS AS IDENT_TABLE)))
			AND NVL(SRC_ND_ID,'?') LIKE NVL(p_SRC_ND_ID,'%')
			AND NVL(SNK_ND_ID,'?') LIKE NVL(p_SNK_ND_ID,'%')
			AND NVL(DP_ND_ID,'?') LIKE NVL(p_DP_ND_ID,'%'))
 GROUP BY CHARGE_HOUR
 ORDER BY 1;

BEGIN
	-- determine the determinant codes to use
	IF p_IS_DAY_AHEAD = 1 THEN
		v_DET_TYP_IDENTS := GET_DET_TYP_IDENTS('DA');
		v_OTHER_TYP_IDENTS := NULL;

        v_PRICE_TYP_ID := 'DA_LMP_'||p_PRICE_TYPE;
	ELSE
		v_DET_TYP_IDENTS := GET_DET_TYP_IDENTS('RT');
		v_OTHER_TYP_IDENTS := GET_DET_TYP_IDENTS('DA');

        v_PRICE_TYP_ID := 'RT_LMP_'||p_PRICE_TYPE;
	END IF;

    IF p_PRICE_TYPE = 'CG' THEN
    	v_MARKET_PRICE_TYPE := 'Marginal Congestion Component';
    ELSE --p_PRICE_TYPE = 'LS'
    	v_MARKET_PRICE_TYPE := 'Marginal Loss Component';
    END IF;

    v_LMP_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_LMP_CHARGE.CHARGE_FACTOR := 1.0;
    -- loop through distinct node pairs
    FOR v_NODE IN c_NODES LOOP
    	v_LMP_CHARGE.SOURCE_ID := GET_SP_ID(v_NODE.SRC_ID,v_NODE.SRC_NODE);
    	v_LMP_CHARGE.DELIVERY_POINT_ID := GET_SP_ID(v_NODE.DP_ID,v_NODE.DP_NODE);
    	v_LMP_CHARGE.SINK_ID := GET_SP_ID(v_NODE.SNK_ID,v_NODE.SNK_NODE);
        -- get parameters for gathering schedule volumes
        v_SRC_ND_ID := v_NODE.SRC_NODE;
        v_SNK_ND_ID := v_NODE.SNK_NODE;
        v_DP_ND_ID := v_NODE.DP_NODE;
        IF v_NODE.SNK_ID IS NULL THEN
        	v_IS_PURCHASE := FALSE;
			v_ND_ID1 := v_DP_ND_ID;
			v_ND_ID2 := v_SRC_ND_ID;
        ELSE
        	v_IS_PURCHASE := TRUE;
			v_ND_ID1 := v_SNK_ND_ID;
			v_ND_ID2 := v_DP_ND_ID;
        END IF;
        -- loop through schedule volumes
        FOR v_SCHED IN c_SCHED(v_SRC_ND_ID, v_SNK_ND_ID, v_DP_ND_ID) LOOP
        	v_LMP_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_SCHED.CHARGE_HOUR/24;
			v_AMT := v_SCHED.QUANTITY;
	       	-- put volumes in appropriate columns of table
			IF p_IS_DAY_AHEAD = 1 THEN
            	IF v_IS_PURCHASE THEN
                	v_LMP_CHARGE.DA_PURCHASES := v_AMT;
                    v_LMP_CHARGE.DA_SALES := NULL;
                ELSE
                	v_LMP_CHARGE.DA_SALES := v_AMT;
                    v_LMP_CHARGE.DA_PURCHASES := NULL;
                END IF;
	            v_LMP_CHARGE.CHARGE_QUANTITY := v_AMT;
            ELSE
              -- return a zero if it's null so the charge quantity arithmetic works
            	v_OTHER_AMT := NVL(GET_VALUE_FOR_HOUR(v_OTHER_TYP_IDENTS, v_SRC_ND_ID, v_SNK_ND_ID, v_DP_ND_ID, v_SCHED.CHARGE_HOUR, p_WORK_ID, g_AO_OR_ASSET, TRUE), 0);
            	IF v_IS_PURCHASE THEN
                	v_LMP_CHARGE.RT_PURCHASES := v_AMT;
                	v_LMP_CHARGE.DA_PURCHASES := v_OTHER_AMT;
                    v_LMP_CHARGE.RT_SALES := NULL;
                    v_LMP_CHARGE.DA_SALES := NULL;
                ELSE
                	v_LMP_CHARGE.RT_SALES := v_AMT;
                	v_LMP_CHARGE.DA_SALES := v_OTHER_AMT;
                    v_LMP_CHARGE.RT_PURCHASES := NULL;
                    v_LMP_CHARGE.DA_PURCHASES := NULL;
                END IF;
                v_LMP_CHARGE.CHARGE_QUANTITY := v_AMT-v_OTHER_AMT;
			END IF;
            -- don't bother storing empty records
            IF NVL(v_LMP_CHARGE.DA_PURCHASES,0) > 0 OR NVL(v_LMP_CHARGE.RT_PURCHASES,0) > 0 OR
               NVL(v_LMP_CHARGE.DA_SALES,0) > 0 OR NVL(v_LMP_CHARGE.RT_SALES,0) > 0 THEN
                -- then get market rates
                v_LMP_CHARGE.PRICE1 := GET_VALUE_FOR_HOUR(v_PRICE_TYP_ID, NULL, NULL, v_ND_ID1, v_SCHED.CHARGE_HOUR, p_WORK_ID);
                v_LMP_CHARGE.PRICE2 := GET_VALUE_FOR_HOUR(v_PRICE_TYP_ID, NULL, NULL, v_ND_ID2, v_SCHED.CHARGE_HOUR, p_WORK_ID);
                -- compute effective charge quantity, rate, and dollar charge amount
                v_LMP_CHARGE.CHARGE_RATE := v_LMP_CHARGE.PRICE1-v_LMP_CHARGE.PRICE2;
                v_LMP_CHARGE.CHARGE_AMOUNT := v_LMP_CHARGE.CHARGE_RATE*v_LMP_CHARGE.CHARGE_FACTOR*v_LMP_CHARGE.CHARGE_QUANTITY;
                -- get bill quantity and amount
    			PC.PRIOR_LMP_CHARGE(p_PRIOR_CHARGE_ID,v_LMP_CHARGE);
                -- store this record
                PC.PUT_LMP_CHARGE(v_LMP_CHARGE);

                 IF p_IS_DAY_AHEAD = 1 THEN
                	v_MKT_TP := 'DayAhead';
                    v_MARKET_TYPE_ABBR := 'DA';
                ELSE
                	v_MKT_TP := 'RealTime';
                    v_MARKET_TYPE_ABBR := 'RT';
                END IF;

                --update market price values
                IF v_IS_PURCHASE THEN
                	UPDATE_MARKET_PRICE(v_MARKET_PRICE_TYPE, v_MKT_TP, v_MARKET_TYPE_ABBR,
										v_LMP_CHARGE.SINK_ID, v_NODE.SNK_NODE,
               							v_LMP_CHARGE.CHARGE_DATE, v_LMP_CHARGE.PRICE1);
                	UPDATE_MARKET_PRICE(v_MARKET_PRICE_TYPE, v_MKT_TP, v_MARKET_TYPE_ABBR,
										v_LMP_CHARGE.DELIVERY_POINT_ID, v_NODE.DP_NODE,
               							v_LMP_CHARGE.CHARGE_DATE, v_LMP_CHARGE.PRICE2);
				ELSE
                   	UPDATE_MARKET_PRICE(v_MARKET_PRICE_TYPE, v_MKT_TP, v_MARKET_TYPE_ABBR,
										v_LMP_CHARGE.DELIVERY_POINT_ID, v_NODE.DP_NODE,
               							v_LMP_CHARGE.CHARGE_DATE, v_LMP_CHARGE.PRICE1);
                    UPDATE_MARKET_PRICE(v_MARKET_PRICE_TYPE, v_MKT_TP, v_MARKET_TYPE_ABBR,
										v_LMP_CHARGE.SOURCE_ID, v_NODE.SRC_NODE,
               							v_LMP_CHARGE.CHARGE_DATE, v_LMP_CHARGE.PRICE2);

                END IF;


			END IF;
        END LOOP;
    END LOOP;
END EXTRACT_BILAT_LMP_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_LMP_CHARGE
	(
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_IS_DAY_AHEAD IN NUMBER,
    p_IS_EXP_IMP IN NUMBER,
    p_IS_VIRTUAL IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS
v_DET_TYP_ID1 VARCHAR2(32);
v_OTHER_TYP_ID1 VARCHAR2(32);

v_DET_TYP_IDENTS2 IDENT_TABLE;
v_OTHER_TYP_IDENTS2 IDENT_TABLE;

v_PRICE_TYP_ID VARCHAR2(32);
v_LMP_CHARGE LMP_CHARGE%ROWTYPE;
v_AMT_L NUMBER;
v_AMT_G NUMBER;
v_AMT_P NUMBER;
v_AMT_S NUMBER;
v_OTHER_AMT_L NUMBER;
v_OTHER_AMT_G NUMBER;
v_OTHER_AMT_P NUMBER;
v_OTHER_AMT_S NUMBER;
v_DET_TYPE VARCHAR2(16);
v_MKT_TP VARCHAR2(16);
v_MARKET_TYPE_ABBR VARCHAR2(2);

-- gather the distinct delivery points
CURSOR c_NODES IS
 SELECT A.NODE, B.SERVICE_POINT_ID "NODE_ID"
 FROM (SELECT DISTINCT
 				CASE
				WHEN DET_TYP_ID = v_DET_TYP_ID1 AND p_IS_EXP_IMP <> 1 THEN
					DP_ND_ID
				ELSE
					NVL(SRC_ND_ID, SNK_ND_ID)
				END "NODE"
 		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE = v_DET_TYPE
			AND (DET_TYP_ID = v_DET_TYP_ID1 OR DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(v_DET_TYP_IDENTS2 AS IDENT_TABLE))))) A,
     SERVICE_POINT B
 WHERE B.EXTERNAL_IDENTIFIER(+) = A.NODE;

-- gather schedule volumes
CURSOR c_SCHED(p_ND_ID IN VARCHAR2) IS
    SELECT INT_NUM "CHARGE_HOUR",
		NVL(SUM(CASE
    	    WHEN DET_TYP_ID = v_DET_TYP_ID1 AND
					( (p_IS_EXP_IMP <> 1 AND VAL > 0) OR
				  	  (p_IS_EXP_IMP = 1 AND SNK_ND_ID IS NOT NULL) ) THEN
				VAL
    		ELSE
            	0
    		END), 0) "LOAD",
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID = v_DET_TYP_ID1 AND
					( (p_IS_EXP_IMP <> 1 AND VAL < 0) OR
				  	  (p_IS_EXP_IMP = 1 AND SRC_ND_ID IS NOT NULL) ) THEN
				-- this expression means that we return +VAL if p_IS_EXP_IMP = 1 but -VAL if p_IS_EXP_IMP = 0
            	(p_IS_EXP_IMP*(2)-1)*VAL
    		ELSE
            	0
    		END), 0) "GENERATION",
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(v_DET_TYP_IDENTS2 AS IDENT_TABLE))) AND SNK_ND_ID IS NOT NULL THEN
            	VAL
    		ELSE
            	0
    		END), 0) "PURCHASES",
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(v_DET_TYP_IDENTS2 AS IDENT_TABLE))) AND SRC_ND_ID IS NOT NULL THEN
            	VAL
    		ELSE
            	0
    		END), 0) "SALES"
    FROM MISO_DET_WORK
	WHERE WORK_ID = p_WORK_ID
		AND DET_TYPE = v_DET_TYPE
		AND ((DET_TYP_ID = v_DET_TYP_ID1
			AND ((p_IS_EXP_IMP <> 1 AND DP_ND_ID = p_ND_ID)
				OR (p_IS_EXP_IMP = 1 AND NVL(SRC_ND_ID, SNK_ND_ID) = p_ND_ID)))
			OR (DET_TYP_ID IN (SELECT IDENT_NAME FROM TABLE(CAST(v_DET_TYP_IDENTS2 AS IDENT_TABLE)))
				AND NVL(SRC_ND_ID, SNK_ND_ID) = p_ND_ID))
    GROUP BY INT_NUM
    ORDER BY 1;

BEGIN

	IF p_IS_EXP_IMP = 1 OR p_IS_VIRTUAL = 1 THEN
		v_DET_TYPE := g_AO_INTERVAL_DET;
	ELSE
		v_DET_TYPE := g_ASSET_INTERVAL_DET;
	END IF;

	-- determine the determinant codes to use
	IF p_IS_DAY_AHEAD = 1 THEN
        v_PRICE_TYP_ID := 'DA_LMP_EN';
    	IF p_IS_EXP_IMP = 1 THEN
            v_DET_TYP_ID1 := 'DA_PHYS';
            v_OTHER_TYP_ID1 := NULL;
            --v_DET_TYP_ID2 := 'DA_FIN';
            --v_OTHER_TYP_ID2 := NULL;
            v_DET_TYP_IDENTS2 := GET_DET_TYP_IDENTS('DA');
            v_OTHER_TYP_IDENTS2 := NULL;
        ELSIF p_IS_VIRTUAL = 1 THEN
            v_DET_TYP_ID1 := 'DA_VSCHD';
            v_OTHER_TYP_ID1 := NULL;
            --v_DET_TYP_ID2 := '?';
            --v_OTHER_TYP_ID2 := NULL;
            v_DET_TYP_IDENTS2 := GET_DET_TYP_IDENTS('?');
            v_OTHER_TYP_IDENTS2 := NULL;
		ELSE
            v_DET_TYP_ID1 := 'DA_SCHD';
            v_OTHER_TYP_ID1 := NULL;
            --v_DET_TYP_ID2 := 'DA_FIN';
            --v_OTHER_TYP_ID2 := NULL;
            v_DET_TYP_IDENTS2 := GET_DET_TYP_IDENTS('DA');
            v_OTHER_TYP_IDENTS2 := NULL;
        END IF;
	ELSE
        v_PRICE_TYP_ID := 'RT_LMP_EN';
    	IF p_IS_EXP_IMP = 1 THEN
            v_DET_TYP_ID1 := 'RT_PHYS';
            v_OTHER_TYP_ID1 := 'DA_PHYS';
            --v_DET_TYP_ID2 := 'RT_FIN';
            --v_OTHER_TYP_ID2 := 'DA_FIN';
            v_DET_TYP_IDENTS2 := GET_DET_TYP_IDENTS('RT');
            v_OTHER_TYP_IDENTS2 := GET_DET_TYP_IDENTS('DA');
        ELSIF p_IS_VIRTUAL = 1 THEN
            v_DET_TYP_ID1 := 'DA_VSCHD';
            v_OTHER_TYP_ID1 := NULL;
            --v_DET_TYP_ID2 := '?';
            --v_OTHER_TYP_ID2 := NULL;
            v_DET_TYP_IDENTS2 := GET_DET_TYP_IDENTS('?');
            v_OTHER_TYP_IDENTS2 := NULL;
		ELSE
            v_DET_TYP_ID1 := 'RT_BLL_MTR';
            v_OTHER_TYP_ID1 := 'DA_SCHD';
            --v_DET_TYP_ID2 := 'RT_FIN';
            --v_OTHER_TYP_ID2 := 'DA_FIN';
            v_DET_TYP_IDENTS2 := GET_DET_TYP_IDENTS('RT');
            v_OTHER_TYP_IDENTS2 := GET_DET_TYP_IDENTS('DA');
        END IF;
    END IF;

    v_LMP_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_LMP_CHARGE.CHARGE_FACTOR := 1.0;
    -- loop through distinct node pairs
    FOR v_NODE IN c_NODES LOOP
    	v_LMP_CHARGE.SOURCE_ID := 0;
    	v_LMP_CHARGE.DELIVERY_POINT_ID := GET_SP_ID(v_NODE.NODE_ID,v_NODE.NODE);
    	v_LMP_CHARGE.SINK_ID := 0;
        -- loop through schedule volumes
        FOR v_SCHED IN c_SCHED(v_NODE.NODE) LOOP
        	v_LMP_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_SCHED.CHARGE_HOUR/24;
			v_AMT_L := v_SCHED.LOAD;
			v_AMT_G := v_SCHED.GENERATION;
			v_AMT_P := v_SCHED.PURCHASES;
			v_AMT_S := v_SCHED.SALES;
	       	-- put volumes in appropriate columns of table
			IF p_IS_DAY_AHEAD = 1 THEN
            	v_LMP_CHARGE.DA_LOAD := v_AMT_L;
                v_LMP_CHARGE.DA_GENERATION := v_AMT_G;
                v_LMP_CHARGE.DA_PURCHASES := v_AMT_P;
                v_LMP_CHARGE.DA_SALES := v_AMT_S;
                v_LMP_CHARGE.CHARGE_QUANTITY := v_AMT_L-v_AMT_G-v_AMT_P+v_AMT_S;
      	    ELSIF p_IS_VIRTUAL = 1 THEN
            	v_LMP_CHARGE.DA_LOAD := v_AMT_L;
                v_LMP_CHARGE.DA_GENERATION := v_AMT_G;
                v_LMP_CHARGE.DA_PURCHASES := v_AMT_P;
                v_LMP_CHARGE.DA_SALES := v_AMT_S;
                v_LMP_CHARGE.CHARGE_QUANTITY := -(v_AMT_L-v_AMT_G-v_AMT_P+v_AMT_S);
            ELSE
            	GET_MULTIPLE_VALUES_FOR_HOUR(p_IS_EXP_IMP, v_OTHER_TYP_ID1, v_OTHER_TYP_IDENTS2, v_NODE.NODE, v_SCHED.CHARGE_HOUR, p_WORK_ID, v_OTHER_AMT_L, v_OTHER_AMT_G, v_OTHER_AMT_P, v_OTHER_AMT_S);
            	v_LMP_CHARGE.RT_LOAD := v_AMT_L;
                v_LMP_CHARGE.RT_GENERATION := v_AMT_G;
                v_LMP_CHARGE.RT_PURCHASES := v_AMT_P;
                v_LMP_CHARGE.RT_SALES := v_AMT_S;
            	v_LMP_CHARGE.DA_LOAD := v_OTHER_AMT_L;
                v_LMP_CHARGE.DA_GENERATION := v_OTHER_AMT_G;
                v_LMP_CHARGE.DA_PURCHASES := v_OTHER_AMT_P;
                v_LMP_CHARGE.DA_SALES := v_OTHER_AMT_S;
                v_LMP_CHARGE.CHARGE_QUANTITY := (v_AMT_L-v_OTHER_AMT_L)-(v_AMT_G-v_OTHER_AMT_G)-(v_AMT_P-v_OTHER_AMT_P)+(v_AMT_S-v_OTHER_AMT_S);
			END IF;
            -- don't bother storing empty records
            IF NVL(v_LMP_CHARGE.DA_LOAD,0) > 0 OR NVL(v_LMP_CHARGE.RT_LOAD,0) > 0 OR
               NVL(v_LMP_CHARGE.DA_GENERATION,0) > 0 OR NVL(v_LMP_CHARGE.RT_GENERATION,0) > 0 OR
               NVL(v_LMP_CHARGE.DA_PURCHASES,0) > 0 OR NVL(v_LMP_CHARGE.RT_PURCHASES,0) > 0 OR
               NVL(v_LMP_CHARGE.DA_SALES,0) > 0 OR NVL(v_LMP_CHARGE.RT_SALES,0) > 0 THEN
                -- then get market rates
                v_LMP_CHARGE.CHARGE_RATE := GET_VALUE_FOR_HOUR(v_PRICE_TYP_ID, NULL, NULL, v_NODE.NODE, v_SCHED.CHARGE_HOUR, p_WORK_ID);
                -- compute effective charge quantity and dollar charge amount
                v_LMP_CHARGE.CHARGE_AMOUNT := v_LMP_CHARGE.CHARGE_RATE*v_LMP_CHARGE.CHARGE_FACTOR*v_LMP_CHARGE.CHARGE_QUANTITY;
                -- get bill quantity and amount
    			PC.PRIOR_LMP_CHARGE(p_PRIOR_CHARGE_ID,v_LMP_CHARGE);
                -- store this record
                PC.PUT_LMP_CHARGE(v_LMP_CHARGE);

                IF p_IS_DAY_AHEAD = 1 THEN
                	v_MKT_TP := 'DayAhead';
                    v_MARKET_TYPE_ABBR := 'DA';
                ELSE
                	v_MKT_TP := 'RealTime';
                    v_MARKET_TYPE_ABBR := 'RT';
                END IF;

                --update maket price value
                UPDATE_MARKET_PRICE('Locational Marginal Price', v_MKT_TP, v_MARKET_TYPE_ABBR,
                					v_LMP_CHARGE.DELIVERY_POINT_ID, v_NODE.NODE,
                					v_LMP_CHARGE.CHARGE_DATE, v_LMP_CHARGE.CHARGE_RATE);

			END IF;
        END LOOP;
    END LOOP;
END EXTRACT_LMP_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_FTR_CHARGE
	(
	p_ISO_SOURCE IN VARCHAR2,
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_SCHED_TYPE IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS
v_FTR_CHARGE FTR_CHARGE%ROWTYPE;
v_FACTORS GA.NUMBER_TABLE;
v_FACTOR_TX_ID NUMBER;

-- gather the FTR allocation factor values
CURSOR c_ALLOC IS
 SELECT CHARGE_HOUR,
	FACTOR
 FROM (SELECT INT_NUM "CHARGE_HOUR",
 			VAL "FACTOR"
		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE = g_MKT_INTERVAL_DET
			AND DET_TYP_ID = 'FTR_HR_ALC_FCT')
 ORDER BY 1,2;

-- gather the distinct combinations of sources and sinks
CURSOR c_NODES IS
 SELECT A.SRC_NODE, B.SERVICE_POINT_ID "SRC_ID",
 		A.SNK_NODE, C.SERVICE_POINT_ID "SNK_ID"
 FROM (SELECT DISTINCT SRC_ND_ID "SRC_NODE",
 					SNK_ND_ID "SNK_NODE"
		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE = g_AO_INTERVAL_DET
			AND DET_TYP_ID = 'AO_FTR_PRF') A,
     SERVICE_POINT B,
     SERVICE_POINT C
 WHERE B.EXTERNAL_IDENTIFIER(+) = A.SRC_NODE
 	AND C.EXTERNAL_IDENTIFIER(+) = A.SNK_NODE;

-- gather schedule volumes
CURSOR c_SCHED(p_SRC_ND_ID IN VARCHAR2, p_SNK_ND_ID IN VARCHAR2) IS
 SELECT CHARGE_HOUR,
	FTR_TYPE,
 	SUM(CASE
	    WHEN VAL > 0 THEN
        	VAL
		ELSE
        	0
		END) "PURCHASES",
 	SUM(CASE
	    WHEN VAL < 0 THEN
        	-VAL
		ELSE
        	0
		END) "SALES"
 FROM (SELECT FTR_TYP_FL||'-'||OPT_FL "FTR_TYPE",
 			INT_NUM "CHARGE_HOUR",
			VAL
		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE = g_AO_INTERVAL_DET
			AND DET_TYP_ID = 'AO_FTR_PRF'
			AND SRC_ND_ID = p_SRC_ND_ID
			AND SNK_ND_ID = p_SNK_ND_ID)
 GROUP BY CHARGE_HOUR, FTR_TYPE
 ORDER BY 1,2;

BEGIN
    v_FTR_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_FTR_CHARGE.CHARGE_FACTOR := 1.0;
    -- first gather the allocation factor values
	v_FACTOR_TX_ID := GET_TX_ID(NULL, 'FTR Alloc Factor', 'FTR Alloc Factor', 'Hour', 0, 0, 0, ID_FOR_MISO_MP(p_ISO_SOURCE));
    FOR v_ALLOC in c_ALLOC LOOP
    	v_FACTORS(v_ALLOC.CHARGE_HOUR) := v_ALLOC.FACTOR;
		PUT_SCHEDULE_VALUE(v_FACTOR_TX_ID, p_STATEMENT_DATE+v_ALLOC.CHARGE_HOUR/24, v_ALLOC.FACTOR, p_SCHED_TYPE);
    END LOOP;
    -- loop through distinct node pairs
    FOR v_NODE IN c_NODES LOOP
    	v_FTR_CHARGE.SOURCE_ID := GET_SP_ID(v_NODE.SRC_ID, v_NODE.SRC_NODE);
    	v_FTR_CHARGE.DELIVERY_POINT_ID := 0;
    	v_FTR_CHARGE.SINK_ID := GET_SP_ID(v_NODE.SNK_ID, v_NODE.SNK_NODE);
        -- loop through schedule volumes
        FOR v_SCHED IN c_SCHED(v_NODE.SRC_NODE, v_NODE.SNK_NODE) LOOP
        	v_FTR_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_SCHED.CHARGE_HOUR/24;
            v_FTR_CHARGE.FTR_TYPE := CASE v_SCHED.FTR_TYPE
            						 WHEN 'PTP-Y' THEN
                                     	'Option'
									 WHEN 'PTP-N' THEN
                                     	'Obligation'
                                     ELSE
                                     	NULL -- Flowgate - not supported right now
                                     END;
			v_FTR_CHARGE.ALLOC_FACTOR := v_FACTORS(v_SCHED.CHARGE_HOUR);
			v_FTR_CHARGE.PURCHASES := v_SCHED.PURCHASES;
			v_FTR_CHARGE.SALES := v_SCHED.SALES;
            v_FTR_CHARGE.CHARGE_QUANTITY := NVL(v_SCHED.PURCHASES,0)-NVL(v_SCHED.SALES,0);
            -- don't bother storing empty records
            IF NVL(v_FTR_CHARGE.PURCHASES,0) > 0 OR NVL(v_FTR_CHARGE.SALES,0) > 0 THEN
                -- then get market rates
                v_FTR_CHARGE.PRICE1 := GET_VALUE_FOR_HOUR('DA_LMP_CG', NULL, NULL, v_NODE.SRC_NODE, v_SCHED.CHARGE_HOUR, p_WORK_ID);
                v_FTR_CHARGE.PRICE2 := GET_VALUE_FOR_HOUR('DA_LMP_CG', NULL, NULL, v_NODE.SNK_NODE, v_SCHED.CHARGE_HOUR, p_WORK_ID);
                v_FTR_CHARGE.CHARGE_RATE := v_FTR_CHARGE.PRICE1-v_FTR_CHARGE.PRICE2;
                -- compute effective charge quantity and dollar charge amount
                IF v_FTR_CHARGE.FTR_TYPE = 'Option' THEN
                	IF v_FTR_CHARGE.CHARGE_QUANTITY*v_FTR_CHARGE.CHARGE_RATE < 0 THEN
                    	v_FTR_CHARGE.CHARGE_QUANTITY := v_FTR_CHARGE.CHARGE_QUANTITY*v_FTR_CHARGE.ALLOC_FACTOR;
    				ELSE
                    	v_FTR_CHARGE.CHARGE_QUANTITY := 0;
                    END IF;
                ELSIF v_FTR_CHARGE.FTR_TYPE = 'Obligation' THEN
                	IF v_FTR_CHARGE.CHARGE_QUANTITY*v_FTR_CHARGE.CHARGE_RATE < 0 THEN
                    	v_FTR_CHARGE.CHARGE_QUANTITY := v_FTR_CHARGE.CHARGE_QUANTITY*v_FTR_CHARGE.ALLOC_FACTOR;
                    END IF;
                END IF;
                v_FTR_CHARGE.CHARGE_AMOUNT := v_FTR_CHARGE.CHARGE_RATE*v_FTR_CHARGE.CHARGE_FACTOR*v_FTR_CHARGE.CHARGE_QUANTITY;
                -- get bill quantity and amount
    			PC.PRIOR_FTR_CHARGE(p_PRIOR_CHARGE_ID,v_FTR_CHARGE);
                -- store this record
                PC.PUT_FTR_CHARGE(v_FTR_CHARGE);
			END IF;
        END LOOP;
    END LOOP;
END EXTRACT_FTR_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_AUCTION_CHARGE
	(
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS
BEGIN
	NULL; -- For now, do nothing: MISO settlement statements provide some info for transaction
    	  -- amounts, but not at the same level of detail as RO provides - and also not with enough
          -- readily usable identifying attributes to properly associate the data w/ corresponding
          -- Interchange Transactions
END EXTRACT_AUCTION_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_ADMIN_CHARGE(p_CHARGE_ID       IN NUMBER,
															 p_STATEMENT_DATE  IN DATE,
															 p_PRIOR_CHARGE_ID IN NUMBER,
															 p_MARKET          IN VARCHAR2,
															 p_RATE_ID         IN VARCHAR2,
															 p_WORK_ID         IN NUMBER) AS
	v_FML_CHARGE FORMULA_CHARGE%ROWTYPE;
    v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
	CURSOR c_CHARGES IS
		SELECT CHARGE_HOUR, ADMIN_VOL, ADMIN_RATE
			FROM (SELECT A.INT_NUM "CHARGE_HOUR", A.VAL "ADMIN_VOL", B.VAL "ADMIN_RATE"
							FROM MISO_DET_WORK A, MISO_DET_WORK B
						 WHERE A.WORK_ID = p_WORK_ID
							 AND A.DET_TYPE = g_AO_INTERVAL_DET
							 AND A.DET_TYP_ID = p_MARKET || '_ADMIN_VOL'
							 AND B.WORK_ID = p_WORK_ID
							 AND B.DET_TYPE = g_MKT_INTERVAL_DET
							 AND B.DET_TYP_ID = p_RATE_ID
							 AND B.INT_NUM = A.INT_NUM)
		 ORDER BY 1;
  v_MKT_PRICE_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
BEGIN
	v_MKT_PRICE_ID := GET_PRICE_ID('MISO:' || p_RATE_ID);

	v_FML_CHARGE.CHARGE_ID      := p_CHARGE_ID;
	v_FML_CHARGE.ITERATOR_ID := 0;
	v_FML_CHARGE.CHARGE_FACTOR  := 1.0;

    v_VAR.CHARGE_ID := p_CHARGE_ID;
    v_VAR.ITERATOR_ID := 0;

	FOR v_CHARGE IN c_CHARGES LOOP
    	v_VAR.CHARGE_DATE := p_STATEMENT_DATE + v_CHARGE.CHARGE_HOUR / 24;
        v_VAR.VARIABLE_NAME := p_MARKET || '_Admin_Vol';
        v_VAR.VARIABLE_VAL := NVL(v_CHARGE.ADMIN_VOL, 0);
        PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := p_MARKET || '_Admin_Rate';
		v_VAR.VARIABLE_VAL := NVL(v_CHARGE.ADMIN_RATE, 0);
		PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

		v_FML_CHARGE.CHARGE_DATE     := p_STATEMENT_DATE + v_CHARGE.CHARGE_HOUR / 24;
		v_FML_CHARGE.CHARGE_QUANTITY := NVL(v_CHARGE.ADMIN_VOL, 0);
		v_FML_CHARGE.CHARGE_RATE     := NVL(v_CHARGE.ADMIN_RATE, 0);
		-- compute dollar charge amount
		v_FML_CHARGE.CHARGE_AMOUNT := v_FML_CHARGE.CHARGE_RATE *
																	v_FML_CHARGE.CHARGE_FACTOR *
																	v_FML_CHARGE.CHARGE_QUANTITY;
		-- get bill quantity and amount
		PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID, v_FML_CHARGE);
		-- store this record
		PC.PUT_FORMULA_CHARGE(v_FML_CHARGE);

    -- add the rate to the market price for the shadow
    PUT_MARKET_PRICE_VALUE(v_MKT_PRICE_ID, 'A', v_FML_CHARGE.CHARGE_DATE, v_CHARGE.ADMIN_RATE);
	END LOOP;
END EXTRACT_ADMIN_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_NI_DIST_CHARGE
	(
	p_ISO_SOURCE IN VARCHAR2,
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_SCHED_TYPE IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS
v_FML_CHARGE FORMULA_CHARGE%ROWTYPE;
v_MP_ID NUMBER;
v_CONTRACT_ID NUMBER(9);
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

CURSOR c_CHARGES IS
 SELECT CHARGE_HOUR,
	ADMIN_VOL,
    ADMIN_RATE
 FROM (SELECT A.INT_NUM "CHARGE_HOUR",
 			A.VAL "ADMIN_VOL",
			B.VAL "ADMIN_RATE"
		FROM MISO_DET_WORK A, MISO_DET_WORK B
		WHERE A.WORK_ID = p_WORK_ID
			AND A.DET_TYPE = g_AO_DET
			AND A.DET_TYP_ID = 'NI_DIST_FCT'
			AND B.WORK_ID = p_WORK_ID
			AND B.DET_TYPE = g_MKT_DET
			AND B.DET_TYP_ID = 'MISO_NI'
			AND B.INT_NUM = A.INT_NUM)
 ORDER BY 1;

BEGIN
    v_CONTRACT_ID := ID_FOR_MISO_CONTRACT(p_ISO_SOURCE);
	v_TRANSACTION_ID := GET_TX_ID(NULL, 'NI Dist Factor', 'MISO NI Dist Factor: '||p_ISO_SOURCE, 'Hour', v_CONTRACT_ID);
	v_MP_ID := GET_PRICE_ID('MISO:MISO_NI', 'MISO Daily Total Net Inadvertent');

    v_FML_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_FML_CHARGE.ITERATOR_ID := 0;
    v_FML_CHARGE.CHARGE_FACTOR := 1.0;
    FOR v_CHARGE IN c_CHARGES LOOP
    	v_FML_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+1/86400;
        v_FML_CHARGE.CHARGE_QUANTITY := NVL(v_CHARGE.ADMIN_VOL,0);
        v_FML_CHARGE.CHARGE_RATE := NVL(v_CHARGE.ADMIN_RATE,0);
        -- compute dollar charge amount
        v_FML_CHARGE.CHARGE_AMOUNT := v_FML_CHARGE.CHARGE_RATE*v_FML_CHARGE.CHARGE_FACTOR*v_FML_CHARGE.CHARGE_QUANTITY;
        -- get bill quantity and amount
        PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_FML_CHARGE);
        -- store this record
        PC.PUT_FORMULA_CHARGE(v_FML_CHARGE);

        --update market_price_value
        PUT_MARKET_PRICE_VALUE(v_MP_ID, 'A', p_STATEMENT_DATE, v_FML_CHARGE.CHARGE_RATE);
        -- and it_schedule
		PUT_SCHEDULE_VALUE(v_TRANSACTION_ID, v_FML_CHARGE.CHARGE_DATE, v_FML_CHARGE.CHARGE_QUANTITY, p_SCHED_TYPE);
    END LOOP;
END EXTRACT_NI_DIST_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_DA_TX_COUNT_CHARGE
	(
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS
v_FML_CHARGE FORMULA_CHARGE%ROWTYPE;
CURSOR c_CHARGES IS
 	SELECT A.INT_NUM "CHARGE_HOUR",
		A.VAL "TX_COUNT",
		B.VAL "TX_RATE"
    FROM MISO_DET_WORK A, MISO_DET_WORK B
    WHERE A.WORK_ID = p_WORK_ID
        AND A.DET_TYPE = g_AO_INTERVAL_DET
        AND A.DET_TYP_ID = 'ADMIN_TXN_CNT'
        AND B.WORK_ID(+) = p_WORK_ID
        AND B.DET_TYPE(+) = g_MKT_DET
        AND B.DET_TYP_ID(+) = 'ADMIN_TXN_RATE'
        AND B.INT_NUM(+) = 0
	ORDER BY 1;

BEGIN
    v_FML_CHARGE.CHARGE_ID := p_CHARGE_ID;
	v_FML_CHARGE.ITERATOR_ID := 0;
    v_FML_CHARGE.CHARGE_FACTOR := 1.0;
    FOR v_CHARGE IN c_CHARGES LOOP
    	v_FML_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_CHARGE.CHARGE_HOUR/24;
        v_FML_CHARGE.CHARGE_QUANTITY := NVL(v_CHARGE.TX_COUNT,0);
        v_FML_CHARGE.CHARGE_RATE := NVL(v_CHARGE.TX_RATE,0);
        -- compute dollar charge amount
        v_FML_CHARGE.CHARGE_AMOUNT := v_FML_CHARGE.CHARGE_RATE*v_FML_CHARGE.CHARGE_FACTOR*v_FML_CHARGE.CHARGE_QUANTITY;
        -- get bill quantity and amount
		PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_FML_CHARGE);
        -- store this record
        PC.PUT_FORMULA_CHARGE(v_FML_CHARGE);
    END LOOP;
END EXTRACT_DA_TX_COUNT_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_RT_RNU_LRS_CHARGE
  (
  p_ISO_SOURCE IN VARCHAR2,
  p_CHARGE_ID IN NUMBER,
  p_STATEMENT_DATE IN DATE,
  p_PRIOR_CHARGE_ID IN NUMBER,
  p_SCHED_TYPE IN NUMBER,
  p_WORK_ID IN NUMBER,
  p_DET_NAME IN VARCHAR2
  ) AS
v_FML_CHARGE FORMULA_CHARGE%ROWTYPE;
v_MP_ID NUMBER;
v_CONTRACT_ID NUMBER(9);
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;


CURSOR c_CHARGES IS
 	SELECT A.INT_NUM "CHARGE_HOUR",
		A.VAL "TX_COUNT",
		B.VAL "TX_RATE"
    FROM MISO_DET_WORK A, MISO_DET_WORK B
    WHERE A.WORK_ID = p_WORK_ID
        AND A.DET_TYPE = g_AO_INTERVAL_DET
        AND A.DET_TYP_ID = 'MISO_LRS_FCT'
        AND B.WORK_ID = p_WORK_ID
        AND B.DET_TYPE = g_MKT_INTERVAL_DET
        AND B.DET_TYP_ID = p_DET_NAME
        AND A.WORK_ID = B.WORK_ID
        AND A.INT_NUM = B.INT_NUM
	ORDER BY 1;

BEGIN
	v_CONTRACT_ID := ID_FOR_MISO_CONTRACT(p_ISO_SOURCE);
	v_TRANSACTION_ID := GET_TX_ID(NULL, 'Ratio Load-Share', 'MISO Ratio Load-Share: '||p_ISO_SOURCE, 'Hour', v_CONTRACT_ID);
	v_MP_ID := GET_PRICE_ID('MISO:' || p_DET_NAME, 'MISO ' || p_DET_NAME);

    v_FML_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_FML_CHARGE.ITERATOR_ID := 0;
    v_FML_CHARGE.CHARGE_FACTOR := 1.0;
    FOR v_CHARGE IN c_CHARGES LOOP
        v_FML_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_CHARGE.CHARGE_HOUR/24;
        v_FML_CHARGE.CHARGE_QUANTITY := NVL(v_CHARGE.TX_COUNT,0);
        v_FML_CHARGE.CHARGE_RATE := NVL(v_CHARGE.TX_RATE,0);
        -- compute dollar charge amount
        v_FML_CHARGE.CHARGE_AMOUNT := v_FML_CHARGE.CHARGE_RATE*v_FML_CHARGE.CHARGE_FACTOR*v_FML_CHARGE.CHARGE_QUANTITY;

        -- get bill quantity and amount
        PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_FML_CHARGE);
        -- store this record
        PC.PUT_FORMULA_CHARGE(v_FML_CHARGE);

        --update market_price_value
        PUT_MARKET_PRICE_VALUE(v_MP_ID, 'A', v_FML_CHARGE.CHARGE_DATE, v_FML_CHARGE.CHARGE_RATE);
        -- and it_schedule
		PUT_SCHEDULE_VALUE(v_TRANSACTION_ID, v_FML_CHARGE.CHARGE_DATE, v_FML_CHARGE.CHARGE_QUANTITY, p_SCHED_TYPE);
    END LOOP;
END EXTRACT_RT_RNU_LRS_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_RNU_CHARGE
	(
	p_ISO_SOURCE IN VARCHAR2,
    p_BILLING_STATEMENT IN BILLING_STATEMENT%ROWTYPE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS
v_CMB_CHARGE COMBINATION_CHARGE%ROWTYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_PRIOR_CHARGE_ID NUMBER;
BEGIN
	-- we use a billing statement record so that PC.GET_PRIOR_CHARGE_ID will work and bill amounts can be correctly computed
	v_BILLING_STATEMENT.ENTITY_ID := p_BILLING_STATEMENT.ENTITY_ID;
	v_BILLING_STATEMENT.PRODUCT_ID := -p_BILLING_STATEMENT.CHARGE_ID;
	v_BILLING_STATEMENT.STATEMENT_TYPE := p_BILLING_STATEMENT.STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := p_BILLING_STATEMENT.STATEMENT_STATE;
	v_BILLING_STATEMENT.STATEMENT_DATE := p_BILLING_STATEMENT.STATEMENT_DATE;
	v_BILLING_STATEMENT.AS_OF_DATE := p_BILLING_STATEMENT.AS_OF_DATE;

	v_CMB_CHARGE.CHARGE_ID := p_BILLING_STATEMENT.CHARGE_ID;
	v_CMB_CHARGE.BEGIN_DATE := p_BILLING_STATEMENT.STATEMENT_DATE;
	v_CMB_CHARGE.END_DATE := p_BILLING_STATEMENT.STATEMENT_DATE;
	v_CMB_CHARGE.CHARGE_FACTOR := 1.0;
	v_CMB_CHARGE.CHARGE_VIEW_TYPE := 'FORMULA';


	v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','RT_RNU-UD_MISO');
  -- for this charge component, the coefficient is -1; everything else is +1
  v_CMB_CHARGE.Coefficient := -1.0;
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_RT_RNU_LRS_CHARGE(p_ISO_SOURCE, v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, v_BILLING_STATEMENT.STATEMENT_TYPE, p_WORK_ID, 'UD_MISO');
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
  -- UD_MISO is negative
	v_CMB_CHARGE.CHARGE_AMOUNT := -v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

  -- use +1 for the coefficient for all other subcomponents
  v_CMB_CHARGE.COEFFICIENT := 1.0;

  v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','RT_RNU-RI_UPLIFT');
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_RT_RNU_LRS_CHARGE(p_ISO_SOURCE, v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, v_BILLING_STATEMENT.STATEMENT_TYPE, p_WORK_ID, 'RI_UPLIFT');
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
	v_CMB_CHARGE.CHARGE_AMOUNT := v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

  v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','RT_RNU-JOA_MISO_UPLIFT');
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_RT_RNU_LRS_CHARGE(p_ISO_SOURCE, v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, v_BILLING_STATEMENT.STATEMENT_TYPE, p_WORK_ID, 'JOA_MISO_UPLIFT');
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
	v_CMB_CHARGE.CHARGE_AMOUNT := v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

  v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','RT_RNU-MISO_RT_GFAOB_DIST');
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_RT_RNU_LRS_CHARGE(p_ISO_SOURCE, v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, v_BILLING_STATEMENT.STATEMENT_TYPE, p_WORK_ID, 'MISO_RT_GFAOB_DIST');
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
	v_CMB_CHARGE.CHARGE_AMOUNT := v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

  v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','RT_RNU-MISO_RT_GFACO_DIST');
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_RT_RNU_LRS_CHARGE(p_ISO_SOURCE, v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, v_BILLING_STATEMENT.STATEMENT_TYPE, p_WORK_ID, 'MISO_RT_GFACO_DIST');
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
	v_CMB_CHARGE.CHARGE_AMOUNT := v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

  v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','RT_RNU-MISO_RT_RSG_DIST2');
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_RT_RNU_LRS_CHARGE(p_ISO_SOURCE, v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, v_BILLING_STATEMENT.STATEMENT_TYPE, p_WORK_ID, 'MISO_RT_RSG_DIST2');
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
	v_CMB_CHARGE.CHARGE_AMOUNT := v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

END EXTRACT_RNU_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_DA_ADMIN_CHARGE
	(
    p_BILLING_STATEMENT IN BILLING_STATEMENT%ROWTYPE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS
v_CMB_CHARGE COMBINATION_CHARGE%ROWTYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_PRIOR_CHARGE_ID NUMBER;
BEGIN
	-- we use a billing statement record so that PC.GET_PRIOR_CHARGE_ID will work and bill amounts can be correctly computed
	v_BILLING_STATEMENT.ENTITY_ID := p_BILLING_STATEMENT.ENTITY_ID;
	v_BILLING_STATEMENT.PRODUCT_ID := -p_BILLING_STATEMENT.CHARGE_ID;
	v_BILLING_STATEMENT.STATEMENT_TYPE := p_BILLING_STATEMENT.STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := p_BILLING_STATEMENT.STATEMENT_STATE;
	v_BILLING_STATEMENT.STATEMENT_DATE := p_BILLING_STATEMENT.STATEMENT_DATE;
	v_BILLING_STATEMENT.AS_OF_DATE := p_BILLING_STATEMENT.AS_OF_DATE;

	v_CMB_CHARGE.CHARGE_ID := p_BILLING_STATEMENT.CHARGE_ID;
	v_CMB_CHARGE.BEGIN_DATE := p_BILLING_STATEMENT.STATEMENT_DATE;
	v_CMB_CHARGE.END_DATE := p_BILLING_STATEMENT.STATEMENT_DATE;
	v_CMB_CHARGE.COEFFICIENT := 1.0;
	v_CMB_CHARGE.CHARGE_FACTOR := 1.0;
	v_CMB_CHARGE.CHARGE_VIEW_TYPE := 'FORMULA';

	-- first do the normal admin fee stuff

	v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','DA_ADMIN-VOL');
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_ADMIN_CHARGE(v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'DA', 'ENERGY_MKT_RATE', p_WORK_ID);
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
	v_CMB_CHARGE.CHARGE_AMOUNT := v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

	-- then do the transaction count admin fee stuff

	v_CMB_CHARGE.COMPONENT_ID := ID_FOR_MISO_COMPONENT('','DA_ADMIN-COUNT');
	v_BILLING_STATEMENT.COMPONENT_ID := v_CMB_CHARGE.COMPONENT_ID;
	PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	v_CMB_CHARGE.COMBINED_CHARGE_ID := v_BILLING_STATEMENT.CHARGE_ID;
	PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- persist so we can fetch the prior charge ID for computing bill amounts
	v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(v_BILLING_STATEMENT);
	EXTRACT_DA_TX_COUNT_CHARGE(v_CMB_CHARGE.COMBINED_CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_WORK_ID);
	SELECT NVL(SUM(CHARGE_QUANTITY),0), NVL(SUM(CHARGE_AMOUNT),0), NVL(AVG(CHARGE_RATE),0)
		INTO v_CMB_CHARGE.CHARGE_QUANTITY, v_CMB_CHARGE.COMPONENT_AMOUNT, v_CMB_CHARGE.CHARGE_RATE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = v_CMB_CHARGE.COMBINED_CHARGE_ID;
	v_CMB_CHARGE.CHARGE_AMOUNT := v_CMB_CHARGE.COMPONENT_AMOUNT;
	PC.PRIOR_COMBINATION_CHARGE(p_PRIOR_CHARGE_ID,v_CMB_CHARGE);
	PC.PUT_COMBINATION_CHARGE(v_CMB_CHARGE);
	-- then clean up BILLING_STATEMENT record that we added
	UPDATE BILLING_STATEMENT SET CHARGE_ID = -CHARGE_ID WHERE CHARGE_ID = v_BILLING_STATEMENT.CHARGE_ID;
	-- first we update the record so that the delete trigger won't wipe out the details we've calculated - then we delete
	DELETE BILLING_STATEMENT WHERE CHARGE_ID = -v_BILLING_STATEMENT.CHARGE_ID;

END EXTRACT_DA_ADMIN_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_LOSS_DIST_CHARGE
	(
	p_ISO_SOURCE IN VARCHAR2,
	p_CHARGE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_SCHED_TYPE IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS

v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;

v_SP_ID NUMBER;
v_CONTRACT_ID NUMBER;
v_ASSET_LOSS_TX NUMBER;
TYPE ID_MAP IS TABLE OF NUMBER(9) INDEX BY VARCHAR2(64);
v_LP_LOSS_TX_MAP ID_MAP;
v_LP_LOSS_POOL_MAP ID_MAP;
v_LP_POOL_ID NUMBER;
v_LP_TX_ID NUMBER;
v_MP_ID NUMBER;

-- gather all asset nodes
CURSOR c_NODES IS
 SELECT A.NODE, B.SERVICE_POINT_ID "NODE_ID"
 FROM (SELECT DISTINCT DP_ND_ID "NODE"
 		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE = g_ASSET_INTERVAL_DET
			AND DET_TYP_ID = 'RT_BLL_MTR') A,
     SERVICE_POINT B
 WHERE B.EXTERNAL_IDENTIFIER(+) = A.NODE;

-- gather distribution factors and dollar amounts
CURSOR c_DETS(p_ND_ID IN VARCHAR2) IS
    SELECT INT_NUM "CHARGE_HOUR",
		MAX(CASE
    	    WHEN DET_TYP_ID = 'LP_FCT' THEN
				DP_ND_ID
    		ELSE
            	NULL
    		END) "LOSS_POOL",
		NVL(SUM(CASE
    	    WHEN DET_TYP_ID = 'LP_FCT' THEN
				VAL
    		ELSE
            	0
    		END), 0) "LP_FCT",
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID = 'LP_LRS_FCT' THEN
            	VAL
    		ELSE
            	0
    		END), 0) "ASSET_FCT",
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID = 'MISO_LOSS_SURPLUS' THEN
            	VAL
    		ELSE
            	0
    		END), 0) "MISO_LOSSES"
    FROM MISO_DET_WORK A
	WHERE WORK_ID = p_WORK_ID
		AND ((DET_TYPE = g_MKT_INTERVAL_DET
			  AND DET_TYP_ID = 'MISO_LOSS_SURPLUS')
			 OR
			 (DET_TYPE = g_ASSET_INTERVAL_DET
			  AND A.ASSET_NM = p_ND_ID
			  AND A.DET_TYP_ID IN ('LP_FCT', 'LP_LRS_FCT')))
    GROUP BY INT_NUM
    ORDER BY 1;

	FUNCTION FETCH_POOL(p_LP_NAME IN VARCHAR2) RETURN NUMBER IS
	BEGIN
		IF NOT v_LP_LOSS_POOL_MAP.EXISTS(p_LP_NAME) THEN
			v_LP_LOSS_POOL_MAP(p_LP_NAME) := GET_POOL_ID('MISO:'||p_LP_NAME);
		END IF;

		RETURN v_LP_LOSS_POOL_MAP(p_LP_NAME);
	END FETCH_POOL;

BEGIN
	v_MP_ID := GET_PRICE_ID('MISO:MISO_LOSS_SURPLUS');

	v_ITERATOR_NAME.CHARGE_ID := p_CHARGE_ID;
	v_ITERATOR_NAME.ITERATOR_NAME1 := 'Asset';
	v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

	v_ITERATOR.CHARGE_ID := p_CHARGE_ID;
	v_ITERATOR.ITERATOR_ID := 0;
	v_ITERATOR.ITERATOR1 := NULL;
	v_ITERATOR.ITERATOR2 := NULL;
	v_ITERATOR.ITERATOR3 := NULL;
	v_ITERATOR.ITERATOR4 := NULL;
	v_ITERATOR.ITERATOR5 := NULL;


    v_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_CHARGE.CHARGE_FACTOR := 1.0;
	v_VAR.CHARGE_ID := p_CHARGE_ID;

	v_CONTRACT_ID := ID_FOR_MISO_CONTRACT(p_ISO_SOURCE);

    -- loop through nodes
    FOR v_NODE IN c_NODES LOOP
		-- setup sub-interval for node
		v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
		v_SP_ID := GET_SP_ID(v_NODE.NODE_ID,v_NODE.NODE);
		SELECT SERVICE_POINT_NAME INTO v_ITERATOR.ITERATOR1
			FROM SERVICE_POINT WHERE SERVICE_POINT_ID = v_SP_ID;
		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_ASSET_LOSS_TX := NULL;

        -- loop through hourly info
        FOR v_DETS IN c_DETS(v_NODE.NODE) LOOP
        	v_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_DETS.CHARGE_HOUR/24;
        	v_VAR.CHARGE_DATE := v_CHARGE.CHARGE_DATE;

			-- save values to transactions' schedules
			IF v_DETS.LOSS_POOL IS NOT NULL THEN
				v_LP_POOL_ID := NULL;

				IF NOT v_LP_LOSS_TX_MAP.EXISTS(v_DETS.LOSS_POOL) THEN
					v_LP_POOL_ID := FETCH_POOL(v_DETS.LOSS_POOL);
					v_LP_LOSS_TX_MAP(v_DETS.LOSS_POOL) := GET_TX_ID(NULL, 'LP Loss Dist', 'LP Loss Dist', 'Hour', 0, 0, v_LP_POOL_ID);
				END IF;
				v_LP_TX_ID := v_LP_LOSS_TX_MAP(v_DETS.LOSS_POOL);
				PUT_SCHEDULE_VALUE(v_LP_TX_ID, v_VAR.CHARGE_DATE, v_DETS.LP_FCT, p_SCHED_TYPE);

				IF v_ASSET_LOSS_TX IS NULL THEN
					IF v_LP_POOL_ID IS NULL THEN
						v_LP_POOL_ID := FETCH_POOL(v_DETS.LOSS_POOL);
					END IF;
					v_ASSET_LOSS_TX := GET_TX_ID(NULL, 'Asset Loss Dist', 'Asset Loss Dist', 'Hour', v_CONTRACT_ID, v_SP_ID, v_LP_POOL_ID);
				END IF;
				PUT_SCHEDULE_VALUE(v_ASSET_LOSS_TX, v_VAR.CHARGE_DATE, v_DETS.ASSET_FCT, p_SCHED_TYPE);
			END IF;

      PUT_MARKET_PRICE_VALUE(v_MP_ID,'A',v_CHARGE.CHARGE_DATE,NVL(v_DETS.MISO_LOSSES,0));

			v_VAR.VARIABLE_NAME := 'AssetLossesDistFactor';
			v_VAR.VARIABLE_VAL := v_DETS.ASSET_FCT;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_VAR.VARIABLE_NAME := 'LPLossesDistFactor';
			v_VAR.VARIABLE_VAL := v_DETS.LP_FCT;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

            -- compute effective charge quantity and dollar charge amount
            v_CHARGE.CHARGE_QUANTITY := NVL(v_DETS.ASSET_FCT,0) * NVL(v_DETS.LP_FCT,0);
			v_CHARGE.CHARGE_RATE := NVL(v_DETS.MISO_LOSSES,0);
			v_CHARGE.CHARGE_AMOUNT := v_CHARGE.CHARGE_QUANTITY * v_CHARGE.CHARGE_RATE;
            -- get bill quantity and amount
  			PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_CHARGE);
            -- store this record
            PC.PUT_FORMULA_CHARGE(v_CHARGE);
        END LOOP;
    END LOOP;
END EXTRACT_LOSS_DIST_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_UD_CHARGE
	(
	p_ISO_SOURCE IN VARCHAR2,
	p_CHARGE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_SCHED_TYPE IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS

v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_LMP NUMBER;
v_MAX_DN_CH NUMBER;
v_UP_VOL NUMBER;
v_DN_VOL NUMBER;
v_UP_CHARGE NUMBER;
v_DN_CHARGE NUMBER;
v_CONTRACT_ID NUMBER;
v_SP_ID NUMBER;

v_UD_PRC_UP_TX NUMBER;
v_UD_PRC_DN_TX NUMBER;
v_UD_PRC_CP_TX NUMBER;
v_UD_TOL_UP_MIN_TX NUMBER;
v_UD_TOL_UP_MAX_TX NUMBER;
v_UD_TOL_UP_PCT_TX NUMBER;
v_UD_TOL_DN_MIN_TX NUMBER;
v_UD_TOL_DN_MAX_TX NUMBER;
v_UD_TOL_DN_PCT_TX NUMBER;
v_UD_EXEMPT_TX NUMBER;

CURSOR c_NODES IS
 SELECT A.NODE, B.SERVICE_POINT_ID "NODE_ID"
 FROM (SELECT DISTINCT DP_ND_ID "NODE"
 		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE = g_ASSET_INTERVAL_DET
			AND DET_TYP_ID = 'UD_XMPT') A,
     SERVICE_POINT B
 WHERE B.EXTERNAL_IDENTIFIER(+) = A.NODE;

-- gather determinants
CURSOR c_DETS(p_ND_ID IN VARCHAR2) IS
    SELECT INT_NUM "CHARGE_HOUR",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'GEN_SP' THEN VAL
	    		ELSE NULL
	    		END), 0) "GEN_SP",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'GEN_PERF' THEN VAL
	    		ELSE NULL
	    		END), 0) "GEN_PERF",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'REG_UP' THEN VAL
	    		ELSE NULL
	    		END), 0) "REG_UP",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'REG_DN' THEN VAL
	    		ELSE NULL
	    		END), 0) "REG_DOWN",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_XMPT' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_EXEMPT",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_UP' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_TOL_UP",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_DN' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_TOL_DOWN",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_PRC_DN' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_DOWN_PRC",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_DN_PCT' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_DOWN_TOL_PCT",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_DN_MIN_MW' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_DOWN_TOL_MIN",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_DN_MAX_MW' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_DOWN_TOL_MAX",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_PRC_CP' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_MAX_PRC",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_PRC_UP' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_UP_PRC",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_UP_PCT' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_UP_TOL_PCT",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_UP_MIN_MW' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_UP_TOL_MIN",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'UD_TOL_UP_MAX_MW' THEN VAL
	    		ELSE NULL
	    		END), 0) "UD_UP_TOL_MAX"
    FROM MISO_DET_WORK A
	WHERE WORK_ID = p_WORK_ID
		AND ((DET_TYPE = g_MKT_INTERVAL_DET
			  AND DET_TYP_ID IN ('UD_PRC_DN','UD_TOL_DN_PCT','UD_TOL_DN_MIN_MW','UD_TOL_DN_MAX_MW',
			  					 'UD_PRC_UP','UD_TOL_UP_PCT','UD_TOL_UP_MIN_MW','UD_TOL_UP_MAX_MW',
								 'UD_PRC_CP'))
			 OR
			 (DET_TYPE = g_ASSET_INTERVAL_DET
			  AND A.DP_ND_ID = p_ND_ID
			  AND A.DET_TYP_ID IN ('GEN_SP','GEN_PERF','REG_UP','REG_DN','UD_XMPT','UD_TOL_UP','UD_TOL_DN')))
    GROUP BY INT_NUM
    ORDER BY 1;

BEGIN
	v_ITERATOR_NAME.CHARGE_ID := p_CHARGE_ID;
	v_ITERATOR_NAME.ITERATOR_NAME1 := 'GenAsset';
	v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

	v_ITERATOR.CHARGE_ID := p_CHARGE_ID;
	v_ITERATOR.ITERATOR_ID := 0;
	v_ITERATOR.ITERATOR1 := NULL;
	v_ITERATOR.ITERATOR2 := NULL;
	v_ITERATOR.ITERATOR3 := NULL;
	v_ITERATOR.ITERATOR4 := NULL;
	v_ITERATOR.ITERATOR5 := NULL;

    v_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_CHARGE.CHARGE_FACTOR := 1.0;
	v_VAR.CHARGE_ID := p_CHARGE_ID;

	v_UD_PRC_UP_TX := GET_TX_ID('MISO:UD_PRC_UP', 'Market Result',  'MISO Uninstr.Dev.Up LMP%');
	v_UD_PRC_DN_TX := GET_TX_ID('MISO:UD_PRC_DN', 'Market Result',  'MISO Uninstr.Dev.Down LMP%');
	v_UD_PRC_CP_TX := GET_TX_ID('MISO:UD_PRC_CP', 'Market Result',  'MISO Uninstr.Dev.Max Charge LMP%');
	v_UD_TOL_UP_MIN_TX := GET_TX_ID('MISO:UD_TOL_UP_MIN_MW', 'Market Result',  'MISO Uninst.Dev.Up Tol. Min MW');
	v_UD_TOL_UP_MAX_TX := GET_TX_ID('MISO:UD_TOL_UP_MAX_MW', 'Market Result',  'MISO Uninst.Dev.Up Tol. Max MW');
	v_UD_TOL_UP_PCT_TX := GET_TX_ID('MISO:UD_TOL_UP_PCT', 'Market Result',  'MISO Uninst.Dev.Up Tol.%');
	v_UD_TOL_DN_MIN_TX := GET_TX_ID('MISO:UD_TOL_DN_MIN_MW', 'Market Result',  'MISO Uninst.Dev.Down Tol.Min MW');
	v_UD_TOL_DN_MAX_TX := GET_TX_ID('MISO:UD_TOL_DN_MAX_MW', 'Market Result',  'MISO Uninst.Dev.Down Tol.Max MW');
	v_UD_TOL_DN_PCT_TX := GET_TX_ID('MISO:UD_TOL_DN_PCT', 'Market Result',  'MISO Uninst.Dev.Down Tol.%');

	v_CONTRACT_ID := ID_FOR_MISO_CONTRACT(p_ISO_SOURCE);

    -- loop through nodes
    FOR v_NODE IN c_NODES LOOP
		-- setup sub-interval for node
		v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
		v_SP_ID := GET_SP_ID(v_NODE.NODE_ID,v_NODE.NODE);
		SELECT SERVICE_POINT_NAME
        INTO v_ITERATOR.ITERATOR1
        FROM SERVICE_POINT
        WHERE SERVICE_POINT_ID = v_SP_ID;

		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_UD_EXEMPT_TX := GET_TX_ID(NULL, 'UD Exempt Flag', 'MISO UD Exempt: '||v_ITERATOR.ITERATOR1, 'Hour', v_CONTRACT_ID, v_SP_ID);

        -- loop through hourly info
        FOR v_DETS IN c_DETS(v_NODE.NODE) LOOP
        	v_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_DETS.CHARGE_HOUR/24;
        	v_VAR.CHARGE_DATE := v_CHARGE.CHARGE_DATE;

			v_VAR.VARIABLE_NAME := 'GenSetPoint';
			v_VAR.VARIABLE_VAL := v_DETS.GEN_SP;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_VAR.VARIABLE_NAME := 'GenPerf';
			v_VAR.VARIABLE_VAL := v_DETS.GEN_PERF;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_VAR.VARIABLE_NAME := 'RegUp';
			v_VAR.VARIABLE_VAL := v_DETS.REG_UP;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_VAR.VARIABLE_NAME := 'RegDown';
			v_VAR.VARIABLE_VAL := v_DETS.REG_DOWN;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_VAR.VARIABLE_NAME := 'UDExempt';
			v_VAR.VARIABLE_VAL := v_DETS.UD_EXEMPT;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_EXEMPT_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_EXEMPT, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDUpLMPPercent';
			v_VAR.VARIABLE_VAL := v_DETS.UD_UP_PRC;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_PRC_UP_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_UP_PRC, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDDownLMPPercent';
			v_VAR.VARIABLE_VAL := v_DETS.UD_DOWN_PRC;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_PRC_DN_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_DOWN_PRC, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDMaxLMPPercent';
			v_VAR.VARIABLE_VAL := v_DETS.UD_MAX_PRC;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_PRC_CP_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_MAX_PRC, p_SCHED_TYPE);

			v_LMP := NVL(GET_VALUE_FOR_HOUR('RT_LMP_EN', NULL, NULL, v_NODE.NODE, v_DETS.CHARGE_HOUR, p_WORK_ID),0);
			v_VAR.VARIABLE_NAME := 'RTLMPEn';
			v_VAR.VARIABLE_VAL := v_LMP;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_VAR.VARIABLE_NAME := 'UDUpTolMin';
			v_VAR.VARIABLE_VAL := v_DETS.UD_UP_TOL_MIN;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_TOL_UP_MIN_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_UP_TOL_MIN, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDUpTolMax';
			v_VAR.VARIABLE_VAL := v_DETS.UD_UP_TOL_MAX;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_TOL_UP_MAX_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_UP_TOL_MAX, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDUpTolPercent';
			v_VAR.VARIABLE_VAL := v_DETS.UD_UP_TOL_PCT;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_TOL_UP_PCT_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_UP_TOL_PCT, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDUpTolerance';
			v_VAR.VARIABLE_VAL := v_DETS.UD_TOL_UP;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_UP_VOL := GREATEST(0, NVL(v_DETS.GEN_PERF,0) - NVL(v_DETS.UD_TOL_UP,0));

			v_VAR.VARIABLE_NAME := 'UDDownTolMin';
			v_VAR.VARIABLE_VAL := v_DETS.UD_DOWN_TOL_MIN;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_TOL_DN_MIN_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_DOWN_TOL_MIN, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDDownTolMax';
			v_VAR.VARIABLE_VAL := v_DETS.UD_DOWN_TOL_MAX;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_TOL_DN_MAX_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_DOWN_TOL_MAX, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDDownTolPercent';
			v_VAR.VARIABLE_VAL := v_DETS.UD_DOWN_TOL_PCT;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
            PUT_SCHEDULE_VALUE(v_UD_TOL_DN_PCT_TX, v_CHARGE.CHARGE_DATE, v_DETS.UD_DOWN_TOL_PCT, p_SCHED_TYPE);

			v_VAR.VARIABLE_NAME := 'UDDownTolerance';
			v_VAR.VARIABLE_VAL := v_DETS.UD_TOL_DOWN;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_DN_VOL := GREATEST(0, NVL(v_DETS.UD_TOL_DOWN,0) - NVL(v_DETS.GEN_PERF,0));

			v_UP_CHARGE := CASE WHEN NVL(v_DETS.UD_EXEMPT,0) = 1 THEN 0
									   ELSE v_UP_VOL * NVL(v_DETS.UD_UP_PRC,0)/100 * ABS(v_LMP)
									   END;
			v_VAR.VARIABLE_NAME := 'UDUpCharge';
			v_VAR.VARIABLE_VAL := v_UP_CHARGE;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_MAX_DN_CH := NVL(v_DETS.GEN_PERF,0) * ABS(v_LMP) * NVL(v_DETS.UD_MAX_PRC,0)/100;
			v_VAR.VARIABLE_NAME := 'UDDownMaxCharge';
			v_VAR.VARIABLE_VAL := v_MAX_DN_CH;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

			v_DN_CHARGE := CASE WHEN NVL(v_DETS.UD_EXEMPT,0) = 1 THEN 0
									   ELSE LEAST(v_MAX_DN_CH, v_DN_VOL * NVL(v_DETS.UD_DOWN_PRC,0)/100 * ABS(v_LMP))
									   END;
			v_VAR.VARIABLE_NAME := 'UDDownCharge';
			v_VAR.VARIABLE_VAL := v_DN_CHARGE;
			PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

            -- compute effective charge quantity and dollar charge amount
            v_CHARGE.CHARGE_QUANTITY := v_UP_CHARGE+v_DN_CHARGE;
            v_CHARGE.CHARGE_RATE := 1.0;
            v_CHARGE.CHARGE_AMOUNT := v_CHARGE.CHARGE_QUANTITY;
            -- get bill quantity and amount
            PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_CHARGE);
            -- store this record
            PC.PUT_FORMULA_CHARGE(v_CHARGE);

        END LOOP;
    END LOOP;

END EXTRACT_UD_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_DA_GFACO_CHARGE
	(
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_DET_TYP_ID IN VARCHAR2,
    p_WORK_ID IN NUMBER
    ) AS

v_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_PRICE1 NUMBER;
v_PRICE2 NUMBER;
v_POR VARCHAR2(32);


CURSOR c_NODES IS
SELECT DISTINCT DP_ND_ID POD, SNK_ND_ID, SRC_ND_ID
 FROM MISO_DET_WORK
 WHERE WORK_ID=p_WORK_ID
 AND DP_ND_ID IS NOT NULL
 AND DET_TYPE = g_ASSET_INTERVAL_DET
 AND DET_TYP_ID = 'DA_GFACO';

 --gather sales and purchases
 CURSOR C_SP(p_POD IN VARCHAR2, p_POR IN VARCHAR2) IS
 SELECT INT_NUM,
 	SUM(CASE
	    WHEN SRC_ND_ID = p_POR and
      VAL > 0 THEN
        	VAL
		ELSE
        	0
		END) "SALES",
 	SUM(CASE
	     WHEN SNK_nd_id = p_POR and
      VAL > 0 THEN
        	VAL
		ELSE
        	0
		END) "PURCHASES"
		FROM MISO_DET_WORK
		WHERE WORK_ID = p_WORK_ID
			AND DET_TYPE = g_ASSET_INTERVAL_DET
			AND DET_TYP_ID = 'DA_GFACO'
		  AND DP_ND_ID = p_POD
 GROUP BY INT_NUM
 ORDER BY 1;

BEGIN

    v_ITERATOR_NAME.CHARGE_ID := p_CHARGE_ID;
	  v_ITERATOR_NAME.ITERATOR_NAME1 := 'POD';
  	v_ITERATOR_NAME.ITERATOR_NAME2 := 'POR';
  	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
  	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
  	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
  	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

  	v_ITERATOR.CHARGE_ID := p_CHARGE_ID;
  	v_ITERATOR.ITERATOR_ID := 0;
  	v_ITERATOR.ITERATOR1 := NULL;
  	v_ITERATOR.ITERATOR2 := NULL;
  	v_ITERATOR.ITERATOR3 := NULL;
  	v_ITERATOR.ITERATOR4 := NULL;
  	v_ITERATOR.ITERATOR5 := NULL;

    v_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_CHARGE.CHARGE_FACTOR := 1.0;
    	v_VAR.CHARGE_ID := p_CHARGE_ID;
    -- loop through nodes
    FOR v_NODE IN c_NODES LOOP

     IF v_NODE.SNK_ND_ID IS NULL THEN
        v_POR := v_NODE.SRC_ND_ID;
      ELSE
        v_POR := v_NODE.SNK_ND_ID;
      END IF;

		  -- setup sub-interval for node
		  v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
		  v_ITERATOR.ITERATOR1 := v_NODE.POD;
			v_ITERATOR.ITERATOR2 := v_POR;
		  PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		  v_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
      v_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

      -- loop through hourly info
      FOR v_SP IN c_SP(v_NODE.POD, v_POR) LOOP
        BEGIN
          SELECT VAL
          INTO v_PRICE1
          FROM MISO_DET_WORK
          WHERE INT_NUM = v_SP.INT_NUM
          AND DET_TYP_ID = p_DET_TYP_ID
          AND DP_ND_ID = v_NODE.POD
          AND WORK_ID = p_WORK_ID;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          v_PRICE1 := 0;
        END;

        BEGIN
          SELECT VAL
          INTO v_PRICE2
          FROM MISO_DET_WORK
          WHERE INT_NUM = v_SP.INT_NUM
          AND DET_TYP_ID = p_DET_TYP_ID
          AND DP_ND_ID = v_POR
          AND WORK_ID = p_WORK_ID;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          v_PRICE2 := 0;
        END;

    	  v_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_SP.INT_NUM/24;
        v_VAR.CHARGE_DATE:= p_STATEMENT_DATE+v_SP.INT_NUM/24;

        v_CHARGE.CHARGE_QUANTITY := v_SP.PURCHASES * (v_PRICE1-v_PRICE2) + v_SP.SALES * (v_PRICE2-v_PRICE1);
        v_CHARGE.CHARGE_RATE := 1.0;
			  v_CHARGE.CHARGE_AMOUNT := v_CHARGE.CHARGE_QUANTITY;

        -- get bill quantity and amount
        PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_CHARGE);
        -- store this record
        PC.PUT_FORMULA_CHARGE(v_CHARGE);

        v_VAR.VARIABLE_NAME := 'Purchases';
			  v_VAR.VARIABLE_VAL := v_SP.PURCHASES ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'Sales';
			  v_VAR.VARIABLE_VAL := v_SP.SALES ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'Price2';
			  v_VAR.VARIABLE_VAL := v_PRICE2;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'Price1';
			  v_VAR.VARIABLE_VAL := v_PRICE1 ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

      END LOOP;

    END LOOP;
END EXTRACT_DA_GFACO_CHARGE;
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_RT_GFACO_CHARGE
	(
    p_CHARGE_ID IN NUMBER,
    p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_DET_TYP_ID IN VARCHAR2,
    p_WORK_ID IN NUMBER
    ) AS

v_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_PRICE1 NUMBER;
v_PRICE2 NUMBER;
v_POR VARCHAR2(32);

 CURSOR c_NODES IS
 SELECT DISTINCT DP_ND_ID POD, SRC_ND_ID, SNK_ND_ID
 FROM MISO_DET_WORK
 WHERE WORK_ID=p_WORK_ID
 AND DP_ND_ID IS NOT NULL
 AND DET_TYPE = g_ASSET_INTERVAL_DET
 AND DET_TYP_ID = 'RT_GFACO';

 --gather sales and purchases: RT and DA
 CURSOR C_SP(p_POD IN VARCHAR2, p_POR IN VARCHAR2) IS
 SELECT INT_NUM "CHARGE_HOUR",
		NVL(SUM(CASE
    	    WHEN DET_TYP_ID = 'RT_GFACO' AND
				  	   SRC_ND_ID = p_POR  THEN
				VAL
    		ELSE
            	0
    		END), 0) "RTSALES",
     	NVL(SUM(CASE
    	    WHEN DET_TYP_ID = 'DA_GFACO'  AND
				  	   SRC_ND_ID = p_POR THEN
			VAL
    		ELSE
            	0
    		END), 0) "DASALES",
     NVL(SUM(CASE
    	    WHEN DET_TYP_ID = 'RT_GFACO' AND
				  	   SNK_ND_ID = p_POR THEN
				VAL
    		ELSE
            	0
    		END), 0) "RTPURCHASES",
     		NVL(SUM(CASE
    	    WHEN DET_TYP_ID = 'DA_GFACO'  AND

				  	   SNK_ND_ID = p_POR THEN
			VAL
    		ELSE
            	0
    		END), 0) "DAPURCHASES"
    FROM MISO_DET_WORK
	  WHERE WORK_ID = p_WORK_ID
    AND DET_TYPE = g_ASSET_INTERVAL_DET
		AND DP_ND_ID = p_POD
    GROUP BY INT_NUM
    ORDER BY 1;

BEGIN

    v_ITERATOR_NAME.CHARGE_ID := p_CHARGE_ID;
	  v_ITERATOR_NAME.ITERATOR_NAME1 := 'POD';
  	v_ITERATOR_NAME.ITERATOR_NAME2 := 'POR';
  	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
  	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
  	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
  	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

  	v_ITERATOR.CHARGE_ID := p_CHARGE_ID;
  	v_ITERATOR.ITERATOR_ID := 0;
  	v_ITERATOR.ITERATOR1 := NULL;
  	v_ITERATOR.ITERATOR2 := NULL;
  	v_ITERATOR.ITERATOR3 := NULL;
  	v_ITERATOR.ITERATOR4 := NULL;
  	v_ITERATOR.ITERATOR5 := NULL;

    v_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_CHARGE.CHARGE_FACTOR := 1.0;
    v_VAR.CHARGE_ID := p_CHARGE_ID;


    -- loop through nodes
    FOR v_NODE IN c_NODES LOOP

      IF v_NODE.SNK_ND_ID IS NULL THEN
        v_POR := v_NODE.SRC_ND_ID;
      ELSE
        v_POR := v_NODE.SNK_ND_ID;
      END IF;

		  -- setup sub-interval for node
		  v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
		  v_ITERATOR.ITERATOR1 := v_NODE.POD;
			v_ITERATOR.ITERATOR2 := v_POR;
		  PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		  v_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
      v_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

      -- loop through hourly info
      FOR v_SP IN c_SP(v_NODE.POD, v_POR) LOOP
        BEGIN
          SELECT VAL
          INTO v_PRICE1
          FROM MISO_DET_WORK
          WHERE INT_NUM = v_SP.CHARGE_HOUR
          AND DET_TYP_ID = p_DET_TYP_ID
          AND DP_ND_ID = v_NODE.POD
          AND WORK_ID = p_WORK_ID;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          v_PRICE1 := 0;
        END;

        BEGIN
          SELECT VAL
          INTO v_PRICE2
          FROM MISO_DET_WORK
          WHERE INT_NUM = v_SP.CHARGE_HOUR
          AND DET_TYP_ID = p_DET_TYP_ID
          AND DP_ND_ID = v_POR
          AND WORK_ID = p_WORK_ID;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          v_PRICE2 := 0;
        END;

    	  v_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_SP.CHARGE_HOUR/24;
        v_VAR.Charge_Date:= p_STATEMENT_DATE+v_SP.CHARGE_HOUR/24;

        v_CHARGE.CHARGE_QUANTITY := (v_SP.RTPURCHASES - v_SP.DAPURCHASES) * (v_PRICE1-v_PRICE2) + (v_SP.RTSALES - v_SP.DASALES) * (v_PRICE2-v_PRICE1);
        v_CHARGE.CHARGE_RATE := 1.0;
			  v_CHARGE.CHARGE_AMOUNT := v_CHARGE.CHARGE_QUANTITY;

        -- get bill quantity and amount
        PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_CHARGE);
        -- store this record
        PC.PUT_FORMULA_CHARGE(v_CHARGE);

        v_VAR.VARIABLE_NAME := 'DAPurchases';
			  v_VAR.VARIABLE_VAL := v_SP.DAPURCHASES ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'RTPurchases';
			  v_VAR.VARIABLE_VAL := v_SP.RTPURCHASES ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'DASales';
			  v_VAR.VARIABLE_VAL := v_SP.DASALES ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'Price2';
			  v_VAR.VARIABLE_VAL := v_PRICE2;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'Price1';
			  v_VAR.VARIABLE_VAL := v_PRICE1 ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'RTSales';
			  v_VAR.VARIABLE_VAL := v_SP.RTSALES ;
			  PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

      END LOOP;

    END LOOP;
END EXTRACT_RT_GFACO_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_FTR_ALC_CHARGE
	(
	p_CHARGE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_ALC_TYPE IN VARCHAR2,
    p_WORK_ID IN NUMBER
    ) AS

v_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_AO_FTR_SHORTFALL NUMBER;
v_MISO_FTR_SHORTFALL NUMBER;
v_MISO_CG_FND NUMBER;
v_INTERVAL VARCHAR2(2) := CASE WHEN p_ALC_TYPE = 'MN' THEN 'MM' ELSE 'Y' END;
v_MARKET_PRICE_ID NUMBER(9);

	FUNCTION IS_END_OF_INTERVAL_DATE
		(
		p_DATE IN DATE,
		p_INTERVAL IN VARCHAR2
		) RETURN BOOLEAN IS
		v_RTN BOOLEAN := FALSE;
	BEGIN
		IF p_INTERVAL = 'MM' THEN
			v_RTN := TRUNC(p_DATE) = LAST_DAY(p_DATE);
		ELSIF p_INTERVAL = 'YY' THEN
			v_RTN := TRUNC(p_DATE) = ADD_MONTHS(TRUNC(p_DATE, 'Y'), 12) - 1;
		END IF;
		RETURN v_RTN;
	END IS_END_OF_INTERVAL_DATE;
BEGIN

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('EXTRACT_FTR_ALC_CHARGE');
		LOGS.LOG_DEBUG('ALC_TYPE=' || p_ALC_TYPE);
	END IF;

	-- Only run

	-- Get determinants from work table
    SELECT NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'AO_FTR_' || p_ALC_TYPE || '_SHORTFALL' THEN VAL
	    		ELSE NULL
	    		END), 0) "AO_FTR_SHORTFALL",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'MISO_FTR_' || p_ALC_TYPE || '_SHORTFALL' THEN VAL
	    		ELSE NULL
	    		END), 0) "MISO_FTR_SHORTFALL",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'MISO_' || p_ALC_TYPE || '_CG_FND' THEN VAL
	    		ELSE NULL
	    		END), 0) "MISO_CG_FND"
	INTO v_AO_FTR_SHORTFALL, v_MISO_FTR_SHORTFALL, v_MISO_CG_FND
    FROM MISO_DET_WORK A
	WHERE WORK_ID = p_WORK_ID
		AND ((DET_TYPE = g_MKT_DET
			  AND DET_TYP_ID IN ('MISO_FTR_' || p_ALC_TYPE || '_SHORTFALL','MISO_' || p_ALC_TYPE || '_CG_FND'))
			 OR
			 (DET_TYPE = g_AO_DET
			  AND A.DET_TYP_ID IN ('AO_FTR_' || p_ALC_TYPE || '_SHORTFALL')));

	--Initialize the charge and formula variable objects
	v_CHARGE.CHARGE_ID := p_CHARGE_ID;
	v_CHARGE.CHARGE_FACTOR := 1.0;
	v_CHARGE.CHARGE_DATE := TRUNC(p_STATEMENT_DATE, v_INTERVAL) + 1/86400;
	v_CHARGE.ITERATOR_ID := 0;
	v_VAR.CHARGE_ID := p_CHARGE_ID;
	v_VAR.ITERATOR_ID := 0;
	v_VAR.CHARGE_DATE := TRUNC(p_STATEMENT_DATE, v_INTERVAL) + 1/86400;

	--Put the MISO_FTR_MN_SHORTFALL as a market price and a data input.
	v_VAR.VARIABLE_NAME := 'MISOFTRShortfall';
	v_VAR.VARIABLE_VAL := v_MISO_FTR_SHORTFALL;
	PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
	IF IS_END_OF_INTERVAL_DATE(p_STATEMENT_DATE, v_INTERVAL) THEN
  		v_MARKET_PRICE_ID := GET_PRICE_ID('MISO:MISO_FTR_' || p_ALC_TYPE || '_SHORTFALL',
				CASE p_ALC_TYPE WHEN 'MN' THEN 'MISO Monthly FTR Shortfall Amount' ELSE 'MISO Yearly FTR Shortfall Amount' END,
				CASE p_ALC_TYPE WHEN 'MN' THEN 'Month' ELSE 'Year' END);
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, 'A', TRUNC(p_STATEMENT_DATE, v_INTERVAL), v_MISO_FTR_SHORTFALL);
	END IF;

	--Put the MISO_MN_CG_FND as a market price and a data input.
	v_VAR.VARIABLE_NAME := 'MISOExcessCongestion';
	v_VAR.VARIABLE_VAL := v_MISO_CG_FND;
	PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
	IF IS_END_OF_INTERVAL_DATE(p_STATEMENT_DATE, v_INTERVAL) THEN
  		v_MARKET_PRICE_ID := GET_PRICE_ID('MISO:MISO_' || p_ALC_TYPE || '_CG_FND',
				CASE p_ALC_TYPE WHEN 'MN' THEN 'MISO Monthly Accum Excess Congestion Funds' ELSE 'MISO Yearly Accum Excess Congestion Funds' END,
				CASE p_ALC_TYPE WHEN 'MN' THEN 'Month' ELSE 'Year' END);
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, 'A', TRUNC(p_STATEMENT_DATE, v_INTERVAL), v_MISO_CG_FND);
	END IF;

	--Put the AO_FTR_MN_SHORTFALL as a variable.
	v_VAR.VARIABLE_NAME := 'AOFTRShortfall';
	v_VAR.VARIABLE_VAL := v_AO_FTR_SHORTFALL;
	PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

	-- compute effective charge quantity and dollar charge amount
	v_CHARGE.CHARGE_QUANTITY := LEAST(v_MISO_CG_FND / v_MISO_FTR_SHORTFALL, 1);
	v_CHARGE.CHARGE_RATE := -1 * v_AO_FTR_SHORTFALL;
	v_CHARGE.CHARGE_AMOUNT := v_CHARGE.CHARGE_QUANTITY * v_CHARGE.CHARGE_RATE;

	-- get bill quantity and amount
	PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID, v_CHARGE);

	-- store this record
	PC.PUT_FORMULA_CHARGE(v_CHARGE);

END EXTRACT_FTR_ALC_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_DA_RSG_DIST
	(
	p_CHARGE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_SCHED_TYPE IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS

v_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_MISO_DA_RSG_MWP_MP NUMBER(9);
v_MISO_RSG_DIST_VOL_TX NUMBER(9);

-- gather determinants
CURSOR c_DETS IS
    SELECT INT_NUM "CHARGE_HOUR",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'MISO_DA_RSG_MWP' THEN VAL
	    		ELSE NULL
	    		END), 0) "MISO_DA_RSG_MWP",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'DA_RSG_DIST_VOL' THEN VAL
	    		ELSE NULL
	    		END), 0) "DA_RSG_DIST_VOL",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'MISO_DA_RSG_DIST_VOL' THEN VAL
	    		ELSE NULL
	    		END), 0) "MISO_DA_RSG_DIST_VOL"
    FROM MISO_DET_WORK A
	WHERE WORK_ID = p_WORK_ID
		AND ((DET_TYPE = g_MKT_INTERVAL_DET
			  AND DET_TYP_ID IN ('MISO_DA_RSG_MWP','MISO_DA_RSG_DIST_VOL'))
			 OR
			 (DET_TYPE = g_AO_INTERVAL_DET
			  AND A.DET_TYP_ID IN ('DA_RSG_DIST_VOL')))
    GROUP BY INT_NUM
    ORDER BY 1;

BEGIN
    v_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_CHARGE.CHARGE_FACTOR := 1.0;
	v_VAR.CHARGE_ID := p_CHARGE_ID;

	v_CHARGE.ITERATOR_ID := 0;
	v_VAR.ITERATOR_ID := 0;

	v_MISO_RSG_DIST_VOL_TX := GET_TX_ID('MISO:MISO_DA_RSG_DIST_VOL', 'Market Result', 'MISO:Hourly MISO DA RSG Distribution Volume', 'Hour');
	v_MISO_DA_RSG_MWP_MP := GET_PRICE_ID('MISO:MISO_DA_RSG_MWP', 'MISO Hourly DA RSG Make Whole Payment Amount', 'Hour');

	-- loop through hourly info
	FOR v_DETS IN c_DETS LOOP
		v_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_DETS.CHARGE_HOUR/24;
		v_VAR.CHARGE_DATE := v_CHARGE.CHARGE_DATE;

		v_VAR.VARIABLE_NAME := 'MISO_RSGDistVol';
		v_VAR.VARIABLE_VAL := v_DETS.MISO_DA_RSG_DIST_VOL;
		PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
		PUT_SCHEDULE_VALUE(v_MISO_RSG_DIST_VOL_TX, v_CHARGE.CHARGE_DATE, v_DETS.MISO_DA_RSG_DIST_VOL, p_SCHED_TYPE);

		v_VAR.VARIABLE_NAME := 'MISO_RSG_MWPAmt';
		v_VAR.VARIABLE_VAL := v_DETS.MISO_DA_RSG_MWP;
		PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
		PUT_MARKET_PRICE_VALUE(v_MISO_DA_RSG_MWP_MP, 'A', v_CHARGE.CHARGE_DATE, v_DETS.MISO_DA_RSG_MWP);

		v_VAR.VARIABLE_NAME := 'RSGDistVol';
		v_VAR.VARIABLE_VAL := v_DETS.DA_RSG_DIST_VOL;
		PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

		-- compute effective charge quantity and dollar charge amount
		v_CHARGE.CHARGE_QUANTITY := v_DETS.DA_RSG_DIST_VOL / v_DETS.MISO_DA_RSG_DIST_VOL;
		v_CHARGE.CHARGE_RATE := -1 * v_DETS.MISO_DA_RSG_MWP;
		v_CHARGE.CHARGE_AMOUNT := v_CHARGE.CHARGE_QUANTITY * v_CHARGE.CHARGE_RATE;
		-- get bill quantity and amount
		PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_CHARGE);
		-- store this record
		PC.PUT_FORMULA_CHARGE(v_CHARGE);
	END LOOP;

END EXTRACT_DA_RSG_DIST;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_RT_RSG_DIST
	(
	p_ISO_SOURCE IN VARCHAR2,
	p_CHARGE_ID IN NUMBER,
	p_STATEMENT_DATE IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_SCHED_TYPE IN NUMBER,
    p_WORK_ID IN NUMBER
    ) AS

v_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_MISO_RT_RSG_DIST_MP NUMBER(9);
v_RSG_ELIG_TX NUMBER(9);
v_PREV_POD_ID NUMBER(9) := -999;
v_CONTRACT_ID NUMBER(9);

-- gather asset owner and market level determinants.
CURSOR c_DETS IS
    SELECT INT_NUM "CHARGE_HOUR",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'MISO_RT_RSG_DIST_RATE' THEN VAL
	    		ELSE NULL
	    		END), 0) "MISO_RT_RSG_DIST_RATE",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'RT_RSG_DIST_VOL' THEN VAL
	    		ELSE NULL
	    		END), 0) "RT_RSG_DIST_VOL"
    FROM MISO_DET_WORK A
	WHERE WORK_ID = p_WORK_ID
		AND ((DET_TYPE = g_MKT_INTERVAL_DET
			  AND DET_TYP_ID IN ('MISO_RT_RSG_DIST_RATE'))
			 OR
			 (DET_TYPE = g_AO_INTERVAL_DET
			  AND A.DET_TYP_ID IN ('RT_RSG_DIST_VOL')))
    GROUP BY INT_NUM
    ORDER BY 1;

-- gather node determinants.
CURSOR c_NODE_DETS IS
    SELECT B.SERVICE_POINT_ID "POD_ID", DP_ND_ID, INT_NUM "CHARGE_HOUR",
		NVL(MAX(CASE
	    	    WHEN DET_TYP_ID = 'RT_RSG_ELIGIBILITY' THEN VAL
	    		ELSE NULL
	    		END), 0) "RT_RSG_ELIGIBILITY"
    FROM MISO_DET_WORK A, SERVICE_POINT B
	WHERE WORK_ID = p_WORK_ID
		AND DET_TYPE = g_ASSET_INTERVAL_DET
		AND A.DET_TYP_ID IN ('RT_RSG_ELIGIBILITY')
		AND B.EXTERNAL_IDENTIFIER = A.DP_ND_ID
    GROUP BY B.SERVICE_POINT_ID, DP_ND_ID, INT_NUM
    ORDER BY 1;

BEGIN
	v_CONTRACT_ID := ID_FOR_MISO_CONTRACT(p_ISO_SOURCE);
    v_CHARGE.CHARGE_ID := p_CHARGE_ID;
    v_CHARGE.CHARGE_FACTOR := 1.0;
	v_VAR.CHARGE_ID := p_CHARGE_ID;

	v_CHARGE.ITERATOR_ID := 0;
	v_VAR.ITERATOR_ID := 0;

	--Get nodal info (set RT_RSG_ELIGIBILITY flag)
	FOR v_NODE_DETS IN c_NODE_DETS LOOP
		--Save the RT_RSG_ELIGIBILITY flag to a transaction.
		IF v_PREV_POD_ID <> v_NODE_DETS.POD_ID THEN
			v_RSG_ELIG_TX := GET_TX_ID(NULL, 'RSG Elig Flag', 'MISO RSG Elig: '||v_NODE_DETS.DP_ND_ID, 'Hour', v_CONTRACT_ID, v_NODE_DETS.POD_ID);
			v_PREV_POD_ID := v_NODE_DETS.POD_ID;
		END IF;
		PUT_SCHEDULE_VALUE(v_RSG_ELIG_TX, p_STATEMENT_DATE+v_NODE_DETS.CHARGE_HOUR/24, v_NODE_DETS.RT_RSG_ELIGIBILITY, p_SCHED_TYPE);
	END LOOP;

	v_MISO_RT_RSG_DIST_MP := GET_PRICE_ID('MISO:MISO_RT_RSG_DIST_RATE', 'MISO Hourly RT RSG Dist Rate', 'Hour');

	--Get market and asset owner level info
	FOR v_DETS IN c_DETS LOOP
		v_CHARGE.CHARGE_DATE := p_STATEMENT_DATE+v_DETS.CHARGE_HOUR/24;
		v_VAR.CHARGE_DATE := v_CHARGE.CHARGE_DATE;

		v_VAR.VARIABLE_NAME := 'MISO_RSGDistRate';
		v_VAR.VARIABLE_VAL := v_DETS.MISO_RT_RSG_DIST_RATE;
		PC.PUT_FORMULA_CHARGE_VAR(v_VAR);
		PUT_MARKET_PRICE_VALUE(v_MISO_RT_RSG_DIST_MP, 'A', v_CHARGE.CHARGE_DATE, v_DETS.MISO_RT_RSG_DIST_RATE);

		v_VAR.VARIABLE_NAME := 'RSGDistVol';
		v_VAR.VARIABLE_VAL := v_DETS.RT_RSG_DIST_VOL;
		PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

		-- compute effective charge quantity and dollar charge amount
		v_CHARGE.CHARGE_QUANTITY := v_DETS.RT_RSG_DIST_VOL;
		v_CHARGE.CHARGE_RATE := v_DETS.MISO_RT_RSG_DIST_RATE;
		v_CHARGE.CHARGE_AMOUNT := v_CHARGE.CHARGE_QUANTITY * v_CHARGE.CHARGE_RATE;
		-- get bill quantity and amount
		PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID,v_CHARGE);
		-- store this record
		PC.PUT_FORMULA_CHARGE(v_CHARGE);
	END LOOP;

END EXTRACT_RT_RSG_DIST;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_SCHD_24_ALC_CHARGE
    (
    p_CHARGE_ID       IN NUMBER,
    p_STATEMENT_DATE  IN DATE,
    p_PRIOR_CHARGE_ID IN NUMBER,
    p_MARKET          IN VARCHAR2,
    p_RATE_ID         IN VARCHAR2,
    p_WORK_ID         IN NUMBER
    ) AS
v_FML_CHARGE FORMULA_CHARGE%ROWTYPE;
v_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_MKT_PRICE_ID MARKET_PRICE.MARKET_PRICE_ID%TYPE;
CURSOR c_CHARGES IS
    SELECT CHARGE_HOUR, ADMIN_VOL, SCHED_RATE
        FROM (SELECT A.INT_NUM "CHARGE_HOUR", A.VAL "ADMIN_VOL", B.VAL "SCHED_RATE"
        FROM MISO_DET_WORK A, MISO_DET_WORK B
        WHERE A.WORK_ID = p_WORK_ID
        AND A.DET_TYPE = g_AO_INTERVAL_DET
        AND A.DET_TYP_ID = p_MARKET || '_ADMIN_VOL'
        AND B.WORK_ID = p_WORK_ID
        AND B.DET_TYPE = g_MKT_INTERVAL_DET
        AND B.DET_TYP_ID = p_RATE_ID
        AND B.INT_NUM = A.INT_NUM)
        ORDER BY 1;

BEGIN
	v_MKT_PRICE_ID := GET_PRICE_ID('MISO:' || p_RATE_ID);

	v_FML_CHARGE.CHARGE_ID      := p_CHARGE_ID;
	v_FML_CHARGE.ITERATOR_ID := 0;
	v_FML_CHARGE.CHARGE_FACTOR  := 1.0;

    v_VAR.CHARGE_ID := p_CHARGE_ID;
    v_VAR.ITERATOR_ID := 0;

	FOR v_CHARGE IN c_CHARGES LOOP
    	v_VAR.CHARGE_DATE := p_STATEMENT_DATE + v_CHARGE.CHARGE_HOUR / 24;
        v_VAR.VARIABLE_NAME := p_MARKET || '_Admin_Vol';
        v_VAR.VARIABLE_VAL := NVL(v_CHARGE.ADMIN_VOL, 0);
        PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

        v_VAR.VARIABLE_NAME := 'Schedule 24 Alloc Rate';
		v_VAR.VARIABLE_VAL := NVL(v_CHARGE.SCHED_RATE, 0);
		PC.PUT_FORMULA_CHARGE_VAR(v_VAR);

		v_FML_CHARGE.CHARGE_DATE     := p_STATEMENT_DATE + v_CHARGE.CHARGE_HOUR / 24;
		v_FML_CHARGE.CHARGE_QUANTITY := NVL(v_CHARGE.ADMIN_VOL, 0);
		v_FML_CHARGE.CHARGE_RATE     := NVL(v_CHARGE.SCHED_RATE, 0);
		-- compute dollar charge amount
		v_FML_CHARGE.CHARGE_AMOUNT := v_FML_CHARGE.CHARGE_RATE *
																	v_FML_CHARGE.CHARGE_FACTOR *
																	v_FML_CHARGE.CHARGE_QUANTITY;
		-- get bill quantity and amount
		PC.PRIOR_FORMULA_CHARGE(p_PRIOR_CHARGE_ID, v_FML_CHARGE);
		-- store this record
		PC.PUT_FORMULA_CHARGE(v_FML_CHARGE);

    -- add the rate to the market price for the shadow
    PUT_MARKET_PRICE_VALUE(v_MKT_PRICE_ID, 'A', v_FML_CHARGE.CHARGE_DATE, v_CHARGE.SCHED_RATE);
	END LOOP;
END EXTRACT_SCHD_24_ALC_CHARGE;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_CHARGE_DETAILS
	(
	p_ISO_SOURCE IN VARCHAR2,
    p_BILLING_STATEMENT IN OUT NOCOPY BILLING_STATEMENT%ROWTYPE,
    p_CHARGE_TYPE_CODE IN VARCHAR2,
	p_WORK_ID IN NUMBER,
    p_SCHED_TYPE IN NUMBER
    ) AS
v_PRIOR_CHARGE_ID NUMBER;
BEGIN
	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('EXTRACT_CHARGE_DETAILS ' || p_CHARGE_TYPE_CODE || ' STARTED ' || UT.TRACE_DATE(SYSDATE));
	END IF;
    v_PRIOR_CHARGE_ID := PC.GET_PRIOR_CHARGE_ID(p_BILLING_STATEMENT);

    CASE UPPER(p_CHARGE_TYPE_CODE)
    WHEN 'DA_FIN_CG' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP4';
        EXTRACT_BILAT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 1, 'CG', p_WORK_ID);
    WHEN 'DA_FIN_LS' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP4';
        EXTRACT_BILAT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 1, 'LS', p_WORK_ID);
    WHEN 'DA_NASSET_EN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP6';
        EXTRACT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 1, 1, 0, p_WORK_ID);
    WHEN 'DA_ASSET_EN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP1';
        EXTRACT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 1, 0, 0, p_WORK_ID);
    WHEN 'DA_VIRT_EN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP3';
        EXTRACT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 1, 0, 1, p_WORK_ID);
    WHEN 'RT_FIN_CG' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP5';
        EXTRACT_BILAT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 0, 'CG', p_WORK_ID);
    WHEN 'RT_FIN_LS' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP5';
        EXTRACT_BILAT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 0, 'LS', p_WORK_ID);
    WHEN 'RT_NASSET_EN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP7';
        EXTRACT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 0, 1, 0, p_WORK_ID);
    WHEN 'RT_ASSET_EN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP2';
        EXTRACT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 0, 0, 0, p_WORK_ID);
    WHEN 'RT_VIRT_EN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'LMP3';
        EXTRACT_LMP_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 0, 0, 1, p_WORK_ID);
    WHEN 'FTR_HR_ALC' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FTR ALLOC';
        EXTRACT_FTR_CHARGE(p_ISO_SOURCE, p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_SCHED_TYPE, p_WORK_ID);
    WHEN 'FTR_TXN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'TRANSMISSION';
        EXTRACT_AUCTION_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_WORK_ID);
    WHEN 'DA_ADMIN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'COMBINATION';
        EXTRACT_DA_ADMIN_CHARGE(p_BILLING_STATEMENT, v_PRIOR_CHARGE_ID, p_WORK_ID);
    WHEN 'RT_ADMIN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
        EXTRACT_ADMIN_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'RT', 'ENERGY_MKT_RATE', p_WORK_ID);
    WHEN 'FTR_ADMIN' THEN
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
        EXTRACT_ADMIN_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'FTR', 'FTR_ADMIN_RATE', p_WORK_ID);
    WHEN 'RT_NI_DIST' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
      EXTRACT_NI_DIST_CHARGE(p_ISO_SOURCE, p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_SCHED_TYPE, p_WORK_ID);
    WHEN 'RT_RNU' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'COMBINATION';
      EXTRACT_RNU_CHARGE(p_ISO_SOURCE, p_BILLING_STATEMENT, v_PRIOR_CHARGE_ID, p_WORK_ID);
    WHEN 'RT_LOSS_DIST' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
      EXTRACT_LOSS_DIST_CHARGE(p_ISO_SOURCE, p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_SCHED_TYPE, p_WORK_ID);
    WHEN 'RT_UD' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
      EXTRACT_UD_CHARGE(p_ISO_SOURCE, p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_SCHED_TYPE, p_WORK_ID);
     WHEN 'DA_GFACO_RBT_LS' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
      EXTRACT_DA_GFACO_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'DA_LMP_LS', p_WORK_ID);
    WHEN 'DA_GFACO_RBT_CG' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
      EXTRACT_DA_GFACO_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'DA_LMP_CG', p_WORK_ID);
    WHEN 'DA_SCHD_24_ALC' THEN
       p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
  		EXTRACT_SCHD_24_ALC_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'DA', 'SCHD_24_ALC_RATE', p_WORK_ID);
    WHEN 'RT_GFACO_RBT_LS' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
      EXTRACT_RT_GFACO_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'RT_LMP_LS', p_WORK_ID);
    WHEN 'RT_GFACO_RBT_CG' THEN
      p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
      EXTRACT_RT_GFACO_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'RT_LMP_CG', p_WORK_ID);
  	WHEN 'FTR_MN_ALC' THEN
  		p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
  		p_BILLING_STATEMENT.CHARGE_INTERVAL := 'Month';
  		EXTRACT_FTR_ALC_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'MN', p_WORK_ID);
  	WHEN 'FTR_YR_ALC' THEN
  		p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
  		p_BILLING_STATEMENT.CHARGE_INTERVAL := 'Year';
  		EXTRACT_FTR_ALC_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'YR', p_WORK_ID);
  	WHEN 'DA_RSG_DIST' THEN
  		p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
  		EXTRACT_DA_RSG_DIST(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_SCHED_TYPE, p_WORK_ID);
  	WHEN 'RT_RSG_DIST1' THEN
  		p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
  		EXTRACT_RT_RSG_DIST(p_ISO_SOURCE, p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, p_SCHED_TYPE, p_WORK_ID);
    WHEN 'RT_SCHD_24_ALC' THEN
       p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'FORMULA';
  		EXTRACT_SCHD_24_ALC_CHARGE(p_BILLING_STATEMENT.CHARGE_ID, p_BILLING_STATEMENT.STATEMENT_DATE, v_PRIOR_CHARGE_ID, 'RT', 'SCHD_24_ALC_RATE', p_WORK_ID);
	ELSE
    	p_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'BILLING CHARGE';
    END CASE;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('END EXTRACT_CHARGE_DETAILS ');
	END IF;
END EXTRACT_CHARGE_DETAILS;
---------------------------------------------------------------------------------------------------
PROCEDURE DUMP_DETS_TO_WORK
	(
	p_WORK_ID IN NUMBER,
	p_STATEMENT IN XMLTYPE
	) AS
-- FIRST grab the asset owner determinants
--    we'll get the non-interval data
CURSOR c_ASSET_OWNER_DETS IS
	SELECT p_WORK_ID "WORK_ID",
		g_AO_DET "DET_TYPE",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/DET_TYP_ID', g_MISO_NAMESPACE) "DET_TYP_ID",
		NULL "ASSET_NM",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SRC_ND_ID', g_MISO_NAMESPACE) "SRC_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SNK_ND_ID', g_MISO_NAMESPACE) "SNK_ND_ID",
		NVL(EXTRACTVALUE(VALUE(X), '/DET_TYP/DEL_ND_ID', g_MISO_NAMESPACE), EXTRACTVALUE(VALUE(X), '/DET_TYP/ND_ID', g_MISO_NAMESPACE)) "DP_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/TRANSACTION_ID', g_MISO_NAMESPACE) "TX_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/FTR_ID', g_MISO_NAMESPACE) "FTR_ID",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@FTR_TYPE_FL', g_MISO_NAMESPACE) "FTR_TYPE_FL",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@OPT_FL', g_MISO_NAMESPACE) "OPT_FL",
		0 "INT_NUM",
		CASE EXTRACTVALUE(VALUE(X), '/DET_TYP/VAL', g_MISO_NAMESPACE)
			WHEN 'N' THEN 0
			WHEN 'Y' THEN 1
			ELSE TO_NUMBER(REPLACE(EXTRACTVALUE(VALUE(X), '/DET_TYP/VAL', g_MISO_NAMESPACE),',',NULL))
			END "VAL"
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT, '/*/ASSET_OWNER/DET_TYP', g_MISO_NAMESPACE))) X
	WHERE EXTRACTVALUE(VALUE(X), '/DET_TYP/VAL', g_MISO_NAMESPACE) IS NOT NULL;
--    and then we'll get the interval data
CURSOR c_ASSET_OWNER_INTERVAL_DETS IS
	SELECT p_WORK_ID "WORK_ID",
		g_AO_INTERVAL_DET "DET_TYPE",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/DET_TYP_ID', g_MISO_NAMESPACE) "DET_TYP_ID",
		NULL "ASSET_NM",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SRC_ND_ID', g_MISO_NAMESPACE) "SRC_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SNK_ND_ID', g_MISO_NAMESPACE) "SNK_ND_ID",
		NVL(EXTRACTVALUE(VALUE(X), '/DET_TYP/DEL_ND_ID', g_MISO_NAMESPACE), EXTRACTVALUE(VALUE(X), '/DET_TYP/ND_ID', g_MISO_NAMESPACE)) "DP_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/TRANSACTION_ID', g_MISO_NAMESPACE) "TX_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/FTR_ID', g_MISO_NAMESPACE) "FTR_ID",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@FTR_TYPE_FL', g_MISO_NAMESPACE) "FTR_TYPE_FL",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@OPT_FL', g_MISO_NAMESPACE) "OPT_FL",
		TO_NUMBER(EXTRACTVALUE(VALUE(U),'/INT/INT_NUM', g_MISO_NAMESPACE)) "INT_NUM",
		CASE EXTRACTVALUE(VALUE(U),'/INT/VAL', g_MISO_NAMESPACE)
			WHEN 'N' THEN 0
			WHEN 'Y' THEN 1
			ELSE TO_NUMBER(REPLACE(EXTRACTVALUE(VALUE(U), '/INT/VAL', g_MISO_NAMESPACE),',',NULL))
			END "VAL"
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT, '/*/ASSET_OWNER/DET_TYP', g_MISO_NAMESPACE))) X,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(X), '/DET_TYP/INT', g_MISO_NAMESPACE))) U;
-- NEXT grab the asset-specific determinants
--    we'll get the non-interval data
CURSOR c_ASSET_DETS IS
	SELECT p_WORK_ID "WORK_ID",
		g_ASSET_DET "DET_TYPE",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/DET_TYP_ID', g_MISO_NAMESPACE) "DET_TYP_ID",
		EXTRACTVALUE(VALUE(W), '/ASSET/ASSET_NM', g_MISO_NAMESPACE) "ASSET_NM",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SRC_ND_ID', g_MISO_NAMESPACE) "SRC_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SNK_ND_ID', g_MISO_NAMESPACE) "SNK_ND_ID",
		NVL(EXTRACTVALUE(VALUE(X), '/DET_TYP/DEL_ND_ID', g_MISO_NAMESPACE), EXTRACTVALUE(VALUE(X), '/DET_TYP/ND_ID', g_MISO_NAMESPACE)) "DP_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/TRANSACTION_ID', g_MISO_NAMESPACE) "TX_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/FTR_ID', g_MISO_NAMESPACE) "FTR_ID",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@FTR_TYPE_FL', g_MISO_NAMESPACE) "FTR_TYPE_FL",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@OPT_FL', g_MISO_NAMESPACE) "OPT_FL",
		0 "INT_NUM",
		CASE EXTRACTVALUE(VALUE(X), '/DET_TYP/VAL', g_MISO_NAMESPACE)
			WHEN 'N' THEN 0
			WHEN 'Y' THEN 1
			ELSE TO_NUMBER(REPLACE(EXTRACTVALUE(VALUE(X), '/DET_TYP/VAL', g_MISO_NAMESPACE),',',NULL))
			END "VAL"
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT, '/*/ASSET_OWNER/ASSET', g_MISO_NAMESPACE))) W,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(W), '/ASSET/DET_TYP', g_MISO_NAMESPACE))) X
	WHERE EXTRACTVALUE(VALUE(X), '/DET_TYP/VAL', g_MISO_NAMESPACE) IS NOT NULL;
--    and then we'll get the interval data
CURSOR c_ASSET_INTERVAL_DETS IS
	SELECT p_WORK_ID "WORK_ID",
		g_ASSET_INTERVAL_DET "DET_TYPE",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/DET_TYP_ID', g_MISO_NAMESPACE) "DET_TYP_ID",
		EXTRACTVALUE(VALUE(W), '/ASSET/ASSET_NM', g_MISO_NAMESPACE) "ASSET_NM",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SRC_ND_ID', g_MISO_NAMESPACE) "SRC_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/SNK_ND_ID', g_MISO_NAMESPACE) "SNK_ND_ID",
		NVL(EXTRACTVALUE(VALUE(X), '/DET_TYP/DEL_ND_ID', g_MISO_NAMESPACE), EXTRACTVALUE(VALUE(X), '/DET_TYP/ND_ID', g_MISO_NAMESPACE)) "DP_ND_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/TRANSACTION_ID', g_MISO_NAMESPACE) "TX_ID",
		EXTRACTVALUE(VALUE(X), '/DET_TYP/FTR_ID', g_MISO_NAMESPACE) "FTR_ID",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@FTR_TYPE_FL', g_MISO_NAMESPACE) "FTR_TYPE_FL",
		EXTRACTVALUE(VALUE(X),'/DET_TYP/DET_TYP_NM/@OPT_FL', g_MISO_NAMESPACE) "OPT_FL",
		TO_NUMBER(EXTRACTVALUE(VALUE(U),'/INT/INT_NUM', g_MISO_NAMESPACE)) "INT_NUM",
		CASE EXTRACTVALUE(VALUE(U),'/INT/VAL', g_MISO_NAMESPACE)
			WHEN 'N' THEN 0
			WHEN 'Y' THEN 1
			ELSE TO_NUMBER(REPLACE(EXTRACTVALUE(VALUE(U), '/INT/VAL', g_MISO_NAMESPACE),',',NULL))
			END "VAL"
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT, '/*/ASSET_OWNER/ASSET', g_MISO_NAMESPACE))) W,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(W), '/ASSET/DET_TYP', g_MISO_NAMESPACE))) X,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(X), '/DET_TYP/INT', g_MISO_NAMESPACE))) U;
-- FINALLY grab the market-wide determinants
--    we'll get the non-interval data
CURSOR c_MARKET_DETS IS
	SELECT p_WORK_ID "WORK_ID",
		g_MKT_DET "DET_TYPE",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/DET_TYP_ID', g_MISO_NAMESPACE) "DET_TYP_ID",
		NULL "ASSET_NM",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/SRC_ND_ID', g_MISO_NAMESPACE) "SRC_ND_ID",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/SNK_ND_ID', g_MISO_NAMESPACE) "SNK_ND_ID",
		NVL(EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/DEL_ND_ID', g_MISO_NAMESPACE), EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/ND_ID', g_MISO_NAMESPACE)) "DP_ND_ID",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/TRANSACTION_ID', g_MISO_NAMESPACE) "TX_ID",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/FTR_ID', g_MISO_NAMESPACE) "FTR_ID",
		EXTRACTVALUE(VALUE(X),'/MKT_DET_TYP/DET_TYP_NM/@FTR_TYPE_FL', g_MISO_NAMESPACE) "FTR_TYPE_FL",
		EXTRACTVALUE(VALUE(X),'/MKT_DET_TYP/DET_TYP_NM/@OPT_FL', g_MISO_NAMESPACE) "OPT_FL",
		0 "INT_NUM",
		CASE EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/VAL', g_MISO_NAMESPACE)
			WHEN 'N' THEN 0
			WHEN 'Y' THEN 1
			ELSE TO_NUMBER(REPLACE(EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/VAL', g_MISO_NAMESPACE),',',NULL))
			END "VAL"
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT, '/*/MKT_DET_TYP', g_MISO_NAMESPACE))) X
	WHERE EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/VAL', g_MISO_NAMESPACE) IS NOT NULL;
--    and then we'll get the interval data
CURSOR c_MARKET_INTERVAL_DETS IS
	SELECT p_WORK_ID "WORK_ID",
		g_MKT_INTERVAL_DET "DET_TYPE",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/DET_TYP_ID', g_MISO_NAMESPACE) "DET_TYP_ID",
		NULL "ASSET_NM",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/SRC_ND_ID', g_MISO_NAMESPACE) "SRC_ND_ID",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/SNK_ND_ID', g_MISO_NAMESPACE) "SNK_ND_ID",
		NVL(EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/DEL_ND_ID', g_MISO_NAMESPACE), EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/ND_ID', g_MISO_NAMESPACE)) "DP_ND_ID",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/TRANSACTION_ID', g_MISO_NAMESPACE) "TX_ID",
		EXTRACTVALUE(VALUE(X), '/MKT_DET_TYP/FTR_ID', g_MISO_NAMESPACE) "FTR_ID",
		EXTRACTVALUE(VALUE(X),'/MKT_DET_TYP/DET_TYP_NM/@FTR_TYPE_FL', g_MISO_NAMESPACE) "FTR_TYPE_FL",
		EXTRACTVALUE(VALUE(X),'/MKT_DET_TYP/DET_TYP_NM/@OPT_FL', g_MISO_NAMESPACE) "OPT_FL",
		TO_NUMBER(EXTRACTVALUE(VALUE(U),'/INT/INT_NUM', g_MISO_NAMESPACE)) "INT_NUM",
		CASE EXTRACTVALUE(VALUE(U),'/INT/VAL', g_MISO_NAMESPACE)
			WHEN 'N' THEN 0
			WHEN 'Y' THEN 1
			ELSE TO_NUMBER(REPLACE(EXTRACTVALUE(VALUE(U), '/INT/VAL', g_MISO_NAMESPACE),',',NULL))
			END "VAL"
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT, '/*/MKT_DET_TYP', g_MISO_NAMESPACE))) X,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(X), '/MKT_DET_TYP/INT', g_MISO_NAMESPACE))) U;
BEGIN
	-- put all determinants into a work table
	FOR v_DET IN c_ASSET_OWNER_DETS LOOP
		INSERT INTO MISO_DET_WORK VALUES v_DET;
	END LOOP;
	COMMIT;

	FOR v_DET IN c_ASSET_OWNER_INTERVAL_DETS LOOP
		INSERT INTO MISO_DET_WORK VALUES v_DET;
	END LOOP;
	COMMIT;


	FOR v_DET IN c_ASSET_DETS LOOP
		INSERT INTO MISO_DET_WORK VALUES v_DET;
	END LOOP;
	COMMIT;

	FOR v_DET IN c_ASSET_INTERVAL_DETS LOOP
		INSERT INTO MISO_DET_WORK VALUES v_DET;
	END LOOP;
	COMMIT;


	FOR v_DET IN c_MARKET_DETS LOOP
		INSERT INTO MISO_DET_WORK VALUES v_DET;
	END LOOP;
	COMMIT;

	FOR v_DET IN c_MARKET_INTERVAL_DETS LOOP
		INSERT INTO MISO_DET_WORK VALUES v_DET;
	END LOOP;

	COMMIT;

END DUMP_DETS_TO_WORK;
---------------------------------------------------------------------------------------------------
PROCEDURE EXTRACT_BILLING_STATEMENT
	(
	p_ISO_SOURCE IN VARCHAR2,
	p_STATEMENT_NAME IN VARCHAR2,
	p_MARKET_ABBR IN VARCHAR2,
	p_STATEMENT_XML IN XMLTYPE,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_PREV_COMPONENT_ID NUMBER(9) := -999;
v_CUR_COMPONENT_ID NUMBER(9) := -999;
v_CUR_COMPONENT_CODE VARCHAR2(32);
v_PREV_COMPONENT_CODE VARCHAR2(32) := '';
v_ENTITY_ID NUMBER := 0;
v_PRODUCT_ID NUMBER := 0;
v_STATEMENT_TYPE NUMBER := 0;
v_STATEMENT_DATE DATE := LOW_DATE;
v_WORK_ID NUMBER(9) := NULL;

CURSOR c_STATEMENT IS
 SELECT
	EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/ASSET_OWNER_NAME', g_MISO_NAMESPACE) "ASSET_OWNER_NAME",
	EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/ASSET_OWNER_ID', g_MISO_NAMESPACE) "ASSET_OWNER_ID",
	TO_DATE(EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/TIMESTAMP', g_MISO_NAMESPACE), g_DATE_FORMAT) "STATEMENT_DATE",
	TO_DATE(EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/SCHEDULED_DATE', g_MISO_NAMESPACE), g_DATE_FORMAT) "EXECUTION_DATE",
	TO_DATE(EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/OPERATING_DATE', g_MISO_NAMESPACE), g_DATE_FORMAT) "TRADE_DATE",
	EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/SETTLEMENT_CODE', g_MISO_NAMESPACE) "STATEMENT_TYPE_NAME",
	EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/STATEMENT_ID', g_MISO_NAMESPACE) "STATEMENT_IDENT",
	EXTRACT(VALUE(T),'/' || p_STATEMENT_NAME || '/LINE_ITEMS', g_MISO_NAMESPACE) "LINE_ITEMS"
 FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT_XML,'/' || p_STATEMENT_NAME, g_MISO_NAMESPACE))) T;

CURSOR c_LINE_ITEMS(v_LINE_ITEMS_XML IN XMLTYPE) IS
 SELECT
	EXTRACTVALUE(VALUE(T),'/CHG_TYP/CHG_TYP_NM', g_MISO_NAMESPACE) "CHARGE_TYPE_NAME",
	EXTRACTVALUE(VALUE(T),'/CHG_TYP/CHG_TYP_ID', g_MISO_NAMESPACE) "CHARGE_TYPE_CODE",
	EXTRACTVALUE(VALUE(U),'/STLMT_TYP/STLMT_TYP_CD', g_MISO_NAMESPACE) "STATEMENT_TYPE_NAME",
	TO_NUMBER(REPLACE(EXTRACTVALUE(VALUE(U),'/STLMT_TYP/AMT', g_MISO_NAMESPACE),',','')) "BILL_AMOUNT"
 FROM TABLE(XMLSEQUENCE(EXTRACT(v_LINE_ITEMS_XML,'/LINE_ITEMS/CHG_TYP', g_MISO_NAMESPACE))) T,
 	TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'/CHG_TYP/STLMT_TYP', g_MISO_NAMESPACE))) U;

BEGIN

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('EXTRACT_BILLING_STATEMENT ' || p_STATEMENT_NAME || ' STARTED ' || UT.TRACE_DATE(SYSDATE));
	END IF;

	--GO THROUGH MAIN STATEMENT (THERE SHOULD ONLY BE ONE OF THESE.)
	FOR v_STATEMENT IN c_STATEMENT LOOP

		v_BILLING_STATEMENT.ENTITY_ID := ID_FOR_MISO_MP(p_ISO_SOURCE);
		v_BILLING_STATEMENT.PRODUCT_ID := ID_FOR_MISO_PRODUCT(v_STATEMENT.ASSET_OWNER_NAME, p_MARKET_ABBR);
		v_BILLING_STATEMENT.STATEMENT_TYPE := MM_MISO_UTIL.ID_FOR_STATEMENT_TYPE(v_STATEMENT.STATEMENT_TYPE_NAME);
		v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
		v_BILLING_STATEMENT.STATEMENT_DATE := v_STATEMENT.TRADE_DATE;
		v_BILLING_STATEMENT.STATEMENT_END_DATE := v_STATEMENT.TRADE_DATE;
		v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
        -- first time for this statement? then delete existing entries
        IF v_ENTITY_ID <> v_BILLING_STATEMENT.ENTITY_ID OR v_PRODUCT_ID <> v_BILLING_STATEMENT.PRODUCT_ID
           OR v_STATEMENT_TYPE <> v_BILLING_STATEMENT.STATEMENT_TYPE
           OR v_STATEMENT_DATE <> v_BILLING_STATEMENT.STATEMENT_DATE THEN
            DELETE BILLING_STATEMENT WHERE
            	ENTITY_ID = v_BILLING_STATEMENT.ENTITY_ID
                AND PRODUCT_ID = v_BILLING_STATEMENT.PRODUCT_ID
                AND STATEMENT_TYPE = v_BILLING_STATEMENT.STATEMENT_TYPE
                AND STATEMENT_STATE = v_BILLING_STATEMENT.STATEMENT_STATE
                AND STATEMENT_DATE = v_BILLING_STATEMENT.STATEMENT_DATE
                AND AS_OF_DATE = v_BILLING_STATEMENT.AS_OF_DATE;
			COMMIT;
			v_ENTITY_ID := v_BILLING_STATEMENT.ENTITY_ID;
            v_STATEMENT_TYPE := v_BILLING_STATEMENT.STATEMENT_TYPE;
            v_STATEMENT_DATE := v_BILLING_STATEMENT.STATEMENT_DATE;
		END IF;
		v_BILLING_STATEMENT.ENTITY_TYPE := 'PSE';
		v_BILLING_STATEMENT.BASIS_AS_OF_DATE := LOW_DATE;
		v_BILLING_STATEMENT.IN_DISPUTE := 0;
		v_BILLING_STATEMENT.PRIOR_PERIOD_QUANTITY := 0;
		v_BILLING_STATEMENT.CHARGE_INTERVAL := 'Hour';
		v_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'BILLING CHARGE';
		v_BILLING_STATEMENT.CHARGE_RATE := 1;

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('STATEMENT_TYPE=' || v_STATEMENT.STATEMENT_TYPE_NAME);
			LOGS.LOG_DEBUG('STATEMENT_DATE=' || UT.TRACE_DATE(v_STATEMENT.TRADE_DATE));
			LOGS.LOG_DEBUG('ASSET_OWNER_NAME=' || v_STATEMENT.ASSET_OWNER_NAME);
			LOGS.LOG_DEBUG('PRODUCT_ID=' || TO_CHAR(v_BILLING_STATEMENT.PRODUCT_ID));
		END IF;

		-- dump the determinants to work table
		UT.GET_RTO_WORK_ID(v_WORK_ID);
		DUMP_DETS_TO_WORK(v_WORK_ID, p_STATEMENT_XML);

		--LOOP OVER LINE ITEMS WHICH ARE OUR BILLING_STATEMENTS.
		FOR v_LINE_ITEMS IN c_LINE_ITEMS(v_STATEMENT.LINE_ITEMS) LOOP

			--SAVE THE BILLING STATEMENT AND RESET THE TOTALS FOR A NEW ONE.
            v_CUR_COMPONENT_CODE := v_LINE_ITEMS.CHARGE_TYPE_CODE;
			v_CUR_COMPONENT_ID := ID_FOR_MISO_COMPONENT(v_LINE_ITEMS.CHARGE_TYPE_NAME,v_CUR_COMPONENT_CODE);
			IF NOT v_CUR_COMPONENT_ID = v_PREV_COMPONENT_ID THEN
				--SAVE THE PREVIOUS ONE IF IT'S NOT THE FIRST TIME.
				IF v_PREV_COMPONENT_ID > 0 THEN
					PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- put first since it must be persisted in order to fetch bill amounts
					EXTRACT_CHARGE_DETAILS(p_ISO_SOURCE, v_BILLING_STATEMENT, v_PREV_COMPONENT_CODE, v_WORK_ID, v_BILLING_STATEMENT.STATEMENT_TYPE);
					PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT); -- put after also, since the record will be updated from extraction of charge details
					COMMIT;
				END IF;
				v_PREV_COMPONENT_ID := v_CUR_COMPONENT_ID;
                v_PREV_COMPONENT_CODE := v_CUR_COMPONENT_CODE;
				v_BILLING_STATEMENT.COMPONENT_ID := v_CUR_COMPONENT_ID;
				v_BILLING_STATEMENT.CHARGE_QUANTITY := 0;
				v_BILLING_STATEMENT.CHARGE_AMOUNT := 0;
				v_BILLING_STATEMENT.BILL_QUANTITY := 0;
				v_BILLING_STATEMENT.BILL_AMOUNT := 0;
				PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
			END IF;

			--BILL AMOUNT IS FOR CURRENT STATEMENT.
			IF v_LINE_ITEMS.STATEMENT_TYPE_NAME = v_STATEMENT.STATEMENT_TYPE_NAME THEN
				v_BILLING_STATEMENT.BILL_AMOUNT := v_LINE_ITEMS.BILL_AMOUNT;
				v_BILLING_STATEMENT.BILL_QUANTITY := v_BILLING_STATEMENT.BILL_AMOUNT;
			END IF;

			--CHARGE AMOUNT IS TOTAL CHARGE.
			v_BILLING_STATEMENT.CHARGE_AMOUNT := v_BILLING_STATEMENT.CHARGE_AMOUNT + v_LINE_ITEMS.BILL_AMOUNT;
			v_BILLING_STATEMENT.CHARGE_QUANTITY := v_BILLING_STATEMENT.CHARGE_AMOUNT;

			IF LOGS.IS_DEBUG_ENABLED THEN
				LOGS.LOG_DEBUG('');
				LOGS.LOG_DEBUG('LINE ITEM');
				LOGS.LOG_DEBUG('CHARGE_TYPE_NAME=' || v_LINE_ITEMS.CHARGE_TYPE_NAME);
				LOGS.LOG_DEBUG('COMPONENT_ID=' || TO_CHAR(v_BILLING_STATEMENT.COMPONENT_ID));
				LOGS.LOG_DEBUG('STATEMENT_TYPE_NAME=' || v_LINE_ITEMS.STATEMENT_TYPE_NAME);
				LOGS.LOG_DEBUG('LINE_ITEM_AMOUNT=' || TO_CHAR(v_LINE_ITEMS.BILL_AMOUNT));
				LOGS.LOG_DEBUG('RUNNING BILL_AMOUNT=' || TO_CHAR(v_BILLING_STATEMENT.BILL_AMOUNT));
				LOGS.LOG_DEBUG('RUNNING CHARGE_AMOUNT=' || TO_CHAR(v_BILLING_STATEMENT.CHARGE_AMOUNT));
			END IF;
		END LOOP;

		--SAVE THE LAST ONE.
		IF v_PREV_COMPONENT_ID > 0 THEN
			PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
			EXTRACT_CHARGE_DETAILS(p_ISO_SOURCE, v_BILLING_STATEMENT, v_PREV_COMPONENT_CODE, v_WORK_ID, v_BILLING_STATEMENT.STATEMENT_TYPE);
			PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
			COMMIT;
		END IF;

		-- cleanup work table
		DELETE MISO_DET_WORK WHERE WORK_ID = v_WORK_ID;
	END LOOP;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('END EXTRACT_BILLING_STATEMENT ');
	END IF;

    p_ERROR_MESSAGE := NULL;


EXCEPTION
	WHEN OTHERS THEN

		-- cleanup work table if necessary
		IF v_WORK_ID IS NOT NULL THEN
			DELETE MISO_DET_WORK WHERE WORK_ID = v_WORK_ID;
		END IF;

    	p_ERROR_MESSAGE := SQLERRM;

END EXTRACT_BILLING_STATEMENT;
-------------------------------------------------------------------------------------
PROCEDURE PUT_SETTLEMENT_STATEMENT
	(
	p_ISO_SOURCE IN VARCHAR2,
	p_STATEMENT_NAME IN VARCHAR2,
	p_MARKET_ABBR IN VARCHAR2,
	p_STATEMENT_XML IN XMLTYPE,
	p_TRACE_ON IN NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
	) AS

--p_STATEMENT_NAME SHOULD BE THE XML NAME OF THE STATEMENT, ONE OF THE FOLLOWING:
--MP_DA_STLMT, MP_RT_STLMT, OR MP_FTR_STLMT.

BEGIN

	EXTRACT_BILLING_STATEMENT(p_ISO_SOURCE, p_STATEMENT_NAME, p_MARKET_ABBR, p_STATEMENT_XML, p_ERROR_MESSAGE);

END PUT_SETTLEMENT_STATEMENT;
-------------------------------------------------------------------------------------
FUNCTION EXTRACT_FILE_NAME
	(
	p_FILE_PATH IN VARCHAR2
	) RETURN VARCHAR2 IS
v_POS1 BINARY_INTEGER;
v_POS2 BINARY_INTEGER;
BEGIN
	v_POS1 := INSTR(p_FILE_PATH,'/',-1);
	v_POS2 := INSTR(p_FILE_PATH,'\',-1);
	IF v_POS2 > v_POS1 THEN
		v_POS1 := v_POS2;
	END IF;

	IF v_POS1 = 0 THEN
		RETURN UPPER(p_FILE_PATH);
	ELSE
		RETURN UPPER(SUBSTR(p_FILE_PATH,v_POS1+1));
	END IF;
END EXTRACT_FILE_NAME;
----------------------------------------------------------------------------------------
FUNCTION GET_ASSET_OWNER_FROM_STMNT(p_IMPORT_FILE IN OUT NOCOPY CLOB, p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) RETURN VARCHAR2 IS
	v_ASSET_OWNER_NAME VARCHAR2(256);
BEGIN
	SELECT EXTRACTVALUE(VALUE(T), '//ASSET_OWNER_NAME') ASSET_OWNER_NAME
	INTO v_ASSET_OWNER_NAME
	FROM TABLE(XMLSEQUENCE(EXTRACT(XMLTYPE.CREATEXML(p_IMPORT_FILE), 'DA_STLMT'))) T;

	p_LOGGER.LOG_INFO('Asset owner name: ' || v_ASSET_OWNER_NAME);

	RETURN v_ASSET_OWNER_NAME;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		p_LOGGER.LOG_ERROR('Cannot extract asset owner name - check XML format.');
		RAISE;
	WHEN OTHERS THEN
		RAISE;
END GET_ASSET_OWNER_FROM_STMNT;
-------------------------------------------------------------------------------------------
PROCEDURE IMPORT_STATEMENT_CLOB(p_FILE_PATH IN VARCHAR2,
								p_IMPORT_FILE IN OUT NOCOPY CLOB,
								p_LOG_TYPE IN NUMBER,
								p_TRACE_ON IN NUMBER,
								p_STATUS OUT NUMBER,
								p_MESSAGE OUT VARCHAR2) AS
	v_LOGGER            MM_LOGGER_ADAPTER;
	v_FILENAME          VARCHAR2(256);
	v_DUMMY             VARCHAR2(4000);
	v_STATEMENT_NAME     VARCHAR2(256);
	v_MARKET_ABBR     VARCHAR2(5);
	v_ISO_SOURCE VARCHAR2(200);

BEGIN
	SAVEPOINT BEFORE_IMPORT;

	p_STATUS  := GA.SUCCESS;
	p_MESSAGE := 'Import Complete.';

	v_LOGGER := MM_UTIL.GET_LOGGER(EC.ES_MISO,
								   NULL,
								   'Import Statement',
								   NULL,
								   p_LOG_TYPE,
								   p_TRACE_ON);
	MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

	v_FILENAME := EXTRACT_FILE_NAME(p_FILE_PATH);

	-- p_STATEMENT_NAME used in the call to EXTRACT_BILLING_STATEMENT should be one of
	-- DA_STLMT, RT_STLMT, OR FTR_STLMT.
	CASE
		WHEN v_FILENAME LIKE 'DA%' THEN
			v_STATEMENT_NAME := 'DA_STLMT';
			v_MARKET_ABBR := 'DA';
		WHEN v_FILENAME LIKE 'FTR%' THEN
			v_STATEMENT_NAME := 'FTR_STLMT';
			v_MARKET_ABBR := 'FTR';
		WHEN v_FILENAME LIKE 'RT%' THEN
			v_STATEMENT_NAME := 'RT_STLMT';
			v_MARKET_ABBR := 'RT';
		ELSE
			v_STATEMENT_NAME := 'INVALID';
			p_STATUS := GA.GENERAL_EXCEPTION;
			p_MESSAGE := 'Unable to extract market name from filename: ' || v_FILENAME;
	END CASE;

	-- v_ISO_SOURCE is the contract alias, and should be of the form <participant name>: MISO.
	-- we need to extract it from the filename
	v_ISO_SOURCE := SUBSTR(SUBSTR(v_FILENAME, 1, INSTR(v_FILENAME, '_', -1, 2) - 1), INSTR(v_FILENAME, '_') + 1) || ': MISO';
	IF v_STATEMENT_NAME != 'INVALID' THEN
		EXTRACT_BILLING_STATEMENT(v_ISO_SOURCE,
								  v_STATEMENT_NAME,
								  v_MARKET_ABBR,
								  XMLTYPE.CREATEXML(p_IMPORT_FILE),
								  v_DUMMY);
	END IF;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		--p_MESSAGE := MM_SEM_UTIL.ERROR_STACKTRACE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, v_DUMMY);
		ROLLBACK TO BEFORE_IMPORT;

END IMPORT_STATEMENT_CLOB;
-------------------------------------------------------------------------------------
END MM_MISO_SETTLEMENT;
/
