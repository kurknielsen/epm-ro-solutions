create or replace package MM_SEM_CFD_ALERTS is

  -- Author  : AHUSSAIN
  -- Created : 4/23/2008 8:35:28 AM
  -- Revision: $Revision: 1.4 $
	--------------------------------------------------------------------------------------
	FUNCTION WHAT_VERSION RETURN VARCHAR;
	--------------------------------------------------------------------------------------
	PROCEDURE RESETTLEMENT_DATA_ALERTS
	(
		p_OPERATING_DAY IN DATE,
		p_STATUS OUT NUMBER
	);

end MM_SEM_CFD_ALERTS;
/