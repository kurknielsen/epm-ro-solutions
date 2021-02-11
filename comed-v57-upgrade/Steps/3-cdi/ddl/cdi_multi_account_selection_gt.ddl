WHENEVER SQLERROR EXIT WARNING ROLLBACK;
SET VERIFY OFF
SET ECHO OFF
SET TERMOUT OFF

DEFINE schema_nme1=&1

PROMPT 'Create Table: CDI_MULTI_ACCOUNT_SELECTION_GT'

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
      AND object_name = 'CDI_MULTI_ACCOUNT_SELECTION_GT';

   IF lv_obj_count > 0 THEN
     execute immediate 'drop table CDI_MULTI_ACCOUNT_SELECTION_GT';
   END IF;

   EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE CDI_MULTI_ACCOUNT_SELECTION_GT (  
                                                            EDC_ID           NUMBER,
                                                            PSE_ID           NUMBER(9), 
                                                            ESP_ID           NUMBER(9), 
                                                            POOL_ID          NUMBER(9), 
                                                            ACCOUNT_ID       NUMBER(9), 
                                                            AGGREGATE_ID     NUMBER(9),
                                                            SERVICE_ID       NUMBER(9)
                                                           ) ON COMMIT PRESERVE ROWS';     

END;
/
PROMPT 'Table Created: CDI_MULTI_ACCOUNT_SELECTION_GT'
