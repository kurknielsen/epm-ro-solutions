CREATE OR REPLACE PACKAGE MM_TDIE_IMPORTS IS
--------------------------------------------------------------------------------
-- Created : 09/28/2009 15:25
-- Purpose : Download Market Messages
-- $Revision: 1.51 $
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- This function is used to calculate the interval dates for a .CSV file given
-- the header date and the interval offset.
-- RETURNS a date in CUT DATE
-- Also assumes since there is no timezone specified within the file that the
-- date is given in GMT.
FUNCTION GET_CSV_FILE_SCHEDULE_DATE(
   p_MSG_SCHEDULE_DATE     IN DATE,
   p_MSG_INTERVAL_POSITION IN NUMBER
   ) RETURN DATE;
PRAGMA RESTRICT_REFERENCES(GET_CSV_FILE_SCHEDULE_DATE, WNDS, TRUST);

--------------------------------------------------------------------------------
-- Standard function to return the version of the package.
FUNCTION WHAT_VERSION RETURN VARCHAR;

--------------------------------------------------------------------------------
-- Simple pass through to the private IMPORT routine with p_FROM_SEM defaulted to zero.
PROCEDURE IMPORT
   (
   p_IMPORT_FILE		   IN CLOB,
   p_IMPORT_FILE_PATH	IN VARCHAR2,
   p_TRACE_ON		    	IN NUMBER,
   p_PROCESS_IMPORT		IN NUMBER DEFAULT 1,
   p_PROCESS_ID			OUT VARCHAR2,
   p_PROCESS_STATUS   	OUT NUMBER,
   p_MESSAGE          	OUT VARCHAR2
   );
--------------------------------------------------------------------------------
-- Simple pass through to the private IMPORT routine with p_FROM_SEM defaulted to one.
PROCEDURE IMPORT_CSV_NIE59X_SEM
   (
   p_IMPORT_FILE		   IN CLOB,
   p_IMPORT_FILE_PATH	IN VARCHAR2,
   p_TRACE_ON		    	IN NUMBER,
   p_PROCESS_IMPORT		IN NUMBER DEFAULT 1,
   p_PROCESS_ID			OUT VARCHAR2,
   p_PROCESS_STATUS   	OUT NUMBER,
   p_MESSAGE          	OUT VARCHAR2
   );
--------------------------------------------------------------------------------
-- This procedure is used for handling a batch import of TDIE Message files.
-- This procedure fetches files from the MEX MessageQueue with category = TDIEImport.
PROCEDURE FETCH_IMPORT_FILES
   (
   p_TRACE_ON 		IN NUMBER,
   p_PROCESS_ID		OUT VARCHAR2,
   p_PROCESS_STATUS	OUT NUMBER,
   p_MESSAGE        OUT VARCHAR2
   );

--------------------------------------------------------------------------------
PROCEDURE PROCESS_598
	(
	p_TDIE_ID    IN NUMBER
	);

--------------------------------------------------------------------------------
PROCEDURE PROCESS_596
	(
	p_TDIE_ID    IN NUMBER
	);

--------------------------------------------------------------------------------
PROCEDURE PROCESS_NIE_NET_DEMAND
   (
	p_RECIPIENT_ID             IN VARCHAR2,
	p_BEGIN_DATE               IN DATE,
	p_END_DATE                 IN DATE,
	p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2,
   p_FROM_SEM      	         IN NUMBER DEFAULT 0
   );

--------------------------------------------------------------------------------
PROCEDURE PROCESS_NIE_GENERATION
   (
	p_RECIPIENT_ID             IN VARCHAR2,
	p_BEGIN_DATE               IN DATE,
	p_END_DATE                 IN DATE,
	p_SETTLEMENT_RUN_INDICATOR IN VARCHAR2
   );

--------------------------------------------------------------------------------
PROCEDURE PROCESS_300(p_TDIE_ID IN NUMBER);

--------------------------------------------------------------------------------
PROCEDURE PROCESS_34X_MPRN
	(
	p_TDIE_MPRN_MSG_ID IN NUMBER
	);

--------------------------------------------------------------------------------
FUNCTION GET_EARN_SERVICE_POINT_ID(
   p_UNIT_ID      IN VARCHAR2,
   p_IS_NIE       IN BOOLEAN,
   p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
   ) RETURN NUMBER;

FUNCTION GET_EARN_TRANSACTION_ID(
   p_SERVICE_POINT_ID    IN NUMBER,
   p_IS_NIE      		 IN BOOLEAN,
   p_TRANSACTION_NAME	 IN VARCHAR2,
   p_TRANSACTION_IDENTIFIER IN VARCHAR2,
   p_MESSAGE_DATE		 IN DATE := SYSDATE,
   p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
   ) RETURN NUMBER;

FUNCTION GET_EARN_TRANSACTION_ID(
   p_UNIT_ID      IN VARCHAR2,
   p_IS_NIE       IN BOOLEAN,
   p_MESSAGE_DATE		 IN DATE,
   p_CREATE_IF_NOT_FOUND IN BOOLEAN := TRUE
   ) RETURN NUMBER;

FUNCTION GET_300_XML_MPRN_NODE_NAME
	(
    p_MESSAGE_CODE_TYPE IN VARCHAR2,
    p_VERSION_UPDATED 	IN NUMBER
	) RETURN VARCHAR2;

PROCEDURE GET_VALIDATION_DATE_RANGE
    (
    p_PREVIOUS_READ_DATE IN DATE,
    p_READ_OR_MSG_DATE IN DATE,
    p_BEGIN_DATE OUT DATE,
    p_END_DATE OUT DATE
    );


FUNCTION IS_NI_HARMONISATION_VERSION
(
	p_VERSION_NUMBER 	IN VARCHAR2,
	p_MESSAGE_TYPE_CODE IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER;

FUNCTION GET_JURISDICTION_FOR_IMPORTS (p_RECIPIENT_CID IN VARCHAR2) RETURN VARCHAR2;

-- THESE METHODS ARE ONLY BEING MADE PUBLIC FOR THE UNIT TESTS, BUT THEY SHOULD BE
-- MADE TO CONDITIONALLY COMPILE IN THE FUTURE
$IF $$UNIT_TEST_MODE = 1 $THEN

-- CSV File Message Header Type
TYPE t_NIE_HEADER IS RECORD(
   TITLE             VARCHAR2(218),
   SUPPLIER_ID       VARCHAR2(3),
   SETTLEMENT_DATE   DATE,
   SETTLEMENT_TYPE   VARCHAR2(4),
   AGGREGATION_TYPE  VARCHAR2(8),
   RUN_VERSION       NUMBER(9),
   REPORT_DATE       DATE);


FUNCTION GET_METER_ID
    (
    p_SERVICE_LOCATION_ID IN NUMBER,
    p_SERIAL_NUMBER IN VARCHAR2,
    p_TIMESLOT_CODE IN VARCHAR2,
    p_BEGIN_DATE IN DATE,
    p_END_DATE IN DATE
    ) RETURN NUMBER;

PROCEDURE GET_MPRN
    (
    p_TDIE_ID IN NUMBER,
    p_ACCOUNT_ID OUT NUMBER,
    p_SERVICE_LOCATION_ID OUT NUMBER
    );

PROCEDURE IMPORT_CSV_NIE59X
   (
   p_MESSAGE_HEADER  IN t_NIE_HEADER,
   p_IMPORT_FILE     IN CLOB,
   p_PROCESS_IMPORT  IN NUMBER,
   p_FROM_SEM      	IN NUMBER DEFAULT 0
   );

FUNCTION GET_CSV_MSG_HEADER
   (
   p_IMPORT_FILE IN CLOB
   )
   RETURN t_NIE_HEADER;

$END


END MM_TDIE_IMPORTS;
/