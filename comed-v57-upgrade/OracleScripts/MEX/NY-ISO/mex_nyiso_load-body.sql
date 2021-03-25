CREATE OR REPLACE PACKAGE BODY MEX_NYISO_LOAD IS

  -- CONSTANTS ---
  vPackageName CONSTANT VARCHAR2(50) := 'MEX_NYISO_LOAD';
-----------------------------------------------------------
	FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
	BEGIN
    	RETURN '$Revision: 1.1 $';
	END WHAT_VERSION;
  -----------------------------------------------------------
	---------------- ISO Load Forecast ------------------------
  -----------------------------------------------------------
  --
  -- parse the CSV file for ISO Load Forecast into records
  --

---------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_ISO_LOAD(p_CSV          IN CLOB,
                           p_RECORDS      OUT MEX_NY_LOAD_TBL,
                           p_STATUS       OUT NUMBER,
                           p_LOGGER      IN OUT mm_logger_adapter) IS

    vProcedureName VARCHAR2(50) := 'PARSE_ISO_LOAD';
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
    v_COLS_IDX   BINARY_INTEGER;
    v_CURRENT_DATE DATE;

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
  -- copied from mex_pjm_esched.PARSE_RECON_DATA()
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_LOAD_TBL();   -- the load zones

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        IF v_LINES(v_IDX) IS NOT NULL THEN
          IF v_IDX = 1 THEN  -- 1st line contains the load zones
  			FOR v_COLS_IDX IN 2 .. v_COLS.LAST LOOP
            --  "Time Stamp","MYZONE1","MYZONE2" ..."MYZONE_N"
               p_RECORDS.EXTEND();  -- get a new load zone
               p_RECORDS(p_RECORDS.LAST) :=  MEX_NY_LOAD(ZONE_ID => NULL,
                                                         ZONE_NAME => trim(both '"' from v_COLS(v_COLS_IDX)),
                                                         SCHEDULES => MEX_SCHEDULE_TBL());
            END LOOP;
          ELSE -- records 2..N have data
            -- convert to standard time

            v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(REPLACE(v_COLS(1), '"', ''),
			                         MEX_NYISO.g_NYISO_TIME_ZONE,
                                     MEX_NYISO.g_DATE_TIME_FMT);

  			FOR v_COLS_IDX IN 2 .. v_COLS.LAST LOOP
				p_RECORDS(v_COLS_IDX - 1).SCHEDULES.EXTEND;
				p_RECORDS(v_COLS_IDX - 1).SCHEDULES(p_RECORDS(v_COLS_IDX - 1).SCHEDULES.LAST) :=
                    MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                    VOLUME => to_number(v_COLS(v_COLS_IDX)),
                    RATE => NULL);
            END LOOP;
          END IF;  -- IF NOT THE 1ST RECORD
        END IF;  -- there is data to parse
        v_IDX := v_LINES.NEXT(v_IDX);
      END LOOP;

/*	  for i in p_RECORDS.FIRST .. p_RECORDS.LAST
	  loop
	  dbms_output.put_line(p_RECORDS(i).ZONE_NAME || ', schedules count(' || to_char(i) || ')=' ||
	               to_char(p_RECORDS(i).SCHEDULES.count()) ||
				   ', ' || to_char(p_RECORDS(i).ZONE_ID));
	  end loop;*/

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_LOGGER.LOG_ERROR('Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM);
  END PARSE_ISO_LOAD;


  ----------------------------------------------------------------------
	---------------- Integrated Real Time Actual (RTA) Load --------------
  ----------------------------------------------------------------------
  --
  -- parse the CSV file for RTA load into records.  Also works for
  --    Integrated RTA load
  --
  PROCEDURE PARSE_RTA_LOAD(p_CSV         IN CLOB,
                           p_ACTION      IN VARCHAR2,
                           p_RECORDS     OUT MEX_NY_LOAD_TBL,
                           p_STATUS      OUT NUMBER,
                           p_LOGGER     IN OUT mm_logger_adapter) IS

    vProcedureName VARCHAR2(50) := 'PARSE_RTA_LOAD';

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
    v_OBJS_SEEN BINARY_INTEGER := 0;

    v_LOAD_VALS MEX_SCHEDULE_TBL;
    v_CURRENT_LOAD_ZONE_INDX BINARY_INTEGER;
    v_CURRENT_TIMEZONE VARCHAR2(4);
    v_CURRENT_DATE DATE;
    v_INDEX_MAP MEX_NYISO.PARAMETER_MAP;
	v_MINUTES_ADJ NUMBER;


  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
  -- copied from mex_pjm_esched.PARSE_RECON_DATA()
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_LOAD_TBL();   -- the load zones

    IF INSTR(UPPER(P_ACTION), 'INTEGRATED') > 0 THEN
	  v_MINUTES_ADJ := 60; -- 60 minute adjust for 'hour ending'
	ELSE
	  v_MINUTES_ADJ := 5; -- 5 minute data adjust for 'hour ending'
	END IF;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        -- skip the 1st line as it has column headers
        --    "Time Stamp","Time Zone","Name","PTID","Integrated Load"
        IF v_IDX >= 2 AND v_LINES(v_IDX) IS NOT NULL THEN
            -- convert to standard time
            v_CURRENT_TIMEZONE := trim(both '"' from v_COLS(2));
            v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(REPLACE(v_COLS(1), '"', ''),
			                         MEX_NYISO.g_NYISO_TIME_ZONE,
                                     MEX_NYISO.g_DATE_TIME_FMT,
									 v_MINUTES_ADJ);
            -- if this is the first time the load zone has been seen:
            --   create a new one and initialize the quantity entry table
            IF (INSTR(v_COLS(1), '00:00:00') > 0) THEN
               v_LOAD_VALS := MEX_SCHEDULE_TBL(); -- get a new load values array
               v_LOAD_VALS.EXTEND();
               v_LOAD_VALS(v_LOAD_VALS.LAST) := MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                                                             VOLUME => to_number(v_COLS(5)),
                                                             RATE => NULL);
               p_RECORDS.EXTEND();  -- get a new load zone
			   p_RECORDS(p_RECORDS.LAST) :=  MEX_NY_LOAD(ZONE_ID => trim(both '"' from v_COLS(4)),
                                                         ZONE_NAME => trim(both '"' from v_COLS(3)),
                                                         SCHEDULES => v_LOAD_VALS);
               v_OBJS_SEEN := v_OBJS_SEEN + 1;
               -- cache the load zone name and its index here.
               v_INDEX_MAP(trim(both '"' from v_COLS(3))) := to_char(v_IDX - 1);
            ELSE -- load zone already exists, look it up
               -- lookup the cached index based on the load zone name
               v_CURRENT_LOAD_ZONE_INDX := to_number(v_INDEX_MAP(trim(both '"' from v_COLS(3))));

			   p_RECORDS(v_CURRENT_LOAD_ZONE_INDX).SCHEDULES.EXTEND;
			   p_RECORDS(v_CURRENT_LOAD_ZONE_INDX).SCHEDULES(p_RECORDS(v_CURRENT_LOAD_ZONE_INDX).SCHEDULES.LAST) :=
                    MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                    VOLUME => to_number(v_COLS(5)),
					RATE => NULL);

            END IF; -- IF AN INSERT OR AN UPDATE
        END IF;  -- IF NOT THE 1ST RECORD
        v_IDX := v_LINES.NEXT(v_IDX);
      END LOOP;

/*	  for i in p_RECORDS.FIRST .. p_RECORDS.LAST
	  loop
	  dbms_output.put_line(p_RECORDS(i).ZONE_NAME || ', schedules count(' || to_char(i) || ')=' ||
	               to_char(p_RECORDS(i).SCHEDULES.count()) ||
				   ', ' || to_char(p_RECORDS(i).ZONE_ID));
	  end loop;*/

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_LOGGER.LOG_ERROR('Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM);
  END PARSE_RTA_LOAD;


  ----------------------------------------------------------------------
	---------------- Generic Fetch Load Routine --------------------------
  ----------------------------------------------------------------------

  --
  -- Fetch the CSV file for LOAD  and map into records for MM import.  The ACTION
  --   parameter dictates what type of LOAD.  Use the constants referenced below
  --   to acquire the desired data:
  --
  -- g_ISO_LOAD                  - 'ISO LOAD';
  -- g_RT_ACTUAL_LOAD            - 'REAL TIME LOAD';
  -- g_INTEGRATED_RT_ACTUAL_LOAD - 'INTEGRATED REAL TIME LOAD';
  --
  PROCEDURE FETCH_LOAD(p_DATE     IN  DATE,
                       p_ACTION   IN VARCHAR2,
                       p_RECORDS  OUT MEX_NY_LOAD_TBL,
                       p_STATUS   OUT NUMBER,
                       p_LOGGER   IN OUT MM_LOGGER_ADAPTER) IS

    vProcedureName VARCHAR2(50) := 'FETCH_LOAD';
    v_REQUEST_URL VARCHAR2(255);
    v_CLOB_RESP    CLOB;
    v_RESULT      MEX_RESULT;
	
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;

    -- build the url needed. The action and date controls the resulting URL
    MEX_NYISO.BUILD_PUBLIC_URL(p_DATE,FALSE, p_ACTION, v_REQUEST_URL, p_STATUS, p_LOGGER);

    -- acquire the CSV file
     IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
          p_LOGGER.EXCHANGE_NAME := p_ACTION;
          v_RESULT               := Mex_Switchboard.FetchURL(v_REQUEST_URL,  p_LOGGER);
      
          p_STATUS := v_RESULT.STATUS_CODE;
          IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
              v_CLOB_RESP := NULL;
          ELSE
              v_CLOB_RESP := v_RESULT.RESPONSE;
          END IF;
      END IF;

    -- parse the response into records
    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
       IF (INSTR(UPPER(p_ACTION), 'REAL TIME') > 0) THEN -- IF READING RT LOAD
          PARSE_RTA_LOAD(v_CLOB_RESP,
		                p_ACTION,
                        p_RECORDS,
                        p_STATUS,
                        p_LOGGER);
       ELSE  -- PARSE ISO LOAD DATA
          PARSE_ISO_LOAD(v_CLOB_RESP,
                        p_RECORDS,
                        p_STATUS,
                        p_LOGGER);
       END IF;
    END IF;

  END FETCH_LOAD;

	----------------------------------------------------------------------------------------------------


END MEX_NYISO_LOAD;
/
