prompt IMO_RESOURCE_TRAITS.sql
@@IMO_RESOURCE_TRAITS.sql

prompt Enabling IMO external system...
BEGIN
UPDATE EXTERNAL_SYSTEM SET IS_ENABLED=1 WHERE EXTERNAL_SYSTEM_ID=EC.ES_IMO;
END;
/

commit;