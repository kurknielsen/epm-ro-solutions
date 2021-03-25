CREATE OR REPLACE PACKAGE PARSE_UTIL AS
--Revision $Revision: 1.10 $
TYPE NUMBER_TABLE IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
TYPE STRING_TABLE IS TABLE OF VARCHAR(256) INDEX BY BINARY_INTEGER;

g_TRACE_INDEX NUMBER(9) := 0;
TYPE BIG_STRING_TABLE_MP IS TABLE OF VARCHAR(4000) INDEX BY BINARY_INTEGER;

FUNCTION WHAT_VERSION RETURN VARCHAR;

-- RSA -- 2007-03-20 -- Function to just return line-count without any
--                      added baggage of collections.
FUNCTION GET_LINE_COUNT_IN_CLOB (p_CLOB IN CLOB) RETURN INTEGER;

PROCEDURE PARSE_CLOB_INTO_LINES
	(
  p_CLOB IN CLOB,
  p_LINES IN OUT NOCOPY BIG_STRING_TABLE_MP
  );

PROCEDURE PARSE_DELIMITED_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	);

PROCEDURE TOKENS_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_STRING_TABLE OUT STRING_TABLE
	);

  PROCEDURE ID_TABLE_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_ID_TABLE OUT ID_TABLE
	);

  PROCEDURE TOKENS_FROM_BIG_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_BIG_STRING_TABLE OUT BIG_STRING_TABLE_MP
	);

  FUNCTION ADD_DOCTYPE(p_XML IN CLOB, p_DOCTYPE_TEXT IN VARCHAR2) RETURN CLOB;

  FUNCTION REMOVE_DOCTYPE(
  		p_XML IN CLOB,
		p_STRIP_ENCODING IN NUMBER := 1
		) RETURN CLOB;

  FUNCTION CREATE_XML_SAFE
	(
	p_XML IN CLOB,
	p_STRIP_ENCODING IN NUMBER := 1
	) RETURN XMLTYPE;

  FUNCTION HTML_RESPONSE_TO_TEXT
	(
	p_CLOB IN CLOB
	) RETURN CLOB;

PROCEDURE NEXT_TOKEN
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_INDEX IN BINARY_INTEGER,
	p_EOF OUT BOOLEAN,
	p_TOKEN OUT VARCHAR
	);

PROCEDURE TOKENS_FROM_SPACE_DELIM_STRING
	(
	p_STRING IN VARCHAR2,
	p_STRING_TABLE OUT STRING_TABLE
	);

FUNCTION FILE_NAME_FROM_PATH
	(
	p_FILE_PATH IN VARCHAR2
	) RETURN VARCHAR2;

PROCEDURE APPEND_TO_STAGING_CLOB
	(
	p_CLOB_IDENT IN VARCHAR2,
	p_CLOB_VAL IN CLOB
	);

END PARSE_UTIL;
/
CREATE OR REPLACE PACKAGE BODY PARSE_UTIL AS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.10 $';
END WHAT_VERSION;
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
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CLOB_INTO_LINES
	(
    p_CLOB IN CLOB,
    p_LINES IN OUT NOCOPY BIG_STRING_TABLE_MP
    ) AS
v_LINE_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER;
v_END_POS2 NUMBER;
v_END_CHAR VARCHAR2(1);
v_CHAR VARCHAR2(1);
v_LENGTH NUMBER;
v_TOKEN VARCHAR2(4000);
v_TOKEN_SIZE NUMBER := 0;

v_CHUNK VARCHAR2(32767);
v_CHUNK_SIZE NUMBER := 32767;
v_CHUNK_OFFSET NUMBER := 1;
v_CHUNK_COUNT NUMBER := 1;

v_LAST_LINE BOOLEAN := FALSE;

BEGIN
	v_LENGTH := DBMS_LOB.GETLENGTH(p_CLOB);
	
    WHILE v_CHUNK_OFFSET <= v_LENGTH AND NOT v_LAST_LINE LOOP
		v_CHUNK_SIZE := 32767;
		DBMS_LOB.READ(p_CLOB,v_CHUNK_SIZE,v_CHUNK_OFFSET,v_CHUNK);

		v_LAST_LINE := (v_CHUNK_SIZE + v_CHUNK_OFFSET) > v_LENGTH;

		-- Cleanup, get ready for next chunk
		v_BEGIN_POS := 1;
		v_END_POS := NULL;
		v_END_POS2 := NULL;
		v_TOKEN := NULL;
		
		WHILE v_BEGIN_POS <= v_CHUNK_SIZE LOOP
    		
			-- Check to make sure we didn't split the CR & LF during the 32K last chunk
			IF v_CHUNK_COUNT > 1 AND v_BEGIN_POS = 1 THEN
				v_END_POS := INSTR(v_CHUNK, CHR(10), v_BEGIN_POS);
				IF v_END_POS = 1 AND v_END_CHAR IS NOT NULL AND v_END_CHAR <> CHR(10) THEN
				-- Remove the first character from the chunk
					v_CHUNK := SUBSTR(v_CHUNK, 2);
				-- Changes the size of the chunk when 1st character removed
					v_CHUNK_SIZE := LENGTH(v_CHUNK);
				END IF;		
			END IF;
			
			v_END_CHAR := NULL;
			
			v_END_POS := INSTR(v_CHUNK, CHR(10), v_BEGIN_POS);
    		v_END_POS2 := INSTR(v_CHUNK, CHR(13), v_BEGIN_POS);
			v_TOKEN_SIZE := 0;
			
			-- determine which character we found - or, if we found both, which one
    		-- comes first
    		IF v_END_POS2 BETWEEN v_BEGIN_POS AND v_END_POS
    			OR v_BEGIN_POS BETWEEN v_END_POS AND v_END_POS2
    		THEN
    			v_END_POS := v_END_POS2;
    			v_END_CHAR := CHR(13);
    		ELSE
    			v_END_CHAR := CHR(10);
    		END IF;

			IF v_END_POS < v_BEGIN_POS THEN
				v_TOKEN := SUBSTR(v_CHUNK, v_BEGIN_POS, 4000);
				v_TOKEN_SIZE := LENGTH(v_TOKEN);
    			v_TOKEN := TRIM(v_TOKEN);
    			v_END_POS := v_CHUNK_SIZE;
				IF v_LAST_LINE THEN
    				v_LINE_COUNT := v_LINE_COUNT + 1;
            		p_LINES(v_LINE_COUNT) := v_TOKEN;
    				v_TOKEN := NULL;
				END IF;
    		ELSE
    			v_TOKEN := TRIM(SUBSTR(v_CHUNK, v_BEGIN_POS, v_END_POS - v_BEGIN_POS));

				v_CHAR := SUBSTR(v_CHUNK, v_END_POS+1, 1);
    			IF v_CHAR IN (CHR(10),CHR(13)) AND v_CHAR <> v_END_CHAR THEN
    				v_END_POS := v_END_POS+1;
    			END IF;

				v_LINE_COUNT := v_LINE_COUNT + 1;
        		p_LINES(v_LINE_COUNT) := v_TOKEN;
				v_TOKEN := NULL;
    		END IF;
			
    		v_BEGIN_POS := v_END_POS + 1;
    	END LOOP;

		IF v_TOKEN IS NOT NULL THEN
			v_CHUNK_OFFSET := v_CHUNK_OFFSET + 32767 - v_TOKEN_SIZE;
		ELSE
			v_CHUNK_OFFSET := v_CHUNK_OFFSET + 32767;
		END IF;

		v_CHUNK_COUNT := v_CHUNK_COUNT + 1;
    END LOOP;

EXCEPTION
    WHEN VALUE_ERROR THEN
		ERRS.RAISE(MSGCODES.c_ERR_GENERAL, 'VALUE_ERROR: COUNTER=' || v_LINE_COUNT
			|| ',TOKEN=' || v_TOKEN
			|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
			|| ',END_POS=' || TO_CHAR(v_END_POS)
			|| ',LENGTH=' || TO_CHAR(v_LENGTH));

END PARSE_CLOB_INTO_LINES;
----------------------------------------------------------------------------------------------------
/*
12-JUL-05 added support for double quotes within quoted strings
*/
PROCEDURE PARSE_DELIMITED_STRING(p_STRING       IN VARCHAR,
																 p_DELIMITER    IN CHAR,
																 p_STRING_TABLE OUT STRING_TABLE) AS

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
	v_QUOTES_COUNT := freq_instr1(p_STRING, QUOTE);

	-- if there's no quotes, process using the "chunking" method. If there's an
	-- odd number of quotes, throw an error; otherwise, parse as below.
	IF v_QUOTES_COUNT = 0 THEN
		TOKENS_FROM_STRING(p_STRING, p_DELIMITER, p_STRING_TABLE);
	ELSIF MOD(v_QUOTES_COUNT, 2) != 0 THEN
		ERRS.RAISE_BAD_ARGUMENT('p_STRING', p_STRING, 'Unbalanced quotes fed to routine PARSE_DELIMITED_STRING');
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
				ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
			END IF;
		END LOOP;

		-- add the last token
		v_COUNT := v_COUNT + 1;
		p_STRING_TABLE(v_COUNT) := TRIM(v_TOKEN);
	END IF;

EXCEPTION
	WHEN VALUE_ERROR THEN
		ERRS.RAISE(MSGCODES.c_ERR_GENERAL, 'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER ||
			',TOKEN=' || v_TOKEN || ',BEGIN_POS=' ||
			TO_CHAR(v_BEGIN_POS) || ',END_POS=' ||
			TO_CHAR(v_END_POS) || ',LENGTH=' ||
			TO_CHAR(v_LENGTH));

END PARSE_DELIMITED_STRING;
----------------------------------------------------------------------------------------------------
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
			ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
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
			ERRS.RAISE(MSGCODES.c_ERR_GENERAL, 'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
				|| ',TOKEN=' || v_TOKEN
				|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
				|| ',END_POS=' || TO_CHAR(v_END_POS)
				|| ',LENGTH=' || TO_CHAR(v_LENGTH));

END TOKENS_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE ID_TABLE_FROM_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_ID_TABLE OUT ID_TABLE
	) AS

v_INDEX BINARY_INTEGER := 1;
v_TOKEN VARCHAR(256);
v_EOF BOOLEAN;
BEGIN

	p_ID_TABLE := ID_TABLE();

	LOOP
		NEXT_TOKEN(p_STRING, p_DELIMITER, v_INDEX, v_EOF, v_TOKEN);
		EXIT WHEN v_EOF;
		p_ID_TABLE.EXTEND();
		p_ID_TABLE(v_INDEX) := ID_TYPE(TO_NUMBER(v_TOKEN));
		v_INDEX := v_INDEX + 1;
	END LOOP;

END ID_TABLE_FROM_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE TOKENS_FROM_BIG_STRING
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_BIG_STRING_TABLE OUT BIG_STRING_TABLE_MP
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
			ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
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
			ERRS.RAISE(MSGCODES.c_ERR_GENERAL,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
				|| ',TOKEN=' || v_TOKEN
				|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
				|| ',END_POS=' || TO_CHAR(v_END_POS)
				|| ',LENGTH=' || TO_CHAR(v_LENGTH));

END TOKENS_FROM_BIG_STRING;
----------------------------------------------------------------------------------------------------
FUNCTION ADD_DOCTYPE(p_XML IN CLOB, p_DOCTYPE_TEXT IN VARCHAR2) RETURN CLOB IS

	v_RET      CLOB;
	v_CLOB_POS NUMBER;
	v_CLOB_LEN NUMBER;
	v_XML_POS  NUMBER;
	v_TEXT     VARCHAR2(8192);
	v_LEN      PLS_INTEGER;
	v_CHUNK_NO NUMBER := 0;

BEGIN

	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
	DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);

	v_CLOB_LEN := DBMS_LOB.GETLENGTH(p_XML);
	v_CLOB_POS := 1;
	WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
		v_LEN := 4000;
		DBMS_LOB.READ(p_XML, v_LEN, v_CLOB_POS, v_TEXT);
		v_CHUNK_NO := v_CHUNK_NO + 1;
		v_CLOB_POS := v_CLOB_POS + v_LEN;
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
-------------------------------------------------------------------------------------
FUNCTION REMOVE_DOCTYPE
	(
	p_XML IN CLOB,
	p_STRIP_ENCODING IN NUMBER := 1
	) RETURN CLOB IS

	v_RET			CLOB;
	v_CLOB_POS		NUMBER;
	v_CLOB_LEN		NUMBER;
	v_POS1			PLS_INTEGER;
	v_POS2			PLS_INTEGER;
	v_POS3			PLS_INTEGER;
	v_POS4			PLS_INTEGER;
	v_OFFS			PLS_INTEGER;
	v_TEXT			VARCHAR2(8192);
	v_CHUNK_NO		NUMBER := 0;
	v_LEN			PLS_INTEGER;
	v_TO_WRITE		VARCHAR2(8192);
	-- used to track where we are when ripping out a
	-- potentially large doc type
	v_IN_DOCTYPE	PLS_INTEGER := 0;
	v_IN_COMMENT	BOOLEAN := FALSE;
	v_CARRYOVER		VARCHAR2(6);

	c_ENCODING_DIRECTIVE CONSTANT VARCHAR2(32) := 'encoding=';

BEGIN

	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
	DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);

	v_CLOB_LEN := DBMS_LOB.GETLENGTH(p_XML);
	v_CLOB_POS := 1;
	WHILE v_CLOB_POS <= v_CLOB_LEN LOOP
		-- potential carry-over from previous chunk to make sure we are able to identify
		-- comment indicators in a doctype ("<!--" and "-->") that are "broken" across
		-- chunks.
		v_CARRYOVER := NULL; -- init to nothing
		IF v_IN_DOCTYPE > 0 THEN
			IF v_IN_COMMENT THEN
				-- looking for comment end indicator "-->"
				IF SUBSTR(v_TEXT, LENGTH(v_TEXT)-1) = '--' THEN
					v_CARRYOVER := '--';
				ELSIF SUBSTR(v_TEXT, LENGTH(v_TEXT)) = '-' THEN
					v_CARRYOVER := '-';
				END IF;
			ELSE
				-- looking for comment start indicator "<!--"
				-- if we find a partial match, we'll need to decrement the in_doctype count
				-- to "unprocess" the leading "<"
				IF SUBSTR(v_TEXT, LENGTH(v_TEXT)-2) = '<!-' THEN
					v_CARRYOVER := '<!-';
					v_IN_DOCTYPE := v_IN_DOCTYPE-1;
				ELSIF SUBSTR(v_TEXT, LENGTH(v_TEXT)-1) = '<!' THEN
					v_CARRYOVER := '<!';
					v_IN_DOCTYPE := v_IN_DOCTYPE-1;
				ELSIF SUBSTR(v_TEXT, LENGTH(v_TEXT)) = '<' THEN
					v_CARRYOVER := '<';
					v_IN_DOCTYPE := v_IN_DOCTYPE-1;
				END IF;
			END IF;
		END IF;

		-- Get the next chunk
		v_LEN := 4000;
		DBMS_LOB.READ(p_XML, v_LEN, v_CLOB_POS, v_TEXT);
		IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
			-- at max debug, trace each chunk
			LOGS.LOG_DEBUG_MORE_DETAIL(v_TEXT);
		END IF;
		v_CHUNK_NO := v_CHUNK_NO + 1;
		v_CLOB_POS := v_CLOB_POS + v_LEN;

		-- prefix the carry-over if there is one		
		IF v_CARRYOVER IS NOT NULL THEN
			v_TEXT := v_CARRYOVER||v_TEXT;
		END IF;

		IF v_CHUNK_NO = 1 THEN
			IF p_STRIP_ENCODING <> 0 THEN
				-- byte-order marker is the first 3 bytes, if it is there
				IF SUBSTR(v_TEXT,1,3) = chr(239)||chr(187)||chr(191) OR
						 SUBSTR(v_TEXT,1,3) = chr(50095)||chr(49851)||chr(49855) THEN
					v_TEXT := SUBSTR(v_TEXT,4);
				END IF;
				IF SUBSTR(v_TEXT,1,5) = '<?xml' THEN
					v_POS1 := INSTR(v_TEXT, '>');
					v_POS2 := INSTR(v_TEXT, c_ENCODING_DIRECTIVE);
					IF v_POS2 > 0 AND v_POS2 < v_POS1 THEN
						v_POS3 := v_POS2+LENGTH(c_ENCODING_DIRECTIVE);
						v_POS4 := INSTR(v_TEXT, SUBSTR(v_TEXT,v_POS3, 1), v_POS3+1);
						v_TEXT := SUBSTR(v_TEXT, 1, v_POS2 - 1) ||
								  SUBSTR(v_TEXT, v_POS4 + 1);
					END IF;
				END IF;
			END IF;
			-- doctype tag will start in first chunk - if it's there, eliminate it
			v_POS1 := INSTR(v_TEXT, '<!DOCTYPE');
			IF v_POS1 > 0 THEN
				v_IN_DOCTYPE := 1; -- we are in the doc type -- v_POS1 records
									-- starting index in this chunk
				v_OFFS := 0; -- start searching for angle-brackets at this position
			END IF;
		ELSIF v_IN_DOCTYPE > 0 THEN
			v_POS1 := 1; -- start at first character of this chunk to
						-- to search for the end of the doc type
			v_OFFS := 1; -- start searching for angle-brackets "before" this position
						-- (in case first character of chunk is an angle-bracket)
		END IF;
		
		IF v_IN_DOCTYPE > 0 THEN
			-- v_POS1 represents start of DOCTYPE (or it's 1 if this is a continuation
			-- and DOCTYPE actually started in previous chunk)
			
			-- v_POS2 indicates position of next '>' (close tag)
			
			-- v_POS3 indicates position of next '<' (open tag)
			
			-- When we've matched all open tags (including the one that precedes "!DOCTYPE")
			-- with close tags then we've found the end of the DOCTYPE.
		
			IF v_IN_COMMENT THEN
				v_POS2 := INSTR(v_TEXT,'-->',1);
				IF v_POS2 <> 0 THEN
					v_IN_COMMENT := FALSE;
					v_POS3 := v_POS2+2;
				END IF;
			ELSE
				v_POS3 := v_POS1-v_OFFS;
			END IF;
			
			IF NOT v_IN_COMMENT THEN
				LOOP
					-- search for next end tag
					v_POS2 := INSTR(v_TEXT, '>', v_POS3+1);
					LOOP
						v_POS3 := INSTR(v_TEXT, '<', v_POS3+1);
						-- keep looking until we find no more "<" chars or
						-- until we 'catch up' to ">" char
						EXIT WHEN (v_POS2 <> 0 AND v_POS3 > v_POS2)
									OR v_POS3 = 0;
						-- is this a comment?
						IF SUBSTR(v_TEXT,v_POS3+1,3) = '!--' THEN
							v_POS2 := INSTR(v_TEXT,'-->',v_POS3+4);
							IF v_POS2 = 0 THEN
								-- end comment must be in next chunk
								-- so get out of this loop
								v_IN_COMMENT := TRUE;
								EXIT;
							ELSE
								-- reset pointers to next position and next
								-- close tag
								v_POS3 := v_POS2+2;
								v_POS2 := INSTR(v_TEXT,'>',v_POS2+3);
							END IF;
						ELSE
							-- increment for each open tag
							v_IN_DOCTYPE := v_IN_DOCTYPE+1;
						END IF;
					END LOOP;
					IF v_POS2 <> 0 THEN
						-- decrement for each close tag
						v_IN_DOCTYPE := v_IN_DOCTYPE-1;
						-- finished when we find the last close tag
						EXIT WHEN v_IN_DOCTYPE = 0;
						-- resume search after this close tag
						v_POS3 := v_POS2;
					ELSE
						-- final close tag must be in another chunk
						EXIT;
					END IF;
				END LOOP;
			END IF;
			
			IF v_IN_DOCTYPE > 0 THEN
				v_TO_WRITE := SUBSTR(v_TEXT, 1, v_POS1 - 1);
				-- rest of chunk is still doctype
			ELSE
				-- strip doctype out (or from beginning)
				v_TO_WRITE := SUBSTR(v_TEXT, 1, v_POS1 - 1) ||
						  		SUBSTR(v_TEXT, v_POS2 + 1);
			END IF;
		ELSE
			-- write the full chunk
			v_TO_WRITE := v_TEXT;
		END IF;
		
		-- append to our result CLOB if there is anything in this chunk to write
		IF v_TO_WRITE IS NOT NULL THEN
			DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_TO_WRITE), v_TO_WRITE);
		END IF;
	END LOOP;

	DBMS_LOB.CLOSE(v_RET);
	RETURN v_RET;

END REMOVE_DOCTYPE;
-------------------------------------------------------------------------------------
FUNCTION CREATE_XML_SAFE
	(
	p_XML IN CLOB,
	p_STRIP_ENCODING IN NUMBER := 1
	) RETURN XMLTYPE IS

v_SAFE_XML CLOB;
v_XML XMLTYPE;

BEGIN
	v_SAFE_XML := PARSE_UTIL.REMOVE_DOCTYPE(p_XML, p_STRIP_ENCODING);
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
        v_OUT_BUFFER := '';
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
FUNCTION GET_LINE_COUNT_IN_CLOB(p_CLOB IN CLOB) RETURN INTEGER IS
    v_LINE_NUMBER INTEGER := 1;
BEGIN
    WHILE (INSTR(p_CLOB, UTL_TCP.CRLF, 1, v_LINE_NUMBER) > 0) LOOP
        v_LINE_NUMBER := v_LINE_NUMBER + 1;
    END LOOP;
    RETURN v_LINE_NUMBER;
END GET_LINE_COUNT_IN_CLOB;
----------------------------------------------------------------------------------------------------
PROCEDURE NEXT_TOKEN
	(
	p_STRING IN VARCHAR,
	p_DELIMITER IN CHAR,
	p_INDEX IN BINARY_INTEGER,
	p_EOF OUT BOOLEAN,
	p_TOKEN OUT VARCHAR
	) AS

v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;

--p_INDEX IS A ONE-BASED INDEX.
BEGIN

	--THESE DEFAULTS WILL BE RETURNED IF A PROPER TOKEN IS NOT FOUND.
	p_EOF := TRUE;
	p_TOKEN := NULL;

	--TRY TO FIND A PROPER TOKEN.
	IF NOT LTRIM(RTRIM(p_STRING)) IS NULL THEN
		v_BEGIN_POS := INSTR(p_DELIMITER || p_STRING, p_DELIMITER, 1, p_INDEX);
		v_END_POS := INSTR(p_STRING || p_DELIMITER, p_DELIMITER, 1, p_INDEX);
		IF v_END_POS > 0 AND v_BEGIN_POS > 0 THEN
			p_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
			p_EOF := FALSE;
		END IF;
	END IF;

END NEXT_TOKEN;
---------------------------------------------------------------------------------------------------
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
			ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
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
		BEGIN
			IF NOT p_CLOB_LOC IS NULL THEN
				IF DBMS_LOB.ISTEMPORARY(p_CLOB_LOC) = 1 THEN
					DBMS_LOB.FREETEMPORARY(p_CLOB_LOC);
				END IF;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE();
		END;
		ERRS.LOG_AND_RAISE();

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
		BEGIN
			IF NOT v_CLOB_LOC IS NULL THEN
				IF DBMS_LOB.ISTEMPORARY(v_CLOB_LOC) = 1 THEN
					DBMS_LOB.FREETEMPORARY(v_CLOB_LOC);
				END IF;
			END IF;
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE();
		END;
		ERRS.LOG_AND_RAISE();

END APPEND_UNTIL_FINISHED_XML;
-------------------------------------------------------------------------------------
/*
  || This procedure return a string table of tokens for a space delimited string.
  || The number of spaces between the tokens could be one or more.
  || For example: A string 'abcd e    fghij' would return tokens 'abcd', 'e' and 'fghij'.
*/
PROCEDURE TOKENS_FROM_SPACE_DELIM_STRING
(
p_STRING IN VARCHAR2,
p_STRING_TABLE OUT STRING_TABLE
) AS

v_COUNT BINARY_INTEGER := 0;
v_BEGIN_POS NUMBER := 1;
v_END_POS NUMBER := 1;
v_LENGTH NUMBER;
v_TOKEN VARCHAR(256);
v_LOOP_COUNTER NUMBER;
p_DELIMITER CONSTANT VARCHAR2(1):= ' ';
v_GET_NEXT_TOKEN BOOLEAN := FALSE;

BEGIN
  -- If the argument string is empty then exit the procedure
  IF LTRIM(RTRIM(p_STRING)) IS NULL THEN
  RETURN;
  END IF;

  v_LENGTH := LENGTH(p_STRING);
  v_LOOP_COUNTER := 1;

  WHILE SUBSTR(p_STRING, v_LOOP_COUNTER, 1) IS NOT NULL
      LOOP
      IF (SUBSTR(p_STRING, v_LOOP_COUNTER, 1) = p_DELIMITER) OR (v_LOOP_COUNTER = v_LENGTH) THEN
         IF v_GET_NEXT_TOKEN = FALSE THEN
           -- Last Token
           IF (v_LOOP_COUNTER = v_LENGTH) THEN
              v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS)));
           ELSE
             v_END_POS := v_LOOP_COUNTER;
             -- Retreive the token
             v_TOKEN := LTRIM(RTRIM(SUBSTR(p_STRING, v_BEGIN_POS, v_END_POS - v_BEGIN_POS)));
           END IF;
           v_COUNT := v_COUNT + 1;
  		   p_STRING_TABLE(v_COUNT) := v_TOKEN;
           v_GET_NEXT_TOKEN := TRUE;
         END IF;
      ELSE
          IF v_GET_NEXT_TOKEN = TRUE THEN
          	v_BEGIN_POS := v_LOOP_COUNTER;
            v_GET_NEXT_TOKEN := FALSE;
          END IF;
      END IF;
      v_LOOP_COUNTER := v_LOOP_COUNTER + 1;

      IF v_LOOP_COUNTER > 10000 THEN
         ERRS.RAISE(MSGCODES.c_ERR_RUNAWAY_LOOP);
      END IF;
  END LOOP;

  EXCEPTION
    WHEN VALUE_ERROR THEN
    	ERRS.RAISE(MSGCODES.c_ERR_GENERAL,'VALUE_ERROR: LOOP_COUNTER=' || v_LOOP_COUNTER
			|| ',TOKEN=' || v_TOKEN
			|| ',BEGIN_POS=' || TO_CHAR(v_BEGIN_POS)
			|| ',END_POS=' || TO_CHAR(v_END_POS)
			|| ',LENGTH=' || TO_CHAR(v_LENGTH));

END TOKENS_FROM_SPACE_DELIM_STRING;
-------------------------------------------------------------------------------------
FUNCTION FILE_NAME_FROM_PATH
	(
	p_FILE_PATH IN VARCHAR2
	) RETURN VARCHAR2 IS
	v_FILE_NAME VARCHAR2(4000);
BEGIN
	--Given a file path with forward or backward slashes, return just the filename of the file.
	SELECT REGEXP_REPLACE(p_FILE_PATH, '.+(/|\\)([^/\\]+$)', '\2') RESULT INTO v_FILE_NAME FROM DUAL;
	RETURN v_FILE_NAME;
END FILE_NAME_FROM_PATH;
-------------------------------------------------------------------------------------
PROCEDURE APPEND_TO_STAGING_CLOB
	(
	p_CLOB_IDENT IN VARCHAR2,
	p_CLOB_VAL IN CLOB
	) AS
	v_CLOB_VAL CLOB;
BEGIN
	-- Check if there already exists a clob_val
	SELECT CLOB_VAL INTO v_CLOB_VAL
	FROM CLOB_STAGING
	WHERE CLOB_IDENT = p_CLOB_IDENT
	FOR UPDATE;

	DBMS_LOB.APPEND(v_CLOB_VAL, p_CLOB_VAL);

	UPDATE CLOB_STAGING
	SET CLOB_VAL = v_CLOB_VAL
	WHERE CLOB_IDENT = p_CLOB_IDENT;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
		INSERT INTO CLOB_STAGING
		VALUES(p_CLOB_IDENT, p_CLOB_VAL);

END APPEND_TO_STAGING_CLOB;
-------------------------------------------------------------------------------------
END PARSE_UTIL;
/
