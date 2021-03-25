CREATE OR REPLACE PACKAGE BODY MM_MISO_LMP IS

g_COMM_RT_ENERGY VARCHAR2(16) := 'RealTime Energy';
g_COMM_DA_ENERGY VARCHAR2(16) := 'DayAhead Energy';
g_REALTIME VARCHAR2(16) := 'RealTime';
g_DAYAHEAD VARCHAR2(16) := 'DayAhead';
g_MISO_SC_ID SCHEDULE_COORDINATOR.SC_ID%TYPE;
g_DATE_FORMAT CONSTANT VARCHAR2(16) := 'YYYY-MM-DD';
g_MISO_NAMESPACE CONSTANT VARCHAR2(64) := MM_MISO.g_MISO_NAMESPACE;
g_MISO_NAMESPACE_NAME CONSTANT VARCHAR2(64) := MM_MISO.g_MISO_NAMESPACE_NAME;
g_LMP_PRICE_TYPE VARCHAR2(32) := 'Locational Marginal Price';
g_MLC_PRICE_TYPE VARCHAR2(32) := 'Marginal Loss Component';
g_MCC_PRICE_TYPE VARCHAR2(32) := 'Marginal Congestion Component';
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION ID_FOR_MARKET_PRICE(p_LOCATION_NAME       IN VARCHAR2,
                             p_MARKET_PRICE_TYPE   IN VARCHAR2,
                             p_MARKET_PRICE_ABBR   IN VARCHAR2,
                             p_MARKET_TYPE         IN VARCHAR2,
                             p_INTERVAL            IN VARCHAR2
                             ) RETURN NUMBER IS
    v_EXTERNAL_IDENTIFIER MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
    v_POD_ID              NUMBER(9);
    v_MARKET_PRICE_ID     NUMBER(9);
    v_MARKET_TYPE_ABBR    VARCHAR2(3);
    v_SC_ID               NUMBER(9) := MM_MISO_UTIL.GET_MISO_SC_ID;
	v_COMMODITY_ID IT_COMMODITY.COMMODITY_ID%TYPE;
	v_CREATE_SVC_PT BOOLEAN;
BEGIN
    v_MARKET_TYPE_ABBR := CASE p_MARKET_TYPE WHEN g_DAYAHEAD THEN 'DA' ELSE 'RT' END;
	ID.ID_FOR_COMMODITY(CASE p_MARKET_TYPE WHEN g_DAYAHEAD THEN g_COMM_DA_ENERGY ELSE g_COMM_RT_ENERGY END, TRUE, v_COMMODITY_ID);
    IF UPPER(p_INTERVAL) = '5 MINUTE' THEN
        v_MARKET_TYPE_ABBR := v_MARKET_TYPE_ABBR || '5';
    END IF;

    BEGIN
        SELECT A.MARKET_PRICE_ID
          INTO v_MARKET_PRICE_ID
          FROM MARKET_PRICE A, SERVICE_POINT B
         WHERE B.EXTERNAL_IDENTIFIER = p_LOCATION_NAME
           AND A.POD_ID = B.SERVICE_POINT_ID
           AND A.SC_ID = v_SC_ID
           AND A.MARKET_PRICE_TYPE = p_MARKET_PRICE_TYPE
           AND UPPER(A.MARKET_PRICE_INTERVAL) = UPPER(p_INTERVAL)
           AND (A.MARKET_TYPE = p_MARKET_TYPE OR A.COMMODITY_ID = v_COMMODITY_ID)
           AND ROWNUM = 1; --Just in case it is not unique (should be, but not enforced in DB)
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            --CREATE THE MARKET PRICE.
            --MARKET PRICE IDENTIFIER:
            --MISO:<RESOURCE_NAME>:<PRICE_TYPE_ABBR>:<MARKET_TYPE>
            v_EXTERNAL_IDENTIFIER := 'MISO:' || p_LOCATION_NAME || ':' || p_MARKET_PRICE_ABBR || ':' ||
                                     v_MARKET_TYPE_ABBR;
            CASE NVL(GET_DICTIONARY_VALUE('Autocreate LMP Service Points', 0, 'MarketExchange', 'MISO', 'Public LMP'), 0)
			WHEN 1 THEN
				v_CREATE_SVC_PT := TRUE;
			ELSE
				v_CREATE_SVC_PT := FALSE;
			END CASE;
			ID.ID_FOR_SERVICE_POINT_XID(p_LOCATION_NAME, v_CREATE_SVC_PT, v_POD_ID);
            IO.PUT_MARKET_PRICE(v_MARKET_PRICE_ID,
                                v_EXTERNAL_IDENTIFIER,
                                v_EXTERNAL_IDENTIFIER, -- ALIAS
                                v_EXTERNAL_IDENTIFIER, -- DESC
                                0,
                                p_MARKET_PRICE_TYPE, -- MARKET_PRICE_TYPE
                                p_INTERVAL, --MARKET_PRICE_INTERVAL
                                p_MARKET_TYPE, --MARKET_TYPE
                                v_COMMODITY_ID, -- COMMODITY_ID
                                'Point', -- SERVICE_POINT_TYPE
                                v_EXTERNAL_IDENTIFIER, -- EXTERNAL_IDENTIFIER
                                0, -- EDC_ID
                                MM_MISO_UTIL.GET_MISO_SC_ID, --SC_ID
                                v_POD_ID, -- POD_ID
                                0 -- ZOD_ID
                                );
    END;

    RETURN v_MARKET_PRICE_ID;
END ID_FOR_MARKET_PRICE;

-------------------------------------------------------------------------------------
PROCEDURE PUT_MARKET_PRICE_LMP
    (
    p_PRICE_DATE IN DATE,
    p_LOCATION_NAME IN VARCHAR2,
    p_MARKET_PRICE_TYPE IN VARCHAR2,
    p_MARKET_PRICE_ABBR IN VARCHAR2,
    p_MARKET_TYPE IN VARCHAR2,
    p_INTERVAL IN VARCHAR2,
    p_PRICE IN NUMBER,    
    p_ERROR_MESSAGE OUT VARCHAR2
    ) AS
v_MARKET_PRICE_ID NUMBER(9);
v_PRICE_BASIS NUMBER := NULL;
v_PRICE_CODE CHAR(1) := 'A';                                                                                                                                                                                                                  --ACTUAL
v_AS_OF_DATE DATE := LOW_DATE;                                                                                                                                         --ASSUME GA.VERSION_MARKET_PRICE IS FALSE.  IF NOT, IT SHOULD BE SYSDATE.
BEGIN
       
    --GET MARKET PRICE RELATED TO THE GIVEN SERVICE POINT, TYPE, AND INTERVAL.    
    v_MARKET_PRICE_ID := MM_MISO.ID_FOR_MARKET_PRICE(p_LOCATION_NAME, p_MARKET_PRICE_TYPE, p_MARKET_PRICE_ABBR, p_MARKET_TYPE, p_INTERVAL);

    --DO THE UPDATE OR INSERT.
    UPDATE MARKET_PRICE_VALUE
    SET PRICE_BASIS = v_PRICE_BASIS,
        PRICE = p_PRICE
    WHERE  MARKET_PRICE_ID = v_MARKET_PRICE_ID AND PRICE_CODE = v_PRICE_CODE AND PRICE_DATE = p_PRICE_DATE AND AS_OF_DATE = v_AS_OF_DATE;

    IF SQL%NOTFOUND THEN
        INSERT INTO MARKET_PRICE_VALUE
                    (
                     MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE
                    )
        VALUES      (
                     v_MARKET_PRICE_ID, v_PRICE_CODE, p_PRICE_DATE, v_AS_OF_DATE, v_PRICE_BASIS, p_PRICE
                    );
    END IF;
   
    EXCEPTION
        WHEN OTHERS THEN             
            p_ERROR_MESSAGE := SQLERRM;
    END PUT_MARKET_PRICE_LMP;
-------------------------------------------------------------------------------------
PROCEDURE IMPORT_LMP(p_MARKET_TYPE IN VARCHAR2,
                     p_RECORDS     IN MEX_MISO_LMP_OBJ_TBL,
                     p_STATUS      OUT NUMBER,
                     p_MESSAGE     OUT VARCHAR2) IS
    v_IDX            BINARY_INTEGER;
    v_PRICE_IDX      BINARY_INTEGER;
    v_PRICES         PRICE_QUANTITY_SUMMARY_TABLE;
    v_LAST_CPNODE_ID VARCHAR2(255) := 'foobar';
	v_LAST_PRICE_TYPE_ABBR VARCHAR2(3) := 'jbc';
    v_MKT_PRICE_TYPE MARKET_PRICE.MARKET_PRICE_TYPE%TYPE;
    v_MPV_ROW        MARKET_PRICE_VALUE%ROWTYPE;
    v_MARKET_TYPE    VARCHAR2(32);
	TYPE ARRAY IS VARRAY(3) OF VARCHAR2(1);
    v_PRICE_CODE_ARRAY ARRAY;
	v_SERVICE_POINT_ID SERVICE_POINT.SERVICE_POINT_ID%TYPE;
BEGIN
    p_STATUS := GA.SUCCESS;

    v_PRICE_CODE_ARRAY := ARRAY('A');

    IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
        v_MARKET_TYPE := g_DAYAHEAD;
    ELSE
        v_MARKET_TYPE := g_REALTIME;
    END IF;

    v_MPV_ROW.AS_OF_DATE  := LOW_DATE;
    v_MPV_ROW.PRICE_BASIS := NULL;

    v_IDX := p_RECORDS.FIRST;
    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        IF (v_LAST_CPNODE_ID != p_RECORDS(v_IDX).NODE_NAME) OR
           (v_LAST_PRICE_TYPE_ABBR != p_RECORDS(v_IDX).PRICE_TYPE) THEN
            v_LAST_CPNODE_ID       := p_RECORDS(v_IDX).NODE_NAME;
            v_LAST_PRICE_TYPE_ABBR := p_RECORDS(v_IDX).PRICE_TYPE;
            CASE v_LAST_PRICE_TYPE_ABBR
                WHEN 'LMP' THEN
                    v_MKT_PRICE_TYPE := g_LMP_PRICE_TYPE;
                WHEN 'MCC' THEN
                    v_MKT_PRICE_TYPE := g_MCC_PRICE_TYPE;
                WHEN 'MLC' THEN
                    v_MKT_PRICE_TYPE := g_MLC_PRICE_TYPE;
            END CASE;

			-- if the service point exists, then get/create the market price
			BEGIN
				-- note that I can't use ID.ID_FOR_SERVICE_POINT_XID here, since if it
				-- can't find the XID it looks up based on the name (NO NO NO)
        		SELECT SERVICE_POINT_ID INTO v_SERVICE_POINT_ID
        		FROM SERVICE_POINT
        		WHERE EXTERNAL_IDENTIFIER = v_LAST_CPNODE_ID;
                v_MPV_ROW.MARKET_PRICE_ID := ID_FOR_MARKET_PRICE(v_LAST_CPNODE_ID,
                                                                 v_MKT_PRICE_TYPE,
                                                                 v_LAST_PRICE_TYPE_ABBR,
                                                                 v_MARKET_TYPE,
                                                                 'Hour'
    															 );
        	EXCEPTION
        		WHEN NO_DATA_FOUND THEN
        			v_MPV_ROW.MARKET_PRICE_ID := NULL;
        	END;
		END IF;
        IF v_MPV_ROW.MARKET_PRICE_ID IS NOT NULL THEN
            v_PRICES    := p_RECORDS(v_IDX).PRICE_TBL;
            v_PRICE_IDX := v_PRICES.FIRST;
            WHILE v_PRICES.EXISTS(v_PRICE_IDX) LOOP
                v_MPV_ROW.PRICE_DATE := v_PRICES(v_PRICE_IDX).SCHEDULE_DATE; -- date already in CUT
                v_MPV_ROW.PRICE      := v_PRICES(v_PRICE_IDX).PRICE;

                FOR I IN v_PRICE_CODE_ARRAY.FIRST .. v_PRICE_CODE_ARRAY.LAST LOOP
                    BEGIN
                        INSERT INTO MARKET_PRICE_VALUE
                            (MARKET_PRICE_ID,
                             PRICE_CODE,
                             PRICE_DATE,
                             AS_OF_DATE,
                             PRICE_BASIS,
                             PRICE)
                        VALUES
                            (v_MPV_ROW.MARKET_PRICE_ID,
                             v_PRICE_CODE_ARRAY(I),
                             v_MPV_ROW.PRICE_DATE,
                             LOW_DATE,
                             NULL,
                             v_MPV_ROW.PRICE);
                    EXCEPTION
                        --do an update for already existing entities
                        WHEN DUP_VAL_ON_INDEX THEN
                            UPDATE MARKET_PRICE_VALUE
                               SET PRICE = v_MPV_ROW.PRICE
                             WHERE MARKET_PRICE_ID = v_MPV_ROW.MARKET_PRICE_ID
                               AND PRICE_CODE = v_PRICE_CODE_ARRAY(I)
                               AND PRICE_DATE = v_MPV_ROW.PRICE_DATE
                               AND AS_OF_DATE = LOW_DATE;
                    END;
                END LOOP;

                v_PRICE_IDX := v_PRICES.NEXT(v_PRICE_IDX);
            END LOOP;
        END IF;

        v_IDX := p_RECORDS.NEXT(v_IDX);
    END LOOP;
EXCEPTION
    WHEN OTHERS THEN
        P_STATUS  := SQLCODE;
        P_MESSAGE := 'MM_MISO_LMP.IMPORT_LMP: ' || SQLERRM;
END IMPORT_LMP;

  ----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_RT_INTEGRATED_LMP_ALL
    (
    p_CRED IN mex_credentials,
    p_RESPONSE_NAME IN VARCHAR2,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_LOG_ONLY IN NUMBER,
    p_ERROR_MESSAGE OUT VARCHAR2,
    p_LOGGER IN OUT MM_LOGGER_ADAPTER
    ) AS
v_XML_REQUEST XMLTYPE;
v_XML_RESPONSE XMLTYPE;
v_INTERVAL NUMBER(2);
v_MARKET_TYPE VARCHAR2(16);
v_LMP_PRICE_ABBR VARCHAR2(3) := 'LMP';
v_MLC_PRICE_ABBR VARCHAR2(3) := 'MLC';
v_MCC_PRICE_ABBR VARCHAR2(3) := 'MCC';
v_MARKET_PRICE_INTERVAL VARCHAR2(16) := 'Hour';
CURSOR c_XML IS
            SELECT TO_DATE(EXTRACTVALUE(VALUE(T), '//@day', g_MISO_NAMESPACE), g_DATE_FORMAT) "RESPONSE_DAY", EXTRACTVALUE(VALUE(U), '//@location', g_MISO_NAMESPACE) "LOCATION_NAME", EXTRACTVALUE(VALUE(V), '//@hour', g_MISO_NAMESPACE) "RESPONSE_HOUR",
                   EXTRACTVALUE(VALUE(V), '//LMP', g_MISO_NAMESPACE) "LMP", EXTRACTVALUE(VALUE(V), '//MCC', g_MISO_NAMESPACE) "MCC", EXTRACTVALUE(VALUE(V), '//MLC', g_MISO_NAMESPACE) "MLC"
            FROM   TABLE(XMLSEQUENCE(EXTRACT(v_XML_RESPONSE, '//' || p_RESPONSE_NAME, g_MISO_NAMESPACE))) T,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(T), '//PricingNode', g_MISO_NAMESPACE))) U,
                   TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//PricingNodeHourly', g_MISO_NAMESPACE))) V;
BEGIN
    
    v_INTERVAL := GET_INTERVAL_NUMBER('HH');
    v_MARKET_TYPE := g_REALTIME;
    
    SELECT XMLELEMENT("QueryRequest", XMLATTRIBUTES(g_MISO_NAMESPACE_NAME AS "xmlns"),
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
                         
       
    MM_MISO.RUN_MISO_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_ERROR_MESSAGE, p_LOGGER);
        

    FOR v_XML IN c_XML LOOP
        --PUT LMP COMPONENT.
        PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24, v_XML.LOCATION_NAME, g_LMP_PRICE_TYPE, v_LMP_PRICE_ABBR, v_MARKET_TYPE, v_MARKET_PRICE_INTERVAL, v_XML.LMP, p_ERROR_MESSAGE);

        --PUT MLC COMPONENT.
        PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24, v_XML.LOCATION_NAME, g_MLC_PRICE_TYPE, v_MLC_PRICE_ABBR, v_MARKET_TYPE, v_MARKET_PRICE_INTERVAL, v_XML.MLC, p_ERROR_MESSAGE);
       
        --PUT MCC COMPONENT.
        PUT_MARKET_PRICE_LMP(v_XML.RESPONSE_DAY + v_XML.RESPONSE_HOUR / 24, v_XML.LOCATION_NAME, g_MCC_PRICE_TYPE, v_MCC_PRICE_ABBR, v_MARKET_TYPE, v_MARKET_PRICE_INTERVAL, v_XML.MCC, p_ERROR_MESSAGE);
       
    END LOOP;
     
EXCEPTION
    WHEN OTHERS THEN
        p_ERROR_MESSAGE := SQLERRM;
END QUERY_RT_INTEGRATED_LMP_ALL;
------------------------------------------------------------------------------------------------------------------
  PROCEDURE QUERY_LMP(p_MARKET_TYPE IN VARCHAR2,
                      p_DATE        IN DATE,
					  p_LOG_ONLY	IN NUMBER,
                      p_STATUS      OUT NUMBER,
                      p_MESSAGE     OUT VARCHAR2,
					  p_LOGGER		IN OUT mm_logger_adapter) IS
    v_LMP_TBL      MEX_MISO_LMP_OBJ_TBL;
  BEGIN
    p_STATUS           := GA.SUCCESS;

    MEX_MISO_LMP.FETCH_LMP_FILE(p_DATE,
                               	p_MARKET_TYPE,
								p_LOG_ONLY,
                               	v_LMP_TBL,
                               	p_STATUS,
                               	p_MESSAGE,
								p_LOGGER);
    IF p_STATUS = GA.SUCCESS THEN
      IMPORT_LMP(p_MARKET_TYPE, v_LMP_TBL, p_STATUS, p_MESSAGE);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_MESSAGE := SQLERRM;
      p_STATUS  := -1;

  END QUERY_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_LOG_ONLY					IN NUMBER := 0,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

	v_CURRENT_DATE DATE;
	v_ACTION VARCHAR2(64);
	v_NO_SUBMIT BOOLEAN := FALSE;
    V_MARKET_TYPE VARCHAR2(32);

	v_CRED MEX_CREDENTIALS;
	v_LOGGER MM_LOGGER_ADAPTER;
	v_LOG_ONLY NUMBER;
BEGIN
	v_ACTION := p_EXCHANGE_TYPE;
	v_LOG_ONLY := NVL(p_LOG_ONLY,0);

	MM_UTIL.INIT_MEX(EC.ES_MISO, NULL, 'MISO:LMP', v_ACTION, p_LOG_TYPE, p_TRACE_ON, v_CRED, v_LOGGER, TRUE);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	--LOOP OVER DATES
	v_CURRENT_DATE := TRUNC(p_BEGIN_DATE);
	LOOP
		CASE v_ACTION
			WHEN g_ET_QRY_DA_LMP THEN
				v_MARKET_TYPE := 'DA';
            WHEN g_ET_QRY_RT_LMP THEN
             	v_MARKET_TYPE := 'RT';               
		--	WHEN g_ET_QRY_RT_INTEGRATED_LMP THEN
		--		v_MARKET_TYPE := 'RT';
			ELSE
				p_STATUS := -1;
				p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
				v_LOGGER.LOG_ERROR(p_MESSAGE);
				EXIT;
		END CASE;

		IF NOT NVL(v_NO_SUBMIT, TRUE) THEN
			QUERY_LMP(v_MARKET_TYPE, v_CURRENT_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
		END IF;

		EXIT WHEN v_CURRENT_DATE >= TRUNC(p_END_DATE);
		v_CURRENT_DATE := v_CURRENT_DATE + 1;
	END LOOP;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
---------------------------------------------------------------------------------------------------
BEGIN
  -- Initialization
  g_MISO_SC_ID := MM_MISO_UTIL.GET_MISO_SC_ID;
EXCEPTION
  WHEN OTHERS THEN
    g_MISO_SC_ID := 0;

END MM_MISO_LMP;
/
