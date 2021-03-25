CREATE OR REPLACE PACKAGE PARSE_UTIL IS

TYPE NUMBER_TABLE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE STRING_TABLE IS TABLE OF VARCHAR(256) INDEX BY BINARY_INTEGER;
TYPE BIG_STRING_TABLE IS TABLE OF VARCHAR(4000) INDEX BY BINARY_INTEGER;
TYPE REF_CURSOR IS REF CURSOR;

PROCEDURE PARSE_CLOB_INTO_LINES
	(
    p_CLOB IN CLOB,
    p_LINES OUT BIG_STRING_TABLE
    );

PROCEDURE TOKENS_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	);

PROCEDURE PARSE_DELIMITED_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	);

PROCEDURE TOKENS_FROM_BIG_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_BIG_STRING_TABLE OUT BIG_STRING_TABLE
	);

FUNCTION ADD_DOCTYPE(p_XML IN CLOB, p_DOCTYPE_TEXT IN VARCHAR2) RETURN CLOB;

FUNCTION REMOVE_DOCTYPE(p_XML IN CLOB) RETURN CLOB;

FUNCTION CREATE_XML_SAFE
	(
	p_XML IN CLOB
	) RETURN XMLTYPE;

FUNCTION HTML_RESPONSE_TO_TEXT
	(
	p_CLOB IN CLOB
	) RETURN CLOB;
	
PROCEDURE APPEND_UNTIL_FINISHED_CLOB
	(
	p_RECORD_DELIMITER IN CHAR,
	p_RECORDS IN VARCHAR,
	p_FILE_PATH IN VARCHAR,
	p_LAST_TIME IN NUMBER,
	p_CLOB_LOC OUT NOCOPY CLOB
	);

PROCEDURE PURGE_CLOB_STAGING_TABLE;

PROCEDURE APPEND_UNTIL_FINISHED_XML
	(
	p_RECORD_DELIMITER IN CHAR,
	p_RECORDS IN VARCHAR,
	p_FILE_PATH IN VARCHAR,
	p_LAST_TIME IN NUMBER,
	p_XML OUT XMLTYPE
	);



END PARSE_UTIL;
/
CREATE OR REPLACE PACKAGE BODY PARSE_UTIL IS

g_PACKAGE_NAME CONSTANT VARCHAR2(16) := 'PARSE_UTIL';

---------------------------------------------------------------------------------------------------
FUNCTION PACKAGE_NAME RETURN VARCHAR IS
BEGIN
    RETURN g_PACKAGE_NAME;
END PACKAGE_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION FREQ_INSTR1
	(
	STRING_IN IN VARCHAR2,
	SUBSTRING_IN IN VARCHAR2,
	MATCH_CASE_IN IN VARCHAR2 := 'IGNORE'
	) RETURN NUMBER
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

END FREQ_INSTR1;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CLOB_INTO_LINES
	(
    p_CLOB IN CLOB,
    p_LINES OUT BIG_STRING_TABLE
    ) AS
v_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;
v_LENGTH NUMBER;
v_TOKEN VARCHAR(4000);
v_LOOP_COUNTER NUMBER;
BEGIN
-- If the argument string is empty then exit the procedure
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	IF v_LENGTH = 0 THEN
		RETURN;
	END IF;

	v_LOOP_COUNTER := 0;
	LOOP
		v_END_POS := DBMS_LOB.INSTR(p_CLOB, CHR(10), v_BEGIN_POS);
		IF v_END_POS = 0 THEN
			v_TOKEN := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB, 4000, v_BEGIN_POS)));
			v_END_POS := v_LENGTH;
		ELSE
        	IF DBMS_LOB.SUBSTR(p_CLOB, 1, v_END_POS-1) = CHR(13) THEN
				v_TOKEN := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB, v_END_POS - v_BEGIN_POS - 1, v_BEGIN_POS)));
            ELSE
				v_TOKEN := LTRIM(RTRIM(DBMS_LOB.SUBSTR(p_CLOB, v_END_POS - v_BEGIN_POS, v_BEGIN_POS)));
                IF DBMS_LOB.SUBSTR(p_CLOB, 1, v_END_POS+1) = CHR(13) THEN
                	v_END_POS := v_END_POS+1;
                END IF;
            END IF;
		END IF;
		v_COUNT := v_COUNT + 1;
		p_LINES(v_COUNT) := v_TOKEN;
		v_BEGIN_POS := v_END_POS + 1;
		v_LOOP_COUNTER := v_LOOP_COUNTER + 1;
		IF v_LOOP_COUNTER > 100000 THEN
			RAISE_APPLICATION_ERROR(-20901,'RUNAWAY LOOP IN PARSE_UTIL.PARSE_CLOB_INTO_LINES');
		END IF;
		EXIT WHEN v_BEGIN_POS > v_LENGTH;
	END LOOP;

EXCEPTION
    WHEN VALUE_ERROR THEN
		RAISE_APPLICATION_ERROR(-20901,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
		|| ',TOKEN=' || v_TOKEN
		|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
		|| ',END_POS=' || TO_CHAR(v_END_POS)
		|| ',LENGTH=' || TO_CHAR(v_LENGTH));
	WHEN OTHERS THEN
		RAISE;
END PARSE_CLOB_INTO_LINES;
---------------------------------------------------------------------------------------------------
PROCEDURE TOKENS_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	) AS

v_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;
v_LENGTH NUMBER;
v_TOKEN VARCHAR(256);
v_LOOP_COUNTER NUMBER;

BEGIN

-- If the argument string is empty then exit the procedure

	IF LTRIM(RTRIM(p_STRING)) IS NULL THEN
		RETURN;
	END IF;

	v_LENGTH := LENGTH(p_STRING);
	v_LOOP_COUNTER := 0;

	LOOP
		v_END_POS := INSTR(p_STRING, p_DELIMITER, v_BEGIN_POS);
		IF v_END_POS = 0 THEN
      -- 14-mar-2005, jbc: need to catch if fields are greater than 255 wide
      -- (why do we have this limitation anyway?)
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, 255)));
			v_END_POS := v_LENGTH;
		ELSE
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
		END IF;
		v_COUNT := v_COUNT + 1;
		p_STRING_TABLE(v_COUNT) := v_TOKEN;
		v_BEGIN_POS := v_END_POS + 1;
		v_LOOP_COUNTER := v_LOOP_COUNTER + 1;
		IF v_LOOP_COUNTER > 10000 THEN
			RAISE_APPLICATION_ERROR(-20901,'RUNAWAY LOOP IN TOKENS_FROM_STRING PROCEDURE');
		END IF;
		EXIT WHEN v_BEGIN_POS > v_LENGTH;
	END LOOP;

-- If the argument string is terminated with the delimiter then append a null string token to the table

	IF SUBSTR(p_STRING, v_LENGTH) = p_DELIMITER THEN
		v_COUNT := v_COUNT + 1;
		p_STRING_TABLE(v_COUNT) := NULL;
	END IF;

	EXCEPTION
	    WHEN VALUE_ERROR THEN
			RAISE_APPLICATION_ERROR(-20901,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
			|| ',TOKEN=' || v_TOKEN
			|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
			|| ',END_POS=' || TO_CHAR(v_END_POS)
			|| ',LENGTH=' || TO_CHAR(v_LENGTH));
		WHEN OTHERS THEN
			RAISE;

END TOKENS_FROM_STRING;
----------------------------------------------------------------------------------------------------
/*
12-JUL-05 added support for double quotes within quoted strings
*/
PROCEDURE PARSE_DELIMITED_STRING	
	(
	p_STRING       IN VARCHAR,
	p_DELIMITER    IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	) AS

	v_COUNT        BINARY_INTEGER := 0;
	v_BEGIN_POS    NUMBER := 1;
	v_END_POS      NUMBER := 1;
	v_LENGTH       NUMBER;
	v_TOKEN        VARCHAR(256) := '';
	v_LOOP_COUNTER NUMBER;
	v_SKIP         BOOLEAN;
	QUOTE CONSTANT CHAR(1) := '"';
	
	v_QUOTES_COUNT NUMBER;
	v_CHAR         CHAR(1);
BEGIN

	-- If the argument string is empty then exit the procedure
	IF LTRIM(RTRIM(p_STRING)) IS NULL THEN
		RETURN;
	END IF;

	-- get the number of quotes in the string
	v_QUOTES_COUNT := FREQ_INSTR1(p_STRING, QUOTE);

	-- if there's no quotes, process using the "chunking" method. If there's an
	-- odd number of quotes, throw an error; otherwise, parse as below.
	IF v_QUOTES_COUNT = 0 THEN
		TOKENS_FROM_STRING(p_STRING, p_DELIMITER, p_STRING_TABLE);
	ELSIF MOD(v_QUOTES_COUNT, 2) != 0 THEN
		RAISE_APPLICATION_ERROR(-20901,
														'Unbalanced quotes fed to routine PARSE_DELIMITED_STRING');
	ELSE
		v_LENGTH       := LENGTH(p_STRING);
		v_LOOP_COUNTER := 1;
    v_SKIP         := FALSE;
    
		LOOP
			EXIT WHEN v_LOOP_COUNTER > v_LENGTH;
			-- get a single character
			v_CHAR := SUBSTR(p_STRING, v_LOOP_COUNTER, 1);
			IF v_CHAR = p_DELIMITER THEN
				v_COUNT := v_COUNT + 1;
				p_STRING_TABLE(v_COUNT) := TRIM(v_TOKEN);
				v_TOKEN := '';
        v_SKIP  := FALSE;
			ELSIF v_CHAR = QUOTE THEN
      
          -- move to the next character
          v_LOOP_COUNTER := v_LOOP_COUNTER + 1;

          -- then grab everything up to the next quote
  				v_TOKEN := v_TOKEN || SUBSTR(p_STRING, v_LOOP_COUNTER,
  																		 INSTR(p_STRING, QUOTE, v_LOOP_COUNTER) -
  																			v_LOOP_COUNTER);   
          -- move to the next quote
          IF NOT (SUBSTR(p_STRING, v_LOOP_COUNTER, 1) = QUOTE) THEN
            v_LOOP_COUNTER := INSTR(p_STRING, QUOTE, v_LOOP_COUNTER);
          END IF;
          -- now v_loop_counter should be pointing at the end quote
          
          -- check for a double quote
          -- this procedure handles quotes within a quoted string
          IF SUBSTR(p_STRING, v_LOOP_COUNTER + 1, 1) = QUOTE THEN
             v_TOKEN := v_TOKEN || QUOTE;
          ELSE
            -- found final end quote, now skip till delimiter
             v_SKIP  := TRUE;
          END IF;
          
			ELSE
        -- skip after quoted strings till delimiter
        IF v_SKIP = FALSE THEN
				  v_TOKEN := v_TOKEN || v_CHAR;
        END IF;
			END IF;
			v_LOOP_COUNTER := v_LOOP_COUNTER + 1;

			IF v_LOOP_COUNTER > 10000 THEN
				RAISE_APPLICATION_ERROR(-20901,
																'RUNAWAY LOOP IN TOKENS_FROM_STRING PROCEDURE');
			END IF;
		END LOOP;

		-- add the last token
		v_COUNT := v_COUNT + 1;
		p_STRING_TABLE(v_COUNT) := TRIM(v_TOKEN);
	END IF;

EXCEPTION
	WHEN VALUE_ERROR THEN
		RAISE_APPLICATION_ERROR(-20901,
														'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER ||
														 ',TOKEN=' || v_TOKEN || ',BEGIN_POS=' ||
														 TO_CHAR(v_BEGIN_POS) || ',END_POS=' ||
														 TO_CHAR(v_END_POS) || ',LENGTH=' ||
														 TO_CHAR(v_LENGTH));
	WHEN OTHERS THEN
		RAISE;

END PARSE_DELIMITED_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE TOKENS_FROM_BIG_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_BIG_STRING_TABLE OUT BIG_STRING_TABLE
	) AS

v_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;
v_LENGTH NUMBER;
v_TOKEN VARCHAR(4000);
v_LOOP_COUNTER NUMBER;

BEGIN

-- If the argument string is empty then exit the procedure

	IF LTRIM(RTRIM(p_STRING)) IS NULL THEN
		RETURN;
	END IF;

	v_LENGTH := LENGTH(p_STRING);
	v_LOOP_COUNTER := 0;

	LOOP
		v_END_POS := INSTR(p_STRING, p_DELIMITER, v_BEGIN_POS);
		IF v_END_POS = 0 THEN
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS)));
			v_END_POS := v_LENGTH;
		ELSE
			v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
		END IF;
		v_COUNT := v_COUNT + 1;
		p_BIG_STRING_TABLE(v_COUNT) := v_TOKEN;
		v_BEGIN_POS := v_END_POS + 1;
		v_LOOP_COUNTER := v_LOOP_COUNTER + 1;
		IF v_LOOP_COUNTER > 10000 THEN
			RAISE_APPLICATION_ERROR(-20901,'RUNAWAY LOOP IN TOKENS_FROM_BIG_STRING PROCEDURE');
		END IF;
		EXIT WHEN v_BEGIN_POS > v_LENGTH;
	END LOOP;

-- If the argument string is terminated with the delimiter then append a null string token to the table

	IF SUBSTR(p_STRING, v_LENGTH) = p_DELIMITER THEN
		v_COUNT := v_COUNT + 1;
		p_BIG_STRING_TABLE(v_COUNT) := NULL;
	END IF;

	EXCEPTION
	    WHEN VALUE_ERROR THEN
			RAISE_APPLICATION_ERROR(-20901,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
			|| ',TOKEN=' || v_TOKEN
			|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
			|| ',END_POS=' || TO_CHAR(v_END_POS)
			|| ',LENGTH=' || TO_CHAR(v_LENGTH));
		WHEN OTHERS THEN
			RAISE;

END TOKENS_FROM_BIG_STRING;
----------------------------------------------------------------------------------------------------
-- PROCEDURE DUMP_CLOB_TO_CHUNKS
-- 	(
--     p_CLOB IN CLOB,
-- 	p_CHUNKS OUT CLOB_CHUNK_TABLE
--     ) AS
-- v_CLOB_LEN NUMBER := DBMS_LOB.GETLENGTH(p_CLOB);
-- v_CLOB_POS NUMBER := 1;
-- v_SEQ NUMBER := 1;
-- v_TEXT VARCHAR2(4000);
-- BEGIN
-- 	p_CHUNKS := CLOB_CHUNK_TABLE();
-- 	WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
--         v_TEXT := DBMS_LOB.SUBSTR(p_CLOB,4000,v_CLOB_POS);
--         -- stuff into table
--         p_CHUNKS.EXTEND();
--         p_CHUNKS(v_SEQ) := CLOB_CHUNK_TYPE(v_SEQ,v_TEXT);
--         v_SEQ := v_SEQ+1;
--         v_CLOB_POS := v_CLOB_POS+4000;
--     END LOOP;
-- END DUMP_CLOB_TO_CHUNKS;
----------------------------------------------------------------------------------------------------
    FUNCTION ADD_DOCTYPE(p_XML IN CLOB, p_DOCTYPE_TEXT IN VARCHAR2) RETURN CLOB IS
        v_RET      CLOB;
        v_CLOB_POS NUMBER;
        v_CLOB_LEN NUMBER;
        v_XML_POS  NUMBER;
        v_TEXT     VARCHAR2(8448); -- 256 byte over 8k to accomodate insertion of DOCTYPE tag
        v_CHUNK_NO NUMBER := 0;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
        DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);
        v_CLOB_LEN := DBMS_LOB.GETLENGTH(p_XML);
        v_CLOB_POS := 1;
        WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
            v_TEXT     := DBMS_LOB.SUBSTR(p_XML, 8192, v_CLOB_POS);
            v_CHUNK_NO := v_CHUNK_NO + 1;
            v_CLOB_POS := v_CLOB_POS + 8192;
            IF v_CHUNK_NO = 1 THEN
                -- doctype tag will go into first chunk
                v_XML_POS := INSTR(v_TEXT, '<?xml');
                v_XML_POS := INSTR(v_TEXT, '>', v_XML_POS);
                IF v_XML_POS > 0 THEN
                    v_TEXT := SUBSTR(v_TEXT, 1, v_XML_POS) || '<!DOCTYPE ' ||
                              p_DOCTYPE_TEXT || '>' ||
                              SUBSTR(v_TEXT, v_XML_POS + 1);
                END IF;
            END IF;
            DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_TEXT), v_TEXT);
        END LOOP;
        DBMS_LOB.CLOSE(v_RET);
        RETURN v_RET;
    END ADD_DOCTYPE;
    ----------------------------------------------------------------------------------------------------
    FUNCTION REMOVE_DOCTYPE(p_XML IN CLOB) RETURN CLOB IS
        v_RET      CLOB;
        v_CLOB_POS NUMBER;
        v_CLOB_LEN NUMBER;
        v_DTD_POS1 NUMBER;
        v_DTD_POS2 NUMBER;
        v_TEXT     VARCHAR2(8192);
        v_CHUNK_NO NUMBER := 0;
    BEGIN
        DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
        DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);
        v_CLOB_LEN := DBMS_LOB.GETLENGTH(p_XML);
        v_CLOB_POS := 1;
        WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
            v_TEXT     := DBMS_LOB.SUBSTR(p_XML, 8192, v_CLOB_POS);
            v_CHUNK_NO := v_CHUNK_NO + 1;
            v_CLOB_POS := v_CLOB_POS + 8192;
            IF v_CHUNK_NO = 1 THEN
                -- doctype tag will be in first chunk - if its there, eliminate it
                v_DTD_POS1 := INSTR(v_TEXT, '<!DOCTYPE');
                v_DTD_POS2 := INSTR(v_TEXT, '>', v_DTD_POS1);
                IF v_DTD_POS1 > 0 THEN
                    v_TEXT := SUBSTR(v_TEXT, 1, v_DTD_POS1 - 1) ||
                              SUBSTR(v_TEXT, v_DTD_POS2 + 1);
                END IF;
            END IF;
            DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_TEXT), v_TEXT);
        END LOOP;
        DBMS_LOB.CLOSE(v_RET);
        RETURN v_RET;
    END REMOVE_DOCTYPE;
-------------------------------------------------------------------------------------
FUNCTION CREATE_XML_SAFE
	(
	p_XML IN CLOB
	) RETURN XMLTYPE IS
v_SAFE_XML CLOB;
v_XML XMLTYPE;
BEGIN
	v_SAFE_XML := REMOVE_DOCTYPE(p_XML);
	v_XML := XMLTYPE.CREATEXML(v_SAFE_XML);
	DBMS_LOB.FREETEMPORARY(v_SAFE_XML);
	
	RETURN v_XML;
END CREATE_XML_SAFE;
-------------------------------------------------------------------------------------

FUNCTION HTML_RESPONSE_TO_TEXT(p_CLOB IN CLOB) RETURN CLOB IS
    v_RET          CLOB;
    v_LAST_EMIT_WS BOOLEAN := FALSE;
    v_IN_TAG       BOOLEAN := FALSE;
    v_CLOB_LEN     NUMBER := DBMS_LOB.GETLENGTH(p_CLOB);
    v_CLOB_POS     NUMBER := 1;
    v_IN_BUF_LEN   NUMBER;
    v_IN_BUFFER    VARCHAR2(16384);
    v_OUT_BUFFER   VARCHAR2(16384);
    v_IN_BUF_POS   BINARY_INTEGER;
    v_END_POS      BINARY_INTEGER;
    v_CHAR         CHAR(1);
    v_TAG          VARCHAR2(16);
BEGIN
    DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
    DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);
    v_OUT_BUFFER := 'Transaction with PJM succeeded. PJM responded with the following:' || CHR(13) ||
                    CHR(10);
    DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_OUT_BUFFER), v_OUT_BUFFER);
    -- parse out all tags, newlines, tabs and extra spaces
    WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
        -- do it 16k chunks
        v_IN_BUF_LEN := 16384;
        DBMS_LOB.READ(p_CLOB, v_IN_BUF_LEN, v_CLOB_POS, v_IN_BUFFER);
        IF v_IN_TAG THEN
            -- cross-block tag? then find its end
            v_IN_BUF_POS := INSTR(v_IN_BUFFER, '>', 1);
            IF v_IN_BUF_POS < 1 THEN
                v_IN_BUF_POS := v_IN_BUF_LEN + 1;
                v_TAG        := '!';
            ELSE
                v_TAG        := SUBSTR(v_TAG || SUBSTR(v_IN_BUFFER, 1, v_IN_BUF_POS - 1), 1, 16);
                v_IN_BUF_POS := v_IN_BUF_POS + 1;
                v_IN_TAG     := FALSE;
                IF UPPER(v_TAG) = 'BR' OR UPPER(v_TAG) = 'P' OR UPPER(v_TAG) = '/HEAD' THEN
                    v_OUT_BUFFER   := v_OUT_BUFFER || CHR(13) || CHR(10);
                    v_LAST_EMIT_WS := TRUE;
                END IF;
            END IF;
        ELSE
            v_IN_BUF_POS := 1;
        END IF;
        v_OUT_BUFFER := '';
        WHILE v_IN_BUF_POS <= v_IN_BUF_LEN LOOP
            v_CHAR := SUBSTR(v_IN_BUFFER, v_IN_BUF_POS, 1);
            IF v_CHAR = CHR(13) OR v_CHAR = CHR(10) OR v_CHAR = CHR(9) OR v_CHAR = ' ' THEN
                IF NOT v_LAST_EMIT_WS THEN
                    v_OUT_BUFFER   := v_OUT_BUFFER || ' ';
                    v_LAST_EMIT_WS := TRUE;
                END IF;
            ELSIF v_CHAR = '<' THEN
                v_END_POS := INSTR(v_IN_BUFFER, '>', v_IN_BUF_POS);
                IF v_END_POS < 1 THEN
                    -- cross-block tag? then go to next block to find tag's end
                    v_TAG        := SUBSTR(SUBSTR(v_IN_BUFFER, v_IN_BUF_POS + 1), 1, 16);
                    v_IN_TAG     := TRUE;
                    v_IN_BUF_POS := v_IN_BUF_LEN;
                ELSE
                    v_TAG        := SUBSTR(SUBSTR(v_IN_BUFFER,
                                                  v_IN_BUF_POS + 1,
                                                  v_END_POS - v_IN_BUF_POS - 1),
                                           1,
                                           16);
                    v_IN_BUF_POS := v_END_POS;
                    IF UPPER(v_TAG) = 'BR' OR UPPER(v_TAG) = 'P' OR UPPER(v_TAG) = '/HEAD' THEN
                        v_OUT_BUFFER   := v_OUT_BUFFER || CHR(13) || CHR(10);
                        v_LAST_EMIT_WS := TRUE;
                    END IF;
                END IF;
            ELSE
                v_OUT_BUFFER   := v_OUT_BUFFER || v_CHAR;
                v_LAST_EMIT_WS := FALSE;
            END IF;
            v_IN_BUF_POS := v_IN_BUF_POS + 1;
        END LOOP;
        IF NOT TRIM(v_OUT_BUFFER) IS NULL THEN
            DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_OUT_BUFFER), v_OUT_BUFFER);
        END IF;
        v_CLOB_POS := v_CLOB_POS + 16384;
    END LOOP;
    DBMS_LOB.CLOSE(v_RET);
    RETURN v_RET;
END HTML_RESPONSE_TO_TEXT;
----------------------------------------------------------------------------------------------------
PROCEDURE APPEND_UNTIL_FINISHED_CLOB
	(
	p_RECORD_DELIMITER IN CHAR,
	p_RECORDS IN VARCHAR,
	p_FILE_PATH IN VARCHAR,
	p_LAST_TIME IN NUMBER,
	p_CLOB_LOC OUT NOCOPY CLOB
	) AS

v_TOKEN_TABLE GA.BIG_STRING_TABLE;
v_ROW_DATA VARCHAR2(4000);

BEGIN

    -- Tokenize into string table.
    UT.TOKENS_FROM_BIG_STRING(p_RECORDS,p_RECORD_DELIMITER,v_TOKEN_TABLE);

	-- Get what was already in the staging table for this session.
    BEGIN
	    SELECT ROW_CONTENTS INTO p_CLOB_LOC
        FROM DATA_IMPORT_STAGING_AREA
        WHERE SESSION_ID = USERENV('SESSIONID')
        	AND FILE_NAME = p_FILE_PATH
            AND ROW_NUM = 0 FOR UPDATE;
		IF p_CLOB_LOC IS NULL THEN
        	DBMS_LOB.CREATETEMPORARY(p_CLOB_LOC,TRUE);
        END IF;
	-- If it didn't exist, create a new clob.
	EXCEPTION
    	WHEN NO_DATA_FOUND THEN
        	DBMS_LOB.CREATETEMPORARY(p_CLOB_LOC,TRUE);
    END;

	-- Open the clob for writing, and add the tokens to it.
    DBMS_LOB.OPEN(p_CLOB_LOC, DBMS_LOB.LOB_READWRITE);
    FOR v_INDEX IN v_TOKEN_TABLE.FIRST..v_TOKEN_TABLE.LAST LOOP
		v_ROW_DATA := v_TOKEN_TABLE(v_INDEX) || CHR(13) || CHR(10);
        DBMS_LOB.WRITEAPPEND(p_CLOB_LOC, LENGTH(v_ROW_DATA), v_ROW_DATA);
    END LOOP;
    DBMS_LOB.CLOSE(p_CLOB_LOC);

	-- Insert back into the staging table if this was the first time.
	-- If this was not the first time, we have already updated the actual object in the table.
    IF DBMS_LOB.ISTEMPORARY(p_CLOB_LOC) = 1 THEN
       	INSERT INTO DATA_IMPORT_STAGING_AREA
           	(SESSION_ID, FILE_NAME, ROW_NUM,
             ROW_CONTENTS, STATUS)
        VALUES
           	(USERENV('SESSIONID'), p_FILE_PATH, 0,
             p_CLOB_LOC, 'B');
	END IF;

	IF p_LAST_TIME = 1 THEN
		-- If this is the last time, mark the rows in the table as Finished.
		-- We are returning the final clob.
    	UPDATE DATA_IMPORT_STAGING_AREA
        SET STATUS = 'F'
        WHERE SESSION_ID = USERENV('SESSIONID')
        	AND FILE_NAME = p_FILE_PATH;
	ELSE
		-- Clean up the clob since it's not the final one.
	    IF DBMS_LOB.ISTEMPORARY(p_CLOB_LOC) = 1 THEN
	    	DBMS_LOB.FREETEMPORARY(p_CLOB_LOC);
	    END IF;
		p_CLOB_LOC := NULL;
	END IF;


EXCEPTION
	WHEN OTHERS THEN
        IF NOT p_CLOB_LOC IS NULL THEN
        	IF DBMS_LOB.ISTEMPORARY(p_CLOB_LOC) = 1 THEN
            	DBMS_LOB.FREETEMPORARY(p_CLOB_LOC);
            END IF;
        END IF;

		RAISE;

END APPEND_UNTIL_FINISHED_CLOB;
----------------------------------------------------------------------------------------------------

PROCEDURE PURGE_CLOB_STAGING_TABLE AS
BEGIN

	DELETE FROM DATA_IMPORT_STAGING_AREA
	WHERE SESSION_ID = USERENV('SESSIONID')
		AND STATUS = 'F';

END PURGE_CLOB_STAGING_TABLE;
----------------------------------------------------------------------------------------------------

PROCEDURE APPEND_UNTIL_FINISHED_XML
	(
	p_RECORD_DELIMITER IN CHAR,
	p_RECORDS IN VARCHAR,
	p_FILE_PATH IN VARCHAR,
	p_LAST_TIME IN NUMBER,
	p_XML OUT XMLTYPE
	) AS

v_CLOB_LOC CLOB;

BEGIN
    APPEND_UNTIL_FINISHED_CLOB(p_RECORD_DELIMITER, p_RECORDS, p_FILE_PATH, p_LAST_TIME, v_CLOB_LOC);
	IF p_LAST_TIME = 1 AND v_CLOB_LOC IS NOT NULL THEN
		p_XML := XMLTYPE.CREATEXML(v_CLOB_LOC);
		PURGE_CLOB_STAGING_TABLE;

		IF DBMS_LOB.ISTEMPORARY(v_CLOB_LOC) = 1 THEN
		   	DBMS_LOB.FREETEMPORARY(v_CLOB_LOC);
		ELSE
			v_CLOB_LOC := NULL;
	    END IF;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
        IF NOT v_CLOB_LOC IS NULL THEN
        	IF DBMS_LOB.ISTEMPORARY(v_CLOB_LOC) = 1 THEN
            	DBMS_LOB.FREETEMPORARY(v_CLOB_LOC);
			ELSE
				v_CLOB_LOC := NULL;
            END IF;
        END IF;

		RAISE;

END APPEND_UNTIL_FINISHED_XML;
-------------------------------------------------------------------------------------
END PARSE_UTIL;
/
