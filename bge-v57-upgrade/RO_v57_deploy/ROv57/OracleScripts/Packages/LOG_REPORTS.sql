CREATE OR REPLACE PACKAGE LOG_REPORTS IS
-- $Revision: 1.10 $

-- Author  : AHUSSAIN
-- Created : 1/28/2008 2:41:33 PM
-- Purpose : Process Log report

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- Query for distinct process names where process start/stop date overlap the specified
-- begin and end dates.
PROCEDURE GET_PROCESS_NAMES
	(
	p_BEGIN_DATE        IN DATE,
	p_END_DATE          IN DATE,
	p_INCLUDE_SESSIONS  IN NUMBER,
	p_PROCESS_NAME_TEXT IN VARCHAR2,
	p_CURSOR            OUT GA.REFCURSOR
	);

-- Gather list of user-names, including an <ALL> entry. If current user does not have
-- permission to view processes for all users, then the list will contain only a single
-- entry representing the current user only.
PROCEDURE GET_USER_LIST(p_CURSOR OUT GA.REFCURSOR);

-- Get summary grid of processes. If the current user does not have permission to view
-- session information (last few fields in the PROCESSES table) then those columns in the
-- cursor will be null. This routine must further validate the p_PROCESS_OWNER input to
-- make sure that, even if another user or <ALL> is specified, that the only the user's
-- processes are returned in the event that the current user does not have permission to
-- view all processes.
PROCEDURE GET_PROCESSES
	(
	p_BEGIN_DATE          IN DATE,
	p_END_DATE            IN DATE,
	p_INCLUDE_SESSIONS    IN NUMBER,
	p_PROCESS_NAME_FILTER IN VARCHAR2,
	p_PROCESS_OWNER_ID    IN NUMBER,
	p_PROCESS_STATE       IN VARCHAR2,
	p_CURSOR              OUT GA.REFCURSOR
	);

FUNCTION GET_SOURCE_STRING
	(
	p_SOURCE_NAME		IN PROCESS_LOG_EVENT.SOURCE_NAME%TYPE,
	p_SOURCE_DOMAIN_ID	IN PROCESS_LOG_EVENT.SOURCE_DOMAIN_ID%TYPE,
	p_SOURCE_ENTITY_ID	IN PROCESS_LOG_EVENT.SOURCE_ENTITY_ID%TYPE,
	p_SOURCE_DATE		IN PROCESS_LOG_EVENT.SOURCE_DATE%TYPE
	) RETURN VARCHAR2;

-- Get detail grid with process events. This grid must validate the p_PROCESS_ID input
-- if it indicates a process owner by another user, but the current user does not have
-- permission to view all processes, then return an empty cursor.
-- This table will need to do a UNION ALL from PROCESS_EVENTS, PROCESS_TRACE and
-- PROCESS_TEMP_TRACE to get all data and then it will need to order by
-- EVENT_TIMESTAMP and EVENT_ID to interleave records from these three sources correctly.
-- The routine should fetch all records where EVENT_LEVEL >= p_LOG_LEVEL
PROCEDURE GET_PROCESS_EVENTS
	(
	p_PROCESS_ID   IN VARCHAR2,
	p_LOG_LEVEL_ID IN NUMBER,
	p_CURSOR       OUT GA.REFCURSOR
	);

PROCEDURE GET_PROCESS_DEBUG_EVENTS
	(
	p_PROCESS_ID IN VARCHAR2,
	p_MESSAGE    OUT VARCHAR2,
	p_CONTENTS	 OUT CLOB
	);

-- Gets the list of details associated with a log event. The p_EVENT_ID input will need
-- to be validated to make sure it belongs to a process to which the current user has
-- access.
PROCEDURE GET_EVENT_DETAILS
	(
	p_EVENT_ID IN VARCHAR2,
	p_CURSOR   OUT GA.REFCURSOR
	);

-- Gets the contents for an event attachment. The p_EVENT_ID input will need to be
-- validated to make sure it belongs to a process to which the current user has access.
PROCEDURE GET_EVENT_DETAIL_CONTENTS
	(
	p_EVENT_ID           IN VARCHAR2,
	p_DETAIL_TYPE        IN VARCHAR2,
	p_CONTENTS           OUT CLOB,
	p_CONTENTS_EXTENSION OUT VARCHAR2
	);

FUNCTION GET_EXTENSION_FOR_CONTENTTYPE(p_CONTENTTYPE IN VARCHAR2) RETURN VARCHAR2;

-- Gets the message details for a particular pre-defined message. The cursor should
-- return a ¿transposed¿ one-row grid for the message. This means it will have two
-- columns: the field name and its value. This way the message will be readable in a grid
-- (instead of having only one row that requires substantial horizontal real estate).
PROCEDURE GET_MESSAGE_DETAILS
	(
	p_MESSAGE_ID IN NUMBER,
	p_CURSOR     OUT GA.REFCURSOR
	);

-- Tuncates the real table (PROCESS_TRACE). Throw an exception if the current user does
-- not have permission to truncate persistent trace data.
PROCEDURE TRUNCATE_TRACE;

-- Truncates the global temporary table for this session (PROCESS_TEMP_TRACE)
PROCEDURE TRUNCATE_TEMP_TRACE;

-- User must own the specified process or have admin privileges. If process cannot be
-- terminated or user has insufficient privileges, an exception will be raised.
PROCEDURE TERMINATE_PROCESS(p_PROCESS_ID IN VARCHAR2);

-- Gets the list of Log Levels
PROCEDURE GET_LOG_LEVELS(p_CURSOR OUT GA.REFCURSOR);
-- Gets the list of Status Levels
PROCEDURE GET_STATUS_LEVELS(p_CURSOR OUT GA.REFCURSOR);
-- Gets the value of a target parameter named BEGIN_DATE for the specified process
FUNCTION GET_TARGET_BEGIN_DATE(p_PROCESS_ID IN NUMBER) RETURN VARCHAR2;

-- Gets the value of a target parameter named END_DATE for the specified process
FUNCTION GET_TARGET_END_DATE(p_PROCESS_ID IN NUMBER) RETURN VARCHAR2;

-- Gets the values of all target parameters other than BEGIN_DATE and END_DATE -
-- for the specified process and combines them into a semi-colon-separated string of
-- name=value pairs
FUNCTION GET_OTHER_TARGET_PARAMETERS(p_PROCESS_ID IN NUMBER) RETURN VARCHAR2;

-- Wrapper Functions/Procedures used by the UI Logging Dialog since we cannot access Boolean types via jdbc
FUNCTION CURRENT_LOG_LEVEL_UI RETURN PLS_INTEGER;
FUNCTION KEEPING_EVENT_DETAILS_UI RETURN NUMBER;
FUNCTION PERSISTING_TRACE_UI RETURN NUMBER;
PROCEDURE SET_CURRENT_LOG_LEVEL_UI(p_LEVEL IN PLS_INTEGER);
PROCEDURE SET_KEEPING_EVENT_DETAILS_UI(p_KEEP_THEM IN NUMBER);
PROCEDURE SET_PERSISTING_TRACE_UI(p_PERSIST IN NUMBER);

-- Returns a string label for the associated LOGS level
FUNCTION GET_LOG_LEVEL_STRING(p_LOG_LEVEL NUMBER) RETURN VARCHAR2;
-- Returns a string label for the associated STATUS level
FUNCTION GET_STATUS_LEVEL_STRING(p_STATUS_LEVEL NUMBER, p_WAS_TERMINATED IN NUMBER) RETURN VARCHAR2;
FUNCTION GET_STATUS_LEVEL_STRING(p_STATUS_LEVEL NUMBER) RETURN VARCHAR2;

-- Get the process finish message and possibly error message
PROCEDURE GET_PROCESS_STATUS
	(
	p_PROCESS_CID IN VARCHAR2,
	p_CONTENTS OUT VARCHAR2
	);

PROCEDURE GET_PROCESSES_BY_IDS
	(
	p_PROCESS_IDS		  IN NUMBER_COLLECTION,
	p_CURSOR              OUT GA.REFCURSOR
	);

END LOG_REPORTS;
/