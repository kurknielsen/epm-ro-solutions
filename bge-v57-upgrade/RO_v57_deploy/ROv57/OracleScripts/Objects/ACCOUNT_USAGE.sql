CREATE OR REPLACE TYPE ACCOUNT_USAGE_TYPE AS OBJECT
(
--Revision: $Revision: 1.16 $
  ACCOUNT_ID NUMBER(9),
  ACCOUNT_SERVICE_ID NUMBER(9),
  USAGE_DATE DATE,
  USAGE_VAL NUMBER(14,4)
);
/

CREATE OR REPLACE TYPE ACCOUNT_USAGE_TABLE IS TABLE OF ACCOUNT_USAGE_TYPE;
/
