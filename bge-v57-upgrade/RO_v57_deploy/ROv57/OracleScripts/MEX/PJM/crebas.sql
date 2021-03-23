--MSRS table for synchronized reserved reports (Tier 1, Tier2, and Reserve Obligation)
CREATE TABLE PJM_SYNC_RESERVE_SUMMARY
(
    ORG_ID                      VARCHAR2(8),
    ORG_NAME                    VARCHAR2(64),
    CUT_DATE                    DATE,
    SPINNING_RESERVE_ZONE       VARCHAR2(32),
    SUBZONE                     VARCHAR2(32),
    SRMCP                       NUMBER,
    SUBZONE_LOAD                NUMBER,
    TOTAL_SUBZONE_LOAD          NUMBER,
    SPIN_OBLIGATION             NUMBER,
    TIER1_ESTIMATE_MWH          NUMBER,
    MEMBER_TIER1_ALLOC_TO_OBLIG NUMBER,
    TOTAL_TIER1_ALLOC_TO_OBLIG  NUMBER,
    TIER1_CHARGE                NUMBER,
    BILATERAL_SPIN_PURCHASES    NUMBER,
    BILATERAL_SPIN_SALES        NUMBER,
    ADJUSTED_OBLIGATION         NUMBER,
    PJM_TOTAL_SPIN_PURCHASES    NUMBER,
    OPP_COST_CHARGE_CLEARED     NUMBER,
    TIER1_LOST                  NUMBER,
    TOTAL_TIER1_LOST            NUMBER,
    OPP_COST_CHARGE_ADDED       NUMBER,
    SRMCP_CHARGE                NUMBER,
    TIER2_SELF_ASSIGNED_MWH     NUMBER,
    TIER2_SHORTFALL             NUMBER
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- Create/Recreate indexes 
create index PJM_SYNC_RESERVE_SUMMARY_IX01 on PJM_SYNC_RESERVE_SUMMARY (ORG_ID, ORG_NAME, CUT_DATE)
  tablespace NERO_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/
----------------------------------------------------------------
--MSRS table for Operating Reserve Generator Credit Details
CREATE TABLE PJM_OPRES_GEN_CREDITS
(
    DAY             DATE,
    ORG_ID          VARCHAR2(8),
    ORG_NAME        VARCHAR2(64),
    UNIT_ID         VARCHAR2(16),
    UNIT_NAME       VARCHAR2(64),
    OWNERSHIP_SHARE NUMBER,
    DA_OFFER        NUMBER,
    DA_VALUE        NUMBER,
    DA_CREDIT       NUMBER,
    RT_OFFER        NUMBER,
    BAL_VALUE       NUMBER,
    BAL_CREDIT      NUMBER,
    REGULATION_REVENUE  NUMBER,
    SPIN_RES_REVENUE    NUMBER,
    REACT_SERV_REVENUE  NUMBER
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/
-- Create/Recreate indexes 
create index PJM_OPRES_GEN_CREDITS_IX01 on PJM_OPRES_GEN_CREDITS (DAY, ORG_ID, UNIT_ID)
  tablespace NERO_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

----------------------------------------------------------------

CREATE TABLE PJM_OBJECT_MAP
(
  OBJECT_TYPE       VARCHAR2(64), 
  OBJECT_NAME       VARCHAR2(64),
  OBJECT_VALUE      NUMBER(10),
	constraint PK_PJM_OBJECT_MAPPING primary key (OBJECT_TYPE, OBJECT_NAME)
       using index
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           next 64K
           pctincrease 0
       )
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

CREATE TABLE PJM_EFTR_MARKET_INFO
(
  MKT_NAME                        VARCHAR2(64),
  MKT_TYPE                        VARCHAR2(8),
  MKT_ROUND                       NUMBER(2),
  MKT_PERIOD                      VARCHAR2(16),
  MKT_INT_START                   DATE,
  MKT_INT_END                     DATE,
  BID_INT_START               	  DATE,
  BID_INT_END                     DATE,
  MKT_STATUS                      VARCHAR2(16), 
  IS_ACTIVE			  NUMBER(1)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

CREATE TABLE PJM_EFTR_NODES
(
  MKT_NAME                        VARCHAR2(64),
  NODE_NAME                       VARCHAR2(64)  
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- Create table
create table MEX_CONGESTION_WORK
(
  WORK_ID                        NUMBER,
  ORG_ID                         VARCHAR2(32),
  DAY                            DATE,
  HOUR                           NUMBER(2),
  DST                            NUMBER(1),
  OASIS_ID                       VARCHAR2(32),
  RESERVATION_TYPE               VARCHAR2(32),
  RESERVED_MW                    NUMBER,
  ENERGY_ID                      VARCHAR2(32),
  BUYER                          VARCHAR2(32),
  SELLER                         VARCHAR2(32),
  SINK_NAME                      VARCHAR2(32),
  SOURCE_NAME                    VARCHAR2(32),
  DA_SCHEDULED_MWH               NUMBER,
  DA_SINK_LMP                    NUMBER,
  DA_SOURCE_LMP                  NUMBER,
  DA_EXPLICIT_CONGESTION_CHARGE  NUMBER,
  BAL_DEVIATION_MWH              NUMBER,
  BAL_SINK_LMP                   NUMBER,
  BAL_SOURCE_LMP                 NUMBER,
  BAL_EXPLICIT_CONGESTION_CHARGE NUMBER
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- Create/Recreate indexes 
create index MEX_CONGESTION_WORK_IX01 on MEX_CONGESTION_WORK (WORK_ID, BUYER)
  tablespace NERO_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

create index MEX_CONGESTION_WORK_IX02 on MEX_CONGESTION_WORK (WORK_ID, SELLER)
  tablespace NERO_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- Create table
create table MEX_DAILY_TX_WORK
(
  WORK_ID          NUMBER,
  PARTICIPANT_NAME VARCHAR2(64),
  TRANSACTION_ID   VARCHAR2(128),
  TRANSACTION_TYPE VARCHAR2(64),
  SELLER           VARCHAR2(32),
  BUYER            VARCHAR2(32),
  TRANSACTION_DATE DATE,
  HOUR_ENDING      NUMBER(2),
  AMOUNT           NUMBER
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/


create table MEX_PJM_FTR_ALLOC_WORK
(
	WORK_ID NUMBER(9),
	ORG_IDENT VARCHAR2(32),
	DAY DATE,
	HOUR NUMBER(2),
	CUT_DATE DATE,
	TRANSACTION_IDENT VARCHAR2(32),
	FTR_MW NUMBER,
	SINK_NAME VARCHAR2(32),
    SINK_PNODE_ID NUMBER,
	SOURCE_NAME VARCHAR2(32),
    SOURCE_PNODE_ID NUMBER,
	HEDGE_TYPE VARCHAR2(32),
	ALLOCATION_PCT NUMBER,
	SINK_LMP NUMBER,
	SOURCE_LMP NUMBER,
	TARGET_ALLOCATION NUMBER
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- Create/Recreate indexes 
create index MEX_PJM_FTR_ALLOC_WORK_IX01 on MEX_PJM_FTR_ALLOC_WORK (WORK_ID, ORG_IDENT, DAY, HOUR, CUT_DATE)
  tablespace NERO_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- holds results of the NodeList query, so service points can be updated 
-- without having all 6800 PJM nodes in the SERVICE_POINT table
create table PJM_EMKT_PNODES
(
  NODENAME                VARCHAR2(30) not null,
  NODETYPE                VARCHAR2(15) not null,
  PNODEID                 NUMBER(15) not null,
  CANSUBMITFIXED          NUMBER not null,
  CANSUBMITPRICESENSITIVE NUMBER not null,
  CANSUBMITINCREMENT      NUMBER not null,
  CANSUBMITDECREMENT      NUMBER not null,
  ZONE                    VARCHAR2(32)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
-- Add comments to the table 
comment on table PJM_EMKT_PNODES
  is 'Holds results of eMarket query QueryNodeList';
-- Add comments to the columns 
comment on column PJM_EMKT_PNODES.NODETYPE
  is 'One of Hub, Zone, Interface, Bus, 500, or Aggregate';
comment on column PJM_EMKT_PNODES.PNODEID
  is 'PJM sequence ID for this pricing node';
comment on column PJM_EMKT_PNODES.CANSUBMITFIXED
  is 'Boolean, if true then this pnode can be specified on a fixed demand bid';
comment on column PJM_EMKT_PNODES.CANSUBMITPRICESENSITIVE
  is 'Boolean, if true then this pnode can be specified on a price-sensitive demand bid';
comment on column PJM_EMKT_PNODES.CANSUBMITINCREMENT
  is 'Boolean, if true then this pnode can be specified on a virtual increment bid';
comment on column PJM_EMKT_PNODES.CANSUBMITDECREMENT
  is 'Boolean, if true then this pnode can be specified on a virtual decrement bid';
comment on column PJM_EMKT_PNODES.ZONE
  is 'Zone name from LMP file (null if row added from eMKT query)';
-- Create/Recreate indexes 
create index PJM_EMKT_PNODE_IX01 on PJM_EMKT_PNODES (PNODEID)
  tablespace NERO_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- holds results of eSchedule Company query (PJM participants and org IDs)
create table PJM_ESCHED_COMPANY
(
  PARTICIPANT_NAME VARCHAR2(64) not null,
  SHORT_NAME       VARCHAR2(32) not null,
  ORG_ID           VARCHAR2(32) not null
)
tablespace NERO_DATA
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

-- really only used in MM side - used to get around an XML bug in Oracle
create table MM_EMTR_XML_WORK
(
  WORK_ID    NUMBER(9),
  OWNER_DATA VARCHAR2(32),
  CA_DATA    VARCHAR2(32),
  XML_DATA   XMLTYPE
)
tablespace NERO_DATA
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/
-- Create/Recreate indexes 
create unique index IX01_MM_EMTR_XML_WORK on MM_EMTR_XML_WORK (WORK_ID)
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/

CREATE TABLE PJM_OPRES_GEN_CREDITS_DETAIL
(
  GENERATOR_ID      VARCHAR2(32), 
  STATEMENT_STATE   NUMBER(1),
  CHARGE_DATE       DATE,
  SCHEDULE_ID       VARCHAR2(32),
  DA_LMP            NUMBER(10,3), 
  DA_SCHED_MW       NUMBER(10,3), 
  DA_VALUE          NUMBER(10,3),
  DA_ENERGY_OFFER   NUMBER(10,3),
  DA_NO_LOAD_COST   NUMBER(10,3),
  DA_STARTUP_COST   NUMBER(10,3),
  DA_OFFER          NUMBER(10,3),
  RT_LMP            NUMBER(10,3),
  RT_MW             NUMBER(10,3),
  BAL_ENERG_MKT_VAL NUMBER(10,3),
  RT_ENERG_OFFER    NUMBER(10,3),
  RT_NO_LOAD_COST   NUMBER(10,3),
  RT_STARTUP_COST   NUMBER(10,3),
  RT_OFFER          NUMBER(10,3),  
    constraint PK_PJM_OPRES_GEN_CRED primary key (GENERATOR_ID, SCHEDULE_ID, STATEMENT_STATE, CHARGE_DATE)
       using index
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           next 64K
           pctincrease 0
       )
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA;

COMMENT ON TABLE PJM_OPRES_GEN_CREDITS_DETAIL IS 'CONTAINS THE HOURLY DETAILS FROM THE DAILY OPRES GENERATOR CREDITS SUMMARY';
/

CREATE TABLE PJM_SERVICE_POINT_OWNERSHIP
(
	SERVICE_POINT_ID NUMBER(9) NOT NULL,
	CONTRACT_ID NUMBER(9) NOT NULL,
	BEGIN_DATE DATE NOT NULL,
	END_DATE DATE,
	OWNERSHIP_PERCENT NUMBER(6,2),
	IS_SCHEDULER NUMBER(1),
	ENTRY_DATE DATE,
	constraint PK_SERVICE_POINT_OWNERSHIP primary key (SERVICE_POINT_ID, CONTRACT_ID, BEGIN_DATE)
       using index
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           next 64K
           pctincrease 0
       )
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

-- this table supports the FERC 668 report
create table PJM_SPOT_MKT_SUMMARY
(
  ORG_ID                VARCHAR2(8),
  DAY                   DATE,
  HOUR                  NUMBER(2),
  DST_FLAG              NUMBER(1),
  DA_NET_INTERCHANGE    NUMBER,
  DA_SPOT_PURCHASE      NUMBER,
  DA_LOAD_WEIGHTED_LMP  NUMBER,
  DA_CHARGE             NUMBER,
  DA_SPOT_SALE          NUMBER,
  DA_GEN_WEIGHTED_LMP   NUMBER,
  DA_CREDIT             NUMBER,
  RT_NET_INTERCHANGE    NUMBER,
  BAL_SPOT_PURCHASE_DEV NUMBER,
  BAL_LOAD_WEIGHTED_LMP NUMBER,
  BAL_CHARGE            NUMBER,
  BAL_SPOT_SALE_DEV     NUMBER,
  BAL_GEN_WEIGHTED_LMP  NUMBER,
  BAL_CREDIT            NUMBER,
  CUT_DATE              DATE
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate indexes 
create index PJM_SPOT_MKT_SUMMARY_IX01 on PJM_SPOT_MKT_SUMMARY (ORG_ID, CUT_DATE)
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  )
/
-- PJM MLTemporary Tables
CREATE GLOBAL TEMPORARY TABLE PJM_SPOT_MARKET_ENERGY_SUMMARY ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  da_spot_market_net_interchange NUMBER,
  da_pjm_energy_price NUMBER,
  da_spot_market_energy_charge NUMBER,
  rt_spot_market_net_interchange NUMBER,
  bal_spot_market_dev NUMBER,
  rt_pjm_energy_price NUMBER,
  bal_spot_market_energy_charge NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_CONGESTION_SUMMARY ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  day_ahead_cong_wd_mwh NUMBER,
  day_ahead_cong_inj_mwh NUMBER,
  day_ahead_cong_wd_charge NUMBER,
  day_ahead_cong_inj_credit NUMBER,
  day_ahead_imp_cong_charge NUMBER,
  day_ahead_exp_cong_charge NUMBER,
  balancing_cong_wd_dev_mwh NUMBER,
  balancing_cong_inj_dev_mwh NUMBER,
  balancing_cong_wd_charge NUMBER,
  balancing_cong_inj_credit NUMBER,
  balancing_imp_cong_charge NUMBER,
  balancing_exp_cong_charge NUMBER,
  ftr_target_allocation NUMBER,
  ftr_cong_credit NUMBER,
  credit_from_uts NUMBER,
  credit_for_monthly_excess NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_EXPLICIT_CONG_CHARGES ( 
  org_nid VARCHAR2(32),
  day VARCHAR2(10),
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  energy_id VARCHAR2(32),
  nerc_tag VARCHAR2(32),
  oasis_id VARCHAR2(32),
  buyer VARCHAR2(32),
  seller VARCHAR2(32),
  sink_name VARCHAR2(128),
  source_name VARCHAR2(128),
  da_transaction_mwh NUMBER,
  da_sink_cong_price NUMBER,
  da_source_cong_price NUMBER,
  da_exp_cong_charge NUMBER,
  rt_transaction_mwh NUMBER,
  bal_dev_mwh NUMBER,
  rt_sink_cong_price NUMBER,
  rt_source_cong_price NUMBER,
  bal_exp_cong_charge NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_TXN_LOSS_CHARGE_SUMMARY ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  day_ahead_loss_wd_mwh NUMBER,
  day_ahead_loss_inj_mwh NUMBER,
  day_ahead_loss_wd_charge NUMBER,
  day_ahead_loss_inj_credit NUMBER,
  day_ahead_imp_loss_charge NUMBER,
  day_ahead_exp_loss_charge NUMBER,
  balancing_loss_wd_dev_mwh NUMBER,
  balancing_loss_inj_dev_mwh NUMBER,
  balancing_loss_wd_charge NUMBER,
  balancing_loss_inj_credit NUMBER,
  balancing_imp_loss_charge NUMBER,
  balancing_exp_loss_charge NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_EXPLICIT_LOSS_CHARGES ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  energy_id VARCHAR2(32),
  nerc_tag VARCHAR2(32),
  oasis_id VARCHAR2(32),
  buyer VARCHAR2(32),
  seller VARCHAR2(32),
  sink_name VARCHAR2(32),
  source_name VARCHAR2(32),
  da_transaction_mwh NUMBER,
  da_sink_loss_price NUMBER,
  da_source_loss_price NUMBER,
  da_exp_loss_charge NUMBER,
  rt_transaction_mwh NUMBER,
  bal_dev_mwh NUMBER,
  rt_sink_loss_price NUMBER,
  rt_source_loss_price NUMBER,
  bal_exp_loss_charge NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_TXN_LOSS_CREDIT_SUMMARY ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  total_pjm_loss_revenues NUMBER,
  real_time_load NUMBER,
  real_time_exports NUMBER,
  total_pjm_rt_ld_plus_exports NUMBER,
  transmission_loss_credit NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_ENG_CONG_LOSSES_CHRGS_RCN ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  edc_la VARCHAR2(32),
  pjm_eschedules_contract_id VARCHAR2(32),
  net_reconciliation_mwh NUMBER(10, 6),
  aggregate_bus_name VARCHAR2(32),
  real_time_energy_price NUMBER,
  real_time_cong_price NUMBER,
  real_time_loss_price NUMBER,
  energy_reconciliation_charge NUMBER,
  cong_reconciliation_charge NUMBER,
  loss_reconciliation_charge NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_INADV_INTERCHG_CHARGE_SUM ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  total_pjm_inadv_interchange NUMBER,
  rt_pjm_energy_price NUMBER,
  rt_cong_price NUMBER,
  rt_loss_price NUMBER,
  customer_rt_load NUMBER,
  total_pjm_rt_load NUMBER,
  customer_inadv_energy_charge NUMBER,
  customer_inadv_cong_charge NUMBER,
  customer_inadv_loss_charge NUMBER
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_EDC_INADVRT_ALLOCATIONS ( 
  org_nid VARCHAR2(32),
  day DATE,
  hour_ending NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  total_edc_rt_load NUMBER(10, 6),
  total_pjm_rt_load NUMBER(10, 6),
  total_pjm_inadv_interchange NUMBER(10, 6),
  edc_inadvertent_mwh NUMBER(10, 6)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_LOAD_ESCHED_WITH_WO_LOSSES ( 
  id VARCHAR2(32),
  type VARCHAR2(32),
  status VARCHAR2(32),
  seller VARCHAR2(32),
  buyer VARCHAR2(32),
  DAY DATE,
  hr1 NUMBER(10, 6),
  hr2 NUMBER(10, 6),
  hr3 NUMBER(10, 6),
  hr4 NUMBER(10, 6),
  hr5 NUMBER(10, 6),
  hr6 NUMBER(10, 6),
  hr7 NUMBER(10, 6),
  hr8 NUMBER(10, 6),
  hr9 NUMBER(10, 6),
  hr10 NUMBER(10, 6),
  hr11 NUMBER(10, 6),
  hr12 NUMBER(10, 6),
  hr13 NUMBER(10, 6),
  hr14 NUMBER(10, 6),
  hr15 NUMBER(10, 6),
  hr16 NUMBER(10, 6),
  hr17 NUMBER(10, 6),
  hr18 NUMBER(10, 6),
  hr19 NUMBER(10, 6),
  hr20 NUMBER(10, 6),
  hr21 NUMBER(10, 6),
  hr22 NUMBER(10, 6),
  hr23 NUMBER(10, 6),
  hr24 NUMBER(10, 6),
  hr25 NUMBER(10, 6),
  TOTAL NUMBER(16, 6)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_EDC_HRLY_LOSS_DER_FACTOR( 
  day DATE,
  hour_ending NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  edc VARCHAR2(32),
  loss_deration_factor NUMBER(10, 6)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_LOAD_RESP_MONTHLY_SUMM ( 
  org_nid VARCHAR2(32),
  edc_account_number VARCHAR2(32),
  end_use_customer VARCHAR2(32),
  zone VARCHAR2(32),
  day DATE,
  hour_ending NUMBER(2),
  dst NUMBER(1),
  cut_date DATE,
  load_response_day_ahead_mwh NUMBER(10, 6),
  day_ahead_lmp NUMBER(10, 6),
  day_ahead_retail_rate_use NUMBER(10, 6),
  csp_day_ahead_credit NUMBER(10, 6),
  lse_day_ahead_charge NUMBER(10, 6),
  cbl_kwh NUMBER(10, 6),
  metered_load_kwh NUMBER(10, 6),
  loss_factor NUMBER(10, 6),
  edc_loss_deration_factor NUMBER(10, 6),
  rt_ld_resp_mwh_plus_losses NUMBER(10, 6),
  real_time_lmp NUMBER(10, 6),
  real_time_retail_rate_used NUMBER(10, 6),
  csp_real_time_credit NUMBER(10, 6),
  lse_real_time_charge NUMBER(10, 6)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_METER_CORR_CHARGE_SUMMARY( 
  org_nid VARCHAR2(32),
  month DATE,
  year DATE,
  COUNTER_PARTY VARCHAR2(32),
  TOTAL_CORRECTION NUMBER (10, 6),
  participant_correction_share NUMBER (10, 6),
  rate NUMBER(10, 6),
  charge NUMBER(10, 6)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_METER_CORR_ALLC_CHRG_SUMM( 
  org_nid VARCHAR2(32),
  month DATE,
  year DATE,
  type VARCHAR2(32),
  total_correction_charge NUMBER (10, 6),
  pjm_east_load NUMBER (10, 6),
  total_pjm_east_load NUMBER(10, 6),
  pjm_region_load NUMBER(10, 6),
  total_pjm_region_load NUMBER(10, 6),
  charge NUMBER(10, 6)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_SCHEDULE_1A_CHARGES( 
  org_nid VARCHAR2(32),
  month DATE,
  zone VARCHAR2(32),
  zonal_rate NUMBER(10,6),
  part_ld_with_losses_in_zone NUMBER (10, 6),
  part_point_to_point_txn_use NUMBER (10, 6),
  charge NUMBER(10, 6),
  total_load_with_losses_in_zone NUMBER(10, 6),
  pjm_total_pt_to_pt_charges NUMBER(10, 6),
  pt_to_pt_allocation_share NUMBER(10, 6),
  credit NUMBER(10, 6)
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_ENG_INADVERT_CHRGS_RCN ( 
  org_id VARCHAR2(32),
  bill_month DATE,
  cut_date DATE,
  zone varchar2(32),
  load_recon_energy NUMBER,
  rt_energy_price NUMBER,
  en_load_recon_charge NUMBER,
  inadvert_en_bill_det NUMBER,
  inadvert_en_recon_chg NUMBER,  
  inadvert_cong_bill_det NUMBER,  
  inadvert_cong_recon_chg NUMBER,  
  inadvert_loss_bill_det NUMBER,  
  inadvert_loss_recon_chg NUMBER  
) ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE PJM_CONG_LOSS_CHRGS_RCN ( 
  org_id VARCHAR2(32),
  bill_month DATE,
  cut_date DATE,
  eschedules_id NUMBER,
  load_recon_energy NUMBER,
  rt_cong_price NUMBER,
  cong_load_recon_charge NUMBER,
  rt_loss_price NUMBER,  
  loss_load_recon_charge NUMBER  
) ON COMMIT PRESERVE ROWS;


