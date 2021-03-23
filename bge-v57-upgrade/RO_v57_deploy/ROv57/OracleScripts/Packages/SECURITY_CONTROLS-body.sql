CREATE OR REPLACE PACKAGE BODY SECURITY_CONTROLS IS
-----------------------------------------------------------------------------
-- Private variables
--------------------
-- Security flags
g_AUTH_ENABLED BOOLEAN := TRUE;
g_IS_INTERFACE BOOLEAN := FALSE;

-- Configuration
g_ROLE_STALENESS_LIMIT NUMBER := NULL;
g_LAST_ROLE_FETCH_TIME DATE := NULL;

-- User identification
g_CURRENT_USER_ID 				CURRENT_SESSION_USER.USER_ID%TYPE := NULL;
g_CURRENT_ROLES 				ID_TABLE := NULL;
g_CAN_UPDATE_RESTRICTED_DATA	BOOLEAN := FALSE;
g_IS_SUPER_USER					BOOLEAN := FALSE;
-----------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.7 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
FUNCTION IS_AUTH_ENABLED RETURN BOOLEAN IS
BEGIN
	-- interface's aren't restricted to authorization calls
	-- and neither are super-users
	IF g_IS_INTERFACE OR IS_SUPER_USER=1 THEN
		RETURN FALSE;
	ELSE
		RETURN g_AUTH_ENABLED;
	END IF;
END IS_AUTH_ENABLED;
-----------------------------------------------------------------------------
PROCEDURE SET_IS_AUTH_ENABLED(p_ENABLED IN BOOLEAN) AS
BEGIN
	g_AUTH_ENABLED := p_ENABLED;
END SET_IS_AUTH_ENABLED;
-----------------------------------------------------------------------------
PROCEDURE SET_IS_INTERFACE(p_ENABLED IN BOOLEAN) AS
BEGIN
	g_IS_INTERFACE := p_ENABLED;
END SET_IS_INTERFACE;
-----------------------------------------------------------------------------
PROCEDURE GET_ROLE_STALENESS_LIMIT AS
BEGIN
	g_ROLE_STALENESS_LIMIT := NVL(TO_NUMBER(GET_DICTIONARY_VALUE('RoleStalenessLimit',0,'System','Security')),5)/1440;
	-- limit of zero indicates roles never get stale
	IF g_ROLE_STALENESS_LIMIT = 0 THEN
		g_ROLE_STALENESS_LIMIT := NULL;
	END IF;
EXCEPTION
	WHEN OTHERS THEN
		-- exception could be thrown if setting is not a valid number
		g_ROLE_STALENESS_LIMIT := 5/1440; -- in which case, default to 5 minutes
END GET_ROLE_STALENESS_LIMIT;
-----------------------------------------------------------------------------
FUNCTION IS_SUPER_USER
	(
	p_ROLES IN ID_TABLE
	) RETURN BOOLEAN IS
v_IDX BINARY_INTEGER;
BEGIN
	IF p_ROLES IS NULL THEN
		RETURN FALSE;
	END IF;

	v_IDX := p_ROLES.FIRST;
	WHILE p_ROLES.EXISTS(v_IDX) LOOP
		IF p_ROLES(v_IDX).ID = g_SUPER_USER_ROLE_ID THEN
			RETURN TRUE;
		END IF;
		v_IDX := p_ROLES.NEXT(v_IDX);
	END LOOP;
	-- super-user role not in the role list? then not a super-user
	RETURN FALSE;
END IS_SUPER_USER;
-----------------------------------------------------------------------------
FUNCTION CAN_UPDATE_RESTRICTED_DATA
	(
	p_ROLES IN ID_TABLE
	) RETURN BOOLEAN IS
v_COUNT PLS_INTEGER;
BEGIN

	SELECT COUNT(1)
	INTO v_COUNT
	FROM SYSTEM_ACTION A,
		SYSTEM_ACTION_ROLE R,
		TABLE(CAST(p_ROLES as ID_TABLE)) IDs
	WHERE A.ACTION_NAME = SD.g_ACTION_UPDATE_RESTRICTED
		AND R.ACTION_ID = A.ACTION_ID
		AND R.ROLE_ID = IDs.ID
		AND R.ENTITY_DOMAIN_ID = CONSTANTS.NOT_ASSIGNED
		AND R.REALM_ID = SD.g_ALL_DATA_REALM_ID;

	RETURN v_COUNT > 0;

END CAN_UPDATE_RESTRICTED_DATA;
-----------------------------------------------------------------------------
PROCEDURE SET_CURRENT_ROLES(p_ROLES IN ID_TABLE, p_ALLOW_STALE IN BOOLEAN) IS
BEGIN
	IF p_ALLOW_STALE THEN
		g_ROLE_STALENESS_LIMIT := NULL;
	ELSE
		GET_ROLE_STALENESS_LIMIT;
	END IF;

	g_CURRENT_ROLES := p_ROLES;
	-- reset
	g_LAST_ROLE_FETCH_TIME := NULL;
	-- is this a super-user?
	g_IS_SUPER_USER := IS_SUPER_USER(p_ROLES);
	IF g_IS_SUPER_USER THEN
		g_CAN_UPDATE_RESTRICTED_DATA := TRUE; -- super-users do not need explicit action privilege
	ELSE
		g_CAN_UPDATE_RESTRICTED_DATA := CAN_UPDATE_RESTRICTED_DATA(p_ROLES);
	END IF;

END SET_CURRENT_ROLES;
-----------------------------------------------------------------------------
PROCEDURE FETCH_ROLES(p_FORCE IN BOOLEAN) AS
v_STALENESS NUMBER := SYSDATE - g_LAST_ROLE_FETCH_TIME;
v_QUERY_THEM BOOLEAN := p_FORCE;
v_ROLES ID_TABLE;
BEGIN
	-- if we are not forcing a re-query of roles, then see if we actually need to
	IF NOT p_FORCE THEN
		-- role staleness is null? then roles never get stale
		IF g_ROLE_STALENESS_LIMIT IS NOT NULL THEN
			-- haven't yet fetched them? then get them
			IF g_LAST_ROLE_FETCH_TIME IS NULL THEN
				v_QUERY_THEM := TRUE;
			ELSE
				v_QUERY_THEM := v_STALENESS > g_ROLE_STALENESS_LIMIT;
			END IF;
		END IF;
	END IF;

	IF v_QUERY_THEM THEN
    	--Set up the list of roles available to the user.
    	SELECT ID_TYPE(UR.ROLE_ID)
    	BULK COLLECT INTO v_ROLES
    	FROM APPLICATION_USER_ROLE UR
		WHERE UR.USER_ID = g_CURRENT_USER_ID;

		SET_CURRENT_ROLES(v_ROLES, FALSE);

		g_LAST_ROLE_FETCH_TIME := SYSDATE;
	END IF;
END FETCH_ROLES;
---------------------------------------------------------------------------------------------------
PROCEDURE RELOAD_CURRENT_ROLES AS
BEGIN
	FETCH_ROLES(TRUE);
END RELOAD_CURRENT_ROLES;
---------------------------------------------------------------------------------------------------
FUNCTION CURRENT_USER RETURN VARCHAR2 IS
v_CURRENT_USER_NAME APPLICATION_USER.USER_NAME%TYPE := NULL;
BEGIN
	SELECT MAX(USER_NAME)
	INTO v_CURRENT_USER_NAME
	FROM APPLICATION_USER
	WHERE USER_ID = g_CURRENT_USER_ID;

	RETURN v_CURRENT_USER_NAME;
END CURRENT_USER;
---------------------------------------------------------------------------------------------------
-- Answer the user display name if present, defaulting to the user name
-- if the display name is not present.
-- %return VARCHAR2 NVL(USER_DISPLAY_NAME,USER_NAME)
FUNCTION GET_CURRENT_USER_DISPLAY_NAME RETURN VARCHAR2 IS
    v_CURRENT_USER_DISPLAY_NAME APPLICATION_USER.USER_NAME%TYPE;
BEGIN
    SELECT NVL(AU.USER_DISPLAY_NAME, AU.USER_NAME)
	INTO v_CURRENT_USER_DISPLAY_NAME
	FROM APPLICATION_USER AU
	WHERE USER_ID = g_CURRENT_USER_ID;
	
	RETURN v_CURRENT_USER_DISPLAY_NAME;
END GET_CURRENT_USER_DISPLAY_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION CURRENT_USER_ID RETURN NUMBER IS
BEGIN
	RETURN g_CURRENT_USER_ID;

END CURRENT_USER_ID;
-----------------------------------------------------------------------------
PROCEDURE SAVE_CURRENT_USER AS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    UPDATE CURRENT_SESSION_USER SET USER_ID = g_CURRENT_USER_ID;
    IF SQL%NOTFOUND THEN
	    INSERT INTO CURRENT_SESSION_USER (USER_ID) VALUES (g_CURRENT_USER_ID);
    END IF;

    COMMIT;
END SAVE_CURRENT_USER;
-----------------------------------------------------------------------------
PROCEDURE SET_CURRENT_USER_ID(p_USER_ID IN NUMBER, p_UPDATE_TBL IN BOOLEAN) AS
BEGIN

	g_CURRENT_USER_ID := p_USER_ID;
	IF p_UPDATE_TBL THEN
		SAVE_CURRENT_USER;
	END IF;

	FETCH_ROLES(TRUE);

END SET_CURRENT_USER_ID;
-----------------------------------------------------------------------------
PROCEDURE SET_CURRENT_USER(p_USER_NAME IN VARCHAR2, p_UPDATE_TBL IN BOOLEAN) AS
v_USER_ID APPLICATION_USER.USER_ID%TYPE;
BEGIN

	SELECT MAX(USER_ID)
	INTO v_USER_ID
	FROM APPLICATION_USER
	WHERE UPPER(USER_NAME) = UPPER(p_USER_NAME)
		AND IS_DISABLED = 0;

	-- if v_USER_NAME is NULL (i.e. no enabled user matches specified user name) then
	-- this will result in no roles and blank user-name in session's client info

	SET_CURRENT_USER_ID(v_USER_ID, p_UPDATE_TBL);

	DBMS_APPLICATION_INFO.SET_CLIENT_INFO(p_USER_NAME||'@'||APP_SCHEMA_NAME);

END SET_CURRENT_USER;
-----------------------------------------------------------------------------
PROCEDURE SET_CURRENT_USER(p_USER_NAME IN VARCHAR2) AS
BEGIN
	SET_CURRENT_USER(p_USER_NAME,TRUE);
END SET_CURRENT_USER;
-----------------------------------------------------------------------------
FUNCTION CURRENT_ROLES RETURN ID_TABLE IS
BEGIN
	FETCH_ROLES(FALSE); -- this will re-query roles if necessary
	RETURN g_CURRENT_ROLES;
END CURRENT_ROLES;
-----------------------------------------------------------------------------
PROCEDURE SET_CURRENT_ROLES(p_ROLES IN ID_TABLE) IS
BEGIN
	SET_CURRENT_ROLES(p_ROLES, TRUE); -- pass true to allow stale roles - meaning
						-- that roles programmatically set this way will remain
						-- in effect until another call to SET_CURRENT_ROLES or
						-- to SET_CURRENT_USER. If roles are not set this way (i.e.
						-- they are queried based on the current user) then the set
						-- of roles may be periodically re-queried (to avoid "staleness")
END SET_CURRENT_ROLES;
-------------------------------------------------------------------------------------------------
FUNCTION IS_SUPER_USER RETURN NUMBER IS
BEGIN
	FETCH_ROLES(FALSE); -- this will re-query roles if necessary
	IF g_IS_SUPER_USER THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END IS_SUPER_USER;
-------------------------------------------------------------------------------------------------
FUNCTION CAN_UPDATE_RESTRICTED_DATA RETURN NUMBER IS
BEGIN
	FETCH_ROLES(FALSE); -- this will re-query roles if necessary
	IF g_CAN_UPDATE_RESTRICTED_DATA THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END CAN_UPDATE_RESTRICTED_DATA;
-------------------------------------------------------------------------------------------------
PROCEDURE RAISE_CANT_DELETE_ERROR
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2,
	p_ERR_DESC IN VARCHAR2
	) AS
BEGIN
	ERRS.RAISE(MSGCODES.c_ERR_CANNOT_DELETE_ENTITY,
				TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_DOMAIN_ID, EC.ED_ENTITY_DOMAIN) ||' "'||p_ENTITY_NAME||'" '||p_ERR_DESC
				);
END RAISE_CANT_DELETE_ERROR;
-------------------------------------------------------------------------------------------------
PROCEDURE RAISE_REF_ERROR
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2,
	p_REF_DESC IN VARCHAR2
	) AS
BEGIN
	RAISE_CANT_DELETE_ERROR(p_ENTITY_DOMAIN_ID, p_ENTITY_NAME, 'is still referenced by '||p_REF_DESC);
END RAISE_REF_ERROR;
-------------------------------------------------------------------------------------------------
PROCEDURE BURY_ENTITY
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2
	) AS
v_ENTITY_TYPE	CHAR(1);
v_OBJECT_NAME 	VARCHAR2(256);
v_COMPONENT_ID  NUMBER(9);
v_ENTITY_GROUP_ID ENTITY_GROUP.ENTITY_GROUP_ID%TYPE;
v_INCLUDE_CONTACT_ADDRESS ENTITY_DOMAIN.INCLUDE_CONTACT_ADDRESS%TYPE;
BEGIN
	-- First validate:

	-- raise an exception if this is a "reserved" entity (ID < 100)
	IF p_ENTITY_ID < 100 THEN
		RAISE_CANT_DELETE_ERROR(p_ENTITY_DOMAIN_ID, p_ENTITY_NAME, 'is a reserved entity and cannot be deleted from the system');
	END IF;

	-- raise an exception if there are any outstanding references from tables w/out
	-- foreign keys (i.e. generic references that use entity_domain_id and entity_id)
	-- other than from child tables:

	-- Formula charge references
	IF p_ENTITY_DOMAIN_ID <> EC.ED_COMPONENT THEN
		-- A component cannot be referenced from within an input, so it is
		-- not necessary to call this step when deleting a component.  It was
		-- causing a "table is mutating" error when it was called.
		IF p_ENTITY_DOMAIN_ID = EC.ED_ENTITY_GROUP THEN
			v_ENTITY_TYPE := 'G';
		ELSIF p_ENTITY_DOMAIN_ID IN (EC.ED_SYSTEM_REALM, EC.ED_CALC_REALM, EC.ED_FORMULA_REALM) THEN
			v_ENTITY_TYPE := 'R';
		ELSE
			v_ENTITY_TYPE := 'E';
		END IF;

		SELECT MAX(COMPONENT_ID), MAX(INPUT_NAME)
		INTO v_COMPONENT_ID, v_OBJECT_NAME
		FROM COMPONENT_FORMULA_INPUT
		WHERE ENTITY_ID = p_ENTITY_ID
			AND ENTITY_TYPE = v_ENTITY_TYPE
			AND (v_ENTITY_TYPE <> 'E' -- ignore domain - we know actual referenced domain just from 'R' or 'G' entity type
					OR ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID)
			AND ROWNUM = 1;

		IF v_OBJECT_NAME IS NOT NULL THEN
			RAISE_REF_ERROR(p_ENTITY_DOMAIN_ID, p_ENTITY_NAME, TEXT_UTIL.TO_CHAR_ENTITY(v_COMPONENT_ID, EC.ED_COMPONENT, TRUE) ||' in formula input:'|| v_OBJECT_NAME || '');
		END IF;

		SELECT MAX(COMPONENT_ID)
		INTO v_COMPONENT_ID
		FROM COMPONENT_FORMULA_RESULT R
		WHERE ENTITY_ID = p_ENTITY_ID
			AND ENTITY_TYPE = v_ENTITY_TYPE
			AND (v_ENTITY_TYPE <> 'E' -- ignore domain - we know actual referenced domain just from 'R' or 'G' entity type
				OR ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID)
			AND ROWNUM = 1;

		IF v_COMPONENT_ID IS NOT NULL THEN
				RAISE_REF_ERROR(p_ENTITY_DOMAIN_ID, p_ENTITY_NAME, TEXT_UTIL.TO_CHAR_ENTITY(v_COMPONENT_ID, EC.ED_COMPONENT, TRUE) ||' in formula result');
		END IF;

		SELECT MAX(COMPONENT_ID), MAX(REFERENCE_NAME)
		INTO v_COMPONENT_ID, v_OBJECT_NAME
		FROM COMPONENT_FORMULA_ENTITY_REF
		WHERE ENTITY_ID = p_ENTITY_ID
			AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND ROWNUM = 1;

		IF v_OBJECT_NAME IS NOT NULL THEN
			RAISE_REF_ERROR(p_ENTITY_DOMAIN_ID, p_ENTITY_NAME, TEXT_UTIL.TO_CHAR_ENTITY(v_COMPONENT_ID, EC.ED_COMPONENT, TRUE) ||' in formula entity reference:' || v_OBJECT_NAME);
		END IF;
	END IF;

	-- Entity Group/Matrix references
	IF p_ENTITY_DOMAIN_ID <> EC.ED_ENTITY_GROUP THEN
		SELECT MAX(G.ENTITY_GROUP_ID)
		INTO v_ENTITY_GROUP_ID
		FROM ENTITY_GROUP_ASSIGNMENT A, ENTITY_GROUP G
		WHERE G.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND A.ENTITY_GROUP_ID = G.ENTITY_GROUP_ID
			AND (A.ENTITY_ID = p_ENTITY_ID OR A.ENTITY2_ID = p_ENTITY_ID
				  OR A.ENTITY3_ID = p_ENTITY_ID OR A.ENTITY4_ID = p_ENTITY_ID
				  OR A.ENTITY4_ID = p_ENTITY_ID OR A.ENTITY6_ID = p_ENTITY_ID
				  OR A.ENTITY7_ID = p_ENTITY_ID OR A.ENTITY8_ID = p_ENTITY_ID
				  OR A.ENTITY9_ID = p_ENTITY_ID OR A.ENTITY10_ID = p_ENTITY_ID)
		AND ROWNUM = 1;

		IF v_ENTITY_GROUP_ID IS NOT NULL THEN
			RAISE_REF_ERROR(p_ENTITY_DOMAIN_ID, p_ENTITY_NAME, TEXT_UTIL.TO_CHAR_ENTITY(v_ENTITY_GROUP_ID, EC.ED_ENTITY_GROUP, TRUE));
		END IF;
	END IF;

	-- NOW, add the entity to the graveyard
	MERGE INTO ENTITY_GRAVEYARD T
	USING (SELECT P_ENTITY_DOMAIN_ID AS ENTITY_DOMAIN_ID,
				  P_ENTITY_ID 		 AS ENTITY_ID,
				  P_ENTITY_NAME 	 AS ENTITY_NAME,
				  SYSDATE 			 AS DELETED_DATE
		   FROM DUAL) S
	ON (T.ENTITY_DOMAIN_ID = S.ENTITY_DOMAIN_ID AND T.ENTITY_ID = S.ENTITY_ID)
	WHEN MATCHED THEN
		UPDATE
		SET T.ENTITY_NAME  = S.ENTITY_NAME,
			T.DELETED_DATE = S.DELETED_DATE
	WHEN NOT MATCHED THEN
		INSERT
			(ENTITY_DOMAIN_ID, ENTITY_ID, ENTITY_NAME, DELETED_DATE)
		VALUES
			(S.ENTITY_DOMAIN_ID, S.ENTITY_ID, S.ENTITY_NAME, S.DELETED_DATE);

	-- and keep track of the realms to which this entity belonged
	INSERT INTO ENTITY_GRAVEYARD_REALM
		(ENTITY_DOMAIN_ID, ENTITY_ID, REALM_ID)
	SELECT p_ENTITY_DOMAIN_ID,
		p_ENTITY_ID,
		REALM_ID
	FROM SYSTEM_REALM_ENTITY
	WHERE ENTITY_ID = p_ENTITY_ID;

	-- Now cleanup child tables that refer to this entity w/out foreign keys
	-- (i.e. generic references that use entity_domain_id and entity_id):

	-- Entity attributes
	DELETE TEMPORAL_ENTITY_ATTRIBUTE
	WHERE OWNER_ENTITY_ID = p_ENTITY_ID
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	-- Contacts and Addresses
	DELETE ENTITY_DOMAIN_ADDRESS
	WHERE OWNER_ENTITY_ID = p_ENTITY_ID
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
	
  -- [BZ 29326] only delete ENTITY_DOMAIN_CONTACT entries for domains that can have contacts
  SELECT INCLUDE_CONTACT_ADDRESS INTO v_INCLUDE_CONTACT_ADDRESS 
  FROM ENTITY_DOMAIN ED
  WHERE ED.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
  IF v_INCLUDE_CONTACT_ADDRESS = 1 THEN
    DELETE ENTITY_DOMAIN_CONTACT
    WHERE OWNER_ENTITY_ID = p_ENTITY_ID
      AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
  END IF;

	-- Entity Note
	DELETE ENTITY_NOTE
	WHERE ENTITY_ID = p_ENTITY_ID
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	-- Data Validatin Rule
	DELETE DATA_VALIDATION_RULE
	WHERE ENTITY_ID = p_ENTITY_ID
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	-- External System identifiers
	IF p_ENTITY_DOMAIN_ID <> EC.ED_EXTERNAL_SYSTEM THEN
		-- external systems are not allowed to have exernal identifiers
		-- because it would cause 'table is mutating' - because the following
		-- delete statement would be issued but external_system_identifier
		-- is mutating due to cascade delete from foreign key to external_system
    	DELETE EXTERNAL_SYSTEM_IDENTIFIER
    	WHERE ENTITY_ID = p_ENTITY_ID
    		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
	END IF;

	-- Contract Assignments
	DELETE CONTRACT_ASSIGNMENT CA
	WHERE CA.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND CA.OWNER_ENTITY_ID = p_ENTITY_ID;

END BURY_ENTITY;
-----------------------------------------------------------------------------
FUNCTION GET_ENCODING_KEY
	RETURN RAW IS
v_RET RAW(32) := NULL;
v_TMP RAW(32);
TYPE BYTE_ARRAY IS VARRAY(32) OF BINARY_INTEGER;
v_K BYTE_ARRAY := BYTE_ARRAY();
v_PRIMES BYTE_ARRAY := BYTE_ARRAY(29, 31, 37, 43, 47, 53, 59, 61, 67, 71,
								  79, 83, 89, 97, 101, 103, 109);
BEGIN
	FOR i IN 1..32 LOOP
		v_K.EXTEND();
		v_K(i) := i-1;
	END LOOP;

	FOR i IN 0..108 LOOP
		v_K(mod(i,32)+1) := CD.BIT_XOR(v_K(mod(i,32)+1), v_PRIMES(mod(i,17)+1));
	END LOOP;

	FOR i IN 1..32 LOOP
		v_TMP := UTL_RAW.CAST_FROM_BINARY_INTEGER(v_K(i), UTL_RAW.LITTLE_ENDIAN);
		v_TMP := UTL_RAW.SUBSTR(v_TMP,1,1);
		v_RET := UTL_RAW.CONCAT(v_RET, v_TMP);
	END LOOP;

	RETURN v_RET;
END GET_ENCODING_KEY;
-----------------------------------------------------------------------------
FUNCTION ENCODE
	(
	p_PLAIN_TXT VARCHAR2
	) RETURN VARCHAR2 IS
BEGIN
	RETURN CD.BASE64ENCODE_FROM_RAW(CD.ENDECRYPT_TO_RAW(p_PLAIN_TXT, GET_ENCODING_KEY));
END ENCODE;
-----------------------------------------------------------------------------
FUNCTION ENCODE
	(
	p_RAW_DATA BLOB
	) RETURN CLOB IS
v_CODED BLOB;
v_RET CLOB;
BEGIN
	v_CODED := CD.ENDECRYPT(p_RAW_DATA, GET_ENCODING_KEY);
	v_RET := CD.BASE64ENCODE(v_CODED);
	IF DBMS_LOB.ISTEMPORARY(v_CODED)=1 THEN
		DBMS_LOB.FREETEMPORARY(v_CODED);
	END IF;
	RETURN v_RET;
END ENCODE;
-----------------------------------------------------------------------------
FUNCTION DECODE
	(
	p_CIPHER_TXT VARCHAR2
	) RETURN VARCHAR2 IS
BEGIN
	RETURN CD.ENDECRYPT_FROM_RAW(CD.BASE64DECODE_TO_RAW(p_CIPHER_TXT), GET_ENCODING_KEY);
END DECODE;
-----------------------------------------------------------------------------
FUNCTION DECODE
	(
	p_CIPHER_TXT CLOB
	) RETURN BLOB IS
v_DECODED BLOB;
v_RET BLOB;
BEGIN
	v_DECODED := CD.BASE64DECODE(p_CIPHER_TXT);
	v_RET := CD.ENDECRYPT(v_DECODED, GET_ENCODING_KEY);
	IF DBMS_LOB.ISTEMPORARY(v_DECODED)=1 THEN
		DBMS_LOB.FREETEMPORARY(v_DECODED);
	END IF;
	RETURN v_RET;
END DECODE;
-----------------------------------------------------------------------------
FUNCTION GET_AVAIL_EXTERNAL_ACCOUNTS
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER
	) RETURN STRING_COLLECTION IS
v_RET STRING_COLLECTION;
BEGIN
	SELECT DISTINCT EXTERNAL_ACCOUNT_NAME
	BULK COLLECT INTO v_RET
	FROM EXTERNAL_CREDENTIALS
	WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
		AND (SECURITY_CONTROLS.CURRENT_USER_ID = USER_ID OR USER_ID IS NULL);

	RETURN v_RET;
END GET_AVAIL_EXTERNAL_ACCOUNTS;
-----------------------------------------------------------------------------
FUNCTION GET_EXTERNAL_CREDENTIAL_ID
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2
	) RETURN NUMBER IS
v_RET NUMBER := NULL;
BEGIN
	-- NULL account name specified? then requestor doesn't care which account - find first one
	IF p_EXTERNAL_ACCOUNT_NAME IS NULL THEN

		-- first try to get credentials as specified
		SELECT MAX(CREDENTIAL_ID)
		INTO v_RET
		FROM (SELECT CREDENTIAL_ID
				FROM EXTERNAL_CREDENTIALS EC
				WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
					AND USER_ID = SECURITY_CONTROLS.CURRENT_USER_ID
				ORDER BY EXTERNAL_ACCOUNT_NAME)
		WHERE ROWNUM=1;

    	-- nothing? then see if any match user-name via wildcard
    	IF v_RET IS NULL THEN
            SELECT MAX(CREDENTIAL_ID)
            INTO v_RET
            FROM (SELECT CREDENTIAL_ID
					FROM EXTERNAL_CREDENTIALS EC
		            WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
    					AND USER_ID IS NULL
					ORDER BY EXTERNAL_ACCOUNT_NAME)
			WHERE ROWNUM=1;
    	END IF;

	ELSE

		-- first try to get credentials as specified
		SELECT MAX(CREDENTIAL_ID)
		INTO v_RET
		FROM EXTERNAL_CREDENTIALS EC
		WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
			AND EXTERNAL_ACCOUNT_NAME = p_EXTERNAL_ACCOUNT_NAME
			AND USER_ID = SECURITY_CONTROLS.CURRENT_USER_ID;
    	-- nothing? then see if any match user-name via wildcard
    	IF v_RET IS NULL THEN
            SELECT MAX(CREDENTIAL_ID)
            INTO v_RET
            FROM (SELECT CREDENTIAL_ID
					FROM EXTERNAL_CREDENTIALS EC
		            WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
						AND EXTERNAL_ACCOUNT_NAME = p_EXTERNAL_ACCOUNT_NAME
    					AND USER_ID IS NULL)
			WHERE ROWNUM=1;
    	END IF;

	END IF;

	-- This will return NULL if no matching credential ID could be found
	RETURN v_RET;
END GET_EXTERNAL_CREDENTIAL_ID;
-----------------------------------------------------------------------------
PROCEDURE GET_EXTERNAL_UNAME_PASSWORD
	(
	p_CREDENTIAL_ID IN NUMBER,
	p_EXTERNAL_USERNAME OUT VARCHAR2,
	p_EXTERNAL_PASSWORD OUT VARCHAR2
	) AS
BEGIN
	SELECT EXTERNAL_USER_NAME, EXTERNAL_PASSWORD
	INTO p_EXTERNAL_USERNAME, p_EXTERNAL_PASSWORD
	FROM EXTERNAL_CREDENTIALS
	WHERE CREDENTIAL_ID = p_CREDENTIAL_ID;
END GET_EXTERNAL_UNAME_PASSWORD;
-----------------------------------------------------------------------------
PROCEDURE GET_EXTERNAL_CERTIFICATE
	(
	p_CREDENTIAL_ID IN NUMBER,
	p_CERTIFICATE_TYPE IN VARCHAR2,
	p_CERT_CONTENTS OUT CLOB,
	p_CERT_PASSWORD OUT VARCHAR2
	) AS
v_CERT_TYPE EXTERNAL_CREDENTIALS_CERT.CERTIFICATE_TYPE%TYPE := NVL(p_CERTIFICATE_TYPE,g_AUTH_CERT_TYPE);
v_EXPIRATION_DATE DATE;
BEGIN
	SELECT MIN(CERTIFICATE_EXPIRATION_DATE)
	INTO v_EXPIRATION_DATE
    FROM EXTERNAL_CREDENTIALS_CERT
    WHERE CREDENTIAL_ID = p_CREDENTIAL_ID
        AND CERTIFICATE_TYPE = v_CERT_TYPE
        AND CERTIFICATE_EXPIRATION_DATE > SYSDATE;

	SELECT CERTIFICATE_CONTENTS, CERTIFICATE_PASSWORD
	INTO p_CERT_CONTENTS, p_CERT_PASSWORD
	FROM EXTERNAL_CREDENTIALS_CERT
	WHERE CREDENTIAL_ID = p_CREDENTIAL_ID
		AND CERTIFICATE_TYPE = v_CERT_TYPE
		AND CERTIFICATE_EXPIRATION_DATE = v_EXPIRATION_DATE;
END GET_EXTERNAL_CERTIFICATE;
-----------------------------------------------------------------------------
FUNCTION START_BACKGROUND_JOB
	(
	p_PLSQL IN VARCHAR2,
	p_RUN_WHEN IN TIMESTAMP WITH TIME ZONE := NULL,
	p_JOB_CLASS IN VARCHAR2 := 'DEFAULT_JOB_CLASS',
	p_COMMENTS IN VARCHAR2 := NULL,
	p_JOB_DATA IN JOB_DATA%ROWTYPE := NULL,
	p_WAIT_FOR_JOB_TO_START IN NUMBER := NULL
	) RETURN VARCHAR2 AS
	
v_WHAT					VARCHAR2(32767);
v_WHEN_DATE				DATE;
v_PROC_NAME				PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
v_STEP_NAME				PROCESS_LOG_EVENT.STEP_NAME%TYPE;
v_EMAIL_TEXT 			VARCHAR2(4000) := '';
v_EXCEPTION_EMAIL_TEXT	VARCHAR2(4000) := '';
v_JOB_DATA 				JOB_DATA%ROWTYPE;
v_MUTEX_IDENT			VARCHAR2(32);
v_WAIT					BOOLEAN := FALSE;

BEGIN

	$if $$UNIT_TEST_MODE = 1 $THEN
		IF UNIT_TEST_UTIL.g_CURRENT_TEST_PROCEDURE LIKE 'TEST_FS.T_RUN_CAST_SERVICE_REQUEST' THEN	
			UT.POST_RTO_WORK(11111 ,1 ,'PLSQL BLOCK: ' || p_PLSQL || ' RUN AT: ' || p_RUN_WHEN);
		END IF;

		RETURN 'TEST_JOB';
	$end

	LOGS.GET_CALLER(v_PROC_NAME, v_STEP_NAME);

	v_JOB_DATA := p_JOB_DATA;
    v_JOB_DATA.USER_ID := NVL(v_JOB_DATA.USER_ID,SECURITY_CONTROLS.CURRENT_USER_ID);

	-- generate job-name that includes the current app-user's ID.
	v_JOB_DATA.JOB_NAME := UT.GENERATE_JOB_NAME(v_JOB_DATA.USER_ID);

	--get a string that can be used to send an email after the job is complete.
	IF v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS IS NOT NULL THEN
		v_EMAIL_TEXT :=
'
	-- send an email when the job is complete.
	ML.MAIL(''Job Completion'', '''||v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS||''', ''Job '||v_JOB_DATA.JOB_NAME||' has completed.'',
		''This is an automated message that Job '||v_JOB_DATA.JOB_NAME||' has completed.'',
		'''||v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS||''');
';
		v_EXCEPTION_EMAIL_TEXT :=
'
		-- send an email if the job encountered an exception.
		ML.MAIL(''Job Error'', '''||v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS||''', ''Job '||v_JOB_DATA.JOB_NAME||' encountered errors.'',
			''This is an automated message that Job '||v_JOB_DATA.JOB_NAME||' encountered errors and may not have completed.'',
			'''||v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS||''');
';
	END IF;

	IF NVL(p_WAIT_FOR_JOB_TO_START,0) > 0 THEN
		IF p_RUN_WHEN IS NULL OR p_RUN_WHEN <= SYSTIMESTAMP AT TIME ZONE DBTIMEZONE THEN
			v_WAIT := TRUE;
			v_MUTEX_IDENT := MUTEX.SYNC_INIT;
		ELSE
			LOGS.LOG_WARN('Waiting for background job to start is not allowed when scheduling background job for future execution.',
							v_PROC_NAME, v_STEP_NAME);
		END IF;
	END IF;
	
	-- wrap the specified PL/SQL in a block that will insure the appropriate session context
	v_WHAT :=
'BEGIN
	-- identify ourselves to the application
	SESSION_START;
	'||CASE WHEN v_WAIT THEN 'MUTEX.SYNC_CHILD('||UT.GET_LITERAL_FOR_STRING(v_MUTEX_IDENT)||');' ELSE NULL END||'
	-- inherit log-level from the session that invoked this job
	LOGS.SET_KEEPING_EVENT_DETAILS('||CASE WHEN LOGS.KEEPING_EVENT_DETAILS THEN 'TRUE' ELSE 'FALSE' END||');
	LOGS.SET_CURRENT_LOG_LEVEL('||UT.GET_LITERAL_FOR_NUMBER(LOGS.CURRENT_LOG_LEVEL)||');
	-- temp trace for a background job doesn''t make much sense - no one would ever be able to view it...
	LOGS.SET_PERSISTING_TRACE(TRUE);
	-- now run the job!
	'||p_PLSQL||v_EMAIL_TEXT||
'
EXCEPTION
	WHEN OTHERS THEN'||v_EXCEPTION_EMAIL_TEXT||
'
	ERRS.LOG_AND_RAISE;
END;';

	-- First Create the job as Disabled, it will be enabled after the Job_Data is set
	DBMS_SCHEDULER.CREATE_JOB(v_JOB_DATA.JOB_NAME, 'PLSQL_BLOCK', v_WHAT,
							 START_DATE => p_RUN_WHEN,
							 JOB_CLASS => NVL(p_JOB_CLASS, 'DEFAULT_JOB_CLASS'),
							 ENABLED => FALSE,
							 AUTO_DROP => TRUE,
							 COMMENTS => p_COMMENTS);
	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Created background job: '||v_JOB_DATA.JOB_NAME, v_PROC_NAME, v_STEP_NAME);
	END IF;

	-- Remove any previous JOB_DATA
	DELETE FROM JOB_DATA D WHERE D.JOB_NAME = v_JOB_DATA.JOB_NAME;

	IF SQL%ROWCOUNT > 0 THEN
		LOGS.LOG_NOTICE('Deleted JOB_DATA for JOB_NAME = ' || v_JOB_DATA.JOB_NAME, v_PROC_NAME, v_STEP_NAME);
	END IF;

	-- Insert new JOB_DATA
	INSERT INTO JOB_DATA VALUES v_JOB_DATA;

	-- Log a Message
	IF p_RUN_WHEN IS NULL THEN
		LOGS.LOG_INFO('Started background job: '||v_JOB_DATA.JOB_NAME, v_PROC_NAME, v_STEP_NAME);
	ELSE
		-- show the time in system time zone
		v_WHEN_DATE := p_RUN_WHEN + (SYSDATE-CURRENT_DATE);
		LOGS.LOG_INFO('Queued background job: '||v_JOB_DATA.JOB_NAME||' -> '||TEXT_UTIL.TO_CHAR_TIME(v_WHEN_DATE), v_PROC_NAME, v_STEP_NAME);
	END IF;

	LOGS.POST_EVENT_DETAILS('Job Definition', CONSTANTS.MIME_TYPE_TEXT, p_PLSQL);
	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.POST_EVENT_DETAILS('Full Job Text *', CONSTANTS.MIME_TYPE_TEXT, v_WHAT);
	END IF;
	IF p_COMMENTS IS NOT NULL THEN
		LOGS.POST_EVENT_DETAILS('Job Comments', CONSTANTS.MIME_TYPE_TEXT, p_COMMENTS);
	END IF;

	-- Enable this job now
	DBMS_SCHEDULER.ENABLE(v_JOB_DATA.JOB_NAME);

	IF v_WAIT THEN
		IF NOT MUTEX.SYNC_PARENT(v_MUTEX_IDENT, p_WAIT_FOR_JOB_TO_START) THEN
			LOGS.LOG_WARN('Background job took too long to start (> '||p_WAIT_FOR_JOB_TO_START||' secs).', v_PROC_NAME, v_STEP_NAME);
		END IF;
	END IF;

	RETURN v_JOB_DATA.JOB_NAME;
END START_BACKGROUND_JOB;
-----------------------------------------------------------------------------
-- Gets the next item in the JOB_QUEUE_ITEM table that belongs to the JOB_THREAD
-- specified by the p_JOB_THREAD_ID.
-- p_JOB_THREAD_ID must not be NULL.
-- The next item is determined by the ITEM_ORDER in the JOB_QUEUE_ITEM table.
PROCEDURE DEQUEUE_BY_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER
	) AS

v_JOB_DATA JOB_DATA%ROWTYPE;
v_JOB_CLASS JOB_THREAD.JOB_CLASS%TYPE;
v_NEXT_JOB_QUEUE_ITEM JOB_QUEUE_ITEM%ROWTYPE;
v_PLSQL JOB_QUEUE_ITEM.PLSQL%TYPE;
DUMMY VARCHAR2(64); -- for job name, which is unused

BEGIN
	-- Abort if the p_JOB_THREAD_ID is null
	ASSERT(p_JOB_THREAD_ID IS NOT NULL, 'p_JOB_THREAD_ID must be set to a non-null value.');

	BEGIN
		SELECT *
		INTO v_NEXT_JOB_QUEUE_ITEM
		FROM (SELECT I.*
			  FROM JOB_QUEUE_ITEM I, JOB_THREAD T
			  WHERE I.JOB_THREAD_ID = T.JOB_THREAD_ID
			  	AND T.JOB_THREAD_ID = p_JOB_THREAD_ID
				AND T.IS_SNOOZED = 0
			  ORDER BY ITEM_ORDER ASC)
		WHERE ROWNUM = 1;

		-- Get the Job Class for the selected Job Thread (if there is one).
		SELECT MAX(CASE WHEN JOB_CLASS = '?' THEN NULL ELSE JOB_CLASS END)
		INTO v_JOB_CLASS
		FROM JOB_THREAD
		WHERE JOB_THREAD_ID = p_JOB_THREAD_ID;

		-- Append a call to DEQUEUE to the PLSQL string
		v_PLSQL :=
'BEGIN
	BEGIN
		-- START original PLSQL block
		'||v_NEXT_JOB_QUEUE_ITEM.PLSQL||'
		-- END original PLSQL block
	EXCEPTION
		WHEN OTHERS THEN
			ERRS.LOG_AND_CONTINUE;
	END;
	-- Call Dequeue to process the next item
	SECURITY_CONTROLS.DEQUEUE_BY_JOB_THREAD('||p_JOB_THREAD_ID||');
END;';

		v_JOB_DATA.ACTION_CHAIN_NAME := 'Job Threads';
		v_JOB_DATA.USER_ID := v_NEXT_JOB_QUEUE_ITEM.USER_ID;
		v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS := v_NEXT_JOB_QUEUE_ITEM.NOTIFICATION_EMAIL_ADDRESS;
		v_JOB_DATA.JOB_THREAD_ID := p_JOB_THREAD_ID;

		-- Start the Background job.
		DUMMY := START_BACKGROUND_JOB(v_PLSQL,
										   NULL,
										   v_JOB_CLASS,
										   v_NEXT_JOB_QUEUE_ITEM.COMMENTS,
										   v_JOB_DATA);

		-- Remove the item from the Queue
		DELETE FROM JOB_QUEUE_ITEM WHERE JOB_QUEUE_ITEM_ID = v_NEXT_JOB_QUEUE_ITEM.JOB_QUEUE_ITEM_ID;

	EXCEPTION
    	WHEN NO_DATA_FOUND THEN
        	LOGS.LOG_INFO('No job items in the queue for JOB_THREAD: ID=' || p_JOB_THREAD_ID || ',NAME=' || EI.GET_ENTITY_NAME(EC.ED_JOB_THREAD, p_JOB_THREAD_ID, 1));

END;

END DEQUEUE_BY_JOB_THREAD;
-----------------------------------------------------------------------------
PROCEDURE ENFORCE_LOCK_STATE
	(
	p_LOCK_STATE IN CHAR
	) AS
BEGIN
	IF p_LOCK_STATE = 'L' OR (p_LOCK_STATE = 'R' AND CAN_UPDATE_RESTRICTED_DATA = 0) THEN
		ERRS.RAISE(MSGCODES.c_ERR_DATA_LOCKED);
	END IF;
END ENFORCE_LOCK_STATE;
-----------------------------------------------------------------------------
FUNCTION GET_EFFECTIVE_LOCK_STATE(p_LOCK_STATE IN CHAR, p_LOCKING_ENABLED IN NUMBER := 1) RETURN CHAR IS
BEGIN
	IF NOT UT.BOOLEAN_FROM_NUMBER(p_LOCKING_ENABLED) THEN
		RETURN 'U';
	ELSE
		RETURN CASE WHEN SECURITY_CONTROLS.CAN_UPDATE_RESTRICTED_DATA = 0 AND p_LOCK_STATE = 'R' THEN 'L' ELSE NVL(p_LOCK_STATE,'U') END;
	END IF;
END GET_EFFECTIVE_LOCK_STATE;
-------------------------------------------------------------------------------------------------
PROCEDURE INIT_PARALLEL_SESSION AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	IF IS_PARALLEL_CHILD_SESSION THEN
		SESSION_START;
		COMMIT;
	END IF;
END INIT_PARALLEL_SESSION;
-------------------------------------------------------------------------------------------------
PROCEDURE FINISH_PARALLEL_SESSION AS
	PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
	IF IS_PARALLEL_CHILD_SESSION THEN
		SESSION_END;
		LOGS.FINISH_PARALLEL_CHILD_PROCESS;
		COMMIT;
	END IF;
END FINISH_PARALLEL_SESSION;
-------------------------------------------------------------------------------------------------

BEGIN
	-- Load current user-name and roles
	DECLARE
		v_CURRENT_USER_ID CURRENT_SESSION_USER.USER_ID%TYPE;
	BEGIN
		SELECT USER_ID INTO v_CURRENT_USER_ID FROM CURRENT_SESSION_USER;

		SET_CURRENT_USER_ID(v_CURRENT_USER_ID,FALSE);

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			g_CURRENT_USER_ID := NULL;
			g_CURRENT_ROLES := NULL;
	END;
END SECURITY_CONTROLS;
/
