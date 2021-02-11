WHENEVER SQLERROR EXIT WARNING ROLLBACK;
SET VERIFY OFF
SET ECHO OFF
SET TERMOUT OFF

DEFINE schema_nme1=&1

PROMPT 'Create Table: CDI_PJM_SHORT_NAME_TEMP'

DECLARE

    lv_schema_nme1      VARCHAR2(15) := '&schema_nme1';
    lv_obj_count        NUMBER;
    lv_sql varchar2(2000);
BEGIN
   ----------------------------------------------------------
   -- Count the object to see if it exists
   ----------------------------------------------------------
   SELECT COUNT(*)
     INTO lv_obj_count
     FROM all_objects
    WHERE upper(owner) = upper(lv_schema_nme1)
      AND object_type = 'TABLE'
      AND object_name = 'CDI_PJM_SHORT_NAME_TEMP';

   IF lv_obj_count > 0 THEN
     execute immediate 'drop table CDI_PJM_SHORT_NAME_TEMP';
   END IF;

   EXECUTE IMMEDIATE 'CREATE TABLE CDI_PJM_SHORT_NAME_TEMP ( CONTRACT_NAME  VARCHAR2(16) )';     

END;
/
PROMPT 'Table Created: CDI_PJM_SHORT_NAME'
