CREATE OR REPLACE TYPE SEASON_TEMPLATE_DEF_TYPE AS OBJECT
(
--Revision: $Revision: 1.4 $
	TEMPLATE_ID NUMBER(9),
	SEASON_ID NUMBER(9),
	DAY_NAME CHAR(3),
	PERIOD_STRING VARCHAR2(512)
);
/

CREATE OR REPLACE TYPE SEASON_TEMPLATE_DEF_TABLE IS TABLE OF SEASON_TEMPLATE_DEF_TYPE;
/