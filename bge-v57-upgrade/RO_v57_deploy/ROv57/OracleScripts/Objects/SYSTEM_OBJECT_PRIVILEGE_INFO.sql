CREATE OR REPLACE TYPE SYSTEM_OBJECT_PRIVILEGE_INFO AS OBJECT (
OBJECT_ID 		NUMBER(9),	-- System Object ID
ROLE_ID 		NUMBER(9),	-- Application Role ID
ROLE_PRIVILEGE	NUMBER(1),	-- Assigned/inherited privilege for this role for this object
PRIVILEGE_STAT	NUMBER(1),	-- Privilege status: None, Inherited, or Assigned
EFF_PRIVILEGE	NUMBER(1),	-- Differs from ROLE_PRIVILEGE when user does not have view access to all ancestors
DO_NOT_INHERIT	NUMBER(1)	-- whether or not this privilege will be inherited by child objects
);
/
CREATE OR REPLACE TYPE SYSTEM_OBJECT_PRIV_INFO_TBL AS TABLE OF SYSTEM_OBJECT_PRIVILEGE_INFO;
/
