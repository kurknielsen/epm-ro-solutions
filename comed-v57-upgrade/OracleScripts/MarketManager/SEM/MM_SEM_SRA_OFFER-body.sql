CREATE OR REPLACE PACKAGE BODY MM_SEM_SRA_OFFER IS
------------------------------------------------------------------------------

g_XML_VERS_NO CONSTANT VARCHAR2(8) := '1.0';
g_XML_STANDING_FLAG CONSTANT VARCHAR2(8) := 'false';

g_TRANSACTION_IDs_USED NUMBER_COLLECTION := NUMBER_COLLECTION();

g_REALLOC_TYPES UT.STRING_MAP;

g_ENERGY_REALLOC_TYPE VARCHAR2(32) := 'ENERGY_PAYMENT';
g_CAPACITY_REALLOC_TYPE VARCHAR2(32) := 'CAPACITY_PAYMENT';

g_ENERGY_ALIAS VARCHAR2(16) := 'Energy';
g_CAPACITY_ALIAS VARCHAR2(16) := 'Capacity';

------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.5 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_REALLOC_TYPE(p_COMMODITY_ID IN NUMBER) RETURN VARCHAR2 AS
   v_RET_VAL        VARCHAR2(16);
BEGIN
    SELECT CASE COMMODITY_ALIAS
				WHEN g_ENERGY_ALIAS THEN g_ENERGY_REALLOC_TYPE
				-- 2007-10-09, jbc: replaced g_CAPACITY_ALIAS with g_CAPACITY_REALLOC_TYPE
				-- (fix for BZ 14811)
				WHEN g_CAPACITY_ALIAS THEN g_CAPACITY_REALLOC_TYPE
				END
    INTO v_RET_VAL
    FROM IT_COMMODITY
    WHERE IT_COMMODITY.COMMODITY_ID = p_COMMODITY_ID;

    RETURN v_RET_VAL;

END GET_REALLOC_TYPE;
------------------------------------------------------------------------------
FUNCTION GET_CREDITED_PART_NAME(p_SELLER_ID IN NUMBER) RETURN VARCHAR2 AS

    v_RET_VAL PURCHASING_SELLING_ENTITY.PSE_NAME%TYPE;
BEGIN

    SELECT PSE.PSE_NAME
    INTO v_RET_VAL
    FROM PURCHASING_SELLING_ENTITY PSE
    WHERE PSE.PSE_ID = p_SELLER_ID;

    RETURN v_RET_VAL;

END GET_CREDITED_PART_NAME;
------------------------------------------------------------------------------
FUNCTION GET_TRAIT_VALUE
(
    p_TXN_ID         IN NUMBER,
    p_DATE           IN DATE,
    p_TRAIT_GROUP_ID IN NUMBER,
	p_TRAIT_INDEX	 IN NUMBER := 1,
	p_SET_NUMBER	 IN NUMBER := 1,
	p_STATEMENT_TYPE_ID IN NUMBER := 0
) RETURN VARCHAR2 AS

    v_RET_VAL IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;
BEGIN

    SELECT TRAIT_VAL
    INTO v_RET_VAL
    FROM IT_TRAIT_SCHEDULE T
    WHERE TRANSACTION_ID = p_TXN_ID
		AND SCHEDULE_STATE = GA.INTERNAL_STATE
	    AND SCHEDULE_DATE = TRUNC(p_DATE)+1/86400
	    AND TRAIT_GROUP_ID = p_TRAIT_GROUP_ID
	    AND TRAIT_INDEX = p_TRAIT_INDEX
		AND SET_NUMBER = p_SET_NUMBER
		AND STATEMENT_TYPE_ID = p_STATEMENT_TYPE_ID;

	RETURN v_RET_VAL;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;

END GET_TRAIT_VALUE;
------------------------------------------------------------------------------
FUNCTION GET_IDENTIFIER_EXT_ID
(
    p_DATE       IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLType IS
    v_RETURN XMLType;
BEGIN
    SELECT XMLElement("identifier", XMLAttributes(TRAIT_VAL AS "external_id"))
    INTO v_RETURN
    FROM IT_TRAIT_SCHEDULE A
    WHERE A.TRANSACTION_ID = p_TRANSACTION_ID
		AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
	    AND A.SCHEDULE_DATE = TRUNC(p_DATE)+1/86400
	    AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_EXT_IDENT
	    AND A.TRAIT_INDEX = 1
		AND SET_NUMBER = 1
		AND STATEMENT_TYPE_ID = 0;

    RETURN v_RETURN;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN NULL;
END GET_IDENTIFIER_EXT_ID;
------------------------------------------------------------------------------
FUNCTION GET_REALLOCATION_DETAIL
(
    p_AGREEMENT_TYPE IN VARCHAR2,
    p_HOUR           IN NUMBER,
    p_INTERVAL       IN NUMBER,
	p_MONETARY_VALUE IN NUMBER
) RETURN XMLTYPE IS

    v_RETURN XMLType;
BEGIN

    SELECT XMLElement("reallocation_detail",
                      XMLAttributes(TO_CHAR(p_HOUR) AS "start_hr",
                                    TO_CHAR(p_INTERVAL) AS "start_int",
                                    TO_CHAR(p_HOUR) AS "end_hr",
                                    TO_CHAR(p_INTERVAL) AS "end_int",
                                    p_AGREEMENT_TYPE AS "agreement_name",
                                    p_MONETARY_VALUE AS "monetary_value"))
    INTO v_RETURN
    FROM DUAL;

    RETURN v_RETURN;

END GET_REALLOCATION_DETAIL;
------------------------------------------------------------------------------
FUNCTION CREATE_SUBMISSION_XML
(
    p_DATE           IN DATE,
    p_TRANSACTION_ID IN NUMBER,
    p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
) RETURN XMLTYPE IS
    --creates XML for submission of SRA offer
    v_TXN_ATTR          INTERCHANGE_TRANSACTION%ROWTYPE;
    v_AGREEMENT_NAME    INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_CREDIT_PART_NAME  PURCHASING_SELLING_ENTITY.PSE_NAME%TYPE;
    v_REALLOCATION_TYPE VARCHAR2(16);
    v_MONETARY_VALUE    IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;
    v_START_TIME_VAL    IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;
    v_DATE              DATE;
    v_INTERVAL          NUMBER;
    v_HOUR              NUMBER;

    v_XML_SEQUENCE_TBL  XMLSEQUENCETYPE := XMLSEQUENCETYPE();
    v_XML_SETTL_REALLOC XMLType;

BEGIN
    --get transaction attributes
    SELECT *
    INTO v_TXN_ATTR
    FROM INTERCHANGE_TRANSACTION
    WHERE TRANSACTION_ID = p_TRANSACTION_ID;

    v_AGREEMENT_NAME := v_TXN_ATTR.AGREEMENT_TYPE;

    --get the CREDITED_PARTICIPANT_NAME from the INTERCHANGE_TRANSACTION.PURCHASER_ID
	v_CREDIT_PART_NAME := MM_SEM_UTIL.GET_PURCHASER_NAME(p_TRANSACTION_ID);

    --get REALLOCATION_TYPE
    v_REALLOCATION_TYPE := GET_REALLOC_TYPE(v_TXN_ATTR.COMMODITY_ID);

    --get the MONETARY_VALUE trait
    v_MONETARY_VALUE := GET_TRAIT_VALUE(p_TRANSACTION_ID, p_DATE,
                                        MM_SEM_UTIL.g_TG_SRA_VALUE);

    --get Start Time trait
    v_START_TIME_VAL := GET_TRAIT_VALUE(p_TRANSACTION_ID, p_DATE,
                                        MM_SEM_UTIL.g_TG_SRA_START_TIME);

	IF v_START_TIME_VAL IS NULL OR v_MONETARY_VALUE IS NULL
			OR v_REALLOCATION_TYPE IS NULL OR v_CREDIT_PART_NAME IS NULL
			OR v_AGREEMENT_NAME IS NULL THEN
		DECLARE
			v_FIELD VARCHAR2(32);
		BEGIN
			IF v_START_TIME_VAL IS NULL THEN
				v_FIELD := 'Start Time';
			ELSIF v_MONETARY_VALUE IS NULL THEN
				v_FIELD := 'Value';
			ELSIF v_REALLOCATION_TYPE IS NULL THEN
				v_FIELD := 'Reallocation Type (Commodity)';
			ELSIF v_CREDIT_PART_NAME IS NULL THEN
				v_FIELD := 'Credited Participant (Purchaser)';
			ELSIF v_AGREEMENT_NAME IS NULL THEN
				v_FIELD := 'Agreement Name';
			END If;
			-- log it and get out of here!
			p_LOGGER.LOG_ERROR('Cannot submit SRA "'||v_TXN_ATTR.TRANSACTION_NAME||'" because it is missing a required field: '||v_FIELD);
			RETURN NULL;
		END;
	END IF;

    v_DATE := DATE_TIME_AS_CUT(TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT),
  							   v_START_TIME_VAL,
							   MM_SEM_UTIL.g_TZ);
    -- start time is stored as interval-beginning, so add 30 minutes to convert to
    -- interval-ending
    v_DATE := v_DATE+1/48;
    --get the hour and interval
    v_HOUR     := MM_SEM_UTIL.GET_HOUR_FROM_DATE(v_DATE);
    v_INTERVAL := MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(v_DATE);

    -- Get Reallocation Detail
    v_XML_SEQUENCE_TBL.EXTEND;
    v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_REALLOCATION_DETAIL(v_AGREEMENT_NAME,
                                                                            v_HOUR,
                                                                            v_INTERVAL,
																			v_MONETARY_VALUE);
    --Get the Identifier external_id
	DECLARE
		v_XML XMLType;
	BEGIN
		v_XML :=  GET_IDENTIFIER_EXT_ID(p_DATE,p_TRANSACTION_ID);
		IF v_XML IS NOT NULL THEN
		    v_XML_SEQUENCE_TBL.EXTEND;
		    v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := v_XML;
		END IF;
	END;

    -- Concatenate all the childNodes under the parentNode <settlement_reallocation>
    SELECT XMLElement("sem_settlement_reallocation",
                      XMLAttributes(v_CREDIT_PART_NAME AS
                                    "credited_participant_name",
                                    v_REALLOCATION_TYPE AS "reallocation_type",
                                    g_XML_STANDING_FLAG AS "standing_flag",
                                    g_XML_VERS_NO AS "version_no"),
                      XMLConcat(CAST(v_XML_SEQUENCE_TBL AS XMLSequenceType)))
    INTO v_XML_SETTL_REALLOC
    FROM DUAL;

    RETURN v_XML_SETTL_REALLOC;
    --done

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating SRA submission XML (' ||
                           p_TRANSACTION_ID || ' for ' ||
                           TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
    	RETURN NULL;

END CREATE_SUBMISSION_XML;
------------------------------------------------------------------------------
FUNCTION CREATE_CANCELLATION_XML
(
    p_DATE           IN DATE,
    p_TRANSACTION_ID IN NUMBER,
    p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
) RETURN XMLTYPE IS
    --creates XML for submission of SRA offer
    v_TXN_ATTR          INTERCHANGE_TRANSACTION%ROWTYPE;
    v_AGREEMENT_NAME    INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_CREDIT_PART_NAME  PURCHASING_SELLING_ENTITY.PSE_NAME%TYPE;
    v_REALLOCATION_TYPE VARCHAR2(16);  
    v_XML_SETTL_REALLOC XMLType;

BEGIN
    --get transaction attributes
    SELECT *
    INTO v_TXN_ATTR
    FROM INTERCHANGE_TRANSACTION
    WHERE TRANSACTION_ID = p_TRANSACTION_ID;

    v_AGREEMENT_NAME := v_TXN_ATTR.AGREEMENT_TYPE;

    --get the CREDITED_PARTICIPANT_NAME from the INTERCHANGE_TRANSACTION.PURCHASER_ID
	v_CREDIT_PART_NAME := MM_SEM_UTIL.GET_PURCHASER_NAME(p_TRANSACTION_ID);

    --get REALLOCATION_TYPE
    v_REALLOCATION_TYPE := GET_REALLOC_TYPE(v_TXN_ATTR.COMMODITY_ID);

    --get the MONETARY_VALUE trait
  --  v_MONETARY_VALUE := GET_TRAIT_VALUE(p_TRANSACTION_ID, p_DATE,
  --                                      MM_SEM_UTIL.g_TG_SRA_VALUE);

    --get Start Time trait
  --  v_START_TIME_VAL := GET_TRAIT_VALUE(p_TRANSACTION_ID, p_DATE,
  --                                      MM_SEM_UTIL.g_TG_SRA_START_TIME);

	IF v_REALLOCATION_TYPE IS NULL OR v_CREDIT_PART_NAME IS NULL
			OR v_AGREEMENT_NAME IS NULL THEN
		DECLARE
			v_FIELD VARCHAR2(32);
		BEGIN		
			IF v_REALLOCATION_TYPE IS NULL THEN
				v_FIELD := 'Reallocation Type (Commodity)';
			ELSIF v_CREDIT_PART_NAME IS NULL THEN
				v_FIELD := 'Credited Participant (Purchaser)';
			ELSIF v_AGREEMENT_NAME IS NULL THEN
				v_FIELD := 'Agreement Name';
			END If;
			-- log it and get out of here!
			p_LOGGER.LOG_ERROR('Cannot submit SRA "'||v_TXN_ATTR.TRANSACTION_NAME||'" because it is missing a required field: '||v_FIELD);
			RETURN NULL;
		END;
	END IF;  

    -- Concatenate all the childNodes under the parentNode <settlement_reallocation>
    SELECT XMLElement("sem_settlement_reallocation",
                      XMLAttributes(v_CREDIT_PART_NAME AS
                                    "credited_participant_name",
                                    v_AGREEMENT_NAME AS "agreement_name",
                                    v_REALLOCATION_TYPE AS "reallocation_type",
												g_XML_VERS_NO AS "version_no"))                             
    INTO v_XML_SETTL_REALLOC
    FROM DUAL;

    RETURN v_XML_SETTL_REALLOC;
    --done

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating SRA submission XML (' ||
                           p_TRANSACTION_ID || ' for ' ||
                           TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
    	RETURN NULL;

END CREATE_CANCELLATION_XML;
------------------------------------------------------------------------------
FUNCTION CREATE_QUERY_XML
(
    p_DATE           IN DATE,
    p_TRANSACTION_ID IN NUMBER,
    p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
) RETURN XMLTYPE IS

    v_TXN_ATTR          INTERCHANGE_TRANSACTION%ROWTYPE;
    v_CREDIT_PART_NAME  PURCHASING_SELLING_ENTITY.PSE_NAME%TYPE;
    v_REALLOCATION_TYPE VARCHAR2(16);
    v_XML_SRA_QUERY     XMLType;

BEGIN

	IF p_TRANSACTION_ID = MM_SEM_UTIL.g_ALL THEN
	   SELECT XMLElement("sem_settlement_reallocation",
                         XMLAttributes(g_XML_STANDING_FLAG AS "standing_flag",
                         g_XML_VERS_NO AS "version_no"))
	   INTO v_XML_SRA_QUERY
       FROM DUAL;
	ELSE
		--get transaction attributes
		SELECT *
		INTO v_TXN_ATTR
		FROM INTERCHANGE_TRANSACTION
		WHERE TRANSACTION_ID = p_TRANSACTION_ID;

		--get the CREDITED_PARTICIPANT_NAME from the INTERCHANGE_TRANSACTION.PURCHASER_ID
		v_CREDIT_PART_NAME := MM_SEM_UTIL.GET_PURCHASER_NAME(p_TRANSACTION_ID);

		--get REALLOCATION_TYPE
		v_REALLOCATION_TYPE := GET_REALLOC_TYPE(v_TXN_ATTR.COMMODITY_ID);

		SELECT XMLElement("sem_settlement_reallocation",
						  XMLAttributes(v_CREDIT_PART_NAME AS "credited_participant_name",
						  				v_REALLOCATION_TYPE as "reallocation_type",
										g_XML_STANDING_FLAG AS "standing_flag",
										g_XML_VERS_NO AS "version_no"))
		INTO v_XML_SRA_QUERY
        FROM DUAL;
	END IF;
    RETURN v_XML_SRA_QUERY;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating SRA query XML (' ||
                           p_TRANSACTION_ID || ' for ' ||
                           TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);
        v_XML_SRA_QUERY := NULL;
        RETURN v_XML_SRA_QUERY;
        RAISE;


END CREATE_QUERY_XML;
------------------------------------------------------------------------------
FUNCTION VALUE_MATCHES
	(
	p_TRAIT_VAL1 IN VARCHAR2,
	p_TRAIT_VAL2 IN VARCHAR2,
	p_DAY IN DATE,
	p_METHOD IN CHAR := 's'
	) RETURN NUMBER IS
BEGIN
	CASE p_METHOD
	WHEN 'n' THEN
		IF TO_NUMBER(p_TRAIT_VAL1) = TO_NUMBER(p_TRAIT_VAL2) THEN
			RETURN 1;
		END IF;
	WHEN 'd' THEN
		IF TO_DATE(p_TRAIT_VAL1,MM_SEM_UTIL.g_DATE_FORMAT) = TO_DATE(p_TRAIT_VAL2,MM_SEM_UTIL.g_DATE_FORMAT) THEN
			RETURN 1;
		END IF;
	WHEN 't' THEN
		DECLARE
			v_DATE VARCHAR2(12) := TO_CHAR(p_DAY,'YYYY-MM-DD');
		BEGIN
			IF DATE_TIME_AS_CUT(v_DATE, p_TRAIT_VAL1, MM_SEM_UTIL.g_TZ) = DATE_TIME_AS_CUT(v_DATE, p_TRAIT_VAL2, MM_SEM_UTIL.g_TZ) THEN
				RETURN 1;
			END IF;
		END;
	WHEN 'u' THEN
		IF UPPER(p_TRAIT_VAL1) = UPPER(p_TRAIT_VAL2) THEN
			RETURN 1;
		END IF;
	WHEN 's' THEN
		IF p_TRAIT_VAL1 = p_TRAIT_VAL2 THEN
			RETURN 1;
		END IF;
	END CASE;

	-- no success...
	RETURN 0;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;
END VALUE_MATCHES;
------------------------------------------------------------------------------
FUNCTION GET_MATCHING_TRANSACTIONS
	(
	p_CANDIDATE_IDs IN NUMBER_COLLECTION,
	p_SCHEDULE_STATE IN NUMBER,
	p_CUT_SCHEDULE_DATE IN DATE,
	p_TRAIT_VAL IN VARCHAR2,
	p_TRAIT_GROUP_ID IN NUMBER,
	p_TRAIT_INDEX IN NUMBER := 1,
	p_SET_NUMBER IN NUMBER := 1,
	p_STATEMENT_TYPE_ID IN NUMBER := 0,
	p_METHOD IN CHAR := 's'
	) RETURN NUMBER_COLLECTION IS
v_RET NUMBER_COLLECTION;
BEGIN
	SELECT X.COLUMN_VALUE
	BULK COLLECT INTO v_RET
	FROM TABLE(CAST(p_CANDIDATE_IDs AS NUMBER_COLLECTION)) X,
		IT_TRAIT_SCHEDULE ITS
	WHERE ITS.TRANSACTION_ID = X.COLUMN_VALUE
		AND ITS.SCHEDULE_STATE = p_SCHEDULE_STATE
		AND ITS.SCHEDULE_DATE = p_CUT_SCHEDULE_DATE
		AND ITS.TRAIT_GROUP_ID = p_TRAIT_GROUP_ID
		AND ITS.TRAIT_INDEX = p_TRAIT_INDEX
		AND ITS.SET_NUMBER = p_SET_NUMBER
		AND ITS.STATEMENT_TYPE_ID = p_STATEMENT_TYPE_ID
		AND VALUE_MATCHES(ITS.TRAIT_VAL, p_TRAIT_VAL, p_CUT_SCHEDULE_DATE, p_METHOD) = 1
	ORDER BY 1;

	RETURN v_RET;
END GET_MATCHING_TRANSACTIONS;
------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_NAME
	(
	p_SELLER_NAME IN VARCHAR2,
	p_AGREEMENT_NAME IN VARCHAR2,
	p_ACCOUNT_NAME IN VARCHAR2,
	p_MARKET_ABBR IN VARCHAR2
	) RETURN VARCHAR2 IS
v_BASE_NAME VARCHAR2(64);
v_SUFFIX VARCHAR2(8);
v_RET VARCHAR2(64);
v_EXISTS BOOLEAN := TRUE;
v_COUNT BINARY_INTEGER;
v_IDX BINARY_INTEGER := 1;
BEGIN
	v_BASE_NAME := SUBSTR(p_MARKET_ABBR||': '||p_ACCOUNT_NAME||' to '||p_SELLER_NAME||', '||p_AGREEMENT_NAME, 1, 64);
	v_RET := v_BASE_NAME;

	WHILE v_EXISTS LOOP
		SELECT COUNT(1)
		INTO v_COUNT
		FROM INTERCHANGE_TRANSACTION
		WHERE TRANSACTION_NAME = v_RET;

		IF v_COUNT = 0 THEN
			v_EXISTS := FALSE;
		ELSE
			v_SUFFIX := ' ('||v_IDX||')';
			v_RET := SUBSTR(v_BASE_NAME,1,64-LENGTH(v_SUFFIX)) || v_SUFFIX;
			v_IDX := v_IDX + 1;
		END IF;

	END LOOP;

	RETURN v_RET;
END GET_TRANSACTION_NAME;
------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_ID
	(
	p_DATE IN DATE,
	p_START_HR IN NUMBER,
	p_START_INT IN NUMBER,
	p_PURCHASER_NAME IN VARCHAR2,
	p_COMMODITY_ID IN NUMBER,
	p_AGREEMENT_NAME IN VARCHAR2,
	p_ACCOUNT_NAME IN VARCHAR2,
	p_VALUE IN NUMBER
	) RETURN NUMBER IS

v_PURCHASER_ID NUMBER;
v_SELLER_ID NUMBER;
v_CANDIDATE_IDs NUMBER_COLLECTION;
v_INTERNAL_MATCH_IDs NUMBER_COLLECTION;
v_EXTERNAL_MATCH_IDs NUMBER_COLLECTION;
v_TXN_ID NUMBER := NULL;
v_START_DATE DATE;
v_SCHEDULE_DATE DATE;
v_START_TIME VARCHAR2(16);
v_MKT VARCHAR2(2);
v_SET_CONTRACT NUMBER(1);
v_CONTRACT_IDs NUMBER_COLLECTION;
v_TXN_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE; -- RSA -- 04/20/2007 -- BUG FIX
BEGIN

	v_PURCHASER_ID := MM_SEM_UTIL.GET_PSE_ID(p_PURCHASER_NAME, TRUE);
	v_SELLER_ID := MM_SEM_UTIL.GET_PSE_ID(p_ACCOUNT_NAME, TRUE);
	v_CONTRACT_IDs := MM_SEM_UTIL.SEM_CONTRACT_IDs(p_ACCOUNT_NAME);
	-- no contract for the seller? then this is an SRA w/ a counter-party that is not represented
	-- by this database - which is fine, so don't worry about finding transactions by contract.
	v_SET_CONTRACT := CASE WHEN v_CONTRACT_IDs.COUNT = 0 THEN 0 ELSE 1 END;

	-- get candidates
	BEGIN
    	SELECT TRANSACTION_ID
    	BULK COLLECT INTO v_CANDIDATE_IDs
    	FROM INTERCHANGE_TRANSACTION IT
			-- make sure transaction is an SEM transaction
    	WHERE IT.SC_ID = MM_SEM_UTIL.SEM_SC_ID
    		AND IT.IS_BID_OFFER = 1
			-- make sure it is a proper SRA that matches our criteria
    		AND IT.TRANSACTION_TYPE = 'SRA'
    		AND IT.SELLER_ID = v_SELLER_ID
			AND IT.PURCHASER_ID = v_PURCHASER_ID
    		AND IT.AGREEMENT_TYPE = p_AGREEMENT_NAME
			AND IT.COMMODITY_ID = p_COMMODITY_ID
			AND (v_SET_CONTRACT = 0 OR IT.CONTRACT_ID IN (SELECT COLUMN_VALUE FROM TABLE(CAST(v_CONTRACT_IDs as NUMBER_COLLECTION))))
			-- finally, make sure we aren't picking a transaction that's already been used
			AND NOT EXISTS (SELECT 1
							FROM TABLE(CAST(g_TRANSACTION_IDs_USED AS NUMBER_COLLECTION)) X
							WHERE X.COLUMN_VALUE = IT.TRANSACTION_ID)
		ORDER BY TRANSACTION_ID;
    EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_CANDIDATE_IDs := NUMBER_COLLECTION();
	END;

	IF v_CANDIDATE_IDs.COUNT > 0 THEN
		v_START_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(p_DATE, p_START_HR, p_START_INT);
        -- start time is in interval-beginning notation, not interval-ending
        -- so subtract 30 minutes to compensate
        v_START_DATE := v_START_DATE-1/48;
		v_START_TIME := SUBSTR(FROM_CUT_AS_HED(v_START_DATE,MM_SEM_UTIL.g_TZ,'MI30'),12);

		v_SCHEDULE_DATE := TRUNC(p_DATE)+1/86400; -- traits we're examining are all daily

		-- get all candidates with matching start time in internal state
		v_INTERNAL_MATCH_IDs := GET_MATCHING_TRANSACTIONS(
									v_CANDIDATE_IDs,
									GA.INTERNAL_STATE,
									v_SCHEDULE_DATE,
									v_START_TIME,
									MM_SEM_UTIL.g_TG_SRA_START_TIME,
									p_METHOD => 't'
									);
		IF v_INTERNAL_MATCH_IDs.COUNT > 0 THEN
			-- further filter this list to those with matching monetary
			-- value in internal state
			DECLARE
				v_MATCH_IDs NUMBER_COLLECTION;
			BEGIN
	    		v_MATCH_IDs := GET_MATCHING_TRANSACTIONS(
    								v_INTERNAL_MATCH_IDs,
    								GA.INTERNAL_STATE,
    								v_SCHEDULE_DATE,
    								p_VALUE,
    								MM_SEM_UTIL.g_TG_SRA_VALUE,
									p_METHOD => 'n'
    								);
				IF v_MATCH_IDs.COUNT > 0 THEN
					-- grab the first match
					v_TXN_ID := v_MATCH_IDs(v_MATCH_IDs.FIRST);
				END IF;
			END;
		END IF;

		-- no transactions match both start time and monetary value in internal state?
		IF v_TXN_ID IS NULL THEN
    		-- get all candidates with matching start time in *external* state
    		v_EXTERNAL_MATCH_IDs := GET_MATCHING_TRANSACTIONS(
    									v_CANDIDATE_IDs,
    									GA.EXTERNAL_STATE,
    									v_SCHEDULE_DATE,
    									v_START_TIME,
    									MM_SEM_UTIL.g_TG_SRA_START_TIME,
										p_METHOD => 't'
    									);
    		IF v_EXTERNAL_MATCH_IDs.COUNT > 0 THEN
    			-- further filter this list to those with matching monetary
    			-- value in *external* state
    			DECLARE
    				v_MATCH_IDs NUMBER_COLLECTION;
    			BEGIN
    	    		v_MATCH_IDs := GET_MATCHING_TRANSACTIONS(
        								v_EXTERNAL_MATCH_IDs,
        								GA.EXTERNAL_STATE,
        								v_SCHEDULE_DATE,
	    								p_VALUE,
	    								MM_SEM_UTIL.g_TG_SRA_VALUE,
										p_METHOD => 'n'
        								);
    				IF v_MATCH_IDs.COUNT > 0 THEN
    					-- grab the first match
    					v_TXN_ID := v_MATCH_IDs(v_MATCH_IDs.FIRST);
    				END IF;
    			END;
    		END IF;
		END IF;

		-- none match both values in external state? how about
		-- ones that just match the start time?
		IF v_TXN_ID IS NULL THEN
			IF v_INTERNAL_MATCH_IDs.COUNT > 0 THEN
				v_TXN_ID := v_INTERNAL_MATCH_IDs(v_INTERNAL_MATCH_IDs.FIRST);
			ELSIF v_EXTERNAL_MATCH_IDs.COUNT > 0 THEN
				v_TXN_ID := v_EXTERNAL_MATCH_IDs(v_EXTERNAL_MATCH_IDs.FIRST);
			ELSE -- none? then just grab the first candidate
				v_TXN_ID := v_CANDIDATE_IDs(v_CANDIDATE_IDs.FIRST);
			END IF;
		END IF;

	END IF;

	-- no appropriate candidates? then we'll create a new transaction
	IF v_TXN_ID IS NOT NULL THEN
		-- make sure transaction's date range includes this day
		UPDATE INTERCHANGE_TRANSACTION
			SET BEGIN_DATE = LEAST(p_DATE, BEGIN_DATE),
				END_DATE = GREATEST(p_DATE, END_DATE)
		WHERE TRANSACTION_ID = v_TXN_ID;
	ELSE
		v_MKT := UPPER(SUBSTR(EI.GET_ENTITY_ALIAS(EC.ED_IT_COMMODITY, p_COMMODITY_ID),1,2));
		v_TXN_NAME := GET_TRANSACTION_NAME(p_PURCHASER_NAME,p_AGREEMENT_NAME,p_ACCOUNT_NAME,v_MKT);
		-- create a new one
		EM.PUT_TRANSACTION(
            v_TXN_ID, --O_OID
            v_TXN_NAME,--P_TRANSACTION_NAME
            v_TXN_NAME,--P_TRANSACTION_ALIAS
            v_TXN_NAME,--P_TRANSACTION_DESC
            0,--P_TRANSACTION_ID
            'Active',--P_TRANSACTION_STATUS
            'SRA',--P_TRANSACTION_TYPE
            NULL,--P_TRANSACTION_IDENTIFIER
            0,--P_IS_FIRM
            0,--P_IS_IMPORT_SCHEDULE
            0,--P_IS_EXPORT_SCHEDULE
            0,--P_IS_BALANCE_TRANSACTION
            1,--P_IS_BID_OFFER
            0,--P_IS_EXCLUDE_FROM_POSITION
            0,--P_IS_IMPORT_EXPORT
            0,--P_IS_DISPATCHABLE
            'Day',--P_TRANSACTION_INTERVAL
            NULL,--P_EXTERNAL_INTERVAL
            NULL,--P_ETAG_CODE
            p_DATE,--P_BEGIN_DATE
            p_DATE,--P_END_DATE
            v_PURCHASER_ID,--P_PURCHASER_ID
            v_SELLER_ID,--P_SELLER_ID
            CASE WHEN v_CONTRACT_IDs.COUNT = 0 THEN 0 ELSE v_CONTRACT_IDs(v_CONTRACT_IDs.FIRST) END,--P_CONTRACT_ID
            MM_SEM_UTIL.SEM_SC_ID,--P_SC_ID
            0,--P_POR_ID
            0,--P_POD_ID
            p_COMMODITY_ID,--P_COMMODITY_ID
            0,--P_SERVICE_TYPE_ID
            0,--P_TX_TRANSACTION_ID
            0,--P_PATH_ID
            0,--P_LINK_TRANSACTION_ID
            0,--P_EDC_ID
            0,--P_PSE_ID
            0,--P_ESP_ID
            0,--P_POOL_ID
            0,--P_SCHEDULE_GROUP_ID
            0,--P_MARKET_PRICE_ID
            0,--P_ZOR_ID
            0,--P_ZOD_ID
            0,--P_SOURCE_ID
            0,--P_SINK_ID
            0,--P_RESOURCE_ID
            p_AGREEMENT_NAME,--P_AGREEMENT_TYPE
            NULL,--P_APPROVAL_TYPE
            NULL,--P_LOSS_OPTION
            'SRA',--P_TRAIT_CATEGORY
            0--P_TP_ID
			);
	END IF;

	-- Got it! Now mark this ID as used
	g_TRANSACTION_IDs_USED.EXTEND;
	g_TRANSACTION_IDs_USED(g_TRANSACTION_IDs_USED.LAST) := v_TXN_ID;

	RETURN v_TXN_ID;

END GET_TRANSACTION_ID;
------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_IDs
	(
	p_DATE IN DATE,
	p_ACCOUNT_NAME IN VARCHAR2,
	p_GATE_WINDOW IN VARCHAR2 DEFAULT NULL,
	p_RESPONSE IN XMLTYPE
	) RETURN NUMBER_COLLECTION IS

v_COMMODITY_ID NUMBER(9);
v_RET NUMBER_COLLECTION := NUMBER_COLLECTION();

CURSOR c_SRAs IS
	-- no order by - return IDs in the order the entries are defined in the XML doc
	SELECT EXTRACTVALUE(p_RESPONSE, '/sem_settlement_reallocation/@credited_participant_name') as PURCHASER_NAME,
		   EXTRACTVALUE(VALUE(D), '/reallocation_detail/@agreement_name') as AGREEMENT_NAME,
		   TO_NUMBER(EXTRACTVALUE(VALUE(D), '/reallocation_detail/@start_hr')) as START_HR,
		   TO_NUMBER(EXTRACTVALUE(VALUE(D), '/reallocation_detail/@start_int')) as START_INT,
		   TO_NUMBER(EXTRACTVALUE(VALUE(D), '/reallocation_detail/@monetary_value')) as VALUE,
		   EXTRACTVALUE(p_RESPONSE, '/sem_settlement_reallocation/@reallocation_type') as REALLOC_TYPE
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_RESPONSE,'/sem_settlement_reallocation/reallocation_detail'))) D;
BEGIN

	FOR v_SRA IN c_SRAs LOOP
		v_COMMODITY_ID := EI.GET_ID_FROM_ALIAS(g_REALLOC_TYPES(v_SRA.REALLOC_TYPE), EC.ED_IT_COMMODITY);

		v_RET.EXTEND;
		v_RET(v_RET.LAST) := GET_TRANSACTION_ID(p_DATE, v_SRA.START_HR, v_SRA.START_INT,
											   v_SRA.PURCHASER_NAME, v_COMMODITY_ID,
											   v_SRA.AGREEMENT_NAME, p_ACCOUNT_NAME,
											   v_SRA.VALUE);
	END LOOP;

	RETURN v_RET;

END GET_TRANSACTION_IDs;
------------------------------------------------------------------------------
PROCEDURE RESET_FOR_PARSE AS
BEGIN
	g_TRANSACTION_IDs_USED := NUMBER_COLLECTION();
END RESET_FOR_PARSE;
------------------------------------------------------------------------------
PROCEDURE IMPORT_SRA
	(
	p_TRANSACTION_ID IN NUMBER,
	p_TRADING_DATE IN DATE,
	p_START_HOUR IN NUMBER,
	p_START_INT IN NUMBER,
	p_EXT_ID IN VARCHAR2,
	p_SRA_AMOUNT IN NUMBER,
	p_VALIDITY_INDEX IN NUMBER,
	p_VALIDITY_STATUS IN NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) AS
v_START_DATE DATE;
v_SCHEDULE_DATE DATE;
v_START VARCHAR2(32);
BEGIN
    v_START_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(p_TRADING_DATE,p_START_HOUR,p_START_INT,1);
    -- start time needs to be in interval-beginning - so convert from interval-ending
    -- by substracting 30 minutes
    v_START_DATE := v_START_DATE-1/48;
	v_START := SUBSTR(FROM_CUT_AS_HED(v_START_DATE, MM_SEM_UTIL.g_TZ, 'MI30'),12);
	v_START := REPLACE(v_START,'::',':'); -- eliminate double-colons if present

    -- schedule date - 1 second past midnight
    v_SCHEDULE_DATE := TRUNC(p_TRADING_DATE)+1/86400;

	-- store the traits
	IF p_EXT_ID IS NOT NULL THEN
		TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TRANSACTION_ID, MM_SEM_UTIL.g_OFFER_SCHEDULE_STATE, 0, v_SCHEDULE_DATE, MM_SEM_UTIL.g_TG_EXT_IDENT, 1, 1, p_EXT_ID);
	END IF;

	IF v_START IS NOT NULL THEN
		TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TRANSACTION_ID, MM_SEM_UTIL.g_OFFER_SCHEDULE_STATE, 0, v_SCHEDULE_DATE, MM_SEM_UTIL.g_TG_SRA_START_TIME, 1, 1, v_START);
	END IF;

	IF p_SRA_AMOUNT IS NOT NULL THEN
		TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TRANSACTION_ID, MM_SEM_UTIL.g_OFFER_SCHEDULE_STATE, 0, v_SCHEDULE_DATE, MM_SEM_UTIL.g_TG_SRA_VALUE, 1, 1, p_SRA_AMOUNT);
	END IF;

	IF (p_VALIDITY_INDEX IS NOT NULL AND p_VALIDITY_STATUS IS NOT NULL) THEN
		-- set both internal
		TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TRANSACTION_ID, GA.INTERNAL_STATE, 0, v_SCHEDULE_DATE, MM_SEM_UTIL.g_TG_SRA_VALIDITY_STATUS, p_VALIDITY_INDEX, 1, p_VALIDITY_STATUS);
		-- and external
		TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TRANSACTION_ID, GA.EXTERNAL_STATE, 0, v_SCHEDULE_DATE, MM_SEM_UTIL.g_TG_SRA_VALIDITY_STATUS, p_VALIDITY_INDEX, 1, p_VALIDITY_STATUS);
	END IF;
END IMPORT_SRA;
------------------------------------------------------------------------------
FUNCTION PARSE_QUERY_XML
	(
	p_TRANSACTION_IDs IN NUMBER_COLLECTION,
	p_DATE IN DATE,
	p_RESPONSE IN XMLTYPE,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN VARCHAR2 IS

v_ERRORS VARCHAR2(4000);
v_IDX BINARY_INTEGER;
v_COUNT BINARY_INTEGER;
v_TRANSACTION_ID NUMBER(9);

CURSOR c_SRAs IS
	-- no order by means we rely on order of elements defined in XML - that is the same order of
	-- IDs in the p_TRANSACTION_IDs collection
	SELECT EXTRACTVALUE(p_RESPONSE, '/sem_settlement_reallocation/identifier/@external_id') as EXT_ID,
		   EXTRACTVALUE(VALUE(D), '/reallocation_detail/@start_hr') as START_HR,
		   EXTRACTVALUE(VALUE(D), '/reallocation_detail/@start_int') as START_INT,
		   EXTRACTVALUE(VALUE(D), '/reallocation_detail/@monetary_value') as VALUE
	FROM TABLE(XMLSEQUENCE(EXTRACT(p_RESPONSE,'/sem_settlement_reallocation/reallocation_detail'))) D;
BEGIN
	--First check for errors
	v_ERRORS := MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE);

	IF v_ERRORS IS NOT NULL THEN
	  	RETURN v_ERRORS;
	ELSE
		-- The transaction will have the correct credited participant, agreement name,
		-- and commodity - because those are the fields required by GET_TRANSACTION_IDs.
		-- So all that remains: external identifier, start interval, and monetary value

		v_IDX := p_TRANSACTION_IDs.FIRST;
		v_COUNT := 0;

		FOR v_SRA IN c_SRAs LOOP
			v_COUNT := v_COUNT+1;
			IF NOT p_TRANSACTION_IDs.EXISTS(v_IDX) THEN
				p_LOGGER.LOG_ERROR('Importing SRAs: insufficient number ('||p_TRANSACTION_IDs.COUNT||') of transaction IDs');
				RETURN NULL;
			ELSE
				v_TRANSACTION_ID := p_TRANSACTION_IDs(v_IDX);
			END IF;

			IMPORT_SRA(v_TRANSACTION_ID,
					   p_DATE,
					   v_SRA.START_HR,
					   v_SRA.START_INT,
					   v_SRA.EXT_ID,
					   v_SRA.VALUE,
					   NULL, -- VALIDITY_STATUS? not available until we download RAR
						NULL,
					   p_LOGGER);

			v_IDX := p_TRANSACTION_IDs.NEXT(v_IDX);
		END LOOP;

		-- too many transaction IDs?
		IF p_TRANSACTION_IDs.EXISTS(v_IDX) THEN
			p_LOGGER.LOG_ERROR('Importing SRAs: superfluous number ('||p_TRANSACTION_IDs.COUNT||') of transaction IDs (only '||v_COUNT||' needed)');
		END IF;

		RETURN NULL;
	END IF;

END PARSE_QUERY_XML;
------------------------------------------------------------------------------
FUNCTION PARSE_SUBMISSION_RESPONSE_XML
	(
	p_TRANSACTION_IDs IN NUMBER_COLLECTION,
	p_DATE IN DATE,
	p_RESPONSE IN XMLTYPE,
	 p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN VARCHAR2 IS
BEGIN
	RETURN MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE);
END PARSE_SUBMISSION_RESPONSE_XML;
------------------------------------------------------------------------------
BEGIN
	g_REALLOC_TYPES(g_ENERGY_REALLOC_TYPE) := g_ENERGY_ALIAS;
	g_REALLOC_TYPES(g_CAPACITY_REALLOC_TYPE) := g_CAPACITY_ALIAS;
END MM_SEM_SRA_OFFER;
/
