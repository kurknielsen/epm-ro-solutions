CREATE OR REPLACE PACKAGE BODY MEX_NYISO_TC IS

FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
  FUNCTION PACKAGE_NAME RETURN VARCHAR IS
	BEGIN
     RETURN 'MEX_NYISO_TC';
  END PACKAGE_NAME;

  ----------------------------------------------------------------------
  ----------------  ATC/TTC  -------------------------------------------
  ----------------------------------------------------------------------
  --
  -- parse the CSV file for ATC/TTC into records
  --
  PROCEDURE PARSE_ATC_TTC(p_CSV          IN CLOB,
                          p_RECORDS      OUT MEX_NY_XFER_CAP_SCHEDS_TBL,
                          p_STATUS       OUT NUMBER,
                          p_LOGGER      IN OUT mm_logger_adapter) IS

    vProcedureName VARCHAR2(50) := 'PARSE_ATC_TTC';
    v_LINES      PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS       PARSE_UTIL.STRING_TABLE;
    v_IDX        BINARY_INTEGER;

    v_SCHEDULES              MEX_SCHEDULE_TBL;
    v_CURRENT_NAME           VARCHAR2(64);
    v_CACHED_NAME            VARCHAR2(64) := 'UNDEFINED';
    v_CURRENT_ENTITY_IDX     BINARY_INTEGER := 0;
    v_CURRENT_DATE           DATE;

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_XFER_CAP_SCHEDS_TBL();   -- the ENTITIES

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        IF v_LINES(v_IDX) IS NOT NULL AND v_IDX > 1 THEN
          -- convert to standard time
          v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(REPLACE(v_COLS(2), '"', ''),
		                             MEX_NYISO.g_NYISO_TIME_ZONE,
                                     MEX_NYISO.g_DATE_TIME_FMT);
          v_CURRENT_NAME := trim(both '"' from v_COLS(1));
          IF (v_CURRENT_NAME <> v_CACHED_NAME) THEN -- FIRST TIME FOR THE ENTITY
             p_RECORDS.EXTEND();  -- get a new load zone
             p_RECORDS(p_RECORDS.LAST) := MEX_NY_XFER_CAP_SCHEDS(INTERFACE_NAME => v_CURRENT_NAME,
                                                      TTC_DAM_SCHED => MEX_SCHEDULE_TBL(),
                                                      ATC_DAM_FIRMS_SCHED => MEX_SCHEDULE_TBL(),
                                                      ATC_DAM_TOTAL_SCHED => MEX_SCHEDULE_TBL(),
                                                      TTC_HAM_SCHED => MEX_SCHEDULE_TBL(),
                                                      ATC_HAM_FIRMS_SCHED => MEX_SCHEDULE_TBL(),
                                                      ATC_HAM_TOTAL_SCHED => MEX_SCHEDULE_TBL());
             -- cache the name and entity index
             v_CURRENT_ENTITY_IDX := v_CURRENT_ENTITY_IDX + 1;
             v_CACHED_NAME := v_CURRENT_NAME;
          END IF;
          -- ENTITY ALREADY EXISTS
          -- UPDATE EACH ATTRIBUTE (A MEX_SCHEDULE)
            -- TTC_DAM_SCHED
            v_SCHEDULES := p_RECORDS(v_CURRENT_ENTITY_IDX).TTC_DAM_SCHED;
            p_RECORDS(v_CURRENT_ENTITY_IDX).TTC_DAM_SCHED.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_IDX).TTC_DAM_SCHED(p_RECORDS(v_CURRENT_ENTITY_IDX).TTC_DAM_SCHED.LAST) :=
                MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                VOLUME => to_number(v_COLS(3)),
                RATE => NULL);

            -- ATC_DAM_FIRMS_SCHED
            p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_DAM_FIRMS_SCHED.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_DAM_FIRMS_SCHED(p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_DAM_FIRMS_SCHED.LAST) :=
                MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                VOLUME => to_number(v_COLS(4)),
                RATE => NULL);

            -- ATC_DAM_TOTAL_SCHED
            p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_DAM_TOTAL_SCHED.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_DAM_TOTAL_SCHED(p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_DAM_TOTAL_SCHED.LAST) :=
                MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                VOLUME => to_number(v_COLS(5)),
                RATE => NULL);

            -- TTC_HAM_SCHED
            p_RECORDS(v_CURRENT_ENTITY_IDX).TTC_HAM_SCHED.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_IDX).TTC_HAM_SCHED(p_RECORDS(v_CURRENT_ENTITY_IDX).TTC_HAM_SCHED.LAST) :=
                MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                VOLUME => to_number(v_COLS(6)),
                RATE => NULL);

            -- ATC_HAM_FIRMS_SCHED
			p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_HAM_FIRMS_SCHED.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_HAM_FIRMS_SCHED(p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_HAM_FIRMS_SCHED.LAST) :=
                MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                VOLUME => to_number(v_COLS(7)),
                RATE => NULL);

            -- ATC_HAM_TOTAL_SCHED
			p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_HAM_TOTAL_SCHED.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_HAM_TOTAL_SCHED(p_RECORDS(v_CURRENT_ENTITY_IDX).ATC_HAM_TOTAL_SCHED.LAST) :=
                MEX_SCHEDULE(CUT_TIME => v_CURRENT_DATE,
                VOLUME => to_number(v_COLS(8)),
                RATE => NULL);

        END IF;  -- there is data to parse
        v_IDX := v_LINES.NEXT(v_IDX);
      END LOOP;

/*	  for i in p_RECORDS.FIRST .. p_RECORDS.LAST
	  loop
	  dbms_output.put_line(p_RECORDS(i).INTERFACE_NAME ||
	   ', ttc_dam_sched count(' || to_char(i) || ')=' || to_char(p_RECORDS(i).TTC_DAM_SCHED.count()) ||
	   ', ttc_dam_firms_sched count(' || to_char(i) || ')=' || to_char(p_RECORDS(i).ATC_DAM_FIRMS_SCHED.count()) ||
	   ', ttc_dam_total_sched count(' || to_char(i) || ')=' || to_char(p_RECORDS(i).ATC_DAM_TOTAL_SCHED.count()) ||
	   ', ttc_ham_sched count(' || to_char(i) || ')=' || to_char(p_RECORDS(i).TTC_HAM_SCHED.count()) ||
	   ', ttc_ham_firms_sched count(' || to_char(i) || ')=' || to_char(p_RECORDS(i).ATC_HAM_FIRMS_SCHED.count()) ||
	   ', ttc_ham_total_sched count(' || to_char(i) || ')=' || to_char(p_RECORDS(i).ATC_HAM_TOTAL_SCHED.count())
	   );
	  end loop;*/

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.PARSE_ATC_TTC: ' || SQLERRM);
  END PARSE_ATC_TTC;

  ----------------------------------------------------------------------
  --
  -- Fetch the CSV file for ATC/TTC and map into records for MM import. The ACTION
  --   parameter dictates what type of ATC/TTC.  Use the constanst referenced below
  --   to acquire the desired data:
  --
  -- g_ATC_TTC - 'ATC TTC';
  --
  PROCEDURE FETCH_ATC_TTC
  (
      p_DATE    IN DATE,
      p_ACTION  IN VARCHAR2,
      p_RECORDS OUT MEX_NY_XFER_CAP_SCHEDS_TBL,
      p_STATUS  OUT NUMBER,
      p_LOGGER  IN OUT MM_LOGGER_ADAPTER
  ) IS
  
  
      v_REQUEST_URL VARCHAR2(255);
      v_CLOB_RESP    CLOB;
      v_RESULT      MEX_RESULT;
  BEGIN
      p_STATUS := MEX_UTIL.g_SUCCESS;
  
      -- build the url needed. The action and date controls the resulting URL
      MEX_NYISO.BUILD_PUBLIC_URL(p_DATE, FALSE, p_ACTION, v_REQUEST_URL, p_STATUS, p_LOGGER);
  
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
          PARSE_ATC_TTC(v_CLOB_RESP, p_RECORDS, p_STATUS, p_LOGGER);
      END IF;
  END FETCH_ATC_TTC;
  ----------------------------------------------------------------------



END MEX_NYISO_TC;
/
