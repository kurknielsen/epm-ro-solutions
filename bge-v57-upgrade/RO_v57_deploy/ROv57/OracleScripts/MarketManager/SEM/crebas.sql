/*==============================================================*/
/* Temporary tables used for parsing settlement                 */
/*==============================================================*/

CREATE GLOBAL TEMPORARY TABLE SEM_STATEMENT_H_TEMP
(
WORK_ID			NUMBER(9),
FILE_VERSION	VARCHAR2(3),
ENTITY			VARCHAR2(20),
REP_TIMESTAMP	DATE,
FILE_NO			NUMBER(8),
PARTICIPANT		VARCHAR2(100),
STATEMENT_NO	NUMBER(8),
STATEMENT_TYPE	VARCHAR2(1),
MARKET			VARCHAR2(4),
MKT_SEGMENT		VARCHAR2(32),
JOB_ID			NUMBER(8),
JOB_VERSION		NUMBER(8),
JOB_TIMESTAMP	DATE,
SETTLEMENT_DAY 	DATE
)
ON COMMIT PRESERVE ROWS;

ALTER TABLE SEM_STATEMENT_H_TEMP ADD CONSTRAINT PK_SEM_STATEMENT_H_TEMP PRIMARY KEY (WORK_ID);

------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE SEM_STATEMENT_S_TEMP
(
WORK_ID			NUMBER(9),
PRODUCT			VARCHAR2(32),
PRODUCT_DESC	VARCHAR2(1000),
DELIVERY_DAY	DATE,
PAY_OR_CHARGE	VARCHAR2(1),
TOTAL_QUANTITY	NUMBER,
UNIT			VARCHAR2(18),
TOTAL_AMOUNT	NUMBER,
CURRENCY		VARCHAR2(6)
)
ON COMMIT PRESERVE ROWS;

ALTER TABLE SEM_STATEMENT_S_TEMP ADD CONSTRAINT PK_SEM_STATEMENT_S_TEMP PRIMARY KEY (WORK_ID,PRODUCT,DELIVERY_DAY,PAY_OR_CHARGE);

------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE SEM_STATEMENT_D_TEMP
(
WORK_ID			NUMBER(9),
PRODUCT			VARCHAR2(32),
REC_ORDER		NUMBER(8),
PAY_OR_CHARGE	VARCHAR2(1),
OPERATION_DATE	DATE,
OPERATION_HOUR	NUMBER(2),
OPERATION_MIN	NUMBER(2),
RESOLUTION		NUMBER(2),
COMMENTS		VARCHAR2(32),
RESOURCE_NAME	VARCHAR2(100),
LOCATION_NAME	VARCHAR2(10),
JURISDICTION	VARCHAR2(30),
CONTRACT		VARCHAR2(30),
INTERCONNECTOR		VARCHAR2(32),
QUANTITY		NUMBER,
UNIT			VARCHAR2(18),
AMOUNT			NUMBER,
CURRENCY		VARCHAR2(6)
)
ON COMMIT PRESERVE ROWS;

ALTER TABLE SEM_STATEMENT_D_TEMP ADD CONSTRAINT PK_SEM_STATEMENT_D_TEMP PRIMARY KEY (WORK_ID,PRODUCT,OPERATION_DATE,OPERATION_HOUR,OPERATION_MIN,RESOLUTION,RESOURCE_NAME,LOCATION_NAME,REC_ORDER);

------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE SEM_MP_INFO_H_TEMP
(
WORK_ID			NUMBER(9),
FILE_VERSION	VARCHAR2(3),
ENTITY			VARCHAR2(20),
REP_TIMESTAMP	DATE,
FILE_NO			NUMBER(8),
PARTICIPANT		VARCHAR2(100),
STATEMENT_TYPE	VARCHAR2(1),
SETTLEMENT_DAY 	DATE
)
ON COMMIT PRESERVE ROWS;

ALTER TABLE SEM_MP_INFO_H_TEMP ADD CONSTRAINT PK_SEM_MP_INFO_H_TEMP PRIMARY KEY (WORK_ID);

------------------------------------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE SEM_MP_INFO_S_TEMP(
   WORK_ID			    NUMBER(9)   NOT NULL,
   MARKET_CID           VARCHAR2(2) NOT NULL,
   PRODUCT_CID          VARCHAR2(32) NOT NULL,
   JOB_ID               NUMBER(9)   NOT NULL,
   JOB_VERSION          NUMBER(8),
   JOB_TYPE             VARCHAR2(1),
   MARKET_TIMESTAMP     TIMESTAMP)
ON COMMIT PRESERVE ROWS;

ALTER TABLE SEM_MP_INFO_S_TEMP 
ADD CONSTRAINT AK_SEM_MP_INFO_S_TEMP 
UNIQUE (WORK_ID,
        MARKET_CID,
        PRODUCT_CID,
        JOB_ID);

------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE SEM_MP_INFO_D_TEMP
(
WORK_ID			NUMBER(9),
DELIVERY_DATE	DATE,
DELIVERY_HOUR	NUMBER(2),
RESOLUTION		NUMBER(2),
RESOURCE_NAME	VARCHAR2(100),
LOCATION_NAME	VARCHAR2(10),
VARIABLE_TYPE	VARCHAR2(24),
VARIABLE_NAME	VARCHAR2(156),
CONTRACT		VARCHAR2(100),
UNIT			VARCHAR2(18),
VALUE1			NUMBER(28,8),
VALUE2			NUMBER(28,8)
)
ON COMMIT PRESERVE ROWS;

ALTER TABLE SEM_MP_INFO_D_TEMP ADD CONSTRAINT PK_SEM_MP_INFO_D_TEMP PRIMARY KEY (WORK_ID,DELIVERY_DATE,DELIVERY_HOUR,RESOLUTION,VARIABLE_TYPE,VARIABLE_NAME,RESOURCE_NAME,LOCATION_NAME);

------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE SEM_SRA_H_TEMP
(
WORK_ID			NUMBER(9),
FILE_VERSION	VARCHAR2(3),
ENTITY			VARCHAR2(20),
REP_TIMESTAMP	DATE,
PARTICIPANT		VARCHAR2(100),
STATEMENT_TYPE	VARCHAR2(1),
BEGIN_DATE 	DATE,
END_DATE 	DATE
)
ON COMMIT PRESERVE ROWS;

ALTER TABLE SEM_SRA_H_TEMP ADD CONSTRAINT PK_SEM_SRA_H_TEMP PRIMARY KEY (WORK_ID);

------------------------------------------------------------------

CREATE GLOBAL TEMPORARY TABLE SEM_SRA_D_TEMP
(
WORK_ID				NUMBER(9),
COUNTERPARTY			VARCHAR2(100),
REALLOCATION_NAME	VARCHAR2(32),
TRADING_INTERVAL	DATE,
DST_FLAG			NUMBER(1),
UNIT				VARCHAR2(3),
AMOUNT				NUMBER(28,8),
VALIDITY			VARCHAR2(1),
REASON				VARCHAR2(500)
)
ON COMMIT PRESERVE ROWS;

-- no primary key - but we can create this index
CREATE INDEX SEM_SRA_D_TEMP_IX01 ON SEM_SRA_D_TEMP(WORK_ID,COUNTERPARTY,REALLOCATION_NAME,TRADING_INTERVAL,DST_FLAG);

/*==============================================================*/
/* Tables used for settlement downloads                         */
/*==============================================================*/

CREATE TABLE SEM_DETAIL_CHARGE(
CHARGE_ID		NUMBER(12),
CHARGE_DATE		DATE,
RESOLUTION		NUMBER(2),
RESOURCE_NAME	VARCHAR2(100),
LOCATION_NAME	VARCHAR2(100),
REC_ORDER		NUMBER(8),
PAY_OR_CHARGE	VARCHAR2(1),
COMMENTS		VARCHAR2(32),
JURISDICTION	VARCHAR2(30),
CONTRACT		VARCHAR2(30),
INTERCONNECTOR		VARCHAR2(32),
CHARGE_QUANTITY	NUMBER,
QUANTITY_UNIT	VARCHAR2(18),
CHARGE_AMOUNT	NUMBER,
AMOUNT_UNIT		VARCHAR2(18)
);

ALTER TABLE SEM_DETAIL_CHARGE ADD CONSTRAINT PK_SEM_DETAIL_CHARGE PRIMARY KEY (CHARGE_ID,CHARGE_DATE,RESOLUTION,RESOURCE_NAME,LOCATION_NAME,REC_ORDER);

------------------------------------------------------------------

CREATE TABLE SEM_MP_STATEMENT 	(
STATEMENT_ID	NUMBER(9) NOT NULL,
ENTITY_ID		NUMBER(9) NOT NULL,
STATEMENT_TYPE	NUMBER(9) NOT NULL,
STATEMENT_DATE	DATE NOT NULL,
ENTRY_DATE		DATE
);

ALTER TABLE SEM_MP_STATEMENT ADD CONSTRAINT PK_SEM_MP_STATEMENT PRIMARY KEY (STATEMENT_ID);

ALTER TABLE SEM_MP_STATEMENT ADD CONSTRAINT AK_SEM_MP_STATEMENT UNIQUE (ENTITY_ID,STATEMENT_TYPE,STATEMENT_DATE);

ALTER TABLE SEM_MP_STATEMENT
   ADD CONSTRAINT FK_SEM_MP_STATEMENT FOREIGN KEY (ENTITY_ID)
      REFERENCES PURCHASING_SELLING_ENTITY (PSE_ID)
      ON DELETE CASCADE;

------------------------------------------------------------------

CREATE TABLE SEM_MP_INFO(
STATEMENT_ID	NUMBER(9) NOT NULL,
CHARGE_DATE		DATE NOT NULL,
RESOLUTION		NUMBER(2) NOT NULL,
RESOURCE_NAME	VARCHAR2(100) NOT NULL,
LOCATION_NAME	VARCHAR2(100) NOT NULL,
VARIABLE_TYPE 	VARCHAR2(24) NOT NULL,
VARIABLE_NAME 	VARCHAR2(156) NOT NULL,
CONTRACT		VARCHAR2(100),
UNIT			VARCHAR2(18),
VALUE			NUMBER(28,8)
);

ALTER TABLE SEM_MP_INFO ADD CONSTRAINT PK_SEM_MP_INFO PRIMARY KEY (STATEMENT_ID, CHARGE_DATE, RESOLUTION, RESOURCE_NAME, LOCATION_NAME, VARIABLE_TYPE, VARIABLE_NAME);

ALTER TABLE SEM_MP_INFO
   ADD CONSTRAINT FK_SEM_MP_INFO_STATEMENT FOREIGN KEY (STATEMENT_ID)
      REFERENCES SEM_MP_STATEMENT (STATEMENT_ID)
      ON DELETE CASCADE;

------------------------------------------------------------------

CREATE TABLE SEM_MP_INFO_FILES (
   IMPORT_FILE_ID   NUMBER NOT NULL,
   IMPORT_FILE      CLOB NOT NULL,
   IMPORT_TIMESTAMP TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
   FILE_NAME        VARCHAR2(1000) NOT NULL,
   PARTICIPANT		VARCHAR2(100) NOT NULL,
   FILE_DATE        DATE NOT NULL,
   MARKET			VARCHAR2(2) NOT NULL,
   JOB_VERSION		VARCHAR2(8) NOT NULL,
   JOB_ID			VARCHAR2(9) NOT NULL
);

ALTER TABLE SEM_MP_INFO_FILES 
   ADD CONSTRAINT PK_SEM_MP_INFO_FILES 
      PRIMARY KEY (IMPORT_FILE_ID)
      USING INDEX TABLESPACE NERO_INDEX;

------------------------------------------------------------------

CREATE TABLE SEM_SRA (
ENTITY_ID		NUMBER(9),
STATEMENT_TYPE	NUMBER(9),
BEGIN_DATE		DATE,
END_DATE		DATE,
COUNTERPARTY_ID		NUMBER(9),
AGREEMENT_NAME	VARCHAR2(32),
CHARGE_DATE		DATE,
UNIT			VARCHAR2(3),
SRA_AMOUNT		NUMBER(28,8),
IS_VALID		NUMBER(1),
REASON_INVALID	VARCHAR2(500),
ENTRY_DATE		DATE
);

-- no primary key - but we can create this index
CREATE INDEX SEM_SRA_IX01 ON SEM_SRA(ENTITY_ID, STATEMENT_TYPE, BEGIN_DATE, COUNTERPARTY_ID, AGREEMENT_NAME, CHARGE_DATE)
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );

ALTER TABLE SEM_SRA
   ADD CONSTRAINT FK_SEM_SRA_ENTITY FOREIGN KEY (ENTITY_ID)
      REFERENCES PURCHASING_SELLING_ENTITY (PSE_ID)
      ON DELETE CASCADE;

ALTER TABLE SEM_SRA
   ADD CONSTRAINT FK_SEM_SRA_COUNTERPARTY FOREIGN KEY (COUNTERPARTY_ID)
      REFERENCES PURCHASING_SELLING_ENTITY (PSE_ID)
      ON DELETE SET NULL;

------------------------------------------------------------------

CREATE TABLE SEM_INVOICE (
  INVOICE_ID       NUMBER(12) not null,
  INVOICE_NUMBER   VARCHAR2(10),
  SENDER_STREET    VARCHAR2(256),
  SENDER_CITY      VARCHAR2(102),
  SENDER_PHONE     VARCHAR2(20),
  SENDER_FAX       VARCHAR2(20),
  SENDER_TAX_ID     VARCHAR2(64),
  RECEIVER_NAME    VARCHAR2(100),
  RECEIVER_STREET  VARCHAR2(256),
  RECEIVER_CITY    VARCHAR2(102),
  RECEIVER_GL      VARCHAR2(20),
  INVOICE_TYPE     VARCHAR2(1),
  DUE_DATE         DATE,
  INVOICE_HEADER   VARCHAR2(200),
  INV_COMMENT      VARCHAR2(160),
  SIGNATURE1       VARCHAR2(120),
  UNIT             VARCHAR2(18),
  INVOICE_DATE     DATE,
  CALENDAR_ID      VARCHAR2(8),
  INVOICE_AMOUNT   NUMBER,
  MARKET_NAME      VARCHAR2(120),
  BILL_PERIOD_NAME VARCHAR2(255),
  RECEIVER_ID      VARCHAR2(120),
  FIRST_AMOUNT     NUMBER,
  EXCHANGE_RATE    NUMBER,
  VAT_JURISDICTION VARCHAR2(30),  
  VERSION		VARCHAR2(16),
  EVENT_ID         NUMBER(9)
);

ALTER TABLE SEM_INVOICE ADD CONSTRAINT PK_SEM_INVOICE PRIMARY KEY (INVOICE_ID);


ALTER TABLE SEM_INVOICE
   ADD CONSTRAINT FK_SEM_INVOICE FOREIGN KEY (INVOICE_ID)
      REFERENCES INVOICE (INVOICE_ID)
      ON DELETE CASCADE;

------------------------------------------------------------------

CREATE TABLE SEM_INVOICE_JOB (
INVOICE_ID				NUMBER(12),
JOB_ID					VARCHAR2(8),
JOB_NAME				VARCHAR2(100),
SETTLEMENT_DAY		DATE,
JOB_NUMBER			NUMBER(16),
JOB_VERSION			VARCHAR2(8),
JOB_STATE				VARCHAR2(6),
JOB_STATUS				VARCHAR2(6),
TRUE_UP_BASED_ON		VARCHAR2(8),
STATEMENT_ID			NUMBER(8),
GLOBAL_PARTICIPANT_NAME	VARCHAR2(100)
);

-- No primary key - but we can create this index
CREATE INDEX SEM_INVOICE_JOB_IX01 ON SEM_INVOICE_JOB (INVOICE_ID, JOB_ID)
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );

ALTER TABLE SEM_INVOICE_JOB
   ADD CONSTRAINT FK_SEM_INVOICE_JOB FOREIGN KEY (INVOICE_ID)
      REFERENCES INVOICE (INVOICE_ID)
      ON DELETE CASCADE;

------------------------------------------------------------------
create table SEM_INVOICE_LINE_ITEM
(
  INVOICE_ID            NUMBER(12) not null,
  LINE_ITEM_NAME        VARCHAR2(128) not NULL,
  BILL_HEADING          VARCHAR2(119),
  CHARGE_DESCRIPTION    VARCHAR2(120),
  CHARGE_ID             VARCHAR2(24),
  QUANTITY              NUMBER,
  QTY_UNIT              VARCHAR2(18),
  AMOUNT                NUMBER,
  AMOUNT_UNIT           VARCHAR2(18),
  BILL_ORDER            VARCHAR2(32),
  CHARGE_TYPE           NUMBER(1),
  TAX_AMOUNT            NUMBER,
  TAX_VARTYPE_CODE      VARCHAR2(24),
  TAX_VARTYPE_NAME      VARCHAR2(120),
  TAX_PAY_OR_CHARGE     VARCHAR2(1),
  TAX_PERCENT_TEXT	VARCHAR2(10),
  PREV_AMOUNT           NUMBER,
  PREV_TAX_AMOUNT       NUMBER  
);

-- Add comments to the columns 
comment on column SEM_INVOICE_LINE_ITEM.INVOICE_ID
  is 'Unique ID of the Invoice to which this line item belongs';
comment on column SEM_INVOICE_LINE_ITEM.LINE_ITEM_NAME
  is 'The Line Item Text';
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_INVOICE_LINE_ITEM add constraint PK_SEM_INVOICE_LINE_ITEM primary key (INVOICE_ID, LINE_ITEM_NAME);

ALTER TABLE SEM_INVOICE_LINE_ITEM
   ADD CONSTRAINT FK_SEM_INVOICE_LINE_ITEM FOREIGN KEY (INVOICE_ID)
      REFERENCES INVOICE (INVOICE_ID)
      ON DELETE CASCADE;

------------------------------------------------------------------
create table SEM_INVOICE_TAX_SUM
(
  INVOICE_ID            NUMBER(12) not null,
  TAX_PERCENT_TEXT      VARCHAR2(10),
  TAX_PAY_OR_CHARGE 	VARCHAR2(1),
  NET_AMOUNT            NUMBER,
  TAX_TOTAL_AMOUNT      NUMBER,
  GROSS_AMOUNT          NUMBER 
);
-- Create/Recreate primary, unique and foreign key constraints 
ALTER TABLE SEM_INVOICE_TAX_SUM
   ADD CONSTRAINT FK_SEM_INVOICE_TAX_SUM FOREIGN KEY (INVOICE_ID)
      REFERENCES INVOICE (INVOICE_ID)
      ON DELETE CASCADE;

------------------------------------------------------------------
CREATE TABLE SEM_SETTLEMENT_DOWNLOADS
(
STATEMENT_DATE	DATE NOT NULL,
FILE_NAME		VARCHAR2(256) NOT NULL,
EVENT_ID   		NUMBER(9),
ENTRY_DATE		DATE
);

ALTER TABLE SEM_SETTLEMENT_DOWNLOADS ADD CONSTRAINT PK_SEM_SETTLEMENT_DOWNLOADS PRIMARY KEY (STATEMENT_DATE, FILE_NAME);


/*==============================================================*/
/* Tables used for Public/Private reports download              */
/*==============================================================*/

create table SEM_LOAD
(
  PERIODICITY   VARCHAR2(6) not null,
  SCHEDULE_DATE DATE not null,
  JURISDICTION  VARCHAR2(4),
  LOAD_MW       NUMBER(8,3),
  NET_MW        NUMBER(8,3),
  ASSUMPTIONS   VARCHAR2(128),
  EVENT_ID      NUMBER(9),
  REPORT_NAME   VARCHAR2(64) DEFAULT '?' NOT NULL,
    constraint PK_SEM_LOAD primary key (PERIODICITY, SCHEDULE_DATE, JURISDICTION, REPORT_NAME)
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

------------------------------------------------------------------

create table SEM_DISPATCH_INSTR
(
  REPORT_TYPE                  VARCHAR2(4) not null,
  PSE_ID                       NUMBER(9) not null,
  POD_ID                       NUMBER(9) not null,
  INSTRUCTION_TIME_STAMP       DATE not null,
  INSTRUCTION_ISSUE_TIME       DATE not null,
  INSTRUCTION_CODE             VARCHAR2(4) not null,
  INSTRUCTION_COMBINATION_CODE VARCHAR2(4) not null,
  DISPATCH_INSTRUCTION         NUMBER(8,3),
  RAMP_UP_RATE                 NUMBER(8,3),
  RAMP_DOWN_RATE               NUMBER(8,3),
  EVENT_ID                     NUMBER(9)
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
-- Add comments to the columns 
comment on column SEM_DISPATCH_INSTR.PSE_ID
  is 'Foreign key to the PURCHASE_SELLING_ENTITY table';
comment on column SEM_DISPATCH_INSTR.POD_ID
  is 'Foreign key to the SERVICE_POINT table';
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_DISPATCH_INSTR
  add constraint PK_SEM_DISPATCH_INSTR primary key (REPORT_TYPE, PSE_ID, POD_ID, INSTRUCTION_TIME_STAMP, INSTRUCTION_ISSUE_TIME, INSTRUCTION_CODE, INSTRUCTION_COMBINATION_CODE)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_DISPATCH_INSTR
  add constraint FK_SEM_DISPATCH_INSTR_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_DISPATCH_INSTR
  add constraint FK_SEM_DISPATCH_INSTR_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;

------------------------------------------------------------------

CREATE TABLE SEM_LOSS_FACTOR(
    SCHEDULE_DATE      DATE        NOT NULL,
    PSE_ID             NUMBER(9),
    POD_ID             NUMBER(9),
    LOSS_FACTOR        NUMBER(4,3),
    EVENT_ID           NUMBER(9),
    constraint PK_SEM_LOSS_FACTOR primary key (SCHEDULE_DATE, PSE_ID, POD_ID)
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

comment on column SEM_LOSS_FACTOR.PSE_ID is
'Foreign key to the PURCHASE_SELLING_ENTITY table';

comment on column SEM_LOSS_FACTOR.POD_ID is
'Foreign key to the SERVICE_POINT table';

alter table SEM_LOSS_FACTOR
   add constraint FK_LOSS_FACTOR_PSE foreign key (PSE_ID)
      references PSE (PSE_ID)
      on delete cascade;

alter table SEM_LOSS_FACTOR
   add constraint FK_LOSS_FACTOR_POD foreign key (POD_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete cascade;
------------------------------------------------------------------
CREATE GLOBAL TEMPORARY TABLE SEM_TLAF_TEMP
(
    TRADE_DATE         DATE,
	PSE_ID             NUMBER(9), 
	POD_ID             NUMBER(9),
	DELIVERY_DATE      DATE,
	DELIVERY_HOUR      NUMBER,
	DELIVERY_INTERVAL  NUMBER, 
	LOSS_FACTOR        NUMBER
);
------------------------------------------------------------------
create table SEM_GEN_FORECAST
(
  SCHEDULE_DATE DATE not null,
  PERIODICITY   VARCHAR2(2) not null,
  JURISDICTION  VARCHAR2(4) not null,
  PSE_ID        NUMBER(9) not null,
  POD_ID        NUMBER(9) not null,
  FORECAST_MW   NUMBER(8,3),
  ASSUMPTIONS   VARCHAR2(128),
  EVENT_ID      NUMBER(9)  
)
tablespace NERO_DATA
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    minextents 1
    maxextents unlimited
  );
-- Add comments to the columns 
comment on column SEM_GEN_FORECAST.PSE_ID
  is 'Foreign key to the PURCHASE_SELLING_ENTITY table';
comment on column SEM_GEN_FORECAST.POD_ID
  is 'Foreign key to the SERVICE_POINT table';
comment on column SEM_GEN_FORECAST.PERIODICITY
  is 'D1, D2, D3, D4 for (D+1), (D+2), (D+3), (D+4) respectively.';
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_GEN_FORECAST
  add constraint PK_SEM_GEN_FORECAST primary key (SCHEDULE_DATE, PERIODICITY, JURISDICTION, PSE_ID, POD_ID)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_GEN_FORECAST
  add constraint FK_SEM_GEN_FORECAST_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_GEN_FORECAST
  add constraint FK_SEM_GEN_FORECAST_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;


------------------------------------------------------------------

CREATE TABLE SEM_LOSS_LOAD_PROB_FORECAST(
    SCHEDULE_DATE                   DATE      NOT NULL,
    LOSS_OF_LOAD_PROBABILITY        NUMBER(11,5),
	EVENT_ID                        NUMBER(9),
	PERIODICITY 					VARCHAR2(6), 
    constraint PK_SEM_LOSS_LOAD_PROB_FORECAST primary key (SCHEDULE_DATE, PERIODICITY)
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

------------------------------------------------------------------

create table SEM_IC_DATA
(
  schedule_date                DATE not null,
  pod_id                       NUMBER(9) not null,
  pse_id                       NUMBER(9) not null,
  run_type                     VARCHAR2(4) not null,
  maximum_import_mw            NUMBER(8,3),
  maximum_export_mw            NUMBER(8,3),
  rev_maximum_import_mw        NUMBER(8,3),
  rev_maximum_export_mw        NUMBER(8,3),
  indicative_net_flow          NUMBER(8,3),
  indicative_residual_capacity NUMBER(8,3),
  initial_net_flow             NUMBER(8,3),
  initial_residual_capacity    NUMBER(8,3),
  unit_nomination              NUMBER(8,3),
  atc_event_id                 NUMBER(9),
  rev_atc_event_id             NUMBER(9),
  indic_event_id               NUMBER(9),
  init_event_id                NUMBER(9),
  nom_event_id                 NUMBER(9)
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

comment on column SEM_IC_DATA.POD_ID is
'Foreign key to the SERVICE_POINT table';

alter table SEM_IC_DATA
  add constraint PK_SEM_IC_DATA primary key (SCHEDULE_DATE, POD_ID, PSE_ID, RUN_TYPE)
  using index 
  tablespace NERO_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
  
alter table SEM_IC_DATA
  add constraint FK_SEM_IC_DATA_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;

------------------------------------------------------------------

CREATE TABLE SEM_IC_ERR_UNIT_BALANCE(
    POD_ID                          NUMBER(9)    NOT NULL,
    EFFECTIVE_DATE                  DATE         NOT NULL,
    INTERCONNECTOR_ADMINISTRATOR    VARCHAR2(128),
    INTERCONNECTOR_IMPORT_CAPACITY  NUMBER(8,3),
    INTERCONNECTOR_EXPORT_CAPACITY  NUMBER(8,3),
    MAXIMUM_EXPORT_CAPACITY         NUMBER(8,3),
    MAXIMUM_IMPORT_CAPACITY         NUMBER(8,3),
    INTERCONNECTOR_RAMP_RATE        NUMBER(8,3),
    EXPIRATION_DATE                 DATE,
	EVENT_ID                        NUMBER(9),
    constraint PK_SEM_IC_ERR_UNIT_BALANCE primary key (POD_ID,EFFECTIVE_DATE)
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

comment on column SEM_IC_ERR_UNIT_BALANCE.POD_ID is
'Foreign key to the SERVICE_POINT table';

alter table SEM_IC_ERR_UNIT_BALANCE
   add constraint FK_SEM_IC_ERR_UNIT_BALANCE_POD foreign key (POD_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete cascade;

------------------------------------------------------------------

CREATE TABLE SEM_IC_NET_ACTUAL(
    SCHEDULE_DATE        DATE         NOT NULL,
    PSE_ID               NUMBER(9)    NOT NULL,
    POD_ID               NUMBER(9)    NOT NULL,
    RUN_TYPE             VARCHAR2(4)  NOT NULL,
    GATE_WINDOW 		 VARCHAR2(4)  NOT NULL,
    SCHEDULE_MW          NUMBER(8,3),
	EVENT_ID             NUMBER(9),
    constraint PK_SEM_IC_NET_ACTUAL primary key (SCHEDULE_DATE, PSE_ID, POD_ID, RUN_TYPE, GATE_WINDOW)
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

comment on column SEM_IC_NET_ACTUAL.PSE_ID is
'Foreign key to the PURCHASE_SELLING_ENTITY table';

comment on column SEM_IC_NET_ACTUAL.POD_ID is
'Foreign key to the SERVICE_POINT table';

alter table SEM_IC_NET_ACTUAL
   add constraint FK_SEM_IC_NET_ACTUAL_PSE foreign key (PSE_ID)
      references PSE (PSE_ID)
      on delete cascade;

alter table SEM_IC_NET_ACTUAL
   add constraint FK_SEM_IC_NET_ACTUAL_POD foreign key (POD_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete cascade;

------------------------------------------------------------------

CREATE TABLE SEM_IC_CAP_HOLDINGS(
    PERIODICITY                      VARCHAR2(2)  NOT NULL,
    SCHEDULE_DATE                   DATE         NOT NULL,
    PSE_ID                          NUMBER(9)    NOT NULL,
    POD_ID                          NUMBER(9)    NOT NULL,
    IC_EXPORT_CAPACITY              NUMBER(8,3),
    IC_IMPORT_CAPACITY              NUMBER(8,3),
	EVENT_ID                        NUMBER(9),
    constraint PK_SEM_IC_CAP_HOLDINGS primary key (PERIODICITY,SCHEDULE_DATE,PSE_ID, POD_ID)
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

comment on column SEM_IC_CAP_HOLDINGS.PSE_ID is
'Foreign key to the PURCHASE_SELLING_ENTITY table';

comment on column SEM_IC_CAP_HOLDINGS.POD_ID is
'Foreign key to the SERVICE_POINT table';

alter table SEM_IC_CAP_HOLDINGS
   add constraint FK_SEM_IC_CAP_HOLDINGS_PSE foreign key (PSE_ID)
      references PSE (PSE_ID)
      on delete cascade;

alter table SEM_IC_CAP_HOLDINGS
   add constraint FK_SEM_IC_CAP_HOLDINGS_POD foreign key (POD_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete cascade;

------------------------------------------------------------------

CREATE TABLE SEM_METER_SUMMARY (
    PERIODICITY        VARCHAR2(2)   NOT NULL,
    SCHEDULE_DATE      DATE          NOT NULL,
    TOTAL_GEN          NUMBER(8,3),
    TOTAL_LOAD         NUMBER(8,3),
	EVENT_ID           NUMBER(9),
    constraint PK_SEM_METER_SUMMARY primary key (PERIODICITY, SCHEDULE_DATE)
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

------------------------------------------------------------------

CREATE TABLE SEM_METER_DETAIL (
    PERIODICITY        VARCHAR2(2)   NOT NULL,
    SCHEDULE_DATE      DATE          NOT NULL,
    JURISDICTION       VARCHAR2(4),
    POD_ID             NUMBER(9),
    RESOURCE_TYPE      VARCHAR2(4),
    METERED_MW         NUMBER(8,3),
    METER_TRANSMISSION_TYPE  VARCHAR2(4),
	EVENT_ID           NUMBER(9),
    constraint PK_SEM_METER_DETAIL primary key (PERIODICITY, SCHEDULE_DATE, POD_ID)
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

alter table SEM_METER_DETAIL
   add constraint FK_SEM_METER_DETAIL_POD foreign key (POD_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete cascade;
      
------------------------------------------------------------------      

CREATE TABLE SEM_OUTAGE_SCHEDULE (
    REPORT_SOURCE           VARCHAR2(64) NOT NULL,
	POD_ID                  NUMBER(9)    NOT NULL,
    BEGIN_TIME              DATE         NOT NULL,
    END_TIME                DATE,
    OUTAGE_REASON_FLAG      VARCHAR2(1),
    DERATE_MW               NUMBER(8,3),
    EQUIPMENT_STATUS        VARCHAR2(1),
    EVENT_ID                NUMBER(9),
    constraint PK_SEM_OUTAGE_SCHEDULE primary key (REPORT_SOURCE, POD_ID, BEGIN_TIME)
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


comment on column SEM_OUTAGE_SCHEDULE.POD_ID is
'Foreign key to the SERVICE_POINT table';


alter table SEM_OUTAGE_SCHEDULE
   add constraint FK_SEM_OUTAGE_SCHEDULE_POD foreign key (POD_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete cascade;

---------------------------------------------------------------------------

create table SEM_INACTIVE_PART
(
  PSE_ID       NUMBER(9) not null,
  EFF_DATE     DATE not null,
  EXP_DATE     DATE,
  EVENT_ID     NUMBER(9),
  ENTRY_DATE   DATE
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
-- Add comments to the columns 
comment on column SEM_INACTIVE_PART.PSE_ID
  is 'Foreign key to the PURCHASE_SELLING_ENTITY table';
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_INACTIVE_PART
  add constraint PK_SEM_INACTIVE_PART primary key (PSE_ID, EFF_DATE)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_INACTIVE_PART
  add constraint FK_SEM_INACTIVE_PART_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;

----------------------------------------------------------------------------
CREATE TABLE SEM_SYSTEM_FREQUENCY (
    PSE_ID               NUMBER(9)    NOT NULL,
    SCHEDULE_DATE        DATE         NOT NULL,
	NORMAL_FREQUENCY     NUMBER(8,3), 
    AVERAGE_FREQUENCY    NUMBER(8,3),
    EVENT_ID             NUMBER(9),
    constraint PK_SEM_SYSTEM_FREQUENCY primary key (PSE_ID, SCHEDULE_DATE)
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


comment on column SEM_SYSTEM_FREQUENCY.PSE_ID is
'Foreign key to the PURCHASE_SELLING_ENTITY table';

alter table SEM_SYSTEM_FREQUENCY
   add constraint FK_SEM_SYSTEM_FREQUENCY_PSE foreign key (PSE_ID)
      references PSE (PSE_ID)
      on delete cascade;

-------------------------------------------------------------------------   
CREATE TABLE SEM_SERVICE_POINT_PSE (
   POD_ID       NUMBER(9),
   PSE_ID       NUMBER(9),
   BEGIN_DATE   DATE,
   END_DATE     DATE,
   ENTRY_DATE   DATE,
   constraint PK_SEM_SERVICE_POINT_PSE primary key (POD_ID, BEGIN_DATE)
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

comment on column SEM_SERVICE_POINT_PSE.PSE_ID is
'Foreign key to the PURCHASE_SELLING_ENTITY table';

comment on column SEM_SERVICE_POINT_PSE.POD_ID is
'Foreign key to the SERVICE_POINT table';

alter table SEM_SERVICE_POINT_PSE
   add constraint FK_SEM_SERVICE_POINT_PSE_ID foreign key (PSE_ID)
      references PSE (PSE_ID)
      on delete cascade;

alter table SEM_SERVICE_POINT_PSE
   add constraint FK_SEM_SERVICE_POINT_POD_ID foreign key (POD_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete cascade;  


-------------------------------------------------------------------------

create table RO_REPORT_FILTERS
(
  STRING_VAL  VARCHAR2(64),
  FILTER_TYPE VARCHAR2(32)
);

create index RO_REPORTS_FILTERS_TYPE_IDX01 on RO_REPORT_FILTERS (STRING_VAL)
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );

create index RO_REPORTS_FILTERS_TYPE_IDX02 on RO_REPORT_FILTERS (FILTER_TYPE)
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );

-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_RESULT (
   ASSESSMENT_DATE     DATE not null,
   STATEMENT_TYPE_ID   NUMBER(9) not null,
   STATEMENT_STATE     NUMBER(1) not null,
   ENTITY_GROUP_ID     NUMBER(9) not null,
   PSE_ID              NUMBER(9) not null,
   CREDIT_MARKET       VARCHAR2(3) not null,
   PARTICIPANT_STATUS  VARCHAR2(1),
   CURRENCY            VARCHAR2(3),
   REQD_CREDIT_COVER   NUMBER(30,2),
   POSTED_CREDIT_COVER NUMBER(30,2),
   INVOICES_NOT_PAID   NUMBER(30,2),
   SETTLEMENT_NOT_INVOICED NUMBER(30,2),
   INTCONN_TRADED_AMT  NUMBER,
   UNDEFINED_EXPOSURE  NUMBER(30,2),
   FIXED_CREDIT_REQT   NUMBER(30,2),
   SRAS_TOTAL          NUMBER(30,2),
   SRAS_SUBMITTED      NUMBER(30,2),
   VAT_AMOUNT          NUMBER(30,2),
   WARNING_LIMIT       NUMBER(30,2),
   BREACH_AMOUNT       NUMBER(30,2),
   GROSS_CC            NUMBER(30,2),
   NET_CC_ALL_SRAS     NUMBER(30,2),
   CALCULATED_DATE     DATE,
   PSE_TYPE            VARCHAR2(16),
   constraint PK_SEM_CREDIT_RESULT primary key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, STATEMENT_STATE, ENTITY_GROUP_ID, PSE_ID, CREDIT_MARKET)
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

alter table SEM_CREDIT_RESULT
   add constraint FK_SEM_CRED_RES_ENT_GRP foreign key (ENTITY_GROUP_ID)
      references ENTITY_GROUP (ENTITY_GROUP_ID)
      on delete cascade;

alter table SEM_CREDIT_RESULT
   add constraint FK_SEM_CRED_RES_PSE foreign key (PSE_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade;

alter table SEM_CREDIT_RESULT
   add constraint FK_SEM_CRED_RES_STMT foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
      on delete cascade;

-------------------------------------------------------------------------

create table SEM_CREDIT_CALC_EXTERNAL
(
  ASSESSMENT_DATE            DATE not null,
  ENTITY_GROUP_ID            NUMBER(9) not null,
  CREDIT_MARKET              VARCHAR2(50) not null,
  UNDEFINED_PERIOD           NUMBER(30,2),
  ANALYSIS_PERCENTILE_PARAM  NUMBER(30,2),
  HIST_ASSESSMENT_PERIOD     NUMBER(30,2),
  CREDIT_ASSESSMENT_PRICE    NUMBER(31,3),
  CAPACITY_ADJUSTMENT_FACTOR NUMBER(30,2),
  VERSION                    NUMBER(3) not null,
  TIME_STAMP                 DATE,
  UDEF_PERIOD_GEN            NUMBER(9),
  UDEF_PERIOD_SUPP           NUMBER(9),
  FORECAST_PRICE             NUMBER(30,3),
  ECPI                       NUMBER(30,3)
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_CREDIT_CALC_EXTERNAL
  add constraint PK_SEM_CREDIT_CALC_EXTERNAL primary key (ASSESSMENT_DATE, ENTITY_GROUP_ID, CREDIT_MARKET, VERSION)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_CREDIT_CALC_EXTERNAL
  add constraint FK_SEM_CRED_CALC_EXT_ENT_GRP foreign key (ENTITY_GROUP_ID)
  references ENTITY_GROUP (ENTITY_GROUP_ID) on delete cascade;

-------------------------------------------------------------------------
CREATE TABLE SEM_CREDIT_CALC_CURRENCY (
   ASSESSMENT_DATE           DATE not null,
   STATEMENT_TYPE_ID         NUMBER(9) not null,
   CURRENCY                  VARCHAR2(3) not null,
   ANALYSIS_PERCENTILE_PARAM NUMBER(7,6),
   VAR_MO_PRICE              NUMBER(16,6),
   IMPERFECTIONS_PRICE       NUMBER(16,6),
   AVERAGE_SMP               NUMBER,
   STD_DEVIATION_SMP         NUMBER,
   AVERAGE_CPDP              NUMBER,
   STD_DEVIATION_CPDP        NUMBER,
   CREDIT_ASSESSMENT_PRICE   NUMBER(31,3),
   ESTIMATED_CAPACITY_PRICE  NUMBER,
   constraint PK_SEM_CREDIT_CALC_CURRENCY primary key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, CURRENCY)
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

alter table SEM_CREDIT_CALC_CURRENCY
   add constraint FK_SEM_CRED_CALC_CURRENCY_STMT foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
      on delete cascade;

-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_CALC_PSE (
   ASSESSMENT_DATE               DATE not null,
   STATEMENT_TYPE_ID             NUMBER(9) not null,
   PSE_ID                        NUMBER(9) not null,
   CREDIT_MARKET                 VARCHAR2(3) not null,
   CREDIT_ASSESSMENT_VOLUME      NUMBER,
   CAPACITY_ADJUSTMENT_FACTOR    NUMBER,
   AVERAGE_HIST_SETTLEMENT       NUMBER,
   STD_DEVIATION_HIST_SETTLEMENT NUMBER,
   DAYS_TO_PAY_INVOICE           NUMBER(2),
   NOT_PAID_BEGIN_DATE           DATE,
   NOT_PAID_END_DATE             DATE,
   NOT_INVOICED_BEGIN_DATE       DATE,
   NOT_INVOICED_END_DATE         DATE,
   HIST_ASSESSMENT_PERIOD        NUMBER(4),
   HIST_ASSESSMENT_BEGIN_DATE    DATE,
   HIST_ASSESSMENT_END_DATE      DATE,
   UNDEFINED_PERIOD              NUMBER(3),
   UNDEFINED_PERIOD_BEGIN_DATE   DATE,
   UNDEFINED_PERIOD_END_DATE     DATE,
   PSE_TYPE                      VARCHAR2(16),
   constraint PK_SEM_CREDIT_CALC_PSE primary key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
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

alter table SEM_CREDIT_CALC_PSE
   add constraint FK_SEM_CRED_CALC_PSE_PSE foreign key (PSE_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade;

alter table SEM_CREDIT_CALC_PSE
   add constraint FK_SEM_CRED_CALC_PSE_STMT foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
      on delete cascade;


-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_INPUT_YEARLY (
   BEGIN_DATE                   DATE NOT NULL,
   END_DATE                     DATE,
   ANALYSIS_PERCENTILE_PARAM     NUMBER(7,6),
   FIXED_CREDIT_REQT_SUP         NUMBER,
   FIXED_CREDIT_REQT_GEN         NUMBER,
   VAR_MO_PRICE                  NUMBER(16,6),
   IMPERFECTIONS_PRICE           NUMBER(16,6),
   HIST_ASSESSMENT_PERIOD_EN     NUMBER(4),
   HIST_ASSESSMENT_PERIOD_CA     NUMBER(4),
   constraint PK_SEM_CREDIT_INPUT_YEARLY primary key (BEGIN_DATE)
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

-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_INPUT_ENTITY_GROUP (
   ASSESSMENT_DAY                DATE NOT NULL,
   ENTITY_GROUP_ID               NUMBER(9),
   POSTED_CREDIT_COVER           NUMBER,
   constraint PK_SEM_CREDIT_INPUT_ENTITY_GP primary key (ASSESSMENT_DAY, ENTITY_GROUP_ID)
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

alter table SEM_CREDIT_INPUT_ENTITY_GROUP
   add constraint FK_SEM_CRED_IEG_ENT_GRP foreign key (ENTITY_GROUP_ID)
      references ENTITY_GROUP (ENTITY_GROUP_ID)
      on delete cascade;
-------------------------------------------------------------------------
create table SEM_SETTLEMENT_CALENDAR
(
  PUBLICATION_DATE DATE not null,
  PUBLICATION_TYPE VARCHAR2(16) not null,
  MARKET           VARCHAR2(16) not null,
  RUN_TYPE         VARCHAR2(16) not null,
  BEGIN_DATE       DATE not null,
  END_DATE         DATE not null,
  RUN_IDENTIFIER   VARCHAR2(16) not null
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_SETTLEMENT_CALENDAR
  add constraint PK_SEM_SETTLEMENT_CALENDAR primary key (PUBLICATION_DATE, PUBLICATION_TYPE, MARKET, RUN_TYPE, BEGIN_DATE)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
-------------------------------------------------------------------------
create table SEM_TRANSACTION_CFD_TERMS
(
  TRANSACTION_ID    NUMBER(9) not null,
  SCHEDULE_DATE     DATE not null,
  FILL_TEMPLATE     VARCHAR2(16) not null,
  TEMPLATE_ORDER    NUMBER(2) not null,
  CONTRACT_QUANTITY NUMBER(10,3),
  STRIKE_PRICE      NUMBER(10,3)
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_TRANSACTION_CFD_TERMS
  add constraint PK_SEM_TXN_CFD_TERMS primary key (TRANSACTION_ID, SCHEDULE_DATE, FILL_TEMPLATE, TEMPLATE_ORDER)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_TRANSACTION_CFD_TERMS
  add constraint FK_SEM_TXN_CFD_TERMS_TXN_ID foreign key (TRANSACTION_ID)
  references INTERCHANGE_TRANSACTION (TRANSACTION_ID) on delete cascade;
-------------------------------------------------------------------------

create table SEM_COMM_OFFER_IC
(
  PSE_ID                        NUMBER(9) not null,
  POD_ID                        NUMBER(9) not null,
  SCHEDULE_DATE                 DATE not null,
  GATE_WINDOW 					VARCHAR2(4) DEFAULT 'EA' NOT NULL,
  RESOURCE_TYPE                 VARCHAR2(4),
  JURISDICTION                  VARCHAR2(4),
  PRICE_1                       NUMBER(8,2),
  QUANTITY_1                    NUMBER(8,3),
  PRICE_2                       NUMBER(8,2),
  QUANTITY_2                    NUMBER(8,3),
  PRICE_3                       NUMBER(8,2),
  QUANTITY_3                    NUMBER(8,3),
  PRICE_4                       NUMBER(8,2),
  QUANTITY_4                    NUMBER(8,3),
  PRICE_5                       NUMBER(8,2),
  QUANTITY_5                    NUMBER(8,3),
  PRICE_6                       NUMBER(8,2),
  QUANTITY_6                    NUMBER(8,3),
  PRICE_7                       NUMBER(8,2),
  QUANTITY_7                    NUMBER(8,3),
  PRICE_8                       NUMBER(8,2),
  QUANTITY_8                    NUMBER(8,3),
  PRICE_9                       NUMBER(8,2),
  QUANTITY_9                    NUMBER(8,3),
  PRICE_10                      NUMBER(8,2),
  QUANTITY_10                   NUMBER(8,3),
  MAXIMUM_IU_IMPORT_CAPACITY_MW NUMBER(8,3),
  MAXIMUM_IU_EXPORT_CAPACITY_MW NUMBER(8,3),
  EVENT_ID                      NUMBER(9)
)
;
alter table SEM_COMM_OFFER_IC
  add constraint PK_SEM_CO_IC primary key (PSE_ID, POD_ID, SCHEDULE_DATE, GATE_WINDOW);
alter table SEM_COMM_OFFER_IC
  add constraint FK_SEM_CO_IC_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_COMM_OFFER_IC
  add constraint FK_SEM_CO_IC_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_COMM_OFFER_STD_UNITS
(
  POD_ID                NUMBER(9) not null,
  SCHEDULE_DATE         DATE not null,
  SCHEDULE_TYPE         NUMBER(9) not null,
  RESOURCE_TYPE         VARCHAR2(4),
  JURISDICTION          VARCHAR2(4),
  FUEL_TYPE             VARCHAR2(5),
  PRIORITY_DISPATCH_YN  VARCHAR2(1),
  PUMP_STORAGE_YN       VARCHAR2(1),
  ENERGY_LIMIT_YN       VARCHAR2(1),
  UNDER_TEST_YN         VARCHAR2(1),
  PRICE_1               NUMBER(8,2),
  QUANTITY_1            NUMBER(8,3),
  PRICE_2               NUMBER(8,2),
  QUANTITY_2            NUMBER(8,3),
  PRICE_3               NUMBER(8,2),
  QUANTITY_3            NUMBER(8,3),
  PRICE_4               NUMBER(8,2),
  QUANTITY_4            NUMBER(8,3),
  PRICE_5               NUMBER(8,2),
  QUANTITY_5            NUMBER(8,3),
  PRICE_6               NUMBER(8,2),
  QUANTITY_6            NUMBER(8,3),
  PRICE_7               NUMBER(8,2),
  QUANTITY_7            NUMBER(8,3),
  PRICE_8               NUMBER(8,2),
  QUANTITY_8            NUMBER(8,3),
  PRICE_9               NUMBER(8,2),
  QUANTITY_9            NUMBER(8,3),
  PRICE_10              NUMBER(8,2),
  QUANTITY_10           NUMBER(8,3),
  STARTUP_COST_HOT      NUMBER(8,2),
  STARTUP_COST_WARM     NUMBER(8,2),
  STARTUP_COST_COLD     NUMBER(8,2),
  NO_LOAD_COST          NUMBER(8,2),
  TARGET_RESV_LEVEL_MWH NUMBER(8,3),
  PUMP_STORAGE_CYC_EFY  NUMBER(7,4),
  SHUTDOWN_COST         NUMBER(8,2),
  GEN_EVENT_ID          NUMBER(9),
  DEM_EVENT_ID          NUMBER(9)
)
;
alter table SEM_COMM_OFFER_STD_UNITS
  add constraint PK_SEM_CO_STD_UNITS primary key (POD_ID, SCHEDULE_DATE, SCHEDULE_TYPE);
alter table SEM_COMM_OFFER_STD_UNITS
  add constraint FK_SEM_CO_STD_UNITS_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_METER_DETAILS_PUB
(
  PSE_ID                  NUMBER(9) not null,
  POD_ID                  NUMBER(9) not null,
  SCHEDULE_DATE           DATE not null,
  RESOURCE_TYPE           VARCHAR2(4),
  JURISDICTION            VARCHAR2(4),
  METERED_MW              NUMBER(8,3),
  METER_TRANSMISSION_TYPE VARCHAR2(4),
  EVENT_ID                NUMBER(9)
)
;
alter table SEM_METER_DETAILS_PUB
  add constraint PK_SEM_MTR_DETS_PUB primary key (PSE_ID, POD_ID, SCHEDULE_DATE);
alter table SEM_METER_DETAILS_PUB
  add constraint FK_SEM_MTR_DETS_PUB_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_METER_DETAILS_PUB
  add constraint FK_SEM_MTR_DETS_PUB_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_MKT_SCHED_DETAIL_PUB
(
  SCHEDULE_DATE          DATE not null,
  POD_ID                 NUMBER(9) not null,
  SCHEDULE_TYPE          NUMBER(9) not null,
  GATE_WINDOW_ID         NUMBER(9) not null,
  PSE_ID                 NUMBER(9) not null,  
  RESOURCE_TYPE          VARCHAR2(4),
  SCHEDULE_QUANTITY      NUMBER(8,3),
  MAXIMUM_AVAILABILITY   NUMBER(8,3),
  MINIMUM_GENERATION     NUMBER(8,3),
  MINIMUM_OUTPUT         NUMBER(8,3),
  ACTUAL_AVAILABILITY    NUMBER(8,3),
  EX_ANTE_EVENT_ID       NUMBER(9),
  INDICATIVE_EVENT_ID    NUMBER(9),
  INITIAL_EVENT_ID       NUMBER(9)
)
;
alter table SEM_MKT_SCHED_DETAIL_PUB
  add constraint PK_SEM_MKT_SCHED_DETAIL_PUB primary key (SCHEDULE_DATE, POD_ID, SCHEDULE_TYPE, GATE_WINDOW_ID);
alter table SEM_MKT_SCHED_DETAIL_PUB
  add constraint FK_SEM_MKT_SCHED_DETAIL_P_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_MKT_SCHED_DETAIL_PUB
  add constraint FK_SEM_MKT_SCHED_DTL_PUB_STMT foreign key (SCHEDULE_TYPE) 
  references STATEMENT_TYPE (STATEMENT_TYPE_ID) on delete cascade;
alter table SEM_MKT_SCHED_DETAIL_PUB
  add constraint FK_SEM_MKT_SCHED_DTL_PUB_GATE foreign key (GATE_WINDOW_ID) 
  references STATEMENT_TYPE (STATEMENT_TYPE_ID) on delete cascade;
alter table SEM_MKT_SCHED_DETAIL_PUB
  add constraint FK_SEM_MKT_SCHED_DETAIL_P_PSE foreign key (PSE_ID)
  references PSE (PSE_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_NOM_PROFILE
(
  POD_ID             NUMBER(9) not null,
  SCHEDULE_DATE      DATE not null,
  RUN_TYPE           VARCHAR2(4) not null,
  RESOURCE_TYPE      VARCHAR2(4),
  JURISDICTION       VARCHAR2(4),
  UNDER_TEST_YN      VARCHAR2(1),
  NOMINATED_QUANTITY NUMBER(8,3),
  DECREMENTAL_PRICE  NUMBER(8,2),
  GEN_EVENT_ID       NUMBER(9),
  DEM_EVENT_ID       NUMBER(9)
)
;
alter table SEM_NOM_PROFILE
  add constraint PK_SEM_NOM_PROFILE primary key (POD_ID, SCHEDULE_DATE, RUN_TYPE);
alter table SEM_NOM_PROFILE
  add constraint FK_SEM_NOM_PROFILE_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_OPS_SCHEDULE
(
  PSE_ID        NUMBER(9) not null,
  POD_ID        NUMBER(9) not null,
  SCHEDULE_DATE DATE not null,
  JURISDICTION  VARCHAR2(4),
  SCHEDULE_MW   NUMBER(8,3),
  POST_TIME     DATE,
  EVENT_ID      NUMBER(9)
)
;
alter table SEM_OPS_SCHEDULE
  add constraint PK_SEM_OPS_SCHEDULE primary key (PSE_ID, POD_ID, SCHEDULE_DATE);
alter table SEM_OPS_SCHEDULE
  add constraint FK_SEM_OPS_SCHEDULE_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_OPS_SCHEDULE
  add constraint FK_SEM_OPS_SCHEDULE_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_TECH_CHAR_EN_LTD
(
  PSE_ID                  NUMBER(9) not null,
  POD_ID                  NUMBER(9) not null,
  SCHEDULE_DATE           DATE not null,
  RESOURCE_TYPE           VARCHAR2(4),
  REDECLARED_ENERGY_LIMIT NUMBER(8,3),
  EVENT_ID                NUMBER(9)
)
;
alter table SEM_TECH_CHAR_EN_LTD
  add constraint PK_SEM_TECH_CHAR_EN_LTD primary key (PSE_ID, POD_ID, SCHEDULE_DATE);
alter table SEM_TECH_CHAR_EN_LTD
  add constraint FK_SEM_TECH_CHAR_EN_LTD_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_TECH_CHAR_EN_LTD
  add constraint FK_SEM_TECH_CHAR_EN_LTD_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_TECH_OFFER_FORECAST
(
  POD_ID                      NUMBER(9) not null,
  SCHEDULE_DATE               DATE not null,
  RUN_TYPE                    VARCHAR2(4) not null,
  RESOURCE_TYPE               VARCHAR2(4),
  JURISDICTION                VARCHAR2(4),
  UNDER_TEST_YN               VARCHAR2(1),
  FORECAST_AVAILABILITY       NUMBER(8,3),
  FORECAST_MINIMUM_STABLE_GEN NUMBER(8,3),
  FORECAST_MINIMUM_OUTPUT     NUMBER(8,3),
  EVENT_ID                    NUMBER(9)
)
;
alter table SEM_TECH_OFFER_FORECAST
  add constraint PK_SEM_TO_FORECAST primary key (POD_ID, SCHEDULE_DATE, RUN_TYPE);
alter table SEM_TECH_OFFER_FORECAST
  add constraint FK_SEM_TO_FORECAST_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;

-------------------------------------------------------------------------

create table SEM_TECH_OFFER_STD_UNITS
(
  POD_ID                         NUMBER(9) not null,
  SCHEDULE_DATE                  DATE not null,
  STATEMENT_TYPE_ID              NUMBER(9) not null,
  RESOURCE_TYPE                  VARCHAR2(4),
  JURISDICTION                   VARCHAR2(4),
  FUEL_TYPE                      VARCHAR2(5),
  PRIORITY_DISPATCH_YN           VARCHAR2(1),
  PUMP_STORAGE_YN                VARCHAR2(1),
  ENERGY_LIMIT_YN                VARCHAR2(1),
  UNDER_TEST_YN                  VARCHAR2(1),
  FIRM_ACCESS_QUANTITY           NUMBER(8,3),
  NON_FIRM_ACC_QUANTITY          NUMBER(8,3),
  SHORT_TERM_MAXIMISATION_CAP    NUMBER(8,3),
  MINIMUM_GENERATION             NUMBER(15,3),
  MAXIMUM_GENERATION             NUMBER(15,3),
  MINIMUM_ON_TIME                NUMBER(15,3),
  MINIMUM_OFF_TIME               NUMBER(15,3),
  MAXIMUM_ON_TIME                NUMBER(15,3),
  HOT_COOLING_BOUNDARY           NUMBER(8,2),
  WARM_COOLING_BOUNDARY          NUMBER(8,2),
  SYNCHRONOUS_START_UP_TIME_HOT  NUMBER(8,2),
  SYNCHRONOUS_START_UP_TIME_WARM NUMBER(8,2),
  SYNCHRONOUS_START_UP_TIME_COLD NUMBER(8,2),
  BLOCK_LOAD_COLD                NUMBER(15,3),
  BLOCK_LOAD_HOT                 NUMBER(15,3),
  BLOCK_LOAD_WARM                NUMBER(15,3),
  LOADING_RATE_COLD_1            NUMBER(15,3),
  LOADING_RATE_COLD_2            NUMBER(15,3),
  LOADING_RATE_COLD_3            NUMBER(15,3),
  LOAD_UP_BREAK_POINT_COLD_1     NUMBER(15,3),
  LOAD_UP_BREAK_POINT_COLD_2     NUMBER(15,3),
  LOADING_RATE_HOT_1             NUMBER(15,3),
  LOADING_RATE_HOT_2             NUMBER(15,3),
  LOADING_RATE_HOT_3             NUMBER(15,3),
  LOAD_UP_BREAK_POINT_HOT_1      NUMBER(15,3),
  LOAD_UP_BREAK_POINT_HOT_2      NUMBER(15,3),
  LOADING_RATE_WARM_1            NUMBER(15,3),
  LOADING_RATE_WARM_2            NUMBER(15,3),
  LOADING_RATE_WARM_3            NUMBER(15,3),
  LOAD_UP_BREAK_POINT_WARM_1     NUMBER(15,3),
  LOAD_UP_BREAK_POINT_WARM_2     NUMBER(15,3),
  SOAK_TIME_COLD_1               NUMBER(8,2),
  SOAK_TIME_COLD_2               NUMBER(8,2),
  SOAK_TIME_TRIGGER_POINT_COLD_1 NUMBER(15,3),
  SOAK_TIME_TRIGGER_POINT_COLD_2 NUMBER(15,3),
  SOAK_TIME_HOT_1                NUMBER(8,2),
  SOAK_TIME_HOT_2                NUMBER(8,2),
  SOAK_TIME_TRIGGER_POINT_HOT_1  NUMBER(15,3),
  SOAK_TIME_TRIGGER_POINT_HOT_2  NUMBER(15,3),
  SOAK_TIME_WARM_1               NUMBER(8,2),
  SOAK_TIME_WARM_2               NUMBER(8,2),
  SOAK_TIME_TRIGGER_POINT_WARM_1 NUMBER(15,3),
  SOAK_TIME_TRIGGER_POINT_WARM_2 NUMBER(15,3),
  END_POINT_OF_START_UP_PERIOD   NUMBER(15,3),
  RAMP_UP_RATE_1                 NUMBER(15,3),
  RAMP_UP_RATE_2                 NUMBER(15,3),
  RAMP_UP_RATE_3                 NUMBER(15,3),
  RAMP_UP_RATE_4                 NUMBER(15,3),
  RAMP_UP_RATE_5                 NUMBER(15,3),
  RAMP_UP_BREAK_POINT_1          NUMBER(15,3),
  RAMP_UP_BREAK_POINT_2          NUMBER(15,3),
  RAMP_UP_BREAK_POINT_3          NUMBER(15,3),
  RAMP_UP_BREAK_POINT_4          NUMBER(15,3),
  DWELL_TIME_1                   NUMBER(8,2),
  DWELL_TIME_2                   NUMBER(8,2),
  DWELL_TIME_3                   NUMBER(8,2),
  DWELL_TIME_TRIGGER_POINT_1     NUMBER,
  DWELL_TIME_TRIGGER_POINT_2     NUMBER,
  DWELL_TIME_TRIGGER_POINT_3     NUMBER,
  DWELL_TIME_DOWN_1              NUMBER,
  DWELL_TIME_DOWN_2              NUMBER,
  DWELL_TIME_DOWN_3              NUMBER,
  DWELL_TIME_DOWN_TRIGGER_PT_1   NUMBER,
  DWELL_TIME_DOWN_TRIGGER_PT_2   NUMBER,
  DWELL_TIME_DOWN_TRIGGER_PT_3   NUMBER,
  RAMP_DOWN_RATE_1               NUMBER(15,3),
  RAMP_DOWN_RATE_2               NUMBER(15,3),
  RAMP_DOWN_RATE_3               NUMBER(15,3),
  RAMP_DOWN_RATE_4               NUMBER(15,3),
  RAMP_DOWN_RATE_5               NUMBER(15,3),
  RAMP_DOWN_BREAK_POINT_1        NUMBER(15,3),
  RAMP_DOWN_BREAK_POINT_2        NUMBER(15,3),
  RAMP_DOWN_BREAK_POINT_3        NUMBER(15,3),
  RAMP_DOWN_BREAK_POINT_4        NUMBER(15,3),
  DELOADING_RATE_1               NUMBER(15,3),
  DELOADING_RATE_2               NUMBER(15,3),
  DELOAD_BREAK_POINT             NUMBER(15,3),
  MAXIMUM_STORAGE_CAPACITY       NUMBER(15,3),
  MINIMUM_STORAGE_CAPACITY       NUMBER(15,3),
  PUMPING_LOAD_CAP               NUMBER(15,3),
  TARGET_RESERVOIR_LEVEL_PERCENT NUMBER(8,2),
  ENERGY_LIMIT_MWH               NUMBER(8,3),
  ENERGY_LIMIT_FACTOR            NUMBER(4,3),
  FIXED_UNIT_LOAD                NUMBER(15,3),
  UNIT_LOAD_SCALAR               NUMBER(5,4),
  MAXIMUM_RAMP_UP_RATE           NUMBER(15,3),
  MAXIMUM_RAMP_DOWN_RATE         NUMBER(15,3),
  MINIMUM_DOWN_TIME              NUMBER(15,3),
  MAXIMUM_DOWN_TIME              NUMBER(15,3),
  GEN_EVENT_ID                   NUMBER(9),
  DEM_EVENT_ID                   NUMBER(9)
)
;
alter table SEM_TECH_OFFER_STD_UNITS
  add constraint PK_SEM_TO_STD_UNITS primary key (POD_ID, SCHEDULE_DATE, STATEMENT_TYPE_ID);
alter table SEM_TECH_OFFER_STD_UNITS
  add constraint FK_SEM_TO_STD_UNITS_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_TECH_OFFER_STD_UNITS
  add constraint FK_SEM_TO_STD_UNITS_STMT foreign key (STATEMENT_TYPE_ID)
  references STATEMENT_TYPE (STATEMENT_TYPE_ID)
  on delete cascade;
-------------------------------------------------------------------------

create table SEM_ACTUAL_SCHEDULES
(
  SCHEDULE_DATE          DATE not null,
  POD_ID                 NUMBER(9) not null,
  SCHEDULE_TYPE          NUMBER(9) not null,
  RESOURCE_TYPE          VARCHAR2(4),
  JURISDICTION           VARCHAR2(4),
  SCHEDULE_MW            NUMBER(8,3),
  POST_TIME              DATE not null,
  INDIC_ACT_EVENT_ID     NUMBER(9),
  WITHIN_DAY_EVENT_ID    NUMBER(9)
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
alter table SEM_ACTUAL_SCHEDULES
  add constraint PK_SEM_ACTUAL_SCHED primary key (SCHEDULE_DATE, POD_ID, SCHEDULE_TYPE, POST_TIME)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_ACTUAL_SCHEDULES
  add constraint FK_SEM_ACTUAL_SCHED_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;

-- Create table
create table SEM_GP_SETTLEMENT
(
  STATEMENT_TYPE NUMBER(9) not null,
  CHARGE_DATE    DATE not null,
  REPORT_TYPE    VARCHAR2(32) not null,
  MARKET         VARCHAR2(32) not null,
  RESOURCE_NAME  VARCHAR2(100) not null,
  JURISDICTION   VARCHAR2(100) not null,
  VARIABLE_TYPE  VARCHAR2(24) not null,
  VARIABLE_NAME  VARCHAR2(156) not null,
  RESOLUTION     NUMBER(2) not null,
  UNIT           VARCHAR2(18),
  VALUE          NUMBER(36,8)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 3M
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_GP_SETTLEMENT
  add constraint PK_SEM_GP_SETTLEMENT primary key (STATEMENT_TYPE, CHARGE_DATE, REPORT_TYPE, MARKET, RESOURCE_NAME, JURISDICTION, VARIABLE_TYPE, VARIABLE_NAME, RESOLUTION)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );


create index SEM_GP_SETTLEMENT_IX01 on SEM_GP_SETTLEMENT( STATEMENT_TYPE, TRUNC(CHARGE_DATE), MARKET, VARIABLE_TYPE, JURISDICTION )
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );


alter table SEM_GP_SETTLEMENT
  add constraint FK_SEM_GP_SETTLEMENT_STMNT_ID foreign key (STATEMENT_TYPE)
  references STATEMENT_TYPE (STATEMENT_TYPE_ID) on delete cascade;

-- Create table
create global temporary table SEM_GP_SETTLEMENT_D_TEMP
(
  WORK_ID       NUMBER(9) not null,
  DELIVERY_DATE DATE not null,
  DELIVERY_HOUR NUMBER(2) not null,
  RESOLUTION    NUMBER(2) not null,
  RESOURCE_NAME VARCHAR2(100) not null,
  JURISDICTION  VARCHAR2(100) not null,
  VARIABLE_TYPE VARCHAR2(24) not null,
  VARIABLE_NAME VARCHAR2(156) not null,
  UNIT          VARCHAR2(18),
  VALUE1        NUMBER(28,8),
  VALUE2        NUMBER(28,8)
)
on commit preserve rows;
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_GP_SETTLEMENT_D_TEMP
  add constraint PK_SEM_GP_SETTLEMENT_D_TEMP primary key (WORK_ID, DELIVERY_DATE, DELIVERY_HOUR, RESOLUTION, VARIABLE_TYPE, VARIABLE_NAME, RESOURCE_NAME, JURISDICTION);

-- Create table
create global temporary table SEM_GP_SETTLEMENT_H_TEMP
(
  WORK_ID        NUMBER(9) not null,
  FILE_VERSION   VARCHAR2(3),
  REP_TIMESTAMP  DATE,
  STATEMENT_TYPE VARCHAR2(1),
  SETTLEMENT_DAY DATE
)
on commit preserve rows;
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_GP_SETTLEMENT_H_TEMP
  add constraint PK_SEM_GP_SETTLEMENT_H_TEMP primary key (WORK_ID);


-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_DAILY_STMT (
   ASSESSMENT_DATE               DATE not null,
   STATEMENT_TYPE_ID             NUMBER(9) not null,
   PSE_ID                        NUMBER(9) not null,
   CREDIT_MARKET                 VARCHAR2(3) not null,
   CREDIT_CATEGORY               VARCHAR2(32) not null,
   STATEMENT_DATE                DATE not null,
   ENTITY_ID                     NUMBER(9) not null,
   BEST_STATEMENT_TYPE           NUMBER(9) not null,
   BEST_STATEMENT_STATE          NUMBER(1) not null,
   BILL_AMOUNT                   NUMBER,
   NATIVE_CURRENCY               VARCHAR2(3) not null,
   EXCHANGE_RATE_POUND_TO_EURO   NUMBER,
   EURO_BILL_AMOUNT              NUMBER,
   VMOP                          NUMBER,
   NDLF                          NUMBER,
   constraint PK_SEM_CREDIT_DAILY_STMT primary key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET, CREDIT_CATEGORY, STATEMENT_DATE, ENTITY_ID)
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
	  
alter table SEM_CREDIT_DAILY_STMT
	add constraint FK_SEM_CREDIT_DAILY_STMT_CALC foreign key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		references SEM_CREDIT_CALC_PSE (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		on delete cascade;
		
-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_DAILY_SRA (
   ASSESSMENT_DATE               DATE not null,
   STATEMENT_TYPE_ID             NUMBER(9) not null,
   PSE_ID                        NUMBER(9) not null,
   CREDIT_MARKET                 VARCHAR2(3) not null,
   CREDIT_CATEGORY               VARCHAR2(32) not null,
   STATEMENT_DATE                DATE not null,
   TRANSACTION_ID                NUMBER(9) not null,
   IS_ACCEPTED                   NUMBER(1) not null,
   RAW_SRA_AMOUNT                NUMBER,
   NATIVE_CURRENCY               VARCHAR2(3) not null,
   EXCHANGE_RATE				 NUMBER,
   SRA_AMOUNT                    NUMBER,
   constraint PK_SEM_CREDIT_DAILY_SRA primary key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET, CREDIT_CATEGORY, STATEMENT_DATE, TRANSACTION_ID)
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
	  
alter table SEM_CREDIT_DAILY_SRA
	add constraint FK_SEM_CREDIT_DAILY_SRA_CALC foreign key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		references SEM_CREDIT_CALC_PSE (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		on delete cascade;
		
-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_DAILY_UNDEF_ADJ (
   ASSESSMENT_DATE               DATE not null,
   STATEMENT_TYPE_ID             NUMBER(9) not null,
   PSE_ID                        NUMBER(9) not null,
   CREDIT_MARKET                 VARCHAR2(3) not null,
   STATEMENT_DATE                DATE not null,
   FORECAST_VOLUME               NUMBER,
   CAPACITY_ADJ_FACTOR           NUMBER,
   ASSESSMENT_PRICE              NUMBER,
   VAT_RATE                      NUMBER,
   constraint PK_SEM_CREDIT_DAILY_UNDEF_ADJ primary key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET, STATEMENT_DATE)
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
	  
alter table SEM_CREDIT_DAILY_UNDEF_ADJ
	add constraint FK_SEM_CREDIT_DAILY_UA_CALC foreign key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		references SEM_CREDIT_CALC_PSE (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		on delete cascade;

-------------------------------------------------------------------------

CREATE TABLE SEM_CREDIT_DAILY_UNDEF_STD (
   ASSESSMENT_DATE               DATE not null,
   STATEMENT_TYPE_ID             NUMBER(9) not null,
   PSE_ID                        NUMBER(9) not null,
   CREDIT_MARKET                 VARCHAR2(3) not null,
   SAMPLE_BEGIN_DATE             DATE not null,
   SAMPLE_END_DATE               DATE not null,
   SAMPLE_AMOUNT                 NUMBER,
   constraint PK_SEM_CREDIT_DAILY_UNDEF_STD primary key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET, SAMPLE_BEGIN_DATE)
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
	  
alter table SEM_CREDIT_DAILY_UNDEF_STD
	add constraint FK_SEM_CREDIT_DAILY_US_CALC foreign key (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		references SEM_CREDIT_CALC_PSE (ASSESSMENT_DATE, STATEMENT_TYPE_ID, PSE_ID, CREDIT_MARKET)
		on delete cascade;

-------------------------------------------------------------------------
create table SEM_GEN_FORECAST_AGG
(
  SCHEDULE_DATE DATE not null,
  PERIODICITY   VARCHAR2(2) not null,
  JURISDICTION  VARCHAR2(4) not null,
  FORECAST_MW   NUMBER(8,3),
  ASSUMPTIONS   VARCHAR2(128),
  EVENT_ID      NUMBER(9)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 192K
    minextents 1
    maxextents unlimited
  );
-- Add comments to the columns 
comment on column SEM_GEN_FORECAST_AGG.PERIODICITY
  is 'D1, D2, D3, D4 for (D+1), (D+2), (D+3), (D+4) respectively.';
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_GEN_FORECAST_AGG
  add constraint PK_SEM_GEN_FORECAST_AGG primary key (SCHEDULE_DATE, PERIODICITY, JURISDICTION)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 192K
    minextents 1
    maxextents unlimited
  );

-------------------------------------------------------------------------
create table SEM_TECH_CHAR_GEN
(
  PSE_ID                     NUMBER(9) not null,
  POD_ID                     NUMBER(9) not null,
  SCHEDULE_DATE              DATE not null,
  GMT_OFFSET                 NUMBER(2) not null,
  EFF_TIME                   DATE not null,
  ISSUE_TIME                 DATE not null,
  RESOURCE_TYPE              VARCHAR2(4),
  OUTTURN_AVAILABILITY       NUMBER(8,3),
  OUTTURN_MINIMUM_STABLE_GEN NUMBER(8,3),
  OUTTURN_MINIMUM_OUTPUT     NUMBER(8,3),
  EVENT_ID                   NUMBER(9)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 448K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_TECH_CHAR_GEN
  add constraint PK_SEM_TECH_CHAR_GEN primary key (PSE_ID, POD_ID, SCHEDULE_DATE, GMT_OFFSET, EFF_TIME, ISSUE_TIME)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_TECH_CHAR_GEN
  add constraint FK_SEM_TECH_CHAR_GEN_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_TECH_CHAR_GEN
  add constraint FK_SEM_TECH_CHAR_GEN_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;

-------------------------------------------------------------------------
create table SEM_SO_TRADES
(
  POD_ID                   NUMBER(9) not null,
  SCHEDULE_DATE            DATE not null,
  SO_INTERCON_IMP_PRICE    NUMBER(8,2),
  SO_INTERCON_IMP_QUANTITY NUMBER(8,3),
  SO_INTERCON_EXP_PRICE    NUMBER(8,2),
  SO_INTERCON_EXP_QUANTITY NUMBER(8,3),
  EVENT_ID                 NUMBER(9)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 448K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_SO_TRADES
  add constraint PK_SEM_SO_TRADES primary key (POD_ID, SCHEDULE_DATE)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_SO_TRADES
  add constraint FK_SEM_SO_TRADES_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;

-------------------------------------------------------------------------
create table SEM_IC_OFFER_CAPACITY
(
  POD_ID                   NUMBER(9) not null,
  SCHEDULE_DATE            DATE not null,
  RUN_TYPE				   VARCHAR2(3) not null,
  AIC   				   NUMBER(8,3),
  OICE 					   NUMBER(8,3),
  OICI    				   NUMBER(8,3),
  MAX_EXPORT_ATC           NUMBER(8,3),
  MAX_IMPORT_ATC           NUMBER(8,3),
  EVENT_ID                 NUMBER(9)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 448K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_IC_OFFER_CAPACITY
  add constraint PK_SEM_IC_OFFER_CAPACITY primary key (POD_ID, SCHEDULE_DATE, RUN_TYPE)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_IC_OFFER_CAPACITY
  add constraint FK_SEM_IC_OFFER_CAPACITY_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;

-- Create table
create table SEM_IC_NOMINATIONS
(
  SCHEDULE_DATE   DATE not null,
  PSE_ID          NUMBER(9) not null,
  POD_ID          NUMBER(9) not null,
  RUN_TYPE		  VARCHAR2(4) NOT NULL,
  GATE_WINDOW	  VARCHAR2(4) NOT NULL,
  UNIT_NOMINATION NUMBER(8,3),
  EVENT_ID        NUMBER(9)
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
-- Add comments to the columns 
comment on column SEM_IC_NOMINATIONS.PSE_ID
  is 'Foreign key to the PURCHASE_SELLING_ENTITY table';
comment on column SEM_IC_NOMINATIONS.POD_ID
  is 'Foreign key to the SERVICE_POINT table';
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_IC_NOMINATIONS
  add constraint PK_SEM_IC_NOMS primary key (SCHEDULE_DATE, PSE_ID, POD_ID, RUN_TYPE, GATE_WINDOW)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_IC_NOMINATIONS
  add constraint FK_SEM_IC_NOMS_POD foreign key (POD_ID)
  references SERVICE_POINT (SERVICE_POINT_ID) on delete cascade;
alter table SEM_IC_NOMINATIONS
  add constraint FK_SEM_IC_NOMS_PSE foreign key (PSE_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade;
  
----------------------------------------------------------------------------
create table SEM_SCHEDULE_TEMPLATE
(
  TEMPLATE_NAME    VARCHAR2(64) not null,
  START_INTERVAL_END   NUMBER(2),
  STOP_INTERVAL_END    NUMBER(2),
  INTERIOR_PERIOD  NUMBER(1),
  DAY_OF_WEEK      CHAR(7),
  INCLUDE_HOLIDAYS NUMBER(1),
  TEMPLATE_ORDER   NUMBER(3)
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_SCHEDULE_TEMPLATE
  add constraint PK_SEM_SCHEDULE_TEMPLATE primary key (TEMPLATE_NAME)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
----------------------------------------------------------------------------
-- Create table
create table MM_CFD_ESTSEM_COEFF
(
  PRODUCT       VARCHAR2(32) not null,
  SCHEDULE_DATE DATE not null,
  ALPHA         NUMBER(16,6),
  BETA          NUMBER(16,6),
  GAMMA         NUMBER(16,6),
  DELTA         NUMBER(16,6),
  EPSILON       NUMBER(16,6),
  ZETA          NUMBER(16,6),
  ETA          NUMBER(16,6),
  PI           NUMBER(16,6)
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table MM_CFD_ESTSEM_COEFF
  add constraint PK_MM_CFD_ESTSEM_COEFF primary key (PRODUCT, SCHEDULE_DATE)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
----------------------------------------------------------------------------
CREATE TABLE SEM_SRA_FORECAST_CONFIG(
	PERIOD_NAME                 VARCHAR2(32) not null,
	CREDIT_MARKET               VARCHAR2(3) not null,
	SORT_ORDER                  NUMBER(3),
	MULTIPLIER                  NUMBER,
	DAYS_UNTIL_POSTED           NUMBER(4),
	DAY_TYPE                    VARCHAR2(2),
	IS_RELATIVE_TO_PERIOD_BEGIN NUMBER(1),
   constraint PK_SEM_SRA_FORECAST_CONFIG primary key (PERIOD_NAME, CREDIT_MARKET)
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
----------------------------------------------------------------------------
-- Create table
create table SEM_SETTLEMENT_TOLERANCE
(
  PSE_ID                   NUMBER not null,
  COMPARISON_ITEM          VARCHAR2(64) not null,
  STATEMENT_TYPE1_ID       NUMBER(9) not null,
  STATEMENT_STATE1_ID      NUMBER(1) not null,
  STATEMENT_TYPE2_ID       NUMBER(9) not null,
  STATEMENT_STATE2_ID      NUMBER(1) not null,
  ABSOLUTE_ERROR_TOLERANCE NUMBER,
  RELATIVE_ERROR_TOLERANCE NUMBER
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_SETTLEMENT_TOLERANCE
  add constraint PK_SEM_SETTLEMENT_TOLERANCE primary key (PSE_ID, COMPARISON_ITEM, STATEMENT_TYPE1_ID, STATEMENT_TYPE2_ID, STATEMENT_STATE1_ID, STATEMENT_STATE2_ID)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
----------------------------------------------------------------------------
CREATE TABLE SEM_CFD_ESTSEM_DAILY(
	ASSESSMENT_DATE DATE not null,
	PRODUCT         VARCHAR(32) not null,
	PRICE_MONTH     DATE not null,
	CURRENCY        VARCHAR2(8) not null,
	CUT_BEGIN_DATE  DATE,
	CUT_END_DATE    DATE,
	ESTSEM        NUMBER(16,6),
	ALPHA         NUMBER(16,6),
	BETA          NUMBER(16,6),
	GAMMA         NUMBER(16,6),
	DELTA         NUMBER(16,6),
	EPSILON       NUMBER(16,6),
	ZETA          NUMBER(16,6),
	ETA           NUMBER(16,6),
	PI            NUMBER(16,6),
	NAT_GAS       NUMBER(16,6),
	LOW_SULPHUR_FUEL NUMBER(16,6),
    GASOIL_FRONTLINE NUMBER(16,6),
    GASOIL_CARGO     NUMBER(16,6),
	CARBON        NUMBER(16,6),
constraint PK_SEM_CFD_ESTSEM_DAILY primary key (ASSESSMENT_DATE, PRODUCT, PRICE_MONTH, CURRENCY)
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
----------------------------------------------------------------------------
CREATE TABLE SEM_CFD_CONTRACT(
	CONTRACT_ID                 NUMBER(9),
	CURRENCY                    VARCHAR2(8),
	JURISDICTION                VARCHAR2(8),
	EXECUTION_DATE              DATE,
	HEDGE_TYPE                  VARCHAR2(16),
	WD_TO_INVOICE               NUMBER(4),
	WD_TO_PAY                   NUMBER(4),
	RECEIVABLES_CUTOFF_OPTION   VARCHAR2(32),
	WD_TO_RECEIVABLES_CUTOFF    NUMBER(4),
	CREDIT_COVER_REGIME         VARCHAR2(32),
	CREATE_DATE                 DATE,
	LAST_UPDATE_DATE            DATE,
	LAST_UPDATED_BY             VARCHAR2(64),
constraint PK_SEM_CFD_CONTRACT primary key (CONTRACT_ID)
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

ALTER TABLE SEM_CFD_CONTRACT
   ADD CONSTRAINT FK_SEM_CFD_CONTRACT_CON_ID FOREIGN KEY (CONTRACT_ID)
      REFERENCES INTERCHANGE_CONTRACT (CONTRACT_ID)
      ON DELETE CASCADE;
----------------------------------------------------------------------------
create global temporary table SEM_M2M_DETAILS_TEMP
(
  TRANSACTION_ID          NUMBER(9) not null,
  TRANSACTION_NAME        VARCHAR2(64) not null,
  PRODUCT                 VARCHAR2(32),
  CONTRACT_ID             NUMBER(9) not null,
  CONTRACT_NAME           VARCHAR2(32) not null,
  CONTRACT_TYPE           VARCHAR2(32),
  CONTRACT_AGREEMENT_TYPE VARCHAR2(32),
  PURCHASER_ID            NUMBER(9),
  SELLER_ID               NUMBER(9),
  PURCHASER_NAME          VARCHAR2(64),
  SELLER_NAME             VARCHAR2(64),
  CURRENCY                CHAR(3),
  SCHEDULE_DATE           DATE not null,
  AMOUNT                  NUMBER(10,3),
  STRIKE_PRICE            NUMBER(10,3),
  M2M_INDEX_VALUE         NUMBER(16,6),
  VAT                     NUMBER,
  Z_SIGN                  NUMBER,
  LOCAL_DAY_TRUNC_DATE    DATE,
  LOCAL_MONTH_TRUNC_DATE  DATE,
  STATEMENT_MONTH_STR     VARCHAR2(10),
  MONTH_NAME              VARCHAR2(14),
  SELLER_PAYS             NUMBER(1),
  BUYER_PAYS              NUMBER(1),
  EFFECTIVE_RATE          NUMBER,
  M2M_VALUATION           NUMBER,
  M2M_VAT                 NUMBER
)
on commit preserve rows;
-- Create/Recreate indexes 
create index SEM_M2M_DETAILS_TEMP_IX01 on SEM_M2M_DETAILS_TEMP (TRANSACTION_ID);
----------------------------------------------------------------------------
CREATE TABLE SEM_CFD_DEAL(
	TRANSACTION_ID              NUMBER(9),
	DIFF_PMT_INDEX_MP_ID        NUMBER(9),
	DIFF_PMT_SPARE_NUM_1        NUMBER,
	DIFF_PMT_SPARE_NUM_2        NUMBER,
	DIFF_PMT_SPARE_STR          VARCHAR2(32),
	DIFF_PMT_VAT_TXN_ID         NUMBER(9),
	CC_VAT_TXN_ID               NUMBER(9),
	CC_PI_MP_ID                 NUMBER(9),
	CC_PERCENTAGE               NUMBER,
	CC_INDEX_MP_ID              NUMBER(9),
	M2M_INDEX_MP_ID             NUMBER(9),
  	EXECUTION_DATE              DATE,
  	TRADER                      VARCHAR2(128),
  	ADDITIONAL_AUTHORISER       VARCHAR2(128),
	NETTING_AGREEMENT_PERCENTAGE NUMBER,
	CREATE_DATE                 DATE,
	LAST_UPDATE_DATE            DATE,
	LAST_UPDATED_BY             VARCHAR2(64),
constraint PK_SEM_CFD_DEAL primary key (TRANSACTION_ID)
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

ALTER TABLE SEM_CFD_DEAL
   ADD CONSTRAINT FK_SEM_CFD_CONTRACT_PRC1_ID FOREIGN KEY (DIFF_PMT_INDEX_MP_ID)
      REFERENCES MARKET_PRICE (MARKET_PRICE_ID)
      ON DELETE SET NULL;

ALTER TABLE SEM_CFD_DEAL
   ADD CONSTRAINT FK_SEM_CFD_CONTRACT_PRC2_ID FOREIGN KEY (CC_PI_MP_ID)
      REFERENCES MARKET_PRICE (MARKET_PRICE_ID)
      ON DELETE SET NULL;

ALTER TABLE SEM_CFD_DEAL
   ADD CONSTRAINT FK_SEM_CFD_CONTRACT_PRC3_ID FOREIGN KEY (CC_INDEX_MP_ID)
      REFERENCES MARKET_PRICE (MARKET_PRICE_ID)
      ON DELETE SET NULL;
	  
ALTER TABLE SEM_CFD_DEAL
	ADD CONSTRAINT FK_SEM_CFD_CONTRACT_PRC4_ID FOREIGN KEY (M2M_INDEX_MP_ID)
	REFERENCES MARKET_PRICE (MARKET_PRICE_ID)
	ON DELETE SET NULL;

ALTER TABLE SEM_CFD_DEAL
   ADD CONSTRAINT FK_SEM_CFD_CONTRACT_TXN1_ID FOREIGN KEY (TRANSACTION_ID)
      REFERENCES INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      ON DELETE CASCADE;

ALTER TABLE SEM_CFD_DEAL
   ADD CONSTRAINT FK_SEM_CFD_CONTRACT_TXN2_ID FOREIGN KEY (DIFF_PMT_VAT_TXN_ID)
      REFERENCES INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      ON DELETE SET NULL;
	  
ALTER TABLE SEM_CFD_DEAL
   ADD CONSTRAINT FK_SEM_CFD_CONTRACT_TXN3_ID FOREIGN KEY (CC_VAT_TXN_ID)
      REFERENCES INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      ON DELETE SET NULL;
----------------------------------------------------------------------------
create global temporary table SEM_CFD_DIFF_PMTS_TEMP
(
	TRANSACTION_ID   NUMBER(9) NOT NULL,
	CHARGE_DATE      DATE,
	TRANSACTION_NAME VARCHAR2(64),
	TRANSACTION_ALIAS VARCHAR2(64),
	LOCAL_DATE_STR   VARCHAR2(32),
	LOCAL_MONTH      DATE,
	LOCAL_DAY        DATE,
	LOCAL_TIME       VARCHAR2(8),
	CURRENCY         VARCHAR2(16),
	VAT_RATE         NUMBER,
	CONTRACT_LEVEL   NUMBER,
	SMP              NUMBER,
	STRIKE_PRICE     NUMBER,
	COST_AT_SMP      NUMBER,
	COST_AT_STRIKE_PRICE NUMBER,
	CHARGE_AMOUNT    NUMBER,
	CONTRACT_LEVEL_2 NUMBER,
	SMP_2            NUMBER,
	STRIKE_PRICE_2   NUMBER,
	COST_AT_SMP_2    NUMBER,
	COST_AT_STRIKE_PRICE_2 NUMBER,
	CHARGE_AMOUNT_2  NUMBER
)
on commit preserve rows;
ALTER TABLE SEM_CFD_DIFF_PMTS_TEMP ADD CONSTRAINT PK_SEM_CFD_DIFF_PMTS_TEMP PRIMARY KEY (TRANSACTION_ID, CHARGE_DATE);
----------------------------------------------------------------------------
create global temporary table SEM_CFD_FORWARD_TEMP
(
  TRANSACTION_ID          NUMBER(9) not null,
  TRANSACTION_NAME        VARCHAR2(64) not null,
  PRODUCT                 VARCHAR2(32),
  CONTRACT_ID             NUMBER(9) not null,
  CONTRACT_NAME           VARCHAR2(32) not null,
  CONTRACT_TYPE           VARCHAR2(32),
  CONTRACT_AGREEMENT_TYPE VARCHAR2(32),
  PURCHASER_ID            NUMBER(9),
  SELLER_ID               NUMBER(9),
  PURCHASER_NAME          VARCHAR2(64),
  SELLER_NAME             VARCHAR2(64),
  CURRENCY                CHAR(3),
  SCHEDULE_DATE           DATE not null,
  AMOUNT                  NUMBER(10,3),
  STRIKE_PRICE            NUMBER(10,3),
  ESTSEM                  NUMBER(16,6),
  VAT                     NUMBER,
  Z_SIGN                  NUMBER,
  LOCAL_DAY_TRUNC_DATE    DATE,
  LOCAL_MONTH_TRUNC_DATE  DATE,
  STATEMENT_MONTH_STR     VARCHAR2(10),
  MONTH_NAME              VARCHAR2(14),
  SELLER_PAYS             NUMBER(1),
  BUYER_PAYS              NUMBER(1),
  CC_PI_MP_ID             NUMBER,
  CC_PERCENTAGE           NUMBER,
  CC_INDEX_MP_ID          NUMBER(9),
  ESTSEMM                 NUMBER(16,6),
  CC_PI_VALUE             NUMBER,
  CC_INDEX_VALUE          NUMBER,
  M2M_INDEX_MP_ID         NUMBER(9),
  M2M_INDEX_VALUE         NUMBER,
  NETTING_AGREEMENT_PERCENTAGE NUMBER
)
on commit preserve rows;
-- Create/Recreate indexes 
create index SEM_CFD_FORWARD_TEMP_IX01 on SEM_CFD_FORWARD_TEMP (TRANSACTION_ID);
----------------------------------------------------------------------------
create global temporary table SEM_CFD_CREDIT_TEMP
(
  TRANSACTION_ID                NUMBER(9) not null,
  TRANSACTION_NAME              VARCHAR2(64),
  TRANSACTION_ALIAS             VARCHAR2(64),
  CONTRACT_ID                   NUMBER(9),
  BILLING_ENTITY_ID             NUMBER(9),
  CURRENCY                      VARCHAR2(16),
  AGREEMENT_TYPE                VARCHAR2(32),
  VAT_TXN_ID                    NUMBER(9),
  RECEIVABLES_CUTOFF_OPTION     VARCHAR2(32),
  BILLED_NOT_PAID_BEGIN         DATE,
  BILLED_NOT_PAID_END           DATE,
  CONSUMED_NOT_BILLED_BEGIN     DATE,
  CONSUMED_NOT_BILLED_END       DATE,
  FUTURE_BEGIN                  DATE,
  CUT_BILLED_NOT_PAID_BEGIN     DATE,
  CUT_BILLED_NOT_PAID_END       DATE,
  CUT_CONSUMED_NOT_BILLED_BEGIN DATE,
  CUT_CONSUMED_NOT_BILLED_END   DATE,
  CUT_FUTURE_BEGIN              DATE,
  VAT_RATE                      NUMBER,
  BILLED_NOT_PAID_AMT           NUMBER,
  CONSUMED_NOT_BILLED_AMT       NUMBER,
  DISPUTE_TEXT                  VARCHAR2(4000),
  DISPUTE_REFERENCE_DATE        DATE
)
on commit preserve rows;
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_CFD_CREDIT_TEMP
  add constraint PK_SEM_CFD_CREDIT_TEMP primary key (TRANSACTION_ID);
----------------------------------------------------------------------------
create table SEM_CFD_ADJUSTMENT
(
  ADJUSTMENT_TYPE            VARCHAR2(16) not null,
  TRANSACTION_ID             NUMBER(9) not null,
  REFERENCE_DATE             DATE not null,
  STATEMENT_TYPE_ID          NUMBER(9) not null,
  ADJUSTMENT_STATUS          VARCHAR2(16) not null,
  ADJUSTMENT_CATEGORY        VARCHAR2(16),
  ADJUSTMENT_TEXT            VARCHAR2(4000),
  SUGGESTED_AMOUNT           NUMBER,
  PAYMENT_SHORTFALL_AMOUNT   NUMBER,
  APPLY_SHORTFALL_TO_CC      NUMBER(1) not null,
  APPLY_SUGGESTED_TO_INVOICE NUMBER(1) not null,
  CREATE_DATE                DATE not null,
  LAST_UPDATE_DATE           DATE,
  LAST_UPDATED_BY            VARCHAR2(64) not null
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
-- Create/Recreate indexes 
create unique index SEM_CFD_ADJUSTMENT_UIX01 on SEM_CFD_ADJUSTMENT (ADJUSTMENT_TYPE, TRANSACTION_ID, REFERENCE_DATE, STATEMENT_TYPE_ID)
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
----------------------------------------------------------------------------
create table SEM_CFD_INVOICE
(
  SEM_CFD_INVOICE_ID         NUMBER(9) not null,
  INVOICE_MONTH              DATE not null,
  CONTRACT_ID                NUMBER(9) not null,
  STATEMENT_TYPE_ID          NUMBER(9) not null,
  INVOICE_DATE               DATE,
  INVOICE_NUMBER             VARCHAR2(128),
  PAYMENT_DUE_DATE           DATE,
  CONTRACT_TYPE              VARCHAR2(32),
  CURRENCY                   VARCHAR2(8),
  BILLING_ENTITY_ID           NUMBER(9),
  BILLING_ENTITY_NAME         VARCHAR2(64),
  BILLING_ENTITY_STREET       VARCHAR2(64),
  BILLING_ENTITY_CITY         VARCHAR2(128),
  BILLING_ENTITY_STATE_CODE   VARCHAR2(128),
  BILLING_ENTITY_POSTAL_CODE  VARCHAR2(128),
  BILLING_ENTITY_COUNTRY_CODE VARCHAR2(128),
  BILLING_ENTITY_PHONE_NUMBER VARCHAR2(24),
  BILLING_ENTITY_VAT_NUMBER   VARCHAR2(16),
  COUNTER_PARTY_ID           NUMBER(9),
  COUNTER_PARTY_NAME         VARCHAR2(64),
  COUNTER_PARTY_STREET       VARCHAR2(64),
  COUNTER_PARTY_CITY         VARCHAR2(128),
  COUNTER_PARTY_STATE_CODE   VARCHAR2(128),
  COUNTER_PARTY_POSTAL_CODE  VARCHAR2(128),
  COUNTER_PARTY_COUNTRY_CODE VARCHAR2(128),
  COUNTER_PARTY_VAT_NUMBER   VARCHAR2(16),
  CREATE_DATE                DATE not null,
  LAST_UPDATE_DATE           DATE,
  LAST_UPDATED_BY            VARCHAR2(64) not null
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_CFD_INVOICE
  add constraint PK_CFD_INVOICE primary key (SEM_CFD_INVOICE_ID)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_CFD_INVOICE
  add constraint AK_CONTRACT_ID unique (CONTRACT_ID, INVOICE_MONTH, STATEMENT_TYPE_ID)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
----------------------------------------------------------------------------
create table SEM_CFD_INVOICE_LINE_ITEM
(
  SEM_CFD_INVOICE_ID  NUMBER(9) not null,
  TRANSACTION_ID      NUMBER(9) not null,
  PRODUCT_TYPE        VARCHAR2(32) not null,
  TRADE_NAME          VARCHAR2(64) not null,
  STRIKE_PRICE        NUMBER,
  CONTRACT_LEVEL      NUMBER,
  BD_AVG_SMP          NUMBER,
  BD_DIFF_SP_SMP      NUMBER,
  BD_TRADING_PERIODS  NUMBER,
  BD_VOLUME           NUMBER,
  NBD_AVG_SMP         NUMBER,
  NBD_DIFF_SP_SMP     NUMBER,
  NBD_TRADING_PERIODS NUMBER,
  NBD_VOLUME          NUMBER,
  NET                 NUMBER,
  VAT_RATE            NUMBER,
  VAT_AMOUNT          NUMBER,
  GROSS               NUMBER
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_CFD_INVOICE_LINE_ITEM
  add constraint PK_CFD_INVOICE_LINE_ITEM primary key (SEM_CFD_INVOICE_ID, TRANSACTION_ID)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
----------------------------------------------------------------------------
create table SEM_TYPE3_CREDIT_COVER_REPORT
(
  ASSESSMENT_DATE        DATE not null,
  STATEMENT_STATE        NUMBER(1) not null,
  ENTITY_GROUP_ID        NUMBER(9) not null,
  PSE_ID                 NUMBER(9) not null,
  CURRENCY               VARCHAR2(4),
  RECORD_TYPE            VARCHAR2(3) not null,
  UNIT_TYPE              VARCHAR2(16) not null,
  MARKET                 VARCHAR2(50) not null,
  REQD_CREDIT_COVER      NUMBER(30,2),
  POSTED_CREDIT_COVER    NUMBER(30,2),
  WARNING_LIMIT          NUMBER(30,2),
  WARNING_LIMIT_REACHED  VARCHAR2(3),
  BREACH_AMOUNT          NUMBER(30,2),
  INVOICES_NOT_PAID      NUMBER(30,2),
  SETTLMENT_NOT_INVOICED NUMBER(30,2),
  UNDEFINED_EXPOSURE     NUMBER(30,2),
  REALLOCATIONS          NUMBER(30,2),
  FIXED_CREDIT_COVER     NUMBER(30,2),
  VERSION                NUMBER(3) not null,
  TIME_STAMP             DATE,
  ADJUSTMENT_AMOUNT      NUMBER(30,2),
  STATUS                 VARCHAR2(1),
  CCIN_BREACH_FLAG       VARCHAR2(8),
  ACC                    NUMBER(30,2),
  INTCONN_TRADED_AMT     NUMBER(30,2)
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_TYPE3_CREDIT_COVER_REPORT
  add constraint PK_SEM_TYPE3_CREDIT_REPORT primary key (ASSESSMENT_DATE, STATEMENT_STATE, ENTITY_GROUP_ID, PSE_ID, RECORD_TYPE, UNIT_TYPE, MARKET, VERSION)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_TYPE3_CREDIT_COVER_REPORT
  add constraint FK_SEM_TYPE3_CREDCOV_ENT_GRP foreign key (ENTITY_GROUP_ID)
  references ENTITY_GROUP (ENTITY_GROUP_ID) on delete cascade;
      
---------------------------------------------------------------------------------- 
-- Create table for Variable Type in GP Settlement Report
create table SEM_GP_SETTLEMENT_SUMM_VAR
(
  REPORT_TYPE VARCHAR2(32) not null,
  VARIABLE_TYPE VARCHAR2(24) not null
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_GP_SETTLEMENT_SUMM_VAR
  add constraint PK_SEM_GP_SETTLEMENT_VAR primary key (REPORT_TYPE, VARIABLE_TYPE)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
---------------------------------------------------------------------------------- 
-- Create table for Resource Name in GP Settlement Report
create table SEM_GP_SETTLEMENT_SUMM_RES
(
  RESOURCE_NAME VARCHAR2(100) not null
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_GP_SETTLEMENT_SUMM_RES
  add constraint PK_SEM_CP_SETTLEMENT_RES primary key (RESOURCE_NAME)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
---------------------------------------------------------------------------------- 
create global temporary table SEM_SETTLEMENT_COMP_SUMM_WORK
(
  INVOICE_BEGIN_DATE DATE not null,
  INVOICE_END_DATE   DATE not null,
  STATEMENT_TYPE      NUMBER not null,
  ENTITY_ID          NUMBER(9) not null,
  COMPONENT_ID       NUMBER(9) not null,
  STATEMENT_DATE     DATE not null,
  STMT_AMOUNT        NUMBER,
  STMT_QUANTITY      NUMBER,
  PIR_AMOUNT         NUMBER,
  PIR_QUANTITY       NUMBER,
  TDIE_AMOUNT        NUMBER,
  TDIE_QUANTITY      NUMBER,
  INTERNAL_AMOUNT    NUMBER,
  INTERNAL_QUANTITY  NUMBER
)
on commit preserve rows;

alter table SEM_SETTLEMENT_COMP_SUMM_WORK
  add constraint PK_SEM_SLMT_COMP_SUMM_WORK primary key (STATEMENT_TYPE, ENTITY_ID, COMPONENT_ID, STATEMENT_DATE);
---------------------------------------------------------------------------------- 
create global temporary table SEM_SETTLEMENT_COMP_DTL_WORK
(
  STATEMENT_DATE     DATE not null,
  DETAIL_DATE        DATE not null,	-- 30 Minute or Daily Intervals
  SUPPLIER_UNIT      VARCHAR2(64) not null,
  STATEMENT_TYPE     NUMBER(9) not null,
  COMPONENT_ID       NUMBER(9) not null,  
  DETAIL_TYPE        VARCHAR2(16) not null, -- Statement, PIR, TDIE, Internal, 300, 341, 591, 595, 596, 598
  AMOUNT             NUMBER,
  QUANTITY           NUMBER,
  ENTITY_ID          NUMBER(9), -- Used by Statement, PIR, TDIE, Internal
  PRODUCT_ID         NUMBER(9), -- Used by Statement, PIR, TDIE, Internal
  TDIE_ID		         NUMBER(9),  -- Used by 591 and 595 messages only
  UNDER_REVIEW 	     NUMBER(1), -- Used by 591 and 595 messages only
  JURISDICTION       VARCHAR2(8)-- Used by 591 and 595 messages only	
)
on commit preserve rows;

alter table SEM_SETTLEMENT_COMP_DTL_WORK
  add constraint PK_SEM_SLMT_COMP_DTL_WORK primary key (STATEMENT_DATE, DETAIL_DATE, SUPPLIER_UNIT, COMPONENT_ID, STATEMENT_TYPE, DETAIL_TYPE);

-------------------------------------------------------------------------------------------
CREATE TABLE SEM_CCR_VERSION_INFO
(
    VERSION_ID      NUMBER(3),
    VERSION_NAME    VARCHAR2(16)
);

-------------------------------------------------------------------------------------------
-- Create table for holding settlement download group data
create table SEM_DOWNLOAD_GROUP
(
  GROUP_NAME            VARCHAR2(128) not null,
  MARKET_TYPE           VARCHAR2(128) not null,
  REPORT_TYPE           VARCHAR2(128) not null,
  STATEMENT_TYPE_ID     NUMBER(9),
  EXTERNAL_ACCOUNT_NAME VARCHAR2(64) not null,
  PIR_STATEMENT_TYPE_ID NUMBER(9),
  INCLUDE_IN_DL         NUMBER(1) not null
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
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_DOWNLOAD_GROUP
  add constraint PK_DOWNLOAD_GROUP unique (GROUP_NAME)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
alter table SEM_DOWNLOAD_GROUP
  add constraint FK_DL_GROUP_PIR_STMNT_TYPE foreign key (PIR_STATEMENT_TYPE_ID)
  references STATEMENT_TYPE (STATEMENT_TYPE_ID) on delete cascade;
alter table SEM_DOWNLOAD_GROUP
  add constraint FK_DL_GROUP_STMNT_TYPE foreign key (STATEMENT_TYPE_ID)
  references STATEMENT_TYPE (STATEMENT_TYPE_ID) on delete cascade;

-- TLAF input data
create table tlaf_inputs
  (PSE_ID         NUMBER not null,
   POD_ID         NUMBER not null,
   BEGIN_DATE     date   not null,
   END_DATE       date   not null,
   DAY_TLAF       NUMBER not null,
   NIGHT_TLAF     NUMBER not null,
   TLAF_SEQUENCE  number,
   LOSS_NAME      varchar2(64),
   constraint tlaf_inputs_pk primary key (tlaf_sequence),
   CONSTRAINT FK_tlaf_inputs_POD FOREIGN KEY (POD_ID) REFERENCES SERVICE_POINT (SERVICE_POINT_ID)  ON DELETE CASCADe,
   CONSTRAINT FK_tlaf_inputs_PSE FOREIGN KEY (PSE_ID) REFERENCES PURCHASING_SELLING_ENTITY (PSE_ID) ON DELETE CASCADE
  );

--------------------------------------------------------------------------------
-- Create SEM Statement Job table and assoicatied constraints.
CREATE TABLE SEM_STATEMENT_JOB
   (BILLING_ENTITY_ID NUMBER(9) NOT NULL,
    STATEMENT_TYPE_ID NUMBER(9) NOT NULL,
    STATEMENT_STATE   NUMBER(1) NOT NULL,
    STATEMENT_DATE    DATE      NOT NULL,
    AS_OF_DATE        DATE      NOT NULL,
    JOB_ID            NUMBER(9) NOT NULL,
    JOB_VERSION       NUMBER(9) NOT NULL,
    STATEMENT_NUMBER  NUMBER(9) NOT NULL,
    FILE_NUMBER       NUMBER(9) NOT NULL) 
TABLESPACE NERO_DATA;


ALTER TABLE SEM_STATEMENT_JOB
  ADD CONSTRAINT PK_SEM_STATEMENT_JOB
  PRIMARY KEY (BILLING_ENTITY_ID,
               STATEMENT_TYPE_ID,
               STATEMENT_STATE,
               STATEMENT_DATE,
               AS_OF_DATE,
			   JOB_ID)
  USING INDEX TABLESPACE NERO_INDEX;


ALTER TABLE SEM_STATEMENT_JOB
  ADD CONSTRAINT FK_STMT_JOB_BILL_STATUS
  FOREIGN KEY (BILLING_ENTITY_ID,
               STATEMENT_TYPE_ID,
               STATEMENT_STATE,
               STATEMENT_DATE,
               AS_OF_DATE) 
  REFERENCES BILLING_STATEMENT_STATUS(ENTITY_ID,
                                      STATEMENT_TYPE,
                                      STATEMENT_STATE,
                                      STATEMENT_DATE,
                                      AS_OF_DATE)
  ON DELETE CASCADE;


ALTER TABLE SEM_STATEMENT_JOB
  ADD CONSTRAINT FK_SEM_STMT_JOB_PSE
  FOREIGN KEY (BILLING_ENTITY_ID) 
  REFERENCES PURCHASING_SELLING_ENTITY(PSE_ID);


ALTER TABLE SEM_STATEMENT_JOB
  ADD CONSTRAINT FK_SEM_STMT_JOB_STMT_TYPE
  FOREIGN KEY (STATEMENT_TYPE_ID) 
  REFERENCES STATEMENT_TYPE(STATEMENT_TYPE_ID);


CREATE INDEX IX01_SEM_STMT_JOB
    ON SEM_STATEMENT_JOB (BILLING_ENTITY_ID,
                          STATEMENT_DATE,
                          JOB_ID,
                          JOB_VERSION,
                          STATEMENT_NUMBER)
TABLESPACE NERO_INDEX;

-- New Table for tracking PIR Variable Names - No longer stored in SYSTEM_LABEL
CREATE TABLE SEM_PIR_VARIABLES
(
  VARIABLE_TYPE VARCHAR2(16) NOT NULL
)
TABLESPACE NERO_DATA
  PCTFREE 10
  INITRANS 1
  MAXTRANS 255
  STORAGE
  (
    INITIAL 64K
    MINEXTENTS 1
    MAXEXTENTS UNLIMITED
  );
  
ALTER TABLE SEM_PIR_VARIABLES
  ADD CONSTRAINT PK_SEM_PIR_VARIABLES PRIMARY KEY (VARIABLE_TYPE)
  USING INDEX 
  TABLESPACE NERO_DATA
  PCTFREE 10
  INITRANS 2
  MAXTRANS 255
  STORAGE
  (
    INITIAL 64K
    MINEXTENTS 1
    MAXEXTENTS UNLIMITED
  );

CREATE GLOBAL TEMPORARY TABLE SEM_NDLFESU_VALIDATION_TEMP
( VALIDATION_DATE DATE,
  DETERMINANT_TYPE VARCHAR2(64),
  MG           NUMBER,
  MGIU         NUMBER,
  MGEU         NUMBER,
  NIJ          NUMBER,
  JMGLF        NUMBER,
  JMDLF        NUMBER
)
ON COMMIT PRESERVE ROWS;

CREATE GLOBAL TEMPORARY TABLE SEM_NDLFESU_VALID_TEMP_DATE
( VALIDATION_DATE DATE,
  DATA_TYPE VARCHAR2(64),
  NDLFESU_PIR  NUMBER,
  NDLFESU_CALC NUMBER,
  MG           NUMBER,
  MGIU         NUMBER,
  MGEU         NUMBER,
  NIJ          NUMBER,
  JMGLF        NUMBER,
  JMDLF        NUMBER
)
ON COMMIT PRESERVE ROWS;



/*==============================================================*/
/* Table: SEM_EXCLUDED_BIDS                                     */
/*==============================================================*/

CREATE TABLE SEM_EXCLUDED_BIDS (
    DELIVERY_DATE       DATE,
    GATE_WINDOW	        VARCHAR2(4),
    PARTICIPANT_NAME    VARCHAR2(32),
    RESOURCE_NAME       VARCHAR2(32),
    PQ_INDEX            NUMBER(2),
    MAX_IMPORT_CAP      NUMBER,
    MAX_EXPORT_CAP      NUMBER,
    PRICE               NUMBER,
    QUANTITY            NUMBER,
    EXCLUDED_FLAG       VARCHAR2(8),
  CONSTRAINT PK_SEM_EXCLUDED_BIDS PRIMARY KEY (DELIVERY_DATE,GATE_WINDOW,PARTICIPANT_NAME,RESOURCE_NAME,PQ_INDEX)
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
;

/*==============================================================*/
/* Table: SEM_MSP_CANCELLATION                                     */
/*==============================================================*/

CREATE TABLE SEM_MSP_CANCELLATION
(
  TRADE_DATE            DATE NOT NULL,
  RUN_TYPE              VARCHAR2(32) NOT NULL,
  CANCELLATION_DATETIME DATE NOT NULL
)
TABLESPACE NERO_DATA
  PCTFREE 10
  INITRANS 1
  MAXTRANS 255
  STORAGE
  (
    INITIAL 64K
    MINEXTENTS 1
    MAXEXTENTS UNLIMITED
  );
  
/*==============================================================*/
/* Table: SEM_CREDIT_ACC_SUMMARY                                */
/*==============================================================*/
CREATE TABLE SEM_CREDIT_ACC_SUMMARY
(
  ACC_ID                NUMBER(9) NOT NULL,
  BATCH_ID              NUMBER(18),
  ACC_REPORT_TIME       DATE,
  CODE_PARTICIPANT_NAME VARCHAR2(50),
  TRADE_DATE            DATE,
  RUN_TYPE              VARCHAR2(4),
  ACC_BALANCE           NUMBER(15,2),
  REASON                VARCHAR2(250),
  ECPI_REPORT_ID        NUMBER(8),
  ECPI                  NUMBER(26,6),
  RCC_REPORT_ID         NUMBER(8),
  POSTED_CREDIT_COVER   NUMBER(26,6),
  S_REQ_CREDIT_COVER    NUMBER(26,6),
  G_REQ_CREDIT_COVER    NUMBER(26,6),
  FIXED_CREDIT_COVER    NUMBER(26,6),
  E_LAST_SETTLEDAY      DATE,
  C_LAST_SETTLEDAY      DATE,
  ETEV			NUMBER(26,6),
  CTEV			NUMBER(26,6),
    CONSTRAINT PK_SEM_CREDIT_ACC_SUMMARY PRIMARY KEY (ACC_ID)
	USING INDEX
       TABLESPACE NERO_INDEX
       STORAGE
       (
           INITIAL 64K
           NEXT 64K
           PCTINCREASE 0
       )
)
STORAGE
(
    INITIAL 128K
    NEXT 128K
    PCTINCREASE 0
)
TABLESPACE NERO_DATA;

ALTER TABLE SEM_CREDIT_ACC_SUMMARY
  ADD CONSTRAINT AK_SEM_CREDIT_ACC_SUMMARY UNIQUE (TRADE_DATE, RUN_TYPE, CODE_PARTICIPANT_NAME);

/*==============================================================*/
/* Table: SEM_CREDIT_ACC_INTERVAL                               */
/*==============================================================*/
CREATE TABLE SEM_CREDIT_ACC_INTERVAL
(
  ACC_ID           NUMBER(9) NOT NULL,
  PARTICIPANT_NAME VARCHAR2(32),
  RESOURCE_NAME    VARCHAR2(32),
  DELIVERY_DATE    DATE,
  ETEV             NUMBER(26,6),
  CTEV             NUMBER(26,6)
)
STORAGE
(
    INITIAL 128K
    NEXT 128K
    PCTINCREASE 0
)
TABLESPACE NERO_DATA;

-- CREATE/RECREATE FOREIGN KEY CONSTRAINTS 
ALTER TABLE SEM_CREDIT_ACC_INTERVAL
  ADD CONSTRAINT FK_SEM_CREDIT_ACC_ID FOREIGN KEY (ACC_ID)
  REFERENCES SEM_CREDIT_ACC_SUMMARY (ACC_ID) ON DELETE CASCADE;

-- CREATE/RECREATE UNIQUE KEY CONSTRAINTS 
ALTER TABLE SEM_CREDIT_ACC_INTERVAL
  ADD CONSTRAINT AK_SEM_CREDIT_ACC_INTERVAL UNIQUE (PARTICIPANT_NAME, RESOURCE_NAME, DELIVERY_DATE, ACC_ID);
  

/*==============================================================*/
/* Table: SEM_MARKET_RESULTS                                    */
/*==============================================================*/
create table SEM_MARKET_RESULTS
(
  trade_date	DATE NOT NULL,
  schedule_date DATE not null,
  run_type      VARCHAR2(4) not null,
  system_load   NUMBER,
  smp_euro      NUMBER,
  smp_gbp       NUMBER,
  lambda_euro   NUMBER,
  lambda_gbp    NUMBER
);
-- Add comments to the columns 
comment on column SEM_MARKET_RESULTS.trade_date
  is 'Trade Date as Date (Has only the Date and not Time portion. So, it is in Local Time.)';
comment on column SEM_MARKET_RESULTS.schedule_date
  is 'Schedule Date in Standard Time';
comment on column SEM_MARKET_RESULTS.run_type
  is 'MSP Software Run applicable to the report';
comment on column SEM_MARKET_RESULTS.smp_euro
  is 'System Marginal Price in Euro';
comment on column SEM_MARKET_RESULTS.smp_gbp
  is 'System Marginal Price in Sterling Pounds';
comment on column SEM_MARKET_RESULTS.lambda_euro
  is 'Shadow Price in Euro - the additional cost of delivering an additional MW of energy in addition to the value of Schedule Demand. This is generally the price for the marginal Generating Unit.';
comment on column SEM_MARKET_RESULTS.lambda_gbp
  is 'Shadow Price in Sterling Pounds - the additional cost of delivering an additional MW of energy in addition to the value of Schedule Demand. This is generally the price for the marginal Generating Unit.';
-- Create/Recreate primary, unique and foreign key constraints 
alter table SEM_MARKET_RESULTS add constraint PK_SEM_MARKET_RESULTS primary key (TRADE_DATE, SCHEDULE_DATE, RUN_TYPE);  

/*==============================================================*/
/* Table: SEM_CANCELLED_SRA_HEADER                              */
/*==============================================================*/
CREATE TABLE SEM_CANCELLED_SRA_HEADER
(
	FILE_ID					NUMBER(9) 		NOT NULL,
	RECORD_TYPE				VARCHAR2(1)		NOT NULL,
	VERSION					VARCHAR2(3)		NOT NULL,
	MARKET_OPERATOR			VARCHAR2(20)	NOT NULL,
	RECORD_TIMESTAMP		DATE			NOT NULL,
	CODE_PARTICIPANT_CID	VARCHAR2(100)	NOT NULL,
	TRANSACTION_CID			NUMBER(8)		NOT NULL
);
ALTER TABLE SEM_CANCELLED_SRA_HEADER ADD CONSTRAINT PK_SEM_CANCELLED_SRA_HEADER PRIMARY KEY (FILE_ID);
ALTER TABLE SEM_CANCELLED_SRA_HEADER ADD CONSTRAINT AK_SEM_CANCELLED_SRA_HEADER UNIQUE (FILE_ID, CODE_PARTICIPANT_CID, TRANSACTION_CID);
COMMENT ON COLUMN SEM_CANCELLED_SRA_HEADER.RECORD_TYPE IS 'Indicates the type of record.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_HEADER.VERSION IS 'The version number that defines the file layout. This version is 001.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_HEADER.MARKET_OPERATOR IS 'This is a reference to the Market Operator. Typically, it is SEMO.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_HEADER.RECORD_TIMESTAMP IS 'Date and time the file was created. ';
COMMENT ON COLUMN SEM_CANCELLED_SRA_HEADER.CODE_PARTICIPANT_CID IS 'Code Participant ID as imported from MI/STL.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_HEADER.TRANSACTION_CID IS 'Unique Transaction ID for the credit risk run under which the reallocation agreement were cancelled.';

/*==============================================================*/
/* Table: SEM_CANCELLED_SRA_DETAIL                              */
/*==============================================================*/;
CREATE TABLE SEM_CANCELLED_SRA_DETAIL
(
	FILE_ID					NUMBER(9) 		NOT NULL,
	RECORD_TYPE				VARCHAR2(3)		NOT NULL,
	PARTICIPANT_NAME		VARCHAR2(32)	NOT NULL,
	PARTICIPANT_NAME_CREDIT VARCHAR2(32)	NOT NULL,
	REALLOC_TYPE			VARCHAR2(2)		NOT NULL,
	DELIVERY_DATE			DATE			NOT NULL,
	DELIVERY_HOUR			NUMBER(2)		NOT NULL,
	DELIVERY_INTERVAL		NUMBER(1)		NOT NULL,
	MONETARY_VALUE			NUMBER(24,2)	NOT NULL,
	REALLOC_AGREEMENT_NAME 	VARCHAR2(128)	NOT NULL,
	CANCEL_FLAG				VARCHAR2(1)		NOT NULL
);
ALTER TABLE SEM_CANCELLED_SRA_DETAIL
   ADD CONSTRAINT FK_SEM_CANCELLED_SRA_DETAIL FOREIGN KEY (FILE_ID)
      REFERENCES SEM_CANCELLED_SRA_HEADER (FILE_ID)
      ON DELETE CASCADE;
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.RECORD_TYPE IS 'Indicates the type of record.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.PARTICIPANT_NAME IS 'Participant Name Account name of debit Participant.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.PARTICIPANT_NAME_CREDIT IS 'Credited Participant Name Account name of credit Participant.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.REALLOC_TYPE IS 'Reallocation type Energy or Capacity.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.DELIVERY_DATE IS 'Delivery date Delivery date of Reallocation. This is TRADING DATE.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.DELIVERY_HOUR IS 'Values can range from 1-25 (local prevailing time).';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.DELIVERY_INTERVAL IS 'Value is either 1 or 2 for the 30-minute sub-hourly count within the hour.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.MONETARY_VALUE IS 'Monetary value Monetary value of Reallocation agreement.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.REALLOC_AGREEMENT_NAME IS 'Reallocation agreement name Name of Reallocation agreement.';
COMMENT ON COLUMN SEM_CANCELLED_SRA_DETAIL.CANCEL_FLAG IS 'Cancel Flag.';