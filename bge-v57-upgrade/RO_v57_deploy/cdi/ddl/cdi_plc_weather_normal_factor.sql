BEGIN CDI_DROP_OBJECT('CDI_PLC_WEATHER_NORMAL_FACTOR','TABLE'); END;
/

CREATE TABLE CDI_PLC_WEATHER_NORMAL_FACTOR
(
  RATE_CLASS    VARCHAR2(64),
  VOLTAGE_LEVEL VARCHAR2(64),
  FACTOR        NUMBER,
  CONSTRAINT PK_PLC_WEATHER_NORMAL_FACTOR PRIMARY KEY (RATE_CLASS, VOLTAGE_LEVEL)
) TABLESPACE &&NERO_DATA_TABLESPACE;