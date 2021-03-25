CREATE OR REPLACE PACKAGE BODY MEX_NYISO_LBMP IS
  
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
  FUNCTION PACKAGE_NAME RETURN VARCHAR IS
	BEGIN
     RETURN 'MEX_NYISO_LBMP';
  END PACKAGE_NAME;
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
						  p_STATUS	OUT NUMBER,
                          p_LOGGER IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

    v_CURRENT_ENTITY_INDX   BINARY_INTEGER;
    v_CURRENT_DATE          DATE;
    v_CURRENT_NAME          VARCHAR2(32);
    v_INDEX_MAP             MEX_NYISO.PARAMETER_MAP;
    v_IS_INTEGRATED_LBMP    BOOLEAN;
	v_MINUTES_ADJ           NUMBER;
    v_SCARCITY_FLAG         CHAR(1) := NULL;

  BEGIN
  
  	p_STATUS  := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_LBMP_TBL();   -- the LBMP records
    -- DETERMINE IF READING INTEGRATED LBMP
    v_IS_INTEGRATED_LBMP := INSTR(UPPER(p_ACTION), 'INTEGRATED') > 0;

    IF INSTR(UPPER(P_ACTION), 'HOUR AHEAD') > 0 THEN
	  v_MINUTES_ADJ := 0; -- no adjust for 'hour ending'
	ELSE
	  v_MINUTES_ADJ := 60; -- adjust for 'hour beginning'
	END IF;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        -- skip the 1st line as it has column headers
        --   "Time Stamp","Name","PTID","LBMP ($/MWHr)",
        --   "Marginal Cost Losses ($/MWHr)","Marginal Cost Congestion ($/MWH"

        IF v_IDX >= 2 AND v_LINES(v_IDX) IS NOT NULL THEN
			-- convert to standard time
            v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(REPLACE(v_COLS(1), '"', ''),
			                         MEX_NYISO.g_NYISO_TIME_ZONE,
                                     MEX_NYISO.g_DATE_TIME_FMT,
									 v_MINUTES_ADJ);
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

  EXCEPTION
    WHEN OTHERS THEN
	  P_STATUS  := SQLCODE;
      p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.PARSE_LBMP: ' || SQLERRM);
  END PARSE_LBMP;

	----------------------------------------------------------------------------------------------------
  --
  -- parse the CSV file for LBMP for a Reference Bus into records.
  --
  PROCEDURE PARSE_REFERENCE_BUS_LBMP(p_CSV      IN CLOB,
                                     p_ACTION   IN VARCHAR2,
                                     p_RECORDS  OUT MEX_NY_LBMP_TBL,
									 p_STATUS	OUT NUMBER,
									 p_LOGGER 	IN OUT NOCOPY MM_LOGGER_ADAPTER) IS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

    v_CURRENT_ENTITY_INDX   BINARY_INTEGER := 1;
    v_CURRENT_DATE          DATE;
    v_IS_INTEGRATED_LBMP    BOOLEAN;
    v_SCARCITY_FLAG         CHAR(1) := NULL;
	v_MINUTES_ADJ           NUMBER;
 
  BEGIN

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NY_LBMP_TBL();   -- the LBMP records
    -- DETERMINE IF READING INTEGRATED LBMP
    v_IS_INTEGRATED_LBMP := INSTR(UPPER(p_ACTION), 'INTEGRATED') > 0;

    IF INSTR(UPPER(P_ACTION), 'HOUR AHEAD') > 0 THEN
	  v_MINUTES_ADJ := 0; -- no adjust for 'hour ending'
	ELSE
	  v_MINUTES_ADJ := 60; -- adjust for 'hour beginning'
	END IF;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
        -- "08/19/2005 00:00","NYISO_LBMP_REFERENCE",24008,58.82,0,0

        IF v_LINES(v_IDX) IS NOT NULL THEN
            -- convert to standard time
            v_CURRENT_DATE := MEX_NYISO.TO_CUT_FROM_STRING(REPLACE(v_COLS(1), '"', ''),
			                         MEX_NYISO.g_NYISO_TIME_ZONE,
                                     MEX_NYISO.g_DATE_TIME_FMT,
									 v_MINUTES_ADJ);
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

EXCEPTION
    WHEN OTHERS THEN
	  p_STATUS := SQLERRM;
      p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.PARSE_REFERENCE_BUS_LBMP: ' || SQLERRM);

END PARSE_REFERENCE_BUS_LBMP;
---------------------------------------------------------------------------

  -- Fetch the zip file for LBMP. Get the list of files in it.
  -- Get contents in files  and map into records for MM import.
  --  The ACTION parameter dictates what type of LBMP.  Use the constanst referenced below
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


PROCEDURE FETCH_LBMP_MONTHLY_ZIP
(
    p_CURRENT_MONTH IN DATE,
    p_ACTION        IN VARCHAR2,
    p_RESPONSE_CLOB OUT CLOB,
    p_STATUS        OUT NUMBER,
    p_LOGGER        IN OUT mm_logger_adapter
) AS

    v_FETCH_URL VARCHAR2(2000);
    v_RESULT    MEX_RESULT;

BEGIN
    -- Get clob response for each month. This has the zip file
    -- for the month.
    -- Build the url for getting th zip file for the current month in the date range
    MEX_NYISO.BUILD_PUBLIC_URL(p_CURRENT_MONTH,
                               TRUE,
                               p_ACTION,
                               v_FETCH_URL,
                               p_STATUS,
                               p_LOGGER);

    IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
        p_LOGGER.EXCHANGE_NAME := 'NYISO_LBMP: Download';
		v_RESULT               := Mex_Switchboard.FetchURL(v_FETCH_URL,p_LOGGER => p_LOGGER);
    
        p_STATUS := v_RESULT.STATUS_CODE;
        IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
            p_RESPONSE_CLOB := NULL;
        ELSE
            p_RESPONSE_CLOB := v_RESULT.RESPONSE;
        END IF;
    END IF;

END FETCH_LBMP_MONTHLY_ZIP;
------------------------------------------------------------------------------------------------
PROCEDURE FETCH_LBMP_DAILY
(
    P_DATE             IN DATE,
    p_IS_ARCHIVED_FLAG IN BOOLEAN,
    p_ACTION           IN VARCHAR2,
	p_FILE_LIST 		IN STRING_COLLECTION,
    p_LMP_TBL          OUT MEX_NY_LBMP_TBL,
    p_STATUS           OUT NUMBER,
    p_LOGGER           IN OUT MM_LOGGER_ADAPTER
) AS

    v_CLOB_RESP    CLOB;
    v_REQUEST_URL  VARCHAR2(2000);
    v_RESULT       MEX_RESULT;
	v_FILE_NAME    VARCHAR2(4000); 
    NOT_IN_RECENT_FILES EXCEPTION;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    IF (p_IS_ARCHIVED_FLAG = FALSE) THEN
        -- build the url needed. The action and date controls the resulting URL
        MEX_NYISO.BUILD_PUBLIC_URL(p_DATE, FALSE,p_ACTION,v_REQUEST_URL,p_STATUS, p_LOGGER);
    
        -- acquire the CSV file
        IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
            p_LOGGER.EXCHANGE_NAME := p_ACTION;
			p_LOGGER.LOG_DEBUG ('Download ''' || v_REQUEST_URL || ''' file');
            v_RESULT               := Mex_Switchboard.FetchURL(v_REQUEST_URL, p_LOGGER);
        
            p_STATUS := v_RESULT.STATUS_CODE;
            IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
                v_CLOB_RESP := NULL;
            ELSE
                v_CLOB_RESP := v_RESULT.RESPONSE;
            END IF;
        END IF;
    
    ELSE
		IF (p_FILE_LIST.COUNT > 0) THEN
			--Retrieve the file name for the given date
			SELECT COLUMN_VALUE INTO v_FILE_NAME
			FROM TABLE(CAST(p_FILE_LIST AS STRING_COLLECTION))
			WHERE COLUMN_VALUE LIKE '%\' || TO_CHAR(p_DATE, 'YYYYMMDD') || '%';

			--Retrive the file from the server          
            DBMS_LOB.CREATETEMPORARY(v_CLOB_RESP, TRUE);
            p_LOGGER.EXCHANGE_NAME := 'NYISO_LBMP: Fetch File';
            v_RESULT               := Mex_Switchboard.FetchFile(v_FILE_NAME, p_LOGGER);
            p_STATUS               := v_RESULT.STATUS_CODE;
            
			IF v_RESULT.STATUS_CODE <> MEX_Switchboard.c_Status_Success THEN
                v_CLOB_RESP := NULL;
            ELSE
                v_CLOB_RESP := v_RESULT.RESPONSE;
            END IF;
        END IF;
    END IF; -- Archived flag check

    -- parse the response into records
    IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
        IF (INSTR(UPPER(p_ACTION), 'REFERENCE BUS') > 0) THEN
            -- IF READING REFERENCE BUS DATA
            PARSE_REFERENCE_BUS_LBMP(v_CLOB_RESP, p_ACTION, p_LMP_TBL, p_STATUS, p_LOGGER);
        ELSE
            -- PARSE NORMAL LBMP DATA
            PARSE_LBMP(v_CLOB_RESP, p_ACTION, p_LMP_TBL, p_STATUS, p_LOGGER);
        END IF;
    ELSE
		p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.FETCH_LBMP_DAILY: File not found for action ' || p_ACTION || SQLERRM);
    END IF;

END FETCH_LBMP_DAILY;
----------------------------------------------------------------------------------------------
PROCEDURE PARSE_NODE_FILE
(
    p_CSV        IN CLOB,
    p_TABLE_NAME IN VARCHAR2,
    p_RECORDS    IN OUT NOCOPY MEX_NY_PTID_NODE_TBL,
    p_STATUS     OUT NUMBER,
    p_LOGGER     IN OUT NOCOPY MM_LOGGER_ADAPTER
) AS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    p_LOGGER.LOG_INFO('Parse ''' || p_TABLE_NAME || ''' file');

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
    
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
    
        -- skip the first row of titles
        IF v_IDX > 1 AND v_COLS.COUNT = 4 THEN
            p_RECORDS.EXTEND;
            p_RECORDS(p_RECORDS.LAST) := MEX_NY_PTID_NODE(PTID         => v_COLS(2),
                                                          PTID_NAME    => v_COLS(1),
                                                          PTID_TYPE    => UPPER(p_TABLE_NAME),
                                                          ZONE_NAME    => v_COLS(4),
                                                          SUBZONE_NAME => v_COLS(3));
				
        END IF;
    
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
		p_STATUS := SQLCODE;
        p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.PARSE_NODE_FILE: ' || SQLERRM);
END PARSE_NODE_FILE;
----------------------------------------------------------------------------------------------
PROCEDURE FETCH_NODES
(
    p_RECORDS   OUT MEX_NY_PTID_NODE_TBL,
    p_STATUS    OUT NUMBER,
    p_LOGGER    IN OUT NOCOPY MM_LOGGER_ADAPTER
) IS
    v_URL           SYSTEM_DICTIONARY.VALUE%TYPE;
    v_RESPONSE_CLOB CLOB;
    v_RESULT        MEX_RESULT;
    v_FILE_NAME     VARCHAR2(255);
    TYPE ARRAY IS VARRAY(2) OF VARCHAR2(16);
    v_FILES ARRAY := ARRAY('load', 'generator');

BEGIN
    p_RECORDS := MEX_NY_PTID_NODE_TBL();

    FOR idx IN 1 .. v_FILES.COUNT LOOP
    
        v_FILE_NAME     := v_FILES(idx);
        v_RESPONSE_CLOB := NULL;
        v_URL           := MEX_NYISO.g_BASE_URL || v_FILE_NAME || '/' || v_FILE_NAME || '.csv';
    
		p_LOGGER.LOG_INFO ('Download ''' || v_FILES(idx) || '.csv'' file');
        v_RESULT := MEX_SWITCHBOARD.FetchURL(v_URL, p_LOGGER);
    
        p_STATUS := v_RESULT.STATUS_CODE;
        IF v_RESULT.STATUS_CODE <> MEX_SWITCHBOARD.c_Status_Success THEN
            v_RESPONSE_CLOB := NULL;
        ELSE
            v_RESPONSE_CLOB := v_RESULT.RESPONSE;
        END IF;
    
        -- parse the response into records
        IF p_STATUS = MEX_UTIL.g_SUCCESS THEN
            PARSE_NODE_FILE(v_RESPONSE_CLOB, v_FILE_NAME, p_RECORDS, p_STATUS, p_LOGGER);
        ELSE
            p_LOGGER.LOG_ERROR(PACKAGE_NAME || '.FETCH_NODES: Error fetching ' || v_FILE_NAME || ': '|| SQLERRM);
        END IF;
    END LOOP;

END FETCH_NODES;
-------------------------------------------------------------------------------

END MEX_NYISO_LBMP;
/
