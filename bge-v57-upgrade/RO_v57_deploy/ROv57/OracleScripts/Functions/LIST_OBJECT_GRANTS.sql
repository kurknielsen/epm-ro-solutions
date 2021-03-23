CREATE OR REPLACE FUNCTION LIST_OBJECT_GRANTS
	(
	p_TARGET_USER_OR_ROLE_NAME IN VARCHAR2,
	p_SOURCE_USER_OR_ROLE_NAME IN VARCHAR2 := NULL,
	p_SOURCE_IS_USER IN NUMBER := 1
	) RETURN STRING_COLLECTION PIPELINED IS

--Revision: $Revision: 1.3 $

/*v_STACK VARCHAR2(4000);
v_IDX1 BINARY_INTEGER;
v_IDX2 BINARY_INTEGER;*/
v_OWNER VARCHAR2(64);
v_NEW_ROLES ID_TABLE;
v_PREV_ROLES ID_TABLE := NULL;
v_SOURCE_USER_OR_ROLE_NAME APPLICATION_USER.USER_NAME%TYPE := NVL(p_SOURCE_USER_OR_ROLE_NAME,p_TARGET_USER_OR_ROLE_NAME);

CURSOR c_OBJS IS
	SELECT OBJECT_TYPE, OBJECT_NAME,
		CASE WHEN UPPER(OBJECT_TYPE) = 'VIEW' THEN 'SELECT'
			ELSE CASE PRIV WHEN 1 THEN 'SELECT'
    				  WHEN 2 THEN 'SELECT, INSERT, UPDATE'
    				  WHEN 3 THEN 'SELECT, INSERT, UPDATE, DELETE'
    				  END
			END as PRIV
	FROM (SELECT OBJECT_TYPE,
    			OBJECT_NAME,
    			MAX(CASE WHEN SD.HAS_DATA_LEVEL_ACCESS('Delete ' || UPPER(A.DOMAIN_NAME), NULL) = 1 THEN 3
    					 WHEN SD.HAS_DATA_LEVEL_ACCESS('Update ' || UPPER(A.DOMAIN_NAME), NULL) = 1 THEN 2
    					 WHEN SD.HAS_DATA_LEVEL_ACCESS('Select ' || UPPER(A.DOMAIN_NAME), NULL) = 1 THEN 1
    					 ELSE 0
    					 END) as PRIV
    	FROM GRANT_OBJECTS A
    	GROUP BY OBJECT_TYPE, OBJECT_NAME)
	WHERE PRIV <> 0
	ORDER BY 1, 2;

BEGIN
	ASSERT(NOT p_TARGET_USER_OR_ROLE_NAME IS NULL, 'A target user or role name *must* be specified');

-- NOTE: This procedure can*not* perform any DML.
-- This is because DML may result in row locks on the table. This means that, for instance, if
-- the ACCOUNT table is updated then when it comes time to grant access on ACCOUNT to the named
-- user or role, the session will hang - waiting for the lock on ACCOUNT to disappear. But the lock
-- won't disappear until this procedure finishes executing... i.e. deadlock. So to avoid
-- deadlock, this procedure should not perform any DML.

	v_PREV_ROLES := SECURITY_CONTROLS.CURRENT_ROLES;
	IF v_PREV_ROLES IS NULL THEN
		v_PREV_ROLES := ID_TABLE();
	END IF;
	v_OWNER := APP_SCHEMA_NAME;

	-- update current roles so that we see privileges as would the named user or role
	IF NVL(p_SOURCE_IS_USER,1) <> 0 THEN
		SELECT ID_TYPE(UR.ROLE_ID)
		BULK COLLECT INTO v_NEW_ROLES
		FROM APPLICATION_USER U, APPLICATION_USER_ROLE UR
		WHERE U.USER_NAME = v_SOURCE_USER_OR_ROLE_NAME
			AND UR.USER_ID = U.USER_ID;
	ELSE
		SELECT ID_TYPE(R.ROLE_ID)
		BULK COLLECT INTO v_NEW_ROLES
		FROM APPLICATION_ROLE R
		WHERE R.ROLE_NAME = v_SOURCE_USER_OR_ROLE_NAME;
	END IF;

	SECURITY_CONTROLS.SET_CURRENT_ROLES(v_NEW_ROLES);

	-- Now grant access to all objects in the GRANT_OBJECTS table. These are objects to which
	-- direct access may be required by the VB components.

	FOR v_OBJ IN c_OBJS LOOP
		PIPE ROW('GRANT '||v_OBJ.PRIV||' ON '||v_OWNER||'.'||v_OBJ.OBJECT_NAME||' TO '||p_TARGET_USER_OR_ROLE_NAME);
	END LOOP;

    -- do NOT forget to restore roles!
    SECURITY_CONTROLS.SET_CURRENT_ROLES(v_PREV_ROLES);

	-- Done!
	RETURN;

EXCEPTION
	WHEN OTHERS THEN
		IF v_PREV_ROLES IS NOT NULL THEN
			-- do NOT forget to restore roles!
			SECURITY_CONTROLS.SET_CURRENT_ROLES(v_PREV_ROLES);
		END IF;
		RAISE;
END LIST_OBJECT_GRANTS;
/
