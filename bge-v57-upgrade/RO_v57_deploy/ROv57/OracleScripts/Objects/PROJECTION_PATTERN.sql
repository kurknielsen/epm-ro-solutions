CREATE OR REPLACE TYPE PROJECTION_PATTERN_TYPE AS OBJECT
(
--Revision: $Revision: 1.14 $
  PROJECTION_ID NUMBER(9),
  PERIOD_ID NUMBER(9),
  PROJECTION_DATE DATE,
  ENERGY NUMBER(12,2),
  DEMAND NUMBER(12,2)
);
/

CREATE OR REPLACE TYPE PROJECTION_PATTERN_TABLE IS TABLE OF PROJECTION_PATTERN_TYPE;
/
