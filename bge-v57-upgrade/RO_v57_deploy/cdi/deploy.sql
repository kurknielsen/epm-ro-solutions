set verify off
define nero_data_tablespace = NERO_DATA
define nero_index_tablespace = NERO_INDEX
define nero_large_data_tablespace = NERO_LARGE_DATA
define nero_large_index_tablespace = NERO_LARGE_INDEX

spool deploy.log

column object_name format a30
column object_type format a16

prompt ***********************************************
prompt *** Invalid Objects Before Script Execution ***
prompt ***********************************************
prompt
select object_name, object_type from user_objects where status <> 'VALID';
prompt

prompt *** plsql/cdi_drop_object.prc ***************************************************************************************************
@@plsql/cdi_drop_object.prc

prompt *** synonyms ********************************************************************************************************************
@@synonyms/deploy.sql

prompt *** override ********************************************************************************************************************
@@override/deploy.sql

prompt *** legacy ********************************************************************************************************************
@@legacy/deploy.sql

prompt *** ddl *************************************************************************************************************************
@@ddl/deploy.sql

prompt *** types ***********************************************************************************************************************
@@types/deploy.sql

prompt *** views ***********************************************************************************************************************
@@views/deploy.sql

prompt *** plsql ***********************************************************************************************************************
@@plsql/deploy.sql

prompt *** mm_mex  *********************************************************************************************************************
@@mm_mex/deploy.sql

prompt *** compile_schema **************************************************************************************************************
begin dbms_utility.compile_schema(user,false); end;
/

prompt **********************************************
prompt *** Invalid Objects After Script Execution ***
prompt **********************************************
prompt

select object_name, object_type from user_objects where status <> 'VALID';

spool off;
exit;
