CREATE OR REPLACE TYPE BID_OFFER_RAMP_TYPE AS OBJECT
(
--Revision: $Revision: 1.14 $
	SCHEDULE_DATE DATE,
	SET_NUMBER NUMBER(1),
	QUANTITY NUMBER(9,3),
	RAMP_UP NUMBER(9,3),
	RAMP_DOWN NUMBER(9,3),
	STATUS CHAR(1)
);
/

CREATE OR REPLACE TYPE BID_OFFER_RAMP_TABLE IS TABLE OF BID_OFFER_RAMP_TYPE;
/