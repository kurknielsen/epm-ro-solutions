CREATE OR REPLACE TYPE BIG_STRING_TYPE AS OBJECT
(
--Revision: $Revision: 1.14 $
  BIG_STRING_VAL VARCHAR2(4000)
);
/

CREATE OR REPLACE TYPE BIG_STRING_TABLE IS TABLE OF BIG_STRING_TYPE;
/
