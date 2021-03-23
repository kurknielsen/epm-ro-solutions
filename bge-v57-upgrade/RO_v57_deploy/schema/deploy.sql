spool deploy.log

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 1-drop_deprecated_objects.sql
@@1-drop_deprecated_objects.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 2-drop_replacement_objects.sql
@@2-drop_replacement_objects.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 3-drop_custom_code.sql
@@3-drop_custom_code.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 4-drop_mm_mex_objects.sql
@@4-drop_mm_mex_objects.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 5-drop_sequences.sql
@@5-drop_sequences.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 6-bge_schema_tasks.sql
@@6-bge_schema_tasks.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 7-create_backup_staging.sql
@@7-create_backup_staging.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 8-drop_core_tables.sql
@@8-drop_core_tables.sql
select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;

spool off;
exit;
