BEGIN CDI_DROP_OBJECT('CDI_ACCNT_SVC_LOC_SYNC_LIST','TYPE'); END;
/
BEGIN CDI_DROP_OBJECT('CDI_ACCNT_SVC_LOC_SYNC_TYPE','TYPE'); END;
/
CREATE OR REPLACE TYPE CDI_ACCNT_SVC_LOC_SYNC_TYPE AS OBJECT
(
   ACCOUNT_EXTERNAL_IDENTIFIER  VARCHAR2(64),
   SERV_LOC_EXTERNAL_IDENTIFIER VARCHAR2(64),
   BEGIN_DATE                   DATE,
   END_DATE                     DATE,
   EDC_IDENTIFIER               VARCHAR2(32),
   ESP_IDENTIFIER               VARCHAR2(32)
);
/
CREATE OR REPLACE TYPE CDI_ACCNT_SVC_LOC_SYNC_LIST IS TABLE OF CDI_ACCNT_SVC_LOC_SYNC_TYPE;
/
