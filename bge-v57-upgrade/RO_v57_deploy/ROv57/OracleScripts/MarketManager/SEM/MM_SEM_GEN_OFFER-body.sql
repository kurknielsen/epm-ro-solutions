CREATE OR REPLACE PACKAGE BODY MM_SEM_GEN_OFFER IS

g_GO_ALLOWED_TAGS MM_SEM_OFFER_UTIL.MAP_OF_STRING_SETS;
g_GO_TAG_OPERATIONS MM_SEM_OFFER_UTIL.TYPE_OF_OPERATIONS;

/*----------------------------------------------------------------------------*
*   WHAT_VERSION                                                             *
*----------------------------------------------------------------------------*/
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
 RETURN '$Revision: 1.7 $';
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
        RETURN NUMBER_COLLECTION( MM_SEM_OFFER_UTIL.GET_TRANSACTION_ID_FOR_RES('Generation', p_ACCOUNT_NAME, p_GATE_WINDOW, p_RESPONSE) );
    END GET_TRANSACTION_IDs;
    ------------------------------------------------------------------------------
    FUNCTION GET_ENERGY_LIMIT_PERIOD_FLAG
    (
	    p_CUT_TIME       DATE,
        p_CUT_BEGIN_DATE DATE,
        p_CUT_END_DATE   DATE,
        p_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
    ) RETURN XMLType IS
        v_RETURN   XMLType;
        doc        xmldom.DOMDocument;
        docElement xmldom.DOMElement;
        element    xmldom.DOMElement;
        nodeCurr   xmldom.DOMNode;
    BEGIN
        BEGIN
            doc        := xmldom.newDomDocument;
            docElement := xmldom.createElement(doc, 'energy_limit_detail');

            FOR v_CURSOR IN (SELECT TRAIT_GROUP_ID, TRAIT_INDEX, TRAIT_VAL
                             FROM   IT_TRAIT_SCHEDULE A
                             WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
									AND A.SCHEDULE_DATE = p_CUT_TIME
                                    AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_GEN_LIMIT
                                    AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
									AND A.STATEMENT_TYPE_ID = 0
                                    AND A.TRAIT_INDEX BETWEEN MM_SEM_UTIL.g_TI_GEN_LIMIT_MWH AND MM_SEM_UTIL.g_TI_GEN_LIMIT_FACTOR) LOOP
                IF v_CURSOR.TRAIT_INDEX = MM_SEM_UTIL.g_TI_GEN_LIMIT_MWH THEN
                    xmldom.setAttribute(docElement,
                                        'limit_mwh',
                                        v_CURSOR.TRAIT_VAL);
                ELSIF v_CURSOR.TRAIT_INDEX = MM_SEM_UTIL.g_TI_GEN_LIMIT_FACTOR THEN
                    xmldom.setAttribute(docElement,
                                        'limit_factor',
                                        v_CURSOR.TRAIT_VAL);
                END IF;
            END LOOP;
            FOR v_CURSOR IN (SELECT MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) START_INT,
                                    MM_SEM_UTIL.GET_INTERVAL_FROM_DATE(SCHEDULE_DATE) END_INT,
                                    MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) START_HR,
                                    MM_SEM_UTIL.GET_HOUR_FROM_DATE(SCHEDULE_DATE) END_HR,
                                    CASE
                                        WHEN TRAIT_VAL = '0' THEN
                                         'false'
                                        ELSE
                                         'true'
                                    END LIMIT_FLAG
                             FROM   IT_TRAIT_SCHEDULE A
                             WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                                    AND A.SCHEDULE_DATE BETWEEN p_CUT_BEGIN_DATE AND p_CUT_END_DATE
                                    AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_GEN_IS_LIMITED
                                    AND A.TRAIT_INDEX = 1
                                    AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
									AND A.STATEMENT_TYPE_ID = 0) LOOP
                element := xmldom.createElement(doc,
                                                'energy_limit_period_flag');
                xmldom.setAttribute(element, 'start_hr', v_CURSOR.start_hr);
                xmldom.setAttribute(element, 'end_hr', v_CURSOR.end_hr);
                xmldom.setAttribute(element, 'start_int', v_CURSOR.start_int);
                xmldom.setAttribute(element, 'end_int', v_CURSOR.end_int);
                xmldom.setAttribute(element,
                                    'limit_flag',
                                    v_CURSOR.limit_flag);
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
    END GET_ENERGY_LIMIT_PERIOD_FLAG;
    ------------------------------------------------------------------------------
    FUNCTION GET_PUMP_STORAGE_DETAIL
    (
        p_CUT_DATE       DATE,
        p_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
    ) RETURN XMLType IS
        v_RETURN XMLType;
        doc      xmldom.DOMDocument;
        element  xmldom.DOMElement;
        nodeCurr xmldom.DOMNode;
    BEGIN
        /* -- MAJOR ORACLE BUG -- Commented out for posterity --
           -- falling back on xmldom for a woraround --
           -- RSA -- 04/05/2007
         SELECT XMLElement("pump_storage_detail",
                          XMLAttributes(spin_generation_cost AS "spin_generation_cost",
                                        spin_pump_cost AS "spin_pump_cost",
                                        minimum_generation_cost AS "minimum_generation_cost",
                                        target_reservoir_level_mwh AS "target_reservoir_level_mwh",
                                        target_reservoir_level_percent AS "target_reservoir_level_percent",
                                        prior_day_res_lvl_mwh AS "prior_day_end_reservoir_level_mwh",
                                        op_res AS "operational_reservoir_capacity_limit_mwh"))
        INTO v_RETURN
        FROM */
        BEGIN
            doc     := xmldom.newDomDocument;
            element := xmldom.createElement(doc, 'pump_storage_detail');
            FOR v_CURSOR IN (SELECT SCHEDULE_DATE,
                                    MAX(DECODE(KEYS,
                                               MM_SEM_UTIL.g_TG_GEN_SPIN_GEN_COST || '1',
                                               CNT,
                                               NULL)) spin_generation_cost,
                                    MAX(DECODE(KEYS,
                                               MM_SEM_UTIL.g_TG_GEN_SPIN_PUMP_COST || '1',
                                               CNT,
                                               NULL)) spin_pump_cost,
                                    MAX(DECODE(KEYS,
                                               MM_SEM_UTIL.g_TG_GEN_MIN_GEN_COST || '1',
                                               CNT,
                                               NULL)) minimum_generation_cost,
                                    MAX(DECODE(KEYS,
                                               MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO ||
                                               MM_SEM_UTIL.g_TI_GEN_RESERVOIR_TARGET_MWH,
                                               CNT,
                                               NULL)) target_reservoir_level_mwh,
                                    MAX(DECODE(KEYS,
                                               MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO ||
                                               MM_SEM_UTIL.g_TI_GEN_RESERVOIR_TARGET_PCT,
                                               CNT,
                                               NULL)) target_reservoir_level_percent,
                                    MAX(DECODE(KEYS,
                                               MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO ||
                                               MM_SEM_UTIL.g_TI_GEN_RESERVOIR_PRIOR_MWH,
                                               CNT,
                                               NULL)) prior_day_res_lvl_mwh, --"prior_day_end_reservoir_level_mwh",
                                    MAX(DECODE(KEYS,
                                               MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO ||
                                               MM_SEM_UTIL.g_TI_GEN_RESERVOIR_OP_CAP_MWH,
                                               CNT,
                                               NULL)) op_res -- "operational_reservoir_capacity_limit_mwh"
                             FROM   (SELECT SCHEDULE_DATE,
                                            TRAIT_GROUP_ID || TRAIT_INDEX "KEYS",
                                            MAX(TRAIT_VAL) CNT
                                     FROM   IT_TRAIT_SCHEDULE A
                                     WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                                            AND A.SCHEDULE_DATE = p_CUT_DATE
											AND A.TRAIT_GROUP_ID BETWEEN MM_SEM_UTIL.g_TG_GEN_SPIN_GEN_COST AND MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO
                                            AND A.TRAIT_INDEX BETWEEN MM_SEM_UTIL.g_TI_GEN_RESERVOIR_TARGET_MWH AND MM_SEM_UTIL.g_TI_GEN_RESERVOIR_OP_CAP_MWH
                                            AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
											AND A.STATEMENT_TYPE_ID = 0
                                     GROUP  BY SCHEDULE_DATE,
                                               TRAIT_GROUP_ID,
                                               TRAIT_INDEX)
                             GROUP  BY SCHEDULE_DATE) LOOP

                xmldom.setAttribute(element,
                                    'spin_generation_cost',
                                    v_CURSOR.spin_generation_cost);
                xmldom.setAttribute(element,
                                    'spin_pump_cost',
                                    v_CURSOR.spin_pump_cost);
                xmldom.setAttribute(element,
                                    'minimum_generation_cost',
                                    v_CURSOR.minimum_generation_cost);
                xmldom.setAttribute(element,
                                    'target_reservoir_level_mwh',
                                    v_CURSOR.target_reservoir_level_mwh);
                xmldom.setAttribute(element,
                                    'target_reservoir_level_percent',
                                    v_CURSOR.target_reservoir_level_percent);
                xmldom.setAttribute(element,
                                    'prior_day_end_reservoir_level_mwh',
                                    v_CURSOR.prior_day_res_lvl_mwh);
                xmldom.setAttribute(element,
                                    'operational_reservoir_capacity_limit_mwh',
                                    v_CURSOR.op_res);
            END LOOP;
            nodeCurr := xmldom.appendChild(xmldom.makeNode(doc),
                                           xmldom.makeNode(element));
            v_RETURN := xmldom.getXMLType(doc);
            xmldom.freeDocument(doc);
        EXCEPTION
            WHEN OTHERS THEN
                xmldom.freeDocument(doc);
                RAISE;
        END;

        RETURN v_RETURN;
    END GET_PUMP_STORAGE_DETAIL;
    ------------------------------------------------------------------------------
    FUNCTION GET_STARTUP_COST
    (
        p_CUT_TIME       IN DATE,
        p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
    ) RETURN XMLType IS
        v_RETURN XMLType;
    BEGIN
        BEGIN
            SELECT XMLElement("startup_cost",
                              XMLAttributes(trait_1 AS "hot",
                                            trait_2 AS "warm",
                                            trait_3 AS "cold"))
            INTO   v_RETURN
            FROM   (SELECT TRAIT_GROUP_ID,
                           MAX(decode(TRAIT_INDEX,
                                      MM_SEM_UTIL.g_TI_GEN_HOT_START_COST,
                                      cnt,
                                      NULL)) TRAIT_1,
                           MAX(decode(TRAIT_INDEX,
                                      MM_SEM_UTIL.g_TI_GEN_WARM_START_COST,
                                      cnt,
                                      NULL)) TRAIT_2,
                           MAX(decode(TRAIT_INDEX,
                                      MM_SEM_UTIL.g_TI_GEN_COLD_START_COST,
                                      cnt,
                                      NULL)) TRAIT_3
                    FROM   (SELECT TRAIT_GROUP_ID,
                                   TRAIT_INDEX,
                                   MAX(TRAIT_VAL) cnt
                            FROM   IT_TRAIT_SCHEDULE A
                            WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                                   AND A.SCHEDULE_DATE = p_CUT_TIME
                                   AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_GEN_STARTUP_COSTS
								   AND A.TRAIT_INDEX BETWEEN MM_SEM_UTIL.g_TI_GEN_HOT_START_COST AND MM_SEM_UTIL.g_TI_GEN_COLD_START_COST
                                   AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
								   AND A.STATEMENT_TYPE_ID = 0
                            GROUP  BY TRAIT_GROUP_ID, TRAIT_INDEX)
                    GROUP  BY TRAIT_GROUP_ID);
            RETURN v_RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
        END;
    END GET_STARTUP_COST;
    ------------------------------------------------------------------------------
    FUNCTION GET_NO_LOAD_COST
    (
        p_CUT_TIME       IN DATE,
        p_TRANSACTION_ID IN INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE
    ) RETURN XMLType IS
        v_RETURN XMLType;
    BEGIN
        BEGIN
            SELECT XMLElement("no_load_cost",
                              XMLAttributes(trait_val AS "value"))
            INTO   v_RETURN
            FROM   (SELECT TRAIT_GROUP_ID, TRAIT_INDEX, TRAIT_VAL
                    FROM   IT_TRAIT_SCHEDULE A
                    WHERE  A.TRANSACTION_ID = p_TRANSACTION_ID
                           AND A.SCHEDULE_DATE = p_CUT_TIME
                           AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_OFFER_NO_LOAD_COST
                           AND A.TRAIT_INDEX = 1
                           AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
						   AND A.STATEMENT_TYPE_ID = 0);
            RETURN v_RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
        END;
    END GET_NO_LOAD_COST;
    -------------------------------------------------------------------------------
    FUNCTION GET_UUT_EXT_IDENT
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
                   AND A.TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_GEN_UNDER_TEST
                   AND A.TRAIT_INDEX = MM_SEM_UTIL.g_TI_TXN_ID
                   AND A.SCHEDULE_STATE = GA.INTERNAL_STATE
          AND A.STATEMENT_TYPE_ID = 0;
            RETURN v_RETURN;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN NULL;
        END;
    END GET_UUT_EXT_IDENT;
    -------------------------------------------------------------------------------
    FUNCTION GET_UUT_STATUS
     (
     p_TRANSACTION_ID IN NUMBER,
     p_DATE IN DATE
     ) RETURN VARCHAR2 IS
    v_TRAIT_VAL IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;
    BEGIN
     SELECT MAX(UPPER(TRAIT_VAL))
     INTO v_TRAIT_VAL
     FROM IT_TRAIT_SCHEDULE
     WHERE TRANSACTION_ID = p_TRANSACTION_ID
      AND SCHEDULE_STATE = GA.INTERNAL_STATE
      AND SCHEDULE_DATE = TRUNC(p_DATE)+1/86400
      AND TRAIT_GROUP_ID = MM_SEM_UTIL.g_TG_GEN_UNDER_TEST
      AND TRAIT_INDEX = MM_SEM_UTIL.g_TI_STATUS
      AND SET_NUMBER = 1
      AND STATEMENT_TYPE_ID = 0;

     RETURN v_TRAIT_VAL;
    END GET_UUT_STATUS;
    ------------------------------------------------------------------------------
    FUNCTION CREATE_SUBMISSION_XML
    (
        p_DATE           IN DATE,
        p_TRANSACTION_ID IN NUMBER,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN XMLTYPE IS
        v_RESOURCE_NAME          	 SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
        v_RESOURCE_TYPE          	 TEMPORAL_ENTITY_ATTRIBUTE.ATTRIBUTE_VAL%TYPE;
        v_XML_SEQUENCE_TBL       	 XMLSequenceType := XMLSequenceType();
        v_XML_PRICE_TAKER_DETAIL 	 XMLType;
        v_CUT_BEGIN_DATE         	 DATE;
        v_CUT_END_DATE           	 DATE;
        v_IS_STANDING_BID        	 BOOLEAN;
        v_STANDING_FLAG          	 VARCHAR2(5) := 'false';
        v_IS_PUMPED_STORAGE      	 BOOLEAN;
        v_IS_ENERGY_LIMITED      	 BOOLEAN;
        v_IS_UNDER_TEST          	 BOOLEAN;
        v_RO_RESOURCE_TYPE       	 VARCHAR2(10);
        v_PRICE_MAKER_TAKER_TAG  	 VARCHAR2(32);
        v_XML_NOMINATION_PROFILE 	 XMLType;
		v_XML_2ND_NOMINATION_PROFILE XMLType;
        v_XML_DECREMENTAL_PRICE  	 XMLType;
        v_PQ_CURVE               	 XMLType;
        v_STARTUP_COST               XMLType;
        v_NO_LOAD_COST           	 XMLType;
        v_XML                    	 XMLType;

    BEGIN
        MM_SEM_UTIL.OFFER_DATE_RANGE(p_DATE, p_DATE, v_CUT_BEGIN_DATE, v_CUT_END_DATE);
       /* UT.CUT_DATE_RANGE(p_DATE,
                          P_DATE,
                          MM_SEM_UTIL.g_TZ,
                          v_CUT_BEGIN_DATE,
                          v_CUT_END_DATE);*/
        v_RESOURCE_NAME     := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);
        v_IS_PUMPED_STORAGE := MM_SEM_UTIL.IS_PUMPED_STORAGE(p_TRANSACTION_ID);
        v_IS_ENERGY_LIMITED := MM_SEM_UTIL.IS_ENERGY_LIMITED(p_TRANSACTION_ID);
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
            v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := MM_SEM_OFFER_UTIL.GET_STANDING(p_DATE +
                                                                         k_1_SEC,
                                                                         p_TRANSACTION_ID);

        END IF;

        IF v_IS_UNDER_TEST THEN
            v_PRICE_mAKER_tAKER_TAG := 'price_taker_detail';
        ELSIF v_RO_RESOURCE_TYPE = 'PPTG' OR v_RO_RESOURCE_TYPE = 'VPTG' THEN
            v_PRICE_mAKER_tAKER_TAG := 'price_taker_detail';
        ELSE
            v_PRICE_mAKER_tAKER_TAG := 'price_maker_detail';
        END IF;

        -- Get External Id
        v_XML := MM_SEM_OFFER_UTIL.GET_EXTERNAL_ID(p_DATE + k_1_SEC, p_TRANSACTION_ID);
        IF v_XML IS NOT NULL THEN
            v_XML_SEQUENCE_TBL.EXTEND;
            v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := v_XML;
        END IF;

        --FORECAST
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := MM_SEM_OFFER_UTIL.GET_FORECAST(v_CUT_BEGIN_DATE,
                                                                     v_CUT_END_DATE,
                                                                     p_TRANSACTION_ID);

		--FUEL USE
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_FUEL_USE(v_CUT_BEGIN_DATE,
                                                                     v_CUT_END_DATE,
                                                                     p_TRANSACTION_ID);

		--SECONDARY FORECAST
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := MM_SEM_OFFER_UTIL.GET_SECONDARY_FORECAST(v_CUT_BEGIN_DATE,
                                                                     v_CUT_END_DATE,
                                                                     p_TRANSACTION_ID);

        --PUMP_STORAGE_DETAIL
        v_XML := GET_PUMP_STORAGE_DETAIL(p_DATE + k_1_SEC, p_TRANSACTION_ID);
        IF v_IS_PUMPED_STORAGE AND v_XML IS NOT NULL THEN
            v_XML_SEQUENCE_TBL.EXTEND;
            v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := v_XML;
        END IF;

        -- ENERGY_LIMIT_PERIOD_FLAG
        v_XML := GET_ENERGY_LIMIT_PERIOD_FLAG(p_DATE + k_1_SEC, -- needed for limit_mwh, limit_factor daily traits
		                                      v_CUT_BEGIN_DATE, -- needed for energy_limit_period_flag 30 mins trait
                                              v_CUT_END_DATE,
                                              p_TRANSACTION_ID);
        IF v_IS_ENERGY_LIMITED AND v_XML IS NOT NULL THEN
            v_XML_SEQUENCE_TBL.EXTEND;
            v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := v_XML;
        END IF;
        /*--Get Nomination Profile
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_NOMINATION_PROFILE(v_CUT_BEGIN_DATE,
                                                                               v_CUT_END_DATE,
                                                                               p_TRANSACTION_ID);
        --Get Decremental Price
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_DECREMENTAL_PRICE(v_CUT_BEGIN_DATE,
                                                                              v_CUT_END_DATE,
                                                                              p_TRANSACTION_ID);

        -- Get Startup Cost
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_STARTUP_COST(p_DATE +
                                                                         k_1_SEC,
                                                                         p_TRANSACTION_ID);

        -- GET PQ-CURVE
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_PQ_CURVE(p_DATE +
                                                                     k_1_SEC,
                                                                     p_TRANSACTION_ID);*/

        v_XML_NOMINATION_PROFILE := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_NOM_PROFILE(v_CUT_BEGIN_DATE,
                                                           v_CUT_END_DATE,
                                                           p_TRANSACTION_ID);
		v_XML_2ND_NOMINATION_PROFILE := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_2ND_NOM_PROFILE(v_CUT_BEGIN_DATE,
                                                           v_CUT_END_DATE,
                                                           p_TRANSACTION_ID);
        v_XML_DECREMENTAL_PRICE  := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_DEC_PRICE(v_CUT_BEGIN_DATE,
                                                          v_CUT_END_DATE,
                                                          p_TRANSACTION_ID);

        -- PQ Curve, Startup Cost and No Load Cost should be submitted
        -- only for PPMG, VPMG or PPTG and not for VPTG or Unit under test.
        IF NOT v_IS_UNDER_TEST AND v_RO_RESOURCE_TYPE <> 'VPTG' THEN
          v_STARTUP_COST           := GET_STARTUP_COST(p_DATE +
                                                       MM_SEM_GEN_OFFER.k_1_SEC,
                                                       p_TRANSACTION_ID);

          v_NO_LOAD_COST := GET_NO_LOAD_COST(p_DATE + MM_SEM_GEN_OFFER.k_1_SEC,
                                             p_TRANSACTION_ID);

          v_PQ_CURVE := MM_SEM_OFFER_UTIL.GET_LOAD_GEN_PQ_CURVE(p_DATE + k_1_SEC, p_TRANSACTION_ID);
        END IF;

        v_XML_SEQUENCE_TBL.EXTEND;

        IF v_PRICE_MAKER_TAKER_TAG = 'price_maker_detail' THEN
            SELECT XMLAgg(XMLElement("price_maker_detail",
                                     XMLConcat(v_PQ_CURVE,
                                               v_STARTUP_COST,
                                               v_NO_LOAD_COST
                                               )))
            INTO   v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT)
            FROM   DUAL;
        ELSE
            -- Nomination profile/Decremental Price should be submitted
            -- if the unit type is PPTG or VPTG or Under Test.
            -- But PQ Curve, Startup Cost and No Load Cost should not be
            -- submitted for VPTG or Under test unit.
            IF v_IS_UNDER_TEST OR v_RO_RESOURCE_TYPE = 'VPTG' THEN
              SELECT XMLAgg(XMLElement("price_taker_detail",
                                       XMLConcat(v_XML_NOMINATION_PROFILE,
									   		     v_XML_2ND_NOMINATION_PROFILE,
                                                 v_XML_DECREMENTAL_PRICE
                                                 )))
              INTO   v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT)
              FROM   DUAL;
            ELSE
              SELECT XMLAgg(XMLElement("price_taker_detail",
                                       XMLConcat(v_PQ_CURVE,
                                                 v_STARTUP_COST,
                                                 v_NO_LOAD_COST,
                                                 v_XML_NOMINATION_PROFILE,
												 v_XML_2ND_NOMINATION_PROFILE,
                                                 v_XML_DECREMENTAL_PRICE
                                                 )))
              INTO   v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT)
              FROM   DUAL;
            END IF;

        END IF;

        -- Concatenate all the childNodes under the parentNode <PRICE_TAKER_DETAIL>
        SELECT XMLElement("sem_gen_offer",
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
            p_LOGGER.LOG_ERROR('Error creating Gen Offer submission XML (' ||
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
        p_DATE           IN DATE,
        p_TRANSACTION_ID IN NUMBER,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN XMLTYPE IS
     v_RESOURCE_NAME          SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
	 v_IS_STANDING_BID        BOOLEAN;
     v_STANDING_FLAG          VARCHAR2(5) := 'false';
     v_XML                    XMLType;
    BEGIN
		IF p_TRANSACTION_ID = MM_SEM_UTIL.g_ALL THEN
		    SELECT XMLElement("sem_gen_offer", XMLAttributes(v_STANDING_FLAG AS "standing_flag",
															 '1.0' AS "version_no"))
			INTO v_XML
			FROM DUAL;
		ELSE
		    v_RESOURCE_NAME     := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);

			--Determine if is a standing bid, add Standing element if true
			v_IS_STANDING_BID := MM_SEM_UTIL.IS_STANDING_BID(p_TRANSACTION_ID,
															 p_DATE);
			IF v_IS_STANDING_BID THEN
				v_STANDING_FLAG := 'true';
			END IF;

			SELECT XMLElement("sem_gen_offer", XMLAttributes(v_STANDING_FLAG AS "standing_flag",
															 '1.0' AS "version_no",
															 v_RESOURCE_NAME AS "resource_name"))
			INTO v_XML
			FROM DUAL;
		END IF;

        RETURN v_XML;

        EXCEPTION
        WHEN OTHERS THEN
            p_LOGGER.LOG_ERROR('Error creating Gen Offer Query XML (' ||
                               p_TRANSACTION_ID || ' for ' ||
                               TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                               MM_SEM_UTIL.ERROR_STACKTRACE);

            v_XML := NULL;
            RETURN v_XML;
            RAISE;
    END CREATE_QUERY_XML;
    ------------------------------------------------------------------------------
    FUNCTION CREATE_UUT_SUBMISSION_XML
    (
        p_DATE           IN DATE,
        p_TRANSACTION_ID IN NUMBER,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN XMLTYPE IS
        v_RESOURCE_NAME          	 SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
        v_XML_DETAIL 	             XMLType;
        v_XML_SEQUENCE_TBL       	 XMLSequenceType := XMLSequenceType();

    BEGIN
        v_RESOURCE_NAME     := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);

        -- Get External Id
        v_XML_SEQUENCE_TBL.EXTEND;
        v_XML_SEQUENCE_TBL(v_XML_SEQUENCE_TBL.COUNT) := GET_UUT_EXT_IDENT(p_DATE + k_1_SEC, p_TRANSACTION_ID);

        SELECT XMLElement("sem_unit_under_test",
              XMLAttributes(v_RESOURCE_NAME AS "resource_name",
                            TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) AS "start_date",
                            TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) AS "end_date",
							k_VERSION_NO AS "version_no"),
              XMLConcat(CAST(v_XML_SEQUENCE_TBL AS XMLSequenceType)))
        INTO   v_XML_DETAIL
        FROM   DUAL;

        RETURN v_XML_DETAIL;

    EXCEPTION
        WHEN OTHERS THEN
            p_LOGGER.LOG_ERROR('Error creating Unit Under Test submission XML (' ||
                               p_TRANSACTION_ID || ' for ' ||
                               TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                               MM_SEM_UTIL.ERROR_STACKTRACE);

                v_XML_DETAIL := NULL;
                RETURN v_XML_DETAIL;
                RAISE;
    END CREATE_UUT_SUBMISSION_XML;
    ------------------------------------------------------------------------------
    FUNCTION CREATE_UUT_QUERY_XML
    (
        p_DATE           IN DATE,
        p_TRANSACTION_ID IN NUMBER,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN XMLTYPE IS
        v_RESOURCE_NAME          	 SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
        v_XML_DETAIL 	             XMLType;
        v_XML_SEQUENCE_TBL       	 XMLSequenceType := XMLSequenceType();
        v_UUT_STATUS               IT_TRAIT_SCHEDULE.TRAIT_VAL%TYPE;

    BEGIN
        v_RESOURCE_NAME     := MM_SEM_UTIL.GET_RESOURCE_NAME(p_TRANSACTION_ID);

        -- Waiting for clarification from SEMO market, for time being we will assume
        -- that the 'APPROVED' status is being passed in when querying unit under test.
        v_UUT_STATUS        := 'APPROVED' /*GET_UUT_STATUS(p_TRANSACTION_ID, p_DATE + k_1_SEC)*/;

        SELECT XMLElement("sem_unit_under_test",
              XMLAttributes(v_RESOURCE_NAME AS "resource_name",
                            v_UUT_STATUS AS "status"),
              XMLConcat(CAST(v_XML_SEQUENCE_TBL AS XMLSequenceType)))
        INTO   v_XML_DETAIL
        FROM   DUAL;

        RETURN v_XML_DETAIL;

    EXCEPTION
        WHEN OTHERS THEN
            p_LOGGER.LOG_ERROR('Error creating Unit Under Test query XML (' ||
                               p_TRANSACTION_ID || ' for ' ||
                               TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                               MM_SEM_UTIL.ERROR_STACKTRACE);

                v_XML_DETAIL := NULL;
                RETURN v_XML_DETAIL;
                RAISE;
    END CREATE_UUT_QUERY_XML;
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
							       FALSE, v_TRANSACTION_ID, g_GO_ALLOWED_TAGS, g_GO_TAG_OPERATIONS,
								   NULL, NULL, NULL, NULL, p_LOGGER);

        RETURN NULL;

        EXCEPTION
           WHEN OTHERS THEN
              p_LOGGER.LOG_ERROR('Error parsing Gen Offer submission XML (' ||
                               ENTITY_NAME_FROM_IDS(EC.ED_TRANSACTION, v_TRANSACTION_ID) || ' for ' ||
                               TO_CHAR(p_DATE, MM_SEM_UTIL.g_DATE_FORMAT) || '):' ||
                               MM_SEM_UTIL.ERROR_STACKTRACE);
    END PARSE_QUERY_XML;
    ------------------------------------------------------------------------------
    FUNCTION PARSE_SUBMISSION_RESPONSE_XML
    (
        p_TRANSACTION_IDs IN NUMBER_COLLECTION,
        p_DATE           IN DATE,
        p_RESPONSE       IN XMLTYPE,
        p_LOGGER         IN OUT NOCOPY MM_LOGGER_ADAPTER
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE);
    END PARSE_SUBMISSION_RESPONSE_XML;
    ------------------------------------------------------------------------------
    PROCEDURE IMPORT_UUT
     (
     p_TRANSACTION_ID IN NUMBER,
     p_DATE           IN DATE,
     p_STATUS         IN VARCHAR2,
     p_EXT_ID         IN VARCHAR2,

     p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
     ) AS
    v_START_DATE DATE;
    v_SCHEDULE_DATE DATE;
    v_START VARCHAR2(32);
    BEGIN
        -- store the external id trait
        IF p_EXT_ID IS NOT NULL THEN
           TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TRANSACTION_ID, MM_SEM_UTIL.g_OFFER_SCHEDULE_STATE, 0, TRUNC(p_DATE)+1/86400, MM_SEM_UTIL.g_TG_EXT_IDENT, 1, 1, p_EXT_ID);
        END IF;

        -- store the status trait
        IF p_STATUS IS NOT NULL THEN
           TG.PUT_IT_TRAIT_SCHEDULE_AS_CUT(p_TRANSACTION_ID, GA.INTERNAL_STATE, 0, TRUNC(p_DATE)+1/86400, MM_SEM_UTIL.g_TG_GEN_UNDER_TEST, MM_SEM_UTIL.g_TI_STATUS, 1, p_STATUS);
        END IF;
    END IMPORT_UUT;
    ------------------------------------------------------------------------------
    FUNCTION PARSE_UUT_SUBMISSION_RESP_XML
     (
     p_TRANSACTION_IDs IN NUMBER_COLLECTION,
     p_DATE IN DATE,
     p_RESPONSE IN XMLTYPE,
      p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
     ) RETURN VARCHAR2 IS

        v_ERRORS         VARCHAR2(4000);
        v_IDX            BINARY_INTEGER;
        v_COUNT          BINARY_INTEGER;
        v_TRANSACTION_ID NUMBER(9);

        CURSOR c_UUTs IS
        -- no order by means we rely on order of elements defined in XML - that is the same order of
        -- IDs in the p_TRANSACTION_IDs collection
        -- Import just the Status for Submission response
        SELECT EXTRACTVALUE(VALUE(T), '/sem_unit_under_test/@status') as STATUS
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_RESPONSE, '/sem_unit_under_test'))) T;
       BEGIN
        --First check for errors
        v_ERRORS := MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE);
        p_LOGGER.LOG_DEBUG('Parsing XML:' || p_RESPONSE.getClobval());

        IF v_ERRORS IS NOT NULL THEN
            RETURN v_ERRORS;
        ELSE
            v_IDX   := p_TRANSACTION_IDs.FIRST;
            v_COUNT := 0;

            FOR v_UUT IN c_UUTs LOOP
                v_COUNT := v_COUNT + 1;
                IF NOT p_TRANSACTION_IDs.EXISTS(v_IDX) THEN
                    p_LOGGER.LOG_ERROR('Importing Unit Under Test: insufficient number (' ||
                                       p_TRANSACTION_IDs.COUNT ||
                                       ') of transaction IDs');
                    RETURN NULL;
                ELSE
                    v_TRANSACTION_ID := p_TRANSACTION_IDs(v_IDX);
                END IF;

                IMPORT_UUT(v_TRANSACTION_ID,
                           p_DATE,
                           v_UUT.STATUS,
                           NULL,
                           p_LOGGER);

                p_LOGGER.LOG_DEBUG('Imported Traits for Txn ID:' || v_TRANSACTION_ID);

                v_IDX := p_TRANSACTION_IDs.NEXT(v_IDX);
            END LOOP;

            -- too many transaction IDs?
            IF p_TRANSACTION_IDs.EXISTS(v_IDX) THEN
                p_LOGGER.LOG_ERROR('Importing Unit Under Test: superfluous number (' ||
                                   p_TRANSACTION_IDs.COUNT ||
                                   ') of transaction IDs (only ' ||
                                   v_COUNT || ' needed)');
            END IF;

            RETURN NULL;
        END IF;
    END PARSE_UUT_SUBMISSION_RESP_XML;
    ------------------------------------------------------------------------------
    FUNCTION PARSE_UUT_QUERY_RESP_XML(p_TRANSACTION_IDs IN NUMBER_COLLECTION,
                                 p_DATE            IN DATE,
                                 p_RESPONSE        IN XMLTYPE,
                                 p_LOGGER          IN OUT NOCOPY MM_LOGGER_ADAPTER)
        RETURN VARCHAR2 IS

        v_ERRORS         VARCHAR2(4000);
        v_IDX            BINARY_INTEGER;
        v_COUNT          BINARY_INTEGER;
        v_TRANSACTION_ID NUMBER(9);

        CURSOR c_UUTs IS
        -- no order by means we rely on order of elements defined in XML - that is the same order of
        -- IDs in the p_TRANSACTION_IDs collection
        -- Import just the Status and External ID for Query response
            SELECT EXTRACTVALUE(VALUE(T), '/sem_unit_under_test/identifier/@external_id') as EXT_ID,
                   EXTRACTVALUE(VALUE(T), '/sem_unit_under_test/@status') as STATUS
              FROM TABLE(XMLSEQUENCE(EXTRACT(p_RESPONSE, '/sem_unit_under_test'))) T;
    BEGIN
        --First check for errors
        v_ERRORS := MM_SEM_OFFER_UTIL.PARSE_SUBMISSION_XML(p_RESPONSE);
        p_LOGGER.LOG_DEBUG('Parsing XML:' || p_RESPONSE.getClobval());

        IF v_ERRORS IS NOT NULL THEN
            RETURN v_ERRORS;
        ELSE
            v_IDX   := p_TRANSACTION_IDs.FIRST;
            v_COUNT := 0;

            FOR v_UUT IN c_UUTs LOOP
                v_COUNT := v_COUNT + 1;
                IF NOT p_TRANSACTION_IDs.EXISTS(v_IDX) THEN
                    p_LOGGER.LOG_ERROR('Importing Unit Under Test: insufficient number (' ||
                                       p_TRANSACTION_IDs.COUNT ||
                                       ') of transaction IDs');
                    RETURN NULL;
                ELSE
                    v_TRANSACTION_ID := p_TRANSACTION_IDs(v_IDX);
                END IF;

                IMPORT_UUT(v_TRANSACTION_ID,
                           p_DATE,
                           v_UUT.STATUS,
                           v_UUT.EXT_ID,
                           p_LOGGER);

                p_LOGGER.LOG_DEBUG('Imported Traits for Txn ID:' || v_TRANSACTION_ID);

                v_IDX := p_TRANSACTION_IDs.NEXT(v_IDX);
            END LOOP;

            -- too many transaction IDs?
            IF p_TRANSACTION_IDs.EXISTS(v_IDX) THEN
                p_LOGGER.LOG_ERROR('Importing Unit Under Test: superfluous number (' ||
                                   p_TRANSACTION_IDs.COUNT ||
                                   ') of transaction IDs (only ' ||
                                   v_COUNT || ' needed)');
            END IF;

            RETURN NULL;
        END IF;
    END PARSE_UUT_QUERY_RESP_XML;
BEGIN
  ------------------------------------------------------------------------------
  -- Generation Query Offer XML Tag MetaData
  -- Allowed Tags(Parent/Child) mapping
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER)('') := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER):= TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_STANDING)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_STANDING):= TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_FUEL_USE)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_SECONDARY_FORECAST)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_FORECAST):= TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_FUEL_USE):= TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL):= TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL):= TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_SEC_NOMINATION_PROFILE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE)(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL):= TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL)(MM_SEM_OFFER_UTIL.g_TAG_SEM_GEN_OFFER) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL):= TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_PERIOD_FLAG)(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL) := TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_PERIOD_FLAG):= TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE):= TRUE;
  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_POINT)(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_SEC_NOMINATION_PROFILE) := TRUE;

  g_GO_ALLOWED_TAGS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES)(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE) := TRUE;

  -- Tags/Attributes
  -- Messages
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_NO_OP;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_MESSAGES).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
    -- Standing
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Expiry
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_STANDING_OFFER;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).TRAIT_IDX := MM_SEM_UTIL.G_TI_STANDING_EXPIRY_DATE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXPIRY).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Type
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_STANDING_OFFER;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_IDX := MM_SEM_UTIL.G_TI_STANDING_TYPE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STANDING).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Identifier
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- External Identifier Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_EXT_IDENT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_IDENTIFIER).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_EXT_ID).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Forecast
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Minimum MW Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_MW).TRAIT_IDX := MM_SEM_UTIL.G_TI_GEN_FORECAST_MIN;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
      -- Maximum MW Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).TRAIT_IDX := MM_SEM_UTIL.G_TI_GEN_FORECAST_MAX;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
      -- Minimum Output MW Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_OP_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_OP_MW).TRAIT_IDX := MM_SEM_UTIL.G_TI_GEN_FORECAST_MIN_OUTPUT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MIN_OP_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
    -- Fuel Use
    g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FUEL_USE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
    g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FUEL_USE).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
        -- Type
	    g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FUEL_USE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	    g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FUEL_USE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_FORECAST_FUEL_USE;
	    g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_FUEL_USE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TYPE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
    -- Secondary Forecast
    g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SECONDARY_FORECAST).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
    g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SECONDARY_FORECAST).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Maximum MW Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SECONDARY_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_FORECAST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SECONDARY_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_FORECAST_2ND_MAX_MW;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SECONDARY_FORECAST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MAX_MW).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Pump Storage Details
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Target Reservoir Level MW Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TARGET_RESV_LEVEL_MWH).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TARGET_RESV_LEVEL_MWH).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_RESERVOIR_TARGET_MWH;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TARGET_RESV_LEVEL_MWH).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Target Reservoir Level Percentage Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TARGET_RESV_LEVEL_PCT).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TARGET_RESV_LEVEL_PCT).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_RESERVOIR_TARGET_PCT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_TARGET_RESV_LEVEL_PCT).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Prior Day End Reservoir Level MWH Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRIOR_DAY_END_RESV_MWH).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRIOR_DAY_END_RESV_MWH).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_RESERVOIR_PRIOR_MWH;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRIOR_DAY_END_RESV_MWH).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Operational Reservoir Capacity MWH Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_OPER_RESV_CAP_LIMIT_MWH).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_RESERVOIR_CO;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_OPER_RESV_CAP_LIMIT_MWH).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_RESERVOIR_OP_CAP_MWH;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_OPER_RESV_CAP_LIMIT_MWH).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Spin Generation Cost Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_SPIN_GENERATION_COST).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_SPIN_GEN_COST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_SPIN_GENERATION_COST).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_SPIN_GENERATION_COST).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Spin Pump Cost Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_SPIN_PUMP_COST).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_SPIN_PUMP_COST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_SPIN_PUMP_COST).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_SPIN_PUMP_COST).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
      -- Min Gen Cost Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MINIMUM_GENERATION_COST).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_MIN_GEN_COST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MINIMUM_GENERATION_COST).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PUMP_STORAGE_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_MINIMUM_GENERATION_COST).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Energy Limit Details
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Limit MWH Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_MWH).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_LIMIT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_MWH).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_LIMIT_MWH;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_MWH).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Limit Factor Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_FACTOR).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_LIMIT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_FACTOR).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_LIMIT_FACTOR;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_DETAIL).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_FACTOR).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Energy Limit Period Flag
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_PERIOD_FLAG).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_PERIOD_FLAG).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Limit Flag Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_PERIOD_FLAG).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_FLAG).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_IS_LIMITED;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_PERIOD_FLAG).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_FLAG).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_ENERGY_LIMIT_PERIOD_FLAG).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_LIMIT_FLAG).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_BOOLEAN;
  -- Price Maker Details
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_CONTAINER;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_MAKER_DETAIL).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
  -- Price Taker Details
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_CONTAINER;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PRICE_TAKER_DETAIL).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
  -- PQ Curve
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_SERIES;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_PQ_CURVE).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
  -- PQ Point
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Price Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).TRAIT_GROUP_ID := TG.g_TG_OFFER_CURVE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).TRAIT_IDX := TG.g_TI_OFFER_PRICE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_PRICE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Quantity Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).TRAIT_GROUP_ID := TG.g_TG_OFFER_CURVE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).TRAIT_IDX := TG.g_TI_OFFER_QUANTITY;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_POINT).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_QTY).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Startup Cost
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Hot Attribute
      g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_HOT_STARTUP_COST).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_STARTUP_COSTS;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_HOT_STARTUP_COST).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_HOT_START_COST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_HOT_STARTUP_COST).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Warm Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_WARM_STARTUP_COST).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_STARTUP_COSTS;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_WARM_STARTUP_COST).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_WARM_START_COST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_WARM_STARTUP_COST).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
	  -- Cold Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_COLD_STARTUP_COST).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_GEN_STARTUP_COSTS;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_COLD_STARTUP_COST).TRAIT_IDX := MM_SEM_UTIL.g_TI_GEN_COLD_START_COST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_STARTUP_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_COLD_STARTUP_COST).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- No Load Cost
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST).INTERVAL := MM_SEM_OFFER_UTIL.g_DAILY_INTERVAL;
      -- Value Attribute
      g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_NO_LOAD_COST;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NO_LOAD_COST).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Nomination Profile
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Value Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_NOM_PROFILE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_IDX := MM_SEM_UTIL.g_TI_OFFER_1ST_NOM_PROFILE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Secondary Nomination Profile
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SEC_NOMINATION_PROFILE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SEC_NOMINATION_PROFILE).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Value Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SEC_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_NOM_PROFILE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SEC_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_IDX := MM_SEM_UTIL.g_TI_OFFER_2ND_NOM_PROFILE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_SEC_NOMINATION_PROFILE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;
  -- Decremental Price
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).TAG_TYPE := MM_SEM_OFFER_UTIL.g_TAG_TYPE_DATA;
  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).INTERVAL := MM_SEM_OFFER_UTIL.g_30MINUTES_INTERVAL;
      -- Value Attribute
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_GROUP_ID := MM_SEM_UTIL.g_TG_OFFER_DEC_PRICE;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).TRAIT_IDX := MM_SEM_OFFER_UTIL.g_TI_DEFAULT;
	  g_GO_TAG_OPERATIONS(MM_SEM_OFFER_UTIL.g_TAG_DECREMENTAL_PRICE).ATTR_INFO_MAP(MM_SEM_OFFER_UTIL.g_ATTR_VALUE).ATTR_TYPE := MM_SEM_OFFER_UTIL.g_ATTR_TYPE_STRING;


END MM_SEM_GEN_OFFER;
/
