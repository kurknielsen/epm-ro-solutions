CREATE OR REPLACE TYPE ACCOUNT_EDC_SYNC_TYPE AS OBJECT
(
--Revision: $Revision: 1.16 $
  ACCOUNT_IDENTIFIER VARCHAR2(64),
  EDC_IDENTIFIER VARCHAR2(32),
  EDC_ACCOUNT_NUMBER VARCHAR2(32),
  EDC_RATE_CLASS VARCHAR2(16),
  EDC_STRATA VARCHAR2(16),
  BEGIN_DATE DATE,
  END_DATE DATE
);
/

CREATE OR REPLACE TYPE ACCOUNT_EDC_SYNC_TABLE IS TABLE OF ACCOUNT_EDC_SYNC_TYPE;
/