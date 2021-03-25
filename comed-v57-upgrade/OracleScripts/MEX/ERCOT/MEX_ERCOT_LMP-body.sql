CREATE OR REPLACE PACKAGE BODY MEX_ERCOT_LMP IS
-----------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_HIST_PAGE(p_PRICE_TYPE IN VARCHAR2,
						  p_CLOB_RESP  IN CLOB,
						  p_BEGIN_DATE IN DATE,
						  p_END_DATE   IN DATE,
						  p_FILES      OUT PARSE_UTIL.BIG_STRING_TABLE_MP,
						  p_STATUS     OUT NUMBER,
						  p_MESSAGE    OUT VARCHAR2) AS

	v_BEGIN_POS        NUMBER := 1;
	v_END_POS          NUMBER := 1;
	v_COUNT            BINARY_INTEGER := 0;
	v_LOOKUP_DATE      VARCHAR2(8);
	v_FILE_NAME        VARCHAR(4000);
	v_CURRENT_DATE     DATE;
	v_LENGTH           NUMBER;
	v_LOOP_COUNTER     NUMBER;
	v_FILE_NAME_LENGTH NUMBER := 64;
    v_URL_LOC   VARCHAR2(16) := '<ContentURL>';

BEGIN
	-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB_RESP);
	IF v_LENGTH = 0 THEN
		p_STATUS := MEX_UTIL.g_FAILURE;
		RETURN;
	END IF;

	p_STATUS := MEX_UTIL.g_SUCCESS;

/*	--THE LENGTH OF THE ZIP FILE NAMES DIFFER FOR MARKET PRICES AND ANCILLARY SERVICES
	IF p_PRICE_TYPE = g_LMP_MKT_PRICE THEN
		v_FILE_NAME_LENGTH := 63;
	ELSE
		v_FILE_NAME_LENGTH := 64;
	END IF;*/

	v_CURRENT_DATE := TRUNC(p_END_DATE);
	v_LOOP_COUNTER := 0;
	--LOOP OVER DATES AND GET THE ZIP FILE NAME THAT MATCHES THAT DATE
	LOOP
		v_LOOKUP_DATE := TO_CHAR(v_CURRENT_DATE, 'YYYYMMDD');
		v_END_POS     := DBMS_LOB.INSTR(p_CLOB_RESP,
										v_LOOKUP_DATE,
										v_BEGIN_POS);

		--ext.00000204.0000000000000000.20060422.053223.Market_Prices.zip - 63 chars
		--ext.00000211.0000000000000000.20060502.190220.DAYAHEADREPORT.zip - 64 chars
		IF v_END_POS = 0 THEN
                --THERE IS NO FILENAME FOR THIS PARTICULAR DATE
                LOGS.LOG_WARN('There is no filename avaliable for ' || v_LOOKUP_DATE || ' .');

		ELSE

            v_BEGIN_POS := DBMS_LOB.INSTR(p_CLOB_RESP,
										v_URL_LOC,
										v_END_POS);

            v_FILE_NAME := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB_RESP,
													   v_FILE_NAME_LENGTH,
													   v_BEGIN_POS + LENGTH(v_URL_LOC))));

			--v_FILE_NAME := DBMS_LOB.SUBSTR(C, 63,v_POS - 30);
			/*v_FILE_NAME := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB_RESP,
													   v_FILE_NAME_LENGTH,
													   v_END_POS - 30)));*/

		    v_COUNT := v_COUNT + 1;
			p_FILES(v_COUNT) := v_FILE_NAME;

			--DBMS_OUTPUT.put_line('FILE NAME: ' || v_FILE_NAME);
			v_BEGIN_POS := 1;
		END IF;

		v_CURRENT_DATE := v_CURRENT_DATE - 1;
		v_LOOP_COUNTER := v_LOOP_COUNTER + 1;
		IF v_LOOP_COUNTER > 100000 THEN
			RAISE_APPLICATION_ERROR(-20901,
									'RUNAWAY LOOP IN PARSE_UTIL.PARSE_CLOB_INTO_LINES');
		END IF;

		EXIT WHEN v_CURRENT_DATE < TRUNC(p_BEGIN_DATE);

	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLERRM;
		p_MESSAGE := 'Error in MEX_ERCOT_LMP.PARSE_HIST_PAGE ' || SQLERRM;

END PARSE_HIST_PAGE;
-----------------------------------------------------------------------------------------
PROCEDURE FETCH_HIST_PAGE(p_CRED	   IN mex_credentials,
						  p_PRICE_TYPE IN VARCHAR2,
						  p_BEGIN_DATE IN DATE,
						  p_END_DATE   IN DATE,
						  p_LOG_ONLY   IN NUMBER,
						  p_FILE_LIST  OUT PARSE_UTIL.BIG_STRING_TABLE_MP,
						  p_STATUS     OUT NUMBER,
						  p_MESSAGE    OUT VARCHAR2,
						  p_LOGGER	   IN OUT mm_logger_adapter) AS

	v_RESPONSE_CLOB    CLOB := NULL;
	v_URL       VARCHAR2(100);
	v_RESULT	   MEX_RESULT;

BEGIN

	IF p_PRICE_TYPE = g_LMP_MKT_PRICE THEN
		v_URL := GET_DICTIONARY_VALUE('LMP HIST BASE URL', 0, 'MarketExchange', 'ERCOT', 'LMP', '?');
	ELSE
		v_URL := GET_DICTIONARY_VALUE('ANC HIST BASE URL', 0, 'MarketExchange', 'ERCOT', 'LMP', '?');
	END IF;

    v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => v_URL, --CD.URL_ENCODE(v_URL),
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
		PARSE_HIST_PAGE(p_PRICE_TYPE,
							v_RESPONSE_CLOB,
							p_BEGIN_DATE,
							p_END_DATE,
							p_FILE_LIST,
							p_STATUS,
							p_MESSAGE);
    END IF;

	DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);
EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLERRM;
		p_MESSAGE := 'Error in MEX_ERCOT_LMP.FETCH_HIST_PAGE ' || SQLERRM;

END FETCH_HIST_PAGE;
-----------------------------------------------------------------------------------------------
PROCEDURE FETCH_MKT_CLEARING_PRICE(p_CRED	   IN mex_credentials,
								   p_FILE_NAME   IN VARCHAR2,
								   p_LOG_ONLY    IN NUMBER,
								   p_WORK_ID     OUT NUMBER,
								   p_STATUS      OUT NUMBER,
								   p_MESSAGE     OUT VARCHAR2,
								   p_LOGGER	   IN OUT mm_logger_adapter) AS

	v_RESPONSE_XML XMLTYPE;
	v_XML_FILE XMLTYPE := NULL;
	v_RESPONSE_CLOB CLOB := NULL;
	v_RESULT MEX_RESULT;

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

	p_STATUS    := MEX_UTIL.g_SUCCESS;
	--v_FETCH_URL := g_LMP_BASE_URL || p_FILE_NAME;

	--GENERATE A WORK ID
	SELECT AID.NEXTVAL INTO p_WORK_ID FROM DUAL;


    v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => p_FILE_NAME, --CD.URL_ENCODE(p_FILE_NAME),
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
	--LOOP THROUGH XML AND GET THE LIST OF FILES
		v_RESPONSE_XML := XMLTYPE.CREATEXML(v_RESPONSE_CLOB);

		FOR v_FILE IN c_FILES(v_RESPONSE_XML) LOOP
			DBMS_LOB.CREATETEMPORARY(v_RESPONSE_CLOB, TRUE);

			p_LOGGER.EXCHANGE_NAME := 'ERCOT_LMP: Fetch File';
			v_RESULT := Mex_Switchboard.FetchFile(p_FilePath => v_FILE.FILENAME,
												 p_Logger => p_LOGGER,
												 p_Cred => p_CRED,
												 p_Log_Only => p_LOG_ONLY);



				p_STATUS  := v_RESULT.STATUS_CODE;
				IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
					v_RESPONSE_CLOB := NULL;
					v_XML_FILE := NULL;
				ELSE
					v_RESPONSE_CLOB := v_RESULT.RESPONSE;
				END IF;

				IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
					IF UPPER(v_FILE.FILENAME) LIKE '%MARKET_INTERVAL_DATA%' THEN
						MEX_ERCOT.PARSE_MKT_DATA(p_WORK_ID,
												 v_RESPONSE_CLOB,
												 p_STATUS,
												 p_MESSAGE);
					ELSE
						MEX_ERCOT.PARSE_MKT_HEADER(p_WORK_ID,
												   v_RESPONSE_CLOB,
												   p_STATUS,
												   p_MESSAGE);
					END IF;

					DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);
				END IF;

			COMMIT;

		END LOOP;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLERRM;
		p_MESSAGE := 'Error in MEX_ERCOT_LMP.FETCH_MKT_CLEARING_PRICE ' ||
					 SQLERRM;

END FETCH_MKT_CLEARING_PRICE;
------------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ANCILLARY_SERVICE(p_CLOB    IN CLOB,
								  p_RECORDS IN OUT MEX_ERCOT_ANCILLARY_SERV_TBL,
								  p_STATUS  OUT NUMBER,
								  p_MESSAGE OUT VARCHAR2) AS

	v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
	v_COLS  PARSE_UTIL.STRING_TABLE;
	v_IDX   BINARY_INTEGER;

BEGIN

	p_STATUS := MEX_UTIL.g_SUCCESS;
	p_RECORDS := MEX_ERCOT_ANCILLARY_SERV_TBL();

	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, v_LINES);
	v_IDX := v_LINES.FIRST;

	WHILE v_LINES.EXISTS(v_IDX) LOOP
		IF v_LINES(v_IDX) IS NOT NULL THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX),',',v_COLS);

			p_RECORDS.EXTEND();
			p_RECORDS(p_RECORDS.LAST) := MEX_ERCOT_ANCILLARY_SERV(HOUR_ENDING    => TO_CUT(TO_DATE(v_COLS(1),
																								   'MM/DD/YYYY HH24:MI:SS'),
																						   MEX_ERCOT.g_ERCOT_TIME_ZONE),
																  MKT_ID         => v_COLS(2),
																  SERVICE_TYPE   => v_COLS(3),
																  REQUESTED_MW   => v_COLS(4),
																  PROCURMENT     => v_COLS(5),
																  CLEARING_PRICE => v_COLS(6),
																  AS_BID_MW      => v_COLS(7));

		END IF;

		v_IDX := v_LINES.NEXT(v_IDX);
	END LOOP;

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLERRM;
		p_MESSAGE := 'Error in MEX_ERCOT_LMP.PARSE_ANCILLARY_SERVICE ' ||
					 SQLERRM;

END PARSE_ANCILLARY_SERVICE;
----------------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ANCILLARY_SERVICE(p_CRED		IN mex_credentials,
								  p_FILE_NAME   IN VARCHAR2,
								  p_LOG_ONLY    IN NUMBER,
								  p_RECORDS     OUT MEX_ERCOT_ANCILLARY_SERV_TBL,
								  p_STATUS      OUT NUMBER,
								  p_MESSAGE     OUT VARCHAR2,
								  p_LOGGER		IN OUT mm_logger_adapter) AS

	v_RESPONSE_CLOB    CLOB := NULL;
	v_RESULT	   MEX_RESULT;
BEGIN

	p_STATUS    := MEX_UTIL.g_SUCCESS;
	--v_FETCH_URL := g_ANC_BASE_URL || p_FILE_NAME;
    v_RESULT := Mex_Switchboard.FetchURL(p_URL_to_Fetch => p_FILE_NAME, --CD.URL_ENCODE(p_FILE_NAME),
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
	  PARSE_ANCILLARY_SERVICE(v_RESPONSE_CLOB, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;

	DBMS_LOB.FREETEMPORARY(v_RESPONSE_CLOB);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS  := SQLERRM;
		p_MESSAGE := 'Error in MEX_ERCOT_LMP.FETCH_ANCILLARY_SERVICE ' ||
					 SQLERRM;

END FETCH_ANCILLARY_SERVICE;
-------------------------------------------------------------------------------------------------------
END MEX_ERCOT_LMP;
/
