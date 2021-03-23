CREATE OR REPLACE PACKAGE BODY MM_ERCOT_EXTRACT IS


---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_ESIID_EXTRACT
	(
	p_CRED	IN mex_credentials,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
	) AS
BEGIN

	MEX_ERCOT_EXTRACT.FETCH_ESIID_EXTRACT_PAGE(p_CRED,
												p_BEGIN_DATE,
												p_END_DATE,
												p_LOG_ONLY,
												p_STATUS,
												p_MESSAGE,
												p_LOGGER);

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MM_ERCOT_EXTRACT.IMPORT_ESIID_EXTRACT: ' || SQLERRM;
END IMPORT_ESIID_EXTRACT;
-------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOAD_EXTRACT
	(
	p_WORK_ID IN NUMBER,
    p_CONTRACT_ID IN NUMBER,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

v_TOTAL_ERCOT_LOAD_ID NUMBER(9);
v_LOAD_RATIO_SHARE_ID NUMBER(9);
v_LSEGUFE_ID_S NUMBER(9);
v_LSEGUFE_ID_H NUMBER(9);
v_LSEGUFE_ID_N NUMBER(9);
v_LSEGUFE_ID_W NUMBER(9);
v_LSEGUFE_ID_NE NUMBER(9);
v_LSEGTL_ID_S NUMBER(9);
v_LSEGTL_ID_H NUMBER(9);
v_LSEGTL_ID_N NUMBER(9);
v_LSEGTL_ID_W NUMBER(9);
v_LSEGTL_ID_NE NUMBER(9);
--v_SCHEDULE_TYPE NUMBER(1);
v_TRANSACTION_ID NUMBER(9);
v_N_POD_ID NUMBER(9);
v_H_POD_ID NUMBER(9);
v_NE_POD_ID NUMBER(9);
v_S_POD_ID NUMBER(9);
v_W_POD_ID NUMBER(9);
v_YEAR VARCHAR2(2);
v_YEAR_P VARCHAR2(2);
--v_TOT_AMT NUMBER(15,8) := 0;
v_S_AMT NUMBER(15,8) := 0;
v_N_AMT NUMBER(15,8) := 0;
v_H_AMT NUMBER(15,8) := 0;
v_NE_AMT NUMBER(15,8) := 0;
v_W_AMT NUMBER(15,8) := 0;
v_NO_PUT BOOLEAN := FALSE;
v_DATE DATE;
J BINARY_INTEGER;
v_LSE_CODE NUMBER(3);

CURSOR c_TRADE_DATE(v_CODE IN VARCHAR2) IS
    SELECT DISTINCT TRUNC(D.TRADE_DATE) "TDATE"
    FROM ERCOT_MARKET_HEADER_WORK H,
         ERCOT_MARKET_DATA_WORK D
    WHERE H.INTERVAL_DATA_ID = D.INTERVAL_DATA_ID
        AND H.WORK_ID = p_WORK_ID
        AND H.WORK_ID = D.WORK_ID
        AND H.RECORDER LIKE v_CODE || '%';

CURSOR c_LOAD(v_CODE IN VARCHAR2, v_TRADE_DATE IN DATE,
                v_STATEMENT_TYPE IN NUMBER) IS
	SELECT H.RECORDER, H.MARKET_INTERVAL,
         D.TRADE_DATE, D.LOAD_AMOUNT
    FROM ERCOT_MARKET_HEADER_WORK H,
         ERCOT_MARKET_DATA_WORK D
    WHERE H.INTERVAL_DATA_ID = D.INTERVAL_DATA_ID
    AND H.WORK_ID = p_WORK_ID
    AND H.WORK_ID = D.WORK_ID
    AND H.RECORDER LIKE v_CODE || '%'
    AND H.MARKET_INTERVAL = v_STATEMENT_TYPE
    AND D.TRADE_DATE = v_TRADE_DATE;

CURSOR c_TOTLOAD(v_CODE IN VARCHAR2) IS
	SELECT H.RECORDER, H.MARKET_INTERVAL,
         D.TRADE_DATE, D.LOAD_AMOUNT
    FROM ERCOT_MARKET_HEADER_WORK H,
         ERCOT_MARKET_DATA_WORK D
    WHERE H.INTERVAL_DATA_ID = D.INTERVAL_DATA_ID
    AND H.WORK_ID = p_WORK_ID
    AND H.WORK_ID = D.WORK_ID
    AND H.RECORDER LIKE v_CODE;

BEGIN

    p_STATUS := GA.SUCCESS;

    ID.ID_FOR_SERVICE_POINT('North',v_N_POD_ID);
    ID.ID_FOR_SERVICE_POINT('Houston',v_H_POD_ID);
    ID.ID_FOR_SERVICE_POINT('Northeast',v_NE_POD_ID);
    ID.ID_FOR_SERVICE_POINT('South',v_S_POD_ID);
    ID.ID_FOR_SERVICE_POINT('West',v_W_POD_ID);

    v_LOAD_RATIO_SHARE_ID := MM_ERCOT_UTIL.GET_TX_ID('LRSLSE', 'Market Result',
                                                    'ERCOT Load Ratio Share',
                                                    '15 Minute', 0, p_CONTRACT_ID);

    v_TOTAL_ERCOT_LOAD_ID := MM_ERCOT_UTIL.GET_TX_ID('LTOTERCOT', 'Market Result',
                                'ERCOT Total System Load',
                                '15 Minute');

    v_LSEGUFE_ID_S := MM_ERCOT_UTIL.GET_TX_ID('LSEGUFE','LSELoad',
                                                    'ERCOT Load:BL+DL+TL+UFE',
                                                    '15 Minute', 0, p_CONTRACT_ID, 0, v_S_POD_ID);

    v_LSEGUFE_ID_N := MM_ERCOT_UTIL.GET_TX_ID('LSEGUFE','LSELoad',
                                                    'ERCOT Load:BL+DL+TL+UFE',
                                                    '15 Minute', 0, p_CONTRACT_ID, 0, v_N_POD_ID);

    v_LSEGUFE_ID_H := MM_ERCOT_UTIL.GET_TX_ID('LSEGUFE','LSELoad',
                                                    'ERCOT Load:BL+DL+TL+UFE',
                                                    '15 Minute', 0, p_CONTRACT_ID, 0, v_H_POD_ID);

    v_LSEGUFE_ID_W := MM_ERCOT_UTIL.GET_TX_ID('LSEGUFE','LSELoad',
                                                    'ERCOT Load:BL+DL+TL+UFE',
                                                    '15 Minute', 0, p_CONTRACT_ID, 0, v_W_POD_ID);
    v_LSEGUFE_ID_NE := MM_ERCOT_UTIL.GET_TX_ID('LSEGUFE','LSELoad',
                                                    'ERCOT Load:BL+DL+TL+UFE',
                                                    '15 Minute', 0, p_CONTRACT_ID, 0, v_NE_POD_ID);

    v_LSEGTL_ID_S := MM_ERCOT_UTIL.GET_TX_ID('LSEGTL', 'Market Result',
                                                'ERCOT Load:BL+DL+TL',
                                                '15 Minute', 0, p_CONTRACT_ID, 0, v_S_POD_ID);

    v_LSEGTL_ID_N := MM_ERCOT_UTIL.GET_TX_ID('LSEGTL', 'Market Result',
                                                'ERCOT Load:BL+DL+TL',
                                                '15 Minute', 0, p_CONTRACT_ID, 0, v_N_POD_ID);

    v_LSEGTL_ID_H := MM_ERCOT_UTIL.GET_TX_ID('LSEGTL', 'Market Result',
                                                'ERCOT Load:BL+DL+TL',
                                                '15 Minute', 0, p_CONTRACT_ID, 0, v_H_POD_ID);

    v_LSEGTL_ID_W := MM_ERCOT_UTIL.GET_TX_ID('LSEGTL', 'Market Result',
                                                'ERCOT Load:BL+DL+TL',
                                                '15 Minute', 0, p_CONTRACT_ID, 0, v_W_POD_ID);

    v_LSEGTL_ID_NE := MM_ERCOT_UTIL.GET_TX_ID('LSEGTL', 'Market Result',
                                                'ERCOT Load:BL+DL+TL',
                                                '15 Minute', 0, p_CONTRACT_ID, 0, v_NE_POD_ID);


	--BZ 16616 - Move the Lodestar constants out of the packages
	-- Loadstar's LSE Code is stored now as an entity attribute of the contract 
	v_LSE_CODE := RO.GET_ENTITY_ATTRIBUTE(g_CONTRACT_LSE_CODE_EA, EC.ED_INTERCHANGE_CONTRACT, p_CONTRACT_ID, SYSDATE);
	IF v_LSE_CODE IS NULL THEN 
		LOGS.LOG_ERROR('ERCOT LSE Code not found as Custom Attribute for "' || 
						TEXT_UTIL.TO_CHAR_ENTITY(p_CONTRACT_ID, EC.ED_INTERCHANGE_CONTRACT, TRUE, EC.ES_ERCOT) || '" contract');
	END IF;
	
	-- ERCOT Total System Load
    FOR v_LOAD IN c_TOTLOAD('LTOTERCOT') LOOP

        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_TOTAL_ERCOT_LOAD_ID,
							                v_LOAD.TRADE_DATE,
                                            v_LOAD.LOAD_AMOUNT,
                                            v_LOAD.MARKET_INTERVAL);
    END LOOP;

    -- Load Ratio Share
   	FOR v_LOAD IN c_TOTLOAD('LRSLSE%') LOOP  
        --Look for assigned LSE 
		IF v_LOAD.RECORDER LIKE 'LRSLSE_' || v_LSE_CODE|| '%' THEN
        	v_TRANSACTION_ID := v_LOAD_RATIO_SHARE_ID;
		ELSE  
            v_TRANSACTION_ID := NULL;        
        END IF;
            
        IF v_TRANSACTION_ID IS NOT NULL THEN       
		    MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_TRANSACTION_ID,
							             v_LOAD.TRADE_DATE,
                                         v_LOAD.LOAD_AMOUNT,
                                         v_LOAD.MARKET_INTERVAL);
       	END IF;
    END LOOP;

    -- Load including UFE
    FOR v_TRADE_DATE IN c_TRADE_DATE('LSEGUFE') LOOP
        v_DATE := v_TRADE_DATE.TDATE + 1/96;
        J := 1;
       WHILE J < 97 LOOP
            FOR I IN 1..3 LOOP
                    FOR v_LOAD IN c_LOAD('LSEGUFE',v_DATE,I) LOOP
                    -- Look for assigned LSE
                    IF v_LOAD.RECORDER LIKE 'LSEGUFE_' || v_LSE_CODE || '%'  THEN
                        v_NO_PUT := FALSE;
                    ELSE
                        v_NO_PUT := TRUE;
                    END IF;

                    IF v_NO_PUT = FALSE THEN
                        v_YEAR := TO_CHAR(v_LOAD.TRADE_DATE, 'YY');
                        v_YEAR_P := SUBSTR(TO_CHAR(v_LOAD.TRADE_DATE, 'YYYY')-1,3);
                        --IF v_LOAD.RECORDER LIKE '%_S' || v_YEAR || '_%' THEN
                        IF INSTR(v_LOAD.RECORDER,'_S' || v_YEAR || '_' )> 1 OR
                         INSTR(v_LOAD.RECORDER,'_S' || v_YEAR_P || '_' )> 1 THEN
                            v_S_AMT := v_S_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_N' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_N' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_N' || v_YEAR || '_%' THEN
                            v_N_AMT := v_N_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_H' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_H' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_H' || v_YEAR || '_%' THEN
                            v_H_AMT := v_H_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_W' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_W' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_W' || v_YEAR || '_%' THEN
                            v_W_AMT := v_W_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_E' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_E' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_E' || v_YEAR || '_%' THEN
                            v_NE_AMT := v_NE_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSE
                           v_NO_PUT := TRUE;
                            LOGS.LOG_WARN('Unrecognized Zone:' || v_LOAD.RECORDER);
                        END IF;

                    END IF;
                END LOOP;
                IF v_NO_PUT = FALSE THEN
                        IF v_S_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGUFE_ID_S,
    							                v_DATE,
                                                v_S_AMT,
                                                I);
                        END IF;
                        IF v_H_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGUFE_ID_H,
    							                v_DATE,
                                                v_H_AMT,
                                                I);
                        END IF;
                        IF v_N_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGUFE_ID_N,
    							                v_DATE,
                                                v_N_AMT,
                                                I);
                        END IF;
                        IF v_W_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGUFE_ID_W,
    							                v_DATE,
                                                v_W_AMT,
                                                I);
                        END IF;
                        IF v_NE_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGUFE_ID_NE,
    							                v_DATE,
                                                v_NE_AMT,
                                                I);
                        END IF;

                END IF;
                v_S_AMT := 0;
                v_H_AMT := 0;
                v_N_AMT := 0;
                v_W_AMT := 0;
                v_NE_AMT := 0;
            END LOOP;
            v_DATE := v_DATE + 1/96;
            J := J + 1;
        END LOOP;
    END LOOP;

     -- Load not including UFE
    FOR v_TRADE_DATE IN c_TRADE_DATE('LSEGTL') LOOP
        v_DATE := v_TRADE_DATE.TDATE + 1/96;
        J := 1;
       WHILE J < 97 LOOP
            FOR I IN 1..3 LOOP
                    FOR v_LOAD IN c_LOAD('LSEGTL',v_DATE,I) LOOP
                    -- Look for assigned LSE
                    IF v_LOAD.RECORDER LIKE 'LSEGTL_' || v_LSE_CODE || '%'  THEN
                        v_NO_PUT := FALSE;
                    ELSE
                        v_NO_PUT := TRUE;
                    END IF;

                    IF v_NO_PUT = FALSE THEN
                        v_YEAR := TO_CHAR(v_LOAD.TRADE_DATE, 'YY');
                        v_YEAR_P := SUBSTR(TO_CHAR(v_LOAD.TRADE_DATE, 'YYYY')-1,3);
                        --v_YEAR := TO_CHAR(v_LOAD.TRADE_DATE, 'YY');
                        IF INSTR(v_LOAD.RECORDER,'_S' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_S' || v_YEAR_P || '_') > 1 THEN
                       -- IF v_LOAD.RECORDER LIKE '%_S' || v_YEAR || '_%' THEN
                            v_S_AMT := v_S_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_N' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_N' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_N' || v_YEAR || '_%' THEN
                            v_N_AMT := v_N_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_H' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_H' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_H' || v_YEAR || '_%' THEN
                            v_H_AMT := v_H_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_W' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_W' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_W' || v_YEAR || '_%' THEN
                            v_W_AMT := v_W_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSIF INSTR(v_LOAD.RECORDER,'_E' || v_YEAR || '_') > 1 OR
                            INSTR(v_LOAD.RECORDER,'_E' || v_YEAR_P || '_') > 1 THEN
                        --ELSIF v_LOAD.RECORDER LIKE '%_E' || v_YEAR || '_%' THEN
                            v_NE_AMT := v_NE_AMT + NVL(v_LOAD.Load_Amount,0);
                        ELSE
                           v_NO_PUT := TRUE;
                            LOGS.LOG_WARN('Unrecognized Zone:' || v_LOAD.RECORDER);
                        END IF;

                    END IF;
                END LOOP;
                IF v_NO_PUT = FALSE THEN
                        IF v_S_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGTL_ID_S,
    							                v_DATE,
                                                v_S_AMT,
                                                I);
                        END IF;
                        IF v_H_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGTL_ID_H,
    							                v_DATE,
                                                v_H_AMT,
                                                I);
                        END IF;
                        IF v_N_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGTL_ID_N,
    							                v_DATE,
                                                v_N_AMT,
                                                I);
                        END IF;
                        IF v_W_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGTL_ID_W,
    							                v_DATE,
                                                v_W_AMT,
                                                I);
                        END IF;
                        IF v_NE_AMT > 0 THEN
                        MM_ERCOT_UTIL.PUT_SCHEDULE_VALUE(v_LSEGTL_ID_NE,
    							                v_DATE,
                                                v_NE_AMT,
                                                I);
                        END IF;

                END IF;
                v_S_AMT := 0;
                v_H_AMT := 0;
                v_N_AMT := 0;
                v_W_AMT := 0;
                v_NE_AMT := 0;
            END LOOP;
            v_DATE := v_DATE + 1/96;
            J := J + 1;
        END LOOP;
    END LOOP;

    COMMIT;


EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MM_ERCOT_EXTRACT.IMPORT_LOAD_EXTRACT: ' || SQLERRM;
END IMPORT_LOAD_EXTRACT;
--------------------------------------------------------------------------------------------------
PROCEDURE IMPORT_LOAD_EXTRACT
	(
	p_CRED	IN mex_credentials,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
	p_LOG_ONLY IN NUMBER,
    p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
	) AS
v_WORK_ID NUMBER;
v_CONTRACT_ID NUMBER;
BEGIN

	MEX_ERCOT_EXTRACT.FETCH_LOAD_EXTRACT_PAGE(p_CRED,
												p_BEGIN_DATE,
												p_END_DATE,
												p_LOG_ONLY,
												v_WORK_ID,
												p_STATUS,
												p_MESSAGE,
												p_LOGGER);


	IF p_STATUS = GA.SUCCESS THEN
		v_CONTRACT_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_CRED.EXTERNAL_ACCOUNT_NAME, EC.ED_INTERCHANGE_CONTRACT, EC.ES_ERCOT);
  		IMPORT_LOAD_EXTRACT(v_WORK_ID, v_CONTRACT_ID, p_STATUS, p_MESSAGE);
    END IF;

    --Clean up the work tables
	DELETE ERCOT_MARKET_HEADER_WORK WHERE WORK_ID = v_WORK_ID;
    DELETE ERCOT_MARKET_DATA_WORK WHERE WORK_ID = v_WORK_ID;
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MM_ERCOT_EXTRACT.IMPORT_LOAD_EXTRACT: ' || SQLERRM;
END IMPORT_LOAD_EXTRACT;
-------------------------------------------------------------------------------------------------
PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2) AS

	v_CREDS mm_credentials_set;
	v_CRED  mex_credentials;
	v_LOGGER mm_logger_adapter;
	v_LOG_ONLY NUMBER;
BEGIN
	v_LOG_ONLY := NVL(p_LOG_ONLY, 0);

	MM_UTIL.INIT_MEX(p_EXTERNAL_SYSTEM_ID => EC.ES_ERCOT,
		p_PROCESS_NAME => 'ERCOT:EXTRACT',
		p_EXCHANGE_NAME => p_EXCHANGE_TYPE,
		p_LOG_TYPE => p_LOG_TYPE,
		p_TRACE_ON => p_TRACE_ON,
		p_CREDENTIALS => v_CREDS,
		p_LOGGER => v_LOGGER);
	MM_UTIL.START_EXCHANGE(FALSE, v_LOGGER);

	WHILE v_CREDS.HAS_NEXT LOOP
		v_CRED := v_CREDS.GET_NEXT;

		IF p_EXCHANGE_TYPE = g_ET_IMPORT_LOAD_EXTRACT THEN
			IMPORT_LOAD_EXTRACT(v_CRED, p_BEGIN_DATE, p_END_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
		ELSIF p_EXCHANGE_TYPE = g_ET_IMPORT_ESIID_EXTRACT THEN
			IMPORT_ESIID_EXTRACT(v_CRED, p_BEGIN_DATE, p_END_DATE, v_LOG_ONLY, p_STATUS, p_MESSAGE, v_LOGGER);
		ELSE
			p_STATUS := -1;
			p_MESSAGE := 'Exchange Type ' || p_EXCHANGE_TYPE || ' not found.';
			v_LOGGER.LOG_ERROR(p_MESSAGE);
			EXIT;
		END IF;
	END LOOP;

	MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);

EXCEPTION
	WHEN OTHERS THEN
		p_MESSAGE := SQLERRM;
		p_STATUS  := SQLCODE;
		MM_UTIL.STOP_EXCHANGE(v_LOGGER, p_STATUS, p_MESSAGE, p_MESSAGE);
END MARKET_EXCHANGE;
--------------------------------------------------------------------------------------------------
END MM_ERCOT_EXTRACT; 
/
