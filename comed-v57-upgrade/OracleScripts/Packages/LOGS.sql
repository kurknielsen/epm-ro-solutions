CREATE OR REPLACE PACKAGE LOGS IS

-- Author  : PMANNING
-- Created : 2/15/2008
-- Purpose : Process and Logging Procedures

FUNCTION WHAT_VERSION RETURN VARCHAR;

-- Create a new process. If p_Event_Level is NULL then the current log
-- level will be left unchanged. Otherwise, it will be changed, and then reverted whe
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
  p_TRACE_ON       IN NUMBER := NULL
  );

-- Target parameter information can be added using this method instead of providing
-- information via a map to the above procedure
PROCEDURE SET_PROCESS_TARGET_PARAMETER
  (
  p_TARGET_PARAMETER_NAME IN VARCHAR2,
  p_TARGET_PARAMETER_VAL  IN VARCHAR2
  );

-- Gets information about the current process for the current session.
FUNCTION CURRENT_PROCESS_ID RETURN NUMBER;
FUNCTION CURRENT_PROCESS_NAME RETURN VARCHAR2;

-- Gets information about the current process for the current session for auditing.
FUNCTION CURRENT_AUDIT_PROCESS_ID RETURN NUMBER;

PROCEDURE INIT_PROCESS_PROGRESS
  (
  p_PROGRESS_DESCRIPTION IN VARCHAR2 := 'Processing...',
  p_TOTAL_WORK           IN NUMBER := 100, -- default to 100 if set to null
  p_WORK_UNITS           IN VARCHAR2 := 'Steps',
  p_CAN_TERMINATE        IN BOOLEAN := FALSE
  );

-- pushes a single range onto the stack
FUNCTION PUSH_PROGRESS_RANGE(p_MAX_VALUE IN NUMBER) RETURN PLS_INTEGER;

-- the range at the top of the stack is popped. this effectively marks the
-- current range as complete. an exception will be raised if there is no range
-- to pop. if a range index is specified, that index – and all other ranges
-- above it in the stack – will be popped. otherwise, the top element in the
-- stack is popped.
PROCEDURE POP_PROGRESS_RANGE(p_RANGE IN PLS_INTEGER := -1);

-- Updates progress with the amount specified by the p_Progress_Value parameter.
-- This procedure will update the Process_Log table and also update the global progress stack.
--
-- %param p_PROGRESS_VALUE - Progress value that will be set for the current progress range or the range
--  specified by the p_Range_Index. If you are only interested in updating the Progress_Desc then you
--  can leave this parameter blank.
-- %param p_PROGRESS_DESCRIPTION - Updates the corresponding column in the Process_Log table.
-- %param p_RANGE_INDEX - The procedure will ensure that the specified range_index will be used to update
--  the progress stack. If the specified range is not at the top of the stack, then
--  all ranges above it will be 'popped' off the stack first.
--
-- %raises MSGCODES.c_ERR_ASSERT - When the Progress_Stack fails validation. Either no progress record or range for the current Process_Id.
-- %raises MSGCODES.c_ERR_CANCELLED - When the process is setup with CAN_TERMINATE = TRUE and the user has set the WAS_TERMINATED flag.
--
-- %see Increment_Process_Progress (similar)
-- %see Put_Process_Progress (private, called in order to update the Process_Log table)
PROCEDURE UPDATE_PROCESS_PROGRESS
  (
  p_PROGRESS_VALUE       IN NUMBER,
  p_PROGRESS_DESCRIPTION IN VARCHAR2 := NULL,
  p_RANGE_INDEX          IN PLS_INTEGER := -1
  );

-- Increments the progress by the amount specified in the p_Progress_Add parameter.
-- By default this procedure increments the progress range by 1 unit.
-- This procedure will update the Process_Log table and also update the global progress stack.
--
-- %param p_PROGRESS_ADD - Optional parameter that allows the user to specify the number of units to increment.
-- %param p_PROGRESS_DESCRIPTION - Updates the corresponding column in the Process_Log table.
-- %param p_RANGE_INDEX - The procedure will ensure that the specified range_index will be used to update
--  the progress stack. If the specified range is not at the top of the stack, then
--  all ranges above it will be 'popped' off the stack first.
--
-- %raises MSGCODES.c_ERR_ASSERT - When the Progress_Stack fails validation. Either no progress record or range for the current Process_Id.
-- %raises MSGCODES.c_ERR_CANCELLED - When the process is setup with CAN_TERMINATE = TRUE and the user has set the WAS_TERMINATED flag.
--
-- %see Update_Process_Progress (similar)
-- %see Put_Process_Progress (private, called in order to update the Process_Log table)
PROCEDURE INCREMENT_PROCESS_PROGRESS
  (
  p_PROGRESS_ADD         IN NUMBER := 1,
  p_PROGRESS_DESCRIPTION IN VARCHAR2 := NULL,
  p_RANGE_INDEX          IN PLS_INTEGER := -1
  );

-- Return true if the current process was terminated/cancelled by the user from the UI.
-- This function does not actually query for the state of the process. Instead, updating
-- the process progress via either of the above two methods will query for the state. So
-- the most frequently a process can check to see if a user cancelled it is as frequently
-- as it updates its progress – no more.
FUNCTION WAS_TERMINATED RETURN BOOLEAN;

-- This returns the severity code for the process id specified.
-- If the process_id is null then the current_process_id is used. The severity code is determined as the
-- event level for the most severe event logged. If the only events logged are for a
-- severity of Info or lower (like Debug) then this returns zero.
FUNCTION GET_PROCESS_SEVERITY(p_PROCESS_ID IN NUMBER := NULL) RETURN NUMBER;

-- Determines the number of messages logged for this process. These functions return the
-- counts in NUM_FATALS, NUM_ERRORS, NUM_WARNINGS, and NUM_NOTICES fields.
FUNCTION GET_FATAL_COUNT RETURN NUMBER;
FUNCTION GET_ERROR_COUNT RETURN NUMBER;
FUNCTION GET_WARNING_COUNT RETURN NUMBER;
FUNCTION GET_NOTICE_COUNT RETURN NUMBER;

-- Gets the finish message for the process if it were to end right now.  This procedure does
-- not do anything to actually stop the process.
FUNCTION GET_FINISH_MESSAGE RETURN VARCHAR2;

-- Stops the current process. If p_PROCESS_STATUS is null then the process status will be
-- determined based on the most severe log event recorded (so NUM_FATALS, NUM_ERRORS,
-- NUM_WARNINGS, and NUM_NOTICES will be examined). Similarly, if p_FINISH_TEXT is null
-- then the process finish text will be generated based on its status. If p_ALERT_TRIGGER
-- is NULL then the finish message is used as the trigger. The alert message body will be
-- the finish text.
PROCEDURE STOP_PROCESS
  (
  p_FINISH_TEXT    IN OUT VARCHAR2,
  p_PROCESS_STATUS IN OUT NUMBER,
  p_SQLCODE        IN NUMBER := 0,
  p_SQLERRM        IN VARCHAR2 := NULL,
  p_ALERT_TRIGGER  IN VARCHAR2 := NULL
  );

-- Helper methods to potentially make logging more readable. Note that there is no
-- method for fatal, error, warn, and notice because it is recommended that application
-- code always log those events - even if the current log-level would discard the event.
-- This is because the API will use that invocation has a hint to the process status.
-- Example: if LOG_ERROR were called but the event discard (due to a log-level set to
-- fatal) it would still record the process status as error, even though the event was
-- never recorded.
FUNCTION IS_INFO_ENABLED RETURN BOOLEAN;
FUNCTION IS_INFO_DETAIL_ENABLED RETURN BOOLEAN;
FUNCTION IS_INFO_MORE_DETAIL_ENABLED RETURN BOOLEAN;
FUNCTION IS_DEBUG_ENABLED RETURN BOOLEAN;
FUNCTION IS_DEBUG_DETAIL_ENABLED RETURN BOOLEAN;
FUNCTION IS_DEBUG_MORE_DETAIL_ENABLED RETURN BOOLEAN;

-- The following methods are the preferred methods for logging events. The generic
-- Log_Event and Log_Trace methods below should be used sparingly. Note that for all
-- log procedures below, if p_MESSAGE_CODE is non-NULL then the p_EVENT_TEXT will be
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
  );

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
  );

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
  );

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
  );

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
  );
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
  );
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
  );

-- Debug messages. These messages will go into the trace tables. If p_Persist_Trace is
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
  );
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
  );

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
  );

-- Current log level?
FUNCTION CURRENT_LOG_LEVEL RETURN PLS_INTEGER;
PROCEDURE SET_CURRENT_LOG_LEVEL(p_LEVEL IN PLS_INTEGER);

-- Are we persisting attachments to events?
FUNCTION KEEPING_EVENT_DETAILS RETURN BOOLEAN;
PROCEDURE SET_KEEPING_EVENT_DETAILS(p_KEEP_THEM IN BOOLEAN);

-- Are we persisting trace messages?
FUNCTION PERSISTING_TRACE RETURN BOOLEAN;
PROCEDURE SET_PERSISTING_TRACE(p_PERSIST IN BOOLEAN);

-- For testing progress reporting - should only be used from test windows...
PROCEDURE SET_PROGRESS_TRACKER
  (
  p_ENABLED IN BOOLEAN := TRUE,
  p_POLL_FREQ IN NUMBER := NULL, -- default: measure progress every 1/100th of a second
  p_WAIT_LIMIT IN NUMBER := NULL, -- default: delay up to 10 seconds for tracker job to start
  p_COMPRESS IN BOOLEAN := NULL -- default: Yes - only record progress measurements when changes
  );

-- The progress tracker. Should generally only be called from inside the LOGS package.
-- Used for testing progress reporting for a process.
PROCEDURE PROGRESS_TRACKER
  (
  p_PROCESS_ID   IN NUMBER,
  p_DELAY_SECS  IN NUMBER := 0.01, -- measure progress every 1/100th of a second
  p_COMPRESS    IN BOOLEAN := TRUE  -- compress results - discard redundant measurements
  );

-- What was the ID for the last event posted by this session. This returns NULL if the
-- last event was discarded due to the current log level
FUNCTION LAST_EVENT_ID RETURN NUMBER;

-- Adds details/attachment to an event. If p_EVENT_ID is null then the details will be
-- posted to the last event posted by this session, using Last_Event_Id above. If
-- Last_Event_Id returns null, details are discarded.
PROCEDURE POST_EVENT_DETAILS
  (
  p_DETAIL_TYPE  IN VARCHAR2,
  p_CONTENT_TYPE IN VARCHAR2,
  p_CONTENTS     IN CLOB,
  p_EVENT_ID     IN NUMBER := NULL
  );

-- Generic logging procedures - the event level is a parameter to these methods
FUNCTION IS_LEVEL_ENABLED(p_EVENT_LEVEL IN PLS_INTEGER) RETURN BOOLEAN;

-- Generic Logging procedure that takes 2 additional parameters: p_Event_Level and p_Persist_Trace.
-- If p_Event_Level > Debug then the log event will go to the Process_Log_Event table.
-- If p_Event_Level <= Debug then the procedure will look at the p_Persist_Trace parameter to determine
--  whether the log event will go to the PROCESS_LOG_TRACE or the PROCESS_LOG_TEMP_TRACE tables.
-- When the p_Persist_Trace parameter is null, this procedure will use the value from the Current_Session table.
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
  );

-- When a MSGCODES.e_ERR_COULD_NOT_START_PROCESS is thrown by START_PROCESS, this will
-- get the original exception that prevented the process from being created. This is
-- NOT intended for general use. It is intended only for use from the ERRS API.
PROCEDURE GET_SOURCE_OF_START_FAILURE
  (
  p_SQLCODE OUT NUMBER,
  p_SQLERRM OUT VARCHAR2
  );

-- Helper method to retrieve the name and line number of the calling routine. This will
-- be used when p_Procedure_Name and p_Step_Name are NULL to the various log routines
-- above. It is also public to allow other logic to take advantage of this capability.
PROCEDURE GET_CALLER
  (
  p_OBJECT_NAME   OUT VARCHAR2,
  p_LINE_NUMBER    OUT PLS_INTEGER,
  p_HOW_FAR_BACK   IN PLS_INTEGER := 1
  );
-- This version will format the object name and line number so they make proper values
-- for the procedure and step name fields in a log event
PROCEDURE GET_CALLER
  (
  p_PROCEDURE_NAME OUT VARCHAR2,
  p_STEP_NAME       OUT VARCHAR2,
  p_HOW_FAR_BACK   IN PLS_INTEGER := 1
  );

-- Clean-up abandoned processes – either for this session only, or system-wide
PROCEDURE CLEANUP_ABANDONED_PROCESSES(p_THIS_SESSION_ONLY IN BOOLEAN);

-- Clean-up expired log events – for a specified process or for all of them
PROCEDURE CLEANUP_EXPIRED_EVENTS(p_PROCESS_ID IN NUMBER := NULL);

-- Wrapper procedure that starts a new Process and calls CLEANUP_EXPIRED_EVENTS and CLEANUP_ABANDONED_PROCESSES for all processes
PROCEDURE RUN_CLEANUP
  (
  p_TRACE_ON IN NUMBER := 0,
  p_MESSAGE OUT VARCHAR2,
  p_PROCESS_STATUS OUT NUMBER
  );

--Gracefully end the last process of a parallel child session.
PROCEDURE FINISH_PARALLEL_CHILD_PROCESS;

-- Constants for p_Event_Level parameter above
c_LEVEL_FATAL             CONSTANT NUMBER(3) := 999;
c_LEVEL_ERROR             CONSTANT NUMBER(3) := 900;
c_LEVEL_WARN              CONSTANT NUMBER(3) := 800;
c_LEVEL_NOTICE            CONSTANT NUMBER(3) := 700;
c_LEVEL_INFO              CONSTANT NUMBER(3) := 600;
c_LEVEL_INFO_DETAIL       CONSTANT NUMBER(3) := 500;
c_LEVEL_INFO_MORE_DETAIL  CONSTANT NUMBER(3) := 400;
c_LEVEL_DEBUG             CONSTANT NUMBER(3) := 300;
c_LEVEL_DEBUG_DETAIL      CONSTANT NUMBER(3) := 200;
c_LEVEL_DEBUG_MORE_DETAIL CONSTANT NUMBER(3) := 100;

c_LEVEL_ALL          CONSTANT NUMBER(3) := 0; -- Only used with SET_CURRENT_LOG_LEVEL to capture all events
c_LEVEL_SUCCESS           CONSTANT NUMBER(3) := 0; -- Only used for process status, not for events

c_PROCESS_TYPE_USER_SESSION   CONSTANT VARCHAR(12) := 'User Session';
c_PROCESS_TYPE_BACKGROUND_JOB CONSTANT VARCHAR(3) := 'Job';
c_PROCESS_TYPE_PROCESS        CONSTANT VARCHAR(7) := 'Process';
c_PROCESS_TYPE_CHILD          CONSTANT VARCHAR(16) := 'Child Session';

c_TARGET_PARAM_BEGIN_DATE CONSTANT VARCHAR(10) := 'BEGIN_DATE';
c_TARGET_PARAM_END_DATE   CONSTANT VARCHAR(8) := 'END_DATE';

$IF $$UNIT_TEST_MODE = 1 $THEN

FUNCTION GET_CURRENT_SESSION_PROCESS_ID RETURN NUMBER;

$END

-- Error messages
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
  );

END LOGS;
/
