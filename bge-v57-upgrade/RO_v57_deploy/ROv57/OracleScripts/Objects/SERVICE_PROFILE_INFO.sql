CREATE OR REPLACE TYPE SERVICE_PROFILE_INFO_TYPE AS OBJECT  
(  
--Revision: $Revision: 1.15 $
  SERVICE_ID NUMBER(9),
  PROFILE_TYPE CHAR(1),
  PROFILE_SOURCE_DATE DATE,
  PROFILE_ZERO_COUNT NUMBER(2)
);
/

CREATE OR REPLACE TYPE SERVICE_PROFILE_INFO_TABLE IS TABLE OF SERVICE_PROFILE_INFO_TYPE;
/
