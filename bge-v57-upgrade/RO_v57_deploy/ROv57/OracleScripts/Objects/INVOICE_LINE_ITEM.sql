CREATE OR REPLACE TYPE INVOICE_LINE_ITEM_TYPE AS OBJECT
(
--Revision: $Revision: 1.18 $
  INVOICE_ID NUMBER(12),
  INVOICE_DATE DATE,
  INVOICE_NUMBER VARCHAR(16),
  INVOICE_SUB_LEDGER_NUMBER VARCHAR(16),
  BILL_PARTY_NAME VARCHAR(32),
  BILL_PARTY_ID NUMBER(9),
  ACCOUNT_GROUP_NAME VARCHAR(32),
  ACCOUNT_GROUP_ID NUMBER(9),
  PRODUCT_NAME VARCHAR(32),
  PRODUCT_ID NUMBER(9),
  COMPONENT_NAME VARCHAR(32),
  COMPONENT_ID NUMBER(9),
  GL_DEBIT_ACCOUNT VARCHAR(32),
  GL_CREDIT_ACCOUNT VARCHAR(32),
  LINE_ITEM_TYPE CHAR(1),
  LINE_ITEM_NAME VARCHAR(128),
  LINE_ITEM_QUANTITY NUMBER(12,2),
  LINE_ITEM_RATE NUMBER(12,4),
  LINE_ITEM_AMOUNT NUMBER(12,2),
  BILLING_STREET VARCHAR(64),
  BILLING_CITY VARCHAR(32),
  BILLING_STATE_CODE CHAR(2),
  BILLING_POSTAL_CODE VARCHAR(16),
  BILLING_COUNTRY_CODE VARCHAR(16),
  ACCOUNT_SERVICE_ID NUMBER(9)
);
/
CREATE OR REPLACE TYPE INVOICE_LINE_ITEM_TABLE IS TABLE OF INVOICE_LINE_ITEM_TYPE;
/
