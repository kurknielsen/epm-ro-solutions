CREATE OR REPLACE TYPE LOSS_FACTOR_SYNC_TYPE AS OBJECT
(
--Revision: $Revision: 1.15 $
  LOSS_FACTOR_NAME VARCHAR(32),
  LOSS_FACTOR_TYPE VARCHAR(16),
  LOSS_FACTOR_MEASURE VARCHAR(16),
  BEGIN_DATE DATE,
  END_DATE DATE,
  LOSS_FACTOR_VAL NUMBER
);
/

CREATE OR REPLACE TYPE LOSS_FACTOR_SYNC_TABLE IS TABLE OF LOSS_FACTOR_SYNC_TYPE;
/
