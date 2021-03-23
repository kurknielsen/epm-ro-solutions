CREATE OR REPLACE PACKAGE body MM_SEM_TLAF AS
------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.1 $';
END WHAT_VERSION;
/*----------------------------------------------------------------------------*
 *   HANDLE_EXCEPTION                                                         *
 *----------------------------------------------------------------------------*/
PROCEDURE HANDLE_EXCEPTION(p_SQLCODE IN NUMBER, p_SQLERRM IN VARCHAR2) IS
BEGIN
   g_PRES := Plog.LOG_PROCESS_EVENT(g_PID, Plog.c_SEV_ABORT, g_PROC_NAME, g_STEP_NAME, g_SOURCE, p_SQLERRM, 'PROCESS EXCEPTION');
   g_PRES := Plog.LOG_PROCESS_END(g_PID, Plog.c_SEV_ABORT, p_SQLCODE, p_SQLERRM,'PROCESS EXCEPTION. CHECK PROCESS_EVENTS FOR DETAILS. '||g_REPORT);
END HANDLE_EXCEPTION;
/*----------------------------------------------------------------------------*
 *   DEFAULT_PROCESS_MESSAGE                                                  *
 *----------------------------------------------------------------------------*/
FUNCTION DEFAULT_PROCESS_MESSAGE(p_STATUS IN NUMBER) RETURN VARCHAR2 IS
BEGIN
   RETURN
      CASE p_STATUS
         WHEN Plog.c_SEV_OK THEN 'Normal, successful completion'
         WHEN Plog.c_SEV_WARNING THEN 'Warnings encountered - check process log for details'
         WHEN Plog.c_SEV_ERROR THEN 'Errors encountered - check process log for details'
         ELSE 'PROBLEMS ENCOUNTERED - CHECK PROCESS LOG FOR DETAILS'
      END;
END DEFAULT_PROCESS_MESSAGE;

/*----------------------------------------------------------------------------*
 *   GET_TLAF                                                                 *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_TLAF --CDI_TLAF.GET_TLAF
(
   P_BEGIN_DATE  IN DATE,
   p_END_DATE    IN date,
   p_CURSOR OUT REF_CURSOR
) IS
BEGIN

   OPEN p_CURSOR FOR
	  SELECT LOSS_NAME,
             BEGIN_DATE STARTDATE,
             END_DATE   ENDDATE,
             DAY_TLAF,
             NIGHT_TLAF,
             POD_ID,
             TLAF_SEQUENCE,
             rowid REPORTID,
			 PSE_ID
      FROM   tlaf_inputs a
      WHERE  a.begin_date <= end_date
      and    a.end_date   >= begin_date
      ORDER BY loss_name,begin_date;
END GET_TLAF;

/*----------------------------------------------------------------------------*
 *   UPDATE_TLAF                                                           *
 *----------------------------------------------------------------------------*/
PROCEDURE UPDATE_TLAF(
   p_STARTDATE        IN DATE,
   p_ENDDATE          IN DATE,
   p_DAY_TLAF         IN NUMBER,
   p_NIGHT_TLAF       IN NUMBER,
   p_PSE_ID           IN NUMBER,
   p_SERVICE_POINT_ID IN NUMBER,
   p_POD_ID           IN NUMBER,
   p_LOSS_NAME        IN VARCHAR2,
   p_REPORTID         IN VARCHAR2,
   p_MESSAGE          OUT VARCHAR2,
   p_STATUS           OUT NUMBER) 
IS
   v_ERROR_MESSAGE VARCHAR2(4000) := '';
   v_CONTINUE      BOOLEAN := TRUE;
   v_COUNT         NUMBER;
   v_TLAF_SEQ      NUMBER;
   v_ERR           VARCHAR2(4000);
   v_NUM           NUMBER;
   v_PSE_ID        PSE.PSE_ID%TYPE;
   
BEGIN
   -- START LOGGING --
   g_PROC_NAME := 'UPDATE_TLAF';
   g_STEP_NAME := 'Initial';
   g_REPORT    := '';

   g_STEP_NAME := 'GET PSE ID';
   SELECT PSE_ID
     INTO v_PSE_ID
     FROM SEM_SERVICE_POINT_PSE SEM
    WHERE SEM.POD_ID = p_POD_ID;

   g_PID       := PLOG.LOG_PROCESS_START('UPDATE_TLAF');
   g_RESULT    := PLOG.C_SEV_OK;
   p_STATUS    := GA.SUCCESS;
   g_PRES      := PLOG.LOG_PROCESS_EVENT(g_PID,
                                         PLOG.C_SEV_OK,
                                         g_PROC_NAME,
                                         g_STEP_NAME,
                                         'UPDATE_TLAF',
                                         'Process Started',
                                         'NOTIFICATION');
   g_step_name := 'Valid Report Information';

   CASE
      WHEN p_STARTDATE > p_ENDDATE THEN
         v_ERROR_MESSAGE := ' Start Greater than End Date ';
         v_CONTINUE      := FALSE;
         g_PRES          := PLOG.LOG_PROCESS_EVENT(g_PID,
                                                   PLOG.C_SEV_OK,
                                                   g_PROC_NAME,
                                                   g_STEP_NAME,
                                                   'UPDATE_TLAF',
                                                   ' Start Greater than End Date ',
                                                   'NOTIFICATION');
      WHEN (p_STARTDATE IS NULL OR 
            p_ENDDATE IS NULL   OR 
            v_PSE_ID IS NULL    OR
            p_POD_ID IS NULL    OR 
            p_DAY_TLAF IS NULL  OR 
            p_NIGHT_TLAF IS NULL) THEN
         v_ERROR_MESSAGE := ' Null Values for Loss Factor Grid is not allowed! ';
         g_PRES          := plog.log_process_event(g_PID,
                                                   PLOG.C_SEV_OK,
                                                   g_PROC_NAME,
                                                   g_STEP_NAME,
                                                   'UPDATE_TLAF',
                                                   ' Null Values for Loss Factor Grid is not allowed!',
                                                   'NOTIFICATION');
         v_CONTINUE      := FALSE;
      ELSE
         NULL;
   END CASE;
   
   SELECT COUNT(*)
     INTO v_COUNT
     FROM TLAF_INPUTS A
    WHERE A.POD_ID     = p_POD_ID
      AND A.PSE_ID     = v_PSE_ID
      AND A.BEGIN_DATE BETWEEN p_STARTDATE AND p_ENDDATE
      AND A.END_DATE   BETWEEN p_STARTDATE AND p_ENDDATE
      AND ROWID        <> p_REPORTID;
      
   IF v_COUNT > 0 THEN
      v_CONTINUE := FALSE;
      g_PRES     := PLOG.LOG_PROCESS_EVENT(g_PID,
                                           PLOG.C_SEV_OK,
                                           g_PROC_NAME,
                                           g_STEP_NAME,
                                           'UPDATE_TLAF',
                                           'Date overlap!',
                                           'NOTIFICATION');
   END IF;--IF v_COUNT > 0 THEN
   
   g_STEP_NAME := 'Update TLAF table';
   IF v_CONTINUE THEN
      
      IF P_REPORTID IS NULL THEN
      
         INSERT INTO TLAF_INPUTS
            (PSE_ID,
             POD_ID,
             BEGIN_DATE,
             END_DATE,
             DAY_TLAF,
             NIGHT_TLAF,
             TLAF_SEQUENCE,
             LOSS_NAME)
         VALUES
            (v_PSE_ID,
             p_POD_ID,
             p_STARTDATE,
             p_ENDDATE,
             p_DAY_TLAF,
             p_NIGHT_TLAF,
             TLAF_SEQ.NEXTVAL,
             p_LOSS_NAME);
             
         g_STEP_NAME := 'Get Report Sequence';
         SELECT TLAF_SEQ.CURRVAL INTO v_TLAF_SEQ FROM DUAL;
           
      ELSE--IF p_REPORTID IS NULL THEN
      
         UPDATE TLAF_INPUTS
            SET LOSS_NAME  = p_LOSS_NAME,
                BEGIN_DATE = p_STARTDATE,
                END_DATE   = p_ENDDATE,
                DAY_TLAF   = p_DAY_TLAF,
                NIGHT_TLAF = p_NIGHT_TLAF,
                POD_ID     = p_POD_ID,
                PSE_ID     = v_PSE_ID
          WHERE ROWID = p_REPORTID;
      
         g_step_name := 'Get Report Sequence';
         SELECT TLAF_SEQUENCE
           INTO v_TLAF_SEQ
           FROM TLAF_INPUTS
          WHERE ROWID = p_REPORTID;
      END IF;--IF p_REPORTID IS NULL THEN   
   
      COMMIT;
      
      DECLARE -- MERGE SECTION
         v_NEW_END_DATE    DATE;
         v_UPDATE_DAYS     NUMBER;
         v_LOSS_START      NUMBER;
         v_LOSS_END        NUMBER;
         v_LOSS_START_CHAR NUMBER;
         v_LOSS_END_CHAR   NUMBER;
         v_START_DATE      DATE;
         v_LOCAL_TIME_ZONE VARCHAR2(64) := LOCAL_TIME_ZONE;
         v_MIN_INTRVL_NUM  NUMBER;
         
      BEGIN -- MERGE SECTION
         g_STEP_NAME := 'Delete Old Information from 30 min table';
         DELETE FROM SEM_LOSS_FACTOR
          WHERE EVENT_ID = v_TLAF_SEQ;
      
         v_LOSS_START      := TRUNC(NVL(GET_DICTIONARY_VALUE('SEM_DAY_START',
                                                             0,
                                                             'MarketExchange',
                                                             'SEM',
                                                             'Loss Factor'),
                                        7));
         v_LOSS_END        := TRUNC(NVL(GET_DICTIONARY_VALUE('SEM_DAY_END',
                                                             0,
                                                             'MarketExchange',
                                                             'SEM',
                                                             'Loss Factor'),
                                        22));
         v_LOSS_START_CHAR := v_LOSS_START || '30';
         v_LOSS_END_CHAR   := v_LOSS_END || '00';
      
         v_UPDATE_DAYS := NVL((p_ENDDATE - p_STARTDATE), 2) + 1;
         v_START_DATE  := TO_CUT(p_STARTDATE, v_LOCAL_TIME_ZONE);
         
         -- Assumes data is always in 30min intervals.
         v_MIN_INTRVL_NUM := GET_INTERVAL_NUMBER(DATE_UTIL.c_NAME_30MIN);
      
         g_STEP_NAME := 'Merge Statement ';         
         IF p_STARTDATE IS NOT NULL AND 
            p_POD_ID    IS NOT NULL AND
            v_PSE_ID    IS NOT NULL AND 
            p_ENDDATE   IS NOT NULL THEN
            
            MERGE INTO SEM_LOSS_FACTOR B
            USING (SELECT SDT.CUT_DATE AS SCHEDULE_DATE,
                          CASE
                              WHEN TO_CHAR(SDT.LOCAL_DATE, 'HH24MI') 
                                   BETWEEN v_LOSS_START_CHAR AND v_LOSS_END_CHAR THEN
                               p_DAY_TLAF
                              ELSE
                               p_NIGHT_TLAF
                           END AS TLAF
                      FROM SYSTEM_DATE_TIME SDT,
                          (SELECT LEVEL              AS LOOP_ROW,
                                  TRUNC(p_STARTDATE) AS QUERY_DATE
                             FROM DUAL
                          CONNECT BY LEVEL <= v_UPDATE_DAYS
                           ) MAIN
                    WHERE SDT.TIME_ZONE                = v_LOCAL_TIME_ZONE
                      AND SDT.DATA_INTERVAL_TYPE       = 1
                      AND SDT.DAY_TYPE                 = 1
                      AND SDT.LOCAL_DAY_TRUNC_DATE     = MAIN.QUERY_DATE + MAIN.LOOP_ROW - 1
                      AND SDT.MINIMUM_INTERVAL_NUMBER >= v_MIN_INTRVL_NUM
                    ORDER BY SDT.LOCAL_DATE) E
            ON (B.SCHEDULE_DATE = E.SCHEDULE_DATE AND 
                B.POD_ID        = p_POD_ID)
            WHEN MATCHED THEN
               UPDATE
                  SET B.LOSS_FACTOR = E.TLAF,
                      B.PSE_ID      = v_PSE_ID,
                      B.EVENT_ID    = v_TLAF_SEQ
            WHEN NOT MATCHED THEN
               INSERT
                  (SCHEDULE_DATE,
                   PSE_ID,
                   POD_ID,
                   LOSS_FACTOR,
                   EVENT_ID)
               VALUES
                  (E.SCHEDULE_DATE,
                   v_PSE_ID,
                   p_POD_ID,
                   E.TLAF,
                   v_TLAF_SEQ);
         END IF;--IF p_STARTDATE IS NOT NULL AND 
         
      END; -- MERGE SECTION
      
   ELSE--IF v_CONTINUE THEN
      g_RESULT := PLOG.C_SEV_ERROR;
      p_STATUS := PLOG.C_SEV_ERROR;
   
   END IF;--IF v_CONTINUE THEN   
   
   g_STEP_NAME := 'END';
   g_REPORT    := 'PROCESS COMPLETE';
   p_STATUS    := g_RESULT;
   p_MESSAGE   := NULL;
   g_PRES      := PLOG.LOG_PROCESS_END(g_PID,
                                       g_RESULT,
                                       0,
                                       DEFAULT_PROCESS_MESSAGE(g_RESULT),
                                       g_REPORT);
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      HANDLE_EXCEPTION(SQLCODE, SQLERRM);
      ROLLBACK;
      RAISE;
END UPDATE_TLAF;
/*----------------------------------------------------------------------------*
 *   DELETE TLAF                                                              *
 *----------------------------------------------------------------------------*/
PROCEDURE DELETE_TLAF
(
   p_TLAF_SEQUENCE IN NUMBER,
   p_message       out varchar2,
   p_status        out number
) IS

v_error_message   varchar2(4000):='';
BEGIN

      -- START LOGGING --
   g_PROC_NAME := 'DELETE_TLAF';
   g_STEP_NAME := 'Initial';
   g_REPORT    := '';


   g_PID    := Plog.LOG_PROCESS_START('DELETE_TLAF');
   g_RESULT := Plog.c_SEV_OK;
   p_Status := Ga.SUCCESS;
   g_PRES   := Plog.LOG_PROCESS_EVENT(g_PID,
                                    Plog.c_SEV_OK,
                                    g_PROC_NAME,
                                    g_STEP_NAME,
                                    'DELETE_TLAF',
                                    'Process Started',
                                    'NOTIFICATION');

   IF p_TLAF_SEQUENCE is not null THEN

      delete from SEM_LOSS_FACTOR
      where  EVENT_ID = p_TLAF_SEQUENCE;

      delete from tlaf_inputs
      where  TLAF_SEQUENCE= p_TLAF_SEQUENCE;

   END IF;

   commit;

   g_STEP_NAME := 'END';
   g_REPORT    := 'Process Complete';
   p_STATUS    := g_RESULT;
   p_MESSAGE   := NULL;
   g_PRES      := Plog.LOG_PROCESS_END(g_PID, g_RESULT, 0, DEFAULT_PROCESS_MESSAGE(g_RESULT), g_REPORT);

   COMMIT;
EXCEPTION
  WHEN OTHERS THEN
       handle_exception(SQLCODE,SQLERRM);
       ROLLBACK;
       RAISE;

END  DELETE_TLAF ;
/*----------------------------------------------------------------------------*
 *  GET_SEM_LOSS                                                              *
 *----------------------------------------------------------------------------*/
PROCEDURE GET_SEM_LOSS
(
   P_BEGIN_DATE IN DATE,
   p_END_DATE   IN date,
   p_WINDFARM_FILTER IN VARCHAR2,
   p_CURSOR OUT REF_CURSOR
) IS
BEGIN

   OPEN p_CURSOR FOR
      SELECT *
      FROM  SEM_LOSS_FACTOR a
      where a.schedule_date between p_begin_Date and p_end_date
      ORDER BY  pod_id,pse_id,schedule_date ;

END GET_SEM_LOSS ;

  PROCEDURE POD
  (
   p_STATUS OUT NUMBER,
   p_CURSOR OUT REF_CURSOR
  ) IS

  BEGIN
      p_STATUS := GA.SUCCESS;

      OPEN p_CURSOR FOR
          SELECT DISTINCT
                 SP.EXTERNAL_IDENTIFIER POD_NAME,
                 SEM_SP.POD_ID
          FROM   PSE,
                 SEM_SERVICE_POINT_PSE SEM_SP,
                 SERVICE_POINT SP
          WHERE  PSE.PSE_EXTERNAL_IDENTIFIER <> '?'
          AND    PSE.PSE_ID = SEM_SP.PSE_ID
          AND    SP.SERVICE_POINT_ALIAS NOT LIKE 'SU%'
          AND    SP.SERVICE_POINT_ID = SEM_SP.POD_ID
          ORDER BY 1;

  END POD;

end MM_SEM_TLAF;
/
