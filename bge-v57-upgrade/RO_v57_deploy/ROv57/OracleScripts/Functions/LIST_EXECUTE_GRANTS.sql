CREATE OR REPLACE FUNCTION LIST_EXECUTE_GRANTS
	(
	p_USER_OR_ROLE_NAME IN VARCHAR2
	) RETURN STRING_COLLECTION PIPELINED IS

--Revision: $Revision: 1.3 $

v_STACK VARCHAR2(4000);
v_IDX1 BINARY_INTEGER;
v_IDX2 BINARY_INTEGER;
v_OWNER VARCHAR2(64);

CURSOR c_OBJS IS
	SELECT OBJECT_TYPE,
			OBJECT_NAME
	FROM ALL_OBJECTS A
	WHERE OWNER = v_OWNER
		AND OBJECT_TYPE IN ('PACKAGE','FUNCTION','PROCEDURE')
		AND NOT EXISTS (SELECT 1 FROM GRANT_EXECUTE_EXCLUSIONS X WHERE A.OBJECT_TYPE = X.OBJECT_TYPE AND A.OBJECT_NAME LIKE X.OBJECT_NAME)
	ORDER BY 1, 2;

BEGIN
	ASSERT(NOT p_USER_OR_ROLE_NAME IS NULL, 'A user or role name *must* be specified');

-- NOTE: This procedure can*not* reference any other stored procedure, function or package.
-- This is because referencing them essentially locks them. This means that, for instance, if
-- the UT package is referenced then when it comes time to grant execute on UT to the named
-- user or role, the session will hang - waiting for the lock on UT to disappear. But the lock
-- won't disappear until this procedure finishes executing... i.e. deadlock. So to avoid
-- deadlock, this procedure should not reference any other procedure or function.


	-- since we cannot reference function APP_SCHEMA_NAME, reproduce logic here
    v_STACK := DBMS_UTILITY.FORMAT_CALL_STACK;
    v_IDX1 := INSTR(v_STACK, '.LIST_EXECUTE_GRANTS'); -- we know we are executing this
    v_IDX2 := INSTR(v_STACK, ' ', -LENGTH(v_STACK)+v_IDX1);
    v_OWNER := SUBSTR(v_STACK, v_IDX2+1, v_IDX1-v_IDX2-1);


	-- Now grant execute on all packages, procedures, and functions (aside from
	-- exclusions) to the named user or role:

	-- Exclusions include any sensitive PL/SQL that could allow a user to manipulate
	-- their security environment, granting themselves illegitimate access, raising their
	-- access level, or spoofing their identity. These are stored in a table named
	-- GRANT_EXECUTE_EXCLUSIONS.

	FOR v_OBJ IN c_OBJS LOOP
		PIPE ROW('GRANT EXECUTE ON '||v_OWNER||'.'||v_OBJ.OBJECT_NAME||' TO '||p_USER_OR_ROLE_NAME);
	END LOOP;

	-- Done!
	RETURN;
END LIST_EXECUTE_GRANTS;
/
