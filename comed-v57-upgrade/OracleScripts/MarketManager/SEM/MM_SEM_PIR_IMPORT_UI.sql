CREATE OR REPLACE PACKAGE MM_SEM_PIR_IMPORT_UI IS
--------------------------------------------------------------------------------
-- Created : 04/28/2010 16:00
-- Purpose : User Interface for Unprocessed PIR Import files.
-- $Revision: 1.3 $
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Standard function to return the version of the package.
FUNCTION WHAT_VERSION RETURN VARCHAR;

--------------------------------------------------------------------------------
-- This procedure get a list of files that have not been processed.
-- Queries the table SEM_MP_INFO_FILES
PROCEDURE GET_UNPROCESSED_PIR_FILES (
   p_CURSOR IN OUT GA.REFCURSOR);

--------------------------------------------------------------------------------
-- This procedure displays the contents of the clob associated with
-- the given import file Id.
PROCEDURE GET_PIR_FILE_CONTENT(
   p_IMPORT_FILE_ID  IN NUMBER,
   p_CONTENTS       OUT CLOB);

--------------------------------------------------------------------------------
-- This procedure process all the ID's in the collection based on the
-- statement type provided.
PROCEDURE PROCESS_PIR_FILES(
   p_IMPORT_FILE_ID    IN NUMBER_COLLECTION,
   p_STATEMENT_TYPE_ID IN STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE,
   p_LOG_TYPE          IN NUMBER,
   p_TRACE_ON          IN NUMBER);

--------------------------------------------------------------------------------
-- This procedure get a list of valid statement types.
-- Queries the table STATEMENT_TYPES
PROCEDURE GET_STATEMENT_TYPES (
   p_CURSOR IN OUT GA.REFCURSOR);

END MM_SEM_PIR_IMPORT_UI;
/