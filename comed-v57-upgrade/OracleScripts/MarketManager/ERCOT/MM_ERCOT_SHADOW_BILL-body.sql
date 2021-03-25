CREATE OR REPLACE PACKAGE BODY MM_ERCOT_SHADOW_BILL IS
--------------------------------------------------------------------------------------------------
g_ERCOT_TIME_ZONE CONSTANT VARCHAR2(8) := 'CDT';

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ANCILLARY_LRS
    (
    p_DATE IN DATE,
    p_CONTRACT_ID IN NUMBER,
    p_SCHEDULE_TYPE IN NUMBER
    ) RETURN NUMBER IS

v_OPER_DATE DATE;
v_TOTAL_ERCOT_LOAD_ID NUMBER(9);
v_SYSTEM_LOAD NUMBER(9);
v_LOAD NUMBER(15,9);
v_LRS NUMBER := 0 ;
BEGIN
    --prior to 3/26/2006, go back 21 days, else go back 14 days
    IF p_DATE < TO_DATE('3/6/2006', 'MM/DD/YYYY') THEN
        v_OPER_DATE := p_DATE - 21;
    ELSE
        v_OPER_DATE := p_DATE - 14;
    END IF; 
        
    v_TOTAL_ERCOT_LOAD_ID := MM_ERCOT_UTIL.GET_TX_ID('LTOTERCOT', 'Market Result',
                                'ERCOT Total System Load',         
                                '15 Minute');         
    
    SELECT SUM(I.AMOUNT)
    INTO v_SYSTEM_LOAD
    FROM IT_SCHEDULE I      
    WHERE I.SCHEDULE_DATE > TO_CUT(v_OPER_DATE, g_ERCOT_TIME_ZONE) - 1/24
    AND I.SCHEDULE_DATE <= TO_CUT(v_OPER_DATE, g_ERCOT_TIME_ZONE)
    AND I.TRANSACTION_ID = v_TOTAL_ERCOT_LOAD_ID
    AND I.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND I.SCHEDULE_TYPE = p_SCHEDULE_TYPE;    
   
    
    SELECT SUM(I.AMOUNT)
    INTO v_LOAD
    FROM IT_SCHEDULE I    
    WHERE I.SCHEDULE_DATE >= TO_CUT(v_OPER_DATE, g_ERCOT_TIME_ZONE) - 1/24
    AND I.SCHEDULE_DATE < TO_CUT(v_OPER_DATE, g_ERCOT_TIME_ZONE)
    AND I.TRANSACTION_ID IN
    (SELECT TRANSACTION_ID FROM INTERCHANGE_TRANSACTION T 
    WHERE T.TRANSACTION_TYPE = 'LSELoad' AND T.CONTRACT_ID = p_CONTRACT_ID)
    AND I.SCHEDULE_STATE = GA.INTERNAL_STATE
    AND I.SCHEDULE_TYPE = p_SCHEDULE_TYPE;    
    
       
    IF v_SYSTEM_LOAD <> 0 THEN
        v_LRS := NVL(v_LOAD/v_SYSTEM_LOAD,0);
    ELSE
        v_LRS := 0;
    END IF;    

    RETURN v_LRS;

END GET_ANCILLARY_LRS;
--------------------------------------------------------------------------------------------------    
END MM_ERCOT_SHADOW_BILL;
/
