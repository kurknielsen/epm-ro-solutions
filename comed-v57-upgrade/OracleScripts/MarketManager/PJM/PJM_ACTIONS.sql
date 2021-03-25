
SET DEFINE OFF	

-- Ignore &'s in data; otherwise it will assume word after & is a substitution variable and prompt for a value	
-- Uncomment the following line if you wish to completely eliminate previous entries and start from scratch w/ delivered entries

DECLARE
	v_USER_ROLE_ID NUMBER(9);
	v_PUSER_ROLE_ID NUMBER (9);
	v_STATUS NUMBER;
	
	TYPE MARKET_T IS RECORD (
		MARKET_NAME VARCHAR2(10), 
		PACKAGE_NAME VARCHAR2(32), 
		HAS_EXCHANGE_LIST_PROC NUMBER(1),
		HAS_SUBMIT_LIST_PROC NUMBER(1)
		);
	
	c_EES MARKET_T;
	c_EFTR MARKET_T;
	c_EMKT MARKET_T;
	c_EMTR MARKET_T;
	c_ERPM MARKET_T;
	c_ESCHED MARKET_T;
	c_LMP MARKET_T;
	c_OASIS MARKET_T;
	c_SETTL MARKET_T;
	
	--Action Types
	c_DE CONSTANT VARCHAR2(20) := 'Data Exchange';
	c_BO CONSTANT VARCHAR2(20) := 'Bid Offer';
	c_IM CONSTANT VARCHAR2(20) := 'Import';
------------------------------------
	PROCEDURE INIT_MARKET
		(
		p_MARKET IN OUT MARKET_T,
		p_MARKET_NAME IN VARCHAR2,
		p_PACKAGE_NAME IN VARCHAR2,
		p_HAS_EXCHANGE_LIST_PROC IN NUMBER,
		p_HAS_SUBMIT_LIST_PROC IN NUMBER
		) AS
	BEGIN
		p_MARKET.MARKET_NAME := p_MARKET_NAME;
		p_MARKET.PACKAGE_NAME := p_PACKAGE_NAME;
		p_MARKET.HAS_EXCHANGE_LIST_PROC := p_HAS_EXCHANGE_LIST_PROC;
		p_MARKET.HAS_SUBMIT_LIST_PROC := p_HAS_SUBMIT_LIST_PROC;
	END INIT_MARKET;
------------------------------------
	PROCEDURE PUT_ACTION
		(
		p_MARKET IN MARKET_T,
		p_EXCHANGE_CATEGORY IN VARCHAR2,
		p_EXCHANGE_NAME IN VARCHAR2,
		p_DISABLE_ACTION IN BOOLEAN := FALSE,
		p_OVERRIDE_EXCHANGE_TYPE IN VARCHAR2 := NULL,
		p_IMPORT_FILE IN VARCHAR2 := NULL
		) AS

		v_ACTION_NAME SYSTEM_ACTION.ACTION_NAME%TYPE;
		v_DISPLAY_NAME SYSTEM_ACTION.DISPLAY_NAME%TYPE;
		v_MKT VARCHAR2(10);
		v_ACTION_TYPE VARCHAR2(32);
		v_MAIN_PROC VARCHAR2(256);
		v_IMPORT_TYPE SYSTEM_ACTION.IMPORT_TYPE%TYPE;
		v_EXCHANGE_TYPE SYSTEM_ACTION.EXCHANGE_TYPE%TYPE;
		v_ID NUMBER;
		v_ACTION_ALREADY_EXISTED BOOLEAN := TRUE;
		v_WARNING_PROC VARCHAR2(100) := NULL;
		v_LIST_PROC VARCHAR2(100) := NULL;
	
	 BEGIN
	 	--Set the Name and Display Name for the Action
	 	v_ACTION_NAME := 'Sched:PJM:' || CASE WHEN p_MARKET.MARKET_NAME IS NULL THEN '' ELSE p_MARKET.MARKET_NAME || ':' END || p_EXCHANGE_NAME;
		v_DISPLAY_NAME := 'PJM: ' || CASE WHEN p_MARKET.MARKET_NAME IS NULL THEN '' ELSE p_MARKET.MARKET_NAME || ': ' END || p_EXCHANGE_NAME ;
		
		--Set the Action Type to determine whether it shows up on Bid/Offer or Data Exchange dialog.
		v_ACTION_TYPE := CASE p_EXCHANGE_CATEGORY WHEN c_IM THEN c_DE ELSE p_EXCHANGE_CATEGORY END;

		--Set up the main Stored Procedure.
		IF p_OVERRIDE_EXCHANGE_TYPE IS NULL THEN
			v_MAIN_PROC := p_MARKET.PACKAGE_NAME || '.' || CASE p_EXCHANGE_CATEGORY
				WHEN c_DE THEN 'MARKET_EXCHANGE'
				WHEN c_IM THEN 'MARKET_IMPORT_CLOB'
				WHEN c_BO THEN 'MARKET_SUBMIT'
				END || ';EXCHANGE_TYPE="' || p_EXCHANGE_NAME || '"';
		ELSE
			v_MAIN_PROC := p_OVERRIDE_EXCHANGE_TYPE;
		END IF;
			
		IF p_EXCHANGE_CATEGORY = c_IM THEN
			v_IMPORT_TYPE := v_MAIN_PROC;
			v_EXCHANGE_TYPE := NULL;
		ELSE
			v_IMPORT_TYPE := NULL;
			v_EXCHANGE_TYPE := v_MAIN_PROC;
			IF p_EXCHANGE_CATEGORY = c_BO THEN
				v_WARNING_PROC := 'MM_PJM.MARKET_SUBMIT_WARNING';
				v_LIST_PROC := CASE WHEN p_MARKET.HAS_SUBMIT_LIST_PROC= 1 THEN
						p_MARKET.PACKAGE_NAME || '.' || 'MARKET_SUBMIT_TRANSACTION_LIST' || ';EXCHANGE_TYPE="' || p_EXCHANGE_NAME || '"'
					ELSE NULL END;
			ELSE
				v_LIST_PROC := CASE WHEN p_MARKET.HAS_EXCHANGE_LIST_PROC = 1 THEN 
						p_MARKET.PACKAGE_NAME || '.' || 'MARKET_EXCHANGE_ENTITY_LIST' || ';EXCHANGE_TYPE="' || p_EXCHANGE_NAME || '"'
					ELSE NULL END;
			END IF;	
		END IF;
			
		
		--Get the ID for the Action, and set a flag to remember whether it already existed.
		v_ID := ID.ID_FOR_SYSTEM_ACTION(v_ACTION_NAME);
		IF v_ID <= 0 THEN
			v_ACTION_ALREADY_EXISTED := FALSE;
			v_ID := 0;
		ELSE
			v_ACTION_ALREADY_EXISTED := TRUE;
		END IF;
				
		--Insert/Update the System Action.
		IO.PUT_SYSTEM_ACTION(v_ID,	-- o_OID
			v_ACTION_NAME,      -- p_ACTION_NAME
			NULL,               -- p_ACTION_ALIAS
			v_ACTION_NAME,      -- p_ACTION_DESC
			v_ID,               -- p_ACTION_ID
			0,                  -- p_ENTITY_DOMAIN_ID
			'Scheduling',       -- p_MODULE
			v_ACTION_TYPE,      -- p_ACTION_TYPE
			v_DISPLAY_NAME,     -- p_DISPLAY_NAME
			v_IMPORT_TYPE,      -- p_IMPORT_TYPE
			NULL,               -- p_EXPORT_TYPE
			v_EXCHANGE_TYPE,    -- p_EXCHANGE_TYPE
			p_IMPORT_FILE,      -- p_IMPORT_FILE
			NULL,               -- p_EXPORT_FILE
			v_WARNING_PROC,     -- p_WARNING_PROC
			v_LIST_PROC);       -- p_ENTITY_LIST
			
		IF v_ID < 0 THEN
			ROLLBACK;
			RAISE_APPLICATION_ERROR(-20010, 'Failed to create action ' || v_ACTION_NAME || ' with status = ' || v_ID);
		END IF;

					
		--Add the 'User' and 'Power-User' roles to it if it did not already exist.
		--If it did already exist, we want to leave the roles alone.
		IF NOT v_ACTION_ALREADY_EXISTED AND NOT p_DISABLE_ACTION THEN
			EM.PUT_SYSTEM_ACTION_ROLE(v_ID, v_USER_ROLE_ID, 1, 0, 0, 0, 0, v_STATUS);
			EM.PUT_SYSTEM_ACTION_ROLE(v_ID, v_PUSER_ROLE_ID, 1, 0, 0, 0, 0, v_STATUS);
		END IF;
				
	END PUT_ACTION;
	------------------------------------	
BEGIN
	--Initialize PJM Market and Package names
	INIT_MARKET(c_EES, 'EES', 'MM_PJM_EES', 0, 0);
	INIT_MARKET(c_EFTR, 'eFTR', 'MM_PJM_EFTR', 0, 1);
	INIT_MARKET(c_EMKT, 'eMKT', 'MM_PJM_EMKT', 1, 1);
	INIT_MARKET(c_EMTR, 'eMTR', 'MM_PJM_EMTR', 0, 0);
	INIT_MARKET(c_ERPM, 'eRPM', 'MM_PJM_ERPM', 0, 0);
	INIT_MARKET(c_ESCHED, 'eSchedule', 'MM_PJM_ESCHED', 0, 1);
	INIT_MARKET(c_LMP, 'LMP', 'MM_PJM_LMP', 0, 0);
	INIT_MARKET(c_OASIS, 'OASIS', 'MM_PJM_OASIS', 0, 0);
	INIT_MARKET(c_SETTL, '', 'MM_PJM_SETTLEMENT', 0, 0);

	SELECT ROLE_ID INTO v_USER_ROLE_ID FROM APPLICATION_ROLE WHERE ROLE_NAME = 'User';
	SELECT ROLE_ID INTO v_PUSER_ROLE_ID FROM APPLICATION_ROLE WHERE ROLE_NAME = 'Power-User';

	--eRPM actions
	PUT_ACTION(c_ERPM, c_DE, MM_PJM_ERPM.g_ET_QUERY_NSPL); 
	PUT_ACTION(c_ERPM, c_DE, MM_PJM_ERPM.g_ET_QUERY_CAPACITY_OBLIG);

	-- Settlement Actions
	PUT_ACTION(c_SETTL, c_DE, MM_PJM_SETTLEMENT.g_ET_IMP_SETTLEMENT_STMT);

	-- public LMP Actions
	PUT_ACTION(c_LMP, c_DE, MM_PJM_LMP.g_ET_DAY_AHEAD_LMP);
	PUT_ACTION(c_LMP, c_DE, MM_PJM_LMP.g_ET_REAL_TIME_LMP);
	PUT_ACTION(c_LMP, c_DE, MM_PJM_LMP.g_ET_FTR_ZONAL_LMP);
    PUT_ACTION(c_LMP, c_IM, MM_PJM_LMP.g_ET_DA_LMP_FROM_FILE);
    PUT_ACTION(c_LMP, c_IM, MM_PJM_LMP.g_ET_RT_LMP_FROM_FILE);
    PUT_ACTION(c_LMP, c_IM, MM_PJM_LMP.g_ET_FTR_LMP_FROM_FILE);

	-- eFTR Actions
	PUT_ACTION(c_EFTR, c_DE, MM_PJM_EFTR.g_ET_QUERY_FTR_AUCTION_RESULTS);
	PUT_ACTION(c_EFTR, c_DE, MM_PJM_EFTR.g_ET_QUERY_MARKET_INFO);
	PUT_ACTION(c_EFTR, c_DE, MM_PJM_EFTR.g_ET_QUERY_FTR_NODES);
	PUT_ACTION(c_EFTR, c_DE, MM_PJM_EFTR.g_ET_QUERY_FTR_QUOTES);
	PUT_ACTION(c_EFTR, c_DE, MM_PJM_EFTR.g_ET_QUERY_FTR_POSITION);
	
	-- eMKT Bid/Offer Actions
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT_GEN.g_ET_SUBMIT_SCHED_OFFER);
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT_GEN.g_ET_SUBMIT_SCHED_DETAIL);
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT_GEN.g_ET_SUBMIT_SCHED_SELECTION);
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT_GEN.g_ET_SUBMIT_UNIT_UPDATE);
	PUT_ACTION(c_EMKT, c_BO,MM_PJM_EMKT_GEN.g_ET_SUBMIT_UNIT_DETAIL);
	PUT_ACTION(c_EMKT, c_BO,MM_PJM_EMKT_GEN.g_ET_SUBMIT_UNIT_SCHEDULE);
	PUT_ACTION(c_EMKT, c_BO,MM_PJM_EMKT_GEN.g_ET_SUBMIT_REG_OFFER);
	PUT_ACTION(c_EMKT, c_BO,MM_PJM_EMKT_GEN.g_ET_SUBMIT_REG_UPDATE);
	PUT_ACTION(c_EMKT, c_BO,MM_PJM_EMKT_GEN.g_ET_SUBMIT_SPIN_OFFER);
	PUT_ACTION(c_EMKT, c_BO,MM_PJM_EMKT_GEN.g_ET_SUBMIT_SPIN_UPDATE);
	
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT.g_ET_PRICE_SENSIT_DEMAND_BID );
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT.g_ET_FIXED_DEMAND_BID );
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT.g_ET_INCREMENT_OFFER);
	PUT_ACTION(c_EMKT, c_BO, MM_PJM_EMKT.g_ET_DECREMENT_BID);

	PUT_ACTION(c_EFTR, c_BO, MM_PJM_EFTR.g_ET_SUBMIT_FTR_QUOTES);

	PUT_ACTION(c_ESCHED, c_BO, MM_PJM_ESCHED.g_ET_SUBMIT_SCHEDULE);
	
	-- eMKT Data Exchange Actions
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_ANC_SRV_MRKT_PRICES);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_BID_NODE_LIST);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_MESSAGES);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_MARKET_RESULTS);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_NODE_LIST);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_SPREG_AWARDS);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_DEMAND_BIDS);
    PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_PORTFOLIOS);

	-- eMKT Uber-Queries
	PUT_ACTION(c_EMKT, c_DE, 'Query All Bids and Offers to Internal', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="All";SCHEDULE_STATE=1');
	PUT_ACTION(c_EMKT, c_DE, 'Query All Bids and Offers', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="All";SCHEDULE_STATE=2');
	PUT_ACTION(c_EMKT, c_DE, 'Query All Generation Offers to Internal', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="Generation";SCHEDULE_STATE=1');
	PUT_ACTION(c_EMKT, c_DE, 'Query All Generation Offers', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="Generation";SCHEDULE_STATE=2');
	PUT_ACTION(c_EMKT, c_DE, 'Query All A/S Offers to Internal', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="AS";SCHEDULE_STATE=1');
	PUT_ACTION(c_EMKT, c_DE, 'Query All A/S Offers', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="AS";SCHEDULE_STATE=2');
	PUT_ACTION(c_EMKT, c_DE, 'Query All Virtuals to Internal', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="Virtual";SCHEDULE_STATE=1');
	PUT_ACTION(c_EMKT, c_DE, 'Query All Virtuals', FALSE, 'MM_PJM_EMKT.QUERY_ALL_BIDS_OF_TYPE;BID_TYPE="Virtual";SCHEDULE_STATE=2');

	-- eMKT Queries: These queries are "disabled" (no roles assigned) by default because they are not "uber-queries", or they are not used.
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_DAY_AHEAD_LMPS, TRUE);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_SCHEDULE_DETAIL, TRUE);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_SCHEDULE_OFFER, TRUE); 
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_SCHEDULE_SELECTION, TRUE);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_UNIT_DETAIL, TRUE);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_UNIT_SCHEDULE, TRUE);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_UNIT_UPDATE, TRUE);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_REGULATION_OFFERS, TRUE);
	PUT_ACTION(c_EMKT, c_DE, MM_PJM_EMKT.g_ET_QUERY_SPIN_RESERVE_OFFERS, TRUE);
	
	-- eMTR Actions  
	PUT_ACTION(c_EMTR, c_DE, MM_PJM_EMTR.g_ET_QUERY_LOAD_VALUES);
	PUT_ACTION(c_EMTR, c_DE, MM_PJM_EMTR.g_ET_QUERY_METER_CORREC_ALLOCS);
	PUT_ACTION(c_EMTR, c_DE, MM_PJM_EMTR.g_ET_QUERY_METER_VALUES);
	
	-- eSchedule Actions
	PUT_ACTION(c_ESCHED, c_DE, MM_PJM_ESCHED.g_ET_QUERY_COMPANIES);
	PUT_ACTION(c_ESCHED, c_DE, MM_PJM_ESCHED.g_ET_QUERY_CONTRACTS);
	PUT_ACTION(c_ESCHED, c_DE, MM_PJM_ESCHED.g_ET_QUERY_CONTR_TO_INTER);
	PUT_ACTION(c_ESCHED, c_DE, MM_PJM_ESCHED.g_ET_QUERY_RL_TIME_DAILY_TXNS);
	PUT_ACTION(c_ESCHED, c_DE, MM_PJM_ESCHED.g_ET_QUERY_RECON_DATA);
	PUT_ACTION(c_ESCHED, c_DE, MM_PJM_ESCHED.g_ET_QUERY_SCHEDULES);
	PUT_ACTION(c_ESCHED, c_DE, MM_PJM_ESCHED.g_ET_QUERY_LOAD);
	PUT_ACTION(c_ESCHED, c_IM, MM_PJM_ESCHED.g_ET_QUERY_COMPANIES_FROM_FILE, FALSE, NULL, 'csv;Comma Delimited files(*.csv)');

	-- OASIS    
	PUT_ACTION(c_OASIS, c_DE, MM_PJM_OASIS.g_ET_QUERY_LOAD_FORECAST);
	PUT_ACTION(c_OASIS, c_DE, MM_PJM_OASIS.g_ET_QUERY_OP_RESV_RATES);

END;
/

-- save changes to database
COMMIT;
SET DEFINE ON	
--Reset
