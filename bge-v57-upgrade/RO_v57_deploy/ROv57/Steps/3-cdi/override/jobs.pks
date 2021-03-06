CREATE OR REPLACE PACKAGE JOBS IS
--Revision $Revision: 1.4 $

  -- Author  : MWEATHERS
  -- Created : 5/27/2008
  -- Purpose : Package to support interaction with DBMS_SCHEDULER from the Java UI

FUNCTION WHAT_VERSION RETURN VARCHAR;

-- Helper function for translating dates from the Jobs tables to a date relative
-- to the client clock.
FUNCTION GET_LOCAL_DATE_FOR_JOB
	(
	p_JOB_DATE IN TIMESTAMP WITH TIME ZONE,
	p_CLIENT_CLOCK IN DATE
	) RETURN DATE;

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
	) RETURN VARCHAR2;

-- Stage a CLOB to the BACKGROUND_CLOB_STAGING table from the Java UI
-- and return its ID so that it can be used when a background job executes.
FUNCTION STAGE_CLOB
	(
	p_LOB IN CLOB
	) RETURN NUMBER;

-- Stage a BLOB to the BACKGROUND_BLOB_STAGING table from the Java UI
-- and return its ID so that it can be used when a background job executes.
FUNCTION STAGE_BLOB
	(
	p_LOB IN BLOB
	) RETURN NUMBER;

-- Return the number of jobs scheduled by the current user that are in the queue.
FUNCTION NUM_JOBS_IN_QUEUE_FOR_ME RETURN NUMBER;

-- Master grid procedure for the Background Job Status screen
PROCEDURE GET_JOB_STATUS_SUMMARY
	(
	p_CLIENT_CLOCK IN DATE,
	p_SEE_ALL_JOBS IN NUMBER,
	p_INCLUDE_LOG IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Detail grid procedure for the Background Job Status screen
PROCEDURE GET_JOB_STATUS_DETAIL
	(
	p_ACTION_CHAIN_NAME IN VARCHAR2,
	p_CLIENT_CLOCK IN DATE,
	p_SEE_ALL_JOBS IN NUMBER,
	p_INCLUDE_LOG IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Put Procedure for Detail grid of Background Job Status screen
PROCEDURE PUT_JOB_STATUS_DETAIL
	(
	p_JOB_NAME IN VARCHAR2,
	p_START_DATE IN DATE,
	p_CLIENT_CLOCK IN DATE
	);

-- Put Procedure for Detail grid of Background Job Status screen -- drops the specified job.
PROCEDURE DEL_JOB_STATUS_DETAIL
	(
	p_JOB_NAME IN VARCHAR2
	);

-- Enable job from Detail grid of Background Job Status screen
PROCEDURE ENABLE_JOB
	(
	p_JOB_NAME IN VARCHAR2
	);

-- Disable job from Detail grid of Background Job Status screen
PROCEDURE DISABLE_JOB
	(
	p_JOB_NAME IN VARCHAR2
	);

PROCEDURE ENQUEUE_BY_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_PLSQL IN VARCHAR2,
	p_COMMENTS IN VARCHAR2 := NULL,
	p_NOTIFICATION_EMAIL_ADDRESS IN VARCHAR2 := NULL
	);

PROCEDURE DEQUEUE_BY_JOB_THREAD
	(
	p_JOB_THREAD_ID IN NUMBER
	);

PROCEDURE GET_JOB_THREAD_STATUS_SUMMARY
	(
	p_CURSOR OUT GA.REFCURSOR
	);

PROCEDURE GET_JOB_THREAD_STATUS_DETAIL
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_CLIENT_CLOCK IN DATE,
	p_CURSOR OUT GA.REFCURSOR
	);

PROCEDURE PUT_JOB_THREAD_STATUS_DETAIL

	(
	p_JOB_QUEUE_ITEM_ID IN NUMBER,
	p_ITEM_ORDER IN NUMBER,
	p_MESSAGE OUT VARCHAR
	);

PROCEDURE DEL_JOB_THREAD_STATUS_DETAIL
	(
	p_JOB_QUEUE_ITEM_ID IN NUMBER,
	p_MESSAGE OUT VARCHAR
	);

PROCEDURE PUT_JOB_THREAD_STATUS_SUMMARY
	(
	p_JOB_THREAD_ID IN NUMBER,
	p_IS_SNOOZED IN NUMBER
	);

PROCEDURE PURGE_ALL_JOB_QUEUE_ITEMS
	(
	p_JOB_THREAD_ID IN NUMBER
	);

PROCEDURE GET_PROGRAM_PARAMETERS
	(
	p_JOB_NAME IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	);

PROCEDURE PUT_PROGRAM_PARAMETERS
	(
	p_JOB_NAME IN VARCHAR2,
	p_ARGUMENT_NAME IN VARCHAR2,
	p_VALUE IN VARCHAR2
	);

--@@Begin Implementation Override --
--@@Allow The User To Run The Job Now --
PROCEDURE RUN_JOB(p_JOB_NAME IN VARCHAR2, p_MESSAGE OUT VARCHAR2);
--@@End Implementation Override --

END JOBS;
/

