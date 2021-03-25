prompt Setting user role to super-user...
@@..\Common\SU.sql

prompt Updating System Settings for PJM...
prompt PJM_LABEL
@@PJM_LABEL.sql

prompt Adding PJM Holidays...
prompt PJM_PJM_HOLIDAYS.sql
@@PJM_HOLIDAYS.sql
prompt PJM_ON_PEAK_END.sql
@@PJM_ON_PEAK_END.sql
--prompt PJM_SYSTEM_DATE_TIME.sql
--@@PJM_SYSTEM_DATE_TIME.sql

prompt Enabling PJM external system...
BEGIN
UPDATE EXTERNAL_SYSTEM SET IS_ENABLED=1, HAS_UNAME_PWD_CREDENTIALS=1, NUMBER_OF_CERTIFICATES=0 WHERE EXTERNAL_SYSTEM_ID=EC.ES_PJM;
END;
/

prompt PJM_ScheduleCoordinator.sql
@@PJM_ScheduleCoordinator.sql

prompt PJM_RESOURCE_TRAITS.sql
@@PJM_RESOURCE_TRAITS.sql

prompt PJM_EntityAttributes.sql
@@PJM_EntityAttributes.sql

prompt EntityAttributesUpdate.sql
@@EntityAttributesUpdate.sql

prompt PJM_Commodities.sql
@@PJM_Commodities.sql

prompt PJM_AncillaryCommodities.sql
@@PJM_AncillaryCommodities.sql

prompt PJM_eScheduleStatuses.sql
@@PJM_eScheduleStatuses.sql

prompt ConditionalFormatUpdate.sql
@@ConditionalFormatUpdate.sql

prompt New PJM Reports
@@Reports\build.sql

commit;
