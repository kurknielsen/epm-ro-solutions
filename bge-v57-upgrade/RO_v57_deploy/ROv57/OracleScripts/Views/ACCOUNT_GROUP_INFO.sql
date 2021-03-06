CREATE OR REPLACE VIEW ACCOUNT_GROUP_INFO ( ACCOUNT_GROUP_ID, 
ACCOUNT_ID, ACCOUNT_GROUP_NAME ) AS 
SELECT AGA.ACCOUNT_GROUP_ID, AGA.ACCOUNT_ID, AG.ACCOUNT_GROUP_NAME
FROM ACCOUNT_GROUP_ASSIGNMENT AGA, ACCOUNT_GROUP AG
WHERE AGA.ACCOUNT_GROUP_ID = AG.ACCOUNT_GROUP_ID;
