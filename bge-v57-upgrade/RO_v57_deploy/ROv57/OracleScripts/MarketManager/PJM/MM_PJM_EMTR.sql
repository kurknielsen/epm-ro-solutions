CREATE OR REPLACE PACKAGE MM_PJM_EMTR IS

    -- Author  : KCHOPRA
    -- Created : 12/4/2004 5:43:02 PM
    -- Purpose :
-- $Revision: 1.13 $

TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE PUT_METER_SVC_PT_MAPPING(p_METER_ID         IN NUMBER,
                                       p_SERVICE_POINT_ID IN NUMBER,
                                       p_STATUS           OUT NUMBER);

PROCEDURE METER_SVC_PT_MAPPING_RPT(p_STATUS OUT NUMBER, p_CURSOR IN OUT REF_CURSOR);

PROCEDURE MARKET_EXCHANGE
	(
	p_BEGIN_DATE            	IN DATE,
	p_END_DATE              	IN DATE,
	p_EXCHANGE_TYPE  			IN VARCHAR2,
	p_ENTITY_LIST           	IN VARCHAR2,
	p_ENTITY_LIST_DELIMITER 	IN CHAR,
	p_LOG_ONLY					IN NUMBER :=0,
	p_LOG_TYPE 					IN NUMBER,
	p_TRACE_ON 					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

PROCEDURE MARKET_IMPORT_CLOB
	(
	p_EXCHANGE_TYPE         	IN VARCHAR2,
	p_FILE_PATH					IN VARCHAR2, 		-- For logging Purposes.
	p_IMPORT_FILE				IN OUT NOCOPY CLOB, -- File to be imported
	p_LOG_TYPE					IN NUMBER,
	p_TRACE_ON					IN NUMBER,
	p_STATUS                	OUT NUMBER,
	p_MESSAGE               	OUT VARCHAR2);

-- Exchange Types
g_ET_QUERY_METER_ACCOUNTS CONSTANT VARCHAR2(64):= 'Query Meter Accounts';
g_ET_QUERY_METER_VALUES CONSTANT VARCHAR2(64):= 'Query Meter Values';
g_ET_QUERY_ALLOC_METER_VALUES CONSTANT VARCHAR2(64):= 'Query Allocated Meter Values';

g_ET_IMPORT_METER_ACC_XML CONSTANT VARCHAR2(64) := 'Import Meter Accounts XML';
g_ET_IMPORT_METER_VALUES_XML CONSTANT VARCHAR2(64) := 'Import Meter Values XML';

-- 24-mar-2009, jbc: these data exchanges aren't used by anyone
/*
	g_ET_QUERY_LOAD_VALUES CONSTANT VARCHAR2(64) := 'Query Load Values';
	g_ET_IMPORT_LOAD_VALUES_XML CONSTANT VARCHAR2(64):= 'Import Load Values XML';
	g_ET_QUERY_METER_CORREC_ALLOCS CONSTANT VARCHAR2(64):= 'Query Meter Correction Allocations';
	g_ET_IMPORT_MTR_CORR_ALLOC_XML CONSTANT VARCHAR2(64) := 'Import Meter Correction Allocations XML';
*/

PROCEDURE PUT_DERATED_LOSS_VALUES
    (
    p_ACCOUNT_NAME IN VARCHAR2,
    p_DATE IN DATE,
    p_METER_VALUE NUMBER,
    p_STATUS OUT NUMBER
    );

PROCEDURE PUT_INADVERTENT_VALUES
    (
    p_ACCOUNT_NAME IN VARCHAR2,
    p_DATE IN DATE,
    p_METER_VALUE NUMBER,
    p_STATUS OUT NUMBER
    );

END MM_PJM_EMTR;
/