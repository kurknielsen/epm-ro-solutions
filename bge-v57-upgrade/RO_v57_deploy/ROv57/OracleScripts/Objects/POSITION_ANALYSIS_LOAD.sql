CREATE OR REPLACE TYPE POSITION_ANALYSIS_LOAD_TYPE AS OBJECT
(
--Revision: $Revision: 1.18 $
  PARTICIPANT_ID NUMBER(9),
  DAY_TYPE CHAR(1),
  LOAD_DATE DATE,
  LOAD_VAL NUMBER(12,4),
  LOSS_FACTOR_VAL NUMBER(12,6),
  ENROLLMENT NUMBER(6),
  DAYS NUMBER(2)
);
/

CREATE OR REPLACE TYPE POSITION_ANALYSIS_LOAD_TABLE IS TABLE OF POSITION_ANALYSIS_LOAD_TYPE;
/
