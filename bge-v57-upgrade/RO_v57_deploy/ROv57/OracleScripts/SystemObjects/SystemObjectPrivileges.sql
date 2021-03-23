declare

	v_admin_obj_id	System_Object.Object_Id%Type := -1;
	v_roles			ut.string_map;
	------------------------------------------------------------------------------------------
	procedure insert_privilege_by_role_id (
		p_object_id in number,
		p_role_id in number,
		p_role_privilege in number
		) as
	begin

		insert into system_object_privilege (object_id, role_id, role_privilege, do_not_inherit, create_date)
			values (p_object_id, p_role_id, p_role_privilege, 0, sysdate);

	exception
		when dup_val_on_index then
			null; -- ignore - if entry already exists, leave it
	end insert_privilege_by_role_id;
	------------------------------------------------------------------------------------------
	procedure insert_privilege (
		p_object_id in number,
		p_role_name in varchar2,
		p_role_privilege in number
		) as
	v_role_id number;
	begin
		if v_roles.exists(p_role_name) then
			v_role_id := to_number(v_roles(p_role_name));
		else
			select role_id 
			into v_role_id
			from application_role
			where role_alias = p_role_name;
			
			v_roles(p_role_name) := v_role_id;
		end if;
		
		insert_privilege_by_role_id(p_object_id, v_role_id, p_role_privilege);
	
	exception
		when no_data_found then
			null; -- ignore - if role does not exist, forget about it
	end insert_privilege;
	------------------------------------------------------------------------------------------
begin

    -- Default Privileges for Top Level System Object
    -- Top Level System Object Id = 0

    insert_privilege_by_role_id(0, security_controls.g_super_user_role_id, 9);
    insert_privilege(0, 'Administrator', 9);
    insert_privilege(0, 'Read-Only', 3);
    insert_privilege(0, 'User', 3);
    insert_privilege(0, 'Power-User', 6);

    -- Now disable access to Admin module and layout for all roles but admin and super-user        

    begin
        select a.object_id 
        into v_admin_obj_id
        from System_Object a
        where a.object_category = 'Module'
              and a.object_name = 'Admin';
    exception
        when others then
            v_admin_obj_id := -1;
    end;
    
    if v_admin_obj_id > 0 then
        -- Default Privileges for Read-Only, User, and Power-Users
        -- is to prevent access to Admin module
		insert_privilege(v_admin_obj_id, 'Read-Only', 0);
		insert_privilege(v_admin_obj_id, 'User', 0);
		insert_privilege(v_admin_obj_id, 'Power-User', 0);
	end if;

    begin
        select a.object_id 
        into v_admin_obj_id
        from System_Object a
        where a.object_category = 'Layout'
              and a.object_name = 'ADMIN';
    exception
        when others then
            v_admin_obj_id := -1;
    end;
    
    if v_admin_obj_id > 0 then
        -- Default Privileges for Read-Only, User, and Power-Users
        -- is to prevent access to Admin module
		insert_privilege(v_admin_obj_id, 'Read-Only', 0);
		insert_privilege(v_admin_obj_id, 'User', 0);
		insert_privilege(v_admin_obj_id, 'Power-User', 0);
	end if;
	
	begin
        v_ADMIN_OBJ_ID :=  
			SO.GET_OBJECT_ID_FOR_PATH('Module|Common/System View|Common.EntityManager/Report|ENTITY_MANAGER/Report Filter|POPULATE_TEMPLATE_DATES');
    exception
        when others then
            v_admin_obj_id := -1;
    end;
    
    if v_admin_obj_id > 0 then
        -- Default Privileges for Read-Only, User, and Power-Users
        -- is to prevent access to Admin module
		insert_privilege(v_admin_obj_id, 'Read-Only', 0);
		insert_privilege(v_admin_obj_id, 'User', 0);
		insert_privilege(v_admin_obj_id, 'Power-User', 0);
	end if;
	
	begin
        v_ADMIN_OBJ_ID :=  
			SO.GET_OBJECT_ID_FOR_PATH('Module|Common/System View|Common.ProductsAndRates/Report|PRODUCTS_AND_RATES/Report Filter|POPULATE_TEMPLATE_DATES');
    exception
        when others then
            v_admin_obj_id := -1;
    end;
    
    if v_admin_obj_id > 0 then
        -- Default Privileges for Read-Only, User, and Power-Users
        -- is to prevent access to Admin module
		insert_privilege(v_admin_obj_id, 'Read-Only', 0);
		insert_privilege(v_admin_obj_id, 'User', 0);
		insert_privilege(v_admin_obj_id, 'Power-User', 0);
	end if;
    
    commit;

end;
/

