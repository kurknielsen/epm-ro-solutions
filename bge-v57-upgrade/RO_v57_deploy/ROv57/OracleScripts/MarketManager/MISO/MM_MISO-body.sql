CREATE OR REPLACE PACKAGE BODY MM_MISO AS
    --g_RVW_STATUS_PENDING CONSTANT VARCHAR2(16) := 'Pending';
    g_RVW_STATUS_ACCEPTED CONSTANT VARCHAR2(16) := 'Accepted';
    g_SUBMIT_STATUS_PENDING CONSTANT VARCHAR2(16) := 'Pending';
    g_SUBMIT_STATUS_SUBMITTED CONSTANT VARCHAR2(16) := 'Submitted';
    g_SUBMIT_STATUS_FAILED CONSTANT VARCHAR2(16) := 'Rejected';
    g_MKT_STATUS_PENDING CONSTANT VARCHAR2(16) := 'Pending';
    g_MKT_STATUS_ACCEPTED CONSTANT VARCHAR2(16) := 'Accepted';
    g_MKT_STATUS_REJECTED CONSTANT VARCHAR2(16) := 'Rejected';
    g_REALTIME CONSTANT VARCHAR2(16) := 'RealTime';
    g_DAYAHEAD CONSTANT VARCHAR2(16) := 'DayAhead';
    g_LMP_PRICE_TYPE CONSTANT VARCHAR2(32) := 'Locational Marginal Price';
    g_MLC_PRICE_TYPE CONSTANT VARCHAR2(32) := 'Marginal Loss Component';
    g_MCC_PRICE_TYPE CONSTANT VARCHAR2(32) := 'Marginal Congestion Component';
    g_LMP_PRICE_ABBR CONSTANT VARCHAR2(3) := 'LMP';
    g_MLC_PRICE_ABBR CONSTANT VARCHAR2(3) := 'MLC';
    g_MCC_PRICE_ABBR CONSTANT VARCHAR2(3) := 'MCC';

    g_UNCONFIRMED_CONTRACT_ALERT VARCHAR2(256) := 'Unconfirmed Contract';

-------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE COPY_DA_TXN_TO_RT
(
    p_TRANSACTION IN INTERCHANGE_TRANSACTION%ROWTYPE,
	p_RT_TRANSACTION_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_ERROR_MESSAGE OUT VARCHAR2
) IS

v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
v_RT_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_COMMODITY_MKT_TYPE IT_COMMODITY.MARKET_TYPE%TYPE;
v_ERR VARCHAR2(32) := 'Error in COPY_DA_TXN_TO_RT: ';
BEGIN
	p_STATUS := GA.SUCCESS;
	v_TRANSACTION := p_TRANSACTION;

    -- get the market type of the commodity
    -- (could be NULL or DayAhead or RealTime)
    BEGIN
        SELECT MARKET_TYPE
        INTO v_COMMODITY_MKT_TYPE
        FROM IT_COMMODITY
		WHERE COMMODITY_ID = v_TRANSACTION.COMMODITY_ID; -- of the existing transaction
    EXCEPTION
    	WHEN OTHERS THEN
    		p_STATUS := SQLCODE;
    		p_ERROR_MESSAGE := v_ERR || SQLERRM;
    		RETURN;
    END;

    -- check if DA txn
    IF v_COMMODITY_MKT_TYPE = g_DAYAHEAD THEN

    	-- get RT commodity #
    	v_TRANSACTION.COMMODITY_ID := 0;

        BEGIN
            SELECT COMMODITY_ID
            INTO v_TRANSACTION.COMMODITY_ID
            FROM IT_COMMODITY
            WHERE UPPER(COMMODITY_NAME) = UPPER(g_REALTIME || ' Energy');
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
                -- add a RT commodity
        		BEGIN
                    IO.PUT_IT_COMMODITY(
                        o_OID => v_TRANSACTION.COMMODITY_ID,
                        p_COMMODITY_NAME => g_REALTIME || ' Energy',
                        p_COMMODITY_ALIAS => 'RT',
                        p_COMMODITY_DESC => g_REALTIME || ' Energy',
                        p_COMMODITY_ID => 0,
                        p_COMMODITY_TYPE => 'Energy',
                        p_COMMODITY_UNIT => 'MWH',
                        p_COMMODITY_UNIT_FORMAT => '?',
                        p_COMMODITY_PRICE_UNIT => 'Dollars',
                        p_COMMODITY_PRICE_FORMAT => '?',
                        p_IS_VIRTUAL => 0,
                        p_MARKET_TYPE => g_REALTIME
                    );
        		EXCEPTION
        			WHEN OTHERS THEN
        				p_STATUS := SQLCODE;
        				p_ERROR_MESSAGE := v_ERR || SQLERRM;
        				RETURN;
        		END;

        	WHEN OTHERS THEN
            	p_STATUS := SQLCODE;
            	p_ERROR_MESSAGE := v_ERR || SQLERRM;
            	RETURN;
    	END;

		-- add or update txn
        v_TRANSACTION.TRANSACTION_ID := 0; -- create new txn if missing
        v_TRANSACTION.TRANSACTION_NAME := v_TRANSACTION.TRANSACTION_NAME || 'RT';
        v_TRANSACTION.TRANSACTION_ALIAS := v_TRANSACTION.TRANSACTION_ALIAS || 'RT';
        v_TRANSACTION.TRANSACTION_IDENTIFIER := v_TRANSACTION.TRANSACTION_IDENTIFIER || 'RT';
        MM_UTIL.PUT_TRANSACTION(v_RT_TRANSACTION_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');

       	BEGIN
    		SELECT TRANSACTION_ID
    		INTO p_RT_TRANSACTION_ID
    		FROM INTERCHANGE_TRANSACTION
    		WHERE TRANSACTION_NAME = v_TRANSACTION.TRANSACTION_NAME;
		EXCEPTION
		       	WHEN OTHERS THEN
            		p_STATUS := SQLCODE;
            		p_ERROR_MESSAGE := v_ERR || SQLERRM;
            		RETURN;
		END;
		--dbms_output.put_line('txn_id=' || to_char(p_RT_TRANSACTION_ID));

    END IF;

END COPY_DA_TXN_TO_RT;
---------------------------------------------------------------------------------------------------
FUNCTION IS_FIN_CONTRACT_DA(p_TXN_ID IN NUMBER) RETURN BOOLEAN IS
    v_TXN_COMMODITY_ID NUMBER;
    v_DA_COMMODITY_ID  NUMBER;
BEGIN
    SELECT COMMODITY_ID
      INTO v_TXN_COMMODITY_ID
      FROM INTERCHANGE_TRANSACTION
     WHERE TRANSACTION_ID = p_TXN_ID;
    SELECT COMMODITY_ID INTO v_DA_COMMODITY_ID FROM IT_COMMODITY WHERE COMMODITY_ALIAS = 'DA';
    RETURN(v_TXN_COMMODITY_ID = v_DA_COMMODITY_ID);
END IS_FIN_CONTRACT_DA;
---------------------------------------------------------------------------------------------------
    FUNCTION SAFE_STRING(
        p_XML IN XMLTYPE,
        p_XPATH IN VARCHAR2,
        p_NAMESPACE IN VARCHAR2 := NULL
    )
        RETURN VARCHAR2 IS
        --RETURN TEXT FOR A PATH OR NULL IF IT DOESN'T EXIST.
        v_XMLTMP XMLTYPE;
    BEGIN
        v_XMLTMP := XMLTYPE.EXTRACT(p_XML, p_XPATH, p_NAMESPACE);

        IF v_XMLTMP IS NULL THEN
            RETURN NULL;
        ELSE
            RETURN v_XMLTMP.GETSTRINGVAL();
        END IF;
    END SAFE_STRING;

----------------------------------------------------------------------------------------------------
    PROCEDURE GET_PARTIES_FOR_ISO_ACCOUNT(
        p_ISO_ACCOUNT_NAME IN VARCHAR2,
        p_PARTIES OUT GA.STRING_TABLE
    ) AS
        CURSOR c_PARTIES IS
            SELECT VALUE
            FROM   SYSTEM_LABEL
            WHERE  MODEL_ID = 0 AND MODULE = 'MarketExchange' AND KEY1 = 'MISO' AND KEY2 = 'Asset Owners' AND UPPER(KEY3) = UPPER(p_ISO_ACCOUNT_NAME);

        v_COUNT BINARY_INTEGER := 0;
    BEGIN
        FOR v_PARTIES IN c_PARTIES LOOP
            v_COUNT := v_COUNT + 1;
            p_PARTIES(v_COUNT) := v_PARTIES.VALUE;
        END LOOP;

        --IF NO PARTIES ARE DEFINED, THEN ASSUME THERE IS
        --ONLY ONE, AND IT IS EQUAL TO THE ISO ACCOUNT NAME.
        IF v_COUNT < 1 THEN
            p_PARTIES(1) := p_ISO_ACCOUNT_NAME;
        END IF;
    END GET_PARTIES_FOR_ISO_ACCOUNT;

---------------------------------------------------------------------------------------------------
    FUNCTION GET_PARTY_FOR_TRANSACTION(
        p_TRANSACTION_ID IN NUMBER
    )
        RETURN VARCHAR2 IS
        v_PARTY_NAME VARCHAR2(16);
    --RETURN THE PARTY ASSOCIATED WITH THE TRANSACTION, WHICH
    --IS WHATEVER COMES AFTER 'MISO '
    BEGIN
        SELECT SUBSTR(A.CONTRACT_NAME, 6)
        INTO   v_PARTY_NAME
        FROM   INTERCHANGE_CONTRACT A, INTERCHANGE_TRANSACTION B
        WHERE  B.TRANSACTION_ID = p_TRANSACTION_ID AND A.CONTRACT_ID = B.CONTRACT_ID;

        RETURN v_PARTY_NAME;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END GET_PARTY_FOR_TRANSACTION;
-------------------------------------------------------------------------------------
    FUNCTION GET_PARTY_FOR_CONTRACT(
        p_CONTRACT_ID IN NUMBER
    )
        RETURN VARCHAR2 IS
        v_PARTY_NAME VARCHAR2(16);
    --RETURN THE PARTY ASSOCIATED WITH THE CONTRACT
    BEGIN
        SELECT SUBSTR(A.CONTRACT_NAME, 6)
        INTO   v_PARTY_NAME
        FROM   INTERCHANGE_CONTRACT A
        WHERE  A.CONTRACT_ID = p_CONTRACT_ID;

        RETURN v_PARTY_NAME;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END GET_PARTY_FOR_CONTRACT;

-------------------------------------------------------------------------------------
    FUNCTION GET_CONTRACT_ID_FOR_PARTY(
        p_PARTY_NAME IN VARCHAR2
    )
        RETURN NUMBER IS
        v_CONTRACT INTERCHANGE_CONTRACT%ROWTYPE;
    --RETURN THE CONTRACT FOR THE ASSET OWNER,
    --GENERALLY THE ONE NAMED 'MISO ' || p_ASSET_OWNER_NAME
    BEGIN
        v_CONTRACT := MM_MISO_UTIL.GET_CONTRACT_FOR_ASSET_OWNER(p_PARTY_NAME);
        RETURN v_CONTRACT.CONTRACT_ID;
    END GET_CONTRACT_ID_FOR_PARTY;

-------------------------------------------------------------------------------------
    FUNCTION ID_FOR_PSE_IDENT(
        p_PSE_IDENT IN VARCHAR2,
		p_LOGGER IN OUT MM_LOGGER_ADAPTER
    )
        RETURN NUMBER IS
        v_PSE_ID NUMBER(9);
    BEGIN
        ID.ID_FOR_PSE_EXTERNAL_IDENTIFIER(p_PSE_IDENT, v_PSE_ID, TRUE);

        IF v_PSE_ID = -1 THEN
            -- there's already a PSE by this name, but likely with a different external identifier.
            -- add (MISO) to the name, and try again
            IO.PUT_PSE(v_PSE_ID, p_PSE_IDENT || ' (MISO)', p_PSE_IDENT, 'Created by MarketManager MISO download.', 0, NULL, 'Active', NULL, NULL, NULL, 'Marketer', p_PSE_IDENT, 0, 0, 0, 0, 'EST', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
        END IF;
        -- if there's still no PSE, log an error and return -1
        IF v_PSE_ID = -1 THEN
			p_LOGGER.LOG_EXCHANGE_ERROR('MISO PSE was not found and could not be created for Identifier "' || p_PSE_IDENT || '" in MM_MISO.ID_FOR_PSE_IDENT.');
        END IF;

        RETURN v_PSE_ID;
    END ID_FOR_PSE_IDENT;

-------------------------------------------------------------------------------------
    FUNCTION ID_FOR_MARKET_PRICE(
        p_LOCATION_NAME IN VARCHAR2,
        p_MARKET_PRICE_TYPE IN VARCHAR2,
        p_MARKET_PRICE_ABBR IN VARCHAR2,
        p_MARKET_TYPE IN VARCHAR2,
        p_INTERVAL IN VARCHAR2
    )
        RETURN NUMBER IS
        v_EXTERNAL_IDENTIFIER MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
        v_POD_ID NUMBER(9);
        v_MARKET_PRICE_ID NUMBER(9);
        v_MARKET_TYPE_ABBR VARCHAR2(3);
        v_SC_ID NUMBER(9) := MM_MISO_UTIL.GET_MISO_SC_ID;
    BEGIN
        v_MARKET_TYPE_ABBR := CASE p_MARKET_TYPE
                                 WHEN g_DAYAHEAD THEN 'DA'
                                 ELSE 'RT'
                             END;
		IF UPPER(p_INTERVAL) = '5 MINUTE' THEN
			v_MARKET_TYPE_ABBR := v_MARKET_TYPE_ABBR || '5';
		END IF;

        BEGIN
            SELECT A.MARKET_PRICE_ID
            INTO   v_MARKET_PRICE_ID
            FROM   MARKET_PRICE A, SERVICE_POINT B
            WHERE  B.EXTERNAL_IDENTIFIER = p_LOCATION_NAME
            AND    A.POD_ID = B.SERVICE_POINT_ID
            AND    A.SC_ID = v_SC_ID
            AND    A.MARKET_PRICE_TYPE = p_MARKET_PRICE_TYPE
            AND    UPPER(A.MARKET_PRICE_INTERVAL) = UPPER(p_INTERVAL)
            AND    A.MARKET_TYPE = p_MARKET_TYPE
            AND    ROWNUM = 1;                                                                                                                                                              --Just in case it is not unique (should be, but not enforced in DB)
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                --CREATE THE MARKET PRICE.
                --MARKET PRICE IDENTIFIER:
                --MISO:<RESOURCE_NAME>:<PRICE_TYPE_ABBR>:<MARKET_TYPE>
                v_EXTERNAL_IDENTIFIER := 'MISO:' || p_LOCATION_NAME || ':' || p_MARKET_PRICE_ABBR || ':' || v_MARKET_TYPE_ABBR;
                ID.ID_FOR_SERVICE_POINT_XID(p_LOCATION_NAME, TRUE, v_POD_ID);
                IO.PUT_MARKET_PRICE(v_MARKET_PRICE_ID, v_EXTERNAL_IDENTIFIER, v_EXTERNAL_IDENTIFIER,                                                                                                                                                  -- ALIAS
                    v_EXTERNAL_IDENTIFIER,                                                                                                                                                                                                             -- DESC
                    0, p_MARKET_PRICE_TYPE,                                                                                                                                                                                               -- MARKET_PRICE_TYPE
                    p_INTERVAL,                                                                                                                                                                                                        --MARKET_PRICE_INTERVAL
                    p_MARKET_TYPE,                                                                                                                                                                                                               --MARKET_TYPE
                    0,                                                                                                                                                                                                                         -- COMMODITY_ID
                    'Point',                                                                                                                                                                                                             -- SERVICE_POINT_TYPE
                    v_EXTERNAL_IDENTIFIER,                                                                                                                                                                                              -- EXTERNAL_IDENTIFIER
                    0,                                                                                                                                                                                                                               -- EDC_ID
                    MM_MISO_UTIL.GET_MISO_SC_ID,                                                                                                                                                                                                       --SC_ID
                    v_POD_ID,                                                                                                                                                                                                                        -- POD_ID
                    0                                                                                                                                                                                                                                -- ZOD_ID
                     );
        END;

        RETURN v_MARKET_PRICE_ID;
    END ID_FOR_MARKET_PRICE;

-------------------------------------------------------------------------------------
    PROCEDURE GET_BID_TRANSACTION_ID(
        p_BID_TYPE IN VARCHAR2,
        p_TRANSACTION_TYPE IN VARCHAR2,
        p_POD_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_MARKET_TYPE IN VARCHAR2,
        p_COMMODITY_TYPE IN VARCHAR2,
        p_IS_VIRTUAL IN NUMBER,
        p_IS_FIRM IN NUMBER,
        p_TRANSACTION_INTERVAL IN VARCHAR2,
        p_PARTY_NAME IN VARCHAR2,
        p_TRANSACTION_ID OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
        p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
    ) AS
        v_CONTRACT_ID NUMBER(9);
        v_COMMODITY_ID NUMBER(9);
        v_COMMODITY_NAME VARCHAR2(32);
        v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
        v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
        v_POD_ID NUMBER(9);
        v_SC_ID NUMBER(9) := MM_MISO_UTIL.GET_MISO_SC_ID;
    BEGIN
        --GET THE SERVICE POINT ID.
        ID.ID_FOR_SERVICE_POINT_XID(p_POD_NAME, TRUE, v_POD_ID);

        IF LOGS.IS_DEBUG_ENABLED THEN
            LOGS.LOG_DEBUG('PARTY=' || p_PARTY_NAME);
            LOGS.LOG_DEBUG('LOCATION_NAME=' || p_POD_NAME);
            LOGS.LOG_DEBUG('SCHEDULE_DAY=' || UT.TRACE_DATE(p_SCHEDULE_DAY));
        END IF;

        v_CONTRACT_ID := GET_CONTRACT_ID_FOR_PARTY(p_PARTY_NAME);

        BEGIN
            SELECT A.TRANSACTION_ID
            INTO   p_TRANSACTION_ID
            FROM   INTERCHANGE_TRANSACTION A, IT_COMMODITY C
            WHERE  A.TRANSACTION_TYPE = p_TRANSACTION_TYPE
            AND    A.SC_ID = v_SC_ID
            AND    A.POD_ID = v_POD_ID
            AND    p_SCHEDULE_DAY BETWEEN A.BEGIN_DATE AND A.END_DATE
            AND    C.MARKET_TYPE = p_MARKET_TYPE
            AND    C.COMMODITY_TYPE = p_COMMODITY_TYPE
            AND    C.IS_VIRTUAL = p_IS_VIRTUAL
            AND    A.COMMODITY_ID = C.COMMODITY_ID
            AND    A.CONTRACT_ID = v_CONTRACT_ID
            AND    A.IS_FIRM = p_IS_FIRM
            AND    A.TRANSACTION_INTERVAL = p_TRANSACTION_INTERVAL
            AND    ROWNUM = 1;                                                                                                                                                                                                 --HOPEFULLY THERE IS ONLY ONE...
        EXCEPTION
            --CREATE THE TRANSACTION IF IT DOES NOT EXIST.
            WHEN NO_DATA_FOUND THEN
                IF p_CREATE_IF_NOT_FOUND THEN
                    SELECT COMMODITY_ID, COMMODITY_ALIAS
                    INTO   v_COMMODITY_ID, v_COMMODITY_NAME
                    FROM   IT_COMMODITY
                    WHERE  MARKET_TYPE = p_MARKET_TYPE AND COMMODITY_TYPE = p_COMMODITY_TYPE AND IS_VIRTUAL = p_IS_VIRTUAL AND ROWNUM = 1;

                    v_TRANSACTION_NAME := 'MISO-' || p_PARTY_NAME || ':' || p_POD_NAME || ':' || v_COMMODITY_NAME || ':' || p_BID_TYPE;
                    v_TRANSACTION.TRANSACTION_ID := 0;
                    v_TRANSACTION.SC_ID := MM_MISO_UTIL.GET_MISO_SC_ID;
                    v_TRANSACTION.IS_BID_OFFER := 1;
                    v_TRANSACTION.TRANSACTION_TYPE := p_TRANSACTION_TYPE;
                    v_TRANSACTION.POD_ID := v_POD_ID;
                    v_TRANSACTION.BEGIN_DATE := ADD_MONTHS(p_SCHEDULE_DAY, -12);
                    v_TRANSACTION.END_DATE := ADD_MONTHS(p_SCHEDULE_DAY, 24);
                    v_TRANSACTION.COMMODITY_ID := v_COMMODITY_ID;
                    v_TRANSACTION.TRANSACTION_INTERVAL := p_TRANSACTION_INTERVAL;
                    v_TRANSACTION.CONTRACT_ID := v_CONTRACT_ID;
                    v_TRANSACTION.IS_IMPORT_EXPORT := 0;
                    v_TRANSACTION.IS_FIRM := p_IS_FIRM;
                    v_TRANSACTION.TRANSACTION_NAME := v_TRANSACTION_NAME;
                    v_TRANSACTION.TRANSACTION_ALIAS := SUBSTR(v_TRANSACTION_NAME, 1, 32);
                    v_TRANSACTION.TRANSACTION_IDENTIFIER := v_TRANSACTION_NAME;
                    v_TRANSACTION.TRAIT_CATEGORY := 'MISO ' || p_BID_TYPE;
                    MM_UTIL.PUT_TRANSACTION(p_TRANSACTION_ID, v_TRANSACTION, GA.INTERNAL_STATE, 'Active');
                ELSE
                    p_TRANSACTION_ID := -1;                                                                                                                                                                                  -- indicates no transaction found
                    p_ERROR_MESSAGE := 'Unable to find Load Transaction associated with location=' || p_POD_NAME || ', day=' || TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT);
                    RETURN;
                END IF;
        END;
    END GET_BID_TRANSACTION_ID;

-------------------------------------------------------------------------------------
    PROCEDURE MISO_UNAPP_BILAT_SCH_RPT(
        p_SCHEDULE_TYPE IN NUMBER,
        p_BEGIN_DATE IN DATE,
        p_END_DATE IN DATE,
        p_STATUS OUT NUMBER,
        p_CURSOR IN OUT REF_CURSOR
    ) IS
    BEGIN
        p_STATUS := GA.SUCCESS;

        OPEN p_CURSOR FOR
            SELECT   A.TRANSACTION_NAME, SELLER.PSE_NAME "SELLER", BUYER.PSE_NAME "BUYER", BO.SCHEDULE_DATE "DATE", BO.QUANTITY "UNCONFIRMED_VAL"
            FROM     BID_OFFER_SET BO, PSE SELLER, PSE BUYER, INTERCHANGE_TRANSACTION A
            WHERE    (BO.TRANSACTION_ID NOT IN(SELECT TRANSACTION_ID
                                               FROM   IT_SCHEDULE
                                               WHERE  IT_SCHEDULE.SCHEDULE_TYPE = p_SCHEDULE_TYPE))
            AND      (BO.SCHEDULE_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE)
            AND      BO.TRANSACTION_ID = A.TRANSACTION_ID
            AND      SELLER.PSE_ID = A.SELLER_ID
            AND      BUYER.PSE_ID = A.PURCHASER_ID
            AND      A.IS_BID_OFFER = 1
            AND      UPPER(A.TRANSACTION_TYPE) IN('PURCHASE', 'SALE')
            AND      BO.SCHEDULE_STATE = 2
            ORDER BY A.TRANSACTION_NAME, SELLER, BUYER, BO.SCHEDULE_DATE;
    END MISO_UNAPP_BILAT_SCH_RPT;

-------------------------------------------------------------------------------------
    PROCEDURE MISO_CPNODES_RPT(
        p_STATUS OUT NUMBER,
        p_CURSOR IN OUT REF_CURSOR
    ) IS
    BEGIN
        p_STATUS := GA.SUCCESS;

        OPEN p_CURSOR FOR
            SELECT   0 "DUMMY", 0 "ADD_SVC_POINT", M.NODE_NAME, M.NODE_TYPE
            FROM     MISO_CPNODES M
            WHERE    M.NODE_NAME NOT IN(SELECT NODE_NAME
                                        FROM   MISO_CPNODES, SERVICE_POINT
                                        WHERE  MISO_CPNODES.NODE_NAME = SERVICE_POINT.EXTERNAL_IDENTIFIER)
            ORDER BY M.NODE_TYPE, M.NODE_NAME;
    END MISO_CPNODES_RPT;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_MISO_CPNODES_RPT(
        p_NODE_NAME IN VARCHAR2,
        p_NODE_TYPE IN VARCHAR2,
        p_ADD_SVC_POINT IN NUMBER,
        p_STATUS OUT NUMBER
    ) IS
        v_SERVICE_POINT_ID SERVICE_POINT.SERVICE_POINT_ID%TYPE;
    BEGIN
        p_STATUS := GA.SUCCESS;

        IF p_ADD_SVC_POINT = 1 THEN
            IO.PUT_SERVICE_POINT(
                O_OID => v_SERVICE_POINT_ID,
                p_SERVICE_POINT_NAME => p_NODE_NAME || ' (MISO)',
                p_SERVICE_POINT_ALIAS => p_NODE_NAME,
                p_SERVICE_POINT_DESC => 'Created via Add MISO CPNode report',
                p_SERVICE_POINT_ID => 0,
                p_SERVICE_POINT_TYPE => 'Point',
                p_TP_ID => 0,
                p_CA_ID => 0,
                p_EDC_ID => 0,
                p_ROLLUP_ID => 0,
                p_SERVICE_REGION_ID => 0,
                p_SERVICE_AREA_ID => 0,
                p_SERVICE_ZONE_ID => 0,
                p_TIME_ZONE => MM_MISO_UTIL.g_MISO_TIMEZONE,
                p_LATITUDE => NULL,
                p_LONGITUDE => NULL,
                p_EXTERNAL_IDENTIFIER => p_NODE_NAME,
                p_IS_INTERCONNECT => 0,
                p_NODE_TYPE => p_NODE_TYPE,
                p_SERVICE_POINT_NERC_CODE => '?',
                p_PIPELINE_ID => NULL,
                p_MILE_MARKER => NULL
            );
            COMMIT;
        END IF;
    END PUT_MISO_CPNODES_RPT;

-------------------------------------------------------------------------------------
    PROCEDURE RUN_MISO_ACTION(
        p_CRED in MEX_Credentials,
		p_ACTION in VARCHAR2,
        p_XML_REQUEST_BODY IN XMLTYPE,
        p_LOG_ONLY IN NUMBER,
        p_XML_RESPONSE_BODY OUT XMLTYPE,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) AS
        v_MISO_ERROR_XML XMLTYPE;
        v_MISO_ERROR_CODE VARCHAR2(32);
        v_MISO_ERROR_MESSAGE VARCHAR2(2000);
        v_MISO_ERROR_LINE VARCHAR2(32);

    	v_RESULT       MEX_RESULT;

    BEGIN


		v_RESULT := Mex_Switchboard.Invoke(p_Market => MM_MISO_UTIL.g_MEX_MARKET,
							 p_Action => p_ACTION,
							 p_Logger => p_LOGGER,
							 p_Cred => p_CRED,
							 p_Request_ContentType => 'text/xml',
							 p_Request => p_XML_REQUEST_BODY.getClobVal(),
							 p_Log_Only => p_LOG_ONLY	-- Invoke will only log the request if not 0
							 );

        -- IF log only mode : No parse required logging already handled by invoke.
        IF p_LOG_ONLY = 0 THEN
			IF v_RESULT.STATUS_CODE = Mex_Switchboard.c_Status_Success THEN
				p_XML_RESPONSE_BODY := XMLTYPE.CREATEXML(v_RESULT.RESPONSE);
				v_MISO_ERROR_XML := p_XML_RESPONSE_BODY.EXTRACT('/descendant::Error', g_MISO_NAMESPACE);

				IF (v_MISO_ERROR_XML IS NOT NULL) THEN
					-- query for the <Error> element updated from just Error/ to //Error[1]/, because there
					-- can be multiple <Error> elements in a given response. Fixes bug 9209.
					v_MISO_ERROR_CODE := SAFE_STRING(v_MISO_ERROR_XML, '//Error[1]/Code/text()', g_MISO_NAMESPACE);
					v_MISO_ERROR_MESSAGE := SAFE_STRING(v_MISO_ERROR_XML, '//Error[1]/Text/text()', g_MISO_NAMESPACE);
					v_MISO_ERROR_LINE := SAFE_STRING(v_MISO_ERROR_XML, '//Error[1]/Line/text()', g_MISO_NAMESPACE);
					p_ERROR_MESSAGE := v_MISO_ERROR_CODE || ' ' || v_MISO_ERROR_MESSAGE || ' ' || v_MISO_ERROR_LINE;


					p_LOGGER.LOG_EXCHANGE_ERROR(p_ERROR_MESSAGE);

					p_XML_RESPONSE_BODY := NULL;
				--LOG A SUCCESS IF NO ERROR.
				END IF;
			ELSE
				p_XML_RESPONSE_BODY := NULL;
			END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := 'MISO_EXCHANGE.RUN_MISO_ACTION: ' || SQLERRM;
			p_LOGGER.LOG_EXCHANGE_ERROR(p_ERROR_MESSAGE);
    END RUN_MISO_ACTION;


-------------------------------------------------------------------------------------
    PROCEDURE RUN_MISO_QUERY(
        p_CRED IN mex_credentials,
        p_LOG_ONLY IN NUMBER,
        p_XML_REQUEST_BODY IN XMLTYPE,
        p_XML_RESPONSE_BODY OUT XMLTYPE,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) AS
    BEGIN

        RUN_MISO_ACTION(p_CRED, 'query', p_XML_REQUEST_BODY, p_LOG_ONLY, p_XML_RESPONSE_BODY, p_ERROR_MESSAGE, p_LOGGER);
    END RUN_MISO_QUERY;


-------------------------------------------------------------------------------------
    PROCEDURE RUN_MISO_SUBMIT(
        p_CRED IN mex_credentials,
        p_LOG_ONLY IN NUMBER,
        p_XML_REQUEST_BODY IN XMLTYPE,
        p_PARTY_NAME IN VARCHAR2,
        p_SUBMIT_STATUS OUT VARCHAR2,
        p_MARKET_STATUS OUT VARCHAR2,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_MISO_TRANSACTION_CODE XMLTYPE;
    BEGIN
        --Guilty until proven innocent
        p_SUBMIT_STATUS := g_SUBMIT_STATUS_FAILED;
        p_MARKET_STATUS := g_MKT_STATUS_REJECTED;

        --Append the SubmitRequest tag.
        IF p_PARTY_NAME IS NULL THEN
            SELECT XMLELEMENT("SubmitRequest", XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"), p_XML_REQUEST_BODY)
            INTO   v_XML_REQUEST
            FROM   DUAL;
        ELSE
            SELECT XMLELEMENT("SubmitRequest", XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"), p_XML_REQUEST_BODY)
            INTO   v_XML_REQUEST
            FROM   DUAL;
        END IF;

        RUN_MISO_ACTION(p_CRED, 'submit', v_XML_REQUEST, p_LOG_ONLY , v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);

        IF p_ERROR_MESSAGE IS NULL THEN
            p_SUBMIT_STATUS := g_SUBMIT_STATUS_SUBMITTED;
        END IF;

        --Log the transaction code.
        IF NOT v_XML_RESPONSE IS NULL THEN
            v_MISO_TRANSACTION_CODE := v_XML_RESPONSE.EXTRACT('/SubmitResponse/Success/TransactionID/text()', g_MISO_NAMESPACE);

            IF NOT v_MISO_TRANSACTION_CODE IS NULL THEN
                p_LOGGER.LOG_EXCHANGE_IDENTIFIER(v_MISO_TRANSACTION_CODE.GETSTRINGVAL());
                p_MARKET_STATUS := g_MKT_STATUS_ACCEPTED;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := 'MISO_EXCHANGE.RUN_MISO_SUBMIT: ' || SQLERRM;
    END RUN_MISO_SUBMIT;
-------------------------------------------------------------------------------------
    PROCEDURE RUN_MISO_QUERY_FROM_FILE(
		p_CRED in MEX_Credentials,
        p_XML_REQUEST_BODY IN XMLTYPE,
		p_LOG_ONLY IN BINARY_INTEGER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) AS
        v_XML_RESPONSE_BODY XMLTYPE;
    BEGIN
        RUN_MISO_ACTION(p_CRED, 'queryDirect', p_XML_REQUEST_BODY, p_LOG_ONLY, v_XML_RESPONSE_BODY, p_ERROR_MESSAGE, p_LOGGER);
    END RUN_MISO_QUERY_FROM_FILE;

-------------------------------------------------------------------------------------
    PROCEDURE RUN_MISO_SUBMIT_FROM_FILE(
		p_CRED in MEX_Credentials,
        p_XML_REQUEST_BODY IN XMLTYPE,
		p_LOG_ONLY IN BINARY_INTEGER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) AS
        v_XML_RESPONSE XMLTYPE;
        v_MISO_TRANSACTION_CODE XMLTYPE;
    BEGIN
        RUN_MISO_ACTION(p_CRED, 'submitDirect', p_XML_REQUEST_BODY, p_LOG_ONLY, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);

        --Log the transaction code.
        IF NOT v_XML_RESPONSE IS NULL THEN
            v_MISO_TRANSACTION_CODE := v_XML_RESPONSE.EXTRACT('/SubmitResponse/Success/TransactionID/text()', g_MISO_NAMESPACE);

            IF NOT v_MISO_TRANSACTION_CODE IS NULL THEN
				p_LOGGER.LOG_EXCHANGE_ERROR(v_MISO_TRANSACTION_CODE.GETSTRINGVAL());
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := 'MISO_EXCHANGE.RUN_MISO_SUBMIT_FROM_FILE: ' || SQLERRM;
    END RUN_MISO_SUBMIT_FROM_FILE;

-------------------------------------------------------------------------------------
    FUNCTION BUILD_TRANSACTION_IDENTIFIER(
        p_PARTY_NAME VARCHAR2,
        p_CONTRACT_NAME VARCHAR2
    )
        RETURN VARCHAR2 IS
    BEGIN
        RETURN 'MISO-' || p_PARTY_NAME || ':' || p_CONTRACT_NAME;
    END BUILD_TRANSACTION_IDENTIFIER;

-------------------------------------------------------------------------------------
    PROCEDURE FIX_TRANSACTION_IDENTIFIER(
        p_TRANSACTION_ID IN NUMBER
    ) AS
        v_TRANSACTION_IDENTIFIER INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE;
        v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
        v_PARTY_NAME VARCHAR2(32);
    BEGIN
        SELECT TRANSACTION_NAME, TRANSACTION_IDENTIFIER
        INTO   v_TRANSACTION_NAME, v_TRANSACTION_IDENTIFIER
        FROM   INTERCHANGE_TRANSACTION
        WHERE  TRANSACTION_ID = p_TRANSACTION_ID;

        -- no transaction identifier?
        -- then set it
        IF NVL(TRIM(v_TRANSACTION_IDENTIFIER), '?') = '?' THEN
            v_PARTY_NAME := GET_PARTY_FOR_TRANSACTION(p_TRANSACTION_ID);

            IF v_TRANSACTION_NAME LIKE 'MISO-%:_%' THEN
                v_TRANSACTION_NAME := SUBSTR(v_TRANSACTION_NAME, INSTR(v_TRANSACTION_NAME, ':') + 1);
            END IF;

            v_TRANSACTION_IDENTIFIER := BUILD_TRANSACTION_IDENTIFIER(v_PARTY_NAME, v_TRANSACTION_NAME);

            UPDATE INTERCHANGE_TRANSACTION
            SET TRANSACTION_IDENTIFIER = v_TRANSACTION_IDENTIFIER
            WHERE  TRANSACTION_ID = p_TRANSACTION_ID;
        END IF;
    END FIX_TRANSACTION_IDENTIFIER;

-------------------------------------------------------------------------------------
    PROCEDURE FIN_CONTRACT(
        p_TRANSACTION_ID IN NUMBER,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
    BEGIN
        -- make sure this transaction has a transaction identifier in the appropriate format
        FIX_TRANSACTION_IDENTIFIER(p_TRANSACTION_ID);

        SELECT XMLELEMENT(
                   "FinContract",
                   XMLATTRIBUTES("name", "buyer", "seller", "type"),
                   XMLFOREST(
                       TO_CHAR("EffectiveStart", g_DATE_FORMAT) AS "EffectiveStart",
                       TO_CHAR("EffectiveEnd", g_DATE_FORMAT) AS "EffectiveEnd",
                       "SourceLocation",
                       "SinkLocation",
                       "DeliveryPoint",
                       "ScheduleApproval",
                       "SettlementMarket",
                       --"CongestionLosses",
                       "BuyerComments",
                       "SellerComments"
                   )
               )
        INTO   p_SUBMIT_XML
        FROM   MISO_FIN_CONTRACTS A
        WHERE  TRANSACTION_ID = p_TRANSACTION_ID;
    END FIN_CONTRACT;

-------------------------------------------------------------------------------------
    PROCEDURE FIN_CONFIRM_CONTRACT(
        p_TRANSACTION_ID IN NUMBER,
        p_CONFIRM_OR_REJECT IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
    BEGIN
        SELECT XMLELEMENT("FinConfirm", XMLELEMENT("FinConfirmContract", XMLATTRIBUTES("name", "buyer", "seller", "type", p_CONFIRM_OR_REJECT AS "confirm")))
        INTO   p_SUBMIT_XML
        FROM   MISO_FIN_CONTRACTS A
        WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID;
    END FIN_CONFIRM_CONTRACT;

-------------------------------------------------------------------------------------
    PROCEDURE FIN_SCHEDULE(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_BEGIN_DATE DATE;
        v_END_DATE DATE;
    BEGIN
        UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_SCHEDULE_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

        SELECT   XMLELEMENT(
                     "FinSchedule",
                     XMLATTRIBUTES("name", "buyer", "seller", "type", TO_CHAR(TRUNC(p_SCHEDULE_DATE), g_DATE_FORMAT) AS "day"),
                     XMLELEMENT("FinScheduleData", XMLAGG(XMLELEMENT("FinScheduleHourly", XMLATTRIBUTES(REPLACE(TO_CHAR(D.SCHEDULE_DATE, 'HH24'), '00', '24') AS "hour", TO_CHAR(D.QUANTITY) AS "MW"))
                                                                                                                                                                                                      --      ORDER BY SCHEDULE_DATE (Oracle bug 3065031)
                         ))
                 )
        INTO     p_SUBMIT_XML
        FROM     MISO_FIN_CONTRACTS A, BID_OFFER_SET D, BID_OFFER_STATUS F
        WHERE    A.TRANSACTION_ID = p_TRANSACTION_ID
        AND      D.TRANSACTION_ID = p_TRANSACTION_ID
        AND      D.SCHEDULE_STATE = p_SCHEDULE_STATE
        AND      D.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
        AND      D.SET_NUMBER = 1
        AND      F.TRANSACTION_ID = D.TRANSACTION_ID
        AND      F.SCHEDULE_DATE = D.SCHEDULE_DATE
        AND      F.REVIEW_STATUS = g_RVW_STATUS_ACCEPTED
        --  MISO REQUIRES ALL 24 HOURS.
        --      AND INSTR(p_SUBMIT_HOURS, '''' || TO_CHAR(D.SCHEDULE_DATE,'HH24') || '''') > 0
        GROUP BY "name", "buyer", "seller", "type";
    END FIN_SCHEDULE;

-------------------------------------------------------------------------------------
    PROCEDURE FIN_CONFIRM_SCHEDULE(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_CONFIRM_OR_REJECT IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
    BEGIN
        SELECT XMLELEMENT("FinConfirm", XMLELEMENT("FinConfirmSchedule", XMLATTRIBUTES("name", "buyer", "seller", "type", TO_CHAR(p_SCHEDULE_DATE, g_DATE_FORMAT) AS "day", p_CONFIRM_OR_REJECT AS "confirm")))
        INTO   p_SUBMIT_XML
        FROM   MISO_FIN_CONTRACTS A
        WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID;
    END FIN_CONFIRM_SCHEDULE;

-------------------------------------------------------------------------------------
    PROCEDURE FIXED_DEMAND_BID(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_BEGIN_DATE DATE;
        v_END_DATE DATE;
    BEGIN
        UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_SCHEDULE_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

        -- case statement added b/c MISO apparently can't handle 0 quantities
        SELECT   XMLELEMENT(
                     "FixedDemandBid",
                     XMLATTRIBUTES(TO_CHAR(TRUNC(p_SCHEDULE_DATE), g_DATE_FORMAT) AS "day"),
                     XMLELEMENT("DemandBid", XMLATTRIBUTES(F.EXTERNAL_IDENTIFIER AS "location"), XMLAGG(XMLELEMENT("BidHourly", XMLATTRIBUTES(REPLACE(TO_CHAR(D.SCHEDULE_DATE, 'HH24'), '00', '24') AS "hour", TO_CHAR(ROUND(D.QUANTITY, 1)) AS "MW"))
                                                                                                                                                                                                                                                      --      ORDER BY SCHEDULE_DATE (Oracle bug 3065031)
                         ))
                 )
        INTO     p_SUBMIT_XML
        FROM     BID_OFFER_SET D, INTERCHANGE_TRANSACTION E, SERVICE_POINT F, BID_OFFER_STATUS G
        WHERE    E.TRANSACTION_ID = p_TRANSACTION_ID
        AND      F.SERVICE_POINT_ID = E.POD_ID
        AND      D.TRANSACTION_ID = p_TRANSACTION_ID
        AND      D.SCHEDULE_STATE = p_SCHEDULE_STATE
        AND      D.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
        AND      D.SET_NUMBER = 1
        AND      G.TRANSACTION_ID = D.TRANSACTION_ID
        AND      G.SCHEDULE_DATE = D.SCHEDULE_DATE
        AND      G.REVIEW_STATUS = g_RVW_STATUS_ACCEPTED
        -- MISO apparently can't handle quantities of zero, so we skip these rows
        AND      ROUND(D.QUANTITY, 1) <> 0
        --  MISO REQUIRES ALL 24 HOURS.
        --      AND INSTR(p_SUBMIT_HOURS, '''' || TO_CHAR(D.SCHEDULE_DATE,'HH24') || '''') > 0
        GROUP BY F.EXTERNAL_IDENTIFIER;
    END FIXED_DEMAND_BID;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_FIXED_DEMAND_BID(
        p_PARTY_NAME IN VARCHAR2,
        p_BIDS IN XMLTYPE,
        p_SCHEDULE_STATE IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        v_TRANSACTION_ID NUMBER(9);
        v_SCHEDULE_STATE NUMBER(1) := p_SCHEDULE_STATE;
        v_STATUS NUMBER;
        v_SET_NUMBER NUMBER(2) := 1;
        v_MARKET_TYPE VARCHAR2(16) := g_DAYAHEAD;
        v_PREV_LOCATION VARCHAR2(64) := g_INIT_VAL_VARCHAR;
        v_PREV_SCHEDULE_DAY DATE := LOW_DATE;

        CURSOR c_BID_XML IS
            SELECT TO_DATE(EXTRACTVALUE(VALUE(U), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "SCHEDULE_DAY", EXTRACTVALUE(VALUE(V), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", EXTRACTVALUE(VALUE(W), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR",
                   EXTRACTVALUE(VALUE(W), '//@MW', g_MISO_NAMESPACE) "MW"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_BIDS, '//FixedDemandBid', g_MISO_NAMESPACE))) U, TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//DemandBid', g_MISO_NAMESPACE))) V, TABLE(XMLSEQUENCE(EXTRACT(VALUE(V), '//BidHourly', g_MISO_NAMESPACE))) W;
    BEGIN
        IF LOGS.IS_DEBUG_ENABLED THEN
            LOGS.LOG_DEBUG('PUT_FIXED_DEMAND_BID');
        END IF;

        --LOOP OVER EACH OFFER.
        FOR v_BID_XML IN c_BID_XML LOOP
            IF v_PREV_LOCATION <> v_BID_XML.LOCATION_NAME OR v_PREV_SCHEDULE_DAY <> v_BID_XML.SCHEDULE_DAY THEN
                GET_BID_TRANSACTION_ID('DEMAND',                                                                                                                                                                                                    --BID_TYPE
                    'Load',                                                                                                                                                                                                                 --TRANSACTION_TYPE
                    v_BID_XML.LOCATION_NAME,                                                                                                                                                                                                        --POD_NAME
                    v_BID_XML.SCHEDULE_DAY,                                                                                                                                                                                                     --SCHEDULE_DAY
                    v_MARKET_TYPE,                                                                                                                                                                                                               --MARKET_TYPE
                    'Energy',                                                                                                                                                                                                                 --COMMODITY_TYPE
                    0,                                                                                                                                                                                                                            --IS_VIRTUAL
                    1,                                                                                                                                                                                                                               --IS_FIRM
                    'Hour',                                                                                                                                                                                                             --TRANSACTION_INTERVAL
                    p_PARTY_NAME,                                                                                                                                                                                                                 --PARTY_NAME
                    v_TRANSACTION_ID, p_ERROR_MESSAGE);

                IF LOGS.IS_DEBUG_ENABLED THEN
                    LOGS.LOG_DEBUG('FOUND TRANSACTION ID=' || TO_CHAR(v_TRANSACTION_ID));
                END IF;

                v_PREV_LOCATION := v_BID_XML.LOCATION_NAME;
                v_PREV_SCHEDULE_DAY := v_BID_XML.SCHEDULE_DAY;
            END IF;

------------------------------------------------------
--    PUT BID AMOUNTS
------------------------------------------------------
			SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
            BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID, 0, v_SCHEDULE_STATE, v_BID_XML.SCHEDULE_DAY + v_BID_XML.SCHEDULE_HOUR / 24, v_SET_NUMBER, NULL, v_BID_XML.MW, 'P', MM_MISO_UTIL.g_MISO_TIMEZONE, v_STATUS);

            IF v_STATUS < 0 THEN
                p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) || ' in MISO_EXCHANGE.PUT_FIXED_DEMAND_BID while calling BO.PUT_BID_OFFER_SET.';
                SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                RETURN;
            END IF;
        END LOOP;

        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
            RAISE;
    END PUT_FIXED_DEMAND_BID;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_FIXED_DEMAND_BID(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_LOCATION_NAME IN VARCHAR2,
        p_PORTFOLIO_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT MM_LOGGER_ADAPTER
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_PARTY_TABLE GA.STRING_TABLE;
        v_PARTY_INDEX BINARY_INTEGER;
    BEGIN
        -- no party specified? then do query for all parties
        IF p_PARTY_NAME IS NULL THEN
            GET_PARTIES_FOR_ISO_ACCOUNT(p_CRED.EXTERNAL_ACCOUNT_NAME, v_PARTY_TABLE);
            v_PARTY_INDEX := v_PARTY_TABLE.FIRST;

            WHILE v_PARTY_TABLE.EXISTS(v_PARTY_INDEX) LOOP
                QUERY_FIXED_DEMAND_BID(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), p_LOCATION_NAME, p_PORTFOLIO_NAME, p_SCHEDULE_DAY, p_LOG_ONLY, p_ERROR_MESSAGE, p_LOGGER);
                v_PARTY_INDEX := v_PARTY_TABLE.NEXT(v_PARTY_INDEX);
            END LOOP;

            RETURN;
        END IF;

        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT("QueryFixedDemandBids", XMLATTRIBUTES(TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT) AS "day"), XMLFOREST(p_LOCATION_NAME AS "LocationName", p_PORTFOLIO_NAME AS "PortfolioName"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinSchedule';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE,p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        IF NOT v_XML_RESPONSE IS NULL THEN
            PUT_FIXED_DEMAND_BID(p_PARTY_NAME, v_XML_RESPONSE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_FIXED_DEMAND_BID;

-------------------------------------------------------------------------------------

    FUNCTION GET_BID_OFFER_TRAIT_VAL(
        p_TRAIT_NAME IN VARCHAR2,
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE
    )
        RETURN VARCHAR2 IS
        v_TRAIT_VAL BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
    BEGIN
	--DEPRECATED!!!! -- IN THE FUTURE, DO NOT REFERENCE A TRAIT BY NAME.
	--YOU SHOULD REFERENCE IT BY ID CONSTANT FROM THE MM_MISO_UTIL PACKAGE.
	--THAT WAY YOU DON'T NEED TO LOOK UP THE NAME.
        BEGIN
            SELECT B.TRAIT_VAL
            INTO v_TRAIT_VAL
            FROM TRANSACTION_TRAIT_GROUP A, IT_TRAIT_SCHEDULE B
            WHERE  A.TRAIT_GROUP_NAME = p_TRAIT_NAME
				AND B.TRANSACTION_ID = p_TRANSACTION_ID
				AND B.SCHEDULE_STATE = p_SCHEDULE_STATE
				AND B.SCHEDULE_DATE = p_SCHEDULE_DATE
				AND B.TRAIT_GROUP_ID = A.TRAIT_GROUP_ID
				AND B.TRAIT_INDEX = 1
				AND B.SET_NUMBER = 1
				AND B.STATEMENT_TYPE_ID = 0;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_TRAIT_VAL := NULL;
        END;

        RETURN v_TRAIT_VAL;
    END GET_BID_OFFER_TRAIT_VAL;

-------------------------------------------------------------------------------------
    FUNCTION GET_BID_OFFER_TEMPLATE_VAL(
        p_TRAIT_GROUP_NAME IN VARCHAR2,
        p_TRANSACTION_ID IN NUMBER,
        p_INTERVAL_DATE IN DATE
    )
        RETURN VARCHAR2 IS
        v_TRAIT_VAL IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;
    BEGIN
        BEGIN
            SELECT A.TRAIT_VAL
            INTO v_TRAIT_VAL
            FROM IT_TRAIT_SCHEDULE A, TRANSACTION_TRAIT_GROUP B
            WHERE B.TRAIT_GROUP_NAME = p_TRAIT_GROUP_NAME
				AND A.TRANSACTION_ID = p_TRANSACTION_ID
				AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
				AND A.TRAIT_GROUP_ID = B.TRAIT_GROUP_ID
				AND p_INTERVAL_DATE BETWEEN A.SCHEDULE_DATE AND NVL(A.SCHEDULE_END_DATE, HIGH_DATE)
				AND A.TRAIT_INDEX = 1
				AND A.SET_NUMBER = 1
				AND A.STATEMENT_TYPE_ID = 0;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_TRAIT_VAL := NULL;
        END;

        RETURN v_TRAIT_VAL;
    END GET_BID_OFFER_TEMPLATE_VAL;

-------------------------------------------------------------------------------------
    PROCEDURE UPDATE_SCHEDULE_OFFER(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_SUBMIT_HOURS IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_HOURS VARCHAR2(256);
        v_HOUR_STRING_TABLE GA.STRING_TABLE;
        v_INDEX BINARY_INTEGER := 0;
        v_SCHEDULE_DATE DATE;
        v_CUR_XML XMLTYPE := NULL;
        v_CURRENT_HOUR NUMBER(2);
        v_DISPATCH_LIMIT_MIN BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_DISPATCH_LIMIT_MAX BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMERGENCY_LIMIT_MIN BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMERGENCY_LIMIT_MAX BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_SELF_REG_UP BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_SELF_REG_DOWN BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_SELF_RESERVE BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_RESOURCE_STATUS BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_UPDATE_ARRAY XMLSEQUENCETYPE := XMLSEQUENCETYPE();
        v_ARRAY_IDX BINARY_INTEGER := 1;
    BEGIN
        v_HOURS := REPLACE(p_SUBMIT_HOURS, '''', '');
        UT.TOKENS_FROM_STRING(v_HOURS, ',', v_HOUR_STRING_TABLE);
        v_INDEX := v_HOUR_STRING_TABLE.FIRST;

        --LOOP OVER HOURS.
        LOOP
            v_CURRENT_HOUR := TO_NUMBER(v_HOUR_STRING_TABLE(v_INDEX));
            v_SCHEDULE_DATE := p_SCHEDULE_DATE + v_CURRENT_HOUR / 24;
            v_DISPATCH_LIMIT_MIN := GET_BID_OFFER_TRAIT_VAL('MISO Update Dispatch Minimum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_DISPATCH_LIMIT_MAX := GET_BID_OFFER_TRAIT_VAL('MISO Update Dispatch Maximum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_EMERGENCY_LIMIT_MIN := GET_BID_OFFER_TRAIT_VAL('MISO Update Emergency Minimum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_EMERGENCY_LIMIT_MAX := GET_BID_OFFER_TRAIT_VAL('MISO Update Emergency Maximum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_SELF_REG_UP := GET_BID_OFFER_TRAIT_VAL('MISO Update Self Scheduled Up Reg', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_SELF_REG_DOWN := GET_BID_OFFER_TRAIT_VAL('MISO Update Self Scheduled Down Reg', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_SELF_RESERVE := GET_BID_OFFER_TRAIT_VAL('MISO Update Self Scheduled Reserve', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_RESOURCE_STATUS := GET_BID_OFFER_TRAIT_VAL('MISO Update Resource Status', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_UPDATE_ARRAY.EXTEND();

            SELECT XMLELEMENT(
                       "UpdateHourly",
                       XMLATTRIBUTES(v_CURRENT_HOUR AS "hour"),
                       XMLCONCAT(
                           EXTRACT(XMLELEMENT("DispatchLimits", XMLATTRIBUTES(v_DISPATCH_LIMIT_MIN AS "minMW", v_DISPATCH_LIMIT_MAX AS "maxMW")), '//DispatchLimits[@minMW or @maxMW]'),
                           EXTRACT(XMLELEMENT("EmergencyLimits", XMLATTRIBUTES(v_EMERGENCY_LIMIT_MIN AS "minMW", v_EMERGENCY_LIMIT_MAX AS "maxMW")), '//EmergencyLimits[@minMW or @maxMW]'),
                           EXTRACT(XMLELEMENT("SelfScheduledReg", XMLATTRIBUTES(v_SELF_REG_UP AS "upMW", v_SELF_REG_DOWN AS "downMW")), '//SelfScheduledReg[@upMW or @downMW]'),
                           EXTRACT(XMLELEMENT("SelfScheduledReserve", XMLATTRIBUTES(v_SELF_RESERVE AS "MW")), '//SelfScheduledReserve[@MW]'),
                           EXTRACT(XMLELEMENT("ResourceStatus", v_RESOURCE_STATUS), '//ResourceStatus')
                       )
                   )
            INTO   v_CUR_XML
            FROM   DUAL;

            v_UPDATE_ARRAY(v_ARRAY_IDX) := v_CUR_XML;
            v_ARRAY_IDX := v_ARRAY_IDX + 1;
            v_INDEX := v_HOUR_STRING_TABLE.NEXT(v_INDEX);
            EXIT WHEN v_INDEX = v_HOUR_STRING_TABLE.LAST;

        END LOOP;                                                                                                                                                                                                                                -- OVER HOURS.

        --WRAP WITH THE UPDATE TAG.
        IF NOT v_CUR_XML IS NULL THEN
            SELECT XMLELEMENT("Update", XMLATTRIBUTES(W.EXTERNAL_IDENTIFIER AS "location", TO_CHAR(p_SCHEDULE_DATE, g_DATE_FORMAT) AS "day"), XMLCONCAT(v_UPDATE_ARRAY))
            INTO   p_SUBMIT_XML
            FROM   INTERCHANGE_TRANSACTION U, SERVICE_POINT W
            WHERE  U.TRANSACTION_ID = p_TRANSACTION_ID AND W.SERVICE_POINT_ID = U.POD_ID;
        END IF;
    END UPDATE_SCHEDULE_OFFER;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_UPDATE(
        p_PARTY_NAME IN VARCHAR2,
        p_UPDATE IN XMLTYPE,
        p_SCHEDULE_STATE IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        v_TRANSACTION_ID NUMBER(9);
        v_SCHEDULE_STATE NUMBER(1) := p_SCHEDULE_STATE;
        v_STATUS NUMBER;
        v_SCHEDULE_DAY DATE;
        v_PREV_LOCATION VARCHAR2(64) := g_INIT_VAL_VARCHAR;
        v_PREV_SCHEDULE_DAY DATE := LOW_DATE;
        v_SCHEDULE_HOUR NUMBER(2) := -1;

        CURSOR c_UPDATE_XML IS
            SELECT EXTRACTVALUE(VALUE(T), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "SCHEDULE_DAY", EXTRACTVALUE(VALUE(U), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR",
                   EXTRACTVALUE(VALUE(U), '//DispatchLimits@minMW', g_MISO_NAMESPACE) "DISPATCH_MIN", EXTRACTVALUE(VALUE(U), '//DispatchLimits@maxMW', g_MISO_NAMESPACE) "DISPATCH_MAX",
                   EXTRACTVALUE(VALUE(U), '//EmergencyLimits@minMW', g_MISO_NAMESPACE) "EMERGENCY_MIN", EXTRACTVALUE(VALUE(U), '//EmergencyLimits@maxMW', g_MISO_NAMESPACE) "EMERGENCY_MAX",
                   EXTRACTVALUE(VALUE(U), '//SelfScheduledReg@upMW', g_MISO_NAMESPACE) "SELF_UP", EXTRACTVALUE(VALUE(U), '//SelfScheduledReg@downMW', g_MISO_NAMESPACE) "SELF_DOWN",
                   EXTRACTVALUE(VALUE(U), '//SelfScheduledReserve@MW', g_MISO_NAMESPACE) "SELF_RESERVE", EXTRACTVALUE(VALUE(U), '//ResourceStatus', g_MISO_NAMESPACE) "RESOURCE_STATUS"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_UPDATE, '//Update', g_MISO_NAMESPACE))) T, TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//UpdateHourly', g_MISO_NAMESPACE))) U;

        PROCEDURE PUT_TRAIT_VALUE(
            p_TRAIT_ID IN NUMBER,
            p_TRAIT_VALUE IN VARCHAR2
        ) AS
        BEGIN
            IF p_TRAIT_VALUE IS NOT NULL THEN
                IF LOGS.IS_DEBUG_ENABLED THEN
                    LOGS.LOG_DEBUG('Trait ID=' || p_TRAIT_ID || ' val=' || TO_CHAR(p_TRAIT_VALUE));
                END IF;

                BO.PUT_BID_OFFER_TRAIT(v_TRANSACTION_ID, 0, v_SCHEDULE_STATE, v_SCHEDULE_DAY + v_SCHEDULE_HOUR / 24, p_TRAIT_ID, p_TRAIT_VALUE, MM_MISO_UTIL.g_MISO_TIMEZONE, v_STATUS);

                IF v_STATUS < 0 THEN
                    p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) || ' while saving TraitID=' || p_TRAIT_ID || ' information.  Transaction aborted.';
                    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                    RETURN;
                END IF;
            END IF;
        END PUT_TRAIT_VALUE;
    BEGIN
        IF LOGS.IS_DEBUG_ENABLED THEN
            LOGS.LOG_DEBUG('PUT_UPDATE');
        END IF;

        --LOOP OVER EACH HOUR.
        FOR v_UPDATE_XML IN c_UPDATE_XML LOOP
            --GET THE NEW TXN ID IF THIS IS A NEW LOCATION OR DAY.
            IF v_PREV_LOCATION <> v_UPDATE_XML.LOCATION_NAME OR v_PREV_SCHEDULE_DAY <> v_SCHEDULE_DAY THEN
                GET_BID_TRANSACTION_ID('GEN',                                                                                                                                                                                                       --BID_TYPE
                    'Generation',                                                                                                                                                                                                           --TRANSACTION_TYPE
                    v_UPDATE_XML.LOCATION_NAME,                                                                                                                                                                                                     --POD_NAME
                    v_UPDATE_XML.SCHEDULE_DAY,                                                                                                                                                                                                  --SCHEDULE_DAY
                    g_REALTIME,                                                                                                                         --MARKET_TYPE --TODO: THIS IS A PROBLEM.  WHAT MARKET IS IT? FIX MESSAGE TOO --v_OFFER_XML.MARKET_TYPE
                    'Energy',                                                                                                                                                                                                                 --COMMODITY_TYPE
                    0,                                                                                                                                                                                                                            --IS_VIRTUAL
                    0,                                                                                                                                                                                                                               --IS_FIRM
                    'Hour',                                                                                                                                                                                                             --TRANSACTION_INTERVAL
                    p_PARTY_NAME,                                                                                                                                                                                                                 --PARTY_NAME
                    v_TRANSACTION_ID, p_ERROR_MESSAGE);

                IF LOGS.IS_DEBUG_ENABLED THEN
                    LOGS.LOG_DEBUG('FOUND TRANSACTION ID=' || TO_CHAR(v_TRANSACTION_ID));
                END IF;

                v_PREV_LOCATION := v_UPDATE_XML.LOCATION_NAME;
                v_PREV_SCHEDULE_DAY := v_SCHEDULE_DAY;
            END IF;

            v_SCHEDULE_HOUR := v_UPDATE_XML.SCHEDULE_HOUR;
------------------------------------------------------
--    UPDATE TRAIT VALUES.
------------------------------------------------------
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_DISPATCH_MIN, v_UPDATE_XML.DISPATCH_MIN);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_DISPATCH_MAX, v_UPDATE_XML.DISPATCH_MAX);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_EMER_MIN, v_UPDATE_XML.EMERGENCY_MIN);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_EMER_MAX, v_UPDATE_XML.EMERGENCY_MAX);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_SELF_UP_REG, v_UPDATE_XML.SELF_UP);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_SELF_DOWN_REG, v_UPDATE_XML.SELF_DOWN);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_SELF_RESERVE, v_UPDATE_XML.SELF_RESERVE);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_UPD_RESOURCE_STATUS, v_UPDATE_XML.RESOURCE_STATUS);
        END LOOP;

        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
            RAISE;
    END PUT_UPDATE;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_UPDATE(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_LOCATION_NAME IN VARCHAR2,
        p_PORTFOLIO_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT MM_LOGGER_ADAPTER
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
    BEGIN
        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT("QueryUpdate", XMLATTRIBUTES(TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT) AS "day"), XMLFOREST(p_LOCATION_NAME AS "LocationName", p_PORTFOLIO_NAME AS "PortfolioName"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinSchedule';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        IF NOT v_XML_RESPONSE IS NULL THEN
            PUT_UPDATE(p_PARTY_NAME, v_XML_RESPONSE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_UPDATE;

-------------------------------------------------------------------------------------
    PROCEDURE SCHEDULE_OFFER(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_BEGIN_DATE DATE;
        v_END_DATE DATE;
        v_SCHEDULE_DATE DATE := TRUNC(p_SCHEDULE_DATE) + 1 / 86400;
        v_OFFER_PRICE_CURVE_XML XMLTYPE;
        v_DAILY_TRAITS_XML XMLTYPE;
        v_HOURLY_NO_LOAD_XML XMLTYPE;
        v_HOURLY_SELF_XML XMLTYPE;
        v_HOURLY_STATUS_XML XMLTYPE;
        v_DISPATCH_LIMIT_MIN BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_DISPATCH_LIMIT_MAX BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMERGENCY_LIMIT_MIN BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMERGENCY_LIMIT_MAX BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_COLD_STARTUP_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_INTERMEDIATE_STARTUP_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_HOT_STARTUP_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_MINIMUM_RUNTIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_MAXIMUM_RUNTIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_MINIMUM_DOWNTIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_HOT_TO_COLD_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_HOT_TO_INT_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_COLD_STARTUP_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_INTERMEDIATE_STARTUP_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_HOT_STARTUP_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_COLD_NOTIF_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_INTERMEDIATE_NOTIF_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_HOT_NOTIF_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_MAX_DAILY_STARTS BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_MAX_DAILY_ENERGY BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_MAX_WEEKLY_STARTS BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_MAX_WEEKLY_ENERGY BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_IS_CONDENSING_AVAILABLE BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_CONDENSE_NOTIF_TIME BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_CONDENSE_STARTUP_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_CONDENSE_HOURLY_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_CONDENSE_POWER BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
    BEGIN
        UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_SCHEDULE_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

        --OFFER PRICE CURVE ---------------------------------------------------------
        SELECT XMLELEMENT(
                   "OfferPriceCurve",
                   XMLAGG(
                       (SELECT XMLELEMENT("PriceCurveHourly", XMLATTRIBUTES(REPLACE(TO_CHAR(D.SCHEDULE_DATE, 'HH24'), '00', '24') AS "hour", NVL(C.TRAIT_VAL, 'false') AS "slope"),
                                   XMLAGG(XMLELEMENT("PricePoint", XMLATTRIBUTES(QUANTITY AS "MW", PRICE AS "price"))))
                        FROM   BID_OFFER_SET A
                        WHERE  A.TRANSACTION_ID = D.TRANSACTION_ID AND A.SCHEDULE_STATE = D.SCHEDULE_STATE AND A.SCHEDULE_DATE = D.SCHEDULE_DATE)
                   )
               )
        INTO   v_OFFER_PRICE_CURVE_XML
        FROM   BID_OFFER_SET D, BID_OFFER_TRAIT C, BID_OFFER_STATUS F
        WHERE    D.TRANSACTION_ID = p_TRANSACTION_ID
        AND    D.SCHEDULE_STATE = p_SCHEDULE_STATE
        AND    D.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
        AND    D.SET_NUMBER = 1
        AND    F.TRANSACTION_ID = D.TRANSACTION_ID
        AND    F.SCHEDULE_DATE = D.SCHEDULE_DATE
        AND    F.REVIEW_STATUS = g_RVW_STATUS_ACCEPTED
        AND    C.TRANSACTION_ID(+) = D.TRANSACTION_ID
        AND    C.SCHEDULE_STATE(+) = D.SCHEDULE_STATE
        AND    C.SCHEDULE_DATE(+) = D.SCHEDULE_DATE
        AND    C.RESOURCE_TRAIT_ID(+) = MM_MISO_UTIL.g_TG_OFF_SLOPE;

        --DAILY RESOURCE TRAITS ---------------------------------------------------------
        BEGIN
            v_COLD_STARTUP_COST := GET_BID_OFFER_TRAIT_VAL('MISO Offer Cold Startup Cost', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_INTERMEDIATE_STARTUP_COST := GET_BID_OFFER_TRAIT_VAL('MISO Offer Intermediate Startup Cost', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_HOT_STARTUP_COST := GET_BID_OFFER_TRAIT_VAL('MISO Offer Hot Startup Cost', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_DISPATCH_LIMIT_MIN := GET_BID_OFFER_TRAIT_VAL('MISO Offer Dispatch Minimum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_DISPATCH_LIMIT_MAX := GET_BID_OFFER_TRAIT_VAL('MISO Offer Dispatch Maximum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_EMERGENCY_LIMIT_MIN := GET_BID_OFFER_TRAIT_VAL('MISO Offer Emergency Minimum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_EMERGENCY_LIMIT_MAX := GET_BID_OFFER_TRAIT_VAL('MISO Offer Emergency Maximum', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_MINIMUM_RUNTIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Minimum Runtime', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_MAXIMUM_RUNTIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Maximum Runtime', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_MINIMUM_DOWNTIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Minimum Downtime', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_HOT_TO_COLD_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Hot to Cold Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_HOT_TO_INT_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Hot to Intermediate Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_COLD_STARTUP_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Cold Startup Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_INTERMEDIATE_STARTUP_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Intermediate Startup Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_HOT_STARTUP_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Hot Startup Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_COLD_NOTIF_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Cold Notification Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_INTERMEDIATE_NOTIF_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Intermediate Notification Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_HOT_NOTIF_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Hot Notification Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_MAX_DAILY_STARTS := GET_BID_OFFER_TRAIT_VAL('MISO Offer Maximum Daily Starts', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_MAX_DAILY_ENERGY := GET_BID_OFFER_TRAIT_VAL('MISO Offer Maximum Daily Energy', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_MAX_WEEKLY_STARTS := GET_BID_OFFER_TRAIT_VAL('MISO Offer Maximum Weekly Starts', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_MAX_WEEKLY_ENERGY := GET_BID_OFFER_TRAIT_VAL('MISO Offer Maximum Weekly Energy', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_IS_CONDENSING_AVAILABLE := GET_BID_OFFER_TRAIT_VAL('MISO Offer Condensing Availability', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_CONDENSE_NOTIF_TIME := GET_BID_OFFER_TRAIT_VAL('MISO Offer Condense Notification Time', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_CONDENSE_STARTUP_COST := GET_BID_OFFER_TRAIT_VAL('MISO Offer Condense Startup Cost', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_CONDENSE_HOURLY_COST := GET_BID_OFFER_TRAIT_VAL('MISO Offer Condense Hourly Cost', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);
            v_CONDENSE_POWER := GET_BID_OFFER_TRAIT_VAL('MISO Offer Condense Power', p_TRANSACTION_ID, p_SCHEDULE_STATE, v_SCHEDULE_DATE);

            SELECT XMLCONCAT(
                       XMLELEMENT("OfferStartupCosts", XMLFOREST(v_COLD_STARTUP_COST AS "ColdStartupCost", v_INTERMEDIATE_STARTUP_COST AS "IntermediateStartupCost", v_HOT_STARTUP_COST AS "HotStartupCost")),
                       XMLELEMENT(
                           "Limits",
                           CASE
                               WHEN v_DISPATCH_LIMIT_MIN IS NULL AND v_DISPATCH_LIMIT_MAX IS NULL THEN NULL
                               ELSE XMLELEMENT("DispatchLimits", XMLATTRIBUTES(v_DISPATCH_LIMIT_MIN AS "minMW", v_DISPATCH_LIMIT_MAX AS "maxMW"))
                           END,
                           CASE
                               WHEN v_EMERGENCY_LIMIT_MIN IS NULL AND v_EMERGENCY_LIMIT_MAX IS NULL THEN NULL
                               ELSE XMLELEMENT("EmergencyLimits", XMLATTRIBUTES(v_EMERGENCY_LIMIT_MIN AS "minMW", v_EMERGENCY_LIMIT_MAX AS "maxMW"))
                           END
                       ),
                       XMLELEMENT(
                           "Runtimes",
                           XMLFOREST(
                               v_MINIMUM_RUNTIME AS "MinimumRuntime",
                               v_MAXIMUM_RUNTIME AS "MaximumRuntime",
                               v_MINIMUM_DOWNTIME AS "MinimumDowntime",
                               v_HOT_TO_COLD_TIME AS "HotToColdTime",
                               v_HOT_TO_INT_TIME AS "HotToIntermediateTime",
                               v_COLD_STARTUP_TIME AS "ColdStartupTime",
                               v_INTERMEDIATE_STARTUP_TIME AS "IntermediateStartupTime",
                               v_HOT_STARTUP_TIME AS "HotStartupTime",
                               v_COLD_NOTIF_TIME AS "ColdNotificationTime",
                               v_INTERMEDIATE_NOTIF_TIME AS "IntermediateNotificationTime",
                               v_HOT_NOTIF_TIME AS "HotNotificationTime",
                               v_MAX_DAILY_STARTS AS "MaximumDailyStarts",
                               v_MAX_DAILY_ENERGY AS "MaximumDailyEnergy",
                               v_MAX_WEEKLY_STARTS AS "MaximumWeeklyStarts",
                               v_MAX_WEEKLY_ENERGY AS "MaximumWeeklyEnergy"
                           )
                       ),
                       XMLELEMENT(
                           "CondensingUnit",
                           XMLFOREST(
                               v_IS_CONDENSING_AVAILABLE AS "CondensingAvailability",
                               v_CONDENSE_NOTIF_TIME AS "CondenseNotificationTime",
                               v_CONDENSE_STARTUP_COST AS "CondenseStartupCost",
                               v_CONDENSE_HOURLY_COST AS "CondenseHourlyCost",
                               v_CONDENSE_POWER AS "CondensePower"
                           )
                       )
                   )
            INTO   v_DAILY_TRAITS_XML
            FROM   DUAL;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_DAILY_TRAITS_XML := NULL;
        END;

        --HOURY NO LOAD COSTS ---------------------------------------------------------
        BEGIN
            SELECT XMLELEMENT("OfferNoLoadCosts", XMLAGG(CASE
                               WHEN B.TRAIT_VAL IS NULL THEN NULL
                               ELSE XMLELEMENT("NoLoadCostHourly", XMLATTRIBUTES(REPLACE(TO_CHAR(B.SCHEDULE_DATE, 'HH24'), '00', '24') AS "hour", B.TRAIT_VAL AS "cost"))
                           END))
            INTO   v_HOURLY_NO_LOAD_XML
            FROM   BID_OFFER_TRAIT B
            WHERE B.TRANSACTION_ID = p_TRANSACTION_ID
            AND    B.SCHEDULE_STATE = p_SCHEDULE_STATE
            AND    B.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
            AND    B.RESOURCE_TRAIT_ID = MM_MISO_UTIL.g_TG_OFF_NO_LOAD_COST;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_HOURLY_NO_LOAD_XML := NULL;
        END;

        --HOURY SELF SCHEDULED ---------------------------------------------------------
        BEGIN
            SELECT XMLELEMENT("SelfSchedule", XMLAGG(CASE
                               WHEN B.TRAIT_VAL IS NULL THEN NULL
                               ELSE XMLELEMENT("SelfScheduleHourly", XMLATTRIBUTES(REPLACE(TO_CHAR(B.SCHEDULE_DATE, 'HH24'), '00', '24') AS "hour", B.TRAIT_VAL AS "MW"))
                           END))
            INTO   v_HOURLY_SELF_XML
            FROM   BID_OFFER_TRAIT B
            WHERE  B.TRANSACTION_ID = p_TRANSACTION_ID
            AND    B.SCHEDULE_STATE = p_SCHEDULE_STATE
            AND    B.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
            AND    B.RESOURCE_TRAIT_ID = MM_MISO_UTIL.g_TG_OFF_SELF_SCHEDULE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_HOURLY_SELF_XML := NULL;
        END;

        --HOURY COMMIT STATUS ---------------------------------------------------------
        BEGIN
            SELECT XMLELEMENT("CommitStatus", XMLAGG(CASE
                               WHEN B.TRAIT_VAL IS NULL THEN NULL
                               ELSE XMLELEMENT("CommitStatusHourly", XMLATTRIBUTES(REPLACE(TO_CHAR(B.SCHEDULE_DATE, 'HH24'), '00', '24') AS "hour", B.TRAIT_VAL AS "status"))
                           END))
            INTO   v_HOURLY_STATUS_XML
            FROM   BID_OFFER_TRAIT B
            WHERE  B.TRANSACTION_ID = p_TRANSACTION_ID
            AND    B.SCHEDULE_STATE = p_SCHEDULE_STATE
            AND    B.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
            AND    B.RESOURCE_TRAIT_ID = MM_MISO_UTIL.g_TG_OFF_COMMIT_STATUS;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_HOURLY_STATUS_XML := NULL;
        END;

        --CONCATENATE INTO ONE XML ---------------------------------------------------
        SELECT XMLELEMENT(
                   "ScheduleOffer",
                   XMLATTRIBUTES(F.EXTERNAL_IDENTIFIER AS "location", G.MARKET_TYPE AS "market", TO_CHAR(TRUNC(p_SCHEDULE_DATE), g_DATE_FORMAT) AS "day"),
                   XMLCONCAT(
                       v_OFFER_PRICE_CURVE_XML,
                       EXTRACT(v_DAILY_TRAITS_XML, '/child::node()[child::*]'),                                                                                                                                                        --NO CHILDLESS ELEMENTS.
                       EXTRACT(v_HOURLY_NO_LOAD_XML, '/child::node()[child::*]'),                                                                                                                                                      --NO CHILDLESS ELEMENTS.
                       EXTRACT(v_HOURLY_STATUS_XML, '/child::node()[child::*]'),                                                                                                                                                       --NO CHILDLESS ELEMENTS.
                       EXTRACT(v_HOURLY_SELF_XML, '/child::node()[child::*]')
                   )
               )
        INTO   p_SUBMIT_XML
        FROM   INTERCHANGE_TRANSACTION E, SERVICE_POINT F, IT_COMMODITY G
        WHERE  E.TRANSACTION_ID = p_TRANSACTION_ID AND F.SERVICE_POINT_ID = E.POD_ID AND G.COMMODITY_ID = E.COMMODITY_ID;
    END SCHEDULE_OFFER;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_SCHEDULE_OFFER(
        p_PARTY_NAME IN VARCHAR2,
        p_OFFERS IN XMLTYPE,
        p_SCHEDULE_STATE IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        v_TRANSACTION_ID NUMBER(9);
        v_SCHEDULE_STATE NUMBER(1) := p_SCHEDULE_STATE;
        v_STATUS NUMBER;
        v_PREV_HOUR NUMBER(2) := -1;
        v_SET_NUMBER NUMBER(2) := 1;
        v_SCHEDULE_DAY DATE;

        CURSOR c_OFFER_XML IS
            SELECT EXTRACTVALUE(VALUE(T), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", EXTRACTVALUE(VALUE(T), '//@market', g_MISO_NAMESPACE) "MARKET_TYPE", TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "SCHEDULE_DAY",
                   EXTRACT(VALUE(T), '//ScheduleOffer', g_MISO_NAMESPACE) "OFFER_XML", EXTRACTVALUE(VALUE(T), '//OfferStartupCosts/ColdStartupCost', g_MISO_NAMESPACE) "COLD_STARTUP_COST",
                   EXTRACTVALUE(VALUE(T), '//OfferStartupCosts/IntermediateStartupCost', g_MISO_NAMESPACE) "INTERMEDIATE_STARTUP_COST", EXTRACTVALUE(VALUE(T), '//OfferStartupCosts/HotStartupCost', g_MISO_NAMESPACE) "HOT_STARTUP_COST",
                   EXTRACT(VALUE(T), '//OfferNoLoadCosts', g_MISO_NAMESPACE) "NO_LOAD_XML", EXTRACT(VALUE(T), '//SelfSchedule', g_MISO_NAMESPACE) "SELF_SCHEDULE_XML",
                   EXTRACTVALUE(VALUE(T), '//Limits/DispatchLimits@minMW', g_MISO_NAMESPACE) "DISPATCH_MIN", EXTRACTVALUE(VALUE(T), '//Limits/DispatchLimits@maxMW', g_MISO_NAMESPACE) "DISPATCH_MAX",
                   EXTRACTVALUE(VALUE(T), '//Limits/EmergencyLimits@minMW', g_MISO_NAMESPACE) "EMERGENCY_MIN", EXTRACTVALUE(VALUE(T), '//Limits/EmergencyLimits@maxMW', g_MISO_NAMESPACE) "EMERGENCY_MAX",
                   EXTRACT(VALUE(T), '//CommitStatus', g_MISO_NAMESPACE) "COMMIT_STATUS_XML", EXTRACTVALUE(VALUE(T), '//Runtimes/MinimumRuntime', g_MISO_NAMESPACE) "MINIMUM_RUNTIME",
                   EXTRACTVALUE(VALUE(T), '//Runtimes/MaximumRuntime', g_MISO_NAMESPACE) "MAXIMUM_RUNTIME", EXTRACTVALUE(VALUE(T), '//Runtimes/MinimumDowntime', g_MISO_NAMESPACE) "MINIMUM_DOWNTIME",
                   EXTRACTVALUE(VALUE(T), '//Runtimes/HotToColdTime', g_MISO_NAMESPACE) "HOT_TO_COLD", EXTRACTVALUE(VALUE(T), '//Runtimes/HotToIntermediateTime', g_MISO_NAMESPACE) "HOT_TO_INTERMEDIATE",
                   EXTRACTVALUE(VALUE(T), '//Runtimes/ColdStartupTime', g_MISO_NAMESPACE) "COLD_STARTUP", EXTRACTVALUE(VALUE(T), '//Runtimes/IntermediateStartupTime', g_MISO_NAMESPACE) "INTERMEDIATE_STARTUP",
                   EXTRACTVALUE(VALUE(T), '//Runtimes/HotStartupTime', g_MISO_NAMESPACE) "HOT_STARTUP", EXTRACTVALUE(VALUE(T), '//Runtimes/ColdNotificationTime', g_MISO_NAMESPACE) "COLD_NOTIFICATION",
                   EXTRACTVALUE(VALUE(T), '//Runtimes/IntermediateNotificationTime', g_MISO_NAMESPACE) "INTERMEDIATE_NOTIFICATION", EXTRACTVALUE(VALUE(T), '//Runtimes/HotNotificationTime', g_MISO_NAMESPACE) "HOT_NOTIFICATION",
                   EXTRACTVALUE(VALUE(T), '//Runtimes/MaximumDailyStarts', g_MISO_NAMESPACE) "MAXIMUM_DAILY_STARTS", EXTRACTVALUE(VALUE(T), '//Runtimes/MaximumDailyEnergy', g_MISO_NAMESPACE) "MAXIMUM_DAILY_ENERGY",
                   EXTRACTVALUE(VALUE(T), '//Runtimes/MaximumWeeklyStarts', g_MISO_NAMESPACE) "MAXIMUM_WEEKLY_STARTS", EXTRACTVALUE(VALUE(T), '//Runtimes/MaximumWeeklyEnergy', g_MISO_NAMESPACE) "MAXIMUM_WEEKLY_ENERGY",
                   EXTRACTVALUE(VALUE(T), '//CondensingUnit/CondensingAvailability', g_MISO_NAMESPACE) "CONDENSING_AVAILABILITY", EXTRACTVALUE(VALUE(T), '//CondensingUnit/CondenseNotificationTime', g_MISO_NAMESPACE) "CONDENSE_NOTIFICATION",
                   EXTRACTVALUE(VALUE(T), '//CondensingUnit/CondenseStartupCost', g_MISO_NAMESPACE) "CONDENSE_STARTUP_COST", EXTRACTVALUE(VALUE(T), '//CondensingUnit/CondenseHourlyCost', g_MISO_NAMESPACE) "CONDENSE_HOURLY_COST",
                   EXTRACTVALUE(VALUE(T), '//CondensingUnit/CondensePower', g_MISO_NAMESPACE) "CONDENSE_POWER"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_OFFERS, '//ScheduleOffer', g_MISO_NAMESPACE))) T;

        CURSOR c_PRICE_CURVE(
            v_XML IN XMLTYPE
        ) IS
            SELECT EXTRACTVALUE(VALUE(T), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR", EXTRACTVALUE(VALUE(T), '//@slope', g_MISO_NAMESPACE) "SLOPE", EXTRACTVALUE(VALUE(U), '//@MW', g_MISO_NAMESPACE) "MW",
                   EXTRACTVALUE(VALUE(U), '//@price', g_MISO_NAMESPACE) "PRICE"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML, '//OfferPriceCurve/PriceCurveHourly', g_MISO_NAMESPACE))) T, TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//PricePoint', g_MISO_NAMESPACE))) U;

        CURSOR c_NO_LOAD(
            v_XML IN XMLTYPE
        ) IS
            SELECT EXTRACTVALUE(VALUE(T), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR", EXTRACTVALUE(VALUE(T), '//@cost', g_MISO_NAMESPACE) "COST"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML, '//OfferNoLoadCosts/NoLoadCostHourly', g_MISO_NAMESPACE))) T;

        CURSOR c_SELF_SCHEDULE(
            v_XML IN XMLTYPE
        ) IS
            SELECT EXTRACTVALUE(VALUE(T), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR", EXTRACTVALUE(VALUE(T), '//@MW', g_MISO_NAMESPACE) "MW"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML, '//SelfSchedule/SelfScheduleHourly', g_MISO_NAMESPACE))) T;

        CURSOR c_COMMIT_STATUS(
            v_XML IN XMLTYPE
        ) IS
            SELECT EXTRACTVALUE(VALUE(T), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR", EXTRACTVALUE(VALUE(T), '//@status', g_MISO_NAMESPACE) "STATUS"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML, '//CommitStatus/CommitStatusHourly', g_MISO_NAMESPACE))) T;

        PROCEDURE PUT_TRAIT_VALUE(
            p_TRAIT_ID IN NUMBER,
            p_TRAIT_VALUE IN VARCHAR2,
            p_HOUR IN NUMBER := 0
        ) AS
        BEGIN
            IF p_TRAIT_VALUE IS NOT NULL THEN
                BO.PUT_BID_OFFER_TRAIT(v_TRANSACTION_ID, 0, v_SCHEDULE_STATE, v_SCHEDULE_DAY + p_HOUR / 24, p_TRAIT_ID, p_TRAIT_VALUE, MM_MISO_UTIL.g_MISO_TIMEZONE, v_STATUS);

                IF v_STATUS < 0 THEN
                    p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) || ' while saving TraitID=' || p_TRAIT_ID || ' information.  Transaction aborted.';
                    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                    RETURN;
                END IF;
            END IF;
        END PUT_TRAIT_VALUE;
    BEGIN
        IF LOGS.IS_DEBUG_ENABLED THEN
            LOGS.LOG_DEBUG('PUT_SCHEDULE_OFFER');
        END IF;

        --LOOP OVER EACH OFFER.
        FOR v_OFFER_XML IN c_OFFER_XML LOOP
            v_SCHEDULE_DAY := v_OFFER_XML.SCHEDULE_DAY;
            GET_BID_TRANSACTION_ID('GEN',                                                                                                                                                                                                           --BID_TYPE
                'Generation',                                                                                                                                                                                                               --TRANSACTION_TYPE
                v_OFFER_XML.LOCATION_NAME,                                                                                                                                                                                                          --POD_NAME
                v_OFFER_XML.SCHEDULE_DAY,                                                                                                                                                                                                       --SCHEDULE_DAY
                v_OFFER_XML.MARKET_TYPE,                                                                                                                                                                                                         --MARKET_TYPE
                'Energy',                                                                                                                                                                                                                     --COMMODITY_TYPE
                0,                                                                                                                                                                                                                                --IS_VIRTUAL
                0,                                                                                                                                                                                                                                   --IS_FIRM
                'Hour',                                                                                                                                                                                                                 --TRANSACTION_INTERVAL
                p_PARTY_NAME,                                                                                                                                                                                                                     --PARTY_NAME
                v_TRANSACTION_ID, p_ERROR_MESSAGE);

            IF LOGS.IS_DEBUG_ENABLED THEN
                LOGS.LOG_DEBUG('FOUND TRANSACTION ID=' || TO_CHAR(v_TRANSACTION_ID));
            END IF;

------------------------------------------------------
--    OFFER PRICE CURVE
------------------------------------------------------
            SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

            FOR v_PRICE_CURVE IN c_PRICE_CURVE(v_OFFER_XML.OFFER_XML) LOOP
                IF v_PREV_HOUR <> v_PRICE_CURVE.SCHEDULE_HOUR THEN
                    v_PREV_HOUR := v_PRICE_CURVE.SCHEDULE_HOUR;
                    v_SET_NUMBER := 1;
                    --SAVE THE SLOPE IF IT IS DEFINED.
                    PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_SLOPE, v_PRICE_CURVE.SLOPE, v_PRICE_CURVE.SCHEDULE_HOUR);
                END IF;

                SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
                BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID, 0, v_SCHEDULE_STATE, v_OFFER_XML.SCHEDULE_DAY + v_PRICE_CURVE.SCHEDULE_HOUR / 24, v_SET_NUMBER, v_PRICE_CURVE.PRICE, v_PRICE_CURVE.MW, 'P', MM_MISO_UTIL.g_MISO_TIMEZONE, v_STATUS);

                IF v_STATUS < 0 THEN
                    p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) || ' in MISO_EXCHANGE.PUT_SCHEDULE_OFFER while calling BO.PUT_BID_OFFER_SET.';
                    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                    RETURN;
                END IF;

                v_SET_NUMBER := v_SET_NUMBER + 1;
            END LOOP;

------------------------------------------------------
--    STARTUP COSTS
------------------------------------------------------
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_COLD_START_COST, v_OFFER_XML.COLD_STARTUP_COST);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_INTER_START_COST, v_OFFER_XML.INTERMEDIATE_STARTUP_COST);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_HOT_START_COST, v_OFFER_XML.HOT_STARTUP_COST);

            FOR v_NO_LOAD IN c_NO_LOAD(v_OFFER_XML.NO_LOAD_XML) LOOP
                PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_NO_LOAD_COST, v_NO_LOAD.COST, v_NO_LOAD.SCHEDULE_HOUR);
            END LOOP;

------------------------------------------------------
--    SELF SCHEDULE
------------------------------------------------------
            FOR v_SELF_SCHEDULE IN c_SELF_SCHEDULE(v_OFFER_XML.SELF_SCHEDULE_XML) LOOP
                PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_SELF_SCHEDULE, v_SELF_SCHEDULE.MW, v_SELF_SCHEDULE.SCHEDULE_HOUR);
            END LOOP;

------------------------------------------------------
--    LIMITS
------------------------------------------------------
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_DISPATCH_MIN, v_OFFER_XML.DISPATCH_MIN);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_DISPATCH_MAX, v_OFFER_XML.DISPATCH_MAX);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_EMER_MIN, v_OFFER_XML.EMERGENCY_MIN);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_EMER_MAX, v_OFFER_XML.EMERGENCY_MAX);

------------------------------------------------------
--    COMMIT STATUS
------------------------------------------------------
            FOR v_COMMIT_STATUS IN c_COMMIT_STATUS(v_OFFER_XML.COMMIT_STATUS_XML) LOOP
                PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_COMMIT_STATUS, v_COMMIT_STATUS.STATUS, v_COMMIT_STATUS.SCHEDULE_HOUR);
            END LOOP;

------------------------------------------------------
--    RUNTIMES
------------------------------------------------------
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_MIN_RUNTIME, v_OFFER_XML.MINIMUM_RUNTIME);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_MAX_RUNTIME, v_OFFER_XML.MAXIMUM_RUNTIME);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_MIN_DOWNTIME, v_OFFER_XML.MINIMUM_DOWNTIME);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_HOT_TO_COLD_TIME, v_OFFER_XML.HOT_TO_COLD);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_HOT_TO_INTER_TIME, v_OFFER_XML.HOT_TO_INTERMEDIATE);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_COLD_START_TIME, v_OFFER_XML.COLD_STARTUP);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_INTER_START_TIME, v_OFFER_XML.INTERMEDIATE_STARTUP);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_HOT_START_TIME, v_OFFER_XML.HOT_STARTUP);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_COLD_NOTIF_TIME, v_OFFER_XML.COLD_NOTIFICATION);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_INTER_NOTIF_TIME, v_OFFER_XML.INTERMEDIATE_NOTIFICATION);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_HOT_NOTIF_TIME, v_OFFER_XML.HOT_NOTIFICATION);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_MAX_DAILY_STARTS, v_OFFER_XML.MAXIMUM_DAILY_STARTS);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_MAX_DAILY_ENERGY, v_OFFER_XML.MAXIMUM_DAILY_ENERGY);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_MAX_WEEKLY_STARTS, v_OFFER_XML.MAXIMUM_WEEKLY_STARTS);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_MAX_WEEKLY_ENERGY, v_OFFER_XML.MAXIMUM_WEEKLY_ENERGY);
------------------------------------------------------
--    CONDENSING UNIT
------------------------------------------------------
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_CONDENSE_AVAIL, v_OFFER_XML.CONDENSING_AVAILABILITY);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_CONDENSE_NOTIF_TIME, v_OFFER_XML.CONDENSE_NOTIFICATION);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_CONDENSE_START_COST, v_OFFER_XML.CONDENSE_STARTUP_COST);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_CONDENSE_HOURLY_COST, v_OFFER_XML.CONDENSE_HOURLY_COST);
            PUT_TRAIT_VALUE(MM_MISO_UTIL.g_TG_OFF_CONDENSE_POWER, v_OFFER_XML.CONDENSE_POWER);
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
            RAISE;
    END PUT_SCHEDULE_OFFER;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_SCHEDULE_OFFER(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_LOCATION_NAME IN VARCHAR2,
        p_PORTFOLIO_NAME IN VARCHAR2,
        p_MARKET_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT MM_LOGGER_ADAPTER
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_PARTY_TABLE GA.STRING_TABLE;
        v_PARTY_INDEX BINARY_INTEGER;
    BEGIN
        -- no party specified? then do query for all parties
        IF p_PARTY_NAME IS NULL THEN
            GET_PARTIES_FOR_ISO_ACCOUNT(p_CRED.EXTERNAL_ACCOUNT_NAME, v_PARTY_TABLE);
            v_PARTY_INDEX := v_PARTY_TABLE.FIRST;

            WHILE v_PARTY_TABLE.EXISTS(v_PARTY_INDEX) LOOP
                QUERY_SCHEDULE_OFFER(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), p_LOCATION_NAME, p_PORTFOLIO_NAME, p_MARKET_NAME, p_SCHEDULE_DAY, p_LOG_ONLY, p_ERROR_MESSAGE, p_LOGGER);
                v_PARTY_INDEX := v_PARTY_TABLE.NEXT(v_PARTY_INDEX);
            END LOOP;

            RETURN;
        END IF;

        IF p_MARKET_NAME IS NULL THEN
            -- no market specified?
            -- then execute for both
            --    realtime
            QUERY_SCHEDULE_OFFER(p_CRED, p_PARTY_NAME, p_LOCATION_NAME, p_PORTFOLIO_NAME, g_REALTIME, p_SCHEDULE_DAY, p_LOG_ONLY, p_ERROR_MESSAGE, p_LOGGER);
            --    and dayahead
            QUERY_SCHEDULE_OFFER(p_CRED, p_PARTY_NAME, p_LOCATION_NAME, p_PORTFOLIO_NAME, g_DAYAHEAD, p_SCHEDULE_DAY, p_LOG_ONLY, p_ERROR_MESSAGE, p_LOGGER);
            RETURN;
        END IF;

        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT("QueryScheduleOffer", XMLATTRIBUTES(TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT) AS "day", p_MARKET_NAME AS "market"), XMLFOREST(p_LOCATION_NAME AS "LocationName", p_PORTFOLIO_NAME AS "PortfolioName"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinSchedule';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        IF NOT v_XML_RESPONSE IS NULL THEN
            PUT_SCHEDULE_OFFER(p_PARTY_NAME, v_XML_RESPONSE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_SCHEDULE_OFFER;

-------------------------------------------------------------------------------------
    PROCEDURE PRICE_QUANTITY_XML_FRAGMENT(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_XML_FRAGMENT OUT XMLTYPE
    ) AS
        v_BEGIN_DATE DATE;
        v_END_DATE DATE;
    BEGIN
        UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_SCHEDULE_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

        SELECT   XMLELEMENT(
                     "Block",
                     XMLATTRIBUTES(F.EXTERNAL_IDENTIFIER AS "location"),
                     XMLAGG((SELECT XMLELEMENT("BlockHourly", XMLATTRIBUTES(REPLACE(TO_CHAR(D.SCHEDULE_DATE, 'HH24'), '00', '24') AS "hour"), XMLAGG(XMLELEMENT("BlockSegment", XMLATTRIBUTES(ROUND(QUANTITY, 1) AS "MW", ROUND(PRICE, 2) AS "price"))))
                             FROM   BID_OFFER_SET C
                             WHERE  C.TRANSACTION_ID = D.TRANSACTION_ID AND C.SCHEDULE_STATE = D.SCHEDULE_STATE AND C.SCHEDULE_DATE = D.SCHEDULE_DATE AND ROUND(C.QUANTITY, 1) > 0))
                 )
        INTO     p_XML_FRAGMENT
        FROM     BID_OFFER_SET D, INTERCHANGE_TRANSACTION E, SERVICE_POINT F, BID_OFFER_STATUS G
        WHERE    E.TRANSACTION_ID = p_TRANSACTION_ID
        AND      F.SERVICE_POINT_ID = E.POD_ID
        AND      D.TRANSACTION_ID = p_TRANSACTION_ID
        AND      D.SCHEDULE_STATE = p_SCHEDULE_STATE
        AND      D.SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE
        AND      D.SET_NUMBER = 1
        AND      G.TRANSACTION_ID = D.TRANSACTION_ID
        AND      G.SCHEDULE_DATE = D.SCHEDULE_DATE
        AND      G.REVIEW_STATUS = g_RVW_STATUS_ACCEPTED
        --AND ROUND(D.QUANTITY, 1) > 0
        --  MISO REQUIRES ALL 24 HOURS.
        --      AND INSTR(p_SUBMIT_HOURS, '''' || TO_CHAR(D.SCHEDULE_DATE,'HH24') || '''') > 0
        GROUP BY F.EXTERNAL_IDENTIFIER;
    END PRICE_QUANTITY_XML_FRAGMENT;

-------------------------------------------------------------------------------------
    PROCEDURE VIRTUAL_BID(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_SUBMIT_XML_FRAGMENT XMLTYPE;
    BEGIN
        PRICE_QUANTITY_XML_FRAGMENT(p_TRANSACTION_ID, p_SCHEDULE_STATE, p_SCHEDULE_DATE, p_TIME_ZONE, v_SUBMIT_XML_FRAGMENT);

        SELECT XMLELEMENT("VirtualBid", XMLATTRIBUTES(TO_CHAR(TRUNC(p_SCHEDULE_DATE), g_DATE_FORMAT) AS "day"), v_SUBMIT_XML_FRAGMENT)
        INTO   p_SUBMIT_XML
        FROM   DUAL;
    END VIRTUAL_BID;

-------------------------------------------------------------------------------------
    PROCEDURE VIRTUAL_OFFER(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_SUBMIT_XML_FRAGMENT XMLTYPE;
    BEGIN
        PRICE_QUANTITY_XML_FRAGMENT(p_TRANSACTION_ID, p_SCHEDULE_STATE, p_SCHEDULE_DATE, p_TIME_ZONE, v_SUBMIT_XML_FRAGMENT);

        SELECT XMLELEMENT("VirtualOffer", XMLATTRIBUTES(TO_CHAR(TRUNC(p_SCHEDULE_DATE), g_DATE_FORMAT) AS "day"), v_SUBMIT_XML_FRAGMENT)
        INTO   p_SUBMIT_XML
        FROM   DUAL;
    END VIRTUAL_OFFER;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_VIRTUAL_BID_OFFER(
        p_PARTY_NAME IN VARCHAR2,
        p_BIDS IN XMLTYPE,
        p_IS_OFFER IN BOOLEAN,
        p_SCHEDULE_STATE IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        v_TRANSACTION_ID NUMBER(9);
        v_SCHEDULE_STATE NUMBER(1) := p_SCHEDULE_STATE;
        v_STATUS NUMBER;
        v_SET_NUMBER NUMBER(2) := 1;
        v_MARKET_TYPE VARCHAR2(16) := g_DAYAHEAD;
        v_PREV_LOCATION VARCHAR2(64) := g_INIT_VAL_VARCHAR;
        v_PREV_SCHEDULE_DAY DATE := LOW_DATE;
        v_PREV_HOUR NUMBER(2) := -1;

        CURSOR c_BID_XML IS
            SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "SCHEDULE_DAY", EXTRACTVALUE(VALUE(U), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", EXTRACTVALUE(VALUE(V), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR",
                   EXTRACTVALUE(VALUE(W), '//@MW', g_MISO_NAMESPACE) "MW", EXTRACTVALUE(VALUE(W), '//@price', g_MISO_NAMESPACE) "PRICE"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_BIDS, '/descendant::*[self::VirtualBid or self::VirtualOffer]', g_MISO_NAMESPACE))) T,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//Block', g_MISO_NAMESPACE))) U,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//BlockHourly', g_MISO_NAMESPACE))) V,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(V), '//BlockSegment', g_MISO_NAMESPACE))) W;
    BEGIN
        IF LOGS.IS_DEBUG_ENABLED THEN
            LOGS.LOG_DEBUG('PUT_VIRTUAL_BID_OFFER');
        END IF;

        --LOOP OVER EACH OFFER.
        FOR v_BID_XML IN c_BID_XML LOOP
            IF v_PREV_LOCATION <> v_BID_XML.LOCATION_NAME OR v_PREV_SCHEDULE_DAY <> v_BID_XML.SCHEDULE_DAY THEN
                GET_BID_TRANSACTION_ID('VIR',                                                                                                                                                                                                       --BID_TYPE
                    CASE p_IS_OFFER
                        WHEN TRUE THEN 'Generation'
                        ELSE 'Load'
                    END,                                                                                                                                                                                                                    --TRANSACTION_TYPE
                    v_BID_XML.LOCATION_NAME,                                                                                                                                                                                                        --POD_NAME
                    v_BID_XML.SCHEDULE_DAY,                                                                                                                                                                                                     --SCHEDULE_DAY
                    v_MARKET_TYPE,                                                                                                                                                                                                               --MARKET_TYPE
                    'Energy',                                                                                                                                                                                                                 --COMMODITY_TYPE
                    1,                                                                                                                                                                                                                            --IS_VIRTUAL
                    0,                                                                                                                                                                                                                               --IS_FIRM
                    'Hour',                                                                                                                                                                                                             --TRANSACTION_INTERVAL
                    p_PARTY_NAME,                                                                                                                                                                                                                 --PARTY_NAME
                    v_TRANSACTION_ID, p_ERROR_MESSAGE);

                IF LOGS.IS_DEBUG_ENABLED THEN
                    LOGS.LOG_DEBUG('FOUND TRANSACTION ID=' || TO_CHAR(v_TRANSACTION_ID));
                END IF;

                v_PREV_LOCATION := v_BID_XML.LOCATION_NAME;
                v_PREV_SCHEDULE_DAY := v_BID_XML.SCHEDULE_DAY;
                v_PREV_HOUR := -1;
            END IF;

------------------------------------------------------
--    PUT BID AMOUNTS
------------------------------------------------------
            SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

            IF v_PREV_HOUR <> v_BID_XML.SCHEDULE_HOUR THEN
                v_SET_NUMBER := 1;
                v_PREV_HOUR := v_BID_XML.SCHEDULE_HOUR;
            END IF;

            BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID, 0, v_SCHEDULE_STATE, v_BID_XML.SCHEDULE_DAY + v_BID_XML.SCHEDULE_HOUR / 24, v_SET_NUMBER, v_BID_XML.PRICE, v_BID_XML.MW, 'P', MM_MISO_UTIL.g_MISO_TIMEZONE, v_STATUS);

            IF v_STATUS < 0 THEN
                p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) || ' in MISO_EXCHANGE.PUT_VIRTUAL_BID_OFFER while calling BO.PUT_BID_OFFER_SET.';
                SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                RETURN;
            END IF;

            v_SET_NUMBER := v_SET_NUMBER + 1;
        END LOOP;

        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
            RAISE;
    END PUT_VIRTUAL_BID_OFFER;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_VIRTUAL_BID(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_LOCATION_NAME IN VARCHAR2,
        p_PORTFOLIO_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_PARTY_TABLE GA.STRING_TABLE;
        v_PARTY_INDEX BINARY_INTEGER;
    BEGIN
        -- no party specified? then do query for all parties
        IF p_PARTY_NAME IS NULL THEN
            GET_PARTIES_FOR_ISO_ACCOUNT(p_CRED.EXTERNAL_ACCOUNT_NAME, v_PARTY_TABLE);
            v_PARTY_INDEX := v_PARTY_TABLE.FIRST;

            WHILE v_PARTY_TABLE.EXISTS(v_PARTY_INDEX) LOOP
                QUERY_VIRTUAL_BID(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), p_LOCATION_NAME, p_PORTFOLIO_NAME, p_SCHEDULE_DAY, p_LOG_ONLY, p_ERROR_MESSAGE, p_LOGGER);                v_PARTY_INDEX := v_PARTY_TABLE.NEXT(v_PARTY_INDEX);
                v_PARTY_INDEX := v_PARTY_TABLE.NEXT(v_PARTY_INDEX);
            END LOOP;

            RETURN;
        END IF;

        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT("QueryVirtualBids", XMLATTRIBUTES(TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT) AS "day"), XMLFOREST(p_LOCATION_NAME AS "LocationName", p_PORTFOLIO_NAME AS "PortfolioName"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinSchedule';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        IF NOT v_XML_RESPONSE IS NULL THEN
            PUT_VIRTUAL_BID_OFFER(p_PARTY_NAME, v_XML_RESPONSE, FALSE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_VIRTUAL_BID;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_VIRTUAL_OFFER(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_LOCATION_NAME IN VARCHAR2,
        p_PORTFOLIO_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_PARTY_TABLE GA.STRING_TABLE;
        v_PARTY_INDEX BINARY_INTEGER;
    BEGIN
        -- no party specified? then do query for all parties
        IF p_PARTY_NAME IS NULL THEN
            GET_PARTIES_FOR_ISO_ACCOUNT(p_CRED.EXTERNAL_ACCOUNT_NAME, v_PARTY_TABLE);
            v_PARTY_INDEX := v_PARTY_TABLE.FIRST;

            WHILE v_PARTY_TABLE.EXISTS(v_PARTY_INDEX) LOOP
                QUERY_VIRTUAL_OFFER(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), p_LOCATION_NAME, p_PORTFOLIO_NAME, p_SCHEDULE_DAY, p_LOG_ONLY, p_ERROR_MESSAGE, p_LOGGER);
                v_PARTY_INDEX := v_PARTY_TABLE.NEXT(v_PARTY_INDEX);
            END LOOP;

            RETURN;
        END IF;

        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT("QueryVirtualOffers", XMLATTRIBUTES(TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT) AS "day"), XMLFOREST(p_LOCATION_NAME AS "LocationName", p_PORTFOLIO_NAME AS "PortfolioName"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinSchedule';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        IF NOT v_XML_RESPONSE IS NULL THEN
            PUT_VIRTUAL_BID_OFFER(p_PARTY_NAME, v_XML_RESPONSE, TRUE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_VIRTUAL_OFFER;

-------------------------------------------------------------------------------------
    PROCEDURE PRICE_SENSITIVE_DEMAND_BID(
        p_TRANSACTION_ID IN NUMBER,
        p_SCHEDULE_STATE IN NUMBER,
        p_SCHEDULE_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_SUBMIT_XML_FRAGMENT XMLTYPE;
    BEGIN
        PRICE_QUANTITY_XML_FRAGMENT(p_TRANSACTION_ID, p_SCHEDULE_STATE, p_SCHEDULE_DATE, p_TIME_ZONE, v_SUBMIT_XML_FRAGMENT);

        SELECT XMLELEMENT("PriceSensitiveDemandBid", XMLATTRIBUTES(TO_CHAR(TRUNC(p_SCHEDULE_DATE), g_DATE_FORMAT) AS "day"), v_SUBMIT_XML_FRAGMENT)
        INTO   p_SUBMIT_XML
        FROM   DUAL;
    END PRICE_SENSITIVE_DEMAND_BID;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_PRICE_SENS_DEMAND_BID(
        p_PARTY_NAME IN VARCHAR2,
        p_BIDS IN XMLTYPE,
        p_SCHEDULE_STATE IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        v_TRANSACTION_ID NUMBER(9);
        v_SCHEDULE_STATE NUMBER(1) := p_SCHEDULE_STATE;
        v_STATUS NUMBER;
        v_SET_NUMBER NUMBER(2) := 1;
        v_MARKET_TYPE VARCHAR2(16) := g_DAYAHEAD;
        v_PREV_LOCATION VARCHAR2(64) := g_INIT_VAL_VARCHAR;
        v_PREV_SCHEDULE_DAY DATE := LOW_DATE;
        v_PREV_HOUR NUMBER(2) := -1;

        CURSOR c_BID_XML IS
            SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '/PriceSensitiveDemandBid/@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "SCHEDULE_DAY", EXTRACTVALUE(VALUE(U), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME",
                   EXTRACTVALUE(VALUE(V), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR", EXTRACTVALUE(VALUE(W), '//@MW', g_MISO_NAMESPACE) "MW", EXTRACTVALUE(VALUE(W), '//@price', g_MISO_NAMESPACE) "PRICE"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_BIDS, '//PriceSensitiveDemandBid', g_MISO_NAMESPACE))) T,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//Block', g_MISO_NAMESPACE))) U,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//BlockHourly', g_MISO_NAMESPACE))) V,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(V), '//BlockSegment', g_MISO_NAMESPACE))) W;
    BEGIN
        IF LOGS.IS_DEBUG_ENABLED THEN
            LOGS.LOG_DEBUG('PUT_PRICE_SENS_DEMAND_BID');
        END IF;

        --LOOP OVER EACH OFFER.
        FOR v_BID_XML IN c_BID_XML LOOP
            IF v_PREV_LOCATION <> v_BID_XML.LOCATION_NAME OR v_PREV_SCHEDULE_DAY <> v_BID_XML.SCHEDULE_DAY THEN
                GET_BID_TRANSACTION_ID('PRICESENS',                                                                                                                                                                                                 --BID_TYPE
                    'Load',                                                                                                                                                                                                                 --TRANSACTION_TYPE
                    v_BID_XML.LOCATION_NAME,                                                                                                                                                                                                        --POD_NAME
                    v_BID_XML.SCHEDULE_DAY,                                                                                                                                                                                                     --SCHEDULE_DAY
                    v_MARKET_TYPE,                                                                                                                                                                                                               --MARKET_TYPE
                    'Energy',                                                                                                                                                                                                                 --COMMODITY_TYPE
                    0,                                                                                                                                                                                                                            --IS_VIRTUAL
                    0,                                                                                                                                                                                                                               --IS_FIRM
                    'Hour',                                                                                                                                                                                                             --TRANSACTION_INTERVAL
                    p_PARTY_NAME,                                                                                                                                                                                                                 --PARTY_NAME
                    v_TRANSACTION_ID, p_ERROR_MESSAGE);

                IF LOGS.IS_DEBUG_ENABLED THEN
                    LOGS.LOG_DEBUG('FOUND TRANSACTION ID=' || TO_CHAR(v_TRANSACTION_ID));
                END IF;

                v_PREV_LOCATION := v_BID_XML.LOCATION_NAME;
                v_PREV_SCHEDULE_DAY := v_BID_XML.SCHEDULE_DAY;
                v_PREV_HOUR := -1;
            END IF;

------------------------------------------------------
--    PUT BID AMOUNTS
------------------------------------------------------
            SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

            IF v_PREV_HOUR <> v_BID_XML.SCHEDULE_HOUR THEN
                v_SET_NUMBER := 1;
                v_PREV_HOUR := v_BID_XML.SCHEDULE_HOUR;
            END IF;

            BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID, 0, v_SCHEDULE_STATE, v_BID_XML.SCHEDULE_DAY + v_BID_XML.SCHEDULE_HOUR / 24, v_SET_NUMBER, v_BID_XML.PRICE, v_BID_XML.MW, 'P', MM_MISO_UTIL.g_MISO_TIMEZONE, v_STATUS);

            IF v_STATUS < 0 THEN
                p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) || ' in MISO_EXCHANGE.PUT_FIXED_DEMAND_BID while calling BO.PUT_BID_OFFER_SET.';
                SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                RETURN;
            END IF;

            v_SET_NUMBER := v_SET_NUMBER + 1;
        END LOOP;

        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
            RAISE;
    END PUT_PRICE_SENS_DEMAND_BID;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_PRICE_SENS_DEMAND_BID(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_LOCATION_NAME IN VARCHAR2,
        p_PORTFOLIO_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_PARTY_TABLE GA.STRING_TABLE;
        v_PARTY_INDEX BINARY_INTEGER;
    BEGIN
        -- no party specified? then do query for all parties
        IF p_PARTY_NAME IS NULL THEN
            GET_PARTIES_FOR_ISO_ACCOUNT(p_CRED.EXTERNAL_ACCOUNT_NAME, v_PARTY_TABLE);
            v_PARTY_INDEX := v_PARTY_TABLE.FIRST;

            WHILE v_PARTY_TABLE.EXISTS(v_PARTY_INDEX) LOOP
                QUERY_PRICE_SENS_DEMAND_BID(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), p_LOCATION_NAME, p_PORTFOLIO_NAME, p_SCHEDULE_DAY, p_LOG_ONLY, p_ERROR_MESSAGE, p_LOGGER);
                v_PARTY_INDEX := v_PARTY_TABLE.NEXT(v_PARTY_INDEX);
            END LOOP;

            RETURN;
        END IF;

        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT("QueryPriceSensitiveDemandBids", XMLATTRIBUTES(TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT) AS "day"), XMLFOREST(p_LOCATION_NAME AS "LocationName", p_PORTFOLIO_NAME AS "PortfolioName"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinSchedule';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        IF NOT v_XML_RESPONSE IS NULL THEN
            PUT_PRICE_SENS_DEMAND_BID(p_PARTY_NAME, v_XML_RESPONSE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_PRICE_SENS_DEMAND_BID;
-------------------------------------------------------------------------------------
    PROCEDURE UPDATE_BID_OFFER_STATUS(
        p_TRANSACTION_ID IN NUMBER,
        p_BEGIN_DATE IN DATE,
        p_END_DATE IN DATE,
        p_TIME_ZONE IN VARCHAR2,
        p_SUBMIT_STATUS IN VARCHAR2,
        p_MARKET_STATUS IN VARCHAR2
    ) AS
        v_BEGIN_DATE DATE;
        v_END_DATE DATE;
    BEGIN
        UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

        UPDATE BID_OFFER_STATUS
        SET SUBMIT_STATUS = p_SUBMIT_STATUS,
            SUBMIT_DATE = SYSDATE,
            SUBMITTED_BY = SECURITY_CONTROLS.CURRENT_USER,
            MARKET_STATUS = p_MARKET_STATUS,
            MARKET_STATUS_DATE = SYSDATE
        WHERE  TRANSACTION_ID = p_TRANSACTION_ID AND SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;
    END UPDATE_BID_OFFER_STATUS;

-------------------------------------------------------------------------------------
    PROCEDURE MARKET_SUBMIT_TRANSACTION_LIST(
        p_ACTION         IN VARCHAR2,
        p_CURSOR IN OUT REF_CURSOR
    ) AS
      v_ACTION VARCHAR2(64) := LTRIM(RTRIM(REPLACE(p_ACTION, 'TEST', '')));
      v_SC_ID  NUMBER(9) := MM_MISO_UTIL.GET_MISO_SC_ID;
    BEGIN
      --Selects the particular transactions that should show up for each Action Type
      --in the Bid/Offer Action Dialog.

      IF v_ACTION = 'FinSchedule' THEN
        OPEN p_CURSOR FOR
          SELECT A.TRANSACTION_NAME, A.TRANSACTION_ID
            FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
           WHERE A.IS_BID_OFFER = 1
             AND A.TRANSACTION_TYPE IN ('Purchase', 'Sale')
             AND A.COMMODITY_ID = B.COMMODITY_ID
             AND A.IS_IMPORT_EXPORT = 0
             AND A.SC_ID = v_SC_ID
             AND B.COMMODITY_TYPE = 'Energy'
           ORDER BY B.COMMODITY_NAME, A.TRANSACTION_NAME;
      ELSIF v_ACTION IN ('VirtualBid', 'VirtualOffer') THEN
        OPEN p_CURSOR FOR
          SELECT TRANSACTION_NAME, A.TRANSACTION_ID
            FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
           WHERE IS_BID_OFFER = 1
             AND B.IS_VIRTUAL = 1
             AND A.COMMODITY_ID = B.COMMODITY_ID
             AND A.SC_ID = v_SC_ID
           ORDER BY B.COMMODITY_NAME, A.TRANSACTION_NAME;
      ELSIF v_ACTION IN ('ScheduleOffer', 'UpdateScheduleOffer') THEN
        OPEN p_CURSOR FOR
          SELECT TRANSACTION_NAME, A.TRANSACTION_ID
            FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
           WHERE IS_BID_OFFER = 1
             AND A.TRANSACTION_TYPE = 'Generation'
             AND B.IS_VIRTUAL = 0
             AND A.COMMODITY_ID = B.COMMODITY_ID
             AND A.SC_ID = v_SC_ID
           ORDER BY B.COMMODITY_NAME, A.TRANSACTION_NAME;
      ELSIF v_ACTION = 'PriceSensitiveDemandBid' THEN
        OPEN p_CURSOR FOR
          SELECT TRANSACTION_NAME, A.TRANSACTION_ID
            FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
           WHERE IS_BID_OFFER = 1
             AND A.IS_FIRM = 0
             AND A.TRANSACTION_TYPE = 'Load'
             AND B.IS_VIRTUAL = 0
             AND A.COMMODITY_ID = B.COMMODITY_ID
             AND A.SC_ID = v_SC_ID
           ORDER BY B.COMMODITY_NAME, A.TRANSACTION_NAME;
      ELSIF v_ACTION = 'FixedDemandBid' THEN
        OPEN p_CURSOR FOR
          SELECT TRANSACTION_NAME, A.TRANSACTION_ID
            FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
           WHERE IS_BID_OFFER = 1
             AND A.IS_FIRM = 1
             AND A.TRANSACTION_TYPE = 'Load'
             AND B.IS_VIRTUAL = 0
             AND A.COMMODITY_ID = B.COMMODITY_ID
             AND A.SC_ID = v_SC_ID
           ORDER BY B.COMMODITY_NAME, A.TRANSACTION_NAME;
      END IF;
    END MARKET_SUBMIT_TRANSACTION_LIST;
----------------------------------------------------------------------------------------------------
    PROCEDURE SYSTEM_ACTION_USES_HOURS
    	(
        p_ACTION IN VARCHAR2,
    	p_SHOW_HOURS OUT NUMBER
    ) AS
    BEGIN
      --Selects the particular transactions that should show up for each Action Type
      --in the Bid/Offer Action Dialog.
      IF UPPER(p_ACTION) = 'UPDATESCHEDULEOFFER' THEN
		p_SHOW_HOURS     := 1;
      ELSE
		p_SHOW_HOURS     := 0;
      END IF;

	END SYSTEM_ACTION_USES_HOURS;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_SUBMIT_WARNING(
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR,
	p_MUST_CANCEL_SUBMIT OUT NUMBER) AS
    BEGIN
        IF p_TIME_ZONE != 'EST' THEN
          p_STATUS := -1;
          p_MESSAGE := 'INCORRECT TIME ZONE.' ||
                       'Set your time zone to EST, verify that bid status is correct, and resubmit.';
          p_MUST_CANCEL_SUBMIT := 1;
        END IF;
    END MARKET_SUBMIT_WARNING;

----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_SUBMIT
	(
	   p_BEGIN_DATE      IN DATE,
       p_END_DATE        IN DATE,
       p_EXCHANGE_TYPE   IN VARCHAR2,
       p_LOG_ONLY	    IN NUMBER,
       p_ENTITY_LIST 	 IN VARCHAR2,
       p_ENTITY_LIST_DELIMITER IN CHAR,
       p_SUBMIT_HOURS    IN VARCHAR2,
       p_TIME_ZONE       IN VARCHAR2,
	   p_LOG_TYPE		 IN NUMBER,
	   p_TRACE_ON		 IN NUMBER,
       p_STATUS          OUT NUMBER,
       p_MESSAGE         OUT VARCHAR2) AS

        v_TRANSACTION_IDS VARCHAR2(2000);
        v_TXN_ID_TABLE GA.ID_TABLE;
        v_INDEX BINARY_INTEGER;
        v_TRANSACTION_ID NUMBER(9);
        v_POD_ID INTERCHANGE_TRANSACTION.POD_ID%TYPE;
        v_TIME_ZONE VARCHAR2(3) := p_TIME_ZONE;
        v_CURRENT_DATE DATE := TRUNC(p_BEGIN_DATE);
        v_SUBMIT_XML XMLTYPE;
        v_CURRENT_XML XMLTYPE;
        v_LOOP_COUNTER BINARY_INTEGER := 1;
        v_ACTION VARCHAR2(64);
        v_DATA_EX_ACTION VARCHAR2(64);
        v_IS_TEST_MODE NUMBER(1) := NVL(p_LOG_ONLY,0);
        v_PARTY_NAME VARCHAR2(16);
        --v_ISO_ACCOUNT VARCHAR2(64);
        v_SUBMIT_STATUS VARCHAR2(32);
        v_MARKET_STATUS VARCHAR2(32);

        v_CRED MEX_CREDENTIALS;
		v_LOGGER MM_LOGGER_ADAPTER;
    BEGIN
        v_TRANSACTION_IDS := REPLACE(p_ENTITY_LIST, '''', '');
        UT.IDS_FROM_STRING(v_TRANSACTION_IDS, p_ENTITY_LIST_DELIMITER, v_TXN_ID_TABLE);

		v_ACTION := p_EXCHANGE_TYPE;

		MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_MISO,
				p_EXTERNAL_ACCOUNT_NAME => NULL,
				p_PROCESS_NAME => 'MISO:MARKET SUBMIT',
				p_EXCHANGE_NAME => v_ACTION,
				p_LOG_TYPE => p_LOG_TYPE,
				p_TRACE_ON => p_TRACE_ON,
				p_CREDENTIALS => v_CRED,
				p_LOGGER => v_LOGGER);
		MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

        IF LOGS.IS_DEBUG_ENABLED THEN
            LOGS.LOG_DEBUG('ABOUT TO EXECUTE BID OFFER ACTION:' || v_ACTION);
        END IF;

        --LOOP OVER TRANSACTIONS
        v_INDEX := v_TXN_ID_TABLE.FIRST;
        LOOP
            v_SUBMIT_XML := NULL;
            v_TRANSACTION_ID := TO_NUMBER(v_TXN_ID_TABLE(v_INDEX));

			--Re-initialize credential for Transaction
			MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_MISO,
				p_EXTERNAL_ACCOUNT_NAME => MM_Util.GET_EXT_ACCOUNT_FOR_TXN(v_TRANSACTION_ID, EC.ES_MISO),
				p_PROCESS_NAME => 'MISO:MARKET SUBMIT',
				p_EXCHANGE_NAME => v_ACTION,
				p_LOG_TYPE => p_LOG_TYPE,
				p_TRACE_ON => p_TRACE_ON,
				p_CREDENTIALS => v_CRED,
				p_LOGGER => v_LOGGER);

            SELECT POD_ID INTO v_POD_ID FROM INTERCHANGE_TRANSACTION
			WHERE TRANSACTION_ID = v_TRANSACTION_ID;


            IF v_CRED IS NOT NULL THEN
                v_PARTY_NAME := GET_PARTY_FOR_TRANSACTION(v_TRANSACTION_ID);

                -- big oops that this wasn't here: for multiple transactions, we'd only submit the last day
                -- of any transaction that wasn't the first one. Fixes bug 9210.
                v_CURRENT_DATE := p_BEGIN_DATE;

                --LOOP OVER DATE RANGE
                LOOP
                    IF v_ACTION = g_ET_SUBMIT_FIN_SCHEDULE THEN
                        FIN_SCHEDULE(v_TRANSACTION_ID, 1, v_CURRENT_DATE, v_TIME_ZONE, v_CURRENT_XML);
                		v_DATA_EX_ACTION := 'QUERYFINSCHEDULES';
                    ELSIF v_ACTION = 'VIRTUALBID' THEN
                        VIRTUAL_BID(v_TRANSACTION_ID, 1, v_CURRENT_DATE, v_TIME_ZONE, v_CURRENT_XML);
                        v_DATA_EX_ACTION := 'QUERYVIRTUALBIDSBYLOCATION';
                    ELSIF v_ACTION = 'VIRTUALOFFER' THEN
                        VIRTUAL_OFFER(v_TRANSACTION_ID, 1, v_CURRENT_DATE, v_TIME_ZONE, v_CURRENT_XML);
                        v_DATA_EX_ACTION := 'QUERYVIRTUALOFFERSBYLOCATION';
                    ELSIF v_ACTION = 'PRICESENSITIVEDEMANDBID' THEN
                        PRICE_SENSITIVE_DEMAND_BID(v_TRANSACTION_ID, 1, v_CURRENT_DATE, v_TIME_ZONE, v_CURRENT_XML);
                        v_DATA_EX_ACTION := 'QUERYPRICESENSITIVEDEMANDBIDSBYLOCATION';
                    ELSIF v_ACTION = 'FIXEDDEMANDBID' THEN
                        FIXED_DEMAND_BID(v_TRANSACTION_ID, 1, v_CURRENT_DATE, v_TIME_ZONE, v_CURRENT_XML);
                        v_DATA_EX_ACTION := 'QUERYFIXEDDEMANDBIDSBYLOCATION';
                    ELSIF v_ACTION = 'SCHEDULEOFFER' THEN
                        SCHEDULE_OFFER(v_TRANSACTION_ID, 1, v_CURRENT_DATE, v_TIME_ZONE, v_CURRENT_XML);
                        v_DATA_EX_ACTION := 'QUERYSCHEDULEOFFERSBYLOCATION';
                    ELSIF v_ACTION = 'UPDATESCHEDULEOFFER' THEN
                        UPDATE_SCHEDULE_OFFER(v_TRANSACTION_ID, 1, v_CURRENT_DATE, p_SUBMIT_HOURS, v_CURRENT_XML);
                        v_DATA_EX_ACTION := 'QUERYUPDATEBYLOCATION';
                    ELSE
                        v_LOGGER.LOG_ERROR('Exchange Type ' || p_EXCHANGE_TYPE || ' not found.');
                        RETURN;
                    END IF;

                    SELECT XMLCONCAT(v_SUBMIT_XML, v_CURRENT_XML)
                    INTO   v_SUBMIT_XML
                    FROM   DUAL;

                    --ONLY GO THROUGH THIS CODE ONCE FOR DATE-INDEPENDENT EXCHANGES.
                    EXIT WHEN v_CURRENT_DATE >= TRUNC(p_END_DATE);
                    v_CURRENT_DATE := v_CURRENT_DATE + 1;

                    --MAKE SURE WE DON'T HAVE A RUNAWAY LOOP.
                    v_LOOP_COUNTER := v_LOOP_COUNTER + 1;

                    IF v_LOOP_COUNTER > 10000 THEN
                        RAISE_APPLICATION_ERROR(-20100, 'RUNAWAY LOOP IN MM_MISO.MARKET_SUBMIT');
                    END IF;
                END LOOP;       -- OVER DATE RANGE

                --UPDATE SUBMIT STATUS TO PENDING.
                IF v_IS_TEST_MODE = 0 THEN
                    UPDATE_BID_OFFER_STATUS(v_TRANSACTION_ID, p_BEGIN_DATE, p_END_DATE, v_TIME_ZONE, g_SUBMIT_STATUS_PENDING, g_MKT_STATUS_PENDING);
                END IF;

                --SUBMIT WHAT IS LEFT.
                IF NOT v_SUBMIT_XML IS NULL THEN
                    --SUBMIT_BIDS_FOR_PARTY;
                    RUN_MISO_SUBMIT(v_CRED, v_IS_TEST_MODE, v_SUBMIT_XML, v_PARTY_NAME, v_SUBMIT_STATUS, v_MARKET_STATUS, p_MESSAGE, v_logger);
                    UPDATE_BID_OFFER_STATUS(v_TRANSACTION_ID,  p_BEGIN_DATE, p_END_DATE, v_TIME_ZONE, v_SUBMIT_STATUS, v_MARKET_STATUS);
                	-- run the query immediately after the action
                	IF NVL(GET_DICTIONARY_VALUE('QueryAfterSubmit', 0, 'MarketExchange'), 0) = 1 THEN
    					MARKET_EXCHANGE(p_BEGIN_DATE,
										p_END_DATE,
    									v_DATA_EX_ACTION,
										v_POD_ID,
										';',
										p_LOG_TYPE,
										p_TRACE_ON,
										p_LOG_ONLY,
										p_STATUS,
										p_MESSAGE);
					END IF;
                END IF;

            END IF;   --v_EXT_CRED IS NOT NULL;

            EXIT WHEN v_INDEX = v_TXN_ID_TABLE.LAST;
            v_INDEX := v_TXN_ID_TABLE.NEXT(v_INDEX);
        END LOOP; -- OVER TRANSACTIONS;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
    EXCEPTION
        WHEN OTHERS THEN
            p_MESSAGE := SQLERRM;
            p_STATUS := SQLCODE;
			MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

	END MARKET_SUBMIT;

-------------------------------------------------------------------------------------
    PROCEDURE GET_TEMP_LIMIT_VALS(
        p_TEMP_LIMIT IN VARCHAR2,
        p_MW OUT NUMBER,
        p_TEMPERATURE OUT NUMBER
    ) AS
        v_SEPARATOR NUMBER(2);
    BEGIN
        --TEMP LIMIT VALS ARE STORED AS <MW>;<TEMPERATURE>
        v_SEPARATOR := INSTR(p_TEMP_LIMIT, ';');

        IF v_SEPARATOR > 0 THEN
            p_MW := TO_NUMBER(SUBSTR(p_TEMP_LIMIT, 1, v_SEPARATOR - 1));
            p_TEMPERATURE := TO_NUMBER(SUBSTR(p_TEMP_LIMIT, v_SEPARATOR + 1));
        END IF;
    END GET_TEMP_LIMIT_VALS;

-------------------------------------------------------------------------------------
    PROCEDURE DEFAULT_LIMITS(
        p_TRANSACTION_ID IN NUMBER,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_INTERVAL_DATE DATE := g_DAILY_TEMPLATE_VAL_DATE;
        v_DISPATCH_LIMIT_MIN BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_DISPATCH_LIMIT_MAX BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMERGENCY_LIMIT_MIN BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMERGENCY_LIMIT_MAX BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_TEMP_LIMIT_1 BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_TEMP_LIMIT_MW_1 NUMBER(8);
        v_TEMP_LIMIT_TEMP_1 NUMBER(5, 1);
        v_TEMP_LIMIT_2 BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_TEMP_LIMIT_MW_2 NUMBER(8);
        v_TEMP_LIMIT_TEMP_2 NUMBER(5, 1);
        v_TEMP_LIMIT_3 BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_TEMP_LIMIT_MW_3 NUMBER(8);
        v_TEMP_LIMIT_TEMP_3 NUMBER(5, 1);
        v_EMER_TEMP_LIMIT_1 BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMER_TEMP_LIMIT_MW_1 NUMBER(8);
        v_EMER_TEMP_LIMIT_TEMP_1 NUMBER(5, 1);
        v_EMER_TEMP_LIMIT_2 BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMER_TEMP_LIMIT_MW_2 NUMBER(8);
        v_EMER_TEMP_LIMIT_TEMP_2 NUMBER(5, 1);
        v_EMER_TEMP_LIMIT_3 BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_EMER_TEMP_LIMIT_MW_3 NUMBER(8);
        v_EMER_TEMP_LIMIT_TEMP_3 NUMBER(5, 1);
        v_NO_DISPATCH_TEMP NUMBER(1) := 0;
        v_NO_EMER_TEMP NUMBER(1) := 0;
		v_RESOURCE_ID NUMBER(9);
    BEGIN
        v_DISPATCH_LIMIT_MIN := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Dispatch Minimum', p_TRANSACTION_ID, v_INTERVAL_DATE);
        v_DISPATCH_LIMIT_MAX := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Dispatch Maximum', p_TRANSACTION_ID, v_INTERVAL_DATE);
        v_EMERGENCY_LIMIT_MIN := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Emergency Minimum', p_TRANSACTION_ID, v_INTERVAL_DATE);
        v_EMERGENCY_LIMIT_MAX := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Emergency Maximum', p_TRANSACTION_ID, v_INTERVAL_DATE);
        v_TEMP_LIMIT_1 := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Dispatch Temp Limit1', p_TRANSACTION_ID, v_INTERVAL_DATE);
        GET_TEMP_LIMIT_VALS(v_TEMP_LIMIT_1, v_TEMP_LIMIT_MW_1, v_TEMP_LIMIT_TEMP_1);
        v_TEMP_LIMIT_2 := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Dispatch Temp Limit2', p_TRANSACTION_ID, v_INTERVAL_DATE);
        GET_TEMP_LIMIT_VALS(v_TEMP_LIMIT_2, v_TEMP_LIMIT_MW_2, v_TEMP_LIMIT_TEMP_2);
        v_TEMP_LIMIT_3 := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Dispatch Temp Limit3', p_TRANSACTION_ID, v_INTERVAL_DATE);
        GET_TEMP_LIMIT_VALS(v_TEMP_LIMIT_3, v_TEMP_LIMIT_MW_3, v_TEMP_LIMIT_TEMP_3);
        v_EMER_TEMP_LIMIT_1 := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Emergency Temp Limit1', p_TRANSACTION_ID, v_INTERVAL_DATE);
        GET_TEMP_LIMIT_VALS(v_EMER_TEMP_LIMIT_1, v_EMER_TEMP_LIMIT_MW_1, v_EMER_TEMP_LIMIT_TEMP_1);
        v_EMER_TEMP_LIMIT_2 := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Emergency Temp Limit2', p_TRANSACTION_ID, v_INTERVAL_DATE);
        GET_TEMP_LIMIT_VALS(v_EMER_TEMP_LIMIT_2, v_EMER_TEMP_LIMIT_MW_2, v_EMER_TEMP_LIMIT_TEMP_2);
        v_EMER_TEMP_LIMIT_3 := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Emergency Temp Limit3', p_TRANSACTION_ID, v_INTERVAL_DATE);
        GET_TEMP_LIMIT_VALS(v_EMER_TEMP_LIMIT_3, v_EMER_TEMP_LIMIT_MW_3, v_EMER_TEMP_LIMIT_TEMP_3);

        IF v_TEMP_LIMIT_TEMP_3 IS NULL OR v_TEMP_LIMIT_MW_3 IS NULL OR v_TEMP_LIMIT_TEMP_2 IS NULL OR v_TEMP_LIMIT_MW_2 IS NULL OR v_TEMP_LIMIT_TEMP_1 IS NULL OR v_TEMP_LIMIT_MW_1 IS NULL THEN
            v_NO_DISPATCH_TEMP := 1;
        END IF;

        IF v_EMER_TEMP_LIMIT_TEMP_3 IS NULL OR v_EMER_TEMP_LIMIT_MW_3 IS NULL OR v_EMER_TEMP_LIMIT_TEMP_2 IS NULL OR v_EMER_TEMP_LIMIT_MW_2 IS NULL OR v_EMER_TEMP_LIMIT_TEMP_1 IS NULL OR v_EMER_TEMP_LIMIT_MW_1 IS NULL THEN
            v_NO_EMER_TEMP := 1;
        END IF;

		SELECT RESOURCE_ID INTO v_RESOURCE_ID FROM INTERCHANGE_TRANSACTION WHERE TRANSACTION_ID = p_TRANSACTION_ID;

        SELECT XMLELEMENT(
                   "DefaultLimits",
                   XMLATTRIBUTES(B.EXTERNAL_IDENTIFIER AS "location"),
                   EXTRACT(XMLELEMENT("DispatchLimits", XMLATTRIBUTES(v_DISPATCH_LIMIT_MIN AS "minMW", v_DISPATCH_LIMIT_MAX AS "maxMW")), 'DispatchLimits[@minMW and @maxMW]'),
                   EXTRACT(XMLELEMENT("EmergencyLimits", XMLATTRIBUTES(v_EMERGENCY_LIMIT_MIN AS "minMW", v_EMERGENCY_LIMIT_MAX AS "maxMW")), 'EmergencyLimits[@minMW and @maxMW]'),
                   EXTRACT(
                       XMLELEMENT(
                           "TemperatureBasedLimits",
                           CASE v_NO_DISPATCH_TEMP
                               WHEN 1 THEN NULL
                               ELSE XMLELEMENT(
                                       "DispatchTempLimits",
                                       XMLELEMENT("LimitPoint", XMLATTRIBUTES(v_TEMP_LIMIT_MW_1 AS "MW", v_TEMP_LIMIT_TEMP_1 AS "temperature")),
                                       XMLELEMENT("LimitPoint", XMLATTRIBUTES(v_TEMP_LIMIT_MW_2 AS "MW", v_TEMP_LIMIT_TEMP_2 AS "temperature")),
                                       XMLELEMENT("LimitPoint", XMLATTRIBUTES(v_TEMP_LIMIT_MW_3 AS "MW", v_TEMP_LIMIT_TEMP_3 AS "temperature"))
                                   )
                           END,
                           CASE v_NO_EMER_TEMP
                               WHEN 1 THEN NULL
                               ELSE XMLELEMENT(
                                       "EmergencyTempLimits",
                                       XMLELEMENT("LimitPoint", XMLATTRIBUTES(v_EMER_TEMP_LIMIT_MW_1 AS "MW", v_EMER_TEMP_LIMIT_TEMP_1 AS "temperature")),
                                       XMLELEMENT("LimitPoint", XMLATTRIBUTES(v_EMER_TEMP_LIMIT_MW_2 AS "MW", v_EMER_TEMP_LIMIT_TEMP_2 AS "temperature")),
                                       XMLELEMENT("LimitPoint", XMLATTRIBUTES(v_EMER_TEMP_LIMIT_MW_3 AS "MW", v_EMER_TEMP_LIMIT_TEMP_3 AS "temperature"))
                                   )
                           END
                       ),
                       '/child::node()[child::*]'
                   )
               )
        INTO   p_SUBMIT_XML
        FROM   SUPPLY_RESOURCE A, SERVICE_POINT B
        WHERE  A.RESOURCE_ID = v_RESOURCE_ID AND B.SERVICE_POINT_ID = A.SERVICE_POINT_ID;
    END DEFAULT_LIMITS;

-------------------------------------------------------------------------------------
    PROCEDURE DEFAULT_STARTUP_COSTS(
        p_TRANSACTION_ID IN NUMBER,
		p_CURRENT_DATE IN DATE,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_NOLOAD_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_COLD_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_INTERMEDIATE_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
        v_HOT_COST BID_OFFER_TRAIT.TRAIT_VAL%TYPE;
    BEGIN
        v_NOLOAD_COST := GET_BID_OFFER_TEMPLATE_VAL('MISO Default No Load Cost', p_TRANSACTION_ID, p_CURRENT_DATE);
        v_COLD_COST := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Cold Startup Cost', p_TRANSACTION_ID, p_CURRENT_DATE);
        v_INTERMEDIATE_COST := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Intermediate Startup Cost', p_TRANSACTION_ID, p_CURRENT_DATE);
        v_HOT_COST := GET_BID_OFFER_TEMPLATE_VAL('MISO Default Hot Startup Cost', p_TRANSACTION_ID, p_CURRENT_DATE);

        SELECT XMLELEMENT("DefaultStartupCosts", XMLATTRIBUTES(B.EXTERNAL_IDENTIFIER AS "location"),
                   XMLFOREST(v_NOLOAD_COST AS "NoLoadCost", v_COLD_COST AS "ColdStartupCost", v_INTERMEDIATE_COST AS "IntermediateStartupCost", v_HOT_COST AS "HotStartupCost"))
        INTO   p_SUBMIT_XML
        FROM   INTERCHANGE_TRANSACTION A, SERVICE_POINT B
        WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID AND B.SERVICE_POINT_ID = A.POD_ID;
    END DEFAULT_STARTUP_COSTS;

-------------------------------------------------------------------------------------
    PROCEDURE DEFAULT_STATUS(
        p_TRANSACTION_ID IN NUMBER,
		p_CURRENT_DATE IN DATE,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
    BEGIN
        SELECT XMLELEMENT("DefaultStatus", XMLATTRIBUTES(B.EXTERNAL_IDENTIFIER AS "location"), XMLELEMENT("ResourceStatus", D.TRAIT_VAL))
        INTO   p_SUBMIT_XML
        FROM   INTERCHANGE_TRANSACTION A, SERVICE_POINT B, IT_TRAIT_SCHEDULE D
        WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
			AND B.SERVICE_POINT_ID = A.POD_ID
			AND D.TRANSACTION_ID = p_TRANSACTION_ID
			AND D.SCHEDULE_STATE = GA.INTERNAL_STATE
			AND D.TRAIT_GROUP_ID = MM_MISO_UTIL.g_TG_DEF_RESOURCE_STATUS
			AND D.TRAIT_INDEX = 1
			AND D.SET_NUMBER = 1
			AND D.STATEMENT_TYPE_ID = 0
			AND p_CURRENT_DATE BETWEEN D.SCHEDULE_DATE AND D.SCHEDULE_END_DATE;
    END DEFAULT_STATUS;

-------------------------------------------------------------------------------------
    PROCEDURE RAMP_RATE(
        p_TRANSACTION_ID IN NUMBER,
		p_CURRENT_DATE IN DATE,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
    BEGIN
        SELECT   XMLELEMENT(
                     "RampRate",
                     XMLATTRIBUTES(X.EXTERNAL_IDENTIFIER AS "location"),
                     XMLELEMENT("DefaultRampRate", X.RAMP_RATE),
                     XMLELEMENT("RampRateCurve", XMLAGG(EXTRACT(XMLELEMENT("RampRatePoint", XMLATTRIBUTES(X.RAMP_CURVE_MW AS "MW", X.RAMP_CURVE_RATE AS "rate")), '/RampRatePoint[@MW and @rate]')))
                 )
        INTO     p_SUBMIT_XML
		FROM (SELECT B.EXTERNAL_IDENTIFIER,
				C.TRAIT_VAL "RAMP_RATE",
				MAX(CASE WHEN D.TRAIT_INDEX = MM_MISO_UTIL.g_TI_DEF_RAMP_CURVE_MW THEN D.TRAIT_VAL ELSE NULL END) "RAMP_CURVE_MW",
				MAX(CASE WHEN D.TRAIT_INDEX = MM_MISO_UTIL.g_TI_DEF_RAMP_CURVE_RATE THEN D.TRAIT_VAL ELSE NULL END) "RAMP_CURVE_RATE"
	        FROM INTERCHANGE_TRANSACTION A, SERVICE_POINT B, IT_TRAIT_SCHEDULE C, IT_TRAIT_SCHEDULE D
	        WHERE A.TRANSACTION_ID = p_TRANSACTION_ID
				AND B.SERVICE_POINT_ID = A.POD_ID
				AND C.TRANSACTION_ID = p_TRANSACTION_ID
				AND C.SCHEDULE_STATE = GA.INTERNAL_STATE
				AND C.TRAIT_GROUP_ID = MM_MISO_UTIL.g_TG_DEF_RAMP_RATE
				AND C.TRAIT_INDEX = 1
				AND C.SET_NUMBER = 1
				AND C.STATEMENT_TYPE_ID = 0
				AND p_CURRENT_DATE BETWEEN C.SCHEDULE_DATE AND C.SCHEDULE_END_DATE
				AND D.TRANSACTION_ID = p_TRANSACTION_ID
				AND D.SCHEDULE_STATE = GA.INTERNAL_STATE
				AND D.TRAIT_GROUP_ID = MM_MISO_UTIL.g_TG_DEF_RAMP_CURVE
				AND D.STATEMENT_TYPE_ID = 0
				AND p_CURRENT_DATE BETWEEN D.SCHEDULE_DATE AND D.SCHEDULE_END_DATE) X
        GROUP BY X.EXTERNAL_IDENTIFIER, X.RAMP_RATE;
    END RAMP_RATE;

-------------------------------------------------------------------------------------
    PROCEDURE UPDATE_PORTFOLIO(
        p_PORTFOLIO_ID IN NUMBER,
        p_PORTFOLIO_IS_NEW IN NUMBER,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
    --If the portfolio is new, just submit it.  Otherwise, remove it first
    --and then resubmit.
    BEGIN
        SELECT   XMLELEMENT(
                     "Portfolios",
                     CASE p_PORTFOLIO_IS_NEW
                         WHEN 0 THEN XMLELEMENT("Portfolio", XMLATTRIBUTES(A.PORTFOLIO_NAME AS "name", 'Remove' AS "action"))
                     END,
                     XMLELEMENT("Portfolio", XMLATTRIBUTES(A.PORTFOLIO_NAME AS "name", 'Create' AS "action"), XMLAGG(XMLELEMENT("LocationName", C.EXTERNAL_IDENTIFIER)))
                 )
        INTO     p_SUBMIT_XML
        FROM     PORTFOLIO A, PORTFOLIO_SERVICE_POINT B, SERVICE_POINT C
        WHERE    A.PORTFOLIO_ID = p_PORTFOLIO_ID AND B.PORTFOLIO_ID = A.PORTFOLIO_ID AND C.SERVICE_POINT_ID = B.SERVICE_POINT_ID
        GROUP BY A.PORTFOLIO_NAME;
    END UPDATE_PORTFOLIO;

-------------------------------------------------------------------------------------
    PROCEDURE WEATHER_FORECAST(
        p_STATION_ID IN NUMBER,
        p_FORECAST_DATE IN DATE,
        p_SUBMIT_XML OUT XMLTYPE
    ) AS
        v_DAYTIME_PARAMETER_ID NUMBER(9);
        v_NIGHTTIME_PARAMETER_ID NUMBER(9);
    BEGIN
        SELECT PARAMETER_ID
        INTO   v_DAYTIME_PARAMETER_ID
        FROM   WEATHER_PARAMETER
        WHERE  PARAMETER_NAME = 'Daytime Temperature';

        SELECT PARAMETER_ID
        INTO   v_NIGHTTIME_PARAMETER_ID
        FROM   WEATHER_PARAMETER
        WHERE  PARAMETER_NAME = 'Nighttime Temperature';

        SELECT XMLELEMENT(
                   "WeatherForecast",
                   XMLATTRIBUTES(TO_CHAR(p_FORECAST_DATE, g_DATE_FORMAT) AS "day"),
                   XMLELEMENT("WeatherPoint", XMLATTRIBUTES(A.STATION_NAME AS "name"), XMLFOREST(B.PARAMETER_VAL AS "DaytimeTemperature", C.PARAMETER_VAL AS "NighttimeTemperature"))
               )
        INTO   p_SUBMIT_XML
        FROM   WEATHER_STATION A, STATION_PARAMETER_VALUE B, STATION_PARAMETER_VALUE C
        WHERE  A.STATION_ID = p_STATION_ID
        AND    B.CASE_ID = GA.BASE_CASE_ID
        AND    B.STATION_ID = p_STATION_ID
        AND    B.PARAMETER_ID = v_DAYTIME_PARAMETER_ID
        AND    B.PARAMETER_DATE = TRUNC(p_FORECAST_DATE)
        AND    C.CASE_ID = GA.BASE_CASE_ID
        AND    C.STATION_ID = p_STATION_ID
        AND    C.PARAMETER_ID = v_NIGHTTIME_PARAMETER_ID
        AND    C.PARAMETER_DATE = TRUNC(p_FORECAST_DATE);
    END WEATHER_FORECAST;

-------------------------------------------------------------------------------------
    FUNCTION GET_LOCATION_EXT_ID(
        p_SERVICE_LOCATION_ID IN NUMBER
    )
        RETURN VARCHAR2 IS
        v_LOCATION_NAME VARCHAR2(128);
    BEGIN
        SELECT EXTERNAL_IDENTIFIER
        INTO   v_LOCATION_NAME
        FROM   SERVICE_POINT
        WHERE  SERVICE_POINT_ID = p_SERVICE_LOCATION_ID;

        RETURN v_LOCATION_NAME;
    END GET_LOCATION_EXT_ID;

-------------------------------------------------------------------------------------
    FUNCTION GET_PORTFOLIO_EXT_ID(
        p_PORTFOLIO_ID IN NUMBER
    )
        RETURN VARCHAR2 IS
        v_PORTFOLIO_NAME VARCHAR2(128);
    BEGIN
        SELECT PORTFOLIO_ALIAS
        INTO   v_PORTFOLIO_NAME
        FROM   PORTFOLIO
        WHERE  PORTFOLIO_ID = p_PORTFOLIO_ID;

        RETURN v_PORTFOLIO_NAME;
    END GET_PORTFOLIO_EXT_ID;

-------------------------------------------------------------------------------------
    FUNCTION GET_PORTFOLIO_PARTY(
        p_PORTFOLIO_ID IN NUMBER
    )
        RETURN VARCHAR2 IS
        v_PORTFOLIO_PARTY VARCHAR2(128);
    BEGIN
        SELECT PORTFOLIO_DESC
        INTO   v_PORTFOLIO_PARTY
        FROM   PORTFOLIO
        WHERE  PORTFOLIO_ID = p_PORTFOLIO_ID;

        RETURN v_PORTFOLIO_PARTY;
    END GET_PORTFOLIO_PARTY;

-------------------------------------------------------------------------------------
    FUNCTION GET_PORTFOLIO_ID(
        p_PORTFOLIO_ALIAS IN VARCHAR2,
        p_PARTY_NAME IN VARCHAR2
    )
        RETURN NUMBER IS
        v_PORTFOLIO_NAME VARCHAR2(128) := p_PARTY_NAME || ':' || p_PORTFOLIO_ALIAS;
        v_PORTFOLIO_ID NUMBER(9);
    BEGIN
        BEGIN
            SELECT PORTFOLIO_ID
            INTO   v_PORTFOLIO_ID
            FROM   PORTFOLIO
            WHERE  PORTFOLIO_NAME = v_PORTFOLIO_NAME;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                IO.PUT_PORTFOLIO(v_PORTFOLIO_ID, v_PORTFOLIO_NAME, p_PORTFOLIO_ALIAS, p_PARTY_NAME, 0);
        END;

        RETURN v_PORTFOLIO_ID;
    END GET_PORTFOLIO_ID;

-------------------------------------------------------------------------------------
    FUNCTION GET_TRANSACTION_EXT_ID(
        p_TRANSACTION_ID IN NUMBER
    )
        RETURN VARCHAR2 IS
        v_TRANSACTION_IDENTIFIER VARCHAR2(128);
    BEGIN
        SELECT TRANSACTION_IDENTIFIER
        INTO   v_TRANSACTION_IDENTIFIER
        FROM   INTERCHANGE_TRANSACTION
        WHERE  TRANSACTION_ID = p_TRANSACTION_ID;

        RETURN v_TRANSACTION_IDENTIFIER;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END GET_TRANSACTION_EXT_ID;

-------------------------------------------------------------------------------------
    PROCEDURE GET_FIN_CONTRACT_TRANSACTION(
        p_PARTY_NAME IN VARCHAR,
        p_CONTRACT_NAME IN VARCHAR2,
        p_SCHEDULE_STATE IN NUMBER,
        p_CREATE_IF_NOT_FOUND IN BOOLEAN,
        p_TRANSACTION IN OUT INTERCHANGE_TRANSACTION%ROWTYPE,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        v_TRANSACTION_IDENTIFIER INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE;
        v_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
    BEGIN
        v_TRANSACTION_IDENTIFIER := BUILD_TRANSACTION_IDENTIFIER(p_PARTY_NAME, p_CONTRACT_NAME);

        --GET THE TRANSACTION FROM THE RIGHT TABLE.
        BEGIN
            --FIRST SEE IF IT EXISTS TO GET ITS ID.
            IF p_SCHEDULE_STATE = GA.INTERNAL_STATE THEN
                SELECT *
                INTO   p_TRANSACTION
                FROM   INTERCHANGE_TRANSACTION
                WHERE  TRANSACTION_IDENTIFIER = v_TRANSACTION_IDENTIFIER;
            ELSE
                SELECT *
                INTO   p_TRANSACTION
                FROM   INTERCHANGE_TRANSACTION_EXT
                WHERE  TRANSACTION_IDENTIFIER = v_TRANSACTION_IDENTIFIER;
            END IF;
        EXCEPTION
            WHEN TOO_MANY_ROWS THEN
                p_ERROR_MESSAGE := 'Multiple INTERCHANGE_TRANSACTIONs exist for party=' || p_PARTY_NAME || ' and contract=' || p_CONTRACT_NAME;
            WHEN NO_DATA_FOUND THEN
                IF p_CREATE_IF_NOT_FOUND THEN
                    -- see if it exists in other schedule state - if so, get that transaction's name
                    BEGIN
                        IF p_SCHEDULE_STATE = GA.INTERNAL_STATE THEN
                            SELECT TRANSACTION_NAME
                            INTO   v_TRANSACTION_NAME
                            FROM   INTERCHANGE_TRANSACTION_EXT
                            WHERE  TRANSACTION_IDENTIFIER = v_TRANSACTION_IDENTIFIER AND ROWNUM = 1;
                        ELSE
                            SELECT TRANSACTION_NAME
                            INTO   v_TRANSACTION_NAME
                            FROM   INTERCHANGE_TRANSACTION
                            WHERE  TRANSACTION_IDENTIFIER = v_TRANSACTION_IDENTIFIER AND ROWNUM = 1;
                        END IF;
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_TRANSACTION_NAME := v_TRANSACTION_IDENTIFIER;
                    END;

                    p_TRANSACTION.TRANSACTION_ID := 0;
                    p_TRANSACTION.TRANSACTION_NAME := v_TRANSACTION_NAME;
                    p_TRANSACTION.TRANSACTION_ALIAS := SUBSTR(v_TRANSACTION_NAME, 1, 32);
                    p_TRANSACTION.TRANSACTION_DESC := 'Created by MarketManager via QueryFin action';
                    p_TRANSACTION.TRANSACTION_IDENTIFIER := v_TRANSACTION_IDENTIFIER;
                    p_TRANSACTION.IS_IMPORT_EXPORT := 0;
                ELSE
                    p_ERROR_MESSAGE := 'Unable to find INTERCHANGE_TRANSACTION associated with party=' || p_PARTY_NAME || ' and contract=' || p_CONTRACT_NAME;
                    RETURN;
                END IF;
        END;
    END GET_FIN_CONTRACT_TRANSACTION;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_FIN_CONTRACT(
        p_PARTY_NAME IN VARCHAR2,
        p_CONTRACT_XML IN XMLTYPE,
        p_SCHEDULE_STATE IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        v_STATUS NUMBER;
        v_BUYER_ATTRIBUTE_ID NUMBER(9);
        v_SELLER_ATTRIBUTE_ID NUMBER(9);
        v_ENTITY_DOMAIN_ALIAS VARCHAR2(32);
        v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
        v_OID NUMBER(9);
        v_TRANSACTION_STATUS IT_STATUS.TRANSACTION_STATUS_NAME%TYPE;
		v_RT_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;

        CURSOR c_XML IS
            SELECT EXTRACTVALUE(VALUE(T), '//@name', g_MISO_NAMESPACE) "TRANSACTION_NAME", EXTRACTVALUE(VALUE(T), '//@buyer', g_MISO_NAMESPACE) "PURCHASER_NAME", EXTRACTVALUE(VALUE(T), '//@seller', g_MISO_NAMESPACE) "SELLER_NAME",
                   EXTRACTVALUE(VALUE(T), '//@type', g_MISO_NAMESPACE) "AGREEMENT_TYPE", TO_DATE(EXTRACTVALUE(VALUE(T), '//EffectiveStart', g_MISO_NAMESPACE), g_DATE_FORMAT) "BEGIN_DATE",
                   TO_DATE(EXTRACTVALUE(VALUE(T), '//EffectiveEnd', g_MISO_NAMESPACE), g_DATE_FORMAT) "END_DATE", EXTRACTVALUE(VALUE(T), '//SourceLocation', g_MISO_NAMESPACE) "SOURCE_NAME",
                   EXTRACTVALUE(VALUE(T), '//SinkLocation', g_MISO_NAMESPACE) "SINK_NAME", EXTRACTVALUE(VALUE(T), '//DeliveryPoint', g_MISO_NAMESPACE) "POD_NAME", EXTRACTVALUE(VALUE(T), '//ScheduleApproval', g_MISO_NAMESPACE) "APPROVAL_TYPE",
                   EXTRACTVALUE(VALUE(T), '//SettlementMarket', g_MISO_NAMESPACE) "MARKET_TYPE", EXTRACTVALUE(VALUE(T), '//CongestionLosses', g_MISO_NAMESPACE) "LOSS_OPTION", EXTRACTVALUE(VALUE(T), '//BuyerComments', g_MISO_NAMESPACE) "BUYER_COMMENTS",
                   EXTRACTVALUE(VALUE(T), '//SellerComments', g_MISO_NAMESPACE) "SELLER_COMMENTS", TO_DATE(EXTRACTVALUE(VALUE(T), '//ContractApproval', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "APPROVAL_DATE"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_CONTRACT_XML, '//FinContract', g_MISO_NAMESPACE))) T;
    BEGIN
        v_ENTITY_DOMAIN_ALIAS := CASE p_SCHEDULE_STATE
                                    WHEN GA.INTERNAL_STATE THEN 'TRANSACTION'
                                    ELSE 'EXTERNAL_TRANSACTION'
                                END;

        --LOOP OVER EACH CONTRACT.
        FOR v_XML IN c_XML LOOP
            GET_FIN_CONTRACT_TRANSACTION(p_PARTY_NAME, v_XML.TRANSACTION_NAME, p_SCHEDULE_STATE, TRUE, v_TRANSACTION, p_ERROR_MESSAGE);

            IF p_ERROR_MESSAGE IS NOT NULL THEN
                RETURN;
            END IF;

            v_TRANSACTION.PURCHASER_ID := ID_FOR_PSE_IDENT(v_XML.PURCHASER_NAME, p_LOGGER);
            v_TRANSACTION.SELLER_ID := ID_FOR_PSE_IDENT(v_XML.SELLER_NAME, p_LOGGER);
            v_TRANSACTION.CONTRACT_ID := GET_CONTRACT_ID_FOR_PARTY(p_PARTY_NAME);
            ID.ID_FOR_SERVICE_POINT_XID(v_XML.SOURCE_NAME, TRUE, v_TRANSACTION.SOURCE_ID);
            ID.ID_FOR_SERVICE_POINT_XID(v_XML.SINK_NAME, TRUE, v_TRANSACTION.SINK_ID);
			IF v_XML.POD_NAME IS NOT NULL THEN
            	ID.ID_FOR_SERVICE_POINT_XID(v_XML.POD_NAME, TRUE, v_TRANSACTION.POD_ID);
			ELSE
				-- DeliveryPoint element is optional in the XML. Since we need it for settlement,
				-- if it's not there, set it to the source for purchases and the sink for sales.
				IF p_PARTY_NAME = v_XML.PURCHASER_NAME THEN
					v_TRANSACTION.POD_ID := v_TRANSACTION.SOURCE_ID;
				ELSE
					v_TRANSACTION.POD_ID := v_TRANSACTION.SINK_ID;
				END IF;
			END IF;
            ID.ID_FOR_SC('MISO', FALSE, v_TRANSACTION.SC_ID);

            BEGIN
                SELECT COMMODITY_ID
                INTO   v_TRANSACTION.COMMODITY_ID
                FROM   IT_COMMODITY
                WHERE  COMMODITY_ALIAS = CASE v_XML.MARKET_TYPE WHEN 'RealTime' THEN 'RT' ELSE 'DA' END;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    p_ERROR_MESSAGE := 'Commodity with market type=' || v_XML.MARKET_TYPE || ' and commodity type=Energy does not exist.';
                    RETURN;
            END;

            ID.ID_FOR_ENTITY_ATTRIBUTE('BuyerComments', v_ENTITY_DOMAIN_ALIAS, 'String', TRUE, v_BUYER_ATTRIBUTE_ID);
            ID.ID_FOR_ENTITY_ATTRIBUTE('SellerComments', v_ENTITY_DOMAIN_ALIAS, 'String', TRUE, v_SELLER_ATTRIBUTE_ID);
            v_TRANSACTION.TRANSACTION_NAME := v_TRANSACTION.TRANSACTION_IDENTIFIER;
            v_TRANSACTION.TRANSACTION_ALIAS := SUBSTR(v_TRANSACTION.TRANSACTION_IDENTIFIER, 1, 32);

            IF v_XML.PURCHASER_NAME = p_PARTY_NAME THEN
                v_TRANSACTION.TRANSACTION_TYPE := 'Purchase';
            ELSIF v_XML.SELLER_NAME = p_PARTY_NAME THEN
                v_TRANSACTION.TRANSACTION_TYPE := 'Sale';
            ELSE
                -- !!! This should never happen!
                v_TRANSACTION.TRANSACTION_TYPE := '?';
            END IF;

            v_TRANSACTION.IS_BID_OFFER := 1;
            v_TRANSACTION.TRANSACTION_INTERVAL := 'Hour';
            v_TRANSACTION.EXTERNAL_INTERVAL := 'Hour';
            v_TRANSACTION.BEGIN_DATE := v_XML.BEGIN_DATE;
            v_TRANSACTION.END_DATE := v_XML.END_DATE;
            v_TRANSACTION.AGREEMENT_TYPE := v_XML.AGREEMENT_TYPE;
            -- transaction approval type is type of SCHEDULE approval,
            -- transaction approval status is based on presence of APPROVAL_DATE in xml
            v_TRANSACTION.APPROVAL_TYPE := v_XML.APPROVAL_TYPE;
            v_TRANSACTION.LOSS_OPTION := v_XML.LOSS_OPTION;
            v_TRANSACTION.IS_IMPORT_EXPORT := 0;

            IF p_SCHEDULE_STATE = GA.EXTERNAL_STATE THEN
                v_TRANSACTION_STATUS := NULL;
            ELSE
                IF v_XML.APPROVAL_DATE IS NULL THEN
                    v_TRANSACTION_STATUS := 'Requires Apvl';
                ELSE
                    v_TRANSACTION_STATUS := 'Approved';
                END IF;
            END IF;

            IF v_XML.APPROVAL_DATE IS NULL THEN
				ALERTS.TRIGGER_ALERTS(g_UNCONFIRMED_CONTRACT_ALERT, LOGS.c_Level_Notice, v_TRANSACTION.Transaction_Name || ' is not confirmed');
			END IF;

            MM_UTIL.PUT_TRANSACTION(v_OID, v_TRANSACTION, p_SCHEDULE_STATE, v_TRANSACTION_STATUS);

            --Save the comments if there are any.
            IF NOT v_XML.BUYER_COMMENTS IS NULL THEN
                SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION.TRANSACTION_ID, v_BUYER_ATTRIBUTE_ID, v_TRANSACTION.BEGIN_DATE, NULL, v_XML.BUYER_COMMENTS, v_TRANSACTION.TRANSACTION_ID, v_BUYER_ATTRIBUTE_ID, v_TRANSACTION.BEGIN_DATE, v_STATUS);
            END IF;

            IF NOT v_XML.SELLER_COMMENTS IS NULL THEN
                SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION.TRANSACTION_ID, v_SELLER_ATTRIBUTE_ID, v_TRANSACTION.BEGIN_DATE, NULL, v_XML.SELLER_COMMENTS, v_TRANSACTION.TRANSACTION_ID, v_SELLER_ATTRIBUTE_ID, v_TRANSACTION.BEGIN_DATE, v_STATUS);
            END IF;

            --if approved and it is a DA transaction, then create a RT transaction as well
            IF v_TRANSACTION_STATUS = 'Approved' AND v_XML.MARKET_TYPE = 'DayAhead' THEN
    			COPY_DA_TXN_TO_RT(v_TRANSACTION, v_RT_TRANSACTION_ID, v_STATUS, p_ERROR_MESSAGE);

                IF v_STATUS < 0 THEN
                	p_ERROR_MESSAGE:=    p_ERROR_MESSAGE || ': ' || TO_CHAR(v_STATUS) ||
                        				 ' in MISO_EXCHANGE.PUT_FIN_SCHEDULE while calling COPY_DA_TXN_TO_RT';
                	RETURN;
    			END IF;
			END IF;

        END LOOP;
    END PUT_FIN_CONTRACT;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_FIN_CONTRACT(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_CONTRACT_NAME IN VARCHAR2,
        p_COUNTER_PARTY_NAME IN VARCHAR2,
        p_EFFECTIVE_START IN DATE,
        p_EFFECTIVE_END IN DATE,
        p_APPROVAL_REQUIRED IN NUMBER,
        p_COUNTER_PARTY IN VARCHAR2,
        p_COPY_INTERNAL IN BOOLEAN,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
    BEGIN
        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT(
                       "QueryFinContract",
                       XMLFOREST(
                           p_CONTRACT_NAME AS "ContractName",
                           p_COUNTER_PARTY_NAME AS "CounterPartyName",
                           TO_CHAR(p_EFFECTIVE_START, g_DATE_FORMAT) AS "EffectiveStart",
                           TO_CHAR(p_EFFECTIVE_END, g_DATE_FORMAT) AS "EffectiveEnd",
                           p_APPROVAL_REQUIRED AS "ApprovalRequired",
                           p_COUNTER_PARTY AS "CounterParty"
                       )
                   )
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinContract';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;
-----------------------------------------------------------------------------------
        PUT_FIN_CONTRACT(p_PARTY_NAME, v_XML_RESPONSE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE, p_LOGGER);

        IF p_COPY_INTERNAL THEN
            PUT_FIN_CONTRACT(p_PARTY_NAME, v_XML_RESPONSE, GA.INTERNAL_STATE, p_ERROR_MESSAGE, p_LOGGER);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE;
    END QUERY_FIN_CONTRACT;

-------------------------------------------------------------------------------------
PROCEDURE PUT_FIN_SCHEDULES(p_PARTY_NAME     IN VARCHAR2,
                            p_FIN_SCHEDULES  IN XMLTYPE,
                            p_SCHEDULE_STATE IN NUMBER,
                            p_ERROR_MESSAGE  OUT VARCHAR2) AS
    v_TRANSACTION         INTERCHANGE_TRANSACTION%ROWTYPE;
    v_PREV_CONTRACT_NAME  INTERCHANGE_TRANSACTION.Transaction_Name%TYPE := 'INITVAL';
    v_PREV_PURCHASER_NAME PSE.PSE_NAME%TYPE := 'INITVAL';
    v_PREV_SELLER_NAME    PSE.PSE_NAME%TYPE := 'INITVAL';
    v_PREV_TYPE           INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE := 'INITVAL';
    v_PREV_SCHEDULE_DAY   DATE := LOW_DATE;
    v_STATUS              NUMBER;
    v_BID_OFFER_ID        NUMBER(9);
    v_RT_TRANSACTION_ID   INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_IS_CONTRACT_DA      BOOLEAN;

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//@name', g_MISO_NAMESPACE) "CONTRACT_NAME",
               EXTRACTVALUE(VALUE(T), '//@buyer', g_MISO_NAMESPACE) "PURCHASER_NAME",
               EXTRACTVALUE(VALUE(T), '//@seller', g_MISO_NAMESPACE) "SELLER_NAME",
               EXTRACTVALUE(VALUE(T), '//@type', g_MISO_NAMESPACE) "AGREEMENT_TYPE",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "SCHEDULE_DAY",
               EXTRACTVALUE(VALUE(U), '//@hour', g_MISO_NAMESPACE) "SCHEDULE_HOUR",
               EXTRACTVALUE(VALUE(U), '//@MW', g_MISO_NAMESPACE) "SCHEDULE_VAL",
               TO_DATE(EXTRACTVALUE(VALUE(T), '//ScheduleApproval', g_MISO_NAMESPACE),
                       g_DATE_TIME_ZONE_FORMAT) "APPROVAL_DATE"
          FROM TABLE(XMLSEQUENCE(EXTRACT(p_FIN_SCHEDULES,
                                         '/QueryResponse/FinSchedule',
                                         g_MISO_NAMESPACE))) T,
               TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                         '/FinSchedule/FinScheduleData/FinScheduleHourly',
                                         g_MISO_NAMESPACE))) U
         ORDER BY 1;

BEGIN
    --GET THE BID_OFFER_ID.
    v_BID_OFFER_ID := 0;
    --ID.ID_FOR_BID_OFFER('Normal', TRUE, v_BID_OFFER_ID, 'Hour');

    --LOOP OVER EACH CONTRACT.
    FOR v_XML IN c_XML LOOP
        --GET THE IDS IF SOMETHING HAS CHANGED
        IF v_PREV_CONTRACT_NAME <> v_XML.CONTRACT_NAME OR
           v_PREV_PURCHASER_NAME <> v_XML.PURCHASER_NAME OR v_PREV_SELLER_NAME <> v_XML.SELLER_NAME OR
           v_PREV_SCHEDULE_DAY <> v_XML.SCHEDULE_DAY OR v_PREV_TYPE <> v_XML.AGREEMENT_TYPE THEN
            v_PREV_CONTRACT_NAME  := v_XML.CONTRACT_NAME;
            v_PREV_PURCHASER_NAME := v_XML.PURCHASER_NAME;
            v_PREV_SELLER_NAME    := v_XML.SELLER_NAME;
            v_PREV_SCHEDULE_DAY   := v_XML.SCHEDULE_DAY;
            v_PREV_TYPE           := v_XML.AGREEMENT_TYPE;
            GET_FIN_CONTRACT_TRANSACTION(p_PARTY_NAME,
                                         v_XML.CONTRACT_NAME,
                                         GA.INTERNAL_STATE,
                                         FALSE,
                                         v_TRANSACTION,
                                         p_ERROR_MESSAGE);

            IF p_ERROR_MESSAGE IS NOT NULL THEN
                v_TRANSACTION.TRANSACTION_ID := 0;
            END IF;

            -- set a flag if this is a real-time contract, so we don't try
            -- to copy things from day-ahead to real-time
            v_IS_CONTRACT_DA := IS_FIN_CONTRACT_DA(v_TRANSACTION.TRANSACTION_ID);

            -- post a notification if the schedule isn't approved
            IF v_XML.APPROVAL_DATE IS NULL THEN
                MM_UTIL.POST_UNCONFIRMED_SCHED_ALARM('MISO',
                                                     v_TRANSACTION.Transaction_Id,
                                                     v_XML.SCHEDULE_DAY);
            END IF;
        END IF;

        IF v_TRANSACTION.TRANSACTION_ID > 0 THEN
            --save the values to BID_OFFER_SET.
            --It gets moved to IT_SCHEDULE when it is accepted.
            SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
            BO.PUT_BID_OFFER_SET(v_TRANSACTION.TRANSACTION_ID,
                                 v_BID_OFFER_ID,
                                 p_SCHEDULE_STATE,
                                 v_XML.SCHEDULE_DAY + v_XML.SCHEDULE_HOUR / 24,
                                 1,
                                 NULL,
                                 v_XML.SCHEDULE_VAL,
                                 'P',
                                 MM_MISO_UTIL.g_MISO_TIMEZONE,
                                 v_STATUS);
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

            IF v_STATUS < 0 THEN
                p_ERROR_MESSAGE            := 'Error ' || TO_CHAR(v_STATUS) ||
                                              ' in MISO_EXCHANGE.PUT_FIN_SCHEDULE while calling BO.PUT_BID_OFFER_SET.';
                SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                RETURN;
            END IF;

            --when the schedule is accepted the bid/offer set quantity
            --gets copied to IT_SCHEDULE also
            IF v_XML.APPROVAL_DATE IS NOT NULL THEN
                --put with internal state
                MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_TRANSACTION.TRANSACTION_ID,
                                                  v_XML.SCHEDULE_DAY + v_XML.SCHEDULE_HOUR / 24,
                                                  GA.INTERNAL_STATE,
                                                  NULL,
                                                  v_XML.SCHEDULE_VAL,
                                                  v_STATUS,
                                                  p_ERROR_MESSAGE);

                IF v_STATUS < 0 THEN
                    p_ERROR_MESSAGE            := 'Error ' || TO_CHAR(v_STATUS) ||
                                                  ' in MISO_EXCHANGE.PUT_FIN_SCHEDULE while calling IT.PUT_IT_SCHEDULE.';
                    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                    RETURN;
                END IF;

                -- put with external state
                MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_TRANSACTION.TRANSACTION_ID,
                                                  v_XML.SCHEDULE_DAY + v_XML.SCHEDULE_HOUR / 24,
                                                  GA.EXTERNAL_STATE,
                                                  NULL,
                                                  v_XML.SCHEDULE_VAL,
                                                  v_STATUS,
                                                  p_ERROR_MESSAGE);

                IF v_STATUS < 0 THEN
                    p_ERROR_MESSAGE            := 'Error ' || TO_CHAR(v_STATUS) ||
                                                  ' in MISO_EXCHANGE.PUT_FIN_SCHEDULE while calling IT.PUT_IT_SCHEDULE.';
                    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
                    RETURN;
                END IF;

                IF v_IS_CONTRACT_DA THEN
                    COPY_DA_TXN_TO_RT(v_TRANSACTION,
                                      v_RT_TRANSACTION_ID,
                                      v_STATUS,
                                      p_ERROR_MESSAGE);

                    IF v_STATUS < 0 THEN
                        p_ERROR_MESSAGE := p_ERROR_MESSAGE || ': ' || TO_CHAR(v_STATUS) ||
                                           ' in MISO_EXCHANGE.PUT_FIN_SCHEDULE while calling COPY_DA_TXN_TO_RT';
                        RETURN;
                    ELSE

                        --put with internal state
                        MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_RT_TRANSACTION_ID,
                                                          v_XML.SCHEDULE_DAY +
                                                          v_XML.SCHEDULE_HOUR / 24,
                                                          GA.INTERNAL_STATE,
                                                          NULL,
                                                          v_XML.SCHEDULE_VAL,
                                                          v_STATUS,
                                                          p_ERROR_MESSAGE);

                        IF v_STATUS < 0 THEN
                            p_ERROR_MESSAGE := 'Error ' || TO_CHAR(v_STATUS) ||
                                               ' in MISO_EXCHANGE.PUT_FIN_SCHEDULE while calling IT.PUT_IT_SCHEDULE.';
                            RETURN;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
        RAISE;
END PUT_FIN_SCHEDULES;
-------------------------------------------------------------------------------------
    PROCEDURE QUERY_FIN_SCHEDULE(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_CONTRACT_NAME IN VARCHAR2,
        p_COUNTER_PARTY_NAME IN VARCHAR2,
        p_SCHEDULE_DAY IN DATE,
        p_APPROVAL_REQUIRED IN NUMBER,
        p_COPY_INTENAL IN BOOLEAN,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
    BEGIN
        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", p_PARTY_NAME AS "party"),
                   XMLELEMENT("QueryFinSchedule", XMLFOREST(p_CONTRACT_NAME AS "ContractName", p_COUNTER_PARTY_NAME AS "CounterParty", TO_CHAR(p_SCHEDULE_DAY, g_DATE_FORMAT) AS "Date", p_APPROVAL_REQUIRED AS "ApprovalRequired"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'QueryFinSchedule';   --TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        IF NOT v_XML_RESPONSE IS NULL THEN
            PUT_FIN_SCHEDULES(p_PARTY_NAME, v_XML_RESPONSE, GA.EXTERNAL_STATE, p_ERROR_MESSAGE);

            IF p_COPY_INTENAL = TRUE THEN
                PUT_FIN_SCHEDULES(p_PARTY_NAME, v_XML_RESPONSE, GA.INTERNAL_STATE, p_ERROR_MESSAGE);
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_FIN_SCHEDULE;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_MESSAGES(
        p_CRED IN mex_credentials,
        p_ACTIVE_DATE_TIME IN DATE,
        p_REALM IN VARCHAR2,
        p_PRIORITY IN NUMBER,
        p_LOG_ONLY IN NUMBER,
        p_STATUS OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        --Handle Query and Response for 'Messages'
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;

        CURSOR c_XML IS
            SELECT EXTRACTVALUE(VALUE(U), '//@realm', g_MISO_NAMESPACE) "MESSAGE_REALM", TO_DATE(EXTRACTVALUE(VALUE(U), '//EffectiveTime', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "EFFECTIVE_TIME",
                   TO_DATE(EXTRACTVALUE(VALUE(U), '//TerminationTime', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "TERMINATION_TIME", EXTRACTVALUE(VALUE(U), '//Priority', g_MISO_NAMESPACE) "MESSAGE_PRIORITY",
                   EXTRACTVALUE(VALUE(U), '//Text', g_MISO_NAMESPACE) "MESSAGE_TEXT"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE, '//Messages', g_MISO_NAMESPACE))) T, TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//Message', g_MISO_NAMESPACE))) U;
    BEGIN
        --Build up the QueryRequest
        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"),
                   XMLELEMENT("QueryMessages", XMLATTRIBUTES(p_REALM AS "realm"), XMLFOREST(TO_CHAR(p_ACTIVE_DATE_TIME, g_DATE_TIME_FORMAT) AS "ActiveDateTime", p_PRIORITY AS "PriorityThreshold"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from XML_TRACE WHERE key1 = 'Messages'; --DEBUG--TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        COMMIT;

-----------------------------------------------------------------------------------
        FOR v_XML IN c_XML LOOP
            MEX_UTIL.INSERT_MARKET_MESSAGE('MISO', p_ACTIVE_DATE_TIME, v_XML.MESSAGE_REALM, v_XML.EFFECTIVE_TIME, v_XML.TERMINATION_TIME, v_XML.MESSAGE_PRIORITY, NULL, NULL, v_XML.MESSAGE_TEXT);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_MESSAGES;

-------------------------------------------------------------------------------------
     PROCEDURE QUERY_SETTLEMENT_STATEMENT(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_STATEMENT_DATE IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        --Handle Query and Response for Settlement Statements
        v_XML_FILELIST XMLTYPE := NULL;
        v_XML_FILE XMLTYPE := NULL;
        v_MAP MEX_UTIL.PARAMETER_MAP;
        v_CLOB_REQ CLOB;
        v_FILE_COUNT BINARY_INTEGER := 0;
		v_RESULT mex_result;

        CURSOR c_FILES(
            v_XML IN XMLTYPE
        ) IS
            SELECT EXTRACTVALUE(VALUE(U), '/File', MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF) "FILENAME"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML, '/FileList', MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) T, TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '/FileList/File', MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) U;

        CURSOR c_STATEMENTS(
            v_XML IN XMLTYPE
        ) IS
            SELECT EXTRACT(VALUE(T), '//DA_STLMT', g_SETTLEMENT_NAMESPACE) "DA_STATEMENT_XML", EXTRACT(VALUE(T), '//RT_STLMT', g_SETTLEMENT_NAMESPACE) "RT_STATEMENT_XML", EXTRACT(VALUE(T), '//FTR_STLMT', g_SETTLEMENT_NAMESPACE) "FTR_STATEMENT_XML"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML, '/', g_SETTLEMENT_NAMESPACE))) T;

        FUNCTION GET_STATEMENT_ID
        (
            p_STATEMENT_NAME IN VARCHAR2,
            p_STATEMENT_XML IN XMLTYPE
        ) RETURN VARCHAR2 AS

        v_STATEMENT_IDENT VARCHAR(256);

        BEGIN

            SELECT EXTRACTVALUE(VALUE(T),'/' || p_STATEMENT_NAME || '/STATEMENT_ID', g_SETTLEMENT_NAMESPACE) "STATEMENT_IDENT"
            INTO v_STATEMENT_IDENT
            FROM TABLE(XMLSEQUENCE(EXTRACT(p_STATEMENT_XML,'/' || p_STATEMENT_NAME, g_SETTLEMENT_NAMESPACE))) T;

            RETURN v_STATEMENT_IDENT;

        END GET_STATEMENT_ID;

        PROCEDURE PUT_STATEMENT_AND_STATUS
        (
            p_ISO_SOURCE IN VARCHAR2,
            p_STATEMENT_NAME IN VARCHAR2,
            p_MARKET_ABBR IN VARCHAR2,
            p_STATEMENT_XML IN XMLTYPE,
            p_TRACE_ON IN NUMBER,
            p_ERROR_MESSAGE OUT VARCHAR2
        )
        AS
        BEGIN

             MM_MISO_SETTLEMENT.PUT_SETTLEMENT_STATEMENT(
                 p_ISO_SOURCE,
                 p_STATEMENT_NAME,
                 p_MARKET_ABBR,
                 p_STATEMENT_XML,
                 p_TRACE_ON,
                 p_ERROR_MESSAGE
                 );

        END PUT_STATEMENT_AND_STATUS;

    BEGIN
        -- TODO - loop through asset owners for current ISO_ACCOUNT
        v_MAP('isoentity') := p_PARTY_NAME;
        v_MAP('isodate') := TO_CHAR(p_STATEMENT_DATE, 'YYYYMMDD');
-----------------------------------------------------------------------------------
-- DO THE EXCHANGE
-----------------------------------------------------------------------------------

        --DO THE TRANSFER IF WE ARE NOT IN TESTING MODE
        IF p_LOG_ONLY = 0 THEN
            DBMS_LOB.CREATETEMPORARY(v_CLOB_REQ, TRUE);
			v_RESULT := Mex_Switchboard.Invoke(p_Market => MM_MISO_UTIL.g_MEX_MARKET,
								 p_Action => 'settlement',
								 p_Logger => p_LOGGER,
								 p_Cred => p_CRED,
								 p_Request_ContentType => 'text/xml',
								 p_Request => v_CLOB_REQ,
								 p_Log_Only => p_LOG_ONLY
								 );

            IF v_RESULT.STATUS_CODE = MEX_SWITCHBOARD.c_Status_Success THEN
                v_XML_FILELIST	:= XMLTYPE.CREATEXML(v_RESULT.RESPONSE);
            END IF;

            DBMS_LOB.FREETEMPORARY(v_CLOB_REQ);
        END IF;


        COMMIT;

-----------------------------------------------------------------------------------
        IF v_XML_FILELIST IS NOT NULL THEN
            --Query for files and send those to the Settlement Statement parsing logic.
            FOR v_FILE IN c_FILES(v_XML_FILELIST) LOOP
                v_FILE_COUNT := v_FILE_COUNT + 1;
-----------------------------------------------------------------------------------
-- GET FILE FROM SERVER
-----------------------------------------------------------------------------------
                DBMS_LOB.CREATETEMPORARY(v_CLOB_REQ, TRUE);
                v_MAP.DELETE;
                v_MAP('isofile') := v_FILE.FILENAME;

				v_RESULT := MEX_SWITCHBOARD.FetchFile(v_FILE.FILENAME, p_LOGGER, p_CRED, p_LOG_ONLY);

                IF v_RESULT.STATUS_CODE = MEX_SWITCHBOARD.c_Status_Success THEN
                    -- these files don't have a SOAP envelope
                    v_XML_FILE := XMLTYPE.CREATEXML(v_RESULT.RESPONSE);
				ELSE
					v_XML_FILE := NULL;
                END IF;

                DBMS_LOB.FREETEMPORARY(v_CLOB_REQ);

                COMMIT;

-----------------------------------------------------------------------------------

                -- TODO log error if fail to get file from server!
                FOR v_STATEMENT IN c_STATEMENTS(v_XML_FILE) LOOP
                    IF v_STATEMENT.DA_STATEMENT_XML IS NOT NULL THEN
                        PUT_STATEMENT_AND_STATUS(p_CRED.EXTERNAL_ACCOUNT_NAME, 'DA_STLMT', 'DA', v_STATEMENT.DA_STATEMENT_XML, 0, p_ERROR_MESSAGE);
                    END IF;

                    IF v_STATEMENT.RT_STATEMENT_XML IS NOT NULL THEN
                        PUT_STATEMENT_AND_STATUS(p_CRED.EXTERNAL_ACCOUNT_NAME, 'RT_STLMT', 'RT', v_STATEMENT.RT_STATEMENT_XML, 0, p_ERROR_MESSAGE);
                    END IF;

                    IF v_STATEMENT.FTR_STATEMENT_XML IS NOT NULL THEN
                        PUT_STATEMENT_AND_STATUS(p_CRED.EXTERNAL_ACCOUNT_NAME, 'FTR_STLMT', 'FTR', v_STATEMENT.FTR_STATEMENT_XML, 0, p_ERROR_MESSAGE);
                    END IF;
                END LOOP;
            END LOOP;

            IF v_FILE_COUNT = 0 THEN
                -- no files? then see if the filelist XML is actually a single statement XML
                FOR v_STATEMENT IN c_STATEMENTS(v_XML_FILELIST) LOOP
                    IF v_STATEMENT.DA_STATEMENT_XML IS NOT NULL THEN
                        PUT_STATEMENT_AND_STATUS(p_CRED.EXTERNAL_ACCOUNT_NAME, 'DA_STLMT', 'DA', v_STATEMENT.DA_STATEMENT_XML, 0, p_ERROR_MESSAGE);
                    END IF;

                    IF v_STATEMENT.RT_STATEMENT_XML IS NOT NULL THEN
                        PUT_STATEMENT_AND_STATUS(p_CRED.EXTERNAL_ACCOUNT_NAME, 'RT_STLMT', 'RT', v_STATEMENT.RT_STATEMENT_XML, 0, p_ERROR_MESSAGE);
                    END IF;

                    IF v_STATEMENT.FTR_STATEMENT_XML IS NOT NULL THEN
                        PUT_STATEMENT_AND_STATUS(p_CRED.EXTERNAL_ACCOUNT_NAME, 'FTR_STLMT', 'FTR', v_STATEMENT.FTR_STATEMENT_XML, 0, p_ERROR_MESSAGE);
                    END IF;
                END LOOP;
            END IF;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_SETTLEMENT_STATEMENT;

-------------------------------------------------------------------------------------
    PROCEDURE PUT_SERVICE_POINT(
        p_REQUEST_DAY IN VARCHAR2,
        p_EXTERNAL_IDENTIFIER IN VARCHAR2,
        p_NODE_TYPE IN VARCHAR2,
        p_SERVICE_POINT_ID OUT NUMBER,
        p_STATUS OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        v_COUNT NUMBER := 0;
    BEGIN
        p_STATUS := GA.SUCCESS;

        SELECT COUNT(*)
        INTO   v_COUNT
        FROM   SERVICE_POINT
        WHERE  EXTERNAL_IDENTIFIER = p_EXTERNAL_IDENTIFIER;

        IF v_COUNT = 0 THEN
            --Add new SERVICE_POINT record
            SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
            IO.PUT_SERVICE_POINT(p_SERVICE_POINT_ID, p_EXTERNAL_IDENTIFIER,                                                                                                                                                                             --Name
                p_EXTERNAL_IDENTIFIER,                                                                                                                                                                                                                 --Alias
                'Downloaded from MISO, day = ' || p_REQUEST_DAY,                                                                                                                                                                                        --Desc
                0,                                                                                                                                                                                                                                        --ID
                'Retail', 0, 0, 0, 0, 0, 0, 0, '?', '?', '?', p_EXTERNAL_IDENTIFIER, 0, p_NODE_TYPE, NULL, NULL, NULL);
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
        ELSE
            SELECT SERVICE_POINT_ID
            INTO   p_SERVICE_POINT_ID
            FROM   SERVICE_POINT
            WHERE  EXTERNAL_IDENTIFIER = p_EXTERNAL_IDENTIFIER;
        END IF;

        SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
    EXCEPTION
        WHEN OTHERS THEN
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := SQLERRM;
    END PUT_SERVICE_POINT;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_NODE_LIST(
        p_CRED IN mex_credentials,
        p_REQUEST_DAY IN DATE,
        p_LOG_ONLY IN NUMBER,
        p_STATUS OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        --Handle Query and Response for 'NodeList'
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
    BEGIN
        p_STATUS := GA.SUCCESS;

        SELECT XMLELEMENT("QueryRequest", XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"), XMLELEMENT("QueryNodeList", XMLATTRIBUTES(TO_CHAR(p_REQUEST_DAY, g_DATE_FORMAT) AS "day")))
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from XML_TRACE WHERE key1 = 'NodeList'; --DEBUG--TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);

-----------------------------------------------------------------------------------
        EXECUTE IMMEDIATE 'TRUNCATE TABLE MISO_CPNODES_STAGING';

        INSERT INTO MISO_CPNODES_STAGING
                    (NODE_NAME, NODE_TYPE, ENTRY_DATE)
            SELECT EXTRACTVALUE(VALUE(U), '//@name', g_MISO_NAMESPACE) NODE_NAME, EXTRACTVALUE(VALUE(U), '//@nodeType', g_MISO_NAMESPACE) NODE_TYPE, SYSDATE ENTRY_DATE
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE, '//Node', g_MISO_NAMESPACE))) U;

        INSERT INTO MISO_CPNODES
                    (NODE_NAME, NODE_TYPE, ENTRY_DATE)
            SELECT NODE_NAME, NODE_TYPE, SYSDATE AS ENTRY_DATE
            FROM   MISO_CPNODES_STAGING
            WHERE  NODE_NAME NOT IN(SELECT NODE_NAME
                                    FROM   MISO_CPNODES);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_NODE_LIST;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_PORTFOLIO(
        p_CRED IN mex_credentials,
        p_PARTY_NAME IN VARCHAR2,
        p_LOG_ONLY IN NUMBER,
        p_STATUS OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        --Handle Query and Response for 'NodeList'
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_PORTFOLIO_ID NUMBER(9);
        v_SERVICE_POINT_ID NUMBER(9);
        v_NODE_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
        v_NODE_TYPE SERVICE_POINT.NODE_TYPE%TYPE;

        CURSOR c_XML IS
            SELECT EXTRACTVALUE(VALUE(T), '//@name', g_MISO_NAMESPACE) "PORTFOLIO_NAME", EXTRACTVALUE(VALUE(U), '//LocationName', g_MISO_NAMESPACE) "LOCATION_NAME"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE, '//Portfolio', g_MISO_NAMESPACE))) T, TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//LocationName', g_MISO_NAMESPACE))) U;
    BEGIN
		p_STATUS := GA.SUCCESS;

        SELECT XMLELEMENT("QueryRequest", XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"), XMLELEMENT("QueryPortfolios", XMLELEMENT("All")))
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from XML_TRACE WHERE key1 = 'NodeList'; --DEBUG--TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);

-----------------------------------------------------------------------------------
        FOR v_XML IN c_XML LOOP
            v_PORTFOLIO_ID := GET_PORTFOLIO_ID(v_XML.PORTFOLIO_NAME, p_PARTY_NAME);
            ID.ID_FOR_SERVICE_POINT_XID(v_XML.LOCATION_NAME, FALSE, v_SERVICE_POINT_ID);

            IF v_SERVICE_POINT_ID <= 0 THEN
                -- create the service point from the MISO_CPNODES table
                BEGIN
                    SELECT NODE_NAME, NODE_TYPE
                    INTO   v_NODE_NAME, v_NODE_TYPE
                    FROM   MISO_CPNODES
                    WHERE  NODE_NAME = v_XML.LOCATION_NAME;

                    IO.PUT_SERVICE_POINT(
                        O_OID => v_SERVICE_POINT_ID,
                        p_SERVICE_POINT_NAME => v_NODE_NAME || '(MISO)',
                        p_SERVICE_POINT_ALIAS => v_NODE_NAME,
                        p_SERVICE_POINT_DESC => 'Created via MISO Portfolio query',
                        p_SERVICE_POINT_ID => 0,
                        p_SERVICE_POINT_TYPE => 'Point',
                        p_TP_ID => 0,
                        p_CA_ID => 0,
                        p_EDC_ID => 0,
                        p_ROLLUP_ID => 0,
                        p_SERVICE_REGION_ID => 0,
                        p_SERVICE_AREA_ID => 0,
                        p_SERVICE_ZONE_ID => 0,
                        p_TIME_ZONE => MM_MISO_UTIL.g_MISO_TIMEZONE,
                        p_LATITUDE => NULL,
                        p_LONGITUDE => NULL,
                        p_EXTERNAL_IDENTIFIER => v_NODE_NAME,
                        p_IS_INTERCONNECT => 0,
                        p_NODE_TYPE => v_NODE_TYPE,
                        p_SERVICE_POINT_NERC_CODE => '?',
                        p_PIPELINE_ID => NULL,
                        p_MILE_MARKER => NULL
                    );
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                        NULL;
                END;
            END IF;

            EM.PUT_PORTFOLIO_SERVICE_POINT(v_PORTFOLIO_ID, v_SERVICE_POINT_ID, 1);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_PORTFOLIO;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_DISTRIBUTION_FACTORS(
        p_CRED IN mex_credentials,
        p_REQUEST_DAY IN DATE,
        p_LOCATION_NAME IN VARCHAR2,
        p_PORTFOLIO_NAME IN VARCHAR2,
        p_LOG_ONLY IN NUMBER,
        p_STATUS OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        --Handle Query and Response for 'DistributionFactors'
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_AGG_SERVICE_POINT_ID NUMBER(9);
        v_SUB_SERVICE_POINT_ID NUMBER(9);

        CURSOR c_XML IS
            SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DAY", EXTRACTVALUE(VALUE(U), '//@location', g_MISO_NAMESPACE) "AGGREGATE_LOCATION",
                   EXTRACTVALUE(VALUE(V), '//@location', g_MISO_NAMESPACE) "BUS_LOCATION", EXTRACTVALUE(VALUE(V), '//@factor', g_MISO_NAMESPACE) "FACTOR"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE, '//DistributionFactors', g_MISO_NAMESPACE))) T, TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//AggregateNode', g_MISO_NAMESPACE))) U,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//BusNode', g_MISO_NAMESPACE))) V;
    BEGIN
		p_STATUS := GA.SUCCESS;
        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"),
                   XMLELEMENT("QueryDistributionFactors", XMLATTRIBUTES(TO_CHAR(p_REQUEST_DAY, g_DATE_FORMAT) AS "day"), XMLFOREST(p_LOCATION_NAME AS "LocationName", p_PORTFOLIO_NAME AS "PortfolioName"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from XML_TRACE WHERE key1 = 'DistributionFactors'; --DEBUG--TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);

-----------------------------------------------------------------------------------
        FOR v_XML IN c_XML LOOP
            PUT_SERVICE_POINT(v_XML.RESPONSE_DAY, v_XML.AGGREGATE_LOCATION, 'Aggregate', v_AGG_SERVICE_POINT_ID, p_STATUS, p_ERROR_MESSAGE);
            PUT_SERVICE_POINT(v_XML.RESPONSE_DAY, v_XML.BUS_LOCATION, 'Bus', v_SUB_SERVICE_POINT_ID, p_STATUS, p_ERROR_MESSAGE);
            SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
            EM.PUT_SUB_SERVICE_POINT(v_AGG_SERVICE_POINT_ID, v_SUB_SERVICE_POINT_ID, TRUNC(SYSDATE),                                                                                                                                              --BEGIN_DATE
                NULL,                                                                                                                                                                                                                               --END_DATE
                100 * v_XML.FACTOR,                                                                                                                                                                                                           --ALLOCATION_PCT
                v_SUB_SERVICE_POINT_ID, TRUNC(SYSDATE));
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_DISTRIBUTION_FACTORS;

-------------------------------------------------------------------------------------
    PROCEDURE QUERY_LOAD_FORECAST(
        p_CRED IN mex_credentials,
        p_REQUEST_DAY IN DATE,
        p_CONTROL_AREA_NAME IN VARCHAR2,
        p_HOUR IN NUMBER,
        p_LOG_ONLY IN NUMBER,
        p_STATUS OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER IN OUT mm_logger_adapter
    ) AS
        --Handle Query and Response for 'LoadForecast'
        v_XML_REQUEST XMLTYPE;
        v_XML_RESPONSE XMLTYPE;
        v_AREA_LOAD AREA_LOAD%ROWTYPE;
        v_PREV_AREA_NAME AREA.AREA_NAME%TYPE := 'INITVAL';

        CURSOR c_XML IS
            SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DAY", EXTRACTVALUE(VALUE(U), '//@name', g_MISO_NAMESPACE) "AREA_NAME", EXTRACTVALUE(VALUE(V), '//@hour', g_MISO_NAMESPACE) "RESPONSE_HOUR",
                   EXTRACTVALUE(VALUE(V), '//ForecastMW', g_MISO_NAMESPACE) "FORECAST_VAL"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE, '//LoadForecast', g_MISO_NAMESPACE))) T,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//ControlArea', g_MISO_NAMESPACE))) U,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//LoadForecastHourly', g_MISO_NAMESPACE))) V;
    BEGIN
        SELECT XMLELEMENT(
                   "QueryRequest",
                   XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"),
                   XMLELEMENT("QueryLoadForecast", XMLATTRIBUTES(TO_CHAR(p_REQUEST_DAY, g_DATE_FORMAT) AS "day"), DECODE(p_CONTROL_AREA_NAME, NULL,(XMLELEMENT("Total")),(XMLELEMENT("ControlAreaName", p_CONTROL_AREA_NAME))), XMLFOREST(p_HOUR AS "Hour"))
               )
        INTO   v_XML_REQUEST
        FROM   DUAL;

-----------------------------------------------------------------------------------
--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
--Uncomment the desired action, and comment the other one.
--select xml into v_XML_RESPONSE from XML_TRACE WHERE key1 = 'loadforecast'; --DEBUG--TEST!!!
        RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
-----------------------------------------------------------------------------------
        v_AREA_LOAD.LOAD_CODE := GA.FORECAST_SERVICE;
        v_AREA_LOAD.CASE_ID := GA.BASE_CASE_ID;
        v_AREA_LOAD.AS_OF_DATE := LOW_DATE;

        FOR v_XML IN c_XML LOOP
            --GET THE NEW AREA_ID IF IT HAS CHANGED.
            IF NOT v_PREV_AREA_NAME = v_XML.AREA_NAME THEN
                ID.ID_FOR_AREA(v_XML.AREA_NAME, TRUE, v_AREA_LOAD.AREA_ID);
                v_PREV_AREA_NAME := v_XML.AREA_NAME;
            END IF;

            v_AREA_LOAD.LOAD_DATE := v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24;
            v_AREA_LOAD.LOAD_VAL := v_XML.FORECAST_VAL;
            --SAVE THE DATA.
            CS.PUT_AREA_LOAD(v_AREA_LOAD, p_STATUS);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS := SQLCODE;
            p_ERROR_MESSAGE := SQLERRM;
    END QUERY_LOAD_FORECAST;

-------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_RESULTS
    (
    p_CONTRACT_ID IN NUMBER,
    p_XML_RESPONSE  IN XMLTYPE,
    p_STATUS        OUT NUMBER,
    p_ERROR_MESSAGE OUT VARCHAR2,
    p_LOGGER IN OUT mm_logger_adapter
    ) AS
v_SC_ID NUMBER(9);
v_COMMODITY_ID  NUMBER(9);
v_FIXED_QTY     BID_OFFER_SET.QUANTITY%TYPE;
v_PRICE_SEN_QTY BID_OFFER_SET.QUANTITY%TYPE;
v_MAX_PS_BID_QTY BID_OFFER_SET.QUANTITY%TYPE;
v_POD_ID NUMBER(9);
v_SCHEDULE_AMOUNT IT_SCHEDULE.AMOUNT%TYPE;
v_SCHEDULE_DATE DATE;
v_USE_PRICE_SENS_DEMAND NUMBER(1);
v_CONTRACT_ALIAS INTERCHANGE_CONTRACT.CONTRACT_ALIAS%TYPE;
v_TRANSACTION_ID NUMBER(9);
v_PARTY_NAME VARCHAR2(32);

	-- cursor for getting fixed and p/s demand txn ids (thanks to Josh for figuring out this one)
	CURSOR c_DEMAND_TXN_IDS IS
			SELECT MAX(CASE WHEN IS_FIRM = 1 THEN TRANSACTION_ID
					ELSE NULL
					END) FIXED_ID,
					MAX(CASE WHEN IS_FIRM = 0 THEN TRANSACTION_ID
					ELSE NULL
					END) PS_ID
			FROM INTERCHANGE_TRANSACTION A
		 WHERE A.TRANSACTION_TYPE = 'Load'
     AND A.POD_ID = v_POD_ID
			 AND A.SC_ID = v_SC_ID
			 AND A.COMMODITY_ID = v_COMMODITY_ID
			 AND A.IS_BID_OFFER = 1
			 AND A.CONTRACT_ID = p_CONTRACT_ID
		 GROUP BY POD_ID;

	CURSOR c_GEN_TXN_IDS IS
		SELECT a.transaction_id GEN_ID
			FROM interchange_transaction a
		 WHERE A.POD_ID = v_POD_ID
			 AND a.transaction_type = 'Generation'
			 AND a.sc_id = v_SC_ID
			 AND a.COMMODITY_ID = v_COMMODITY_ID
			 AND A.CONTRACT_ID = p_CONTRACT_ID
			 AND a.is_bid_offer = 1;

	CURSOR c_VIRT_TXN_IDS IS
		SELECT a.transaction_id VIRT_ID
			FROM interchange_transaction a
		 WHERE A.POD_ID = v_POD_ID
			 AND a.transaction_type IN ('Load', 'Generation')
			 AND a.sc_id = v_SC_ID
			 AND a.COMMODITY_ID = v_COMMODITY_ID
			 AND A.CONTRACT_ID = p_CONTRACT_ID
			 AND a.is_bid_offer = 1;

	CURSOR c_XML IS
		SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DAY",
					 EXTRACTVALUE(VALUE(U), '//@name', g_MISO_NAMESPACE) "LOCATION_NAME",
					 EXTRACTVALUE(VALUE(V), '//@hour', g_MISO_NAMESPACE) "RESPONSE_HOUR",
					 EXTRACTVALUE(VALUE(V), '//ClearedMW', g_MISO_NAMESPACE) "AMOUNT",
					 EXTRACTVALUE(VALUE(V), '//ClearedVirtualMW', g_MISO_NAMESPACE) "VIRTUAL_AMOUNT",
					 EXTRACTVALUE(VALUE(V), '//ClearedPrice', g_MISO_NAMESPACE) "PRICE",
					 EXTRACTVALUE(VALUE(V), '//PriceCapped', g_MISO_NAMESPACE) "PRICE_CAPPED"
			FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
																		 '//MarketResults',
																		 g_MISO_NAMESPACE))) T,
					 TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//Location', g_MISO_NAMESPACE))) U,
					 TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//HourlySchedule', g_MISO_NAMESPACE))) V;

	-- return True if txn has type Load, false otherwise
	-- log event if txn type is not Gen or Load
	FUNCTION IS_VIRTUAL_BID(p_TXN_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE) RETURN BOOLEAN IS
		v_IS_VIRTUAL_BID BOOLEAN;
		v_TXN_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
	BEGIN
		v_IS_VIRTUAL_BID := FALSE;
		SELECT UPPER(TRANSACTION_TYPE)
		INTO v_TXN_TYPE
		FROM INTERCHANGE_TRANSACTION
		WHERE TRANSACTION_ID = p_TXN_ID;

		IF v_TXN_TYPE = 'LOAD' THEN
			v_IS_VIRTUAL_BID := TRUE;
		ELSE
			IF v_TXN_TYPE NOT IN ('GENERATION', 'LOAD') THEN
				p_LOGGER.LOG_WARN('Virtual txn id ' || p_TXN_ID || ' must have type Generation or Load; check clearing results.');
			END IF;
		END IF;
		RETURN v_IS_VIRTUAL_BID;
	EXCEPTION
		WHEN OTHERS THEN
			p_LOGGER.LOG_ERROR('Failed to get Transaction Type for Virtual Txn ID=' || p_TXN_ID);
			RETURN FALSE;
	END IS_VIRTUAL_BID;
BEGIN
  p_STATUS := GA.SUCCESS;

	v_SC_ID := MM_MISO_UTIL.GET_MISO_SC_ID;

	FOR v_XML IN c_XML LOOP
		v_SCHEDULE_DATE := v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24;

		ID.ID_FOR_SERVICE_POINT_XID(v_XML.LOCATION_NAME, FALSE, v_POD_ID);

        ID.ID_FOR_COMMODITY('Virtual Energy', FALSE, v_COMMODITY_ID);
        FOR v_VIRT_TXN_ID IN c_VIRT_TXN_IDS LOOP
			-- this block of logic here makes sure we only put virtual gen (offer)
			-- in a gen transaction, and virtual load (bid) in a load transaction
			v_SCHEDULE_AMOUNT := v_XML.VIRTUAL_AMOUNT;
			IF v_SCHEDULE_AMOUNT < 0 THEN
				IF IS_VIRTUAL_BID(v_VIRT_TXN_ID.VIRT_ID) THEN
					v_SCHEDULE_AMOUNT := 0;
				END IF;
			ELSE
				IF NOT IS_VIRTUAL_BID(v_VIRT_TXN_ID.VIRT_ID) THEN
					v_SCHEDULE_AMOUNT := 0;
				END IF;
			END IF;
			MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_VIRT_TXN_ID.Virt_Id,
												v_SCHEDULE_DATE,
												GA.INTERNAL_STATE,
												v_XML.PRICE,
												ABS(v_SCHEDULE_AMOUNT),
												p_STATUS,
												p_ERROR_MESSAGE);
		END LOOP;

		ID.ID_FOR_COMMODITY('DayAhead Energy', FALSE, v_COMMODITY_ID);
		FOR v_GEN_TXN_ID IN c_GEN_TXN_IDS LOOP
			MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_GEN_TXN_ID.Gen_Id,
												v_SCHEDULE_DATE,
												GA.INTERNAL_STATE,
												v_XML.PRICE,
												-v_XML.AMOUNT,
												p_STATUS,
												p_ERROR_MESSAGE);
		END LOOP;

		--Use a System Dictionary Flag to tell whether or not to ignore Price-Sens Demand Bids.
        v_USE_PRICE_SENS_DEMAND := NVL(GET_DICTIONARY_VALUE('Use Price-Sensitive Demand Bids', 0, 'MarketExchange', 'MISO'),0);
        IF v_USE_PRICE_SENS_DEMAND = 0 THEN
            SELECT CONTRACT_ALIAS INTO v_CONTRACT_ALIAS FROM INTERCHANGE_CONTRACT WHERE CONTRACT_ID = p_CONTRACT_ID;
            v_PARTY_NAME := SUBSTR(v_CONTRACT_ALIAS,1,INSTR(v_CONTRACT_ALIAS, ':') - 1);
            GET_BID_TRANSACTION_ID('DEMAND', 'Load', v_XML.LOCATION_NAME, v_XML.RESPONSE_DAY, g_DAYAHEAD, 'Energy', 0, 1, 'Hour',
                             v_PARTY_NAME, v_TRANSACTION_ID, p_ERROR_MESSAGE);
            IF v_TRANSACTION_ID IS NOT NULL THEN
				    MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_TRANSACTION_ID,
													v_SCHEDULE_DATE,
													GA.INTERNAL_STATE,
													v_XML.PRICE,
													v_XML.AMOUNT,
													p_STATUS,
													p_ERROR_MESSAGE);
            END IF;
        ELSE

		FOR v_DEMAND_TXN_ID IN c_DEMAND_TXN_IDS LOOP

			-- if demand then break up the total quantity from the XML into fixed
			-- and price-sensitive portions
			BEGIN
				-- Get the fixed demand quantity
				IF v_DEMAND_TXN_ID.FIXED_ID IS NOT NULL THEN
					SELECT B.QUANTITY
						INTO v_FIXED_QTY
						FROM BID_OFFER_SET B
					 WHERE B.TRANSACTION_ID = v_DEMAND_TXN_ID.Fixed_Id
						 AND B.SET_NUMBER = 1
						 AND B.SCHEDULE_STATE = GA.INTERNAL_STATE
						 AND B.SCHEDULE_DATE = v_SCHEDULE_DATE;
				ELSE
					v_FIXED_QTY := 0;
				END IF;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_FIXED_QTY := 0;
			END;

			IF v_XML.AMOUNT > v_FIXED_QTY THEN
        -- there's leftover stuff for the price-sensitive portion of the bid
        v_PRICE_SEN_QTY := v_XML.AMOUNT - v_FIXED_QTY;
			ELSE
        -- there's an assumption here that if anything clears,
        -- it will be at least the amount of the fixed demand bid.
				v_FIXED_QTY     := v_XML.AMOUNT;
				v_PRICE_SEN_QTY := 0;
			END IF;

			IF v_DEMAND_TXN_ID.FIXED_ID IS NOT NULL THEN
				MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_DEMAND_TXN_ID.FIXED_ID,
																					v_SCHEDULE_DATE,
																					GA.INTERNAL_STATE,
																					v_XML.PRICE,
																					v_FIXED_QTY,
																					p_STATUS,
																					p_ERROR_MESSAGE);
			END IF;

			IF v_DEMAND_TXN_ID.PS_ID IS NOT NULL THEN
				-- post an alarm if the cleared price-sensitive demand is greater than zero
				-- but less than the maximum price-sensitive bid
				IF v_PRICE_SEN_QTY > 0 THEN
    				v_MAX_PS_BID_QTY := MM_UTIL.GET_MAX_PS_DEMAND(v_DEMAND_TXN_ID.PS_ID, v_SCHEDULE_DATE);
    				IF v_MAX_PS_BID_QTY > v_PRICE_SEN_QTY THEN
    					MM_UTIL.POST_PART_CLEARED_DEMAND_ALERT(v_DEMAND_TXN_ID.PS_ID, v_MAX_PS_BID_QTY, v_PRICE_SEN_QTY, 'MISO');
    				END IF;
				END IF;
				MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_DEMAND_TXN_ID.PS_ID,
																					v_SCHEDULE_DATE,
																					GA.INTERNAL_STATE,
																					v_XML.PRICE,
																					v_PRICE_SEN_QTY,
																					p_STATUS,
																					p_ERROR_MESSAGE);
			END IF;

		END LOOP;
	END IF;

	END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS        := SQLCODE;
		p_ERROR_MESSAGE := 'MM_MISO.PUT_MARKET_RESULTS: ' || SQLERRM;
END PUT_MARKET_RESULTS;
-------------------------------------------------------------------------------------
PROCEDURE QUERY_MARKET_RESULTS(p_CRED      IN mex_credentials,
															 p_BEGIN_DATE    IN DATE,
															 p_END_DATE      IN DATE,
															 p_LOG_ONLY      IN NUMBER,
															 p_STATUS        OUT NUMBER,
															 p_ERROR_MESSAGE OUT VARCHAR2,
															 p_LOGGER IN OUT mm_logger_adapter) AS
	--Handle Query and Response for 'MarketResults'
	v_XML_REQUEST        XMLTYPE;
	v_XML_RESPONSE       XMLTYPE;
	v_CONTRACT_ID   NUMBER(9);
  v_PARTIES GA.STRING_TABLE;
  v_INTERVAL NUMBER(2);
v_PARTY_NAME VARCHAR2(32);
BEGIN
  p_STATUS := GA.SUCCESS;

  GET_PARTIES_FOR_ISO_ACCOUNT(p_CRED.EXTERNAL_ACCOUNT_NAME, v_PARTIES);
  v_CONTRACT_ID := GET_CONTRACT_ID_FOR_PARTY(v_PARTIES(v_PARTIES.FIRST));
  v_INTERVAL := GET_INTERVAL_NUMBER('HH');
  v_PARTY_NAME := v_PARTIES(v_PARTIES.FIRST);
	--GENERATE THE REQUEST XML.
	SELECT XMLELEMENT("QueryRequest",
										XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns", v_PARTY_NAME AS "party"),
										XMLAGG(XMLELEMENT("QueryMarketResults",
																			XMLATTRIBUTES(TO_CHAR(T.LOCAL_DATE,
																														g_DATE_FORMAT) AS "day"),
																			XMLFOREST(S.EXTERNAL_IDENTIFIER AS
																								"LocationName"))))
		INTO v_XML_REQUEST
		FROM SYSTEM_DATE_TIME        T,
				 SERVICE_POINT           S,
				 MISO_CPNODES            M,
				 INTERCHANGE_TRANSACTION TXN
	 WHERE TXN.TRANSACTION_TYPE IN ('Generation', 'Load')
		 AND TXN.IS_BID_OFFER = 1
		 AND TXN.COMMODITY_ID IN
				 (SELECT COMMODITY_ID
						FROM IT_COMMODITY
					 WHERE COMMODITY_NAME IN ('DayAhead Energy', 'Virtual Energy'))
		 AND TXN.POD_ID = S.SERVICE_POINT_ID
     AND TXN.CONTRACT_ID = v_CONTRACT_ID
		 AND S.EXTERNAL_IDENTIFIER = M.NODE_NAME
		 AND T.TIME_ZONE = MM_MISO_UTIL.g_MISO_TIMEZONE
		 AND T.DATA_INTERVAL_TYPE = 1
		 AND T.DAY_TYPE = 1
		 AND T.LOCAL_DATE BETWEEN TRUNC(p_BEGIN_DATE, 'DD') AND TRUNC(p_END_DATE, 'DD')
		 AND T.LOCAL_DATE = TRUNC(T.LOCAL_DATE, 'DD')
		 AND T.MINIMUM_INTERVAL_NUMBER >= v_INTERVAL
	 ORDER BY S.EXTERNAL_IDENTIFIER, T.LOCAL_DATE;

	-----------------------------------------------------------------------------------
	--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
	--Uncomment the desired action, and comment the other one.
	--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'MarketResults';
	RUN_MISO_QUERY(p_CRED,
								 p_LOG_ONLY,
								 v_XML_REQUEST,
								 v_XML_RESPONSE,
								 p_ERROR_MESSAGE,
								 p_LOGGER);

	-----------------------------------------------------------------------------------
  IF p_ERROR_MESSAGE IS NULL THEN
    PUT_MARKET_RESULTS(v_CONTRACT_ID, v_XML_RESPONSE, p_STATUS, p_ERROR_MESSAGE, p_LOGGER);
  END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS        := SQLCODE;
		p_ERROR_MESSAGE := SQLERRM;
END QUERY_MARKET_RESULTS;

----------------------------------------------------------------------------------------------------------------
PROCEDURE QUERY_RT_INT_LMP_ALL_LOC
    (
    p_CRED  IN MEX_CREDENTIALS,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
    p_ERROR_MESSAGE OUT VARCHAR2,
    p_LOGGER IN OUT MM_LOGGER_ADAPTER
    ) AS

v_XML_REQUEST        XMLTYPE;
v_XML_RESPONSE       XMLTYPE;
v_INTERVAL NUMBER(2);
v_RESPONSE_NAME VARCHAR2(32) := 'RealTimeIntegratedLMP';
v_MARKET_PRICE_INTERVAL VARCHAR2(4) := 'Hour';

 CURSOR c_XML IS
            SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DAY", EXTRACTVALUE(VALUE(U), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", EXTRACTVALUE(VALUE(V), '//@hour', g_MISO_NAMESPACE) "RESPONSE_HOUR",
                   EXTRACTVALUE(VALUE(V), '//LMP', g_MISO_NAMESPACE) "LMP", EXTRACTVALUE(VALUE(V), '//MCC', g_MISO_NAMESPACE) "MCC", EXTRACTVALUE(VALUE(V), '//MLC', g_MISO_NAMESPACE) "MLC"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE, '//' || v_RESPONSE_NAME, g_MISO_NAMESPACE))) T,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//PricingNode', g_MISO_NAMESPACE))) U,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//PricingNodeHourly', g_MISO_NAMESPACE))) V;
BEGIN
    p_STATUS := GA.SUCCESS;
    v_INTERVAL := GET_INTERVAL_NUMBER('HH');

	--GENERATE THE REQUEST XML.
	SELECT   XMLELEMENT("QueryRequest", XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"),
                         XMLAGG(XMLELEMENT("QueryRealTimeIntegratedLMP", XMLATTRIBUTES(TO_CHAR(T.LOCAL_DATE, 'YYYY-MM-DD') AS "day"), XMLFOREST(S.EXTERNAL_IDENTIFIER AS "LocationName"))))
            INTO     v_XML_REQUEST
            FROM     SYSTEM_DATE_TIME T, SERVICE_POINT S, MISO_CPNODES M
            WHERE    S.EXTERNAL_IDENTIFIER = M.NODE_NAME
            AND      T.TIME_ZONE = MM_MISO_UTIL.g_MISO_TIMEZONE
            AND      T.DATA_INTERVAL_TYPE = 1
            AND      T.DAY_TYPE = 1
            AND      T.LOCAL_DATE BETWEEN TRUNC(p_BEGIN_DATE, 'DD') AND TRUNC(p_END_DATE, 'DD')
            AND      T.LOCAL_DATE = TRUNC(T.LOCAL_DATE, 'DD')
			AND      T.MINIMUM_INTERVAL_NUMBER >= v_INTERVAL
            ORDER BY S.EXTERNAL_IDENTIFIER, T.LOCAL_DATE;

	--Submit the QueryRequest to MISO
	RUN_MISO_QUERY(p_CRED,
    				 p_LOG_ONLY,
    				 v_XML_REQUEST,
    				 v_XML_RESPONSE,
    				 p_ERROR_MESSAGE,
    				 p_LOGGER);

    FOR v_XML IN c_XML LOOP
        --PUT LMP COMPONENT.
        MM_MISO_LMP.PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24, v_XML.LOCATION_NAME, g_LMP_PRICE_TYPE, g_LMP_PRICE_ABBR, g_REALTIME, v_MARKET_PRICE_INTERVAL, v_XML.LMP, p_ERROR_MESSAGE);

        --PUT MLC COMPONENT.
        MM_MISO_LMP.PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24, v_XML.LOCATION_NAME, g_MLC_PRICE_TYPE, g_MLC_PRICE_ABBR, g_REALTIME, v_MARKET_PRICE_INTERVAL, v_XML.MLC, p_ERROR_MESSAGE);

        --PUT MCC COMPONENT.
        MM_MISO_LMP.PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24, v_XML.LOCATION_NAME, g_MCC_PRICE_TYPE, g_MCC_PRICE_ABBR, g_REALTIME, v_MARKET_PRICE_INTERVAL, v_XML.MCC, p_ERROR_MESSAGE);
    END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS        := SQLCODE;
		p_ERROR_MESSAGE := SQLERRM;
END QUERY_RT_INT_LMP_ALL_LOC;
------------------------------------------------------------------------------------------------------------------------
PROCEDURE QUERY_5_MIN_RT_LMP
    (
    p_CRED  IN MEX_CREDENTIALS,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
    p_ERROR_MESSAGE OUT VARCHAR2,
    p_LOGGER IN OUT MM_LOGGER_ADAPTER
    ) AS

v_XML_REQUEST        XMLTYPE;
v_XML_RESPONSE       XMLTYPE;
v_INTERVAL NUMBER(2);
v_MARKET_PRICE_INTERVAL VARCHAR2(16) := '5 Minute';

CURSOR c_XML IS
	SELECT
		TO_DATE(EXTRACTVALUE(VALUE(T),'//@day', g_MISO_NAMESPACE),g_DATE_FORMAT) "RESPONSE_DAY",
		EXTRACTVALUE(VALUE(U),'//@location', g_MISO_NAMESPACE) "LOCATION_NAME",
		TO_DATE(EXTRACTVALUE(VALUE(V),'//@interval', g_MISO_NAMESPACE),g_DATE_TIME_ZONE_FORMAT) "RESPONSE_INTERVAL",
		EXTRACTVALUE(VALUE(V),'//LMP', g_MISO_NAMESPACE) "LMP",
		EXTRACTVALUE(VALUE(V),'//MCC', g_MISO_NAMESPACE) "MCC",
		EXTRACTVALUE(VALUE(V),'//MLC', g_MISO_NAMESPACE) "MLC"
	FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE,'//RealTimeLMP', g_MISO_NAMESPACE))) T,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),'//PricingNode', g_MISO_NAMESPACE))) U,
		TABLE(XMLSEQUENCE(EXTRACT(VALUE(U),'//PricingNodeInterval', g_MISO_NAMESPACE))) V;
BEGIN
    p_STATUS := GA.SUCCESS;
    v_INTERVAL := GET_INTERVAL_NUMBER('MI5');

	--GENERATE THE REQUEST XML.
	SELECT   XMLELEMENT("QueryRequest", XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"),
    	XMLAGG(XMLELEMENT("QueryRealTimeLMP", XMLATTRIBUTES(TO_CHAR(T.LOCAL_DATE, g_DATE_TIME_FORMAT) AS "interval"),
    	XMLFOREST(S.EXTERNAL_IDENTIFIER AS "LocationName"))))
    INTO v_XML_REQUEST
    FROM     SYSTEM_DATE_TIME T, SERVICE_POINT S, MISO_CPNODES M, MISO_5MIN_LMP_POINTS L
    WHERE    S.SERVICE_POINT_ID = L.SERVICE_POINT_ID
    AND      S.EXTERNAL_IDENTIFIER = M.NODE_NAME
    AND      T.TIME_ZONE = MM_MISO_UTIL.g_MISO_TIMEZONE
    AND      T.DATA_INTERVAL_TYPE = 1
    AND      T.DAY_TYPE = 1
    AND      T.LOCAL_DATE BETWEEN p_BEGIN_DATE AND p_END_DATE
    AND      T.MINIMUM_INTERVAL_NUMBER >= v_INTERVAL
    ORDER BY S.EXTERNAL_IDENTIFIER, T.LOCAL_DATE;

	--Submit the QueryRequest to MISO
	RUN_MISO_QUERY(p_CRED,
    				 p_LOG_ONLY,
    				 v_XML_REQUEST,
    				 v_XML_RESPONSE,
    				 p_ERROR_MESSAGE,
    				 p_LOGGER);

    FOR v_XML IN c_XML LOOP
        --PUT LMP COMPONENT.
        MM_MISO_LMP.PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_INTERVAL, v_XML.LOCATION_NAME, g_LMP_PRICE_TYPE, g_LMP_PRICE_ABBR, g_REALTIME, v_MARKET_PRICE_INTERVAL, v_XML.LMP, p_ERROR_MESSAGE);

        --PUT MLC COMPONENT.
        MM_MISO_LMP.PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_INTERVAL, v_XML.LOCATION_NAME, g_MLC_PRICE_TYPE, g_MLC_PRICE_ABBR, g_REALTIME, v_MARKET_PRICE_INTERVAL, v_XML.MLC, p_ERROR_MESSAGE);

        --PUT MCC COMPONENT.
        MM_MISO_LMP.PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_INTERVAL, v_XML.LOCATION_NAME, g_MCC_PRICE_TYPE, g_MCC_PRICE_ABBR, g_REALTIME, v_MARKET_PRICE_INTERVAL, p_STATUS, p_ERROR_MESSAGE);
    END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS        := SQLCODE;
		p_ERROR_MESSAGE := SQLERRM;
END QUERY_5_MIN_RT_LMP;
------------------------------------------------------------------------------------------------------------------------
PROCEDURE UPLOAD_METER_DATA(p_CRED      IN mex_credentials,
							p_SERVICE_POINT_ID IN NUMBER,
							p_START_DATE       IN DATE,
							p_END_DATE         IN DATE,
							p_LOG_ONLY		   IN BINARY_INTEGER :=0,
							p_STATUS           OUT NUMBER,
							p_MESSAGE          OUT VARCHAR2,
							p_LOGGER	IN OUT mm_logger_adapter) AS

	v_XML_REQUEST  XMLTYPE;
	v_XML_RESPONSE XMLTYPE;

	v_RECORDER   SERVICE_POINT.EXTERNAL_IDENTIFIER%TYPE;
	v_SPI CONSTANT VARCHAR2(4) := '3600';
	v_UOM CONSTANT VARCHAR2(2) := '44';
	v_INTERVAL      NUMBER(2);

BEGIN

	p_STATUS := GA.SUCCESS;

	/*v_START_DATE := TRUNC(p_START_DATE);
    v_END_DATE   := TRUNC(p_END_DATE);*/
	v_INTERVAL := GET_INTERVAL_NUMBER('HH');

	SELECT T.EXTERNAL_IDENTIFIER
	  INTO v_RECORDER
	  FROM SERVICE_POINT T
	 WHERE T.SERVICE_POINT_ID = p_SERVICE_POINT_ID;

		--GET ALL METERS THAT BELONG TO THE SELECTED SERVICE_POINT
		--ROLL UP THE METER DATA; SUBMIT ONLY THE 'ACTUAL' METER TYPE
		SELECT XMLELEMENT("INTERVAL_DATA",
						  XMLELEMENT("CUT",
									 XMLELEMENT("RECORDER",v_RECORDER),
									 XMLELEMENT("STARTTIME",TO_CHAR(p_START_DATE,g_DATE_TIME_FORMAT)),
									 XMLELEMENT("STOPTIME", TO_CHAR(p_END_DATE, g_DATE_TIME_FORMAT)),
									 XMLELEMENT("SPI", v_SPI),
									 XMLELEMENT("UOM", v_UOM),
									 XMLELEMENT("INTERVAL",
												XMLAGG(XMLELEMENT("RECORDING",
																  XMLELEMENT("VALUE",
																			 NVL(SUM(MPV.METER_VAL*A.MULT),
																				 0)))))))
		  INTO v_XML_REQUEST
		  FROM (SELECT MP.METER_POINT_ID, MPS.MEASUREMENT_SOURCE_ID,
					CONSTANTS.CODE_ACTUAL as METER_CODE,
					SDT.CUT_DATE as METER_DATE,
					CASE MP.OPERATION_CODE
						WHEN 'A' THEN 1
						WHEN 'S' THEN -1
						ELSE 0
						END as MULT
		  		FROM SYSTEM_DATE_TIME SDT,
					TX_SUB_STATION_METER M,
					TX_SUB_STATION_METER_OWNER MO,
					INTERCHANGE_CONTRACT IC,
					EXTERNAL_SYSTEM_IDENTIFIER ESI,
					TX_SUB_STATION_METER_POINT MP,
					TX_SUB_STATION_METER_PT_SOURCE MPS
				 WHERE SDT.TIME_ZONE = g_TIME_ZONE
				   AND SDT.DATA_INTERVAL_TYPE = 1
				   AND SDT.DAY_TYPE = '1'
				   AND SDT.CUT_DATE BETWEEN p_START_DATE AND p_END_DATE
				   AND SDT.MINIMUM_INTERVAL_NUMBER >= v_INTERVAL
				   AND M.SERVICE_POINT_ID = p_SERVICE_POINT_ID
				   -- get meter owner - it should be the bill entity for this ISO account contract
				   AND MO.METER_ID = M.METER_ID
				   AND TRUNC(SDT.LOCAL_DATE-1/86400) BETWEEN MO.BEGIN_DATE AND NVL(MO.END_DATE, CONSTANTS.HIGH_DATE)
				   AND IC.BILLING_ENTITY_ID = MO.OWNER_ID
				   AND ESI.EXTERNAL_SYSTEM_ID = EC.ES_MISO
				   AND ESI.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT
				   AND ESI.ENTITY_ID = IC.CONTRACT_ID
				   AND ESI.IDENTIFIER_TYPE = EI.g_DEFAULT_IDENTIFIER_TYPE
				   AND ESI.EXTERNAL_IDENTIFIER = p_CRED.EXTERNAL_ACCOUNT_NAME
				   -- now find the right source for each meter data point
				   AND MP.SUB_STATION_METER_ID = M.METER_ID
				   AND MPS.METER_POINT_ID = MP.METER_POINT_ID
				   AND TRUNC(SDT.LOCAL_DATE-1/86400) BETWEEN MPS.BEGIN_DATE AND NVL(MPS.END_DATE, CONSTANTS.HIGH_DATE)
				   AND MPS.IS_PRIMARY = 1) A,
		  		TX_SUB_STATION_METER_PT_VALUE MPV
		   -- now get the interval data
		WHERE MPV.METER_POINT_ID(+) = A.METER_POINT_ID
		   AND MPV.MEASUREMENT_SOURCE_ID(+) = A.MEASUREMENT_SOURCE_ID
		   AND MPV.METER_CODE(+) = A.METER_CODE
		   AND MPV.METER_DATE(+) = A.METER_DATE
		 GROUP BY TO_CHAR(A.METER_DATE, 'HH24');



	--SUBMIT THE XML
	-----------------------------------------------------------------------------------
	--Either Submit the QueryRequest to MISO, or debug with a select from XML_TRACE.
	--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'Upload Meter Data';   --TEST!!!

	--Submit the xml to MISO
	RUN_MISO_ACTION(p_CRED,
	                'meter',
					v_XML_REQUEST,
					p_LOG_ONLY,
					v_XML_RESPONSE,
					p_MESSAGE,
					p_LOGGER);

	COMMIT;

	-----------------------------------------------------------------------------------
	/*IF NOT v_XML_RESPONSE IS NULL THEN
        --parse the response that is received through the programmatic interface

    END IF;*/

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MM_MISO.UPLOAD_METER_DATA: ' || SQLERRM;

END UPLOAD_METER_DATA;
--------------------------------------------------------------------------------------------
PROCEDURE MARKET_IMPORT_CLOB
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR,
	p_FILE_PATH IN VARCHAR2,
	p_IMPORT_FILE IN OUT NOCOPY CLOB,
	p_LOG_TYPE IN NUMBER,
	p_TRACE_ON IN NUMBER,
	p_LOG_ONLY IN BINARY_INTEGER := 0,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR
    ) AS

	v_XML XMLTYPE := XMLTYPE.CREATEXML(p_IMPORT_FILE);
	v_CRED MEX_CREDENTIALS;
	v_LOGGER MM_LOGGER_ADAPTER;
BEGIN
	p_STATUS := GA.SUCCESS;

	MM_UTIL.INIT_MEX(EC.ES_MISO, NULL, 'MISO File Import', p_EXCHANGE_TYPE, p_LOG_TYPE, p_TRACE_ON, v_CRED, v_LOGGER);
	MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('MM_MISO.MARKET_IMPORT TYPE=' || p_EXCHANGE_TYPE);
	END IF;

	IF NOT v_XML IS NULL THEN
		CASE p_EXCHANGE_TYPE
			WHEN g_ET_DA_SETTLEMENT_STATEMENT THEN
				MM_MISO_SETTLEMENT.PUT_SETTLEMENT_STATEMENT(g_DEFAULT_ISO_ACCT_NAME, 'DA_STLMT', 'DA', v_XML, p_TRACE_ON, p_MESSAGE);
			WHEN g_ET_RT_SETTLEMENT_STATEMENT THEN
				MM_MISO_SETTLEMENT.PUT_SETTLEMENT_STATEMENT(g_DEFAULT_ISO_ACCT_NAME, 'RT_STLMT', 'RT', v_XML, p_TRACE_ON, p_MESSAGE);
			WHEN g_ET_FTR_SETTLEMENT_STATEMENT THEN
				MM_MISO_SETTLEMENT.PUT_SETTLEMENT_STATEMENT(g_DEFAULT_ISO_ACCT_NAME, 'FTR_STLMT', 'FTR', v_XML, p_TRACE_ON, p_MESSAGE);
			WHEN g_ET_DIRECT_SUBMIT THEN
				RUN_MISO_SUBMIT_FROM_FILE(v_CRED, v_XML, p_LOG_ONLY, p_MESSAGE, v_LOGGER);
			WHEN g_ET_DIRECT_QUERY THEN
				RUN_MISO_QUERY_FROM_FILE(v_CRED, v_XML, p_LOG_ONLY, p_MESSAGE, v_LOGGER);
			WHEN MM_MISO_FTR.g_ET_IMPORT_AUCTION_RESULTS THEN
				MM_MISO_FTR.PUT_FTR_AUCTION_RESULTS(v_XML, p_BEGIN_DATE, p_STATUS, p_MESSAGE);
			WHEN MM_MISO_FTR.g_ET_IMPORT_EXISTING_FTRS THEN
				MM_MISO_FTR.PUT_EXISTING_FTRS(v_XML, p_STATUS, p_MESSAGE);
			ELSE
				p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found';
		END CASE;
	END IF;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
        p_STATUS := SQLCODE;
        p_MESSAGE := SQLERRM;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_IMPORT_CLOB;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE_ENTITY_LIST
	(
	p_EXCHANGE_TYPE IN VARCHAR,
	p_ENTITY_LABEL OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT REF_CURSOR
	) AS
        --THIS CURSOR SHOULD RETURN DATA IN EITHER NAME, ID FORMAT OR JUST NAME FORMAT. --IF NAME AND ID ARE USED, NAME MUST COME BEFORE ID. --FOR EXAMPLE, THE FOLLOWING TWO SELECT STATEMENTS WOULD BE VALID.
        --SELECT PSE_NAME, PSE_ID FROM PURCHASING_SELLING_ENTITY; --SELECT PSE_NAME FROM PURCHASING_SELLING_ENTITY; --THE FIRST ONE WILL RETURN A LIST OF IDS TO DATA_EXCHANGE, AND THE SECOND WILL RETURN A LIST OF NAMES.

        --YOU MUST GIVE A VALUE FOR THE p_ENTITY_LABEL PARAMETER.  IT IS WHAT --IS DISPLAYED ON TOP OF THE LIST ON THE DIALOG. BEGIN
        v_EXCHANGE_TYPE VARCHAR2(64) := p_EXCHANGE_TYPE;
        v_SC_ID NUMBER(9) := MM_MISO_UTIL.GET_MISO_SC_ID;
    BEGIN
        p_STATUS := GA.SUCCESS;

        IF v_EXCHANGE_TYPE IN (g_ET_CONFIRM_FIN_CONTRACT, g_ET_REJECT_FIN_CONTRACT) THEN
            p_ENTITY_LABEL := 'Financial Contracts';

            OPEN p_CURSOR FOR
                SELECT   TRANSACTION_NAME, A.TRANSACTION_ID
                FROM     INTERCHANGE_TRANSACTION A, IT_COMMODITY B, IT_STATUS C
                WHERE    A.TRANSACTION_ID > 0
                AND      TRANSACTION_TYPE IN('Purchase', 'Sale')
                AND      B.COMMODITY_TYPE = 'Energy'
                AND      B.COMMODITY_ID = A.COMMODITY_ID
                AND      C.TRANSACTION_STATUS_NAME = MM_UTIL.g_BILAT_REQUIRES_APPROVAL
                AND      A.TRANSACTION_ID = C.TRANSACTION_ID
                AND      A.SC_ID = v_SC_ID
                ORDER BY 1;
        ELSIF v_EXCHANGE_TYPE IN(g_ET_CONFIRM_FIN_SCHEDULE, g_ET_REJECT_FIN_SCHEDULE, g_ET_SUBMIT_FIN_CONTRACT) THEN
            --, 'QueryFinSchedules') THEN
            p_ENTITY_LABEL := 'Financial Contracts';

            OPEN p_CURSOR FOR
                SELECT   TRANSACTION_NAME, A.TRANSACTION_ID
                FROM     INTERCHANGE_TRANSACTION A, IT_COMMODITY B
                WHERE    A.TRANSACTION_ID > 0 AND A.TRANSACTION_TYPE IN('Purchase', 'Sale') AND B.COMMODITY_TYPE = 'Energy' AND B.COMMODITY_ID = A.COMMODITY_ID AND A.SC_ID = v_SC_ID
                ORDER BY 1;
        ELSIF v_EXCHANGE_TYPE IN(g_ET_SUBMIT_FTR_BID_PROFILE) THEN
            p_ENTITY_LABEL := 'FTR Transactions';

            OPEN p_CURSOR FOR
                SELECT   TRANSACTION_NAME, A.TRANSACTION_ID
                FROM     INTERCHANGE_TRANSACTION A, IT_COMMODITY B
                WHERE    TRANSACTION_ID > 0 AND B.COMMODITY_TYPE = 'Transmission' AND B.COMMODITY_ID = A.COMMODITY_ID
                ORDER BY 1;
        ELSIF SUBSTR(v_EXCHANGE_TYPE, -9) = 'Portfolio' THEN
            p_ENTITY_LABEL := 'Portfolios';

            OPEN p_CURSOR FOR
                SELECT   PORTFOLIO_NAME, PORTFOLIO_ID
                FROM     PORTFOLIO
                WHERE    PORTFOLIO_ID > 0
                ORDER BY 1;
        ELSIF SUBSTR(v_EXCHANGE_TYPE, -11) = 'By Location' OR v_EXCHANGE_TYPE = g_ET_UPLOAD_METER_DATA THEN
            p_ENTITY_LABEL := 'Service Points';

            OPEN p_CURSOR FOR
                SELECT   SERVICE_POINT_NAME, SERVICE_POINT_ID
                FROM     SERVICE_POINT
                WHERE    SERVICE_POINT_ID > 0
                ORDER BY 1;
        ELSIF v_EXCHANGE_TYPE = g_ET_SUBMIT_WEATHER_FORECAST THEN
            p_ENTITY_LABEL := 'Weather Stations';

            OPEN p_CURSOR FOR
                SELECT   STATION_NAME, STATION_ID
                FROM     WEATHER_STATION
                WHERE    STATION_ID > 0
                ORDER BY 1;
        ELSIF v_EXCHANGE_TYPE = g_ET_QRY_LOAD_FORECAST THEN
            p_ENTITY_LABEL := 'Control Areas';

            OPEN p_CURSOR FOR
                SELECT   AREA_NAME, AREA_ID
                FROM     AREA
                WHERE    AREA_ID > 0
                ORDER BY 1;
        ELSE
            OPEN p_CURSOR FOR
                SELECT NULL
                FROM   DUAL;
        END IF;
    END MARKET_EXCHANGE_ENTITY_LIST;
----------------------------------------------------------------------------------------------------
    FUNCTION GET_ENTITY_TYPE_FOR_ACTION(
        p_ACTION IN VARCHAR2
    )
        RETURN VARCHAR2 IS
	BEGIN
		CASE
			WHEN SUBSTR(p_ACTION, -12) = 'By Portfolio' THEN
				RETURN g_ENTITY_TYPE_PORTFOLIO;
			WHEN SUBSTR(p_ACTION, -11) = 'By Location' THEN
				RETURN g_ENTITY_TYPE_SERVICE_POINT;
			WHEN p_ACTION = g_ET_SUBMIT_WEATHER_FORECAST THEN
				RETURN g_ENTITY_TYPE_WEATHER_STATION;
			WHEN p_ACTION = g_ET_QRY_LOAD_FORECAST THEN
				RETURN g_ENTITY_TYPE_AREA;
			WHEN p_ACTION = g_ET_UPLOAD_METER_DATA THEN
				RETURN g_ENTITY_TYPE_SUBSTATION_METER;
			ELSE
				RETURN g_ENTITY_TYPE_TRANSACTION;
        END CASE;
    END GET_ENTITY_TYPE_FOR_ACTION;
---------------------------------------------------------------------------------
    PROCEDURE REQUIRE_FIN_CONFIRMATION(
        p_ISO_ACCOUNT_NAME IN VARCHAR2,
        p_XML IN XMLTYPE,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        CURSOR c_CONTRACTS IS
            SELECT EXTRACTVALUE(VALUE(T), '//@name', g_MISO_NAMESPACE) "CONTRACT_NAME", EXTRACTVALUE(VALUE(T), '//@buyer', g_MISO_NAMESPACE) "BUYER_NAME", EXTRACTVALUE(VALUE(T), '//@seller', g_MISO_NAMESPACE) "SELLER_NAME",
                   EXTRACTVALUE(VALUE(T), '//@type', g_MISO_NAMESPACE) "AGREEMENT_TYPE"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//RequireFinConfirmations/RequireForContract', g_MISO_NAMESPACE))) T;

        CURSOR c_SCHEDULES IS
            SELECT EXTRACTVALUE(VALUE(T), '//@name', g_MISO_NAMESPACE) "CONTRACT_NAME", EXTRACTVALUE(VALUE(T), '//@buyer', g_MISO_NAMESPACE) "BUYER_NAME", EXTRACTVALUE(VALUE(T), '//@seller', g_MISO_NAMESPACE) "SELLER_NAME",
                   TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "SCHEDULE_DAY", EXTRACTVALUE(VALUE(T), '//@type', g_MISO_NAMESPACE) "AGREEMENT_TYPE"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//RequireFinConfirmations/RequireForSchedule', g_MISO_NAMESPACE))) T;

        v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
        v_AS_OF_DATE DATE := LOW_DATE;
        v_SCHEDULE_STATE NUMBER(1) := GA.INTERNAL_STATE;
        v_HOUR NUMBER(2);
        v_PARTIES GA.STRING_TABLE;
        v_IDX BINARY_INTEGER;
    BEGIN
        GET_PARTIES_FOR_ISO_ACCOUNT(p_ISO_ACCOUNT_NAME, v_PARTIES);
        v_IDX := v_PARTIES.FIRST;

        -- loop through all parties
        WHILE v_PARTIES.EXISTS(v_IDX) LOOP
            FOR v_CONTRACTS IN c_CONTRACTS LOOP
                GET_FIN_CONTRACT_TRANSACTION(v_PARTIES(v_IDX), v_CONTRACTS.CONTRACT_NAME, v_SCHEDULE_STATE, FALSE, v_TRANSACTION, p_ERROR_MESSAGE);

                -- couldn't find it for this party? then it must be for another party
                IF p_ERROR_MESSAGE IS NULL THEN
                    UPDATE IT_STATUS
                    SET TRANSACTION_STATUS_NAME = MM_UTIL.g_BILAT_REQUIRES_APPROVAL
                    WHERE  TRANSACTION_ID = v_TRANSACTION.TRANSACTION_ID AND AS_OF_DATE = v_AS_OF_DATE;
                END IF;
            END LOOP;

            FOR v_SCHEDULES IN c_SCHEDULES LOOP
                GET_FIN_CONTRACT_TRANSACTION(v_PARTIES(v_IDX), v_SCHEDULES.CONTRACT_NAME, v_SCHEDULE_STATE, FALSE, v_TRANSACTION, p_ERROR_MESSAGE);

                -- couldn't find it for this party? then it must be for another party
                IF p_ERROR_MESSAGE IS NULL THEN
                    FOR v_HOUR IN 1 .. 24 LOOP
                        UPDATE BID_OFFER_STATUS
                        SET MARKET_STATUS = MM_UTIL.g_BILAT_REQUIRES_APPROVAL
                        WHERE TRANSACTION_ID = v_TRANSACTION.TRANSACTION_ID AND SCHEDULE_DATE = v_SCHEDULES.SCHEDULE_DAY + v_HOUR / 24;
                    END LOOP;
                END IF;
            END LOOP;

            v_IDX := v_PARTIES.NEXT(v_IDX);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END REQUIRE_FIN_CONFIRMATION;

-------------------------------------------------------------------------------------
     PROCEDURE DISPATCH(
        p_XML IN XMLTYPE,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        CURSOR c_DISPATCH IS
            SELECT EXTRACTVALUE(VALUE(T), '//@location', g_MISO_NAMESPACE) "SERVICE_POINT_NAME", TO_DATE(EXTRACTVALUE(VALUE(T), '//@interval', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "SCHEDULE_DATE",
                   EXTRACTVALUE(VALUE(T), '//DispatchMW', g_MISO_NAMESPACE) "AMOUNT", EXTRACTVALUE(VALUE(T), '//Price', g_MISO_NAMESPACE) "PRICE"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//Dispatch', g_MISO_NAMESPACE))) T;

        v_TRANSACTION_ID NUMBER(9);
        v_STATUS NUMBER;
    BEGIN
        FOR v_DISPATCH IN c_DISPATCH LOOP
            --GET THE TRANSACTION ID
            BEGIN
                SELECT A.TRANSACTION_ID
                INTO   v_TRANSACTION_ID
                FROM   INTERCHANGE_TRANSACTION A, SUPPLY_RESOURCE B, SERVICE_POINT C
                WHERE  C.EXTERNAL_IDENTIFIER = v_DISPATCH.SERVICE_POINT_NAME AND C.SERVICE_POINT_ID = B.SERVICE_POINT_ID AND A.RESOURCE_ID = B.RESOURCE_ID AND v_DISPATCH.SCHEDULE_DATE BETWEEN A.BEGIN_DATE AND A.END_DATE
                       AND A.TRANSACTION_INTERVAL = '5 Minute';
            EXCEPTION
                WHEN OTHERS THEN
                    p_ERROR_MESSAGE := 'Unable to determine TRANSACTION_ID for Dispatch Instructions to location ' || v_DISPATCH.SERVICE_POINT_NAME || '.';
                    RETURN;
            END;

            --SAVE THE SCHEDULE.
            MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(v_TRANSACTION_ID, v_DISPATCH.SCHEDULE_DATE, GA.EXTERNAL_STATE, v_DISPATCH.AMOUNT, v_DISPATCH.PRICE, v_STATUS, p_ERROR_MESSAGE);

            IF p_ERROR_MESSAGE IS NOT NULL THEN
                RETURN;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END DISPATCH;

-------------------------------------------------------------------------------------
    PROCEDURE RESOURCE_START_STOP(
        p_XML IN XMLTYPE,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
	BEGIN
		NULL;
--         CURSOR c_RESOURCE_START IS
--             SELECT EXTRACTVALUE(VALUE(T), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", TO_DATE(EXTRACTVALUE(VALUE(T), '//@interval', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "START_DATE"
--             FROM   TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//ResourceStart', g_MISO_NAMESPACE))) T;
--
--         CURSOR c_RESOURCE_STOP IS
--             SELECT EXTRACTVALUE(VALUE(T), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", TO_DATE(EXTRACTVALUE(VALUE(T), '//@interval', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "STOP_DATE"
--             FROM   TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//ResourceStop', g_MISO_NAMESPACE))) T;
--
--         v_RESOURCE_ID NUMBER(9);
--         v_PREV_LOCATION_NAME VARCHAR2(64);
--         v_STATUS NUMBER;
--
--         PROCEDURE RESOURCE_ID_FROM_LOCATION(
--             p_LOCATION_NAME IN VARCHAR2
--         ) IS
--         BEGIN
--             IF NOT v_PREV_LOCATION_NAME = p_LOCATION_NAME THEN
--                 v_PREV_LOCATION_NAME := p_LOCATION_NAME;
--
--                 SELECT RESOURCE_ID
--                 INTO   v_RESOURCE_ID
--                 FROM   SUPPLY_RESOURCE A, SERVICE_POINT B
--                 WHERE  B.EXTERNAL_IDENTIFIER = p_LOCATION_NAME AND A.SERVICE_POINT_ID = B.SERVICE_POINT_ID;
--             END IF;
--         EXCEPTION
--             WHEN OTHERS THEN
--                 p_ERROR_MESSAGE := 'Unable to determine RESOURCE_ID for Resource at location ' || p_LOCATION_NAME || '.';
--         END RESOURCE_ID_FROM_LOCATION;
--     BEGIN
--         FOR v_RESOURCE_START IN c_RESOURCE_START LOOP
--             RESOURCE_ID_FROM_LOCATION(v_RESOURCE_START.LOCATION_NAME);
--
--             IF p_ERROR_MESSAGE IS NOT NULL THEN
--                 RETURN;
--             END IF;
--
--             BEGIN
-- --				TG.PUT_IT_TRAIT_SCHEDULE_SPARSE(
--                 INSERT INTO RESOURCE_INTERVAL_QUANTITY
--                             (
--                              RESOURCE_ID, QUANTITY_TYPE, BEGIN_DATE, END_DATE, QUANTITY
--                             )
--                 VALUES      (
--                              v_RESOURCE_ID, 'Started', v_RESOURCE_START.START_DATE, NULL, 1
--                             );
--             EXCEPTION
--                 WHEN DUP_VAL_ON_INDEX THEN
--                     --It's okay if this entry already exists.  Just ignore it.
--                     NULL;
--             END;
--         END LOOP;
--
--         FOR v_RESOURCE_STOP IN c_RESOURCE_STOP LOOP
--             RESOURCE_ID_FROM_LOCATION(v_RESOURCE_STOP.LOCATION_NAME);
--
--             IF p_ERROR_MESSAGE IS NOT NULL THEN
--                 RETURN;
--             END IF;
--
--             --UPDATE THE STOP DATE.
--             BEGIN
--                 UPDATE RESOURCE_INTERVAL_QUANTITY
--                 SET END_DATE = v_RESOURCE_STOP.STOP_DATE
--                 WHERE  RESOURCE_ID = v_RESOURCE_ID AND QUANTITY_TYPE = 'Started' AND BEGIN_DATE = (SELECT MAX(BEGIN_DATE)
--                                                                                                    FROM   RESOURCE_INTERVAL_QUANTITY
--                                                                                                    WHERE  RESOURCE_ID = v_RESOURCE_ID AND QUANTITY_TYPE = 'Started' AND BEGIN_DATE <= v_RESOURCE_STOP.STOP_DATE);
--
--                 IF SQL%NOTFOUND THEN
--                     p_ERROR_MESSAGE := 'No matching start date found for Resource at location ' || v_RESOURCE_STOP.LOCATION_NAME || ' for stop date=' || UT.TRACE_DATE(v_RESOURCE_STOP.STOP_DATE);
--                     RETURN;
--                 END IF;
--             END;
--         END LOOP;
--     EXCEPTION
--         WHEN OTHERS THEN
--             p_ERROR_MESSAGE := SQLERRM;
     END RESOURCE_START_STOP;

-------------------------------------------------------------------------------------
    PROCEDURE EMERGENCY_NOTIFICATIONS(
        p_XML IN XMLTYPE,
        p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
        CURSOR c_NOTIFICATIONS IS
            SELECT EXTRACTVALUE(VALUE(T), '//@realm', g_MISO_NAMESPACE) "REALM", EXTRACTVALUE(VALUE(T), '//@source', g_MISO_NAMESPACE) "SOURCE", EXTRACTVALUE(VALUE(T), '//@destination', g_MISO_NAMESPACE) "DESTINATION",
                   TO_DATE(EXTRACTVALUE(VALUE(T), '//EffectiveTime', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "EFFECTIVE_TIME", TO_DATE(EXTRACTVALUE(VALUE(T), '//TerminationTime', g_MISO_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) "TERMINATION_TIME",
                   EXTRACTVALUE(VALUE(T), '//Priority', g_MISO_NAMESPACE) "PRIORITY", EXTRACTVALUE(VALUE(T), '//Text', g_MISO_NAMESPACE) "TEXT"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(p_XML, '//EmergencyNotifications', g_MISO_NAMESPACE))) T;

    BEGIN
        FOR v_NOTIFICATIONS IN c_NOTIFICATIONS LOOP
            MEX_UTIL.INSERT_MARKET_MESSAGE('MISO', SYSDATE, v_NOTIFICATIONS.REALM, v_NOTIFICATIONS.EFFECTIVE_TIME, v_NOTIFICATIONS.TERMINATION_TIME, v_NOTIFICATIONS.PRIORITY, v_NOTIFICATIONS.SOURCE, v_NOTIFICATIONS.DESTINATION, v_NOTIFICATIONS.TEXT);

            IF p_ERROR_MESSAGE IS NOT NULL THEN
                RETURN;
            END IF;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := SQLERRM;
    END EMERGENCY_NOTIFICATIONS;
-------------------------------------------------------------------------------------

    PROCEDURE RETRIEVE_NOTIFICATIONS(
		p_CRED			IN mex_credentials,
		p_LOG_ONLY 		IN NUMBER,
		p_STATUS		OUT NUMBER,
        p_ERROR_MESSAGE OUT VARCHAR2,
		p_LOGGER		IN OUT mm_logger_adapter
    ) AS
        v_XML_DUMMY_REQUEST XMLTYPE := XMLTYPE.CREATEXML('<GetNotifications/>');
        v_XML_RESPONSE_BODY XMLTYPE := XMLTYPE.CREATEXML('<NoResponse/>');
        v_STILL_MORE BOOLEAN := TRUE;
    BEGIN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		--GET THE LATEST NOTIFICATIONS UNTIL THERE ARE NO MORE.
		WHILE v_STILL_MORE LOOP

			RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_DUMMY_REQUEST, v_XML_RESPONSE_BODY, p_ERROR_MESSAGE, p_LOGGER);

			IF NOT p_ERROR_MESSAGE IS NULL THEN
				RETURN;
			END IF;

			--CHECK TO SEE IF IT IS PAST THE LAST ONE.  OTHERWISE, PROCESS IT.
			IF NOT SAFE_STRING(v_XML_RESPONSE_BODY, '//MMNoMoreNotifications') IS NULL THEN
				v_STILL_MORE := FALSE;
			ELSE
				REQUIRE_FIN_CONFIRMATION(p_CRED.EXTERNAL_ACCOUNT_NAME, v_XML_RESPONSE_BODY, p_ERROR_MESSAGE);
				DISPATCH(v_XML_RESPONSE_BODY, p_ERROR_MESSAGE);
				RESOURCE_START_STOP(v_XML_RESPONSE_BODY, p_ERROR_MESSAGE);
				EMERGENCY_NOTIFICATIONS(v_XML_RESPONSE_BODY, p_ERROR_MESSAGE);

				--LOG THE STATUS
				IF p_ERROR_MESSAGE IS NOT NULL THEN
					p_LOGGER.LOG_ERROR('Processing Error: ' || p_ERROR_MESSAGE);
				END IF;
			END IF;
		END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            p_ERROR_MESSAGE := 'MISO_EXCHANGE.RETRIEVE_NOTIFICATIONS: ' || SQLERRM;
			p_STATUS := SQLCODE;
    END RETRIEVE_NOTIFICATIONS;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ISO_ACCOUNTS_FOR_ENTITY
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2
	) RETURN STRING_TABLE IS
v_RET STRING_TABLE;
BEGIN
	-- Always try to determine ISO account by tracking the entity back to an Interchange Contract
	-- object. The Contract's External Identifier for MISO will be the ISO Account Name.
	--
	-- AREA and WEATHER_STATION have no way to link to a contract. So Areas and Weather Stations
	-- have the ISO account name as their alias.

	CASE UPPER(p_ENTITY_TYPE)
	WHEN g_ENTITY_TYPE_TRANSACTION THEN
		SELECT STRING_TYPE(EXTERNAL_IDENTIFIER)
   		BULK COLLECT INTO v_RET
		FROM (SELECT DISTINCT X.EXTERNAL_IDENTIFIER
    		FROM INTERCHANGE_TRANSACTION B, EXTERNAL_SYSTEM_IDENTIFIER X
    		WHERE B.TRANSACTION_ID = p_ENTITY_ID
				AND X.EXTERNAL_SYSTEM_ID = EC.ES_MISO
				AND X.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT
				AND X.ENTITY_ID = B.CONTRACT_ID
				AND X.IDENTIFIER_TYPE = EI.g_DEFAULT_IDENTIFIER_TYPE);

	WHEN g_ENTITY_TYPE_PORTFOLIO THEN
		SELECT STRING_TYPE(KEY3)
		BULK COLLECT INTO v_RET
		FROM (SELECT DISTINCT KEY3
    		FROM PORTFOLIO A, SYSTEM_LABEL B
    		WHERE A.PORTFOLIO_ID = p_ENTITY_ID
    			AND B.MODEL_ID = 0
    			AND B.MODULE = 'MarketExchange'
    			AND B.KEY1 = 'MISO'
    			AND B.KEY2 = 'Asset Owners'
    			AND B.VALUE = A.PORTFOLIO_DESC);

	WHEN g_ENTITY_TYPE_SERVICE_POINT THEN
		SELECT STRING_TYPE(EXTERNAL_IDENTIFIER)
		BULK COLLECT INTO v_RET
		FROM (SELECT DISTINCT X.EXTERNAL_IDENTIFIER
    		FROM INTERCHANGE_TRANSACTION A, EXTERNAL_SYSTEM_IDENTIFIER X
    		WHERE A.POD_ID = p_ENTITY_ID
				AND X.EXTERNAL_SYSTEM_ID = EC.ES_MISO
				AND X.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT
				AND X.ENTITY_ID = A.CONTRACT_ID
				AND X.IDENTIFIER_TYPE = EI.g_DEFAULT_IDENTIFIER_TYPE);

	WHEN g_ENTITY_TYPE_AREA THEN
		SELECT STRING_TYPE(AREA_ALIAS)
		BULK COLLECT INTO v_RET
		FROM (SELECT DISTINCT A.AREA_ALIAS
    		FROM AREA A
    		WHERE A.AREA_ID = p_ENTITY_ID);

	WHEN g_ENTITY_TYPE_WEATHER_STATION THEN
		SELECT STRING_TYPE(STATION_ALIAS)
		BULK COLLECT INTO v_RET
		FROM (SELECT DISTINCT A.STATION_ALIAS
    		FROM WEATHER_STATION A
    		WHERE A.STATION_ID = p_ENTITY_ID);

	WHEN g_ENTITY_TYPE_SUBSTATION_METER THEN
		SELECT STRING_TYPE(EXTERNAL_IDENTIFIER)
		BULK COLLECT INTO v_RET
		FROM (SELECT DISTINCT X.EXTERNAL_IDENTIFIER
    		FROM TX_SUB_STATION_METER M, TX_SUB_STATION_METER_OWNER MO, EXTERNAL_SYSTEM_IDENTIFIER X
			WHERE M.SERVICE_POINT_ID = p_ENTITY_ID
    			AND MO.METER_ID = M.METER_ID
				AND X.EXTERNAL_SYSTEM_ID = EC.ES_MISO
				AND X.ENTITY_DOMAIN_ID = EC.ED_PSE
				AND X.ENTITY_ID = MO.OWNER_ID
				AND X.IDENTIFIER_TYPE = EI.g_DEFAULT_IDENTIFIER_TYPE);

	ELSE
		-- unrecognized entity type? return an empty collection
		v_RET := STRING_TABLE();
	END CASE;

	RETURN v_RET;
END GET_ISO_ACCOUNTS_FOR_ENTITY;
-------------------------------------------------------------------------------------
FUNCTION GET_ISO_ACCOUNTS RETURN STRING_TABLE IS
	v_RET STRING_TABLE;
BEGIN
	SELECT STRING_TYPE(EXTERNAL_ACCOUNT_NAME) BULK COLLECT
		INTO v_RET
		FROM (SELECT DISTINCT EXTERNAL_ACCOUNT_NAME
			FROM EXTERNAL_CREDENTIALS
			WHERE EXTERNAL_SYSTEM_ID = EC.ES_MISO);

	RETURN v_RET;
END GET_ISO_ACCOUNTS;
-------------------------------------------------------------------------------------
FUNCTION GET_ISO_ACCOUNT_MAP
	(
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_IDs IN GA.ID_TABLE
	) RETURN ISO_TO_IDs_MAP IS
v_MAP ISO_TO_IDs_MAP;
v_INDEX BINARY_INTEGER;
v_JDX BINARY_INTEGER;
v_ISOs STRING_TABLE;
v_ISO_NAME VARCHAR2(64);
v_IDs ID_TABLE;
v_ENTITY_ID NUMBER;
BEGIN
	v_ISOs := GET_ISO_ACCOUNTS;

	IF v_ISOs.COUNT = 0 THEN
		-- no ISO accounts? then just associate all IDs with the ISO name itself
    	v_INDEX := p_ENTITY_IDs.FIRST;
		v_IDs := ID_TABLE();
    	WHILE p_ENTITY_IDs.EXISTS(v_INDEX) LOOP
    		v_ENTITY_ID := p_ENTITY_IDs(v_INDEX);
			v_IDs.EXTEND();
			v_IDs(v_IDs.LAST) := ID_TYPE(v_ENTITY_ID);
    		v_INDEX := p_ENTITY_IDs.NEXT(v_INDEX);
    	END LOOP;
		v_MAP('MISO') := v_IDs;

	ELSE
    	-- loop over list of entity IDs
    	v_INDEX := p_ENTITY_IDs.FIRST;
    	WHILE p_ENTITY_IDs.EXISTS(v_INDEX) LOOP
    		-- get list of ISO Accounts for this entity (typically this list should just have 1 entry)
    		v_ENTITY_ID := p_ENTITY_IDs(v_INDEX);
    		v_ISOs := GET_ISO_ACCOUNTS_FOR_ENTITY(v_ENTITY_ID, p_ENTITY_TYPE);
    		v_JDX := v_ISOs.FIRST;

    		-- loop through list of ISO accounts adding this entity to the map for each one
    		WHILE v_ISOs.EXISTS(v_JDX) LOOP
    			v_ISO_NAME := v_ISOs(v_JDX).STRING_VAL;
    			IF v_MAP.EXISTS(v_ISO_NAME) THEN
    				-- entry already exists in map? then add ID to that list
    				v_IDs := v_MAP(v_ISO_NAME);
    			ELSE
    				-- otherwise, make a new list - and associate it with this ISO in the map
    				v_IDs := ID_TABLE();
    			END IF;
    			-- add the entity
                v_IDs.EXTEND();
                v_IDs(v_IDs.LAST) := ID_TYPE(v_ENTITY_ID);

				v_MAP(v_ISO_NAME) := v_IDs;

    			v_JDX := v_ISOs.NEXT(v_JDX);
    		END LOOP;

    		v_INDEX := p_ENTITY_IDs.NEXT(v_INDEX);
    	END LOOP;
	END IF;

	-- all done
	RETURN v_MAP;
END GET_ISO_ACCOUNT_MAP;
-------------------------------------------------------------------------------------
PROCEDURE HANDLE_CONFIRMED_FIN_SCHEDS
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ENTITY_ID_TABLE IN ID_TABLE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
	v_HOURLY_BEGIN_DATE DATE;
	v_HOURLY_END_DATE DATE;
	v_INDEX NUMBER;
	v_ENTITY_ID NUMBER;
	v_CURRENT_DATE DATE;
	v_AMOUNT NUMBER;
	v_PRICE NUMBER;
BEGIN
	UT.CUT_DAY_INTERVAL_RANGE(1, p_BEGIN_DATE, p_END_DATE, MM_MISO_UTIL.g_MISO_TIMEZONE, 60, v_HOURLY_BEGIN_DATE, v_HOURLY_END_DATE);
	v_INDEX := p_ENTITY_ID_TABLE.FIRST;

	WHILE p_ENTITY_ID_TABLE.EXISTS(v_INDEX) LOOP
		v_ENTITY_ID := p_ENTITY_ID_TABLE(v_INDEX).ID;
		--LOOP OVER DATES
		v_CURRENT_DATE := v_HOURLY_BEGIN_DATE;

		WHILE v_CURRENT_DATE <= v_HOURLY_END_DATE LOOP
			SELECT QUANTITY, PRICE
			INTO   v_AMOUNT, v_PRICE
			FROM   BID_OFFER_SET
			WHERE  TRANSACTION_ID = v_ENTITY_ID AND SCHEDULE_STATE = GA.INTERNAL_STATE AND SCHEDULE_DATE = v_CURRENT_DATE AND SET_NUMBER = 1;

			MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(p_TRANSACTION_ID => v_ENTITY_ID, p_SCHEDULE_DATE => v_CURRENT_DATE, p_SCHEDULE_STATE => GA.INTERNAL_STATE, p_PRICE => v_PRICE, p_AMOUNT => v_AMOUNT, p_STATUS => p_STATUS,
				p_ERROR_MESSAGE => p_MESSAGE);

			IF NOT p_MESSAGE IS NULL THEN
				RETURN;
			END IF;

			v_CURRENT_DATE := v_CURRENT_DATE + 1 / 24;
		END LOOP;        --OVER DATES

		v_INDEX := p_ENTITY_ID_TABLE.NEXT(v_INDEX);
	END LOOP;    -- OVER ENTITIES;

END HANDLE_CONFIRMED_FIN_SCHEDS;
-------------------------------------------------------------------------------------
PROCEDURE HANDLE_CONFIRMED_FIN_CONTRACTS
	(
	p_ENTITY_ID_TABLE IN ID_TABLE
	) AS
	v_INDEX NUMBER;
	v_ENTITY_ID NUMBER;
	v_TRANSACTION INTERCHANGE_TRANSACTION%ROWTYPE;
BEGIN
	v_INDEX := p_ENTITY_ID_TABLE.FIRST;

	WHILE p_ENTITY_ID_TABLE.EXISTS(v_INDEX) LOOP
		v_ENTITY_ID := p_ENTITY_ID_TABLE(v_INDEX).ID;

		--COPY THE EXTERNAL TRANSACTION INTO THE INTERNAL ONE AND MARK IT AS APPROVED.
		SELECT A.*
		INTO   v_TRANSACTION
		FROM   INTERCHANGE_TRANSACTION_EXT A, INTERCHANGE_TRANSACTION B
		WHERE  B.TRANSACTION_ID = v_ENTITY_ID AND A.TRANSACTION_NAME = B.TRANSACTION_NAME;

		v_TRANSACTION.TRANSACTION_ID := v_ENTITY_ID;
		MM_UTIL.PUT_TRANSACTION(v_ENTITY_ID, v_TRANSACTION, GA.INTERNAL_STATE, MM_UTIL.g_BILAT_APPROVED);
		v_INDEX := p_ENTITY_ID_TABLE.NEXT(v_INDEX);
	END LOOP; -- OVER ENTITIES;
END HANDLE_CONFIRMED_FIN_CONTRACTS;
-------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE_ALL_ENTITIES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ACTION IN VARCHAR2,
	p_CRED IN MEX_CREDENTIALS,
	p_LOGGER IN OUT MM_LOGGER_ADAPTER,
	p_FOUND OUT BOOLEAN,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_CURRENT_DATE DATE;
	v_LOOP_OVER_DATES BOOLEAN := FALSE;
	v_LOG_ONLY NUMBER(1) := 0;
	v_ACTION VARCHAR2(64);
	v_NO_SUBMIT BOOLEAN := FALSE;
	v_PARTY_TABLE GA.STRING_TABLE;
	v_PARTY_INDEX BINARY_INTEGER;
BEGIN
	p_STATUS := GA.SUCCESS;
	v_ACTION := p_ACTION;
	p_FOUND := FALSE;

	-- If action is one of these, then we don't need to look at the entity list because
	-- these don't take any entities as input parameters
	-- So just query for this account.  (Outer call will loop over each account.)

	v_CURRENT_DATE := TRUNC(p_BEGIN_DATE);
	LOOP --LOOP OVER DATES
		p_FOUND := TRUE;

		 CASE v_ACTION
			WHEN g_ET_QRY_MESSAGES THEN
				QUERY_MESSAGES(p_CRED, v_CURRENT_DATE, NULL, NULL, v_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
			WHEN g_ET_QRY_NODE_LIST THEN
				QUERY_NODE_LIST(p_CRED, v_CURRENT_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
			WHEN g_ET_QRY_LOAD_FORECAST THEN
				QUERY_LOAD_FORECAST(p_CRED, v_CURRENT_DATE, NULL, NULL, v_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
				v_LOOP_OVER_DATES := TRUE;
				v_NO_SUBMIT := TRUE;
			WHEN g_ET_QRY_MARKET_RESULTS THEN
				QUERY_MARKET_RESULTS(p_CRED => p_CRED, p_BEGIN_DATE => p_BEGIN_DATE, p_END_DATE => p_END_DATE, p_LOG_ONLY => v_LOG_ONLY, p_STATUS => p_STATUS,  p_ERROR_MESSAGE => p_MESSAGE, p_LOGGER => p_LOGGER);
				v_LOOP_OVER_DATES := FALSE;
				v_NO_SUBMIT := TRUE;
			WHEN g_ET_QRY_PSS_SCHEDULE_AND_BIDS THEN
				MM_MISO_PSS.QUERY_PSS_SCHEDULE_BIDS(p_CRED,p_BEGIN_DATE,p_END_DATE, v_LOG_ONLY, p_STATUS,  p_MESSAGE, p_LOGGER => p_LOGGER);
				v_LOOP_OVER_DATES := FALSE;
				v_NO_SUBMIT := TRUE;
            WHEN g_ET_RT_INTEGRATED_LMP_QUERY THEN
				QUERY_RT_INT_LMP_ALL_LOC(p_CRED,p_BEGIN_DATE,p_END_DATE, v_LOG_ONLY, p_STATUS,  p_MESSAGE, p_LOGGER => p_LOGGER);
				v_LOOP_OVER_DATES := FALSE;
				v_NO_SUBMIT := TRUE;
        --    WHEN g_ET_5_MINUTE_LMP_QUERY THEN
	--			MM_MISO_PSS.QUERY_PSS_SCHEDULE_BIDS(p_CRED,p_BEGIN_DATE,p_END_DATE, v_LOG_ONLY, p_STATUS,  p_MESSAGE, p_LOGGER => p_LOGGER);
	--			v_LOOP_OVER_DATES := FALSE;
	--			v_NO_SUBMIT := TRUE;
			ELSE
				p_FOUND := FALSE;
				--If we did not find our action in this set, look in the next set.
		END CASE;

		IF NOT p_FOUND THEN
			-- Loop over each of the asset owners, and query certain things
			-- based on asset owner, or party.
			GET_PARTIES_FOR_ISO_ACCOUNT(p_CRED.EXTERNAL_ACCOUNT_NAME, v_PARTY_TABLE);
			v_PARTY_INDEX := v_PARTY_TABLE.FIRST;

			WHILE v_PARTY_TABLE.EXISTS(v_PARTY_INDEX) LOOP
				p_FOUND := TRUE;
				CASE v_ACTION
					WHEN g_ET_QRY_FCONTR THEN
						QUERY_FIN_CONTRACT(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, NULL, NULL, NULL, NULL, FALSE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
					WHEN g_ET_QRY_FCONTR_APPRV THEN
						QUERY_FIN_CONTRACT(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), 1, NULL, FALSE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
					WHEN g_ET_QRY_FCONTR_INTERNAL THEN
						QUERY_FIN_CONTRACT(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, NULL, NULL, NULL, NULL, TRUE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
					WHEN g_ET_QRY_FCONTR_APPRV_INTERNAL THEN
						QUERY_FIN_CONTRACT(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, TRUNC(p_BEGIN_DATE), TRUNC(p_END_DATE), 1, NULL, TRUE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
					WHEN g_ET_QRY_FSCHED THEN
						QUERY_FIN_SCHEDULE(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, v_CURRENT_DATE, NULL, FALSE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_QRY_FSCHED_APPRV THEN
						QUERY_FIN_SCHEDULE(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, v_CURRENT_DATE, 1, FALSE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_QRY_FSCHED_INTERNAL THEN
						QUERY_FIN_SCHEDULE(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, v_CURRENT_DATE, NULL, TRUE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_QRY_FSCHED_APPRV_INTERNAL THEN
						QUERY_FIN_SCHEDULE(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), NULL, NULL, v_CURRENT_DATE, 1, TRUE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_QRY_SETTLEMENT_STATEMENT THEN
						QUERY_SETTLEMENT_STATEMENT(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_QRY_PORTFOLIOS THEN
						QUERY_PORTFOLIO(p_CRED, v_PARTY_TABLE(v_PARTY_INDEX), v_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
					ELSE
						p_FOUND := FALSE;
				END CASE;

				v_PARTY_INDEX := v_PARTY_TABLE.NEXT(v_PARTY_INDEX);
			END LOOP;
		END IF;

		EXIT WHEN (NOT v_LOOP_OVER_DATES) OR(v_CURRENT_DATE >= TRUNC(p_END_DATE));
		v_CURRENT_DATE := v_CURRENT_DATE + 1;
	END LOOP;

END MARKET_EXCHANGE_ALL_ENTITIES;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE_BY_ENTITY
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ACTION IN VARCHAR2,
	p_ENTITY_IDS IN VARCHAR2,
	p_ENTITY_DELIMITER IN CHAR,
	p_LOG_TYPE IN NUMBER,
	p_TRACE_ON IN NUMBER,
	p_LOG_ONLY IN BINARY_INTEGER :=0,
	p_LOGGER IN OUT MM_LOGGER_ADAPTER,
	p_FOUND OUT BOOLEAN,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_ENTITY_ID_TABLE GA.ID_TABLE;
	v_ID_MAP ISO_TO_IDS_MAP;
	v_ISO_ACCOUNT VARCHAR2(64);
	v_ENTITY_TYPE VARCHAR2(32);
	v_ENTITY_ID NUMBER(9);
	v_SUBMIT_XML XMLTYPE;
	v_CURRENT_XML XMLTYPE;
	v_LOOP_COUNTER BINARY_INTEGER := 1;
	v_SUBMIT_STATUS VARCHAR2(32);
	v_MARKET_STATUS VARCHAR2(32);
	v_CURRENT_DATE DATE;
	v_LOOP_OVER_DATES BOOLEAN := FALSE;
	v_LOG_ONLY NUMBER(1) := 0;
	v_ACTION VARCHAR2(64);
	v_NO_SUBMIT BOOLEAN := FALSE;
	v_ENTITY_NAME VARCHAR2(64);
	v_PARTY_NAME VARCHAR2(16) := NULL;
	v_INDEX NUMBER;
	v_CRED MEX_CREDENTIALS;
	v_ISO_INDEX BINARY_INTEGER;
	v_ISOs STRING_TABLE;
BEGIN
	v_ACTION := p_ACTION;

	-- These actions take an input entity. So we have to use that input entity to determine
	-- which ISO account to use when sending submit/query to the ISO.
	UT.IDS_FROM_STRING(p_ENTITY_IDS, p_ENTITY_DELIMITER, v_ENTITY_ID_TABLE);
	v_ENTITY_TYPE := GET_ENTITY_TYPE_FOR_ACTION(v_ACTION);
	v_ID_MAP := GET_ISO_ACCOUNT_MAP(v_ENTITY_TYPE, v_ENTITY_ID_TABLE);
	v_ISOs := GET_ISO_ACCOUNTS;
	v_ISO_INDEX := v_ISOs.FIRST;
	p_FOUND := TRUE;

	--LOOP OVER ISO ACCOUNTS
	WHILE v_ISOs.EXISTS(v_ISO_INDEX) LOOP

		v_ISO_ACCOUNT := v_ISOs(v_ISO_INDEX).STRING_VAL;
		v_INDEX := v_ID_MAP(v_ISO_ACCOUNT).FIRST;
		v_SUBMIT_XML := NULL;                                                                                                                                                                                             -- reset submission XML body

		--LOOP OVER ENTITIES
		LOOP
			IF p_ENTITY_IDS IS NULL THEN
				v_ENTITY_ID := NULL;
			ELSE
				v_ENTITY_ID := v_ID_MAP(v_ISO_ACCOUNT)(v_INDEX).ID;
			END IF;

			--Get the credential for this entity.
			MM_UTIL.INIT_MEX(EC.ES_MISO, v_ISO_ACCOUNT, 'MISO:MARKET EXCHANGE', v_ACTION, p_LOG_TYPE, p_TRACE_ON, v_CRED, p_LOGGER);

			--LOOP OVER DATES
			v_CURRENT_DATE := TRUNC(p_BEGIN_DATE);
			LOOP
				CASE v_ACTION
					WHEN g_ET_SUBMIT_FIN_CONTRACT THEN
						FIN_CONTRACT(v_ENTITY_ID, v_CURRENT_XML);

					/* THESE NEED TO BE SUBMITTED BY TRANSACTION NOW, NOT BY RESOURCE_ID.
					WHEN g_ET_SUBMIT_DEF_LIMITS THEN
						DEFAULT_LIMITS(v_ENTITY_ID, v_CURRENT_DATE, v_CURRENT_XML);
					WHEN g_ET_SUBMIT_DEF_STARTUP_COSTS THEN
						DEFAULT_STARTUP_COSTS(v_ENTITY_ID, v_CURRENT_DATE, v_CURRENT_XML);
					WHEN g_ET_SUBMIT_DEF_STATUS THEN
						DEFAULT_STATUS(v_ENTITY_ID, v_CURRENT_DATE, v_CURRENT_XML);
					WHEN g_ET_SUBMIT_RAMP_RATE THEN
						RAMP_RATE(v_ENTITY_ID, v_CURRENT_DATE, v_CURRENT_XML);
					*/

					WHEN g_ET_CREATE_PORTFOLIO THEN
						UPDATE_PORTFOLIO(v_ENTITY_ID, 1, v_CURRENT_XML);
					WHEN g_ET_UPDATE_PORTFOLIO THEN
						UPDATE_PORTFOLIO(v_ENTITY_ID, 0, v_CURRENT_XML);
					WHEN g_ET_CONFIRM_FIN_CONTRACT THEN
						--NOTE THIS HAS EXTRA FUNCTIONALITY BELOW (AT END).
						FIN_CONFIRM_CONTRACT(v_ENTITY_ID, 'Confirm', v_CURRENT_XML);
					WHEN g_ET_REJECT_FIN_CONTRACT THEN
						FIN_CONFIRM_CONTRACT(v_ENTITY_ID, 'Reject', v_CURRENT_XML);
					WHEN g_ET_CONFIRM_FIN_SCHEDULE THEN
						--NOTE THIS HAS EXTRA FUNCTIONALITY BELOW (AT END).
						FIN_CONFIRM_SCHEDULE(v_ENTITY_ID, v_CURRENT_DATE, 'Confirm', v_CURRENT_XML);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_REJECT_FIN_SCHEDULE THEN
						FIN_CONFIRM_SCHEDULE(v_ENTITY_ID, v_CURRENT_DATE, 'Reject', v_CURRENT_XML);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_SUBMIT_WEATHER_FORECAST THEN
						WEATHER_FORECAST(v_ENTITY_ID, v_CURRENT_DATE, v_CURRENT_XML);
						v_LOOP_OVER_DATES := TRUE;
					WHEN g_ET_QRY_DIST_FACTORS_LOC THEN
						v_ENTITY_NAME := GET_LOCATION_EXT_ID(v_ENTITY_ID);
						QUERY_DISTRIBUTION_FACTORS(v_CRED, v_CURRENT_DATE, v_ENTITY_NAME, NULL, v_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := FALSE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_DIST_FACTORS_PORT THEN
						v_ENTITY_NAME := GET_PORTFOLIO_EXT_ID(v_ENTITY_ID);
						QUERY_DISTRIBUTION_FACTORS(v_CRED, v_CURRENT_DATE, NULL, v_ENTITY_NAME, v_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := FALSE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_FIXED_DEMAND_PORT THEN
						v_ENTITY_NAME := GET_PORTFOLIO_EXT_ID(v_ENTITY_ID);
						v_PARTY_NAME := GET_PORTFOLIO_PARTY(v_ENTITY_ID);
						QUERY_FIXED_DEMAND_BID(v_CRED, v_PARTY_NAME, NULL, v_ENTITY_NAME, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_FIXED_DEMAND_LOC THEN
						v_ENTITY_NAME := GET_LOCATION_EXT_ID(v_ENTITY_ID);
						QUERY_FIXED_DEMAND_BID(v_CRED, NULL, NULL, v_ENTITY_NAME, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_PRICE_SENS_DEMD_PORT THEN
						v_ENTITY_NAME := GET_PORTFOLIO_EXT_ID(v_ENTITY_ID);
						v_PARTY_NAME := GET_PORTFOLIO_PARTY(v_ENTITY_ID);
						QUERY_PRICE_SENS_DEMAND_BID(v_CRED, v_PARTY_NAME, NULL, v_ENTITY_NAME, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_PRICE_SENS_DEMD_LOC THEN
						v_ENTITY_NAME := GET_LOCATION_EXT_ID(v_ENTITY_ID);
						QUERY_PRICE_SENS_DEMAND_BID(v_CRED, NULL, NULL, v_ENTITY_NAME, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_SCHEDULE_OFFERS_PORT THEN
						v_ENTITY_NAME := GET_PORTFOLIO_EXT_ID(v_ENTITY_ID);
						v_PARTY_NAME := GET_PORTFOLIO_PARTY(v_ENTITY_ID);
						QUERY_SCHEDULE_OFFER(v_CRED, v_PARTY_NAME, NULL, v_ENTITY_NAME, NULL, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_SCHEDULE_OFFERS_LOC THEN
						v_ENTITY_NAME := GET_LOCATION_EXT_ID(v_ENTITY_ID);
						QUERY_SCHEDULE_OFFER(v_CRED, NULL, v_ENTITY_NAME, NULL, NULL, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_UPDATE_PORT THEN
						v_ENTITY_NAME := GET_PORTFOLIO_EXT_ID(v_ENTITY_ID);
						v_PARTY_NAME := GET_PORTFOLIO_PARTY(v_ENTITY_ID);
						QUERY_UPDATE(v_CRED, v_PARTY_NAME, NULL, v_ENTITY_NAME, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_VIRT_BIDS_PORT THEN
						v_ENTITY_NAME := GET_PORTFOLIO_EXT_ID(v_ENTITY_ID);
						v_PARTY_NAME := GET_PORTFOLIO_PARTY(v_ENTITY_ID);
						QUERY_VIRTUAL_BID(v_CRED, v_PARTY_NAME, NULL, v_ENTITY_NAME, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_VIRT_BIDS_LOC THEN
						v_ENTITY_NAME := GET_LOCATION_EXT_ID(v_ENTITY_ID);
						QUERY_VIRTUAL_BID(v_CRED, NULL, v_ENTITY_NAME, NULL, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_VIRT_OFFERS_PORT THEN
						v_ENTITY_NAME := GET_PORTFOLIO_EXT_ID(v_ENTITY_ID);
						v_PARTY_NAME := GET_PORTFOLIO_PARTY(v_ENTITY_ID);
						QUERY_VIRTUAL_OFFER(v_CRED, v_PARTY_NAME, NULL, v_ENTITY_NAME, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_VIRT_OFFERS_LOC THEN
						v_ENTITY_NAME := GET_LOCATION_EXT_ID(v_ENTITY_ID);
						QUERY_VIRTUAL_OFFER(v_CRED, NULL, v_ENTITY_NAME, NULL, v_CURRENT_DATE, v_LOG_ONLY, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_QRY_LOAD_FORECAST THEN
						SELECT AREA_NAME
						INTO   v_ENTITY_NAME
						FROM   AREA
						WHERE  AREA_ID = v_ENTITY_ID;

						QUERY_LOAD_FORECAST(v_CRED, v_CURRENT_DATE, v_ENTITY_NAME, NULL, v_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := TRUE;
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_SUBMIT_FTR_BID_PROFILE THEN
						MM_MISO_FTR.GET_FTR_BID_PROFILE(v_ENTITY_ID, v_CURRENT_DATE, v_CURRENT_XML, p_MESSAGE, p_LOGGER);
						v_NO_SUBMIT := TRUE;
					WHEN g_ET_UPLOAD_METER_DATA THEN
						UPLOAD_METER_DATA(v_CRED, v_ENTITY_ID, p_BEGIN_DATE, p_END_DATE, p_LOG_ONLY, p_STATUS, p_MESSAGE, p_LOGGER);
						v_LOOP_OVER_DATES := FALSE;
						v_NO_SUBMIT := TRUE;
					ELSE
						p_FOUND := FALSE;
						RETURN;
				END CASE;

				SELECT XMLCONCAT(v_SUBMIT_XML, v_CURRENT_XML)
				INTO   v_SUBMIT_XML
				FROM   DUAL;

				--MAKE SURE WE DON'T HAVE A RUNAWAY LOOP.
				v_LOOP_COUNTER := v_LOOP_COUNTER + 1;

				IF v_LOOP_COUNTER > 10000 THEN
					RAISE_APPLICATION_ERROR(-20100, 'RUNAWAY LOOP IN MM_MISO.MARKET_SUBMIT');
				END IF;

				EXIT WHEN (NOT v_LOOP_OVER_DATES) OR(v_CURRENT_DATE >= TRUNC(p_END_DATE));
				v_CURRENT_DATE := v_CURRENT_DATE + 1;
			END LOOP;

			EXIT WHEN v_ENTITY_ID IS NULL OR v_INDEX = v_ID_MAP(v_ISO_ACCOUNT).LAST;
			v_INDEX := v_ID_MAP(v_ISO_ACCOUNT).NEXT(v_INDEX);
		END LOOP; -- OVER ENTITIES                                                                                                                                                                                                              -- OVER ENTITIES;

		--SUBMIT EVERYTHING FOR THIS ACCOUNT AT ONCE.
		IF NOT v_NO_SUBMIT THEN
			RUN_MISO_SUBMIT(v_CRED, v_LOG_ONLY, v_SUBMIT_XML, v_PARTY_NAME, v_SUBMIT_STATUS, v_MARKET_STATUS, p_MESSAGE, p_LOGGER);
		END IF;

		--IF THIS WAS A CONFIRM FIN SCHEDULE AND IT WAS SUCCESSFUL,
		--MOVE THE BID OFFER DATA TO IT_SCHEDULE FOR THE FIN CONTRACTS.
		IF p_STATUS = MEX_SWITCHBOARD.c_Status_Success AND v_ACTION = g_ET_CONFIRM_FIN_SCHEDULE THEN
			HANDLE_CONFIRMED_FIN_SCHEDS(p_BEGIN_DATE, p_END_DATE, v_ID_MAP(v_ISO_ACCOUNT), p_STATUS, p_MESSAGE);
		ELSIF p_STATUS = MEX_SWITCHBOARD.c_Status_Success AND v_ACTION = g_ET_CONFIRM_FIN_CONTRACT THEN
			HANDLE_CONFIRMED_FIN_CONTRACTS(v_ID_MAP(v_ISO_ACCOUNT));
		END IF;

		v_ISO_INDEX := v_ISOs.NEXT(v_ISO_INDEX);
	END LOOP; -- OVER ISO ACCOUNTS

END MARKET_EXCHANGE_BY_ENTITY;
----------------------------------------------------------------------------------------------------

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_LOG_ONLY					IN BINARY_INTEGER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2
	) AS

	v_EXT_CREDS mm_credentials_set;
	v_CRED  mex_credentials;
	v_LOGGER mm_logger_adapter;
	v_ACTION VARCHAR2(64) := p_EXCHANGE_TYPE;
	v_RUN_ONCE BOOLEAN := FALSE;
	v_FOUND BOOLEAN := FALSE;

BEGIN
	p_STATUS := GA.SUCCESS;

	IF p_EXCHANGE_TYPE LIKE '%LMP%' THEN
		MM_MISO_LMP.MARKET_EXCHANGE(p_BEGIN_DATE, p_END_DATE, p_EXCHANGE_TYPE, p_LOG_TYPE, p_TRACE_ON, p_LOG_ONLY, p_STATUS, p_MESSAGE);
		RETURN;
	END IF;

	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_MISO,
		p_PROCESS_NAME => 'MISO:MARKET EXCHANGE',
		p_EXCHANGE_NAME => p_EXCHANGE_TYPE,
		p_LOG_TYPE => p_LOG_TYPE,
		p_TRACE_ON => p_TRACE_ON,
		p_CREDENTIALS => v_EXT_CREDS,
		p_LOGGER => v_LOGGER);

	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	--Get a credential for each entity as we loop.
	IF p_ENTITY_LIST IS NOT NULL THEN
		MARKET_EXCHANGE_BY_ENTITY(p_BEGIN_DATE, p_END_DATE, p_EXCHANGE_TYPE, p_ENTITY_LIST, p_ENTITY_LIST_DELIMITER,
			p_LOG_TYPE, p_TRACE_ON, p_LOG_ONLY, v_LOGGER, v_FOUND, p_STATUS, p_MESSAGE);
	ELSE

		-- Querying messages, node list, load forecast is the same for everyone, so it gets run only once.
		IF v_ACTION IN (g_ET_QRY_MESSAGES, g_ET_QRY_NODE_LIST, g_ET_QRY_LOAD_FORECAST) THEN
			v_RUN_ONCE := TRUE;
		ELSE
			v_RUN_ONCE := FALSE;
		END IF;

		WHILE v_EXT_CREDS.HAS_NEXT LOOP
			v_CRED := v_EXT_CREDS.GET_NEXT;

			IF p_EXCHANGE_TYPE = g_ET_RETRIEVE_NOTIFICATIONS THEN
				RETRIEVE_NOTIFICATIONS(v_CRED, p_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
				v_FOUND := TRUE;
			ELSE
				MARKET_EXCHANGE_ALL_ENTITIES(p_BEGIN_DATE, p_END_DATE, p_EXCHANGE_TYPE,
					v_CRED, v_LOGGER, v_FOUND, p_STATUS, p_MESSAGE);
			END IF;

			EXIT WHEN (v_RUN_ONCE);
		END LOOP;
	END IF;

	IF p_MESSAGE IS NOT NULL THEN
		v_LOGGER.LOG_ERROR(p_MESSAGE);
	ELSIF NOT (v_FOUND) THEN
		IF p_ENTITY_LIST IS NULL THEN
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' is not a valid non-Entity Exchange Type.';
		ELSE
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' is not a valid Entity Exchange Type.';
		END IF;
		v_LOGGER.LOG_ERROR(p_MESSAGE);
	END IF;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
EXCEPTION
	WHEN OTHERS THEN
    	p_STATUS := SQLCODE;
        p_MESSAGE := SQLERRM;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
--------------------------------------------------------------------------------------------
    PROCEDURE GET_AGREEMENT_TYPE_LIST(
        p_COMMODITY_ID IN NUMBER,
        p_CURSOR IN OUT REF_CURSOR
    ) AS
        --RETURN CURSOR TO POPULATE AGREEMENT TYPE DROPDOWN IN TXN DIALOG
        v_COMMODITY_TYPE IT_COMMODITY.COMMODITY_TYPE%TYPE := NULL;
    BEGIN
        BEGIN
            SELECT COMMODITY_TYPE
            INTO   v_COMMODITY_TYPE
            FROM   IT_COMMODITY
            WHERE  COMMODITY_ID = p_COMMODITY_ID;
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;

        IF v_COMMODITY_TYPE = 'Transmission' THEN
            OPEN p_CURSOR FOR
                SELECT 'FTR OnPeak Obligation'
                FROM   DUAL
                UNION ALL
                SELECT 'FTR OffPeak Obligation'
                FROM   DUAL
                UNION ALL
                SELECT 'FTR OnPeak Option'
                FROM   DUAL
                UNION ALL
                SELECT 'FTR OffPeak Option'
                FROM   DUAL;
        ELSIF v_COMMODITY_TYPE = 'Energy' THEN
            OPEN p_CURSOR FOR
                SELECT 'PureFinancial'
                FROM   DUAL
                UNION ALL
                SELECT 'GrandFathered'
                FROM   DUAL;
        ELSE
            OPEN p_CURSOR FOR
                SELECT NULL
                FROM   DUAL
                WHERE  1 = 2;
        END IF;
    END GET_AGREEMENT_TYPE_LIST;

----------------------------------------------------------------------------------------------------
FUNCTION GET_BID_OFFER_INTERVAL
	(
	p_TRANSACTION IN INTERCHANGE_TRANSACTION%ROWTYPE
	) RETURN VARCHAR2 IS
v_COMMODITY_TYPE VARCHAR2(16);
BEGIN

	SELECT SUBSTR(MAX(COMMODITY_TYPE),1,16)
	INTO v_COMMODITY_TYPE
	FROM IT_COMMODITY
	WHERE COMMODITY_ID = p_TRANSACTION.COMMODITY_ID;

	IF UPPER(v_COMMODITY_TYPE) = 'TRANSMISSION' THEN
		RETURN 'Month'; -- FTRs have monthly bids/offers
	ELSE
		RETURN 'Hour'; -- everything is hourly
	END IF;
END GET_BID_OFFER_INTERVAL;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_5MIN_LMP_REPORT(p_STATUS        OUT NUMBER,
							  p_CURSOR        IN OUT REF_CURSOR) AS
BEGIN
OPEN p_CURSOR FOR
	SELECT B.OWNER_ENTITY_ID AS SERVICE_POINT_ID
		FROM ENTITY_ATTRIBUTE A, TEMPORAL_ENTITY_ATTRIBUTE B, SERVICE_POINT S
	 WHERE A.ENTITY_DOMAIN_ID = -210
		 AND A.ATTRIBUTE_NAME = 'Use for MISO 5min LMP'
		 AND B.ATTRIBUTE_ID = A.ATTRIBUTE_ID
		 AND B.BEGIN_DATE = (SELECT MAX(BEGIN_DATE)
													 FROM TEMPORAL_ENTITY_ATTRIBUTE
													WHERE OWNER_ENTITY_ID = B.OWNER_ENTITY_ID
														AND ATTRIBUTE_ID = B.ATTRIBUTE_ID)
		 AND B.OWNER_ENTITY_ID=S.SERVICE_POINT_ID
		 ORDER BY S.SERVICE_POINT_NAME;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;

END GET_5MIN_LMP_REPORT;
------------------------------------------------------------------------------------------------------------------------------
PROCEDURE PUT_MISO_5MIN_LMP_SVC_PT(p_SERVICE_POINT_ID     IN NUMBER,
																	 p_STATUS               OUT NUMBER) IS
	v_ATTRIBUTE_ID NUMBER(9);
BEGIN
	p_STATUS := GA.SUCCESS;
	ID.ID_FOR_ENTITY_ATTRIBUTE('Use for MISO 5min LMP',
														 'SERVICE_POINT',
														 'String',
														 TRUE,
														 v_ATTRIBUTE_ID);
	SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(p_SERVICE_POINT_ID,
																	 v_ATTRIBUTE_ID,
																	 LOW_DATE,
																	 NULL,
																	 1,
																	 p_SERVICE_POINT_ID,
																	 v_ATTRIBUTE_ID,
																	 LOW_DATE,
																	 p_STATUS);
END PUT_MISO_5MIN_LMP_SVC_PT;
------------------------------------------------------------------------------------------------------------------------------
PROCEDURE DEL_MISO_5MIN_LMP_SVC_PT(p_SERVICE_POINT_ID IN NUMBER,
																	 p_STATUS           OUT NUMBER) IS
	v_ATTRIBUTE_ID NUMBER(9);
BEGIN
	p_STATUS := GA.SUCCESS;
	ID.ID_FOR_ENTITY_ATTRIBUTE('Use for MISO 5min LMP',
														 'SERVICE_POINT',
														 'String',
														 TRUE,
														 v_ATTRIBUTE_ID);
	DELETE FROM TEMPORAL_ENTITY_ATTRIBUTE T
	 WHERE T.OWNER_ENTITY_ID = p_SERVICE_POINT_ID
		 AND T.ATTRIBUTE_ID = v_ATTRIBUTE_ID;
END DEL_MISO_5MIN_LMP_SVC_PT;
------------------------------------------------------------------------------------------------------------------------------
END MM_MISO;
/
