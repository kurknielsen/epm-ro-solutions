create or replace package MM_PJM_FERC is
-- $Revision: 1.5 $

  -- Author  : KJONES
  -- Created : 3/26/2007 10:55:34 AM
  -- Purpose : reports, procs, functions for FERC related logic

  -- Public type declarations
TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE GET_FERC_668_RPT
	(
    p_PSE_ID IN VARCHAR2,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT REF_CURSOR
	);

PROCEDURE IMPORT_FERC_668_DATA
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    );

INSUFFICIENT_PRIVILEGES EXCEPTION;
PRAGMA EXCEPTION_INIT(INSUFFICIENT_PRIVILEGES, -1031);

end MM_PJM_FERC;
/