CREATE OR REPLACE TYPE MEX_CA_PI_DATA AS OBJECT
	(
    TAG     VARCHAR2(80),
    DTE     DATE,
    VAL     NUMBER(10,3)
    );
/

CREATE OR REPLACE TYPE MEX_CA_PI_DATA_TBL AS TABLE OF MEX_CA_PI_DATA;
/