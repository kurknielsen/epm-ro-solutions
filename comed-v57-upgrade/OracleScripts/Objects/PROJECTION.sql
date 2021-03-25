CREATE OR REPLACE TYPE PROJECTION_TYPE AS OBJECT
(
--Revision: $Revision: 1.16 $
  HOUR NUMBER(2),
  X NUMBER(10,2),
  Y NUMBER(10,2)
);
/

CREATE OR REPLACE TYPE PROJECTION_TABLE IS TABLE OF PROJECTION_TYPE;
/