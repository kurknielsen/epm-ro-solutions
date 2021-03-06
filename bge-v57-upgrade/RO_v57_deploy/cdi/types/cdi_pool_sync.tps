BEGIN CDI_DROP_OBJECT('CDI_POOL_SYNC_LIST','TYPE'); END;
/
BEGIN CDI_DROP_OBJECT('CDI_POOL_SYNC_TYPE','TYPE'); END;
/
CREATE OR REPLACE TYPE CDI_POOL_SYNC_TYPE AS OBJECT
(
   POOL_NAME                  VARCHAR2(32),
   POOL_ALIAS                 VARCHAR2(32),
   POOL_DESC                  VARCHAR2(256),
   POOL_EXTERNAL_IDENTIFIER   VARCHAR2(64),
   POOL_STATUS                VARCHAR2(16),
   POOL_CATEGORY              VARCHAR2(32),
   POOL_EXCLUDE_LOAD_SCHEDULE NUMBER(1),
   IS_TOU_POOL                NUMBER(1),
   POLR_TYPE                  VARCHAR2(64),
   IS_ID_SALES                NUMBER(1),  
   TARIFF_ID                  NUMBER,
   PLC_BAND                   VARCHAR2(2),
   REPORTED_SEGMENT           VARCHAR2(64),
   VOLTAGE_CLASS              VARCHAR2(64)
);
/
CREATE OR REPLACE TYPE CDI_POOL_SYNC_LIST IS TABLE OF CDI_POOL_SYNC_TYPE;
/
