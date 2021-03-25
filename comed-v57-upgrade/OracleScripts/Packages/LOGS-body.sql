CREATE OR REPLACE PACKAGE BODY LOGS IS
----------------------------------------------------------------------------------------------------
-- Constants
c_DEFAULT_PROGRAM CONSTANT VARCHAR(16) := 'Client';
c_PROCESS_CLEANUP_MESSAGE CONSTANT VARCHAR(256) := 'This process was terminated by the system during session cleanup.';

-- Columns widths used when inserting or updating PROCESS_LOG
c_WIDTH_PROCESS_NAME         CONSTANT NUMBER(4) := 256;
c_WIDTH_PROCESS_TYPE         CONSTANT NUMBER(4) := 16;
c_WIDTH_PROCESS_ERRM         CONSTANT NUMBER(4) := 4000;
c_WIDTH_PROCESS_FINISH_TEXT  CONSTANT NUMBER(4) := 4000;
c_WIDTH_PROGRESS_UNITS       CONSTANT NUMBER(4) := 32;
c_WIDTH_PROGRESS_DESCRIPTION CONSTANT NUMBER(4) := 64;
c_WIDTH_SCHEMA_NAME          CONSTANT NUMBER(4) := 30;
c_WIDTH_SESSION_PROGRAM      CONSTANT NUMBER(4) := 64;
c_WIDTH_SESSION_MACHINE      CONSTANT NUMBER(4) := 64;
c_WIDTH_SESSION_OSUSER       CONSTANT NUMBER(4) := 64;
c_WIDTH_SESSION_SID          CONSTANT NUMBER(4) := 32;
c_WIDTH_SESSION_SERIALNUM    CONSTANT NUMBER(4) := 32;
c_WIDTH_UNIQUE_SESSION_CID   CONSTANT NUMBER(4) := 24;
c_WIDTH_JOB_NAME             CONSTANT NUMBER(4) := 30;

-- Columns widths used when inserting or updating PROCESS_LOG_EVENT
c_WIDTH_PROCEDURE_NAME CONSTANT NUMBER(4) := 64;
c_WIDTH_STEP_NAME      CONSTANT NUMBER(4) := 64;
c_WIDTH_SOURCE_NAME    CONSTANT NUMBER(4) := 512;
c_WIDTH_EVENT_ERRM     CONSTANT NUMBER(4) := 4000;
c_WIDTH_EVENT_TEXT     CONSTANT NUMBER(4) := 4000;

-- Columns widths used when inserting or updating PROCESS_LOG_EVENT_DETAIL
c_WIDTH_DETAIL_TYPE  CONSTANT NUMBER(4) := 64;
c_WIDTH_CONTENT_TYPE CONSTANT NUMBER(4) := 128;

-- Columns widths used when inserting or updating PROCESS_LOG_TARGET_PARAMETER
c_WIDTH_TARGET_PARAMETER_NAME  CONSTANT NUMBER(4) := 32;
c_WIDTH_TARGET_PARAMETER_VALUE CONSTANT NUMBER(4) := 4000;

-- Constant use to indicate an infinite Event Retention Policy when actual setting value is -1 or 0.
c_MAX_EVENT_RETENTION CONSTANT NUMBER(9) := 999999999;

-- Change this value to TRUE to turn on tracing of internal LOGS package structures
c_INTERNAL_TRACING CONSTANT BOOLEAN := FALSE;
----------------------------------------------------------------------------------------------------
-- Types

TYPE t_PROCESS_ENTRY IS RECORD
	(
	PROCESS_ID        NUMBER,
	PROCESS_STATUS	  PLS_INTEGER,
	LOG_LEVEL         PLS_INTEGER,
	WAS_TERMINATED    NUMBER,
	PERSIST_TRACE     BOOLEAN,
	KEEP_EVENT_DETAIL BOOLEAN
	);
TYPE t_PROCESS_STACK IS TABLE OF t_PROCESS_ENTRY;

TYPE t_PROGRESS_ENTRY IS RECORD
	(
	MAX_VALUE NUMBER,
	CUR_VALUE NUMBER
	);
TYPE t_PROGRESS_STACK IS TABLE OF t_PROGRESS_ENTRY INDEX BY PLS_INTEGER;
TYPE t_PROGRESS_STACK_MAP IS TABLE OF t_PROGRESS_STACK INDEX BY VARCHAR2(16);

----------------------------------------------------------------------------------------------------
-- Globals

g_PROCESSES			t_PROCESS_STACK := t_PROCESS_STACK();
g_LAST_EVENT_ID		PROCESS_LOG_EVENT.EVENT_ID%TYPE;
g_PROGRESS_STACKS	t_PROGRESS_STACK_MAP;

g_START_FAIL_SQLCODE NUMBER;
g_START_FAIL_SQLERRM VARCHAR2(32767);

-- Indicates whether TRACE_INTERNAL_STRUCTURES is currently
-- executing or not.
g_TRACING			 BOOLEAN := FALSE;

-- Indicates state of progress tracker
g_PROGRESS_TRACKER_ENABLED		BOOLEAN := FALSE;
g_PROGRESS_TRACKER_POLL_FREQ	NUMBER := 0.01;
g_PROGRESS_TRACKER_WAIT			NUMBER := 10;
g_PROGRESS_TRACKER_COMPRESS		BOOLEAN := TRUE;

g_LAST_PROCESS_ID       PROCESS_LOG.PROCESS_ID%TYPE := NULL;
g_LAST_PROCESS_USER_ID  PROCESS_LOG.USER_ID%TYPE := NULL;
g_LAST_PROCESS_DATE     DATE := CONSTANTS.LOW_DATE;

----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
	RETURN '$Revision: 1.15 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE TRACE_INTERNAL_STRUCTURES(p_WHAT IN VARCHAR2) AS
v_PROCID	VARCHAR2(16);
BEGIN
	IF NOT c_INTERNAL_TRACING THEN
		RETURN;
	END IF;
	IF g_TRACING THEN
		RETURN; -- don't want infinite recursion since this calls
				-- LOG_DEBUG_MORE_DETAIL - which in turn calls
				-- PUT_LOG_EVENT which in turn calls this procedure
	END IF;

	g_TRACING := TRUE;

	IF IS_DEBUG_MORE_DETAIL_ENABLED THEN
		IF p_WHAT IS NOT NULL THEN
			LOG_DEBUG_MORE_DETAIL('------------------------------------------------------------------------------');
			LOG_DEBUG_MORE_DETAIL(p_WHAT);
		END IF;
		LOG_DEBUG_MORE_DETAIL('------------------------ LOGS Internal Structures ----------------------------');
		LOG_DEBUG_MORE_DETAIL('g_LAST_EVENT_ID = '||g_LAST_EVENT_ID);
		LOG_DEBUG_MORE_DETAIL('g_PROCESSES = ');
		FOR i IN g_PROCESSES.FIRST..g_PROCESSES.LAST LOOP
			LOG_DEBUG_MORE_DETAIL('    @'||TO_CHAR(i)||' = { PROCESS_ID: '||g_PROCESSES(i).PROCESS_ID
								||', PROCESS_STATUS: '||g_PROCESSES(i).PROCESS_STATUS
								||', LOG_LEVEL: '||g_PROCESSES(i).LOG_LEVEL
								||', WAS_TERMINATED: '||g_PROCESSES(i).WAS_TERMINATED
								||', PERSIST_TRACE: '||CASE WHEN g_PROCESSES(i).PERSIST_TRACE THEN 'true' ELSE 'false' END
								||', KEEP_EVENT_DETAIL: '||CASE WHEN g_PROCESSES(i).KEEP_EVENT_DETAIL THEN 'true' ELSE 'false' END
								||' }');
		END LOOP;
		LOG_DEBUG_MORE_DETAIL('g_PROGRESS_STACKS = ');
		v_PROCID := g_PROGRESS_STACKS.FIRST;
		WHILE g_PROGRESS_STACKS.EXISTS(v_PROCID) LOOP
			LOG_DEBUG_MORE_DETAIL('    @'||v_PROCID||' = ');
			FOR i IN g_PROGRESS_STACKS(v_PROCID).FIRST..g_PROGRESS_STACKS(v_PROCID).LAST LOOP
				LOG_DEBUG_MORE_DETAIL('        @'||i||' = { MAX_VALUE: '||g_PROGRESS_STACKS(v_PROCID)(i).MAX_VALUE
									||', CUR_VALUE: '||g_PROGRESS_STACKS(v_PROCID)(i).CUR_VALUE
									||' }');
			END LOOP;
			v_PROCID := g_PROGRESS_STACKS.NEXT(v_PROCID);
		END LOOP;
		LOG_DEBUG_MORE_DETAIL('------------------------------------------------------------------------------');
	END IF;

	g_TRACING := FALSE;

EXCEPTION
	WHEN OTHERS THEN
		g_TRACING := FALSE;
		RAISE;
END TRACE_INTERNAL_STRUCTURES;
----------------------------------------------------------------------------------------------------
PROCEDURE PUSH_PROCESS
	(
	p_PROCESS_ID        IN NUMBER,
	p_LOG_LEVEL         IN PLS_INTEGER,
	p_PERSIST_TRACE     IN BOOLEAN,
	p_KEEP_EVENT_DETAIL IN BOOLEAN,
	p_WAS_TERMINATED    IN NUMBER := 0
	) IS
	v_INDEX PLS_INTEGER;
BEGIN
	g_PROCESSES.EXTEND;
	v_INDEX := g_PROCESSES.LAST;
	g_PROCESSES(v_INDEX).PROCESS_ID := p_PROCESS_ID;
	g_PROCESSES(v_INDEX).PROCESS_STATUS := c_LEVEL_SUCCESS;
	g_PROCESSES(v_INDEX).LOG_LEVEL := p_LOG_LEVEL;
	g_PROCESSES(v_INDEX).WAS_TERMINATED := p_WAS_TERMINATED;
	g_PROCESSES(v_INDEX).KEEP_EVENT_DETAIL := p_KEEP_EVENT_DETAIL;
	g_PROCESSES(v_INDEX).PERSIST_TRACE := p_PERSIST_TRACE;
	TRACE_INTERNAL_STRUCTURES('PUSH_PROCESS');
END PUSH_PROCESS;
----------------------------------------------------------------------------------------------------
PROCEDURE POP_PROCESS IS
BEGIN
	g_PROCESSES.DELETE(g_PROCESSES.LAST);
	TRACE_INTERNAL_STRUCTURES('POP_PROCESS');
END POP_PROCESS;
----------------------------------------------------------------------------------------------------
-- This helper procedure validates the progress stack to make sure there is a range on the stack
-- that can manage the progress tracking.
PROCEDURE VALIDATE_PROGRESS_STACK
	(
	p_RANGE IN NUMBER := NULL,
	p_RANGE_MUST_EXIST IN BOOLEAN := TRUE
	) IS
	v_PROGRESS_STACK t_PROGRESS_STACK;
BEGIN
	ASSERT(g_PROGRESS_STACKS.EXISTS(CURRENT_PROCESS_ID()),'There is no progress record for the current Process_Id (' || CURRENT_PROCESS_ID() || ')');

	v_PROGRESS_STACK := g_PROGRESS_STACKS(CURRENT_PROCESS_ID());

	ASSERT(v_PROGRESS_STACK.COUNT() > 0,'The progress record is empty for the current Process_Id (' || CURRENT_PROCESS_ID() || ')');

	-- If a range is specified and it does not exist then throw an Exception
	IF p_RANGE_MUST_EXIST AND p_RANGE IS NOT NULL AND p_RANGE >= 0 THEN
		ASSERT(v_PROGRESS_STACK.EXISTS(p_RANGE),'The progress range for specified index (' || p_Range || ') does not exist for the current Process_Id (' || CURRENT_PROCESS_ID() || ')');
	END IF;
END VALIDATE_PROGRESS_STACK;
----------------------------------------------------------------------------------------------------
-- pushes a single range onto the stack
FUNCTION PUSH_PROGRESS_RANGE(p_MAX_VALUE IN NUMBER) RETURN PLS_INTEGER IS
	v_INDEX              PLS_INTEGER;
	v_NEW_PROGRESS_ENTRY t_PROGRESS_ENTRY;
	v_PROGRESS_STACK     t_PROGRESS_STACK;
BEGIN
	IF g_PROGRESS_STACKS.EXISTS(CURRENT_PROCESS_ID()) THEN
		v_PROGRESS_STACK := g_PROGRESS_STACKS(CURRENT_PROCESS_ID());
	END IF;

	v_INDEX := NVL(v_PROGRESS_STACK.LAST(), 0) + 1;
	v_NEW_PROGRESS_ENTRY.MAX_VALUE := p_MAX_VALUE;
	v_NEW_PROGRESS_ENTRY.CUR_VALUE := 0;
	v_PROGRESS_STACK(v_INDEX) := v_NEW_PROGRESS_ENTRY;
	g_PROGRESS_STACKS(CURRENT_PROCESS_ID()) := v_PROGRESS_STACK;
	TRACE_INTERNAL_STRUCTURES('PUSH_PROGRESS_RANGE');
	RETURN v_INDEX;
END PUSH_PROGRESS_RANGE;
----------------------------------------------------------------------------------------------------
-- clears the stack (in case there are remnants of progress info from a
-- previous process).
PROCEDURE CLEAR_PROGRESS IS
BEGIN
	g_PROGRESS_STACKS.DELETE(CURRENT_PROCESS_ID);
	TRACE_INTERNAL_STRUCTURES('CLEAR_PROGRESS');
END CLEAR_PROGRESS;
----------------------------------------------------------------------------------------------------
-- the range at the top of the stack is popped. this effectively marks the
-- current range as complete. an exception will be raised if there is no range
-- to pop. if a range index is specified, that index – and all other ranges
-- above it in the stack – will be popped. otherwise, the top element in the
-- stack is popped.
PROCEDURE POP_PROGRESS_RANGE
	(
	p_RANGE IN PLS_INTEGER := -1,
	p_RANGE_MUST_EXIST IN BOOLEAN
	) IS
	v_TOP_INDEX    PLS_INTEGER;
	v_BOTTOM_INDEX PLS_INTEGER;
BEGIN
	VALIDATE_PROGRESS_STACK(p_RANGE, p_RANGE_MUST_EXIST);
	v_TOP_INDEX := g_PROGRESS_STACKS(CURRENT_PROCESS_ID()).LAST();
	IF p_RANGE >= 0 THEN
		v_BOTTOM_INDEX := p_RANGE;
	ELSE
		v_BOTTOM_INDEX := v_TOP_INDEX;
	END IF;

	IF v_TOP_INDEX >= v_BOTTOM_INDEX THEN
		-- if bottom > top then that means the specified range did not
		-- exist - no exception was thrown by VALIDATE_PROGRESS_STACK because
		-- p_RANGE_MUST_EXIST apparently must be true
		g_PROGRESS_STACKS(CURRENT_PROCESS_ID()).DELETE(v_BOTTOM_INDEX, v_TOP_INDEX);
		TRACE_INTERNAL_STRUCTURES('POP_PROGRESS_RANGE');
	END IF;
END POP_PROGRESS_RANGE;
----------------------------------------------------------------------------------------------------
-- Public version of POP_PROGRESS_RANGE. If the specified range does
-- not exist then an exception is raised.
PROCEDURE POP_PROGRESS_RANGE(p_RANGE IN PLS_INTEGER := -1) IS
BEGIN
	-- call internal version. This public API version will throw an
	-- exception if the specified range index is not valid
	POP_PROGRESS_RANGE(p_RANGE, TRUE);
END POP_PROGRESS_RANGE;
----------------------------------------------------------------------------------------------------
-- Returns a new Process_Id that uses the Process_Id Sequence and appends that to numeric
-- representation of todays date
FUNCTION CREATE_PROCESS_ID RETURN NUMBER IS
	v_PROCESS_ID        PROCESS_LOG.PROCESS_ID%TYPE;
	v_PROCESS_ID_SUFFIX NUMBER(5);
BEGIN

	SELECT PROCESS_ID.NEXTVAL INTO v_PROCESS_ID_SUFFIX FROM DUAL;

	v_PROCESS_ID := (TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYDDD')) * 100000) + v_PROCESS_ID_SUFFIX;

	RETURN v_PROCESS_ID;
END CREATE_PROCESS_ID;
----------------------------------------------------------------------------------------------------
-- Returns a new Process Name that uses the format: User YYYY-MM-DD (Program @ Machine)
FUNCTION CREATE_PROCESS_NAME
	(
	p_PROCESS_TYPE IN VARCHAR2,
	p_PROGRAM      IN VARCHAR2,
	p_MACHINE      IN VARCHAR2
	) RETURN VARCHAR IS
v_PROCESS_NAME VARCHAR2(32767);
v_PROGRAM_NAME V$SESSION.PROGRAM%TYPE;
BEGIN
	v_PROGRAM_NAME := NVL(p_PROGRAM,c_DEFAULT_PROGRAM);

	-- Short Process Name
	IF p_PROCESS_TYPE = c_PROCESS_TYPE_BACKGROUND_JOB THEN
		v_PROCESS_NAME := 'Background Jobs';
	ELSIF p_PROCESS_TYPE = c_PROCESS_TYPE_USER_SESSION THEN
		IF SECURITY_CONTROLS.CURRENT_USER_ID IS NULL THEN
			v_PROCESS_NAME := 'Unauthenticated Sessions from '||v_PROGRAM_NAME || '@' || p_MACHINE;
		ELSE
			v_PROCESS_NAME := 'User Sessions from '||v_PROGRAM_NAME || '@' || p_MACHINE;
		END IF;
	ELSE
		v_PROCESS_NAME := p_PROCESS_TYPE||' ('||v_PROGRAM_NAME || '@' || p_MACHINE||')';
	END IF;
	RETURN SUBSTR(v_PROCESS_NAME, 1, c_WIDTH_PROCESS_NAME);
END CREATE_PROCESS_NAME;
----------------------------------------------------------------------------------------------------
PROCEDURE CREATE_PROCESS
	(
	p_PROCESS_ID         OUT NUMBER,
	p_PROCESS_NAME       IN VARCHAR2,
	p_PROCESS_TYPE       IN VARCHAR2,
	p_PARENT_PROCESS_ID  IN NUMBER,
	p_TARGET_BEGIN_DATE  IN DATE := NULL,
	p_TARGET_END_DATE    IN DATE := NULL,
	p_TARGET_PARAMETERS  IN UT.STRING_MAP := UT.c_EMPTY_MAP,
	p_TOTAL_WORK         IN NUMBER := 100, -- default to 100, as in percent
	p_PROCESS_START_DATE IN DATE := SYSDATE,
	p_PROCESS_STOP_DATE  IN DATE := NULL
	) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_PROCESS_ID        PROCESS_LOG.PROCESS_ID%TYPE;
	v_PROCESS_NAME      VARCHAR2(32767);
	v_TARGET_PARAM_NAME VARCHAR(32);
	v_TARGET_PARAM_VAL  VARCHAR(4000);

	--Session values
	v_USERNAME           V$SESSION.USERNAME%TYPE;
	v_PROGRAM            V$SESSION.PROGRAM%TYPE;
	v_MACHINE            V$SESSION.MACHINE%TYPE;
	v_OSUSER             V$SESSION.OSUSER%TYPE;
	v_SERIALNUM          V$SESSION.SERIAL#%TYPE;
	v_UNIQUE_SESSION_CID VARCHAR(24);

	-- The Job Name is the name of the scheduler job that started this process.
	v_JOB_NAME           PROCESS_LOG.JOB_NAME%TYPE;

	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');
BEGIN
	-- Create a new Process Id
	v_PROCESS_ID := CREATE_PROCESS_ID();

	-- Setup Session Variables
	-- Be careful to make sure we don't get more than one record (use the max() grouping function)
	-- By using max, we will guaranteed 1 row but values still may be null if there is no matching
	-- data in the V$SESSION view. - pbm
	SELECT MAX(SUBSTR(USERNAME, 1, c_WIDTH_SCHEMA_NAME)),
		   MAX(SUBSTR(PROGRAM, 1, c_WIDTH_SESSION_PROGRAM)),
		   MAX(SUBSTR(MACHINE, 1, c_WIDTH_SESSION_MACHINE)),
		   MAX(SUBSTR(OSUSER, 1, c_WIDTH_SESSION_OSUSER)),
		   MAX(SUBSTR(SERIAL#, 1, c_WIDTH_SESSION_SERIALNUM)),
		   MAX(CASE WHEN MODULE = 'DBMS_SCHEDULER' AND p_PROCESS_TYPE = c_PROCESS_TYPE_PROCESS THEN SUBSTR(ACTION, 1, c_WIDTH_JOB_NAME) ELSE NULL END)
	INTO v_USERNAME, v_PROGRAM, v_MACHINE, v_OSUSER, v_SERIALNUM, v_JOB_NAME
	FROM V$SESSION
	WHERE SID = v_SID
	  AND AUDSID = v_AUDSID;

	-- Create a default Process Name if necessary
	IF p_PROCESS_NAME IS NULL THEN
		v_PROCESS_NAME := CREATE_PROCESS_NAME(p_PROCESS_TYPE, v_PROGRAM, v_MACHINE);
	ELSE
		v_PROCESS_NAME := p_PROCESS_NAME;
	END IF;

	v_UNIQUE_SESSION_CID := SUBSTR(DBMS_SESSION.UNIQUE_SESSION_ID(), 1, c_WIDTH_UNIQUE_SESSION_CID);

    LOGS_IMPL.PUT_PROCESS_LOG(v_PROCESS_ID,
		 SUBSTR(v_PROCESS_NAME, 1, c_WIDTH_PROCESS_NAME),
		 SUBSTR(p_PROCESS_TYPE, 1, c_WIDTH_PROCESS_TYPE),
		 SECURITY_CONTROLS.CURRENT_USER_ID(),
		 p_PARENT_PROCESS_ID,
		 p_PROCESS_START_DATE,
		 p_PROCESS_STOP_DATE,
		 p_TOTAL_WORK,
		 'Steps', -- PROGRESS_UNITS
		 0, -- CAN_TERMINATE
		 0, -- WAS_TERMINATED
		 p_PROCESS_STOP_DATE, -- Default the Next Event Cleanup to the Stop_Date when it is not null
		 v_USERNAME,
		 v_PROGRAM,
		 v_MACHINE,
		 v_OSUSER,
		 v_SID,
		 v_SERIALNUM,
		 v_UNIQUE_SESSION_CID,
		 v_JOB_NAME);

	-- Setup Target Begin Date Parameter
	IF NOT p_TARGET_BEGIN_DATE IS NULL THEN
		LOGS_IMPL.PUT_PROCESS_TARGET_PARAMETER(v_PROCESS_ID, c_TARGET_PARAM_BEGIN_DATE, TEXT_UTIL.TO_CHAR_DATE(p_TARGET_BEGIN_DATE));
	END IF;

	-- Setup Target End Date Parameter
	IF NOT p_TARGET_END_DATE IS NULL THEN
		LOGS_IMPL.PUT_PROCESS_TARGET_PARAMETER(v_PROCESS_ID, c_TARGET_PARAM_END_DATE, TEXT_UTIL.TO_CHAR_DATE(p_TARGET_END_DATE));
	END IF;

	-- Setup Other Target Parameters
	IF p_TARGET_PARAMETERS.COUNT() > 0 THEN
		v_TARGET_PARAM_NAME := SUBSTR(p_TARGET_PARAMETERS.FIRST(), 1, c_WIDTH_TARGET_PARAMETER_NAME);
		WHILE p_TARGET_PARAMETERS.EXISTS(v_TARGET_PARAM_NAME) LOOP

			v_TARGET_PARAM_VAL := SUBSTR(p_TARGET_PARAMETERS(v_TARGET_PARAM_NAME),
										 1,
										 c_WIDTH_TARGET_PARAMETER_VALUE);

			LOGS_IMPL.PUT_PROCESS_TARGET_PARAMETER(v_PROCESS_ID, v_TARGET_PARAM_NAME, v_TARGET_PARAM_VAL);

			v_TARGET_PARAM_NAME := SUBSTR(p_TARGET_PARAMETERS.NEXT(v_TARGET_PARAM_NAME),
										  1,
										  c_WIDTH_TARGET_PARAMETER_NAME);
		END LOOP;
	END IF;

	p_PROCESS_ID := v_PROCESS_ID;

	COMMIT;
END CREATE_PROCESS;
----------------------------------------------------------------------------------------------------
-- Updates the current process values in the SYSTEM_SESSION table
PROCEDURE UPDATE_CURRENT_SESSION_VALUES
	(
	p_LOG_LEVEL          IN PLS_INTEGER,
	p_PERSIST_TRACE      IN BOOLEAN,
	p_KEEP_EVENT_DETAIL  IN BOOLEAN
	) IS
	v_PERSIST_TRACE_NUM     PLS_INTEGER;
	v_KEEP_EVENT_DETAIL_NUM PLS_INTEGER;
	v_PROCESS_ID            PROCESS_LOG.PROCESS_ID%TYPE;
	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');
BEGIN
	v_PERSIST_TRACE_NUM := UT.NUMBER_FROM_BOOLEAN(p_KEEP_EVENT_DETAIL);
	v_KEEP_EVENT_DETAIL_NUM := UT.NUMBER_FROM_BOOLEAN(p_PERSIST_TRACE);
	v_PROCESS_ID := g_PROCESSES(g_PROCESSES.LAST).PROCESS_ID;

	UPDATE SYSTEM_SESSION S
	SET S.CURRENT_PROCESS_ID = v_PROCESS_ID,
		S.LOG_LEVEL          = p_LOG_LEVEL,
		S.KEEP_EVENT_DETAIL  = v_PERSIST_TRACE_NUM,
		S.PERSIST_TRACE      = v_KEEP_EVENT_DETAIL_NUM
	WHERE S.SESSION_SID = v_SID
		AND S.SESSION_AUDSID = v_AUDSID;

END UPDATE_CURRENT_SESSION_VALUES;
----------------------------------------------------------------------------------------------------
-- Sets the current process in both the global stack and the Session table
PROCEDURE SET_CURRENT_PROCESS
	(
	p_PROCESS_ID        IN NUMBER,
	p_LOG_LEVEL         IN PLS_INTEGER,
	p_PERSIST_TRACE     IN BOOLEAN,
	p_KEEP_EVENT_DETAIL IN BOOLEAN
	) IS
	v_LOG_LEVEL         PLS_INTEGER;
	v_PERSIST_TRACE     BOOLEAN;
	v_KEEP_EVENT_DETAIL BOOLEAN;
BEGIN
	-- If the logging values are null, then load based on their current values
	v_LOG_LEVEL := NVL(p_LOG_LEVEL, CURRENT_LOG_LEVEL());
	v_PERSIST_TRACE := NVL(p_PERSIST_TRACE, PERSISTING_TRACE());
	v_KEEP_EVENT_DETAIL := NVL(p_KEEP_EVENT_DETAIL, KEEPING_EVENT_DETAILS());

	PUSH_PROCESS(p_PROCESS_ID, v_LOG_LEVEL, v_PERSIST_TRACE, v_KEEP_EVENT_DETAIL);

	UPDATE_CURRENT_SESSION_VALUES(v_LOG_LEVEL, v_PERSIST_TRACE, v_KEEP_EVENT_DETAIL);

END SET_CURRENT_PROCESS;
----------------------------------------------------------------------------------------------------
PROCEDURE START_PROGRESS_TRACKER AS
v_PLSQL	VARCHAR2(4000);
DUMMY	VARCHAR2(64);
BEGIN
	v_PLSQL := 'BEGIN
					LOGS.PROGRESS_TRACKER('||CURRENT_PROCESS_ID||', '||g_PROGRESS_TRACKER_POLL_FREQ||',
										'||CASE WHEN g_PROGRESS_TRACKER_COMPRESS THEN 'TRUE' ELSE 'FALSE' END||');
				END;';
	DUMMY := START_BACKGROUND_JOB(v_PLSQL, p_WAIT_FOR_JOB_TO_START => g_PROGRESS_TRACKER_WAIT);
END START_PROGRESS_TRACKER;
----------------------------------------------------------------------------------------------------
-- Create a new process. if p_Event_Level is null then the current log
-- level will be left unchanged. Otherwise, it will be changed, and then reverted when
-- this process is stopped. Same goes for p_Keep_Event_Details and p_Persist_Trace flags.
PROCEDURE START_PROCESS
	(
	p_PROCESS_NAME       IN VARCHAR2,
	p_TARGET_BEGIN_DATE  IN DATE := NULL,
	p_TARGET_END_DATE    IN DATE := NULL,
	p_TARGET_PARAMETERS  IN UT.STRING_MAP := UT.c_EMPTY_MAP,
	p_EVENT_LEVEL        IN NUMBER := NULL,
	p_KEEP_EVENT_DETAILS IN BOOLEAN := NULL,
	p_PERSIST_TRACE      IN BOOLEAN := NULL,
	p_TRACE_ON			 IN NUMBER := NULL
	) IS
	v_PARENT_PROCESS_ID PROCESS_LOG.PROCESS_ID%TYPE;
	v_PROCESS_ID        PROCESS_LOG.PROCESS_ID%TYPE;
	v_EVENT_LEVEL       NUMBER(9);
BEGIN
	BEGIN
		ASSERT(SECURITY_CONTROLS.CURRENT_USER_ID IS NOT NULL,
				'Process cannot be started from unauthorized session (current user ID = NULL)');
		-- Get Parent Process Id
		v_PARENT_PROCESS_ID := CURRENT_PROCESS_ID();

		-- Create Process
		CREATE_PROCESS(v_PROCESS_ID,
					   p_PROCESS_NAME,
					   c_PROCESS_TYPE_PROCESS,
					   v_PARENT_PROCESS_ID,
					   p_TARGET_BEGIN_DATE,
					   p_TARGET_END_DATE,
					   p_TARGET_PARAMETERS);
	EXCEPTION
		WHEN OTHERS THEN
			g_START_FAIL_SQLCODE := SQLCODE;
			g_START_FAIL_SQLERRM := SQLERRM;
			ERRS.RAISE(MSGCODES.c_ERR_COULD_NOT_START_PROCESS, p_PROCESS_NAME, TRUE);
	END;

	IF p_EVENT_LEVEL IS NULL THEN
		v_EVENT_LEVEL := LEAST(CURRENT_LOG_LEVEL,
						   CASE p_TRACE_ON
							   WHEN 1 THEN
								LOGS.c_LEVEL_DEBUG
							   WHEN 2 THEN
								LOGS.c_LEVEL_ALL
							   ELSE
								LOGS.c_LEVEL_FATAL
						   END);
	END IF;

	-- Update Process Stack and Session Table Values
	SET_CURRENT_PROCESS(v_PROCESS_ID, v_EVENT_LEVEL, p_PERSIST_TRACE, p_KEEP_EVENT_DETAILS);

	-- Run progress tracker if it is enabled
	IF g_PROGRESS_TRACKER_ENABLED THEN
		START_PROGRESS_TRACKER;
	END IF;
END START_PROCESS;
----------------------------------------------------------------------------------------------------
-- Target parameter information can be added using this method instead of providing
-- information via a map to the above procedure
PROCEDURE SET_PROCESS_TARGET_PARAMETER
	(
	p_TARGET_PARAMETER_NAME IN VARCHAR2,
	p_TARGET_PARAMETER_VAL  IN VARCHAR2
	) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_PROCESS_ID PROCESS_LOG.PROCESS_ID%TYPE;
BEGIN
	v_PROCESS_ID := CURRENT_PROCESS_ID();

	LOGS_IMPL.PUT_PROCESS_TARGET_PARAMETER(
						v_PROCESS_ID,
						SUBSTR(p_TARGET_PARAMETER_NAME, 1, c_WIDTH_TARGET_PARAMETER_NAME),
						SUBSTR(p_TARGET_PARAMETER_VAL, 1, c_WIDTH_TARGET_PARAMETER_VALUE)
						);

	COMMIT;
END SET_PROCESS_TARGET_PARAMETER;
----------------------------------------------------------------------------------------------------
FUNCTION GET_CURRENT_SESSION_PROCESS_ID RETURN NUMBER IS
	v_CURRENT_SESSION_PROCESS_ID	PROCESS_LOG.PROCESS_ID%TYPE;
	v_PROCESS_TYPE					PROCESS_LOG.PROCESS_TYPE%TYPE;
	v_USER_ID						PROCESS_LOG.USER_ID%TYPE := SECURITY_CONTROLS.CURRENT_USER_ID;
	v_PARENT_SID                    SYSTEM_SESSION.SESSION_SID%TYPE;
	v_PROCESS_NAME                  PROCESS_LOG.PROCESS_NAME%TYPE;
	v_PARENT_PROCESS_ID             PROCESS_LOG.PARENT_PROCESS_ID%TYPE;

	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');
BEGIN
    IF v_USER_ID = g_LAST_PROCESS_USER_ID AND TRUNC(SYSDATE) = g_LAST_PROCESS_DATE THEN
        v_CURRENT_SESSION_PROCESS_ID := g_LAST_PROCESS_ID;
    ELSE
	-- Check to see if this Session is a parallel child session.
	v_PARENT_SID := GET_PARALLEL_PARENT_SID;
	IF v_PARENT_SID IS NOT NULL THEN
		v_PROCESS_TYPE := c_PROCESS_TYPE_CHILD;
		-- Child Sessions don't have the concept of a "User Session" so first check to see if there is anything on the stack.
		IF g_PROCESSES.COUNT > 0 THEN
			v_CURRENT_SESSION_PROCESS_ID := g_PROCESSES(g_PROCESSES.LAST).PROCESS_ID;
		ELSE
			-- If not, we have to create a new process based on the parent session's process.
			SELECT 'Parallel Session: '|| P.PROCESS_NAME, P.PROCESS_ID
			INTO v_PROCESS_NAME, v_PARENT_PROCESS_ID
			FROM SYSTEM_SESSION S, PROCESS_LOG P
			WHERE S.SESSION_SID = v_PARENT_SID
				AND S.SESSION_AUDSID = v_SID
				AND P.PROCESS_ID = S.CURRENT_PROCESS_ID;

			CREATE_PROCESS(v_CURRENT_SESSION_PROCESS_ID, v_PROCESS_NAME, c_PROCESS_TYPE_CHILD, v_PARENT_PROCESS_ID);
		END IF;
	-- Check to see if this Session is a Background Job or User Session
	ELSIF NOT SYS_CONTEXT('USERENV', 'BG_JOB_ID') IS NULL THEN
		v_PROCESS_TYPE := c_PROCESS_TYPE_BACKGROUND_JOB;
		-- Background Job
		IF v_USER_ID IS NULL THEN
			SELECT MAX(PROCESS_ID)
			INTO v_CURRENT_SESSION_PROCESS_ID
			FROM PROCESS_LOG P
			WHERE P.PROCESS_TYPE = v_PROCESS_TYPE
				  AND P.USER_ID IS NULL
				  AND TRUNC(P.PROCESS_START_TIME) = TRUNC(SYSDATE);
		ELSE
			SELECT MAX(PROCESS_ID)
			INTO v_CURRENT_SESSION_PROCESS_ID
			FROM PROCESS_LOG P
			WHERE P.PROCESS_TYPE = v_PROCESS_TYPE
				  AND P.USER_ID = v_USER_ID
				  AND TRUNC(P.PROCESS_START_TIME) = TRUNC(SYSDATE);
		END IF;
	ELSE
		v_PROCESS_TYPE := c_PROCESS_TYPE_USER_SESSION;
		-- User Session
		IF v_USER_ID IS NULL THEN
			SELECT MAX(PROCESS_ID)
			INTO v_CURRENT_SESSION_PROCESS_ID
			FROM PROCESS_LOG P, V$SESSION S
			WHERE P.SESSION_MACHINE = S.MACHINE
				  AND (P.SESSION_PROGRAM = S.PROGRAM OR (P.SESSION_PROGRAM IS NULL AND S.PROGRAM IS NULL))
				  AND P.USER_ID IS NULL
				  AND TRUNC(P.PROCESS_START_TIME) = TRUNC(SYSDATE)
				  AND P.PROCESS_TYPE = v_PROCESS_TYPE
				  AND S.SID = v_SID
				  AND S.AUDSID = v_AUDSID;
		ELSE
			SELECT MAX(PROCESS_ID)
			INTO v_CURRENT_SESSION_PROCESS_ID
			FROM PROCESS_LOG P, V$SESSION S
			WHERE P.SESSION_MACHINE = S.MACHINE
				  AND (P.SESSION_PROGRAM = S.PROGRAM OR (P.SESSION_PROGRAM IS NULL AND S.PROGRAM IS NULL))
				  AND P.USER_ID = v_USER_ID
				  AND TRUNC(P.PROCESS_START_TIME) = TRUNC(SYSDATE)
				  AND P.PROCESS_TYPE = v_PROCESS_TYPE
				  AND S.SID = v_SID
				  AND S.AUDSID = v_AUDSID;
		END IF;

	END IF;

	IF v_CURRENT_SESSION_PROCESS_ID IS NULL THEN
		CREATE_PROCESS(v_CURRENT_SESSION_PROCESS_ID,
					   NULL, -- Process_Name (let Create_Process auto create this name)
					   v_PROCESS_TYPE,
					   NULL, -- Parent_Process = null
					   NULL, -- Target_Begin_Date = null
					   NULL, -- Target_End_Date = null
					   UT.c_EMPTY_MAP, -- Target_Others = empty map  (otherwise will not compile)
					   0, -- Total_Work
					   TRUNC(SYSDATE), -- Start_Date
					   TRUNC(SYSDATE + 1) - 1 / 86400);
	END IF;
        g_LAST_PROCESS_ID := v_CURRENT_SESSION_PROCESS_ID;
    END IF;

    g_LAST_PROCESS_USER_ID := v_USER_ID;
    g_LAST_PROCESS_DATE := TRUNC(SYSDATE);

	RETURN v_CURRENT_SESSION_PROCESS_ID;
END GET_CURRENT_SESSION_PROCESS_ID;
----------------------------------------------------------------------------------------------------
PROCEDURE CREATE_USER_SESSION_PROCESS IS
	v_LOG_LEVEL      NUMBER(3);
	v_KEEP_THEM_NUM  PLS_INTEGER;
	v_KEEP_THEM_BOOL BOOLEAN;
	v_PERSIST_NUM    PLS_INTEGER;
	v_PERSIST_BOOL   BOOLEAN;
	v_PROCESS_ID  	 PROCESS_LOG.PROCESS_ID%TYPE;
	v_PARENT_SID     SYSTEM_SESSION.SESSION_SID%TYPE;
	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');
BEGIN

	--Use the parent's session if this is a parallel child.  Otherwise use the current session.
	v_PARENT_SID := GET_PARALLEL_PARENT_SID;
	IF v_PARENT_SID IS NULL THEN
		-- Get all values from the session
		SELECT MAX(S.LOG_LEVEL), MAX(S.KEEP_EVENT_DETAIL), MAX(S.PERSIST_TRACE)
		INTO v_LOG_LEVEL, v_KEEP_THEM_NUM, v_PERSIST_NUM
		FROM SYSTEM_SESSION S
		WHERE S.SESSION_SID = v_SID
			AND S.SESSION_AUDSID = v_AUDSID;
	ELSE
		-- Get values from the parent session
		SELECT MAX(S.LOG_LEVEL), MAX(S.KEEP_EVENT_DETAIL), 1
		INTO v_LOG_LEVEL, v_KEEP_THEM_NUM, v_PERSIST_NUM
		FROM SYSTEM_SESSION S
		WHERE S.SESSION_SID = v_PARENT_SID
			AND S.SESSION_AUDSID = v_AUDSID;
	END IF;

	v_LOG_LEVEL := NVL(v_LOG_LEVEL, CURRENT_LOG_LEVEL());

	IF v_KEEP_THEM_NUM IS NULL THEN
		v_KEEP_THEM_BOOL := KEEPING_EVENT_DETAILS();
	ELSE
		v_KEEP_THEM_BOOL := UT.BOOLEAN_FROM_NUMBER(v_KEEP_THEM_NUM);
	END IF;

	IF v_PERSIST_NUM IS NULL THEN
		IF NOT SYS_CONTEXT('USERENV', 'BG_JOB_ID') IS NULL THEN
			-- All Background jobs should be set to persisting trace. Otherwise there is no way to see the trace data in the UI.
			v_PERSIST_BOOL := TRUE;
		ELSE
			v_PERSIST_BOOL := PERSISTING_TRACE();
		END IF;
	ELSE
		v_PERSIST_BOOL := UT.BOOLEAN_FROM_NUMBER(v_PERSIST_NUM);
	END IF;

	-- This will force a process entry to be created for the current user session if
	-- one does not already exist.
	v_PROCESS_ID := GET_CURRENT_SESSION_PROCESS_ID;

	PUSH_PROCESS(v_PROCESS_ID, v_LOG_LEVEL, v_PERSIST_BOOL, v_KEEP_THEM_BOOL);

END CREATE_USER_SESSION_PROCESS;
----------------------------------------------------------------------------------------------------
-- Gets information about the current process for the current session.
FUNCTION CURRENT_PROCESS_ID RETURN NUMBER IS
	v_CURRENT_PROCESS_ID PROCESS_LOG.PROCESS_ID%TYPE;
	v_TODAY              NUMBER(7);
	v_CUR_PROCESS_DATE   NUMBER(7);
BEGIN
	v_CURRENT_PROCESS_ID := g_PROCESSES(g_PROCESSES.LAST).PROCESS_ID;

	IF v_CURRENT_PROCESS_ID IS NULL THEN
		v_CURRENT_PROCESS_ID := GET_CURRENT_SESSION_PROCESS_ID();
	ELSE
		IF g_PROCESSES.COUNT = 1 THEN
			-- Then the Process Entry must be the User Session Process.
			-- Check the date of the process.
			v_TODAY := TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYDDD'));
			v_CUR_PROCESS_DATE := v_CURRENT_PROCESS_ID / 100000;
			IF v_TODAY <> v_CUR_PROCESS_DATE THEN
				-- Create new User Session Process for today
				v_CURRENT_PROCESS_ID := GET_CURRENT_SESSION_PROCESS_ID();
				-- Update the User Session Process Id on the stack
				g_PROCESSES(g_PROCESSES.FIRST()).PROCESS_ID := v_CURRENT_PROCESS_ID;
			END IF;
		END IF;
	END IF;

	RETURN v_CURRENT_PROCESS_ID;
END CURRENT_PROCESS_ID;
----------------------------------------------------------------------------------------------------
-- Gets information about the current process for the current session for audit trail.
FUNCTION CURRENT_AUDIT_PROCESS_ID RETURN NUMBER IS
	v_CURRENT_PROCESS_ID PROCESS_LOG.PROCESS_ID%TYPE := NULL;
BEGIN
	IF (GA.AUDIT_PROCESSES AND g_PROCESSES.COUNT != 1) OR (GA.AUDIT_USER_SESSIONS AND g_PROCESSES.COUNT = 1)THEN
    v_CURRENT_PROCESS_ID :=CURRENT_PROCESS_ID;
  END IF;

	RETURN v_CURRENT_PROCESS_ID;
END CURRENT_AUDIT_PROCESS_ID;
----------------------------------------------------------------------------------------------------
FUNCTION CURRENT_PROCESS_NAME RETURN VARCHAR2 IS
	v_CURRENT_PROCESS_ID   PROCESS_LOG.PROCESS_ID%TYPE;
	v_CURRENT_PROCESS_NAME PROCESS_LOG.PROCESS_NAME%TYPE;
BEGIN
	v_CURRENT_PROCESS_ID := CURRENT_PROCESS_ID();

	SELECT P.PROCESS_NAME INTO v_CURRENT_PROCESS_NAME FROM PROCESS_LOG P WHERE P.PROCESS_ID = v_CURRENT_PROCESS_ID;

	RETURN v_CURRENT_PROCESS_NAME;

END CURRENT_PROCESS_NAME;
----------------------------------------------------------------------------------------------------
PROCEDURE INIT_PROCESS_PROGRESS
	(
	p_PROGRESS_DESCRIPTION IN VARCHAR2 := 'Processing...',
	p_TOTAL_WORK           IN NUMBER := 100, -- default to 100 if set to null
	p_WORK_UNITS           IN VARCHAR2 := 'Steps',
	p_CAN_TERMINATE        IN BOOLEAN := FALSE
	) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_CURRENT_PROCESS_ID PROCESS_LOG.PROCESS_ID%TYPE;
	v_CAN_TERMINATE_NUM  NUMBER(1);
	DUMMY              NUMBER;
BEGIN
	-- Get Parent Process Id
	v_CURRENT_PROCESS_ID := CURRENT_PROCESS_ID();

	CLEAR_PROGRESS();

	DUMMY := PUSH_PROGRESS_RANGE(p_TOTAL_WORK);

	-- TODO: Add entry to SESSION_LONGOPS View (Phase 2)

	v_CAN_TERMINATE_NUM := UT.NUMBER_FROM_BOOLEAN(p_CAN_TERMINATE);

	-- Update 'Work Units' and 'Can Terminate' and 'Progree
	UPDATE PROCESS_LOG P
	SET P.PROGRESS_UNITS       = SUBSTR(p_WORK_UNITS, 1, c_WIDTH_PROGRESS_UNITS),
		P.PROGRESS_TOTALWORK   = p_TOTAL_WORK,
		P.PROGRESS_SOFAR	   = 0,
		P.PROGRESS_DESCRIPTION = SUBSTR(p_PROGRESS_DESCRIPTION, 1, c_WIDTH_PROGRESS_DESCRIPTION),
		P.CAN_TERMINATE        = v_CAN_TERMINATE_NUM
	WHERE P.PROCESS_ID = v_CURRENT_PROCESS_ID;

	COMMIT;
END INIT_PROCESS_PROGRESS;
----------------------------------------------------------------------------------------------------
PROCEDURE SET_WAS_TERMINATED(p_WAS_TERMINATED NUMBER) AS
BEGIN
	g_PROCESSES(g_PROCESSES.LAST()).WAS_TERMINATED := p_WAS_TERMINATED;
	TRACE_INTERNAL_STRUCTURES('SET_WAS_TERMINATED');
END SET_WAS_TERMINATED;
----------------------------------------------------------------------------------------------------
-- This internal private procedure is used for updating the Process_Log table with the latest
-- progress for the current process. This method internally calculates the progress_factor
-- based on the progress_stack. The progress_sofar is determined by multiplying the progress_
-- factor with the totalwork for the current process.
PROCEDURE PUT_PROCESS_PROGRESS(p_PROGRESS_DESCRIPTION IN VARCHAR2 := NULL) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_CURRENT_PROCESS_ID 	PROCESS_LOG.PROCESS_ID%TYPE;
	v_PROGRESS_DESCRIPTION	PROCESS_LOG.PROGRESS_DESCRIPTION%TYPE;
	v_PROGRESS_FACTOR   	NUMBER := 0;
	v_DIVISOR            	NUMBER := 1;
	v_TEMP_MAX_VALUE    	NUMBER := 0;
	v_TEMP_CUR_VALUE     	NUMBER := 0;
	v_WAS_TERMINATED     	NUMBER(1);
	v_CAN_TERMINATE		 	NUMBER(1);
	v_TERMINATED_BY_USER_ID	NUMBER(9);
	v_TERMINATED_BY			VARCHAR2(64);
BEGIN
	v_CURRENT_PROCESS_ID := CURRENT_PROCESS_ID();

	-- Determine the Progress Factor (represents the percentage of work done).
	VALIDATE_PROGRESS_STACK();

	FOR v_IDX IN g_PROGRESS_STACKS(v_CURRENT_PROCESS_ID).FIRST .. g_PROGRESS_STACKS(v_CURRENT_PROCESS_ID).LAST LOOP
		v_TEMP_MAX_VALUE := g_PROGRESS_STACKS(v_CURRENT_PROCESS_ID) (v_IDX).MAX_VALUE;
		v_TEMP_CUR_VALUE := g_PROGRESS_STACKS(v_CURRENT_PROCESS_ID) (v_IDX).CUR_VALUE;
		v_DIVISOR := v_DIVISOR * v_TEMP_MAX_VALUE;
		v_PROGRESS_FACTOR := v_PROGRESS_FACTOR + v_TEMP_CUR_VALUE / v_DIVISOR;
	END LOOP;

	v_PROGRESS_DESCRIPTION := SUBSTR(p_PROGRESS_DESCRIPTION, 1, c_WIDTH_PROGRESS_DESCRIPTION);

	-- Update the Process_Log table with the Progress, Return the value of Was_Terminated
	UPDATE PROCESS_LOG P
	SET P.PROGRESS_SOFAR       = P.PROGRESS_TOTALWORK * v_PROGRESS_FACTOR,
		P.PROGRESS_DESCRIPTION = NVL(v_PROGRESS_DESCRIPTION, P.PROGRESS_DESCRIPTION), -- leave alone if not specified
		P.PROGRESS_LAST_UPDATE = SYSDATE
	WHERE P.PROCESS_ID = v_CURRENT_PROCESS_ID
	RETURNING P.WAS_TERMINATED, P.CAN_TERMINATE, P.TERMINATED_BY_USER_ID INTO v_WAS_TERMINATED, v_CAN_TERMINATE, v_TERMINATED_BY_USER_ID;

	IF v_TERMINATED_BY_USER_ID IS NOT NULL THEN
		SELECT NVL(USER_DISPLAY_NAME, USER_NAME) INTO v_TERMINATED_BY
		FROM APPLICATION_USER
		WHERE USER_ID = v_TERMINATED_BY_USER_ID;
	END IF;

	-- Update the was_terminated value
	SET_WAS_TERMINATED(v_WAS_TERMINATED);

	COMMIT;

	IF v_WAS_TERMINATED = 1 AND v_CAN_TERMINATE = 1 THEN
		ERRS.RAISE(MSGCODES.c_ERR_CANCELLED, 'This process was terminated by ' || v_TERMINATED_BY);
	END IF;

END PUT_PROCESS_PROGRESS;
----------------------------------------------------------------------------------------------------
PROCEDURE UPDATE_PROCESS_PROGRESS
	(
	p_PROGRESS_VALUE       IN NUMBER,
	p_PROGRESS_DESCRIPTION IN VARCHAR2 := NULL,
	p_RANGE_INDEX          IN PLS_INTEGER := -1
	) IS
	v_IDX          PLS_INTEGER;
	v_CURPROCESSID PROCESS_LOG.PROCESS_ID%TYPE;
BEGIN
	IF NOT p_PROGRESS_VALUE IS NULL THEN

		v_CURPROCESSID := CURRENT_PROCESS_ID();

		IF p_RANGE_INDEX >= 0 THEN
			POP_PROGRESS_RANGE(p_RANGE_INDEX + 1, FALSE);
		END IF;

		VALIDATE_PROGRESS_STACK();

		v_IDX := g_PROGRESS_STACKS(v_CURPROCESSID).LAST();

		IF p_PROGRESS_VALUE > g_PROGRESS_STACKS(v_CURPROCESSID) (v_IDX).MAX_VALUE THEN
			g_PROGRESS_STACKS(v_CURPROCESSID)(v_IDX).CUR_VALUE := g_PROGRESS_STACKS(v_CURPROCESSID) (v_IDX)
																 .MAX_VALUE;
		ELSE
			g_PROGRESS_STACKS(v_CURPROCESSID)(v_IDX).CUR_VALUE := p_PROGRESS_VALUE;
		END IF;
		TRACE_INTERNAL_STRUCTURES('UPDATE_PROCESS_PROGRESS');

	END IF;

	PUT_PROCESS_PROGRESS(p_PROGRESS_DESCRIPTION);

END UPDATE_PROCESS_PROGRESS;
----------------------------------------------------------------------------------------------------
PROCEDURE INCREMENT_PROCESS_PROGRESS
	(
	p_PROGRESS_ADD         IN NUMBER := 1,
	p_PROGRESS_DESCRIPTION IN VARCHAR2 := NULL,
	p_RANGE_INDEX          IN PLS_INTEGER := -1
	) IS
	v_IDX          PLS_INTEGER;
	v_CURPROCESSID PROCESS_LOG.PROCESS_ID%TYPE;
BEGIN
	v_CURPROCESSID := CURRENT_PROCESS_ID();

	IF p_RANGE_INDEX > 0 THEN
		POP_PROGRESS_RANGE(p_RANGE_INDEX + 1, FALSE);
	END IF;

	VALIDATE_PROGRESS_STACK();

	v_IDX := g_PROGRESS_STACKS(v_CURPROCESSID).LAST();

	IF g_PROGRESS_STACKS(v_CURPROCESSID) (v_IDX).CUR_VALUE + p_PROGRESS_ADD > g_PROGRESS_STACKS(v_CURPROCESSID)
	 (v_IDX).MAX_VALUE THEN
		g_PROGRESS_STACKS(v_CURPROCESSID)(v_IDX).CUR_VALUE := g_PROGRESS_STACKS(v_CURPROCESSID) (v_IDX).MAX_VALUE;
	ELSE
		g_PROGRESS_STACKS(v_CURPROCESSID)(v_IDX).CUR_VALUE := g_PROGRESS_STACKS(v_CURPROCESSID) (v_IDX)
															 .CUR_VALUE + p_PROGRESS_ADD;
	END IF;
	TRACE_INTERNAL_STRUCTURES('INCREMENT_PROCESS_PROGRESS');

	PUT_PROCESS_PROGRESS(p_PROGRESS_DESCRIPTION);
END INCREMENT_PROCESS_PROGRESS;
----------------------------------------------------------------------------------------------------
-- This returns the severity code for the process id specified.
-- If the process_id is null then the current_process_id is used. The severity code is determined as the
-- event level for the most severe event logged. if the only events logged are for a
-- severity of Info or lower (like Debug) then this returns zero.
FUNCTION GET_PROCESS_SEVERITY(p_PROCESS_ID IN NUMBER := NULL) RETURN NUMBER IS
	v_PROCESS_STATUS PROCESS_LOG.PROCESS_STATUS%TYPE;
BEGIN
	IF p_PROCESS_ID IS NULL THEN
		v_PROCESS_STATUS := g_PROCESSES(g_PROCESSES.LAST).PROCESS_STATUS;
		-- if most severe event is less than notice, then the process is successful
		IF v_PROCESS_STATUS < c_LEVEL_NOTICE THEN
			v_PROCESS_STATUS := c_LEVEL_SUCCESS;
		END IF;
	ELSE
		-- get process record
		SELECT NVL(PROCESS_STATUS,
					CASE WHEN NUM_FATALS > 0 THEN c_LEVEL_FATAL
						 WHEN NUM_ERRORS > 0 THEN c_LEVEL_ERROR
						 WHEN NUM_WARNINGS > 0 THEN c_LEVEL_WARN
						 WHEN NUM_NOTICES > 0 THEN c_LEVEL_NOTICE
						 ELSE c_LEVEL_SUCCESS -- Success
						 END)
		INTO v_PROCESS_STATUS
		FROM PROCESS_LOG
		WHERE PROCESS_ID = p_PROCESS_ID;
	END IF;

	RETURN v_PROCESS_STATUS;

END GET_PROCESS_SEVERITY;
----------------------------------------------------------------------------------------------------
-- Determines the number of messages logged for this process. These functions return the
-- counts in NUM_FATALS, NUM_ERRORS, NUM_WARNINGS, and NUM_NOTICES fields.
FUNCTION GET_FATAL_COUNT RETURN NUMBER IS
	v_NUM PROCESS_LOG.NUM_FATALS%TYPE := 0;
BEGIN
	SELECT MAX(P.NUM_FATALS) INTO v_NUM FROM PROCESS_LOG P WHERE P.PROCESS_ID = CURRENT_PROCESS_ID();
	RETURN NVL(v_NUM, 0);
END GET_FATAL_COUNT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ERROR_COUNT RETURN NUMBER IS
	v_NUM PROCESS_LOG.NUM_ERRORS%TYPE := 0;
BEGIN
	SELECT MAX(P.NUM_ERRORS) INTO v_NUM FROM PROCESS_LOG P WHERE P.PROCESS_ID = CURRENT_PROCESS_ID();
	RETURN NVL(v_NUM, 0);
END GET_ERROR_COUNT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_WARNING_COUNT RETURN NUMBER IS
	v_NUM PROCESS_LOG.NUM_WARNINGS%TYPE := 0;
BEGIN
	SELECT MAX(P.NUM_WARNINGS) INTO v_NUM FROM PROCESS_LOG P WHERE P.PROCESS_ID = CURRENT_PROCESS_ID();
	RETURN NVL(v_NUM, 0);
END GET_WARNING_COUNT;
----------------------------------------------------------------------------------------------------
FUNCTION GET_NOTICE_COUNT RETURN NUMBER IS
	v_NUM PROCESS_LOG.NUM_NOTICES%TYPE := 0;
BEGIN
	SELECT MAX(P.NUM_NOTICES) INTO v_NUM FROM PROCESS_LOG P WHERE P.PROCESS_ID = CURRENT_PROCESS_ID();
	RETURN NVL(v_NUM, 0);
END GET_NOTICE_COUNT;
----------------------------------------------------------------------------------------------------
-- Gets the finish message for the process if it were to end right now.  This procedure does
-- not do anything to actually stop the process.
FUNCTION GET_FINISH_MESSAGE RETURN VARCHAR2 IS
	v_PROCESS_STATUS PROCESS_LOG.PROCESS_STATUS%TYPE := GET_PROCESS_SEVERITY;
BEGIN
	RETURN SUBSTR(
		CASE WHEN v_PROCESS_STATUS = c_LEVEL_FATAL THEN
				'Process aborted.'
			 WHEN v_PROCESS_STATUS >= c_LEVEL_ERROR THEN
				'Process encountered errors.'
			 WHEN v_PROCESS_STATUS >= c_LEVEL_WARN THEN
				'Process encountered warnings.'
			 WHEN v_PROCESS_STATUS >= c_LEVEL_NOTICE THEN
				'Process encountered notices.'
			 ELSE
				'Process completed successfully.'
			 END,
		1, 4000);
END GET_FINISH_MESSAGE;
----------------------------------------------------------------------------------------------------
-- Stops the current process. if p_STATUS is null then the process status will be
-- determined based on the most severe log event recorded (so NUM_FATALS, NUM_ERRORS,
-- NUM_WARNINGS, and NUM_NOTICES will be examined). if p_ALERT_TRIGGER is null then
-- the finish message is used as the trigger. The alert message will be the finish text
PROCEDURE END_PROCESS
	(
	p_PROCESS_ID  IN NUMBER,
	p_FINISH_TEXT IN VARCHAR2,
	p_STATUS      IN NUMBER := NULL,
	p_SQLCODE     IN NUMBER := 0,
	p_SQLERRM     IN VARCHAR2 := NULL
	) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_PROCESS_STATUS PROCESS_LOG.PROCESS_STATUS%TYPE;
BEGIN
	IF NOT p_PROCESS_ID IS NULL THEN

		v_PROCESS_STATUS := NVL(p_STATUS, GET_PROCESS_SEVERITY(p_PROCESS_ID));

		-- Update the Process Log Table with the new
		UPDATE PROCESS_LOG P
		SET P.PROGRESS_SOFAR       = P.PROGRESS_TOTALWORK,
		    P.PROGRESS_DESCRIPTION = 'Completed',
			P.PROCESS_STATUS       = v_PROCESS_STATUS,
			P.PROCESS_FINISH_TEXT  = SUBSTR(p_FINISH_TEXT, 1, c_WIDTH_PROCESS_FINISH_TEXT),
			P.PROCESS_ERRM         = SUBSTR(p_SQLERRM, 1, c_WIDTH_PROCESS_ERRM),
			P.PROCESS_CODE         = p_SQLCODE,
			P.PROCESS_STOP_TIME    = SYSDATE,
			P.NEXT_EVENT_CLEANUP   = SYSDATE
		WHERE P.PROCESS_ID = p_PROCESS_ID;

	END IF;

	COMMIT;
END END_PROCESS;
----------------------------------------------------------------------------------------------------
-- If this process has any child processes with anything above Info logged,
--   add a log message about it to the current process.
PROCEDURE LOG_EVENT_FROM_CHILD IS
	v_PROCESS_ID PROCESS_LOG.PROCESS_ID%TYPE;
	v_PROCESS_STATUS PROCESS_LOG.PROCESS_STATUS%TYPE;
BEGIN
	v_PROCESS_ID := g_PROCESSES(g_PROCESSES.LAST).PROCESS_ID;
	IF v_PROCESS_ID IS NOT NULL THEN

		SELECT MAX(CASE WHEN PROCESS_STATUS >= c_LEVEL_ERROR THEN c_LEVEL_ERROR ELSE PROCESS_STATUS END)
		INTO v_PROCESS_STATUS
		FROM PROCESS_LOG
		WHERE PARENT_PROCESS_ID = v_PROCESS_ID
			AND PROCESS_TYPE = c_PROCESS_TYPE_CHILD;

		IF v_PROCESS_STATUS >= c_LEVEL_NOTICE THEN
			LOG_EVENT(v_PROCESS_STATUS,
				CASE WHEN v_PROCESS_STATUS >= c_LEVEL_ERROR THEN
					'A Child Session for this Process encountered errors.'
				 WHEN v_PROCESS_STATUS >= c_LEVEL_WARN THEN
					'A Child Session for this Process encountered warnings.'
				 WHEN v_PROCESS_STATUS >= c_LEVEL_NOTICE THEN
					'A Child Session for this Process encountered notices.'
				 END);
		END IF;
	END IF;
END LOG_EVENT_FROM_CHILD;
----------------------------------------------------------------------------------------------------
-- Stops the current process. if p_STATUS is null then the process status will be
-- determined based on the most severe log event recorded (so NUM_FATALS, NUM_ERRORS,
-- NUM_WARNINGS, and NUM_NOTICES will be examined). if p_ALERT_TRIGGER is null then
-- the finish message is used as the trigger. The alert message will be the finish text
PROCEDURE STOP_PROCESS
	(
	p_FINISH_TEXT    IN OUT VARCHAR2,
	p_PROCESS_STATUS IN OUT NUMBER,
	p_SQLCODE        IN NUMBER := 0,
	p_SQLERRM        IN VARCHAR2 := NULL,
	p_ALERT_TRIGGER  IN VARCHAR2 := NULL
	) IS
BEGIN
	-- Determine if the current process is a 'User Session' or 'Job' process (only 1 in the stack)
	ASSERT(g_PROCESSES.COUNT > 1, 'Cannot invoke STOP_PROCESS to terminate User Session or Job process entry');

	-- Account for the worst status of any child sessions.
	LOG_EVENT_FROM_CHILD();

	IF p_PROCESS_STATUS IS NULL THEN
		p_PROCESS_STATUS := GET_PROCESS_SEVERITY;
	END IF;

	IF p_FINISH_TEXT IS NULL THEN
		p_FINISH_TEXT := GET_FINISH_MESSAGE;
	END IF;

	-- Handle Alerts
	ALERTS.TRIGGER_ALERTS(NVL(p_ALERT_TRIGGER, p_FINISH_TEXT),
						  p_PROCESS_STATUS,
						  p_FINISH_TEXT,
						  ALERTS.c_TYPE_PROCESS_COMPLETION);

	END_PROCESS(g_PROCESSES(g_PROCESSES.LAST).PROCESS_ID, p_FINISH_TEXT, p_PROCESS_STATUS, p_SQLCODE, p_SQLERRM);

	-- Remove current process from the stack
	POP_PROCESS();

	-- Update the new current process values in the session
	UPDATE_CURRENT_SESSION_VALUES(g_PROCESSES(g_PROCESSES.LAST).LOG_LEVEL,
								  g_PROCESSES(g_PROCESSES.LAST).PERSIST_TRACE,
								  g_PROCESSES(g_PROCESSES.LAST).KEEP_EVENT_DETAIL);

	-- Cleanup the progress stack
	CLEAR_PROGRESS();

END STOP_PROCESS;
----------------------------------------------------------------------------------------------------
FUNCTION IS_INFO_ENABLED RETURN BOOLEAN IS
BEGIN
	RETURN IS_LEVEL_ENABLED(c_LEVEL_INFO);
END IS_INFO_ENABLED;
----------------------------------------------------------------------------------------------------
FUNCTION IS_INFO_DETAIL_ENABLED RETURN BOOLEAN IS
BEGIN
	RETURN IS_LEVEL_ENABLED(c_LEVEL_INFO_DETAIL);
END IS_INFO_DETAIL_ENABLED;
----------------------------------------------------------------------------------------------------
FUNCTION IS_INFO_MORE_DETAIL_ENABLED RETURN BOOLEAN IS
BEGIN
	RETURN IS_LEVEL_ENABLED(c_LEVEL_INFO_MORE_DETAIL);
END IS_INFO_MORE_DETAIL_ENABLED;
----------------------------------------------------------------------------------------------------
FUNCTION IS_DEBUG_ENABLED RETURN BOOLEAN IS
BEGIN
	RETURN IS_LEVEL_ENABLED(c_LEVEL_DEBUG);
END IS_DEBUG_ENABLED;
----------------------------------------------------------------------------------------------------
FUNCTION IS_DEBUG_DETAIL_ENABLED RETURN BOOLEAN IS
BEGIN
	RETURN IS_LEVEL_ENABLED(c_LEVEL_DEBUG_DETAIL);
END IS_DEBUG_DETAIL_ENABLED;
----------------------------------------------------------------------------------------------------
FUNCTION IS_DEBUG_MORE_DETAIL_ENABLED RETURN BOOLEAN IS
BEGIN
	RETURN IS_LEVEL_ENABLED(c_LEVEL_DEBUG_MORE_DETAIL);
END IS_DEBUG_MORE_DETAIL_ENABLED;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_LOG_EVENT
	(
	p_EVENT_LEVEL      IN NUMBER,
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_SQLERRM          IN VARCHAR2 := NULL,
	p_PERSIST_TRACE    IN BOOLEAN := NULL,
	p_EVENT_TEXT_CLOB  IN CLOB := NULL,
	p_DETAIL_TYPE      IN VARCHAR2 := NULL,
	p_CONTENT_TYPE     IN VARCHAR2 := NULL
	) IS
	v_PROCESS_ID	  NUMBER;

	PROCEDURE STORE_EVENT AS
		PRAGMA AUTONOMOUS_TRANSACTION;

		v_RECORD PROCESS_LOG_EVENT%ROWTYPE;
		v_PROCEDURE_NAME  PROCESS_LOG_EVENT.PROCEDURE_NAME%TYPE;
		v_STEP_NAME       PROCESS_LOG_EVENT.STEP_NAME%TYPE;
		v_MESSAGE_RECORD  UT.MSG_DEF;
		v_EVENT_ID_SUFFIX NUMBER(11);
	BEGIN
		v_RECORD.PROCESS_ID := v_PROCESS_ID;
		v_RECORD.EVENT_LEVEL := p_EVENT_LEVEL;
		v_RECORD.EVENT_TIMESTAMP := SYSTIMESTAMP;
		v_RECORD.PROCEDURE_NAME := SUBSTR(p_PROCEDURE_NAME, 1, c_WIDTH_PROCEDURE_NAME);
		v_RECORD.STEP_NAME := SUBSTR(p_STEP_NAME, 1, c_WIDTH_STEP_NAME);
		v_RECORD.SOURCE_NAME := SUBSTR(p_SOURCE_NAME, 1, c_WIDTH_SOURCE_NAME);
		v_RECORD.SOURCE_DATE := p_SOURCE_DATE;
		v_RECORD.SOURCE_DOMAIN_ID := p_SOURCE_DOMAIN_ID;
		v_RECORD.SOURCE_ENTITY_ID := p_SOURCE_ENTITY_ID;
		v_RECORD.EVENT_ERRM := SUBSTR(p_SQLERRM, 1, c_WIDTH_EVENT_ERRM);
		v_RECORD.EVENT_TEXT := SUBSTR(p_EVENT_TEXT, 1, c_WIDTH_EVENT_TEXT);

		IF p_EVENT_TEXT_CLOB IS NOT NULL AND v_RECORD.EVENT_TEXT IS NULL THEN
			-- Passing clob w/o text means intention is to write standard message
			--  if possible, otherwise write to clob
			IF DBMS_LOB.GETLENGTH(p_EVENT_TEXT_CLOB) > 4000 THEN
				v_RECORD.EVENT_TEXT := 'Event contains large amount of text, please review detail';
			ELSE
				v_RECORD.EVENT_TEXT := DBMS_LOB.SUBSTR(p_EVENT_TEXT, 1, c_WIDTH_EVENT_TEXT);
			END IF;
	    ELSE
			v_RECORD.EVENT_TEXT := SUBSTR(p_EVENT_TEXT, 1, c_WIDTH_EVENT_TEXT);
		END IF;

		-- Test to see if both of these 2 parameters (procedure_name,step_name) are null
		IF v_RECORD.PROCEDURE_NAME IS NULL AND v_RECORD.STEP_NAME IS NULL THEN
			GET_CALLER(v_PROCEDURE_NAME, v_STEP_NAME, 3);
			v_RECORD.PROCEDURE_NAME := v_PROCEDURE_NAME;
			v_RECORD.STEP_NAME := v_STEP_NAME;
		END IF;

		-- Get the Event Suffix.  Trace level events use a sequence with a higher cache size.
		IF p_EVENT_LEVEL > c_LEVEL_DEBUG THEN
			SELECT EVENT_ID.NEXTVAL INTO v_EVENT_ID_SUFFIX FROM DUAL;
		ELSE
			SELECT TRACE_EVENT_ID.NEXTVAL INTO v_EVENT_ID_SUFFIX FROM DUAL;
		END IF;

		v_RECORD.EVENT_ID := (TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYDDD')) * 100000000000) + v_EVENT_ID_SUFFIX;

		-- Handle Message Ids
		IF NOT p_MESSAGE_CODE IS NULL THEN
			UT.GET_MESSAGE_DEFINITION(p_MESSAGE_CODE, v_MESSAGE_RECORD);
			IF NOT v_MESSAGE_RECORD.MESSAGE_ID IS NULL THEN
				IF v_RECORD.EVENT_TEXT IS NULL THEN
					v_RECORD.EVENT_TEXT := v_MESSAGE_RECORD.MESSAGE_TEXT;
				ELSE
					v_RECORD.EVENT_TEXT := v_MESSAGE_RECORD.MESSAGE_TEXT || ': ' || v_RECORD.EVENT_TEXT;
				END IF;
				v_RECORD.MESSAGE_ID := v_MESSAGE_RECORD.MESSAGE_ID;
			END IF;
		END IF;

		-- now put the log record
		IF p_EVENT_LEVEL > c_LEVEL_DEBUG THEN
			-- Insert Log Event into the PROCESS_LOG_EVENT Table
			IF p_EVENT_TEXT_CLOB IS NULL THEN
				LOGS_IMPL.PUT_PROCESS_LOG_EVENT(v_RECORD);
			ELSE
				LOGS_IMPL.PUT_PROCESS_LOG_EVENT(v_RECORD, p_EVENT_TEXT_CLOB, p_DETAIL_TYPE, p_CONTENT_TYPE);
			END IF;

			-- Update Process_Log with the number of events
			UPDATE PROCESS_LOG P
			SET P.NUM_FATALS   = CASE v_RECORD.EVENT_LEVEL WHEN c_LEVEL_FATAL THEN NVL(P.NUM_FATALS, 0) + 1 ELSE P.NUM_FATALS END,
				P.NUM_ERRORS   = CASE v_RECORD.EVENT_LEVEL WHEN c_LEVEL_ERROR THEN NVL(P.NUM_ERRORS, 0) + 1 ELSE P.NUM_ERRORS END,
				P.NUM_WARNINGS = CASE v_RECORD.EVENT_LEVEL WHEN c_LEVEL_WARN THEN NVL(P.NUM_WARNINGS, 0) + 1 ELSE P.NUM_WARNINGS END,
				P.NUM_NOTICES  = CASE v_RECORD.EVENT_LEVEL WHEN c_LEVEL_NOTICE THEN NVL(P.NUM_NOTICES, 0) + 1 ELSE P.NUM_NOTICES END,
				P.NUM_INFOS    = CASE WHEN v_RECORD.EVENT_LEVEL < c_LEVEL_NOTICE AND v_RECORD.EVENT_LEVEL > c_LEVEL_DEBUG THEN NVL(P.NUM_INFOS, 0) + 1 ELSE P.NUM_INFOS END
			WHERE P.PROCESS_ID = v_RECORD.PROCESS_ID;
		ELSIF NVL(p_PERSIST_TRACE, PERSISTING_TRACE()) THEN
			-- Insert Log Event into the PROCESS_LOG_TRACE Table
			LOGS_IMPL.PUT_PROCESS_LOG_TRACE(v_RECORD);
		ELSE
			-- Insert Log Event into the PROCESS_LOG_TEMP_TRACE Table
			LOGS_IMPL.PUT_PROCESS_LOG_TEMP_TRACE(v_RECORD);
		END IF;

		g_LAST_EVENT_ID := v_RECORD.EVENT_ID;

		COMMIT;
	END STORE_EVENT;
BEGIN
	-- make sure we have a process ID
	v_PROCESS_ID := CURRENT_PROCESS_ID;
	-- so that we can get this entry from the stack - this updates the record to track the
	-- most severe event level - even if we don't actually log it due to current log level
	g_PROCESSES(g_PROCESSES.LAST).PROCESS_STATUS := GREATEST(p_EVENT_LEVEL,
														g_PROCESSES(g_PROCESSES.LAST).PROCESS_STATUS);

	-- Check the Log_Level at this point
	IF NOT IS_LEVEL_ENABLED(p_EVENT_LEVEL) THEN
		-- Clear the last event so that if someone tries to post event_details
		-- after this log event, it will be ignored.
		g_LAST_EVENT_ID := NULL;
		RETURN;
	END IF;

	STORE_EVENT;

	TRACE_INTERNAL_STRUCTURES('PUT_LOG_EVENT');

END PUT_LOG_EVENT;
----------------------------------------------------------------------------------------------------
-- The following methods are the preferred methods for logging events. The generic
-- Log_Event and Log_Trace methods below should be used sparingly. Note that for all
-- log procedures below, if p_MESSAGE_CODE is non-null then the p_EVENT_TEXT will be
-- appended to the specified message’s text and the event will be associated with a
-- message ID. Otherwise the PROCESS_EVENTS.MESSAGE_ID field will be left null.

-- Fatal Error message - Note that this procedure does NOT need to be invoked. Code
-- should probably instead use Errs.Abort_Process, which will log a fatal event and stop
-- the process, all in one step.
PROCEDURE LOG_FATAL
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_SQLERRM          IN VARCHAR2 := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_FATAL, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  p_SQLERRM, NULL);
END LOG_FATAL;
----------------------------------------------------------------------------------------------------
-- Error messages
PROCEDURE LOG_ERROR
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_SQLERRM          IN VARCHAR2 := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_ERROR, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  p_SQLERRM, NULL);
END LOG_ERROR;

-- Error messages using clob
PROCEDURE LOG_ERROR_CLOB
  (
  p_EVENT_TEXT       IN VARCHAR2,
  p_EVENT_TEXT_CLOB  IN CLOB,
  p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
  p_STEP_NAME        IN VARCHAR2 := NULL,
  p_SOURCE_NAME      IN VARCHAR2 := NULL,
  p_SOURCE_DATE      IN DATE := NULL,
  p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
  p_SOURCE_ENTITY_ID IN NUMBER := NULL,
  p_MESSAGE_CODE     IN VARCHAR2 := NULL,
  p_SQLERRM          IN VARCHAR2 := NULL,
  p_DETAIL_TYPE      IN VARCHAR2 := NULL,
  p_CONTENT_TYPE     IN VARCHAR2 := NULL
  ) IS
BEGIN
  PUT_LOG_EVENT(c_LEVEL_ERROR, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
          p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
          p_SQLERRM, NULL, p_EVENT_TEXT_CLOB, p_DETAIL_TYPE, p_CONTENT_TYPE);
END LOG_ERROR_CLOB;
----------------------------------------------------------------------------------------------------
-- Warning messages
PROCEDURE LOG_WARN
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_SQLERRM          IN VARCHAR2 := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_WARN, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  p_SQLERRM, NULL);
END LOG_WARN;
----------------------------------------------------------------------------------------------------
-- Notice messages
PROCEDURE LOG_NOTICE
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_SQLERRM          IN VARCHAR2 := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_NOTICE, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  p_SQLERRM, NULL);
END LOG_NOTICE;
----------------------------------------------------------------------------------------------------
-- Info messages.
PROCEDURE LOG_INFO
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_INFO, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  NULL, NULL);
END LOG_INFO;
----------------------------------------------------------------------------------------------------
PROCEDURE LOG_INFO_DETAIL
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_INFO_DETAIL, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  NULL, NULL);
END LOG_INFO_DETAIL;
----------------------------------------------------------------------------------------------------
PROCEDURE LOG_INFO_MORE_DETAIL
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_INFO_MORE_DETAIL, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  NULL, NULL);
END LOG_INFO_MORE_DETAIL;
----------------------------------------------------------------------------------------------------
-- Debug messages. These messages will go into the trace tables. if p_Persist_Trace is
-- left null then the current session’s setting will be used
PROCEDURE LOG_DEBUG
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_PERSIST_TRACE    IN BOOLEAN := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_DEBUG, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  NULL, p_PERSIST_TRACE);
END LOG_DEBUG;
----------------------------------------------------------------------------------------------------
PROCEDURE LOG_DEBUG_DETAIL
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_PERSIST_TRACE    IN BOOLEAN := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_DEBUG_DETAIL, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  NULL, p_PERSIST_TRACE);
END LOG_DEBUG_DETAIL;
----------------------------------------------------------------------------------------------------
PROCEDURE LOG_DEBUG_MORE_DETAIL
	(
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_PERSIST_TRACE    IN BOOLEAN := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(c_LEVEL_DEBUG_MORE_DETAIL, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  NULL, p_PERSIST_TRACE);
END LOG_DEBUG_MORE_DETAIL;
----------------------------------------------------------------------------------------------------
-- Current log level?
FUNCTION CURRENT_LOG_LEVEL RETURN PLS_INTEGER IS
	v_CURRENT_LOG_LEVEL	PLS_INTEGER;
	v_TEMP_STR			SYSTEM_LABEL.CODE%TYPE;
BEGIN
	IF g_PROCESSES.COUNT > 0 THEN
		v_CURRENT_LOG_LEVEL := g_PROCESSES(g_PROCESSES.LAST).LOG_LEVEL;
	END IF;

	IF v_CURRENT_LOG_LEVEL IS NULL THEN
		SP.GET_DEFAULT_SYSTEM_LABEL_CODE(0, 'System', 'Logging', 'Log Levels', 'Values', 1, v_TEMP_STR);
		v_CURRENT_LOG_LEVEL := TO_NUMBER(v_TEMP_STR);
		v_CURRENT_LOG_LEVEL := NVL(v_CURRENT_LOG_LEVEL, c_LEVEL_INFO); -- default to c_Level_Info if it is null
	END IF;

	RETURN v_CURRENT_LOG_LEVEL;
END CURRENT_LOG_LEVEL;
----------------------------------------------------------------------------------------------------
PROCEDURE SET_CURRENT_LOG_LEVEL(p_LEVEL IN PLS_INTEGER) IS
	v_LEVEL PLS_INTEGER;
	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');
BEGIN
	-- do not change anything if the value is null
	IF NOT p_LEVEL IS NULL THEN
		-- Make sure this can't be set to a value > fatal
		IF p_LEVEL >= c_LEVEL_FATAL THEN
			v_LEVEL := c_LEVEL_FATAL;
		ELSE
			v_LEVEL := p_LEVEL;
		END IF;
		-- Update the Session value
		UPDATE SYSTEM_SESSION S SET S.LOG_LEVEL = v_LEVEL
		WHERE S.SESSION_SID = v_SID
			AND S.SESSION_AUDSID = v_AUDSID;
		-- Update the global variable
		g_PROCESSES(g_PROCESSES.LAST()).LOG_LEVEL := v_LEVEL;
	END IF;
END SET_CURRENT_LOG_LEVEL;
----------------------------------------------------------------------------------------------------
-- Are we persisting attachments to events?
FUNCTION KEEPING_EVENT_DETAILS RETURN BOOLEAN IS
	v_KEEP_THEM BOOLEAN;
BEGIN
	IF g_PROCESSES.COUNT > 0 THEN
		v_KEEP_THEM := g_PROCESSES(g_PROCESSES.LAST).KEEP_EVENT_DETAIL;
	END IF;

	IF v_KEEP_THEM IS NULL THEN
		v_KEEP_THEM := UT.BOOLEAN_FROM_STRING(GET_DICTIONARY_VALUE('Keep Event Detail', 0, 'System', 'Logging'));
		v_KEEP_THEM := NVL(v_KEEP_THEM, TRUE); -- default to true if it is null
	END IF;

	RETURN v_KEEP_THEM;
END KEEPING_EVENT_DETAILS;
----------------------------------------------------------------------------------------------------
PROCEDURE SET_KEEPING_EVENT_DETAILS(p_KEEP_THEM IN BOOLEAN) IS
	v_BOOL_NUM NUMBER(1) := 0;
	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');
BEGIN
	-- do not change anything if the value is null
	IF NOT p_KEEP_THEM IS NULL THEN
		v_BOOL_NUM := UT.NUMBER_FROM_BOOLEAN(p_KEEP_THEM);
		-- Update the Session value
		UPDATE SYSTEM_SESSION S SET S.KEEP_EVENT_DETAIL = v_BOOL_NUM
		WHERE S.SESSION_SID = v_SID
			AND S.SESSION_AUDSID = v_AUDSID;
		-- Update the global variable
		g_PROCESSES(g_PROCESSES.LAST()).KEEP_EVENT_DETAIL := p_KEEP_THEM;
		TRACE_INTERNAL_STRUCTURES('SET_KEEPING_EVENT_DETAILS');
	END IF;
END SET_KEEPING_EVENT_DETAILS;
----------------------------------------------------------------------------------------------------
-- Are we persisting trace messages?
FUNCTION PERSISTING_TRACE RETURN BOOLEAN IS
	v_PERSIST BOOLEAN;
BEGIN
	IF g_PROCESSES.COUNT > 0 THEN
		v_PERSIST := g_PROCESSES(g_PROCESSES.LAST).PERSIST_TRACE;
	END IF;

	IF v_PERSIST IS NULL THEN
		v_PERSIST := UT.BOOLEAN_FROM_STRING(GET_DICTIONARY_VALUE('Persist Trace', 0, 'System', 'Logging'));
		v_PERSIST := NVL(v_PERSIST, FALSE); -- default to false if it is null
	END IF;
	RETURN v_PERSIST;
END PERSISTING_TRACE;
----------------------------------------------------------------------------------------------------
PROCEDURE SET_PERSISTING_TRACE(p_PERSIST IN BOOLEAN) IS
	v_BOOL_NUM NUMBER(1) := 0;
	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');
BEGIN
	-- do not change anything if the value is null
	IF NOT p_PERSIST IS NULL THEN
		v_BOOL_NUM := UT.NUMBER_FROM_BOOLEAN(p_PERSIST);
		-- Update the Session value
		UPDATE SYSTEM_SESSION S SET S.PERSIST_TRACE = v_BOOL_NUM
		WHERE S.SESSION_SID = v_SID
			AND S.SESSION_AUDSID = v_AUDSID;
		-- Update the global variable
		g_PROCESSES(g_PROCESSES.LAST()).PERSIST_TRACE := p_PERSIST;
		TRACE_INTERNAL_STRUCTURES('SET_PERSISTING_TRACE');
	END IF;
END SET_PERSISTING_TRACE;
----------------------------------------------------------------------------------------------------
-- For testing progress reporting - should only be used from test windows...
PROCEDURE SET_PROGRESS_TRACKER
	(
	p_ENABLED IN BOOLEAN := TRUE,
	p_POLL_FREQ IN NUMBER := NULL, -- default: measure progress every 1/100th of a second
	p_WAIT_LIMIT IN NUMBER := NULL, -- default: delay up to 10 seconds for tracker job to start
	p_COMPRESS IN BOOLEAN := NULL -- default: Yes - only record progress measurements when changes
	) AS
BEGIN
	g_PROGRESS_TRACKER_ENABLED := p_ENABLED;
	IF p_POLL_FREQ IS NOT NULL THEN
		g_PROGRESS_TRACKER_POLL_FREQ := GREATEST(p_POLL_FREQ, 0.01);
	END IF;
	IF p_WAIT_LIMIT IS NOT NULL THEN
		g_PROGRESS_TRACKER_WAIT := GREATEST(p_WAIT_LIMIT, 0.1);
	END IF;
	IF p_COMPRESS IS NOT NULL THEN
		g_PROGRESS_TRACKER_COMPRESS := p_COMPRESS;
	END IF;
END SET_PROGRESS_TRACKER;
----------------------------------------------------------------------------------------------------
-- The progress tracker. Should generally only be called from inside the LOGS package.
-- Used for testing progress reporting for a process.
PROCEDURE PROGRESS_TRACKER
	(
	p_PROCESS_ID 	IN NUMBER,
	p_DELAY_SECS	IN NUMBER := 0.01, -- measure progress every 1/100th of a second
	p_COMPRESS		IN BOOLEAN := TRUE	-- compress results - discard redundant measurements
	) AS

PRAGMA AUTONOMOUS_TRANSACTION;

v_UNIQUE_SESSION_ID	VARCHAR2(24);
v_SO_FAR			NUMBER;
v_TOTAL_WORK		NUMBER;
v_STARTED			DATE;
v_STOPPED			DATE;
v_LAST_UPDATE		DATE;
v_DONE				BOOLEAN := FALSE;
v_REPORT			CLOB;
v_EVENT_ID			PROCESS_LOG_EVENT.EVENT_ID%TYPE;
v_PREV_LAST_UPDATE	DATE;
v_PREV_SO_FAR		NUMBER;
v_SEQ				PLS_INTEGER;
v_LINE				VARCHAR2(4000);
v_NUM_SECS			NUMBER;
	----------------------------------------------------------
	PROCEDURE WRITELINE IS
	BEGIN
		DBMS_LOB.WRITEAPPEND(v_REPORT, LENGTH(v_LINE||UTL_TCP.CRLF), v_LINE||UTL_TCP.CRLF);
		-- and then reset
		v_LINE := NULL;
	END WRITELINE;
	----------------------------------------------------------
	PROCEDURE APPEND(p_TEXT IN VARCHAR2) IS
	v_TEXT	VARCHAR2(4000) := p_TEXT;
	BEGIN
		IF INSTR(v_TEXT,',') > 0 OR INSTR(v_TEXT,'"') > 0 THEN
			v_TEXT := '"'||REPLACE(v_TEXT,'"','""')||'"';
		END IF;
		IF v_LINE IS NOT NULL THEN
			v_LINE := v_LINE||',';
		END IF;
		v_LINE := v_LINE||v_TEXT;
	END APPEND;
	----------------------------------------------------------
BEGIN
	-- monitor the specified process, recording measurements that are specified number of seconds apart
	-- delay can be less than one (i.e. measurements could be as often as 100/second via delay of 0.01)
	WHILE NOT v_DONE LOOP
		-- get process characteristics
		SELECT PROCESS_START_TIME, PROCESS_STOP_TIME,
				PROGRESS_TOTALWORK, PROGRESS_SOFAR,
				PROGRESS_LAST_UPDATE, UNIQUE_SESSION_CID
		INTO v_STARTED, v_STOPPED,
			v_TOTAL_WORK, v_SO_FAR,
			v_LAST_UPDATE, v_UNIQUE_SESSION_ID
		FROM PROCESS_LOG
		WHERE PROCESS_ID = p_PROCESS_ID;

		IF DBMS_SESSION.IS_SESSION_ALIVE(v_UNIQUE_SESSION_ID) AND v_STOPPED IS NULL THEN
			-- process still going

			IF NOT p_COMPRESS OR v_SEQ IS NULL OR v_LAST_UPDATE <> v_PREV_LAST_UPDATE OR v_SO_FAR <> v_PREV_SO_FAR THEN
				-- only record measurement when there is a delta to report unless p_COMPRESS is false
				v_STOPPED := CASE WHEN v_SO_FAR = 0 THEN NULL ELSE ((v_TOTAL_WORK * (v_LAST_UPDATE - v_STARTED)) / v_SO_FAR) + v_STARTED END;

				INSERT INTO PROGRESS_TRACKER_WORK (PROCESS_ID, SO_FAR, TOTAL_WORK, PCT_COMPLETE, PROCESS_START, PROCESS_STOP, STOP_IS_EST, TEST_TIMESTAMP, SEQ)
				VALUES (p_PROCESS_ID, v_SO_FAR, v_TOTAL_WORK,
						CASE WHEN v_TOTAL_WORK = 0 THEN NULL ELSE 100 * v_SO_FAR / v_TOTAL_WORK END,
						v_STARTED, v_STOPPED, 1,
						SYSTIMESTAMP, NVL(v_SEQ,0));

				v_PREV_LAST_UPDATE := v_LAST_UPDATE;
				v_PREV_SO_FAR := v_SO_FAR;
				v_SEQ := NVL(v_SEQ,0)+1;
			END IF;

			MUTEX.SLEEP(p_DELAY_SECS);

		ELSE
			-- process and/or session has completed
			INSERT INTO PROGRESS_TRACKER_WORK (PROCESS_ID, SO_FAR, TOTAL_WORK, PCT_COMPLETE, PROCESS_START, PROCESS_STOP, STOP_IS_EST, TEST_TIMESTAMP, SEQ)
			VALUES (p_PROCESS_ID, v_SO_FAR, v_TOTAL_WORK,
					CASE WHEN v_TOTAL_WORK = 0 THEN NULL ELSE 100 * v_SO_FAR / v_TOTAL_WORK END,
					v_STARTED, NVL(v_STOPPED,SYSDATE), 0,
					SYSTIMESTAMP, NVL(v_SEQ,0));

			v_DONE := TRUE;

		END IF;
	END LOOP;

	-- finished monitoring the process - now build the report and attach it to the process
	DBMS_LOB.CREATETEMPORARY(v_REPORT, TRUE);
	DBMS_LOB.OPEN(v_REPORT, DBMS_LOB.LOB_READWRITE);
	-- report headers
	APPEND('Timestamp');
	APPEND('Seconds');
	APPEND('Total Work');
	APPEND('So Far');
	APPEND('% Complete');
	APPEND('Start');
	APPEND('Stop');
	APPEND('Estimate?');
	WRITELINE;
	-- now report rows
	FOR v_REC IN (SELECT * FROM PROGRESS_TRACKER_WORK ORDER BY SEQ, TEST_TIMESTAMP) LOOP
		APPEND(TO_CHAR(v_REC.TEST_TIMESTAMP, 'YYYY-MM-DD HH24:MI:SSXFF'));
		-- this confusing expression is to convert INTERVAL data type (result of subtracting two TIMESTAMP values
		-- which is confusingly very different than subtracting two DATE values) to a number that represents number of seconds
		v_NUM_SECS := (CAST(v_REC.TEST_TIMESTAMP AS DATE)
						+ (v_REC.TEST_TIMESTAMP - TO_TIMESTAMP(v_REC.PROCESS_START)) * 86400
						- CAST(v_REC.TEST_TIMESTAMP AS DATE));
		APPEND(v_NUM_SECS);
		APPEND(v_REC.TOTAL_WORK);
		APPEND(v_REC.SO_FAR);
		APPEND(v_REC.PCT_COMPLETE);
		APPEND(TO_CHAR(v_REC.PROCESS_START, 'YYYY-MM-DD HH24:MI:SS'));
		APPEND(TO_CHAR(v_REC.PROCESS_STOP, 'YYYY-MM-DD HH24:MI:SS'));
		APPEND(CASE WHEN UT.BOOLEAN_FROM_NUMBER(v_REC.STOP_IS_EST) THEN 'Y' ELSE 'N' END);
		WRITELINE;
	END LOOP;
	DBMS_LOB.CLOSE(v_REPORT);

	-- now post it
	SELECT (TO_NUMBER(TO_CHAR(SYSDATE, 'YYYYDDD')) * 100000000000) + EVENT_ID.NEXTVAL INTO v_EVENT_ID FROM DUAL;
	-- log event
    LOGS_IMPL.PUT_PROCESS_LOG_EVENT(p_PROCESS_ID, v_EVENT_ID, LOGS.c_LEVEL_INFO_DETAIL,
        SYSTIMESTAMP, 'Progress Tracking Test Output. See attachment for details.');

	-- attachment to log evenT
    LOGS_IMPL.PUT_PROCESS_LOG_EVENT_DETAIL(v_EVENT_ID, 'Progress tracking results',
        CONSTANTS.MIME_TYPE_CSV, v_REPORT);

	-- Done
	COMMIT;

END PROGRESS_TRACKER;
----------------------------------------------------------------------------------------------------
-- Return true if the current process was terminated/cancelled by the user from the UI.
-- This function does not actually query for the state of the process. Instead, updating
-- the process progress via either of the above two methods will query for the state. So
-- the most frequently a process can check to see if a user cancelled it is as frequently
-- as it updates its progress – no more.
FUNCTION WAS_TERMINATED RETURN BOOLEAN IS
BEGIN
	RETURN UT.BOOLEAN_FROM_NUMBER(g_PROCESSES(g_PROCESSES.LAST).WAS_TERMINATED);
END WAS_TERMINATED;
----------------------------------------------------------------------------------------------------
-- What was the ID for the last event posted by this session. This returns null if the
-- last event was discarded due to the current log level
FUNCTION LAST_EVENT_ID RETURN NUMBER IS
BEGIN
	RETURN g_LAST_EVENT_ID;
END LAST_EVENT_ID;
----------------------------------------------------------------------------------------------------
-- Adds details/attachment to an event. if p_EVENT_ID is null then the details will be
-- posted to the last event posted by this session, using Last_Event_Id above. if
-- Last_Event_Id returns null, details are discarded.
PROCEDURE POST_EVENT_DETAILS
	(
	p_DETAIL_TYPE  IN VARCHAR2,
	p_CONTENT_TYPE IN VARCHAR2,
	p_CONTENTS     IN CLOB,
	p_EVENT_ID     IN NUMBER := NULL
	) IS
	PRAGMA AUTONOMOUS_TRANSACTION;
	v_EVENT_ID PROCESS_LOG_EVENT.EVENT_ID%TYPE;
BEGIN
	IF KEEPING_EVENT_DETAILS() THEN
		v_EVENT_ID := NVL(p_EVENT_ID, LAST_EVENT_ID);

		IF NOT v_EVENT_ID IS NULL AND NOT p_DETAIL_TYPE IS NULL AND NOT p_CONTENT_TYPE IS NULL THEN
            LOGS_IMPL.PUT_PROCESS_LOG_EVENT_DETAIL(v_EVENT_ID,
                                SUBSTR(p_DETAIL_TYPE, 1, c_WIDTH_DETAIL_TYPE),
				                SUBSTR(p_CONTENT_TYPE, 1, c_WIDTH_CONTENT_TYPE),
				                p_CONTENTS);

			COMMIT;
		END IF;
	END IF;
END POST_EVENT_DETAILS;
----------------------------------------------------------------------------------------------------
-- Generic logging procedures - the event level is a parameter to these methods
FUNCTION IS_LEVEL_ENABLED(p_EVENT_LEVEL IN PLS_INTEGER) RETURN BOOLEAN IS
BEGIN
	RETURN g_PROCESSES(g_PROCESSES.LAST).LOG_LEVEL <= p_EVENT_LEVEL;
END IS_LEVEL_ENABLED;
----------------------------------------------------------------------------------------------------
PROCEDURE LOG_EVENT
	(
	p_EVENT_LEVEL      IN NUMBER,
	p_EVENT_TEXT       IN VARCHAR2,
	p_PROCEDURE_NAME   IN VARCHAR2 := NULL,
	p_STEP_NAME        IN VARCHAR2 := NULL,
	p_SOURCE_NAME      IN VARCHAR2 := NULL,
	p_SOURCE_DATE      IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_MESSAGE_CODE     IN VARCHAR2 := NULL,
	p_SQLERRM          IN VARCHAR2 := NULL,
	p_PERSIST_TRACE    IN BOOLEAN := NULL
	) IS
BEGIN
	PUT_LOG_EVENT(p_EVENT_LEVEL, p_EVENT_TEXT, p_PROCEDURE_NAME, p_STEP_NAME, p_SOURCE_NAME,
				  p_SOURCE_DATE, p_SOURCE_DOMAIN_ID, p_SOURCE_ENTITY_ID, p_MESSAGE_CODE,
				  p_SQLERRM, p_PERSIST_TRACE);
END LOG_EVENT;
----------------------------------------------------------------------------------------------------
-- When a MSGCODES.e_ERR_COULD_NOT_START_PROCESS is thrown by START_PROCESS, this will
-- get the original exception that prevented the process from being created. This is
-- NOT intended for general use. It is intended only for use from the ERRS API.
PROCEDURE GET_SOURCE_OF_START_FAILURE
	(
	p_SQLCODE OUT NUMBER,
	p_SQLERRM OUT VARCHAR2
	) AS
BEGIN
	p_SQLCODE := g_START_FAIL_SQLCODE;
	p_SQLERRM := g_START_FAIL_SQLERRM;
END GET_SOURCE_OF_START_FAILURE;
----------------------------------------------------------------------------------------------------
-- Helper method to retrieve the name and line number of the calling routine. This will
-- be used when p_Procedure_Name and p_Step_Name are NULL to the various log routines
-- above. It is also public to allow other logic to take advantage of this capability.
PROCEDURE GET_CALLER
	(
	p_OBJECT_NAME	 OUT VARCHAR2,
	p_LINE_NUMBER    OUT PLS_INTEGER,
	p_HOW_FAR_BACK   IN PLS_INTEGER := 1
	) IS

	v_NEWLINE       VARCHAR2(1) := CHR(10);
	v_CALLSTACK     VARCHAR2(4000);
	v_LEN			PLS_INTEGER;
	v_LINE_BEGIN    PLS_INTEGER := 0;
	v_LINE_END      PLS_INTEGER := 0;
	v_CALL          VARCHAR2(128);
	v_OBJECT_HANDLE VARCHAR2(24);
	v_COUNT         NUMBER(3) := 0;
	v_HOW_FAR_BACK	PLS_INTEGER;

BEGIN
	v_CALLSTACK := DBMS_UTILITY.FORMAT_CALL_STACK;
	v_LEN := LENGTH(v_CALLSTACK);

	/*
            Unwind the call stack to get each call out by scanning the
            call stack string. Start with the index after the  first call
            on the stack. This will be after the first occurrence of
            'name' and the newline.
        */
	v_LINE_END := INSTR(v_CALLSTACK, 'name') + 4;

	-- Add one to p_HOW_FAR_BACK - a value of one will get this function's caller,
	-- but the intent is to get the invoker's caller (one level further back)
	v_HOW_FAR_BACK := p_HOW_FAR_BACK+1;

	WHILE v_COUNT <= v_HOW_FAR_BACK LOOP
		v_LINE_BEGIN := v_LINE_END+1;
		v_LINE_END := INSTR(v_CALLSTACK, v_NEWLINE, v_LINE_BEGIN);
		IF v_LINE_BEGIN >= v_LEN THEN
			-- end of stack trace before we got to the specified level?
			-- then there is no specified level - return NULL
			p_LINE_NUMBER := NULL;
			p_OBJECT_NAME := NULL;
			RETURN;
		END IF;
		v_COUNT := v_COUNT + 1;
	END LOOP;

	v_CALL := SUBSTR(v_CALLSTACK, v_LINE_BEGIN, v_LINE_END - v_LINE_BEGIN);

	v_CALL := TRIM(v_CALL);

	-- First get the object handle
	v_OBJECT_HANDLE := SUBSTR(v_CALL, 1, INSTR(v_CALL, ' ') - 1);

	-- Remove the object handle,then the white space
	v_CALL := SUBSTR(v_CALL, LENGTH(v_OBJECT_HANDLE) + 1);
	v_CALL := TRIM(v_CALL);

	-- Get the line number
	p_LINE_NUMBER := TO_NUMBER(SUBSTR(v_CALL, 1, INSTR(v_CALL, ' ')));

	-- Remove the line number, and white space
	v_CALL := SUBSTR(v_CALL, LENGTH(p_LINE_NUMBER) + 1);
	v_CALL := TRIM(v_CALL);

	-- What is left is the object name
	p_OBJECT_NAME := v_CALL;

END GET_CALLER;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_CALLER
	(
	p_PROCEDURE_NAME OUT VARCHAR2,
	p_STEP_NAME    	 OUT VARCHAR2,
	p_HOW_FAR_BACK   IN PLS_INTEGER := 1
	) AS
v_LINE PLS_INTEGER;
BEGIN
	-- add one to p_HOW_FAR_BACK since this procedure is now an extra one in the call-stack
	GET_CALLER(p_PROCEDURE_NAME, v_LINE, p_HOW_FAR_BACK+1);
	-- init-cap
	p_PROCEDURE_NAME := UPPER(SUBSTR(p_PROCEDURE_NAME,1,1))||SUBSTR(p_PROCEDURE_NAME,2);
	p_STEP_NAME := 'Line '||v_LINE;
END GET_CALLER;
----------------------------------------------------------------------------------------------------
-- Clean-up abandoned processes – either for this session only, or system-wide
PROCEDURE CLEANUP_ABANDONED_PROCESSES(p_THIS_SESSION_ONLY IN BOOLEAN) IS

	-- Added these local variables to avoid binding queries to SYS_CONTEXT.
	v_SID V$SESSION.SID%TYPE := SYS_CONTEXT('USERENV', 'SID');
	v_AUDSID V$SESSION.AUDSID%TYPE := SYS_CONTEXT('USERENV', 'SESSIONID');

	CURSOR c_ABANDONED_PROCESSES IS
		SELECT P.PROCESS_ID
		FROM PROCESS_LOG P,
			 (SELECT MAX(SUBSTR(USERNAME, 1, c_WIDTH_SCHEMA_NAME)) USERNAME,
					 MAX(SUBSTR(PROGRAM, 1, c_WIDTH_SESSION_PROGRAM)) PROGRAM,
					 MAX(SUBSTR(MACHINE, 1, c_WIDTH_SESSION_MACHINE)) MACHINE,
					 MAX(SUBSTR(OSUSER, 1, c_WIDTH_SESSION_OSUSER)) OSUSER,
					 MAX(SUBSTR(SID, 1, c_WIDTH_SESSION_SID)) SID,
					 MAX(SUBSTR(SERIAL#, 1, c_WIDTH_SESSION_SERIALNUM)) SERIAL#
			  FROM V$SESSION
			  WHERE SID = v_SID
					AND AUDSID = v_AUDSID) S
		WHERE P.SCHEMA_NAME = S.USERNAME
			  AND P.SESSION_PROGRAM = S.PROGRAM
			  AND P.SESSION_MACHINE = S.MACHINE
			  AND P.SESSION_OSUSER = S.OSUSER
			  AND P.SESSION_SID = S.SID
			  AND P.SESSION_SERIALNUM = S.SERIAL#
			  AND P.PROCESS_STOP_TIME IS NULL
			  AND P.PROCESS_TYPE <> c_PROCESS_TYPE_CHILD;

	CURSOR c_ALL_ABANDONED_PROCESSES IS
		SELECT PROCESS_ID
		FROM PROCESS_LOG
		WHERE PROCESS_STOP_TIME IS NULL
			AND UT.IS_SESSION_ALIVE(UNIQUE_SESSION_CID) = 0;
v_PROCESS_COUNT NUMBER(9);
BEGIN
	LOG_DEBUG('Starting Cleanup of Abandoned Processes...');
	v_PROCESS_COUNT := 0;
	IF p_THIS_SESSION_ONLY THEN
		LOG_DEBUG('Cleaning up this session only.');
		FOR v_PROCESS IN c_ABANDONED_PROCESSES LOOP
			END_PROCESS(v_PROCESS.PROCESS_ID, c_PROCESS_CLEANUP_MESSAGE);
			v_PROCESS_COUNT := v_PROCESS_COUNT + 1;
		END LOOP;
	ELSE
		FOR v_PROCESS IN c_ALL_ABANDONED_PROCESSES LOOP
			END_PROCESS(v_PROCESS.PROCESS_ID, c_PROCESS_CLEANUP_MESSAGE);
			v_PROCESS_COUNT := v_PROCESS_COUNT + 1;
		END LOOP;

		--Delete any stale System Session entries.
		DELETE SYSTEM_SESSION S
		WHERE NOT EXISTS
			(SELECT 1
			FROM V$SESSION V
			WHERE S.SESSION_SID = V.SID
				AND S.SESSION_AUDSID = V.AUDSID);
	END IF;
	LOG_DEBUG(v_PROCESS_COUNT || ' processes have been stopped.' );
	LOG_DEBUG('Finished Cleanup of Abandoned Processes...');
END CLEANUP_ABANDONED_PROCESSES;
----------------------------------------------------------------------------------------------------
-- Clean-up expired log events – for a specified process or for all of them
PROCEDURE CLEANUP_EXPIRED_EVENTS(p_PROCESS_ID IN NUMBER := NULL) IS

CURSOR c_LOG_LEVELS IS
	SELECT L.VALUE AS LEVEL_NAME, L.CODE AS LEVEL_ID
	FROM SYSTEM_LABEL L
	WHERE L.MODEL_ID = 0
	AND L.MODULE = 'System'
	AND L.KEY1 = 'Logging'
	AND L.KEY2 = 'Log Levels'
	AND L.KEY3 = 'Values'
	ORDER BY L.POSITION;

CURSOR c_ALL_EXPIRED_PROCESSES IS
	SELECT P.PROCESS_ID, P.PROCESS_NAME, P.PROCESS_STOP_TIME, P.NEXT_EVENT_CLEANUP
	FROM PROCESS_LOG P
	WHERE NVL(P.NEXT_EVENT_CLEANUP, HIGH_DATE) <= SYSDATE
	  AND p_PROCESS_ID IS NULL
	UNION ALL
	SELECT P.PROCESS_ID, P.PROCESS_NAME, P.PROCESS_STOP_TIME, P.NEXT_EVENT_CLEANUP
	FROM PROCESS_LOG P
	WHERE P.PROCESS_ID = p_PROCESS_ID;

CURSOR c_SETTINGS_BY_PROCESS_NAME(p_PROCESS_NAME IN VARCHAR) IS
	SELECT S.SETTING_NAME AS LOG_LEVEL, TO_NUMBER(S.VALUE) AS POLICY_VALUE
	FROM SYSTEM_DICTIONARY S
	WHERE S.MODEL_ID = 0
	AND S.MODULE = 'System'
	AND S.KEY1 = 'Logging'
	AND S.KEY2 = 'Event Retention Policy'
	AND S.KEY3 = p_PROCESS_NAME;

CURSOR c_SETTINGS_USING_WILD_CARD(p_PROCESS_NAME IN VARCHAR) IS
	SELECT X.SETTING_NAME AS LOG_LEVEL,
           MAX(X.POLICY_VALUE) AS POLICY_VALUE
	FROM (SELECT B.KEY3,
				 B.SETTING_NAME,
				 LAST_VALUE(CASE
								WHEN TO_NUMBER(A.VALUE) <= 0 THEN
								 c_MAX_EVENT_RETENTION
								ELSE
								 TO_NUMBER(A.VALUE)
							END IGNORE NULLS) OVER(PARTITION BY B.KEY3 ORDER BY B.CODE DESC) AS POLICY_VALUE
		  FROM SYSTEM_DICTIONARY A,
			   (-- CARTESIAN MERGE - return the sparse set, needed for the outer join
				-- Distinct Matching Wildcards + Distinct Set of Matching Log Levels
			    SELECT C.*, D.*
				FROM (-- Inner View - Distinct Set of Matching Policy Keys
					  SELECT DISTINCT S.MODEL_ID, S.MODULE, S.KEY1, S.KEY2, S.KEY3
					  FROM SYSTEM_DICTIONARY S
					  WHERE S.MODEL_ID = 0
							AND S.MODULE = 'System'
							AND S.KEY1 = 'Logging'
							AND S.KEY2 = 'Event Retention Policy'
							AND S.KEY3 <> '%'
							AND p_PROCESS_NAME LIKE S.KEY3) C,
					 (-- Inner View - Distinct Set of Log Levels Joined with System Label
					  SELECT DISTINCT D.SETTING_NAME, L.CODE
					  FROM SYSTEM_DICTIONARY D,
						   SYSTEM_LABEL L
					  WHERE D.SETTING_NAME = L.VALUE
					    AND D.MODEL_ID = 0
						AND D.MODULE = 'System'
						AND D.KEY1 = 'Logging'
						AND D.KEY2 = 'Event Retention Policy'
						AND D.KEY3 <> '%'
						AND p_PROCESS_NAME LIKE D.KEY3
						AND L.MODEL_ID = 0
						AND L.MODULE = 'System'
						AND L.KEY1 = 'Logging'
						AND L.KEY2 = 'Log Levels'
						AND L.KEY3 = 'Values') D ) B
		  WHERE A.MODEL_ID(+) = B.MODEL_ID
				AND A.MODULE(+) = B.MODULE
				AND A.KEY1(+) = B.KEY1
				AND A.KEY2(+) = B.KEY2
				AND A.KEY3(+) = B.KEY3
				AND A.SETTING_NAME(+) = B.SETTING_NAME) X
	GROUP BY X.SETTING_NAME;

v_EVENT_RETENTION_PERIOD NUMBER(9);
v_NEXT_CLEANUP_FOR_LEVEL DATE;
v_NEXT_CLEANUP_FOR_PROCESS DATE;
v_SETTINGS UT.STRING_MAP;
v_TODAY DATE;
v_DELETE_COUNT NUMBER;
v_DELETE_COMMENT_COUNT NUMBER;
v_AUDIT_RETENTION_DATE DATE;
v_AUDIT_RECORDS_SQL VARCHAR2(512);
v_AUDIT_DELETE_SQL VARCHAR2(512);
v_AUDIT_RETENTION_POLICY_VAL NUMBER(9);
v_ZAU_ID NUMBER(18);
c_AUDIT_RECORDS GA.REFCURSOR;
BEGIN
	v_TODAY := SYSDATE;
	LOG_DEBUG('Starting Cleanup Expired Events...');

	FOR v_PROCESS IN c_ALL_EXPIRED_PROCESSES LOOP

		v_SETTINGS.DELETE();

		LOG_DEBUG('Begin cleanup for process = ' || v_PROCESS.PROCESS_NAME);

		-- Precise
		FOR v_SETTING IN c_SETTINGS_BY_PROCESS_NAME(v_PROCESS.PROCESS_NAME)	LOOP
			v_SETTINGS(v_SETTING.LOG_LEVEL) := v_SETTING.POLICY_VALUE;
		END LOOP;

		-- Wildcard
		IF v_SETTINGS.COUNT = 0 THEN
			FOR v_SETTING IN c_SETTINGS_USING_WILD_CARD(v_PROCESS.PROCESS_NAME)	LOOP
				v_SETTINGS(v_SETTING.LOG_LEVEL) := v_SETTING.POLICY_VALUE;
			END LOOP;

			-- Default
			IF v_SETTINGS.COUNT = 0 THEN
				FOR v_SETTING IN c_SETTINGS_BY_PROCESS_NAME('%') LOOP
					v_SETTINGS(v_SETTING.LOG_LEVEL) := v_SETTING.POLICY_VALUE;
				END LOOP;

				IF v_SETTINGS.COUNT > 0 THEN
					LOG_DEBUG('Using DEFAULT retention policy.');
				END IF;
			ELSE
				LOG_DEBUG('Using WILDCARD retention policy.');
			END IF;
		ELSE
			LOG_DEBUG('Using PRECISE retention policy.');
		END IF;

		LOG_DEBUG('Found ' || v_SETTINGS.COUNT || ' settings.');

		IF v_SETTINGS.COUNT > 0 THEN

			v_EVENT_RETENTION_PERIOD := -1;
			v_NEXT_CLEANUP_FOR_PROCESS := HIGH_DATE;

			-- Loop over each Log Level
			FOR v_LEVEL IN c_LOG_LEVELS
			LOOP
				LOG_DEBUG('Processing... Level = ' || v_LEVEL.LEVEL_NAME);

				IF v_SETTINGS.EXISTS(v_LEVEL.LEVEL_NAME) THEN
					v_EVENT_RETENTION_PERIOD := NVL(v_SETTINGS(v_LEVEL.LEVEL_NAME), v_EVENT_RETENTION_PERIOD);
				END IF;

				LOG_DEBUG('Event retention policy = ' || v_EVENT_RETENTION_PERIOD);

				IF v_EVENT_RETENTION_PERIOD > 0 AND v_EVENT_RETENTION_PERIOD <> c_MAX_EVENT_RETENTION THEN
					v_NEXT_CLEANUP_FOR_LEVEL := v_PROCESS.PROCESS_STOP_TIME + v_EVENT_RETENTION_PERIOD;
					IF v_TODAY > v_NEXT_CLEANUP_FOR_LEVEL THEN

						-- First remove the event details if any exist.
						DELETE FROM PROCESS_LOG_EVENT_DETAIL D
						WHERE D.EVENT_ID IN (SELECT E.EVENT_ID
											 FROM PROCESS_LOG_EVENT E
											 WHERE E.PROCESS_ID = v_PROCESS.PROCESS_ID
							  				 AND E.EVENT_LEVEL = v_LEVEL.LEVEL_ID);

						LOG_DEBUG('Deleted ' || SQL%ROWCOUNT || ' event details.');

						IF v_LEVEL.LEVEL_ID > c_LEVEL_DEBUG THEN
							DELETE FROM PROCESS_LOG_EVENT P
							WHERE P.PROCESS_ID = v_PROCESS.PROCESS_ID
							  AND P.EVENT_LEVEL = v_LEVEL.LEVEL_ID;
							LOG_DEBUG('Deleted ' || SQL%ROWCOUNT || ' events.');
						ELSE
							DELETE FROM PROCESS_LOG_TRACE P
							WHERE P.PROCESS_ID = v_PROCESS.PROCESS_ID
							  AND P.EVENT_LEVEL = v_LEVEL.LEVEL_ID;
							LOG_DEBUG('Deleted ' || SQL%ROWCOUNT || ' debug events.');
						END IF;

					ELSIF v_NEXT_CLEANUP_FOR_LEVEL < v_NEXT_CLEANUP_FOR_PROCESS THEN
						-- Set as the new NEXT_EVENT_CLEANUP for this process to the minimum value
						v_NEXT_CLEANUP_FOR_PROCESS := v_NEXT_CLEANUP_FOR_LEVEL;
					END IF;
				END IF;
			END LOOP;
			LOG_DEBUG('Updating the Next Event Cleanup date = ' || v_NEXT_CLEANUP_FOR_PROCESS);
			-- Set the next cleanup for this Process
			UPDATE PROCESS_LOG P SET P.NEXT_EVENT_CLEANUP = v_NEXT_CLEANUP_FOR_PROCESS WHERE P.PROCESS_ID = v_PROCESS.PROCESS_ID;
		END IF;
		LOG_DEBUG('Finished cleanup for process = ' || v_PROCESS.PROCESS_NAME);
	END LOOP;

	LOG_DEBUG('Finished Cleanup Expired Events...');


	LOG_DEBUG('Starting Cleanup Audit Records...');

	v_AUDIT_RETENTION_POLICY_VAL := TO_NUMBER(NVL(GET_DICTIONARY_VALUE('Event Retention Policy', 0, 'System', 'Audit Trail'), 0));

	LOG_DEBUG('Audit Retention Policy = ' || v_AUDIT_RETENTION_POLICY_VAL);

	-- Loop over each System Table
	IF v_AUDIT_RETENTION_POLICY_VAL > 0 THEN
		v_AUDIT_RETENTION_DATE := v_TODAY-v_AUDIT_RETENTION_POLICY_VAL;
		FOR v_SYSTEM_TABLE IN (SELECT S.MIRROR_TABLE_NAME FROM SYSTEM_TABLE S) LOOP

			LOG_DEBUG('Begin cleanup for audit table = ' || v_SYSTEM_TABLE.MIRROR_TABLE_NAME);

			v_AUDIT_RECORDS_SQL := 'SELECT X.ZAU_ID ' ||
								   'FROM ' || v_SYSTEM_TABLE.MIRROR_TABLE_NAME || ' X ' ||
								   'WHERE X.ZAU_TIMESTAMP < :AUDIT_RETENTION_DATE';
			v_DELETE_COUNT := 0;
			v_DELETE_COMMENT_COUNT := 0;
			BEGIN
				OPEN c_AUDIT_RECORDS FOR v_AUDIT_RECORDS_SQL USING v_AUDIT_RETENTION_DATE;
				LOOP
				FETCH c_AUDIT_RECORDS INTO v_ZAU_ID;
				EXIT WHEN c_AUDIT_RECORDS%NOTFOUND;
					-- First, remove comments
					DELETE FROM AUDIT_CHANGE_COMMENT C WHERE C.ZAU_ID = v_ZAU_ID;
					v_DELETE_COMMENT_COUNT := v_DELETE_COMMENT_COUNT + SQL%ROWCOUNT;
					-- Next, remove audit records
					v_AUDIT_DELETE_SQL := 'DELETE FROM ' || v_SYSTEM_TABLE.MIRROR_TABLE_NAME || ' X ' ||
										  'WHERE X.ZAU_ID = :ZAU_ID';
					v_DELETE_COUNT := v_DELETE_COUNT + 1;
					EXECUTE IMMEDIATE v_AUDIT_DELETE_SQL USING v_ZAU_ID;
				END LOOP;
				CLOSE c_AUDIT_RECORDS;
			EXCEPTION
				WHEN OTHERS THEN
					IF c_AUDIT_RECORDS%ISOPEN THEN
						BEGIN
							CLOSE c_AUDIT_RECORDS;
						EXCEPTION
							WHEN OTHERS THEN ERRS.LOG_AND_CONTINUE();
						END;
					END IF;
					ERRS.LOG_AND_RAISE();
			END;
			LOG_DEBUG('Deleted ' || v_DELETE_COUNT || ' audit records and ' || v_DELETE_COMMENT_COUNT || ' audit comments.');
			LOG_DEBUG('Finished cleanup for audit table = ' || v_SYSTEM_TABLE.MIRROR_TABLE_NAME);
		END LOOP;
	END IF;

	LOG_DEBUG('Finished Cleanup Audit Records...');

END CLEANUP_EXPIRED_EVENTS;
----------------------------------------------------------------------------------------------------
PROCEDURE RUN_CLEANUP
	(
	p_TRACE_ON IN NUMBER := 0,
	p_MESSAGE OUT VARCHAR2,
	p_PROCESS_STATUS OUT NUMBER
	) IS
BEGIN
	START_PROCESS('Cleanup Logs', p_EVENT_LEVEL => CASE WHEN p_TRACE_ON = 1 THEN LOGS.c_LEVEL_DEBUG_MORE_DETAIL ELSE NULL END);
	CLEANUP_ABANDONED_PROCESSES(FALSE);
	CLEANUP_EXPIRED_EVENTS();
	STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);
EXCEPTION
	WHEN OTHERS THEN
		ERRS.ABORT_PROCESS();
END RUN_CLEANUP;
----------------------------------------------------------------------------------------------------
--Gracefully end the last process of a parallel child session.
PROCEDURE FINISH_PARALLEL_CHILD_PROCESS IS
BEGIN
	IF IS_PARALLEL_CHILD_SESSION AND g_PROCESSES.COUNT = 1 THEN
		END_PROCESS(g_PROCESSES(g_PROCESSES.LAST).PROCESS_ID, GET_FINISH_MESSAGE, GET_PROCESS_SEVERITY);
	END IF;
END;

-- Initialization
BEGIN
	CREATE_USER_SESSION_PROCESS();
END LOGS;
/
