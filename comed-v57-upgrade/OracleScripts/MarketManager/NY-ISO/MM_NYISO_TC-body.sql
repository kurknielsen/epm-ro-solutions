CREATE OR REPLACE PACKAGE BODY MM_NYISO_TC IS

-- output schedule types, passed as market type to create transaction name
g_TTC_DAM_SCHED_TYPE         CONSTANT VARCHAR2(25) := 'TTC (DAM)';
g_ATC_DAM_NONFIRM_SCHED_TYPE CONSTANT VARCHAR2(25) := 'ATC w/ Non-Firms (DAM)';
g_ATC_DAM_FIRM_SCHED_TYPE    CONSTANT VARCHAR2(25) := 'ATC w/o Non-Firms (DAM)';

g_TTC_HAM_SCHED_TYPE         CONSTANT VARCHAR2(25) := 'TTC (HAM)';
g_ATC_HAM_NONFIRM_SCHED_TYPE CONSTANT VARCHAR2(25) := 'ATC w/ Non-Firms (HAM)';
g_ATC_HAM_FIRM_SCHED_TYPE    CONSTANT VARCHAR2(25) := 'ATC w/o Non-Firms (HAM)';

g_ET_QUERY_ATC_TTC VARCHAR2(20):= 'QUERY ATC TTC';
-------------------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION CREATE_TRANSACTION_NAME(p_INTERFACE_NAME     IN VARCHAR2,
								 p_MARKET_TYPE        IN VARCHAR2,
								 p_SERVICE_POINT_NAME OUT SERVICE_ZONE.SERVICE_ZONE_NAME%TYPE,
								 p_SERVICE_POINT_ID   OUT SERVICE_ZONE.SERVICE_ZONE_ID%TYPE,
								 p_LOGGER            IN OUT mm_logger_adapter) RETURN INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE IS

	v_TRANSACTION_NAME  INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;

BEGIN

	-- NAME is 64 long
	-- ALIAS is 32 long


	--Tran. Name: <Interface name> <DA or HA> <Firm or Non-firm, for ATC only> <ATC or TTC>
	--Tran. External Identifier: <Interface name>:<DA or HA>:<Firm or Non-firm, for ATC only>:<ATC or TTC>
	BEGIN
		-- use external_id to find service point name and id
		SELECT SP.SERVICE_POINT_NAME, SP.SERVICE_POINT_ID
		  INTO p_SERVICE_POINT_NAME, p_SERVICE_POINT_ID
		  FROM SERVICE_POINT SP
		 WHERE SP.EXTERNAL_IDENTIFIER = p_INTERFACE_NAME;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			p_LOGGER.LOG_INFO('Attempting to create the' || P_INTERFACE_NAME || 'service point');
			-- add a service point
			p_SERVICE_POINT_NAME := p_INTERFACE_NAME;
			IO.PUT_SERVICE_POINT(o_OID                     => p_SERVICE_POINT_ID,
								 p_SERVICE_POINT_NAME      => P_INTERFACE_NAME,
								 p_SERVICE_POINT_ALIAS     => P_INTERFACE_NAME,
								 p_SERVICE_POINT_DESC      => P_INTERFACE_NAME,
								 p_SERVICE_POINT_ID        => 0,
								 p_SERVICE_POINT_TYPE      => 'Retail',
								 p_TP_ID                   => NULL,
								 p_CA_ID                   => NULL,
								 p_EDC_ID                  => NULL,
								 p_ROLLUP_ID               => NULL,
								 p_SERVICE_REGION_ID       => NULL,
								 p_SERVICE_AREA_ID         => NULL,
								 p_SERVICE_ZONE_ID         => NULL,
								 p_TIME_ZONE               => 'Eastern',
								 p_LATITUDE                => NULL,
								 p_LONGITUDE               => NULL,
								 p_EXTERNAL_IDENTIFIER     => P_INTERFACE_NAME,
								 p_IS_INTERCONNECT         => NULL,
								 p_NODE_TYPE               => 'Interface',
								 p_SERVICE_POINT_NERC_CODE => NULL,
                                 p_PIPELINE_ID             => NULL,
                                 p_MILE_MARKER             => NULL);

	END;

	v_TRANSACTION_NAME  := p_SERVICE_POINT_NAME || ' ' || p_MARKET_TYPE;

	RETURN v_TRANSACTION_NAME;
EXCEPTION
	WHEN OTHERS THEN
		p_LOGGER.LOG_ERROR('Failed to create the service point: ' || P_INTERFACE_NAME || CHR(13)
		|| SQLERRM);
		RAISE;

END CREATE_TRANSACTION_NAME;

----------------------------------------------------------------------------------------------------
--
-- MARKET_TYPES:
--g_TTC_DAM_SCHED_TYPE         CONSTANT VARCHAR2(15) := 'DA TTC';
--g_ATC_DAM_NONFIRM_SCHED_TYPE CONSTANT VARCHAR2(15) := 'DA Non-firm ATC';
--g_ATC_DAM_FIRM_SCHED_TYPE    CONSTANT VARCHAR2(15) := 'DA Firm ATC';
--g_TTC_HAM_SCHED_TYPE         CONSTANT VARCHAR2(15) := 'HA TTC';
--g_ATC_HAM_NONFIRM_SCHED_TYPE CONSTANT VARCHAR2(15) := 'HA Non-firm ATC';
--g_ATC_HAM_FIRM_SCHED_TYPE    CONSTANT VARCHAR2(15) := 'HA Firm ATC';
--
-- there will be only three types of transactions:  TTC, Firm ATC, Non-firm ATC
--
FUNCTION GET_IT_TRANSACTION_ID(p_INTERFACE_NAME IN VARCHAR2,
							   p_MARKET_TYPE    IN VARCHAR2,
							   p_LOGGER       IN OUT MM_LOGGER_ADAPTER) RETURN NUMBER IS

	v_SERVICE_POINT_NAME SERVICE_POINT.SERVICE_POINT_NAME%TYPE;
	v_SERVICE_POINT_ID   SERVICE_POINT.SERVICE_POINT_ID%TYPE;
	v_TRANSACTION_ID     INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	v_TRANSACTION_NAME   INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE; -- 64
	v_IS_FIRM            INTERCHANGE_TRANSACTION.IS_FIRM%TYPE;
	v_COMMODITY_ID       IT_COMMODITY.COMMODITY_ID%TYPE;
	v_PRICE_INTERVAL     VARCHAR2(9);

BEGIN

	-- use MM_NYISO.g_REALTIMEINTEGRATED for hour
	v_PRICE_INTERVAL := MM_NYISO_UTIL.GET_PRICE_INTERVAL(MM_NYISO_UTIL.g_REALTIMEINTEGRATED);

	-- using external_identifier = p_INTERFACE_NAME as a service point lookup
	-- generate a unique name and alias, return service point name and id too
	v_TRANSACTION_NAME := CREATE_TRANSACTION_NAME(p_INTERFACE_NAME,
												  p_MARKET_TYPE,
												  v_SERVICE_POINT_NAME,
												  v_SERVICE_POINT_ID,
												  p_LOGGER);

	IF v_TRANSACTION_NAME IS NOT NULL THEN

		--we need the commodity_id , if no record add one
		IF p_MARKET_TYPE = g_TTC_DAM_SCHED_TYPE OR
		   p_MARKET_TYPE = g_ATC_DAM_FIRM_SCHED_TYPE OR
		   p_MARKET_TYPE = g_ATC_DAM_NONFIRM_SCHED_TYPE THEN
			v_COMMODITY_ID := MM_NYISO_UTIL.GET_COMMODITY_ID(MM_NYISO_UTIL.g_XFER_CAP_DA);
		ELSE
			v_COMMODITY_ID := MM_NYISO_UTIL.GET_COMMODITY_ID(MM_NYISO_UTIL.g_XFER_CAP_HA);
		END IF;

		IF v_COMMODITY_ID = -1 THEN
			v_COMMODITY_ID := 0;
		END IF;

		IF p_MARKET_TYPE = g_ATC_DAM_FIRM_SCHED_TYPE OR
		   p_MARKET_TYPE = g_ATC_HAM_FIRM_SCHED_TYPE THEN
			v_IS_FIRM := 1;
		ELSE
			v_IS_FIRM := 0;
		END IF;

		BEGIN
			-- look for existing ID
			SELECT TRANSACTION_ID
			  INTO v_TRANSACTION_ID
			  FROM INTERCHANGE_TRANSACTION T
			 WHERE POD_ID = v_SERVICE_POINT_ID
			   AND TRANSACTION_IDENTIFIER = v_TRANSACTION_NAME -- provides ATC/TTC info
			   AND COMMODITY_ID = v_COMMODITY_ID
			   AND IS_FIRM = v_IS_FIRM
			   AND TRANSACTION_TYPE = 'Market Result'
			   AND SC_ID = MM_NYISO_UTIL.g_NYISO_SC_ID;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_TRANSACTION_ID := 0;
		END;

		IF v_TRANSACTION_ID = 0 THEN
			--create a new transaction

			BEGIN

				/*IF p_MARKET_TYPE = g_ATC_DAM_FIRM_SCHED_TYPE OR
                   p_MARKET_TYPE = g_ATC_HAM_FIRM_SCHED_TYPE THEN
                  v_IS_FIRM := 1;
                ELSE
                  v_IS_FIRM := 0;
                END IF;*/
				-- return existing ID matching on P_TRANSACTION_NAME or create new
				EM.PUT_TRANSACTION(o_OID                      => v_TRANSACTION_ID,
								   P_TRANSACTION_NAME         => v_TRANSACTION_NAME,
								   P_TRANSACTION_ALIAS        => NULL,
								   P_TRANSACTION_DESC         => 'Created by MarketManager via ATC TTC import',
								   P_TRANSACTION_ID           => 0,
								   p_TRANSACTION_STATUS       => 'Active',
								   P_TRANSACTION_TYPE         => 'Market Result',
								   P_TRANSACTION_IDENTIFIER   => v_TRANSACTION_NAME,
								   p_IS_FIRM                  => v_IS_FIRM,
								   p_IS_IMPORT_SCHEDULE       => 0,
								   p_IS_EXPORT_SCHEDULE       => 0,
								   P_IS_BALANCE_TRANSACTION   => 0,
								   p_IS_BID_OFFER             => 0,
								   P_IS_EXCLUDE_FROM_POSITION => 0,
								   P_IS_IMPORT_EXPORT         => 0,
								   p_IS_DISPATCHABLE          => 0,
								   P_TRANSACTION_INTERVAL     => v_PRICE_INTERVAL,
								   P_EXTERNAL_INTERVAL        => '?',
								   P_ETAG_CODE                => NULL,
								   p_BEGIN_DATE               => LOW_DATE,
								   p_END_DATE                 => HIGH_DATE,
								   p_PURCHASER_ID             => 0,
								   p_SELLER_ID                => 0,
								   p_CONTRACT_ID              => 0,
								   p_SC_ID                    => MM_NYISO_UTIL.G_NYISO_SC_ID,
								   p_POR_ID                   => 0,
								   p_POD_ID                   => v_SERVICE_POINT_ID,
								   P_COMMODITY_ID             => v_COMMODITY_ID,
								   P_SERVICE_TYPE_ID          => 0,
								   P_TX_TRANSACTION_ID        => 0,
								   P_PATH_ID                  => 0,
								   P_LINK_TRANSACTION_ID      => 0,
								   P_EDC_ID                   => 0,
								   P_PSE_ID                   => 0,
								   P_ESP_ID                   => 0,
								   P_POOL_ID                  => 0,
								   P_SCHEDULE_GROUP_ID        => 0,
								   P_MARKET_PRICE_ID          => 0,
								   P_ZOR_ID                   => 0,
								   P_ZOD_ID                   => 0,
								   P_SOURCE_ID                => 0,
								   P_SINK_ID                  => 0,
								   P_RESOURCE_ID              => 0,
								   P_AGREEMENT_TYPE           => NULL,
								   P_APPROVAL_TYPE            => NULL,
								   P_LOSS_OPTION              => NULL,
								   P_TRAIT_CATEGORY           => NULL,
								   P_TP_ID                    => 0);

				COMMIT;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					-- no service point, so no market price
					V_TRANSACTION_ID := NULL;
			END;
		END IF;
	END IF;

	RETURN V_TRANSACTION_ID;

EXCEPTION
	WHEN OTHERS THEN
		p_LOGGER.LOG_ERROR('Could not create transaction (' || v_TRANSACTION_NAME || ')');
		RAISE;
END GET_IT_TRANSACTION_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE CALCULATE_NON_FIRM(p_FIRM     IN MEX_SCHEDULE_TBL,
							 p_TOTAL    IN MEX_SCHEDULE_TBL,
							 p_NON_FIRM IN OUT MEX_SCHEDULE_TBL) AS

BEGIN
	-- calculate non firm value from total - firm
	p_NON_FIRM.DELETE;
	FOR X IN (SELECT T.CUT_TIME CUT_TIME, T.VOLUME - F.VOLUME VOLUME, T.RATE
				FROM TABLE(CAST(p_TOTAL AS MEX_SCHEDULE_TBL)) T,
					 TABLE(CAST(p_FIRM AS MEX_SCHEDULE_TBL)) F
			   WHERE T.CUT_TIME = F.CUT_TIME) LOOP
		P_NON_FIRM.EXTEND;
		P_NON_FIRM(P_NON_FIRM.LAST) := MEX_SCHEDULE(X.CUT_TIME,
													X.VOLUME,
													X.RATE);
	END LOOP;

END CALCULATE_NON_FIRM;

----------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ATC_TTC(p_ACTION  IN VARCHAR2,
						 p_RECORDS IN MEX_NY_XFER_CAP_SCHEDS_TBL,
						 p_LOGGER IN OUT MM_LOGGER_ADAPTER) IS

v_IDX       BINARY_INTEGER;
v_SCHED_IDX BINARY_INTEGER;
v_SCHED     MEX_SCHEDULE_TBL;

v_SCH_ROW     IT_SCHEDULE%ROWTYPE;
v_MARKET_TYPE VARCHAR2(32);

BEGIN

	p_LOGGER.LOG_INFO ('Attempting to store ATC/TTC values');

	v_IDX := p_RECORDS.FIRST;
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP

		FOR idx IN 1 .. 6 LOOP

			CASE idx
				WHEN 1 THEN
					-- Forecast TTC DAM
					v_SCHED       := p_RECORDS(v_IDX).TTC_DAM_SCHED;
					v_MARKET_TYPE := g_TTC_DAM_SCHED_TYPE;

				WHEN 2 THEN
					-- Forecast ATC Firm DAM
					v_SCHED       := p_RECORDS(v_IDX).ATC_DAM_FIRMS_SCHED; -- w/o non-firms
					v_MARKET_TYPE := g_ATC_DAM_FIRM_SCHED_TYPE;

				WHEN 3 THEN
					-- Forecast ATC Non-Firm DAM
					-- calculate Non-Firm
					v_SCHED       := p_RECORDS(v_IDX).ATC_DAM_TOTAL_SCHED;
					v_MARKET_TYPE := g_ATC_DAM_NONFIRM_SCHED_TYPE;

				WHEN 4 THEN
					-- Forecast TTC HAM
					v_SCHED       := p_RECORDS(v_IDX).TTC_HAM_SCHED;
					v_MARKET_TYPE := g_TTC_HAM_SCHED_TYPE;

				WHEN 5 THEN
					-- Forecast ATC Firm HAM
					v_SCHED       := p_RECORDS(v_IDX).ATC_HAM_FIRMS_SCHED; -- w/o non-firms
					v_MARKET_TYPE := g_ATC_HAM_FIRM_SCHED_TYPE;

				WHEN 6 THEN
					-- Forecast ATC Non-Firm HAM
					-- calculate Non-Firm
					v_SCHED       := p_RECORDS(v_IDX).ATC_HAM_TOTAL_SCHED;
					v_MARKET_TYPE := g_ATC_HAM_NONFIRM_SCHED_TYPE;
			END CASE;

			IF v_SCHED.COUNT > 0 THEN

				--IF v_LAST_PNODE_ID != p_RECORDS(v_IDX).INTERFACE_NAME THEN
				--    v_LAST_PNODE_ID           := p_RECORDS(v_IDX).INTERFACE_NAME;
				v_SCH_ROW.TRANSACTION_ID := GET_IT_TRANSACTION_ID(p_RECORDS(v_IDX).INTERFACE_NAME, v_MARKET_TYPE, p_LOGGER);
				--END IF;

				IF v_SCH_ROW.TRANSACTION_ID IS NOT NULL AND
				   v_SCH_ROW.TRANSACTION_ID <> -1 THEN

					v_SCH_ROW.AS_OF_DATE     := LOW_DATE;
					v_SCH_ROW.SCHEDULE_STATE := GA.INTERNAL_STATE;
					v_SCH_ROW.SCHEDULE_TYPE  := GA.SCHEDULE_TYPE_FORECAST;

					v_SCHED_IDX := v_SCHED.FIRST;

					WHILE v_SCHED.EXISTS(v_SCHED_IDX) LOOP

						BEGIN
							v_SCH_ROW.SCHEDULE_DATE := v_SCHED(v_SCHED_IDX).CUT_TIME;
							v_SCH_ROW.AMOUNT        := v_SCHED(v_SCHED_IDX).VOLUME;
							v_SCH_ROW.PRICE         := v_SCHED(v_SCHED_IDX).RATE;

							INSERT INTO IT_SCHEDULE
								(TRANSACTION_ID,
								 SCHEDULE_TYPE,
								 SCHEDULE_STATE,
								 SCHEDULE_DATE,
								 AS_OF_DATE,
								 AMOUNT,
								 PRICE)
							VALUES
								(v_SCH_ROW.TRANSACTION_ID,
								 v_SCH_ROW.SCHEDULE_TYPE,
								 v_SCH_ROW.SCHEDULE_STATE,
								 v_SCH_ROW.SCHEDULE_DATE,
								 v_SCH_ROW.AS_OF_DATE,
								 v_SCH_ROW.AMOUNT,
								 v_SCH_ROW.PRICE);
						EXCEPTION
							--do an update for already existing entities
							WHEN DUP_VAL_ON_INDEX THEN
								UPDATE IT_SCHEDULE
								   SET AMOUNT = v_SCH_ROW.AMOUNT,
									   PRICE  = v_SCH_ROW.PRICE
								 WHERE TRANSACTION_ID =
									   v_SCH_ROW.TRANSACTION_ID
								   AND SCHEDULE_TYPE =
									   v_SCH_ROW.SCHEDULE_TYPE
								   AND SCHEDULE_STATE =
									   v_SCH_ROW.SCHEDULE_STATE
								   AND SCHEDULE_DATE =
									   v_SCH_ROW.SCHEDULE_DATE
								   AND AS_OF_DATE = v_SCH_ROW.AS_OF_DATE;
						END;

						v_SCHED_IDX := v_SCHED.NEXT(v_SCHED_IDX);
					END LOOP; -- schedule loop

				END IF; -- transaction id test
			END IF; -- schedule count test
		END LOOP; -- interface loop

		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	COMMIT;


EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE('ATC/TTC Data => Txn Id:' || v_SCH_ROW.TRANSACTION_ID ||
		                   ', Amount:' || v_SCH_ROW.AMOUNT ||
						   ', Price' || v_SCH_ROW.PRICE);

END IMPORT_ATC_TTC;
----------------------------------------------------------------------------------------------------
-- ACTIONS:
-- g_ATC_TTC - 'ATC TTC';
--
-- SCHED TYPES: GA.SCHEDULE_TYPE_PRELIM, GA.SCHEDULE_TYPE_FINAL
--
PROCEDURE QUERY_ATC_TTC
(
    p_ACTION IN VARCHAR2,
    p_DATE   IN DATE,
    p_STATUS OUT NUMBER,
    p_LOGGER IN OUT MM_LOGGER_ADAPTER
) IS

    v_LOAD_TBL MEX_NY_XFER_CAP_SCHEDS_TBL;
BEGIN
    p_STATUS := GA.SUCCESS;

    MEX_NYISO_TC.FETCH_ATC_TTC(p_DATE,
                               p_ACTION,
                               v_LOAD_TBL,
                               p_STATUS,
                               p_LOGGER);

    -- Save values into database
    ERRS.VALIDATE_STATUS('MEX_NYISO_TC.FETCH_ATC_TTC', p_STATUS);
    IMPORT_ATC_TTC(p_ACTION, v_LOAD_TBL, p_LOGGER);


END QUERY_ATC_TTC;
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
    v_MARKET_TYPE  VARCHAR2(64);
    v_CRED         MEX_CREDENTIALS;
    v_LOGGER       MM_LOGGER_ADAPTER;

BEGIN

	p_STATUS := GA.SUCCESS;

    MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID    => EC.ES_MEX_SWITCHBOARD, --EC.ES_NYISO,
                     p_EXTERNAL_ACCOUNT_NAME => NULL,
                     p_PROCESS_NAME          => 'NYISO:TC',
                     p_EXCHANGE_NAME         => p_EXCHANGE_TYPE,
                     p_LOG_TYPE              => p_LOG_TYPE,
                     p_TRACE_ON              => p_TRACE_ON,
                     p_CREDENTIALS           => v_CRED,
                     p_LOGGER                => v_LOGGER,
					 p_IS_PUBLIC 			 => TRUE);

    MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	DBMS_OUTPUT.put_line('Error Count1:' || LOGS.GET_ERROR_COUNT);

    --LOOP OVER DATES
    v_CURRENT_DATE := TRUNC(p_BEGIN_DATE);
    LOOP
        CASE p_EXCHANGE_TYPE
            WHEN g_ET_QUERY_ATC_TTC THEN
                v_MARKET_TYPE := MEX_NYISO.g_ATC_TTC;
				QUERY_ATC_TTC(v_MARKET_TYPE, v_CURRENT_DATE, p_STATUS, v_LOGGER);
            ELSE
                p_STATUS  := GA.GENERAL_EXCEPTION;
                p_MESSAGE := p_EXCHANGE_TYPE || ' is not a valid Action.';

        END CASE;

        EXIT WHEN v_CURRENT_DATE >= TRUNC(p_END_DATE);
        v_CURRENT_DATE := v_CURRENT_DATE + 1;
    END LOOP; -- day loop

    p_MESSAGE := v_LOGGER.GET_END_MESSAGE() || ' Error Count:' || LOGS.GET_ERROR_COUNT;
    MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
	DBMS_OUTPUT.put_line('Error Count1:' || LOGS.GET_ERROR_COUNT);

EXCEPTION
    WHEN OTHERS THEN
        p_MESSAGE := SQLERRM;
        p_STATUS  := SQLCODE;
        MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
-----------------------------------------------------------------------------------------------

END MM_NYISO_TC;
/
