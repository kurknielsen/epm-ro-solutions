create table DATA_IMPORT_STAGING_AREA
(
  SESSION_ID   VARCHAR2(32) not null,
  FILE_NAME    VARCHAR2(256) not null,
  ROW_NUM      NUMBER not null,
  ROW_CONTENTS CLOB,
  STATUS       CHAR(1)
)
tablespace NERO_DATA
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 128K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate primary, unique and foreign key constraints 
alter table DATA_IMPORT_STAGING_AREA
  add constraint PK_DATA_IMPORT_STAGING_AREA primary key (SESSION_ID,FILE_NAME,ROW_NUM)
  using index 
  tablespace NERO_INDEX
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );