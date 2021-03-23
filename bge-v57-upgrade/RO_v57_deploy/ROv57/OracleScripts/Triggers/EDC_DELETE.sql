CREATE OR REPLACE TRIGGER EDC_DELETE
	AFTER DELETE ON ENERGY_DISTRIBUTION_COMPANY
	FOR EACH ROW
BEGIN
	DELETE ACCOUNT_EDC WHERE EDC_ID = :old.EDC_ID;
	DELETE EDC_RATE_CLASS WHERE EDC_ID = :old.EDC_ID;
	DELETE EDC_SYSTEM_UFE_LOAD WHERE EDC_ID = :old.EDC_ID;
	DELETE EDC_LOSS_FACTOR WHERE EDC_ID = :old.EDC_ID;
	DELETE PROVIDER_SERVICE WHERE EDC_ID = :old.EDC_ID;
	DELETE SHADOW_SETTLEMENT WHERE EDC_ID = :old.EDC_ID;
	UPDATE MARKET_PRICE SET EDC_ID = 0 WHERE EDC_ID = :old.EDC_ID;
	UPDATE SERVICE_POINT SET EDC_ID = 0 WHERE EDC_ID = :old.EDC_ID;
	DELETE TEMPORAL_ENTITY_ATTRIBUTE WHERE OWNER_ENTITY_ID = :old.EDC_ID AND ATTRIBUTE_ID IN
		(SELECT A.ATTRIBUTE_ID FROM ENTITY_ATTRIBUTE A, ENTITY_DOMAIN B
		 WHERE UPPER(B.ENTITY_DOMAIN_TABLE_ALIAS) = 'EDC' AND A.ENTITY_DOMAIN_ID = B.ENTITY_DOMAIN_ID);
	DELETE ENTITY_DOMAIN_CONTACT WHERE OWNER_ENTITY_ID = :old.EDC_ID AND ENTITY_DOMAIN_ID IN
		(SELECT ENTITY_DOMAIN_ID FROM ENTITY_DOMAIN WHERE UPPER(ENTITY_DOMAIN_TABLE_ALIAS) = 'EDC');
	DELETE ENTITY_DOMAIN_ADDRESS WHERE OWNER_ENTITY_ID = :old.EDC_ID AND ENTITY_DOMAIN_ID IN
		(SELECT ENTITY_DOMAIN_ID FROM ENTITY_DOMAIN WHERE UPPER(ENTITY_DOMAIN_TABLE_ALIAS) = 'EDC');
END EDC_DELETE;
/