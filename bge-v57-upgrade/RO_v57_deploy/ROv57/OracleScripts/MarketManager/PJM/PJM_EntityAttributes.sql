DECLARE
	v_ATTRIBUTE_ID NUMBER(9);
BEGIN
    
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: PopulateFromRTDailyTx', EC.ED_TRANSACTION, 'Boolean', TRUE, v_ATTRIBUTE_ID);
 
    -- Resource identifiers (for PJM generators)
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM_PNODEID', EC.ED_SUPPLY_RESOURCE, 'String', TRUE, v_ATTRIBUTE_ID);
    ID.ID_FOR_ENTITY_ATTRIBUTE('UNIT_TYPE', EC.ED_SUPPLY_RESOURCE, 'String', TRUE, v_ATTRIBUTE_ID);
    
    --eSuite access permissions
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMKT Gen', EC.ED_INTERCHANGE_CONTRACT, 'String', TRUE, v_ATTRIBUTE_ID);
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMKT Load', EC.ED_INTERCHANGE_CONTRACT, 'String', TRUE, v_ATTRIBUTE_ID);
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eSchedules', EC.ED_INTERCHANGE_CONTRACT, 'String', TRUE, v_ATTRIBUTE_ID);
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eMTR', EC.ED_INTERCHANGE_CONTRACT, 'String', TRUE, v_ATTRIBUTE_ID);
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eFTR', EC.ED_INTERCHANGE_CONTRACT, 'String', TRUE, v_ATTRIBUTE_ID);
    ID.ID_FOR_ENTITY_ATTRIBUTE('PJM: eRPM', EC.ED_INTERCHANGE_CONTRACT, 'String', TRUE, v_ATTRIBUTE_ID);
    
    commit;
END;
/

