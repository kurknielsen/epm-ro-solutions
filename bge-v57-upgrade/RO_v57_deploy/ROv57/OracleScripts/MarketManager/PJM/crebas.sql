-- Create table
create table MM_EMTR_XML_WORK
(
  WORK_ID    NUMBER(9),
  OWNER_DATA VARCHAR2(32),
  CA_DATA    VARCHAR2(32),
  XML_DATA   XMLTYPE
)
tablespace NERO_DATA
  pctfree 10
  pctused 40
  initrans 1
  maxtrans 255
  storage
  (
    initial 64K
    minextents 1
    maxextents unlimited
  );
-- Create/Recreate indexes 
create unique index IX01_MM_EMTR_XML_WORK on MM_EMTR_XML_WORK (WORK_ID)
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
/

