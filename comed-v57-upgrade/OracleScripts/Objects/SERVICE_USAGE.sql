CREATE OR REPLACE TYPE SERVICE_USAGE_TYPE AS OBJECT
(
--Revision: $Revision: 1.13 $
  SERVICE_ID NUMBER(9),
  USAGE_CODE CHAR(1),
  USAGE_DATE DATE,
  USAGE_VAL NUMBER(16,4)
);
/

CREATE OR REPLACE TYPE SERVICE_USAGE_TABLE IS TABLE OF SERVICE_USAGE_TYPE;
/
