CREATE OR REPLACE VIEW UNASSIGNED_ATTRIBUTE_INFO ( ATTRIBUTE_NAME, 
ATTRIBUTE_ID, ENTITY_DOMAIN_ID, ATTRIBUTE_TYPE, ATTRIBUTE_SHOW, 
BEGIN_DATE, END_DATE, ATTRIBUTE_VAL, ENTRY_DATE, 
OWNER_ENTITY_ID ) AS SELECT ATTRIBUTE_NAME, ATTRIBUTE_ID, ENTITY_DOMAIN_ID, ATTRIBUTE_TYPE, ATTRIBUTE_SHOW, 
	TO_DATE('12/31/9999','MM/DD/YYYY'), TO_DATE('12/31/9999','MM/DD/YYYY') ,
	'NULL', TO_DATE('12/31/9999','MM/DD/YYYY'), -1
FROM ENTITY_ATTRIBUTE
WHERE ATTRIBUTE_SHOW = 1 AND 
	NOT ATTRIBUTE_ID IN(SELECT ATTRIBUTE_ID FROM TEMPORAL_ENTITY_ATTRIBUTE);

