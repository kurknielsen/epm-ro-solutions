DECLARE

v_ID NUMBER(9);
v_COUNT BINARY_INTEGER;

BEGIN

	select count(1)
	into v_COUNT
	from application_user_role r, application_user u
	where r.role_id = security_controls.g_SUPER_USER_ROLE_ID
		and u.user_id = r.user_id
		and u.is_disabled = 0
		and u.is_system_user = 0;

	-- no super-user? then create one
	IF v_COUNT = 0 THEN

		SELECT COUNT(1)
		INTO v_COUNT
		FROM APPLICATION_USER
		WHERE USER_NAME = 'ventyxadmin';

		-- only create the user if it doesn't already exist
		IF v_COUNT = 0 THEN
			-- Get a new id
			SELECT OID.NEXTVAL INTO v_ID FROM DUAL;
			    
			-- insert neaadmin user
			INSERT INTO APPLICATION_USER
				(USER_ID, USER_NAME, USER_DISPLAY_NAME, ENTRY_DATE)
			VALUES
				(v_ID, 'ventyxadmin', 'Ventyx Admin', SYSDATE);
			    
			-- add super user role  
			INSERT INTO APPLICATION_USER_ROLE (USER_ID, ROLE_ID, ENTRY_DATE) VALUES (v_ID, SECURITY_CONTROLS.g_SUPER_USER_ROLE_ID, SYSDATE);
		END IF;

	END IF;

	
END;
/
