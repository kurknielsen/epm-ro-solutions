CREATE OR REPLACE TYPE ANCILLARY_WORK_TYPE AS OBJECT 
	( 
--Revision: $Revision: 1.16 $
	ENTITY_ID NUMBER(9), 
	SERVICE_DATE DATE, 
	SERVICE_VAL NUMBER(12,4),
 	SERVICE_ACCOUNTS NUMBER(8)
);
/

CREATE OR REPLACE TYPE ANCILLARY_WORK_TABLE IS TABLE OF ANCILLARY_WORK_TYPE;
/

