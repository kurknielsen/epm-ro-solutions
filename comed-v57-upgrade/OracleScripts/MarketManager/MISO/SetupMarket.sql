prompt MISO_LABEL
@@MISO_LABEL.sql
prompt MISO_RESOURCE_TRAITS
@@MISO_RESOURCE_TRAITS.sql
prompt MISOEntityManagerDefaults
@@MISOEntityManagerDefaults.sql
prompt MISO_STATUS_NAMES
@@MISO_STATUS_NAMES.sql
prompt MISO_ACTION
@@MISO_ACTION.sql
prompt MISO_HOLIDAYS
@@MISO_HOLIDAYS.sql

prompt Enabling MISO external system...
BEGIN
UPDATE EXTERNAL_SYSTEM SET IS_ENABLED=1 WHERE EXTERNAL_SYSTEM_ID=EC.ES_MISO;
END;
/

commit;
