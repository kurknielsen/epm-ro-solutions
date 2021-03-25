create or replace trigger SYSTEM_ACTION_UPDATE
  before update on system_action
  for each row
begin
    IF SECURITY_CONTROLS.IS_SUPER_USER != 1 THEN
        -- If in an update, the entity Domain is changed, then
        -- 1. Check if the ENTITY_DOMAIN_ID is changed to -1.
        -- then no need to delete or make any changes in the SYSTEM_ACTION_ROLE
        -- 2. If ENITYT_DOMAIN_ID is changed to something other than -1.
        -- then scan through SYSTEM_ACTION_ROLE for rows with ACTION_ID
        -- then delete all rows whose ENTITY_DOMAIN_ID != :new.ENTITY_DOMAIN_ID
        IF :old.ENTITY_DOMAIN_ID <> :new.ENTITY_DOMAIN_ID THEN
        	IF :new.ENTITY_DOMAIN_ID != -1 THEN
            	DELETE
                FROM SYSTEM_ACTION_ROLE A
                WHERE A.ACTION_ID = :new.ACTION_ID
                	and A.ENTITY_DOMAIN_ID != :new.ENTITY_DOMAIN_ID;
            END IF;
        END IF;


    END IF;
end SYSTEM_ACTION_UPDATE;
/
