CREATE OR REPLACE PACKAGE BODY MM_SEM_LOAD_OFFER IS
------------------------------------------------------------------------------
g_LO_ALLOWED_TAGS MM_SEM_OFFER_UTIL.MAP_OF_STRING_SETS;
g_LO_TAG_OPERATIONS MM_SEM_OFFER_UTIL.TYPE_OF_OPERATIONS;
------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.2 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_SHUTDOWN_COST
(
    p_CUT_TIME       IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLType IS
    v_RETURN XMLType;
BEGIN
    BEGIN
        SELECT XMLElement("shutdown_cost",
                          XMLAttributes(trait_val AS "value"))
        INTO   v_RETURN
        FROM   (SELECT TRAIT_GROUP_ID, TRAIT_INDEX, TRAIT_VAL
                FROM   IT_TRAIT_SCHEDULE A
                WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                       AND A.SCHEDULE_DATE = p_CUT_TIME
                       AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_LOAD_SHUTDOWN_COST
                       AND A.TRAIT_INDEX = 1
                       AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
					   AND A.STATEMENT_TYPE_ID = 0);
        RETURN v_RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;
END GET_SHUTDOWN_COST;
------------------------------------------------------------------------------
-- RSA -- 06/07/2007
FUNCTION CREATE_SUBMISSION_XML
	(
	p_DATE IN DATE,
	p_TRANSACTION_ID IN NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN XMLTYPE IS
    v_RESOURCE_NAME          SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
    v_RESOURCE_TYPE          TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
    v_XML_SEQUENCE_TBL       XMLSequenceType := XMLSequenceType();
    v_XML_PRICE_TAKER_DETAIL XMLType;
    v_CUT_BEGIN_DATE         DATE;
    v_CUT_END_DATE           DATE;
    v_IS_STANDING_BID        BOOLEAN;
    v_STANDING_FLAG          VARCHAR2(5) := 'false';
    v_IS_UNDER_TEST          BOOLEAN;
    v_RO_RESOURCE_TYPE       VARCHAR2(10);
    v_PRICE_MAKER_TAKER_TAG  VARCHAR2(32);
    v_XML_NOMINATION_PROFILE XMLType;
    v_XML_DECREMENTAL_PRICE  XMLType;
    v_PQ_CURVE               XMLType;
    v_SHUTDOWN_COST          XMLType;
    v_XML                    XMLType;
BEGIN
	MM_SEM_UTIL.OFFER_DATE_RANGE(p_DATE, p_DATE, v_CUT_BEGIN_DATE, v_CUT_END_DATE);
    v_RESOURCE_NAME     := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);
    v_IS_UNDER_TEST     := MM_SEM_UTIL.IS_UNDER_TEST(p_TRANSACTION_ID,
                                                     p_DATE);

    v_RO_RESOURCE_TYPE := MM_SEM_UTIL.GET_RESOURCE_TYPE(p_TRANSACTION_ID,
                                                        p_DATE);
    v_RESOURCE_TYPE    := GET_DICTIONARY_VALUE(v_RO_RESOURCE_TYPE,
                                           0,
                                           'MarketExchange',
                                           'SEM',
                                           'Offer Resource');

    --Determine if is a standing bid, add Standing element if true
    v_IS_STANDING_BID := MM_SEM_UTIL.IS_STANDING_BID(p_TRANSACTION_ID,
                                                 p_DATE);
    IF v_IS_STANDING_BID THEN
        v_STANDING_FLAG := 'true';
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.LAST) := MM_SEM_OFFER_UTIL.GET_STANDING(p_DATE +
                                                                     k_1_SEC,
                                                                     p_TRANSACTION_ID);

    END IF;

    IF v_IS_UNDER_TEST THEN
        v_PRICE_mAKER_tAKER_TAG := 'price_taker_detail';
    ELSIF NOT v_IS_UNDER_TEST THEN
        v_PRICE_mAKER_tAKER_TAG := 'price_maker_detail';
    END IF;

    -- Get External Id
    v_XML := MM_SEM_OFFER_UTIL.GET_EXTERNAL_ID(p_DATE + k_1_SEC, p_TRANSACTION_ID);
    IF v_XML IS NOT NULL THEN
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.LAST) := v_XML;
    END IF;

    --FORECAST
    v_XML_SEQUENCE_TBL.EXTEND;
    v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.LAST) := MM_SEM_OFFER_UTIL.GET_FORECAST(v_CUT_BEGIN_DATE,
                                                                 v_CUT_END_DATE,
                                                                 p_TRANSACTION_ID);

    v_SHUTDOWN_COST           := GET_SHUTDOWN_COST(p_DATE +
                                                     k_1_SEC,
                                                     p_TRANSACTION_ID);
    v_XML_NOMINATION_PROFILE := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_NOM_PROFILE(v_CUT_BEGIN_DATE,
                                                       v_CUT_END_DATE,
                                                       p_TRANSACTION_ID);
    v_XML_DECREMENTAL_PRICE  := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_DEC_PRICE(v_CUT_BEGIN_DATE,
                                                      v_CUT_END_DATE,
                                                      p_TRANSACTION_ID);
    v_PQ_CURVE := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_PQ_CURVE(p_DATE + k_1_SEC, p_TRANSACTION_ID);

    v_XML_SEQUENCE_TBL.EXTEND;
    IF v_PRICE_MAKER_TAKER_TAG = 'price_maker_detail' THEN
        SELECT XMLAgg(XMLElement("price_maker_detail",
                                 XMLConcat(v_PQ_CURVE,
                                           v_SHUTDOWN_COST
                                           )))
        INTO   v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.LAST)
        FROM   DUAL;
    ELSE
        SELECT XMLAgg(XMLElement("price_taker_detail",
                                 XMLConcat(v_XML_NOMINATION_PROFILE,
                                           v_XML_DECREMENTAL_PRICE
                                           )))
        INTO   v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.LAST)
        FROM   DUAL;
    END IF;

    -- Concatenate all the childNodes under the parentNode <PRICE_TAKER_DETAIL>
    SELECT XMLElement("sem_demand_offer",
                      XMLAttributes(v_RESOURCE_NAME AS "resource_name",
                                    v_RESOURCE_TYPE AS "resource_type",
                                    v_STANDING_FLAG AS "standing_flag",
                                    k_VERSION_NO AS "version_no"),
                      XMLConcat(CAST(v_XML_SEQUENCE_TBL AS XMLSequenceType)))
    INTO   v_XML_PRICE_TAKER_DETAIL
    FROM   DUAL;

    RETURN v_XML_PRICE_TAKER_DETAIL;

    EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating Load Offer submission XML (' ||
                           p_TRANSACTION_ID || ' for ' ||
                           TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);

        v_XML_PRICE_TAKER_DETAIL := NULL;
        RETURN v_XML_PRICE_TAKER_DETAIL;
        RAISE;
END CREATE_SUBMISSION_XML;
------------------------------------------------------------------------------
FUNCTION CREATE_QUERY_XML
	(
	p_DATE IN DATE,
	p_TRANSACTION_ID IN NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN XMLTYPE IS
    v_RESOURCE_NAME          SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
	v_IS_STANDING_BID        BOOLEAN;
    v_STANDING_FLAG          VARCHAR2(5) := 'false';
    v_XML                    XMLType;
BEGIN
    IF p_TRANSACTION_ID = MM_SEM_UTIL.g_ALL THEN
		SELECT XMLElement("sem_demand_offer", XMLAttributes(v_STANDING_FLAG AS "standing_flag",
														  '1.0' AS "version_no"))
		INTO v_XML FROM DUAL;
	ELSE
	    v_RESOURCE_NAME := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);

		--Determine if is a standing bid, add Standing element if true
		v_IS_STANDING_BID := MM_SEM_UTIL.IS_STANDING_BID(p_TRANSACTION_ID,
														 p_DATE);
		IF v_IS_STANDING_BID THEN
			v_STANDING_FLAG := 'true';
		END IF;
		SELECT XMLElement("sem_demand_offer", XMLAttributes(v_STANDING_FLAG AS "standing_flag",
														  '1.0' AS "version_no",
														   v_RESOURCE_NAME AS "resource_name"))
		INTO v_XML FROM DUAL;
	END IF;
    RETURN v_XML;

    EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating Load Offer Query XML (' ||
                           p_TRANSACTION_ID || ' for ' ||
                           TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);

        v_XML := NULL;
        RETURN v_XML;
        RAISE;
END CREATE_QUERY_XML;
------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_IDs
	(
	p_DATE IN DATE,
	p_ACCOUNT_NAME IN VARCHAR2,
	p_GATE_WINDOW IN VARCHAR2,
	p_RESPONSE IN XMLTYPE
	) RETURN NUMBER_COLLECTION IS
BEGIN
	RETURN NUMBER_COLLECTION( MM_SEM_OFFER_UTIL.GET_TRANSACTION_ID_FOR_RES('Load', p_ACCOUNT_NAME, p_GATE_WINDOW, p_RESPONSE) );
END GET_TRANSACTION_IDs;
------------------------------------------------------------------------------
FUNCTION PARSE_QUERY_XML
(
	p_TRANSACTION_IDs IN NUMBER_COLLECTION,
	p_DATE           IN DATE,
	p_RESPONSE       IN XMLTYPE,
	p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
) RETURN VARCHAR2 IS

	v_PARSER_MESSAGE VARCHAR2(1024) := NULL;
	v_TRANSACTION_ID NUMBER;

BEGIN
	IF p_TRANSACTION_IDs.COUNT <> 1 THEN
		RETURN 'Expecting single transaction ID - received '||p_TRANSACTION_IDs.COUNT||' IDs!';
	END IF;

	v_TRANSACTION_ID := p_TRANSACTION_IDs(p_TRANSACTION_IDs.FIRST);

	v_PARSER_MESSAGE := MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE);

	IF v_PARSER_MESSAGE IS NOT NULL THEN
	   RETURN v_PARSER_MESSAGE;
	END IF;

	-- Delete the Trait values for this transaction
	MM_SEM_OFFER_UTIL.PURGE_IT_TRAIT_SCHEDULE(p_DATE, v_TRANSACTION_ID);

	-- Import the traits
	MM_SEM_OFFER_UTIL.IMPORT_TRAITS(p_RESPONSE, p_DATE,
							   FALSE, v_TRANSACTION_ID, g_LO_ALLOWED_TAGS, g_LO_TAG_OPERATIONS,
							   NULL, NULL, NULL, NULL, p_LOGGER);

	RETURN NULL;

	EXCEPTION
	   WHEN OTHERS THEN
		  p_LOGGER.LOG_ERROR('Error parsing Load Offer submission XML (' ||
						   ENTITY_NAME_FROM_IDS(EC.ED_TRANSACTION, v_TRANSACTION_ID) || ' for ' ||
						   TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
						   MM_SEM_UTIL.ERROR_STACKTRACE);

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
  -- Load Offer XML Tag MetaData
  -- Allowed Tags(Parent/Child) mapping
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_SEM_LOAD_OFFER)('') := TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_SEM_LOAD_OFFER):= TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_STANDING)(MM_SEM_OFFER_UTIL.g_TAG_SEM_LOAD_OFFER) := TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_STANDING):= TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER)(MM_SEM_OFFER_UTIL.g_TAG_SEM_LOAD_OFFER) := TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST)(MM_SEM_OFFER_UTIL.g_TAG_SEM_LOAD_OFFER) := TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_FORECAST):= TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL)(MM_SEM_OFFER_UTIL.g_TAG_SEM_LOAD_OFFER) := TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL):= TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL) := TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_SHUTDOWN_COST)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL) := TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL)(MM_SEM_OFFER_UTIL.g_TAG_SEM_LOAD_OFFER) := TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL):= TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE):= TRUE;
  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_POINT)(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE) := TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE) := TRUE;

  g_LO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE) := TRUE;

  -- Tags/Attributes
  -- Messages
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_NO_OP;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
  -- Standing
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Expiry
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_STANDING_OFFER;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).TRAIT_IDX := MM_SEM_UTIL.G_TI_STANDING_EXPIRY_DATE;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Type
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_STANDING_OFFER;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_IDX := MM_SEM_UTIL.G_TI_STANDING_TYPE;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Identifier
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- External Identifier Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_EXT_IDENT;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Forecast
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Minimum MW Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_MW).TRAIT_IDX := MM_SEM_UTIL.G_TI_GEN_FORECAST_MIN;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
      -- Maximum MW Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).TRAIT_IDX := MM_SEM_UTIL.G_TI_GEN_FORECAST_MAX;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
      -- Minimum Output MW Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_OP_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_OP_MW).TRAIT_IDX := MM_SEM_UTIL.G_TI_GEN_FORECAST_MIN_OUTPUT;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_OP_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Price Maker Details
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_CONTAINER;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
  -- Price Taker Details
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_CONTAINER;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
  -- PQ Curve
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_SERIES;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
  -- PQ Point
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Price Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).TRAIT_GROUP_ID := TG.g_TG_OFFER_CURVE;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).TRAIT_IDX := TG.g_TI_OFFER_PRICE;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Quantity Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).TRAIT_GROUP_ID := TG.g_TG_OFFER_CURVE;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).TRAIT_IDX := TG.g_TI_OFFER_QUANTITY;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Shutdown cost
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SHUTDOWN_COST).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SHUTDOWN_COST).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Value Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SHUTDOWN_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_LOAD_SHUTDOWN_COST;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SHUTDOWN_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SHUTDOWN_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
   -- Nomination Profile
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Value Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_NOM_PROFILE;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Decremental Price
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Value Attribute
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_DEC_PRICE;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_LO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;

END MM_SEM_LOAD_OFFER;
/
