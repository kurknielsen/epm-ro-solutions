DECLARE
	v_ID NUMBER(9);
BEGIN

	--Create the Entity Attributes that do not exist.
	ID.ID_FOR_ENTITY_ATTRIBUTE(MM_TDIE_UTIL.g_EA_CCL_RELIEF_PCT, EC.ED_ACCOUNT, 'Float', TRUE, v_ID);
	
	COMMIT;
END;
/
