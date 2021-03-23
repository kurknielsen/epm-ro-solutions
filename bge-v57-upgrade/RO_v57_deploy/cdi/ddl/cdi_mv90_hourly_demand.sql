BEGIN CDI_DROP_OBJECT('CDI_MV90_HOURLY_DEMAND','TABLE'); END;
/

CREATE TABLE CDI_MV90_HOURLY_DEMAND
(
  ACCOUNT_EXTERNAL_IDENTIFIER VARCHAR2(64),
  SERVICE_DATE                DATE,
  HR01                        NUMBER(14,4),
  HR02                        NUMBER(14,4),
  HR03                        NUMBER(14,4),
  HR04                        NUMBER(14,4),
  HR05                        NUMBER(14,4),
  HR06                        NUMBER(14,4),
  HR07                        NUMBER(14,4),
  HR08                        NUMBER(14,4),
  HR09                        NUMBER(14,4),
  HR10                        NUMBER(14,4),
  HR11                        NUMBER(14,4),
  HR12                        NUMBER(14,4),
  HR13                        NUMBER(14,4),
  HR14                        NUMBER(14,4),
  HR15                        NUMBER(14,4),
  HR16                        NUMBER(14,4),
  HR17                        NUMBER(14,4),
  HR18                        NUMBER(14,4),
  HR19                        NUMBER(14,4),
  HR20                        NUMBER(14,4),
  HR21                        NUMBER(14,4),
  HR22                        NUMBER(14,4),
  HR23                        NUMBER(14,4),
  HR24                        NUMBER(14,4),
  HR25                        NUMBER(14,4),
  ENTRY_DATE                  DATE,
  CONSTRAINT PK_CDI_MV90_HOURLY_DEMAND PRIMARY KEY (ACCOUNT_EXTERNAL_IDENTIFIER, SERVICE_DATE) USING INDEX TABLESPACE &&NERO_LARGE_INDEX_TABLESPACE
) TABLESPACE &&NERO_LARGE_DATA_TABLESPACE;
