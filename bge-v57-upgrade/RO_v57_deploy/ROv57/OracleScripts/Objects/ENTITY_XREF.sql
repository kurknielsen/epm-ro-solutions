CREATE OR REPLACE TYPE ENTITY_XREF_TYPE AS OBJECT
(
--Revision: $Revision: 1.12 $
  ENTITY_ID NUMBER(9),
  XREF_ID NUMBER(9)
);
/

CREATE OR REPLACE TYPE ENTITY_XREF_TABLE IS TABLE OF ENTITY_XREF_TYPE;
/