BEGIN CDI_DROP_OBJECT('CDI_BGE_RTO_STUDY','TABLE'); END;
/

CREATE TABLE CDI_BGE_RTO_STUDY
(
  STUDY_ID                     VARCHAR2(16),
  BILL_ACCOUNT                 NUMBER,
  AGGR_IDENTIFIER              VARCHAR2(64),
  EFFECTIVE_DATE               DATE,
  TERMINATION_DATE             DATE,
  ACCOUNT_ID                   NUMBER,
  ACCOUNT_NAME                 VARCHAR2(64),
  ACCOUNT_EXTERNAL_IDENTIFIER  VARCHAR2(64)
);

CREATE INDEX CDI_BGE_RTO_STUDY_IX01 ON CDI_BGE_RTO_STUDY(STUDY_ID, EFFECTIVE_DATE, TERMINATION_DATE);
