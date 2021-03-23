CREATE OR REPLACE PACKAGE MUTEX IS
--Revision $Revision: 1.5 $

  -- Author  : JHUMPHRIES
  -- Created : 1/21/2008 12:02:24 PM
  -- Purpose : Provides re-entrant mutex functionality - provides simpler API to wrap DBMS_LOCK

c_MAX_WAIT CONSTANT INTEGER := 32767; -- must match DBMS_LOCK.MAXWAIT

SUBTYPE t_HANDLE IS VARCHAR2(128);

-- Acquire the named lock and return a handle to it. The handle is to be used later
-- to release the lock.
FUNCTION ACQUIRE
	(
	p_MUTEX_NAME IN VARCHAR2,
	p_TIMEOUT IN INTEGER := C_MAX_WAIT,
	p_EXCLUSIVE IN BOOLEAN := TRUE,
	p_RELEASE_ON_COMMIT IN BOOLEAN := FALSE
	) RETURN t_HANDLE;

-- Releases the specified lock handle
PROCEDURE RELEASE
	(
	p_HANDLE IN t_HANDLE
	);

-- Releases the specified lock handle, by name.
PROCEDURE RELEASE_BY_NAME
	(
	p_MUTEX_NAME IN VARCHAR2
	);

-- To synchronize two sessions so that a "parent" session waits for "child"
-- session to start before continuing, use these procedures.

-- Parent session first calls this method. The return value is a
-- mutex ID to be used with subsequent method calls.
FUNCTION SYNC_INIT RETURN VARCHAR2;

-- After parent has initialized (via above function) and then started the
-- child process, call this function. This will wait until the child is started
-- before returning. If the specified number of seconds elapses and the child
-- still has not started, it will return FALSE. If the child starts and then
-- the function returns, it returns TRUE.
FUNCTION SYNC_PARENT
	(
	p_MUTEX_IDENT	IN VARCHAR2,
	p_WAIT_SECONDS	IN NUMBER := 10
	) RETURN BOOLEAN;

-- Child process should call this procedure. It basically signals the parent
-- that the process is starting so both sessions will be "synchronized" and
-- can proceed.
PROCEDURE SYNC_CHILD
	(
	p_MUTEX_IDENT	IN VARCHAR2
	);

-- Wrapper for DBMS_LOCK.SLEEP
PROCEDURE SLEEP
	(
	p_SECONDS	IN NUMBER
	);

END MUTEX;
/
CREATE OR REPLACE PACKAGE BODY MUTEX IS
----------------------------------------------------------------------------------------------------
g_HAS_DBMS_LOCK_PRIV	BOOLEAN := NULL;
g_LOCK_HANDLES 			UT.STRING_MAP;

TYPE t_COUNT_MAP IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(128);
g_LOCK_COUNTS t_COUNT_MAP;
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.5 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
--Check to see if the current user can access DBMS_LOCK, and raise
-- an exception if it cannot.  If this step is not performed, Oracle sometimes
-- winds up with library cache latch contention trying to get a lock.
PROCEDURE CHECK_DBMS_LOCK_ACCESS IS
	v_COUNT NUMBER;
BEGIN
	IF g_HAS_DBMS_LOCK_PRIV IS NULL THEN

		SELECT COUNT(1)
		INTO v_COUNT
		FROM USER_TAB_PRIVS
		WHERE TABLE_NAME = 'DBMS_LOCK'
			AND PRIVILEGE = 'EXECUTE';
			
		g_HAS_DBMS_LOCK_PRIV := v_COUNT > 0;

	END IF;

	IF NOT g_HAS_DBMS_LOCK_PRIV THEN
		ERRS.RAISE(MSGCODES.c_ERR_NO_DBMS_LOCK);
	END IF;

END CHECK_DBMS_LOCK_ACCESS;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LOCK_HANDLE
	(
	p_MUTEX_NAME IN VARCHAR2
	) RETURN t_HANDLE IS
PRAGMA AUTONOMOUS_TRANSACTION; -- in its own transaction because this call could perform commits
								-- when generating a handle and storing into dbms_lock_allocated
v_LOCK_NAME VARCHAR2(4000);
v_HANDLE t_HANDLE;
BEGIN

	IF g_LOCK_HANDLES.EXISTS(p_MUTEX_NAME) THEN
		v_HANDLE := g_LOCK_HANDLES(p_MUTEX_NAME);
		LOGS.LOG_DEBUG_DETAIL('The lock handle already exists:' || v_HANDLE);
	ELSE
		-- fix up lock name so we don't collide with other schemas or other apps
		v_LOCK_NAME := 'VENTYX_EMO::'||APP_SCHEMA_NAME||'.MUTEX('||p_MUTEX_NAME||')';

		-- Get the lock handle for named lock
		LOGS.LOG_DEBUG_DETAIL('Attempting to allocate lock handle for new lock name: ' || v_LOCK_NAME);
		EXECUTE IMMEDIATE 'BEGIN DBMS_LOCK.ALLOCATE_UNIQUE(:name, :handle); END;'
			USING IN v_LOCK_NAME,
				  OUT v_HANDLE;

		LOGS.LOG_DEBUG_DETAIL('Handle has been allocated:' || v_HANDLE);
		g_LOCK_HANDLES(p_MUTEX_NAME) := v_HANDLE;
	END IF;

	COMMIT; -- close autonomous transaction
	RETURN v_HANDLE;
END GET_LOCK_HANDLE;
----------------------------------------------------------------------------------------------------
-- Acquire the named lock and return a handle to it. The handle is to be used later
-- to release the lock.
FUNCTION ACQUIRE
	(
	p_MUTEX_NAME IN VARCHAR2,
	p_TIMEOUT IN INTEGER := C_MAX_WAIT,
	p_EXCLUSIVE IN BOOLEAN := TRUE,
	p_RELEASE_ON_COMMIT IN BOOLEAN := FALSE
	) RETURN t_HANDLE IS
v_HANDLE t_HANDLE;
v_RET INTEGER;
v_MODE INTEGER;
v_ERROR_DESC VARCHAR2(256);
BEGIN
	CHECK_DBMS_LOCK_ACCESS;
	LOGS.LOG_DEBUG_DETAIL('Attempting to find lock handle named ' || p_MUTEX_NAME);

	v_HANDLE := GET_LOCK_HANDLE(p_MUTEX_NAME);

	IF g_LOCK_COUNTS.EXISTS(v_HANDLE) THEN
		IF g_LOCK_COUNTS(v_HANDLE) > 0 THEN
			-- already have it? increment count and return
			g_LOCK_COUNTS(v_HANDLE) := g_LOCK_COUNTS(v_HANDLE)+1;
			LOGS.LOG_DEBUG_DETAIL('Incremented lock count on this handle to '||g_LOCK_COUNTS(v_HANDLE)||'. Returning handle.');
			RETURN v_HANDLE;
		END IF;
	END IF;

	-- Find the correct lock mode.
	EXECUTE IMMEDIATE
		'BEGIN :mode := CASE WHEN :exclusive = 1 THEN DBMS_LOCK.X_MODE ELSE DBMS_LOCK.SS_MODE END; END;'
		USING OUT v_MODE,
			CASE WHEN p_EXCLUSIVE THEN 1 ELSE 0 END;
	LOGS.LOG_DEBUG_DETAIL('Found lock mode: ' || v_MODE || '.  Attempting to aquire lock.');

	-- Acquire the lock
	EXECUTE IMMEDIATE
		'BEGIN :ret := DBMS_LOCK.REQUEST(:handle, :mode, :timeout, CASE WHEN :release = 1 THEN TRUE ELSE FALSE END); END;'
		USING OUT v_RET,
			  v_HANDLE,
			  v_MODE,
			  p_TIMEOUT,
			  CASE WHEN p_RELEASE_ON_COMMIT THEN 1 ELSE 0 END;

	IF v_RET IN ( 0 /* success */, 4 /* already own lock */ ) THEN
		-- Success
		g_LOCK_COUNTS(v_HANDLE) := 1;
		LOGS.LOG_DEBUG_DETAIL('Lock was successfully acquired.  Returning handle.');
		RETURN v_HANDLE;
	ELSIF v_RET = 1 THEN
		--Timeout
		ERRS.RAISE(MSGCODES.c_ERR_LOCK_WAIT_TIME_OUT, 'Timeout exceeded while requesting "'||v_HANDLE||'" for mutex "'||p_MUTEX_NAME||'"');
	ELSE
		--Other error
		v_ERROR_DESC := CASE v_RET
			WHEN 2 THEN 'Deadlock'
			WHEN 3 THEN 'Parameter error'
			WHEN 5 THEN 'Illegal lock handle'
			ELSE 'Error ' || v_RET END;
		ERRS.RAISE(MSGCODES.c_ERR_FAILED_TO_ACQUIRE_LOCK, 'DBMS_LOCK.REQUEST failed due to "'||v_ERROR_DESC||'" while requesting "'||v_HANDLE||'" for mutex "'||p_MUTEX_NAME||'"');
	END IF;
END ACQUIRE;
----------------------------------------------------------------------------------------------------
-- Releases the specified lock handle
PROCEDURE RELEASE
	(
	p_HANDLE IN t_HANDLE
	) IS
v_COUNT PLS_INTEGER;
v_RET INTEGER;
BEGIN
	CHECK_DBMS_LOCK_ACCESS;
	IF g_LOCK_COUNTS.EXISTS(p_HANDLE) THEN
		v_COUNT := g_LOCK_COUNTS(p_HANDLE);
		IF v_COUNT <= 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_FAILED_TO_RELEASE_LOCK , 'An attempt was made to release lock handle "'||p_HANDLE||'", but that handle has already been released.');
		ELSIF v_COUNT = 1 THEN
			-- decrement count and release the lock
			g_LOCK_COUNTS(p_HANDLE) := 0;
			EXECUTE IMMEDIATE 'BEGIN :ret := DBMS_LOCK.RELEASE(:handle); END;'
				USING OUT v_RET, IN p_HANDLE;
			IF v_RET <> 0 THEN
				ERRS.RAISE(MSGCODES.c_ERR_FAILED_TO_RELEASE_LOCK, 'DBMS_LOCK.RELEASE returned "'||v_RET||'" while releasing "'||p_HANDLE||'".');
			END IF;
		ELSE
			-- Just decrement lock count
			g_LOCK_COUNTS(p_HANDLE) := v_COUNT-1;
			RETURN;
		END IF;
	ELSE
		ERRS.RAISE(MSGCODES.c_ERR_FAILED_TO_RELEASE_LOCK, 'An attempt was made to release lock handle "'||p_HANDLE||'", but that handle could not be found.');
	END IF;
END RELEASE;
----------------------------------------------------------------------------------------------------
-- Releases the specified lock handle, by name.
PROCEDURE RELEASE_BY_NAME
	(
	p_MUTEX_NAME IN VARCHAR2
	) IS
	v_HANDLE t_HANDLE;
BEGIN
	v_HANDLE := GET_LOCK_HANDLE(p_MUTEX_NAME);
	RELEASE(v_HANDLE);
END RELEASE_BY_NAME;
----------------------------------------------------------------------------------------------------
-- Parent session first calls this method. The return value is a
-- mutex id to be used with subsequent method calls.
FUNCTION SYNC_INIT RETURN VARCHAR2 AS
v_MUTEX_IDENT	VARCHAR2(24) := DBMS_SESSION.UNIQUE_SESSION_ID;
v_MUTEX_NAME	VARCHAR2(26) := 'Sync:P:'||v_MUTEX_IDENT;
DUMMY			t_HANDLE;
BEGIN
	-- acquire the "parent" lock and return
	DUMMY := ACQUIRE(v_MUTEX_NAME);
	RETURN v_MUTEX_IDENT;
END SYNC_INIT;
----------------------------------------------------------------------------------------------------
-- After parent has initialized (via above function) and then started the
-- child process, call this function. This will wait until the child is started
-- before returning. If the specified number of seconds elapses and the child
-- still has not started, it will return FALSE. If the child starts and then
-- the function returns, it returns TRUE.
FUNCTION SYNC_PARENT
	(
	p_MUTEX_IDENT	IN VARCHAR2,
	p_WAIT_SECONDS	IN NUMBER := 10
	) RETURN BOOLEAN AS

v_SUCCESS			BOOLEAN := FALSE;
v_DONE 				BOOLEAN := FALSE;
v_MUTEX_CHILD_NAME	VARCHAR2(26) := 'Sync:C:'||p_MUTEX_IDENT;
v_MUTEX_PARENT_NAME	VARCHAR2(26) := 'Sync:P:'||p_MUTEX_IDENT;
v_HANDLE			t_HANDLE;
v_TS_A				TIMESTAMP := SYSTIMESTAMP;

BEGIN

	-- we have the parent lock. we now want to wait until we ca*not* get
	-- the child lock (indicating child has started and acquired lock).
	WHILE NOT v_DONE LOOP
		BEGIN
			v_HANDLE := ACQUIRE(v_MUTEX_CHILD_NAME, 0); -- timeout zero means no wait
			-- immediately release and then wait
			RELEASE(v_HANDLE);

			IF SYSTIMESTAMP > v_TS_A + NUMTODSINTERVAL(p_WAIT_SECONDS, 'SECOND') THEN
				-- time out!
				v_DONE := TRUE;
			END IF;

			SLEEP(0.1); -- wait tenth of a second between attempts
		EXCEPTION
			WHEN MSGCODES.e_ERR_LOCK_WAIT_TIME_OUT THEN
				-- couldn't get lock? then child has it - ready to go!
				v_SUCCESS := TRUE;
				v_DONE := TRUE;
		END;
	END LOOP;

	-- make sure to release this before leaving - allows child to continue
	RELEASE_BY_NAME(v_MUTEX_PARENT_NAME);

	RETURN v_SUCCESS;

EXCEPTION
	WHEN OTHERS THEN
		-- don't leave w/out releasing the lock
		BEGIN
			RELEASE_BY_NAME(v_MUTEX_PARENT_NAME);
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE;
		END;

		ERRS.LOG_AND_RAISE;

END SYNC_PARENT;
----------------------------------------------------------------------------------------------------
-- Child process should call this procedure. It basically signals the parent
-- that the process is starting so both sessions will be "synchronized" and
-- can proceed.
PROCEDURE SYNC_CHILD
	(
	p_MUTEX_IDENT	IN VARCHAR2
	) AS

v_MUTEX_CHILD_NAME	VARCHAR2(26) := 'Sync:C:'||p_MUTEX_IDENT;
v_MUTEX_PARENT_NAME	VARCHAR2(26) := 'Sync:P:'||p_MUTEX_IDENT;
v_CHILD_HANDLE		t_HANDLE;
v_PARENT_HANDLE		t_HANDLE;

BEGIN

	-- acquiring this lock will signal to parent that child has started
	-- so it will release its lock
	v_CHILD_HANDLE := ACQUIRE(v_MUTEX_CHILD_NAME);
	-- wait for parent to release its lock
	v_PARENT_HANDLE := ACQUIRE(v_MUTEX_PARENT_NAME);
	-- parent has released its lock so we are now ready to go
	RELEASE(v_CHILD_HANDLE);
	RELEASE(v_PARENT_HANDLE);

EXCEPTION
	WHEN OTHERS THEN
		-- don't leave w/out releasing the locks
		BEGIN
			IF v_CHILD_HANDLE IS NOT NULL THEN
				RELEASE(v_CHILD_HANDLE);
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE;
		END;
		BEGIN
			IF v_PARENT_HANDLE IS NOT NULL THEN
				RELEASE(v_PARENT_HANDLE);
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE;
		END;

		ERRS.LOG_AND_RAISE;

END SYNC_CHILD;
----------------------------------------------------------------------------------------------------
-- Wrapper for DBMS_LOCK.SLEEP
PROCEDURE SLEEP
	(
	p_SECONDS	IN NUMBER
	) AS
BEGIN
	CHECK_DBMS_LOCK_ACCESS;
	EXECUTE IMMEDIATE 'BEGIN DBMS_LOCK.SLEEP(:1); END;' USING p_SECONDS;
END SLEEP;
----------------------------------------------------------------------------------------------------
END MUTEX;
/
