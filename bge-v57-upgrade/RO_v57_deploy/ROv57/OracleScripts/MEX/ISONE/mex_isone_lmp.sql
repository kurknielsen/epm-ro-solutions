CREATE OR REPLACE PACKAGE MEX_ISONE_LMP IS

g_BASE_HIST_RPTS_URL      VARCHAR2(40) := 'http://www.iso-ne.com/histRpts/';
g_BASE_HOURLY_DATA_URL    VARCHAR2(100) := 'http://www.iso-ne.com/markets/hrly_data/res/hourlyRES.do';

PROCEDURE FETCH_LMP
(
    p_DATE              IN  DATE,
    p_ACTION            IN VARCHAR2,
    p_CREDENTIALS       IN EXTERNAL_CREDENTIAL_TBL,
    p_RECORDS           OUT MEX_NE_LMP_TBL,
    p_STATUS            OUT NUMBER,
    p_MESSAGE           OUT VARCHAR2
);


PROCEDURE FETCH_RCP
(
    p_DATE              IN  DATE,
    p_ACTION            IN VARCHAR2,
    p_CREDENTIALS       IN EXTERNAL_CREDENTIAL_TBL,
    p_RECORDS           OUT MEX_NE_RCP_COST_TBL,
    p_STATUS            OUT NUMBER,
    p_MESSAGE           OUT VARCHAR2
);

END MEX_ISONE_LMP;
/
CREATE OR REPLACE PACKAGE BODY MEX_ISONE_LMP IS

  -- CONSTANTS ---
  vPackageName CONSTANT VARCHAR2(50) := 'MEX_ISONE_LMP';

  ----------------------------------------------------------------------
  ----------------  LMP  -------------------------------
  ----------------------------------------------------------------------
  --
  -- parse the CSV file for LMP into records.  This routine supports reading both
  --    Day Ahead and Real-time Integrated LMP
  --
PROCEDURE PARSE_LMP(p_CSV      IN CLOB,
                    p_RECORDS  OUT MEX_NE_LMP_TBL,
                    p_STATUS   OUT NUMBER,
                    p_MESSAGE  OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'PARSE_LMP';

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;
	v_DATA_IDX BINARY_INTEGER := 0;

    v_CURRENT_ENTITY_INDX   BINARY_INTEGER;
    v_CURRENT_DATE          DATE;
    v_CURRENT_NAME          VARCHAR2(32);
    v_INDEX_MAP             MEX_ISONE.PARAMETER_MAP;
	v_MINUTES_ADJ           NUMBER;

BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NE_LMP_TBL();   -- the LMP records

	v_MINUTES_ADJ := 0; -- no adjust for 'hour ending'
	--v_MINUTES_ADJ := 60; -- adjust for 'hour beginning'

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
		-- 10 columns per row
		-- Row Type (C,H,D,T), Date, Hour End, Location ID, Location Name, Loation Type, LMP, EC, CC, MLC

        IF v_LINES(v_IDX) IS NOT NULL THEN
			IF REPLACE(v_COLS(1), '"', '') = 'D' THEN -- import data columns only
				v_DATA_IDX := v_DATA_IDX + 1;

    			-- convert to standard time
                v_CURRENT_DATE := MEX_ISONE.TO_CUT_FROM_STRING(REPLACE(v_COLS(2), '"', '') || ' ' || REPLACE(v_COLS(3), '"', ''),
    			                         MEX_ISONE.g_ISONE_TIME_ZONE,
                                         MEX_ISONE.g_DATE_TIME_FMT,
    									 v_MINUTES_ADJ);
                v_CURRENT_NAME := trim(both '"' from v_COLS(5));

                -- if this is the first time the ENTITY has been seen:
                --   create a new one
                IF (NOT v_INDEX_MAP.EXISTS(v_CURRENT_NAME)) THEN
    			   -- begin the next entity record, with an empty COSTS table
                   p_RECORDS.EXTEND();  -- get a new LMP record.
                   p_RECORDS(p_RECORDS.LAST) :=  MEX_NE_LMP(LOCATION_NID => trim(both '"' from v_COLS(4)),
                                                             LOCATION_NAME => trim(both '"' from v_COLS(5)),
    														 LOCATION_TYPE => trim(both '"' from v_COLS(6)),
                                                             COSTS => MEX_NE_LMP_COST_TBL());
                   -- cache the ENTITY name and its index here.
                   v_INDEX_MAP(v_CURRENT_NAME) := to_char(v_DATA_IDX);
                END IF;

                -- lookup the cached index based on the ENTITY name
                v_CURRENT_ENTITY_INDX := to_number(v_INDEX_MAP(v_CURRENT_NAME));

    			p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS.EXTEND;
    			p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS(p_RECORDS(v_CURRENT_ENTITY_INDX).COSTS.LAST) :=
                    MEX_NE_LMP_COST(CUT_DATE => v_CURRENT_DATE,
                    LMP_COST => to_number(v_COLS(7)),
					ENERGY_COST => to_number(v_COLS(8)),
					MC_CONGESTION => to_number(v_COLS(9)),
                    MC_LOSSES => to_number(v_COLS(10))
                    );
			END IF;
        END IF;  -- IF NOT NULL
        v_IDX := v_LINES.NEXT(v_IDX);
      END LOOP;

/*	  for i in p_RECORDS.FIRST .. p_RECORDS.LAST
	  loop
	  dbms_output.put_line(p_RECORDS(i).LOCATION_NAME || ', costs count(' || to_char(i) || ')=' ||
	               to_char(p_RECORDS(i).COSTS.count()) ||
				   ', ' || to_char(p_RECORDS(i).LOCATION_NID));
	  end loop;*/

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || '.' || vProcedureName || ': ' || SQLERRM;
END PARSE_LMP;

----------------------------------------------------------------------------------------------------
	----------------------------------------------------------------------------------------------------
  --
  -- parse the CSV file for Regulation Price into records.
  --
PROCEDURE PARSE_REGULATION(p_CSV      IN CLOB,
                                     p_RECORDS  OUT MEX_NE_RCP_COST_TBL,
                                     p_STATUS   OUT NUMBER,
                                     p_MESSAGE  OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'PARSE_REGULATION';

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

    v_CURRENT_ENTITY_INDX   BINARY_INTEGER := 1;
    v_CURRENT_DATE          DATE;
	v_MINUTES_ADJ           NUMBER;


BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
	v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_NE_RCP_COST_TBL();   -- the LMP records

	v_MINUTES_ADJ := 0; -- no adjust for 'hour ending'
	--v_MINUTES_ADJ := 60; -- adjust for 'hour beginning'

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);

        IF v_LINES(v_IDX) IS NOT NULL THEN
    		IF REPLACE(v_COLS(1), '"', '') = 'D' THEN -- import data columns only
                -- convert to standard time
                v_CURRENT_DATE := MEX_ISONE.TO_CUT_FROM_STRING(REPLACE(v_COLS(2), '"', '') || ' ' ||  REPLACE(v_COLS(3), '"', ''),
    			                         MEX_ISONE.g_ISONE_TIME_ZONE,
                                         MEX_ISONE.g_DATE_TIME_FMT,
    									 v_MINUTES_ADJ);

                   p_RECORDS.EXTEND();  -- get a new LMP record
                   p_RECORDS(p_RECORDS.LAST) :=  MEX_NE_RCP_COST(CUT_DATE => v_CURRENT_DATE,
    			   												 RCP_PRICE => trim(both '"' from v_COLS(4)));

    		END IF;
        END IF;  -- IF NOT NULL
        v_IDX := v_LINES.NEXT(v_IDX);
      END LOOP;

/*	  for i in p_RECORDS.FIRST .. p_RECORDS.LAST
	  loop
	  dbms_output.put_line('RCP costs count=' ||
	               to_char(p_RECORDS.count()));
	  end loop;*/

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || '.' || vProcedureName || ': ' || SQLERRM;
END PARSE_REGULATION;

----------------------------------------------------------------------------------------------------
-- based on the action and date provided, build a proper URL used to access the public ISONE site
--
PROCEDURE BUILD_PUBLIC_URL(p_DATE         IN DATE,
                           p_REQUEST_TYPE     IN VARCHAR2,
                           v_REQUEST_URL      OUT VARCHAR2,
                           p_STATUS           OUT NUMBER,
                           p_MESSAGE          OUT VARCHAR2) IS
    vProcedureName VARCHAR2(50) := 'BUILD_PUBLIC_URL';
    v_FILENAME  VARCHAR2(255);
    v_DATE_STRING  VARCHAR2(12);
	INVALID_REQUEST EXCEPTION;
BEGIN

    p_STATUS  := MEX_UTIL.g_SUCCESS;

    v_DATE_STRING := TO_CHAR(p_DATE, 'YYYYMMDD');

    IF UPPER(p_REQUEST_TYPE) = MEX_ISONE.g_DA_LMP THEN
      v_FILENAME := 'da-lmp/lmp_da_' || v_DATE_STRING || '.csv';
      v_REQUEST_URL := g_BASE_HIST_RPTS_URL || v_FILENAME;
    ELSIF UPPER(p_REQUEST_TYPE) = MEX_ISONE.g_RT_LMP THEN
      v_FILENAME := 'rt-lmp/lmp_rt_final_' || v_DATE_STRING || '.csv';
      v_REQUEST_URL := g_BASE_HIST_RPTS_URL || v_FILENAME;
    ELSIF UPPER(p_REQUEST_TYPE) = MEX_ISONE.g_REG_CLR_PRICE THEN
      --v_FILENAME := 'rcpf/final_regulation_' || v_DATE_STRING || '.csv';
      v_FILENAME := '?report=rcp&subcat=final&submit=csv&startDate=' || v_DATE_STRING || '&endDate=' || v_DATE_STRING;
      v_REQUEST_URL := g_BASE_HOURLY_DATA_URL || v_FILENAME;
    ELSE
      v_REQUEST_URL := '';
	  RAISE INVALID_REQUEST;
    END IF;

EXCEPTION
	WHEN INVALID_REQUEST THEN
	  P_STATUS  := -50000;
	  P_MESSAGE := 'Error in ' || vPackageName || '.' || vProcedureName || ': Invalid request type ' || p_REQUEST_TYPE;
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || '.' || vProcedureName || ': ' || SQLERRM;
END BUILD_PUBLIC_URL;
----------------------------------------------------------------------------------------------------
  --
  -- Fetch the CSV file for LMP  and map into records for MM import.  The ACTION
  --   parameter dictates what type of file.  Use the constanst referenced below
  --   to acquire the desired data:
  --MEX_ISONE.g_DA_LMP CONSTANT VARCHAR2(64) := 'DAY-AHEAD';
  --MEX_ISONE.g_RT_LMP CONSTANT VARCHAR2(64) := 'REAL-TIME';

PROCEDURE FETCH_LMP(p_DATE              IN  DATE,
                    p_ACTION            IN VARCHAR2,
                    p_CREDENTIALS       IN EXTERNAL_CREDENTIAL_TBL,
                    p_RECORDS           OUT MEX_NE_LMP_TBL,
                    p_STATUS            OUT NUMBER,
                    p_MESSAGE           OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'FETCH_LMP';
    v_REQUEST_URL  VARCHAR2(255);
    v_CSV_CLOB     CLOB;
    v_MAP          MEX_HTTP.PARAMETER_MAP;
BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;

    -- build the url needed. The action and date controls the resulting URL
    BUILD_PUBLIC_URL(p_DATE, p_ACTION, v_REQUEST_URL, p_STATUS, p_MESSAGE);    
    v_MAP('isourl') := v_REQUEST_URL;

	IF  p_STATUS = MEX_UTIL.g_SUCCESS THEN
        -- acquire the CSV file
        IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
        	MEX_ISONE.RUN_EXCHANGE(v_MAP,
    							   p_CREDENTIALS(p_CREDENTIALS.FIRST),
    							   'sys',
    							   'fetchurl',
    							   'ISONE_LMP: Fetching LMP',
    							   v_CSV_CLOB,
    							   p_STATUS,
    							   p_MESSAGE);
        END IF;

        -- parse the response into records
        IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
              PARSE_LMP(v_CSV_CLOB,
                        p_RECORDS,
                        p_STATUS,
                        p_MESSAGE);
       END IF;
	END IF;

EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || '.' || vProcedureName || ': ' || SQLERRM;
END FETCH_LMP;

----------------------------------------------------------------------------------------------------

  --
  -- Fetch the CSV file for RCP  and map into records for MM import.  The ACTION
  --   parameter dictates what type of file.  Use the constanst referenced below
  --   to acquire the desired data:
  --MEX_ISONE.g_REG_CLR_PRICE CONSTANT VARCHAR2(64) := 'REGULATION CLEARING PRICE';

  --
PROCEDURE FETCH_RCP(p_DATE              IN  DATE,
                    p_ACTION            IN VARCHAR2,
                    p_CREDENTIALS       IN EXTERNAL_CREDENTIAL_TBL,
                    p_RECORDS           OUT MEX_NE_RCP_COST_TBL,
                    p_STATUS            OUT NUMBER,
                    p_MESSAGE           OUT VARCHAR2) IS

    vProcedureName VARCHAR2(50) := 'FETCH_RCP';
    v_REQUEST_URL  VARCHAR2(255);
    v_CSV_CLOB     CLOB;
    v_MAP          MEX_HTTP.PARAMETER_MAP;
BEGIN
    p_STATUS  := MEX_UTIL.g_SUCCESS;

    -- build the url needed. The action and date controls the resulting URL
    BUILD_PUBLIC_URL(p_DATE, p_ACTION, v_REQUEST_URL, p_STATUS, p_MESSAGE);
    v_MAP('isourl') := v_REQUEST_URL;
    
	IF  p_STATUS = MEX_UTIL.g_SUCCESS THEN
        -- acquire the CSV file
        IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
          MEX_ISONE.RUN_EXCHANGE(v_MAP,
    							 p_CREDENTIALS(p_CREDENTIALS.FIRST),
    							 'sys',
    							 'fetchurl',
    							 'ISONE_LMP: Fetching RCP',
    							 v_CSV_CLOB,
    							 p_STATUS,
    							 p_MESSAGE);
        END IF;

        -- parse the response into records
        IF (p_STATUS = MEX_UTIL.g_SUCCESS) THEN
              PARSE_REGULATION(v_CSV_CLOB,
                               p_RECORDS,
                               p_STATUS,
                               p_MESSAGE);
        END IF;
	END IF;
EXCEPTION
    WHEN OTHERS THEN
      P_STATUS  := SQLCODE;
      P_MESSAGE := 'Error in ' || vPackageName || '.' || vProcedureName || ': ' || SQLERRM;
END FETCH_RCP;

END MEX_ISONE_LMP;
/
