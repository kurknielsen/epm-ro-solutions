CREATE OR REPLACE PACKAGE ROML_IMPORT IS
-- $Revision: 1.3 $

  -- Author  : JHUMPHRIES
  -- Created : 5/4/2010 2:59:50 PM
  -- Purpose : Import table data from ROML file: Retail Operations Markup Language
  -- 			(non-XML proprietary text format)
  
FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE DO_IMPORT
	(
	p_IMPORT_FILE		IN CLOB,
	p_IMPORT_FILE_PATH	IN VARCHAR2,
	p_TRACE_ON 			IN NUMBER,
	p_PROCESS_ID 		OUT VARCHAR2,
	p_PROCESS_STATUS 	OUT NUMBER,
	p_MESSAGE 			OUT VARCHAR2
	);

END ROML_IMPORT;
/
CREATE OR REPLACE PACKAGE BODY ROML_IMPORT IS
-------------------------------------------------------------------------------
-- Map of entity identifiers in ROML file to actual entity IDs in database
TYPE t_ENTITY_ID_MAP IS TABLE OF NUMBER(9) INDEX BY VARCHAR2(80);

-- Prefixes used for representing literal values in ROML file
c_ROML_NUM	CONSTANT CHAR(1) := '#';
c_ROML_DATE	CONSTANT CHAR(1) := '@';
c_ROML_STR	CONSTANT CHAR(1) := '"';
c_ROML_REF	CONSTANT CHAR(1) := '*';

-- date format for ROML representation of dates
c_ROML_FMT	CONSTANT VARCHAR2(32) := 'MON-DD-YYYY HH24:MI:SS';

-- "Tab stop" used for indentation of log messages to make trace log easier to read
c_INDENT	CONSTANT VARCHAR2(4) := '    ';

-- Keep track of lines to import and our current location in the set
g_LINE_NO	PLS_INTEGER := NULL;
g_LINES		PARSE_UTIL.BIG_STRING_TABLE_MP;
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
-------------------------------------------------------------------------------
-- Reset local variables
PROCEDURE RESET IS
BEGIN
	g_LINES.DELETE;
	g_LINE_NO := NULL;
END RESET;
-------------------------------------------------------------------------------
-- Initialize local variables - and setup progress tracking for the process
PROCEDURE INIT
	(
	p_CLOB IN CLOB
	) IS
BEGIN
	RESET;
	PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CLOB, g_LINES);
	LOGS.INIT_PROCESS_PROGRESS('Importing data', g_LINES.COUNT, 'Lines', TRUE);
END INIT;
-------------------------------------------------------------------------------
-- Are we looking at the last line?
FUNCTION IS_EOF RETURN BOOLEAN IS
BEGIN
	RETURN NOT g_LINES.EXISTS( g_LINES.NEXT(NVL(g_LINE_NO,g_LINES.FIRST)) );
END IS_EOF;
-------------------------------------------------------------------------------
-- Retrieve the next line from the file and increment the process progress
FUNCTION NEXT_LINE RETURN VARCHAR2 IS
BEGIN
	-- get the next line from the collection
	IF g_LINE_NO IS NULL THEN
		g_LINE_NO := g_LINES.FIRST;
	ELSE
		g_LINE_NO := g_LINES.NEXT(g_LINE_NO);
	END IF;

	-- advance the import progress
	LOGS.INCREMENT_PROCESS_PROGRESS;
	
	RETURN LTRIM(g_LINES(g_LINE_NO));
END NEXT_LINE;
-------------------------------------------------------------------------------
-- Add an entity mapping to the specified ID map
PROCEDURE ADD_ENTITY
	(
	p_IDENTIFIER	IN VARCHAR2,
	p_ID			IN NUMBER,
	p_ENTITY_MAP	IN OUT NOCOPY t_ENTITY_ID_MAP
	) IS
BEGIN
	ASSERT(SUBSTR(p_IDENTIFIER,1,1) = c_ROML_REF, 'Invalid ROML Import File. ID for object is not in correct object reference format.', MSGCODES.c_ERR_DATA_IMPORT);

	IF NOT p_ENTITY_MAP.EXISTS(p_IDENTIFIER) THEN
		-- associate specified entity ID with specified ROML identifier
		p_ENTITY_MAP(p_IDENTIFIER) := p_ID;
	END IF;
END ADD_ENTITY;
-------------------------------------------------------------------------------
-- Query for an entity ID from the specified ID map
FUNCTION GET_ENTITY
	(
	p_IDENTIFIER	IN VARCHAR2,
	p_ENTITY_MAP	IN OUT NOCOPY t_ENTITY_ID_MAP
	) RETURN NUMBER IS
BEGIN
	IF p_ENTITY_MAP.EXISTS(p_IDENTIFIER) THEN
		RETURN p_ENTITY_MAP(p_IDENTIFIER);
	ELSE
		RETURN NULL;
	END IF;
END GET_ENTITY;
-------------------------------------------------------------------------------
-- Translate ROML value to PL-SQL literal value for specified field name
-- from specified set of field values
FUNCTION GET_LITERAL_VALUE
	(
	p_FIELDS		IN OUT NOCOPY UT.STRING_MAP,
	p_FIELD_NAME	IN VARCHAR2
	) RETURN VARCHAR2 IS
v_FIELD_VALUE	VARCHAR2(4000);
v_PREFIX		CHAR(1);
BEGIN
	v_FIELD_VALUE := p_FIELDS(p_FIELD_NAME);
	v_PREFIX := SUBSTR(v_FIELD_VALUE,1,1);
	v_FIELD_VALUE := SUBSTR(v_FIELD_VALUE,2);
	
	IF v_FIELD_VALUE IS NULL THEN
		RETURN CONSTANTS.LITERAL_NULL;
	END IF;

	CASE v_PREFIX
	WHEN c_ROML_DATE THEN
		RETURN UT.GET_LITERAL_FOR_DATE(TO_DATE(v_FIELD_VALUE, c_ROML_FMT));
	WHEN c_ROML_NUM THEN
		RETURN v_FIELD_VALUE;
	WHEN c_ROML_STR THEN
		RETURN UT.GET_LITERAL_FOR_STRING(REPLACE(REPLACE(REPLACE(v_FIELD_VALUE,'\n',CHR(10)),'\r',CHR(13)),'\\','\'));
	END CASE;
END GET_LITERAL_VALUE;
-------------------------------------------------------------------------------
-- Update field values so that any object references get resolved to proper
-- ID values
PROCEDURE RESOLVE_ENTITY_REFERENCES
	(
	p_FIELDS		IN OUT NOCOPY UT.STRING_MAP,
	p_ENTITY_MAP	IN OUT NOCOPY t_ENTITY_ID_MAP
	) AS
v_FIELD_NAME	VARCHAR2(30);
v_FIELD_VAL		VARCHAR2(4000);
v_ID			NUMBER(9);
v_POS			PLS_INTEGER;
v_SEQ			VARCHAR2(30);
BEGIN
	v_FIELD_NAME := p_FIELDS.FIRST;
	-- loop over fields
	WHILE p_FIELDS.EXISTS(v_FIELD_NAME) LOOP
		v_FIELD_VAL := p_FIELDS(v_FIELD_NAME);
		IF SUBSTR(v_FIELD_VAL,1,1) = c_ROML_REF THEN
			-- found entity reference - resolve it
			
			v_POS := INSTR(v_FIELD_VAL, '|');
			-- does the reference include a sequence name?
			IF v_POS > 0 THEN
				v_SEQ := SUBSTR(v_FIELD_VAL,v_POS+1);
				v_FIELD_VAL := SUBSTR(v_FIELD_VAL,1,v_POS-1);
			ELSE
				v_SEQ := 'OID'; -- OID is default sequence name
			END IF;
			
			v_ID := GET_ENTITY(v_FIELD_VAL, p_ENTITY_MAP);
			IF v_ID IS NULL THEN
				-- not in the map? must create ID from sequence
				EXECUTE IMMEDIATE 'SELECT '||v_SEQ||'.NEXTVAL FROM DUAL' INTO v_ID;

				ADD_ENTITY(v_FIELD_VAL, v_ID, p_ENTITY_MAP);
			END IF;

			-- replace object reference with numeric ID value
			p_FIELDS(v_FIELD_NAME) := c_ROML_NUM||v_ID;
			
		END IF;
		v_FIELD_NAME := p_FIELDS.NEXT(v_FIELD_NAME);
	END LOOP;
END RESOLVE_ENTITY_REFERENCES;
-------------------------------------------------------------------------------
-- Dump DML text to log
PROCEDURE TRACE_DML
	(
	p_DML IN VARCHAR2
	) AS
BEGIN
	IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		LOGS.LOG_INFO_MORE_DETAIL('Issuing dynamic DML. See attachment for DML text');
		LOGS.POST_EVENT_DETAILS('DML Text', CONSTANTS.MIME_TYPE_TEXT, p_DML);
	END IF;
END TRACE_DML;
-------------------------------------------------------------------------------
-- Return a map whose values are PL-SQL literals instead of ROML formatted values
FUNCTION GET_MAP_OF_LITERAL_VALUES
	(
	p_FIELDS	IN OUT NOCOPY UT.STRING_MAP
	) RETURN UT.STRING_MAP IS
v_RET	UT.STRING_MAP;
v_KEY	VARCHAR2(30);
BEGIN
	v_KEY := p_FIELDS.FIRST;
	WHILE p_FIELDS.EXISTS(v_KEY) LOOP
		v_RET(v_KEY) := GET_LITERAL_VALUE(p_FIELDS, v_KEY);
		v_KEY := p_FIELDS.NEXT(v_KEY);
	END LOOP;
	RETURN v_RET;
END GET_MAP_OF_LITERAL_VALUES;
-------------------------------------------------------------------------------
-- Insert a single row in the database
PROCEDURE INSERT_DATABASE_RECORD
	(
	p_TABLE_NAME	IN VARCHAR2,
	p_FIELDS		IN OUT NOCOPY UT.STRING_MAP
	) AS
v_MAP	UT.STRING_MAP := GET_MAP_OF_LITERAL_VALUES(p_FIELDS);
v_DML	VARCHAR2(32767);
BEGIN
	v_DML := 'INSERT INTO '||p_TABLE_NAME||' ('||UT.MAP_TO_INSERT_NAMES(v_MAP)||')'
				||' VALUES ('||UT.MAP_TO_INSERT_VALS(v_MAP)||')';
	TRACE_DML(v_DML);
	EXECUTE IMMEDIATE v_DML;
END INSERT_DATABASE_RECORD;
-------------------------------------------------------------------------------
-- Update a single row in the database by ID
PROCEDURE UPDATE_DATABASE_RECORD
	(
	p_TABLE_NAME	IN VARCHAR2,
	p_FIELDS		IN OUT NOCOPY UT.STRING_MAP,
	p_ID_COLUMN		IN VARCHAR2,
	p_ID_VALUE		IN NUMBER
	) AS
v_MAP	UT.STRING_MAP := GET_MAP_OF_LITERAL_VALUES(p_FIELDS);
v_DML	VARCHAR2(32767);
BEGIN
	v_DML := 'UPDATE '||p_TABLE_NAME||' SET '||UT.MAP_TO_UPDATE_CLAUSE(v_MAP)
				||' WHERE '||p_ID_COLUMN||' = '||UT.GET_LITERAL_FOR_NUMBER(p_ID_VALUE);
	TRACE_DML(v_DML);
	EXECUTE IMMEDIATE v_DML;
END UPDATE_DATABASE_RECORD;
-------------------------------------------------------------------------------
-- Build DML statement to clear out child records (which is done before subsequently
-- reloading child records from data in the ROML file)
FUNCTION BUILD_SUBTABLE_DELETE
	(
	p_PARENT_FIELDS	IN OUT NOCOPY UT.STRING_MAP,
	p_TABLE_NAME	IN VARCHAR2,
	p_RELATIONSHIP	IN VARCHAR2
	) RETURN VARCHAR2 IS

v_DML			VARCHAR2(32767);
v_REL_PARTS		GA.STRING_TABLE;
v_MAIN_JOINS	GA.STRING_TABLE;
v_JOIN_FIELDS	GA.STRING_TABLE;
v_IDX			PLS_INTEGER;
v_NEW_FIELD		VARCHAR2(30);
v_OLD_FIELD		VARCHAR2(30);
v_FIRST			BOOLEAN := TRUE;
v_POS			PLS_INTEGER;
v_TOKEN			VARCHAR2(32);
	------------------------------------------------
	-- Append "AND" to query if needed
	PROCEDURE ADD_AND IS
	BEGIN
		IF v_FIRST THEN
			v_FIRST := FALSE;
		ELSE
			v_DML := v_DML||' AND ';
		END IF;
	END ADD_AND;
	------------------------------------------------
BEGIN
	v_DML := 'DELETE '||p_TABLE_NAME||' WHERE';
	
	-- parse the relationship definition
	UT.TOKENS_FROM_STRING(p_RELATIONSHIP, ';', v_REL_PARTS);
	IF LENGTH(v_REL_PARTS(v_REL_PARTS.FIRST)) > 0 THEN
		-- has a main join criteria - add to the SQL where clause
		UT.TOKENS_FROM_STRING(v_REL_PARTS(v_REL_PARTS.FIRST), '^', v_MAIN_JOINS);
		
		v_IDX := v_MAIN_JOINS.FIRST;
		WHILE v_MAIN_JOINS.EXISTS(v_IDX) LOOP
			UT.TOKENS_FROM_STRING(v_MAIN_JOINS(v_IDX), '=', v_JOIN_FIELDS);
			
			-- if only one field name and no "=" delimiter, this will get same
			-- field name for both sides of join
			v_NEW_FIELD := v_JOIN_FIELDS(v_JOIN_FIELDS.FIRST);
			v_OLD_FIELD := v_JOIN_FIELDS(v_JOIN_FIELDS.LAST);
			
            -- now we can add the join to the query
			ADD_AND;
			v_DML := v_DML||' '||v_NEW_FIELD||' = '||GET_LITERAL_VALUE(p_PARENT_FIELDS, v_OLD_FIELD);

			v_IDX := v_MAIN_JOINS.NEXT(v_IDX);
		END LOOP;
	END IF;
	
    -- any other relationship clauses?
	v_IDX := v_REL_PARTS.NEXT(v_REL_PARTS.FIRST);
	WHILE v_REL_PARTS.EXISTS(v_IDX) LOOP
		ADD_AND;
		-- dollar-sign means substitute value from other table
		IF SUBSTR(v_REL_PARTS(v_IDX),1,1) = '$' THEN
			v_POS := INSTR(v_REL_PARTS(v_IDX), '=');
			IF v_POS <= 0 THEN
				v_POS := INSTR(v_REL_PARTS(v_IDX), ' ');
			END IF;
			v_TOKEN := TRIM(SUBSTR(v_REL_PARTS(v_IDX), 2, v_POS-2));
			-- ignore trailing at (@) or pound (#) - no longer used/needed
			IF SUBSTR(v_TOKEN, LENGTH(v_TOKEN), 1) IN ('@','#') THEN
				v_TOKEN := SUBSTR(v_TOKEN, 1, LENGTH(v_TOKEN)-1);
			END IF;
			v_DML := v_DML||GET_LITERAL_VALUE(p_PARENT_FIELDS, v_TOKEN)||SUBSTR(v_REL_PARTS(v_IDX), v_POS);
		ELSE
			-- add clause
			v_DML := v_DML||v_REL_PARTS(v_IDX);
		END IF;
		
		v_IDX := v_REL_PARTS.NEXT(v_IDX);
	END LOOP;
	
	-- Got it!
	RETURN v_DML;
	
END BUILD_SUBTABLE_DELETE;
-------------------------------------------------------------------------------
-- Forward declaration to support circular recursion
PROCEDURE IMPORT_SUBTABLE_DATA
	(
	p_PARENT_FIELDS	IN OUT NOCOPY UT.STRING_MAP,
	p_ENTITY_MAP	IN OUT NOCOPY t_ENTITY_ID_MAP,
	p_INDENT		IN VARCHAR2 := c_INDENT
	);
-------------------------------------------------------------------------------
-- Forward declaration to support circular recursion
PROCEDURE IMPORT_SUBTABLE_ROW
	(
	p_TABLE_NAME	IN VARCHAR2,
	p_ENTITY_MAP	IN OUT NOCOPY t_ENTITY_ID_MAP,
	p_INDENT		IN VARCHAR2 := c_INDENT
	) AS

v_LINE				VARCHAR2(4000);
v_DONE				BOOLEAN := FALSE;
v_FIELDS			UT.STRING_MAP;
v_FIELDS_COMPLETE	BOOLEAN := FALSE;
v_FLUSHED			BOOLEAN := FALSE;
v_POS				PLS_INTEGER;

	----------------------------------------------------------
	PROCEDURE FLUSH_ROW IS
	BEGIN
		IF NOT v_FLUSHED THEN
			v_FLUSHED := TRUE;
			-- resolve any other IDs
			RESOLVE_ENTITY_REFERENCES(v_FIELDS, p_ENTITY_MAP);
			-- insert new record
			INSERT_DATABASE_RECORD(p_TABLE_NAME, v_FIELDS);
		END IF;
	END FLUSH_ROW;
	----------------------------------------------------------
BEGIN
	WHILE NOT v_DONE LOOP
		ASSERT(NOT IS_EOF, 'Invalid ROML Import File. Subtable row definition incomplete.', MSGCODES.c_ERR_DATA_IMPORT);
		
		v_LINE := NEXT_LINE;
		
		IF v_LINE IS NOT NULL THEN -- ignore blank lines
		
			IF v_LINE = 'end row' THEN
				-- reached the end - flush the record
				FLUSH_ROW;
				v_DONE := TRUE;
				
			ELSIF v_LINE = 'begin subtable' THEN
				-- flush the record data before importing row's own sub-table data
				FLUSH_ROW;
				IMPORT_SUBTABLE_DATA(v_FIELDS, p_ENTITY_MAP, p_INDENT||c_INDENT);
				
			ELSE
				-- import the next field
				
				ASSERT(NOT v_FIELDS_COMPLETE, 'Invalid ROML Import File. Subtable row definition malformed: expecting "begin subtable" or "end row" tag.', MSGCODES.c_ERR_DATA_IMPORT);
				
				v_POS := INSTR(v_LINE, ':');
				v_FIELDS(SUBSTR(v_LINE,1,v_POS-1)) := SUBSTR(v_LINE,v_POS+1);
				
			END IF;
			
		END IF;

	END LOOP;
END IMPORT_SUBTABLE_ROW;
-------------------------------------------------------------------------------
-- Import sub-table data from the ROML file
PROCEDURE IMPORT_SUBTABLE_DATA
	(
	p_PARENT_FIELDS	IN OUT NOCOPY UT.STRING_MAP,
	p_ENTITY_MAP	IN OUT NOCOPY t_ENTITY_ID_MAP,
	p_INDENT		IN VARCHAR2 := c_INDENT
	) AS

v_LINE				VARCHAR2(4000);
v_DONE				BOOLEAN := FALSE;
v_TABLE_NAME		VARCHAR2(30);
v_RELATIONSHIP		VARCHAR2(4000);
v_FIELDS_COMPLETE	BOOLEAN := FALSE;
v_FLUSHED			BOOLEAN := FALSE;
v_ROWCOUNT			PLS_INTEGER := 0;

	----------------------------------------------------------
	PROCEDURE FLUSH_SUBTABLE IS
	v_DML	VARCHAR2(32767);
	BEGIN
		IF NOT v_FLUSHED THEN
			v_FLUSHED := TRUE;
			
			ASSERT(v_TABLE_NAME IS NOT NULL, 'Invalid ROML Import File. Subtable definition malformed: missing "table_name" attribute.', MSGCODES.c_ERR_DATA_IMPORT);
			ASSERT(v_RELATIONSHIP IS NOT NULL, 'Invalid ROML Import File. Subtable definition malformed: missing "relationship" attribute.', MSGCODES.c_ERR_DATA_IMPORT);
			
			IF LOGS.IS_DEBUG_ENABLED THEN
				LOGS.LOG_DEBUG(p_INDENT||'Importing data for '||v_TABLE_NAME);
			END IF;
			
			-- clear out existing child rows based on relationship
			v_DML := BUILD_SUBTABLE_DELETE(p_PARENT_FIELDS, v_TABLE_NAME, v_RELATIONSHIP);
			TRACE_DML(v_DML);
			EXECUTE IMMEDIATE v_DML;
			
			IF LOGS.IS_DEBUG_ENABLED THEN
				LOGS.LOG_DEBUG('Deleted '||SQL%ROWCOUNT||' row(s) in '||v_TABLE_NAME);
			END IF;
		END IF;
	END FLUSH_SUBTABLE;
	----------------------------------------------------------
BEGIN
	WHILE NOT v_DONE LOOP
		ASSERT(NOT IS_EOF, 'Invalid ROML Import File. Subtable definition incomplete.', MSGCODES.c_ERR_DATA_IMPORT);
		
		v_LINE := NEXT_LINE;
		
		IF v_LINE IS NOT NULL THEN -- ignore blank lines
		
			IF v_LINE = 'end subtable' THEN
				-- reached the end - flush if needed and exit
				FLUSH_SUBTABLE;
				IF LOGS.IS_DEBUG_ENABLED THEN
					LOGS.LOG_DEBUG(p_INDENT||'Inserted '||v_ROWCOUNT||' row(s) in '||v_TABLE_NAME);
				END IF;
				v_DONE := TRUE;
				
			ELSIF v_LINE = 'begin row' THEN
				-- flush if needed before re-building from row data
				FLUSH_SUBTABLE;
				IMPORT_SUBTABLE_ROW(v_TABLE_NAME, p_ENTITY_MAP, p_INDENT||c_INDENT);
				v_ROWCOUNT := v_ROWCOUNT+1;
				
			ELSE
				-- import the next field
				
				ASSERT(NOT v_FIELDS_COMPLETE, 'Invalid ROML Import File. Subtable definition malformed: expecting "begin row" or "end subtable" tag.', MSGCODES.c_ERR_DATA_IMPORT);
				
				IF SUBSTR(v_LINE,1,11) = 'table_name:' THEN
					v_TABLE_NAME := SUBSTR(v_LINE,12);
				ELSIF SUBSTR(v_LINE,1,13) = 'relationship:' THEN
					v_RELATIONSHIP := SUBSTR(v_LINE,14);
				ELSE
					ERRS.RAISE(MSGCODES.c_ERR_DATA_IMPORT, 'Invalid ROML Import File. Subtable definition malformed: expecting "table_name" or "relationship" attribute.');
				END IF;
				
			END IF;
			
		END IF;

	END LOOP;
END IMPORT_SUBTABLE_DATA;
-------------------------------------------------------------------------------
-- Import a single object from the ROML file
PROCEDURE IMPORT_SINGLE_OBJECT
	(
	p_ENTITY_MAP	IN OUT NOCOPY t_ENTITY_ID_MAP
	) IS
	
v_LINE				VARCHAR2(4000);
v_DONE				BOOLEAN := FALSE;
v_TABLE_NAME		VARCHAR2(30);
v_TABLE_ALIAS		VARCHAR2(30);
v_FIELDS			UT.STRING_MAP;
v_FIELDS_COMPLETE	BOOLEAN := FALSE;
v_FLUSHED			BOOLEAN := FALSE;
v_POS				PLS_INTEGER;

	----------------------------------------------------------
	PROCEDURE FLUSH_OBJECT IS
	v_SQL	VARCHAR2(32767);
	v_ID	NUMBER(9);
	BEGIN
		IF NOT v_FLUSHED THEN
			v_FLUSHED := TRUE;
			
			ASSERT(v_TABLE_NAME IS NOT NULL, 'Invalid ROML Import File. Object definition malformed: missing "table_name" attribute.', MSGCODES.c_ERR_DATA_IMPORT);
			ASSERT(v_TABLE_ALIAS IS NOT NULL, 'Invalid ROML Import File. Object definition malformed: missing "table_alias" attribute.', MSGCODES.c_ERR_DATA_IMPORT);
			
			-- first see if object exists - look-up by name
			v_SQL := 'SELECT MAX('||v_TABLE_ALIAS||'_ID) FROM '||v_TABLE_NAME||' WHERE '||v_TABLE_ALIAS||'_NAME = '
						||GET_LITERAL_VALUE(v_FIELDS, v_TABLE_ALIAS||'_NAME');
			EXECUTE IMMEDIATE v_SQL INTO v_ID;
			
			IF v_ID IS NULL THEN
				IF LOGS.IS_DEBUG_ENABLED THEN
					LOGS.LOG_DEBUG('Creating new '||v_TABLE_NAME||' object '||GET_LITERAL_VALUE(v_FIELDS, v_TABLE_ALIAS||'_NAME'));
				END IF;
				-- resolve any other IDs
				RESOLVE_ENTITY_REFERENCES(v_FIELDS, p_ENTITY_MAP);
				-- insert new record
				INSERT_DATABASE_RECORD(v_TABLE_NAME, v_FIELDS);
			ELSE
				IF LOGS.IS_DEBUG_ENABLED THEN
					LOGS.LOG_DEBUG('Updating '||v_TABLE_NAME||' object '||GET_LITERAL_VALUE(v_FIELDS, v_TABLE_ALIAS||'_NAME')
									||' (ID='||v_ID||')');
				END IF;
				-- add mapping for existing ID
				ADD_ENTITY(v_FIELDS(v_TABLE_ALIAS||'_ID'), v_ID, p_ENTITY_MAP);
				-- resolve any other IDs
				RESOLVE_ENTITY_REFERENCES(v_FIELDS, p_ENTITY_MAP);
				-- update existing record
				UPDATE_DATABASE_RECORD(v_TABLE_NAME, v_FIELDS, v_TABLE_ALIAS||'_ID', v_ID);
			END IF;
		END IF;
	END FLUSH_OBJECT;
	----------------------------------------------------------
BEGIN
	WHILE NOT v_DONE LOOP
		ASSERT(NOT IS_EOF, 'Invalid ROML Import File. Object definition incomplete.', MSGCODES.c_ERR_DATA_IMPORT);
		
		v_LINE := NEXT_LINE;
		
		IF v_LINE IS NOT NULL THEN -- ignore blank lines
		
			IF v_LINE = 'end object' THEN
				-- reached end of object
				-- make sure we've flushed object to database and then we're done
				FLUSH_OBJECT;
				v_DONE := TRUE;
				
			ELSIF v_LINE = 'begin subtable' THEN
				-- reached end of fields and start of sub-tables
				-- make sure we've flushed object and then process sub-table data
				FLUSH_OBJECT;
				v_FIELDS_COMPLETE := TRUE;
				IMPORT_SUBTABLE_DATA(v_FIELDS, p_ENTITY_MAP);
				
			ELSE
				-- import the next field
				
				ASSERT(NOT v_FIELDS_COMPLETE, 'Invalid ROML Import File. Object definition malformed: expecting "begin subtable" or "end object" tag.', MSGCODES.c_ERR_DATA_IMPORT);
				
				IF SUBSTR(v_LINE,1,11) = 'table_name:' THEN
					v_TABLE_NAME := SUBSTR(v_LINE,12);
				ELSIF SUBSTR(v_LINE,1,12) = 'table_alias:' THEN
					v_TABLE_ALIAS := SUBSTR(v_LINE,13);
				ELSE
					v_POS := INSTR(v_LINE, ':');
					v_FIELDS(SUBSTR(v_LINE,1,v_POS-1)) := SUBSTR(v_LINE,v_POS+1);
				END IF;
				
			END IF;
			
		END IF;
	END LOOP;
END IMPORT_SINGLE_OBJECT;
-------------------------------------------------------------------------------
-- Import the specified ROML file
PROCEDURE DO_IMPORT
	(
	p_IMPORT_FILE		IN CLOB,
	p_IMPORT_FILE_PATH	IN VARCHAR2,
	p_TRACE_ON 			IN NUMBER,
	p_PROCESS_ID 		OUT VARCHAR2,
	p_PROCESS_STATUS 	OUT NUMBER,
	p_MESSAGE 			OUT VARCHAR2
	) IS

v_ENTITY_MAP	t_ENTITY_ID_MAP;
v_LINE			VARCHAR2(4000);

BEGIN

	SAVEPOINT BEFORE_IMPORT;
	
	LOGS.START_PROCESS('Import ROML Data', p_TRACE_ON => p_TRACE_ON);
	LOGS.SET_PROCESS_TARGET_PARAMETER('Import File Name', p_IMPORT_FILE_PATH);

	-- Security check!
	SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_ROML_PUB_SUB);

	-- Read the file
	INIT(p_IMPORT_FILE);

	-- And start importing
	WHILE NOT IS_EOF LOOP
		v_LINE := NEXT_LINE;
		IF v_LINE IS NOT NULL THEN -- ignore blank lines
			-- currently, only objects are allowed as "top-level" tags in ROML
			ASSERT(v_LINE = 'begin object', 'Invalid ROML Import File. Document malformed: expecting "begin object" tag.', MSGCODES.c_ERR_DATA_IMPORT);
			IMPORT_SINGLE_OBJECT(v_ENTITY_MAP);
		END IF;
	END LOOP;
	
	-- Done!
	RESET; -- clear variables when done
	p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;
	LOGS.STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);
	COMMIT;
	
EXCEPTION
	WHEN OTHERS THEN
		RESET; -- clear variables when done
		ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'BEFORE_IMPORT');

END DO_IMPORT;
-------------------------------------------------------------------------------
END ROML_IMPORT;
/
