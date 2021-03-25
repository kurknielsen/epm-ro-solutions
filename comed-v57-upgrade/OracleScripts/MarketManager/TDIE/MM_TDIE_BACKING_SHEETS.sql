CREATE OR REPLACE PACKAGE MM_TDIE_BACKING_SHEETS IS
--------------------------------------------------------------------------------
-- Created : 11/19/2009 12:14
-- Purpose : Download Retail Financial Settlement Backing Sheets
-- $Revision: 1.7 $
--------------------------------------------------------------------------------

c_TUOS_DET_TYPE_CHG_PARM   CONSTANT VARCHAR2(64) := 'CHARGING PARAMETERS';
c_TUOS_DET_TYPE_RATES      CONSTANT VARCHAR2(64) := 'RATES';
c_TUOS_DET_TYPE_CHG_INTRVL CONSTANT VARCHAR2(64) := 'CHARGES FOR ACCOUNT IN CHARGING INTERVAL';

--------------------------------------------------------------------------------
-- Standard function to return the version of the package.
FUNCTION WHAT_VERSION RETURN VARCHAR;

--------------------------------------------------------------------------------
-- This procedure handles the import of a single TDIE Backing Sheet file.
-- This procedure will start the  Import TDIE Backing Sheet File process.
PROCEDURE IMPORT (
   p_IMPORT_FILE       IN CLOB,
   p_IMPORT_FILE_PATH  IN VARCHAR2,
   p_FILE_TYPE         IN VARCHAR2,
   p_PROCESS_ID       OUT VARCHAR2,
   p_PROCESS_STATUS   OUT NUMBER,
   p_MESSAGE          OUT VARCHAR2);

PROCEDURE MAP_TUOS_SUPPLY_UNITS(p_INVOICE_NUMBER  IN VARCHAR2);

END MM_TDIE_BACKING_SHEETS;
/