spool crebas.log
/*==============================================================*/
/* Database name:  4_2_0_NEW_ENERGY_OFFICE                      */
/* DBMS name:      ORACLE Version 9i                            */
/* Created on:     7/24/2008 11:31:14 AM                        */
/*==============================================================*/


/*==============================================================*/
/* Table: ACCOUNT                                               */
/*==============================================================*/


create table ACCOUNT  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   ACCOUNT_NAME         VARCHAR2(128)                     not null,
   ACCOUNT_ALIAS        VARCHAR2(32),
   ACCOUNT_DESC         VARCHAR2(256),
   ACCOUNT_DUNS_NUMBER  VARCHAR2(16),
   ACCOUNT_EXTERNAL_IDENTIFIER VARCHAR2(64),
   ACCOUNT_MODEL_OPTION VARCHAR2(16),
   ACCOUNT_SIC_CODE     VARCHAR2(8),
   ACCOUNT_METER_TYPE   VARCHAR2(16),
   ACCOUNT_METER_EXT_IDENTIFIER VARCHAR2(16),
   ACCOUNT_DISPLAY_NAME VARCHAR2(128),
   ACCOUNT_BILL_OPTION  VARCHAR2(16),
   ACCOUNT_ROLLUP_ID    NUMBER(9),
   IS_EXTERNAL_INTERVAL_USAGE NUMBER(1),
   IS_EXTERNAL_BILLED_USAGE NUMBER(1),
   IS_AGGREGATE_ACCOUNT NUMBER(1),
   IS_UFE_PARTICIPANT   NUMBER(1),
   IS_CREATE_SETTLEMENT_PROFILE NUMBER(1),
   IS_EXTERNAL_FORECAST NUMBER(1),
   IS_SUB_AGGREGATE     NUMBER(1)                        not null,
   TX_SERVICE_TYPE_ID   NUMBER(9),
   USE_TOU_USAGE_FACTOR   NUMBER(1),
   MODEL_ID             NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT primary key (ACCOUNT_ID)
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

/* A table cannot be both sub aggregate and aggregate model */
alter table ACCOUNT
	add constraint CK01_ACCOUNT check (IS_SUB_AGGREGATE = 0 OR (IS_SUB_AGGREGATE = 1 AND ACCOUNT_MODEL_OPTION <> 'Aggregate'))
/



/*==============================================================*/
/* Index: ACCOUNT_IX01                                          */
/*==============================================================*/
create index ACCOUNT_IX01 on ACCOUNT (
   ACCOUNT_NAME ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: ACCOUNT_IX02                                          */
/*==============================================================*/
create index ACCOUNT_IX02 on ACCOUNT (
   ACCOUNT_EXTERNAL_IDENTIFIER ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Index: ACCOUNT_IX03                                          */
/*==============================================================*/
create index ACCOUNT_IX03 on ACCOUNT (
   IS_SUB_AGGREGATE, ACCOUNT_MODEL_OPTION, IS_AGGREGATE_ACCOUNT
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/



/*==============================================================*/
/* Table: ACCOUNT_ANCILLARY_SERVICE                             */
/*==============================================================*/


create table ACCOUNT_ANCILLARY_SERVICE  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   ANCILLARY_SERVICE_ID NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SERVICE_VAL          NUMBER,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_ANCILLARY_SERVICE primary key (ACCOUNT_ID, ANCILLARY_SERVICE_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Table: ACCOUNT_AGGREGATE_STATIC_DATA                         */
/*==============================================================*/

create table ACCOUNT_AGGREGATE_STATIC_DATA  (
   AGGREGATE_ACCOUNT_ID NUMBER(9) not null,
   SERVICE_LOCATION_ID NUMBER(9),
   EDC_ID NUMBER(9) not null,
   SERVICE_POINT_ID NUMBER(9) not null,
   SERVICE_ZONE_ID NUMBER(9) not null,
   SCHEDULE_GROUP_ID NUMBER(9) not null,
   CALENDAR_ID NUMBER(9) not null,
   WEATHER_STATION_ID NUMBER(9) not null,
   LOSS_FACTOR_ID NUMBER(9) not null,
   EDC_RATE_CLASS VARCHAR2(16),
   EDC_STRATA VARCHAR2(16),
   REVENUE_PRODUCT_ID NUMBER(9) not null,
   COST_PRODUCT_ID NUMBER(9) not null,
   METER_TYPE VARCHAR2(2) not null,
   MODEL_ID NUMBER(1) not null,
   TOU_TEMPLATE_ID NUMBER(9) not null,
   BILL_CYCLE_ID NUMBER(9) not null,
   AGGREGATION_GROUP VARCHAR2(64),
   constraint PK_ACCOUNT_AGG_STATIC_DATA primary key (AGGREGATE_ACCOUNT_ID)
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

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT AK_ACCOUNT_AGG_STATIC_DATA UNIQUE (EDC_ID, SERVICE_POINT_ID, SERVICE_ZONE_ID, SCHEDULE_GROUP_ID, CALENDAR_ID, WEATHER_STATION_ID,
                                                        LOSS_FACTOR_ID, EDC_RATE_CLASS, EDC_STRATA, REVENUE_PRODUCT_ID, COST_PRODUCT_ID, METER_TYPE,
                                                        MODEL_ID, TOU_TEMPLATE_ID, BILL_CYCLE_ID, AGGREGATION_GROUP)
    USING INDEX
    TABLESPACE NERO_INDEX
    STORAGE
    (
        INITIAL 64K
        NEXT 64K
        PCTINCREASE 0
    )
/


/*==============================================================*/
/* Table: ACCOUNT_BILL_CYCLE                                    */
/*==============================================================*/


create table ACCOUNT_BILL_CYCLE  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   BILL_CYCLE_ID        NUMBER(9)                        not null,
   BILL_CYCLE_ENTITY    VARCHAR(16)                      not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_BILL_CYCLE primary key (ACCOUNT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: ACCOUNT_BILL_PARTY                                    */
/*==============================================================*/


create table ACCOUNT_BILL_PARTY  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   BILL_PARTY_ID        NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_BILL_PARTY primary key (ACCOUNT_ID, BILL_PARTY_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: ACCOUNT_CALENDAR                                      */
/*==============================================================*/


create table ACCOUNT_CALENDAR  (
   CASE_ID              NUMBER(9)                        not null,
   ACCOUNT_ID           NUMBER(9)                        not null,
   CALENDAR_ID          NUMBER(9)                        not null,
   CALENDAR_TYPE        VARCHAR2(16)                     not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_CALENDAR primary key (CASE_ID, ACCOUNT_ID, CALENDAR_TYPE, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_ACCOUNT_CALENDAR                                   */
/*==============================================================*/
create index FK_ACCOUNT_CALENDAR on ACCOUNT_CALENDAR (
   ACCOUNT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 

/*==============================================================*/
/* Table: ACCOUNT_EDC                                           */
/*==============================================================*/


create table ACCOUNT_EDC  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   EDC_ID               NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   EDC_ACCOUNT_NUMBER   VARCHAR2(32),
   EDC_RATE_CLASS       VARCHAR2(16),
   EDC_STRATA           VARCHAR2(16),
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_EDC primary key (ACCOUNT_ID, EDC_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: ACCOUNT_ESP                                           */
/*==============================================================*/


create table ACCOUNT_ESP  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   ESP_ID               NUMBER(9)                        not null,
   POOL_ID              NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ESP_ACCOUNT_NUMBER   VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_ESP primary key (ACCOUNT_ID, BEGIN_DATE)
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

create index ACCOUNT_ESP_IX1 on ACCOUNT_ESP (
   ACCOUNT_ID, ESP_ID, POOL_ID, BEGIN_DATE
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ACCOUNT_GROUP                                         */
/*==============================================================*/


create table ACCOUNT_GROUP  (
   ACCOUNT_GROUP_ID     NUMBER(9)                        not null,
   ACCOUNT_GROUP_NAME   VARCHAR2(32)                     not null,
   ACCOUNT_GROUP_ALIAS  VARCHAR2(32),
   ACCOUNT_GROUP_DESC   VARCHAR2(256),
   EXTERNAL_IDENTIFIER  VARCHAR(32),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_GROUP primary key (ACCOUNT_GROUP_ID)
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


alter table ACCOUNT_GROUP
   add constraint AK_ACCOUNT_GROUP unique (ACCOUNT_GROUP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ACCOUNT_GROUP_ASSIGNMENT                              */
/*==============================================================*/


create table ACCOUNT_GROUP_ASSIGNMENT  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   ACCOUNT_GROUP_ID     NUMBER(9)                        not null,
   ASSIGNMENT_CATEGORY  VARCHAR(16)                      not null,
   constraint PK_ACCOUNT_GROUP_ASSIGNMENT primary key (ACCOUNT_ID, ACCOUNT_GROUP_ID, ASSIGNMENT_CATEGORY)
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


/*==============================================================*/
/* Table: ACCOUNT_GROWTH                                        */
/*==============================================================*/


create table ACCOUNT_GROWTH  (
   CASE_ID              NUMBER(9)                        not null,
   ACCOUNT_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PATTERN_ID           NUMBER(9),
   GROWTH_PCT           NUMBER(8,3),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_GROWTH primary key (CASE_ID, ACCOUNT_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_ACCOUNT_GROWTH                                     */
/*==============================================================*/
create index FK_ACCOUNT_GROWTH on ACCOUNT_GROWTH (
   ACCOUNT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 

/*==============================================================*/
/* Table: ACCOUNT_LOSS_FACTOR                                   */
/*==============================================================*/


create table ACCOUNT_LOSS_FACTOR  (
   CASE_ID              NUMBER(9)                        not null,
   ACCOUNT_ID           NUMBER(9)                        not null,
   LOSS_FACTOR_ID       NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_LOSS_FACTOR primary key (CASE_ID, ACCOUNT_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_ACCOUNT_LOSS_FACTOR                                */
/*==============================================================*/
create index FK_ACCOUNT_LOSS_FACTOR on ACCOUNT_LOSS_FACTOR (
   ACCOUNT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_ACCT_LOSS_FACTOR                                   */
/*==============================================================*/
create index FK_ACCT_LOSS_FACTOR on ACCOUNT_LOSS_FACTOR (
   LOSS_FACTOR_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ACCOUNT_METER                                         */
/*==============================================================*/


create table ACCOUNT_METER  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   METER_NAME           VARCHAR2(128)                     not null,
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   USAGE_FACTOR         NUMBER(12,6),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_METER primary key (ACCOUNT_ID, METER_NAME)
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


/*==============================================================*/
/* Table: ACCOUNT_PRODUCT                                       */
/*==============================================================*/


create table ACCOUNT_PRODUCT  (
   CASE_ID              NUMBER(9)                        not null,
   ACCOUNT_ID           NUMBER(9)                        not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   PRODUCT_TYPE         CHAR(1)                          not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_PRODUCT primary key (CASE_ID, ACCOUNT_ID, PRODUCT_TYPE, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_ACCOUNT_PRODUCT                                    */
/*==============================================================*/
create index FK_ACCOUNT_PRODUCT on ACCOUNT_PRODUCT (
   ACCOUNT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ACCOUNT_PROXY_DAY_METHOD                              */
/*==============================================================*/


create table ACCOUNT_PROXY_DAY_METHOD (
   ACCOUNT_ID            NUMBER(9)     not null,
   PROXY_DAY_METHOD_TYPE VARCHAR2(16)  not null,
   BEGIN_DATE            DATE          not null,
   END_DATE              DATE,
   PROXY_DAY_METHOD_ID   NUMBER(9)     not null,
   ENTRY_DATE                DATE,
   constraint PK_ACCOUNT_PROXY_DAY_METHOD primary key (ACCOUNT_ID, PROXY_DAY_METHOD_TYPE, BEGIN_DATE)
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


alter table ACCOUNT_PROXY_DAY_METHOD
	add constraint CK01_ACCOUNT_PROXY_DAY_METHOD check (PROXY_DAY_METHOD_TYPE IN ('Forecast','Backcast'))
/


/*==============================================================*/
/* Table: ACCOUNT_SCHEDULE_GROUP                                */
/*==============================================================*/


create table ACCOUNT_SCHEDULE_GROUP  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   SCHEDULE_GROUP_ID    NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,   
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_SCHEDULE_GROUP primary key (ACCOUNT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: ACCOUNT_SERVICE                                       */
/*==============================================================*/


create table ACCOUNT_SERVICE  (
   ACCOUNT_SERVICE_ID   NUMBER(9)                        not null,
   ACCOUNT_ID           NUMBER(9),
   SERVICE_LOCATION_ID  NUMBER(9),
   METER_ID             NUMBER(9),
   AGGREGATE_ID         NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_SERVICE primary key (ACCOUNT_SERVICE_ID)
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


alter table ACCOUNT_SERVICE
   add constraint AK_ACCOUNT_SERVICE unique (ACCOUNT_ID, SERVICE_LOCATION_ID, METER_ID, AGGREGATE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


alter table ACCOUNT_SERVICE
   add constraint AK2_ACCOUNT_SERVICE unique (ACCOUNT_SERVICE_ID, AGGREGATE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table ACCOUNT_SERVICE
   add constraint AK3_ACCOUNT_SERVICE unique (METER_ID, SERVICE_LOCATION_ID, ACCOUNT_ID, ACCOUNT_SERVICE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: ACCOUNT_SERVICE_CHARGE                                */
/*==============================================================*/


create table ACCOUNT_SERVICE_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   ACCOUNT_SERVICE_ID   NUMBER(9)                        not null,
   BAND_NUMBER          NUMBER(1)                        not null,
   BILL_CODE            CHAR(1)                          not null,
   CHARGE_BEGIN_DATE    DATE                             not null,
   CHARGE_END_DATE      DATE,
   CHARGE_QUANTITY      NUMBER(10,4),
   CHARGE_RATE          NUMBER(10,4),
   CHARGE_FACTOR        NUMBER(10,4),
   CHARGE_AMOUNT        NUMBER(10,4),
   BILL_QUANTITY        NUMBER(10,4),
   BILL_AMOUNT          NUMBER(10,4),
   constraint PK_ACCOUNT_SERVICE_CHARGE primary key (CHARGE_ID, ACCOUNT_SERVICE_ID, BAND_NUMBER, BILL_CODE, CHARGE_BEGIN_DATE)
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


/*==============================================================*/
/* Table: ACCOUNT_SERVICE_LOCATION                              */
/*==============================================================*/


create table ACCOUNT_SERVICE_LOCATION  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   SERVICE_LOCATION_ID  NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   EDC_IDENTIFIER       VARCHAR2(32),
   ESP_IDENTIFIER       VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_SERVICE_LOCATION primary key (ACCOUNT_ID, SERVICE_LOCATION_ID, BEGIN_DATE)
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

--This index gets used often when looking up the Account for a DER via the DER's Service Location.
create index ACCOUNT_SERVICE_LOCATION_IX01 on ACCOUNT_SERVICE_LOCATION (
   SERVICE_LOCATION_ID ASC,
   BEGIN_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ACCOUNT_STATUS                                        */
/*==============================================================*/

create table ACCOUNT_STATUS  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   STATUS_NAME          VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_STATUS primary key (ACCOUNT_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_ACCNT_STATUS_NAME                                  */
/*==============================================================*/
create index FK_ACCNT_STATUS_NAME on ACCOUNT_STATUS (
   STATUS_NAME ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 

/*==============================================================*/
/* Table: ACCOUNT_STATUS_NAME                                        */
/*==============================================================*/


create table ACCOUNT_STATUS_NAME  (
   STATUS_NAME          VARCHAR2(16)	not null,
   IS_ACTIVE            NUMBER(1),
   constraint PK_ACCOUNT_STATUS_NAME primary key (STATUS_NAME)
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


/*==============================================================*/
/* Table: ACCOUNT_SYNC_STAGING                                  */
/*==============================================================*/
create table ACCOUNT_SYNC_STAGING  (
    BEGIN_DATE                          DATE            not null,
    END_DATE                            DATE,
    ACCOUNT_IDENT                       VARCHAR2(64)    not null,
    ACCOUNT_SERVICE                     VARCHAR2(16)    not null,
    ACCOUNT_NAME                        VARCHAR2(128),
    ACCOUNT_ALIAS                       VARCHAR2(32),
    ACCOUNT_DESC                        VARCHAR2(256),
    ACCOUNT_STATUS                      VARCHAR2(16),
    ACCOUNT_MODEL_OPTION                VARCHAR2(16),
    ACCOUNT_IS_SUB_AGGREGATE            NUMBER(1),
    ACCOUNT_IS_UFE_PARTICIPANT          NUMBER(1),
    ACCOUNT_DUNS_NUMBER                 VARCHAR2(16),
    ACCOUNT_SIC_CODE                    VARCHAR2(8),
    EDC_IDENT                           VARCHAR2(64),
    EDC_ACCOUNT_NUMBER                  VARCHAR2(32),
    EDC_RATE_CLASS                      VARCHAR2(16),
    EDC_STRATA                          VARCHAR2(16),
    ESP_IDENT                           VARCHAR2(64),
    POOL_IDENT                          VARCHAR2(64),
    ESP_ACCOUNT_NUMBER                  VARCHAR2(32),
    ACCOUNT_ANC_SERVICE_VAL1        	NUMBER,
    ACCOUNT_ANC_SERVICE_VAL2        	NUMBER,
    ACCOUNT_ANC_SERVICE_VAL3        	NUMBER,
    ACCOUNT_ANC_SERVICE_VAL4        	NUMBER,
    ACCOUNT_ANC_SERVICE_VAL5        	NUMBER,
    SERVICE_LOCATION_IDENT      	VARCHAR2(64),
    SERVICE_LOCATION_NAME               VARCHAR2(32),
    SERVICE_LOCATION_ALIAS              VARCHAR2(32),
    SERVICE_LOCATION_DESC               VARCHAR2(256),
    LATITUDE                            VARCHAR2(8),
    LONGITUDE                           VARCHAR2(8),
    TIME_ZONE                           VARCHAR2(16),
    WEATHER_STATION_IDENT               VARCHAR2(32),
    SQUARE_FOOTAGE                      NUMBER(7),
    ANNUAL_CONSUMPTION                  NUMBER(16,4),
    SUMMER_CONSUMPTION                  NUMBER(15,4),
    SERVICE_ZONE_IDENT              	VARCHAR2(64),
    SERVICE_POINT_IDENT             	VARCHAR2(32),
    SUB_STATION_IDENT                   VARCHAR2(32),
    FEEDER_IDENT                        VARCHAR2(64),
    FEEDER_SEGMENT_IDENT                VARCHAR2(64),
    PREMISE_EDC_IDENT                   VARCHAR2(32),
    PREMISE_ESP_IDENT                   VARCHAR2(32),
    METER_IDENT                     	VARCHAR2(128),
    METER_NAME                          VARCHAR2(128),
    METER_ALIAS                         VARCHAR2(128),
    METER_DESC                          VARCHAR2(256),
    METER_STATUS                        VARCHAR2(16),
    METER_TYPE                  VARCHAR2(8),
    USE_TOU_USAGE_FACTOR                NUMBER(1),
    METER_INTERVAL                      VARCHAR2(16),
    METER_UNIT                          VARCHAR2(8),
    MRSP_IDENT                          VARCHAR2(32),
    METER_EDC_IDENT                     VARCHAR2(32),
    METER_ESP_IDENT                     VARCHAR2(32),
    METER_ANC_SERVICE_VAL1              NUMBER,
    METER_ANC_SERVICE_VAL2              NUMBER,
    METER_ANC_SERVICE_VAL3              NUMBER,
    METER_ANC_SERVICE_VAL4              NUMBER,
    METER_ANC_SERVICE_VAL5              NUMBER,
    FORECAST_CALENDAR_IDENT         	VARCHAR2(32),
    BACKCAST_CALENDAR_IDENT         	VARCHAR2(32),
    STTL_PROFILE_CALENDAR_IDENT     	VARCHAR2(32),
    TOU_TEMPLATE_IDENT                  VARCHAR2(32),
    USAGE_FACTOR_VAL1                   NUMBER(14,6),
    USAGE_FACTOR_VAL2                   NUMBER(14,6),
    USAGE_FACTOR_VAL3                   NUMBER(14,6),
    USAGE_FACTOR_VAL4                   NUMBER(14,6),
    USAGE_FACTOR_VAL5                   NUMBER(14,6),
    LOSS_FACTOR_IDENT                   VARCHAR2(32),
    SCHEDULE_GROUP_IDENT                VARCHAR2(32),
    COST_PRODUCT_IDENT                  VARCHAR2(32),
    REVENUE_PRODUCT_IDENT               VARCHAR2(32),
    BILLING_AGENT                       VARCHAR2(16),
    BILL_CYCLE_IDENT                    VARCHAR2(32),
    CONTRACT_IDENT		       	VARCHAR2(32),
    ACCOUNT_GROUP_IDENT1                VARCHAR2(32),
    ACCOUNT_GROUP_IDENT2                VARCHAR2(32),
    ACCOUNT_GROUP_IDENT3                VARCHAR2(32),
    ACCOUNT_GROUP_IDENT4                VARCHAR2(32),
    ACCOUNT_GROUP_IDENT5                VARCHAR2(32),
    ENTITY_GROUP_IDENT1                 VARCHAR2(32),
    ENTITY_GROUP_IDENT2                 VARCHAR2(32),
    ENTITY_GROUP_IDENT3                 VARCHAR2(32),
    ENTITY_GROUP_IDENT4                 VARCHAR2(32),
    ENTITY_GROUP_IDENT5                 VARCHAR2(32),
    TEMPORAL_ATTRIBUTE_VAL1         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL2         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL3         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL4         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL5         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL6         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL7         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL8         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL9         	VARCHAR2(64),
    TEMPORAL_ATTRIBUTE_VAL10         	VARCHAR2(64),
    FORECAST_PROXY_DAY_IDENT            VARCHAR2(32),
    BACKCAST_PROXY_DAY_IDENT            VARCHAR2(32),
    SYNC_ORDER                         	NUMBER,
    SYNC_STATUS                 		VARCHAR2(32),
    ERROR_MESSAGE                 		VARCHAR2(4000)
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

/*==============================================================*/
/* Table: ACCOUNT_TOU_USAGE_FACTOR                                        */
/*==============================================================*/


create table ACCOUNT_TOU_USAGE_FACTOR  (
   ACCOUNT_ID          NUMBER(9)	not null,
   CASE_ID          NUMBER(9) 	not null,
   BEGIN_DATE          DATE	not null,
   END_DATE          DATE,  
   TEMPLATE_ID            NUMBER(9)	not null,
   TOU_USAGE_FACTOR_ID            NUMBER(9)	not null,
   ENTRY_DATE          DATE,
   constraint PK_ACCOUNT_TOU_USAGE_FACTOR primary key (ACCOUNT_ID, CASE_ID, BEGIN_DATE)
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

alter table ACCOUNT_TOU_USAGE_FACTOR
   add constraint AK_ACCOUNT_TOU_USAGE_FACTOR unique (TOU_USAGE_FACTOR_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: ACCOUNT_TOU_USG_FACTOR_PERIOD                                        */
/*==============================================================*/


create table ACCOUNT_TOU_USG_FACTOR_PERIOD  (
   TOU_USAGE_FACTOR_ID          NUMBER(9)	not null,
   PERIOD_ID          NUMBER(9) 	not null,
   FACTOR_VAL          NUMBER(14,6),
   ENTRY_DATE          DATE,
   constraint PK_ACCT_TOU_USG_FACTOR_PERIOD primary key (TOU_USAGE_FACTOR_ID, PERIOD_ID)
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


/*==============================================================*/
/* Table: ACCOUNT_UFE_PARTICIPATION                             */
/*==============================================================*/


create table ACCOUNT_UFE_PARTICIPATION  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   UFE_CODE             CHAR(1)                          not null,
   UFE_REQUESTOR        VARCHAR2(16)                     not null,
   IS_UFE_PARTICIPANT   NUMBER(1),
   constraint PK_ACCOUNT_UFE_PARTICIPATION primary key (ACCOUNT_ID, UFE_CODE, UFE_REQUESTOR)
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


/*==============================================================*/
/* Table: ACCOUNT_USAGE_FACTOR                                  */
/*==============================================================*/


create table ACCOUNT_USAGE_FACTOR  (
   CASE_ID              NUMBER(9)                        not null,
   ACCOUNT_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   FACTOR_VAL           NUMBER(14,6),
   SOURCE_CALENDAR_ID   NUMBER(9),
   SOURCE_BEGIN_DATE    DATE,
   SOURCE_END_DATE      DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_USAGE_FACTOR primary key (CASE_ID, ACCOUNT_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_ACCOUNT_USAGE_FACTOR                               */
/*==============================================================*/
create index FK_ACCOUNT_USAGE_FACTOR on ACCOUNT_USAGE_FACTOR (
   ACCOUNT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ACCOUNT_USAGE_WRF                                     */
/*==============================================================*/


create table ACCOUNT_USAGE_WRF  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   WRF_ID               NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_USAGE_WRF primary key (ACCOUNT_ID, WRF_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_ACCOUNT_USAGE_WRF                                  */
/*==============================================================*/
create index FK_ACCOUNT_USAGE_WRF on ACCOUNT_USAGE_WRF (
   WRF_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 

/*==============================================================*/
/* Table: ACCOUNT_USAGE_WRF_LINE                                */
/*==============================================================*/


create table ACCOUNT_USAGE_WRF_LINE  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   WRF_ID               NUMBER(9)                        not null,
   TEMPLATE_ID          NUMBER(9)                        not null,
   SEGMENT_NBR          NUMBER(1)                        not null,
   AS_OF_DATE           DATE                             not null,
   ALPHA                NUMBER(8,4),
   BETA                 NUMBER(8,4),
   R2                   NUMBER(8,6),
   N                    NUMBER(6),
   X_MIN                NUMBER(8,2),
   X_MAX                NUMBER(8,2),
   Y_MIN                NUMBER(8,2),
   Y_MAX                NUMBER(8,2),
   X_ZERO               NUMBER(4),
   Y_ZERO               NUMBER(4),
   Y_LIMIT              NUMBER(8,2),
   Y_TYPE               CHAR(1),
   BASE_LOAD_TEMPLATE_ID NUMBER(9),
   constraint PK_ACCOUNT_USAGE_WRF_LINE primary key (ACCOUNT_ID, WRF_ID, TEMPLATE_ID, SEGMENT_NBR, AS_OF_DATE)
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

/*==============================================================*/
/* Index: FK_ACCOUNT_USAGE_WRF_LINE                             */
/*==============================================================*/
create index FK_ACCOUNT_USAGE_WRF_LINE on ACCOUNT_USAGE_WRF_LINE (
   WRF_ID ASC, TEMPLATE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_ACCOUNT_USAGE_WRF_LINE_TMPL                        */
/*==============================================================*/
create index FK_ACCOUNT_USAGE_WRF_LINE_TMPL on ACCOUNT_USAGE_WRF_LINE (
   BASE_LOAD_TEMPLATE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: AGGREGATE_ACCOUNT_CUSTOMER                            */
/*==============================================================*/


create table AGGREGATE_ACCOUNT_CUSTOMER  (
   AGGREGATE_ID         NUMBER(9)                        not null,
   CUSTOMER_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_AGGREGATE_ACCOUNT_CUSTOMER primary key (AGGREGATE_ID, CUSTOMER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: AGGREGATE_ACCOUNT_ESP                                 */
/*==============================================================*/


create table AGGREGATE_ACCOUNT_ESP  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   ESP_ID               NUMBER(9)                        not null,
   POOL_ID              NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   AGGREGATE_ID         NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_AGGREGATE_ACCOUNT_ESP primary key (ACCOUNT_ID, ESP_ID, POOL_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: AGGREGATE_ACCOUNT_GROWTH                              */
/*==============================================================*/


create table AGGREGATE_ACCOUNT_GROWTH  (
   CASE_ID              NUMBER(9)                        not null,
   AGGREGATE_ID         NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SERVICE_ACCOUNTS     NUMBER(12),
   GROWTH_PCT           NUMBER(8,3),
   PATTERN_ID           NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_AGGREGATE_ACCOUNT_GROWTH primary key (CASE_ID, AGGREGATE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: AGGREGATE_ACCOUNT_SERVICE                             */
/*==============================================================*/


create table AGGREGATE_ACCOUNT_SERVICE  (
   CASE_ID              NUMBER(9)                        not null,
   AGGREGATE_ID         NUMBER(9)                        not null,
   SERVICE_DATE         DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   SERVICE_ACCOUNTS     NUMBER(9),
   ENROLLED_ACCOUNTS    NUMBER(9),
   USAGE_FACTOR         NUMBER(14,6),
   constraint PK_AGGREGATE_ACCOUNT_SERVICE primary key (CASE_ID, SERVICE_DATE, AS_OF_DATE, AGGREGATE_ID)
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


/*==============================================================*/
/* Table: AGGREGATE_ANCILLARY_SERVICE                           */
/*==============================================================*/


create table AGGREGATE_ANCILLARY_SERVICE  (
   AGGREGATE_ID         NUMBER(9)                        not null,
   ANCILLARY_SERVICE_ID NUMBER(9)                        not null,
   SERVICE_DATE         DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   SERVICE_VAL          NUMBER(14,6),
   constraint PK_AGGREGATE_ANCILLARY_SERVICE primary key (AGGREGATE_ID, ANCILLARY_SERVICE_ID, SERVICE_DATE, AS_OF_DATE)
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


/*==============================================================*/
/* Table: ANCILLARY_SERVICE                                     */
/*==============================================================*/


create table ANCILLARY_SERVICE  (
   ANCILLARY_SERVICE_ID NUMBER(9)                        not null,
   ANCILLARY_SERVICE_NAME VARCHAR2(32)                     not null,
   ANCILLARY_SERVICE_ALIAS VARCHAR2(32),
   ANCILLARY_SERVICE_DESC VARCHAR2(256),
   ANCILLARY_SERVICE_TYPE VARCHAR2(16),
   PROVIDER_CATEGORY    VARCHAR2(16),
   PROVIDER_ID          NUMBER(9),
   TRANSACTION_TYPE     VARCHAR2(32),
   IT_COMMODITY_ID      NUMBER(9),
   ROUNDING_PREFERENCE  VARCHAR2(32),
   MINIMUM_SCHEDULE_AMT NUMBER(8,3),
   ANCILLARY_SERVICE_UNIT VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_ANCILLARY_SERVICE primary key (ANCILLARY_SERVICE_ID)
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


alter table ANCILLARY_SERVICE
   add constraint AK_ANCILLARY_SERVICE unique (ANCILLARY_SERVICE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ANCILLARY_SERVICE_ALLOCATION                          */
/*==============================================================*/


create table ANCILLARY_SERVICE_ALLOCATION  (
   ANCILLARY_SERVICE_ID NUMBER(9)                        not null,
   ALLOCATION_NAME      VARCHAR(64)                      not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ALLOCATION_VAL       NUMBER(16,4),
   DEFAULT_VAL          NUMBER(16,4),
   constraint PK_ANCILLARY_SERVICE_ALLOCATIO primary key (ANCILLARY_SERVICE_ID, ALLOCATION_NAME, BEGIN_DATE)
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


/*==============================================================*/
/* Table: ANCILLARY_SERVICE_AREA_PEAK                           */
/*==============================================================*/


create table ANCILLARY_SERVICE_AREA_PEAK  (
   ANCILLARY_SERVICE_ID NUMBER(9)                        not null,
   AREA_ID              NUMBER(9)                        not null,
   PEAK_DATE            DATE                             not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PEAK_VAL             NUMBER(16,4),
   constraint PK_ANCILLARY_SERVICE_AREA_PEAK primary key (ANCILLARY_SERVICE_ID, AREA_ID, PEAK_DATE, BEGIN_DATE)
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

/*==============================================================*/
/* Table: ACCOUNT_SUB_AGG_AGGREGATION                           */
/*==============================================================*/
create table ACCOUNT_SUB_AGG_AGGREGATION  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   AGGREGATE_ID         NUMBER(9)                        not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_ACCOUNT_SUB_AGG_AGG primary key (ACCOUNT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: APPLICATION_ROLE                                      */
/*==============================================================*/


create table APPLICATION_ROLE  (
   ROLE_ID              NUMBER(9)                        not null,
   ROLE_NAME            VARCHAR2(32)                     not null,
   ROLE_ALIAS           VARCHAR2(32),
   ROLE_DESC            VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_APPLICATION_ROLE primary key (ROLE_ID)
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


alter table APPLICATION_ROLE
   add constraint AK_APPLICATION_ROLE unique (ROLE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: APPLICATION_USER                                      */
/*==============================================================*/


create table APPLICATION_USER  (
   USER_ID              NUMBER(9)                        not null,
   USER_NAME            VARCHAR(64)                      not null,
   USER_DISPLAY_NAME    VARCHAR(64),
   EMAIL_ADDR           VARCHAR2(128),
   IS_DISABLED          NUMBER(1)                      default 0  not null,
   IS_SYSTEM_USER       NUMBER(1)                      default 0  not null,
   ENTRY_DATE           DATE,
   constraint PK_APPLICATION_USER primary key (USER_ID)
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


alter table APPLICATION_USER
   add constraint AK_APPLICATION_USER unique (USER_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: APPLICATION_USER_PREFERENCES                          */
/*==============================================================*/


create table APPLICATION_USER_PREFERENCES  (
   USER_ID              NUMBER(9)                        not null,
   MODULE               VARCHAR(64)                      not null,
   KEY1                 VARCHAR(64)                      not null,
   KEY2                 VARCHAR(64)                      not null,
   KEY3                 VARCHAR(64)                      not null,
   SETTING_NAME         VARCHAR(64)                      not null,
   VALUE                VARCHAR(4000),
   constraint PK_APPLICATION_USER_PREFERENCE primary key (USER_ID, MODULE, KEY1, KEY2, KEY3, SETTING_NAME)
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


/*==============================================================*/
/* Table: APPLICATION_USER_ROLE                                 */
/*==============================================================*/


create table APPLICATION_USER_ROLE  (
   USER_ID              NUMBER(9)                        not null,
   ROLE_ID              NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_APPLICATION_USER_ROLE primary key (USER_ID, ROLE_ID)
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


/*==============================================================*/
/* Index: FK_APPLICATION_ROLE_ID                                */
/*==============================================================*/
create index FK_APPLICATION_ROLE_ID on APPLICATION_USER_ROLE (
   ROLE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: AREA                                                  */
/*==============================================================*/


create table AREA  (
   AREA_ID              NUMBER(9)                        not null,
   AREA_NAME            VARCHAR2(32)                     not null,
   AREA_ALIAS           VARCHAR2(32),
   AREA_DESC            VARCHAR2(256),
   AREA_INTERVAL        VARCHAR2(16),
   PROJECTION_PERIOD    VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_AREA primary key (AREA_ID)
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


alter table AREA
   add constraint AK_AREA unique (AREA_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: AREA_LOAD                                             */
/*==============================================================*/


create table AREA_LOAD  (
   CASE_ID              NUMBER(9)                        not null,
   AREA_ID              NUMBER(9)                        not null,
   LOAD_CODE            CHAR(1)                          not null,
   LOAD_DATE            DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   LOAD_VAL             NUMBER(14,4),
   constraint PK_AREA_LOAD primary key (CASE_ID, AREA_ID, LOAD_CODE, LOAD_DATE, AS_OF_DATE)
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


/*==============================================================*/
/* Table: AREA_LOAD_PROJECTION                                  */
/*==============================================================*/


create table AREA_LOAD_PROJECTION  (
   CASE_ID              NUMBER(9)                        not null,
   AREA_ID              NUMBER(9)                        not null,
   LOAD_DATE            DATE                             not null,
   LOAD_MIN             NUMBER(8,2),
   LOAD_MAX             NUMBER(8,2),
   LOAD_AVG             NUMBER(8,2),
   HISTORICAL_BEGIN_DATE DATE,
   HISTORICAL_END_DATE  DATE,
   HISTORICAL_MIN       NUMBER(8,2),
   HISTORICAL_MAX       NUMBER(8,2),
   HISTORICAL_AVG       NUMBER(8,2),
   HISTORICAL_SUM       NUMBER(12,2),
   HISTORICAL_CNT       NUMBER(8),
   HISTORICAL_FACTOR    NUMBER(8,6),
   ENTRY_DATE           DATE,
   constraint PK_AREA_LOAD_PROJECTION primary key (CASE_ID, AREA_ID, LOAD_DATE)
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


/*==============================================================*/
/* Table: AUDIT_CHANGE_COMMENT                                  */
/*==============================================================*/


create table AUDIT_CHANGE_COMMENT  (
   ZAU_ID               NUMBER(18)                       not null,
   WHY_CHANGED          VARCHAR2(4000)                   not null,
   constraint PK_AUDIT_CHANGE_COMMENT primary key (ZAU_ID)
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


/*==============================================================*/
/* Table: AUDIT_TRAIL_WORK                                      */
/*==============================================================*/


create global temporary table AUDIT_TRAIL_WORK  (
   WORK_ID              NUMBER(9)                        not null,
   AUDIT_DATE           DATE,
   ENTITY_DOMAIN_ID     NUMBER(9),
   NUM_CHANGES          NUMBER(9),
   ENTITY_ID            NUMBER(9),
   USER_ID              NUMBER(9),
   SYSTEM_TABLE_NAME    VARCHAR2(128),
   SYSTEM_TABLE_ID      NUMBER(9)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: BACKGROUND_BLOB_STAGING                               */
/*==============================================================*/


create table BACKGROUND_BLOB_STAGING  (
   BACKGROUND_LOB_ID    NUMBER(9)                        not null,
   BLOB_VAL             BLOB,
   ENTRY_DATE           DATE,
   constraint PK_BACKGROUND_BLOB_STAGING primary key (BACKGROUND_LOB_ID)
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


/*==============================================================*/
/* Table: BACKGROUND_CLOB_STAGING                               */
/*==============================================================*/


create table BACKGROUND_CLOB_STAGING  (
   BACKGROUND_LOB_ID    NUMBER(9)                        not null,
   CLOB_VAL             CLOB,
   ENTRY_DATE           DATE,
   constraint PK_BACKGROUND_CLOB_STAGING primary key (BACKGROUND_LOB_ID)
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

/*==============================================================*/
/* Table: BILL_CASE                                             */
/*==============================================================*/

CREATE TABLE BILL_CASE (
  BILL_CASE_ID                   NUMBER(9)        NOT NULL,
  BILL_CASE_NAME                 VARCHAR2(128)    NOT NULL,
  BILL_CASE_ALIAS                VARCHAR2(32),
  BILL_CASE_DESC                 VARCHAR2(256),
  BILL_CASE_EXT_IDENTIFIER       VARCHAR2(256),
  SENDER_PSE_ID                  NUMBER(9)        NOT NULL,
  PRODUCT_CATEGORY               VARCHAR2(32)     NOT NULL,
  STATEMENT_TYPE_ID              NUMBER(9)        NOT NULL,
  PERIOD_BEGIN_DATE              DATE             NOT NULL,
  PERIOD_END_DATE                DATE             NOT NULL,
  BILL_CASE_STATUS               VARCHAR2(32)     NOT NULL,
  RUN_TYPE                       VARCHAR2(32)     NOT NULL,
  RUN_STATUS                     VARCHAR2(32),
  RUN_DATE                       DATE,
  RUN_BY                         VARCHAR2(64),
  APPROVAL_STATE                 VARCHAR2(32),
  APPROVAL_DATE                  DATE,
  APPROVAL_BY                    VARCHAR2(64),
  RELEASE_STATE                  VARCHAR2(32),
  RELEASE_DATE                   DATE,
  RELEASE_BY                     VARCHAR2(64),
  CONSTRAINT PK_BILL_CASE PRIMARY KEY (BILL_CASE_ID)
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

comment on table BILL_CASE
  is 'CSB Bill Case Management table.'
/  
comment on column BILL_CASE.BILL_CASE_ID
  is 'Auto-generated unique ID for a Bill Case.'
/  
comment on column BILL_CASE.BILL_CASE_NAME
  is 'Unique name of a Bill Case.'
/  
comment on column BILL_CASE.BILL_CASE_ALIAS
  is 'Alias of a Bill Case.'
/  
comment on column BILL_CASE.BILL_CASE_DESC
  is 'User description of a Bill Case.'
/  
comment on column BILL_CASE.BILL_CASE_EXT_IDENTIFIER
  is 'External Identifier for a Bill Case.'
/  
comment on column BILL_CASE.SENDER_PSE_ID
  is 'ID of a PURCHASING_SELLING_ENTITY with Type of Billing Agent.'
/  
comment on column BILL_CASE.PRODUCT_CATEGORY
  is 'This is the scheme for a Bill Case.  It is one of the categories defined for a Product.'
/  
comment on column BILL_CASE.STATEMENT_TYPE_ID
  is 'ID of a Statement Type for a Bill Case.'
/  
comment on column BILL_CASE.PERIOD_BEGIN_DATE
  is 'The start date for a Bill Case.'
/  
comment on column BILL_CASE.PERIOD_END_DATE
  is 'The end date for a Bill Case.'
/  
comment on column BILL_CASE.BILL_CASE_STATUS
  is 'The status of a Bill Case.'
/  
comment on column BILL_CASE.RUN_TYPE
  is 'The Run Type for a Bill Case (Global, Partial - Include, Partial - Exclude).'
/  
comment on column BILL_CASE.RUN_STATUS
  is 'The status for a Bill Case (Success).'
/  
comment on column BILL_CASE.RUN_DATE
  is 'When a Bill Case was run.'
/  
comment on column BILL_CASE.RUN_BY
  is 'Who ran a Bill Case.'
/  
comment on column BILL_CASE.APPROVAL_STATE
  is 'The approval status of a Bill Case (Approved).'
/  
comment on column BILL_CASE.APPROVAL_DATE
  is 'When a Bill Case was approved.'
/  
comment on column BILL_CASE.APPROVAL_BY
  is 'Who approved a Bill Case.'
/  
comment on column BILL_CASE.RELEASE_STATE
  is 'The release status of a Bill Case (Unreleased, Released).'
/  
comment on column BILL_CASE.RELEASE_DATE
  is 'When a Bill Case was released.'
/  
comment on column BILL_CASE.RELEASE_BY
  is 'Who released a Bill Case.'
/

/*==============================================================*/
/* Global Temporary Table for CSB                               */
/*==============================================================*/;
CREATE GLOBAL TEMPORARY TABLE CSB_ACCOUNT_ESP_TEMP
(
  ACCOUNT_ID NUMBER(9) NOT NULL, 
  ESP_ID NUMBER(9) NOT NULL, 
  POOL_ID NUMBER(9) NOT NULL, 
  BEGIN_DATE DATE NOT NULL, 
  END_DATE DATE, 
  ESP_ACCOUNT_NUMBER VARCHAR2(32)
)
ON COMMIT PRESERVE ROWS
/

ALTER TABLE CSB_ACCOUNT_ESP_TEMP
  ADD CONSTRAINT PK_CSB_ACCOUNT_ESP_TEMP PRIMARY KEY (ACCOUNT_ID, BEGIN_DATE)
/
  
CREATE GLOBAL TEMPORARY TABLE CSB_ACCOUNT_STATUS_TEMP
(
  ACCOUNT_ID  NUMBER(9) NOT NULL,
  BEGIN_DATE  DATE NOT NULL,
  END_DATE    DATE,
  STATUS_NAME VARCHAR2(16)
)
ON COMMIT PRESERVE ROWS
/

ALTER TABLE CSB_ACCOUNT_STATUS_TEMP
  ADD CONSTRAINT PK_CSB_ACCOUNT_STATUS_TEMP PRIMARY KEY (ACCOUNT_ID, BEGIN_DATE)
/
  
CREATE GLOBAL TEMPORARY TABLE CSB_AAS_MEC_TEMP
(
  ACCOUNT_ID  NUMBER(9) NOT NULL,
  BEGIN_DATE  DATE NOT NULL,
  END_DATE    DATE
)
ON COMMIT PRESERVE ROWS
/

-- CREATE/RECREATE PRIMARY, UNIQUE AND FOREIGN KEY CONSTRAINTS 
ALTER TABLE CSB_AAS_MEC_TEMP
  ADD CONSTRAINT PK_CSB_AAS_MEC_TEMP PRIMARY KEY (ACCOUNT_ID, BEGIN_DATE)
/
  
CREATE GLOBAL TEMPORARY TABLE CSB_AAS_MIC_TEMP
(
  ACCOUNT_ID  NUMBER(9) NOT NULL,
  BEGIN_DATE  DATE NOT NULL,
  END_DATE    DATE
)
ON COMMIT PRESERVE ROWS
/

ALTER TABLE CSB_AAS_MIC_TEMP
  ADD CONSTRAINT PK_CSB_AAS_MIC_TEMP PRIMARY KEY (ACCOUNT_ID, BEGIN_DATE)
/
  
CREATE GLOBAL TEMPORARY TABLE CSB_PRODUCT_COMP_TEMP
(
  PRODUCT_ID NUMBER(9),
  COMPONENT_ID NUMBER(9),
  PRODUCT_EXTERNAL_IDENTIFIER  VARCHAR2(32) NOT NULL,
  PRODUCT_BEGIN_DATE  	DATE,
  PRODUCT_END_DATE    	DATE,
  PC_BEGIN_DATE  DATE,
  PC_END_DATE    DATE,
  COMP_CHARGE_TYPE  VARCHAR2(32)
)
ON COMMIT PRESERVE ROWS
/

/*==============================================================*/
/* Table: BILL_CASE_SELECTIONS                                  */
/*==============================================================*/

CREATE TABLE BILL_CASE_SELECTIONS (
  BILL_CASE_SELECTIONS_ID        NUMBER(9)        NOT NULL,
  BILL_CASE_ID                   NUMBER(9)        NOT NULL,
  PSE_ID                         NUMBER(9),
  ACCOUNT_ID                     NUMBER(9),
  PRODUCT_ID                     NUMBER(9),
  COMPONENT_ID                   NUMBER(9),
  CONSTRAINT PK_BC_SELECTIONS PRIMARY KEY (BILL_CASE_SELECTIONS_ID)
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

comment on table BILL_CASE_SELECTIONS
  is 'CSB Bill Case Selections Management table.'
/  
comment on column BILL_CASE_SELECTIONS.BILL_CASE_SELECTIONS_ID
  is 'Auto-generated unique ID for a Bill Case Selection.'
/  
comment on column BILL_CASE_SELECTIONS.BILL_CASE_ID
  is 'ID of Bill Case for selection.'
/
comment on column BILL_CASE_SELECTIONS.PSE_ID
  is 'ID of PSE for selection.'
/
comment on column BILL_CASE_SELECTIONS.ACCOUNT_ID
  is 'ID of Account for selection.'
/
comment on column BILL_CASE_SELECTIONS.PRODUCT_ID
  is 'ID of Product for selection.'
/
comment on column BILL_CASE_SELECTIONS.COMPONENT_ID
  is 'ID of Component for selection.'
/

/*==============================================================*/
/* Table: BILL_CASE_INVOICE                                     */
/*==============================================================*/

CREATE TABLE BILL_CASE_INVOICE
(BILL_CASE_ID 		NUMBER(9,0),
 RETAIL_INVOICE_ID	NUMBER(9,0)
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: BILLING_CHARGE                                        */
/*==============================================================*/


create table BILLING_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   PEAK_DATE            DATE,
   PEAK_QUANTITY        NUMBER(12,4),
   SERVICE_POINT_ID     NUMBER(9),
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_BILLING_CHARGE primary key (CHARGE_ID, CHARGE_DATE)
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


/*==============================================================*/
/* Table: BILLING_CHARGE_DISPUTE                                */
/*==============================================================*/


create table BILLING_CHARGE_DISPUTE
(
  ENTITY_ID         NUMBER(9) not null,
  PRODUCT_ID        NUMBER(9) not null,
  COMPONENT_ID      NUMBER(9) not null,
  STATEMENT_TYPE    NUMBER(9) not null,
  STATEMENT_STATE   NUMBER(1) not null,
  STATEMENT_DATE    DATE not null,
  DISPUTE_DATE      DATE not null,
  ITERATOR1         VARCHAR2(256),
  ITERATOR2         VARCHAR2(256),
  ITERATOR3         VARCHAR2(256),
  ITERATOR4         VARCHAR2(256),
  ITERATOR5         VARCHAR2(256),
  ITERATOR6         VARCHAR2(256),
  ITERATOR7         VARCHAR2(256),
  ITERATOR8         VARCHAR2(256),
  ITERATOR9         VARCHAR2(256),
  ITERATOR10        VARCHAR2(256),
  DISPUTE_STATUS    VARCHAR2(16),
  SUBMIT_STATUS     VARCHAR2(16),
  MARKET_STATUS     VARCHAR2(16),
  OLD_BILL_AMOUNT   NUMBER(12,2),
  NEW_BILL_AMOUNT   NUMBER(12,2),
  OLD_BILL_QUANTITY NUMBER(18,9),
  NEW_BILL_QUANTITY NUMBER(18,9),
  DISPUTE_DESC      VARCHAR2(256),
  ENTRY_DATE        DATE
)
  storage
  (
    initial 128K
    next 128K
    pctincrease 0
)
  tablespace NERO_DATA
/

alter table BILLING_CHARGE_DISPUTE
   add constraint AK_BILLING_CHRG_DSPT unique (ENTITY_ID, PRODUCT_ID, COMPONENT_ID, STATEMENT_TYPE, STATEMENT_STATE, STATEMENT_DATE, DISPUTE_DATE,ITERATOR1, ITERATOR2, ITERATOR3, ITERATOR4, ITERATOR5, ITERATOR6, ITERATOR7, ITERATOR8, ITERATOR9, ITERATOR10)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Index: FK_BILLING_CHRG_DSPT_COMP                             */
/*==============================================================*/
create index FK_BILLING_CHRG_DSPT_COMP on BILLING_CHARGE_DISPUTE (
   COMPONENT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_BILLING_CHRG_DSPT_PROD                             */
/*==============================================================*/
create index FK_BILLING_CHRG_DSPT_PROD on BILLING_CHARGE_DISPUTE (
   PRODUCT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_BILLING_CHRG_DSPT_STMT                             */
/*==============================================================*/
create index FK_BILLING_CHRG_DSPT_STMT on BILLING_CHARGE_DISPUTE (
   STATEMENT_TYPE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: BILLING_STATEMENT                                     */
/*==============================================================*/


create table BILLING_STATEMENT  (
   ENTITY_ID            NUMBER(9)                        not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   STATEMENT_TYPE       NUMBER(9)                        not null,
   STATEMENT_STATE      NUMBER(1)                        not null,
   STATEMENT_DATE       DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   STATEMENT_END_DATE   DATE,
   BASIS_AS_OF_DATE     DATE,
   IN_DISPUTE           NUMBER(1),
   CHARGE_INTERVAL      VARCHAR2(16),
   CHARGE_VIEW_TYPE     VARCHAR2(16),
   ENTITY_TYPE          VARCHAR2(16),
   CHARGE_QUANTITY      NUMBER(12,2),
   CHARGE_RATE          NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(12,2),
   BILL_AMOUNT          NUMBER(12,2),
   PRIOR_PERIOD_QUANTITY NUMBER(12,2),
   CHARGE_ID            NUMBER(12)                       not null,
   ENTRY_DATE           DATE,
   LOCK_STATE           CHAR(1),
   constraint PK_BILLING_STATEMENT primary key (ENTITY_ID, STATEMENT_TYPE, STATEMENT_STATE, STATEMENT_DATE, COMPONENT_ID, PRODUCT_ID, AS_OF_DATE)
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


alter table BILLING_STATEMENT
   add constraint AK_BILLING_STATEMENT unique (CHARGE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_BILLING_STMT_COMPONENT                             */
/*==============================================================*/
create index FK_BILLING_STMT_COMPONENT on BILLING_STATEMENT (
   COMPONENT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_BILLING_STMT_PRODUCT                               */
/*==============================================================*/
create index FK_BILLING_STMT_PRODUCT on BILLING_STATEMENT (
   PRODUCT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_BILLING_STMT_STMT_TYPE                             */
/*==============================================================*/
create index FK_BILLING_STMT_STMT_TYPE on BILLING_STATEMENT (
   STATEMENT_TYPE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: BILLING_STATEMENT_ERRS_TMP                            */
/*==============================================================*/


create global temporary table BILLING_STATEMENT_ERRS_TMP  (
   ORA_ERR_NUMBER$      NUMBER,
   ORA_ERR_MESG$        VARCHAR2(2000),
   ORA_ERR_ROWID$       ROWID,
   ORA_ERR_OPTYP$       VARCHAR2(2),
   ORA_ERR_TAG$         VARCHAR2(2000),
   ENTITY_ID            VARCHAR2(4000),
   PRODUCT_ID           VARCHAR2(4000),
   COMPONENT_ID         VARCHAR2(4000),
   STATEMENT_TYPE       VARCHAR2(4000),
   STATEMENT_STATE      VARCHAR2(4000),
   STATEMENT_DATE       VARCHAR2(4000),
   AS_OF_DATE           VARCHAR2(4000),
   STATEMENT_END_DATE   VARCHAR2(4000),
   BASIS_AS_OF_DATE     VARCHAR2(4000),
   IN_DISPUTE           VARCHAR2(4000),
   CHARGE_INTERVAL      VARCHAR2(4000),
   CHARGE_VIEW_TYPE     VARCHAR2(4000),
   ENTITY_TYPE          VARCHAR2(4000),
   CHARGE_QUANTITY      VARCHAR2(4000),
   CHARGE_RATE          VARCHAR2(4000),
   CHARGE_AMOUNT        VARCHAR2(4000),
   BILL_QUANTITY        VARCHAR2(4000),
   BILL_AMOUNT          VARCHAR2(4000),
   PRIOR_PERIOD_QUANTITY VARCHAR2(4000),
   CHARGE_ID            VARCHAR2(4000),
   ENTRY_DATE           VARCHAR2(4000),
   LOCK_STATE           VARCHAR2(4000)
)
/


/*==============================================================*/
/* Index: BILLING_STATEMENT_ERR_TMP_IX01                        */
/*==============================================================*/
create index BILLING_STATEMENT_ERR_TMP_IX01 on BILLING_STATEMENT_ERRS_TMP (
   ORA_ERR_TAG$ ASC
)
/


/*==============================================================*/
/* Table: BILLING_STATEMENT_LOCK_SUMMARY                        */
/*==============================================================*/


create table BILLING_STATEMENT_LOCK_SUMMARY  (
   ENTITY_ID            NUMBER(9)                        not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   STATEMENT_TYPE       NUMBER(9)                        not null,
   STATEMENT_STATE      NUMBER(1)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOCK_STATE           CHAR(1) DEFAULT 'U'              not null,
   constraint PK_BILL_STATEMENT_LOCK_SUMMARY primary key (ENTITY_ID, STATEMENT_TYPE, STATEMENT_STATE, COMPONENT_ID, PRODUCT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Index: FK_BILLING_STMT_LK_S_COMPONENT                        */
/*==============================================================*/
create index FK_BILLING_STMT_LK_S_COMPONENT on BILLING_STATEMENT_LOCK_SUMMARY (
   COMPONENT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_BILLING_STMT_LK_S_PRODUCT                          */
/*==============================================================*/
create index FK_BILLING_STMT_LK_S_PRODUCT on BILLING_STATEMENT_LOCK_SUMMARY (
   PRODUCT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_BILLING_STMT_LK_S_STMT_TYPE                        */
/*==============================================================*/
create index FK_BILLING_STMT_LK_S_STMT_TYPE on BILLING_STATEMENT_LOCK_SUMMARY (
   STATEMENT_TYPE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: BILLING_STATEMENT_STATUS                              */
/*==============================================================*/


create table BILLING_STATEMENT_STATUS  (
   ENTITY_ID            NUMBER(9)                        not null,
   STATEMENT_TYPE       NUMBER(9)                        not null,
   STATEMENT_STATE      NUMBER(1)                        not null,
   STATEMENT_DATE       DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   REVIEW_STATUS        VARCHAR2(16),
   NOTES                VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_BILLING_STATEMENT_STATUS primary key (ENTITY_ID, STATEMENT_TYPE, STATEMENT_STATE, STATEMENT_DATE, AS_OF_DATE)
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


/*==============================================================*/
/* Index: FK_BILLING_STMT_STATUS_STMT                           */
/*==============================================================*/
create index FK_BILLING_STMT_STATUS_STMT on BILLING_STATEMENT_STATUS (
   STATEMENT_TYPE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: BILL_CYCLE                                            */
/*==============================================================*/


create table BILL_CYCLE  (
   BILL_CYCLE_ID        NUMBER(9)                        not null,
   BILL_CYCLE_NAME      VARCHAR2(32)                     not null,
   BILL_CYCLE_ALIAS     VARCHAR2(32),
   BILL_CYCLE_DESC      VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_BILL_CYCLE primary key (BILL_CYCLE_ID)
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


alter table BILL_CYCLE
   add constraint AK_BILL_CYCLE unique (BILL_CYCLE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: BILL_CYCLE_PERIOD                                     */
/*==============================================================*/


create table BILL_CYCLE_PERIOD  (
   BILL_CYCLE_ID        NUMBER(9)                        not null,
   BILL_CYCLE_MONTH     DATE                             not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   ENTRY_DATE           DATE,
   constraint PK_BILL_CYCLE_PERIOD primary key (BILL_CYCLE_ID, BILL_CYCLE_MONTH, BEGIN_DATE)
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


/*==============================================================*/
/* Table: BILL_PARTY                                            */
/*==============================================================*/


create table BILL_PARTY  (
   BILL_PARTY_ID        NUMBER(9)                        not null,
   BILL_PARTY_NAME      VARCHAR(32)                      not null,
   BILL_PARTY_ALIAS     VARCHAR(32),
   BILL_PARTY_DESC      VARCHAR(256),
   BILL_PARTY_STATUS    VARCHAR(16),
   EXTERNAL_IDENTIFIER  VARCHAR(32),
   IS_INVOICE_DETAIL    NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_BILL_PARTY primary key (BILL_PARTY_ID)
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


alter table BILL_PARTY
   add constraint AK_BILL_PARTY unique (BILL_PARTY_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: BREAKPOINT                                            */
/*==============================================================*/


create table BREAKPOINT  (
   BREAKPOINT_ID        NUMBER(9)                        not null,
   BREAKPOINT_NAME      VARCHAR(32)                      not null,
   BREAKPOINT_ALIAS     VARCHAR(32),
   BREAKPOINT_DESC      VARCHAR(256),
   ENTRY_DATE           DATE,
   constraint PK_BREAKPOINT primary key (BREAKPOINT_ID)
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


alter table BREAKPOINT
   add constraint AK_BREAKPOINT unique (BREAKPOINT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: BREAKPOINT_VALUE                                      */
/*==============================================================*/


create table BREAKPOINT_VALUE  (
   BREAKPOINT_ID        NUMBER(9)                        not null,
   BREAKPOINT_HOUR      NUMBER(2)                        not null,
   BREAKPOINT_NBR       NUMBER(2)                        not null,
   BREAKPOINT_VAL       NUMBER(6,2),
   ENTRY_DATE           DATE,
   constraint PK_BREAKPOINT_VALUE primary key (BREAKPOINT_ID, BREAKPOINT_HOUR, BREAKPOINT_NBR)
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


/*==============================================================*/
/* Table: CALCULATION_PROCESS                                   */
/*==============================================================*/


create table CALCULATION_PROCESS  (
   CALC_PROCESS_ID      NUMBER(9)                        not null,
   CALC_PROCESS_NAME    VARCHAR2(64)                     not null,
   CALC_PROCESS_ALIAS   VARCHAR2(32),
   CALC_PROCESS_DESC    VARCHAR2(512),
   CALC_PROCESS_CATEGORY VARCHAR2(64),
   TIME_ZONE            VARCHAR2(8),
   PROCESS_INTERVAL     VARCHAR2(16),
   WEEK_BEGIN           VARCHAR2(16),
   CONTEXT_DOMAIN_ID    NUMBER(9),
   CONTEXT_REALM_ID     NUMBER(9),
   CONTEXT_GROUP_ID     NUMBER(9),
   CONTEXT_NAME         VARCHAR2(32),
   IS_STATEMENT_TYPE_SPECIFIC NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_CALCULATION_PROCESS primary key (CALC_PROCESS_ID)
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


alter table CALCULATION_PROCESS
   add constraint CK01_CALCULATION_PROCESS_GROUP check ((NVL(CONTEXT_DOMAIN_ID,0) = 0 AND CONTEXT_REALM_ID IS NULL AND CONTEXT_GROUP_ID IS NULL)
																					OR (NVL(CONTEXT_DOMAIN_ID,0) <> 0 AND CONTEXT_REALM_ID IS NULL AND CONTEXT_GROUP_ID IS NOT NULL)
																					OR (NVL(CONTEXT_DOMAIN_ID,0) <> 0 AND CONTEXT_REALM_ID IS NOT NULL AND CONTEXT_GROUP_ID IS NULL))
/


alter table CALCULATION_PROCESS
   add constraint AK_CALCULATION_PROCESS unique (CALC_PROCESS_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_CALCULATION_PROCESS_DOMAIN                         */
/*==============================================================*/
create index FK_CALCULATION_PROCESS_DOMAIN on CALCULATION_PROCESS (
   CONTEXT_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_CALCULATION_PROCESS_GROUP                          */
/*==============================================================*/
create index FK_CALCULATION_PROCESS_GROUP on CALCULATION_PROCESS (
   CONTEXT_GROUP_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_CALCULATION_PROCESS_REALM                          */
/*==============================================================*/
create index FK_CALCULATION_PROCESS_REALM on CALCULATION_PROCESS (
   CONTEXT_REALM_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: CALCULATION_PROCESS_GLOBAL                            */
/*==============================================================*/


create table CALCULATION_PROCESS_GLOBAL  (
   CALC_PROCESS_ID      NUMBER(9)                        not null,
   GLOBAL_NAME          VARCHAR2(32)                     not null,
   FORMULA              VARCHAR2(4000)                   not null,
   COMMENTS             VARCHAR2(2000),
   ROW_NUMBER           NUMBER(4),
   PERSIST_VALUE        NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_CALCULATION_PROCESS_GLOBAL primary key (CALC_PROCESS_ID, GLOBAL_NAME)
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


/*==============================================================*/
/* Table: CALCULATION_PROCESS_SECURITY                          */
/*==============================================================*/


create table CALCULATION_PROCESS_SECURITY  (
   CALC_PROCESS_ID      NUMBER(9)                        not null,
   SELECT_ACTION_ID     NUMBER(9),
   RUN_ACTION_ID        NUMBER(9),
   PURGE_ACTION_ID      NUMBER(9),
   LOCK_STATE_ACTION_ID NUMBER(9),
   constraint PK_CALC_PROCESS_SECURITY primary key (CALC_PROCESS_ID)
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


/*==============================================================*/
/* Index: FK_CALC_PROC_SECURITY_ACTION1                         */
/*==============================================================*/
create index FK_CALC_PROC_SECURITY_ACTION1 on CALCULATION_PROCESS_SECURITY (
   SELECT_ACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_CALC_PROC_SECURITY_ACTION2                         */
/*==============================================================*/
create index FK_CALC_PROC_SECURITY_ACTION2 on CALCULATION_PROCESS_SECURITY (
   RUN_ACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_CALC_PROC_SECURITY_ACTION3                         */
/*==============================================================*/
create index FK_CALC_PROC_SECURITY_ACTION3 on CALCULATION_PROCESS_SECURITY (
   PURGE_ACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: CALCULATION_PROCESS_STEP                              */
/*==============================================================*/


create table CALCULATION_PROCESS_STEP  (
   CALC_STEP_ID         NUMBER(9)                        not null,
   CALC_PROCESS_ID      NUMBER(9)                        not null,
   STEP_NUMBER          NUMBER(4)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   COMPONENT_ID         NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_CALCULATION_PROCESS_STEP primary key (CALC_STEP_ID)
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


alter table CALCULATION_PROCESS_STEP
   add constraint AK_CALCULATION_PROCESS_STEP unique (CALC_PROCESS_ID, STEP_NUMBER, BEGIN_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_CALCULATION_PROC_STEP_COMP                         */
/*==============================================================*/
create index FK_CALCULATION_PROC_STEP_COMP on CALCULATION_PROCESS_STEP (
   COMPONENT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: CALCULATION_PROCESS_STEP_PARM                         */
/*==============================================================*/


create table CALCULATION_PROCESS_STEP_PARM  (
   CALC_STEP_ID         NUMBER(9)                        not null,
   PARAMETER_NAME       VARCHAR2(32)                     not null,
   FORMULA              VARCHAR2(4000)                   not null,
   COMMENTS             VARCHAR2(2000),
   ROW_NUMBER           NUMBER(4),
   ENTRY_DATE           DATE,
   constraint PK_CALCULATION_PROC_STEP_PARM primary key (CALC_STEP_ID, PARAMETER_NAME)
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


/*==============================================================*/
/* Table: CALCULATION_RUN                                       */
/*==============================================================*/


create table CALCULATION_RUN  (
   CALC_RUN_ID          NUMBER(12)                       not null,
   CALC_PROCESS_ID      NUMBER(9)                        not null,
   RUN_DATE             DATE                             not null,
   STATEMENT_TYPE_ID    NUMBER(9),
   CONTEXT_ENTITY_ID    NUMBER(9),
   START_TIME           DATE                             not null,
   END_TIME             DATE,
   PROCESS_ID           NUMBER(12)                       not null,
   LOCK_STATE           CHAR(1),
   constraint PK_CALCULATION_RUN primary key (CALC_RUN_ID)
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


alter table CALCULATION_RUN
   add constraint AK_CALCULATION_RUN unique (CALC_PROCESS_ID, RUN_DATE, STATEMENT_TYPE_ID, CONTEXT_ENTITY_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_CALCULATION_RUN_PROCESS_LOG                        */
/*==============================================================*/
create index FK_CALCULATION_RUN_PROCESS_LOG on CALCULATION_RUN (
   PROCESS_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_CALCULATION_RUN_STMNT_TYPE                         */
/*==============================================================*/
create index FK_CALCULATION_RUN_STMNT_TYPE on CALCULATION_RUN (
   STATEMENT_TYPE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: CALCULATION_RUN_ERRS_TMP                              */
/*==============================================================*/


create global temporary table CALCULATION_RUN_ERRS_TMP  (
   ORA_ERR_NUMBER$      NUMBER,
   ORA_ERR_MESG$        VARCHAR2(2000),
   ORA_ERR_ROWID$       ROWID,
   ORA_ERR_OPTYP$       VARCHAR2(2),
   ORA_ERR_TAG$         VARCHAR2(2000),
   CALC_RUN_ID          VARCHAR2(4000),
   CALC_PROCESS_ID      VARCHAR2(4000),
   RUN_DATE             VARCHAR2(4000),
   STATEMENT_TYPE_ID    VARCHAR2(4000),
   CONTEXT_ENTITY_ID    VARCHAR2(4000),
   START_TIME           VARCHAR2(4000),
   END_TIME             VARCHAR2(4000),
   PROCESS_ID           VARCHAR2(4000),
   LOCK_STATE           VARCHAR2(4000)
)
/


/*==============================================================*/
/* Index: CALCULATION_RUN_ERRS_TMP_IX01                         */
/*==============================================================*/
create index CALCULATION_RUN_ERRS_TMP_IX01 on CALCULATION_RUN_ERRS_TMP (
   ORA_ERR_TAG$ ASC
)
/


/*==============================================================*/
/* Table: CALCULATION_RUN_GLOBAL                                */
/*==============================================================*/


create table CALCULATION_RUN_GLOBAL  (
   CALC_RUN_ID          NUMBER(12)                       not null,
   GLOBAL_NAME          VARCHAR2(32)                     not null,
   GLOBAL_VAL           VARCHAR2(256),
   ROW_NUMBER           NUMBER(4),
   constraint PK_CALCULATION_RUN_GLOBAL primary key (CALC_RUN_ID, GLOBAL_NAME)
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


/*==============================================================*/
/* Table: CALCULATION_RUN_LOCK_SUMMARY                          */
/*==============================================================*/


create table CALCULATION_RUN_LOCK_SUMMARY  (
   CALC_PROCESS_ID      NUMBER(9)                        not null,
   STATEMENT_TYPE_ID    NUMBER(9),
   CONTEXT_ENTITY_ID    NUMBER(9),
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOCK_STATE           CHAR(1) DEFAULT 'U'              not null
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


alter table CALCULATION_RUN_LOCK_SUMMARY
   add constraint AK_CALCULATION_RUN_LCK_SUMMARY unique (CALC_PROCESS_ID, STATEMENT_TYPE_ID, CONTEXT_ENTITY_ID, BEGIN_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_CALC_RUN_LOCK_S_STMNT_TYPE                         */
/*==============================================================*/
create index FK_CALC_RUN_LOCK_S_STMNT_TYPE on CALCULATION_RUN_LOCK_SUMMARY (
   STATEMENT_TYPE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: CALCULATION_RUN_STEP                                  */
/*==============================================================*/


create table CALCULATION_RUN_STEP  (
   CHARGE_ID            NUMBER(12)                       not null,
   CALC_RUN_ID          NUMBER(12)                       not null,
   STEP_NUMBER          VARCHAR2(32)                     not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   START_TIME           DATE                             not null,
   END_TIME             DATE,
   constraint PK_CALCULATION_RUN_STEP primary key (CHARGE_ID)
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


alter table CALCULATION_RUN_STEP
   add constraint AK_CALCULATION_RUN_STEP unique (CALC_RUN_ID, STEP_NUMBER)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_CALCULATION_RUN_STEP_COMP                          */
/*==============================================================*/
create index FK_CALCULATION_RUN_STEP_COMP on CALCULATION_RUN_STEP (
   COMPONENT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: CALCULATION_RUN_STEP_PARM                             */
/*==============================================================*/


create table CALCULATION_RUN_STEP_PARM  (
   CHARGE_ID            NUMBER(12)                       not null,
   PARAMETER_NAME       VARCHAR2(32)                     not null,
   PARAMETER_VAL        VARCHAR2(256),
   ROW_NUMBER           NUMBER(4),
   constraint PK_CALCULATION_RUN_STEP_PARM primary key (CHARGE_ID, PARAMETER_NAME)
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


/*==============================================================*/
/* Table: CALENDAR                                              */
/*==============================================================*/


create table CALENDAR  (
   CALENDAR_ID          NUMBER(9)                        not null,
   CALENDAR_NAME        VARCHAR2(130)                     not null,
   CALENDAR_ALIAS       VARCHAR2(130),
   CALENDAR_DESC        VARCHAR2(256),
   ASSIGNMENT_TYPE      CHAR(1),
   HAS_ADJUSTMENTS      NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_CALENDAR primary key (CALENDAR_ID)
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


alter table CALENDAR
   add constraint AK_CALENDAR unique (CALENDAR_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CALENDAR_ADJUSTMENT                                   */
/*==============================================================*/


create table CALENDAR_ADJUSTMENT  (
   CALENDAR_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ADJ_OP               CHAR(1),
   ADJ_VAL              NUMBER(8,4),
   ENTRY_DATE           DATE,
   constraint PK_CALENDAR_ADJUSTMENT primary key (CALENDAR_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CALENDAR_PROFILE                                      */
/*==============================================================*/


create table CALENDAR_PROFILE  (
   CALENDAR_ID          NUMBER(9)                        not null,
   PROFILE_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_CALENDAR_PROFILE primary key (CALENDAR_ID, PROFILE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Index: CALENDAR_PROFILE_IX01                                 */
/*==============================================================*/
create index CALENDAR_PROFILE_IX01 on CALENDAR_PROFILE (
   CALENDAR_ID ASC,
   BEGIN_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: CALENDAR_PROFILE_LIBRARY                              */
/*==============================================================*/


create table CALENDAR_PROFILE_LIBRARY  (
   CALENDAR_ID          NUMBER(9)                        not null,
   PROFILE_LIBRARY_ID   NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_CALENDAR_PROFILE_LIBRARY primary key (CALENDAR_ID, PROFILE_LIBRARY_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Index: CALENDAR_PROFILE_LIBRARY_IX01                         */
/*==============================================================*/
create index CALENDAR_PROFILE_LIBRARY_IX01 on CALENDAR_PROFILE_LIBRARY (
   CALENDAR_ID ASC,
   BEGIN_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Table: CALENDAR_PROFILE_VALUE                                */
/*==============================================================*/
create global temporary table CALENDAR_PROFILE_VALUE
(
  weather_station_id NUMBER(9) not null,
  calendar_id        NUMBER(9) not null,
  edc_id             NUMBER(9) not null,
  profile_date       DATE not null,
  profile_value      NUMBER not null
)
on commit preserve rows
/

comment on table CALENDAR_PROFILE_VALUE
  is 'Usage Factors Lookup Cache to be cleared for each user session.'
/  
comment on column CALENDAR_PROFILE_VALUE.weather_station_id
  is 'WEATHER_STATION_ID for the Weather Station associated to the Profile'
/  
comment on column CALENDAR_PROFILE_VALUE.calendar_id
  is 'CALENDAR_ID for the Calendar associated with the account for a particular day'
/  
comment on column CALENDAR_PROFILE_VALUE.edc_id
  is 'EDC_ID associated with the Holiday Set'
/  
comment on column CALENDAR_PROFILE_VALUE.profile_date
  is 'Date for the profile to be calculated'
/  
comment on column CALENDAR_PROFILE_VALUE.profile_value
  is 'Sum of all Profile Points for that particular day.'
/  

alter table CALENDAR_PROFILE_VALUE
  add constraint PK_CALENDAR_PROFILE_VALUE primary key (WEATHER_STATION_ID, CALENDAR_ID, EDC_ID, PROFILE_DATE)
/  


/*==============================================================*/
/* Table: CALENDAR_PROJECTION                                   */
/*==============================================================*/


create table CALENDAR_PROJECTION  (
   PROJECTION_ID        NUMBER(9)                        not null,
   CALENDAR_ID          NUMBER(9),
   PROJECTION_TYPE      VARCHAR2(16),
   TEMPLATE_ID          NUMBER(9),
   AS_OF_DATE           DATE,
   ENTRY_DATE           DATE,
   constraint PK_CALENDAR_PROJECTION primary key (PROJECTION_ID)
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


alter table CALENDAR_PROJECTION
   add constraint AK_CALENDAR_PROJECTION unique (CALENDAR_ID, PROJECTION_TYPE, TEMPLATE_ID, AS_OF_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CASE_LABEL                                            */
/*==============================================================*/


create table CASE_LABEL  (
   CASE_ID              NUMBER(9)                        not null,
   CASE_NAME            VARCHAR2(32)                     not null,
   CASE_ALIAS           VARCHAR2(32),
   CASE_DESC            VARCHAR2(256),
   CASE_CATEGORY        VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_CASE_LABEL primary key (CASE_ID)
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


alter table CASE_LABEL
   add constraint AK_CASE_LABEL unique (CASE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CATEGORY                                              */
/*==============================================================*/


create table CATEGORY  (
   CATEGORY_ID          NUMBER(9)                        not null,
   CATEGORY_NAME        VARCHAR2(32)                     not null,
   CATEGORY_ALIAS       VARCHAR2(32),
   CATEGORY_DESC        VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_CATEGORY primary key (CATEGORY_ID)
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


alter table CATEGORY
   add constraint AK_CATEGORY unique (CATEGORY_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CLOB_STAGING                                          */
/*==============================================================*/


create global temporary table CLOB_STAGING  (
   CLOB_IDENT           VARCHAR2(32)                     not null,
   CLOB_VAL             CLOB,
   constraint PK_CLOB_STAGING primary key (CLOB_IDENT)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: COMBINATION_CHARGE                                    */
/*==============================================================*/


create table COMBINATION_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   COMBINED_CHARGE_ID   NUMBER(12),
   CHARGE_VIEW_TYPE     VARCHAR2(16),
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   COMPONENT_AMOUNT     NUMBER(12,2),
   COEFFICIENT          NUMBER(18,9),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_COMPONENT_AMOUNT NUMBER(12,2),
   BILL_AMOUNT          NUMBER(12,2),
   ENTRY_DATE           DATE,
   constraint PK_COMBINATION_CHARGE primary key (CHARGE_ID, COMPONENT_ID, BEGIN_DATE)
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
       )
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
)
/


alter table COMBINATION_CHARGE
   add constraint AK_COMBINATION_CHARGE unique (COMBINED_CHARGE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: COMPONENT                                             */
/*==============================================================*/


create table COMPONENT  (
   COMPONENT_ID         NUMBER(9)                        not null,
   COMPONENT_NAME       VARCHAR2(256)                    not null,
   COMPONENT_ALIAS      VARCHAR2(32),
   COMPONENT_DESC       VARCHAR2(256),
   COMPONENT_ENTITY     VARCHAR2(16),
   CHARGE_TYPE          VARCHAR2(32),
   RATE_STRUCTURE       VARCHAR2(32),
   RATE_INTERVAL        VARCHAR2(16),
   IS_REBILL            NUMBER(1),
   IS_TAXED             NUMBER(1),
   IS_CUSTOM_CHARGE     NUMBER(1),
   IS_CREDIT_CHARGE     NUMBER(1),
   IS_INCLUDE_TX_LOSS   NUMBER(1),
   IS_INCLUDE_DX_LOSS   NUMBER(1),
   TEMPLATE_ID          NUMBER(9),
   MARKET_PRICE_ID      NUMBER(9),
   SERVICE_POINT_ID     NUMBER(9),
   MODEL_ID             NUMBER(9),
   EVENT_ID             NUMBER(9),
   COMPONENT_REFERENCE  VARCHAR2(64),
   INVOICE_GROUP_ID     NUMBER(9),
   INVOICE_GROUP_ORDER  NUMBER(3),
   COMPUTATION_ORDER    NUMBER(4),
   QUANTITY_UNIT        VARCHAR2(8),
   CURRENCY_UNIT        VARCHAR2(8),
   QUANTITY_TYPE        CHAR(1),
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   COMPONENT_CATEGORY   VARCHAR2(32),
   GL_DEBIT_ACCOUNT     VARCHAR2(32),
   GL_CREDIT_ACCOUNT    VARCHAR2(32),
   FIRM_NON_FIRM        VARCHAR2(32),
   EXCLUDE_FROM_INVOICE NUMBER(1),
   EXCLUDE_FROM_INVOICE_TOTAL NUMBER(1),
   IMBALANCE_TYPE       VARCHAR2(16),
   ACCUMULATION_PERIOD  NUMBER(6),
   BASE_COMPONENT_ID    NUMBER(9),
   BASE_LIMIT_ID        NUMBER(9),
   MARKET_TYPE          VARCHAR2(32),
   MARKET_PRICE_TYPE    VARCHAR2(32),
   WHICH_INTERVAL       VARCHAR2(16),
   LMP_PRICE_CALC       VARCHAR2(32),
   LMP_INCLUDE_EXT      NUMBER(1),
   LMP_INCLUDE_SALES    VARCHAR2(16),
   CHARGE_WHEN          VARCHAR2(16),
   BILATERALS_SIGN      NUMBER(1),
   LMP_COMMODITY_ID     NUMBER(9),
   LMP_BASE_COMMODITY_ID NUMBER(9),
   USE_ZONAL_PRICE      NUMBER(1),
   ALTERNATE_PRICE      VARCHAR2(32),
   ALTERNATE_PRICE_FUNCTION VARCHAR2(16),
   EXCLUDE_FROM_BILLING_EXPORT NUMBER(1),
   IS_DEFAULT_TEMPLATE 	NUMBER(1),
   KWH_MULTIPLIER		NUMBER(16,6),
   ANCILLARY_SERVICE_ID NUMBER(9),
   APPLY_RATE_FOR VARCHAR2(32),
   LOSS_ADJ_TYPE 	NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT primary key (COMPONENT_ID)
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


comment on table COMPONENT is
'Holds all of the data for Charge Components that is Rate Structure independent'
/


comment on column COMPONENT.COMPONENT_ID is
'Unique ID generated by OID'
/


comment on column COMPONENT.COMPONENT_NAME is
'Unique name for Charge Component'
/


comment on column COMPONENT.COMPONENT_ALIAS is
'Optional Charge Component Alias'
/


comment on column COMPONENT.COMPONENT_DESC is
'Optional Charge Component Description'
/


comment on column COMPONENT.COMPONENT_ENTITY is
'The intended Billing Entity Type: Account, Pool, or PSE'
/


comment on column COMPONENT.CHARGE_TYPE is
'Combined with Rate Structure, this determines how the charges are computed.
'
/


comment on column COMPONENT.RATE_STRUCTURE is
'Determines in which table the Rate inputs exist.
'
/


comment on column COMPONENT.RATE_INTERVAL is
'The interval of the Charge Component'
/


comment on column COMPONENT.IS_REBILL is
'Is this charge a re-billed charge?'
/


comment on column COMPONENT.IS_TAXED is
'Is this charge taxable by Tax Charge Components?
'
/


comment on column COMPONENT.IS_CUSTOM_CHARGE is
'Is this charge a custom charge?
'
/


comment on column COMPONENT.IS_CREDIT_CHARGE is
' Is this charge supposed to be a credit (instead of a debit)?'
/


comment on column COMPONENT.IS_INCLUDE_TX_LOSS is
'Should this charge include Transmission Losses?'
/


comment on column COMPONENT.IS_INCLUDE_DX_LOSS is
'Should this charge include Distribution Losses?
'
/


comment on column COMPONENT.TEMPLATE_ID is
'The ID of a Time Period Template (used for Time of Use Rate Structures)
'
/


comment on column COMPONENT.MARKET_PRICE_ID is
'The ID of a Market Rate (used for Market Rate Structures)
'
/


comment on column COMPONENT.SERVICE_POINT_ID is
'The ID of a Service Point where this charge applies'
/


comment on column COMPONENT.MODEL_ID is
'The value 1 or 2 – Electric or Gas
'
/


comment on column COMPONENT.EVENT_ID is
'The ID of a System Event with which this Charge Component is associated'
/


comment on column COMPONENT.COMPONENT_REFERENCE is
'The name of an OASIS Ancillary Service Type (used for Transmission Charge Types)
'
/


comment on column COMPONENT.INVOICE_GROUP_ID is
'The ID of an Invoice Group that determines the way this charge shows up on the invoice'
/


comment on column COMPONENT.INVOICE_GROUP_ORDER is
'The order in the Invoice Group in which this charge falls (charges are ordered on the invoice within their Invoice Groups by this Order field)
'
/


comment on column COMPONENT.QUANTITY_UNIT is
'The units of the Charge Quantity for this Charge Component'
/


comment on column COMPONENT.CURRENCY_UNIT is
'The units of the Charge Amount for this Charge Component. The Charge Rate has units of (Currency Unit / Quantity Unit) – e.g. $/MWH'
/


comment on column COMPONENT.QUANTITY_TYPE is
'Optional Service Load Type'
/


comment on column COMPONENT.EXTERNAL_IDENTIFIER is
'Optional Identifier to be used by External Rate Structure logic or Interfaces to External Systems
'
/


comment on column COMPONENT.COMPONENT_CATEGORY is
'Optional Label for Invoice Category'
/


comment on column COMPONENT.GL_DEBIT_ACCOUNT is
'Optional Associated Debit Account Number'
/


comment on column COMPONENT.GL_CREDIT_ACCOUNT is
'Optional Associated Credit Account Number
'
/


comment on column COMPONENT.FIRM_NON_FIRM is
'Determines whether the Component Charge is to be applied to Firm or Non-Firm only transactions (used for Transmission Charge Types)'
/


comment on column COMPONENT.EXCLUDE_FROM_INVOICE is
'Will this charge be excluded from an invoice? (Typically no)'
/


comment on column COMPONENT.EXCLUDE_FROM_INVOICE_TOTAL is
'Will this charge be excluded from the invoice’s total charge amount? (Typically no)'
/


comment on column COMPONENT.IMBALANCE_TYPE is
'When the Rate Structure is Imbalance, this field indicates the type of imbalance calculation to be performed.'
/


comment on column COMPONENT.MARKET_TYPE is
'Settlement Market (day-ahead, real-time) - for LMP Rate Structure'
/


comment on column COMPONENT.MARKET_PRICE_TYPE is
'Market Price Type to use - for LMP Rate Structure'
/


comment on column COMPONENT.WHICH_INTERVAL is
'If Statement Interval is less than Charge Interval, on which Statement Interval does this charge appear (First, Last, or All)? E.g. you have a Daily Statement and a Monthly Charge, so on which Daily Statement does the Monthly Charge show up - First Day, Last Day, or All Days of the Month?'
/


comment on column COMPONENT.LMP_PRICE_CALC is
'Price Calculation method for LMP Rate Structure: can be Normal, Weighted Average, or Normal Minus Weighted Average (to support PJM LMP charges).'
/


comment on column COMPONENT.LMP_INCLUDE_EXT is
'For LMP Charges: Should external bilaterals be included in purchases and sales?'
/


comment on column COMPONENT.LMP_INCLUDE_SALES is
'For LMP charges: Should Sales be included in bilateral calculations (since only Buyer pays charges for some charges in PJM)? Options include All, None, Internal Only, and External Only.'
/


comment on column COMPONENT.CHARGE_WHEN is
'For LMP charges: when should this charge be applied? Valid options are Always, Net Generation, and Net Load.'
/


comment on column COMPONENT.BILATERALS_SIGN is
'For LMP charges: In MISO Purchases and Sales are counted with signs that are negative of NYISO and PJM. This flag controls how to sign the bilaterals.'
/


comment on column COMPONENT.LMP_COMMODITY_ID is
'For LMP Commodity Charge: What commodity is being billed?'
/


comment on column COMPONENT.LMP_BASE_COMMODITY_ID is
'For LMP Commodity Charge: If this is a balancing charge, what commodity represents the base market? Example: Real-Time Energy would be the LMP Commodity, and Day-Ahead Energy would be the LMP Base Commodity - the billed quantity would be the balance between the two.'
/


comment on column COMPONENT.USE_ZONAL_PRICE is
'For LMP Commodity Charges: Should a Zonal price be used instead of a Service Point price? This causes the pricing logic to use a Zonal price correspoding to a delivery point''s Service Zone.'
/


comment on column COMPONENT.ALTERNATE_PRICE is
'Can the price be replaced or modified by an alternate rate? Choices include Bid Prices and Internal Schedule Prices.'
/


comment on column COMPONENT.ALTERNATE_PRICE_FUNCTION is
'If there is an alternate price, how is it used? The Min function, for instance, indicates that the rate to bill will be the lesser of the LMP rate or the alternate price.'
/


comment on column COMPONENT.ENTRY_DATE is
'The time stamp of this record’s entry.'
/


alter table COMPONENT
   add constraint AK_COMPONENT unique (COMPONENT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Index: FK_COMPONENT_MKT_PRICE                                */
/*==============================================================*/
create index FK_COMPONENT_MKT_PRICE on COMPONENT (
   MARKET_PRICE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: COMPONENT_BLOCK_RATE                                  */
/*==============================================================*/


create table COMPONENT_BLOCK_RATE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   BLOCK_MIN            NUMBER(10,3)                     not null,
   BLOCK_MAX            NUMBER(10,3),
   RATE                 NUMBER(16,6),
   CHARGE_MIN           NUMBER(16,6),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_BLOCK_RATE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, BEGIN_DATE, BLOCK_MIN)
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


/*==============================================================*/
/* Table: COMPONENT_COINCIDENT_PEAK                             */
/*==============================================================*/


create table COMPONENT_COINCIDENT_PEAK  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   A_SYSTEM_LOAD_ID     NUMBER(9),
   B_SYSTEM_LOAD_ID     NUMBER(9),
   RATE                 NUMBER(16,6),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_COINCIDENT_PEAK primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_COMBINATION                                 */
/*==============================================================*/


create table COMPONENT_COMBINATION  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   COMBINED_COMPONENT_ID NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   COEFFICIENT          NUMBER(16,6),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_COMBINATION primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, COMBINED_COMPONENT_ID, BEGIN_DATE)
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
       )
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
)
/


/*==============================================================*/
/* Table: COMPONENT_COMPOSITE                                   */
/*==============================================================*/


create table COMPONENT_COMPOSITE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   BLOCK_MIN            NUMBER(10,3)                     not null,
   BLOCK_MAX            NUMBER(10,3),
   COMPOSITE_COMPONENT_ID NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_BLOCK_COMPOSITE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, BEGIN_DATE, BLOCK_MIN)
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


/*==============================================================*/
/* Table: COMPONENT_CONVERSION_RATE                             */
/*==============================================================*/


create table COMPONENT_CONVERSION_RATE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   SCHEDULE_GROUP_ID    NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   COEFF_X3             NUMBER(30,20),
   COEFF_X2             NUMBER(30,20),
   COEFF_X1             NUMBER(30,20),
   CONST_K              NUMBER(30,20),
   RATE                 NUMBER(16,6),
   CHARGE_MIN           NUMBER(16,6),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_CONVERSION_RATE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, SCHEDULE_GROUP_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_ENTITY_ATTRIBUTE                            */
/*==============================================================*/


create table COMPONENT_ENTITY_ATTRIBUTE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ATTRIBUTE_ID  NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_ENTITY_ATTRIBUTE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, ENTITY_DOMAIN_ID, ENTITY_ATTRIBUTE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_FLAT_RATE                                   */
/*==============================================================*/


create table COMPONENT_FLAT_RATE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   RATE                 NUMBER(16,6),
   CHARGE_MIN           NUMBER(16,6),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_FLAT_RATE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_FORMULA_ENTITY_REF                          */
/*==============================================================*/


create table COMPONENT_FORMULA_ENTITY_REF  (
   COMPONENT_ID         NUMBER(9)                        not null,
   REFERENCE_NAME       VARCHAR2(32)                     not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_FML_ENTITY_REF primary key (COMPONENT_ID, REFERENCE_NAME)
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


/*==============================================================*/
/* Index: FK_COMPONENT_FML_ENTITY_REF_DM                        */
/*==============================================================*/
create index FK_COMPONENT_FML_ENTITY_REF_DM on COMPONENT_FORMULA_ENTITY_REF (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: COMPONENT_FORMULA_INPUT                               */
/*==============================================================*/


create table COMPONENT_FORMULA_INPUT  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   INPUT_NAME           VARCHAR2(32)                     not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   FUNCTION             VARCHAR2(32)                     not null,
   WHERE_CLAUSE         VARCHAR2(4000),
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_TYPE          CHAR(1)                          not null,
   ENTITY_ID            NUMBER(9)                        not null,
   WHAT_FIELD           VARCHAR2(40)                     not null,
   COMMENTS             VARCHAR2(2000),
   ROW_NUMBER           NUMBER(4),
   VIEW_ORDER           NUMBER(9),
   PERSIST_VALUE        NUMBER(1),
   STATE_FML            VARCHAR2(4000),
   STATEMENT_TYPE_FML   VARCHAR2(4000),
   SET_NUMBER_FML       VARCHAR2(4000),
   CODE_FML             VARCHAR2(4000),
   MEASUREMENT_SOURCE_FML VARCHAR2(4000),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_FORMULA_INPUT primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, INPUT_NAME, BEGIN_DATE)
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


alter table COMPONENT_FORMULA_INPUT
   add constraint CK01_COMPONENT_FORMULA_INPUT check (ENTITY_TYPE IN ('E','R','G'))
/


/*==============================================================*/
/* Index: FK_COMPONENT_FML_INPUT_DOMAIN                         */
/*==============================================================*/
create index FK_COMPONENT_FML_INPUT_DOMAIN on COMPONENT_FORMULA_INPUT (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: COMPONENT_FORMULA_ITERATOR                            */
/*==============================================================*/


create table COMPONENT_FORMULA_ITERATOR  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   ITERATOR_NAME        VARCHAR2(256)                    not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ITERATOR_QUERY       VARCHAR2(4000),
   IS_MULTICOLUMN       NUMBER(1),
   IDENT_COLUMNS        NUMBER(2),
   IS_INNER_LOOP        NUMBER(1),
   COMMENTS             VARCHAR2(2000),
   ROW_NUMBER           NUMBER(4),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_FORMULA_ITERATOR primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, ITERATOR_NAME, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_FORMULA_PARAMETER                           */
/*==============================================================*/


create table COMPONENT_FORMULA_PARAMETER  (
   COMPONENT_ID         NUMBER(9)                        not null,
   PARAMETER_NAME       VARCHAR2(32)                     not null,
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_FORMULA_PARAMETER primary key (COMPONENT_ID, PARAMETER_NAME)
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


/*==============================================================*/
/* Table: COMPONENT_FORMULA_RESULT                              */
/*==============================================================*/


create table COMPONENT_FORMULA_RESULT  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_TYPE          CHAR(1)                          not null,
   ENTITY_ID            NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   WHAT_FIELD           VARCHAR2(40)                     not null,
   FORMULA              VARCHAR2(4000)                   not null,
   COMMENTS             VARCHAR2(2000),
   STATE_FML            VARCHAR2(4000),
   STATEMENT_TYPE_FML   VARCHAR2(4000),
   SET_NUMBER_FML       VARCHAR2(4000),
   CODE_FML             VARCHAR2(4000),
   MEASUREMENT_SOURCE_FML VARCHAR2(4000),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_FORMULA_RESULT primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, ENTITY_DOMAIN_ID, ENTITY_TYPE, ENTITY_ID, BEGIN_DATE, WHAT_FIELD)
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


alter table COMPONENT_FORMULA_RESULT
   add constraint CK01_COMPONENT_FORMULA_RESULT check (ENTITY_TYPE IN ('E','R'))
/


/*==============================================================*/
/* Index: FK_COMPONENT_FML_RESULT_DOMAIN                        */
/*==============================================================*/
create index FK_COMPONENT_FML_RESULT_DOMAIN on COMPONENT_FORMULA_RESULT (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: COMPONENT_FORMULA_VARIABLE                            */
/*==============================================================*/


create table COMPONENT_FORMULA_VARIABLE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   VARIABLE_NAME        VARCHAR2(256)                    not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   FORMULA              VARCHAR2(4000),
   IS_MULTICOLUMN       NUMBER(1),
   IS_PLSQL             NUMBER(1),
   COMMENTS             VARCHAR2(2000),
   ROW_NUMBER           NUMBER(4),
   VIEW_ORDER           NUMBER(9),
   PERSIST_VALUE        NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_FORMULA_VARIABLE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, VARIABLE_NAME, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_IMBALANCE                                   */
/*==============================================================*/


create table COMPONENT_IMBALANCE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SERVICE_POINT_ID     NUMBER(9),
   UNDER_UNDER_PRICE_ID NUMBER(9),
   UNDER_OVER_PRICE_ID  NUMBER(9),
   OVER_UNDER_PRICE_ID  NUMBER(9),
   OVER_OVER_PRICE_ID   NUMBER(9),
   IS_PERCENT           NUMBER(1),
   IS_PRORATE           NUMBER(1),
   SETTLEMENT_AGENT     VARCHAR2(16),
   IMBALANCE_ID         NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_IMBALANCE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_COMP_IMBLNCE_OO_PRICE                              */
/*==============================================================*/
create index FK_COMP_IMBLNCE_OO_PRICE on COMPONENT_IMBALANCE (
   OVER_OVER_PRICE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Index: FK_COMP_IMBLNCE_OU_PRICE                              */
/*==============================================================*/
create index FK_COMP_IMBLNCE_OU_PRICE on COMPONENT_IMBALANCE (
   OVER_UNDER_PRICE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_COMP_IMBLNCE_UO_PRICE                              */
/*==============================================================*/
create index FK_COMP_IMBLNCE_UO_PRICE on COMPONENT_IMBALANCE (
   UNDER_OVER_PRICE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_COMP_IMBLNCE_UU_PRICE                              */
/*==============================================================*/
create index FK_COMP_IMBLNCE_UU_PRICE on COMPONENT_IMBALANCE (
   UNDER_UNDER_PRICE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: COMPONENT_IMBALANCE_BAND                              */
/*==============================================================*/


create table COMPONENT_IMBALANCE_BAND  (
   IMBALANCE_ID         NUMBER(9)                        not null,
   BAND_TYPE            VARCHAR2(8)                      not null,
   BAND_NUMBER          NUMBER(1)                        not null,
   BAND_MINIMUM         NUMBER(12,4),
   BAND_THRESHOLD       NUMBER(12,4),
   BAND_MULTIPLIER      NUMBER(9,6),
   BAND_CHARGE          NUMBER(8,2),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_IMBALANCE_BAND primary key (IMBALANCE_ID, BAND_TYPE, BAND_NUMBER)
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


/*==============================================================*/
/* Table: COMPONENT_MARKET_PRICE                                */
/*==============================================================*/


create table COMPONENT_MARKET_PRICE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   RATE_ADDER           NUMBER(16,6),
   RATE_MULTIPLIER      NUMBER(16,6),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_MARKET_PRICE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_PERCENTAGE                                  */
/*==============================================================*/


create table COMPONENT_PERCENTAGE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PERCENT_VAL          NUMBER(10,4),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_PERCENTAGE primary key (COMPONENT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPONENT_TOU_RATE                                    */
/*==============================================================*/


create table COMPONENT_TOU_RATE  (
   COMPONENT_ID         NUMBER(9)                        not null,
   SUB_COMPONENT_TYPE   VARCHAR2(16)                     not null,
   SUB_COMPONENT_ID     NUMBER(9)                        not null,
   PERIOD_ID            NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   RATE                 NUMBER(16,6),
   CHARGE_MIN			NUMBER(16,6),
   ENTRY_DATE           DATE,
   constraint PK_COMPONENT_TOU_RATE primary key (COMPONENT_ID, SUB_COMPONENT_TYPE, SUB_COMPONENT_ID, PERIOD_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: COMPOSITE_WEATHER_WORK                                */
/*==============================================================*/


create global temporary table COMPOSITE_WEATHER_WORK
(
  ROOT_ENTITY_ID NUMBER(9),
  ENTITY_INDEX   NUMBER(4),
  ENTITY_ID      NUMBER(9),
  COEFFICIENT    NUMBER
)
on commit preserve rows
/


/*==============================================================*/
/* Index: COMPOSITE_WEATHER_WORK_IX01                           */
/*==============================================================*/
create index COMPOSITE_WEATHER_WORK_IX01 on COMPOSITE_WEATHER_WORK (
   ENTITY_INDEX ASC,
   ENTITY_ID ASC
)
/


/*==============================================================*/
/* Table: CONDITIONAL_FORMAT                                    */
/*==============================================================*/


create table CONDITIONAL_FORMAT  (
   CONDITIONAL_FORMAT_ID NUMBER(9)                        not null,
   CONDITIONAL_FORMAT_NAME VARCHAR(32)                      not null,
   CONDITIONAL_FORMAT_ALIAS VARCHAR(32),
   CONDITIONAL_FORMAT_DESC VARCHAR(64),
   CONDITIONAL_FORMAT_MODULE VARCHAR(32),
   ENTRY_DATE           DATE,
   constraint PK_CONDITIONAL_FORMAT primary key (CONDITIONAL_FORMAT_ID)
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


alter table CONDITIONAL_FORMAT
   add constraint AK_CONDITIONAL_FORMAT unique (CONDITIONAL_FORMAT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CONDITIONAL_FORMAT_ITEM                               */
/*==============================================================*/


create table CONDITIONAL_FORMAT_ITEM  (
   CONDITIONAL_FORMAT_ID NUMBER(9)                        not null,
   ITEM_NUMBER          NUMBER(9)                        not null,
   COLOR_WHEN_FORMULA   VARCHAR(256),
   FOREGROUND_COLOR     NUMBER(9),
   BACKGROUND_COLOR     NUMBER(9),
   IS_BOLD              NUMBER(1),
   IS_ITALIC            NUMBER(1),
   IS_STRIKE_THROUGH    NUMBER(1),
   IS_UNDERLINE         NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_CONDITIONAL_FORMAT_ITEM primary key (CONDITIONAL_FORMAT_ID, ITEM_NUMBER)
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


/*==============================================================*/
/* Table: CONTACT                                               */
/*==============================================================*/


create table CONTACT  (
   CONTACT_ID           NUMBER(9)                        not null,
   CONTACT_NAME         VARCHAR2(64)                     not null,
   CONTACT_ALIAS        VARCHAR2(32),
   CONTACT_DESC         VARCHAR2(256),
   CONTACT_STATUS       VARCHAR2(32),
   EMAIL_ADDRESS        VARCHAR2(64),
   FIRST_NAME           VARCHAR2(32),
   MIDDLE_NAME          VARCHAR2(32),
   LAST_NAME            VARCHAR2(32),
   SALUTATION           VARCHAR2(16),
   TITLE                VARCHAR2(32),
   EXTERNAL_IDENTIFIER  VARCHAR2(64),
   ENTRY_DATE           DATE,
   constraint PK_CONTACT primary key (CONTACT_ID)
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


alter table CONTACT
   add constraint AK_CONTACT unique (CONTACT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CONTACT_CATEGORY                                      */
/*==============================================================*/


create table CONTACT_CATEGORY  (
   CONTACT_ID           NUMBER(9)                        not null,
   CATEGORY_ID          NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_CONTACT_CATEGORY primary key (CONTACT_ID, CATEGORY_ID)
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


/*==============================================================*/
/* Index: CONTACT_CATEGORY_IX01                                 */
/*==============================================================*/
create index CONTACT_CATEGORY_IX01 on CONTACT_CATEGORY (
   CATEGORY_ID ASC,
   CONTACT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: CONTRACT_ASSIGNMENT                                   */
/*==============================================================*/


create table CONTRACT_ASSIGNMENT  (
   CONTRACT_ID          NUMBER(9)                        not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   OWNER_ENTITY_ID      NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTITY_NAME          VARCHAR(64),
   ENTRY_DATE           DATE,
   constraint PK_CONTRACT_ASSIGNMENT primary key (ENTITY_DOMAIN_ID, CONTRACT_ID, OWNER_ENTITY_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CONTRACT_LIMIT                                        */
/*==============================================================*/


create table CONTRACT_LIMIT  (
   LIMIT_ID             NUMBER(9)                        not null,
   LIMIT_NAME           VARCHAR2(32)                     not null,
   LIMIT_ALIAS          VARCHAR2(32),
   LIMIT_DESC           VARCHAR2(256),
   LIMIT_TYPE           VARCHAR2(16),
   LIMIT_MEASURE        VARCHAR2(16),
   LIMIT_INTERVAL       VARCHAR2(16),
   LIMIT_IS_SEASONABLE  NUMBER(1),
   TEMPLATE_ID          NUMBER(9),
   PERIOD_ID            NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_CONTRACT_LIMIT primary key (LIMIT_ID)
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


alter table CONTRACT_LIMIT
   add constraint AK_CONTRACT_LIMIT unique (LIMIT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CONTRACT_LIMIT_QUANTITY                               */
/*==============================================================*/


create table CONTRACT_LIMIT_QUANTITY  (
   CONTRACT_ID          NUMBER(9)                        not null,
   LIMIT_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   LIMIT_QUANTITY       NUMBER(14,4),
   ENTRY_DATE           DATE,
   constraint PK_CONTRACT_LIMIT_QUANTITY primary key (CONTRACT_ID, LIMIT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CONTRACT_PRODUCT_COMPONENT                            */
/*==============================================================*/


create table CONTRACT_PRODUCT_COMPONENT  (
   CONTRACT_ID          NUMBER(9)                        not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_CONTRACT_PRODUCT_COMPONENT primary key (CONTRACT_ID, PRODUCT_ID, COMPONENT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CONTROL_AREA                                          */
/*==============================================================*/


create table CONTROL_AREA  (
   CA_ID                NUMBER(9)                        not null,
   CA_NAME              VARCHAR2(32)                     not null,
   CA_ALIAS             VARCHAR2(32),
   CA_DESC              VARCHAR2(256),
   CA_NERC_CODE         VARCHAR2(16),
   CA_STATUS            VARCHAR2(16),
   CA_DUNS_NUMBER       VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_CONTROL_AREA primary key (CA_ID)
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


alter table CONTROL_AREA
   add constraint AK_CONTROL_AREA unique (CA_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CONVERSION_CHARGE                                     */
/*==============================================================*/


create table CONVERSION_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   SCHEDULE_GROUP_ID    NUMBER(9)                        not null,
   PEAK_DATE            DATE,
   PEAK_DEMAND          NUMBER(12,4),
   SCHEDULED_AMOUNT     NUMBER(18,9),
   COEFF_X3             NUMBER(30,20),
   COEFF_X2             NUMBER(30,20),
   COEFF_X1             NUMBER(30,20),
   CONST_K              NUMBER(30,20),
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_CONVERSION_CHARGE primary key (CHARGE_ID, CHARGE_DATE, SCHEDULE_GROUP_ID)
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


/*==============================================================*/
/* Table: CRYSTAL_REPORT_FILES                                  */
/*==============================================================*/


create table CRYSTAL_REPORT_FILES  (
   OBJECT_ID            NUMBER(9)                        not null,
   TEMPLATE_TYPE        VARCHAR2(2000)                   not null,
   REPORT_FILE          BLOB,
   ENTRY_DATE           DATE,
   constraint PK_CRYSTAL_REPORT_FILES primary key (OBJECT_ID, TEMPLATE_TYPE)
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
       )
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
)
/


comment on table CRYSTAL_REPORT_FILES is
'This table stores Crystal Report RPT files to be used for custom reports (on the Other tab)'
/


comment on column CRYSTAL_REPORT_FILES.OBJECT_ID is
'Object ID of a Report (from SYSTEM_OBJECT table)'
/


comment on column CRYSTAL_REPORT_FILES.TEMPLATE_TYPE is
'Template Type for a Report (if no type needed then it should be "<Default>")'
/


comment on column CRYSTAL_REPORT_FILES.REPORT_FILE is
'The binary report data that constitutes the Crystal Report Template RPT file.'
/


comment on column CRYSTAL_REPORT_FILES.ENTRY_DATE is
'When was the last time this database record was updated?'
/


/*==============================================================*/
/* Table: CRYSTAL_REPORT_TEMPLATE                               */
/*==============================================================*/


create table CRYSTAL_REPORT_TEMPLATE  (
   OBJECT_ID            NUMBER(9)                        not null,
   ROW_NUMBER           NUMBER(4)                        not null,
   REPORT_DATA          VARCHAR2(4000),
   ENTRY_DATE           DATE,
   constraint PK_CRYSTAL_REPORT_TEMPLATE primary key (OBJECT_ID, ROW_NUMBER)
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
       )
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
)
/


comment on table CRYSTAL_REPORT_TEMPLATE is
'This table stores Crystal Report RPT files to be used for custom reports (on the Other tab)'
/


comment on column CRYSTAL_REPORT_TEMPLATE.OBJECT_ID is
'Object ID of a Report (from SYSTEM_OBJECT table)'
/


comment on column CRYSTAL_REPORT_TEMPLATE.ROW_NUMBER is
'When the RPT file cannot fit into a single record, this determines the order of the records so the file is correctly reconstructed'
/


comment on column CRYSTAL_REPORT_TEMPLATE.REPORT_DATA is
'The Hex encoded binary report data.'
/


comment on column CRYSTAL_REPORT_TEMPLATE.ENTRY_DATE is
'When was the last time this database record was updated?'
/


/*==============================================================*/
/* Table: CURRENT_SESSION_USER                                  */
/*==============================================================*/


create global temporary table CURRENT_SESSION_USER  (
   USER_ID              NUMBER(9)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: CURTAILMENT_EVENT                                     */
/*==============================================================*/


create table CURTAILMENT_EVENT  (
   CURTAILMENT_ID       NUMBER(9)                        not null,
   CURTAILMENT_DATE     DATE                             not null,
   CURTAILMENT_SEQUENCE NUMBER(1)                        not null,
   LIMIT_ID             NUMBER(9)                        not null,
   CURTAILMENT_QUANTITY NUMBER(8),
   CURTAILMENT_RATE     NUMBER(8,2),
   ENTRY_DATE           DATE,
   constraint PK_CURTAILMENT_EVENT primary key (CURTAILMENT_ID, CURTAILMENT_DATE, CURTAILMENT_SEQUENCE, LIMIT_ID)
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


/*==============================================================*/
/* Table: CURTAILMENT_PARTICIPATION                             */
/*==============================================================*/


create table CURTAILMENT_PARTICIPATION  (
   CURTAILMENT_ID       NUMBER(9)                        not null,
   ACCOUNT_SERVICE_ID   NUMBER(9)                        not null,
   OFFERED_WHEN         DATE,
   ACCEPTED_WHEN        DATE,
   CONFIRMED_WHEN       DATE,
   PROCESS_CODE         NUMBER(1),
   constraint PK_CURTAILMENT_PARTICIPATION primary key (CURTAILMENT_ID, ACCOUNT_SERVICE_ID)
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


/*==============================================================*/
/* Table: CURTAILMENT_SCHEDULE                                  */
/*==============================================================*/


create table CURTAILMENT_SCHEDULE  (
   CURTAILMENT_ID       NUMBER(9)                        not null,
   ACCOUNT_SERVICE_ID   NUMBER(9)                        not null,
   CURTAILMENT_DATE     DATE,
   CURTAILED_USAGE      NUMBER(14,4),
   FORECASTED_USAGE     NUMBER(14,4),
   METERED_USAGE        NUMBER(14,4),
   constraint PK_CURTAILMENT_SCHEDULE primary key (CURTAILMENT_ID, ACCOUNT_SERVICE_ID)
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


/*==============================================================*/
/* Table: CUSTOMER                                              */
/*==============================================================*/


create table CUSTOMER  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   CUSTOMER_NAME        VARCHAR(32)                      not null,
   CUSTOMER_ALIAS       VARCHAR(32),
   CUSTOMER_DESC        VARCHAR(256),
   CUSTOMER_IDENTIFIER  VARCHAR2(64),
   CUSTOMER_STATUS      VARCHAR2(16),
   CUSTOMER_IS_ACTIVE   NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER primary key (CUSTOMER_ID)
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


alter table CUSTOMER
   add constraint AK_CUSTOMER unique (CUSTOMER_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: CUSTOMER_ANCILLARY_SERVICE                            */
/*==============================================================*/


create table CUSTOMER_ANCILLARY_SERVICE  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   ANCILLARY_SERVICE_ID NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SERVICE_VAL          NUMBER(10,4),
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER_ANCILLARY_SERVICE primary key (CUSTOMER_ID, ANCILLARY_SERVICE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CUSTOMER_BILL_CYCLE                                   */
/*==============================================================*/


create table CUSTOMER_BILL_CYCLE  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   BILL_CYCLE_ID        NUMBER(9)                        not null,
   BILL_CYCLE_ENTITY    VARCHAR(16)                      not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER_BILL_CYCLE primary key (CUSTOMER_ID, BILL_CYCLE_ID, BILL_CYCLE_ENTITY, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CUSTOMER_CHARGE                                       */
/*==============================================================*/


create table CUSTOMER_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CUSTOMER_ID          NUMBER(9)                        not null,
   BAND_NUMBER          NUMBER(1)                        not null,
   BILL_CODE            CHAR(1)                          not null,
   CHARGE_BEGIN_DATE    DATE                             not null,
   CHARGE_END_DATE      DATE,
   CHARGE_QUANTITY      NUMBER(10,4),
   CHARGE_RATE          NUMBER(10,4),
   CHARGE_FACTOR        NUMBER(10,4),
   CHARGE_AMOUNT        NUMBER(10,4),
   BILL_QUANTITY        NUMBER(10,4),
   BILL_AMOUNT          NUMBER(10,4),
   constraint PK_CUSTOMER_CHARGE primary key (CHARGE_ID, CUSTOMER_ID, BAND_NUMBER, BILL_CODE, CHARGE_BEGIN_DATE)
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


/*==============================================================*/
/* Table: CUSTOMER_CONSUMPTION                                  */
/*==============================================================*/


create table CUSTOMER_CONSUMPTION  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   BILL_CODE            CHAR(1)                          not null,
   CONSUMPTION_CODE     CHAR(1)                          not null,
   RECEIVED_DATE        DATE                             not null,
   METER_TYPE           CHAR(1),
   METER_READING        VARCHAR(16),
   BILLED_USAGE         NUMBER(14,4),
   METERED_USAGE        NUMBER(14,4),
   METERS_READ          NUMBER(8),
   CONVERSION_FACTOR    CHAR(10),
   IGNORE_CONSUMPTION   NUMBER(1),
   BILL_CYCLE_MONTH     DATE,
   BILL_PROCESSED_DATE  DATE,
   READ_BEGIN_DATE      DATE,
   READ_END_DATE        DATE,
   CONSUMPTION_ID       NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER_CONSUMPTION primary key (CUSTOMER_ID, BEGIN_DATE, END_DATE, BILL_CODE, CONSUMPTION_CODE, RECEIVED_DATE)
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


/*==============================================================*/
/* Table: CUSTOMER_GROWTH                                       */
/*==============================================================*/


create table CUSTOMER_GROWTH  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SERVICE_ACCOUNTS     NUMBER(12),
   GROWTH_PCT           NUMBER(8,3),
   PATTERN_ID           NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER_GROWTH primary key (CUSTOMER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CUSTOMER_PRODUCT                                      */
/*==============================================================*/


create table CUSTOMER_PRODUCT  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   PRODUCT_TYPE         VARCHAR(16)                      not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER_PRODUCT primary key (CUSTOMER_ID, PRODUCT_ID, PRODUCT_TYPE, BEGIN_DATE)
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


/*==============================================================*/
/* Table: CUSTOMER_SERVICE                                      */
/*==============================================================*/


create table CUSTOMER_SERVICE  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   SERVICE_DATE         DATE                             not null,
   SERVICE_ACCOUNTS     NUMBER(8),
   USAGE_FACTOR         NUMBER(8,4),
   constraint PK_CUSTOMER_SERVICE primary key (CUSTOMER_ID, SERVICE_DATE)
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


/*==============================================================*/
/* Table: CUSTOMER_SERVICE_LOAD                                 */
/*==============================================================*/


create table CUSTOMER_SERVICE_LOAD  (
   SERVICE_ID           NUMBER(9)                        not null,
   CUSTOMER_ID          NUMBER(9)                        not null,
   SERVICE_CODE         CHAR(1)                          not null,
   LOAD_DATE            DATE                             not null,
   LOAD_CODE            CHAR(1)                          not null,
   LOAD_VAL             NUMBER(14,4),
   TX_LOSS_VAL          NUMBER(10,4),
   DX_LOSS_VAL          NUMBER(10,4),
   UE_LOSS_VAL          NUMBER(10,4),
   constraint PK_CUSTOMER_SERVICE_LOAD primary key (SERVICE_ID, CUSTOMER_ID, SERVICE_CODE, LOAD_DATE, LOAD_CODE)
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


/*==============================================================*/
/* Table: CUSTOMER_USAGE_FACTOR                                 */
/*==============================================================*/


create table CUSTOMER_USAGE_FACTOR  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   FACTOR_VAL           NUMBER(14,6),
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER_USAGE_FACTOR primary key (CUSTOMER_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Table: SERVICE_LOAD_STAGING                                  */
/*==============================================================*/


create table SERVICE_LOAD_STAGING  (
    ACCOUNT_IDENT                       VARCHAR2(64)    not null,
    METER_IDENT                     	VARCHAR2(128),
    ESP_IDENT                           VARCHAR2(64),
    POOL_IDENT                          VARCHAR2(64),
    SERVICE_CODE                        CHAR(1),
    SERVICE_DATE                        DATE    not null,
    INTERVAL                            VARCHAR2(9)    not null,
    UOM                                 VARCHAR2(8),
    VAL1                                NUMBER,
    VAL2                                NUMBER,
    VAL3                                NUMBER,
    VAL4                                NUMBER,
    VAL5                                NUMBER,
    VAL6                                NUMBER,
    VAL7                                NUMBER,
    VAL8                                NUMBER,
    VAL9                                NUMBER,
    VAL10                               NUMBER,
    VAL11                               NUMBER,
    VAL12                               NUMBER,
    VAL13                               NUMBER,
    VAL14                               NUMBER,
    VAL15                               NUMBER,
    VAL16                               NUMBER,
    VAL17                               NUMBER,
    VAL18                               NUMBER,
    VAL19                               NUMBER,
    VAL20                               NUMBER,
    VAL21                               NUMBER,
    VAL22                               NUMBER,
    VAL23                               NUMBER,
    VAL24                               NUMBER,
    VAL25                               NUMBER,
    VAL26                               NUMBER,
    VAL27                               NUMBER,
    VAL28                               NUMBER,
    VAL29                               NUMBER,
    VAL30                               NUMBER,
    VAL31                               NUMBER,
    VAL32                               NUMBER,
    VAL33                               NUMBER,
    VAL34                               NUMBER,
    VAL35                               NUMBER,
    VAL36                               NUMBER,
    VAL37                               NUMBER,
    VAL38                               NUMBER,
    VAL39                               NUMBER,
    VAL40                               NUMBER,
    VAL41                               NUMBER,
    VAL42                               NUMBER,
    VAL43                               NUMBER,
    VAL44                               NUMBER,
    VAL45                               NUMBER,
    VAL46                               NUMBER,
    VAL47                               NUMBER,
    VAL48                               NUMBER,
    VAL49                               NUMBER,
    VAL50                               NUMBER,
    VAL51                               NUMBER,
    VAL52                               NUMBER,
    VAL53                               NUMBER,
    VAL54                               NUMBER,
    VAL55                               NUMBER,
    VAL56                               NUMBER,
    VAL57                               NUMBER,
    VAL58                               NUMBER,
    VAL59                               NUMBER,
    VAL60                               NUMBER,
    VAL61                               NUMBER,
    VAL62                               NUMBER,
    VAL63                               NUMBER,
    VAL64                               NUMBER,
    VAL65                               NUMBER,
    VAL66                               NUMBER,
    VAL67                               NUMBER,
    VAL68                               NUMBER,
    VAL69                               NUMBER,
    VAL70                               NUMBER,
    VAL71                               NUMBER,
    VAL72                               NUMBER,
    VAL73                               NUMBER,
    VAL74                               NUMBER,
    VAL75                               NUMBER,
    VAL76                               NUMBER,
    VAL77                               NUMBER,
    VAL78                               NUMBER,
    VAL79                               NUMBER,
    VAL80                               NUMBER,
    VAL81                               NUMBER,
    VAL82                               NUMBER,
    VAL83                               NUMBER,
    VAL84                               NUMBER,
    VAL85                               NUMBER,
    VAL86                               NUMBER,
    VAL87                               NUMBER,
    VAL88                               NUMBER,
    VAL89                               NUMBER,
    VAL90                               NUMBER,
    VAL91                               NUMBER,
    VAL92                               NUMBER,
    VAL93                               NUMBER,
    VAL94                               NUMBER,
    VAL95                               NUMBER,
    VAL96                               NUMBER,
    VAL97                               NUMBER,
    VAL98                               NUMBER,
    VAL99                               NUMBER,
    VAL100                              NUMBER,
    SYNC_ORDER                         	NUMBER(9),
    SYNC_STATUS                         VARCHAR2(32),
    ERROR_MESSAGE                       VARCHAR2(4000)
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: CUSTOMER_USAGE_WRF                                    */
/*==============================================================*/


create table CUSTOMER_USAGE_WRF  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   WRF_ID               NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_CUSTOMER_USAGE_WRF primary key (CUSTOMER_ID, WRF_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_CUSTOMER_USAGE_WRF                                 */
/*==============================================================*/
create index FK_CUSTOMER_USAGE_WRF on CUSTOMER_USAGE_WRF (
   WRF_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: CUSTOMER_USAGE_WRF_LINE                               */
/*==============================================================*/


create table CUSTOMER_USAGE_WRF_LINE  (
   CUSTOMER_ID          NUMBER(9)                        not null,
   WRF_ID               NUMBER(9)                        not null,
   TEMPLATE_ID          NUMBER(9)                        not null,
   SEGMENT_NBR          NUMBER(1)                        not null,
   AS_OF_DATE           DATE                             not null,
   ALPHA                NUMBER(8,4),
   BETA                 NUMBER(8,4),
   R2                   NUMBER(8,6),
   N                    NUMBER(6),
   X_MIN                NUMBER(8,2),
   X_MAX                NUMBER(8,2),
   Y_MIN                NUMBER(8,2),
   Y_MAX                NUMBER(8,2),
   X_ZERO               NUMBER(4),
   Y_ZERO               NUMBER(4),
   Y_LIMIT              NUMBER(8,2),
   Y_TYPE               CHAR(1),
   BASE_LOAD_TEMPLATE_ID NUMBER(9),
   constraint PK_CUSTOMER_USAGE_WRF_LINE primary key (CUSTOMER_ID, WRF_ID, TEMPLATE_ID, SEGMENT_NBR, AS_OF_DATE)
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

/*==============================================================*/
/* Index: FK_CUSTOMER_USAGE_WRF_LINE                            */
/*==============================================================*/
create index FK_CUSTOMER_USAGE_WRF_LINE on CUSTOMER_USAGE_WRF_LINE (
   WRF_ID ASC, TEMPLATE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_CUSTOMER_USAGE_WRF_LINE_TPL                        */
/*==============================================================*/
create index FK_CUSTOMER_USAGE_WRF_LINE_TPL on CUSTOMER_USAGE_WRF_LINE (
   BASE_LOAD_TEMPLATE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 

/*==============================================================*/
/* Table: CUST_WRF_SEASON_CACHE                                 */
/*==============================================================*/


create global temporary table CUST_WRF_SEASON_CACHE  (
   AGGREGATE_ID         NUMBER(9)                        not null,
   CUSTOMER_ID          NUMBER(9)                        not null,
   COMPOSITE_BEGIN_DATE DATE,
   COMPOSITE_END_DATE   DATE,
   SEASON_BEGIN_DATE    DATE                             not null,
   SEASON_END_DATE      DATE                             not null,
   STATION_ID           NUMBER(9),
   PARAMETER_ID         NUMBER(9),
   COMPOSITE_ALPHA      NUMBER,
   COMPOSITE_BETA       NUMBER,
   Y_LIMIT              NUMBER
)
on commit preserve rows
/


comment on table CUST_WRF_SEASON_CACHE is
'Temporary Table used for Customer WRF Forecast and Backcast'
/


/*==============================================================*/
/* Table: DATA_IMPORT_STAGING_AREA                              */
/*==============================================================*/


create table DATA_IMPORT_STAGING_AREA  (
   SESSION_ID           VARCHAR(32)                      not null,
   FILE_NAME            VARCHAR(256)                     not null,
   ROW_NUM              NUMBER                           not null,
   ROW_CONTENTS         CLOB,
   STATUS               CHAR(1),
   COLUMN_6             CHAR(10),
   constraint PK_DATA_IMPORT_STAGING_AREA primary key (SESSION_ID, FILE_NAME, ROW_NUM)
         using index
       pctfree 10
       initrans 2
       maxtrans 255
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           minextents 1
           maxextents unlimited
       )
)
pctfree 10
initrans 1
maxtrans 255
storage
(
    initial 128K
    minextents 1
    maxextents unlimited
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: DATA_LOCK_GROUP                                       */
/*==============================================================*/


create table DATA_LOCK_GROUP  (
   DATA_LOCK_GROUP_ID       NUMBER(9)                        not null,
   DATA_LOCK_GROUP_NAME     VARCHAR2(32)                     not null,
   DATA_LOCK_GROUP_ALIAS    VARCHAR2(32),
   DATA_LOCK_GROUP_DESC     VARCHAR2(512),
   DATA_LOCK_GROUP_INTERVAL VARCHAR2(16),
   IS_AUTOMATIC             NUMBER(1),
   AUTOLOCK_DATE_FORMULA    VARCHAR2(4000),
   LOCK_LIMIT_DATE_FORMULA  VARCHAR2(4000),
   LOCK_STATE               CHAR(1),
   LAST_PROCESSED_INTERVAL  DATE,
   TIME_ZONE                VARCHAR2(8),
   WEEK_BEGIN               VARCHAR2(16),
   constraint PK_DATA_LOCK_GROUP primary key (DATA_LOCK_GROUP_ID)
         using index
       pctfree 10
       initrans 2
       maxtrans 255
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           minextents 1
           maxextents unlimited
       )
)
pctfree 10
initrans 1
maxtrans 255
storage
(
    initial 128K
    minextents 1
    maxextents unlimited
)
tablespace NERO_DATA
/


alter table DATA_LOCK_GROUP
   add constraint AK_DATA_LOCK_GROUP unique (DATA_LOCK_GROUP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table DATA_LOCK_GROUP
   add constraint CK_DATA_LOCK_GROUP_01 check ((IS_AUTOMATIC = 1 AND AUTOLOCK_DATE_FORMULA IS NOT NULL AND LOCK_LIMIT_DATE_FORMULA IS NULL)OR(IS_AUTOMATIC = 0 AND AUTOLOCK_DATE_FORMULA IS NULL AND LOCK_LIMIT_DATE_FORMULA IS NOT NULL))
/

/*==============================================================*/
/* Table: DATA_LOCK_GROUP_ITEM                                  */
/*==============================================================*/


create table DATA_LOCK_GROUP_ITEM  (
   DATA_LOCK_GROUP_ITEM_ID   NUMBER(9)                        not null,
   DATA_LOCK_GROUP_ID        NUMBER(9)                        not null,
   TABLE_ID                  NUMBER(9)                        not null,
   ENTITY_DOMAIN_ID          NUMBER(9)                        not null,
   ENTITY_TYPE               CHAR(1)                          not null,
   ENTITY_ID                 NUMBER(9)                        not null,
   constraint PK_DATA_LOCK_GROUP_ITEM primary key (DATA_LOCK_GROUP_ITEM_ID)
         using index
       pctfree 10
       initrans 2
       maxtrans 255
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           minextents 1
           maxextents unlimited
       )
)
pctfree 10
initrans 1
maxtrans 255
storage
(
    initial 128K
    minextents 1
    maxextents unlimited
)
tablespace NERO_DATA
/

alter table DATA_LOCK_GROUP_ITEM
   add constraint CK_DATA_LOCK_GROUP_ITEM_01 check (ENTITY_TYPE IN ('E','R','G'))
/

/*==============================================================*/
/* Index: FK_DATA_LOCK_GROUP_ITEM_GROUP                         */
/*==============================================================*/
create index FK_DATA_LOCK_GROUP_ITEM_GROUP on DATA_LOCK_GROUP_ITEM (
   DATA_LOCK_GROUP_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: FK_DATA_LOCK_GROUP_ITEM_TABLE                         */
/*==============================================================*/
create index FK_DATA_LOCK_GROUP_ITEM_TABLE on DATA_LOCK_GROUP_ITEM (
   TABLE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: FK_DATA_LOCK_GROUP_ITEM_DOMAIN                        */
/*==============================================================*/
create index FK_DATA_LOCK_GROUP_ITEM_DOMAIN on DATA_LOCK_GROUP_ITEM (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: DATA_LOCK_GROUP_ITEM_CRITERIA                         */
/*==============================================================*/


create table DATA_LOCK_GROUP_ITEM_CRITERIA  (
   DATA_LOCK_GROUP_ITEM_ID   NUMBER(9)                        not null,
   COLUMN_NAME               VARCHAR2(30)                     not null,
   COLUMN_VALUE              VARCHAR2(4000)                   not null,
   constraint PK_DATA_LOCK_GROUP_ITEM_CRIT primary key (DATA_LOCK_GROUP_ITEM_ID, COLUMN_NAME)
         using index
       pctfree 10
       initrans 2
       maxtrans 255
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           minextents 1
           maxextents unlimited
       )
)
pctfree 10
initrans 1
maxtrans 255
storage
(
    initial 128K
    minextents 1
    maxextents unlimited
)
tablespace NERO_DATA
/

/*==============================================================*/
/* Table: DER_PROGRAM                                           */
/*==============================================================*/


create table DER_PROGRAM  (
   DER_ID               NUMBER(9)                        not null,
   PROGRAM_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   COUNT                NUMBER(4),
   constraint PK_DER_PROGRAM primary key (DER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* INDEX: FK_DER_PROGRAM_PROGRAM                                */
/*==============================================================*/
CREATE INDEX FK_DER_PROGRAM_PROGRAM ON DER_PROGRAM (
   PROGRAM_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DISTRIBUTED_ENERGY_RESOURCE                           */
/*==============================================================*/


create table DISTRIBUTED_ENERGY_RESOURCE (
   DER_ID                  NUMBER(9)                        not null,
   DER_NAME                VARCHAR2(64)                     not null,
   DER_ALIAS               VARCHAR2(32),
   DER_DESC                VARCHAR2(256),
   SERVICE_LOCATION_ID     NUMBER(9)                        not null,
   DER_TYPE_ID             NUMBER(9),
   EXTERNAL_SYSTEM_ID      NUMBER(9),
   EXTERNAL_IDENTIFIER     VARCHAR2(32),
   BEGIN_DATE              DATE	                            not null,
   END_DATE           	   DATE,
   SERIAL_NUMBER           VARCHAR2(32),
   ENTRY_DATE              DATE,
   constraint PK_DISTRIBUTED_ENERGY_RESOURCE primary key (DER_ID)
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


alter table DISTRIBUTED_ENERGY_RESOURCE
   add constraint AK_DISTRIBUTED_ENERGY_RESOURCE unique (DER_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_DER_DER_TYPE                                       */
/*==============================================================*/
CREATE INDEX FK_DER_DER_TYPE ON DISTRIBUTED_ENERGY_RESOURCE (
   DER_TYPE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_EXT_SYS                                        */
/*==============================================================*/
CREATE INDEX FK_DER_EXT_SYS ON DISTRIBUTED_ENERGY_RESOURCE (
   EXTERNAL_SYSTEM_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_SL                                             */
/*==============================================================*/
CREATE INDEX FK_DER_SL ON DISTRIBUTED_ENERGY_RESOURCE (
   SERVICE_LOCATION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DER_CALENDAR                                           */
/*==============================================================*/


create table DER_CALENDAR (
   DER_ID               NUMBER(9)                            not null,
   CASE_ID              NUMBER(9)                            not null,
   BEGIN_DATE           DATE                     		     not null,
   END_DATE            	DATE,
   CALENDAR_ID          NUMBER(9)             			     not null,
   ENTRY_DATE           DATE,
   constraint PK_DER_CALENDAR primary key (DER_ID, CASE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* INDEX: FK_DER_CAL                                            */
/*==============================================================*/
CREATE INDEX FK_DER_CAL ON DER_CALENDAR (
   CALENDAR_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_CASE                                           */
/*==============================================================*/
CREATE INDEX FK_DER_CASE ON DER_CALENDAR (
   CASE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DER_SCALE_FACTOR                                           */
/*==============================================================*/


create table DER_SCALE_FACTOR (
   DER_ID          	    NUMBER(9)                       not null,
   CASE_ID              NUMBER(9)                       not null,
   BEGIN_DATE           DATE                            not null,
   END_DATE            	DATE,
   SCALE_FACTOR         NUMBER(9,4)                     not null,
   ENTRY_DATE           DATE,
   constraint PK_DER_SCALE_FACTOR primary key (DER_ID, CASE_ID, BEGIN_DATE)
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

/*==============================================================*/
/* INDEX: FK_DER_SCALE_CASE                                     */
/*==============================================================*/
CREATE INDEX FK_DER_SCALE_CASE ON DER_SCALE_FACTOR (
   CASE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DER_SEG_RESULT_DEFAULT_EXT                            */
/*==============================================================*/

create table DER_SEG_RESULT_DEFAULT_EXT  (
   PROGRAM_ID NUMBER(9) not null,
   SERVICE_ZONE_ID NUMBER(9) not null,
   EXTERNAL_SYSTEM_ID NUMBER(9) not null,
   constraint PK_DER_SEG_RESULT_DFLT_EXT primary key (PROGRAM_ID, SERVICE_ZONE_ID, EXTERNAL_SYSTEM_ID)
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

/*==============================================================*/
/* Table: DER_SEG_RESULT_IS_EXTERNAL                            */
/*==============================================================*/

create table DER_SEG_RESULT_IS_EXTERNAL  (
   RESULT_DAY DATE not null,
   PROGRAM_ID NUMBER(9) not null,
   SERVICE_ZONE_ID NUMBER(9) not null,
   EXTERNAL_SYSTEM_ID NUMBER(9) not null,
   SCENARIO_ID NUMBER(9) not null,
   CUT_BEGIN_DATE DATE not null,
   CUT_END_DATE DATE not null,
   IS_EXTERNAL NUMBER(1) not null,
   constraint PK_DER_SEG_RESULT_IS_EXT primary key (RESULT_DAY, PROGRAM_ID, SERVICE_ZONE_ID, EXTERNAL_SYSTEM_ID, SCENARIO_ID)
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


/*==============================================================*/
/* Table: DER_SEGMENT_RESULT                                           */
/*==============================================================*/

create table DER_SEGMENT_RESULT  (
   DER_SEGMENT_RESULT_ID NUMBER(9) not null,
   PROGRAM_ID NUMBER(9) not null,
   SERVICE_ZONE_ID NUMBER(9) not null,
   SUB_STATION_ID NUMBER(9) not null,
   FEEDER_ID NUMBER(9) not null,
   FEEDER_SEGMENT_ID NUMBER(9) not null,
   EXTERNAL_SYSTEM_ID NUMBER(9) not null,
   IS_EXTERNAL NUMBER(1) not null,
   SERVICE_CODE CHAR(1) not null,
   SCENARIO_ID NUMBER(9) not null,
   ENTRY_DATE DATE,
   constraint PK_DER_SEGMENT_RESULT primary key (DER_SEGMENT_RESULT_ID)
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

alter table DER_SEGMENT_RESULT
   add constraint AK_DER_SEGMENT_RESULT unique (PROGRAM_ID, SERVICE_ZONE_ID, SUB_STATION_ID, FEEDER_ID, FEEDER_SEGMENT_ID, EXTERNAL_SYSTEM_ID, IS_EXTERNAL, SERVICE_CODE, SCENARIO_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: DER_SEGMENT_RESULT_IX01                               */
/*==============================================================*/
--Used in the rollup from DER_DAILY_RESULTs to DER_SEGMENT_RESULTs
create index DER_SEGMENT_RESULT_IX01 on DER_SEGMENT_RESULT (
   PROGRAM_ID ASC,
   SERVICE_ZONE_ID ASC,
   IS_EXTERNAL ASC,
   SERVICE_CODE ASC,
   SCENARIO_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* INDEX: FK_DER_SEGMENT_RESULT_EXT_SYS                         */
/*==============================================================*/
CREATE INDEX FK_DER_SEGMENT_RESULT_EXT_SYS ON DER_SEGMENT_RESULT (
   EXTERNAL_SYSTEM_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_SEGMENT_RESULT_SCEN                            */
/*==============================================================*/
CREATE INDEX FK_DER_SEGMENT_RESULT_SCEN ON DER_SEGMENT_RESULT (
   SCENARIO_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_SEGMENT_RESULT_SEGMENT                         */
/*==============================================================*/
CREATE INDEX FK_DER_SEGMENT_RESULT_SEGMENT ON DER_SEGMENT_RESULT (
   FEEDER_SEGMENT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DER_SEGMENT_RESULT_DATA                               */
/*==============================================================*/

create table DER_SEGMENT_RESULT_DATA  (
   DER_SEGMENT_RESULT_ID     NUMBER(9) not null,
   RESULT_DATE               DATE not null,
   LOAD_VAL                  NUMBER(14,4) not null,
   FAILURE_VAL               NUMBER(10,4) not null,
   OPT_OUT_VAL               NUMBER(10,4) not null,
   OVERRIDE_VAL              NUMBER(10,4) not null,
   TX_LOSS_VAL               NUMBER(10,4) not null,
   DX_LOSS_VAL               NUMBER(10,4) not null,
   DER_COUNT                 NUMBER(9),
   UNCONSTRAINED_LOAD_VAL    NUMBER(14,4),
   UNCONSTRAINED_TX_LOSS_VAL NUMBER(10,4),
   UNCONSTRAINED_DX_LOSS_VAL NUMBER(10,4),
   constraint PK_DER_SEGMENT_RESULT_DATA primary key (DER_SEGMENT_RESULT_ID, RESULT_DATE)
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

/*==============================================================*/
/* Table: DER_STATUS                                           */
/*==============================================================*/


create table DER_STATUS (
   DER_ID               NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE      		DATE,
   STATUS_NAME          VARCHAR2(32)                     not null,
   ENTRY_DATE           DATE,
   constraint PK_DER_STATUS primary key (DER_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Table: DER_TYPE                                              */
/*==============================================================*/


create table DER_TYPE (
   DER_TYPE_ID                NUMBER(9)                        not null,
   DER_TYPE_NAME              VARCHAR2(64)                     not null,
   DER_TYPE_ALIAS             VARCHAR2(32),
   DER_TYPE_DESC              VARCHAR2(256),
   DER_TYPE_FUNCTION		  VARCHAR2(64),
   DER_TYPE_CATEGORY          VARCHAR2(64),
   DEFAULT_FAILURE_PCT        NUMBER(5,2),
   USE_DEFAULT_FAIL_PCT       NUMBER(1),
   EXTERNAL_IDENTIFIER        VARCHAR2(32),
   ENTRY_DATE                 DATE,
   constraint PK_DER_TYPE primary key (DER_TYPE_ID)
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


alter table DER_TYPE
   add constraint AK_DER_TYPE unique (DER_TYPE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: DER_TYPE_CALENDAR                                     */
/*==============================================================*/


create table DER_TYPE_CALENDAR (
   DER_TYPE_ID              NUMBER(9)                        not null,
   CASE_ID                  NUMBER(9)                        not null,
   BEGIN_DATE               DATE                             not null,
   END_DATE                 DATE,
   CALENDAR_ID              NUMBER(9)                        not null,
   ENTRY_DATE               DATE,
   constraint PK_DER_TYPE_CALENDAR primary key (DER_TYPE_ID, CASE_ID, BEGIN_DATE)
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

/*==============================================================*/
/* INDEX: FK_DER_TYPE_CAL                                       */
/*==============================================================*/
CREATE INDEX FK_DER_TYPE_CAL ON DER_TYPE_CALENDAR (
   CALENDAR_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_TYPE_CASE                                      */
/*==============================================================*/
CREATE INDEX FK_DER_TYPE_CASE ON DER_TYPE_CALENDAR (
   CASE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DER_TYPE_HISTORY                                      */
/*==============================================================*/


create table DER_TYPE_HISTORY (
   DER_TYPE_ID                NUMBER(9)                        not null,
   EVENT_ID                   NUMBER(9)                        not null,
   TOTAL_SIGNALED             NUMBER(9),
   TOTAL_FAILED               NUMBER(9),
   constraint PK_DER_TYPE_HISTORY primary key (DER_TYPE_ID, EVENT_ID)
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

/*==============================================================*/
/* Table: DER_VPP_RESULT                                        */
/*==============================================================*/

create table DER_VPP_RESULT
(
  DER_VPP_RESULT_ID         NUMBER(9) not null,
  PROGRAM_ID                NUMBER(9) not null,
  SERVICE_ZONE_ID           NUMBER(9) not null,
  IS_EXTERNAL               NUMBER(1) not null,
  SERVICE_CODE              CHAR(1) not null,
  SCENARIO_ID               NUMBER(9) not null,
   constraint PK_DER_VPP_RESULT primary key (DER_VPP_RESULT_ID)
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

alter table DER_VPP_RESULT
   add constraint AK_DER_VPP_RESULT unique (PROGRAM_ID,SERVICE_ZONE_ID, IS_EXTERNAL, SERVICE_CODE, SCENARIO_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_DER_VPP_RESULT_SCEN                                */
/*==============================================================*/
CREATE INDEX FK_DER_VPP_RESULT_SCEN ON DER_VPP_RESULT (
   SCENARIO_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DER_VPP_RESULT_DATA                            */
/*==============================================================*/


create table DER_VPP_RESULT_DATA
(
  DER_VPP_RESULT_ID NUMBER(9) not null,
  RESULT_DATE       DATE not null,
  LOAD_VAL          NUMBER(14,4) not null,
  FAILURE_VAL       NUMBER(10,4) not null,
  OPT_OUT_VAL       NUMBER(10,4) not null,
  OVERRIDE_VAL      NUMBER(10,4) not null,
  TX_LOSS_VAL       NUMBER(10,4) not null,
  DX_LOSS_VAL       NUMBER(10,4) not null,
  DER_COUNT         NUMBER(9),
  UNCONSTRAINED_LOAD_VAL    NUMBER(14,4),
  UNCONSTRAINED_TX_LOSS_VAL NUMBER(10,4),
  UNCONSTRAINED_DX_LOSS_VAL NUMBER(10,4),
   constraint PK_DER_VPP_RESULT_DATA primary key (DER_VPP_RESULT_ID, RESULT_DATE)
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

/*==============================================================*/
/* Table: DR_EVENT                            */
/*==============================================================*/
create table DR_EVENT  (
   EVENT_ID  NUMBER(9) not null,
   EVENT_NAME VARCHAR2(32) not null,
   EVENT_ALIAS VARCHAR2(32),
   EVENT_DESC  VARCHAR2(256),
   VPP_ID NUMBER(9) not null,
   EVENT_STATUS VARCHAR2(32) not null,
   START_TIME DATE,
   STOP_TIME DATE,
   EVENT_TYPE VARCHAR2(16),
   ENTRY_DATE DATE,
   constraint PK_DR_EVENT primary key (EVENT_ID)
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

alter table DR_EVENT
   add constraint AK_EVENT_NAME unique (EVENT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table DR_EVENT
   add constraint AK_VPP_START_TIME unique (VPP_ID, START_TIME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: DR_EVENT_EXCEPTION                            */
/*==============================================================*/
create table DR_EVENT_EXCEPTION  (
   EVENT_ID  NUMBER(9) not null,
   DER_ID  NUMBER(9) not null,
   EXCEPTION_TYPE VARCHAR2(32) not null,
   EXCEPTION_DATE DATE not null,
   ENTRY_DATE DATE not null,
   constraint PK_DR_EVENT_EXCEPTION primary key (EVENT_ID, DER_ID /* TODO ???? */)
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

alter table DR_EVENT_EXCEPTION
   add constraint CK01_EVENT_EXCEPTION_TYPE check (EXCEPTION_TYPE IN ('Opt Out', 'Failure', 'Override'))
/

/*==============================================================*/
/* INDEX: FK_DR_EVENT_EXCEPTION_DER                             */
/*==============================================================*/
CREATE INDEX FK_DR_EVENT_EXCEPTION_DER ON DR_EVENT_EXCEPTION (
   DER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DR_EVENT_PARTICIPATION                            */
/*==============================================================*/
create table DR_EVENT_PARTICIPATION  (
   EVENT_ID  NUMBER(9) not null,
   DER_ID NUMBER(9) not null,
   ENTRY_DATE DATE not null,
   constraint PK_DR_EVENT_PARTICIPATION primary key (EVENT_ID, DER_ID)
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

/*==============================================================*/
/* INDEX: FK_DR_EVENT_PARTICIPATION_DER                         */
/*==============================================================*/
CREATE INDEX FK_DR_EVENT_PARTICIPATION_DER ON DR_EVENT_PARTICIPATION (
   DER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DR_EVENT_SCHEDULE                            */
/*==============================================================*/
create table DR_EVENT_SCHEDULE  (
   EVENT_ID  NUMBER(9) not null,
   SCHEDULE_DATE DATE not null,
   AMOUNT NUMBER(14,4),
   PRICE NUMBER(10,3),
   constraint PK_DR_EVENT_SCHEDULE primary key (EVENT_ID, SCHEDULE_DATE)
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

/*==============================================================*/
/* Table: DER_DAILY_RESULT                                      */
/*==============================================================*/


create table DER_DAILY_RESULT  (
   DER_ID                    NUMBER(9)                        not null,
   IS_EXTERNAL               NUMBER(1)                        not null,
   SERVICE_CODE              CHAR(1)                          not null,
   SCENARIO_ID               NUMBER(9)                        not null,
   RESULT_DAY                DATE                             not null,
   SOURCE_TIME_ZONE          VARCHAR2(16)                     not null,
   CUT_BEGIN_DATE            DATE                             not null,
   CUT_END_DATE              DATE                             not null,
   RESULT_INTERVAL           VARCHAR2(16)                     not null,
   LOAD_SHAPE_RESULT_ID      NUMBER(9)                        not null,
   TX_LOSS_FACTOR_RESULT_ID  NUMBER(9),
   DX_LOSS_FACTOR_RESULT_ID  NUMBER(9),
   HITS_REMAINING_RESULT_ID  NUMBER(9),
   SCALE_FACTOR              NUMBER(14,6)                     not null,
   FAILURE_RATE              NUMBER(5,4)                      not null,
   OPT_OUT_RATE              NUMBER(5,4)                      not null,
   OVERRIDE_RATE             NUMBER(5,4)                      not null,
   DER_TYPE_ID               NUMBER(9)                        not null,
   EXTERNAL_SYSTEM_ID        NUMBER(9)                        not null,
   PROGRAM_ID                NUMBER(9)                        not null,
   SERVICE_ZONE_ID           NUMBER(9)                        not null,
   SUB_STATION_ID            NUMBER(9)                        not null,
   FEEDER_ID                 NUMBER(9)                        not null,
   FEEDER_SEGMENT_ID         NUMBER(9)                        not null,
   ACCOUNT_ID                NUMBER(9)                        not null,
   SERVICE_LOCATION_ID       NUMBER(9)                        not null,
   EDC_ID                    NUMBER(9)                        not null,
   ENTRY_DATE                DATE,
   constraint PK_DER_DAILY_RESULT primary key (DER_ID, IS_EXTERNAL, SERVICE_CODE, SCENARIO_ID, RESULT_DAY)
       using index
       pctfree 10
       initrans 2
       maxtrans 255
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           minextents 1
           maxextents unlimited
       )
)
pctfree 10
initrans 1
maxtrans 255
storage
(
    initial 128K
    minextents 1
    maxextents unlimited
)
tablespace NERO_DATA
/


/*==============================================================*/
/* INDEX: DER_DAILY_RESULT_IX01                                 */
/*==============================================================*/
create index DER_DAILY_RESULT_IX01 on DER_DAILY_RESULT (
   FEEDER_SEGMENT_ID ASC,
   PROGRAM_ID ASC,
   EXTERNAL_SYSTEM_ID ASC,
   IS_EXTERNAL ASC,
   SERVICE_CODE ASC,
   SCENARIO_ID ASC,
   RESULT_DAY ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_ACCOUNT                           */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_ACCOUNT ON DER_DAILY_RESULT (
   ACCOUNT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_DER_TYPE                          */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_DER_TYPE ON DER_DAILY_RESULT (
   DER_TYPE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_DXLOSS                            */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_DXLOSS ON DER_DAILY_RESULT (
   DX_LOSS_FACTOR_RESULT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_EDC                               */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_EDC ON DER_DAILY_RESULT (
   EDC_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_EXTSYS                            */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_EXTSYS ON DER_DAILY_RESULT (
   EXTERNAL_SYSTEM_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_FEEDER                            */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_FEEDER ON DER_DAILY_RESULT (
   FEEDER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_HITS                              */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_HITS ON DER_DAILY_RESULT (
   HITS_REMAINING_RESULT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_LSR                               */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_LSR ON DER_DAILY_RESULT (
   LOAD_SHAPE_RESULT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_PROGRAM                           */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_PROGRAM ON DER_DAILY_RESULT (
   PROGRAM_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_SL                                */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_SL ON DER_DAILY_RESULT (
   SERVICE_LOCATION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_TXLOSS                            */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_TXLOSS ON DER_DAILY_RESULT (
   TX_LOSS_FACTOR_RESULT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/



/*==============================================================*/
/* INDEX: FK_DER_DAILY_RESULT_ZONE                              */
/*==============================================================*/
CREATE INDEX FK_DER_DAILY_RESULT_ZONE ON DER_DAILY_RESULT (
   SERVICE_ZONE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: DST_INTERVAL_MAP                                 */
/*==============================================================*/

create table DST_INTERVAL_MAP  (
   INTERVAL         VARCHAR2(16)                     not null, 
   SRC_DST_TYPE     NUMBER(1)                        not null, 
   TGT_DST_TYPE     NUMBER(1)                        not null,
   TGT_INTERVAL     NUMBER                           not null,
   SRC_INTERVAL     NUMBER                           not null, 
   constraint PK_DST_INTERVAL_MAP primary key (INTERVAL, SRC_DST_TYPE, TGT_DST_TYPE, TGT_INTERVAL)
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

/*==============================================================*/
/* Table: DST_TYPE                                 */
/*==============================================================*/


create table DST_TYPE  (
   DST_TYPE         NUMBER(1)                        not null,
   BEGIN_DATE       DATE                             not null,
   END_DATE         DATE                             not null,
   constraint PK_DST_TYPE primary key (DST_TYPE, BEGIN_DATE)
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


/*==============================================================*/
/* Table: DETERMINANT_CACHE_INTERVAL                            */
/*==============================================================*/


create global temporary table DETERMINANT_CACHE_INTERVAL  (
	OBJECT_ID			NUMBER(9),
	UOM					VARCHAR2(32),
	TEMPLATE_ID			NUMBER(9),
	LOAD_DATE			DATE,
	PERIOD_ID			NUMBER(9),
	OPERATION_CODE		VARCHAR2(1),
	LOAD_VAL			NUMBER,
	LOSS_VAL			NUMBER,
	UFE_VAL				NUMBER
) on commit preserve rows
/

/*==============================================================*/
/* INDEX: DETERMINANT_CACHE_INTVL_IX01                          */
/*==============================================================*/
CREATE INDEX DETERMINANT_CACHE_INTVL_IX01 ON DETERMINANT_CACHE_INTERVAL (
   OBJECT_ID ASC,
   UOM ASC,
   TEMPLATE_ID ASC,
   LOAD_DATE ASC,
   PERIOD_ID ASC,
   OPERATION_CODE ASC
)
/



/*==============================================================*/
/* Table: DETERMINANT_CACHE_PERIOD                              */
/*==============================================================*/


create global temporary table DETERMINANT_CACHE_PERIOD  (
	OBJECT_ID			NUMBER(9),
	UOM					VARCHAR2(32),
	TEMPLATE_ID			NUMBER(9),
	PERIOD_ID			NUMBER(9),
	BEGIN_DATE			DATE,
	END_DATE			DATE,
	ENERGY				NUMBER,
	DEMAND				NUMBER
) on commit preserve rows
/

/*==============================================================*/
/* INDEX: DETERMINANT_CACHE_PERIOD_IX01                         */
/*==============================================================*/
CREATE INDEX DETERMINANT_CACHE_PERIOD_IX01 ON DETERMINANT_CACHE_PERIOD (
   OBJECT_ID ASC,
   UOM ASC,
   TEMPLATE_ID ASC,
   PERIOD_ID ASC,
   BEGIN_DATE ASC,
   END_DATE ASC
)
/



/*==============================================================*/
/* Table: EDC_CONVERSION_FACTOR                                 */
/*==============================================================*/


create table EDC_CONVERSION_FACTOR  (
   EDC_ID               NUMBER(9)                        not null,
   SERVICE_AREA_ID      NUMBER(9)                        not null,
   FACTOR_CODE          CHAR(1)                          not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   FACTOR_VAL           NUMBER(8,6),
   ENTRY_DATE           DATE,
   constraint PK_EDC_CONVERSION_FACTOR primary key (EDC_ID, SERVICE_AREA_ID, BEGIN_DATE, FACTOR_CODE)
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


/*==============================================================*/
/* Table: EDC_LOSS_FACTOR                                       */
/*==============================================================*/


create table EDC_LOSS_FACTOR  (
   EDC_ID               NUMBER(9)                        not null,
   CASE_ID              NUMBER(9)                        not null,
   LOSS_FACTOR_ID       NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_EDC_LOSS_FACTOR primary key (EDC_ID, CASE_ID, LOSS_FACTOR_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_EDC_LOSS_FACTOR                                    */
/*==============================================================*/
create index FK_EDC_LOSS_FACTOR on EDC_LOSS_FACTOR (
   LOSS_FACTOR_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: EDC_RATE_CLASS                                        */
/*==============================================================*/


create table EDC_RATE_CLASS  (
   EDC_ID               NUMBER(9)                        not null,
   RATE_CLASS           VARCHAR2(16)                     not null,
   constraint PK_EDC_RATE_CLASS primary key (EDC_ID, RATE_CLASS)
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


/*==============================================================*/
/* Table: EDC_SETTLEMENT_AGENT                                  */
/*==============================================================*/


create table EDC_SETTLEMENT_AGENT  (
   SETTLEMENT_AGENT_NAME VARCHAR2(16)                     not null,
   constraint PK_EDC_SETTLEMENT_AGENT primary key (SETTLEMENT_AGENT_NAME)
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


/*==============================================================*/
/* Table: EDC_SYSTEM_UFE_LOAD                                   */
/*==============================================================*/


create table EDC_SYSTEM_UFE_LOAD  (
   MODEL_ID             NUMBER(1)                        not null,
   SCENARIO_ID          NUMBER(9)                        not null,
   AS_OF_DATE           DATE                             not null,
   SERVICE_CODE         CHAR(1)                          not null,
   LOAD_DATE            DATE                             not null,
   LOAD_CODE            CHAR(1)                          not null,
   EDC_ID               NUMBER(9)                        not null,
   UFE_SYSTEM_LOAD      NUMBER(12,3),
   UFE_SERVICE_LOAD     NUMBER(12,3),
   UFE_PARTICIPANT_LOAD NUMBER(12,3),
   constraint PK_EDC_SYSTEM_UFE_LOAD primary key (MODEL_ID, SCENARIO_ID, AS_OF_DATE, SERVICE_CODE, LOAD_DATE, LOAD_CODE, EDC_ID)
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


/*==============================================================*/
/* Table: EMAIL_LOG                                             */
/*==============================================================*/


create table EMAIL_LOG  (
   EMAIL_ID             NUMBER(9)                        not null,
   EMAIL_CATEGORY       VARCHAR2(128),
   EMAIL_STATUS         VARCHAR2(32),
   FROM_ADDRESS         VARCHAR2(128),
   SUBJECT              VARCHAR2(1024),
   PRIORITY             NUMBER(1),
   SEND_DATE            DATE,
   ENTRY_DATE           DATE,
   constraint PK_EMAIL_LOG primary key (EMAIL_ID)
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


/*==============================================================*/
/* Table: EMAIL_LOG_ATTACHMENT                                  */
/*==============================================================*/


create table EMAIL_LOG_ATTACHMENT  (
   EMAIL_ID             NUMBER(9)                        not null,
   CONTENT_ORDER        NUMBER(3)                        not null,
   FILE_NAME            VARCHAR2(256),
   CONTENT_TYPE         VARCHAR2(64),
   IS_INLINE            NUMBER(1),
   TRANSFER_ENCODING    VARCHAR2(64),
   CONTENTS             CLOB,
   constraint PK_EMAIL_LOG_ATTACHMENT primary key (EMAIL_ID, CONTENT_ORDER)
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


/*==============================================================*/
/* Table: EMAIL_LOG_RECIPIENT                                   */
/*==============================================================*/


create table EMAIL_LOG_RECIPIENT  (
   EMAIL_ID             NUMBER(9)                        not null,
   RECIPIENT_TYPE       VARCHAR2(4)                      not null,
   RECIPIENT_ADDRESS    VARCHAR2(128)                    not null,
   constraint PK_EMAIL_LOG_RECIPIENT primary key (EMAIL_ID, RECIPIENT_TYPE, RECIPIENT_ADDRESS)
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


/*==============================================================*/
/* Table: ENERGY_DISTRIBUTION_COMPANY                           */
/*==============================================================*/


create table ENERGY_DISTRIBUTION_COMPANY  (
   EDC_ID               NUMBER(9)                        not null,
   EDC_NAME             VARCHAR2(64)                     not null,
   EDC_ALIAS            VARCHAR2(32),
   EDC_DESC             VARCHAR2(256),
   EDC_STATUS           VARCHAR2(16),
   EDC_DUNS_NUMBER      VARCHAR2(16),
   EDC_EXTERNAL_IDENTIFIER VARCHAR2(64),
   EDC_SETTLEMENT_AGENT_NAME VARCHAR2(16),
   EDC_LOSS_FACTOR_OPTION VARCHAR2(16),
   EDC_SYSTEM_LOAD_ID   NUMBER(9),
   EDC_MARKET_PRICE_ID  NUMBER(9),
   EDC_HOLIDAY_SET_ID   NUMBER(9),
   EDC_SC_ID            NUMBER(9),
   EDC_EXCLUDE_LOAD_SCHEDULE NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_ENERGY_DISTRIBUTION_COMPANY primary key (EDC_ID)
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


alter table ENERGY_DISTRIBUTION_COMPANY
   add constraint AK_ENERGY_DISTRIBUTION_COMPANY unique (EDC_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ENERGY_SERVICE_PROVIDER                               */
/*==============================================================*/


create table ENERGY_SERVICE_PROVIDER  (
   ESP_ID               NUMBER(9)                        not null,
   ESP_NAME             VARCHAR2(32)                     not null,
   ESP_ALIAS            VARCHAR2(32),
   ESP_DESC             VARCHAR2(256),
   ESP_EXTERNAL_IDENTIFIER VARCHAR2(64),
   ESP_DUNS_NUMBER      VARCHAR2(16),
   ESP_STATUS           VARCHAR2(16),
   ESP_TYPE             VARCHAR2(16),
   ESP_EXCLUDE_LOAD_SCHEDULE NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_ENERGY_SERVICE_PROVIDER primary key (ESP_ID)
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


alter table ENERGY_SERVICE_PROVIDER
   add constraint AK_ENERGY_SERVICE_PROVIDER unique (ESP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ENTITY_ATTRIBUTE                                      */
/*==============================================================*/


create table ENTITY_ATTRIBUTE  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ATTRIBUTE_NAME       VARCHAR2(32)                     not null,
   ATTRIBUTE_ID         NUMBER(9),
   ATTRIBUTE_TYPE       VARCHAR2(16),
   ATTRIBUTE_SHOW       NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_ENTITY_ATTRIBUTE primary key (ENTITY_DOMAIN_ID, ATTRIBUTE_NAME)
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


/*==============================================================*/
/* Table: ENTITY_ATTRIBUTE_CHARGE                               */
/*==============================================================*/


create table ENTITY_ATTRIBUTE_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   ATTRIBUTE_ID         NUMBER(9)                        not null,
   CHARGE_DATE          DATE                             not null,
   PEAK_DATE            DATE,
   PEAK_QUANTITY        NUMBER(12,4),
   CHARGE_QUANTITY      NUMBER(12,4),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(12,4),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_ENTITY_ATTRIBUTE_CHARGE primary key (CHARGE_ID, ENTITY_DOMAIN_ID, ENTITY_ID, ATTRIBUTE_ID, CHARGE_DATE)
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


/*==============================================================*/
/* Table: ENTITY_CONFIG_DICTIONARY                              */
/*==============================================================*/


create table ENTITY_CONFIG_DICTIONARY  (
   MODEL_ID             NUMBER(1)                        not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   MODULE               VARCHAR(16)                      not null,
   KEY1                 VARCHAR(32)                      not null,
   KEY2                 VARCHAR(32)                      not null,
   KEY3                 VARCHAR(32)                      not null,
   VALUE                VARCHAR(512),
   constraint PK_ENTITY_CONFIG_DICTIONARY primary key (MODEL_ID, ENTITY_DOMAIN_ID, ENTITY_ID, MODULE, KEY1, KEY2, KEY3)
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


/*==============================================================*/
/* Table: ENTITY_DOMAIN                                         */
/*==============================================================*/


create table ENTITY_DOMAIN  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_DOMAIN_NAME   VARCHAR2(32)                     not null,
   ENTITY_DOMAIN_ALIAS  VARCHAR2(32),
   ENTITY_DOMAIN_DESC   VARCHAR2(256),
   ENTITY_DOMAIN_TABLE  VARCHAR2(30),
   ENTITY_DOMAIN_TABLE_ALIAS VARCHAR2(32),
   ENTITY_DOMAIN_CATEGORY VARCHAR2(32),
   DISPLAY_NAME         VARCHAR2(32),
   INCLUDE_CONTACT_ADDRESS NUMBER(1),
   INCLUDE_ENTITY_ATTRIBUTE NUMBER(1),
   INCLUDE_EXTERNAL_IDENTIFIER NUMBER(1),
   INCLUDE_GROUPS       NUMBER(1),
   INCLUDE_NOTES        NUMBER(1),
   IS_PSEUDO            NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_ENTITY_DOMAIN primary key (ENTITY_DOMAIN_ID)
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


comment on column ENTITY_DOMAIN.INCLUDE_CONTACT_ADDRESS is
'Flag controlling whether this Entity gets a Contacts and Addresses tab in the Entity Manager.'
/


comment on column ENTITY_DOMAIN.INCLUDE_ENTITY_ATTRIBUTE is
'Flag controlling whether this Entity gets a Custom Attribtues tab in the Entity Manager.'
/


comment on column ENTITY_DOMAIN.INCLUDE_EXTERNAL_IDENTIFIER is
'Flag controlling whether this Entity gets an External Identifier tab in the Entity Manager.'
/


comment on column ENTITY_DOMAIN.INCLUDE_GROUPS is
'Flag controlling whether this Entity gets a Groups tab in the Entity Manager.'
/

comment on column ENTITY_DOMAIN.INCLUDE_NOTES is
'Flag controlling whether this Entity gets a Notes tab in the Entity Manager.'
/


comment on column ENTITY_DOMAIN.IS_PSEUDO is
'Pseudo-domains are alternative ways of grouping entities - for instance Purchaser as a pseudo-domain of PSEs. They do not show up in the Entity Manager'
/


alter table ENTITY_DOMAIN
   add constraint AK_ENTITY_DOMAIN unique (ENTITY_DOMAIN_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ENTITY_DOMAIN_ADDRESS                                 */
/*==============================================================*/


create table ENTITY_DOMAIN_ADDRESS  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   OWNER_ENTITY_ID      NUMBER(9)                        not null,
   CATEGORY_ID          NUMBER(9)                        not null,
   STREET               VARCHAR2(64),
   STREET2              VARCHAR2(64),
   GEOGRAPHY_ID         NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_ENTITY_DOMAIN_ADDRESS primary key (ENTITY_DOMAIN_ID, OWNER_ENTITY_ID, CATEGORY_ID)
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


/*==============================================================*/
/* Index: FK_ENTITY_DOMAIN_ADDRESS                              */
/*==============================================================*/
create index FK_ENTITY_DOMAIN_ADDRESS on ENTITY_DOMAIN_ADDRESS (
   GEOGRAPHY_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: FK_ENTITY_DOMAIN_ADDRESS_CAT                          */
/*==============================================================*/
create index FK_ENTITY_DOMAIN_ADDRESS_CAT on ENTITY_DOMAIN_ADDRESS (
   CATEGORY_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ENTITY_DOMAIN_CONTACT                                 */
/*==============================================================*/


create table ENTITY_DOMAIN_CONTACT  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   OWNER_ENTITY_ID      NUMBER(9)                        not null,
   CATEGORY_ID          NUMBER(9)                        not null,
   CONTACT_ID           NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_ENTITY_DOMAIN_CONTACT primary key (ENTITY_DOMAIN_ID, OWNER_ENTITY_ID, CATEGORY_ID, CONTACT_ID)
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


/*==============================================================*/
/* Index: FK_ENTITY_DOMAIN_CONTACT                              */
/*==============================================================*/
create index FK_ENTITY_DOMAIN_CONTACT on ENTITY_DOMAIN_CONTACT (
   CONTACT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: FK_ENTITY_DOMAIN_CONTACT_CAT                          */
/*==============================================================*/
create index FK_ENTITY_DOMAIN_CONTACT_CAT on ENTITY_DOMAIN_CONTACT (
   CATEGORY_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ENTITY_GRAVEYARD                                      */
/*==============================================================*/


create table ENTITY_GRAVEYARD  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   ENTITY_NAME          VARCHAR2(128),
   DELETED_DATE         DATE,
   constraint PK_ENTITY_GRAVEYARD primary key (ENTITY_DOMAIN_ID, ENTITY_ID)
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


/*==============================================================*/
/* Table: ENTITY_GRAVEYARD_REALM                                */
/*==============================================================*/


create table ENTITY_GRAVEYARD_REALM  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   REALM_ID             NUMBER(9)                        not null,
   constraint PK_ENTITY_GRAVEYARD_REALM primary key (ENTITY_DOMAIN_ID, ENTITY_ID, REALM_ID)
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


/*==============================================================*/
/* Index: FK_ENTITY_GRAVEYARD_REALM                             */
/*==============================================================*/
create index FK_ENTITY_GRAVEYARD_REALM on ENTITY_GRAVEYARD_REALM (
   REALM_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: ENTITY_GROUP                                          */
/*==============================================================*/


create table ENTITY_GROUP  (
   ENTITY_GROUP_ID      NUMBER(9)                        not null,
   ENTITY_GROUP_NAME    VARCHAR2(32)                     not null,
   ENTITY_GROUP_ALIAS   VARCHAR2(32),
   ENTITY_GROUP_DESC    VARCHAR2(64),
   ENTITY_DOMAIN_ID     NUMBER(9),
   PARENT_GROUP_ID      NUMBER(9),
   IS_MATRIX            NUMBER(1),
   GROUP_CATEGORY       VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_ENTITY_GROUP primary key (ENTITY_GROUP_ID)
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


alter table ENTITY_GROUP
   add constraint CK01_ENTITY_GROUP check ((NVL(IS_MATRIX,0) = 0 OR PARENT_GROUP_ID IS NULL))
/


alter table ENTITY_GROUP
   add constraint AK_PSE_GROUP unique (ENTITY_GROUP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_PARENT_ENTITY_GROUP                                */
/*==============================================================*/
create index FK_PARENT_ENTITY_GROUP on ENTITY_GROUP (
   PARENT_GROUP_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: ENTITY_GROUP_ASSIGNMENT                               */
/*==============================================================*/


create table ENTITY_GROUP_ASSIGNMENT  (
   ENTITY_GROUP_ID      NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   ENTITY2_ID           NUMBER(9),
   ENTITY3_ID           NUMBER(9),
   ENTITY4_ID           NUMBER(9),
   ENTITY5_ID           NUMBER(9),
   ENTITY6_ID           NUMBER(9),
   ENTITY7_ID           NUMBER(9),
   ENTITY8_ID           NUMBER(9),
   ENTITY9_ID           NUMBER(9),
   ENTITY10_ID          NUMBER(9),
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


alter table ENTITY_GROUP_ASSIGNMENT
   add constraint AK_ENTITY_GROUP_ASSIGNMENT unique (ENTITY_GROUP_ID, BEGIN_DATE, ENTITY_ID, ENTITY2_ID, ENTITY3_ID, ENTITY4_ID, ENTITY5_ID, ENTITY6_ID, ENTITY7_ID, ENTITY8_ID, ENTITY9_ID, ENTITY10_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ESP_POOL                                              */
/*==============================================================*/


create table ESP_POOL  (
   ESP_ID               NUMBER(9)                        not null,
   POOL_ID              NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ALLOCATION_PCT       NUMBER(9,6),
   ENTRY_DATE           DATE,
   constraint PK_ESP_POOL primary key (ESP_ID, POOL_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: ETAG                                                  */
/*==============================================================*/


create table ETAG  (
   ETAG_ID              NUMBER(9)                        not null,
   ETAG_NAME            VARCHAR2(32)                     not null,
   ETAG_ALIAS           VARCHAR2(32),
   ETAG_DESC            VARCHAR2(256),
   TAG_IDENT            VARCHAR2(32)                     not null,
   GCA_CODE             VARCHAR2(7)                      not null,
   PSE_CODE             VARCHAR2(7)                      not null,
   TAG_CODE             VARCHAR2(7)                      not null,
   LCA_CODE             VARCHAR2(7)                      not null,
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   ETAG_STATUS          VARCHAR2(32),
   SECURITY_KEY         VARCHAR2(20),
   WSCC_PRESCHEDULE_FLAG CHAR(1),
   TEST_FLAG            CHAR(1),
   TRANSACTION_TYPE     VARCHAR2(16),
   NOTES                VARCHAR2(128),
   ENTRY_DATE           DATE,
   constraint PK_ETAG primary key (ETAG_ID)
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


alter table ETAG
   add constraint AK_ETAG unique (ETAG_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ETAG_LIST                                             */
/*==============================================================*/


create table ETAG_LIST  (
   ETAG_ID              NUMBER(9)                        not null,
   ETAG_LIST_ID         NUMBER(9)                        not null,
   LIST_TYPE            VARCHAR2(32),
   LIST_USED_BY         VARCHAR2(32),
   constraint PK_ETAG_LIST primary key (ETAG_ID, ETAG_LIST_ID)
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


/*==============================================================*/
/* Table: ETAG_LIST_ITEM                                        */
/*==============================================================*/


create table ETAG_LIST_ITEM  (
   ETAG_ID              NUMBER(9)                        not null,
   ETAG_ITEM_ID         NUMBER(9)                        not null,
   ETAG_LIST_ID         NUMBER(9),
   ETAG_ITEM            VARCHAR2(128),
   constraint PK_ETAG_LIST_ITEM primary key (ETAG_ID, ETAG_ITEM_ID)
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


/*==============================================================*/
/* Index: FK_ETAG_LIST_ITEM                                     */
/*==============================================================*/
create index FK_ETAG_LIST_ITEM on ETAG_LIST_ITEM (
   ETAG_ID ASC, ETAG_LIST_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: ETAG_LOSS_METHOD                                      */
/*==============================================================*/


create table ETAG_LOSS_METHOD  (
   ETAG_ID              NUMBER(9)                        not null,
   PHYSICAL_SEGMENT_NID NUMBER(9)                        not null,
   START_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOSS_CORRECTION_NID  NUMBER(9),
   REQUEST_REF          NUMBER(9),
   LOSS_TYPE            VARCHAR2(32),
   LOSS_TYPE_LIST_ID    NUMBER(9),
   constraint PK_ETAG_LOSS_METHOD primary key (ETAG_ID, PHYSICAL_SEGMENT_NID, START_DATE, END_DATE)
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


/*==============================================================*/
/* Table: ETAG_MARKET_SEGMENT                                   */
/*==============================================================*/


create table ETAG_MARKET_SEGMENT  (
   ETAG_ID              NUMBER(9)                        not null,
   MARKET_SEGMENT_NID   NUMBER(9)                        not null,
   CURRENT_CORRECTION_NID NUMBER(9)                        not null,
   PSE_CODE             NUMBER(9)                        not null,
   ENERGY_PRODUCT_REF   NUMBER(4),
   CONTRACT_NUMBER_LIST_ID NUMBER(9),
   MISC_INFO_LIST_ID    NUMBER(9),
   constraint PK_ETAG_MARKET_SEGMENT primary key (ETAG_ID, MARKET_SEGMENT_NID)
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


/*==============================================================*/
/* Table: ETAG_MESSAGE_INFO                                     */
/*==============================================================*/


create table ETAG_MESSAGE_INFO  (
   ETAG_ID              NUMBER(9)                        not null,
   MESSAGE_TYPE         VARCHAR2(64)                     not null,
   MESSAGE_CALL_DATE    DATE                             not null,
   FROM_ENTITY_CODE     NUMBER(9),
   FROM_ENTITY_TYPE     VARCHAR2(16),
   TO_ENTITY_CODE       NUMBER(9),
   TO_ENTITY_TYPE       VARCHAR2(16),
   constraint PK_ETAG_MESSAGE_INFO primary key (ETAG_ID, MESSAGE_TYPE, MESSAGE_CALL_DATE)
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


/*==============================================================*/
/* Table: ETAG_PROFILE                                          */
/*==============================================================*/


create table ETAG_PROFILE  (
   PROFILE_KEY_ID       NUMBER(9)                        not null,
   ETAG_ID              NUMBER(9)                        not null,
   PARENT_TYPE          VARCHAR2(64)                     not null,
   PARENT_NID           NUMBER(9),
   PROFILE_STYLE        VARCHAR2(64),
   PROFILE_TYPE_LIST_ID NUMBER(9),
   constraint PK_ETAG_PROFILE primary key (PROFILE_KEY_ID)
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


/*==============================================================*/
/* Index: FK_ETAG_PROFILE                                       */
/*==============================================================*/
create index FK_ETAG_PROFILE on ETAG_PROFILE (
   ETAG_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: ETAG_PROFILE_LIST                                     */
/*==============================================================*/


create table ETAG_PROFILE_LIST  (
   ETAG_ID              NUMBER(9)                        not null,
   PROFILE_KEY_ID       NUMBER(9)                        not null,
   ETAG_LIST_ID         NUMBER(9)                        not null,
   constraint PK_ETAG_PROFILE_LIST primary key (ETAG_ID, PROFILE_KEY_ID, ETAG_LIST_ID)
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


/*==============================================================*/
/* Index: FK2_ETAG_PROFILE_LIST                                 */
/*==============================================================*/
create index FK2_ETAG_PROFILE_LIST on ETAG_PROFILE_LIST (
   PROFILE_KEY_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK3_ETAG_PROFILE_LIST                                 */
/*==============================================================*/
create index FK3_ETAG_PROFILE_LIST on ETAG_PROFILE_LIST (
   ETAG_ID ASC, ETAG_LIST_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: ETAG_PROFILE_VALUE                                    */
/*==============================================================*/


create table ETAG_PROFILE_VALUE  (
   PROFILE_KEY_ID       NUMBER(9)                        not null,
   START_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   MW_LEVEL             NUMBER(10),
   constraint PK_ETAG_PROFILE_VALUE primary key (PROFILE_KEY_ID, START_DATE, END_DATE)
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


/*==============================================================*/
/* Table: ETAG_RESOURCE                                         */
/*==============================================================*/


create table ETAG_RESOURCE  (
   ETAG_ID              NUMBER(9)                        not null,
   PHYSICAL_SEGMENT_NID NUMBER(9)                        not null,
   PROFILE_NID          NUMBER(9)                        not null,
   TAGGING_POINT_NID    NUMBER(9),
   CONTRACT_NUMBER_LIST_ID NUMBER(9),
   MISC_INFO_LIST_ID    NUMBER(9),
   constraint PK_ETAG_RESOURCE primary key (ETAG_ID, PHYSICAL_SEGMENT_NID, PROFILE_NID)
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


/*==============================================================*/
/* Table: ETAG_RESOURCE_SEGMENT                                 */
/*==============================================================*/


create table ETAG_RESOURCE_SEGMENT  (
   ETAG_ID              NUMBER(9)                        not null,
   PHYSICAL_SEGMENT_NID NUMBER(9)                        not null,
   SEGMENT_TYPE         VARCHAR2(32),
   MARKET_SEGMENT_NID   NUMBER(9),
   CURRENT_CORRECTION_NID NUMBER(4),
   constraint PK_ETAG_RESOURCE_SEGMENT primary key (ETAG_ID, PHYSICAL_SEGMENT_NID)
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


/*==============================================================*/
/* Index: FK_ETAG_RESOURCE_SEGMENT                              */
/*==============================================================*/
create index FK_ETAG_RESOURCE_SEGMENT on ETAG_RESOURCE_SEGMENT (
   ETAG_ID ASC, MARKET_SEGMENT_NID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: ETAG_STATUS                                           */
/*==============================================================*/


create table ETAG_STATUS  (
   ETAG_ID              NUMBER(9)                        not null,
   ENTITY_CODE_TYPE     VARCHAR2(10)                     not null,
   ENTITY_CODE          VARCHAR2(7)                      not null,
   MESSAGE_CALL_DATE    DATE                             not null,
   REQUEST_REF          NUMBER(9),
   DELIVERY_STATUS      VARCHAR2(16),
   APPROVAL_STATUS      VARCHAR2(16),
   APPROVAL_STATUS_TYPE VARCHAR2(16),
   APPROVAL_DATE        DATE,
   NOTES                VARCHAR2(128),
   constraint PK_ETAG_STATUS primary key (ETAG_ID, ENTITY_CODE_TYPE, ENTITY_CODE)
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


/*==============================================================*/
/* Table: ETAG_TRANSACTION                                      */
/*==============================================================*/


create table ETAG_TRANSACTION  (
   ETAG_ID              NUMBER(9)                        not null,
   TRANSACTION_ID       NUMBER(9)                        not null,
   constraint PK_ETAG_TRANSACTION primary key (ETAG_ID, TRANSACTION_ID)
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


/*==============================================================*/
/* Index: FK_ETAG_TRANSACTION_IT                                */
/*==============================================================*/
create index FK_ETAG_TRANSACTION_IT on ETAG_TRANSACTION (
   TRANSACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: ETAG_TRANSMISSION_ALLOCATION                          */
/*==============================================================*/


create table ETAG_TRANSMISSION_ALLOCATION  (
   ETAG_ID              NUMBER(9)                        not null,
   TRANSMISSION_ALLOCATION_NID NUMBER(9)                        not null,
   PHYSICAL_SEGMENT_NID NUMBER(9)                        not null,
   CURRENT_CORRECTION_NID NUMBER(9),
   TRANSMISSION_PRODUCT_NID NUMBER(9),
   CONTRACT_NUMBER      VARCHAR2(50),
   TRANSMISSION_CUSTOMER_CODE NUMBER(9),
   constraint PK_ETAG_TRANSMISSION_ALLOCATN primary key (ETAG_ID, TRANSMISSION_ALLOCATION_NID)
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


/*==============================================================*/
/* Index: FK_ETAG_TRANSMISSION_ALLOCATN                         */
/*==============================================================*/
create index FK_ETAG_TRANSMISSION_ALLOCATN on ETAG_TRANSMISSION_ALLOCATION (
   ETAG_ID ASC, PHYSICAL_SEGMENT_NID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: ETAG_TRANSMISSION_PROFILE                             */
/*==============================================================*/


create table ETAG_TRANSMISSION_PROFILE  (
   ETAG_ID              NUMBER(9)                        not null,
   PHYSICAL_SEGMENT_NID NUMBER(9)                        not null,
   POR_ETAG_PROFILE_NID NUMBER(9)                        not null,
   POD_ETAG_PROFILE_NID NUMBER(9)                        not null,
   constraint PK_ETAG_TRANSMISSION_PROFILE primary key (ETAG_ID, PHYSICAL_SEGMENT_NID, POR_ETAG_PROFILE_NID, POD_ETAG_PROFILE_NID)
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


/*==============================================================*/
/* Table: ETAG_TRANSMISSION_SEGMENT                             */
/*==============================================================*/


create table ETAG_TRANSMISSION_SEGMENT  (
   ETAG_ID              NUMBER(9)                        not null,
   PHYSICAL_SEGMENT_NID NUMBER(9)                        not null,
   SEGMENT_TYPE         VARCHAR2(32),
   MARKET_SEGMENT_NID   NUMBER(9),
   TP_CODE              NUMBER(9),
   POR_CODE             NUMBER(9),
   POD_CODE             NUMBER(9),
   CURRENT_CORRECTION_NID NUMBER(4),
   SCHEDULING_ENTITY_LIST_ID NUMBER(9),
   MISC_INFO_LIST_ID    NUMBER(9),
   constraint PK_ETAG_TRANSMISSION_SEGMENT primary key (ETAG_ID, PHYSICAL_SEGMENT_NID)
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


/*==============================================================*/
/* Index: FK_ETAG_TRANSMISSION_SEGMENT                          */
/*==============================================================*/
create index FK_ETAG_TRANSMISSION_SEGMENT on ETAG_TRANSMISSION_SEGMENT (
   ETAG_ID ASC, MARKET_SEGMENT_NID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: EXTERNAL_CREDENTIALS                                  */
/*==============================================================*/


create table EXTERNAL_CREDENTIALS  (
   CREDENTIAL_ID        NUMBER(9)                        not null,
   EXTERNAL_SYSTEM_ID   NUMBER(9)                        not null,
   EXTERNAL_ACCOUNT_NAME VARCHAR2(64)                     not null,
   USER_ID              NUMBER(9),
   EXTERNAL_USER_NAME   VARCHAR2(256),
   EXTERNAL_PASSWORD    VARCHAR2(64),
   ENTRY_DATE           DATE,
   constraint PK_EXTERNAL_CREDENTIALS primary key (CREDENTIAL_ID)
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


alter table EXTERNAL_CREDENTIALS
   add constraint AK_EXTERNAL_CREDENTIALS unique (EXTERNAL_SYSTEM_ID, EXTERNAL_ACCOUNT_NAME, USER_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_EXTERNAL_CREDENTIALS_USERS                         */
/*==============================================================*/
create index FK_EXTERNAL_CREDENTIALS_USERS on EXTERNAL_CREDENTIALS (
   USER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: EXTERNAL_CREDENTIALS_CERT                             */
/*==============================================================*/


create table EXTERNAL_CREDENTIALS_CERT  (
   CREDENTIAL_ID        NUMBER(9)                        not null,
   CERTIFICATE_TYPE     VARCHAR2(32)                     not null,
   CERTIFICATE_EXPIRATION_DATE DATE                             not null,
   CERTIFICATE_CONTENTS CLOB,
   CERTIFICATE_PASSWORD VARCHAR2(64),
   ENTRY_DATE           DATE,
   constraint PK_EXTERNAL_CREDENTIALS_CERT primary key (CREDENTIAL_ID, CERTIFICATE_TYPE, CERTIFICATE_EXPIRATION_DATE)
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


/*==============================================================*/
/* Table: EXTERNAL_SYSTEM                                       */
/*==============================================================*/


create table EXTERNAL_SYSTEM  (
   EXTERNAL_SYSTEM_ID   NUMBER(9)                        not null,
   EXTERNAL_SYSTEM_NAME VARCHAR2(64)                     not null,
   EXTERNAL_SYSTEM_ALIAS VARCHAR2(32),
   EXTERNAL_SYSTEM_DESC VARCHAR2(256),
   EXTERNAL_SYSTEM_TYPE VARCHAR2(32),
   EXTERNAL_SYSTEM_DISPLAY_NAME VARCHAR2(64),
   IS_ENABLED           NUMBER(1),
   EXTERNAL_ACCOUNT_DOMAIN_ID NUMBER(9),
   HAS_UNAME_PWD_CREDENTIALS NUMBER(1),
   NUMBER_OF_CERTIFICATES NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_EXTERNAL_SYSTEM primary key (EXTERNAL_SYSTEM_ID)
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


alter table EXTERNAL_SYSTEM
   add constraint AK_EXTERNAL_SYSTEM unique (EXTERNAL_SYSTEM_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_EXTERNAL_SYSTEM_ACCOUNT                            */
/*==============================================================*/
create index FK_EXTERNAL_SYSTEM_ACCOUNT on EXTERNAL_SYSTEM (
   EXTERNAL_ACCOUNT_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: EXTERNAL_SYSTEM_IDENTIFIER                            */
/*==============================================================*/


create table EXTERNAL_SYSTEM_IDENTIFIER  (
   EXTERNAL_SYSTEM_ID   NUMBER(9)                        not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   IDENTIFIER_TYPE      VARCHAR2(32)                   default 'Default'  not null,
   EXTERNAL_IDENTIFIER  VARCHAR2(128),
   ENTRY_DATE           DATE,
   constraint PK_EXTERNAL_SYSTEM_IDENTIFIER primary key (EXTERNAL_SYSTEM_ID, ENTITY_DOMAIN_ID, ENTITY_ID, IDENTIFIER_TYPE)
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

/*==============================================================*/
/* Index: EXTERNAL_SYSTEM_IDENT_IX01                            */
/*==============================================================*/
create index EXTERNAL_SYSTEM_IDENT_IX01 on EXTERNAL_SYSTEM_IDENTIFIER (
   EXTERNAL_SYSTEM_ID,
   ENTITY_DOMAIN_ID,
   IDENTIFIER_TYPE,
   EXTERNAL_IDENTIFIER,
   ENTITY_ID
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/



/*==============================================================*/
/* Table: FORMULA_CHARGE                                        */
/*==============================================================*/


create table FORMULA_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   ITERATOR_ID          NUMBER(9)                        not null,
   CHARGE_DATE          DATE                             not null,
   PERIOD_END_DATE      DATE,
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(16,6),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_FORMULA_CHARGE primary key (CHARGE_ID, ITERATOR_ID, CHARGE_DATE)
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

/*==============================================================*/
/* Table: TX_FEEDER                                             */
/*==============================================================*/
create table TX_FEEDER  (
   FEEDER_ID              NUMBER(9) not null,
   FEEDER_NAME            VARCHAR2(64) not null,
   FEEDER_ALIAS           VARCHAR2(32),
   FEEDER_DESC            VARCHAR2(256),
   EXTERNAL_IDENTIFIER    VARCHAR2(64),
   SUB_STATION_ID         NUMBER(9),
   BEGIN_DATE             DATE not null,
   END_DATE               DATE,
   ENTRY_DATE             DATE not null,
   constraint PK_TX_FEEDER primary key (FEEDER_ID)
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

alter table TX_FEEDER
   add constraint AK_TX_FEEDER unique (FEEDER_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* INDEX: FK_FEEDER_SUB_STATION                                 */
/*==============================================================*/
CREATE INDEX FK_FEEDER_SUB_STATION ON TX_FEEDER (
   SUB_STATION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: TX_FEEDER_SEGMENT                                     */
/*==============================================================*/
create table TX_FEEDER_SEGMENT  (
   FEEDER_SEGMENT_ID          NUMBER(9) not null,
   FEEDER_SEGMENT_NAME        VARCHAR2(64) not null,
   FEEDER_SEGMENT_ALIAS       VARCHAR2(32),
   FEEDER_SEGMENT_DESC        VARCHAR2(256),
   EXTERNAL_IDENTIFIER        VARCHAR2(64),
   FEEDER_ID                  NUMBER(9),
   BEGIN_DATE                 DATE not null,
   END_DATE                   DATE,
   PRIORITY                   NUMBER,
   ENTRY_DATE                 DATE not null,
   constraint PK_TX_FEEDER_SEGMENT primary key (FEEDER_SEGMENT_ID)
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

alter table TX_FEEDER_SEGMENT
   add constraint AK_TX_FEEDER_SEGMENT unique (FEEDER_SEGMENT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_FEEDER_SEG_FEEDER                                  */
/*==============================================================*/
CREATE INDEX FK_FEEDER_SEG_FEEDER ON TX_FEEDER_SEGMENT (
   FEEDER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: TX_FEEDER_SEGMENT_LOSS_FACTOR                         */
/*==============================================================*/
create table TX_FEEDER_SEGMENT_LOSS_FACTOR  (
   FEEDER_SEGMENT_ID          NUMBER(9) not null,
   BEGIN_DATE                 DATE not null,
   END_DATE                   DATE,
   LOSS_FACTOR_ID             NUMBER(9),
   ENTRY_DATE                 DATE not null,
   constraint PK_TX_SEGMENT_LOSS_FACTOR primary key (FEEDER_SEGMENT_ID, BEGIN_DATE)
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

/*==============================================================*/
/* INDEX: FK_SEG_LOSS_FACT_ID                                   */
/*==============================================================*/
CREATE INDEX FK_SEG_LOSS_FACT_ID ON TX_FEEDER_SEGMENT_LOSS_FACTOR (
   LOSS_FACTOR_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: FORMULA_CHARGE_DRILL_DOWN_TEMP                        */
/*==============================================================*/


create global temporary table FORMULA_CHARGE_DRILL_DOWN_TEMP (
   RECORD_DATE		DATE,
   PERIOD_END_DATE      DATE,
   DISPUTE_STATUS	VARCHAR2(16),
   ITERATOR1_NAME	VARCHAR2(32),
   ITERATOR1_VAL	VARCHAR2(256),
   ITERATOR2_NAME	VARCHAR2(32),
   ITERATOR2_VAL	VARCHAR2(256),
   ITERATOR3_NAME	VARCHAR2(32),
   ITERATOR3_VAL	VARCHAR2(256),
   ITERATOR4_NAME	VARCHAR2(32),
   ITERATOR4_VAL	VARCHAR2(256),
   ITERATOR5_NAME	VARCHAR2(32),
   ITERATOR5_VAL	VARCHAR2(256),
   ITERATOR6_NAME	VARCHAR2(32),
   ITERATOR6_VAL	VARCHAR2(256),
   ITERATOR7_NAME	VARCHAR2(32),
   ITERATOR7_VAL	VARCHAR2(256),
   ITERATOR8_NAME	VARCHAR2(32),
   ITERATOR8_VAL	VARCHAR2(256),
   ITERATOR9_NAME	VARCHAR2(32),
   ITERATOR9_VAL	VARCHAR2(256),
   ITERATOR10_NAME	VARCHAR2(32),
   ITERATOR10_VAL	VARCHAR2(256),
   CHARGE_QUANTITY	NUMBER(18,9),
   CHARGE_RATE		NUMBER(16,6),
   CHARGE_FACTOR	NUMBER(12,4),
   CHARGE_AMOUNT	NUMBER(16,6),
   BILL_QUANTITY	NUMBER(18,9),
   BILL_AMOUNT		NUMBER(12,2),
   CALC_ORDER		NUMBER(4),
   VIEW_ORDER		NUMBER(9),
   VARIABLE_NAME	VARCHAR2(64),
   VARIABLE_VALUE	NUMBER
) 
on commit preserve rows
/


/*==============================================================*/
/* Table: FORMULA_CHARGE_ITERATOR                               */
/*==============================================================*/


create table FORMULA_CHARGE_ITERATOR  (
   CHARGE_ID            NUMBER(12)                       not null,
   ITERATOR_ID          NUMBER(9)                        not null,
   ITERATOR1            VARCHAR2(256),
   ITERATOR2            VARCHAR2(256),
   ITERATOR3            VARCHAR2(256),
   ITERATOR4            VARCHAR2(256),
   ITERATOR5            VARCHAR2(256),
   ITERATOR6            VARCHAR2(256),
   ITERATOR7            VARCHAR2(256),
   ITERATOR8            VARCHAR2(256),
   ITERATOR9            VARCHAR2(256),
   ITERATOR10           VARCHAR2(256),
   constraint PK_FORMULA_CHARGE_ITERATOR primary key (CHARGE_ID, ITERATOR_ID)
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


alter table FORMULA_CHARGE_ITERATOR
   add constraint AK_FORMULA_CHARGE_ITERATOR unique (CHARGE_ID, ITERATOR1, ITERATOR2, ITERATOR3, ITERATOR4, ITERATOR5, ITERATOR6, ITERATOR7, ITERATOR8, ITERATOR9, ITERATOR10)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: FORMULA_CHARGE_ITERATOR_NAME                          */
/*==============================================================*/


create table FORMULA_CHARGE_ITERATOR_NAME  (
   CHARGE_ID            NUMBER(12)                       not null,
   ITERATOR_NAME1       VARCHAR2(32),
   ITERATOR_NAME2       VARCHAR2(32),
   ITERATOR_NAME3       VARCHAR2(32),
   ITERATOR_NAME4       VARCHAR2(32),
   ITERATOR_NAME5       VARCHAR2(32),
   ITERATOR_NAME6       VARCHAR2(32),
   ITERATOR_NAME7       VARCHAR2(32),
   ITERATOR_NAME8       VARCHAR2(32),
   ITERATOR_NAME9       VARCHAR2(32),
   ITERATOR_NAME10      VARCHAR2(32),
   constraint PK_FORMULA_CHARGE_ITER_NAME primary key (CHARGE_ID)
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


/*==============================================================*/
/* Table: FORMULA_CHARGE_VARIABLE                               */
/*==============================================================*/


create table FORMULA_CHARGE_VARIABLE  (
   CHARGE_ID            NUMBER(12)                       not null,
   ITERATOR_ID          NUMBER(9)                        not null,
   CHARGE_DATE          DATE                             not null,
   VARIABLE_NAME        VARCHAR2(64)                     not null,
   VARIABLE_VAL         NUMBER,
   ROW_NUMBER           NUMBER(4),
   constraint PK_FORMULA_CHARGE_VARIABLE primary key (CHARGE_ID, ITERATOR_ID, CHARGE_DATE, VARIABLE_NAME)
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


/*==============================================================*/
/* Table: FTR_CHARGE                                            */
/*==============================================================*/


create table FTR_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   SOURCE_ID            NUMBER(9)                        not null,
   DELIVERY_POINT_ID    NUMBER(9)                        not null,
   SINK_ID              NUMBER(9)                        not null,
   FTR_TYPE             VARCHAR2(16)                     not null,
   ALLOC_FACTOR         NUMBER(18,9),
   PURCHASES            NUMBER(18,9),
   SALES                NUMBER(18,9),
   PRICE1               NUMBER(16,6),
   PRICE2               NUMBER(16,6),
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_FTR_CHARGE primary key (CHARGE_ID, CHARGE_DATE, SOURCE_ID, DELIVERY_POINT_ID, SINK_ID, FTR_TYPE)
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
       )
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
)
/


/*==============================================================*/
/* Table: GAS_POSITION_WORK                                     */
/*==============================================================*/


create global temporary table GAS_POSITION_WORK  (
   WORK_ID              NUMBER(9)                        not null,
   TRANSACTION_ID       NUMBER(9)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   TRANSACTION_TYPE     VARCHAR2(32)                     not null,
   AMOUNT               NUMBER,
   constraint PK_GAS_POSITION_WORK primary key (WORK_ID, TRANSACTION_ID, SCHEDULE_DATE, TRANSACTION_TYPE)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: GEOGRAPHY                                             */
/*==============================================================*/


create table GEOGRAPHY  (
   GEOGRAPHY_ID         NUMBER(9)                        not null,
   GEOGRAPHY_NAME       VARCHAR2(128)                    not null,
   GEOGRAPHY_ALIAS      VARCHAR2(32),
   GEOGRAPHY_DESC       VARCHAR2(256),
   GEOGRAPHY_TYPE       VARCHAR2(32),
   PARENT_GEOGRAPHY_ID  NUMBER(9),
   DISPLAY_NAME         VARCHAR2(64),
   ABBREVIATION         VARCHAR2(8),
   ENTRY_DATE           DATE,
   constraint PK_GEOGRAPHY primary key (GEOGRAPHY_ID)
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


alter table GEOGRAPHY
   add constraint AK_GEOGRAPHY unique (GEOGRAPHY_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: GRANT_EXECUTE_EXCLUSIONS                              */
/*==============================================================*/


create table GRANT_EXECUTE_EXCLUSIONS  (
   OBJECT_TYPE          VARCHAR2(32)                     not null,
   OBJECT_NAME          VARCHAR2(32)                     not null,
   constraint PK_GRANT_EXECUTE_EXCLUSIONS primary key (OBJECT_TYPE, OBJECT_NAME)
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


/*==============================================================*/
/* Table: GRANT_OBJECTS                                         */
/*==============================================================*/


create table GRANT_OBJECTS  (
   OBJECT_TYPE          VARCHAR2(32)                     not null,
   OBJECT_NAME          VARCHAR2(32)                     not null,
   DOMAIN_NAME          VARCHAR2(64)                     not null,
   constraint PK_GRANT_OBJECTS primary key (OBJECT_TYPE, OBJECT_NAME, DOMAIN_NAME)
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


/*==============================================================*/
/* Table: GROUP_EXPORT                                          */
/*==============================================================*/


create table GROUP_EXPORT  (
   EXPORT_NAME          VARCHAR2(64)                     not null,
   EXPORT_GROUP         VARCHAR2(64),
   EXPORT_FORMAT        VARCHAR2(32),
   EXPORT_TYPE          CHAR(1),
   BEGIN_DATE_OFFSET    NUMBER(4),
   END_DATE_OFFSET      NUMBER(4),
   EXPORT_INTERVAL      VARCHAR2(16),
   EXPORT_UNITS         VARCHAR2(8),
   EXPORT_ACCOUNT_OPTION VARCHAR2(16),
   EXPORT_DELIMITER     VARCHAR2(16),
   EXPORT_DIRECTORY     VARCHAR2(256),
   EXPORT_DISPOSITION   VARCHAR2(16),
   FILE_PREFIX          VARCHAR2(32),
   FILE_DATE_FORMAT     VARCHAR2(16),
   FILE_SUFFIX          VARCHAR2(32),
   FILE_AUTOINCR_SUFFIX VARCHAR2(2),
   FILE_EXTENSION       VARCHAR2(8),
   PRINT_COLUMN_HEADERS NUMBER(1),
   EDC_ID               NUMBER(9),
   ESP_ID               NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_GROUP_EXPORT primary key (EXPORT_NAME)
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


/*==============================================================*/
/* Table: GROWTH_PATTERN                                        */
/*==============================================================*/


create table GROWTH_PATTERN  (
   PATTERN_ID           NUMBER                           not null,
   PATTERN_NAME         VARCHAR(32)                      not null,
   PATTERN_ALIAS        VARCHAR(32),
   PATTERN_DESC         VARCHAR(256),
   JAN_PCT              NUMBER(12,6),
   FEB_PCT              NUMBER(12,6),
   MAR_PCT              NUMBER(12,6),
   APR_PCT              NUMBER(12,6),
   MAY_PCT              NUMBER(12,6),
   JUN_PCT              NUMBER(12,6),
   JUL_PCT              NUMBER(12,6),
   AUG_PCT              NUMBER(12,6),
   SEP_PCT              NUMBER(12,6),
   OCT_PCT              NUMBER(12,6),
   NOV_PCT              NUMBER(12,6),
   DEC_PCT              NUMBER(12,6),
   ENTRY_DATE           DATE,
   constraint PK_GROWTH_PATTERN primary key (PATTERN_ID)
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


alter table GROWTH_PATTERN
   add constraint AK_GROWTH_PATTERN unique (PATTERN_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: HEAT_RATE_CURVE                                       */
/*==============================================================*/


create table HEAT_RATE_CURVE  (
   HEAT_RATE_CURVE_ID   NUMBER(9)                        not null,
   HEAT_RATE_CURVE_NAME VARCHAR2(32)                     not null,
   HEAT_RATE_CURVE_ALIAS VARCHAR2(32),
   HEAT_RATE_CURVE_DESC VARCHAR2(256),
   STATION_ID           NUMBER(9),
   PARAMETER_1_ID       NUMBER(9),
   PARAMETER_1_ROUND_TO_NEAREST NUMBER(6,3),
   PARAMETER_1_ROUNDING_STYLE VARCHAR2(16),
   PARAMETER_2_ID       NUMBER(9),
   PARAMETER_2_ROUND_TO_NEAREST NUMBER(6,3),
   PARAMETER_2_ROUNDING_STYLE VARCHAR2(16),
   PARAMETER_3_ID       NUMBER(9),
   PARAMETER_3_ROUND_TO_NEAREST NUMBER(6,3),
   PARAMETER_3_ROUNDING_STYLE VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_HEAT_RATE_CURVE primary key (HEAT_RATE_CURVE_ID)
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


comment on table HEAT_RATE_CURVE is
'A collection of heat rate curves represented by the specified weather parameters.  A Heat rate curve is associated with a Resource via the HEAT_RATE_CURVE_ID on the SUPPLY_RESOURCE table.'
/


comment on column HEAT_RATE_CURVE.HEAT_RATE_CURVE_ID is
'Unique ID generated by OID'
/


comment on column HEAT_RATE_CURVE.HEAT_RATE_CURVE_NAME is
'Unique name for Heat Rate Curve'
/


comment on column HEAT_RATE_CURVE.HEAT_RATE_CURVE_ALIAS is
'Optional Heat Rate Curve Alias'
/


comment on column HEAT_RATE_CURVE.HEAT_RATE_CURVE_DESC is
'Optional Heat Rate Curve Description'
/


comment on column HEAT_RATE_CURVE.STATION_ID is
'Weather Station from which this curve is looked up'
/


comment on column HEAT_RATE_CURVE.PARAMETER_1_ID is
'ID of first Weather Parameter'
/


comment on column HEAT_RATE_CURVE.PARAMETER_1_ROUND_TO_NEAREST is
'Number specifying the data interval for this parameter in the curve.'
/


comment on column HEAT_RATE_CURVE.PARAMETER_1_ROUNDING_STYLE is
'How to round to the nearest value - Up, Down, or Round.'
/


comment on column HEAT_RATE_CURVE.PARAMETER_2_ID is
'ID of second Weather Parameter'
/


comment on column HEAT_RATE_CURVE.PARAMETER_2_ROUND_TO_NEAREST is
'Number specifying the data interval for this parameter in the curve.'
/


comment on column HEAT_RATE_CURVE.PARAMETER_2_ROUNDING_STYLE is
'How to round to the nearest value - Up, Down, or Round.'
/


comment on column HEAT_RATE_CURVE.PARAMETER_3_ID is
'ID of third Weather Parameter'
/


comment on column HEAT_RATE_CURVE.PARAMETER_3_ROUND_TO_NEAREST is
'Number specifying the data interval for this parameter in the curve.'
/


comment on column HEAT_RATE_CURVE.PARAMETER_3_ROUNDING_STYLE is
'How to round to the nearest value - Up, Down, or Round.'
/


comment on column HEAT_RATE_CURVE.ENTRY_DATE is
'Date this record was last updated'
/


alter table HEAT_RATE_CURVE
   add constraint AK_HEAT_RATE_CURVE unique (HEAT_RATE_CURVE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: HEAT_RATE_CURVE_POINT                                 */
/*==============================================================*/


create table HEAT_RATE_CURVE_POINT  (
   HEAT_RATE_CURVE_ID   NUMBER(9)                        not null,
   PARAMETER_1_VAL      NUMBER(8,2)                      not null,
   PARAMETER_2_VAL      NUMBER(8,2)                      not null,
   PARAMETER_3_VAL      NUMBER(8,2)                      not null,
   OPERATING_MODE       VARCHAR2(16)                     not null,
   AMOUNT               NUMBER(9,3)                      not null,
   PRICE                NUMBER(9,3),
   ENTRY_DATE           DATE,
   constraint PK_HEAT_RATE_CURVE_POINT primary key (HEAT_RATE_CURVE_ID, PARAMETER_1_VAL, PARAMETER_2_VAL, PARAMETER_3_VAL, OPERATING_MODE, AMOUNT)
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


comment on table HEAT_RATE_CURVE_POINT is
'A point on a heat rate curve'
/


comment on column HEAT_RATE_CURVE_POINT.HEAT_RATE_CURVE_ID is
'ID of the associated Heat Rate Curve'
/


comment on column HEAT_RATE_CURVE_POINT.PARAMETER_1_VAL is
'Key value of the first parameter specified in the Heat Rate Curve'
/


comment on column HEAT_RATE_CURVE_POINT.PARAMETER_2_VAL is
'Key value of the second parameter specified in the Heat Rate Curve'
/


comment on column HEAT_RATE_CURVE_POINT.PARAMETER_3_VAL is
'Key value of the third parameter specified in the Heat Rate Curve'
/


comment on column HEAT_RATE_CURVE_POINT.OPERATING_MODE is
'The generator mode of operation for this point'
/


comment on column HEAT_RATE_CURVE_POINT.AMOUNT is
'The x-coordinate, or amount of Energy for this point.'
/


comment on column HEAT_RATE_CURVE_POINT.PRICE is
'The y-coordinate, or price at this point.'
/


comment on column HEAT_RATE_CURVE_POINT.ENTRY_DATE is
'Date this record was last updated'
/


/*==============================================================*/
/* Table: HOLIDAY                                               */
/*==============================================================*/


create table HOLIDAY  (
   HOLIDAY_ID           NUMBER(9)                        not null,
   HOLIDAY_NAME         VARCHAR2(32)                     not null,
   HOLIDAY_ALIAS        VARCHAR2(32),
   HOLIDAY_DESC         VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_HOLIDAY primary key (HOLIDAY_ID)
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


alter table HOLIDAY
   add constraint AK_HOLIDAY unique (HOLIDAY_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: HOLIDAY_OBSERVANCE                                    */
/*==============================================================*/


create table HOLIDAY_OBSERVANCE  (
   HOLIDAY_ID           NUMBER(9)                        not null,
   HOLIDAY_YEAR         NUMBER(4)                        not null,
   HOLIDAY_DATE         DATE,
   ENTRY_DATE           DATE,
   constraint PK_HOLIDAY_OBSERVANCE primary key (HOLIDAY_ID, HOLIDAY_YEAR)
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


alter table HOLIDAY_OBSERVANCE
   add constraint AK_HOLIDAY_OBSERVANCE unique (HOLIDAY_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: HOLIDAY_SCHEDULE                                      */
/*==============================================================*/


create table HOLIDAY_SCHEDULE  (
   HOLIDAY_SET_ID       NUMBER(9)                        not null,
   HOLIDAY_ID           NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_HOLIDAY_SCHEDULE primary key (HOLIDAY_SET_ID, HOLIDAY_ID)
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


/*==============================================================*/
/* Table: HOLIDAY_SET                                           */
/*==============================================================*/


create table HOLIDAY_SET  (
   HOLIDAY_SET_ID       NUMBER(9)                        not null,
   HOLIDAY_SET_NAME     VARCHAR2(32)                     not null,
   HOLIDAY_SET_ALIAS    VARCHAR2(32),
   HOLIDAY_SET_DESC     VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_HOLIDAY_SET primary key (HOLIDAY_SET_ID)
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


alter table HOLIDAY_SET
   add constraint AK_HOLIDAY_SET unique (HOLIDAY_SET_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: IMBALANCE_CHARGE                                      */
/*==============================================================*/


create table IMBALANCE_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   DEMAND               NUMBER(12,4),
   SUPPLY               NUMBER(12,4),
   NET_SYSTEM_IMBALANCE NUMBER(12,4),
   ENERGY_IMBALANCE_AMOUNT NUMBER(12,2),
   BILL_NET_SYSTEM_IMBALANCE NUMBER(12,4),
   BILL_ENERGY_IMBALANCE_AMOUNT NUMBER(12,2),
   constraint PK_IMBALANCE_CHARGE primary key (CHARGE_ID, CHARGE_DATE)
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


/*==============================================================*/
/* Table: IMBALANCE_CHARGE_BAND                                 */
/*==============================================================*/


create table IMBALANCE_CHARGE_BAND  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   BAND_NUMBER          NUMBER(1)                        not null,
   ENERGY_IMBALANCE_QUANTITY NUMBER(12,4),
   ENERGY_IMBALANCE_RATE NUMBER(16,6),
   ENERGY_IMBALANCE_AMOUNT NUMBER(12,2),
   BILL_ENERGY_IMBALANCE_QUANTITY NUMBER(12,4),
   BILL_ENERGY_IMBALANCE_AMOUNT NUMBER(12,2),
   constraint PK_IMBALANCE_CHARGE_BAND primary key (CHARGE_ID, CHARGE_DATE, BAND_NUMBER)
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


/*==============================================================*/
/* Table: INCUMBENT_ENTITY                                      */
/*==============================================================*/


create table INCUMBENT_ENTITY  (
   INCUMBENT_TYPE       VARCHAR2(16)                     not null,
   INCUMBENT_ID         NUMBER(9),
   constraint PK_INCUMBENT_ENTITY primary key (INCUMBENT_TYPE)
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


/*==============================================================*/
/* Table: INTERCHANGE_CONTRACT                                  */
/*==============================================================*/


create table INTERCHANGE_CONTRACT  (
   CONTRACT_ID          NUMBER(9)                        not null,
   CONTRACT_NAME        VARCHAR2(32)                     not null,
   CONTRACT_ALIAS       VARCHAR2(32),
   CONTRACT_DESC        VARCHAR2(256),
   CONTRACT_STATUS      VARCHAR2(32),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   IS_EVERGREEN         NUMBER(1),
   CONTRACT_TYPE        VARCHAR2(32),
   BILLING_ENTITY_ID    NUMBER(9),
   PURCHASER_ID         NUMBER(9),
   SELLER_ID            NUMBER(9),
   SOURCE_ID            NUMBER(9),
   SINK_ID              NUMBER(9),
   POR_ID               NUMBER(9),
   POD_ID               NUMBER(9),
   SC_ID                NUMBER(9),
   AGREEMENT_TYPE       VARCHAR2(32),
   APPROVAL_TYPE        VARCHAR2(32),
   MARKET_TYPE          VARCHAR2(32),
   LOSS_OPTION          VARCHAR2(32),
   CONTRACT_FILE_NAME   VARCHAR2(128),
   PIPELINE_ID          NUMBER(9),
   PIPELINE_TARIFF_TYPE VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_INTERCHANGE_CONTRACT primary key (CONTRACT_ID)
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


comment on table INTERCHANGE_CONTRACT is
'Wholesale contracts for Scheduling and Gas Delivery.  Fields repeated on Interchange Transaction are used as a template.'
/


comment on column INTERCHANGE_CONTRACT.CONTRACT_ID is
'Unique ID generated by OID'
/


comment on column INTERCHANGE_CONTRACT.CONTRACT_NAME is
'Required unique identifier'
/


comment on column INTERCHANGE_CONTRACT.CONTRACT_ALIAS is
'Optional Identifier'
/


comment on column INTERCHANGE_CONTRACT.CONTRACT_DESC is
'Optional description'
/


comment on column INTERCHANGE_CONTRACT.BEGIN_DATE is
'Beginning of the contract'
/


comment on column INTERCHANGE_CONTRACT.END_DATE is
'End of the contract'
/


comment on column INTERCHANGE_CONTRACT.IS_EVERGREEN is
'Is this contract evergreen?'
/


comment on column INTERCHANGE_CONTRACT.CONTRACT_TYPE is
'Type of the contract in order to change the display behavior'
/


comment on column INTERCHANGE_CONTRACT.BILLING_ENTITY_ID is
'ID of Entity to bill of a type defined by BILLING_ENTITY_TYPE'
/


comment on column INTERCHANGE_CONTRACT.PURCHASER_ID is
'ID of the PSE that is the Purchaser'
/


comment on column INTERCHANGE_CONTRACT.SOURCE_ID is
'ID of the origination of the contract'
/


comment on column INTERCHANGE_CONTRACT.SINK_ID is
'ID of the final destination of the contract'
/


comment on column INTERCHANGE_CONTRACT.POR_ID is
'Service Point ID for the Receipt Point'
/


comment on column INTERCHANGE_CONTRACT.POD_ID is
'Service Point ID for the delivery point'
/


comment on column INTERCHANGE_CONTRACT.SC_ID is
'ID for the Schedule Coordinator of the Contract'
/


comment on column INTERCHANGE_CONTRACT.AGREEMENT_TYPE is
'User-defined identifier'
/


comment on column INTERCHANGE_CONTRACT.APPROVAL_TYPE is
'User-defined identifier'
/


comment on column INTERCHANGE_CONTRACT.MARKET_TYPE is
'User-defined identifier'
/


comment on column INTERCHANGE_CONTRACT.LOSS_OPTION is
'User-defined identifier'
/


comment on column INTERCHANGE_CONTRACT.CONTRACT_FILE_NAME is
'Location of Contract file on local or network drive'
/


comment on column INTERCHANGE_CONTRACT.PIPELINE_ID is
'If this is a Pipeline Contract, then this refers to the corresponding Pipeline object.'
/


comment on column INTERCHANGE_CONTRACT.PIPELINE_TARIFF_TYPE is
'If this is a Pipeline Contract, then this refers to the type of tariff used for this contract (Zone to Zone, Zone Additive, Postage Stamp, or Mileage).'
/


alter table INTERCHANGE_CONTRACT
   add constraint AK_INTERCHANGE_CONTRACT unique (CONTRACT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: INTERCHANGE_TRANSACTION                               */
/*==============================================================*/


create table INTERCHANGE_TRANSACTION  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   TRANSACTION_NAME     VARCHAR2(64)                     not null,
   TRANSACTION_ALIAS    VARCHAR2(64),
   TRANSACTION_DESC     VARCHAR2(256),
   TRANSACTION_TYPE     VARCHAR2(32),
   TRANSACTION_CODE     CHAR(1),
   TRANSACTION_IDENTIFIER VARCHAR2(64),
   IS_FIRM              NUMBER(1),
   IS_IMPORT_SCHEDULE   NUMBER(1),
   IS_EXPORT_SCHEDULE   NUMBER(1),
   IS_BALANCE_TRANSACTION NUMBER(1),
   IS_BID_OFFER         NUMBER(1),
   IS_EXCLUDE_FROM_POSITION NUMBER(1),
   IS_IMPORT_EXPORT     NUMBER(1),
   IS_DISPATCHABLE      NUMBER(1),
   TRANSACTION_INTERVAL VARCHAR2(16),
   EXTERNAL_INTERVAL    VARCHAR2(16),
   ETAG_CODE            VARCHAR2(16),
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   PURCHASER_ID         NUMBER(9),
   SELLER_ID            NUMBER(9),
   CONTRACT_ID          NUMBER(9),
   SC_ID                NUMBER(9),
   POR_ID               NUMBER(9),
   POD_ID               NUMBER(9),
   COMMODITY_ID         NUMBER(9),
   SERVICE_TYPE_ID      NUMBER(9),
   TX_TRANSACTION_ID    NUMBER(9),
   PATH_ID              NUMBER(9),
   LINK_TRANSACTION_ID  NUMBER(9),
   EDC_ID               NUMBER(9),
   PSE_ID               NUMBER(9),
   ESP_ID               NUMBER(9),
   POOL_ID              NUMBER(9),
   SCHEDULE_GROUP_ID    NUMBER(9),
   MARKET_PRICE_ID      NUMBER(9),
   ZOR_ID               NUMBER(9),
   ZOD_ID               NUMBER(9),
   SOURCE_ID            NUMBER(9),
   SINK_ID              NUMBER(9),
   RESOURCE_ID          NUMBER(9),
   AGREEMENT_TYPE       VARCHAR2(32),
   APPROVAL_TYPE        VARCHAR2(32),
   LOSS_OPTION          VARCHAR2(32),
   TRAIT_CATEGORY       VARCHAR2(32),
   TP_ID                NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_INTERCHANGE_TRANSACTION primary key (TRANSACTION_ID)
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


comment on table INTERCHANGE_TRANSACTION is
'Holds all of the attributes for Interchange Transactions and Gas Deliveries'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_ID is
'Unique ID generated by OID'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_NAME is
'Unique name for Interchange Transaction'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_ALIAS is
'Optional Interchange Transaction Alias'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_DESC is
'Optional Interchange Transaction Description'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_TYPE is
'The type of Interchange Transaction'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_CODE is
'Single-Character Code that indicates the nature of the Transaction Type'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_IDENTIFIER is
'Optional Identifier to be used by Interfaces to External Systems'
/


comment on column INTERCHANGE_TRANSACTION.IS_FIRM is
'Is this a Transaction a Firm Transmission Reservation?'
/


comment on column INTERCHANGE_TRANSACTION.IS_IMPORT_SCHEDULE is
'Can this Transaction''s Schedule be imported?'
/


comment on column INTERCHANGE_TRANSACTION.IS_EXPORT_SCHEDULE is
'Can this Transaction''s Schedule be exported?'
/


comment on column INTERCHANGE_TRANSACTION.IS_BALANCE_TRANSACTION is
'Is this a Balance Transaction (a Demand Transaction that is specially balanced by Supply Transactions)'
/


comment on column INTERCHANGE_TRANSACTION.IS_BID_OFFER is
'Can this Transaction''s Schedule be bid or offered wholesale into an ISO?'
/


comment on column INTERCHANGE_TRANSACTION.IS_EXCLUDE_FROM_POSITION is
'Does this Transaction not participate in the Position Report?'
/


comment on column INTERCHANGE_TRANSACTION.IS_IMPORT_EXPORT is
'Is this Transaction and Import or Export ("inter"market vs. "intra"market)?'
/


comment on column INTERCHANGE_TRANSACTION.TRANSACTION_INTERVAL is
'The Interval of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.EXTERNAL_INTERVAL is
'Optional alternative interval for the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.ETAG_CODE is
'Code identifying this transaction in an eTag system'
/


comment on column INTERCHANGE_TRANSACTION.BEGIN_DATE is
'The Begin Date of the Transaction.'
/


comment on column INTERCHANGE_TRANSACTION.END_DATE is
'The End Date of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.PURCHASER_ID is
'The Purchaser of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.SELLER_ID is
'The Seller of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.CONTRACT_ID is
'The Interchange Contract to which this Transaction is assigned.'
/


comment on column INTERCHANGE_TRANSACTION.SC_ID is
'The Schedule Coordinator (Market/ISO) of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.POR_ID is
'The Point of Receipt of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.POD_ID is
'The Point of Delivery of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.COMMODITY_ID is
'The Commodity of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.SERVICE_TYPE_ID is
'The Transmission Service Type of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.TX_TRANSACTION_ID is
'An associated Transmission Transaction for this Energy Transaction'
/


comment on column INTERCHANGE_TRANSACTION.PATH_ID is
'A Path for the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.LINK_TRANSACTION_ID is
'An optional linked Transaction - typically a Loss Transaction corresponding to this Energy Transaction.'
/


comment on column INTERCHANGE_TRANSACTION.EDC_ID is
'The EDC of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.PSE_ID is
'The PSE of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.ESP_ID is
'The ESP of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.POOL_ID is
'The Pool of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.SCHEDULE_GROUP_ID is
'The Schedule Group to which this Transaction belongs'
/


comment on column INTERCHANGE_TRANSACTION.MARKET_PRICE_ID is
'A default Market Price that is associated with this Transaction''s Schedule'
/


comment on column INTERCHANGE_TRANSACTION.ZOR_ID is
'The Zone of Reciept fo the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.ZOD_ID is
'The Zone of Delivery of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.SOURCE_ID is
'The Source of the Transaction (a Service Point)'
/


comment on column INTERCHANGE_TRANSACTION.SINK_ID is
'The Sink of the Transaction (a Service Point)'
/


comment on column INTERCHANGE_TRANSACTION.RESOURCE_ID is
'A Supply Resource to whose output this Transaction''s Schedule corresponds'
/


comment on column INTERCHANGE_TRANSACTION.AGREEMENT_TYPE is
'User-defined identifier'
/


comment on column INTERCHANGE_TRANSACTION.APPROVAL_TYPE is
'User-defined identifier'
/


comment on column INTERCHANGE_TRANSACTION.LOSS_OPTION is
'User-defined identifier'
/


comment on column INTERCHANGE_TRANSACTION.TRAIT_CATEGORY is
'Defines Resource Traits applicable for this Transaction'
/


comment on column INTERCHANGE_TRANSACTION.TP_ID is
'The Transmission Provider of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION.ENTRY_DATE is
'The time stamp of this record’s entry'
/


alter table INTERCHANGE_TRANSACTION
   add constraint AK_INTERCHANGE_TRANSACTION unique (TRANSACTION_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table INTERCHANGE_TRANSACTION 
  add constraint AK_INTERCHANGE_TRANSACTION1 unique (TRANSACTION_ID, BEGIN_DATE, END_DATE)
    using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: INTERCHANGE_TRANSACTION_IX02                          */
/*==============================================================*/
create index INTERCHANGE_TRANSACTION_IX02 on INTERCHANGE_TRANSACTION (
   BEGIN_DATE ASC,
   CONTRACT_ID ASC,
   TRANSACTION_INTERVAL ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: INTERCHANGE_TRANSACTION_EXT                           */
/*==============================================================*/


create table INTERCHANGE_TRANSACTION_EXT  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   TRANSACTION_NAME     VARCHAR2(64)                     not null,
   TRANSACTION_ALIAS    VARCHAR2(64),
   TRANSACTION_DESC     VARCHAR2(256),
   TRANSACTION_TYPE     VARCHAR2(16),
   TRANSACTION_CODE     CHAR(1),
   TRANSACTION_IDENTIFIER VARCHAR2(64),
   IS_FIRM              NUMBER(1),
   IS_IMPORT_SCHEDULE   NUMBER(1),
   IS_EXPORT_SCHEDULE   NUMBER(1),
   IS_BALANCE_TRANSACTION NUMBER(1),
   IS_BID_OFFER         NUMBER(1),
   IS_EXCLUDE_FROM_POSITION NUMBER(1),
   IS_IMPORT_EXPORT     NUMBER(1),
   IS_DISPATCHABLE      NUMBER(1),
   TRANSACTION_INTERVAL VARCHAR2(16),
   EXTERNAL_INTERVAL    VARCHAR2(16),
   ETAG_CODE            VARCHAR2(16),
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   PURCHASER_ID         NUMBER(9),
   SELLER_ID            NUMBER(9),
   CONTRACT_ID          NUMBER(9),
   SC_ID                NUMBER(9),
   POR_ID               NUMBER(9),
   POD_ID               NUMBER(9),
   COMMODITY_ID         NUMBER(9),
   SERVICE_TYPE_ID      NUMBER(9),
   TX_TRANSACTION_ID    NUMBER(9),
   PATH_ID              NUMBER(9),
   LINK_TRANSACTION_ID  NUMBER(9),
   EDC_ID               NUMBER(9),
   PSE_ID               NUMBER(9),
   ESP_ID               NUMBER(9),
   POOL_ID              NUMBER(9),
   SCHEDULE_GROUP_ID    NUMBER(9),
   MARKET_PRICE_ID      NUMBER(9),
   ZOR_ID               NUMBER(9),
   ZOD_ID               NUMBER(9),
   SOURCE_ID            NUMBER(9),
   SINK_ID              NUMBER(9),
   RESOURCE_ID          NUMBER(9),
   AGREEMENT_TYPE       VARCHAR2(32),
   APPROVAL_TYPE        VARCHAR2(32),
   LOSS_OPTION          VARCHAR2(32),
   TRAIT_CATEGORY       VARCHAR2(16),
   TP_ID                NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_INTERCHANGE_TRANSACTION_EXT primary key (TRANSACTION_ID)
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


comment on table INTERCHANGE_TRANSACTION_EXT is
'Holds an external copy of all of the attributes for Interchange Transactions and Gas Deliveries'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_ID is
'Unique ID generated by OID'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_NAME is
'Unique name for Interchange Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_ALIAS is
'Optional Interchange Transaction Alias'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_DESC is
'Optional Interchange Transaction Description'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_TYPE is
'The type of Interchange Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_CODE is
'Single-Character Code that indicates the nature of the Transaction Type'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_IDENTIFIER is
'Optional Identifier to be used by Interfaces to External Systems'
/


comment on column INTERCHANGE_TRANSACTION_EXT.IS_FIRM is
'Is this a Transaction a Firm Transmission Reservation?'
/


comment on column INTERCHANGE_TRANSACTION_EXT.IS_IMPORT_SCHEDULE is
'Can this Transaction''s Schedule be imported?'
/


comment on column INTERCHANGE_TRANSACTION_EXT.IS_EXPORT_SCHEDULE is
'Can this Transaction''s Schedule be exported?'
/


comment on column INTERCHANGE_TRANSACTION_EXT.IS_BALANCE_TRANSACTION is
'Is this a Balance Transaction (a Demand Transaction that is specially balanced by Supply Transactions)'
/


comment on column INTERCHANGE_TRANSACTION_EXT.IS_BID_OFFER is
'Can this Transaction''s Schedule be bid or offered wholesale into an ISO?'
/


comment on column INTERCHANGE_TRANSACTION_EXT.IS_EXCLUDE_FROM_POSITION is
'Does this Transaction not participate in the Position Report?'
/


comment on column INTERCHANGE_TRANSACTION_EXT.IS_IMPORT_EXPORT is
'Is this Transaction and Import or Export ("inter"market vs. "intra"market)?'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRANSACTION_INTERVAL is
'The Interval of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.EXTERNAL_INTERVAL is
'Optional alternative interval for the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.ETAG_CODE is
'Code identifying this transaction in an eTag system'
/


comment on column INTERCHANGE_TRANSACTION_EXT.BEGIN_DATE is
'The Begin Date of the Transaction.'
/


comment on column INTERCHANGE_TRANSACTION_EXT.END_DATE is
'The End Date of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.PURCHASER_ID is
'The Purchaser of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.SELLER_ID is
'The Seller of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.CONTRACT_ID is
'The Interchange Contract to which this Transaction is assigned.'
/


comment on column INTERCHANGE_TRANSACTION_EXT.SC_ID is
'The Schedule Coordinator (Market/ISO) of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.POR_ID is
'The Point of Receipt of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.POD_ID is
'The Point of Delivery of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.COMMODITY_ID is
'The Commodity of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.SERVICE_TYPE_ID is
'The Transmission Service Type of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TX_TRANSACTION_ID is
'An associated Transmission Transaction for this Energy Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.PATH_ID is
'A Path for the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.LINK_TRANSACTION_ID is
'An optional linked Transaction - typically a Loss Transaction corresponding to this Energy Transaction.'
/


comment on column INTERCHANGE_TRANSACTION_EXT.EDC_ID is
'The EDC of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.PSE_ID is
'The PSE of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.ESP_ID is
'The ESP of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.POOL_ID is
'The Pool of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.SCHEDULE_GROUP_ID is
'The Schedule Group to which this Transaction belongs'
/


comment on column INTERCHANGE_TRANSACTION_EXT.MARKET_PRICE_ID is
'A default Market Price that is associated with this Transaction''s Schedule'
/


comment on column INTERCHANGE_TRANSACTION_EXT.ZOR_ID is
'The Zone of Reciept fo the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.ZOD_ID is
'The Zone of Delivery of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.SOURCE_ID is
'The Source of the Transaction (a Service Point)'
/


comment on column INTERCHANGE_TRANSACTION_EXT.SINK_ID is
'The Sink of the Transaction (a Service Point)'
/


comment on column INTERCHANGE_TRANSACTION_EXT.RESOURCE_ID is
'A Supply Resource to whose output this Transaction''s Schedule corresponds'
/


comment on column INTERCHANGE_TRANSACTION_EXT.AGREEMENT_TYPE is
'User-defined identifier'
/


comment on column INTERCHANGE_TRANSACTION_EXT.APPROVAL_TYPE is
'User-defined identifier'
/


comment on column INTERCHANGE_TRANSACTION_EXT.LOSS_OPTION is
'User-defined identifier'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TRAIT_CATEGORY is
'Defines Resource Traits applicable for this Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.TP_ID is
'The Transmission Provider of the Transaction'
/


comment on column INTERCHANGE_TRANSACTION_EXT.ENTRY_DATE is
'The time stamp of this record’s entry'
/


alter table INTERCHANGE_TRANSACTION_EXT
   add constraint AK_INTERCHANGE_TRANSACTION_EXT unique (TRANSACTION_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: INTERCHANGE_TRANSACTION_LIMIT                         */
/*==============================================================*/


create table INTERCHANGE_TRANSACTION_LIMIT  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   LIMIT_INTERVAL       VARCHAR2(16)                     not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   MIN_TRANSACTION_ID   NUMBER(9),
   LIMIT_TRANSACTION_ID NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_INTERCHANGE_TRANSACTION_LIM primary key (TRANSACTION_ID, LIMIT_INTERVAL, BEGIN_DATE)
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


/*==============================================================*/
/* Table: INTERCHANGE_TRANSACTION_STATUS                        */
/*==============================================================*/


create table INTERCHANGE_TRANSACTION_STATUS  (
   TRANSACTION_STATUS_NAME VARCHAR2(16)                     not null,
   TRANSACTION_IS_ACTIVE NUMBER(1),
   constraint PK_INTERCHANGE_TRANSACTION_STA primary key (TRANSACTION_STATUS_NAME)
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


/*==============================================================*/
/* Table: INVOICE_ATTACHMENT                                    */
/*==============================================================*/


create table INVOICE_ATTACHMENT  (
   INVOICE_ID           NUMBER(9)     NOT NULL,
   FILE_NAME            VARCHAR2(128) NOT NULL,
   FILE_MIME_TYPE       VARCHAR2(64)  NOT NULL,
   FILE_CONTENTS        BLOB          NOT NULL,
   USER_ID              NUMBER(9),
   ENTRY_DATE           DATE,
  constraint PK_INVOICE_ATTACHMENT primary key (INVOICE_ID, FILE_NAME)
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


/*==============================================================*/
/* Table: INVOICE                                               */
/*==============================================================*/


create table INVOICE  (
   ENTITY_ID            NUMBER(9)                        not null,
   STATEMENT_TYPE       NUMBER(9)                        not null,
   STATEMENT_STATE      NUMBER(1)                        not null,
   BEGIN_DATE           DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   END_DATE             DATE,
   INVOICE_DATE         DATE,
   INVOICE_NUMBER       VARCHAR2(16),
   INVOICE_SUB_LEDGER_NUMBER VARCHAR2(16),
   BILLING_CONTACT      VARCHAR2(100),
   BILLING_PHONE        VARCHAR2(24),
   BILLING_FAX          VARCHAR2(24),
   BILLING_STREET       VARCHAR2(256),
   BILLING_CITY         VARCHAR2(102),
   BILLING_STATE_CODE   CHAR(2),
   BILLING_POSTAL_CODE  VARCHAR2(16),
   BILLING_COUNTRY_CODE VARCHAR2(16),
   INVOICE_TERMS        VARCHAR2(512),
   INVOICE_PRIMARY_CONTACT VARCHAR2(120),
   INVOICE_PRIMARY_PHONE VARCHAR2(24),
   INVOICE_SECONDARY_CONTACT VARCHAR2(32),
   INVOICE_SECONDARY_PHONE VARCHAR2(24),
   PAY_CHECK_CONTACT    VARCHAR2(32),
   PAY_CHECK_STREET     VARCHAR2(64),
   PAY_CHECK_CITY       VARCHAR2(32),
   PAY_CHECK_STATE_CODE CHAR(2),
   PAY_CHECK_POSTAL_CODE VARCHAR2(12),
   PAY_CHECK_COUNTRY_CODE VARCHAR2(16),
   PAY_ELECTRONIC_DEBIT_NAME VARCHAR2(32),
   PAY_ELECTRONIC_DEBIT_NBR VARCHAR2(32),
   PAY_ELECTRONIC_CREDIT_NAME VARCHAR2(32),
   PAY_ELECTRONIC_CREDIT_NBR VARCHAR2(32),
   ENTITY_TYPE          VARCHAR2(16),
   INVOICE_STATUS       VARCHAR2(16),
   PAYMENT_DUE_DATE     DATE,
   APPROVED_BY_ID       NUMBER(9),
   APPROVED_WHEN        DATE,
   LAST_SENT_BY_ID		NUMBER(9),
   LAST_SENT_WHEN 		DATE,
   INVOICE_ID           NUMBER(12),
   constraint PK_INVOICE primary key (ENTITY_ID, STATEMENT_TYPE, STATEMENT_STATE, BEGIN_DATE, AS_OF_DATE)
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


comment on column INVOICE.APPROVED_BY_ID is
'User ID of the person who approved the invoice, or null if it has not been approved.'
/


comment on column INVOICE.APPROVED_WHEN is
'Date the invoice was approved, or null if it has not been approved.'
/


alter table INVOICE
   add constraint AK_INVOICE unique (INVOICE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_INVOICE_APPROVED_BY                                */
/*==============================================================*/
create index FK_INVOICE_APPROVED_BY on INVOICE (
   APPROVED_BY_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_INVOICE_STMT_TYPE                                  */
/*==============================================================*/
create index FK_INVOICE_STMT_TYPE on INVOICE (
   STATEMENT_TYPE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: INVOICE_GROUP                                         */
/*==============================================================*/


create table INVOICE_GROUP  (
   INVOICE_GROUP_ID     NUMBER(9)                        not null,
   INVOICE_GROUP_NAME   VARCHAR2(32)                     not null,
   INVOICE_GROUP_ALIAS  VARCHAR2(32),
   INVOICE_GROUP_DESC   VARCHAR2(256),
   DISPLAY_ORDER        NUMBER(3),
   SHOW_TITLE_ON_INVOICE NUMBER(1),
   SHOW_SUBTOTAL_ON_INVOICE NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_INVOICE_GROUP primary key (INVOICE_GROUP_ID)
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


comment on table INVOICE_GROUP is
'Holds attributes for Invoice Groups which are means of grouping charges for presentation on the invoice.'
/


comment on column INVOICE_GROUP.INVOICE_GROUP_ID is
'Unique ID generated by OID'
/


comment on column INVOICE_GROUP.INVOICE_GROUP_NAME is
'Unique Invoice Group Name'
/


comment on column INVOICE_GROUP.INVOICE_GROUP_ALIAS is
'Optional Invoice Group Alias'
/


comment on column INVOICE_GROUP.INVOICE_GROUP_DESC is
'Optional Invoice Group Description'
/


comment on column INVOICE_GROUP.SHOW_TITLE_ON_INVOICE is
'Will the presentation of this Invoice Group on the Invoice be prefaced by the Invoice Group Title?'
/


comment on column INVOICE_GROUP.SHOW_SUBTOTAL_ON_INVOICE is
'Will the presentation of this Invoice Group on the Invoice immediately by followed by a Subtotal for the Invoice Group’s charges?'
/


comment on column INVOICE_GROUP.ENTRY_DATE is
'The time stamp of this record’s entry.'
/


alter table INVOICE_GROUP
   add constraint AK_INVOICE_GROUP unique (INVOICE_GROUP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: INVOICE_LINE_ITEM                                     */
/*==============================================================*/


create table INVOICE_LINE_ITEM  (
   INVOICE_ID           NUMBER(12)                       not null,
   LINE_ITEM_NAME       VARCHAR2(128)                    not null,
   STATEMENT_TYPE       NUMBER(9),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   PRODUCT_ID           NUMBER(9),
   COMPONENT_ID         NUMBER(9),
   ACCOUNT_SERVICE_ID   NUMBER(9),
   OTHER_ID             NUMBER(9),
   OTHER_DATA           VARCHAR2(128),
   LINE_ITEM_CATEGORY   VARCHAR2(32),
   LINE_ITEM_QUANTITY   NUMBER(12,2),
   LINE_ITEM_RATE       NUMBER(14,6),
   LINE_ITEM_AMOUNT     NUMBER(12,2),
   LINE_ITEM_BILL_AMOUNT NUMBER(12,2),
   DEFAULT_DISPLAY      VARCHAR2(6),
   LINE_ITEM_OPTION     VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_INVOICE_LINE_ITEM primary key (INVOICE_ID, LINE_ITEM_NAME)
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


comment on column INVOICE_LINE_ITEM.INVOICE_ID is
'Unique ID of the Invoice to which this line item belongs'
/


comment on column INVOICE_LINE_ITEM.LINE_ITEM_NAME is
'The Line Item Text'
/


comment on column INVOICE_LINE_ITEM.STATEMENT_TYPE is
'What Statement Type does this line represent? Typically the same as INVOICE.STATEMENT_TYPE'
/


comment on column INVOICE_LINE_ITEM.BEGIN_DATE is
'The begin date of the bill period this line represents. Typically the same as INVOICE.BEGIN_DATE'
/


comment on column INVOICE_LINE_ITEM.END_DATE is
'The end date of the bill period this line represents. Typically the same as INVOICE.END_DATE'
/


comment on column INVOICE_LINE_ITEM.PRODUCT_ID is
'If this Line Item corresponds to a product, this is the product''s unique ID'
/


comment on column INVOICE_LINE_ITEM.COMPONENT_ID is
'If this Line Item corresponds to a component, this is the component''s unique ID'
/


comment on column INVOICE_LINE_ITEM.ACCOUNT_SERVICE_ID is
'If this Line Item corresponds to an account service, this is the account service''s unique ID'
/


comment on column INVOICE_LINE_ITEM.LINE_ITEM_CATEGORY is
'Optional Invoice Category (comes from PRODUCT.PRODUCT_CATEGORY or COMPONENT.COMPONENT_CATEGORY)'
/


comment on column INVOICE_LINE_ITEM.LINE_ITEM_QUANTITY is
'Billed Quantity'
/


comment on column INVOICE_LINE_ITEM.LINE_ITEM_RATE is
'Billing Rate in $/Quantity Unit'
/


comment on column INVOICE_LINE_ITEM.LINE_ITEM_AMOUNT is
'Total Charge for this Line Item (typically will be Quantity times Rate)'
/


comment on column INVOICE_LINE_ITEM.LINE_ITEM_BILL_AMOUNT is
'Billed Amount for this Line Item. This should represent a delta for this line item between this invoice and the same invoice for the previous Statement Type.'
/


comment on column INVOICE_LINE_ITEM.DEFAULT_DISPLAY is
'What amount is displayed by default for this line - the Charge Amount or the Bill Amount?'
/


comment on column INVOICE_LINE_ITEM.ENTRY_DATE is
'A timestamp of the last time this record was updated'
/


/*==============================================================*/
/* Table: INVOICE_USER_LINE_ITEM                                */
/*==============================================================*/


create table INVOICE_USER_LINE_ITEM  (
   ENTITY_ID            NUMBER(9)                        not null,
   STATEMENT_TYPE       NUMBER(9)                        not null,
   STATEMENT_STATE      NUMBER(1)                        not null,
   BEGIN_DATE           DATE                             not null,
   LINE_ITEM_NAME       VARCHAR2(128)                    not null,
   LINE_ITEM_CATEGORY   VARCHAR2(32),
   LINE_ITEM_TYPE       CHAR(1),
   LINE_ITEM_QUANTITY   NUMBER(12,2),
   LINE_ITEM_RATE       NUMBER(12,4),
   LINE_ITEM_AMOUNT     NUMBER(12,2),
   LINE_ITEM_BILL_AMOUNT NUMBER(12,2),
   DEFAULT_DISPLAY      VARCHAR2(6),
   INVOICE_GROUP_ID     NUMBER(9),
   INVOICE_GROUP_ORDER  NUMBER(3),
   EXCLUDE_FROM_INVOICE_TOTAL NUMBER(1),
   IS_TAXED             NUMBER(1),
   TAX_COMPONENT_ID     NUMBER(9),
   TAX_GEOGRAPHY_ID     NUMBER(9),
   LINE_ITEM_POSTED_DATE DATE,
   ENTRY_DATE           DATE,
   constraint PK_INVOICE_USER_LINE_ITEM primary key (ENTITY_ID, STATEMENT_TYPE, STATEMENT_STATE, BEGIN_DATE, LINE_ITEM_NAME)
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


comment on table INVOICE_USER_LINE_ITEM is
'A manually added invoice line item'
/


comment on column INVOICE_USER_LINE_ITEM.ENTITY_ID is
'ID of the Counter-Party (will be a PSE ID, Pool ID, or Bill Party ID)'
/


comment on column INVOICE_USER_LINE_ITEM.STATEMENT_TYPE is
'A number 1, 2, or 3 – Forecast, Preliminary, or Forecast respectively'
/


comment on column INVOICE_USER_LINE_ITEM.STATEMENT_STATE is
'A number 1 or 2 – Internal or External respectively'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_NAME is
'How the line item appears on the Invoice'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_CATEGORY is
'Optional Invoice Category (comes from PRODUCT.PRODUCT_CATEGORY or COMPONENT.COMPONENT_CATEGORY)'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_TYPE is
'One character code to determine the type (Adjustment, Payment, Balance, Miscellaneous, etc…)'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_QUANTITY is
'A quantity that is being billed'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_RATE is
'A rate – typically in $ / quantity unit'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_AMOUNT is
'The total dollar charge for this line item (typically the quantity times the rate)'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_BILL_AMOUNT is
'The dollar amount to bill to the customer in cases where the customer has already paid an invoice for the previous Statement Type'
/


comment on column INVOICE_USER_LINE_ITEM.DEFAULT_DISPLAY is
'What amount is displayed by default for this line - the Charge Amount or the Bill Amount?'
/


comment on column INVOICE_USER_LINE_ITEM.INVOICE_GROUP_ID is
'Optional ID of the Invoice Group in which this line item appears'
/


comment on column INVOICE_USER_LINE_ITEM.INVOICE_GROUP_ORDER is
'Optional information that determines where the line item appears within the Invoice Group'
/


comment on column INVOICE_USER_LINE_ITEM.EXCLUDE_FROM_INVOICE_TOTAL is
'Will this line item amount be excluded from the Invoice Total? (Is it an informational only line item?)'
/


comment on column INVOICE_USER_LINE_ITEM.IS_TAXED is
'Is this line item automatically taxed?'
/


comment on column INVOICE_USER_LINE_ITEM.TAX_COMPONENT_ID is
'If the line item is taxed, then this is the ID of the Charge Component that defines the Tax Rates'
/


comment on column INVOICE_USER_LINE_ITEM.TAX_GEOGRAPHY_ID is
'The Geography (Tax Jurisdiction) to use when looking up tax rates to apply.'
/


comment on column INVOICE_USER_LINE_ITEM.LINE_ITEM_POSTED_DATE is
'When was this line item was added to the Invoice?'
/


comment on column INVOICE_USER_LINE_ITEM.ENTRY_DATE is
'When was the last time this database record was updated?'
/


/*==============================================================*/
/* Index: FK_INVOICE_USR_LN_STMT_TYPE                           */
/*==============================================================*/
create index FK_INVOICE_USR_LN_STMT_TYPE on INVOICE_USER_LINE_ITEM (
   STATEMENT_TYPE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: IT_ASSIGNMENT                                         */
/*==============================================================*/


create table IT_ASSIGNMENT  (
   ASSIGNMENT_ID        NUMBER(9)                        not null,
   TO_TRANSACTION_ID    NUMBER(9)                        not null,
   FROM_TRANSACTION_ID  NUMBER(9)                        not null,
   ASSIGNMENT_TYPE      VARCHAR2(32)                     not null,
   ENTRY_DATE           DATE,
   constraint PK_IT_ASSIGNMENT primary key (ASSIGNMENT_ID)
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


/*==============================================================*/
/* Index: IT_ASSIGNMENT_UIX01                                   */
/*==============================================================*/
create unique index IT_ASSIGNMENT_UIX01 on IT_ASSIGNMENT (
   TO_TRANSACTION_ID ASC,
   ASSIGNMENT_TYPE ASC,
   FROM_TRANSACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: IT_ASSIGNMENT_UIX02                                   */
/*==============================================================*/
create unique index IT_ASSIGNMENT_UIX02 on IT_ASSIGNMENT (
   FROM_TRANSACTION_ID ASC,
   ASSIGNMENT_TYPE ASC,
   TO_TRANSACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: IT_ASSIGNMENT_OPTION                                  */
/*==============================================================*/


create table IT_ASSIGNMENT_OPTION  (
   OPTION_ID            NUMBER(9)                        not null,
   TO_TRANSACTION_ID    NUMBER(9),
   FROM_TRANSACTION_ID  NUMBER(9),
   ASSIGNMENT_TYPE      VARCHAR2(32)                     not null,
   OTHER_TRANSACTION_ID NUMBER(9),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   STATUS               VARCHAR2(32),
   NOTES                VARCHAR2(512),
   LAST_EVALUATED       DATE,
   constraint PK_IT_ASSIGNMENT_OPTION primary key (OPTION_ID)
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


alter table IT_ASSIGNMENT_OPTION
   add constraint CK_IT_ASSIGN_OPTION_01 check ((OPTION_ID=0 OR (TO_TRANSACTION_ID IS NOT NULL AND FROM_TRANSACTION_ID IS NOT NULL AND OTHER_TRANSACTION_ID IS NOT NULL)))
/


/*==============================================================*/
/* Index: IT_ASSIGNMENT_OPTION_UIX01                            */
/*==============================================================*/
create unique index IT_ASSIGNMENT_OPTION_UIX01 on IT_ASSIGNMENT_OPTION (
   TO_TRANSACTION_ID ASC,
   ASSIGNMENT_TYPE ASC,
   FROM_TRANSACTION_ID ASC,
   OTHER_TRANSACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: IT_ASSIGNMENT_OPTION_UIX02                            */
/*==============================================================*/
create unique index IT_ASSIGNMENT_OPTION_UIX02 on IT_ASSIGNMENT_OPTION (
   FROM_TRANSACTION_ID ASC,
   ASSIGNMENT_TYPE ASC,
   TO_TRANSACTION_ID ASC,
   OTHER_TRANSACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: FK_IT_ASSGN_OPTION_OTHER                              */
/*==============================================================*/
create index FK_IT_ASSGN_OPTION_OTHER on IT_ASSIGNMENT_OPTION (
   OTHER_TRANSACTION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: IT_ASSIGNMENT_PERIOD                                  */
/*==============================================================*/


create table IT_ASSIGNMENT_PERIOD  (
   ASSIGNMENT_ID        NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   constraint PK_IT_ASSIGNMENT_PERIOD primary key (ASSIGNMENT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: IT_ASSIGNMENT_SCHEDULE                                */
/*==============================================================*/


create table IT_ASSIGNMENT_SCHEDULE  (
   ASSIGNMENT_ID        NUMBER(9)                        not null,
   OPTION_ID            NUMBER(9)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   STATEMENT_TYPE_ID    NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   AMOUNT               NUMBER(10,3),
   PRICE                NUMBER(10,3),
   ENTRY_DATE           DATE,
   constraint PK_IT_ASSIGNMENT_SCHEDULE primary key (ASSIGNMENT_ID, OPTION_ID, SCHEDULE_DATE, STATEMENT_TYPE_ID, SCHEDULE_STATE)
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

/*==============================================================*/
/* INDEX: FK_IT_ASSIGNMENT_OPTION                               */
/*==============================================================*/
CREATE INDEX FK_IT_ASSIGNMENT_OPTION ON IT_ASSIGNMENT_SCHEDULE (
   OPTION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: IT_ASSIGNMENT_WORK                                    */
/*==============================================================*/


create global temporary table IT_ASSIGNMENT_WORK  (
   WORK_ID              NUMBER(9)                        not null,
   TRANSACTION_ID       NUMBER(9)                        not null,
   TRANSACTION_NAME     VARCHAR2(64),
   SCHEDULE_DATE        DATE                             not null,
   AMOUNT               NUMBER,
   PRICE                NUMBER,
   OTHER_PRICE          NUMBER,
   ASSIGNED             NUMBER,
   IS_FIXED             NUMBER(1),
   TOTAL_ASSIGNED       NUMBER,
   TERM_MAX             NUMBER,
   TERM_MIN             NUMBER,
   constraint PK_IT_ASSIGNMENT_WORK primary key (WORK_ID, TRANSACTION_ID, SCHEDULE_DATE)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: IT_COMMODITY                                          */
/*==============================================================*/


create table IT_COMMODITY  (
   COMMODITY_ID         NUMBER(9)                        not null,
   COMMODITY_NAME       VARCHAR2(32)                     not null,
   COMMODITY_ALIAS      VARCHAR2(32),
   COMMODITY_DESC       VARCHAR2(256),
   COMMODITY_TYPE       VARCHAR2(16),
   COMMODITY_UNIT       VARCHAR2(16),
   COMMODITY_UNIT_FORMAT VARCHAR2(16),
   COMMODITY_PRICE_UNIT VARCHAR2(16),
   COMMODITY_PRICE_FORMAT VARCHAR2(16),
   IS_VIRTUAL           NUMBER(1),
   MARKET_TYPE          VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_IT_COMMODITY primary key (COMMODITY_ID)
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


comment on table IT_COMMODITY is
'Holds all of the data for Interchange Transaction Commodities'
/


comment on column IT_COMMODITY.COMMODITY_ID is
'Unique ID generated by OID'
/


comment on column IT_COMMODITY.COMMODITY_NAME is
'Unique name for Commodity'
/


comment on column IT_COMMODITY.COMMODITY_ALIAS is
'Optional Commodity Alias'
/


comment on column IT_COMMODITY.COMMODITY_DESC is
'Optional Commodity Description'
/


comment on column IT_COMMODITY.COMMODITY_TYPE is
'The physical commodity type for this Commodity'
/


comment on column IT_COMMODITY.COMMODITY_UNIT is
'The unit of measure for this Commodity'
/


comment on column IT_COMMODITY.COMMODITY_UNIT_FORMAT is
'The display format for quantities of this Commodity'
/


comment on column IT_COMMODITY.COMMODITY_PRICE_UNIT is
'The unit of measure for the price of this Commodity'
/


comment on column IT_COMMODITY.COMMODITY_PRICE_FORMAT is
'The display format for prices of this Commodity'
/


comment on column IT_COMMODITY.IS_VIRTUAL is
'Do quantities represent virtual quantities? (for supporting ISO virtual bids and offers)'
/


comment on column IT_COMMODITY.MARKET_TYPE is
'Settlement Market (day-ahead, real-time)'
/


comment on column IT_COMMODITY.ENTRY_DATE is
'The time stamp of this record’s entry'
/


alter table IT_COMMODITY
   add constraint AK_IT_COMMODITY unique (COMMODITY_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: IT_SCHEDULE                                           */
/*==============================================================*/


create table IT_SCHEDULE  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   SCHEDULE_TYPE        NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   AMOUNT               NUMBER(10,3),
   PRICE                NUMBER(10,3),
   LOCK_STATE           CHAR(1),
   constraint PK_IT_SCHEDULE primary key (TRANSACTION_ID, SCHEDULE_TYPE, SCHEDULE_STATE, SCHEDULE_DATE, AS_OF_DATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: IT_SCHEDULE_ERRS_TMP                                  */
/*==============================================================*/


create global temporary table IT_SCHEDULE_ERRS_TMP  (
   ORA_ERR_NUMBER$      NUMBER,
   ORA_ERR_MESG$        VARCHAR2(2000),
   ORA_ERR_ROWID$       ROWID,
   ORA_ERR_OPTYP$       VARCHAR2(2),
   ORA_ERR_TAG$         VARCHAR2(2000),
   TRANSACTION_ID       VARCHAR2(4000),
   SCHEDULE_TYPE        VARCHAR2(4000),
   SCHEDULE_STATE       VARCHAR2(4000),
   SCHEDULE_DATE        VARCHAR2(4000),
   AS_OF_DATE           VARCHAR2(4000),
   AMOUNT               VARCHAR2(4000),
   PRICE                VARCHAR2(4000),
   LOCK_STATE           VARCHAR2(4000)
)
/


/*==============================================================*/
/* Index: IT_SCHEDULE_ERRS_TMP_IX01                             */
/*==============================================================*/
create index IT_SCHEDULE_ERRS_TMP_IX01 on IT_SCHEDULE_ERRS_TMP (
   ORA_ERR_TAG$ ASC
)
/


/*==============================================================*/
/* Table: IT_SCHEDULE_LOCK_SUMMARY                              */
/*==============================================================*/


create table IT_SCHEDULE_LOCK_SUMMARY  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   SCHEDULE_TYPE        NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOCK_STATE           CHAR(1) DEFAULT 'U'              not null,
   constraint PK_IT_SCHEDULE_LOCK_SUMMARY primary key (TRANSACTION_ID, SCHEDULE_TYPE, SCHEDULE_STATE, BEGIN_DATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/

/*==============================================================*/
/* Table: IT_SCHEDULE_MANAGEMENT_MAP                            */
/*==============================================================*/
create table IT_SCHEDULE_MANAGEMENT_MAP  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   STATEMENT_TYPE_ID    NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   SCHED_MGMT_CID       VARCHAR2(20)                     not null,
   SCHED_MGMT_DATA_SOURCE CHAR(1)                        not null,
   constraint PK_IT_SCHEDULE_MANAGEMENT_MAP primary key (TRANSACTION_ID, STATEMENT_TYPE_ID,SCHEDULE_STATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


alter table IT_SCHEDULE_MANAGEMENT_MAP
   add constraint CK01_IT_SCHED_MGMT_MAP check (SCHEDULE_STATE IN (1,2))
/

alter table IT_SCHEDULE_MANAGEMENT_MAP
   add constraint CK02_IT_SCHED_MGMT_MAP check (SCHED_MGMT_DATA_SOURCE IN ('P','I','A','D','R','O'))
/

alter table IT_SCHEDULE_MANAGEMENT_MAP
   add constraint AK_IT_SCHEDULE_MANAGEMENT_MAP unique (SCHED_MGMT_CID, SCHED_MGMT_DATA_SOURCE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_IT_SCHED_MGMT_MAP_STATEMENT                        */
/*==============================================================*/
CREATE INDEX FK_IT_SCHED_MGMT_MAP_STATEMENT ON IT_SCHEDULE_MANAGEMENT_MAP (
   STATEMENT_TYPE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: IT_SCHEDULE_MANAGEMENT_STAGING                        */
/*==============================================================*/


create global temporary table IT_SCHEDULE_MANAGEMENT_STAGING  (
   SCHED_MGMT_CID       VARCHAR2(20)                     not null,
   SCHED_MGMT_DATA_SOURCE CHAR(1)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   AMOUNT               NUMBER,
   INTERVAL             VARCHAR2(16),
   constraint PK_IT_SCHED_MGMT_STAGING primary key (SCHED_MGMT_CID, SCHED_MGMT_DATA_SOURCE, SCHEDULE_DATE)
)
on commit preserve rows
/

/*==============================================================*/
/* Table: IT_SEGMENT                                            */
/*==============================================================*/


create table IT_SEGMENT  (
   IT_SEGMENT_ID        NUMBER(9)                        not null,
   TRANSACTION_ID       NUMBER(9)                        not null,
   POR_ID               NUMBER(9),
   POD_ID               NUMBER(9),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   SEGMENT_ORDER        NUMBER(3),
   CONTRACT_ID          NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_IT_SEGMENT primary key (IT_SEGMENT_ID)
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


alter table IT_SEGMENT
   add constraint AK_IT_SEGMENT unique (TRANSACTION_ID, POR_ID, BEGIN_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: IT_SEGMENT_SCHEDULE                                   */
/*==============================================================*/


create table IT_SEGMENT_SCHEDULE  (
   IT_SEGMENT_ID        NUMBER(9)                        not null,
   STATEMENT_TYPE_ID    NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   RECEIVED_AMOUNT      NUMBER(16,3),
   FUEL_AMOUNT          NUMBER(16,3),
   DELIVERED_AMOUNT     NUMBER(16,3),
   constraint PK_IT_SEGMENT_SCHEDULE primary key (IT_SEGMENT_ID, STATEMENT_TYPE_ID, SCHEDULE_STATE, SCHEDULE_DATE, AS_OF_DATE)
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


/*==============================================================*/
/* Table: IT_STATUS                                             */
/*==============================================================*/


create table IT_STATUS  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   AS_OF_DATE           DATE                             not null,
   TRANSACTION_STATUS_NAME VARCHAR2(16),
   TRANSACTION_IS_ACTIVE NUMBER(1),
   constraint PK_IT_STATUS primary key (TRANSACTION_ID, AS_OF_DATE)
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

/*==============================================================*/
/* Index: FK_IT_STATUS_INTER_STATUS                             */
/*==============================================================*/
create index FK_IT_STATUS_INTER_STATUS on IT_STATUS (
   TRANSACTION_STATUS_NAME ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: IT_TRAIT_SCHEDULE                                     */
/*==============================================================*/


create table IT_TRAIT_SCHEDULE  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   TRAIT_GROUP_ID       NUMBER(9)                        not null,
   TRAIT_INDEX          NUMBER(3)                        not null,
   SET_NUMBER           NUMBER(3)                        not null,
   STATEMENT_TYPE_ID    NUMBER(9)                        not null,
   SCHEDULE_END_DATE    DATE,
   TRAIT_VAL            VARCHAR2(128),
   ENTRY_DATE           DATE,
   LOCK_STATE           CHAR(1),
   constraint PK_IT_TRAIT_SCHEDULE primary key (TRANSACTION_ID, SCHEDULE_STATE, SCHEDULE_DATE, TRAIT_GROUP_ID, TRAIT_INDEX, SET_NUMBER, STATEMENT_TYPE_ID)
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


comment on table IT_TRAIT_SCHEDULE is
'Data relating to an INTERCHANGE_TRANSACTION for a particular TRANSACTION_TRAIT.'
/


comment on column IT_TRAIT_SCHEDULE.TRANSACTION_ID is
'Foreign key to the INTERCHANGE_TRANSACTION table.'
/


comment on column IT_TRAIT_SCHEDULE.SCHEDULE_STATE is
'State of the data -- either 1 (Internal) or 2 (External)'
/


comment on column IT_TRAIT_SCHEDULE.SCHEDULE_DATE is
'CUT date of the data record.'
/


comment on column IT_TRAIT_SCHEDULE.TRAIT_GROUP_ID is
'Foreign key to the TRANSACTION_TRAIT table'
/


comment on column IT_TRAIT_SCHEDULE.TRAIT_INDEX is
'Foreign key to the TRANSACTION_TRAIT table'
/


comment on column IT_TRAIT_SCHEDULE.SET_NUMBER is
'If the TRAIT_GROUP''s IS_SERIES is set to 1, then this SET_NUMBER can be anything from 1 to 999, denoting a numbered point in a curve of data.'
/


comment on column IT_TRAIT_SCHEDULE.STATEMENT_TYPE_ID is
'If the Trait Group''s IS_STATEMENT_TYPE_SPECIFIC = 0 then this will always be 0.  Otherwise, it is the foreign key to the STATEMENT_TYPE table.  '
/


comment on column IT_TRAIT_SCHEDULE.SCHEDULE_END_DATE is
'If the Trait Group''s IS_SPARSE = 1, then this is the End Date of the record, which SCHEDULE_DATE is the Begin Date.  If IS_SPARSE = 0, then this field should be null.'
/


comment on column IT_TRAIT_SCHEDULE.TRAIT_VAL is
'The value of the Trait.'
/


comment on column IT_TRAIT_SCHEDULE.ENTRY_DATE is
'The last date this row was updated.'
/


/*==============================================================*/
/* Index: IT_TRAIT_SCHEDULE_UIX01                               */
/*==============================================================*/
create unique index IT_TRAIT_SCHEDULE_UIX01 on IT_TRAIT_SCHEDULE (
   TRANSACTION_ID ASC,
   SCHEDULE_STATE ASC,
   TRAIT_GROUP_ID ASC,
   TRAIT_INDEX ASC,
   SCHEDULE_DATE ASC,
   SET_NUMBER ASC,
   STATEMENT_TYPE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: IT_TRAIT_SCHEDULE_ERRS_TMP                            */
/*==============================================================*/


create global temporary table IT_TRAIT_SCHEDULE_ERRS_TMP  (
   ORA_ERR_NUMBER$      NUMBER,
   ORA_ERR_MESG$        VARCHAR2(2000),
   ORA_ERR_ROWID$       ROWID,
   ORA_ERR_OPTYP$       VARCHAR2(2),
   ORA_ERR_TAG$         VARCHAR2(2000),
   TRANSACTION_ID       VARCHAR2(4000),
   SCHEDULE_STATE       VARCHAR2(4000),
   SCHEDULE_DATE        VARCHAR2(4000),
   TRAIT_GROUP_ID       VARCHAR2(4000),
   TRAIT_INDEX          VARCHAR2(4000),
   SET_NUMBER           VARCHAR2(4000),
   STATEMENT_TYPE_ID    VARCHAR2(4000),
   SCHEDULE_END_DATE    VARCHAR2(4000),
   TRAIT_VAL            VARCHAR2(4000),
   ENTRY_DATE           VARCHAR2(4000),
   LOCK_STATE           VARCHAR2(4000)
)
/


/*==============================================================*/
/* Index: IT_TRAIT_SCHEDULE_ERR_TMP_IX01                        */
/*==============================================================*/
create index IT_TRAIT_SCHEDULE_ERR_TMP_IX01 on IT_TRAIT_SCHEDULE_ERRS_TMP (
   ORA_ERR_TAG$ ASC
)
/


/*==============================================================*/
/* Table: IT_TRAIT_SCHEDULE_LOCK_SUMMARY                        */
/*==============================================================*/


create table IT_TRAIT_SCHEDULE_LOCK_SUMMARY  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   TRAIT_GROUP_ID       NUMBER(9)                        not null,
   STATEMENT_TYPE_ID    NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOCK_STATE           CHAR(1) DEFAULT 'U'              not null,
   constraint PK_IT_TRAIT_SCHED_LOCK_SUMMARY primary key (TRANSACTION_ID, SCHEDULE_STATE, TRAIT_GROUP_ID, STATEMENT_TYPE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: IT_TRAIT_SCHEDULE_STATUS                              */
/*==============================================================*/


create table IT_TRAIT_SCHEDULE_STATUS  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   CREATE_DATE          DATE,
   REVIEW_STATUS        VARCHAR(16),
   REVIEW_DATE          DATE,
   REVIEWED_BY_ID       NUMBER(9),
   SUBMIT_STATUS        VARCHAR(16),
   SUBMIT_DATE          DATE,
   SUBMITTED_BY_ID      NUMBER(9),
   MARKET_STATUS        VARCHAR(16),
   MARKET_STATUS_DATE   DATE,
   REASON_FOR_CHANGE    VARCHAR(16),
   OTHER_REASON         VARCHAR(1000),
   PROCESS_MESSAGE      VARCHAR(4000),
   ENTRY_DATE           DATE,
   constraint PK_IT_TRAIT_SCHEDULE_STATUS primary key (TRANSACTION_ID, SCHEDULE_DATE)
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


comment on table IT_TRAIT_SCHEDULE_STATUS is
'The status of a date in the IT_TRAIT_SCHEDULE table for a particular Transaction'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.TRANSACTION_ID is
'Foreign Key to the INTERCHANGE_TRANSACTION table'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.SCHEDULE_DATE is
'The CUT date that this status applies to'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.CREATE_DATE is
'The date this row was created'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.REVIEW_DATE is
'The date this record was reviewed'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.REVIEWED_BY_ID is
'The User ID name of the person who Reviewed the record'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.SUBMIT_DATE is
'The date the record was submitted'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.SUBMITTED_BY_ID is
'The User ID name of the person who last Submitted the record'
/


comment on column IT_TRAIT_SCHEDULE_STATUS.MARKET_STATUS_DATE is
'The date this Market Status last changed'
/

/*==============================================================*/
/* Index: FK_IT_TRAIT_SCHED_ST_REVIEW                           */
/*==============================================================*/
create index FK_IT_TRAIT_SCHED_ST_REVIEW on IT_TRAIT_SCHEDULE_STATUS (
   REVIEWED_BY_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_IT_TRAIT_SCHED_ST_SUBMIT                           */
/*==============================================================*/
create index FK_IT_TRAIT_SCHED_ST_SUBMIT on IT_TRAIT_SCHEDULE_STATUS (
   SUBMITTED_BY_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Table: JOB_DATA                                              */
/*==============================================================*/

create table JOB_DATA (
   JOB_NAME  					VARCHAR2(64) NOT NULL,
   USER_ID        				NUMBER(9),
   JOB_THREAD_ID    			NUMBER(9),
   ACTION_CHAIN_NAME 			VARCHAR2(256),
   ACTION_DISPLAY_NAME 			VARCHAR2(256),
   NOTIFICATION_EMAIL_ADDRESS 	VARCHAR2(256),
   constraint PK_JOB_DATA primary key (JOB_NAME)
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

/*==============================================================*/
/* Table: JOB_THREAD                                            */
/*==============================================================*/

create table JOB_THREAD (
   JOB_THREAD_ID           NUMBER(9)    NOT NULL,
   JOB_THREAD_NAME         VARCHAR2(64) NOT NULL,
   JOB_THREAD_ALIAS        VARCHAR2(32),
   JOB_THREAD_DESC         VARCHAR2(256),
   JOB_CLASS               VARCHAR2(64),
   IS_SNOOZED              NUMBER(1),
   ENTRY_DATE              DATE,
   constraint PK_JOB_THREAD primary key (JOB_THREAD_ID)
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

/*==============================================================*/
/* Table: JOB_QUEUE_ITEM                                            */
/*==============================================================*/

create table JOB_QUEUE_ITEM
(
  JOB_QUEUE_ITEM_ID          NUMBER(9) not null,
  JOB_THREAD_ID              NUMBER(9),
  ITEM_ORDER                 NUMBER(9) not null,
  COMMENTS                   VARCHAR2(256),
  USER_ID                    NUMBER(9),
  PLSQL                      VARCHAR2(4000) not null,
  NOTIFICATION_EMAIL_ADDRESS VARCHAR2(128),
  ENTRY_DATE                 DATE,
   constraint PK_JOB_QUEUE_ITEM primary key (JOB_QUEUE_ITEM_ID)
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

/*==============================================================*/
/* Index: FK_JOB_QUEUE_ITEM_THREAD                              */
/*==============================================================*/
create index FK_JOB_QUEUE_ITEM_THREAD on JOB_QUEUE_ITEM (
   JOB_THREAD_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_JOB_QUEUE_ITEM_USER                                */
/*==============================================================*/
create index FK_JOB_QUEUE_ITEM_USER on JOB_QUEUE_ITEM (
   USER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: LAYOUT_HIERARCHY_WORK                                 */
/*==============================================================*/


create global temporary table LAYOUT_HIERARCHY_WORK  (
   OBJECT_ID            NUMBER(9)                        not null,
   SYSTEM_VIEW_OBJECT_ID NUMBER(9),
   PATH                 VARCHAR2(4000),
   DISPLAY_PATH         VARCHAR2(4000),
   IS_AGGREGATE         NUMBER(1),
   constraint PK_LAYOUT_HIERARCHY_WORK primary key (OBJECT_ID)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: LMP_CHARGE                                            */
/*==============================================================*/


create table LMP_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   SOURCE_ID            NUMBER(9)                        not null,
   DELIVERY_POINT_ID    NUMBER(9)                        not null,
   SINK_ID              NUMBER(9)                        not null,
   DA_PURCHASES         NUMBER(18,9),
   RT_PURCHASES         NUMBER(18,9),
   DA_SALES             NUMBER(18,9),
   RT_SALES             NUMBER(18,9),
   DA_LOAD              NUMBER(18,9),
   RT_LOAD              NUMBER(18,9),
   DA_GENERATION        NUMBER(18,9),
   RT_GENERATION        NUMBER(18,9),
   PRICE1               NUMBER(16,6),
   PRICE2               NUMBER(16,6),
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_LMP_CHARGE primary key (CHARGE_ID, CHARGE_DATE, SOURCE_ID, DELIVERY_POINT_ID, SINK_ID)
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


/*==============================================================*/
/* Table: LOAD_FORECAST_SCENARIO                                */
/*==============================================================*/


create table LOAD_FORECAST_SCENARIO  (
   SCENARIO_ID          NUMBER(9)                        not null,
   WEATHER_CASE_ID      NUMBER(9),
   AREA_LOAD_CASE_ID    NUMBER(9),
   ENROLLMENT_CASE_ID   NUMBER(9),
   CALENDAR_CASE_ID     NUMBER(9),
   USAGE_FACTOR_CASE_ID NUMBER(9),
   LOSS_FACTOR_CASE_ID  NUMBER(9),
   GROWTH_FACTOR_CASE_ID NUMBER(9),
   RUN_MODE             NUMBER(1),
   SCENARIO_USE_DAY_TYPE NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_FORECAST_SCENARIO primary key (SCENARIO_ID)
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

/*==============================================================*/
/* Index: FK_LOAD_FCAST_SCEN_AREA                               */
/*==============================================================*/
create index FK_LOAD_FCAST_SCEN_AREA on LOAD_FORECAST_SCENARIO (
   AREA_LOAD_CASE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_LOAD_FCAST_SCEN_ENRLLMNT                           */
/*==============================================================*/
create index FK_LOAD_FCAST_SCEN_ENRLLMNT on LOAD_FORECAST_SCENARIO (
   ENROLLMENT_CASE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_LOAD_FCAST_SCEN_GROWTH                             */
/*==============================================================*/
create index FK_LOAD_FCAST_SCEN_GROWTH on LOAD_FORECAST_SCENARIO (
   GROWTH_FACTOR_CASE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_LOAD_FCAST_SCEN_LF                                 */
/*==============================================================*/
create index FK_LOAD_FCAST_SCEN_LF on LOAD_FORECAST_SCENARIO (
   LOSS_FACTOR_CASE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_LOAD_FCAST_SCEN_USAGE                              */
/*==============================================================*/
create index FK_LOAD_FCAST_SCEN_USAGE on LOAD_FORECAST_SCENARIO (
   USAGE_FACTOR_CASE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_LOAD_FCAST_SCEN_WTHR                               */
/*==============================================================*/
create index FK_LOAD_FCAST_SCEN_WTHR on LOAD_FORECAST_SCENARIO (
   WEATHER_CASE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: LOAD_FORECAST_SCENARIO_STATUS                      */
/*==============================================================*/


create table LOAD_FORECAST_SCENARIO_STATUS  (
   SCENARIO_ID          NUMBER(9)                        not null,
   STATUS_NAME          VARCHAR2(16)                   not null,
   constraint PK_LOAD_FORECAST_SCEN_STATUS primary key (SCENARIO_ID, STATUS_NAME)
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

/*==============================================================*/
/* Index: FK_LOAD_FCAST_STATUS                                  */
/*==============================================================*/
create index FK_LOAD_FCAST_STATUS on LOAD_FORECAST_SCENARIO_STATUS (
   STATUS_NAME ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: LOAD_OBLIGATION                                       */
/*==============================================================*/


create table LOAD_OBLIGATION  (
   OBLIGATION_ID        NUMBER(9)                        not null,
   SC_ID                NUMBER(9),
   PSE_ID               NUMBER(9),
   ESP_ID               NUMBER(9),
   EDC_ID               NUMBER(9),
   POOL_ID              NUMBER(9),
   SERVICE_POINT_ID     NUMBER(9),
   SERVICE_ZONE_ID      NUMBER(9),
   SCHEDULE_GROUP_ID    NUMBER(9),
   OBLIGATION_LOAD_CODE CHAR(1),
   OBLIGATION_INTERVAL  VARCHAR2(16),
   OBLIGATION_NAME      VARCHAR2(64),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_OBLIGATION primary key (OBLIGATION_ID)
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


/*==============================================================*/
/* Table: LOAD_OBLIGATION_SCHEDULE                              */
/*==============================================================*/


create table LOAD_OBLIGATION_SCHEDULE  (
   OBLIGATION_ID        NUMBER(9)                        not null,
   OBLIGATION_DATE      DATE                             not null,
   OBLIGATION_TYPE      CHAR(1)                          not null,
   OBLIGATION_LOAD_VAL  NUMBER(16,6),
   constraint PK_LOAD_OBLIGATION_SCHEDULE primary key (OBLIGATION_ID, OBLIGATION_DATE, OBLIGATION_TYPE)
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


/*==============================================================*/
/* Table: LOAD_PROFILE                                          */
/*==============================================================*/


create table LOAD_PROFILE  (
   PROFILE_LIBRARY_ID   NUMBER(9)                        not null,
   PROFILE_ID           NUMBER(9)                        not null,
   PROFILE_NAME         VARCHAR2(130)                    not null,
   PROFILE_ALIAS        VARCHAR2(130),
   PROFILE_DESC         VARCHAR2(256),
   PROFILE_TYPE         VARCHAR2(16),
   PROFILE_OPERATION    VARCHAR2(16),
   PROFILE_ORIGIN       VARCHAR2(16),
   PROFILE_RATE_CLASS   VARCHAR2(16),
   PROFILE_DAY_TYPE     VARCHAR2(16),
   PROFILE_ACCOUNT_REF  VARCHAR2(16),
   PROFILE_METER_REF    VARCHAR2(16),
   PROFILE_SIC_CODE     VARCHAR2(16),
   PROFILE_SEASON       VARCHAR2(64),
   PROFILE_SYSTEM_LOAD  VARCHAR2(16),
   PROFILE_ADJUSTMENT_OPTION VARCHAR2(16),
   PROFILE_STATION_ID   NUMBER(9),
   PROFILE_TEMPLATE_ID  NUMBER(9),
   PROFILE_SOURCE_BEGIN_DATE DATE,
   PROFILE_SOURCE_END_DATE DATE,
   PROFILE_SOURCE_ID    NUMBER(9),
   PROFILE_INTERVAL     NUMBER(4),
   PROFILE_SOURCE_VERSION DATE,
   PROFILE_BREAKPOINT_INTERVAL VARCHAR(4),
   IS_EXTERNAL_PROFILE  NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_PROFILE primary key (PROFILE_ID)
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


alter table LOAD_PROFILE
   add constraint AK_LOAD_PROFILE unique (PROFILE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: LOAD_PROFILE_IX01                                     */
/*==============================================================*/
create unique index LOAD_PROFILE_IX01 on LOAD_PROFILE (
   PROFILE_LIBRARY_ID ASC,
   PROFILE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: LOAD_PROFILE_IX02                                     */
/*==============================================================*/
create index LOAD_PROFILE_IX02 on LOAD_PROFILE (
   PROFILE_ACCOUNT_REF ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: LOAD_PROFILE_LIBRARY                                  */
/*==============================================================*/


create table LOAD_PROFILE_LIBRARY  (
   PROFILE_LIBRARY_ID   NUMBER(9)                        not null,
   PROFILE_LIBRARY_NAME VARCHAR2(128)                    not null,
   PROFILE_LIBRARY_ALIAS VARCHAR2(128),
   PROFILE_LIBRARY_DESC VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_PROFILE_LIBRARY primary key (PROFILE_LIBRARY_ID)
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


alter table LOAD_PROFILE_LIBRARY
   add constraint AK_LOAD_PROFILE_LIBRARY unique (PROFILE_LIBRARY_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: LOAD_PROFILE_POINT                                    */
/*==============================================================*/


create table LOAD_PROFILE_POINT  (
   PROFILE_ID           NUMBER(9)                        not null,
   POINT_INDEX          NUMBER(9)                        not null,
   POINT_DATE           DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   POINT_VAL            NUMBER,
   constraint PK_LOAD_PROFILE_POINT primary key (PROFILE_ID, POINT_INDEX, POINT_DATE, AS_OF_DATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: LOAD_PROFILE_SET                                      */
/*==============================================================*/


create table LOAD_PROFILE_SET  (
   PROFILE_SET_ID       NUMBER(9)                        not null,
   PROFILE_SET_NAME     VARCHAR(32)                      not null,
   PROFILE_SET_ALIAS    VARCHAR(32),
   PROFILE_SET_DESC     VARCHAR(256),
   PROFILE_ID           NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_PROFILE_SET primary key (PROFILE_SET_ID)
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


alter table LOAD_PROFILE_SET
   add constraint AK_LOAD_PROFILE_SET unique (PROFILE_SET_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: LOAD_PROFILE_SET_MEMBER                               */
/*==============================================================*/


create table LOAD_PROFILE_SET_MEMBER  (
   PROFILE_SET_ID       NUMBER(9)                        not null,
   PROFILE_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   WEIGHT_FACTOR        NUMBER(9,4),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_PROFILE_SET_MEMBER primary key (PROFILE_SET_ID, PROFILE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: LOAD_PROFILE_STATISTICS                               */
/*==============================================================*/


create table LOAD_PROFILE_STATISTICS  (
   PROFILE_ID           NUMBER(9)                        not null,
   AS_OF_DATE           DATE                             not null,
   FROM_DATE            DATE,
   TO_DATE              DATE,
   PROFILE_COUNT        NUMBER(10),
   PROFILE_LOAD_FACTOR  NUMBER(16,4),
   PROFILE_MIN          NUMBER(16,4),
   PROFILE_NZ_MIN       NUMBER(16,4),
   PROFILE_MAX          NUMBER(16,4),
   PROFILE_SUM          NUMBER(16,4),
   PROFILE_MEAN_APE     NUMBER(16,4),
   PROFILE_AVG_DEV_APE  NUMBER(16,4),
   PROFILE_TOTAL_ERROR_PCT NUMBER(16,4),
   R_SQUARED_MIN        NUMBER(14,6),
   R_SQUARED_MAX        NUMBER(14,6),
   R_SQUARED_THRESHOLD  NUMBER(14,6),
   R_SQUARED_FAIL_PCT   NUMBER(10,2),
   T_STAT_TEMP_FAIL_PCT NUMBER(10,2),
   T_STAT_HUMID_FAIL_PCT NUMBER(10,2),
   T_STAT_WIND_FAIL_PCT NUMBER(10,2),
   PROFILE_STATUS       VARCHAR2(16),
   VERSION_ID           NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_PROFILE_STATISTICS primary key (PROFILE_ID, AS_OF_DATE)
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


comment on column LOAD_PROFILE_STATISTICS.PROFILE_TOTAL_ERROR_PCT is
'Total Error % = abs(Total Error / Total Load) * 100'
/


/*==============================================================*/
/* Table: LOAD_PROFILE_WRF                                      */
/*==============================================================*/


create table LOAD_PROFILE_WRF  (
   PROFILE_ID           NUMBER(9)                        not null,
   WRF_LINE_NBR         NUMBER(1)                        not null,
   AS_OF_DATE           DATE                             not null,
   SEGMENT_MIN          NUMBER(8,2),
   SEGMENT_MAX          NUMBER(8,2),
   WRF_ID               NUMBER(9),
   constraint PK_LOAD_PROFILE_WRF primary key (PROFILE_ID, WRF_LINE_NBR, AS_OF_DATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: LOAD_PROFILE_WRF_LINE                                 */
/*==============================================================*/


create table LOAD_PROFILE_WRF_LINE  (
   WRF_ID               NUMBER(9)                        not null,
   WRF_HOUR             NUMBER(3)                        not null,
   COEFF_0              NUMBER(16,8),
   COEFF_1              NUMBER(16,8),
   COEFF_2              NUMBER(16,8),
   COEFF_3              NUMBER(16,8),
   COEFF_4              NUMBER(16,8),
   COEFF_5              NUMBER(16,8),
   TSTAT_0              NUMBER(16,8),
   TSTAT_1              NUMBER(16,8),
   TSTAT_2              NUMBER(16,8),
   TSTAT_3              NUMBER(16,8),
   TSTAT_4              NUMBER(16,8),
   TSTAT_5              NUMBER(16,8),
   NUM_VARS             NUMBER(1),
   R_SQUARED            NUMBER(16,8),
   TSTAT_CRITICAL       NUMBER(16,8),
   SEGMENT_MIN          NUMBER(8,2),
   SEGMENT_MAX          NUMBER(8,2),
   constraint PK_LOAD_PROFILE_WRF_LINE primary key (WRF_ID, WRF_HOUR)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: LOAD_PROFILE_WRF_T_STAT                               */
/*==============================================================*/


create table LOAD_PROFILE_WRF_T_STAT  (
   PROFILE_ID           NUMBER(9)                        not null,
   AS_OF_DATE           DATE                             not null,
   VARIABLE_NBR         NUMBER(9)                        not null,
   T_STAT_FAIL_PCT      NUMBER(10,2),
   ENTRY_DATE           DATE,
   constraint PK_LOAD_PROFILE_WRF_T_STAT primary key (PROFILE_ID, AS_OF_DATE, VARIABLE_NBR)
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


/*==============================================================*/
/* Table: LOAD_PROFILE_WRF_WEATHER                              */
/*==============================================================*/


create table LOAD_PROFILE_WRF_WEATHER  (
   PROFILE_ID           NUMBER(9)                        not null,
   VARIABLE_NBR         NUMBER(2)                        not null,
   PARAMETER_ID         NUMBER(9),
   constraint PK_LOAD_PROFILE_WRF_WEATHER primary key (PROFILE_ID, VARIABLE_NBR)
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

/*==============================================================*/
/* Table: LOAD_RESULT                                           */
/*==============================================================*/


create table LOAD_RESULT  (
   LOAD_RESULT_ID         NUMBER(9)                        not null,
   LOAD_RESULT_TYPE       VARCHAR2(16)                     not null,
   ENTRY_DATE             DATE,
   constraint PK_LOAD_RESULT primary key (LOAD_RESULT_ID)
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

alter table LOAD_RESULT
   add constraint CK01_LOAD_RESULT check (LOAD_RESULT_TYPE IN ('Calendar', 'Loss Factor', 'Entity'))
/


/*==============================================================*/
/* Table: LOAD_RESULT_CALENDAR                                  */
/*==============================================================*/


create table LOAD_RESULT_CALENDAR  (
   CALENDAR_ID          NUMBER(9)                        not null,
   SERVICE_CODE         CHAR(1)                          not null,
   SCENARIO_ID          NUMBER(9)                        not null,
   WEATHER_STATION_ID   NUMBER(9)                        not null,
   SOURCE_TIME_ZONE     VARCHAR2(16)                     not null,
   RESULT_INTERVAL      VARCHAR2(16)                     not null,
   LOAD_RESULT_ID       NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_LOAD_SHAPE_RESULT_CALENDAR primary key (CALENDAR_ID, SERVICE_CODE, SCENARIO_ID, WEATHER_STATION_ID, SOURCE_TIME_ZONE, RESULT_INTERVAL)
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

alter table LOAD_RESULT_CALENDAR
   add constraint AK_LOAD_RESULT_CALENDAR unique (LOAD_RESULT_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_LOAD_RESULT_CALENDAR_SCEN                          */
/*==============================================================*/
CREATE INDEX FK_LOAD_RESULT_CALENDAR_SCEN ON LOAD_RESULT_CALENDAR (
   SCENARIO_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_LOAD_RESULT_CALENDAR_WS                            */
/*==============================================================*/
CREATE INDEX FK_LOAD_RESULT_CALENDAR_WS ON LOAD_RESULT_CALENDAR (
   WEATHER_STATION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: LOAD_RESULT_DATA                                      */
/*==============================================================*/


create table LOAD_RESULT_DATA  (
   LOAD_RESULT_ID           NUMBER(9)                        not null,
   RESULT_DATE              DATE                             not null,
   RESULT_VAL               NUMBER(16,6),
   constraint PK_LOAD_RESULT_DATA primary key (LOAD_RESULT_ID, RESULT_DATE)
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

/*==============================================================*/
/* Table: LOAD_RESULT_ENTITY                                    */
/*==============================================================*/


create table LOAD_RESULT_ENTITY  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   SERVICE_CODE         CHAR(1)                          not null,
   SCENARIO_ID          NUMBER(9)                        not null,
   SOURCE_TIME_ZONE     VARCHAR2(16)                     not null,
   DATA_TYPE            VARCHAR2(16)                     not null,
   RESULT_INTERVAL      VARCHAR2(16)                     not null,
   LOAD_RESULT_ID       NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_LOAD_RESULT_ENTITY primary key (ENTITY_DOMAIN_ID, ENTITY_ID, SERVICE_CODE, SCENARIO_ID, SOURCE_TIME_ZONE, DATA_TYPE, RESULT_INTERVAL)
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

alter table LOAD_RESULT_ENTITY
   add constraint AK_LOAD_RESULT_ENTITY unique (LOAD_RESULT_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_LOAD_RESULT_ENTITY_SCEN                            */
/*==============================================================*/
CREATE INDEX FK_LOAD_RESULT_ENTITY_SCEN ON LOAD_RESULT_ENTITY (
   SCENARIO_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: LOAD_RESULT_LOSS_FACTOR                               */
/*==============================================================*/


create table LOAD_RESULT_LOSS_FACTOR  (
   LOSS_FACTOR_PATTERN_ID       NUMBER(9)                        not null,
   SERVICE_CODE        		CHAR(1)                          not null,
   SCENARIO_ID          	NUMBER(9)                        not null,
   SOURCE_TIME_ZONE     	VARCHAR2(16)                     not null,
   RESULT_INTERVAL      	VARCHAR2(16)                     not null,
   LOAD_RESULT_ID       	NUMBER(9)                        not null,
   ENTRY_DATE           	DATE,
   constraint PK_LOAD_RESULT_LOSS_FACTOR primary key (LOSS_FACTOR_PATTERN_ID, SERVICE_CODE, SCENARIO_ID, SOURCE_TIME_ZONE, RESULT_INTERVAL)
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

alter table LOAD_RESULT_LOSS_FACTOR
   add constraint AK_LOAD_RESULT_LOSS_FACTOR unique (LOAD_RESULT_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_LOAD_RESULT_LF_SCEN                                */
/*==============================================================*/
CREATE INDEX FK_LOAD_RESULT_LF_SCEN ON LOAD_RESULT_LOSS_FACTOR (
   SCENARIO_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: LOAD_SEG_ACCOUNTS_TMP                                 */
/*==============================================================*/


CREATE GLOBAL TEMPORARY TABLE LOAD_SEG_ACCOUNTS_TMP( 
   PROCESS_ID                     NUMBER(12) NOT NULL,
   REPORT_ID                      NUMBER(9) NOT NULL,
   ACCOUNT_ID                     NUMBER(9) NOT NULL,
   ACCOUNT_MODEL_OPTION           VARCHAR2(16) NOT NULL, 
   ACCOUNT_IDENT                  VARCHAR2(64) NOT NULL, 
   IS_SUB_AGGREGATE               NUMBER(1) NOT NULL, 
   BEGIN_DATE                     DATE, 
   END_DATE                       DATE, 
   ATTR_NAME_01                   VARCHAR2(512),  
   ATTR_VAL_01                    VARCHAR2(512),  
   ATTR_NAME_02                   VARCHAR2(512),  
   ATTR_VAL_02                    VARCHAR2(512),  
   ATTR_NAME_03                   VARCHAR2(512),  
   ATTR_VAL_03                    VARCHAR2(512),  
   ATTR_NAME_04                   VARCHAR2(512),  
   ATTR_VAL_04                    VARCHAR2(512),  
   ATTR_NAME_05                   VARCHAR2(512),  
   ATTR_VAL_05                    VARCHAR2(512),  
   ATTR_NAME_06                   VARCHAR2(512),  
   ATTR_VAL_06                    VARCHAR2(512),  
   ATTR_NAME_07                   VARCHAR2(512),  
   ATTR_VAL_07                    VARCHAR2(512),  
   ATTR_NAME_08                   VARCHAR2(512),  
   ATTR_VAL_08                    VARCHAR2(512),  
   ATTR_NAME_09                   VARCHAR2(512),  
   ATTR_VAL_09                    VARCHAR2(512),  
   ATTR_NAME_10                   VARCHAR2(512),  
   ATTR_VAL_10                    VARCHAR2(512)  
   )
ON COMMIT PRESERVE ROWS   
/

   
/*==============================================================*/
/* Table: LOAD_SEG_AGG_ACCOUNTS_TMP                             */
/*==============================================================*/


CREATE GLOBAL TEMPORARY TABLE LOAD_SEG_AGG_ACCOUNTS_TMP( 
   PROCESS_ID            NUMBER(12) NOT NULL,
   REPORT_ID             NUMBER(9) NOT NULL,
   AGG_ACCOUNT_ID        NUMBER(9) NOT NULL,
   ACCOUNT_ID            NUMBER(9) NOT NULL,
   AGGREGATE_ID          NUMBER(9) NOT NULL,
   AVG_USAGE_FACTOR      NUMBER(14,6),    
   SUB_AGG_USAGE_FACTOR  NUMBER(14,6),    
   MODEL_ID              NUMBER(1),    
   SERVICE_ID            NUMBER(9),
   SERVICE_DATE          DATE,    
   SERVICE_ACCOUNTS      NUMBER(8) 
   )
ON COMMIT PRESERVE ROWS   
/


/*==============================================================*/
/* Table: LOAD_SEGMENTATION_DEF                                 */
/*==============================================================*/


create table LOAD_SEGMENTATION_DEF
(REPORT_ID NUMBER(9) not null,
 REPORT_NAME VARCHAR2(128) not null,
 CREATE_USER_NAME VARCHAR2(64) not null,
 CREATE_DATE DATE not null,
 MODIFY_USER_NAME VARCHAR2(64) not null,
 MODIFY_DATE DATE not null,
 PROCESS_ID  NUMBER(12),
 constraint PK_LOAD_SEGMENTATION_DEF primary key (REPORT_ID)
 using index
       tablespace NERO_INDEX
       storage
       (
           initial 64k
           next 64k
           pctincrease 0
       )
)
storage
(
    initial 128k
    next 128k
    pctincrease 0
)
tablespace NERO_DATA
/

alter table LOAD_SEGMENTATION_DEF
 add constraint AK_LOAD_SEGMENTATION_DEF unique (REPORT_NAME)
 using index
       tablespace NERO_INDEX
       storage
       (
           initial 64k
           next 64k
           pctincrease 0
       )
/


/*==============================================================*/
/* Table: LOAD_SEGMENTATION_DEF_DETAILS                         */
/*==============================================================*/


create table LOAD_SEGMENTATION_DEF_DETAILS
(REPORT_ID			NUMBER(9) not null,
 ATTRIBUTE_ID		NUMBER(9) not null,
 SEGMENT_BY			NUMBER(1) default 0 not null,
 constraint	PK_LOAD_SEG_DEF_DTLS primary key (REPORT_ID, ATTRIBUTE_ID)
 using index
 	   tablespace NERO_INDEX
	   storage
	   (
	   		initial 64k
			next 64k
			pctincrease 0
	   )
)
storage
(
    initial 128k
    next 128k
    pctincrease 0
)
tablespace NERO_DATA
/

alter table LOAD_SEGMENTATION_DEF_DETAILS
 add constraint CK01_LOAD_SEG_DEF_DTLS check (SEGMENT_BY IN (0 ,1))
/


/*==============================================================*/
/* Table: LOAD_SEG_DEF_DTLS_ATTR_VALUES                         */
/*==============================================================*/


create table LOAD_SEG_DEF_DTLS_ATTR_VALUES
(REPORT_ID			NUMBER(9) not null,
 ATTRIBUTE_ID		NUMBER(9) not null,
 ATTRIBUTE_VALUE	VARCHAR2(128) not null,
 constraint PK_LOAD_SEG_DEF_DTLS_ATTR_VALS primary key(REPORT_ID, ATTRIBUTE_ID, ATTRIBUTE_VALUE)
 using index
 	   tablespace NERO_INDEX
	   storage
	   (
	   		initial 64k
			next 64k
			pctincrease 0
	   )
)
storage
(
	initial 128k
	next 128k
	pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: LOAD_SEGMENTATION_REPORT                              */
/*==============================================================*/


create table LOAD_SEGMENTATION_REPORT( 
   PROCESS_ID                   NUMBER(12) not null,
   REPORT_ID                    NUMBER(9)  not null,   
   REPORT_FILE_NAME             VARCHAR2(250) not null,
   EFFECTIVE_DATE               DATE not null,
   ACCOUNT_IDENT                VARCHAR2(64),
   ATTR_VAL_01                  VARCHAR2(512),
   ATTR_VAL_02                  VARCHAR2(512),
   ATTR_VAL_03                  VARCHAR2(512),
   ATTR_VAL_04                  VARCHAR2(512),
   ATTR_VAL_05                  VARCHAR2(512),
   ATTR_VAL_06                  VARCHAR2(512),
   ATTR_VAL_07                  VARCHAR2(512),
   ATTR_VAL_08                  VARCHAR2(512),
   ATTR_VAL_09                  VARCHAR2(512),
   ATTR_VAL_10                  VARCHAR2(512),
   VAL_001                      NUMBER(18,6),
   VAL_002                      NUMBER(18,6),
   VAL_003                      NUMBER(18,6),
   VAL_004                      NUMBER(18,6),
   VAL_005                      NUMBER(18,6),
   VAL_006                      NUMBER(18,6),
   VAL_007                      NUMBER(18,6),
   VAL_008                      NUMBER(18,6),
   VAL_009                      NUMBER(18,6),
   VAL_010                      NUMBER(18,6),
   VAL_011                      NUMBER(18,6),
   VAL_012                      NUMBER(18,6),
   VAL_013                      NUMBER(18,6),
   VAL_014                      NUMBER(18,6),
   VAL_015                      NUMBER(18,6),
   VAL_016                      NUMBER(18,6),
   VAL_017                      NUMBER(18,6),
   VAL_018                      NUMBER(18,6),
   VAL_019                      NUMBER(18,6),
   VAL_020                      NUMBER(18,6),
   VAL_021                      NUMBER(18,6),
   VAL_022                      NUMBER(18,6),
   VAL_023                      NUMBER(18,6),
   VAL_024                      NUMBER(18,6),
   VAL_025                      NUMBER(18,6),
   VAL_026                      NUMBER(18,6),
   VAL_027                      NUMBER(18,6),
   VAL_028                      NUMBER(18,6),
   VAL_029                      NUMBER(18,6),
   VAL_030                      NUMBER(18,6),
   VAL_031                      NUMBER(18,6),
   VAL_032                      NUMBER(18,6),
   VAL_033                      NUMBER(18,6),
   VAL_034                      NUMBER(18,6),
   VAL_035                      NUMBER(18,6),
   VAL_036                      NUMBER(18,6),
   VAL_037                      NUMBER(18,6),
   VAL_038                      NUMBER(18,6),
   VAL_039                      NUMBER(18,6),
   VAL_040                      NUMBER(18,6),
   VAL_041                      NUMBER(18,6),
   VAL_042                      NUMBER(18,6),
   VAL_043                      NUMBER(18,6),
   VAL_044                      NUMBER(18,6),
   VAL_045                      NUMBER(18,6),
   VAL_046                      NUMBER(18,6),
   VAL_047                      NUMBER(18,6),
   VAL_048                      NUMBER(18,6),
   VAL_049                      NUMBER(18,6),
   VAL_050                      NUMBER(18,6),
   VAL_051                      NUMBER(18,6),
   VAL_052                      NUMBER(18,6),
   VAL_053                      NUMBER(18,6),
   VAL_054                      NUMBER(18,6),
   VAL_055                      NUMBER(18,6),
   VAL_056                      NUMBER(18,6),
   VAL_057                      NUMBER(18,6),
   VAL_058                      NUMBER(18,6),
   VAL_059                      NUMBER(18,6),
   VAL_060                      NUMBER(18,6),
   VAL_061                      NUMBER(18,6),
   VAL_062                      NUMBER(18,6),
   VAL_063                      NUMBER(18,6),
   VAL_064                      NUMBER(18,6),
   VAL_065                      NUMBER(18,6),
   VAL_066                      NUMBER(18,6),
   VAL_067                      NUMBER(18,6),
   VAL_068                      NUMBER(18,6),
   VAL_069                      NUMBER(18,6),
   VAL_070                      NUMBER(18,6),
   VAL_071                      NUMBER(18,6),
   VAL_072                      NUMBER(18,6),
   VAL_073                      NUMBER(18,6),
   VAL_074                      NUMBER(18,6),
   VAL_075                      NUMBER(18,6),
   VAL_076                      NUMBER(18,6),
   VAL_077                      NUMBER(18,6),
   VAL_078                      NUMBER(18,6),
   VAL_079                      NUMBER(18,6),
   VAL_080                      NUMBER(18,6),
   VAL_081                      NUMBER(18,6),
   VAL_082                      NUMBER(18,6),
   VAL_083                      NUMBER(18,6),
   VAL_084                      NUMBER(18,6),
   VAL_085                      NUMBER(18,6),
   VAL_086                      NUMBER(18,6),
   VAL_087                      NUMBER(18,6),
   VAL_088                      NUMBER(18,6),
   VAL_089                      NUMBER(18,6),
   VAL_090                      NUMBER(18,6),
   VAL_091                      NUMBER(18,6),
   VAL_092                      NUMBER(18,6),
   VAL_093                      NUMBER(18,6),
   VAL_094                      NUMBER(18,6),
   VAL_095                      NUMBER(18,6),
   VAL_096                      NUMBER(18,6),
   VAL_097                      NUMBER(18,6),
   VAL_098                      NUMBER(18,6),
   VAL_099                      NUMBER(18,6),
   VAL_100                      NUMBER(18,6)
   )
storage
(
	initial 128K
        next 128K
        pctincrease 0
)
tablespace nero_data
/


/*==============================================================*/
/* Table: LOAD_SEG_REPORT_RUN_HEADER                            */
/*==============================================================*/


create table LOAD_SEG_REPORT_RUN_HEADER( 
   PROCESS_ID           NUMBER(12) not null,
   REPORT_ID            NUMBER(9) not null,
   BEGIN_DATE           DATE not null,
   END_DATE             DATE not null,
   INTERVAL             VARCHAR2(16) not null,
   RUN_TYPE_ID          NUMBER(9) not null,
   ACCOUNT_IDENT_ATTR   VARCHAR2(512),             
   ACCOUNT_IDENT_SEG_BY NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_01         VARCHAR2(512),  
   ATTR_01_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_02         VARCHAR2(512),  
   ATTR_02_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_03         VARCHAR2(512),  
   ATTR_03_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_04         VARCHAR2(512),  
   ATTR_04_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_05         VARCHAR2(512),  
   ATTR_05_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_06         VARCHAR2(512),  
   ATTR_06_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_07         VARCHAR2(512),  
   ATTR_07_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_08         VARCHAR2(512),  
   ATTR_08_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_09         VARCHAR2(512),  
   ATTR_09_SEG_BY       NUMBER(1,0) DEFAULT 0 not null,
   ATTR_NAME_10         VARCHAR2(512),  
   ATTR_10_SEG_BY       NUMBER(1,0) DEFAULT 0 not null
   )
storage
(
	initial 128K
        next 128K
        pctincrease 0
)
tablespace nero_data
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LOAD_SEG_RPT_HDR_PK
   PRIMARY KEY (PROCESS_ID)
   USING INDEX
	TABLESPACE NERO_INDEX
	STORAGE(INITIAL 64K
			  NEXT 64K
			  PCTINCREASE 0)
/ 

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_SUB_AGG_SEG_BY_CHK CHECK (ACCOUNT_IDENT_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_01_SEG_BY_CHK CHECK (ATTR_01_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_02_SEG_BY_CHK CHECK (ATTR_02_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_03_SEG_BY_CHK CHECK (ATTR_03_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_04_SEG_BY_CHK CHECK (ATTR_04_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_05_SEG_BY_CHK CHECK (ATTR_05_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_06_SEG_BY_CHK CHECK (ATTR_06_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_07_SEG_BY_CHK CHECK (ATTR_07_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_08_SEG_BY_CHK CHECK (ATTR_08_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_09_SEG_BY_CHK CHECK (ATTR_09_SEG_BY IN (0 ,1))
/

ALTER TABLE LOAD_SEG_REPORT_RUN_HEADER
   ADD CONSTRAINT LSRH_ATTR_10_SEG_BY_CHK CHECK (ATTR_10_SEG_BY IN (0 ,1))
/


/*==============================================================*/
/* Table: LOSS_FACTOR                                           */
/*==============================================================*/


create table LOSS_FACTOR  (
   LOSS_FACTOR_ID       NUMBER(9)                        not null,
   LOSS_FACTOR_NAME     VARCHAR2(32)                     not null,
   LOSS_FACTOR_ALIAS    VARCHAR2(32),
   LOSS_FACTOR_DESC     VARCHAR2(256),
   EXTERNAL_IDENTIFIER  VARCHAR(32),
   ENTRY_DATE           DATE,
   constraint PK_LOSS_FACTOR primary key (LOSS_FACTOR_ID)
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


alter table LOSS_FACTOR
   add constraint AK_LOSS_FACTOR unique (LOSS_FACTOR_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: LOSS_FACTOR_MODEL                                     */
/*==============================================================*/


create table LOSS_FACTOR_MODEL  (
   LOSS_FACTOR_ID		NUMBER(9)						not null,
   LOSS_TYPE			VARCHAR2(32)					not null,
   BEGIN_DATE           DATE							not null,
   END_DATE             DATE,
   FACTOR_TYPE     		VARCHAR2(16)              		not null,
   MODEL_TYPE      		VARCHAR2(32)                   	not null,
   INTERVAL 			VARCHAR2(16)           	 		not null,
   PATTERN_ID           NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_LOSS_FACTOR_MODEL primary key (LOSS_FACTOR_ID, LOSS_TYPE, BEGIN_DATE)
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

alter table LOSS_FACTOR_MODEL
   add constraint AK_LOSS_FACTOR_MODEL unique (PATTERN_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: LOSS_FACTOR_PATTERN                                   */
/*==============================================================*/


create table LOSS_FACTOR_PATTERN  (
   PATTERN_ID           NUMBER(9)                       not null,
   PATTERN_DATE         DATE                          	not null,
   EXPANSION_VAL		NUMBER(8,6)						not null,
   LOSS_VAL          	NUMBER(8,6)						not null,
   constraint PK_LOSS_FACTOR_PATTERN primary key (PATTERN_ID, PATTERN_DATE)
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


/*==============================================================*/
/* Table: MARKET_FORWARD_PRICE                                  */
/*==============================================================*/


create table MARKET_FORWARD_PRICE  (
   MARKET_PRICE_ID      NUMBER(9)                        not null,
   CONTRACT_MONTH       DATE                             not null,
   CONTRACT_TYPE        CHAR(1)                          not null,
   CONTRACT_DATE        DATE                             not null,
   BID_PRICE            NUMBER(6,2),
   ASK_PRICE            NUMBER(6,2),
   LOW_PRICE            NUMBER(6,2),
   HIGH_PRICE           NUMBER(6,2),
   ENTRY_DATE           DATE,
   constraint PK_MARKET_FORWARD_PRICE primary key (MARKET_PRICE_ID, CONTRACT_MONTH, CONTRACT_TYPE, CONTRACT_DATE)
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


/*==============================================================*/
/* Table: MARKET_PRICE                                          */
/*==============================================================*/


create table MARKET_PRICE  (
   MARKET_PRICE_ID      NUMBER(9)                        not null,
   MARKET_PRICE_NAME    VARCHAR2(256)                     not null,
   MARKET_PRICE_ALIAS   VARCHAR2(256),
   MARKET_PRICE_DESC    VARCHAR2(4000),
   MARKET_PRICE_TYPE    VARCHAR2(32),
   MARKET_PRICE_INTERVAL VARCHAR2(16),
   MARKET_TYPE          VARCHAR2(32),
   COMMODITY_ID         NUMBER(9),
   SERVICE_POINT_TYPE   VARCHAR2(16),
   EXTERNAL_IDENTIFIER  VARCHAR2(64),
   EDC_ID               NUMBER(9),
   SC_ID                NUMBER(9),
   POD_ID               NUMBER(9),
   ZOD_ID               NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_MARKET_PRICE primary key (MARKET_PRICE_ID)
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


comment on table MARKET_PRICE is
'Holds all of the data for a Market Price other than the actual Price Schedule'
/


comment on column MARKET_PRICE.MARKET_PRICE_ID is
'Unique ID generated by OID'
/


comment on column MARKET_PRICE.MARKET_PRICE_NAME is
'Unique Name for the Market Price'
/


comment on column MARKET_PRICE.MARKET_PRICE_ALIAS is
'Optional Market Price Alias'
/


comment on column MARKET_PRICE.MARKET_PRICE_DESC is
'Optional Market Price Description'
/


comment on column MARKET_PRICE.MARKET_PRICE_TYPE is
'The Market Price Type'
/


comment on column MARKET_PRICE.MARKET_PRICE_INTERVAL is
'The Interval of the Market Price'
/


comment on column MARKET_PRICE.MARKET_TYPE is
'Settlement Market (day-ahead, real-time)'
/


comment on column MARKET_PRICE.COMMODITY_ID is
'For what Commodity does this price apply?'
/


comment on column MARKET_PRICE.SERVICE_POINT_TYPE is
'Service Point Type for Locational Marginal Price Type Market Prices. Can be ''Zonal'' to indicate that this is a Zonal Market Price.'
/


comment on column MARKET_PRICE.EXTERNAL_IDENTIFIER is
'Optional Identifier to be used by Interfaces to External Systems'
/


comment on column MARKET_PRICE.EDC_ID is
'EDC with which this Market Price is associated'
/


comment on column MARKET_PRICE.SC_ID is
'Schedule Coordinator with which this Market Price is associated'
/


comment on column MARKET_PRICE.POD_ID is
'Service Point to which this Locational Marginal Price Type Market Price corresponds'
/


comment on column MARKET_PRICE.ZOD_ID is
'Service Zone to which this Zonal Market Price corresponds'
/


comment on column MARKET_PRICE.ENTRY_DATE is
'The time stamp of this record’s entry'
/


alter table MARKET_PRICE
   add constraint AK_MARKET_PRICE unique (MARKET_PRICE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: MARKET_PRICE_IX01                                     */
/*==============================================================*/
create index MARKET_PRICE_IX01 on MARKET_PRICE (
   MARKET_PRICE_TYPE ASC,
   MARKET_TYPE ASC,
   POD_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: MARKET_PRICE_COMPOSITE                                */
/*==============================================================*/


create table MARKET_PRICE_COMPOSITE  (
   MARKET_PRICE_ID      NUMBER(9)                        not null,
   COMPOSITE_MARKET_PRICE_ID NUMBER(9)                        not null,
   COMPOSITE_OPTION     VARCHAR2(32),
   COMPOSITE_MULTIPLIER NUMBER(8,4),
   ENTRY_DATE           DATE,
   constraint PK_MARKET_PRICE_COMPOSITE primary key (MARKET_PRICE_ID, COMPOSITE_MARKET_PRICE_ID)
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

/*==============================================================*/
/* Index: FK_MARKET_PRICE_COMP2                                 */
/*==============================================================*/
create index FK_MARKET_PRICE_COMP2 on MARKET_PRICE_COMPOSITE (
   COMPOSITE_MARKET_PRICE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: MARKET_PRICE_VAL_LOCK_SUMMARY                         */
/*==============================================================*/


create table MARKET_PRICE_VAL_LOCK_SUMMARY  (
   MARKET_PRICE_ID      NUMBER(9)                        not null,
   PRICE_CODE           CHAR(1)                          not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOCK_STATE           CHAR(1) DEFAULT 'U'              not null,
   constraint PK_MARKET_PRICE_VAL_LK_SUMMARY primary key (MARKET_PRICE_ID, PRICE_CODE, BEGIN_DATE)
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


/*==============================================================*/
/* Table: MARKET_PRICE_VALUE                                    */
/*==============================================================*/


create table MARKET_PRICE_VALUE  (
   MARKET_PRICE_ID      NUMBER(9)                        not null,
   PRICE_CODE           CHAR(1)                          not null,
   PRICE_DATE           DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   PRICE_BASIS          NUMBER(16,6),
   PRICE                NUMBER(16,6),
   LOCK_STATE           CHAR(1),
   constraint PK_MARKET_PRICE_VALUE primary key (MARKET_PRICE_ID, PRICE_CODE, PRICE_DATE, AS_OF_DATE)
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

alter table MARKET_PRICE_VALUE
   add constraint CK01_MARKET_PRICE_VALUE check (MARKET_PRICE_ID <> 0)
/


alter table MARKET_PRICE_VALUE
   add constraint CK02_MARKET_PRICE_VALUE check (PRICE_CODE IN ('F','P','A'))
/


/*==============================================================*/
/* Index: MARKET_PRICE_VALUE_IX01                               */
/*==============================================================*/
create index MARKET_PRICE_VALUE_IX01 on MARKET_PRICE_VALUE (
   MARKET_PRICE_ID ASC,
   PRICE_DATE ASC,
   PRICE_CODE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: MARKET_PRICE_VALUE_ERRS_TMP                           */
/*==============================================================*/


create global temporary table MARKET_PRICE_VALUE_ERRS_TMP  (
   ORA_ERR_NUMBER$      NUMBER,
   ORA_ERR_MESG$        VARCHAR2(2000),
   ORA_ERR_ROWID$       ROWID,
   ORA_ERR_OPTYP$       VARCHAR2(2),
   ORA_ERR_TAG$         VARCHAR2(2000),
   MARKET_PRICE_ID      VARCHAR2(4000),
   PRICE_CODE           VARCHAR2(4000),
   PRICE_DATE           VARCHAR2(4000),
   AS_OF_DATE           VARCHAR2(4000),
   PRICE_BASIS          VARCHAR2(4000),
   PRICE                VARCHAR2(4000),
   LOCK_STATE           VARCHAR2(4000)
)
/


/*==============================================================*/
/* Index: MARKET_PRICE_VAL_ERRS_TMP_IX01                        */
/*==============================================================*/
create index MARKET_PRICE_VAL_ERRS_TMP_IX01 on MARKET_PRICE_VALUE_ERRS_TMP (
   ORA_ERR_TAG$ ASC
)
/


/*==============================================================*/
/* Table: MEASUREMENT_SOURCE                                    */
/*==============================================================*/


create table MEASUREMENT_SOURCE  (
   MEASUREMENT_SOURCE_ID NUMBER(9)                        not null,
   MEASUREMENT_SOURCE_NAME VARCHAR2(64)                     not null,
   MEASUREMENT_SOURCE_ALIAS VARCHAR2(32),
   MEASUREMENT_SOURCE_DESC VARCHAR2(256),
   MEASUREMENT_SOURCE_TYPE VARCHAR2(32),
   MEASUREMENT_SOURCE_INTERVAL VARCHAR2(16),
   METER_TYPE           VARCHAR2(32),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   EXTERNAL_SYSTEM_ID   NUMBER(9),
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   PRECISION            NUMBER(2),
   UOM                  VARCHAR2(16),
   POLLING_TIME         NUMBER(6),
   ENTRY_DATE           DATE,
   constraint PK_MEASUREMENT_SOURCE primary key (MEASUREMENT_SOURCE_ID)
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


alter table MEASUREMENT_SOURCE
   add constraint AK_MEASUREMENT_SOURCE unique (MEASUREMENT_SOURCE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_MEASUREMENT_SOURCE                                 */
/*==============================================================*/
create index FK_MEASUREMENT_SOURCE on MEASUREMENT_SOURCE (
   EXTERNAL_SYSTEM_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: MEASUREMENT_SOURCE_VALUE                              */
/*==============================================================*/


create table MEASUREMENT_SOURCE_VALUE  (
   MEASUREMENT_SOURCE_ID NUMBER(9)                        not null,
   SOURCE_DATE          DATE                             not null,
   SOURCE_VALUE         NUMBER,
   SOURCE_QUAL_CODE     VARCHAR2(16),
   ENTRY_DATE           DATE,
   LOCK_STATE           CHAR(1),
   constraint PK_MEASUREMENT_SOURCE_VALUE primary key (MEASUREMENT_SOURCE_ID, SOURCE_DATE)
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


/*==============================================================*/
/* Table: MEASUREMENT_SOURCE_VAL_ERR_TMP                        */
/*==============================================================*/


create global temporary table MEASUREMENT_SOURCE_VAL_ERR_TMP  (
   ORA_ERR_NUMBER$      NUMBER,
   ORA_ERR_MESG$        VARCHAR2(2000),
   ORA_ERR_ROWID$       ROWID,
   ORA_ERR_OPTYP$       VARCHAR2(2),
   ORA_ERR_TAG$         VARCHAR2(2000),
   MEASUREMENT_SOURCE_ID VARCHAR2(4000),
   SOURCE_DATE          VARCHAR2(4000),
   SOURCE_VALUE         VARCHAR2(4000),
   SOURCE_QUAL_CODE     VARCHAR2(4000),
   ENTRY_DATE           VARCHAR2(4000),
   LOCK_STATE           VARCHAR2(4000)
)
/


/*==============================================================*/
/* Index: MEASUREMENT_SRC_VAL_ERR_T_IX01                        */
/*==============================================================*/
create index MEASUREMENT_SRC_VAL_ERR_T_IX01 on MEASUREMENT_SOURCE_VAL_ERR_TMP (
   ORA_ERR_TAG$ ASC
)
/


/*==============================================================*/
/* Table: MEASUREMENT_SRC_VAL_LK_SUMMARY                        */
/*==============================================================*/


create table MEASUREMENT_SRC_VAL_LK_SUMMARY  (
   MEASUREMENT_SOURCE_ID NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOCK_STATE           CHAR(1) DEFAULT 'U'              not null,
   constraint PK_MEASUREMENT_SRC_VAL_LK_SUM primary key (MEASUREMENT_SOURCE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: MESSAGE_DEFINITION                                    */
/*==============================================================*/


create table MESSAGE_DEFINITION  (
   MESSAGE_ID           NUMBER(9)                        not null,
   MESSAGE_TYPE         VARCHAR2(6)                      not null,
   MESSAGE_NUMBER       NUMBER(5)                        not null,
   MESSAGE_TEXT         VARCHAR2(1000)                   not null,
   MESSAGE_DESC         VARCHAR2(4000),
   MESSAGE_SOLUTION     VARCHAR2(4000),
   MESSAGE_IDENT        VARCHAR2(28)                     not null,
   constraint PK_MESSAGE_DEFINITION primary key (MESSAGE_ID)
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


alter table MESSAGE_DEFINITION
   add constraint CK01_MESSAGE_DEFINITION check ((MESSAGE_TYPE = 'ORA' AND MESSAGE_NUMBER BETWEEN 20000 AND 20999) OR MESSAGE_NUMBER BETWEEN 0 AND 99999)
/


alter table MESSAGE_DEFINITION
   add constraint AK_MESSAGE_DEFINITION unique (MESSAGE_TYPE, MESSAGE_NUMBER)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


alter table MESSAGE_DEFINITION
   add constraint AK_MESSAGE_DEFINITION2 unique (MESSAGE_IDENT)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: METER                                                 */
/*==============================================================*/


create table METER  (
   MRSP_ID              NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   METER_NAME           VARCHAR2(128)                     not null,
   METER_ALIAS          VARCHAR2(128),
   METER_DESC           VARCHAR2(256),
   METER_EXTERNAL_IDENTIFIER VARCHAR2(128),
   METER_STATUS         VARCHAR2(16),
   METER_INTERVAL       VARCHAR2(16),
   METER_TYPE           VARCHAR2(8),
   METER_UNIT           VARCHAR2(8),
   IS_EXTERNAL_INTERVAL_USAGE NUMBER(1),
   IS_EXTERNAL_BILLED_USAGE NUMBER(1),
   IS_EXTERNAL_FORECAST NUMBER(1),
   USE_TOU_USAGE_FACTOR             NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_METER primary key (MRSP_ID, METER_ID)
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


alter table METER
   add constraint AK_METER unique (METER_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Index: METER_IX01                                            */
/*==============================================================*/
create index METER_IX01 on METER (
   METER_NAME ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Index: METER_IX02                                            */
/*==============================================================*/
create index METER_IX02 on METER (
   METER_EXTERNAL_IDENTIFIER ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Index: FK_METER_STATUS_NAME                                  */
/*==============================================================*/
create index FK_METER_STATUS_NAME on METER (
   METER_STATUS ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: METER_ANCILLARY_SERVICE                               */
/*==============================================================*/


create table METER_ANCILLARY_SERVICE  (
   METER_ID             NUMBER(9)                        not null,
   ANCILLARY_SERVICE_ID NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SERVICE_VAL          NUMBER,
   ENTRY_DATE           DATE,
   constraint PK_METER_ANCILLARY_SERVICE primary key (METER_ID, ANCILLARY_SERVICE_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: METER_BILL_CYCLE                                      */
/*==============================================================*/


create table METER_BILL_CYCLE  (
   METER_ID             NUMBER(9)                        not null,
   BILL_CYCLE_ID        NUMBER(9)                        not null,
   BILL_CYCLE_ENTITY    VARCHAR(16)                      not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_METER_BILL_CYCLE primary key (METER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: METER_BILL_PARTY                                      */
/*==============================================================*/


create table METER_BILL_PARTY  (
   METER_ID             NUMBER(9)                        not null,
   BILL_PARTY_ID        NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_METER_BILL_PARTY primary key (METER_ID, BILL_PARTY_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: METER_CALENDAR                                        */
/*==============================================================*/


create table METER_CALENDAR  (
   CASE_ID              NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   CALENDAR_ID          NUMBER(9)                        not null,
   CALENDAR_TYPE        VARCHAR2(16)                     not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_METER_CALENDAR primary key (CASE_ID, METER_ID, CALENDAR_TYPE, BEGIN_DATE)
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


/*==============================================================*/
/* Table: METER_GROWTH                                          */
/*==============================================================*/


create table METER_GROWTH  (
   CASE_ID              NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PATTERN_ID           NUMBER(9),
   GROWTH_PCT           NUMBER(8,3),
   ENTRY_DATE           DATE,
   constraint PK_METER_GROWTH primary key (CASE_ID, METER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: METER_LOSS_FACTOR                                     */
/*==============================================================*/


create table METER_LOSS_FACTOR  (
   CASE_ID              NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   LOSS_FACTOR_ID       NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_METER_LOSS_FACTOR primary key (CASE_ID, METER_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: FK_MTR_LOSS_FACTOR                                    */
/*==============================================================*/
create index FK_MTR_LOSS_FACTOR on METER_LOSS_FACTOR (
   LOSS_FACTOR_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: METER_PRODUCT                                         */
/*==============================================================*/


create table METER_PRODUCT  (
   CASE_ID              NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   PRODUCT_TYPE         CHAR(1)                          not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_METER_PRODUCT primary key (CASE_ID, METER_ID, PRODUCT_TYPE, BEGIN_DATE)
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


/*==============================================================*/
/* Table: METER_READING_SERVICE_PROVIDER                        */
/*==============================================================*/


create table METER_READING_SERVICE_PROVIDER  (
   MRSP_ID              NUMBER(9)                        not null,
   MRSP_NAME            VARCHAR2(32)                     not null,
   MRSP_ALIAS           VARCHAR2(32),
   MRSP_DESC            VARCHAR2(256),
   MRSP_DUNS_NUMBER     VARCHAR2(16),
   MRSP_STATUS          VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_METER_READING_SERVICE_PROVI primary key (MRSP_ID)
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


alter table METER_READING_SERVICE_PROVIDER
   add constraint AK_METER_READING_SERVICE_PROVI unique (MRSP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: METER_SUB_AGG_AGGREGATION                             */
/*==============================================================*/
create table METER_SUB_AGG_AGGREGATION  (
   METER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   AGGREGATE_ID         NUMBER(9)                        not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_METER_SUB_AGG_AGG primary key (METER_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Table: METER_TOU_USAGE_FACTOR                                  */
/*==============================================================*/


create table METER_TOU_USAGE_FACTOR  (
   METER_ID             NUMBER(9)                        not null,
   CASE_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   TEMPLATE_ID    NUMBER(9)	not null,
   TOU_USAGE_FACTOR_ID    NUMBER(9)	not null,
   ENTRY_DATE           DATE,
   constraint PK_METER_TOU_USAGE_FACTOR primary key (METER_ID, CASE_ID, BEGIN_DATE)
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

alter table METER_TOU_USAGE_FACTOR
   add constraint AK_METER_TOU_USAGE_FACTOR unique (TOU_USAGE_FACTOR_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: METER_TOU_USAGE_FACTOR_PERIOD                                        */
/*==============================================================*/


create table METER_TOU_USAGE_FACTOR_PERIOD  (
   TOU_USAGE_FACTOR_ID          NUMBER(9)	not null,
   PERIOD_ID          NUMBER(9) 	not null,
   FACTOR_VAL          NUMBER(14,6),
   ENTRY_DATE          DATE,
   constraint PK_METER_TOU_USG_FACTOR_PERIOD primary key (TOU_USAGE_FACTOR_ID, PERIOD_ID)
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

/*==============================================================*/
/* Table: METER_SCHEDULE_GROUP                                  */
/*==============================================================*/


create table METER_SCHEDULE_GROUP  (
   METER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SCHEDULE_GROUP_ID    NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_METER_SCHEDULE_GROUP primary key (METER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: METER_USAGE_FACTOR                                    */
/*==============================================================*/


create table METER_USAGE_FACTOR  (
   CASE_ID              NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   FACTOR_VAL           NUMBER(14,6),
   SOURCE_CALENDAR_ID   NUMBER(9),
   SOURCE_BEGIN_DATE    DATE,
   SOURCE_END_DATE      DATE,
   ENTRY_DATE           DATE,
   constraint PK_METER_USAGE_FACTOR primary key (CASE_ID, METER_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Table: MEX_MESSAGE                                   */
/*==============================================================*/
CREATE TABLE MEX_MESSAGE
(
  MESSAGE_ID            NUMBER(9)                   NOT NULL,
  MESSAGE_DATE          DATE,
  MARKET_OPERATOR       VARCHAR2(32),
  MESSAGE_REALM         VARCHAR2(16),
  MESSAGE_PRIORITY      NUMBER(9),
  EFFECTIVE_DATE        DATE,
  TERMINATION_DATE      DATE,
  MESSAGE_SOURCE        VARCHAR2(64),
  MESSAGE_DESTINATION   VARCHAR2(64),
  MESSAGE_TEXT          VARCHAR2(4000),
   ENTRY_DATE           DATE,
  constraint PK_MEX_MESSAGE primary key (MESSAGE_ID)
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

/*==============================================================*/
/* Table: MODEL                                                 */
/*==============================================================*/


create table MODEL  (
   MODEL_ID             NUMBER(1)                        not null,
   MODEL_NAME           VARCHAR2(32),
   constraint PK_MODEL primary key (MODEL_ID)
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


/*==============================================================*/
/* Table: NERO_TABLE_PROPERTY_INDEX                             */
/*==============================================================*/


create table NERO_TABLE_PROPERTY_INDEX  (
   TABLE_NAME           VARCHAR2(32)                     not null,
   PRIMARY_ID_COLUMN    VARCHAR2(32),
   ALIAS                VARCHAR2(32),
   SECONDARY_ID_COLUMN  VARCHAR2(32),
   INCLUDE_UNIQUE_NAME_TEST NUMBER (1),
   PRIMARY_IDENT_COLUMN VARCHAR2(32),
   constraint PK_NERO_TABLE_PROPERTY_INDEX primary key (TABLE_NAME)
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


/*==============================================================*/
/* Table: NET_RETAIL_PROFIT_LOSS                                */
/*==============================================================*/


create table NET_RETAIL_PROFIT_LOSS  (
   STATEMENT_TYPE       NUMBER(9)                        not null,
   STATEMENT_DATE       DATE                             not null,
   CHARGE_DATE          DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   SYSTEM_OVER_SUPPLY   NUMBER(12,4),
   SYSTEM_UNDER_SUPPLY  NUMBER(12,4),
   SYSTEM_NET_POSITION  NUMBER(12,4),
   OVER_SUPPLY_RATE     NUMBER(12,4),
   UNDER_SUPPLY_RATE    NUMBER(12,4),
   OSF_AMOUNT           NUMBER(12,4),
   OSF_RATE             NUMBER(12,4),
   REVENUE_AMOUNT       NUMBER(12,2),
   BENEFIT_AMOUNT       NUMBER(12,2),
   constraint PK_NET_RETAIL_PROFIT_LOSS primary key (STATEMENT_TYPE, STATEMENT_DATE, CHARGE_DATE, AS_OF_DATE)
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

/*==============================================================*/
/* Table: SERVICE_CONSUMPTION_STAGING		                */
/*==============================================================*/
create table SERVICE_CONSUMPTION_STAGING  (
	ACCOUNT_IDENT            	VARCHAR2(64)    not null,
	METER_IDENT               	VARCHAR2(128),
	ESP_IDENT               	VARCHAR2(64),
	POOL_IDENT                	VARCHAR2(64),
	BEGIN_DATE             		DATE  		not null,
	END_DATE                   	DATE  		not null,
	BILL_CODE            		CHAR(1) ,	
	CONSUMPTION_CODE     		CHAR(1) ,
	TEMPLATE_IDENT          	VARCHAR2(32),
	PERIOD_IDENT            	VARCHAR2(32) ,
	UOM  		VARCHAR2(8),
	METER_READING        		VARCHAR2(16),
	BILLED_USAGE         		NUMBER,
	BILLED_DEMAND        		NUMBER,
	METERED_USAGE        		NUMBER,
	METERED_DEMAND       		NUMBER,
	METERS_READ          		NUMBER,
	CONVERSION_FACTOR    		NUMBER,
	BILL_PROCESSED_DATE  		DATE,
   	SYNC_ORDER               	NUMBER,
   	SYNC_STATUS              	VARCHAR2(32),
   	ERROR_MESSAGE              	VARCHAR2(4000),
	AGGREGATE_ID 			NUMBER,
	ACCOUNT_MODEL_OPTION 		VARCHAR2(16),
	ACCOUNT_METER_TYPE	 	VARCHAR2(16),
	ACCOUNT_NAME 			VARCHAR2(128),
	PROCESS_ID 			NUMBER,
	ERROR_LIST_ITEM			VARCHAR2(64),
	ERROR_FLAG 			NUMBER,
	STEP_ERROR_FLAG 		NUMBER,
	ACCOUNT_ID 			NUMBER,
	SERVICE_LOCATION_ID 		NUMBER,
	METER_ID 			NUMBER,
	METER_NAME 			VARCHAR2(128),
	METER_TYPE			VARCHAR2(8),
	TEMPLATE_ID 			NUMBER,
	PERIOD_ID 			NUMBER,
	ESP_ID 				NUMBER,
	POOL_ID 			NUMBER
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: NOST_DEMAND_STATION_MAPPING                           */
/*==============================================================*/


create table NOST_DEMAND_STATION_MAPPING  (
   STATION_ID           NUMBER(9)                        not null,
   FAC_CODE             NUMBER(9),
   constraint PK_NOST_DEMAND_STATION_MAPPING primary key (STATION_ID)
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


/*==============================================================*/
/* Table: NOST_WEATHER_PARAMETER_MAPPING                        */
/*==============================================================*/


create table NOST_WEATHER_PARAMETER_MAPPING  (
   PARAMETER_ID         NUMBER(9)                        not null,
   ITEMCODE             NUMBER(9),
   constraint PK_NOST_WEATHER_PARAMETER_MAPP primary key (PARAMETER_ID)
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


/*==============================================================*/
/* Table: NOST_WEATHER_STATION_MAPPING                          */
/*==============================================================*/


create table NOST_WEATHER_STATION_MAPPING  (
   STATION_ID           NUMBER(9)                        not null,
   FAC_CODE             NUMBER(9),
   constraint PK_NOST_WEATHER_STATION_MAPPIN primary key (STATION_ID)
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


/*==============================================================*/
/* Table: OASIS_NODE                                            */
/*==============================================================*/


create table OASIS_NODE  (
   OASIS_NODE_ID        NUMBER(9)                        not null,
   OASIS_NODE_NAME      VARCHAR2(150)                    not null,
   OASIS_NODE_ALIAS     VARCHAR2(150),
   OASIS_NODE_DESC      VARCHAR2(256),
   URL                  VARCHAR2(150),
   ENTRY_DATE           DATE,
   constraint PK_OASIS_NODE primary key (OASIS_NODE_ID)
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


alter table OASIS_NODE
   add constraint AK_OASIS_NODE unique (OASIS_NODE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: OASIS_RESERVATION                                     */
/*==============================================================*/


create table OASIS_RESERVATION  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   RESERVATON_NBR       NUMBER                           not null,
   CHANGE_DATE          DATE                             not null,
   START_DATE           DATE,
   STOP_DATE            DATE,
   RESERVATION_IDENTIFIER VARCHAR2(32),
   CAPACITY_RESERVED    NUMBER(6),
   OASIS_DEMAND_CHARGE  NUMBER(8,2),
   OASIS_POD_ID         NUMBER(9),
   OASIS_POR_ID         NUMBER(9),
   SCHEDULE_1           NUMBER(1),
   SCHEDULE_2           NUMBER(1),
   SCHEDULE_3           NUMBER(1),
   SCHEDULE_4           NUMBER(1),
   SCHEDULE_5           NUMBER(1),
   SCHEDULE_6           NUMBER(1),
   OASIS_CAPACITY_TYPE  VARCHAR2(64),
   BILLING_FLAG         CHAR(1),
   DURATION             VARCHAR2(4),
   constraint PK_OASIS_RESERVATION primary key (TRANSACTION_ID, RESERVATON_NBR, CHANGE_DATE)
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


/*==============================================================*/
/* Table: OPER_PROFIT_CHARGE                                    */
/*==============================================================*/


create table OPER_PROFIT_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   SERVICE_POINT_ID     NUMBER(9),
   MARKET_QUANTITY      NUMBER(18,9),
   MARKET_OPER_PROFIT   NUMBER (18,9),
   DISPATCH_QUANTITY    NUMBER(18,9),
   DISPATCH_OPER_PROFIT NUMBER(18,9),
   ACTUAL_QUANTITY      NUMBER(18,9),
   ACTUAL_OPER_PROFIT   NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_OPER_PROFIT_CHARGE primary key (CHARGE_ID, CHARGE_DATE)
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


/*==============================================================*/
/* Table: OPER_PROFIT_CHARGE_SET                                */
/*==============================================================*/


create table OPER_PROFIT_CHARGE_SET  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   SET_NUMBER           NUMBER(4)                        not null,
   QUANTITY             NUMBER(12,3),
   PRICE                NUMBER(12,3),
   constraint PK_OPER_PROFIT_CHARGE_SET primary key (CHARGE_ID, CHARGE_DATE, SET_NUMBER)
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


/*==============================================================*/
/* Table: OPER_PROFIT_WORK                                      */
/*==============================================================*/


create global temporary table OPER_PROFIT_WORK  (
   WORK_ID              NUMBER(9)                        not null,
   WORK_XID             NUMBER(9)                        not null,
   WORK_DATE            DATE                             not null,
   WORK_SET_NUMBER      NUMBER(4)                        not null,
   WORK_PRICE           NUMBER(12,3),
   WORK_QUANTITY        NUMBER(12,3),
   constraint PK_OPER_PROFIT_WORK primary key (WORK_ID, WORK_XID, WORK_DATE, WORK_SET_NUMBER)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: PATH_PROVIDER                                         */
/*==============================================================*/


create table PATH_PROVIDER  (
   PATH_ID              NUMBER(9)                        not null,
   LEG_NBR              NUMBER(2)                        not null,
   CA_ID                NUMBER(9),
   TP_ID                NUMBER(9),
   PSE_ID               NUMBER(9),
   TP_PRODUCT_CODE      VARCHAR2(16),
   TP_PATH_NAME         VARCHAR2(32),
   TP_ASSIGNMENT_REF    VARCHAR2(16),
   TP_PRODUCT_LEVEL     VARCHAR2(16),
   MISC_INFO            VARCHAR2(16),
   MISC_REF             VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_PATH_PROVIDER primary key (PATH_ID, LEG_NBR)
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


/*==============================================================*/
/* Table: PERIOD                                                */
/*==============================================================*/


create table PERIOD  (
   PERIOD_ID            NUMBER(9)                        not null,
   PERIOD_NAME          VARCHAR2(32)                     not null,
   PERIOD_ALIAS         VARCHAR2(32),
   PERIOD_DESC          VARCHAR2(256),
   PERIOD_COLOR         NUMBER(8),
   ENTRY_DATE           DATE,
   constraint PK_PERIOD primary key (PERIOD_ID)
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


alter table PERIOD
   add constraint AK_PERIOD unique (PERIOD_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: PHONE_NUMBER                                          */
/*==============================================================*/


create table PHONE_NUMBER  (
   CONTACT_ID           NUMBER(9)                        not null,
   PHONE_TYPE           VARCHAR2(16)                     not null,
   PHONE_NUMBER         VARCHAR2(24),
   ENTRY_DATE           DATE,
   constraint PK_PHONE_NUMBER primary key (CONTACT_ID, PHONE_TYPE)
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


/*==============================================================*/
/* Table: PIPELINE                                              */
/*==============================================================*/


create table PIPELINE  (
   PIPELINE_ID          NUMBER(9)                        not null,
   PIPELINE_NAME        VARCHAR(32)                      not null,
   PIPELINE_ALIAS       VARCHAR(32),
   PIPELINE_DESC        VARCHAR(256),
   PIPELINE_STATUS      VARCHAR(16),
   EXTERNAL_IDENTIFIER  VARCHAR(32),
   ENTRY_DATE           DATE,
   constraint PK_PIPELINE primary key (PIPELINE_ID)
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


alter table PIPELINE
   add constraint AK_PIPELINE unique (PIPELINE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: PIPELINE_CHARGE                                       */
/*==============================================================*/


create table PIPELINE_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   DELIVERY_ID          NUMBER(9)                        not null,
   POR_ID               NUMBER(9)                        not null,
   POD_ID               NUMBER(9)                        not null,
   SEGMENT_NUMBER       NUMBER(3),
   DISTANCE             NUMBER(18,3),
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_PIPELINE_CHARGE primary key (CHARGE_ID, CHARGE_DATE, DELIVERY_ID, POR_ID, POD_ID)
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
       )
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
  )
/


/*==============================================================*/
/* Table: PIPELINE_LIMIT_VALIDATION_WORK                        */
/*==============================================================*/


create global temporary table PIPELINE_LIMIT_VALIDATION_WORK  (
   WORK_ID              NUMBER(9)                        not null,
   PIPELINE_ID          NUMBER(9),
   POR_ID               NUMBER(9)                        not null,
   POD_ID               NUMBER(9)                        not null,
   CONTRACT_ID          NUMBER(9)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   TRANSACTION_ID       NUMBER(9)                        not null,
   CAPACITY_PURCHASED   NUMBER(16,3),
   CAPACITY_SOLD        NUMBER(16,3),
   TOTAL_RECEIVED       NUMBER(16,3),
   TOTAL_DELIVERED      NUMBER(16,3),
   MAX_DAILY_QUANTITY   NUMBER(16,3),
   TOTAL_EXCESS         NUMBER(16,3),
   TOTAL_AVAIL          NUMBER(16,3),
   MISSING_LIMITS       NUMBER(1),
   constraint PK_PIPELINE_LIMIT_VALID_WORK primary key (WORK_ID, POR_ID, POD_ID, CONTRACT_ID, TRANSACTION_ID, SCHEDULE_DATE)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: PIPELINE_POINT_LIMIT                                  */
/*==============================================================*/


create table PIPELINE_POINT_LIMIT  (
   CONTRACT_ID          NUMBER(9)                        not null,
   SERVICE_POINT_ID     NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PERIOD_BEGIN         DATE                             not null,
   PERIOD_END           DATE,
   MAX_DAILY_QUANTITY   NUMBER(16,3),
   ENTRY_DATE           DATE,
   constraint PK_PIPELINE_POINT_LIMIT primary key (CONTRACT_ID, SERVICE_POINT_ID, BEGIN_DATE, PERIOD_BEGIN)
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


/*==============================================================*/
/* Table: PIPELINE_SEGMENT_LIMIT                                */
/*==============================================================*/


create table PIPELINE_SEGMENT_LIMIT  (
   CONTRACT_ID          NUMBER(9)                        not null,
   POR_ID               NUMBER(9)                        not null,
   POD_ID               NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PERIOD_BEGIN         DATE                             not null,
   PERIOD_END           DATE,
   MAX_DAILY_QUANTITY   NUMBER(16,3),
   ENTRY_DATE           DATE,
   constraint PK_PIPELINE_SEGMENT_LIMIT primary key (CONTRACT_ID, POR_ID, POD_ID, BEGIN_DATE, PERIOD_BEGIN)
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
       )
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
  )
/


/*==============================================================*/
/* Table: PIPELINE_TARIFF_RATE                                  */
/*==============================================================*/


create table PIPELINE_TARIFF_RATE  (
   CONTRACT_ID          NUMBER(9)                        not null,
   PIPELINE_TARIFF_TYPE VARCHAR2(16)                     not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PERIOD_BEGIN         DATE                             not null,
   PERIOD_END           DATE,
   ZOR_ID               NUMBER(9)                        not null,
   ZOD_ID               NUMBER(9)                        not null,
   ZONE_ORDER           NUMBER(3)                        not null,
   FROM_MILEAGE         NUMBER(16,3)                     not null,
   TO_MILEAGE           NUMBER(16,3),
   COMMODITY_CHARGE     NUMBER(12,6),
   FUEL_PCT             NUMBER(8,4),
   FUEL_CHARGE          NUMBER(12,6),
   ENTRY_DATE           DATE,
   constraint PK_PIPELINE_TARIFF_RATE primary key (CONTRACT_ID, PIPELINE_TARIFF_TYPE, BEGIN_DATE, PERIOD_BEGIN, ZOR_ID, ZOD_ID, ZONE_ORDER, FROM_MILEAGE)
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


/*==============================================================*/
/* Table: POOL                                                  */
/*==============================================================*/


create table POOL  (
   POOL_ID              NUMBER(9)                        not null,
   POOL_NAME            VARCHAR2(32)                     not null,
   POOL_ALIAS           VARCHAR2(32),
   POOL_DESC            VARCHAR2(256),
   POOL_EXTERNAL_IDENTIFIER VARCHAR2(64),
   POOL_STATUS          VARCHAR2(16),
   POOL_CATEGORY        VARCHAR2(32),
   POOL_EXCLUDE_LOAD_SCHEDULE NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_POOL primary key (POOL_ID)
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


alter table POOL
   add constraint AK_POOL unique (POOL_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: POOL_SUB_POOL                                         */
/*==============================================================*/


create table POOL_SUB_POOL  (
   POOL_ID              NUMBER(9)                        not null,
   SUB_POOL_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ALLOCATION_PCT       NUMBER(9,6),
   ENTRY_DATE           DATE,
   constraint PK_POOL_SUB_POOL primary key (POOL_ID, SUB_POOL_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: PORTFOLIO                                             */
/*==============================================================*/


create table PORTFOLIO  (
   PORTFOLIO_ID         NUMBER(9)                        not null,
   PORTFOLIO_NAME       VARCHAR2(64)                     not null,
   PORTFOLIO_ALIAS      VARCHAR2(32),
   PORTFOLIO_DESC       VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_PORTFOLIO primary key (PORTFOLIO_ID)
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


comment on table PORTFOLIO is
'Portfolios are used for grouping Service Points (see PORTFOLIO_SERVICE_POINT.)'
/


comment on column PORTFOLIO.PORTFOLIO_ID is
'Unique ID generated by OID'
/


comment on column PORTFOLIO.PORTFOLIO_NAME is
'Required unique identifier'
/


comment on column PORTFOLIO.PORTFOLIO_ALIAS is
'Optional alias'
/


comment on column PORTFOLIO.PORTFOLIO_DESC is
'Optional description'
/


alter table PORTFOLIO
   add constraint AK_PORTFOLIO unique (PORTFOLIO_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: PORTFOLIO_SERVICE_POINT                               */
/*==============================================================*/


create table PORTFOLIO_SERVICE_POINT  (
   PORTFOLIO_ID         NUMBER(9)                        not null,
   SERVICE_POINT_ID     NUMBER(9)                        not null,
   constraint PK_PORTFOLIO_SERVICE_POINT primary key (PORTFOLIO_ID, SERVICE_POINT_ID)
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


comment on table PORTFOLIO_SERVICE_POINT is
'Used for maintaining a many to many relationship between Portfolios and Service Points'
/


comment on column PORTFOLIO_SERVICE_POINT.PORTFOLIO_ID is
'Foreign key for PORTFOLIO table'
/


comment on column PORTFOLIO_SERVICE_POINT.SERVICE_POINT_ID is
'Foreign key for SERVICE_POINT table'
/


/*==============================================================*/
/* Table: POSITION_ANALYSIS_CANDIDATE                           */
/*==============================================================*/


create table POSITION_ANALYSIS_CANDIDATE  (
   EVALUATION_ID        NUMBER(9)                        not null,
   ACCOUNT_ID           NUMBER(9)                        not null,
   SERVICE_LOCATION_ID  NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   AGGREGATE_ID         NUMBER(9)                        not null,
   EDC_ID               NUMBER(9),
   PSE_ID               NUMBER(9),
   ESP_ID               NUMBER(9),
   POOL_ID              NUMBER(9),
   CALENDAR_ID          NUMBER(9),
   PRODUCT_ID           NUMBER(9),
   LOSS_FACTOR_ID       NUMBER(9),
   USAGE_FACTOR         NUMBER(10,6),
   ENROLLMENT           NUMBER(8),
   constraint PK_POSITION_ANALYSIS_CANDIDATE primary key (EVALUATION_ID, ACCOUNT_ID, SERVICE_LOCATION_ID, METER_ID, AGGREGATE_ID)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_ENROLLMENT                          */
/*==============================================================*/


create table POSITION_ANALYSIS_ENROLLMENT  (
   EVALUATION_ID        NUMBER(9)                        not null,
   PARTICIPANT_ID       NUMBER(9)                        not null,
   ENROLLMENT_MONTH     DATE                             not null,
   ENROLLMENT           NUMBER(8),
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_ENROLLMEN primary key (EVALUATION_ID, PARTICIPANT_ID, ENROLLMENT_MONTH)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_EVALUATION                          */
/*==============================================================*/


create table POSITION_ANALYSIS_EVALUATION  (
   EVALUATION_ID        NUMBER(9)                        not null,
   EVALUATION_NAME      VARCHAR2(32)                     not null,
   EVALUATION_ALIAS     VARCHAR2(32),
   EVALUATION_DESC      VARCHAR2(256),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   MARKET_PRICE_ID      NUMBER(9),
   LAST_RUN_DATE        DATE,
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_EVALUATIO primary key (EVALUATION_ID)
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


alter table POSITION_ANALYSIS_EVALUATION
   add constraint AK_POSITION_ANALYSIS_EVALUATIO unique (EVALUATION_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: POSITION_ANALYSIS_LOAD                                */
/*==============================================================*/


create table POSITION_ANALYSIS_LOAD  (
   EVALUATION_ID        NUMBER(9)                        not null,
   PARTICIPANT_ID       NUMBER(9)                        not null,
   DAY_TYPE             CHAR(1)                          not null,
   LOAD_DATE            DATE                             not null,
   LOAD_VAL             NUMBER(12,3),
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_LOAD primary key (EVALUATION_ID, PARTICIPANT_ID, DAY_TYPE, LOAD_DATE)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_PARTICIPANT                         */
/*==============================================================*/


create table POSITION_ANALYSIS_PARTICIPANT  (
   PARTICIPANT_ID       NUMBER(9)                        not null,
   EVALUATION_ID        NUMBER(9),
   PARTICIPANT_ENTITY_ID NUMBER(9),
   PARTICIPANT_TYPE     CHAR(1),
   PARTICIPANT_NAME     VARCHAR2(64),
   LOSS_FACTOR_ID       NUMBER(9),
   STATION_ID           NUMBER(9),
   CALENDAR_ID          NUMBER(9),
   PRODUCT_ID           NUMBER(9),
   CALENDAR_PROJECTION_TYPE CHAR(1),
   USAGE_FACTOR         NUMBER(8,4),
   USE_BILLING_DETERMINANTS NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_PARTICIPA primary key (PARTICIPANT_ID)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_REVENUE                             */
/*==============================================================*/


create table POSITION_ANALYSIS_REVENUE  (
   EVALUATION_ID        NUMBER(9)                        not null,
   PARTICIPANT_ID       NUMBER(9)                        not null,
   REVENUE_MONTH        DATE                             not null,
   REVENUE_ENERGY       NUMBER(12,4),
   REVENUE_DEMAND       NUMBER(12,4),
   REVENUE_AMOUNT       NUMBER(12,4),
   constraint PK_POSITION_ANALYSIS_REVENUE primary key (EVALUATION_ID, PARTICIPANT_ID, REVENUE_MONTH)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_SEGMENT                             */
/*==============================================================*/


create table POSITION_ANALYSIS_SEGMENT  (
   EVALUATION_ID        NUMBER(9)                        not null,
   SEGMENT_NAME         VARCHAR2(32)                     not null,
   SEGMENT_TYPE         CHAR(1)                          not null,
   SEGMENT_DAY_TYPE     CHAR(1)                          not null,
   SEGMENT_DATE         DATE                             not null,
   SEGMENT_ORDER        NUMBER(4),
   SEGMENT_QUANTITY     NUMBER(12,4),
   SEGMENT_COST         NUMBER(12,2),
   constraint PK_POSITION_ANALYSIS_SEGMENT primary key (EVALUATION_ID, SEGMENT_NAME, SEGMENT_TYPE, SEGMENT_DAY_TYPE, SEGMENT_DATE)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_SPOT_MARKET                         */
/*==============================================================*/


create table POSITION_ANALYSIS_SPOT_MARKET  (
   EVALUATION_ID        NUMBER(9)                        not null,
   MARKET_PRICE_ID      NUMBER(9)                        not null,
   PRICE_INTERVAL       CHAR(1)                          not null,
   PRICE_DATE           DATE                             not null,
   PRICE_VAL            NUMBER(8,2),
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_SPOT_MARK primary key (EVALUATION_ID, MARKET_PRICE_ID, PRICE_INTERVAL, PRICE_DATE)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_SUPPLY_BLOCK                        */
/*==============================================================*/


create table POSITION_ANALYSIS_SUPPLY_BLOCK  (
   EVALUATION_ID        NUMBER(9)                        not null,
   BLOCK_ORDER          NUMBER(2)                        not null,
   TEMPLATE_NAME        VARCHAR2(32),
   BLOCK_QUANTITY       NUMBER(12,4),
   BLOCK_PRICE          NUMBER(10,2),
   MARKET_PRICE_ID      NUMBER(9),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_SUPPLY_BL primary key (EVALUATION_ID, BLOCK_ORDER)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_TRANSACTION                         */
/*==============================================================*/


create table POSITION_ANALYSIS_TRANSACTION  (
   EVALUATION_ID        NUMBER(9)                        not null,
   TRANSACTION_ID       NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_TRANSACTI primary key (EVALUATION_ID, TRANSACTION_ID)
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


/*==============================================================*/
/* Table: POSITION_ANALYSIS_WEATHER                             */
/*==============================================================*/


create table POSITION_ANALYSIS_WEATHER  (
   EVALUATION_ID        NUMBER(9)                        not null,
   STATION_ID           NUMBER(9)                        not null,
   PARAMETER_ID         NUMBER(9)                        not null,
   PARAMETER_INTERVAL   CHAR(1)                          not null,
   PARAMETER_DATE       DATE                             not null,
   PARAMETER_VAL        NUMBER(8,2),
   ENTRY_DATE           DATE,
   constraint PK_POSITION_ANALYSIS_WEATHER primary key (EVALUATION_ID, STATION_ID, PARAMETER_ID, PARAMETER_INTERVAL, PARAMETER_DATE)
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


/*==============================================================*/
/* Table: PROCESS_LOG                                           */
/*==============================================================*/


create table PROCESS_LOG  (
   PROCESS_ID           NUMBER(12)                       not null,
   PROCESS_NAME         VARCHAR2(256)                    not null,
   PROCESS_TYPE         VARCHAR2(16)                     not null,
   USER_ID              NUMBER(9),
   PARENT_PROCESS_ID    NUMBER(12),
   PROCESS_START_TIME   DATE                             not null,
   PROCESS_STOP_TIME    DATE,
   PROCESS_STATUS       NUMBER(3),
   PROCESS_CODE         NUMBER(6),
   PROCESS_ERRM         VARCHAR2(4000),
   PROCESS_FINISH_TEXT  VARCHAR2(4000),
   PROGRESS_TOTALWORK   NUMBER                           not null,
   PROGRESS_UNITS       VARCHAR2(32),
   PROGRESS_SOFAR       NUMBER,
   PROGRESS_DESCRIPTION VARCHAR2(64),
   PROGRESS_LAST_UPDATE DATE,
   CAN_TERMINATE        NUMBER(1)                        not null,
   WAS_TERMINATED       NUMBER(1)                        not null,
   TERMINATED_BY_USER_ID NUMBER(9),
   NUM_FATALS           NUMBER(9),
   NUM_ERRORS           NUMBER(9),
   NUM_WARNINGS         NUMBER(9),
   NUM_NOTICES          NUMBER(9),
   NUM_INFOS            NUMBER(9),
   EXTERNAL_STATUS      VARCHAR2(32),
   NOTIFICATION_STATUS  VARCHAR2(64),
   NEXT_EVENT_CLEANUP   DATE,
   SCHEMA_NAME          VARCHAR2(30)                     not null,
   SESSION_PROGRAM      VARCHAR2(64),
   SESSION_MACHINE      VARCHAR2(64)                     not null,
   SESSION_OSUSER       VARCHAR2(64)                     not null,
   SESSION_SID          VARCHAR2(32)                     not null,
   SESSION_SERIALNUM    VARCHAR2(32)                     not null,
   UNIQUE_SESSION_CID   VARCHAR2(24)                     not null,
   JOB_NAME             VARCHAR2(30),
   constraint PK_PROCESS_LOG primary key (PROCESS_ID)
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


/*==============================================================*/
/* Index: PROCESS_LOG_IX01                                      */
/*==============================================================*/
create index PROCESS_LOG_IX01 on PROCESS_LOG (
   PROCESS_NAME ASC,
   PROCESS_START_TIME ASC,
   PROCESS_STOP_TIME ASC
)
tablespace NERO_INDEX
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
/


/*==============================================================*/
/* Index: PROCESS_LOG_IX02                                      */
/*==============================================================*/
create index PROCESS_LOG_IX02 on PROCESS_LOG (
   PROCESS_START_TIME ASC,
   PROCESS_STOP_TIME ASC
)
tablespace NERO_INDEX
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
/


/*==============================================================*/
/* Index: PROCESS_LOG_IX03                                      */
/*==============================================================*/
create index PROCESS_LOG_IX03 on PROCESS_LOG (
   NEXT_EVENT_CLEANUP ASC
)
tablespace NERO_INDEX
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
/

/*==============================================================*/
/* Index: FK_PARENT_PROCESS                                     */
/*==============================================================*/
create index FK_PARENT_PROCESS on PROCESS_LOG (
   PARENT_PROCESS_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_PROC_LOG_APP_USER                                  */
/*==============================================================*/
create index FK_PROC_LOG_APP_USER on PROCESS_LOG (
   TERMINATED_BY_USER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: PROCESS_LOG_EVENT                                     */
/*==============================================================*/


create table PROCESS_LOG_EVENT  (
   EVENT_ID             NUMBER(18)                       not null,
   PROCESS_ID           NUMBER(12)                       not null,
   EVENT_LEVEL          NUMBER(3)                        not null,
   EVENT_TIMESTAMP      TIMESTAMP(3)                     not null,
   PROCEDURE_NAME       VARCHAR2(64),
   STEP_NAME            VARCHAR2(64),
   SOURCE_NAME          VARCHAR2(512),
   SOURCE_DATE          DATE,
   SOURCE_DOMAIN_ID     NUMBER(9),
   SOURCE_ENTITY_ID     NUMBER(9),
   EVENT_ERRM           VARCHAR2(4000),
   EVENT_TEXT           VARCHAR2(4000),
   MESSAGE_ID           NUMBER(9),
   constraint PK_PROCESS_LOG_EVENT primary key (EVENT_ID)
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


/*==============================================================*/
/* Index: PROCESS_LOG_EVENT_IX01                                */
/*==============================================================*/
create index PROCESS_LOG_EVENT_IX01 on PROCESS_LOG_EVENT (
   PROCESS_ID ASC,
   EVENT_LEVEL ASC,
   EVENT_TIMESTAMP ASC
)
tablespace NERO_INDEX
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
/


/*==============================================================*/
/* Index: PROCESS_LOG_EVENT_IX02                                */
/*==============================================================*/
create index PROCESS_LOG_EVENT_IX02 on PROCESS_LOG_EVENT (
   SOURCE_DOMAIN_ID ASC,
   SOURCE_ENTITY_ID ASC,
   EVENT_TIMESTAMP ASC
)
tablespace NERO_INDEX
  storage
  (
    initial 64K
    next 64K
    pctincrease 0
  )
/


/*==============================================================*/
/* Index: PROCESS_LOG_EVENT_IX03                                */
/*==============================================================*/
create index PROCESS_LOG_EVENT_IX03 on PROCESS_LOG_EVENT (
   SOURCE_NAME ASC,
   EVENT_TIMESTAMP ASC
)
tablespace NERO_INDEX
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
/


/*==============================================================*/
/* Index: PROCESS_LOG_EVENT_IX04                                */
/*==============================================================*/
create index PROCESS_LOG_EVENT_IX04 on PROCESS_LOG_EVENT (
   MESSAGE_ID ASC
)
tablespace NERO_INDEX
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
/


/*==============================================================*/
/* Table: PROCESS_LOG_EVENT_DETAIL                              */
/*==============================================================*/


create table PROCESS_LOG_EVENT_DETAIL  (
   EVENT_ID             NUMBER(18)                       not null,
   DETAIL_TYPE          VARCHAR2(64)                     not null,
   CONTENT_TYPE         VARCHAR2(128)                    not null,
   CONTENTS             CLOB,
   constraint PK_PROCESS_LOG_EVENT_DETAIL primary key (EVENT_ID, DETAIL_TYPE)
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


/*==============================================================*/
/* Table: PROCESS_LOG_TARGET_PARAMETER                          */
/*==============================================================*/


create table PROCESS_LOG_TARGET_PARAMETER  (
   PROCESS_ID           NUMBER(12)                       not null,
   PARAMETER_NAME       VARCHAR2(32)                     not null,
   PARAMETER_VAL        VARCHAR2(4000),
   constraint PK_PROCESS_LOG_TARGET_PARAM primary key (PROCESS_ID, PARAMETER_NAME)
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


/*==============================================================*/
/* Table: PROCESS_LOG_TEMP_TRACE                                */
/*==============================================================*/


create global temporary table PROCESS_LOG_TEMP_TRACE  (
   EVENT_ID             NUMBER(18)                       not null,
   PROCESS_ID           NUMBER(12)                       not null,
   EVENT_LEVEL          NUMBER(3)                        not null,
   EVENT_TIMESTAMP      TIMESTAMP(3)                     not null,
   PROCEDURE_NAME       VARCHAR2(64),
   STEP_NAME            VARCHAR2(64),
   SOURCE_NAME          VARCHAR2(512),
   SOURCE_DATE          DATE,
   SOURCE_DOMAIN_ID     NUMBER(9),
   SOURCE_ENTITY_ID     NUMBER(9),
   EVENT_ERRM           VARCHAR2(4000),
   EVENT_TEXT           VARCHAR2(4000),
   MESSAGE_ID           NUMBER(9),
   constraint PK_PROCESS_LOG_TEMP_TRACE primary key (EVENT_ID)
)
on commit preserve rows
/


/*==============================================================*/
/* Index: PROCESS_LOG_TEMP_TRACE_IX01                           */
/*==============================================================*/
create index PROCESS_LOG_TEMP_TRACE_IX01 on PROCESS_LOG_TEMP_TRACE (
   PROCESS_ID ASC,
   EVENT_LEVEL ASC,
   EVENT_TIMESTAMP ASC
)
/


/*==============================================================*/
/* Table: PROCESS_LOG_TRACE                                     */
/*==============================================================*/


create table PROCESS_LOG_TRACE  (
   EVENT_ID             NUMBER(18)                       not null,
   PROCESS_ID           NUMBER(12)                       not null,
   EVENT_LEVEL          NUMBER(3)                        not null,
   EVENT_TIMESTAMP      TIMESTAMP(3)                     not null,
   PROCEDURE_NAME       VARCHAR2(64),
   STEP_NAME            VARCHAR2(64),
   SOURCE_NAME          VARCHAR2(512),
   SOURCE_DATE          DATE,
   SOURCE_DOMAIN_ID     NUMBER(9),
   SOURCE_ENTITY_ID     NUMBER(9),
   EVENT_ERRM           VARCHAR2(4000),
   EVENT_TEXT           VARCHAR2(4000),
   MESSAGE_ID           NUMBER(9),
   constraint PK_PROCESS_LOG_TRACE primary key (EVENT_ID)
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


/*==============================================================*/
/* Index: PROCESS_LOG_TRACE_IX01                                */
/*==============================================================*/
create index PROCESS_LOG_TRACE_IX01 on PROCESS_LOG_TRACE (
   PROCESS_ID ASC,
   EVENT_LEVEL ASC,
   EVENT_TIMESTAMP ASC
)
tablespace NERO_INDEX
  storage
  (
    initial 64K
    next 64K
    pctincrease 0
  )
/


/*==============================================================*/
/* Index: FK_MESSAGE_DEFINITION1                                */
/*==============================================================*/
create index FK_MESSAGE_DEFINITION1 on PROCESS_LOG_TRACE (
   MESSAGE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: PROCESS_STATUS                                        */
/*==============================================================*/


create table PROCESS_STATUS  (
   PROCESS_NAME         VARCHAR2(32)                     not null,
   PROCESS_DATE         DATE                             not null,
   PROCESS_AS_OF_DATE   DATE                             not null,
   PROCESS_STATE        VARCHAR2(32),
   PROCESS_SYSDATE      DATE,
   constraint PK_PROCESS_STATUS primary key (PROCESS_NAME, PROCESS_DATE, PROCESS_AS_OF_DATE)
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


/*==============================================================*/
/* Table: PRODUCT                                               */
/*==============================================================*/


create table PRODUCT  (
   PRODUCT_ID           NUMBER(9)                        not null,
   PRODUCT_NAME         VARCHAR2(32)                     not null,
   PRODUCT_ALIAS        VARCHAR2(32),
   PRODUCT_DESC         VARCHAR2(256),
   PRODUCT_EXTERNAL_IDENTIFIER VARCHAR2(32),
   PRODUCT_CATEGORY     VARCHAR2(32),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_PRODUCT primary key (PRODUCT_ID)
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


alter table PRODUCT
   add constraint AK_PRODUCT unique (PRODUCT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: PRODUCT_COMPONENT                                     */
/*==============================================================*/


create table PRODUCT_COMPONENT  (
   PRODUCT_ID           NUMBER(9)                        not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_PRODUCT_COMPONENT primary key (PRODUCT_ID, COMPONENT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: PROFILE_MONITOR                                       */
/*==============================================================*/


create table PROFILE_MONITOR  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   MONITOR_DATE         DATE                             not null,
   MONITOR_MAPE         NUMBER(8,2),
   ENTRY_DATE           DATE,
   constraint PK_PROFILE_MONITOR primary key (ACCOUNT_ID, METER_ID, MONITOR_DATE)
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

/*==============================================================*/
/* Table: PROGRAM                                               */
/*==============================================================*/
create table PROGRAM (
  PROGRAM_ID              NUMBER(9) not null,
  PROGRAM_NAME            VARCHAR2(64) not null,
  PROGRAM_ALIAS           VARCHAR2(32),
  PROGRAM_DESC            VARCHAR2(256),
  EXTERNAL_IDENTIFIER     VARCHAR2(64),
  PROGRAM_TYPE            VARCHAR2(128),
  PROGRAM_INTERVAL        VARCHAR2(16),
  CUSTOMER_TYPE           VARCHAR2(32),
  MAX_DURATION_HOUR       NUMBER(2),
  MAX_DURATION_MINUTE     NUMBER(2),
  MIN_OFF_TIME_HOUR       NUMBER(2),
  MIN_OFF_TIME_MINUTE     NUMBER(2),
  DEGREE_INCREASE         NUMBER(2),
  DEGREE_DECREASE         NUMBER(2),
  ALLOW_CUSTOMER_OVERRIDE NUMBER(1),
  DEFAULT_OPT_OUT_PCT      NUMBER(5,2),
  DEFAULT_OVERRIDE_PCT    NUMBER(5,2),
  USE_DEFAULT_OPT_OUT_OVERRIDE NUMBER(1),
  VALIDATION_METHOD       VARCHAR2(64),
  TRANSACTION_ID          NUMBER(9),
  COMPONENT_ID            NUMBER(9),
  SIGNAL_TYPE             VARCHAR2(32),
  ENTRY_DATE              DATE,
  constraint PK_PROGRAM primary key (PROGRAM_ID)
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

alter table PROGRAM
   add constraint AK_PROGRAM unique (PROGRAM_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_COMPONENT                                          */
/*==============================================================*/
CREATE INDEX FK_COMPONENT ON PROGRAM (
   COMPONENT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_TRANSACTION                                        */
/*==============================================================*/
CREATE INDEX FK_TRANSACTION ON PROGRAM (
   TRANSACTION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_BILL_DETERMINANT                              */
/*==============================================================*/
create table PROGRAM_BILL_DETERMINANT (
  BILL_DETERMINANT_ID NUMBER(12) not null,
  BILL_RESULT_ID NUMBER(12) not null,
  DETERMINANT_TYPE VARCHAR2(32) not null,
  DER_TYPE_ID NUMBER(9) not null,
  HAS_SUB_DAILY_DETAILS NUMBER(1),
  BILL_QUANTITY NUMBER(18,6),
  BILL_QUANTITY_UNIT VARCHAR2(32),
  BILL_RATE NUMBER(18,6),
  BILL_AMOUNT NUMBER(10,2),
  constraint PK_PROGRAM_BILL_DETERMINANT primary key (BILL_DETERMINANT_ID)
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

alter table PROGRAM_BILL_DETERMINANT
   add constraint AK_PROGRAM_BILL_DETERMINANT1 unique (BILL_RESULT_ID, DETERMINANT_TYPE, DER_TYPE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_PROGRAM_BILL_DETER_DER_TYPE                        */
/*==============================================================*/
CREATE INDEX FK_PROGRAM_BILL_DETER_DER_TYPE ON PROGRAM_BILL_DETERMINANT (
   DER_TYPE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_BILL_DETERMINANT_DTL                          */
/*==============================================================*/
create table PROGRAM_BILL_DETERMINANT_DTL (
  BILL_DETERMINANT_ID NUMBER(12) not null,
  EVENT_ID NUMBER(9),
  DER_ID NUMBER(9),
  DETERMINANT_DATE DATE not null,
  BILL_QUANTITY NUMBER(18,6),
  BILL_RATE NUMBER(18,6),
  BILL_AMOUNT NUMBER(10,2)
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

alter table PROGRAM_BILL_DETERMINANT_DTL
   add constraint AK_PROGRAM_BILL_DETERMNT_DTL1 unique (BILL_DETERMINANT_ID, EVENT_ID, DER_ID, DETERMINANT_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_PROG_BILL_DTR_DTL_DER                              */
/*==============================================================*/
CREATE INDEX FK_PROG_BILL_DTR_DTL_DER ON PROGRAM_BILL_DETERMINANT_DTL (
   DER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_PROG_BILL_DTR_DTL_DR_EVENT                         */
/*==============================================================*/
CREATE INDEX FK_PROG_BILL_DTR_DTL_DR_EVENT ON PROGRAM_BILL_DETERMINANT_DTL (
   EVENT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_BILL_RESULT                                   */
/*==============================================================*/
create table PROGRAM_BILL_RESULT (
  BILL_RESULT_ID NUMBER(12) not null,
  BILL_SUMMARY_ID NUMBER(12) not null,
  ACCOUNT_ID NUMBER(9) not null,
  SERVICE_LOCATION_ID NUMBER(9) not null,
  BILL_AMOUNT NUMBER(16,2),
  DETERMINANT_AMOUNT NUMBER(16,2),
  RESULT_STATUS VARCHAR2(32),
  PROCESS_ID NUMBER(12) not null,
  ENTRY_DATE DATE,
  constraint PK_PROGRAM_BILL_RESULT primary key (BILL_RESULT_ID)
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

alter table PROGRAM_BILL_RESULT
   add constraint AK_PROGRAM_BILL_RESULT_1 unique (BILL_SUMMARY_ID, ACCOUNT_ID, SERVICE_LOCATION_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_PROG_BILL_RESULT_ACCOUNT                           */
/*==============================================================*/
CREATE INDEX FK_PROG_BILL_RESULT_ACCOUNT ON PROGRAM_BILL_RESULT (
   ACCOUNT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_PROG_BILL_RESULT_PROC_LOG                          */
/*==============================================================*/
CREATE INDEX FK_PROG_BILL_RESULT_PROC_LOG ON PROGRAM_BILL_RESULT (
   PROCESS_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_PROG_BILL_RESULT_SERV_LOC                          */
/*==============================================================*/
CREATE INDEX FK_PROG_BILL_RESULT_SERV_LOC ON PROGRAM_BILL_RESULT (
   SERVICE_LOCATION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_BILL_SUMMARY                                  */
/*==============================================================*/
create table PROGRAM_BILL_SUMMARY (
  BILL_SUMMARY_ID NUMBER(12) not null,
  PROGRAM_ID NUMBER(9) not null,
  BILL_CYCLE_ID NUMBER(9) not null,
  BEGIN_DATE DATE not null,
  END_DATE DATE not null,
  BILL_MONTH DATE not null,
  BILL_AMOUNT NUMBER(16,2),
  NUM_SERVICE_LOCATIONS NUMBER(9) not null,
  NUM_WARNINGS NUMBER(9),
  NUM_ERRORS NUMBER(9),
  ENTRY_DATE DATE,
  constraint PK_PROGRAM_BILL_SUMMARY primary key (BILL_SUMMARY_ID)
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

alter table PROGRAM_BILL_SUMMARY
   add constraint AK_PROGRAM_BILL_SUMMARY_1 unique (PROGRAM_ID, BILL_CYCLE_ID, BEGIN_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table PROGRAM_BILL_SUMMARY
   add constraint AK_PROGRAM_BILL_SUMMARY_2 unique (PROGRAM_ID, BILL_CYCLE_ID, BILL_MONTH)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_PROG_BILL_SUMMARY_BILL_CYCL                        */
/*==============================================================*/
CREATE INDEX FK_PROG_BILL_SUMMARY_BILL_CYCL ON PROGRAM_BILL_SUMMARY (
   BILL_CYCLE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_DER_TYPE                                */
/*==============================================================*/
create table PROGRAM_DER_TYPE (
  PROGRAM_ID        NUMBER(9) not null,
  DER_TYPE_ID NUMBER(9) not null,
  ENTRY_DATE        DATE not null,
  constraint PK_PROGRAM_DER_TYPE primary key (PROGRAM_ID, DER_TYPE_ID)
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

/*==============================================================*/
/* INDEX: FK_PROG_DER_TYPE_DER_TYPE_ID                          */
/*==============================================================*/
CREATE INDEX FK_PROG_DER_TYPE_DER_TYPE_ID ON PROGRAM_DER_TYPE (
   DER_TYPE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_DER_PAYMENT                             */
/*==============================================================*/
create table PROGRAM_DER_PAYMENT (
  PROGRAM_ID        NUMBER(9) not null,
  PAYMENT_TYPE      VARCHAR2(64) not null,
  DER_TYPE_ID NUMBER(9),
  AMOUNT            NUMBER(12,6),
  ENTRY_DATE        DATE not null
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

alter table PROGRAM_DER_PAYMENT
  add constraint AK_PROG_DER_PAY_DER_TYPE_ID unique (PROGRAM_ID, DER_TYPE_ID, PAYMENT_TYPE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: PROGRAM_EVENT_HISTORY                                 */
/*==============================================================*/
create table PROGRAM_EVENT_HISTORY (
  PROGRAM_ID      NUMBER(9) not null,
  EVENT_ID        NUMBER(9) not null,
  TOTAL_SIGNALED  NUMBER(9),
  TOTAL_OVERRIDES NUMBER(9),
  TOTAL_OPT_OUTS   NUMBER(9),
  constraint PK_PROGRAM_EVENT_HISTORY primary key (PROGRAM_ID, EVENT_ID)
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

/*==============================================================*/
/* INDEX: FK_EVENT_HISTORY_EVENT_ID                             */
/*==============================================================*/
CREATE INDEX FK_EVENT_HISTORY_EVENT_ID ON PROGRAM_EVENT_HISTORY (
   EVENT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_EXECUTION_TYPE                                */
/*==============================================================*/
create table PROGRAM_EXECUTION_TYPE (
  PROGRAM_ID     NUMBER(9) not null,
  EXECUTION_TYPE VARCHAR2(32) not null,
  ENTRY_DATE     DATE not null,
  constraint PK_PROGRAM_EXEC_TYPE primary key (PROGRAM_ID, EXECUTION_TYPE)
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

/*==============================================================*/
/* Table: PROGRAM_LIMIT                                         */
/*==============================================================*/
create table PROGRAM_LIMIT (
  PROGRAM_ID        NUMBER(9)    not null,
  LIMIT_TYPE        VARCHAR2(64) not null,
  LIMIT_PERIOD      VARCHAR2(32) not null,
  TEMPLATE_ID       NUMBER(9)    not null,
  PERIOD_ID         NUMBER(9)    not null,
  MAX_LIMIT         NUMBER(5),
  PROGRAM_LIMIT_ID  NUMBER(9)    not null,
  ENTRY_DATE        DATE         not null,
  constraint PK_PROGRAM_LIMIT primary key (PROGRAM_ID, LIMIT_TYPE, LIMIT_PERIOD, TEMPLATE_ID, PERIOD_ID)
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

alter table PROGRAM_LIMIT
   add constraint AK_PROGRAM_LIMIT unique (PROGRAM_LIMIT_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_PROGRAM_LIMIT_PERIOD_ID                            */
/*==============================================================*/
CREATE INDEX FK_PROGRAM_LIMIT_PERIOD_ID ON PROGRAM_LIMIT (
   PERIOD_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_PROGRAM_LIMIT_TEMPLATE_ID                          */
/*==============================================================*/
CREATE INDEX FK_PROGRAM_LIMIT_TEMPLATE_ID ON PROGRAM_LIMIT (
   TEMPLATE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_LIMIT_HITS_USED                               */
/*==============================================================*/
create table PROGRAM_LIMIT_HITS_USED (
  PROGRAM_LIMIT_ID      NUMBER(9)       not null,
  SERVICE_LOCATION_ID   NUMBER(9)       not null,
  EVENT_ID              NUMBER(9)       not null,
  PERIOD_START_DATE     DATE            not null,
  PERIOD_STOP_DATE      DATE            not null,
  HITS_USED             NUMBER(5)       not null,
  constraint PK_PROGRAM_LIMIT_HITS_USED primary key (PROGRAM_LIMIT_ID, SERVICE_LOCATION_ID, EVENT_ID, PERIOD_START_DATE)
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

/*==============================================================*/
/* INDEX: FK_PROGRAM_LIMIT_HITS_EV                              */
/*==============================================================*/
CREATE INDEX FK_PROGRAM_LIMIT_HITS_EV ON PROGRAM_LIMIT_HITS_USED (
   EVENT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_PROGRAM_LIMIT_HITS_SL                              */
/*==============================================================*/
CREATE INDEX FK_PROGRAM_LIMIT_HITS_SL ON PROGRAM_LIMIT_HITS_USED (
   SERVICE_LOCATION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: PROGRAM_NOTIFICATION                                  */
/*==============================================================*/
create table PROGRAM_NOTIFICATION (
  PROGRAM_ID   NUMBER(9) not null,
  HOUR         NUMBER(2) not null,
  MINUTE       NUMBER(2) not null,
  METHOD       VARCHAR2(32) not null,
  MESSAGE_TEXT VARCHAR2(2000),
  ENTRY_DATE   DATE not null,
  constraint PK_PROGRAM_NOTIFICATION primary key (PROGRAM_ID, HOUR, MINUTE, METHOD)
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

/*==============================================================*/
/* Table: PROGRAM_PAYMENT                                       */
/*==============================================================*/
create table PROGRAM_PAYMENT(
  PROGRAM_ID NUMBER(9) not null,
  PAYMENT_TYPE VARCHAR2(64) NOT NULL,
  BEGIN_DATE DATE not null,
  END_DATE   DATE,
  AMOUNT     NUMBER(12,6),
  ENTRY_DATE DATE not null,
  constraint PK_PROGRAM_PAYMENT primary key (PROGRAM_ID, PAYMENT_TYPE, BEGIN_DATE)
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

/*==============================================================*/
/* Table: PROGRAM_REQUIRED_EQUIPMENT                            */
/*==============================================================*/
create table PROGRAM_REQUIRED_EQUIPMENT (
  PROGRAM_ID     NUMBER(9) not null,
  EQUIPMENT_TYPE VARCHAR2(64) not null,
  ENTRY_DATE     DATE not null,
  constraint PK_PROGRAM_REQ_EQUIP primary key (PROGRAM_ID, EQUIPMENT_TYPE)
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

/*==============================================================*/
/* Table: PROGRAM_THRESHOLD                           */
/*==============================================================*/
create table PROGRAM_THRESHOLD(
  PROGRAM_ID      NUMBER(9) not null,
  THRESHOLD_NAME  VARCHAR2(32) not null,
  MIN_VALUE       NUMBER(10,3) not null,
  MAX_VALUE       NUMBER(10,3),
  ENTRY_DATE     DATE not null,
  constraint PK_PROGRAM_THRESHOLD primary key (PROGRAM_ID, THRESHOLD_NAME, MIN_VALUE)
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

alter table PROGRAM_THRESHOLD
   add constraint AK_PROGRAM_THRESHOLD unique (PROGRAM_ID, MIN_VALUE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/



/*==============================================================*/
/* Table: PROGRESS_TRACKER_WORK                                 */
/*==============================================================*/


create global temporary table PROGRESS_TRACKER_WORK (
	PROCESS_ID     NUMBER(12)   not null,
	SO_FAR         NUMBER,
	TOTAL_WORK     NUMBER,
	PCT_COMPLETE   NUMBER,
	PROCESS_START  DATE         not null,
	PROCESS_STOP   DATE,
	STOP_IS_EST    NUMBER(1)    not null,
	TEST_TIMESTAMP TIMESTAMP(3) not null,
	SEQ            NUMBER(9)    not null
)
/



/*==============================================================*/
/* Table: PROJECTION_PATTERN                                    */
/*==============================================================*/


create table PROJECTION_PATTERN  (
   PROJECTION_ID        NUMBER(9)                        not null,
   PERIOD_ID            NUMBER(9)                        not null,
   PROJECTION_DATE      DATE                             not null,
   ENERGY               NUMBER(12,4),
   DEMAND               NUMBER(12,4),
   constraint PK_PROJECTION_PATTERN primary key (PROJECTION_ID, PERIOD_ID, PROJECTION_DATE)
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


/*==============================================================*/
/* Table: PROSPECT                                              */
/*==============================================================*/


create table PROSPECT  (
   SCREEN_ID            NUMBER(9)                        not null,
   EDC_NAME             VARCHAR2(64)                     not null,
   ACCOUNT_NUMBER       VARCHAR2(32)                     not null,
   EDC_TARIFF           VARCHAR2(16)                     not null,
   EDC_RATE_CLASS       VARCHAR2(16)                     not null,
   EDC_ID               NUMBER(9),
   PROFILE_CALENDAR_ID  NUMBER(9),
   COMPARE_PRODUCT_ID   NUMBER(9),
   PROSPECT_ID          NUMBER(9),
   constraint PK_PROSPECT primary key (SCREEN_ID, EDC_NAME, ACCOUNT_NUMBER, EDC_TARIFF, EDC_RATE_CLASS)
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


/*==============================================================*/
/* Table: PROSPECT_CONSUMPTION                                  */
/*==============================================================*/


create table PROSPECT_CONSUMPTION  (
   PROSPECT_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   PERIOD_CODE          VARCHAR2(16)                     not null,
   PERIOD_ID            NUMBER(9),
   TEMPLATE_ID          NUMBER(9),
   ENERGY               NUMBER(14,4),
   DEMAND               NUMBER(14,4),
   constraint PK_PROSPECT_CONSUMPTION primary key (PROSPECT_ID, BEGIN_DATE, END_DATE, PERIOD_CODE)
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


/*==============================================================*/
/* Table: PROSPECT_EVALUATION                                   */
/*==============================================================*/


create table PROSPECT_EVALUATION  (
   EVALUATION_ID        NUMBER(9)                        not null,
   PROSPECT_ID          NUMBER(9)                        not null,
   SERVICE_MONTH        DATE                             not null,
   PROSPECT_ENERGY      NUMBER(10,2),
   PROSPECT_DEMAND      NUMBER(10,2),
   PROSPECT_REVENUE     NUMBER(10,2),
   PROSPECT_COST        NUMBER(10,2),
   PROSPECT_COMPARE     NUMBER(10,2),
   constraint PK_PROSPECT_EVALUATION primary key (EVALUATION_ID, PROSPECT_ID, SERVICE_MONTH)
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


/*==============================================================*/
/* Table: PROSPECT_SCREEN                                       */
/*==============================================================*/


create table PROSPECT_SCREEN  (
   SCREEN_ID            NUMBER(9)                        not null,
   SCREEN_NAME          VARCHAR2(32)                     not null,
   SCREEN_ALIAS         VARCHAR2(32),
   SCREEN_DESC          VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_PROSPECT_SCREEN primary key (SCREEN_ID)
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


alter table PROSPECT_SCREEN
   add constraint AK_PROSPECT_SCREEN unique (SCREEN_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: PROSPECT_SCREEN_EVALUATION                            */
/*==============================================================*/


create table PROSPECT_SCREEN_EVALUATION  (
   SCREEN_ID            NUMBER(9)                        not null,
   OFFER_PRODUCT_ID     NUMBER(9)                        not null,
   COST_PRODUCT_ID      NUMBER(9)                        not null,
   COMPARE_PRODUCT_ID   NUMBER(9)                        not null,
   PROFILE_CALENDAR_ID  NUMBER(9)                        not null,
   PROSPECT_ID          NUMBER(9)                        not null,
   STATION_ID           NUMBER(9),
   LOSS_FACTOR_ID       NUMBER(9),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   EVALUATION_ID        NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_PROSPECT_SCREEN_EVALUATION primary key (SCREEN_ID, OFFER_PRODUCT_ID, COST_PRODUCT_ID, COMPARE_PRODUCT_ID, PROFILE_CALENDAR_ID, PROSPECT_ID)
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


/*==============================================================*/
/* Table: PROVIDER_SERVICE                                      */
/*==============================================================*/


create table PROVIDER_SERVICE  (
   PROVIDER_SERVICE_ID  NUMBER(9)                        not null,
   EDC_ID               NUMBER(9),
   ESP_ID               NUMBER(9),
   PSE_ID               NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_PROVIDER_SERVICE primary key (PROVIDER_SERVICE_ID)
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


alter table PROVIDER_SERVICE
   add constraint AK_PROVIDER_SERVICE unique (EDC_ID, ESP_ID, PSE_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: PROXY_DAY_METHOD                                      */
/*==============================================================*/


create table PROXY_DAY_METHOD (
   PROXY_DAY_METHOD_ID       NUMBER(9)     not null,
   PROXY_DAY_METHOD_NAME     VARCHAR2(32)  not null,
   PROXY_DAY_METHOD_ALIAS    VARCHAR2(32),
   PROXY_DAY_METHOD_DESC     VARCHAR2(512),
   TEMPLATE_ID               NUMBER(9)     not null,
   COMPARATIVE_VALUE	     CHAR(1)       not null,
   STATION_ID                NUMBER(9),
   PARAMETER_ID              NUMBER(9),
   SYSTEM_LOAD_ID            NUMBER(9),
   LOOKUP_TIME_HORIZON       NUMBER(3)     not null,
   TIME_HORIZON_SHIFT        NUMBER(3),
   LOOKUP_CANDIDATE_LIMIT    NUMBER(3),
   CANDIDATE_DELTA_THRESHOLD NUMBER,
   ENTRY_DATE                DATE,
   HOLIDAY_SET_ID			 NUMBER(9),
   constraint PK_PROXY_DAY_METHOD primary key (PROXY_DAY_METHOD_ID)
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


alter table PROXY_DAY_METHOD
   add constraint AK_PROXY_DAY_METHOD unique (PROXY_DAY_METHOD_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table PROXY_DAY_METHOD
	add constraint CK01_PROXY_DAY_METHOD check
		( (COMPARATIVE_VALUE = 'W' AND STATION_ID IS NOT NULL AND PARAMETER_ID IS NOT NULL AND SYSTEM_LOAD_ID IS NULL)
			OR
		  (COMPARATIVE_VALUE = 'S' AND STATION_ID IS NULL AND PARAMETER_ID IS NULL AND SYSTEM_LOAD_ID IS NOT NULL) )
/


/*==============================================================*/
/* Table: PROXY_DAY_METHOD_WORK                                 */
/*==============================================================*/


create global temporary table PROXY_DAY_METHOD_WORK (
   PROXY_DAY_METHOD_ID       NUMBER(9)     not null,
   HOLIDAY_SET_ID            NUMBER(9)     not null,
   COMPARATIVE_VALUE	     CHAR(1)       not null,
   STATION_ID                NUMBER(9),
   PARAMETER_ID              NUMBER(9),
   SYSTEM_LOAD_ID            NUMBER(9),
   LOOKUP_CANDIDATE_LIMIT    NUMBER(3),
   CANDIDATE_DELTA_THRESHOLD NUMBER,
   CANDIDATE_DAY             DATE          not null,
   CANDIDATE_DELTA           NUMBER,
   PDM_INTERVAL              VARCHAR2(16)  not null,
   constraint PK_PROXY_DAY_METHOD_WORK primary key (PROXY_DAY_METHOD_ID,HOLIDAY_SET_ID,CANDIDATE_DAY)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: PSE_CUSTOM_INVOICE                                    */
/*==============================================================*/


create table PSE_CUSTOM_INVOICE  (
   PSE_ID               NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_PSE_CUSTOM_INVOICE primary key (PSE_ID, BEGIN_DATE)
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



/*==============================================================*/
/* Table: PSE_INVOICE_RECIPIENT                                    */
/*==============================================================*/


create table PSE_INVOICE_RECIPIENT  (
   PSE_ID               NUMBER(9)   not null,
   CONTACT_GROUP_ID     NUMBER(9),
   CONTACT_ID           NUMBER(9),
   EMAIL_REC_TYPE       VARCHAR2(3) NOT NULL
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


alter table PSE_INVOICE_RECIPIENT
   add constraint AK_PSE_INVOICE_RECIPIENT unique (PSE_ID, CONTACT_GROUP_ID, CONTACT_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


alter table PSE_INVOICE_RECIPIENT
	add constraint CK01_PSE_INVOICE_RECIPIENT check
		(((CONTACT_GROUP_ID IS NULL AND CONTACT_ID IS NOT NULL) OR
		 (CONTACT_GROUP_ID IS NOT NULL AND CONTACT_ID IS NULL))
		  AND EMAIL_REC_TYPE IN ('TO','CC','BCC'))
/

/*==============================================================*/
/* Table: PSE_ESP                                               */
/*==============================================================*/


create table PSE_ESP  (
   PSE_ID               NUMBER(9)                        not null,
   ESP_ID               NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_PSE_ESP primary key (PSE_ID, ESP_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: PSE_PRE_SCHEDULE                                      */
/*==============================================================*/


create table PSE_PRE_SCHEDULE  (
   PSE_ID               NUMBER(9)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   AMOUNT               NUMBER(10,4),
   constraint PK_PSE_PRE_SCHEDULE primary key (PSE_ID, SCHEDULE_DATE)
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


/*==============================================================*/
/* Table: PURCHASING_SELLING_ENTITY                             */
/*==============================================================*/


create table PURCHASING_SELLING_ENTITY  (
   PSE_ID               NUMBER(9)                        not null,
   PSE_NAME             VARCHAR2(256)                     not null,
   PSE_ALIAS            VARCHAR2(256),
   PSE_DESC             VARCHAR2(4000),
   PSE_NERC_CODE        VARCHAR2(16),
   PSE_STATUS           VARCHAR2(16),
   PSE_DUNS_NUMBER      VARCHAR2(16),
   PSE_BANK             VARCHAR2(64),
   PSE_ACH_NUMBER       VARCHAR2(16),
   PSE_TYPE             VARCHAR2(16),
   PSE_EXTERNAL_IDENTIFIER VARCHAR2(32),
   PSE_IS_RETAIL_AGGREGATOR NUMBER(1),
   PSE_IS_BACKUP_GENERATION NUMBER(1),
   PSE_EXCLUDE_LOAD_SCHEDULE NUMBER(1),
   IS_BILLING_ENTITY    NUMBER(1),
   TIME_ZONE            VARCHAR2(16),
   STATEMENT_INTERVAL   VARCHAR2(32),
   INVOICE_INTERVAL     VARCHAR2(32),
   WEEK_BEGIN           VARCHAR2(32),
   INVOICE_LINE_ITEM_OPTION VARCHAR2(32),
   INVOICE_EMAIL_SUBJECT        VARCHAR2(512),
   INVOICE_EMAIL_PRIORITY       NUMBER(1),
   INVOICE_EMAIL_BODY           VARCHAR2(4000),
   INVOICE_EMAIL_BODY_MIME_TYPE VARCHAR2(64),
   SCHEDULE_NAME_PREFIX VARCHAR2(32),
   SCHEDULE_FORMAT   VARCHAR2(32),
   SCHEDULE_INTERVAL VARCHAR2(16),
   LOAD_ROUNDING_PREFERENCE VARCHAR2(32),
   LOSS_ROUNDING_PREFERENCE VARCHAR2(32),
   CREATE_TX_LOSS_SCHEDULE NUMBER(1),
   CREATE_DX_LOSS_SCHEDULE NUMBER(1),
   CREATE_UFE_SCHEDULE NUMBER(1),
   MINIMUM_SCHEDULE_AMT NUMBER(8,3),   
   ENTRY_DATE           DATE,
   constraint PK_PURCHASING_SELLING_ENTITY primary key (PSE_ID)
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


alter table PURCHASING_SELLING_ENTITY
   add constraint AK_PURCHASING_SELLING_ENTITY unique (PSE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: QUOTE_BILLING_DETERMINANT                             */
/*==============================================================*/


create table QUOTE_BILLING_DETERMINANT  (
   QUOTE_ID             NUMBER(9)                        not null,
   PERIOD_ID            NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   DEMAND               NUMBER(14,4),
   ENERGY               NUMBER(14,4),
   ENTRY_DATE           DATE,
   constraint PK_QUOTE_BILLING_DETERMINANT primary key (QUOTE_ID, PERIOD_ID, BEGIN_DATE, END_DATE)
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


/*==============================================================*/
/* Table: QUOTE_CALENDAR_PRODUCT                                */
/*==============================================================*/


create table QUOTE_CALENDAR_PRODUCT  (
   QUOTE_ID             NUMBER(9)                        not null,
   QUOTE_SCENARIO       VARCHAR2(32)                     not null,
   PROFILE_CALENDAR_ID  NUMBER(9),
   OFFER_PRODUCT_ID     NUMBER(9),
   COST_PRODUCT_ID      NUMBER(9),
   COMPARE_PRODUCT_ID   NUMBER(9),
   LOSS_FACTOR_ID       NUMBER(9),
   IS_SELECTED_OFFER    NUMBER(1),
   USE_BILLING_DETERMINANTS NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_QUOTE_CALENDAR_PRODUCT primary key (QUOTE_ID, QUOTE_SCENARIO)
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


/*==============================================================*/
/* Table: QUOTE_COMPONENT                                       */
/*==============================================================*/


create table QUOTE_COMPONENT  (
   QUOTE_ID             NUMBER(9)                        not null,
   QUOTE_SCENARIO       VARCHAR2(32)                     not null,
   PRODUCT_CATEGORY     CHAR(1)                          not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   CHARGE_ID            NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_QUOTE_COMPONENT primary key (QUOTE_ID, QUOTE_SCENARIO, PRODUCT_CATEGORY, PRODUCT_ID, COMPONENT_ID)
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


/*==============================================================*/
/* Table: QUOTE_COMPONENT_CHARGE                                */
/*==============================================================*/


create table QUOTE_COMPONENT_CHARGE  (
   CHARGE_ID            NUMBER(9)                        not null,
   CHARGE_DATE          DATE                             not null,
   PERIOD_ID            NUMBER(9)                        not null,
   CHARGE_ENERGY        NUMBER(10,2),
   CHARGE_DEMAND        NUMBER(10,2),
   CHARGE_RATE          NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(10,2),
   CHARGE_FACTOR        NUMBER(10,4),
   constraint PK_QUOTE_COMPONENT_CHARGE primary key (CHARGE_ID, CHARGE_DATE, PERIOD_ID)
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


/*==============================================================*/
/* Table: QUOTE_COMPONENT_POSITION                              */
/*==============================================================*/


create table QUOTE_COMPONENT_POSITION  (
   QUOTE_ID             NUMBER(9)                        not null,
   QUOTE_SCENARIO       VARCHAR2(32)                     not null,
   QUOTE_MONTH          DATE                             not null,
   PERIOD_ID            NUMBER(9)                        not null,
   QUOTE_ENERGY         NUMBER(14,4),
   QUOTE_DEMAND         NUMBER(14,4),
   QUOTE_REVENUE        NUMBER(10,2),
   QUOTE_COST           NUMBER(10,2),
   QUOTE_COMPARE        NUMBER(10,2),
   PRICING_SEASON       VARCHAR2(32),
   SEASONAL_COST_RATE   NUMBER(8,3),
   SEASONAL_COMPARE_RATE NUMBER(8,3),
   SEASONAL_REVENUE_RATE NUMBER(8,3),
   constraint PK_QUOTE_COMPONENT_POSITION primary key (QUOTE_ID, QUOTE_SCENARIO, QUOTE_MONTH, PERIOD_ID)
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


/*==============================================================*/
/* Table: QUOTE_PRICING_SEASON                                  */
/*==============================================================*/


create table QUOTE_PRICING_SEASON  (
   QUOTE_ID             NUMBER(9)                        not null,
   PRICING_MONTH        NUMBER(2)                        not null,
   PRICING_SEASON       VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_QUOTE_PRICING_SEASON primary key (QUOTE_ID, PRICING_MONTH)
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


/*==============================================================*/
/* Table: QUOTE_REQUEST                                         */
/*==============================================================*/


create table QUOTE_REQUEST  (
   QUOTE_ID             NUMBER(9)                        not null,
   QUOTE_NAME           VARCHAR2(32)                     not null,
   QUOTE_ALIAS          VARCHAR2(32),
   QUOTE_DESC           VARCHAR2(256),
   CAMPAIGN_NAME        VARCHAR2(32),
   CUSTOMER_NAME        VARCHAR2(32),
   CUSTOMER_TYPE        VARCHAR2(32),
   CUSTOMER_REP_NAME    VARCHAR2(32),
   EDC_ID               NUMBER(9),
   SERVICE_POINT_ID     NUMBER(9),
   CUSTOMER_CLASS       VARCHAR2(32),
   EDC_ACCOUNT_NUMBER   VARCHAR2(32),
   QUOTE_EFFECTIVE_DATE DATE,
   QUOTE_EXPIRATION_DATE DATE,
   SERVICE_BEGIN_DATE   DATE,
   SERVICE_END_DATE     DATE,
   QUOTE_TYPE           VARCHAR2(32),
   QUOTE_STATUS         VARCHAR2(32),
   STATION_ID           NUMBER(9),
   NUMBER_OF_CUSTOMERS  NUMBER(9),
   SIGNING_PROBABILITY  NUMBER(3),
   QUOTE_NOTES          VARCHAR2(2000),
   ENTRY_DATE           DATE,
   constraint PK_QUOTE_REQUEST primary key (QUOTE_ID)
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


alter table QUOTE_REQUEST
   add constraint AK_QUOTE_REQUEST unique (QUOTE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: REACTOR_PENDING                                       */
/*==============================================================*/

create table REACTOR_PENDING (
   TABLE_ID NUMBER(9),
   ZAU_ID NUMBER(9)
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_DATA
/

/*==============================================================*/
/* Table: REACTOR_PROCEDURE                                     */
/*==============================================================*/

create table REACTOR_PROCEDURE (
   REACTOR_PROCEDURE_ID    NUMBER(9)    NOT NULL,
   REACTOR_PROCEDURE_NAME  VARCHAR2(128) NOT NULL,
   REACTOR_PROCEDURE_ALIAS VARCHAR2(32),
   REACTOR_PROCEDURE_DESC  VARCHAR2(256),
   TABLE_ID                NUMBER(9) NOT NULL,
   PROCEDURE_NAME          VARCHAR2(64),
   JOB_THREAD_ID           NUMBER(9),
   JOB_COMMENTS            VARCHAR2(64),
   CALL_ORDER              NUMBER(3),
   SKIP_WHEN_FORMULA       VARCHAR2(4000),
   TIME_ZONE               VARCHAR2(8),
   IS_IMMEDIATE            NUMBER(1),
   IS_ENABLED	           NUMBER(1),
   ENTRY_DATE              DATE,
   constraint PK_REACTOR_PROCEDURE primary key (REACTOR_PROCEDURE_ID)
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

/*==============================================================*/
/* Index: REACTOR_PROCEDURE_IX01                                */
/*==============================================================*/
create index REACTOR_PROCEDURE_IX01 on REACTOR_PROCEDURE (
   TABLE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Index: REACTOR_PROCEDURE_IX02                                */
/*==============================================================*/
create index REACTOR_PROCEDURE_IX02 on REACTOR_PROCEDURE (
   JOB_THREAD_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Table: REACTOR_PROCEDURE_ENTITY_REF                          */
/*==============================================================*/
create table REACTOR_PROCEDURE_ENTITY_REF
(
  REACTOR_PROCEDURE_ID   NUMBER(9) not null,
  REFERENCE_NAME   VARCHAR2(32) not null,
  ENTITY_DOMAIN_ID NUMBER(9) not null,
  ENTITY_ID        NUMBER(9) not null,
  ENTRY_DATE       DATE,
  constraint PK_REACTOR_PROCEDURE_ENTITY_RE primary key (REACTOR_PROCEDURE_ID, REFERENCE_NAME)
  using index
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           next 64K
           pctincrease 0
       )
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

/*==============================================================*/
/* Index: REACTOR_PROCEDURE_ENT_REF_IX01                        */
/*==============================================================*/
create index REACTOR_PROCEDURE_ENT_REF_IX01 on REACTOR_PROCEDURE_ENTITY_REF (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* Table: REACTOR_PROCEDURE_INPUT                               */
/*==============================================================*/
create table REACTOR_PROCEDURE_INPUT (
   REACTOR_PROCEDURE_ID    NUMBER(9)    NOT NULL,
   ENTITY_DOMAIN_ID        NUMBER(9)    NOT NULL,
   ENTITY_TYPE             CHAR(1)      NOT NULL,
   ENTITY_ID               NUMBER(9)    NOT NULL,
   BEGIN_DATE              DATE         NOT NULL,
   END_DATE                DATE,
   constraint PK_REACTOR_PROCEDURE_INPUT primary key (REACTOR_PROCEDURE_ID, ENTITY_DOMAIN_ID, ENTITY_TYPE, ENTITY_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: REACTOR_PROCEDURE_INPUT_IX01                          */
/*==============================================================*/
create index REACTOR_PROCEDURE_INPUT_IX01 on REACTOR_PROCEDURE_INPUT (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

alter table REACTOR_PROCEDURE_INPUT
   add constraint CK01_REACTOR_PROCEDURE_INPUT check (ENTITY_TYPE IN ('E','R','G'))
/

/*==============================================================*/
/* Table: REACTOR_PROCEDURE_LIST_TEMP                           */
/*==============================================================*/
create global temporary table REACTOR_PROCEDURE_LIST_TEMP  (
   KEY_PROCEDURE_CALL   VARCHAR2(4000),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   PROCEDURE_CALL       VARCHAR2(4000),
   JOB_THREAD_ID        NUMBER(9),
   JOB_COMMENTS         VARCHAR2(64),
   CALL_ORDER           NUMBER(3),
   IS_IMMEDIATE            NUMBER(1)
)
/

/*==============================================================*/
/* Table: REACTOR_PROCEDURE_PARAMETER                           */
/*==============================================================*/
create table REACTOR_PROCEDURE_PARAMETER (
   REACTOR_PROCEDURE_ID    NUMBER(9)    NOT NULL,
   PARAMETER_NAME          VARCHAR2(32) NOT NULL,
   PARAMETER_TYPE          VARCHAR2(32) NOT NULL,
   PARAMETER_FORMULA       VARCHAR2(256),
   PARAMETER_ORDER         NUMBER(3),
   constraint PK_REACTOR_PROCEDURE_PARAMETER primary key (REACTOR_PROCEDURE_ID, PARAMETER_NAME)
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

alter table REACTOR_PROCEDURE_PARAMETER
   add constraint CK01_REACTOR_PROCEDURE_PARAM check (PARAMETER_TYPE IN ('Begin Date','End Date','Key','Non-Key','Lazy'))
/

/*==============================================================*/
/* Table: RETAIL_INVOICE                                        */
/*==============================================================*/
create table RETAIL_INVOICE (
	RETAIL_INVOICE_ID	NUMBER(12)		NOT NULL,
	RECIPIENT_PSE_ID	NUMBER(9)		NOT NULL,
	SENDER_PSE_ID		NUMBER(9)		NOT NULL,
	INVOICE_NUMBER		VARCHAR2(256)	NOT NULL,
	INVOICE_DATE		DATE			NOT NULL,
	PERIOD_BEGIN_DATE	DATE,
	PERIOD_END_DATE		DATE,
	PROCESS_ID			NUMBER(12),
	TIME_ZONE			VARCHAR2(32),	
	SERVICE_CODE		CHAR(1),
	STATEMENT_TYPE_ID	NUMBER(9),
	constraint PK_RETAIL_INVOICE primary key (RETAIL_INVOICE_ID)
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

alter table RETAIL_INVOICE
   	add constraint AK_RETAIL_INVOICE unique (RECIPIENT_PSE_ID, SENDER_PSE_ID, INVOICE_NUMBER)
	using index 
	tablespace NERO_INDEX
	storage
	(
		initial 64K
		next 64K
		pctincrease 0
	)
/

alter table RETAIL_INVOICE
   add constraint CK01_SERVICE_CODE check (SERVICE_CODE IS NULL OR SERVICE_CODE IN ('F','B','A'))
/

/*==============================================================*/
/* Table: RETAIL_INVOICE_LINE                                   */
/*==============================================================*/
create table RETAIL_INVOICE_LINE (
	RETAIL_INVOICE_LINE_ID	NUMBER(12)	NOT NULL,
	RETAIL_INVOICE_ID		NUMBER(9)	NOT NULL,
	ACCOUNT_ID				NUMBER(9)	NOT NULL,
	METER_ID				NUMBER(9)	NOT NULL,
	SERVICE_POINT_ID		NUMBER(9)	NOT NULL,	
	METER_TYPE				VARCHAR2(64),
	constraint PK_RETAIL_INVOICE_LINE primary key (RETAIL_INVOICE_LINE_ID)
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

alter table RETAIL_INVOICE_LINE
   	add constraint AK_RETAIL_INVOICE_LINE unique (RETAIL_INVOICE_ID, ACCOUNT_ID, METER_ID, SERVICE_POINT_ID)
	using index 
	tablespace NERO_INDEX
	storage
	(
		initial 64K
		next 64K
		pctincrease 0
	)
/


alter table RETAIL_INVOICE_LINE
	add constraint CK02_RETAIL_INVOICE_LINE check ((SERVICE_POINT_ID = 0 AND METER_TYPE IS NULL) 
		OR (SERVICE_POINT_ID <> 0 AND METER_TYPE IN ('Period','Interval','Either')))
/

alter table RETAIL_INVOICE_LINE
	add constraint CK03_RETAIL_INVOICE_LINE check (METER_ID = 0 
		OR (METER_ID <> 0 AND ACCOUNT_ID <> 0 AND SERVICE_POINT_ID = 0))
/

/*==============================================================*/
/* Table: RETAIL_INVOICE_COMPONENT                              */
/*==============================================================*/
create table RETAIL_INVOICE_COMPONENT (
	RETAIL_INVOICE_ID		NUMBER(9)	NOT NULL,
	PRODUCT_ID				NUMBER(9)	NOT NULL,
	COMPONENT_ID			NUMBER(9)	NOT NULL,
	PERIOD_ID				NUMBER(9),
	TOTAL_INTERNAL_QUANTITY	NUMBER,	
	TOTAL_INTERNAL_AMOUNT	NUMBER,	
	TOTAL_EXTERNAL_QUANTITY	NUMBER,	
	TOTAL_EXTERNAL_AMOUNT	NUMBER
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

alter table RETAIL_INVOICE_COMPONENT
   	add constraint AK_RETAIL_INVOICE_COMPONENT unique (RETAIL_INVOICE_ID, PRODUCT_ID, COMPONENT_ID, PERIOD_ID)
	using index 
	tablespace NERO_INDEX
	storage
	(
		initial 64K
		next 64K
		pctincrease 0
	)
/

/*==============================================================*/
/* Table: RETAIL_INVOICE_LINE_COMPONENT                         */
/*==============================================================*/
create table RETAIL_INVOICE_LINE_COMPONENT (
	RETAIL_INVOICE_LINE_COMP_ID		NUMBER(12)	NOT NULL,
	RETAIL_INVOICE_LINE_ID			NUMBER(12)	NOT NULL,
	PRODUCT_ID						NUMBER(9)	NOT NULL,
	COMPONENT_ID					NUMBER(9)	NOT NULL,
	PERIOD_ID						NUMBER(9),
	BEGIN_DATE						DATE		NOT NULL,
	END_DATE						DATE,
	CHARGE_STATE					NUMBER(1),
	INTERNAL_QUANTITY				NUMBER,
	INTERNAL_RATE					NUMBER,
	INTERNAL_AMOUNT					NUMBER,
	EXTERNAL_QUANTITY				NUMBER,
	EXTERNAL_RATE					NUMBER,
	EXTERNAL_AMOUNT					NUMBER,
	DETERMINANT_STATUS				NUMBER(1),
	CREDIT_REFERENCE_ID 			NUMBER(12),
	constraint PK_RETAIL_INVOICE_LINE_COMP primary key (RETAIL_INVOICE_LINE_COMP_ID)
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

PROMPT CREATE INDEX RET_INV_PRICING_RESULT_IX01...  
CREATE INDEX RETAIL_INVOICE_LINE_COMP_IX01
   ON RETAIL_INVOICE_LINE_COMPONENT (RETAIL_INVOICE_LINE_ID, 
                                     PRODUCT_ID, 
                                     COMPONENT_ID, 
                                     PERIOD_ID, 
                                     BEGIN_DATE, 
                                     END_DATE, 
                                     CHARGE_STATE) 
STORAGE(INITIAL     128K
	     NEXT        128K
		  PCTINCREASE   0)
TABLESPACE NERO_INDEX
/


alter table RETAIL_INVOICE_LINE_COMPONENT
	add constraint CK01_RETAIL_INVOICE_LINE_COMP check (CHARGE_STATE IN (0,1,2,3,4,7,8,9))
/

alter table RETAIL_INVOICE_LINE_COMPONENT
	add constraint CK02_RETAIL_INVOICE_LINE_COMP check (DETERMINANT_STATUS IS NULL OR DETERMINANT_STATUS IN (0,1,2))
/

/*==============================================================*/
/* Table: RETAIL_INVOICE_PRICING_RESULT                         */
/*==============================================================*/
create table RETAIL_INVOICE_PRICING_RESULT (
	RETAIL_INVOICE_LINE_COMP_ID		NUMBER(12)	NOT NULL,
	TAXED_PRODUCT_ID				NUMBER(9),
	TAXED_COMPONENT_ID				NUMBER(9),	
	CHILD_COMPONENT_ID				NUMBER(9),	
	PERIOD_ID						NUMBER(9),	
	BAND_TIER_NUMBER				NUMBER(3),	
	BEGIN_DATE						DATE		NOT NULL,
	END_DATE						DATE		NOT NULL,
	DATES_ARE_CUT					NUMBER(1)	NOT NULL,
	NUMBER_OF_INTERVALS				NUMBER		NOT NULL,
	BASE_QUANTITY					NUMBER,
	FACTOR							NUMBER,	
	QUANTITY						NUMBER,	
	RATE							NUMBER,	
	AMOUNT							NUMBER,
	FML_CHARGE_ID					NUMBER(12),	
	DETERMINANT_STATUS				NUMBER(1)
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

PROMPT CREATE INDEX RET_INV_PRICING_RESULT_IX01...
CREATE INDEX RET_INV_PRICING_RESULT_IX01 
   ON RETAIL_INVOICE_PRICING_RESULT (RETAIL_INVOICE_LINE_COMP_ID, 
                                     TAXED_PRODUCT_ID, 
                                     TAXED_COMPONENT_ID, 
                                     CHILD_COMPONENT_ID, 
                                     PERIOD_ID, 
                                     BAND_TIER_NUMBER, 
                                     BEGIN_DATE) 
STORAGE(INITIAL     128K
	     NEXT        128K
		  PCTINCREASE   0)
TABLESPACE NERO_INDEX 
/ 



alter table RETAIL_INVOICE_PRICING_RESULT
	add constraint CK01_RET_INV_PRICING_RESULT check (DETERMINANT_STATUS IN (0,1,2))
/


/*==============================================================*/
/* Table: ROML_ENTITY                                           */
/*==============================================================*/
create table ROML_ENTITY (
	ROML_ENTITY_NID 	NUMBER(9)	NOT NULL,
	ROML_ENTITY_NAME	VARCHAR2(50)	NOT NULL,
	TABLE_NAME 		VARCHAR2(30)	NOT NULL,
	TABLE_ALIAS 		VARCHAR2(30),
	IS_OBJECT 		NUMBER(1),
	IS_DATA 		NUMBER(1),
	SAVE_ID 		NUMBER(1),
	ID_COLUMN 		VARCHAR2(30),
	USE_SEQ 		VARCHAR2(30),
	EXPORT_ORDER 		NUMBER(3),
	DATE1_COL 		VARCHAR2(30),
	DATE2_COL 		VARCHAR2(30),
	constraint PK_ROML_ENTITY primary key (ROML_ENTITY_NID)
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


alter table ROML_ENTITY
	add constraint AK_ROML_ENTITY unique (ROML_ENTITY_NAME)
         using index
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           next 64K
           pctincrease 0
       )
/


/*==============================================================*/
/* Table: ROML_ENTITY_DEPENDS                                   */
/*==============================================================*/
create table ROML_ENTITY_DEPENDS (
	ROML_ENTITY_NID 	NUMBER(9)	NOT NULL,
	DEP_ROML_ENTITY_NID	NUMBER(9)	NOT NULL,
	RELATIONSHIP 		VARCHAR2(4000)	NOT NULL,
	constraint PK_ROML_ENTITY_DEPENDS primary key (ROML_ENTITY_NID, DEP_ROML_ENTITY_NID, RELATIONSHIP)
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


/*==============================================================*/
/* Table: ROML_COL_RULES_MAP                                    */
/*==============================================================*/
create table ROML_COL_RULES_MAP (
	COLUMN_NAME	VARCHAR2(30)	NOT NULL,
	RULE		VARCHAR2(4000)	NOT NULL,
	ROML_ENTITY_NID	NUMBER(9),
	TABLE_NAME	VARCHAR2(30)	NOT NULL
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/

alter table ROML_COL_RULES_MAP
	add constraint AK_ROML_COL_RULES_MAP unique (COLUMN_NAME, RULE, ROML_ENTITY_NID)
         using index
       tablespace NERO_INDEX
       storage
       (
           initial 64K
           next 64K
           pctincrease 0
       )
/


/*==============================================================*/
/* Table: ROML_PREFIX_MAP                                       */
/*==============================================================*/
create table ROML_PREFIX_MAP (
	COLUMN_PREFIX	VARCHAR2(30)	NOT NULL,
	TABLE_NAME	VARCHAR2(30)	NOT NULL,
	constraint PK_ROML_PREFIX_MAP primary key (COLUMN_PREFIX)
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


/*==============================================================*/
/* Table: ROML_WORK                                             */
/*==============================================================*/
create global temporary table ROML_WORK (
	ROML_ENTITY_NID	NUMBER(9)		NOT NULL,
	ENTITY_ID	NUMBER(9)		NOT NULL,
	TABLE_NAME 	VARCHAR2(30)	NOT NULL,
	TABLE_ALIAS 	VARCHAR2(30),
	ENTITY_NAME	VARCHAR2(4000)	NOT NULL,
	WORK_ORDER	NUMBER(6),
	constraint PK_ROML_WORK primary key (ROML_ENTITY_NID, ENTITY_ID)
)
/


/*==============================================================*/
/* Table: ROML_WORK_DEP                                         */
/*==============================================================*/
create global temporary table ROML_WORK_DEP (
	ROML_ENTITY_NID		NUMBER(9)		NOT NULL,
	ENTITY_ID		NUMBER(9)		NOT NULL,
	DEP_ROML_ENTITY_NID	NUMBER(9)		NOT NULL,
	DEP_ENTITY_ID		NUMBER(9)		NOT NULL,
	constraint PK_ROML_WORK_DEP primary key (ROML_ENTITY_NID, ENTITY_ID, DEP_ROML_ENTITY_NID, DEP_ENTITY_ID)
)
/


/*==============================================================*/
/* Table: RTO_ROLLUP                                            */
/*==============================================================*/


create table RTO_ROLLUP  (
   ROLLUP_NAME          VARCHAR2(32)                     not null,
   ROLLUP_ALIAS         VARCHAR2(32),
   ROLLUP_DESC          VARCHAR2(256),
   ROLLUP_ID            NUMBER(9),
   ROLLUP_CATEGORY      VARCHAR2(16),
   ROLLUP_LEVEL         NUMBER(2),
   ROLLUP_PARENT_ID     NUMBER(9),
   ROLLUP_CHILDREN      NUMBER(4),
   ENTRY_DATE           DATE,
   constraint PK_RTO_ROLLUP primary key (ROLLUP_NAME)
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


/*==============================================================*/
/* Table: RTO_ROLLUP_HIERARCHY                                  */
/*==============================================================*/


create table RTO_ROLLUP_HIERARCHY  (
   ROLLUP_CATEGORY      VARCHAR2(16)                     not null,
   ROLLUP_ID_1          NUMBER(9)                        not null,
   ROLLUP_1             VARCHAR2(32),
   ROLLUP_ID_2          NUMBER(9),
   ROLLUP_2             VARCHAR2(32),
   ROLLUP_ID_3          NUMBER(9),
   ROLLUP_3             VARCHAR2(32),
   ROLLUP_ID_4          NUMBER(9),
   ROLLUP_4             VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_RTO_ROLLUP_HIERARCHY primary key (ROLLUP_CATEGORY, ROLLUP_ID_1)
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


/*==============================================================*/
/* Table: RTO_WORK                                              */
/*==============================================================*/


create global temporary table RTO_WORK  (
   WORK_ID              NUMBER(9),
   WORK_SEQ             NUMBER(9),
   WORK_XID             NUMBER(9),
   WORK_DATE            DATE,
   WORK_DATA            VARCHAR2(4000),
   WORK_DATA2           VARCHAR2(4000)
)
on commit preserve rows
/


/*==============================================================*/
/* Index: RTO_WORK_IX01                                         */
/*==============================================================*/
create index RTO_WORK_IX01 on RTO_WORK (
   WORK_ID ASC,
   WORK_XID ASC,
   WORK_DATE ASC
)
/


/*==============================================================*/
/* Index: RTO_WORK_IX02                                         */
/*==============================================================*/
create index RTO_WORK_IX02 on RTO_WORK (
   WORK_ID ASC,
   WORK_DATE ASC,
   WORK_XID ASC
)
/

/*==============================================================*/
/* Table: RUN_BILL_CASE_TEMP                                    */
/*==============================================================*/

CREATE GLOBAL TEMPORARY TABLE RUN_BILL_CASE_TEMP
(BILL_CASE_ID 		NUMBER(9,0),
 PROCESS_ID			NUMBER(12,0),
 ACCOUNT_ID 		NUMBER(9,0),
 METER_ID			NUMBER(9,0),
 SERVICE_POINT_ID 	NUMBER(9,0),
 METER_TYPE			VARCHAR2(8),
 BEGIN_DATE 		DATE,
 END_DATE			DATE,
 PRODUCT_ID			NUMBER(9,0),
 COMPONENT_ID 		NUMBER(9,0),
 PERIOD_ID 			NUMBER(9,0),
 CHARGE_STATE 		NUMBER(1,0),
 INTERNAL_QUANTITY 	NUMBER,
 INTERNAL_RATE 		NUMBER,
 INTERNAL_AMOUNT 	NUMBER,
 EXTERNAL_QUANTITY 	NUMBER,
 EXTERNAL_RATE 		NUMBER,
 EXTERNAL_AMOUNT 	NUMBER,
 ENTITY_GROUP_ID1 	NUMBER(9,0),
 ENTITY_GROUP_ID2 	NUMBER(9,0),
 ESP_ID 			NUMBER(9,0),
 SENDER_PSE_ID 		NUMBER(9,0),
 RECIPIENT_PSE_ID 	NUMBER(9,0),
 CREDIT_REFERENCE_ID NUMBER(12)
)
/

CREATE INDEX IDX_RUN_BILL_CASE_TEMP1 on RUN_BILL_CASE_TEMP (bill_case_id, process_id, recipient_pse_id)
/

/*==============================================================*/
/* Table: SAMPLE_INTERVAL_USAGE                                 */
/*==============================================================*/


create table SAMPLE_INTERVAL_USAGE  (
   SAMPLE_ID            NUMBER(9)                        not null,
   SAMPLE_DATE          DATE                             not null,
   USAGE                NUMBER(10,4),
   constraint PK_SAMPLE_INTERVAL_USAGE primary key (SAMPLE_ID, SAMPLE_DATE)
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


/*==============================================================*/
/* Table: SAMPLE_USAGE                                          */
/*==============================================================*/


create table SAMPLE_USAGE  (
   SAMPLE_ID            NUMBER(9)                        not null,
   SAMPLE_NAME          VARCHAR2(32),
   SAMPLE_ALIAS         VARCHAR2(32),
   SAMPLE_DESC          VARCHAR2(256),
   METER_NUMBER         VARCHAR2(16),
   ACCOUNT_NUMBER       VARCHAR2(16),
   TIME_ZONE            CHAR(3),
   SAMPLE_INTERVAL      VARCHAR2(16),
   SAMPLE_TYPE          VARCHAR2(16),
   SAMPLE_UNIT          VARCHAR2(16),
   SAMPLE_IS_EXTERNAL   NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_SAMPLE_USAGE primary key (SAMPLE_ID)
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


/*==============================================================*/
/* Table: SCENARIO                                              */
/*==============================================================*/


create table SCENARIO  (
   SCENARIO_ID          NUMBER(9)                        not null,
   SCENARIO_NAME        VARCHAR2(32)                     not null,
   SCENARIO_ALIAS       VARCHAR2(32),
   SCENARIO_DESC        VARCHAR2(256),
   SCENARIO_CATEGORY    VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_SCENARIO primary key (SCENARIO_ID)
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


alter table SCENARIO
   add constraint AK_SCENARIO unique (SCENARIO_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SCHEDULE_COORDINATOR                                  */
/*==============================================================*/


create table SCHEDULE_COORDINATOR  (
   SC_ID                NUMBER(9)                        not null,
   SC_NAME              VARCHAR2(32)                     not null,
   SC_ALIAS             VARCHAR2(32),
   SC_DESC              VARCHAR2(256),
   SC_NERC_CODE         VARCHAR2(16),
   SC_DUNS_NUMBER       VARCHAR2(16),
   SC_STATUS            VARCHAR2(16),
   SC_EXTERNAL_IDENTIFIER VARCHAR2(64),
   SC_SCHEDULE_NAME_PREFIX VARCHAR2(32),
   SC_SCHEDULE_FORMAT   VARCHAR2(32),
   SC_SCHEDULE_INTERVAL VARCHAR2(16),
   SC_LOAD_ROUNDING_PREFERENCE VARCHAR2(32),
   SC_LOSS_ROUNDING_PREFERENCE VARCHAR2(32),
   SC_CREATE_TX_LOSS_SCHEDULE NUMBER(1),
   SC_CREATE_DX_LOSS_SCHEDULE NUMBER(1),
   SC_CREATE_UFE_SCHEDULE NUMBER(1),
   SC_MARKET_PRICE_ID   NUMBER(9),
   SC_MINIMUM_SCHEDULE_AMT NUMBER(8,3),
   ENTRY_DATE           DATE,
   constraint PK_SCHEDULE_COORDINATOR primary key (SC_ID)
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


alter table SCHEDULE_COORDINATOR
   add constraint AK_SCHEDULE_COORDINATOR unique (SC_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SCHEDULE_GROUP                                        */
/*==============================================================*/


create table SCHEDULE_GROUP  (
   SCHEDULE_GROUP_ID    NUMBER(9)                        not null,
   SCHEDULE_GROUP_NAME  VARCHAR2(32)                     not null,
   SCHEDULE_GROUP_ALIAS VARCHAR2(32),
   SCHEDULE_GROUP_DESC  VARCHAR2(256),
   SERVICE_ZONE_ID      NUMBER(9),
   SC_ID                NUMBER(9),
   SERVICE_POINT_ID     NUMBER(9),
   METER_TYPE           VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_SCHEDULE_GROUP primary key (SCHEDULE_GROUP_ID)
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


alter table SCHEDULE_GROUP
   add constraint AK_SCHEDULE_GROUP unique (SCHEDULE_GROUP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SCHEDULE_TEMPLATE                                     */
/*==============================================================*/


create table SCHEDULE_TEMPLATE  (
   TEMPLATE_NAME        VARCHAR2(16)                     not null,
   TEMPLATE_TYPE		NUMBER(1)						 not null,
   START_HOUR_END       NUMBER(2),
   STOP_HOUR_END        NUMBER(2),
   INTERIOR_PERIOD      NUMBER(1),
   DAY_OF_WEEK          CHAR(7),
   INCLUDE_HOLIDAYS     NUMBER(1),
   TEMPLATE_ORDER       NUMBER(3),
   constraint PK_SCHEDULE_TEMPLATE primary key (TEMPLATE_NAME)
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

comment on column SCHEDULE_TEMPLATE.TEMPLATE_TYPE
  is '0 - Special (eg: Local On Peak and Local Off Peak), 1- Persisted';
/


/*==============================================================*/
/* Table: SEASON                                                */
/*==============================================================*/


create table SEASON  (
   SEASON_ID            NUMBER(9)                        not null,
   SEASON_NAME          VARCHAR2(32)                     not null,
   SEASON_ALIAS         VARCHAR2(32),
   SEASON_DESC          VARCHAR2(256),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   ENTRY_DATE           DATE,
   constraint PK_SEASON primary key (SEASON_ID)
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


alter table SEASON
   add constraint AK_SEASON unique (SEASON_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SEASON_BREAKPOINT                                     */
/*==============================================================*/


create table SEASON_BREAKPOINT  (
   SEASON_ID            NUMBER(9)                        not null,
   PARAMETER_ID         NUMBER(9)                        not null,
   BREAKPOINT_ID        NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SEASON_BREAKPOINT primary key (SEASON_ID, PARAMETER_ID)
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


/*==============================================================*/
/* Table: SEASON_DATES                                          */
/*==============================================================*/


create table SEASON_DATES  (
   SEASON_ID            NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   CUT_BEGIN_DATE       DATE,
   CUT_END_DATE         DATE,
   ENTRY_DATE           DATE,
   constraint PK_SEASON_DATES primary key (SEASON_ID, BEGIN_DATE, END_DATE)
)
organization
    index
        tablespace NERO_DATA
        storage
        (
            initial 128K
            next 128K
            pctincrease 0
        )
/


comment on table SEASON_DATES is
'Dates for specific seasons covering a range of years before and after the generic dates in SEASON table'
/


/*==============================================================*/
/* Index: SEASON_DATES_IX01                                     */
/*==============================================================*/
create index SEASON_DATES_IX01 on SEASON_DATES (
   BEGIN_DATE ASC,
   END_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: SEASON_DATES_IX02                                     */
/*==============================================================*/
create index SEASON_DATES_IX02 on SEASON_DATES (
   CUT_BEGIN_DATE ASC,
   CUT_END_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: SEASON_TEMPLATE                                       */
/*==============================================================*/


create table SEASON_TEMPLATE  (
   TEMPLATE_ID          NUMBER(9)                        not null,
   SEASON_ID            NUMBER(9)                        not null,
   DAY_NAME             CHAR(3)                          not null,
   BEGIN_INTERVAL       VARCHAR2(8)                          not null,
   END_INTERVAL         VARCHAR2(8)                          not null,
   PERIOD_ID            NUMBER(9)                          not null,
   ENTRY_DATE           DATE,
   constraint PK_SEASON_TEMPLATE primary key (TEMPLATE_ID, SEASON_ID, DAY_NAME, BEGIN_INTERVAL)
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


/*==============================================================*/
/* Table: SERVICE                                               */
/*==============================================================*/


create table SERVICE  (
   SERVICE_ID           NUMBER(9)                        not null,
   MODEL_ID             NUMBER(1),
   SCENARIO_ID          NUMBER(9),
   AS_OF_DATE           DATE,
   PROVIDER_SERVICE_ID  NUMBER(9),
   ACCOUNT_SERVICE_ID   NUMBER(9),
   SERVICE_DELIVERY_ID  NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE primary key (SERVICE_ID)
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


alter table SERVICE
   add constraint AK_SERVICE unique (MODEL_ID, SCENARIO_ID, AS_OF_DATE, PROVIDER_SERVICE_ID, ACCOUNT_SERVICE_ID, SERVICE_DELIVERY_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: SERVICE_IX01                                          */
/*==============================================================*/
create index SERVICE_IX01 on SERVICE (
   MODEL_ID ASC,
   SCENARIO_ID ASC,
   AS_OF_DATE ASC,
   ACCOUNT_SERVICE_ID ASC,
   SERVICE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: SERVICE_IX02                                          */
/*==============================================================*/
create index SERVICE_IX02 on SERVICE (
   ACCOUNT_SERVICE_ID, SCENARIO_ID
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/



/*==============================================================*/
/* Table: SERVICE_AREA                                          */
/*==============================================================*/


create table SERVICE_AREA  (
   SERVICE_AREA_ID      NUMBER(9)                        not null,
   SERVICE_AREA_NAME    VARCHAR2(32)                     not null,
   SERVICE_AREA_ALIAS   VARCHAR2(32),
   SERVICE_AREA_DESC    VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_AREA primary key (SERVICE_AREA_ID)
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


alter table SERVICE_AREA
   add constraint AK_SERVICE_AREA unique (SERVICE_AREA_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SERVICE_CONSUMPTION                                   */
/*==============================================================*/


create table SERVICE_CONSUMPTION  (
   SERVICE_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   BILL_CODE            CHAR(1)                          not null,
   CONSUMPTION_CODE     CHAR(1)                          not null,
   RECEIVED_DATE        DATE                             not null,
   TEMPLATE_ID          NUMBER(9)                        not null,
   PERIOD_ID            NUMBER(9)                        not null,
   UNIT_OF_MEASUREMENT  VARCHAR2(16)						 not null,
   METER_TYPE           CHAR(1),
   METER_READING        VARCHAR(16),
   BILLED_USAGE         NUMBER(14,4),
   BILLED_DEMAND        NUMBER(14,4),
   METERED_USAGE        NUMBER(14,4),
   METERED_DEMAND       NUMBER(14,4),
   METERS_READ          NUMBER(8),
   CONVERSION_FACTOR    NUMBER(6,3),
   IGNORE_CONSUMPTION   NUMBER(1),
   BILL_CYCLE_MONTH     DATE,
   BILL_PROCESSED_DATE  DATE,
   READ_BEGIN_DATE      DATE,
   READ_END_DATE        DATE,
   CONSUMPTION_ID       NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_CONSUMPTION primary key (SERVICE_ID, BEGIN_DATE, END_DATE, BILL_CODE, CONSUMPTION_CODE, RECEIVED_DATE, TEMPLATE_ID, PERIOD_ID, UNIT_OF_MEASUREMENT)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


alter table SERVICE_CONSUMPTION
   add constraint AK_SERVICE_CONSUMPTION unique (CONSUMPTION_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: SERVICE_CONSUMPTION_ROLLBACK                          */
/*==============================================================*/


create table SERVICE_CONSUMPTION_ROLLBACK  (
   STATEMENT_TYPE       NUMBER(1)                        not null,
   STATEMENT_MONTH      DATE                             not null,
   ENTITY_ID            NUMBER(9)                        not null,
   CONSUMPTION_ID       NUMBER(9)                        not null,
   BILL_PROCESSED_DATE  DATE,
   constraint PK_SERVICE_CONSUMPTION_ROLLBAC primary key (STATEMENT_TYPE, STATEMENT_MONTH, ENTITY_ID, CONSUMPTION_ID)
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


/*==============================================================*/
/* Table: SERVICE_CONSUMPTION_VALIDATION                        */
/*==============================================================*/


create table SERVICE_CONSUMPTION_VALIDATION  (
   BILL_CYCLE_ID        NUMBER(9)                        not null,
   STATEMENT_MONTH      DATE                             not null,
   BILL_PARTIES         NUMBER(6),
   MISSING_CONSUMPTION  NUMBER(6),
   ZERO_CONSUMPTION     NUMBER(6),
   UNBILLED_CONSUMPTION NUMBER(6),
   AVERAGE_DAILY_QUANTITY NUMBER (14,4),
   END_DATE_DIST_1      NUMBER(6),
   END_DATE_DIST_2      NUMBER(6),
   END_DATE_DIST_3      NUMBER(6),
   END_USE_DAYS_DIST_1  NUMBER(6),
   END_USE_DAYS_DIST_2  NUMBER(6),
   END_USE_DAYS_DIST_3  NUMBER(6),
   CONSUMPTION_RECORDS  NUMBER(12),
   constraint PK_SERVICE_CONSUMPTION_VALIDAT primary key (BILL_CYCLE_ID, STATEMENT_MONTH)
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


/*==============================================================*/
/* Table: SERVICE_CONTRACT                                      */
/*==============================================================*/


create table SERVICE_CONTRACT  (
   CONTRACT_ID          NUMBER(9)                        not null,
   CONTRACT_NAME        VARCHAR2(32)                     not null,
   CONTRACT_ALIAS       VARCHAR2(32),
   CONTRACT_DESC        VARCHAR2(256),
   EXTERNAL_IDENTIFIER  VARCHAR(32),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   IS_ESTIMATED_END_DATE NUMBER(1),
   IS_EVERGREEN         NUMBER(1),
   IS_INTERRUPTIBLE     NUMBER(1),
   EXPECTED_RENEWAL_PCT NUMBER(3),
   NEXT_ACTION_DATE     DATE,
   NOTIFICATION_REQUIREMENTS VARCHAR2(1000),
   CURTAILMENT_ABILITY  VARCHAR2(1000),
   PENALTY_CLAUSES      VARCHAR2(1000),
   PRICING_MODEL        VARCHAR2(1000),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_CONTRACT primary key (CONTRACT_ID)
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


alter table SERVICE_CONTRACT
   add constraint AK_SERVICE_CONTRACT unique (CONTRACT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: ENTITY_NOTE                                 */
/*==============================================================*/


create table ENTITY_NOTE  (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   NOTE_TYPE            VARCHAR(16)                      not null,
   NOTE_DATE            DATE                             not null,
   NOTE_AUTHOR_ID       NUMBER(9)                        not null,
   NOTE_TEXT            VARCHAR(2000),
   constraint PK_ENTITY_NOTE primary key (ENTITY_DOMAIN_ID, ENTITY_ID, NOTE_TYPE, NOTE_DATE, NOTE_AUTHOR_ID)
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

alter table ENTITY_NOTE
  add constraint FK_ENTITY_NOTE_ENTITY_DOMAIN foreign key (ENTITY_DOMAIN_ID)
   references entity_domain (ENTITY_DOMAIN_ID)
/


/*==============================================================*/
/* Table: SERVICE_DELIVERY                                      */
/*==============================================================*/


create table SERVICE_DELIVERY  (
   SERVICE_DELIVERY_ID  NUMBER(9)                        not null,
   POOL_ID              NUMBER(9)                        not null,
   SERVICE_POINT_ID     NUMBER(9)                        not null,
   SERVICE_ZONE_ID      NUMBER(9),
   SCHEDULE_GROUP_ID    NUMBER(9)                        not null,
   SC_ID                NUMBER(9),
   SUPPLY_TYPE          CHAR(1)                          not null,
   IS_BUG               NUMBER(1)                        not null,
   IS_WHOLESALE         NUMBER(1)                        not null,
   IS_AGGREGATE_POOL    NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_DELIVERY primary key (SERVICE_DELIVERY_ID)
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


alter table SERVICE_DELIVERY
   add constraint AK_SERVICE_DELIVERY unique (POOL_ID, SERVICE_POINT_ID, SERVICE_ZONE_ID, SCHEDULE_GROUP_ID, SC_ID, SUPPLY_TYPE, IS_BUG, IS_WHOLESALE, IS_AGGREGATE_POOL)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SERVICE_LOAD                                          */
/*==============================================================*/


create table SERVICE_LOAD  (
   SERVICE_ID           NUMBER(9)                        not null,
   SERVICE_CODE         CHAR(1)                          not null,
   LOAD_DATE            DATE                             not null,
   LOAD_CODE            CHAR(1)                          not null,
   LOAD_VAL             NUMBER(14,4),
   TX_LOSS_VAL          NUMBER(10,4),
   DX_LOSS_VAL          NUMBER(10,4),
   UE_LOSS_VAL          NUMBER(10,4),
   constraint PK_SERVICE_LOAD primary key (SERVICE_ID, SERVICE_CODE, LOAD_DATE, LOAD_CODE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: SERVICE_LOAD_TYPE                                     */
/*==============================================================*/


create table SERVICE_LOAD_TYPE  (
   SERVICE_LOAD_TYPE_NAME VARCHAR2(32),
   SERVICE_LOAD_TYPE_CODE CHAR(1),
   SERVICE_LOAD_TYPE_MODULE CHAR(1),
   SERVICE_LOAD_TYPE_RESERVED NUMBER(1),
   SERVICE_LOAD_TYPE_ORDER NUMBER(1)
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: SERVICE_LOCATION                                      */
/*==============================================================*/

create table SERVICE_LOCATION  (
   SERVICE_LOCATION_ID  NUMBER(9)                        not null,
   SERVICE_LOCATION_NAME VARCHAR2(32)                     not null,
   SERVICE_LOCATION_ALIAS VARCHAR2(32),
   SERVICE_LOCATION_DESC VARCHAR2(256),
   LATITUDE             VARCHAR2(8),
   LONGITUDE            VARCHAR2(8),
   TIME_ZONE            VARCHAR2(16),
   EXTERNAL_IDENTIFIER  VARCHAR2(64),
   IS_EXTERNAL_BILLED_USAGE NUMBER(1),
   IS_METER_ALLOCATION  NUMBER(1),
   SERVICE_POINT_ID     NUMBER(9),
   WEATHER_STATION_ID   NUMBER(9),
   BUSINESS_ROLLUP_ID   NUMBER(9),
   GEOGRAPHIC_ROLLUP_ID NUMBER(9),
   SQUARE_FOOTAGE       NUMBER(7),
   ANNUAL_CONSUMPTION   NUMBER(16,4),
   SUMMER_CONSUMPTION   NUMBER(15,4),
   SERVICE_ZONE_ID      NUMBER(9),
   SUB_STATION_ID       NUMBER(9),
   FEEDER_ID            NUMBER(9),
   FEEDER_SEGMENT_ID    NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_LOCATION primary key (SERVICE_LOCATION_ID)
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


/*==============================================================*/
/* Index: SERVICE_LOCATION_IX01                                 */
/*==============================================================*/
create index SERVICE_LOCATION_IX01 on SERVICE_LOCATION (
   SERVICE_LOCATION_NAME ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/

/*==============================================================*/
/* INDEX: FK_SERVICE_LOCATION_FEEDER                            */
/*==============================================================*/
CREATE INDEX FK_SERVICE_LOCATION_FEEDER ON SERVICE_LOCATION (
   FEEDER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_SERVICE_LOCATION_FEEDER_SEG                        */
/*==============================================================*/
CREATE INDEX FK_SERVICE_LOCATION_FEEDER_SEG ON SERVICE_LOCATION (
   FEEDER_SEGMENT_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_SERVICE_LOCATION_SUB_STAT                          */
/*==============================================================*/
CREATE INDEX FK_SERVICE_LOCATION_SUB_STAT ON SERVICE_LOCATION (
   SUB_STATION_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_SERVICE_LOCATION_ZONE                              */
/*==============================================================*/
CREATE INDEX FK_SERVICE_LOCATION_ZONE ON SERVICE_LOCATION (
   SERVICE_ZONE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: SERVICE_LOCATION_METER                                */
/*==============================================================*/


create table SERVICE_LOCATION_METER  (
   SERVICE_LOCATION_ID  NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   IS_ESTIMATED_END_DATE NUMBER(1),
   EDC_IDENTIFIER       VARCHAR2(32),
   ESP_IDENTIFIER       VARCHAR2(32),
   NEXT_ACTION_DATE     DATE,
   EDC_RATE_CLASS       VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_LOCATION_METER primary key (SERVICE_LOCATION_ID, METER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: SERVICE_LOCATION_MRSP                                 */
/*==============================================================*/


create table SERVICE_LOCATION_MRSP  (
   SERVICE_LOCATION_ID  NUMBER(9)                        not null,
   MRSP_ID              NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   MRSP_ACCOUNT_NUMBER  VARCHAR2(32),
   METER_READ_CYCLE     VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_LOCATION_MRSP primary key (SERVICE_LOCATION_ID, MRSP_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: SERVICE_LOCATION_PROGRAM                              */
/*==============================================================*/


create table SERVICE_LOCATION_PROGRAM  (
   SERVICE_LOCATION_ID  NUMBER(9)                        not null,
   PROGRAM_ID           NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   AUTO_ENROLL          NUMBER(1),
   constraint PK_SERVICE_LOCATION_PROGRAM primary key (SERVICE_LOCATION_ID, PROGRAM_ID, BEGIN_DATE)
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


/*==============================================================*/
/* INDEX: FK_SRVC_LOCTN_PRGRM_PRGRM                             */
/*==============================================================*/
CREATE INDEX FK_SRVC_LOCTN_PRGRM_PRGRM ON SERVICE_LOCATION_PROGRAM (
   PROGRAM_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: SERVICE_OBLIGATION                                    */
/*==============================================================*/


create table SERVICE_OBLIGATION  (
   SERVICE_OBLIGATION_ID NUMBER(9)                        not null,
   MODEL_ID             NUMBER(1),
   SCENARIO_ID          NUMBER(9),
   AS_OF_DATE           DATE,
   PROVIDER_SERVICE_ID  NUMBER(9),
   SERVICE_DELIVERY_ID  NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_OBLIGATION primary key (SERVICE_OBLIGATION_ID)
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


alter table SERVICE_OBLIGATION
   add constraint AK_SERVICE_OBLIGATION unique (MODEL_ID, SCENARIO_ID, AS_OF_DATE, PROVIDER_SERVICE_ID, SERVICE_DELIVERY_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SERVICE_OBLIGATION_LOAD                               */
/*==============================================================*/


create table SERVICE_OBLIGATION_LOAD  (
   SERVICE_OBLIGATION_ID NUMBER(9)                        not null,
   SERVICE_CODE         CHAR(1)                          not null,
   LOAD_DATE            DATE                             not null,
   LOAD_CODE            CHAR(1)                          not null,
   LOAD_VAL             NUMBER(14,4),
   TX_LOSS_VAL          NUMBER(10,4),
   DX_LOSS_VAL          NUMBER(10,4),
   AGG_LOAD_VAL         NUMBER(14,4),
   AGG_TX_LOSS_VAL      NUMBER(10,4),
   AGG_DX_LOSS_VAL      NUMBER(10,4),
   UFE_LOAD_VAL         NUMBER(14,4),
   constraint PK_SERVICE_OBLIGATION_LOAD primary key (SERVICE_OBLIGATION_ID, SERVICE_CODE, LOAD_DATE, LOAD_CODE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/

/*==============================================================*/
/* Table: SERVICE_OBLIGATION_ANC_SVC                            */
/*==============================================================*/


create table SERVICE_OBLIGATION_ANC_SVC  (
   SERVICE_OBLIGATION_ID   NUMBER(9)                        not null,
   ANCILLARY_SERVICE_ID    NUMBER(9)                        not null,
   ANCILLARY_SERVICE_DATE  DATE                             not null,
   ANCILLARY_SERVICE_VALUE NUMBER(10,4),
   constraint PK_SERVICE_OBLIGATION_ANC_SVC primary key (SERVICE_OBLIGATION_ID, ANCILLARY_SERVICE_ID, ANCILLARY_SERVICE_DATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/

/*==============================================================*/
/* Table: SERVICE_POINT                                         */
/*==============================================================*/


create table SERVICE_POINT  (
   SERVICE_POINT_ID     NUMBER(9)                        not null,
   SERVICE_POINT_NAME   VARCHAR2(32)                     not null,
   SERVICE_POINT_ALIAS  VARCHAR2(32),
   SERVICE_POINT_DESC   VARCHAR2(256),
   SERVICE_POINT_TYPE   VARCHAR2(24),
   TP_ID                NUMBER(9),
   CA_ID                NUMBER(9),
   EDC_ID               NUMBER(9),
   ROLLUP_ID            NUMBER(9),
   SERVICE_REGION_ID    NUMBER(9),
   SERVICE_AREA_ID      NUMBER(9),
   SERVICE_ZONE_ID      NUMBER(9),
   TIME_ZONE            VARCHAR2(16),
   LATITUDE             VARCHAR2(8),
   LONGITUDE            VARCHAR2(8),
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   IS_INTERCONNECT      NUMBER(1),
   NODE_TYPE            VARCHAR2(32),
   SERVICE_POINT_NERC_CODE VARCHAR2(16),
   PIPELINE_ID          NUMBER(9),
   MILE_MARKER          NUMBER(16,3),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_POINT primary key (SERVICE_POINT_ID)
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


alter table SERVICE_POINT
   add constraint AK_SERVICE_POINT unique (SERVICE_POINT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SERVICE_POINT_AGGREGATE                               */
/*==============================================================*/


create table SERVICE_POINT_AGGREGATE  (
   SERVICE_POINT_ID     NUMBER(9)                        not null,
   SUB_SERVICE_POINT_ID NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ALLOCATION_PCT       NUMBER(9,6),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_POINT_AGGREGATE primary key (SERVICE_POINT_ID, SUB_SERVICE_POINT_ID, BEGIN_DATE)
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


comment on table SERVICE_POINT_AGGREGATE is
'Service Points can be Aggregate Service Points with Sub Service Points under them.'
/


comment on column SERVICE_POINT_AGGREGATE.SERVICE_POINT_ID is
'Aggregate Service Point ID'
/


comment on column SERVICE_POINT_AGGREGATE.SUB_SERVICE_POINT_ID is
'Child Service Point ID'
/


comment on column SERVICE_POINT_AGGREGATE.BEGIN_DATE is
'Beginning of temporal relationship between Aggregate and Child Service Point'
/


comment on column SERVICE_POINT_AGGREGATE.END_DATE is
'End of temporal relationship between Aggregate and Child Service Point'
/


comment on column SERVICE_POINT_AGGREGATE.ALLOCATION_PCT is
'Percentage of Aggregate Service Point that is allocated to the Sub Service Point'
/


/*==============================================================*/
/* Table: SERVICE_POSITION_CHARGE                               */
/*==============================================================*/


create table SERVICE_POSITION_CHARGE  (
   SERVICE_ID           NUMBER(9)                        not null,
   POSITION_TYPE        NUMBER(1)                        not null,
   CHARGE_DATE          DATE                             not null,
   PRODUCT_TYPE         CHAR(1)                          not null,
   CUSTOMER_ID          NUMBER(9)                        not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   PERIOD_ID            NUMBER(9)                        not null,
   BAND_NUMBER          NUMBER(1)                        not null,
   CHARGE_QUANTITY      NUMBER(12,2),
   CHARGE_RATE          NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   IS_DETERMINANT       NUMBER(1),
   constraint PK_SERVICE_POSITION_CHARGE primary key (SERVICE_ID, POSITION_TYPE, CHARGE_DATE, PRODUCT_TYPE, CUSTOMER_ID, PRODUCT_ID, COMPONENT_ID, PERIOD_ID, BAND_NUMBER)
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


/*==============================================================*/
/* Table: SERVICE_REGION                                        */
/*==============================================================*/


create table SERVICE_REGION  (
   SERVICE_REGION_ID    NUMBER(9)                        not null,
   SERVICE_REGION_NAME  VARCHAR2(32)                     not null,
   SERVICE_REGION_ALIAS VARCHAR2(32),
   SERVICE_REGION_DESC  VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_REGION primary key (SERVICE_REGION_ID)
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


alter table SERVICE_REGION
   add constraint AK_SERVICE_REGION unique (SERVICE_REGION_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SERVICE_STATE                                         */
/*==============================================================*/


create table SERVICE_STATE  (
   SERVICE_ID           NUMBER(9)                        not null,
   SERVICE_CODE         CHAR(1)                          not null,
   SERVICE_DATE         DATE                             not null,
   BASIS_AS_OF_DATE     DATE,
   IS_UFE_PARTICIPANT   NUMBER(1),
   SERVICE_ACCOUNTS     NUMBER(8),
   METER_TYPE           CHAR(1),
   IS_EXTERNAL_FORECAST NUMBER(1),
   IS_AGGREGATE_ACCOUNT NUMBER(1),
   IS_AGGREGATE_POOL    NUMBER(1),
   PROFILE_TYPE         CHAR(1),
   PROFILE_SOURCE_DATE  DATE,
   PROFILE_ZERO_COUNT   NUMBER(3),
   PROXY_DAY_METHOD_ID  NUMBER(9),
   USAGE_FACTOR         NUMBER(14,6),
   SERVICE_INTERVALS    NUMBER(3),
   HAS_DETAILS          NUMBER(1),
   constraint PK_SERVICE_STATE primary key (SERVICE_ID, SERVICE_CODE, SERVICE_DATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/

/*==============================================================*/
/* Index: SERVICE_STATE_IX01                                    */
/*==============================================================*/
create index SERVICE_STATE_IX01 on SERVICE_STATE (
   SERVICE_CODE, HAS_DETAILS, SERVICE_DATE, SERVICE_ID
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/



/*==============================================================*/
/* Table: SERVICE_VALIDATION_BEST_FIT                           */
/*==============================================================*/


create table SERVICE_VALIDATION_BEST_FIT  (
   SERVICE_ID           NUMBER(9)                        not null,
   SERVICE_DATE         DATE                             not null,
   TOTAL_VAR            NUMBER(14,4),
   TOTAL_PCT            NUMBER(8,4),
   TOTAL_RULE           NUMBER(1),
   TOTAL_METHOD         CHAR(1),
   PEAK_VAR             NUMBER(14,4),
   PEAK_PCT             NUMBER(8,4),
   PEAK_RULE            NUMBER(1),
   PEAK_METHOD          CHAR(1),
   HOUR_VAR             NUMBER(14,4),
   HOUR_PCT             NUMBER(8,4),
   HOUR_RULE            NUMBER(1),
   HOUR_METHOD          CHAR(1),
   constraint PK_SERVICE_VALIDATION_BEST_FIT primary key (SERVICE_ID, SERVICE_DATE)
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


/*==============================================================*/
/* Table: SERVICE_VALIDATION_LOAD                               */
/*==============================================================*/


create table SERVICE_VALIDATION_LOAD  (
   SERVICE_ID           NUMBER(9)                        not null,
   LOAD_DATE            DATE                             not null,
   LOAD_VAL             NUMBER(14,4),
   HISTORICAL_VAL       NUMBER(14,4),
   AVERAGE_VAL          NUMBER(14,4),
   MOST_RECENT_VAL      NUMBER(14,4),
   constraint PK_SERVICE_VALIDATION primary key (SERVICE_ID, LOAD_DATE)
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


/*==============================================================*/
/* Table: SERVICE_ZONE                                          */
/*==============================================================*/


create table SERVICE_ZONE  (
   SERVICE_ZONE_ID      NUMBER(9)                        not null,
   SERVICE_ZONE_NAME    VARCHAR2(32)                     not null,
   SERVICE_ZONE_ALIAS   VARCHAR2(32),
   SERVICE_ZONE_DESC    VARCHAR2(256),
   EXTERNAL_IDENTIFIER 		VARCHAR2(64), 
   MARKET_PRICE_ID      NUMBER(9),
   CONTROL_AREA_ID	   		NUMBER(9),
   TIME_ZONE            VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_SERVICE_ZONE primary key (SERVICE_ZONE_ID)
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


alter table SERVICE_ZONE
   add constraint AK_SERVICE_ZONE unique (SERVICE_ZONE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_SERVICE_ZONE_CONTROL_AREA                          */
/*==============================================================*/
CREATE INDEX FK_SERVICE_ZONE_CONTROL_AREA ON SERVICE_ZONE (
   CONTROL_AREA_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: SETTLEMENT_TYPE                                       */
/*==============================================================*/


create table SETTLEMENT_TYPE  (
   SETTLEMENT_TYPE_ID   NUMBER(9)                        not null,
   SETTLEMENT_TYPE_NAME VARCHAR2(32)                     not null,
   SETTLEMENT_TYPE_ALIAS VARCHAR2(32),
   SETTLEMENT_TYPE_DESC VARCHAR2(256),
   SETTLEMENT_TYPE_ORDER VARCHAR2(16),
   SERVICE_CODE         CHAR(1),
   SCENARIO_ID          NUMBER(9),
   STATEMENT_TYPE_ID    NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SETTLEMENT_TYPE primary key (SETTLEMENT_TYPE_ID)
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


comment on table SETTLEMENT_TYPE is
'A combination of Service Code and Scenario in order to give the user multiple Settlement Type options other than Preliminary and Final.'
/


comment on column SETTLEMENT_TYPE.SETTLEMENT_TYPE_ID is
'OID generated primary key'
/


comment on column SETTLEMENT_TYPE.SETTLEMENT_TYPE_NAME is
'Unique Identifier'
/


comment on column SETTLEMENT_TYPE.SETTLEMENT_TYPE_ALIAS is
'Optional identifier'
/


comment on column SETTLEMENT_TYPE.SETTLEMENT_TYPE_DESC is
'Optional Description'
/


comment on column SETTLEMENT_TYPE.SETTLEMENT_TYPE_ORDER is
'Order in which the types appear in the Settlement dropdown.  The first one will be the default.'
/


comment on column SETTLEMENT_TYPE.SERVICE_CODE is
'F, B, or A, to match the SERVICE_CODE in the SERVICE_LOAD table.  This defines the type of run.'
/


comment on column SETTLEMENT_TYPE.SCENARIO_ID is
'The ID of the appropriate Scenario from the SCENARIO table.'
/


comment on column SETTLEMENT_TYPE.STATEMENT_TYPE_ID is
'The ID of the appropriate Statement Type the Settlement will be accepted into.  From the STATEMENT_TYPE table.'
/


comment on column SETTLEMENT_TYPE.ENTRY_DATE is
'Date the record was last updated.'
/


alter table SETTLEMENT_TYPE
   add constraint AK_SETTLEMENT_TYPE unique (SETTLEMENT_TYPE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SHADOW_SETTLEMENT                                     */
/*==============================================================*/


create table SHADOW_SETTLEMENT  (
   EDC_ID               NUMBER(9)                        not null,
   ESP_ID               NUMBER(9)                        not null,
   SETTLEMENT_CODE      CHAR(1)                          not null,
   SETTLEMENT_DATE      DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   EDC_ENERGY_IMBALANCE_CHARGE NUMBER(14,4),
   EDC_NET_RETAIL_IMBALANCE NUMBER(14,4),
   EDC_SUPPLY           NUMBER(14,4),
   EDC_USAGE            NUMBER(14,4),
   EDC_IMBALANCE        NUMBER(14,4),
   EDC_PENALTY          NUMBER(14,4),
   EDC_COST             NUMBER(14,4),
   ESP_SUPPLY           NUMBER(14,4),
   ESP_USAGE            NUMBER(14,4),
   ESP_IMBALANCE        NUMBER(14,4),
   ESP_PENALTY          NUMBER(14,4),
   ESP_COST             NUMBER(14,4),
   constraint PK_SHADOW_SETTLEMENT primary key (EDC_ID, ESP_ID, SETTLEMENT_CODE, SETTLEMENT_DATE, AS_OF_DATE)
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


/*==============================================================*/
/* Table: STATEMENT_FORECAST_SCENARIO                           */
/*==============================================================*/


create table STATEMENT_FORECAST_SCENARIO  (
   SCENARIO_ID          NUMBER(9)                        not null,
   LOAD_SCENARIO_ID     NUMBER(9),
   PRODUCT_CASE_ID      NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_STATEMENT_FORECAST_SCENARIO primary key (SCENARIO_ID)
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


/*==============================================================*/
/* Table: STATEMENT_TYPE                                        */
/*==============================================================*/


create table STATEMENT_TYPE  (
   STATEMENT_TYPE_ID    NUMBER(9)                        not null,
   STATEMENT_TYPE_NAME  VARCHAR2(32)                     not null,
   STATEMENT_TYPE_ALIAS VARCHAR2(32),
   STATEMENT_TYPE_DESC  VARCHAR2(256),
   STATEMENT_TYPE_ORDER NUMBER(3),
   ENTRY_DATE           DATE,
   constraint PK_STATEMENT_TYPE primary key (STATEMENT_TYPE_ID)
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


comment on table STATEMENT_TYPE is
'Holds attributes for Statement Types - which allow storing scheduling/delivery data for distinct phases of forecasting/settlement process'
/


comment on column STATEMENT_TYPE.STATEMENT_TYPE_ID is
'Unique ID for this Statement Type'
/


comment on column STATEMENT_TYPE.STATEMENT_TYPE_NAME is
'The Name of the Statement Type (used for display)'
/


comment on column STATEMENT_TYPE.STATEMENT_TYPE_ALIAS is
'Optional Alias for the Statement Type'
/


comment on column STATEMENT_TYPE.STATEMENT_TYPE_DESC is
'Optional Description of the Statement Type'
/


comment on column STATEMENT_TYPE.STATEMENT_TYPE_ORDER is
'Display Order (used for displaying lists)'
/


comment on column STATEMENT_TYPE.ENTRY_DATE is
'The timestamp of the last modification to this record'
/


alter table STATEMENT_TYPE
   add constraint AK_STATEMENT_TYPE unique (STATEMENT_TYPE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: STATION_PARAMETER_INDEX_CACHE                         */
/*==============================================================*/


create global temporary table STATION_PARAMETER_INDEX_CACHE  (
   STATION_ID           NUMBER(9),
   PARAMETER_ID         NUMBER(9)
)
on commit preserve rows
/


comment on table STATION_PARAMETER_INDEX_CACHE is
'Temporary table used for Forecast and Backcast'
/


/*==============================================================*/
/* Table: STATION_PARAMETER_PROJECTION                          */
/*==============================================================*/


create table STATION_PARAMETER_PROJECTION  (
   CASE_ID              NUMBER(9)                        not null,
   STATION_ID           NUMBER(9)                        not null,
   PARAMETER_ID         NUMBER(9)                        not null,
   PARAMETER_DATE       DATE                             not null,
   PARAMETER_MIN        NUMBER(8,2),
   PARAMETER_MAX        NUMBER(8,2),
   PARAMETER_AVG        NUMBER(8,2),
   HISTORICAL_BEGIN_DATE DATE,
   HISTORICAL_END_DATE  DATE,
   HISTORICAL_MIN       NUMBER(8,2),
   HISTORICAL_MAX       NUMBER(8,2),
   HISTORICAL_AVG       NUMBER(8,2),
   HISTORICAL_SUM       NUMBER(8,2),
   HISTORICAL_CNT       NUMBER(8),
   HISTORICAL_FACTOR    NUMBER(8,6),
   ENTRY_DATE           DATE,
   constraint PK_STATION_PARAMETER_PROJECTIO primary key (CASE_ID, STATION_ID, PARAMETER_ID, PARAMETER_DATE)
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


/*==============================================================*/
/* Table: STATION_PARAMETER_VALUE                               */
/*==============================================================*/


create table STATION_PARAMETER_VALUE  (
   CASE_ID              NUMBER(9)                        not null,
   STATION_ID           NUMBER(9)                        not null,
   PARAMETER_ID         NUMBER(9)                        not null,
   PARAMETER_CODE       CHAR(1)                          not null,
   PARAMETER_DATE       DATE                             not null,
   PARAMETER_VAL        NUMBER(8,2),
   constraint PK_STATION_PARAMETER_VALUE primary key (CASE_ID, STATION_ID, PARAMETER_ID, PARAMETER_CODE, PARAMETER_DATE)
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
    initial 1M
    next 1M
    pctincrease 0
)
tablespace NERO_DATA
/


/*==============================================================*/
/* Table: STATION_PARAMETER_VALUE_CACHE                         */
/*==============================================================*/


create global temporary table STATION_PARAMETER_VALUE_CACHE  (
   STATION_ID           NUMBER(9)                        not null,
   PARAMETER_ID         NUMBER(9)                        not null,
   PARAMETER_DATE       DATE                             not null,
   PARAMETER_VAL        NUMBER(8,2),
   constraint PK_STATION_PARAMETER_VALUE_CAC primary key (STATION_ID, PARAMETER_ID, PARAMETER_DATE)
)
on commit preserve rows
/


comment on table STATION_PARAMETER_VALUE_CACHE is
'Temporary table used for Forecast and Backcast'
/
/*==============================================================*/
/* Table: STATION_PARAMETER_VALUE_TEMP                          */
/*==============================================================*/
create global temporary table STATION_PARAMETER_VALUE_TEMP  (
   STATION_NAME           VARCHAR2(32)                         not null,
   PARAMETER_NAME         VARCHAR2(32)                        not null,
   PARAMETER_CODE       CHAR(1)                          not null,
   PARAMETER_DATE       DATE                             not null,
   PARAMETER_VAL        NUMBER(8,2),
      constraint PK_STATION_PARAMETER_VALUE_TMP primary key (STATION_NAME, PARAMETER_NAME, PARAMETER_CODE, PARAMETER_DATE)
)
on commit preserve rows
/
comment on table STATION_PARAMETER_VALUE_TEMP is
'Temporary table used for MDR sync'
/

/*==============================================================*/
/* Table: STORAGE_CAPACITY                                      */
/*==============================================================*/


create table STORAGE_CAPACITY  (
   CONTRACT_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   MAX_CAPACITY         NUMBER(16,3),
   MAX_DAILY_INJECTIONS NUMBER(16,3),
   MAX_DAILY_WITHDRAWALS NUMBER(16,3),
   INJECTION_FUEL_PCT   NUMBER(8,4),
   WITHDRAWAL_FUEL_PCT  NUMBER(8,4),
   ENTRY_DATE           DATE,
   constraint PK_STORAGE_CAPACITY primary key (CONTRACT_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: STORAGE_RATCHET                                       */
/*==============================================================*/


create table STORAGE_RATCHET  (
   CONTRACT_ID          NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   PERIOD_BEGIN         DATE                             not null,
   PERIOD_END           DATE,
   FROM_PCT_FULL        NUMBER(8,4)                      not null,
   TO_PCT_FULL          NUMBER(8,4),
   MAX_INJECTION_PCT    NUMBER(8,4),
   MAX_WITHDRAWAL_PCT   NUMBER(8,4),
   ENTRY_DATE           DATE,
   constraint PK_STORAGE_RATCHET primary key (CONTRACT_ID, BEGIN_DATE, PERIOD_BEGIN, FROM_PCT_FULL)
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


/*==============================================================*/
/* Table: STORAGE_SCHEDULE                                      */
/*==============================================================*/


create table STORAGE_SCHEDULE  (
   CONTRACT_ID          NUMBER(9)                        not null,
   STATEMENT_TYPE_ID    NUMBER(9)                        not null,
   SCHEDULE_STATE       NUMBER(1)                        not null,
   SCHEDULE_DATE        DATE                             not null,
   AS_OF_DATE           DATE                             not null,
   BALANCE              NUMBER(16,3),
   TOTAL_INJECTIONS     NUMBER(16,3),
   TOTAL_INJECTION_FUEL NUMBER(16,3),
   TOTAL_WITHDRAWALS    NUMBER(16,3),
   TOTAL_WITHDRAWAL_FUEL NUMBER(16,3),
   constraint PK_STORAGE_SCHEDULE primary key (CONTRACT_ID, STATEMENT_TYPE_ID, SCHEDULE_STATE, SCHEDULE_DATE, AS_OF_DATE)
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


/*==============================================================*/
/* Table: SUPPLY_RESOURCE                                       */
/*==============================================================*/


create table SUPPLY_RESOURCE  (
   RESOURCE_ID          NUMBER(9)                        not null,
   RESOURCE_NAME        VARCHAR2(64)                     not null,
   RESOURCE_ALIAS       VARCHAR2(32),
   RESOURCE_DESC        VARCHAR2(256),
   RESOURCE_GROUP_ID    NUMBER(9),
   SERVICE_POINT_ID     NUMBER(9),
   HEAT_RATE_CURVE_ID   NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SUPPLY_RESOURCE primary key (RESOURCE_ID)
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


alter table SUPPLY_RESOURCE
   add constraint AK_SUPPLY_RESOURCE unique (RESOURCE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SUPPLY_RESOURCE_GROUP                                 */
/*==============================================================*/


create table SUPPLY_RESOURCE_GROUP  (
   RESOURCE_GROUP_ID    NUMBER(9)                        not null,
   RESOURCE_GROUP_NAME  VARCHAR2(64)                     not null,
   RESOURCE_GROUP_ALIAS VARCHAR2(32),
   RESOURCE_GROUP_DESC  VARCHAR2(256),
   SERVICE_ZONE_ID      NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_SUPPLY_RESOURCE_GROUP primary key (RESOURCE_GROUP_ID)
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


alter table SUPPLY_RESOURCE_GROUP
   add constraint AK_SUPPLY_RESOURCE_GROUP unique (RESOURCE_GROUP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SUPPLY_RESOURCE_METER                                 */
/*==============================================================*/


create table SUPPLY_RESOURCE_METER  (
   RESOURCE_ID          NUMBER(9)                        not null,
   METER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   ASSIGNMENT_PCT       NUMBER,
   ENTRY_DATE           DATE,
   constraint PK_SUPPLY_RESOURCE_METER primary key (RESOURCE_ID, METER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Index: FK_SUPPLY_RESOURCE_METER                              */
/*==============================================================*/
create index FK_SUPPLY_RESOURCE_METER on SUPPLY_RESOURCE_METER (
   METER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SUPPLY_RESOURCE_OWNER                                 */
/*==============================================================*/


create table SUPPLY_RESOURCE_OWNER  (
   RESOURCE_ID          NUMBER(9)                        not null,
   OWNER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   OWNER_PCT            NUMBER,
   IS_RESIDUAL          NUMBER(1)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_SUPPLY_RESOURCE_OWNER primary key (RESOURCE_ID, OWNER_ID, BEGIN_DATE)
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


alter table SUPPLY_RESOURCE_OWNER
   add constraint CK01_SUPPLY_RESOURCE_OWNER check ((IS_RESIDUAL = 1 and OWNER_PCT is null) or (IS_RESIDUAL = 0 and OWNER_PCT is not null))
/


/*==============================================================*/
/* Index: FK_SUPPLY_RESOURCE_OWNER                              */
/*==============================================================*/
create index FK_SUPPLY_RESOURCE_OWNER on SUPPLY_RESOURCE_OWNER (
   OWNER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_ACTION                                         */
/*==============================================================*/


create table SYSTEM_ACTION  (
   ACTION_ID            NUMBER(9)                        not null,
   ACTION_NAME          VARCHAR2(256)                    not null,
   ACTION_ALIAS         VARCHAR2(32),
   ACTION_DESC          VARCHAR2(256),
   ENTITY_DOMAIN_ID     NUMBER(9),
   MODULE               VARCHAR2(32),
   ACTION_TYPE          VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_ACTION primary key (ACTION_ID)
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


alter table SYSTEM_ACTION
   add constraint AK_SYSTEM_ACTION unique (ACTION_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SYSTEM_ACTION_ROLE                                    */
/*==============================================================*/


create table SYSTEM_ACTION_ROLE  (
   ACTION_ID            NUMBER(9)                        not null,
   ROLE_ID              NUMBER(9)                        not null,
   REALM_ID             NUMBER(9)                        not null,
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_ACTION_ROLE primary key (ACTION_ID, ROLE_ID, REALM_ID, ENTITY_DOMAIN_ID)
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


comment on table SYSTEM_ACTION_ROLE is
'The definition of which Roles can access which Actions over which Realms.'
/


comment on column SYSTEM_ACTION_ROLE.ACTION_ID is
'The Action from the SYSTEM_ACTION table for which this role and realm applies'
/


comment on column SYSTEM_ACTION_ROLE.ROLE_ID is
'The Role from the RETAIL_OFFICE_ROLE table in the security schema for which this Action has access to this Realm.'
/


comment on column SYSTEM_ACTION_ROLE.REALM_ID is
'The Realm from the SYSTEM_REALM table over which this Action can be performed by this Role.'
/


comment on column SYSTEM_ACTION_ROLE.ENTITY_DOMAIN_ID is
'The Domain for this SYSTEM_REALM relationship - some SYSTEM_ACTIONS can have a domain of ALL, allowing multiple domains in this table for the same action'
/


/*==============================================================*/
/* Index: FK_SYSTEM_ACTION_ROLE_DOMAIN                          */
/*==============================================================*/
create index FK_SYSTEM_ACTION_ROLE_DOMAIN on SYSTEM_ACTION_ROLE (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_SYSTEM_ACTION_ROLE_REALM                           */
/*==============================================================*/
create index FK_SYSTEM_ACTION_ROLE_REALM on SYSTEM_ACTION_ROLE (
   REALM_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_SYSTEM_ACTION_ROLE_ROLE                            */
/*==============================================================*/
create index FK_SYSTEM_ACTION_ROLE_ROLE on SYSTEM_ACTION_ROLE (
   ROLE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_ALERT                                          */
/*==============================================================*/


create table SYSTEM_ALERT  (
   ALERT_ID             NUMBER(9)                        not null,
   ALERT_NAME           VARCHAR2(32)                     not null,
   ALERT_ALIAS          VARCHAR2(32),
   ALERT_DESC           VARCHAR2(256),
   ALERT_TYPE           VARCHAR2(32),
   ALERT_CATEGORY       VARCHAR2(32),
   ALERT_DURATION       NUMBER,
   IS_EMAIL_ALERT       NUMBER(1),
   IS_EMAIL_FIRST_ACK   NUMBER(1),
   ALERT_EMAIL_PRIORITY NUMBER(1),
   ALERT_EMAIL_SUBJECT  VARCHAR2(64),
   ACK_EMAIL_PRIORITY   NUMBER(1),
   ACK_EMAIL_SUBJECT    VARCHAR2(64),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_ALERT primary key (ALERT_ID)
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


alter table SYSTEM_ALERT
   add constraint AK_SYSTEM_ALERT unique (ALERT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SYSTEM_ALERT_ACKNOWLEDGEMENT                          */
/*==============================================================*/


create table SYSTEM_ALERT_ACKNOWLEDGEMENT  (
   OCCURRENCE_ID        NUMBER(9)                        not null,
   USER_ID              NUMBER(9)                        not null,
   RECIEVED_DATE        DATE,
   ACKNOWLEDGE_DATE     DATE,
   COMPLETED_DATE       DATE,
   constraint PK_SYSTEM_ALERT_ACKNOWLEDGEMNT primary key (OCCURRENCE_ID, USER_ID)
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


/*==============================================================*/
/* Index: FK_SYSTEM_A_REFERENCE_APPLICAT                        */
/*==============================================================*/
create index FK_SYSTEM_A_REFERENCE_APPLICAT on SYSTEM_ALERT_ACKNOWLEDGEMENT (
   USER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_ALERT_OCCURRENCE                               */
/*==============================================================*/


create table SYSTEM_ALERT_OCCURRENCE  (
   OCCURRENCE_ID        NUMBER(9)                        not null,
   ALERT_ID             NUMBER(9)                        not null,
   ALERT_DATE           DATE                             not null,
   ALERT_EXPIRY         DATE,
   ALERT_MESSAGE        VARCHAR2(4000),
   PRIORITY             NUMBER(2)                        not null,
   TRIGGER_TYPE         VARCHAR2(32)                     not null,
   TRIGGER_LEVEL        NUMBER(3)                        not null,
   TRIGGER_VALUE        VARCHAR2(4000)                   not null,
   PROCESS_ID           NUMBER(12)                       not null,
   constraint PK_SYSTEM_ALERT_OCCURRENCE primary key (OCCURRENCE_ID)
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


/*==============================================================*/
/* Index: SYSTEM_ALERT_OCCURRENCE_IX01                          */
/*==============================================================*/
create index SYSTEM_ALERT_OCCURRENCE_IX01 on SYSTEM_ALERT_OCCURRENCE (
   ALERT_ID ASC,
   TRIGGER_TYPE ASC,
   TRIGGER_LEVEL ASC,
   ALERT_DATE ASC,
   ALERT_EXPIRY ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: FK_SYSTEM_ALERT_OCCUR_PROCESS                         */
/*==============================================================*/
create index FK_SYSTEM_ALERT_OCCUR_PROCESS on SYSTEM_ALERT_OCCURRENCE (
   PROCESS_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_ALERT_ROLE                                     */
/*==============================================================*/


create table SYSTEM_ALERT_ROLE  (
   ALERT_ID             NUMBER(9)                        not null,
   ROLE_ID              NUMBER(9)                        not null,
   EMAIL_REC_TYPE       CHAR(3),
   constraint PK_SYSTEM_ALERT_ROLE primary key (ALERT_ID, ROLE_ID)
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


/*==============================================================*/
/* Table: SYSTEM_ALERT_TRIGGER                                  */
/*==============================================================*/


create table SYSTEM_ALERT_TRIGGER  (
   ALERT_ID             NUMBER(9)                        not null,
   TRIGGER_TYPE         VARCHAR2(32)                     not null,
   TRIGGER_LEVEL        NUMBER(3)                        not null,
   EXACT_LEVEL          NUMBER(1)                        not null,
   PROCESS_NAME         VARCHAR2(128)                    not null,
   NAME_IS_REG_EXP      NUMBER(1)                        not null,
   TRIGGER_VALUE        VARCHAR2(1000)                   not null,
   VALUE_IS_REG_EXP     NUMBER(1)                        not null,
   constraint PK_SYSTEM_ALERT_TRIGGER primary key (ALERT_ID, TRIGGER_TYPE, TRIGGER_LEVEL, EXACT_LEVEL, PROCESS_NAME, NAME_IS_REG_EXP, TRIGGER_VALUE, VALUE_IS_REG_EXP)
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


/*==============================================================*/
/* Index: SYSTEM_ALERT_TRIGGER_IX01                             */
/*==============================================================*/
create index SYSTEM_ALERT_TRIGGER_IX01 on SYSTEM_ALERT_TRIGGER (
   TRIGGER_TYPE ASC,
   TRIGGER_LEVEL ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: SYSTEM_ATTRIBUTE                                      */
/*==============================================================*/


create table SYSTEM_ATTRIBUTE  (
   ATTRIBUTE_ID         NUMBER(9)                        not null,
   ATTRIBUTE_NAME       VARCHAR(32)                      not null,
   OBJECT_CATEGORY      VARCHAR(32)                      not null,
   ATTRIBUTE_DESC       VARCHAR(256),
   ATTRIBUTE_COMBO_LIST VARCHAR(512),
   ATTRIBUTE_IS_BOOLEAN NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_ATTRIBUTE primary key (ATTRIBUTE_ID, ATTRIBUTE_NAME, OBJECT_CATEGORY)
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


/*==============================================================*/
/* Table: SYSTEM_DATE_TIME                                      */
/*==============================================================*/


create table SYSTEM_DATE_TIME  (
   TIME_ZONE            VARCHAR2(4)                      not null,
   DATA_INTERVAL_TYPE   NUMBER(1)                        not null,
   DAY_TYPE             CHAR(1)                          not null,
   CUT_DATE             DATE                             not null,
   LOCAL_DATE           DATE,
   STANDARD_DATE        DATE,
   CUT_DATE_SCHEDULING  DATE,
   MINIMUM_INTERVAL_NUMBER NUMBER(2),
   CUT_MINUTE           NUMBER(2),
   CUT_HOUR             NUMBER(2),
   CUT_DAY_IN_WEEK      NUMBER(1),
   CUT_DAY_ABBR         VARCHAR2(16),
   CUT_DAY_IN_MONTH     NUMBER(2),
   CUT_WEEK_IN_YEAR     NUMBER(2),
   CUT_MONTH            NUMBER(2),
   CUT_QUARTER          NUMBER(2),
   CUT_YEAR             NUMBER(4),
   CUT_FISCAL_YEAR      NUMBER(4),
   LOCAL_HOUR_TRUNC_DATE DATE,
   LOCAL_DAY_TRUNC_DATE DATE,
   LOCAL_WEEK_TRUNC_DATE DATE,
   LOCAL_MONTH_TRUNC_DATE DATE,
   LOCAL_QUARTER_TRUNC_DATE DATE,
   LOCAL_YEAR_TRUNC_DATE DATE,
   LOCAL_FISCAL_YEAR_TRUNC_DATE DATE,
   NO_ROLLUP_YYYY_MM_DD VARCHAR2(32),
   MI15_YYYY_MM_DD      VARCHAR2(32),
   MI30_YYYY_MM_DD      VARCHAR2(32),
   HOUR_YYYY_MM_DD      VARCHAR2(32),
   DAY_YYYY_MM_DD       VARCHAR2(32),
   WEEK_YYYY_MM_DD      VARCHAR2(32),
   MONTH_YYYY_MM_DD     VARCHAR2(32),
   QUARTER_YYYY_MM_DD   VARCHAR2(32),
   YEAR_YYYY_MM_DD      VARCHAR2(32),
   FISCAL_YEAR_YYYY_MM_DD VARCHAR2(32),
   NO_ROLLUP_CUSTOM_STRING VARCHAR2(32),
   HOUR_CUSTOM_STRING   VARCHAR2(32),
   DAY_CUSTOM_STRING    VARCHAR2(32),
   WEEK_CUSTOM_STRING   VARCHAR2(32),
   MONTH_CUSTOM_STRING  VARCHAR2(32),
   QUARTER_CUSTOM_STRING VARCHAR2(32),
   YEAR_CUSTOM_STRING   VARCHAR2(32),
   FISCAL_YEAR_CUSTOM_STRING VARCHAR2(32),
   IS_IN_DST_RANGE      NUMBER(1),
   IS_DST_SPRING_AHEAD_HOUR NUMBER(1),
   IS_DST_SPRING_AHEAD_DAY NUMBER(1),
   IS_DST_FALL_BACK_HOUR NUMBER(1),
   IS_DST_FALL_BACK_DAY NUMBER(1),
   IS_ON_PEAK           NUMBER(1),
   constraint PK_SYSTEM_DATE_TIME primary key (TIME_ZONE, DATA_INTERVAL_TYPE, DAY_TYPE, CUT_DATE)
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


comment on table SYSTEM_DATE_TIME is
'System table to cross-reference dates of different intervals with each other.  This table is automatically generated via a script.'
/


comment on column SYSTEM_DATE_TIME.TIME_ZONE is
'The Time Zone for which these mappings apply.  Should match a TIME_ZONE from the SYSTEM_TIME_ZONE table.'
/


comment on column SYSTEM_DATE_TIME.DATA_INTERVAL_TYPE is
'The interval of the underlying data -- roughly corresponds to MODEL_ID on most tables where 1 is hourly and 2 is daily.  Hourly data that falls on zero o-clock is rolled back to the previous day (24:00), but daily data stays on the same day.'
/


comment on column SYSTEM_DATE_TIME.DAY_TYPE is
'Corresponds to SERVICE_LOAD.LOAD_CODE where 1 is a Standard day, 2 is a Weekday Day, and 3 is a Weekend Day.'
/


comment on column SYSTEM_DATE_TIME.CUT_DATE is
'The key date of the row from which the other columns are derived.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_DATE is
'The local time zone equivalent of the CUT_DATE.'
/


comment on column SYSTEM_DATE_TIME.STANDARD_DATE is
'The CUT_DATE converted to the LOCAL_DATE ignoring DST'
/


comment on column SYSTEM_DATE_TIME.CUT_DATE_SCHEDULING is
'If Data_Interval_Type is 2, then this field is Cut_Date plus one second (which is the way daily intervals are stored in the Scheduling module).  For Data_Interval_Type of 1, this field is equal to Cut_Date.'
/


comment on column SYSTEM_DATE_TIME.MINIMUM_INTERVAL_NUMBER is
'In order to get all the dates of a certain interval, specify this column in the query as AND MINIMUM_INTERVAL_NUMBER >= v_MIN_NUM, where v_MIN_NUM is determined from the function GET_INTERVAL_NUMBER(p_INTERVAL).'
/


comment on column SYSTEM_DATE_TIME.CUT_MINUTE is
'The Minute value of the CUT_DATE, from 0 to 59.'
/


comment on column SYSTEM_DATE_TIME.CUT_HOUR is
'The Hour value of the CUT_DATE, from 0 to 23.'
/


comment on column SYSTEM_DATE_TIME.CUT_DAY_IN_WEEK is
'The Day number in the week of the CUT_DATE, from 1 to 7.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.CUT_DAY_ABBR is
'The abbreviation of the day name, such as MON, TUE, WED, etc.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.CUT_DAY_IN_MONTH is
'The Day number in the month of the CUT_DATE, from 1 to 31 depending on the month.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.CUT_WEEK_IN_YEAR is
'The number of the week in the current year, from 1 to 53.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.CUT_MONTH is
'The number of the month in the current year, from 1 to 12.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.CUT_QUARTER is
'The number of the quarter in the current year, from 1 to 4.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.CUT_YEAR is
'The number of the current year, such as 2005.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.CUT_FISCAL_YEAR is
'The number of the current fiscal year, such as 2005.  The end of the fiscal year is defined in the initial population script.  If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_HOUR_TRUNC_DATE is
'The local time zone equivalent of the CUT_DATE truncated to the hour.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_DAY_TRUNC_DATE is
'The local time zone equivalent of the CUT_DATE truncated to the day.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_WEEK_TRUNC_DATE is
'The local time zone equivalent of the CUT_DATE truncated to the week.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_MONTH_TRUNC_DATE is
'The local time zone equivalent of the CUT_DATE truncated to the month.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_QUARTER_TRUNC_DATE is
'The local time zone equivalent of the CUT_DATE truncated to the quarter.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_YEAR_TRUNC_DATE is
'The local time zone equivalent of the CUT_DATE truncated to the year.'
/


comment on column SYSTEM_DATE_TIME.LOCAL_FISCAL_YEAR_TRUNC_DATE is
'The local time zone equivalent of the CUT_DATE truncated to the fiscal year.'
/


comment on column SYSTEM_DATE_TIME.NO_ROLLUP_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE formatted as a YYYY_MM_DD varchar2.'
/

comment on column SYSTEM_DATE_TIME.MI15_YYYY_MM_DD is 
'The local time zone equivalent of the CUT_DATE rolled up to 15 mins and formatted as a YYYY_MM_DD varchar2.'
/

comment on column SYSTEM_DATE_TIME.MI30_YYYY_MM_DD is 
'The local time zone equivalent of the CUT_DATE rolled up to 30 mins and formatted as a YYYY_MM_DD varchar2.'
/

comment on column SYSTEM_DATE_TIME.HOUR_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE rolled up to the hour and formatted as a YYYY_MM_DD varchar2.'
/


comment on column SYSTEM_DATE_TIME.DAY_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE rolled up to the day and formatted as a YYYY_MM_DD varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.WEEK_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE rolled up to the week and formatted as a YYYY_MM_DD varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.MONTH_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE rolled up to the month and formatted as a YYYY_MM_DD varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.QUARTER_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE rolled up to the quarter and formatted as a YYYY_MM_DD varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.YEAR_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE rolled up to the year and formatted as a YYYY_MM_DD varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.FISCAL_YEAR_YYYY_MM_DD is
'The local time zone equivalent of the CUT_DATE rolled up to the fiscal year and formatted as a YYYY_MM_DD varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.NO_ROLLUP_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE formatted as a SHORT_STRING varchar2.'
/


comment on column SYSTEM_DATE_TIME.HOUR_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE rolled up to the hour and formatted as a SHORT_STRING varchar2.'
/


comment on column SYSTEM_DATE_TIME.DAY_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE rolled up to the day and formatted as a SHORT_STRING varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.WEEK_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE rolled up to the week and formatted as a SHORT_STRING varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.MONTH_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE rolled up to the month and formatted as a SHORT_STRING varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.QUARTER_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE rolled up to the quarter and formatted as a SHORT_STRING varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.YEAR_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE rolled up to the year and formatted as a SHORT_STRING varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.FISCAL_YEAR_CUSTOM_STRING is
'The local time zone equivalent of the CUT_DATE rolled up to the fiscal year and formatted as a SHORT_STRING varchar2. If the Data Interval Type is 1 and CUT_DATE lands on zero o-clock, then the date is rolled back to the previous day.'
/


comment on column SYSTEM_DATE_TIME.IS_IN_DST_RANGE is
'Is this CUT_DATE in the Daylight Savings Time Range?'
/


comment on column SYSTEM_DATE_TIME.IS_DST_SPRING_AHEAD_HOUR is
'Is this the actual transition hour from Standard to Daylight?'
/


comment on column SYSTEM_DATE_TIME.IS_DST_SPRING_AHEAD_DAY is
'Is this the transition day from Standard to Daylight?'
/


comment on column SYSTEM_DATE_TIME.IS_DST_FALL_BACK_HOUR is
'Is this the actual transition hour from Daylight to Standard?'
/


comment on column SYSTEM_DATE_TIME.IS_DST_FALL_BACK_DAY is
'Is this the transition day from Daylight to Standard?'
/


comment on column SYSTEM_DATE_TIME.IS_ON_PEAK is
'Field equals 1 if we are On Peak or 0 if we are Off Peak.  For Data_Interval_Type of 2, the value is always 0.'
/


/*==============================================================*/
/* Index: SYSTEM_DATE_TIME_UIX01                                */
/*==============================================================*/
create unique index SYSTEM_DATE_TIME_UIX01 on SYSTEM_DATE_TIME (
   TIME_ZONE ASC,
   DATA_INTERVAL_TYPE ASC,
   DAY_TYPE ASC,
   CUT_DATE ASC,
   LOCAL_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: SYSTEM_DATE_TIME_IX01                                 */
/*==============================================================*/
create index SYSTEM_DATE_TIME_IX01 on SYSTEM_DATE_TIME (
   TIME_ZONE ASC,
   DATA_INTERVAL_TYPE ASC,
   CUT_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: SYSTEM_DATE_TIME_IX02                                 */
/*==============================================================*/
create index SYSTEM_DATE_TIME_IX02 on SYSTEM_DATE_TIME (
   TIME_ZONE ASC,
   DATA_INTERVAL_TYPE ASC,
   DAY_TYPE ASC,
   CUT_DATE ASC,
   MINIMUM_INTERVAL_NUMBER ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: SYSTEM_DATE_TIME_IX03                                 */
/*==============================================================*/
create index SYSTEM_DATE_TIME_IX03 on SYSTEM_DATE_TIME (
   TIME_ZONE ASC,
   DATA_INTERVAL_TYPE ASC,
   DAY_TYPE ASC,
   CUT_DATE_SCHEDULING ASC,
   MINIMUM_INTERVAL_NUMBER ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: SYSTEM_DATE_TIME_IX04                                 */
/*==============================================================*/
create index SYSTEM_DATE_TIME_IX04 on SYSTEM_DATE_TIME (
   TIME_ZONE ASC,
   DATA_INTERVAL_TYPE ASC,
   DAY_TYPE ASC,
   LOCAL_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: SYSTEM_DATE_TIME_SCENARIO                             */
/*==============================================================*/


create table SYSTEM_DATE_TIME_SCENARIO  (
   DAY_TYPE             CHAR(1)                          not null,
   ROLLUP_DATE          DATE                             not null,
   SCENARIO_ROLLUP_TYPE NUMBER(1)                        not null,
   SCENARIO_MULTIPLIER  NUMBER(7,4),
   constraint PK_SYSTEM_DATE_TIME_SCENARIO primary key (DAY_TYPE, ROLLUP_DATE, SCENARIO_ROLLUP_TYPE)
)
organization
    index
        tablespace NERO_DATA
        storage
        (
            initial 128K
            next 128K
            pctincrease 0
        )
/


comment on table SYSTEM_DATE_TIME_SCENARIO is
'System table that helps with the expansion of Long-Term Forecast results into Monthly totals. This table is automatically generated via a script, along with the SYSTEM_DATE_TIME table.'
/


comment on column SYSTEM_DATE_TIME_SCENARIO.DAY_TYPE is
'Corresponds to SERVICE_LOAD.LOAD_CODE where 1 is a Standard day, 2 is a Weekday Day, and 3 is a Weekend Day.'
/


comment on column SYSTEM_DATE_TIME_SCENARIO.ROLLUP_DATE is
'The beginning of the day, week, or month that corresponds to the multiplier for the daytype.'
/


comment on column SYSTEM_DATE_TIME_SCENARIO.SCENARIO_ROLLUP_TYPE is
'Corresponds to the LOAD_FORECAST_SCENARIO.SCENARIO_ROLLUP_TYPE column: 0 for hourly/standard rollup, 1 for daily rollup, 2 for weekly rollup, and 3 for monthly rollup of Long-Term Forecasts.'
/


comment on column SYSTEM_DATE_TIME_SCENARIO.SCENARIO_MULTIPLIER is
'The multiplier to expand a single day of Long Term results to represent the whole month of data.  In the case of a monthly rollup LT Forecast, this would be the number of weekdays in the month if the DAY_TYPE were 2, or the number of weekend days in the month if the DAY_TYPE were 3.'
/

/*==============================================================*/
/* Table: SYSTEM_DAY_INFO                                     */
/*==============================================================*/


create table SYSTEM_DAY_INFO (
   TIME_ZONE             VARCHAR2(4)                          not null,
   LOCAL_DATE            DATE                                 not null,
   DST_TYPE              NUMBER(1)                            not null,
   CUT_BEGIN_DATE        DATE                                 not null,
   CUT_END_DATE          DATE                                 not null,
  constraint PK_SYSTEM_DAY_INFO primary key (TIME_ZONE, LOCAL_DATE)
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


/*==============================================================*/
/* Table: SYSTEM_DICTIONARY                                     */
/*==============================================================*/


create table SYSTEM_DICTIONARY  (
   MODEL_ID             NUMBER(1)                        not null,
   MODULE               VARCHAR2(64)                     not null,
   KEY1                 VARCHAR2(64)                     not null,
   KEY2                 VARCHAR2(64)                     not null,
   KEY3                 VARCHAR2(64)                     not null,
   SETTING_NAME         VARCHAR2(64)                     not null,
   VALUE                VARCHAR2(512),
   constraint PK_SYSTEM_DICTIONARY primary key (MODEL_ID, MODULE, KEY1, KEY2, KEY3, SETTING_NAME)
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


/*==============================================================*/
/* Table: SYSTEM_EVENT                                          */
/*==============================================================*/


create table SYSTEM_EVENT  (
   EVENT_ID             NUMBER(9)                        not null,
   EVENT_NAME           VARCHAR2(32)                     not null,
   EVENT_ALIAS          VARCHAR2(32),
   EVENT_DESC           VARCHAR2(256),
   EVENT_TYPE           VARCHAR2(32),
   EVENT_CATEGORY       VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_EVENT primary key (EVENT_ID)
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


alter table SYSTEM_EVENT
   add constraint AK_SYSTEM_EVENT unique (EVENT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SYSTEM_EVENT_OCCURRENCE                               */
/*==============================================================*/


create table SYSTEM_EVENT_OCCURRENCE  (
   EVENT_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   EVENT_REASON         VARCHAR2(128),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_EVENT_OCCURRENCE primary key (EVENT_ID, BEGIN_DATE, END_DATE)
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


/*==============================================================*/
/* Table: SYSTEM_LABEL                                          */
/*==============================================================*/


create table SYSTEM_LABEL  (
   MODEL_ID             NUMBER(1)                        not null,
   MODULE               VARCHAR2(64)                     not null,
   KEY1                 VARCHAR2(64)                     not null,
   KEY2                 VARCHAR2(64)                     not null,
   KEY3                 VARCHAR2(64)                     not null,
   POSITION             NUMBER(7)                        not null,
   VALUE                VARCHAR2(128),
   CODE                 VARCHAR2(32),
   IS_DEFAULT           NUMBER(1),
   IS_HIDDEN            NUMBER(1),
   constraint PK_SYSTEM_LABEL primary key (MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION)
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


/*==============================================================*/
/* Table: SYSTEM_LOAD                                           */
/*==============================================================*/


create table SYSTEM_LOAD  (
   SYSTEM_LOAD_ID       NUMBER(9)                        not null,
   SYSTEM_LOAD_NAME     VARCHAR2(32)                     not null,
   SYSTEM_LOAD_ALIAS    VARCHAR2(32),
   SYSTEM_LOAD_DESC     VARCHAR2(256),
   SYSTEM_LOAD_INTERVAL VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_LOAD primary key (SYSTEM_LOAD_ID)
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


alter table SYSTEM_LOAD
   add constraint AK_SYSTEM_LOAD unique (SYSTEM_LOAD_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: SYSTEM_LOAD_AREA                                      */
/*==============================================================*/


create table SYSTEM_LOAD_AREA  (
   SYSTEM_LOAD_ID       NUMBER(9)                        not null,
   AREA_ID              NUMBER(9)                        not null,
   OPERATION_CODE       CHAR(1),
   constraint PK_SYSTEM_LOAD_AREA primary key (SYSTEM_LOAD_ID, AREA_ID)
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

/*==============================================================*/
/* Table: SYSTEM_MESSAGE                                      */
/*==============================================================*/


create table SYSTEM_MESSAGE  (
   MESSAGE_ID       NUMBER(9)                        not null,
   OCCURRENCE_ID       NUMBER(9),
   PROCESS_ID       NUMBER(12),
   FROM_USER_ID              NUMBER(9)                        not null,
   TO_USER_ID              NUMBER(9)                        not null,
   SEND_DATE              DATE                        not null,
   RECEIVED              DATE,
   READ              DATE,
   SUBJECT              VARCHAR2(256),
   BODY              CLOB,
   constraint PK_SYSTEM_MESSAGE primary key (MESSAGE_ID)
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



/*==============================================================*/
/* Table: SYSTEM_OBJECT                                         */
/*==============================================================*/


create table SYSTEM_OBJECT  (
   OBJECT_ID            NUMBER(9)                        not null,
   PARENT_OBJECT_ID     NUMBER(9)                        not null,
   OBJECT_NAME          VARCHAR2(256)                    not null,
   OBJECT_INDEX         NUMBER(9)                        not null,
   OBJECT_CATEGORY      VARCHAR2(32)                     not null,
   OBJECT_TYPE          VARCHAR2(64)                     not null,
   OBJECT_ALIAS         VARCHAR2(32),
   OBJECT_DESC          VARCHAR2(256),
   OBJECT_DISPLAY_NAME  VARCHAR2(128),
   OBJECT_TAG           VARCHAR2(64),
   OBJECT_ORDER         NUMBER(4),
   OBJECT_IS_HIDDEN     NUMBER(1),
   IS_MODIFIED          NUMBER(1)                      default 1  not null,
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_OBJECT primary key (OBJECT_ID)
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

create unique index AK_SYSTEM_OBJECT
on SYSTEM_OBJECT(PARENT_OBJECT_ID, UPPER(OBJECT_NAME), OBJECT_INDEX, OBJECT_CATEGORY, OBJECT_TYPE)
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


/*==============================================================*/
/* Table: SYSTEM_OBJECT_ATTRIBUTE                               */
/*==============================================================*/


create table SYSTEM_OBJECT_ATTRIBUTE  (
   OBJECT_ID            NUMBER(9)                        not null,
   ATTRIBUTE_ID         NUMBER(9)                        not null,
   ATTRIBUTE_VAL        VARCHAR2(4000),
   constraint PK_SYSTEM_OBJECT_ATTRIBUTE primary key (OBJECT_ID, ATTRIBUTE_ID)
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


/*==============================================================*/
/* Table: SYSTEM_OBJECT_IMPORT                                  */
/*==============================================================*/


create table SYSTEM_OBJECT_IMPORT  (
   OBJECT_IMPORT_ID     NUMBER(9)                        not null,
   USER_ID              NUMBER(9),
   IMPORTED_DATE        DATE                             not null,
   IMPORT_STATUS        VARCHAR2(64),
   IMPORT_MODE          VARCHAR2(32),
   IMPORT_FILENAME      VARCHAR2(128),
   PRODUCT_SCRIPT_TYPE  VARCHAR2(32),
   PRODUCT_SCRIPT_REVISION VARCHAR2(32),
   constraint PK_SYSTEM_OBJECT_IMPORT primary key (OBJECT_IMPORT_ID)
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


/*==============================================================*/
/* Index: FK_SYSTEM_O_REFERENCE_APPLICAT                        */
/*==============================================================*/
create index FK_SYSTEM_O_REFERENCE_APPLICAT on SYSTEM_OBJECT_IMPORT (
   USER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_OBJECT_IMPORT_ATTR_LOG                         */
/*==============================================================*/


create table SYSTEM_OBJECT_IMPORT_ATTR_LOG  (
   OBJECT_IMPORT_ID     NUMBER(9)                        not null,
   OBJECT_ID            NUMBER(9)                        not null,
   IMPORT_SIDE          VARCHAR2(16)                     not null,
   ATTRIBUTE_ID         NUMBER(9)                        not null,
   ATTRIBUTE_VAL        VARCHAR2(4000),
   constraint PK_SYSTEM_OBJECT_IMPORT_ATTR_L primary key (OBJECT_IMPORT_ID, OBJECT_ID, IMPORT_SIDE, ATTRIBUTE_ID)
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


/*==============================================================*/
/* Table: SYSTEM_OBJECT_IMPORT_CRYSTAL                          */
/*==============================================================*/


create table SYSTEM_OBJECT_IMPORT_CRYSTAL  (
   OBJECT_IMPORT_ID     NUMBER(9)                        not null,
   OBJECT_ID            NUMBER(9)                        not null,
   IMPORT_SIDE          VARCHAR2(16)                     not null,
   TEMPLATE_TYPE        VARCHAR2(2000)                   not null,
   REPORT_FILE          BLOB                             not null,
   constraint PK_SYSTEM_OBJECT_IMPORT_CRYSTA primary key (OBJECT_IMPORT_ID, OBJECT_ID, IMPORT_SIDE, TEMPLATE_TYPE)
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


/*==============================================================*/
/* Table: SYSTEM_OBJECT_IMPORT_ITEM                             */
/*==============================================================*/


create table SYSTEM_OBJECT_IMPORT_ITEM  (
   OBJECT_IMPORT_ID     NUMBER(9)                        not null,
   OBJECT_ID            NUMBER(9)                        not null,
   PARENT_OBJECT_ID     NUMBER(9)                        not null,
   OBJECT_NAME          VARCHAR2(256)                    not null,
   OBJECT_INDEX         NUMBER(9)                        not null,
   OBJECT_CATEGORY      VARCHAR2(32)                     not null,
   OBJECT_TYPE          VARCHAR2(64)                     not null,
   MERGE_TYPE           VARCHAR2(16),
   constraint PK_SYSTEM_OBJECT_IMPORT_ITEM primary key (OBJECT_IMPORT_ID, OBJECT_ID)
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


/*==============================================================*/
/* Index: SYSTEM_OBJECT_IMPORT_ITEM_IX01                        */
/*==============================================================*/
create index SYSTEM_OBJECT_IMPORT_ITEM_IX01 on SYSTEM_OBJECT_IMPORT_ITEM (
   OBJECT_IMPORT_ID ASC,
   PARENT_OBJECT_ID ASC
)
/


/*==============================================================*/
/* Table: SYSTEM_OBJECT_IMPORT_LOG                              */
/*==============================================================*/


create table SYSTEM_OBJECT_IMPORT_LOG  (
   OBJECT_IMPORT_ID     NUMBER(9)                        not null,
   OBJECT_ID            NUMBER(9)                        not null,
   IMPORT_SIDE          VARCHAR2(16)                     not null,
   OBJECT_ALIAS         VARCHAR2(32),
   OBJECT_DESC          VARCHAR2(256),
   OBJECT_DISPLAY_NAME  VARCHAR2(128),
   OBJECT_TAG           VARCHAR2(64),
   OBJECT_ORDER         NUMBER(4),
   OBJECT_IS_HIDDEN     NUMBER(1),
   IS_MODIFIED          NUMBER(1),
   IS_OBJECT_PRESENT    NUMBER(1),
   constraint PK_SYSTEM_OBJECT_IMPORT_LOG primary key (OBJECT_IMPORT_ID, OBJECT_ID, IMPORT_SIDE)
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


/*==============================================================*/
/* Table: SYSTEM_OBJECT_PRIVILEGE                               */
/*==============================================================*/


create table SYSTEM_OBJECT_PRIVILEGE  (
   OBJECT_ID            NUMBER(9)                        not null,
   ROLE_ID              NUMBER(9)                        not null,
   ROLE_PRIVILEGE       NUMBER(1)                        not null,
   DO_NOT_INHERIT       NUMBER(1)                        not null,
   CREATE_DATE          DATE                             not null,
   LAST_UPDATE_DATE     DATE,
   constraint PK_SYSTEM_OBJECT_PRIVILEGE primary key (OBJECT_ID, ROLE_ID)
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


/*==============================================================*/
/* Index: FK_APPLICATION_ROLE                                   */
/*==============================================================*/
create index FK_APPLICATION_ROLE on SYSTEM_OBJECT_PRIVILEGE (
   ROLE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_REALM                                          */
/*==============================================================*/


create table SYSTEM_REALM  (
   REALM_ID             NUMBER(9)                        not null,
   REALM_NAME           VARCHAR(32)                      not null,
   REALM_ALIAS          VARCHAR(32),
   REALM_DESC           VARCHAR(256),
   ENTITY_DOMAIN_ID     NUMBER(9),
   REALM_CALC_TYPE      NUMBER(1)                        not null,
   CUSTOM_QUERY         VARCHAR(4000),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_REALM primary key (REALM_ID)
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


comment on table SYSTEM_REALM is
'Contains all System Realms.'
/


comment on column SYSTEM_REALM.REALM_ID is
'The ID of the Realm'
/


comment on column SYSTEM_REALM.REALM_NAME is
'The Realm Name'
/


comment on column SYSTEM_REALM.ENTITY_DOMAIN_ID is
'The Entity Domain over which the Realm extends'
/


comment on column SYSTEM_REALM.REALM_CALC_TYPE is
'Is this a System Realm (0), a Formula Charge Realm (1), or a Calculation Component Realm (2) ?'
/


alter table SYSTEM_REALM
   add constraint AK_SYSTEM_REALM unique (REALM_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_SYSTEM_REALM_DOMAIN                                */
/*==============================================================*/
create index FK_SYSTEM_REALM_DOMAIN on SYSTEM_REALM (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_REALM_COLUMN                                   */
/*==============================================================*/


create table SYSTEM_REALM_COLUMN  (
   REALM_ID             NUMBER(9)                        not null,
   ENTITY_COLUMN        VARCHAR2(32)                     not null,
   IS_EXCLUDING_VALS    NUMBER(1),
   COLUMN_VALS          VARCHAR2(4000),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_REALM_COLUMN primary key (REALM_ID, ENTITY_COLUMN)
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


comment on column SYSTEM_REALM_COLUMN.REALM_ID is
'The Realm from the SYSTEM_REALM table that contains the specified entities'
/


comment on column SYSTEM_REALM_COLUMN.ENTITY_COLUMN is
'The entity Column from the Domain for this particular Realm and Role'
/


/*==============================================================*/
/* Table: SYSTEM_REALM_ENTITY                                   */
/*==============================================================*/


create table SYSTEM_REALM_ENTITY  (
   REALM_ID             NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_REALM_ENTITY primary key (REALM_ID, ENTITY_ID)
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


comment on table SYSTEM_REALM_ENTITY is
'The list of Entities in a Realm'
/


comment on column SYSTEM_REALM_ENTITY.REALM_ID is
'The Realm from the SYSTEM_REALM table that contains the specified entities'
/


comment on column SYSTEM_REALM_ENTITY.ENTITY_ID is
'The Entity ID of type defined in the SYSTEM_REALM_TYPE table that is included in the specified Realm'
/

/*==============================================================*/
/* Table: SYSTEM_SESSION                                        */
/*==============================================================*/

create table SYSTEM_SESSION  (
   SESSION_SID          VARCHAR2(32)     not null,
   SESSION_AUDSID       NUMBER           not null,
   CURRENT_PROCESS_ID   NUMBER(12),
   LOG_LEVEL            NUMBER(3),
   KEEP_EVENT_DETAIL    NUMBER(1),
   PERSIST_TRACE        NUMBER(1),
   constraint SYSTEM_SESSION primary key (SESSION_SID, SESSION_AUDSID)
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


/*==============================================================*/
/* INDEX: FK_SYSTEM_SESSION_PROCESS                             */
/*==============================================================*/
CREATE INDEX FK_SYSTEM_SESSION_PROCESS ON SYSTEM_SESSION (
   CURRENT_PROCESS_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: SYSTEM_STATE                                          */
/*==============================================================*/

create table SYSTEM_STATE (
   SETTING_NAME            VARCHAR2(64) NOT NULL,
   NUMBER_VAL              NUMBER,
   STRING_VAL              VARCHAR2(256),
   DATE_VAL                DATE,
   constraint PK_SYSTEM_STATE primary key (SETTING_NAME)
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

/*==============================================================*/
/* Table: SYSTEM_TABLE                                          */
/*==============================================================*/


create table SYSTEM_TABLE  (
   TABLE_ID                NUMBER(9)                        not null,
   TABLE_NAME              VARCHAR2(128)                    not null,
   TABLE_ALIAS             VARCHAR2(32),
   TABLE_DESC              VARCHAR2(512),
   DB_TABLE_NAME           VARCHAR2(30)                     not null,
   MIRROR_TABLE_NAME       VARCHAR2(30)                     not null,
   ENTITY_DOMAIN_ID        NUMBER(9)                        not null,
   KEY_CONSTRAINT_NAME     VARCHAR2(30)                     not null,
   ENTITY_ID_COLUMN_NAME   VARCHAR2(30),
   DATE1_COLUMN_NAME       VARCHAR2(30),
   DATE2_COLUMN_NAME       VARCHAR2(30),
   IS_REACTIVE             NUMBER(1)        default 0       not null,
   LOCK_SUMMARY_TABLE_NAME VARCHAR2(30),
   ENTRY_DATE           DATE,
   constraint PK_SYSTEM_TABLE primary key (TABLE_ID)
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


alter table SYSTEM_TABLE
   add constraint CHK_SYSTEM_TABLE_ENTITY_ID_COL check ((ENTITY_DOMAIN_ID <> 0 AND NOT ENTITY_ID_COLUMN_NAME IS NULL) OR (ENTITY_DOMAIN_ID = 0 AND ENTITY_ID_COLUMN_NAME IS NULL))
/


alter table SYSTEM_TABLE
   add constraint AK_SYSTEM_TABLE unique (TABLE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


alter table SYSTEM_TABLE
   add constraint AK2_SYSTEM_TABLE unique (DB_TABLE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


alter table SYSTEM_TABLE
   add constraint AK3_SYSTEM_TABLE unique (MIRROR_TABLE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_SYSTEM_TABLE_ENTITY_DOMAIN                         */
/*==============================================================*/
create index FK_SYSTEM_TABLE_ENTITY_DOMAIN on SYSTEM_TABLE (
   ENTITY_DOMAIN_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: SYSTEM_TIME_ZONE                                      */
/*==============================================================*/


create table SYSTEM_TIME_ZONE  (
   TIME_ZONE            VARCHAR2(4)                      not null,
   TIME_ZONE_DESC       VARCHAR2(64),
   IS_DST_OBSERVANT     NUMBER(1),
   STANDARD_TIME_ZONE   VARCHAR2(4),
   STANDARD_TIME_ZONE_OFFSET VARCHAR2(6),
   ENABLED			NUMBER(1),
   constraint PK_SYSTEM_TIME_ZONE primary key (TIME_ZONE)
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


comment on table SYSTEM_TIME_ZONE is
'Time Zone table to determine DST observation and correlation between Standard and Daylight Time Zones.'
/


comment on column SYSTEM_TIME_ZONE.TIME_ZONE is
'Oracle-recognized abbreviation for Time Zone.'
/


comment on column SYSTEM_TIME_ZONE.TIME_ZONE_DESC is
'Optional Description of Time Zone.'
/


comment on column SYSTEM_TIME_ZONE.IS_DST_OBSERVANT is
'Does this Time Zone represent a Time Zone that will observe DST at the appropriate time?'
/


comment on column SYSTEM_TIME_ZONE.STANDARD_TIME_ZONE is
'The Oracle-recognized abbreviation for the Standard Time Zone that correlates to this one when DST is not in effect.'
/

comment on column SYSTEM_TIME_ZONE.ENABLED is
'Does this Time Zone display in UI?'
/


/*==============================================================*/
/* Table: TAX_CHARGE                                            */
/*==============================================================*/


create table TAX_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   PRODUCT_ID           NUMBER(9)                        not null,
   COMPONENT_ID         NUMBER(9)                        not null,
   GEOGRAPHY_ID         NUMBER(9)                        not null,
   SERVICE_POINT_ID     NUMBER(9),
   CHARGE_QUANTITY      NUMBER(18,9),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_QUANTITY        NUMBER(18,9),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_TAX_CHARGE primary key (CHARGE_ID, CHARGE_DATE, PRODUCT_ID, COMPONENT_ID, GEOGRAPHY_ID)
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

/*==============================================================*/
/* Table: TEMP_LOAD_RESULT_CAL_LIST                             */
/*==============================================================*/

create global temporary table TEMP_LOAD_RESULT_CAL_LIST  (
   LOAD_RESULT_ID       NUMBER(9)                        not null
)
on commit preserve rows
/

/*==============================================================*/
/* Table: TEMP_LOAD_RESULT_LOSS_LIST                            */
/*==============================================================*/

create global temporary table TEMP_LOAD_RESULT_LOSS_LIST  (
   LOAD_RESULT_ID       NUMBER(9)                        not null
)
on commit preserve rows
/

/*==============================================================*/
/* Table: TEMP_LOAD_RESULT_HITS_LIST                            */
/*==============================================================*/

create global temporary table TEMP_LOAD_RESULT_HITS_LIST  (
   LOAD_RESULT_ID       NUMBER(9)                        not null
)
on commit preserve rows
/

/*==============================================================*/
/* Table: TEMP_PROGRAM_HITS_LIST                            */
/*==============================================================*/
create global temporary table TEMP_PROGRAM_HITS_LIST (
  PROGRAM_LIMIT_ID      NUMBER(9)       not null,
  PERIOD_START_DATE     DATE            not null,
  PERIOD_STOP_DATE      DATE            not null,
  HOLIDAY_SET_ID      NUMBER(9)       not null
)
on commit preserve rows
/



/*==============================================================*/
/* Table: TEMPLATE                                              */
/*==============================================================*/


create table TEMPLATE  (
   TEMPLATE_ID          NUMBER(9)                        not null,
   TEMPLATE_NAME        VARCHAR2(32)                     not null,
   TEMPLATE_ALIAS       VARCHAR2(32),
   TEMPLATE_DESC        VARCHAR2(256),
   IS_DAY_TYPE          NUMBER(1),
   IS_DST_OBSERVANT     NUMBER(1)                        not null,
   VALIDATION_MESSAGE   VARCHAR2(2000),
   ENTRY_DATE           DATE,
   constraint PK_TEMPLATE primary key (TEMPLATE_ID)
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


comment on column TEMPLATE.IS_DAY_TYPE is
'Differenciates between TOU Templates and DayType Templates, which are represented as separate entities.'
/


alter table TEMPLATE
   add constraint AK_TEMPLATE unique (TEMPLATE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: TEMPLATE_BREAKPOINT                                   */
/*==============================================================*/


create table TEMPLATE_BREAKPOINT  (
   TEMPLATE_ID          NUMBER(9)                        not null,
   VARIABLE_NBR         NUMBER(1)                        not null,
   PARAMETER_ID         NUMBER(9)                        not null,
   BREAKPOINT_ID        NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_TEMPLATE_BREAKPOINT primary key (TEMPLATE_ID, VARIABLE_NBR)
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

/*==============================================================*/
/* Table: TEMPLATE_DATES                                   */
/*==============================================================*/


create table TEMPLATE_DATES  (
   TIME_ZONE          VARCHAR2(4)                      not null,   
   TEMPLATE_ID        NUMBER(9)                        not null,
   HOLIDAY_SET_ID     NUMBER(9)                        not null,
   LOCAL_DATE         DATE                             not null,
   CUT_BEGIN_DATE     DATE                             not null,
   CUT_END_DATE       DATE                             not null,
   DAY_TYPE_ID        NUMBER(9)                        not null,
   constraint PK_TEMPLATE_DATES primary key (TIME_ZONE, TEMPLATE_ID, HOLIDAY_SET_ID, LOCAL_DATE)
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

alter table TEMPLATE_DATES
   add constraint AK_TEMPLATE_DATES unique (TIME_ZONE, TEMPLATE_ID, HOLIDAY_SET_ID, CUT_BEGIN_DATE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: TEMPLATE_DAY_TYPE                                   */
/*==============================================================*/


create table TEMPLATE_DAY_TYPE  (
   DAY_TYPE_ID         NUMBER(9)                        not null,
   TEMPLATE_ID         NUMBER(9)                        not null,
   SEASON_ID           NUMBER(9)                        not null,
   DAY_NAME            VARCHAR2(3)                      not null,
   DST_TYPE            NUMBER(1)                        not null,
   constraint PK_TEMPLATE_DAY_TYPE primary key (DAY_TYPE_ID)
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

alter table TEMPLATE_DAY_TYPE
   add constraint AK_TEMPLATE_DAY_TYPE unique (TEMPLATE_ID, SEASON_ID, DAY_NAME, DST_TYPE)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Table: TEMPLATE_DAY_TYPE_PERIOD                                   */
/*==============================================================*/


create table TEMPLATE_DAY_TYPE_PERIOD  (
   DAY_TYPE_ID                 NUMBER(9)   not null,
   TIME_STAMP                  NUMBER      not null,
   MINIMUM_INTERVAL_NUMBER     NUMBER(2)   not null,
   PERIOD_ID                   NUMBER(9)   not null,
   constraint PK_TEMPLATE_DAY_TYPE_PERIOD primary key (DAY_TYPE_ID, TIME_STAMP)
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

/*==============================================================*/
/* Table: TEMPLATE_SEASON_DAY_NAME                                   */
/*==============================================================*/


create table TEMPLATE_SEASON_DAY_NAME  (
   TEMPLATE_ID       NUMBER(9)                        not null,
   SEASON_ID         NUMBER(9)                        not null,
   DAY_NAME          CHAR(3),
   ENTRY_DATE        DATE,
   constraint PK_TEMPLATE_SEASON_DAY_NAME primary key (TEMPLATE_ID, SEASON_ID, DAY_NAME)
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


/*==============================================================*/
/* Table: TEMPORAL_ENTITY_ATTRIBUTE                             */
/*==============================================================*/


create table TEMPORAL_ENTITY_ATTRIBUTE  (
   OWNER_ENTITY_ID      NUMBER(9)                        not null,
   ATTRIBUTE_ID         NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   ENTITY_DOMAIN_ID     NUMBER(9),
   ATTRIBUTE_NAME       VARCHAR2(32),
   END_DATE             DATE,
   ATTRIBUTE_VAL        VARCHAR2(64),
   ENTRY_DATE           DATE,
   constraint PK_TEMPORAL_ENTITY_ATTRIBUTE primary key (OWNER_ENTITY_ID, ATTRIBUTE_ID, BEGIN_DATE)
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

/*==============================================================*/
/* Index: TEMPORAL_ENTITY_ATTR_IX01                             */
/*==============================================================*/
create index TEMPORAL_ENTITY_ATTR_IX01 on TEMPORAL_ENTITY_ATTRIBUTE (
   ATTRIBUTE_ID ASC,
   BEGIN_DATE ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: TP_CONTRACT_NUMBER                                    */
/*==============================================================*/


create table TP_CONTRACT_NUMBER  (
   CONTRACT_ID          NUMBER(9)                        not null,
   TP_ID                NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   CONTRACT_NAME        VARCHAR2(32),
   CONTRACT_NUMBER      VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_TP_CONTRACT_NUMBER primary key (CONTRACT_ID, TP_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Table: TRANSACTION_PATH                                      */
/*==============================================================*/


create table TRANSACTION_PATH  (
   TRANSACTION_ID       NUMBER(9)                        not null,
   LEG_NBR              NUMBER(2)                        not null,
   CA_ID                NUMBER(9),
   TP_ID                NUMBER(9),
   PSE_ID               NUMBER(9),
   TP_PRODUCT_CODE      VARCHAR2(16),
   TP_PATH_NAME         VARCHAR2(32),
   TP_ASSIGNMENT_REF    VARCHAR2(16),
   TP_PRODUCT_LEVEL     VARCHAR2(16),
   MISC_INFO            VARCHAR2(16),
   MISC_REF             VARCHAR2(16),
   constraint PK_TRANSACTION_PATH primary key (TRANSACTION_ID, LEG_NBR)
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


/*==============================================================*/
/* Table: TRANSACTION_TRAIT                                     */
/*==============================================================*/


create table TRANSACTION_TRAIT  (
   TRAIT_GROUP_ID       NUMBER(9)                        not null,
   TRAIT_INDEX          NUMBER(3)                        not null,
   SYSTEM_OBJECT_ID     NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_TRANSACTION_TRAIT primary key (TRAIT_GROUP_ID, TRAIT_INDEX)
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


comment on table TRANSACTION_TRAIT is
'A single Trait in a Group, whose data is stored in the IT_TRAIT_SCHEDULE table.'
/


comment on column TRANSACTION_TRAIT.TRAIT_GROUP_ID is
'Foreign key to the TRANSACTION_TRAIT_GROUP table'
/


comment on column TRANSACTION_TRAIT.TRAIT_INDEX is
'The index of this Trait within the Group.  This is not the order in which traits appeared, and should not be changed.  If there is more than one Trait in the Group, then the indexes need to be stored as constants in a _UTIL package.'
/


comment on column TRANSACTION_TRAIT.SYSTEM_OBJECT_ID is
'The foreign key to the SYSTEM_OBJECT table of a Column Object which has attributes that reflect how this Trait is handled in a report.  Display Name, Display Order, Edit Mask, Combo List, and Data Type are some of the attributes that are defined in this System Object''s attributes.'
/


comment on column TRANSACTION_TRAIT.ENTRY_DATE is
'The last date this row was updated.'
/


/*==============================================================*/
/* Index: FK_TRANSACT_TRAIT_SYSTEM_OBJ                          */
/*==============================================================*/
create index FK_TRANSACT_TRAIT_SYSTEM_OBJ on TRANSACTION_TRAIT (
   SYSTEM_OBJECT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: TRANSACTION_TRAIT_GROUP                               */
/*==============================================================*/


create table TRANSACTION_TRAIT_GROUP  (
   TRAIT_GROUP_ID       NUMBER(9)                        not null,
   TRAIT_GROUP_NAME     VARCHAR2(64)                     not null,
   TRAIT_GROUP_ALIAS    VARCHAR2(32),
   TRAIT_GROUP_DESC     VARCHAR2(256),
   TRAIT_GROUP_INTERVAL VARCHAR2(16),
   TRAIT_GROUP_TYPE     VARCHAR2(32),
   SC_ID                NUMBER(9),
   TRAIT_CATEGORY       VARCHAR2(64),
   DISPLAY_NAME         VARCHAR2(64),
   DISPLAY_ORDER        NUMBER(3),
   IS_SERIES            NUMBER(1),
   IS_SPARSE            NUMBER(1),
   IS_STATEMENT_TYPE_SPECIFIC NUMBER(1),
   DEFAULT_NUMBER_OF_SETS NUMBER(2),
   ENTRY_DATE           DATE,
   constraint PK_TRANSACTION_TRAIT_GROUP primary key (TRAIT_GROUP_ID)
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


comment on table TRANSACTION_TRAIT_GROUP is
'Attributes that define a Group of Traits, whose data is stored in the IT_TRAIT_SCHEDULE table.'
/


comment on column TRANSACTION_TRAIT_GROUP.TRAIT_GROUP_ID is
'Unique Identifier of Trait Group.  This Identifier should be specified as a constant in a _UTIL package to allow for faster queries.'
/


comment on column TRANSACTION_TRAIT_GROUP.TRAIT_GROUP_NAME is
'Unique Name of the Trait Group'
/


comment on column TRANSACTION_TRAIT_GROUP.TRAIT_GROUP_ALIAS is
'Optional Alias of the Trait Group'
/


comment on column TRANSACTION_TRAIT_GROUP.TRAIT_GROUP_DESC is
'Optional Description of the Trait Group'
/


comment on column TRANSACTION_TRAIT_GROUP.TRAIT_GROUP_INTERVAL is
'Interval of the data of the Traits in the Group: 5 Minute, 15 Minute, 30 Minute, Hour, Day, Week, Month, Year'
/


comment on column TRANSACTION_TRAIT_GROUP.TRAIT_GROUP_TYPE is
'Type of the Trait Group.  Used by Display Reports to determine which Traits to display on a given Report.'
/


comment on column TRANSACTION_TRAIT_GROUP.SC_ID is
'Foreign Key to SCHEDULE_COORDINATOR table.'
/


comment on column TRANSACTION_TRAIT_GROUP.TRAIT_CATEGORY is
'By default, traits where INTERCHANGE_TRANSACTION.TRAIT_CATEGORY LIKE TRANSACTION_TRAIT_GROUP.TRAIT_CATEGORY are shown on a report for that transaction.'
/


comment on column TRANSACTION_TRAIT_GROUP.DISPLAY_NAME is
'Name to be shown on report.  This name should just be the name of the market in the case of a Group with only one Trait, since the Trait itself stores the actual Display Name.'
/


comment on column TRANSACTION_TRAIT_GROUP.DISPLAY_ORDER is
'Display Order of this Group of Traits in a Report'
/


comment on column TRANSACTION_TRAIT_GROUP.IS_SERIES is
'If IS_SERIES = 1 then the IT_TRAIT_SCHEDULE data can have more than one SET of data.'
/


comment on column TRANSACTION_TRAIT_GROUP.IS_SPARSE is
'If IS_SPARSE = 1 then the SCHEDULE_DATE and the SCHEDULE_END_DATE are used in the IT_TRAIT_SCHEDULE table to represent data with begin date/end date.  Otherwise, data is expected to be populated for every interval.'
/


comment on column TRANSACTION_TRAIT_GROUP.IS_STATEMENT_TYPE_SPECIFIC is
'If this field is 0, then the STATEMENT_TYPE_ID in the IT_TRAIT_SCHEDULE table should always be zero.  Otherwise, it will correspond to a particular STATEMENT_TYPE.'
/


comment on column TRANSACTION_TRAIT_GROUP.DEFAULT_NUMBER_OF_SETS is
'The default number of sets to be shown in the Fill Dialog for this Trait.'
/


comment on column TRANSACTION_TRAIT_GROUP.ENTRY_DATE is
'The date this record was last updated.'
/


alter table TRANSACTION_TRAIT_GROUP
   add constraint AK_TRANSACTION_TRAIT_GROUP unique (TRAIT_GROUP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: TRANSACTION_TRAIT_TEMPLATE                            */
/*==============================================================*/


create table TRANSACTION_TRAIT_TEMPLATE  (
   COMMODITY_ID         NUMBER(9)                        not null,
   TRAIT_TEMPLATE_NAME  VARCHAR2(64)                     not null,
   ROW_NUMBER           NUMBER(9)                        not null,
   TEMPLATE_TYPE        VARCHAR2(16)                     not null,
   TEMPLATE_DATA        VARCHAR2(4000),
   ENTRY_DATE           DATE,
   constraint PK_TRANSACTION_TRAIT_TEMPLATE primary key (COMMODITY_ID, TRAIT_TEMPLATE_NAME, ROW_NUMBER, TEMPLATE_TYPE)
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


/*==============================================================*/
/* Table: TRANSMISSION_CHARGE                                   */
/*==============================================================*/


create table TRANSMISSION_CHARGE  (
   CHARGE_ID            NUMBER(12)                       not null,
   CHARGE_DATE          DATE                             not null,
   TRANSACTION_ID       NUMBER(9)                        not null,
   TRANSACTION_NAME     VARCHAR2(64),
   CHARGE_INTERVAL      VARCHAR2(16),
   CAPACITY_RESERVED    NUMBER(12,4),
   CHARGE_RATE          NUMBER(16,6),
   CHARGE_FACTOR        NUMBER(12,4),
   CHARGE_AMOUNT        NUMBER(12,2),
   BILL_CAPACITY_RESERVED NUMBER(12,4),
   BILL_AMOUNT          NUMBER(12,2),
   constraint PK_TRANSMISSION_CHARGE primary key (CHARGE_ID, CHARGE_DATE, TRANSACTION_ID)
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


/*==============================================================*/
/* Table: TRANSMISSION_PROVIDER                                 */
/*==============================================================*/


create table TRANSMISSION_PROVIDER  (
   TP_ID                NUMBER(9)                        not null,
   TP_NAME              VARCHAR2(32)                     not null,
   TP_ALIAS             VARCHAR2(32),
   TP_DESC              VARCHAR2(256),
   TP_NERC_CODE         VARCHAR2(16),
   TP_STATUS            VARCHAR2(16),
   TP_DUNS_NUMBER       VARCHAR2(16),
   OASIS_NODE_ID        NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_TRANSMISSION_PROVIDER primary key (TP_ID)
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


alter table TRANSMISSION_PROVIDER
   add constraint AK_TRANSMISSION_PROVIDER unique (TP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_TP_OASIS_NODE                                      */
/*==============================================================*/
create index FK_TP_OASIS_NODE on TRANSMISSION_PROVIDER (
   OASIS_NODE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: TSIN_CA_REGISTRY                                      */
/*==============================================================*/


create table TSIN_CA_REGISTRY  (
   TAGGING_ENTITY_ID    NUMBER(10)                       not null,
   TAG_CODE             VARCHAR2(4)                      not null,
   ENTITY_NAME          VARCHAR2(150),
   CONTACT24            VARCHAR2(150),
   PHONE24              VARCHAR2(32),
   FAX                  VARCHAR2(32),
   AGENT_URL            VARCHAR2(255),
   AUTHORITY_URL        VARCHAR2(255),
   APPROVAL_URL         VARCHAR2(255),
   FORWARD_URL          VARCHAR2(255),
   ENTITY_CODE          VARCHAR2(4),
   TAG_CODE_TYPE        VARCHAR2(3),
   NERC_ID              NUMBER(10),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   SC_CODE              VARCHAR2(4),
   REGION               VARCHAR2(20),
   ZERO_NHMBAM_FLAG     VARCHAR2(1),
   ALT1_DESC            VARCHAR2(150),
   ALT1_PHONE           VARCHAR2(32),
   ALT2_DESC            VARCHAR2(150),
   ALT2_PHONE           VARCHAR2(32),
   ALT3_DESC            VARCHAR2(150),
   ALT3_PHONE           VARCHAR2(32),
   MARKET_OPERATOR_FLAG VARCHAR2(1),
   PSEUDO_CA            VARCHAR2(1),
   constraint PK_TSIN_CA_REGISTRY primary key (TAGGING_ENTITY_ID, TAG_CODE)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_ENTITY_REGISTRY                                  */
/*==============================================================*/


create table TSIN_ENTITY_REGISTRY  (
   RECORD_ID            NUMBER(10)                       not null,
   NERC_ID              NUMBER(10),
   DUNS                 VARCHAR2(16),
   ENTITY_CODE          VARCHAR2(4),
   ENTITY_TYPE          VARCHAR2(8),
   ENTITY_NAME          VARCHAR2(150),
   ADDRESS_LINE_ONE     VARCHAR2(150),
   ADDRESS_LINE_TWO     VARCHAR2(150),
   CITY                 VARCHAR2(150),
   STATE                VARCHAR2(100),
   ZIP_CODE             VARCHAR2(15),
   COUNTRY              VARCHAR2(15),
   PRIM_CONTACT         VARCHAR2(150),
   PRIM_PHONE           VARCHAR2(32),
   PRIM_FAX             VARCHAR2(32),
   STRPRIMARYEMAIL      VARCHAR2(150),
   ADMIN_CONTACT        VARCHAR2(150),
   ADMIN_PHONE          VARCHAR2(32),
   ADMIN_FAX            VARCHAR2(32),
   ADMIN_EMAIL          VARCHAR2(150),
   ENTITY_URL           VARCHAR2(150),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   INITIAL_DATE         DATE,
   constraint PK_TSIN_ENTITY_REGISTRY primary key (RECORD_ID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_MRD_FLOWGATES                                    */
/*==============================================================*/


create table TSIN_MRD_FLOWGATES  (
   FGATE_NO             NUMBER(5)                        not null,
   FGATE_NAME           VARCHAR2(255),
   SEC_COORD            VARCHAR2(255),
   CON_AREAS            VARCHAR2(255),
   constraint PK_TSIN_MRD_FLOWGATES primary key (FGATE_NO)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_MRD_RESOURCES                                    */
/*==============================================================*/


create table TSIN_MRD_RESOURCES  (
   MRDRESOURCEID        NUMBER(10)                       not null,
   COMMON_NAME          VARCHAR2(50)                     not null,
   RESOURCE_NAME        VARCHAR2(20),
   CONTACT24            VARCHAR2(150),
   RESOURCE_PHONE       VARCHAR2(32),
   RESOURCE_FAX         VARCHAR2(32),
   constraint PK_TSIN_MRD_RESOURCES primary key (MRDRESOURCEID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_POR_POD_POINT                                    */
/*==============================================================*/


create table TSIN_POR_POD_POINT  (
   PORPODPOINTID        NUMBER(10)                       not null,
   NERC_ID              NUMBER(10),
   POINTNAME            VARCHAR2(255),
   TP_ENTITY_ID         NUMBER(10),
   CA_ENTITY_ID         NUMBER(10),
   PORPODROLEID         NUMBER(10),
   CREATION_DATE        DATE,
   DEACTIVATION_DATE    DATE,
   constraint PK_TSIN_POR_POD_POINT primary key (PORPODPOINTID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_POR_POD_ROLE                                     */
/*==============================================================*/


create table TSIN_POR_POD_ROLE  (
   PORPODROLEID         NUMBER(10)                       not null,
   PORPODROLEDESCRIPTION VARCHAR2(255),
   constraint PK_TSIN_POR_POD_ROLE primary key (PORPODROLEID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_PRODUCT_REGISTRY                                 */
/*==============================================================*/


create table TSIN_PRODUCT_REGISTRY  (
   PRODUCTID            NUMBER(10)                       not null,
   PRODUCTTYPEID        NUMBER(10),
   CODE                 VARCHAR2(4),
   PRODUCT              VARCHAR2(255),
   constraint PK_TSIN_PRODUCT_REGISTRY primary key (PRODUCTID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_PRODUCT_TYPE                                     */
/*==============================================================*/


create table TSIN_PRODUCT_TYPE  (
   PRODUCTTYPEID        NUMBER(10)                       not null,
   PRODUCTTYPEDESCRIPTION VARCHAR2(255),
   constraint PK_TSIN_PRODUCT_TYPE primary key (PRODUCTTYPEID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_PSE_REGISTRY                                     */
/*==============================================================*/


create table TSIN_PSE_REGISTRY  (
   TAGGING_ENTITY_ID    NUMBER(10)                       not null,
   TAG_CODE             VARCHAR2(6)                      not null,
   ENTITY_NAME          VARCHAR2(150),
   CONTACT24            VARCHAR2(150),
   PHONE24              VARCHAR2(32),
   FAX                  VARCHAR2(32),
   AGENT_URL            VARCHAR2(255),
   AUTHORITY_URL        VARCHAR2(255),
   APPROVAL_URL         VARCHAR2(255),
   FORWARD_URL          VARCHAR2(255),
   ENTITY_CODE          VARCHAR2(4),
   TAG_CODE_TYPE        VARCHAR2(3),
   NERC_ID              NUMBER(10),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   SC_CODE              VARCHAR2(4),
   REGION               VARCHAR2(20),
   ZERO_NHMBAM_FLAG     VARCHAR2(1),
   ALT1_DESC            VARCHAR2(150),
   ALT1_PHONE           VARCHAR2(32),
   ALT2_DESC            VARCHAR2(150),
   ALT2_PHONE           VARCHAR2(32),
   ALT3_DESC            VARCHAR2(150),
   ALT3_PHONE           VARCHAR2(32),
   MARKET_OPERATOR_FLAG VARCHAR2(1),
   PSEUDO_CA            VARCHAR2(1),
   constraint PK_TSIN_PSE_REGISTRY primary key (TAGGING_ENTITY_ID, TAG_CODE)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_REGISTRY_VERSION                                 */
/*==============================================================*/


create table TSIN_REGISTRY_VERSION  (
   VERSION_ID           NUMBER(10)                       not null,
   VERSION              VARCHAR2(20),
   CREATION_DATE        DATE,
   EFFECTIVE_DATE       DATE,
   constraint PK_TSIN_REGISTRY_VERSION primary key (VERSION_ID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_SC_REGISTRY                                      */
/*==============================================================*/


create table TSIN_SC_REGISTRY  (
   TAGGING_ENTITY_ID    NUMBER(10)                       not null,
   TAG_CODE             VARCHAR2(4)                      not null,
   ENTITY_NAME          VARCHAR2(150),
   CONTACT24            VARCHAR2(150),
   PHONE24              VARCHAR2(32),
   FAX                  VARCHAR2(32),
   AGENT_URL            VARCHAR2(255),
   AUTHORITY_URL        VARCHAR2(255),
   APPROVAL_URL         VARCHAR2(255),
   FORWARD_URL          VARCHAR2(255),
   ENTITY_CODE          VARCHAR2(4),
   TAG_CODE_TYPE        VARCHAR2(3),
   NERC_ID              NUMBER(10),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   SC_CODE              VARCHAR2(4),
   REGION               VARCHAR2(20),
   ZERO_NHMBAM_FLAG     VARCHAR2(1),
   ALT1_DESC            VARCHAR2(150),
   ALT1_PHONE           VARCHAR2(32),
   ALT2_DESC            VARCHAR2(150),
   ALT2_PHONE           VARCHAR2(32),
   ALT3_DESC            VARCHAR2(150),
   ALT3_PHONE           VARCHAR2(32),
   MARKET_OPERATOR_FLAG VARCHAR2(1),
   constraint PK_TSIN_SC_REGISTRY primary key (TAGGING_ENTITY_ID, TAG_CODE)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_SOURCE_SINK_POINT                                */
/*==============================================================*/


create table TSIN_SOURCE_SINK_POINT  (
   SOURCESINKPOINTID    NUMBER(10)                       not null,
   NERC_ID              NUMBER(10),
   POINTNAME            VARCHAR2(255),
   HOSTCATAGGINGID      NUMBER(10),
   GPELSETAGGINGENTITYID NUMBER(10),
   MRDRESOURCEID        NUMBER(6),
   APPROVALTAGGINGENTITYID NUMBER(10),
   APPROVALTAGGINGENTITYTYPE VARCHAR2(3),
   SOURCESINKROLEID     NUMBER(10),
   CREATION_DATE        DATE,
   DEACTIVATION_DATE    DATE,
   constraint PK_TSIN_SOURCE_SINK_POINT primary key (SOURCESINKPOINTID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_SOURCE_SINK_ROLE                                 */
/*==============================================================*/


create table TSIN_SOURCE_SINK_ROLE  (
   SOURCESINKROLEID     NUMBER(10)                       not null,
   SOURCESINKROLEDESC   VARCHAR2(255),
   constraint PK_TSIN_SOURCE_SINK_ROLE primary key (SOURCESINKROLEID)
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
       )
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
)
/


/*==============================================================*/
/* Table: TSIN_TP_REGISTRY                                      */
/*==============================================================*/


create table TSIN_TP_REGISTRY  (
   TAGGING_ENTITY_ID    NUMBER(10)                       not null,
   TAG_CODE             VARCHAR2(4)                      not null,
   ENTITY_NAME          VARCHAR2(150),
   CONTACT24            VARCHAR2(150),
   PHONE24              VARCHAR2(32),
   FAX                  VARCHAR2(32),
   AGENT_URL            VARCHAR2(255),
   AUTHORITY_URL        VARCHAR2(255),
   APPROVAL_URL         VARCHAR2(255),
   FORWARD_URL          VARCHAR2(255),
   ENTITY_CODE          VARCHAR2(4),
   TAG_CODE_TYPE        VARCHAR2(3),
   NERC_ID              NUMBER(10),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   SC_CODE              VARCHAR2(4),
   REGION               VARCHAR2(20),
   ZERO_NHMBAM_FLAG     VARCHAR2(1),
   ALT1_DESC            VARCHAR2(150),
   ALT1_PHONE           VARCHAR2(32),
   ALT2_DESC            VARCHAR2(150),
   ALT2_PHONE           VARCHAR2(32),
   ALT3_DESC            VARCHAR2(150),
   ALT3_PHONE           VARCHAR2(32),
   MARKET_OPERATOR_FLAG VARCHAR2(1),
   constraint PK_TSIN_TP_REGISTRY primary key (TAGGING_ENTITY_ID, TAG_CODE)
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
       )
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
)
/


/*==============================================================*/
/* Table: TX_PATH                                               */
/*==============================================================*/


create table TX_PATH  (
   PATH_ID              NUMBER(9)                        not null,
   PATH_NAME            VARCHAR2(32)                     not null,
   PATH_ALIAS           VARCHAR2(32),
   PATH_DESC            VARCHAR2(256),
   ENTRY_DATE           DATE,
   constraint PK_TX_PATH primary key (PATH_ID)
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


alter table TX_PATH
   add constraint AK_TX_PATH unique (PATH_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: TX_PATH_SEGMENT                                       */
/*==============================================================*/


create table TX_PATH_SEGMENT  (
   PATH_ID              NUMBER(9)                        not null,
   SEGMENT_ID           NUMBER(9)                        not null,
   SEGMENT_POS          NUMBER(2)                        not null,
   constraint PK_TX_PATH_SEGMENT primary key (PATH_ID, SEGMENT_ID, SEGMENT_POS)
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


/*==============================================================*/
/* Table: TX_SEGMENT                                            */
/*==============================================================*/


create table TX_SEGMENT  (
   SEGMENT_ID           NUMBER(9)                        not null,
   SEGMENT_NAME         VARCHAR2(32)                     not null,
   SEGMENT_ALIAS        VARCHAR2(32),
   SEGMENT_DESC         VARCHAR2(256),
   POR_ID               NUMBER(9),
   POD_ID               NUMBER(9),
   MW_LIMIT_1           VARCHAR2(8),
   MW_LIMIT_2           VARCHAR2(8),
   MW_LIMIT_3           VARCHAR2(8),
   LOSS_FACTOR          NUMBER(8,4),
   ENTRY_DATE           DATE,
   constraint PK_TX_SEGMENT primary key (SEGMENT_ID)
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


alter table TX_SEGMENT
   add constraint AK_TX_SEGMENT unique (SEGMENT_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: TX_SERVICE_TYPE                                       */
/*==============================================================*/


create table TX_SERVICE_TYPE  (
   SERVICE_TYPE_ID      NUMBER(9)                        not null,
   SERVICE_TYPE_NAME    VARCHAR2(32)                     not null,
   SERVICE_TYPE_ALIAS   VARCHAR2(32),
   SERVICE_TYPE_DESC    VARCHAR2(256),
   SERVICE_TYPE_CATEGORY VARCHAR2(16),
   IS_FIRM              NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_TX_SERVICE_TYPE primary key (SERVICE_TYPE_ID)
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


alter table TX_SERVICE_TYPE
   add constraint AK_TX_SERVICE_TYPE unique (SERVICE_TYPE_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: TX_SUB_STATION                                        */
/*==============================================================*/


create table TX_SUB_STATION  (
   SUB_STATION_ID       NUMBER(9)                        not null,
   SUB_STATION_NAME     VARCHAR2(64)                     not null,
   SUB_STATION_ALIAS    VARCHAR2(32),
   SUB_STATION_DESC     VARCHAR2(256),
   SUB_STATION_TYPE     VARCHAR2(32),
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   SERVICE_ZONE_ID      NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_TX_SUB_STATION primary key (SUB_STATION_ID)
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


alter table TX_SUB_STATION
   add constraint AK_TX_SUB_STATION unique (SUB_STATION_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_TX_SUB_STATION                                     */
/*==============================================================*/
CREATE INDEX FK_TX_SUB_STATION ON TX_SUB_STATION (
   SERVICE_ZONE_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: TX_SUB_STATION_METER                                  */
/*==============================================================*/


create table TX_SUB_STATION_METER  (
   METER_ID             NUMBER(9)                        not null,
   METER_NAME           VARCHAR2(64)                     not null,
   METER_ALIAS          VARCHAR2(32),
   METER_DESC           VARCHAR2(256),
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   METER_TYPE           VARCHAR2(32),
   METER_SUB_TYPE       VARCHAR2(32),
   METER_CATEGORY       VARCHAR2(32),
   REF_METER_ID         NUMBER(9),
   SUB_STATION_ID       NUMBER(9),
   SERVICE_POINT_ID     NUMBER(9),
   TRUNCATE_CARRY_FWD   NUMBER(1),
   QUALITY_RATING       VARCHAR2(16),
   ENTRY_DATE           DATE,
   constraint PK_TX_SUB_STATION_METER primary key (METER_ID)
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


alter table TX_SUB_STATION_METER
   add constraint CK01_TX_SUB_STATION_METER check (NVL(TRUNCATE_CARRY_FWD,0) in (0,1))
/


alter table TX_SUB_STATION_METER
   add constraint AK_TX_SUB_STATION_METER unique (METER_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Index: FK_TX_SUB_STATION_METER                               */
/*==============================================================*/
create index FK_TX_SUB_STATION_METER on TX_SUB_STATION_METER (
   SUB_STATION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_TX_SUB_STATION_METER_REF                           */
/*==============================================================*/
create index FK_TX_SUB_STATION_METER_REF on TX_SUB_STATION_METER (
   REF_METER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_TX_SUB_STATION_METER_SP                            */
/*==============================================================*/
create index FK_TX_SUB_STATION_METER_SP on TX_SUB_STATION_METER (
   SERVICE_POINT_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: TX_SUB_STATION_METER_OWNER                            */
/*==============================================================*/


create table TX_SUB_STATION_METER_OWNER  (
   METER_ID             NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   OWNER_ID             NUMBER(9),
   PARTY1_ID            NUMBER(9),
   PARTY2_ID            NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_TX_SUB_STATION_METER_OWNER primary key (METER_ID, BEGIN_DATE)
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


/*==============================================================*/
/* Index: TX_SUB_STATION_MTR_OWNER_IX01                         */
/*==============================================================*/
create index TX_SUB_STATION_MTR_OWNER_IX01 on TX_SUB_STATION_METER_OWNER (
   PARTY1_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Index: TX_SUB_STATION_MTR_OWNER_IX02                         */
/*==============================================================*/
create index TX_SUB_STATION_MTR_OWNER_IX02 on TX_SUB_STATION_METER_OWNER (
   PARTY2_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Index: FK_TX_SUB_STATION_METER_OWNER2                        */
/*==============================================================*/
create index FK_TX_SUB_STATION_METER_OWNER2 on TX_SUB_STATION_METER_OWNER (
   OWNER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: TX_SUB_STATION_METER_POINT                            */
/*==============================================================*/


create table TX_SUB_STATION_METER_POINT  (
   METER_POINT_ID       NUMBER(9)                        not null,
   METER_POINT_NAME     VARCHAR2(64)                     not null,
   METER_POINT_ALIAS    VARCHAR2(32),
   METER_POINT_DESC     VARCHAR2(256),
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   METER_POINT_CATEGORY VARCHAR2(32),
   RETAIL_METER_ID      NUMBER(9),
   SUB_STATION_METER_ID NUMBER(9),
   METER_POINT_INTERVAL	VARCHAR2(16),
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   UOM                  VARCHAR2(16),
   OPERATION_CODE       CHAR(1),
   DIRECTION            VARCHAR2(16),
   TOLERANCE            NUMBER,
   ENTRY_DATE           DATE,
   constraint PK_TX_SUB_STATION_METER_POINT primary key (METER_POINT_ID)
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


alter table TX_SUB_STATION_METER_POINT
   add constraint CK01_TX_SUB_STATION_MTR_POINT check (NVL(OPERATION_CODE,'N') in ('A','S','N'))
/


alter table TX_SUB_STATION_METER_POINT
   add constraint AK_TX_SUB_STATION_METER_POINT unique (METER_POINT_NAME, RETAIL_METER_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table TX_SUB_STATION_METER_POINT
   add constraint CK02_TX_SUB_STATION_MTR_POINT check 
   ((RETAIL_METER_ID IS NULL AND SUB_STATION_METER_ID IS NOT NULL) 
   OR (RETAIL_METER_ID IS NOT NULL AND SUB_STATION_METER_ID IS NULL))
/

/*==============================================================*/
/* Index: TX_SUB_STATION_METER_PT_IX01                          */
/*==============================================================*/
create index TX_SUB_STATION_METER_PT_IX01 on TX_SUB_STATION_METER_POINT (
   SUB_STATION_METER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/

/*==============================================================*/
/* INDEX: FK_RETAIL_METER_POINT                                 */
/*==============================================================*/
CREATE INDEX FK_RETAIL_METER_POINT ON TX_SUB_STATION_METER_POINT (
   RETAIL_METER_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/



/*==============================================================*/
/* Table: TX_SUB_STATION_METER_PT_LOSS                          */
/*==============================================================*/


create table TX_SUB_STATION_METER_PT_LOSS  (
   METER_POINT_ID       NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   FACTOR_TYPE          VARCHAR2(16)                     not null,
   LOSS_FACTOR_ID       NUMBER(9)                        not null,
   ENTRY_DATE           DATE,
   constraint PK_TX_SUB_STATION_MTR_PT_LOSS primary key (METER_POINT_ID, BEGIN_DATE)
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

alter table TX_SUB_STATION_METER_PT_LOSS
   add constraint CK01_TX_SUB_STATION_MTR_PT_LOS check (FACTOR_TYPE in ('Loss','Expansion'))
/


/*==============================================================*/
/* Index: FK_TX_SUB_STATION_MTR_PT_LOSS2                        */
/*==============================================================*/
create index FK_TX_SUB_STATION_MTR_PT_LOSS2 on TX_SUB_STATION_METER_PT_LOSS (
   LOSS_FACTOR_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: DATA_VALIDATION_RULE                         */
/*==============================================================*/


create table DATA_VALIDATION_RULE (
   ENTITY_DOMAIN_ID     NUMBER(9)                        not null,
   ENTITY_ID            NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   MIN_VAL              NUMBER,
   MAX_VAL              NUMBER,
   HOUR_COMPARE         CHAR(1),
   HOUR_VAL             NUMBER,
   DISALLOW_NEG         NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_DATA_VALIDATION_RULE primary key (ENTITY_DOMAIN_ID, ENTITY_ID, BEGIN_DATE)
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

alter table DATA_VALIDATION_RULE
   add constraint CK01_DATA_VALIDATION_RULE check (NVL(DISALLOW_NEG,0) in (0,1) and NVL(HOUR_COMPARE,'N') in ('P','A','N'))
/

alter table DATA_VALIDATION_RULE
   add constraint CK02_DATA_VALIDATION_RULE check (ENTITY_DOMAIN_ID in (-170, -190, -1030))
/


/*==============================================================*/
/* Table: TX_SUB_STATION_METER_PT_SOURCE                        */
/*==============================================================*/


create table TX_SUB_STATION_METER_PT_SOURCE  (
   METER_POINT_ID       NUMBER(9)                        not null,
   MEASUREMENT_SOURCE_ID NUMBER(9)                        not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE,
   IS_PRIMARY           NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_TX_SUB_STATION_METER_PT_SRC primary key (METER_POINT_ID, MEASUREMENT_SOURCE_ID, BEGIN_DATE)
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


alter table TX_SUB_STATION_METER_PT_SOURCE
   add constraint CK01_TX_SUB_STATION_MTR_PT_SRC check (NVL(IS_PRIMARY,0) in (0,1))
/


/*==============================================================*/
/* Index: FK_TX_SUB_STATION_MTR_PT_SRC2                         */
/*==============================================================*/
create index FK_TX_SUB_STATION_MTR_PT_SRC2 on TX_SUB_STATION_METER_PT_SOURCE (
   MEASUREMENT_SOURCE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: TX_SUB_STATION_METER_PT_VALUE                         */
/*==============================================================*/


create table TX_SUB_STATION_METER_PT_VALUE  (
   METER_POINT_ID       NUMBER(9)                        not null,
   MEASUREMENT_SOURCE_ID NUMBER(9)                        not null,
   METER_CODE           CHAR(1)                          not null,
   METER_DATE           DATE                             not null,
   METER_VAL            NUMBER(12,3),
   METER_VAL_CARRY_FWD  NUMBER(6,3),
   METER_VAL_ACCUM      NUMBER(15,3),
   METER_VAL_QUAL_CODE  VARCHAR2(16),
   TRUNCATED_VAL        NUMBER(12,3),
   TRUNCATED_VAL_ACCUM  NUMBER(15,3),
   TRUNCATED_VAL_QUAL_CODE VARCHAR2(16),
   LIFETIME_VAL_ACCUM   NUMBER(20,3),
   ENTRY_DATE           DATE,
   LOCK_STATE           CHAR(1),
   LOSS_VAL            NUMBER,
   constraint PK_TX_SUB_STATION_MTR_PT_VALUE primary key (METER_POINT_ID, MEASUREMENT_SOURCE_ID, METER_CODE, METER_DATE)
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


alter table TX_SUB_STATION_METER_PT_VALUE
   add constraint CK01_TX_SUB_STATION_MTR_PT_VAL check (METER_CODE in ('F','P','A'))
/


/*==============================================================*/
/* Table: TX_SUB_STATION_MTR_PT_VAL_LK_S                        */
/*==============================================================*/


create table TX_SUB_STATION_MTR_PT_VAL_LK_S  (
   METER_POINT_ID       NUMBER(9)                        not null,
   MEASUREMENT_SOURCE_ID NUMBER(9)                        not null,
   METER_CODE           CHAR(1)                          not null,
   BEGIN_DATE           DATE                             not null,
   END_DATE             DATE                             not null,
   LOCK_STATE           CHAR(1) DEFAULT 'U'              not null,
   constraint PK_TX_SUB_STAT_MTR_PT_LK_S_VAL primary key (METER_POINT_ID, MEASUREMENT_SOURCE_ID, METER_CODE, BEGIN_DATE)
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


/*==============================================================*/
/* Table: TX_SUB_STAT_MTR_PT_VAL_ERR_TMP                        */
/*==============================================================*/


create global temporary table TX_SUB_STAT_MTR_PT_VAL_ERR_TMP  (
   ORA_ERR_NUMBER$      NUMBER,
   ORA_ERR_MESG$        VARCHAR2(2000),
   ORA_ERR_ROWID$       ROWID,
   ORA_ERR_OPTYP$       VARCHAR2(2),
   ORA_ERR_TAG$         VARCHAR2(2000),
   METER_POINT_ID       VARCHAR2(4000),
   MEASUREMENT_SOURCE_ID VARCHAR2(4000),
   METER_CODE           VARCHAR2(4000),
   METER_DATE           VARCHAR2(4000),
   METER_VAL            VARCHAR2(4000),
   METER_VAL_CARRY_FWD  VARCHAR2(4000),
   METER_VAL_ACCUM      VARCHAR2(4000),
   METER_VAL_QUAL_CODE  VARCHAR2(4000),
   TRUNCATED_VAL        VARCHAR2(4000),
   TRUNCATED_VAL_ACCUM  VARCHAR2(4000),
   TRUNCATED_VAL_QUAL_CODE VARCHAR2(4000),
   LIFETIME_VAL_ACCUM   VARCHAR2(4000),
   ENTRY_DATE           VARCHAR2(4000),
   LOCK_STATE           VARCHAR2(4000)
)
/


/*==============================================================*/
/* Index: TX_SUB_STAT_MTR_VAL_ERR_T_IX01                        */
/*==============================================================*/
create index TX_SUB_STAT_MTR_VAL_ERR_T_IX01 on TX_SUB_STAT_MTR_PT_VAL_ERR_TMP (
   ORA_ERR_TAG$ ASC
)
/


/*==============================================================*/
/* Table: USAGE_WRF                                             */
/*==============================================================*/


create table USAGE_WRF  (
   WRF_ID               NUMBER(9)                        not null,
   WRF_NAME             VARCHAR2(32)                     not null,
   WRF_ALIAS            VARCHAR2(32),
   WRF_DESC             VARCHAR2(256),
   STATION_ID           NUMBER(9),
   PARAMETER_ID         NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_USAGE_WRF primary key (WRF_ID)
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


alter table USAGE_WRF
   add constraint AK_USAGE_WRF unique (WRF_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* Index: FK_USAGE_WRF_PARM                                     */
/*==============================================================*/
create index FK_USAGE_WRF_PARM on USAGE_WRF (
   PARAMETER_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_USAGE_WRF_STATION                                  */
/*==============================================================*/
create index FK_USAGE_WRF_STATION on USAGE_WRF (
   STATION_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: USAGE_WRF_SEASON                                      */
/*==============================================================*/


create table USAGE_WRF_SEASON  (
   WRF_ID               NUMBER(9)                        not null,
   TEMPLATE_ID          NUMBER(9)                        not null,
   SEASON_ID            NUMBER(9)                        not null,
   AS_OF_DATE           DATE                             not null,
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   BASE_LOAD_BEGIN_DATE DATE,
   BASE_LOAD_END_DATE   DATE,
   BASE_LOAD_TEMPLATE_ID NUMBER(9),
   BASE_LOAD_SEASON_ID  NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_USAGE_WRF_SEASON primary key (WRF_ID, TEMPLATE_ID, SEASON_ID, AS_OF_DATE)
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

/*==============================================================*/
/* Index: FK_USAGE_WRF_SEASON_SEASON                            */
/*==============================================================*/
create index FK_USAGE_WRF_SEASON_SEASON on USAGE_WRF_SEASON (
   SEASON_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_USAGE_WRF_SEASON_SEASON2                           */
/*==============================================================*/
create index FK_USAGE_WRF_SEASON_SEASON2 on USAGE_WRF_SEASON (
   BASE_LOAD_SEASON_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
/*==============================================================*/
/* Index: FK_USAGE_WRF_SEASON_TEMPLATE                          */
/*==============================================================*/
create index FK_USAGE_WRF_SEASON_TEMPLATE on USAGE_WRF_SEASON (
   BASE_LOAD_TEMPLATE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: USAGE_WRF_STATISTICS                                  */
/*==============================================================*/


create table USAGE_WRF_STATISTICS  (
   WRF_ID               NUMBER(9)                        not null,
   TEMPLATE_ID          NUMBER(9)                        not null,
   SEGMENT_NBR          NUMBER(1)                        not null,
   AS_OF_DATE           DATE                             not null,
   OBSERVATIONS         NUMBER(8),
   DEFAULT_ASSIGNMENTS  NUMBER(6),
   AVG_ALPHA            NUMBER(8,4),
   AVG_BETA             NUMBER(8,4),
   STD_ALPHA            NUMBER(8,4),
   STD_BETA             NUMBER(8,4),
   STD_ALPHA_N_1        NUMBER(6),
   STD_BETA_N_1         NUMBER(6),
   STD_ALPHA_N_2        NUMBER(6),
   STD_BETA_N_2         NUMBER(6),
   STD_ALPHA_N_3        NUMBER(6),
   STD_BETA_N_3         NUMBER(6),
   WRF_MIN              NUMBER(8,2),
   WRF_MAX              NUMBER(8,2),
   R2_MIN               NUMBER(8,6),
   R2_MAX               NUMBER(8,6),
   AVG_Y_MIN            NUMBER(8,4),
   AVG_Y_MAX            NUMBER(8,4),
   AVG_Y_LOW_WARNING    NUMBER(8,4),
   AVG_Y_HIGH_WARNING   NUMBER(8,4),
   BEGIN_DATE           DATE,
   END_DATE             DATE,
   LAST_RUN_STATUS      VARCHAR2(16),
   LAST_RUN_DATE        DATE,
   constraint PK_USAGE_WRF_STATISTICS primary key (WRF_ID, TEMPLATE_ID, SEGMENT_NBR, AS_OF_DATE)
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

/*==============================================================*/
/* Table: USAGE_WRF_TEMPLATE                                    */
/*==============================================================*/


create table USAGE_WRF_TEMPLATE  (
   WRF_ID               NUMBER(9)                        not null,
   TEMPLATE_ID          NUMBER(9)                        not null,
   ALPHA                NUMBER(8,4),
   BETA                 NUMBER(8,4),
   EXTEND_BEGIN_DAYS    NUMBER(4),
   EXTEND_END_DAYS      NUMBER(4),
   PARAMETER_MIN        NUMBER(8,2),
   PARAMETER_MAX        NUMBER(8,2),
   PARAMETER_MIN_TOLERANCE NUMBER(7,4),
   PARAMETER_MAX_TOLERANCE NUMBER(7,4),
   BASE_LOAD_TEMPLATE_ID NUMBER(9),
   ENTRY_DATE           DATE,
   constraint PK_USAGE_WRF_TEMPLATE primary key (WRF_ID, TEMPLATE_ID)
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

/*==============================================================*/
/* Index: FK_USAGE_WRF_TEMPLATE_TEMPLAT2                        */
/*==============================================================*/
create index FK_USAGE_WRF_TEMPLATE_TEMPLAT2 on USAGE_WRF_TEMPLATE (
   BASE_LOAD_TEMPLATE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Index: FK_USAGE_WRF_TEMPLATE_TEMPLATE                        */
/*==============================================================*/
create index FK_USAGE_WRF_TEMPLATE_TEMPLATE on USAGE_WRF_TEMPLATE (
   TEMPLATE_ID ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Table: VERSION                                               */
/*==============================================================*/


create table VERSION  (
   VERSION_DOMAIN       VARCHAR2(32)                     not null,
   VERSION_NAME         VARCHAR2(32)                     not null,
   VERSION_ALIAS        VARCHAR2(32),
   VERSION_DESC         VARCHAR2(256),
   VERSION_ID           NUMBER(9),
   AS_OF_DATE           DATE,
   UNTIL_DATE           DATE,
   VERSION_STATUS       VARCHAR2(32),
   VERSION_REQUESTOR    VARCHAR2(32),
   ENTRY_DATE           DATE,
   constraint PK_VERSION primary key (VERSION_DOMAIN, VERSION_NAME)
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

/*==============================================================*/
/* Table: VIRTUAL_POWER_PLANT                                   */
/*==============================================================*/


create table VIRTUAL_POWER_PLANT (
  VPP_ID              NUMBER(9) not null,
  VPP_NAME            VARCHAR2(64) not null,
  VPP_ALIAS           VARCHAR2(32),
  VPP_DESC            VARCHAR2(256),
  EXTERNAL_IDENTIFIER VARCHAR2(64),
  STATUS_NAME         VARCHAR2(32),
  SERVICE_ZONE_ID     NUMBER(9),
  PROGRAM_ID          NUMBER(9),
  ENTRY_DATE          DATE not null,
   constraint PK_VIRTUAL_POWER_PLANT primary key (VPP_ID)
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

alter table VIRTUAL_POWER_PLANT
   add constraint AK_VIRTUAL_POWER_PLANT unique (VPP_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

alter table VIRTUAL_POWER_PLANT
  add constraint AK_VPP_PROG_SERVICE_ZONE unique (SERVICE_ZONE_ID, PROGRAM_ID)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/

/*==============================================================*/
/* INDEX: FK_VPP_PROGRAM                                        */
/*==============================================================*/
CREATE INDEX FK_VPP_PROGRAM ON VIRTUAL_POWER_PLANT (
   PROGRAM_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: VPP_PEAK_CAPACITY_DESIGN                              */
/*==============================================================*/


create table VPP_PEAK_CAPACITY_DESIGN (
  VPP_ID              NUMBER(9)     not null,
  DESIGN_DAY          DATE          not null,
  CUT_BEGIN_DATE   DATE         not null,
  CUT_END_DATE      DATE         not null,
  SCENARIO_ID         NUMBER(9)     not null,
  PROCESS_ID          NUMBER(12)    not null,
   constraint PK_VPP_PEAK_CAPACITY_DESIGN primary key (VPP_ID)
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

/*==============================================================*/
/* INDEX: FK_VPP_PEAK_CAPACITY_PROC                             */
/*==============================================================*/
CREATE INDEX FK_VPP_PEAK_CAPACITY_PROC ON VPP_PEAK_CAPACITY_DESIGN (
   PROCESS_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* INDEX: FK_VPP_PEAK_CAPACITY_SCEN                             */
/*==============================================================*/
CREATE INDEX FK_VPP_PEAK_CAPACITY_SCEN ON VPP_PEAK_CAPACITY_DESIGN (
   SCENARIO_ID ASC
)
STORAGE
(
    INITIAL 64K
    NEXT 64K
    PCTINCREASE 0
)
TABLESPACE NERO_INDEX
/


/*==============================================================*/
/* Table: WEATHER_PARAMETER                                     */
/*==============================================================*/


create table WEATHER_PARAMETER  (
   PARAMETER_ID         NUMBER(9)                        not null,
   PARAMETER_NAME       VARCHAR2(32)                     not null,
   PARAMETER_ALIAS      VARCHAR2(32),
   PARAMETER_DESC       VARCHAR2(256),
   PARAMETER_CATEGORY   VARCHAR2(32),
   PARAMETER_INTERVAL   VARCHAR2(16),
   PARAMETER_MEASUREMENT VARCHAR2(16),
   PROJECTION_PERIOD    VARCHAR2(16),
   IS_COMPOSITE         NUMBER(1),
   IS_CALCULATE         NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_WEATHER_PARAMETER primary key (PARAMETER_ID)
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


alter table WEATHER_PARAMETER
   add constraint AK_WEATHER_PARAMETER unique (PARAMETER_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: WEATHER_PARAMETER_COMPOSITE                           */
/*==============================================================*/


create table WEATHER_PARAMETER_COMPOSITE  (
   PARAMETER_ID         NUMBER(9)                        not null,
   COMPOSITE_PARAMETER_ID NUMBER(9)                        not null,
   COMPOSITE_COEFFICIENT NUMBER(12,6),
   constraint PK_WEATHER_PARAMETER_COMPOSITE primary key (PARAMETER_ID, COMPOSITE_PARAMETER_ID)
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


/*==============================================================*/
/* Table: WEATHER_STATION                                       */
/*==============================================================*/


create table WEATHER_STATION  (
   STATION_ID           NUMBER(9)                        not null,
   STATION_NAME         VARCHAR2(32)                     not null,
   STATION_ALIAS        VARCHAR2(32),
   STATION_DESC         VARCHAR2(256),
   TIME_ZONE            VARCHAR2(16),
   IS_COMPOSITE         NUMBER(1),
   ENTRY_DATE           DATE,
   constraint PK_WEATHER_STATION primary key (STATION_ID)
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


alter table WEATHER_STATION
   add constraint AK_WEATHER_STATION unique (STATION_NAME)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: WEATHER_STATION_COMPOSITE                             */
/*==============================================================*/


create table WEATHER_STATION_COMPOSITE  (
   STATION_ID           NUMBER(9)                        not null,
   COMPOSITE_STATION_ID NUMBER(9)                        not null,
   COMPOSITE_PERCENT    NUMBER(6,2),
   constraint PK_WEATHER_STATION_COMPOSITE primary key (STATION_ID, COMPOSITE_STATION_ID)
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


/*==============================================================*/
/* Table: WEATHER_STATION_PARAMETER                             */
/*==============================================================*/


create table WEATHER_STATION_PARAMETER  (
   STATION_ID           NUMBER(9)                        not null,
   PARAMETER_ID         NUMBER(9)                        not null,
   constraint PK_WEATHER_STATION_PARAMETER primary key (STATION_ID, PARAMETER_ID)
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


/*==============================================================*/
/* Table: WRF_ACCOUNTS_TO_RUN_TEMP                              */
/*==============================================================*/


create global temporary table WRF_ACCOUNTS_TO_RUN_TEMP  (
   ACCOUNT_ID           NUMBER(9)                        not null,
   constraint PK_WRF_ACCOUNTS_TO_RUN_TEMP primary key (ACCOUNT_ID)
)
on commit preserve rows
/


/*==============================================================*/
/* Table: WRF_BATCH_RUN_WEATHER                                 */
/*==============================================================*/


create global temporary table WRF_BATCH_RUN_WEATHER  (
   PARAMETER_DATE       DATE                             not null,
   HOUR                 NUMBER(2)                        not null,
   PARAMETER_1          NUMBER(8,2),
   PARAMETER_2          NUMBER(8,2),
   PARAMETER_3          NUMBER(8,2),
   PARAMETER_4          NUMBER(8,2),
   PARAMETER_5          NUMBER(8,2),
   constraint PK_WRF_BATCH_RUN_WEATHER primary key (PARAMETER_DATE)
)
on commit preserve rows
/


/*==============================================================*/
/* Index: WRF_BATCH_RUN_WEATHER_IX01                            */
/*==============================================================*/
create index WRF_BATCH_RUN_WEATHER_IX01 on WRF_BATCH_RUN_WEATHER (
   HOUR ASC,
   PARAMETER_1 ASC
)
/


/*==============================================================*/
/* Table: WRF_FCM                                               */
/*==============================================================*/


create table WRF_FCM  (
   FCM_ID               NUMBER(9)                        not null,
   PROFILE_ID           NUMBER(9)                        not null,
   HOUR_NUM             NUMBER(3)                        not null,
   START_DATE           DATE                             not null,
   STOP_DATE            DATE,
   NUM_VARS             NUMBER(1)                        not null,
   constraint PK_WRF_FCM primary key (FCM_ID)
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


alter table WRF_FCM
   add constraint AK_WRF_FCM unique (PROFILE_ID, HOUR_NUM)
      using index
    tablespace NERO_INDEX
    storage
    (
        initial 64K
        next 64K
        pctincrease 0
    )
/


/*==============================================================*/
/* Table: WRF_FCM_CANDIDATE                                     */
/*==============================================================*/


create table WRF_FCM_CANDIDATE  (
   FCM_ID               NUMBER(9)                        not null,
   NUM_SEGMENTS         NUMBER(1)                        not null,
   NUM_ITERATIONS       NUMBER(4),
   MAPE                 NUMBER,
   P_MAX                NUMBER,
   P_MIN                NUMBER,
   P_NZMIN              NUMBER,
   P_SUM                NUMBER,
   P_COUNT              NUMBER,
   P_ERR_SUM            NUMBER,
   R2MAX                NUMBER,
   R2MIN                NUMBER,
   R2TOTAL_COUNT        NUMBER,
   R2FAIL_COUNT         NUMBER,
   T_TEMP_COUNT         NUMBER,
   T_HUMID_COUNT        NUMBER,
   T_WIND_COUNT         NUMBER,
   constraint PK_WRF_FCM_CANDIDATE primary key (FCM_ID, NUM_SEGMENTS)
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


/*==============================================================*/
/* Table: WRF_FCM_CLUSTER                                       */
/*==============================================================*/


create table WRF_FCM_CLUSTER  (
   FCM_ID               NUMBER(9)                        not null,
   NUM_SEGMENTS         NUMBER(1)                        not null,
   CLUSTER_NUM          NUMBER(3)                        not null,
   CENTER_X             NUMBER                           not null,
   CENTER_Y             NUMBER                           not null,
   SEGMENT_MIN          NUMBER(8,2),
   SEGMENT_MAX          NUMBER(8,2),
   COEFF_0              NUMBER(16,8),
   COEFF_1              NUMBER(16,8),
   COEFF_2              NUMBER(16,8),
   COEFF_3              NUMBER(16,8),
   COEFF_4              NUMBER(16,8),
   COEFF_5              NUMBER(16,8),
   TSTAT_0              NUMBER(16,8),
   TSTAT_1              NUMBER(16,8),
   TSTAT_2              NUMBER(16,8),
   TSTAT_3              NUMBER(16,8),
   TSTAT_4              NUMBER(16,8),
   TSTAT_5              NUMBER(16,8),
   R_SQUARED            NUMBER(16,8),
   TSTAT_CRITICAL       NUMBER(16,8),
   constraint PK_WRF_FCM_CLUSTER primary key (FCM_ID, NUM_SEGMENTS, CLUSTER_NUM)
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


/*==============================================================*/
/* Table: WRF_FCM_CLUSTER_ASSIGNMENT                            */
/*==============================================================*/


create table WRF_FCM_CLUSTER_ASSIGNMENT  (
   FCM_ID               NUMBER(9)                        not null,
   NUM_SEGMENTS         NUMBER(1)                        not null,
   OBSERVATION_NUM      NUMBER(12)                       not null,
   CLUSTER_NUM          NUMBER(3)                        not null,
   APE                  NUMBER,
   constraint PK_WRF_FCM_CLUSTER_ASSIGNMENT primary key (FCM_ID, NUM_SEGMENTS, OBSERVATION_NUM)
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


/*==============================================================*/
/* Index: WRF_FCM_CLUSTER_ASSIGNMENT_IX1                        */
/*==============================================================*/
create index WRF_FCM_CLUSTER_ASSIGNMENT_IX1 on WRF_FCM_CLUSTER_ASSIGNMENT (
   FCM_ID ASC,
   NUM_SEGMENTS ASC,
   CLUSTER_NUM ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/


/*==============================================================*/
/* Index: FK_WRF_FCM_OBSERVATION_ASSIGN                         */
/*==============================================================*/
create index FK_WRF_FCM_OBSERVATION_ASSIGN on WRF_FCM_CLUSTER_ASSIGNMENT (
   FCM_ID ASC, OBSERVATION_NUM ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: WRF_FCM_CLUSTER_MEMBERSHIP                            */
/*==============================================================*/


create table WRF_FCM_CLUSTER_MEMBERSHIP  (
   FCM_ID               NUMBER(9)                        not null,
   NUM_SEGMENTS         NUMBER(1)                        not null,
   CLUSTER_NUM          NUMBER(3)                        not null,
   OBSERVATION_NUM      NUMBER(12)                       not null,
   MEMBERSHIP           NUMBER                           not null,
   constraint PK_WRF_FCM_CLUSTER_MEMBERSHIP primary key (FCM_ID, NUM_SEGMENTS, CLUSTER_NUM, OBSERVATION_NUM)
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


/*==============================================================*/
/* Index: FK_WRF_FCM_OBSERVATION_MEMBER                         */
/*==============================================================*/
create index FK_WRF_FCM_OBSERVATION_MEMBER on WRF_FCM_CLUSTER_MEMBERSHIP (
   FCM_ID ASC, OBSERVATION_NUM ASC
)
storage
(
    initial 64K
    next 64K
    pctincrease 0
)
tablespace NERO_INDEX
/
 
 
/*==============================================================*/
/* Table: WRF_FCM_OBSERVATION                                   */
/*==============================================================*/


create table WRF_FCM_OBSERVATION  (
   FCM_ID               NUMBER(9)                        not null,
   OBSERVATION_NUM      NUMBER(6)                        not null,
   OBSERVATION_X        NUMBER                           not null,
   OBSERVATION_Y        NUMBER                           not null,
   OBSERVATION_P2       NUMBER,
   OBSERVATION_P3       NUMBER,
   OBSERVATION_P4       NUMBER,
   OBSERVATION_P5       NUMBER,
   constraint PK_WRF_FCM_OBSERVATION primary key (FCM_ID, OBSERVATION_NUM)
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


/*==============================================================*/
/* Table: WRF_TEMPLATES_TO_RUN_TEMP                             */
/*==============================================================*/


create global temporary table WRF_TEMPLATES_TO_RUN_TEMP  (
   TEMPLATE_ID          NUMBER(9)                        not null,
   constraint PK_WRF_TEMPLATES_TO_RUN_TEMP primary key (TEMPLATE_ID)
)
on commit preserve rows
/  


alter table APPLICATION_USER_PREFERENCES
   add constraint FK_APPLICATION_USER_PREF foreign key (USER_ID)
      references APPLICATION_USER (USER_ID)
      on delete cascade
/


alter table APPLICATION_USER_ROLE
   add constraint FK_APPLICATION_ROLE_ID foreign key (ROLE_ID)
      references APPLICATION_ROLE (ROLE_ID)
      on delete cascade
/


alter table APPLICATION_USER_ROLE
   add constraint FK_APPLICATION_USER_ID foreign key (USER_ID)
      references APPLICATION_USER (USER_ID)
      on delete cascade
/

ALTER TABLE BILL_CASE
  ADD CONSTRAINT AK_BILL_CASE_NAME UNIQUE (BILL_CASE_NAME)
/


ALTER TABLE BILL_CASE
  ADD CONSTRAINT FK_BILL_CASE_SENDER_PSE_ID FOREIGN KEY (SENDER_PSE_ID)
    REFERENCES PURCHASING_SELLING_ENTITY(PSE_ID)
/


ALTER TABLE BILL_CASE
  ADD CONSTRAINT FK_BILL_CASE_STATEMENT_TYPE_ID FOREIGN KEY (STATEMENT_TYPE_ID)
  REFERENCES STATEMENT_TYPE (STATEMENT_TYPE_ID)
/

ALTER TABLE BILL_CASE_SELECTIONS
  ADD CONSTRAINT FK_BC_SELECTIONS_BILL_CASE_ID FOREIGN KEY (BILL_CASE_ID)
  REFERENCES BILL_CASE(BILL_CASE_ID)
  ON DELETE CASCADE
/

ALTER TABLE BILL_CASE_SELECTIONS
  ADD CONSTRAINT FK_BC_SELECTIONS_PSE_ID FOREIGN KEY (PSE_ID)
  REFERENCES PURCHASING_SELLING_ENTITY(PSE_ID)
  ON DELETE CASCADE
/

ALTER TABLE BILL_CASE_SELECTIONS
  ADD CONSTRAINT FK_BC_SELECTIONS_ACCOUNT_ID FOREIGN KEY (ACCOUNT_ID)
  REFERENCES ACCOUNT(ACCOUNT_ID)
  ON DELETE CASCADE
/

ALTER TABLE BILL_CASE_SELECTIONS
  ADD CONSTRAINT FK_BC_SELECTIONS_PRODUCT_ID FOREIGN KEY (PRODUCT_ID)
  REFERENCES PRODUCT(PRODUCT_ID)
  ON DELETE CASCADE
/

ALTER TABLE BILL_CASE_SELECTIONS
  ADD CONSTRAINT FK_BC_SELECTIONS_COMPONENT_ID FOREIGN KEY (COMPONENT_ID)
  REFERENCES COMPONENT(COMPONENT_ID)
  ON DELETE CASCADE
/


alter table BILL_CASE_INVOICE
  add constraint FK_BILL_CASE_ID foreign key (BILL_CASE_ID)
  references BILL_CASE (BILL_CASE_ID)
  on delete cascade
/


alter table BILL_CASE_INVOICE
  add constraint FK_RETAIL_INVOICE_ID foreign key (RETAIL_INVOICE_ID)
  references RETAIL_INVOICE (RETAIL_INVOICE_ID)
  on delete cascade
/


alter table BILLING_CHARGE_DISPUTE
  add constraint FK_BILLING_CHRG_DSPT_COMP foreign key (COMPONENT_ID)
  references COMPONENT (COMPONENT_ID) on delete cascade

/

alter table BILLING_CHARGE_DISPUTE
  add constraint FK_BILLING_CHRG_DSPT_PROD foreign key (PRODUCT_ID)
  references PRODUCT (PRODUCT_ID) on delete cascade
/

alter table BILLING_CHARGE_DISPUTE
  add constraint FK_BILLING_CHRG_DSPT_PSE foreign key (ENTITY_ID)
  references PURCHASING_SELLING_ENTITY (PSE_ID) on delete cascade
/

alter table BILLING_CHARGE_DISPUTE
  add constraint FK_BILLING_CHRG_DSPT_STMT foreign key (STATEMENT_TYPE)
  references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table BILLING_STATEMENT
   add constraint FK_BILLING_STMT_COMPONENT foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table BILLING_STATEMENT
   add constraint FK_BILLING_STMT_PSE foreign key (ENTITY_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade
/


alter table BILLING_STATEMENT
   add constraint FK_BILLING_STMT_STMT_TYPE foreign key (STATEMENT_TYPE)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table BILLING_STATEMENT_LOCK_SUMMARY
   add constraint FK_BILLING_STMT_LK_S_COMPONENT foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table BILLING_STATEMENT_LOCK_SUMMARY
   add constraint FK_BILLING_STMT_LK_SPRODUCT foreign key (PRODUCT_ID)
      references PRODUCT (PRODUCT_ID)
      on delete cascade
/


alter table BILLING_STATEMENT_LOCK_SUMMARY
   add constraint FK_BILLING_STMT_LK_S_PSE foreign key (ENTITY_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade
/


alter table BILLING_STATEMENT_LOCK_SUMMARY
   add constraint FK_BILLING_STMT_LK_S_STMT_TYPE foreign key (STATEMENT_TYPE)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table BILLING_STATEMENT_STATUS
   add constraint FK_BILLING_STMT_STATUS_PSE foreign key (ENTITY_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade
/


alter table BILLING_STATEMENT_STATUS
   add constraint FK_BILLING_STMT_STATUS_STMT foreign key (STATEMENT_TYPE)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table CALCULATION_PROCESS
   add constraint FK_CALCULATION_PROCESS_DOMAIN foreign key (CONTEXT_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table CALCULATION_PROCESS
   add constraint FK_CALCULATION_PROCESS_GROUP foreign key (CONTEXT_GROUP_ID)
      references ENTITY_GROUP (ENTITY_GROUP_ID)
/


alter table CALCULATION_PROCESS
   add constraint FK_CALCULATION_PROCESS_REALM foreign key (CONTEXT_REALM_ID)
      references SYSTEM_REALM (REALM_ID)
/


alter table CALCULATION_PROCESS_GLOBAL
   add constraint FK_CALCULATION_PROCESS_GLOBAL foreign key (CALC_PROCESS_ID)
      references CALCULATION_PROCESS (CALC_PROCESS_ID)
      on delete cascade
/


alter table CALCULATION_PROCESS_SECURITY
   add constraint FK_CALC_PROCESS_SECURITY foreign key (CALC_PROCESS_ID)
      references CALCULATION_PROCESS (CALC_PROCESS_ID)
      on delete cascade
/


alter table CALCULATION_PROCESS_SECURITY
   add constraint FK_CALC_PROC_SECURITY_ACTION1 foreign key (SELECT_ACTION_ID)
      references SYSTEM_ACTION (ACTION_ID)
/


alter table CALCULATION_PROCESS_SECURITY
   add constraint FK_CALC_PROC_SECURITY_ACTION2 foreign key (RUN_ACTION_ID)
      references SYSTEM_ACTION (ACTION_ID)
/


alter table CALCULATION_PROCESS_SECURITY
   add constraint FK_CALC_PROC_SECURITY_ACTION3 foreign key (PURGE_ACTION_ID)
      references SYSTEM_ACTION (ACTION_ID)
/


alter table CALCULATION_PROCESS_STEP
   add constraint FK_CALCULATION_PROCESS_STEP foreign key (CALC_PROCESS_ID)
      references CALCULATION_PROCESS (CALC_PROCESS_ID)
      on delete cascade
/


alter table CALCULATION_PROCESS_STEP
   add constraint FK_CALCULATION_PROC_STEP_COMP foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
/


alter table CALCULATION_PROCESS_STEP_PARM
   add constraint FK_CALCULATION_PROC_STEP_PARM foreign key (CALC_STEP_ID)
      references CALCULATION_PROCESS_STEP (CALC_STEP_ID)
      on delete cascade
/


alter table CALCULATION_RUN
   add constraint FK_CALCULATION_RUN_PROCESS foreign key (CALC_PROCESS_ID)
      references CALCULATION_PROCESS (CALC_PROCESS_ID)
      on delete cascade
/


alter table CALCULATION_RUN
   add constraint FK_CALCULATION_RUN_PROCESS_LOG foreign key (PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/


alter table CALCULATION_RUN
   add constraint FK_CALCULATION_RUN_STMNT_TYPE foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
      on delete cascade
/


alter table CALCULATION_RUN_GLOBAL
   add constraint FK_CALCULATION_RUN_GLOBAL foreign key (CALC_RUN_ID)
      references CALCULATION_RUN (CALC_RUN_ID)
      on delete cascade
/


alter table CALCULATION_RUN_LOCK_SUMMARY
   add constraint FK_CALC_RUN_LOCK_S_PROCESS foreign key (CALC_PROCESS_ID)
      references CALCULATION_PROCESS (CALC_PROCESS_ID)
      on delete cascade
/


alter table CALCULATION_RUN_LOCK_SUMMARY
   add constraint FK_CALC_RUN_LOCK_S_STMNT_TYPE foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
      on delete cascade
/


alter table CALCULATION_RUN_STEP
   add constraint FK_CALCULATION_RUN_STEP foreign key (CALC_RUN_ID)
      references CALCULATION_RUN (CALC_RUN_ID)
      on delete cascade
/


alter table CALCULATION_RUN_STEP
   add constraint FK_CALCULATION_RUN_STEP_COMP foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table CALCULATION_RUN_STEP_PARM
   add constraint FK_CALCULATION_RUN_STEP_PARM foreign key (CHARGE_ID)
      references CALCULATION_RUN_STEP (CHARGE_ID)
      on delete cascade
/


alter table COMPONENT_FORMULA_ENTITY_REF
   add constraint FK_COMPONENT_FML_ENTITY_REF foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table COMPONENT_FORMULA_ENTITY_REF
   add constraint FK_COMPONENT_FML_ENTITY_REF_DM foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table COMPONENT_FORMULA_INPUT
   add constraint FK_COMPONENT_FML_INPUT_DOMAIN foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table COMPONENT_FORMULA_INPUT
   add constraint FK_COMPONENT_FORMULA_INPUT foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table COMPONENT_FORMULA_ITERATOR
   add constraint FK_COMPONENT_FORMULA_ITERATOR foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table COMPONENT_FORMULA_PARAMETER
   add constraint FK_COMPONENT_FORMULA_PARAMETER foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table COMPONENT_FORMULA_RESULT
   add constraint FK_COMPONENT_FML_RESULT_DOMAIN foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table COMPONENT_FORMULA_RESULT
   add constraint FK_COMPONENT_FORMULA_RESULT foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table COMPONENT_FORMULA_VARIABLE
   add constraint FK_COMPONENT_FORMULA_VARIABLE foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
      on delete cascade
/


alter table CONDITIONAL_FORMAT_ITEM
   add constraint FK_CONDITIONAL_FORMAT_ITEM foreign key (CONDITIONAL_FORMAT_ID)
      references CONDITIONAL_FORMAT (CONDITIONAL_FORMAT_ID)
      on delete cascade
/


alter table CRYSTAL_REPORT_FILES
   add constraint FK_CRYSTAL_REPORT_FILES_OBJ foreign key (OBJECT_ID)
      references SYSTEM_OBJECT (OBJECT_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_DER foreign key (DER_ID)
      references DISTRIBUTED_ENERGY_RESOURCE (DER_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_LSR foreign key (LOAD_SHAPE_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_TXLOSS foreign key (TX_LOSS_FACTOR_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_DXLOSS foreign key (DX_LOSS_FACTOR_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_HITS foreign key (HITS_REMAINING_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_DER_TYPE foreign key (DER_TYPE_ID)
      references DER_TYPE (DER_TYPE_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_EXTSYS foreign key (EXTERNAL_SYSTEM_ID)
      references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_PROGRAM foreign key (PROGRAM_ID)
      references PROGRAM (PROGRAM_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_ZONE foreign key (SERVICE_ZONE_ID)
      references SERVICE_ZONE (SERVICE_ZONE_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_SS foreign key (SUB_STATION_ID)
      references TX_SUB_STATION (SUB_STATION_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_FEEDER foreign key (FEEDER_ID)
      references TX_FEEDER (FEEDER_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_SEGMENT foreign key (FEEDER_SEGMENT_ID)
      references TX_FEEDER_SEGMENT (FEEDER_SEGMENT_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_ACCOUNT foreign key (ACCOUNT_ID)
      references ACCOUNT (ACCOUNT_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_SL foreign key (SERVICE_LOCATION_ID)
      references SERVICE_LOCATION (SERVICE_LOCATION_ID)
      on delete cascade
/

alter table DER_DAILY_RESULT
   add constraint FK_DER_DAILY_RESULT_EDC foreign key (EDC_ID)
      references ENERGY_DISTRIBUTION_COMPANY (EDC_ID)
      on delete cascade
/


alter table ENTITY_GRAVEYARD
   add constraint FK_ENTITY_GRAVEYARD_DOMAIN foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
      on delete cascade
/


alter table ENTITY_GRAVEYARD_REALM
   add constraint FK_ENTITY_GRAVEYARD foreign key (ENTITY_DOMAIN_ID, ENTITY_ID)
      references ENTITY_GRAVEYARD (ENTITY_DOMAIN_ID, ENTITY_ID)
      on delete cascade
/

alter table ENTITY_GRAVEYARD_REALM
   add constraint FK_ENTITY_GRAVEYARD_REALM foreign key (REALM_ID)
      references SYSTEM_REALM (REALM_ID)
      on delete cascade
/


alter table ENTITY_GROUP
   add constraint FK_PARENT_ENTITY_GROUP foreign key (PARENT_GROUP_ID)
      references ENTITY_GROUP (ENTITY_GROUP_ID)
/


alter table ENTITY_GROUP_ASSIGNMENT
   add constraint FK_ENTITY_GROUP foreign key (ENTITY_GROUP_ID)
      references ENTITY_GROUP (ENTITY_GROUP_ID)
      on delete cascade
/


alter table ETAG_LIST
   add constraint FK_ETAG_LIST foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_LIST_ITEM
   add constraint FK_ETAG_LIST_ITEM foreign key (ETAG_ID, ETAG_LIST_ID)
      references ETAG_LIST (ETAG_ID, ETAG_LIST_ID)
      on delete cascade
/


alter table ETAG_LOSS_METHOD
   add constraint FK_ETAG_LOSS_METHOD foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_MARKET_SEGMENT
   add constraint FK_ETAG_MARKET_SEGMENT foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_MESSAGE_INFO
   add constraint FK_ETAG_MESSAGE_INFO foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_PROFILE
   add constraint FK_ETAG_PROFILE foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_PROFILE_LIST
   add constraint FK1_ETAG_PROFILE_LIST foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_PROFILE_LIST
   add constraint FK2_ETAG_PROFILE_LIST foreign key (PROFILE_KEY_ID)
      references ETAG_PROFILE (PROFILE_KEY_ID)
      on delete cascade
/


alter table ETAG_PROFILE_LIST
   add constraint FK3_ETAG_PROFILE_LIST foreign key (ETAG_ID, ETAG_LIST_ID)
      references ETAG_LIST (ETAG_ID, ETAG_LIST_ID)
      on delete cascade
/


alter table ETAG_PROFILE_VALUE
   add constraint FK_ETAG_PROFILE_VALUE foreign key (PROFILE_KEY_ID)
      references ETAG_PROFILE (PROFILE_KEY_ID)
      on delete cascade
/


alter table ETAG_RESOURCE
   add constraint FK_ETAG_RESOURCE foreign key (ETAG_ID, PHYSICAL_SEGMENT_NID)
      references ETAG_RESOURCE_SEGMENT (ETAG_ID, PHYSICAL_SEGMENT_NID)
      on delete cascade
/


alter table ETAG_RESOURCE_SEGMENT
   add constraint FK_ETAG_RESOURCE_SEGMENT foreign key (ETAG_ID, MARKET_SEGMENT_NID)
      references ETAG_MARKET_SEGMENT (ETAG_ID, MARKET_SEGMENT_NID)
      on delete cascade
/


alter table ETAG_STATUS
   add constraint FK_ETAG_STATUS foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_TRANSACTION
   add constraint FK1_ETAG_TRANSACTION foreign key (ETAG_ID)
      references ETAG (ETAG_ID)
      on delete cascade
/


alter table ETAG_TRANSACTION
   add constraint FK_ETAG_TRANSACTION_IT foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table ETAG_TRANSMISSION_ALLOCATION
   add constraint FK_ETAG_TRANSMISSION_ALLOCATN foreign key (ETAG_ID, PHYSICAL_SEGMENT_NID)
      references ETAG_TRANSMISSION_SEGMENT (ETAG_ID, PHYSICAL_SEGMENT_NID)
      on delete cascade
/


alter table ETAG_TRANSMISSION_PROFILE
   add constraint FK_ETAG_TRANSMISSION_PROFILE foreign key (ETAG_ID, PHYSICAL_SEGMENT_NID)
      references ETAG_TRANSMISSION_SEGMENT (ETAG_ID, PHYSICAL_SEGMENT_NID)
      on delete cascade
/


alter table ETAG_TRANSMISSION_SEGMENT
   add constraint FK_ETAG_TRANSMISSION_SEGMENT foreign key (ETAG_ID, MARKET_SEGMENT_NID)
      references ETAG_MARKET_SEGMENT (ETAG_ID, MARKET_SEGMENT_NID)
      on delete cascade
/


alter table EXTERNAL_CREDENTIALS
   add constraint FK_EXTERNAL_CREDENTIALS_USERS foreign key (USER_ID)
      references APPLICATION_USER (USER_ID)
      on delete cascade
/


alter table EXTERNAL_CREDENTIALS
   add constraint FK_EXTERNAL_CREDENTIALS foreign key (EXTERNAL_SYSTEM_ID)
      references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
      on delete cascade
/


alter table EXTERNAL_CREDENTIALS_CERT
   add constraint FK_EXTERNAL_CREDENTIALS_CERT foreign key (CREDENTIAL_ID)
      references EXTERNAL_CREDENTIALS (CREDENTIAL_ID)
      on delete cascade
/


alter table EXTERNAL_SYSTEM
   add constraint FK_EXTERNAL_SYSTEM_ACCOUNT foreign key (EXTERNAL_ACCOUNT_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
      on delete set null
/


alter table EXTERNAL_SYSTEM_IDENTIFIER
   add constraint FK_EXTERNAL_SYSTEM_IDENTIFIER foreign key (EXTERNAL_SYSTEM_ID)
      references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
      on delete cascade
/

alter table DATA_LOCK_GROUP_ITEM
   add constraint FK_DATA_LOCK_GROUP_ITEM_GROUP foreign key (DATA_LOCK_GROUP_ID)
      references DATA_LOCK_GROUP (DATA_LOCK_GROUP_ID)
      on delete cascade
/

alter table DATA_LOCK_GROUP_ITEM
   add constraint FK_DATA_LOCK_GROUP_ITEM_TABLE foreign key (TABLE_ID)
      references SYSTEM_TABLE (TABLE_ID)
/

alter table DATA_LOCK_GROUP_ITEM
   add constraint FK_DATA_LOCK_GROUP_ITEM_DOMAIN foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/

alter table DATA_LOCK_GROUP_ITEM_CRITERIA
   add constraint FK_DATA_LOCK_GROUP_ITEM_CRIT foreign key (DATA_LOCK_GROUP_ITEM_ID)
      references DATA_LOCK_GROUP_ITEM (DATA_LOCK_GROUP_ITEM_ID)
      on delete cascade
/

alter table DER_PROGRAM
   add constraint FK_DER_PROGRAM_DER foreign key (DER_ID)
      references DISTRIBUTED_ENERGY_RESOURCE (DER_ID)
		on delete cascade
/

alter table DER_PROGRAM
   add constraint FK_DER_PROGRAM_PROGRAM foreign key (PROGRAM_ID)
      references PROGRAM (PROGRAM_ID)
      on delete cascade
/

alter table FORMULA_CHARGE
   add constraint FK_FORMULA_CHARGE foreign key (CHARGE_ID, ITERATOR_ID)
      references FORMULA_CHARGE_ITERATOR (CHARGE_ID, ITERATOR_ID)
      on delete cascade
/


alter table FORMULA_CHARGE_ITERATOR
   add constraint FK_FORMULA_CHARGE_ITERATOR foreign key (CHARGE_ID)
      references FORMULA_CHARGE_ITERATOR_NAME (CHARGE_ID)
      on delete cascade
/


alter table FORMULA_CHARGE_VARIABLE
   add constraint FK_FORMULA_CHARGE_VARIABLE foreign key (CHARGE_ID, ITERATOR_ID, CHARGE_DATE)
      references FORMULA_CHARGE (CHARGE_ID, ITERATOR_ID, CHARGE_DATE)
      on delete cascade
/


alter table INTERCHANGE_TRANSACTION_LIMIT
   add constraint FK_INT_TRANS_LMT_IT foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table INVOICE
   add constraint FK_INVOICE_APPROVED_BY foreign key (APPROVED_BY_ID)
      references APPLICATION_USER (USER_ID)
/


alter table INVOICE
   add constraint FK_INVOICE_LAST_SENT_BY foreign key (LAST_SENT_BY_ID)
      references APPLICATION_USER (USER_ID)
/

alter table INVOICE
   add constraint FK_INVOICE_PSE foreign key (ENTITY_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade
/


alter table INVOICE
   add constraint FK_INVOICE_STMT_TYPE foreign key (STATEMENT_TYPE)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table INVOICE_ATTACHMENT
   add constraint FK_INVOICE_ATTACHMENT foreign key (INVOICE_ID)
      references INVOICE (INVOICE_ID)
	  on delete cascade
/

alter table INVOICE_ATTACHMENT
   add constraint FK_INVOICE_ATTCH_USER foreign key (USER_ID)
      references APPLICATION_USER (USER_ID)
/
alter table INVOICE_USER_LINE_ITEM
   add constraint FK_INVOICE_USR_LN_PSE foreign key (ENTITY_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade
/


alter table INVOICE_USER_LINE_ITEM
   add constraint FK_INVOICE_USR_LN_STMT_TYPE foreign key (STATEMENT_TYPE)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table IT_ASSIGNMENT
   add constraint FK_IT_ASSIGNMENT_FROM foreign key (FROM_TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
/


alter table IT_ASSIGNMENT
   add constraint FK_IT_ASSIGNMENT_TO foreign key (TO_TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
/


alter table IT_ASSIGNMENT_OPTION
   add constraint FK_IT_ASSGN_OPTION_FROM foreign key (FROM_TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
/


alter table IT_ASSIGNMENT_OPTION
   add constraint FK_IT_ASSGN_OPTION_OTHER foreign key (OTHER_TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
/


alter table IT_ASSIGNMENT_OPTION
   add constraint FK_IT_ASSGN_OPTION_TO foreign key (TO_TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
/


alter table IT_ASSIGNMENT_PERIOD
   add constraint FK_IT_ASSIGNMENT_PERIOD foreign key (ASSIGNMENT_ID)
      references IT_ASSIGNMENT (ASSIGNMENT_ID)
      on delete cascade
/


alter table IT_ASSIGNMENT_SCHEDULE
   add constraint FK_IT_ASSGN_SCHD_STMNT_TYPE foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table IT_ASSIGNMENT_SCHEDULE
   add constraint FK_IT_ASSIGNMENT_SCHEDULE foreign key (ASSIGNMENT_ID)
      references IT_ASSIGNMENT (ASSIGNMENT_ID)
      on delete cascade
/


alter table IT_ASSIGNMENT_SCHEDULE
   add constraint FK_IT_ASSIGNMENT_OPTION foreign key (OPTION_ID)
      references IT_ASSIGNMENT_OPTION (OPTION_ID)
      on delete cascade
/


alter table IT_SCHEDULE
   add constraint FK_IT_SCHEDULE_IT foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table IT_SCHEDULE
   add constraint FK_IT_SCHEDULE_STMENT_TYPE foreign key (SCHEDULE_TYPE)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/

alter table IT_SCHEDULE_LOCK_SUMMARY
   add constraint FK_IT_SCHEDULE_LOCK_SUMMARY_IT foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table IT_SCHEDULE_LOCK_SUMMARY
   add constraint FK_IT_SCHEDULE_LOCK_SUMMARY_ST foreign key (SCHEDULE_TYPE)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table IT_SEGMENT
   add constraint FK_IT_SEGMENT_INTERCHANGE_TX foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table IT_SEGMENT_SCHEDULE
   add constraint FK_IT_SEGMENT_SCHEDULE_IT_SEG foreign key (IT_SEGMENT_ID)
      references IT_SEGMENT (IT_SEGMENT_ID)
      on delete cascade
/


alter table IT_STATUS
   add constraint FK_IT_STATUS_INTER_STATUS foreign key (TRANSACTION_STATUS_NAME)
      references INTERCHANGE_TRANSACTION_STATUS (TRANSACTION_STATUS_NAME)
/


alter table IT_STATUS
   add constraint FK_IT_STATUS_IT foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table IT_TRAIT_SCHEDULE
   add constraint FK_IT_TRAIT_SCHD_STMT_TYPE foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table IT_TRAIT_SCHEDULE
   add constraint FK_IT_TRAIT_SCHED_TRAIT foreign key (TRAIT_GROUP_ID, TRAIT_INDEX)
      references TRANSACTION_TRAIT (TRAIT_GROUP_ID, TRAIT_INDEX)
/


alter table IT_TRAIT_SCHEDULE
   add constraint FK_IT_TRAIT_SCHED_TXN foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table IT_TRAIT_SCHEDULE_LOCK_SUMMARY
   add constraint FK_IT_TRAIT_SCHD_LK_S_ST_TYPE foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table IT_TRAIT_SCHEDULE_LOCK_SUMMARY
   add constraint FK_IT_TRAIT_SCHED_LK_S_TRAIT foreign key (TRAIT_GROUP_ID)
      references TRANSACTION_TRAIT_GROUP (TRAIT_GROUP_ID)
/


alter table IT_TRAIT_SCHEDULE_LOCK_SUMMARY
   add constraint FK_IT_TRAIT_SCHED_LK_S_TXN foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/

alter table IT_TRAIT_SCHEDULE_STATUS
   add constraint FK_IT_TRAIT_SCHED_ST_REVIEW foreign key (REVIEWED_BY_ID)
      references APPLICATION_USER (USER_ID)
/


alter table IT_TRAIT_SCHEDULE_STATUS
   add constraint FK_IT_TRAIT_SCHED_ST_SUBMIT foreign key (SUBMITTED_BY_ID)
      references APPLICATION_USER (USER_ID)
/


alter table IT_TRAIT_SCHEDULE_STATUS
   add constraint FK_IT_TRAIT_SCHEDULE_STATUS foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table JOB_QUEUE_ITEM
  add constraint FK_JOB_QUEUE_ITEM_USER foreign key (USER_ID)
  	references APPLICATION_USER (USER_ID)
/


alter table JOB_QUEUE_ITEM
  add constraint FK_JOB_QUEUE_ITEM_THREAD foreign key (JOB_THREAD_ID)
  	references JOB_THREAD (JOB_THREAD_ID)
/

alter table LOAD_RESULT_CALENDAR
   add constraint FK_LOAD_RESULT_CALENDAR_CAL foreign key (CALENDAR_ID)
      references CALENDAR (CALENDAR_ID)
/

alter table LOAD_RESULT_CALENDAR
   add constraint FK_LOAD_RESULT_CALENDAR_SCEN foreign key (SCENARIO_ID)
      references SCENARIO (SCENARIO_ID)
      on delete cascade
/

alter table LOAD_RESULT_CALENDAR
   add constraint FK_LOAD_RESULT_CALENDAR_WS foreign key (WEATHER_STATION_ID)
      references WEATHER_STATION (STATION_ID)
/

alter table LOAD_RESULT_CALENDAR
   add constraint FK_LOAD_RESULT_CALENDAR_LR foreign key (LOAD_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
      on delete cascade
/

alter table LOAD_RESULT_DATA
   add constraint FK_LOAD_RESULT_DATA_LR foreign key (LOAD_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
      on delete cascade
/

alter table LOAD_RESULT_ENTITY
   add constraint FK_LOAD_RESULT_ENTITY_ED foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/

alter table LOAD_RESULT_ENTITY
   add constraint FK_LOAD_RESULT_ENTITY_SCEN foreign key (SCENARIO_ID)
      references SCENARIO (SCENARIO_ID)
      on delete cascade
/

alter table LOAD_RESULT_ENTITY
   add constraint FK_LOAD_RESULT_ENTITY_LR foreign key (LOAD_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
      on delete cascade
/

alter table LOAD_RESULT_LOSS_FACTOR
   add constraint FK_LOAD_RESULT_LF_LF foreign key (LOSS_FACTOR_PATTERN_ID)
      references LOSS_FACTOR_MODEL (PATTERN_ID)
/

alter table LOAD_RESULT_LOSS_FACTOR
   add constraint FK_LOAD_RESULT_LF_SCEN foreign key (SCENARIO_ID)
      references SCENARIO (SCENARIO_ID)
      on delete cascade
/

alter table LOAD_RESULT_LOSS_FACTOR
   add constraint FK_LOAD_RESULT_LF_LR foreign key (LOAD_RESULT_ID)
      references LOAD_RESULT (LOAD_RESULT_ID)
      on delete cascade
/

alter table LOAD_SEGMENTATION_DEF
  add constraint LOAD_SEG_DEF_PROCESS_ID_FK foreign key (PROCESS_ID)
  references PROCESS_LOG(PROCESS_ID) 
  on delete set null
/

alter table LOAD_SEGMENTATION_DEF_DETAILS
 add constraint FK_LOAD_SEG_DEF_DTLS_REP_ID foreign key (REPORT_ID)
 references LOAD_SEGMENTATION_DEF(REPORT_ID)
 on delete cascade
/


alter table LOAD_SEG_DEF_DTLS_ATTR_VALUES
 add constraint FK_LOAD_SEG_DEF_DT_ATT_VAL foreign key (REPORT_ID, ATTRIBUTE_ID)
 references LOAD_SEGMENTATION_DEF_DETAILS (REPORT_ID, ATTRIBUTE_ID)
 on delete cascade
/

alter table LOAD_SEGMENTATION_REPORT 
  add constraint LSR_PROCESS_ID_FK foreign key (PROCESS_ID)
  references LOAD_SEG_REPORT_RUN_HEADER(PROCESS_ID) 
  on delete cascade
/

alter table LOAD_SEG_REPORT_RUN_HEADER 
  add constraint LSRRH_PROCESS_ID_FK foreign key (PROCESS_ID)
  references PROCESS_LOG(PROCESS_ID) 
  on delete set null
/

alter table MEASUREMENT_SOURCE
   add constraint FK_MEASUREMENT_SOURCE foreign key (EXTERNAL_SYSTEM_ID)
      references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
/


alter table MEASUREMENT_SOURCE_VALUE
   add constraint FK_MEASUREMENT_SOURCE_VALUE foreign key (MEASUREMENT_SOURCE_ID)
      references MEASUREMENT_SOURCE (MEASUREMENT_SOURCE_ID)
      on delete cascade
/


alter table MEASUREMENT_SRC_VAL_LK_SUMMARY
   add constraint FK_MEASUREMENT_SRC_VAL_LK_SUM foreign key (MEASUREMENT_SOURCE_ID)
      references MEASUREMENT_SOURCE (MEASUREMENT_SOURCE_ID)
      on delete cascade
/


alter table OASIS_RESERVATION
   add constraint FK_OASIS_RESRV_IT foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table PIPELINE_POINT_LIMIT
   add constraint FK_PIPELINE_PT_LIMIT_CONTRACT foreign key (CONTRACT_ID)
      references INTERCHANGE_CONTRACT (CONTRACT_ID)
      on delete cascade
/


alter table PIPELINE_SEGMENT_LIMIT
   add constraint FK_PIPELINE_SEG_LIMIT_CONTRACT foreign key (CONTRACT_ID)
      references INTERCHANGE_CONTRACT (CONTRACT_ID)
      on delete cascade
/


alter table PIPELINE_TARIFF_RATE
   add constraint FK_PIPELINE_TARIFF_CONTRACT foreign key (CONTRACT_ID)
      references INTERCHANGE_CONTRACT (CONTRACT_ID)
      on delete cascade
/


alter table PROCESS_LOG
   add constraint FK_PARENT_PROCESS foreign key (PARENT_PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/


alter table PROCESS_LOG
   add constraint FK_PROC_LOG_APP_USER foreign key (TERMINATED_BY_USER_ID)
      references APPLICATION_USER (USER_ID)
/


alter table PROCESS_LOG_EVENT
   add constraint FK_MESSAGE_DEFINITION foreign key (MESSAGE_ID)
      references MESSAGE_DEFINITION (MESSAGE_ID)
/


alter table PROCESS_LOG_EVENT
   add constraint FK_PROCESS_LOG1 foreign key (PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/


alter table PROCESS_LOG_EVENT_DETAIL
   add constraint FK_PROCESS_LOG_EVENT foreign key (EVENT_ID)
      references PROCESS_LOG_EVENT (EVENT_ID)
/


alter table PROCESS_LOG_TARGET_PARAMETER
   add constraint FK_PROCESS_LOG foreign key (PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/


alter table PROCESS_LOG_TRACE
   add constraint FK_MESSAGE_DEFINITION1 foreign key (MESSAGE_ID)
      references MESSAGE_DEFINITION (MESSAGE_ID)
/


alter table PROCESS_LOG_TRACE
   add constraint FK_PROCESS_LOG2 foreign key (PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/


alter table PRODUCT_COMPONENT
  add constraint FK_PRODUCT foreign key (PRODUCT_ID)
   references PRODUCT (PRODUCT_ID) 
   on delete cascade
/

alter table PRODUCT_COMPONENT
  add constraint FK_COMPONENT_TABLE foreign key (COMPONENT_ID)
   references COMPONENT (COMPONENT_ID) 
/

alter table PROGRAM_LIMIT_HITS_USED 
   add constraint FK_PROGRAM_LIMIT_HITS_PL  foreign key (PROGRAM_LIMIT_ID)
      references PROGRAM_LIMIT (PROGRAM_LIMIT_ID)
      on delete cascade
/


alter table PROGRAM_LIMIT_HITS_USED 
   add constraint FK_PROGRAM_LIMIT_HITS_SL  foreign key (SERVICE_LOCATION_ID)
      references SERVICE_LOCATION (SERVICE_LOCATION_ID)
      on delete cascade
/


alter table PROGRAM_LIMIT_HITS_USED 
   add constraint FK_PROGRAM_LIMIT_HITS_EV  foreign key (EVENT_ID)
      references DR_EVENT (EVENT_ID)
      on delete cascade
/

alter table PSE_INVOICE_RECIPIENT 
   add constraint FK_PSE_INVOICE_RECIP  foreign key (PSE_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade
/

alter table PSE_INVOICE_RECIPIENT 
   add constraint FK_PSE_INV_RECIP_GROUP  foreign key (CONTACT_GROUP_ID)
      references ENTITY_GROUP (ENTITY_GROUP_ID)
      on delete cascade
/

alter table PSE_INVOICE_RECIPIENT 
   add constraint FK_PSE_INV_RECIP_CONTACT  foreign key (CONTACT_ID)
      references CONTACT (CONTACT_ID)
      on delete cascade
/

alter table REACTOR_PROCEDURE 
   add constraint FK_REACTOR_PROCEDURE_TABLE foreign key (TABLE_ID)
      references SYSTEM_TABLE (TABLE_ID)
/


alter table REACTOR_PROCEDURE 
   add constraint FK_REACTOR_PROCEDURE_THREAD foreign key (JOB_THREAD_ID)
      references JOB_THREAD (JOB_THREAD_ID)
/


alter table REACTOR_PROCEDURE_ENTITY_REF
  add constraint FK_REACTOR_PROC_ENTITY_REF foreign key (REACTOR_PROCEDURE_ID)
  references REACTOR_PROCEDURE (REACTOR_PROCEDURE_ID) on delete cascade
/


alter table REACTOR_PROCEDURE_ENTITY_REF
  add constraint FK_REACTOR_PROC_ENTITY_REF_DM foreign key (ENTITY_DOMAIN_ID)
  references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table REACTOR_PROCEDURE_INPUT
   add constraint FK_REACTOR_PROCEDURE_INPUT foreign key (REACTOR_PROCEDURE_ID)
      references REACTOR_PROCEDURE (REACTOR_PROCEDURE_ID)
      on delete cascade
/


alter table REACTOR_PROCEDURE_INPUT
   add constraint FK_REACTOR_PROCEDURE_INPUT_DM foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table REACTOR_PROCEDURE_PARAMETER
   add constraint FK_REACTOR_PROCEDURE_PARAMETER foreign key (REACTOR_PROCEDURE_ID)
      references REACTOR_PROCEDURE (REACTOR_PROCEDURE_ID)
      on delete cascade
/

alter table SERVICE_LOCATION
   add constraint FK_SERVICE_LOCATION_ZONE foreign key (SERVICE_ZONE_ID)
      references SERVICE_ZONE(SERVICE_ZONE_ID)
/

alter table SERVICE_LOCATION
   add constraint FK_SERVICE_LOCATION_SUB_STAT foreign key (SUB_STATION_ID)
      references TX_SUB_STATION(SUB_STATION_ID)
/

alter table SERVICE_LOCATION
   add constraint FK_SERVICE_LOCATION_FEEDER foreign key (FEEDER_ID)
      references TX_FEEDER(FEEDER_ID)
/

alter table SERVICE_LOCATION
   add constraint FK_SERVICE_LOCATION_FEEDER_SEG foreign key (FEEDER_SEGMENT_ID)
      references TX_FEEDER_SEGMENT(FEEDER_SEGMENT_ID)
/

alter table SERVICE_LOCATION_PROGRAM
   add constraint FK_SRVC_LOCTN_PRGRM_SRVC_LOCTN foreign key (SERVICE_LOCATION_ID)
      references SERVICE_LOCATION(SERVICE_LOCATION_ID)
      on delete cascade
/

alter table SERVICE_LOCATION_PROGRAM
   add constraint FK_SRVC_LOCTN_PRGRM_PRGRM foreign key (PROGRAM_ID)
      references PROGRAM(PROGRAM_ID)
/

alter table STORAGE_CAPACITY
   add constraint FK_STORAGE_CAPACITY_CONTRACT foreign key (CONTRACT_ID)
      references INTERCHANGE_CONTRACT (CONTRACT_ID)
      on delete cascade
/


alter table STORAGE_RATCHET
   add constraint FK_STORAGE_RATCHET_CONTRACT foreign key (CONTRACT_ID)
      references INTERCHANGE_CONTRACT (CONTRACT_ID)
      on delete cascade
/


alter table STORAGE_SCHEDULE
   add constraint FK_STORAGE_SCHEDULE_CONTRACT foreign key (CONTRACT_ID)
      references INTERCHANGE_CONTRACT (CONTRACT_ID)
      on delete cascade
/


alter table SUPPLY_RESOURCE_METER
   add constraint FK_SUPPLY_RESOURCE_METER foreign key (METER_ID)
      references TX_SUB_STATION_METER (METER_ID)
      on delete cascade
/


alter table SUPPLY_RESOURCE_METER
   add constraint FK_SUPPLY_RESOURCE_METER_RES foreign key (RESOURCE_ID)
      references SUPPLY_RESOURCE (RESOURCE_ID)
      on delete cascade
/


alter table SUPPLY_RESOURCE_OWNER
   add constraint FK_SUPPLY_RESOURCE_OWNER foreign key (OWNER_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete cascade
/


alter table SUPPLY_RESOURCE_OWNER
   add constraint FK_SUPPLY_RESOURCE_OWNER_RES foreign key (RESOURCE_ID)
      references SUPPLY_RESOURCE (RESOURCE_ID)
      on delete cascade
/


alter table SYSTEM_ACTION_ROLE
   add constraint FK_ACTION_ACTION_ROLE foreign key (ACTION_ID)
      references SYSTEM_ACTION (ACTION_ID)
      on delete cascade
/


alter table SYSTEM_ACTION_ROLE
   add constraint FK_SYSTEM_ACTION_ROLE_REALM foreign key (REALM_ID)
      references SYSTEM_REALM (REALM_ID)
      on delete cascade
/


alter table SYSTEM_ACTION_ROLE
   add constraint FK_SYSTEM_ACTION_ROLE_DOMAIN foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
      on delete cascade
/


alter table SYSTEM_ACTION_ROLE
   add constraint FK_SYSTEM_ACTION_ROLE_ROLE foreign key (ROLE_ID)
      references APPLICATION_ROLE (ROLE_ID)
      on delete cascade
/


alter table SYSTEM_ALERT_ACKNOWLEDGEMENT
   add constraint FK_SYSTEM_A_REFERENCE_APPLICAT foreign key (USER_ID)
      references APPLICATION_USER (USER_ID)
/


alter table SYSTEM_ALERT_ACKNOWLEDGEMENT
   add constraint FK_SYSTEM_ALERT_ACKNOW foreign key (OCCURRENCE_ID)
      references SYSTEM_ALERT_OCCURRENCE (OCCURRENCE_ID)
      on delete cascade
/


alter table SYSTEM_ALERT_OCCURRENCE
   add constraint FK_SYSTEM_ALERT_OCCUR_PROCESS foreign key (PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/


alter table SYSTEM_ALERT_OCCURRENCE
   add constraint FK_SYSTEM_ALERT_OCCURRENCE foreign key (ALERT_ID)
      references SYSTEM_ALERT (ALERT_ID)
      on delete cascade
/


alter table SYSTEM_ALERT_ROLE
   add constraint FK_SYSTEM_ALERT_ROLE foreign key (ALERT_ID)
      references SYSTEM_ALERT (ALERT_ID)
      on delete cascade
/


alter table SYSTEM_ALERT_TRIGGER
   add constraint FK_SYSTEM_ALERT_TRIGGER foreign key (ALERT_ID)
      references SYSTEM_ALERT (ALERT_ID)
      on delete cascade
/


alter table SYSTEM_OBJECT_ATTRIBUTE
   add constraint FK_SYSTEM_OBJ_ATTR_TO_OBJ foreign key (OBJECT_ID)
      references SYSTEM_OBJECT (OBJECT_ID)
      on delete cascade
/


alter table SYSTEM_OBJECT_IMPORT
   add constraint FK_SYSTEM_O_REFERENCE_APPLICAT foreign key (USER_ID)
      references APPLICATION_USER (USER_ID)
      on delete set null
/


alter table SYSTEM_OBJECT_IMPORT_ATTR_LOG
   add constraint FK_SYSTEM_OBJECT_IMPORT_ATTR_L foreign key (OBJECT_IMPORT_ID, OBJECT_ID, IMPORT_SIDE)
      references SYSTEM_OBJECT_IMPORT_LOG (OBJECT_IMPORT_ID, OBJECT_ID, IMPORT_SIDE)
      on delete cascade
/


alter table SYSTEM_OBJECT_IMPORT_CRYSTAL
   add constraint FK_SYSTEM_OBJECT_IMPORT_CRYSTA foreign key (OBJECT_IMPORT_ID, OBJECT_ID, IMPORT_SIDE)
      references SYSTEM_OBJECT_IMPORT_LOG (OBJECT_IMPORT_ID, OBJECT_ID, IMPORT_SIDE)
      on delete cascade
/


alter table SYSTEM_OBJECT_IMPORT_ITEM
   add constraint FK_SYSTEM_OBJECT_IMPORT_ITEM foreign key (OBJECT_IMPORT_ID)
      references SYSTEM_OBJECT_IMPORT (OBJECT_IMPORT_ID)
      on delete cascade
/


alter table SYSTEM_OBJECT_IMPORT_LOG
   add constraint FK_SYSTEM_OBJECT_IMPORT_LOG foreign key (OBJECT_IMPORT_ID, OBJECT_ID)
      references SYSTEM_OBJECT_IMPORT_ITEM (OBJECT_IMPORT_ID, OBJECT_ID)
      on delete cascade
/


alter table SYSTEM_OBJECT_PRIVILEGE
   add constraint FK_APPLICATION_ROLE foreign key (ROLE_ID)
      references APPLICATION_ROLE (ROLE_ID)
      on delete cascade
/


alter table SYSTEM_OBJECT_PRIVILEGE
   add constraint FK_SYSTEM_OBJECT foreign key (OBJECT_ID)
      references SYSTEM_OBJECT (OBJECT_ID)
      on delete cascade
/


alter table SYSTEM_REALM
   add constraint FK_SYSTEM_REALM_DOMAIN foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table SYSTEM_REALM_COLUMN
   add constraint FK_SYSTEM_REALM_COLUMN foreign key (REALM_ID)
      references SYSTEM_REALM (REALM_ID)
      on delete cascade
/


alter table SYSTEM_REALM_ENTITY
   add constraint FK_SYSTEM_REALM_ENTITY foreign key (REALM_ID)
      references SYSTEM_REALM (REALM_ID)
      on delete cascade
/

alter table SYSTEM_SESSION
   add constraint FK_SYSTEM_SESSION_PROCESS foreign key (CURRENT_PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/


alter table SYSTEM_TABLE
   add constraint FK_SYSTEM_TABLE_ENTITY_DOMAIN foreign key (ENTITY_DOMAIN_ID)
      references ENTITY_DOMAIN (ENTITY_DOMAIN_ID)
/


alter table TRANSACTION_PATH
   add constraint FK_TRANSACTION_PATH_IT foreign key (TRANSACTION_ID)
      references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
      on delete cascade
/


alter table TRANSACTION_TRAIT
   add constraint FK_TRANSACTION_TRAIT foreign key (TRAIT_GROUP_ID)
      references TRANSACTION_TRAIT_GROUP (TRAIT_GROUP_ID)
      on delete cascade
/


alter table TRANSACTION_TRAIT
   add constraint FK_TRANSACT_TRAIT_SYSTEM_OBJ foreign key (SYSTEM_OBJECT_ID)
      references SYSTEM_OBJECT (OBJECT_ID)
      on delete set null
/


alter table TRANSMISSION_PROVIDER
   add constraint FK_TP_OASIS_NODE foreign key (OASIS_NODE_ID)
      references OASIS_NODE (OASIS_NODE_ID)
      on delete set null
/


alter table TX_SUB_STATION_METER
   add constraint FK_TX_SUB_STATION_METER foreign key (SUB_STATION_ID)
      references TX_SUB_STATION (SUB_STATION_ID)
/


alter table TX_SUB_STATION_METER
   add constraint FK_TX_SUB_STATION_METER_REF foreign key (REF_METER_ID)
      references TX_SUB_STATION_METER (METER_ID)
      on delete set null
/


alter table TX_SUB_STATION_METER
   add constraint FK_TX_SUB_STATION_METER_SP foreign key (SERVICE_POINT_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
      on delete set null
/

alter table TX_SUB_STATION
  add constraint FK_TX_SUB_STATION foreign key (SERVICE_ZONE_ID)
  references SERVICE_ZONE (SERVICE_ZONE_ID)
/

alter table TX_SUB_STATION_METER_OWNER
   add constraint FK_TX_SUB_STATION_METER_OWNER foreign key (METER_ID)
      references TX_SUB_STATION_METER (METER_ID)
      on delete cascade
/


alter table TX_SUB_STATION_METER_OWNER
   add constraint FK_TX_SUB_STATION_METER_OWNER2 foreign key (OWNER_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete set null
/


alter table TX_SUB_STATION_METER_OWNER
   add constraint FK_TX_SUB_STATION_METER_PARTY1 foreign key (PARTY1_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete set null
/


alter table TX_SUB_STATION_METER_OWNER
   add constraint FK_TX_SUB_STATION_METER_PARTY2 foreign key (PARTY2_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
      on delete set null
/


alter table TX_SUB_STATION_METER_POINT
   add constraint FK_RETAIL_METER_POINT foreign key (RETAIL_METER_ID)
      references METER (METER_ID)
      on delete cascade
/


alter table TX_SUB_STATION_METER_POINT
   add constraint FK_TX_SUB_STATION_METER_POINT foreign key (SUB_STATION_METER_ID)
      references TX_SUB_STATION_METER (METER_ID)
/


alter table TX_SUB_STATION_METER_PT_LOSS
   add constraint FK_TX_SUB_STATION_MTR_PT_LOSS foreign key (METER_POINT_ID)
      references TX_SUB_STATION_METER_POINT (METER_POINT_ID)
      on delete cascade
/


alter table TX_SUB_STATION_METER_PT_LOSS
   add constraint FK_TX_SUB_STATION_MTR_PT_LOSS2 foreign key (LOSS_FACTOR_ID)
      references LOSS_FACTOR (LOSS_FACTOR_ID)
/


alter table TX_SUB_STATION_METER_PT_SOURCE
   add constraint FK_TX_SUB_STATION_MTR_PT_SRC foreign key (METER_POINT_ID)
      references TX_SUB_STATION_METER_POINT (METER_POINT_ID)
      on delete cascade
/


alter table TX_SUB_STATION_METER_PT_SOURCE
   add constraint FK_TX_SUB_STATION_MTR_PT_SRC2 foreign key (MEASUREMENT_SOURCE_ID)
      references MEASUREMENT_SOURCE (MEASUREMENT_SOURCE_ID)
/


alter table TX_SUB_STATION_METER_PT_VALUE
   add constraint FK_TX_SUB_STATION_MTR_PT_VALUE foreign key (METER_POINT_ID)
      references TX_SUB_STATION_METER_POINT (METER_POINT_ID)
      on delete cascade
/


alter table TX_SUB_STATION_METER_PT_VALUE
   add constraint FK_TX_SUB_STATION_MTR_PT_VAL_S foreign key (MEASUREMENT_SOURCE_ID)
      references MEASUREMENT_SOURCE (MEASUREMENT_SOURCE_ID)
/


alter table TX_SUB_STATION_MTR_PT_VAL_LK_S
   add constraint FK_TX_SUB_STATION_MTR_VAL_LK_M foreign key (METER_POINT_ID)
      references TX_SUB_STATION_METER_POINT (METER_POINT_ID)
      on delete cascade
/


alter table TX_SUB_STATION_MTR_PT_VAL_LK_S
   add constraint FK_TX_SUB_STATION_MTR_VAL_L_MS foreign key (MEASUREMENT_SOURCE_ID)
      references MEASUREMENT_SOURCE (MEASUREMENT_SOURCE_ID)
/


alter table WRF_FCM
   add constraint FK_WRF_FCM foreign key (PROFILE_ID)
      references LOAD_PROFILE (PROFILE_ID)
      on delete cascade
/


alter table WRF_FCM_CANDIDATE
   add constraint FK_WRF_FCM_CANDIDATE foreign key (FCM_ID)
      references WRF_FCM (FCM_ID)
      on delete cascade
/


alter table WRF_FCM_CLUSTER
   add constraint FK_WRF_FCM_CLUSTER foreign key (FCM_ID, NUM_SEGMENTS)
      references WRF_FCM_CANDIDATE (FCM_ID, NUM_SEGMENTS)
      on delete cascade
/


alter table WRF_FCM_CLUSTER_ASSIGNMENT
   add constraint FK_WRF_FCM_CLUSTER_ASSIGNMENT foreign key (FCM_ID, NUM_SEGMENTS, CLUSTER_NUM)
      references WRF_FCM_CLUSTER (FCM_ID, NUM_SEGMENTS, CLUSTER_NUM)
      on delete cascade
/


alter table WRF_FCM_CLUSTER_ASSIGNMENT
   add constraint FK_WRF_FCM_OBSERVATION_ASSIGN foreign key (FCM_ID, OBSERVATION_NUM)
      references WRF_FCM_OBSERVATION (FCM_ID, OBSERVATION_NUM)
      on delete cascade
/


alter table WRF_FCM_CLUSTER_MEMBERSHIP
   add constraint FK_WRF_FCM_CLUSTER_MEMBERSHIP foreign key (FCM_ID, NUM_SEGMENTS, CLUSTER_NUM)
      references WRF_FCM_CLUSTER (FCM_ID, NUM_SEGMENTS, CLUSTER_NUM)
      on delete cascade
/


alter table WRF_FCM_CLUSTER_MEMBERSHIP
   add constraint FK_WRF_FCM_OBSERVATION_MEMBER foreign key (FCM_ID, OBSERVATION_NUM)
      references WRF_FCM_OBSERVATION (FCM_ID, OBSERVATION_NUM)
      on delete cascade
/


alter table WRF_FCM_OBSERVATION
   add constraint FK_WRF_FCM_OBSERVATION foreign key (FCM_ID)
      references WRF_FCM (FCM_ID)
      on delete cascade
/

alter table LOSS_FACTOR_MODEL
   add constraint FK_LOSS_FACTOR_MODEL foreign key (LOSS_FACTOR_ID)
      references LOSS_FACTOR(LOSS_FACTOR_ID)
      on delete cascade
/

alter table LOSS_FACTOR_PATTERN
   add constraint FK_LOSS_FACTOR_PATTERN foreign key (PATTERN_ID)
      references LOSS_FACTOR_MODEL(PATTERN_ID)
      on delete cascade
/

alter table ACCOUNT_LOSS_FACTOR
   add constraint FK_ACCT_LOSS_FACTOR foreign key (LOSS_FACTOR_ID)
      references LOSS_FACTOR(LOSS_FACTOR_ID)
      on delete cascade
/

alter table METER_LOSS_FACTOR
   add constraint FK_MTR_LOSS_FACTOR foreign key (LOSS_FACTOR_ID)
      references LOSS_FACTOR(LOSS_FACTOR_ID)
      on delete cascade
/

alter table EDC_LOSS_FACTOR
   add constraint FK_EDC_LOSS_FACTOR foreign key (LOSS_FACTOR_ID)
      references LOSS_FACTOR(LOSS_FACTOR_ID)
      on delete cascade
/

alter table MARKET_PRICE_VAL_LOCK_SUMMARY
   add constraint FK_MARKET_PRICE_VAL_LK_SUMMARY foreign key (MARKET_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
      on delete cascade
/

alter table MARKET_PRICE_VALUE
   add constraint FK_MARKET_PRICE_VALUE foreign key (MARKET_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
      on delete cascade
/

alter table MARKET_PRICE_COMPOSITE
   add constraint FK_MARKET_PRICE_COMP foreign key (MARKET_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
      on delete cascade
/

alter table MARKET_PRICE_COMPOSITE
   add constraint FK_MARKET_PRICE_COMP2 foreign key (COMPOSITE_MARKET_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
/

alter table COMPONENT
   add constraint FK_COMPONENT_MKT_PRICE foreign key (MARKET_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
/

alter table COMPONENT_IMBALANCE
   add constraint FK_COMP_IMBLNCE_UU_PRICE foreign key (UNDER_UNDER_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
/

alter table COMPONENT_IMBALANCE
   add constraint FK_COMP_IMBLNCE_OU_PRICE foreign key (OVER_UNDER_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
/

alter table COMPONENT_IMBALANCE
   add constraint FK_COMP_IMBLNCE_UO_PRICE foreign key (UNDER_OVER_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
/

alter table COMPONENT_IMBALANCE
   add constraint FK_COMP_IMBLNCE_OO_PRICE foreign key (OVER_OVER_PRICE_ID)
      references MARKET_PRICE(MARKET_PRICE_ID)
/

alter table LOAD_FORECAST_SCENARIO 
   add constraint FK_LOAD_FCAST_SCEN_WTHR foreign key (WEATHER_CASE_ID)
      references CASE_LABEL(CASE_ID)
/

alter table LOAD_FORECAST_SCENARIO 
   add constraint FK_LOAD_FCAST_SCEN_SCEN foreign key (SCENARIO_ID)
      references SCENARIO(SCENARIO_ID)
      on delete cascade
/

alter table LOAD_FORECAST_SCENARIO 
   add constraint FK_LOAD_FCAST_SCEN_AREA foreign key (AREA_LOAD_CASE_ID)
      references CASE_LABEL(CASE_ID)
/

alter table LOAD_FORECAST_SCENARIO 
   add constraint FK_LOAD_FCAST_SCEN_ENRLLMNT foreign key (ENROLLMENT_CASE_ID)
      references CASE_LABEL(CASE_ID)
/

alter table LOAD_FORECAST_SCENARIO 
   add constraint FK_LOAD_FCAST_SCEN_USAGE foreign key (USAGE_FACTOR_CASE_ID)
      references CASE_LABEL(CASE_ID)
/

alter table LOAD_FORECAST_SCENARIO 
   add constraint FK_LOAD_FCAST_SCEN_LF foreign key (LOSS_FACTOR_CASE_ID)
      references CASE_LABEL(CASE_ID)
/

alter table LOAD_FORECAST_SCENARIO 
   add constraint FK_LOAD_FCAST_SCEN_GROWTH foreign key (GROWTH_FACTOR_CASE_ID)
      references CASE_LABEL(CASE_ID)
/

alter table LOAD_FORECAST_SCENARIO_STATUS
   add constraint FK_LOAD_FCAST_SCEN foreign key (SCENARIO_ID)
      references LOAD_FORECAST_SCENARIO (SCENARIO_ID)
      on delete cascade
/

alter table LOAD_FORECAST_SCENARIO_STATUS
   add constraint FK_LOAD_FCAST_STATUS foreign key (STATUS_NAME)
      references ACCOUNT_STATUS_NAME (STATUS_NAME)
      on delete cascade
/

alter table ACCOUNT_STATUS
   add constraint FK_ACCNT_STATUS_NAME foreign key (STATUS_NAME)
      references ACCOUNT_STATUS_NAME (STATUS_NAME)
/

alter table ACCOUNT_STATUS
   add constraint FK_ACCOUNT_STATUS foreign key (ACCOUNT_ID)
      references ACCOUNT(ACCOUNT_ID)
      on delete cascade
/

alter table ACCOUNT_METER
   add constraint FK_ACCOUNT_METER foreign key (ACCOUNT_ID)
      references ACCOUNT(ACCOUNT_ID)
      on delete cascade
/

alter table ENTITY_NOTE
  add constraints FK_ENTITY_NOTE_AUTHOR foreign key (NOTE_AUTHOR_ID)
      references APPLICATION_USER (USER_ID)
/

alter table ACCOUNT_ESP
	add constraint FK_ACCOUNT_ESP foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_EDC
	add constraint FK_ACCOUNT_EDC foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_USAGE_FACTOR
	add constraint FK_ACCOUNT_USAGE_FACTOR foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_USAGE_FACTOR
	add constraint FK_ACCOUNT_USAGE_FACTOR_CAL foreign key (SOURCE_CALENDAR_ID)
		references CALENDAR(CALENDAR_ID)
		on delete cascade
/

alter table ACCOUNT_LOSS_FACTOR
	add constraint FK_ACCOUNT_LOSS_FACTOR foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_PRODUCT
	add constraint FK_ACCOUNT_PRODUCT foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_GROUP_ASSIGNMENT
	add constraint FK_ACCOUNT_GROUP_ASSIGNMENT foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_CALENDAR
	add constraint FK_ACCOUNT_CALENDAR foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_SERVICE_LOCATION
	add constraint FK_ACCOUNT_SERVICE_LOCATION foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_SERVICE
	add constraint FK_ACCOUNT_SERVICE foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table AGGREGATE_ACCOUNT_ESP
	add constraint FK_AGGREGATE_ACCOUNT_ESP foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_ANCILLARY_SERVICE
	add constraint FK_ACCOUNT_ANCILLARY_SERVICE foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_UFE_PARTICIPATION
	add constraint FK_ACCOUNT_UFE_PARTICIPATION foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_SCHEDULE_GROUP
	add constraint FK_ACCOUNT_SCHEDULE_GROUP foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_GROWTH
	add constraint FK_ACCOUNT_GROWTH foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_BILL_CYCLE
	add constraint FK_ACCOUNT_BILL_CYCLE foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table METER
	add constraint FK_METER_STATUS_NAME foreign key (METER_STATUS)
		references ACCOUNT_STATUS_NAME(STATUS_NAME)
/

alter table CONTACT_CATEGORY
	add constraint FK_CONTACT_CATEGORY foreign key (CONTACT_ID)
		references CONTACT(CONTACT_ID)
		on delete cascade
/

alter table CONTACT_CATEGORY
	add constraint FK_CONTACT_CATEGORY_CAT foreign key (CATEGORY_ID)
		references CATEGORY(CATEGORY_ID)
/

alter table ENTITY_DOMAIN_ADDRESS
	add constraint FK_ENTITY_DOMAIN_ADDRESS foreign key (GEOGRAPHY_ID)
		references GEOGRAPHY(GEOGRAPHY_ID)
/

alter table ENTITY_DOMAIN_ADDRESS
	add constraint FK_ENTITY_DOMAIN_ADDRESS_CAT foreign key (CATEGORY_ID)
		references CATEGORY(CATEGORY_ID)
/

alter table ENTITY_DOMAIN_CONTACT
	add constraint FK_ENTITY_DOMAIN_CONTACT foreign key (CONTACT_ID)
		references CONTACT(CONTACT_ID)
		on delete cascade
/

alter table ENTITY_DOMAIN_CONTACT
	add constraint FK_ENTITY_DOMAIN_CONTACT_CAT foreign key (CATEGORY_ID)
		references CATEGORY(CATEGORY_ID)
/

alter table PHONE_NUMBER
	add constraint FK_PHONE_NUMBER foreign key (CONTACT_ID)
		references CONTACT(CONTACT_ID)
		on delete cascade
/

alter table DR_EVENT
   add constraint FK_DR_EVENT_VPP foreign key (VPP_ID)
       references VIRTUAL_POWER_PLANT (VPP_ID)
       on delete cascade
/

alter table DR_EVENT_EXCEPTION
   add constraint FK_DR_EVENT_EXCEPTION_EVENT foreign key (EVENT_ID)
       references DR_EVENT (EVENT_ID)
       on delete cascade
/

alter table DR_EVENT_EXCEPTION
   add constraint FK_DR_EVENT_EXCEPTION_DER foreign key (DER_ID)
       references DISTRIBUTED_ENERGY_RESOURCE (DER_ID)
/

alter table DR_EVENT_SCHEDULE
   add constraint FK_DR_EVENT_SCHEDULE_EVENT foreign key (EVENT_ID)
       references DR_EVENT (EVENT_ID)
       on delete cascade
/

alter table DR_EVENT_PARTICIPATION
   add constraint FK_DR_EVENT_PARTICIPATE_EVENT foreign key (EVENT_ID)
       references DR_EVENT (EVENT_ID)
       on delete cascade
/

alter table DR_EVENT_PARTICIPATION
   add constraint FK_DR_EVENT_PARTICIPATION_DER foreign key (DER_ID)
       references DISTRIBUTED_ENERGY_RESOURCE (DER_ID)
/

alter table DER_TYPE_CALENDAR
   add constraint FK_DER_TYPE foreign key (DER_TYPE_ID)
      references DER_TYPE (DER_TYPE_ID)
      on delete cascade
/

alter table DER_TYPE_CALENDAR
   add constraint FK_DER_TYPE_CAL foreign key (CALENDAR_ID)
      references CALENDAR (CALENDAR_ID)
/

alter table DER_TYPE_HISTORY
   add constraint FK_DER_TYPE_HIST foreign key (DER_TYPE_ID)
      references DER_TYPE (DER_TYPE_ID)
      on delete cascade
/

--alter table DER_TYPE_HISTORY
--   add constraint FK_DER_TYPE_EVENT foreign key (EVENT_ID)
--      references DR_PROGRAM_EVENT (EVENT_ID)
--      on delete cascade
--/

alter table DISTRIBUTED_ENERGY_RESOURCE
   add constraint FK_DER_DER_TYPE foreign key (DER_TYPE_ID)
      references DER_TYPE (DER_TYPE_ID)
/

alter table DISTRIBUTED_ENERGY_RESOURCE
   add constraint FK_DER_EXT_SYS foreign key (EXTERNAL_SYSTEM_ID)
      references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
/

alter table DISTRIBUTED_ENERGY_RESOURCE
   add constraint FK_DER_SL foreign key (SERVICE_LOCATION_ID)
      references SERVICE_LOCATION (SERVICE_LOCATION_ID)
      on delete cascade
/

alter table DER_CALENDAR
   add constraint FK_DER_CAL foreign key (CALENDAR_ID)
      references CALENDAR (CALENDAR_ID)
/

alter table DER_CALENDAR
   add constraint FK_DER foreign key (DER_ID)
      references DISTRIBUTED_ENERGY_RESOURCE (DER_ID)
      on delete cascade
/

alter table DER_SCALE_FACTOR
   add constraint FK_DER_SCALE foreign key (DER_ID)
      references DISTRIBUTED_ENERGY_RESOURCE (DER_ID)
      on delete cascade
/

alter table DER_STATUS
   add constraint FK_STATUS_DER foreign key (DER_ID)
      references DISTRIBUTED_ENERGY_RESOURCE (DER_ID)
      on delete cascade
/

alter table DER_TYPE_CALENDAR
   add constraint FK_DER_TYPE_CASE foreign key (CASE_ID)
      references CASE_LABEL (CASE_ID)
/

alter table DER_CALENDAR
   add constraint FK_DER_CASE foreign key (CASE_ID)
      references CASE_LABEL (CASE_ID)
/

alter table DER_SCALE_FACTOR
   add constraint FK_DER_SCALE_CASE foreign key (CASE_ID)
      references CASE_LABEL (CASE_ID)
/

alter table PROGRAM
  add constraint FK_COMPONENT foreign key (COMPONENT_ID)
  references COMPONENT (COMPONENT_ID)
/

alter table PROGRAM
  add constraint FK_TRANSACTION foreign key (TRANSACTION_ID)
  references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
/

alter table PROGRAM_DER_TYPE
  add constraint FK_PROGRAM_DER_TYPE_PROG_ID foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table PROGRAM_DER_TYPE
  add constraint FK_PROG_DER_TYPE_DER_TYPE_ID foreign key (DER_TYPE_ID)
  references DER_TYPE (DER_TYPE_ID)
/

alter table PROGRAM_DER_PAYMENT
  add constraint FK_PROG_DER_PAY_PROGRAM_ID foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table PROGRAM_EVENT_HISTORY
  add constraint FK_PROG_EVENT_HIST_PROGRAM_ID foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table PROGRAM_EVENT_HISTORY
  add constraint FK_EVENT_HISTORY_EVENT_ID foreign key (EVENT_ID)
  references DR_EVENT (EVENT_ID)
/

alter table PROGRAM_EXECUTION_TYPE
  add constraint FK_PROG_EXEC_TYPE_PROG_ID foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table PROGRAM_LIMIT
  add constraint FK_PROGRAM_LIMIT_PROGRAM_ID foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table PROGRAM_LIMIT
  add constraint FK_PROGRAM_LIMIT_PERIOD_ID foreign key (PERIOD_ID)
  references PERIOD (PERIOD_ID)
/

alter table PROGRAM_LIMIT
  add constraint FK_PROGRAM_LIMIT_TEMPLATE_ID foreign key (TEMPLATE_ID)
  references TEMPLATE (TEMPLATE_ID)
/

alter table PROGRAM_NOTIFICATION
  add constraint FK_PROGRAM_NOTIFICATION foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table PROGRAM_PAYMENT
  add constraint FK_PROGRAM_PAYMENT_PROGRAM_ID foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table PROGRAM_REQUIRED_EQUIPMENT
  add constraint FK_PROGRAM_REQ_EQUIP_PROG_ID foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID) on delete cascade
/

alter table VIRTUAL_POWER_PLANT
  add constraint FK_VPP_PROGRAM foreign key (PROGRAM_ID)
  references PROGRAM (PROGRAM_ID)
/

alter table VIRTUAL_POWER_PLANT
  add constraint FK_VPP_SERVICE_ZONE_ID foreign key (SERVICE_ZONE_ID)
  references SERVICE_ZONE (SERVICE_ZONE_ID)
/

alter table TX_FEEDER
  add constraint FK_FEEDER_SUB_STATION foreign key (SUB_STATION_ID)
  references TX_SUB_STATION (SUB_STATION_ID)
/

alter table TX_FEEDER_SEGMENT
  add constraint FK_FEEDER_SEG_FEEDER foreign key (FEEDER_ID)
  references TX_FEEDER (FEEDER_ID)
/

alter table TX_FEEDER_SEGMENT_LOSS_FACTOR
  add constraint FK_SEG_LOSS_FACT_FEEDER_SEG foreign key (FEEDER_SEGMENT_ID)
  references TX_FEEDER_SEGMENT (FEEDER_SEGMENT_ID) on delete cascade
/

alter table TX_FEEDER_SEGMENT_LOSS_FACTOR
  add constraint FK_SEG_LOSS_FACT_ID foreign key (LOSS_FACTOR_ID)
  references LOSS_FACTOR (LOSS_FACTOR_ID)
/

alter table SERVICE_ZONE
  add constraint FK_SERVICE_ZONE_CONTROL_AREA foreign key (CONTROL_AREA_ID)
  references CONTROL_AREA (CA_ID)
/

alter table DER_VPP_RESULT
  add constraint FK_DER_VPP_RESULT_PROG foreign key (PROGRAM_ID)
  	references PROGRAM (PROGRAM_ID)
  	on delete cascade
/

alter table DER_VPP_RESULT
  add constraint FK_DER_VPP_RESULT_ZONE foreign key (SERVICE_ZONE_ID)
  	references SERVICE_ZONE (SERVICE_ZONE_ID)
  	on delete cascade
/

alter table DER_VPP_RESULT
  add constraint FK_DER_VPP_RESULT_SCEN foreign key (SCENARIO_ID)
    references SCENARIO (SCENARIO_ID)
    on delete cascade
/

alter table DER_VPP_RESULT_DATA
  add constraint FK_DER_VPP_RESULT_DATA_ID foreign key (DER_VPP_RESULT_ID)
    references DER_VPP_RESULT (DER_VPP_RESULT_ID)
    on delete cascade
/

alter table USAGE_WRF
	add constraint FK_USAGE_WRF_STATION foreign key (STATION_ID)
		references WEATHER_STATION(STATION_ID)
/

alter table USAGE_WRF
	add constraint FK_USAGE_WRF_PARM foreign key (PARAMETER_ID)
		references WEATHER_PARAMETER(PARAMETER_ID)
/

alter table USAGE_WRF_SEASON
	add constraint FK_USAGE_WRF_SEASON foreign key (WRF_ID,TEMPLATE_ID)
		references USAGE_WRF_TEMPLATE(WRF_ID,TEMPLATE_ID)
		on delete cascade
/

alter table USAGE_WRF_SEASON
	add constraint FK_USAGE_WRF_SEASON_TEMPLATE foreign key (BASE_LOAD_TEMPLATE_ID)
		references TEMPLATE(TEMPLATE_ID)
/

alter table USAGE_WRF_SEASON
	add constraint FK_USAGE_WRF_SEASON_SEASON foreign key (SEASON_ID)
		references SEASON(SEASON_ID)
/

alter table USAGE_WRF_SEASON
	add constraint FK_USAGE_WRF_SEASON_SEASON2 foreign key (BASE_LOAD_SEASON_ID)
		references SEASON(SEASON_ID)
/

alter table USAGE_WRF_STATISTICS
	add constraint FK_USAGE_WRF_STATISTICS foreign key (WRF_ID,TEMPLATE_ID)
		references USAGE_WRF_TEMPLATE(WRF_ID,TEMPLATE_ID)
		on delete cascade
/

alter table USAGE_WRF_TEMPLATE
	add constraint FK_USAGE_WRF_TEMPLATE foreign key (WRF_ID)
		references USAGE_WRF(WRF_ID)
		on delete cascade
/

alter table USAGE_WRF_TEMPLATE
	add constraint FK_USAGE_WRF_TEMPLATE_TEMPLATE foreign key (TEMPLATE_ID)
		references TEMPLATE(TEMPLATE_ID)
/

alter table USAGE_WRF_TEMPLATE
	add constraint FK_USAGE_WRF_TEMPLATE_TEMPLAT2 foreign key (BASE_LOAD_TEMPLATE_ID)
		references TEMPLATE(TEMPLATE_ID)
/

alter table ACCOUNT_USAGE_WRF
	add constraint FK_ACCOUNT_USAGE_WRF_ACCOUNT foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_USAGE_WRF
	add constraint FK_ACCOUNT_USAGE_WRF foreign key (WRF_ID)
		references USAGE_WRF(WRF_ID)
		on delete cascade
/

alter table ACCOUNT_USAGE_WRF_LINE
	add constraint FK_ACCOUNT_USAGE_WRF_LINE_ACCT foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_USAGE_WRF_LINE
	add constraint FK_ACCOUNT_USAGE_WRF_LINE foreign key (WRF_ID,TEMPLATE_ID)
		references USAGE_WRF_TEMPLATE(WRF_ID,TEMPLATE_ID)
		on delete cascade
/

alter table ACCOUNT_USAGE_WRF_LINE
	add constraint FK_ACCOUNT_USAGE_WRF_LINE_TMPL foreign key (BASE_LOAD_TEMPLATE_ID)
		references TEMPLATE(TEMPLATE_ID)
/

alter table CUSTOMER_USAGE_WRF
	add constraint FK_CUSTOMER_USAGE_WRF_CUSTOMER foreign key (CUSTOMER_ID)
		references CUSTOMER(CUSTOMER_ID)
		on delete cascade
/

alter table CUSTOMER_USAGE_WRF
	add constraint FK_CUSTOMER_USAGE_WRF foreign key (WRF_ID)
		references USAGE_WRF(WRF_ID)
		on delete cascade
/

alter table CUSTOMER_USAGE_WRF_LINE
	add constraint FK_CUSTOMER_USAGE_WRF_LINE_CUS foreign key (CUSTOMER_ID)
		references CUSTOMER(CUSTOMER_ID)
		on delete cascade
/

alter table CUSTOMER_USAGE_WRF_LINE
	add constraint FK_CUSTOMER_USAGE_WRF_LINE foreign key (WRF_ID,TEMPLATE_ID)
		references USAGE_WRF_TEMPLATE(WRF_ID,TEMPLATE_ID)
		on delete cascade
/

alter table CUSTOMER_USAGE_WRF_LINE
	add constraint FK_CUSTOMER_USAGE_WRF_LINE_TPL foreign key (BASE_LOAD_TEMPLATE_ID)
		references TEMPLATE(TEMPLATE_ID)
/

alter table PROGRAM_BILL_SUMMARY
	add constraint FK_PROG_BILL_SUMMARY_PROGRAM foreign key (PROGRAM_ID)
		references PROGRAM(PROGRAM_ID)
		on delete cascade
/

alter table PROGRAM_BILL_SUMMARY
	add constraint FK_PROG_BILL_SUMMARY_BILL_CYCL foreign key (BILL_CYCLE_ID)
		references BILL_CYCLE(BILL_CYCLE_ID)
		on delete cascade
/

alter table PROGRAM_BILL_RESULT
	add constraint FK_PROG_BILL_RST_PROG_BILL_SUM foreign key (BILL_SUMMARY_ID)
		references PROGRAM_BILL_SUMMARY (BILL_SUMMARY_ID)
		on delete cascade
/

alter table PROGRAM_BILL_RESULT
	add constraint FK_PROG_BILL_RESULT_ACCOUNT foreign key (ACCOUNT_ID)
		references ACCOUNT(ACCOUNT_ID)
		on delete cascade
/

alter table PROGRAM_BILL_RESULT
	add constraint FK_PROG_BILL_RESULT_SERV_LOC foreign key (SERVICE_LOCATION_ID)
		references SERVICE_LOCATION(SERVICE_LOCATION_ID)
		on delete cascade
/

alter table PROGRAM_BILL_RESULT
	add constraint FK_PROG_BILL_RESULT_PROC_LOG foreign key (PROCESS_ID)
		references PROCESS_LOG(PROCESS_ID)
/

alter table PROGRAM_BILL_DETERMINANT
	add constraint FK_PROG_BILL_DETER_PRG_BLL_RST foreign key (BILL_RESULT_ID)
		references PROGRAM_BILL_RESULT(BILL_RESULT_ID)
		on delete cascade
/

alter table PROGRAM_BILL_DETERMINANT
	add constraint FK_PROGRAM_BILL_DETER_DER_TYPE foreign key (DER_TYPE_ID)
		references DER_TYPE(DER_TYPE_ID)
/

alter table PROGRAM_BILL_DETERMINANT_DTL
	add constraint FK_PROG_BILL_DTR_DTL_BILL_DTR foreign key (BILL_DETERMINANT_ID)
		references PROGRAM_BILL_DETERMINANT(BILL_DETERMINANT_ID)
		on delete cascade
/

alter table PROGRAM_BILL_DETERMINANT_DTL
	add constraint FK_PROG_BILL_DTR_DTL_DR_EVENT foreign key (EVENT_ID)
		references DR_EVENT(EVENT_ID)
		on delete cascade
/

alter table PROGRAM_BILL_DETERMINANT_DTL
	add constraint FK_PROG_BILL_DTR_DTL_DER foreign key (DER_ID)
		references DISTRIBUTED_ENERGY_RESOURCE(DER_ID)
		on delete cascade
/	

alter table DER_SEGMENT_RESULT
  add constraint FK_DER_SEGMENT_RESULT_PROGRAM foreign key (PROGRAM_ID)
    references PROGRAM (PROGRAM_ID)
   on delete cascade
/

alter table DER_SEGMENT_RESULT
  add constraint FK_DER_SEGMENT_RESULT_SEGMENT foreign key (FEEDER_SEGMENT_ID)
    references TX_FEEDER_SEGMENT (FEEDER_SEGMENT_ID)
   on delete cascade
/

alter table DER_SEGMENT_RESULT
  add constraint FK_DER_SEGMENT_RESULT_EXT_SYS foreign key (EXTERNAL_SYSTEM_ID)
    references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
   on delete cascade
/

alter table DER_SEGMENT_RESULT
  add constraint FK_DER_SEGMENT_RESULT_SCEN foreign key (SCENARIO_ID)
    references SCENARIO (SCENARIO_ID)
   on delete cascade
/

alter table DER_SEGMENT_RESULT
  add constraint FK_DER_SEGMENT_RESULT_FEEDER foreign key (FEEDER_ID)
     references TX_FEEDER (FEEDER_ID)
     on delete cascade
/

alter table DER_SEGMENT_RESULT
  add constraint FK_DER_SEGMENT_RESULT_SS foreign key (SUB_STATION_ID)
     references TX_SUB_STATION (SUB_STATION_ID)
     on delete cascade
/

alter table DER_SEGMENT_RESULT
  add constraint FK_DER_SEGMENT_RESULT_SZ foreign key (SERVICE_ZONE_ID)
     references SERVICE_ZONE (SERVICE_ZONE_ID)
     on delete cascade
/

alter table DER_SEGMENT_RESULT_DATA
  add constraint FK_DER_SEG_RESULT_DATA_ID foreign key (DER_SEGMENT_RESULT_ID)
    references DER_SEGMENT_RESULT (DER_SEGMENT_RESULT_ID)
   on delete cascade
/

alter table VPP_PEAK_CAPACITY_DESIGN
	add constraint FK_VPP_PEAK_CAPACITY_VPP foreign key (VPP_ID)
		references VIRTUAL_POWER_PLANT (VPP_ID)
		on delete cascade
/

alter table VPP_PEAK_CAPACITY_DESIGN
	add constraint FK_VPP_PEAK_CAPACITY_SCEN foreign key (SCENARIO_ID)
		references SCENARIO (SCENARIO_ID)
		on delete cascade
/

alter table VPP_PEAK_CAPACITY_DESIGN
	add constraint FK_VPP_PEAK_CAPACITY_PROC foreign key (PROCESS_ID)
		references PROCESS_LOG (PROCESS_ID)
/

alter table IT_SCHEDULE_MANAGEMENT_MAP
	add constraint FK_IT_SCHED_MGMT_MAP_TXN foreign key (TRANSACTION_ID)
		references INTERCHANGE_TRANSACTION (TRANSACTION_ID)
/

alter table IT_SCHEDULE_MANAGEMENT_MAP
	add constraint FK_IT_SCHED_MGMT_MAP_STATEMENT foreign key (STATEMENT_TYPE_ID)
		references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table DER_SEG_RESULT_IS_EXTERNAL
	add constraint FK_DER_SEG_RESULT_ISEXT_PROG foreign key (PROGRAM_ID)
		references PROGRAM (PROGRAM_ID)
/

alter table DER_SEG_RESULT_IS_EXTERNAL
	add constraint FK_DER_SEG_RESULT_ISEXT_ZONE foreign key (SERVICE_ZONE_ID)
		references SERVICE_ZONE (SERVICE_ZONE_ID)
/

alter table DER_SEG_RESULT_IS_EXTERNAL
	add constraint FK_DER_SEG_RESULT_ISEXT_EXTSYS foreign key (EXTERNAL_SYSTEM_ID)
		references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
/

alter table DER_SEG_RESULT_IS_EXTERNAL
	add constraint FK_DER_SEG_RESULT_ISEXT_SCEN foreign key (SCENARIO_ID)
		references SCENARIO (SCENARIO_ID)
/

alter table DER_SEG_RESULT_DEFAULT_EXT
	add constraint FK_DER_SEG_RESULT_DEFAULT_PROG foreign key (PROGRAM_ID)
		references PROGRAM (PROGRAM_ID)
/

alter table DER_SEG_RESULT_DEFAULT_EXT
	add constraint FK_DER_SEG_RESULT_DFLT_EXTSYS foreign key (EXTERNAL_SYSTEM_ID)
		references EXTERNAL_SYSTEM (EXTERNAL_SYSTEM_ID)
/

alter table ACCOUNT_TOU_USAGE_FACTOR
	add constraint FK_ACCT_TOU_USG_FACTOR_CASE foreign key (CASE_ID)
		references CASE_LABEL (CASE_ID)
/

ALTER TABLE ACCOUNT_TOU_USAGE_FACTOR
	ADD CONSTRAINT FK_ACCT_TOU_USG_FACTOR_ACCT FOREIGN KEY (ACCOUNT_ID)
		REFERENCES ACCOUNT (ACCOUNT_ID)
		ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_TOU_USAGE_FACTOR
	ADD CONSTRAINT FK_ACCT_TOU_USG_FCTR_TEMPLATE FOREIGN KEY (TEMPLATE_ID)
		REFERENCES TEMPLATE (TEMPLATE_ID)
/

ALTER TABLE ACCOUNT_TOU_USG_FACTOR_PERIOD
	ADD CONSTRAINT FK_ACCT_TOU_USG_FACTOR_PERIOD FOREIGN KEY (TOU_USAGE_FACTOR_ID)
		REFERENCES ACCOUNT_TOU_USAGE_FACTOR (TOU_USAGE_FACTOR_ID)
		ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_TOU_USG_FACTOR_PERIOD
	ADD CONSTRAINT FK_ACT_TOU_USG_FCT_PERIOD_PER FOREIGN KEY (PERIOD_ID)
		REFERENCES PERIOD (PERIOD_ID)
/

alter table METER_TOU_USAGE_FACTOR
	add constraint FK_METER_TOU_USG_FACTOR_CASE foreign key (CASE_ID)
		references CASE_LABEL (CASE_ID)
/

ALTER TABLE METER_TOU_USAGE_FACTOR
	ADD CONSTRAINT FK_METER_TOU_USG_FACTOR_MTR FOREIGN KEY (METER_ID)
		REFERENCES METER (METER_ID)
		ON DELETE CASCADE
/

ALTER TABLE METER_TOU_USAGE_FACTOR
	ADD CONSTRAINT FK_METER_TOU_USG_FCTR_TEMPLATE FOREIGN KEY (TEMPLATE_ID)
		REFERENCES TEMPLATE (TEMPLATE_ID)
/

ALTER TABLE METER_TOU_USAGE_FACTOR_PERIOD
	ADD CONSTRAINT FK_METER_TOU_USG_FACTOR_PERIOD FOREIGN KEY (TOU_USAGE_FACTOR_ID)
		REFERENCES METER_TOU_USAGE_FACTOR (TOU_USAGE_FACTOR_ID)
		ON DELETE CASCADE
/

ALTER TABLE METER_TOU_USAGE_FACTOR_PERIOD
	ADD CONSTRAINT FK_MTR_TOU_USG_FCT_PERIOD_PER FOREIGN KEY (PERIOD_ID)
		REFERENCES PERIOD (PERIOD_ID)
/

alter table SCHEDULE_GROUP
	add constraint FK_SCHED_GROUP_SVC_PT foreign key (SERVICE_POINT_ID)
		references SERVICE_POINT (SERVICE_POINT_ID)
/

alter table SERVICE_OBLIGATION_ANC_SVC
	add constraint FK_SVC_OBL_ANC_SVC_SERVICE_OBL foreign key (SERVICE_OBLIGATION_ID)
		references SERVICE_OBLIGATION (SERVICE_OBLIGATION_ID)
    on delete cascade
/

alter table SERVICE_OBLIGATION_ANC_SVC
	add constraint FK_SVC_OBL_ANC_SVC_ID foreign key (ANCILLARY_SERVICE_ID)
		references ANCILLARY_SERVICE (ANCILLARY_SERVICE_ID)
    on delete cascade
/

alter table ANCILLARY_SERVICE
	add constraint FK_ANC_SVC_IT_COMMODITY foreign key (IT_COMMODITY_ID)
		references IT_COMMODITY (COMMODITY_ID)
/

alter table PROXY_DAY_METHOD
	add constraint FK_PROXY_DAY_METHOD_TEMPLATE foreign key (TEMPLATE_ID)
		references TEMPLATE (TEMPLATE_ID)
/

alter table PROXY_DAY_METHOD
	add constraint FK_PROXY_DAY_METHOD_STATION foreign key (STATION_ID)
		references WEATHER_STATION (STATION_ID)
/

alter table PROXY_DAY_METHOD
	add constraint FK_PROXY_DAY_METHOD_PARAMETER foreign key (PARAMETER_ID)
		references WEATHER_PARAMETER (PARAMETER_ID)
/

alter table PROXY_DAY_METHOD
	add constraint FK_PROXY_DAY_METHOD_SYS_LOAD foreign key (SYSTEM_LOAD_ID)
		references SYSTEM_LOAD (SYSTEM_LOAD_ID)
/

alter table PROXY_DAY_METHOD
	add constraint FK_PROXY_DAY_METHOD_HOL_SET foreign key (HOLIDAY_SET_ID)
		references HOLIDAY_SET (HOLIDAY_SET_ID)
/

alter table ACCOUNT_PROXY_DAY_METHOD
	add constraint FK_ACCOUNT_PROXY_DAY_METHOD foreign key (ACCOUNT_ID)
		references ACCOUNT (ACCOUNT_ID)
		on delete cascade
/

alter table ACCOUNT_PROXY_DAY_METHOD
	add constraint FK_ACCOUNT_PROXY_DAY_METHOD2 foreign key (PROXY_DAY_METHOD_ID)
		references PROXY_DAY_METHOD (PROXY_DAY_METHOD_ID)
/

alter table SYSTEM_MESSAGE
	add constraint FK_SYSTEM_MESSAGE_OCCURRENCE foreign key (OCCURRENCE_ID)
		references SYSTEM_ALERT_OCCURRENCE (OCCURRENCE_ID)
		on delete set null
/

alter table SYSTEM_MESSAGE
	add constraint FK_SYSTEM_MESSAGE_PROCESS_LOG foreign key (PROCESS_ID)
		references PROCESS_LOG (PROCESS_ID)
		on delete set null
/

alter table SYSTEM_MESSAGE
	add constraint FK_SYSTEM_MESSAGE_FROM_USER foreign key (FROM_USER_ID)
		references APPLICATION_USER (USER_ID)
/

alter table SYSTEM_MESSAGE
	add constraint FK_SYSTEM_MESSAGE_TO_USER foreign key (TO_USER_ID)
		references APPLICATION_USER (USER_ID)
/
alter table RETAIL_INVOICE
   add constraint FK1_RET_INV_PSE foreign key (RECIPIENT_PSE_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
/

alter table RETAIL_INVOICE
   add constraint FK2_RET_INV_PSE foreign key (SENDER_PSE_ID)
      references PURCHASING_SELLING_ENTITY (PSE_ID)
/

alter table RETAIL_INVOICE
   add constraint FK_RET_INV_PROCESS_LOG foreign key (PROCESS_ID)
      references PROCESS_LOG (PROCESS_ID)
/

alter table RETAIL_INVOICE
   add constraint FK_RET_INV_STATEMENT_TYPE foreign key (STATEMENT_TYPE_ID)
      references STATEMENT_TYPE (STATEMENT_TYPE_ID)
/


alter table RETAIL_INVOICE_LINE
   add constraint FK_RET_INV_LINE_RET_INV foreign key (RETAIL_INVOICE_ID)
      references RETAIL_INVOICE (RETAIL_INVOICE_ID)
	  on delete cascade
/

alter table RETAIL_INVOICE_LINE
   add constraint FK_RET_INV_LINE_ACCOUNT foreign key (ACCOUNT_ID)
      references ACCOUNT (ACCOUNT_ID)
/

alter table RETAIL_INVOICE_LINE
   add constraint FK_RET_INV_LINE_METER foreign key (METER_ID)
      references METER (METER_ID)
/

alter table RETAIL_INVOICE_LINE
   add constraint FK_RET_INV_LINE_SERVICE_POINT foreign key (SERVICE_POINT_ID)
      references SERVICE_POINT (SERVICE_POINT_ID)
/

alter table RETAIL_INVOICE_COMPONENT
   add constraint FK_RET_INV_COMP_RET_INV foreign key (RETAIL_INVOICE_ID)
      references RETAIL_INVOICE (RETAIL_INVOICE_ID)
	  on delete cascade
/

alter table RETAIL_INVOICE_COMPONENT
   add constraint FK_RET_INV_COMP_PRODUCT foreign key (PRODUCT_ID)
      references PRODUCT (PRODUCT_ID)
/

alter table RETAIL_INVOICE_COMPONENT
   add constraint FK_RET_INV_COMP_COMPONENT foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
/

alter table RETAIL_INVOICE_COMPONENT
   add constraint FK_RET_INV_COMP_PERIOD foreign key (PERIOD_ID)
      references PERIOD (PERIOD_ID)
/

alter table RETAIL_INVOICE_LINE_COMPONENT
   add constraint FK_RET_INV_LN_COMP_RET_INV foreign key (RETAIL_INVOICE_LINE_ID)
      references RETAIL_INVOICE_LINE (RETAIL_INVOICE_LINE_ID)
	  on delete cascade
/

alter table RETAIL_INVOICE_LINE_COMPONENT
   add constraint FK_RET_INV_LN_COMP_PRODUCT foreign key (PRODUCT_ID)
      references PRODUCT (PRODUCT_ID)
/

alter table RETAIL_INVOICE_LINE_COMPONENT
   add constraint FK_RET_INV_LN_COMP_COMPONENT foreign key (COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
/

alter table RETAIL_INVOICE_LINE_COMPONENT
   add constraint FK_RET_INV_LN_COMP_PERIOD foreign key (PERIOD_ID)
      references PERIOD (PERIOD_ID)
/

alter table RETAIL_INVOICE_PRICING_RESULT
   add constraint FK_RET_INV_PR_RET_INV_LN_COMP foreign key (RETAIL_INVOICE_LINE_COMP_ID)
      references RETAIL_INVOICE_LINE_COMPONENT (RETAIL_INVOICE_LINE_COMP_ID)
	  on delete cascade
/

alter table RETAIL_INVOICE_PRICING_RESULT
   add constraint FK_RET_INV_PR_TAXED_PRODUCT foreign key (TAXED_PRODUCT_ID)
      references PRODUCT (PRODUCT_ID)
/

alter table RETAIL_INVOICE_PRICING_RESULT
   add constraint FK_RET_INV_PR_TAXED_COMP foreign key (TAXED_COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
/

alter table RETAIL_INVOICE_PRICING_RESULT
   add constraint FK_RET_INV_PR_CHILD_COMP foreign key (CHILD_COMPONENT_ID)
      references COMPONENT (COMPONENT_ID)
/

alter table RETAIL_INVOICE_PRICING_RESULT
   add constraint FK_RET_INV_PR_PERIOD foreign key (PERIOD_ID)
      references PERIOD (PERIOD_ID)
/

alter table SEASON_TEMPLATE
	add constraint FK_SEASON_TEMPLATE_TEMPLATE foreign key (TEMPLATE_ID)
		references TEMPLATE (TEMPLATE_ID)
		on delete cascade
/

alter table SEASON_TEMPLATE
	add constraint FK_SEASON_TEMPLATE_SEASON foreign key (SEASON_ID)
		references SEASON (SEASON_ID)
/

alter table SEASON_TEMPLATE
	add constraint FK_SEASON_TEMPLATE_PERIOD foreign key (PERIOD_ID)
		references PERIOD (PERIOD_ID)
/

alter table TEMPLATE_SEASON_DAY_NAME
	add constraint FK_TEMPLATE_SEASON_DAY_TEMP foreign key (TEMPLATE_ID)
		references TEMPLATE (TEMPLATE_ID)
		on delete cascade
/

alter table TEMPLATE_SEASON_DAY_NAME
	add constraint FK_TEMPLATE_SEASON_DAY_SEAS foreign key (SEASON_ID)
		references SEASON (SEASON_ID)
/

alter table TEMPLATE_DATES
	add constraint FK_TEMPLATE_DATES_TIME_ZONE foreign key (TIME_ZONE)
		references SYSTEM_TIME_ZONE (TIME_ZONE)
		on delete cascade
/

alter table TEMPLATE_DATES
	add constraint FK_TEMPLATE_DATES_TEMPLATE foreign key (TEMPLATE_ID)
		references TEMPLATE (TEMPLATE_ID)
		on delete cascade
/

alter table TEMPLATE_DATES
	add constraint FK_TEMPLATE_DATES_HOLIDAY_SET foreign key (HOLIDAY_SET_ID)
		references HOLIDAY_SET (HOLIDAY_SET_ID)
		on delete cascade
/

alter table TEMPLATE_DATES
	add constraint FK_TEMPLATE_DATES_DAY_TYPE foreign key (DAY_TYPE_ID)
		references TEMPLATE_DAY_TYPE (DAY_TYPE_ID)
/

alter table TEMPLATE_DAY_TYPE
	add constraint FK_TEMPLATE_DAY_TYPE_TEMPLATE foreign key (TEMPLATE_ID)
		references TEMPLATE (TEMPLATE_ID)
		on delete cascade
/

alter table TEMPLATE_DAY_TYPE
	add constraint FK_TEMPLATE_DAY_TYPE_SEASON foreign key (SEASON_ID)
		references SEASON (SEASON_ID)
/

alter table TEMPLATE_DAY_TYPE_PERIOD
	add constraint FK_TEMPLATE_DAY_TYPE_PER_DT foreign key (DAY_TYPE_ID)
		references TEMPLATE_DAY_TYPE (DAY_TYPE_ID)
		on delete cascade
/

alter table TEMPLATE_DAY_TYPE_PERIOD
	add constraint FK_TEMPLATE_DAY_TYPE_PER_PER foreign key (PERIOD_ID)
		references PERIOD (PERIOD_ID)
/

ALTER TABLE ROML_ENTITY_DEPENDS
	ADD CONSTRAINT FK_ROML_ENTITY_DEPENDS_ID FOREIGN KEY (ROML_ENTITY_NID)
		REFERENCES ROML_ENTITY(ROML_ENTITY_NID)
		ON DELETE CASCADE
/

ALTER TABLE ROML_ENTITY_DEPENDS
	ADD CONSTRAINT FK_ROML_ENTITY_DEPENDS_ID_DEP FOREIGN KEY (DEP_ROML_ENTITY_NID)
		REFERENCES ROML_ENTITY(ROML_ENTITY_NID)
		ON DELETE CASCADE
/

ALTER TABLE ROML_COL_RULES_MAP
	ADD CONSTRAINT FK_ROML_COL_RULES_MAP FOREIGN KEY (ROML_ENTITY_NID)
		REFERENCES ROML_ENTITY(ROML_ENTITY_NID)
		ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_SUB_AGG_AGGREGATION
    ADD CONSTRAINT FK_ACCOUNT_SA_AGG_ACCOUNT FOREIGN KEY (ACCOUNT_ID)
        REFERENCES ACCOUNT(ACCOUNT_ID)
        ON DELETE CASCADE
/

ALTER TABLE METER_SUB_AGG_AGGREGATION
    ADD CONSTRAINT FK_METER_SA_AGG_METER FOREIGN KEY (METER_ID)
        REFERENCES METER(METER_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_ACCT FOREIGN KEY (AGGREGATE_ACCOUNT_ID)
        REFERENCES ACCOUNT(ACCOUNT_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_SL FOREIGN KEY (SERVICE_LOCATION_ID)
        REFERENCES SERVICE_LOCATION(SERVICE_LOCATION_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_EDC FOREIGN KEY (EDC_ID)
        REFERENCES ENERGY_DISTRIBUTION_COMPANY(EDC_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_SP FOREIGN KEY (SERVICE_POINT_ID)
        REFERENCES SERVICE_POINT(SERVICE_POINT_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_SZ FOREIGN KEY (SERVICE_ZONE_ID)
        REFERENCES SERVICE_ZONE(SERVICE_ZONE_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_SG FOREIGN KEY (SCHEDULE_GROUP_ID)
        REFERENCES SCHEDULE_GROUP(SCHEDULE_GROUP_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_CAL FOREIGN KEY (CALENDAR_ID)
        REFERENCES CALENDAR(CALENDAR_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_WS FOREIGN KEY (WEATHER_STATION_ID)
        REFERENCES WEATHER_STATION(STATION_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_LF FOREIGN KEY (LOSS_FACTOR_ID)
        REFERENCES LOSS_FACTOR(LOSS_FACTOR_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_REV_PROD FOREIGN KEY (REVENUE_PRODUCT_ID)
        REFERENCES PRODUCT(PRODUCT_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_CST_PROD FOREIGN KEY (COST_PRODUCT_ID)
        REFERENCES PRODUCT(PRODUCT_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_TEMPLATE FOREIGN KEY (TOU_TEMPLATE_ID)
        REFERENCES TEMPLATE(TEMPLATE_ID)
        ON DELETE CASCADE
/

ALTER TABLE ACCOUNT_AGGREGATE_STATIC_DATA
    ADD CONSTRAINT FK_ACCT_AGG_STAT_DATA_BILL_CYC FOREIGN KEY (BILL_CYCLE_ID)
        REFERENCES BILL_CYCLE(BILL_CYCLE_ID)
        ON DELETE CASCADE
/

ALTER TABLE METER_USAGE_FACTOR
   ADD CONSTRAINT FK_METER_USAGE_FACTOR_METER FOREIGN KEY (METER_ID)
	REFERENCES METER(METER_ID)
	ON DELETE CASCADE
/

ALTER TABLE METER_USAGE_FACTOR
  ADD CONSTRAINT FK_METER_USAGE_FACTOR_CAL FOREIGN KEY (SOURCE_CALENDAR_ID)
	REFERENCES CALENDAR(CALENDAR_ID)
	ON DELETE CASCADE
/

/*==============================================================*/
/* Table: RETAIL_INVOICE_DISPUTE                                */
/*==============================================================*/

CREATE TABLE RETAIL_INVOICE_DISPUTE (
    DISPUTE_ID 						NUMBER 		NOT NULL,
    DISPUTE_TYPE 					NUMBER 		NOT NULL,
    RETAIL_INVOICE_ID				NUMBER		NOT NULL,
	ACCOUNT_ID						NUMBER		NOT NULL,
	METER_ID						NUMBER		NOT NULL,
	SERVICE_POINT_ID				NUMBER		NOT NULL,
	PRODUCT_ID						NUMBER		NOT NULL,
	COMPONENT_ID					NUMBER		NOT NULL,
	PERIOD_ID						NUMBER,
	BEGIN_DATE						DATE		NOT NULL,
	END_DATE						DATE,
	INTERNAL_QUANTITY				NUMBER,
	INTERNAL_AMOUNT					NUMBER,
	EXTERNAL_QUANTITY				NUMBER,
	EXTERNAL_AMOUNT					NUMBER,
	ORIGINAL_RETAIL_INVOICE_ID		NUMBER,
	ORIGINAL_PRODUCT_ID				NUMBER,
	ORIGINAL_COMPONENT_ID			NUMBER,
	ORIGINAL_INT_QUANTITY			NUMBER,
	ORIGINAL_INT_AMOUNT				NUMBER,
	ORIGINAL_EXT_QUANTITY			NUMBER,
	ORIGINAL_EXT_AMOUNT				NUMBER,
	OOT_VOLUME_AMOUNT_THRESH		NUMBER,
	OOT_VOLUME_PERCENT_THRESH		NUMBER,
	OOT_CHARGE_AMOUNT_THRESH		NUMBER,
	OOT_CHARGE_PERCENT_THRESH		NUMBER,
	SETTLEMENT_RUN_ON				DATE,
	DISPUTE_STATUS					VARCHAR2(128),
	PROCESS_STATUS					VARCHAR2(128),
	DISPUTE_CATEGORY				VARCHAR2(128),
	UPDATED_BY						VARCHAR2(64),
	UPDATED_DATE					DATE,
	NOTES							VARCHAR2(4000),	
    CONSTRAINT PK_RETAIL_INVOICE_DISPUTE PRIMARY KEY (DISPUTE_ID)
	USING INDEX TABLESPACE NERO_INDEX
    STORAGE
    (
    	initial 64K
        next 64K
        pctincrease 0
    )
)
STORAGE
(
    initial 128K
    next 128K
    pctincrease 0
)
TABLESPACE NERO_DATA
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_RETAIL_INVOICE_ID FOREIGN KEY (RETAIL_INVOICE_ID)
    REFERENCES RETAIL_INVOICE(RETAIL_INVOICE_ID)
    ON DELETE CASCADE
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_ACCOUNT_ID FOREIGN KEY (ACCOUNT_ID)
    REFERENCES ACCOUNT(ACCOUNT_ID)
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_METER_ID FOREIGN KEY (METER_ID)
    REFERENCES METER(METER_ID)
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_SERVICE_POINT_ID FOREIGN KEY (SERVICE_POINT_ID)
    REFERENCES SERVICE_POINT(SERVICE_POINT_ID)
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_PRODUCT_ID FOREIGN KEY (PRODUCT_ID)
    REFERENCES PRODUCT(PRODUCT_ID)
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_COMPONENT_ID FOREIGN KEY (COMPONENT_ID)
    REFERENCES COMPONENT(COMPONENT_ID)
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_PERIOD_ID FOREIGN KEY (PERIOD_ID)
    REFERENCES PERIOD(PERIOD_ID)
/

CREATE INDEX RETAIL_INVOICE_DISPUTE_IX01 ON RETAIL_INVOICE_DISPUTE
(
    RETAIL_INVOICE_ID ASC,
    ACCOUNT_ID ASC,
    METER_ID ASC,
    SERVICE_POINT_ID ASC,
    PRODUCT_ID ASC,
    COMPONENT_ID ASC,
    PERIOD_ID ASC
)
STORAGE
(
    initial 64K
    next 64K
    pctincrease 0
)
TABLESPACE NERO_INDEX
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_ORIG_RETAIL_INVOICE_ID FOREIGN KEY (ORIGINAL_RETAIL_INVOICE_ID)
    REFERENCES RETAIL_INVOICE(RETAIL_INVOICE_ID)
    ON DELETE CASCADE
/
CREATE INDEX RETAIL_INVOICE_DISPUTE_IX02 ON RETAIL_INVOICE_DISPUTE(ORIGINAL_RETAIL_INVOICE_ID ASC)
STORAGE
(
    initial 64K
    next 64K
    pctincrease 0
)
TABLESPACE NERO_INDEX
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_ORIG_PRODUCT_ID FOREIGN KEY (ORIGINAL_PRODUCT_ID)
    REFERENCES PRODUCT(PRODUCT_ID)
/
CREATE INDEX RETAIL_INVOICE_DISPUTE_IX03 ON RETAIL_INVOICE_DISPUTE(ORIGINAL_PRODUCT_ID ASC)
STORAGE
(
    initial 64K
    next 64K
    pctincrease 0
)
TABLESPACE NERO_INDEX
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
    ADD CONSTRAINT FK_RID_ORIG_COMPONENT_ID FOREIGN KEY (ORIGINAL_COMPONENT_ID)
    REFERENCES COMPONENT(COMPONENT_ID)
/
CREATE INDEX RETAIL_INVOICE_DISPUTE_IX04 ON RETAIL_INVOICE_DISPUTE(ORIGINAL_COMPONENT_ID ASC)
STORAGE
(
    initial 64K
    next 64K
    pctincrease 0
)
TABLESPACE NERO_INDEX
/

ALTER TABLE RETAIL_INVOICE_DISPUTE
ADD CONSTRAINT CK01_RETAIL_INVOICE_DISPUTE
CHECK
(
    DISPUTE_TYPE BETWEEN 0 AND 2
)
/


COMMENT ON TABLE RETAIL_INVOICE_DISPUTE IS
  'Retail Invoice Dispute Management table.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.DISPUTE_ID IS
  'Sequence generated (DISPUTE_ID sequence) unique ID for a Dispute.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.DISPUTE_TYPE IS
  'Type of dispute: 0=Manual,1=Duplicate,2=Out-of-Tolerance'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.RETAIL_INVOICE_ID IS
  'ID of the associated Retail Invoice'
/ 
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.ACCOUNT_ID IS
  'ID of the associated Account'
/   
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.METER_ID IS
  'ID of the associated Meter'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.SERVICE_POINT_ID IS
  'ID of the associated Service Point'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.PRODUCT_ID IS
  'ID of the associated Product'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.COMPONENT_ID IS
  'ID of the associated Component'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.PERIOD_ID IS
  'ID of the associated Period'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.BEGIN_DATE IS
  'Begin Date of the associated Component'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.END_DATE IS
  'End Date of the associated Component'
/ 
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.INTERNAL_QUANTITY IS
  'Captured Internal Quantity from the Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.INTERNAL_AMOUNT IS
  'Caputred Internal Amount from the Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.EXTERNAL_QUANTITY IS
  'Captured External Quantity from the Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.EXTERNAL_AMOUNT IS
  'Captured External Amount from the Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.ORIGINAL_PRODUCT_ID IS
  'ID of the duplicated Product'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.ORIGINAL_COMPONENT_ID IS
  'ID of the duplicated Component'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.ORIGINAL_INT_QUANTITY IS
  'Captured Internal Quantity from the duplicated Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.ORIGINAL_INT_AMOUNT IS
  'Captured Internal Amount from the duplicated Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.ORIGINAL_EXT_QUANTITY IS
  'Captured External Quantity from the duplicated Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.ORIGINAL_EXT_AMOUNT IS
  'Captured External Amount from the duplicated Invoice line'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.OOT_VOLUME_AMOUNT_THRESH IS
  'Captured out of tolerance volume amount threshold.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.OOT_VOLUME_PERCENT_THRESH IS
  'Captured out of tolerance volume percent threshold.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.OOT_CHARGE_AMOUNT_THRESH IS
  'Captured out of tolerance charge amount threshold.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.OOT_CHARGE_PERCENT_THRESH IS
  'Captured out of tolerance charge percent threshold.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.SETTLEMENT_RUN_ON IS
  'Captured date the settlement was run when the dispute was created.'
/ 
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.DISPUTE_STATUS IS
  'System setting for the status of the dispute (e.g., Open).'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.PROCESS_STATUS IS
  'System setting for the process status of the dispute (e.g., New).'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.DISPUTE_CATEGORY IS
  'System setting for the category of the dispute (e.g., Manual).'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.UPDATED_BY IS
  'User display name (or user name if display name is null) who last updated the dispute.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.UPDATED_DATE IS
  'When the dispute was last updated.'
/  
COMMENT ON COLUMN RETAIL_INVOICE_DISPUTE.NOTES IS
  'User-defined notes for the dispute.'
/  

/*==============================================================*/
/* Table: COMPONENT_TOLERANCES                                  */
/*==============================================================*/

CREATE TABLE COMPONENT_TOLERANCES (
    COMPONENT_ID					NUMBER 		NOT NULL,
    VOLUME_AMOUNT_THRESH 			NUMBER,
    VOLUME_PERCENT_THRESH			NUMBER,
	CHARGE_AMOUNT_THRESH			NUMBER,
	CHARGE_PERCENT_THRESH			NUMBER,
	UPDATED_BY						VARCHAR2(64),
	UPDATED_DATE					DATE,	
    CONSTRAINT PK_COMPONENT_TOLERANCES PRIMARY KEY (COMPONENT_ID)
	USING INDEX TABLESPACE NERO_INDEX
    STORAGE
    (
    	initial 64K
        next 64K
        pctincrease 0
    )
)
STORAGE
(
    initial 128K
    next 128K
    pctincrease 0
)
TABLESPACE NERO_DATA
/

ALTER TABLE COMPONENT_TOLERANCES
    ADD CONSTRAINT FK_CT_COMPONENT_ID FOREIGN KEY (COMPONENT_ID)
    REFERENCES COMPONENT(COMPONENT_ID)
/


COMMENT ON TABLE COMPONENT_TOLERANCES IS
  'Component Tolerances Management table.'
/  
COMMENT ON COLUMN COMPONENT_TOLERANCES.COMPONENT_ID IS
  'ID of the associated Component.'
/  
COMMENT ON COLUMN COMPONENT_TOLERANCES.VOLUME_AMOUNT_THRESH IS
  'Defined volume amount threshold.'
/  
COMMENT ON COLUMN COMPONENT_TOLERANCES.VOLUME_PERCENT_THRESH IS
  'Defined volume percent threshold.'
/  
COMMENT ON COLUMN COMPONENT_TOLERANCES.CHARGE_AMOUNT_THRESH IS
  'Defined charge amount threshold.'
/  
COMMENT ON COLUMN COMPONENT_TOLERANCES.CHARGE_PERCENT_THRESH IS
  'Defined charge percent threshold.'
/  
COMMENT ON COLUMN COMPONENT_TOLERANCES.UPDATED_BY IS
  'User display name (or user name if display name is null) who last updated the tolerance.'
/  
COMMENT ON COLUMN COMPONENT_TOLERANCES.UPDATED_DATE IS
  'When the tolerance was last updated.'
/  


create table PDM_CANDIDATE_DAYS
(
  proxy_day_method_id      NUMBER(9) not null,
  forecast_day             DATE not null,
  candidate_day            DATE not null,
  candidate_delta          NUMBER
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );
  
alter table PDM_CANDIDATE_DAYS
  add constraint PK_PDM_CANDIDATE_DAYS primary key 
  (proxy_day_method_id, forecast_day, candidate_day);
spool off
exit
