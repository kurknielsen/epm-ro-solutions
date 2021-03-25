CREATE OR REPLACE PACKAGE BODY MM_NYISO_LBMP IS
-------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION PACKAGE_NAME RETURN VARCHAR IS
BEGIN
     RETURN 'MM_NYISO_LBMP';
END PACKAGE_NAME;
----------------------------------------------------------------------------------------------------
FUNCTION GET_PRICE_TYPE_CODE(p_PRICE_TYPE IN VARCHAR2) RETURN VARCHAR2 IS

	v_PRICE_TYPE_CODE VARCHAR2(64);

BEGIN

	IF p_PRICE_TYPE = MM_NYISO_UTIL.g_LMP_PRICE_TYPE THEN
		v_PRICE_TYPE_CODE := 'LMP';
	ELSIF p_PRICE_TYPE = MM_NYISO_UTIL.g_MLC_PRICE_TYPE THEN
		v_PRICE_TYPE_CODE := 'MLC';
	ELSIF p_PRICE_TYPE = MM_NYISO_UTIL.g_MCC_PRICE_TYPE THEN
		v_PRICE_TYPE_CODE := 'MCC';
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

	v_PRICE_TYPE_CODE    VARCHAR2(3);
	v_SUFFIX             VARCHAR2(14);

BEGIN

    p_MKT_PRICE_ALIAS := NULL;
    v_PRICE_TYPE_CODE := GET_PRICE_TYPE_CODE(p_PRICE_TYPE);

    -- use external_id to find service point name and id
    SELECT SP.SERVICE_POINT_NAME, SP.SERVICE_POINT_ID
      INTO p_SERVICE_POINT_NAME, p_SERVICE_POINT_ID
      FROM SERVICE_POINT SP
     WHERE SP.EXTERNAL_IDENTIFIER = P_SP_ID;

    -- NAME is 64 long
    -- ALIAS is 32 long
    -- SUFFIX is 14 long

    IF p_MARKET_TYPE = MM_NYISO_UTIL.g_DAYAHEAD THEN
        v_SUFFIX :=  ' (DA ' || v_PRICE_TYPE_CODE || ')';
        v_MKT_PRICE_ALIAS := SUBSTR(p_SERVICE_POINT_NAME, 1, 18) || v_SUFFIX;
        v_MKT_PRICE_NAME := p_SERVICE_POINT_NAME || v_SUFFIX;
    ELSIF p_MARKET_TYPE = MM_NYISO_UTIL.g_HOURAHEAD THEN
        v_SUFFIX := ' (HA ' || v_PRICE_TYPE_CODE || ')';
        v_MKT_PRICE_ALIAS := SUBSTR(p_SERVICE_POINT_NAME, 1, 18) || v_SUFFIX;
        v_MKT_PRICE_NAME := p_SERVICE_POINT_NAME || v_SUFFIX;
    ELSIF p_MARKET_TYPE = MM_NYISO_UTIL.g_REALTIME THEN
        v_SUFFIX := ' (RT 5min ' || v_PRICE_TYPE_CODE || ')';
        v_MKT_PRICE_ALIAS := SUBSTR(p_SERVICE_POINT_NAME, 1, 18) || v_SUFFIX;
        v_MKT_PRICE_NAME := p_SERVICE_POINT_NAME || v_SUFFIX;
    ELSE
        -- assume real-time-integrated
        v_SUFFIX := ' (RT ' || v_PRICE_TYPE_CODE || ')';
        v_MKT_PRICE_ALIAS := SUBSTR(p_SERVICE_POINT_NAME, 1, 18) || v_SUFFIX;
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
-- MARKET_TYPES:  'DayAhead', 'HourAhead', 'RealTime', 'RealTimeIntegrated'
-- PRICE_TYPES:  'Locational Marginal Price', 'Marginal Congestion Component', 'Marginal Loss Component'
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

    v_PRICE_INTERVAL := MM_NYISO_UTIL.GET_PRICE_INTERVAL(p_MARKET_TYPE);

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
		  v_COMMODITY_ID := MM_NYISO_UTIL.GET_COMMODITY_ID(p_MARKET_TYPE);
		  IF v_COMMODITY_ID = -1 THEN
			v_COMMODITY_ID := 0;
		  END IF;

		  IF p_MARKET_TYPE = MM_NYISO_UTIL.g_DAYAHEAD THEN
		  	v_MP_MARKET_TYPE := MM_NYISO_UTIL.g_DAYAHEAD;
		  ELSE
		  	v_MP_MARKET_TYPE := MM_NYISO_UTIL.g_REALTIME;
		  END IF;

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
                              P_SC_ID                 => MM_NYISO_UTIL.G_NYISO_SC_ID,
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
PROCEDURE IMPORT_LBMP
(
    p_ACTION  IN VARCHAR2,
    p_RECORDS IN MEX_NY_LBMP_TBL,
    p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER
) IS
    v_IDX           BINARY_INTEGER;
    v_PRICE_IDX     BINARY_INTEGER;
    v_PRICES        MEX_NY_LBMP_COST_TBL;
    v_LAST_PNODE_ID VARCHAR2(255) := 'foobar';
    v_MPV_ROW       MARKET_PRICE_VALUE%ROWTYPE;
    v_MARKET_TYPE   VARCHAR2(32);
    v_PRICE_TYPE    VARCHAR2(64);
    v_STATUS        NUMBER;

BEGIN
    v_STATUS := GA.SUCCESS;

    -- v_MARKET_TYPE_COMMODITY can be DA or RT only
    -- v_MARKET_TYPE can be DA, HA, RT, or RTI

    IF UPPER(p_ACTION) LIKE '%DA' THEN
        v_MARKET_TYPE := MM_NYISO_UTIL.g_DAYAHEAD;
    ELSIF UPPER(p_ACTION) LIKE '%BHA' THEN
        v_MARKET_TYPE := MM_NYISO_UTIL.g_HOURAHEAD;
    ELSIF UPPER(p_ACTION) LIKE '%RTI' THEN
        v_MARKET_TYPE := MM_NYISO_UTIL.g_REALTIMEINTEGRATED;
    ELSE
        v_MARKET_TYPE := MM_NYISO_UTIL.g_REALTIME;
    END IF;

    v_MPV_ROW.AS_OF_DATE  := LOW_DATE;
    v_MPV_ROW.PRICE_BASIS := NULL;

    -- three passes to get LBMP_COST, MC_LOSSES, MC_CONGESTION.
    -- no support for SCARCITY_FLAG.
    FOR idx IN 1 .. 3 LOOP
        IF idx = 1 THEN
            v_PRICE_TYPE := MM_NYISO_UTIL.g_LMP_PRICE_TYPE;
        ELSIF idx = 2 THEN
            v_PRICE_TYPE := MM_NYISO_UTIL.g_MLC_PRICE_TYPE;
        ELSE
            v_PRICE_TYPE := MM_NYISO_UTIL.g_MCC_PRICE_TYPE;
        END IF;

        v_IDX := p_RECORDS.FIRST;
        WHILE p_RECORDS.EXISTS(v_IDX) LOOP
            IF v_LAST_PNODE_ID != p_RECORDS(v_IDX).ENTITY_ID THEN
                v_LAST_PNODE_ID           := p_RECORDS(v_IDX).ENTITY_ID;
                v_MPV_ROW.MARKET_PRICE_ID := GET_MARKET_PRICE_ID(p_RECORDS(v_IDX).ENTITY_ID,
                                                                 v_MARKET_TYPE,
                                                                 v_PRICE_TYPE);
            END IF;

            IF v_MPV_ROW.MARKET_PRICE_ID IS NOT NULL AND
               v_MPV_ROW.MARKET_PRICE_ID <> -1 THEN

                v_PRICES    := p_RECORDS(v_IDX).COSTS;
                v_PRICE_IDX := v_PRICES.FIRST;
                WHILE v_PRICES.EXISTS(v_PRICE_IDX) LOOP
                    v_MPV_ROW.PRICE_DATE := v_PRICES(v_PRICE_IDX).CUT_TIME;

                    IF idx = 1 THEN
                        v_MPV_ROW.PRICE := v_PRICES(v_PRICE_IDX).LBMP_COST;
                    ELSIF idx = 2 THEN
                        v_MPV_ROW.PRICE := v_PRICES(v_PRICE_IDX).MC_LOSSES;
                    ELSE
                        v_MPV_ROW.PRICE := v_PRICES(v_PRICE_IDX).MC_CONGESTION;
                    END IF;

                    MM_NYISO_UTIL.PUT_MARKET_PRICE_VALUE(v_MPV_ROW.MARKET_PRICE_ID,
                                                   v_MPV_ROW.PRICE_DATE,
                                                   'A',
                                                   v_MPV_ROW.PRICE,
                                                   NULL,
                                                   v_STATUS,
                                                   p_LOGGER);
                    v_PRICE_IDX := v_PRICES.NEXT(v_PRICE_IDX);
                END LOOP;
            END IF;

            v_IDX := p_RECORDS.NEXT(v_IDX);
        END LOOP;

        IF v_STATUS >= 0 THEN
            COMMIT;
        END IF;

    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        p_LOGGER.LOG_ERROR(PACKAGE_NAME ||
                           '.IMPORT_LBMP: Error when importing for action: ' ||
                           p_ACTION || ':' || SQLERRM);

END IMPORT_LBMP;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_LBMP( p_ACTION IN VARCHAR2,
                      p_BEGIN_DATE 	IN DATE,
                      p_END_DATE 	IN DATE,
					  p_STATUS      OUT NUMBER,
					  p_LOGGER		IN OUT mm_logger_adapter) IS

    v_LMP_TBL	MEX_NY_LBMP_TBL;
    not_valid_date_range EXCEPTION;
    v_END_DATE_RANGE DATE;

BEGIN
    p_STATUS := GA.SUCCESS;

    v_END_DATE_RANGE := p_END_DATE;
    -- Make sure begin date comes before end date - TRUNC to make sure the dates are compared without
    -- looking at times.
    IF (TRUNC(p_BEGIN_DATE,'DDD') <= TRUNC(v_END_DATE_RANGE,'DDD')) THEN
        -- Loop from the last date and keep going down until you cant find files in the csv file list directly.
    	LOOP
    		MEX_NYISO_LBMP.FETCH_LBMP_DAILY(v_END_DATE_RANGE,
            						        FALSE, -- IS_Archived flag -- we are asking for csv directly. Hence false.
                					        P_ACTION,
                                    		NULL, -- No clob resp with zip - file list
                                    		v_LMP_TBL,
                                    		p_STATUS,
											p_LOGGER);
            -- Put the values into table
            ERRS.VALIDATE_STATUS('MEX_NYISO_LBMP.FETCH_LBMP_DAILY', p_STATUS);
        	IMPORT_LBMP(p_ACTION, v_LMP_TBL, p_LOGGER);

           	-- This flag says that we did try to get files from the public site.
            --v_NORMAL_FILE_CHECK_FLAG := TRUE;
            --EXIT WHEN (trunc(v_END_DATE_RANGE,'DDD') = TRUNC(p_BEGIN_DATE,'DDD') OR (p_STATUS != '0' AND v_END_DATE_RANGE < SYSDATE));
			EXIT WHEN (trunc(v_END_DATE_RANGE,'DDD') = TRUNC(p_BEGIN_DATE,'DDD') OR (p_STATUS != GA.SUCCESS AND v_END_DATE_RANGE < SYSDATE));

    		v_END_DATE_RANGE := v_END_DATE_RANGE - 1;
    	END LOOP;

    ELSE
    	ERRS.LOG_AND_RAISE('Incorrect Date Range: Begin date must start before the End date');
    END IF;

END QUERY_LBMP;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_ARCHIVE_LBMP( p_ACTION IN VARCHAR2,
                      p_BEGIN_DATE 	IN DATE,
                      p_END_DATE 	IN DATE,
					  p_STATUS      OUT NUMBER,
					  p_LOGGER		IN OUT mm_logger_adapter) IS

    v_LMP_TBL	MEX_NY_LBMP_TBL;
    v_CLOB_RESP CLOB;
    not_valid_date_range EXCEPTION;
    v_FIRST_MONTH DATE;
    v_END_DATE_RANGE DATE;
    v_CURRENT_MONTH DATE;
    v_END_MONTH DATE;
    v_CURRENT_DATE DATE;
    v_END_DATE DATE;
	v_FILE_NAMES STRING_COLLECTION := STRING_COLLECTION();
	v_SHEET_NAMES STRING_COLLECTION := STRING_COLLECTION();

BEGIN
    p_STATUS := GA.SUCCESS;

    v_END_DATE_RANGE := p_END_DATE;

	-- Try getting it from zipped files
	-- We want the first day of the first month to build url for the zip file of the month.
	-- We can also use the first day of the first and last month to loop through each month in the date range
	-- and check to which month we are in.
	v_CURRENT_MONTH := TRUNC(p_BEGIN_DATE,'MONTH');
	v_FIRST_MONTH := TRUNC(p_BEGIN_DATE,'MONTH');
	v_END_MONTH := TRUNC(v_END_DATE_RANGE,'MONTH');

	-- Loop over each month in the date range.
	WHILE v_CURRENT_MONTH <= v_END_MONTH LOOP
		--fetch directory listing first
		MEX_NYISO_LBMP.FETCH_LBMP_MONTHLY_ZIP(v_CURRENT_MONTH, p_ACTION, v_CLOB_RESP, p_STATUS, p_LOGGER);
		ERRS.VALIDATE_STATUS('MEX_NYISO_LBMP.FETCH_LBMP_MONTHLY_ZIP', p_STATUS);

		-- Get the File List
		MEX_SWITCHBOARD.ParseFileList(v_CLOB_RESP, v_FILE_NAMES, v_SHEET_NAMES);

		-- SET BEGIN AND END DATES FOR CURRENT MONTH.
		-- Set begin date for the current month. If first month, the set the begin date from
		-- date range, else set first of the month.
		IF (v_CURRENT_MONTH = v_FIRST_MONTH) THEN
			v_CURRENT_DATE := p_BEGIN_DATE;
		ELSE
			v_CURRENT_DATE := v_CURRENT_MONTH;
		END IF;

		-- Set end date for the current month. If last month in the date range, the set the end date from
		-- date range, else set 30th or 31st of month
		IF (v_CURRENT_MONTH = v_END_MONTH) THEN
			v_END_DATE := v_END_DATE_RANGE;
		ELSE
			v_END_DATE := LAST_DAY(v_CURRENT_MONTH);
		END IF;

		-- EACH DAY OF THE MONTH: Get files for each day in current month
		WHILE v_CURRENT_DATE <= v_END_DATE LOOP
			MEX_NYISO_LBMP.FETCH_LBMP_DAILY (v_CURRENT_DATE, TRUE, p_ACTION, v_FILE_NAMES, v_LMP_TBL, p_STATUS, p_LOGGER);

			-- Put the values into table
			ERRS.VALIDATE_STATUS('MEX_NYISO_LBMP.FETCH_LBMP_DAILY', p_STATUS);
			IMPORT_LBMP(p_ACTION, v_LMP_TBL, p_LOGGER);

			v_CURRENT_DATE := v_CURRENT_DATE + 1;
		END LOOP;

		v_CURRENT_MONTH := ADD_MONTHS(v_CURRENT_MONTH,1);
	END LOOP;

END QUERY_ARCHIVE_LBMP;
----------------------------------------------------------------------------------------------------
PROCEDURE TRUNCATE_TABLE(p_TABLENAME IN VARCHAR2) AS
BEGIN

EXECUTE IMMEDIATE 'TRUNCATE TABLE ' || p_TABLENAME;
COMMIT;

EXCEPTION
  WHEN OTHERS THEN
  	ERRS.LOG_AND_RAISE;
	ERRS.RAISE(MSGCODES.c_ERR_GENERAL, 'Error while truncating ' || p_TABLENAME, TRUE);
END TRUNCATE_TABLE;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_PRICE_NODES
(
    p_RECORDS    IN MEX_NY_PTID_NODE_TBL,
    p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

	v_IDX  BINARY_INTEGER;
BEGIN

    IF p_RECORDS.COUNT > 0 THEN
        TRUNCATE_TABLE('NYISO_PTID_NODE');
    	v_IDX    := p_RECORDS.FIRST;
        WHILE p_RECORDS.EXISTS(v_IDX) LOOP
            BEGIN
                INSERT INTO NYISO_PTID_NODE
                VALUES
                    (p_RECORDS(v_IDX).PTID,
                     p_RECORDS(v_IDX).PTID_NAME,
                     p_RECORDS(v_IDX).PTID_TYPE,
                     p_RECORDS(v_IDX).ZONE_NAME,
                     p_RECORDS(v_IDX).SUBZONE_NAME);
            EXCEPTION
                WHEN DUP_VAL_ON_INDEX THEN
                    ERRS.LOG_AND_CONTINUE('Duplicate value in NYISO_PTID_NODE.' || chr(13) ||
					'Data: '||p_RECORDS(v_IDX).PTID || ','
					||p_RECORDS(v_IDX).PTID_NAME||','
					||p_RECORDS(v_IDX).PTID_TYPE ||','
					||p_RECORDS(v_IDX).ZONE_NAME || ','
					||p_RECORDS(v_IDX).SUBZONE_NAME,LOGS.c_LEVEL_DEBUG);

                WHEN OTHERS THEN
                    ROLLBACK;
                    ERRS.LOG_AND_CONTINUE;
                    ERRS.RAISE(MSGCODES.c_ERR_GENERAL, 'Can not save nodes', TRUE);
            END;
			v_IDX := p_RECORDS.NEXT(v_IDX);
        END LOOP;
        COMMIT;

    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.PUT_PRICE_NODES: ' || SQLERRM);

END PUT_PRICE_NODES;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_PTID_ZONAL_LBMP
(
    p_RECORDS IN OUT MEX_NY_LBMP_TBL,
    p_LOGGER  IN OUT mm_logger_adapter
) AS

BEGIN

    -- add the summary zone also with PTID 0 (not used)
    p_RECORDS.EXTEND;
    p_RECORDS(p_RECORDS.LAST) := MEX_NY_LBMP('NYISO', 0, NULL);

    FOR I IN 1 .. p_RECORDS.COUNT LOOP
        BEGIN
            INSERT INTO NYISO_PTID_NODE
            VALUES
                (p_RECORDS(I).ENTITY_ID,
                 p_RECORDS(I).ENTITY_NAME,
                 'ZONE',
                 p_RECORDS(I).ENTITY_NAME,
                 p_RECORDS(I).ENTITY_NAME);
        EXCEPTION
            WHEN OTHERS THEN
                p_LOGGER.LOG_DEBUG('NYISO_PTID_NODE: Could not insert ' ||
                                   p_RECORDS(I).ENTITY_NAME || ' with PTID ' ||
                                   p_RECORDS(I).ENTITY_ID);
        END;
    END LOOP;
EXCEPTION
	WHEN OTHERS THEN
		p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.PUT_PTID_ZONAL_LBMP: ' || SQLERRM);

END PUT_PTID_ZONAL_LBMP;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_PRICE_NODES
(
    p_STATUS IN OUT NUMBER,
    p_LOGGER IN OUT NOCOPY mm_logger_adapter
) IS

    v_RECORDS MEX_NY_LBMP_TBL;
    v_NODES   MEX_NY_PTID_NODE_TBL;

BEGIN
    P_STATUS := GA.SUCCESS;

	--Fetch service points from 'generator.csv' and 'load.csv'
	--Service zones for LOAD and LBMP are from 'generator.csv' and 'load.csv' without PTID.
	--Service points for LBMP generators are from 'generator.csv'.
	--Service points for BIDPOST loads and virtual suppliers are from 'load.csv'.
	--Service points for BIDPOST generators are from 'generator.csv'.
	--Service points as interfaces for TC are created from the query results

    MEX_NYISO_LBMP.FETCH_NODES(v_NODES, p_STATUS, p_LOGGER);

    ERRS.VALIDATE_STATUS('MEX_NYISO_BIDPOST.FETCH_NODES', p_STATUS);
    PUT_PRICE_NODES(v_NODES, p_LOGGER);

	--Download a zonal LBMP file to bring in the PTID of the service points
    MEX_NYISO_LBMP.FETCH_LBMP_DAILY(SYSDATE - 1,
                                    FALSE,
                                    MEX_NYISO.g_DA_LBMP_ZONAL,
                                    NULL,
                                    v_RECORDS,
                                    P_STATUS,
                                    p_LOGGER);

	ERRS.VALIDATE_STATUS('MEX_NYISO_LBMP.FETCH_LBMP_DAILY', p_STATUS);
	PUT_PTID_ZONAL_LBMP(v_RECORDS, p_LOGGER);


END QUERY_PRICE_NODES;
-------------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_LIST_FOR_LBMP
	(
	p_CURSOR OUT SYS_REFCURSOR
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT g_ET_QUERY_DAY_AHEAD_LMP FROM DUAL
		UNION ALL
		SELECT g_ET_QUERY_REAL_TIME_LMP FROM DUAL
		UNION ALL
		SELECT g_ET_QUERY_REAL_TIME_INT_LMP FROM DUAL;
END;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
(
    p_BEGIN_DATE    IN DATE,
    p_END_DATE      IN DATE,
    p_EXCHANGE_TYPE IN VARCHAR2,
	p_ENTITY_LIST 	IN VARCHAR2,
    p_LOG_TYPE      IN NUMBER,
    p_TRACE_ON      IN NUMBER,
    p_STATUS        OUT NUMBER,
    p_MESSAGE       OUT VARCHAR2
) AS

    v_MARKET_TYPE  VARCHAR2(64);
    v_CRED   MEX_CREDENTIALS;
    v_LOGGER MM_LOGGER_ADAPTER;
	v_INDEX NUMBER;
	v_EXCHANGE_TYPES STRING_COLLECTION := STRING_COLLECTION();

BEGIN


    MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID    => EC.ES_MEX_SWITCHBOARD,
                     p_EXTERNAL_ACCOUNT_NAME => NULL,
                     p_PROCESS_NAME          => 'NYISO:LBMP',
                     p_EXCHANGE_NAME         => p_EXCHANGE_TYPE,
                     p_LOG_TYPE              => p_LOG_TYPE,
                     p_TRACE_ON              => p_TRACE_ON,
                     p_CREDENTIALS           => v_CRED,
                     p_LOGGER                => v_LOGGER);

    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

    -- Nodes
	IF p_EXCHANGE_TYPE = g_ET_QUERY_PRICE_NODES  THEN
		QUERY_PRICE_NODES(p_STATUS, v_LOGGER);
	-- Archieve LBMP
	ELSIF p_EXCHANGE_TYPE = g_ET_QUERY_ARCHIEVE_LBMP THEN
		UT.STRING_COLLECTION_FROM_STRING(p_ENTITY_LIST,',', v_EXCHANGE_TYPES);
		v_INDEX := v_EXCHANGE_TYPES.FIRST;
		--Loop Over the Entity List
		WHILE v_INDEX IS NOT NULL
		LOOP
			--LOOP OVER FILE TYPES
        	FOR v_IDX IN 1 .. 3 LOOP
            CASE v_EXCHANGE_TYPES(v_INDEX) --p_EXCHANGE_TYPE
                WHEN g_ET_QUERY_DAY_AHEAD_LMP THEN
                    CASE v_IDX
                        WHEN 1 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_DA_LBMP_ZONAL;
                        WHEN 2 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_DA_LBMP_GEN;
                        WHEN 3 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_DA_LBMP_BUS;
                    END CASE;
                WHEN g_ET_QUERY_REAL_TIME_LMP THEN
                    CASE v_IDX
                        WHEN 1 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_BHA_LBMP_ZONAL;
                        WHEN 2 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_BHA_LBMP_GEN;
                        WHEN 3 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_BHA_LBMP_BUS;
                    END CASE;
                WHEN g_ET_QUERY_REAL_TIME_INT_LMP THEN
                    CASE v_IDX
                        WHEN 1 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_INTEGRATED_RT_LBMP_ZONAL;
                        WHEN 2 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_INTEGRATED_RT_LBMP_GEN;
                        WHEN 3 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_INTEGRATED_RT_LBMP_BUS;
                    END CASE;
                ELSE
                    p_STATUS  := GA.GENERAL_EXCEPTION;
                    p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
                    v_LOGGER.LOG_ERROR(p_MESSAGE);
                    EXIT;
            END CASE;

			QUERY_ARCHIVE_LBMP(v_MARKET_TYPE, p_BEGIN_DATE,  p_END_DATE, p_STATUS, v_LOGGER);
	        END LOOP; -- file type loop

			v_INDEX := v_EXCHANGE_TYPES.NEXT(v_INDEX);
		END LOOP;
		NULL;
	ELSE
    	--LOOP OVER FILE TYPES
        FOR v_IDX IN 1 .. 3 LOOP
            CASE p_EXCHANGE_TYPE
                WHEN g_ET_QUERY_DAY_AHEAD_LMP THEN
                    CASE v_IDX
                        WHEN 1 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_DA_LBMP_ZONAL;
                        WHEN 2 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_DA_LBMP_GEN;
                        WHEN 3 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_DA_LBMP_BUS;
                    END CASE;
                WHEN g_ET_QUERY_REAL_TIME_LMP THEN
                    CASE v_IDX
                        WHEN 1 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_BHA_LBMP_ZONAL;
                        WHEN 2 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_BHA_LBMP_GEN;
                        WHEN 3 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_BHA_LBMP_BUS;
                    END CASE;
                WHEN g_ET_QUERY_REAL_TIME_INT_LMP THEN
                    CASE v_IDX
                        WHEN 1 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_INTEGRATED_RT_LBMP_ZONAL;
                        WHEN 2 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_INTEGRATED_RT_LBMP_GEN;
                        WHEN 3 THEN
                            v_MARKET_TYPE := MEX_NYISO.g_INTEGRATED_RT_LBMP_BUS;
                    END CASE;
                ELSE
                    p_STATUS  := GA.GENERAL_EXCEPTION;
                    p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
                    v_LOGGER.LOG_ERROR(p_MESSAGE);
                    EXIT;
            END CASE;

            QUERY_LBMP(v_MARKET_TYPE, p_BEGIN_DATE,  p_END_DATE, p_STATUS, v_LOGGER);

        END LOOP; -- file type loop
	END IF;

	p_MESSAGE := v_LOGGER.GET_END_MESSAGE();
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
    WHEN OTHERS THEN
        p_MESSAGE := SQLERRM;
        p_STATUS  := SQLCODE;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
-----------------------------------------------------------------------------------------------
END MM_NYISO_LBMP;
/
