CREATE OR REPLACE PACKAGE BODY MEX_NYISO_BIDPOST IS

  -- DATA USED TO BUILD REQUESTS
  g_NYISO_REQUEST_HDR_DELIMITER CONSTANT CHAR(1) := '&';
  g_CRLF                        CONSTANT VARCHAR2(2) := CHR(13) || CHR(10);
  g_NYISO_DATE_TIME_FMT         CONSTANT VARCHAR2(21) := 'MM/DD/YYYY HH24:MI';


----------------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
  FUNCTION PACKAGE_NAME RETURN VARCHAR IS
  BEGIN
      RETURN 'MEX_NYISO_BIDPOST';
  END PACKAGE_NAME;
----------------------------------------------------------------------------------------------------------
  -----------------------------------------------------------
	---------------- Physical Load QUERY ----------------------
  -----------------------------------------------------------
  --
  -- Parse the CSV file for the Physical Load into records.
  -- This request works for interpreting both the query
  -- and submit responses.
  --
  PROCEDURE PARSE_LOAD_RESPONSE(p_RESPONSE     IN  CLOB,
                                p_RECORDS      OUT MEX_NY_PHYSICAL_LOAD_TBL,
								p_STATUS       OUT NUMBER,
								p_LOGGER	   IN OUT NOCOPY MM_LOGGER_ADAPTER
                                ) IS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
    v_CURRENT_DATE DATE;
    v_TS_STRING varchar2(64);
    v_TS_DATE DATE;

  BEGIN
  
  	p_STATUS  := MEX_UTIL.g_SUCCESS;
	p_LOGGER.LOG_DEBUG('Parsing Load Response');
	
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_RESPONSE, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_PHYSICAL_LOAD_TBL();   -- data

    WHILE v_LINES.EXISTS(v_IDX) LOOP
		IF v_LINES(v_IDX) IS NOT NULL THEN
			PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);	
			
			IF v_IDX = 1 THEN -- timestamp record
            	v_TS_STRING := substr(v_COLS(1), (instr(v_COLS(1), '=') + 1));
            	v_TS_DATE := TO_DATE(v_TS_STRING, g_NYISO_DATE_TIME_FMT);
				
			ELSIF v_IDX > 3 THEN-- 1st 3 record are not needed
              	-- hour 25 means extra fall back hour
                -- NYISO times are Hour Beginning
                -- ROMM database times are Hour Ending
    			v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(v_COLS(3), MEX_NYISO.g_NYISO_TIME_ZONE, g_NYISO_DATE_TIME_FMT);
    
                p_RECORDS.EXTEND();  -- get a new load record
                p_RECORDS(p_RECORDS.LAST) :=
                    MEX_NY_PHYSICAL_LOAD(
                      LOAD_NAME                  => trim(both '"' from v_COLS(1)),
                      LOAD_NID                   => to_number(v_COLS(2)),
                      LOAD_DATE                  => v_CURRENT_DATE,
                      FORECAST_MW                => to_number(v_COLS(4)),
                      FIXED_MW                   => to_number(v_COLS(5)),
                      PRICE_CAP_1_MW             => to_number(v_COLS(6)),
                      PRICE_CAP_1_DOLLAR         => to_number(v_COLS(7)),
                      PRICE_CAP_2_MW             => to_number(v_COLS(8)),
                      PRICE_CAP_2_DOLLAR         => to_number(v_COLS(9)),
                      PRICE_CAP_3_MW             => to_number(v_COLS(10)),
                      PRICE_CAP_3_DOLLAR         => to_number(v_COLS(11)),
                      INTERRUPTIBLE_TYPE         => trim(both '"' from v_COLS(12)),
                      INTERRUPTIBLE_FIXED_MW     => to_number(v_COLS(13)),
                      INTERRUPTIBLE_FIXED_COST   => to_number(v_COLS(14)),
                      INTERRUPTIBLE_CAPPED_MW    => to_number(v_COLS(15)),
                      INTERRUPTIBLE_CAPPED_COST  => to_number(v_COLS(16)),
                      BID_NID                    => to_number(v_COLS(17)),
                      SCHED_PRICE_CAPPED         => to_number(v_COLS(18)),
                      SCHED_INTERRUPTIBLE_FIXED  => to_number(v_COLS(19)),
                      SCHED_INTERRUPTIBLE_CAPPED => to_number(v_COLS(20)),
                      -- TODO: determine if UPDATE_USER_IDENT is the userid passed into NYISO
                      UPDATE_USER_IDENT          => NULL,
                      -- TODO: determine if UPDATE_TIME should come from record # 1
                      UPDATE_TIME                => v_TS_DATE,
                      BID_STATUS                 => trim(both '"' from v_COLS(21)),
                      MESSAGE                    => trim(both '"' from v_COLS(22)));
          END IF;
		END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;
	
	p_LOGGER.LOG_DEBUG('Done Parsing Load Response');
  
  EXCEPTION
    WHEN OTHERS THEN
	  p_STATUS  := SQLCODE;
      p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.PARSE_LOAD_RESPONSE: ' || SQLERRM);
  END PARSE_LOAD_RESPONSE;
----------------------------------------------------------------------------------------------------------
  -- Build the request needed to pose a query for physical load
  PROCEDURE BUILD_PHY_LOAD_QUERY_REQUEST
  (
      p_REQUEST_DAY IN DATE,
      p_CRED        IN mex_credentials,
      p_REQUEST     OUT CLOB,
      p_LOGGER      IN OUT mm_logger_adapter
  ) IS
  
      v_ROW_DATA VARCHAR2(500);
  
  BEGIN
  
      p_LOGGER.LOG_INFO('Building Physical Load Query Request for ' || p_REQUEST_DAY);
  
      DBMS_LOB.CREATETEMPORARY(p_REQUEST, TRUE);
      DBMS_LOB.OPEN(p_REQUEST, DBMS_LOB.LOB_READWRITE);
  
      v_ROW_DATA := 'USERID=' || p_CRED.USERNAME || g_NYISO_REQUEST_HDR_DELIMITER;
      DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);
  
      v_ROW_DATA := 'PASSWORD=' || SECURITY_CONTROLS.DECODE(p_CRED.PASSWORD) ||g_NYISO_REQUEST_HDR_DELIMITER;
      DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);
  
      v_ROW_DATA := 'QUERY_TYPE=LOAD_SCH' || g_NYISO_REQUEST_HDR_DELIMITER;
      DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);
  
      v_ROW_DATA := 'DATE=' || TO_CHAR(p_REQUEST_DAY, 'MM/DD/YYYY');
      DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);
  
      DBMS_LOB.CLOSE(p_REQUEST);
  
  END BUILD_PHY_LOAD_QUERY_REQUEST;
----------------------------------------------------------------------------------------------------------
  -- Fetch the CSV file for PHYSICAL LOAD  and map into records for MM import.
  PROCEDURE FETCH_PHYSICAL_LOAD
  (
    p_DATE    IN DATE,
    p_CRED    IN mex_credentials,
    p_RECORDS OUT MEX_NY_PHYSICAL_LOAD_TBL,
    p_STATUS  OUT NUMBER,
    p_LOGGER  IN OUT NOCOPY MM_LOGGER_ADAPTER
  ) IS

    v_REQUEST_CLOB CLOB;
    v_DATA_CLOB    CLOB;
    v_RESULT       MEX_RESULT;
  BEGIN
    -- build the request
    BUILD_PHY_LOAD_QUERY_REQUEST(p_DATE, p_CRED, v_REQUEST_CLOB, p_LOGGER);

    IF MM_NYISO_UTIL.g_TEST THEN
        v_DATA_CLOB := NULL;
        p_LOGGER.LOG_START('test.' || MEX_NYISO.g_MEX_MARKET,
                           MEX_NYISO.g_MEX_ACTION_BID_QUERY);
        p_LOGGER.LOG_ATTACHMENT('Request Body', 'text', v_REQUEST_CLOB);
        p_LOGGER.LOG_STOP(0, 'Success');
    
    ELSE
        v_RESULT := MEX_SWITCHBOARD.invoke(p_Market              => MEX_NYISO.g_MEX_MARKET,
                                           p_Action              => MEX_NYISO.g_MEX_ACTION_BID_QUERY,
                                           p_Logger              => p_LOGGER,
                                           p_Cred                => p_CRED,
                                           p_Request_ContentType => CONSTANTS.MIME_TYPE_TEXT,
                                           p_Request             => v_REQUEST_CLOB);
    END IF;

    p_STATUS := v_RESULT.STATUS_CODE;
    IF p_STATUS <> MEX_Switchboard.c_Status_Success THEN
        v_DATA_CLOB := NULL; -- this indicates failure - MEX_Switchboard.Invoke will have already logged error message
    ELSE
        p_LOGGER.LOG_INFO('Exchange successful');
        v_DATA_CLOB := v_RESULT.RESPONSE;
    END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        -- parse the response into records
        PARSE_LOAD_RESPONSE(v_DATA_CLOB, p_RECORDS, p_STATUS, p_LOGGER);
    ELSE
        p_LOGGER.LOG_ERROR(PACKAGE_NAME ||
                           '.FETCH_PHYSICAL_LOAD: Error when downloading physical load,' || SQLERRM);
    END IF;
	
  END FETCH_PHYSICAL_LOAD;
----------------------------------------------------------------------------------------------------------
---------------- Physical Load SUBMIT ----------------------
  -- Build the request needed to SUBMIT physical load data to NYISO.
  -- This involves translating the data in the records provided into
  -- a properly formed NYISO request.
  --
PROCEDURE BUILD_PHY_LOAD_SUBMIT_REQUEST(p_RECORDS   IN MEX_NY_PHYSICAL_LOAD_TBL,
										p_CRED     	IN mex_credentials,
										p_REQUEST   OUT CLOB,
										p_LOGGER    IN OUT mm_logger_adapter) IS

	v_ROW_DATA     VARCHAR2(1024);
	v_DA_REC       MEX_NY_PHYSICAL_LOAD;
	v_IDX          BINARY_INTEGER;
	v_CURRENT_DATE VARCHAR2(32);
BEGIN
	
	p_LOGGER.LOG_INFO('Building Physical Load Submit Request');

	DBMS_LOB.CREATETEMPORARY(p_REQUEST, TRUE);
	DBMS_LOB.OPEN(p_REQUEST, DBMS_LOB.LOB_READWRITE);

	-- TODO: DETERMINE IF WE NEED NEWLINES AFTER EACH ENTRY IN THE HEADER
	v_ROW_DATA := 'BID_TYPE=LOAD_BID' || g_NYISO_REQUEST_HDR_DELIMITER || g_CRLF;
	DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);
	
	v_ROW_DATA := 'USERID=' || p_CRED.USERNAME|| g_NYISO_REQUEST_HDR_DELIMITER || g_CRLF;
	DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);

	v_ROW_DATA := 'PASSWORD=' || SECURITY_CONTROLS.DECODE(p_CRED.PASSWORD) || g_NYISO_REQUEST_HDR_DELIMITER || g_CRLF;
	DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);

	v_ROW_DATA := 'DATA_ROWS=' || p_RECORDS.LAST || g_NYISO_REQUEST_HDR_DELIMITER || g_CRLF;
	DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);
	
	v_IDX := p_RECORDS.FIRST();
	WHILE p_RECORDS.EXISTS(v_IDX) LOOP
		v_DA_REC := p_RECORDS(v_IDX);

		-- p_RECORDS date is standard hour ending time
		-- output hour 25 means extra fall back hour
		-- NYISO times are Hour Beginning
		-- ROMM database times are Hour Ending
		v_CURRENT_DATE := MEX_NYISO.FROM_CUT_TO_STRING(v_DA_REC.LOAD_DATE,
													   MEX_NYISO.g_NYISO_TIME_ZONE,
													   g_NYISO_DATE_TIME_FMT);

		/*Load PTID, date and time, forecast MW, fixed MW,
        price cap 1 MW, price cap 1 dollar,
        price cap 2 MW, price cap 2 dollar,
        price cap 3 MW, price cap 3 dollar,
        interruptible type, interruptible fixed MW, interruptible fixed cost,
        interruptible capped MW, interruptible capped cost  */

		v_ROW_DATA := v_DA_REC.LOAD_NID || ',' ||
					  v_CURRENT_DATE || ',' ||
					  v_DA_REC.FORECAST_MW || ',' ||
					  v_DA_REC.FIXED_MW || ',' ||
					  v_DA_REC.PRICE_CAP_1_MW || ',' ||
					  v_DA_REC.PRICE_CAP_1_DOLLAR || ',' ||
					  v_DA_REC.PRICE_CAP_2_MW || ',' ||
					  v_DA_REC.PRICE_CAP_2_DOLLAR || ',' ||
					  v_DA_REC.PRICE_CAP_3_MW || ',' ||
					  v_DA_REC.PRICE_CAP_3_DOLLAR || ',' ||
					  v_DA_REC.INTERRUPTIBLE_TYPE || ',' ||
					  v_DA_REC.INTERRUPTIBLE_FIXED_MW || ',' ||
					  v_DA_REC.INTERRUPTIBLE_FIXED_COST || ',' ||
					  v_DA_REC.INTERRUPTIBLE_CAPPED_MW || ',' ||
					  v_DA_REC.INTERRUPTIBLE_CAPPED_COST || g_CRLF;

		DBMS_LOB.WRITEAPPEND(p_REQUEST, LENGTH(v_ROW_DATA), v_ROW_DATA);
		
		v_IDX := p_RECORDS.NEXT(v_IDX);
	END LOOP;

	DBMS_LOB.CLOSE(p_REQUEST);
	
END BUILD_PHY_LOAD_SUBMIT_REQUEST;
-------------------------------------------------------------------------------------------------------
  -- Submit the data for PHYSICAL LOAD.  Map the response into records for MM usage.
  -- The parameter map will include needed connect / permissions info
PROCEDURE SUBMIT_PHYSICAL_LOAD
(
    p_CRED        IN mex_credentials,
    p_RECORDS_IN  IN MEX_NY_PHYSICAL_LOAD_TBL,
    p_RECORDS_OUT OUT MEX_NY_PHYSICAL_LOAD_TBL,
    p_LOGGER      IN OUT NOCOPY MM_LOGGER_ADAPTER,
    p_STATUS      OUT NUMBER
) IS

    v_REQUEST_CLOB  CLOB;
    v_RESPONSE_CLOB CLOB;
    v_RESULT        MEX_RESULT;

BEGIN
    -- build the request
    BUILD_PHY_LOAD_SUBMIT_REQUEST(p_RECORDS_IN, p_CRED, v_REQUEST_CLOB,p_LOGGER);

    IF MM_NYISO_UTIL.g_TEST THEN
        v_RESPONSE_CLOB := NULL;
        p_LOGGER.LOG_START('test.' || MEX_NYISO.g_MEX_MARKET, MEX_NYISO.g_MEX_ACTION_BID_SUBMIT);
        p_LOGGER.LOG_ATTACHMENT('Request Body', 'text', v_REQUEST_CLOB);
        p_LOGGER.LOG_STOP(0, 'Success');
    ELSE
        v_RESULT := MEX_SWITCHBOARD.invoke(p_Market              => MEX_NYISO.g_MEX_MARKET,
                                           p_Action              => MEX_NYISO.g_MEX_ACTION_BID_SUBMIT,
                                           p_Logger              => p_LOGGER,
                                           p_Cred                => p_CRED,
                                           p_Request_ContentType => CONSTANTS.MIME_TYPE_TEXT,
                                           p_Request             => v_REQUEST_CLOB);
    END IF;

    p_STATUS := v_RESULT.STATUS_CODE;
    IF p_STATUS <> MEX_Switchboard.c_Status_Success THEN
        v_RESPONSE_CLOB := NULL; -- this indicates failure - MEX_Switchboard.Invoke will have already logged error message
    ELSE
        p_LOGGER.LOG_INFO('Exchange successful');
        v_RESPONSE_CLOB := v_RESULT.RESPONSE;
    END IF;

    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        -- parse the response into records
        PARSE_LOAD_RESPONSE(v_RESPONSE_CLOB, p_RECORDS_OUT, p_STATUS, p_LOGGER);
    ELSE
        p_LOGGER.LOG_ERROR(PACKAGE_NAME ||
                           '.SUBMIT_PHYSICAL_LOAD: Error when submitting physical load,' || SQLERRM);
    END IF;

END SUBMIT_PHYSICAL_LOAD;
----------------------------------------------------------------------------------------------------
END MEX_NYISO_BIDPOST;
/
