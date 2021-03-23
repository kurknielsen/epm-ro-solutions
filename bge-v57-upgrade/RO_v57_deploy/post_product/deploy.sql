spool deploy.log

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 1-add_table_attributes.sql
@@1-add_table_attributes.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 2-modify_table_attributes.sql
@@2-modify_table_attributes.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 3-compile_schema.sql
@@3-compile_schema.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 4-business_entity_data.sql
@@4-business_entity_data.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 5-entity_domain_data.sql
@@5-entity_domain_data.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 6-migrate_load_profile.sql
@@6-migrate_load_profile.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 7-migrate_market_price.sql
@@7-migrate_market_price.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 8-migrate_system_load.sql
@@8-migrate_system_load.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 9-migrate_weather.sql
@@9-migrate_weather.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 10-migrate_loss_factor.sql
@@10-migrate_loss_factor.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 11-ancillary_service_allocation_data.sql
@@11-ancillary_service_allocation_data.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 12-holiday_data.sql
@@12-holiday_data.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 13-alm_trigger.sql
@@13-alm_trigger.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 14-cdi_plc_icap_tx_trigger.sql
@@14-cdi_plc_icap_tx_trigger.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 15-dormant_plc_trigger.sql
@@15-dormant_plc_trigger.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 16-rider_trigger.sql
@@16-rider_trigger.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 17-tariff_trigger.sql
@@17-tariff_trigger.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 18-create_aggregate_accounts.sql
@@18-create_aggregate_accounts.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 19-create_sesason_templates.sql
@@19-create_sesason_templates.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 20-drop_backup_staging.sql
@@20-drop_backup_staging.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 21-truncate_bge_table_content.sql
@@21-truncate_bge_table_content.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
prompt 22-drop_deprecated_jobs.sql
@@22-drop_deprecated_jobs.sql

select to_char(current_date, 'mm/dd/yyyy hh24:mi:ss') "CURRENT_TIME" from dual;
spool off;
exit;

