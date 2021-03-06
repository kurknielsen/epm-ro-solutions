CREATE OR REPLACE PACKAGE MM_SEM_CFD_REPORTS IS

	-- Author  : AHUSSAIN
	-- Created : 3/18/2008 9:29:33 AM
	-- Purpose : 
 	-- $Revision: 1.3 $
  
	-- Public type declarations
		  
	-- Public constant declarations

	-- Public variable declarations

	-- Public function and procedure declarations
	FUNCTION WHAT_VERSION RETURN VARCHAR;

	PROCEDURE GET_SUMMARY_OF_TRADES_RPT
	(
		p_BEGIN_DATE IN DATE,
		p_END_DATE IN DATE,
		p_CONTRACT_IDS IN VARCHAR2,
		p_CURRENCY_FILTER IN VARCHAR2,
		p_JURISDICTION_FILTER IN VARCHAR2,
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);

	PROCEDURE GET_JURISDICTION
	(
		p_STATUS OUT NUMBER,
		p_CURSOR OUT SYS_REFCURSOR
	);

END MM_SEM_CFD_REPORTS;
/