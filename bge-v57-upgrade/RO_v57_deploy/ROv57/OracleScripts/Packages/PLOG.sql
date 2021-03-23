CREATE OR REPLACE PACKAGE PLOG
--Revision $Revision: 1.3 $
AS


/*============================================================================*
 *                        !!!   I M P O R T A N T !!!                         *
 *============================================================================*
 *                                                                            *
 * THIS PACKAGE IS A WORK-IN-PROGRESS AT PECO. IT'S BEEN EXTENSIVELY TESTED   *
 * AND MODIFIED FOR THE PECO IDR RE-DESIGN PROJECT.                           *
 *                                                                            *
 * PLEASE, CONTACT ALEX BOTVINIK TO REPORT BUGS AND TO REQUEST ADDITIONAL     *
FUNCTION WHAT_VERSION RETURN VARCHAR;

 * FUNCTIONALITY.                                                             *
 *                                                                            *
 *----------------------------------------------------------------------------*/

/*============================================================================*
 *                                DESCRIPTION                                 *
 *============================================================================*
 *                                                                            *
 * THIS PACKAGE PROVIDES A NUMBER OF FUNCTIONS FOR THE PROCESS LOGGING.       *
 *                                                                            *
 * THERE ARE TWO DATABASE TABLES INVOLVED IN THE PROCESS END EVENT LOGGING:   *
 *    PROCESSES AND PROCESS_EVENTS.                                           *
 *                                                                            *
 * FUNCTIONS ARE IMPLEMENTED AS AUTONOMOUS TRANSACTIONS AND DO NOT REQUIRE    *
 * ANY ADDITIONAL COMMIT OR ROLLBACK HANDLING. EVERY PROCESS AND EVENT WILL   *
 * BE COMMITED REGARDLESS OF THE STATE OF THE CALLING PROCEDURE.              *
 *                                                                            *
 * ALL FUNCTIONS WILL NEVER RAISE AN EXCEPTION BARRING THE INSTANCE FAILURE.  *
 * CALLING(PARENT) PROCESS CAN ANALYZE EXECUTION RESULTS BY USING CODES       *
 * RETURNED BY FUNCTIONS.                                                     *
 *                                                                            *
 * EVERY FUNCTION WITH THE EXCEPTION OF LOG_PROCESS_START WILL RETURN EITHER  *
 * c_OK OR c_ERROR. LOG_PROCESS_START RETURNS EITHER PROCESS_ID OR c_ERROR.   *
 *                                                                            *
 * IF FUNCTION RETURNS c_ERROR, THEN PARENT PROCESS MAY ANALYZE GLOBAL        *
 * VARIABLES v_SQLCODE AND v_SQLERRM. THIS VARIABLES WILL KEEP A COPY OF      *
 * THE ORACLE EXCEPTION DETAILS. USE OF THIS VARIABLES MAY NOT BE 100%        *
 * RELIABLE IN MULTI-THREADED PROCESSES THAT SHARE THE SAME DATABASE          *
 * CONNECTION. THE BEST SOLUTION IS TO USE "THREAD-SAFE" UNINTERRUPTABLE      *
 * PROCEDURES FOR PROCESS AND EVENT LOGGING.                                  *
 *                                                                            *
 * MOST OF THE FUNCTIONS HAVE DEFAULT VALUES FOR SOME PARAMETERS. USING       *
 * NAMING METHOD TO PASS PAREMETERS MAY BE REALLY CONVENIENT.                 *
 * EXAMPLE:                                                                   *
 * x := PLOG.LOG_PROCESS_START('ENROLLMENTS SYNC', p_PARAMETERS => 'MONTHLY') *
 *                                                                            *
 * PLEASE, REVIEW TABLE STRUCTURES AND COMMENTS IN THE PACKAGE DEFINITION     *
 * SECTION FOR THE ADDITIONAL INFORMATION AND DETAILS.                        *
 *                                                                            *
 *----------------------------------------------------------------------------*/

/*============================================================================*
 *                            MAINTENANCE HISTORY                             *
 *============================================================================*
 *    DATE    | AUTHOR |                    DESCRIPTION                       *
 *============================================================================*
 * 05/09/2001 | AB     | INITIAL RELEASE                                      *
 *----------------------------------------------------------------------------*
 * 05/15/2001 | AGY    | EXTENDED PROCEDURE_NAME TO 64                        *
 *----------------------------------------------------------------------------*
 * 07/30/2001 | AB     | CHANGED TO HANDLE DMBS_JOB STYLE OF EXECUTION        *
 *----------------------------------------------------------------------------*
 * 08/27/2001 | AB     | CHANGED TO HANDLE DMBS_JOB STYLE OF EXECUTION        *
 *----------------------------------------------------------------------------*
 * 04/07/2006 | AB     | ADDED GENERIC 'GET' APIS FOR DISPLAY PURPOSES        *
 *============================================================================*/

/*----------------------------------------------------------------------------*
 *   TYPE DECLARATIONS                                                        *
 *----------------------------------------------------------------------------*/

   -- PARENT PROCESS SHOULD DEFINE A VARIABLE OF THIS TYPE.
   -- THAT VARIABLE WILL BE USED FOR ALL CALLS TO THE FUNCTIONS IN THIS PACKAGE.
   SUBTYPE t_PROCESS_DESCRIPTOR   IS PROCESS_LOG.PROCESS_ID%TYPE;

   -- IMAGE OF THE ENTIRE RECORD OF THE PROCESSES TABLE.
   SUBTYPE t_PROCESS_RECORD       IS PROCESS_LOG%ROWTYPE;

   -- TYPE FOR THE PROCESS RETURN CODES AND EVENTS SEVERITY LEVELS
   SUBTYPE t_SEVERITY_CODE        IS PROCESS_LOG.PROCESS_STATUS%TYPE;

   /*
    *  A VALUE OF THIS TYPE WILL BE RETURNED BY ALL FUNCTIONS IN THIS PACKAGE.
    *  THERE ARE TWO POSSIBLE VALUES: c_OK AND c_ERROR.
	*
    *  c_ERROR WILL INDICATE AN EXCEPTION IN THE FUNCTION EXECUTION.
    *  PARENT PROCESS MAY RETRIEVE v_SQLERRM AND v_SQLCODE GLOBAL VARIABLES
	*  TO FURTHER ANALYZE OR REPORT AN EXCEPTION.
    */
   SUBTYPE t_PLOG_RESULT          IS t_PROCESS_DESCRIPTOR; -- NUMBER

   -- WILL BE USED BY AUDITING AND E-MAIL REPORTING MODULE --
   SUBTYPE t_ACTUALITY_STATUS     IS PROCESS_LOG.EXTERNAL_STATUS%TYPE; -- NUMBER

/*----------------------------------------------------------------------------*
 *   CONSTANTS                                                                *
 *----------------------------------------------------------------------------*/

   -- RETURN CODES SEE t_PLOG_RESULT ABOVE --
   c_OK                  CONSTANT t_PLOG_RESULT := 0;
   c_ERROR               CONSTANT t_PLOG_RESULT := -1;

   -- PARAMETERS --
   c_UPDATE              CONSTANT NUMBER := 0;
   c_ADD                 CONSTANT NUMBER := 1;

   -- PROCESS ACTUALITY STATUSES (PAS) SEE t_ACTUALITY_STATUS ABOVE --
   c_PAS_OK              CONSTANT t_ACTUALITY_STATUS := 0;
   c_PAS_NOT_IMPORTANT   CONSTANT t_ACTUALITY_STATUS := 4;
   c_PAS_IMPORTANT       CONSTANT t_ACTUALITY_STATUS := 8;
   c_PAS_CRITICAL        CONSTANT t_ACTUALITY_STATUS := 16;
   c_PAS_NOTIFIED        CONSTANT t_ACTUALITY_STATUS := 12;
   c_PAS_RESOLVED        CONSTANT t_ACTUALITY_STATUS := 2;

   -- SEVERITY LEVELS SEE t_SEVERITY_CODE ABOVE--
   c_SEV_OK              CONSTANT t_SEVERITY_CODE := LOGS.c_Level_Notice;
   c_SEV_WARNING         CONSTANT t_SEVERITY_CODE := LOGS.c_Level_Warn;
   c_SEV_ERROR           CONSTANT t_SEVERITY_CODE := LOGS.c_Level_Error;
   -- c_SEV_RESERVED        CONSTANT t_SEVERITY_CODE := 12;
   c_SEV_ABORT           CONSTANT t_SEVERITY_CODE := LOGS.c_Level_Fatal;

   -- CRLF MAY BE USEFUL FOR LONG MESSAGES --
   c_CRLF                CONSTANT VARCHAR2(2) := CHR(13)||CHR(10);

/*----------------------------------------------------------------------------*
 *   PUBLIC VARIABLES                                                         *
 *----------------------------------------------------------------------------*/

   -- WILL CONTAIN A COPY OF SQLERRM AND SQLCODE IN CASE OF EXCEPTION --
   v_SQLERRM             VARCHAR2(512);
   v_SQLCODE             NUMBER;

/*----------------------------------------------------------------------------*
 *   PUBLIC PROCEDURES AND FUNCTIONS                                          *
 *----------------------------------------------------------------------------*/

   /*
    * LOG_PROCESS_START INITIALIZES ALL FIELDS AND CREATES RECORD IN THE
	* PROCESSES TABLE.
	*
	* THIS FUNCTION WILL RETURN A PROCESS_DESCRIPTOR THAT MUST BE STORED AND
	* USED FOR ALL FUTURE CALLS TO THIS PACKAGE.
	*
	* FUNCTION WILL RETURN c_ERROR IF EXCEPTION OCCURES.
	*
	* p_TARGET_START_DATE, p_TARGET_STOP_DATE AND p_PARAMETERS ARE ALL
	* OPTIONAL FIELDS THAT MAY BE USED TO LOG PARAMETERS PASSED TO THE
	* PARENT PROCESS.
	*
	* EXAMPLE 1:
	* x := PLOG.LOG_PROCESS_START('ENROLLMENTS SYNC','1-MAY-01','26-JUN-01','MONTHLY');
	*
	* EXAMPLE 2:
	* x := PLOG.LOG_PROCESS_START('ENROLLMENTS SYNC', p_PARAMETERS => 'MONTHLY');
    */
   FUNCTION LOG_PROCESS_START
   (
      p_PROCESS_NAME                 IN PROCESS_LOG.PROCESS_NAME%TYPE,
	  p_TARGET_START_DATE            IN DATE DEFAULT NULL,
      p_TARGET_STOP_DATE             IN DATE DEFAULT NULL,
      p_PARAMETERS                   IN VARCHAR2 DEFAULT NULL
   ) RETURN t_PROCESS_DESCRIPTOR;

   /*
    * LOG_PROCESS_END UPDATES PROCESSES RECORD TO REFLECT THE END OF THE PROCESS.
	*
	* p_RETURN_CODE MUST CONTAIN ONE OF THE PRE-DEFINED c_SEV_xxx CODES.
	* p_EXTENDED_RETURN_CODE MAY BE SET TO ANY NUMBER OR NULL.
	*
	* IN CASE OF PROCESS EXCEPTION p_MESSAGE MUST(!) CONTAIN SQLERRM WITH
	* THE TEXT OF ORACLE ERROR.
	*
	* p_MESSAGE_DESCRIPTION SHOULD HAVE A USER-FRIENDLY(!) DESCRIPTION OF
	* THE PROCESS COMPLETION. IT SHOULD ALWAYS BE POPULATED IN THE EVENT
	* OF PROCESS ERROR.
	*
    */
   FUNCTION LOG_PROCESS_END
   (
      p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
      p_RETURN_CODE                  IN t_SEVERITY_CODE,
      p_EXTENDED_RETURN_CODE         IN PROCESS_LOG.PROCESS_CODE%TYPE,
   	  p_MESSAGE                      IN VARCHAR2,
   	  p_MESSAGE_DESCRIPTION          IN VARCHAR2
   ) RETURN t_PLOG_RESULT;

   /*
    * INIT_PROCESS_STATS FUNCTION INITIALIZES PROGRESS STATASTICS FOR THE PROCESS.
	*
	* p_TOTAL_WORK SHOULD BE SET TO THE TOTAL NUMBER OF THE
	* ABSTRACT UNITS OF WORK.
	*
	* p_UNITS SHOULD CONTIAN A NAME FOR THE UNIT OF WORK. EXAMPLES:
	*    "units" - FOR GENERIC UNITS
	*    "steps" - ABSTRACT PROCESSING STEPS
	*    "accounts"
	*    "days"
	*
	* p_PROGRESS_DESCRIPTION SHOULD HAVE A USER-FRIENDLY DESCRIPTION OF
	* WHAT PROCESS IS CURRENTLY DOING.
	*
	*/
   FUNCTION INIT_PROCESS_STATS
   (
      p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
      p_TOTAL_WORK 					 IN PROCESS_LOG.PROGRESS_TOTALWORK%TYPE,
      p_UNITS 						 IN PROCESS_LOG.PROGRESS_UNITS%TYPE,
	  p_PROGRESS_DESCRIPTION         IN VARCHAR2
   ) RETURN t_PLOG_RESULT;

   /*
    * UPDATE_PROCESS_PROGRESS FUNCTION UPDATES PROGRESS STATISTICS.
	*
	* p_SO_FAR SHOULD CONTAIN NUMBER OF PROCESSES UNITS OF WORK.
	* PROCESSING OF THE SO_FAR NUMBER WILL BE DIFFERENT BASED ON p_ADD_FLAG.
	*
	* IF p_ADD_FLAG IS NOT PRESENT OR SET TO c_UPDATE THEN PROCESSES TABLE
	* SO_FAR FIELD WILL BE SET TO THE PASSED VALUE.
	*
	* IF p_ADD_FLAG IS SET TO c_ADD THEN PASSED VALUE WILL BE ADDED TO THE
	* CURRENT SO_FAR VALUE IN THE PROCESSES TABLE.
	*
	* SEE INIT_PROCESS_STATS ABOVE FOR THE ADDITIONAL DETAILS.
	*
    */
   FUNCTION UPDATE_PROCESS_PROGRESS
   (
      p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
      p_SO_FAR  					 IN PROCESS_LOG.PROGRESS_SOFAR%TYPE,
	  p_PROGRESS_DESCRIPTION         IN VARCHAR2,
	  p_ADD_FLAG                     IN NUMBER DEFAULT c_UPDATE
   ) RETURN t_PLOG_RESULT;

   /*
    * LOG_PROCESS_EVENT INSERTS NEW RECORD INTO THE PROCESS_EVENTS TABLE AND
	* INCREMENTS EVENT COUNT IN THE PROCESSES TABLE.
	*
	* p_SEVERITY_LEVEL MUST(!) CONTAIN ONE OF THE PRE-DEFINED c_SEV_xxx CODES.
	*
	* p_PROCEDURE_NAME AND p_STEP_NAME SHOULD IDENTIFY A STEP IN THE PARENT
	* PROCESS THAT CAUSED AN EVENT.
	*
	* p_SOURCE SHOULD HAVE A "DUMP" OF THE PROBLEMATIC DATA. FOR EXAMPLE, BAD RECORD.
	*
	* p_MESSAGE SHOULD BE SET TO SQLERRM, IF POSSIBLE. THAT IS A MUST FOR THE
	* ORACLE EXCEPTIONS HANDLING.
	*
	* p_MESSAGE_DESCRIPTION SHOULD HAVE A USER-FRIENDLY(!) DESCRIPTION OF THE EVENT.
	*
	*/
   FUNCTION LOG_PROCESS_EVENT
   (
      p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
      p_SEVERITY_LEVEL               IN t_SEVERITY_CODE,
      p_PROCEDURE_NAME               IN VARCHAR2 DEFAULT NULL,
      p_STEP_NAME                    IN VARCHAR2 DEFAULT NULL,
      p_SOURCE                       IN VARCHAR2 DEFAULT NULL,
      p_MESSAGE                      IN VARCHAR2 DEFAULT NULL,
      p_MESSAGE_DESCRIPTION          IN VARCHAR2 DEFAULT NULL
   ) RETURN t_PLOG_RESULT;

END PLOG;
/
CREATE OR REPLACE PACKAGE BODY PLOG
AS

/*============================================================================*
 *   PACKAGE BODY                                                             *
 *============================================================================*/
c_PARAM_OTHERS CONSTANT VARCHAR2(6) := 'Others';

----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE VALIDATE_PROCESS_ID
(
p_PROCESS_ID IN NUMBER
) IS
BEGIN
	ASSERT(p_PROCESS_ID = LOGS.CURRENT_PROCESS_ID(),
	       'Process ID ' || p_PROCESS_ID || ' is not the current process',
		   MSGCODES.c_ERR_ARGUMENT);
END;
/*----------------------------------------------------------------------------*
 *   PUBLISH_SQLCODE                                                          *
 *----------------------------------------------------------------------------*/
PROCEDURE PUBLISH_SQLCODE IS
BEGIN
   v_SQLCODE := SQLCODE;
   v_SQLERRM := SQLERRM;
END;

/*----------------------------------------------------------------------------*
 *   LOG_PROCESS_START                                                        *
 *----------------------------------------------------------------------------*/
FUNCTION LOG_PROCESS_START
(
   p_PROCESS_NAME                 IN PROCESS_LOG.PROCESS_NAME%TYPE,
   p_TARGET_START_DATE            IN DATE DEFAULT NULL,
   p_TARGET_STOP_DATE             IN DATE DEFAULT NULL,
   p_PARAMETERS                   IN VARCHAR2 DEFAULT NULL
) RETURN t_PROCESS_DESCRIPTOR IS
BEGIN
	LOGS.START_PROCESS(p_PROCESS_NAME, p_TARGET_START_DATE, p_TARGET_STOP_DATE);	
	LOGS.SET_PROCESS_TARGET_PARAMETER(c_PARAM_OTHERS, p_PARAMETERS);	
	RETURN LOGS.CURRENT_PROCESS_ID();
EXCEPTION
   WHEN OTHERS THEN
      PUBLISH_SQLCODE;
      RETURN c_ERROR;
END;

/*----------------------------------------------------------------------------*
 *   LOG_PROCESS_END                                                          *
 *----------------------------------------------------------------------------*/
FUNCTION LOG_PROCESS_END
(
   p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
   p_RETURN_CODE                  IN t_SEVERITY_CODE,
   p_EXTENDED_RETURN_CODE         IN PROCESS_LOG.PROCESS_CODE%TYPE,
   p_MESSAGE                      IN VARCHAR2,
   p_MESSAGE_DESCRIPTION          IN VARCHAR2
) RETURN t_PLOG_RESULT IS
v_RETURN_CODE			t_SEVERITY_CODE := p_RETURN_CODE;
v_MESSAGE_DESCRIPTION	VARCHAR2(4000) := SUBSTR(p_MESSAGE_DESCRIPTION,1,4000);
BEGIN
	VALIDATE_PROCESS_ID(P_PROCESS_ID);
	LOGS.STOP_PROCESS(v_MESSAGE_DESCRIPTION,v_RETURN_CODE,p_EXTENDED_RETURN_CODE, p_MESSAGE);
	RETURN C_OK;
EXCEPTION
   WHEN OTHERS THEN
      PUBLISH_SQLCODE;
      RETURN c_ERROR;
END;

/*----------------------------------------------------------------------------*
 *   INIT_PROCESS_STATS                                                       *
 *----------------------------------------------------------------------------*/
FUNCTION INIT_PROCESS_STATS
(
   p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
   p_TOTAL_WORK 				  IN PROCESS_LOG.PROGRESS_TOTALWORK%TYPE,
   p_UNITS 						  IN PROCESS_LOG.PROGRESS_UNITS%TYPE,
   p_PROGRESS_DESCRIPTION         IN VARCHAR2
) RETURN t_PLOG_RESULT IS
BEGIN
	VALIDATE_PROCESS_ID(P_PROCESS_ID);
	LOGS.INIT_PROCESS_PROGRESS(p_PROGRESS_DESCRIPTION, p_TOTAL_WORK, p_UNITS);
	RETURN C_OK;
EXCEPTION
   WHEN OTHERS THEN
      PUBLISH_SQLCODE;
      RETURN c_ERROR;
END;

/*----------------------------------------------------------------------------*
 *   UPDATE_PROCESS_PROGRESS                                                  *
 *----------------------------------------------------------------------------*/
FUNCTION UPDATE_PROCESS_PROGRESS
(
   p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
   p_SO_FAR  					  IN PROCESS_LOG.PROGRESS_SOFAR%TYPE,
   p_PROGRESS_DESCRIPTION         IN VARCHAR2,
   p_ADD_FLAG                     IN NUMBER DEFAULT c_UPDATE
) RETURN t_PLOG_RESULT IS
BEGIN
    VALIDATE_PROCESS_ID(P_PROCESS_ID);
	IF P_ADD_FLAG = C_ADD THEN
		LOGS.INCREMENT_PROCESS_PROGRESS(P_SO_FAR, P_PROGRESS_DESCRIPTION);
	ELSE
		LOGS.UPDATE_PROCESS_PROGRESS(P_SO_FAR, P_PROGRESS_DESCRIPTION);
	END IF;
	RETURN C_OK;
EXCEPTION
   WHEN OTHERS THEN
      PUBLISH_SQLCODE;
      RETURN c_ERROR;
END;

/*----------------------------------------------------------------------------*
 *   LOG_PROCESS_EVENT                                                        *
 *----------------------------------------------------------------------------*/
FUNCTION LOG_PROCESS_EVENT
(
   p_PROCESS_ID                   IN t_PROCESS_DESCRIPTOR,
   p_SEVERITY_LEVEL               IN t_SEVERITY_CODE,
   p_PROCEDURE_NAME               IN VARCHAR2 DEFAULT NULL,
   p_STEP_NAME                    IN VARCHAR2 DEFAULT NULL,
   p_SOURCE                       IN VARCHAR2 DEFAULT NULL,
   p_MESSAGE                      IN VARCHAR2 DEFAULT NULL,
   p_MESSAGE_DESCRIPTION          IN VARCHAR2 DEFAULT NULL
) RETURN t_PLOG_RESULT IS
BEGIN
	VALIDATE_PROCESS_ID(p_PROCESS_ID);
	LOGS.LOG_EVENT(p_SEVERITY_LEVEL, p_MESSAGE_DESCRIPTION,
		       p_PROCEDURE_NAME, p_STEP_NAME,
		       p_SOURCE, p_SQLERRM => p_MESSAGE);
	RETURN c_OK;
EXCEPTION
   WHEN OTHERS THEN
      PUBLISH_SQLCODE;
      RETURN c_ERROR;
END LOG_PROCESS_EVENT;

END PLOG;
/
