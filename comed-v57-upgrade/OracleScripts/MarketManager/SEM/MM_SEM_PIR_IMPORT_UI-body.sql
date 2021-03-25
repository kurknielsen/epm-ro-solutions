CREATE OR REPLACE PACKAGE BODY MM_SEM_PIR_IMPORT_UI IS
--------------------------------------------------------------------------------
-- Created : 04/28/2010 16:00
-- Purpose : User Interface for Unprocessed PIR Import files.
-- $Revision: 1.1 $
--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
   RETURN '$Revision: 1.1 $';
END WHAT_VERSION;

--------------------------------------------------------------------------------
PROCEDURE GET_UNPROCESSED_PIR_FILES (
   p_CURSOR IN OUT GA.REFCURSOR)
IS
BEGIN
  
  OPEN P_CURSOR FOR
    SELECT 0 AS PROCESS_FLAG,
           FILE_DATE,
           FILE_NAME,
           IMPORT_TIMESTAMP,
           IMPORT_FILE_ID
      FROM SEM_MP_INFO_FILES
     ORDER BY IMPORT_TIMESTAMP;
           
END GET_UNPROCESSED_PIR_FILES;


--------------------------------------------------------------------------------
PROCEDURE GET_PIR_FILE_CONTENT(
   p_IMPORT_FILE_ID IN NUMBER,
   p_CONTENTS      OUT CLOB)
IS
BEGIN
  
  SELECT IMPORT_FILE
    INTO p_CONTENTS           
    FROM SEM_MP_INFO_FILES
   WHERE IMPORT_FILE_ID = p_IMPORT_FILE_ID;    
       
END GET_PIR_FILE_CONTENT;


--------------------------------------------------------------------------------
PROCEDURE PROCESS_PIR_FILES
	(
	p_IMPORT_FILE_ID    IN NUMBER_COLLECTION,
	p_STATEMENT_TYPE_ID IN STATEMENT_TYPE.STATEMENT_TYPE_ID%TYPE,
	p_LOG_TYPE          IN NUMBER,
	p_TRACE_ON          IN NUMBER) AS

v_STATUS	NUMBER;
v_MESSAGE	VARCHAR2(32767);
BEGIN

	MM_SEM_SETTLEMENT.IMPORT_UNPROCESSED_PIRS(p_IMPORT_FILE_ID, p_STATEMENT_TYPE_ID, p_LOG_TYPE, p_TRACE_ON, v_STATUS, v_MESSAGE);
	ERRS.VALIDATE_STATUS('MM_SEM_SETTLEMENT.IMPORT_UNPROCESSED_PIRS', v_STATUS, v_MESSAGE);
	
END PROCESS_PIR_FILES;
--------------------------------------------------------------------------------
-- This procedure get a list of valid statement types.
-- Queries the table STATEMENT_TYPES
PROCEDURE GET_STATEMENT_TYPES (
   p_CURSOR IN OUT GA.REFCURSOR)
IS
BEGIN
  
  OPEN P_CURSOR FOR
    SELECT STATEMENT_TYPE_NAME,
           STATEMENT_TYPE_ID           
      FROM STATEMENT_TYPE 
     ORDER BY STATEMENT_TYPE_NAME;    
       
END GET_STATEMENT_TYPES;



END MM_SEM_PIR_IMPORT_UI;
/
