CREATE OR REPLACE TYPE IMBALANCE_SCHEDULE_TYPE AS OBJECT
(
--Revision: $Revision: 1.16 $
  SCHEDULE_DATE DATE,
  DEMAND NUMBER(16,4),
  SUPPLY NUMBER(16,4),
  IMBALANCE NUMBER(16,4),
  ACCUMULATED NUMBER(16,4)
);
/

CREATE OR REPLACE TYPE IMBALANCE_SCHEDULE_TABLE IS TABLE OF IMBALANCE_SCHEDULE_TYPE;
/
