CREATE OR REPLACE PACKAGE MEX_NYISO_TC IS
-- $Revision: 1.7 $

  -- Author  : VGODYN
  -- Created : 9/26/2005 3:03:55 PM
  -- Purpose : Provides NYISO (Available and Total) Transfer Capabilities

FUNCTION WHAT_VERSION RETURN VARCHAR2;

  -----------------------------------------------------------------------------
  -- ATC/TTC REQUESTS
  -----------------------------------------------------------------------------
  --
  -- Fetch the CSV file for ATC/TTC and map into records for MM import. The ACTION
  --   parameter dictates what type of ATC/TTC.  Use the constanst referenced below
  --   to acquire the desired data:
  --
  -- g_ATC_TTC - 'ATC TTC';

  PROCEDURE FETCH_ATC_TTC
  (
      p_DATE    IN DATE,
      p_ACTION  IN VARCHAR2,
      p_RECORDS OUT MEX_NY_XFER_CAP_SCHEDS_TBL,
      p_STATUS  OUT NUMBER,
      p_LOGGER  IN OUT MM_LOGGER_ADAPTER
  );


END MEX_NYISO_TC;
/