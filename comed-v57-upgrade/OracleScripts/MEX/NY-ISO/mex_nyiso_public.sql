CREATE OR REPLACE PACKAGE MEX_NYISO_PUBLIC IS

--
-- file: MEX_NYISO_PUBLIC.SQL
--
-- contains behavior needed to access public access data managed by nyiso
--

  TYPE PARAMETER_MAP IS TABLE OF VARCHAR2(512) INDEX BY VARCHAR2(512);
  
  --
  -- LBMP constants
  -- Use these constants to request the desired type of fetch for LBMP
  g_DA_LBMP_ZONAL CONSTANT VARCHAR2(64) := 'ZONAL DAY AHEAD LBMP';
  g_DA_LBMP_GEN   CONSTANT VARCHAR2(64) := 'GENERATOR DAY AHEAD LBMP';
  g_DA_LBMP_BUS   CONSTANT VARCHAR2(64) := 'REFERENCE BUS DAY AHEAD LBMP';  
  -- INTEGRATED REAL-TIME (IRT)
  g_INTEGRATED_RT_LBMP_ZONAL CONSTANT VARCHAR2(64) := 'ZONAL INTEGRATED REAL TIME LBMP';
  g_INTEGRATED_RT_LBMP_GEN   CONSTANT VARCHAR2(64) := 'GENERATOR INTEGRATED REAL TIME LBMP';
  g_INTEGRATED_RT_LBMP_BUS CONSTANT VARCHAR2(64) := 'REFERENCE BUS INTEGRATED REAL TIME LBMP';
  -- BALANCING HOUR AHEAD (BHA)
  g_BHA_LBMP_ZONAL CONSTANT VARCHAR2(64) := 'ZONAL BALANCING HOUR AHEAD LBMP';
  g_BHA_LBMP_GEN   CONSTANT VARCHAR2(64) := 'GENERATOR BALANCING HOUR AHEAD LBMP';
  g_BHA_LBMP_BUS CONSTANT VARCHAR2(64) := 'REFERENCE BUS BALANCING HOUR AHEAD LBMP';
  
  --
  -- load constants
  -- Use these constants to request the desired type of fetch for Load
  g_ISO_LOAD CONSTANT VARCHAR2(64) := 'ISO LOAD';
  g_RT_ACTUAL_LOAD CONSTANT VARCHAR2(64) := 'REAL TIME LOAD';
  g_INTEGRATED_RT_ACTUAL_LOAD CONSTANT VARCHAR2(64) := 'INTEGRATED REAL TIME LOAD';
  --
  -- load constants
  -- Use these constants to request the desired type of fetch for Load
  g_ATC_TTC CONSTANT VARCHAR2(64) := 'ATC TTC';
  
  

  -----------------------------------------------------------------------------
  -- LOAD REQUESTS
  -----------------------------------------------------------------------------
  --
  -- Fetch the CSV file for LOAD  and map into records for MM import.  The ACTION 
  --   parameter dictates what type of LOAD.  Use the constants referenced below
  --   to acquire the desired data:
  -- 
  -- g_ISO_LOAD                  - 'ISO LOAD';
  -- g_RT_ACTUAL_LOAD            - 'REAL TIME LOAD';
  -- g_INTEGRATED_RT_ACTUAL_LOAD - 'INTEGRATED REAL TIME LOAD';
  --
  PROCEDURE FETCH_LOAD(p_DATE     IN DATE,
                           p_ACTION   IN VARCHAR2,
                           p_RECORDS  OUT MEX_NY_LOAD_TBL,
                           p_STATUS   OUT NUMBER,
                           p_MESSAGE  OUT VARCHAR2);
                           
 
  -----------------------------------------------------------------------------
  -- LBMP REQUESTS
  -----------------------------------------------------------------------------
  
  --
  -- Fetch the CSV file for LBMP  and map into records for MM import.  The ACTION 
  --   parameter dictates what type of LBMP.  Use the constanst referenced below
  --   to acquire the desired data:
  -- Day Ahead
  --   g_DA_LBMP_ZONAL - 'ZONAL DAY AHEAD LBMP'
  --   g_DA_LBMP_GEN   - 'GENERATOR DAY AHEAD LBMP'
  --   g_DA_LBMP_BUS   - 'REFERENCE BUS DAY AHEAD LBMP'
  -- Integrated Real Time
  --   g_INTEGRATED_RT_LBMP_ZONAL - 'ZONAL INTEGRATED REAL TIME LBMP';
  --   g_INTEGRATED_RT_LBMP_GEN   - 'GENERATOR INTEGRATED REAL TIME LBMP';
  --   g_INTEGRATED_RT_LBMP_BUS   - 'REFERENCE BUS INTEGRATED REAL TIME LBMP';
  -- Balancing Hour Ahead (BHA)
  --   g_BHA_LBMP_ZONAL   - 'ZONAL BALANCING HOUR AHEAD LBMP';
  --   g_BHA_LBMP_GEN  - 'GENERATOR BALANCING HOUR AHEAD LBMP';
  --   g_BHA_LBMP_BUS  - 'REFERENCE BUS BALANCING HOUR AHEAD LBMP';
  
  PROCEDURE FETCH_LBMP(p_DATE     IN  DATE,
                          p_ACTION   IN VARCHAR2,
                          p_RECORDS  OUT MEX_NY_LBMP_TBL,
                          p_STATUS   OUT NUMBER,
                          p_MESSAGE  OUT VARCHAR2);
                          
  -----------------------------------------------------------------------------
  -- ATC/TTC REQUESTS
  -----------------------------------------------------------------------------
  --
  -- Fetch the CSV file for ATC/TTC and map into records for MM import. The ACTION 
  --   parameter dictates what type of ATC/TTC.  Use the constanst referenced below
  --   to acquire the desired data:
  --
  -- g_ATC_TTC - 'ATC TTC';
  
  PROCEDURE FETCH_ATC_TTC(p_DATE     IN DATE,
                          p_ACTION   IN VARCHAR2,
                          p_RECORDS  OUT MEX_NY_XFER_CAP_SCHEDS_TBL,
                          p_STATUS   OUT NUMBER,
                          p_MESSAGE  OUT VARCHAR2);                          
                           

END MEX_NYISO_PUBLIC;
/
CREATE OR REPLACE PACKAGE BODY MEX_NYISO_PUBLIC IS

-- CONSTANTS ---
vPackageName CONSTANT VARCHAR2(50) := 'MEX_NYISO_PUBLIC';

	---------------------------------------------------------------------------------------------------
  -- utility logic
	---------------------------------------------------------------------------------------------------

	---------------------------------------------------------------------------------------------------
  -- answer a cut date from a string based on a date format, time zone, and source string
  --
  FUNCTION TO_CUT_FROM_STRING
  	(
  	p_DATE        VARCHAR2,
  	p_TIME_ZONE   VARCHAR2,
    p_DATE_FORMAT VARCHAR2
  	)
  	RETURN DATE IS

  v_DATE DATE;
  v_TIME_ZONE CHAR(3);
  
  BEGIN
  
  	v_TIME_ZONE := UPPER(p_TIME_ZONE);
  
  --c If a DST time zone that is not not currently in the DST period then make it standard time
  
  	v_DATE := TO_DATE(p_DATE, p_DATE_FORMAT);
    v_Date := TO_CUT(v_DATE, v_TIME_ZONE);
  
  	RETURN v_DATE;
  
  END TO_CUT_FROM_STRING;

	----------------------------------------------------------------------------------------------------
  -- submit a request to get the CSV file from the public source
  --
	PROCEDURE SUBMIT_PUBLIC_REQUEST(p_MEX_DISPATCH_URL IN VARCHAR2,
                                  p_CLOB_RESPONSE    OUT CLOB,
                                  p_STATUS           OUT NUMBER,
                                  p_MESSAGE          OUT VARCHAR2) AS
    vProcedureName VARCHAR2(50) := 'SUBMIT_PUBLIC_REQUEST';
    v_EXCHANGE_ID  NUMBER;
	BEGIN

		p_STATUS := MEX_UTIL.g_SUCCESS;
    
		MEX_NYISO.PUT_EXCHANGE_LOG(MEX_NYISO.g_NYISO_QUERY_TYPE, -- direction
                               'PUBLIC', -- type
                               'PENDING', -- status
                               p_MESSAGE, -- error
                               NULL, -- external id
                               NULL, -- reference id
                               NULL, -- request
                               NULL, -- response
                               'txt',  -- response extention
                               v_EXCHANGE_ID);     

		DBMS_LOB.CREATETEMPORARY(p_CLOB_RESPONSE, TRUE);

    MEX_HTTP.SEND_REQUEST(
    	p_URL => p_MEX_DISPATCH_URL,
    	p_CONTENT_TYPE => 'text/html',
    	p_REQUEST_TEXT => NULL,
    	p_RESPONSE_TEXT => p_CLOB_RESPONSE,
    	p_ERROR_MESSAGE => p_MESSAGE,
      p_HTTP_VER => NULL,
      p_USERNAME => '',
      p_PASSWORD => '');

		IF NOT p_MESSAGE IS NULL THEN
			p_STATUS := -1;
		ELSIF DBMS_LOB.GETLENGTH(p_CLOB_RESPONSE) = 0 THEN
			p_STATUS  := -1;
			p_MESSAGE := 'NYISO Public Interface: Request generated Empty Response!';
		END IF;

    --LOG THE REQUEST AND THE RESPONSE.
    MEX_UTIL.PUT_EXCHANGE_DETAILS(v_EXCHANGE_ID,
                                  MEX_NYISO.g_INTERFACE_SN,
                                  NULL,   -- request
                                  NULL,   -- extension
                                  p_CLOB_RESPONSE,
                                  'txt');
    COMMIT;  -- THE LOG DETAILS

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
	END SUBMIT_PUBLIC_REQUEST;

	----------------------------------------------------------------------------------------------------
  -- based on the action and date provided, build a proper URL used to access the public NYISO site
  --
    PROCEDURE BUILD_PUBLIC_URL(p_DATE         IN DATE,
                           p_REQUEST_TYPE     IN VARCHAR2,
                           v_REQUEST_URL      OUT VARCHAR2,
                           p_STATUS           OUT NUMBER,
                           p_MESSAGE          OUT VARCHAR2) IS
    vProcedureName VARCHAR2(50) := 'BUILD_PUBLIC_URL';
    v_FILENAME  VARCHAR2(255);
    v_DATE_STRING  VARCHAR2(12);
    v_BASE_URL  VARCHAR2(40) := 'http://mis.nyiso.com/public/csv/';
  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMMDD');
-- LOAD    
    IF UPPER(p_REQUEST_TYPE) = g_ISO_LOAD THEN   -- ISO LOAD
      v_FILENAME := 'isolf/' || v_DATE_STRING || 'isolf.csv';  
    ELSIF UPPER(p_REQUEST_TYPE) = g_RT_ACTUAL_LOAD THEN   -- REAL TIME ACTUAL
      v_FILENAME := 'pal/' || v_DATE_STRING || 'pal.csv'; 
    ELSIF UPPER(p_REQUEST_TYPE) = g_INTEGRATED_RT_ACTUAL_LOAD THEN -- INTEGRATED RTA
      v_FILENAME := 'palIntegrated/' || v_DATE_STRING || 'palIntegrated.csv';
-- DAY AHEAD LBMP      
    ELSIF UPPER(p_REQUEST_TYPE) = g_DA_LBMP_ZONAL THEN -- zonal
      v_FILENAME := 'damlbmp/' || v_DATE_STRING || 'damlbmp_zone.csv';
    ELSIF UPPER(p_REQUEST_TYPE) = g_DA_LBMP_GEN THEN -- generator
      v_FILENAME := 'damlbmp/' || v_DATE_STRING || 'damlbmp_gen.csv';
    ELSIF UPPER(p_REQUEST_TYPE) = g_DA_LBMP_BUS THEN -- REFERENCE BUS
      v_FILENAME := 'refbus/' || v_DATE_STRING || 'damlbmp_gen_refbus.csv';    
-- INTEGRATED REAL TIME LBMP      
    ELSIF UPPER(p_REQUEST_TYPE) = g_INTEGRATED_RT_LBMP_ZONAL THEN -- zonal
      v_FILENAME := 'rtlbmp/' || v_DATE_STRING || 'rtlbmp_zone.csv';
    ELSIF UPPER(p_REQUEST_TYPE) = g_INTEGRATED_RT_LBMP_GEN THEN -- generator
      v_FILENAME := 'rtlbmp/' || v_DATE_STRING || 'rtlbmp_gen.csv';
    ELSIF UPPER(p_REQUEST_TYPE) = g_INTEGRATED_RT_LBMP_BUS THEN -- REFERENCE BUS
      v_FILENAME := 'refbus/' || v_DATE_STRING || 'rtlbmp_gen_refbus.csv';  
-- Balancing Hour Ahead (BHA) LBMP
    ELSIF UPPER(p_REQUEST_TYPE) = g_BHA_LBMP_ZONAL THEN -- zonal
      v_FILENAME := 'hamlbmp/' || v_DATE_STRING || 'hamlbmp_zone.csv';
    ELSIF UPPER(p_REQUEST_TYPE) = g_BHA_LBMP_GEN THEN -- generator
      v_FILENAME := 'hamlbmp/' || v_DATE_STRING || 'hamlbmp_gen.csv';
    ELSIF UPPER(p_REQUEST_TYPE) = g_BHA_LBMP_BUS THEN -- REFERENCE BUS
      v_FILENAME := 'refbus/' || v_DATE_STRING || 'hamlbmp_gen_refbus.csv';  
-- ATC/TTC
    ELSIF UPPER(p_REQUEST_TYPE) = g_ATC_TTC THEN
      v_FILENAME := 'atc_ttc/' || v_DATE_STRING || 'atc_ttc.csv';        
    ELSE
      v_FILENAME := 'INVALID_ACTION';
    END IF;

    v_REQUEST_URL := v_BASE_URL || v_FILENAME;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END BUILD_PUBLIC_URL;

	----------------------------------------------------------------------------------------
  -- NYISO LOGIC FOR PUBLIC ACCESS DATA
	----------------------------------------------------------------------------------------

  -----------------------------------------------------------
	---------------- ISO Load Forecast ------------------------
  -----------------------------------------------------------
  --
  -- parse the CSV file for ISO Load Forecast into records
  --
  PROCEDURE PARSE_ISO_LOAD(p_CSV          IN CLOB,
                           p_RECORDS      OUT MEX_NY_LOAD_TBL,
                           p_STATUS       OUT NUMBER,
                           p_MESSAGE      OUT VARCHAR2) IS

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
    -- todo: do CUT / DST math here
            v_CURRENT_DATE := TO_DATE(REPLACE(v_COLS(1), '"', ''),
                                     'MM/DD/YYYY HH24:MI:SS');
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
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END PARSE_ISO_LOAD;


  ----------------------------------------------------------------------
	---------------- Integrated Real Time Actual (RTA) Load --------------
  ----------------------------------------------------------------------
  --
  -- parse the CSV file for RTA load into records.  Also works for 
  --    Integrated RTA load
  --
  PROCEDURE PARSE_RTA_LOAD(p_CSV         IN CLOB,
                           p_RECORDS     OUT MEX_NY_LOAD_TBL,
                           p_STATUS      OUT NUMBER,
                           p_MESSAGE     OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'PARSE_RTA_LOAD';

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
    v_OBJS_SEEN BINARY_INTEGER := 0;

    v_LOAD_VALS MEX_SCHEDULE_TBL;
    v_CURRENT_LOAD_ZONE_INDX BINARY_INTEGER;
    v_CURRENT_TIMEZONE VARCHAR2(4);
    v_CURRENT_DATE DATE;
    v_INDEX_MAP MEX_NYISO_PUBLIC.PARAMETER_MAP;


  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;
  -- copied from mex_pjm_esched.PARSE_RECON_DATA()
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_LOAD_TBL();   -- the load zones

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        -- skip the 1st line as it has column headers
        --    "Time Stamp","Time Zone","Name","PTID","Integrated Load"
        IF v_IDX >= 2 AND v_LINES(v_IDX) IS NOT NULL THEN
  -- todo: do CUT / DST math here
            v_CURRENT_TIMEZONE := trim(both '"' from v_COLS(2));
            v_CURRENT_DATE := TO_DATE(REPLACE(v_COLS(1), '"', ''),
                                     'MM/DD/YYYY HH24:MI:SS');
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
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
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
                       p_MESSAGE  OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'FETCH_LOAD';
    v_REQUEST_URL VARCHAR2(255);
    v_CSV_CLOB CLOB;
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;

    -- build the url needed. The action and date controls the resulting URL
    BUILD_PUBLIC_URL(p_DATE, p_ACTION, v_REQUEST_URL, p_STATUS, p_MESSAGE);

    -- acquire the CSV file
    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
      SUBMIT_PUBLIC_REQUEST(v_REQUEST_URL,
                       v_CSV_CLOB,
                       p_STATUS,
                       p_MESSAGE);
    END IF;

    -- parse the response into records
    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN 
       IF (INSTR(UPPER(p_ACTION), 'REAL TIME') > 0) THEN -- IF READING INTEGRATED LOAD
          PARSE_RTA_LOAD(v_CSV_CLOB,
                        p_RECORDS,
                        p_STATUS,
                        p_MESSAGE);
       ELSE  -- PARSE ISO LOAD DATA
          PARSE_ISO_LOAD(v_CSV_CLOB,
                        p_RECORDS,
                        p_STATUS,
                        p_MESSAGE);       
       END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END FETCH_LOAD;

	----------------------------------------------------------------------------------------------------
  
  ----------------------------------------------------------------------
	----------------  LBMP  -------------------------------
  ----------------------------------------------------------------------
  --
  -- parse the CSV file for LBMP into records.  This routine supports reading both
  --    Day Ahead and Real-time Integrated LBMP
  --
  PROCEDURE PARSE_LBMP(p_CSV      IN CLOB,
                          p_ACTION   IN VARCHAR2,
                          p_RECORDS  OUT MEX_NY_LBMP_TBL,
                          p_STATUS   OUT NUMBER,
                          p_MESSAGE  OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'PARSE_LBMP';

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

    v_CURRENT_ENTITY_INDX   BINARY_INTEGER;
    v_CURRENT_DATE          DATE;
    v_CURRENT_NAME          VARCHAR2(32);
    v_INDEX_MAP             MEX_NYISO_PUBLIC.PARAMETER_MAP;
    v_IS_INTEGRATED_LBMP    BOOLEAN;
    v_SCARCITY_FLAG         CHAR(1) := NULL;

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_LBMP_TBL();   -- the LBMP records
    -- DETERMINE IF READING INTEGRATED LBMP
    v_IS_INTEGRATED_LBMP := INSTR(UPPER(p_ACTION), 'INTEGRATED') > 0;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        -- skip the 1st line as it has column headers
        --   "Time Stamp","Name","PTID","LBMP ($/MWHr)",
        --   "Marginal Cost Losses ($/MWHr)","Marginal Cost Congestion ($/MWH"

        IF v_IDX >= 2 AND v_LINES(v_IDX) IS NOT NULL THEN
  -- todo: do CUT / DST math here
            v_CURRENT_DATE := TO_DATE(REPLACE(v_COLS(1), '"', ''),
                                     'MM/DD/YYYY HH24:MI');
            v_CURRENT_NAME := trim(both '"' from v_COLS(2));
            -- IF READING INTEGRATED LBMP, GRAB THE EXTRA FIELD, ELSE IT IS ALREADY NULL                         
            IF v_IS_INTEGRATED_LBMP THEN
              v_SCARCITY_FLAG := trim(both '"' from v_COLS(7));
            END IF;
            -- if this is the first time the ENTITY has been seen:
            --   create a new one
            IF (NOT v_INDEX_MAP.EXISTS(v_CURRENT_NAME)) THEN
			   -- begin the next entity record, with an empty COSTS table
               p_RECORDS.EXTEND();  -- get a new LBMP record.
               p_RECORDS(p_RECORDS.LAST) :=  MEX_NY_LBMP(ENTITY_NAME => trim(both '"' from v_COLS(2)),
                                                         ENTITY_ID => trim(both '"' from v_COLS(3)),
                                                         COSTS => MEX_NY_LBMP_COST_TBL());
               -- cache the ENTITY name and its index here.
               v_INDEX_MAP(v_CURRENT_NAME) := to_char(v_IDX - 1);
            END IF;
			
            -- lookup the cached index based on the ENTITY name
            v_CURRENT_ENTITY_INDX := to_number(v_INDEX_MAP(v_CURRENT_NAME));
			
			p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS(p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS.LAST) :=
                MEX_NY_LBMP_COST(CUT_TIME => v_CURRENT_DATE,
                LBMP_COST => to_number(v_COLS(4)),
                MC_LOSSES => to_number(v_COLS(5)),
                MC_CONGESTION => to_number(v_COLS(6)),
                SCARCITY_FLAG => v_SCARCITY_FLAG);
			
        END IF;  -- IF NOT THE 1ST RECORD
        v_IDX := v_LINES.NEXT(v_IDX);
      END LOOP;
	  
/*	  for i in p_RECORDS.FIRST .. p_RECORDS.LAST
	  loop
	  dbms_output.put_line(p_RECORDS(i).ENTITY_NAME || ', costs count(' || to_char(i) || ')=' || 
	               to_char(p_RECORDS(i).COSTS.count()) || 
				   ', ' || to_char(p_RECORDS(i).ENTITY_ID));   
	  end loop;*/
	  
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END PARSE_LBMP;

	----------------------------------------------------------------------------------------------------
  --
  -- parse the CSV file for LBMP for a Reference Bus into records.
  --
  PROCEDURE PARSE_REFERENCE_BUS_LBMP(p_CSV      IN CLOB,
                                     p_ACTION   IN VARCHAR2,
                                     p_RECORDS  OUT MEX_NY_LBMP_TBL,
                                     p_STATUS   OUT NUMBER,
                                     p_MESSAGE  OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'PARSE_REFERENCE_BUS_LBMP';

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

    v_CURRENT_ENTITY_INDX   BINARY_INTEGER := 1;
    v_CURRENT_DATE          DATE;
    v_IS_INTEGRATED_LBMP    BOOLEAN;
    v_SCARCITY_FLAG         CHAR(1) := NULL;
    

  BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_LBMP_TBL();   -- the LBMP records
    -- DETERMINE IF READING INTEGRATED LBMP
    v_IS_INTEGRATED_LBMP := INSTR(UPPER(p_ACTION), 'INTEGRATED') > 0;
    

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        -- "08/19/2005 00:00","NYISO_LBMP_REFERENCE",24008,58.82,0,0

        IF v_LINES(v_IDX) IS NOT NULL THEN
  -- todo: do CUT / DST math here
            v_CURRENT_DATE := TO_DATE(REPLACE(v_COLS(1), '"', ''),
                                     'MM/DD/YYYY HH24:MI');
            -- IF READING INTEGRATED LBMP, GRAB THE EXTRA FIELD, ELSE IT IS ALREADY NULL                         
            IF v_IS_INTEGRATED_LBMP THEN
              v_SCARCITY_FLAG := trim(both '"' from v_COLS(7));
            END IF;
            --   create a new ENTITY and initialize the COST table
            IF (v_IDX = 1) THEN 
               p_RECORDS.EXTEND();  -- get a new LBMP record
               p_RECORDS(p_RECORDS.LAST) :=  MEX_NY_LBMP(ENTITY_NAME => trim(both '"' from v_COLS(2)),
                                                         ENTITY_ID => trim(both '"' from v_COLS(3)),
                                                         COSTS => MEX_NY_LBMP_COST_TBL());
            END IF; 
			
			p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS.EXTEND;
			p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS(p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS.LAST) :=
            	MEX_NY_LBMP_COST(CUT_TIME => v_CURRENT_DATE,
                	LBMP_COST => to_number(v_COLS(4)),
                	MC_LOSSES => to_number(v_COLS(5)),
                	MC_CONGESTION => to_number(v_COLS(6)),
                    SCARCITY_FLAG => v_SCARCITY_FLAG);
					

        END IF;  -- IF NOT THE 1ST RECORD
        v_IDX := v_LINES.NEXT(v_IDX);
      END LOOP;
	  
/*	  for i in p_RECORDS.FIRST .. p_RECORDS.LAST
	  loop
	  dbms_output.put_line(p_RECORDS(i).ENTITY_NAME || ', costs count(' || to_char(i) || ')=' || 
	               to_char(p_RECORDS(i).COSTS.count()) || 
				   ', ' || to_char(p_RECORDS(i).ENTITY_ID));   
	  end loop;*/
	  
  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END PARSE_REFERENCE_BUS_LBMP;

	----------------------------------------------------------------------------------------------------

  --
  -- Fetch the CSV file for LBMP  and map into records for MM import.  The ACTION 
  --   parameter dictates what type of LBMP.  Use the constanst referenced below
  --   to acquire the desired data:
  -- Day Ahead
  --   g_DA_LBMP_ZONAL - 'ZONAL DAY AHEAD LBMP'
  --   g_DA_LBMP_GEN   - 'GENERATOR DAY AHEAD LBMP'
  --   g_DA_LBMP_BUS   - 'REFERENCE BUS DAY AHEAD LBMP'
  -- Integrated Real Time
  --   g_INTEGRATED_RT_LBMP_ZONAL - 'ZONAL INTEGRATED REAL TIME LBMP';
  --   g_INTEGRATED_RT_LBMP_GEN   - 'GENERATOR INTEGRATED REAL TIME LBMP';
  --   g_INTEGRATED_RT_LBMP_BUS   - 'REFERENCE BUS INTEGRATED REAL TIME LBMP';
  -- Balancing Hour Ahead (BHA)
  --   g_BHA_LBMP_ZONAL   - 'ZONAL BALANCING HOUR AHEAD LBMP';
  --   g_BHA_LBMP_GEN  - 'GENERATOR BALANCING HOUR AHEAD LBMP';
  --   g_BHA_LBMP_BUS  - 'REFERENCE BUS BALANCING HOUR AHEAD LBMP';
  
  --
  PROCEDURE FETCH_LBMP(p_DATE     IN  DATE,
                          p_ACTION   IN VARCHAR2,
                          p_RECORDS  OUT MEX_NY_LBMP_TBL,
                          p_STATUS   OUT NUMBER,
                          p_MESSAGE  OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'FETCH_LBMP';
    v_REQUEST_URL VARCHAR2(255);
    v_CSV_CLOB CLOB;
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;

    -- build the url needed. The action and date controls the resulting URL
    BUILD_PUBLIC_URL(p_DATE, p_ACTION, v_REQUEST_URL, p_STATUS, p_MESSAGE);

    -- acquire the CSV file
    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
      SUBMIT_PUBLIC_REQUEST(v_REQUEST_URL,
                       v_CSV_CLOB,
                       p_STATUS,
                       p_MESSAGE);
    END IF;

    -- parse the response into records
    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN 
       IF (INSTR(UPPER(p_ACTION), 'REFERENCE BUS') > 0) THEN -- IF READING REFERENCE BUS DATA
          PARSE_REFERENCE_BUS_LBMP(v_CSV_CLOB,
                        p_ACTION,
                        p_RECORDS,
                        p_STATUS,
                        p_MESSAGE);
       ELSE  -- PARSE NORMAL LBMP DATA 
          PARSE_LBMP(v_CSV_CLOB,
                        p_ACTION,
                        p_RECORDS,
                        p_STATUS,
                        p_MESSAGE);       
       END IF;
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END FETCH_LBMP;
  ----------------------------------------------------------------------
	----------------  ATC/TTC  -------------------------------------------
  ----------------------------------------------------------------------
  
  --
  -- parse the CSV file for ATC/TTC into records
  --
  PROCEDURE PARSE_ATC_TTC(p_CSV          IN CLOB,
                          p_RECORDS      OUT MEX_NY_XFER_CAP_SCHEDS_TBL,
                          p_STATUS       OUT NUMBER,
                          p_MESSAGE      OUT VARCHAR2) IS

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
    -- todo: do CUT / DST math here
          v_CURRENT_DATE := TO_DATE(REPLACE(v_COLS(2), '"', ''),
                                     'MM/DD/YYYY HH24:MI');
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
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END PARSE_ATC_TTC;

  ----------------------------------------------------------------------
  --
  -- Fetch the CSV file for ATC/TTC and map into records for MM import. The ACTION 
  --   parameter dictates what type of ATC/TTC.  Use the constanst referenced below
  --   to acquire the desired data:
  --
  -- g_ATC_TTC - 'ATC TTC';
  --
  PROCEDURE FETCH_ATC_TTC(p_DATE     IN DATE,
                          p_ACTION   IN VARCHAR2,
                          p_RECORDS  OUT MEX_NY_XFER_CAP_SCHEDS_TBL,
                          p_STATUS   OUT NUMBER,
                          p_MESSAGE  OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'FETCH_ATC_TTC';
    v_REQUEST_URL VARCHAR2(255);
    v_CSV_CLOB CLOB;
  BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;

    -- build the url needed. The action and date controls the resulting URL
    BUILD_PUBLIC_URL(p_DATE, p_ACTION, v_REQUEST_URL, p_STATUS, p_MESSAGE);

    -- acquire the CSV file
    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
      SUBMIT_PUBLIC_REQUEST(v_REQUEST_URL,
                       v_CSV_CLOB,
                       p_STATUS,
                       p_MESSAGE);
    END IF;

    -- parse the response into records
    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN 
       PARSE_ATC_TTC(v_CSV_CLOB,
                        p_RECORDS,
                        p_STATUS,
                        p_MESSAGE);
    END IF;

  EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || ':' || vProcedureName || ': ' || SQLERRM;
  END FETCH_ATC_TTC;                        
  ----------------------------------------------------------------------

END MEX_NYISO_PUBLIC;
/
