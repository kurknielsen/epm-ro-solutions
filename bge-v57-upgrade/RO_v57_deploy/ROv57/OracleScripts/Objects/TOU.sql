CREATE OR REPLACE TYPE TOU_TYPE AS OBJECT
(
--Revision: $Revision: 1.16 $
  PERIOD_ID NUMBER(9),
  HOUR NUMBER(2),
  DAY_NAME VARCHAR2(3)
);
/

CREATE OR REPLACE TYPE TOU_TABLE IS TABLE OF TOU_TYPE;
/