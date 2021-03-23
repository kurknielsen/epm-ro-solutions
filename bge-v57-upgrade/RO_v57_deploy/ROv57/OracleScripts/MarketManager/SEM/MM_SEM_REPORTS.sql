CREATE OR REPLACE PACKAGE MM_SEM_REPORTS IS
 -------------------------------------------------------------------------------
  -- Created : 03/21/2007 14:18:41
  -- Purpose : Download public and private reports from SEM market
  -- $Revision: 1.17 $
 -------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE QUERY_REPORT
(
    p_BEGIN_DATE   IN DATE,
	   p_END_DATE     IN DATE,
    p_INT_REP_NAME IN VARCHAR2,
    p_LOG_TYPE     IN NUMBER,
    p_TRACE_ON     IN NUMBER,
    p_STATUS       OUT NUMBER,
    p_MESSAGE      OUT VARCHAR2,
    P_RUN_TYPE     IN VARCHAR2 := NULL
);

PROCEDURE IMPORT_MPI_REPORT_CLOB
(
    p_IMPORT_FILE_PATH   IN VARCHAR2,
	   p_IMPORT_FILE IN OUT NOCOPY CLOB,
    p_LOG_TYPE    IN NUMBER,
    p_TRACE_ON    IN NUMBER,
    p_STATUS      OUT NUMBER,
    p_MESSAGE     OUT VARCHAR2
);

PROCEDURE IMPORT_TLAF_REPORT_CLOB 
(
    p_IMPORT_FILE_PATH   IN VARCHAR2,
    p_IMPORT_FILE IN OUT NOCOPY CLOB,
    p_LOG_TYPE    IN NUMBER,
    p_TRACE_ON    IN NUMBER,
    p_STATUS      OUT NUMBER,
    p_MESSAGE     OUT VARCHAR2
);

END MM_SEM_REPORTS;
/