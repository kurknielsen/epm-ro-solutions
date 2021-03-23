CREATE OR REPLACE PACKAGE BODY MM_ERCOT IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION IS_SUPPORTED_EXCHANGE_TYPE
	(
	p_MKT_APP IN VARCHAR2,
	p_EXCHANGE_TYPE IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	-- @TODO: dispatch based on p_MKT_APP
	RETURN TRUE;
END IS_SUPPORTED_EXCHANGE_TYPE;
----------------------------------------------------------------------------------------------------

END MM_ERCOT;
/
