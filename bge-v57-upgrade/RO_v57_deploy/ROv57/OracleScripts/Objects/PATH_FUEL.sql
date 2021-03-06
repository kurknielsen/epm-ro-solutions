CREATE OR REPLACE TYPE PATH_FUEL_TYPE AS OBJECT
	(
--Revision: $Revision: 1.12 $
	PATH_ID NUMBER(9),
	PATH_BEGIN_DATE DATE,
	PATH_END_DATE DATE,
	ALLOCATION NUMBER(10,3),
	IS_PERCENT NUMBER(1),
	LEG_ORDER NUMBER(2),
	FUEL_BEGIN_DATE DATE,
	FUEL_END_DATE DATE,
	FUEL_PCT NUMBER(6,3),
	FUEL_IS_SEASONABLE NUMBER(1),
	FUEL_IS_CHARGED NUMBER(1)
);
/

CREATE OR REPLACE TYPE PATH_FUEL_TABLE IS TABLE OF PATH_FUEL_TYPE;
/
