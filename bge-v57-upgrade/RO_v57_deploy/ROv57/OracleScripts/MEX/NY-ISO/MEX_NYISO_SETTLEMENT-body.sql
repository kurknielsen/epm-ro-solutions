CREATE OR REPLACE PACKAGE BODY MEX_NYISO_SETTLEMENT IS
-----------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
------------------------------------------------------------------------------------------------------
--NOT USED 
/*PROCEDURE FETCH_DSS_REPORT(p_CRED    IN mex_credentials,
						   p_REC_DATA        IN MEX_NY_DOC_IDENT,
						   p_CLOB_RESP       OUT CLOB,
						   p_EXCHANGE_ID     OUT NUMBER,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_MAP MEX_HTTP.PARAMETER_MAP;
	v_RESULT       MEX_RESULT;
	v_LOG_ONLY NUMBER := 0;

BEGIN

	--retrieve the individual file content for a file
	v_MAP('isoID') := p_REC_DATA.DOC_ID;
    v_MAP('isofileName') := p_REC_DATA.DOC_NAME;
    v_MAP('isofileType') := 'CSV';
    v_MAP('isofileSize') := p_REC_DATA.DOC_SIZE;
    v_MAP('isoMEX-REQUEST-HEADER-COOKIE') := g_DSS_COOKIE_STRING;

	IF MM_NYISO_UTIL.g_TEST THEN
		v_LOG_ONLY := 1;
	END IF;
    
	v_RESULT := MEX_SWITCHBOARD.INVOKE(p_Market => g_NYISO_DSS_MARKET,
									   p_Action => g_DSS_FILE_RETRIEVE_ACTION,
									   p_Logger => p_LOGGER,
									   p_Cred => p_CRED,
									   p_Parms => v_MAP,
									   p_Log_Only => v_LOG_ONLY);
										   
	p_STATUS := v_RESULT.STATUS_CODE;
    IF p_STATUS <> MEX_Switchboard.c_Status_Success THEN
        p_CLOB_RESP := NULL; -- this indicates failure - MEX_Switchboard.Invoke will have already logged error message
    ELSE
        p_LOGGER.LOG_INFO('Exchange successful');
        p_CLOB_RESP := v_RESULT.RESPONSE;
    END IF;
    
EXCEPTION
	WHEN OTHERS THEN 
	p_STATUS := SQLCODE;
    p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_DSS_REPORT:' || SQLERRM);
END FETCH_DSS_REPORT;*/
-----------------------------------------------------------------------------------------------
PROCEDURE FETCH_DSS_REPORT(p_CRED    IN mex_credentials,
						   p_REC_DATA        IN MEX_NY_DOC_IDENT,
						   p_CLOB_RESP       OUT CLOB,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_MAP MEX_Util.Parameter_Map;
	v_RESULT       MEX_RESULT;
	v_LOG_ONLY NUMBER := 0;

BEGIN

	--retrieve the individual file content for a file
	v_MAP('isoID') := p_REC_DATA.DOC_ID;
    v_MAP('isofileName') := p_REC_DATA.DOC_NAME;
    v_MAP('isofileType') := 'CSV';
    v_MAP('isofileSize') := p_REC_DATA.DOC_SIZE;
    v_MAP('isoMEX-REQUEST-HEADER-COOKIE') := g_DSS_COOKIE_STRING;

	IF MM_NYISO_UTIL.g_TEST THEN
		v_LOG_ONLY := 1;
	END IF;
    
	v_RESULT := MEX_SWITCHBOARD.INVOKE(p_Market => g_NYISO_DSS_MARKET,
									   p_Action => g_DSS_FILE_RETRIEVE_ACTION,
									   p_Logger => p_LOGGER,
									   p_Cred => p_CRED,
									   p_Parms => v_MAP,
									   p_Log_Only => v_LOG_ONLY);
										   
	p_STATUS := v_RESULT.STATUS_CODE;
    IF p_STATUS <> MEX_Switchboard.c_Status_Success THEN
        p_CLOB_RESP := NULL; -- this indicates failure - MEX_Switchboard.Invoke will have already logged error message
    ELSE
        p_LOGGER.LOG_INFO('Exchange successful');
        p_CLOB_RESP := v_RESULT.RESPONSE;
    END IF;
    
EXCEPTION
	WHEN OTHERS THEN 
	p_STATUS := SQLCODE;
    p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_DSS_REPORT:' || SQLERRM);

END FETCH_DSS_REPORT;
--------------------------------------------------------------------------------------------------------------
PROCEDURE DELETE_DSS_REPORTS(p_CRED    IN mex_credentials,
                             p_DATE            IN DATE,
  							 p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
  							 p_STATUS          OUT NUMBER,
  							 p_LOGGER         IN OUT mm_logger_adapter) IS

v_MAP MEX_Util.Parameter_Map;
v_IDX          BINARY_INTEGER;
v_DOC_DATA     MEX_NY_DOC_IDENT;
v_COOKIES      MEX_COOKIE_TBL;
v_LOOKUP_DATE  VARCHAR2(20);
v_LOG_ONLY     NUMBER(1) := 0;
v_RESULT       MEX_RESULT;

BEGIN

	IF MM_NYISO_UTIL.g_TEST THEN
		v_LOG_ONLY := 1;
	END IF;
	
/*	p_LOGGER.LOG_INFO ('Settlement: Delete NYISO DSS reports');
    v_MAP('isoMEX-REQUEST-HEADER-COOKIE') := g_DSS_COOKIE_STRING;
    -- Delete all files for this date.
    v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), 'MM/DD/YYYY');
    v_IDX         := p_DOC_LIST.FIRST;
	
	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
        v_MAP('isoID') := v_DOC_DATA.DOC_ID;
        v_MAP('isofileName') := v_DOC_DATA.DOC_NAME;

        IF v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN
            --delete the file
			v_RESULT := MEX_SWITCHBOARD.Invoke(p_Market => g_NYISO_DSS_MARKET,
								   p_Action => g_DSS_FILE_DELETE_ACTION,
								   p_Logger => P_LOGGER,
								   p_Cred => p_CRED,
								   p_Parms => v_MAP,
								   p_Log_Only => v_LOG_ONLY);
			
			p_STATUS := v_RESULT.STATUS_CODE;
    		IF p_STATUS <> MEX_Switchboard.c_Status_Success THEN
        		p_LOGGER.LOG_INFO('Failure when attempting to delete DSS report');      
    		END IF;
        	
        END IF;

        v_IDX := p_DOC_LIST.NEXT(v_IDX);
	END LOOP;
	v_MAP.DELETE;*/
	

	--log-out of the automated enviroment
	p_LOGGER.LOG_INFO ('Settlement: NYISO DSS Logout');
    v_MAP('isoMEX-REQUEST-HEADER-COOKIE') := g_DSS_COOKIE_STRING;
	v_RESULT := MEX_SWITCHBOARD.Invoke(p_Market => g_NYISO_DSS_MARKET,
								   p_Action => g_DSS_LOGOUT_ACTION,
								   p_Logger => P_LOGGER,
								   p_Cred => p_CRED,
								   p_Parms => v_MAP,
								   p_Log_Only => v_LOG_ONLY);

	p_STATUS := v_RESULT.STATUS_CODE;
	IF p_STATUS <> MEX_Switchboard.c_Status_Success THEN
		p_LOGGER.LOG_INFO('Failure when attempting to logout from NYISO DSS');      
	END IF;
    -- Reset the cookie string
	g_DSS_COOKIE_STRING := '';

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_INFO('Error in MEX_NYISO_SETTLEMENT.DELETE_DSS_REPORTS:' || SQLERRM);
		
END DELETE_DSS_REPORTS;
-------------------------------------------------------------------------------------------------------------
PROCEDURE PARSE_INVOICE_SUMMARY(p_CLOB    IN CLOB,
								p_RECORDS OUT MEX_NY_INVOICE_TBL,
                                p_DSS_ERROR_MESSAGE_TYPE OUT NUMBER,
								p_STATUS  OUT NUMBER,
								p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH NUMBER;
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX    BINARY_INTEGER;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
    p_DSS_ERROR_MESSAGE_TYPE := CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER);
	IF v_LENGTH = 0 OR p_DSS_ERROR_MESSAGE_TYPE < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_INVOICE_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_INVOICE(INVOICE_VERSION   => TO_NUMBER(v_COLS(1)),
															INV_POSTED_IND    => v_COLS(2),
															INV_BILLING_MONTH => TO_CHAR(TO_DATE(SUBSTR(v_COLS(3),1,10), 'YYYY-MM_DD'), 'MON-YYYY'),
															SETTL_TYPE_DESC   => v_COLS(4),
															INV_ID            => v_COLS(5));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_INVOICE_SUMMARY:' ||
					 SQLERRM);

END PARSE_INVOICE_SUMMARY;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_INVOICE_SUMMARY(p_DATE                   IN DATE,
								p_DOC_LIST               IN MEX_NY_DOC_IDENT_TBL,
								p_CRED                   IN mex_credentials,
								p_RECORDS                OUT MEX_NY_INVOICE_TBL,
                                p_DSS_ERROR_MESSAGE_TYPE OUT NUMBER,
								p_STATUS                 OUT NUMBER,
								p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;


BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, g_DSS_INVOICE_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

            FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);
            IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
               --Parse the clob, return the object
               PARSE_INVOICE_SUMMARY(v_CLOB_RESP, p_RECORDS, p_DSS_ERROR_MESSAGE_TYPE, p_STATUS, p_LOGGER);
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(g_DSS_INVOICE_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;


EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_INVOICE_SUMMARY:' ||
					 SQLERRM);
END FETCH_INVOICE_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_NYISO_RATES(p_CLOB    IN CLOB,
							p_RECORDS OUT MEX_NY_RATES_TBL,
							p_STATUS  OUT NUMBER,
							p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;
	
BEGIN

    -- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_RATES_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		-- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(2),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_RATES(INVOICE_VERSION => TO_NUMBER(v_COLS(1)),
														  CHARGE_DATE => v_CURRENT_DATE,
														  MST_RATE    => TO_NUMBER(NVL(v_COLS(3),'0')),
														  OATT_RATE   => TO_NUMBER(NVL(v_COLS(4),'0')),
														  VSS_RATE    => TO_NUMBER(NVL(v_COLS(5),'0')),
														  RT_LSE_LOAD => TO_NUMBER(NVL(v_COLS(6),'0')),
														  MST_STLM    => TO_NUMBER(NVL(v_COLS(7),'0')),
														  OATT_STLM   => TO_NUMBER(NVL(v_COLS(8),'0')),
														  VSS_STLM    => TO_NUMBER(NVL(v_COLS(9),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_NYISO_RATES:' ||
					 SQLERRM);

END PARSE_NYISO_RATES;

------------------------------------------------------------------------------------------
/*PROCEDURE GET_NYISO_RATES(p_REPORT_TYPE     IN VARCHAR2,
							p_RECORDS         OUT MEX_NY_RATES_TBL,
							p_STATUS          OUT NUMBER,
							p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_EXCHANGE_ID    NUMBER(9);
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_REPORT_NAME VARCHAR2(64);
	v_NAME VARCHAR2(64);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	 --Build report name
	v_REPORT_NAME := g_DSS_NYISO_RATES_REP_NAME || '_' || p_REPORT_TYPE;


	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_NYISO_RATES(v_CLOB_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

	-- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve clob',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  g_DSS_NYISO_RATES_REP_NAME || ' report is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_NYISO_RATES:' ||
					 SQLERRM;
END GET_NYISO_RATES;*/
---------------------------------------------------------------------------------------------
PROCEDURE FETCH_NYISO_RATES(p_DATE            IN DATE,
							p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							p_CRED    IN mex_credentials,
							p_REPORT_TYPE     IN VARCHAR2,
							p_RECORDS         OUT MEX_NY_RATES_TBL,
							p_STATUS          OUT NUMBER,
							p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_REPORT_NAME VARCHAR2(64);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	 --Build report name
	v_REPORT_NAME := g_DSS_NYISO_RATES_REP_NAME || '_' || p_REPORT_TYPE;


	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
               PARSE_NYISO_RATES(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
            END IF;
			v_EXIT_LOOP := TRUE;
		END IF;
 
		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(g_DSS_NYISO_RATES_REP_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_NYISO_RATES:' ||
					 SQLERRM);
END FETCH_NYISO_RATES;
------------------------------------------------------------------------------------------
/*PROCEDURE FETCH_NYISO_RATES(p_DATE            IN DATE,
							p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							p_CRED    IN mex_credentials,
							p_REPORT_TYPE     IN VARCHAR2,
							p_STATUS          OUT NUMBER,
							p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_REPORT_NAME VARCHAR2(64);
	v_EXCHANGE_ID NUMBER(9);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	 --Build report name
	v_REPORT_NAME := g_DSS_NYISO_RATES_REP_NAME || '_' || p_REPORT_TYPE;


	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

            --SAVE THE CLOB AND EXCHANGE ID
            IF p_STATUS >= 0 THEN
               g_DSS_REP_MAP (v_REPORT_NAME) := v_EXCHANGE_ID;
            END IF;
			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(g_DSS_NYISO_RATES_REP_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_NYISO_RATES:' ||
					 SQLERRM);
END FETCH_NYISO_RATES;*/
-------------------------------------------------------------------------------------------
PROCEDURE PARSE_NYISO_RESIDUALS(p_CLOB    IN CLOB,
								p_RECORDS OUT MEX_NY_RESIDUAL_TBL,
								p_STATUS  OUT NUMBER,
								p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_RESIDUAL_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        -- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(2),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);

				p_RECORDS(p_RECORDS.LAST) := MEX_NY_RESIDUAL(INVOICE_VERSION => TO_NUMBER(v_COLS(1)),
														  CHARGE_DATE            => v_CURRENT_DATE,
														  NY_RT_LSE_LOAD => TO_NUMBER(NVL(v_COLS(3),'0')),
														  NY_RT_EXPORT_TRANS => TO_NUMBER(NVL(v_COLS(4),'0')),
														  NY_RT_WT_TRANS => TO_NUMBER(NVL(v_COLS(5),'0')),
														  NY_DAM_ENGY_CR_TO_PS => TO_NUMBER(NVL(v_COLS(6),'0')),
														  NY_DAM_ENGY_CH_TO_LSE => TO_NUMBER(NVL(v_COLS(7),'0')),
														  NY_DAM_LMBP_ENGY_CH_TC => TO_NUMBER(NVL(v_COLS(8),'0')),
														  NY_DAM_LOSS_CR_TO_PS => TO_NUMBER(NVL(v_COLS(9),'0')),
														  NY_DAM_LOSS_CH_TO_LSE => TO_NUMBER(NVL(v_COLS(10),'0')),
														  NY_DAM_LMBP_LOSS_CH_TC => TO_NUMBER(NVL(v_COLS(11),'0')),
														  NY_DAM_TUC_LOSS_CH_TC => TO_NUMBER(NVL(v_COLS(12),'0')),
														  NY_BAL_ENGY_CR_TO_PS => TO_NUMBER(NVL(v_COLS(13),'0')),
														  NY_BAL_ENGY_CH_TO_LSE => TO_NUMBER(NVL(v_COLS(14),'0')),
														  NY_BAL_LMBP_ENGY_CH_TC => TO_NUMBER(NVL(v_COLS(15),'0')),
														  NY_BAL_LOSS_CR_PS => TO_NUMBER(NVL(v_COLS(16),'0')),
														  NY_BAL_LOSS_CH_LSE => TO_NUMBER(NVL(v_COLS(17),'0')),
														  NY_BAL_LMBP_LOSS_CH_TC => TO_NUMBER(NVL(v_COLS(18),'0')),
														  NY_BAL_TUC_LOSS_CH_TC => TO_NUMBER(NVL(v_COLS(19),'0')),
														  NY_BAL_CONG_CR_TO_PC => TO_NUMBER(NVL(v_COLS(20),'0')),
														  NY_BAL_CONG_CH_TO_LSE => TO_NUMBER(NVL(v_COLS(21),'0')),
														  NY_BAL_LMBP_CONG_CH_TC => TO_NUMBER(NVL(v_COLS(22),'0')),
														  NY_BAL_TUC_CONG_CH_TC => TO_NUMBER(NVL(v_COLS(23),'0')),
														  DAM_ENGY_RESID_STLM => TO_NUMBER(NVL(v_COLS(24),'0')),
														  DAM_LOSS_RESID_STLM => TO_NUMBER(NVL(v_COLS(25),'0')),
														  BAL_ENGY_RESID_STLM => TO_NUMBER(NVL(v_COLS(26),'0')),
														  BAL_LOSS_RESID_STLM => TO_NUMBER(NVL(v_COLS(27),'0')),
														  BAL_CONG_RESID_STLM => TO_NUMBER(NVL(v_COLS(28),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_NYISO_RESIDUALS:' ||
					 SQLERRM);

END PARSE_NYISO_RESIDUALS;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_NYISO_RESIDUALS(p_DATE            IN DATE,
								p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								p_CRED    IN mex_credentials,
								p_REPORT_TYPE     IN VARCHAR2,
								p_RECORDS         OUT MEX_NY_RESIDUAL_TBL,
								p_STATUS          OUT NUMBER,
								p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_NYISO_RESID_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

            FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);
            IF p_STATUS >= 0 THEN
               --Parse the clob, return the object
               PARSE_NYISO_RESIDUALS(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
            END IF;

            v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_NYISO_RESIDUALS:' ||
					 SQLERRM);
END FETCH_NYISO_RESIDUALS;
---------------------------------------------------------------------------------------
/*PROCEDURE FETCH_NYISO_RESIDUALS(p_DATE            IN DATE,
								p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								p_CRED    IN mex_credentials,
								p_REPORT_TYPE     IN VARCHAR2,
								p_STATUS          OUT NUMBER,
								p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_NYISO_RESID_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

            FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);
            IF p_STATUS >= 0 THEN
               --Parse the clob, return the object
               g_DSS_REP_MAP(v_REPORT_NAME) := v_EXCHANGE_ID;
            END IF;

            v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
     END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		P_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_NYISO_RESIDUALS:' ||
					 SQLERRM);
END FETCH_NYISO_RESIDUALS;*/
--------------------------------------------------------------------------------------
/*PROCEDURE GET_NYISO_RESIDUALS(p_REPORT_TYPE     IN VARCHAR2,
                              p_RECORDS         OUT mex_ny_residual_tbl,
								p_STATUS          OUT NUMBER,
								p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);
	v_NAME VARCHAR2(64);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_NYISO_RESID_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_NYISO_RESIDUALS(v_CLOB_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_NYISO_RESIDUALS:' ||
					 SQLERRM;
END GET_NYISO_RESIDUALS;*/
---------------------------------------------------------------------------------------
PROCEDURE PARSE_NYISO_TOTALS(p_CLOB    IN CLOB,
							 p_RECORDS OUT MEX_NY_TOTAL_TBL,
							 p_STATUS  OUT NUMBER,
							 p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_TOTAL_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        -- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(2),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_TOTAL(INVOICE_VERSION => TO_NUMBER(v_COLS(1)),
														  CHARGE_DATE            => v_CURRENT_DATE,
														  NY_RT_EXPORT_TRANS     => TO_NUMBER(NVL(v_COLS(3),'0')),
														  NY_RT_LSE_LOAD         => TO_NUMBER(NVL(v_COLS(4),'0')),
														  NY_REG_CR_TO_PS        => TO_NUMBER(NVL(v_COLS(5),'0')),
														  NY_REG_CHG_TO_PS       => TO_NUMBER(NVL(v_COLS(6),'0')),
														  REGULATION_STLM        => TO_NUMBER(NVL(v_COLS(7),'0')),
														  NY_OP_RES_CR_TO_PS     => TO_NUMBER(NVL(v_COLS(8),'0')),
														  NY_OP_RES_SHTCHG_TO_PS => TO_NUMBER(NVL(v_COLS(9),'0')),
														  OP_RES_STLM            => TO_NUMBER(NVL(v_COLS(10),'0')),
														  NY_BLACK_START_COST    => TO_NUMBER(NVL(v_COLS(11),'0')),
														  BLACK_START_STLM       => TO_NUMBER(NVL(v_COLS(12),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_NYISO_TOTALS:' ||
					 SQLERRM);

END PARSE_NYISO_TOTALS;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_NYISO_TOTALS(p_DATE            IN DATE,
							 p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							 p_CRED    IN mex_credentials,
							 p_REPORT_TYPE     IN VARCHAR2,
							 p_RECORDS         OUT MEX_NY_TOTAL_TBL,
							 p_STATUS          OUT NUMBER,
							 p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_NYISO_TOTAL_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

            FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

            IF p_STATUS >= 0 THEN
               --Parse the clob, return the object
               PARSE_NYISO_TOTALS(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_NYISO_TOTALS:' ||
					 SQLERRM);
END FETCH_NYISO_TOTALS;
------------------------------------------------------------------------------------------------
/*PROCEDURE FETCH_NYISO_TOTALS(p_DATE            IN DATE,
							 p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
							 p_CRED    IN mex_credentials,
							 p_REPORT_TYPE     IN VARCHAR2,
							 p_STATUS          OUT NUMBER,
							 p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_NYISO_TOTAL_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

            FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

            IF p_STATUS >= 0 THEN
               --Parse the clob, return the object
               g_DSS_REP_MAP (v_REPORT_NAME) := v_EXCHANGE_ID;
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_NYISO_TOTALS:' ||
					 SQLERRM);
END FETCH_NYISO_TOTALS;*/
-----------------------------------------------------------------------------------------------------
/*PROCEDURE GET_NYISO_TOTALS(p_REPORT_TYPE     IN VARCHAR2,
						   p_RECORDS         OUT mex_ny_total_tbl,
							 p_STATUS          OUT NUMBER,
							 p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);
	v_REPORT_NAME VARCHAR2(64);
	v_NAME VARCHAR2(64);

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_NYISO_TOTAL_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size


	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP

		IF v_NAME = v_REPORT_NAME THEN
			v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_NYISO_TOTALS(v_CLOB_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_NYISO_TOTALS:' ||
					 SQLERRM;
END GET_NYISO_TOTALS;*/
------------------------------------------------------------------------------------------------------
PROCEDURE PARSE_BAL_MARKET_ENERGY(p_CLOB    IN CLOB,
								  p_RECORDS OUT MEX_NY_BAL_MKT_EN_TBL,
								  p_STATUS  OUT NUMBER,
								  p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES 	   PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  	   PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_BAL_MKT_EN_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        -- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(3),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_BAL_MKT_EN(INVOICE_VERSION => TO_NUMBER(v_COLS(1)),
															   SERVICE_POINT_ID => v_COLS(2),
															   CHARGE_DATE      => v_CURRENT_DATE,
															   BAL_MKT_ENRG_STLM => TO_NUMBER(NVL(v_COLS(4),'0')),
															   BAL_MKT_LOSS_STLM => TO_NUMBER(NVL(v_COLS(5),'0')),
															   BAL_MKT_CONG_STLM => TO_NUMBER(NVL(v_COLS(6),'0')),
															   TOTAL_BAL_MKT_STLM => TO_NUMBER(NVL(v_COLS(7),'0')),
															   BAL_MKT_LOAD => TO_NUMBER(NVL(v_COLS(8),'0')),
															   DAM_SCHED_LOAD => TO_NUMBER(NVL(v_COLS(9),'0')),
															   RT_ACTUAL_LOAD => TO_NUMBER(NVL(v_COLS(10),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_BAL_MARKET_ENERGY:' ||
					 SQLERRM);

END PARSE_BAL_MARKET_ENERGY;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_BAL_MARKET_ENERGY(p_DATE            IN DATE,
								  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								  p_CRED    IN mex_credentials,
								  p_REPORT_TYPE     IN VARCHAR2,
								  p_RECORDS         OUT MEX_NY_BAL_MKT_EN_TBL,
								  p_STATUS          OUT NUMBER,
								  p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_EN_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
	           PARSE_BAL_MARKET_ENERGY(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_BAL_MARKET_ENERGY:' ||
					 SQLERRM);
END FETCH_BAL_MARKET_ENERGY;
---------------------------------------------------------------------------------------
/*PROCEDURE GET_BAL_MARKET_ENERGY(p_REPORT_TYPE     IN VARCHAR2,
								  p_RECORDS         OUT MEX_NY_BAL_MKT_EN_TBL,
								  p_STATUS          OUT NUMBER,
								  p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_NAME        VARCHAR2(64);
	v_REPORT_NAME VARCHAR2(64);
    v_EXCHANGE_ID NUMBER(9);

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_EN_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_BAL_MARKET_ENERGY(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_BAL_MARKET_ENERGY:' ||
					 SQLERRM;
END GET_BAL_MARKET_ENERGY;*/
---------------------------------------------------------------------------------------
/*PROCEDURE FETCH_BAL_MARKET_ENERGY(p_DATE            IN DATE,
								  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								  p_CRED    IN mex_credentials,
								  p_REPORT_TYPE     IN VARCHAR2,
								  p_STATUS          OUT NUMBER,
								  p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID    NUMBER(9);

BEGIN

    p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_EN_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
	           g_DSS_REP_MAP(v_REPORT_NAME) := v_EXCHANGE_ID;
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER_LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_BAL_MARKET_ENERGY:' ||
					 SQLERRM);
END FETCH_BAL_MARKET_ENERGY;*/
---------------------------------------------------------------------------------------
PROCEDURE PARSE_DAM_ENERGY(p_CLOB    IN CLOB,
						   p_RECORDS OUT MEX_NY_DAM_ENERGY_TBL,
						   p_STATUS  OUT NUMBER,
						   p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_DAM_ENERGY_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        -- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(3),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_DAM_ENERGY(INVOICE_VERSION => TO_NUMBER(v_COLS(1)),
															   SERVICE_POINT_ID => v_COLS(2),
															   CHARGE_DATE => v_CURRENT_DATE,
															   LMBP_DAM_ENERGY => TO_NUMBER(NVL(v_COLS(4),'0')),
															   LMBP_DAM_LOSS => TO_NUMBER(NVL(v_COLS(5),'0')),
															   LMBP_DAM_CONG => TO_NUMBER(NVL(v_COLS(6),'0')),
															   DAM_SCH_LOAD => TO_NUMBER(NVL(v_COLS(7),'0')),
															   TOTAL_DAM_STLM => TO_NUMBER(NVL(v_COLS(8),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_DAM_ENERGY:' ||
					 SQLERRM);

END PARSE_DAM_ENERGY;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_DAM_ENERGY(p_DATE            IN DATE,
						   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
						   p_CRED    IN mex_credentials,
						   p_REPORT_TYPE     IN VARCHAR2,
						   p_RECORDS         OUT MEX_NY_DAM_ENERGY_TBL,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_ENERG_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
               PARSE_DAM_ENERGY(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_DAM_ENERGY:' ||
					 SQLERRM);
END FETCH_DAM_ENERGY;
----------------------------------------------------------------------------------------
/*PROCEDURE FETCH_DAM_ENERGY(p_DATE            IN DATE,
						   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
						   p_CRED    IN mex_credentials,
						   p_REPORT_TYPE     IN VARCHAR2,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_ENERG_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
               g_DSS_REP_MAP(v_REPORT_NAME) := v_EXCHANGE_ID;
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_DAM_ENERGY:' ||
					 SQLERRM);
END FETCH_DAM_ENERGY;*/
----------------------------------------------------------------------------------------
/*PROCEDURE GET_DAM_ENERGY(p_REPORT_TYPE     IN VARCHAR2,
                         p_RECORDS         OUT mex_ny_dam_energy_tbl,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);
	v_REPORT_NAME VARCHAR2(64);
	v_NAME VARCHAR2(64);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_ENERG_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_DAM_ENERGY(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_DAM_ENERGY:' ||
					 SQLERRM;
END GET_DAM_ENERGY;*/

-----------------------------------------------------------------------------------------
PROCEDURE PARSE_INBOX_LIST(p_CLOB        IN CLOB,
						   p_RECORDS     IN OUT MEX_NY_DOC_IDENT_TBL,
						   p_STATUS      OUT NUMBER,
						   p_LOGGER      IN OUT MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
        p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

    p_STATUS := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_DOC_IDENT_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        -- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL THEN
				PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
				p_RECORDS.EXTEND();
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_DOC_IDENT(DOC_ID => v_COLS(1),
															  DOC_NAME => v_COLS(2),
															  DOC_SIZE => v_COLS(3),
															  DOC_DATE => SUBSTR(v_COLS(5),1,11) || SUBSTR(v_COLS(5),-4));

		END IF;
		v_IDX := v_LINES.NEXT(v_IDX);


	END LOOP;


EXCEPTION
	WHEN OTHERS THEN
		P_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_INBOX_LIST:' ||
					 SQLERRM);
END PARSE_INBOX_LIST;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_INBOX_LIST(p_CRED    IN mex_credentials,
						   p_RECORDS   OUT MEX_NY_DOC_IDENT_TBL,
						   p_STATUS    OUT NUMBER,
						   p_LOGGER    IN OUT MM_LOGGER_ADAPTER) IS

	v_MAP MEX_Util.Parameter_Map;
	v_CLOB_RESP CLOB;
    v_COOKIES   MEX_COOKIE_TBL;
	v_RESULT       MEX_RESULT;
	v_LOG_ONLY NUMBER := 0;

BEGIN

	v_MAP('isouser') := p_CRED.USERNAME;
	v_MAP('isopass') := p_CRED.PASSWORD;
	v_MAP('isoautomated') := g_DSS_AUTOMATED_LEVEL;

	IF MM_NYISO_UTIL.g_TEST THEN
		v_LOG_ONLY := 1;
	END IF;
	
	p_LOGGER.LOG_INFO('Settlement: Get list of files');
	v_RESULT := MEX_SWITCHBOARD.INVOKE(p_Market => g_NYISO_DSS_MARKET,
									   p_Action => g_DSS_FILE_LIST_ACTION,
									   p_Logger => p_LOGGER,
									   p_Cred => p_CRED,
									   p_Parms => v_MAP,
									   p_Log_Only => v_LOG_ONLY);
										   
	p_STATUS := v_RESULT.STATUS_CODE;
    IF p_STATUS <> MEX_Switchboard.c_Status_Success THEN
        v_CLOB_RESP := NULL; -- this indicates failure - MEX_Switchboard.Invoke will have already logged error message
    ELSE
        p_LOGGER.LOG_INFO('Exchange successful');
        v_CLOB_RESP := v_RESULT.RESPONSE;
		-- This cookie string will be used for all other fetches here after
		v_COOKIES := v_RESULT.COOKIES;
		g_DSS_COOKIE_STRING := GET_COOKIE_STRING(v_COOKIES);
    END IF;

	-- Parse he list and extract the Document Name, Document ID, and Document Size from the list
	IF p_status = MEX_UTIL.g_SUCCESS THEN
		PARSE_INBOX_LIST(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_INBOX_LIST:' ||
					 SQLERRM);
END FETCH_INBOX_LIST;
------------------------------------------------------------------------------------------
  -- Author  : AHUSSAIN
  -- Created : 6/26/2006 1:35:09 PM
  -- Purpose : Converts the MEX_COOKIE_TBL entries to a semi-colon delimited Cookie String
  --           used in the 'isoMEX-REQUEST-HEADER-COOKIE' parameter

  FUNCTION GET_COOKIE_STRING(p_COOKIES MEX_COOKIE_TBL) RETURN VARCHAR2 IS
    v_RESULT VARCHAR2(8192);
    v_IDX BINARY_INTEGER;
  BEGIN
    -- loop through all the records in the table
    v_IDX := p_COOKIES.FIRST;
    WHILE p_COOKIES.EXISTS(v_IDX) LOOP
        v_RESULT := v_RESULT || p_COOKIES(v_IDX).NAME || '=' || p_COOKIES(v_IDX).VALUE || '; ';
    	--next line
    	v_IDX := p_COOKIES.NEXT(v_IDX);
    END LOOP;
    RETURN(v_RESULT);
  END GET_COOKIE_STRING;
------------------------------------------------------------------------------------------
  -- Author  : AHUSSAIN
  -- Created : 6/26/2006 4:35:09 PM
  -- Purpose : Check for error messages in the clob and post an event log if one found.
  --           Returns 0 if no error, -1 if Zero rows error, -2 if row exceeded error
  --           and -3 if file size limit exceeded.
  FUNCTION CHECK_ERROR_MESSAGES(p_CLOB IN CLOB, p_LOGGER IN OUT mm_logger_adapter) RETURN NUMBER IS
    v_RESULT NUMBER(1);
  BEGIN
    v_RESULT := g_DSS_ERR_NO_ERROR;
    IF INSTR(p_CLOB, 'ZERO ROWS') > 0 THEN
		p_LOGGER.LOG_WARN('Retrieved empty document.');
		v_RESULT := g_DSS_ERR_ZERO_ROWS;
    ELSIF INSTR(p_CLOB, 'EXCEEDS ROWCOUNT LIMIT') > 0 THEN
		p_LOGGER.LOG_WARN('Rowcount limit exceeded.');
        v_RESULT := g_DSS_ERR_ROWCOUNT_EXCEEDED;
    ELSIF INSTR(p_CLOB, 'EXCEEDS SIZE') > 0 THEN
		p_LOGGER.LOG_WARN('File size limit exceeded.');
        v_RESULT := g_DSS_ERR_FILESIZE_EXCEEDED;
	END IF;
    RETURN(v_RESULT);
  END CHECK_ERROR_MESSAGES;
------------------------------------------------------------------------------------------------
PROCEDURE PARSE_DAM_VIRTUAL_SUPPLY(p_CLOB    IN CLOB,
						           p_RECORDS OUT MEX_NY_DAM_VIR_SUP_TBL,
						           p_STATUS  OUT NUMBER,
						           p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_DAM_VIR_SUP_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
        -- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(3),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);

				p_RECORDS(p_RECORDS.LAST) := MEX_NY_DAM_VIR_SUP(INVOICE_VERSION => v_COLS(1),
																VS_BUS_IDENT => v_COLS(2),
																CHARGE_DATE => v_CURRENT_DATE,
																VS_DAM_ENGY_PRICE => TO_NUMBER(NVL(v_COLS(4),'0')),
																VS_DAM_LOSS_PRICE => TO_NUMBER(NVL(v_COLS(5),'0')),
																VS_DAM_CONG_PRICE => TO_NUMBER(NVL(v_COLS(6),'0')),
																VS_DAM_SUPPLY_ENGY => TO_NUMBER(NVL(v_COLS(7),'0')),
																VS_TOTAL_DAM_STLM => TO_NUMBER(NVL(v_COLS(8),'0')));
			END IF;

		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_DAM_VIRTUAL_SUPPLY:' ||
					 SQLERRM);

END PARSE_DAM_VIRTUAL_SUPPLY;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_DAM_VIRTUAL_SUPPLY(p_DATE            IN DATE,
						   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
						   p_CRED    IN mex_credentials,
						   p_REPORT_TYPE     IN VARCHAR2,
						   p_RECORDS         OUT MEX_NY_DAM_VIR_SUP_TBL ,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_VIRT_SUPPLY_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
               PARSE_DAM_VIRTUAL_SUPPLY(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_DAM_VIRTUAL_SUPPLY:' ||
					 SQLERRM);
END FETCH_DAM_VIRTUAL_SUPPLY;
------------------------------------------------------------------------------------------------
/*PROCEDURE FETCH_DAM_VIRTUAL_SUPPLY(p_DATE            IN DATE,
						   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
						   p_CRED    IN mex_credentials,
						   p_REPORT_TYPE     IN VARCHAR2,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_VIRT_SUPPLY_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
               g_DSS_REP_MAP(v_REPORT_NAME) := v_EXCHANGE_ID;
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.FETCH_DAM_VIRTUAL_SUPPLY:' ||
					 SQLERRM;
END FETCH_DAM_VIRTUAL_SUPPLY;*/
------------------------------------------------------------------------------------------------
/*PROCEDURE GET_DAM_VIRTUAL_SUPPLY(p_REPORT_TYPE     IN VARCHAR2,
								p_RECORDS         OUT mex_ny_dam_vir_sup_tbl,
						        p_STATUS          OUT NUMBER,
						        p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);
	v_REPORT_NAME VARCHAR2(64);
	v_NAME        VARCHAR2(64);
	v_CLOB_RESP   CLOB;

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_VIRT_SUPPLY_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_DAM_VIRTUAL_SUPPLY(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_DAM_VIRTUAL_SUPPLY:' ||
					 SQLERRM;
END GET_DAM_VIRTUAL_SUPPLY;*/

------------------------------------------------------------------------------------------------
PROCEDURE PARSE_DAM_VIRTUAL_LOAD(p_CLOB    IN CLOB,
								 p_RECORDS OUT MEX_NY_DAM_VIR_LOAD_TBL,
								 p_STATUS  OUT NUMBER,
								 p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES        PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_DAM_VIR_LOAD_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		-- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(3),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);

				p_RECORDS(p_RECORDS.LAST) := MEX_NY_DAM_VIR_LOAD(INVOICE_VERSION   => v_COLS(1),
																 VL_BUS_IDENT      => v_COLS(2),
																 CHARGE_DATE       => v_CURRENT_DATE,
																 VL_DAM_ENGY_PRICE => TO_NUMBER(NVL(v_COLS(4),0)),
																 VL_DAM_LOSS_PRICE => TO_NUMBER(NVL(v_COLS(5),'0')),
																 VL_DAM_CONG_PRICE => TO_NUMBER(NVL(v_COLS(6),'0')),
																 VL_DAM_LOAD_ENGY  => TO_NUMBER(NVL(v_COLS(7),'0')),
																 VL_TOTAL_DAM_STLM => TO_NUMBER(NVL(v_COLS(8),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_DAM_VIRTUAL_LOAD:' ||
					 SQLERRM);

END PARSE_DAM_VIRTUAL_LOAD;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_DAM_VIRTUAL_LOAD(p_DATE            IN DATE,
						   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
						   p_CRED    IN mex_credentials,
						   p_REPORT_TYPE     IN VARCHAR2,
						   p_RECORDS         OUT MEX_NY_DAM_VIR_LOAD_TBL ,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_VIRT_LOAD_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
               PARSE_DAM_VIRTUAL_LOAD(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_DAM_VIRTUAL_LOAD:' ||
					 SQLERRM);
END FETCH_DAM_VIRTUAL_LOAD;
-------------------------------------------------------------------------------------------
/*PROCEDURE GET_DAM_VIRTUAL_LOAD(p_REPORT_TYPE     IN VARCHAR2,
						   p_RECORDS         OUT MEX_NY_DAM_VIR_LOAD_TBL ,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_REPORT_NAME VARCHAR2(64);
	v_NAME VARCHAR2(64);
	v_EXCHANGE_ID    NUMBER(9);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_VIRT_LOAD_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_DAM_VIRTUAL_LOAD(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;


    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
       POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report is missing.',
							  GB.g_OSUSER);
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_DAM_VIRTUAL_LOAD:' ||
					 SQLERRM;
END GET_DAM_VIRTUAL_LOAD;*/
-----------------------------------------------------------------------------
/*PROCEDURE FETCH_DAM_VIRTUAL_LOAD(p_DATE            IN DATE,
						   p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
						   p_CRED    IN mex_credentials,
						   p_REPORT_TYPE     IN VARCHAR2,
						   p_STATUS          OUT NUMBER,
						   p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID NUMBER(9);

BEGIN

     p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_DAM_VIRT_LOAD_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

            --Parse the clob, return the object
            IF p_STATUS >= 0 THEN
               g_DSS_REP_MAP(v_REPORT_NAME) := v_EXCHANGE_ID;
            END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

    -- Report missing in DSS
    IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
    END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_DAM_VIRTUAL_LOAD:' ||
					 SQLERRM);
END FETCH_DAM_VIRTUAL_LOAD;*/

------------------------------------------------------------------------------------------------
PROCEDURE PARSE_BAL_MKT_VIRT_SUPPLY(p_CLOB    IN CLOB,
									p_RECORDS OUT MEX_NY_BAL_VS_TBL,
									p_STATUS  OUT NUMBER,
									p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES 	   PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  	   PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_BAL_VS_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		-- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(3),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_BAL_VS(INVOICE_VERSION   => TO_NUMBER(v_COLS(1)),
														   VS_BUS_IDENT      => v_COLS(2),
														   CHARGE_DATE       => v_CURRENT_DATE,
														   BAL_VS_ENRG_STLM  => TO_NUMBER(NVL(v_COLS(4),'0')),
														   BAL_VS_LOSS_STLM  => TO_NUMBER(NVL(v_COLS(5),'0')),
														   BAL_VS_CONG_STLM  => TO_NUMBER(NVL(v_COLS(6),'0')),
														   TOTAL_VS_BAL_STLM => TO_NUMBER(NVL(v_COLS(7),'0')),
														   VS_DAM_SUPPLY_ENGY => TO_NUMBER(NVL(v_COLS(8),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_BAL_MKT_VIRT_SUPPLY:' ||
					 SQLERRM);

END PARSE_BAL_MKT_VIRT_SUPPLY;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_BAL_MKT_VIRT_SUPPLY(p_DATE            IN DATE,
									p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
									p_CRED    IN mex_credentials,
									p_REPORT_TYPE     IN VARCHAR2,
									p_RECORDS         OUT MEX_NY_BAL_VS_TBL,
									p_STATUS          OUT NUMBER,
									p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_VS_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

			--Parse the clob, return the object
			IF p_STATUS >= 0 THEN
				PARSE_BAL_MKT_VIRT_SUPPLY(v_CLOB_RESP,
										  p_RECORDS,
										  p_STATUS,
										  p_LOGGER);
			END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

	-- Report missing in DSS
	IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_BAL_MKT_VIRT_SUPPLY:' ||
					 SQLERRM);
END FETCH_BAL_MKT_VIRT_SUPPLY;
-------------------------------------------------------------------------------------------
/*PROCEDURE GET_BAL_MKT_VIRT_SUPPLY(p_REPORT_TYPE     IN VARCHAR2,
									p_RECORDS         OUT MEX_NY_BAL_VS_TBL,
									p_STATUS          OUT NUMBER,
									p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_NAME VARCHAR2(64);
    v_EXCHANGE_ID    NUMBER(9);

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_VS_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_BAL_MKT_VIRT_SUPPLY(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;


	-- Report missing in DSS
	IF v_EXIT_LOOP = FALSE THEN
		POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report for is missing.',
							  GB.g_OSUSER);
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_MESSAGE := 'Error in MEX_NYISO_SETTLEMENT.GET_BAL_MKT_VIRT_SUPPLY:' ||
					 SQLERRM;
END GET_BAL_MKT_VIRT_SUPPLY;*/
-----------------------------------------------------------------------------------------------
/*PROCEDURE FETCH_BAL_MKT_VIRT_SUPPLY(p_DATE            IN DATE,
									p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
									p_CRED    IN mex_credentials,
									p_REPORT_TYPE     IN VARCHAR2,
									p_STATUS          OUT NUMBER,
									p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID    NUMBER(9);

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_VS_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

			--Parse the clob, return the object
			IF p_STATUS >= 0 THEN
				g_DSS_REP_MAP(v_REPORT_NAME) := v_EXCHANGE_ID;
			END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

	-- Report missing in DSS
	IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_BAL_MKT_VIRT_SUPPLY:' ||
					 SQLERRM);
END FETCH_BAL_MKT_VIRT_SUPPLY;*/
-------------------------------------------------------------------------------------------
PROCEDURE PARSE_BAL_MKT_VIRT_LOAD(p_CLOB    IN CLOB,
								  p_RECORDS OUT MEX_NY_BAL_VL_TBL,
								  p_STATUS  OUT NUMBER,
								  p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_LENGTH       NUMBER;
	v_LINES 	   PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS         PARSE_UTIL.STRING_TABLE;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE DATE;

BEGIN

	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 OR CHECK_ERROR_MESSAGES(p_CLOB, p_LOGGER) < 0 THEN
		p_STATUS := MEX_UTIL.g_SUCCESS;
		RETURN;
	END IF;

	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_NY_BAL_VL_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		-- Skip if the line is a header line or if it is null
		IF v_LINES(v_IDX) IS NOT NULL AND v_IDX != 1 THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
			--the new DSS interface will generate some of the CADD reports with multiple headers 
			--check if the val in first col is numeric; skip the line otherwise 
			IF REGEXP_SUBSTR(v_COLS(1), '^[[:digit:]]+$') IS NOT NULL THEN
				p_RECORDS.EXTEND();
				-- convert to standard time, hour ending
				v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(3),
															   g_DSS_TIME_ZONE,
															   g_DSS_DATE_TIME_FORMAT,
															   60);
				p_RECORDS(p_RECORDS.LAST) := MEX_NY_BAL_VL(INVOICE_VERSION   => TO_NUMBER(v_COLS(1)),
														   VL_BUS_IDENT      => v_COLS(2),
														   CHARGE_DATE       => v_CURRENT_DATE,
														   BAL_VL_ENRG_STLM  => TO_NUMBER(NVL(v_COLS(4),'0')),
														   BAL_VL_LOSS_STLM  => TO_NUMBER(NVL(v_COLS(5),'0')),
														   BAL_VL_CONG_STLM  => TO_NUMBER(NVL(v_COLS(6),'0')),
														   TOTAL_VL_BAL_STLM => TO_NUMBER(NVL(v_COLS(7),'0')),
														   VL_DAM_LOAD_ENGY  => TO_NUMBER(NVL(v_COLS(8),'0')));
			END IF;
		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.PARSE_BAL_MKT_VIRT_LOAD:' ||
					 SQLERRM);

END PARSE_BAL_MKT_VIRT_LOAD;
------------------------------------------------------------------------------------------
PROCEDURE FETCH_BAL_MKT_VIRT_LOAD(p_DATE            IN DATE,
								  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								  p_CRED    IN mex_credentials,
								  p_REPORT_TYPE     IN VARCHAR2,
								  p_RECORDS         OUT MEX_NY_BAL_VL_TBL,
								  p_STATUS          OUT NUMBER,
								  p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_VL_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 p_STATUS,
							 p_LOGGER);

			--Parse the clob, return the object
			IF p_STATUS >= 0 THEN
				PARSE_BAL_MKT_VIRT_LOAD(v_CLOB_RESP,
									    p_RECORDS,
									    p_STATUS,
									    p_LOGGER);
			END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

	-- Report missing in DSS
	IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_BAL_MKT_VIRT_LOAD:' ||
					 SQLERRM);
END FETCH_BAL_MKT_VIRT_LOAD;
-------------------------------------------------------------------------------------------
/*PROCEDURE GET_BAL_MKT_VIRT_LOAD(p_REPORT_TYPE     IN VARCHAR2,
								  p_RECORDS         OUT MEX_NY_BAL_VL_TBL,
								  p_STATUS          OUT NUMBER,
								  p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_NAME VARCHAR2(64);
    v_EXCHANGE_ID    NUMBER(9);


BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_VL_REP_NAME || '_' || p_REPORT_TYPE;

	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_NAME := g_DSS_REP_MAP.FIRST;

	WHILE g_DSS_REP_MAP.EXISTS(v_NAME) LOOP
		IF v_NAME = v_REPORT_NAME THEN
		   v_EXCHANGE_ID := g_DSS_REP_MAP(v_NAME);
		    SELECT RESPONSE_CONTENTS INTO v_CLOB_RESP FROM MEX_LOG_CLOB_DETAILS WHERE EXCHANGE_ID = v_EXCHANGE_ID;
            --Parse the clob, return the object
            PARSE_BAL_MKT_VIRT_LOAD(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
			v_EXIT_LOOP := TRUE;
		END IF;

		v_NAME := g_DSS_REP_MAP.NEXT(v_NAME);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

	-- Report missing in DSS
	IF v_EXIT_LOOP = FALSE THEN
		POST_TO_APP_EVENT_LOG('Admin',
							  'MEX_NYISO_SETTLEMENT',
							  'Retrieve file',
							  'WARNING',
							  'PROCESS',
							  NULL,
							  NULL,
							  v_REPORT_NAME || ' report is missing.',
							  GB.g_OSUSER);
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.GET_BAL_MKT_VIRT_LOAD:' ||
					 SQLERRM);
END GET_BAL_MKT_VIRT_LOAD;*/
----------------------------------------------------------------------------------------------

/*PROCEDURE FETCH_BAL_MKT_VIRT_LOAD(p_DATE            IN DATE,
								  p_DOC_LIST        IN MEX_NY_DOC_IDENT_TBL,
								  p_CRED    IN mex_credentials,
								  p_REPORT_TYPE     IN VARCHAR2,
								  p_STATUS          OUT NUMBER,
								  p_LOGGER          IN OUT MM_LOGGER_ADAPTER) IS

	v_REPORT_NAME VARCHAR2(64);
	v_DOC_DATA    MEX_NY_DOC_IDENT;
	v_LOOKUP_DATE VARCHAR2(20);
	v_IDX         BINARY_INTEGER;
	v_CLOB_RESP   CLOB;
	v_EXIT_LOOP   BOOLEAN := FALSE;
	v_EXCHANGE_ID    NUMBER(9);

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;

	--Build report name
	v_REPORT_NAME := g_DSS_BAL_MKT_VL_REP_NAME || '_' || p_REPORT_TYPE;
	
	--Search though the list of documents and get the identifiers for this report: name, id and size
	v_LOOKUP_DATE := TO_CHAR(TRUNC(p_DATE), g_DSS_DATE_FORMAT);
	v_IDX         := p_DOC_LIST.FIRST;

	WHILE p_DOC_LIST.EXISTS(v_IDX) LOOP
		v_DOC_DATA := p_DOC_LIST(v_IDX);
		IF INSTR(v_DOC_DATA.DOC_NAME, v_REPORT_NAME) > 0 AND
		   v_DOC_DATA.DOC_DATE = v_LOOKUP_DATE THEN

			FETCH_DSS_REPORT(p_CRED,
							 v_DOC_DATA,
							 v_CLOB_RESP,
							 v_EXCHANGE_ID,
							 p_STATUS,
							 p_LOGGER);

			--Parse the clob, return the object
			IF p_STATUS >= 0 THEN
				g_DSS_REP_MAP(v_REPORT_NAME) := v_EXCHANGE_ID;
			END IF;

			v_EXIT_LOOP := TRUE;
		END IF;

		v_IDX := p_DOC_LIST.NEXT(v_IDX);
		EXIT WHEN v_EXIT_LOOP;
	END LOOP;

	-- Report missing in DSS
	IF v_EXIT_LOOP = FALSE THEN
		p_LOGGER.LOG_ERROR(v_REPORT_NAME || ' report for ' || v_LOOKUP_DATE || ' is missing.');
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLCODE;
		p_LOGGER.LOG_ERROR('Error in MEX_NYISO_SETTLEMENT.FETCH_BAL_MKT_VIRT_LOAD:' ||
					 SQLERRM);
END FETCH_BAL_MKT_VIRT_LOAD;*/
------------------------------------------------------------------------------------------------------
END MEX_NYISO_SETTLEMENT;
/
