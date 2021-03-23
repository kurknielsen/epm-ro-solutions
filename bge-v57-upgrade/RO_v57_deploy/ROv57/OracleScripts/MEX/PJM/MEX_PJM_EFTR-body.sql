CREATE OR REPLACE PACKAGE BODY MEX_PJM_EFTR IS

	g_PACKAGE_NAME CONSTANT VARCHAR2(14) := 'MEX_PJM_EFTR';
	g_ANNUAL_AUCTION_BEGIN_MONTH CONSTANT VARCHAR2(3) := 'JUL';
	g_PJM_EFTR_NAMESPACE      CONSTANT VARCHAR2(64) := 'xmlns="http://eftr.pjm.com/ftr/xml"';
	g_PJM_EFTR_MKT            CONSTANT VARCHAR2(8) := 'pjmeftr';
	g_DATE_TIME_ZONE_FORMAT CONSTANT VARCHAR2(64) := 'yyyy-mm-dd"T"hh24:mi:ss.%%%"-%%:00"';

  ---------------------------------------------------------------------------------------------------
  FUNCTION WHAT_VERSION RETURN VARCHAR IS
  BEGIN
    RETURN '$Revision: 1.1 $';
  END WHAT_VERSION;
  ---------------------------------------------------------------------------------------------------
  FUNCTION PACKAGE_NAME RETURN VARCHAR IS
  BEGIN
    RETURN g_PACKAGE_NAME;
  END PACKAGE_NAME;
---------------------------------------------------------------------------------------------------
 FUNCTION SAFE_STRING(p_XML       IN XMLTYPE,
                      p_XPATH     IN VARCHAR2,
                      p_NAMESPACE IN VARCHAR2 := NULL) RETURN VARCHAR2 IS
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

-------------------------------------------------------------------------------------

PROCEDURE RUN_PJM_QUERY
	(
	P_CRED IN mex_credentials,
	P_LOG_ONLY IN BINARY_INTEGER,
	P_XML_REQUEST_BODY IN XMLTYPE,
	P_XML_RESPONSE_BODY OUT XMLTYPE,
	P_STATUS OUT NUMBER,
	P_ERROR_MESSAGE OUT VARCHAR2,
	P_LOGGER IN OUT mm_logger_adapter
	) AS

  BEGIN
    MEX_PJM.RUN_PJM_ACTION(P_CRED,
				   'query',
				   P_LOG_ONLY,
                   P_XML_REQUEST_BODY,
				   g_PJM_EFTR_NAMESPACE,
				   g_PJM_EFTR_MKT,
                   P_XML_RESPONSE_BODY,
				   P_STATUS,
                   P_ERROR_MESSAGE,
				   P_LOGGER);

  EXCEPTION
    WHEN OTHERS THEN
      p_ERROR_MESSAGE := 'MEX_PJM_EFTR.RUN_PJM_QUERY: ' || UT.GET_FULL_ERRM;
	  P_STATUS		  := SQLCODE;
END RUN_PJM_QUERY;

  -------------------------------------------------------------------------------------
  PROCEDURE GET_AUCTION_MARKET_DATES(p_AUCTION_MARKET_NAME IN VARCHAR2,
                                     p_AUCTION_BEGIN_DATE  OUT DATE,
                                     p_AUCTION_END_DATE    OUT DATE,
                                     p_IS_ANNUAL           OUT BOOLEAN,
                                     p_STATUS              OUT NUMBER,
                                     p_MESSAGE             OUT VARCHAR2) AS

    -- Answer DATES of FTR Auction Market based on given name.

    v_STRING_TABLE PARSE_UTIL.STRING_TABLE;
    v_YEAR         NUMBER(4);

  BEGIN

    p_IS_ANNUAL := FALSE;
    PARSE_UTIL.TOKENS_FROM_STRING(p_AUCTION_MARKET_NAME, ' ', v_STRING_TABLE);

    BEGIN
      v_YEAR               := TO_NUMBER(SUBSTR(v_STRING_TABLE(1), 1, 4));
      p_IS_ANNUAL          := TRUE; --VALID NUMBER
      p_AUCTION_BEGIN_DATE := TO_DATE('01-' || g_ANNUAL_AUCTION_BEGIN_MONTH || '-' ||
                                      v_YEAR,
                                      'DD-Mon-YYYY');
      p_AUCTION_END_DATE   := ADD_MONTHS(p_AUCTION_BEGIN_DATE, 12) - 1; --1 YEAR

    EXCEPTION
      --Doesn't start with a year, must be monthly
      WHEN OTHERS THEN
        p_IS_ANNUAL          := FALSE;
        p_AUCTION_BEGIN_DATE := TO_DATE('01-' ||
                                        SUBSTR(v_STRING_TABLE(1), 1, 3) || '-' ||
                                        v_STRING_TABLE(2),
                                        'DD-Mon-YYYY');
        p_AUCTION_END_DATE   := LAST_DAY(p_AUCTION_BEGIN_DATE); --1 MONTH

    END;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := -1;
      p_MESSAGE := '"' || p_AUCTION_MARKET_NAME ||
                   '" can not be parsed as a valid Auction Market name.  ' ||
                   PACKAGE_NAME || '.GET_AUCTION_MARKET_DATE';

  END GET_AUCTION_MARKET_DATES;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE GET_AUCTION_MARKET_NAMES_LIST(p_BEGIN_DATE           IN DATE,
                                          p_END_DATE             IN DATE,
                                          p_DELIMITER            IN CHAR,
                                          p_AUCTION_MARKET_NAMES OUT VARCHAR2,
                                          p_STATUS               OUT NUMBER,
                                          p_MESSAGE              OUT VARCHAR2) AS

    -- Answer delimited list of FTR Auction Market names based on given dates.

    v_DATE     DATE := TRUNC(p_BEGIN_DATE, 'MM');
    v_END_DATE DATE := TRUNC(p_END_DATE, 'MM');

  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    p_AUCTION_MARKET_NAMES := TRIM(TO_CHAR(v_DATE, 'MON')) || ' ' ||
                              TO_CHAR(v_DATE, 'YYYY') || ' Auction';

    WHILE v_DATE < v_END_DATE LOOP
      v_DATE                 := ADD_MONTHS(v_DATE, 1);
      p_AUCTION_MARKET_NAMES := p_AUCTION_MARKET_NAMES || p_DELIMITER ||
                                TRIM(TO_CHAR(v_DATE, 'MON')) || ' ' ||
                                TO_CHAR(v_DATE, 'YYYY') || ' Auction';
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := UT.GET_FULL_ERRM;

  END GET_AUCTION_MARKET_NAMES_LIST;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE GET_AUCTION_MARKET_NAMES_TABLE(p_BEGIN_DATE           IN DATE,
                                           p_END_DATE             IN DATE,
                                           p_ENTITY_LIST          IN VARCHAR2,
                                           p_ENTITY_DELIMITER     IN CHAR,
                                           p_AUCTION_MARKET_NAMES OUT PARSE_UTIL.STRING_TABLE,
                                           p_STATUS               OUT NUMBER,
                                           p_MESSAGE              OUT VARCHAR2) AS

    v_DATE         DATE := TRUNC(p_BEGIN_DATE, 'MM');
    v_END_DATE     DATE := TRUNC(p_END_DATE, 'MM');
    v_AUCTION_NAME VARCHAR2(64);
    v_INDEX        BINARY_INTEGER := 0;
  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    IF NOT (p_ENTITY_LIST IS NULL) THEN
      --Getting Selected Auction Names from the Entity List
      PARSE_UTIL.TOKENS_FROM_STRING(p_ENTITY_LIST,
                                  p_ENTITY_DELIMITER,
                                  p_AUCTION_MARKET_NAMES);

    ELSE

      v_AUCTION_NAME := TRIM(TO_CHAR(v_DATE, 'MON')) || ' ' ||
                        TO_CHAR(v_DATE, 'YYYY') || ' Auction';

      WHILE v_DATE <= v_END_DATE LOOP

        p_AUCTION_MARKET_NAMES(v_INDEX) := v_AUCTION_NAME;
        v_DATE := ADD_MONTHS(v_DATE, 1);
        v_INDEX := v_INDEX + 1;
      END LOOP;

    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := UT.GET_FULL_ERRM;

  END GET_AUCTION_MARKET_NAMES_TABLE;
  ---------------------------------------------------------------------------------------------------

  PROCEDURE GETX_QUERY_MARKET_RESULTS(p_XML_REQUEST_BODY     OUT XMLTYPE,
                                      p_STATUS               OUT NUMBER,
                                      p_MESSAGE              OUT VARCHAR2) AS

    v_AUCTION_MARKET_NAME VARCHAR2(64);
    v_LAST_AUCTION_NAME VARCHAR2(64);
    v_AUCTION_ROUND VARCHAR2(2);
    v_MARKET_PERIOD VARCHAR2(16);
    v_REQUEST       XMLTYPE;
    v_FTR_XML XMLTYPE;

    CURSOR c_MARKETS IS
    SELECT MKT_NAME, MKT_ROUND, MKT_PERIOD
    FROM PJM_EFTR_MARKET_INFO
    WHERE IS_ACTIVE = 1
    AND MKT_NAME NOT LIKE '%ARR%'
    ORDER BY BID_INT_START, MKT_INT_START, MKT_ROUND;
    -- don't include ARR auctions in query for FTR Auction results; this
    -- causes an error


  BEGIN
    p_STATUS := g_SUCCESS;

    FOR v_MARKET IN c_MARKETS LOOP
        v_AUCTION_MARKET_NAME := v_MARKET.MKT_NAME;
        --if the auctions have the same name, only request results once
        --because PJM just looks at the name and ignores the period, the
        --results are for all periods. don't want to request multiple times
        --as this will mess up FTR totals
        IF v_LAST_AUCTION_NAME IS NULL OR
            (v_LAST_AUCTION_NAME = v_AUCTION_MARKET_NAME AND v_AUCTION_ROUND <> v_MARKET.Mkt_Round)
            OR v_LAST_AUCTION_NAME <> v_AUCTION_MARKET_NAME THEN
            v_LAST_AUCTION_NAME := v_AUCTION_MARKET_NAME;
            v_AUCTION_ROUND := v_MARKET.MKT_ROUND;
            v_MARKET_PERIOD := v_MARKET.Mkt_Period;

            SELECT XMLELEMENT("QueryMarketResults",
                   XMLATTRIBUTES(v_AUCTION_MARKET_NAME  AS
                                 "market",
                                 v_AUCTION_ROUND AS
                                 "round"),
                                 --v_MARKET_PERIOD AS
                                -- "Period"),
                    XMLELEMENT("All"))
            INTO v_FTR_XML
            FROM DUAL;

            SELECT XMLCONCAT(v_REQUEST, v_FTR_XML)
            INTO v_REQUEST
            FROM DUAL;
        END IF;

    END LOOP;

    SELECT XMLELEMENT("QueryRequest",
                        XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                        v_REQUEST)
    INTO p_XML_REQUEST_BODY
    FROM DUAL;


  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_EFTR.GETX_QUERY_MARKET_RESULTS: ' || UT.GET_FULL_ERRM;

  END GETX_QUERY_MARKET_RESULTS;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_FTR_POSITION
    (
    p_XML_RESPONSE IN XMLTYPE,
    p_RECORDS IN OUT NOCOPY MEX_PJM_FTR_POSITION_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    CURSOR c_XML IS
        SELECT EXTRACTVALUE(VALUE(T), '//@date', g_FTR_NAMESPACE) "POSITION_DATE",
            EXTRACTVALUE(VALUE(U), '//MarketName', g_FTR_NAMESPACE) "MKT_NAME",
            EXTRACTVALUE(VALUE(V), '//@source', g_FTR_NAMESPACE) "SOURCE_NAME",
            EXTRACTVALUE(VALUE(V), '//@sink', g_FTR_NAMESPACE) "SINK_NAME",
            EXTRACTVALUE(VALUE(U), '//Trade', g_FTR_NAMESPACE) "BUY_SELL",
            EXTRACTVALUE(VALUE(U), '//Class', g_FTR_NAMESPACE) "CLASS",
            EXTRACTVALUE(VALUE(U), '//Period', g_FTR_NAMESPACE) "PERIOD",
            EXTRACTVALUE(VALUE(U), '//Hedge', g_FTR_NAMESPACE) "HEDGE_TYPE",
            EXTRACTVALUE(VALUE(U), '//MW', g_FTR_NAMESPACE) "MW_AMOUNT",
            EXTRACTVALUE(VALUE(U), '//Price', g_FTR_NAMESPACE) "PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//Positions',
                                       g_FTR_NAMESPACE))) T,
             --FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT xml from xml_trace WHERE key1 = 'MarketResults'),'//QueryResponse/MarketResults', g_FTR_NAMESPACE))) T,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//Position',
                                       g_FTR_NAMESPACE))) U,
        TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//Path', g_FTR_NAMESPACE))) V
        ORDER BY 3, 4, 5, 7, 9;

    BEGIN

    p_STATUS := GA.SUCCESS;

    FOR v_XML IN c_XML LOOP

        p_RECORDS.EXTEND();
        p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_POSITION(TO_DATE(v_XML.POSITION_DATE, 'YYYY-MM-DD'),
                                                      v_XML.MKT_NAME,
                                                      v_XML.SOURCE_NAME,
                                                      v_XML.SINK_NAME,
                                                      v_XML.BUY_SELL,
                                                      v_XML.CLASS,
                                                      v_XML.PERIOD,
                                                      v_XML.HEDGE_TYPE,
                                                      v_XML.MW_AMOUNT,
                                                      v_XML.PRICE);

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'ERROR OCCURED IN PARSE_FTR_POSITION' || UT.GET_FULL_ERRM;
END PARSE_FTR_POSITION;
---------------------------------------------------------------------------------------------------
PROCEDURE GETX_QUERY_POSITION
    (
    p_DATE IN DATE,
    p_XML_REQUEST_BODY OUT XMLTYPE,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

v_REQUEST       XMLTYPE;
v_POSITION_XML XMLTYPE;

BEGIN

    p_STATUS := GA.SUCCESS;
    v_REQUEST := NULL;

    SELECT XMLELEMENT("QueryPosition",
                      XMLELEMENT("Date", TO_CHAR(p_DATE, 'YYYY-MM-DD')))
    INTO v_POSITION_XML
    FROM DUAL;

    SELECT XMLCONCAT(v_REQUEST, v_POSITION_XML)
    INTO v_REQUEST
    FROM DUAL;

    SELECT XMLELEMENT("QueryRequest",
                        XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                        v_REQUEST)
    INTO p_XML_REQUEST_BODY
    FROM DUAL;


  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := UT.GET_FULL_ERRM;

END GETX_QUERY_POSITION;
-----------------------------------------------------------------------------------------------
PROCEDURE QUERY_FTR_POSITION
    (
	p_CRED IN mex_credentials,
	p_LOG_ONLY IN BINARY_INTEGER,
    p_DATE IN DATE,
    p_RECORDS OUT MEX_PJM_FTR_POSITION_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
    ) AS

v_XML_REQUEST  XMLTYPE;
v_XML_RESPONSE XMLTYPE;

BEGIN

    p_STATUS  := GA.SUCCESS;
    p_RECORDS := MEX_PJM_FTR_POSITION_TBL();

    ---BUILD XML REQUEST
    GETX_QUERY_POSITION(p_DATE, v_XML_REQUEST, p_STATUS, p_MESSAGE);


    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
		RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);
	END IF;

    PARSE_FTR_POSITION(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);


EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_FTR_POSITION: ' || UT.GET_FULL_ERRM;
END QUERY_FTR_POSITION;
-------------------------------------------------------------------------------------
PROCEDURE GETX_QUERY_PORTFOLIOS
    (p_PORTFOLIOS       IN PARSE_UTIL.STRING_TABLE,
                                  p_XML_REQUEST_BODY OUT XMLTYPE,
                                  p_CLOB             OUT CLOB,
                                  p_STATUS           OUT NUMBER,
                                  p_MESSAGE          OUT VARCHAR2) AS



    v_PORTFOLIO     VARCHAR2(64);
    v_REQUEST       XMLTYPE;
    v_INDEX         BINARY_INTEGER;
    v_PORTFOLIO_XML XMLTYPE;

  BEGIN

    p_STATUS := g_SUCCESS;

    IF p_PORTFOLIOS.COUNT = 0 THEN
      SELECT XMLELEMENT("QueryRequest",
                        XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                        XMLELEMENT("QueryPortfolios", XMLELEMENT("All")))
        INTO p_XML_REQUEST_BODY
        FROM DUAL;

    ELSE

      v_INDEX   := p_PORTFOLIOS.FIRST;
      v_REQUEST := NULL;

      WHILE p_PORTFOLIOS.EXISTS(v_INDEX) LOOP

        v_PORTFOLIO := p_PORTFOLIOS(v_INDEX);

        SELECT XMLELEMENT("QueryPortfolios",
                          XMLELEMENT("PortfolioName", v_PORTFOLIO))
          INTO v_PORTFOLIO_XML
          FROM DUAL;

        SELECT XMLCONCAT(v_REQUEST, v_PORTFOLIO_XML)
          INTO v_REQUEST
          FROM DUAL;

        v_INDEX := p_PORTFOLIOS.NEXT(v_INDEX);

      END LOOP;

      SELECT XMLELEMENT("QueryResponse",
                        XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                        v_REQUEST)
        INTO p_XML_REQUEST_BODY
        FROM DUAL;

    END IF;

    p_CLOB := p_XML_REQUEST_BODY.getclobval();

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := UT.GET_FULL_ERRM;

  END GETX_QUERY_PORTFOLIOS;
  ---------------------------------------------------------------------------------------------------

  PROCEDURE GETX_QUERY_CLEARED_FTRS(p_AUCTION_MARKET_NAME IN VARCHAR2,
                                    p_AUCTION_ROUND       IN VARCHAR2,
                                    p_XML_REQUEST_BODY    OUT XMLTYPE,
                                    p_STATUS              OUT NUMBER,
                                    p_MESSAGE             OUT VARCHAR2) AS


  BEGIN
    p_STATUS := g_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryClearedFTRs",
                                 XMLATTRIBUTES(p_AUCTION_MARKET_NAME AS
                                               "market",
                                               p_AUCTION_ROUND AS
                                               "round")))
    INTO p_XML_REQUEST_BODY
    FROM DUAL;


  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_EFTR.GETX_QUERY_CLEARED_FTRS: ' || UT.GET_FULL_ERRM;

  END GETX_QUERY_CLEARED_FTRS;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_INITIAL_ARR(p_XML_REQUEST_BODY     OUT XMLTYPE,
                                   p_STATUS               OUT NUMBER,
                                   p_MESSAGE              OUT VARCHAR2) AS

    v_AUCTION_MARKET_NAME VARCHAR2(64);
    v_AUCTION_ROUND VARCHAR2(2);
    v_REQUEST       XMLTYPE;
    v_FTR_XML XMLTYPE;

    CURSOR c_MARKETS IS
    SELECT MKT_NAME, MKT_ROUND
    FROM PJM_EFTR_MARKET_INFO
    WHERE IS_ACTIVE = 1;


  BEGIN
    p_STATUS := g_SUCCESS;

    FOR v_MARKET IN c_MARKETS LOOP
      v_AUCTION_MARKET_NAME := v_MARKET.MKT_NAME;
      v_AUCTION_ROUND := v_MARKET.MKT_ROUND;

      SELECT XMLELEMENT("QueryInitialARRs",
                       XMLATTRIBUTES(v_AUCTION_MARKET_NAME  AS
                                     "market"))

      INTO v_FTR_XML
      FROM DUAL;

      SELECT XMLCONCAT(v_REQUEST, v_FTR_XML)
      INTO v_REQUEST
      FROM DUAL;

    END LOOP;

    SELECT XMLELEMENT("QueryRequest",
                        XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                        v_REQUEST)
    INTO p_XML_REQUEST_BODY
    FROM DUAL;


  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_EFTR.GETX_QUERY_INITIAL_ARR: ' || UT.GET_FULL_ERRM;

  END GETX_QUERY_INITIAL_ARR;
  ---------------------------------------------------------------------------------------------------

  PROCEDURE GETX_QUERY_FTR_QUOTES(p_XML_REQUEST_BODY     OUT XMLTYPE,
                                  p_STATUS               OUT NUMBER,
                                  p_MESSAGE              OUT VARCHAR2) AS

    v_AUCTION_MARKET_NAME VARCHAR2(64);
    v_AUCTION_ROUND VARCHAR2(2);
    v_REQUEST       XMLTYPE;
    v_FTR_XML XMLTYPE;

    CURSOR c_MARKETS IS
    SELECT MKT_NAME, MKT_ROUND
    FROM PJM_EFTR_MARKET_INFO
    WHERE IS_ACTIVE = 1;

  BEGIN
    p_STATUS := g_SUCCESS;

    FOR v_MARKET IN c_MARKETS LOOP
      v_AUCTION_MARKET_NAME := v_MARKET.MKT_NAME;
      v_AUCTION_ROUND := v_MARKET.MKT_ROUND;

      SELECT XMLELEMENT("QueryFTRQuotes",
                       XMLATTRIBUTES(v_AUCTION_MARKET_NAME  AS
                                     "market",
                                     v_AUCTION_ROUND AS
                                     "round"),
                       XMLELEMENT("All"))
      INTO v_FTR_XML
      FROM DUAL;

      SELECT XMLCONCAT(v_REQUEST, v_FTR_XML)
      INTO v_REQUEST
      FROM DUAL;

    END LOOP;

    SELECT XMLELEMENT("QueryRequest",
                        XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                        v_REQUEST)
    INTO p_XML_REQUEST_BODY
    FROM DUAL;


    /*SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryFTRQuotes",
                                 XMLATTRIBUTES(p_AUCTION_MARKET_NAME AS
                                               "market",
                                               p_ANNUAL_AUCTION_ROUND AS
                                               "round"),
                                 CASE
                                   WHEN NOT p_PORTFOLIO_NAME IS NULL THEN
                                    XMLELEMENT("PortfolioName",
                                               p_PORTFOLIO_NAME)
                                   WHEN (p_SOURCE IS NULL OR p_SINK IS NULL) THEN
                                    XMLELEMENT("All")
                                   ELSE
                                    XMLELEMENT("Path",
                                               XMLATTRIBUTES(p_SOURCE AS
                                                             "source",
                                                             p_SINK AS "sink"))
                                 END))
      INTO p_XML_REQUEST_BODY
      FROM DUAL;

    p_CLOB := p_XML_REQUEST_BODY.getclobval();*/

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EFTR.GETX_QUERY_FTR_QUOTES: ' || UT.GET_FULL_ERRM;

  END GETX_QUERY_FTR_QUOTES;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE GETX_SUBMIT_QUOTES(p_RECORDS          IN MEX_PJM_FTR_QUOTES_TBL,
                               p_XML_REQUEST_BODY OUT XMLTYPE) AS

    -- Get XML for FTRQuote for the given Auction Market date

    v_XML XMLTYPE;

    CURSOR c_XML_REQUEST IS
      SELECT (XMLELEMENT("FTRQuotes",
                         XMLATTRIBUTES(P.AuctionMarketName AS "market",
                                       P.AuctionRound AS "round"),
                         XMLAGG(XMLELEMENT("FTRQuote",
                                           XMLATTRIBUTES(P.BuySell AS "trade"),
                                           XMLELEMENT("Path",
                                                      XMLATTRIBUTES(P.SourceName AS
                                                                    "source",
                                                                    P.SinkName AS
                                                                    "sink")),
                                           XMLELEMENT("Class", P.PeakClass),
                                           XMLELEMENT("Period", P.Period),
                                           XMLELEMENT("Hedge", P.HedgeType),
                                           XMLELEMENT("MW", P.Amount),
                                           XMLELEMENT("Price", P.Price))))) AS FTRQUOTES
        FROM TABLE(CAST(p_RECORDS AS MEX_PJM_FTR_QUOTES_TBL)) P
       GROUP BY P.AuctionMarketName, P.AuctionRound;

  BEGIN
    p_XML_REQUEST_BODY := NULL;

    FOR v_XML IN c_XML_REQUEST LOOP

      SELECT XMLCONCAT(p_XML_REQUEST_BODY, v_XML.FTRQUOTES)
        INTO p_XML_REQUEST_BODY
        FROM DUAL;

    END LOOP;

  END GETX_SUBMIT_QUOTES;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_MARKET_RESULTS(p_XML_RESPONSE IN XMLTYPE,
                                 p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_MARKET_RESULTS_TBL,
                                 p_STATUS       OUT NUMBER,
                                 p_MESSAGE      OUT VARCHAR2) AS

    CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(T), '//@market', g_FTR_NAMESPACE) "AUCTION_NAME",
             EXTRACTVALUE(VALUE(T), '//@round', g_FTR_NAMESPACE) "AUCTION_ROUND",
             EXTRACTVALUE(VALUE(U), '//@trade', g_FTR_NAMESPACE) "BUY_SELL",
             EXTRACTVALUE(VALUE(V), '//@source', g_FTR_NAMESPACE) "SOURCE_NAME",
             EXTRACTVALUE(VALUE(V), '//@sink', g_FTR_NAMESPACE) "SINK_NAME",
             EXTRACTVALUE(VALUE(U), '//Class', g_FTR_NAMESPACE) "PK_CLASS",
             EXTRACTVALUE(VALUE(U), '//Period', g_FTR_NAMESPACE) "PERIOD",
             EXTRACTVALUE(VALUE(U), '//Hedge', g_FTR_NAMESPACE) "OPT_OBL",
             EXTRACTVALUE(VALUE(U), '//BidMW', g_FTR_NAMESPACE) "BID_AMOUNT",
             EXTRACTVALUE(VALUE(U), '//ClearedMW', g_FTR_NAMESPACE) "CLEARED_AMOUNT",
             EXTRACTVALUE(VALUE(U), '//BidPrice', g_FTR_NAMESPACE) "BID_PRICE",
             EXTRACTVALUE(VALUE(U), '//ClearedPrice', g_FTR_NAMESPACE) "CLEARED_PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//MarketResults',
                                       g_FTR_NAMESPACE))) T,
             --FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT xml from xml_trace WHERE key1 = 'MarketResults'),'//QueryResponse/MarketResults', g_FTR_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//FTRCleared',
                                       g_FTR_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//Path', g_FTR_NAMESPACE))) V
       ORDER BY 1, 2, 3, 4, 5, 6, 8;

  BEGIN

    FOR v_XML IN c_XML LOOP

      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_MARKET_RESULTS(v_XML.AUCTION_NAME,
                                                              v_XML.AUCTION_ROUND,
                                                              v_XML.BUY_SELL,
                                                              v_XML.SOURCE_NAME,
                                                              v_XML.SINK_NAME,
                                                              v_XML.PK_CLASS,
                                                              v_XML.PERIOD,
                                                              v_XML.OPT_OBL,
                                                              v_XML.BID_AMOUNT,
                                                              v_XML.CLEARED_AMOUNT,
                                                              v_XML.BID_PRICE,
                                                              v_XML.CLEARED_PRICE);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN PARSE_MARKET_RESULTS' || UT.GET_FULL_ERRM;

  END PARSE_MARKET_RESULTS;

  ---------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_CLEARED_FTRS(p_XML_RESPONSE IN XMLTYPE,
                               p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_CLEARED_TBL,
                               p_STATUS       OUT NUMBER,
                               p_MESSAGE      OUT VARCHAR2) AS

    CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(T), '//@market', g_FTR_NAMESPACE) "MKT_NAME",
             EXTRACTVALUE(VALUE(T), '//@round', g_FTR_NAMESPACE) "AUCTION_ROUND",
             EXTRACTVALUE(VALUE(U), '//@trade', g_FTR_NAMESPACE) "BUY_SELL",
             EXTRACTVALUE(VALUE(U), '//Owner', g_FTR_NAMESPACE) "OWNER",
             EXTRACTVALUE(VALUE(U), '//Path/@source', g_FTR_NAMESPACE) "SOURCE_NAME",
             EXTRACTVALUE(VALUE(U), '//Path/@sink', g_FTR_NAMESPACE) "SINK_NAME",
             EXTRACTVALUE(VALUE(U), '//Class', g_FTR_NAMESPACE) "PK_CLASS",
             EXTRACTVALUE(VALUE(U), '//Period', g_FTR_NAMESPACE) "PERIOD",
             EXTRACTVALUE(VALUE(U), '//Hedge', g_FTR_NAMESPACE) "HEDGE_TYPE",
             EXTRACTVALUE(VALUE(U), '//ClearedMW', g_FTR_NAMESPACE) "CLEARED_MW",
             EXTRACTVALUE(VALUE(U), '//ClearedPrice', g_FTR_NAMESPACE) "CLEARED_PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//ClearedFTRs',
                                       g_FTR_NAMESPACE))) T,

             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//ClearedFTR',
                                       g_FTR_NAMESPACE))) U

       ORDER BY 1, 2, 3, 5, 6, 7, 9;

  BEGIN
  NULL;

 -- FOR v_XML IN c_XML LOOP
	--	INSERT INTO pjm_work_ftrs VALUES v_XML;
	--END LOOP;
	--COMMIT;

  /*
    INSERT INTO pjm_work_ftrs
      SELECT EXTRACTVALUE(VALUE(T), '//@market', g_FTR_NAMESPACE) "MKT_NAME",
             EXTRACTVALUE(VALUE(T), '//@round', g_FTR_NAMESPACE) "AUCTION_ROUND",
             EXTRACTVALUE(VALUE(U), '//@trade', g_FTR_NAMESPACE) "BUY_SELL",
             EXTRACTVALUE(VALUE(U), '//Owner', g_FTR_NAMESPACE) "OWNER",
             EXTRACTVALUE(VALUE(U), '//@source', g_FTR_NAMESPACE) "SOURCE_NAME",
             EXTRACTVALUE(VALUE(U), '//@sink', g_FTR_NAMESPACE) "SINK_NAME",
             EXTRACTVALUE(VALUE(U), '//Class', g_FTR_NAMESPACE) "PK_CLASS",
             EXTRACTVALUE(VALUE(U), '//Period', g_FTR_NAMESPACE) "PERIOD",
             EXTRACTVALUE(VALUE(U), '//Hedge', g_FTR_NAMESPACE) "HEDGE_TYPE",
             EXTRACTVALUE(VALUE(U), '//ClearedMW', g_FTR_NAMESPACE) "CLEARED_MW",
             EXTRACTVALUE(VALUE(U), '//ClearedPrice', g_FTR_NAMESPACE) "CLEARED_PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//ClearedFTRs',
                                       g_FTR_NAMESPACE))) T,

             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//ClearedFTR',
                                       g_FTR_NAMESPACE))) U,
              TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//Path', g_FTR_NAMESPACE))) V

       ORDER BY 1, 2, 3, 5, 6, 7, 9;
       COMMIT;/*
 /* --temp
  p_RECORDS := MEX_PJM_FTR_CLEARED_TBL();

    FOR v_XML IN c_XML LOOP

      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_CLEARED(v_XML.AUCTION_NAME,
                                                       v_XML.AUCTION_ROUND,
                                                       v_XML.BUY_SELL,
                                                       v_XML.OWNER,
                                                       v_XML.SOURCE_NAME,
                                                       v_XML.SINK_NAME,
                                                       v_XML.PK_CLASS,
                                                       v_XML.PERIOD,
                                                       v_XML.OPT_OBL,
                                                       v_XML.CLEARED_AMOUNT,
                                                       v_XML.CLEARED_PRICE);

    END LOOP;*/

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN PARSE_CLEARED_FTRS' || UT.GET_FULL_ERRM;

  END PARSE_CLEARED_FTRS;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_FTR_QUOTES(p_XML_RESPONSE IN XMLTYPE,
                             p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_QUOTES_TBL,
                             p_STATUS       OUT NUMBER,
                             p_MESSAGE      OUT VARCHAR2) AS

    v_AUCTION_BEGIN_DATE DATE;
    v_AUCTION_END_DATE   DATE;
    v_IS_ANNUAL          BOOLEAN;

    CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(T), '//@market', g_FTR_NAMESPACE) "AUCTION_NAME",
             EXTRACTVALUE(VALUE(T), '//@round', g_FTR_NAMESPACE) "AUCTION_ROUND",
             EXTRACTVALUE(VALUE(U), '//@trade', g_FTR_NAMESPACE) "BUY_SELL",
             EXTRACTVALUE(VALUE(V), '//@source', g_FTR_NAMESPACE) "SOURCE_NAME",
             EXTRACTVALUE(VALUE(V), '//@sink', g_FTR_NAMESPACE) "SINK_NAME",
             EXTRACTVALUE(VALUE(U), '//Class', g_FTR_NAMESPACE) "PK_CLASS",
             EXTRACTVALUE(VALUE(U), '//Period', g_FTR_NAMESPACE) "PERIOD",
             EXTRACTVALUE(VALUE(U), '//Hedge', g_FTR_NAMESPACE) "OPT_OBL",
             EXTRACTVALUE(VALUE(U), '//MW', g_FTR_NAMESPACE) "AMOUNT",
             EXTRACTVALUE(VALUE(U), '//Price', g_FTR_NAMESPACE) "PRICE"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//FTRQuotes',
                                       g_FTR_NAMESPACE))) T,
             --FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT xml from xml_trace WHERE key1 = 'MarketResults'),'//QueryResponse/MarketResults', g_FTR_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//FTRQuote',
                                       g_FTR_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//Path', g_FTR_NAMESPACE))) V
       ORDER BY 1, 2, 3, 4, 5, 6, 8;

  BEGIN

    FOR v_XML IN c_XML LOOP

      GET_AUCTION_MARKET_DATES(v_XML.AUCTION_NAME,
                               v_AUCTION_BEGIN_DATE,
                               v_AUCTION_END_DATE,
                               v_IS_ANNUAL,
                               p_STATUS,
                               p_MESSAGE);

      --FIX
      --CHANGE SO THAT YOU GET ONE DATE BACK AND WHEN IS_ANNUAL IS TRUE
      --THEN THE DATE IS NULL ELSE THE BEGINNING OF THE YEAR - COULD CHANGE
      --THE GET_AUCTION_MARKET_DATES PROC.

      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_QUOTES(v_XML.AUCTION_NAME,
                                                      v_AUCTION_BEGIN_DATE,
                                                      v_XML.AUCTION_ROUND,
                                                      v_XML.BUY_SELL,
                                                      v_XML.SOURCE_NAME,
                                                      v_XML.SINK_NAME,
                                                      v_XML.PK_CLASS,
                                                      v_XML.PERIOD,
                                                      v_XML.OPT_OBL,
                                                      v_XML.AMOUNT,
                                                      v_XML.PRICE);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN PARSE_FTR_QUOTES ' || UT.GET_FULL_ERRM;

  END PARSE_FTR_QUOTES;
  ---------------------------------------------------------------------------------------------------

  PROCEDURE PARSE_INITIAL_ARR(p_XML_RESPONSE IN XMLTYPE,
                              p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_INITIAL_ARR_TBL,
                              p_STATUS       OUT NUMBER,
                              p_MESSAGE      OUT VARCHAR2) AS

    CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(T), '//@market', g_FTR_NAMESPACE) "AUCTION_NAME",
             EXTRACTVALUE(VALUE(V), '//@source', g_FTR_NAMESPACE) "SOURCE_NAME",
             EXTRACTVALUE(VALUE(V), '//@sink', g_FTR_NAMESPACE) "SINK_NAME",
             EXTRACTVALUE(VALUE(U), '//BidMW', g_FTR_NAMESPACE) "BID_AMOUNT",
             EXTRACTVALUE(VALUE(U), '//ClearedMW', g_FTR_NAMESPACE) "CLEARED_AMOUNT"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//InitialARRs',
                                       g_FTR_NAMESPACE))) T,
             --FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT xml from xml_trace WHERE key1 = 'MarketResults'),'//QueryResponse/MarketResults', g_FTR_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//InitialARR',
                                       g_FTR_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//Path', g_FTR_NAMESPACE))) V
       ORDER BY 1, 2, 3, 4, 5;

  BEGIN

    FOR v_XML IN c_XML LOOP

      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_INITIAL_ARR(NULL,
                                                           v_XML.SOURCE_NAME,
                                                           v_XML.SINK_NAME,
                                                           v_XML.BID_AMOUNT,
                                                           v_XML.CLEARED_AMOUNT);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN PARSE_INITIAL_ARR ' || UT.GET_FULL_ERRM;

  END PARSE_INITIAL_ARR;

  ---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ARR_RESULTS(p_XML_RESPONSE IN XMLTYPE,
                              p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_INITIAL_ARR_TBL,
                              p_STATUS       OUT NUMBER,
                              p_MESSAGE      OUT VARCHAR2) AS

 g_ARR_NAMESPACE Varchar2(64) := 'xmlns="http://eftr.pjm.com/arr/xml"';

    CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(U), '//SinkName', g_ARR_NAMESPACE) "SOURCE_NAME",
             EXTRACTVALUE(VALUE(U), '//SourceName', g_ARR_NAMESPACE) "SINK_NAME",
             EXTRACTVALUE(VALUE(U), '//BidMW', g_ARR_NAMESPACE) "BID_AMOUNT",
             EXTRACTVALUE(VALUE(U), '//ClearedMW', g_ARR_NAMESPACE) "CLEARED_AMOUNT"
     FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//ARRResults',
                                       g_ARR_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//ARRResult',
                                       g_ARR_NAMESPACE))) U;


  BEGIN

    FOR v_XML IN c_XML LOOP

      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_INITIAL_ARR(NULL,
                                                           v_XML.SOURCE_NAME,
                                                           v_XML.SINK_NAME,
                                                           v_XML.BID_AMOUNT,
                                                           v_XML.CLEARED_AMOUNT);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN PARSE_ARR_RESULTS ' || UT.GET_FULL_ERRM;

  END PARSE_ARR_RESULTS;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_PORTFOLIOS(p_XML_RESPONSE IN XMLTYPE,
                             p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_PORTFOLIOS_TBL,
                             p_STATUS       OUT NUMBER,
                             p_MESSAGE      OUT VARCHAR2) AS

    CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(U), '//@name', g_FTR_NAMESPACE) "PORTFOLIO_NAME",
             EXTRACTVALUE(VALUE(V), '//@source', g_FTR_NAMESPACE) "SOURCE_NAME",
             EXTRACTVALUE(VALUE(V), '//@sink', g_FTR_NAMESPACE) "SINK_NAME"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//Portfolios',
                                       g_FTR_NAMESPACE))) T,
             --FROM TABLE(XMLSEQUENCE(EXTRACT((SELECT xml from xml_trace WHERE key1 = 'MarketResults'),'//QueryResponse/MarketResults', g_FTR_NAMESPACE))) T,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
                                       '//Portfolio',
                                       g_FTR_NAMESPACE))) U,
             TABLE(XMLSEQUENCE(EXTRACT(VALUE(U), '//Path', g_FTR_NAMESPACE))) V
       ORDER BY 1, 2, 3;

  BEGIN

    FOR v_XML IN c_XML LOOP

      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_PORTFOLIOS(v_XML.PORTFOLIO_NAME,
                                                          v_XML.SOURCE_NAME,
                                                          v_XML.SINK_NAME);

    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN PARSE_PORTFOLIOS ' || UT.GET_FULL_ERRM;

  END PARSE_PORTFOLIOS;
  ---------------------------------------------------------------------------------------------------

  PROCEDURE QUERY_MARKET_RESULTS(p_CRED          IN mex_credentials,
  								 p_LOG_ONLY      IN BINARY_INTEGER,
                                 p_RECORDS       OUT MEX_PJM_FTR_MARKET_RESULTS_TBL,
                                 p_STATUS        OUT NUMBER,
                                 p_MESSAGE       OUT VARCHAR2,
								 p_LOGGER		   IN OUT mm_logger_adapter) AS



    v_XML_REQUEST            XMLTYPE;
    v_XML_RESPONSE           XMLTYPE;


  BEGIN

    p_RECORDS := MEX_PJM_FTR_MARKET_RESULTS_TBL();

    p_STATUS := MEX_UTIL.g_SUCCESS;

      ---BUILD XML REQUEST FOR AUCTION
      MEX_PJM_EFTR.GETX_QUERY_MARKET_RESULTS(v_XML_REQUEST,
                                             p_STATUS,
                                             p_MESSAGE);

      --p_PARAMETER_MAP('BeginDate') := p_BEGIN_DATE;
      --p_PARAMETER_MAP('EndDate') := p_END_DATE;

      IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      	RUN_PJM_QUERY(P_CRED, P_LOG_ONLY, V_XML_REQUEST, V_XML_RESPONSE, P_STATUS, P_MESSAGE, P_LOGGER);

        --CALL PARSE MARKET RESULTS
        PARSE_MARKET_RESULTS(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);

      END IF;

  EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_MARKET_RESULTS: ' || UT.GET_FULL_ERRM;

  END QUERY_MARKET_RESULTS;

  --------------------------------------------------------------------------------------------------
   PROCEDURE QUERY_CLEARED_FTRS(p_CRED			 IN	 mex_credentials,
							    p_LOG_ONLY		 IN  BINARY_INTEGER,
                          		p_RECORDS        OUT MEX_PJM_FTR_CLEARED_TBL,
                                p_STATUS         OUT NUMBER,
                                p_MESSAGE        OUT VARCHAR2,
								p_LOGGER		   IN OUT mm_logger_adapter) AS


    v_XML_REQUEST            XMLTYPE;
    v_XML_RESPONSE           XMLTYPE;
    v_AUCTION_MARKET_NAME VARCHAR2(64);
    v_AUCTION_ROUND VARCHAR2(2);

    --Note: originally sent one xml request for all the markets
    -- but received "java.lang.OutOfMemoryError" for the response
    -- so changed it to one request per market
    CURSOR c_MARKETS IS
    SELECT MKT_NAME, MKT_ROUND
    FROM PJM_EFTR_MARKET_INFO
    WHERE IS_ACTIVE = 1;

  BEGIN

    p_RECORDS := MEX_PJM_FTR_CLEARED_TBL();
    p_STATUS := MEX_UTIL.g_SUCCESS;

     FOR v_MARKET IN c_MARKETS LOOP
      v_AUCTION_MARKET_NAME := v_MARKET.MKT_NAME;
      v_AUCTION_ROUND := v_MARKET.MKT_ROUND;

      ---BUILD XML REQUEST FOR AUCTION
      MEX_PJM_EFTR.GETX_QUERY_CLEARED_FTRS(v_AUCTION_MARKET_NAME,
                                           v_AUCTION_ROUND,
                                           v_XML_REQUEST,
                                           p_STATUS,
                                           p_MESSAGE);
      IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_STATUS, p_MESSAGE, p_LOGGER);


          --PARSE_CLEARED_FTRS(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);

      END IF;

    END LOOP;


  EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_CLEARED_FTRS: ' || UT.GET_FULL_ERRM;

  END QUERY_CLEARED_FTRS;
   --------------------------------------------------------------------------------------------------

  PROCEDURE QUERY_INITIAL_ARR(p_CRED			 IN	 mex_credentials,
  							  p_LOG_ONLY		 IN  BINARY_INTEGER,
                              p_RECORDS          OUT MEX_PJM_FTR_INITIAL_ARR_TBL,
                              p_STATUS           OUT NUMBER,
                              p_MESSAGE          OUT VARCHAR2,
							  p_LOGGER		   IN OUT mm_logger_adapter) AS


    v_XML_REQUEST            XMLTYPE;
    v_XML_RESPONSE           XMLTYPE;

  BEGIN

    p_RECORDS := MEX_PJM_FTR_INITIAL_ARR_TBL();
    p_STATUS := MEX_UTIL.g_SUCCESS;

    ---BUILD XML REQUEST FOR AUCTION
    MEX_PJM_EFTR.GETX_QUERY_INITIAL_ARR(v_XML_REQUEST,
                                        p_STATUS,
                                        p_MESSAGE);



    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_STATUS, p_MESSAGE, p_LOGGER);
      PARSE_INITIAL_ARR(v_XML_RESPONSE, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;

  EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_INITIAL_ARR: ' || UT.GET_FULL_ERRM;

  END QUERY_INITIAL_ARR;
  ---------------------------------------------------------------------------------------------------


PROCEDURE QUERY_FTR_QUOTES(p_CRED			 IN	 mex_credentials,
						   p_LOG_ONLY		 IN  BINARY_INTEGER,
                           p_RECORDS       OUT MEX_PJM_FTR_QUOTES_TBL,
                           p_STATUS        OUT NUMBER,
                           p_MESSAGE       OUT VARCHAR2,
						   p_LOGGER		   IN OUT mm_logger_adapter) AS

    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;


  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
    p_RECORDS := MEX_PJM_FTR_QUOTES_TBL();

    ---BUILD XML REQUEST
    GETX_QUERY_FTR_QUOTES(v_XML_REQUEST, p_STATUS, p_MESSAGE);


    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      /*RUN_PJM_QUERY('QueryFTRQuotes',
                    p_LOG_ONLY,
                    v_XML_REQUEST,
                    v_XML_RESPONSE,
                    p_MESSAGE); */


      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_STATUS, p_MESSAGE, p_LOGGER);

      PARSE_FTR_QUOTES(v_XML_RESPONSE,
                     p_RECORDS,
                     p_STATUS,
                     p_MESSAGE);

    END IF;


  EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_FTR_QUOTES: ' || UT.GET_FULL_ERRM;
END QUERY_FTR_QUOTES;

-------------------------------------------------------------------------------------
  PROCEDURE GETX_QUERY_MESSAGES(p_DATE             IN DATE,
                                p_XML_REQUEST_BODY OUT XMLTYPE,
                                p_STATUS           OUT NUMBER,
                                p_MESSAGE          OUT VARCHAR2) AS
  BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryMessages",
                                 XMLELEMENT("EffectiveDate",
                                            TO_CHAR(p_DATE, 'YYYY-MM-DD'))))
      INTO p_XML_REQUEST_BODY
      FROM DUAL;

  EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in MEX_PJM_EFTR.GETX_QUERY_MARKET_MESSAGES: ' || UT.GET_FULL_ERRM;
  END GETX_QUERY_MESSAGES;
-------------------------------------------------------------------------------------

  PROCEDURE PARSE_MESSAGES(p_DATE         IN DATE,
                           p_XML_RESPONSE IN XMLTYPE,
                           p_RECORDS      IN OUT NOCOPY MEX_PJM_FTR_MESSAGE_TBL,
                           p_STATUS       OUT NUMBER,
                           p_MESSAGE      OUT VARCHAR2) AS
    CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(T),'//Message/@effectiveDate',
                          g_FTR_NAMESPACE) EFFECTIVE_DATE,
             EXTRACTVALUE(VALUE(T), '//Message/@terminationDate',
                          g_FTR_NAMESPACE) TERMINATION_DATE,
             EXTRACTVALUE(VALUE(T), '//Message',
                          g_FTR_NAMESPACE) MESSAGE_TEXT
      FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                     '//Messages/Message',
                                      g_FTR_NAMESPACE))) T;

  BEGIN
    FOR v_XML IN c_XML LOOP
      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_FTR_MESSAGE(p_DATE,
                                                       v_XML.MESSAGE_TEXT,
                                                       TO_DATE(v_XML.EFFECTIVE_DATE,
                                                               'YYYY-MM-DD'),
                                                       TO_DATE(v_XML.TERMINATION_DATE,
                                                               'YYYY-MM-DD'));
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EFTR.PARSE_MESSAGES: ' || UT.GET_FULL_ERRM;

  END PARSE_MESSAGES;

-------------------------------------------------------------------------------------

PROCEDURE QUERY_MARKET_MESSAGES(p_CRED			 IN	 mex_credentials,
							    p_LOG_ONLY		 IN  BINARY_INTEGER,
								p_EFFECTIVE_DATE IN DATE,
                          		p_RECORDS    OUT MEX_PJM_FTR_MESSAGE_TBL,
                                p_STATUS     OUT NUMBER,
                                p_MESSAGE    OUT VARCHAR2,
								p_LOGGER		   IN OUT mm_logger_adapter) AS


    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;

  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_PJM_FTR_MESSAGE_TBL();

    ---BUILD XML REQUEST
    GETX_QUERY_MESSAGES(p_EFFECTIVE_DATE, v_XML_REQUEST, p_STATUS, p_MESSAGE);

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_STATUS, p_MESSAGE, p_LOGGER);
    END IF;

    PARSE_MESSAGES(p_EFFECTIVE_DATE,
                   v_XML_RESPONSE,
                   p_RECORDS,
                   p_STATUS,
                   p_MESSAGE);


  EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_MARKET_MESSAGES: ' || UT.GET_FULL_ERRM;
  END QUERY_MARKET_MESSAGES;
 -------------------------------------------------------------------------------------

PROCEDURE GETX_QUERY_MARKET_INFO(p_XML_REQUEST_BODY OUT XMLTYPE,
                                 p_STATUS           OUT NUMBER,
                                 p_MESSAGE          OUT VARCHAR2) AS
  BEGIN
  	p_STATUS := MEX_UTIL.g_SUCCESS;

    SELECT XMLELEMENT("QueryRequest",
                      XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                      XMLELEMENT("QueryMarketInfo"))
      INTO p_XML_REQUEST_BODY
      FROM DUAL;
  EXCEPTION
		WHEN OTHERS THEN
			p_STATUS  := SQLCODE;
			p_MESSAGE := 'Error in MEX_PJM_EFTR.GETX_QUERY_MARKET_INFO: ' || UT.GET_FULL_ERRM;
END GETX_QUERY_MARKET_INFO;
-------------------------------------------------------------------------------------

PROCEDURE PARSE_MARKET_INFO(p_XML_RESPONSE IN XMLTYPE,
                            p_STATUS       OUT NUMBER,
                            p_MESSAGE      OUT VARCHAR2) AS

  v_PJM_MKT_INFO PJM_EFTR_MARKET_INFO%ROWTYPE;
  v_STATUS VARCHAR2(16);


  CURSOR c_MARKET_INFO IS
	  SELECT EXTRACTVALUE(VALUE(T), '//MarketName', g_PJM_EFTR_NAMESPACE) MKT_NAME,
					 EXTRACTVALUE(VALUE(T), '//MarketType', g_PJM_EFTR_NAMESPACE) MKT_TYPE,
           EXTRACTVALUE(VALUE(T), '//MarketRound', g_PJM_EFTR_NAMESPACE) MKT_ROUND,
           EXTRACTVALUE(VALUE(T), '//MarketPeriod', g_PJM_EFTR_NAMESPACE) MKT_PERIOD,
	 TO_DATE(EXTRACTVALUE(VALUE(T), '//MarketInterval/@start', g_PJM_EFTR_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) MKT_INT_START,
	 TO_DATE(EXTRACTVALUE(VALUE(T), '//MarketInterval/@end', g_PJM_EFTR_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) MKT_INT_END,
   TO_DATE(EXTRACTVALUE(VALUE(T), '//BiddingInterval/@start', g_PJM_EFTR_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) BID_INT_START,
   TO_DATE(EXTRACTVALUE(VALUE(T), '//BiddingInterval/@end', g_PJM_EFTR_NAMESPACE), g_DATE_TIME_ZONE_FORMAT) BID_INT_END,
           EXTRACTVALUE(VALUE(T), '//MarketStatus', g_PJM_EFTR_NAMESPACE) MKT_STATUS

				FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,'//MarketInfo/Market',g_PJM_EFTR_NAMESPACE))) T;

  BEGIN
    FOR v_XML IN c_MARKET_INFO LOOP
      v_PJM_MKT_INFO.MKT_NAME := v_XML.MKT_NAME;
      v_PJM_MKT_INFO.MKT_TYPE := v_XML.MKT_TYPE;
      v_PJM_MKT_INFO.MKT_ROUND := v_XML.MKT_ROUND;
      v_PJM_MKT_INFO.MKT_PERIOD := v_XML.MKT_PERIOD;
      v_PJM_MKT_INFO.MKT_INT_START := v_XML.MKT_INT_START;
      v_PJM_MKT_INFO.MKT_INT_END := v_XML.MKT_INT_END;
      v_PJM_MKT_INFO.BID_INT_START := v_XML.BID_INT_START;
      v_PJM_MKT_INFO.BID_INT_END := v_XML.BID_INT_END;
      v_PJM_MKT_INFO.MKT_STATUS := v_XML.MKT_STATUS;
      IF (v_XML.MKT_INT_END < TRUNC(SYSDATE, 'MM') - NUMTOYMINTERVAL(2, 'MONTH')) THEN
     	v_PJM_MKT_INFO.IS_ACTIVE := 0; --if mkt_int_end is more than 2 months ago, set as inactive
      ELSE
      	v_PJM_MKT_INFO.IS_ACTIVE := 1; -- set to true
      END IF;

      BEGIN
      	SELECT MKT_STATUS INTO v_STATUS
      	FROM PJM_EFTR_MARKET_INFO
      	WHERE MKT_NAME = v_PJM_MKT_INFO.MKT_NAME
      	AND MKT_ROUND = v_XML.MKT_ROUND
        AND MKT_PERIOD = v_XML.MKT_PERIOD;
      EXCEPTION
      	WHEN NO_DATA_FOUND THEN
      		INSERT INTO PJM_EFTR_MARKET_INFO VALUES v_PJM_MKT_INFO;
	      	COMMIT;
	END;


    END LOOP;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EFTR.PARSE_MARKET_INFO: ' || UT.GET_FULL_ERRM;

END PARSE_MARKET_INFO;

-------------------------------------------------------------------------------------
PROCEDURE QUERY_MARKET_INFO(p_CRED			 IN	 mex_credentials,
							p_LOG_ONLY		 IN  BINARY_INTEGER,
                            p_STATUS     OUT NUMBER,
                            p_MESSAGE    OUT VARCHAR2,
							p_LOGGER	 IN OUT mm_logger_adapter) AS


    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    ---BUILD XML REQUEST
    GETX_QUERY_MARKET_INFO(v_XML_REQUEST,
                           p_STATUS,
                           p_MESSAGE);


    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_STATUS, p_MESSAGE, p_LOGGER);
    END IF;

    PARSE_MARKET_INFO(v_XML_RESPONSE,
                      p_STATUS,
                      p_MESSAGE);


  EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_MARKET_INFO: ' || UT.GET_FULL_ERRM;
  END QUERY_MARKET_INFO;

  -------------------------------------------------------------------------------------
PROCEDURE GETX_QUERY_FTR_NODES(p_MARKET_NAMES     IN PARSE_UTIL.STRING_TABLE,
                               p_XML_REQUEST_BODY OUT XMLTYPE,
                               p_STATUS           OUT NUMBER,
                               p_MESSAGE          OUT VARCHAR2) AS



    v_MKT_NAME     VARCHAR2(64);
    v_REQUEST       XMLTYPE;
    v_INDEX         BINARY_INTEGER;
    v_FTR_XML XMLTYPE;


  BEGIN

    p_STATUS := g_SUCCESS;
    v_INDEX   := p_MARKET_NAMES.FIRST;

    WHILE p_MARKET_NAMES.EXISTS(v_INDEX) LOOP

      v_MKT_NAME := p_MARKET_NAMES(v_INDEX);

        SELECT XMLELEMENT("QueryFTRNodes",
                          XMLATTRIBUTES(v_MKT_NAME AS "market"))
          INTO v_FTR_XML
          FROM DUAL;

        SELECT XMLCONCAT(v_REQUEST, v_FTR_XML)
          INTO v_REQUEST
          FROM DUAL;

      v_INDEX := p_MARKET_NAMES.NEXT(v_INDEX);


    END LOOP;

    SELECT XMLELEMENT("QueryRequest",
                        XMLATTRIBUTES(g_FTR_NAMESPACE_NAME AS "xmlns"),
                        v_REQUEST)
    INTO p_XML_REQUEST_BODY
    FROM DUAL;


  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EFTR.GETX_QUERY_FTR_NODES: ' || UT.GET_FULL_ERRM;

  END GETX_QUERY_FTR_NODES;
  ---------------------------------------------------------------------------------------------------

  PROCEDURE PARSE_FTR_NODES(p_XML_RESPONSE IN XMLTYPE,
                            p_STATUS       OUT NUMBER,
                            p_MESSAGE      OUT VARCHAR2) AS

  v_PJM_NODES PJM_EFTR_NODES%ROWTYPE;

  CURSOR c_NODES IS
	  SELECT EXTRACTVALUE(VALUE(T), '//FTRNodes/@market', g_PJM_EFTR_NAMESPACE) MKT_NAME,
					 EXTRACTVALUE(VALUE(U), '//Node', g_PJM_EFTR_NAMESPACE) NODE_NAME
		FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
																	 '//FTRNodes',
																	 g_PJM_EFTR_NAMESPACE))) T,
         TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
																	 '//Node',
																	 g_PJM_EFTR_NAMESPACE))) U;

    /*CURSOR c_XML IS
      SELECT EXTRACTVALUE(VALUE(NODES), '//Node', g_FTR_NAMESPACE) "EXTERNAL_ID"
        FROM TABLE(XMLSEQUENCE(EXTRACT(p_XML_RESPONSE,
                                       '//FTRNodes',
                                       g_FTR_NAMESPACE))) NODES;*/

  BEGIN
    FOR v_XML IN c_NODES LOOP
      v_PJM_NODES.MKT_NAME := v_XML.MKT_NAME;
      v_PJM_NODES.NODE_NAME := v_XML.NODE_NAME;

      INSERT INTO PJM_EFTR_NODES VALUES v_PJM_NODES;


    END LOOP;
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_EFTR.PARSE_FTR_NODES: ' || UT.GET_FULL_ERRM;

  END PARSE_FTR_NODES;

-------------------------------------------------------------------------------------

PROCEDURE QUERY_FTR_NODES(p_CRED			 IN	 mex_credentials,
					      p_LOG_ONLY		 IN  BINARY_INTEGER,
                          p_STATUS     OUT NUMBER,
                          p_MESSAGE    OUT VARCHAR2,
						  p_LOGGER		   IN OUT mm_logger_adapter) AS


    v_XML_REQUEST  XMLTYPE;
    v_XML_RESPONSE XMLTYPE;
    v_MARKET_NAMES PARSE_UTIL.STRING_TABLE;
    v_INDEX           BINARY_INTEGER;

    CURSOR c_MARKETS IS
    SELECT MKT_NAME
    FROM PJM_EFTR_MARKET_INFO
    WHERE IS_ACTIVE = 1;

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
    v_INDEX := 1;

    --get all active markets
    FOR v_MARKET IN c_MARKETS LOOP
      v_MARKET_NAMES(v_INDEX) := v_MARKET.MKT_NAME;
      v_INDEX := v_INDEX + 1;
    END LOOP;

    ---BUILD XML REQUEST
    GETX_QUERY_FTR_NODES(v_MARKET_NAMES, v_XML_REQUEST, p_STATUS, p_MESSAGE);


    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
      RUN_PJM_QUERY(p_CRED, p_LOG_ONLY, v_XML_REQUEST, v_XML_RESPONSE, p_STATUS, p_MESSAGE, p_LOGGER);
    END IF;

    PARSE_FTR_NODES(v_XML_RESPONSE,
                    p_STATUS,
                    p_MESSAGE);


  EXCEPTION
		WHEN OTHERS THEN
			P_STATUS  := SQLCODE;
			P_MESSAGE := 'Error in MEX_PJM_EFTR.QUERY_FTR_NODES: ' || UT.GET_FULL_ERRM;
END QUERY_FTR_NODES;

-------------------------------------------------------------------------------------

PROCEDURE SUBMIT_FTR_QUOTES
	(
	p_CRED IN MEX_CREDENTIALS,
	p_RECORDS IN MEX_PJM_FTR_QUOTES_TBL,
	p_LOG_ONLY IN NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT MM_LOGGER_ADAPTER
	) AS

    v_XML_REQUEST  XMLTYPE;
	v_XML_RESPONSE XMLTYPE;
BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;

    --GENERATE THE XML SUBMIT REQUEST
    GETX_SUBMIT_QUOTES(p_RECORDS, v_XML_REQUEST);

    -- SEND THE XML SUBMIT REQUEST
	MEX_PJM.RUN_PJM_ACTION(p_CRED, 'submit', p_LOG_ONLY, v_XML_REQUEST, g_PJM_EFTR_NAMESPACE,
		g_PJM_EFTR_MKT, v_XML_RESPONSE, p_STATUS, p_MESSAGE, p_LOGGER);

END SUBMIT_FTR_QUOTES;
-------------------------------------------------------------------------------------
END MEX_PJM_EFTR;
/