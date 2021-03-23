--====================================
--	MEX_PRICE_QUANTITY
--====================================
CREATE OR REPLACE TYPE MEX_PRICE_QUANTITY_TYPE AS OBJECT
(
	INTERVAL_NUMBER NUMBER(4),
	SET_NUMBER NUMBER(2),
	PRICE NUMBER(9,3),	
	QUANTITY NUMBER(9,3)
);
/

CREATE OR REPLACE TYPE MEX_PRICE_QUANTITY_TABLE IS TABLE OF MEX_PRICE_QUANTITY_TYPE;
/

--====================================
--	MEX_QUANTITY
--====================================
CREATE OR REPLACE TYPE MEX_QUANTITY_TYPE AS OBJECT
(
	ENTITY_IDENTIFIER_1 VARCHAR2(32),
	ENTITY_IDENTIFIER_2 VARCHAR2(32),
	INTERVAL_NUMBER NUMBER(4),
	QUANTITY NUMBER(9,3)
);
/

CREATE OR REPLACE TYPE MEX_QUANTITY_TABLE IS TABLE OF MEX_QUANTITY_TYPE;
/

--====================================
--	MEX_STATUS
--====================================
CREATE OR REPLACE TYPE MEX_STATUS_TYPE AS OBJECT
(
	INTERVAL_NUMBER NUMBER(4),
	STATUS VARCHAR2(64)
);
/

CREATE OR REPLACE TYPE MEX_STATUS_TABLE IS TABLE OF MEX_STATUS_TYPE;
/

--====================================
--	MEX_SCHEDULE
--====================================
CREATE OR REPLACE TYPE MEX_SCHEDULE AS OBJECT
(
	CUT_TIME DATE,
	VOLUME NUMBER,
	RATE NUMBER
);
/

CREATE OR REPLACE TYPE MEX_SCHEDULE_TBL AS TABLE OF MEX_SCHEDULE;
/


