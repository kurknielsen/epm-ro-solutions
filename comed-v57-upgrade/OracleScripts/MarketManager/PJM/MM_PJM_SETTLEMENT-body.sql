CREATE OR REPLACE PACKAGE BODY MM_PJM_SETTLEMENT IS
----------------------------------------------------------------------------------------------------
g_PJM_SC_ID SC.SC_ID%TYPE;
g_STATEMENT_TYPE NUMBER(9) := 1; -- put everything in Forecast statement type for now
g_MARKET_PRICE_CODE CHAR(1) := 'A'; -- put prices in Actual

g_MISC_PRODUCT_EXT_ID VARCHAR2(32) := 'PJM:Other';
g_FTR_CONG_CRED_WK_ID NUMBER(9) := 0;
g_EMKT_GEN_ATTR ENTITY_ATTRIBUTE.ATTRIBUTE_ID%TYPE;
g_PJM_TIME_ZONE VARCHAR2(3) := 'EDT';
g_MARGINAL_LOSS_DATE DATE := DATE '2007-06-01';


FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
-- These are helper routines to perform some I/O on behalf of the import logic.
----------------------------------------------------------------------------------------------------
FUNCTION GET_PSE
	(
	p_ORG_ID IN VARCHAR2,
	p_ORG_NAME IN VARCHAR2
  ) RETURN NUMBER IS
v_PSE_ID NUMBER := NULL;
BEGIN
	IF NOT p_ORG_ID IS NULL THEN
		BEGIN
			SELECT PSE_ID INTO v_PSE_ID
			FROM PURCHASING_SELLING_ENTITY
			WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) = UPPER('PJM-'||TRUNC(p_ORG_ID, 0));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_PSE_ID := NULL;
			WHEN TOO_MANY_ROWS THEN
				-- ??
       			LOGS.LOG_WARN('More than one PSE for PJM found. Using the first one.');
				SELECT PSE_ID INTO v_PSE_ID
				FROM PURCHASING_SELLING_ENTITY
				WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) = UPPER('PJM-'||TRUNC(p_ORG_ID, 0))
       				AND ROWNUM = 1; -- just grab the first one
		END;
	END IF;
	IF v_PSE_ID IS NULL AND NOT p_ORG_NAME IS NULL THEN
		BEGIN
			SELECT PSE_ID INTO v_PSE_ID
			FROM PURCHASING_SELLING_ENTITY
			WHERE UPPER(PSE_DESC) = UPPER('PJM: '||TRIM(p_ORG_NAME));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
        		BEGIN
        			SELECT PSE_ID INTO v_PSE_ID
        			FROM PURCHASING_SELLING_ENTITY
        			WHERE UPPER(REPLACE(PSE_DESC,',','')) = UPPER('PJM: '||TRIM(REPLACE(p_ORG_NAME,',','')));
        		EXCEPTION
              WHEN NO_DATA_FOUND THEN
                BEGIN
            		  -- schedule 9 and 10 summary replaces the comma in the name with a space
                	SELECT PSE_ID INTO v_PSE_ID
            			FROM PURCHASING_SELLING_ENTITY
            			WHERE UPPER(REPLACE(PSE_DESC,',',' ')) = UPPER('PJM: '||TRIM(REPLACE(p_ORG_NAME,',',' ')));
                EXCEPTION
            			WHEN NO_DATA_FOUND THEN
            				v_PSE_ID := NULL;
            			WHEN TOO_MANY_ROWS THEN
            				-- ??
                   			LOGS.LOG_WARN('More than one PSE for PJM found. Using the first one.');
            				SELECT PSE_ID INTO v_PSE_ID
            				FROM PURCHASING_SELLING_ENTITY
    	        			WHERE UPPER(REPLACE(PSE_DESC,',','')) = UPPER('PJM: '||TRIM(REPLACE(p_ORG_NAME,',','')))
                   				AND ROWNUM = 1; -- just grab the first one
          		  END;
            END;
			WHEN TOO_MANY_ROWS THEN
				-- ??
       			LOGS.LOG_WARN('More than one PSE for PJM found. Using the first one.');
				SELECT PSE_ID INTO v_PSE_ID
				FROM PURCHASING_SELLING_ENTITY
				WHERE UPPER(PSE_DESC) = UPPER('PJM: '||TRIM(p_ORG_NAME))
       				AND ROWNUM = 1; -- just grab the first one
		END;
	END IF;
	IF v_PSE_ID IS NULL THEN
		BEGIN
			SELECT PSE_ID INTO v_PSE_ID
			FROM PURCHASING_SELLING_ENTITY
			WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) = 'PJM';
		EXCEPTION
			WHEN TOO_MANY_ROWS THEN
				-- ??
       			LOGS.LOG_WARN('More than one PSE for PJM found. Using the first one.');
				SELECT PSE_ID INTO v_PSE_ID
				FROM PURCHASING_SELLING_ENTITY
				WHERE UPPER(PSE_EXTERNAL_IDENTIFIER) = 'PJM'
       				AND ROWNUM = 1; -- just grab the first one
		END;
	END IF;
	RETURN v_PSE_ID;
END GET_PSE;
----------------------------------------------------------------------------------------------------
FUNCTION TRIM_COMPONENT_NAME
	(
	p_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS
v_SHORT_NAME VARCHAR2(128);
v_POS NUMBER(3);
v_DATE_STR VARCHAR2(128);
v_DATE DATE;
BEGIN
	v_POS := INSTR(p_NAME, '-');
	IF v_POS > 0 THEN
		v_DATE_STR := SUBSTR(p_NAME, v_POS + 2);
        BEGIN
        	v_DATE := TO_DATE(v_DATE_STR, 'MonYYYY');
            -- trim off '- MonYYYY'
        	v_SHORT_NAME := TRIM(SUBSTR(p_NAME, 1, v_POS - 1));
        EXCEPTION
        	WHEN OTHERS THEN
            	-- if not a date after dash, don't trim
            	v_SHORT_NAME := p_NAME;
        END;
	ELSE
    	v_SHORT_NAME := p_NAME;
    END IF;

	RETURN v_SHORT_NAME;
END TRIM_COMPONENT_NAME;
----------------------------------------------------------------------------------------------------
FUNCTION GET_SERVICE_POINT
	(
	p_NAME IN VARCHAR2
	) RETURN NUMBER IS
v_ID NUMBER := NULL;
BEGIN
	v_ID := MM_PJM_UTIL.ID_FOR_SERVICE_POINT_NAME(p_NAME);
	RETURN v_ID;
END GET_SERVICE_POINT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_COMPONENT
	(
	p_LINE_ITEM_NAME IN VARCHAR2
	) RETURN NUMBER IS
v_COMPONENT_ID NUMBER;
BEGIN
	BEGIN
		-- first check external ID
		SELECT COMPONENT_ID INTO v_COMPONENT_ID
		FROM COMPONENT
		WHERE UPPER(EXTERNAL_IDENTIFIER) = UPPER(TRIM(p_LINE_ITEM_NAME));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- then check description
			BEGIN
				SELECT COMPONENT_ID INTO v_COMPONENT_ID
				FROM COMPONENT
				WHERE UPPER(COMPONENT_DESC) = UPPER(TRIM(p_LINE_ITEM_NAME));
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- None? Then create a component
					SELECT OID.NEXTVAL INTO v_COMPONENT_ID FROM DUAL;
					IO.PUT_COMPONENT(v_COMPONENT_ID,
							SUBSTR(TRIM(p_LINE_ITEM_NAME),1,256),
							SUBSTR(TRIM(p_LINE_ITEM_NAME), 1, 32),
							'Generated by PJM Import',
							v_COMPONENT_ID,
							'PSE',
							'PJM Charge',
							'External',
							NULL,
							NULL,--P_IS_REBILL,
							NULL,--P_IS_TAXED,
							NULL,--P_IS_CUSTOM_CHARGE,
							NULL,--P_IS_CREDIT_CHARGE,
							NULL,--P_IS_INCLUDE_TX_LOSS,
							NULL,--P_IS_INCLUDE_DX_LOSS,
							NULL,--P_TEMPLATE_ID,
							NULL,--P_MARKET_PRICE_ID,
							NULL,--P_SERVICE_POINT_ID,
							NULL,--P_MODEL_ID,
							NULL,--P_EVENT_ID,
							NULL,--P_COMPONENT_REFERENCE,
							NULL,--P_INVOICE_GROUP_ID,
							NULL,--P_INVOICE_GROUP_ORDER,
							NULL,--P_COMPUTATION_ORDER,
							NULL,--P_QUANTITY_UNIT,
							NULL,--P_CURRENCY_UNIT,
							NULL,--P_QUANTITY_TYPE,
							SUBSTR(TRIM(p_LINE_ITEM_NAME), 1, 32),--P_EXTERNAL_IDENTIFIER,
							NULL, --P_COMPONENT_CATEGORY,
							NULL,--P_GL_DEBIT_ACCOUNT,
							NULL,--P_GL_CREDIT_ACCOUNT,
							NULL,--P_FIRM_NON_FIRM,
							NULL,--P_EXCLUDE_FROM_INVOICE,
							NULL,--P_EXCLUDE_FROM_INVOICE_TOTAL,
							NULL,--P_IMBALANCE_TYPE,
							NULL,--P_ACCUMULATION_PERIOD,
							NULL,--P_BASE_COMPONENT_ID,
							NULL,--P_BASE_LIMIT_ID,
							NULL,--P_MARKET_TYPE,
							NULL,--P_MARKET_PRICE_TYPE,
							NULL,--P_WHICH_INTERVAL,
							NULL,--P_LMP_PRICE_CALC,
							NULL,--P_LMP_INCLUDE_EXT,
							NULL,--P_LMP_INCLUDE_SALES,
							NULL,--P_CHARGE_WHEN,
							NULL,--P_BILATERALS_SIGN,
							NULL,--P_LMP_COMMODITY_ID,
							NULL,--P_LMP_BASE_COMMODITY_ID,
							NULL,--P_USE_ZONAL_PRICE,
							NULL,--P_ALTERNATE_PRICE,
							NULL,--P_ALTERNATE_PRICE_FUNCTION
							NULL, -- p_EXCLUDE_FROM_BILLING_EXPORT,
							NULL, -- p_IS_DEFAULT_TEMPLATE
							NULL, -- p_KWH_MULTIPLIER
                            NULL,-- p_ANCILLARY SERVICE ID
                            NULL, -- p_APPLY_RATE_FOR
							NULL); -- p_LOSS_ADJ_TYPE

				WHEN TOO_MANY_ROWS THEN
					-- ??
        			LOGS.LOG_WARN('More than one component found with Desc. of '''||p_LINE_ITEM_NAME||'''. Using the first one.');
        			SELECT COMPONENT_ID INTO v_COMPONENT_ID
        			FROM COMPONENT
					WHERE UPPER(COMPONENT_DESC) = UPPER(TRIM(p_LINE_ITEM_NAME))
        				AND ROWNUM = 1; -- just grab the first one
			END;
		WHEN TOO_MANY_ROWS THEN
			-- ??
			LOGS.LOG_WARN('More than one component found with Ext.ID of '''||p_LINE_ITEM_NAME||'''. Using the first one.');
			SELECT COMPONENT_ID INTO v_COMPONENT_ID
			FROM COMPONENT
			WHERE UPPER(EXTERNAL_IDENTIFIER) = UPPER(TRIM(p_LINE_ITEM_NAME))
				AND ROWNUM = 1; -- just grab the first one
	END;
	RETURN v_COMPONENT_ID;
END GET_COMPONENT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_PRODUCT
	(
	p_COMPONENT_ID IN NUMBER
	) RETURN NUMBER IS
v_PRODUCT_ID NUMBER;
BEGIN
	BEGIN
		SELECT PRODUCT_ID INTO v_PRODUCT_ID
		FROM PRODUCT_COMPONENT
		WHERE COMPONENT_ID = p_COMPONENT_ID;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- use default product for unknown components
			BEGIN
        		SELECT PRODUCT_ID INTO v_PRODUCT_ID
        		FROM PRODUCT
        		WHERE UPPER(PRODUCT.PRODUCT_EXTERNAL_IDENTIFIER) = UPPER(g_MISC_PRODUCT_EXT_ID);
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- None? then create the product
					SELECT OID.NEXTVAL INTO v_PRODUCT_ID FROM DUAL;
					INSERT INTO PRODUCT (
						PRODUCT_ID, PRODUCT_NAME, PRODUCT_ALIAS, PRODUCT_DESC, PRODUCT_EXTERNAL_IDENTIFIER, BEGIN_DATE, END_DATE, ENTRY_DATE
					) VALUES (
						v_PRODUCT_ID, 'PJM Other Charges', 'PJM Other Charges', 'Generated by PJM Import - Product to group unknown/unshadowed components', g_MISC_PRODUCT_EXT_ID, TO_DATE('01/01/2001','MM/DD/YYYY'), NULL, SYSDATE
					);
				WHEN TOO_MANY_ROWS THEN
        			-- ??
                    LOGS.LOG_WARN('More than one product with Ext.ID of '''||g_MISC_PRODUCT_EXT_ID||'''. Using the first one.');
            		SELECT PRODUCT_ID INTO v_PRODUCT_ID
            		FROM PRODUCT
            		WHERE UPPER(PRODUCT.PRODUCT_EXTERNAL_IDENTIFIER) = UPPER(g_MISC_PRODUCT_EXT_ID)
        	            AND ROWNUM = 1; -- just grab the first one
			END;
		WHEN TOO_MANY_ROWS THEN
			-- ??
            LOGS.LOG_WARN('Component '||p_COMPONENT_ID||' is associated with more than one product. Using the first one.');
    		SELECT PRODUCT_ID INTO v_PRODUCT_ID
    		FROM PRODUCT_COMPONENT
    		WHERE COMPONENT_ID = p_COMPONENT_ID
	            AND ROWNUM = 1; -- just grab the first one
	END;
	RETURN v_PRODUCT_ID;
END GET_PRODUCT;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_PRODUCT_COMPONENT
	(
	p_LINE_ITEM_NAME IN VARCHAR2,
	p_PRODUCT_ID OUT NUMBER,
	p_COMPONENT_ID OUT NUMBER
	) AS
BEGIN
	-- First get the component
	p_COMPONENT_ID := GET_COMPONENT(p_LINE_ITEM_NAME);
	p_PRODUCT_ID := GET_PRODUCT(p_COMPONENT_ID);
END GET_PRODUCT_COMPONENT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_CHARGE_ID
	(
	p_PSE_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_MONTH IN DATE,
	p_CHARGE_VIEW_TYPE IN VARCHAR2
	) RETURN NUMBER IS
v_CHARGE_ID NUMBER;
v_PRODUCT_ID NUMBER(9);
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
BEGIN
	SELECT CHARGE_ID INTO v_CHARGE_ID
	FROM BILLING_STATEMENT A
	WHERE ENTITY_ID = p_PSE_ID
		AND COMPONENT_ID = p_COMPONENT_ID
		AND STATEMENT_TYPE = g_STATEMENT_TYPE
		AND STATEMENT_STATE = g_EXTERNAL_STATE
		AND STATEMENT_DATE = p_MONTH
		AND AS_OF_DATE = (SELECT MAX(AS_OF_DATE)
							FROM BILLING_STATEMENT
							WHERE ENTITY_ID = A.ENTITY_ID
								AND PRODUCT_ID = A.PRODUCT_ID
								AND COMPONENT_ID = A.COMPONENT_ID
								AND STATEMENT_TYPE = A.STATEMENT_TYPE
								AND STATEMENT_STATE = A.STATEMENT_STATE
								AND STATEMENT_DATE = A.STATEMENT_DATE
								AND AS_OF_DATE <= SYSDATE);

	UPDATE BILLING_STATEMENT
		SET CHARGE_VIEW_TYPE = p_CHARGE_VIEW_TYPE
	WHERE CHARGE_ID = v_CHARGE_ID;

	RETURN v_CHARGE_ID;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
        --create charge_id
        v_PRODUCT_ID := GET_PRODUCT(p_COMPONENT_ID);
        v_BILLING_STATEMENT.Entity_Id := p_PSE_ID;
        v_BILLING_STATEMENT.Product_Id := v_PRODUCT_ID;
        v_BILLING_STATEMENT.Component_Id := p_COMPONENT_ID;
        v_BILLING_STATEMENT.Statement_Type := g_STATEMENT_TYPE;
        v_BILLING_STATEMENT.Statement_State := g_EXTERNAL_STATE;
        v_BILLING_STATEMENT.Statement_Date := p_MONTH;
        v_BILLING_STATEMENT.As_Of_Date := LOW_DATE;
        v_BILLING_STATEMENT.Statement_End_Date := LAST_DAY(p_MONTH);
        v_BILLING_STATEMENT.Charge_View_Type := p_CHARGE_VIEW_TYPE;
        v_BILLING_STATEMENT.Entity_Type := 'PSE';
        v_BILLING_STATEMENT.Charge_Quantity := NULL;
        v_BILLING_STATEMENT.Charge_Rate := NULL;
        v_BILLING_STATEMENT.Charge_Amount := NULL;

        PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
	    RETURN v_BILLING_STATEMENT.Charge_Id;
END GET_CHARGE_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_COMBO_CHARGE_ID
	(
	p_CHARGE_ID IN NUMBER,
	p_COMPONENT_ID IN NUMBER,
	p_MONTH IN DATE,
	p_CHARGE_VIEW_TYPE IN VARCHAR2,
    p_IS_DAILY IN BOOLEAN := FALSE
	) RETURN NUMBER IS
v_COMBO_CHARGE_ID NUMBER;
v_END_DATE DATE;
BEGIN
    IF p_IS_DAILY = TRUE THEN
        v_END_DATE := p_MONTH;
    ELSE
        v_END_DATE := LAST_DAY(p_MONTH);
    END IF;

	SELECT COMBINED_CHARGE_ID INTO v_COMBO_CHARGE_ID
	FROM COMBINATION_CHARGE
	WHERE CHARGE_ID = p_CHARGE_ID
		AND COMPONENT_ID = p_COMPONENT_ID
		AND BEGIN_DATE = p_MONTH;

	UPDATE COMBINATION_CHARGE
		SET CHARGE_VIEW_TYPE = p_CHARGE_VIEW_TYPE
	WHERE CHARGE_ID = p_CHARGE_ID
		AND COMPONENT_ID = p_COMPONENT_ID
		AND BEGIN_DATE = p_MONTH;

	RETURN v_COMBO_CHARGE_ID;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		SELECT BID.NEXTVAL INTO v_COMBO_CHARGE_ID FROM DUAL;
		INSERT INTO COMBINATION_CHARGE (
			CHARGE_ID, COMPONENT_ID, BEGIN_DATE, END_DATE,
			COMBINED_CHARGE_ID, CHARGE_VIEW_TYPE, COEFFICIENT,
			CHARGE_FACTOR, ENTRY_DATE)
		VALUES (
			p_CHARGE_ID, p_COMPONENT_ID, p_MONTH, v_END_DATE,
			v_COMBO_CHARGE_ID, p_CHARGE_VIEW_TYPE, 1.0,
			1.0, SYSDATE);
		RETURN v_COMBO_CHARGE_ID;
END GET_COMBO_CHARGE_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_CHARGE_DATE
	(
	p_DAY IN DATE,
	p_HOUR IN NUMBER,
	p_DST_FLAG IN NUMBER
	) RETURN DATE IS
v_TZ VARCHAR2(4) := 'EDT';
BEGIN
	--DST FLAG DENOTES SECOND HOUR ENDING 2.
	IF NVL(p_DST_FLAG,0) = 1 THEN
		RETURN TO_CUT_WITH_OPTIONS(p_DAY + p_HOUR/24 + 1/86400, v_TZ, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
	--HOUR 25 ALSO DENOTES SECOND HOUR ENDING 2.
    ELSIF p_HOUR = 25 THEN
        RETURN TO_CUT_WITH_OPTIONS(p_DAY + 2/24 + 1/86400, v_TZ, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
	ELSE
		RETURN TO_CUT_WITH_OPTIONS(p_DAY + p_HOUR/24, v_TZ, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
	END IF;
END GET_CHARGE_DATE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_MARKET_PRICE
    (
    p_EXT_ID IN VARCHAR2
    ) RETURN NUMBER IS

    v_MKT_PRICE_ID NUMBER;
BEGIN

    SELECT MARKET_PRICE_ID
    INTO v_MKT_PRICE_ID
    FROM MARKET_PRICE
    WHERE UPPER(EXTERNAL_IDENTIFIER) = UPPER(TRIM(p_EXT_ID));

    RETURN v_MKT_PRICE_ID;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN TOO_MANY_ROWS THEN
        LOGS.LOG_WARN('More than one Market Price with Ext.ID of ''' || p_EXT_ID
            || ''' was found. Using the first one.');

        SELECT MARKET_PRICE_ID
        INTO v_MKT_PRICE_ID
        FROM MARKET_PRICE
        WHERE UPPER(EXTERNAL_IDENTIFIER) = UPPER(TRIM(p_EXT_ID))
            AND ROWNUM = 1; -- just grab the first one

        RETURN v_MKT_PRICE_ID;
END GET_MARKET_PRICE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_CONTRACT_ID
    (
	p_BILLING_ENTITY_ID IN NUMBER
	)  RETURN NUMBER IS

-- Answer the interchange contract id associated with the counter party.

v_CONTRACT_ID NUMBER;

BEGIN

	SELECT CONTRACT_ID
	INTO v_CONTRACT_ID
	FROM INTERCHANGE_CONTRACT
	WHERE BILLING_ENTITY_ID = p_BILLING_ENTITY_ID
	    AND ROWNUM = 1;

	RETURN v_CONTRACT_ID;

	 EXCEPTION
 		WHEN NO_DATA_FOUND THEN
			RETURN 0;
	 	WHEN OTHERS THEN
 			RAISE;

END GET_CONTRACT_ID;
----------------------------------------------------------------------------------------------------
FUNCTION ID_FOR_PJM_CONTRACT
	(
	p_ISO_SOURCE IN VARCHAR2
	) RETURN NUMBER AS
v_ID NUMBER;
-- Answer the interchange contract id associated with the ISO account name.
BEGIN
	SELECT CONTRACT_ID
	INTO v_ID
	FROM INTERCHANGE_CONTRACT A
	WHERE A.CONTRACT_ALIAS = p_ISO_SOURCE
		AND ROWNUM = 1;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN 0;
	WHEN OTHERS THEN
		RAISE;
END ID_FOR_PJM_CONTRACT;
 -------------------------------------------------------------------------------------
FUNCTION GET_TX_ID
  (
  p_EXT_ID IN VARCHAR2,
  p_TRANS_TYPE IN VARCHAR2 := 'Market Result',
  p_NAME IN VARCHAR2 := NULL,
  p_INTERVAL IN VARCHAR2 := 'Hour',
  p_COMMODITY_ID IN NUMBER := 0,
  p_CONTRACT_ID IN NUMBER := 0,
  p_ZOD_ID IN NUMBER := 0,
  p_SERVICE_POINT_ID IN NUMBER := 0,
  p_POOL_ID IN NUMBER := 0,
  p_SELLER_ID IN NUMBER := 0
  ) RETURN NUMBER IS

  v_ID NUMBER;
  v_SC NUMBER(9);
  v_SUFFIX VARCHAR2(32) := '';
  v_TMP VARCHAR2(32);
  v_NAME VARCHAR2(64);
  v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
  v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

BEGIN
	IF p_EXT_ID IS NULL THEN
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_TYPE = p_TRANS_TYPE
            AND CONTRACT_ID = p_CONTRACT_ID
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID)
            AND (p_ZOD_ID = 0 OR ZOD_ID = p_ZOD_ID);
	ELSE
        SELECT TRANSACTION_ID
        INTO v_ID
        FROM INTERCHANGE_TRANSACTION
        WHERE TRANSACTION_IDENTIFIER = p_EXT_ID
            AND (p_CONTRACT_ID = 0 OR CONTRACT_ID = p_CONTRACT_ID)
            AND (p_SERVICE_POINT_ID = 0 OR POD_ID = p_SERVICE_POINT_ID)
            AND (p_POOL_ID = 0 OR POOL_ID = p_POOL_ID)
			AND (p_SELLER_ID = 0 OR SELLER_ID = p_SELLER_ID)
            AND (p_ZOD_ID = 0 OR ZOD_ID = p_ZOD_ID);
	END IF;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_NAME := NVL(p_NAME,p_EXT_ID);

        SELECT SC_ID
        INTO v_SC
        FROM SCHEDULE_COORDINATOR
        WHERE SC_NAME = 'PJM';

		IF p_CONTRACT_ID <> 0 THEN
    	    SELECT ': '||CONTRACT_NAME
	        INTO v_TMP
	        FROM INTERCHANGE_CONTRACT
	        WHERE CONTRACT_ID = p_CONTRACT_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
		END IF;
        IF p_SELLER_ID <> 0 THEN
    	    SELECT ': '||PSE_NAME
	        INTO v_TMP
	        FROM PURCHASING_SELLING_ENTITY
	        WHERE PSE_ID = p_SELLER_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
        END IF;
        IF p_POOL_ID <> 0 THEN
    	    SELECT ': '||POOL_NAME
	        INTO v_TMP
	        FROM POOL
	        WHERE POOL_ID = p_POOL_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
        END IF;
        IF p_SERVICE_POINT_ID <> 0 THEN
    	    SELECT ': '||SERVICE_POINT_NAME
	        INTO v_TMP
	        FROM SERVICE_POINT
	        WHERE SERVICE_POINT_ID = p_SERVICE_POINT_ID;
			v_SUFFIX := SUBSTR(v_SUFFIX||v_TMP,1,32);
        END IF;

	--create the transaction

    	v_TRANSACTION.TRANSACTION_ID := 0;
        v_TRANSACTION.TRANSACTION_NAME := SUBSTR(v_NAME||v_SUFFIX,1,64);
        v_TRANSACTION.TRANSACTION_ALIAS := SUBSTR(v_NAME||v_SUFFIX,1,32);
        v_TRANSACTION.TRANSACTION_DESC := v_NAME||v_SUFFIX;
        v_TRANSACTION.TRANSACTION_TYPE := p_TRANS_TYPE;
        v_TRANSACTION.TRANSACTION_IDENTIFIER := p_EXT_ID;
        v_TRANSACTION.TRANSACTION_INTERVAL := p_INTERVAL;
        v_TRANSACTION.BEGIN_DATE := TO_DATE('1/1/2000','MM/DD/YYYY');
        v_TRANSACTION.END_DATE := TO_DATE('12/31/2020','MM/DD/YYYY');
        v_TRANSACTION.SELLER_ID := p_SELLER_ID;
        v_TRANSACTION.CONTRACT_ID := p_CONTRACT_ID;
        v_TRANSACTION.SC_ID := v_SC;
        v_TRANSACTION.POD_ID := p_SERVICE_POINT_ID;
        v_TRANSACTION.POOL_ID := p_POOL_ID;
        v_TRANSACTION.ZOD_ID := p_ZOD_ID;
        v_TRANSACTION.COMMODITY_ID := p_COMMODITY_ID;

		MM_UTIL.PUT_TRANSACTION(v_TRANSACTION_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');

		RETURN v_TRANSACTION_ID;
END GET_TX_ID;
---------------------------------------------------------------------------------------------------
--      Only Reconciliation Report Schedule 1 has EDC (PSE) field. The associated Zone must be known.
--      When importing Reconciliation Report Schedule 1A, which has both EDC (PSE) and Zone, create
--      PSE if does not exist and set its Zone custom attribute it its associated Zone
FUNCTION PUT_PSE
    (
    p_PSE_ALIAS IN VARCHAR2,
    p_ZONE_NAME IN VARCHAR2
    ) RETURN NUMBER AS
v_PSE_ID NUMBER(9) := 0;
v_PJM_ID NUMBER(9);
v_ZONE_ATTRIBUTE_ID NUMBER(9);
v_STATUS NUMBER;
BEGIN
    v_STATUS := GA.SUCCESS;
    BEGIN
		SELECT POM.OBJECT_VALUE
			INTO v_PJM_ID
			FROM PJM_OBJECT_MAP POM
		 WHERE POM.OBJECT_TYPE = 'PSE'
			 AND UPPER(POM.OBJECT_NAME) = UPPER(p_PSE_ALIAS);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			LOGS.LOG_WARN('No PJM Org ID found with name ' || p_PSE_ALIAS || ', try downloading latest eSchedules Company modeling data.');
	END;
        IO.PUT_PSE(o_OID                       => v_PSE_ID,
        			 p_PSE_NAME                  => p_PSE_ALIAS,
        			 p_PSE_ALIAS                 => p_PSE_ALIAS,
        			 p_PSE_DESC                  => 'Created via Reconcil import',
        			 p_PSE_ID                    => 0,
        			 p_PSE_NERC_CODE             => NULL,
        			 p_PSE_STATUS                => 'Active',
        			 p_PSE_DUNS_NUMBER           => NULL,
        			 p_PSE_BANK                  => NULL,
        			 p_PSE_ACH_NUMBER            => NULL,
        			 p_PSE_TYPE                  => NULL,
        			 p_PSE_EXTERNAL_IDENTIFIER   => 'PJM-' || v_PJM_ID,
        			 p_PSE_IS_RETAIL_AGGREGATOR  => NULL,
        			 p_PSE_IS_BACKUP_GENERATION  => NULL,
        			 p_PSE_EXCLUDE_LOAD_SCHEDULE => NULL,
        			 p_IS_BILLING_ENTITY         => NULL,
        			 p_TIME_ZONE                 => 'EDT',
        			 p_STATEMENT_INTERVAL        => NULL,
        			 p_INVOICE_INTERVAL          => NULL,
        			 p_WEEK_BEGIN                => NULL,
        			 p_INVOICE_LINE_ITEM_OPTION  => NULL,
					 p_SCHEDULE_NAME_PREFIX => NULL,
					 p_SCHEDULE_FORMAT => NULL,
					 p_SCHEDULE_INTERVAL => NULL,
					 p_LOAD_ROUNDING_PREFERENCE => NULL,
					 p_LOSS_ROUNDING_PREFERENCE => NULL,
					 p_CREATE_TX_LOSS_SCHEDULE => NULL,
					 p_CREATE_DX_LOSS_SCHEDULE => NULL,
					 p_CREATE_UFE_SCHEDULE => NULL,
					 p_MINIMUM_SCHEDULE_AMT => NULL,
					 p_INVOICE_EMAIL_SUBJECT => NULL,
					 p_INVOICE_EMAIL_PRIORITY => NULL,
					 p_INVOICE_EMAIL_BODY => NULL,
					 p_INVOICE_EMAIL_BODY_MIME_TYPE => NULL
					 );


    ID.ID_FOR_ENTITY_ATTRIBUTE('Zone', 'PSE', 'String', TRUE, v_ZONE_ATTRIBUTE_ID);

    SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_PSE_ID, v_ZONE_ATTRIBUTE_ID,
        								SYSDATE, NULL, p_ZONE_NAME,
                                        v_PSE_ID, v_ZONE_ATTRIBUTE_ID,
                                        SYSDATE, v_STATUS);

    COMMIT;
    RETURN v_PSE_ID;

END PUT_PSE;
------------------------------------------------------------------------------------------------------
FUNCTION ID_FOR_SERVICE_ZONE
	(
	p_ZONE_NAME IN VARCHAR2
	) RETURN NUMBER AS
v_ID NUMBER(9);
BEGIN
	SELECT A.SERVICE_ZONE_ID
	INTO v_ID
	FROM SERVICE_ZONE A
	WHERE A.SERVICE_ZONE_ALIAS= p_ZONE_NAME
		AND ROWNUM = 1;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		v_ID := 0;
		RETURN v_ID;
END ID_FOR_SERVICE_ZONE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_IS_DAILY_CHARGE
    (
    p_COMPONENT_ID IN NUMBER
    ) RETURN BOOLEAN IS
TYPE ARRAY IS VARRAY(20) OF VARCHAR2(64);
v_COMP_EXT_ID VARCHAR2(32);
v_IS_DAILY BOOLEAN := FALSE;
v_DAILY_CHARGES ARRAY :=
	ARRAY('PJM:BalOpResChg', 'PJM:BalOpResCred',    --Balancing Op Reserves Charges/Credits
    		'PJM:DAOpResCred', 'PJM:DAOpResChg',    --DayAhead Op Reserves Charges/Credits
            'PJM:DASpotChg', 'PJM:DASpotCred',      --DayAhead Spot Charges/Credits
            'PJM:BalSpotChg', 'PJM:BalOpResCred',   --Balancing Spot Charges/Credits
            'PJM:DATxCongChg', 'PJM:BalTxCongChg',  --Transmission Congestion Charges
            'PJM:TxCongCred', 'PJM:TxLossCred',     --Transmission Congestion Credits, Transmission Loss Credits
            'PJM:RegChg', 'PJM:SpinResChg', 'PJM:SyncCondChg', --Regulation Charges / Spin Reserve Charges / Sync Condensing Charges
            'PJM:BalTransLossChg', 'PJM:InadvertIntChg',  --Balancing TransLoss Charges, Inadvertent Interchange Charges
            'PJM:DATransLossChg','PJM:TransLossCred'); --DayAhead Transmission Loss Charges / Transmission Loss credits (new post ML)
BEGIN
    SELECT EXTERNAL_IDENTIFIER INTO v_COMP_EXT_ID
    FROM COMPONENT
    WHERE COMPONENT_ID = p_COMPONENT_ID;

	FOR I IN v_DAILY_CHARGES.FIRST .. v_DAILY_CHARGES.LAST LOOP
        IF v_DAILY_CHARGES(I) = v_COMP_EXT_ID THEN
            v_IS_DAILY := TRUE;
            EXIT;
        END IF;
    END LOOP;

    RETURN v_IS_DAILY;

END GET_IS_DAILY_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_SCHEDULE_VALUE
  (
  p_TX_ID IN NUMBER,
  p_SCHED_DATE IN DATE,
  p_AMOUNT NUMBER,
  p_PRICE NUMBER := NULL,
  p_TO_INTERNAL BOOLEAN := TRUE
  ) AS

  v_STATUS NUMBER;
  v_IDX BINARY_INTEGER;

  BEGIN

	FOR v_IDX IN 1..MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
		IF p_TO_INTERNAL THEN
            ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                               p_SCHEDULE_TYPE => MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(v_IDX),
                               p_SCHEDULE_STATE => 1,
                               p_SCHEDULE_DATE => p_SCHED_DATE,
                               p_AS_OF_DATE => SYSDATE,
                               p_AMOUNT => p_AMOUNT,
                               p_PRICE => p_PRICE,
                               p_STATUS => v_STATUS);
		END IF;
        ITJ.PUT_IT_SCHEDULE(p_TRANSACTION_ID => p_TX_ID,
                           p_SCHEDULE_TYPE => MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY(v_IDX),
                           p_SCHEDULE_STATE => 2,
                           p_SCHEDULE_DATE => p_SCHED_DATE,
                           p_AS_OF_DATE => SYSDATE,
                           p_AMOUNT => p_AMOUNT,
                           p_PRICE => p_PRICE,
                           p_STATUS => v_STATUS);
	END LOOP;

  END PUT_SCHEDULE_VALUE;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_PRICE_VALUE
    (
    p_MARKET_PRICE_ID IN NUMBER,
    p_PRICE_DATE IN DATE,
    p_PRICE IN NUMBER
    ) AS

v_AS_OF_DATE DATE;
BEGIN
	IF p_MARKET_PRICE_ID IS NULL THEN RETURN; END IF;

	IF GA.VERSION_MARKET_PRICE THEN
		v_AS_OF_DATE := SYSDATE;
	ELSE
		v_AS_OF_DATE := LOW_DATE;
	END IF;

	UPDATE MARKET_PRICE_VALUE
		SET PRICE = p_PRICE
	WHERE MARKET_PRICE_ID = p_MARKET_PRICE_ID
		AND PRICE_DATE = p_PRICE_DATE
		AND PRICE_CODE = g_MARKET_PRICE_CODE
		AND AS_OF_DATE = v_AS_OF_DATE;

	IF SQL%NOTFOUND THEN
		INSERT INTO MARKET_PRICE_VALUE (
			MARKET_PRICE_ID, PRICE_DATE, PRICE_CODE, AS_OF_DATE, PRICE)
		VALUES (
			p_MARKET_PRICE_ID, p_PRICE_DATE, g_MARKET_PRICE_CODE, v_AS_OF_DATE, p_PRICE);
	END IF;
END PUT_MARKET_PRICE_VALUE;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_PRICE_VALUE_EXTID
	(
	p_MARKET_PRICE IN VARCHAR2,
	p_PRICE_DATE IN DATE,
	p_PRICE IN NUMBER
	) AS
BEGIN
	PUT_MARKET_PRICE_VALUE(GET_MARKET_PRICE(p_MARKET_PRICE),p_PRICE_DATE,p_PRICE);
END PUT_MARKET_PRICE_VALUE_EXTID;
---------------------------------------------------------------------------------------------------
PROCEDURE FILL_NON_SHADOWED_TXNS
	(
    p_PSE_ID IN NUMBER,
    p_COMPONENT_ID IN NUMBER,
    p_CHARGE_AMOUNT IN NUMBER,
    p_DATE IN DATE
    ) AS
v_COMPONENT_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_PSE_NAME VARCHAR2(32);
TYPE ARRAY IS VARRAY(4) OF VARCHAR2(128);
v_NON_SHADOWED_CHARGES ARRAY :=
	ARRAY('Capacity Credit Market Charges', 'Auction Revenue Rights Credits',
    		'PJM/MISO Seams Elimination Cost Assignment Charges',
            'Intra-PJM Seams Elimination Cost Assignment Charges');

PROCEDURE UPDATE_SCHEDULE(v_EXT_ID IN VARCHAR2, v_CONTRACT IN NUMBER,
							v_TRXN_NAME IN VARCHAR2) IS
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	BEGIN
		v_TRANSACTION_ID := GET_TX_ID(v_EXT_ID,
                                      'Market Result',
                                      v_TRXN_NAME,
                                      'Month',
                                      0,
                                      v_CONTRACT);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           p_DATE + 1/86400,
                           p_CHARGE_AMOUNT);

        COMMIT;
	END UPDATE_SCHEDULE;
BEGIN
	v_CONTRACT_ID := GET_CONTRACT_ID(p_PSE_ID);
    SELECT PSE_ALIAS INTO v_PSE_NAME FROM PURCHASING_SELLING_ENTITY
    WHERE PSE_ID = p_PSE_ID;

	FOR I IN v_NON_SHADOWED_CHARGES.FIRST .. v_NON_SHADOWED_CHARGES.LAST LOOP
    	BEGIN
      		SELECT COMPONENT_ID INTO v_COMPONENT_ID
            FROM COMPONENT
            WHERE COMPONENT_DESC = v_NON_SHADOWED_CHARGES(I);
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
            	LOGS.LOG_WARN('Component not found with description of ' || v_NON_SHADOWED_CHARGES(I));
        END;

        IF p_COMPONENT_ID = v_COMPONENT_ID THEN
        	CASE
            WHEN I = 1 THEN
            	UPDATE_SCHEDULE('PJM-CapCredMktChg$', v_CONTRACT_ID,
                				'PJM ' || v_PSE_NAME || ' Capacity Credit Mkt Charges Amount');
          /*  WHEN I = 2 THEN
            	UPDATE_SCHEDULE('PJM-FTRChg$', v_CONTRACT_ID,
              					'PJM ' || v_PSE_NAME || ' FTR Auction Charge Amount'); */
            WHEN I = 2 THEN
            	UPDATE_SCHEDULE('PJM-ARR$', v_CONTRACT_ID,
                				'PJM ' || v_PSE_NAME || ' Auction Revenue Rights Charge Amount');
            WHEN I = 3 THEN
            	UPDATE_SCHEDULE('PJM-PMSeamsElim$', v_CONTRACT_ID,
                				'PJM ' || v_PSE_NAME || ' PJM/MISO Seams Elim Cost Amount');
       		ELSE -- I=4
            	UPDATE_SCHEDULE('PJM-IntraSeamsElim$', v_CONTRACT_ID,
                				'PJM ' || v_PSE_NAME || ' Intra-PJM Seams Elim Cost Amount');
            END CASE;

       		EXIT;
		END IF;

	END LOOP;

END FILL_NON_SHADOWED_TXNS;
----------------------------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION
	(
	p_TX_EXT_ID IN VARCHAR2
	) RETURN NUMBER IS
v_TX_ID NUMBER;
BEGIN
	SELECT TRANSACTION_ID
	INTO v_TX_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE UPPER(TRANSACTION_IDENTIFIER) = UPPER(TRIM(p_TX_EXT_ID));
	RETURN v_TX_ID;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
	WHEN TOO_MANY_ROWS THEN
        -- ??
        LOGS.LOG_WARN('More than one Transaction with Ext.ID of '''||p_TX_EXT_ID||''' was found. Using the first one.');
    	SELECT TRANSACTION_ID
    	INTO v_TX_ID
    	FROM INTERCHANGE_TRANSACTION
    	WHERE UPPER(TRANSACTION_IDENTIFIER) = UPPER(TRIM(p_TX_EXT_ID))
			AND ROWNUM = 1; -- just grab the first one
		RETURN v_TX_ID;
END GET_TRANSACTION;
----------------------------------------------------------------------------------------------------
FUNCTION GET_SOURCE_SINK_ITERATOR_ID
	(
	p_CHARGE_ID IN NUMBER,
	p_SOURCE_NAME IN VARCHAR2,
	p_SINK_NAME IN VARCHAR2
	) RETURN NUMBER IS
	v_ITERATOR_ID NUMBER(9);
	v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
	v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
	v_SOURCE_ID NUMBER(9);
	v_SINK_ID NUMBER(9);
	v_SOURCE_NAME VARCHAR2(64);
	v_SINK_NAME VARCHAR2(64);
BEGIN

	IF p_SOURCE_NAME IS NULL AND p_SINK_NAME IS NULL THEN
		v_ITERATOR_ID := 0;
	ELSE
		--Make sure the Service Point exists, and get the correct name.
		v_SOURCE_ID := MM_PJM_UTIL.ID_FOR_SERVICE_POINT_NAME(p_SOURCE_NAME);
		v_SINK_ID := MM_PJM_UTIL.ID_FOR_SERVICE_POINT_NAME(p_SINK_NAME);
		SELECT SERVICE_POINT_NAME INTO v_SOURCE_NAME FROM SERVICE_POINT WHERE SERVICE_POINT_ID = v_SOURCE_ID;
		SELECT SERVICE_POINT_NAME INTO v_SINK_NAME FROM SERVICE_POINT WHERE SERVICE_POINT_ID = v_SINK_ID;

		--Get the ITERATOR id if it exists.  Otherwise, create one.

		BEGIN
			SELECT ITERATOR_ID
			INTO v_ITERATOR_ID
			FROM FORMULA_CHARGE_ITERATOR
			WHERE CHARGE_ID = p_CHARGE_ID
				AND ITERATOR1 = v_SOURCE_NAME
				AND ITERATOR2 = v_SINK_NAME;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_ITERATOR_NAME.CHARGE_ID := p_CHARGE_ID;
				v_ITERATOR_NAME.ITERATOR_NAME1 := 'source';
				v_ITERATOR_NAME.ITERATOR_NAME2 := 'sink';
				v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
				v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
				v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
				PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

				v_ITERATOR.CHARGE_ID := p_CHARGE_ID;
				SELECT NVL(MAX(ITERATOR_ID),0) + 1 INTO v_ITERATOR.ITERATOR_ID FROM FORMULA_CHARGE_ITERATOR WHERE CHARGE_ID = p_CHARGE_ID;
				v_ITERATOR.ITERATOR1 := v_SOURCE_NAME;
				v_ITERATOR.ITERATOR2 := v_SINK_NAME;
				v_ITERATOR.ITERATOR3 := NULL;
				v_ITERATOR.ITERATOR4 := NULL;
				v_ITERATOR.ITERATOR5 := NULL;
				PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

				v_ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		END;
	END IF;

	RETURN v_ITERATOR_ID;
END GET_SOURCE_SINK_ITERATOR_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_FORMULA_CHARGE
	(
	p_CHARGE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_ITERATOR_ID IN NUMBER
	) RETURN FORMULA_CHARGE%ROWTYPE IS

	v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
BEGIN

	BEGIN
		SELECT * INTO v_FORMULA_CHARGE
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = p_CHARGE_ID
			AND ITERATOR_ID = p_ITERATOR_ID
			AND CHARGE_DATE = p_CHARGE_DATE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_FORMULA_CHARGE.CHARGE_DATE := p_CHARGE_DATE;
			v_FORMULA_CHARGE.CHARGE_FACTOR := 1.0;
			v_FORMULA_CHARGE.ITERATOR_ID := p_ITERATOR_ID;
			v_FORMULA_CHARGE.CHARGE_ID := p_CHARGE_ID;
	END;

	RETURN v_FORMULA_CHARGE;

END GET_FORMULA_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_LMP_FORMULA_CHARGE_VAR
	(
	p_CHARGE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_SOURCE_NAME IN VARCHAR2,
	p_SINK_NAME IN VARCHAR2,
	p_DA_LOAD IN NUMBER,
	p_DA_GEN IN NUMBER,
	p_DA_PURCH IN NUMBER,
	p_DA_SALES IN NUMBER,
	p_INC IN NUMBER,
	p_DEC IN NUMBER,
	p_RT_LOAD IN NUMBER,
	p_RT_GEN IN NUMBER,
	p_RT_PURCH IN NUMBER,
	p_RT_SALES IN NUMBER
	) AS

	v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
	v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
	v_ITERATOR_ID NUMBER(9);


	PROCEDURE ADD_VAR
		(
		p_VAR_NAME IN VARCHAR2,
		p_VAR_VAL IN NUMBER
		) AS
	BEGIN

		IF NOT p_VAR_VAL IS NULL THEN
			v_FORMULA_CHARGE_VAR.VARIABLE_NAME := p_VAR_NAME;
			v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_VAR_VAL;
			PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		END IF;
	END ADD_VAR;
BEGIN
	-- null charge ID? then skip it
	IF p_CHARGE_ID IS NULL THEN RETURN; END IF;

	v_ITERATOR_ID := GET_SOURCE_SINK_ITERATOR_ID(p_CHARGE_ID, p_SOURCE_NAME, p_SINK_NAME);

	v_FORMULA_CHARGE_VAR.CHARGE_DATE := p_CHARGE_DATE;
	v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR_ID;
	v_FORMULA_CHARGE_VAR.CHARGE_ID := p_CHARGE_ID;

	--ADD FORMULA CHARGE VARIABLES IF VALUES ARE NOT NULL.
	ADD_VAR('DALoad', p_DA_LOAD);
	ADD_VAR('DAGen', -1 * p_DA_GEN);
	ADD_VAR('DAPurch', -1 * p_DA_PURCH);
	ADD_VAR('DASales', p_DA_SALES);
	ADD_VAR('Inc', -1 * p_INC);
	ADD_VAR('Dec', p_DEC);
	ADD_VAR('RTLoad', p_RT_LOAD);
	ADD_VAR('RTGen', -1 * p_RT_GEN);
	ADD_VAR('RTPurch', -1 * p_RT_PURCH);
	ADD_VAR('RTSales', p_RT_SALES);

	--MAKE SURE A FORMULA CHARGE ROW EXISTS.
	v_FORMULA_CHARGE := GET_FORMULA_CHARGE(p_CHARGE_ID, p_CHARGE_DATE, v_ITERATOR_ID);
	PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

END PUT_LMP_FORMULA_CHARGE_VAR;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_LMP_FORMULA_CHARGE_VAR_RT
	(
	p_CHARGE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_SINK_NAME IN VARCHAR2,
	p_SOURCE_NAME IN VARCHAR2,
	p_RT_LOAD IN NUMBER,
	p_RT_GEN IN NUMBER,
	p_RT_PURCH IN NUMBER,
	p_RT_SALES IN NUMBER
	) AS
BEGIN
	PUT_LMP_FORMULA_CHARGE_VAR(p_CHARGE_ID, p_CHARGE_DATE, p_SINK_NAME, p_SOURCE_NAME, NULL, NULL, NULL, NULL, NULL, NULL,
			p_RT_LOAD, p_RT_GEN, p_RT_PURCH, p_RT_SALES);
END PUT_LMP_FORMULA_CHARGE_VAR_RT;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_LMP_FORMULA_CHARGE_VAR_DA
	(
	p_CHARGE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_SOURCE_NAME IN VARCHAR2,
	p_SINK_NAME IN VARCHAR2,
	p_DA_LOAD IN NUMBER,
	p_DA_GEN IN NUMBER,
	p_DA_PURCH IN NUMBER,
	p_DA_SALES IN NUMBER,
	p_INC IN NUMBER,
	p_DEC IN NUMBER
	) AS
BEGIN
	PUT_LMP_FORMULA_CHARGE_VAR(p_CHARGE_ID, p_CHARGE_DATE, p_SINK_NAME, p_SOURCE_NAME,
			p_DA_LOAD, p_DA_GEN, p_DA_PURCH, p_DA_SALES, p_INC, p_DEC, NULL, NULL, NULL, NULL);
END PUT_LMP_FORMULA_CHARGE_VAR_DA;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_LMP_FORMULA_CHARGE
	(
	p_CHARGE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_SOURCE_NAME IN VARCHAR2,
	p_SINK_NAME IN VARCHAR2,
	p_CHARGE_QUANTITY IN NUMBER,
	p_CHARGE_RATE IN NUMBER,
	p_CHARGE_AMOUNT IN NUMBER,
	p_CHARGE_FACTOR IN NUMBER
	) AS

v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_ITERATOR_ID NUMBER(9);
BEGIN
	-- null charge ID? then skip it
	IF p_CHARGE_ID IS NULL THEN RETURN; END IF;

	v_ITERATOR_ID := GET_SOURCE_SINK_ITERATOR_ID(p_CHARGE_ID, p_SOURCE_NAME, p_SINK_NAME);
	v_FORMULA_CHARGE := GET_FORMULA_CHARGE(p_CHARGE_ID, p_CHARGE_DATE, v_ITERATOR_ID);


--	IF p_CHARGE_RATE IS NULL AND v_FORMULA_CHARGE.CHARGE_RATE IS NULL THEN
--		v_FORMULA_CHARGE.CHARGE_RATE := NVL(p_PRICE1,0)-NVL(p_PRICE2,0);

	IF NOT p_CHARGE_RATE IS NULL THEN v_FORMULA_CHARGE.CHARGE_RATE := p_CHARGE_RATE; END IF;
	IF NOT p_CHARGE_QUANTITY IS NULL THEN v_FORMULA_CHARGE.CHARGE_QUANTITY := p_CHARGE_QUANTITY; END IF;
	IF NOT p_CHARGE_FACTOR IS NULL THEN v_FORMULA_CHARGE.CHARGE_FACTOR := p_CHARGE_FACTOR; END IF;
	IF NOT p_CHARGE_AMOUNT IS NULL THEN v_FORMULA_CHARGE.CHARGE_AMOUNT := p_CHARGE_AMOUNT; END IF;

	PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

END PUT_LMP_FORMULA_CHARGE;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_LMP_FORMULA_CHARGE
	(
	p_CHARGE_ID IN NUMBER,
	p_CHARGE_DATE IN DATE,
	p_CHARGE_QUANTITY IN NUMBER,
	p_CHARGE_RATE IN NUMBER,
	p_CHARGE_AMOUNT IN NUMBER,
	p_CHARGE_FACTOR IN NUMBER
	) AS
--NO ITERATOR NECESSARY.
BEGIN
	PUT_LMP_FORMULA_CHARGE(p_CHARGE_ID, p_CHARGE_DATE, NULL, NULL,
		p_CHARGE_QUANTITY, p_CHARGE_RATE, p_CHARGE_AMOUNT, p_CHARGE_FACTOR);
END PUT_LMP_FORMULA_CHARGE;
----------------------------------------------------------------------------------------------------
FUNCTION PUT_SERVICE_POINT(p_POINT_NAME IN VARCHAR2)
	RETURN SERVICE_POINT.SERVICE_POINT_ID%TYPE IS
	v_SERVICE_POINT_ID SERVICE_POINT.SERVICE_POINT_ID%TYPE;
BEGIN
	IO.PUT_SERVICE_POINT(o_OID                     => v_SERVICE_POINT_ID,
											 p_SERVICE_POINT_NAME      => p_POINT_NAME,
											 p_SERVICE_POINT_ALIAS     => p_POINT_NAME,
											 p_SERVICE_POINT_DESC      => 'Created by MarketManager',
											 p_SERVICE_POINT_ID        => 0,
											 p_SERVICE_POINT_TYPE      => 'Retail',
											 p_TP_ID                   => 0,
											 p_CA_ID                   => 0,
											 p_EDC_ID                  => 0,
											 p_ROLLUP_ID               => 0,
											 p_SERVICE_REGION_ID       => 0,
											 p_SERVICE_AREA_ID         => 0,
											 p_SERVICE_ZONE_ID         => 0,
											 p_TIME_ZONE               => LOCAL_TIME_ZONE,
											 p_LATITUDE                => NULL,
											 p_LONGITUDE               => NULL,
											 p_EXTERNAL_IDENTIFIER     => NULL,
											 p_IS_INTERCONNECT         => 0,
											 p_NODE_TYPE               => 'Bus',
											 p_SERVICE_POINT_NERC_CODE => NULL,
											 p_PIPELINE_ID => 0,
											 p_MILE_MARKER => 0
											 );
  RETURN v_SERVICE_POINT_ID;
END PUT_SERVICE_POINT;
----------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_COMBINATION_CHARGE
	(
	p_CHARGE_ID IN NUMBER,
	p_COMBINED_CHARGE_ID IN NUMBER,
	p_CHARGE_TABLE IN VARCHAR2,
    p_MULTIPLIER IN NUMBER := 1,
    p_DATE IN DATE := SYSDATE,
    p_COMPONENT_ID IN NUMBER := 0
	) AS
v_CHARGE_QUANTITY NUMBER;
v_CHARGE_RATE NUMBER;
v_CHARGE_AMOUNT NUMBER;
v_TEST NUMBER;
BEGIN
	IF p_CHARGE_TABLE = 'LMP' THEN
		SELECT SUM(CHARGE_QUANTITY), AVG(CHARGE_RATE), SUM(CHARGE_AMOUNT)
		INTO v_CHARGE_QUANTITY, v_CHARGE_RATE, v_CHARGE_AMOUNT
		FROM LMP_CHARGE
		WHERE CHARGE_ID = p_COMBINED_CHARGE_ID;
	ELSIF p_CHARGE_TABLE = 'FTR' THEN
		SELECT SUM(CHARGE_QUANTITY), AVG(CHARGE_RATE), SUM(CHARGE_AMOUNT)
		INTO v_CHARGE_QUANTITY, v_CHARGE_RATE, v_CHARGE_AMOUNT
		FROM FTR_CHARGE
		WHERE CHARGE_ID = p_COMBINED_CHARGE_ID;
	/*ELSIF p_CHARGE_TABLE = 'FORMULA' THEN
		SELECT SUM(CHARGE_QUANTITY), AVG(CHARGE_RATE), SUM(CHARGE_AMOUNT)
		INTO v_CHARGE_QUANTITY, v_CHARGE_RATE, v_CHARGE_AMOUNT
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = p_COMBINED_CHARGE_ID;
	ELSIF p_CHARGE_TABLE = 'COMBINATION' THEN
		SELECT SUM(CHARGE_QUANTITY), AVG(CHARGE_RATE), SUM(CHARGE_AMOUNT)
		INTO v_CHARGE_QUANTITY, v_CHARGE_RATE, v_CHARGE_AMOUNT
		FROM COMBINATION_CHARGE
		WHERE CHARGE_ID = p_COMBINED_CHARGE_ID;*/
    ELSIF p_CHARGE_TABLE = 'FORMULA' THEN
		SELECT SUM(CHARGE_QUANTITY), SUM(CHARGE_AMOUNT)
		INTO v_CHARGE_QUANTITY, v_CHARGE_AMOUNT
		FROM FORMULA_CHARGE
		WHERE CHARGE_ID = p_COMBINED_CHARGE_ID;
        IF v_CHARGE_QUANTITY <> 0 THEN
            v_CHARGE_RATE := v_CHARGE_AMOUNT / v_CHARGE_QUANTITY;
        ELSE
            v_CHARGE_RATE := 0;
        END IF;
	ELSIF p_CHARGE_TABLE = 'COMBINATION' THEN
		SELECT SUM(CHARGE_QUANTITY), AVG(CHARGE_RATE), SUM(CHARGE_AMOUNT)
		INTO v_CHARGE_QUANTITY, v_CHARGE_RATE, v_CHARGE_AMOUNT
		FROM COMBINATION_CHARGE
		WHERE CHARGE_ID = p_COMBINED_CHARGE_ID;
        IF v_CHARGE_QUANTITY <> 0 THEN
            v_CHARGE_RATE := v_CHARGE_AMOUNT / v_CHARGE_QUANTITY;
        ELSE
            v_CHARGE_RATE := 0;
        END IF;
	END IF;

	BEGIN
        SELECT CHARGE_ID INTO v_TEST
        FROM COMBINATION_CHARGE
        WHERE CHARGE_ID = p_CHARGE_ID
        AND COMBINED_CHARGE_ID = p_COMBINED_CHARGE_ID;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO COMBINATION_CHARGE (
			CHARGE_ID, COMPONENT_ID, BEGIN_DATE, END_DATE,
			COMBINED_CHARGE_ID, CHARGE_VIEW_TYPE, COEFFICIENT,
			CHARGE_FACTOR, ENTRY_DATE)
		VALUES (
			p_CHARGE_ID, p_COMPONENT_ID, p_DATE, p_DATE,
			p_COMBINED_CHARGE_ID, p_CHARGE_TABLE, 1.0,
			1.0, SYSDATE);
        END;

    UPDATE COMBINATION_CHARGE
		SET CHARGE_QUANTITY = v_CHARGE_QUANTITY,
			CHARGE_RATE = v_CHARGE_RATE,
			CHARGE_AMOUNT = p_MULTIPLIER * v_CHARGE_AMOUNT
		WHERE CHARGE_ID = p_CHARGE_ID
			AND COMBINED_CHARGE_ID = p_COMBINED_CHARGE_ID;
END UPDATE_COMBINATION_CHARGE;
----------------------------------------------------------------------------------------------------
-- These routines are private routines used by the public ones for actually putting the data
-- into RO/MM tables.
----------------------------------------------------------------------------------------------------
  PROCEDURE IMPORT_MONTHLY_STATEMENT
	(
	p_RECORDS IN MEX_PJM_MONTHLY_STATEMENT_TBL,
	p_STATUS OUT NUMBER
	) AS
v_PSE_ID NUMBER(9);
v_PRODUCT_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_INVOICE_ROW INVOICE%ROWTYPE;
v_NUM_LINE_ITEMS NUMBER;
v_INVOICE_LINE_ITEM INVOICE_LINE_ITEM%ROWTYPE;
v_INVOICE_ADJ_LINE_ITEM INVOICE_USER_LINE_ITEM%ROWTYPE;
v_IDX BINARY_INTEGER;
v_AS_OF_DATE DATE := SYSDATE;
v_AMT NUMBER;
v_TOTAL_SO_FAR NUMBER := 0;
v_LINE_ITEM_NAME VARCHAR2(128);
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
	IF NOT GA.VERSION_STATEMENT THEN
		v_AS_OF_DATE := LOW_DATE;
	END IF;

	v_PSE_ID := GET_PSE(p_RECORDS(v_IDX).ORG_ID, p_RECORDS(v_IDX).ORG_NAME);

    -- clear out existing/old invoice
    DELETE INVOICE WHERE ENTITY_ID = v_PSE_ID
          AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
          AND BEGIN_DATE = p_RECORDS(v_IDX).BEGIN_DATE AND AS_OF_DATE = v_AS_OF_DATE;
    DELETE INVOICE_USER_LINE_ITEM WHERE ENTITY_ID = v_PSE_ID
          AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
          AND BEGIN_DATE = p_RECORDS(v_IDX).BEGIN_DATE;
	-- and clear out billing statement
/*	DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID
          AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
          AND STATEMENT_DATE = p_RECORDS(v_IDX).BEGIN_DATE AND AS_OF_DATE = v_AS_OF_DATE;*/

    PC.GET_INVOICE (v_PSE_ID,'PSE',g_STATEMENT_TYPE, p_RECORDS(v_IDX).BEGIN_DATE, v_AS_OF_DATE, v_INVOICE_ROW);
    -- is this an existing internal invoice?
    SELECT COUNT(*) INTO v_NUM_LINE_ITEMS FROM INVOICE_LINE_ITEM
    WHERE INVOICE_ID = v_INVOICE_ROW.INVOICE_ID;
    IF v_NUM_LINE_ITEMS > 0 THEN
        -- existing invoice? then don't overwrite it - get new ID before doing PUT
        SELECT BID.NEXTVAL INTO v_INVOICE_ROW.INVOICE_ID FROM DUAL;
    END IF;
    v_INVOICE_ROW.STATEMENT_STATE := g_EXTERNAL_STATE;
	v_INVOICE_ROW.END_DATE := p_RECORDS(v_IDX).END_DATE;
    v_INVOICE_ROW.INVOICE_DATE := p_RECORDS(v_IDX).END_DATE+1;
    -- save invoice
    PC.PUT_INVOICE(v_INVOICE_ROW);
	-- init line item records
	v_INVOICE_LINE_ITEM.INVOICE_ID := v_INVOICE_ROW.INVOICE_ID;
	v_INVOICE_LINE_ITEM.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_INVOICE_LINE_ITEM.BEGIN_DATE := v_INVOICE_ROW.BEGIN_DATE;
	v_INVOICE_LINE_ITEM.END_DATE := v_INVOICE_ROW.END_DATE;
	v_INVOICE_LINE_ITEM.DEFAULT_DISPLAY := 'CHARGE';
	v_INVOICE_LINE_ITEM.LINE_ITEM_OPTION := 'By Component';
	v_INVOICE_ADJ_LINE_ITEM.ENTITY_ID := v_PSE_ID;
	v_INVOICE_ADJ_LINE_ITEM.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_INVOICE_ADJ_LINE_ITEM.STATEMENT_STATE := g_EXTERNAL_STATE;
	v_INVOICE_ADJ_LINE_ITEM.BEGIN_DATE := p_RECORDS(v_IDX).BEGIN_DATE;
	v_INVOICE_ADJ_LINE_ITEM.DEFAULT_DISPLAY := 'CHARGE';
	v_INVOICE_ADJ_LINE_ITEM.LINE_ITEM_POSTED_DATE := v_INVOICE_ROW.INVOICE_DATE;
	v_INVOICE_ADJ_LINE_ITEM.LINE_ITEM_TYPE := 'A';
 	-- init billing statement record
	v_BILLING_STATEMENT.ENTITY_ID := v_PSE_ID;
	v_BILLING_STATEMENT.ENTITY_TYPE := 'PSE';
	v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := g_EXTERNAL_STATE;
	v_BILLING_STATEMENT.STATEMENT_DATE := p_RECORDS(v_IDX).BEGIN_DATE;
	v_BILLING_STATEMENT.STATEMENT_END_DATE := p_RECORDS(v_IDX).END_DATE;
	v_BILLING_STATEMENT.AS_OF_DATE := v_AS_OF_DATE;

    -- now get invoice line items and billing statement items
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		v_AMT := p_RECORDS(v_IDX).LINE_ITEM_AMOUNT;
		IF p_RECORDS(v_IDX).IS_CREDIT=1 THEN
			v_AMT := -v_AMT;
		END IF;
		IF p_RECORDS(v_IDX).IS_TOTAL=1 THEN
			IF v_TOTAL_SO_FAR <> v_AMT THEN
				-- log error message
				LOGS.LOG_WARN('Error importing statement: Total in statement file ('||v_AMT||') does not match total imported ('||v_TOTAL_SO_FAR||')');
			END IF;
		ELSE
			v_TOTAL_SO_FAR := v_TOTAL_SO_FAR + v_AMT;
--			IF UPPER(SUBSTR(p_RECORDS(v_IDX).LINE_ITEM_NAME,1,4)) = 'ADJ.' THEN
				-- add adjustment to invoice as manual line item
		--		v_INVOICE_ADJ_LINE_ITEM.LINE_ITEM_NAME := p_RECORDS(v_IDX).LINE_ITEM_NAME;
		--		v_INVOICE_ADJ_LINE_ITEM.LINE_ITEM_QUANTITY := v_AMT;
		--		v_INVOICE_ADJ_LINE_ITEM.LINE_ITEM_RATE := 1;
	--			v_INVOICE_ADJ_LINE_ITEM.LINE_ITEM_AMOUNT := v_AMT;
	--			BSJ.PUT_INVOICE_USER_LINE_ITEM(v_INVOICE_ADJ_LINE_ITEM);
--			ELSE
				-- add billing statement entry as well as invoice line item
                -- trim out '- Mon YYYY' from line item name if needed
                --v_LINE_ITEM_NAME := TRIM_COMPONENT_NAME(p_RECORDS(v_IDX).LINE_ITEM_NAME);
                v_LINE_ITEM_NAME := (p_RECORDS(v_IDX).LINE_ITEM_NAME);
				GET_PRODUCT_COMPONENT(v_LINE_ITEM_NAME,v_PRODUCT_ID,v_COMPONENT_ID);

                --don't delete / put billing_statement for daily charges
                IF GET_IS_DAILY_CHARGE(v_COMPONENT_ID) = FALSE THEN
                    DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID = v_COMPONENT_ID
                    AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
                    AND STATEMENT_DATE = p_RECORDS(v_IDX).BEGIN_DATE AND AS_OF_DATE = v_AS_OF_DATE;
    				v_BILLING_STATEMENT.PRODUCT_ID := v_PRODUCT_ID;
    				v_BILLING_STATEMENT.COMPONENT_ID := v_COMPONENT_ID;
    				v_BILLING_STATEMENT.CHARGE_VIEW_TYPE := 'BILLING CHARGE'; -- default - override when we import details
    				v_BILLING_STATEMENT.CHARGE_QUANTITY := v_AMT;
    				v_BILLING_STATEMENT.CHARGE_RATE := 1;
    				v_BILLING_STATEMENT.CHARGE_AMOUNT := v_AMT;
    				v_BILLING_STATEMENT.BILL_QUANTITY := v_BILLING_STATEMENT.CHARGE_QUANTITY;
    				v_BILLING_STATEMENT.BILL_AMOUNT := v_BILLING_STATEMENT.CHARGE_AMOUNT;
    				PC.GET_CHARGE_ID(v_BILLING_STATEMENT);
                    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                END IF;
				v_INVOICE_LINE_ITEM.LINE_ITEM_NAME := p_RECORDS(v_IDX).LINE_ITEM_NAME;
				v_INVOICE_LINE_ITEM.COMPONENT_ID := v_COMPONENT_ID;
				v_INVOICE_LINE_ITEM.LINE_ITEM_QUANTITY := v_AMT;
				v_INVOICE_LINE_ITEM.LINE_ITEM_RATE := 1;
				v_INVOICE_LINE_ITEM.LINE_ITEM_AMOUNT := v_AMT;
				v_INVOICE_LINE_ITEM.LINE_ITEM_BILL_AMOUNT := v_AMT;
				PC.PUT_INVOICE_LINE_ITEM(v_INVOICE_LINE_ITEM);
                -- fill schedule if non-shadowed charge
                FILL_NON_SHADOWED_TXNS(v_PSE_ID, v_COMPONENT_ID, v_AMT, p_RECORDS(v_IDX).BEGIN_DATE);
--			END IF;
		END IF;
		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_MONTHLY_STATEMENT;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPOT_SUMMARY
	(
	p_STATUS OUT NUMBER
	) AS
v_DA_SPOT_CH_ID NUMBER(9);
v_RT_SPOT_CH_ID NUMBER(9);
v_DA_SPOT_CHG_COMP NUMBER(9);
v_BAL_SPOT_CHG_COMP NUMBER(9);
v_PSE_ID NUMBER(9);
--v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_BILLING_STATEMENT_1 BILLING_STATEMENT%ROWTYPE;
v_BILLING_STATEMENT_2 BILLING_STATEMENT%ROWTYPE;

CURSOR p_SPOT IS
    SELECT * FROM PJM_SPOT_MARKET_ENERGY_SUMMARY
    ORDER BY DAY, HOUR;

BEGIN
    p_STATUS := GA.SUCCESS;

    v_DA_SPOT_CHG_COMP := GET_COMPONENT('PJM-1200');
    v_BAL_SPOT_CHG_COMP := GET_COMPONENT('PJM-1205');

    v_BILLING_STATEMENT_1.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_1.STATEMENT_TYPE := g_STATEMENT_TYPE;
    v_BILLING_STATEMENT_1.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_1.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_1.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT_1.Product_Id := GET_PRODUCT(v_DA_SPOT_CHG_COMP);

    v_BILLING_STATEMENT_2.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_2.STATEMENT_TYPE := g_STATEMENT_TYPE;
    v_BILLING_STATEMENT_2.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_2.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_2.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT_2.Product_Id := GET_PRODUCT(v_BAL_SPOT_CHG_COMP);

    FOR v_SPOT IN p_SPOT LOOP

        IF v_LAST_ORG_ID <> v_SPOT.Org_Nid OR v_LAST_DATE <> TRUNC(v_SPOT.Day,'DD') THEN
            --put billing statement for previous day
            IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);

                v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

                v_BILLING_STATEMENT_1.Charge_Quantity :=0;
                v_BILLING_STATEMENT_1.Charge_Amount := 0;
                v_BILLING_STATEMENT_1.Bill_Quantity := 0;
                v_BILLING_STATEMENT_1.Bill_Amount := 0;
                v_BILLING_STATEMENT_2.Charge_Quantity := 0;
                v_BILLING_STATEMENT_2.Charge_Amount := 0;
                v_BILLING_STATEMENT_2.Bill_Quantity := 0;
                v_BILLING_STATEMENT_2.Bill_Amount := 0;
        END IF;

            v_LAST_ORG_ID := v_SPOT.Org_Nid;
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_LAST_DATE := TRUNC(v_SPOT.Day,'DD');
            v_BILLING_STATEMENT_1.Entity_Id := v_PSE_ID;
            v_BILLING_STATEMENT_2.Entity_Id := v_PSE_ID;

			-- get charge IDs
			v_DA_SPOT_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_DA_SPOT_CHG_COMP,v_LAST_DATE,'Formula');
			v_RT_SPOT_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_BAL_SPOT_CHG_COMP,v_LAST_DATE,'Formula');

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID
            IN(v_DA_SPOT_CHG_COMP, v_BAL_SPOT_CHG_COMP)
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;
		END IF;

		-- put the data
        v_CHARGE_DATE := GET_CHARGE_DATE(v_SPOT.Day, v_SPOT.Hour, v_SPOT.Dst);

        IF NOT v_SPOT.Da_Spot_Market_Energy_Charge IS NULL THEN

            PUT_LMP_FORMULA_CHARGE(v_DA_SPOT_CH_ID,v_CHARGE_DATE,
    							v_SPOT.Da_Spot_Market_Net_Interchange,
    							v_SPOT.Da_Pjm_Energy_Price,
    							v_SPOT.Da_Spot_Market_Energy_Charge, 1);
		END IF;
        v_BILLING_STATEMENT_1.Component_Id := v_DA_SPOT_CHG_COMP;
        v_BILLING_STATEMENT_1.CHARGE_Id := v_DA_SPOT_CH_ID;
        v_BILLING_STATEMENT_1.Charge_Quantity := NVL(v_BILLING_STATEMENT_1.Charge_Quantity,0) + NVL(v_SPOT.Da_Spot_Market_Energy_Charge,0);
        v_BILLING_STATEMENT_1.Charge_Rate := 1;
        v_BILLING_STATEMENT_1.Charge_Amount := NVL(v_BILLING_STATEMENT_1.Charge_Amount,0) + NVL(v_SPOT.Da_Spot_Market_Energy_Charge,0);
        v_BILLING_STATEMENT_1.Bill_Quantity := NVL(v_BILLING_STATEMENT_1.Bill_Quantity,0) + NVL(v_SPOT.Da_Spot_Market_Energy_Charge,0);
        v_BILLING_STATEMENT_1.Bill_Amount := NVL(v_BILLING_STATEMENT_1.Bill_Amount,0) + NVL(v_SPOT.Da_Spot_Market_Energy_Charge,0);

        IF NOT v_SPOT.Bal_Spot_Market_Energy_Charge IS NULL THEN

            PUT_LMP_FORMULA_CHARGE(v_RT_SPOT_CH_ID,v_CHARGE_DATE,
    							v_SPOT.Rt_Spot_Market_Net_Interchange,
    							v_SPOT.Rt_Pjm_Energy_Price,
    							v_SPOT.Bal_Spot_Market_Energy_Charge, 1);
		END IF;

        v_BILLING_STATEMENT_2.Component_Id := v_BAL_SPOT_CHG_COMP;
        v_BILLING_STATEMENT_2.CHARGE_Id := v_RT_SPOT_CH_ID;
        v_BILLING_STATEMENT_2.Charge_Quantity := NVL(v_BILLING_STATEMENT_2.Charge_Quantity,0) + NVL(v_SPOT.Bal_Spot_Market_Energy_Charge,0);
        v_BILLING_STATEMENT_2.Charge_Rate := 1;
        v_BILLING_STATEMENT_2.Charge_Amount := NVL(v_BILLING_STATEMENT_2.Charge_Amount,0) + NVL(v_SPOT.Bal_Spot_Market_Energy_Charge,0);
        v_BILLING_STATEMENT_2.Bill_Quantity := NVL(v_BILLING_STATEMENT_2.Bill_Quantity,0) + NVL(v_SPOT.Bal_Spot_Market_Energy_Charge,0);
        v_BILLING_STATEMENT_2.Bill_Amount := NVL(v_BILLING_STATEMENT_2.Bill_Amount,0) + NVL(v_SPOT.Bal_Spot_Market_Energy_Charge,0);

	END LOOP;

    v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);

    v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

    DELETE FROM PJM_SPOT_MARKET_ENERGY_SUMMARY;
    COMMIT;

END IMPORT_SPOT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CONGESTION_SUMMARY
	(
	p_STATUS OUT NUMBER
	) AS

v_DA_CONG_CH_ID NUMBER(9);
v_DA_CONG_CH_ID_IMP NUMBER(9);
v_RT_CONG_CH_ID NUMBER(9);
v_RT_CONG_CH_ID_IMP NUMBER(9);
v_RT_SPOT_CH_ID NUMBER(9);
v_CONG_CR_FTR_ID NUMBER(9);
v_CONG_CR_ID NUMBER(9);
v_CONG_CR_MISC_ID NUMBER(9);
v_ALLOC_FACTOR_TX_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_DA_CONG_COMP NUMBER(9);
v_BAL_CONG_COMP NUMBER(9);
v_CONG_CRED_COMP NUMBER(9);
v_PSE_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_UTS_ALLOC_TX_ID NUMBER(9);
v_MONTHLY_ALLOC_TX_ID NUMBER(9);
v_CHARGE_RATE NUMBER;
v_CHARGE_AMOUNT NUMBER;
v_ALLOC_FACTOR NUMBER;
v_PSE_NAME VARCHAR2(32);
v_FTR_TARGET_ALLOC_TOTAL NUMBER := 0;
v_FTR_CONG_CRED_TOTAL NUMBER := 0;
v_CONG_FLAG_TXN NUMBER(9);
v_TEST NUMBER;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_BILLING_STATEMENT_1 BILLING_STATEMENT%ROWTYPE;
v_BILLING_STATEMENT_2 BILLING_STATEMENT%ROWTYPE;

CURSOR p_CONG IS
    SELECT * FROM PJM_CONGESTION_SUMMARY C
    ORDER BY C.DAY, C.HOUR;

	PROCEDURE ROLL_UP_SPOT_CHARGE
		(
		p_CHARGE_CHARGE_ID IN NUMBER,
		p_CREDIT_CHARGE_ID IN NUMBER,
		p_RESULT_CHARGE_ID IN NUMBER
		) IS
		v_CHARGE_AMOUNT NUMBER;
		v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
	--Roll the Spot Charge up to the monthly **Cong:Spot charge so that
	--it can be used in the total Congestion Charge comparison.
	BEGIN
		SELECT SUM(A.CHARGE_AMOUNT)
		INTO v_CHARGE_AMOUNT
		FROM FORMULA_CHARGE A
		WHERE A.CHARGE_ID IN (p_CHARGE_CHARGE_ID, p_CREDIT_CHARGE_ID)
			AND A.ITERATOR_ID = 0;

		v_FORMULA_CHARGE.CHARGE_ID := p_RESULT_CHARGE_ID;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE.CHARGE_DATE := v_LAST_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE := 1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := v_CHARGE_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END ROLL_UP_SPOT_CHARGE;

	PROCEDURE UPDATE_COMBINATION_CHARGES IS
    v_COMPONENT NUMBER(9);
	BEGIN

		--Roll everything all the values up the combination tree.
		IF NOT v_DA_CONG_CH_ID IS NULL THEN
			UPDATE_COMBINATION_CHARGE(v_DA_CONG_CH_ID,v_DA_CONG_CH_ID_IMP,'FORMULA',1, v_LAST_DATE, GET_COMPONENT('PJM:DATransCongChg:Imp'));
            --this was combination
		END IF;

		IF NOT v_RT_CONG_CH_ID IS NULL THEN
			UPDATE_COMBINATION_CHARGE(v_RT_CONG_CH_ID,v_RT_CONG_CH_ID_IMP,'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:BalTransCongChg:Imp'));
		END IF;

		IF NOT v_CONG_CR_ID IS NULL THEN
			UPDATE_COMBINATION_CHARGE(v_CONG_CR_ID, v_CONG_CR_MISC_ID, 'FORMULA',-1, v_LAST_DATE, GET_COMPONENT('PJM:TxCongCred:Misc'));
            --UPDATE FTR portion
            IF v_FTR_TARGET_ALLOC_TOTAL <> 0 THEN
                v_CHARGE_RATE := v_FTR_CONG_CRED_TOTAL / v_FTR_TARGET_ALLOC_TOTAL;
            ELSE
                v_CHARGE_RATE := 0;
            END IF;

            BEGIN
                SELECT CHARGE_ID INTO v_TEST
                FROM COMBINATION_CHARGE
                WHERE CHARGE_ID = v_CONG_CR_ID
                AND COMBINED_CHARGE_ID = v_CONG_CR_FTR_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_COMPONENT := GET_COMPONENT('PJM:TransCongCred:FTR');
                INSERT INTO COMBINATION_CHARGE (
    			CHARGE_ID, COMPONENT_ID, BEGIN_DATE, END_DATE,
    			COMBINED_CHARGE_ID, CHARGE_VIEW_TYPE, COEFFICIENT,
    			CHARGE_FACTOR, ENTRY_DATE)
    		VALUES (
    			v_CONG_CR_ID, v_COMPONENT, v_LAST_DATE, v_LAST_DATE,
    			v_CONG_CR_FTR_ID, 'FTR', 1.0,
			    1.0, SYSDATE);
        END;

            UPDATE COMBINATION_CHARGE
		    SET CHARGE_QUANTITY = v_FTR_TARGET_ALLOC_TOTAL,
			CHARGE_RATE = v_CHARGE_RATE,
			CHARGE_AMOUNT = -v_FTR_CONG_CRED_TOTAL
		    WHERE CHARGE_ID = v_CONG_CR_ID
			AND COMBINED_CHARGE_ID = v_CONG_CR_FTR_ID;
		END IF;
	END;
BEGIN
    p_STATUS := GA.SUCCESS;

    v_DA_CONG_COMP := GET_COMPONENT('PJM-1210');
    v_BAL_CONG_COMP := GET_COMPONENT('PJM-1215');
    v_CONG_CRED_COMP := GET_COMPONENT('PJM-2210');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'COMBINATION';
    v_BILLING_STATEMENT.Component_Id := v_CONG_CRED_COMP;
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_CONG_CRED_COMP);
    v_BILLING_STATEMENT_1.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_1.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT_1.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_1.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_1.Charge_View_Type := 'COMBINATION';
    v_BILLING_STATEMENT_1.Component_Id := v_DA_CONG_COMP;
    v_BILLING_STATEMENT_1.Product_Id := GET_PRODUCT(v_DA_CONG_COMP);
    v_BILLING_STATEMENT_2.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_2.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT_2.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_2.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_2.Charge_View_Type := 'COMBINATION';
    v_BILLING_STATEMENT_2.Component_Id := v_BAL_CONG_COMP;
    v_BILLING_STATEMENT_2.Product_Id := GET_PRODUCT(v_BAL_CONG_COMP);

    FOR v_CONG IN p_CONG LOOP
        IF v_LAST_ORG_ID <> v_CONG.Org_Nid OR v_LAST_DATE <> TRUNC(v_CONG.Day,'DD') THEN
		    -- flush last month's charges to combination charge table
			UPDATE_COMBINATION_CHARGES;

            IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);
                v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

                v_BILLING_STATEMENT.Charge_Quantity :=0;
                v_BILLING_STATEMENT.Charge_Amount := 0;
                v_BILLING_STATEMENT.Bill_Quantity := 0;
                v_BILLING_STATEMENT.Bill_Amount := 0;
                v_BILLING_STATEMENT_1.Charge_Quantity :=0;
                v_BILLING_STATEMENT_1.Charge_Amount := 0;
                v_BILLING_STATEMENT_1.Bill_Quantity := 0;
                v_BILLING_STATEMENT_1.Bill_Amount := 0;
                v_BILLING_STATEMENT_2.Charge_Quantity := 0;
                v_BILLING_STATEMENT_2.Charge_Amount := 0;
                v_BILLING_STATEMENT_2.Bill_Quantity := 0;
                v_BILLING_STATEMENT_2.Bill_Amount := 0;

                v_FTR_CONG_CRED_TOTAL := 0;
                v_FTR_TARGET_ALLOC_TOTAL := 0;

            END IF;
		   	-- get charge IDs for this month and this PSE.  Build the combo tree if it does not exist.
            v_LAST_ORG_ID := v_CONG.Org_Nid;
			v_LAST_DATE := TRUNC(v_CONG.Day,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;
            v_BILLING_STATEMENT_1.Entity_Id := v_PSE_ID;
            v_BILLING_STATEMENT_2.Entity_Id := v_PSE_ID;
            SELECT PSE_ALIAS INTO v_PSE_NAME FROM PURCHASING_SELLING_ENTITY
    		WHERE PSE_ID = v_PSE_ID;
			v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

            v_CONG_FLAG_TXN := GET_TX_ID('PJMCongestionFlag:' || v_PSE_NAME, 'Congestion Flag',
                                        'PJMCongestionFlag:' || v_PSE_NAME, 'Hour', 0, v_CONTRACT_ID);

			v_DA_CONG_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_DA_CONG_COMP,v_LAST_DATE,'COMBINATION');
			v_COMPONENT_ID := GET_COMPONENT('PJM:DATransCongChg:Imp');
			v_DA_CONG_CH_ID_IMP := GET_COMBO_CHARGE_ID(v_DA_CONG_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);

			v_RT_CONG_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_BAL_CONG_COMP,v_LAST_DATE,'COMBINATION');
			v_COMPONENT_ID := GET_COMPONENT('PJM:BalTransCongChg:Imp');
			v_RT_CONG_CH_ID_IMP := GET_COMBO_CHARGE_ID(v_RT_CONG_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);

			v_CONG_CR_ID := GET_CHARGE_ID(v_PSE_ID, v_CONG_CRED_COMP, v_LAST_DATE, 'COMBINATION');
			v_COMPONENT_ID := GET_COMPONENT('PJM:TxCongCred:Misc');
			v_CONG_CR_MISC_ID := GET_COMBO_CHARGE_ID(v_CONG_CR_ID, v_COMPONENT_ID, v_LAST_DATE, 'Formula', TRUE);
            v_COMPONENT_ID := GET_COMPONENT('PJM:TransCongCred:FTR');
			v_CONG_CR_FTR_ID := GET_COMBO_CHARGE_ID(v_CONG_CR_ID, v_COMPONENT_ID, v_LAST_DATE, 'FTR', TRUE);

			--Get the Transaction IDS to store internal results for the CREDIT.
			v_UTS_ALLOC_TX_ID := GET_TX_ID(NULL, 'UTSAlloc', 'UTS Allocation', 'Hour', 0, v_CONTRACT_ID);
			v_MONTHLY_ALLOC_TX_ID := GET_TX_ID(NULL, 'MonthlyAlloc', 'Monthly Excess Allocation', 'Hour', 0, v_CONTRACT_ID);

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID
            IN(v_DA_CONG_COMP, v_BAL_CONG_COMP, v_CONG_CRED_COMP)
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;
		END IF;

		-- put the Implicit Transmission Congestion Charges.
		v_CHARGE_DATE := GET_CHARGE_DATE(v_CONG.Day, v_CONG.Hour, v_CONG.Dst);

        v_BILLING_STATEMENT_1.Charge_Id := v_DA_CONG_CH_ID;
        v_BILLING_STATEMENT_1.Charge_Quantity := NVL(v_BILLING_STATEMENT_1.Charge_Quantity,0) + NVL(v_CONG.Day_Ahead_Imp_Cong_Charge,0) +
                                                    NVL(v_CONG.Day_Ahead_Exp_Cong_Charge,0);
        v_BILLING_STATEMENT_1.Charge_Amount := NVL(v_BILLING_STATEMENT_1.Charge_Amount,0) + NVL(v_CONG.Day_Ahead_Imp_Cong_Charge,0) +
                                                    NVL(v_CONG.Day_Ahead_Exp_Cong_Charge,0);
        v_BILLING_STATEMENT_1.Charge_Rate := 1;
        v_BILLING_STATEMENT_1.Bill_Quantity := NVL(v_BILLING_STATEMENT_1.Bill_Quantity,0) + NVL(v_CONG.Day_Ahead_Imp_Cong_Charge,0) +
                                                NVL(v_CONG.Day_Ahead_Exp_Cong_Charge,0);
        v_BILLING_STATEMENT_1.Bill_Amount := NVL(v_BILLING_STATEMENT_1.Bill_Amount,0) + NVL(v_CONG.Day_Ahead_Imp_Cong_Charge,0) +
                                                NVL(v_CONG.Day_Ahead_Exp_Cong_Charge,0);

        v_BILLING_STATEMENT_2.Charge_Id := v_RT_CONG_CH_ID;
        v_BILLING_STATEMENT_2.Charge_Quantity := NVL(v_BILLING_STATEMENT_2.Charge_Quantity,0) + NVL(v_CONG.Balancing_Imp_Cong_Charge,0) +
                                                    NVL(v_CONG.Balancing_Exp_Cong_Charge,0);
        v_BILLING_STATEMENT_2.Charge_Amount := NVL(v_BILLING_STATEMENT_2.Charge_Amount,0) + NVL(v_CONG.Balancing_Imp_Cong_Charge,0) +
                                                    NVL(v_CONG.Balancing_Exp_Cong_Charge,0);
        v_BILLING_STATEMENT_2.Charge_Rate := 1;
        v_BILLING_STATEMENT_2.Bill_Quantity := NVL(v_BILLING_STATEMENT_2.Bill_Quantity,0) + NVL(v_CONG.Balancing_Imp_Cong_Charge,0) +
                                                NVL(v_CONG.Balancing_Exp_Cong_Charge,0);
        v_BILLING_STATEMENT_2.Bill_Amount := NVL(v_BILLING_STATEMENT_2.Bill_Amount,0) + NVL(v_CONG.Balancing_Imp_Cong_Charge,0) +
                                                NVL(v_CONG.Balancing_Exp_Cong_Charge,0);

        v_BILLING_STATEMENT.Charge_Id := v_CONG_CR_ID;
        v_BILLING_STATEMENT.Charge_Quantity := NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + NVL(-v_CONG.Ftr_Target_Allocation,0);
        v_BILLING_STATEMENT.Charge_Amount := NVL(v_BILLING_STATEMENT.Charge_Amount,0) + NVL(-v_CONG.Ftr_Target_Allocation,0);
        v_BILLING_STATEMENT.Charge_Rate := 1;
        v_BILLING_STATEMENT.Bill_Quantity := NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + NVL(-v_CONG.Ftr_Target_Allocation,0);
        v_BILLING_STATEMENT.Bill_Amount := NVL(v_BILLING_STATEMENT.Bill_Amount,0) + NVL(-v_CONG.Ftr_Target_Allocation,0);

        PUT_SCHEDULE_VALUE(v_CONG_FLAG_TXN, v_CHARGE_DATE, 1);

		--===========DAY-AHEAD=======================

		--Put CHARGE_QUANTITY, RATE, AND AMOUNT for the Net Energy Bill Component.
       --this should be for implicit now
        PUT_LMP_FORMULA_CHARGE(v_DA_CONG_CH_ID_IMP, v_CHARGE_DATE,
					v_CONG.Day_Ahead_Cong_Wd_Mwh-v_CONG.Day_Ahead_Cong_Inj_Mwh,
					CASE
						WHEN v_CONG.Day_Ahead_Cong_Wd_Mwh-v_CONG.Day_Ahead_Cong_Inj_Mwh = 0 THEN
							NULL
						ELSE
							v_CONG.Day_Ahead_Imp_Cong_Charge /
								(v_CONG.Day_Ahead_Cong_Wd_Mwh-v_CONG.Day_Ahead_Cong_Inj_Mwh)
					END,
					v_CONG.Day_Ahead_Imp_Cong_Charge, 1);

 		--Put DALoad and DAGen
         --this should be for implicit now
 		PUT_LMP_FORMULA_CHARGE_VAR_DA(v_DA_CONG_CH_ID_IMP, v_CHARGE_DATE,
					NULL, NULL, --ITERATORs not used because PJM does not provide that level of detail.
 					v_CONG.Day_Ahead_Cong_Wd_Mwh, -1 * v_CONG.Day_Ahead_Cong_Inj_Mwh,
 					NULL, NULL, NULL, NULL);

		--===========REAL-TIME========================
		--Put CHARGE_QUANTITY, RATE, AND AMOUNT.
        PUT_LMP_FORMULA_CHARGE(v_RT_CONG_CH_ID_IMP, v_CHARGE_DATE,
					v_CONG.Balancing_Cong_Wd_Dev_Mwh-v_CONG.Balancing_Cong_Inj_Dev_Mwh,
					CASE
						WHEN v_CONG.Balancing_Cong_Wd_Dev_Mwh-v_CONG.Balancing_Cong_Inj_Dev_Mwh = 0 THEN
							NULL
						ELSE
							v_CONG.Balancing_Imp_Cong_Charge /
								(v_CONG.Balancing_Cong_Wd_Dev_Mwh-v_CONG.Balancing_Cong_Inj_Dev_Mwh)
					END,
					v_CONG.Balancing_Imp_Cong_Charge, 1);

		--Put DALoad, DAGen, RTLoad, and RTGen.
		PUT_LMP_FORMULA_CHARGE_VAR(v_RT_CONG_CH_ID_IMP, v_CHARGE_DATE,
					NULL, NULL, --ITERATORs not used because PJM does not provide that level of detail.
					v_CONG.Day_Ahead_Cong_Wd_Mwh, -1 * v_CONG.Day_Ahead_Cong_Inj_Mwh,
					NULL, NULL, NULL, NULL,
					v_CONG.Day_Ahead_Cong_Wd_Mwh+v_CONG.Balancing_Cong_Wd_Dev_Mwh,
					-1 * (v_CONG.Day_Ahead_Cong_Inj_Mwh+v_CONG.Balancing_Cong_Inj_Dev_Mwh),
					NULL, NULL
					);

		-- put the rt gen+purch and rt load+sales into charges and credits, so we can
		-- subtract out purch and sales once we import the rt daily txn report. Fix to bug 10900
		PUT_LMP_FORMULA_CHARGE_VAR_RT(v_RT_SPOT_CH_ID, v_CHARGE_DATE, NULL, NULL,
					v_CONG.Day_Ahead_Cong_Wd_Mwh+v_CONG.Balancing_Cong_Wd_Dev_Mwh,
					-1 * (v_CONG.Day_Ahead_Cong_Inj_Mwh+v_CONG.Balancing_Cong_Inj_Dev_Mwh),
					NULL, NULL);

--===========CREDITS========================
		--Put the Congestion Credit Misc Variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_CONG_CR_MISC_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'UTSAlloc';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_CONG.Credit_From_Uts;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		PUT_SCHEDULE_VALUE(v_UTS_ALLOC_TX_ID, v_CHARGE_DATE, v_CONG.Credit_From_Uts, NULL, TRUE);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlyAlloc';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_CONG.Credit_For_Monthly_Excess;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		PUT_SCHEDULE_VALUE(v_MONTHLY_ALLOC_TX_ID, v_CHARGE_DATE, v_CONG.Credit_For_Monthly_Excess, NULL, TRUE);

		--Put the Congestion Credit Misc Formula Charge.
		v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_FACTOR := 1;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE.CHARGE_ID := v_CONG_CR_MISC_ID;
		v_FORMULA_CHARGE.CHARGE_RATE := 1;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CONG.Credit_From_Uts + v_CONG.Credit_For_Monthly_Excess;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := v_FORMULA_CHARGE.CHARGE_QUANTITY;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        --Congestion Credit FTR Charge
        v_ALLOC_FACTOR_TX_ID := GET_TX_ID('FTR Alloc Factor: ' || v_PSE_NAME,
        								'FTR Alloc Factor',
                                        'FTR Alloc Factor',
                                        'Hour',
                                        0,
                                        v_CONTRACT_ID,
                                        0,
                                        0,
                                        0,
                                        v_PSE_ID);

        IF v_CONG.Ftr_Target_Allocation <> 0 THEN
            v_ALLOC_FACTOR := v_CONG.Ftr_Cong_Credit / v_CONG.Ftr_Target_Allocation;
        ELSE
            v_ALLOC_FACTOR := 0;
        END IF;
        PUT_SCHEDULE_VALUE(v_ALLOC_FACTOR_TX_ID, v_CHARGE_DATE, v_ALLOC_FACTOR, NULL, TRUE);

        v_FTR_CONG_CRED_TOTAL := v_FTR_CONG_CRED_TOTAL + v_CONG.Ftr_Cong_Credit;
        v_FTR_TARGET_ALLOC_TOTAL := v_FTR_TARGET_ALLOC_TOTAL + v_CONG.Ftr_Target_Allocation;

	END LOOP;

    -- flush last month's charges to combination charge table
	UPDATE_COMBINATION_CHARGES;

    v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
    v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);
    v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

    DELETE FROM PJM_CONGESTION_SUMMARY;
    COMMIT;
END IMPORT_CONGESTION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CHARGES
	(
	p_STATUS OUT NUMBER
	) AS
v_DA_LOSS_CH_ID NUMBER(9);
v_DA_LOSS_CH_ID_IMP NUMBER(9);
v_RT_LOSS_CH_ID NUMBER(9);
v_RT_LOSS_CH_ID_IMP NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_DA_LOSS_COMP NUMBER(9);
v_BAL_LOSS_COMP NUMBER(9);
v_PSE_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_PSE_NAME VARCHAR2(32);
v_BILLING_STATEMENT_1 BILLING_STATEMENT%ROWTYPE;
v_BILLING_STATEMENT_2 BILLING_STATEMENT%ROWTYPE;

CURSOR p_LOSS IS
    SELECT * FROM PJM_TXN_LOSS_CHARGE_SUMMARY C
    ORDER BY C.DAY, C.HOUR;

	PROCEDURE UPDATE_COMBINATION_CHARGES IS
    --v_COMPONENT NUMBER(9);
	BEGIN
		--Roll everything all the values up the combination tree.
		IF NOT v_DA_LOSS_CH_ID IS NULL THEN
			UPDATE_COMBINATION_CHARGE(v_DA_LOSS_CH_ID,v_DA_LOSS_CH_ID_IMP,'FORMULA',1, v_LAST_DATE, GET_COMPONENT('PJM:DATransLossChg:Imp'));
		END IF;
		IF NOT v_RT_LOSS_CH_ID IS NULL THEN
			UPDATE_COMBINATION_CHARGE(v_RT_LOSS_CH_ID,v_RT_LOSS_CH_ID_IMP,'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:BalTransLossChg:Imp'));
		END IF;
	END;
BEGIN
    p_STATUS := GA.SUCCESS;

    v_DA_LOSS_COMP := GET_COMPONENT('PJM-1220');
    v_BAL_LOSS_COMP := GET_COMPONENT('PJM-1225');
    v_BILLING_STATEMENT_1.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_1.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT_1.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_1.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_1.Charge_View_Type := 'COMBINATION';
    v_BILLING_STATEMENT_1.Component_Id := v_DA_LOSS_COMP;
    v_BILLING_STATEMENT_1.Product_Id := GET_PRODUCT(v_DA_LOSS_COMP);
    v_BILLING_STATEMENT_2.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_2.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT_2.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_2.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_2.Charge_View_Type := 'COMBINATION';
    v_BILLING_STATEMENT_2.Component_Id := v_BAL_LOSS_COMP;
    v_BILLING_STATEMENT_2.Product_Id := GET_PRODUCT(v_BAL_LOSS_COMP);

    FOR v_LOSS IN p_LOSS LOOP
        IF v_LAST_ORG_ID <> v_LOSS.Org_Nid OR v_LAST_DATE <> TRUNC(v_LOSS.Day,'DD') THEN
		    -- flush last month's charges to combination charge table
			UPDATE_COMBINATION_CHARGES;

            IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);
                v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

                v_BILLING_STATEMENT_1.Charge_Quantity :=0;
                v_BILLING_STATEMENT_1.Charge_Amount := 0;
                v_BILLING_STATEMENT_1.Bill_Quantity := 0;
                v_BILLING_STATEMENT_1.Bill_Amount := 0;
                v_BILLING_STATEMENT_2.Charge_Quantity := 0;
                v_BILLING_STATEMENT_2.Charge_Amount := 0;
                v_BILLING_STATEMENT_2.Bill_Quantity := 0;
                v_BILLING_STATEMENT_2.Bill_Amount := 0;
            END IF;
		   	-- get charge IDs for this month and this PSE.  Build the combo tree if it does not exist.
            v_LAST_ORG_ID := v_LOSS.Org_Nid;
			v_LAST_DATE := TRUNC(v_LOSS.Day,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_BILLING_STATEMENT_1.Entity_Id := v_PSE_ID;
            v_BILLING_STATEMENT_2.Entity_Id := v_PSE_ID;
            SELECT PSE_ALIAS INTO v_PSE_NAME FROM PURCHASING_SELLING_ENTITY
    		WHERE PSE_ID = v_PSE_ID;
			v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

			v_DA_LOSS_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_DA_LOSS_COMP,v_LAST_DATE,'COMBINATION');
			v_COMPONENT_ID := GET_COMPONENT('PJM:DATransLossChg:Imp');
			v_DA_LOSS_CH_ID_IMP := GET_COMBO_CHARGE_ID(v_DA_LOSS_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);

			v_RT_LOSS_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_BAL_LOSS_COMP,v_LAST_DATE,'COMBINATION');
			v_COMPONENT_ID := GET_COMPONENT('PJM:BalTransLossChg:Imp');
			v_RT_LOSS_CH_ID_IMP := GET_COMBO_CHARGE_ID(v_RT_LOSS_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID
            IN(v_DA_LOSS_COMP, v_BAL_LOSS_COMP)
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;
		END IF;

		-- put the Implicit Transmission Congestion Charges.
		v_CHARGE_DATE := GET_CHARGE_DATE(v_LOSS.Day, v_LOSS.Hour, v_LOSS.Dst);

        v_BILLING_STATEMENT_1.Charge_Id := v_DA_LOSS_CH_ID;
        v_BILLING_STATEMENT_1.Charge_Quantity := NVL(v_BILLING_STATEMENT_1.Charge_Quantity,0) + NVL(v_LOSS.Day_Ahead_Imp_Loss_Charge,0) +
                                                    NVL(v_LOSS.Day_Ahead_Exp_Loss_Charge,0);
        v_BILLING_STATEMENT_1.Charge_Amount := NVL(v_BILLING_STATEMENT_1.Charge_Amount,0) + NVL(v_LOSS.Day_Ahead_Imp_Loss_Charge,0) +
                                                    NVL(v_LOSS.Day_Ahead_Exp_Loss_Charge,0);
        v_BILLING_STATEMENT_1.Charge_Rate := 1;
        v_BILLING_STATEMENT_1.Bill_Quantity := NVL(v_BILLING_STATEMENT_1.Bill_Quantity,0) + NVL(v_LOSS.Day_Ahead_Imp_Loss_Charge,0) +
                                                NVL(v_LOSS.Day_Ahead_Exp_Loss_Charge,0);
        v_BILLING_STATEMENT_1.Bill_Amount := NVL(v_BILLING_STATEMENT_1.Bill_Amount,0) + NVL(v_LOSS.Day_Ahead_Imp_Loss_Charge,0) +
                                                NVL(v_LOSS.Day_Ahead_Exp_Loss_Charge,0);

        v_BILLING_STATEMENT_2.Charge_Id := v_RT_LOSS_CH_ID;
        v_BILLING_STATEMENT_2.Charge_Quantity := NVL(v_BILLING_STATEMENT_2.Charge_Quantity,0) + NVL(v_LOSS.Balancing_Imp_Loss_Charge,0) +
                                                    NVL(v_LOSS.Balancing_Exp_Loss_Charge,0);
        v_BILLING_STATEMENT_2.Charge_Amount := NVL(v_BILLING_STATEMENT_2.Charge_Amount,0) + NVL(v_LOSS.Balancing_Imp_Loss_Charge,0) +
                                                    NVL(v_LOSS.Balancing_Exp_Loss_Charge,0);
        v_BILLING_STATEMENT_2.Charge_Rate := 1;
        v_BILLING_STATEMENT_2.Bill_Quantity := NVL(v_BILLING_STATEMENT_2.Bill_Quantity,0) + NVL(v_LOSS.Balancing_Imp_Loss_Charge,0) +
                                                NVL(v_LOSS.Balancing_Exp_Loss_Charge,0);
        v_BILLING_STATEMENT_2.Bill_Amount := NVL(v_BILLING_STATEMENT_2.Bill_Amount,0) + NVL(v_LOSS.Balancing_Imp_Loss_Charge,0) +
                                                NVL(v_LOSS.Balancing_Exp_Loss_Charge,0);

		--===========DAY-AHEAD=======================

		--Put CHARGE_QUANTITY, RATE, AND AMOUNT for the DA Implicit Component.
        PUT_LMP_FORMULA_CHARGE(v_DA_LOSS_CH_ID_IMP, v_CHARGE_DATE,
					v_LOSS.Day_Ahead_Loss_Wd_Mwh-v_LOSS.Day_Ahead_Loss_Inj_Mwh,
					CASE
						WHEN v_LOSS.Day_Ahead_Loss_Wd_Mwh-v_LOSS.Day_Ahead_Loss_Inj_Mwh = 0 THEN
							NULL
						ELSE
							v_LOSS.Day_Ahead_Imp_Loss_Charge /
								(v_LOSS.Day_Ahead_Loss_Wd_Mwh-v_LOSS.Day_Ahead_Loss_Inj_Mwh)
					END,
					v_LOSS.Day_Ahead_Imp_Loss_Charge, 1);
--?
 		--Put DALoad and DAGen
 		PUT_LMP_FORMULA_CHARGE_VAR_DA(v_DA_LOSS_CH_ID_IMP, v_CHARGE_DATE,
					NULL, NULL, --ITERATORs not used because PJM does not provide that level of detail.
 					v_LOSS.Day_Ahead_Loss_Wd_Mwh, -1 * v_LOSS.Day_Ahead_Loss_Inj_Mwh,
 					NULL, NULL, NULL, NULL);

		--===========REAL-TIME========================
		--Put CHARGE_QUANTITY, RATE, AND AMOUNT.
        PUT_LMP_FORMULA_CHARGE(v_RT_LOSS_CH_ID_IMP, v_CHARGE_DATE,
					v_LOSS.Balancing_Loss_Wd_Dev_Mwh-v_LOSS.Balancing_Loss_Inj_Dev_Mwh,
					CASE
						WHEN v_LOSS.Balancing_Loss_Wd_Dev_Mwh-v_LOSS.Balancing_Loss_Inj_Dev_Mwh = 0 THEN
							NULL
						ELSE
							v_LOSS.Balancing_Imp_Loss_Charge /
								(v_LOSS.Balancing_Loss_Wd_Dev_Mwh-v_LOSS.Balancing_Loss_Inj_Dev_Mwh)
					END,
					v_LOSS.Balancing_Imp_Loss_Charge, 1);
--?
		--Put DALoad, DAGen, RTLoad, and RTGen.
		PUT_LMP_FORMULA_CHARGE_VAR(v_RT_LOSS_CH_ID_IMP, v_CHARGE_DATE,
					NULL, NULL, --ITERATORs not used because PJM does not provide that level of detail.
					v_LOSS.Day_Ahead_Loss_Wd_Mwh, -1 * v_LOSS.Day_Ahead_Loss_Inj_Mwh,
					NULL, NULL, NULL, NULL,
					v_LOSS.Day_Ahead_Loss_Wd_Mwh+v_LOSS.Balancing_Loss_Wd_Dev_Mwh,
					-1 * (v_LOSS.Day_Ahead_Loss_Inj_Mwh+v_LOSS.Balancing_Loss_Inj_Dev_Mwh),
					NULL, NULL
					);
	END LOOP;

    -- flush last month's charges to combination charge table
	UPDATE_COMBINATION_CHARGES;

    v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);
    v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;
    DELETE FROM PJM_TXN_LOSS_CHARGE_SUMMARY;
    COMMIT;
END IMPORT_TRANS_LOSS_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE9_10_SUMMARY
	(
	p_RECORDS IN MEX_PJM_SCHED9_10_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
v_MARKET_PRICE_ID NUMBER(9);
v_SSCD_CH_ID NUMBER(9);
v_MAAC_CH_ID NUMBER(9);
v_SSCD_CH_ID_CROM NUMBER(9);
v_SSCD_CH_ID_CASC NUMBER(9);
v_SSCD_CH_ID_FERC NUMBER(9);
v_SSCD_CH_ID_FTRA NUMBER(9);
v_SSCD_CH_ID_FTRA_BIDS NUMBER(9);
v_SSCD_CH_ID_FTRA_HELD NUMBER(9);
v_SSCD_CH_ID_MKSP NUMBER(9);
v_SSCD_CH_ID_MKSP_CNT NUMBER(9);
v_SSCD_CH_ID_MKSP_VOL NUMBER(9);
v_SSCD_CH_ID_RFRA NUMBER(9);
v_FTRA_BIDS_QUANTITY NUMBER := 0;
v_FTRA_BIDS_AMOUNT NUMBER := 0;
v_FTRA_HELD_AMT NUMBER := 0;
v_FTRA_HELD_QTY NUMBER := 0;
v_FTRA_BIDS_QTY_RATE NUMBER := 0;
v_FTRA_HELD_RATE NUMBER := 0;
v_MKT_SUPP_RATE NUMBER := 0;
v_BID_OFFER_RATE NUMBER := 0;
v_MKSP_CNT_QUANTITY NUMBER := 0;
v_MKSP_CNT_AMOUNT NUMBER := 0;
v_MKSP_VOL_QUANTITY NUMBER := 0;
v_MKSP_VOL_AMOUNT NUMBER := 0;
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_IS_VAR BOOLEAN;
v_UNKNOWN BOOLEAN;
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
	v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).MONTH) + 1/86400;
	v_PSE_ID := GET_PSE(NULL, p_RECORDS(v_IDX).ORG_NAME);

	v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
	v_FORMULA_CHARGE.CHARGE_FACTOR := 1.0;
	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
	v_FORMULA_CHARGE.ITERATOR_ID := 0;
	v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;


	-- get charge IDs

   v_COMPONENT_ID := GET_COMPONENT('Mid-Atlantic Area Council (MAAC)');
   v_MAAC_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');

    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg');
    v_SSCD_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'COMBINATION');

    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:CapResObMg');
    v_SSCD_CH_ID_CROM := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:CASvc');
    v_SSCD_CH_ID_CASC := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:FERCAnnChgRec');
    v_SSCD_CH_ID_FERC := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:RegFrqResp');
    v_SSCD_CH_ID_RFRA := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');

    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:FTRAdmin');
    v_SSCD_CH_ID_FTRA := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'COMBINATION');
    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:FTRAdmin:Bids');
    v_SSCD_CH_ID_FTRA_BIDS := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID_FTRA,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:FTRAdmin:Held');
    v_SSCD_CH_ID_FTRA_HELD := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID_FTRA,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');

    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:MktSupp');
    v_SSCD_CH_ID_MKSP := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'COMBINATION');
    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:MktSupp:Count');
    v_SSCD_CH_ID_MKSP_CNT := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID_MKSP,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_COMPONENT_ID := GET_COMPONENT('PJM:SSC&DChg:MktSupp:Vol');
    v_SSCD_CH_ID_MKSP_VOL := GET_COMBO_CHARGE_ID(v_SSCD_CH_ID_MKSP,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		v_IS_VAR := FALSE;
		v_UNKNOWN := FALSE;

		CASE TRIM(SUBSTR(p_RECORDS(v_IDX).SCHEDULE,1,4))
		WHEN UPPER('9-1:') THEN
			-- get market price ID
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:ControlAreaAdminRate');
			-- formula charges
			v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_CASC;

		WHEN UPPER('9-2:') THEN
			-- get market price ID
			IF UPPER(p_RECORDS(v_IDX).DETERMINANT) LIKE '%(MWH)' THEN
				v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:FTRAdminRate');
			ELSE
				v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:FTRAdminBidsRate');
			END IF;
			-- formula charges
			IF UPPER(p_RECORDS(v_IDX).DETERMINANT) LIKE '%(MWH)' THEN
				v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_FTRA_HELD;
                v_FTRA_HELD_QTY := p_RECORDS(v_IDX).QUANTITY;
                v_FTRA_HELD_RATE := p_RECORDS(v_IDX).RATE;
                v_FTRA_HELD_AMT := p_RECORDS(v_IDX).CHARGE;
			ELSE
				v_IS_VAR := TRUE;
        		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SSCD_CH_ID_FTRA_BIDS;
				CASE UPPER(TRIM(p_RECORDS(v_IDX).DETERMINANT))
				WHEN 'FTR BID OPTIONS X5' THEN
					v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'FTRBidOptionsX5';
					v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY;
                    v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).RATE;
					PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

					v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'FTRBidOptions';
					v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY/5;
					PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

					v_FTRA_BIDS_QUANTITY := v_FTRA_BIDS_QUANTITY+p_RECORDS(v_IDX).QUANTITY;
					v_FTRA_BIDS_AMOUNT := v_FTRA_BIDS_AMOUNT+p_RECORDS(v_IDX).CHARGE;
                    v_FTRA_BIDS_QTY_RATE := p_RECORDS(v_IDX).RATE;

				WHEN 'FTR BID OBLIGATIONS' THEN
					v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'FTRBidObligations';
					v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY;
                    v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).RATE;
					PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

					v_FTRA_BIDS_QUANTITY := v_FTRA_BIDS_QUANTITY+p_RECORDS(v_IDX).QUANTITY;
					v_FTRA_BIDS_AMOUNT := v_FTRA_BIDS_AMOUNT+p_RECORDS(v_IDX).CHARGE;
				ELSE
					NULL; --??
				END CASE;
			END IF;

		WHEN UPPER('9-3:') THEN
			-- get market price ID
			IF UPPER(p_RECORDS(v_IDX).DETERMINANT) LIKE '%(MWH)' THEN
				v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:MarketSupportRate');
			ELSE
				v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:BidOfferSegmentRate');
			END IF;
			-- formula charges
			v_IS_VAR := TRUE;
            CASE UPPER(TRIM(p_RECORDS(v_IDX).DETERMINANT))
            WHEN 'GENERATION OFFER SEGMENTS' THEN
				v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SSCD_CH_ID_MKSP_CNT;
            	v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'GenOfferSegments';
            	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY;
                v_BID_OFFER_RATE := p_RECORDS(v_IDX).RATE;
            	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            	v_MKSP_CNT_QUANTITY := v_MKSP_CNT_QUANTITY+p_RECORDS(v_IDX).QUANTITY;
            	v_MKSP_CNT_AMOUNT := v_MKSP_CNT_AMOUNT+p_RECORDS(v_IDX).CHARGE;
            WHEN 'DEMAND + TRANSACTION BID/OFFER SEGMENTS' THEN
				v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SSCD_CH_ID_MKSP_CNT;
            	v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'DemandAndTransBidOfferSegments';
            	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY;
            	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            	v_MKSP_CNT_QUANTITY := v_MKSP_CNT_QUANTITY+p_RECORDS(v_IDX).QUANTITY;
            	v_MKSP_CNT_AMOUNT := v_MKSP_CNT_AMOUNT+p_RECORDS(v_IDX).CHARGE;
            WHEN 'GENERATION PROVIDED (MWH)' THEN
				v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SSCD_CH_ID_MKSP_VOL;
            	v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'GenerationProvided';
            	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY;
                v_MKT_SUPP_RATE := p_RECORDS(v_IDX).RATE;
            	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            	v_MKSP_VOL_QUANTITY := v_MKSP_VOL_QUANTITY+p_RECORDS(v_IDX).QUANTITY;
            	v_MKSP_VOL_AMOUNT := v_MKSP_VOL_AMOUNT+p_RECORDS(v_IDX).CHARGE;
            WHEN 'LOAD + EXPORTS (MWH)' THEN
				v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SSCD_CH_ID_MKSP_VOL;
            	v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'NetworkLoadPlusExports';
            	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY;
            	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            	v_MKSP_VOL_QUANTITY := v_MKSP_VOL_QUANTITY+p_RECORDS(v_IDX).QUANTITY;
            	v_MKSP_VOL_AMOUNT := v_MKSP_VOL_AMOUNT+p_RECORDS(v_IDX).CHARGE;
            WHEN 'INCS + DECS + UPTOCONGESTION (MWH)' THEN
				v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SSCD_CH_ID_MKSP_VOL;
            	v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'IncsDecs';
            	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).QUANTITY;
            	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            	v_MKSP_VOL_QUANTITY := v_MKSP_VOL_QUANTITY+p_RECORDS(v_IDX).QUANTITY;
            	v_MKSP_VOL_AMOUNT := v_MKSP_VOL_AMOUNT+p_RECORDS(v_IDX).CHARGE;
            ELSE
            	NULL; --??
            END CASE;

		WHEN UPPER('9-4:') THEN
			-- get market price ID
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:RegulationFreqRespRate');
			-- formula charges
			v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_RFRA;

		WHEN UPPER('9-5:') THEN
			-- get market price ID
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:CapResOblMgmtRate');
			-- formula charges
			v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_CROM;

		WHEN UPPER('9-FE') THEN
			-- get market price ID
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:FERCAnnualRecoveryRate');
			-- formula charges
			v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_FERC;

		WHEN UPPER('10:') THEN
			-- get market price ID
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:MAACRate');
			-- formula charges
            IF v_MAAC_CH_ID IS NOT NULL THEN
				v_FORMULA_CHARGE.CHARGE_ID := v_MAAC_CH_ID;
            ELSE
            	v_IS_VAR := TRUE;
            END IF;

		ELSE
			v_UNKNOWN := TRUE;
		END CASE;
		IF v_UNKNOWN = FALSE THEN
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).RATE);
		IF NOT v_IS_VAR THEN
			-- not a formula charge variable? then it corresponds to a formula charge
			v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).QUANTITY;
			v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).RATE;
			v_FORMULA_CHARGE.CHARGE_AMOUNT := p_RECORDS(v_IDX).CHARGE;
		    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
		END IF;
       END IF;

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;
    -- flush charges to formula charge table where applicable
	v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_FTRA_BIDS;
	v_FORMULA_CHARGE.CHARGE_QUANTITY := v_FTRA_BIDS_QUANTITY;
	v_FORMULA_CHARGE.CHARGE_RATE := v_FTRA_BIDS_QTY_RATE; --NULL;
	v_FORMULA_CHARGE.CHARGE_AMOUNT := v_FTRA_BIDS_AMOUNT;
    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

    v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_FTRA_HELD;
	v_FORMULA_CHARGE.CHARGE_QUANTITY := v_FTRA_HELD_QTY;
	v_FORMULA_CHARGE.CHARGE_RATE := v_FTRA_HELD_RATE; --NULL;
	v_FORMULA_CHARGE.CHARGE_AMOUNT := v_FTRA_HELD_AMT;
    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

	v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_MKSP_CNT;
	v_FORMULA_CHARGE.CHARGE_QUANTITY := v_MKSP_CNT_QUANTITY;
	v_FORMULA_CHARGE.CHARGE_RATE := v_BID_OFFER_RATE; --NULL;
	v_FORMULA_CHARGE.CHARGE_AMOUNT := v_MKSP_CNT_AMOUNT;
    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

	v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_CH_ID_MKSP_VOL;
	v_FORMULA_CHARGE.CHARGE_QUANTITY := v_MKSP_VOL_QUANTITY;
	v_FORMULA_CHARGE.CHARGE_RATE := v_MKT_SUPP_RATE;  --NULL;
	v_FORMULA_CHARGE.CHARGE_AMOUNT := v_MKSP_VOL_AMOUNT;
    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

	-- combine charges
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID_FTRA,v_SSCD_CH_ID_FTRA_BIDS,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID_FTRA,v_SSCD_CH_ID_FTRA_HELD,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID_MKSP,v_SSCD_CH_ID_MKSP_CNT,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID_MKSP,v_SSCD_CH_ID_MKSP_VOL,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID,v_SSCD_CH_ID_CROM,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID,v_SSCD_CH_ID_CASC,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID,v_SSCD_CH_ID_FERC,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID,v_SSCD_CH_ID_FTRA,'COMBINATION');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID,v_SSCD_CH_ID_MKSP,'COMBINATION');
    UPDATE_COMBINATION_CHARGE(v_SSCD_CH_ID,v_SSCD_CH_ID_RFRA,'FORMULA');


  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_SCHEDULE9_10_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_REVNEUT_SUMMARY
	(
	p_RECORDS IN MEX_PJM_TRANS_REVNEUT_CHG_TBL,
	p_STATUS OUT NUMBER
	) AS
v_MARKET_PRICE_ID NUMBER(9);
v_NITS_OFFSET_CH_ID NUMBER(9);
v_RTO_COST_CH_ID NUMBER(9);
v_CHARGE_RATE NUMBER;
v_CHARGE_QTY NUMBER;
v_CHARGE_AMOUNT NUMBER;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_PSE_ALIAS VARCHAR2(32);
v_ZONE VARCHAR2(32);
v_ZONE_ID NUMBER(9);
v_ITERATOR_ID NUMBER(3);
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_RATE_TYPE VARCHAR2(10);
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
	v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).MONTH);
	v_PSE_ID := GET_PSE(NULL, p_RECORDS(v_IDX).ORG_NAME);
    IF NOT v_PSE_ID IS NULL THEN
        SELECT PSE_ALIAS INTO v_PSE_ALIAS
        FROM PSE WHERE PSE_ID = v_PSE_ID;
    END IF;
    ID.ID_FOR_COMMODITY('Transmission', FALSE, v_COMMODITY_ID);

    v_COMPONENT_ID := GET_COMPONENT('PJM-1104');
    v_NITS_OFFSET_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_COMPONENT_ID := GET_COMPONENT('PJM-1720');
    v_RTO_COST_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');

    v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
	v_FORMULA_CHARGE.CHARGE_FACTOR := 1.0;
	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
    v_ITERATOR.Iterator_Id := 0;

    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		CASE p_RECORDS(v_IDX).SERVICE
		WHEN 'AP Network Load - Wholesale' THEN
			IF p_RECORDS(v_IDX).QUANTITY <> 0 THEN
                v_FORMULA_CHARGE.Charge_Id := v_NITS_OFFSET_CH_ID;
                v_FORMULA_CHARGE_VAR.Charge_Id := v_NITS_OFFSET_CH_ID;
                v_CHARGE_RATE := p_RECORDS(v_IDX).RATE;
                v_CHARGE_QTY := p_RECORDS(v_IDX).QUANTITY;
                v_CHARGE_AMOUNT := p_RECORDS(v_IDX).CHARGE;
                v_RATE_TYPE := 'Wholesale';
            END IF;
		WHEN 'AP Network Load - Retail' THEN
			-- get market price ID
			IF p_RECORDS(v_IDX).QUANTITY <> 0 THEN
                v_FORMULA_CHARGE.Charge_Id := v_NITS_OFFSET_CH_ID;
                v_FORMULA_CHARGE_VAR.Charge_Id := v_NITS_OFFSET_CH_ID;
                v_CHARGE_RATE := p_RECORDS(v_IDX).RATE;
                v_CHARGE_QTY := p_RECORDS(v_IDX).QUANTITY;
                v_CHARGE_AMOUNT := p_RECORDS(v_IDX).CHARGE;
                v_RATE_TYPE := 'Retail';
			END IF;
        WHEN 'RTO Start-up Cost Recovery - AEP' THEN
            IF p_RECORDS(v_IDX).QUANTITY <> 0 THEN
                v_FORMULA_CHARGE.Charge_Id := v_RTO_COST_CH_ID;
                v_FORMULA_CHARGE_VAR.Charge_Id := v_RTO_COST_CH_ID;
                v_CHARGE_RATE := p_RECORDS(v_IDX).RATE;
                v_CHARGE_QTY := p_RECORDS(v_IDX).QUANTITY;
                v_CHARGE_AMOUNT := p_RECORDS(v_IDX).CHARGE;
            END IF;

		ELSE
			NULL;
		END CASE;
		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

    CASE v_FORMULA_CHARGE.Charge_Id
    WHEN v_NITS_OFFSET_CH_ID THEN
        v_ZONE := 'APS';
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);
        v_ITERATOR_NAME.CHARGE_ID := v_NITS_OFFSET_CH_ID;
    	v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
    	v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
    	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
    	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
    	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
    	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	v_ITERATOR.CHARGE_ID := v_NITS_OFFSET_CH_ID;
        v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
        v_ITERATOR_ID := v_ITERATOR.Iterator_Id;
        v_ITERATOR.ITERATOR1 := v_ZONE;
    	v_ITERATOR.ITERATOR2 := NULL;
    	v_ITERATOR.ITERATOR3 := NULL;
    	v_ITERATOR.ITERATOR4 := NULL;
    	v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE_VAR.Variable_Name := 'NetworkLoadRate';
        v_FORMULA_CHARGE_VAR.Variable_Val := v_CHARGE_RATE;
        v_FORMULA_CHARGE_VAR.Iterator_Id := v_ITERATOR_ID;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'ZoneUsage';
        v_FORMULA_CHARGE_VAR.Variable_Val := v_CHARGE_QTY;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

    	v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_QTY;
    	v_FORMULA_CHARGE.CHARGE_RATE := v_CHARGE_RATE;
    	v_FORMULA_CHARGE.CHARGE_AMOUNT := v_CHARGE_AMOUNT;
        v_FORMULA_CHARGE.Iterator_Id := v_ITERATOR_ID;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        --create market price
        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE || ':NetworkLdRate:' || v_RATE_TYPE);
    	IF v_MARKET_PRICE_ID IS NULL THEN
            IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
              							p_MARKET_PRICE_NAME => 'PJM AP Network Load Rate:' || v_RATE_TYPE ,
    									p_MARKET_PRICE_ALIAS =>'PJM AP Network Load Rate',
                                		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
    									p_MARKET_PRICE_ID => 0,
                                		p_MARKET_PRICE_TYPE => 'Network Load Rate',
    									p_MARKET_PRICE_INTERVAL => 'Month',
                                		p_MARKET_TYPE => '?',
    									p_COMMODITY_ID => v_COMMODITY_ID,
    									p_SERVICE_POINT_TYPE => '?',
                                		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':NetworkLdRate' || v_RATE_TYPE,
    									p_EDC_ID => 0,
    									p_SC_ID => g_PJM_SC_ID,
                                		p_POD_ID => 0,
    									p_ZOD_ID => v_ZONE_ID);
        END IF;

    	PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE, v_CHARGE_RATE);
    WHEN v_RTO_COST_CH_ID THEN
        v_ZONE := 'AEP';
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);
        v_ITERATOR_NAME.CHARGE_ID := v_RTO_COST_CH_ID;
    	v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
    	v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
    	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
    	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
    	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
    	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	v_ITERATOR.CHARGE_ID := v_RTO_COST_CH_ID;
        v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
        v_ITERATOR_ID := v_ITERATOR.Iterator_Id;
        v_ITERATOR.ITERATOR1 := v_ZONE;
    	v_ITERATOR.ITERATOR2 := NULL;
    	v_ITERATOR.ITERATOR3 := NULL;
    	v_ITERATOR.ITERATOR4 := NULL;
    	v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE_VAR.Variable_Name := 'RTOStartUpCostRecoverRate';
        v_FORMULA_CHARGE_VAR.Variable_Val := v_CHARGE_RATE;
        v_FORMULA_CHARGE_VAR.Iterator_Id := v_ITERATOR_ID;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'ZoneUsage';
        v_FORMULA_CHARGE_VAR.Variable_Val := v_CHARGE_QTY;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

    	v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_QTY;
    	v_FORMULA_CHARGE.CHARGE_RATE := v_CHARGE_RATE;
    	v_FORMULA_CHARGE.CHARGE_AMOUNT := v_CHARGE_AMOUNT;
        v_FORMULA_CHARGE.Iterator_Id := v_ITERATOR_ID;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        --create market price
        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE|| ':StartUpCostRecoverRate:');
    	IF v_MARKET_PRICE_ID IS NULL THEN

            IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
              							p_MARKET_PRICE_NAME => 'PJM AEP StartUp Cost Recovery Rate' ,
    									p_MARKET_PRICE_ALIAS =>'PJM AEP StartUp Cost Recovery Rate',
                                		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
    									p_MARKET_PRICE_ID => 0,
                                		p_MARKET_PRICE_TYPE => 'StartUp Cost Recovery',
    									p_MARKET_PRICE_INTERVAL => 'Month',
                                		p_MARKET_TYPE => '?',
    									p_COMMODITY_ID => 0,
    									p_SERVICE_POINT_TYPE => '?',
                                		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':StartUpCostRecoverRate:',
    									p_EDC_ID => 0,
    									p_SC_ID => g_PJM_SC_ID,
                                		p_POD_ID => 0,
    									p_ZOD_ID => v_ZONE_ID);
        END IF;

    	PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE, v_CHARGE_RATE);
    ELSE
        NULL;
    END CASE;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        COMMIT;
    END IF;
END IMPORT_TRANS_REVNEUT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NITS_SUMMARY(p_RECORDS IN MEX_PJM_NITS_SUMMARY_TBL,
                              p_STATUS  OUT NUMBER) AS
TYPE MKT_PRICE_ID_MAP IS TABLE OF NUMBER(9) INDEX BY VARCHAR2(32);
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_NITS_RATE_ID_MAP   MKT_PRICE_ID_MAP;
v_NITS_REV_ID_MAP    MKT_PRICE_ID_MAP;
v_ITERATOR_ID_MAP		 ITERATOR_ID_MAP;
v_MARKET_PRICE_ID    NUMBER(9);
v_NITS_CH_ID         NUMBER(9);
v_NITS_CR_ID         NUMBER(9);
v_ZONE VARCHAR2(32);
v_ZONE_ID			 NUMBER(9);
v_ITERATOR_ID	 NUMBER(3) := 0;
v_CHARGE_AMOUNT      NUMBER;
v_CREDIT_AMOUNT      NUMBER;
v_NITS_CH_COMP NUMBER(9);
v_NITS_CR_COMP       NUMBER(9);
v_PSE_ID             NUMBER(9);
v_COMMODITY_ID	IT_COMMODITY.COMMODITY_ID%TYPE;
v_IDX                BINARY_INTEGER;
v_LAST_ORG_ID        VARCHAR2(16) := '?';
v_LAST_DATE          DATE := LOW_DATE;
v_CHARGE_DATE        DATE := LOW_DATE;
v_FORMULA_CHARGE     FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
    v_ITERATOR.ITERATOR_ID := 0;
	ID.ID_FOR_COMMODITY('Transmission',FALSE, v_COMMODITY_ID);
    v_NITS_CH_COMP := GET_COMPONENT('PJM-1100');
    v_NITS_CR_COMP := GET_COMPONENT('PJM-2100');

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
			-- flush charge to formula charge
			IF NOT v_NITS_CH_ID IS NULL THEN
                v_FORMULA_CHARGE.CHARGE_ID       := v_NITS_CH_ID;
				v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
				v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
				v_FORMULA_CHARGE.CHARGE_RATE     := 1;
				v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
				PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
 			END IF;
			IF NOT v_NITS_CR_ID IS NULL THEN
				v_FORMULA_CHARGE.CHARGE_ID       := v_NITS_CR_ID;
				v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
				v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CREDIT_AMOUNT;
				v_FORMULA_CHARGE.CHARGE_RATE     := -1;
				v_FORMULA_CHARGE.CHARGE_AMOUNT   := -v_CREDIT_AMOUNT;
				PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
 			END IF;
			v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).DAY) + 1 / 86400;
			v_CHARGE_AMOUNT := 0;
			v_CREDIT_AMOUNT := 0;
		--END IF;
		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY, 'MM') THEN
			-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'MM');
			v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, p_RECORDS(v_IDX).ORG_NAME);
			v_NITS_CH_ID   := GET_CHARGE_ID(v_PSE_ID, v_NITS_CH_COMP, v_LAST_DATE,
																			'FORMULA');
			v_NITS_CR_ID   := GET_CHARGE_ID(v_PSE_ID, v_NITS_CR_COMP, v_LAST_DATE,
																			'FORMULA');

		END IF;

		v_ZONE := REPLACE(p_RECORDS(v_IDX).ZONE, ' ', '');

        --get zone id
		v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		-- first update the market prices - get IDs from cache
		IF v_NITS_REV_ID_MAP.EXISTS(v_ZONE) THEN
			v_MARKET_PRICE_ID := v_NITS_REV_ID_MAP(v_ZONE);
		ELSE
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE || ':NITSTotal');
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM NITS Total Rev - ' || v_ZONE,
									p_MARKET_PRICE_ALIAS =>'PJM NITS Total Rev - ' || v_ZONE,
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
									p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'PJM Total NITS Revenue',
									p_MARKET_PRICE_INTERVAL => 'Day',
                            		p_MARKET_TYPE => '?',
									p_COMMODITY_ID => v_COMMODITY_ID,
									p_SERVICE_POINT_TYPE => '?',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':NITSTotal',
									p_EDC_ID => 0,
									p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => 0,
									p_ZOD_ID => v_ZONE_ID);
			END IF;
			v_NITS_REV_ID_MAP(v_ZONE) := v_MARKET_PRICE_ID;
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE),
													 p_RECORDS(v_IDX).TOTAL_REVENUES);

		IF v_NITS_RATE_ID_MAP.EXISTS(v_ZONE) THEN
			v_MARKET_PRICE_ID := v_NITS_RATE_ID_MAP(v_ZONE);
		ELSE
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE || ':NITSRate');
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM NITS Charge Rate - ' || v_ZONE,
									p_MARKET_PRICE_ALIAS =>'PJM NITS Charge Rate - ' || v_ZONE,
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
									p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'PJM NITS Charge',
									p_MARKET_PRICE_INTERVAL => 'Day',
                            		p_MARKET_TYPE => '?',
									p_COMMODITY_ID => v_COMMODITY_ID,
									p_SERVICE_POINT_TYPE => '?',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':NITSRate',
									p_EDC_ID => 0,
									p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => 0,
									p_ZOD_ID => v_ZONE_ID);
			END IF;
			v_NITS_RATE_ID_MAP(v_ZONE) := v_MARKET_PRICE_ID;
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE),
													 p_RECORDS(v_IDX).NETWORK_RATE);

		-- next, update formula variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_NITS_CH_ID;

        v_ITERATOR_NAME.CHARGE_ID := v_NITS_CH_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_NITS_CH_ID;
       	IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
            v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

		v_ITERATOR.ITERATOR1 := v_ZONE;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'NITSRate';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).NETWORK_RATE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZoneDemand';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).PEAK_LOAD;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_CHARGE_AMOUNT := v_CHARGE_AMOUNT + p_RECORDS(v_IDX).CHARGE;

		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_NITS_CR_ID;
        v_ITERATOR.CHARGE_ID := v_NITS_CR_ID;
		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TransRevReqShare';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).REVENUE_REQ_SHARE;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'NITSTotalRevenues';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_REVENUES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_CREDIT_AMOUNT := v_CREDIT_AMOUNT + p_RECORDS(v_IDX).CREDIT;

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;
	-- flush charge to formula charge
	IF NOT v_NITS_CH_ID IS NULL THEN
		v_FORMULA_CHARGE.CHARGE_ID       := v_NITS_CH_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE     := 1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END IF;
	IF NOT v_NITS_CR_ID IS NULL THEN
		v_FORMULA_CHARGE.CHARGE_ID       := v_NITS_CR_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CREDIT_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE     := -1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := -v_CREDIT_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END IF;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_NITS_SUMMARY;
-------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPANSION_COST_SUMMARY
    (
    p_RECORDS IN MEX_PJM_NITS_SUMMARY_TBL,
    p_STATUS  OUT NUMBER
    ) AS
TYPE MKT_PRICE_ID_MAP IS TABLE OF NUMBER(9) INDEX BY VARCHAR2(32);
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ID_MAP   MKT_PRICE_ID_MAP;
v_ITERATOR_ID_MAP		 ITERATOR_ID_MAP;
v_MARKET_PRICE_ID    NUMBER(9);
v_EXP_COST_CH_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_ZONE_ID			 NUMBER(9);
v_ITERATOR_ID	 NUMBER(3) := 0;
v_CHARGE_AMOUNT NUMBER;
v_CHARGE_RATE NUMBER;
v_CHARGE_QTY NUMBER;
v_COMPONENT_ID       NUMBER(9);
v_PSE_ID             NUMBER(9);
v_IDX                BINARY_INTEGER;
v_LAST_ORG_ID        VARCHAR2(16) := '?';
v_LAST_DATE          DATE := LOW_DATE;
v_CHARGE_DATE        DATE := LOW_DATE;
v_FORMULA_CHARGE     FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
    v_ITERATOR.ITERATOR_ID := 0;
	--ID.ID_FOR_COMMODITY('Transmission',FALSE, v_COMMODITY_ID);

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
			-- flush charge to formula charge
        IF NOT v_EXP_COST_CH_ID IS NULL THEN
            v_FORMULA_CHARGE.CHARGE_ID       := v_EXP_COST_CH_ID;
            v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
            v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_QTY;
            v_FORMULA_CHARGE.CHARGE_RATE     := v_CHARGE_RATE;
            v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
            PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
        END IF;

        v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + 1/86400;

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY, 'MM') THEN
			-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'MM');
			v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

			v_COMPONENT_ID := GET_COMPONENT('PJM-1730');
			v_EXP_COST_CH_ID   := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE,
																			'FORMULA');
			--v_COMPONENT_ID := GET_COMPONENT('PJM:NITSCred');
			--v_NITS_CR_ID   := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE,
			--																'FORMULA');

		END IF;

		v_ZONE := REPLACE(p_RECORDS(v_IDX).ZONE, ' ', '');
        --get zone id
		v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		-- first update the market prices - get IDs from cache
		IF v_ID_MAP.EXISTS(v_ZONE) THEN
			v_MARKET_PRICE_ID := v_ID_MAP(v_ZONE);
		ELSE
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE || ':ExpCostRecovery');
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM Expansion Cost Recovery Rate - ' || v_ZONE,
									p_MARKET_PRICE_ALIAS =>'PJM Expansion Cost Recovery Rate - ' || v_ZONE,
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
									p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'PJM Expansion Cost Recovery',
									p_MARKET_PRICE_INTERVAL => 'Month',
                            		p_MARKET_TYPE => '?',
									p_COMMODITY_ID => 0,
									p_SERVICE_POINT_TYPE => '?',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':ExpCostRecovery',
									p_EDC_ID => 0,
									p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => 0,
									p_ZOD_ID => v_ZONE_ID);
			END IF;
			v_ID_MAP(v_ZONE) := v_MARKET_PRICE_ID;
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE),
													 p_RECORDS(v_IDX).NETWORK_RATE);



		-- next, update formula variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_EXP_COST_CH_ID;

        v_ITERATOR_NAME.CHARGE_ID := v_EXP_COST_CH_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_EXP_COST_CH_ID;
       	IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

		v_ITERATOR.ITERATOR1 := v_ZONE;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Zone_Avg_Peak_Use';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).PEAK_LOAD;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Expansion_Cost_Recovery_Rate';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).NETWORK_RATE;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_CHARGE_QTY := p_RECORDS(v_IDX).PEAK_LOAD;
        v_CHARGE_RATE := p_RECORDS(v_IDX).NETWORK_RATE;
	    v_CHARGE_AMOUNT := p_RECORDS(v_IDX).CHARGE;

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;
	-- flush charge to formula charge
	IF NOT v_EXP_COST_CH_ID IS NULL THEN
		v_FORMULA_CHARGE.CHARGE_ID       := v_EXP_COST_CH_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_QTY;
		v_FORMULA_CHARGE.CHARGE_RATE     := v_CHARGE_RATE;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END IF;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_EXPANSION_COST_SUMMARY;
-------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_SUMMARY
	(
	p_RECORDS IN MEX_PJM_OPER_RES_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
v_OR_DA_MKT_PR_ID NUMBER(9);
v_OR_BAL_MKT_PR_ID NUMBER(9);
v_OR_DA_CH_ID NUMBER(9);
v_OR_BAL_CH_ID NUMBER(9);
v_DA_LOAD_TX_ID NUMBER(9);
v_DEVIATION_TX_ID NUMBER(9);
v_OR_DA_COMP NUMBER(9);
v_OR_BAL_COMP NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;

	ID.ID_FOR_COMMODITY('DayAhead Energy',FALSE, v_COMMODITY_ID);
    v_OR_DA_COMP := GET_COMPONENT('PJM-1370');
    v_OR_BAL_COMP := GET_COMPONENT('PJM-1375');

	--v_DA_LOAD_TX_ID := GET_TRANSACTION('PJM:TotalDALoad+Exports');
	--v_DEVIATION_TX_ID := GET_TRANSACTION('PJM:TotalDeviation');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_OR_DA_COMP);

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).DAY) + 1/86400;
		--IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).ORG_ID OR
		   --v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY,'MM') THEN
        IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).ORG_ID OR
		   v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY,'DD') THEN
		   	-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE := TRUNC(v_CHARGE_DATE,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
			v_OR_DA_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_OR_DA_COMP,v_LAST_DATE,'FORMULA');
			v_OR_BAL_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_OR_BAL_COMP,v_LAST_DATE,'FORMULA');
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID IN(v_OR_DA_COMP, v_OR_BAL_COMP)
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;

		END IF;

        --update market prices
		v_OR_DA_MKT_PR_ID := GET_MARKET_PRICE('PJM:ORTotal-DayAhead');
		IF v_OR_DA_MKT_PR_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_OR_DA_MKT_PR_ID,
      							p_MARKET_PRICE_NAME => 'PJM:OpResTotal-DayAhead',
								p_MARKET_PRICE_ALIAS =>'PJM:OpResTotal-DayAhead',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Day',
                        		p_MARKET_TYPE => MM_PJM_UTIL.g_DAYAHEAD,
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:ORTotal-DayAhead',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		v_OR_BAL_MKT_PR_ID := GET_MARKET_PRICE('PJM:ORTotal-Balancing');
		IF v_OR_BAL_MKT_PR_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_OR_BAL_MKT_PR_ID,
      							p_MARKET_PRICE_NAME => 'PJM:OpResTotal-Balancing',
								p_MARKET_PRICE_ALIAS =>'PJM:OpResTotal-Balancing',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Day',
                        		p_MARKET_TYPE => MM_PJM_UTIL.g_DAYAHEAD,
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:ORTotal-Balancing',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;

		PUT_MARKET_PRICE_VALUE(v_OR_DA_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).Total_DA_Credits);
		PUT_MARKET_PRICE_VALUE(v_OR_BAL_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).Total_Bal_Credits);

        --get transaction ids, update schedule
        v_DA_LOAD_TX_ID := GET_TX_ID('PJM:TotalDALoad+Exports',
                                      'Load',
                                      'PJM:TotalDALoad+Exports',
                                      'Day',
                                      v_COMMODITY_ID);

        PUT_SCHEDULE_VALUE(v_DA_LOAD_TX_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).TOTAL_DA_LOAD_PLUS_EXPORTS);

        v_DEVIATION_TX_ID := GET_TX_ID('PJM:TotalDeviation',
                                      'Load',
                                      'PJM:TotalDeviation',
                                      'Day',
                                      v_COMMODITY_ID);

        PUT_SCHEDULE_VALUE(v_DEVIATION_TX_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).TOTAL_DEVIATION);

		-- next, update formula charges and variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;

		-- day ahead charge first
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_OR_DA_CH_ID;
		v_FORMULA_CHARGE.CHARGE_ID := v_OR_DA_CH_ID;

		-- put variables
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalDACredits';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).Total_DA_Credits;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'DALoadPlusExports';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).DA_Load_Plus_Exports;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TotalDALoadPlusExports';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).Total_DA_Load_Plus_Exports;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		-- put charge
		v_FORMULA_CHARGE.CHARGE_QUANTITY :=
        	CASE WHEN p_RECORDS(v_IDX).Total_DA_Load_Plus_Exports = 0 THEN 0 ELSE p_RECORDS(v_IDX).DA_Load_Plus_Exports/p_RECORDS(v_IDX).Total_DA_Load_Plus_Exports END;
		v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).Total_DA_Credits;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := p_RECORDS(v_IDX).DA_Charge;
	    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.Component_Id := v_OR_DA_COMP;
        v_BILLING_STATEMENT.CHARGE_Id := v_OR_DA_CH_ID;
        v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
        v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
        v_BILLING_STATEMENT.Charge_Quantity := v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT.Charge_Rate := v_FORMULA_CHARGE.CHARGE_RATE;
        v_BILLING_STATEMENT.Charge_Amount := v_FORMULA_CHARGE.CHARGE_AMOUNT;
        v_BILLING_STATEMENT.Bill_Quantity := v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT.Bill_Amount := v_FORMULA_CHARGE.CHARGE_AMOUNT;

        PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);

		-- balancing charges next
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_OR_BAL_CH_ID;
		v_FORMULA_CHARGE.CHARGE_ID := v_OR_BAL_CH_ID;

		-- put variables
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMDeviation';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).Total_Deviation;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'GenerationDeviation';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).Generation_Deviation;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'OtherDeviation';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).Injection_Deviation +
        						p_RECORDS(v_IDX).Withdrawal_Deviation;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		-- put charge
		v_FORMULA_CHARGE.CHARGE_QUANTITY :=
				CASE WHEN p_RECORDS(v_IDX).Total_Deviation = 0 THEN 0 ELSE
 				(p_RECORDS(v_IDX).Generation_Deviation+p_RECORDS(v_IDX).Injection_Deviation +
 				p_RECORDS(v_IDX).Withdrawal_Deviation)/p_RECORDS(v_IDX).Total_Deviation END;
		v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).Total_Bal_Credits;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := p_RECORDS(v_IDX).Bal_Charge;
	    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.Component_Id := v_OR_BAL_COMP;
        v_BILLING_STATEMENT.CHARGE_Id := v_OR_BAL_CH_ID;
        v_BILLING_STATEMENT.Charge_Quantity := v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT.Charge_Rate := v_FORMULA_CHARGE.CHARGE_RATE;
        v_BILLING_STATEMENT.Charge_Amount := v_FORMULA_CHARGE.CHARGE_AMOUNT;
        v_BILLING_STATEMENT.Bill_Quantity := v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT.Bill_Amount := v_FORMULA_CHARGE.CHARGE_AMOUNT;

        PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_OP_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_LOST_OPP_COST
    (
    p_RECORDS IN MEX_PJM_OP_RES_LOC_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(64);
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
v_LAST_DATE DATE := LOW_DATE;
v_PSE_ID NUMBER(9);
v_BAL_OP_COMP NUMBER(9);
v_BAL_OP_LOC_COMP NUMBER(9);
v_BAL_OP_EXCESS_COMP NUMBER(9);
v_BAL_OPRES_CR_ID NUMBER(9);
v_BAL_OPRES_CR_LOC_ID NUMBER(9);
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_ID VARCHAR2(64);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_ITERATOR_ID NUMBER(9) := 0;
v_UPDATE BOOLEAN;
v_TEST NUMBER;
v_EXCESS_AMT NUMBER;
BEGIN
    p_STATUS := GA.SUCCESS;
	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do
    v_ITERATOR.ITERATOR_ID := 0;
	v_IDX := p_RECORDS.FIRST;
    v_BAL_OP_COMP := GET_COMPONENT('PJM-2375');
    v_BAL_OP_LOC_COMP := GET_COMPONENT('PJM:BalOpResCredLOC');
    v_BAL_OP_EXCESS_COMP := GET_COMPONENT('PJM:BalOpResCredExcess');

    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_BAL_OP_COMP);

    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        v_CHARGE_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).CHARGE_DATE, p_RECORDS(v_IDX).HR_ENDING,
                                p_RECORDS(v_IDX).DST_FLAG);
		v_PSE_ID := GET_PSE(p_RECORDS(v_IDX).ORG_ID, p_RECORDS(v_IDX).ORG_NAME);
        v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;
        IF v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).CHARGE_DATE,'DD') THEN
            IF v_LAST_DATE <> LOW_DATE THEN
                UPDATE_COMBINATION_CHARGE(v_BAL_OPRES_CR_ID, v_BAL_OPRES_CR_LOC_ID, 'FORMULA',-1,v_LAST_DATE, v_BAL_OP_LOC_COMP);
            v_UPDATE := TRUE;
            BEGIN
                SELECT B.ENTITY_ID INTO v_TEST
                FROM BILLING_STATEMENT B
                WHERE B.ENTITY_ID = v_PSE_ID
                AND B.COMPONENT_ID = v_BAL_OP_COMP
                AND B.CHARGE_ID = v_BAL_OPRES_CR_ID
                AND B.STATEMENT_STATE = GA.EXTERNAL_STATE
                AND B.STATEMENT_DATE = v_LAST_DATE;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                --create billing_statement record; this will happen if no OpResExcess for this day
                v_UPDATE := FALSE;
                v_BILLING_STATEMENT.Component_Id := v_BAL_OP_COMP;
                v_BILLING_STATEMENT.CHARGE_Id := v_BAL_OPRES_CR_ID;
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                DBMS_OUTPUT.put_line(v_BILLING_STATEMENT.Bill_Amount);
            END;

            IF v_UPDATE THEN
                BEGIN
                    SELECT NVL(C.CHARGE_AMOUNT,0) INTO v_EXCESS_AMT
                    FROM COMBINATION_CHARGE C
                    WHERE C.CHARGE_ID = v_BAL_OPRES_CR_ID
                    AND C.BEGIN_DATE = v_LAST_DATE
                    AND C.COMPONENT_ID = v_BAL_OP_EXCESS_COMP;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_EXCESS_AMT := 0;
                END;

                UPDATE BILLING_STATEMENT B
                SET CHARGE_QUANTITY = NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + v_EXCESS_AMT,
                    CHARGE_RATE = 1,
                    CHARGE_AMOUNT = NVL(v_BILLING_STATEMENT.Charge_Amount,0) + v_EXCESS_AMT,
                    BILL_QUANTITY = NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + v_EXCESS_AMT,
                    BILL_AMOUNT = NVL(v_BILLING_STATEMENT.Bill_Amount,0) + v_EXCESS_AMT
                WHERE B.COMPONENT_ID = v_BAL_OP_COMP
                AND B.CHARGE_ID = v_BAL_OPRES_CR_ID
                AND B.STATEMENT_DATE = v_LAST_DATE
                AND B.ENTITY_ID = v_PSE_ID
                AND B.STATEMENT_STATE = GA.EXTERNAL_STATE;
            END IF;

            v_BILLING_STATEMENT.Charge_Quantity := 0;
            v_BILLING_STATEMENT.Charge_Amount := 0;
            v_BILLING_STATEMENT.Bill_Quantity := 0;
            v_BILLING_STATEMENT.Bill_Amount := 0;
        END IF;
            v_LAST_DATE := TRUNC(v_CHARGE_DATE, 'DD');
    		v_BAL_OPRES_CR_ID := GET_CHARGE_ID(v_PSE_ID, v_BAL_OP_COMP, v_LAST_DATE, 'FORMULA');
            v_BAL_OPRES_CR_LOC_ID := GET_COMBO_CHARGE_ID(v_BAL_OPRES_CR_ID,v_BAL_OP_LOC_COMP,v_LAST_DATE,'FORMULA', TRUE);

        END IF;

        v_FORMULA_CHARGE.Charge_Date := v_CHARGE_DATE;
        v_FORMULA_CHARGE_VAR.Charge_Date := v_CHARGE_DATE;
        v_FORMULA_CHARGE.Charge_Id := v_BAL_OPRES_CR_LOC_ID;
		v_FORMULA_CHARGE_VAR.Charge_Id := v_BAL_OPRES_CR_LOC_ID;

        v_ITERATOR_NAME.CHARGE_ID := v_BAL_OPRES_CR_LOC_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Generator_ID';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

        v_ITERATOR.CHARGE_ID := v_BAL_OPRES_CR_LOC_ID;
        v_ID := p_RECORDS(v_IDX).UNIT_ID;
       	IF v_ITERATOR_ID_MAP.EXISTS(v_ID) THEN
            v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ID);
		ELSE
            v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ID) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

        v_ITERATOR.ITERATOR1 := v_ID;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

        v_FORMULA_CHARGE_VAR.Variable_Name := 'DayAheadMW';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).DA_MW;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'OfferAtDayAheadMW';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).OFFER_DA_MW;
        v_FORMULA_CHARGE_VAR.Variable_Name := 'DALMP';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).DA_LMP;
        v_FORMULA_CHARGE_VAR.Variable_Name := 'RealTimeMW';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).RT_MW;
        v_FORMULA_CHARGE_VAR.Variable_Name := 'OfferAtRealTimeMW';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).OFFER_RT_MW;
        v_FORMULA_CHARGE_VAR.Variable_Name := 'RTLMP';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).RT_LMP;
        v_FORMULA_CHARGE_VAR.Variable_Name := 'RTDesiredMW';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).RT_DESIRED_MW;
        v_FORMULA_CHARGE_VAR.Variable_Name := 'MWHReduced';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).MWH_REDUCED;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        IF NVL(p_RECORDS(v_IDX).MWH_REDUCED,0) > 0 THEN
            v_FORMULA_CHARGE.Charge_Quantity := p_RECORDS(v_IDX).MWH_REDUCED;
            v_FORMULA_CHARGE.Charge_Rate := p_RECORDS(v_IDX).RT_LMP - p_RECORDS(v_IDX).OFFER_RT_MW;
            v_FORMULA_CHARGE.Charge_Amount := p_RECORDS(v_IDX).LOC_CREDIT;
        ELSIF (p_RECORDS(v_IDX).RT_LMP - p_RECORDS(v_IDX).DA_LMP) >
                    (p_RECORDS(v_IDX).RT_LMP - p_RECORDS(v_IDX).OFFER_DA_MW) THEN
            v_FORMULA_CHARGE.Charge_Quantity := (p_RECORDS(v_IDX).RT_LMP - p_RECORDS(v_IDX).DA_LMP);
            v_FORMULA_CHARGE.Charge_Rate := p_RECORDS(v_IDX).DA_MW;
        ELSE
            v_FORMULA_CHARGE.Charge_Quantity := (p_RECORDS(v_IDX).RT_LMP - p_RECORDS(v_IDX).OFFER_DA_MW);
            v_FORMULA_CHARGE.Charge_Rate := p_RECORDS(v_IDX).DA_MW;
        END IF;

        v_FORMULA_CHARGE.Charge_Amount := p_RECORDS(v_IDX).LOC_CREDIT;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.Charge_Quantity := NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + -v_FORMULA_CHARGE.Charge_Amount;
        v_BILLING_STATEMENT.Charge_Rate := 1;
        v_BILLING_STATEMENT.Charge_Amount := NVL(v_BILLING_STATEMENT.Charge_Amount,0) + -v_FORMULA_CHARGE.Charge_Amount;
        v_BILLING_STATEMENT.Bill_Quantity := NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + -v_FORMULA_CHARGE.Charge_Amount;
        v_BILLING_STATEMENT.Bill_Amount := NVL(v_BILLING_STATEMENT.Bill_Amount,0) + -v_FORMULA_CHARGE.Charge_Amount;

        v_IDX := p_RECORDS.NEXT(v_IDX);
    END LOOP;
    UPDATE_COMBINATION_CHARGE(v_BAL_OPRES_CR_ID, v_BAL_OPRES_CR_LOC_ID, 'FORMULA',-1,v_LAST_DATE, v_BAL_OP_LOC_COMP);
    v_UPDATE := TRUE;
            BEGIN
                SELECT B.ENTITY_ID INTO v_TEST
                FROM BILLING_STATEMENT B
                WHERE B.ENTITY_ID = v_PSE_ID
                AND B.COMPONENT_ID = v_BAL_OP_COMP
                AND B.CHARGE_ID = v_BAL_OPRES_CR_ID
                AND B.STATEMENT_STATE = GA.EXTERNAL_STATE
                AND B.STATEMENT_DATE = v_LAST_DATE;
            EXCEPTION
            WHEN NO_DATA_FOUND THEN
                --create billing_statement record; this will happen if no OpResExcess for this day
                v_UPDATE := FALSE;
                v_BILLING_STATEMENT.Component_Id := v_BAL_OP_COMP;
                v_BILLING_STATEMENT.CHARGE_Id := v_BAL_OPRES_CR_ID;
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
            END;

            IF v_UPDATE THEN
                BEGIN
                    SELECT NVL(C.CHARGE_AMOUNT,0) INTO v_EXCESS_AMT
                    FROM COMBINATION_CHARGE C
                    WHERE C.CHARGE_ID = v_BAL_OPRES_CR_ID
                    AND C.BEGIN_DATE = v_LAST_DATE
                    AND C.COMPONENT_ID = v_BAL_OP_EXCESS_COMP;
                EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_EXCESS_AMT := 0;
                END;

                UPDATE BILLING_STATEMENT B
                 SET CHARGE_QUANTITY = NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + v_EXCESS_AMT,
                    CHARGE_RATE = 1,
                    CHARGE_AMOUNT = NVL(v_BILLING_STATEMENT.Charge_Amount,0) + v_EXCESS_AMT,
                    BILL_QUANTITY = NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + v_EXCESS_AMT,
                    BILL_AMOUNT = NVL(v_BILLING_STATEMENT.Bill_Amount,0) + v_EXCESS_AMT
                WHERE B.COMPONENT_ID = v_BAL_OP_COMP
                AND B.CHARGE_ID = v_BAL_OPRES_CR_ID
                AND B.STATEMENT_DATE = v_LAST_DATE
                AND B.ENTITY_ID = v_PSE_ID
                AND B.STATEMENT_STATE = GA.EXTERNAL_STATE;
            END IF;

    COMMIT;
END IMPORT_OP_RES_LOST_OPP_COST;
--------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_GEN_CREDITS
	(
	p_RECORDS IN MEX_PJM_OPRES_GEN_CREDITS_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(64);
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
v_LAST_DATE DATE := LOW_DATE;
v_PSE_ID NUMBER(9);
v_DA_OP_COMP NUMBER(9);
v_BAL_OP_COMP NUMBER(9);
v_BAL_EX_COMP NUMBER(9);
v_DA_OPRES_CR_ID NUMBER(9);
v_BAL_OPRES_CR_ID NUMBER(9);
v_BAL_OPRES_CR_EXCESS_ID NUMBER(9);
v_ID VARCHAR2(64);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_ITERATOR_ID NUMBER(9) := 0;
v_FORMULA_CHARGE     FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_BILLING_STATEMENT_1 BILLING_STATEMENT%ROWTYPE;
v_BILLING_STATEMENT_2 BILLING_STATEMENT%ROWTYPE;
BEGIN
    p_STATUS := GA.SUCCESS;
	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do
    v_ITERATOR.ITERATOR_ID := 0;
	v_IDX := p_RECORDS.FIRST;
    v_DA_OP_COMP := GET_COMPONENT('PJM-2370');
    v_BAL_OP_COMP := GET_COMPONENT('PJM-2375');
    v_BAL_EX_COMP := GET_COMPONENT('PJM:BalOpResCredExcess');

    v_BILLING_STATEMENT_1.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_1.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT_1.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_1.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_1.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT_1.Product_Id := GET_PRODUCT(v_DA_OP_COMP);
    v_BILLING_STATEMENT_2.Entity_Type := 'PSE';
    v_BILLING_STATEMENT_2.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT_2.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT_2.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT_2.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT_2.Product_Id := GET_PRODUCT(v_BAL_OP_COMP);


    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
       	v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).CHARGE_DATE) + 1 / 86400;
		v_PSE_ID      := GET_PSE(NULL, p_RECORDS(v_IDX).ORG_NAME);
        v_BILLING_STATEMENT_1.Entity_Id := v_PSE_ID;
        v_BILLING_STATEMENT_2.Entity_Id := v_PSE_ID;

        IF v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).CHARGE_DATE,'DD') THEN
            --put billing statement for previous day
            IF v_LAST_DATE <> LOW_DATE THEN
                UPDATE_COMBINATION_CHARGE(v_BAL_OPRES_CR_ID,v_BAL_OPRES_CR_EXCESS_ID,'FORMULA',-1, v_LAST_DATE, v_BAL_EX_COMP);
                v_BILLING_STATEMENT_1.Component_Id := v_DA_OP_COMP;
                v_BILLING_STATEMENT_1.CHARGE_Id := v_DA_OPRES_CR_ID;
                v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);

                v_BILLING_STATEMENT_2.Component_Id := v_BAL_OP_COMP;
                v_BILLING_STATEMENT_2.CHARGE_Id := v_BAL_OPRES_CR_ID;
                v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

                v_BILLING_STATEMENT_1.Charge_Quantity := 0;
                v_BILLING_STATEMENT_1.Charge_Amount := 0;
                v_BILLING_STATEMENT_1.Bill_Quantity := 0;
                v_BILLING_STATEMENT_1.Bill_Amount := 0;
                v_BILLING_STATEMENT_2.Charge_Quantity := 0;
                v_BILLING_STATEMENT_2.Charge_Amount := 0;
                v_BILLING_STATEMENT_2.Bill_Quantity := 0;
                v_BILLING_STATEMENT_2.Bill_Amount := 0;

            END IF;

            v_LAST_DATE := TRUNC(v_CHARGE_DATE, 'DD');
    		v_DA_OPRES_CR_ID := GET_CHARGE_ID(v_PSE_ID, v_DA_OP_COMP, v_LAST_DATE, 'FORMULA');
    		v_BAL_OPRES_CR_ID := GET_CHARGE_ID(v_PSE_ID, v_BAL_OP_COMP, v_LAST_DATE, 'FORMULA');
            v_BAL_OPRES_CR_EXCESS_ID := GET_COMBO_CHARGE_ID(v_BAL_OPRES_CR_ID,v_BAL_EX_COMP,v_LAST_DATE,'FORMULA',TRUE);

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID IN(v_DA_OP_COMP, v_BAL_OP_COMP)
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE  AND CHARGE_ID IN(v_DA_OPRES_CR_ID,v_BAL_OPRES_CR_ID);

        END IF;

        v_FORMULA_CHARGE.Charge_Date := v_CHARGE_DATE;
        v_FORMULA_CHARGE_VAR.Charge_Date := v_CHARGE_DATE;
        v_FORMULA_CHARGE.Charge_Id := v_DA_OPRES_CR_ID;
		v_FORMULA_CHARGE_VAR.Charge_Id := v_DA_OPRES_CR_ID;

        v_ITERATOR_NAME.CHARGE_ID := v_DA_OPRES_CR_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Generator_ID';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_DA_OPRES_CR_ID;
        v_ID := p_RECORDS(v_IDX).UNIT_ID;
       	IF v_ITERATOR_ID_MAP.EXISTS(v_ID) THEN
            v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ID);
		ELSE
            v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ID) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

        v_ITERATOR.ITERATOR1 := v_ID;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

        v_FORMULA_CHARGE_VAR.Variable_Name := 'DayAheadOffer';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).DA_OFFER;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'DayAheadMarketValue';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).DA_VALUE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.Charge_Quantity := p_RECORDS(v_IDX).DA_CREDIT;
        v_FORMULA_CHARGE.Charge_Rate := 1;
        v_FORMULA_CHARGE.Charge_Amount := p_RECORDS(v_IDX).DA_CREDIT;

        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);


        v_BILLING_STATEMENT_1.Charge_Quantity := NVL(v_BILLING_STATEMENT_1.Charge_Quantity,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT_1.Charge_Rate := 1;
        v_BILLING_STATEMENT_1.Charge_Amount := NVL(v_BILLING_STATEMENT_1.Charge_Amount,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT_1.Bill_Quantity := NVL(v_BILLING_STATEMENT_1.Bill_Quantity,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT_1.Bill_Amount := NVL(v_BILLING_STATEMENT_1.Bill_Amount,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;

        v_FORMULA_CHARGE.Charge_Id := v_BAL_OPRES_CR_EXCESS_ID;
		v_FORMULA_CHARGE_VAR.Charge_Id := v_BAL_OPRES_CR_EXCESS_ID;

        v_ITERATOR_NAME.CHARGE_ID := v_BAL_OPRES_CR_EXCESS_ID;
        PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

        v_ITERATOR.CHARGE_ID := v_BAL_OPRES_CR_EXCESS_ID;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE_VAR.Variable_Name := 'BalEnergyMktValue';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).BAL_VALUE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'RTOfferAmount';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).RT_OFFER;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'DAOpResCredit';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).DA_CREDIT;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'RegMktRevenue';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).REG_REVENUE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'SpinReserveRevenue';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).SPIN_RES_REV;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.Variable_Name := 'ReactiveServRevenue';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).REACT_SERV_REV;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.Charge_Quantity := p_RECORDS(v_IDX).BAL_CREDIT;
        v_FORMULA_CHARGE.Charge_Rate := 1;
        v_FORMULA_CHARGE.Charge_Amount := p_RECORDS(v_IDX).BAL_CREDIT;

        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        --put billing statement for Bal Op Res Credit here & update in the
        -- import of Lost Opp Credits summary
        v_BILLING_STATEMENT_2.Charge_Quantity := NVL(v_BILLING_STATEMENT_2.Charge_Quantity,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT_2.Charge_Rate := 1;
        v_BILLING_STATEMENT_2.Charge_Amount := NVL(v_BILLING_STATEMENT_2.Charge_Amount,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT_2.Bill_Quantity := NVL(v_BILLING_STATEMENT_2.Bill_Quantity,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT_2.Bill_Amount := NVL(v_BILLING_STATEMENT_2.Bill_Amount,0) +
                                                -v_FORMULA_CHARGE.CHARGE_QUANTITY;

        v_IDX := p_RECORDS.NEXT(v_IDX);
    END LOOP;

    v_BILLING_STATEMENT_1.Component_Id := v_DA_OP_COMP;
    v_BILLING_STATEMENT_1.CHARGE_Id := v_DA_OPRES_CR_ID;
    v_BILLING_STATEMENT_1.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_1.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_1);

    v_BILLING_STATEMENT_2.Component_Id := v_BAL_OP_COMP;
    v_BILLING_STATEMENT_2.CHARGE_Id := v_BAL_OPRES_CR_ID;
    v_BILLING_STATEMENT_2.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT_2.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT_2);

    --UPDATE_COMBINATION_CHARGE(v_BAL_OPRES_CR_ID,v_BAL_OPRES_CR_EXCESS_ID,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_BAL_OPRES_CR_ID,v_BAL_OPRES_CR_EXCESS_ID,'FORMULA',-1, v_LAST_DATE, v_BAL_EX_COMP);
    COMMIT;
END IMPORT_OP_RES_GEN_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SYNCH_CONDENS_SUMMARY
	(
	p_RECORDS IN MEX_PJM_SYNCH_COND_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
v_COND_MKT_PR_ID NUMBER(9);
v_SYNC_COND_CH_ID NUMBER(9);
v_RT_EXPORTS_TX_ID NUMBER(9);
v_RT_LOAD_TX_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
	ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_COMMODITY_ID);
    v_COMPONENT_ID := GET_COMPONENT('PJM-1377');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Component_Id := v_COMPONENT_ID;
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_COMPONENT_ID);
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;


	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).DAY) + 1/86400;
		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).ORG_ID OR
		   v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY,'DD') THEN
		   	-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE := TRUNC(v_CHARGE_DATE,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;

			v_SYNC_COND_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'FORMULA');
            IF v_SYNC_COND_CH_ID IS NULL THEN
            	LOGS.LOG_WARN('PJM:SyncCondChg Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_SYNCH_CONDENS_SUMMARY');
                RETURN;
            END IF;

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID = v_COMPONENT_ID
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;

		END IF;

        --update market prices
		v_COND_MKT_PR_ID := GET_MARKET_PRICE('PJM:CondCrTotal');
		IF v_COND_MKT_PR_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_COND_MKT_PR_ID,
      							p_MARKET_PRICE_NAME => 'PJM:CondenserCrTotal',
								p_MARKET_PRICE_ALIAS =>'PJM:CondenserCrTotal',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Day',
                        		p_MARKET_TYPE => MM_PJM_UTIL.g_REALTIME,
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:CondCrTotal',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;

		PUT_MARKET_PRICE_VALUE(v_COND_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).PJM_Total_Cond_Cr);

        --get transaction ids, update schedule
        v_RT_LOAD_TX_ID := GET_TX_ID('PJM:TotalRTLoad',
                                      'Load',
                                      'PJM:TotalRealTimeLoad',
                                      'Day',
                                      v_COMMODITY_ID);

        PUT_SCHEDULE_VALUE(v_RT_LOAD_TX_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).PJM_Total_RT_Load);

        v_RT_EXPORTS_TX_ID := GET_TX_ID('PJM:TotalRTExports',
                                      'Sale',
                                      'PJM:TotalRealTimeExports',
                                      'Day',
                                      v_COMMODITY_ID);


        PUT_SCHEDULE_VALUE(v_RT_EXPORTS_TX_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).PJM_Total_RT_Exports);

		-- next, update formula charges and variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;

		-- day ahead charge first
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SYNC_COND_CH_ID;
		v_FORMULA_CHARGE.CHARGE_ID := v_SYNC_COND_CH_ID;

		-- put variables
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalCondenserCredits';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).PJM_Total_Cond_Cr;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RealTimeLoad';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).RT_Load;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RealTimeExports';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).RT_Exports;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalRTLoad';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).PJM_Total_RT_Load;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalRTExports';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).PJM_Total_RT_Exports;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		-- put charge
		v_FORMULA_CHARGE.CHARGE_QUANTITY :=
        	CASE WHEN (p_RECORDS(v_IDX).PJM_Total_RT_Load + p_RECORDS(v_IDX).PJM_Total_RT_Exports) = 0 THEN 0
            ELSE (p_RECORDS(v_IDX).RT_Load + p_RECORDS(v_IDX).RT_Exports)
                  /(p_RECORDS(v_IDX).PJM_Total_RT_Load + p_RECORDS(v_IDX).PJM_Total_RT_Exports) END;
		v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).PJM_Total_Cond_Cr;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := p_RECORDS(v_IDX).Charge;
	    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.CHARGE_Id := v_SYNC_COND_CH_ID;
        v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
        v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
        v_BILLING_STATEMENT.Charge_Quantity := v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT.Charge_Rate := v_FORMULA_CHARGE.CHARGE_RATE;
        v_BILLING_STATEMENT.Charge_Amount := v_FORMULA_CHARGE.CHARGE_AMOUNT;
        v_BILLING_STATEMENT.Bill_Quantity := v_FORMULA_CHARGE.CHARGE_QUANTITY;
        v_BILLING_STATEMENT.Bill_Amount := v_FORMULA_CHARGE.CHARGE_AMOUNT;

        PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_SYNCH_CONDENS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSSES_CHARGES
	(
	p_RECORDS IN MEX_PJM_LOSSES_CHARGES_TBL,
	p_STATUS OUT NUMBER
	) AS
v_DA_CH_ID NUMBER(9);
v_RT_CH_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_REC MEX_PJM_LOSSES_CHARGES;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		v_REC := p_RECORDS(v_IDX);
		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).ORG_ID OR
		   v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY,'MM') THEN
		   	-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE := TRUNC(p_RECORDS(v_IDX).DAY,'MM');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);

			v_COMPONENT_ID := GET_COMPONENT('PJM:DATxLossChg');
			v_DA_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula');
			v_COMPONENT_ID := GET_COMPONENT('PJM:BalTxLossChg');
			v_RT_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula');
		END IF;

		-- put the data
		v_CHARGE_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).DAY,
        									p_RECORDS(v_IDX).HOUR,
                                            p_RECORDS(v_IDX).DST_FLAG);

		v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_FACTOR := 1.0;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;


		-- first put the day-ahead charge
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_DA_CH_ID;
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'LossFactor';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).LOSS_FACTOR;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'LoadWtgAvgLMP';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).DA_LOAD_WEIGHTED_LMP;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.CHARGE_ID := v_DA_CH_ID;
		v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).LOSS_FACTOR * p_RECORDS(v_IDX).DA_LOAD_WEIGHTED_LMP;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).DA_NET_INTERCHANGE;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := v_FORMULA_CHARGE.CHARGE_QUANTITY * v_FORMULA_CHARGE.CHARGE_RATE;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

		-- then put the balancing charge
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_RT_CH_ID;
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'LossFactor';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).LOSS_FACTOR;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'LoadWtgAvgLMP';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).RT_LOAD_WEIGHTED_LMP;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.CHARGE_ID := v_RT_CH_ID;
		v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).LOSS_FACTOR * p_RECORDS(v_IDX).RT_LOAD_WEIGHTED_LMP;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).BAL_NET_INTERCHANGE_DEVIATION;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := v_FORMULA_CHARGE.CHARGE_QUANTITY * v_FORMULA_CHARGE.CHARGE_RATE;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_LOSSES_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CREDITS
    (
	p_STATUS OUT NUMBER
	) AS

v_TRANS_LOSS_COMP NUMBER(9);
v_TRANS_LOSS_CR_ID NUMBER(9);
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_PSE_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_TRANSM_COMM IT_COMMODITY.COMMODITY_ID%TYPE;
v_RT_ENG_COMM IT_COMMODITY.COMMODITY_ID%TYPE;
v_CHG_QTY NUMBER;
v_MARKET_PRICE_ID NUMBER(9);
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

CURSOR p_LOSS IS
    SELECT * FROM PJM_TXN_LOSS_CREDIT_SUMMARY C
    ORDER BY C.DAY, C.HOUR;

BEGIN
     p_STATUS := GA.SUCCESS;
     ID.ID_FOR_COMMODITY('Transmission',FALSE, v_TRANSM_COMM);
     ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_RT_ENG_COMM);

    v_TRANS_LOSS_COMP := GET_COMPONENT('PJM-2220');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Component_Id := v_TRANS_LOSS_COMP;
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_TRANS_LOSS_COMP);

    FOR v_LOSS IN p_LOSS LOOP
        IF v_LAST_ORG_ID <> v_LOSS.Org_Nid OR v_LAST_DATE <> TRUNC(v_LOSS.Day,'DD') THEN
            IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                v_BILLING_STATEMENT.Charge_Quantity :=0;
                v_BILLING_STATEMENT.Charge_Amount := 0;
                v_BILLING_STATEMENT.Bill_Quantity := 0;
                v_BILLING_STATEMENT.Bill_Amount := 0;
            END IF;
            v_LAST_ORG_ID := v_LOSS.Org_Nid;
			v_LAST_DATE := TRUNC(v_LOSS.Day,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;

			v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

			v_TRANS_LOSS_CR_ID := GET_CHARGE_ID(v_PSE_ID,v_TRANS_LOSS_COMP,v_LAST_DATE,'FORMULA');

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID
            AND COMPONENT_ID = v_TRANS_LOSS_COMP
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;

        END IF;

        v_CHARGE_DATE := GET_CHARGE_DATE(v_LOSS.Day, v_LOSS.Hour, v_LOSS.Dst);

        v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_TRANS_LOSS_CR_ID;
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RealTimeLoad';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_LOSS.Real_Time_Load;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RealTimeExports';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_LOSS.Real_Time_Exports;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalLoadPlusExports';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_LOSS.Total_Pjm_Rt_Ld_Plus_Exports;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalLossRevenues';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_LOSS.Total_Pjm_Loss_Revenues;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        IF v_LOSS.Total_Pjm_Rt_Ld_Plus_Exports <> 0 THEN
            v_CHG_QTY := (NVL(v_LOSS.Real_Time_Load,0) + NVL(v_LOSS.Real_Time_Exports,0))/
                            v_LOSS.Total_Pjm_Rt_Ld_Plus_Exports;
        ELSE
            v_CHG_QTY := 0;
        END IF;

        v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_FACTOR := 1;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE.CHARGE_ID := v_TRANS_LOSS_CR_ID;
		v_FORMULA_CHARGE.CHARGE_RATE := v_LOSS.Total_Pjm_Loss_Revenues;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := -v_CHG_QTY;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := -v_LOSS.Transmission_Loss_Credit;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.Charge_Id := v_TRANS_LOSS_CR_ID;
        v_BILLING_STATEMENT.Charge_Quantity := NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + NVL(-v_LOSS.Transmission_Loss_Credit,0);
        v_BILLING_STATEMENT.Charge_Amount := NVL(v_BILLING_STATEMENT.Charge_Amount,0) + NVL(-v_LOSS.Transmission_Loss_Credit,0);
        v_BILLING_STATEMENT.Charge_Rate := 1;
        v_BILLING_STATEMENT.Bill_Quantity := NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + NVL(-v_LOSS.Transmission_Loss_Credit,0);
        v_BILLING_STATEMENT.Bill_Amount := NVL(v_BILLING_STATEMENT.Bill_Amount,0) + NVL(-v_LOSS.Transmission_Loss_Credit,0);

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:TotalLossRevenues');
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Total Loss Revenues',
								p_MARKET_PRICE_ALIAS => 'PJM Total Loss Revenues',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Result',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_TRANSM_COMM,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:TotalLossRevenues',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE, v_LOSS.Total_Pjm_Loss_Revenues);

        v_TRANSACTION_ID := GET_TX_ID('PJM:TotalLoadPlusExports',
                                      'Market Result',
                                      'PJM Total Load Plus Exports',
                                      'Hour',
                                      v_RT_ENG_COMM);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           v_LOSS.Total_Pjm_Rt_Ld_Plus_Exports);


    END LOOP;
    v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
    DELETE FROM PJM_TXN_LOSS_CREDIT_SUMMARY;
    COMMIT;

END IMPORT_TRANS_LOSS_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_INADVERTENT_INTERCHANGE
    (
	p_STATUS OUT NUMBER
	) AS

v_INADV_COMP NUMBER(9);
v_INADV_CH_ID NUMBER(9);
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_PSE_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_RT_ENG_COMM IT_COMMODITY.COMMODITY_ID%TYPE;
v_CHG_QTY NUMBER;
v_MARKET_PRICE_ID NUMBER(9);
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

CURSOR p_INADV IS
    SELECT * FROM PJM_INADV_INTERCHG_CHARGE_SUM C
    ORDER BY C.DAY, C.HOUR;

BEGIN
    p_STATUS := GA.SUCCESS;
    ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_RT_ENG_COMM);

    v_INADV_COMP := GET_COMPONENT('PJM-1230');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Component_Id := v_INADV_COMP;
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_INADV_COMP);

    FOR v_INADV IN p_INADV LOOP
        IF v_LAST_ORG_ID <> v_INADV.Org_Nid OR v_LAST_DATE <> TRUNC(v_INADV.Day,'DD') THEN
            IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                v_BILLING_STATEMENT.Charge_Quantity :=0;
                v_BILLING_STATEMENT.Charge_Amount := 0;
                v_BILLING_STATEMENT.Bill_Quantity := 0;
                v_BILLING_STATEMENT.Bill_Amount := 0;
            END IF;
            v_LAST_ORG_ID := v_INADV.Org_Nid;
			v_LAST_DATE := TRUNC(v_INADV.Day,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;

			v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

			v_INADV_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_INADV_COMP,v_LAST_DATE,'FORMULA');

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID
            AND COMPONENT_ID = v_INADV_COMP
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;

        END IF;

        v_CHARGE_DATE := GET_CHARGE_DATE(v_INADV.Day, v_INADV.Hour, v_INADV.Dst);

        v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_INADV_CH_ID;
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RealTimeLoad';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_INADV.Customer_Rt_Load;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalRTLoad';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_INADV.Total_Pjm_Rt_Load;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotaInadvInt';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_INADV.Total_Pjm_Inadv_Interchange;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        IF v_INADV.Total_Pjm_Rt_Load <> 0 THEN
            v_CHG_QTY := NVL(v_INADV.Customer_Rt_Load,0) / v_INADV.Total_Pjm_Rt_Load;
        ELSE
            v_CHG_QTY := 0;
        END IF;

        v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_FACTOR := 1;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE.CHARGE_ID := v_INADV_CH_ID;
		v_FORMULA_CHARGE.CHARGE_RATE := 1;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHG_QTY;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := NVL(v_INADV.Customer_Inadv_Energy_Charge,0) + NVL(v_INADV.Customer_Inadv_Cong_Charge,0) + NVL(v_INADV.Customer_Inadv_Loss_Charge,0);
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.Charge_Id := v_INADV_CH_ID;
        v_BILLING_STATEMENT.Charge_Quantity := NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + NVL(v_INADV.Customer_Inadv_Energy_Charge,0)
                                                + NVL(v_INADV.Customer_Inadv_Cong_Charge,0) + NVL(v_INADV.Customer_Inadv_Loss_Charge,0);
        v_BILLING_STATEMENT.Charge_Amount := NVL(v_BILLING_STATEMENT.Charge_Amount,0) + NVL(v_INADV.Customer_Inadv_Energy_Charge,0)
                                                + NVL(v_INADV.Customer_Inadv_Cong_Charge,0) + NVL(v_INADV.Customer_Inadv_Loss_Charge,0);
        v_BILLING_STATEMENT.Charge_Rate := 1;
        v_BILLING_STATEMENT.Bill_Quantity := NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + NVL(v_INADV.Customer_Inadv_Energy_Charge,0)
                                                + NVL(v_INADV.Customer_Inadv_Cong_Charge,0) + NVL(v_INADV.Customer_Inadv_Loss_Charge,0);
        v_BILLING_STATEMENT.Bill_Amount := NVL(v_BILLING_STATEMENT.Bill_Amount,0) + NVL(v_INADV.Customer_Inadv_Energy_Charge,0)
                                                + NVL(v_INADV.Customer_Inadv_Cong_Charge,0) + NVL(v_INADV.Customer_Inadv_Loss_Charge,0);

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:TotalInadvertInt');
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Total Inadvertent Interchange',
								p_MARKET_PRICE_ALIAS => 'PJM Total Inadvertent Interchange',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Result',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:TotalInadvertInt',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE, v_INADV.Total_Pjm_Inadv_Interchange);

        v_TRANSACTION_ID := GET_TX_ID('PJM:TotalLoad',
                                      'Market Result',
                                      'PJM Total System Load',
                                      'Hour',
                                      v_RT_ENG_COMM);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           v_INADV.Total_Pjm_Rt_Load);


    END LOOP;
    v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
    DELETE FROM PJM_INADV_INTERCHG_CHARGE_SUM;
    COMMIT;

END IMPORT_INADVERTENT_INTERCHANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSSES_CREDITS
	(
	p_RECORDS IN MEX_PJM_LOSSES_CREDITS_TBL,
	p_STATUS OUT NUMBER
	) AS
v_TX_LOSS_CR_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_MARKET_PRICE_ID NUMBER(9);
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
	ID.ID_FOR_COMMODITY('Transmission',FALSE, v_COMMODITY_ID);
    v_COMPONENT_ID := GET_COMPONENT('PJM:TxLossCred');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Component_Id := v_COMPONENT_ID;
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_COMPONENT_ID);

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).ORG_ID OR
		   v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY,'DD') THEN

           IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                v_BILLING_STATEMENT.Charge_Quantity :=0;
                v_BILLING_STATEMENT.Charge_Amount := 0;
                v_BILLING_STATEMENT.Bill_Quantity := 0;
                v_BILLING_STATEMENT.Bill_Amount := 0;
            END IF;
		   	-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE := TRUNC(p_RECORDS(v_IDX).DAY,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;

			v_TX_LOSS_CR_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula');

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID = v_COMPONENT_ID
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;
		END IF;

		-- put the data
		v_CHARGE_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).DAY,
        									p_RECORDS(v_IDX).HOUR,
                                            p_RECORDS(v_IDX).DST_FLAG);

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:TxLossTotal-DayAhead');
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM DayAhead Transmission Losses Charges',
								p_MARKET_PRICE_ALIAS => 'PJM DA Trans Loss Total',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Result',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:TxLossTotal-DayAhead',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
								p_RECORDS(v_IDX).DA_TOTAL_CHARGES);

		v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:TxLossTotal-Balancing');
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Balancing Transmission Losses Charges',
								p_MARKET_PRICE_ALIAS => 'PJM Bal Trans Loss Total',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:TxLossTotal-Balancing',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
								p_RECORDS(v_IDX).BAL_TOTAL_CHARGES);

		v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:TxLossInKindTotal-DayAhead');
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Total Collected DayAhead Transmission Losses in Kind',
								p_MARKET_PRICE_ALIAS => 'PJM DA Trans LossInKind Total',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:TxLossInKindTotal-DayAhead',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
								p_RECORDS(v_IDX).DA_TOTAL_LOSSES_IN_KIND);

		v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:TxLossInKindTotal-Balancing');
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Total Collected Balancing Transmission Losses in Kind',
								p_MARKET_PRICE_ALIAS => 'PJM Bal Trans LossInKind Total',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:TxLossInKindTotal-Balancing',
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
								p_RECORDS(v_IDX).BAL_TOTAL_LOSSES_IN_KIND);

        ID.ID_FOR_COMMODITY('RealTime Energy',FALSE, v_COMMODITY_ID);

        v_TRANSACTION_ID := GET_TX_ID('PJM:TotalLoad',
                                      'Market Result',
                                      'PJM Total System Load',
                                      'Hour',
                                      v_COMMODITY_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).RT_SYSTEM_LOAD);

		v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_FACTOR := 1.0;
		v_FORMULA_CHARGE.ITERATOR_ID := 0;
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;


		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_TX_LOSS_CR_ID;
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Load';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).RT_LOAD;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SystemLoad';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).RT_SYSTEM_LOAD;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'DayAheadLossCharges';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).DA_TOTAL_CHARGES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'BalancingLossCharges';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).BAL_TOTAL_CHARGES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'DayAheadLossesInKind';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).DA_TOTAL_LOSSES_IN_KIND;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'BalancingLossesInKind';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).BAL_TOTAL_LOSSES_IN_KIND;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.CHARGE_ID := v_TX_LOSS_CR_ID;
		v_FORMULA_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).DA_TOTAL_CHARGES + p_RECORDS(v_IDX).DA_TOTAL_LOSSES_IN_KIND
        								+ p_RECORDS(v_IDX).BAL_TOTAL_CHARGES + p_RECORDS(v_IDX).BAL_TOTAL_LOSSES_IN_KIND;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := -p_RECORDS(v_IDX).LOAD_SHARE_RATIO;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := -p_RECORDS(v_IDX).CREDIT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.CHARGE_Id := v_TX_LOSS_CR_ID;
        v_BILLING_STATEMENT.Charge_Quantity := NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + NVL(v_FORMULA_CHARGE.CHARGE_AMOUNT,0);
        v_BILLING_STATEMENT.Charge_Rate := 1;
        v_BILLING_STATEMENT.Charge_Amount := NVL(v_BILLING_STATEMENT.Charge_Amount,0) + NVL(v_FORMULA_CHARGE.CHARGE_AMOUNT,0);
        v_BILLING_STATEMENT.Bill_Quantity := NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + NVL(v_FORMULA_CHARGE.CHARGE_AMOUNT,0);
        v_BILLING_STATEMENT.Bill_Amount := NVL(v_BILLING_STATEMENT.Bill_Amount,0) + NVL(v_FORMULA_CHARGE.CHARGE_AMOUNT,0);

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

    v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_LOSSES_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FTR_AUCTION
	(
	p_RECORDS IN MEX_PJM_FTR_AUCTION_TBL,
	p_STATUS OUT NUMBER
	) AS

v_TX_ID NUMBER(9);
v_TX_TYPE VARCHAR2(32);
v_FTR_CH_ID NUMBER(9);
v_FTR_CR_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_LOC NUMBER;
v_SINK VARCHAR2(32);
v_MONTH VARCHAR2(2);
v_YEAR VARCHAR2(4);
v_MON NUMBER(2);
v_YR NUMBER(4);
v_CLEARINGPRICE_ATTRIBUTE_ID NUMBER(9);
v_STATUS NUMBER;
v_SOURCE_ID NUMBER(9);
v_SINK_ID NUMBER(9);
v_VAL NUMBER;

CURSOR C_TRANS(v_CONTRACT IN NUMBER, v_TYPE IN VARCHAR2,
				v_SOURCE IN NUMBER, v_SINK IN NUMBER,
                v_CLASS_TYPE IN VARCHAR2, v_DATE IN DATE,
                v_YEAR IN NUMBER, v_MW IN NUMBER) IS
	SELECT DISTINCT TRANSACTION_ID
    FROM INTERCHANGE_TRANSACTION I, TEMPORAL_ENTITY_ATTRIBUTE T
    WHERE i.CONTRACT_ID = v_CONTRACT
    AND I.AGREEMENT_TYPE LIKE '%FTR%'
    AND I.TRANSACTION_TYPE = v_TYPE
    AND I.SOURCE_ID = v_SOURCE
    AND I.SINK_ID = v_SINK
    AND INSTR(UPPER(I.AGREEMENT_TYPE), UPPER(v_CLASS_TYPE)) > 0
    AND (I.BEGIN_DATE =  TO_DATE('01-JUN-' || v_YEAR,'DD-MON-YYYY')
    	OR I.BEGIN_DATE = v_DATE)
    AND T.ATTRIBUTE_ID = (SELECT ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE WHERE
    						ATTRIBUTE_NAME = 'ClearedMW')
    AND T.ATTRIBUTE_VAL = TO_CHAR(v_MW)
    AND I.TRANSACTION_ID = T.OWNER_ENTITY_ID;


BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

    ID.ID_FOR_ENTITY_ATTRIBUTE('ClearingPrice', 'TRANSACTION', 'Number',
         						TRUE, v_CLEARINGPRICE_ATTRIBUTE_ID);

	v_IDX := p_RECORDS.FIRST;
    IF p_RECORDS.EXISTS(v_IDX) THEN
        v_PSE_ID := GET_PSE(p_RECORDS(v_IDX).Org_ID, NULL);
        v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
        --delete any clearing prices if this import has already been run for some reason
        DELETE FROM TEMPORAL_ENTITY_ATTRIBUTE T WHERE
        T.ATTRIBUTE_ID = v_CLEARINGPRICE_ATTRIBUTE_ID
        AND T.BEGIN_DATE = p_RECORDS(v_IDX).MONTH
        AND T.OWNER_ENTITY_ID IN(SELECT TRANSACTION_ID FROM INTERCHANGE_TRANSACTION
        WHERE CONTRACT_ID = v_CONTRACT_ID);
    END IF;


    v_ITERATOR.ITERATOR_ID := 0;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).Org_ID OR
		   v_LAST_DATE <> p_RECORDS(v_IDX).Month THEN
			v_LAST_DATE := p_RECORDS(v_IDX).Month;
			v_LAST_ORG_ID := p_RECORDS(v_IDX).Org_ID;
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

            v_COMPONENT_ID := GET_COMPONENT('PJM-1500');
            v_FTR_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_LAST_DATE),'TRANSMISSION');
            v_COMPONENT_ID := GET_COMPONENT('PJM-2500');
            v_FTR_CR_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_LAST_DATE),'TRANSMISSION');
		END IF;
		IF p_RECORDS(v_IDX).Charge <> 0 THEN
            --cannot assume negative mw_cleared, which is a sale, will be a credit
			IF p_RECORDS(v_IDX).CLEARED_MW < 0 THEN
                v_TX_TYPE := 'Sale';
            ELSE
                v_TX_TYPE := 'Purchase';
            END IF;
            v_FORMULA_CHARGE.CHARGE_ID := v_FTR_CH_ID;
		ELSIF p_RECORDS(v_IDX).Credit <> 0 THEN
			v_TX_TYPE := 'Sale';
            v_FORMULA_CHARGE.CHARGE_ID := v_FTR_CR_ID;
		ELSE
			v_TX_TYPE := NULL;
		END IF;
		-- get the transaction ID for the record
		IF NOT v_TX_TYPE IS NULL THEN
        	v_LOC := INSTR(UPPER(p_RECORDS(v_IDX).SINK), '_ZONE');
            IF v_LOC > 0 THEN
            	v_SINK := SUBSTR(p_RECORDS(v_IDX).SINK, 1, v_LOC-1);
            ELSE
          		v_SINK := p_RECORDS(v_IDX).SINK;
            END IF;

            v_MONTH := TO_CHAR(p_RECORDS(v_IDX).MONTH, 'MM');
            v_YEAR := TO_CHAR(p_RECORDS(v_IDX).MONTH, 'YYYY');
            v_MON := TO_NUMBER(v_MONTH);
        	v_YR := TO_NUMBER(v_YEAR);

        	IF v_MON BETWEEN 1 AND 5 THEN
        		v_YR := v_YR - 1;
        	END IF;

            v_SOURCE_ID := MM_PJM_EFTR.ID_FOR_SERVICE_POINT_NAME(p_RECORDS(v_IDX).SOURCE);
            v_SINK_ID := MM_PJM_EFTR.ID_FOR_SERVICE_POINT_NAME(v_SINK);


            --FIND THE TXN ID
            FOR v_TRANS IN c_TRANS(v_CONTRACT_ID, v_TX_TYPE,
            						v_SOURCE_ID, v_SINK_ID,
            						p_RECORDS(v_IDX).CLASS_TYPE,
                                    p_RECORDS(v_IDX).MONTH,
                                    v_YR, p_RECORDS(v_IDX).CLEARED_MW) LOOP

           		v_TX_ID := v_TRANS.TRANSACTION_ID;
                BEGIN
                	SELECT T.ATTRIBUTE_VAL INTO v_VAL
                    FROM TEMPORAL_ENTITY_ATTRIBUTE T
                    WHERE T.OWNER_ENTITY_ID = v_TX_ID
                    AND T.ATTRIBUTE_ID = (SELECT ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE WHERE
                						ATTRIBUTE_NAME = 'ClearingPrice')
                    AND T.BEGIN_DATE = p_RECORDS(v_IDX).MONTH;


              	EXCEPTION
                	WHEN NO_DATA_FOUND THEN
                    	SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TX_ID, v_CLEARINGPRICE_ATTRIBUTE_ID,
        									p_RECORDS(v_IDX).MONTH, NULL, p_RECORDS(v_IDX).PRICE,
                                            v_TX_ID, v_CLEARINGPRICE_ATTRIBUTE_ID,
                                            p_RECORDS(v_IDX).MONTH, v_STATUS);
                     	COMMIT;
                        EXIT;
               END;

            END LOOP;


          IF v_TX_ID > 0 THEN
        	v_ITERATOR_NAME.CHARGE_ID := v_FORMULA_CHARGE.CHARGE_ID;
            v_ITERATOR_NAME.ITERATOR_NAME1 := 'PeakClass';
    		v_ITERATOR_NAME.ITERATOR_NAME2 := 'Source';
    		v_ITERATOR_NAME.ITERATOR_NAME3 := 'Sink';
    		v_ITERATOR_NAME.ITERATOR_NAME4 := 'TransactionID';
    		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
    		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

            v_ITERATOR.CHARGE_ID := v_FORMULA_CHARGE.CHARGE_ID;
            v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;

            v_ITERATOR.ITERATOR1 := p_RECORDS(v_IDX).CLASS_TYPE;
    		v_ITERATOR.ITERATOR2 := p_RECORDS(v_IDX).SOURCE;
    		v_ITERATOR.ITERATOR3 := p_RECORDS(v_IDX).SINK;
    		v_ITERATOR.ITERATOR4 := v_TX_ID;
    		v_ITERATOR.ITERATOR5 := NULL;
            PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

            v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
            v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

            v_CHARGE_DATE := p_RECORDS(v_IDX).MONTH + 1 / 86400;

            v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
        	v_FORMULA_CHARGE_VAR.CHARGE_ID := v_FORMULA_CHARGE.CHARGE_ID;

			v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ClearedMW';
    		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).CLEARED_MW;
    		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        	v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ClearingPrice';
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).PRICE;
        	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'NumberOfDays';
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := TO_NUMBER(TO_CHAR(LAST_DAY(p_RECORDS(v_IDX).MONTH),'DD'));
        	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

    		v_FORMULA_CHARGE.CHARGE_ID       := v_FORMULA_CHARGE.CHARGE_ID;
			v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
			v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).CLEARED_MW * TO_NUMBER(TO_CHAR(LAST_DAY(p_RECORDS(v_IDX).MONTH),'DD'));
			v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).PRICE;
			v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_FORMULA_CHARGE.CHARGE_QUANTITY * v_FORMULA_CHARGE.CHARGE_RATE;
			PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
            v_TX_ID :=0;
        	END IF;
		END IF;

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_FTR_AUCTION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MONTHLY_CREDIT_ALLOC
	(
	p_RECORDS IN MEX_PJM_MONTHLY_CRED_ALLOC_TBL,
	p_STATUS OUT NUMBER
	) AS
v_EXP_INT_MKT_PR_ID NUMBER(9);
v_RAMAPO_PAR_MKT_PR_ID NUMBER(9);
v_FIRM_TX_MKT_PR_ID NUMBER(9);
v_NETWORK_TX_SERV_MKT_PR_ID NUMBER(9);
v_NONFIRM_TX_SERV_MKT_PR_ID NUMBER(9);
v_EXP_INT_FML_CHARGE FORMULA_CHARGE%ROWTYPE;
v_RAMAPO_PAR_FML_CHARGE FORMULA_CHARGE%ROWTYPE;
v_NON_FM_P2P_TX_CRED FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR_ND FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_FORMULA_CHARGE_VAR_TND FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
BEGIN
  p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;

 	-- get charge IDs
    v_PSE_ID := GET_PSE(p_RECORDS(v_IDX).ORG_ID, p_RECORDS(v_IDX).ORG_NAME);
	v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).Month, 'MM') + 1/86400;

    v_COMPONENT_ID := GET_COMPONENT('PJM:ExpIntCred');
    v_EXP_INT_FML_CHARGE.CHARGE_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_EXP_INT_FML_CHARGE.ITERATOR_ID := 0;
    v_COMPONENT_ID := GET_COMPONENT('PJM:RamapoChg');
    v_RAMAPO_PAR_FML_CHARGE.CHARGE_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_RAMAPO_PAR_FML_CHARGE.ITERATOR_ID := 0;

    v_COMPONENT_ID := GET_COMPONENT('PJM:NonFirmP2PTxCr');
    v_NON_FM_P2P_TX_CRED.CHARGE_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
    v_NON_FM_P2P_TX_CRED.ITERATOR_ID := 0;


	-- and market price IDs
    v_EXP_INT_MKT_PR_ID := GET_MARKET_PRICE('PJM:ExpIntegrationTotal');
    v_RAMAPO_PAR_MKT_PR_ID := GET_MARKET_PRICE('PJM:RamapoPARTotal');
    v_FIRM_TX_MKT_PR_ID := GET_MARKET_PRICE('PJM:FirmTxServiceTotal');
	v_NETWORK_TX_SERV_MKT_PR_ID := GET_MARKET_PRICE('PJM:NetworkTxServiceTotal');
    v_NONFIRM_TX_SERV_MKT_PR_ID := GET_MARKET_PRICE('PJM:NonFirmTxServiceTotal');

	v_EXP_INT_FML_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
	v_RAMAPO_PAR_FML_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
    v_NON_FM_P2P_TX_CRED.CHARGE_DATE := v_CHARGE_DATE;
    v_FORMULA_CHARGE_VAR_ND.CHARGE_DATE := v_CHARGE_DATE;
    v_FORMULA_CHARGE_VAR_TND.CHARGE_DATE := v_CHARGE_DATE;
    v_FORMULA_CHARGE_VAR_ND.ITERATOR_ID := 0;
    v_FORMULA_CHARGE_VAR_TND.ITERATOR_ID := 0;
    v_FORMULA_CHARGE_VAR_ND.CHARGE_ID := v_NON_FM_P2P_TX_CRED.CHARGE_ID;
    v_FORMULA_CHARGE_VAR_TND.CHARGE_ID := v_NON_FM_P2P_TX_CRED.CHARGE_ID;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		CASE UPPER(SUBSTR(p_RECORDS(v_IDX).Determinant_Type,1,5))
		WHEN 'TOTAL' THEN
    		PUT_MARKET_PRICE_VALUE(v_EXP_INT_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).Expansion_Int_Credit);
    		PUT_MARKET_PRICE_VALUE(v_RAMAPO_PAR_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).Ramapo_PAR_Charge);
    		PUT_MARKET_PRICE_VALUE(v_FIRM_TX_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).Firm_P2P_Credit);
            PUT_MARKET_PRICE_VALUE(v_NETWORK_TX_SERV_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).PJM_CA_Ntwk_Firm_Demand_Charge);
            PUT_MARKET_PRICE_VALUE(v_NONFIRM_TX_SERV_MKT_PR_ID, TRUNC(v_CHARGE_DATE), p_RECORDS(v_IDX).Non_Firm_P2P_Credit);

			v_FORMULA_CHARGE_VAR_TND.VARIABLE_NAME := 'TotalNetworkDemandCharges';
            v_FORMULA_CHARGE_VAR_TND.VARIABLE_VAL  := p_RECORDS(v_IDX).PJM_CA_Ntwk_Firm_Demand_Charge;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR_TND);

            v_EXP_INT_FML_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).Expansion_Int_Credit;
			v_RAMAPO_PAR_FML_CHARGE.CHARGE_RATE := p_RECORDS(v_IDX).Ramapo_PAR_Charge;
            v_NON_FM_P2P_TX_CRED.CHARGE_RATE := p_RECORDS(v_IDX).Non_Firm_P2P_Credit;

		WHEN 'PARTI' THEN
			v_FORMULA_CHARGE_VAR_ND.VARIABLE_NAME := 'NetworkDemandCharges';
			v_FORMULA_CHARGE_VAR_ND.VARIABLE_VAL  := p_RECORDS(v_IDX).PJM_CA_Ntwk_Firm_Demand_Charge;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR_ND);

            v_EXP_INT_FML_CHARGE.CHARGE_AMOUNT := p_RECORDS(v_IDX).Expansion_Int_Credit;
			v_RAMAPO_PAR_FML_CHARGE.CHARGE_AMOUNT := p_RECORDS(v_IDX).Ramapo_PAR_Charge;
            v_NON_FM_P2P_TX_CRED.CHARGE_AMOUNT := -p_RECORDS(v_IDX).Non_Firm_P2P_Credit;

		ELSE
			NULL; -- this shouldn't ever happen!
		END CASE;

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;
    -- flush charges to formula charge table
    IF NOT v_EXP_INT_FML_CHARGE.CHARGE_ID IS NULL THEN
		IF v_EXP_INT_FML_CHARGE.CHARGE_RATE <> 0 THEN
		    v_EXP_INT_FML_CHARGE.CHARGE_QUANTITY := v_EXP_INT_FML_CHARGE.CHARGE_AMOUNT / v_EXP_INT_FML_CHARGE.CHARGE_RATE;
		END IF;
	    PC.PUT_FORMULA_CHARGE(v_EXP_INT_FML_CHARGE);
    END IF;
    IF NOT v_RAMAPO_PAR_FML_CHARGE.CHARGE_ID IS NULL THEN
		IF v_RAMAPO_PAR_FML_CHARGE.CHARGE_RATE <> 0 THEN
		    v_RAMAPO_PAR_FML_CHARGE.CHARGE_QUANTITY := v_RAMAPO_PAR_FML_CHARGE.CHARGE_AMOUNT / v_RAMAPO_PAR_FML_CHARGE.CHARGE_RATE;
		END IF;
	    PC.PUT_FORMULA_CHARGE(v_RAMAPO_PAR_FML_CHARGE);
    END IF;
    IF NOT v_NON_FM_P2P_TX_CRED.CHARGE_ID IS NULL THEN
		IF v_NON_FM_P2P_TX_CRED.CHARGE_RATE <> 0 THEN
		    v_NON_FM_P2P_TX_CRED.CHARGE_QUANTITY := v_FORMULA_CHARGE_VAR_ND.VARIABLE_VAL / v_FORMULA_CHARGE_VAR_TND.VARIABLE_VAL;
		END IF;
	    PC.PUT_FORMULA_CHARGE(v_NON_FM_P2P_TX_CRED);
    END IF;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_MONTHLY_CREDIT_ALLOC;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ARR_SUMMARY
	(
	p_RECORDS IN MEX_PJM_ARR_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
v_DATE DATE;
v_BEGIN_DATE DATE;
v_END_DATE DATE;
v_PSE_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_MARKET_PRICE_ID NUMBER(9);
v_PSE_ALIAS VARCHAR2(32);
v_ZONE_ID NUMBER(9);
v_RATE NUMBER := 0;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_ITERATOR_ID	 NUMBER(3) := 0;
v_ARR_CREDIT_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_LAST_DATE DATE := LOW_DATE;
BEGIN
    p_STATUS := GA.SUCCESS;

    IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

    v_IDX := p_RECORDS.FIRST;
    v_COMPONENT_ID := GET_COMPONENT('PJM-2510');

    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        v_CHARGE_DATE := p_RECORDS(v_IDX).BEGIN_DATE + 1/86400;
        v_PSE_ID := GET_PSE(p_RECORDS(v_IDX).ORG_ID, p_RECORDS(v_IDX).ORG_NAME);
        IF v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).BEGIN_DATE, 'MM') THEN
            v_ARR_CREDIT_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE, 'DD'),'FORMULA');
        END IF;

        v_LAST_DATE := TRUNC(v_CHARGE_DATE,'MM');
        v_ZONE := p_RECORDS(v_IDX).CONTROL_AREA;
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

        IF v_IDX = 1 THEN
            SELECT P.PSE_ALIAS INTO v_PSE_ALIAS
            FROM PSE P
            WHERE P.PSE_ID = v_PSE_ID;

            IF p_RECORDS(v_IDX).ZONAL_PEAK_LOAD_MW <> 0 THEN
                v_RATE := p_RECORDS(v_IDX).TARGET_ARR_CREDIT / p_RECORDS(v_IDX).ZONAL_PEAK_LOAD_MW;
            END IF;

            v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM: ' || v_PSE_ALIAS || ':ARR Rate' );
            IF v_MARKET_PRICE_ID IS NULL THEN
                IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
              							p_MARKET_PRICE_NAME => 'PJM ARR Rate:' || v_PSE_ALIAS ,
    									p_MARKET_PRICE_ALIAS =>'PJM ARR Rate:' || v_PSE_ALIAS,
                                		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
    									p_MARKET_PRICE_ID => 0,
                                		p_MARKET_PRICE_TYPE => 'ARR Rate',
    									p_MARKET_PRICE_INTERVAL => 'Day',
                                		p_MARKET_TYPE => '?',
    									p_COMMODITY_ID => 0,
    									p_SERVICE_POINT_TYPE => '?',
                                		p_EXTERNAL_IDENTIFIER => 'PJM: ' || v_PSE_ALIAS || ':ARR Rate',
    									p_EDC_ID => 0,
    									p_SC_ID => g_PJM_SC_ID,
                                		p_POD_ID => 0,
    									p_ZOD_ID => v_ZONE_ID);
            END IF;
        END IF;

    	PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE), v_RATE);

        v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
	    v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
        v_FORMULA_CHARGE.Charge_Id := v_ARR_CREDIT_ID;
        v_FORMULA_CHARGE_VAR.Charge_Id := v_ARR_CREDIT_ID;

        v_FORMULA_CHARGE_VAR.Iterator_Id := 0;
        v_FORMULA_CHARGE_VAR.Variable_Name := 'ZonalPeakLoadMW';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).ZONAL_PEAK_LOAD_MW;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.Variable_Name := 'TargetARRCredit';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).TARGET_ARR_CREDIT;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.Variable_Name := 'DailyARRCredit';
        v_FORMULA_CHARGE_VAR.Variable_Val := p_RECORDS(v_IDX).DAILY_ARR_CREDIT;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.Iterator_Id := 0;
        v_FORMULA_CHARGE.Charge_Quantity := p_RECORDS(v_IDX).ZONAL_PEAK_LOAD_MW;
        v_FORMULA_CHARGE.Charge_Rate := v_RATE;
        v_FORMULA_CHARGE.Charge_Amount := p_RECORDS(v_IDX).DAILY_ARR_CREDIT;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;
    --fill in the market price for the next month as well to estimate the charge for the next month
    v_BEGIN_DATE := FIRST_DAY(p_RECORDS(1).BEGIN_DATE) + NUMTOYMINTERVAL(1, 'MONTH');
    v_END_DATE := LAST_DAY(v_BEGIN_DATE);
    v_DATE := v_BEGIN_DATE;
    WHILE v_DATE <= v_END_DATE LOOP
        PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_DATE, v_RATE);
        v_DATE := v_DATE + 1;
    END LOOP;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_ARR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REACTIVE_SUMMARY
	(
	p_RECORDS IN MEX_PJM_REACTIVE_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE MKT_PRICE_ID_MAP IS TABLE OF NUMBER(9) INDEX BY VARCHAR2(32);
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_REACTIVE_REV_ID_MAP    MKT_PRICE_ID_MAP;
v_ITERATOR_ID_MAP		 	 ITERATOR_ID_MAP;
v_MARKET_PRICE_ID    	 NUMBER(9);
v_REACTIVE_CH_ID         NUMBER(9);
v_REACTIVE_CR_ID         NUMBER(9);
v_ZONE               VARCHAR2(32);
v_CHARGE_AMOUNT      NUMBER;
v_CREDIT_AMOUNT      NUMBER;
v_COMPONENT_ID       NUMBER(9);
v_PSE_ID             NUMBER(9);
v_ZONE_ID			 SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME           VARCHAR2(64);
v_CONTRACT_ID        NUMBER(9);
v_ITERATOR_ID	 NUMBER(3) := 0;
v_TRANSACTION_ID     INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_IDX                BINARY_INTEGER;
v_LAST_ORG_ID        VARCHAR2(16) := '?';
v_LAST_DATE          DATE := LOW_DATE;
v_CHARGE_DATE        DATE := LOW_DATE;
v_FORMULA_CHARGE     FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;


	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
			-- flush charge to formula charge
			IF NOT v_REACTIVE_CH_ID IS NULL THEN
				v_FORMULA_CHARGE.CHARGE_ID       := v_REACTIVE_CH_ID;
				v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
				v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
				v_FORMULA_CHARGE.CHARGE_RATE     := 1;
				v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
				PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
			END IF;
			IF NOT v_REACTIVE_CR_ID IS NULL THEN
				v_FORMULA_CHARGE.CHARGE_ID       := v_REACTIVE_CR_ID;
				v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
				v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CREDIT_AMOUNT;
				v_FORMULA_CHARGE.CHARGE_RATE     := -1;
				v_FORMULA_CHARGE.CHARGE_AMOUNT   := -v_CREDIT_AMOUNT;
				PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
			END IF;
			v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).BEGIN_DATE) + 1 / 86400;
			v_CHARGE_AMOUNT := 0;
			v_CREDIT_AMOUNT := 0;
        --END IF;

        v_ZONE := REPLACE(p_RECORDS(v_IDX).CONTROL_AREA, ' ', '');

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).BEGIN_DATE, 'MM') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).BEGIN_DATE, 'MM');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

            --get contract id
            v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

            ID.ID_FOR_COMMODITY('Transmission',FALSE, v_COMMODITY_ID);

			v_COMPONENT_ID := GET_COMPONENT('PJM-1330');
			v_REACTIVE_CH_ID   := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE,
																			'FORMULA');
			v_COMPONENT_ID := GET_COMPONENT('PJM-2330');
			v_REACTIVE_CR_ID   := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE,
																			'FORMULA');
		END IF;

   		v_ITERATOR_NAME.CHARGE_ID := v_REACTIVE_CH_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_REACTIVE_CH_ID;
       	IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;
		v_ITERATOR.ITERATOR1 := v_ZONE;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


		-- first update the market prices - get IDs from cache
		IF v_REACTIVE_REV_ID_MAP.EXISTS(v_ZONE) THEN
			v_MARKET_PRICE_ID := v_REACTIVE_REV_ID_MAP(v_ZONE);
		ELSE
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE || ':ReactiveTotal');
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM Reactive Rev Req - ' || v_ZONE,
									p_MARKET_PRICE_ALIAS =>'PJM Reactive Rev Req - ' || v_ZONE,
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
									p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'PJM Reactive Rev Req',
									p_MARKET_PRICE_INTERVAL => 'Month',
                            		p_MARKET_TYPE => '?',
									p_COMMODITY_ID => v_COMMODITY_ID, --transmission
									p_SERVICE_POINT_TYPE => '?',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':ReactiveTotal',
									p_EDC_ID => 0,
									p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => 0,
									p_ZOD_ID => v_ZONE_ID);
			END IF;
			v_REACTIVE_REV_ID_MAP(v_ZONE) := v_MARKET_PRICE_ID;
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE),
													 p_RECORDS(v_IDX).TOTAL_ZONAL_REACTIVE_REV_REQ);

		-- next, update formula variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;

		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_REACTIVE_CH_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZonePeakUse';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_ZONE_PK_TRANS_USE;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        --cn get transaction id, update schedule
        v_TRANSACTION_ID := GET_TX_ID('PJM:' || v_ZONE || ':ZnPk',
                                      'Zonal Peak Use',
                                      'PJM Zonal Peak Use: '|| v_ZONE,
                                      'Month',
                                      v_COMMODITY_ID,
                                      0,
                                      v_ZONE_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_FORMULA_CHARGE_VAR.CHARGE_DATE,
                           p_RECORDS(v_IDX).TOTAL_ZONE_PK_TRANS_USE);



        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZoneReactiveRevReq';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_ZONAL_REACTIVE_REV_REQ;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalNonZonePeakUse';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_PJM_NONZONE_PK_TRANS_USE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        --cn get transaction id, update schedule
        v_TRANSACTION_ID := GET_TX_ID('PJMNonZonePeak',
                                      'TtlNZon Peak Use',
                                      'PJM TotNonZonalPeak',
                                      'Month',
                                      v_COMMODITY_ID);


        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_FORMULA_CHARGE_VAR.CHARGE_DATE,
                           p_RECORDS(v_IDX).TOTAL_PJM_NONZONE_PK_TRANS_USE);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalZonalPeakUse';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        --cn get transaction id, update schedule
        v_TRANSACTION_ID := GET_TX_ID('PJMZonePeak',
                                      'TtlZone Peak Use',
                                      v_zone || 'PJM TotZonalPeak',
                                      'Month',
                                      v_COMMODITY_ID,
                                      0,
                                      v_ZONE_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_FORMULA_CHARGE_VAR.CHARGE_DATE,
                           p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE);


        -- intermediate variables for the charge component
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlyZoneTransUse';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_ZONE_PK_TRANS_USE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlyNonZoneTransUse';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_NONZONE_PK_TRANS_USE;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'AdjustmentFactor';
        IF (p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE+p_RECORDS(v_IDX).TOTAL_PJM_NONZONE_PK_TRANS_USE) = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE/
        									(p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE+p_RECORDS(v_IDX).TOTAL_PJM_NONZONE_PK_TRANS_USE);
        END IF;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlyZoneCharge';
        IF p_RECORDS(v_IDX).TOTAL_ZONE_PK_TRANS_USE = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_ZONE_PK_TRANS_USE*p_RECORDS(v_IDX).TOTAL_ZONAL_REACTIVE_REV_REQ*
        									(p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE/
        									(p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE+p_RECORDS(v_IDX).TOTAL_PJM_NONZONE_PK_TRANS_USE))/
                                            p_RECORDS(v_IDX).TOTAL_ZONE_PK_TRANS_USE;
        END IF;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlynNonZoneCharge';
        IF (p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE+p_RECORDS(v_IDX).TOTAL_PJM_NONZONE_PK_TRANS_USE) = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_NONZONE_PK_TRANS_USE/
            									 (p_RECORDS(v_IDX).TOTAL_PJM_ZONE_PK_TRANS_USE+p_RECORDS(v_IDX).TOTAL_PJM_NONZONE_PK_TRANS_USE)*
        									p_RECORDS(v_IDX).TOTAL_ZONAL_REACTIVE_REV_REQ;
        END IF;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MemberCharge';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).CHARGE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_CHARGE_AMOUNT := v_CHARGE_AMOUNT + p_RECORDS(v_IDX).CHARGE;

        -- now update the credit component
        v_FORMULA_CHARGE_VAR.CHARGE_ID := v_REACTIVE_CR_ID;

        v_ITERATOR.CHARGE_ID := v_REACTIVE_CR_ID;
		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);


        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZoneReactiveRevReq';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_ZONAL_REACTIVE_REV_REQ;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_CREDIT_AMOUNT := v_CREDIT_AMOUNT + p_RECORDS(v_IDX).CREDIT;

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;
	-- flush charge to formula charge
	IF NOT v_REACTIVE_CH_ID IS NULL THEN
		v_FORMULA_CHARGE.CHARGE_ID       := v_REACTIVE_CH_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE     := 1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END IF;
	IF NOT v_REACTIVE_CR_ID IS NULL THEN
		v_FORMULA_CHARGE.CHARGE_ID       := v_REACTIVE_CR_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CREDIT_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE     := -1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := -v_CREDIT_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END IF;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;
END IMPORT_REACTIVE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REACTIVE_SERV_SUMMARY
	(
	p_RECORDS IN MEX_PJM_REACTIVE_SERV_SUMM_TBL,
	p_STATUS OUT NUMBER
	) AS
v_IDX BINARY_INTEGER;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_CHARGE_DATE DATE;
v_PSE_ID NUMBER(9);
v_ZONE_ID NUMBER(9);
v_ZONE VARCHAR2(16);
v_LAST_ZONE VARCHAR2(16);
v_COMPONENT_ID NUMBER(9);
v_REACT_SERV_CHG_ID NUMBER(9);
v_RT_LOAD NUMBER := 0;
v_ZONE_RT_LOAD NUMBER := 0;
v_TOTAL_REACT_CREDIT NUMBER := 0;
v_ITERATOR_ID NUMBER(9);
v_MARKET_PRICE_ID NUMBER(9);
v_TRANSACTION_ID NUMBER(9);
v_COMMODITY_ID NUMBER(9);
v_POD_ID NUMBER(9);
BEGIN
    p_STATUS := GA.SUCCESS;
	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
    v_ITERATOR.ITERATOR_ID := 0;
    ID.ID_FOR_COMMODITY('RealTime Energy', FALSE, v_COMMODITY_ID);

    WHILE p_RECORDS.EXISTS(v_IDX) LOOP

        v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).DAY,'MM') + 1/86400;
	    v_PSE_ID := GET_PSE(p_RECORDS(v_IDX).ORG_ID, NULL);
        v_ZONE := p_RECORDS(v_IDX).ZONE;
        v_POD_ID := GET_SERVICE_POINT(v_ZONE);
        IF v_LAST_ZONE IS NULL THEN
            v_LAST_ZONE := v_ZONE;
        END IF;

        v_COMPONENT_ID := GET_COMPONENT('PJM-1378');
        v_REACT_SERV_CHG_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');

        v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
	    v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
        v_FORMULA_CHARGE.Charge_Id := v_REACT_SERV_CHG_ID;
        v_FORMULA_CHARGE_VAR.Charge_Id := v_REACT_SERV_CHG_ID;

        IF v_ZONE <> v_LAST_ZONE THEN
            v_ZONE := v_LAST_ZONE;
            v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_LAST_ZONE);
            v_ITERATOR_NAME.CHARGE_ID := v_REACT_SERV_CHG_ID;
        	v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
        	v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
        	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
        	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
        	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
        	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	    v_ITERATOR.CHARGE_ID := v_REACT_SERV_CHG_ID;
            v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
            v_ITERATOR_ID := v_ITERATOR.Iterator_Id;
            v_ITERATOR.ITERATOR1 := v_LAST_ZONE;
    	    v_ITERATOR.ITERATOR2 := NULL;
    	    v_ITERATOR.ITERATOR3 := NULL;
    	    v_ITERATOR.ITERATOR4 := NULL;
    	    v_ITERATOR.ITERATOR5 := NULL;
            PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

            v_FORMULA_CHARGE_VAR.Iterator_Id := v_ITERATOR_ID;
            v_FORMULA_CHARGE_VAR.Variable_Name := 'RealTimeLoad';
            v_FORMULA_CHARGE_VAR.Variable_Val := v_RT_LOAD;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            v_FORMULA_CHARGE_VAR.Iterator_Id := v_ITERATOR_ID;
            v_FORMULA_CHARGE_VAR.Variable_Name := 'TotalZoneRTLoad';
            v_FORMULA_CHARGE_VAR.Variable_Val := v_ZONE_RT_LOAD;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            v_FORMULA_CHARGE.Iterator_Id := v_ITERATOR_ID;
            IF v_ZONE_RT_LOAD <> 0 THEN
                v_FORMULA_CHARGE.Charge_Quantity := v_RT_LOAD/v_ZONE_RT_LOAD;
            ELSE
                v_FORMULA_CHARGE.Charge_Quantity := 0;
            END IF;
            v_FORMULA_CHARGE.Charge_Rate := v_TOTAL_REACT_CREDIT;
            v_FORMULA_CHARGE.Charge_Amount := v_FORMULA_CHARGE.Charge_Quantity * v_TOTAL_REACT_CREDIT;
            PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

            v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_LAST_ZONE || ':TotalReactServCred:' );
    	    IF v_MARKET_PRICE_ID IS NULL THEN
                IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
              							p_MARKET_PRICE_NAME => 'PJM Total Reactive Services Credit:' || v_LAST_ZONE ,
    									p_MARKET_PRICE_ALIAS =>'PJM Total React Serv Credit' || v_LAST_ZONE,
                                		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
    									p_MARKET_PRICE_ID => 0,
                                		p_MARKET_PRICE_TYPE => 'Reactive Services Credit',
    									p_MARKET_PRICE_INTERVAL => 'Month',
                                		p_MARKET_TYPE => '?',
    									p_COMMODITY_ID => 0,
    									p_SERVICE_POINT_TYPE => '?',
                                		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_LAST_ZONE || ':TotalReactServCred:',
    									p_EDC_ID => 0,
    									p_SC_ID => g_PJM_SC_ID,
                                		p_POD_ID => v_POD_ID,
    									p_ZOD_ID => v_ZONE_ID);
            END IF;

    	    PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE), v_TOTAL_REACT_CREDIT);

            v_TRANSACTION_ID := GET_TX_ID('PJM:TotalLoad:' || v_LAST_ZONE,
                                      'Market Result',
                                      'PJM:TotalLoad:' || v_LAST_ZONE,
                                      'Month',
                                      v_COMMODITY_ID,
                                      0, v_ZONE_ID, v_POD_ID);

            PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                            v_ZONE_RT_LOAD);


            v_RT_LOAD := 0;
            v_ZONE_RT_LOAD := 0;
            v_TOTAL_REACT_CREDIT := 0;


        END IF;
        v_LAST_ZONE := v_ZONE;
        v_RT_LOAD := v_RT_LOAD + p_RECORDS(v_IDX).PARTICIPANT_REAL_TIME_LOAD;
        v_ZONE_RT_LOAD := v_ZONE_RT_LOAD + p_RECORDS(v_IDX).TOTAL_ZONE_REAL_TIME_LOAD;
        v_TOTAL_REACT_CREDIT := v_TOTAL_REACT_CREDIT + p_RECORDS(v_IDX).TOTAL_ZONE_REACTIVE_SERV_CRED;

        v_IDX := p_RECORDS.NEXT(v_IDX);
    END LOOP;


    v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_LAST_ZONE);
    v_ITERATOR_NAME.CHARGE_ID := v_REACT_SERV_CHG_ID;
	v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
	v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
	v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
	PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    v_ITERATOR.CHARGE_ID := v_REACT_SERV_CHG_ID;
    v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
    v_ITERATOR_ID := v_ITERATOR.Iterator_Id;
    v_ITERATOR.ITERATOR1 := v_LAST_ZONE;
    v_ITERATOR.ITERATOR2 := NULL;
    v_ITERATOR.ITERATOR3 := NULL;
    v_ITERATOR.ITERATOR4 := NULL;
    v_ITERATOR.ITERATOR5 := NULL;
    PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

    v_FORMULA_CHARGE_VAR.Iterator_Id := v_ITERATOR_ID;
    v_FORMULA_CHARGE_VAR.Variable_Name := 'RealTimeLoad';
    v_FORMULA_CHARGE_VAR.Variable_Val := v_RT_LOAD;
    PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

    v_FORMULA_CHARGE_VAR.Iterator_Id := v_ITERATOR_ID;
    v_FORMULA_CHARGE_VAR.Variable_Name := 'TotalZoneRTLoad';
    v_FORMULA_CHARGE_VAR.Variable_Val := v_ZONE_RT_LOAD;
    PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

    v_FORMULA_CHARGE.Iterator_Id := v_ITERATOR_ID;
    IF v_ZONE_RT_LOAD <> 0 THEN
        v_FORMULA_CHARGE.Charge_Quantity := v_RT_LOAD/v_ZONE_RT_LOAD;
    ELSE
        v_FORMULA_CHARGE.Charge_Quantity := 0;
    END IF;
    v_FORMULA_CHARGE.Charge_Rate := v_TOTAL_REACT_CREDIT;
    v_FORMULA_CHARGE.Charge_Amount := v_FORMULA_CHARGE.Charge_Quantity * v_TOTAL_REACT_CREDIT;
    PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

    v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_LAST_ZONE || ':TotalReactServCred:' );
    IF v_MARKET_PRICE_ID IS NULL THEN
        IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM Total Reactive Services Credit:' || v_LAST_ZONE ,
    					            p_MARKET_PRICE_ALIAS =>'PJM Total React Serv Credit' || v_LAST_ZONE,
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
    					            p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'Reactive Services Credit',
    					            p_MARKET_PRICE_INTERVAL => 'Month',
                            		p_MARKET_TYPE => '?',
    				            	p_COMMODITY_ID => 0,
    					            p_SERVICE_POINT_TYPE => '?',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_LAST_ZONE || ':TotalReactServCred:',
    					            p_EDC_ID => 0,
    					            p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => v_POD_ID,
    					            p_ZOD_ID => v_ZONE_ID);
    END IF;

    PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE), v_TOTAL_REACT_CREDIT);

    v_TRANSACTION_ID := GET_TX_ID('PJM:TotalLoad:' || v_LAST_ZONE,
                              'Market Result',
                              'PJM:TotalLoad:' || v_LAST_ZONE,
                              'Month',
                              v_COMMODITY_ID,
                              0, v_ZONE_ID,
                              v_POD_ID);

    PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                   v_CHARGE_DATE,
                    v_ZONE_RT_LOAD);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_REACTIVE_SERV_SUMMARY;
-----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REGULATION_SUMMARY
	(
	p_RECORDS IN MEX_PJM_REGULATION_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS

TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_ZONE VARCHAR2(32);
v_CONTRACT_ID NUMBER(9);
v_ITERATOR_ID NUMBER(3) := 0;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_CHARGE_DATE DATE;
v_CHARGE_AMOUNT NUMBER;
v_PSE_ID NUMBER(9);
v_MARKET_PRICE_ID NUMBER(9);
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_LOAD_RATIO NUMBER;
v_REGULATION_CH_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_IDX BINARY_INTEGER;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;

	PROCEDURE FLUSH_TO_FORMULA_CHARGE IS
	BEGIN
		IF NOT v_REGULATION_CH_ID IS NULL THEN
			v_FORMULA_CHARGE.CHARGE_ID := v_REGULATION_CH_ID;
			v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
			v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
			v_FORMULA_CHARGE.CHARGE_RATE := 1;
			v_FORMULA_CHARGE.CHARGE_AMOUNT := v_CHARGE_AMOUNT;
			PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
		END IF;
	END FLUSH_TO_FORMULA_CHARGE;
BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;
    v_COMPONENT_ID := GET_COMPONENT('PJM-1340');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Component_Id := v_COMPONENT_ID;
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_COMPONENT_ID);

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		-- flush charge to formula charge
		FLUSH_TO_FORMULA_CHARGE;

		v_CHARGE_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).HOUR, p_RECORDS(v_IDX).DST_FLAG);
		v_CHARGE_AMOUNT := 0;

		v_ZONE := p_RECORDS(v_IDX).CONTROL_ZONE;

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY, 'DD') THEN
            IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                v_BILLING_STATEMENT.Charge_Quantity :=0;
                v_BILLING_STATEMENT.Charge_Amount := 0;
                v_BILLING_STATEMENT.Bill_Quantity := 0;
                v_BILLING_STATEMENT.Bill_Amount := 0;
            END IF;
			-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'DD');
			v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;

			--get contract id
			v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

			v_REGULATION_CH_ID := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'FORMULA');

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID = v_COMPONENT_ID
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;
		END IF;

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:RegMCP:' || v_ZONE);
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Reg Mkt Clearing Price:' || v_ZONE,
								p_MARKET_PRICE_ALIAS => 'PJM Reg Mkt Clearing Price' || v_ZONE,
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Clearing Price',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:RegMCP:' || v_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
								p_RECORDS(v_IDX).REGULATION_CLEARING_PRICE);

		--if load ratio is null, calculate it
		IF p_RECORDS(v_IDX).LOAD_SHARE_RATIO IS NULL THEN
			IF p_RECORDS(v_IDX).TOTAL_SYSTEM_REG_PURCHASES = 0 THEN
				v_LOAD_RATIO := 0;
			ELSE
				v_LOAD_RATIO :=  p_RECORDS(v_IDX).REGULATION_OBLIGATION /
					p_RECORDS(v_IDX).TOTAL_SYSTEM_REG_PURCHASES;
			END IF;
		ELSE
			v_LOAD_RATIO := p_RECORDS(v_IDX).LOAD_SHARE_RATIO;
		END IF;


		--get transaction id, update schedule
        v_TRANSACTION_ID := GET_TX_ID('PJM:RegLSR:' || v_ZONE,
                                      'Ratio Load Share',
                                      NULL,
                                      'Hour',
                                      0,
                                      v_CONTRACT_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           v_LOAD_RATIO);

		v_TRANSACTION_ID := GET_TX_ID('PJM:RegTotal:' || v_ZONE,
                                      'Market Result');

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).TOTAL_SYSTEM_REG_PURCHASES);

		v_TRANSACTION_ID := GET_TX_ID('PJM:RegOppCost:' || v_ZONE,
                                      'Market Result');

        IF v_LOAD_RATIO = 0 THEN
			PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE, 0);

		ELSE
			PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).OPPORTUNITY_COST_CHARGE /
                           v_LOAD_RATIO);
		END IF;

        ID.ID_FOR_COMMODITY('Regulation',TRUE, v_COMMODITY_ID);

        -- store regulation obligation as txn. This will be needed for SSC&D calc
        v_TRANSACTION_ID := GET_TX_ID('RegulationOblg: ' || v_ZONE,
                                      'Obligation',
                                      NULL,
                                      'Hour',
                                      v_COMMODITY_ID,
                                      v_CONTRACT_ID);

        IF p_RECORDS(v_IDX).TOTAL_SYSTEM_REG_PURCHASES = 0 THEN
        	PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           0);
        ELSE
        	PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).REGULATION_OBLIGATION);
       	END IF;

		v_ITERATOR_NAME.CHARGE_ID := v_REGULATION_CH_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'RegZone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_REGULATION_CH_ID;
		IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
			v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
			v_ITERATOR_ID := v_ITERATOR_ID + 1;
		END IF;
		v_ITERATOR.ITERATOR1 := v_ZONE;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


		-- next, update formula variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_REGULATION_CH_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RMCP';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).REGULATION_CLEARING_PRICE;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'LoadShareRatio';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := v_LOAD_RATIO;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RegObl';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).REGULATION_OBLIGATION;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'BilatPurchases';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).BILATERAL_REG_PURCHASES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'BilatSales';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).BILATERAL_REG_SALES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'RegCharge';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).CHARGE;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TotalAssignments';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOTAL_SYSTEM_REG_PURCHASES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'OppCostCharge';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).OPPORTUNITY_COST_CHARGE;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TotalOppCost';
		IF v_LOAD_RATIO = 0 THEN
			v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := 0;
		ELSE
			v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).OPPORTUNITY_COST_CHARGE / v_LOAD_RATIO;
		END IF;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_CHARGE_AMOUNT := p_RECORDS(v_IDX).OPPORTUNITY_COST_CHARGE + p_RECORDS(v_IDX).CHARGE;

        v_BILLING_STATEMENT.CHARGE_Id := v_REGULATION_CH_ID;
        v_BILLING_STATEMENT.Charge_Quantity := NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + NVL(v_CHARGE_AMOUNT,0);
        v_BILLING_STATEMENT.Charge_Rate := 1;
        v_BILLING_STATEMENT.Charge_Amount := NVL(v_BILLING_STATEMENT.Charge_Amount,0) + NVL(v_CHARGE_AMOUNT,0);
        v_BILLING_STATEMENT.Bill_Quantity := NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + NVL(v_CHARGE_AMOUNT,0);
        v_BILLING_STATEMENT.Bill_Amount := NVL(v_BILLING_STATEMENT.Bill_Amount,0) + NVL(v_CHARGE_AMOUNT,0);

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	-- flush charge to formula charge
	FLUSH_TO_FORMULA_CHARGE;
    v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
    v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
    PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;
END IMPORT_REGULATION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FTR_TARGET_ALLOCATION
(
    p_WORK_ID IN NUMBER,
    p_STATUS  OUT NUMBER
) AS

    v_SOMETHING_DONE     BOOLEAN := FALSE;
    v_DATE               DATE;
    v_LAST_ORG_IDENT     VARCHAR2(32) := '?';
    v_LAST_DATE          DATE := LOW_DATE;
    v_PSE_ID             NUMBER(9);
    v_CONTRACT_ID        NUMBER(9);
    v_COMPONENT_ID       NUMBER(9);
    v_CONG_CR_FTR_ID     NUMBER(9);
    v_CONG_CR_ID         NUMBER(9);
    v_FTR_CHARGE         FTR_CHARGE%ROWTYPE;
    v_ALLOC_FACTOR_TX_ID NUMBER(9);
    v_ALLOC_FACTOR       NUMBER;
    v_PSE_NAME           VARCHAR2(32);

    CURSOR c_ALLOC IS
        SELECT A.ORG_IDENT,
               A.DAY,
               A.HOUR,
               A.SINK_NAME,
               A.SOURCE_NAME,
               A.HEDGE_TYPE,
               SUM(A.FTR_MW) "FTR_MW",
               MAX(A.SINK_LMP) "SINK_LMP",
               MAX(A.SOURCE_LMP) "SOURCE_LMP",
               SUM(CASE
                        WHEN MAX(SINK_LMP) > MAX(SOURCE_LMP) THEN
                         (MAX(SINK_LMP) - MAX(SOURCE_LMP)) * SUM(FTR_MW)
                        ELSE
                         0
                    END) OVER(PARTITION BY ORG_IDENT, DAY, HOUR) "POS_ALLOC",
               SUM(CASE
                        WHEN MAX(SINK_LMP) < MAX(SOURCE_LMP) THEN
                         (MAX(SINK_LMP) - MAX(SOURCE_LMP)) * SUM(FTR_MW)
                        ELSE
                         0
                    END) OVER(PARTITION BY ORG_IDENT, DAY, HOUR) "NEG_ALLOC"
        FROM MEX_PJM_FTR_ALLOC_WORK A
        WHERE A.WORK_ID = p_WORK_ID
        GROUP BY A.ORG_IDENT,
                 A.DAY,
                 A.HOUR,
                 A.SINK_NAME,
                 A.SOURCE_NAME,
                 A.HEDGE_TYPE
        ORDER BY ORG_IDENT, DAY, HOUR;

    PROCEDURE UPDATE_COMBINATION_CHARGES IS
    BEGIN
        --Roll all the values up the combination tree.
        IF NOT v_CONG_CR_ID IS NULL THEN
            UPDATE_COMBINATION_CHARGE(v_CONG_CR_ID, v_CONG_CR_FTR_ID, 'FTR');
        END IF;
    END;

BEGIN
    p_STATUS := GA.SUCCESS;

    FOR v_ALLOC IN c_ALLOC LOOP
        v_SOMETHING_DONE := TRUE;

        IF v_LAST_ORG_IDENT <> v_ALLOC.ORG_IDENT OR
           v_LAST_DATE <> TRUNC(v_ALLOC.DAY, 'DD') THEN
            -- flush last month's charges to combination charge table
            --cgn combination charge is already updated via congestion summary import
            --UPDATE_COMBINATION_CHARGES;

            -- get charge IDs
            v_LAST_ORG_IDENT := v_ALLOC.ORG_IDENT;
            v_LAST_DATE      := TRUNC(v_ALLOC.DAY, 'DD');
            v_PSE_ID         := GET_PSE(v_LAST_ORG_IDENT, NULL);
            SELECT PSE_ALIAS INTO v_PSE_NAME FROM PURCHASING_SELLING_ENTITY
             WHERE PSE_ID = v_PSE_ID;

            --get contract id
            v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

			v_COMPONENT_ID := GET_COMPONENT('PJM-2210');
			v_CONG_CR_ID := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'COMBINATION');
			IF v_LAST_DATE >= g_MARGINAL_LOSS_DATE THEN
            v_COMPONENT_ID := GET_COMPONENT('PJM:TransCongCred:FTR');
            ELSE
                v_COMPONENT_ID := GET_COMPONENT('PJM:TxCongCred:FTR');
            END IF;
			v_CONG_CR_FTR_ID := GET_COMBO_CHARGE_ID(v_CONG_CR_ID, v_COMPONENT_ID, v_LAST_DATE, 'FTR', TRUE);

            v_ALLOC_FACTOR_TX_ID := GET_TX_ID('FTR Alloc Factor: ' || v_PSE_NAME,
                                              'FTR Alloc Factor',
                                              'FTR Alloc Factor',
                                              'Hour',
                                              0,
                                              v_CONTRACT_ID,
                                              0,
                                              0,
                                              0,
                                              v_PSE_ID);
        END IF;

        -- Use Hour 25 for the DST extra hour.
        v_DATE := GET_CHARGE_DATE(v_ALLOC.DAY, v_ALLOC.HOUR, 0);

        -- Populate the FTR Charge record.
        v_FTR_CHARGE.CHARGE_ID         := v_CONG_CR_FTR_ID;
        v_FTR_CHARGE.CHARGE_DATE       := v_DATE;
        v_FTR_CHARGE.SOURCE_ID         := GET_SERVICE_POINT(v_ALLOC.SOURCE_NAME);
        v_FTR_CHARGE.DELIVERY_POINT_ID := 0;
        v_FTR_CHARGE.SINK_ID           := GET_SERVICE_POINT(v_ALLOC.SINK_NAME);
        v_FTR_CHARGE.FTR_TYPE          := v_ALLOC.HEDGE_TYPE;
        v_FTR_CHARGE.PURCHASES         := v_ALLOC.FTR_MW;
        v_FTR_CHARGE.PRICE1            := v_ALLOC.SINK_LMP;
        v_FTR_CHARGE.PRICE2            := v_ALLOC.SOURCE_LMP;

        BEGIN
            SELECT S.AMOUNT
            INTO v_ALLOC_FACTOR
            FROM IT_SCHEDULE S
            WHERE S.TRANSACTION_ID = v_ALLOC_FACTOR_TX_ID
            AND S.SCHEDULE_DATE = v_DATE
            AND S.SCHEDULE_STATE = 1
            AND S.SCHEDULE_TYPE = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_ALLOC_FACTOR := 0;
        END;
        /*   --Calculate the PJM-wide Allocation Factor.
        IF v_ALLOC.POS_ALLOC = 0 THEN
            --If it is null, do not save it to the schedule.
            v_ALLOC_FACTOR := 1;
        ELSE
            BEGIN
            --Get the congestion credit value we cached from the congestion summary import.
            SELECT WORK_DATA INTO v_FTR_CONG_CRED FROM RTO_WORK
            WHERE WORK_ID = g_FTR_CONG_CRED_WK_ID
                AND WORK_XID = v_PSE_ID
                AND WORK_DATE = v_DATE;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_FTR_CONG_CRED := 0;
            END;

            --Calculate the allocation factor and save it to the schedule.
            v_ALLOC_FACTOR := (v_FTR_CONG_CRED - v_ALLOC.NEG_ALLOC)/v_ALLOC.POS_ALLOC;
            PUT_SCHEDULE_VALUE(v_ALLOC_FACTOR_TX_ID, v_DATE, v_ALLOC_FACTOR, NULL, TRUE);
        END IF;*/

        --Finish the FTR Charge.
        v_FTR_CHARGE.ALLOC_FACTOR := v_ALLOC_FACTOR;
        --v_FTR_CHARGE.CHARGE_QUANTITY := v_FTR_CHARGE.PURCHASES * v_ALLOC_FACTOR;
        v_FTR_CHARGE.CHARGE_RATE     := v_FTR_CHARGE.PRICE1 -  v_FTR_CHARGE.PRICE2;
        v_FTR_CHARGE.CHARGE_QUANTITY := v_FTR_CHARGE.PURCHASES * v_FTR_CHARGE.CHARGE_RATE;
        v_FTR_CHARGE.CHARGE_RATE     := v_ALLOC_FACTOR;
        v_FTR_CHARGE.CHARGE_AMOUNT   := v_FTR_CHARGE.CHARGE_QUANTITY * v_FTR_CHARGE.CHARGE_RATE;

        PC.PUT_FTR_CHARGE(v_FTR_CHARGE);

    END LOOP;

    -- flush last month's charges to combination charge table
    --UPDATE_COMBINATION_CHARGES;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        COMMIT;
    END IF;

    --Clean up the work table.
    DELETE MEX_PJM_FTR_ALLOC_WORK
    WHERE WORK_ID = p_WORK_ID;

EXCEPTION
    WHEN OTHERS THEN
        DELETE MEX_PJM_FTR_ALLOC_WORK
        WHERE WORK_ID = p_WORK_ID;
        RAISE;

END IMPORT_FTR_TARGET_ALLOCATION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1A_SUMMARY
	(
	p_RECORDS IN MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_MARKET_PRICE_ID NUMBER(9);
v_TO_SSCD_CH_ID NUMBER(9);
v_TO_SSCD_CH_ID_NW NUMBER(9);
v_TO_SSCD_CH_ID_P2P NUMBER(9);
v_ZONE VARCHAR2(32);
v_CHARGE_AMOUNT NUMBER;
v_CREDIT_AMOUNT NUMBER;
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ZONE_ID SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME VARCHAR2(64);
v_ITERATOR_ID NUMBER(3) := 0;
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP

        v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).MONTH) + 1 / 86400;
        v_CHARGE_AMOUNT := 0;
        v_CREDIT_AMOUNT := 0;

        v_ZONE := REPLACE(p_RECORDS(v_IDX).ZONE, ' ', '');

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).MONTH, 'MM') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).MONTH, 'MM');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

            ID.ID_FOR_COMMODITY('Transmission',FALSE, v_COMMODITY_ID);

			v_COMPONENT_ID := GET_COMPONENT('PJM-1320');
    		--v_TO_SSCD_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');
            v_TO_SSCD_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'COMBINATION');

			v_COMPONENT_ID := GET_COMPONENT('PJM:TOSSC&DChg:Nw');
			v_TO_SSCD_CH_ID_NW := GET_COMBO_CHARGE_ID(v_TO_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');

			v_COMPONENT_ID := GET_COMPONENT('PJM:TOSSC&DChg:P2P');
			v_TO_SSCD_CH_ID_P2P := GET_COMBO_CHARGE_ID(v_TO_SSCD_CH_ID,v_COMPONENT_ID,TRUNC(v_CHARGE_DATE),'FORMULA');


		END IF;

        --if zone is NOT PJM, then this is not P2P but part of the Network charge
        IF v_ZONE <> 'PJM' THEN

            v_ITERATOR_NAME.CHARGE_ID := v_TO_SSCD_CH_ID_NW;
    		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
    		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
    		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
    		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
    		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
    		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    		v_ITERATOR.CHARGE_ID := v_TO_SSCD_CH_ID_NW;
            IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
				v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
			ELSE
				v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
				v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
				v_ITERATOR_ID := v_ITERATOR_ID + 1;
        	END IF;

    		v_ITERATOR.ITERATOR1 := v_ZONE;
    		v_ITERATOR.ITERATOR2 := NULL;
    		v_ITERATOR.ITERATOR3 := NULL;
    		v_ITERATOR.ITERATOR4 := NULL;
    		v_ITERATOR.ITERATOR5 := NULL;
            PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

            v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
            v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


			-- first update the zonal rate market price
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE || ':TOSSCDRate');
            IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM TO SSCD Rate - ' || v_ZONE,
									p_MARKET_PRICE_ALIAS =>'PJM TO SSCD Rate - ' || v_ZONE,
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
									p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'PJM TO SSCD Rate',
									p_MARKET_PRICE_INTERVAL => 'Month',
                            		p_MARKET_TYPE => MM_PJM_UTIL.g_REALTIME,
									p_COMMODITY_ID => v_COMMODITY_ID, --transmission
									p_SERVICE_POINT_TYPE => '?',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':TOSSCDRate',
									p_EDC_ID => 0,
									p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => 0,
									p_ZOD_ID => v_ZONE_ID);
			END IF;
			PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE),
									p_RECORDS(v_IDX).RATE);

    		-- next, update formula variables
    		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
    		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_TO_SSCD_CH_ID_NW;
            v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZonalRate';
            v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RATE;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
			v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZoneLoad';
    		v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).LOAD;
    		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            v_FORMULA_CHARGE.CHARGE_ID       := v_TO_SSCD_CH_ID_NW;
            v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
            v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).LOAD;
            v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
            v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).LOAD * p_RECORDS(v_IDX).RATE;
            PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

    	ELSE
        	-- if PJM zone then its the P2P Charge
        	v_FORMULA_CHARGE.CHARGE_ID := v_TO_SSCD_CH_ID_P2P;
            v_FORMULA_CHARGE.ITERATOR_ID := 0;
            v_FORMULA_CHARGE_VAR.ITERATOR_ID := 0;

            v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;

            v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
    		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_TO_SSCD_CH_ID_P2P;
            v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'P2PPoolRate';
            v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RATE;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'P2PUsage';
            v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).P2P_TRANSMISSION_USE;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            --TO DO create the pool rate if it doesn't exist
            -- first update P2P pool-wide market price
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:P2P:PoolRate');
            IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM P2P Transmission Pool-Wide Rate',
									p_MARKET_PRICE_ALIAS =>'PJM P2P Transmission Pool Rate',
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
									p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'User Defined',
									p_MARKET_PRICE_INTERVAL => 'Month',
                            		p_MARKET_TYPE => MM_PJM_UTIL.g_REALTIME,
									p_COMMODITY_ID => v_COMMODITY_ID, --transmission
									p_SERVICE_POINT_TYPE => 'Point',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:P2P:PoolRate',
									p_EDC_ID => 0,
									p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => 0,
									p_ZOD_ID => v_ZONE_ID);
			END IF;
			PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE),
									p_RECORDS(v_IDX).RATE);

            v_FORMULA_CHARGE.CHARGE_ID       := v_TO_SSCD_CH_ID_P2P;
            v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
            v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).P2P_TRANSMISSION_USE;
            v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
            v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).P2P_TRANSMISSION_USE * p_RECORDS(v_IDX).RATE;
            PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        END IF;
        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	UPDATE_COMBINATION_CHARGE(v_TO_SSCD_CH_ID,v_TO_SSCD_CH_ID_NW,'FORMULA');
    UPDATE_COMBINATION_CHARGE(v_TO_SSCD_CH_ID,v_TO_SSCD_CH_ID_P2P,'FORMULA');

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_SCHEDULE1A_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FIRM_TRANS_SERV_CHARGES
	(
	p_RECORDS IN MEX_PJM_TRANS_SERV_CHARGES_TBL,
    p_ISO_NAME      IN VARCHAR2,
	p_STATUS OUT NUMBER
	) AS
v_IDX BINARY_INTEGER;
v_PSE_NAME VARCHAR2(16);
v_PSE_ID NUMBER(9);
v_CONTRACT_ID NUMBER(9);
v_FM_TRANS_CH_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_CHARGE_AMOUNT NUMBER := 0;
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;

BEGIN
  	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
    v_ITERATOR.ITERATOR_ID := 0;


    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
   		IF v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).CHARGE_DATE, 'MM') THEN

            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).CHARGE_DATE, 'MM');

			IF p_ISO_NAME IS NULL THEN
            	--get billing entity from the org_name
                IF INSTR(p_RECORDS(v_IDX).ORG_NAME, 'PPL') > 0 THEN
                	v_PSE_NAME := 'AMPPPL';
                ELSIF INSTR(p_RECORDS(v_IDX).ORG_NAME, 'PTP') > 0 THEN
                	v_PSE_NAME := 'AMPPTP';
                ELSIF INSTR(p_RECORDS(v_IDX).ORG_NAME, 'PIQ') > 0 THEN
                	v_PSE_NAME := 'AMPPIQ';
                ELSIF INSTR(p_RECORDS(v_IDX).ORG_NAME, 'DAY') > 0 THEN
                	v_PSE_NAME := 'AMPDAY';
                ELSIF INSTR(p_RECORDS(v_IDX).ORG_NAME, 'GPU') > 0 THEN
                	v_PSE_NAME := 'AMPGPU';
                ELSIF INSTR(p_RECORDS(v_IDX).ORG_NAME, 'CEL') > 0 THEN
                	v_PSE_NAME := 'AMPCEL';
                ELSIF INSTR(p_RECORDS(v_IDX).ORG_NAME, 'COL') > 0 THEN
                	v_PSE_NAME := 'AMPCOL';
                ELSE v_PSE_NAME := 'AMPO';
            	END IF;
                SELECT PSE_ID INTO v_PSE_ID FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ALIAS = v_PSE_NAME;
                v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
            ELSE
            	--get billing entity from external credential
                v_CONTRACT_ID := ID_FOR_PJM_CONTRACT(p_ISO_NAME);
                SELECT BILLING_ENTITY_ID INTO v_PSE_ID
                FROM INTERCHANGE_CONTRACT
                WHERE CONTRACT_ALIAS = p_ISO_NAME;
            END IF;

            v_COMPONENT_ID := GET_COMPONENT('PJM-1130');
            v_FM_TRANS_CH_ID := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE,
										'FORMULA');
		END IF;

        BEGIN
        	SELECT TRANSACTION_NAME INTO v_TRANSACTION_NAME
            FROM INTERCHANGE_TRANSACTION
            WHERE TRANSACTION_IDENTIFIER = TO_CHAR(p_RECORDS(v_IDX).OASIS_NUM);
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
            	v_TRANSACTION_NAME := '';
        END;

		v_ITERATOR_NAME.CHARGE_ID := v_FM_TRANS_CH_ID;
        v_ITERATOR_NAME.ITERATOR_NAME1 := 'Transaction';
		v_ITERATOR_NAME.ITERATOR_NAME2 := 'OasisNumber';
		v_ITERATOR_NAME.ITERATOR_NAME3 := 'Begin_Date';
		v_ITERATOR_NAME.ITERATOR_NAME4 := 'End_Date';
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

        v_ITERATOR.CHARGE_ID := v_FM_TRANS_CH_ID;
        v_ITERATOR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID + 1;
        IF v_TRANSACTION_NAME IS NULL THEN
            v_ITERATOR.ITERATOR1 := p_RECORDS(v_IDX).OASIS_NUM;
        ELSE
            v_ITERATOR.ITERATOR1 := v_TRANSACTION_NAME;

        END IF;
		v_ITERATOR.ITERATOR2 := p_RECORDS(v_IDX).OASIS_NUM;
		v_ITERATOR.ITERATOR3 := p_RECORDS(v_IDX).BEGIN_DATE;
		v_ITERATOR.ITERATOR4 := p_RECORDS(v_IDX).END_DATE;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


        v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).CHARGE_DATE) + 1 / 86400;

        -- next, update formula variables
        v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
        v_FORMULA_CHARGE_VAR.CHARGE_ID := v_FM_TRANS_CH_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'FirmP2PTxnRate';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RATE;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReservationMW';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RES_AMT_MW;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_CHARGE_AMOUNT := p_RECORDS(v_IDX).CHARGE;

    	v_FORMULA_CHARGE.CHARGE_ID       := v_FM_TRANS_CH_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE     := 1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

    	v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;


  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_FIRM_TRANS_SERV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NON_FM_TRANS_SV_CHARGES
	(
	p_RECORDS IN MEX_PJM_NFIRM_TRANS_SV_CHG_TBL,
	p_STATUS OUT NUMBER
	) AS
v_IDX BINARY_INTEGER;
v_PSE_ID NUMBER(9);
v_NFM_TRANS_CH_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_CHARGE_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;

BEGIN
  	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN RETURN; END IF; -- nothing to do

    v_IDX := p_RECORDS.FIRST;
    v_ITERATOR.ITERATOR_ID := 0;


	v_COMPONENT_ID := GET_COMPONENT('PJM-1140');

    WHILE p_RECORDS.EXISTS(v_IDX) LOOP

    	v_PSE_ID := GET_PSE(p_RECORDS(v_IDX).ORG_ID, NULL);
        v_NFM_TRANS_CH_ID := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID,
        						TRUNC(p_RECORDS(v_IDX).CHARGE_DATE, 'MM'),
								'FORMULA');

        BEGIN
        	SELECT TRANSACTION_NAME INTO v_TRANSACTION_NAME
    		FROM INTERCHANGE_TRANSACTION
    		WHERE TRANSACTION_IDENTIFIER = TO_CHAR(p_RECORDS(v_IDX).OASIS_NUM);
    	EXCEPTION
            	WHEN NO_DATA_FOUND THEN
                	v_TRANSACTION_NAME := '';
    	END;

        --loop through each hour of data
        FOR I IN 1..25 LOOP

			IF p_RECORDS(v_IDX).RES_CAPACITY.EXISTS(I) THEN
            	v_CHARGE_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).CHARGE_DATE,
								I, NULL);

            	v_ITERATOR_NAME.CHARGE_ID := v_NFM_TRANS_CH_ID;
                v_ITERATOR_NAME.ITERATOR_NAME1 := 'Transaction';
        		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
        		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
        		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
        		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
        		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

                v_ITERATOR.CHARGE_ID := v_NFM_TRANS_CH_ID;
                v_ITERATOR.ITERATOR_ID :=  v_ITERATOR.ITERATOR_ID + 1;
        		IF v_TRANSACTION_NAME IS NULL THEN
            		v_ITERATOR.ITERATOR1 := p_RECORDS(v_IDX).OASIS_NUM;
        		ELSE
            		v_ITERATOR.ITERATOR1 := v_TRANSACTION_NAME;

        		END IF;
				v_ITERATOR.ITERATOR2 := NULL;
				v_ITERATOR.ITERATOR3 := NULL;
				v_ITERATOR.ITERATOR4 := NULL;
				v_ITERATOR.ITERATOR5 := NULL;
        		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


                -- next, update formula variables
                v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
                v_FORMULA_CHARGE_VAR.CHARGE_ID := v_NFM_TRANS_CH_ID;

       			v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReservedCapacity';
    			v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RES_CAPACITY(I).QUANTITY;
    			PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

				v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'BilledCapacity';
    			v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).BILLABLE_CAPACITY(I).QUANTITY;
    			PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'HourlyRate';
    			v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RATE;
    			PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

				v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'CongestionAdj';
    			v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).CONGESTION_ADJ(I).QUANTITY;
    			PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TransServiceCharge';
    			v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).CHARGE(I).QUANTITY - p_RECORDS(v_IDX).CONGESTION_ADJ(I).QUANTITY;
    			PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

    			v_FORMULA_CHARGE.CHARGE_ID := v_NFM_TRANS_CH_ID;
				v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
				v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).CHARGE(I).QUANTITY;
				v_FORMULA_CHARGE.CHARGE_RATE := 1;
				v_FORMULA_CHARGE.CHARGE_AMOUNT := p_RECORDS(v_IDX).CHARGE(I).QUANTITY;
				PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
			END IF;
    	END LOOP;
        v_IDX := p_RECORDS.NEXT(v_IDX);
    END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    	COMMIT;
  	END IF;
END IMPORT_NON_FM_TRANS_SV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPIN_RES_SUMMARY
	(
	p_RECORDS IN MEX_PJM_SPIN_RES_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(64);
v_SPIN_RES_CH_ID NUMBER(9);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_CONTRACT_ID NUMBER(9);
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE;
v_PSE_NAME VARCHAR2(64);
v_SPIN_RES_ZONE VARCHAR2(64);
v_MARKET_PRICE_ID NUMBER(9);
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
v_BILLING_STATEMENT BILLING_STATEMENT%ROWTYPE;
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_ITERATOR_ID NUMBER(3) := 0;


BEGIN
	p_STATUS := GA.SUCCESS;
	v_IDX := p_RECORDS.FIRST;
    v_ITERATOR.ITERATOR_ID := 0;
    v_COMPONENT_ID := GET_COMPONENT('PJM-1360');
    v_BILLING_STATEMENT.Entity_Type := 'PSE';
    v_BILLING_STATEMENT.STATEMENT_TYPE := g_STATEMENT_TYPE;
	v_BILLING_STATEMENT.STATEMENT_STATE := GA.EXTERNAL_STATE;
    v_BILLING_STATEMENT.AS_OF_DATE := LOW_DATE;
    v_BILLING_STATEMENT.Charge_View_Type := 'FORMULA';
    v_BILLING_STATEMENT.Component_Id := v_COMPONENT_ID;
    v_BILLING_STATEMENT.Product_Id := GET_PRODUCT(v_COMPONENT_ID);


	ID.ID_FOR_COMMODITY('Spinning Reserve',FALSE, v_COMMODITY_ID);


	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX).ORG_ID OR
		   v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).BEGIN_DATE,'DD') THEN
           IF v_LAST_DATE <> LOW_DATE THEN
                v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
                v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
                PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
                v_BILLING_STATEMENT.Charge_Quantity :=0;
                v_BILLING_STATEMENT.Charge_Amount := 0;
                v_BILLING_STATEMENT.Bill_Quantity := 0;
                v_BILLING_STATEMENT.Bill_Amount := 0;
           END IF;
		   	-- get charge IDs
			v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
			v_LAST_DATE := TRUNC(p_RECORDS(v_IDX).BEGIN_DATE,'DD');
			v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);
            v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
            v_BILLING_STATEMENT.Entity_Id := v_PSE_ID;

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

			v_SPIN_RES_CH_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula');

            DELETE BILLING_STATEMENT WHERE ENTITY_ID = v_PSE_ID AND COMPONENT_ID = v_COMPONENT_ID
            AND STATEMENT_TYPE = g_STATEMENT_TYPE AND STATEMENT_STATE = g_EXTERNAL_STATE
            AND STATEMENT_DATE = v_LAST_DATE;
		END IF;

        IF p_RECORDS(v_IDX).RESERVE_ZONE IS NULL THEN
        	v_SPIN_RES_ZONE := p_RECORDS(v_IDX).SPINNING_RESERVE_ZONE;
        ELSE
            v_SPIN_RES_ZONE := p_RECORDS(v_IDX).SPINNING_RESERVE_ZONE ||
										':' || p_RECORDS(v_IDX).RESERVE_ZONE;
		END IF;

		-- put the data
		v_CHARGE_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).BEGIN_DATE,
        									p_RECORDS(v_IDX).HOUR_ENDING,
                                            p_RECORDS(v_IDX).DST_FLAG);

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:SpinResMCP:' || v_SPIN_RES_ZONE);
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM:SpinResMCP:' || v_SPIN_RES_ZONE ,
								p_MARKET_PRICE_ALIAS => 'PJM Spinning Reserve Mkt Clearing Price',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Clearing Price',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:SpinResMCP:' || v_SPIN_RES_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
			END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE, p_RECORDS(v_IDX).SRMCP);

        IF p_RECORDS(v_IDX).MEMBER_TIER1_ALLOC_TO_OBLIG <> 0 THEN
        	v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:SpinResTier1Total:' || v_SPIN_RES_ZONE);
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM SpinRes Tier1 Total' || v_SPIN_RES_ZONE ,
								p_MARKET_PRICE_ALIAS => 'PJM Spinning Reserve Tier1 Total',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Result',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:SpinResTier1Total:' || v_SPIN_RES_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
			END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
									(p_RECORDS(v_IDX).TOTAL_TIER1_ALLOC_TO_OBLIG * p_RECORDS(v_IDX).TIER1_CHARGE)
        							/ p_RECORDS(v_IDX).MEMBER_TIER1_ALLOC_TO_OBLIG);
		END IF;


        IF	p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES <> 0 AND
        	(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        										p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES) <> 0 THEN

        	v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:SpinResOppCost:' || v_SPIN_RES_ZONE);
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM SpinRes Opp Cost' || v_SPIN_RES_ZONE ,
								p_MARKET_PRICE_ALIAS => 'PJM Spinning Reserve Opp Cost',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:SpinResOppCost:' || v_SPIN_RES_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
			END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
									p_RECORDS(v_IDX).OPP_COST_CHARGE_CLEARED /
        								(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        								p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES));
        END IF;

		IF	p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES <> 0 AND
        	(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        										p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES) <> 0 THEN
        	v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:SpinResOppCostAdd:' || v_SPIN_RES_ZONE);
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM SpinRes Opp Cost Added'|| v_SPIN_RES_ZONE,
								p_MARKET_PRICE_ALIAS => 'PJM Spinning Reserve Opportunity Cost Added',
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'User Defined',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => v_COMMODITY_ID,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:SpinResOppCostAdd:'|| v_SPIN_RES_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => 0);
			END IF;
			PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_CHARGE_DATE,
									p_RECORDS(v_IDX).OPP_COST_CHARGE_ADDED /
        								(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        									p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES));
    	END IF;


        v_TRANSACTION_ID := GET_TX_ID('PJM:SpinResLSR:' || v_SPIN_RES_ZONE,
                                      'Market Result',
                                      SUBSTR('PJM SpinRes LoadShareRatio'|| v_SPIN_RES_ZONE, 1,51),
                                      'Hour',
                                      v_COMMODITY_ID,
                                      v_CONTRACT_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).REAL_TIME_LOAD_RATIO);

        IF p_RECORDS(v_IDX).REAL_TIME_LOAD_RATIO <> 0 THEN
        	v_TRANSACTION_ID := GET_TX_ID('PJM:SpinResTotal:' || v_SPIN_RES_ZONE,
                                      'Market Result',
                                      SUBSTR('PJM SpinRes Total' || v_SPIN_RES_ZONE, 1,51),
                                      'Hour',
                                      v_COMMODITY_ID);

        	PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           		v_CHARGE_DATE,
                           		p_RECORDS(v_IDX).SPIN_OBLIGATION /
                                p_RECORDS(v_IDX).REAL_TIME_LOAD_RATIO);
		END IF;

        v_TRANSACTION_ID := GET_TX_ID('PJM:SpinResTier1:' || v_SPIN_RES_ZONE,
                                      'Market Result',
                                      SUBSTR('PJM Tier1 Alloc to Obligation:' || v_SPIN_RES_ZONE, 1,51),
                                      'Hour',
                                      v_COMMODITY_ID,
                                      v_CONTRACT_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_CHARGE_DATE,
                           p_RECORDS(v_IDX).MEMBER_TIER1_ALLOC_TO_OBLIG);

        v_TRANSACTION_ID := GET_TX_ID('PJM:SpinResTier1Total:' || v_SPIN_RES_ZONE,
                                      'Market Result',
                                      SUBSTR('PJM Total Tier1 Allocation to Obligation' || v_SPIN_RES_ZONE, 1,51),
                                      'Hour',
                                      v_COMMODITY_ID);

		PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           		v_CHARGE_DATE,
                           		p_RECORDS(v_IDX).TOTAL_TIER1_ALLOC_TO_OBLIG);

		v_TRANSACTION_ID := GET_TX_ID('PJM:SpinResTier2Total:' || v_SPIN_RES_ZONE,
                                      'Market Result',
                                      SUBSTR('PJM Spinning Reserve Tier2 Total' || v_SPIN_RES_ZONE, 1,51),
                                      'Hour',
                                      v_COMMODITY_ID);

		PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           		v_CHARGE_DATE,
                           		p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES);

		v_ITERATOR_NAME.CHARGE_ID := v_SPIN_RES_CH_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'SpinResZone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_SPIN_RES_CH_ID;
		IF v_ITERATOR_ID_MAP.EXISTS(v_SPIN_RES_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_SPIN_RES_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
			v_ITERATOR_ID_MAP(v_SPIN_RES_ZONE) := v_ITERATOR.ITERATOR_ID;
			v_ITERATOR_ID := v_ITERATOR_ID + 1;
		END IF;

        v_ITERATOR.ITERATOR1 := v_SPIN_RES_ZONE;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


		v_FORMULA_CHARGE.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_FACTOR := 1.0;
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;

		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SPIN_RES_CH_ID;
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SRMCP';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).SRMCP;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'LoadRatioShare';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).REAL_TIME_LOAD_RATIO;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TotalSpinAssignments';
		IF p_RECORDS(v_IDX).REAL_TIME_LOAD_RATIO = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).SPIN_OBLIGATION / p_RECORDS(v_IDX).REAL_TIME_LOAD_RATIO;
        END IF;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SpinObl';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).SPIN_OBLIGATION;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'BilatPurchases';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).BILATERAL_SPIN_PURCHASES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'BilatSales';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).BILATERAL_SPIN_SALES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier1AllocMWH';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).MEMBER_TIER1_ALLOC_TO_OBLIG;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier1TotalMWH';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).TOTAL_TIER1_ALLOC_TO_OBLIG;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier1TotalCredits';
		IF p_RECORDS(v_IDX).MEMBER_TIER1_ALLOC_TO_OBLIG = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := (p_RECORDS(v_IDX).TOTAL_TIER1_ALLOC_TO_OBLIG * p_RECORDS(v_IDX).TIER1_CHARGE)
        										/ p_RECORDS(v_IDX).MEMBER_TIER1_ALLOC_TO_OBLIG;
		END IF;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier1Ratio';
		IF p_RECORDS(v_IDX).TOTAL_TIER1_ALLOC_TO_OBLIG = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).MEMBER_TIER1_ALLOC_TO_OBLIG /
        										p_RECORDS(v_IDX).TOTAL_TIER1_ALLOC_TO_OBLIG;
		END IF;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier1Charge';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).TIER1_CHARGE;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier2MWH';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier2TotalMWH';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier2Charge';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).SRMCP_CHARGE;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Tier2Ratio';
		IF p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        										p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES;
		END IF;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TotOppCostCleared';
		IF	p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES <> 0 AND
        	(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        	p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES) <> 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).OPP_COST_CHARGE_CLEARED /
        										(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        										p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES);
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := 0;
        END IF;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'OppCostClearedCharge';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).OPP_COST_CHARGE_CLEARED;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'TotalOppCostAdded';
		IF	p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES <> 0 AND
        	(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        	p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES) <> 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).OPP_COST_CHARGE_ADDED /
        										(p_RECORDS(v_IDX).PARTICIPANT_SPIN_PURCHASES /
        										p_RECORDS(v_IDX).PJM_TOTAL_SPIN_PURCHASES);
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL := 0;
        END IF;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'OppCostAddedCharge';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := p_RECORDS(v_IDX).OPP_COST_CHARGE_ADDED;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.CHARGE_ID := v_SPIN_RES_CH_ID;
		v_FORMULA_CHARGE.CHARGE_RATE := 1;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).TIER1_CHARGE + p_RECORDS(v_IDX).SRMCP_CHARGE
        									+ p_RECORDS(v_IDX).OPP_COST_CHARGE_CLEARED + p_RECORDS(v_IDX).OPP_COST_CHARGE_ADDED;
		v_FORMULA_CHARGE.CHARGE_AMOUNT := v_FORMULA_CHARGE.CHARGE_QUANTITY;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_BILLING_STATEMENT.CHARGE_Id := v_SPIN_RES_CH_ID;
        v_BILLING_STATEMENT.Charge_Quantity := NVL(v_BILLING_STATEMENT.Charge_Quantity,0) + NVL(v_FORMULA_CHARGE.CHARGE_QUANTITY,0);
        v_BILLING_STATEMENT.Charge_Rate := 1;
        v_BILLING_STATEMENT.Charge_Amount := NVL(v_BILLING_STATEMENT.Charge_Amount,0) + NVL(v_FORMULA_CHARGE.CHARGE_QUANTITY,0);
        v_BILLING_STATEMENT.Bill_Quantity := NVL(v_BILLING_STATEMENT.Bill_Quantity,0) + NVL(v_FORMULA_CHARGE.CHARGE_QUANTITY,0);
        v_BILLING_STATEMENT.Bill_Amount := NVL(v_BILLING_STATEMENT.Bill_Amount,0) + NVL(v_FORMULA_CHARGE.CHARGE_QUANTITY,0);

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

    v_IDX := p_RECORDS.FIRST;
    IF p_RECORDS.EXISTS(v_IDX) THEN
       v_BILLING_STATEMENT.Statement_Date:= v_LAST_DATE;
       v_BILLING_STATEMENT.Statement_End_Date := v_LAST_DATE;
       PC.PUT_BILLING_STATEMENT(v_BILLING_STATEMENT);
    END IF;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;

END IMPORT_SPIN_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_BLACK_START_SUMMARY
	(
	p_RECORDS IN MEX_PJM_BLACKSTART_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE MKT_PRICE_ID_MAP IS TABLE OF NUMBER(9) INDEX BY VARCHAR2(32);
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_BLACK_ST_REV_ID_MAP    MKT_PRICE_ID_MAP;
v_ITERATOR_ID_MAP	ITERATOR_ID_MAP;
v_MARKET_PRICE_ID	NUMBER(9);
v_BLACK_ST_CH_ID	NUMBER(9);
v_BLACK_ST_CR_ID	NUMBER(9);
v_ZONE	VARCHAR2(32);
v_CHARGE_AMOUNT	NUMBER;
v_CREDIT_AMOUNT	NUMBER;

v_COMPONENT_ID	NUMBER(9);
v_PSE_ID	NUMBER(9);
v_ZONE_ID	SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME	VARCHAR2(64);
v_CONTRACT_ID	NUMBER(9);
v_ITERATOR_ID	NUMBER(3) := 0;
v_TRANSACTION_ID	INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_IDX	BINARY_INTEGER;
v_LAST_ORG_ID	VARCHAR2(16) := '?';
v_LAST_DATE	DATE := LOW_DATE;
v_CHARGE_DATE	DATE := LOW_DATE;
v_FORMULA_CHARGE	FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;

BEGIN
  	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;


	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		-- flush charge to formula charge
		IF NOT v_BLACK_ST_CH_ID IS NULL THEN
			v_FORMULA_CHARGE.CHARGE_ID       := v_BLACK_ST_CH_ID;
			v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
			v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
			v_FORMULA_CHARGE.CHARGE_RATE     := 1;
			v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
			PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
		END IF;
		IF NOT v_BLACK_ST_CR_ID IS NULL THEN
			v_FORMULA_CHARGE.CHARGE_ID       := v_BLACK_ST_CR_ID;
			v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
			v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CREDIT_AMOUNT;
			v_FORMULA_CHARGE.CHARGE_RATE     := -1;
			v_FORMULA_CHARGE.CHARGE_AMOUNT   := -v_CREDIT_AMOUNT;
			PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
		END IF;
		v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).BEGIN_DATE) + 1 / 86400;
		v_CHARGE_AMOUNT := 0;
		v_CREDIT_AMOUNT := 0;

        v_ZONE := REPLACE(p_RECORDS(v_IDX).CONTROL_AREA, ' ', '');

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).BEGIN_DATE, 'MM') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).BEGIN_DATE, 'MM');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

            --get contract id
            v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);

            ID.ID_FOR_COMMODITY('Transmission',FALSE, v_COMMODITY_ID);

			v_COMPONENT_ID := GET_COMPONENT('PJM-1380');
			v_BLACK_ST_CH_ID   := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE,
																			'FORMULA');
			v_COMPONENT_ID := GET_COMPONENT('PJM-2380');
			v_BLACK_ST_CR_ID   := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE,
																			'FORMULA');
		END IF;

   		v_ITERATOR_NAME.CHARGE_ID := v_BLACK_ST_CH_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_BLACK_ST_CH_ID;
       	IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;
		v_ITERATOR.ITERATOR1 := v_ZONE;
		v_ITERATOR.ITERATOR2 := NULL;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

        v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
        v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


		-- first update the market prices - get IDs from cache
		IF v_BLACK_ST_REV_ID_MAP.EXISTS(v_ZONE) THEN
			v_MARKET_PRICE_ID := v_BLACK_ST_REV_ID_MAP(v_ZONE);
		ELSE
			v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:' || v_ZONE || ':BlackStRevReq');
			IF v_MARKET_PRICE_ID IS NULL THEN
				IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
          							p_MARKET_PRICE_NAME => 'PJM Black Start Rev Req - ' || v_ZONE,
									p_MARKET_PRICE_ALIAS =>'PJM Black Start Rev Req - ' || v_ZONE,
                            		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
									p_MARKET_PRICE_ID => 0,
                            		p_MARKET_PRICE_TYPE => 'PJM Black Start Rev Req',
									p_MARKET_PRICE_INTERVAL => 'Month',
                            		p_MARKET_TYPE => '?',
									p_COMMODITY_ID => v_COMMODITY_ID, --transmission
									p_SERVICE_POINT_TYPE => '?',
                            		p_EXTERNAL_IDENTIFIER => 'PJM:' || v_ZONE || ':BlackStRevReq',
									p_EDC_ID => 0,
									p_SC_ID => g_PJM_SC_ID,
                            		p_POD_ID => 0,
									p_ZOD_ID => v_ZONE_ID);
			END IF;
			v_BLACK_ST_REV_ID_MAP(v_ZONE) := v_MARKET_PRICE_ID;
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, TRUNC(v_CHARGE_DATE),
													 p_RECORDS(v_IDX).TOT_ZONAL_BLACKSTART_REV_REQ);

		-- next, update formula variables
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_BLACK_ST_CH_ID;
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZonePeakUse';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOT_ZONE_PEAK_TRANS_USE;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        --cn get transaction id, update schedule
        v_TRANSACTION_ID := GET_TX_ID('PJM:' || v_ZONE || ':ZnPk',
                                      'Zonal Peak Use',
                                      'PJM Zonal Peak Use: '|| v_ZONE,
                                      'Month',
                                      v_COMMODITY_ID,
                                      0,
                                      v_ZONE_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_FORMULA_CHARGE_VAR.CHARGE_DATE,
                           p_RECORDS(v_IDX).TOT_ZONE_PEAK_TRANS_USE );



        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZoneBlackStartRevReq';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOT_ZONAL_BLACKSTART_REV_REQ;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalNonZonePeakUse';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOT_PJM_NONZONE_PEAK_TRANS_USE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        --cn get transaction id, update schedule
        v_TRANSACTION_ID := GET_TX_ID('PJMNonZonePeakBlkSt',
                                      'TtlNZon Peak Use',
                                      'PJM Total NonZonal Peak Use_BlkSt',
                                      'Month',
                                      v_COMMODITY_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_FORMULA_CHARGE_VAR.CHARGE_DATE,
                           p_RECORDS(v_IDX).TOT_PJM_NONZONE_PEAK_TRANS_USE );

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'PJMTotalZonalPeakUse';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE ;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        --cn get transaction id, update schedule
        v_TRANSACTION_ID := GET_TX_ID('PJMZonePeakBlkSt',
                                      'TtlZone Pk BlkSt',
                                      v_zone ||'PJM TotZonal Pk Use_BlkSt',
                                      'Month',
                                      v_COMMODITY_ID,
                                      0,
                                      v_ZONE_ID);

        PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
                           v_FORMULA_CHARGE_VAR.CHARGE_DATE,
                           p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE );

        -- intermediate variables for the charge component
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlyZoneTransUse';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_ZONE_PEAK_TRANS_USE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlyNonZoneTransUse';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_NONZONE_PEAK_TRANS_USE;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'AdjustmentFactor';
        IF (p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE+p_RECORDS(v_IDX).TOT_PJM_NONZONE_PEAK_TRANS_USE) = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE/
        									(p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE+p_RECORDS(v_IDX).TOT_PJM_NONZONE_PEAK_TRANS_USE );
        END IF;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlyZoneCharge';
        IF p_RECORDS(v_IDX).TOT_ZONE_PEAK_TRANS_USE = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_ZONE_PEAK_TRANS_USE *p_RECORDS(v_IDX).TOT_ZONAL_BLACKSTART_REV_REQ *
        									(p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE /
        									(p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE +p_RECORDS(v_IDX).TOT_PJM_NONZONE_PEAK_TRANS_USE ))/
                                            p_RECORDS(v_IDX).TOT_ZONE_PEAK_TRANS_USE ;
        END IF;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MonthlynNonZoneCharge';
        IF (p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE+p_RECORDS(v_IDX).TOT_PJM_NONZONE_PEAK_TRANS_USE) = 0 THEN
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := 0;
        ELSE
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).MEMBER_NONZONE_PEAK_TRANS_USE /
            									 (p_RECORDS(v_IDX).TOT_PJM_ZONE_PEAK_TRANS_USE+p_RECORDS(v_IDX).TOT_PJM_NONZONE_PEAK_TRANS_USE )*
        									p_RECORDS(v_IDX).TOT_ZONAL_BLACKSTART_REV_REQ ;
        END IF;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'MemberCharge';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).CHARGE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_CHARGE_AMOUNT := v_CHARGE_AMOUNT + p_RECORDS(v_IDX).CHARGE;

        -- now update the credit component
        v_FORMULA_CHARGE_VAR.CHARGE_ID := v_BLACK_ST_CR_ID;

        v_ITERATOR.CHARGE_ID := v_BLACK_ST_CR_ID;
		PC.PUT_FORMULA_ITERATOR(v_ITERATOR);


        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZoneReactiveRevReq';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).TOT_ZONAL_BLACKSTART_REV_REQ ;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_CREDIT_AMOUNT := v_CREDIT_AMOUNT + p_RECORDS(v_IDX).CREDIT;

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;
	-- flush charge to formula charge
	IF NOT v_BLACK_ST_CH_ID IS NULL THEN
		v_FORMULA_CHARGE.CHARGE_ID       := v_BLACK_ST_CH_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CHARGE_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE     := 1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := v_CHARGE_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END IF;
	IF NOT v_BLACK_ST_CR_ID IS NULL THEN
		v_FORMULA_CHARGE.CHARGE_ID       := v_BLACK_ST_CR_ID;
		v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
		v_FORMULA_CHARGE.CHARGE_QUANTITY := v_CREDIT_AMOUNT;
		v_FORMULA_CHARGE.CHARGE_RATE     := -1;
		v_FORMULA_CHARGE.CHARGE_AMOUNT   := -v_CREDIT_AMOUNT;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END IF;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;
END IMPORT_BLACK_START_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EN_IMB_CRE_SUMMARY
	(
	p_RECORDS IN MEX_PJM_EN_IMB_CRE_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
BEGIN
  p_STATUS := GA.SUCCESS;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_EN_IMB_CRE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CAP_CRED_SUMMARY
	(
	p_RECORDS IN MEX_PJM_CAP_CRED_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
BEGIN
  p_STATUS := GA.SUCCESS;

  IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    COMMIT;
  END IF;
END IMPORT_CAP_CRED_SUMMARY;
----------------------------------------------------------------------------------------------------
FUNCTION DAILY_TX_TO_TABLE(p_RECORDS IN MEX_PJM_DAILY_TX_TBL)
	RETURN NUMBER IS

	v_WORK_ID  NUMBER;
BEGIN
	SELECT AID.NEXTVAL INTO v_WORK_ID FROM DUAL;
	FOR I IN p_RECORDS.FIRST .. p_RECORDS.LAST LOOP
		INSERT INTO MEX_DAILY_TX_WORK
			(WORK_ID,
			 PARTICIPANT_NAME,
			 TRANSACTION_ID,
			 TRANSACTION_TYPE,
			 SELLER,
			 BUYER,
			 TRANSACTION_DATE,
			 HOUR_ENDING,
			 AMOUNT)
		VALUES
			(v_WORK_ID,
			 p_RECORDS(i).PARTICIPANT_NAME,
			 p_RECORDS(i).TRANSACTION_ID,
			 p_RECORDS(i).TRANSACTION_TYPE,
			 p_RECORDS(i).SELLER,
			 p_RECORDS(i).BUYER,
			 p_RECORDS(i).TRANSACTION_DATE,
			 p_RECORDS(i).HOUR_ENDING,
			 p_RECORDS(i).AMOUNT);
	END LOOP;
	COMMIT;
	RETURN v_WORK_ID;
END DAILY_TX_TO_TABLE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_DA_DAILY_TX
    (
    p_RECORDS IN MEX_PJM_DAILY_TX_TBL,
    p_STATUS  OUT NUMBER
    ) AS

    v_INC_AMT NUMBER;
    v_DEC_AMT NUMBER;
    v_LOAD_AMT NUMBER;
    v_GEN_AMT NUMBER;
    v_PURCH_AMT NUMBER;
    v_SALE_AMT NUMBER;
    v_HOURS_FOR_DAY NUMBER(2);

    v_PSE_ID NUMBER(9);
    v_LAST_DATE   DATE := LOW_DATE;
    v_CHARGE_DATE DATE;
    v_COMPONENT_ID      NUMBER(9);

    TYPE ARRAY IS VARRAY(10) OF BINARY_INTEGER;
    v_CHARGE_IDS ARRAY := ARRAY();

    v_WORK_ID NUMBER;
    CURSOR c_DATES IS
        SELECT DISTINCT T.TRANSACTION_DATE
        FROM MEX_DAILY_TX_WORK T
        WHERE T.WORK_ID = v_WORK_ID
        ORDER BY T.TRANSACTION_DATE ASC;

BEGIN
    p_STATUS := GA.SUCCESS;

    IF p_RECORDS.COUNT = 0 THEN
    	RETURN;
    END IF; -- nothing to do

    -- put the records into the working table
    v_WORK_ID := DAILY_TX_TO_TABLE(p_RECORDS);

    -- assume the first record's market participant name is the only one
    v_PSE_ID := GET_PSE(p_ORG_ID => NULL, p_ORG_NAME => p_RECORDS(1).PARTICIPANT_NAME);

    FOR REC IN c_DATES LOOP

    -- get the charge IDs to index into LMP_CHARGE with;
    -- they'll only change once a month for these charges
    IF v_LAST_DATE <> TRUNC(REC.TRANSACTION_DATE, 'MM') THEN
        -- get charge IDs
        v_LAST_DATE := TRUNC(REC.TRANSACTION_DATE, 'MM');

        v_CHARGE_IDS.EXTEND(4);

        v_COMPONENT_ID := GET_COMPONENT('PJM-1200');
        v_CHARGE_IDS(1) := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'Formula');
        v_COMPONENT_ID := GET_COMPONENT('PJM:DASpotCred');
        v_CHARGE_IDS(2) := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'Formula');
        v_COMPONENT_ID := GET_COMPONENT('PJM-1205');
        v_CHARGE_IDS(3) := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'Formula');
        v_COMPONENT_ID := GET_COMPONENT('PJM:BalSpotCred');
        v_CHARGE_IDS(4) := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'Formula');
    END IF;

    -- get the number of hours by getting the max hour_ending for this date
    SELECT MAX(T.HOUR_ENDING)
    INTO v_HOURS_FOR_DAY
    FROM TABLE(p_RECORDS) T
    WHERE T.TRANSACTION_DATE = REC.TRANSACTION_DATE;

    FOR HR IN 1 .. v_HOURS_FOR_DAY LOOP
			SELECT T.AMOUNT
				INTO v_INC_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.TRANSACTION_TYPE = 'INCREMENT TRANSACTIONS'
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR;
			SELECT T.AMOUNT
				INTO v_DEC_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.TRANSACTION_TYPE = 'DECREMENT TRANSACTIONS'
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR;
			SELECT T.AMOUNT
				INTO v_LOAD_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.TRANSACTION_TYPE = 'DEMAND'
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR;
			SELECT T.AMOUNT
				INTO v_GEN_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.TRANSACTION_TYPE = 'GENERATION'
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR;
			SELECT SUM(T.AMOUNT)
				INTO v_PURCH_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.AMOUNT < 0
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR
				 AND T.TRANSACTION_TYPE NOT IN
						 ('INCREMENT TRANSACTIONS', 'DECREMENT TRANSACTIONS', 'DEMAND',
							'GENERATION');

			 SELECT SUM(T.AMOUNT)
				INTO v_SALE_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.AMOUNT > 0
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR
				 AND T.TRANSACTION_TYPE NOT IN
						 ('INCREMENT TRANSACTIONS', 'DECREMENT TRANSACTIONS', 'DEMAND',
							'GENERATION');

			-- dst should be represented by HR = 25
			v_CHARGE_DATE := GET_CHARGE_DATE(REC.TRANSACTION_DATE, HR, 0);

			FOR i IN v_CHARGE_IDS.FIRST..v_CHARGE_IDS.LAST LOOP
				PUT_LMP_FORMULA_CHARGE_VAR_DA(v_CHARGE_IDS(i), v_CHARGE_DATE, NULL, NULL,
						NVL(v_LOAD_AMT,0), NVL(v_GEN_AMT,0),
  						NVL(v_PURCH_AMT,0), NVL(v_SALE_AMT,0),
						NVL(v_INC_AMT,0), NVL(v_DEC_AMT,0));
			END LOOP;

		END LOOP;

		-- commit for every day
		COMMIT;

	END LOOP;

	DELETE FROM MEX_DAILY_TX_WORK WHERE WORK_ID = v_WORK_ID;
	COMMIT;
END IMPORT_DA_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_RT_DAILY_TX
	(
	p_RECORDS IN MEX_PJM_DAILY_TX_TBL,
	p_STATUS  OUT NUMBER
	) AS

	v_PURCH_AMT NUMBER;
	v_SALE_AMT NUMBER;
    v_LOAD_AMT NUMBER;
    v_GEN_AMT NUMBER;
	v_HOURS_FOR_DAY NUMBER(2);

    v_PSE_ID NUMBER(9);
	v_LAST_DATE   DATE := LOW_DATE;
	v_CHARGE_DATE DATE;
	v_COMPONENT_ID      NUMBER(9);

  TYPE ARRAY IS VARRAY(10) OF BINARY_INTEGER;
  v_CHARGE_IDS ARRAY := ARRAY();

	v_WORK_ID NUMBER;
	CURSOR c_DATES IS
		SELECT DISTINCT T.TRANSACTION_DATE
			FROM MEX_DAILY_TX_WORK T
		 WHERE T.WORK_ID = v_WORK_ID
		 ORDER BY T.TRANSACTION_DATE ASC;

    FUNCTION GET_FORMULA_VAR_VALUE
    (
        p_CHARGE_ID IN NUMBER,
        p_CHARGE_DATE IN DATE,
        p_VAR_NAME IN VARCHAR2,
		p_ITERATOR_ID IN NUMBER := 0

    ) RETURN NUMBER AS

    v_VALUE NUMBER;
    BEGIN
        BEGIN
            SELECT VARIABLE_VAL
            INTO v_VALUE
            FROM FORMULA_CHARGE_VARIABLE
            WHERE CHARGE_ID = p_CHARGE_ID
            AND ITERATOR_ID = p_ITERATOR_ID
            AND CHARGE_DATE = p_CHARGE_DATE
            AND VARIABLE_NAME = p_VAR_NAME;
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
        		NULL;
        END;

    	RETURN NVL(v_VALUE,0);

    END GET_FORMULA_VAR_VALUE;

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	-- put the records into the working table
	v_WORK_ID := DAILY_TX_TO_TABLE(p_RECORDS);

	-- assume the first record's market participant name is the only one
	v_PSE_ID := GET_PSE(p_ORG_ID => NULL,
											p_ORG_NAME => p_RECORDS(1).PARTICIPANT_NAME);

	FOR REC IN c_DATES LOOP

		-- get the charge IDs to index into LMP_CHARGE with;
		-- they'll only change once a month for these charges
		IF v_LAST_DATE <> TRUNC(REC.TRANSACTION_DATE, 'MM') THEN
			-- get charge IDs
			v_LAST_DATE := TRUNC(REC.TRANSACTION_DATE, 'MM');

			-- I know a priori that I've got 2 charges to update:
			-- balancing spot charges and credits
			v_CHARGE_IDS.EXTEND(2);

			v_COMPONENT_ID  := GET_COMPONENT('PJM-1205');
			v_CHARGE_IDS(1) := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'Formula');
			v_COMPONENT_ID  := GET_COMPONENT('PJM:BalSpotCred');
			v_CHARGE_IDS(2) := GET_CHARGE_ID(v_PSE_ID, v_COMPONENT_ID, v_LAST_DATE, 'Formula');
		END IF;

		-- get the number of hours by getting the max hour_ending for this date
		SELECT MAX(T.HOUR_ENDING)
			INTO v_HOURS_FOR_DAY
			FROM TABLE(p_RECORDS) T
		 WHERE T.TRANSACTION_DATE = REC.TRANSACTION_DATE;


		FOR HR IN 1 .. v_HOURS_FOR_DAY LOOP
			-- we want the real-time purchases and sales exclusive of any WLRs, to back out from the
			-- totals that are in the RTLoad and RTGen variables from the import of the transmission
			-- congestion summary. Fix to bug 10900.
			SELECT ABS(SUM(T.AMOUNT))
				INTO v_PURCH_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.AMOUNT < 0
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR
                 AND TRANSACTION_TYPE != 'INTERNAL WLR';
			SELECT SUM(T.AMOUNT)
				INTO v_SALE_AMT
				FROM MEX_DAILY_TX_WORK T
			 WHERE T.AMOUNT > 0
				 AND T.WORK_ID = v_WORK_ID
				 AND T.TRANSACTION_DATE = REC.TRANSACTION_DATE
				 AND T.HOUR_ENDING = HR
                 AND TRANSACTION_TYPE != 'INTERNAL WLR';

            --HR will be 25 for second hour 2 on DST day.
			v_CHARGE_DATE := GET_CHARGE_DATE(REC.TRANSACTION_DATE, HR, 0);

			FOR i IN v_CHARGE_IDS.FIRST..v_CHARGE_IDS.LAST LOOP

				v_LOAD_AMT  := GET_FORMULA_VAR_VALUE(v_CHARGE_IDS(i), v_CHARGE_DATE, 'RTLoad') - NVL(v_SALE_AMT, 0);
				v_GEN_AMT   := GET_FORMULA_VAR_VALUE(v_CHARGE_IDS(i), v_CHARGE_DATE, 'RTGen') - NVL(v_PURCH_AMT, 0);
				-- strictly speaking, there won't ever be an existing value in RTPurch or RTSales
				v_PURCH_AMT := NVL(v_PURCH_AMT, 0) + GET_FORMULA_VAR_VALUE(v_CHARGE_IDS(i), v_CHARGE_DATE, 'RTPurch');
				v_SALE_AMT  := NVL(v_SALE_AMT, 0)  + GET_FORMULA_VAR_VALUE(v_CHARGE_IDS(i), v_CHARGE_DATE, 'RTSales');

				PUT_LMP_FORMULA_CHARGE_VAR_RT(v_CHARGE_IDS(i), v_CHARGE_DATE, NULL, NULL,
					v_LOAD_AMT, -v_GEN_AMT, -v_PURCH_AMT, v_SALE_AMT);
			END LOOP; --over charge ids

		END LOOP; --over hours

		-- commit for every day
		COMMIT;

	END LOOP;

	DELETE FROM MEX_DAILY_TX_WORK WHERE WORK_ID = v_WORK_ID;
	COMMIT;
END IMPORT_RT_DAILY_TX;
----------------------------------------------------------------------------------------------------
FUNCTION EXPLICIT_CONG_TO_TABLE
	(
	p_RECORDS IN MEX_PJM_EXPLICIT_CONG_TBL
	) RETURN NUMBER IS

	v_WORK_ID NUMBER;
BEGIN
	SELECT AID.NEXTVAL INTO v_WORK_ID FROM DUAL;
	FOR I IN p_RECORDS.FIRST .. p_RECORDS.LAST LOOP
		INSERT INTO MEX_CONGESTION_WORK
			(WORK_ID,
			 ORG_ID,
			 DAY,
			 HOUR,
			 DST,
			 OASIS_ID,
			 RESERVATION_TYPE,
			 RESERVED_MW,
			 ENERGY_ID,
			 BUYER,
			 SELLER,
			 SINK_NAME,
			 SOURCE_NAME,
			 DA_SCHEDULED_MWH,
			 DA_SINK_LMP,
			 DA_SOURCE_LMP,
			 DA_EXPLICIT_CONGESTION_CHARGE,
			 BAL_DEVIATION_MWH,
			 BAL_SINK_LMP,
			 BAL_SOURCE_LMP,
			 BAL_EXPLICIT_CONGESTION_CHARGE)
		VALUES
			(v_WORK_ID,
			 p_RECORDS(I).ORG_ID,
			 p_RECORDS(I).DAY,
			 p_RECORDS(I).HOUR,
			 p_RECORDS(I).DST,
			 p_RECORDS(I).OASIS_ID,
			 p_RECORDS(I).RESERVATION_TYPE,
			 p_RECORDS(I).RESERVED_MW,
			 p_RECORDS(I).ENERGY_ID,
			 p_RECORDS(I).BUYER,
			 p_RECORDS(I).SELLER,
			 p_RECORDS(I).SINK_NAME,
			 p_RECORDS(I).SOURCE_NAME,
			 p_RECORDS(I).DA_SCHEDULED_MWH,
			 p_RECORDS(I).DA_SINK_LMP,
			 p_RECORDS(I).DA_SOURCE_LMP,
			 p_RECORDS(I).DA_EXPLICIT_CONGESTION_CHARGE,
			 p_RECORDS(I).BAL_DEVIATION_MWH,
			 p_RECORDS(I).BAL_SINK_LMP,
			 p_RECORDS(I).BAL_SOURCE_LMP,
			 p_RECORDS(I).BAL_EXPLICIT_CONGESTION_CHARGE);
	END LOOP;
	COMMIT;
	RETURN v_WORK_ID;
END EXPLICIT_CONG_TO_TABLE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPLICIT_CONGESTION
	(
	p_STATUS  OUT NUMBER
	) AS
v_DA_CONG_CH_ID     NUMBER(9);
v_DA_CONG_CH_ID_EXP NUMBER(9);
v_RT_CONG_CH_ID     NUMBER(9);
v_RT_CONG_CH_ID_EXP NUMBER(9);
v_COMPONENT_ID      NUMBER(9);
v_PSE_ID            NUMBER(9);
v_LAST_ORG_ID       VARCHAR2(16) := '?';
v_LAST_DATE         DATE := LOW_DATE;
v_CHARGE_DATE       DATE;
v_WORK_ID NUMBER;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_ITERATOR_ID NUMBER := 0;

CURSOR c_BAL_EXPLICIT IS
    SELECT T.DAY,
	        T.HOUR,
	        T.DST,
	        T.SOURCE_NAME,
	        T.SINK_NAME,
	        SUM(T.BAL_DEV_MWH) AS QUANTITY,
	        T.RT_SOURCE_CONG_PRICE,
	        T.RT_SINK_CONG_PRICE,
	        (T.RT_SINK_CONG_PRICE - T.RT_SOURCE_CONG_PRICE) AS RATE
    FROM PJM_EXPLICIT_CONG_CHARGES T
    GROUP BY T.DAY,T.HOUR,T.DST,T.SOURCE_NAME,T.SINK_NAME,T.RT_SINK_CONG_PRICE,T.RT_SOURCE_CONG_PRICE
    ORDER BY T.DAY, T.HOUR;

CURSOR c_DA_EXPLICIT IS
    SELECT T.DAY,
	        T.HOUR,
	        T.DST,
	        T.SOURCE_NAME,
	        T.SINK_NAME,
	        SUM(T.DA_TRANSACTION_MWH) AS QUANTITY,
	        T.DA_SOURCE_CONG_PRICE,
	        T.DA_SINK_CONG_PRICE,
	    (T.DA_SINK_CONG_PRICE - T.DA_SOURCE_CONG_PRICE) AS RATE
    FROM PJM_EXPLICIT_CONG_CHARGES T
    GROUP BY T.DAY, T.HOUR, T.DST, T.SOURCE_NAME, T.SINK_NAME, T.DA_SINK_CONG_PRICE, T.DA_SOURCE_CONG_PRICE
    ORDER BY  T.DAY, T.HOUR;

BEGIN
	p_STATUS := GA.SUCCESS;

	SELECT T.ORG_NID
		INTO v_LAST_ORG_ID
		FROM PJM_EXPLICIT_CONG_CHARGES T
	 WHERE ROWNUM = 1;
	v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);

	-- day-ahead
	FOR v_DA IN c_DA_EXPLICIT LOOP

		v_CHARGE_DATE := GET_CHARGE_DATE(v_DA.Day, v_DA.Hour, v_DA.Dst);

        IF v_LAST_DATE = LOW_DATE THEN
            v_COMPONENT_ID      := GET_COMPONENT('PJM-1210');
            v_DA_CONG_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),
                                                    'COMBINATION');
            v_COMPONENT_ID      := GET_COMPONENT('PJM:DATxCongChg:Exp');
            v_DA_CONG_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_DA_CONG_CH_ID,v_COMPONENT_ID,
                                    TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),'Formula', TRUE);
        END IF;

		IF v_LAST_DATE <> LOW_DATE THEN
			IF v_LAST_DATE <> TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD') THEN
				UPDATE_COMBINATION_CHARGE(v_DA_CONG_CH_ID, v_DA_CONG_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:DATxCongChg:Exp'));
                v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');
                v_COMPONENT_ID      := GET_COMPONENT('PJM:DATxCongChg');
                v_DA_CONG_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'COMBINATION');
                v_COMPONENT_ID      := GET_COMPONENT('PJM:DATxCongChg:Exp');
                v_DA_CONG_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_DA_CONG_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);
			END IF;
		END IF;
		v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');

		v_ITERATOR_NAME.CHARGE_ID := v_DA_CONG_CH_ID_EXP;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Source';
		v_ITERATOR_NAME.ITERATOR_NAME2 := 'Sink';
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_DA_CONG_CH_ID_EXP;
		v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR.ITERATOR1 := v_DA.Source_Name;
		v_ITERATOR.ITERATOR2 := v_DA.Sink_Name;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_DA_CONG_CH_ID_EXP;
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SourceCongPrice';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_DA.Da_Source_Cong_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SinkCongPrice';
	    v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_DA.Da_Sink_Cong_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.Charge_Id := v_DA_CONG_CH_ID_EXP;
		v_FORMULA_CHARGE.Iterator_Id := v_FORMULA_CHARGE_VAR.ITERATOR_ID;
		v_FORMULA_CHARGE.Charge_Date := v_CHARGE_DATE;
		v_FORMULA_CHARGE.Charge_Quantity := v_DA.Quantity;
		v_FORMULA_CHARGE.Charge_Rate := v_DA.Rate;
		v_FORMULA_CHARGE.Charge_Amount := v_DA.Quantity * v_DA.Rate;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END LOOP;

    IF v_LAST_DATE <> LOW_DATE THEN
        UPDATE_COMBINATION_CHARGE(v_DA_CONG_CH_ID, v_DA_CONG_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:DATxCongChg:Exp'));
    END IF;

	-- real-time purchases
	v_LAST_DATE := LOW_DATE;
	FOR v_BAL IN c_BAL_EXPLICIT LOOP

		v_CHARGE_DATE := GET_CHARGE_DATE(v_BAL.Day, v_BAL.Hour, v_BAL.Dst);

         IF v_LAST_DATE = LOW_DATE THEN
            v_COMPONENT_ID      := GET_COMPONENT('PJM-1215');
	        v_RT_CONG_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),
                                    'COMBINATION');
	        v_COMPONENT_ID      := GET_COMPONENT('PJM:BalTxCongChg:Exp');
	        v_RT_CONG_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_RT_CONG_CH_ID,v_COMPONENT_ID,
                                    TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),'Formula', TRUE);
        END IF;
		IF v_LAST_DATE <> LOW_DATE THEN
            IF v_LAST_DATE <> TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD') THEN
				UPDATE_COMBINATION_CHARGE(v_RT_CONG_CH_ID, v_RT_CONG_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:BalTxCongChg:Exp'));
                v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');
	            v_COMPONENT_ID      := GET_COMPONENT('PJM:BalTxCongChg');
                v_RT_CONG_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'COMBINATION');
	            v_COMPONENT_ID      := GET_COMPONENT('PJM:BalTxCongChg:Exp');
                v_RT_CONG_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_RT_CONG_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);
			END IF;
		END IF;
        v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');

		v_ITERATOR_NAME.CHARGE_ID := v_RT_CONG_CH_ID_EXP;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Source';
		v_ITERATOR_NAME.ITERATOR_NAME2 := 'Sink';
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_RT_CONG_CH_ID_EXP;
		v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR.ITERATOR1 := v_BAL.Source_Name;
		v_ITERATOR.ITERATOR2 := v_BAL.Sink_Name;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_RT_CONG_CH_ID_EXP;
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SourceCongPrice';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_BAL.Rt_Source_Cong_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SinkCongPrice';
	  v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_BAL.Rt_Sink_Cong_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.Charge_Id := v_RT_CONG_CH_ID_EXP;
		v_FORMULA_CHARGE.Iterator_Id := v_FORMULA_CHARGE_VAR.ITERATOR_ID;
		v_FORMULA_CHARGE.Charge_Date := v_CHARGE_DATE;
		v_FORMULA_CHARGE.Charge_Quantity := v_BAL.Quantity;
		v_FORMULA_CHARGE.Charge_Rate := v_BAL.Rate;
		v_FORMULA_CHARGE.Charge_Amount := v_BAL.Quantity * v_BAL.Rate;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END LOOP;
	--COMMIT;

	-- flush charges to combination charge table
    IF v_LAST_DATE <> LOW_DATE THEN
		UPDATE_COMBINATION_CHARGE(v_RT_CONG_CH_ID, v_RT_CONG_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:BalTxCongChg:Exp'));
    END IF;
	-- kill the stuff in the working table
	DELETE FROM MEX_CONGESTION_WORK WHERE WORK_ID = v_WORK_ID;
    DELETE FROM PJM_EXPLICIT_CONG_CHARGES;
	COMMIT;

END IMPORT_EXPLICIT_CONGESTION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPLICIT_LOSSES
	(
	p_STATUS  OUT NUMBER
	) AS
v_DA_LOSS_CH_ID     NUMBER(9);
v_DA_LOSS_CH_ID_EXP NUMBER(9);
v_RT_LOSS_CH_ID     NUMBER(9);
v_RT_LOSS_CH_ID_EXP NUMBER(9);
v_COMPONENT_ID      NUMBER(9);
v_PSE_ID            NUMBER(9);
v_LAST_ORG_ID       VARCHAR2(16) := '?';
v_LAST_DATE         DATE := LOW_DATE;
v_CHARGE_DATE       DATE;
v_WORK_ID NUMBER;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_ITERATOR_ID	 NUMBER := 0;

CURSOR c_BAL_EXPLICIT IS
    SELECT T.DAY,
	        T.HOUR,
	        T.DST,
	        T.SOURCE_NAME,
	        T.SINK_NAME,
	        SUM(T.BAL_DEV_MWH) AS QUANTITY,
	        T.RT_SOURCE_LOSS_PRICE,
	        T.RT_SINK_LOSS_PRICE,
	        (T.RT_SINK_LOSS_PRICE - T.RT_SOURCE_LOSS_PRICE) AS RATE
    FROM PJM_EXPLICIT_LOSS_CHARGES T
    GROUP BY T.DAY,T.HOUR,T.DST,T.SOURCE_NAME,T.SINK_NAME,T.RT_SINK_LOSS_PRICE,T.RT_SOURCE_LOSS_PRICE
    ORDER BY T.DAY, T.HOUR;

CURSOR c_DA_EXPLICIT IS
    SELECT T.DAY,
	        T.HOUR,
	        T.DST,
	        T.SOURCE_NAME,
	        T.SINK_NAME,
	        SUM(T.DA_TRANSACTION_MWH) AS QUANTITY,
	        T.DA_SOURCE_LOSS_PRICE,
	        T.DA_SINK_LOSS_PRICE,
	    (T.DA_SINK_LOSS_PRICE - T.DA_SOURCE_LOSS_PRICE) AS RATE
    FROM PJM_EXPLICIT_LOSS_CHARGES T
    GROUP BY T.DAY, T.HOUR, T.DST, T.SOURCE_NAME, T.SINK_NAME, T.DA_SINK_LOSS_PRICE, T.DA_SOURCE_LOSS_PRICE
    ORDER BY  T.DAY, T.HOUR;

BEGIN
	p_STATUS := GA.SUCCESS;

	SELECT T.ORG_NID
		INTO v_LAST_ORG_ID
		FROM PJM_EXPLICIT_LOSS_CHARGES T
	 WHERE ROWNUM = 1;
	v_PSE_ID := GET_PSE(v_LAST_ORG_ID, NULL);

	-- day-ahead
	FOR v_DA IN c_DA_EXPLICIT LOOP

		v_CHARGE_DATE := GET_CHARGE_DATE(v_DA.Day, v_DA.Hour, v_DA.Dst);

        IF v_LAST_DATE = LOW_DATE THEN
            v_COMPONENT_ID      := GET_COMPONENT('PJM-1220');
            v_DA_LOSS_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),
                                                    'COMBINATION');
            v_COMPONENT_ID      := GET_COMPONENT('PJM:DATransLossChg:Exp');
            v_DA_LOSS_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_DA_LOSS_CH_ID,v_COMPONENT_ID,
                                    TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),'Formula', TRUE);
        END IF;

		IF v_LAST_DATE <> LOW_DATE THEN
			IF v_LAST_DATE <> TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD') THEN
				UPDATE_COMBINATION_CHARGE(v_DA_LOSS_CH_ID, v_DA_LOSS_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:DATransLossChg:Exp'));
                v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');
                v_COMPONENT_ID      := GET_COMPONENT('PJM:DATransLossChg');
                v_DA_LOSS_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'COMBINATION');
                v_COMPONENT_ID      := GET_COMPONENT('PJM:DATransLossChg:Exp');
                v_DA_LOSS_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_DA_LOSS_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);
			END IF;
		END IF;
		v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');

		v_ITERATOR_NAME.CHARGE_ID := v_DA_LOSS_CH_ID_EXP;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Source';
		v_ITERATOR_NAME.ITERATOR_NAME2 := 'Sink';
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_DA_LOSS_CH_ID_EXP;
		v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR.ITERATOR1 := v_DA.Source_Name;
		v_ITERATOR.ITERATOR2 := v_DA.Sink_Name;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_DA_LOSS_CH_ID_EXP;
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SourceLossPrice';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_DA.Da_Source_Loss_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SinkLossPrice';
	    v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_DA.Da_Sink_Loss_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.Charge_Id := v_DA_LOSS_CH_ID_EXP;
		v_FORMULA_CHARGE.Iterator_Id := v_FORMULA_CHARGE_VAR.ITERATOR_ID;
		v_FORMULA_CHARGE.Charge_Date := v_CHARGE_DATE;
		v_FORMULA_CHARGE.Charge_Quantity := v_DA.Quantity;
		v_FORMULA_CHARGE.Charge_Rate := v_DA.Rate;
		v_FORMULA_CHARGE.Charge_Amount := v_DA.Quantity * v_DA.Rate;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END LOOP;

    IF v_LAST_DATE <> LOW_DATE THEN
        UPDATE_COMBINATION_CHARGE(v_DA_LOSS_CH_ID, v_DA_LOSS_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:DATransLossChg:Exp'));
    END IF;

	-- real-time purchases
	v_LAST_DATE := LOW_DATE;
	FOR v_BAL IN c_BAL_EXPLICIT LOOP

		v_CHARGE_DATE := GET_CHARGE_DATE(v_BAL.Day, v_BAL.Hour, v_BAL.Dst);

         IF v_LAST_DATE = LOW_DATE THEN
            v_COMPONENT_ID      := GET_COMPONENT('PJM-1225');
	        v_RT_LOSS_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),
                                    'COMBINATION');
	        v_COMPONENT_ID      := GET_COMPONENT('PJM:BalTransLossChg:Exp');
	        v_RT_LOSS_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_RT_LOSS_CH_ID,v_COMPONENT_ID,
                                    TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD'),'Formula', TRUE);
        END IF;
		IF v_LAST_DATE <> LOW_DATE THEN
            IF v_LAST_DATE <> TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD') THEN
				UPDATE_COMBINATION_CHARGE(v_RT_LOSS_CH_ID, v_RT_LOSS_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:BalTransLossChg:Exp'));
                v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');
	            v_COMPONENT_ID      := GET_COMPONENT('PJM:BalTransLossChg');
                v_RT_LOSS_CH_ID     := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'COMBINATION');
	            v_COMPONENT_ID      := GET_COMPONENT('PJM:BalTransLossChg:Exp');
                v_RT_LOSS_CH_ID_EXP := GET_COMBO_CHARGE_ID(v_RT_LOSS_CH_ID,v_COMPONENT_ID,v_LAST_DATE,'Formula', TRUE);
			END IF;
		END IF;
        v_LAST_DATE := TRUNC((FROM_CUT(v_CHARGE_DATE,g_PJM_TIME_ZONE) - 1/86400), 'DD');

		v_ITERATOR_NAME.CHARGE_ID := v_RT_LOSS_CH_ID_EXP;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Source';
		v_ITERATOR_NAME.ITERATOR_NAME2 := 'Sink';
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

		v_ITERATOR.CHARGE_ID := v_RT_LOSs_CH_ID_EXP;
		v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR_ID := v_ITERATOR_ID + 1;
		v_ITERATOR.ITERATOR1 := v_BAL.Source_Name;
		v_ITERATOR.ITERATOR2 := v_BAL.Sink_Name;
		v_ITERATOR.ITERATOR3 := NULL;
		v_ITERATOR.ITERATOR4 := NULL;
		v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE_VAR.CHARGE_ID := v_RT_LOSS_CH_ID_EXP;
		v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SourceLossPrice';
		v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_BAL.Rt_Source_Loss_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'SinkLossPrice';
	    v_FORMULA_CHARGE_VAR.VARIABLE_VAL := v_BAL.Rt_Sink_Loss_Price;
		PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

		v_FORMULA_CHARGE.Charge_Id := v_RT_LOSS_CH_ID_EXP;
		v_FORMULA_CHARGE.Iterator_Id := v_FORMULA_CHARGE_VAR.ITERATOR_ID;
		v_FORMULA_CHARGE.Charge_Date := v_CHARGE_DATE;
		v_FORMULA_CHARGE.Charge_Quantity := v_BAL.Quantity;
		v_FORMULA_CHARGE.Charge_Rate := v_BAL.Rate;
		v_FORMULA_CHARGE.Charge_Amount := v_BAL.Quantity * v_BAL.Rate;
		PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);
	END LOOP;

	-- flush charges to combination charge table
    IF v_LAST_DATE <> LOW_DATE THEN
		UPDATE_COMBINATION_CHARGE(v_RT_LOSS_CH_ID, v_RT_LOSS_CH_ID_EXP, 'FORMULA', 1, v_LAST_DATE, GET_COMPONENT('PJM:BalTransLossChg:Exp'));
    END IF;
	-- kill the stuff in the working table
	DELETE FROM MEX_CONGESTION_WORK WHERE WORK_ID = v_WORK_ID;
    DELETE FROM PJM_EXPLICIT_LOSS_CHARGES;
	COMMIT;

END IMPORT_EXPLICIT_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1_RECONCILE
	(
	p_RECORDS IN MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_SSCD_REC_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ZONE_ID SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME VARCHAR2(64);
v_ITERATOR_ID NUMBER(3) := 0;
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_ATTRIBUTE NUMBER(9);
v_RECONCIL_LAG BINARY_INTEGER;
v_CONTRACT_ID NUMBER(9);

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;

    IF p_RECORDS.Exists(v_IDX) THEN
        v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
        v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);
        v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
        v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
    END IF;


	WHILE p_RECORDS.EXISTS(v_IDX) LOOP

        v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).MONTH)+ NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') + 1 / 86400;

         --get zone name from custom attribute
        ID.ID_FOR_ENTITY_ATTRIBUTE('Zone', 'PSE', 'String', TRUE, v_ATTRIBUTE);

        SELECT ATTRIBUTE_VAL INTO v_ZONE
        FROM TEMPORAL_ENTITY_ATTRIBUTE
        WHERE ATTRIBUTE_ID = v_ATTRIBUTE
        AND OWNER_ENTITY_ID = (SELECT PSE_ID FROM PSE
        WHERE PSE_ALIAS = p_RECORDS(v_IDX).ZONE);

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).MONTH, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).MONTH, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

			v_COMPONENT_ID := GET_COMPONENT('PJM:ReconcilSSCD');
            v_SSCD_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'FORMULA');

			IF v_SSCD_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for SSCD Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_SCHEDULE1_RECONCILE');
                RETURN;
            END IF;

		END IF;

		v_ITERATOR_NAME.CHARGE_ID := v_SSCD_REC_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	v_ITERATOR.CHARGE_ID := v_SSCD_REC_ID;
        IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

    	v_ITERATOR.ITERATOR1 := v_ZONE;
    	v_ITERATOR.ITERATOR2 := NULL;
    	v_ITERATOR.ITERATOR3 := NULL;
    	v_ITERATOR.ITERATOR4 := NULL;
    	v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


    	--update formula variables
    	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
    	v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SSCD_REC_ID;
        v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'Rate';
        v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RATE;
        PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).LOAD;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.CHARGE_ID := v_SSCD_REC_ID;
        v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
        v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).LOAD;
        v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
        v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).CHARGE;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_SCHEDULE1_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1A_RECONCILE
	(
	p_RECORDS IN MEX_PJM_SCHEDULE1A_SUMMARY_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_TO_SSCD_REC_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ZONE_ID SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME VARCHAR2(64);
v_ITERATOR_ID NUMBER(3) := 0;
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_EDC_ID NUMBER(9);
v_NO_CHARGE BOOLEAN := FALSE;
v_ZONE_ATTRIBUTE_ID NUMBER(9);
v_VAL VARCHAR2(32);
v_RECONCIL_LAG BINARY_INTEGER;
v_CONTRACT_ID NUMBER(9);

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;

    IF p_RECORDS.Exists(v_IDX) THEN
        v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
        v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);
        v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
        v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
    END IF;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP

        v_CHARGE_DATE   := TRUNC(p_RECORDS(v_IDX).MONTH)+ NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') + 1 / 86400;

        v_ZONE := REPLACE(p_RECORDS(v_IDX).ZONE, ' ', '');

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

       BEGIN
            SELECT P.PSE_ID INTO v_EDC_ID
            FROM PSE P
            WHERE P.PSE_ALIAS = p_RECORDS(v_IDX).EDC;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_EDC_ID := PUT_PSE(p_RECORDS(v_IDX).EDC, p_RECORDS(v_IDX).ZONE);
        END;

        --make sure zone custom attribute is set
        ID.ID_FOR_ENTITY_ATTRIBUTE('Zone', 'PSE', 'String', TRUE, v_ZONE_ATTRIBUTE_ID);

        BEGIN
            SELECT T.ATTRIBUTE_VAL INTO v_VAL
            FROM TEMPORAL_ENTITY_ATTRIBUTE T
            WHERE T.OWNER_ENTITY_ID = v_EDC_ID
            AND T.ATTRIBUTE_ID = v_ZONE_ATTRIBUTE_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_EDC_ID, v_ZONE_ATTRIBUTE_ID,
        								SYSDATE, NULL, v_ZONE,
                                        v_EDC_ID, v_ZONE_ATTRIBUTE_ID,
                                        SYSDATE, p_STATUS);
        END;

    	IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).MONTH, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).MONTH, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

			v_COMPONENT_ID := GET_COMPONENT('PJM-1450');
            v_TO_SSCD_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'FORMULA');

			IF v_TO_SSCD_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for TOSSCD Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_SCHEDULE1A_RECONCILE');
                --RETURN;
                v_NO_CHARGE := TRUE;
            END IF;

        END IF;
        IF v_NO_CHARGE = FALSE THEN
    		v_ITERATOR_NAME.CHARGE_ID := v_TO_SSCD_REC_ID;
    		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
    		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
    		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
    		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
    		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
    		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

        	v_ITERATOR.CHARGE_ID := v_TO_SSCD_REC_ID;
            IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
    			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
    		ELSE
    			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
                v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
                v_ITERATOR_ID := v_ITERATOR_ID + 1;
            END IF;

        	v_ITERATOR.ITERATOR1 := v_ZONE;
        	v_ITERATOR.ITERATOR2 := NULL;
        	v_ITERATOR.ITERATOR3 := NULL;
        	v_ITERATOR.ITERATOR4 := NULL;
        	v_ITERATOR.ITERATOR5 := NULL;
            PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

    		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
    		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


        	--update formula variables
        	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_CHARGE_DATE;
        	v_FORMULA_CHARGE_VAR.CHARGE_ID := v_TO_SSCD_REC_ID;
            v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ZonalRate';
            v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).RATE;
            PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);
    		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReconciliationMWh';
        	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).LOAD;
        	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

            v_FORMULA_CHARGE.CHARGE_ID := v_TO_SSCD_REC_ID;
            v_FORMULA_CHARGE.CHARGE_DATE     := v_CHARGE_DATE;
            v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).LOAD;
            v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
            v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).CHARGE;
            PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        END IF;
        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_SCHEDULE1A_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ENERGY_CH_RECONCIL
	(
	p_RECORDS IN MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_SPOT_REC_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ZONE_ID SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME VARCHAR2(64);
v_ITERATOR_ID NUMBER(3) := 0;
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_RECONCIL_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_RECONCIL_LAG BINARY_INTEGER;
v_CONTRACT_ID NUMBER(9);

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;

    IF p_RECORDS.Exists(v_IDX) THEN
        v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
        v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);
        v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
        v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
    END IF;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP


        -- put the date
		v_RECONCIL_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).HOUR/100, p_RECORDS(v_IDX).DST_FLAG);
       	v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
        v_ZONE := REPLACE(p_RECORDS(v_IDX).ZONE, ' ', '');

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

			v_COMPONENT_ID := GET_COMPONENT('PJM-1400');
            v_SPOT_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'FORMULA');

			IF v_SPOT_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for Spot Market Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_ENERGY_CH_RECONCIL');
                RETURN;
            END IF;

		END IF;

		v_ITERATOR_NAME.CHARGE_ID := v_SPOT_REC_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	v_ITERATOR.CHARGE_ID := v_SPOT_REC_ID;
        IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

    	v_ITERATOR.ITERATOR1 := v_ZONE;
    	v_ITERATOR.ITERATOR2 := NULL;
    	v_ITERATOR.ITERATOR3 := NULL;
    	v_ITERATOR.ITERATOR4 := NULL;
    	v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


    	--update formula variables
    	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_RECONCIL_DATE;
    	v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SPOT_REC_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).QUANTITY;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.CHARGE_ID := v_SPOT_REC_ID;
        v_FORMULA_CHARGE.CHARGE_DATE     := v_RECONCIL_DATE;
        v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).QUANTITY;
        v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
        v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).CHARGE;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_ENERGY_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ENERGY_CH_RECONCIL_ML
	(
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_SPOT_REC_ID NUMBER(9);
v_CONG_REC_ID NUMBER(9);
v_LOSS_REC_ID NUMBER(9);
v_CONTRACT_ID VARCHAR2(16);
v_SPOT_RECON_ID NUMBER(9);
v_CONG_RECON_ID NUMBER(9);
v_LOSS_RECON_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ITERATOR_ID NUMBER(3) := 0;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_RECONCIL_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE_1 FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR_1 FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME_1 FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR_1 FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_FORMULA_CHARGE_2 FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR_2 FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME_2 FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR_2 FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_FORMULA_CHARGE_3 FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR_3 FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME_3 FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR_3 FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_RECONCIL_LAG BINARY_INTEGER;

CURSOR p_RECON IS
    SELECT * FROM PJM_ENG_CONG_LOSSES_CHRGS_RCN C
    ORDER BY C.PJM_ESCHEDULES_CONTRACT_ID, C.DAY, C.HOUR;

BEGIN
	p_STATUS := GA.SUCCESS;
  	v_ITERATOR_1.ITERATOR_ID := 0;
    v_ITERATOR_2.ITERATOR_ID := 0;
    v_ITERATOR_3.ITERATOR_ID := 0;
    v_SPOT_RECON_ID := GET_COMPONENT('PJM-1400');
    v_CONG_RECON_ID := GET_COMPONENT('PJM-1410');
    v_LOSS_RECON_ID := GET_COMPONENT('PJM-1420');

	FOR v_RECON IN p_RECON LOOP
        -- put the date
        v_CONTRACT_ID := v_RECON.Pjm_Eschedules_Contract_Id;
        v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
		v_RECONCIL_DATE := GET_CHARGE_DATE(v_RECON.Day, v_RECON.Hour/100, v_RECON.Dst);
       	v_CHARGE_DATE := TRUNC(v_RECON.Day, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');


		IF v_LAST_ORG_ID <> v_RECON.Org_Nid OR
            v_LAST_DATE <> TRUNC(v_RECON.Day, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') THEN
            -- get charge IDs
            v_LAST_ORG_ID := v_RECON.Org_Nid;
            v_LAST_DATE   := TRUNC(v_RECON.Day, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            v_SPOT_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_SPOT_RECON_ID,v_LAST_DATE,'FORMULA');
            v_CONG_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_CONG_RECON_ID,v_LAST_DATE,'FORMULA');
            v_LOSS_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_LOSS_RECON_ID,v_LAST_DATE,'FORMULA');

			IF v_SPOT_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for Spot Market Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_ENERGY_CH_RECONCIL');
                RETURN;
            END IF;
            IF v_CONG_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for Transmission Congestion Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_ENERGY_CH_RECONCIL');
                RETURN;
            END IF;
            IF v_LOSS_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for Transmission Losses Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_ENERGY_CH_RECONCIL');
                RETURN;
            END IF;

		END IF;

		v_ITERATOR_NAME_1.CHARGE_ID := v_SPOT_REC_ID;
		v_ITERATOR_NAME_1.ITERATOR_NAME1 := 'Contract_ID';
		v_ITERATOR_NAME_1.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME_1.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME_1.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME_1.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME_1);

        v_ITERATOR_NAME_2.CHARGE_ID := v_CONG_REC_ID;
		v_ITERATOR_NAME_2.ITERATOR_NAME1 := 'Contract_ID';
		v_ITERATOR_NAME_2.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME_2.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME_2.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME_2.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME_2);

        v_ITERATOR_NAME_3.CHARGE_ID := v_LOSS_REC_ID;
		v_ITERATOR_NAME_3.ITERATOR_NAME1 := 'Contract_ID';
		v_ITERATOR_NAME_3.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME_3.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME_3.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME_3.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME_3);

    	v_ITERATOR_1.CHARGE_ID := v_SPOT_REC_ID;
        v_ITERATOR_2.CHARGE_ID := v_CONG_REC_ID;
        v_ITERATOR_3.CHARGE_ID := v_LOSS_REC_ID;
        IF v_ITERATOR_ID_MAP.EXISTS(v_CONTRACT_ID) THEN
			v_ITERATOR_1.ITERATOR_ID := v_ITERATOR_ID_MAP(v_CONTRACT_ID);
            v_ITERATOR_2.ITERATOR_ID := v_ITERATOR_ID_MAP(v_CONTRACT_ID);
            v_ITERATOR_3.ITERATOR_ID := v_ITERATOR_ID_MAP(v_CONTRACT_ID);
		ELSE
			v_ITERATOR_1.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_2.ITERATOR_ID := v_ITERATOR_1.ITERATOR_ID;
            v_ITERATOR_3.ITERATOR_ID := v_ITERATOR_1.ITERATOR_ID;
            v_ITERATOR_ID_MAP(v_CONTRACT_ID) := v_ITERATOR_1.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

    	v_ITERATOR_1.ITERATOR1 := v_CONTRACT_ID;
    	v_ITERATOR_1.ITERATOR2 := NULL;
    	v_ITERATOR_1.ITERATOR3 := NULL;
    	v_ITERATOR_1.ITERATOR4 := NULL;
    	v_ITERATOR_1.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR_1);

        v_ITERATOR_2.ITERATOR1 := v_CONTRACT_ID;
    	v_ITERATOR_2.ITERATOR2 := NULL;
    	v_ITERATOR_2.ITERATOR3 := NULL;
    	v_ITERATOR_2.ITERATOR4 := NULL;
    	v_ITERATOR_2.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR_2);

        v_ITERATOR_3.ITERATOR1 := v_CONTRACT_ID;
    	v_ITERATOR_3.ITERATOR2 := NULL;
    	v_ITERATOR_3.ITERATOR3 := NULL;
    	v_ITERATOR_3.ITERATOR4 := NULL;
    	v_ITERATOR_3.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR_3);

		v_FORMULA_CHARGE_1.ITERATOR_ID := v_ITERATOR_1.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR_1.ITERATOR_ID := v_ITERATOR_1.ITERATOR_ID;

        v_FORMULA_CHARGE_2.ITERATOR_ID := v_ITERATOR_2.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR_2.ITERATOR_ID := v_ITERATOR_2.ITERATOR_ID;

        v_FORMULA_CHARGE_3.ITERATOR_ID := v_ITERATOR_3.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR_3.ITERATOR_ID := v_ITERATOR_3.ITERATOR_ID;

    	--update formula variables
    	v_FORMULA_CHARGE_VAR_1.CHARGE_DATE := v_RECONCIL_DATE;
    	v_FORMULA_CHARGE_VAR_1.CHARGE_ID := v_SPOT_REC_ID;

        v_FORMULA_CHARGE_VAR_2.CHARGE_DATE := v_RECONCIL_DATE;
    	v_FORMULA_CHARGE_VAR_2.CHARGE_ID := v_CONG_RECON_ID;

        v_FORMULA_CHARGE_VAR_3.CHARGE_DATE := v_RECONCIL_DATE;
    	v_FORMULA_CHARGE_VAR_3.CHARGE_ID := v_LOSS_REC_ID;

		v_FORMULA_CHARGE_VAR_1.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR_1.VARIABLE_VAL  := v_RECON.Net_Reconciliation_Mwh;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR_1);

        v_FORMULA_CHARGE_VAR_2.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR_2.VARIABLE_VAL  := v_RECON.Net_Reconciliation_Mwh;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR_2);

        v_FORMULA_CHARGE_VAR_3.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR_3.VARIABLE_VAL  := v_RECON.Net_Reconciliation_Mwh;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR_3);

        v_FORMULA_CHARGE_1.CHARGE_ID := v_SPOT_REC_ID;
        v_FORMULA_CHARGE_1.CHARGE_DATE := v_RECONCIL_DATE;
        v_FORMULA_CHARGE_1.CHARGE_QUANTITY := v_RECON.Net_Reconciliation_Mwh;
        v_FORMULA_CHARGE_1.CHARGE_RATE := v_RECON.Real_Time_Energy_Price;
        v_FORMULA_CHARGE_1.CHARGE_AMOUNT := v_RECON.Energy_Reconciliation_Charge;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE_1);

        v_FORMULA_CHARGE_2.CHARGE_ID := v_CONG_RECON_ID;
        v_FORMULA_CHARGE_2.CHARGE_DATE := v_RECONCIL_DATE;
        v_FORMULA_CHARGE_2.CHARGE_QUANTITY := v_RECON.Net_Reconciliation_Mwh;
        v_FORMULA_CHARGE_2.CHARGE_RATE := v_RECON.Real_Time_Cong_Price;
        v_FORMULA_CHARGE_2.CHARGE_AMOUNT := v_RECON.Cong_Reconciliation_Charge;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE_2);

        v_FORMULA_CHARGE_3.CHARGE_ID := v_LOSS_REC_ID;
        v_FORMULA_CHARGE_3.CHARGE_DATE := v_RECONCIL_DATE;
        v_FORMULA_CHARGE_3.CHARGE_QUANTITY := v_RECON.Net_Reconciliation_Mwh;
        v_FORMULA_CHARGE_3.CHARGE_RATE := v_RECON.Real_Time_Loss_Price;
        v_FORMULA_CHARGE_3.CHARGE_AMOUNT := v_RECON.Loss_Reconciliation_Charge;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE_3);

	END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

    DELETE FROM PJM_ENG_CONG_LOSSES_CHRGS_RCN;
    COMMIT;

END IMPORT_ENERGY_CH_RECONCIL_ML;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REGULATION_CH_RECONCIL
	(
	p_RECORDS IN MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER
	) AS

TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_REG_REC_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ZONE_ID SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME VARCHAR2(64);
v_ITERATOR_ID NUMBER(3) := 0;
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_RECONCIL_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_MARKET_PRICE_ID NUMBER(9);
v_ATTRIBUTE NUMBER(9);
v_RECONCIL_LAG BINARY_INTEGER;
v_CONTRACT_ID NUMBER(9);

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;

    IF p_RECORDS.Exists(v_IDX) THEN
        v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
        v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);
        v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
        v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
    END IF;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP


        -- put the date
		v_RECONCIL_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).HOUR/100, p_RECORDS(v_IDX).DST_FLAG);
       	v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');

        --get zone name from custom attribute
        ID.ID_FOR_ENTITY_ATTRIBUTE('Zone', 'PSE', 'String', TRUE, v_ATTRIBUTE);

        SELECT ATTRIBUTE_VAL INTO v_ZONE
        FROM TEMPORAL_ENTITY_ATTRIBUTE
        WHERE ATTRIBUTE_ID = v_ATTRIBUTE
        AND OWNER_ENTITY_ID = (SELECT PSE_ID FROM PSE
        WHERE PSE_ALIAS = p_RECORDS(v_IDX).ZONE);

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

			v_COMPONENT_ID := GET_COMPONENT('PJM-1460');
            v_REG_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'FORMULA');

			IF v_REG_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for Regulation Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_REGULATION_CH_RECONCIL');
                RETURN;
            END IF;

		END IF;

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:RegReconRate:' || v_ZONE);
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Regulation Reconciliation Rate:' || v_ZONE,
								p_MARKET_PRICE_ALIAS => 'PJM Reg Reconcil Rate' || v_ZONE,
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Clearing Price',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:RegReconRate:' || v_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => v_ZONE_ID);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_RECONCIL_DATE,
								p_RECORDS(v_IDX).RATE);


		v_ITERATOR_NAME.CHARGE_ID := v_REG_REC_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	v_ITERATOR.CHARGE_ID := v_REG_REC_ID;
        IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

    	v_ITERATOR.ITERATOR1 := v_ZONE;
    	v_ITERATOR.ITERATOR2 := NULL;
    	v_ITERATOR.ITERATOR3 := NULL;
    	v_ITERATOR.ITERATOR4 := NULL;
    	v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


    	--update formula variables
    	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_RECONCIL_DATE;
    	v_FORMULA_CHARGE_VAR.CHARGE_ID := v_REG_REC_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).QUANTITY;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.CHARGE_ID := v_REG_REC_ID;
        v_FORMULA_CHARGE.CHARGE_DATE     := v_RECONCIL_DATE;
        v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).QUANTITY;
        v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
        v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).CHARGE;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_REGULATION_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPIN_RES_CH_RECONCIL
	(
	p_RECORDS IN MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_SPIN_RES_REC_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ZONE_ID SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME VARCHAR2(64);
v_ITERATOR_ID NUMBER(3) := 0;
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_RECONCIL_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_MARKET_PRICE_ID NUMBER(9);
v_ATTRIBUTE NUMBER(9);
v_RECONCIL_LAG BINARY_INTEGER;
v_CONTRACT_ID NUMBER(9);

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;

    IF p_RECORDS.Exists(v_IDX) THEN
        v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
        v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);
        v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
        v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
    END IF;

	WHILE p_RECORDS.EXISTS(v_IDX) LOOP


        -- put the date
		v_RECONCIL_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).HOUR/100, p_RECORDS(v_IDX).DST_FLAG);
       	v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');

        --get zone name from custom attribute
        ID.ID_FOR_ENTITY_ATTRIBUTE('Zone', 'PSE', 'String', TRUE, v_ATTRIBUTE);

        SELECT ATTRIBUTE_VAL INTO v_ZONE
        FROM TEMPORAL_ENTITY_ATTRIBUTE
        WHERE ATTRIBUTE_ID = v_ATTRIBUTE
        AND OWNER_ENTITY_ID = (SELECT PSE_ID FROM PSE
        WHERE PSE_ALIAS = p_RECORDS(v_IDX).ZONE);

        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;

			v_COMPONENT_ID := GET_COMPONENT('PJM-1470');
            v_SPIN_RES_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'FORMULA');

			IF v_SPIN_RES_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Reconciliation for Spinning Reserve Charge ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_SPIN_RES_CH_RECONCIL');
                RETURN;
            END IF;

		END IF;

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:SpinResReconRate:' || v_ZONE);
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM SpinRes Reconciliation Rate:' || v_ZONE,
								p_MARKET_PRICE_ALIAS => 'PJM SpinRes Reconcil Rate' || v_ZONE,
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Clearing Price',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:SpinResReconRate:' || v_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => v_ZONE_ID);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_RECONCIL_DATE,
								p_RECORDS(v_IDX).RATE);


		v_ITERATOR_NAME.CHARGE_ID := v_SPIN_RES_REC_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	v_ITERATOR.CHARGE_ID := v_SPIN_RES_REC_ID;
        IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

    	v_ITERATOR.ITERATOR1 := v_ZONE;
    	v_ITERATOR.ITERATOR2 := NULL;
    	v_ITERATOR.ITERATOR3 := NULL;
    	v_ITERATOR.ITERATOR4 := NULL;
    	v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


    	--update formula variables
    	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_RECONCIL_DATE;
    	v_FORMULA_CHARGE_VAR.CHARGE_ID := v_SPIN_RES_REC_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).QUANTITY;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.CHARGE_ID := v_SPIN_RES_REC_ID;
        v_FORMULA_CHARGE.CHARGE_DATE     := v_RECONCIL_DATE;
        v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).QUANTITY;
        v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
        v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).CHARGE;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_SPIN_RES_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CR_RECONCIL
	(
	p_RECORDS IN MEX_PJM_RECONCIL_CHARGES_TBL,
	p_STATUS OUT NUMBER
	) AS
TYPE ITERATOR_ID_MAP IS TABLE OF NUMBER(2) INDEX BY VARCHAR2(32);
v_ITERATOR_ID_MAP ITERATOR_ID_MAP;
v_REG_REC_ID NUMBER(9);
v_ZONE VARCHAR2(32);
v_COMPONENT_ID NUMBER(9);
v_PSE_ID NUMBER(9);
v_ZONE_ID SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
v_PSE_NAME VARCHAR2(64);
v_ITERATOR_ID NUMBER(3) := 0;
v_IDX BINARY_INTEGER;
v_LAST_ORG_ID VARCHAR2(16) := '?';
v_LAST_DATE DATE := LOW_DATE;
v_CHARGE_DATE DATE := LOW_DATE;
v_RECONCIL_DATE DATE := LOW_DATE;
v_FORMULA_CHARGE FORMULA_CHARGE%ROWTYPE;
v_FORMULA_CHARGE_VAR FORMULA_CHARGE_VARIABLE%ROWTYPE;
v_ITERATOR_NAME FORMULA_CHARGE_ITERATOR_NAME%ROWTYPE;
v_ITERATOR FORMULA_CHARGE_ITERATOR%ROWTYPE;
v_MARKET_PRICE_ID NUMBER(9);
v_ATTRIBUTE NUMBER(9);
v_RECONCIL_LAG BINARY_INTEGER;
v_CONTRACT_ID NUMBER(9);

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_RECORDS.COUNT = 0 THEN
		RETURN;
	END IF; -- nothing to do

	v_IDX := p_RECORDS.FIRST;
  	v_ITERATOR.ITERATOR_ID := 0;

    IF p_RECORDS.Exists(v_IDX) THEN
        v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
        v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);
        v_CONTRACT_ID := GET_CONTRACT_ID(v_PSE_ID);
        v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
    END IF;

    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        -- put the date
		v_RECONCIL_DATE := GET_CHARGE_DATE(p_RECORDS(v_IDX).DAY, p_RECORDS(v_IDX).HOUR/100, p_RECORDS(v_IDX).DST_FLAG);
       	v_CHARGE_DATE := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');

        --get zone name from custom attribute
        ID.ID_FOR_ENTITY_ATTRIBUTE('Zone', 'PSE', 'String', TRUE, v_ATTRIBUTE);

        SELECT ATTRIBUTE_VAL INTO v_ZONE
        FROM TEMPORAL_ENTITY_ATTRIBUTE
        WHERE ATTRIBUTE_ID = v_ATTRIBUTE
        AND OWNER_ENTITY_ID = (SELECT PSE_ID FROM PSE
        WHERE PSE_ALIAS = p_RECORDS(v_IDX).ZONE);


        --get zone id
        v_ZONE_ID := ID_FOR_SERVICE_ZONE(v_ZONE);

		IF v_LAST_ORG_ID <> p_RECORDS(v_IDX)
		.ORG_ID OR v_LAST_DATE <> TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH') THEN
            -- get charge IDs
            v_LAST_ORG_ID := p_RECORDS(v_IDX).ORG_ID;
            v_LAST_DATE   := TRUNC(p_RECORDS(v_IDX).DAY, 'MM') + NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');
            v_PSE_ID      := GET_PSE(v_LAST_ORG_ID, NULL);

            --get PSE Name
            BEGIN
            	SELECT PSE_NAME
            	INTO v_PSE_NAME
            	FROM PURCHASING_SELLING_ENTITY
            	WHERE PSE_ID = v_PSE_ID;
            EXCEPTION
               	WHEN NO_DATA_FOUND THEN
               		v_PSE_NAME := '?';
            END;


			v_COMPONENT_ID := GET_COMPONENT('PJM-2420');
            v_REG_REC_ID := GET_CHARGE_ID(v_PSE_ID,v_COMPONENT_ID,v_LAST_DATE,'FORMULA');

			IF v_REG_REC_ID IS NULL THEN
            	LOGS.LOG_WARN('Transmission Losses Reconciliation Credits ID not found for PSE_ID:' || v_PSE_ID
                                    || ' during IMPORT_TRANS_LOSS_CR_RECONCIL');
                RETURN;
            END IF;

		END IF;

        v_MARKET_PRICE_ID := GET_MARKET_PRICE('PJM:TransLossReconRate:' || v_ZONE);
		IF v_MARKET_PRICE_ID IS NULL THEN
			IO.PUT_MARKET_PRICE(o_OID =>v_MARKET_PRICE_ID,
      							p_MARKET_PRICE_NAME => 'PJM Transmission Loss Reconciliation Rate:' || v_ZONE,
								p_MARKET_PRICE_ALIAS => 'PJM Trans Loss Reconcil Rate' || v_ZONE,
                        		p_MARKET_PRICE_DESC => 'Generated by MarketManager',
								p_MARKET_PRICE_ID => 0,
                        		p_MARKET_PRICE_TYPE => 'Market Clearing Price',
								p_MARKET_PRICE_INTERVAL => 'Hour',
                        		p_MARKET_TYPE => '?',
								p_COMMODITY_ID => 0,
								p_SERVICE_POINT_TYPE => '?',
                        		p_EXTERNAL_IDENTIFIER => 'PJM:TransLossReconRate:' || v_ZONE,
								p_EDC_ID => 0,
								p_SC_ID => g_PJM_SC_ID,
                        		p_POD_ID => 0,
								p_ZOD_ID => v_ZONE_ID);
		END IF;
		PUT_MARKET_PRICE_VALUE(v_MARKET_PRICE_ID, v_RECONCIL_DATE,
								p_RECORDS(v_IDX).RATE);

		v_ITERATOR_NAME.CHARGE_ID := v_REG_REC_ID;
		v_ITERATOR_NAME.ITERATOR_NAME1 := 'Zone';
		v_ITERATOR_NAME.ITERATOR_NAME2 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME3 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME4 := NULL;
		v_ITERATOR_NAME.ITERATOR_NAME5 := NULL;
		PC.PUT_FORMULA_ITERATOR_NAMES(v_ITERATOR_NAME);

    	v_ITERATOR.CHARGE_ID := v_REG_REC_ID;
        IF v_ITERATOR_ID_MAP.EXISTS(v_ZONE) THEN
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID_MAP(v_ZONE);
		ELSE
			v_ITERATOR.ITERATOR_ID := v_ITERATOR_ID + 1;
            v_ITERATOR_ID_MAP(v_ZONE) := v_ITERATOR.ITERATOR_ID;
            v_ITERATOR_ID := v_ITERATOR_ID + 1;
        END IF;

    	v_ITERATOR.ITERATOR1 := v_ZONE;
    	v_ITERATOR.ITERATOR2 := NULL;
    	v_ITERATOR.ITERATOR3 := NULL;
    	v_ITERATOR.ITERATOR4 := NULL;
    	v_ITERATOR.ITERATOR5 := NULL;
        PC.PUT_FORMULA_ITERATOR(v_ITERATOR);

		v_FORMULA_CHARGE.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;
		v_FORMULA_CHARGE_VAR.ITERATOR_ID := v_ITERATOR.ITERATOR_ID;


    	--update formula variables
    	v_FORMULA_CHARGE_VAR.CHARGE_DATE := v_RECONCIL_DATE;
    	v_FORMULA_CHARGE_VAR.CHARGE_ID := v_REG_REC_ID;

		v_FORMULA_CHARGE_VAR.VARIABLE_NAME := 'ReconciliationMWh';
    	v_FORMULA_CHARGE_VAR.VARIABLE_VAL  := p_RECORDS(v_IDX).QUANTITY;
    	PC.PUT_FORMULA_CHARGE_VAR(v_FORMULA_CHARGE_VAR);

        v_FORMULA_CHARGE.CHARGE_ID := v_REG_REC_ID;
        v_FORMULA_CHARGE.CHARGE_DATE     := v_RECONCIL_DATE;
        v_FORMULA_CHARGE.CHARGE_QUANTITY := p_RECORDS(v_IDX).QUANTITY;
        v_FORMULA_CHARGE.CHARGE_RATE     := p_RECORDS(v_IDX).RATE;
        v_FORMULA_CHARGE.CHARGE_AMOUNT   := p_RECORDS(v_IDX).CHARGE;
        PC.PUT_FORMULA_CHARGE(v_FORMULA_CHARGE);

        v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		COMMIT;
	END IF;

END IMPORT_TRANS_LOSS_CR_RECONCIL;
----------------------------------------------------------------------------------------------------
-- These public routines take a CLOB of CSV data and import them into RO/MM tables. They use routines
-- in MEX to parse the CSV data into records.
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MONTHLY_STATEMENT
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_MONTHLY_STATEMENT_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_MONTHLY_STATEMENT(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_MONTHLY_STATEMENT(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_MONTHLY_STATEMENT;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPOT_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_SPOT_SUMMARY_TBL;
BEGIN
	--assumes date is 6/1/2007 or later with marginal losses changes
    MEX_PJM_SETTLEMENT.PARSE_SPOT_SUMMARY(p_CSV, p_STATUS, p_MESSAGE);
    --MEX_PJM_SETTLEMENT.PARSE_SPOT_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SPOT_SUMMARY(p_STATUS);
        --IMPORT_SPOT_SUMMARY(v_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
END IMPORT_SPOT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CONGESTION_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_CONGESTION_SUMMARY_TBL;
BEGIN
    --assumes date is 6/1/2007 or later with marginal losses changes
	MEX_PJM_SETTLEMENT.PARSE_CONGESTION_SUMMARY(p_CSV, p_STATUS, p_MESSAGE);
    --MEX_PJM_SETTLEMENT.PARSE_CONGESTION_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        IMPORT_CONGESTION_SUMMARY(p_STATUS);
		--IMPORT_CONGESTION_SUMMARY(v_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
END IMPORT_CONGESTION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE9_10_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_SCHED9_10_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_SCHEDULE9_10_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SCHEDULE9_10_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_SCHEDULE9_10_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1A_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_SCHEDULE1A_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_SCHEDULE1A_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SCHEDULE1A_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_SCHEDULE1A_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NITS_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_NITS_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_NITS_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_NITS_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_NITS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_LOST_OPP_COST
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_OP_RES_LOC_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_OP_RES_LOST_OPP_COST(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_OP_RES_LOST_OPP_COST(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_OP_RES_LOST_OPP_COST;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_REVNEUT_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_TRANS_REVNEUT_CHG_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_TRANS_REVNEUT_CHARGES(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_TRANS_REVNEUT_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_TRANS_REVNEUT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPANSION_COST_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_NITS_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_EXPANSION_COST_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_EXPANSION_COST_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_EXPANSION_COST_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_OPER_RES_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_OPER_RES_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_OP_RES_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_OP_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_GEN_CREDITS
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_OPRES_GEN_CREDITS_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_OPER_RES_GEN_CREDITS(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_OP_RES_GEN_CREDITS(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_OP_RES_GEN_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSSES_CHARGES
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_LOSSES_CHARGES_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_LOSSES_CHARGES(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_LOSSES_CHARGES(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_LOSSES_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSSES_CREDITS
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_LOSSES_CREDITS_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_LOSSES_CREDITS(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_LOSSES_CREDITS(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_LOSSES_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FTR_AUCTION
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_FTR_AUCTION_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_FTR_AUCTION(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_FTR_AUCTION(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_FTR_AUCTION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MONTHLY_CREDIT_ALLOC
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_MONTHLY_CRED_ALLOC_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_MONTHLY_CREDIT_ALLOC(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_MONTHLY_CREDIT_ALLOC(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_MONTHLY_CREDIT_ALLOC;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_BLACK_START_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_BLACKSTART_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_BLACK_START_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_BLACK_START_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_BLACK_START_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ARR_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_ARR_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_ARR_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_ARR_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_ARR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REACTIVE_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_REACTIVE_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_REACTIVE_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_REACTIVE_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_REACTIVE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REACTIVE_SERV_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_REACTIVE_SERV_SUMM_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_REACTIVE_SERV_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_REACTIVE_SERV_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_REACTIVE_SERV_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REGULATION_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_REGULATION_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_REGULATION_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_REGULATION_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_REGULATION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FTR_TARGET_ALLOCATION
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
	v_WORK_ID NUMBER(9);
BEGIN
	UT.GET_RTO_WORK_ID(v_WORK_ID);
	MEX_PJM_SETTLEMENT.PARSE_FTR_TARGET_ALLOCATION(p_CSV, v_WORK_ID, p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_FTR_TARGET_ALLOCATION(v_WORK_ID,p_STATUS);
	END IF;
END IMPORT_FTR_TARGET_ALLOCATION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EN_IMB_CRE_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_EN_IMB_CRE_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_EN_IMB_CRE_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_EN_IMB_CRE_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_EN_IMB_CRE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CAP_CRED_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_CAP_CRED_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_CAP_CRED_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_CAP_CRED_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_CAP_CRED_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPIN_RES_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_SPIN_RES_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_SPIN_RES_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SPIN_RES_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_SPIN_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_DA_DAILY_TX
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_DAILY_TX_TBL;
BEGIN
	MEX_PJM_ESCHED.PARSE_DAILY_TRANS_RPT(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_DA_DAILY_TX(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_DA_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_RT_DAILY_TX
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_DAILY_TX_TBL;
BEGIN
	MEX_PJM_ESCHED.PARSE_REAL_TIME_DAILY_TX(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_RT_DAILY_TX(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_RT_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPLICIT_CONGESTION
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_EXPLICIT_CONG_TBL;
BEGIN
	--assumes date is 6/1/2007 or later with marginal losses changes
    --MEX_PJM_SETTLEMENT.PARSE_EXPLICIT_CONGESTION(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
    MEX_PJM_SETTLEMENT.PARSE_EXPLICIT_CONGESTION(p_CSV, p_STATUS, p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        IMPORT_EXPLICIT_CONGESTION(p_STATUS);
		--IMPORT_EXPLICIT_CONGESTION(v_RECORDS,p_STATUS,p_MESSAGE);
	END IF;
END IMPORT_EXPLICIT_CONGESTION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FIRM_TRANS_SERV_CHARGES
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_TRANS_SERV_CHARGES_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_FIRM_TRANS_SERV_CHARGES(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_FIRM_TRANS_SERV_CHARGES(v_RECORDS,NULL,p_STATUS);
	END IF;
END IMPORT_FIRM_TRANS_SERV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NON_FM_TRANS_SV_CHARGES
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_NFIRM_TRANS_SV_CHG_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_NON_FM_TRANS_SV_CHARGES(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_NON_FM_TRANS_SV_CHARGES(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_NON_FM_TRANS_SV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SYNCH_CONDENS_SUMMARY
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_SYNCH_COND_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_SYNCH_CONDENS_SUMMARY(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SYNCH_CONDENS_SUMMARY(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_SYNCH_CONDENS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1_RECONCILE
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_SCHEDULE1A_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_SCHEDULE1_RECONCILE(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SCHEDULE1_RECONCILE(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_SCHEDULE1_RECONCILE;
-----------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1A_RECONCILE
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_SCHEDULE1A_SUMMARY_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_SCHEDULE1A_RECONCILE(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SCHEDULE1A_RECONCILE(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_SCHEDULE1A_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ENERGY_CH_RECONCIL
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
	--assumes date is 6/1/2007 or later with marginal losses changes
    --MEX_PJM_SETTLEMENT.PARSE_ENERGY_CHARGES_RECONCIL(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
    MEX_PJM_SETTLEMENT.PARSE_ENERGY_RECON(p_CSV, p_STATUS, p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        IMPORT_ENERGY_CH_RECONCIL_ML(p_STATUS);
	END IF;
END IMPORT_ENERGY_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REGULATION_CH_RECONCIL
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_REG_CHARGES_RECONCIL(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_REGULATION_CH_RECONCIL(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_REGULATION_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPIN_RES_CH_RECONCIL
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_SPIN_RES_CH_RECONCIL(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SPIN_RES_CH_RECONCIL(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_SPIN_RES_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CR_RECONCIL
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_TRANS_LOSS_CR_RECONCIL(p_CSV,v_RECORDS,p_STATUS,p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_TRANS_LOSS_CR_RECONCIL(v_RECORDS,p_STATUS);
	END IF;
END IMPORT_TRANS_LOSS_CR_RECONCIL;
--------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CHARGES
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_TXN_LOSS_CHARGE(p_CSV, p_STATUS, p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_TRANS_LOSS_CHARGES(p_STATUS);
	END IF;
END IMPORT_TRANS_LOSS_CHARGES;
--------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPLICIT_LOSSES
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_EXPLICIT_LOSS(p_CSV, p_STATUS, p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_EXPLICIT_LOSSES(p_STATUS);
	END IF;
END IMPORT_EXPLICIT_LOSSES;
--------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_INADVERTENT_INTERCHANGE
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_INADV_INTERCHG_CHARGE(p_CSV, p_STATUS, p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_INADVERTENT_INTERCHANGE(p_STATUS);
	END IF;
END IMPORT_INADVERTENT_INTERCHANGE;
--------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CREDITS
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	MEX_PJM_SETTLEMENT.PARSE_TXN_LOSS_CREDIT(p_CSV, p_STATUS, p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_TRANS_LOSS_CREDITS(p_STATUS);
	END IF;
END IMPORT_TRANS_LOSS_CREDITS;
-----------------------------------------------------------------------------
-- These public routines take a begin and end date and download the corresponding data from PJM and
-- then import them into RO/MM tables.
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MONTHLY_STATEMENT(p_CRED 		IN mex_credentials,
								   p_MONTH 		IN DATE,
								   p_LOG_ONLY	IN BINARY_INTEGER,
                                   p_STATUS     OUT NUMBER,
                                   p_MESSAGE    OUT VARCHAR2,
								   p_LOGGER		IN OUT mm_logger_adapter) AS
    v_RECORDS MEX_PJM_MONTHLY_STATEMENT_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_MONTHLY_STATEMENT(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_MONTHLY_STATEMENT(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_MONTHLY_STATEMENT;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPOT_SUMMARY
	(p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_SPOT_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
	MEX_PJM_SETTLEMENT.FETCH_SPOT_SUMMARY(TRUNC(p_MONTH,'MM'),
									LAST_DAY(p_MONTH),
									   p_LOGGER,
									   p_CRED,
											   p_LOG_ONLY,
									p_STATUS,
									p_MESSAGE);
	IF p_STATUS = 0 THEN
		IMPORT_SPOT_SUMMARY(p_STATUS);
	END IF;
END IMPORT_SPOT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CONGESTION_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_CONGESTION_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
	UT.GET_RTO_WORK_ID(g_FTR_CONG_CRED_WK_ID);

	MEX_PJM_SETTLEMENT.FETCH_CONGESTION_SUMMARY(TRUNC(p_MONTH,'MM'),
									   LAST_DAY(p_MONTH),
									   p_LOGGER,
									   p_CRED,
									   p_LOG_ONLY,
									   p_STATUS,
									   p_MESSAGE);
	IF p_STATUS = 0 THEN
		IMPORT_CONGESTION_SUMMARY(p_STATUS);
	END IF;
END IMPORT_CONGESTION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE9_10_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_SCHED9_10_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_SCHEDULE9_10_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_SCHEDULE9_10_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_SCHEDULE9_10_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1A_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_SCHEDULE1A_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_SCHEDULE1A_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_SCHEDULE1A_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_SCHEDULE1A_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NITS_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_NITS_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_NITS_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_NITS_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_NITS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_LOST_OPP_COST
	(
	p_CRED		 IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_OP_RES_LOC_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_OP_RES_LOST_OPP_COST(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_OP_RES_LOST_OPP_COST(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_OP_RES_LOST_OPP_COST;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_REVNEUT_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
--import Transitional Revenue Neutrality Summary for
-- Network Integration Transmission Offset Charges
v_RECORDS MEX_PJM_TRANS_REVNEUT_CHG_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_TRANS_REVNEUT_CHARGES(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_TRANS_REVNEUT_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_TRANS_REVNEUT_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPANSION_COST_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_NITS_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_EXPANSION_COST_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
 											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_EXPANSION_COST_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_EXPANSION_COST_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_OPER_RES_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_OPER_RES_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_OP_RES_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_OP_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_OP_RES_GEN_CREDITS
	(
	p_CRED 		IN mex_credentials,
	p_BEGIN_DATE IN DATE,
	p_END_DATE	IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_OPRES_GEN_CREDITS_TBL;
v_DATE DATE;
BEGIN
    p_STATUS := GA.SUCCESS;
	IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(g_EMKT_GEN_ATTR, p_CRED.EXTERNAL_ACCOUNT_NAME) THEN
		--file is too large to download for entire month... PJM returns nothing if
		--date range too great; download a day at a time
		v_DATE := TRUNC(p_BEGIN_DATE,'MM');
		WHILE v_DATE <= p_END_DATE LOOP
			MEX_PJM_SETTLEMENT.FETCH_OPER_RES_GEN_CREDITS(v_DATE,
														   v_DATE,
															p_LOGGER,
															p_CRED,
															p_LOG_ONLY,
														   v_RECORDS,
														   p_STATUS,
														   p_MESSAGE);
			IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
				IMPORT_OP_RES_GEN_CREDITS(v_RECORDS, p_STATUS);
			END IF;
			v_DATE := v_DATE + 1;
		END LOOP;
	END IF;
END IMPORT_OP_RES_GEN_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSSES_CHARGES
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_LOSSES_CHARGES_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_LOSSES_CHARGES(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_LOSSES_CHARGES(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_LOSSES_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOSSES_CREDITS
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_LOSSES_CREDITS_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_LOSSES_CREDITS(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_LOSSES_CREDITS(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_LOSSES_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FTR_AUCTION
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_FTR_AUCTION_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_FTR_AUCTION(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_FTR_AUCTION(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_FTR_AUCTION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_MONTHLY_CREDIT_ALLOC
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_MONTHLY_CRED_ALLOC_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_MONTHLY_CREDIT_ALLOC(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
 											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_MONTHLY_CREDIT_ALLOC(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_MONTHLY_CREDIT_ALLOC;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ARR_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_ARR_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_ARR_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_ARR_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_ARR_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REACTIVE_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS

	v_RECORDS MEX_PJM_REACTIVE_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_REACTIVE_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_REACTIVE_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_REACTIVE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REACTIVE_SERV_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS

	v_RECORDS MEX_PJM_REACTIVE_SERV_SUMM_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_REACTIVE_SERV_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_REACTIVE_SERV_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_REACTIVE_SERV_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REGULATION_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
	v_RECORDS MEX_PJM_REGULATION_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
		MEX_PJM_SETTLEMENT.FETCH_REGULATION_SUMMARY(
			TRUNC(p_MONTH, 'MM'),
			LAST_DAY(p_MONTH),
			p_LOGGER,
			p_CRED,
			p_LOG_ONLY,
			v_RECORDS,
			p_STATUS,
			p_MESSAGE);

		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
			IMPORT_REGULATION_SUMMARY(v_RECORDS, p_STATUS);
		END IF;
END IMPORT_REGULATION_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FTR_TARGET_ALLOCATION
	(
	p_CRED 		IN mex_credentials,
	p_BEGIN_DATE 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
	v_WORK_ID NUMBER(9);
v_BEGIN_DATE DATE;
v_END_DATE DATE;
BEGIN
    p_STATUS := GA.SUCCESS;
--need to get this report in two chunks, trying to get it for a whole month fails,
--PJM issue
        FOR J IN 1..3 LOOP
            IF J = 1 THEN
                v_BEGIN_DATE := p_BEGIN_DATE;
                v_END_DATE := p_BEGIN_DATE + 9;
            ELSIF J =  2 THEN
                v_BEGIN_DATE := v_END_DATE + 1;
                v_END_DATE := v_BEGIN_DATE + 9;
            ELSE
                v_BEGIN_DATE := v_END_DATE + 1;
                v_END_DATE := LAST_DAY(v_BEGIN_DATE);
            END IF;
		    UT.GET_RTO_WORK_ID(v_WORK_ID);
		    MEX_PJM_SETTLEMENT.FETCH_FTR_TARGET_ALLOCATION(
    			v_WORK_ID,
    			v_BEGIN_DATE,
    			v_END_DATE,--LAST_DAY(p_MONTH),
				p_LOGGER,
				p_CRED,
				p_LOG_ONLY,
    			p_STATUS,
    			p_MESSAGE);

    		IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
    			IMPORT_FTR_TARGET_ALLOCATION(v_WORK_ID, p_STATUS);
    		END IF;

        END LOOP;

	-- Clean up the Congestion Summary information that we cached.
	--DELETE RTO_WORK WHERE WORK_ID = g_FTR_CONG_CRED_WK_ID;

--EXCEPTION
	--WHEN OTHERS THEN
		-- Clean up the Congestion Summary information that we cached.
		--DELETE RTO_WORK WHERE WORK_ID = g_FTR_CONG_CRED_WK_ID;
		--RAISE;
END IMPORT_FTR_TARGET_ALLOCATION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_BLACK_START_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_BLACKSTART_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_BLACK_START_SUMMARY(TRUNC(p_MONTH,'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_BLACK_START_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_BLACK_START_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EN_IMB_CRE_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_EN_IMB_CRE_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_EN_IMB_CRE_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_EN_IMB_CRE_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_EN_IMB_CRE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_CAP_CRED_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_CAP_CRED_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_CAP_CRED_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_CAP_CRED_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_CAP_CRED_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPIN_RES_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_SPIN_RES_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_SPIN_RES_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
   											   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_SPIN_RES_SUMMARY(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_SPIN_RES_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_DA_DAILY_TX
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_DAILY_TX_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_ESCHED.FETCH_DAILY_TRANS_RPT(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_CRED,
											   p_LOGGER,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_DA_DAILY_TX(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_DA_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_RT_DAILY_TX
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_DAILY_TX_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_ESCHED.FETCH_REAL_TIME_DAILY_TX(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
											   p_CRED,
											   p_LOGGER,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_RT_DAILY_TX(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_RT_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPLICIT_CONGESTION
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_EXPLICIT_CONG_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
	MEX_PJM_SETTLEMENT.FETCH_EXPLICIT_CONGESTION(TRUNC(p_MONTH,'MM'),
									   LAST_DAY(p_MONTH),
									   p_LOGGER,
									   p_CRED,
									   p_LOG_ONLY,
									   p_STATUS,
									   p_MESSAGE);

	IF p_STATUS = 0 THEN
		IMPORT_EXPLICIT_CONGESTION(p_STATUS);
	END IF;
END IMPORT_EXPLICIT_CONGESTION;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_EXPLICIT_LOSSES
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
BEGIN
    p_STATUS := GA.SUCCESS;
	MEX_PJM_SETTLEMENT.FETCH_EXPLICIT_LOSS(TRUNC(p_MONTH,'MM'),
										   LAST_DAY(p_MONTH),
										   p_LOGGER,
										   p_CRED,
										   p_LOG_ONLY,
										   p_STATUS,
										   p_MESSAGE);

	IF p_STATUS = 0 THEN
		IMPORT_EXPLICIT_LOSSES(p_STATUS);
	END IF;

END IMPORT_EXPLICIT_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CREDITS
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
BEGIN
    p_STATUS := GA.SUCCESS;
	MEX_PJM_SETTLEMENT.FETCH_TXN_LOSS_CREDIT(TRUNC(p_MONTH,'MM'),
										   LAST_DAY(p_MONTH),
										   p_LOGGER,
										   p_CRED,
										   p_LOG_ONLY,
										   p_STATUS,
										   p_MESSAGE);

	IF p_STATUS = 0 THEN
		IMPORT_TRANS_LOSS_CREDITS(p_STATUS);
	END IF;

END IMPORT_TRANS_LOSS_CREDITS;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_INADVERTENT_INTERCHANGE
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
BEGIN
    p_STATUS := GA.SUCCESS;
	MEX_PJM_SETTLEMENT.FETCH_INADV_INTERCHG_CHARGE(TRUNC(p_MONTH,'MM'),
										   LAST_DAY(p_MONTH),
										   p_LOGGER,
										   p_CRED,
										   p_LOG_ONLY,
										   p_STATUS,
										   p_MESSAGE);

	IF p_STATUS = 0 THEN
		IMPORT_INADVERTENT_INTERCHANGE(p_STATUS);
	END IF;

END IMPORT_INADVERTENT_INTERCHANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FIRM_TRANS_SERV_CHARGES
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_TRANS_SERV_CHARGES_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_FIRM_TRANS_SERV_CHARGES(TRUNC(p_MONTH,
                                                     'MM'),
                                                   LAST_DAY(p_MONTH),
       										   	   p_LOGGER,
											   		p_CRED,
													p_LOG_ONLY,
                                                   v_RECORDS,
                                                   p_STATUS,
                                                   p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_FIRM_TRANS_SERV_CHARGES(v_RECORDS,
      								p_CRED.EXTERNAL_ACCOUNT_NAME,
      								p_STATUS);
    END IF;
END IMPORT_FIRM_TRANS_SERV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_NON_FM_TRANS_SV_CHARGES
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_NFIRM_TRANS_SV_CHG_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_NON_FM_TRANS_SV_CHARGES(TRUNC(p_MONTH,
                                                     'MM'),
                                                   LAST_DAY(p_MONTH),
      										       p_LOGGER,
											       p_CRED,
												   p_LOG_ONLY,
                                                   v_RECORDS,
                                                   p_STATUS,
                                                   p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_NON_FM_TRANS_SV_CHARGES(v_RECORDS,
      								p_STATUS);
    END IF;
END IMPORT_NON_FM_TRANS_SV_CHARGES;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SYNCH_CONDENS_SUMMARY
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_SYNCH_COND_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_SYNCH_CONDENS_SUMMARY(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
      										   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
	IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		IMPORT_SYNCH_CONDENS_SUMMARY(v_RECORDS, p_STATUS);
	END IF;
END IMPORT_SYNCH_CONDENS_SUMMARY;
---------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1_RECONCILE
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_SCHEDULE1A_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_SCHEDULE1_RECONCILE(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
      										   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_SCHEDULE1_RECONCILE(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_SCHEDULE1_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SCHEDULE1A_RECONCILE
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_SCHEDULE1A_SUMMARY_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_SCHEDULE1A_RECONCILE(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
      										   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_SCHEDULE1A_RECONCILE(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_SCHEDULE1A_RECONCILE;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ENERGY_CH_RECONCIL
(
    p_CRED     IN mex_credentials,
    p_MONTH    IN DATE,
    p_LOG_ONLY IN BINARY_INTEGER,
    p_STATUS   OUT NUMBER,
    p_MESSAGE  OUT VARCHAR2,
    p_LOGGER   IN OUT mm_logger_adapter
) AS
    v_RECORDS       MEX_PJM_RECONCIL_CHARGES_TBL;
    v_RECONCIL_LAG  BINARY_INTEGER;
    v_CONTRACT_ID   NUMBER(9);
    v_RECONCIL_DATE DATE;
BEGIN
    p_STATUS := GA.SUCCESS;

    v_CONTRACT_ID  := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_CRED.EXTERNAL_ACCOUNT_NAME);
    v_RECONCIL_LAG := MM_PJM_SHADOW_BILL.GET_RECONCILIATION_LAG(v_CONTRACT_ID);
    IF v_RECONCIL_LAG = 0 THEN
        v_RECONCIL_LAG := 3;
    END IF;
    v_RECONCIL_DATE := TRUNC(p_MONTH, 'MM') -
                       NUMTOYMINTERVAL(v_RECONCIL_LAG, 'MONTH');


    MEX_PJM_SETTLEMENT.FETCH_ENERGY_RECON(TRUNC(p_MONTH, 'MM'),
                                          LAST_DAY(p_MONTH),
                                          p_LOGGER,
                                          p_CRED,
                                          p_LOG_ONLY,
                                          p_STATUS,
                                          p_MESSAGE);
    IF p_STATUS = 0 THEN
        IMPORT_ENERGY_CH_RECONCIL_ML(p_STATUS);
    END IF;

END IMPORT_ENERGY_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_REGULATION_CH_RECONCIL
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_REG_CHARGES_RECONCIL(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
      										   P_LOGGER,
											   P_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_REGULATION_CH_RECONCIL(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_REGULATION_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_SPIN_RES_CH_RECONCIL
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_SPIN_RES_CH_RECONCIL(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
         									   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_SPIN_RES_CH_RECONCIL(v_RECORDS,p_STATUS);
    END IF;
END IMPORT_SPIN_RES_CH_RECONCIL;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CR_RECONCIL
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
    MEX_PJM_SETTLEMENT.FETCH_TRANS_LOSS_CR_RECONCIL(TRUNC(p_MONTH,
                                                     'MM'),
                                               LAST_DAY(p_MONTH),
      										   p_LOGGER,
											   p_CRED,
											   p_LOG_ONLY,
                                               v_RECORDS,
                                               p_STATUS,
                                               p_MESSAGE);
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      IMPORT_TRANS_LOSS_CR_RECONCIL(v_RECORDS, p_STATUS);
    END IF;
END IMPORT_TRANS_LOSS_CR_RECONCIL;
---------------------------------------------------------------------------------------------
PROCEDURE IMPORT_TRANS_LOSS_CHARGES
	(
	p_CRED 		IN mex_credentials,
	p_MONTH 		IN DATE,
	p_LOG_ONLY	IN BINARY_INTEGER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER		IN OUT mm_logger_adapter
	) AS
v_RECORDS MEX_PJM_RECONCIL_CHARGES_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;
	MEX_PJM_SETTLEMENT.FETCH_TXN_LOSS_CHARGE(TRUNC(p_MONTH,'MM'),
										   LAST_DAY(p_MONTH),
										   p_LOGGER,
										   p_CRED,
										   p_LOG_ONLY,
										   p_STATUS,
										   p_MESSAGE);


	IF p_STATUS = 0 THEN
		IMPORT_TRANS_LOSS_CHARGES(p_STATUS);
	END IF;
END IMPORT_TRANS_LOSS_CHARGES;
----------------------------------------------------------------------------------------------------
-- This routine is meant to be a one stop shop to import the entire billing statement and its details
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ENTIRE_STATEMENT
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOG_ONLY IN NUMBER,
	p_LOG_TYPE IN NUMBER,
	p_TRACE_ON IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_EXCHANGE_TYPE IN VARCHAR2 := g_ET_IMP_SETTLEMENT_STMT
	) AS
v_CLOB CLOB;
v_SOMETHING_DONE BOOLEAN;

v_CREDS	mm_credentials_set;
v_CRED	mex_credentials;
v_LOGGER mm_logger_adapter;

v_MONTHLY_BILLING_STATEMENT BOOLEAN := TRUE;
v_SPOT_MKT_ENERGY_SUMMARY BOOLEAN := TRUE;
v_CONGESTION_SUMMARY BOOLEAN := TRUE;
v_SCHEDULE_9_AND_10_SUMMARY BOOLEAN := TRUE;
v_NET_TRANS_SERVICE_SUMMARY BOOLEAN := TRUE;
v_EXP_COST_RECOVERY_CHARGES BOOLEAN := TRUE;
v_REACTIVE_SERVICES_SUMMARY BOOLEAN := TRUE;
v_OPER_RESERVES_SUMMARY BOOLEAN := TRUE;
v_DAILY_OPRES_GEN_CREDITS BOOLEAN := TRUE;
v_DLY_OPRES_LOST_OPP BOOLEAN := TRUE;
v_LOSSES_CHARGES BOOLEAN := TRUE;
v_LOSSES_CREDITS BOOLEAN := TRUE;
v_TRANS_REVENUE_NEUTRALITY BOOLEAN := TRUE;
v_MONTHLY_CREDIT_ALLOC BOOLEAN := TRUE;
v_SYNC_CONDENSING_SUMMARY BOOLEAN := TRUE;
v_REGULATION_SUMMARY BOOLEAN := TRUE;
v_FTR_TARGET_ALLOCATIONS BOOLEAN := TRUE;
v_FTR_AUCTION BOOLEAN := TRUE;
v_BLACK_START_SUMMARY BOOLEAN := TRUE;
v_ARR_SUMMARY BOOLEAN := TRUE;
v_REACTIVE_SUMMARY BOOLEAN := TRUE;
v_ENGY_IMBALANCE_CRED_ALLOC BOOLEAN := TRUE;
v_CAP_CREDIT_MARKET_SUMMARY BOOLEAN := TRUE;
v_SYNC_RESERVE_SUMMARY BOOLEAN := TRUE;
v_EXP_CONGESTION_CHARGES BOOLEAN := TRUE;
v_FIRM_TRANS_SERVICE_CHAR BOOLEAN := TRUE;
v_NON_FIRM_TRANS_SER_CHAR BOOLEAN := TRUE;
v_SCHEDULE_1_CHARGES BOOLEAN := TRUE;
v_SCHEDULE_1A_CHARGES BOOLEAN := TRUE;
v_ENERGY_CHAR_RECON BOOLEAN := TRUE;
v_REGULATION_CHARGES BOOLEAN := TRUE;
v_SYNC_RESERVE_CHARGES BOOLEAN := TRUE;
v_TRANS_LOSSES_CREDITS BOOLEAN := TRUE;
v_EXPLICIT_LOSS_SUMMARY BOOLEAN := TRUE;
v_TRANS_LOSS_CHARGE_SUMMARY BOOLEAN := TRUE;
v_TRANS_LOSS_CREDIT_SUMMARY BOOLEAN := TRUE;
v_ENGY_CONG_LOSSES_CHARGES BOOLEAN := TRUE;
v_INADVERT_INTER_SUMMARY BOOLEAN := TRUE;
v_EDC_INADVERT_ALLOCATIONS BOOLEAN := TRUE;
v_LOAD_ESCHED_W_O_LOSSES BOOLEAN := TRUE;
v_EDC_HOUR_LOSS_DERATION BOOLEAN := TRUE;
v_LOAD_RESP_MONTHLY_SUMMARY BOOLEAN := TRUE;
v_METER_CORR_CHARGE_SUMMARY BOOLEAN := TRUE;
v_METER_CORR_ALLOC_CHARGE BOOLEAN := TRUE;
v_SCHEDULE_1A_SUMMARY BOOLEAN := TRUE;
v_DAY_AHEAD_DAILY_TRANS BOOLEAN := TRUE;
v_REAL_TIME_DLY_TRANS BOOLEAN := TRUE;
v_RPM_AUCTION_SUMMARY BOOLEAN := TRUE;

BEGIN
	p_STATUS := 0;

	IF p_EXCHANGE_TYPE = g_ET_IMP_SETTLEMENT_STMT THEN
		-- download the monthly lmp's, real-time and day-ahead
		MM_PJM_LMP.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE, 'MM'), TRUNC(p_END_DATE, 'MM'), MM_PJM_LMP.g_ET_REAL_TIME_LMP_MONTH,
			p_LOG_TYPE, p_TRACE_ON,p_STATUS,p_MESSAGE);

		MM_PJM_LMP.MARKET_EXCHANGE(TRUNC(p_BEGIN_DATE, 'MM'), TRUNC(p_END_DATE, 'MM'), MM_PJM_LMP.g_ET_DAY_AHEAD_LMP_MONTH,
			p_LOG_TYPE, p_TRACE_ON,p_STATUS,p_MESSAGE);

		--get reconciliation data
		MM_PJM_ESCHED.MARKET_EXCHANGE(p_BEGIN_DATE,
										   p_END_DATE,
										   MM_PJM_ESCHED.g_ET_QUERY_RECON_DATA,
										   NULL, --Entity List
										   NULL, -- Entity List Delimitor
										   p_LOG_ONLY,
										   p_LOG_TYPE,
										   p_TRACE_ON,
										   p_STATUS,
										   p_MESSAGE);
	ELSE
		v_MONTHLY_BILLING_STATEMENT 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_MONTHLY_BILLING_STATEMENT;
		v_SPOT_MKT_ENERGY_SUMMARY 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SPOT_MKT_ENERGY_SUMMARY;
		v_CONGESTION_SUMMARY 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_CONGESTION_SUMMARY;
		v_SCHEDULE_9_AND_10_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_9_AND_10_SUMMARY;
		v_NET_TRANS_SERVICE_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_NET_TRANS_SERVICE_SUMMARY;
		v_EXP_COST_RECOVERY_CHARGES 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_EXP_COST_RECOVERY_CHARGES;
		v_REACTIVE_SERVICES_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_REACTIVE_SERVICES_SUMMARY;
		v_OPER_RESERVES_SUMMARY 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_OPER_RESERVES_SUMMARY;
		v_DAILY_OPRES_GEN_CREDITS 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_DAILY_OPRES_GEN_CREDITS;
		v_DLY_OPRES_LOST_OPP 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_DLY_OPRES_LOST_OPP;
		v_LOSSES_CHARGES 					:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_LOSSES_CHARGES;
		v_LOSSES_CREDITS 					:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_LOSSES_CREDITS;
		v_TRANS_REVENUE_NEUTRALITY 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_TRANS_REVENUE_NEUTRALITY;
		v_MONTHLY_CREDIT_ALLOC 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_MONTHLY_CREDIT_ALLOC;
		v_SYNC_CONDENSING_SUMMARY 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SYNC_CONDENSING_SUMMARY;
		v_REGULATION_SUMMARY 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_REGULATION_SUMMARY;
		v_FTR_TARGET_ALLOCATIONS 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_FTR_TARGET_ALLOCATIONS;
		v_FTR_AUCTION 						:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_FTR_AUCTION;
		v_BLACK_START_SUMMARY 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_BLACK_START_SUMMARY;
		v_ARR_SUMMARY 						:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_ARR_SUMMARY;
		v_REACTIVE_SUMMARY 					:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_REACTIVE_SUMMARY;
		v_ENGY_IMBALANCE_CRED_ALLOC 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_ENGY_IMBALANCE_CRED_ALLOC;
		v_CAP_CREDIT_MARKET_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_CAP_CREDIT_MARKET_SUMMARY;
		v_SYNC_RESERVE_SUMMARY 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SYNC_RESERVE_SUMMARY;
		v_EXP_CONGESTION_CHARGES 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_EXP_CONGESTION_CHARGES;
		v_FIRM_TRANS_SERVICE_CHAR 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_FIRM_TRANS_SERVICE_CHAR;
		v_NON_FIRM_TRANS_SER_CHAR			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_NON_FIRM_TRANS_SER_CHAR;
		v_SCHEDULE_1_CHARGES 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_1_CHARGES;
		v_SCHEDULE_1A_CHARGES 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_1A_CHARGES;
		v_ENERGY_CHAR_RECON 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_ENERGY_CHAR_RECON;
		v_REGULATION_CHARGES 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_REGULATION_CHARGES;
		v_SYNC_RESERVE_CHARGES 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SYNC_RESERVE_CHARGES;
		v_TRANS_LOSSES_CREDITS 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_TRANS_LOSSES_CREDITS;
		v_EXPLICIT_LOSS_SUMMARY 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_EXPLICIT_LOSS_SUMMARY;
		v_TRANS_LOSS_CHARGE_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_TRANS_LOSS_CHARGE_SUMMARY;
		v_TRANS_LOSS_CREDIT_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_TRANS_LOSS_CREDIT_SUMMARY;
		v_ENGY_CONG_LOSSES_CHARGES 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_ENGY_CONG_LOSSES_CHARGES;
		v_INADVERT_INTER_SUMMARY 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_INADVERT_INTER_SUMMARY;
		v_EDC_INADVERT_ALLOCATIONS 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_EDC_INADVERT_ALLOCATIONS;
		v_LOAD_ESCHED_W_O_LOSSES 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_LOAD_ESCHED_W_O_LOSSES;
		v_EDC_HOUR_LOSS_DERATION 			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_EDC_HOUR_LOSS_DERATION;
		v_LOAD_RESP_MONTHLY_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_LOAD_RESP_MONTHLY_SUMMARY;
		v_METER_CORR_CHARGE_SUMMARY 		:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_METER_CORR_CHARGE_SUMMARY;
		v_METER_CORR_ALLOC_CHARGE			:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_METER_CORR_ALLOC_CHARGE;
		v_SCHEDULE_1A_SUMMARY 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_1A_SUMMARY;
        v_RPM_AUCTION_SUMMARY 				:= p_EXCHANGE_TYPE = MEX_PJM_SETTLEMENT_MSRS.g_ET_RPM_AUCTION_SUMMARY;

		v_DAY_AHEAD_DAILY_TRANS				:= p_EXCHANGE_TYPE = MEX_PJM_ESCHED.g_ET_DAY_AHEAD_DAILY_TRANS;
		v_REAL_TIME_DLY_TRANS				:= p_EXCHANGE_TYPE = MEX_PJM_ESCHED.g_ET_REAL_TIME_DLY_TRANS;
	END IF;


	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_PJM,
		p_PROCESS_NAME => 'PJM:SETTLEMENT',
		p_EXCHANGE_NAME => 'IMPORT_ENTIRE_STATEMENT', -- Replaced by IMPORT procedures
		p_LOG_TYPE => p_LOG_TYPE,
		p_TRACE_ON => p_TRACE_ON,
		p_CREDENTIALS => v_CREDS,
		p_LOGGER => v_LOGGER);

	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	WHILE v_CREDS.HAS_NEXT LOOP
		v_CRED := v_CREDS.GET_NEXT;
		IF v_MONTHLY_BILLING_STATEMENT 	THEN IMPORT_MONTHLY_STATEMENT(v_CRED, p_BEGIN_DATE,p_LOG_ONLY, p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_MONTHLY_BILLING_STATEMENT || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
    	IF v_SPOT_MKT_ENERGY_SUMMARY   	THEN IMPORT_SPOT_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SPOT_MKT_ENERGY_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_CONGESTION_SUMMARY 	   	THEN IMPORT_CONGESTION_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_CONGESTION_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_SCHEDULE_9_AND_10_SUMMARY 	THEN IMPORT_SCHEDULE9_10_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_9_AND_10_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_NET_TRANS_SERVICE_SUMMARY 	THEN IMPORT_NITS_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_NET_TRANS_SERVICE_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_OPER_RESERVES_SUMMARY 	   	THEN IMPORT_OP_RES_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_OPER_RESERVES_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_FTR_TARGET_ALLOCATIONS 	THEN IMPORT_FTR_TARGET_ALLOCATION(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_FTR_TARGET_ALLOCATIONS || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;

		IF v_TRANS_LOSS_CHARGE_SUMMARY 	THEN IMPORT_TRANS_LOSS_CHARGES(v_CRED, p_BEGIN_DATE, p_LOG_ONLY,p_STATUS, p_MESSAGE,v_LOGGER); END IF;
        	IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_TRANS_LOSS_CHARGE_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
       IF v_EXPLICIT_LOSS_SUMMARY 		THEN IMPORT_EXPLICIT_LOSSES(v_CRED, p_BEGIN_DATE, p_LOG_ONLY,p_STATUS, p_MESSAGE,v_LOGGER); END IF;
        	IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_EXPLICIT_LOSS_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
       IF v_INADVERT_INTER_SUMMARY 	THEN IMPORT_INADVERTENT_INTERCHANGE(v_CRED, p_BEGIN_DATE,p_LOG_ONLY, p_STATUS, p_MESSAGE,v_LOGGER); END IF;
        	IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_INADVERT_INTER_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
       IF v_TRANS_LOSS_CREDIT_SUMMARY 	THEN IMPORT_TRANS_LOSS_CREDITS(v_CRED, p_BEGIN_DATE, p_LOG_ONLY,p_STATUS, p_MESSAGE,v_LOGGER); END IF;
        	IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_TRANS_LOSS_CREDIT_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;

		IF v_FTR_AUCTION 				THEN IMPORT_FTR_AUCTION(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_FTR_AUCTION || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_DAY_AHEAD_DAILY_TRANS 		THEN IMPORT_DA_DAILY_TX(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_ESCHED.g_ET_DAY_AHEAD_DAILY_TRANS || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_REAL_TIME_DLY_TRANS 		THEN IMPORT_RT_DAILY_TX(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_ESCHED.g_ET_REAL_TIME_DLY_TRANS || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
    	IF v_EXP_CONGESTION_CHARGES 	THEN IMPORT_EXPLICIT_CONGESTION(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_EXP_CONGESTION_CHARGES || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_FIRM_TRANS_SERVICE_CHAR 	THEN IMPORT_FIRM_TRANS_SERV_CHARGES(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_FIRM_TRANS_SERVICE_CHAR || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_SCHEDULE_1A_SUMMARY 		THEN IMPORT_SCHEDULE1A_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_1A_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;

		IF v_MONTHLY_CREDIT_ALLOC 		THEN IMPORT_MONTHLY_CREDIT_ALLOC(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_MONTHLY_CREDIT_ALLOC || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_BLACK_START_SUMMARY 		THEN IMPORT_BLACK_START_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_BLACK_START_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_ARR_SUMMARY 				THEN IMPORT_ARR_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_ARR_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;

		-- not implemented yet
		--IF p_STATUS = MEX_UTIL.g_SUCCESS THEN IF v_MONTHLY_BILLING_STATEMENT THEN IMPORT_EN_IMB_CRE_SUMMARY(v_CRED, p_BEGIN_DATE,p_END_DATE,p_STATUS,p_MESSAGE,v_LOGGER); END IF; END IF;
		--IF p_STATUS = MEX_UTIL.g_SUCCESS THEN IF v_MONTHLY_BILLING_STATEMENT THEN IMPORT_CAP_CRED_SUMMARY(v_CRED, p_BEGIN_DATE,p_END_DATE,p_STATUS,p_MESSAGE,v_LOGGER); END IF; END IF;

    	IF v_SYNC_RESERVE_SUMMARY 		THEN IMPORT_SPIN_RES_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SYNC_RESERVE_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_ENGY_IMBALANCE_CRED_ALLOC 	THEN IMPORT_REACTIVE_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_ENGY_IMBALANCE_CRED_ALLOC || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_REACTIVE_SERVICES_SUMMARY 	THEN IMPORT_REACTIVE_SERV_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_REACTIVE_SERVICES_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_SYNC_CONDENSING_SUMMARY 	THEN IMPORT_SYNCH_CONDENS_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SYNC_CONDENSING_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;

		IF v_REGULATION_SUMMARY 		THEN IMPORT_REGULATION_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_REGULATION_SUMMARY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_NON_FIRM_TRANS_SER_CHAR 	THEN IMPORT_NON_FM_TRANS_SV_CHARGES(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_NON_FIRM_TRANS_SER_CHAR || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_DAILY_OPRES_GEN_CREDITS 	THEN IMPORT_OP_RES_GEN_CREDITS(v_CRED, p_BEGIN_DATE,p_END_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_DAILY_OPRES_GEN_CREDITS || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_DLY_OPRES_LOST_OPP 		THEN IMPORT_OP_RES_LOST_OPP_COST(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_DLY_OPRES_LOST_OPP || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_TRANS_REVENUE_NEUTRALITY 	THEN IMPORT_TRANS_REVNEUT_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_TRANS_REVENUE_NEUTRALITY || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_EXP_COST_RECOVERY_CHARGES 	THEN IMPORT_EXPANSION_COST_SUMMARY(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_EXP_COST_RECOVERY_CHARGES || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;

		IF v_SCHEDULE_1A_CHARGES 		THEN IMPORT_SCHEDULE1A_RECONCILE(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_1A_CHARGES || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_SCHEDULE_1_CHARGES 		THEN IMPORT_SCHEDULE1_RECONCILE(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SCHEDULE_1_CHARGES || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_ENGY_CONG_LOSSES_CHARGES 	THEN IMPORT_ENERGY_CH_RECONCIL(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_ENGY_CONG_LOSSES_CHARGES || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_REGULATION_CHARGES 		THEN IMPORT_REGULATION_CH_RECONCIL(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_REGULATION_CHARGES || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_SYNC_RESERVE_CHARGES 		THEN IMPORT_SPIN_RES_CH_RECONCIL(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_SYNC_RESERVE_CHARGES || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;
		IF v_TRANS_LOSSES_CREDITS 		THEN IMPORT_TRANS_LOSS_CR_RECONCIL(v_CRED, p_BEGIN_DATE,p_LOG_ONLY,p_STATUS,p_MESSAGE,v_LOGGER); END IF;
			IF(p_STATUS <> MEX_UTIL.g_SUCCESS) THEN v_LOGGER.LOG_ERROR(MEX_PJM_SETTLEMENT.g_ET_TRANS_LOSSES_CREDITS || ': ' || p_MESSAGE); p_STATUS := 0; p_MESSAGE := NULL; END IF;

	END LOOP;


	IF p_MESSAGE IS NOT NULL THEN
		v_LOGGER.LOG_ERROR(p_MESSAGE);
	END IF;
	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END IMPORT_ENTIRE_STATEMENT;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

BEGIN
	IMPORT_ENTIRE_STATEMENT(p_BEGIN_DATE, p_END_DATE, NVL(p_LOG_ONLY, 0), p_LOG_TYPE, p_TRACE_ON, p_STATUS, p_MESSAGE, p_EXCHANGE_TYPE);
END MARKET_EXCHANGE;
----------------------------------------------------------------------------------------------------

BEGIN
ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMKT Gen', 'INTERCHANGE_CONTRACT', 'String', TRUE, g_EMKT_GEN_ATTR);

	SELECT SC_ID INTO g_PJM_SC_ID
	FROM SCHEDULE_COORDINATOR
	WHERE SC_NAME = 'PJM';
EXCEPTION
	WHEN OTHERS THEN
		g_PJM_SC_ID := 0;

END MM_PJM_SETTLEMENT;
/
