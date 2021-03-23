BEGIN CDI_DROP_OBJECT('CDI_MV90_DATA','TABLE'); END;
/

CREATE GLOBAL TEMPORARY TABLE CDI_MV90_DATA
(
  CHANNEL                     VARCHAR2(8) NOT NULL,
  CUT_INTERVAL                DATE NOT NULL,
  IS_ALTERNATE_FORMAT         CHAR(1),
  PULSE_MULTIPLIER            NUMBER,
  PULSE_OFFSET                NUMBER,
  ALTERNATE_PULSE_MULTIPLIER  NUMBER,
  PREMISE_NUMBER              NUMBER,
  KW                          NUMBER,
  STATUS_CODE                 CHAR(1),
  PROCESS_ID                  NUMBER,
  CREATE_DATE_TIME            DATE,
  CONSTRAINT PK_CDI_MV90_DATA PRIMARY KEY(CUT_INTERVAL, CHANNEL)
) ON COMMIT PRESERVE ROWS;

CREATE INDEX CDI_MV90_DATA_IX01 ON CDI_MV90_DATA(PROCESS_ID);
