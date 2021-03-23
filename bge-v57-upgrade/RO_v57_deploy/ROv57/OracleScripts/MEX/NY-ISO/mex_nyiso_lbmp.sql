CREATE OR REPLACE PACKAGE MEX_NYISO_LBMP IS
-- $Revision: 1.7 $
-------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2;
-------------------------------------------------
PROCEDURE FETCH_LBMP_MONTHLY_ZIP
(
    p_CURRENT_MONTH IN DATE,
    p_ACTION        IN VARCHAR2,
    p_RESPONSE_CLOB OUT CLOB,
    p_STATUS        OUT NUMBER,
    p_LOGGER        IN OUT MM_LOGGER_ADAPTER
);
----------------------------------------------------
PROCEDURE FETCH_LBMP_DAILY
(
    P_DATE             IN DATE,
    p_IS_ARCHIVED_FLAG IN BOOLEAN,
    p_ACTION           IN VARCHAR2,
	p_FILE_LIST 		IN STRING_COLLECTION,
    p_LMP_TBL          OUT MEX_NY_LBMP_TBL,
    p_STATUS           OUT NUMBER,
    p_LOGGER           IN OUT MM_LOGGER_ADAPTER
);
---------------------------------------------------
PROCEDURE FETCH_NODES
(
    p_RECORDS   OUT MEX_NY_PTID_NODE_TBL,
    p_STATUS    OUT NUMBER,
    p_LOGGER    IN OUT NOCOPY MM_LOGGER_ADAPTER
);
-----------------------------------------------------
END MEX_NYISO_LBMP;
/