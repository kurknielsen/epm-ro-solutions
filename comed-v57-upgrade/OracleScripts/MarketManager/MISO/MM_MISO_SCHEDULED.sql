CREATE OR REPLACE PACKAGE MM_MISO_SCHEDULED IS

	-- Author  : JCOOPE4
	-- Created : 02/13/2007 08:41:57 AM
	-- Purpose : 
PROCEDURE PUBLIC_DA_LMP    
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );
PROCEDURE PUBLIC_RT_LMP
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );  
PROCEDURE MISO_RT_INTEGRATED_LMP
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );      
PROCEDURE MISO_FIVE_MINUTE_LMP
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );
PROCEDURE MISO_QUERY_NODE_LIST
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );
PROCEDURE MISO_MARKET_RESULTS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );
PROCEDURE MISO_SETTLEMENT_STATEMENT
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );
PROCEDURE MISO_FIN_CONTRACTS_SCHEDULES
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    );
PROCEDURE MISO_BILL_RUN;
                        
END MM_MISO_SCHEDULED;
/
CREATE OR REPLACE PACKAGE BODY MM_MISO_SCHEDULED IS
g_LOG_ONLY BINARY_INTEGER :=0;
g_LOG_TYPE BINARY_INTEGER :=NULL;
g_TRACE_ON BINARY_INTEGER :=NULL;
---------------------------------------------------------------------------------------
PROCEDURE PUBLIC_DA_LMP 
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
	p_STATUS := GA.SUCCESS;  
                                   
    MM_MISO_LMP.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_MISO_LMP.g_ET_QRY_DA_LMP,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);  
                                
    IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing MISO Day-ahead LMP: ' || p_message);
	END IF;                                                    
	
END PUBLIC_DA_LMP;
---------------------------------------------------------------------------------------
PROCEDURE PUBLIC_RT_LMP
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
	p_STATUS := GA.SUCCESS;
    
     MM_MISO_LMP.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_MISO_LMP.g_ET_QRY_RT_LMP,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);  
                                
    IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		LOGS.LOG_WARN('Problem importing MISO Real-time LMP: ' || p_message);
	END IF;                          
	
END PUBLIC_RT_LMP;
---------------------------------------------------------------------------------------
PROCEDURE MISO_RT_INTEGRATED_LMP
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);

BEGIN
	p_STATUS := GA.SUCCESS;
    
    --only get the LMPs if hour > 0 or else they won't be available
    IF TO_NUMBER(TO_CHAR(p_BEGIN_DATE, 'HH24')) > 0 THEN       
        MM_MISO.MARKET_EXCHANGE(p_BEGIN_DATE, p_END_DATE, MM_MISO.g_ET_RT_INTEGRATED_LMP_QUERY, NULL, NULL,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);                                           

    	 IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		    LOGS.LOG_WARN('Problem importing MISO RT Integrated LMP: ' || p_message);
	    END IF;  
    END IF;        
END MISO_RT_INTEGRATED_LMP;
---------------------------------------------------------------------------------------
PROCEDURE MISO_FIVE_MINUTE_LMP
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);

BEGIN
    p_STATUS := GA.SUCCESS;
    
    --only get the LMPs if hour > 0 or else they won't be available
    IF TO_NUMBER(TO_CHAR(p_BEGIN_DATE, 'HH24')) > 0 THEN       
        MM_MISO.MARKET_EXCHANGE(p_BEGIN_DATE, p_END_DATE, MM_MISO.g_ET_5_MINUTE_LMP_QUERY, NULL, NULL,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);                                           

    	 IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		    LOGS.LOG_WARN('Problem importing MISO 5 Minute LMP: ' || p_message);
	    END IF;  
    END IF;        
END MISO_FIVE_MINUTE_LMP;
---------------------------------------------------------------------------------------
PROCEDURE MISO_QUERY_NODE_LIST
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
	p_STATUS := GA.SUCCESS;
    
    --only get the LMPs if hour > 0 or else they won't be available
    IF TO_NUMBER(TO_CHAR(p_BEGIN_DATE, 'HH24')) > 0 THEN       
        MM_MISO.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_MISO.g_ET_QRY_NODE_LIST, NULL, NULL,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);                                           

    	 IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		    LOGS.LOG_WARN('Problem importing MISO Node List: ' || p_message);
	    END IF;  
    END IF;        
END MISO_QUERY_NODE_LIST;
---------------------------------------------------------------------------------------
PROCEDURE MISO_MARKET_RESULTS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
	p_STATUS := GA.SUCCESS;
    
    --only get the LMPs if hour > 0 or else they won't be available
    IF TO_NUMBER(TO_CHAR(p_BEGIN_DATE, 'HH24')) > 0 THEN       
        MM_MISO.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_MISO.g_ET_QRY_MARKET_RESULTS, NULL, NULL,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);                                           

    	 IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		    LOGS.LOG_WARN('Problem importing MISO Market Results: ' || p_message);
	    END IF;  
    END IF;        
END MISO_MARKET_RESULTS;
---------------------------------------------------------------------------------------
PROCEDURE MISO_SETTLEMENT_STATEMENT
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
    p_STATUS := GA.SUCCESS;
    
    --only get the LMPs if hour > 0 or else they won't be available
    IF TO_NUMBER(TO_CHAR(p_BEGIN_DATE, 'HH24')) > 0 THEN       
        MM_MISO.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_MISO.g_ET_QRY_SETTLEMENT_STATEMENT, NULL, NULL,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);                                           

    	 IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		    LOGS.LOG_WARN('Problem importing MISO Settlement Statement: ' || p_message);
	    END IF;  
    END IF;        
END MISO_SETTLEMENT_STATEMENT;
---------------------------------------------------------------------------------------
PROCEDURE MISO_QUERY_FIN_CONTRACTS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
	 p_STATUS := GA.SUCCESS;
    
    --only get the LMPs if hour > 0 or else they won't be available
    IF TO_NUMBER(TO_CHAR(p_BEGIN_DATE, 'HH24')) > 0 THEN       
        MM_MISO.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_MISO.g_ET_QRY_FCONTR_INTERNAL, NULL, NULL,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);                                           

    	 IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		    LOGS.LOG_WARN('Problem importing MISO Fin Contracts: ' || p_MESSAGE);
	    END IF;  
    END IF;                           

END MISO_QUERY_FIN_CONTRACTS;
---------------------------------------------------------------------------------------
PROCEDURE MISO_QUERY_FIN_SCHEDULES
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_BEGIN_DATE DATE := TRUNC(p_BEGIN_DATE);
v_END_DATE DATE := TRUNC(p_END_DATE);

BEGIN
    p_STATUS := GA.SUCCESS;
    
    --only get the LMPs if hour > 0 or else they won't be available
    IF TO_NUMBER(TO_CHAR(p_BEGIN_DATE, 'HH24')) > 0 THEN       
        MM_MISO.MARKET_EXCHANGE(v_BEGIN_DATE, v_END_DATE, MM_MISO.g_ET_QRY_FSCHED_INTERNAL, NULL, NULL,
	 							g_LOG_TYPE, g_TRACE_ON, g_LOG_ONLY, p_STATUS, p_MESSAGE);                                           

    	 IF p_STATUS != MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
		    LOGS.LOG_WARN('Problem importing MISO Fin Schedules: ' || p_MESSAGE);
	    END IF;  
    END IF;                                 

END MISO_QUERY_FIN_SCHEDULES;
---------------------------------------------------------------------------------------
PROCEDURE MISO_FIN_CONTRACTS_SCHEDULES
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) IS
BEGIN
    MISO_QUERY_FIN_CONTRACTS(p_BEGIN_DATE, p_END_DATE);
    MISO_QUERY_FIN_SCHEDULES(p_BEGIN_DATE, p_END_DATE);
END MISO_FIN_CONTRACTS_SCHEDULES;
----------------------------------------------------------------------------------------    
PROCEDURE MISO_BILL_RUN IS
   
p_STATUS     NUMBER;
p_MESSAGE    VARCHAR2(256);
v_SCRIPT_RUN_DATE DATE;
v_DATE DATE;
v_PSE_IDS NUMBER_COLLECTION;

CURSOR C_STATEMENT_TYPE_INFO IS
    SELECT STATEMENT_TYPE_ID, STATEMENT_TYPE_NAME,
            TRUNC(v_DATE) - TO_NUMBER(SUBSTR(STATEMENT_TYPE_ALIAS, 7)) STATEMENT_DATE
    FROM STATEMENT_TYPE
    WHERE STATEMENT_TYPE_ALIAS LIKE 'MISO:S%';
CURSOR C_BILLING_ENTITIES IS
		SELECT -BILLING_ENTITY_ID a,
				CONTRACT_NAME
			FROM INTERCHANGE_CONTRACT
		 WHERE SC_ID = (SELECT SC_ID FROM SCHEDULE_COORDINATOR WHERE SC_NAME = 'MISO');


BEGIN
	p_STATUS := GA.SUCCESS;
    v_PSE_IDS := NUMBER_COLLECTION();
    v_SCRIPT_RUN_DATE := SYSDATE;
	v_DATE := TRUNC(v_SCRIPT_RUN_DATE, 'DD') - 1;
	FOR r_STATEMENT_TYPE_INFO IN c_STATEMENT_TYPE_INFO LOOP
		FOR r_BILLING_ENTITY IN c_BILLING_ENTITIES LOOP
            v_PSE_IDS := NUMBER_COLLECTION(r_BILLING_ENTITY.a);

            PC.BILLING_STATEMENT_REQUEST('Scheduling',
										 1,
										 v_PSE_IDS, 
										 -1,
										 -1,
										 1,
										 r_STATEMENT_TYPE_INFO.statement_type_id, 
										 r_STATEMENT_TYPE_INFO.statement_date,
										 r_STATEMENT_TYPE_INFO.statement_date,
										 HIGH_DATE,
										 LOW_DATE,
										 0,
										 0,
										 p_STATUS,
										 p_MESSAGE);
			IF p_STATUS != GA.SUCCESS THEN
                LOGS.LOG_WARN('Problem running shadow settlement for contract ' || r_BILLING_ENTITY.contract_name ||
										 ' and statement type ' ||
										 r_STATEMENT_TYPE_INFO.statement_type_name ||
										 ' on ' || 											
										 r_STATEMENT_TYPE_INFO.statement_date || ': ' || p_MESSAGE);				
			END IF;
		END LOOP;
	END LOOP;
EXCEPTION WHEN OTHERS THEN
    LOGS.LOG_WARN('Problem running shadow settlement for contract ' || p_MESSAGE);
			
END MISO_BILL_RUN;
---------------------------------------------------------------------------------------

END MM_MISO_SCHEDULED;
/
