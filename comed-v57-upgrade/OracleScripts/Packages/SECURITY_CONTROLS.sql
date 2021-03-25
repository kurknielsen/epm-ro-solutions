CREATE OR REPLACE PACKAGE SECURITY_CONTROLS IS
--Revision $Revision: 1.10 $

  -- Author  : JHUMPHRIES
  -- Created : 11/30/2006 10:32:45 AM
  -- Purpose : This package contains logic that controls security features. This package should *not*
  --           be exposed to any other schema if running in direct-Oracle-login mode
  -- $Revision: 1.10 $

FUNCTION WHAT_VERSION RETURN VARCHAR;


-- Is Data-Level Security Authorization enabled? If false, all data-level security checks will succeeed.
-- Setting this to false should be done with caution. It is intended only for processes that need
-- unrestricted access to the API
FUNCTION IS_AUTH_ENABLED RETURN BOOLEAN;
PROCEDURE SET_IS_AUTH_ENABLED(p_ENABLED IN BOOLEAN);

-- This flag controls whether or not an interface is running. Interfaces that need unrestricted access
-- to the API and to updating data should call this with a parameter of TRUE. It is important to
-- always call it again with a parameter of FALSE when done so that the session isn't left in
-- an un-secured state.
-- This flag essentially overrides the IS_AUTH_ENABLED and IS_DATA_WINDOW_ENABLED flags.
PROCEDURE SET_IS_INTERFACE(p_ENABLED IN BOOLEAN);

-- These functions are used to identify the current user. The SET_CURRENT_USER should only be called
-- from the SESSION_START procedure.
FUNCTION CURRENT_USER_ID RETURN NUMBER;
FUNCTION CURRENT_USER RETURN VARCHAR2;
-- Answer the user display name if present, defaulting to the user name
-- if the display name is not present.
-- %return VARCHAR2 NVL(USER_DISPLAY_NAME,USER_NAME)
FUNCTION GET_CURRENT_USER_DISPLAY_NAME RETURN VARCHAR2;
PROCEDURE SET_CURRENT_USER(p_USER_NAME IN VARCHAR2);

-- These functions are used to identify the current user. The SET_CURRENT_ROLES should only be called
-- from the build scripts (so that data can be initialized in a consistent manner regardless of
-- data-level security configuration).
FUNCTION CURRENT_ROLES RETURN ID_TABLE;
PROCEDURE SET_CURRENT_ROLES(p_ROLES IN ID_TABLE);
PROCEDURE RELOAD_CURRENT_ROLES; -- force the roles to be re-queried from tables

-- return 1 if the current user belongs to the super-user role or 0 otherwise
FUNCTION IS_SUPER_USER RETURN NUMBER;
-- return 1 if the current user belongs to a role that can update restricted data or 0 otherwise
FUNCTION CAN_UPDATE_RESTRICTED_DATA RETURN NUMBER;

-- Add a deleted entity to the graveyard
PROCEDURE BURY_ENTITY
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2
	);

FUNCTION GET_AVAIL_EXTERNAL_ACCOUNTS
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER
	) RETURN STRING_COLLECTION;

FUNCTION GET_EXTERNAL_CREDENTIAL_ID
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2
	) RETURN NUMBER;

PROCEDURE GET_EXTERNAL_UNAME_PASSWORD
	(
	p_CREDENTIAL_ID IN NUMBER,
	p_EXTERNAL_USERNAME OUT VARCHAR2,
	p_EXTERNAL_PASSWORD OUT VARCHAR2
	);

PROCEDURE GET_EXTERNAL_CERTIFICATE
	(
	p_CREDENTIAL_ID IN NUMBER,
	p_CERTIFICATE_TYPE IN VARCHAR2,
	p_CERT_CONTENTS OUT CLOB,
	p_CERT_PASSWORD OUT VARCHAR2
	);

-- Encryption/decryption routines - these should be used to
-- encrypt/decrypt data going into or coming out of the
-- external credentials tables - in particular external passwords,
-- certificate contents, and certificate passwords are all stored
-- in an encrypted format
FUNCTION ENCODE
	(
	p_PLAIN_TXT VARCHAR2
	) RETURN VARCHAR2;
FUNCTION ENCODE
	(
	p_RAW_DATA BLOB
	) RETURN CLOB;
FUNCTION DECODE
	(
	p_CIPHER_TXT VARCHAR2
	) RETURN VARCHAR2;
FUNCTION DECODE
	(
	p_CIPHER_TXT CLOB
	) RETURN BLOB;

FUNCTION START_BACKGROUND_JOB
	(
	p_PLSQL IN VARCHAR2,
	p_RUN_WHEN IN TIMESTAMP WITH TIME ZONE := NULL,
	p_JOB_CLASS IN VARCHAR2 := 'DEFAULT_JOB_CLASS',
	p_COMMENTS IN VARCHAR2 := NULL,
	p_JOB_DATA IN JOB_DATA%ROWTYPE := NULL,
	p_WAIT_FOR_JOB_TO_START IN NUMBER := NULL
	) RETURN VARCHAR2;

PROCEDURE DEQUEUE_BY_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER
	);

PROCEDURE ENFORCE_LOCK_STATE
	(
	p_LOCK_STATE IN CHAR
	);

-- if the user can update restricted data, return 'R' for Lock State 'R'.  Otherwise, return 'L' for Lock State 'R'.
--  in all other cases, echo back the Lock State. If p_LOCKING_ENABLED is specified and set to non-zero (to indicate that
--  the table's lock trigger is disabled - see AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED) then 'U' is always returned.
-- This function is used by reports that let "effective" lock state control conditional formatting in the UI. This gives
-- accurate feedback to the user regarding whether or not they will be able to update the record.
FUNCTION GET_EFFECTIVE_LOCK_STATE(p_LOCK_STATE IN CHAR, p_LOCKING_ENABLED IN NUMBER := 1) RETURN CHAR;

-- Calls Session_Start and Session_Stop if we are in a Parallel Child Session since the Child Sessions do not cause
--    the logon/logoff triggers to execute.
PROCEDURE INIT_PARALLEL_SESSION;
PROCEDURE FINISH_PARALLEL_SESSION;

-- Constants
g_SUPER_USER_ROLE_ID CONSTANT NUMBER := 1;
g_AUTH_CERT_TYPE CONSTANT VARCHAR2(32) := 'Authentication';
g_SIG_CERT_TYPE CONSTANT VARCHAR2(32) := 'Signature';

-- Constants for System Users
c_SUSER_SYSTEM CONSTANT VARCHAR2(32) := 'System';
c_SUSER_ID_SYSTEM CONSTANT NUMBER(9) := 1;

c_SUSER_MAIL_MONITOR CONSTANT VARCHAR2(32) := 'MailMonitor';
c_SUSER_ID_MAIL_MONITOR CONSTANT NUMBER(9) := 2;

c_SUSER_REACTOR CONSTANT VARCHAR2(32) := 'Reactor';
c_SUSER_ID_REACTOR CONSTANT NUMBER(9) := 3;

c_SUSER_PS_QUEUES_MONITOR CONSTANT VARCHAR2(32) := 'ProcQueuesMonitor';
c_SUSER_ID_PS_QUEUES_MONITOR CONSTANT NUMBER(9) := 4;

END SECURITY_CONTROLS;
/
