BEGIN CDI_DROP_OBJECT('CDI_DAILY_USAGE_FACTOR','TABLE'); END;
/

CREATE GLOBAL TEMPORARY TABLE CDI_DAILY_USAGE_FACTOR
(
  BILL_ACCOUNT    NUMBER,
  SERVICE_POINT   NUMBER,
  USAGE_FACTOR    NUMBER(14,6)
) ON COMMIT PRESERVE ROWS;

CREATE INDEX IX1_DAILY_USAGE_FACTOR ON CDI_DAILY_USAGE_FACTOR(BILL_ACCOUNT, SERVICE_POINT);
