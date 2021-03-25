CREATE OR REPLACE PACKAGE BODY MM_MISO_PSS IS

  -- Private constant declarations
	g_TIME_ZONE CONSTANT VARCHAR2(3) := 'EST';
  -------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_CONTRACT_ID_FOR_ISO_ACCT(p_ACCT_NAME IN VARCHAR2)
	RETURN NUMBER IS
	--RETURN THE CONTRACT FOR THE ISO ACCOUNT NAME
	v_CONTRACT INTERCHANGE_CONTRACT%ROWTYPE;

BEGIN
	SELECT *
	  INTO v_CONTRACT
	  FROM INTERCHANGE_CONTRACT
	 WHERE CONTRACT_ALIAS = p_ACCT_NAME;

	RETURN v_CONTRACT.CONTRACT_ID;
END GET_CONTRACT_ID_FOR_ISO_ACCT;
------------------------------------------------------------------------------------
FUNCTION ID_FOR_PORPOD(p_PORPOD_IDENT        IN VARCHAR2,
					   p_TP_NAME             IN VARCHAR2,
					   p_CREATE_IF_NOT_FOUND IN BOOLEAN) RETURN NUMBER IS

	v_TSIN_PORPOD_ID NUMBER(9);
	v_PORPOD_ID NUMBER(9);

BEGIN

	--Get POR/POD ID from TSIN names
	SELECT T.PORPODPOINTID
	  INTO v_TSIN_PORPOD_ID
	  FROM TSIN_POR_POD_POINT T, TSIN_TP_REGISTRY D
	 WHERE T.POINTNAME = p_PORPOD_IDENT
	   AND T.TP_ENTITY_ID = D.TAGGING_ENTITY_ID
	   AND D.TAG_CODE = p_TP_NAME;

	ID.ID_FOR_SERVICE_POINT_XID(p_EXTERNAL_IDENTIFIER => v_TSIN_PORPOD_ID,
								p_CREATE_IF_NOT_FOUND => p_CREATE_IF_NOT_FOUND,
								p_SERVICE_POINT_ID    =>v_PORPOD_ID);

	RETURN v_PORPOD_ID;

END ID_FOR_PORPOD;
-------------------------------------------------------------------------------------
FUNCTION GET_TRANSMISSION_PROVIDER_ID(p_TP_NAME             IN VARCHAR2,
									  p_CREATE_IF_NOT_FOUND IN BOOLEAN)
	RETURN NUMBER IS

	v_TP_ID   NUMBER(9);
	v_DUNS    TSIN_ENTITY_REGISTRY.DUNS%TYPE;
	v_NERC_ID TSIN_ENTITY_REGISTRY.NERC_ID%TYPE;

BEGIN
	BEGIN
		SELECT TP.TP_ID
		  INTO v_TP_ID
		  FROM TRANSMISSION_PROVIDER TP
		 WHERE TP.TP_ALIAS = p_TP_NAME;

	EXCEPTION
		--CREATE IF IT DOES NOT EXIST.
		WHEN NO_DATA_FOUND THEN
			IF p_CREATE_IF_NOT_FOUND THEN
				SELECT NERC_ID, DUNS
				  INTO v_NERC_ID, v_DUNS
				  FROM TSIN_ENTITY_REGISTRY T
				 WHERE ENTITY_CODE = p_TP_NAME;

				IO.PUT_TP(v_TP_ID,
						  p_TP_NAME,
						  p_TP_NAME,
						  p_TP_NAME,
						  0,
						  TO_CHAR(v_NERC_ID),
						  'Active',
						  TO_CHAR(v_DUNS),
						  NULL);
			END IF;
	END;

	RETURN v_TP_ID;

END GET_TRANSMISSION_PROVIDER_ID;
-------------------------------------------------------------------------------------
PROCEDURE CREATE_PSS_TRANSACTION(p_ACCT_NAME            IN VARCHAR2,
                                 p_TRANSACTION_NAME     IN VARCHAR2,
								 p_SOURCE               IN VARCHAR2,
								 p_SINK                 IN VARCHAR2,
								 p_POR                  IN VARCHAR2,
								 p_POD                  IN VARCHAR2,
								 p_TRANSACTION_INTERVAL IN VARCHAR2,
								 p_PROVIDER             IN VARCHAR2,
								 p_MARKET_TYPE          IN VARCHAR2,
								 p_START_DATE           IN DATE,
								 p_TRANSACTION_ID       OUT NUMBER) AS

	v_TRANSACTION      INTERCHANGE_TRANSACTION%ROWTYPE;
	v_TRAIT_CATEGORY   INTERCHANGE_TRANSACTION.TRAIT_CATEGORY%TYPE := 'MISO:PSS';

BEGIN

	--CREATE THE TRANSACTION
	v_TRANSACTION.TRANSACTION_NAME       := 'MISO:PSS:' || p_TRANSACTION_NAME;
	v_TRANSACTION.TRANSACTION_ALIAS      := SUBSTR(v_TRANSACTION.Transaction_Name,32);
	v_TRANSACTION.TRANSACTION_DESC       := 'Generated by Market Manager';
	v_TRANSACTION.TRANSACTION_IDENTIFIER := v_TRANSACTION.Transaction_Name;
	v_TRANSACTION.TRANSACTION_INTERVAL   := p_TRANSACTION_INTERVAL;
	v_TRANSACTION.BEGIN_DATE     := p_START_DATE;
	v_TRANSACTION.END_DATE       := p_START_DATE;
	v_TRANSACTION.CONTRACT_ID    := GET_CONTRACT_ID_FOR_ISO_ACCT(p_ACCT_NAME);
	ID.ID_FOR_SC('MISO', TRUE, v_TRANSACTION.SC_ID);

	--Check the TSIN tables for the related ids
	--Update Service_Point.External_Identifier with TSIN ids
	v_TRANSACTION.POR_ID := ID_FOR_PORPOD(p_POR, p_PROVIDER,TRUE);
    v_TRANSACTION.POD_ID := ID_FOR_PORPOD(p_POD, p_PROVIDER,TRUE);

	IF p_MARKET_TYPE = 'DA' THEN
		ID.ID_FOR_COMMODITY('DayAhead Energy', TRUE, v_TRANSACTION.COMMODITY_ID);
	ELSE
		ID.ID_FOR_COMMODITY('RealTime Energy', TRUE, v_TRANSACTION.COMMODITY_ID);
	END IF;

	--Update the Service_Point table with Source and Sink
	--if they don't exist.
	ID.ID_FOR_SERVICE_POINT_XID(p_SOURCE, TRUE, v_TRANSACTION.SOURCE_ID);
	ID.ID_FOR_SERVICE_POINT_XID(p_SINK, TRUE, v_TRANSACTION.SINK_ID);

	v_TRANSACTION.TP_ID          := GET_TRANSMISSION_PROVIDER_ID(p_PROVIDER, TRUE);
	v_TRANSACTION.TRAIT_CATEGORY := v_TRAIT_CATEGORY;

	v_TRANSACTION.TRANSACTION_ID  := 0;
	v_TRANSACTION.IS_BID_OFFER    := 1;
	v_TRANSACTION.IS_IMPORT_EXPORT := 1;
	v_TRANSACTION.AGREEMENT_TYPE := 'PSS';



	MM_UTIL.PUT_TRANSACTION(p_TRANSACTION_ID,
							v_TRANSACTION,
							GA.INTERNAL_STATE,
							'Active');
END CREATE_PSS_TRANSACTION;
-------------------------------------------------------------------------------------

PROCEDURE IMPORT_PSS_SCHEDULE(p_ACCT_NAME     IN VARCHAR2,
                              p_PSS_SCHEDULES IN XMLTYPE,
                              p_ERROR_MESSAGE OUT VARCHAR2) AS

	v_TRANSACTION_ID 	INTERCHANGE_TRANSACTION.TRANSACTION_ID%TYPE;
	v_TRANSACTION_IDENT INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER%TYPE;
	v_SOURCE        	VARCHAR2(50);
	v_SINK          	VARCHAR2(50);
	v_POD           	VARCHAR2(12);
	v_POR           	VARCHAR2(12);
	v_PATH          	VARCHAR2(50);
	v_INTERVAL      	VARCHAR2(8);
	v_SCHEDULE_NAME 	INTERCHANGE_TRANSACTION.TRANSACTION_NAME%TYPE;
	v_MARKET_TYPE   	IT_COMMODITY.MARKET_TYPE%TYPE;
	v_SCHEDULE_STATUS 	IT_STATUS.TRANSACTION_STATUS_NAME%TYPE;
	v_START_TIME		DATE;
	v_PROVIDER          TRANSMISSION_PROVIDER.TP_NAME%TYPE;
	v_DATE_INCREMENT 	INTERCHANGE_TRANSACTION.TRANSACTION_INTERVAL%TYPE;
	v_POS               NUMBER(2);
	v_STATUS            NUMBER;

	CURSOR c_XML IS
		SELECT EXTRACTVALUE(VALUE(T),'//ScheduleHeader/ScheduleName') "SCHEDULE_NAME",
	   	       EXTRACTVALUE(VALUE(T),'//ScheduleTable/SourceCA') "SOURCE",
	           EXTRACTVALUE(VALUE(T),'//ScheduleTable/SinkCA') "SINK",
	           EXTRACTVALUE(VALUE(T),'//ScheduleTable/MarketType') "MARKET_TYPE",
	           EXTRACTVALUE(VALUE(T),'//ScheduleTable/ProfileFormat') "PROFILE",
			   EXTRACTVALUE(VALUE(T),'//ScheduleTable/Path') "PATH",
	           EXTRACTVALUE(VALUE(T),'//ScheduleTable/ScheduleStatus') "SCHEDULE_STATUS",
			   TO_DATE(EXTRACTVALUE(VALUE(T), '//ScheduleProfileTable/Block/StartTime'),g_DATE_TIME_FORMAT) "START_TIME",
	           EXTRACTVALUE(VALUE(T),'//ScheduleProfileTable/Block/BidMW') "BID_MW",
	           EXTRACTVALUE(VALUE(T),'//ScheduleProfileTable/Block/ClearedMW') "CLEARED_MW",
	           EXTRACTVALUE(VALUE(T),'//OASISTable/Reservation/Provider') "PROVIDER"
		FROM TABLE(XMLSEQUENCE(EXTRACT(p_PSS_SCHEDULES,	'//MarketClearing/Schedule'))) T;


	BEGIN

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('IMPORT_PSS_SCHEDULE');
		END IF;

		--LOOP OVER EACH SCHEDULE
		FOR v_XML IN c_XML LOOP
			--GET EACH ELEMENT OF THE SCHEDULE
			v_SCHEDULE_NAME := v_XML.sCHEDULE_NAME;
			v_SOURCE := v_XML.SOURCE;
			v_SINK := v_XML.SINK;
			v_MARKET_TYPE := v_XML.MARKET_TYPE;
			v_INTERVAL := v_XML.PROFILE;
			--MAP THE VALUE
			CASE v_INTERVAL
				WHEN 'HOURLY' THEN v_DATE_INCREMENT := 'HOUR';
				ELSE v_DATE_INCREMENT := NULL;
			END CASE;

			--EXTRACT POR/POD FROM PATH
			v_PATH := v_XML.PATH;
			v_POS := INSTR(v_PATH,'/');
			v_POR := SUBSTR(v_PATH,1,v_POS-1);
			v_POD := SUBSTR(v_PATH,-(v_POS-1),LENGTH(v_PATH)-v_POS);

			v_SCHEDULE_STATUS := v_XML.SCHEDULE_STATUS;
			v_START_TIME := v_XML.START_TIME;

			v_PROVIDER := v_XML.PROVIDER;

			--TRY TO FIND THE INTERCHANGE TRANSACTION THAT APPLIES
			v_TRANSACTION_IDENT := 'MISO:PSS' || v_SCHEDULE_NAME;

			IF LOGS.IS_DEBUG_ENABLED THEN
				LOGS.LOG_DEBUG('LOOKING FOR PSS TXN:' || v_TRANSACTION_IDENT);
			END IF;

			BEGIN
    			SELECT TRANSACTION_ID
    			   INTO v_TRANSACTION_ID
    			   FROM INTERCHANGE_TRANSACTION
    			   WHERE TRANSACTION_IDENTIFIER = v_TRANSACTION_IDENT;

			--CREATE ONE IF IT DOES NOT EXIST.
			EXCEPTION
				WHEN NO_DATA_FOUND THEN

        			--IF MARKET_TYPE=DA/RT CREATE TWO TRANSACTIONS
        			--ONE FOR DA AND ANOTHER FOR RT
        			IF v_MARKET_TYPE<>'DA/RT' THEN
        				CREATE_PSS_TRANSACTION(p_ACCT_NAME,
        				                       v_SCHEDULE_NAME,
        				                       v_SOURCE,
        									   v_SINK,
        									   v_POR,
        									   v_POD,
        									   v_INTERVAL,
        									   v_PROVIDER,
        									   v_MARKET_TYPE,
        									   v_START_TIME,
        									   v_TRANSACTION_ID);

        			ELSE
        				CREATE_PSS_TRANSACTION(p_ACCT_NAME,
        				                       v_SCHEDULE_NAME,
        				                       v_SOURCE,
        									   v_SINK,
        									   v_POR,
        									   v_POD,
        									   v_INTERVAL,
        									   v_PROVIDER,
        									   'DA',
        									   v_START_TIME,
        									   v_TRANSACTION_ID);

        			    CREATE_PSS_TRANSACTION(p_ACCT_NAME,
        				                       v_SCHEDULE_NAME,
        				                       v_SOURCE,
        									   v_SINK,
        									   v_POR,
        									   v_POD,
        									   v_INTERVAL,
        									   v_PROVIDER,
        									   'RT',
        									   v_START_TIME,
        									   v_TRANSACTION_ID);
        			END IF;
			END;

			--Put Schedule data into IT_SCHEDULE, Internal
			MM_MISO_UTIL.PUT_IT_SCHEDULE_DATA(p_TRANSACTION_ID => v_TRANSACTION_ID,
			                                  p_SCHEDULE_DATE => v_START_TIME,
											  p_SCHEDULE_STATE => GA.INTERNAL_STATE,
											  p_PRICE => NULL,
											  p_AMOUNT => v_XML.CLEARED_MW,
											  p_STATUS => v_STATUS,
											  p_ERROR_MESSAGE => p_ERROR_MESSAGE);
			ERRS.VALIDATE_STATUS(v_STATUS, p_ERROR_MESSAGE);

			--Put Bid data into IT_TRAIT_SCHEDULE, Internal and External
			TG.PUT_IT_TRAIT_SCHEDULE(p_TRANSACTION_ID => v_TRANSACTION_ID,
			                         p_SCHEDULE_STATE => GA.INTERNAL_STATE,
									 p_SCHEDULE_TYPE => 0,
									 p_SCHEDULE_DATE => v_START_TIME,
									 p_TRAIT_GROUP_ID => TG.g_TG_OFFER_CURVE,
									 p_TRAIT_INDEX => TG.g_TI_OFFER_PRICE,
									 p_SET_NUMBER => 1,
									 p_TRAIT_VAL => v_XML.BID_MW,
									 p_TIME_ZONE => g_TIME_ZONE);

			TG.PUT_IT_TRAIT_SCHEDULE(p_TRANSACTION_ID => v_TRANSACTION_ID,
			                         p_SCHEDULE_STATE => GA.EXTERNAL_STATE,
									 p_SCHEDULE_TYPE => 0,
									 p_SCHEDULE_DATE => v_START_TIME,
									 p_TRAIT_GROUP_ID => TG.g_TG_OFFER_CURVE,
									 p_TRAIT_INDEX => TG.g_TI_OFFER_PRICE,
									 p_SET_NUMBER => 1,
									 p_TRAIT_VAL => v_XML.BID_MW,
									 p_TIME_ZONE => g_TIME_ZONE);



		END LOOP;


END IMPORT_PSS_SCHEDULE;
-------------------------------------------------------------------------------------
PROCEDURE QUERY_PSS_SCHEDULE_BIDS(p_CRED      IN mex_credentials,
								  p_BEGIN_DATE    IN DATE,
								  p_END_DATE      IN DATE,
								  p_LOG_ONLY      IN NUMBER,
								  p_STATUS        OUT NUMBER,
								  p_ERROR_MESSAGE OUT VARCHAR2,
								  p_LOGGER IN OUT mm_logger_adapter) AS

	--Handle Query and Response for 'PSS Schedules'
	v_XML_REQUEST  XMLTYPE;
	v_XML_RESPONSE XMLTYPE;
	v_REQUESTOR    VARCHAR2(32);
	v_RESULT       MEX_RESULT;
BEGIN

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('QUERY_PSS_SCHEDULE_BIDS');
	END IF;

	p_STATUS := GA.SUCCESS;
	v_REQUESTOR := p_LOGGER.EXTERNAL_ACCOUNT_NAME;


	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('CREATE XML REQUEST FOR:' || v_REQUESTOR);
	END IF;

	--GENERATE THE REQUEST XML.
	SELECT XMLELEMENT("QueryRequest",
					  XMLELEMENT("QueryMarketClearing",
								 XMLFOREST(v_REQUESTOR AS "Requestor",
										   TO_CHAR(p_BEGIN_DATE, g_DATE_TIME_fORMAT) AS "StartTime",
										   TO_CHAR(p_END_DATE, g_DATE_TIME_FORMAT) AS "EndTime",
										   g_TIME_ZONE AS "TimeZone")))
	  INTO v_XML_REQUEST
	  FROM DUAL;

	--For testing purpose
	--select xml into v_XML_RESPONSE from xml_trace WHERE key1 = 'Query PSS Schedule and Bids';
	v_RESULT := Mex_Switchboard.Invoke(p_Market => MM_MISO_UTIL.g_MEX_MARKET,
						 p_Action => 'pssdownload',
						 p_Logger => p_LOGGER,
						 p_Cred => p_CRED,
						 p_Request_ContentType => 'text/xml',
						 p_Request => v_XML_REQUEST.getClobVal(),
						 p_Log_Only => p_LOG_ONLY	-- Invoke will only log the request if not 0
						 );
	COMMIT;

	IF v_RESULT.STATUS_CODE = Mex_Switchboard.c_Status_Success THEN
		v_XML_RESPONSE := XMLTYPE.CREATEXML(v_RESULT.RESPONSE);
		IMPORT_PSS_SCHEDULE(v_REQUESTOR,v_XML_RESPONSE, p_ERROR_MESSAGE);
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS        := SQLCODE;
		p_ERROR_MESSAGE := SQLERRM;
END QUERY_PSS_SCHEDULE_BIDS;
------------------------------------------------------------------------------------------

END MM_MISO_PSS;
/
