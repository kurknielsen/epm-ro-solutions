CREATE OR REPLACE TYPE IMBALANCE_TRANSACTION_TYPE AS OBJECT
(
--Revision: $Revision: 1.15 $
  TRANSACTION_ID NUMBER(9),
  TRANSACTION_TYPE CHAR(2)
);
/

CREATE OR REPLACE TYPE IMBALANCE_TRANSACTION_TABLE IS TABLE OF IMBALANCE_TRANSACTION_TYPE;
/