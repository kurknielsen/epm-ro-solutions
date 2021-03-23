BEGIN CDI_DROP_OBJECT('CDI_ACCOUNT_ASSIGN_SYNC_LIST','TYPE'); END;
/
BEGIN CDI_DROP_OBJECT('CDI_ACCOUNT_ASSIGN_SYNC_TYPE','TYPE'); END;
/
CREATE OR REPLACE TYPE CDI_ACCOUNT_ASSIGN_SYNC_TYPE AS OBJECT
(
   ACCOUNT_EXTERNAL_IDENTIFIER VARCHAR2(64),
   EDC_EXTERNAL_IDENTIFIER     VARCHAR2(64),
   ESP_EXTERNAL_IDENTIFIER     VARCHAR2(64),
   POOL_EXTERNAL_IDENTIFIER    VARCHAR2(64),
   EDC_ACCOUNT_NUMBER          VARCHAR2(32),
   ESP_ACCOUNT_NUMBER          VARCHAR2(32),
   ACCOUNT_NAME                VARCHAR2(64),
   RATE_CLASS                  VARCHAR2(32),
   STRATA                      VARCHAR2(32),
   ACCOUNT_DUNS_NUMBER         VARCHAR2(16),
   ACCOUNT_SIC_CODE            VARCHAR2(16),
   ACCOUNT_METER_TYPE          VARCHAR2(16),
   ACCOUNT_SERV_LOC_EXT_ID     VARCHAR2(64),
   BEGIN_DATE                  DATE,
   END_DATE                    DATE
);
/
CREATE OR REPLACE TYPE CDI_ACCOUNT_ASSIGN_SYNC_LIST IS TABLE OF CDI_ACCOUNT_ASSIGN_SYNC_TYPE;
/