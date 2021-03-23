CREATE OR REPLACE PACKAGE MEX_NYISO_LOAD IS
-- $Revision: 1.8 $

  /*TYPE PARAMETER_MAP IS TABLE OF VARCHAR2(512) INDEX BY VARCHAR2(512);*/

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
FUNCTION WHAT_VERSION RETURN VARCHAR2;

  PROCEDURE FETCH_LOAD(p_DATE     IN DATE,
                           p_ACTION   IN VARCHAR2,
                           p_RECORDS  OUT MEX_NY_LOAD_TBL,
                           p_STATUS   OUT NUMBER,
                           p_LOGGER  	IN OUT MM_LOGGER_ADAPTER);



END MEX_NYISO_LOAD;
/