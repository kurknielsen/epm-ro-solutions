--Create table
CREATE TABLE TP_OASIS_LIST_RESULT
(
  TP_ID                 NUMBER(9) NOT NULL,
  OASIS_LIST_NAME       VARCHAR2(50) NOT NULL,  
  OASIS_LIST_ITEM       VARCHAR2(50) NOT NULL,
  OASIS_LIST_ITEM_DESC  VARCHAR2(2000), 
  IS_APPLICABLE         NUMBER(1),
  ENTRY_DATE            DATE
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
ALTER TABLE TP_OASIS_LIST_RESULT 
  ADD CONSTRAINT PK_TP_OASIS_LIST_RESULT PRIMARY KEY (TP_ID, OASIS_LIST_NAME, OASIS_LIST_ITEM)
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
