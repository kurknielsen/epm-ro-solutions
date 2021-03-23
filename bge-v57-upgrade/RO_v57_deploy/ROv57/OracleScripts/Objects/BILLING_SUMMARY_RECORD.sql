CREATE OR REPLACE TYPE BILLING_SUMMARY_RECORD_TYPE AS OBJECT
(
--Revision: $Revision: 1.14 $
	STATEMENT_DATE DATE,
    STATEMENT_END_DATE DATE,
	ENTITY_ID VARCHAR2(2000),
    ENTITY_NAME VARCHAR2(64),
    PRODUCT_ID NUMBER(9),
    PRODUCT_NAME VARCHAR2(64),
    COMPONENT_ID NUMBER(9),
    COMPONENT_NAME VARCHAR2(256),
    IN_DISPUTE NUMBER(1),
    BILL_AMOUNT NUMBER,
    CHARGE_AMOUNT NUMBER,
    STATEMENT_INTERVAL VARCHAR(30),
    ORIGINAL_DATE DATE,
    ORIGINAL_END_DATE DATE,
    SHOW_CHARGE_DETAILS NUMBER(1),
    SHOW_INTERVAL NUMBER(1),
	SHOW_ENTITY_DETAIL NUMBER(1),
	SHOW_PRODUCT_ID NUMBER(1),
	SHOW_COMPONENT_ID NUMBER(1)
);
/
CREATE OR REPLACE TYPE BILLING_SUMMARY_RECORD_TABLE IS TABLE OF BILLING_SUMMARY_RECORD_TYPE;
/
