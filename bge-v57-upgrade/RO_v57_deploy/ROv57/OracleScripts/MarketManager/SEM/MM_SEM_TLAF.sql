CREATE OR REPLACE PACKAGE MM_SEM_TLAF AS
--Revision: $Revision: 1.3 $

TYPE REF_CURSOR IS REF CURSOR;
--PROCESS LOGGING --
  g_PID           Plog.t_PROCESS_DESCRIPTOR;
  g_PRES          Plog.t_PLOG_RESULT;
  g_result        Plog.t_SEVERITY_CODE;
  g_report        VARCHAR2(1024);
  g_source        VARCHAR2(1024);
  g_proc_name     VARCHAR2(1024);
  g_step_name     VARCHAR2(1024);

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE GET_TLAF
(
   P_BEGIN_DATE  IN DATE,
   p_END_DATE    IN date,
   p_CURSOR OUT REF_CURSOR
);
PROCEDURE UPDATE_TLAF
(
   P_STARTDATE     IN  DATE,
   p_ENDDATE       IN  date,
   p_DAY_TLAF      in  number,
   p_NIGHT_TLAF    in  number,
   p_PSE_ID        IN  NUMBER,
   p_SERVICE_POINT_ID        IN  NUMBER,
   p_POD_ID        IN  NUMBER,
   p_LOSS_NAME     IN  VARCHAR2,
   p_REPORTID      IN  VARCHAR2,
   p_message       out varchar2,
   p_status        out number
);
PROCEDURE DELETE_TLAF
(
   p_TLAF_SEQUENCE       IN NUMBER,
   p_message       out varchar2,
   p_status        out number
);
PROCEDURE GET_SEM_LOSS
(
   P_BEGIN_DATE IN DATE,
   p_END_DATE   IN date,
   p_WINDFARM_FILTER IN VARCHAR2,
   p_CURSOR OUT REF_CURSOR
);

PROCEDURE POD
  (
   p_STATUS OUT NUMBER,
   p_CURSOR OUT REF_CURSOR
  );
end MM_SEM_TLAF;
/