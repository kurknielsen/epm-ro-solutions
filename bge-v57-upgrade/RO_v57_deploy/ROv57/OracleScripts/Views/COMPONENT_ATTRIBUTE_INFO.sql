CREATE OR REPLACE VIEW COMPONENT_ATTRIBUTE_INFO ( COMPONENT_ID, 
ENTITY_DOMAIN_ID, ENTITY_ATTRIBUTE_ID, BEGIN_DATE, END_DATE, 
ENTRY_DATE, ENTITY_DOMAIN_ALIAS, ATTRIBUTE_NAME, ATTRIBUTE_TYPE
 ) AS SELECT C.COMPONENT_ID, C.ENTITY_DOMAIN_ID, C.ENTITY_ATTRIBUTE_ID, 
	C.BEGIN_DATE, C.END_DATE, C.ENTRY_DATE, D.ENTITY_DOMAIN_TABLE_ALIAS, 
	A.ATTRIBUTE_NAME, A.ATTRIBUTE_TYPE
FROM COMPONENT_ENTITY_ATTRIBUTE C, ENTITY_DOMAIN D, ENTITY_ATTRIBUTE A
WHERE C.ENTITY_DOMAIN_ID = D.ENTITY_DOMAIN_ID(+) AND C.ENTITY_ATTRIBUTE_ID = A.ATTRIBUTE_ID(+);