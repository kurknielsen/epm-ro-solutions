CREATE OR REPLACE TYPE MEX_LOGGER AS OBJECT
(
-- This object is really like an "interface" - we only care about the methods it provides.
-- But to keep the compiler happy - we must have at least one attribute
DUMMY	NUMBER,

-- These methods will be called by MEX_SWITCHBOARD package to record log events.
-- Caller can pass NULL logger to skip logging, but caller can also provide a sub-class
-- of MEX_LOGGER that overrides all of these to perform app-specific logging.

-- The default implementations in this object do nothing - all log events are ignored.

MEMBER PROCEDURE LOG_START ( p_MARKET IN VARCHAR2, p_ACTION IN VARCHAR2 ),
MEMBER PROCEDURE LOG_ERROR ( p_MESSAGE IN VARCHAR2 ),
MEMBER PROCEDURE LOG_WARN ( p_MESSAGE IN VARCHAR2 ),
MEMBER PROCEDURE LOG_INFO ( p_MESSAGE IN VARCHAR2 ),
MEMBER PROCEDURE LOG_REQUEST ( p_REQUEST_HEADERS IN CLOB , 
								p_REQUEST_BODY IN CLOB , 
								p_BODY_CONTENT_TYPE IN VARCHAR2 ),
MEMBER PROCEDURE LOG_RESPONSE ( p_RESPONSE_HEADERS IN CLOB ,
								p_RESPONSE_BODY IN CLOB ,
								p_BODY_CONTENT_TYPE IN VARCHAR2 ),
MEMBER PROCEDURE LOG_ATTACHMENT ( p_DESCRIPTION IN VARCHAR2,
                                  p_ATTACHMENT_TYPE IN VARCHAR2,
                                  p_ATTACHMENT IN CLOB ),
MEMBER PROCEDURE LOG_DEBUG ( p_MESSAGE IN VARCHAR2 ),
MEMBER PROCEDURE LOG_STOP ( p_RESULT IN MEX_RESULT ),

-- no-arg constructor
CONSTRUCTOR FUNCTION MEX_LOGGER RETURN SELF AS RESULT
)
NOT FINAL;
/
CREATE OR REPLACE TYPE BODY MEX_LOGGER IS
-----------------------------------------------------------------------------
-- all methods do nothing - sub-class and override to perform real logging
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_START ( p_MARKET IN VARCHAR2, p_ACTION IN VARCHAR2 ) AS
BEGIN
	NULL;
END LOG_START;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_ERROR ( p_MESSAGE IN VARCHAR2 ) AS
BEGIN
	NULL;
END LOG_ERROR;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_WARN ( p_MESSAGE IN VARCHAR2 ) AS
BEGIN
	NULL;
END LOG_WARN;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_INFO ( p_MESSAGE IN VARCHAR2 ) AS
BEGIN
	NULL;
END LOG_INFO;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_REQUEST ( p_REQUEST_HEADERS IN CLOB ,
                               p_REQUEST_BODY IN CLOB ,
                               p_BODY_CONTENT_TYPE IN VARCHAR2 ) AS
BEGIN
	NULL;
END LOG_REQUEST;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_RESPONSE ( p_RESPONSE_HEADERS IN CLOB ,
                                p_RESPONSE_BODY IN CLOB ,
                                p_BODY_CONTENT_TYPE IN VARCHAR2 ) AS
BEGIN
	NULL;
END LOG_RESPONSE;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_ATTACHMENT ( p_DESCRIPTION IN VARCHAR2,
                                  p_ATTACHMENT_TYPE IN VARCHAR2,
                                  p_ATTACHMENT IN CLOB ) AS
BEGIN
	NULL;
END LOG_ATTACHMENT;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_DEBUG ( p_MESSAGE IN VARCHAR2 ) AS
BEGIN
	NULL;
END LOG_DEBUG;
-----------------------------------------------------------------------------
MEMBER PROCEDURE LOG_STOP ( p_RESULT IN MEX_RESULT ) AS
BEGIN
	NULL;
END LOG_STOP;
-----------------------------------------------------------------------------
CONSTRUCTOR FUNCTION MEX_LOGGER RETURN SELF AS RESULT AS
BEGIN
	SELF.DUMMY := NULL;
	RETURN;
END;
-----------------------------------------------------------------------------
END;
/
