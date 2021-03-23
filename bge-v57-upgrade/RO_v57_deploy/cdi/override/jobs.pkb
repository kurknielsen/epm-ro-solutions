CREATE OR REPLACE PACKAGE BODY JOBS IS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
-- Helper function for translating dates from the Jobs tables to a date relative
-- to the client clock.
FUNCTION GET_LOCAL_DATE_FOR_JOB
	(
	p_JOB_DATE IN TIMESTAMP WITH TIME ZONE,
	p_CLIENT_CLOCK IN DATE
	) RETURN DATE IS
BEGIN
	RETURN ROUND(SYS_EXTRACT_UTC(p_JOB_DATE) - (CURRENT_DATE - p_CLIENT_CLOCK), 'MI');
END GET_LOCAL_DATE_FOR_JOB;
----------------------------------------------------------------------------------------------------
-- Raise an exception if the current user does not have access to modify the specified job.
PROCEDURE CHECK_JOB_PRIVILEGE
	(
	p_JOB_NAME IN VARCHAR2
	) AS
	v_JOB_OWNER BACKGROUND_JOBS.USER_ID%TYPE;
BEGIN
	SELECT USER_ID INTO v_JOB_OWNER FROM BACKGROUND_JOBS WHERE JOB_NAME = p_JOB_NAME;
	IF v_JOB_OWNER IS NULL OR v_JOB_OWNER <> SECURITY_CONTROLS.CURRENT_USER_ID THEN SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_MANAGE_ALL_JOBS); END IF;
END CHECK_JOB_PRIVILEGE;
----------------------------------------------------------------------------------------------------
-- Raise an exception if the current user does not have access to modify the specified queue item.
PROCEDURE CHECK_QUEUE_ITEM_PRIVILEGE
	(
	p_JOB_QUEUE_ITEM_ID IN NUMBER
	) AS
v_OWNER NUMBER(9);
BEGIN

	SELECT I.USER_ID
	INTO v_OWNER
	FROM JOB_QUEUE_ITEM I
	WHERE I.JOB_QUEUE_ITEM_ID = p_JOB_QUEUE_ITEM_ID;

	IF v_OWNER <> SECURITY_CONTROLS.CURRENT_USER_ID THEN
		SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_MANAGE_ALL_JOBS);
	END IF;

END CHECK_QUEUE_ITEM_PRIVILEGE;
----------------------------------------------------------------------------------------------------
-- Sends a job initiated from the Java UI to the DBMS_SCHEDULER.
FUNCTION START_BACKGROUND_ACTION
	(
	p_PLSQL IN VARCHAR2,
	p_RUN_WHEN IN DATE,
	p_JOB_CLASS IN VARCHAR2,
	p_ACTION_CHAIN_NAME IN VARCHAR2,
	p_ACTION_DISPLAY_NAME IN VARCHAR2,
	p_NOTIFICATION_EMAIL_ADDRESS IN VARCHAR2,
	p_SEND_EMAIL_WHEN_COMPLETE IN NUMBER,
	p_CLIENT_CLOCK IN DATE
	) RETURN VARCHAR2 IS

	v_JOB_DATA JOB_DATA%ROWTYPE;
	v_START_TIME DATE;
	v_RTN VARCHAR2(256);
	v_INDENTED_PLSQL VARCHAR2(4000);



BEGIN

	v_JOB_DATA.ACTION_CHAIN_NAME := p_ACTION_CHAIN_NAME;
	v_JOB_DATA.ACTION_DISPLAY_NAME := p_ACTION_DISPLAY_NAME;
	v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS := CASE WHEN p_SEND_EMAIL_WHEN_COMPLETE = 1 THEN p_NOTIFICATION_EMAIL_ADDRESS ELSE NULL END;

	v_START_TIME := p_RUN_WHEN + (CURRENT_DATE - p_CLIENT_CLOCK);

	v_INDENTED_PLSQL := REPLACE(p_PLSQL, CHR(10), CHR(10)||'		');

	v_INDENTED_PLSQL :=
'DECLARE
	v_PROCESS_ID VARCHAR2(12);
	v_PROCESS_STATUS NUMBER(9);
	v_MESSAGE VARCHAR2(2000);
	v_WAS_TERMINATED PROCESS_LOG.WAS_TERMINATED%TYPE;
	v_STATUS VARCHAR2(32);
	v_SEE_LOG_MESSAGE VARCHAR2(200);

BEGIN
		'|| v_INDENTED_PLSQL || '
	-- SEND A MESSAGE WHEN THE JOB COMPLETES

	IF v_MESSAGE IS NOT NULL THEN
		v_MESSAGE := ''The job finished with the following message: '' ||
			UTL_TCP.CRLF || UTL_TCP.CRLF || v_MESSAGE; -- SPACE THE FINISH MESSAGE
	END IF;

	IF v_PROCESS_ID IS NOT NULL THEN

		SELECT MAX(PL.WAS_TERMINATED)
		INTO v_WAS_TERMINATED
		FROM PROCESS_LOG PL
		WHERE PL.PROCESS_ID = TO_NUMBER(v_PROCESS_ID);

		v_STATUS := LOG_REPORTS.GET_STATUS_LEVEL_STRING(LOGS.GET_PROCESS_SEVERITY(TO_NUMBER(v_PROCESS_ID)), v_WAS_TERMINATED);

		IF v_PROCESS_ID IS NOT NULL AND v_PROCESS_STATUS IS NOT NULL THEN
			v_SEE_LOG_MESSAGE := UTL_TCP.CRLF || UTL_TCP.CRLF || ''Please see the process log for more details.'';
		END IF;

		MESSAGES.SEND_SYSTEM_MESSAGE(''Job ''|| v_STATUS || '': '' || ' || UT.GET_LITERAL_FOR_STRING(p_ACTION_CHAIN_NAME) || ', ' ||
			'  ''Your background job has finished.'' || v_MESSAGE || v_SEE_LOG_MESSAGE, ' || UT.GET_LITERAL_FOR_NUMBER(SECURITY_CONTROLS.CURRENT_USER_ID) || ',
			NULL, TO_NUMBER(v_PROCESS_ID));
	ELSE
		MESSAGES.SEND_SYSTEM_MESSAGE(''Job Finished: '' || ' || UT.GET_LITERAL_FOR_STRING(p_ACTION_CHAIN_NAME) || ', ' ||
			'  ''Your background job has finished.'' || v_MESSAGE, ' ||
			UT.GET_LITERAL_FOR_NUMBER(SECURITY_CONTROLS.CURRENT_USER_ID) || ');
	END IF;

	EXCEPTION WHEN OTHERS THEN

		-- SEND A MESSAGE WHEN THE JOB FAILS
		MESSAGES.SEND_SYSTEM_MESSAGE(''Job Fatal: '' || ' || UT.GET_LITERAL_FOR_STRING(p_ACTION_CHAIN_NAME) || ', ''' ||
			'Your background job was unable to complete.  It failed with the following exception: '' ||' ||
			'UTL_TCP.CRLF || UTL_TCP.CRLF || UT.GET_FULL_ERRM, ' || UT.GET_LITERAL_FOR_NUMBER(SECURITY_CONTROLS.CURRENT_USER_ID) || ');

		ERRS.LOG_AND_RAISE;
END;
';

	--Send the job to the scheduler.
	v_RTN := SECURITY_CONTROLS.START_BACKGROUND_JOB(v_INDENTED_PLSQL, v_START_TIME, NVL(p_JOB_CLASS, 'DEFAULT_JOB_CLASS'), NULL, v_JOB_DATA);

	LOGS.LOG_DEBUG_DETAIL('JOBS.START_BACKGROUND_ACTION JOB_NAME="'||v_RTN||'"');
	LOGS.LOG_DEBUG_DETAIL('p_RUN_WHEN='|| TEXT_UTIL.TO_CHAR_TIME(p_RUN_WHEN));
	LOGS.LOG_DEBUG_DETAIL('CURRENT_DATE='|| TEXT_UTIL.TO_CHAR_TIME(CURRENT_DATE));
	LOGS.LOG_DEBUG_DETAIL('p_CLIENT_CLOCK='|| TEXT_UTIL.TO_CHAR_TIME(p_CLIENT_CLOCK));
	LOGS.LOG_DEBUG_DETAIL('v_START_TIME='|| TEXT_UTIL.TO_CHAR_TIME(v_START_TIME));

	--Return the Job Name of the job that was queued.
	RETURN v_RTN;

END START_BACKGROUND_ACTION;
----------------------------------------------------------------------------------------------------
-- Stage a CLOB to the BACKGROUND_CLOB_STAGING table from the Java UI
-- and return its ID so that it can be used when a background job executes.
FUNCTION STAGE_CLOB
	(
	p_LOB IN CLOB
	) RETURN NUMBER IS
	v_ID NUMBER;
BEGIN
	SELECT BACKGROUND_LOB_ID.NEXTVAL INTO v_ID FROM DUAL;

	INSERT INTO BACKGROUND_CLOB_STAGING(BACKGROUND_LOB_ID, CLOB_VAL, ENTRY_DATE)
	VALUES (v_ID, p_LOB, SYSDATE);

	RETURN v_ID;
END STAGE_CLOB;
----------------------------------------------------------------------------------------------------
-- Stage a BLOB to the BACKGROUND_BLOB_STAGING table from the Java UI
-- and return its ID so that it can be used when a background job executes.
FUNCTION STAGE_BLOB
	(
	p_LOB IN BLOB
	) RETURN NUMBER IS
	v_ID NUMBER;
BEGIN
	SELECT BACKGROUND_LOB_ID.NEXTVAL INTO v_ID FROM DUAL;

	INSERT INTO BACKGROUND_BLOB_STAGING(BACKGROUND_LOB_ID, BLOB_VAL, ENTRY_DATE)
	VALUES (v_ID, p_LOB, SYSDATE);

	RETURN v_ID;
END STAGE_BLOB;
----------------------------------------------------------------------------------------------------
-- Return the number of jobs scheduled by the current user that are in the queue.
FUNCTION NUM_JOBS_IN_QUEUE_FOR_ME RETURN NUMBER IS
	v_COUNT NUMBER;
BEGIN
	SELECT COUNT(1)
	INTO v_COUNT
	FROM BACKGROUND_JOBS J
	WHERE J.USER_ID = SECURITY_CONTROLS.CURRENT_USER_ID
		AND J.FROM_LOG = 0; -- exclude old jobs from the job log

	RETURN v_COUNT;
END NUM_JOBS_IN_QUEUE_FOR_ME;
----------------------------------------------------------------------------------------------------
-- Master grid procedure for the Background Job Status screen
PROCEDURE GET_JOB_STATUS_SUMMARY
	(
	p_CLIENT_CLOCK IN DATE,
	p_SEE_ALL_JOBS IN NUMBER,
	p_INCLUDE_LOG IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
	c_UNK CONSTANT VARCHAR2(64) := '<html><i>Other</i></html>';
	c_VAR CONSTANT VARCHAR2(64) := '<html><i>Various</i></html>';
BEGIN
	IF p_SEE_ALL_JOBS = 1 THEN SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_MANAGE_ALL_JOBS); END IF;

	OPEN p_CURSOR FOR
		SELECT CASE WHEN J.CONTEXT_NAME IS NULL THEN c_UNK ELSE J.CONTEXT_NAME END AS CONTEXT_NAME,
			J.CONTEXT_NAME AS ACTION_CHAIN_NAME,
			CASE WHEN MIN(NVL(U.USER_NAME,c_UNK)) = MAX(NVL(U.USER_NAME,c_UNK)) THEN MIN(NVL(U.USER_NAME,c_UNK)) ELSE c_VAR END AS USER_NAME,
			MIN(GET_LOCAL_DATE_FOR_JOB(J.START_DATE, p_CLIENT_CLOCK)) AS MIN_START_DATE,
			CASE WHEN AVG(NVL(J.PROGRESS,-999999999)) < 0 THEN NULL ELSE AVG(J.PROGRESS) END AS AVG_PROGRESS,
			MAX(CASE WHEN J.STATE = 'RUNNING' THEN 1 ELSE 0 END) AS IS_RUNNING
		FROM BACKGROUND_JOBS J, APPLICATION_USER U
		WHERE (p_SEE_ALL_JOBS = 1 OR J.USER_ID = SECURITY_CONTROLS.CURRENT_USER_ID)
			AND J.USER_ID = U.USER_ID(+)
			AND (J.FROM_LOG = 0 OR NVL(p_INCLUDE_LOG,0) <> 0)
		GROUP BY J.CONTEXT_NAME
		ORDER BY MIN_START_DATE;

END GET_JOB_STATUS_SUMMARY;
----------------------------------------------------------------------------------------------------
-- Detail grid procedure for the Background Job Status screen
PROCEDURE GET_JOB_STATUS_DETAIL
	(
	p_ACTION_CHAIN_NAME IN VARCHAR2,
	p_CLIENT_CLOCK IN DATE,
	p_SEE_ALL_JOBS IN NUMBER,
	p_INCLUDE_LOG IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	IF p_SEE_ALL_JOBS = 1 THEN SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_MANAGE_ALL_JOBS); END IF;

	OPEN p_CURSOR FOR
		SELECT U.USER_NAME,
			J.ACTION_DISPLAY_NAME,
			J.PROCESS_NAME,
			CASE SCHEDULE_TYPE WHEN 'NAMED' THEN NULL ELSE GET_LOCAL_DATE_FOR_JOB(J.START_DATE, p_CLIENT_CLOCK) END AS START_DATE,
			J.PROGRESS,
			J.PROGRESS_DESCRIPTION,
			J.EXPECTED_COMPLETION,
			J.STATE,
			J.JOB_NAME,
			J.JOB_CLASS,
			J.SCHEDULE_NAME,
			J.SCHEDULE_TYPE,
			J.REPEAT_INTERVAL,
			CASE SCHEDULE_TYPE WHEN 'ONCE' THEN NULL ELSE GET_LOCAL_DATE_FOR_JOB(J.LAST_START_DATE, p_CLIENT_CLOCK) END AS LAST_START_DATE,
			CASE SCHEDULE_TYPE WHEN 'ONCE' THEN NULL ELSE GET_LOCAL_DATE_FOR_JOB(J.NEXT_RUN_DATE, p_CLIENT_CLOCK) END AS NEXT_RUN_DATE,
			J.COMMENTS,
			J.PROGRAM_OWNER,
			J.PROGRAM_NAME,
         J.SCHEDULE_NAME "OLD_SCHEDULE_NAME", --@@Implementation Override--
			J.FROM_LOG,
			TO_CHAR(J.PROCESS_ID) as PROCESS_ID,
			LOG_REPORTS.GET_STATUS_LEVEL_STRING(J.PROCESS_STATUS, J.WAS_TERMINATED) as PROCESS_STATUS
		FROM BACKGROUND_JOBS J, APPLICATION_USER U
		WHERE (J.CONTEXT_NAME = p_ACTION_CHAIN_NAME OR (J.CONTEXT_NAME IS NULL AND p_ACTION_CHAIN_NAME IS NULL))
			AND (p_SEE_ALL_JOBS = 1 OR J.USER_ID = SECURITY_CONTROLS.CURRENT_USER_ID)
			AND J.USER_ID = U.USER_ID(+)
			AND (J.FROM_LOG = 0 OR NVL(p_INCLUDE_LOG,0) <> 0)
		ORDER BY JOB_NAME, START_DATE;

END GET_JOB_STATUS_DETAIL;
----------------------------------------------------------------------------------------------------
-- Put Procedure for Detail grid of Background Job Status screen
PROCEDURE PUT_JOB_STATUS_DETAIL
	(
	p_JOB_NAME IN VARCHAR2,
	p_START_DATE IN DATE,
	p_CLIENT_CLOCK IN DATE,
   p_SCHEDULE_NAME IN VARCHAR2,    --@@Implementation Override--
   p_OLD_SCHEDULE_NAME IN VARCHAR2 --@@Implementation Override--
	) AS
	v_START_TIME DATE;
BEGIN
	CHECK_JOB_PRIVILEGE(p_JOB_NAME);
   IF p_OLD_SCHEDULE_NAME <> p_SCHEDULE_NAME THEN  --@@Implementation Override--
      DBMS_SCHEDULER.SET_ATTRIBUTE(p_JOB_NAME, 'SCHEDULE_NAME', p_SCHEDULE_NAME);  --@@Implementation Override--
   ELSE
      v_START_TIME := p_START_DATE + (CURRENT_DATE - p_CLIENT_CLOCK);
      DBMS_SCHEDULER.SET_ATTRIBUTE(p_JOB_NAME, 'START_DATE', v_START_TIME);
   END IF;
END PUT_JOB_STATUS_DETAIL;
----------------------------------------------------------------------------------------------------
-- Put Procedure for Detail grid of Background Job Status screen -- drops the specified job.
PROCEDURE DEL_JOB_STATUS_DETAIL
	(
	p_JOB_NAME IN VARCHAR2
	) AS
BEGIN
	CHECK_JOB_PRIVILEGE(p_JOB_NAME);
	DBMS_SCHEDULER.DROP_JOB(p_JOB_NAME);
END DEL_JOB_STATUS_DETAIL;
----------------------------------------------------------------------------------------------------
-- Enable job from Detail grid of Background Job Status screen
PROCEDURE ENABLE_JOB
	(
	p_JOB_NAME IN VARCHAR2
	) AS
BEGIN
	CHECK_JOB_PRIVILEGE(p_JOB_NAME);
	DBMS_SCHEDULER.ENABLE(p_JOB_NAME);
END ENABLE_JOB;
----------------------------------------------------------------------------------------------------
-- Disable job from Detail grid of Background Job Status screen
PROCEDURE DISABLE_JOB
	(
	p_JOB_NAME IN VARCHAR2
	) AS
BEGIN
	CHECK_JOB_PRIVILEGE(p_JOB_NAME);

	-- Disable using the Force.  This allows us to disable the job even if it is running.
	-- The currently running instance will be allowed to complete, then the job will be disabled.
	DBMS_SCHEDULER.DISABLE(name => p_JOB_NAME, force => TRUE);
END DISABLE_JOB;
----------------------------------------------------------------------------------------------------
-- This private procedure inserts a new record in the JOB_QUEUE_ITEM table.
-- This uses an Autonomous TXN.
-- This method also calculates the next ITEM_ORDER value for the JOB_QUEUE_ITEM.
PROCEDURE PUT_JOB_QUEUE_ITEM
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_PLSQL IN VARCHAR2,
	p_COMMENTS IN VARCHAR2 := NULL,
	p_NOTIFICATION_EMAIL_ADDRESS IN VARCHAR2 := NULL
	) AS
v_ITEM_ORDER 		JOB_QUEUE_ITEM.ITEM_ORDER%TYPE;
v_DUMMY_LOCK 				MUTEX.t_HANDLE;

-- Use an Autonomous TXN to ensure that the value is committed to the prior to a call to DEQUEUE
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN

	-- Acquire a lock so that we ensure that the item_order is calculated properly
	v_DUMMY_LOCK := MUTEX.ACQUIRE('NQ' || p_JOB_THREAD_ID, p_RELEASE_ON_COMMIT => TRUE);

	-- Determine the next order in the Queue for this Job Thread
	SELECT NVL(MAX(J.ITEM_ORDER),0) + 1
	INTO v_ITEM_ORDER
	FROM JOB_QUEUE_ITEM J
	WHERE J.JOB_THREAD_ID = p_JOB_THREAD_ID;

	-- Add JOB_QUEUE_ITEM to the table
	INSERT INTO JOB_QUEUE_ITEM
		(JOB_QUEUE_ITEM_ID, JOB_THREAD_ID, ITEM_ORDER, COMMENTS, USER_ID, PLSQL, NOTIFICATION_EMAIL_ADDRESS, ENTRY_DATE)
	VALUES
		(JOB_QUEUE_ITEM_ID.NEXTVAL,
		p_JOB_THREAD_ID,
		v_ITEM_ORDER,
		p_COMMENTS,
		SECURITY_CONTROLS.CURRENT_USER_ID,
		p_PLSQL,
		p_NOTIFICATION_EMAIL_ADDRESS,
		SYSDATE);

	COMMIT;

END PUT_JOB_QUEUE_ITEM;
----------------------------------------------------------------------------------------------------
-- Adds an Item to the JOB_QUEUE_ITEM table to be processed. This allows for mutliple job queues to
-- run in parallel by Job Thread. It also allows Job Queue Items to run in a FIFO order.
-- If the p_JOB_THREAD_ID is null, then the p_PLSQL statement is executed immediately using
-- SECURITY_CONTROLS.START_BACKGROUND_JOB().
PROCEDURE ENQUEUE_BY_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_PLSQL IN VARCHAR2,
	p_COMMENTS IN VARCHAR2 := NULL,
	p_NOTIFICATION_EMAIL_ADDRESS IN VARCHAR2 := NULL
	) AS
v_JOB_DATA JOB_DATA%ROWTYPE;
v_DUMMY_JOB_NAME VARCHAR2(30);
BEGIN

	IF p_JOB_THREAD_ID IS NULL THEN
		v_JOB_DATA.NOTIFICATION_EMAIL_ADDRESS := p_NOTIFICATION_EMAIL_ADDRESS;
		v_DUMMY_JOB_NAME := SECURITY_CONTROLS.START_BACKGROUND_JOB(p_PLSQL,NULL,NULL,p_COMMENTS,v_JOB_DATA);
	ELSE
		PUT_JOB_QUEUE_ITEM(p_JOB_THREAD_ID,p_PLSQL,p_COMMENTS,p_NOTIFICATION_EMAIL_ADDRESS);
		DEQUEUE_BY_JOB_THREAD(p_JOB_THREAD_ID);
	END IF;

END ENQUEUE_BY_JOB_THREAD;
----------------------------------------------------------------------------------------------------
-- This procedure executes a new item in the JOB_QUEUE_ITEM table based on the p_JOB_THREAD_ID param.
-- Ensures that only one item can be DEQUEUE'd at a time by using locks (MUTEX pkg).
-- Ensures that an item cannot be DEQUEUE'd if something is already running.
-- Ensures that an item cannot be DEQUEUE'd if the Job Thread is snoozed.
PROCEDURE DEQUEUE_BY_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER
	) AS
v_LOCK 						MUTEX.t_HANDLE;
v_RUNNING_JOB_ITEM_COUNT 	NUMBER;
v_IS_SNOOZED 				JOB_THREAD.IS_SNOOZED%TYPE;
BEGIN

	IF p_JOB_THREAD_ID IS NOT NULL THEN
		-- Acquire a lock so that 2 items cannot be dequeued at the same time for the same job_thread_id
		v_LOCK := MUTEX.ACQUIRE('DQ' || p_JOB_THREAD_ID);

		-- Determine if there are any Job Queue Items runnings for this Job Thread
		SELECT COUNT(1)
		INTO v_RUNNING_JOB_ITEM_COUNT
		FROM BACKGROUND_JOBS J
		WHERE J.JOB_THREAD_ID = p_JOB_THREAD_ID
			AND J.FROM_LOG = 0; -- only get current jobs - ignore old entries from the job log

		-- Determine if the Job Thread is currently Snoozed
		SELECT IS_SNOOZED
		INTO v_IS_SNOOZED
		FROM JOB_THREAD T
		WHERE T.JOB_THREAD_ID = p_JOB_THREAD_ID;

		-- If nothing is running then call DEQUEUE
		IF v_RUNNING_JOB_ITEM_COUNT = 0 AND v_IS_SNOOZED = 0 THEN
			SECURITY_CONTROLS.DEQUEUE_BY_JOB_THREAD(p_JOB_THREAD_ID);
		END IF;

		-- Release Lock
		MUTEX.RELEASE(v_LOCK);
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		MUTEX.RELEASE(v_LOCK);
		ERRS.LOG_AND_RAISE;
END DEQUEUE_BY_JOB_THREAD;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_JOB_THREAD_STATUS_SUMMARY
	(
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN

	OPEN p_CURSOR FOR
		SELECT T.JOB_THREAD_ID,
			   T.JOB_THREAD_NAME,
			   T.IS_SNOOZED,
			   COUNT(I.ITEM_ORDER) JOB_QUEUE_ITEM_COUNT
		FROM JOB_THREAD T,
			 JOB_QUEUE_ITEM I
		WHERE I.JOB_THREAD_ID(+) = T.JOB_THREAD_ID
		GROUP BY T.JOB_THREAD_ID, T.JOB_THREAD_NAME, T.IS_SNOOZED
		ORDER BY T.JOB_THREAD_NAME;

END GET_JOB_THREAD_STATUS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_JOB_THREAD_STATUS_DETAIL
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_CLIENT_CLOCK IN DATE,
	p_CURSOR OUT GA.REFCURSOR
	) AS
v_SEE_ALL_JOBS NUMBER;
BEGIN

	v_SEE_ALL_JOBS := UT.NUMBER_FROM_BOOLEAN(SD.GET_ACTION_IS_ALLOWED(SD.g_ACTION_MANAGE_ALL_JOBS));

	OPEN p_CURSOR FOR
		SELECT B.JOB_NAME,
			   EI.GET_ENTITY_NAME(EC.ED_JOB_THREAD, p_JOB_THREAD_ID) AS JOB_THREAD_NAME,
			   NULL AS JOB_QUEUE_ITEM_ID,
			   (SELECT NVL(U.USER_DISPLAY_NAME, U.USER_NAME)
			    FROM APPLICATION_USER U
				WHERE U.USER_ID = B.USER_ID) AS USER_NAME,
			   B.COMMENTS,
			   0 AS ITEM_ORDER,
			   B.STATE,
			   NULL AS QUEUED_ON,
			   GET_LOCAL_DATE_FOR_JOB(B.START_DATE, p_CLIENT_CLOCK) AS STARTED_ON,
			   B.JOB_ACTION AS PLSQL
		FROM BACKGROUND_JOBS B
		WHERE B.JOB_THREAD_ID = p_JOB_THREAD_ID
		  AND (v_SEE_ALL_JOBS = 1 OR B.USER_ID = SECURITY_CONTROLS.CURRENT_USER_ID)

		UNION ALL

	    SELECT NULL AS JOB_NAME,
			   EI.GET_ENTITY_NAME(EC.ED_JOB_THREAD, p_JOB_THREAD_ID) AS JOB_THREAD_NAME,
			   I.JOB_QUEUE_ITEM_ID,
			   NVL(U.USER_DISPLAY_NAME, U.USER_NAME) AS USER_NAME,
			   I.COMMENTS,
			   I.ITEM_ORDER,
			   'QUEUED' AS STATE,
			   I.ENTRY_DATE AS QUEUED_ON,
			   NULL AS STARTED_ON,
			   I.PLSQL
		FROM JOB_QUEUE_ITEM I,
			 APPLICATION_USER U
		WHERE I.JOB_THREAD_ID = p_JOB_THREAD_ID
		  AND (v_SEE_ALL_JOBS = 1 OR U.USER_ID = SECURITY_CONTROLS.CURRENT_USER_ID)
		  AND I.USER_ID = U.USER_ID
		ORDER BY ITEM_ORDER;

END GET_JOB_THREAD_STATUS_DETAIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_JOB_THREAD_STATUS_DETAIL
	(
	p_JOB_QUEUE_ITEM_ID IN NUMBER,
	p_ITEM_ORDER IN NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS
BEGIN

	CHECK_QUEUE_ITEM_PRIVILEGE(p_JOB_QUEUE_ITEM_ID);
	UPDATE JOB_QUEUE_ITEM I SET I.ITEM_ORDER = p_ITEM_ORDER WHERE I.JOB_QUEUE_ITEM_ID = p_JOB_QUEUE_ITEM_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		p_MESSAGE := 'Could not update the Item Order.  The Process Queue Item no longer exists. It may be running or may have already completed.';
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END PUT_JOB_THREAD_STATUS_DETAIL;
----------------------------------------------------------------------------------------------------
PROCEDURE DEL_JOB_THREAD_STATUS_DETAIL
	(
	p_JOB_QUEUE_ITEM_ID IN NUMBER,
	p_MESSAGE OUT VARCHAR
	) AS
BEGIN

	CHECK_QUEUE_ITEM_PRIVILEGE(p_JOB_QUEUE_ITEM_ID);
	DELETE FROM JOB_QUEUE_ITEM I WHERE I.JOB_QUEUE_ITEM_ID = p_JOB_QUEUE_ITEM_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		p_MESSAGE := 'Could not delete the Process Queue Item.  The Process Queue Item no longer exists.  It may be running or may have already completed.';
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;

END DEL_JOB_THREAD_STATUS_DETAIL;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_JOB_THREAD_STATUS_SUMMARY
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_IS_SNOOZED IN NUMBER
	) AS
BEGIN
	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT,p_JOB_THREAD_ID,EC.ED_JOB_THREAD);
	UPDATE JOB_THREAD T SET T.IS_SNOOZED = p_IS_SNOOZED WHERE T.JOB_THREAD_ID = p_JOB_THREAD_ID;
END PUT_JOB_THREAD_STATUS_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE PURGE_ALL_JOB_QUEUE_ITEMS
	(
	p_JOB_THREAD_ID IN NUMBER
	) AS
BEGIN
	SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_MANAGE_ALL_JOBS);
	DELETE FROM JOB_QUEUE_ITEM I WHERE I.JOB_THREAD_ID = p_JOB_THREAD_ID;
END PURGE_ALL_JOB_QUEUE_ITEMS;
----------------------------------------------------------------
-- View the parameters available in the Scheduler Program.
PROCEDURE GET_PROGRAM_PARAMETERS
	(
	p_JOB_NAME IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	CHECK_JOB_PRIVILEGE(p_JOB_NAME);

	OPEN p_CURSOR FOR
		SELECT J.JOB_NAME, P.PROGRAM_NAME, P.ARGUMENT_POSITION, P.ARGUMENT_NAME, P.ARGUMENT_TYPE, P.DEFAULT_VALUE, A.VALUE
		FROM USER_SCHEDULER_JOBS J, ALL_SCHEDULER_PROGRAM_ARGS P, USER_SCHEDULER_JOB_ARGS A
		WHERE J.JOB_NAME = p_JOB_NAME
			AND P.OWNER = J.PROGRAM_OWNER
			AND P.PROGRAM_NAME = J.PROGRAM_NAME
			AND A.JOB_NAME(+) = p_JOB_NAME
			AND A.ARGUMENT_NAME(+) = P.ARGUMENT_NAME
			AND A.ARGUMENT_POSITION(+) = P.ARGUMENT_POSITION
		ORDER BY P.ARGUMENT_POSITION;

END GET_PROGRAM_PARAMETERS;
----------------------------------------------------------------
-- Set the value of a parameter in the Scheduler Program.
PROCEDURE PUT_PROGRAM_PARAMETERS
	(
	p_JOB_NAME IN VARCHAR2,
	p_ARGUMENT_NAME IN VARCHAR2,
	p_VALUE IN VARCHAR2
	) AS
BEGIN
	CHECK_JOB_PRIVILEGE(p_JOB_NAME);
	DBMS_SCHEDULER.SET_JOB_ARGUMENT_VALUE(p_JOB_NAME, p_ARGUMENT_NAME, p_VALUE);
END PUT_PROGRAM_PARAMETERS;

--@@Begin Implementation Override --
PROCEDURE RUN_JOB_NOW(p_JOB_NAME IN VARCHAR2, p_MESSAGE OUT VARCHAR2) AS
BEGIN
   CHECK_JOB_PRIVILEGE(p_JOB_NAME);
   DBMS_SCHEDULER.RUN_JOB(p_JOB_NAME);
   p_MESSAGE := 'Job: ' || p_JOB_NAME || ' Submitted To Run';
END RUN_JOB_NOW;

PROCEDURE RUN_JOB_AT(p_FILTER_JOB_NAME IN VARCHAR2, p_FILTER_RUN_AT DATE, p_MESSAGE OUT VARCHAR2) AS
BEGIN
   CHECK_JOB_PRIVILEGE(p_FILTER_JOB_NAME);
   p_MESSAGE := 'Job: ' || p_FILTER_JOB_NAME || ' Scheduled To Run At: ' || TO_CHAR(p_FILTER_RUN_AT, 'MM/DD/YYYY HH24:MI:SS');
END RUN_JOB_AT;

PROCEDURE GET_JOB_RUN_AT_DATE_TIME(p_JOB_NAME IN VARCHAR2, p_CURSOR OUT GA.REFCURSOR) AS
BEGIN
   OPEN p_CURSOR FOR
      SELECT p_JOB_NAME "JOB_NAME", TRUNC(CURRENT_DATE) "RUN_AT_DATE", 1 "RUN_AT_HOUR", 0 "RUN_AT_MINUTE" FROM DUAL;
END GET_JOB_RUN_AT_DATE_TIME;

PROCEDURE GET_JOB_SCHEDULE(p_CURSOR OUT GA.REFCURSOR) AS
BEGIN
   OPEN p_CURSOR FOR
      SELECT SCHEDULE_NAME FROM USER_SCHEDULER_SCHEDULES ORDER BY SCHEDULE_NAME;
END GET_JOB_SCHEDULE;

PROCEDURE PUT_JOB_RUN_AT_DATE_TIME
   (
   p_JOB_NAME      IN VARCHAR2,
   p_RUN_AT_DATE   IN DATE,
   p_RUN_AT_AM_PM  IN VARCHAR2,
   p_RUN_AT_HOUR   IN NUMBER,
   p_RUN_AT_MINUTE IN NUMBER,
   p_MESSAGE      OUT VARCHAR2
   ) AS
v_PROGRAM_NAME VARCHAR2(32);
v_JOB_ACTION VARCHAR2(128);
v_HOUR NUMBER(2) := CASE WHEN p_RUN_AT_HOUR BETWEEN 1 AND 12 THEN p_RUN_AT_HOUR ELSE 0 END;
v_MINUTE NUMBER(2) := CASE WHEN p_RUN_AT_MINUTE BETWEEN 0 AND 55 THEN p_RUN_AT_MINUTE ELSE 0 END;
v_RUN_AT_DATE DATE := TO_DATE(TO_CHAR(p_RUN_AT_DATE,'MM/DD/YYYY') || ' ' || TO_CHAR(v_HOUR) || ':' || TO_CHAR(v_MINUTE) || ' ' || NVL(p_RUN_AT_AM_PM,'PM'), 'MM/DD/YYYY HH:MI AM');
v_JOB_NAME VARCHAR2(32) := DBMS_SCHEDULER.GENERATE_JOB_NAME('RUN_AT_JOB#');
v_COUNT PLS_INTEGER;
BEGIN
   CDI_POST_TO_TRACE('PUT_JOB_RUN_AT_DATE_TIME','ENTRY',TRUE);
-- Check To See If A Job Is Already Running --
   SELECT COUNT(*) INTO v_COUNT FROM USER_SCHEDULER_RUNNING_JOBS WHERE JOB_NAME = p_JOB_NAME OR JOB_NAME LIKE 'RUN_AT_JOB#%';
   IF v_COUNT = 0 THEN
-- Get The Associated Job Program To Execute --
      SELECT MAX(PROGRAM_NAME) INTO v_PROGRAM_NAME FROM USER_SCHEDULER_JOBS WHERE JOB_NAME = p_JOB_NAME;
      SELECT 'BEGIN ' || MAX(PROGRAM_ACTION) || '; END;' INTO v_JOB_ACTION FROM USER_SCHEDULER_PROGRAMS WHERE PROGRAM_NAME = v_PROGRAM_NAME;
      DBMS_SCHEDULER.CREATE_JOB(
         JOB_NAME   => v_JOB_NAME,
         JOB_TYPE   => 'PLSQL_BLOCK',
         JOB_ACTION => v_JOB_ACTION,
         START_DATE => TO_TIMESTAMP_TZ(TO_CHAR(v_RUN_AT_DATE,'YYYY-MM-DD HH24:MI') || ' US/Eastern', 'YYYY-MM-DD HH24:MI TZR'),
         END_DATE   => TO_TIMESTAMP_TZ(TO_CHAR(v_RUN_AT_DATE+1/24,'YYYY-MM-DD HH24:MI') || ' US/Eastern', 'YYYY-MM-DD HH24:MI TZR'),
         AUTO_DROP  => TRUE,
         ENABLED    => TRUE,
         COMMENTS   => 'User Initiated One Time Scheduled Execution Of ' || p_JOB_NAME);
      p_MESSAGE := 'Background Job "' || v_JOB_NAME || '" Has Been Submitted To Run At ' || TO_CHAR(v_RUN_AT_DATE, 'MM/DD/YYYY HH:MI:SS AM');
   ELSE
      p_MESSAGE := 'Another Background Job Is Currently Running. Only One Job Can Be Active At A Time.';
   END IF;
END PUT_JOB_RUN_AT_DATE_TIME;

--@@End Implementation Override --

END JOBS;
/
