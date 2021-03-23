CREATE OR REPLACE PACKAGE BODY MM_SEM_IC_OFFER IS

--g_XML_NODE_NAME CONSTANT VARCHAR2(32) := 'sem_interconnector_offer';
g_XML_VERS_NO CONSTANT VARCHAR2(8) := '1.0';
g_1_SEC         CONSTANT INTERVAL DAY TO SECOND := INTERVAL '1' SECOND;
g_IO_ALLOWED_TAGS MM_SEM_OFFER_UTIL.MAP_OF_STRING_SETS;
g_IO_TAG_OPERATIONS MM_SEM_OFFER_UTIL.TYPE_OF_OPERATIONS;

/*----------------------------------------------------------------------------*
*   WHAT_VERSION                                                             *
*----------------------------------------------------------------------------*/
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
 RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_IDs
	(
	p_DATE IN DATE,
	p_ACCOUNT_NAME IN VARCHAR2,
	p_GATE_WINDOW IN VARCHAR2,
	p_RESPONSE IN XMLTYPE
	) RETURN NUMBER_COLLECTION IS
BEGIN
	RETURN NUMBER_COLLECTION( MM_SEM_OFFER_UTIL.GET_TRANSACTION_ID_FOR_RES('Nomination', p_ACCOUNT_NAME, p_GATE_WINDOW, p_RESPONSE) );
END GET_TRANSACTION_IDs;
-------------------------------------------------------------------------------
FUNCTION GET_IC_CAPACITY
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN

    SELECT XMLAgg(XMLElement("interconnector_capacity",
                             XMLAttributes(MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS "start_int",
                                           MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS "end_int",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS "start_hr",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS "end_hr",
                                           TRAIT_VAL1 AS "maximum_import_capacity_mw",
                                           TRAIT_VAL2 AS "maximum_export_capacity_mw"))
                  )
    INTO   v_RETURN
    FROM   (SELECT SCHEDULE_DATE,
                   MAX(decode(TRAIT_INDEX, MM_SEM_UTIL.g_TI_IC_MAX_IMPORT, cnt, NULL)) TRAIT_VAL1,
                   MAX(decode(TRAIT_INDEX, MM_SEM_UTIL.g_TI_IC_MAX_EXPORT, cnt, NULL)) TRAIT_VAL2
            FROM   (SELECT TRAIT_INDEX, SCHEDULE_DATE, MAX(TRAIT_VAL) cnt
                    FROM   IT_TRAIT_SCHEDULE A
                    WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                           AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
                           AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_IC_MAX_CAP
						   AND A.TRAIT_INDEX BETWEEN MM_SEM_UTIL.g_TI_IC_MAX_IMPORT AND MM_SEM_UTIL.g_TI_IC_MAX_EXPORT
						   AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
						   AND A.STATEMENT_TYPE_ID = 0
                    GROUP  BY TRAIT_INDEX, SCHEDULE_DATE)
            GROUP  BY SCHEDULE_DATE);

    RETURN v_RETURN;


END GET_IC_CAPACITY;
-------------------------------------------------------------------------------
FUNCTION GET_PQ_CURVE
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS

    v_RETURN       XMLType;
    doc            xmldom.DOMDocument;
    docElement     xmldom.DOMElement;
    elementPQCurve xmldom.DOMElement;
    elementPoint   xmldom.DOMElement;
    nodePQ         xmldom.DOMNode;
    nodeCurr       xmldom.DOMNode;
    TYPE t_PQ_RECORD IS RECORD(
        PRICE    NUMBER,
        QUANTITY NUMBER);
    TYPE t_PQ_REC_TYPE IS TABLE OF t_PQ_RECORD INDEX BY PLS_INTEGER;
    v_PQ_REC_TBL t_PQ_REC_TYPE;
BEGIN


    BEGIN
        doc := xmldom.newDomDocument;

        -- RSA -- remember DOM needs a doc-element. So, let's have one defined even if SMO documentation
        -- is not clear on this one. We will return only the children to the invoking function.
        docElement := xmldom.createElement(doc, 'doc_element');

        FOR v_INT IN (SELECT DISTINCT MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) START_HR,
                                MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) START_INT,
                                MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) END_HR,
                                MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) END_INT,
								SCHEDULE_DATE
                         FROM IT_TRAIT_SCHEDULE
                         WHERE TRANSACTION_ID = p_TRANSACTION_ID
							 AND SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
							 AND TRAIT_GROUP_ID = TG.g_TG_OFFER_CURVE
							 AND TRAIT_INDEX BETWEEN TG.g_TI_OFFER_PRICE AND TG.g_TI_OFFER_QUANTITY
							 AND SCHEDULE_STATE = GA.INTERNAL_STATE
							 AND STATEMENT_TYPE_ID = 0
               ORDER BY SCHEDULE_DATE
							 ) LOOP
            elementPQCurve := xmldom.createElement(doc, 'pq_curve');
            xmldom.setAttribute(elementPQCurve, 'start_hr', v_INT.START_HR);
            xmldom.setAttribute(elementPQCurve, 'start_int', v_INT.START_INT);
            xmldom.setAttribute(elementPQCurve, 'end_hr', v_INT.END_HR);
            xmldom.setAttribute(elementPQCurve, 'end_int', v_INT.END_INT);
            nodePQ := xmldom.appendChild(xmldom.makeNode(docElement),
                                         xmldom.makeNode(elementPQCurve));

            FOR v_SET IN (SELECT TRAIT_INDEX, SET_NUMBER, TRAIT_VAL
                             FROM IT_TRAIT_SCHEDULE
                             WHERE TRANSACTION_ID = p_TRANSACTION_ID
								 AND SCHEDULE_DATE =  v_INT.Schedule_Date
								 AND TRAIT_GROUP_ID = TG.g_TG_OFFER_CURVE
								 AND TRAIT_INDEX BETWEEN TG.g_TI_OFFER_PRICE AND TG.g_TI_OFFER_QUANTITY
								 AND SCHEDULE_STATE = GA.INTERNAL_STATE
								 AND STATEMENT_TYPE_ID = 0
                             ORDER BY TRAIT_INDEX) LOOP
                IF v_SET.TRAIT_INDEX = TG.g_TI_OFFER_PRICE THEN
                    v_PQ_REC_TBL(v_SET.SET_NUMBER).PRICE := v_SET.TRAIT_VAL;
                ELSIF v_SET.TRAIT_INDEX = TG.g_TI_OFFER_QUANTITY THEN
                    v_PQ_REC_TBL(v_SET.SET_NUMBER).QUANTITY := v_SET.TRAIT_VAL;
                END IF;
            END LOOP;

            --RSA -- pq info is now available
            FOR I IN 1 .. v_PQ_REC_TBL.COUNT LOOP
                elementPoint := xmldom.createElement(doc, 'point');
                xmldom.setAttribute(elementPoint,
                                    'price',
                                    v_PQ_REC_TBL(I).PRICE);
                xmldom.setAttribute(elementPoint,
                                    'quantity',
                                    v_PQ_REC_TBL(I).QUANTITY);
                nodeCurr := xmldom.appendChild(nodePQ,
                                               xmldom.makeNode(elementPoint));
            END LOOP;
            v_PQ_REC_TBL.DELETE;
        END LOOP;

        nodeCurr := xmldom.appendChild(xmldom.makeNode(doc),
                                       xmldom.makeNode(docElement));
        -- RSA -- strip away the "doc_element". Later, if SMO doc is clear and if it indeed needs a
        -- parent element that encloses all pq_curve info, then rename this info and remove
        -- the extract portion
        --v_RETURN := xmldom.getXMLType(doc).extract('/doc_element/*');
        v_RETURN := xmldom.getXMLType(doc).extract('//doc_element/*');
        xmldom.freeDocument(doc);

    EXCEPTION
        WHEN OTHERS THEN
            xmldom.freeDocument(doc);
    END;
    RETURN v_RETURN;
END GET_PQ_CURVE;
-------------------------------------------------------------------------------
FUNCTION CREATE_SUBMISSION_XML
	(
	p_DATE IN DATE,
	p_TRANSACTION_ID IN NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
	) RETURN XMLTYPE IS
	--create XML for submission of interconnector offer

    v_RESOURCE_NAME          SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
    v_RESOURCE_TYPE          TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
	v_RO_RESOURCE_TYPE       VARCHAR2(10);
    v_XML_SEQUENCE_TBL       XMLSequenceType := XMLSequenceType();
    v_XML_IC_OFFER           XMLType;
    v_CUT_BEGIN_DATE         DATE;
    v_CUT_END_DATE           DATE;

    v_IS_STANDING_BID        BOOLEAN;
    v_STANDING_FLAG          VARCHAR2(5) := 'false'; -- RSA -- bug-fix -- 07/24/2007

BEGIN
    MM_SEM_UTIL.OFFER_DATE_RANGE(p_DATE, p_DATE, v_CUT_BEGIN_DATE, v_CUT_END_DATE);

    v_RESOURCE_NAME := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);

	-- 2007-sep-20, jbc: look up resource type from system settings, don't use directly from svc point
	v_RO_RESOURCE_TYPE := MM_SEM_UTIL.GET_RESOURCE_TYPE(p_TRANSACTION_ID, p_DATE);
    v_RESOURCE_TYPE    := GET_DICTIONARY_VALUE(v_RO_RESOURCE_TYPE,
                                           0,
                                           'MarketExchange',
                                           'SEM',
                                           'Offer Resource');

    --Determine if is a standing bid, add Standing element if true
    v_IS_STANDING_BID := MM_SEM_UTIL.IS_STANDING_BID(p_TRANSACTION_ID, p_DATE);
    IF v_IS_STANDING_BID THEN
    	v_STANDING_FLAG:= 'true';
    	v_XML_SEQUENCE_TBL.EXTEND;
    	v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := MM_SEM_OFFER_UTIL.GET_STANDING(p_DATE + g_1_SEC,
					                                                                   p_TRANSACTION_ID);

    END IF;

    --Get the Identifier external_id
    v_XML_SEQUENCE_TBL.EXTEND;
    v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := MM_SEM_OFFER_UTIL.GET_EXTERNAL_ID(p_DATE + g_1_SEC,
					                                                                   p_TRANSACTION_ID);

    --Get Interconnector Capacity
    v_XML_SEQUENCE_TBL.EXTEND;
    v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_IC_CAPACITY(v_CUT_BEGIN_DATE,
                                                                    v_CUT_END_DATE,
                                                                    p_TRANSACTION_ID);

    --Get PQ_CURVE
    v_XML_SEQUENCE_TBL.EXTEND;
    v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_PQ_CURVE(v_CUT_BEGIN_DATE,
                                                                 v_CUT_END_DATE,
                                                                 p_TRANSACTION_ID);

    -- Concatenate all the childNodes under the parentNode <sem_interconnector_offer>
    SELECT XMLElement("sem_interconnector_offer",
                      XMLAttributes(v_STANDING_FLAG AS "standing_flag",
                      						  g_XML_VERS_NO AS "version_no",
                                    v_RESOURCE_NAME AS "resource_name",
                                    v_RESOURCE_TYPE AS "resource_type"
                                    ),
                      XMLConcat(CAST(v_XML_SEQUENCE_TBL AS XMLSequenceType)))
    INTO v_XML_IC_OFFER
    FROM DUAL;

    RETURN v_XML_IC_OFFER;

 EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating Interconnector Offer submission XML (' ||
                           p_TRANSACTION_ID || ' for ' ||
                           TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);

        v_XML_IC_OFFER := NULL;
        RETURN v_XML_IC_OFFER;
        RAISE;

END CREATE_SUBMISSION_XML;
------------------------------------------------------------------------------
FUNCTION CREATE_QUERY_XML
(
    p_DATE           IN DATE,
    p_TRANSACTION_ID IN NUMBER,
    p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
) RETURN XMLTYPE IS

    v_XML_IC_OFFER     XMLType;
    v_RESOURCE_NAME    SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
	v_IS_STANDING_BID  BOOLEAN;
	v_STANDING_FLAG    VARCHAR2(5) := 'false';

BEGIN

    IF p_TRANSACTION_ID = MM_SEM_UTIL.g_ALL THEN
	   SELECT XMLElement("sem_interconnector_offer", XMLAttributes(v_STANDING_FLAG AS "standing_flag",
                                                                   '1.0' AS "version_no"))
       INTO v_XML_IC_OFFER FROM DUAL;
	ELSE
	   v_RESOURCE_NAME := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);
	   --Determine if is a standing bid, add Standing element if true
		v_IS_STANDING_BID := MM_SEM_UTIL.IS_STANDING_BID(p_TRANSACTION_ID,
														 p_DATE);
		IF v_IS_STANDING_BID THEN
			v_STANDING_FLAG := 'true';
		END IF;

	   SELECT XMLElement("sem_interconnector_offer", XMLAttributes(v_STANDING_FLAG AS "standing_flag",
                                                                   '1.0' AS "version_no",
																   v_RESOURCE_NAME AS "resource_name"))
       INTO v_XML_IC_OFFER FROM DUAL;
	END IF;

    RETURN v_XML_IC_OFFER;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR('Error creating Interconnector Offer query XML (' ||
                           p_TRANSACTION_ID || ' for ' ||
                           TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                           MM_SEM_UTIL.ERROR_STACKTRACE);

        v_XML_IC_OFFER := NULL;
        RETURN v_XML_IC_OFFER;
        RAISE;
END CREATE_QUERY_XML;
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
							   FALSE, v_TRANSACTION_ID, g_IO_ALLOWED_TAGS, g_IO_TAG_OPERATIONS,
							   NULL, NULL, NULL, NULL, p_LOGGER);

	RETURN NULL;

	EXCEPTION
	   WHEN OTHERS THEN
		  p_LOGGER.LOG_ERROR('Error parsing Interconnector Offer submission XML (' ||
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
  -- Nominations Offer XML Tag MetaData
  -- Allowed Tags mapping
  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_SEM_INTERCONNECTOR_OFFER)('') := TRUE;
  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_SEM_INTERCONNECTOR_OFFER):= TRUE;

  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_STANDING)(MM_SEM_OFFER_UTIL.g_TAG_SEM_INTERCONNECTOR_OFFER) := TRUE;
  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_STANDING):= TRUE;

  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER)(MM_SEM_OFFER_UTIL.g_TAG_SEM_INTERCONNECTOR_OFFER) := TRUE;

  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP)(MM_SEM_OFFER_UTIL.g_TAG_SEM_INTERCONNECTOR_OFFER) := TRUE;
  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP):= TRUE;

  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE):= TRUE;
  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE)(MM_SEM_OFFER_UTIL.g_TAG_SEM_INTERCONNECTOR_OFFER) := TRUE;

  g_IO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_POINT)(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE) := TRUE;

  -- Tags/Attributes
  -- Messages
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_NO_OP;
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
    -- Standing
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Expiry
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_STANDING_OFFER;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).TRAIT_IDX := MM_SEM_UTIL.G_TI_STANDING_EXPIRY_DATE;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Type
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_STANDING_OFFER;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_IDX := MM_SEM_UTIL.G_TI_STANDING_TYPE;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Identifier
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- External Identifier Attribute
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_EXT_IDENT;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- PQ Curve
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_SERIES;
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
  -- PQ Point
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_NOOP_INTERVAL;
      -- Price Attribute
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).TRAIT_GROUP_ID := TG.g_TG_OFFER_CURVE;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).TRAIT_IDX := TG.g_TI_OFFER_PRICE;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Quantity Attribute
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).TRAIT_GROUP_ID := TG.g_TG_OFFER_CURVE;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).TRAIT_IDX := TG.g_TI_OFFER_QUANTITY;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  --Interconnector Capacity
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Max Import Capacity MW
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_IMPORT_CAPACITY_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_IC_MAX_CAP;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_IMPORT_CAPACITY_MW).TRAIT_IDX := MM_SEM_UTIL.g_TI_IC_MAX_IMPORT;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_IMPORT_CAPACITY_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Max Export Capacity MW
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_EXPORT_CAPACITY_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_IC_MAX_CAP;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_EXPORT_CAPACITY_MW).TRAIT_IDX := MM_SEM_UTIL.g_TI_IC_MAX_EXPORT;
	  g_IO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_INTERCONNECTOR_CAP).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_EXPORT_CAPACITY_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
------------------------------------------------------------------------------
END MM_SEM_IC_OFFER;
/
