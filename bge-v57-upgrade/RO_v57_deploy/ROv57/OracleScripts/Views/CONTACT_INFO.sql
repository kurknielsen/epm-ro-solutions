CREATE OR REPLACE VIEW CONTACT_INFO ( CATEGORY_NAME, 
CONTACT_NAME, CONTACT_ALIAS, CONTACT_DESC, EMAIL_ADDRESS, 
CONTACT_ID, CATEGORY_ID, OWNER_ENTITY_ID, ENTITY_DOMAIN_ID, 
ENTRY_DATE, FIRST_NAME, MIDDLE_NAME, LAST_NAME, 
SALUTATION,EXTERNAL_IDENTIFIER ) AS SELECT T.CATEGORY_NAME, C.CONTACT_NAME, C.CONTACT_ALIAS,
C.CONTACT_DESC, C.EMAIL_ADDRESS, C.CONTACT_ID, T.CATEGORY_ID,
E.OWNER_ENTITY_ID,E.ENTITY_DOMAIN_ID, C.ENTRY_DATE,
C.FIRST_NAME, C.MIDDLE_NAME, C.LAST_NAME, C.SALUTATION, C.EXTERNAL_IDENTIFIER
FROM CATEGORY T, CONTACT C, ENTITY_DOMAIN_CONTACT E
WHERE T.CATEGORY_ID(+) = E.CATEGORY_ID
AND C.CONTACT_ID = E.CONTACT_ID(+);
