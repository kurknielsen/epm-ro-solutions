CREATE OR REPLACE PACKAGE MM_ERCOT_SHADOW_BILL IS
-- $Revision: 1.4 $

  -- Author  : CNAVALTA
  -- Created : 5/5/2006 5:49:03 PM
  -- Purpose : contains functions for settlement calculations  

FUNCTION WHAT_VERSION RETURN VARCHAR2;

FUNCTION GET_ANCILLARY_LRS
    (
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
     p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER;  

END MM_ERCOT_SHADOW_BILL;
/