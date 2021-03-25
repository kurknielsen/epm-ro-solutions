CREATE OR REPLACE PACKAGE JOB_PROGRAMS IS
--Revision $Revision: 1.5 $

  -- Author  : MWEATHERS
  -- Created : 7/7/2008
  -- Purpose : Contains Programs to be used by the DBMS_SCHEDULER and some helper procedures for creating jobs.

--NOTE: DEFAULT VALUES WILL NOT BE USED BY JOBS.  PARAMETERS THAT ARE NOT SPECIFIED FOR A JOB WILL BE PASSED IN AS "NULL".

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE PROCESS_QUEUED_EMAILS_PRG;

PROCEDURE CLEANUP_LOB_STAGING_PRG;

PROCEDURE REACTOR_PRG
	(
	p_TRACE_ON IN NUMBER DEFAULT 0
	);

PROCEDURE PROCESS_QUEUES_MONITOR_PRG;

PROCEDURE CLEANUP_PROCESS_EVENTS_PRG
	(
	p_TRACE_ON IN NUMBER DEFAULT 0
	);

PROCEDURE REBUILD_CUSTOM_REALMS_PRG;

PROCEDURE APPLY_AUTO_DATA_LOCKS_PRG;

PROCEDURE SEND_APPROVED_INVOICES_PRG
	(
	p_EXPORT_FMT IN NUMBER DEFAULT 0
	);

PROCEDURE EC_CERT_EXPIR_ALERT_PRG;	
PROCEDURE OADR_POLL_PRG;
--NOTE: DEFAULT VALUES WILL NOT BE USED BY JOBS.  PARAMETERS THAT ARE NOT SPECIFIED FOR A JOB WILL BE PASSED IN AS "NULL".

END JOB_PROGRAMS;
/
CREATE OR REPLACE PACKAGE BODY JOB_PROGRAMS IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.5 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_QUEUED_EMAILS_PRG
AS BEGIN

	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	ML.PROCESS_QUEUED;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END PROCESS_QUEUED_EMAILS_PRG;
---------------------------------------------------------------------------------------------------
-- Delete anything in the LOB staging tables that is too old.
PROCEDURE CLEANUP_LOB_STAGING_PRG AS
	v_DAYS NUMBER;
BEGIN

	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	v_DAYS := NVL(GET_DICTIONARY_VALUE('Days Old', 0, 'System', 'Background Jobs', 'Lob Staging Cleanup'),31);

	DELETE BACKGROUND_CLOB_STAGING WHERE ENTRY_DATE < SYSDATE - v_DAYS;
	DELETE BACKGROUND_BLOB_STAGING WHERE ENTRY_DATE < SYSDATE - v_DAYS;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END CLEANUP_LOB_STAGING_PRG;
---------------------------------------------------------------------------------------------------
-- Run the Reactor to check for data changes and react to them.
PROCEDURE REACTOR_PRG
	(
	p_TRACE_ON IN NUMBER DEFAULT 0
	) AS
BEGIN

	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	IF NVL(p_TRACE_ON,0) > 0 THEN
		LOGS.SET_CURRENT_LOG_LEVEL(p_LEVEL => LOGS.c_LEVEL_DEBUG_MORE_DETAIL);
	END IF;

	REACTOR.REACT;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END REACTOR_PRG;
---------------------------------------------------------------------------------------------------
-- Check to see if there is any work in the queue to perform
PROCEDURE PROCESS_QUEUES_MONITOR_PRG AS
BEGIN
	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	-- Loop over all Job Threads and call DEQUEUE
	FOR v_JOB_THREAD IN (SELECT T.JOB_THREAD_ID FROM JOB_THREAD T)
    LOOP
   		JOBS.DEQUEUE_BY_JOB_THREAD(v_JOB_THREAD.JOB_THREAD_ID);
 	END LOOP;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END PROCESS_QUEUES_MONITOR_PRG;
---------------------------------------------------------------------------------------------------
-- Remove any expired events in the PROCESS_LOG_EVENT table as defined by the Event Retention Policy
PROCEDURE CLEANUP_PROCESS_EVENTS_PRG
	(
	p_TRACE_ON IN NUMBER DEFAULT 0
	) AS
v_MESSAGE VARCHAR2(4000);
v_STATUS NUMBER(9);
BEGIN
	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	-- Cleanup ALL expired events and Abandoned processes
	LOGS.RUN_CLEANUP(NVL(p_TRACE_ON,0), v_MESSAGE, v_STATUS);

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END CLEANUP_PROCESS_EVENTS_PRG;
---------------------------------------------------------------------------------------------------
PROCEDURE REBUILD_CUSTOM_REALMS_PRG AS
v_ID NUMBER(9);
BEGIN
	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	-- Find all realms defined via custom queries and re-generate them
	FOR v_REALM_ID IN (SELECT REALM_ID
						FROM SYSTEM_REALM
						WHERE NVL(TRIM(CUSTOM_QUERY),'?') <> '?'
							AND REALM_CALC_TYPE = 0 /* exclude calc and fml.charge realms */) LOOP
		v_ID := v_REALM_ID.REALM_ID;
		SD.POPULATE_ENTITIES_FOR_REALM(v_REALM_ID.REALM_ID);
		v_ID := NULL; -- reset once we've successfully populated entities for this realm
	END LOOP;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE(p_EXTRA_MESSAGE => CASE WHEN v_ID IS NULL THEN NULL ELSE
							'Populating member entities for '||TEXT_UTIL.TO_CHAR_ENTITY(v_ID, EC.ED_SYSTEM_REALM, TRUE)
							END);
END REBUILD_CUSTOM_REALMS_PRG;
---------------------------------------------------------------------------------------------------
PROCEDURE APPLY_AUTO_DATA_LOCKS_PRG AS
BEGIN
	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	-- Find all realms defined via custom queries and re-generate them
	DATA_LOCK.APPLY_AUTO_DATA_LOCK_GROUPS;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END APPLY_AUTO_DATA_LOCKS_PRG;
---------------------------------------------------------------------------------------------------
PROCEDURE SEND_APPROVED_INVOICES_PRG
	(
	p_EXPORT_FMT IN NUMBER DEFAULT 0
	) AS
v_MESSAGE VARCHAR2(4000);
v_STATUS NUMBER(9);
BEGIN
	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	-- Email all approved invoices in the INVOICE table
	BSJ.EMAIL_ALL_APPROVED_INVOICES(p_EXPORT_FMT, v_STATUS, v_MESSAGE);

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END SEND_APPROVED_INVOICES_PRG;
---------------------------------------------------------------------------------------------------
PROCEDURE EC_CERT_EXPIR_ALERT_PRG AS
BEGIN
	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	-- Email all external credential certificates that will expire in the next 30 days
	SA.SEND_EXTERNAL_CREDENTIAL_ALERT;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END EC_CERT_EXPIR_ALERT_PRG;
---------------------------------------------------------------------------------------------------
PROCEDURE OADR_POLL_PRG AS
BEGIN
	--SESSION_START is required for every job, to set the current user name.
	SESSION_START;

	-- oadr poll
	DEMAND_RESPONSE_UTIL.OADR_POLL;

--Log the error to our log rather than just letting it bubble up to the DBMS Scheduler's log.
EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE;
END OADR_POLL_PRG;
---------------------------------------------------------------------------------------------------

END JOB_PROGRAMS;
/
