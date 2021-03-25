CREATE OR REPLACE PACKAGE ERRS IS
--Revision $Revision: 1.7 $

  -- Author  : JHUMPHRIES
  -- Created : 12/21/2007 11:41:40 AM
  -- Purpose : Error Handling Procedures

-- All of the following routines should only be used in exception handlers. If you want
-- to log an error outside of an exception handler, it is advised to instead use
-- LOG.LOG_ERROR.

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- Log the current exception. If SQLERRM starts with a predefined message code, the
-- recorded log event will be associated with that message. If p_ALERT_TRIGGER is null,
-- then UT.GET_FULL_ERRM will be used as a trigger value. If a savepoint name is specified
-- then it will be used in a ‘rollback to’ operation.
PROCEDURE LOG_AND_CONTINUE
	(
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_LOG_LEVEL IN NUMBER := LOGS.c_LEVEL_ERROR,
	p_ALERT_TRIGGER IN VARCHAR2 := NULL,
	p_PROCEDURE_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL,
	p_SOURCE_NAME IN VARCHAR2 := NULL,
	p_SOURCE_DATE IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_SAVEPOINT_NAME IN VARCHAR2 := NULL
	);

-- Same as above, except the exception is re-raised after the log event is recorded.
PROCEDURE LOG_AND_RAISE
	(
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_LOG_LEVEL IN NUMBER := LOGS.c_LEVEL_ERROR,
	p_ALERT_TRIGGER IN VARCHAR2 := NULL,
	p_PROCEDURE_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL,
	p_SOURCE_NAME IN VARCHAR2 := NULL,
	p_SOURCE_DATE IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_SAVEPOINT_NAME IN VARCHAR2 := NULL
	);

-- Generally speaking, do NOT use this method. Use LOG_AND_RAISE instead. There are
-- some cases however that necessitate the ability to re-raise an exception via
-- SQLCODE and SQLERRM w/out using the LOG_AND_RAISE API above.
PROCEDURE RERAISE
	(
	p_SQLCODE IN PLS_INTEGER,
	p_SQLERRM IN VARCHAR2
	);

-- Rolls back to a savepoint. This is the same as issuing a ROLLBACK TO statement
-- except that it will also catch any subsequent exceptions (like an undefined savepoint)
-- and log and continue. Using this instead of ROLLBACK TO will improve robustness while
-- minimizing boiler-plate code. In an exception handler, code should use LOG_AND_CONTINUE
-- or LOG_AND_RAISE. But when not in an exception handler, if code needs to rollback,
-- it should use this procedure.
PROCEDURE ROLLBACK_TO
	(
	p_SAVEPOINT_NAME IN VARCHAR2
	);

-- This method calls LOG_AND_CONTINUE with a FATAL level, then it calls LOGS.STOP_PROCESS
-- to end the current process, and finally it re-raises the exception.
PROCEDURE ABORT_PROCESS(
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_ALERT_TRIGGER IN VARCHAR2 := NULL,
	p_PROCEDURE_NAME IN VARCHAR2 := NULL,
	p_STEP_NAME IN VARCHAR2 := NULL,
	p_SOURCE_NAME IN VARCHAR2 := NULL,
	p_SOURCE_DATE IN DATE := NULL,
	p_SOURCE_DOMAIN_ID IN NUMBER := NULL,
	p_SOURCE_ENTITY_ID IN NUMBER := NULL,
	p_SAVEPOINT_NAME IN VARCHAR2 := NULL
	);


-- Raises an exception. If the message code is in the format ‘ORA-XXXXX’ then an
-- exception with the specified SQLCODE (the ‘XXXXX’ in the message code) will be raised.
-- Otherwise, a SQLCODE of -20,000 will be used. Note that this will use
-- RAISE_APPLICATION_ERROR, so if a SQLCODE is specified that is outside the range of
-- -20,000 to -20,999 then -21,000 will be used instead. If specified to keep the
-- exception source then the SQLERRM of the resulting exception will include a
-- reference to the current one (if this method is called from within an exception
-- handler)
PROCEDURE RAISE
	(
	p_MESSAGE_CODE IN VARCHAR2,
	p_EXTRA_MESSAGE IN VARCHAR2 := NULL,
	p_KEEP_EXCEPTION_SOURCE IN BOOLEAN := FALSE
	);

-- Utility function for extracting message code from a SQLERRM message
-- (if applicable)
FUNCTION GET_MESSAGE_CODE
	(
	p_SQLERRM IN VARCHAR2
	) RETURN VARCHAR2;
	

-- Helper methods for constructing consistent message text for frequently used errors:

-- These raise MSGCODES.c_ERR_PRIVILEGES

-- These methods are for throwing exceptions after using CAN_READ, CAN_WRITE, or
-- CAN_DELETE to validate module-level security.
PROCEDURE RAISE_NO_READ_MODULE
	(
	p_MODULE_NAME IN VARCHAR2
	);
PROCEDURE RAISE_NO_WRITE_MODULE
	(
	p_MODULE_NAME IN VARCHAR2
	);
PROCEDURE RAISE_NO_DELETE_MODULE
	(
	p_MODULE_NAME IN VARCHAR2
	);

-- These methods are for throwing exceptions after using SD package to validate
-- data-level security
PROCEDURE RAISE_NO_PRIVILEGE_ACTION
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER := NULL,
	p_ENTITY_ID IN NUMBER := NULL
	);

-- This raises MSGCODES.c_ERR_ARGUMENT

PROCEDURE RAISE_BAD_ARGUMENT
	(
	p_ARGUMENT_NAME IN VARCHAR2,
	p_ARGUMENT_VALUE IN VARCHAR2,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	);

-- This raises MSGCODES.c_ERR_INVALID_DATE

PROCEDURE RAISE_BAD_DATE
	(
	p_DATE_STRING IN VARCHAR2,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	);

-- This raises MSGCODES.c_ERR_DATE_RANGE

PROCEDURE RAISE_BAD_DATE_RANGE
	(
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	);


-- This raises MSGCODES.c_ERR_DATES_OVERLAP

PROCEDURE RAISE_OVERLAPPING_DATES
	(
	p_BEGIN_DATE1 IN DATE,
	p_END_DATE1 IN DATE,
	p_BEGIN_DATE2 IN DATE,
	p_END_DATE2 IN DATE,
	p_ADDITIONAL_INFO IN VARCHAR2 := NULL
	);

-- This raises MSGCODES.c_ERR_BUS_RULE

PROCEDURE RAISE_BUSINESS_RULE_ERROR
	(
	p_BUSINESS_RULE IN VARCHAR2
	);

-- This helper methods raise MSGCODES.c_ERR_ASSERT and should only be used after calling
-- legacy API routines that set a p_STATUS (and optionally p_MESSAGE) instead of raising
-- exceptions. The p_PROCEDURE_NAME parameter should be the name of the API that returned
-- this status. An exception will only be raised when p_STATUS is non-zero.

PROCEDURE VALIDATE_STATUS
	(
	p_PROCEDURE_NAME IN VARCHAR2,
	p_STATUS IN NUMBER,
	p_MESSAGE IN VARCHAR2 := NULL
	);

-- This procedure is the same as the one above, except that it validates that the
-- specified error message is NULL. If non-null, an exception is raised.

PROCEDURE VALIDATE_ERROR_MESSAGE
	(
	p_PROCEDURE_NAME IN VARCHAR2,
	p_ERROR_MESSAGE IN VARCHAR2
	);

  e_TABLE_IS_MUTATING EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_TABLE_IS_MUTATING, -4091);

  e_INVALID_SAVEPOINT EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_INVALID_SAVEPOINT, -1086);

  e_INVALID_DATE EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_INVALID_DATE, -1848);

  e_INVALID_SESSION_ID EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_INVALID_SESSION_ID, -1848);
  
  e_NUM_VALUE_ERR EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_NUM_VALUE_ERR, -6502);

  -- COMPILE ERROR IN DYNAMIC PLSQL
  e_COMPILE_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_COMPILE_ERROR, -6550);
  
  e_CHILD_RECORD_FOUND EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_CHILD_RECORD_FOUND, -2292);
  
END ERRS;
/
