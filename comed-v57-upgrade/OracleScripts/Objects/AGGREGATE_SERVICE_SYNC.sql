CREATE OR REPLACE TYPE AGGREGATE_SERVICE_SYNC_TYPE AS OBJECT
(
--Revision: $Revision: 1.17 $
  AGGREGATE_ID NUMBER(9),
  ANCILLARY_SERVICE_ID NUMBER(9),
  SERVICE_DATE DATE,
  SERVICE_ACCOUNTS NUMBER(9),
  USAGE_FACTOR NUMBER(14,6),
  SERVICE_VAL NUMBER(20,6)
);
/

CREATE OR REPLACE TYPE AGGREGATE_SERVICE_SYNC_TABLE IS TABLE OF AGGREGATE_SERVICE_SYNC_TYPE;
/
