-- when building the schema, script should fail upon encountering any SQL errors
WHENEVER SQLERROR EXIT FAILURE;

-- Parameter 1 is a path ot the Oraclescripts. Parameter 2 is the name of an output spool file

-- We are actually building a script named buildWorker.tmp that
-- will the fully-expanded paths. That way it can issue a 
-- SET DEFINE OFF statement so that ampersands in any of the
-- objects won't cause any issues

-- get current user and current day
column current_user new_value user
column current_date new_value now
select user as current_user,
	to_char(sysdate,'hh24:mi yyyy-mm-dd') current_date
from dual
/

DEFINE fullPath=&1
DEFINE spoolFile=&2

prompt SYSTEM_TIME_ZONE
@&1\System\SYSTEM_TIME_ZONE.sql

@@GenerateBuildWorkerTmp

-- disable failing on SQL errors when initializing database objects
WHENEVER SQLERROR CONTINUE NONE;

prompt ********************************************************
prompt Building schema &user at &now
prompt Using scripts in &fullPath
prompt ********************************************************

@~buildWorker.tmp

-- reenable failing on SQL errors
WHENEVER SQLERROR EXIT FAILURE;

-- Now that we have stored functions built we can build
-- function-based indexes
@@FUNCTION_BASED_INDEX.sql

---------------------------------------------------------------------------
-- Now finish building the schema by initializing tables with default data
---------------------------------------------------------------------------

-- Become super-user to make sure none of the logic below that
-- seeds data in the schema fails with privilege issues
BEGIN
	SECURITY_CONTROLS.SET_CURRENT_ROLES(ID_TABLE(ID_TYPE(SECURITY_CONTROLS.g_SUPER_USER_ROLE_ID)));
END;
/

-- We use custom exceptions as part of certain procedures run
-- during the build, so we need to create the message definitions
@&1\System\CREATE_MESSAGE_DEFINITIONS.sql

-- Entity metadata
@&1\System\ENTITY_DOMAIN.sql
@&1\System\NERO_TABLE_PROPERTY_INDEX.dat
@&1\System\STATUS_NAMES.sql
@&1\System\NOT_ASSIGNED.sql

-- Default roles, actions, and permissions
@&1\datalevelsecurity\build.sql
-- Default users
@&1\System\DEFAULT_SUPER_USER.sql
@&1\System\CREATE_SYSTEM_USERS.sql

-- Scheduler objects: programs, schedules, and jobs
@&1\Jobs\build.sql

-- Set the current user to 'System'
@&1\System\SU.sql

-- Default configuration and configuration-level security permissions
@&1\Systemobjects\build.sql

-- other out-of-the-box data and other settings
@&1\System\SYSTEM_DICTIONARY.sql
@&1\System\SYSTEM_LABEL.sql
@&1\System\DST_TYPE.sql
@&1\System\SYSTEM_DAY_INFO.sql
@&1\System\ANYTIME_TEMPLATE.sql
@&1\System\EXTERNAL_SYSTEM.sql
@&1\System\EDC_SETTLEMENT_AGENT.sql
@&1\System\SYSTEM_TABLE.sql
@&1\System\SETUP.sql
@&1\System\RTO_VERSION.sql
@&1\System\VERSION.sql
@&1\System\POST_SETUP.sql
@&1\System\SCHEDULE_TEMPLATE.sql
@&1\System\ROML_METADATA.sql
@&1\System\CREATE_ENTITY_ATTRIBUTES.sql

spool off

-- disable failing on SQL error
WHENEVER SQLERROR CONTINUE NONE;