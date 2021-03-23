CREATE OR REPLACE FUNCTION LIST_REVOKES
	(
	p_TARGET_USER_OR_ROLE_NAME IN VARCHAR2
	) RETURN STRING_COLLECTION PIPELINED IS

--Revision: $Revision: 1.2 $

v_TARGET_NAME VARCHAR2(128) := TRIM(p_TARGET_USER_OR_ROLE_NAME);
CURSOR c_GRANTS IS
	SELECT GRANTOR, TABLE_NAME, PRIVILEGE
	FROM USER_TAB_PRIVS_MADE
	WHERE GRANTEE = v_TARGET_NAME;

BEGIN

	-- First revoke existing privileges
	IF SUBSTR(v_TARGET_NAME,1,1) = '"' THEN
		-- parse out the mixed-case name
		v_TARGET_NAME := REPLACE(v_TARGET_NAME,'~','~tilde;');
		v_TARGET_NAME := REPLACE(v_TARGET_NAME,'""','~quot;');
		v_TARGET_NAME := REPLACE(v_TARGET_NAME,'"',NULL);
		v_TARGET_NAME := REPLACE(v_TARGET_NAME,'~quot;','"');
		v_TARGET_NAME := REPLACE(v_TARGET_NAME,'~tilde;','~');
	ELSE
		v_TARGET_NAME := UPPER(v_TARGET_NAME);
	END IF;
	
	FOR v_GRANT IN c_GRANTS LOOP
		PIPE ROW('REVOKE '||v_GRANT.PRIVILEGE||' ON '||v_GRANT.GRANTOR||'.'||v_GRANT.TABLE_NAME||' FROM '||p_TARGET_USER_OR_ROLE_NAME);
	END LOOP;

	RETURN;
END LIST_REVOKES;
/
