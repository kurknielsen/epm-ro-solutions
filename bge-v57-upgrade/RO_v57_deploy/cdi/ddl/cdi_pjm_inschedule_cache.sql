BEGIN CDI_DROP_OBJECT('CDI_PJM_INSCHEDULE_CACHE','TABLE'); END;
/

CREATE TABLE CDI_PJM_INSCHEDULE_CACHE
(
  RECORD_NUMBER        NUMBER(6),
  RECORD_CONTENT       VARCHAR2(128)
);