CREATE OR REPLACE PACKAGE BODY MM_NYISO_LOAD IS

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
-- ADJUST_TO_5_MIN:
-- if the time between 5 minute periods is < 2.5 minutes then round down, else round up
--
FUNCTION ADJUST_TO_5_MIN(p_DATETIME IN DATE) RETURN DATE AS
	v_DATETIME DATE;
	v_N NUMBER;
	v_MINUTES NUMBER;
    v_SECONDS NUMBER;
BEGIN
    v_MINUTES := to_number(to_char(p_DATETIME,'MI'));
	v_SECONDS := to_number(to_char(p_DATETIME,'SS'));

    -- check if NOT on 5 minute period OR NOT 0 seconds
    IF (v_MINUTES MOD 5 > 0) OR (v_SECONDS > 0) THEN

        -- get time to the minute
    	v_DATETIME := to_date(to_char(p_DATETIME, 'mm/dd/yyyy HH24:MI') ,'mm/dd/yyyy HH24:MI');

        -- get last 5 minute period
        v_N := to_number(v_MINUTES/5)*5;

		IF (v_N MOD 5  + v_SECONDS/60) >= 2.5 THEN
        	-- move minutes to the next 5 minute period
        	v_DATETIME := v_DATETIME + (5 - (v_N MOD 5)) / 1440; -- new minutes
		ELSE
			v_DATETIME := v_DATETIME - (v_N MOD 5) /1440;
		END IF;

    ELSE
		v_DATETIME := p_DATETIME;
    END IF;

    RETURN v_DATETIME;

    EXCEPTION
    WHEN OTHERS THEN
    RETURN p_DATETIME;

END ADJUST_TO_5_MIN;

----------------------------------------------------------------------------------------------------
--
-- MARKET_TYPES:  'DayAhead', 'HourAhead', 'RealTime', 'RealTimeIntegrated'
--
FUNCTION GET_IT_TRANSACTION_ID
(
	P_EXTERNAL_ID IN VARCHAR2,
	p_MARKET_TYPE IN VARCHAR2,
	p_LOGGER      IN OUT MM_LOGGER_ADAPTER
) RETURN NUMBER IS

    v_TRANSACTION_ID     INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
    v_SERVICE_ZONE_NAME  SERVICE_ZONE.SERVICE_ZONE_NAME%TYPE;
    v_SERVICE_ZONE_ID    SERVICE_ZONE.SERVICE_ZONE_ID%TYPE;
	v_SERVICE_ZONE_ALIAS SERVICE_ZONE.SERVICE_ZONE_ALIAS%TYPE;
    v_TRANSACTION_NAME   INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
	v_TRANSACTION_ALIAS  INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS%TYPE;
	v_COMMODITY_ID       IT_COMMODITY.COMMODITY_ID%TYPE;
	v_PRICE_INTERVAL     VARCHAR2(9);
	v_SERVICE_POINT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
	v_SERVICE_POINT_ID   SERVICE_POINT.SERVICE_POINT_ID%TYPE;

BEGIN

    v_PRICE_INTERVAL := MM_NYISO_UTIL.GET_PRICE_INTERVAL(p_MARKET_TYPE);
	v_SERVICE_ZONE_ALIAS := UPPER(p_EXTERNAL_ID);

     -- we need the commodity_id , if no record add one
    v_COMMODITY_ID := MM_NYISO_UTIL.GET_COMMODITY_ID(MM_NYISO_UTIL.g_REALTIME);
    IF v_COMMODITY_ID = -1 THEN
    	v_COMMODITY_ID := 0;
    END IF;

    BEGIN -- TRANSACTION ZONE LOOKUP
    SELECT ITT.TRANSACTION_ID
    INTO V_TRANSACTION_ID
    FROM INTERCHANGE_TRANSACTION ITT, SERVICE_ZONE SZ
    WHERE SZ.SERVICE_ZONE_ALIAS = v_SERVICE_ZONE_ALIAS
    AND SZ.SERVICE_ZONE_ID = ITT.ZOD_ID
    AND ITT.TRANSACTION_INTERVAL = v_PRICE_INTERVAL
    AND ITT.COMMODITY_ID = v_COMMODITY_ID
    AND ITT.TRANSACTION_TYPE = 'Market Result'
    AND SC_ID = MM_NYISO_UTIL.G_NYISO_SC_ID;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN

        BEGIN -- TRANSACTION POINT LOOKUP
        SELECT ITT.TRANSACTION_ID
        INTO V_TRANSACTION_ID
        FROM INTERCHANGE_TRANSACTION ITT, SERVICE_POINT SP
        WHERE SP.SERVICE_POINT_ALIAS = v_SERVICE_ZONE_ALIAS
        AND SP.SERVICE_POINT_ID = ITT.POD_ID
        AND ITT.TRANSACTION_INTERVAL = v_PRICE_INTERVAL
        AND ITT.COMMODITY_ID = v_COMMODITY_ID
        AND ITT.TRANSACTION_TYPE = 'Market Result'
        AND SC_ID = MM_NYISO_UTIL.G_NYISO_SC_ID;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN

            -- if there's no transaction tied to a zone or point add one
            -- but only if there is a zone or point match
            BEGIN -- ADD NEW TRANSACTION

            -- lookup service zone
            BEGIN
            SELECT SZ.SERVICE_ZONE_NAME, SZ.SERVICE_ZONE_ID
            INTO v_SERVICE_ZONE_NAME, v_SERVICE_ZONE_ID
            FROM SERVICE_ZONE SZ
            WHERE SZ.SERVICE_ZONE_ALIAS = v_SERVICE_ZONE_ALIAS;
            EXCEPTION
            WHEN OTHERS THEN
            NULL;
            END;

            -- also lookup service point
            BEGIN
            SELECT SP.SERVICE_POINT_NAME, SP.SERVICE_POINT_ID
            INTO v_SERVICE_POINT_NAME, v_SERVICE_POINT_ID
            FROM SERVICE_POINT SP
            WHERE SP.SERVICE_POINT_ALIAS = v_SERVICE_ZONE_ALIAS;
            EXCEPTION
            WHEN OTHERS THEN
            NULL;
            END;

            -- set service zone name to service point name when zone is missing
            -- this allows configuration with points only

            -- if not both null
            IF NOT ((v_SERVICE_ZONE_NAME IS NULL) AND (v_SERVICE_POINT_NAME IS NULL)) THEN

                IF v_SERVICE_ZONE_NAME IS NULL THEN
                	v_SERVICE_ZONE_NAME  := v_SERVICE_POINT_NAME;
                END IF;

                IF v_PRICE_INTERVAL = 'Hour' THEN
                	v_TRANSACTION_NAME := v_SERVICE_ZONE_NAME || ':Zonal Load';
                	v_TRANSACTION_ALIAS := SUBSTR(v_SERVICE_ZONE_NAME, 1, 14) || ':Zonal Load';
                ELSE
                	v_TRANSACTION_NAME := v_SERVICE_ZONE_NAME || ':Zonal Load (5min)';
                	v_TRANSACTION_ALIAS := SUBSTR(v_SERVICE_ZONE_NAME, 1, 14) || ':Zonal Load (5min)';
                END IF;

           		EM.PUT_TRANSACTION(O_OID => V_TRANSACTION_ID,
                                P_TRANSACTION_NAME       => v_TRANSACTION_NAME,
                                P_TRANSACTION_ALIAS      => v_TRANSACTION_ALIAS,
                                P_TRANSACTION_DESC       => 'Created by MarketManager via LOAD import',
                                P_TRANSACTION_ID         => 0,
								p_TRANSACTION_STATUS       => 'Active',
                                P_TRANSACTION_TYPE       => 'Market Result',
                                P_TRANSACTION_IDENTIFIER => v_TRANSACTION_NAME,
                                p_IS_FIRM                => 0,
                                p_IS_IMPORT_SCHEDULE     => 0,
                                p_IS_EXPORT_SCHEDULE     => 0,
                                P_IS_BALANCE_TRANSACTION => 0,
                                p_IS_BID_OFFER           => 0,
                                P_IS_EXCLUDE_FROM_POSITION => 0,
                                P_IS_IMPORT_EXPORT       => 0,
                                p_IS_DISPATCHABLE        => 0,
                                P_TRANSACTION_INTERVAL   => v_PRICE_INTERVAL,
                                P_EXTERNAL_INTERVAL      => NULL,
                                P_ETAG_CODE              => NULL,
                                p_BEGIN_DATE             => LOW_DATE,
                                p_END_DATE               => HIGH_DATE,
                                p_PURCHASER_ID           => 0,
                                p_SELLER_ID              => 0,
                                p_CONTRACT_ID            => 0,
                                p_SC_ID                  => MM_NYISO_UTIL.G_NYISO_SC_ID,
                                p_POR_ID                 => 0,
                                p_POD_ID                 => v_SERVICE_POINT_ID,
                                P_COMMODITY_ID           => v_COMMODITY_ID,
                                P_SERVICE_TYPE_ID        => 0,
                                P_TX_TRANSACTION_ID      => 0,
                                P_PATH_ID                => 0,
                                P_LINK_TRANSACTION_ID    => 0,
                                P_EDC_ID                 => 0,
                                P_PSE_ID                 => 0,
                                P_ESP_ID                 => 0,
                                P_POOL_ID                => 0,
                                P_SCHEDULE_GROUP_ID      => 0,
                                P_MARKET_PRICE_ID        => 0,
                                P_ZOR_ID                 => 0,
                                P_ZOD_ID                 => v_SERVICE_ZONE_ID,
                                P_SOURCE_ID              => 0,
                                P_SINK_ID                => 0,
                                P_RESOURCE_ID            => 0,
                                P_AGREEMENT_TYPE         => NULL,
                                P_APPROVAL_TYPE          => NULL,
                                P_LOSS_OPTION            => NULL,
                                P_TRAIT_CATEGORY         => NULL,
								p_TP_ID 				 => 0
								);
            COMMIT;

            END IF; -- SERVICE ZONE AND POINT TEST

            EXCEPTION
              WHEN OTHERS THEN
                -- no transaction
                V_TRANSACTION_ID := NULL;
            END; -- ADD NEW TRANSACTION

		END; -- TRANSACTION POINT LOOKUP

    END; -- TRANSACTION ZONE LOOKUP

    RETURN v_TRANSACTION_ID;

EXCEPTION
    WHEN OTHERS THEN
      p_LOGGER.LOG_ERROR('Could not create transaction (' || v_TRANSACTION_NAME || ')');
	  RAISE;

END GET_IT_TRANSACTION_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOAD(p_ACTION IN VARCHAR2,
					  p_RECORDS IN MEX_NY_LOAD_TBL,
					  p_LOGGER IN OUT MM_LOGGER_ADAPTER) IS

	v_IDX                   BINARY_INTEGER;
	v_PRICE_IDX             BINARY_INTEGER;
	v_PRICES                MEX_SCHEDULE_TBL;
	v_LAST_PNODE_ID         VARCHAR2(255) := 'foobar';
	v_SCH_ROW               IT_SCHEDULE%ROWTYPE;
	v_MARKET_TYPE           VARCHAR2(32);
	v_TXN_ID                NUMBER(9);
	v_SCHED_DATE            DATE;
	v_SCHED_PRICE           IT_SCHEDULE.PRICE%TYPE;
	v_SCHED_AMOUNT          IT_SCHEDULE.AMOUNT%TYPE;

BEGIN
	p_LOGGER.LOG_INFO ('Attempting to store ' || p_ACTION || ' values');

	IF p_ACTION = MEX_NYISO.g_ISO_LOAD THEN
		v_MARKET_TYPE           := MM_NYISO_UTIL.g_REALTIMEINTEGRATED; -- hourly (not using DayAhead for loads)
	ELSIF p_ACTION = MEX_NYISO.g_INTEGRATED_RT_ACTUAL_LOAD THEN
		v_MARKET_TYPE           := MM_NYISO_UTIL.g_REALTIMEINTEGRATED; -- hourly
	ELSIF p_ACTION = MEX_NYISO.g_RT_ACTUAL_LOAD THEN
		v_MARKET_TYPE           := MM_NYISO_UTIL.g_REALTIME; -- 5min
	END IF;

	v_IDX := p_RECORDS.FIRST;
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		IF v_LAST_PNODE_ID != p_RECORDS(v_IDX).ZONE_NAME THEN
			v_LAST_PNODE_ID := p_RECORDS(v_IDX).ZONE_NAME;
			v_TXN_ID        := GET_IT_TRANSACTION_ID(p_RECORDS(v_IDX).ZONE_NAME,v_MARKET_TYPE, p_LOGGER);
		END IF;

		IF v_TXN_ID IS NOT NULL THEN
			v_PRICES    := p_RECORDS(v_IDX).SCHEDULES;
			v_PRICE_IDX := v_PRICES.FIRST;

			WHILE v_PRICES.EXISTS(v_PRICE_IDX) LOOP
				v_SCHED_DATE   := v_PRICES(v_PRICE_IDX).CUT_TIME;
				v_SCHED_AMOUNT := v_PRICES(v_PRICE_IDX).VOLUME;
				v_SCHED_PRICE  := v_PRICES(v_PRICE_IDX).RATE;

				-- check for real time values between the 5 minute times
				IF p_ACTION = MEX_NYISO.g_RT_ACTUAL_LOAD THEN
					-- move the time to the next 5 minute
					v_SCHED_DATE := ADJUST_TO_5_MIN(v_SCHED_DATE);
				END IF;

				MM_NYISO_UTIL.PUT_SCHEDULE_VALUE(p_TX_ID      => v_TXN_ID,
												 p_SCHED_DATE => v_SCHED_DATE,
												 p_AMOUNT     => v_SCHED_AMOUNT,
												 p_PRICE      => v_SCHED_PRICE);

				v_PRICE_IDX := v_PRICES.NEXT(v_PRICE_IDX);
			END LOOP;
		END IF;

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	COMMIT;


EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE('ATC/TTC Data => Txn Id:' || v_SCH_ROW.TRANSACTION_ID ||
		                   ', Amount:' || v_SCH_ROW.AMOUNT ||
						   ', Price' || v_SCH_ROW.PRICE);
END IMPORT_LOAD;
----------------------------------------------------------------------------------------------------
PROCEDURE QUERY_LOAD(p_ACTION   IN VARCHAR2,
					 p_DATE     IN DATE,
					 p_STATUS   OUT NUMBER,
					 p_LOGGER  	IN OUT MM_LOGGER_ADAPTER) IS

	v_LOAD_TBL MEX_NY_LOAD_TBL;
BEGIN
	p_STATUS := GA.SUCCESS;

	MEX_NYISO_LOAD.FETCH_LOAD(p_DATE,
							  p_ACTION,
							  v_LOAD_TBL,
							  p_STATUS,
							  p_LOGGER);

	-- Save values into database
    ERRS.VALIDATE_STATUS('MEX_NYISO_LOAD.FETCH_LOAD', p_STATUS);
	IMPORT_LOAD(p_ACTION, v_LOAD_TBL, p_LOGGER);

END QUERY_LOAD;
----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
(
    p_BEGIN_DATE    IN DATE,
    p_END_DATE      IN DATE,
    p_EXCHANGE_TYPE IN VARCHAR2,
    p_LOG_TYPE      IN NUMBER,
    p_TRACE_ON      IN NUMBER,
    p_STATUS        OUT NUMBER,
    p_MESSAGE       OUT VARCHAR2
) AS

	v_CURRENT_DATE DATE;
	v_CRED         MEX_CREDENTIALS;
	v_LOGGER       MM_LOGGER_ADAPTER;

BEGIN

	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID    => EC.ES_MEX_SWITCHBOARD,                     p_EXTERNAL_ACCOUNT_NAME => NULL,
                     p_PROCESS_NAME          => 'NYISO:LOAD',
                     p_EXCHANGE_NAME         => p_EXCHANGE_TYPE,
                     p_LOG_TYPE              => p_LOG_TYPE,
                     p_TRACE_ON              => p_TRACE_ON,
                     p_CREDENTIALS           => v_CRED,
                     p_LOGGER                => v_LOGGER);

    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	v_CURRENT_DATE := TRUNC(p_BEGIN_DATE);
	LOOP
		QUERY_LOAD(p_EXCHANGE_TYPE, v_CURRENT_DATE, p_STATUS, v_LOGGER);

		EXIT WHEN v_CURRENT_DATE >= TRUNC(p_END_DATE);
		v_CURRENT_DATE := v_CURRENT_DATE + 1;

	END LOOP; -- day loop

 	p_MESSAGE := v_LOGGER.GET_END_MESSAGE();
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
        p_STATUS  := SQLCODE;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
--------------------------------------------------------------------------------------
END MM_NYISO_LOAD;
/
