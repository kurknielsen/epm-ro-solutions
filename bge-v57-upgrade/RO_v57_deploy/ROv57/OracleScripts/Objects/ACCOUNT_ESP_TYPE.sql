create or replace TYPE ACCOUNT_ESP_TYPE AS OBJECT
(
-- Revision: $Revision: 1.1 $
  account_id         NUMBER(9),
  esp_id             NUMBER(9),
  pool_id            NUMBER(9),
  begin_date         DATE,
  end_date           DATE,
  esp_account_number VARCHAR2(32),
  entry_date         DATE
);
/

CREATE OR REPLACE TYPE ACCOUNT_ESP_TABLE AS TABLE OF ACCOUNT_ESP_TYPE;
/
