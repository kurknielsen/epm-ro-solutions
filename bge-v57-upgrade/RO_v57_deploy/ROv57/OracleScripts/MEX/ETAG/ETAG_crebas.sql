/*==============================================================*/
/* Table: ETAG                                                  */
/*==============================================================*/


create table ETAG  (
   ETAG_ID              NUMBER(9)  not null,
   ETAG_NAME            VARCHAR2(32),
   ETAG_ALIAS           VARCHAR2(32),
   ETAG_DESC            VARCHAR2(256),
   TAG_IDENT            VARCHAR2(32) not null,
   GCA_CODE             VARCHAR2(7) not null,
   PSE_CODE             VARCHAR2(7) not null,
   TAG_CODE             VARCHAR2(7) not null,
   LCA_CODE             VARCHAR2(7) not null,
   EXTERNAL_IDENTIFIER  VARCHAR2(32),
   ETAG_STATUS          VARCHAR2(32),
   SECURITY_KEY         VARCHAR2(20),
   WSCC_PRESCHEDULE_FLAG  CHAR(1),
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

-- Foreign Key
ALTER TABLE ETAG_TRANSACTION
    ADD CONSTRAINT FK1_ETAG_TRANSACTION
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/
ALTER TABLE ETAG_TRANSACTION
    ADD CONSTRAINT FK2_ETAG_TRANSACTION
    FOREIGN KEY (TRANSACTION_ID)
    REFERENCES INTERCHANGE_TRANSACTION(TRANSACTION_ID) ON DELETE CASCADE
/
  

/*==============================================================*/
/* Table: ETAG_MARKET_SEGMENT                                   */
/*==============================================================*/

create table ETAG_MARKET_SEGMENT  (
   ETAG_ID                     NUMBER(9)  not null,
   MARKET_SEGMENT_NID          NUMBER(9)  not null,
   CURRENT_CORRECTION_NID      NUMBER(9)  not null,
   PSE_CODE                    NUMBER(9)  not null,
   ENERGY_PRODUCT_REF          NUMBER(4),
   CONTRACT_NUMBER_LIST_ID     NUMBER(9),
   MISC_INFO_LIST_ID           NUMBER(9),
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

-- Foreign Key
ALTER TABLE ETAG_MARKET_SEGMENT
    ADD CONSTRAINT FK_ETAG_MARKET_SEGMENT
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/


/*==============================================================*/
/* Table: ETAG_TRANSMISSION_SEGMENT                             */
/*==============================================================*/

create table ETAG_TRANSMISSION_SEGMENT  (
   ETAG_ID                  NUMBER(9)  not null,
   PHYSICAL_SEGMENT_NID     NUMBER(9)  not null,
   SEGMENT_TYPE             VARCHAR2(32),
   MARKET_SEGMENT_NID       NUMBER(9),
   TP_CODE                  NUMBER(9),
   POR_CODE                 NUMBER(9),
   POD_CODE                 NUMBER(9),
   CURRENT_CORRECTION_NID   NUMBER(4),
   SCHEDULING_ENTITY_LIST_ID  NUMBER(9),
   MISC_INFO_LIST_ID        NUMBER(9),
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

-- Foreign Key
ALTER TABLE ETAG_TRANSMISSION_SEGMENT
    ADD CONSTRAINT FK_ETAG_TRANSMISSION_SEGMENT
    FOREIGN KEY (ETAG_ID, MARKET_SEGMENT_NID)
    REFERENCES ETAG_MARKET_SEGMENT(ETAG_ID, MARKET_SEGMENT_NID) ON DELETE CASCADE
/


/*==============================================================*/
/* Table: ETAG_TRANSMISSION_PROFILE                             */
/*==============================================================*/

create table ETAG_TRANSMISSION_PROFILE  (
   ETAG_ID                  NUMBER(9)  not null,
   PHYSICAL_SEGMENT_NID     NUMBER(9)  not null,
   POR_ETAG_PROFILE_NID     NUMBER(9)  not null,
   POD_ETAG_PROFILE_NID     NUMBER(9)  not null,
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

-- Foreign Key
ALTER TABLE ETAG_TRANSMISSION_PROFILE
    ADD CONSTRAINT FK_ETAG_TRANSMISSION_PROFILE
    FOREIGN KEY (ETAG_ID, PHYSICAL_SEGMENT_NID)
    REFERENCES ETAG_TRANSMISSION_SEGMENT(ETAG_ID, PHYSICAL_SEGMENT_NID) ON DELETE CASCADE
/


/*==============================================================*/
/* Table: ETAG_RESOURCE_SEGMENT                                 */
/*==============================================================*/

create table ETAG_RESOURCE_SEGMENT  (
   ETAG_ID                  NUMBER(9)  not null,
   PHYSICAL_SEGMENT_NID     NUMBER(9)  not null,
   SEGMENT_TYPE             VARCHAR2(32),
   MARKET_SEGMENT_NID       NUMBER(9),
   CURRENT_CORRECTION_NID   NUMBER(4),
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

-- Foreign Key
ALTER TABLE ETAG_RESOURCE_SEGMENT
    ADD CONSTRAINT FK_ETAG_RESOURCE_SEGMENT
    FOREIGN KEY (ETAG_ID, MARKET_SEGMENT_NID)
    REFERENCES ETAG_MARKET_SEGMENT(ETAG_ID, MARKET_SEGMENT_NID) ON DELETE CASCADE
/


/*==============================================================*/
/* Table: ETAG_RESOURCE                                         */
/*==============================================================*/

create table ETAG_RESOURCE  (
   ETAG_ID                  NUMBER(9)  not null,
   PHYSICAL_SEGMENT_NID     NUMBER(9)  not null,
   PROFILE_NID              NUMBER(9)  not null,
   TAGGING_POINT_NID        NUMBER(9),
   CONTRACT_NUMBER_LIST_ID  NUMBER(9),
   MISC_INFO_LIST_ID        NUMBER(9),
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

-- Foreign Key
ALTER TABLE ETAG_RESOURCE
    ADD CONSTRAINT FK_ETAG_RESOURCE
    FOREIGN KEY (ETAG_ID, PHYSICAL_SEGMENT_NID)
    REFERENCES ETAG_RESOURCE_SEGMENT(ETAG_ID, PHYSICAL_SEGMENT_NID) ON DELETE CASCADE
/


/*==============================================================*/
/* Table: ETAG_TRANSMISSION_ALLOCATION                          */
/*==============================================================*/

create table ETAG_TRANSMISSION_ALLOCATION  (
   ETAG_ID                       NUMBER(9)  not null,
   TRANSMISSION_ALLOCATION_NID   NUMBER(9)  not null,
   PHYSICAL_SEGMENT_NID          NUMBER(9)  not null,
   CURRENT_CORRECTION_NID        NUMBER(9),
   TRANSMISSION_PRODUCT_NID      NUMBER(9),
   CONTRACT_NUMBER               VARCHAR2(50),
   TRANSMISSION_CUSTOMER_CODE    NUMBER(9),
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

-- Foreign Key
ALTER TABLE ETAG_TRANSMISSION_ALLOCATION
    ADD CONSTRAINT FK_ETAG_TRANSMISSION_ALLOCATN
    FOREIGN KEY (ETAG_ID, PHYSICAL_SEGMENT_NID)
    REFERENCES ETAG_TRANSMISSION_SEGMENT(ETAG_ID, PHYSICAL_SEGMENT_NID) ON DELETE CASCADE
/


/*==============================================================*/
/* Table: ETAG_PROFILE                                          */
/*==============================================================*/

create table ETAG_PROFILE  (
   PROFILE_KEY_ID           NUMBER(9)  not null,
   ETAG_ID                  NUMBER(9)  not null,
   PARENT_TYPE              VARCHAR2(64)  not null,  --BaseProfile, AllocationBaseProfile, AllocationExceptionProfile
   PARENT_NID               NUMBER(9),
   PROFILE_STYLE            VARCHAR2(64),   -- Relative, RelativeAllocation, or Absolute
   PROFILE_TYPE_LIST_ID     NUMBER(9),
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

-- Foreign Key
ALTER TABLE ETAG_PROFILE
    ADD CONSTRAINT FK_ETAG_PROFILE
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/

/*==============================================================*/
/* Table: ETAG_PROFILE_VALUE                                    */
/*==============================================================*/

create table ETAG_PROFILE_VALUE  (
   PROFILE_KEY_ID           NUMBER(9)  not null,
   START_DATE               DATE  not null,
   END_DATE                 DATE  not null,
   MW_LEVEL                 NUMBER(10),
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

-- Foreign Key
ALTER TABLE ETAG_PROFILE_VALUE
    ADD CONSTRAINT FK_ETAG_PROFILE_VALUE
    FOREIGN KEY (PROFILE_KEY_ID)
    REFERENCES ETAG_PROFILE(PROFILE_KEY_ID) ON DELETE CASCADE
/

/*==============================================================*/
/* Table: ETAG_LIST                                             */
/*==============================================================*/

create table ETAG_LIST  (
   ETAG_ID              NUMBER(9) not null,
   ETAG_LIST_ID         NUMBER(9) not null,
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
ALTER TABLE ETAG_LIST
    ADD CONSTRAINT FK_ETAG_LIST
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/
  

/*==============================================================*/
/* Table: ETAG_LIST_ITEM                                        */
/*==============================================================*/

create table ETAG_LIST_ITEM  (
   ETAG_ID              NUMBER(9) not null,
   ETAG_ITEM_ID         NUMBER(9) not null,
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
ALTER TABLE ETAG_LIST_ITEM
    ADD CONSTRAINT FK_ETAG_LIST_ITEM
    FOREIGN KEY (ETAG_ID, ETAG_LIST_ID)
    REFERENCES ETAG_LIST(ETAG_ID, ETAG_LIST_ID) ON DELETE CASCADE
/
  
/*==============================================================*/
/* Table: ETAG_PROFILE_LIST                                     */
/*==============================================================*/

create table ETAG_PROFILE_LIST  (
   ETAG_ID                  NUMBER(9)  not null,
   PROFILE_KEY_ID           NUMBER(9)  not null,
   ETAG_LIST_ID             NUMBER(9) not null,
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

-- Foreign Key
ALTER TABLE ETAG_PROFILE_LIST
    ADD CONSTRAINT FK1_ETAG_PROFILE_LIST
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/
ALTER TABLE ETAG_PROFILE_LIST
    ADD CONSTRAINT FK2_ETAG_PROFILE_LIST
    FOREIGN KEY (PROFILE_KEY_ID)
    REFERENCES ETAG_PROFILE(PROFILE_KEY_ID) ON DELETE CASCADE
/
ALTER TABLE ETAG_PROFILE_LIST
    ADD CONSTRAINT FK3_ETAG_PROFILE_LIST
    FOREIGN KEY (ETAG_ID, ETAG_LIST_ID)
    REFERENCES ETAG_LIST(ETAG_ID, ETAG_LIST_ID) ON DELETE CASCADE
/

/*==============================================================*/
/* Table: ETAG_STATUS                                           */
/*==============================================================*/

create table ETAG_STATUS  (
  ETAG_ID              NUMBER(9) not null,
  ENTITY_CODE_TYPE     VARCHAR2(10) not null,
  ENTITY_CODE          VARCHAR2(7) not null,
  MESSAGE_CALL_DATE    DATE  not null,
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
ALTER TABLE ETAG_STATUS
    ADD CONSTRAINT FK_ETAG_STATUS
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/
  
  
/*==============================================================*/
/* Table: ETAG_LOSS_METHOD                                      */
/*==============================================================*/

create table ETAG_LOSS_METHOD  (
   ETAG_ID                       NUMBER(9)  not null,
   PHYSICAL_SEGMENT_NID          NUMBER(9)  not null,
   START_DATE                    DATE  not null,
   END_DATE                      DATE  not null,
   LOSS_CORRECTION_NID           NUMBER(9),
   REQUEST_REF                   NUMBER(9),
   LOSS_TYPE                     VARCHAR2(32),  --InKind, Financial, Internal, External
   LOSS_TYPE_LIST_ID             NUMBER(9),
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

-- Foreign Key
ALTER TABLE ETAG_LOSS_METHOD
    ADD CONSTRAINT FK_ETAG_LOSS_METHOD
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/

  
/*==============================================================*/
/* Table: ETAG_MESSAGE_INFO                                     */
/*==============================================================*/

create table ETAG_MESSAGE_INFO  (
   ETAG_ID                     NUMBER(9)  not null,
   MESSAGE_TYPE                VARCHAR2(64)  not null,
   MESSAGE_CALL_DATE           DATE  not null,
   FROM_ENTITY_CODE            NUMBER(9),
   FROM_ENTITY_TYPE            VARCHAR2(16),
   TO_ENTITY_CODE              NUMBER(9),
   TO_ENTITY_TYPE              VARCHAR2(16),
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

-- Foreign Key
ALTER TABLE ETAG_MESSAGE_INFO
    ADD CONSTRAINT FK_ETAG_MESSAGE_INFO
    FOREIGN KEY (ETAG_ID)
    REFERENCES ETAG(ETAG_ID) ON DELETE CASCADE
/



