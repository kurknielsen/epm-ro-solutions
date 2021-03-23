
CREATE OR REPLACE TYPE MEX_ERCOT_ANCILLARY_SERV AS OBJECT
(
 	HOUR_ENDING	      DATE,
    MKT_ID         	  NUMBER(10),
    SERVICE_TYPE 	  VARCHAR2(15),
    REQUESTED_MW      NUMBER(10),
    PROCURMENT 	      NUMBER(10),
    CLEARING_PRICE    NUMBER(12,2),
    AS_BID_MW	      NUMBER(10)
);
/
CREATE OR REPLACE TYPE MEX_ERCOT_ANCILLARY_SERV_TBL AS TABLE OF MEX_ERCOT_ANCILLARY_SERV;
/

CREATE OR REPLACE TYPE MEX_ERCOT_CHARGE_TOTAL AS OBJECT
(
    CHARGE_DATE      DATE,
    CHARGE_ABBR      VARCHAR2(32),
    CHARGE_TOTAL     NUMBER,
    SETTLEMENT_TYPE  NUMBER(1)     
);
/
CREATE OR REPLACE TYPE MEX_ERCOT_CHARGE_TOTAL_TBL AS TABLE OF MEX_ERCOT_CHARGE_TOTAL;
/