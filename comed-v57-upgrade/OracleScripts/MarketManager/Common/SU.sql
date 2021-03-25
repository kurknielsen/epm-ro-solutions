declare
	v_SU_ROLE_ID ID_TABLE := ID_TABLE(ID_TYPE(SECURITY_CONTROLS.g_SUPER_USER_ROLE_ID));
	v_SU_USER_NAME APPLICATION_USER.USER_NAME%TYPE;
begin
	select u.user_name
	into v_SU_USER_NAME
	from application_user_role r, application_user u
	where r.role_id = security_controls.g_SUPER_USER_ROLE_ID
		and u.user_id = r.user_id
		and u.is_disabled = 0
		and u.is_system_user = 0
		and rownum = 1;

	-- pick first super-user and enable it
	SECURITY_CONTROLS.SET_CURRENT_USER(v_SU_USER_NAME);

exception
	when others then
		-- fall back to just setting current role-list
		SECURITY_CONTROLS.SET_CURRENT_ROLES(v_SU_ROLE_ID);
end;
/
