CREATE OR REPLACE PACKAGE MEX_UTIL IS

-- Generic Market Exchange Utilities for use by both MarketManager and Monaco.
-- Most of the generic MM_UTIL procedures should be moved to this package.
-- These procedures can be called by both Monaco and MarketManager procedures,
-- therefore this package should not reference any tables or procedures
-- specific to MarketManager, RetailOffice, or Monaco.
-- The tables referenced by this package should become part of
-- a more generic multi-product Market Exchange setup.

TYPE PARAMETER_MAP IS TABLE OF VARCHAR2(4000) INDEX BY VARCHAR2(256);

v_HTTP_VER CONSTANT VARCHAR2(3) := '1.1';

g_RVW_STATUS_ACCEPTED CONSTANT VARCHAR2(16):= 'Accepted';
g_SUBMIT_STATUS_PENDING CONSTANT VARCHAR2(16):= 'Pending';
g_SUBMIT_STATUS_SUBMITTED CONSTANT VARCHAR2(16):= 'Submitted';
g_SUBMIT_STATUS_FAILED CONSTANT VARCHAR2(16):= 'Rejected';
g_MKT_STATUS_PENDING CONSTANT VARCHAR2(16):= 'Pending';
g_MKT_STATUS_ACCEPTED CONSTANT VARCHAR2(16):= 'Accepted';
g_MKT_STATUS_REJECTED CONSTANT VARCHAR2(16):= 'Rejected';

g_LOW_DATE CONSTANT DATE := TO_DATE('01-JAN-1900','DD-MON-YYYY');
g_HIGH_DATE CONSTANT DATE := TO_DATE('31-DEC-9999', 'DD-MON-YYYY');

g_SUCCESS CONSTANT NUMBER(1) := 0;
g_FAILURE CONSTANT NUMBER(2) := -2;
---------------------------------------------------------------------------------------------------

TYPE REF_CURSOR IS REF CURSOR;

FUNCTION WHAT_VERSION RETURN VARCHAR;

PROCEDURE DUMP_CLOB_TO_CHUNKS
   (
    p_CLOB IN CLOB,
   p_CHUNKS OUT CLOB_CHUNK_TABLE
    );

FUNCTION GET_MARKET_MESSAGE_ID
    (
    p_REALM IN VARCHAR2,
    p_EFFECTIVE_DATE IN DATE,
    p_TERMINATION_DATE IN DATE,
    p_PRIORITY IN NUMBER,
    p_TEXT     IN VARCHAR2
    ) RETURN NUMBER;

PROCEDURE INSERT_MARKET_MESSAGE(
   p_MARKET_OPERATOR IN VARCHAR2,
   p_MESSAGE_DATE IN DATE,
   p_REALM IN VARCHAR2,
   p_EFFECTIVE_DATE IN DATE,
   p_TERMINATION_DATE IN DATE,
   p_PRIORITY IN NUMBER,
   p_MESSAGE_SOURCE IN VARCHAR2,
   p_MESSAGE_DESTINATION IN VARCHAR2,
   p_TEXT IN VARCHAR2
   );

PROCEDURE GET_MARKET_MESSAGES
   (
   p_MARKET_OPERATOR IN VARCHAR2,
   p_SHOW_TERMINATED IN NUMBER,
   p_CURSOR IN OUT REF_CURSOR
   );

PROCEDURE SEND_MESSAGE
   (
   p_MARKET IN VARCHAR2,
   p_ACTION IN VARCHAR2,
   p_EXTERNAL_SYSTEM_ID IN NUMBER,
   p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2 := NULL,
   p_REQUEST_CLOB IN CLOB
   );


END MEX_UTIL;
/
create or replace package body MEX_UTIL is

g_PACKAGE_NAME CONSTANT VARCHAR2(8) := 'MEX_UTIL';

---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '08262004.1';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION PACKAGE_NAME RETURN VARCHAR IS
BEGIN
    RETURN g_PACKAGE_NAME;
END PACKAGE_NAME;
----------------------------------------------------------------------------------------------------
FUNCTION freq_instr1(string_in     IN VARCHAR2,
                               substring_in  IN VARCHAR2,
                               match_case_in IN VARCHAR2 := 'IGNORE') RETURN NUMBER
/*
  || Parameters:
  ||    string_in - the string in which frequency is checked.
  ||    substring_in - the substring we are counting in the string.
  ||    match_case_in - If "IGNORE" then count frequency of occurrences
  ||                    of substring regardless of case. If "MATCH" then
  ||                    only count occurrences if case matches.
  ||
  ||  Returns the number of times (frequency) a substring is found
  ||  by INSTR in the full string (string_in). If either string_in or
  || substring_in are NULL, then return 0.
  This code is taken from Chapter 11 and companion file freqinst.sf, in
  Oracle PL/SQL Programming 2nd Edition by Steven Feuerstein. Copyright 1997, 1995
  O'Reilly and Associates. O'Reilly allows such use of their code; see
  http://www.oreilly.com/pub/a/oreilly/ask_tim/2001/codepolicy.html
  */
 IS
   -- Starting location from which INSTR will search for a match.
   search_loc NUMBER := 1;

   -- The length of the incoming substring.
   substring_len NUMBER := LENGTH(substring_in);

   -- The Boolean variable which controls the loop.
   check_again BOOLEAN := TRUE;

   -- The return value for the function.
   return_value NUMBER := 0;
BEGIN

   IF string_in IS NOT NULL AND substring_in IS NOT NULL THEN
      /* Loop through string, moving forward the start of search.
    || The loop finds the next occurrence in string_in of the
    || substring_in. It does this by changing the starting location
    || of the search, but always finding the NEXT occurrence (the
    || last parameter is always 1).
    */
      WHILE check_again LOOP
         IF UPPER(match_case_in) = 'IGNORE' THEN
            -- Use UPPER to ignore case when performing the INSTR.
            search_loc := INSTR(UPPER(string_in), UPPER(substring_in), search_loc, 1);
         ELSE
            search_loc := INSTR(string_in, substring_in, search_loc, 1);
         END IF;
         check_again := search_loc > 0; -- Did I find another occurrence?
         IF check_again THEN
            -- Increment return value.
            return_value := return_value + 1;

            -- Move the start position for next search past the substring.
            search_loc := search_loc + substring_len;
         END IF;
      END LOOP;
   END IF;

   RETURN return_value;

END freq_instr1;
---------------------------------------------------------------------------------------------------
FUNCTION SAFE_STRING
   (
   p_XML IN XMLTYPE,
   p_XPATH IN VARCHAR2,
   p_NAMESPACE IN VARCHAR2 := NULL
   ) RETURN VARCHAR2 IS
--RETURN TEXT FOR A PATH OR NULL IF IT DOESN'T EXIST.
v_XMLTMP XMLTYPE;
BEGIN
   v_XMLTMP := XMLTYPE.EXTRACT(p_XML, p_XPATH, p_NAMESPACE);
   IF v_XMLTMP IS NULL THEN
      RETURN NULL;
   ELSE
      RETURN v_XMLTMP.GETSTRINGVAL();
   END IF;
END SAFE_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE DUMP_CLOB_TO_CHUNKS
   (
    p_CLOB IN CLOB,
   p_CHUNKS OUT CLOB_CHUNK_TABLE
    ) AS
v_CLOB_LEN NUMBER := DBMS_LOB.GETLENGTH(p_CLOB);
v_CLOB_POS NUMBER := 1;
v_SEQ NUMBER := 1;
v_TEXT VARCHAR2(4000);
BEGIN
   p_CHUNKS := CLOB_CHUNK_TABLE();
   WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
        v_TEXT := DBMS_LOB.SUBSTR(p_CLOB,4000,v_CLOB_POS);
        -- stuff into table
        p_CHUNKS.EXTEND();
        p_CHUNKS(v_SEQ) := CLOB_CHUNK_TYPE(v_SEQ,v_TEXT);
        v_SEQ := v_SEQ+1;
        v_CLOB_POS := v_CLOB_POS+4000;
    END LOOP;
END DUMP_CLOB_TO_CHUNKS;
-------------------------------------------------------------------------------------
FUNCTION GET_CONTENTTYPE_FOR_EXTENSION
   (
   p_EXTENSION IN VARCHAR2
   ) RETURN VARCHAR2 IS
BEGIN
   IF p_EXTENSION IS NULL THEN
      RETURN NULL;
   ELSE
      RETURN CASE UPPER(p_EXTENSION)
               WHEN 'HTML' THEN
                  'text/html'
               WHEN 'XML' THEN
                  'text/xml'
               ELSE -- anything else will be viewed as plain text...
                  'text/plain'
               END;
   END IF;
END GET_CONTENTTYPE_FOR_EXTENSION;
-------------------------------------------------------------------------------------
FUNCTION GET_MARKET_MESSAGE_ID
(
  p_REALM IN VARCHAR2,
  p_EFFECTIVE_DATE IN DATE,
  p_TERMINATION_DATE IN DATE,
  p_PRIORITY IN NUMBER,
  p_TEXT     IN VARCHAR2
  ) RETURN NUMBER IS

v_MEXID NUMBER(9);

BEGIN

  BEGIN
          -- has this message already been put in the system?
       SELECT M.MESSAGE_ID
        INTO v_MEXID
        FROM MEX_MESSAGE M
        WHERE M.MESSAGE_REALM = p_REALM
         AND M.MESSAGE_PRIORITY = p_PRIORITY
         AND M.EFFECTIVE_DATE = p_EFFECTIVE_DATE
         AND M.TERMINATION_DATE = p_TERMINATION_DATE
         AND M.MESSAGE_TEXT = p_TEXT;
  EXCEPTION
           WHEN NO_DATA_FOUND THEN
                RETURN 0;
  END;

  RETURN v_MEXID;

END GET_MARKET_MESSAGE_ID;
-------------------------------------------------------------------------------------
PROCEDURE INSERT_MARKET_MESSAGE(
    p_MARKET_OPERATOR     IN VARCHAR2,
   p_MESSAGE_DATE IN DATE,
   p_REALM IN VARCHAR2,
   p_EFFECTIVE_DATE IN DATE,
   p_TERMINATION_DATE IN DATE,
   p_PRIORITY IN NUMBER,
   p_MESSAGE_SOURCE IN VARCHAR2,
   p_MESSAGE_DESTINATION IN VARCHAR2,
   p_TEXT                IN VARCHAR2) AS

--Put Messages to database
v_MEXID NUMBER(9);

BEGIN

/*   -- has this message already been put in the system?
   SELECT M.MESSAGE_ID
      INTO v_MEXID
      FROM MEX_MESSAGE M
    WHERE M.MESSAGE_REALM = p_REALM
       AND M.MESSAGE_PRIORITY = p_PRIORITY
       AND M.EFFECTIVE_DATE = p_EFFECTIVE_DATE
       AND M.TERMINATION_DATE = p_TERMINATION_DATE
       AND M.MESSAGE_TEXT = p_TEXT;
    EXCEPTION
   WHEN NO_DATA_FOUND THEN*/

    v_MEXID := GET_MARKET_MESSAGE_ID(p_REALM, p_EFFECTIVE_DATE, p_TERMINATION_DATE, p_PRIORITY, p_TEXT);

    IF v_MEXID = 0 THEN

   SELECT MEXID.NEXTVAL INTO v_MEXID FROM DUAL;

      INSERT INTO MEX_MESSAGE
      (MESSAGE_ID,
       MARKET_OPERATOR,
      MESSAGE_DATE,
       MESSAGE_REALM,
       MESSAGE_PRIORITY,
      EFFECTIVE_DATE,
      TERMINATION_DATE,
      MESSAGE_SOURCE,
      MESSAGE_DESTINATION,
      MESSAGE_TEXT,
      ENTRY_DATE)
      VALUES
      (v_MEXID,
      p_MARKET_OPERATOR,
      p_MESSAGE_DATE,
      p_REALM,
      p_PRIORITY,
      p_EFFECTIVE_DATE,
      p_TERMINATION_DATE,
      p_MESSAGE_SOURCE,
      p_MESSAGE_DESTINATION,
      p_TEXT,
      SYSDATE);

    END IF;

END INSERT_MARKET_MESSAGE;
-------------------------------------------------------------------------------------
PROCEDURE GET_MARKET_MESSAGES
   (
   p_MARKET_OPERATOR IN VARCHAR2,
   p_SHOW_TERMINATED IN NUMBER,
   p_CURSOR IN OUT REF_CURSOR
   ) AS

BEGIN

   OPEN p_CURSOR FOR
       SELECT *
       FROM MEX_MESSAGE A
       WHERE (p_MARKET_OPERATOR = '<All>' OR MARKET_OPERATOR = p_MARKET_OPERATOR)
         AND (p_SHOW_TERMINATED = 1 OR SYSDATE BETWEEN NVL(EFFECTIVE_DATE,g_LOW_DATE) AND NVL(TERMINATION_DATE,g_HIGH_DATE))
      ORDER BY MESSAGE_DATE DESC, MESSAGE_PRIORITY, MARKET_OPERATOR, MESSAGE_DATE, MESSAGE_REALM;

END GET_MARKET_MESSAGES;
-------------------------------------------------------------------------------------
PROCEDURE SEND_MESSAGE
   (
   p_MARKET IN VARCHAR2,
   p_ACTION IN VARCHAR2,
   p_EXTERNAL_SYSTEM_ID IN NUMBER,
   p_EXTERNAL_ACCOUNT_NAME IN VARCHAR2 := NULL,
   p_REQUEST_CLOB IN CLOB
   )
AS
   v_IS_ENABLED EXTERNAL_SYSTEM.IS_ENABLED%TYPE;
   v_CRED MEX_CREDENTIALS;
   v_LOGGER MM_LOGGER_ADAPTER;
   v_RESULT MEX_RESULT;
   v_LOG_ONLY NUMBER;
   v_MESSAGE VARCHAR2(256);
BEGIN
   MEX_SWITCHBOARD.INIT_MEX(p_EXTERNAL_SYSTEM_ID, p_EXTERNAL_ACCOUNT_NAME, NULL, NULL, 0, 0, v_CRED, v_LOGGER);

   -- Get 'Is Enabled' value for the External System
   SELECT S.IS_ENABLED INTO v_IS_ENABLED
   FROM EXTERNAL_SYSTEM S
   WHERE S.EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;

   IF v_IS_ENABLED = 0 THEN
      v_LOG_ONLY:= 1;
   ELSE
      v_LOG_ONLY := 0;
      -- only call this "pre" exchange handler if we are actually going to do something
      XS.PRE_MARKET_EXCHANGE(p_EXTERNAL_SYSTEM_ID, p_ACTION, UT.c_EMPTY_MAP, p_REQUEST_CLOB, v_LOGGER);
   END IF;

   v_LOGGER.LOG_INFO(p_ACTION);
   
   v_RESULT := MEX_SWITCHBOARD.Invoke(p_MARKET => p_MARKET,
                              p_ACTION => p_ACTION,
                              p_LOGGER => v_LOGGER,
                              p_CRED => v_CRED,
                              P_REQUEST_CONTENTTYPE => CONSTANTS.MIME_TYPE_XML,
                              p_REQUEST => p_REQUEST_CLOB,
                              p_LOG_ONLY => v_LOG_ONLY);

   IF v_LOG_ONLY = 1 THEN
      v_MESSAGE := 'The External System for sending the dispatch schedule is disabled.';
      v_LOGGER.LOG_ERROR(v_MESSAGE);
      ERRS.RAISE(MSGCODES.c_ERR_MEX_SEND_MESSAGE, v_MESSAGE);
   END IF;

   IF v_RESULT.STATUS_CODE <> MEX_SWITCHBOARD.C_STATUS_SUCCESS THEN
      v_LOGGER.LOG_ERROR(MEX_SWITCHBOARD.GETERRORTEXT(v_RESULT));
      ERRS.RAISE(MSGCODES.c_ERR_MEX_SEND_MESSAGE, MEX_SWITCHBOARD.GETERRORTEXT(v_RESULT));
   END IF;

   -- only call this "post" exchange handler on success
   XS.POST_MARKET_EXCHANGE(p_EXTERNAL_SYSTEM_ID, p_ACTION, UT.c_EMPTY_MAP, p_REQUEST_CLOB, v_LOGGER);
   
END SEND_MESSAGE;
-------------------------------------------------------------------------------------
END MEX_UTIL;
/
