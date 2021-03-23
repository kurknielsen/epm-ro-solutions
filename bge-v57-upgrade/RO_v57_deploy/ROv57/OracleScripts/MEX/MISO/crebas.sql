-- Create table

-- NOTE: IF YOU CHANGE THIS TABLE YOU *MUST* ALSO UPDATE MM_MISO_SETTLEMENT.DUMP_DETS_TO_WORK
--  Code in that procedure assume a certain layout (order of columns and their types)

create table MISO_DET_WORK
(
  WORK_ID    NUMBER(9) not null,
  DET_TYPE   VARCHAR2(32) not null,
  DET_TYP_ID VARCHAR2(32) not null,
  ASSET_NM   VARCHAR2(64),
  SRC_ND_ID  VARCHAR2(32),
  SNK_ND_ID  VARCHAR2(32),
  DP_ND_ID   VARCHAR2(32),
  TX_ID      VARCHAR2(128),
  FTR_ID     VARCHAR2(64),
  FTR_TYP_FL VARCHAR2(32),
  OPT_FL     VARCHAR2(32),
  INT_NUM    NUMBER(2) not null,
  VAL        NUMBER
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

-- we use a unique index but no primary key because some of the columns in this unique index can be null - null
-- values, however, are not allowed in primary key columns
alter table MISO_DET_WORK add constraint AK_MISO_DET_WORK unique (WORK_ID,DET_TYPE,DET_TYP_ID,ASSET_NM,INT_NUM,DP_ND_ID,SRC_ND_ID,SNK_ND_ID,TX_ID,FTR_ID);

-- Create/Recreate indexes
create index IX01_MISO_DET_WORK on MISO_DET_WORK (WORK_ID,DET_TYPE,DET_TYP_ID,INT_NUM,DP_ND_ID,SRC_ND_ID,SNK_ND_ID,TX_ID,FTR_ID);

create index IX02_MISO_DET_WORK on MISO_DET_WORK (WORK_ID,DET_TYPE,DET_TYP_ID,INT_NUM,SRC_ND_ID,SNK_ND_ID,FTR_ID,DP_ND_ID);

create table MISO_CPNODES
(
  NODE_NAME  VARCHAR2(32) not null,
  NODE_TYPE  VARCHAR2(32) not null,
  ENTRY_DATE DATE not null
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


create table MISO_CPNODES_STAGING
(
  NODE_NAME  VARCHAR2(32) not null,
  NODE_TYPE  VARCHAR2(32) not null,
  ENTRY_DATE DATE not null
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
