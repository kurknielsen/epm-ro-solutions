CREATE OR REPLACE PACKAGE SCHEDULE_MANAGEMENT_REACTOR IS
-- $Revision: 1.4 $

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- Resets package variables so that we have a clean slate for queuing and
-- processing schedule entries.
PROCEDURE RESET;

-- Queues a schedule entry for inclusion in next sync to schedule management.
-- %param p_TRANSACTION_ID		The transaction ID for the queued record
-- %param p_STATEMENT_TYPE_ID	The schedule type for the queued record
-- %param p_SCHEDULE_STATE		The schedule state for the queued record
-- %param p_SCHEDULE_DATE		The schedule date for the queued record
PROCEDURE QUEUE_RECORD
(
p_TRANSACTION_ID IN NUMBER,
p_STATEMENT_TYPE_ID IN NUMBER,
p_SCHEDULE_STATE IN NUMBER,
p_SCHEDULE_DATE IN DATE
);

-- Processes the current queue of schedule entries into an export file. 
PROCEDURE PROCESS_QUEUE;

-- Get the current background LOB ID.
-- %return	The current background LOB ID. This ID is used to store files
-- into BACKGROUND_CLOB_STAGING when a queue of records is processed.
FUNCTION GET_BG_LOB_ID RETURN NUMBER;

-- Submit a file to schedule management for synchronization.
-- %param p_BG_LOB_ID	The Background LOB ID to submit. If unspecified or 
--				NULL then current LOB ID will be used.
PROCEDURE SUBMIT
(
p_BG_LOB_ID IN NUMBER := NULL
);


END SCHEDULE_MANAGEMENT_REACTOR;
/
CREATE OR REPLACE PACKAGE BODY SCHEDULE_MANAGEMENT_REACTOR IS
--------------------------------------------------------------------------------
g_BG_LOB_ID BACKGROUND_CLOB_STAGING.BACKGROUND_LOB_ID%TYPE;
--------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE RESET
AS
BEGIN
	SELECT BACKGROUND_LOB_ID.NEXTVAL INTO g_BG_LOB_ID FROM DUAL;
	EXECUTE IMMEDIATE 'TRUNCATE TABLE IT_SCHEDULE_MANAGEMENT_STAGING';
END RESET;
--------------------------------------------------------------------------------
PROCEDURE QUEUE_RECORD
(
p_TRANSACTION_ID IN NUMBER,
p_STATEMENT_TYPE_ID IN NUMBER,
p_SCHEDULE_STATE IN NUMBER,
p_SCHEDULE_DATE IN DATE
)
AS
	v_SCHED_MGMT_CID IT_SCHEDULE_MANAGEMENT_MAP.SCHED_MGMT_CID%TYPE;
	v_SCHED_MGMT_DATA_SOURCE IT_SCHEDULE_MANAGEMENT_MAP.SCHED_MGMT_DATA_SOURCE%TYPE;
BEGIN
	BEGIN
		-- Get the corresponding Schedule Management mapping
		SELECT M.SCHED_MGMT_CID, M.SCHED_MGMT_DATA_SOURCE
		INTO v_SCHED_MGMT_CID, v_SCHED_MGMT_DATA_SOURCE
		FROM IT_SCHEDULE_MANAGEMENT_MAP M
		WHERE M.TRANSACTION_ID = p_TRANSACTION_ID
			AND M.STATEMENT_TYPE_ID = p_STATEMENT_TYPE_ID
			AND M.SCHEDULE_STATE = p_SCHEDULE_STATE;
		
		-- Add the changed IT_SCHEDULE to the staging table
		INSERT INTO IT_SCHEDULE_MANAGEMENT_STAGING
		SELECT v_SCHED_MGMT_CID, v_SCHED_MGMT_DATA_SOURCE, S.SCHEDULE_DATE, NVL(S.AMOUNT,0), T.TRANSACTION_INTERVAL 
		FROM INTERCHANGE_TRANSACTION T, IT_SCHEDULE S
		WHERE T.TRANSACTION_ID = p_TRANSACTION_ID
			AND S.TRANSACTION_ID = T.TRANSACTION_ID
			AND S.SCHEDULE_TYPE = p_STATEMENT_TYPE_ID
			AND S.SCHEDULE_STATE = p_SCHEDULE_STATE
			AND S.SCHEDULE_DATE = p_SCHEDULE_DATE;

		-- Debug Information
		LOGS.LOG_DEBUG ('Queued Record in the stagging table for Schedule Management CID = ' || v_SCHED_MGMT_CID 
							|| ' and Data Source = ' || v_SCHED_MGMT_DATA_SOURCE);

	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			LOGS.LOG_DEBUG('Unable to find matching record in the Schedule Management Mapping table');
			RETURN;
	END;
END QUEUE_RECORD;
--------------------------------------------------------------------------------
PROCEDURE PROCESS_QUEUE AS

v_EXISTS	PLS_INTEGER;

BEGIN
	-- Do we have any records to send?
	SELECT COUNT(1)
	INTO v_EXISTS
	FROM IT_SCHEDULE_MANAGEMENT_STAGING
	WHERE ROWNUM=1;

	-- If so, create the payload to send	
	IF v_EXISTS <> 0 THEN
		INSERT INTO BACKGROUND_CLOB_STAGING (BACKGROUND_LOB_ID, CLOB_VAL, ENTRY_DATE)
		VALUES (GET_BG_LOB_ID, SCHEDULE_MANAGEMENT_SYNC.BUILD_FILE, SYSDATE);
	-- Otherwise setup the payload as NULL
	ELSE
		INSERT INTO BACKGROUND_CLOB_STAGING (BACKGROUND_LOB_ID, CLOB_VAL, ENTRY_DATE)
		VALUES (GET_BG_LOB_ID, NULL, SYSDATE);
	END IF;
END PROCESS_QUEUE;
--------------------------------------------------------------------------------
FUNCTION GET_BG_LOB_ID RETURN NUMBER
AS
BEGIN
	RETURN g_BG_LOB_ID;
END GET_BG_LOB_ID;
--------------------------------------------------------------------------------
PROCEDURE SUBMIT
	(
	p_BG_LOB_ID IN NUMBER := NULL
	) AS

v_BG_LOB_ID	NUMBER := NVL(p_BG_LOB_ID, GET_BG_LOB_ID);
v_CLOB 		CLOB;

BEGIN
	-- De-queue the clob value from the staging area
	DELETE FROM BACKGROUND_CLOB_STAGING C
	WHERE C.BACKGROUND_LOB_ID = v_BG_LOB_ID
	RETURNING C.CLOB_VAL INTO v_CLOB;

	-- PROCESS_QUEUE will insert A NULL value when there is nothing to send
	IF v_CLOB IS NOT NULL THEN
		SCHEDULE_MANAGEMENT_SYNC.SUBMIT_FILE(v_CLOB);
	END IF;

END SUBMIT;
--------------------------------------------------------------------------------
END SCHEDULE_MANAGEMENT_REACTOR;
/
