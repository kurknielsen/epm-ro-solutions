BEGIN CDI_DROP_OBJECT('CDI_MV90_DATA_CACHE','TABLE'); END;
/

CREATE TABLE CDI_MV90_DATA_CACHE
(
  CHANNEL               VARCHAR2(8 BYTE),
  STUDY_ID              VARCHAR2(4 BYTE),
  KW_DATE               DATE,
  KW_VAL                NUMBER(13,6),
  LOCAL_DAY_TRUNC_DATE  DATE
);
