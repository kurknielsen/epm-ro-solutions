CREATE OR REPLACE TYPE SERVICE_TYPE AS OBJECT
(
--Revision: $Revision: 1.14 $
  PROVIDER_SERVICE_ID NUMBER(9),
  ACCOUNT_SERVICE_ID NUMBER(9),
  SERVICE_DELIVERY_ID NUMBER(9),
  SERVICE_ID NUMBER(9)
);
/

CREATE OR REPLACE TYPE SERVICE_TABLE IS TABLE OF SERVICE_TYPE;
/
