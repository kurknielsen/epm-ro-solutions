CREATE OR REPLACE TYPE TEMPLATE_PARAMETER_TYPE AS OBJECT
	(
--Revision: $Revision: 1.12 $
	TEMPLATE_ID NUMBER(9),
	PARAMETER_ID_1 NUMBER(9),
	PARAMETER_ID_2 NUMBER(9),
	PARAMETER_ID_3 NUMBER(9),
	PARAMETER_ID_4 NUMBER(9),
	PARAMETER_ID_5 NUMBER(9)
	);
/

CREATE OR REPLACE TYPE TEMPLATE_PARAMETER_TABLE IS TABLE OF TEMPLATE_PARAMETER_TYPE;
/
