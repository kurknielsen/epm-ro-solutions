prompt *** compile_schema ***
begin dbms_utility.compile_schema(user,false); end;
/

column object_name format a30
column object_type format a16

prompt ************************************************
prompt *** Invalid Objects After Product Deployment ***
prompt ************************************************
prompt
select object_name, object_type from user_objects where status <> 'VALID';
prompt
