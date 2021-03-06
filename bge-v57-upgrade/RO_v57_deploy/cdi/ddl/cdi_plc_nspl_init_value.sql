BEGIN CDI_DROP_OBJECT('CDI_PLC_NSPL_INIT_VALUE','TABLE'); END;
/

CREATE GLOBAL TEMPORARY TABLE CDI_PLC_NSPL_INIT_VALUE
(
  BILL_ACCOUNT    NUMBER(10),
  SERVICE_POINT   NUMBER(10),
  PREMISE_NUMBER  NUMBER(10),
  PEAK_DATE       DATE,
  POINT_VAL       NUMBER
) ON COMMIT PRESERVE ROWS;

BEGIN CDI_DROP_OBJECT('CDI_PLC_NSPL_INIT_VALUE_LIST','TYPE'); END;
/

BEGIN CDI_DROP_OBJECT('CDI_PLC_NSPL_INIT_VALUE_TYPE','TYPE'); END;
/

CREATE OR REPLACE TYPE CDI_PLC_NSPL_INIT_VALUE_TYPE AS OBJECT
(
  BILL_ACCOUNT    NUMBER(10),
  SERVICE_POINT   NUMBER(10),
  PREMISE_NUMBER  NUMBER(10),
  PEAK_DATE       DATE,
  POINT_VAL       NUMBER
);
/

CREATE OR REPLACE TYPE CDI_PLC_NSPL_INIT_VALUE_LIST AS TABLE OF CDI_PLC_NSPL_INIT_VALUE_TYPE;
/
