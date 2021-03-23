CREATE OR REPLACE PACKAGE BODY MM_PJM_LMP IS

  -- Author  : LDUMITRIU
  -- Created : 2/8/2005 9:55:40 AM
  -- Purpose :

  -- Public type declarations
  G_PJM_SC_ID SC.SC_ID%TYPE;
  g_ENERGY_COMPONENT VARCHAR2(16) := 'Energy Component';
  g_CONG_COMPONENT VARCHAR2(32) := 'Marginal Congestion Component';
  g_LOSS_COMPONENT VARCHAR2(32) := 'Marginal Loss Component';
  g_LMP VARCHAR2(32) := 'Locational Marginal Price';
  g_MARGINAL_LOSS_DATE DATE := DATE '2007-06-01';
  g_RESIDUAL_PRICE_DATE DATE := TO_DATE(NVL(GET_DICTIONARY_VALUE('Date', 0, 'MarketExchange', 'PJM', 'LMP', 'Residual Price'),'01-JUN-2015'),'DD-MON-YYYY');  -- '01-JUN-2015;
  g_RESIDUAL_PNODE_ID VARCHAR2(32) :=  TRIM(SUBSTR(NVL(GET_DICTIONARY_VALUE('Residual PNode ID', 0, 'MarketExchange', 'PJM', 'LMP', 'Residual Price'),'116472949'),1,16));
  g_PECO_PNODE_ID VARCHAR2(32) :=  TRIM(SUBSTR(NVL(GET_DICTIONARY_VALUE('PECO PNode ID', 0, 'MarketExchange', 'PJM', 'LMP', 'Residual Price'),'51297'),1,16));

  ----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------

FUNCTION GET_MARKET_PRICE_ID(P_EXTERNAL_ID IN VARCHAR2,
    p_MARKET_TYPE IN VARCHAR2,
    p_MARKET_PRICE_TYPE IN VARCHAR2) RETURN NUMBER IS

v_MKT_PRICE_ID       MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_SERVICE_POINT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
v_SERVICE_POINT_ID   SERVICE_POINT.SERVICE_POINT_ID%TYPE;
v_MKT_PRICE_NAME     MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
v_NAME VARCHAR2(32);
v_EXT_ID VARCHAR2(32);
BEGIN
    IF p_MARKET_PRICE_TYPE = g_ENERGY_COMPONENT THEN
        IF p_MARKET_TYPE = MM_PJM_UTIL.g_DAYAHEAD THEN
            v_NAME := 'PJM:Energy Component:DA';
            v_EXT_ID := 'SystemEnergyPrice:DA';
        ELSE --MM_PJM_UTIL.g_REALTIME
            v_NAME := 'PJM:Energy Component:RT';
            v_EXT_ID := 'SystemEnergyPrice:RT';
        END IF;
        BEGIN
            SELECT MP.MARKET_PRICE_ID
            INTO v_MKT_PRICE_ID
            FROM MARKET_PRICE MP
            WHERE MP.MARKET_PRICE_NAME = v_NAME;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                --create it
                IO.PUT_MARKET_PRICE(O_OID               => v_MKT_PRICE_ID,
                              P_MARKET_PRICE_NAME     => v_NAME,
                              P_MARKET_PRICE_ALIAS    => v_NAME,
                              P_MARKET_PRICE_DESC     => 'Created by MarketManager via LMP import',
                              P_MARKET_PRICE_ID       => 0,
                              P_MARKET_PRICE_TYPE     => p_MARKET_PRICE_TYPE,
                              P_MARKET_PRICE_INTERVAL => 'Hour',
                              P_MARKET_TYPE           => P_MARKET_TYPE,
                              p_COMMODITY_ID          => 0,
                              P_SERVICE_POINT_TYPE    => '?',
                              P_EXTERNAL_IDENTIFIER   => v_EXT_ID,
                              P_EDC_ID                => 0,
                              P_SC_ID                 => G_PJM_SC_ID,
                              P_POD_ID                => 0,
                              p_ZOD_ID                => 0);
            COMMIT;
        END;
    ELSE

        BEGIN
          SELECT MP.MARKET_PRICE_ID
            INTO v_MKT_PRICE_ID
            FROM MARKET_PRICE MP, SERVICE_POINT SP
           WHERE MP.POD_ID = SP.SERVICE_POINT_ID
             AND SP.EXTERNAL_IDENTIFIER = p_EXTERNAL_ID
             AND MP.MARKET_PRICE_TYPE = p_MARKET_PRICE_TYPE
             AND MP.MARKET_TYPE = p_MARKET_TYPE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
            -- if there's a service point but no market price, create the market price
                BEGIN
                    SELECT SP.SERVICE_POINT_NAME, SP.SERVICE_POINT_ID
                    INTO v_SERVICE_POINT_NAME, v_SERVICE_POINT_ID
                    FROM SERVICE_POINT SP
                    WHERE SP.EXTERNAL_IDENTIFIER = P_EXTERNAL_ID;

                    IF p_MARKET_PRICE_TYPE = 'FTR Zonal LMP' THEN
                        v_MKT_PRICE_NAME := SUBSTR(v_SERVICE_POINT_NAME || ' FTR Zonal', 1, 32);
                    ELSIF p_MARKET_PRICE_TYPE = 'FTR Zonal Congestion Price' THEN
                        v_MKT_PRICE_NAME := SUBSTR(v_SERVICE_POINT_NAME || ' FTR Zonal Congestion Price', 1, 32);
                    ELSE
                        IF UPPER(p_MARKET_TYPE) LIKE 'DAY%' AND p_MARKET_PRICE_TYPE = g_LMP THEN
                            v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':LMP:DA', 1, 64);
                        ELSIF UPPER(p_MARKET_TYPE) LIKE 'REAL%' AND p_MARKET_PRICE_TYPE = g_LMP THEN
                            v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':LMP:RT', 1, 64);
                        ELSIF UPPER(p_MARKET_TYPE) LIKE 'DAY%' AND p_MARKET_PRICE_TYPE = g_CONG_COMPONENT THEN
                            v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MCC:DA', 1, 64);
                        ELSIF UPPER(p_MARKET_TYPE) LIKE 'REAL%' AND p_MARKET_PRICE_TYPE = g_CONG_COMPONENT THEN
                            v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MCC:RT', 1, 64);
                        ELSIF UPPER(p_MARKET_TYPE) LIKE 'DAY%' AND p_MARKET_PRICE_TYPE = g_LOSS_COMPONENT THEN
                            v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MLC:DA', 1, 64);
                        ELSIF UPPER(p_MARKET_TYPE) LIKE 'REAL%' AND p_MARKET_PRICE_TYPE = g_LOSS_COMPONENT THEN
                            v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MLC:RT', 1, 64);
                        ELSE
                            NULL;
                        END IF;
                    END IF;

                    IO.PUT_MARKET_PRICE(O_OID         => V_MKT_PRICE_ID,
                              P_MARKET_PRICE_NAME     => v_MKT_PRICE_NAME,
                              P_MARKET_PRICE_ALIAS    => v_MKT_PRICE_NAME,
                              P_MARKET_PRICE_DESC     => 'Created by MarketManager via LMP import',
                              P_MARKET_PRICE_ID       => 0,
                              P_MARKET_PRICE_TYPE     => p_MARKET_PRICE_TYPE,
                              P_MARKET_PRICE_INTERVAL => 'Hour',
                              P_MARKET_TYPE           => P_MARKET_TYPE,
                              p_COMMODITY_ID          => 0,
                              P_SERVICE_POINT_TYPE    => 'Point',
                              P_EXTERNAL_IDENTIFIER   => P_EXTERNAL_ID,
                              P_EDC_ID                => 0,
                              P_SC_ID                 => G_PJM_SC_ID,
                              P_POD_ID                => v_SERVICE_POINT_ID,
                              p_ZOD_ID                => 0);
                    COMMIT;
                EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                    -- no service point, so no market price
                        v_MKT_PRICE_ID := NULL;
                END;
        END;
    END IF;

    RETURN v_MKT_PRICE_ID;

EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END GET_MARKET_PRICE_ID;
--------------------------------------------------------------------------------
  --@@ 2015-04-16
FUNCTION IS_POPULATE(
    p_PNODE_ID IN VARCHAR2,
    p_DATE IN DATE
    ) RETURN BOOLEAN IS

v_POPULATE BOOLEAN := FALSE;

BEGIN


  v_POPULATE := (p_PNODE_ID NOT IN (g_PECO_PNODE_ID, g_RESIDUAL_PNODE_ID)
             OR (p_DATE >= (g_RESIDUAL_PRICE_DATE)  AND p_PNODE_ID = g_RESIDUAL_PNODE_ID)
             OR (p_DATE < (g_RESIDUAL_PRICE_DATE+(1/86400))  AND p_PNODE_ID = g_PECO_PNODE_ID));

  IF LOGS.IS_DEBUG_ENABLED THEN
     LOGS.LOG_INFO(p_PNODE_ID||' g_RESIDUAL_PRICE_DATE = '||TO_CHAR(g_RESIDUAL_PRICE_DATE,'MM/DD/YYYY HH24:MI')|| ' PRICE_DATE='||TO_CHAR(p_DATE,'MM/DD/YYYY HH24:MI'));
  END IF;
  RETURN v_POPULATE;
END;
--------------------------------------------------------------------------------
FUNCTION GET_MARKET_PRICE_ID_RSD(
    P_EXTERNAL_ID IN VARCHAR2,
    p_MARKET_TYPE IN VARCHAR2,
    p_MARKET_PRICE_TYPE IN VARCHAR2
    ) RETURN NUMBER IS

v_MKT_PRICE_ID       MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_SERVICE_POINT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
v_SERVICE_POINT_ID   SERVICE_POINT.SERVICE_POINT_ID%TYPE;
v_MKT_PRICE_NAME     MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
v_NAME VARCHAR2(32);
v_EXT_ID VARCHAR2(32) := p_EXTERNAL_ID;

BEGIN

  IF p_EXTERNAL_ID = g_RESIDUAL_PNODE_ID THEN
     v_EXT_ID := g_PECO_PNODE_ID;
  END IF;

  BEGIN

      SELECT MP.MARKET_PRICE_ID
        INTO v_MKT_PRICE_ID
        FROM MARKET_PRICE MP, SERVICE_POINT SP
       WHERE MP.POD_ID = SP.SERVICE_POINT_ID
         AND SP.EXTERNAL_IDENTIFIER = v_EXT_ID  ---p_EXTERNAL_ID
         AND MP.MARKET_PRICE_TYPE = p_MARKET_PRICE_TYPE
         AND MP.MARKET_TYPE = p_MARKET_TYPE;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        -- if there's a service point but no market price, create the market price
            BEGIN
                SELECT SP.SERVICE_POINT_NAME, SP.SERVICE_POINT_ID
                INTO v_SERVICE_POINT_NAME, v_SERVICE_POINT_ID
                FROM SERVICE_POINT SP
                WHERE SP.EXTERNAL_IDENTIFIER = P_EXTERNAL_ID;

                IF p_MARKET_PRICE_TYPE = 'FTR Zonal LMP' THEN
                    v_MKT_PRICE_NAME := SUBSTR(v_SERVICE_POINT_NAME || ' FTR Zonal', 1, 32);
                ELSIF p_MARKET_PRICE_TYPE = 'FTR Zonal Congestion Price' THEN
                    v_MKT_PRICE_NAME := SUBSTR(v_SERVICE_POINT_NAME || ' FTR Zonal Congestion Price', 1, 32);
                ELSE
                    IF UPPER(p_MARKET_TYPE) LIKE 'DAY%' AND p_MARKET_PRICE_TYPE = g_LMP THEN
                        v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':LMP:DA', 1, 64);
                    ELSIF UPPER(p_MARKET_TYPE) LIKE 'REAL%' AND p_MARKET_PRICE_TYPE = g_LMP THEN
                        v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':LMP:RT', 1, 64);
                    ELSIF UPPER(p_MARKET_TYPE) LIKE 'DAY%' AND p_MARKET_PRICE_TYPE = g_CONG_COMPONENT THEN
                        v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MCC:DA', 1, 64);
                    ELSIF UPPER(p_MARKET_TYPE) LIKE 'REAL%' AND p_MARKET_PRICE_TYPE = g_CONG_COMPONENT THEN
                        v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MCC:RT', 1, 64);
                    ELSIF UPPER(p_MARKET_TYPE) LIKE 'DAY%' AND p_MARKET_PRICE_TYPE = g_LOSS_COMPONENT THEN
                        v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MLC:DA', 1, 64);
                    ELSIF UPPER(p_MARKET_TYPE) LIKE 'REAL%' AND p_MARKET_PRICE_TYPE = g_LOSS_COMPONENT THEN
                        v_MKT_PRICE_NAME := SUBSTR('PJM:' || v_SERVICE_POINT_NAME || ':MLC:RT', 1, 64);
                    ELSE
                        NULL;
                    END IF;
                END IF;

                IO.PUT_MARKET_PRICE(O_OID         => V_MKT_PRICE_ID,
                          P_MARKET_PRICE_NAME     => v_MKT_PRICE_NAME,
                          P_MARKET_PRICE_ALIAS    => v_MKT_PRICE_NAME,
                          P_MARKET_PRICE_DESC     => 'Created by MarketManager via LMP import',
                          P_MARKET_PRICE_ID       => 0,
                          P_MARKET_PRICE_TYPE     => p_MARKET_PRICE_TYPE,
                          P_MARKET_PRICE_INTERVAL => 'Hour',
                          P_MARKET_TYPE           => P_MARKET_TYPE,
                          p_COMMODITY_ID          => 0,
                          P_SERVICE_POINT_TYPE    => 'Point',
                          P_EXTERNAL_IDENTIFIER   => P_EXTERNAL_ID,
                          P_EDC_ID                => 0,
                          P_SC_ID                 => G_PJM_SC_ID,
                          P_POD_ID                => v_SERVICE_POINT_ID,
                          p_ZOD_ID                => 0);
                COMMIT;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                -- no service point, so no market price
                    v_MKT_PRICE_ID := NULL;
            END;
    END;

    RETURN v_MKT_PRICE_ID;

EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
END GET_MARKET_PRICE_ID_RSD;
------------------------------------------------------
PROCEDURE IMPORT_LMP(p_MARKET_TYPE IN VARCHAR2,
                     p_RECORDS     IN MEX_PJM_LMP_OBJ_TBL,
                     p_MONTHLY         IN NUMBER,
                     p_STATUS      OUT NUMBER,
                     p_MESSAGE     OUT VARCHAR2) IS
  v_IDX           BINARY_INTEGER;
  v_PRICE_IDX     BINARY_INTEGER;
  v_PRICES        PRICE_QUANTITY_SUMMARY_TABLE;
  v_LAST_PNODE_ID VARCHAR2(255) := 'foobar';
  v_MPV_ROW       MARKET_PRICE_VALUE%ROWTYPE;
  v_MARKET_TYPE   VARCHAR2(32);

  TYPE ARRAY IS VARRAY(3) OF VARCHAR2(1);
  v_PRICE_CODE_ARRAY ARRAY;

BEGIN
  p_STATUS := GA.SUCCESS;

  IF p_MONTHLY = 0 THEN
    v_PRICE_CODE_ARRAY := ARRAY('A', 'F', 'P');
  ELSE
    v_PRICE_CODE_ARRAY := ARRAY('A');
  END IF;

  IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
    v_MARKET_TYPE := MM_PJM_UTIL.g_DAYAHEAD;
  ELSE
    v_MARKET_TYPE := MM_PJM_UTIL.g_REALTIME;
  END IF;

  v_MPV_ROW.AS_OF_DATE  := LOW_DATE;
  v_MPV_ROW.PRICE_BASIS := NULL;

  v_IDX := p_RECORDS.FIRST;
  WHILE p_RECORDS.EXISTS(v_IDX) LOOP
    IF v_LAST_PNODE_ID != p_RECORDS(v_IDX).PNODEID THEN
      v_LAST_PNODE_ID           := p_RECORDS(v_IDX).PNODEID;
      v_MPV_ROW.MARKET_PRICE_ID := GET_MARKET_PRICE_ID(p_RECORDS(v_IDX).PNODEID, v_MARKET_TYPE, 'Locational Marginal Price');
    END IF;

    IF v_MPV_ROW.MARKET_PRICE_ID IS NOT NULL THEN
      v_PRICES    := p_RECORDS(v_IDX).PRICE_TBL;
      v_PRICE_IDX := v_PRICES.FIRST;
      WHILE v_PRICES.EXISTS(v_PRICE_IDX) LOOP
        v_MPV_ROW.PRICE_DATE := TO_CUT_WITH_OPTIONS(v_PRICES(v_PRICE_IDX).SCHEDULE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
        v_MPV_ROW.PRICE      := v_PRICES(v_PRICE_IDX).PRICE;

        FOR I IN v_PRICE_CODE_ARRAY.FIRST .. v_PRICE_CODE_ARRAY.LAST LOOP
          BEGIN
            INSERT INTO MARKET_PRICE_VALUE
              (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
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

  IF p_STATUS >= 0 THEN
    COMMIT;
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    P_STATUS  := SQLCODE;
    P_MESSAGE := 'MM_PJM_LMP.IMPORT_LMP: ' || UT.GET_FULL_ERRM;
END IMPORT_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LMP_ML
    (
    p_MARKET_TYPE IN VARCHAR2,
    p_ENG_RECORDS IN PRICE_QUANTITY_SUMMARY_TABLE,
    p_RECORDS IN MEX_PJM_LMP_ML_OBJ_TBL,
    p_MONTHLY IN NUMBER,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) IS
v_IDX BINARY_INTEGER;
v_TTL_PRICE_IDX BINARY_INTEGER;
v_CONG_PRICE_IDX BINARY_INTEGER;
v_LOSS_PRICE_IDX BINARY_INTEGER;
v_TOTAL_PRICES PRICE_QUANTITY_SUMMARY_TABLE;
v_CONG_PRICES PRICE_QUANTITY_SUMMARY_TABLE;
v_LOSS_PRICES PRICE_QUANTITY_SUMMARY_TABLE;
v_LAST_PNODE_ID VARCHAR2(255) := '?';
v_MPV_ROW MARKET_PRICE_VALUE%ROWTYPE;
v_MARKET_TYPE VARCHAR2(32);
v_MP_ID_LMP MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_MP_ID_MCC MARKET_PRICE.MARKET_PRICE_ID%TYPE;
v_MP_ID_MLC MARKET_PRICE.MARKET_PRICE_ID%TYPE;

TYPE ARRAY IS VARRAY(3) OF VARCHAR2(1);
v_PRICE_CODE_ARRAY ARRAY;

BEGIN
    p_STATUS := GA.SUCCESS;

    IF p_MONTHLY = 0 THEN
        v_PRICE_CODE_ARRAY := ARRAY('A', 'F', 'P');
    ELSE
        v_PRICE_CODE_ARRAY := ARRAY('A');
    END IF;

    IF UPPER(p_MARKET_TYPE) LIKE 'D%' THEN
        v_MARKET_TYPE := MM_PJM_UTIL.g_DAYAHEAD;
    ELSE
        v_MARKET_TYPE := MM_PJM_UTIL.g_REALTIME;
    END IF;

    v_MPV_ROW.AS_OF_DATE  := LOW_DATE;
    v_MPV_ROW.PRICE_BASIS := NULL;

    v_IDX := p_ENG_RECORDS.FIRST;
    WHILE p_ENG_RECORDS.EXISTS(v_IDX) LOOP
        v_MPV_ROW.MARKET_PRICE_ID := GET_MARKET_PRICE_ID(NULL, v_MARKET_TYPE, 'Energy Component');
        v_MPV_ROW.PRICE_DATE := TO_CUT_WITH_OPTIONS(p_ENG_RECORDS(v_IDX).SCHEDULE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
        v_MPV_ROW.PRICE := p_ENG_RECORDS(v_IDX).PRICE;

        FOR I IN v_PRICE_CODE_ARRAY.FIRST .. v_PRICE_CODE_ARRAY.LAST LOOP
            BEGIN
                INSERT INTO MARKET_PRICE_VALUE
                (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
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
        v_IDX := p_ENG_RECORDS.NEXT(v_IDX);
    END LOOP;

    v_IDX := p_RECORDS.FIRST;
    WHILE p_RECORDS.EXISTS(v_IDX) LOOP
        IF v_LAST_PNODE_ID != p_RECORDS(v_IDX).PNODEID THEN
            v_LAST_PNODE_ID := p_RECORDS(v_IDX).PNODEID;
            -- @@
            v_MP_ID_LMP := GET_MARKET_PRICE_ID_RSD(p_RECORDS(v_IDX).PNODEID, v_MARKET_TYPE, g_LMP);
            v_MP_ID_MCC := GET_MARKET_PRICE_ID_RSD(p_RECORDS(v_IDX).PNODEID, v_MARKET_TYPE, g_CONG_COMPONENT);
            v_MP_ID_MLC := GET_MARKET_PRICE_ID_RSD(p_RECORDS(v_IDX).PNODEID, v_MARKET_TYPE, g_LOSS_COMPONENT);
            -- @@
        END IF;

        v_TOTAL_PRICES := p_RECORDS(v_IDX).TOTAL_PRICE_TBL;
        v_CONG_PRICES := p_RECORDS(v_IDX).CONG_PRICE_TBL;
        v_LOSS_PRICES := p_RECORDS(v_IDX).LOSS_PRICE_TBL;

        --Total LMP
        IF v_MP_ID_LMP IS NOT NULL THEN
            v_TTL_PRICE_IDX := v_TOTAL_PRICES.FIRST;
            WHILE v_TOTAL_PRICES.EXISTS(v_TTL_PRICE_IDX) LOOP
              -- @@
               IF IS_POPULATE(v_LAST_PNODE_ID, v_TOTAL_PRICES(v_TTL_PRICE_IDX).SCHEDULE_DATE) THEN
              --@@
                 v_MPV_ROW.PRICE_DATE := TO_CUT_WITH_OPTIONS(v_TOTAL_PRICES(v_TTL_PRICE_IDX).SCHEDULE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
                 v_MPV_ROW.PRICE := v_TOTAL_PRICES(v_TTL_PRICE_IDX).PRICE;

                 FOR I IN v_PRICE_CODE_ARRAY.FIRST .. v_PRICE_CODE_ARRAY.LAST LOOP
                    BEGIN
                        INSERT INTO MARKET_PRICE_VALUE
                        (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
                        VALUES
                        (v_MP_ID_LMP,
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
                        WHERE MARKET_PRICE_ID = v_MP_ID_LMP
                        AND PRICE_CODE = v_PRICE_CODE_ARRAY(I)
                        AND PRICE_DATE = v_MPV_ROW.PRICE_DATE
                        AND AS_OF_DATE = LOW_DATE;
                    END;
                 END LOOP;
               END IF;
               v_TTL_PRICE_IDX := v_TOTAL_PRICES.NEXT(v_TTL_PRICE_IDX);
            END LOOP;
        END IF;

        --Congestion Price
        IF v_MP_ID_MCC IS NOT NULL THEN
            v_CONG_PRICE_IDX := v_CONG_PRICES.FIRST;
            WHILE v_CONG_PRICES.EXISTS(v_CONG_PRICE_IDX) LOOP
              -- @@
              IF IS_POPULATE(v_LAST_PNODE_ID, v_CONG_PRICES(v_CONG_PRICE_IDX).SCHEDULE_DATE) THEN
              --@@
                v_MPV_ROW.PRICE_DATE := TO_CUT_WITH_OPTIONS(v_CONG_PRICES(v_CONG_PRICE_IDX).SCHEDULE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
                v_MPV_ROW.PRICE := v_CONG_PRICES(v_CONG_PRICE_IDX).PRICE;

                FOR I IN v_PRICE_CODE_ARRAY.FIRST .. v_PRICE_CODE_ARRAY.LAST LOOP
                    BEGIN
                        INSERT INTO MARKET_PRICE_VALUE
                        (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
                        VALUES
                        (v_MP_ID_MCC,
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
                        WHERE MARKET_PRICE_ID = v_MP_ID_MCC
                        AND PRICE_CODE = v_PRICE_CODE_ARRAY(I)
                        AND PRICE_DATE = v_MPV_ROW.PRICE_DATE
                        AND AS_OF_DATE = LOW_DATE;
                    END;
                END LOOP;
              END IF;
              v_CONG_PRICE_IDX := v_CONG_PRICES.NEXT(v_CONG_PRICE_IDX);
            END LOOP;
        END IF;

        --Loss Price
        IF v_MP_ID_MLC IS NOT NULL THEN
            v_LOSS_PRICE_IDX := v_LOSS_PRICES.FIRST;
            WHILE v_LOSS_PRICES.EXISTS(v_LOSS_PRICE_IDX) LOOP
              -- @@
              IF IS_POPULATE(v_LAST_PNODE_ID, v_LOSS_PRICES(v_LOSS_PRICE_IDX).SCHEDULE_DATE) THEN
              --@@
                v_MPV_ROW.PRICE_DATE := TO_CUT_WITH_OPTIONS(v_LOSS_PRICES(v_LOSS_PRICE_IDX).SCHEDULE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
                v_MPV_ROW.PRICE := v_LOSS_PRICES(v_LOSS_PRICE_IDX).PRICE;

                FOR I IN v_PRICE_CODE_ARRAY.FIRST .. v_PRICE_CODE_ARRAY.LAST LOOP
                    BEGIN
                        INSERT INTO MARKET_PRICE_VALUE
                        (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
                        VALUES
                        (v_MP_ID_MLC,
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
                        WHERE MARKET_PRICE_ID = v_MP_ID_MLC
                        AND PRICE_CODE = v_PRICE_CODE_ARRAY(I)
                        AND PRICE_DATE = v_MPV_ROW.PRICE_DATE
                        AND AS_OF_DATE = LOW_DATE;
                    END;
                END LOOP;
              END IF;
              v_LOSS_PRICE_IDX := v_LOSS_PRICES.NEXT(v_LOSS_PRICE_IDX);
            END LOOP;
        END IF;

        v_IDX := p_RECORDS.NEXT(v_IDX);
    END LOOP;

    IF p_STATUS >= 0 THEN
        COMMIT;
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    P_STATUS  := SQLCODE;
    P_MESSAGE := 'MM_PJM_LMP.IMPORT_LMP_ML: ' || UT.GET_FULL_ERRM;
END IMPORT_LMP_ML;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_FTR_ZONAL_LMP
        (
        p_DATE IN DATE,
        p_RECORDS     IN MEX_PJM_LMP_OBJ_TBL,
        p_STATUS      OUT NUMBER,
        p_MESSAGE     OUT VARCHAR2
        ) IS
v_IDX           BINARY_INTEGER;
v_PRICE_IDX     BINARY_INTEGER;
v_PRICES        PRICE_QUANTITY_SUMMARY_TABLE;
v_LAST_PNODE_ID VARCHAR2(255) := 'foobar';
v_MPV_ROW       MARKET_PRICE_VALUE%ROWTYPE;
v_MARKET_TYPE   VARCHAR2(32);
v_NODENAME PJM_EMKT_PNODES.NODENAME%TYPE;
v_PNODE_ID PJM_EMKT_PNODES.NODETYPE%TYPE;
TYPE ARRAY IS VARRAY(3) OF VARCHAR2(1);
v_PRICE_CODE_ARRAY ARRAY;

BEGIN
      p_STATUS := GA.SUCCESS;
    v_PRICE_CODE_ARRAY := ARRAY('A', 'F', 'P');
      v_MARKET_TYPE := MM_PJM_UTIL.g_DAYAHEAD;

      v_MPV_ROW.AS_OF_DATE  := LOW_DATE;
      v_MPV_ROW.PRICE_BASIS := NULL;

      v_IDX := p_RECORDS.FIRST;
      WHILE p_RECORDS.EXISTS(v_IDX) LOOP
    IF v_LAST_PNODE_ID != p_RECORDS(v_IDX).PNODEID THEN
        v_LAST_PNODE_ID := p_RECORDS(v_IDX).PNODEID;
            v_NODENAME := NVL(GET_DICTIONARY_VALUE(v_LAST_PNODE_ID, 1, 'MarketExchange', 'PJM', 'Corrected NodeName'), v_LAST_PNODE_ID);
            SELECT P.PNODEID INTO v_PNODE_ID
            FROM PJM_EMKT_PNODES P
            WHERE P.NODENAME = v_NODENAME;

        IF p_DATE >= g_MARGINAL_LOSS_DATE THEN
            v_MPV_ROW.MARKET_PRICE_ID := GET_MARKET_PRICE_ID(v_PNODE_ID, v_MARKET_TYPE, 'FTR Zonal Congestion Price');
        ELSE
            v_MPV_ROW.MARKET_PRICE_ID := GET_MARKET_PRICE_ID(v_PNODE_ID, v_MARKET_TYPE, 'FTR Zonal LMP');
        END IF;
    END IF;

    IF v_MPV_ROW.MARKET_PRICE_ID IS NOT NULL THEN
        v_PRICES    := p_RECORDS(v_IDX).PRICE_TBL;
        v_PRICE_IDX := v_PRICES.FIRST;
        WHILE v_PRICES.EXISTS(v_PRICE_IDX) LOOP
            v_MPV_ROW.PRICE_DATE := TO_CUT_WITH_OPTIONS(v_PRICES(v_PRICE_IDX).SCHEDULE_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE, MM_PJM_UTIL.g_DST_SPRING_AHEAD_OPTION);
            v_MPV_ROW.PRICE      := v_PRICES(v_PRICE_IDX).PRICE;

            FOR I IN v_PRICE_CODE_ARRAY.FIRST .. v_PRICE_CODE_ARRAY.LAST LOOP
              BEGIN
                INSERT INTO MARKET_PRICE_VALUE
                  (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE, PRICE_BASIS, PRICE)
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

    IF p_STATUS >= 0 THEN
        COMMIT;
    END IF;
EXCEPTION
  WHEN OTHERS THEN
    P_STATUS  := SQLCODE;
    P_MESSAGE := 'MM_PJM_LMP.IMPORT_FTR_ZONAL_LMP: ' || UT.GET_FULL_ERRM;
END IMPORT_FTR_ZONAL_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_LMP(p_MARKET_TYPE IN VARCHAR2,
                      p_DATE        IN DATE,
                      p_MONTHLY        IN NUMBER,
                      p_STATUS      OUT NUMBER,
                      p_MESSAGE     OUT VARCHAR2,
                      p_LOGGER        IN OUT mm_logger_adapter) IS

    v_LMP_TBL          MEX_PJM_LMP_OBJ_TBL;
    v_LMP_ML_TBL       MEX_PJM_LMP_ML_OBJ_TBL;
    v_ENERGY_PRICE_TBL  PRICE_QUANTITY_SUMMARY_TABLE;
BEGIN
    p_STATUS := GA.SUCCESS;

    IF p_DATE >= g_MARGINAL_LOSS_DATE THEN
        MEX_PJM_LMP.FETCH_LMP_ML_FILE(p_DATE,
                                       p_MARKET_TYPE,
                                       p_MONTHLY,
                                       v_ENERGY_PRICE_TBL,
                                       v_LMP_ML_TBL,
                                       p_STATUS,
                                       p_MESSAGE,
                                    p_LOGGER);

        IF p_STATUS = GA.SUCCESS THEN
           IMPORT_LMP_ML(p_MARKET_TYPE, v_ENERGY_PRICE_TBL, v_LMP_ML_TBL, p_MONTHLY, p_STATUS, p_MESSAGE);
        ELSIF

            v_LMP_ML_TBL.COUNT = 0 THEN
            p_STATUS := 0;
            p_MESSAGE:= 'File is not found for '||TO_CHAR(p_DATE,'MM/DD/YYYY');
            p_LOGGER.LOG_WARN(p_MESSAGE);
            --RETURN;
        END IF;

    ELSE
        MEX_PJM_LMP.FETCH_LMP_FILE(p_DATE,
                                       p_MARKET_TYPE,
                                       p_MONTHLY,
                                       v_LMP_TBL,
                                       p_STATUS,
                                       p_MESSAGE,
                                    p_LOGGER);
        IF p_STATUS = GA.SUCCESS THEN
            IMPORT_LMP(p_MARKET_TYPE, v_LMP_TBL, p_MONTHLY, p_STATUS, p_MESSAGE);
        END IF;
    END IF;

EXCEPTION
    WHEN OTHERS THEN
      p_MESSAGE := UT.GET_FULL_ERRM;
      p_STATUS  := SQLCODE;
END QUERY_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LMP_ML_FROM_FILE
    (
    p_DATE IN DATE,
    p_IMPORT_FILE IN CLOB,
    p_IMPORT_TYPE IN VARCHAR2,
    p_MONTHLY     IN PLS_INTEGER, --@@Implementation Override--
    p_STATUS      OUT NUMBER,
    p_MESSAGE     OUT VARCHAR2
    ) IS
v_ENG_RECORDS PRICE_QUANTITY_SUMMARY_TABLE;
v_RECORDS MEX_PJM_LMP_ML_OBJ_TBL;
v_FTR_RECORDS MEX_PJM_LMP_OBJ_TBL;

BEGIN

    --For debugging.  Import_type should be "DA" or "RT" or "FTR"
    p_STATUS := GA.SUCCESS;
    IF p_IMPORT_TYPE IN ('DA','RT') THEN
        MEX_PJM_LMP.PARSE_LMP_ML(p_DATE, p_IMPORT_FILE, p_MONTHLY, v_ENG_RECORDS, v_RECORDS, p_STATUS, p_MESSAGE);
        IF p_STATUS = GA.SUCCESS THEN
            IMPORT_LMP_ML(p_IMPORT_TYPE, v_ENG_RECORDS, v_RECORDS, p_MONTHLY, p_STATUS, p_MESSAGE);
        END IF;
    ELSIF p_IMPORT_TYPE = 'FTR' THEN
        MEX_PJM_LMP.PARSE_FTR_ZONAL_LMP(p_DATE, p_IMPORT_FILE, v_FTR_RECORDS, p_STATUS, p_MESSAGE);

        IF p_STATUS = GA.SUCCESS THEN
          IMPORT_FTR_ZONAL_LMP(p_DATE, v_FTR_RECORDS, p_STATUS, p_MESSAGE);
        END IF;
    END IF;
END IMPORT_LMP_ML_FROM_FILE;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_FTR_ZONAL_LMP
(
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2,
    p_LOGGER  IN OUT mm_logger_adapter
) IS

v_LMP_TBL MEX_PJM_LMP_OBJ_TBL;
v_CURRENT_DATE DATE;
v_END_DATE DATE;
BEGIN
    p_STATUS := GA.SUCCESS;

    v_CURRENT_DATE := TRUNC(p_BEGIN_DATE,'MM');
    v_END_DATE := TRUNC(p_END_DATE, 'MM');
    WHILE v_CURRENT_DATE <= v_END_DATE
    LOOP
        MEX_PJM_LMP.FETCH_FTR_ZONAL_LMP_FILE
                                (v_CURRENT_DATE,
                                   v_LMP_TBL,
                                   p_STATUS,
                                   p_MESSAGE,
                                p_LOGGER);
        IF p_STATUS = GA.SUCCESS THEN
            IMPORT_FTR_ZONAL_LMP(v_CURRENT_DATE, v_LMP_TBL, p_STATUS, p_MESSAGE);
        END IF;

        v_CURRENT_DATE := v_CURRENT_DATE + NUMTOYMINTERVAL(1, 'MONTH');
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_MESSAGE := UT.GET_FULL_ERRM;
      p_STATUS  := SQLCODE;

END QUERY_FTR_ZONAL_LMP;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_PNODES(p_RECORDS IN MEX_PJM_LMP_OBJ_TBL,
p_STATUS OUT NUMBER,
p_MESSAGE OUT VARCHAR2) IS

v_IDX BINARY_INTEGER;
v_LAST_PNODE_ID VARCHAR2(255) := 'foobar';

BEGIN
  p_STATUS := GA.SUCCESS;

  v_IDX := p_RECORDS.FIRST;
  WHILE p_RECORDS.EXISTS(v_IDX)
  LOOP

    IF v_LAST_PNODE_ID != p_RECORDS(v_IDX).PNODEID THEN
      BEGIN
        SELECT PNODEID
        INTO v_LAST_PNODE_ID
        FROM PJM_EMKT_PNODES
        WHERE PNODEID = p_RECORDS(v_IDX).PNODEID;

        -- update the zone

        UPDATE PJM_EMKT_PNODES
        SET ZONE = p_RECORDS(v_IDX).ZONE
        WHERE PNODEID = v_LAST_PNODE_ID;

      EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_LAST_PNODE_ID := p_RECORDS(v_IDX).PNODEID;
        INSERT
        INTO PJM_EMKT_PNODES(NODENAME, NODETYPE, PNODEID, CANSUBMITFIXED, CANSUBMITPRICESENSITIVE, CANSUBMITINCREMENT, CANSUBMITDECREMENT, ZONE)
        VALUES(p_RECORDS(v_IDX).NAME, p_RECORDS(v_IDX).TYPE, p_RECORDS(v_IDX).PNODEID, 0, 0, 0, 0, p_RECORDS(v_IDX).ZONE);
      END;

    END IF;

    v_IDX := p_RECORDS.NEXT(v_IDX);
  END LOOP;

  IF p_STATUS >= 0 THEN
    COMMIT;
  END IF;

EXCEPTION
WHEN OTHERS THEN
  P_STATUS := SQLCODE;
  P_MESSAGE := 'MM_PJM_LMP.IMPORT_PNODES: ' || UT.GET_FULL_ERRM;
END IMPORT_PNODES;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_PNODES
    (
    p_STATUS      OUT NUMBER,
    p_MESSAGE     OUT VARCHAR2,
    p_LOGGER      IN OUT MM_LOGGER_ADAPTER
    ) IS

    v_LMP_TBL          MEX_PJM_LMP_OBJ_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;

    MEX_PJM_LMP.FETCH_LMP_FILE(TRUNC(SYSDATE-1),
                                   'DA',
                                   0,
                                   v_LMP_TBL,
                                   p_STATUS,
                                   p_MESSAGE,
                                p_LOGGER);
    IF p_STATUS = GA.SUCCESS THEN
      IMPORT_PNODES(v_LMP_TBL, p_STATUS, p_MESSAGE);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      p_MESSAGE := UT.GET_FULL_ERRM;
      p_STATUS  := SQLCODE;

  END QUERY_PNODES;
  ----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
    (
    p_BEGIN_DATE                IN DATE,
    p_END_DATE                  IN DATE,
    p_EXCHANGE_TYPE              IN VARCHAR2,
    p_LOG_TYPE                     IN NUMBER,
    p_TRACE_ON                     IN NUMBER,
    p_STATUS                    OUT NUMBER,
    p_MESSAGE                   OUT VARCHAR2
    ) AS

    v_CURRENT_DATE        DATE;
    v_ACTION              VARCHAR2(64);
    v_MARKET_TYPE         VARCHAR2(32);

    v_CRED                  MEX_CREDENTIALS;
    v_LOGGER              MM_LOGGER_ADAPTER;

    v_MESSAGE             VARCHAR2(1064);
BEGIN

    v_ACTION := p_EXCHANGE_TYPE;


    MM_UTIL.INIT_MEX(EC.ES_PJM,
                         NULL,
                         'PJM:LMP: '||p_EXCHANGE_TYPE,
                         v_ACTION,
                         p_LOG_TYPE,
                         p_TRACE_ON,
                         v_CRED,
                         v_LOGGER,
                         TRUE);
    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);
    --LOGS.LOG_INFO('V_action='||v_ACTION);
--@@Implementation Override Begin: Case 00200150:add target begin/end date in process log.
    LOGS.SET_PROCESS_TARGET_PARAMETER('BEGIN_DATE', TO_CHAR(p_BEGIN_DATE,'yyyy-mm-dd'));
    LOGS.SET_PROCESS_TARGET_PARAMETER('END_DATE', TO_CHAR(p_END_DATE, 'yyyy-mm-dd'));
--@@Implementation Override End: Case 00200150

    IF v_ACTION = g_ET_QUERY_PNODES THEN
         QUERY_PNODES(p_STATUS, p_MESSAGE, v_LOGGER);
    ELSIF v_ACTION = g_ET_FTR_ZONAL_LMP THEN
         QUERY_FTR_ZONAL_LMP(p_BEGIN_DATE, p_END_DATE, p_STATUS, p_MESSAGE, v_LOGGER);
    ELSE
        --LOOP OVER DATES
        v_CURRENT_DATE := TRUNC(p_BEGIN_DATE);
        v_MESSAGE := NULL;
        LOOP
            CASE v_ACTION
                WHEN g_ET_DAY_AHEAD_LMP THEN
                    v_MARKET_TYPE := 'DA';
                    QUERY_LMP(v_MARKET_TYPE, v_CURRENT_DATE, 0, p_STATUS, p_MESSAGE, v_LOGGER);
                WHEN g_ET_REAL_TIME_LMP THEN
                    v_MARKET_TYPE := 'RT';
                    QUERY_LMP(v_MARKET_TYPE, v_CURRENT_DATE, 0, p_STATUS, p_MESSAGE, v_LOGGER);
                ELSE
                   IF (v_ACTION <> g_ET_DAY_AHEAD_LMP_MONTH AND v_ACTION <> g_ET_REAL_TIME_LMP_MONTH) THEN
                     p_STATUS := -1;
                     p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
                     --v_LOGGER.LOG_ERROR(p_MESSAGE);
                    EXIT;
                   END IF;
            END CASE;
            EXIT WHEN v_CURRENT_DATE >= TRUNC(p_END_DATE);
            v_CURRENT_DATE := v_CURRENT_DATE + 1;
        END LOOP;

        IF v_MARKET_TYPE IS NULL THEN
           -- For monthly
           v_CURRENT_DATE := TRUNC(p_BEGIN_DATE,'MM');
           v_MESSAGE := NULL;
           LOOP
              CASE v_ACTION
                WHEN g_ET_DAY_AHEAD_LMP_MONTH THEN
                    v_MARKET_TYPE := 'DA';
                    QUERY_LMP(v_MARKET_TYPE, v_CURRENT_DATE, 1, p_STATUS, v_MESSAGE, v_LOGGER);
                WHEN g_ET_REAL_TIME_LMP_MONTH THEN
                    v_MARKET_TYPE := 'RT';
                    QUERY_LMP(v_MARKET_TYPE, v_CURRENT_DATE, 1, p_STATUS, v_MESSAGE, v_LOGGER);
              END CASE;
              IF v_MESSAGE IS NOT NULL THEN
                 p_MESSAGE := p_MESSAGE||' '||v_MESSAGE;
                 p_STATUS := 800;
              END IF;
              v_CURRENT_DATE := ADD_MONTHS(TRUNC(v_CURRENT_DATE, 'MM'),1);
              EXIT WHEN v_CURRENT_DATE >= TRUNC(p_END_DATE);
              v_MESSAGE := NULL;
            END LOOP;

        END IF;

    END IF;

    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
EXCEPTION
    WHEN OTHERS THEN
        p_MESSAGE := UT.GET_FULL_ERRM;
        p_STATUS  := SQLCODE;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_IMPORT_CLOB
    (
    p_BEGIN_DATE                IN DATE,
    p_END_DATE                  IN DATE,
    p_EXCHANGE_TYPE             IN VARCHAR2,
    p_LOG_TYPE                  IN NUMBER,
    p_TRACE_ON                  IN NUMBER,
    p_FILE_PATH                 IN VARCHAR2, -- For logging Purposes.
    p_IMPORT_FILE               IN CLOB,     -- File to be imported
    p_MONTHLY                   IN PLS_INTEGER, --@@Implementation Override--
    p_STATUS                    OUT NUMBER,
    p_MESSAGE                   OUT VARCHAR2
    ) AS

    v_CRED                  MEX_CREDENTIALS;
    v_LOGGER              MM_LOGGER_ADAPTER;
BEGIN

    MM_UTIL.INIT_MEX(EC.ES_PJM,
                         NULL,
                         'PJM:' || CASE WHEN p_MONTHLY = 1 THEN 'Monthly ' ELSE '' END || 'LMP Import From File',  --@@Implementation Override--
                         p_EXCHANGE_TYPE,
                         p_LOG_TYPE,
                         p_TRACE_ON,
                         v_CRED,
                         v_LOGGER,
                         TRUE);
    MM_UTIL.START_EXCHANGE(TRUE, v_LOGGER);

    CASE p_EXCHANGE_TYPE
        WHEN g_ET_DA_LMP_FROM_FILE THEN
            IMPORT_LMP_ML_FROM_FILE(p_BEGIN_DATE, p_IMPORT_FILE, 'DA', p_MONTHLY, p_STATUS, p_MESSAGE);  --@@Implementation Override--
        WHEN g_ET_RT_LMP_FROM_FILE THEN
            IMPORT_LMP_ML_FROM_FILE(p_BEGIN_DATE, p_IMPORT_FILE, 'RT', p_MONTHLY, p_STATUS, p_MESSAGE);  --@@Implementation Override--
        WHEN g_ET_FTR_LMP_FROM_FILE THEN
            IMPORT_LMP_ML_FROM_FILE(p_BEGIN_DATE, p_IMPORT_FILE, 'FTR', p_MONTHLY, p_STATUS, p_MESSAGE);  --@@Implementation Override--
        ELSE
            p_STATUS := -1;
            p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
            v_LOGGER.LOG_ERROR(p_MESSAGE);
    END CASE;

    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
EXCEPTION
    WHEN OTHERS THEN
        p_MESSAGE := UT.GET_FULL_ERRM;
        p_STATUS  := SQLCODE;
        v_LOGGER.LOG_EXCHANGE_ERROR(p_MESSAGE);
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_IMPORT_CLOB;
----------------------------------------------------------------------------------------------------
BEGIN
  -- Initialization
  SELECT SC_ID
    INTO G_PJM_SC_ID
    FROM SCHEDULE_COORDINATOR
   WHERE SC_NAME = 'PJM';
EXCEPTION
  WHEN OTHERS THEN
    G_PJM_SC_ID := 0;

END MM_PJM_LMP;
/

