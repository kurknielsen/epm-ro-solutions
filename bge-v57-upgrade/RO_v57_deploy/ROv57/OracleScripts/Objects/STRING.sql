CREATE OR REPLACE TYPE STRING_TYPE AS OBJECT
(
--Revision: $Revision: 1.14 $
  STRING_VAL VARCHAR2(128)
);
/

CREATE OR REPLACE TYPE STRING_TABLE IS TABLE OF STRING_TYPE;
/
