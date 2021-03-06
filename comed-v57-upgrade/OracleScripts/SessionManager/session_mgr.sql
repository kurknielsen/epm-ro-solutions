CREATE OR REPLACE PACKAGE SESSION_MGR IS
-- $Revision: 1.5 $

-----------------------------------------------------------------------------
-- FILE: SESSION_MGR.SQL
--
-- Behavior used to manage sessions for MarketManager (MM).
--
-- MarketManager tags each Oracle database sesssion with:
--  v$session.CLIENT_IDENTIFIER = the value 'VENTYX EMO'
--  v$session.CLIENT_INFO = the MM_user@MM_schemaName
--
-- This package is used to list and kill specific Oracle sessions that
--   meet that criteria, thus providing management of MM related sessions
--   while not endangering any others.
-----------------------------------------------------------------------------

TYPE REF_CURSOR IS REF CURSOR;

---------------
-- CONSTANTS --
---------------

c_STATUS_OK           CONSTANT NUMBER := 0;
c_STATUS_CURR_NOT_VTX CONSTANT NUMBER := 1;
c_STATUS_BAD_SESSION  CONSTANT NUMBER := 2;
c_STATUS_PRIV         CONSTANT NUMBER := 3;
c_STATUS_OWN_SESSION  CONSTANT NUMBER := 4;

FUNCTION WHAT_VERSION RETURN VARCHAR2;
------------------------------------------------------------------------------------
-- LIST ALL THE CURRENT ORACLE SESSIONS IN USE BY MarketManager
FUNCTION LIST_SESSIONS(p_CURSOR OUT REF_CURSOR) RETURN NUMBER;
------------------------------------------------------------------------------------
-- KILL THE SPECIFIED SESSION - IFF it is a MarketManager session
FUNCTION KILL_SESSION
	(
	p_SESSION_SID       IN NUMBER,
	p_SESSION_SERIALNUM IN NUMBER
	) RETURN NUMBER;
------------------------------------------------------------------------------------
--
-- Kill all sessions for the specified userInfo that is in the form of:
--   marketMgrUser@schemaName
--   IFF it is a MarketManager session
FUNCTION KILL_USER_SESSIONS(p_USER IN VARCHAR2) RETURN NUMBER;
------------------------------------------------------------------------------------
END SESSION_MGR;
/
CREATE OR REPLACE PACKAGE BODY SESSION_MGR AS

c_PRODUCT_FLAG    CONSTANT VARCHAR2(32) := 'VENTYX EMO';

---------------
-- ERRORS    --
---------------

-- This schema does not necessarily have to be an application schema, so we
-- have to redefine our own exceptions, even though they are already in the
-- MSG package

e_ERR_INVALID_SESSION EXCEPTION;
PRAGMA EXCEPTION_INIT(E_ERR_INVALID_SESSION, -30);

e_ERR_PRIVILEGES EXCEPTION;
PRAGMA EXCEPTION_INIT(E_ERR_PRIVILEGES, -1031);

------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.5 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION CURRENT_APp_SCHEMA_NAME RETURN VARCHAR2 IS
	v_CLIENT_INFO        V$SESSION.CLIENT_INFO%TYPE;
	v_CURRENT_SCHEMA 	 VARCHAR2(256);

BEGIN

	DBMS_APPLICATION_INFO.READ_CLIENT_INFO(v_CLIENT_INFO);

	IF INSTR(v_CLIENT_INFO, '@') > 0 THEN
	  -- GET THE CURRENT CLIENT_INFO TO DETERMINE THE CURRENT SCHEMA
	  v_CURRENT_SCHEMA := SUBSTR(v_CLIENT_INFO, INSTR(v_CLIENT_INFO, '@') + 1);
	ELSE
		RETURN NULL;
	END IF;

	RETURN v_CURRENT_SCHEMA;
END CURRENT_APp_SCHEMA_NAME;
------------------------------------------------------------------------------------
FUNCTION TEST_CURRENT_SESSION RETURN NUMBER IS

	v_CURRENT_AUSID      NUMBER(9);
	v_CURRENT_IDENTIFIER V$SESSION.CLIENT_IDENTIFIER%TYPE;
	v_CURRENT_PROGRAM    V$SESSION.PROGRAM%TYPE;
	v_CURRENT_SID		 V$SESSION.SID%TYPE;

BEGIN

	-- GET THE CURRENT AUDSID AND SID SO WE CAN MAKE SURE THE CURRENT PROGRAM IS RO/MM
	SELECT SYS_CONTEXT('userenv', 'sessionid') INTO v_CURRENT_AUSID FROM DUAL;
	SELECT SYS_CONTEXT('userenv', 'sid') INTO v_CURRENT_SID FROM DUAL;

	SELECT SYS_CONTEXT('userenv', 'client_identifier') INTO v_CURRENT_IDENTIFIER FROM DUAL;

	SELECT V.PROGRAM INTO v_CURRENT_PROGRAM FROM V$SESSION V WHERE V.AUDSID = v_CURRENT_AUSID
																	AND V.SID = v_CURRENT_SID;

	-- ONLY RO/MM PRODUCT SESSIONS CAN USE THIS PACKAGE -- TEST PRODUCT FLAG
	IF v_CURRENT_IDENTIFIER != c_PRODUCT_FLAG THEN
		RETURN c_STATUS_CURR_NOT_VTX;
	END IF;

	RETURN c_STATUS_OK;

END TEST_CURRENT_SESSION;
------------------------------------------------------------------------------------
FUNCTION LIST_SESSIONS(p_CURSOR OUT REF_CURSOR) RETURN NUMBER IS

	v_TEST_CURR_SESSION NUMBER := c_STATUS_OK;
	v_CURRENT_AUSID V$SESSION.AUDSID%TYPE;
	v_CURRENT_SID	V$SESSION.SID%TYPE;
	v_CURRENT_SCHEMA v$SESSION.CLIENT_INFO%TYPE;

BEGIN

	-- GET THE CURRENT AUDSID AND SID SO WE CAN TEST WHICH SESSION IS THE ONE CALLING THE METHOD
	SELECT SYS_CONTEXT('userenv', 'sessionid') INTO v_CURRENT_AUSID FROM DUAL;
	SELECT SYS_CONTEXT('userenv', 'sid') INTO v_CURRENT_SID FROM DUAL;

	v_TEST_CURR_SESSION := TEST_CURRENT_SESSION();

	IF v_TEST_CURR_SESSION != c_STATUS_OK THEN
		RETURN v_TEST_CURR_SESSION;
	END IF;

	v_CURRENT_SCHEMA := CURRENT_APp_SCHEMA_NAME;

	IF v_CURRENT_SCHEMA IS NULL THEN
		RETURN c_STATUS_CURR_NOT_VTX;
	END IF;

	OPEN p_CURSOR FOR
		SELECT V.SID as SESSION_SID,
			   V.SERIAL# AS SESSION_SERIALNUM,
			   V.AUDSID,
			   SUBSTR(V.CLIENT_INFO, 0, INSTR(V.CLIENT_INFO, '@') - 1) AS OWNER,
			   V.USERNAME AS SCHEMA,
			   V.PROGRAM,
			   V.MODULE,
			   V.ACTION,
			   V.MACHINE,
			   V.OSUSER,
			   TO_CHAR(V.LOGON_TIME, 'MM/DD/YYYY HH:MI:SS AM') AS LOGON_TIME,
			   CASE
				   WHEN v_CURRENT_AUSID = V.AUDSID and v_CURRENT_SID = V.SID THEN
					1
				   ELSE
					0
			   END AS CURRENT_SCHEMA
		FROM V$SESSION V
		WHERE V.CLIENT_IDENTIFIER = c_PRODUCT_FLAG
			  AND V.STATUS != 'KILLED'
			  AND UPPER(V.CLIENT_INFO) LIKE '%@' || UPPER(v_CURRENT_SCHEMA)
		ORDER BY V.CLIENT_INFO, V.LOGON_TIME, V.PROGRAM;

	RETURN c_STATUS_OK;
EXCEPTION
	WHEN E_ERR_PRIVILEGES THEN
		RETURN c_STATUS_PRIV;
END LIST_SESSIONS;
------------------------------------------------------------------------------------
-- Kill the session, iff it is an RO/MM Session, belongs to the current schema and is a valid session
FUNCTION KILL_SESSION
	(
	p_SESSION_SID       IN NUMBER,
	p_SESSION_SERIALNUM IN NUMBER
	) RETURN NUMBER IS

	v_COUNT NUMBER(3);

	v_CURRENT_SCHEMA V$SESSION.CLIENT_INFO%TYPE;

	v_KILL_SESSION_INFO  V$SESSION.CLIENT_INFO%TYPE;
	v_KILL_SESSION_IDENT V$SESSION.CLIENT_IDENTIFIER%TYPE;

	v_STR VARCHAR2(200);

	v_SESSION_AUSID     NUMBER(9);
	v_TEST_CURR_SESSION NUMBER := c_STATUS_OK;

BEGIN

	SELECT COUNT(1)
	INTO v_COUNT
	FROM V$SESSION V
	WHERE V.SID = SYS_CONTEXT('USERENV', 'SID')
		  AND V.AUDSID = SYS_CONTEXT('USERENV', 'SESSIONID')
		  AND V.SID = p_SESSION_SID
		  AND V.SERIAL# = p_SESSION_SERIALNUM;

	IF v_COUNT > 0 THEN
		RETURN c_STATUS_OWN_SESSION;
	END IF;

	v_TEST_CURR_SESSION := TEST_CURRENT_SESSION;

	IF v_TEST_CURR_SESSION != c_STATUS_OK THEN
		RETURN v_TEST_CURR_SESSION;
	END IF;

	v_CURRENT_SCHEMA := CURRENT_APp_SCHEMA_NAME;

	IF v_CURRENT_SCHEMA IS NULL THEN
		RETURN c_STATUS_CURR_NOT_VTX;
	END IF;

	SELECT V.CLIENT_INFO, V.CLIENT_IDENTIFIER, V.AUDSID
	INTO v_KILL_SESSION_INFO, v_KILL_SESSION_IDENT, v_SESSION_AUSID
	FROM V$SESSION V
	WHERE V.SID = p_SESSION_SID
		  AND V.SERIAL# = p_SESSION_SERIALNUM;

	IF v_KILL_SESSION_IDENT != c_PRODUCT_FLAG OR
	   NOT v_KILL_SESSION_INFO LIKE '%@' || v_CURRENT_SCHEMA THEN
		-- WE CAN'T KILL SESSIONS THAT AREN'T RO/MM OR BELONG TO ANOTHER SCHEMA
		RETURN c_STATUS_BAD_SESSION;
	END IF;

	-- KILL THE SESSION
	v_STR := 'ALTER SYSTEM KILL SESSION ''' ||p_SESSION_SID|| ', ' ||p_SESSION_SERIALNUM || '''';

	EXECUTE IMMEDIATE v_STR;

	RETURN c_STATUS_OK;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN c_STATUS_BAD_SESSION;
	WHEN e_ERR_INVALID_SESSION THEN
		RETURN c_STATUS_BAD_SESSION;
	WHEN e_ERR_PRIVILEGES THEN
		RETURN c_STATUS_PRIV;

END KILL_SESSION;
------------------------------------------------------------------------------------
--
-- Kill all sessions for the specified userInfo that is in the form of:
--   marketMgrUser@schemaName
--   IFF it is a MarketManager session
--
FUNCTION KILL_USER_SESSIONS(p_USER IN VARCHAR2) RETURN NUMBER IS

	v_TEST_CURR_SESSION NUMBER := c_STATUS_OK;
	v_CURRENT_SCHEMA v$SESSION.CLIENT_INFO%TYPE := CURRENT_APp_SCHEMA_NAME;

	CURSOR USER_CUR IS
		SELECT V.SID, V.SERIAL#, V.CLIENT_INFO, V.CLIENT_IDENTIFIER
		FROM V$SESSION V
		WHERE UPPER(V.CLIENT_INFO) = UPPER(p_USER || '@' || v_CURRENT_SCHEMA )
			  AND UPPER(V.CLIENT_IDENTIFIER) = c_PRODUCT_FLAG;

	v_USER_REC USER_CUR%ROWTYPE;

	v_STR VARCHAR2(512);

BEGIN

	IF p_USER IS NULL OR LENGTH(TRIM(p_USER)) = 0 THEN
		RETURN c_STATUS_BAD_SESSION;
	END IF;

	v_TEST_CURR_SESSION := TEST_CURRENT_SESSION;

	IF v_TEST_CURR_SESSION != c_STATUS_OK THEN
		RETURN v_TEST_CURR_SESSION;
	END IF;

	IF v_CURRENT_SCHEMA IS NULL THEN
		RETURN c_STATUS_CURR_NOT_VTX;
	END IF;

	FOR v_USER_REC IN USER_CUR LOOP
		BEGIN

			v_STR := 'alter system kill session ''' || v_USER_REC.SID || ',' || v_USER_REC.SERIAL# || '''';
			EXECUTE IMMEDIATE v_STR;

		EXCEPTION
			WHEN e_ERR_INVALID_SESSION THEN
				-- DO NOTHING, IGNORE IT
				-- THIS MEANS THE SESSION TERMINATED BEFORE WE COULD KILL IT
				NULL;
		END;
	END LOOP;

	RETURN c_STATUS_OK;

EXCEPTION
	WHEN e_ERR_PRIVILEGES THEN
		RETURN c_STATUS_PRIV;

END KILL_USER_SESSIONS;
---------------------------------------------------------------------------------------------------
END SESSION_MGR;
/
