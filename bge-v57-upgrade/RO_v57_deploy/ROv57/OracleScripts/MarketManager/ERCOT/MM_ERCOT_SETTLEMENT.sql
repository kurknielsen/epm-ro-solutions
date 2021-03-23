CREATE OR REPLACE PACKAGE MM_ERCOT_SETTLEMENT IS
-- $Revision: 1.9 $

  -- Author  : CNAVALTA
  -- Created : 4/19/2006 1:57:54 PM
  -- Purpose :

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

g_ET_IMPORT_ANNUAL_INITIAL  VARCHAR2(60)  := 'Import Annual Initial Settlement Totals';
g_ET_IMPORT_MONTHLY_INITIAL VARCHAR2(60) := 'Import Monthly Initial Settlement Totals';
g_ET_IMPORT_ANNUAL_FINAL 	VARCHAR2(60) := 'Import Annual Final Settlement Totals';
g_ET_IMPORT_MONTHLY_FINAL 	VARCHAR2(60) := 'Import Monthly Final Settlement Totals';
g_ET_IMPORT_ANNUAL_TRUE_UP  VARCHAR2(60) := 'Import Annual True-Up Settlement Totals';
g_ET_IMPORT_MONTHLY_TRUE_UP VARCHAR2(60) := 'Import Monthly True-Up Settlement Totals';
END MM_ERCOT_SETTLEMENT;
/