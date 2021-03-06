BEGIN CDI_DROP_OBJECT('CDI_PLC_NSPL_STAGE','TABLE'); END;
/

CREATE GLOBAL TEMPORARY TABLE CDI_PLC_NSPL_STAGE
(
  PLC_DATE           DATE,
  ESP_ID             NUMBER,
  PSE_ID             NUMBER,
  PJM_SHORT_NAME     VARCHAR2(64),
  POLR_TYPE          VARCHAR2(64),
  VOLTAGE_CLASS      VARCHAR2(64),
  REPORTED_SEGMENT   VARCHAR2(64),
  RFT_TICKET_NUMBER  VARCHAR2(64),
  PLC_BAND           VARCHAR2(2),
  ICAP_VALUE         NUMBER(18,4),
  NSPL_VALUE         NUMBER(18,4)
) ON COMMIT PRESERVE ROWS;
