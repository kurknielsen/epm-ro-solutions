CREATE OR REPLACE PACKAGE BODY MEX_ERCOT_SETTLEMENT IS

-------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SETTLEMENT_FILE
	(
    v_RESPONSE_CLOB IN CLOB,
    p_RECORDS IN OUT MEX_ERCOT_CHARGE_TOTAL_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
    ) IS
v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_CHARGE_DATE DATE;
v_CHARGE_TYPE NUMBER(1);
BEGIN
	p_STATUS := MEX_UTIL.g_SUCCESS;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(v_RESPONSE_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
    	IF v_LINES(v_IDX) IS NOT NULL THEN
			PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX),',',v_COLS);
            --PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);
			IF v_IDX = 1 THEN
        		v_CHARGE_DATE := TO_CUT(TO_DATE(SUBSTR(v_COLS(1), 1, 6), 'MMDDYY'), MEX_ERCOT.g_ERCOT_TIME_ZONE);
        	ELSE
            	p_RECORDS.EXTEND();
                -- 1 is ERCOT Settlement Channel for Final state
                IF v_COLS(2) = '1"' THEN
                	v_CHARGE_TYPE := 1;
                -- 4 is ERCOT Settlement Channel for Final state
                ELSIF v_COLS(2) = '4"' THEN
                	v_CHARGE_TYPE := 2;
                -- 5-9 is ERCOT Settlement Channel for True-Up & Resettlement states
                ELSIF v_COLS(2) = '5"' OR v_COLS(2) = '6"' OR
                	v_COLS(2) = '7"' OR v_COLS(2) = '8"' OR
                    v_COLS(2) = '9"' THEN
                	v_CHARGE_TYPE := 3;
                ELSE
                	v_CHARGE_TYPE := 1;
                END IF;
				p_RECORDS(p_RECORDS.LAST) := MEX_ERCOT_CHARGE_TOTAL
            									(
                                            	v_CHARGE_DATE,
                                            	v_COLS(1),
                                            	v_COLS(3),
                                            	v_CHARGE_TYPE
                                            	);

        	END IF;
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;
EXCEPTION
    WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.PARSE_SETTLEMENT_FILE: ' || SQLERRM;
END PARSE_SETTLEMENT_FILE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TOTAL_CHARGES_XLS_FILE
	(
     p_RESPONSE_XLS_FILE_LIST XMLTYPE,
     p_CRED IN mex_credentials,
	 p_LOG_ONLY	IN NUMBER,
     p_RECORDS OUT MEX_ERCOT_CHARGE_TOTAL_TBL,
     p_STATUS OUT NUMBER,
	 p_MESSAGE OUT VARCHAR2,
	 p_LOGGER IN OUT mm_logger_adapter
	) IS

v_RESPONSE_CLOB CLOB;
v_RESULT	   MEX_RESULT;
    CURSOR c_FILES(v_XML IN XMLTYPE) IS
	SELECT EXTRACTVALUE(VALUE(U),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF) "FILENAME"
	FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML,
									'//FileList',
									MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) T,
	TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) U
	WHERE UPPER(SUBSTR(EXTRACTVALUE(VALUE(T), 
	                       '//FileList/File'), -4)) = '.XLS';

BEGIN

    p_RECORDS := MEX_ERCOT_CHARGE_TOTAL_TBL();
    -- parse returned file list of zip file contents and request
    -- each file
	
    FOR v_FILE IN c_FILES(p_RESPONSE_XLS_FILE_LIST) LOOP
        -- send the request
        DBMS_LOB.CREATETEMPORARY(v_RESPONSE_CLOB, TRUE);
		
		v_RESULT := Mex_Switchboard.FetchFile(p_FilePath =>  v_FILE.FILENAME,
											 p_Logger => p_LOGGER,
											 p_Cred => p_CRED,
											 p_Log_Only => p_LOG_ONLY);

		p_STATUS  := v_RESULT.STATUS_CODE;
		IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
			v_RESPONSE_CLOB := NULL;
		ELSE
			v_RESPONSE_CLOB := v_RESULT.RESPONSE;
		END IF;

        IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
			PARSE_SETTLEMENT_FILE(v_RESPONSE_CLOB, p_RECORDS, p_STATUS, p_MESSAGE);
			DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);
		END IF;

    END LOOP;
EXCEPTION
	WHEN OTHERS THEN
	p_STATUS  := SQLCODE;
	p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.FETCH_TOTAL_CHARGES_XLS_FILE: ' || SQLERRM;
END FETCH_TOTAL_CHARGES_XLS_FILE;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_TOTAL_CHARGES_FILE
	(
	p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_SETTLEMENT_TYPE IN VARCHAR2,
    p_SETTLEMENT_PERIOD_TYPE IN VARCHAR2,
	p_CRED	IN mex_credentials,
	p_LOG_ONLY IN NUMBER,
	p_RECORDS OUT MEX_ERCOT_CHARGE_TOTAL_TBL,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_LOGGER IN OUT mm_logger_adapter
	) IS
v_URL       VARCHAR2(255);
v_FILENAME  VARCHAR2(255);
v_YEAR VARCHAR2(4);
v_MONTH VARCHAR2(2);
v_RESPONSE_CLOB CLOB;
v_RESPONSE_XLS_FILE_LIST XMLTYPE;
v_RESPONSE_ZIP_FILE_LIST XMLTYPE;
v_INTIAL_BASE_URL VARCHAR2(64) := GET_DICTIONARY_VALUE('INTIAL BASE URL', 0, 'MarketExchange', 'ERCOT', 'SETTLEMENT', '?');
v_FINAL_BASE_URL VARCHAR2(64) := GET_DICTIONARY_VALUE('FINAL BASE URL', 0, 'MarketExchange', 'ERCOT', 'SETTLEMENT', '?');
v_TRUEUP_BASE_URL VARCHAR2(64) := GET_DICTIONARY_VALUE('TRUEUP BASE URL', 0, 'MarketExchange', 'ERCOT', 'SETTLEMENT', '?');
v_CURRENT_DATE DATE;
v_END_DATE DATE;
v_RESULT	   MEX_RESULT;
CURSOR c_FILES(v_XML IN XMLTYPE) IS
	SELECT EXTRACTVALUE(VALUE(U),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF) "FILENAME"
	FROM TABLE(XMLSEQUENCE(EXTRACT(v_XML,
									'//FileList',
									MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) T,
	TABLE(XMLSEQUENCE(EXTRACT(VALUE(T),
							'//File',
							MEX_SWITCHBOARD.c_MEX_FILELIST_NAMESPACE_DEF))) U;

BEGIN
	p_STATUS  := MEX_UTIL.g_SUCCESS;
    -- Loop through the incremented begin date till we reach the end date
    v_CURRENT_DATE := FIRST_DAY(p_BEGIN_DATE);
    --for yearly request, only download one year
    IF p_SETTLEMENT_PERIOD_TYPE = MEX_ERCOT.g_ERCOT_YEARLY THEN
        v_END_DATE := p_BEGIN_DATE;
    ELSE
        v_END_DATE := p_END_DATE;
    END IF;

    WHILE v_CURRENT_DATE <= v_END_DATE
    LOOP
        v_YEAR := TO_CHAR(v_CURRENT_DATE, 'YYYY');
        v_MONTH := TO_CHAR(v_CURRENT_DATE, 'MM');

        -- Set the appropriate zip file name depending upon if the download is annual or monthly
        CASE
          WHEN p_SETTLEMENT_PERIOD_TYPE = MEX_ERCOT.g_ERCOT_MONTHLY THEN
               v_FILENAME := v_YEAR || '-' || v_MONTH || '%20' || p_SETTLEMENT_TYPE ||'.zip';
          WHEN p_SETTLEMENT_PERIOD_TYPE = MEX_ERCOT.g_ERCOT_YEARLY THEN
               v_FILENAME := v_YEAR || '_' || p_SETTLEMENT_TYPE ||'.zip';
          ELSE
              NULL;
        END CASE;

        CASE
        WHEN p_SETTLEMENT_TYPE = MEX_ERCOT.g_ERCOT_INITIAL THEN
        	v_URL := v_INTIAL_BASE_URL || v_FILENAME;
        WHEN p_SETTLEMENT_TYPE = MEX_ERCOT.g_ERCOT_FINAL THEN
        	v_URL := v_FINAL_BASE_URL || v_FILENAME;
        WHEN p_SETTLEMENT_TYPE = MEX_ERCOT.g_ERCOT_TRUEUP THEN
        	v_URL := v_TRUEUP_BASE_URL || v_FILENAME;
        ELSE
        	NULL;
        END CASE;

		v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => v_URL,
											 p_Logger => p_LOGGER,
											 p_Cred => p_CRED,
											 p_Log_Only => p_LOG_ONLY);

		p_STATUS  := v_RESULT.STATUS_CODE;
		IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
			v_RESPONSE_CLOB := NULL;
		ELSE
			v_RESPONSE_CLOB := v_RESULT.RESPONSE;
		END IF;

        CASE
            -- Monthly settlement
            -- We now have the list of xls files for this month
             WHEN p_SETTLEMENT_PERIOD_TYPE = MEX_ERCOT.g_ERCOT_MONTHLY THEN
            	IF v_RESPONSE_CLOB IS NOT NULL THEN
                	v_RESPONSE_XLS_FILE_LIST :=  XMLTYPE.CREATEXML(v_RESPONSE_CLOB);
                    MEX_ERCOT_SETTLEMENT.FETCH_TOTAL_CHARGES_XLS_FILE(v_RESPONSE_XLS_FILE_LIST, p_CRED, p_LOG_ONLY, p_RECORDS, p_STATUS, p_message, p_LOGGER);
            	END IF;

              -- Yearly Settlement
              -- We now have the list of monthly zip files
              WHEN p_SETTLEMENT_PERIOD_TYPE = MEX_ERCOT.g_ERCOT_YEARLY THEN
                   IF v_RESPONSE_CLOB IS NOT NULL THEN
                      v_RESPONSE_ZIP_FILE_LIST :=  XMLTYPE.CREATEXML(v_RESPONSE_CLOB);
                      FOR v_FILE IN c_FILES(v_RESPONSE_ZIP_FILE_LIST) LOOP

							v_RESULT := Mex_Switchboard.FetchFile(p_FilePath =>  v_FILE.FILENAME,
																 p_Logger => p_LOGGER,
																 p_Cred => p_CRED,
																 p_Log_Only => p_LOG_ONLY);

							p_STATUS  := v_RESULT.STATUS_CODE;
							IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
								v_RESPONSE_CLOB := NULL;
							ELSE
								v_RESPONSE_CLOB := v_RESULT.RESPONSE;
							END IF;

							IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
								v_RESPONSE_XLS_FILE_LIST :=  XMLTYPE.CREATEXML(v_RESPONSE_CLOB);
                            	FETCH_TOTAL_CHARGES_XLS_FILE(v_RESPONSE_XLS_FILE_LIST, p_CRED, p_LOG_ONLY, p_RECORDS, p_STATUS, p_message, p_LOGGER);
							END IF;
                      END LOOP;
                   END IF;

              ELSE
                  NULL;

           END CASE;
        v_CURRENT_DATE := v_CURRENT_DATE + NUMTOYMINTERVAL(1, 'MONTH');
     END LOOP;

EXCEPTION
	WHEN OTHERS THEN
	p_STATUS  := SQLCODE;
	p_MESSAGE := 'Error in MEX_ERCOT_SETTLEMENT.FETCH_TOTAL_CHARGES_FILE: ' || SQLERRM;
END FETCH_TOTAL_CHARGES_FILE;
----------------------------------------------------------------------------------------------
END MEX_ERCOT_SETTLEMENT;
/
