

CREATE TABLE MARKET_CLOSINGS
(
  CLOSING_TYPE      VARCHAR2(16)	NOT NULL,
  SC_ID             NUMBER(9)			NOT NULL,
  COMMODITY_ID      NUMBER(9)			NOT NULL,
  TRANSACTION_TYPE  VARCHAR2(16)	NOT NULL,
  IS_IMPORT_EXPORT  NUMBER(1)			NOT NULL,
  TRUNCATE_TO       VARCHAR2(16),
  DAYS_ADDED	  NUMBER(3),
  HOURS_ADDED       NUMBER(3),
  MINUTES_ADDED     NUMBER(5,2),
	constraint PK_MARKET_CLOSINGS primary key (CLOSING_TYPE, SC_ID, COMMODITY_ID, TRANSACTION_TYPE, IS_IMPORT_EXPORT)
       using index
        tablespace NERO_INDEX
       storage
       (
           initial 64K
           next 64K
           pctincrease 0
       )
)
storage
(
    initial 128K
    next 128K
    pctincrease 0
)
tablespace NERO_DATA
/


PROMPT ***************************************************
PROMPT MEX\PJM
PROMPT ***************************************************
@&1\&3\PJM\crebas.sql
PROMPT ***************************************************
PROMPT MEX\MISO
PROMPT ***************************************************
@&1\&3\MISO\crebas.sql
PROMPT ***************************************************
PROMPT MEX\NY-ISO
PROMPT ***************************************************
@&1\&3\NY-ISO\crebas.sql
PROMPT ***************************************************
PROMPT MEX\OASIS
PROMPT ***************************************************
@&1\&3\OASIS\MEX_OASIS_crebas.sql
PROMPT ***************************************************
PROMPT MEX\ERCOT
PROMPT ***************************************************
@&1\&3\ERCOT\crebas.sql
PROMPT ***************************************************
PROMPT MINT\SEM
PROMPT ***************************************************
@&1\&2\SEM\crebas.sql
PROMPT ***************************************************
PROMPT MINT\TDIE
PROMPT ***************************************************
@&1\&2\TDIE\crebas.sql



