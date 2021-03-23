CREATE OR REPLACE PACKAGE BODY MM_SEM_OFFER_UTIL IS
------------------------------------------------------------------------------
    -- RSA -- 04/04/2007 -- Utility package for SEM Offer
------------------------------------------------------------------------------

FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
------------------------------------------------------------------------------
FUNCTION ADD_INTERVALS_FOR_STANDING(p_XML IN XMLTYPE, p_TRADING_DATE IN DATE, p_ELEMENT_NAME IN VARCHAR2, p_TRANSACTION_ID IN NUMBER)
	RETURN XMLTYPE IS

	v_NEW_XML XMLTYPE;
	nodeToCopy xmltype;
	newNode xmltype;
	newNodeInt1 xmltype;
	newNodeInt2 xmltype;
	v_STANDING_OFFER_TYPE_XML XMLTYPE;
	v_STANDING_OFFER_TYPE VARCHAR2(32);
	v_HR NUMBER;
	v_TRADE_DAY DATE;

BEGIN
	IF p_XML IS NULL THEN
		RETURN NULL;
	END IF;

	v_NEW_XML := p_XML;

	-- most of the time we probably won't have standing intervals to add (the element won't exist)
	IF XMLTYPE.EXISTSNODE(v_NEW_XML, '//' || p_ELEMENT_NAME) = 1 THEN

		-- p_TRADING_DATE is 06:00:01 converted to CUT on the trade day; we need to do our processing based on just the day.
		v_TRADE_DAY := TRUNC(p_TRADING_DATE, 'DD');

		CASE v_TRADE_DAY+1
			WHEN TRUNC(DST_FALL_BACK_DATE(v_TRADE_DAY)) THEN
				v_HR := 0;
			WHEN TRUNC(DST_SPRING_AHEAD_DATE(v_TRADE_DAY)) THEN
				v_HR := 1;
			ELSE
				v_HR := 2;
		END CASE;

		IF v_HR>0 THEN
			-- the long day already has the right number of intervals, so we only need to check for standing offer on normal and short days
			v_STANDING_OFFER_TYPE_XML := GET_STANDING(v_TRADE_DAY + 0.00001,p_TRANSACTION_ID);

			IF v_STANDING_OFFER_TYPE_XML IS NOT NULL THEN
				-- only need to add extra intervals if the standing offer type is All
				SELECT EXTRACTVALUE(v_STANDING_OFFER_TYPE_XML, '//standing/@type') INTO v_STANDING_OFFER_TYPE FROM DUAL;

				IF UPPER(v_STANDING_OFFER_TYPE) = 'ALL' THEN
					-- pull out the element with the hour closest to the missing intervals
					SELECT EXTRACT(v_NEW_XML, '//' || p_ELEMENT_NAME || '[@start_hr="' || v_HR || '" and @start_int="2"]')
						INTO nodeToCopy FROM DUAL;

					-- copy this into the two hr 25 intervals
					newNodeInt2 := xmltype.createxml(regexp_replace(nodeToCopy.getClobVal(), '(_hr="' || v_HR || '")', '_hr="25"'));
					newNodeInt1 := xmltype.createxml(regexp_replace(newNodeInt2.getClobVal(), '(_int="2")', '_int="1"'));

					SELECT XMLCONCAT(newNodeInt1, newNodeInt2) INTO newNode FROM dual;

					-- add elements for h1 if we're on the DST spring ahead date
					IF v_HR = 1 THEN
						newNodeInt1 := xmltype.createxml(regexp_replace(newNodeInt1.getClobVal(), '(_hr="25")', '_hr="2"'));
						newNodeInt2 := xmltype.createxml(regexp_replace(newNodeInt2.getClobVal(), '(_hr="25")', '_hr="2"'));
						SELECT XMLCONCAT(newNode, newNodeInt1, newNodeInt2) INTO newNode FROM dual;
					END IF;

					SELECT XMLCONCAT(v_NEW_XML, newNode) INTO v_NEW_XML FROM DUAL;
				END IF;
			END IF;
		END IF;
	END IF;

	RETURN v_NEW_XML;

END ADD_INTERVALS_FOR_STANDING;

/*----------------------------------------------------------------------------*
 *   GET_LOAD_GEN_DEC_PRICE                                                   *
 *----------------------------------------------------------------------------*/
FUNCTION GET_LOAD_GEN_DEC_PRICE
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN

    SELECT XMLAgg(XMLElement("decremental_price",
                             XMLAttributes(MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS
                                           "start_int",
                                           MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS
                                           "end_int",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS
                                           "start_hr",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS
                                           "end_hr",
                                           TRAIT_VAL AS "value"))
                  ORDER BY SCHEDULE_DATE
                  )
    INTO   v_RETURN
    FROM   IT_TRAIT_SCHEDULE A
    WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
           AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_OFFER_DEC_PRICE
           AND A.TRAIT_INDEX = 1
           AND SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
           AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
		   AND A.STATEMENT_TYPE_ID = 0;

    v_RETURN := ADD_INTERVALS_FOR_STANDING(v_RETURN, p_CUT_BEGIN_DATE, 'decremental_price', p_TRANSACTION_ID);
    RETURN v_RETURN;
END GET_LOAD_GEN_DEC_PRICE;

/*----------------------------------------------------------------------------*
 *   GET_LOAD_GEN_NOM_PROFILE                                                 *
 *----------------------------------------------------------------------------*/
FUNCTION GET_LOAD_GEN_NOM_PROFILE
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN
    SELECT XMLAgg(XMLElement("nomination_profile",
                             XMLAttributes(MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS
                                           "start_int",
                                           MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS
                                           "end_int",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS
                                           "start_hr",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS
                                           "end_hr",
                                           TRAIT_VAL AS "value"))
                  ORDER BY SCHEDULE_DATE
                  )
    INTO   v_RETURN
    FROM   IT_TRAIT_SCHEDULE A
    WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
           AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_OFFER_NOM_PROFILE
           AND A.TRAIT_INDEX = MM_SEM_UTIL.g_TI_OFFER_1ST_NOM_PROFILE
           AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
		   AND A.STATEMENT_TYPE_ID = 0
           AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE;

    v_RETURN := ADD_INTERVALS_FOR_STANDING(v_RETURN, p_CUT_BEGIN_DATE, 'nomination_profile', p_TRANSACTION_ID);
    RETURN v_RETURN;
END GET_LOAD_GEN_NOM_PROFILE;

/*----------------------------------------------------------------------------*
 *   GET_LOAD_GEN_NOM_PROFILE                                                 *
 *----------------------------------------------------------------------------*/
FUNCTION GET_LOAD_GEN_2ND_NOM_PROFILE
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN
    SELECT XMLAgg(XMLElement("secondary_nomination_profile",
                             XMLAttributes(MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS
                                           "start_int",
                                           MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) AS
                                           "end_int",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS
                                           "start_hr",
                                           MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) AS
                                           "end_hr",
                                           TRAIT_VAL AS "value"))
                  ORDER BY SCHEDULE_DATE
                  )
    INTO   v_RETURN
    FROM   IT_TRAIT_SCHEDULE A
    WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
           AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_OFFER_NOM_PROFILE
           AND A.TRAIT_INDEX = MM_SEM_UTIL.g_TI_OFFER_2ND_NOM_PROFILE
           AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
		   AND A.STATEMENT_TYPE_ID = 0
           AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE;

    v_RETURN := ADD_INTERVALS_FOR_STANDING(v_RETURN, p_CUT_BEGIN_DATE, 'secondary_nomination_profile', p_TRANSACTION_ID);
    RETURN v_RETURN;
END GET_LOAD_GEN_2ND_NOM_PROFILE;

/*----------------------------------------------------------------------------*
 *   GET_LOAD_GEN_FUEL_USE                                                    *
 *----------------------------------------------------------------------------*/
FUNCTION GET_LOAD_GEN_FUEL_USE
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN

    SELECT XMLAgg(XMLElement("fuel_use",
                             XMLAttributes(HOUR AS "start_hr",
                                           HOUR AS "end_hr",
                                           INTERVAL AS "start_int",
                                           INTERVAL AS "end_int",
                                           FUEL_USE_TYPE AS "type"
                            ))
                  ORDER BY SCHEDULE_DATE
                  )
    INTO   v_RETURN
    FROM   (SELECT MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) "INTERVAL",
                   MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) "HOUR",
                   SCHEDULE_DATE,
                   FUEL_USE_TYPE
            FROM   (SELECT A.SCHEDULE_DATE,
                           A.TRAIT_VAL AS FUEL_USE_TYPE
                            FROM   IT_TRAIT_SCHEDULE A
                            WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                                   AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_OFFER_FORECAST
                                   AND A.TRAIT_INDEX = MM_SEM_UTIL.g_TI_GEN_FORECAST_FUEL_USE
                                   AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
                                   AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
								   AND A.STATEMENT_TYPE_ID = 0));

    v_RETURN := ADD_INTERVALS_FOR_STANDING(v_RETURN, p_CUT_BEGIN_DATE, 'fuel_use', p_TRANSACTION_ID);
    RETURN v_RETURN;
END GET_LOAD_GEN_FUEL_USE;

/*----------------------------------------------------------------------------*
 *   GET_LOAD_GEN_PQ_CURVE                                                    *
 *----------------------------------------------------------------------------*/
FUNCTION GET_LOAD_GEN_PQ_CURVE
(
    p_CUT_DATE       DATE,
    p_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    doc        xmldom.DOMDocument;
    docElement xmldom.DOMElement;
    element    xmldom.DOMElement;
    nodeCurr   xmldom.DOMNode;
    TYPE t_PQ_RECORD IS RECORD(
        PRICE    NUMBER,
        QUANTITY NUMBER);
    TYPE t_PQ_REC_TYPE IS TABLE OF t_PQ_RECORD INDEX BY PLS_INTEGER;
    v_PQ_REC_TBL t_PQ_REC_TYPE;
    v_RETURN     XMLType;
BEGIN
    BEGIN
        doc        := xmldom.newDomDocument;
        docElement := xmldom.createElement(doc, 'pq_curve');

        FOR v_CURSOR IN (SELECT SCHEDULE_DATE,
                                TRAIT_INDEX,
                                SET_NUMBER,
                                ROW_NUMBER() OVER(ORDER BY SET_NUMBER, TRAIT_INDEX) RNUM,
                                TRAIT_VAL
                         FROM   IT_TRAIT_SCHEDULE A
                         WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                                AND A.SCHEDULE_DATE = p_CUT_DATE
                                AND A.TRAIT_GROUP_ID = TG.g_TG_OFFER_CURVE
                                AND A.TRAIT_INDEX BETWEEN TG.G_TI_OFFER_PRICE AND TG.g_TI_OFFER_QUANTITY
                                AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
								AND A.STATEMENT_TYPE_ID = 0
                         ORDER  BY SET_NUMBER, TRAIT_INDEX) LOOP
            IF (v_CURSOR.TRAIT_INDEX = TG.g_TI_OFFER_PRICE) THEN
                v_PQ_REC_TBL(v_CURSOR.SET_NUMBER).PRICE := v_CURSOR.TRAIT_VAL;
            ELSIF (v_CURSOR.TRAIT_INDEX = TG.g_TI_OFFER_QUANTITY) THEN
                v_PQ_REC_TBL(v_CURSOR.SET_NUMBER).QUANTITY := v_CURSOR.TRAIT_VAL;
            END IF;
        END LOOP;

        FOR I IN 1 .. v_PQ_REC_TBL.COUNT LOOP
            element := xmldom.createElement(doc, 'point');
            xmldom.setAttribute(element, 'price', v_PQ_REC_TBL(I).PRICE);
            xmldom.setAttribute(element,
                                'quantity',
                                v_PQ_REC_TBL(I).QUANTITY);
            nodeCurr := xmldom.appendChild(xmldom.makeNode(docElement),
                                           xmldom.makeNode(element));
        END LOOP;

        nodeCurr := xmldom.appendChild(xmldom.makeNode(doc),
                                       xmldom.makeNode(docElement));
        v_RETURN := xmldom.getXMLType(doc);
        xmldom.freeDocument(doc);
    EXCEPTION
        WHEN OTHERS THEN
            xmldom.freeDocument(doc);
    END;
    RETURN v_RETURN;
END GET_LOAD_GEN_PQ_CURVE;


/*----------------------------------------------------------------------------*
 *   GET_FORECAST                                                             *
 *----------------------------------------------------------------------------*/
FUNCTION GET_FORECAST
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN

    SELECT XMLAgg(XMLElement("forecast",
                             XMLAttributes(HOUR AS "start_hr",
                                           HOUR AS "end_hr",
                                           INTERVAL AS "start_int",
                                           INTERVAL AS "end_int",
                                           maximum_mw AS "maximum_mw",
                                           minimum_mw AS "minimum_mw",
                                           minimum_output_mw AS
                                           "minimum_output_mw"))
                   ORDER BY SCHEDULE_DATE)
    INTO   v_RETURN
    FROM   (SELECT MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) "INTERVAL",
                   MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) "HOUR",
                   SCHEDULE_DATE,
                   maximum_mw,
                   minimum_mw,
                   minimum_output_mw
            FROM   (SELECT SCHEDULE_DATE,
                           MAX(decode(TRAIT_INDEX,
                                      MM_SEM_UTIL.g_TI_GEN_FORECAST_MIN,
                                      cnt,
                                      NULL)) minimum_mw,
                           MAX(decode(TRAIT_INDEX,
                                      MM_SEM_UTIL.g_TI_GEN_FORECAST_MAX,
                                      cnt,
                                      NULL)) maximum_mw,
                           MAX(decode(TRAIT_INDEX,
                                      MM_SEM_UTIL.g_TI_GEN_FORECAST_MIN_OUTPUT,
                                      cnt,
                                      NULL)) minimum_output_mw
                    FROM   (SELECT SCHEDULE_DATE,
                                   TRAIT_INDEX,
                                   MAX(TRAIT_VAL) CNT
                            FROM   IT_TRAIT_SCHEDULE A
                            WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                                   AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_OFFER_FORECAST
                                   AND A.TRAIT_INDEX BETWEEN MM_SEM_UTIL.g_TI_GEN_FORECAST_MIN AND MM_SEM_UTIL.g_TI_GEN_FORECAST_MIN_OUTPUT
                                   AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
                                   AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
								   AND A.STATEMENT_TYPE_ID = 0
                            GROUP  BY SCHEDULE_DATE, TRAIT_INDEX
                            ORDER  BY SCHEDULE_DATE, TRAIT_INDEX)
                    GROUP  BY SCHEDULE_DATE));

	v_RETURN := ADD_INTERVALS_FOR_STANDING(v_RETURN, p_CUT_BEGIN_DATE, 'forecast', p_TRANSACTION_ID);
    RETURN v_RETURN;
END GET_FORECAST;

/*----------------------------------------------------------------------------*
 *   GET_SECONDARY_FORECAST                                                   *
 *----------------------------------------------------------------------------*/
FUNCTION GET_SECONDARY_FORECAST
(
    p_CUT_BEGIN_DATE IN DATE,
    p_CUT_END_DATE   IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN

    SELECT XMLAgg(XMLElement("secondary_forecast",
                             XMLAttributes(HOUR AS "start_hr",
                                           HOUR AS "end_hr",
                                           INTERVAL AS "start_int",
                                           INTERVAL AS "end_int",
                                           SECOND_MAX_MW AS "maximum_mw"))
                  ORDER BY SCHEDULE_DATE
                  )
    INTO   v_RETURN
    FROM   (SELECT MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) "INTERVAL",
                   MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) "HOUR",
                   SCHEDULE_DATE,
                   SECOND_MAX_MW
            FROM   (SELECT A.SCHEDULE_DATE,
                           A.TRAIT_VAL AS SECOND_MAX_MW
                            FROM   IT_TRAIT_SCHEDULE A
                            WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                                   AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_OFFER_FORECAST
                                   AND A.TRAIT_INDEX = MM_SEM_UTIL.g_TI_GEN_FORECAST_2ND_MAX_MW
                                   AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
                                   AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
								   AND A.STATEMENT_TYPE_ID = 0));

	v_RETURN := ADD_INTERVALS_FOR_STANDING(v_RETURN, p_CUT_BEGIN_DATE, 'secondary_forecast', p_TRANSACTION_ID);
    RETURN v_RETURN;
END GET_SECONDARY_FORECAST;

/*----------------------------------------------------------------------------*
 *   GET_STANDING                                                             *
 *----------------------------------------------------------------------------*/
FUNCTION GET_STANDING
(
    p_CUT_TIME       IN DATE,
    p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLTYPE IS
    v_RETURN XMLType;
BEGIN
    BEGIN
        SELECT XMLElement("standing",
                          XMLAttributes(TRAIT_VAL1 AS "expiry_date",
                                        TRAIT_VAL2 AS "type"))
        INTO   v_RETURN
        FROM   (SELECT TRAIT_GROUP_ID,
                       MAX(decode(TRAIT_INDEX,
                                  MM_SEM_UTIL.g_TI_STANDING_EXPIRY_DATE,
                                  cnt,
                                  NULL)) TRAIT_VAL1,
                       MAX(decode(TRAIT_INDEX,
                                  MM_SEM_UTIL.g_TI_STANDING_TYPE,
                                  cnt,
                                  NULL)) TRAIT_VAL2
                FROM   (SELECT TRAIT_GROUP_ID,
                               TRAIT_INDEX,
                               MAX(TRAIT_VAL) cnt
                        FROM   IT_TRAIT_SCHEDULE A
                        WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                               AND A.SCHEDULE_DATE = p_CUT_TIME
                               AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_STANDING_OFFER
							   AND A.TRAIT_INDEX BETWEEN MM_SEM_UTIL.g_TI_STANDING_TYPE AND MM_SEM_UTIL.g_TI_STANDING_EXPIRY_DATE
                               AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
							   AND A.STATEMENT_TYPE_ID = 0
                        GROUP  BY TRAIT_GROUP_ID, TRAIT_INDEX)
                GROUP  BY TRAIT_GROUP_ID);
        RETURN v_RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;
    END GET_STANDING;

/*----------------------------------------------------------------------------*
 *   GET_EXTERNAL_ID                                                          *
 *----------------------------------------------------------------------------*/
FUNCTION GET_EXTERNAL_ID
(
    p_CUT_DATE       DATE,
    p_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN XMLType IS
    v_RETURN XMLType;
BEGIN
    BEGIN
        SELECT XMLElement("identifier",
                          XMLAttributes(TRAIT_VAL AS "external_id"))
        INTO   v_RETURN
        FROM   IT_TRAIT_SCHEDULE A
        WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
               AND A.SCHEDULE_DATE = p_CUT_DATE
               AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_EXT_IDENT
               AND A.TRAIT_INDEX = 1
               AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
			   AND A.STATEMENT_TYPE_ID = 0;
        RETURN v_RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;
END GET_EXTERNAL_ID;
------------------------------------------------------------------------------
/*
** GET_GATE_WINDOW is used to retrieve the agreement_type attribute
** from the INTERCHANGE_TRANSACTION table when trying to process
** a gate_window specific offere
*/
FUNCTION GET_GATE_WINDOW
(
    p_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
) RETURN INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE IS
    v_RETURN INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
BEGIN
    BEGIN
        SELECT AGREEMENT_TYPE
        INTO   v_RETURN
        FROM   INTERCHANGE_TRANSACTION A
        WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
        AND AGREEMENT_TYPE IS NOT NULL
        AND AGREEMENT_TYPE != CONSTANTS.UNDEFINED_ATTRIBUTE;
        RETURN v_RETURN;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;
END GET_GATE_WINDOW;
------------------------------------------------------------------------------
FUNCTION PARSE_SUBMISSION_XML
	(
	p_XML IN XMLType,
	p_XPATH IN VARCHAR2 := '//error|//fatal'
	) RETURN VARCHAR2 IS
	v_RET VARCHAR2(4000) := NULL;
	v_CUR VARCHAR2(4004);
	CURSOR c_MSGs IS
		SELECT EXTRACTVALUE(VALUE(T), '/*') as MSG
		FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML, p_XPATH))) T;
BEGIN
	FOR v_MSG IN c_MSGs LOOP
		IF v_RET IS NULL THEN
			v_CUR := v_MSG.MSG;
		ELSE
			v_CUR := UTL_TCP.CRLF||v_MSG.MSG;
		END IF;

		IF NVL(LENGTH(v_RET),0) + LENGTH(v_CUR) > 4000 THEN
			v_RET := v_RET || SUBSTR(v_CUR, 1, 4000-3-NVL(LENGTH(v_RET),0)) || '...';
			-- buffer is full, so go ahead and return
			RETURN v_RET;
		ELSE
			v_RET := v_RET || UTL_TCP.CRLF || v_MSG.MSG;
		END IF;
	END LOOP;

	RETURN v_RET;

END PARSE_SUBMISSION_XML;
------------------------------------------------------------------------------
FUNCTION GET_TRANSACTION_ID_FOR_RES
	(
	p_TRANSACTION_TYPE IN VARCHAR2,
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2,
	p_GATE_WINDOW IN VARCHAR2,
	p_RESPONSE IN XMLTYPE
	) RETURN NUMBER IS
v_RESOURCE_NAME VARCHAR2(64);
v_TRANSACTION_ID NUMBER;
BEGIN
	SELECT EXTRACTVALUE(p_RESPONSE, '/*/@resource_name')
	INTO v_RESOURCE_NAME
	FROM DUAL;

	v_TRANSACTION_ID := MM_SEM_UTIL.GET_TRANSACTION_ID( p_TRANSACTION_TYPE 	=> p_TRANSACTION_TYPE,
														p_RESOURCE_NAME		=> v_RESOURCE_NAME,
														p_CREATE_IF_NOT_FOUND => TRUE,
														p_TRANSACTION_NAME	  => NULL,
														p_EXTERNAL_IDENTIFIER => NULL,
														p_ACCOUNT_NAME		  => p_EXTERNAL_ACCOUNT_NAME,
														p_AGREEMENT_TYPE         => p_GATE_WINDOW);
	IF NVL(v_TRANSACTION_ID,0) > 0 THEN
		RETURN v_TRANSACTION_ID;
	ELSE
		RAISE_APPLICATION_ERROR(-20000, 'Could not determine transaction ID for '||p_TRANSACTION_TYPE||'-'||v_RESOURCE_NAME||' f0r '||p_EXTERNAL_ACCOUNT_NAME||': '||NVL(v_TRANSACTION_ID,'NULL'));
	END IF;
END GET_TRANSACTION_ID_FOR_RES;
-----------------------------------------------------------------------------
PROCEDURE IMPORT_DATA
(
	p_PARENT_TAG_NAME IN VARCHAR2,
	p_RESPONSE IN XMLTYPE,
	p_TRADING_DATE IN DATE,
	p_INTERVAL IN SMALLINT,
	p_TXN_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
	p_TAG_OPERATIONS IN TYPE_OF_OPERATIONS,
	p_START_HR IN NUMBER,
    p_START_INT IN NUMBER,
    p_END_HR IN NUMBER,
    p_END_INT IN NUMBER,
	--p_SET_NUMBER_MAP IN OUT MAP_OF_SET_NUMBERS,
	p_SET_NUMBER IN NUMBER,
	p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS
v_XML_DOC XMLDOM.DOMDOCUMENT;
v_NODE_LIST XMLDOM.DOMNODELIST;
v_NAMED_NODE_MAP XMLDOM.DOMNAMEDNODEMAP;
v_LEN1 NUMBER;
v_NODE XMLDOM.DOMNODE;
v_ATTRNAME VARCHAR2(64);
v_ATTRVAL VARCHAR2(64);
v_SCHEDULED_DATE DATE;
  -------------------------------------------------------------------------
  FUNCTION GET_BOOLEAN_VALUE
  (
    p_BOOLEAN_VALUE VARCHAR2
  )
  RETURN VARCHAR2 IS
  BEGIN
    IF LOWER(p_BOOLEAN_VALUE) IN ('1', 'y', 'true') THEN
      RETURN '1';
    ELSE
      RETURN '0';
    END IF;
  END GET_BOOLEAN_VALUE;

BEGIN
 -- get XML node name
 v_XML_DOC := XMLDOM.newDomDocument(p_RESPONSE);
 -- get the parent node and process it
 v_NODE_LIST := XMLDOM.GETELEMENTSBYTAGNAME(v_XML_DOC, '*');
 v_NODE := XMLDOM.ITEM(v_NODE_LIST, 0);

 -- GET ALL ATTRIBUTES OF ELEMENT
 v_NAMED_NODE_MAP := XMLDOM.GETATTRIBUTES(v_NODE);

 IF (XMLDOM.ISNULL(v_NAMED_NODE_MAP) = FALSE) THEN
  v_LEN1 := XMLDOM.GETLENGTH(v_NAMED_NODE_MAP);

  -- LOOP THROUGH ATTRIBUTES
  FOR I IN 0..v_LEN1-1 LOOP
     v_NODE := XMLDOM.ITEM(v_NAMED_NODE_MAP, I);
     v_ATTRNAME := XMLDOM.GETNODENAME(v_NODE);

     -- Ignore Start_Hr, Start_int, End_Hr and End_Int for 30 Minutes interval tags
     IF v_ATTRNAME NOT IN (g_ATTR_START_HR, g_ATTR_END_HR, g_ATTR_START_INT, g_ATTR_END_INT) THEN

      -- Convert Boolean type attribute to appropriate value
      IF p_TAG_OPERATIONS(p_PARENT_TAG_NAME).ATTR_INFO_MAP(v_ATTRNAME).ATTR_TYPE = g_ATTR_TYPE_BOOLEAN THEN
       v_ATTRVAL := GET_BOOLEAN_VALUE(XMLDOM.GETNODEVALUE(v_NODE));
      ELSE
       v_ATTRVAL := XMLDOM.GETNODEVALUE(v_NODE);
      END IF;

      IF p_INTERVAL = g_DAILY_INTERVAL THEN
         v_SCHEDULED_DATE := p_TRADING_DATE + (1/(24*60*60));

         TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TXN_ID,
            GA.EXTERNAL_STATE,
            0,
            v_SCHEDULED_DATE,
            p_TAG_OPERATIONS(p_PARENT_TAG_NAME).ATTR_INFO_MAP(v_ATTRNAME).TRAIT_GROUP_ID,
            p_TAG_OPERATIONS(p_PARENT_TAG_NAME).ATTR_INFO_MAP(v_ATTRNAME).TRAIT_IDX,
            p_SET_NUMBER,
            v_ATTRVAL);
      ELSIF p_INTERVAL = g_30MINUTES_INTERVAL OR p_INTERVAL = g_30MINUTES_NOOP_INTERVAL THEN

        FOR HOUR IN p_START_HR..p_END_HR LOOP
                FOR INTERVAL IN 1..2 LOOP
              -- Iterate through all the hours/interval in the range
              IF (p_START_HR = p_END_HR AND INTERVAL >= p_START_INT AND INTERVAL <= p_END_INT) OR
               (p_START_HR <> p_END_HR AND HOUR = p_START_HR AND INTERVAL >= p_START_INT) OR
               (p_START_HR <> p_END_HR AND HOUR = p_END_HR AND INTERVAL <= p_END_INT) OR
             (HOUR > p_START_HR AND HOUR < p_END_HR) THEN

             -- 24-nov-2009, jbc: standing offers will typically have extra intervals that
             -- don't relate to the trading date; don't import these (hr25 except on fallback; hr2 on spring-forward
             IF (TRUNC(DST_FALL_BACK_DATE(p_TRADING_DATE+1)) <> p_TRADING_DATE+1 AND HOUR <> 25)
               OR (TRUNC(DST_SPRING_AHEAD_DATE(p_TRADING_DATE+1)) = p_TRADING_DATE+1 AND HOUR <> 2)
              OR (TRUNC(DST_FALL_BACK_DATE(p_TRADING_DATE+1)) = p_TRADING_DATE+1) THEN

              v_SCHEDULED_DATE := MM_SEM_UTIL.GET_SCHEDULE_DATE(p_TRADING_DATE,HOUR,INTERVAL, 1);
              TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TXN_ID,
                  GA.EXTERNAL_STATE,
                  0,
                  v_SCHEDULED_DATE,
                  p_TAG_OPERATIONS(p_PARENT_TAG_NAME).ATTR_INFO_MAP(v_ATTRNAME).TRAIT_GROUP_ID,
                  p_TAG_OPERATIONS(p_PARENT_TAG_NAME).ATTR_INFO_MAP(v_ATTRNAME).TRAIT_IDX,
                  p_SET_NUMBER,
                  v_ATTRVAL);
            END IF;
            END IF;
          END LOOP;
        END LOOP;

      END IF;

     END IF;
  END LOOP;
 END IF;
EXCEPTION
  WHEN OTHERS THEN
    p_LOGGER.LOG_ERROR('Could not process attribute <' || v_ATTRNAME || '> for tag <' || p_PARENT_TAG_NAME || '>.');
    XMLDOM.freeDocument ( v_XML_DOC );
    RAISE;
END IMPORT_DATA;
------------------------------------------------------------------------------
PROCEDURE IMPORT_TRAITS
  (
  p_RESPONSE IN XMLTYPE,
  p_TRADING_DATE IN DATE,
  p_IS_SERIES IN BOOLEAN,
  p_TXN_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE,
  p_ALLOWED_TAGS IN MAP_OF_STRING_SETS,
  p_TAG_OPERATIONS IN TYPE_OF_OPERATIONS,
  p_START_HR NUMBER,
    p_START_INT NUMBER,
    p_END_HR NUMBER,
    p_END_INT NUMBER,
  p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) AS

v_XML_DOC XMLDOM.DOMDOCUMENT;
v_NODE_LIST XMLDOM.DOMNODELIST;
v_NODE XMLDOM.DOMNODE;
v_ELEMENT XMLDOM.DOMELEMENT;
v_TAG_NAME VARCHAR(64);
v_TOP_LEVEL_TAG_NAME VARCHAR(64);
v_SET_NUMBER_MAP MAP_OF_SET_NUMBERS;
v_START_HR NUMBER;
v_START_INT NUMBER;
v_END_HR NUMBER;
v_END_INT NUMBER;
v_TRADING_DATE DATE;
v_INTERVAL SMALLINT;
v_MESSAGE VARCHAR2(256);

CURSOR c_ELEMENTS IS
  SELECT VALUE(T) as VAL
  FROM TABLE(XMLSEQUENCE(EXTRACT(p_RESPONSE, '/*/*'))) T;  -- Get all the children nodes
  -------------------------------------------------------------------------
  FUNCTION IS_VALID_TAG
  (
    p_TAG VARCHAR2,
    p_PARENT_TAG VARCHAR2
  )
  RETURN BOOLEAN IS
  BEGIN
    IF NOT p_ALLOWED_TAGS.EXISTS(p_TAG) THEN
      p_LOGGER.LOG_ERROR('Unrecognized tag <' || v_TAG_NAME || '> found.');
      RETURN FALSE;
    ELSIF NOT p_ALLOWED_TAGS(p_TAG).EXISTS(p_PARENT_TAG) THEN
      p_LOGGER.LOG_ERROR('Tag <' || v_TAG_NAME || '> cannot be child node of tag <' || p_PARENT_TAG || '> .');
      RETURN FALSE;
    END IF;
    RETURN TRUE;
  END IS_VALID_TAG;
  -------------------------------------------------------------------------
  FUNCTION GET_SET_NUMBER
  (
    p_TAG_NAME VARCHAR2,
    p_IS_SERIES BOOLEAN
  )
  RETURN NUMBER IS
  BEGIN
    IF p_IS_SERIES THEN
      IF v_SET_NUMBER_MAP.EXISTS(p_TAG_NAME) THEN
         v_SET_NUMBER_MAP(p_TAG_NAME) := v_SET_NUMBER_MAP(p_TAG_NAME) + 1;
      ELSE
         v_SET_NUMBER_MAP(p_TAG_NAME) := 1;
      END IF;
      RETURN v_SET_NUMBER_MAP(p_TAG_NAME);
    ELSE
      RETURN 1;
    END IF;
  END GET_SET_NUMBER;
  -------------------------------------------------------------------------
BEGIN
  -- Get the Parent node name or the Top Level Tag Name
  v_XML_DOC := XMLDOM.NEWDOMDOCUMENT(p_RESPONSE);
  v_NODE := xmldom.makeNode(v_XML_DOC);
  v_TOP_LEVEL_TAG_NAME := XMLDOM.getNodeName(xmldom.getFirstChild(v_NODE));

  FOR v_ELEMENT IN c_ELEMENTS LOOP
    -- get XML node name
    v_XML_DOC := XMLDOM.newDomDocument(v_ELEMENT.VAL);
    v_TAG_NAME := XMLDOM.getTagName(XMLDOM.getDocumentElement(v_XML_DOC));

    -- get the parent node and process it
    v_NODE_LIST := XMLDOM.GETELEMENTSBYTAGNAME(v_XML_DOC, '*');

    -- Check if the tag is valid
    IF IS_VALID_TAG(v_TAG_NAME, v_TOP_LEVEL_TAG_NAME) THEN
      v_INTERVAL := p_TAG_OPERATIONS(v_TAG_NAME).INTERVAL;
      v_TRADING_DATE := p_TRADING_DATE;
      IF p_TAG_OPERATIONS(v_TAG_NAME).INTERVAL = g_30MINUTES_INTERVAL THEN
         SELECT TO_NUMBER(EXTRACTVALUE(v_ELEMENT.VAL, v_TAG_NAME||g_XPATH_START_HR)),
            TO_NUMBER(EXTRACTVALUE(v_ELEMENT.VAL, v_TAG_NAME||g_XPATH_START_INTERVAL)),
            TO_NUMBER(EXTRACTVALUE(v_ELEMENT.VAL, v_TAG_NAME||g_XPATH_END_HR)),
            TO_NUMBER(EXTRACTVALUE(v_ELEMENT.VAL, v_TAG_NAME||g_XPATH_END_INTERVAL))
         INTO v_START_HR, v_START_INT, v_END_HR, v_END_INT
         FROM DUAL;
      ELSE
         v_START_HR := p_START_HR;
         v_START_INT := p_START_INT;
         v_END_HR := p_END_HR;
         v_END_INT := p_END_INT;
      END IF;

      CASE p_TAG_OPERATIONS(v_TAG_NAME).TAG_TYPE
        WHEN g_TAG_TYPE_NO_OP THEN
            NULL; --Ignore
        WHEN g_TAG_TYPE_DATA THEN
          IMPORT_DATA(v_TAG_NAME, v_ELEMENT.VAL, v_TRADING_DATE, v_INTERVAL,
                p_TXN_ID, p_TAG_OPERATIONS, v_START_HR, v_START_INT,
                v_END_HR, v_END_INT, GET_SET_NUMBER(v_TAG_NAME, p_IS_SERIES), p_LOGGER);

          -- Data node could have other children nodes
          IF XMLDOM.getLength(v_NODE_LIST) > 1 THEN
             IMPORT_TRAITS(v_ELEMENT.VAL, v_TRADING_DATE,
                   FALSE, p_TXN_ID, p_ALLOWED_TAGS, p_TAG_OPERATIONS,
                   v_START_HR, v_START_INT, v_END_HR, v_END_INT, p_LOGGER);
          END IF;

        WHEN g_TAG_TYPE_CONTAINER THEN
           IMPORT_TRAITS(v_ELEMENT.VAL, v_TRADING_DATE,
                   FALSE, p_TXN_ID, p_ALLOWED_TAGS, p_TAG_OPERATIONS,
                   v_START_HR, v_START_INT, v_END_HR, v_END_INT, p_LOGGER);
        WHEN g_TAG_TYPE_SERIES THEN
           IMPORT_TRAITS(v_ELEMENT.VAL, v_TRADING_DATE,
                   TRUE, p_TXN_ID, p_ALLOWED_TAGS, p_TAG_OPERATIONS,
                   v_START_HR, v_START_INT, v_END_HR, v_END_INT, p_LOGGER);
      END CASE;
    ELSE
      XMLDOM.freeDocument(v_XML_DOC);
      v_MESSAGE := 'Tag <' || v_TAG_NAME || '> is not a valid child node of tag <' || v_TOP_LEVEL_TAG_NAME || '>.';
      RAISE_APPLICATION_ERROR(-20000, v_MESSAGE);
    END IF;

    XMLDOM.freeDocument(v_XML_DOC);
  END LOOP;

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      XMLDOM.freeDocument(v_XML_DOC);
      v_MESSAGE := 'Unable to import, process failed for tag <' || v_TAG_NAME || '>';
      p_LOGGER.LOG_ERROR(v_MESSAGE);
      RAISE_APPLICATION_ERROR(-20000, v_MESSAGE);
END IMPORT_TRAITS;

-------------------------------------------------------------------------
PROCEDURE PURGE_IT_TRAIT_SCHEDULE (
   p_TRADING_DATE DATE,
   p_TXN_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
)
IS
   v_CUT_BEGIN_DATE DATE;
   v_CUT_END_DATE DATE;
   v_CUT_DATE_FOR_DAILY_TRAIT DATE;
BEGIN
    SAVEPOINT ROLLBACK_SCHEDULE_DELETE;

    -- "Cut Date" for Daily Trait is Calendar Day + 1 second.
    v_CUT_DATE_FOR_DAILY_TRAIT := p_TRADING_DATE + (1/(24*60*60));

    -- Get CUT Date Range for Trading Date
    MM_SEM_UTIL.OFFER_DATE_RANGE(p_TRADING_DATE, v_CUT_BEGIN_DATE, v_CUT_END_DATE);

    DELETE FROM IT_TRAIT_SCHEDULE A
    WHERE A.TRANSACTION_ID = p_TXN_ID
    AND   A.SCHEDULE_STATE = GA.EXTERNAL_STATE
    AND  ((A.SCHEDULE_DATE = v_CUT_DATE_FOR_DAILY_TRAIT)
       OR (A.SCHEDULE_DATE BETWEEN v_CUT_BEGIN_DATE AND v_CUT_END_DATE));

    COMMIT;

   EXCEPTION
    WHEN OTHERS THEN
     ROLLBACK TO ROLLBACK_SCHEDULE_DELETE;

END PURGE_IT_TRAIT_SCHEDULE;
------------------------------------------------------------------------------
END MM_SEM_OFFER_UTIL;
/
