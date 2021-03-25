CREATE OR REPLACE TYPE ID_SET AS OBJECT
(
  ID1 NUMBER(9),
  ID2 NUMBER(9), 
  ID3 NUMBER(9),
  ID4 NUMBER(9),
  ID5 NUMBER(9),
  ID6 NUMBER(9),
  ID7 NUMBER(9),
  ID8 NUMBER(9),
  ID9 NUMBER(9),
  ID10 NUMBER(9),
  
  -- CUSTOM CONSTRUCTOR SO ONE ONLY HAS 
  -- TO SPECIFY A MINIMUM OF 2 IDS TO CREATE A SET 
  CONSTRUCTOR FUNCTION ID_SET
  (
  	p_ID1 IN NUMBER, 
  	p_ID2 IN NUMBER,
	p_ID3 IN NUMBER := NULL,
	p_ID4 IN NUMBER := NULL,
	p_ID5 IN NUMBER := NULL,
	p_ID6 IN NUMBER := NULL,
	p_ID7 IN NUMBER := NULL,
	p_ID8 IN NUMBER := NULL,
	p_ID9 IN NUMBER := NULL,
	p_ID10 IN NUMBER := NULL
  ) RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY ID_SET AS
  
  -- CUSTOM CONSTRUCTOR SO ONE ONLY HAS 
  -- TO SPECIFY A MINIMUM OF 2 IDS TO CREATE A SET 
  CONSTRUCTOR FUNCTION ID_SET
  (
  	p_ID1 IN NUMBER, 
  	p_ID2 IN NUMBER,
	p_ID3 IN NUMBER := NULL,
	p_ID4 IN NUMBER := NULL,
	p_ID5 IN NUMBER := NULL,
	p_ID6 IN NUMBER := NULL,
	p_ID7 IN NUMBER := NULL,
	p_ID8 IN NUMBER := NULL,
	p_ID9 IN NUMBER := NULL,
	p_ID10 IN NUMBER := NULL
  ) RETURN SELF AS RESULT IS
  
  BEGIN
  
  	SELF.ID1 := p_ID1;
	SELF.ID2 := p_ID2;
	SELF.ID3 := p_ID3;
	SELF.ID4 := p_ID4;
	SELF.ID5 := p_ID5;
	SELF.ID6 := p_ID6;
	SELF.ID7 := p_ID7;
	SELF.ID8 := p_ID8;
	SELF.ID9 := p_ID9;
	SELF.ID10 := p_ID10;

	RETURN;
  END ID_SET;
  
END;
/
