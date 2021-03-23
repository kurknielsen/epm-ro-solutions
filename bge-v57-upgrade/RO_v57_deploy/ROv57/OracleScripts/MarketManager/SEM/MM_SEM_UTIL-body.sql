CREATE OR REPLACE PACKAGE BODY MM_SEM_UTIL IS
------------------------------------------------------------------------------
g_SC_ID NUMBER(9) := NULL;
g_SC_ALIAS VARCHAR2(4) := 'SEM';
c_IU_AGREEMENT_TYPE_DEFAULT CONSTANT VARCHAR2(3) := 'EA';

TYPE MAP_OF_IDs IS TABLE OF NUMBER_COLLECTION INDEX BY VARCHAR2(120);
g_CONTRACT_IDs MAP_OF_IDs;
------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.13 $';
END WHAT_VERSION;
------------------------------------------------------------------------------
FUNCTION GET_SERVICE_POINT_ID
(
    p_RESOURCE_NAME       IN VARCHAR2,
    p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
) RETURN NUMBER IS
    v_RET NUMBER;
BEGIN

    RETURN EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_RESOURCE_NAME,
                                            EC.ED_SERVICE_POINT,
                                            EC.ES_SEM);

EXCEPTION
    WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
        IF p_CREATE_IF_NOT_FOUND THEN

            SAVEPOINT BEFORE_PUT_SERVICE_POINT;

            -- not found? create it
            IO.PUT_SERVICE_POINT(v_RET, --                O_OID,
                                 p_RESOURCE_NAME, --      P_SERVICE_POINT_NAME,
                                 p_RESOURCE_NAME, --      P_SERVICE_POINT_ALIAS,
                                 p_RESOURCE_NAME, --      P_SERVICE_POINT_DESC,
                                 0, --            P_SERVICE_POINT_ID,
                                 'Wholesale', --        P_SERVICE_POINT_TYPE,
                                 0, --            P_TP_ID,
                                 0, --            P_CA_ID,
                                 0, --            P_EDC_ID,
                                 0, --            P_ROLLUP_ID,
                                 0, --            P_SERVICE_REGION_ID,
                                 0, --            P_SERVICE_AREA_ID,
                                 0, --            P_SERVICE_ZONE_ID,
                                 g_TZ, --           P_TIME_ZONE,
                                 NULL, --           P_LATITUDE,
                                 NULL, --           P_LONGITUDE,
                                 p_RESOURCE_NAME, --      P_EXTERNAL_IDENTIFIER,
                                 0, --            P_IS_INTERCONNECT,
                                 NULL, --           P_NODE_TYPE,
                                 NULL, --           P_SERVICE_POINT_NERC_CODE,
                                 0, --            P_PIPELINE_ID,
                                 0 --             P_MILE_MARKER
                                 );

            IF v_RET <= 0 THEN
                RAISE_ERR(v_RET,
                          'Could not create service point (for resource name = ' ||
                          p_RESOURCE_NAME || ')');
            ELSE
                -- save external identifier, too
                BEGIN
                    EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_SEM,
                                                      EC.ED_SERVICE_POINT,
                                                      v_RET,
                                                      p_RESOURCE_NAME);
                    RETURN v_RET;
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK TO BEFORE_PUT_SERVICE_POINT; -- undo the creation of the service point
                        RAISE;
                END;
            END IF;

        ELSE
            RAISE;
        END IF;

END GET_SERVICE_POINT_ID;
------------------------------------------------------------------------------
FUNCTION GET_ESP_ID
(
    p_RESOURCE_NAME       IN VARCHAR2,
    p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
) RETURN NUMBER IS
    v_RET NUMBER;
BEGIN

 	RETURN EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_RESOURCE_NAME,
                                            EC.ED_ESP,
                                            EC.ES_SEM);
	EXCEPTION
   		WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
        	IF p_CREATE_IF_NOT_FOUND THEN

            SAVEPOINT BEFORE_PUT_ESP;

            -- not found? create it
			 IO.PUT_ESP
					(
					v_RET,
					p_RESOURCE_NAME,
					p_RESOURCE_NAME, -- ALIAS
					p_RESOURCE_NAME, -- DESC
					0,
					p_RESOURCE_NAME, -- ESP_EXTERNAL_IDENTIFIER
					GA.UNDEFINED_ATTRIBUTE, -- DUNS
					'Active', 	 -- STATUS
					'Certified', -- TYPE
					0
					);

            IF v_RET <= 0 THEN
                RAISE_ERR(v_RET,
                          'Could not create esp (for resource name = ' ||
                          p_RESOURCE_NAME || ')');
            ELSE
                -- save external identifier, too
                BEGIN
                    EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_SEM,
                                                      EC.ED_ESP,
                                                      v_RET,
                                                      p_RESOURCE_NAME);
                    RETURN v_RET;
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK TO BEFORE_PUT_ESP; -- undo the creation of the esp
                        RAISE;
                END;
            END IF;

        ELSE
            RAISE;
        END IF;

END GET_ESP_ID;
------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_ID
    (
    p_TRANSACTION_TYPE    IN VARCHAR2,
    p_RESOURCE_NAME       IN VARCHAR2 := NULL,
    p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE,
	p_AGREEMENT_TYPE	  IN VARCHAR2 := NULL,
	p_TRANSACTION_NAME	  IN VARCHAR2 := NULL,
	p_EXTERNAL_IDENTIFIER IN VARCHAR2 := NULL,
	p_ACCOUNT_NAME		  IN VARCHAR2 := '%',
	p_COMMODITY           IN VARCHAR2 := 'Energy',
	p_IS_BID_OFFER        IN NUMBER   := 1
    ) RETURN NUMBER IS

v_POD_ID NUMBER;
v_COMMODITY_ID NUMBER;
v_SC_ID NUMBER;
v_CONTRACT_ID NUMBER;
v_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_RET NUMBER;
v_IS_BID_OFFER NUMBER;
BEGIN
	v_NAME := NVL(p_TRANSACTION_NAME, g_SC_ALIAS||': '||p_TRANSACTION_TYPE||':'||p_RESOURCE_NAME);

	v_SC_ID := SEM_SC_ID;

	IF p_RESOURCE_NAME IS NULL THEN
		v_POD_ID := 0; -- not assigned
	ELSE
		v_POD_ID := GET_SERVICE_POINT_ID(p_RESOURCE_NAME, p_CREATE_IF_NOT_FOUND);
	END IF;

	v_COMMODITY_ID := EI.GET_ID_FROM_ALIAS(CASE WHEN p_TRANSACTION_TYPE IN ('Capacity Holdings', 'Eligible Avail.') THEN 'Capacity'
												WHEN p_TRANSACTION_TYPE IN ('Generation', 'Dispatch Instr.') THEN p_COMMODITY
                                                ELSE NVL(p_COMMODITY, 'Energy') END, EC.ED_IT_COMMODITY);

	--Viridian has several custom transactions that are created from PIR determinants
	--if new transactions then set is_bid_offer attribute to 0
    IF p_IS_BID_OFFER = 1 THEN
    	--use current logic
    	v_IS_BID_OFFER := CASE WHEN p_RESOURCE_NAME IS NULL THEN 0 ELSE 1 END;
    ELSIF p_IS_BID_OFFER = 0 THEN
    	v_IS_BID_OFFER := 0;
    END IF;

	IF p_EXTERNAL_IDENTIFIER IS NULL AND v_POD_ID = 0 THEN
		-- don't have external identifier or POD for lookup?
		-- then do lookup by name
		RETURN EI.GET_ID_FROM_NAME(v_NAME, EC.ED_TRANSACTION);
	ELSIF p_EXTERNAL_IDENTIFIER IS NULL THEN
		-- no external identifier but there is a POD?
		-- lookup transaction by type and POD
		-- VERY IMPORTANT CHANGE: The lookup with AGREEMENT_TYPE will be done like this hereafter and if it is NULL then:
			-- (1) first attempt will be made with "EA" being default value for AGREEMENT_TYPE,
			-- (2) second attemplt will be made with "?" being default value for the AGREEMENT_TYPE, and finally
			-- (3) third attempt will be made with NULL being the default value for the AGREEMENT_TYPE
		-- If all 3 attempts fail, then the error will be raised and logged
		BEGIN
			-- 1st attempt: If agreement_type is NULL, then pass "EA" as default value
			SELECT TRANSACTION_ID
			INTO v_RET
			FROM INTERCHANGE_TRANSACTION
			WHERE POD_ID = v_POD_ID
				AND SC_ID = v_SC_ID
				AND TRANSACTION_TYPE = p_TRANSACTION_TYPE
				AND COMMODITY_ID = v_COMMODITY_ID
				AND AGREEMENT_TYPE = NVL(p_AGREEMENT_TYPE, c_IU_AGREEMENT_TYPE_DEFAULT);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				BEGIN
					-- 2nd attempt: If agreement_type is NULL, then pass "?" as default value
					SELECT TRANSACTION_ID
					INTO v_RET
					FROM INTERCHANGE_TRANSACTION
					WHERE POD_ID = v_POD_ID
						AND SC_ID = v_SC_ID
						AND TRANSACTION_TYPE = p_TRANSACTION_TYPE
						AND COMMODITY_ID = v_COMMODITY_ID
						AND AGREEMENT_TYPE = NVL(p_AGREEMENT_TYPE, CONSTANTS.UNDEFINED_ATTRIBUTE);
				EXCEPTION
					WHEN NO_DATA_FOUND THEN
						-- 3rd attempt: If agreement_type is NULL, then pass NULL as default value
						SELECT TRANSACTION_ID
						INTO v_RET
						FROM INTERCHANGE_TRANSACTION
						WHERE POD_ID = v_POD_ID
							AND SC_ID = v_SC_ID
							AND TRANSACTION_TYPE = p_TRANSACTION_TYPE
							AND COMMODITY_ID = v_COMMODITY_ID
							AND NVL(AGREEMENT_TYPE, c_IU_AGREEMENT_TYPE_DEFAULT) = NVL(p_AGREEMENT_TYPE, c_IU_AGREEMENT_TYPE_DEFAULT);
				END;
		END;
		RETURN v_RET;
	ELSE
    	-- lookup by external identifier
    	RETURN EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_EXTERNAL_IDENTIFIER,
    											EC.ED_TRANSACTION,
    				  							EC.ES_SEM);
	END IF;

EXCEPTION
	WHEN NO_DATA_FOUND OR MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		IF p_CREATE_IF_NOT_FOUND THEN
			IF p_ACCOUNT_NAME <> '%' THEN
    			v_CONTRACT_ID := SEM_CONTRACT_ID(p_ACCOUNT_NAME);

    			IF v_CONTRACT_ID IS NULL THEN
    				RAISE;
    			END IF;
			ELSE
				v_CONTRACT_ID := 0;
			END IF;

			EM.PUT_TRANSACTION(
                v_RET,--O_OID,
                v_NAME,--P_TRANSACTION_NAME,
                NVL(p_EXTERNAL_IDENTIFIER,p_TRANSACTION_TYPE||': '||p_RESOURCE_NAME),--P_TRANSACTION_ALIAS,
                NVL(p_EXTERNAL_IDENTIFIER,p_TRANSACTION_TYPE||': '||p_RESOURCE_NAME),--P_TRANSACTION_DESC,
                0,--P_TRANSACTION_ID,
				'Active',--P_TRANSACTION_STATUS
                p_TRANSACTION_TYPE,
                NVL(p_EXTERNAL_IDENTIFIER,p_TRANSACTION_TYPE||': '||p_RESOURCE_NAME),--P_TRANSACTION_IDENTIFIER,
                0,--P_IS_FIRM,
                0,--P_IS_IMPORT_SCHEDULE,
                0,--P_IS_EXPORT_SCHEDULE,
                0,--P_IS_BALANCE_TRANSACTION,
                v_IS_BID_OFFER,--   CASE WHEN p_RESOURCE_NAME IS NULL THEN 0 ELSE 1 END,--P_IS_BID_OFFER,
                0,--P_IS_EXCLUDE_FROM_POSITION,
                CASE WHEN p_TRANSACTION_TYPE IN ('Nomination','Capacity Holdings') THEN 1 ELSE 0 END,--P_IS_IMPORT_EXPORT,
                0,--P_IS_DISPATCHABLE,
                '30 Minute',--P_TRANSACTION_INTERVAL,
                CASE WHEN p_TRANSACTION_TYPE = 'Nomination' THEN '30 Minute' ELSE 'Day' END,--P_EXTERNAL_INTERVAL,
                NULL,--P_ETAG_CODE,
                LOW_DATE,--P_BEGIN_DATE,
                HIGH_DATE,--p_END_DATE,
                0,--P_PURCHASER_ID,
                0,--P_SELLER_ID,
                v_CONTRACT_ID,--P_CONTRACT_ID,
                v_SC_ID,--P_SC_ID,
                0,--P_POR_ID,
                v_POD_ID,--P_POD_ID,
                v_COMMODITY_ID,-- P_COMMODITY_ID,
                0,--P_SERVICE_TYPE_ID,
                0,--P_TX_TRANSACTION_ID,
                0,--P_PATH_ID,
                0,--P_LINK_TRANSACTION_ID,
                0,--P_EDC_ID,
                0,--P_PSE_ID,
                0,--P_ESP_ID,
                0,--P_POOL_ID,
                0,--P_SCHEDULE_GROUP_ID,
                0,--P_MARKET_PRICE_ID,
                0,--P_ZOR_ID,
                0,--P_ZOD_ID,
                0,--P_SOURCE_ID,
                0,--P_SINK_ID,
                0,--P_RESOURCE_ID,
                p_AGREEMENT_TYPE,--P_AGREEMENT_TYPE,
                NULL,--P_APPROVAL_TYPE,
                NULL,--P_LOSS_OPTION,
                p_TRANSACTION_TYPE,--P_TRAIT_CATEGORY,
                0--P_TP_ID
				);
			RETURN v_RET;
		ELSE
            ERRS.LOG_AND_CONTINUE
            (
                p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG_DETAIL, 
                p_EXTRA_MESSAGE => 'No transaction found for POD_ID = ' || v_POD_ID || ', SC_ID = ' || v_SC_ID ||
							       ', TRANSACTION_TYPE = ' || p_TRANSACTION_TYPE || ', COMMODITY_ID = ' || v_COMMODITY_ID ||
							       ', AGREEMENT_TYPE = ' || NVL(p_AGREEMENT_TYPE, c_IU_AGREEMENT_TYPE_DEFAULT)
            );
            RETURN NULL;
		END IF;
END GET_TRANSACTION_ID;
------------------------------------------------------------------------------
/*------------------------------------------------------------------------------
This version of GET_TRANSACTION_ID is intended to be used when we expect the
transaction to have already been created by other means. Unfortunately, we are
not consistent in how we set up our transaction identifiers, so sometimes
we can't find the transactions we're looking for using the other signature,
and can get name collisions or get two transactions where really we need one.
Here, if we can't find the transaction we return NULL; if there's more than
one that fits the bill, we return the first one we find (lowest txn id).
------------------------------------------------------------------------------*/
FUNCTION GET_TRANSACTION_ID
    (
    p_TRANSACTION_TYPE    IN VARCHAR2,
    p_RESOURCE_NAME       IN VARCHAR2,
	p_COMMODITY_NAME      IN VARCHAR2,
	p_AGREEMENT_TYPE	  IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
v_POD_ID NUMBER;
v_COMMODITY_ID NUMBER;
v_SC_ID NUMBER;
v_RET NUMBER;
BEGIN
	v_SC_ID := SEM_SC_ID;
	v_POD_ID := GET_SERVICE_POINT_ID(p_RESOURCE_NAME, FALSE);
	v_COMMODITY_ID := EI.GET_ID_FROM_ALIAS(CASE WHEN p_TRANSACTION_TYPE IN ('Capacity Holdings', 'Eligible Avail.') THEN 'Capacity'
												WHEN p_TRANSACTION_TYPE IN ('Generation', 'Dispatch Instr.') THEN p_COMMODITY_NAME
                                                ELSE NVL(p_COMMODITY_NAME, 'Energy') END, EC.ED_IT_COMMODITY);

	SELECT TRANSACTION_ID INTO v_RET FROM
	(SELECT TRANSACTION_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE POD_ID = v_POD_ID
		AND SC_ID = v_SC_ID
		AND TRANSACTION_TYPE = p_TRANSACTION_TYPE
		AND COMMODITY_ID = v_COMMODITY_ID
		AND NVL(AGREEMENT_TYPE, GA.UNDEFINED_ATTRIBUTE) = NVL(p_AGREEMENT_TYPE, GA.UNDEFINED_ATTRIBUTE)
	ORDER BY 1)
	WHERE ROWNUM=1;

	RETURN v_RET;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
END GET_TRANSACTION_ID;
------------------------------------------------------------------------------
FUNCTION GET_SCHEDULE_DATE
	(
	p_OPERATING_DATE IN DATE,
	p_OPERATING_HOUR IN NUMBER,
	p_OPERATING_INTERVAL IN NUMBER,
	p_IS_TRADING_DAY IN NUMBER := 0,
    p_IS_CO_CSV_FILE IN NUMBER DEFAULT 0
	) RETURN DATE IS
v_OPERATING_DATE DATE := p_OPERATING_DATE;
v_DATE DATE;
BEGIN
	-- Trading Day is from HE 7 on the specified day through HE 6 of day+1
	IF p_IS_TRADING_DAY = 1 AND NOT p_OPERATING_HOUR BETWEEN 7 and 24 THEN
		v_OPERATING_DATE := v_OPERATING_DATE + 1;
	END IF;

	-- Hours are 1 to 24 for normal days.
	-- Hours are 1 to 24 but 2 is skipped for DST short day.
    --       ( RSA -- this assumption is invalid for CO-CSV file,where hrs are contiguous)
	-- Hours are 1 to 24 for DST long day, with hour 25 indicating the repeated hour 2.

	IF p_OPERATING_HOUR = 0 AND p_OPERATING_INTERVAL = 0 THEN
		v_DATE := TRUNC(p_OPERATING_DATE) + 1/86400;
	ELSE
    	IF TRUNC(DST_SPRING_AHEAD_DATE(v_OPERATING_DATE)) = TRUNC(v_OPERATING_DATE) THEN
    		v_DATE := TO_CUT(TRUNC(v_OPERATING_DATE), g_TZ) + p_OPERATING_HOUR/24;
            -- RSA -- 05/15/2007 -- Do this only for all other cases, other than CO-CSV offer file import
			IF p_IS_CO_CSV_FILE = 0 AND p_OPERATING_HOUR > 2 THEN
				v_DATE := v_DATE-1/24;
			END IF;
    	ELSIF TRUNC(DST_FALL_BACK_DATE(v_OPERATING_DATE)) = TRUNC(v_OPERATING_DATE) AND p_OPERATING_HOUR = 25 THEN
    		v_DATE := TO_CUT(TRUNC(v_OPERATING_DATE) + 2/24, g_TZ) + 1/24;
		ELSE
    		v_DATE := TO_CUT(TRUNC(v_OPERATING_DATE) + p_OPERATING_HOUR/24, g_TZ);
    	END IF;
		IF p_OPERATING_INTERVAL <> 0 THEN
			v_DATE := v_DATE - 1/24 + (30*p_OPERATING_INTERVAL)/1440;
		END IF;
	END IF;

	RETURN v_DATE;
END GET_SCHEDULE_DATE;
------------------------------------------------------------------------------
FUNCTION GET_TRADING_DAY
	(
	p_CUT_DATE IN DATE
	) RETURN DATE IS
v_DATE DATE := FROM_CUT(p_CUT_DATE, g_TZ);
BEGIN
	IF v_DATE-TRUNC(v_DATE-1/86400) <= 6/24 THEN
		v_DATE := v_DATE-1;
	END IF;
	RETURN TRUNC(v_DATE-1/86400);
END GET_TRADING_DAY;
------------------------------------------------------------------------------
PROCEDURE GET_DATE_FIELDS
	(
	p_CUT_DATE IN DATE,
	p_DAY OUT VARCHAR2,
	p_HOUR OUT VARCHAR2,
	p_INTERVAL OUT VARCHAR2,
	p_IS_TRADING_DAY IN NUMBER := 0
	) IS
BEGIN
	p_DAY := GET_DAY_FROM_DATE(p_CUT_DATE, p_IS_TRADING_DAY);
	p_HOUR := GET_HOUR_FROM_DATE(p_CUT_DATE);
	p_INTERVAL := GET_INTERVAL_FROM_DATE(p_CUT_DATE);
END GET_DATE_FIELDS;
------------------------------------------------------------------------------
FUNCTION GET_DAY_FROM_DATE
	(
	p_CUT_DATE IN DATE,
	p_IS_TRADING_DAY IN NUMBER := 0
	) RETURN VARCHAR2 IS
v_DATE DATE;
BEGIN
	IF p_IS_TRADING_DAY = 1 THEN
		v_DATE := GET_TRADING_DAY(p_CUT_DATE);
	ELSE
		v_DATE := FROM_CUT(p_CUT_DATE, g_TZ)-1/86400;
	END IF;
	RETURN TO_CHAR(v_DATE, g_DATE_FORMAT);
END GET_DAY_FROM_DATE;
------------------------------------------------------------------------------
FUNCTION GET_HOUR_FROM_DATE
	(
	p_CUT_DATE IN DATE
	) RETURN NUMBER IS
v_LOCAL_DATE DATE := FROM_CUT(p_CUT_DATE, g_TZ);
v_CUT_DAY DATE := TO_CUT(TRUNC(v_LOCAL_DATE-1/86400), g_TZ); -- determine local midnight and shift to CUT
v_RET NUMBER;
BEGIN
	v_RET := TRUNC((p_CUT_DATE-v_CUT_DAY)*24+0.6); -- adding 0.6 makes sure we are rounding
			  								    -- 30 minute intervals to correct ending hour
   	IF TRUNC(DST_SPRING_AHEAD_DATE(v_LOCAL_DATE)) = TRUNC(v_LOCAL_DATE-1/86400) AND v_RET > 1 THEN
		RETURN v_RET+1;
	ELSIF TRUNC(DST_FALL_BACK_DATE(v_LOCAL_DATE)) = TRUNC(v_LOCAL_DATE-1/86400) THEN
		IF v_RET = 3 THEN
			RETURN 25;
		ELSIF v_RET > 3 THEN
			RETURN v_RET-1;
		ELSE
			RETURN v_RET;
		END IF;
	ELSE
		RETURN v_RET;
	END IF;

END GET_HOUR_FROM_DATE;
------------------------------------------------------------------------------
FUNCTION GET_INTERVAL_FROM_DATE
	(
	p_CUT_DATE IN DATE
	) RETURN NUMBER IS
BEGIN
	IF TO_NUMBER(TO_CHAR(p_CUT_DATE,'MI')) = 0 THEN
		RETURN 2;
	ELSE
		RETURN 1;
	END IF;
END GET_INTERVAL_FROM_DATE;
------------------------------------------------------------------------------
FUNCTION SEM_SC_ID RETURN NUMBER IS
BEGIN
	IF g_SC_ID IS NULL THEN
		-- query for the SC
		SELECT MAX(SC_ID)
		INTO g_SC_ID
		FROM SCHEDULE_COORDINATOR
		WHERE SC_ALIAS = g_SC_ALIAS;
	END IF;

	RETURN g_SC_ID;
END SEM_SC_ID;
------------------------------------------------------------------------------
FUNCTION SEM_CONTRACT_IDs(p_ACCOUNT_NAME IN VARCHAR2) RETURN NUMBER_COLLECTION IS
v_IDs NUMBER_COLLECTION;
BEGIN
	IF g_CONTRACT_IDs.EXISTS(p_ACCOUNT_NAME) THEN
            v_IDs := g_CONTRACT_IDs(p_ACCOUNT_NAME);
	ELSE
            -- query for the contract IDs
            v_IDs := EI.GET_IDs_FROM_IDENTIFIER_EXTSYS(p_ACCOUNT_NAME, EC.ED_INTERCHANGE_CONTRACT, EC.ES_SEM);
            g_CONTRACT_IDs(p_ACCOUNT_NAME) := v_IDs;
	END IF;

	RETURN v_IDs;
END SEM_CONTRACT_IDs;
------------------------------------------------------------------------------
FUNCTION SEM_CONTRACT_ID(p_ACCOUNT_NAME IN VARCHAR2) RETURN NUMBER IS
v_IDs NUMBER_COLLECTION;
BEGIN
	-- For creating new transactions, we need a contract. There will be several
	-- contracts per participant for shadow settlement purposes. So we'll just grab
	-- arbitrarily since it doesn't matter which one we use - as long as it is
	-- associated with the right participant account
    v_IDs := SEM_CONTRACT_IDs(p_ACCOUNT_NAME);
    IF v_IDs.COUNT > 0 THEN -- does collection have something in it?
        RETURN v_IDs(v_IDs.FIRST);
    ELSE
        RETURN NULL;
    END IF;
END SEM_CONTRACT_ID;
------------------------------------------------------------------------------
FUNCTION GET_PSE_ID
(
    p_PARTICIPANT_ID      IN VARCHAR2,
    p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE,
    p_PARTICIPANT_NAME    IN VARCHAR2 := NULL
) RETURN NUMBER IS
    v_PSE_ID   PURCHASING_SELLING_ENTITY.PSE_ID%TYPE;
    v_PSE_NAME PURCHASING_SELLING_ENTITY.PSE_NAME%TYPE;
BEGIN
    RETURN EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_PARTICIPANT_ID,
                                            EC.ED_PSE,
                                            EC.ES_SEM);
EXCEPTION
    WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
        IF p_CREATE_IF_NOT_FOUND THEN

            SAVEPOINT BEFORE_PUT_PSE;

            -- not found? create it
            v_PSE_NAME := NVL(p_PARTICIPANT_NAME || ' (' ||p_PARTICIPANT_ID || ')' , p_PARTICIPANT_ID);

            IO.PUT_PSE(v_PSE_ID, --o_OID
                       v_PSE_NAME, --p_PSE_NAME
                       p_PARTICIPANT_ID, --p_PSE_ALIAS
                       p_PARTICIPANT_NAME, --p_PSE_DESC
                       0, --p_PSE_ID
                       GA.UNDEFINED_ATTRIBUTE, --p_PSE_NERC_CODE
                       'Active', --p_PSE_STATUS
                       GA.UNDEFINED_ATTRIBUTE, --p_PSE_DUNS_NUMBER
                       GA.UNDEFINED_ATTRIBUTE, --p_PSE_BANK
                       GA.UNDEFINED_ATTRIBUTE, --p_PSE_ACH_NUMBER
                       'Marketer', --p_PSE_TYPE
                       p_PARTICIPANT_ID, --p_PSE_EXTERNAL_IDENTIFIER
                       0, --p_PSE_IS_RETAIL_AGGREGATOR
                       0, --p_PSE_IS_BACKUP_GENERATION
                       0, --p_PSE_EXCLUDE_LOAD_SCHEDULE
                       0, --p_IS_BILLING_ENTITY
                       'EST', --p_TIME_ZONE
                       'Day', --p_STATEMENT_INTERVAL
                       'Month', --p_INVOICE_INTERVAL
                       'First of Month', --p_WEEK_BEGIN
                       'By Product-Component', --p_INVOICE_LINE_ITEM_OPTION
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL,
					   NULL
					   );
            IF v_PSE_ID <= 0 THEN
                RAISE_ERR(v_PSE_ID,
                          'Could not create PSE (for participant name = ' ||
                          p_PARTICIPANT_ID || ')');
            ELSE
                -- save external identifier, too
                BEGIN
                    EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_SEM,
                                                      EC.ED_PSE,
                                                      v_PSE_ID,
                                                      p_PARTICIPANT_ID);
                    RETURN v_PSE_ID;
                EXCEPTION
                    WHEN OTHERS THEN
                        ROLLBACK TO BEFORE_PUT_PSE; -- undo the creation of the service point
                        RAISE;
                END;
            END IF;
        ELSE
            RAISE;
        END IF;

END GET_PSE_ID;
------------------------------------------------------------------------------
FUNCTION GET_MARKET_PRICE_ID
(
    p_MARKET_PRICE_NAME   IN VARCHAR2,
    p_MARKET_PRICE_TYPE   IN VARCHAR2,
    p_MARKET_PRICE_INTERVAL IN VARCHAR2,
    p_CREATE_IF_NOT_FOUND IN BOOLEAN
) RETURN NUMBER IS

    v_MARKET_PRICE_ID NUMBER := NULL;
    v_COMMODITY_ID    NUMBER(9);
    v_SC_ID           NUMBER(9);

BEGIN

    IF p_MARKET_PRICE_NAME IS NULL THEN
        v_MARKET_PRICE_ID := 0;
        RETURN v_MARKET_PRICE_ID;
    END IF;

    v_COMMODITY_ID := EI.GET_ID_FROM_ALIAS('Energy', EC.ED_IT_COMMODITY);
    v_SC_ID        := SEM_SC_ID;

	BEGIN
    	v_MARKET_PRICE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_MARKET_PRICE_NAME,
															 EC.ED_MARKET_PRICE,
															 EC.ES_SEM);
    EXCEPTION WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		IF p_CREATE_IF_NOT_FOUND THEN

			IO.PUT_MARKET_PRICE(v_MARKET_PRICE_ID,
								'SEM:' || p_MARKET_PRICE_NAME,
								NULL, -- ALIAS
								NULL, -- DESC
								0,
								p_MARKET_PRICE_TYPE, -- MARKET_PRICE_TYPE
								p_MARKET_PRICE_INTERVAL, --MARKET_PRICE_INTERVAL
								NULL, --MARKET_TYPE
								v_COMMODITY_ID,
								NULL, -- SERVICE_POINT_TYPE
								p_MARKET_PRICE_NAME, -- EXTERNAL_IDENTIFIER
								0, -- EDC_ID
								v_SC_ID, -- SC_ID
								0, -- POD_ID
								0);
			IF v_MARKET_PRICE_ID <= 0 THEN
				RAISE_ERR(v_MARKET_PRICE_ID,
										'Could not create market price (for name = ' ||
										p_MARKET_PRICE_NAME || ')');
			ELSE
				-- save external identifier for current market price entity
				EI.PUT_EXTERNAL_SYSTEM_IDENTIFIER(EC.ES_SEM,
												  EC.ED_MARKET_PRICE,
												  v_MARKET_PRICE_ID,
												  p_MARKET_PRICE_NAME);
			END IF;
		END IF;
    END;

    RETURN v_MARKET_PRICE_ID;

END GET_MARKET_PRICE_ID;
-------------------------------------------------------------------------------
PROCEDURE RAISE_ERR
    (
    p_SQLCODE IN PLS_INTEGER := NULL,
    p_SQLERRM IN VARCHAR2 := NULL
    ) IS
    v_SQLCODE PLS_INTEGER := NVL(p_SQLCODE, SQLCODE);
    v_SQLERRM VARCHAR2(1000) := NVL(p_SQLERRM, SQLERRM);
BEGIN
    -- Log the exception --
    IF v_SQLCODE BETWEEN - 20999 AND - 20000 THEN
        RAISE_APPLICATION_ERROR(v_SQLCODE, v_SQLERRM);
    ELSIF v_SQLCODE > 0 AND v_SQLCODE != 100 THEN
        RAISE_APPLICATION_ERROR(-20000, v_SQLCODE || '-' || v_SQLERRM);
        -- EXCEPTION_INIT -1403 is disallowed --
    ELSIF v_SQLCODE IN (100, -1403) THEN
        RAISE NO_DATA_FOUND;
        -- Re-raise any other exception --
    ELSIF v_SQLCODE != 0 THEN
        EXECUTE IMMEDIATE '   DECLARE x_CEPTION EXCEPTION; ' ||
                          '   PRAGMA EXCEPTION_INIT (x_CEPTION, ' ||
                          TO_CHAR(v_SQLCODE) || ');' ||
                          '   BEGIN  RAISE x_CEPTION; END;';
    END IF;
END RAISE_ERR;
-------------------------------------------------------------------------------
FUNCTION ERROR_STACKTRACE RETURN VARCHAR2 IS
BEGIN
	RETURN DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
END ERROR_STACKTRACE;
-------------------------------------------------------------------------------
FUNCTION GET_EXTERNAL_ACCOUNT_NAME
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN VARCHAR2 IS
v_CONTRACT_ID NUMBER;
BEGIN
	SELECT CONTRACT_ID
	INTO v_CONTRACT_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_INTERCHANGE_CONTRACT, v_CONTRACT_ID, EC.ES_SEM);

END GET_EXTERNAL_ACCOUNT_NAME;
-------------------------------------------------------------------------------
FUNCTION GET_RESOURCE_TYPE
	(
	p_TRANSACTION_ID IN NUMBER,
	p_DATE IN DATE
	) RETURN VARCHAR2 IS
v_POD_ID NUMBER;
BEGIN
	SELECT POD_ID
	INTO v_POD_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN RO.GET_ENTITY_ATTRIBUTE(g_EA_RESOURCE_TYPE, EC.ED_SERVICE_POINT, v_POD_ID, p_DATE);

END GET_RESOURCE_TYPE;
-------------------------------------------------------------------------------
FUNCTION IS_UNDER_TEST
	(
	p_TRANSACTION_ID IN NUMBER,
	p_DATE IN DATE
	) RETURN BOOLEAN IS
v_TRAIT_VAL NUMBER;
BEGIN
	SELECT NVL(MAX(TO_NUMBER(TRAIT_VAL)),0)
	INTO v_TRAIT_VAL
	FROM IT_TRAIT_SCHEDULE
	WHERE TRANSACTION_ID = p_TRANSACTION_ID
		AND SCHEDULE_STATE = GA.INTERNAL_STATE
		AND SCHEDULE_DATE = TRUNC(p_DATE)+1/86400
		AND TRAIT_GROUP_ID = g_TG_GEN_UNDER_TEST
		AND TRAIT_INDEX = 1
		AND SET_NUMBER = 1
		AND STATEMENT_TYPE_ID = 0;

	RETURN v_TRAIT_VAL <> 0;
END IS_UNDER_TEST;
-------------------------------------------------------------------------------
FUNCTION IS_STANDING_BID
	(
	p_TRANSACTION_ID IN NUMBER,
	p_DATE IN DATE
	) RETURN BOOLEAN IS
v_TRAIT_VAL NUMBER;
BEGIN
	SELECT NVL(MAX(CASE WHEN UPPER(NVL(TRAIT_VAL,'?')) IN ('?','NONE') THEN 0 ELSE 1 END),0)
	INTO v_TRAIT_VAL
	FROM IT_TRAIT_SCHEDULE
	WHERE TRANSACTION_ID = p_TRANSACTION_ID
		AND SCHEDULE_STATE = GA.INTERNAL_STATE
		AND SCHEDULE_DATE = TRUNC(p_DATE)+1/86400
		AND TRAIT_GROUP_ID = g_TG_STANDING_OFFER
		AND TRAIT_INDEX = g_TI_STANDING_TYPE
		AND SET_NUMBER = 1
		AND STATEMENT_TYPE_ID = 0;

	RETURN v_TRAIT_VAL <> 0;
END IS_STANDING_BID;
-------------------------------------------------------------------------------
FUNCTION IS_PUMPED_STORAGE
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN BOOLEAN IS
v_POD_ID NUMBER;
BEGIN
	SELECT POD_ID
	INTO v_POD_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN NVL(RO.GET_ENTITY_ATTRIBUTE(g_EA_IS_PUMPED_STORAGE, EC.ED_SERVICE_POINT, v_POD_ID, SYSDATE),0)<>0;

END IS_PUMPED_STORAGE;
-------------------------------------------------------------------------------
FUNCTION IS_ENERGY_LIMITED
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN BOOLEAN IS
v_POD_ID NUMBER;
BEGIN
	SELECT POD_ID
	INTO v_POD_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN NVL(RO.GET_ENTITY_ATTRIBUTE(g_EA_IS_ENERGY_LIMITED, EC.ED_SERVICE_POINT, v_POD_ID, SYSDATE),0)<>0;

END IS_ENERGY_LIMITED;
-------------------------------------------------------------------------------
FUNCTION IS_NETTING_GENERATOR
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN BOOLEAN IS
v_POD_ID NUMBER;
BEGIN
	SELECT POD_ID
	INTO v_POD_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN NVL(RO.GET_ENTITY_ATTRIBUTE(g_EA_IS_NETTING_GEN, EC.ED_SERVICE_POINT, v_POD_ID, SYSDATE),0)<>0;

END IS_NETTING_GENERATOR;
-------------------------------------------------------------------------------
FUNCTION IS_BLOCK_LOAD_GEN
	(
	p_TRANSACTION_ID IN NUMBER
	) RETURN BOOLEAN IS
v_POD_ID NUMBER;
BEGIN
	SELECT POD_ID
	INTO v_POD_ID
	FROM INTERCHANGE_TRANSACTION
	WHERE TRANSACTION_ID = p_TRANSACTION_ID;

	RETURN NVL(RO.GET_ENTITY_ATTRIBUTE(g_EA_IS_BLOCK_LOAD_GEN, EC.ED_SERVICE_POINT, v_POD_ID, SYSDATE),0)<>0;

END IS_BLOCK_LOAD_GEN;
-------------------------------------------------------------------------------
FUNCTION GET_RESOURCE_NAME
	(
   	p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
	) RETURN VARCHAR2 IS

v_POD_ID SERVICE_POINT.SERVICE_POINT_ID%TYPE;

BEGIN
	SELECT SERVICE_POINT_ID
	INTO v_POD_ID
	FROM INTERCHANGE_TRANSACTION A, SERVICE_POINT B
	WHERE A.TRANSACTION_ID = p_TRANSACTION_ID
   		AND A.POD_ID = B.SERVICE_POINT_ID;

	RETURN EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_SERVICE_POINT, v_POD_ID, EC.ES_SEM);
END GET_RESOURCE_NAME;
-------------------------------------------------------------------------------
FUNCTION GET_PURCHASER_NAME
	(
   	p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
	) RETURN VARCHAR2 IS

v_PSE_ID PURCHASING_SELLING_ENTITY.PSE_ID%TYPE;

BEGIN

    SELECT PSE.PSE_ID
    INTO v_PSE_ID
    FROM INTERCHANGE_TRANSACTION T, PURCHASING_SELLING_ENTITY PSE
    WHERE T.TRANSACTION_ID = p_TRANSACTION_ID
      AND PSE.PSE_ID = T.PURCHASER_ID;

    RETURN EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_PSE, v_PSE_ID, EC.ES_SEM);
END GET_PURCHASER_NAME;
--------------------------------------------------------------------------------
PROCEDURE RAISE_ALERTS
	(
	p_TYPE IN VARCHAR2,
	p_NAME IN VARCHAR2,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER,
	p_MSG IN VARCHAR2,
	p_FATAL IN BOOLEAN := FALSE
	) AS
v_NAME SYSTEM_ALERT_TRIGGER.TRIGGER_VALUE%Type := p_TYPE||': '||p_NAME;
v_TRIGGER_LEVEL PROCESS_LOG_EVENT.EVENT_LEVEL%Type;
BEGIN
	IF p_FATAL THEN
		v_TRIGGER_LEVEL := LOGS.c_Level_Fatal;
	ELSIF LOGS.GET_ERROR_COUNT() > 0 THEN
		v_TRIGGER_LEVEL := LOGS.c_Level_Error;
	ELSIF LOGS.GET_WARNING_COUNT() > 0 THEN
		v_TRIGGER_LEVEL := LOGS.c_Level_Warn;
	ELSE
		v_TRIGGER_LEVEL := LOGS.c_Level_Success;
	END IF;


	ALERTS.TRIGGER_ALERTS(v_NAME, v_TRIGGER_LEVEL, p_MSG);

	/*FOR v_ALERT_NAME IN c_ALERT_NAMES LOOP
		--fix for BZ 15337 - the time displayed in alerts is five hours behind the system time
		ALERTS.SEND_ALERT(v_ALERT_NAME.VALUE, p_MSG, v_STATUS, v_PRIORITY, SYSDATE);
		IF NVL(v_STATUS, GA.SUCCESS) <> GA.SUCCESS THEN
			p_LOGGER.LOG_ERROR('Failed to raise alert: '||v_ALERT_NAME.VALUE||'('||p_MSG||'). SQLCODE = '||v_STATUS);
		END IF;
	END LOOP;*/


END RAISE_ALERTS;
------------------------------------------------------------------------------
PROCEDURE OFFER_DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_OUT_BEGIN_DATE OUT DATE,
	p_OUT_END_DATE OUT DATE
	) AS
BEGIN
	-- We cannot use CUT_DATE_RANGE because that assumes that days start at TRUNC(time) [i.e. midnight]
	-- That assumption is used to ascertain where the skipped or duplicated HE 2 falls for DST
	-- transition days. Because the trading starts at 6am, the DST HE 2 falls on Saturday trading date,
	-- not the Sunday trading date.

	-- The logic follows:
	-- For the begin date, calculate 6am local time, convert to CUT, and add a second. We have to
	-- add a second because right at 6am indicates the interval ending 5:30 -> 6:00 (which is part of
	-- previous trading date).
	-- For the end date, calculate *following* day 6am local time, convert to CUT. We have to use the
	-- 6am of the following date because that is when the day ends. In other words the last date for
	-- trading day 10/01/2007 is, in fact, 11/01/2007 06:00 because the trading day for Halloween will
	-- go from 6am of Halloween through 6am of the next day.
	p_OUT_BEGIN_DATE := TO_CUT( TRUNC(p_BEGIN_DATE) + g_TRADE_DAY_HOUR_SHIFT/24, g_TZ ) + 1/86400;
	p_OUT_END_DATE := TO_CUT( TRUNC(p_END_DATE+1) + g_TRADE_DAY_HOUR_SHIFT/24, g_TZ );
END OFFER_DATE_RANGE;
------------------------------------------------------------------------------
PROCEDURE OFFER_DATE_RANGE
	(
	p_TRADING_DAY IN DATE,
	p_BEGIN_DATE OUT DATE,
	p_END_DATE OUT DATE
	) AS
BEGIN
	OFFER_DATE_RANGE(p_TRADING_DAY, p_TRADING_DAY, p_BEGIN_DATE, p_END_DATE);
END OFFER_DATE_RANGE;
------------------------------------------------------------------------------
FUNCTION GET_DEMAND_CTRL_DATA_TXN(p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) RETURN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE IS
	v_TXN_ID       INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	v_TXN_NAME     INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE := 'SEM Demand Control Data';
	v_TXN_TYPE     INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE := 'Demand Control';
	v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
	v_SC_ID        SCHEDULE_COORDINATOR.SC_ID%TYPE;
BEGIN
	ID.ID_FOR_TRANSACTION(p_TRANSACTION_NAME    => v_TXN_NAME,
						  p_TRANSACTION_TYPE    => v_TXN_TYPE,
						  p_CREATE_IF_NOT_FOUND => FALSE,
						  p_TRANSACTION_ID      => v_TXN_ID);
	IF v_TXN_ID <= 0 THEN
		ID.ID_FOR_TRANSACTION(p_TRANSACTION_NAME    => v_TXN_NAME,
							  p_TRANSACTION_TYPE    => v_TXN_TYPE,
							  p_CREATE_IF_NOT_FOUND => TRUE,
							  p_TRANSACTION_ID      => v_TXN_ID);
		p_LOGGER.LOG_INFO(v_TXN_NAME || ' created.');
		-- update commodity and sc
		ID.ID_FOR_COMMODITY(p_COMMODITY_NAME => 'Power', p_CREATE_IF_NOT_FOUND => FALSE, p_COMMODITY_ID => v_COMMODITY_ID);
		IF v_COMMODITY_ID <= 0 THEN
			ID.ID_FOR_COMMODITY(p_COMMODITY_NAME => 'Power', p_CREATE_IF_NOT_FOUND => TRUE, p_COMMODITY_ID => v_COMMODITY_ID);
			p_LOGGER.LOG_INFO('Power commodity created in MM_SEM_UTIL.GET_DEMAND_CTRL_DATA_TXN');
		END IF;

		ID.ID_FOR_SC(p_SC_NAME => 'SEM', p_CREATE_IF_NOT_FOUND => FALSE, p_SC_ID => v_SC_ID);
		IF v_SC_ID <= 0 THEN
			ID.ID_FOR_SC(p_SC_NAME => 'SEM', p_CREATE_IF_NOT_FOUND => TRUE, p_SC_ID => v_SC_ID);
			p_LOGGER.LOG_INFO('SEM Schedule coordinator created in MM_SEM_UTIL.GET_DEMAND_CTRL_DATA_TXN');
		END IF;

		UPDATE INTERCHANGE_TRANSACTION
		SET COMMODITY_ID = v_COMMODITY_ID,
			SC_ID = v_SC_ID,
			TRANSACTION_INTERVAL = '30 Minute',
			BEGIN_DATE = DATE '2007-01-01',
			END_DATE = DATE '2050-01-01'
		WHERE TRANSACTION_ID = v_TXN_ID;
		COMMIT;
	END IF;
	RETURN v_TXN_ID;
END GET_DEMAND_CTRL_DATA_TXN;
---------------------------------------------------------------------------------
FUNCTION GET_PSE_UNIT_TYPE
	(
	p_PSE_ID IN NUMBER,
	p_IS_PARTICIPANT_PSE IN NUMBER,
	p_DATE IN DATE
	) RETURN VARCHAR2 IS
	v_UNIT_TYPE VARCHAR2(1);
	v_ATTRIBUTE_ID NUMBER(9);
	v_DIFF_UNIT_TYPE VARCHAR2(1);
	v_PARTICIPANT_PSE_ID NUMBER(9);
BEGIN
	--Deterine whether a participant is a Supplier or Generator based on the type of its units.
	--Value returned will be one of the two constants g_PSE_TYPE_SUPPLIER_UNITS or g_PSE_TYPE_GENERATOR_UNITS

	ID.ID_FOR_ENTITY_ATTRIBUTE(MM_SEM_UTIL.g_EA_RESOURCE_TYPE, EC.ED_SERVICE_POINT, NULL, FALSE, v_ATTRIBUTE_ID);

	--Get the proper Setttlement PSE ID.
	IF p_IS_PARTICIPANT_PSE = 1 THEN
		v_PARTICIPANT_PSE_ID := p_PSE_ID;
	ELSE
		SELECT SSE.PARTICIPANT_PSE_ID
		INTO v_PARTICIPANT_PSE_ID
		FROM SEM_SETTLEMENT_ENTITY SSE
		WHERE SSE.SETTLEMENT_PSE_ID = p_PSE_ID;
	END IF;

	SELECT MAX(CASE WHEN REGEXP_LIKE(ATTRIBUTE_VAL, g_REGEXP_SUP_UNIT_TYPE) THEN g_PSE_TYPE_SUPPLIER_UNITS
		WHEN REGEXP_LIKE(ATTRIBUTE_VAL, g_REGEXP_GEN_UNIT_TYPE) THEN g_PSE_TYPE_GENERATOR_UNITS END),
		MIN(CASE WHEN REGEXP_LIKE(ATTRIBUTE_VAL, g_REGEXP_SUP_UNIT_TYPE) THEN g_PSE_TYPE_SUPPLIER_UNITS
		WHEN REGEXP_LIKE(ATTRIBUTE_VAL, g_REGEXP_GEN_UNIT_TYPE) THEN g_PSE_TYPE_GENERATOR_UNITS END)
	INTO v_UNIT_TYPE, v_DIFF_UNIT_TYPE
	FROM SEM_SERVICE_POINT_PSE SPP, TEMPORAL_ENTITY_ATTRIBUTE TEA
	WHERE SPP.PSE_ID = v_PARTICIPANT_PSE_ID
		AND p_DATE BETWEEN SPP.BEGIN_DATE AND NVL(SPP.END_DATE, p_DATE)
		AND TEA.OWNER_ENTITY_ID = SPP.POD_ID
		AND TEA.ATTRIBUTE_ID = v_ATTRIBUTE_ID
		AND p_DATE BETWEEN TEA.BEGIN_DATE AND NVL(TEA.END_DATE, p_DATE);

	IF NOT v_UNIT_TYPE = v_DIFF_UNIT_TYPE THEN
		LOGS.LOG_ERROR('MM_SEM_UTIL.GET_PSE_UNIT_TYPE found Units of multiple types for ' ||
				CASE p_IS_PARTICIPANT_PSE WHEN 1 THEN 'Participant ' ELSE 'Settlement ' END || 'PSE_ID=' || p_PSE_ID);
	END IF;

	RETURN NVL(v_UNIT_TYPE, g_PSE_TYPE_GENERATOR_UNITS);

END GET_PSE_UNIT_TYPE;
-----------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------
FUNCTION GEN_IMPORT_MPI_REPORT_PROC RETURN CLOB IS
	CURSOR c_IMPORT_PROCS_PARAMS IS
		SELECT A.REPORT_NAME, B.IMPORT_PROC, MAX(C.IMPORT_PARAM) as IMPORT_PARAM
		FROM (SELECT KEY3, VALUE REPORT_NAME FROM SYSTEM_DICTIONARY WHERE SETTING_NAME = 'report_name') A,
			 (SELECT KEY3, VALUE IMPORT_PROC FROM SYSTEM_DICTIONARY WHERE SETTING_NAME = 'import_procedure') B,
			 (SELECT KEY3, VALUE IMPORT_PARAM FROM SYSTEM_DICTIONARY WHERE SETTING_NAME = 'import_param') C
		WHERE A.KEY3 = B.KEY3
		AND A.KEY3 = C.KEY3
		AND A.REPORT_NAME <> 'PUB_A_TransLossAdjustmentFactors'
  		GROUP BY A.REPORT_NAME, B.IMPORT_PROC
		ORDER BY 1;

	v_RET CLOB;
	v_LINE VARCHAR2(32000);
	v_TAB CHAR := CHR(9);
BEGIN

	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);

	v_LINE := '-- AUTOGENERATED CODE: DO NOT HAND EDIT!!!!' || UTL_TCP.CRLF;
	v_LINE := v_LINE || '-- To regenerate this procedure, use the output from MM_SEM_UTIL.GEN_IMPORT_MPI_REPORT_PROC' || UTL_TCP.CRLF;
	v_LINE := v_LINE || 'PROCEDURE IMPORT_MPI_REPORT (' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'p_MPI_REPORT_NAME IN SYSTEM_DICTIONARY.VALUE%TYPE,' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'p_IMPORT_FILE IN OUT NOCOPY CLOB,' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'v_IMPORT_PARM SYSTEM_DICTIONARY.VALUE%TYPE;' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'v_KEY3_VALUE SYSTEM_DICTIONARY.VALUE%TYPE;' || UTL_TCP.CRLF;
	v_LINE := v_LINE || 'BEGIN' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || '-- get the run type (if it exists) from the file to get to the right system dictionary settings' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'MPI_RUN_TYPE(p_IMPORT_FILE, p_LOGGER);' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'IF g_RUN_TYPE IS NOT NULL THEN' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB ||'v_KEY3_VALUE := p_MPI_REPORT_NAME||''_''||g_RUN_TYPE;' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'ELSE' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB || 'v_KEY3_VALUE := p_MPI_REPORT_NAME;' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'END IF;' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'SET_MPUD5_PARAMETERS(p_IMPORT_FILE, p_LOGGER);' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'BEGIN' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB || 'SELECT VALUE INTO v_IMPORT_PARM' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB || 'FROM SYSTEM_DICTIONARY' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB || 'WHERE SETTING_NAME = ''import_param''' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB ||  v_TAB ||  v_TAB ||  v_TAB || 'AND KEY3=(' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB ||  v_TAB ||  v_TAB ||  v_TAB || 'SELECT KEY3' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB ||  v_TAB ||  v_TAB ||  v_TAB || 'FROM SYSTEM_DICTIONARY' || UTL_TCP.CRLF;
    v_LINE := v_LINE || v_TAB || v_TAB ||  v_TAB ||  v_TAB ||  v_TAB || 'WHERE VALUE=v_KEY3_VALUE || '|| '''.xml''' || ');' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'EXCEPTION WHEN OTHERS THEN' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB || 'v_IMPORT_PARM := NULL;' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'END;' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'CASE p_MPI_REPORT_NAME' || UTL_TCP.CRLF;
	DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_LINE), v_LINE);

	FOR v_RECORD IN c_IMPORT_PROCS_PARAMS LOOP
		v_LINE := v_TAB || v_TAB || 'WHEN ''' || v_RECORD.Report_Name || ''' THEN ';
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_LINE), v_LINE);

		IF v_RECORD.Import_Param IS NULL THEN
			v_LINE := v_RECORD.Import_Proc || '(p_IMPORT_FILE, p_LOGGER);' || UTL_TCP.CRLF;
		ELSE
			v_LINE := v_RECORD.Import_Proc || '(p_IMPORT_FILE, v_IMPORT_PARM, p_LOGGER);' || UTL_TCP.CRLF;
		END IF;
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_LINE), v_LINE);
	END LOOP;

	v_LINE := v_TAB || v_TAB || '-- you''re not hand-editing this case statement, are you?' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || v_TAB|| 'ELSE p_LOGGER.LOG_ERROR(p_MPI_REPORT_NAME || '' is not a valid report name. Report cannot be loaded.'');' || UTL_TCP.CRLF;
	v_LINE := v_LINE || v_TAB || 'END CASE;' || UTL_TCP.CRLF;
	v_LINE := v_LINE ||'END IMPORT_MPI_REPORT;' || UTL_TCP.CRLF || UTL_TCP.CRLF;
	DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_LINE), v_LINE);

	RETURN v_RET;

EXCEPTION
	WHEN OTHERS THEN
		IF v_RET IS NOT NULL THEN
			IF DBMS_LOB.ISOPEN(v_RET) <> 0 THEN
				DBMS_LOB.CLOSE(v_RET);
			END IF;
			DBMS_LOB.FREETEMPORARY(v_RET);
		END IF;
		DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
		RAISE;
END GEN_IMPORT_MPI_REPORT_PROC;
---------------------------------------------------------------------------------
FUNCTION IS_SEM_SHADOW_STATEMENT_TYPE(p_STATEMENT_TYPE_ID IN NUMBER) RETURN NUMBER IS
v_EXT_IDENT		EXTERNAL_SYSTEM_IDENTIFIER.EXTERNAL_IDENTIFIER%TYPE;
BEGIN
	v_EXT_IDENT := EI.GET_ENTITY_IDENTIFIER_EXTSYS(EC.ED_STATEMENT_TYPE, p_STATEMENT_TYPE_ID,
													EC.ES_SEM, g_STATEMENT_TYPE_SETTLEMENT, 1);
	IF v_EXT_IDENT LIKE 'P%' OR v_EXT_IDENT LIKE 'F%' THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;
-- constants
---------------------------------------------------------------------------------
-- provided statement type ID, return the run identifier (e.g. “P”, “F”, “F(1)”, etc.) and
-- the category (one of three categories above)
PROCEDURE GET_STATEMENT_TYPE_INFO
    (
    p_STATEMENT_TYPE_ID IN NUMBER,
    p_RUN_IDENTIFIER OUT VARCHAR2,
    p_CATEGORY OUT PLS_INTEGER
    ) AS
BEGIN
	-- Lookup TDIE External System Identifier
	p_CATEGORY := c_STATEMENT_CATEGORY_TDIE;

	SELECT MAX(ESI.EXTERNAL_IDENTIFIER)
	INTO p_RUN_IDENTIFIER
	FROM EXTERNAL_SYSTEM_IDENTIFIER ESI
	WHERE ESI.EXTERNAL_SYSTEM_ID = EC.ES_TDIE
	  AND ESI.ENTITY_DOMAIN_ID = EC.ED_STATEMENT_TYPE
	  AND ESI.IDENTIFIER_TYPE = EI.g_DEFAULT_IDENTIFIER_TYPE
	  AND ESI.ENTITY_ID = p_STATEMENT_TYPE_ID;

	IF p_RUN_IDENTIFIER IS NULL THEN
		-- Lookup SMO External System Identifier
		p_CATEGORY := c_STATEMENT_CATEGORY_SMO;

		SELECT MAX(ESI.EXTERNAL_IDENTIFIER)
    	INTO p_RUN_IDENTIFIER
    	FROM EXTERNAL_SYSTEM_IDENTIFIER ESI
    	WHERE ESI.EXTERNAL_SYSTEM_ID = EC.ES_SEM
    	  AND ESI.ENTITY_DOMAIN_ID = EC.ED_STATEMENT_TYPE
    	  AND ESI.IDENTIFIER_TYPE = g_STATEMENT_TYPE_SETTLEMENT
    	  AND ESI.ENTITY_ID = p_STATEMENT_TYPE_ID;

		IF p_RUN_IDENTIFIER IS NOT NULL THEN
			IF LENGTH(p_RUN_IDENTIFIER) > 4 AND SUBSTR(p_RUN_IDENTIFIER, 0, 4) = 'SMO ' THEN
				-- Found SMO
				p_RUN_IDENTIFIER := SUBSTR(p_RUN_IDENTIFIER, 5);
				p_CATEGORY := c_STATEMENT_CATEGORY_SMO;
			ELSE
				p_CATEGORY := c_STATEMENT_CATEGORY_INTERNAL;
			END IF;
		ELSE
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No info found for STATEMENT_TYPE_ID = ' || p_STATEMENT_TYPE_ID);
		END IF;
	END IF;
END GET_STATEMENT_TYPE_INFO;
---------------------------------------------------------------------------------
-- provided run identifier and statement type category, return statement type ID
FUNCTION GET_STATEMENT_TYPE_FROM_INFO
    (
    p_RUN_IDENTIFIER IN VARCHAR2,
    p_CATEGORY IN PLS_INTEGER
    ) RETURN NUMBER AS
v_STATEMENT_TYPE_ID STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
BEGIN
	v_STATEMENT_TYPE_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(
		CASE
			WHEN p_CATEGORY = c_STATEMENT_CATEGORY_SMO THEN
				'SMO ' || p_RUN_IDENTIFIER
			ELSE
				p_RUN_IDENTIFIER
		END,
		EC.ED_STATEMENT_TYPE,
		CASE
			WHEN p_CATEGORY = c_STATEMENT_CATEGORY_TDIE THEN
				EC.ES_TDIE
			ELSE
				EC.ES_SEM
		END,
		CASE
			WHEN p_CATEGORY = c_STATEMENT_CATEGORY_TDIE THEN
				EI.g_DEFAULT_IDENTIFIER_TYPE
			ELSE
				g_STATEMENT_TYPE_SETTLEMENT
		END);

	RETURN v_STATEMENT_TYPE_ID;
END GET_STATEMENT_TYPE_FROM_INFO;
---------------------------------------------------------------------------------
FUNCTION USING_CROSS_BORDER_VAT_FORMAT(p_DATE IN DATE, p_BILLING_ENTITY_ID IN NUMBER) RETURN BOOLEAN AS
v_INTERVAL 		PSE.INVOICE_INTERVAL%TYPE;
v_WEEK_BEGIN 	PSE.WEEK_BEGIN%TYPE;
BEGIN
	SELECT MAX(P.INVOICE_INTERVAL), MAX(P.WEEK_BEGIN)
	INTO v_INTERVAL, v_WEEK_BEGIN
	FROM PSE P
	WHERE P.PSE_ID = p_BILLING_ENTITY_ID;

	ASSERT(v_INTERVAL IS NOT NULL, 'The Billing Entity''s Invoice Interval attribute must be non-null.');
	ASSERT(v_INTERVAL IN (DATE_UTIL.c_NAME_WEEK, DATE_UTIL.c_NAME_MONTH), 'The Billing Entity''s Invoice Interval attribute must be one of the following: Week, Month.');
	ASSERT(v_WEEK_BEGIN IS NOT NULL, 'The Billing Entity''s Week Begin attribute must be non-null.');

	RETURN USING_CROSS_BORDER_VAT_FORMAT(p_DATE,v_INTERVAL,v_WEEK_BEGIN);
END USING_CROSS_BORDER_VAT_FORMAT;
---------------------------------------------------------------------------------
FUNCTION USING_CROSS_BORDER_VAT_FORMAT(p_DATE IN DATE, p_INTERVAL IN VARCHAR2, p_WEEK_BEGIN IN VARCHAR2) RETURN BOOLEAN AS
    v_CROSS_BORDER_VAT_START_DATE  DATE := TO_DATE(NVL(GET_DICTIONARY_VALUE('Cross Border VAT Start Date',
        CONSTANTS.GLOBAL_MODEL,'MarketExchange','SEM','Settlement'),CONSTANTS.HIGH_DATE),'YYYY-MM-DD');
	v_PERIOD_BEGIN_DATE DATE;
	v_PERIOD_END_DATE DATE;
BEGIN
	-- Get the adjusted BEGIN DATE based on the XBV Cutover date, Interval, and Week Begin
	v_PERIOD_BEGIN_DATE := DATE_UTIL.BEGIN_DATE_FOR_INTERVAL(v_CROSS_BORDER_VAT_START_DATE,p_INTERVAL,p_WEEK_BEGIN);
	-- Using the BEGIN_DATE of the period, find the END_DATE
	v_PERIOD_END_DATE := DATE_UTIL.END_DATE_FOR_INTERVAL(v_PERIOD_BEGIN_DATE,p_INTERVAL,p_WEEK_BEGIN);
	-- Return whether the specified date belongs to the next invoice period.
	RETURN p_DATE > v_PERIOD_END_DATE;
END;
---------------------------------------------------------------------------------
FUNCTION GET_USING_CROSS_BORDER_VAT_FMT(p_DATE IN DATE, p_BILLING_ENTITY_ID IN NUMBER) RETURN NUMBER AS
BEGIN
	RETURN UT.NUMBER_FROM_BOOLEAN(USING_CROSS_BORDER_VAT_FORMAT(p_DATE, p_BILLING_ENTITY_ID));
END GET_USING_CROSS_BORDER_VAT_FMT;
---------------------------------------------------------------------------------
PROCEDURE GET_GATE_INTERCONNECT
	(
	p_CONTRACT			IN	VARCHAR2,
	p_GATE_WINDOW	   OUT	VARCHAR2,
	p_INTERCONNECTOR   OUT	VARCHAR2
	) AS
	v_GATE_WINDOW_ID		NUMBER(9);
	v_INTERCONNECTOR_ID 	NUMBER(9);
	v_IS_RESOURCE_TYPE_SET	NUMBER(1);
	v_POSITION				NUMBER(3);
BEGIN
	IF p_CONTRACT IS NOT NULL THEN
		v_POSITION := INSTR(TRIM(p_CONTRACT), '_', 1, 2);

		-- Look for the occurance of second '_'. If found, extract Gate and Interconnector.
		IF v_POSITION > 0 THEN
			p_GATE_WINDOW := SUBSTR(TRIM(p_CONTRACT), v_POSITION + 1);
			v_GATE_WINDOW_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_GATE_WINDOW, EC.ED_STATEMENT_TYPE, EC.ES_SEM, MM_SEM_UTIL.g_STATEMENT_TYPE_GATE_WINDOW, 1);

			ASSERT(v_GATE_WINDOW_ID IS NOT NULL, 'Gate Window ' || p_GATE_WINDOW || ' does not exist.');

			p_INTERCONNECTOR := SUBSTR(TRIM(p_CONTRACT), 1, v_POSITION - 1);
		-- If not found, then there is no Gate but just the Interconnector
		ELSE
			p_INTERCONNECTOR := TRIM(p_CONTRACT);
		END IF;
		v_INTERCONNECTOR_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_INTERCONNECTOR, EC.ED_SERVICE_POINT, EC.ES_SEM, p_QUIET => 1);

		SELECT COUNT(1)
		  INTO v_IS_RESOURCE_TYPE_SET
		  FROM TEMPORAL_ENTITY_ATTRIBUTE
		 WHERE ATTRIBUTE_ID = (SELECT ATTRIBUTE_ID
								 FROM ENTITY_ATTRIBUTE
								WHERE ENTITY_DOMAIN_ID =
									(SELECT ENTITY_DOMAIN_ID
									   FROM ENTITY_DOMAIN
									  WHERE ENTITY_DOMAIN_NAME = 'Service Point')
										AND ATTRIBUTE_NAME = 'Resource Type')
		AND ATTRIBUTE_VAL = 'I'
		AND OWNER_ENTITY_ID = v_INTERCONNECTOR_ID;

		ASSERT(v_IS_RESOURCE_TYPE_SET = 1, 'Service Point ' || p_INTERCONNECTOR || ' does not have Resource Type set as I.');
	END IF;
END GET_GATE_INTERCONNECT;
---------------------------------------------------------------------------------
FUNCTION AFTER_SEM_2_2_CUT_OVER(p_DATE IN DATE) RETURN NUMBER IS
BEGIN
	IF p_DATE >= TO_DATE(NVL(GET_DICTIONARY_VALUE('SEM R2.2 Cutover Date',
        CONSTANTS.GLOBAL_MODEL,'MarketExchange','SEM','Settlement'),CONSTANTS.HIGH_DATE),'YYYY-MM-DD') THEN
		RETURN 1;
	ELSE 
		RETURN 0;
	END IF;
END;
---------------------------------------------------------------------------------------------------
BEGIN
	BEGIN
		g_TEST := TO_NUMBER(NVL(GET_DICTIONARY_VALUE('Test Mode',0,'MarketExchange','SEM'),'0'))<>0;
	EXCEPTION
		WHEN OTHERS THEN
			g_TEST := FALSE;
	END;
END MM_SEM_UTIL;
/
