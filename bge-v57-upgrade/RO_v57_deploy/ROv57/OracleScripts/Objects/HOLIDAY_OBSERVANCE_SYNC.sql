CREATE OR REPLACE TYPE HOLIDAY_OBSERVANCE_SYNC_TYPE AS OBJECT
(
--Revision: $Revision: 1.15 $
  HOLIDAY_NAME VARCHAR2(32),
  HOLIDAY_DATE DATE
);
/

CREATE OR REPLACE TYPE HOLIDAY_OBSERVANCE_SYNC_TABLE IS TABLE OF HOLIDAY_OBSERVANCE_SYNC_TYPE;
/
