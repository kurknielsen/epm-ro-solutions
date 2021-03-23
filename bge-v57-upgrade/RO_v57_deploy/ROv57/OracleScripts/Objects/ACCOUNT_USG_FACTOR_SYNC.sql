CREATE OR REPLACE TYPE ACCOUNT_USG_FACTOR_SYNC_TYPE AS OBJECT
(
--Revision: $Revision: 1.16 $
  ACCOUNT_IDENTIFIER VARCHAR2(64),
  BEGIN_DATE DATE,
  END_DATE DATE,
  FACTOR_VAL NUMBER(20,6)
);
/

CREATE OR REPLACE TYPE ACCOUNT_USG_FACTOR_SYNC_TABLE IS TABLE OF ACCOUNT_USG_FACTOR_SYNC_TYPE;
/
