CREATE OR REPLACE PACKAGE MM_PJM_LMP IS
-- $Revision: 1.18 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

PROCEDURE MARKET_IMPORT_CLOB
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE         	IN VARCHAR2,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_FILE_PATH					IN VARCHAR2, 		-- For logging Purposes.
	p_IMPORT_FILE				IN OUT NOCOPY CLOB, 	-- File to be imported
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2
	);


	g_ET_DAY_AHEAD_LMP VARCHAR2(20) := 'Query Day-ahead LMP';
	g_ET_REAL_TIME_LMP VARCHAR2(20) := 'Query Real-time LMP';
	g_ET_FTR_ZONAL_LMP VARCHAR2(20) := 'Query FTR Zonal LMP';
	g_ET_QUERY_PNODES VARCHAR2(20) := 'Query PNodes';
	g_ET_DAY_AHEAD_LMP_MONTH VARCHAR2(64) := 'Query Monthly Day-ahead LMP';
	g_ET_REAL_TIME_LMP_MONTH VARCHAR2(64) := 'Query Monthly Real-time LMP';

	g_ET_DA_LMP_FROM_FILE VARCHAR2(50) := 'Import Day-ahead LMP from File';
    g_ET_RT_LMP_FROM_FILE VARCHAR2(50) := 'Import Real-time LMP from File';
    g_ET_FTR_LMP_FROM_FILE VARCHAR2(50) := 'Import FTR Zonal LMP from File';
END MM_PJM_LMP;
/