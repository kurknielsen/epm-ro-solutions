spool setup.log

DEFINE database=&1
DEFINE schemaName=&2
DEFINE superUser=&3

prompt ======================================================================================
prompt Setup NYISO 
prompt ======================================================================================
prompt Schema: &schemaName@&database FOR: &superUser
prompt ======================================================================================

connect &schemaName@&database

BEGIN
    SECURITY_CONTROLS.SET_CURRENT_USER('&superUser');    
END;
/

set define off

--prompt NYISO_ENTITIES
--@@NYISO_ENTITIES.sql
prompt NYISO_STATEMENT_TYPES
@@NYISO_STATEMENT_TYPES.sql
--prompt NYISO_SYSTEM_ACTIONS
--@@NYISO_SYSTEM_ACTIONS.sql
prompt NYISO_SYSTEM_DICTIONARY
@@NYISO_SYSTEM_DICTIONARY.sql

prompt Enabling NYISO external system...
BEGIN
UPDATE EXTERNAL_SYSTEM SET IS_ENABLED=1 WHERE EXTERNAL_SYSTEM_ID=EC.ES_NYISO;
END;
/

commit;
/

spool off
exit;
