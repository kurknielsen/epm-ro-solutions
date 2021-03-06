CREATE OR REPLACE PACKAGE MM_ISONE AS

-- ISONE-specific Market Manager procedures


TYPE REF_CURSOR IS REF CURSOR;

PROCEDURE SYSTEM_ACTION_USES_HOURS
	(
    p_MKT_APP IN VARCHAR2,
    p_ACTION IN VARCHAR2,
	p_SHOW_HOURS OUT NUMBER
    );

FUNCTION IS_SUPPORTED_EXCHANGE_TYPE
	(
	p_MKT_APP IN VARCHAR2,
	p_EXCHANGE_TYPE IN VARCHAR2
	) RETURN BOOLEAN;


END MM_ISONE;
/
CREATE OR REPLACE PACKAGE BODY MM_ISONE AS
----------------------------------------------------------------------------

PROCEDURE SYSTEM_ACTION_USES_HOURS
	(
    p_MKT_APP IN VARCHAR2,
    p_ACTION IN VARCHAR2,
	p_SHOW_HOURS OUT NUMBER
    ) AS
BEGIN
	p_SHOW_HOURS := 0;
END SYSTEM_ACTION_USES_HOURS;
----------------------------------------------------------------------------------------------------
FUNCTION IS_SUPPORTED_EXCHANGE_TYPE
	(
	p_MKT_APP IN VARCHAR2,
	p_EXCHANGE_TYPE IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	-- @TODO: dispatch based on p_MKT_APP
	RETURN TRUE;
END IS_SUPPORTED_EXCHANGE_TYPE;


END MM_ISONE;
/
