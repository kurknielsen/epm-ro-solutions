BEGIN CDI_DROP_OBJECT('CDI_PLC_LOAD','TABLE'); END;
/

CREATE TABLE CDI_PLC_LOAD
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
) TABLESPACE &&NERO_DATA_TABLESPACE;

CREATE INDEX IX_CDI_PLC_LOAD ON CDI_PLC_LOAD(PLC_DATE, ESP_ID, PSE_ID, PJM_SHORT_NAME, POLR_TYPE, VOLTAGE_CLASS, REPORTED_SEGMENT, RFT_TICKET_NUMBER, PLC_BAND) TABLESPACE &&NERO_INDEX_TABLESPACE;

