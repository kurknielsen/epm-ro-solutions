-- CVS Revision: $Revision: 1.12 $
SET DEFINE OFF

prompt Setting user role to super-user...
@@SU.sql

-- IT_SCHEDULE.AMOUNT needs to be widened to support 6 decimals in PIR determinants
ALTER TABLE IT_SCHEDULE MODIFY AMOUNT NUMBER(16,8);

prompt SEM_SYSTEM_TIME_ZONE 
@@SEM_SYSTEM_TIME_ZONE.sql
 	
prompt SEM_LABEL		
@@SEM_LABEL.sql

prompt SEM_SYSTEM_DICTIONARY 
@@SEM_system_dictionary.sql

prompt SEM_REPORT_ATTRIBUTES 
@@SEM_REPORT_ATTRIBUTES.sql

prompt SEM_STATEMENT_TYPES
@@SEM_STATEMENT_TYPES.sql    

prompt add_pir_statement_types.sql
@@add_pir_statement_types.sql

PROMPT ADD_VISIBLE_STMNT_TYPES_REALM.sql
@@ADD_VISIBLE_STMNT_TYPES_REALM.sql

prompt SYSTEM_RESOURCE_TRAITS
@@SEM_RESOURCE_TRAITS.sql     

prompt SEM_CONDITIONAL_FORMATS
@@SEM_CONDITIONAL_FORMATS.sql

PROMPT SEM_HOLIDAYS
@@SEM_HOLIDAYS.sql

PROMPT SEM_HOLIDAY_OBSERVANCE
@@SEM_HOLIDAY_OBSERVANCE.sql

PROMPT SEM_EntityAttributes
@@SEM_EntityAttributes.sql

PROMPT SEM_OtherEntities.sql
@@SEM_OtherEntities.sql

prompt CFD Prices
@@CFD_Prices.sql

prompt SEM_Triggers
@@SEM_Triggers.sql

prompt Enabling SEM external system...
BEGIN
UPDATE EXTERNAL_SYSTEM SET IS_ENABLED=1 WHERE EXTERNAL_SYSTEM_ID=EC.ES_SEM;
END;
/

prompt DST_FALL_BACK_DATE
@@DST_FALL_BACK_DATE.sql

prompt DST_SPRING_AHEAD_DATE
@@DST_SPRING_AHEAD_DATE.sql

commit;

prompt Recompile invalid objects
BEGIN
RECOMPILE_INVALID_OBJECTS;
END;
/

prompt createSEMSystemConfig.sql
@@CreateSEMSystemConfig.sql

prompt SEMConfigTweaks.sql
@@SEMConfigTweaks.sql

prompt Rebuild list of PIR Variables
@@SEM_PIR_VARIABLES_Rebuild.sql

prompt SEM_INTERCHANGE_TRANSACTION.sql
@@SEM_INTERCHANGE_TRANSACTION.sql

commit;

SET DEFINE ON
