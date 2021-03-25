CREATE OR REPLACE PACKAGE SECURITY_INFO IS
--Revision $Revision: 1.2 $

  -- Author  : JHUMPHRIES
  -- Created : 1/18/2007 11:40:26 PM
  -- Purpose : Provide security related information
  --           This package has no entry-points that can be used to change
  --           security information. Most methods pass through to the private
  --           SECURITY_CONTROLS package.
  
FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE RELOAD_CURRENT_ROLES; -- force roles to be re-loaded from tables
FUNCTION CURRENT_ROLES RETURN ID_TABLE; -- query for current roles
FUNCTION CURRENT_USER RETURN VARCHAR2;  -- query for current user-name

PROCEDURE GET_INITIALIZATION_PARAMS -- query for VBD initialization parameters
    (
    p_DOMAIN_NAME IN VARCHAR,
    p_MODEL_ID OUT NUMBER,
    p_ACCESS_CODE OUT VARCHAR
    );

END SECURITY_INFO;
/
CREATE OR REPLACE PACKAGE BODY SECURITY_INFO IS
-----------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.2 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE RELOAD_CURRENT_ROLES AS
BEGIN
	SECURITY_CONTROLS.RELOAD_CURRENT_ROLES;
END;
-----------------------------------------------------------------------------
FUNCTION CURRENT_ROLES RETURN ID_TABLE IS
v_ROLES ID_TABLE := SECURITY_CONTROLS.CURRENT_ROLES;
v_RET ID_TABLE := ID_TABLE();
v_IDX BINARY_INTEGER;
BEGIN
	-- make sure a copy is returned - so that if caller tries to add 
	-- entries to the returned collection, there is no way they could 
	-- elevate their privileges 
	v_IDX := v_ROLES.FIRST;
	WHILE v_ROLES.EXISTS(v_IDX) LOOP
		v_RET.EXTEND;
		v_RET(v_RET.LAST) := ID_TYPE(v_ROLES(v_IDX).ID);
		v_IDX := v_ROLES.NEXT(v_IDX);
	END LOOP;
	
	RETURN v_RET;
END CURRENT_ROLES;
-----------------------------------------------------------------------------
FUNCTION CURRENT_USER RETURN VARCHAR2 IS
BEGIN
	RETURN SECURITY_CONTROLS.CURRENT_USER;
END CURRENT_USER;
-----------------------------------------------------------------------------
-- Query for VBD initialization info
PROCEDURE GET_INITIALIZATION_PARAMS
    (
    p_DOMAIN_NAME IN VARCHAR,
    p_MODEL_ID OUT NUMBER,
    p_ACCESS_CODE OUT VARCHAR
    ) AS

BEGIN

    p_MODEL_ID := GA.DEFAULT_MODEL;

    IF CAN_DELETE(p_DOMAIN_NAME) THEN
        p_ACCESS_CODE := 'D';
    ELSIF CAN_WRITE(p_DOMAIN_NAME) THEN
        p_ACCESS_CODE := 'U';
    ELSIF CAN_READ(p_DOMAIN_NAME) THEN
        p_ACCESS_CODE := 'S';
    ELSE
        p_ACCESS_CODE := '';
    END IF;

END GET_INITIALIZATION_PARAMS;
-----------------------------------------------------------------------------
END SECURITY_INFO;
/
