CREATE OR REPLACE PACKAGE MM_PJM_SETTLEMENT_MSRS IS

    -- Author  : LDUMITRIU
    -- Created : 12/06/2007 16:01:57
    -- Purpose :
-- $Revision: 1.8 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

     -- This group of procedures take CSV file as a CLOB and imports it
    -- These are only used for testing; commented out because many procedures
    -- with begin and end date are called from data exchange and this throws an
    -- error if the clob procedure is also public
/*    PROCEDURE IMPORT_MONTHLY_STATEMENT
      (
      p_CSV IN CLOB,
      p_STATUS OUT NUMBER,
      p_MESSAGE OUT VARCHAR2
      );
    PROCEDURE IMPORT_MONTH_TO_DATE_BILL
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_CONGESTION_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_TRANS_LOSS_CREDITS
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_SCHEDULE9_10_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

	PROCEDURE IMPORT_SYNC_RES_T1_CHG_SUMMARY
	(
		p_CSV IN CLOB,
		p_STATUS OUT NUMBER,
		p_MESSAGE OUT VARCHAR2
	);
	PROCEDURE IMPORT_SYNC_RES_T2_CHG_SUMMARY
	(
		p_CSV IN CLOB,
		p_STATUS OUT NUMBER,
		p_MESSAGE OUT VARCHAR2
	);
	PROCEDURE IMPORT_SYNC_RES_OBL
	(
		p_CSV IN CLOB,
		p_STATUS OUT NUMBER,
		p_MESSAGE OUT VARCHAR2
	);
    PROCEDURE IMPORT_TOSSCD_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_NITS_CHARGE_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_NITS_CREDIT_SUMMARY
    (
        p_CSV     IN CLOB,
      p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_NITS_OFFSET_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_RTO_STARTUP_COST_SUMM
	(
	    p_CSV IN CLOB,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_OP_RES_CHG_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_OP_RES_GEN_CR_DETAILS
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_FTR_AUCTION
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_FTR_TARGET_CREDITS
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_ARR_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
   PROCEDURE IMPORT_REACTIVE_SUMMARY
      (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_REGULATION_CREDITS
	(
	    p_CSV IN CLOB,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);
    PROCEDURE IMPORT_BLACK_START_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_DA_DAILY_TX
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_RT_DAILY_TX
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_EXPLICIT_CONGESTION
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_REGULATION_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_FIRM_TRANS_SERV_CHARGES
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_NON_FM_TRANS_SV_CHARGES
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_RAMAPO_PAR_SUMMARY
	(
	    p_CSV IN CLOB,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_SYNCH_CONDENS_SUMMARY
    (
        p_CSV IN CLOB,
        p_STATUS OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_SCHED_9_10_RECON
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_SCHEDULE1A_RECONCILE
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_ENERGY_CH_RECONCIL
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_REGULATION_CH_RECONCIL
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_SYNC_RES_CH_RECONCIL
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_TRANS_LOSS_CR_RECONCIL
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_RPM_AUCTION_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_LOC_RELIABILITY_SUMM
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_REACTIVE_SERV_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_EXPANSION_COST_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_GEN_CREDIT_PORTFOLIO
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

    PROCEDURE IMPORT_SPOT_SUMMARY
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );

        PROCEDURE IMPORT_TRANS_LOSS_CHARGES
    (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_EXPLICIT_LOSSES
   (
        p_CSV     IN CLOB,
        p_STATUS  OUT NUMBER,
        p_MESSAGE OUT VARCHAR2
    );
    PROCEDURE IMPORT_NON_FM_TRANS_SV_CREDITS
	(
	    p_CSV IN CLOB,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_CONG_LOSS_LOAD_RECONCIL
	(
	    p_CSV IN CLOB,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_REACT_SERVICES_RECONCIL
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);
    
    PROCEDURE IMPORT_CAP_TRANSFER_CREDITS
	(
	p_CSV IN CLOB,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);*/

    -- This group of procedures, however, takes parameters for what to import and actually fetches the CSV via PJM-Browserless interface
/*   PROCEDURE IMPORT_MONTHLY_STATEMENT
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_MONTH_TO_DATE_BILL
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_SPOT_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_SCHEDULE9_10_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_TOSSCD_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_NITS_CHARGE_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_NITS_CREDIT_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_NITS_OFFSET_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_NON_FM_TRANS_SV_CREDITS
	(
	    p_BEGIN_DATE IN DATE,
	    p_END_DATE IN DATE,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_FTR_AUCTION
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_ARR_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_REACTIVE_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_REGULATION_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_RTO_STARTUP_COST_SUMM
	(
        p_BEGIN_DATE IN DATE,
	    p_END_DATE IN DATE,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);
    PROCEDURE IMPORT_BLACK_START_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_RAMAPO_PAR_SUMMARY
	(
	    p_BEGIN_DATE IN DATE,
	    p_END_DATE IN DATE,
	    p_STATUS OUT NUMBER,
	    p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_DA_DAILY_TX
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_RT_DAILY_TX
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_EXPLICIT_CONGESTION
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_FIRM_TRANS_SERV_CHARGES
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_NON_FM_TRANS_SV_CHARGES
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_ENERGY_CH_RECONCIL
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_REGULATION_CH_RECONCIL
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_SYNC_RES_CH_RECONCIL
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_TRANS_LOSS_CR_RECONCIL
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );
    PROCEDURE IMPORT_EXPANSION_COST_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_ENTIRE_STATEMENT
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_REACTIVE_SERV_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_SCHEDULE1A_RECONCILE
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_SCHED_9_10_RECON
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );


    PROCEDURE IMPORT_FTR_TARGET_CREDITS
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_INADVERTENT_INTERCHANGE
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_TRANS_LOSS_CREDITS
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_EXPLICIT_LOSSES
    (
        p_BEGIN_DATE IN DATE,
        p_END_DATE   IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_LOC_RELIABILITY_SUMM
    (
        p_BEGIN_DATE IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_RPM_AUCTION_SUMMARY
    (
        p_BEGIN_DATE IN DATE,
        p_STATUS     OUT NUMBER,
        p_MESSAGE    OUT VARCHAR2
    );

    FUNCTION GET_PSE
    (
        p_ORG_ID   IN VARCHAR2,
        p_ORG_NAME IN VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE FILL_NON_SHADOWED_TXNS
    (
        p_PSE_ID        IN NUMBER,
        p_COMPONENT_ID  IN NUMBER,
        p_CHARGE_AMOUNT IN NUMBER,
        p_DATE          IN DATE
    );

    PROCEDURE IMPORT_CONGESTION_AND_LOSS_RPT
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_REGULATION_CREDITS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_CONG_LOSS_LOAD_RECONCIL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_OP_RESERVE_REPORTS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_SYNC_RESERVE_REPORTS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2
    );

    PROCEDURE IMPORT_REACT_SERVICES_RECONCIL
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_IMPLICIT_CONG_LOSS_CH
    (
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

    PROCEDURE IMPORT_CAP_TRANSFER_CREDITS
	(
	p_BEGIN_DATE IN DATE,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);*/

    FUNCTION ID_FOR_SERVICE_ZONE(p_ZONE_NAME IN VARCHAR2) RETURN NUMBER;

    g_EXTERNAL_STATE NUMBER(1) := 2;

    PROCEDURE IMPORT_RT_DAILY_TX
	(
	p_RECORDS IN MEX_PJM_DAILY_TX_TBL,
	p_STATUS  OUT NUMBER
	);

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
	p_MESSAGE               	OUT VARCHAR2);

    ---Constants for Component Name / External Identifiers
    g_ARR_AUCTION_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Auction Revenue Rights';
    g_ARR_AUCTION_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2510';

    g_DA_SPOT_COMP_NAME       CONSTANT VARCHAR2(100) := 'PJM Day-Ahead Spot Market Energy';
    g_DA_SPOT_CHG_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-1200';
    g_BAL_SPOT_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Balancing Spot Market Energy';
    g_BAL_SPOT_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1205';

    g_DA_TX_CONG_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Day-Ahead Transmission Congestion';
    g_DA_TX_CONG_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1210';

    g_BAL_TX_CONG_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Balancing Transmission Congestion';
    g_BAL_TX_CONG_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1215';

    g_BLACK_START_COMP_NAME     CONSTANT VARCHAR2(100) := 'PJM Black Start Service';
    g_BLACK_START_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1380';

    g_EXPANSION_COST_RECOV_NAME    CONSTANT VARCHAR2(100) := 'PJM Expansion Cost Recovery';
    g_EXP_CST_RECOV_CHG_COMP_IDENT CONSTANT VARCHAR2(40) := 'PJM-1730';
    g_EXP_CST_RECOV_CR_COMP_IDENT  CONSTANT VARCHAR2(40) := 'PJM-2730';

    g_FIRM_P2P_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Firm Point-to-Point Transmission Service';
    g_FIRM_P2P_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1130';
    g_FIRM_P2P_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2130';

    g_FTR_AUCTION_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM FTR Auction';
    g_FTR_AUCTION_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1500';
    g_FTR_AUCTION_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2500';

    g_INADV_INTERCH_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Inadvertent Interchange';
    g_INADV_INTERCH_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1230';

    g_LOCATIONAL_REL_COMP_NAME    CONSTANT VARCHAR2(100) := 'PJM Locational Reliability';
    g_LOCATION_REL_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1610';

    g_NON_FIRM_P2P_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Non-Firm Point-to-Point Transmission Service';
    g_NON_FIRM_P2P_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1140';
    g_NON_FIRM_P2P_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2140';

    g_NITS_OFFSET_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Network Integration Transmission Service Offset';
    g_NITS_OFFSET_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1104';
    g_NITS_OFFSET_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2104';
    g_NITS_COMP_NAME             CONSTANT VARCHAR2(100) := 'PJM Network Integration Transmission Service';
    g_NITS_CHG_COMP_IDENT        CONSTANT VARCHAR2(32) := 'PJM-1100';
    g_NITS_CR_COMP_IDENT         CONSTANT VARCHAR2(32) := 'PJM-2100';

    g_REACTIVE_SERV_COMP_NAME  CONSTANT VARCHAR2(100) := 'PJM Reactive Services';
    g_REACTIVE_SERV_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1378';
    g_REACTIVE_SERV_CR_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-2378';

    g_RSVCFG_SERV_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM RS&VCFG Service';
    g_RSVCFG_SERV_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1330';
    g_RRSVCFG_SERV_CR_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-2330';

    g_RTO_STARTUP_COST_COMP_NAME CONSTANT VARCHAR2(100) := 'PJM RTO Start-Up Cost Recovery';
    g_RTO_STARTUP_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1720';
    g_RTO_STARTUP_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2720';

    g_RPM_AUCTION_COMP_NAME     CONSTANT VARCHAR2(100) := 'PJM RPM Auction';
    g_RPM_AUCTION_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1600';
    g_RPM_AUCTION_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2600';

    g_SYNC_RESERVE_COMP_NAME  CONSTANT VARCHAR2(100) := 'PJM Synchronized Reserve';
    g_SYNC_RESERVE_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1360';
    g_SYNC_RESERVE_CR_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-2360';

    g_RAMAPO_PAR_COMP_NAME  CONSTANT VARCHAR2(100) := 'PJM Ramapo PAR';
    g_RAMAPO_PAR_CH_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1910';

    --in MSRS 'PJM Regulation Summary' has been renamed as 'Regulation and Frequency Response Service'
    g_REGULATION_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Regulation and Frequency Response Service';
    g_REGULATION_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1340';
    g_REGULATION_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2340';

    g_DA_TX_LOSS_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Day-Ahead Transmission Losses';
    g_DA_TX_LOSS_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1220';
    g_DA_TX_LOSS_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2220';

    g_BAL_TX_LOSS_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Balancing Transmission Losses';
    g_BAL_TX_LOSS_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1225';

    g_SSCD_CONT_AREA_ADMIN_NAME    CONSTANT VARCHAR2(100) := 'PJM Scheduling, System Control and Dispatch Service - Control Area Administration';
    g_SSCD_CONT_AREA_ADMIN_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1301';

    g_SSCD_FTR_ADMIN_COMP_NAME    CONSTANT VARCHAR2(100) := 'PJM Scheduling, System Control and Dispatch Service - FTR Administration';
    g_SSCD_FTR_ADMIN_COMP_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1302';

    g_SSCD_MKT_SUPP_COMP_NAME    CONSTANT VARCHAR2(100) := 'PJM Scheduling, System Control and Dispatch Service - Market Support';
    g_SSCD_MKT_SUPP_COMP_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1303';

    g_SSCD_REG_MKT_ADMIN_NAME    CONSTANT VARCHAR2(100) := 'PJM Scheduling, System Control and Dispatch Service - Regulation Market Administration';
    g_SSCD_REG_MKT_ADMIN_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1304';

    g_SSCD_CAP_RES_OBLIG_NAME    CONSTANT VARCHAR2(100) := 'PJM Scheduling, System Control and Dispatch Service - Capacity Resource/Obligation Mgmt';
    g_SSCD_CAP_RES_OBLIG_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1305';

    g_FERC_ANNUAL_RECOV_NAME    CONSTANT VARCHAR2(100) := 'PJM FERC Annual Charge Recovery';
    g_FERC_ANNUAL_RECOV_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1315';

    g_OPSI_FUNDING_NAME    CONSTANT VARCHAR2(100) := 'PJM OPSI Funding Charge';
    g_OPSI_FUNDING_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1316';


    g_NERC_CHARGE_NAME    CONSTANT VARCHAR2(100) := 'PJM North American Electric Reliability Corporation (NERC) Charge';
    g_NERC_CHARGE_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1317';

    g_RFC_CHARGE_NAME    CONSTANT VARCHAR2(100) := 'PJM Reliability First Corporation (RFC) Charge';
    g_RFC_CHARGE_IDENT   CONSTANT VARCHAR2(32) := 'PJM-1318';

    g_TOSSCD_CONG_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM TO SSC&D Service';
    g_TOSSCD_CONG_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1320';
    g_TOSSCD_CONG_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2320';

    g_TX_CONG_COMP_NAME     CONSTANT VARCHAR2(100) := 'PJM Transmission Congestion';
    g_TX_CONG_CR_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-2210';

    g_DA_OP_RES_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Day-Ahead Operating Reserve';
    g_DA_OP_RES_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1370';
    g_DA_OP_RES_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2370';

    g_BAL_OP_RES_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Balancing Operating Reserve';
    g_BAL_OP_RES_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1375';
    g_BAL_OP_RES_CR_COMP_IDENT  CONSTANT VARCHAR2(32) := 'PJM-2375';

    g_SYNCH_CONDENS_COMP_NAME      CONSTANT VARCHAR2(100) := 'PJM Synchronous Condensing';
    g_SYNCH_CONDENS_CHG_COMP_IDENT CONSTANT VARCHAR2(32) := 'PJM-1377';

    g_LOAD_RECONCIL_SPOT_NAME       CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Spot Market Energy';
    g_LOAD_RECONCIL_SPOT_IDENT      CONSTANT VARCHAR2(100) := 'PJM-1400';

    g_LOAD_RECONCIL_INADVERT_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Inadvertent Interchange';
    g_LOAD_RECONCIL_INADVERT_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1430';

    g_LD_RECONCIL_TRANS_CONG_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Transmission Congestion';
    g_LD_RECONCIL_TRANS_CONG_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1410';

    g_LD_RECONCIL_TRANS_LOSS_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Transmission Losses';
    g_LD_RECONCIL_TRANS_LOSS_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1420';

    --Schedule 1A Reconcil
    g_LD_RECONCIL_TOSSCD_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Transmission Owner Scheduling, System Control and Dispatch Service';
    g_LD_RECONCIL_TOSSCD_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1450';

    g_LD_RECONCIL_REG_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Regulation and Frequency Response Service';
    g_LD_RECONCIL_REG_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1460';

    g_LD_RECONCIL_LOSSES_NAME      CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Transmission Losses';
    g_LD_RECONCIL_LOSSES_CH_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1420';
    g_LD_RECONCIL_LOSSES_CR_IDENT  CONSTANT VARCHAR2(100) := 'PJM-2420';

    g_LD_RECONCIL_REACTIVE_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Reactive Services';
    g_LD_RECONCIL_REACTIVE_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1490';

    g_LD_RECONCIL_SPIN_RES_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Synchronized Reserve';
    g_LD_RECONCIL_SPIN_RES_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1470';

    g_LD_RECONCIL_SYNC_COND_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Synchronous Condensing';
    g_LD_RECONCIL_SYNC_COND_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1480';

    g_LD_RECONCIL_SSCD_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for PJM Scheduling, System Control and Dispatch Service';
    g_LD_RECONCIL_SSCD_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1440';

    g_LD_RECONCIL_SSCD_REF_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for PJM Scheduling, System Control and Dispatch Service Refund';
    g_LD_RECONCIL_SSCD_REF_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1441';

    g_LD_RECONCIL_FERC_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for FERC Annual Charge Recovery';
    g_LD_RECONCIL_FERC_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1445';

    g_LD_RECONCIL_OPSI_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Organization of PJM States, Inc. (OPSI) Funding';
    g_LD_RECONCIL_OPSI_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1446';

    g_LD_RECONCIL_NERC_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for North American Electric Reliability Corporation (NERC)';
    g_LD_RECONCIL_NERC_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1447';

    g_LD_RECONCIL_RFC_NAME   CONSTANT VARCHAR2(100) := 'PJM Load Reconciliation for Reliability First Corporation (RFC)';
    g_LD_RECONCIL_RFC_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1448';
    g_ET_IMP_SETTLEMENT_STMT VARCHAR2(30):= 'IMPORT SETTLEMENT STATEMENT';

    g_INTERRUPT_LD_REL_NAME   CONSTANT VARCHAR2(100) := 'PJM Interruptible Load for Reliability Credits';
    g_INTERRUPT_LD_REL_IDENT  CONSTANT VARCHAR2(100) := 'PJM-2620';

	g_SSCD_REG_REFUND_NAME   CONSTANT VARCHAR2(100) := 'PJM SSCD Refund - Regulation Market Admin Charges';
    g_SSCD_REG_REFUND_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1311';

	g_SSCD_MKT_REFUND_NAME   CONSTANT VARCHAR2(100) := 'PJM SSCD Refund - Market Support Charges';
    g_SSCD_MKT_REFUND_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1310';

	g_SSCD_FTR_ADMIN_REFUND_NAME   CONSTANT VARCHAR2(100) := 'PJM SSCD Refund - FTR Admin Charges';
    g_SSCD_FTR_ADMIN_REFUND_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1309';

	g_SSCD_CONTROL_REFUND_NAME   CONSTANT VARCHAR2(100) := 'PJM SSCD Refund - Control Area Admin Charges';
    g_SSCD_CONTROL_REFUND_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1308';

	g_SSCD_CAP_RES_REFUND_NAME   CONSTANT VARCHAR2(100) := 'PJM SSCD Refund - Capacity Resource Obligation Mgt Charges';
    g_SSCD_CAP_RES_REFUND_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1312';

	g_SSCD_ADVANCED_NAME   CONSTANT VARCHAR2(100) := 'PJM SSCD Service - Advanced Second Control Center Charges';
    g_SSCD_ADVANCED_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1306';

	g_CAP_RES_DEF_NAME   CONSTANT VARCHAR2(100) := 'PJM Capacity Resource Deficiency Credit';
    g_CAP_RES_DEF_IDENT  CONSTANT VARCHAR2(100) := 'PJM-2661';

    g_DA_SCHEDULING_RESERVE_NAME CONSTANT VARCHAR2(100) := 'PJM Day-Ahead Scheduling Reserve';
    g_DA_SCHED_CHG_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1365';
    g_DA_SCHED_CR_IDENT  CONSTANT VARCHAR2(100) := 'PJM-2365';

    g_CAP_TRANSFER_RIGHTS_NAME CONSTANT VARCHAR2(100) := 'PJM Capacity Transfer Rights';
    g_CAP_TRANSFER_CR_IDENT  CONSTANT VARCHAR2(100) := 'PJM-2630';

    g_MMU_FUNDING_NAME CONSTANT VARCHAR2(100) := 'PJM Market Monitoring Unit (MMU) Funding Charges';
    g_MMU_FUNDING_CHG_IDENT  CONSTANT VARCHAR2(100) := 'PJM-1314';


END MM_PJM_SETTLEMENT_MSRS;
/