CREATE OR REPLACE PACKAGE MM_ISONE_LMP IS

  -- Author  : VGODYN
  -- Created : 9/8/2005 4:04:29 PM
  -- Purpose : Interface for ISONE LMP IMPORT using MEX_ISONE

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER,	
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

END MM_ISONE_LMP;
/
CREATE OR REPLACE PACKAGE BODY MM_ISONE_LMP IS

g_ISONE_NID CONSTANT VARCHAR2(9) := 'ISO-NE'; -- for Regulation Market Clearing Price

g_ET_QUERY_DAY_AHEAD VARCHAR2(30) := 'QUERY DAY-AHEAD';
g_ET_QUERY_REAL_TIME VARCHAR2(30) := 'QUERY REAL-TIME';
g_ET_QUERY_REG_CLEARING_PRICE VARCHAR2(30) := 'QUERY REGULATION CLEARING PRICE';
----------------------------------------------------------------------------------------------------
FUNCTION GET_PRICE_TYPE_CODE(p_PRICE_TYPE IN VARCHAR2) RETURN VARCHAR2 IS

	v_PRICE_TYPE_CODE VARCHAR2(64);

BEGIN

	IF p_PRICE_TYPE = MM_ISONE_UTIL.g_LMP_PRICE_TYPE THEN
		v_PRICE_TYPE_CODE := 'LMP'; -- Locational Marginal Price
	ELSIF p_PRICE_TYPE = MM_ISONE_UTIL.g_MLC_PRICE_TYPE THEN
		v_PRICE_TYPE_CODE := 'MLC';  -- Marginal Loss Component
	ELSIF p_PRICE_TYPE = MM_ISONE_UTIL.g_MCC_PRICE_TYPE THEN
		v_PRICE_TYPE_CODE := 'MCC'; -- Marginal Congestion Component
	ELSIF p_PRICE_TYPE = MM_ISONE_UTIL.g_MCP_PRICE_TYPE THEN
		v_PRICE_TYPE_CODE := 'RMCP'; -- Regulation Market Clearing Price
	END IF;

	RETURN v_PRICE_TYPE_CODE;

END GET_PRICE_TYPE_CODE;
-----------------------------------------------------------------------------------------
FUNCTION CREATE_MARKET_PRICE_NAME (
    p_SP_ID IN VARCHAR2,
	p_MARKET_TYPE IN VARCHAR2,
	p_PRICE_TYPE IN VARCHAR2,
	p_SERVICE_POINT_NAME OUT SERVICE_POINT.SERVICE_POINT_NAME%TYPE,
	p_SERVICE_POINT_ID OUT SERVICE_POINT.SERVICE_POINT_ID%TYPE,
	p_MKT_PRICE_ALIAS OUT MARKET_PRICE.MARKET_PRICE_ALIAS%TYPE
) RETURN MARKET_PRICE.MARKET_PRICE_NAME%TYPE IS

	v_MKT_PRICE_ALIAS    MARKET_PRICE.MARKET_PRICE_ALIAS%TYPE;
    v_MKT_PRICE_NAME     MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
	v_PRICE_TYPE_CODE    VARCHAR2(4);
	v_SUFFIX             VARCHAR2(8);

BEGIN

    p_MKT_PRICE_ALIAS := NULL;
    v_PRICE_TYPE_CODE := GET_PRICE_TYPE_CODE(p_PRICE_TYPE);

    -- The RMCP service point has P_SP_ID of g_ISONE_NID
    -- use external_id to find service point name and id
    SELECT SP.SERVICE_POINT_NAME, SP.SERVICE_POINT_ID
      INTO p_SERVICE_POINT_NAME, p_SERVICE_POINT_ID
      FROM SERVICE_POINT SP
     WHERE SP.EXTERNAL_IDENTIFIER = P_SP_ID;

    -- NAME is 64 long
    -- ALIAS is 32 long
    -- SUFFIX is 8 long

    IF p_MARKET_TYPE = MM_ISONE_UTIL.g_DAYAHEAD THEN
        v_SUFFIX :=  ':' || v_PRICE_TYPE_CODE || ':DA';
        v_MKT_PRICE_ALIAS := SUBSTR(p_SERVICE_POINT_NAME, 1, 24) || v_SUFFIX;
        v_MKT_PRICE_NAME := p_SERVICE_POINT_NAME || v_SUFFIX;
    ELSIF p_MARKET_TYPE = MM_ISONE_UTIL.g_REALTIME THEN
        v_SUFFIX := ':' || v_PRICE_TYPE_CODE || ':RT';
        v_MKT_PRICE_ALIAS := SUBSTR(p_SERVICE_POINT_NAME, 1, 24) || v_SUFFIX;
        v_MKT_PRICE_NAME := p_SERVICE_POINT_NAME || v_SUFFIX;
    ELSIF p_MARKET_TYPE = MM_ISONE_UTIL.g_REGULATION THEN
        v_SUFFIX := ':' || v_PRICE_TYPE_CODE;
        v_MKT_PRICE_ALIAS := 'ISO-NE' || v_SUFFIX;
        v_MKT_PRICE_NAME := 'ISO-NE' || v_SUFFIX;
	ELSE -- other
	    v_SUFFIX := ':' || v_PRICE_TYPE_CODE;
        v_MKT_PRICE_ALIAS := SUBSTR(p_SERVICE_POINT_NAME, 1, 24) || v_SUFFIX;
        v_MKT_PRICE_NAME := p_SERVICE_POINT_NAME || v_SUFFIX;
    END IF;

	p_MKT_PRICE_ALIAS := v_MKT_PRICE_ALIAS;
	RETURN v_MKT_PRICE_NAME;

EXCEPTION
    WHEN OTHERS THEN
		RETURN NULL;
END CREATE_MARKET_PRICE_NAME;

----------------------------------------------------------------------------------------------------
--
-- MARKET_TYPES:  'DayAhead', 'RealTime'
-- PRICE_TYPES:  'Locational Marginal Price', 'Marginal Congestion Component', 'Marginal Loss Component', 'Regulation Market Clearing Price'
--
FUNCTION GET_MARKET_PRICE_ID(P_SERVICE_POINT_ID IN VARCHAR2, p_MARKET_TYPE IN VARCHAR2, p_PRICE_TYPE IN VARCHAR2) RETURN NUMBER IS


    v_SERVICE_POINT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
    v_SERVICE_POINT_ID   SERVICE_POINT.SERVICE_POINT_ID%TYPE;
    v_MKT_PRICE_NAME     MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
	v_MKT_PRICE_ALIAS    MARKET_PRICE.MARKET_PRICE_ALIAS%TYPE;

	V_MKT_PRICE_ID       MARKET_PRICE.MARKET_PRICE_ID%TYPE;
	v_COMMODITY_ID       IT_COMMODITY.COMMODITY_ID%TYPE;
	v_PRICE_INTERVAL     VARCHAR2(9);
	v_MP_MARKET_TYPE     VARCHAR2(32);

BEGIN

    v_PRICE_INTERVAL := 'Hour';

	-- using external_identifier = v_MKT_PRICE_NAME as a lookup
	-- generate a unique name and alias, return service point name and id too
    v_MKT_PRICE_NAME := CREATE_MARKET_PRICE_NAME
        (p_SERVICE_POINT_ID, p_MARKET_TYPE, p_PRICE_TYPE,
        v_SERVICE_POINT_NAME, v_SERVICE_POINT_ID, v_MKT_PRICE_ALIAS);

	  IF v_MKT_PRICE_NAME IS NOT NULL THEN

      BEGIN
	  -- look for existing ID
	  SELECT MARKET_PRICE_ID
	  INTO v_MKT_PRICE_ID
	  FROM MARKET_PRICE
	  WHERE MARKET_PRICE_NAME = v_MKT_PRICE_NAME;
	  EXCEPTION
	  	WHEN NO_DATA_FOUND THEN
		v_MKT_PRICE_ID := 0;
	  END;

	  IF v_MKT_PRICE_ID = 0 THEN
	  --create a new transaction

        BEGIN

		  -- we need the commodity_id , if no record add one
		  v_COMMODITY_ID := MM_ISONE_UTIL.GET_COMMODITY_ID(p_MARKET_TYPE);
		  IF v_COMMODITY_ID = -1 THEN
			v_COMMODITY_ID := 0;
		  END IF;

		  v_MP_MARKET_TYPE := p_MARKET_TYPE;

          IO.PUT_MARKET_PRICE(O_OID                   => V_MKT_PRICE_ID,
                              P_MARKET_PRICE_NAME     => v_MKT_PRICE_NAME,
                              P_MARKET_PRICE_ALIAS    => v_MKT_PRICE_ALIAS,
                              P_MARKET_PRICE_DESC     => 'Created by MarketManager via LMP import',
                              P_MARKET_PRICE_ID       => 0,
                              P_MARKET_PRICE_TYPE     => p_PRICE_TYPE,
                              P_MARKET_PRICE_INTERVAL => v_PRICE_INTERVAL,
                              P_MARKET_TYPE           => v_MP_MARKET_TYPE,
                              p_COMMODITY_ID          => v_COMMODITY_ID,
                              P_SERVICE_POINT_TYPE    => 'Point',
                              P_EXTERNAL_IDENTIFIER   => v_MKT_PRICE_NAME,
                              P_EDC_ID                => 0,
                              P_SC_ID                 => MM_ISONE_UTIL.G_ISONE_SC_ID,
                              P_POD_ID                => v_SERVICE_POINT_ID,
                              p_ZOD_ID                => 0);
          COMMIT;

          EXCEPTION
		    WHEN OTHERS THEN
            --WHEN NO_DATA_FOUND THEN
            -- no service point, so no market price
            V_MKT_PRICE_ID := NULL;
          END;
		END IF;
    	END IF;

    RETURN V_MKT_PRICE_ID;

EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END GET_MARKET_PRICE_ID;
----------------------------------------------------------------------------------------------------
-- Import Regulation Closing Price
PROCEDURE IMPORT_RCP(p_ACTION IN VARCHAR2,
					 p_PRICE_CODE IN VARCHAR2, -- 'P' or 'A'
                     p_RECORDS     IN MEX_NE_RCP_COST_TBL,
                     p_STATUS      OUT NUMBER,
                     p_MESSAGE     OUT VARCHAR2) IS
  v_IDX           BINARY_INTEGER;
  v_MPV_ROW       MARKET_PRICE_VALUE%ROWTYPE;
  v_MARKET_TYPE VARCHAR2(32);
  v_PRICE_TYPE VARCHAR2(64);

BEGIN
  p_STATUS        := GA.SUCCESS;

  --MAKE SURE USER HAS APPROPRIATE ACCESS
  IF NOT CAN_WRITE('Data Setup') THEN
    RAISE IO.INSUFFICIENT_PRIVILEGES;
  END IF;

	 IF NOT UPPER(p_ACTION) LIKE '%REGULATION%' THEN
	 	RETURN; -- nothing to do
	 END IF;

      v_MARKET_TYPE := MM_ISONE_UTIL.g_REGULATION;
      v_PRICE_TYPE := MM_ISONE_UTIL.g_MCP_PRICE_TYPE;

      v_MPV_ROW.AS_OF_DATE  := LOW_DATE;
      v_MPV_ROW.PRICE_BASIS := NULL;

      v_IDX := p_RECORDS.FIRST;
      WHILE p_RECORDS.EXISTS(v_IDX) LOOP
          v_MPV_ROW.MARKET_PRICE_ID := GET_MARKET_PRICE_ID(g_ISONE_NID, v_MARKET_TYPE, v_PRICE_TYPE);

        IF v_MPV_ROW.MARKET_PRICE_ID IS NOT NULL
		   AND v_MPV_ROW.MARKET_PRICE_ID <> -1 THEN

            v_MPV_ROW.PRICE_DATE := p_RECORDS(v_IDX).CUT_DATE;
    		v_MPV_ROW.PRICE      := p_RECORDS(v_IDX).RCP_PRICE;
			--dbms_output.put_line(to_char(v_MPV_ROW.PRICE_DATE,'mm/dd/yyyy HH24') || ' rcp_price = ' || to_char(v_MPV_ROW.PRICE));
              BEGIN
                INSERT INTO MARKET_PRICE_VALUE
                  (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
                VALUES
                  (v_MPV_ROW.MARKET_PRICE_ID,
                   p_PRICE_CODE,
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
                     AND PRICE_CODE = p_PRICE_CODE
                     AND PRICE_DATE = v_MPV_ROW.PRICE_DATE
                     AND AS_OF_DATE = LOW_DATE;
              END;

        END IF;

        v_IDX := p_RECORDS.NEXT(v_IDX);
      END LOOP;

      IF p_STATUS = GA.SUCCESS THEN
        COMMIT;
      END IF;

  --END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    P_STATUS  := SQLCODE;
    P_MESSAGE := 'MM_ISONE_LMP.IMPORT_RCP: ' || SQLERRM;
END IMPORT_RCP;
----------------------------------------------------------------------------------------------------
-- ACTIONS:

 -- Import Locational Marginal Price
PROCEDURE IMPORT_LMP(p_ACTION IN VARCHAR2,
					 p_PRICE_CODE IN VARCHAR2, -- 'P' or 'A'
                     p_RECORDS     IN MEX_NE_LMP_TBL,
                     p_STATUS      OUT NUMBER,
                     p_MESSAGE     OUT VARCHAR2) IS
  v_IDX           BINARY_INTEGER;
  v_PRICE_IDX     BINARY_INTEGER;
  v_PRICES        MEX_NE_LMP_COST_TBL;
  v_LAST_PNODE_ID VARCHAR2(255) := 'foobar';
  v_MPV_ROW       MARKET_PRICE_VALUE%ROWTYPE;
  v_MARKET_TYPE VARCHAR2(32);
  v_PRICE_TYPE VARCHAR2(64);

BEGIN
  p_STATUS        := GA.SUCCESS;

  --MAKE SURE USER HAS APPROPRIATE ACCESS
  IF NOT CAN_WRITE('Data Setup') THEN
    RAISE IO.INSUFFICIENT_PRIVILEGES;
  END IF;

  -- v_MARKET_TYPE can be DA or RT or Regulation
  IF UPPER(p_ACTION) LIKE '%REGULATION%' THEN
    RETURN; -- nothing to do
  END IF;

  IF UPPER(p_ACTION) LIKE '%DAY-AHEAD%' THEN
	v_MARKET_TYPE := MM_ISONE_UTIL.g_DAYAHEAD;
  ELSIF UPPER(p_ACTION) LIKE '%REAL-TIME%' THEN
	v_MARKET_TYPE := MM_ISONE_UTIL.g_REALTIME;
  END IF;

  v_MPV_ROW.AS_OF_DATE  := LOW_DATE;
  v_MPV_ROW.PRICE_BASIS := NULL;

  -- four passes to get LMP_COST, MC_LOSSES, MC_CONGESTION (ENERGY_COST is ignored here)
  FOR idx IN 1 .. 3
  LOOP
	  IF idx = 1 THEN
	  	v_PRICE_TYPE := MM_ISONE_UTIL.g_LMP_PRICE_TYPE;
	  ELSIF idx = 2 THEN
	  	v_PRICE_TYPE := MM_ISONE_UTIL.g_MLC_PRICE_TYPE;
	  ELSIF idx = 3 THEN
	  	v_PRICE_TYPE := MM_ISONE_UTIL.g_MCC_PRICE_TYPE;
	  END IF;

      v_IDX := p_RECORDS.FIRST;
      WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        IF v_LAST_PNODE_ID != to_char(p_RECORDS(v_IDX).LOCATION_NID) THEN
          v_LAST_PNODE_ID  := to_char(p_RECORDS(v_IDX).LOCATION_NID);
          v_MPV_ROW.MARKET_PRICE_ID := GET_MARKET_PRICE_ID(p_RECORDS(v_IDX).LOCATION_NID, v_MARKET_TYPE, v_PRICE_TYPE);
        END IF;

        IF v_MPV_ROW.MARKET_PRICE_ID IS NOT NULL
		   AND v_MPV_ROW.MARKET_PRICE_ID <> -1 THEN

          v_PRICES    := p_RECORDS(v_IDX).COSTS;
          v_PRICE_IDX := v_PRICES.FIRST;
          WHILE v_PRICES.EXISTS(v_PRICE_IDX) LOOP
            v_MPV_ROW.PRICE_DATE := v_PRICES(v_PRICE_IDX).CUT_DATE;

    		IF idx = 1 THEN
            	v_MPV_ROW.PRICE      := v_PRICES(v_PRICE_IDX).LMP_COST;
    		ELSIF idx = 2 THEN
    			v_MPV_ROW.PRICE      := v_PRICES(v_PRICE_IDX).MC_LOSSES;
    		ELSIF idx = 3 THEN
				v_MPV_ROW.PRICE      := v_PRICES(v_PRICE_IDX).MC_CONGESTION;
    		END IF;


              BEGIN
                INSERT INTO MARKET_PRICE_VALUE
                  (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
                VALUES
                  (v_MPV_ROW.MARKET_PRICE_ID,
                   p_PRICE_CODE,
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
                     AND PRICE_CODE = p_PRICE_CODE
                     AND PRICE_DATE = v_MPV_ROW.PRICE_DATE
                     AND AS_OF_DATE = LOW_DATE;
              END;


            v_PRICE_IDX := v_PRICES.NEXT(v_PRICE_IDX);
          END LOOP;
        END IF;

        v_IDX := p_RECORDS.NEXT(v_IDX);
      END LOOP;

      IF p_STATUS = GA.SUCCESS THEN
        COMMIT;
      END IF;

  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    P_STATUS  := SQLCODE;
    P_MESSAGE := 'MM_ISONE_LMP.IMPORT_LMP: ' || SQLERRM;
END IMPORT_LMP;
----------------------------------------------------------------------------------------------------
-- ACTIONS:

 -- Query Locational Marginal Price (or Regulation Closing Price) and then import it
PROCEDURE QUERY_LMP(p_ACTION IN VARCHAR2,
					  p_PRICE_TYPE IN VARCHAR2, -- 'P' or 'A'
                      p_DATE        IN DATE,
                      p_STATUS      OUT NUMBER,
                      p_MESSAGE     OUT VARCHAR2) IS

    v_RCP_TBL           MEX_NE_RCP_COST_TBL;
	v_LMP_TBL           MEX_NE_LMP_TBL;
    v_EXT_CREDS        EXTERNAL_CREDENTIAL_TBL;

BEGIN
    p_STATUS           := GA.SUCCESS;
    v_EXT_CREDS := MM_UTIL.GET_CREDENTIALS('Proxy');

	IF p_ACTION =  MEX_ISONE.g_REG_CLR_PRICE THEN
    	MEX_ISONE_LMP.FETCH_RCP(p_DATE,
                                p_ACTION,
                                v_EXT_CREDS,
                                v_RCP_TBL,
                                p_STATUS,
                                p_MESSAGE);
    	IF p_STATUS = GA.SUCCESS THEN
          IMPORT_RCP(p_ACTION, p_PRICE_TYPE, v_RCP_TBL, p_STATUS, p_MESSAGE);
        END IF;
	ELSIF p_ACTION = MEX_ISONE.g_DA_LMP OR p_ACTION = MEX_ISONE.g_RT_LMP THEN
    	MEX_ISONE_LMP.FETCH_LMP(p_DATE,
                                p_ACTION,
                                v_EXT_CREDS,
                                v_LMP_TBL,
                                p_STATUS,
                                p_MESSAGE);
    	IF p_STATUS = GA.SUCCESS THEN
          IMPORT_LMP(p_ACTION, p_PRICE_TYPE, v_LMP_TBL, p_STATUS, p_MESSAGE);
        END IF;
	ELSE
		NULL;
	END IF;

EXCEPTION
    WHEN OTHERS THEN
      p_MESSAGE := SQLERRM;
      p_STATUS  := GA.GENERAL_EXCEPTION;

END QUERY_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER,	
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS
	
	v_CURRENT_DATE        DATE;
	v_LOG_ONLY            NUMBER(1) := 0;
	v_ACTION              VARCHAR2(64);
	v_NO_SUBMIT           BOOLEAN := FALSE;
    V_MARKET_TYPE         VARCHAR2(64);
	v_PRICE_TYPE          VARCHAR2(6);
BEGIN
		SECURITY_CONTROLS.SET_IS_INTERFACE(TRUE);
		--Check for testing mode.
		IF SUBSTR(p_EXCHANGE_TYPE, 1, 5) = 'TEST ' THEN
			v_ACTION   := UPPER(TRIM(SUBSTR(p_EXCHANGE_TYPE, 6)));
			v_LOG_ONLY := 1;
		ELSE
			v_ACTION := UPPER(p_EXCHANGE_TYPE);
		END IF;

        --LOOP OVER DATES
        v_CURRENT_DATE := TRUNC(p_BEGIN_DATE);
        LOOP

            v_PRICE_TYPE := 'A'; -- Actual
            CASE v_ACTION
            WHEN 'QUERY DAY-AHEAD' THEN
            	v_MARKET_TYPE :=  MEX_ISONE.g_DA_LMP;
            WHEN 'QUERY REAL-TIME' THEN
            	v_MARKET_TYPE :=  MEX_ISONE.g_RT_LMP;
            WHEN 'QUERY REGULATION CLEARING PRICE' THEN
            	v_MARKET_TYPE :=  MEX_ISONE.g_REG_CLR_PRICE;
            ELSE
            	p_STATUS    := GA.GENERAL_EXCEPTION;
            	p_MESSAGE   := v_ACTION || ' is not a valid Action.';
            	v_NO_SUBMIT := TRUE;
            END CASE;

            IF NOT NVL(v_NO_SUBMIT, TRUE) THEN
            	QUERY_LMP(v_MARKET_TYPE, v_PRICE_TYPE, v_CURRENT_DATE, p_STATUS, p_MESSAGE);
            END IF;

            EXIT WHEN v_CURRENT_DATE >= TRUNC(p_END_DATE);
            v_CURRENT_DATE := v_CURRENT_DATE + 1;

        END LOOP; -- day loop

		--SET p_STATUS TO SHOW AN APPROPRIATE MESSAGE;
		IF p_MESSAGE IS NOT NULL THEN
			p_STATUS := GA.GENERAL_EXCEPTION; -- TO RAISE ERROR TO GUI.
		ELSIF v_LOG_ONLY = 1 THEN
			p_STATUS  := GA.SUCCESS;
			p_MESSAGE := 'Test successful.  See Exchange Log for details.';
		ELSE
			p_STATUS := GA.SUCCESS;
		END IF;
		SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
EXCEPTION
		WHEN OTHERS THEN
			p_MESSAGE := SQLERRM;
			p_STATUS  := GA.GENERAL_EXCEPTION;
			SECURITY_CONTROLS.SET_IS_INTERFACE(FALSE);
END MARKET_EXCHANGE;
------------------------------------------------------------------------------------------
END MM_ISONE_LMP;
/
