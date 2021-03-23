CREATE OR REPLACE PACKAGE BODY MM_PJM_EFTR IS

  g_PACKAGE_NAME CONSTANT VARCHAR2(14) := 'MM_PJM_EFTR';

  g_PJM_CONTRACT_NAME CONSTANT VARCHAR2(64) := 'PJM Contract';
  g_INIT_VAL_VARCHAR  CONSTANT VARCHAR2(16) := '<#*~INITVAL>';

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
  ---------------------------------------------------------------------------------------------------
  --COMMON SC UTILS
  ----------------------------------------------------------------------------------------------------
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
  ---------------------------------------------------------------------------------------------------
  FUNCTION ID_FOR_STATEMENT_TYPE(p_STATEMENT_TYPE_NAME IN VARCHAR2)
    RETURN NUMBER IS
    v_TYPE_ID NUMBER(9);
  BEGIN
    SELECT STATEMENT_TYPE_ID
      INTO v_TYPE_ID
      FROM STATEMENT_TYPE
     WHERE STATEMENT_TYPE_NAME = p_STATEMENT_TYPE_NAME;

    RETURN v_TYPE_ID;

    --RAISE AN EXCEPTION IF IT DOESN'T EXIST.
  END ID_FOR_STATEMENT_TYPE;
  -------------------------------------------------------------------------------------
  FUNCTION ID_FOR_PJM_CONTRACT
	(
	p_ISO_SOURCE IN VARCHAR2
	) RETURN NUMBER AS
v_ID NUMBER;
BEGIN
	SELECT CONTRACT_ID
	INTO v_ID
	FROM INTERCHANGE_CONTRACT A
	WHERE A.CONTRACT_ALIAS = p_ISO_SOURCE
		AND ROWNUM = 1;

	RETURN v_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ID.ID_FOR_INTERCHANGE_CONTRACT(g_PJM_CONTRACT_NAME, v_ID);
		RETURN v_ID;
END ID_FOR_PJM_CONTRACT;
 -------------------------------------------------------------------------------------
FUNCTION ID_FOR_SERVICE_POINT_NAME
	(
	p_SERVICE_POINT_NAME IN VARCHAR2
	) RETURN NUMBER IS

	v_SERVICE_POINT_ID NUMBER(9);
	v_PEP_ROW PJM_EMKT_PNODES%ROWTYPE;
	v_NODENAME PJM_EMKT_PNODES.NODENAME%TYPE;
	v_IS_ZONE NUMBER(1) := 0;
BEGIN

	v_NODENAME := p_SERVICE_POINT_NAME;

	--Strip off the (PJM) at the end if there happens to be one there.
	IF SUBSTR(p_SERVICE_POINT_NAME, -5) = '(PJM)' THEN
		v_NODENAME := TRIM(SUBSTR(v_NODENAME, 1, LENGTH(v_NODENAME)-5));
	END IF;

	--Strip off the _ZONE at the end if there happens to be one there.
	IF SUBSTR(p_SERVICE_POINT_NAME, -5) = '_ZONE' THEN
		v_NODENAME := TRIM(SUBSTR(v_NODENAME, 1, LENGTH(v_NODENAME)-5));
		v_IS_ZONE := 1;
	END IF;

	--See if there is a different NODENAME for this node.
	v_NODENAME := NVL(GET_DICTIONARY_VALUE(v_NODENAME, 1, 'MarketExchange', 'PJM', 'Corrected NodeName'), v_NODENAME);

	SELECT P.SERVICE_POINT_ID
	INTO v_SERVICE_POINT_ID
	FROM SERVICE_POINT P, PJM_EMKT_PNODES PEP
    WHERE REPLACE(PEP.NODENAME, ' ', '') = REPLACE(v_NODENAME,' ', '')
    	AND P.EXTERNAL_IDENTIFIER = TO_CHAR(PEP.PNODEID)
		AND (v_IS_ZONE = 0 OR PEP.NODETYPE = 'Zone');

	RETURN v_SERVICE_POINT_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		BEGIN
			SELECT PEP.*
			INTO v_PEP_ROW
			FROM PJM_EMKT_PNODES PEP
			--
            WHERE PEP.NODENAME LIKE v_NODENAME;

			v_SERVICE_POINT_ID := MM_PJM_UTIL.CREATE_SERVICE_POINT(v_PEP_ROW.NODENAME, v_PEP_ROW.PNODEID, v_PEP_ROW.NODETYPE);
			RETURN v_SERVICE_POINT_ID;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
         -- can't find anything like this in the system; we're out of sync with PJM
				LOGS.LOG_WARN('NodeName ' || v_NODENAME || ' not found. Run the Query Node List action to update the node list.');
				RETURN NULL;
		END;

END ID_FOR_SERVICE_POINT_NAME;
----------------------------------------------------------------------------------------------------

  FUNCTION IS_ON_PEAK_DAY (p_LOCAL_DATE IN DATE, p_EDC_ID NUMBER := 0) RETURN BOOLEAN DETERMINISTIC AS

    -- Answer DATE of FTR Auction Market based on given name.

    v_IS_ONPEAK BOOLEAN;
	v_NERC_SET_ID NUMBER(9);
  BEGIN

  BEGIN
		SELECT HOLIDAY_SET_ID INTO v_NERC_SET_ID
		FROM HOLIDAY_SET WHERE HOLIDAY_SET_NAME = 'NERC';
		EXCEPTION
			WHEN OTHERS THEN
				v_NERC_SET_ID := 0;
	END;

    v_IS_ONPEAK := FALSE;
    IF SUBSTR(TO_CHAR(p_LOCAL_DATE, 'DY'), 1,1) <> 'S' THEN
      --NOT SAT OR SUN
      IF IS_HOLIDAY_FOR_SET(TRUNC(p_LOCAL_DATE, 'DD'), v_NERC_SET_ID) = 0 THEN
        v_IS_ONPEAK := TRUE;
      END IF;
    END IF;

    RETURN v_IS_ONPEAK;

  END IS_ON_PEAK_DAY;
  ---------------------------------------------------------------------------------------------------
  FUNCTION IS_ON_PEAK_HOUR(p_LOCAL_DATE IN DATE, p_EDC_ID NUMBER := 0)
    RETURN BOOLEAN DETERMINISTIC AS

    -- Answer DATE of FTR Auction Market based on given name.

    v_IS_ONPEAK BOOLEAN;
    V_HOUR      NUMBER(2);

  BEGIN
    v_IS_ONPEAK := FALSE;
    IF IS_ON_PEAK_DAY(p_LOCAL_DATE, p_EDC_ID) THEN
      V_HOUR := TO_CHAR(p_LOCAL_DATE, 'HH24');
      IF V_HOUR BETWEEN MEX_PJM_EFTR.g_FTR_ON_PEAK_BEGIN AND
         MEX_PJM_EFTR.g_FTR_ON_PEAK_END THEN
        v_IS_ONPEAK := TRUE;
      END IF;
    END IF;

    RETURN v_IS_ONPEAK;

  END IS_ON_PEAK_HOUR;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE UPDATE_BID_OFFER_STATUS(p_TRANSACTION_ID IN NUMBER,
                                    p_BEGIN_DATE     IN DATE,
                                    p_END_DATE       IN DATE,
                                    p_TIME_ZONE      IN VARCHAR2,
                                    p_SUBMIT_STATUS  IN VARCHAR2,
                                    p_MARKET_STATUS  IN VARCHAR2) AS

    v_BEGIN_DATE DATE;
    v_END_DATE   DATE;
  BEGIN

    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,
                      p_BEGIN_DATE,
                      p_END_DATE,
                      p_TIME_ZONE,
                      v_BEGIN_DATE,
                      v_END_DATE);

    UPDATE IT_TRAIT_SCHEDULE_STATUS
       SET SUBMIT_STATUS      = p_SUBMIT_STATUS,
           SUBMIT_DATE        = SYSDATE,
           SUBMITTED_BY_ID       = SECURITY_CONTROLS.CURRENT_USER_ID,
           MARKET_STATUS      = p_MARKET_STATUS,
           MARKET_STATUS_DATE = SYSDATE
     WHERE TRANSACTION_ID = p_TRANSACTION_ID
       AND SCHEDULE_DATE BETWEEN v_BEGIN_DATE AND v_END_DATE;

  END UPDATE_BID_OFFER_STATUS;
-------------------------------------------------------------------------------------
FUNCTION GET_FTR_TRANSACTION_ID(p_AUCTION_DATE             IN DATE,
                                p_NEW_TRANSACTION_END_DATE IN DATE,
                                p_TRANSACTION_TYPE         IN VARCHAR2,
                                p_CONTRACT_ID           	 IN NUMBER,
                                p_FLOWGATE_NAME            IN VARCHAR2,
                                p_SOURCE_NAME              IN VARCHAR2,
                                p_SINK_NAME                IN VARCHAR2,
                                p_COMMODITY_TYPE           IN VARCHAR2,
                                p_AGREEMENT_TYPE           IN VARCHAR2,
                                p_PEAK_CLASS IN VARCHAR2,
                                p_TRANSACTION_ROWNUM       IN VARCHAR2,
                                p_CREATE_IF_NOT_FOUND      IN BOOLEAN,
                                p_ERROR_MESSAGE            OUT VARCHAR2,
                                p_CLEARED_MW IN NUMBER := 0,
                                p_AUCTION_TYPE IN VARCHAR2 := NULL,
                                p_TRANSACTION_DESC IN VARCHAR2 := NULL)
    RETURN NUMBER IS

    v_TRANSACTION_ID       NUMBER(9);
    v_RAW_TRANSACTION_NAME VARCHAR2(1024); --INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
    v_TRANS_NAME	INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
    v_MAX_TXN_INDEX        NUMBER(2);
    v_TRANSACTION          INTERCHANGE_TRANSACTION%ROWTYPE;
    v_CURRENT_ROWNUM       NUMBER(3) := 1;
    v_TXN_DOES_NOT_EXIST   BOOLEAN := FALSE;
    v_SERV_POINT_ID		   SERVICE_POINT.SERVICE_POINT_ID%TYPE;
v_STATUS NUMBER;
v_CLEAREDMW_ATTRIBUTE_ID NUMBER(9);
v_AUCTNAME_ATTRIBUTE_ID NUMBER(9);

    CURSOR c_TRANSACTIONS(v_NAME IN VARCHAR2) IS
      SELECT TRANSACTION_ID
        FROM INTERCHANGE_TRANSACTION A,
             SERVICE_POINT           C,
             SERVICE_POINT           D,
             IT_COMMODITY            E,
             PJM_EMKT_PNODES	P
       WHERE p_AUCTION_DATE BETWEEN A.BEGIN_DATE AND A.END_DATE
         AND A.TRANSACTION_TYPE = INITCAP(LTRIM(RTRIM(p_TRANSACTION_TYPE)))
         AND A.TRANSACTION_NAME = v_NAME
         AND A.AGREEMENT_TYPE = p_AGREEMENT_TYPE
         AND C.SERVICE_POINT_ALIAS = p_SOURCE_NAME
         AND C.SERVICE_POINT_ID = A.SOURCE_ID
         AND P.NODENAME = p_SINK_NAME
         AND D.EXTERNAL_IDENTIFIER = P.PNODEID
         AND D.SERVICE_POINT_ID = A.SINK_ID
         AND E.COMMODITY_TYPE = p_COMMODITY_TYPE
         AND E.COMMODITY_ID = A.COMMODITY_ID
       ORDER BY TRANSACTION_ID;

  BEGIN

    IF LOGS.IS_DEBUG_ENABLED THEN
      LOGS.LOG_DEBUG('GET_FTR_TRANSACTION_ID');
      LOGS.LOG_DEBUG(' TRANSACTION_TYPE=' || p_TRANSACTION_TYPE);
      LOGS.LOG_DEBUG(' CONTRACT_ID=' || p_CONTRACT_ID);
      LOGS.LOG_DEBUG(' SOURCE_XID=' || p_SOURCE_NAME);
      LOGS.LOG_DEBUG(' SINK_XID=' || p_SINK_NAME);
      LOGS.LOG_DEBUG(' AGREEMENT_TYPE=' || p_AGREEMENT_TYPE);
      LOGS.LOG_DEBUG(' COMMODITY_TYPE=' || p_COMMODITY_TYPE);
      LOGS.LOG_DEBUG(' DUPLICATE ROWNUM=' || TO_CHAR(p_TRANSACTION_ROWNUM));
      COMMIT;
    END IF;


    v_RAW_TRANSACTION_NAME := TO_CHAR(p_AUCTION_DATE, 'MON YYYY') || '_' ||
                                  SUBSTR(p_AGREEMENT_TYPE, 1, 15) ||
                                  '_' ||
                                  SUBSTR(REPLACE(p_SOURCE_NAME, ' ', ''), 1, 22) || '_' ||
                                  SUBSTR(REPLACE(p_SINK_NAME, ' ', ''), 1, 22) ||
                                  SUBSTR(p_TRANSACTION_TYPE,1,4);

    v_RAW_TRANSACTION_NAME := SUBSTR(v_RAW_TRANSACTION_NAME,1,59);


    BEGIN
		SELECT NVL(MAX(TO_NUMBER(SUBSTR(TRANSACTION_NAME, -3, 3))), 0)
		INTO v_MAX_TXN_INDEX
		FROM INTERCHANGE_TRANSACTION
		WHERE TRANSACTION_NAME LIKE v_RAW_TRANSACTION_NAME || '____'
		AND SUBSTR(TRANSACTION_NAME, -4) BETWEEN '_000' AND '_999';
	EXCEPTION
		WHEN OTHERS THEN
            v_MAX_TXN_INDEX := 0;
	END;

    --Append the new number to the end of the transaction name so we always get a unique name.
    v_TRANS_NAME := v_RAW_TRANSACTION_NAME || '_' ||
					TRIM(TO_CHAR(v_MAX_TXN_INDEX + 1,'000'));

    --FIND THE INTERCHANGE TRANSACTION THAT APPLIES.
    BEGIN
      OPEN c_TRANSACTIONS(v_TRANS_NAME);
      WHILE v_CURRENT_ROWNUM <= p_TRANSACTION_ROWNUM LOOP
        v_TRANSACTION_ID := NULL;
        FETCH c_TRANSACTIONS
          INTO v_TRANSACTION_ID;

        v_TXN_DOES_NOT_EXIST := c_TRANSACTIONS%NOTFOUND;

        IF LOGS.IS_DEBUG_ENABLED THEN
          LOGS.LOG_DEBUG('v_CURRENT_ROWNUM=' || TO_CHAR(v_CURRENT_ROWNUM));
          LOGS.LOG_DEBUG('DID IT EXIST? ' ||
                         UT.TRACE_BOOLEAN(NOT v_TXN_DOES_NOT_EXIST) ||
                         ' TRANSACTION_ID= ' || TO_CHAR(v_TRANSACTION_ID));
        END IF;

        EXIT WHEN v_TXN_DOES_NOT_EXIST;

        v_CURRENT_ROWNUM := v_CURRENT_ROWNUM + 1;
      END LOOP;
      CLOSE c_TRANSACTIONS;
    EXCEPTION
      WHEN OTHERS THEN
        CLOSE c_TRANSACTIONS;
        RAISE;
    END;

    --CREATE ONE IF IT DOES NOT EXIST.
    IF v_TXN_DOES_NOT_EXIST THEN
      IF p_CREATE_IF_NOT_FOUND THEN

        IF LOGS.IS_DEBUG_ENABLED THEN
          LOGS.LOG_DEBUG('THE TRANSACTION DOES NOT EXIST.  ATTEMPTING WITH RAW NAME=' ||
                         v_RAW_TRANSACTION_NAME);
          COMMIT;
        END IF;

		v_TRANSACTION.TRANSACTION_NAME := v_TRANS_NAME;

        IF LOGS.IS_DEBUG_ENABLED THEN
          LOGS.LOG_DEBUG('FULL TRANSACTION NAME=' ||
                         v_TRANSACTION.TRANSACTION_NAME);
          COMMIT;
        END IF;

        --Get the correct values in preparation for adding the txn.

        v_TRANSACTION.PSE_ID := 0; --ID.ID_FOR_PSE_EXTERNAL_IDENTIFIER(p_PSE_NAME);

	--get source and sink ids
        v_TRANSACTION.SOURCE_ID := ID_FOR_SERVICE_POINT_NAME(p_SOURCE_NAME);
		v_TRANSACTION.SINK_ID := ID_FOR_SERVICE_POINT_NAME(p_SINK_NAME);

        IF v_TRANSACTION.SOURCE_ID <= 0 THEN
          p_ERROR_MESSAGE := 'Service Point with External Identifier=' ||
                             p_SOURCE_NAME || ' does not exist.';
          RETURN - 1;
        ELSIF v_TRANSACTION.SINK_ID <= 0 THEN
          p_ERROR_MESSAGE := 'Service Point with External Identifier=' ||
                             p_SINK_NAME || ' does not exist.';
          RETURN - 1;
        END IF;

        SELECT COMMODITY_ID
          INTO v_TRANSACTION.COMMODITY_ID
          FROM IT_COMMODITY
         WHERE COMMODITY_TYPE = p_COMMODITY_TYPE
           AND ROWNUM = 1;

        v_TRANSACTION.TRANSACTION_TYPE     := p_TRANSACTION_TYPE;
        v_TRANSACTION.TRANSACTION_ALIAS    := SUBSTR(v_TRANSACTION.TRANSACTION_NAME,
                                                     1,
                                                     32);

        v_TRANSACTION.TRANSACTION_DESC     := 'RetailOffice generated schedule';

        v_TRANSACTION.TRANSACTION_ID       := 0;
        v_TRANSACTION.IS_BID_OFFER         := 1;
        v_TRANSACTION.TRANSACTION_INTERVAL := 'Hour';
        v_TRANSACTION.EXTERNAL_INTERVAL    := 'Hour';
        v_TRANSACTION.BEGIN_DATE           := TRUNC(p_AUCTION_DATE, 'MONTH');
        v_TRANSACTION.END_DATE             := p_NEW_TRANSACTION_END_DATE;
        v_TRANSACTION.AGREEMENT_TYPE       := p_AGREEMENT_TYPE;
        v_TRANSACTION.SC_ID				   := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM);
		v_TRANSACTION.CONTRACT_ID		   := p_CONTRACT_ID;

        --Create the transaction and get the new ID to return.
        MM_UTIL.PUT_TRANSACTION(v_TRANSACTION_ID,
                                v_TRANSACTION,
                                GA.INTERNAL_STATE,
                                'Active');

			-- add the needed entity attributes
			ID.ID_FOR_ENTITY_ATTRIBUTE('ClearedMW', 'TRANSACTION', 'Number',
         							TRUE, v_CLEAREDMW_ATTRIBUTE_ID);
            --bugzilla 9717 use entity attribute for auction name
            ID.ID_FOR_ENTITY_ATTRIBUTE('Auction_Name', 'TRANSACTION', 'String',
         							TRUE, v_AUCTNAME_ATTRIBUTE_ID);
            IF UPPER(p_TRANSACTION_TYPE) = 'SALE' THEN
            	SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
        									v_TRANSACTION.BEGIN_DATE, NULL, p_CLEARED_MW * -1,
                                            v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
                                            v_TRANSACTION.BEGIN_DATE, v_STATUS);
        	ELSE
            	SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
        									v_TRANSACTION.BEGIN_DATE, NULL, p_CLEARED_MW,
                                            v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
                                            v_TRANSACTION.BEGIN_DATE, v_STATUS);
           END IF;
           SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID, v_AUCTNAME_ATTRIBUTE_ID,
        									v_TRANSACTION.BEGIN_DATE, NULL, p_TRANSACTION_DESC,
                                            v_TRANSACTION_ID, v_AUCTNAME_ATTRIBUTE_ID,
                                            v_TRANSACTION.BEGIN_DATE, v_STATUS);
      ELSE
        p_ERROR_MESSAGE := 'Transaction does not exist.';
      END IF;
    END IF;

    RETURN v_TRANSACTION_ID;

 EXCEPTION
    WHEN OTHERS THEN
      p_ERROR_MESSAGE            := 'ERROR OCCURED IN GET_FTR_TRANSACTION_ID ' ||
                                    UT.GET_FULL_ERRM;
    RETURN v_TRANSACTION_ID;
  END GET_FTR_TRANSACTION_ID;
-------------------------------------------------------------------------------------------
--called by PUT_FTR_POSITION, although very similar to GET_FTR_TRANSACTION_ID, this
--separate routine is needed so extra transactions don't get created for same source
-- and sink
FUNCTION GET_FTR_TXN_ID_POSITION(p_AUCTION_DATE             IN DATE,
                                p_NEW_TRANSACTION_END_DATE IN DATE,
                                p_INTERVAL_BEG_DATE IN DATE,
                                p_TRANSACTION_TYPE         IN VARCHAR2,
                                p_CONTRACT_ID           	 IN NUMBER,
                                p_FLOWGATE_NAME            IN VARCHAR2,
                                p_SOURCE_NAME              IN VARCHAR2,
                                p_SINK_NAME                IN VARCHAR2,
                                p_COMMODITY_TYPE           IN VARCHAR2,
                                p_AGREEMENT_TYPE           IN VARCHAR2,
                                p_PEAK_CLASS IN VARCHAR2,
                                p_TRANSACTION_ROWNUM       IN VARCHAR2,
                                p_CREATE_IF_NOT_FOUND      IN BOOLEAN,
                                p_ERROR_MESSAGE            OUT VARCHAR2,
                                p_CLEARED_MW IN NUMBER := 0,
                                p_CLEARING_PRICE IN NUMBER := 0,
                                p_AUCTION_TYPE IN VARCHAR2 := NULL,
                                p_TRANSACTION_DESC IN VARCHAR2 := NULL)
RETURN NUMBER IS

v_TRANSACTION_ID       NUMBER(9);
v_RAW_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_TRANS_NAME	INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_MAX_TXN_INDEX        NUMBER(2);
v_TRANSACTION          INTERCHANGE_TRANSACTION%ROWTYPE;
v_CURRENT_ROWNUM       NUMBER(3) := 1;
v_TXN_DOES_NOT_EXIST   BOOLEAN := FALSE;
v_SERV_POINT_ID		   SERVICE_POINT.SERVICE_POINT_ID%TYPE;
v_STATUS NUMBER;
v_CLEAREDMW_ATTRIBUTE_ID NUMBER(9);
v_AUCTNAME_ATTRIBUTE_ID NUMBER(9);
v_CLEARINGPRICE_ATTRIBUTE_ID NUMBER(9);
v_PSE_ALIAS VARCHAR2(32);

    CURSOR c_TRANSACTIONS(v_NAME IN VARCHAR2) IS
      SELECT TRANSACTION_ID
        FROM INTERCHANGE_TRANSACTION A,
             SERVICE_POINT           C,
             SERVICE_POINT           D,
             IT_COMMODITY            E,
             PJM_EMKT_PNODES	P
       WHERE p_AUCTION_DATE BETWEEN A.BEGIN_DATE AND A.END_DATE
         AND A.TRANSACTION_TYPE = INITCAP(LTRIM(RTRIM(p_TRANSACTION_TYPE)))
         AND A.TRANSACTION_NAME = v_NAME
         AND A.AGREEMENT_TYPE = p_AGREEMENT_TYPE
         AND C.SERVICE_POINT_ALIAS like p_SOURCE_NAME ||'%'
         AND C.SERVICE_POINT_ID = A.SOURCE_ID
         AND P.NODENAME = p_SINK_NAME
         AND D.EXTERNAL_IDENTIFIER = P.PNODEID
         AND D.SERVICE_POINT_ID = A.SINK_ID
         AND E.COMMODITY_TYPE = p_COMMODITY_TYPE
         AND E.COMMODITY_ID = A.COMMODITY_ID
       ORDER BY TRANSACTION_ID;

BEGIN

    SELECT P.PSE_ALIAS
    INTO v_PSE_ALIAS
    FROM PURCHASING_SELLING_ENTITY P, INTERCHANGE_CONTRACT I
    WHERE I.CONTRACT_ID = p_CONTRACT_ID
    AND P.PSE_ID = I.BILLING_ENTITY_ID;

    v_RAW_TRANSACTION_NAME := v_PSE_ALIAS || ':' || TO_CHAR(p_AUCTION_DATE, 'MON YY') ||
                                  SUBSTR(p_AGREEMENT_TYPE, 1, 11) ||
                                  '_' ||
                                  SUBSTR(REPLACE(p_SOURCE_NAME, ' ', ''), 1, 17) || '_' ||
                                  SUBSTR(REPLACE(p_SINK_NAME, ' ', ''), 1, 17) ||
                                  SUBSTR(p_TRANSACTION_TYPE,1,1);

    v_RAW_TRANSACTION_NAME := SUBSTR(v_RAW_TRANSACTION_NAME,1,59);

    v_TRANS_NAME := v_RAW_TRANSACTION_NAME || '_' ||
					TRIM(TO_CHAR(TO_NUMBER(p_TRANSACTION_ROWNUM),'000'));


    --FIND THE INTERCHANGE TRANSACTION THAT APPLIES.
    BEGIN
      OPEN c_TRANSACTIONS(v_TRANS_NAME);

        FETCH c_TRANSACTIONS
          INTO v_TRANSACTION_ID;

        IF v_TRANSACTION_ID IS NULL THEN
            v_TXN_DOES_NOT_EXIST := TRUE;
        END IF;

      CLOSE c_TRANSACTIONS;
   EXCEPTION
     WHEN OTHERS THEN
        CLOSE c_TRANSACTIONS;
        RAISE;
   END;
    --CREATE ONE IF IT DOES NOT EXIST.
    IF v_TXN_DOES_NOT_EXIST THEN
      IF p_CREATE_IF_NOT_FOUND THEN

        IF LOGS.IS_DEBUG_ENABLED THEN
          LOGS.LOG_DEBUG('THE TRANSACTION DOES NOT EXIST.  ATTEMPTING WITH RAW NAME=' ||
                         v_RAW_TRANSACTION_NAME);
          COMMIT;
        END IF;

		v_TRANSACTION.TRANSACTION_NAME := v_TRANS_NAME;

        IF LOGS.IS_DEBUG_ENABLED THEN
          LOGS.LOG_DEBUG('FULL TRANSACTION NAME=' ||
                         v_TRANSACTION.TRANSACTION_NAME);
          COMMIT;
        END IF;

        --Get the correct values in preparation for adding the txn.

        v_TRANSACTION.PSE_ID := 0; --ID.ID_FOR_PSE_EXTERNAL_IDENTIFIER(p_PSE_NAME);

	--get source and sink ids
        v_TRANSACTION.SOURCE_ID := ID_FOR_SERVICE_POINT_NAME(p_SOURCE_NAME);
		v_TRANSACTION.SINK_ID := ID_FOR_SERVICE_POINT_NAME(p_SINK_NAME);

        IF v_TRANSACTION.SOURCE_ID <= 0 THEN
          p_ERROR_MESSAGE := 'Service Point with External Identifier=' ||
                             p_SOURCE_NAME || ' does not exist.';
          RETURN - 1;
        ELSIF v_TRANSACTION.SINK_ID <= 0 THEN
          p_ERROR_MESSAGE := 'Service Point with External Identifier=' ||
                             p_SINK_NAME || ' does not exist.';
          RETURN - 1;
        END IF;

        SELECT COMMODITY_ID
          INTO v_TRANSACTION.COMMODITY_ID
          FROM IT_COMMODITY
         WHERE COMMODITY_TYPE = p_COMMODITY_TYPE
           AND ROWNUM = 1;

        v_TRANSACTION.TRANSACTION_TYPE     := p_TRANSACTION_TYPE;
        v_TRANSACTION.TRANSACTION_ALIAS    := SUBSTR(v_TRANSACTION.TRANSACTION_NAME,
                                                     1, 32);
        v_TRANSACTION.TRANSACTION_DESC     := 'RetailOffice generated schedule';
        v_TRANSACTION.TRANSACTION_ID       := 0;
        v_TRANSACTION.IS_BID_OFFER         := 1;
        v_TRANSACTION.TRANSACTION_INTERVAL := 'Hour';
        v_TRANSACTION.EXTERNAL_INTERVAL    := 'Hour';
        v_TRANSACTION.BEGIN_DATE           := TRUNC(p_AUCTION_DATE, 'MONTH');
        v_TRANSACTION.END_DATE             := p_NEW_TRANSACTION_END_DATE;
        v_TRANSACTION.AGREEMENT_TYPE       := p_AGREEMENT_TYPE;
        v_TRANSACTION.SC_ID				   := EI.GET_ID_FROM_IDENTIFIER_EXTSYS('PJM', EC.ED_SC, EC.ES_PJM);
		v_TRANSACTION.CONTRACT_ID		   := p_CONTRACT_ID;

        --Create the transaction and get the new ID to return.
        MM_UTIL.PUT_TRANSACTION(v_TRANSACTION_ID,
                                v_TRANSACTION,
                                GA.INTERNAL_STATE,
                                'Active');

			-- add the needed entity attributes
			ID.ID_FOR_ENTITY_ATTRIBUTE('ClearedMW', 'TRANSACTION', 'Number',
         							TRUE, v_CLEAREDMW_ATTRIBUTE_ID);
            --bugzilla 9717 use entity attribute for auction name
            ID.ID_FOR_ENTITY_ATTRIBUTE('Auction_Name', 'TRANSACTION', 'String',
         							TRUE, v_AUCTNAME_ATTRIBUTE_ID);

            IF UPPER(p_TRANSACTION_TYPE) = 'SALE' THEN
            	SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
        									v_TRANSACTION.BEGIN_DATE, NULL, p_CLEARED_MW * -1,
                                            v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
                                            v_TRANSACTION.BEGIN_DATE, v_STATUS);
        	ELSE
            	SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
        									v_TRANSACTION.BEGIN_DATE, NULL, p_CLEARED_MW,
                                            v_TRANSACTION_ID, v_CLEAREDMW_ATTRIBUTE_ID,
                                            v_TRANSACTION.BEGIN_DATE, v_STATUS);
           END IF;
           SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID, v_AUCTNAME_ATTRIBUTE_ID,
        									v_TRANSACTION.BEGIN_DATE, NULL, p_TRANSACTION_DESC,
                                            v_TRANSACTION_ID, v_AUCTNAME_ATTRIBUTE_ID,
                                            v_TRANSACTION.BEGIN_DATE, v_STATUS);


      ELSE
        p_ERROR_MESSAGE := 'Transaction does not exist.';
      END IF;
    END IF;

    IF v_TRANSACTION_ID IS NOT NULL THEN
        IF p_AUCTION_TYPE = 'Annual' THEN
            ID.ID_FOR_ENTITY_ATTRIBUTE('ClearingPrice', 'TRANSACTION', 'Number',
             							TRUE, v_CLEARINGPRICE_ATTRIBUTE_ID);
            SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(v_TRANSACTION_ID, v_CLEARINGPRICE_ATTRIBUTE_ID,
            									TRUNC(p_INTERVAL_BEG_DATE, 'MONTH'), NULL, p_CLEARING_PRICE/365,
                                                v_TRANSACTION_ID, v_CLEARINGPRICE_ATTRIBUTE_ID,
                                                TRUNC(p_INTERVAL_BEG_DATE, 'MONTH'), v_STATUS);
        END IF;
    END IF;

    RETURN v_TRANSACTION_ID;

 EXCEPTION
    WHEN OTHERS THEN
      p_ERROR_MESSAGE := 'ERROR OCCURED IN GET_FTR_TXN_ID ' ||
                                    UT.GET_FULL_ERRM;
    RETURN v_TRANSACTION_ID;
END GET_FTR_TXN_ID_POSITION;
-------------------------------------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_IT_SCHEDULE_24H
	(
   	p_TRANSACTION_ID IN NUMBER,
   	p_INTERVAL_BEGIN_DATE  IN DATE,
    p_INTERVAL_END_DATE IN DATE,
 	p_SCHEDULE_STATE IN NUMBER,
 	p_STATEMENT_TYPE IN NUMBER,
 	p_AMOUNT IN NUMBER,
 	p_STATUS OUT NUMBER,
 	p_ERROR_MESSAGE  OUT VARCHAR2) AS

v_AS_OF_DATE DATE;

    --For now, we are applying results to all defined schedule types.
    v_STATEMENT_TYPE STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
  BEGIN

    p_STATUS                     := GA.SUCCESS;
	SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

    IF GA.VERSION_SCHEDULE THEN
      v_AS_OF_DATE := SYSDATE;
    ELSE
      v_AS_OF_DATE := LOW_DATE;
    END IF;

   MERGE INTO IT_SCHEDULE IT
    USING ( SELECT p_TRANSACTION_ID t_id, p_STATEMENT_TYPE state_type, p_SCHEDULE_STATE sched_state,
    		CUT_DATE, v_AS_OF_DATE as_date, p_AMOUNT s_amount
            FROM system_date_time
            WHERE TIME_ZONE='EDT'
			AND DATA_INTERVAL_TYPE=1
			AND DAY_TYPE = 1
			AND MINIMUM_INTERVAL_NUMBER >= 30
			AND CUT_DATE BETWEEN p_INTERVAL_BEGIN_DATE AND p_INTERVAL_END_DATE) t1
    ON (TRANSACTION_ID = t1.t_id AND
        SCHEDULE_STATE = t1.sched_state AND
        SCHEDULE_DATE = t1.CUT_DATE  AND
        AS_OF_DATE = t1.as_date)
    WHEN MATCHED THEN
      UPDATE SET AMOUNT = p_AMOUNT
    WHEN NOT MATCHED THEN
      INSERT (TRANSACTION_ID,
         SCHEDULE_TYPE,
         SCHEDULE_STATE,
         SCHEDULE_DATE,
         AS_OF_DATE,
         AMOUNT)
     VALUES(p_TRANSACTION_ID,
         p_STATEMENT_TYPE,
         p_SCHEDULE_STATE,
         t1.CUT_DATE,
         v_AS_OF_DATE,
         p_AMOUNT);

	SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                     := SQLCODE;
      p_ERROR_MESSAGE              := UT.GET_FULL_ERRM;

  END UPDATE_IT_SCHEDULE_24H;
-------------------------------------------------------------------------------------------
PROCEDURE UPDATE_IT_SCHEDULE_PEAK
	(
   	p_TRANSACTION_ID IN NUMBER,
   	p_INTERVAL_BEGIN_DATE  IN DATE,
    p_INTERVAL_END_DATE IN DATE,
 	p_SCHEDULE_STATE IN NUMBER,
 	p_STATEMENT_TYPE IN NUMBER,
 	p_AMOUNT IN NUMBER,
    p_PEAK_CLASS IN VARCHAR2,
 	p_STATUS OUT NUMBER,
 	p_ERROR_MESSAGE  OUT VARCHAR2) AS

v_AS_OF_DATE DATE;
v_ON_PEAK NUMBER(1);

    --For now, we are applying results to all defined schedule types.
    v_STATEMENT_TYPE STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
  BEGIN

    p_STATUS := GA.SUCCESS;
    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

    IF GA.VERSION_SCHEDULE THEN
      v_AS_OF_DATE := SYSDATE;
    ELSE
      v_AS_OF_DATE := LOW_DATE;
    END IF;

    IF UPPER(p_PEAK_CLASS) = 'ONPEAK' THEN
    	v_ON_PEAK := 1;
    ELSE
    	v_ON_PEAK := 0;
    END IF;

   MERGE INTO IT_SCHEDULE IT
    USING ( SELECT p_TRANSACTION_ID t_id, p_STATEMENT_TYPE state_type, p_SCHEDULE_STATE sched_state,
    		CUT_DATE, v_AS_OF_DATE as_date, p_AMOUNT s_amount
            FROM system_date_time
            WHERE TIME_ZONE='EDT'
			AND DATA_INTERVAL_TYPE=1
			AND DAY_TYPE = 1
            AND IS_ON_PEAK = v_ON_PEAK
			AND MINIMUM_INTERVAL_NUMBER >= 30
			AND CUT_DATE BETWEEN p_INTERVAL_BEGIN_DATE AND p_INTERVAL_END_DATE) t1
    ON (TRANSACTION_ID = t1.t_id AND
        SCHEDULE_STATE = t1.sched_state AND
        SCHEDULE_DATE = t1.CUT_DATE  AND
        AS_OF_DATE = t1.as_date)
    WHEN MATCHED THEN
      UPDATE SET AMOUNT = p_AMOUNT
    WHEN NOT MATCHED THEN
      INSERT (TRANSACTION_ID,
         SCHEDULE_TYPE,
         SCHEDULE_STATE,
         SCHEDULE_DATE,
         AS_OF_DATE,
         AMOUNT)
     VALUES(p_TRANSACTION_ID,
         p_STATEMENT_TYPE,
         p_SCHEDULE_STATE,
         t1.CUT_DATE,
         v_AS_OF_DATE,
         p_AMOUNT);

	SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
	  SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                     := SQLCODE;
      p_ERROR_MESSAGE              := UT.GET_FULL_ERRM;

END UPDATE_IT_SCHEDULE_PEAK;
-------------------------------------------------------------------------------------------
PROCEDURE ADD_FTR_SALE_TO_SCHEDULE
	(
	p_AUCTION_DATE IN DATE,
    p_INTERVAL_BEGIN_DATE IN DATE,
    p_INTERVAL_END_DATE IN DATE,
	p_SCHEDULE_STATE IN NUMBER,
	p_TRANSACTION_TYPE IN VARCHAR2,
	p_CONTRACT_ID IN NUMBER,
    p_PEAK_CLASS IN VARCHAR2,
	p_SOURCE_NAME IN VARCHAR2,
	p_SINK_NAME IN VARCHAR2,
	p_COMMODITY_TYPE IN VARCHAR2,
	p_AGREEMENT_TYPE IN VARCHAR2,
    p_CLEARED_MW IN NUMBER,
	p_TRANSACTION_ROWNUM IN VARCHAR2,
	p_MESSAGE OUT VARCHAR2,
    p_STATUS OUT NUMBER,
	p_TRANSACTION_DESC IN VARCHAR2 := NULL,
	p_AUCTION_ROUND	IN NUMBER := 1
    )IS

v_TRANSACTION_ID NUMBER(9);
v_RAW_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_TRANS_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_MAX_TXN_INDEX NUMBER(2);
v_CURRENT_ROWNUM NUMBER(3) := 1;
v_AMOUNT IT_SCHEDULE.AMOUNT%TYPE;
v_REMAINDER IT_SCHEDULE.AMOUNT%TYPE;
v_TXN_DOES_NOT_EXIST BOOLEAN := FALSE;
v_UPDATE_AMOUNT IT_SCHEDULE.AMOUNT%TYPE;
v_UPDATE_SCHEDULE BOOLEAN := FALSE;
v_TOTAL_AMOUNT BOOLEAN := FALSE;
v_MONTH VARCHAR2(2);
v_YEAR VARCHAR2(4);
v_MON NUMBER(2);
v_YR NUMBER(4);
v_START_DATE DATE;


    CURSOR c_TRANSACTIONS(v_NAME IN VARCHAR2) IS
      SELECT TRANSACTION_ID
        FROM INTERCHANGE_TRANSACTION A,
             SERVICE_POINT           C,
             SERVICE_POINT           D,
             IT_COMMODITY            E,
             PJM_EMKT_PNODES	P
       WHERE p_AUCTION_DATE BETWEEN A.BEGIN_DATE AND A.END_DATE
         AND A.TRANSACTION_TYPE = INITCAP(LTRIM(RTRIM(p_TRANSACTION_TYPE)))
         AND A.TRANSACTION_NAME = v_NAME
         AND A.AGREEMENT_TYPE = p_AGREEMENT_TYPE
         AND C.SERVICE_POINT_ALIAS = p_SOURCE_NAME
         AND C.SERVICE_POINT_ID = A.SOURCE_ID
         AND P.NODENAME = p_SINK_NAME
         AND D.EXTERNAL_IDENTIFIER = P.PNODEID
         AND D.SERVICE_POINT_ID = A.SINK_ID
         AND E.COMMODITY_TYPE = p_COMMODITY_TYPE
         AND E.COMMODITY_ID = A.COMMODITY_ID
       ORDER BY TRANSACTION_ID;

  BEGIN

    v_RAW_TRANSACTION_NAME := TO_CHAR(p_AUCTION_DATE, 'MON YYYY') || '_' ||
                                  SUBSTR(p_AGREEMENT_TYPE, 1, 15) ||
                                  '_' ||
                                  SUBSTR(p_SOURCE_NAME, 1, 22) || '_' ||
                                  SUBSTR(p_SINK_NAME, 1, 22) ||
                                  SUBSTR('Purchase',1,4);

    v_RAW_TRANSACTION_NAME := SUBSTR(v_RAW_TRANSACTION_NAME,1,59);

    BEGIN
          SELECT NVL(MAX(TO_NUMBER(SUBSTR(TRANSACTION_NAME, -3, 3))), 0)
            INTO v_MAX_TXN_INDEX
            FROM INTERCHANGE_TRANSACTION
           WHERE TRANSACTION_NAME LIKE v_RAW_TRANSACTION_NAME || '____'
             AND SUBSTR(TRANSACTION_NAME, -4) BETWEEN '_000' AND '_999'
             AND CONTRACT_ID = p_CONTRACT_ID;
	EXCEPTION
    	WHEN OTHERS THEN
			v_MAX_TXN_INDEX := 0;
    END;

    -- sale may be OnPeak or OffPeak but original txn may be 24H so look for
    -- FTR%, not FTR 24H, for example
    IF v_MAX_TXN_INDEX = 0 THEN
    	v_RAW_TRANSACTION_NAME := TO_CHAR(p_AUCTION_DATE, 'MON YYYY') || '_' ||
                                  'FTR%' ||
                                  '_' ||
                                  SUBSTR(p_SOURCE_NAME, 1, 22) || '_' ||
                                  SUBSTR(p_SINK_NAME, 1, 22) ||
                                  'Purchase';
        v_RAW_TRANSACTION_NAME := SUBSTR(v_RAW_TRANSACTION_NAME,1,59);

		BEGIN
        	SELECT NVL(MAX(TO_NUMBER(SUBSTR(TRANSACTION_NAME, -3, 3))), 0)
        	INTO v_MAX_TXN_INDEX
        	FROM INTERCHANGE_TRANSACTION
       		WHERE TRANSACTION_NAME LIKE v_RAW_TRANSACTION_NAME || '____'
         	AND SUBSTR(TRANSACTION_NAME, -4) BETWEEN '_000' AND '_999'
            AND CONTRACT_ID = p_CONTRACT_ID;
		EXCEPTION
            WHEN OTHERS THEN
				v_MAX_TXN_INDEX := 0;
       END;
	END IF;

    v_START_DATE := p_INTERVAL_BEGIN_DATE;
    IF IS_ON_PEAK_DAY(v_START_DATE) = FALSE THEN
    	WHILE IS_ON_PEAK_DAY(v_START_DATE) = FALSE LOOP
    		v_START_DATE := v_START_DATE + 1;
        END LOOP;
    END IF;

    -- if a monthly sale, name should be JUN YYYY, not name of current month auction
    IF v_MAX_TXN_INDEX = 0 THEN
    	v_MONTH := TO_CHAR(p_AUCTION_DATE, 'MM');
        v_YEAR := TO_CHAR(p_AUCTION_DATE, 'YYYY');
        v_MON := TO_NUMBER(v_MONTH);
        v_YR := TO_NUMBER(v_YEAR);

        IF v_MON BETWEEN 1 AND 5 THEN
        	v_YR := v_YR - 1;
        END IF;

    	v_RAW_TRANSACTION_NAME := 'JUN ' || TO_CHAR(v_YR) || '_' ||
                                  'FTR%' ||
                                  '_' ||
                                  SUBSTR(p_SOURCE_NAME, 1, 22) || '_' ||
                                  SUBSTR(p_SINK_NAME, 1, 22) ||
                                  'Purchase';
        v_RAW_TRANSACTION_NAME := SUBSTR(v_RAW_TRANSACTION_NAME,1,59);

		BEGIN
        	SELECT NVL(MAX(TO_NUMBER(SUBSTR(TRANSACTION_NAME, -3, 3))), 0)
        	INTO v_MAX_TXN_INDEX
        	FROM INTERCHANGE_TRANSACTION
       		WHERE TRANSACTION_NAME LIKE v_RAW_TRANSACTION_NAME || '____'
         	AND SUBSTR(TRANSACTION_NAME, -4) BETWEEN '_000' AND '_999'
            AND CONTRACT_ID = p_CONTRACT_ID;
		EXCEPTION
            WHEN OTHERS THEN
				v_MAX_TXN_INDEX := 0;
       END;
	END IF;

	IF v_MAX_TXN_INDEX > 0 THEN
    	v_REMAINDER := p_CLEARED_MW;

		FOR v_INDEX IN 1..v_MAX_TXN_INDEX LOOP
        	v_TXN_DOES_NOT_EXIST := FALSE;

            v_TRANS_NAME := v_RAW_TRANSACTION_NAME || '_' ||
  							TRIM(TO_CHAR(v_INDEX,'000'));

			--FIND THE INTERCHANGE TRANSACTION THAT APPLIES.
			BEGIN
            	SELECT TRANSACTION_ID INTO v_TRANSACTION_ID
                FROM INTERCHANGE_TRANSACTION
                WHERE TRANSACTION_NAME LIKE v_TRANS_NAME
                AND CONTRACT_ID = p_CONTRACT_ID;

			EXCEPTION
  				WHEN NO_DATA_FOUND THEN
    				v_TXN_DOES_NOT_EXIST := TRUE;
			END;

            IF NOT v_TXN_DOES_NOT_EXIST THEN
            	IF UPPER(p_PEAK_CLASS) <> 'ONPEAK' THEN
                    SELECT AMOUNT INTO v_AMOUNT
                    FROM IT_SCHEDULE WHERE
                    TRANSACTION_ID = v_TRANSACTION_ID
                    AND SCHEDULE_DATE = v_START_DATE;
               ELSE
               		SELECT AMOUNT INTO v_AMOUNT
                    FROM IT_SCHEDULE WHERE
                    TRANSACTION_ID = v_TRANSACTION_ID
                    AND SCHEDULE_DATE = v_START_DATE + 8 / 24;
               END IF;



                IF v_AMOUNT >= v_REMAINDER THEN
                	v_UPDATE_SCHEDULE := TRUE;
                    v_TOTAL_AMOUNT := TRUE;
                    v_UPDATE_AMOUNT := v_AMOUNT - v_REMAINDER;
                -- update this schedule but will need to get
                -- another txn too
                ELSIF v_AMOUNT > 0 THEN
                	v_UPDATE_SCHEDULE := TRUE;
                    v_TOTAL_AMOUNT := FALSE;
                    v_UPDATE_AMOUNT := v_REMAINDER - v_AMOUNT;
                    v_REMAINDER := v_REMAINDER - v_AMOUNT;
                END IF;

            	IF v_UPDATE_SCHEDULE THEN
                	IF UPPER(p_PEAK_CLASS) = '24H' THEN
                    	FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
                			UPDATE_IT_SCHEDULE_24H(
                    								v_TRANSACTION_ID,
                            						p_INTERVAL_BEGIN_DATE,
                            						p_INTERVAL_END_DATE,
                                                    p_SCHEDULE_STATE,
                                                    I,
                                                    v_UPDATE_AMOUNT,
                                                    p_STATUS,
                                                    p_MESSAGE);
                    	END LOOP;
					ELSE
                    	FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
                			UPDATE_IT_SCHEDULE_PEAK(
                    								v_TRANSACTION_ID,
                                                    p_INTERVAL_BEGIN_DATE,
                                                    p_INTERVAL_END_DATE,
                                                    p_SCHEDULE_STATE,
                                                    I,
                                                    v_UPDATE_AMOUNT,
                                                    p_PEAK_CLASS,
                                                    p_STATUS,
                                                    p_MESSAGE);
                    	END LOOP;
                    END IF;


                    NULL;
                END IF;

                IF v_TOTAL_AMOUNT THEN
                	EXIT;
            	END IF;


        	END IF;

		END LOOP;

	END IF;




END ADD_FTR_SALE_TO_SCHEDULE;
---------------------------------------------------------------------------------------------
PROCEDURE ADD_FTR_BILAT_SALE_TO_SCHED
	(
	p_AUCTION_DATE IN DATE,
    p_INTERVAL_BEGIN_DATE IN DATE,
    p_INTERVAL_END_DATE IN DATE,
	p_SCHEDULE_STATE IN NUMBER,
	p_TRANSACTION_TYPE IN VARCHAR2,
	p_CONTRACT_ID IN NUMBER,
    p_PEAK_CLASS IN VARCHAR2,
	p_SOURCE_NAME IN VARCHAR2,
	p_SINK_NAME IN VARCHAR2,
	p_COMMODITY_TYPE IN VARCHAR2,
	p_AGREEMENT_TYPE IN VARCHAR2,
    p_CLEARED_MW IN NUMBER,
    p_SALE_TXN_ID IN NUMBER,
	p_TRANSACTION_ROWNUM IN VARCHAR2,
	p_MESSAGE OUT VARCHAR2,
    p_STATUS OUT NUMBER,
	p_TRANSACTION_DESC IN VARCHAR2 := NULL,
	p_AUCTION_ROUND	IN NUMBER := 1
    )IS

v_TRANSACTION_ID NUMBER(9);
v_TRANS_ROW_NUM NUMBER;
v_RAW_TRANSACTION_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_TRANS_NAME INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
v_MAX_TXN_INDEX NUMBER(2);
v_CURRENT_ROWNUM NUMBER(3) := 1;
v_AMOUNT IT_SCHEDULE.AMOUNT%TYPE;
v_REMAINDER IT_SCHEDULE.AMOUNT%TYPE;
v_TXN_DOES_NOT_EXIST BOOLEAN := FALSE;
v_UPDATE_AMOUNT IT_SCHEDULE.AMOUNT%TYPE;
v_UPDATE_SCHEDULE BOOLEAN := FALSE;
v_TOTAL_AMOUNT BOOLEAN := FALSE;
v_MONTH VARCHAR2(2);
v_YEAR VARCHAR2(4);
v_MON NUMBER(2);
v_YR NUMBER(4);
v_START_DATE DATE;
v_PSE_ALIAS VARCHAR2(32);
v_CLEARINGPRICE_ATTRIBUTE_ID NUMBER(9);
v_CLEARING_PRICE NUMBER;


    CURSOR c_TRANSACTIONS(v_NAME IN VARCHAR2) IS
      SELECT TRANSACTION_ID
        FROM INTERCHANGE_TRANSACTION A,
             SERVICE_POINT           C,
             SERVICE_POINT           D,
             IT_COMMODITY            E,
             PJM_EMKT_PNODES	P
       WHERE p_AUCTION_DATE BETWEEN A.BEGIN_DATE AND A.END_DATE
         AND A.TRANSACTION_TYPE = INITCAP(LTRIM(RTRIM(p_TRANSACTION_TYPE)))
         AND A.TRANSACTION_NAME = v_NAME
         AND A.AGREEMENT_TYPE = p_AGREEMENT_TYPE
         AND C.SERVICE_POINT_ALIAS = p_SOURCE_NAME
         AND C.SERVICE_POINT_ID = A.SOURCE_ID
         AND P.NODENAME = p_SINK_NAME
         AND D.EXTERNAL_IDENTIFIER = P.PNODEID
         AND D.SERVICE_POINT_ID = A.SINK_ID
         AND E.COMMODITY_TYPE = p_COMMODITY_TYPE
         AND E.COMMODITY_ID = A.COMMODITY_ID
       ORDER BY TRANSACTION_ID;

  BEGIN

    SELECT P.PSE_ALIAS
    INTO v_PSE_ALIAS
    FROM PURCHASING_SELLING_ENTITY P, INTERCHANGE_CONTRACT I
    WHERE I.CONTRACT_ID = p_CONTRACT_ID
    AND P.PSE_ID = I.BILLING_ENTITY_ID;

    v_RAW_TRANSACTION_NAME := v_PSE_ALIAS || ':' || TO_CHAR(p_AUCTION_DATE, 'MON YY') ||
                                  SUBSTR(p_AGREEMENT_TYPE, 1, 11) ||
                                  '_' ||
                                  SUBSTR(REPLACE(p_SOURCE_NAME, ' ', ''), 1, 17) || '_' ||
                                  SUBSTR(REPLACE(p_SINK_NAME, ' ', ''), 1, 17) ||
                                  SUBSTR('Purchase',1,1);

    v_RAW_TRANSACTION_NAME := SUBSTR(v_RAW_TRANSACTION_NAME,1,59);

		BEGIN
          SELECT NVL(MAX(TO_NUMBER(SUBSTR(TRANSACTION_NAME, -3, 3))), 0)
            INTO v_MAX_TXN_INDEX
            FROM INTERCHANGE_TRANSACTION
           WHERE TRANSACTION_NAME LIKE v_RAW_TRANSACTION_NAME || '%'
             AND CONTRACT_ID = p_CONTRACT_ID;
		EXCEPTION
    	WHEN OTHERS THEN
			v_MAX_TXN_INDEX := 0;
    END;

		--if more than 4 sales for 4 purchases, need to re-iterate through the 4
		--purchases
		IF v_MAX_TXN_INDEX < p_TRANSACTION_ROWNUM THEN
			v_TRANS_ROW_NUM := p_TRANSACTION_ROWNUM - 4;
		ELSE
			v_TRANS_ROW_NUM := p_TRANSACTION_ROWNUM;
		END IF;

    v_TRANS_NAME := v_RAW_TRANSACTION_NAME || '_' ||
					TRIM(TO_CHAR(TO_NUMBER(v_TRANS_ROW_NUM),'000'));


    BEGIN
          SELECT NVL(MAX(TO_NUMBER(SUBSTR(TRANSACTION_NAME, -3, 3))), 0)
            INTO v_MAX_TXN_INDEX
            FROM INTERCHANGE_TRANSACTION
           WHERE TRANSACTION_NAME LIKE v_TRANS_NAME
             AND CONTRACT_ID = p_CONTRACT_ID;
	EXCEPTION
    	WHEN OTHERS THEN
			v_MAX_TXN_INDEX := 0;
    END;

    v_START_DATE := p_INTERVAL_BEGIN_DATE;

	IF v_MAX_TXN_INDEX > 0 THEN
    	v_REMAINDER := p_CLEARED_MW;

		FOR v_INDEX IN 1..v_MAX_TXN_INDEX LOOP
        	v_TXN_DOES_NOT_EXIST := FALSE;

			--FIND THE INTERCHANGE TRANSACTION THAT APPLIES.
			BEGIN
            	SELECT TRANSACTION_ID INTO v_TRANSACTION_ID
                FROM INTERCHANGE_TRANSACTION
                WHERE TRANSACTION_NAME LIKE v_TRANS_NAME
                AND CONTRACT_ID = p_CONTRACT_ID;

			EXCEPTION
  				WHEN NO_DATA_FOUND THEN
    				v_TXN_DOES_NOT_EXIST := TRUE;
			END;

            IF NOT v_TXN_DOES_NOT_EXIST THEN
            	IF UPPER(p_PEAK_CLASS) <> 'ONPEAK' THEN
                    SELECT AMOUNT INTO v_AMOUNT
                    FROM IT_SCHEDULE WHERE
                    TRANSACTION_ID = v_TRANSACTION_ID
                    AND SCHEDULE_DATE = v_START_DATE;
               ELSE
               		SELECT AMOUNT INTO v_AMOUNT
                    FROM IT_SCHEDULE WHERE
                    TRANSACTION_ID = v_TRANSACTION_ID
                    AND SCHEDULE_DATE = v_START_DATE + 8 / 24;
               END IF;



                IF v_AMOUNT >= v_REMAINDER THEN
                	v_UPDATE_SCHEDULE := TRUE;
                    v_TOTAL_AMOUNT := TRUE;
                    v_UPDATE_AMOUNT := v_AMOUNT - v_REMAINDER;
                -- update this schedule but will need to get
                -- another txn too
                ELSIF v_AMOUNT > 0 THEN
                	v_UPDATE_SCHEDULE := TRUE;
                    v_TOTAL_AMOUNT := FALSE;
                    v_UPDATE_AMOUNT := v_REMAINDER - v_AMOUNT;
                    v_REMAINDER := v_REMAINDER - v_AMOUNT;
                END IF;

                 IF v_UPDATE_SCHEDULE THEN
                	IF UPPER(p_PEAK_CLASS) = '24H' THEN
                    	FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
                			UPDATE_IT_SCHEDULE_24H(
                    								v_TRANSACTION_ID,
                            						p_INTERVAL_BEGIN_DATE,
                            						p_INTERVAL_END_DATE,
                                                    p_SCHEDULE_STATE,
                                                    I,
                                                    v_UPDATE_AMOUNT,
                                                    p_STATUS,
                                                    p_MESSAGE);
                    	END LOOP;
					ELSE
                    	FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
                			UPDATE_IT_SCHEDULE_PEAK(
                    								v_TRANSACTION_ID,
                                                    p_INTERVAL_BEGIN_DATE,
                                                    p_INTERVAL_END_DATE,
                                                    p_SCHEDULE_STATE,
                                                    I,
                                                    v_UPDATE_AMOUNT,
                                                    p_PEAK_CLASS,
                                                    p_STATUS,
                                                    p_MESSAGE);
                    	END LOOP;
                    END IF;


                    --get clearing price from purchase txn and copy to sale txn
                    ID.ID_FOR_ENTITY_ATTRIBUTE('ClearingPrice', 'TRANSACTION', 'Number',
         							TRUE, v_CLEARINGPRICE_ATTRIBUTE_ID);
                    BEGIN
                        SELECT T.ATTRIBUTE_VAL INTO v_CLEARING_PRICE
                        FROM TEMPORAL_ENTITY_ATTRIBUTE T
                        WHERE T.OWNER_ENTITY_ID = v_TRANSACTION_ID
                        AND T.ATTRIBUTE_ID = v_CLEARINGPRICE_ATTRIBUTE_ID
                        AND T.BEGIN_DATE = TRUNC(p_INTERVAL_BEGIN_DATE, 'MONTH');
                    EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            NULL;
                    END;

                    IF v_CLEARING_PRICE IS NOT NULL THEN

                        SP.PUT_TEMPORAL_ENTITY_ATTRIBUTE(p_SALE_TXN_ID, v_CLEARINGPRICE_ATTRIBUTE_ID,
        									TRUNC(p_INTERVAL_BEGIN_DATE, 'MONTH'), NULL, v_CLEARING_PRICE,
                                            p_SALE_TXN_ID, v_CLEARINGPRICE_ATTRIBUTE_ID,
                                            TRUNC(p_INTERVAL_BEGIN_DATE, 'MONTH'), p_STATUS);
                    END IF;


                END IF;

                IF v_TOTAL_AMOUNT THEN
                	EXIT;
            	END IF;


        	END IF;

		END LOOP;


	END IF;



END ADD_FTR_BILAT_SALE_TO_SCHED;
---------------------------------------------------------------------------------------------

  PROCEDURE PUT_IT_SCHEDULE_DATA(p_TRANSACTION_ID IN NUMBER,
                                 p_SCHEDULE_DATE  IN DATE,
                                 p_SCHEDULE_STATE IN NUMBER,
                                 p_STATEMENT_TYPE IN NUMBER,
                                 p_PRICE          IN NUMBER,
                                 p_AMOUNT         IN NUMBER,
                                 p_STATUS         OUT NUMBER,
                                 p_ERROR_MESSAGE  OUT VARCHAR2) AS

    v_AS_OF_DATE DATE;

    --For now, we are applying results to all defined schedule types.
    v_STATEMENT_TYPE STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
  BEGIN

    p_STATUS                     := GA.SUCCESS;
    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

    IF GA.VERSION_SCHEDULE THEN
      v_AS_OF_DATE := SYSDATE;
    ELSE
      v_AS_OF_DATE := LOW_DATE;
    END IF;

   MERGE INTO IT_SCHEDULE
    USING dual ON (TRANSACTION_ID = p_TRANSACTION_ID AND
                   SCHEDULE_STATE = p_SCHEDULE_STATE AND
                   SCHEDULE_DATE = p_SCHEDULE_DATE  AND
                   AS_OF_DATE = v_AS_OF_DATE)
    WHEN MATCHED THEN
      UPDATE SET AMOUNT = NVL(p_AMOUNT, AMOUNT), PRICE = NVL(p_PRICE, PRICE)
    WHEN NOT MATCHED THEN
      INSERT (TRANSACTION_ID,
         SCHEDULE_TYPE,
         SCHEDULE_STATE,
         SCHEDULE_DATE,
         AS_OF_DATE,
         AMOUNT,
         PRICE)
     VALUES(p_TRANSACTION_ID,
         p_STATEMENT_TYPE,
         p_SCHEDULE_STATE,
         p_SCHEDULE_DATE,
         v_AS_OF_DATE,
         p_AMOUNT,
         p_PRICE);

    /*UPDATE IT_SCHEDULE
       SET AMOUNT = NVL(p_AMOUNT, AMOUNT), PRICE = NVL(p_PRICE, PRICE)
     WHERE TRANSACTION_ID = p_TRANSACTION_ID
       AND SCHEDULE_TYPE = v_STATEMENT_TYPE
       AND SCHEDULE_STATE = p_SCHEDULE_STATE
       AND SCHEDULE_DATE = p_SCHEDULE_DATE
       AND AS_OF_DATE = v_AS_OF_DATE;
    IF SQL%NOTFOUND THEN
      INSERT INTO IT_SCHEDULE
        (TRANSACTION_ID,
         SCHEDULE_TYPE,
         SCHEDULE_STATE,
         SCHEDULE_DATE,
         AS_OF_DATE,
         AMOUNT,
         PRICE)
      VALUES
        (p_TRANSACTION_ID,
         g_STATEMENT_TYPE, -- Everything Put in Forecast Statement Type
         p_SCHEDULE_STATE,
         p_SCHEDULE_DATE,
         v_AS_OF_DATE,
         p_AMOUNT,
         p_PRICE);
    END IF;*/

    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                     := SQLCODE;
      p_ERROR_MESSAGE              := UT.GET_FULL_ERRM;

  END PUT_IT_SCHEDULE_DATA;

  --------------------------------------------------------------------------------------------------
PROCEDURE PUT_IT_SCHEDULE_DATA_24H
	(
   	p_TRANSACTION_ID IN NUMBER,
   	p_INTERVAL_BEGIN_DATE  IN DATE,
    p_INTERVAL_END_DATE IN DATE,
 	p_SCHEDULE_STATE IN NUMBER,
 	p_STATEMENT_TYPE IN NUMBER,
 	p_PRICE          IN NUMBER,
 	p_AMOUNT         IN NUMBER,
 	p_STATUS         OUT NUMBER,
 	p_ERROR_MESSAGE  OUT VARCHAR2) AS

    v_AS_OF_DATE DATE;

    --For now, we are applying results to all defined schedule types.
    v_STATEMENT_TYPE STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
  BEGIN

    p_STATUS                     := GA.SUCCESS;
    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

    IF GA.VERSION_SCHEDULE THEN
      v_AS_OF_DATE := SYSDATE;
    ELSE
      v_AS_OF_DATE := LOW_DATE;
    END IF;

   MERGE INTO IT_SCHEDULE IT
    USING ( SELECT p_TRANSACTION_ID t_id, p_STATEMENT_TYPE state_type, p_SCHEDULE_STATE sched_state,
    		CUT_DATE, v_AS_OF_DATE as_date, p_AMOUNT s_amount, p_PRICE s_price
            FROM system_date_time
            WHERE TIME_ZONE='EDT'
			AND DATA_INTERVAL_TYPE=1
			AND DAY_TYPE = 1
			AND MINIMUM_INTERVAL_NUMBER >= 30
			AND CUT_DATE BETWEEN p_INTERVAL_BEGIN_DATE AND p_INTERVAL_END_DATE) t1
    ON (TRANSACTION_ID = t1.t_id AND
        SCHEDULE_STATE = t1.sched_state AND
        SCHEDULE_DATE = t1.CUT_DATE  AND
        AS_OF_DATE = t1.as_date)
    WHEN MATCHED THEN
      UPDATE SET AMOUNT = NVL(p_AMOUNT, AMOUNT), PRICE = NVL(p_PRICE, PRICE)
    WHEN NOT MATCHED THEN
      INSERT (TRANSACTION_ID,
         SCHEDULE_TYPE,
         SCHEDULE_STATE,
         SCHEDULE_DATE,
         AS_OF_DATE,
         AMOUNT,
         PRICE)
     VALUES(p_TRANSACTION_ID,
         p_STATEMENT_TYPE,
         p_SCHEDULE_STATE,
         t1.CUT_DATE,
         v_AS_OF_DATE,
         p_AMOUNT,
         p_PRICE);

    /*UPDATE IT_SCHEDULE
       SET AMOUNT = NVL(p_AMOUNT, AMOUNT), PRICE = NVL(p_PRICE, PRICE)
     WHERE TRANSACTION_ID = p_TRANSACTION_ID
       AND SCHEDULE_TYPE = v_STATEMENT_TYPE
       AND SCHEDULE_STATE = p_SCHEDULE_STATE
       AND SCHEDULE_DATE = p_SCHEDULE_DATE
       AND AS_OF_DATE = v_AS_OF_DATE;
    IF SQL%NOTFOUND THEN
      INSERT INTO IT_SCHEDULE
        (TRANSACTION_ID,
         SCHEDULE_TYPE,
         SCHEDULE_STATE,
         SCHEDULE_DATE,
         AS_OF_DATE,
         AMOUNT,
         PRICE)
      VALUES
        (p_TRANSACTION_ID,
         g_STATEMENT_TYPE, -- Everything Put in Forecast Statement Type
         p_SCHEDULE_STATE,
         p_SCHEDULE_DATE,
         v_AS_OF_DATE,
         p_AMOUNT,
         p_PRICE);
    END IF;*/

    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                     := SQLCODE;
      p_ERROR_MESSAGE              := UT.GET_FULL_ERRM;
 END PUT_IT_SCHEDULE_DATA_24H;
--------------------------------------------------------------------------------------------------
PROCEDURE PUT_IT_SCHEDULE_DATA_PEAK
	(
   	p_TRANSACTION_ID IN NUMBER,
   	p_INTERVAL_BEGIN_DATE  IN DATE,
    p_INTERVAL_END_DATE IN DATE,
 	p_SCHEDULE_STATE IN NUMBER,
 	p_STATEMENT_TYPE IN NUMBER,
 	p_PRICE          IN NUMBER,
 	p_AMOUNT         IN NUMBER,
    p_PEAK_CLASS IN VARCHAR2,
 	p_STATUS         OUT NUMBER,
 	p_ERROR_MESSAGE  OUT VARCHAR2) AS

v_AS_OF_DATE DATE;
v_ON_PEAK NUMBER;
    --For now, we are applying results to all defined schedule types.
    v_STATEMENT_TYPE STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE;
  BEGIN

    p_STATUS                     := GA.SUCCESS;
    SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

    IF GA.VERSION_SCHEDULE THEN
      v_AS_OF_DATE := SYSDATE;
    ELSE
      v_AS_OF_DATE := LOW_DATE;
    END IF;

    IF UPPER(p_PEAK_CLASS) = 'ONPEAK' THEN
    	v_ON_PEAK := 1;
    ELSE
    	v_ON_PEAK := 0;
    END IF;

   MERGE INTO IT_SCHEDULE IT
    USING ( SELECT p_TRANSACTION_ID t_id, p_STATEMENT_TYPE state_type, p_SCHEDULE_STATE sched_state,
    		CUT_DATE, v_AS_OF_DATE as_date, p_AMOUNT s_amount, p_PRICE s_price
            FROM system_date_time
            WHERE TIME_ZONE='EDT'
			AND DATA_INTERVAL_TYPE=1
			AND DAY_TYPE = 1
            AND IS_ON_PEAK = v_ON_PEAK
			AND MINIMUM_INTERVAL_NUMBER >= 30
			AND CUT_DATE BETWEEN p_INTERVAL_BEGIN_DATE AND p_INTERVAL_END_DATE) t1
    ON (TRANSACTION_ID = t1.t_id AND
        SCHEDULE_STATE = t1.sched_state AND
        SCHEDULE_DATE = t1.CUT_DATE  AND
        AS_OF_DATE = t1.as_date)
    WHEN MATCHED THEN
      UPDATE SET AMOUNT = NVL(p_AMOUNT, AMOUNT), PRICE = NVL(p_PRICE, PRICE)
    WHEN NOT MATCHED THEN
      INSERT (TRANSACTION_ID,
         SCHEDULE_TYPE,
         SCHEDULE_STATE,
         SCHEDULE_DATE,
         AS_OF_DATE,
         AMOUNT,
         PRICE)
     VALUES(p_TRANSACTION_ID,
         p_STATEMENT_TYPE,
         p_SCHEDULE_STATE,
         t1.CUT_DATE,
         v_AS_OF_DATE,
         p_AMOUNT,
         p_PRICE);
	SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
	  SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                     := SQLCODE;
      p_ERROR_MESSAGE              := UT.GET_FULL_ERRM;
 END PUT_IT_SCHEDULE_DATA_PEAK;
--------------------------------------------------------------------------------------------------
  PROCEDURE PUT_FTR_MARKET_RESULTS(p_RECORDS       IN MEX_PJM_FTR_MARKET_RESULTS_TBL,
  								   p_ISO_ACCT_NAME      IN VARCHAR2,
                                   p_BEGIN_DATE    IN DATE,
                                   p_END_DATE      IN DATE,
                                   p_STATUS        OUT NUMBER,
                                   p_ERROR_MESSAGE OUT VARCHAR2) AS

    --Save Auction Results to MM.

    v_PREV_AUCTION_MKT_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SOURCE_NAME      VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SINK_NAME        VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_OPT_OBL          VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_PK_CLASS         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_BUY_SELL         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_TRANSACTION_ID        NUMBER(9);
    --v_COMMODITY_NAME IT_COMMODITY.COMMODITY_NAME%TYPE;
    v_AGREEMENT_TYPE      INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_TRANSACTION_TYPE    INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_COMMODITY_TYPE      IT_COMMODITY.COMMODITY_TYPE%TYPE := 'Transmission';
    v_SET_NUMBER          NUMBER(2);
    v_PK_CLASS            VARCHAR2(16);
    v_AUCTION_DATE        DATE;
    v_AUCTION_END_DATE    DATE;
    v_BID_OFFER_DATE      DATE;
    v_SCHEDULE_DATE       DATE;
    v_INTERVAL_BEGIN_DATE DATE;
    v_INTERVAL_END_DATE   DATE;
    v_BEGIN_DATE          DATE;
    v_END_DATE            DATE;
    v_IS_ON_PEAK          BOOLEAN;
    v_PUT_HOUR            BOOLEAN;
    v_TXN_ROWNUM          NUMBER(3) := 1;
    v_AS_OF_DATE          DATE := LOW_DATE;
    v_SAME_AUCTION        BOOLEAN;
    p_EXCHANGE_ID         NUMBER(9);
    v_CONTRACT_ID		  INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;
	p_AUCTION_TYPE VARCHAR2(8);
    v_INDEX BINARY_INTEGER;

  BEGIN

    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,
                      p_BEGIN_DATE,
                      p_END_DATE,
                      MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                      v_BEGIN_DATE,
                      v_END_DATE);

    IF p_RECORDS.COUNT = 0 THEN
      RETURN;
    END IF;

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP

      --CHECK TO SEE IF EVERYTHING IS THE SAME.
      v_SAME_AUCTION := (v_PREV_AUCTION_MKT_NAME = p_RECORDS(v_INDEX)
                        .AuctionMarketName || p_RECORDS(v_INDEX).PERIOD);

    /*    IF NOT v_SAME_AUCTION THEN
            UPDATE PJM_EFTR_MARKET_INFO
            SET IS_ACTIVE = 0
            WHERE MKT_NAME = p_RECORDS(v_INDEX).AuctionMarketName;
        END IF;     */


     IF INSTR(p_RECORDS(v_INDEX).AuctionMarketName, 'Annual') > 0  THEN
     	p_AUCTION_TYPE := 'Annual';
     ELSE
     	p_AUCTION_TYPE := 'Monthly';
     END IF;

      IF (v_SAME_AUCTION AND
         (p_RECORDS(v_INDEX)
         .SourceName IS NULL OR
          (v_PREV_SOURCE_NAME = p_RECORDS(v_INDEX)
          .SourceName AND v_PREV_SINK_NAME = p_RECORDS(v_INDEX).SinkName)) AND
         v_PREV_OPT_OBL = p_RECORDS(v_INDEX)
         .HedgeType AND v_PREV_PK_CLASS = p_RECORDS(v_INDEX)
         .PeakClass AND v_PREV_BUY_SELL = p_RECORDS(v_INDEX).BuySell) THEN
        v_TXN_ROWNUM := v_TXN_ROWNUM + 1;
      ELSE
        --Different FTR
        v_TXN_ROWNUM := 1;

        --DETERMINE AGREEMENT TYPE
        v_PK_CLASS := p_RECORDS(v_INDEX).PeakClass;

        IF UPPER(SUBSTR(p_RECORDS(v_INDEX).HedgeType, 1, 3)) = 'OPT' THEN
          v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Option';
        ELSE
          v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Obligation';
        END IF;

        --DETERMINE TRANSACTION TYPE
        CASE UPPER(p_RECORDS(v_INDEX).BuySell)
          WHEN 'BUY' THEN
            v_TRANSACTION_TYPE := 'Purchase';
          WHEN 'SELL' THEN
            v_TRANSACTION_TYPE := 'Sale';
          WHEN 'SELFSCHEDULED' THEN
            --cgn treat Self Scheduled as Purchase but add Self Scheduled to
            --agreement type
            v_TRANSACTION_TYPE := 'Purchase';
            v_AGREEMENT_TYPE := v_AGREEMENT_TYPE || 'SelfSched';
          ELSE
            v_TRANSACTION_TYPE := '?';
        END CASE;

        v_PREV_AUCTION_MKT_NAME := p_RECORDS(v_INDEX).AuctionMarketName || p_RECORDS(v_INDEX).PERIOD;
        v_PREV_SOURCE_NAME      := p_RECORDS(v_INDEX).SourceName;
        v_PREV_SINK_NAME        := p_RECORDS(v_INDEX).SinkName;
        v_PREV_OPT_OBL          := p_RECORDS(v_INDEX).HedgeType;
        v_PREV_PK_CLASS         := p_RECORDS(v_INDEX).PeakClass;
        v_PREV_BUY_SELL         := p_RECORDS(v_INDEX).BuySell;

        SELECT MKT_INT_START, MKT_INT_END
        INTO v_AUCTION_DATE, v_AUCTION_END_DATE
        FROM PJM_EFTR_MARKET_INFO
        WHERE UPPER(MKT_NAME) = UPPER(p_RECORDS(v_INDEX).AuctionMarketName)
        AND MKT_PERIOD = p_RECORDS(v_INDEX).PERIOD
        AND ROWNUM = 1;

        IF p_ERROR_MESSAGE IS NOT NULL THEN
          p_STATUS := -1;
          ROLLBACK;
          RETURN;
        END IF;
        UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                  v_AUCTION_DATE,
                                  v_AUCTION_END_DATE,
                                  MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                                  60,
                                  v_INTERVAL_BEGIN_DATE,
                                  v_INTERVAL_END_DATE);
        --v_BID_OFFER_DATE should be 1 sec after midnite FOR BID_OFFER_SET
        v_BID_OFFER_DATE := v_AUCTION_DATE + g_SECOND;

      END IF;

      --use contract's external identifier instead of the entity's alias
	  v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCT_NAME);

      --GET THE TRANSACTION ID; CREATE TXN IF IT DOES NOT EXIST.
      v_TRANSACTION_ID := GET_FTR_TRANSACTION_ID(v_AUCTION_DATE,
                                                 v_AUCTION_END_DATE,
                                                 v_TRANSACTION_TYPE,
                                                 v_CONTRACT_ID,
                                                 NULL,
                                                 p_RECORDS(v_INDEX)
                                                 .SourceName,
                                                 p_RECORDS(v_INDEX).SinkName,
                                                 v_COMMODITY_TYPE,
                                                 v_AGREEMENT_TYPE,
                                                 v_PK_CLASS,
                                                 v_TXN_ROWNUM,
                                                 TRUE,
                                                 p_ERROR_MESSAGE,
                                                 p_RECORDS(v_INDEX).ClearedAmount,
                                                 p_AUCTION_TYPE,
                                                 p_RECORDS(v_INDEX).AuctionMarketName);
	 COMMIT;
      IF v_TRANSACTION_ID < 0 OR p_ERROR_MESSAGE IS NOT NULL THEN
        IF p_ERROR_MESSAGE IS NULL THEN

          p_ERROR_MESSAGE := 'Could not get TRANSACTION ID for ' ||
                             p_RECORDS(v_INDEX)
                            .AuctionMarketName || ', ' || v_AGREEMENT_TYPE;
        END IF;
        p_STATUS := -1;
        ROLLBACK;
        RETURN;
      END IF;


	IF v_TRANSACTION_TYPE = 'Sale' AND p_RECORDS(v_INDEX).ClearedAmount > 0 THEN
		ADD_FTR_SALE_TO_SCHEDULE(v_AUCTION_DATE,
        							v_INTERVAL_BEGIN_DATE,
                                    v_INTERVAL_END_DATE,
                                    GA.INTERNAL_STATE,
                                    v_TRANSACTION_TYPE,
                                    v_CONTRACT_ID,
                                    v_PK_CLASS,
                                    REPLACE(p_RECORDS(v_INDEX).SourceName,' ', ''),
                                    REPLACE(p_RECORDS(v_INDEX).SinkName,' ', ''),
                                    v_COMMODITY_TYPE,
                                    v_AGREEMENT_TYPE,
                                    p_RECORDS(v_INDEX).ClearedAmount,
                                    v_TXN_ROWNUM,
                                    p_ERROR_MESSAGE,
                                    p_STATUS,
                                    p_RECORDS(v_INDEX).AuctionMarketName,
                                    p_RECORDS(v_INDEX).AuctionRound);
    ELSIF v_TRANSACTION_TYPE = 'Purchase' THEN
     /* --GET THE TRANSACTION ID; CREATE TXN IF IT DOES NOT EXIST.
      v_TRANSACTION_ID := GET_FTR_TRANSACTION_ID(v_AUCTION_DATE,
                                                 v_AUCTION_END_DATE,
                                                 v_TRANSACTION_TYPE,
                                                 v_CONTRACT_ID,
                                                 NULL,
                                                 p_RECORDS(v_INDEX)
                                                 .SourceName,
                                                 p_RECORDS(v_INDEX).SinkName,
                                                 v_COMMODITY_TYPE,
                                                 v_AGREEMENT_TYPE,
                                                 v_PK_CLASS,
                                                 v_TXN_ROWNUM,
                                                 TRUE,
                                                 p_ERROR_MESSAGE,
                                                 p_RECORDS(v_INDEX).ClearedAmount,
                                                 p_AUCTION_TYPE,
                                                 v_PREV_AUCTION_MKT_NAME);

      IF v_TRANSACTION_ID < 0 OR p_ERROR_MESSAGE IS NOT NULL THEN
        IF p_ERROR_MESSAGE IS NULL THEN

          p_ERROR_MESSAGE := 'Could not get TRANSACTION ID for ' ||
                             p_RECORDS(v_INDEX)
                            .AuctionMarketName || ', ' || v_AGREEMENT_TYPE;
        END IF;
        p_STATUS := -1;
        ROLLBACK;
        RETURN;
      END IF;*/

  /*
    	IF p_RECORDS(v_INDEX).ClearedAmount <= 0 THEN
            --JUST LOG THE FAILED BID.
			MEX_UTIL.PUT_EXCHANGE_LOG('PJM',
                                      'In',
                                      'QueryMarketResults',
                                      'Information',
                                      'Cleared MW=0 :' || p_RECORDS(v_INDEX)
                                      .AuctionMarketName || ', ' ||
                                       p_RECORDS(v_INDEX)
                                      .SourceName || ', ' || p_RECORDS(v_INDEX)
                                      .SinkName || ', ' || p_RECORDS(v_INDEX)
                                      .PeakClass || ', ' || p_RECORDS(v_INDEX)
                                      .BidAmount || ', ' || p_RECORDS(v_INDEX)
                                      .BidPrice,
                                      '',
                                      0,
                                      p_EXCHANGE_ID);*/


        --cgn: put the mw hours into IT_SCHEDULE, even if
        -- the cleared mw's is 0, because we count these hours
        -- for the FTR Admin Charge
        --SAVE THE CLEARED AMOUNT AND PRICE FOR THE PERIOD.

        IF UPPER(v_PK_CLASS) = '24H' THEN
        	FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
            	PUT_IT_SCHEDULE_DATA_24H(v_TRANSACTION_ID,
                                     v_INTERVAL_BEGIN_DATE,
                                     v_INTERVAL_END_DATE,
                                     GA.INTERNAL_STATE,
                                     I,
                                     p_RECORDS(v_INDEX).ClearedPrice,
                                     p_RECORDS(v_INDEX).ClearedAmount,
                                     p_STATUS,
                                     p_ERROR_MESSAGE);
         	END LOOP;
        ELSE

        		FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
            	PUT_IT_SCHEDULE_DATA_PEAK(v_TRANSACTION_ID,
                                     v_INTERVAL_BEGIN_DATE,
                                     v_INTERVAL_END_DATE,
                                     GA.INTERNAL_STATE,
                                     I,
                                     p_RECORDS(v_INDEX).ClearedPrice,
                                     p_RECORDS(v_INDEX).ClearedAmount,
                                     v_PK_CLASS,
                                     p_STATUS,
                                     p_ERROR_MESSAGE);
         	END LOOP;
      END IF;

      --SAVE THE BID CURVE AS EXTERNAL.
      v_SET_NUMBER               := 1;
      SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

      BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID,
                           0,
                           GA.EXTERNAL_STATE,
                           v_BID_OFFER_DATE,
                           v_SET_NUMBER,
                           p_RECORDS(v_INDEX).BidPrice,
                           p_RECORDS(v_INDEX).BidAmount,
                           'P',
                           MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                           p_STATUS);
    END IF;
      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

      v_SET_NUMBER := v_SET_NUMBER + 1;

        COMMIT;
        v_INDEX := p_RECORDS.NEXT(v_INDEX);
	END LOOP;


    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                   := SQLCODE;
      p_ERROR_MESSAGE            := 'ERROR OCCURED IN PUT_FTR_MARKET_RESULTS ' ||
                                    UT.GET_FULL_ERRM;
      ROLLBACK;

  END PUT_FTR_MARKET_RESULTS;
------------------------------------------------------------------------------------
PROCEDURE PUT_ARR_MARKET_RESULTS(p_RECORDS       IN MEX_PJM_FTR_INITIAL_ARR_TBL,
  								   p_ISO_ACCT_NAME      IN VARCHAR2,
                                   p_BEGIN_DATE    IN DATE,
                                   p_END_DATE      IN DATE,
                                   p_STATUS        OUT NUMBER,
                                   p_ERROR_MESSAGE OUT VARCHAR2) AS

    --Save Auction Results to MM.

    v_PREV_AUCTION_MKT_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SOURCE_NAME      VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SINK_NAME        VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_OPT_OBL          VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_PK_CLASS         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_BUY_SELL         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
v_TRANSACTION_ID        NUMBER(9);
    v_AGREEMENT_TYPE      INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_TRANSACTION_TYPE    INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_COMMODITY_TYPE      IT_COMMODITY.COMMODITY_TYPE%TYPE := 'Transmission';
    v_SET_NUMBER          NUMBER(2);
    v_PK_CLASS            VARCHAR2(16);
    v_AUCTION_DATE        DATE;
    v_AUCTION_END_DATE    DATE;
    v_BID_OFFER_DATE      DATE;
    v_SCHEDULE_DATE       DATE;
    v_INTERVAL_BEGIN_DATE DATE;
    v_INTERVAL_END_DATE   DATE;
    v_BEGIN_DATE          DATE;
    v_END_DATE            DATE;
    v_IS_ON_PEAK          BOOLEAN;
    v_PUT_HOUR            BOOLEAN;
    v_TXN_ROWNUM          NUMBER(3) := 1;
    v_AS_OF_DATE          DATE := LOW_DATE;
    v_SAME_AUCTION        BOOLEAN;
    p_EXCHANGE_ID         NUMBER(9);
    v_CONTRACT_ID		  INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;
	p_AUCTION_TYPE VARCHAR2(8);
    v_INDEX BINARY_INTEGER;

  BEGIN

    UT.CUT_DATE_RANGE(GA.ELECTRIC_MODEL,
                      p_BEGIN_DATE,
                      p_END_DATE,
                      MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                      v_BEGIN_DATE,
                      v_END_DATE);

    IF p_RECORDS.COUNT = 0 THEN
      RETURN;
    END IF;

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP

      --CHECK TO SEE IF EVERYTHING IS THE SAME.



      IF (v_PREV_SOURCE_NAME = p_RECORDS(v_INDEX).SourceName AND
      v_PREV_SINK_NAME = p_RECORDS(v_INDEX).SinkName) THEN
        v_TXN_ROWNUM := v_TXN_ROWNUM + 1;
      ELSE
        --Different FTR
        v_TXN_ROWNUM := 1;

        v_AGREEMENT_TYPE := 'ARR';

        v_PREV_SOURCE_NAME      := p_RECORDS(v_INDEX).SourceName;
        v_PREV_SINK_NAME        := p_RECORDS(v_INDEX).SinkName;


      /*  SELECT MKT_INT_START, MKT_INT_END
        INTO v_AUCTION_DATE, v_AUCTION_END_DATE
        FROM PJM_EFTR_MARKET_INFO
        WHERE UPPER(MKT_NAME) = UPPER(p_RECORDS(v_INDEX).AuctionMarketName)
        AND MKT_PERIOD = p_RECORDS(v_INDEX).PERIOD
        AND ROWNUM = 1;*/

        IF p_ERROR_MESSAGE IS NOT NULL THEN
          p_STATUS := -1;
          ROLLBACK;
          RETURN;
        END IF;
        UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                  v_AUCTION_DATE,
                                  v_AUCTION_END_DATE,
                                  MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                                  60,
                                  v_INTERVAL_BEGIN_DATE,
                                  v_INTERVAL_END_DATE);
        --v_BID_OFFER_DATE should be 1 sec after midnite FOR BID_OFFER_SET
        v_BID_OFFER_DATE := v_AUCTION_DATE + g_SECOND;

      END IF;

      --use contract's external identifier instead of the entity's alias
	  v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCT_NAME);

      --GET THE TRANSACTION ID; CREATE TXN IF IT DOES NOT EXIST.
      v_TRANSACTION_ID := GET_FTR_TRANSACTION_ID('01-JUN-2006',
                                                 '31-MAY-2007',
                                                 'Purchase',
                                                 v_CONTRACT_ID,
                                                 NULL,
                                                 p_RECORDS(v_INDEX)
                                                 .SourceName,
                                                 p_RECORDS(v_INDEX).SinkName,
                                                 v_COMMODITY_TYPE,
                                                 v_AGREEMENT_TYPE,
                                                 '24H',
                                                 v_TXN_ROWNUM,
                                                 TRUE,
                                                 p_ERROR_MESSAGE,
                                                 p_RECORDS(v_INDEX).ClearedAmount,
                                                 'Annual',
                                                'ARR');
	 COMMIT;
      IF v_TRANSACTION_ID < 0 OR p_ERROR_MESSAGE IS NOT NULL THEN
        IF p_ERROR_MESSAGE IS NULL THEN

          p_ERROR_MESSAGE := 'Could not get TRANSACTION ID for ' ||
                             p_RECORDS(v_INDEX)
                            .AuctionMarketName || ', ' || v_AGREEMENT_TYPE;
        END IF;
        p_STATUS := -1;
        ROLLBACK;
        RETURN;
      END IF;


/*	IF v_TRANSACTION_TYPE = 'Sale' AND p_RECORDS(v_INDEX).ClearedAmount > 0 THEN
		ADD_FTR_SALE_TO_SCHEDULE(v_AUCTION_DATE,
        							v_INTERVAL_BEGIN_DATE,
                                    v_INTERVAL_END_DATE,
                                    GA.INTERNAL_STATE,
                                    v_TRANSACTION_TYPE,
                                    v_CONTRACT_ID,
                                    v_PK_CLASS,
                                    REPLACE(p_RECORDS(v_INDEX).SourceName,' ', ''),
                                    REPLACE(p_RECORDS(v_INDEX).SinkName,' ', ''),
                                    v_COMMODITY_TYPE,
                                    v_AGREEMENT_TYPE,
                                    p_RECORDS(v_INDEX).ClearedAmount,
                                    v_TXN_ROWNUM,
                                    p_ERROR_MESSAGE,
                                    p_STATUS,
                                    p_RECORDS(v_INDEX).AuctionMarketName,
                                    p_RECORDS(v_INDEX).AuctionRound);
    ELSIF v_TRANSACTION_TYPE = 'Purchase' THEN
      --GET THE TRANSACTION ID; CREATE TXN IF IT DOES NOT EXIST.
      v_TRANSACTION_ID := GET_FTR_TRANSACTION_ID(v_AUCTION_DATE,
                                                 v_AUCTION_END_DATE,
                                                 v_TRANSACTION_TYPE,
                                                 v_CONTRACT_ID,
                                                 NULL,
                                                 p_RECORDS(v_INDEX)
                                                 .SourceName,
                                                 p_RECORDS(v_INDEX).SinkName,
                                                 v_COMMODITY_TYPE,
                                                 v_AGREEMENT_TYPE,
                                                 v_PK_CLASS,
                                                 v_TXN_ROWNUM,
                                                 TRUE,
                                                 p_ERROR_MESSAGE,
                                                 p_RECORDS(v_INDEX).ClearedAmount,
                                                 p_AUCTION_TYPE,
                                                 v_PREV_AUCTION_MKT_NAME);

      IF v_TRANSACTION_ID < 0 OR p_ERROR_MESSAGE IS NOT NULL THEN
        IF p_ERROR_MESSAGE IS NULL THEN

          p_ERROR_MESSAGE := 'Could not get TRANSACTION ID for ' ||
                             p_RECORDS(v_INDEX)
                            .AuctionMarketName || ', ' || v_AGREEMENT_TYPE;
        END IF;
        p_STATUS := -1;
        ROLLBACK;
        RETURN;
      END IF;


    	IF p_RECORDS(v_INDEX).ClearedAmount <= 0 THEN
            --JUST LOG THE FAILED BID.
			MEX_UTIL.PUT_EXCHANGE_LOG('PJM',
                                      'In',
                                      'QueryMarketResults',
                                      'Information',
                                      'Cleared MW=0 :' || p_RECORDS(v_INDEX)
                                      .AuctionMarketName || ', ' ||
                                       p_RECORDS(v_INDEX)
                                      .SourceName || ', ' || p_RECORDS(v_INDEX)
                                      .SinkName || ', ' || p_RECORDS(v_INDEX)
                                      .PeakClass || ', ' || p_RECORDS(v_INDEX)
                                      .BidAmount || ', ' || p_RECORDS(v_INDEX)
                                      .BidPrice,
                                      '',
                                      0,
                                      p_EXCHANGE_ID);


        --cgn: put the mw hours into IT_SCHEDULE, even if
        -- the cleared mw's is 0, because we count these hours
        -- for the FTR Admin Charge
        --SAVE THE CLEARED AMOUNT AND PRICE FOR THE PERIOD.

        IF UPPER(v_PK_CLASS) = '24H' THEN
        	FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
            	PUT_IT_SCHEDULE_DATA_24H(v_TRANSACTION_ID,
                                     v_INTERVAL_BEGIN_DATE,
                                     v_INTERVAL_END_DATE,
                                     GA.INTERNAL_STATE,
                                     I,
                                     p_RECORDS(v_INDEX).ClearedPrice,
                                     p_RECORDS(v_INDEX).ClearedAmount,
                                     p_STATUS,
                                     p_ERROR_MESSAGE);
         	END LOOP;
        ELSE

        		FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
            	PUT_IT_SCHEDULE_DATA_PEAK(v_TRANSACTION_ID,
                                     v_INTERVAL_BEGIN_DATE,
                                     v_INTERVAL_END_DATE,
                                     GA.INTERNAL_STATE,
                                     I,
                                     p_RECORDS(v_INDEX).ClearedPrice,
                                     p_RECORDS(v_INDEX).ClearedAmount,
                                     v_PK_CLASS,
                                     p_STATUS,
                                     p_ERROR_MESSAGE);
         	END LOOP;
      END IF;

      --SAVE THE BID CURVE AS EXTERNAL.
      v_SET_NUMBER               := 1;
	  SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
      BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID,
                           0,
                           GA.EXTERNAL_STATE,
                           v_BID_OFFER_DATE,
                           v_SET_NUMBER,
                           p_RECORDS(v_INDEX).BidPrice,
                           p_RECORDS(v_INDEX).BidAmount,
                           'P',
                           g_PJM_EFTR_TIMEZONE,
                           p_STATUS);
    END IF;*/
      --SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

      --v_SET_NUMBER := v_SET_NUMBER + 1;

        COMMIT;
        v_INDEX := p_RECORDS.NEXT(v_INDEX);
	END LOOP;


    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                   := SQLCODE;
      p_ERROR_MESSAGE            := 'ERROR OCCURED IN PUT_ARR_MARKET_RESULTS ' ||
                                    UT.GET_FULL_ERRM;
      ROLLBACK;

END PUT_ARR_MARKET_RESULTS;
------------------------------------------------------------------------------------
PROCEDURE PUT_FTR_POSITION
    (
    p_RECORDS IN MEX_PJM_FTR_POSITION_TBL,
    p_ISO_ACCT_NAME IN VARCHAR2,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

v_TRANSACTION_ID INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
v_CONTRACT_ID INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;
v_AGREEMENT_TYPE INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
v_COMMODITY_TYPE IT_COMMODITY.COMMODITY_TYPE%TYPE := 'Transmission';
v_CLASS VARCHAR2(16);
v_AUCTION_TYPE VARCHAR2(16);
v_TRANSACTION_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
v_PREV_AUCTION_MKT_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
v_PREV_SOURCE_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
v_PREV_SINK_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
v_PREV_OPT_OBL VARCHAR2(64) := g_INIT_VAL_VARCHAR;
v_PREV_PK_CLASS VARCHAR2(64) := g_INIT_VAL_VARCHAR;
v_PREV_BUY_SELL VARCHAR2(64) := g_INIT_VAL_VARCHAR;
v_TXN_ROWNUM NUMBER(3) := 1;
v_SAME_AUCTION BOOLEAN;
v_AUCTION_DATE DATE;
v_AUCTION_END_DATE DATE;
v_INTERVAL_BEGIN_DATE DATE;
v_INTERVAL_END_DATE DATE;
v_YEAR VARCHAR2(4);
v_INDEX BINARY_INTEGER;
v_MONTH VARCHAR2(2);
v_MON BINARY_INTEGER;
v_YR BINARY_INTEGER;
BEGIN
    p_STATUS := GA.SUCCESS;

    IF p_RECORDS.COUNT = 0 THEN
        RETURN;
    END IF;

    v_INDEX := p_RECORDS.FIRST;
    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP

        --check if everything is the same
        v_SAME_AUCTION := (v_PREV_AUCTION_MKT_NAME = p_RECORDS(v_INDEX)
                        .MKT_NAME || p_RECORDS(v_INDEX).PERIOD);
        --use contract's external identifier instead of the entity's alias
		v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCT_NAME);

        v_MONTH := TO_CHAR(p_RECORDS(v_INDEX).POSITION_DATE, 'MM');
        v_YEAR :=  TO_CHAR(p_RECORDS(v_INDEX).POSITION_DATE, 'YYYY');
        v_MON := TO_NUMBER(v_MONTH);
        v_YR := TO_NUMBER(v_YEAR);

        IF v_MON BETWEEN 1 AND 5 THEN
        	v_YR := v_YR - 1;
        END IF;

        v_AUCTION_DATE := TO_DATE('01-JUN-' || v_YR, 'DD-MON-YYYY');
        v_AUCTION_END_DATE := TO_DATE('31-MAY-' || TO_CHAR(TO_NUMBER(v_YR) + 1), 'DD-MON-YYYY');

        UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL, p_RECORDS(v_INDEX).POSITION_DATE,
                                    p_RECORDS(v_INDEX).POSITION_DATE, MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                                    60, v_INTERVAL_BEGIN_DATE, v_INTERVAL_END_DATE);

        IF (v_SAME_AUCTION AND (v_PREV_SOURCE_NAME = p_RECORDS(v_INDEX)
          .SOURCE_NAME AND v_PREV_SINK_NAME = p_RECORDS(v_INDEX).SINK_NAME) AND
         v_PREV_OPT_OBL = p_RECORDS(v_INDEX).HEDGE_TYPE AND
         v_PREV_PK_CLASS = p_RECORDS(v_INDEX).CLASS AND
         v_PREV_BUY_SELL = p_RECORDS(v_INDEX).BUY_SELL) THEN
            v_TXN_ROWNUM := v_TXN_ROWNUM + 1;
        ELSE
            --Different FTR
            v_TXN_ROWNUM := 1;
            v_CLASS := p_RECORDS(v_INDEX).CLASS;

            IF UPPER(SUBSTR(p_RECORDS(v_INDEX).HEDGE_TYPE, 1, 3)) = 'OPT' THEN
                v_AGREEMENT_TYPE := 'FTR ' || v_CLASS || ' Option';
            ELSE
                v_AGREEMENT_TYPE := 'FTR ' || v_CLASS || ' Obligation';
            END IF;

            --DETERMINE TRANSACTION TYPE
            CASE UPPER(p_RECORDS(v_INDEX).BUY_SELL)
            WHEN 'BUY' THEN
                v_TRANSACTION_TYPE := 'Purchase';
            WHEN 'SELL' THEN
                v_TRANSACTION_TYPE := 'Sale';
            WHEN 'SELFSCHEDULED' THEN
            --cgn treat Self Scheduled as Purchase but add Self Scheduled to
            --agreement type
                v_TRANSACTION_TYPE := 'Purchase';
                v_AGREEMENT_TYPE := v_AGREEMENT_TYPE || 'SelfSched';
            ELSE
                v_TRANSACTION_TYPE := '?';
            END CASE;

            IF p_RECORDS(v_INDEX).MKT_NAME = 'Bilateral Market' THEN
                v_AUCTION_TYPE := 'Secondary Market';
                IF v_TRANSACTION_TYPE = 'Purchase' THEN
                    v_AGREEMENT_TYPE := v_AGREEMENT_TYPE || 'SelfSched';
                END IF;
            ELSIF INSTR(p_RECORDS(v_INDEX).MKT_NAME, 'Annual') > 0  THEN
     	        v_AUCTION_TYPE := 'Annual';
            ELSE
     	        v_AUCTION_TYPE := 'Monthly';
            END IF;

            v_PREV_AUCTION_MKT_NAME := p_RECORDS(v_INDEX).MKT_NAME || p_RECORDS(v_INDEX).PERIOD;
            v_PREV_SOURCE_NAME      := p_RECORDS(v_INDEX).SOURCE_NAME;
            v_PREV_SINK_NAME        := p_RECORDS(v_INDEX).SINK_NAME;
            v_PREV_OPT_OBL          := p_RECORDS(v_INDEX).HEDGE_TYPE;
            v_PREV_PK_CLASS         := p_RECORDS(v_INDEX).CLASS;
            v_PREV_BUY_SELL         := p_RECORDS(v_INDEX).BUY_SELL;

        END IF;

        v_TRANSACTION_ID := GET_FTR_TXN_ID_POSITION(v_AUCTION_DATE,
                                            v_AUCTION_END_DATE,
                                            v_INTERVAL_BEGIN_DATE,
                                            v_TRANSACTION_TYPE,
                                            v_CONTRACT_ID,
                                            NULL,
                                            p_RECORDS(v_INDEX).SOURCE_NAME,
                                            p_RECORDS(v_INDEX).SINK_NAME,
                                            v_COMMODITY_TYPE,
                                            v_AGREEMENT_TYPE,
                                            v_CLASS,
                                            v_TXN_ROWNUM,
                                            TRUE,
                                            p_MESSAGE,
                                            p_RECORDS(v_INDEX).MW_AMOUNT,
                                            p_RECORDS(v_INDEX).PRICE,
                                            v_AUCTION_TYPE,
                                            p_RECORDS(v_INDEX).MKT_NAME);
        COMMIT;

        IF v_TRANSACTION_TYPE = 'Sale' AND p_RECORDS(v_INDEX).MW_AMOUNT > 0 THEN
		    ADD_FTR_BILAT_SALE_TO_SCHED(v_AUCTION_DATE,
        							v_INTERVAL_BEGIN_DATE,
                                    v_INTERVAL_END_DATE,
                                    GA.INTERNAL_STATE,
                                    v_TRANSACTION_TYPE,
                                    v_CONTRACT_ID,
                                    v_CLASS,
                                    REPLACE(p_RECORDS(v_INDEX).SOURCE_NAME,' ', ''),
                                    REPLACE(p_RECORDS(v_INDEX).SINK_NAME,' ', ''),
                                    v_COMMODITY_TYPE,
                                    v_AGREEMENT_TYPE,
                                    p_RECORDS(v_INDEX).MW_AMOUNT,
                                    v_TRANSACTION_ID,
                                    v_TXN_ROWNUM,
                                    p_MESSAGE,
                                    p_STATUS,
                                    p_RECORDS(v_INDEX).MKT_NAME);

        ELSIF v_TRANSACTION_TYPE = 'Purchase' THEN
            IF UPPER(v_CLASS) = '24H' THEN
        	    FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
            	    PUT_IT_SCHEDULE_DATA_24H(v_TRANSACTION_ID,
                                     v_INTERVAL_BEGIN_DATE,
                                     v_INTERVAL_END_DATE,
                                     GA.INTERNAL_STATE,
                                     I,
                                     p_RECORDS(v_INDEX).PRICE,
                                     p_RECORDS(v_INDEX).MW_AMOUNT,
                                     p_STATUS,
                                     p_MESSAGE);
         	    END LOOP;
            ELSE

        		FOR I IN 1 .. MM_PJM_UTIL.g_STATEMENT_TYPE_ID_ARRAY.COUNT LOOP
            	    PUT_IT_SCHEDULE_DATA_PEAK(v_TRANSACTION_ID,
                                     v_INTERVAL_BEGIN_DATE,
                                     v_INTERVAL_END_DATE,
                                     GA.INTERNAL_STATE,
                                     I,
                                     p_RECORDS(v_INDEX).PRICE,
                                     p_RECORDS(v_INDEX).MW_AMOUNT,
                                     v_CLASS,
                                     p_STATUS,
                                     p_MESSAGE);
         	    END LOOP;
            END IF;
        END IF;
      v_INDEX := p_RECORDS.NEXT(v_INDEX);
    END LOOP;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'ERROR OCCURED IN PUT_FTR_POSITION ' || UT.GET_FULL_ERRM;

END PUT_FTR_POSITION;
---------------------------------------------------------------------------------------
  PROCEDURE PUT_INITIAL_ARR(p_COPY_INTERNAL IN BOOLEAN,
  							p_ISO_ACCT_NAME      IN VARCHAR2,
                            p_RECORDS       IN MEX_PJM_FTR_INITIAL_ARR_TBL,
                            p_LOGGER        IN OUT MM_LOGGER_ADAPTER,
                            p_STATUS        OUT NUMBER,
                            p_ERROR_MESSAGE OUT VARCHAR2) AS

    --Save Auction Results to MM.

    v_PREV_AUCTION_MKT_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SOURCE_NAME      VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SINK_NAME        VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_OPT_OBL          VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_PK_CLASS         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_BUY_SELL         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_TRANSACTION_ID        NUMBER(9);
    --v_COMMODITY_NAME IT_COMMODITY.COMMODITY_NAME%TYPE;
    v_AGREEMENT_TYPE      INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_TRANSACTION_TYPE    INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_COMMODITY_TYPE      IT_COMMODITY.COMMODITY_TYPE%TYPE := 'Transmission';
    v_SET_NUMBER          NUMBER(2);
    v_PK_CLASS            VARCHAR2(16);
    v_AUCTION_DATE        DATE;
    v_AUCTION_END_DATE    DATE;
    v_IS_ANNUAL           BOOLEAN;
    v_BID_OFFER_DATE      DATE;
    v_SCHEDULE_DATE       DATE;
    v_INTERVAL_BEGIN_DATE DATE;
    v_INTERVAL_END_DATE   DATE;
    v_IS_ON_PEAK          BOOLEAN;
    v_PUT_HOUR            BOOLEAN;
    v_TXN_ROWNUM          NUMBER(3) := 1;
    v_AS_OF_DATE          DATE := LOW_DATE;
    v_SAME_AUCTION        BOOLEAN;
    p_EXCHANGE_ID         NUMBER(9);
	v_CONTRACT_ID	INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;
    v_INDEX BINARY_INTEGER;

  BEGIN

	--use contract's external identifier instead of the entity's alias
	v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCT_NAME);

    IF p_RECORDS.COUNT = 0 THEN
      RETURN;
    END IF;

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP

      --CHECK TO SEE IF EVERYTHING IS THE SAME.
      v_SAME_AUCTION := (v_PREV_AUCTION_MKT_NAME = p_RECORDS(v_INDEX)
                        .AuctionMarketName);
      IF (v_SAME_AUCTION AND
         (p_RECORDS(v_INDEX)
         .SourceName IS NULL OR
          (v_PREV_SOURCE_NAME = p_RECORDS(v_INDEX)
          .SourceName AND v_PREV_SINK_NAME = p_RECORDS(v_INDEX).SinkName)))
      THEN
        v_TXN_ROWNUM := v_TXN_ROWNUM + 1;
      ELSE
        --Different FTR
        v_TXN_ROWNUM := 1;

        --DETERMINE AGREEMENT TYPE
        --v_PK_CLASS := p_RECORDS(v_INDEX).PeakClass;

        --IF UPPER(SUBSTR(p_RECORDS(v_INDEX).HedgeType, 1, 3)) = 'OPT' THEN
        --  v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Option';
       -- ELSE
        --  v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Obligation';
      --  END IF;

        --DETERMINE TRANSACTION TYPE
        --CASE UPPER(p_RECORDS(v_INDEX).BuySell)
          --WHEN 'BUY' THEN
        --    v_TRANSACTION_TYPE := 'Purchase';
        --  WHEN 'SELL' THEN
        --    v_TRANSACTION_TYPE := 'Sale';
       --   ELSE
       --     v_TRANSACTION_TYPE := 'SelfScheduled';
      --  END CASE;

        v_PREV_AUCTION_MKT_NAME := p_RECORDS(v_INDEX).AuctionMarketName;
        v_PREV_SOURCE_NAME      := p_RECORDS(v_INDEX).SourceName;
        v_PREV_SINK_NAME        := p_RECORDS(v_INDEX).SinkName;
        --v_PREV_OPT_OBL          := p_RECORDS(v_INDEX).HedgeType;
        --v_PREV_PK_CLASS         := p_RECORDS(v_INDEX).PeakClass;
        --v_PREV_BUY_SELL         := p_RECORDS(v_INDEX).BuySell;

        SELECT MKT_INT_START, MKT_INT_END
        INTO v_AUCTION_DATE, v_AUCTION_END_DATE
        FROM PJM_EFTR_MARKET_INFO
        WHERE UPPER(MKT_NAME) = UPPER(p_RECORDS(v_INDEX).AuctionMarketName)
        AND ROWNUM = 1;

        /*MEX_PJM_EFTR.GET_AUCTION_MARKET_DATES(p_RECORDS(v_INDEX)
                                              .AuctionMarketName,
                                              v_AUCTION_DATE,
                                              v_AUCTION_END_DATE,
                                              v_IS_ANNUAL,
                                              p_STATUS,
                                              p_ERROR_MESSAGE);*/
        IF p_ERROR_MESSAGE IS NOT NULL THEN
          p_STATUS := -1;
          ROLLBACK;
          RETURN;
        END IF;
        UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                  v_AUCTION_DATE,
                                  v_AUCTION_END_DATE,
                                  MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                                  60,
                                  v_INTERVAL_BEGIN_DATE,
                                  v_INTERVAL_END_DATE);
        --v_BID_OFFER_DATE should be 1 sec after midnite FOR BID_OFFER_SET
        v_BID_OFFER_DATE := v_AUCTION_DATE + g_SECOND;

      END IF;

      --GET THE TRANSACTION ID; CREATE TXN IF IT DOES NOT EXIST.
      v_TRANSACTION_ID := GET_FTR_TRANSACTION_ID(v_AUCTION_DATE,
                                                 v_AUCTION_END_DATE,
                                                 v_TRANSACTION_TYPE,
                                                 v_CONTRACT_ID,
                                                 NULL,
                                                 p_RECORDS(v_INDEX)
                                                 .SourceName,
                                                 p_RECORDS(v_INDEX).SinkName,
                                                 v_COMMODITY_TYPE,
                                                 v_AGREEMENT_TYPE,
                                                 v_PK_CLASS,
                                                 v_TXN_ROWNUM,
                                                 TRUE,
                                                 p_ERROR_MESSAGE,
                                                 0,
                                                 NULL,
                                                 v_PREV_AUCTION_MKT_NAME);
      IF v_TRANSACTION_ID < 0 OR p_ERROR_MESSAGE IS NOT NULL THEN
        IF p_ERROR_MESSAGE IS NULL THEN

          p_ERROR_MESSAGE := 'Could not get TRANSACTION ID for ' ||
                             p_RECORDS(v_INDEX)
                            .AuctionMarketName || ', ' || v_AGREEMENT_TYPE;
        END IF;
        p_STATUS := -1;
        ROLLBACK;
        RETURN;
      END IF;

      /*IF NOT v_SAME_AUCTION THEN
        --WIPE OUT IT_SCHEDULE FTR DATA FOR THE DATE RANGE.
        DELETE IT_SCHEDULE
         WHERE TRANSACTION_ID IN
               (SELECT A.TRANSACTION_ID
                  FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
                 WHERE B.COMMODITY_TYPE = v_COMMODITY_TYPE
                   AND A.COMMODITY_ID = B.COMMODITY_ID
                   AND A.TRANSACTION_TYPE IN
                       ('Purchase', 'Sale', 'SelfScheduled')
                   AND UPPER(SUBSTR(A.AGREEMENT_TYPE, 1, 3)) = 'FTR')
           AND SCHEDULE_STATE = GA.INTERNAL_STATE
           AND SCHEDULE_DATE BETWEEN v_AUCTION_DATE AND v_AUCTION_END_DATE
           AND AS_OF_DATE = v_AS_OF_DATE;
      END IF;*/

		IF p_RECORDS(v_INDEX).ClearedAmount <= 0 THEN
			--JUST LOG THE FAILED BID.
			p_LOGGER.LOG_WARN('Cleared MW=0 :' || p_RECORDS(v_INDEX).AuctionMarketName || ', ' ||
				p_RECORDS(v_INDEX).SourceName || ', ' || p_RECORDS(v_INDEX).SinkName || ', ' ||
				p_RECORDS(v_INDEX).BidAmount);

		ELSE
        --MW > 0,  process the result
        --SAVE THE CLEARED AMOUNT AND PRICE FOR THE PERIOD.
        v_SCHEDULE_DATE := v_INTERVAL_BEGIN_DATE;
  --we don't know the peak class

        WHILE v_SCHEDULE_DATE <= v_INTERVAL_END_DATE LOOP
          v_PUT_HOUR := FALSE;
          CASE UPPER(v_PK_CLASS)
            WHEN '24H' THEN
              v_PUT_HOUR := TRUE;
            WHEN 'ONPEAK' THEN
              v_PUT_HOUR := IS_ON_PEAK_HOUR(v_SCHEDULE_DATE, 0);
            WHEN 'OFFPEAK' THEN
              v_PUT_HOUR := NOT IS_ON_PEAK_HOUR(v_SCHEDULE_DATE, 0);
            ELSE
              NULL;
          END CASE;
          IF v_PUT_HOUR THEN
            FOR v_STATEMENT_TYPE IN 1..3 LOOP
              PUT_IT_SCHEDULE_DATA(v_TRANSACTION_ID,
                                 v_SCHEDULE_DATE,
                                 GA.INTERNAL_STATE,
                                 v_STATEMENT_TYPE,
                                 p_RECORDS(v_INDEX).ClearedAmount,
                                 NULL,
                                 p_STATUS,
                                 p_ERROR_MESSAGE);
            END LOOP;
          END IF;
          v_SCHEDULE_DATE := v_SCHEDULE_DATE + 1 / 24;

        END LOOP;

      END IF; --MW > 0

      --SAVE THE BID CURVE AS EXTERNAL.
      v_SET_NUMBER               := 1;
      SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

      BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID,
                           0,
                           GA.EXTERNAL_STATE,
                           v_BID_OFFER_DATE,
                           v_SET_NUMBER,
                           NULL,
                           p_RECORDS(v_INDEX).BidAmount,
                           'P',
                           MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                           p_STATUS);

      IF p_COPY_INTERNAL THEN
        BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID,
                           0,
                           GA.INTERNAL_STATE,
                           v_BID_OFFER_DATE,
                           v_SET_NUMBER,
                           NULL,
                           p_RECORDS(v_INDEX).BidAmount,
                           'P',
                           MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                           p_STATUS);


      END IF;

      v_SET_NUMBER := v_SET_NUMBER + 1;
      v_INDEX := p_RECORDS.NEXT(v_INDEX);

    END LOOP;

  END PUT_INITIAL_ARR;
  ------------------------------------------------------------------------------------
  PROCEDURE PUT_CLEARED_FTRS(p_RECORDS       IN MEX_PJM_FTR_CLEARED_TBL,
                             p_LOGGER        IN OUT NOCOPY MM_LOGGER_ADAPTER,
                             p_STATUS        OUT NUMBER,
                             p_ERROR_MESSAGE OUT VARCHAR2) AS

    --Save Auction Results to MM.

    v_PREV_AUCTION_MKT_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SOURCE_NAME      VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SINK_NAME        VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_OPT_OBL          VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_PK_CLASS         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_BUY_SELL         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_TRANSACTION_ID        NUMBER(9);
    v_AGREEMENT_TYPE      INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_TRANSACTION_TYPE    INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_COMMODITY_TYPE      IT_COMMODITY.COMMODITY_TYPE%TYPE := 'Transmission';
    v_PK_CLASS            VARCHAR2(16);
    v_AUCTION_DATE        DATE;
    v_AUCTION_END_DATE    DATE;
    v_IS_ANNUAL           BOOLEAN;
    v_SCHEDULE_DATE       DATE;
    v_INTERVAL_BEGIN_DATE DATE;
    v_INTERVAL_END_DATE   DATE;
    v_PUT_HOUR            BOOLEAN;
    v_TXN_ROWNUM          NUMBER(3) := 1;
    v_AS_OF_DATE          DATE := LOW_DATE;
    v_SAME_AUCTION        BOOLEAN;
    p_EXCHANGE_ID         NUMBER(9);
    v_INDEX BINARY_INTEGER;

  BEGIN

    IF p_RECORDS.COUNT = 0 THEN
      RETURN;
    END IF;

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP

      --CHECK TO SEE IF EVERYTHING IS THE SAME.
      v_SAME_AUCTION := (v_PREV_AUCTION_MKT_NAME = p_RECORDS(v_INDEX)
                        .AuctionMarketName);
      IF (v_SAME_AUCTION AND
         (p_RECORDS(v_INDEX)
         .SourceName IS NULL OR
          (v_PREV_SOURCE_NAME = p_RECORDS(v_INDEX)
          .SourceName AND v_PREV_SINK_NAME = p_RECORDS(v_INDEX).SinkName)) AND
         v_PREV_OPT_OBL = p_RECORDS(v_INDEX)
         .HedgeType AND v_PREV_PK_CLASS = p_RECORDS(v_INDEX)
         .PeakClass AND v_PREV_BUY_SELL = p_RECORDS(v_INDEX).BuySell) THEN
        v_TXN_ROWNUM := v_TXN_ROWNUM + 1;
      ELSE
        --Different FTR
        v_TXN_ROWNUM := 1;

        --DETERMINE AGREEMENT TYPE
        v_PK_CLASS := p_RECORDS(v_INDEX).PeakClass;

        IF UPPER(SUBSTR(p_RECORDS(v_INDEX).HedgeType, 1, 3)) = 'OPT' THEN
          v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Option';
        ELSE
          v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Obligation';
        END IF;

        --DETERMINE TRANSACTION TYPE
        CASE UPPER(p_RECORDS(v_INDEX).BuySell)
          WHEN 'BUY' THEN
            v_TRANSACTION_TYPE := 'Purchase';
          WHEN 'SELL' THEN
            v_TRANSACTION_TYPE := 'Sale';
          ELSE
            v_TRANSACTION_TYPE := 'SelfScheduled';
        END CASE;

        v_PREV_AUCTION_MKT_NAME := p_RECORDS(v_INDEX).AuctionMarketName;
        v_PREV_SOURCE_NAME      := p_RECORDS(v_INDEX).SourceName;
        v_PREV_SINK_NAME        := p_RECORDS(v_INDEX).SinkName;
        v_PREV_OPT_OBL          := p_RECORDS(v_INDEX).HedgeType;
        v_PREV_PK_CLASS         := p_RECORDS(v_INDEX).PeakClass;
        v_PREV_BUY_SELL         := p_RECORDS(v_INDEX).BuySell;

        SELECT MKT_INT_START, MKT_INT_END
        INTO v_AUCTION_DATE, v_AUCTION_END_DATE
        FROM PJM_EFTR_MARKET_INFO
        WHERE UPPER(MKT_NAME) = UPPER(p_RECORDS(v_INDEX).AuctionMarketName)
        AND ROWNUM = 1;

        /*MEX_PJM_EFTR.GET_AUCTION_MARKET_DATES(p_RECORDS(v_INDEX)
                                              .AuctionMarketName,
                                              v_AUCTION_DATE,
                                              v_AUCTION_END_DATE,
                                              v_IS_ANNUAL,
                                              p_STATUS,
                                              p_ERROR_MESSAGE);*/
        IF p_ERROR_MESSAGE IS NOT NULL THEN
          p_STATUS := -1;
          ROLLBACK;
          RETURN;
        END IF;
        UT.CUT_DAY_INTERVAL_RANGE(GA.ELECTRIC_MODEL,
                                  v_AUCTION_DATE,
                                  v_AUCTION_END_DATE,
                                  MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                                  60,
                                  v_INTERVAL_BEGIN_DATE,
                                  v_INTERVAL_END_DATE);

      END IF;

      --GET THE TRANSACTION ID; CREATE TXN IF IT DOES NOT EXIST.
      v_TRANSACTION_ID := GET_FTR_TRANSACTION_ID(v_AUCTION_DATE,
                                                 v_AUCTION_END_DATE,
                                                 v_TRANSACTION_TYPE,
                                                 ID_FOR_PJM_CONTRACT(g_PJM_CONTRACT_NAME),
                                                 NULL,
                                                 p_RECORDS(v_INDEX)
                                                 .SourceName,
                                                 p_RECORDS(v_INDEX).SinkName,
                                                 v_COMMODITY_TYPE,
                                                 v_AGREEMENT_TYPE,
                                                 v_PK_CLASS,
                                                 v_TXN_ROWNUM,
                                                 TRUE,
                                                 p_ERROR_MESSAGE,
                                                 0,
                                                 NULL,
                                                 v_PREV_AUCTION_MKT_NAME);

      IF v_TRANSACTION_ID < 0 OR p_ERROR_MESSAGE IS NOT NULL THEN
        IF p_ERROR_MESSAGE IS NULL THEN

          p_ERROR_MESSAGE := 'Could not get TRANSACTION ID for ' ||
                             p_RECORDS(v_INDEX)
                            .AuctionMarketName || ', ' || v_AGREEMENT_TYPE;
        END IF;
        p_STATUS := -1;
        ROLLBACK;
        RETURN;
      END IF;

      /*IF NOT v_SAME_AUCTION THEN
        --WIPE OUT IT_SCHEDULE FTR DATA FOR THE DATE RANGE.
        DELETE IT_SCHEDULE
         WHERE TRANSACTION_ID IN
               (SELECT A.TRANSACTION_ID
                  FROM INTERCHANGE_TRANSACTION A, IT_COMMODITY B
                 WHERE B.COMMODITY_TYPE = v_COMMODITY_TYPE
                   AND A.COMMODITY_ID = B.COMMODITY_ID
                   AND A.TRANSACTION_TYPE IN
                       ('Purchase', 'Sale', 'SelfScheduled')
                   AND UPPER(SUBSTR(A.AGREEMENT_TYPE, 1, 3)) = 'FTR')
           AND SCHEDULE_STATE = GA.INTERNAL_STATE
           AND SCHEDULE_DATE BETWEEN v_AUCTION_DATE AND v_AUCTION_END_DATE
           AND AS_OF_DATE = v_AS_OF_DATE;
      END IF;*/

      IF p_RECORDS(v_INDEX).ClearedAmount <= 0 THEN
        --JUST LOG THE FAILED BID.
		p_LOGGER.LOG_WARN('Cleared MW=0 :' || p_RECORDS(v_INDEX).AuctionMarketName || ', ' ||
			p_RECORDS(v_INDEX).SourceName || ', ' || p_RECORDS(v_INDEX).SinkName || ', ' ||
			p_RECORDS(v_INDEX).PeakClass);
      ELSE
        --MW > 0,  process the result
        --SAVE THE CLEARED AMOUNT AND PRICE FOR THE PERIOD.
        v_SCHEDULE_DATE := v_INTERVAL_BEGIN_DATE;
        WHILE v_SCHEDULE_DATE <= v_INTERVAL_END_DATE LOOP
          v_PUT_HOUR := FALSE;
          CASE UPPER(v_PK_CLASS)
            WHEN '24H' THEN
              v_PUT_HOUR := TRUE;
            WHEN 'ONPEAK' THEN
              v_PUT_HOUR := IS_ON_PEAK_HOUR(v_SCHEDULE_DATE, 0);
            WHEN 'OFFPEAK' THEN
              v_PUT_HOUR := NOT IS_ON_PEAK_HOUR(v_SCHEDULE_DATE, 0);
            ELSE
              NULL;
          END CASE;
          IF v_PUT_HOUR THEN
            FOR v_STATEMENT_TYPE IN 1..3 LOOP
              PUT_IT_SCHEDULE_DATA(v_TRANSACTION_ID,
                                 v_SCHEDULE_DATE,
                                 GA.INTERNAL_STATE,
                                 v_STATEMENT_TYPE,
                                 p_RECORDS(v_INDEX).ClearedAmount,
                                 p_RECORDS(v_INDEX).ClearedPrice,
                                 p_STATUS,
                                 p_ERROR_MESSAGE);
              END LOOP;
          END IF;
          v_SCHEDULE_DATE := v_SCHEDULE_DATE + 1 / 24;

        END LOOP;

      END IF; --MW > 0

    END LOOP;
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS                   := SQLCODE;
      p_ERROR_MESSAGE            := 'ERROR OCCURED IN PUT_CLEARED_FTRS ' ||
                                    UT.GET_FULL_ERRM;
      ROLLBACK;

  END PUT_CLEARED_FTRS;
  ------------------------------------------------------------------------------------
  PROCEDURE PUT_FTR_QUOTES(p_RECORDS       IN MEX_PJM_FTR_QUOTES_TBL,
                           p_ISO_ACCT_NAME      IN VARCHAR2,
                           p_COPY_INTERNAL IN BOOLEAN,
                           p_STATUS        OUT NUMBER,
                           p_ERROR_MESSAGE OUT VARCHAR2) AS

    --Save Auction Results to MM.

    v_PREV_AUCTION_MKT_NAME VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SOURCE_NAME      VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_SINK_NAME        VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_OPT_OBL          VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_PK_CLASS         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_PREV_BUY_SELL         VARCHAR2(64) := g_INIT_VAL_VARCHAR;
    v_TRANSACTION_ID        NUMBER(9);
    --v_COMMODITY_NAME IT_COMMODITY.COMMODITY_NAME%TYPE;
    v_AGREEMENT_TYPE   INTERCHANGE_TRANSACTION.AGREEMENT_TYPE%TYPE;
    v_TRANSACTION_TYPE INTERCHANGE_TRANSACTION.TRANSACTION_TYPE%TYPE;
    v_COMMODITY_TYPE   IT_COMMODITY.COMMODITY_TYPE%TYPE := 'Transmission';
    v_SET_NUMBER       NUMBER(2);
    v_PK_CLASS         VARCHAR2(16);
    v_AUCTION_DATE     DATE;
    v_AUCTION_END_DATE DATE;
    v_IS_ANNUAL        BOOLEAN;
    v_BID_OFFER_DATE   DATE;
    v_TXN_ROWNUM       NUMBER(3) := 1;
    v_SAME_AUCTION     BOOLEAN;
    v_CONTRACT_ID	INTERCHANGE_CONTRACT.CONTRACT_ID%TYPE;

    v_INDEX BINARY_INTEGER;

  BEGIN

    --use contract's external identifier instead of the entity's alias
	v_CONTRACT_ID := MM_PJM_UTIL.GET_CONTRACT_ID_FOR_ISO_ACCT(p_ISO_ACCT_NAME);

    IF p_RECORDS.COUNT = 0 THEN
      RETURN;
    END IF;

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP

      --CHECK TO SEE IF EVERYTHING IS THE SAME.
      v_SAME_AUCTION := (v_PREV_AUCTION_MKT_NAME = p_RECORDS(v_INDEX)
                        .AuctionMarketName);
      IF (v_SAME_AUCTION AND
         (p_RECORDS(v_INDEX)
         .SourceName IS NULL OR
          (v_PREV_SOURCE_NAME = p_RECORDS(v_INDEX)
          .SourceName AND v_PREV_SINK_NAME = p_RECORDS(v_INDEX).SinkName)) AND
         v_PREV_OPT_OBL = p_RECORDS(v_INDEX)
         .HedgeType AND v_PREV_PK_CLASS = p_RECORDS(v_INDEX)
         .PeakClass AND v_PREV_BUY_SELL = p_RECORDS(v_INDEX).BuySell) THEN
        v_TXN_ROWNUM := v_TXN_ROWNUM + 1;
      ELSE
        --Different FTR
        v_TXN_ROWNUM := 1;

        --DETERMINE AGREEMENT TYPE
        v_PK_CLASS := p_RECORDS(v_INDEX).PeakClass;

        IF UPPER(SUBSTR(p_RECORDS(v_INDEX).HedgeType, 1, 3)) = 'OPT' THEN
          v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Option';
        ELSE
          v_AGREEMENT_TYPE := 'FTR ' || v_PK_CLASS || ' Obligation';
        END IF;

        --DETERMINE TRANSACTION TYPE
        CASE UPPER(p_RECORDS(v_INDEX).BuySell)
          WHEN 'BUY' THEN
            v_TRANSACTION_TYPE := 'Purchase';
          WHEN 'SELL' THEN
            v_TRANSACTION_TYPE := 'Sale';
          ELSE
            v_TRANSACTION_TYPE := 'SelfScheduled';
        END CASE;

        v_PREV_AUCTION_MKT_NAME := p_RECORDS(v_INDEX).AuctionMarketName;
        v_PREV_SOURCE_NAME      := p_RECORDS(v_INDEX).SourceName;
        v_PREV_SINK_NAME        := p_RECORDS(v_INDEX).SinkName;
        v_PREV_OPT_OBL          := p_RECORDS(v_INDEX).HedgeType;
        v_PREV_PK_CLASS         := p_RECORDS(v_INDEX).PeakClass;
        v_PREV_BUY_SELL         := p_RECORDS(v_INDEX).BuySell;

        SELECT MKT_INT_START, MKT_INT_END
        INTO v_AUCTION_DATE, v_AUCTION_END_DATE
        FROM PJM_EFTR_MARKET_INFO
        WHERE UPPER(MKT_NAME) = UPPER(p_RECORDS(v_INDEX).AuctionMarketName)
        AND ROWNUM = 1;

        /*MEX_PJM_EFTR.GET_AUCTION_MARKET_DATES(p_RECORDS(v_INDEX)
                                              .AuctionMarketName,
                                              v_AUCTION_DATE,
                                              v_AUCTION_END_DATE,
                                              v_IS_ANNUAL,
                                              p_STATUS,
                                              p_ERROR_MESSAGE);*/
        IF p_ERROR_MESSAGE IS NOT NULL THEN
          p_STATUS := -1;
          ROLLBACK;
          RETURN;
        END IF;
        --v_BID_OFFER_DATE should be 1 sec after midnite FOR BID_OFFER_SET
        v_BID_OFFER_DATE := v_AUCTION_DATE + g_SECOND;

      END IF;

      --GET THE TRANSACTION ID; CREATE TXN IF IT DOES NOT EXIST.
      v_TRANSACTION_ID := GET_FTR_TRANSACTION_ID(v_AUCTION_DATE,
                                                 v_AUCTION_END_DATE,
                                                 v_TRANSACTION_TYPE,
                                                 v_CONTRACT_ID,
                                                 NULL,
                                                 p_RECORDS(v_INDEX)
                                                 .SourceName,
                                                 p_RECORDS(v_INDEX).SinkName,
                                                 v_COMMODITY_TYPE,
                                                 v_AGREEMENT_TYPE,
                                                 v_PK_CLASS,
                                                 v_TXN_ROWNUM,
                                                 TRUE,
                                                 p_ERROR_MESSAGE,
                                                 0,
                                                 NULL,
                                                 v_PREV_AUCTION_MKT_NAME);

      IF v_TRANSACTION_ID < 0 OR p_ERROR_MESSAGE IS NOT NULL THEN
        IF p_ERROR_MESSAGE IS NULL THEN

          p_ERROR_MESSAGE := 'Could not get TRANSACTION ID for ' ||
                             p_RECORDS(v_INDEX)
                            .AuctionMarketName || ', ' || v_AGREEMENT_TYPE;
        END IF;
        p_STATUS := -1;
        ROLLBACK;
        RETURN;
      END IF;

      --SAVE THE BID CURVE AS EXTERNAL.
      v_SET_NUMBER               := 1;
      SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);

      BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID,
                           0,
                           GA.EXTERNAL_STATE,
                           v_BID_OFFER_DATE,
                           v_SET_NUMBER,
                           p_RECORDS(v_INDEX).Price,
                           p_RECORDS(v_INDEX).Amount,
                           'P',
                           MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                           p_STATUS);

      IF p_COPY_INTERNAL THEN
        BO.PUT_BID_OFFER_SET(v_TRANSACTION_ID,
                           0,
                           GA.INTERNAL_STATE,
                           v_BID_OFFER_DATE,
                           v_SET_NUMBER,
                           p_RECORDS(v_INDEX).Price,
                           p_RECORDS(v_INDEX).Amount,
                           'P',
                           MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
                           p_STATUS);
      END IF;

      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

      v_SET_NUMBER := v_SET_NUMBER + 1;

      v_INDEX := p_RECORDS.NEXT(v_INDEX);

    END LOOP;
    COMMIT;

    SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);

  EXCEPTION
    WHEN OTHERS THEN
      SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
      p_STATUS                   := SQLCODE;
      p_ERROR_MESSAGE            := 'ERROR OCCURED IN PUT_FTR_MARKET_RESULTS ' ||
                                    UT.GET_FULL_ERRM;
      ROLLBACK;

  END PUT_FTR_QUOTES;
  ------------------------------------------------------------------------------------

  PROCEDURE QUERY_INITIAL_ARR(p_CRED		  IN MEX_CREDENTIALS,
  							  p_COPY_INTERNAL IN BOOLEAN,
                              p_LOG_ONLY      IN NUMBER,
                              p_STATUS        OUT NUMBER,
                              p_MESSAGE       OUT VARCHAR2,
							  p_LOGGER	      IN OUT MM_LOGGER_ADAPTER) AS

  v_RECORDS MEX_PJM_FTR_INITIAL_ARR_TBL;

  BEGIN
    p_STATUS := GA.SUCCESS;

	MEX_PJM_EFTR.QUERY_INITIAL_ARR(p_CRED,
								 p_LOG_ONLY,
								 v_RECORDS,
								 p_STATUS,
								 p_MESSAGE,
								 p_LOGGER);

	-- put records from query into the database
	PUT_INITIAL_ARR(p_COPY_INTERNAL,
				  p_CRED.EXTERNAL_ACCOUNT_NAME,
				  v_RECORDS,
				  p_LOGGER,
				  p_STATUS,
				  p_MESSAGE);

  END QUERY_INITIAL_ARR;
 ------------------------------------------------------------------------------------

  PROCEDURE QUERY_MARKET_RESULTS(p_CRED		  IN mex_credentials,
  								 p_BEGIN_DATE IN DATE,
                                 p_END_DATE   IN DATE,
                                 p_LOG_ONLY   IN NUMBER,
                                 p_STATUS     OUT NUMBER,
                                 p_MESSAGE    OUT VARCHAR2,
								 p_LOGGER	  IN OUT mm_logger_adapter) AS

  v_RECORDS MEX_PJM_FTR_MARKET_RESULTS_TBL;

  BEGIN
    p_STATUS := GA.SUCCESS;

	MEX_PJM_EFTR.QUERY_MARKET_RESULTS(p_CRED,
									p_LOG_ONLY,
									v_RECORDS,
									p_STATUS,
									p_MESSAGE,
									p_LOGGER);

	-- put records from query into the database
	PUT_FTR_MARKET_RESULTS(v_RECORDS,
							p_CRED.EXTERNAL_ACCOUNT_NAME,
							p_BEGIN_DATE,
							p_END_DATE,
							p_STATUS,
							p_MESSAGE);

    UPDATE PJM_EFTR_MARKET_INFO
    SET IS_ACTIVE = 0
    WHERE IS_ACTIVE = 1;
    COMMIT;

  END QUERY_MARKET_RESULTS;
 ------------------------------------------------------------------------------------
PROCEDURE QUERY_FTR_QUOTES(p_CRED		  IN mex_credentials,
						   p_LOG_ONLY   IN NUMBER,
                           p_COPY_INTERNAL IN BOOLEAN,
                           p_STATUS     OUT NUMBER,
                           p_MESSAGE    OUT VARCHAR2,
						   p_LOGGER	  IN OUT mm_logger_adapter) AS

  v_RECORDS MEX_PJM_FTR_QUOTES_TBL;

  BEGIN
    p_STATUS := GA.SUCCESS;

	MEX_PJM_EFTR.QUERY_FTR_QUOTES(p_CRED,
								p_LOG_ONLY,
								v_RECORDS,
								p_STATUS,
								p_MESSAGE,
								p_LOGGER);

	PUT_FTR_QUOTES(v_RECORDS,
					p_CRED.EXTERNAL_ACCOUNT_NAME,
					p_COPY_INTERNAL,
					p_STATUS,
					p_MESSAGE);

END QUERY_FTR_QUOTES;
---------------------------------------------------------------------------------------------------

  PROCEDURE PUT_MARKET_MESSAGES(p_RECORDS    IN MEX_PJM_FTR_MESSAGE_TBL) AS
    v_INDEX  BINARY_INTEGER;
    l_RECORD MEX_PJM_FTR_MESSAGE;
  BEGIN

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP
      l_RECORD := p_RECORDS(v_INDEX);
      MEX_UTIL.INSERT_MARKET_MESSAGE(p_MARKET_OPERATOR     => 'PJM',
                                     p_MESSAGE_DATE        => l_RECORD.MessageDate,
                                     p_REALM               => NULL,
                                     p_EFFECTIVE_DATE      => l_RECORD.EffectiveDate,
                                     p_TERMINATION_DATE    => l_RECORD.TerminationDate,
                                     p_PRIORITY            => NULL,
                                     p_MESSAGE_SOURCE      => 'PJM QUERY_MARKET_MESSAGES',
                                     p_MESSAGE_DESTINATION => NULL,
                                     p_TEXT                => l_RECORD.MessageText);
      v_INDEX := p_RECORDS.NEXT(v_INDEX);
    END LOOP;

  END PUT_MARKET_MESSAGES;

-------------------------------------------------------------------------------------

PROCEDURE QUERY_MARKET_MESSAGES(p_CRED		  IN mex_credentials,
								p_EFFECTIVE_DATE IN DATE,
                                p_LOG_ONLY   IN NUMBER,
                                p_STATUS     OUT NUMBER,
                                p_MESSAGE    OUT VARCHAR2,
								p_LOGGER	  IN OUT mm_logger_adapter) AS

  v_RECORDS MEX_PJM_FTR_MESSAGE_TBL;

  BEGIN
    p_STATUS := GA.SUCCESS;

	MEX_PJM_EFTR.QUERY_MARKET_MESSAGES(p_CRED,
									   P_LOG_ONLY,
									   p_EFFECTIVE_DATE,
									   v_RECORDS,
									   p_STATUS,
									   p_MESSAGE,
									   p_LOGGER);

	-- put records from query into the database
	PUT_MARKET_MESSAGES(v_RECORDS);
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MM_PJM_EFTR.QUERY_MARKET_MESSAGES: ' || UT.GET_FULL_ERRM;

  END QUERY_MARKET_MESSAGES;
-------------------------------------------------------------------------------------

PROCEDURE QUERY_MARKET_INFO(p_CRED		  IN mex_credentials,
						  	p_LOG_ONLY   IN NUMBER,
                            p_STATUS     OUT NUMBER,
                            p_MESSAGE    OUT VARCHAR2,
							p_LOGGER	  IN OUT mm_logger_adapter) AS

    --Handle Query and Response for FTR Market Information
    --no date specified. default returns any market whose bidding
    -- period is currently open or future markets that are defined
  BEGIN
    p_STATUS := GA.SUCCESS;

	MEX_PJM_EFTR.QUERY_MARKET_INFO(p_CRED,
								   p_LOG_ONLY,
								   p_STATUS,
								   p_MESSAGE,
								   p_LOGGER);
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MM_PJM_EFTR.QUERY_MARKET_INFO: ' || UT.GET_FULL_ERRM;
  END QUERY_MARKET_INFO;

-------------------------------------------------------------------------------------
--cgn this is meant to be queried for a given date
PROCEDURE QUERY_FTR_POSITION
    (
	p_CRED		  IN mex_credentials,
    p_BEGIN_DATE IN DATE,
    p_END_DATE DATE,
    p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
	p_LOGGER	  IN OUT mm_logger_adapter
    ) AS

  v_RECORDS MEX_PJM_FTR_POSITION_TBL;
  v_DATE DATE;

BEGIN

    p_STATUS := GA.SUCCESS;

	v_DATE := p_BEGIN_DATE;
	WHILE v_DATE <= p_END_DATE LOOP
		MEX_PJM_EFTR.QUERY_FTR_POSITION(p_CRED, p_LOG_ONLY, v_DATE, v_RECORDS,
										p_STATUS, p_MESSAGE, p_LOGGER);
		PUT_FTR_POSITION(v_RECORDS,
							p_CRED.EXTERNAL_ACCOUNT_NAME,
							p_STATUS,
							p_MESSAGE);

		v_DATE := v_DATE + 1;
	END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MM_PJM_EFTR.QUERY_FTR_POSITION: ' || UT.GET_FULL_ERRM;

  END QUERY_FTR_POSITION;
-------------------------------------------------------------------------------------

  PROCEDURE QUERY_CLEARED_FTRS(p_CRED		  IN mex_credentials,
  							   p_LOG_ONLY   IN NUMBER,
                               p_STATUS     OUT NUMBER,
                               p_MESSAGE    OUT VARCHAR2,
							   p_LOGGER	  IN OUT mm_logger_adapter) AS

  v_RECORDS MEX_PJM_FTR_CLEARED_TBL;

  BEGIN
    p_STATUS := GA.SUCCESS;
	MEX_PJM_EFTR.QUERY_CLEARED_FTRS(p_CRED,
									p_LOG_ONLY,
									v_RECORDS,
									p_STATUS,
									p_MESSAGE,
									p_LOGGER);
	-- put records from query into the database
	PUT_CLEARED_FTRS(v_RECORDS,
					 p_LOGGER,
					 p_STATUS,
					 p_MESSAGE);

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := 'Error in MM_PJM_EFTR.QUERY_CLEARED_FTRS: ' || UT.GET_FULL_ERRM;

  END QUERY_CLEARED_FTRS;
-------------------------------------------------------------------------------------

  PROCEDURE PUT_FTR_NODES(p_RECORDS    IN MEX_PJM_FTR_NODE_TBL,
                          p_STATUS     OUT NUMBER,
                          p_MESSAGE    OUT VARCHAR2) AS
    v_INDEX  BINARY_INTEGER;
    l_RECORD MEX_PJM_FTR_NODE;
    l_OID    NUMBER;

  BEGIN
    p_STATUS := GA.SUCCESS;

    v_INDEX := p_RECORDS.FIRST;

    WHILE p_RECORDS.EXISTS(v_INDEX) LOOP
      l_RECORD := p_RECORDS(v_INDEX);
      IO.PUT_SERVICE_POINT(o_OID                 => l_OID,
                           p_SERVICE_POINT_NAME  => l_RECORD.EXTERNAL_ID,
                           p_SERVICE_POINT_ALIAS => GA.UNDEFINED_ATTRIBUTE,
                           p_SERVICE_POINT_DESC  => GA.UNDEFINED_ATTRIBUTE,
                           p_SERVICE_POINT_ID    => 0,
                           p_SERVICE_POINT_TYPE  => 'Retail',
                           p_TP_ID               => NULL,
                           p_CA_ID               => NULL,
                           p_EDC_ID              => NULL,
                           p_ROLLUP_ID           => NULL,
                           p_SERVICE_REGION_ID   => NULL,
                           p_SERVICE_AREA_ID     => NULL,
                           p_SERVICE_ZONE_ID     => NULL,
                           p_TIME_ZONE           => 'EDT',
                           p_LATITUDE            => NULL,
                           p_LONGITUDE           => NULL,
                           p_EXTERNAL_IDENTIFIER => l_RECORD.EXTERNAL_ID,
                           p_IS_INTERCONNECT     => 0,
                           p_NODE_TYPE           => 'Bus',
                           p_SERVICE_POINT_NERC_CODE => NULL,
						   p_PIPELINE_ID => 0,
						   p_MILE_MARKER => 0);

      v_INDEX := p_RECORDS.NEXT(v_INDEX);
    END LOOP;

  END PUT_FTR_NODES;

-------------------------------------------------------------------------------------

PROCEDURE QUERY_FTR_NODES(p_CRED		  IN mex_credentials,
						  p_LOG_ONLY         IN NUMBER,
                          p_STATUS           OUT NUMBER,
                          p_MESSAGE          OUT VARCHAR2,
						  p_LOGGER	  IN OUT mm_logger_adapter) AS

  --query for each active market in PJM_EFTR_MARKET_INFO table
  BEGIN
   p_STATUS := GA.SUCCESS;

	MEX_PJM_EFTR.QUERY_FTR_NODES(p_CRED,
							   p_LOG_ONLY,
							   p_STATUS,
							   p_MESSAGE,
							   p_LOGGER);

  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
       p_MESSAGE := 'Error in MM_PJM_EFTR.QUERY_FTR_NODES: ' || UT.GET_FULL_ERRM;

  END QUERY_FTR_NODES;
  -------------------------------------------------------------------------------------
  PROCEDURE MARKET_EXCHANGE(p_BEGIN_DATE       IN DATE,
                            p_END_DATE         IN DATE,
                            p_EXCHANGE_TYPE    IN VARCHAR2,
							p_LOG_ONLY			IN NUMBER :=0,
							p_LOG_TYPE			IN NUMBER,
							p_TRACE_ON			IN NUMBER,
                            p_STATUS           OUT NUMBER,
                            p_MESSAGE          OUT VARCHAR2) AS

    v_LOG_ONLY NUMBER(1) := 0;
    v_ACTION   VARCHAR2(64);
	
	v_EFTR_PERMISSION_ID NUMBER(9);

	v_CREDS		mm_credentials_set;
	v_CRED		mex_credentials;
	v_LOGGER	mm_logger_adapter;

  BEGIN
	v_LOG_ONLY := NVL(p_LOG_ONLY,0);
    v_ACTION := p_EXCHANGE_TYPE;
	ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eFTR', EC.ED_INTERCHANGE_CONTRACT, 'String', TRUE, v_EFTR_PERMISSION_ID);

	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_PJM,
		p_PROCESS_NAME => 'PJM:EFTR',
		p_EXCHANGE_NAME => v_ACTION,
		p_LOG_TYPE => p_LOG_TYPE,
		p_TRACE_ON => p_TRACE_ON,
		p_CREDENTIALS => v_CREDS,
		p_LOGGER => v_LOGGER);

	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

    WHILE v_CREDS.HAS_NEXT LOOP
	  v_CRED := v_CREDS.GET_NEXT;

	  IF MM_PJM_UTIL.HAS_ESUITE_ACCESS(v_EFTR_PERMISSION_ID, v_CRED.EXTERNAL_ACCOUNT_NAME) THEN

		IF v_ACTION = g_ET_QUERY_FTR_AUCTION_RESULTS THEN
		  --AUCTION RESULTS
		  --'Query', 'download'
		  QUERY_MARKET_RESULTS(v_CRED,
							   p_BEGIN_DATE,
							   p_END_DATE,
							   v_LOG_ONLY,
							   p_STATUS,
							   p_MESSAGE,
							   v_LOGGER);

		ELSIF v_ACTION = g_ET_QUERY_FTR_QUOTES THEN
		  -- Querying for Cleared FTRs
		  QUERY_FTR_QUOTES(v_CRED,
						   v_LOG_ONLY,
						   FALSE,
						   p_STATUS,
						   p_MESSAGE,
						   v_LOGGER);

		ELSIF v_ACTION = g_ET_QUERY_FTR_QUOTES_TO_INT THEN
		  -- Querying for Cleared FTRs
		  QUERY_FTR_QUOTES(v_CRED,
						   v_LOG_ONLY,
						   TRUE,
						   p_STATUS,
						   p_MESSAGE,
						   v_LOGGER);

		  -- query for FTR nodes
		ELSIF v_ACTION = g_ET_QUERY_FTR_NODES THEN
		  QUERY_FTR_NODES(v_CRED,
						  v_LOG_ONLY,
						  p_STATUS,
						  p_MESSAGE,
						  v_LOGGER);

		  -- query for messages
		ELSIF v_ACTION = g_ET_QUERY_MESSAGES THEN
		  QUERY_MARKET_MESSAGES(v_CRED,
								p_BEGIN_DATE,
								v_LOG_ONLY,
								p_STATUS,
								p_MESSAGE,
								v_LOGGER);

		  -- query for market info
		ELSIF v_ACTION = g_ET_QUERY_MARKET_INFO THEN
		  QUERY_MARKET_INFO(v_CRED,
							v_LOG_ONLY,
							p_STATUS,
							p_MESSAGE,
							v_LOGGER);

		-- query for initial arr
		ELSIF v_ACTION = g_ET_QUERY_INITIAL_ARR THEN
		  QUERY_INITIAL_ARR(v_CRED,
							FALSE,
							v_LOG_ONLY,
							p_STATUS,
							p_MESSAGE,
							v_LOGGER);

		ELSIF v_ACTION = g_ET_QUERY_INITIAL_ARR_TO_INT THEN
		  QUERY_INITIAL_ARR(v_CRED,
							TRUE,
							v_LOG_ONLY,
							p_STATUS,
							p_MESSAGE,
							v_LOGGER);

		 -- query for cleared ftrs
		ELSIF v_ACTION = g_ET_QUERY_CLEARED_FTRS THEN
		  QUERY_CLEARED_FTRS(v_CRED,
							v_LOG_ONLY,
							p_STATUS,
							p_MESSAGE,
							v_LOGGER);

		ELSIF v_ACTION = g_ET_QUERY_FTR_POSITION THEN
			QUERY_FTR_POSITION(v_CRED,
								p_BEGIN_DATE,
								p_END_DATE,
								v_LOG_ONLY,
								p_STATUS,
								p_MESSAGE,
								v_LOGGER);

		ELSE
			p_STATUS := -1;
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
			v_LOGGER.LOG_ERROR(p_MESSAGE);
			EXIT;
		END IF;

		-- RUN FOR ONLY ONE SET OF CREDENTIALS
		EXIT WHEN (v_ACTION = g_ET_QUERY_MARKET_INFO) OR (v_ACTION = g_ET_QUERY_FTR_NODES);
	  END IF;
	END LOOP;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := UT.GET_FULL_ERRM;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

END MARKET_EXCHANGE;
---------------------------------------------------------------------------------------------------
PROCEDURE MARKET_IMPORT_CLOB
	(
	p_EXCHANGE_TYPE         	IN VARCHAR2,
	p_FILE_PATH					IN VARCHAR2, 		-- For logging Purposes.
	p_IMPORT_FILE				IN OUT NOCOPY CLOB, -- File to be imported
	p_LOG_TYPE					IN NUMBER,
	p_TRACE_ON					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

    v_XML                    XMLTYPE;
    v_RECORDS_MARKET_RESULTS MEX_PJM_FTR_MARKET_RESULTS_TBL;
    v_RECORDS_FTR_QUOTES     MEX_PJM_FTR_QUOTES_TBL;
	v_CRED                   MEX_CREDENTIALS;
	v_LOGGER                 MM_LOGGER_ADAPTER;
BEGIN

	MM_UTIL.INIT_MEX(EC.ES_PJM, NULL, 'PJM:EFTR Import', p_EXCHANGE_TYPE, p_LOG_TYPE, p_TRACE_ON, v_CRED, v_LOGGER, TRUE);
	MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

	-- do something with the data
	CASE p_EXCHANGE_TYPE
		WHEN g_ET_IMPORT_FTR_AUCTION_RES THEN

			v_XML                    := XMLTYPE.CREATEXML(p_IMPORT_FILE);
			v_RECORDS_MARKET_RESULTS := MEX_PJM_FTR_MARKET_RESULTS_TBL();

			--PARSE XML INTO TABLE OF OBJECTS
			MEX_PJM_EFTR.PARSE_MARKET_RESULTS(v_XML, v_RECORDS_MARKET_RESULTS, p_STATUS, p_MESSAGE);

			--UPDATE DATABASE
			/* PUT_FTR_MARKET_RESULTS(v_RECORDS_MARKET_RESULTS,
                               p_BEGIN_DATE,
                               p_END_DATE,
                               p_STATUS,
                               p_MESSAGE);*/

		WHEN g_ET_IMPORT_FTR_QUOTES THEN

			v_XML                := XMLTYPE.CREATEXML(p_IMPORT_FILE);
			v_RECORDS_FTR_QUOTES := MEX_PJM_FTR_QUOTES_TBL();

			--PARSE XML INTO TABLE OF OBJECTS
			MEX_PJM_EFTR.PARSE_FTR_QUOTES(v_XML,
                                      v_RECORDS_FTR_QUOTES,
                                      p_STATUS,
                                      p_MESSAGE);

			--UPDATE DATABASE
			PUT_FTR_QUOTES(v_RECORDS_FTR_QUOTES,
        			   g_PJM_CONTRACT_NAME,
                       FALSE,
                       p_STATUS,
                       p_MESSAGE);

		ELSE
		p_STATUS := -1;
		p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
		v_LOGGER.LOG_ERROR(p_MESSAGE);
	END CASE;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := UT.GET_FULL_ERRM;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END	MARKET_IMPORT_CLOB;
-----------------------------------------------------------------------------------------------------
PROCEDURE SUBMIT_FTR_QUOTES
	(
	p_CRED IN MEX_CREDENTIALS,
  	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ROUND IN NUMBER,
	p_IS_TEST_MODE IN NUMBER,
	p_ENTITY_LIST IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER IN CHAR,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT MM_LOGGER_ADAPTER) AS

    v_TXN_ID_TABLE       ID_TABLE;
    v_RECORDS            MEX_PJM_FTR_QUOTES_TBL;
    v_SUBMIT_STATUS      VARCHAR2(16);
    v_MKT_STATUS         VARCHAR2(16);
    v_AUCTION_DATE       DATE;
    v_AUCTION_BEGIN_DATE DATE;
    v_AUCTION_END_DATE   DATE;
    v_AUCTION_NAME       VARCHAR2(32);

    CURSOR c_TXNS IS
      SELECT *
        FROM PJM_FTRQUOTES P, TABLE(CAST(v_TXN_ID_TABLE AS ID_TABLE)) X
       WHERE P.AUCTION_DATE BETWEEN TRUNC(p_BEGIN_DATE, 'MONTH') AND
             TRUNC(p_END_DATE, 'MONTH')
         AND P.TRANSACTION_ID = X.ID
       ORDER BY P.AUCTION_DATE;

  BEGIN
    v_RECORDS := MEX_PJM_FTR_QUOTES_TBL();

    p_STATUS := GA.SUCCESS;

    UT.ID_TABLE_FROM_STRING(REPLACE(p_ENTITY_LIST,'''',''), p_ENTITY_LIST_DELIMITER, v_TXN_ID_TABLE);

    FOR v_TXN IN c_TXNS LOOP

      v_AUCTION_NAME := TRIM(TO_CHAR(v_TXN.AUCTION_DATE, 'MON')) || ' ' ||
                        TO_CHAR(v_TXN.AUCTION_DATE, 'YYYY') || ' Auction';

      v_RECORDS.EXTEND();
      v_RECORDS(v_RECORDS.LAST) := MEX_PJM_FTR_QUOTES(v_AUCTION_NAME,
                                                      v_TXN.AUCTION_DATE,
                                                      p_ROUND,
                                                      v_TXN.BUY_SELL,
                                                      v_TXN.SOURCE_NAME,
                                                      v_TXN.SINK_NAME,
                                                      v_TXN.PEAK_CLASS,
                                                      'All',
                                                      v_TXN.OPT_OBL,
                                                      v_TXN.BID_AMOUNT,
                                                      v_TXN.BID_PRICE);

    END LOOP;

	-- CALL MEX WITH THIS TABLE OF OBJECTS TO BUILD THE XML SUBMIT REQUEST AND SEND IT
	MEX_PJM_EFTR.SUBMIT_FTR_QUOTES(p_CRED, v_RECORDS, p_IS_TEST_MODE, p_STATUS, p_MESSAGE, p_LOGGER);

	IF p_STATUS = MEX_SWITCHBOARD.c_Status_Success THEN
		v_SUBMIT_STATUS := MEX_UTIL.g_SUBMIT_STATUS_SUBMITTED;
		v_MKT_STATUS := MEX_UTIL.g_MKT_STATUS_ACCEPTED;
	ELSE
		v_SUBMIT_STATUS := MEX_UTIL.g_SUBMIT_STATUS_FAILED;
		v_MKT_STATUS := NULL;
	END IF;

	FOR v_TXN IN c_TXNS LOOP

		v_AUCTION_DATE := v_TXN.AUCTION_DATE;
		v_AUCTION_BEGIN_DATE := TRUNC(v_AUCTION_DATE, 'MONTH');
		v_AUCTION_END_DATE   := LAST_DAY(v_AUCTION_BEGIN_DATE);

		UPDATE_BID_OFFER_STATUS(v_TXN.TRANSACTION_ID,
						  v_AUCTION_BEGIN_DATE,
						  v_AUCTION_END_DATE,
						  MEX_PJM_EFTR.g_PJM_EFTR_TIMEZONE,
						  v_SUBMIT_STATUS,
						  v_MKT_STATUS);

	END LOOP;

END SUBMIT_FTR_QUOTES;
---------------------------------------------------------------------------------------------------

  PROCEDURE  MARKET_SUBMIT_TRANSACTION_LIST
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_EXCHANGE_TYPE IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR) AS

  BEGIN


    CASE p_EXCHANGE_TYPE

      WHEN g_ET_SUBMIT_FTR_QUOTES THEN
        OPEN p_CURSOR FOR
          SELECT TRANSACTION_NAME, TRANSACTION_ID
            FROM INTERCHANGE_TRANSACTION
           WHERE IS_BID_OFFER = 1
             AND UPPER(AGREEMENT_TYPE) LIKE 'FTR%'
           ORDER BY TRANSACTION_NAME;
    END CASE;
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;

  END  MARKET_SUBMIT_TRANSACTION_LIST;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE SYSTEM_ACTION_USES_HOURS(p_ACTION IN VARCHAR2,
                                	 p_SHOW_HOURS OUT NUMBER) AS
  BEGIN
  	p_SHOW_HOURS := 0;
  END SYSTEM_ACTION_USES_HOURS;
  ---------------------------------------------------------------------------------------------------
  PROCEDURE MARKET_SUBMIT(p_BEGIN_DATE          IN DATE,
						  p_END_DATE 			IN DATE,
						  p_EXCHANGE_TYPE 		IN VARCHAR2,
						  p_ENTITY_LIST         IN VARCHAR2,
						  p_ENTITY_LIST_DELIMITER 	IN CHAR,
						  p_STATEMENT_TYPE_ID 	IN NUMBER,
					      p_SUBMIT_HOURS   		IN VARCHAR2,
					      p_TIME_ZONE       	IN VARCHAR2,
						  p_LOG_ONLY			IN NUMBER  :=0,
						  p_LOG_TYPE			IN NUMBER,
						  p_TRACE_ON		    IN NUMBER,
					      p_STATUS              OUT NUMBER,
						  p_MESSAGE         	OUT VARCHAR2) AS

    v_ROUND    NUMBER(1) := 1;
	v_LOG_ONLY NUMBER;
	v_CRED     MEX_CREDENTIALS;
	v_LOGGER   MM_LOGGER_ADAPTER;
  BEGIN

    v_LOG_ONLY := NVL(p_LOG_ONLY,0);

	MM_UTIL.INIT_MEX(EC.ES_PJM, NULL, 'PJM:EFTR', p_EXCHANGE_TYPE, p_LOG_TYPE, p_TRACE_ON, v_CRED, v_LOGGER);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	CASE p_EXCHANGE_TYPE
		WHEN g_ET_SUBMIT_FTR_QUOTES THEN
			SUBMIT_FTR_QUOTES(v_CRED,
				p_BEGIN_DATE,
				p_END_DATE,
				v_ROUND,
				v_LOG_ONLY,
				p_ENTITY_LIST,
				p_ENTITY_LIST_DELIMITER,
				p_STATUS,
				p_MESSAGE,
				v_LOGGER);
		ELSE
			p_STATUS := -1;
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
			v_LOGGER.LOG_ERROR(p_MESSAGE);
	END CASE;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
  EXCEPTION
    WHEN OTHERS THEN
      p_STATUS  := SQLCODE;
      p_MESSAGE := UT.GET_FULL_ERRM;
      MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

  END MARKET_SUBMIT;
---------------------------------------------------------------------------------------------------
END MM_PJM_EFTR;
/
