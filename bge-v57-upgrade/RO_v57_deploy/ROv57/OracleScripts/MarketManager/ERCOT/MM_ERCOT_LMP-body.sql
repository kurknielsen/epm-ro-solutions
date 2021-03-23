CREATE OR REPLACE PACKAGE BODY MM_ERCOT_LMP IS

--MARKET CLEARING PRICES
--DEFINE CSCs (Commercially Significant Constraint in the ERCOT transmission system):
g_CSC1	CONSTANT VARCHAR2(20) := 'West to North';
g_CSC2	CONSTANT VARCHAR2(20) := 'South to North';
g_CSC3	CONSTANT VARCHAR2(20) := 'South to Houston';
g_CSC4	CONSTANT VARCHAR2(20) := 'North to Houston';
g_CSC5	CONSTANT VARCHAR2(20) := 'Northeast to North';
g_CSC6	CONSTANT VARCHAR2(20) := 'North to West';
g_CSC7	CONSTANT VARCHAR2(20) := 'North to South';


--ANCILLARY SERVICES
--Define The Ancillary Service Code.
/*g_NSRS CONSTANT VARCHAR2(4) := 'NSRS';		--Non-Spinning Reserve Service
g_DRS  CONSTANT VARCHAR2(4) := 'DRS';		--Regulation Down Service
g_URS  CONSTANT VARCHAR2(4) := 'URS';		--Regulation Up Service
g_RRS  CONSTANT VARCHAR2(4) := 'RRS';		--Responsive Reserve Service*/

g_LMP_MKT_PRICE     CONSTANT VARCHAR2(3) := 'LMP';
g_ANC_MKT_PRICE     CONSTANT VARCHAR2(10) := 'ANCILLARY';

-----------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_MARKET_PRICE_NAME(p_PRICE_TYPE        IN VARCHAR2,
								p_BASE_STRING       IN VARCHAR2,
								p_MARKET_PRICE_NAME OUT VARCHAR2,
                                p_DATE IN DATE,
								p_MESSAGE           OUT VARCHAR2) AS

	--BUILD MARKET PRICE NAME FOR MARKET CLEARING PRICE FOR ENERGY AND
	--SHADOW CLEARING PRICE FOR BALANCING ENERGY

	v_CONGESTION_ZONE_NAME VARCHAR2(9);
	v_PATH                 VARCHAR2(2);
	v_CSC_PATH             VARCHAR2(20);
	v_TMP_STR              VARCHAR2(20);

BEGIN

	IF p_PRICE_TYPE = g_LMP_MKT_PRICE THEN
		--Case of Market Clearing Prices
		IF SUBSTR(p_BASE_STRING, 1, 5) = 'MCPEL' THEN
			--MARKET CLEARING PRICE FOR ENERGY
			CASE SUBSTR(p_BASE_STRING, 7, 1)
				WHEN 'S' THEN
					v_CONGESTION_ZONE_NAME := 'SOUTH';
				WHEN 'N' THEN
					v_CONGESTION_ZONE_NAME := 'NORTH';
				WHEN 'W' THEN
					v_CONGESTION_ZONE_NAME := 'WEST';
				WHEN 'H' THEN
					v_CONGESTION_ZONE_NAME := 'HOUSTON';
				WHEN 'E' THEN
					v_CONGESTION_ZONE_NAME := 'NORTHEAST';
				ELSE
					p_MESSAGE := 'No market price name for this recorder: ' ||
								 p_BASE_STRING;
			END CASE;

			p_MARKET_PRICE_NAME := 'ERCOT-' || v_CONGESTION_ZONE_NAME ||
								   '-MCP';

		ELSE
			--BALANCING CLEARING PRICE FOR ENERGY
            v_PATH := REPLACE(SUBSTR(p_BASE_STRING, 9, 6), TO_CHAR(p_DATE,'YY') , '');

			CASE v_PATH
				WHEN 'WN' THEN
					v_CSC_PATH := g_CSC1;
				WHEN 'SN' THEN
					v_CSC_PATH := g_CSC2;
				WHEN 'SH' THEN
					v_CSC_PATH := g_CSC3;
				WHEN 'NH' THEN
					v_CSC_PATH := g_CSC4;
				WHEN 'EN' THEN
					v_CSC_PATH := g_CSC5;
				WHEN 'NW' THEN
					v_CSC_PATH := g_CSC6;
				WHEN 'NS' THEN
					v_CSC_PATH := g_CSC7;
				ELSE
					p_MESSAGE := 'No market price name for this recorder: ' ||
								 p_BASE_STRING;
			END CASE;

			p_MARKET_PRICE_NAME := 'ERCOT-' || v_CSC_PATH || '-MCP-BE';
		END IF;

	ELSE
		--case of Ancillary Serice Market Prices
		CASE p_BASE_STRING
			WHEN 'NSRS' THEN
				v_TMP_STR := 'Non-Spinning Reserve';
			WHEN 'DRS' THEN
				v_TMP_STR := 'Regulation Down';
			WHEN 'URS' THEN
				v_TMP_STR := 'Regulation Up';
			WHEN 'RRS' THEN
				v_TMP_STR := 'Responsive Reserve';
			ELSE
				p_MESSAGE := 'No market price name for this recorder: ' ||
							 p_BASE_STRING;
		END CASE;

		p_MARKET_PRICE_NAME := 'ERCOT-' || v_TMP_STR || ' Price';

	END IF;

END GET_MARKET_PRICE_NAME;
---------------------------------------------------------------------------------------------------------------------
PROCEDURE GET_TXN_NAME(p_BASE_STRING IN VARCHAR2,
					   p_TXN_NAME    OUT VARCHAR2,
					   p_MESSAGE     OUT VARCHAR2) AS

	v_TMP_STR VARCHAR2(32);
BEGIN

	CASE p_BASE_STRING
		WHEN 'NSRS' THEN
			v_TMP_STR := 'Non-Spinning Reserve Service';
		WHEN 'DRS' THEN
			v_TMP_STR := 'Regulation Down Service';
		WHEN 'URS' THEN
			v_TMP_STR := 'Regulation Up Service';
		WHEN 'RRS' THEN
			v_TMP_STR := 'Responsive Reserve Service';

		ELSE
			p_MESSAGE := 'No transaction name for this Ancillary Service Code: ' ||
						 p_BASE_STRING;
	END CASE;

	p_TXN_NAME := 'ERCOT-' || v_TMP_STR || ' Requirement';

END GET_TXN_NAME;
---------------------------------------------------------------------------------------------------------------------
-- MARKET_TYPES:  'RealTime'
-- PRICE_TYPES:  'Market Clearing Price,'
--
PROCEDURE ID_FOR_MARKET_PRICE(p_MARKET_PRICE_NAME   IN VARCHAR2,
							  p_PRICE_INTERVAL      IN VARCHAR2,
							  p_MARKET_TYPE         IN VARCHAR2,
							  p_COMMODITY_ID        IN NUMBER,
							  p_SC_ID               IN NUMBER,
							  p_POD_ID              IN NUMBER,
							  p_CREATE_IF_NOT_FOUND IN BOOLEAN,
							  p_MARKET_PRICE_ID     OUT NUMBER,
							  p_MESSAGE             OUT VARCHAR2) AS

	v_MKT_PRICE_ALIAS     MARKET_PRICE.MARKET_PRICE_ALIAS%TYPE;
	v_EXTERNAL_IDENTIFIER MARKET_PRICE.EXTERNAL_IDENTIFIER%TYPE;

	v_MKT_PRICE_TYPE VARCHAR2(32) := 'Market Clearing Price';

BEGIN

	IF p_MARKET_PRICE_NAME IS NULL THEN
		p_MARKET_PRICE_ID := 0;
		RETURN;
	END IF;

	IF SUBSTR(p_MARKET_PRICE_NAME,-3) ='MCP' THEN
		v_EXTERNAL_IDENTIFIER := 'MCP';
	ELSE
		v_EXTERNAL_IDENTIFIER := LTRIM(RTRIM(p_MARKET_PRICE_NAME));
	END IF;

	v_MKT_PRICE_ALIAS := SUBSTR(p_MARKET_PRICE_NAME, 1,32);

	IF p_MARKET_PRICE_NAME IS NOT NULL THEN
		BEGIN

			SELECT MARKET_PRICE_ID
			  INTO p_MARKET_PRICE_ID
			  FROM MARKET_PRICE
			 WHERE MARKET_PRICE_ALIAS = v_MKT_PRICE_ALIAS;

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				IF p_CREATE_IF_NOT_FOUND THEN

					IO.PUT_MARKET_PRICE(p_MARKET_PRICE_ID,
										p_MARKET_PRICE_NAME,
										v_MKT_PRICE_ALIAS, -- ALIAS
										'Created by MarketManager via Market Price import', -- DESC
										0,
										v_MKT_PRICE_TYPE, -- MARKET_PRICE_TYPE
										p_PRICE_INTERVAL, --MARKET_PRICE_INTERVAL
										p_MARKET_TYPE, --MARKET_TYPE
										p_COMMODITY_ID,
										'Point', -- SERVICE_POINT_TYPE
										v_EXTERNAL_IDENTIFIER, -- EXTERNAL_IDENTIFIER
										0, -- EDC_ID
										p_SC_ID, -- SC_ID
										p_POD_ID, -- POD_ID
										0);

				ELSE
					p_MARKET_PRICE_ID := GA.NO_DATA_FOUND;
				END IF;

			WHEN OTHERS THEN
				RAISE;
		END;
	END IF;

END ID_FOR_MARKET_PRICE;
--------------------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LMP(p_WORK_ID IN NUMBER,
					 p_STATUS  OUT NUMBER,
					 p_MESSAGE OUT VARCHAR2) AS

	v_COMMODITY_ID      NUMBER(9) := MM_ERCOT_UTIL.GET_COMMODITY_ID(MM_ERCOT_UTIL.g_MKT_CLEARING_PRICE);
	v_SC_ID             NUMBER(9) := MM_ERCOT_UTIL.GET_ERCOT_SC_ID;
	v_MARKET_PRICE_ID   NUMBER(9);
	v_IDENT             NUMBER(10);
	v_PREV_IDENT        NUMBER(10) := 1;
	v_PRICE_DATE        DATE;
	v_MARKET_PRICE_NAME MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
	v_POD_ID            NUMBER(9);
	v_EXTERNAL_IDENT    VARCHAR2(6);
	v_YEAR              VARCHAR2(2);



	CURSOR c_MKT_PRICES IS
		SELECT A.INTERVAL_DATA_ID, A.RECORDER, B.TRADE_DATE, B.LOAD_AMOUNT
		  FROM ERCOT_MARKET_HEADER_WORK A, ERCOT_MARKET_DATA_WORK B
		 WHERE A.INTERVAL_DATA_ID = B.INTERVAL_DATA_ID
		   AND A.WORK_ID = p_WORK_ID
           AND A.WORK_ID = B.WORK_ID
		   AND (A.RECORDER LIKE 'MCPEL%' OR A.RECORDER LIKE 'MCPESPC%');

BEGIN
	p_STATUS := GA.SUCCESS;

	FOR v_MKT_PRICES IN c_MKT_PRICES LOOP
		v_IDENT      := v_MKT_PRICES.INTERVAL_DATA_ID;
		v_PRICE_DATE := v_MKT_PRICES.TRADE_DATE;

		IF v_PREV_IDENT <> v_IDENT THEN
			--BUILD MARKET PRICE NAME BASED ON RECORDER INFORMATION
			GET_MARKET_PRICE_NAME(g_LMP_MKT_PRICE,
							  v_MKT_PRICES.RECORDER,
							  v_MARKET_PRICE_NAME,
                              v_PRICE_DATE,
							  p_MESSAGE);

			--GET POD_ID FOR MARKET CLEARING PRICE FOR ENERGY
        	IF SUBSTR(v_MKT_PRICES.RECORDER, 1, 5) = 'MCPEL' THEN
				v_EXTERNAL_IDENT := SUBSTR(v_MKT_PRICES.RECORDER, 7, 1);
        		v_POD_ID := MM_ERCOT_UTIL.GET_POD_ID(v_EXTERNAL_IDENT);

			--GET POD_ID FOR Shadow Clearing Price for Balancing Energy
        	ELSE
				v_EXTERNAL_IDENT := SUBSTR(v_MKT_PRICES.RECORDER,-6);
				v_YEAR := TO_CHAR(v_MKT_PRICES.TRADE_DATE,'YY');
				v_POD_ID := MM_ERCOT_UTIL.GET_POD_ID(REPLACE(v_EXTERNAL_IDENT,v_YEAR,''));

        	END IF;

			ID_FOR_MARKET_PRICE(v_MARKET_PRICE_NAME,
			                    '15 Minute',
								'Real-Time',
								v_COMMODITY_ID,
								v_SC_ID,
								v_POD_ID,
								TRUE,
								v_MARKET_PRICE_ID,
								p_MESSAGE);
			v_PREV_IDENT := v_IDENT;
		END IF;

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('INSERTING MARKET PRICE FOR DATE=' ||
						   UT.TRACE_DATE(v_PRICE_DATE) || ' ID=' ||
						   TO_CHAR(v_MARKET_PRICE_ID) || ' IDENT=' ||
						   v_IDENT);
		END IF;

		MM_UTIL.PUT_MARKET_PRICE_VALUE(p_MARKET_PRICE_ID => v_MARKET_PRICE_ID,
										p_PRICE_DATE => v_PRICE_DATE,
										p_PRICE_CODE => 'A',
										p_PRICE => v_MKT_PRICES.LOAD_AMOUNT,
										p_PRICE_BASIS => 0,
										p_STATUS => p_STATUS,
										p_ERROR_MESSAGE => p_MESSAGE);

	END LOOP;

	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error IN MM_ERCOT_LMP.IMPORT_LMP: ' || SQLERRM;

END IMPORT_LMP;
---------------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ANCILLARY_PRICE(p_TBL     IN MEX_ERCOT_ANCILLARY_SERV_TBL,
								 p_STATUS  OUT NUMBER,
								 p_MESSAGE OUT VARCHAR2) AS

	v_REC MEX_ERCOT_ANCILLARY_SERV;
	v_IDX BINARY_INTEGER;

	v_COMMODITY_ID      NUMBER(9) := MM_ERCOT_UTIL.GET_COMMODITY_ID(MM_ERCOT_UTIL.g_ANCILLARY_SERVICE);
	v_SC_ID             NUMBER(9) := MM_ERCOT_UTIL.GET_ERCOT_SC_ID;
	v_MARKET_PRICE_NAME MARKET_PRICE.MARKET_PRICE_NAME%TYPE;
	v_TXN_NAME          INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
	v_SERVICE_TYPE      VARCHAR2(4);
	v_PREV_SERVICE_TYPE VARCHAR2(4) := 'PREV';
	v_MARKET_PRICE_ID NUMBER(9);
	v_TRANSACTION_ID NUMBER(9);

BEGIN

	--Loop over records
	FOR v_IDX IN p_TBL.FIRST .. p_TBL.LAST LOOP

		v_REC          := p_TBL(v_IDX);
		v_SERVICE_TYPE := v_REC.SERVICE_TYPE;

		IF v_PREV_SERVICE_TYPE <> v_SERVICE_TYPE THEN
			--BUILD MARKET PRICE NAME BASED ON ANCILLARY SERVICE CODE
			GET_MARKET_PRICE_NAME(g_ANC_MKT_PRICE,
								  v_REC.SERVICE_TYPE,
								  v_MARKET_PRICE_NAME,
                                  v_REC.HOUR_ENDING,
								  p_MESSAGE);
			--GET MAARKET PRICE ID
			ID_FOR_MARKET_PRICE(v_MARKET_PRICE_NAME,
								'Hour',
								'Day-Ahead',
								v_COMMODITY_ID,
								v_SC_ID,
								0,
								TRUE,
								v_MARKET_PRICE_ID,
								p_MESSAGE);

			--TRANSACTION NAME
			GET_TXN_NAME(v_REC.SERVICE_TYPE, v_TXN_NAME, p_MESSAGE);
			--TRANSACTION_ID
			v_TRANSACTION_ID := MM_ERCOT_UTIL.GET_TX_ID(v_SERVICE_TYPE,
														'Requirement',
														v_TXN_NAME,
														'Hour',
														v_COMMODITY_ID);

			v_PREV_SERVICE_TYPE := v_SERVICE_TYPE;
		END IF;

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('INSERTING MARKET PRICE FOR DATE=' ||
						   UT.TRACE_DATE(v_REC.HOUR_ENDING) || ' ID=' ||
						   TO_CHAR(v_MARKET_PRICE_ID) || ' IDENT=' ||
						   v_SERVICE_TYPE);
			LOGS.LOG_DEBUG('INSERTING SCHEDULE VALUE FOR DATE=' ||
						   UT.TRACE_DATE(v_REC.HOUR_ENDING) || ' ID=' ||
						   TO_CHAR(v_TRANSACTION_ID) || ' IDENT=' ||
						   v_SERVICE_TYPE);
		END IF;

		MM_UTIL.PUT_MARKET_PRICE_VALUE(p_MARKET_PRICE_ID => v_MARKET_PRICE_ID,
									   p_PRICE_DATE      => v_REC.HOUR_ENDING,
									   p_PRICE_CODE      => 'A',
									   p_PRICE           => v_REC.CLEARING_PRICE,
									   p_PRICE_BASIS     => 0,
									   p_STATUS          => p_STATUS,
									   p_ERROR_MESSAGE   => p_MESSAGE);

		MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
										 v_REC.HOUR_ENDING,
										 v_REC.REQUESTED_MW,
										 1);

	END LOOP;

	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error IN MM_ERCOT_LMP.IMPORT_ANCILLARY_PRICE: ' ||
					 SQLERRM;

END IMPORT_ANCILLARY_PRICE;
----------------------------------------------------------------------------------------------------------
PROCEDURE QUERY_LMP(p_CRED			IN mex_credentials,
					p_PRICE_TYPE    IN VARCHAR2,
					p_BEGIN_DATE    IN DATE,
					p_END_DATE      IN DATE,
					p_LOG_ONLY      IN NUMBER,
					p_STATUS        OUT NUMBER,
					p_ERROR_MESSAGE OUT VARCHAR2,
					p_LOGGER		IN OUT mm_logger_adapter) AS

	v_MKT_PRICE_ZIP_LST PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_IDX               NUMBER := 1;
	v_FILE_NAME         VARCHAR2(64);
	v_WORK_ID           NUMBER;

	v_TBL MEX_ERCOT_ANCILLARY_SERV_TBL;

BEGIN

	p_STATUS    := GA.SUCCESS;

	--USE ERCOT PUBLIC SITE TO RETRIEVE ALL THESE FILES
	--GET THE LIST OF MKT PRICES ZIP FILES FOR THE REQUESTED DATE RANGE
	MEX_ERCOT_LMP.FETCH_HIST_PAGE(p_CRED,
								  p_PRICE_TYPE,
								  p_BEGIN_DATE,
								  p_END_DATE,
								  p_LOG_ONLY,
								  v_MKT_PRICE_ZIP_LST,
								  p_STATUS,
								  p_ERROR_MESSAGE,
								  p_LOGGER);

	--RETRIEVE MARKET PRICES FROM EACH ZIP FILE
	v_IDX := v_MKT_PRICE_ZIP_LST.FIRST;
	WHILE v_MKT_PRICE_ZIP_LST.EXISTS(v_IDX) LOOP
		v_FILE_NAME := v_MKT_PRICE_ZIP_LST(v_IDX);

		IF p_PRICE_TYPE = g_LMP_MKT_PRICE THEN
			MEX_ERCOT_LMP.FETCH_MKT_CLEARING_PRICE(p_CRED,
												   v_FILE_NAME,
												   p_LOG_ONLY,
												   v_WORK_ID,
												   p_STATUS,
												   p_ERROR_MESSAGE,
												   p_LOGGER);

			IF p_ERROR_MESSAGE IS NULL THEN
				IMPORT_LMP(v_WORK_ID, p_STATUS, p_ERROR_MESSAGE);
			END IF;

			-- CLEANUP THE WORKING TABLES
			DELETE ERCOT_MARKET_HEADER_WORK WHERE WORK_ID =v_WORK_ID;
			DELETE ERCOT_MARKET_DATA_WORK WHERE WORK_ID = v_WORK_ID;

		ELSE
			MEX_ERCOT_LMP.FETCH_ANCILLARY_SERVICE(p_CRED,
												  v_FILE_NAME,
												  p_LOG_ONLY,
												  v_TBL,
												  p_STATUS,
												  p_ERROR_MESSAGE,
												  p_LOGGER);

			IF p_ERROR_MESSAGE IS NULL THEN
				IMPORT_ANCILLARY_PRICE(v_TBL,
									   p_STATUS,
									   p_ERROR_MESSAGE);
			END IF;

		END IF;

		v_IDX := v_IDX + 1;
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS        := SQLCODE;
		p_ERROR_MESSAGE := 'Error IN MM_ERCOT_LMP.QUERY_LMP: ' || SQLERRM;

END QUERY_LMP;
-----------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

	v_LOG_ONLY            NUMBER(1) := 0;
	v_ACTION              VARCHAR2(64);

	v_CRED		mex_credentials;
	v_LOGGER	mm_logger_adapter;
BEGIN
	v_LOG_ONLY := NVL(p_LOG_ONLY,0);
	v_ACTION := p_EXCHANGE_TYPE;

	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_ERCOT,
		p_EXTERNAL_ACCOUNT_NAME => NULL,
		p_PROCESS_NAME => 'ERCOT:LMP',
		p_EXCHANGE_NAME => v_ACTION,
		p_LOG_TYPE => p_LOG_TYPE,
		p_TRACE_ON => p_TRACE_ON,
		p_CREDENTIALS => v_CRED,
		p_LOGGER => v_LOGGER,
		p_IS_PUBLIC => TRUE);

	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	CASE v_ACTION
    	WHEN g_ET_QUERY_MRKT_CLRING_PRICES THEN
		   QUERY_LMP(v_CRED, g_LMP_MKT_PRICE, p_BEGIN_DATE, p_END_DATE, v_LOG_ONLY,p_STATUS, p_MESSAGE, v_LOGGER);

		WHEN g_ET_QUERY_ANC_SERVICE_PRICES THEN
			QUERY_LMP(v_CRED, g_ANC_MKT_PRICE, p_BEGIN_DATE, p_END_DATE,v_LOG_ONLY,p_STATUS, p_MESSAGE, v_LOGGER);

		ELSE
			p_STATUS := -1;
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
			v_LOGGER.LOG_ERROR(p_MESSAGE);
    END CASE;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
--------------------------------------------------------------------------------------
END MM_ERCOT_LMP;
/
