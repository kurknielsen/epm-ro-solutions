CREATE OR REPLACE VIEW COMPONENT_TOU_RATE_INFO ( COMPONENT_ID, 
PERIOD_ID, BEGIN_DATE, END_DATE, RATE, 
ENTRY_DATE, PERIOD_NAME ) AS SELECT C.COMPONENT_ID,C.PERIOD_ID,C.BEGIN_DATE,C.END_DATE,C.RATE,
	C.ENTRY_DATE,P.PERIOD_NAME
FROM COMPONENT_TOU_RATE C, PERIOD P
WHERE C.PERIOD_ID = P.PERIOD_ID(+);

