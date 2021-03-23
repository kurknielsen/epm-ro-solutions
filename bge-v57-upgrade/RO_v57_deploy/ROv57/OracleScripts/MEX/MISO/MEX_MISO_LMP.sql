CREATE OR REPLACE PACKAGE MEX_MISO_LMP IS
-- $Revision: 1.5 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE FETCH_LMP_FILE
	(
	p_DATE             	IN DATE,
	p_MARKET_TYPE      	IN VARCHAR2,
	p_LOG_ONLY			IN BINARY_INTEGER :=0,
	p_RECORDS          	OUT MEX_MISO_LMP_OBJ_TBL,
	p_STATUS           	OUT NUMBER,
	p_MESSAGE          	OUT VARCHAR2,
	p_LOGGER            IN OUT mm_logger_adapter
	);

END MEX_MISO_LMP;
/