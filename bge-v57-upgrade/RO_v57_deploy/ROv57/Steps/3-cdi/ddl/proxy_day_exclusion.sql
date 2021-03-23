BEGIN CDI_DROP_OBJECT('PROXY_DAY_EXCLUSION', 'TABLE'); END;
/

CREATE TABLE PROXY_DAY_EXCLUSION
(
  ACCOUNT_ID   NUMBER(9) NOT NULL, 
  BEGIN_DATE   DATE      NOT NULL, 
  END_DATE     DATE, 
  USER_COMMENT VARCHAR2(256), 
  ENTRY_DATE   DATE,
  CONSTRAINT PK_PROXY_DAY_EXCLUSION PRIMARY KEY (ACCOUNT_ID, BEGIN_DATE)  USING INDEX TABLESPACE &&NERO_INDEX_TABLESPACE 
) TABLESPACE &&NERO_DATA_TABLESPACE;
