-- If you are planning to change this script, apply the same change to the SU.sql scripts used in the following locations:
-- RetailOffice\Database\MAIN\System\SU.sql
-- RetailOffice\Database\MINT\SEM\SU.sql
-- RetailOffice\Database\MINT\TDIE\SU.sql
declare
    v_SU_USER_NAME APPLICATION_USER.USER_NAME%TYPE := 'System';
begin
    SECURITY_CONTROLS.SET_CURRENT_USER(v_SU_USER_NAME);
    ASSERT(SECURITY_CONTROLS.IS_SUPER_USER = 1, 'The current user ''' || v_SU_USER_NAME || ''' is not a super-user.');
end;
/
