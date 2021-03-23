CREATE OR REPLACE PACKAGE ROML_EXPORT IS
-- $Revision: 1.3 $

  -- Author  : JHUMPHRIES
  -- Created : 4/26/2010 5:05:41 PM
  -- Purpose : Export table data to ROML file: Retail Operations Markup Language
  -- 			(non-XML proprietary text format)

FUNCTION WHAT_VERSION RETURN VARCHAR2;

PROCEDURE DO_EXPORT
	(
	p_ROML_ENTITY_NID 	IN NUMBER,
	p_ENTITY_IDs 		IN NUMBER_COLLECTION,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_INCLUDE_DATA 		IN NUMBER,
	p_TRACE_ON 			IN NUMBER,
	p_FILE				OUT CLOB,
	p_PROCESS_ID 		OUT VARCHAR2,
	p_PROCESS_STATUS 	OUT NUMBER,
	p_MESSAGE 			OUT VARCHAR2
	);

FUNCTION ROML_METADATA_DML RETURN CLOB;

END ROML_EXPORT;
/
CREATE OR REPLACE PACKAGE BODY ROML_EXPORT IS
-------------------------------------------------------------------------------
-- Used to generically model record data to more easily handle the data
-- returned from native dynamic queries without having to resort to the
-- more complicated DBMS_SQL APIs.
TYPE t_NAME_LIST IS TABLE OF VARCHAR2(30);
TYPE t_NAME_MAP IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(30);
TYPE t_TABLE_METADATA IS RECORD (
	NAMES		t_NAME_LIST,
	POSITIONS	t_NAME_MAP,
	TYPES		UT.STRING_MAP
);

-- date format for internal representation of dates as strings
c_DATE_FMT	CONSTANT VARCHAR2(32) := 'YYYYMMDDHH24MISS';

-- "Tab stop" used for indentation of resulting ROML file and for indenting log messages
-- to make trace log easier to read
c_INDENT	CONSTANT VARCHAR2(4) := '    ';

-- Prefixes used for representing literal values in ROML file
c_ROML_NUM	CONSTANT CHAR(1) := '#';
c_ROML_DATE	CONSTANT CHAR(1) := '@';
c_ROML_STR	CONSTANT CHAR(1) := '"';
c_ROML_REF	CONSTANT CHAR(1) := '*';

-- NULL representation in ROML
c_ROML_NULL	CONSTANT VARCHAR2(4) := c_ROML_STR;

-- date format for ROML representation of dates
c_ROML_FMT	CONSTANT VARCHAR2(32) := 'MON-DD-YYYY HH24:MI:SS';

-- Sequence number used for generating unique identifiers recorded to ROML file
g_SEQ_NBR	PLS_INTEGER := 0;
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
-------------------------------------------------------------------------------
-- Text "descriptor" for an ROML Entity - used for logging
FUNCTION GET_DESCRIPTOR(p_TABLE_NAME IN VARCHAR2, p_ENTITY_NAME IN VARCHAR2, p_ENTITY_ID IN NUMBER)
RETURN VARCHAR2 IS
BEGIN
	RETURN p_TABLE_NAME||': '||p_ENTITY_NAME||' (ID='||p_ENTITY_ID||')';
END GET_DESCRIPTOR;
-------------------------------------------------------------------------------
-- Does specified entity already exist in the work table?
FUNCTION EXISTS_IN_WORK
	(
	p_ROML_ENTITY_NID IN NUMBER,
	p_ENTITY_ID IN NUMBER
	) RETURN BOOLEAN AS
v_COUNT PLS_INTEGER;
BEGIN
	SELECT COUNT(1)
	INTO v_COUNT
	FROM ROML_WORK
	WHERE ROML_ENTITY_NID = p_ROML_ENTITY_NID
		AND ENTITY_ID = p_ENTITY_ID;
		
	RETURN v_COUNT <> 0;
END EXISTS_IN_WORK;
-------------------------------------------------------------------------------
-- Store specified entity into the work table
PROCEDURE STORE_TO_WORK
	(
	p_ROML_ENTITY_NID IN NUMBER,
	p_TABLE_NAME IN VARCHAR2,
	p_TABLE_ALIAS IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2
	) AS
BEGIN
	IF NOT EXISTS_IN_WORK(p_ROML_ENTITY_NID, p_ENTITY_ID) THEN
		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('Storing entity for export - '||GET_DESCRIPTOR(p_TABLE_NAME, p_ENTITY_NAME, p_ENTITY_ID));
		END IF;
		INSERT INTO ROML_WORK
			(ROML_ENTITY_NID, TABLE_NAME, TABLE_ALIAS, ENTITY_ID, ENTITY_NAME)
		VALUES
			(p_ROML_ENTITY_NID, p_TABLE_NAME, p_TABLE_ALIAS, p_ENTITY_ID, p_ENTITY_NAME);
	END IF;
END STORE_TO_WORK;
-------------------------------------------------------------------------------
-- Retrieve metadata (column names, positions, and types) for specified table
FUNCTION GET_TABLE_METADATA
	(
	p_TABLE_NAME IN VARCHAR2
	) RETURN t_TABLE_METADATA IS
v_NAMES	STRING_COLLECTION;
v_TYPES	STRING_COLLECTION;
v_IDX	PLS_INTEGER;
v_JDX	PLS_INTEGER;
v_RET	t_TABLE_METADATA;
BEGIN
	SELECT U.COLUMN_NAME, U.DATA_TYPE
	BULK COLLECT INTO v_NAMES, v_TYPES
	FROM USER_TAB_COLS U
	WHERE U.TABLE_NAME = p_TABLE_NAME
	ORDER BY U.COLUMN_ID;
	
	v_IDX := v_NAMES.FIRST;
	v_JDX := 1;
	v_RET.NAMES := t_NAME_LIST(); -- initialize table (not needed for
								  -- other fields since INDEX BY tables
								  -- do not require initialization)
	WHILE v_NAMES.EXISTS(v_IDX) LOOP
		v_RET.NAMES.EXTEND;
		v_RET.NAMES(v_RET.NAMES.LAST) := v_NAMES(v_IDX);
		v_RET.POSITIONS(v_NAMES(v_IDX)) := v_JDX;
		v_RET.TYPES(v_NAMES(v_IDX)) := v_TYPES(v_IDX);
		v_JDX := v_JDX+1;
		v_IDX := v_NAMES.NEXT(v_IDX);
	END LOOP;
	
	RETURN v_RET;
END GET_TABLE_METADATA;
-------------------------------------------------------------------------------
-- Retrieve data type for specified column given specified table metadata
FUNCTION GET_COL_TYPE
	(
	p_METADATA		IN OUT NOCOPY t_TABLE_METADATA,
	p_COLUMN_NAME	IN VARCHAR2
	) RETURN VARCHAR2 IS
BEGIN
	RETURN p_METADATA.TYPES(p_COLUMN_NAME);
END GET_COL_TYPE;
-------------------------------------------------------------------------------
-- Retrieve SELECT clause for specified table metadata. This will result in
-- querying all fields as strings into a STRING_COLLECTION.
FUNCTION GET_SQL_FIELDS
	(
	p_METADATA IN OUT NOCOPY t_TABLE_METADATA
	) RETURN VARCHAR2 IS
v_RET	VARCHAR2(32767);
v_IDX	PLS_INTEGER;
v_FIRST	BOOLEAN := TRUE;
BEGIN
	v_RET := 'STRING_COLLECTION(';
	-- build list of column names, converting to string if needed
	v_IDX := p_METADATA.NAMES.FIRST;
	WHILE p_METADATA.NAMES.EXISTS(v_IDX) LOOP
		IF NOT v_FIRST THEN
			v_RET := v_RET||', ';
		ELSE
			v_FIRST := FALSE;
		END IF;
		
		v_RET := v_RET||CASE GET_COL_TYPE(p_METADATA, p_METADATA.NAMES(v_IDX))
						WHEN 'NUMBER' THEN
							'TO_CHAR('||p_METADATA.NAMES(v_IDX)||')'
						WHEN 'DATE' THEN
							'TO_CHAR('||p_METADATA.NAMES(v_IDX)||', '||UT.GET_LITERAL_FOR_STRING(c_DATE_FMT)||')'
						ELSE
							p_METADATA.NAMES(v_IDX)
						END;
						
		v_IDX := p_METADATA.NAMES.NEXT(v_IDX);
	END LOOP;
	v_RET := v_RET||')';
	
	RETURN v_RET;
END GET_SQL_FIELDS;
-------------------------------------------------------------------------------
-- Retrieve VARCHAR2 value for specified column given specified table metadata
-- and record values
FUNCTION GET_COL_VAL_STRING
	(
	p_VALUES		IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA		IN OUT NOCOPY t_TABLE_METADATA,
	p_COLUMN_NAME	IN VARCHAR2
	) RETURN VARCHAR2 IS
BEGIN
	RETURN p_VALUES(p_METADATA.POSITIONS(p_COLUMN_NAME));
END GET_COL_VAL_STRING;
-------------------------------------------------------------------------------
-- Retrieve NUMBER value for specified column given specified table metadata
-- and record values
FUNCTION GET_COL_VAL_NUMBER
	(
	p_VALUES		IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA		IN OUT NOCOPY t_TABLE_METADATA,
	p_COLUMN_NAME	IN VARCHAR2
	) RETURN NUMBER IS
BEGIN
	RETURN TO_NUMBER(GET_COL_VAL_STRING(p_VALUES, p_METADATA, p_COLUMN_NAME));
END GET_COL_VAL_NUMBER;
-------------------------------------------------------------------------------
-- Retrieve DATE value for specified column given specified table metadata
-- and record values
FUNCTION GET_COL_VAL_DATE
	(
	p_VALUES		IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA		IN OUT NOCOPY t_TABLE_METADATA,
	p_COLUMN_NAME	IN VARCHAR2
	) RETURN DATE IS
BEGIN
	RETURN TO_DATE(GET_COL_VAL_STRING(p_VALUES, p_METADATA, p_COLUMN_NAME), c_DATE_FMT);
END GET_COL_VAL_DATE;
-------------------------------------------------------------------------------
-- Retrieve value for specified column given specified table metadata and
-- record values as a PL-SQL literal string
FUNCTION GET_COL_VAL_LITERAL
	(
	p_VALUES		IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA		IN OUT NOCOPY t_TABLE_METADATA,
	p_COLUMN_NAME	IN VARCHAR2
	) RETURN VARCHAR2 IS
BEGIN
	CASE GET_COL_TYPE(p_METADATA, p_COLUMN_NAME)
	WHEN 'NUMBER' THEN
		RETURN UT.GET_LITERAL_FOR_NUMBER( GET_COL_VAL_NUMBER(p_VALUES, p_METADATA, p_COLUMN_NAME) );
	WHEN 'DATE' THEN
		RETURN UT.GET_LITERAL_FOR_DATE( GET_COL_VAL_DATE(p_VALUES, p_METADATA, p_COLUMN_NAME) );
	ELSE
		RETURN UT.GET_LITERAL_FOR_STRING( GET_COL_VAL_STRING(p_VALUES, p_METADATA, p_COLUMN_NAME) );
	END CASE;
END GET_COL_VAL_LITERAL;
-------------------------------------------------------------------------------
-- Retrieve value for specified column given specified table metadata and
-- record values as a PL-SQL literal string
FUNCTION GET_COL_VAL_ROML
	(
	p_VALUES		IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA		IN OUT NOCOPY t_TABLE_METADATA,
	p_COLUMN_NAME	IN VARCHAR2
	) RETURN VARCHAR2 IS
v_VAL	VARCHAR2(4000) := GET_COL_VAL_STRING(p_VALUES, p_METADATA, p_COLUMN_NAME);
BEGIN
	IF v_VAL IS NULL THEN
		RETURN c_ROML_NULL;
	ELSE
		CASE GET_COL_TYPE(p_METADATA, p_COLUMN_NAME)
		WHEN 'DATE' THEN
			RETURN c_ROML_DATE||TO_CHAR( GET_COL_VAL_DATE(p_VALUES, p_METADATA, p_COLUMN_NAME), c_ROML_FMT );
		WHEN 'NUMBER' THEN
			RETURN c_ROML_NUM||v_VAL;
		ELSE
			RETURN c_ROML_STR||REPLACE(REPLACE(REPLACE(v_VAL,'\','\\'),CHR(10),'\n'),CHR(13),'\r');
		END CASE;
	END IF;
END GET_COL_VAL_ROML;
-------------------------------------------------------------------------------
-- Buld string of comma-separated column names
FUNCTION GET_COLUMN_NAMES
	(
	p_METADATA	IN OUT NOCOPY t_TABLE_METADATA
	) RETURN VARCHAR2 IS
v_RET	VARCHAR2(32767);
v_IDX	PLS_INTEGER;
BEGIN
	v_IDX := p_METADATA.NAMES.FIRST;
	WHILE p_METADATA.NAMES.EXISTS(v_IDX) LOOP
		IF v_RET IS NOT NULL THEN
			v_RET := v_RET||', ';
		END IF;
		v_RET := v_RET||p_METADATA.NAMES(v_IDX);
		v_IDX := p_METADATA.NAMES.NEXT(v_IDX);
	END LOOP;
	
	RETURN v_RET;
END GET_COLUMN_NAMES;
-------------------------------------------------------------------------------
-- Buld string of name=value pairs describing the record data
FUNCTION TO_CHAR_VALUES
	(
	p_VALUES	IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA	IN OUT NOCOPY t_TABLE_METADATA
	) RETURN VARCHAR2 IS
v_RET	VARCHAR2(32767);
v_IDX	PLS_INTEGER;
BEGIN
	v_IDX := p_METADATA.NAMES.FIRST;
	WHILE p_METADATA.NAMES.EXISTS(v_IDX) LOOP
		IF v_RET IS NOT NULL THEN
			v_RET := v_RET||', ';
		END IF;
		v_RET := v_RET||p_METADATA.NAMES(v_IDX)||'='
				||GET_COL_VAL_ROML(p_VALUES, p_METADATA, p_METADATA.NAMES(v_IDX));
		v_IDX := p_METADATA.NAMES.NEXT(v_IDX);
	END LOOP;
	
	RETURN v_RET;
END TO_CHAR_VALUES;
-------------------------------------------------------------------------------
-- Generate query to get child records for given entity and given child table
FUNCTION BUILD_SQL_FOR_SUBTABLE_ROWS
	(
	p_PARENT_VALUES		IN OUT NOCOPY STRING_COLLECTION,
	p_PARENT_METADATA	IN OUT NOCOPY t_TABLE_METADATA,
	p_TABLE_NAME		IN VARCHAR2,
	p_RELATIONSHIP		IN OUT VARCHAR2,
	p_DATE1_COL			IN VARCHAR2,
	p_DATE2_COL			IN VARCHAR2,
	p_CHILD_METADATA	IN OUT NOCOPY t_TABLE_METADATA,
	p_BEGIN_DATE		IN DATE,
	p_END_DATE			IN DATE
	) RETURN VARCHAR2 IS

v_SQL			VARCHAR2(32767);
v_REL_PARTS		GA.STRING_TABLE;
v_MAIN_JOINS	GA.STRING_TABLE;
v_JOIN_FIELDS	GA.STRING_TABLE;
v_IDX			PLS_INTEGER;
v_NEW_FIELD		VARCHAR2(30);
v_OLD_FIELD		VARCHAR2(30);
v_FIRST			BOOLEAN := TRUE;
v_POS			PLS_INTEGER;
v_TOKEN			VARCHAR2(32);
v_DATE_JOIN		VARCHAR2(4000);
	------------------------------------------------
	-- Append "AND" to query if needed
	PROCEDURE ADD_AND IS
	BEGIN
		IF v_FIRST THEN
			v_FIRST := FALSE;
		ELSE
			v_SQL := v_SQL||' AND ';
		END IF;
	END ADD_AND;
	------------------------------------------------
BEGIN
	v_SQL := 'SELECT '||GET_SQL_FIELDS(p_CHILD_METADATA)||' FROM '||p_TABLE_NAME||' WHERE';
	
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
			v_SQL := v_SQL||' '||v_NEW_FIELD||' = '||GET_COL_VAL_LITERAL(p_PARENT_VALUES, p_PARENT_METADATA, v_OLD_FIELD);

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
			v_SQL := v_SQL||GET_COL_VAL_LITERAL(p_PARENT_VALUES, p_PARENT_METADATA, v_TOKEN)||SUBSTR(v_REL_PARTS(v_IDX), v_POS);
		ELSE
			-- add clause
			v_SQL := v_SQL||v_REL_PARTS(v_IDX);
		END IF;
		
		v_IDX := v_REL_PARTS.NEXT(v_IDX);
	END LOOP;

	-- date range clause
    If p_DATE1_COL IS NOT NULL THEN
		IF p_DATE2_COL IS NOT NULL THEN
			v_DATE_JOIN := p_DATE1_COL||' <= '||UT.GET_LITERAL_FOR_DATE(NVL(p_END_DATE, CONSTANTS.HIGH_DATE))
					||' AND NVL('||p_DATE2_COL||', DATE ''9999-12-31'') >= '||UT.GET_LITERAL_FOR_DATE(NVL(p_BEGIN_DATE, CONSTANTS.LOW_DATE));
		ELSE
			v_DATE_JOIN := p_DATE1_COL||' BETWEEN '||UT.GET_LITERAL_FOR_DATE(NVL(p_BEGIN_DATE, CONSTANTS.LOW_DATE))
					||' AND '||UT.GET_LITERAL_FOR_DATE(NVL(p_END_DATE, CONSTANTS.HIGH_DATE));
		END IF;
		
		ADD_AND;
		v_SQL := v_SQL||v_DATE_JOIN;
        -- add this to the relation string so we'll have this criteria at import time.
        -- that way we won't delete too much (i.e. we won't accidentally delete data outside
        -- date range that exists in the file)
        p_RELATIONSHIP := p_RELATIONSHIP||';'||v_DATE_JOIN;
	END IF;
	
	-- Finally, add ordering to the query
	v_SQL := v_SQL||' ORDER BY '||GET_COLUMN_NAMES(p_CHILD_METADATA);

	-- Got it!
	RETURN v_SQL;

END BUILD_SQL_FOR_SUBTABLE_ROWS;
-------------------------------------------------------------------------------
-- Dump SQL text to log
PROCEDURE TRACE_SQL
	(
	p_SQL IN VARCHAR2
	) AS
BEGIN
	IF LOGS.IS_DEBUG_MORE_DETAIL_ENABLED THEN
		LOGS.LOG_INFO_MORE_DETAIL('Issuing dynamic SQL. See attachment for SQL text');
		LOGS.POST_EVENT_DETAILS('SQL Text', CONSTANTS.MIME_TYPE_TEXT, p_SQL);
	END IF;
END TRACE_SQL;
-------------------------------------------------------------------------------
-- Get entity definition as a cursor (with a single row)
PROCEDURE GET_ENTITY_AS_CURSOR
	(
	p_TABLE_NAME 	IN VARCHAR2,
	p_TABLE_ALIAS	IN VARCHAR2,
	p_ENTITY_ID		IN VARCHAR2,
	p_METADATA		OUT t_TABLE_METADATA,
	p_CURSOR		OUT GA.REFCURSOR
	) AS
v_SQL	VARCHAR2(32767);
BEGIN
	p_METADATA := GET_TABLE_METADATA(p_TABLE_NAME);
	v_SQL := 'SELECT '||GET_SQL_FIELDS(p_METADATA)||' FROM '||p_TABLE_NAME||' WHERE '||p_TABLE_ALIAS||'_ID = '||p_ENTITY_ID;
	TRACE_SQL(v_SQL);
	OPEN p_CURSOR FOR v_SQL;
END GET_ENTITY_AS_CURSOR;
-------------------------------------------------------------------------------
-- Get entity definition as a collection of field values
PROCEDURE GET_ENTITY_AS_COLL
	(
	p_TABLE_NAME 	IN VARCHAR2,
	p_TABLE_ALIAS	IN VARCHAR2,
	p_ENTITY_ID		IN VARCHAR2,
	p_METADATA		OUT t_TABLE_METADATA,
	p_VALUES		OUT STRING_COLLECTION
	) AS
v_CURSOR	GA.REFCURSOR;
BEGIN
	GET_ENTITY_AS_CURSOR(p_TABLE_NAME, p_TABLE_ALIAS, p_ENTITY_ID, p_METADATA, v_CURSOR);
	FETCH v_CURSOR INTO p_VALUES;
	IF v_CURSOR%NOTFOUND THEN
		p_VALUES := NULL;
	END IF;
	CLOSE v_CURSOR;
END GET_ENTITY_AS_COLL;
-------------------------------------------------------------------------------
-- Forward declaration to support circular recursion
PROCEDURE GET_DEPENDENCIES
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_ENTITY_ID 		IN NUMBER,
	p_TABLE_NAME 		IN VARCHAR2,
	p_TABLE_ALIAS 		IN VARCHAR2,
	p_ENTITY_NAME 		IN VARCHAR2,
	p_INCLUDE_DATA 		IN BOOLEAN,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_INDENT			IN VARCHAR2 := ''
	);
-------------------------------------------------------------------------------
-- Enumerates dependencies of specified entity that are found in specified 
-- cursor of records. This will recursively traverse dependency graph and store
-- entities to the work table as it goes in addition to identifying all
-- dependency relationships.
PROCEDURE GET_DEPENDENT_OBJECTS
	(
	p_PARENT_ENTITY_NID	IN NUMBER,
	p_ENTITY_ID			IN NUMBER,
	p_ENTITY_DESC		IN VARCHAR2,
	p_INDENT			IN VARCHAR2,
	p_CUR_ENTITY_NID	IN NUMBER,
	p_CUR_METADATA		IN OUT NOCOPY t_TABLE_METADATA,
	p_INCLUDE_DATA 		IN BOOLEAN,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_RECORDS			IN OUT NOCOPY GA.REFCURSOR
	) AS

v_VALS				STRING_COLLECTION;
v_INCLUDE_DATA		NUMBER(1) := UT.NUMBER_FROM_BOOLEAN(p_INCLUDE_DATA);
v_SQL				VARCHAR2(32767);
v_CHILD_RECORDS		GA.REFCURSOR;
v_CHILD_VALS		STRING_COLLECTION;
v_CHILD_ID			NUMBER(9);
v_CHILD_NAME		VARCHAR2(4000);
v_CHILD_METADATA	t_TABLE_METADATA;
v_COUNT				PLS_INTEGER;

BEGIN
	-- loop over all incoming records
	LOOP
		FETCH p_RECORDS INTO v_VALS;
		EXIT WHEN p_RECORDS%NOTFOUND;

		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG(p_INDENT||'Finding dependencies for '||TO_CHAR_VALUES(v_VALS, p_CUR_METADATA));
		END IF;

		-- for each record, loop through all dependent tables...
		FOR v_DEPS IN (SELECT B.ROML_ENTITY_NID, B.TABLE_NAME, B.TABLE_ALIAS,
							B.DATE1_COL, B.DATE2_COL, B.IS_OBJECT, A.RELATIONSHIP
						FROM ROML_ENTITY_DEPENDS A, ROML_ENTITY B
						WHERE A.ROML_ENTITY_NID = p_CUR_ENTITY_NID
							AND B.ROML_ENTITY_NID = A.DEP_ROML_ENTITY_NID
							AND (NVL(B.IS_DATA,0) = 0 OR v_INCLUDE_DATA = 1)) LOOP
							
			IF LOGS.IS_DEBUG_ENABLED THEN
				LOGS.LOG_DEBUG(p_INDENT||'Searching for references in '||v_DEPS.TABLE_NAME);
			END IF;

			v_CHILD_METADATA := GET_TABLE_METADATA(v_DEPS.TABLE_NAME);
			
			v_SQL := BUILD_SQL_FOR_SUBTABLE_ROWS(v_VALS, p_CUR_METADATA,
												v_DEPS.TABLE_NAME, v_DEPS.RELATIONSHIP,
												v_DEPS.DATE1_COL, v_DEPS.DATE2_COL,
												v_CHILD_METADATA,
												p_BEGIN_DATE, p_END_DATE);
			TRACE_SQL(v_SQL);
			OPEN v_CHILD_RECORDS FOR v_SQL;
			
			IF UT.BOOLEAN_FROM_NUMBER(v_DEPS.IS_OBJECT) THEN
				LOOP
					FETCH v_CHILD_RECORDS INTO v_CHILD_VALS;
					EXIT WHEN v_CHILD_RECORDS%NOTFOUND;
					
					v_CHILD_ID := GET_COL_VAL_NUMBER(v_CHILD_VALS, v_CHILD_METADATA, v_DEPS.TABLE_ALIAS||'_ID');
					v_CHILD_NAME := GET_COL_VAL_STRING(v_CHILD_VALS, v_CHILD_METADATA, v_DEPS.TABLE_ALIAS||'_NAME');

					IF v_CHILD_ID = CONSTANTS.NOT_ASSIGNED THEN
						-- don't bother exporting the dependency tree for 'Not Assigned' entities
						IF LOGS.IS_DEBUG_ENABLED THEN
							LOGS.LOG_DEBUG(p_INDENT||'Skipping not assigned entity - '||GET_DESCRIPTOR(v_DEPS.TABLE_NAME, v_CHILD_NAME, v_CHILD_ID));
						END IF;
					ELSE
						-- have we already added this edge to the dependency tree?
						SELECT COUNT(1)
						INTO v_COUNT
						FROM ROML_WORK_DEP
						WHERE ROML_ENTITY_NID = p_PARENT_ENTITY_NID
							AND ENTITY_ID = p_ENTITY_ID
							AND DEP_ROML_ENTITY_NID = v_DEPS.ROML_ENTITY_NID
							AND DEP_ENTITY_ID = v_CHILD_ID;
						-- if not, add it now
						IF v_COUNT = 0 THEN
							INSERT INTO ROML_WORK_DEP
								(ROML_ENTITY_NID, ENTITY_ID, DEP_ROML_ENTITY_NID, DEP_ENTITY_ID)
							VALUES
								(p_PARENT_ENTITY_NID, p_ENTITY_ID, v_DEPS.ROML_ENTITY_NID, v_CHILD_ID);
						END IF;
						
						-- now get dependency tree for this object
						GET_DEPENDENCIES(v_DEPS.ROML_ENTITY_NID, v_CHILD_ID, v_DEPS.TABLE_NAME, v_DEPS.TABLE_ALIAS,
											v_CHILD_NAME, p_INCLUDE_DATA, p_BEGIN_DATE, p_END_DATE, p_INDENT);
					END IF;
				END LOOP;
				-- clean-up
				CLOSE v_CHILD_RECORDS;
			ELSE
				-- keep recursing, searching for referenced entities
				GET_DEPENDENT_OBJECTS(p_PARENT_ENTITY_NID, p_ENTITY_ID,
										p_ENTITY_DESC, p_INDENT||c_INDENT,
										v_DEPS.ROML_ENTITY_NID,
										v_CHILD_METADATA,
										p_INCLUDE_DATA, p_BEGIN_DATE, p_END_DATE,
										v_CHILD_RECORDS);
			END IF;
		END LOOP;
	END LOOP;
	-- Clean-up	
	CLOSE p_RECORDS;
END GET_DEPENDENT_OBJECTS;
-------------------------------------------------------------------------------
-- Enumerate the dependencies for the given entity. This will store the entity
-- to the work table and continue to traverse the dependency graph, storing
-- dependent entities in the work table and identifying the dependency graph.
PROCEDURE GET_DEPENDENCIES
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_ENTITY_ID 		IN NUMBER,
	p_TABLE_NAME 		IN VARCHAR2,
	p_TABLE_ALIAS 		IN VARCHAR2,
	p_ENTITY_NAME 		IN VARCHAR2,
	p_INCLUDE_DATA 		IN BOOLEAN,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_INDENT			IN VARCHAR2 := ''
	) AS

v_METADATA	t_TABLE_METADATA;
v_CURSOR	GA.REFCURSOR;
v_DESC		VARCHAR2(4000) := GET_DESCRIPTOR(p_TABLE_NAME, p_ENTITY_NAME, p_ENTITY_ID);

BEGIN
	IF EXISTS_IN_WORK(p_ROML_ENTITY_NID, p_ENTITY_ID) THEN
		-- already have this object - no need to recurse further
		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG(p_INDENT||'Entity already in export workset - '||GET_DESCRIPTOR(p_TABLE_NAME, p_ENTITY_NAME, p_ENTITY_ID));
		END IF;
		
		RETURN;
	ELSE
		STORE_TO_WORK(p_ROML_ENTITY_NID, p_TABLE_NAME, p_TABLE_ALIAS, p_ENTITY_ID, p_ENTITY_NAME);
	END IF;

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG(p_INDENT||'Gathering dependencies for '||v_DESC);
	END IF;

	-- now get dependents using the resulting data for this entity
	GET_ENTITY_AS_CURSOR(p_TABLE_NAME, p_TABLE_ALIAS, p_ENTITY_ID, v_METADATA, v_CURSOR);

	GET_DEPENDENT_OBJECTS(p_ROML_ENTITY_NID, p_ENTITY_ID, v_DESC, p_INDENT||c_INDENT, p_ROML_ENTITY_NID,
							v_METADATA, p_INCLUDE_DATA, p_BEGIN_DATE, p_END_DATE, v_CURSOR);

END GET_DEPENDENCIES;
-------------------------------------------------------------------------------
-- Utility method to simply write a line of text to a CLOB
PROCEDURE WRITE_TO_CLOB
	(
	p_CLOB	IN OUT NOCOPY CLOB,
	p_TEXT	IN VARCHAR2
	) AS
BEGIN
	DBMS_LOB.WRITEAPPEND(p_CLOB, LENGTH(p_TEXT||UTL_TCP.CRLF), p_TEXT||UTL_TCP.CRLF);
END WRITE_TO_CLOB;
-------------------------------------------------------------------------------
-- Determines correct WORK_ORDER values for entries in work table based on
-- dependencies. Lower WORK_ORDER entities should be exported first as their
-- definition is required by entities with higher WORK_ORDER values.
PROCEDURE ORDER_WORK_TABLE
	(
	p_ORDER IN PLS_INTEGER := 1
	) AS
v_COUNT		PLS_INTEGER := 0;
v_DETAILS	CLOB;
BEGIN
	UPDATE ROML_WORK W
	SET W.WORK_ORDER = p_ORDER
	-- find all objects that have no remaining dependencies
	WHERE W.WORK_ORDER IS NULL
		AND NOT EXISTS (SELECT 1
						FROM ROML_WORK_DEP D
						WHERE D.ROML_ENTITY_NID = W.ROML_ENTITY_NID
							AND D.ENTITY_ID = W.ENTITY_ID);

	IF SQL%NOTFOUND THEN
		-- no more things to export? make sure set of "remaining"/unordered items is empty.
		-- if not, then there is a cycle that prevents some objects from being exported
		DBMS_LOB.CREATETEMPORARY(v_DETAILS, TRUE);
		DBMS_LOB.OPEN(v_DETAILS, DBMS_LOB.LOB_READWRITE);
		FOR v_ENTITY IN (SELECT *
						 FROM ROML_WORK
						 WHERE WORK_ORDER IS NULL
						 ORDER BY TABLE_NAME, ENTITY_NAME) LOOP
			v_COUNT := v_COUNT+1;
			WRITE_TO_CLOB(v_DETAILS, GET_DESCRIPTOR(v_ENTITY.TABLE_NAME, v_ENTITY.ENTITY_NAME, v_ENTITY.ENTITY_ID)||' depends on:');
			FOR v_DEP_ENTITY IN (SELECT W.*
								 FROM ROML_WORK_DEP D,
								 	ROML_WORK W
								 WHERE D.ROML_ENTITY_NID = v_ENTITY.ROML_ENTITY_NID
								 	AND D.ENTITY_ID = v_ENTITY.ENTITY_ID
									AND W.ROML_ENTITY_NID = D.DEP_ROML_ENTITY_NID
									AND W.ENTITY_ID = D.DEP_ENTITY_ID
								 ORDER BY W.TABLE_NAME, W.ENTITY_NAME, W.ENTITY_ID) LOOP
				WRITE_TO_CLOB(v_DETAILS, '    '||GET_DESCRIPTOR(v_DEP_ENTITY.TABLE_NAME, v_DEP_ENTITY.ENTITY_NAME, v_DEP_ENTITY.ENTITY_ID));
			END LOOP;
		END LOOP;
		DBMS_LOB.CLOSE(v_DETAILS);
		
		IF v_COUNT > 0 THEN
			DELETE ROML_WORK WHERE WORK_ORDER IS NULL; -- clear them out so they are excluded from final export
			
			LOGS.LOG_ERROR('Not all objects could be exported due to circular references that cannot be resolved. See attachment for more details.');
			LOGS.POST_EVENT_DETAILS('Unresolved/circular references', CONSTANTS.MIME_TYPE_TEXT, v_DETAILS);
		END IF;
	ELSE
		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('Updated '||SQL%ROWCOUNT||' entities with order = '||p_ORDER||'.');
		END IF;
		-- remove dependencies associated with these objects
		DELETE ROML_WORK_DEP D
		WHERE (D.DEP_ROML_ENTITY_NID,D.DEP_ENTITY_ID) IN (SELECT W.ROML_ENTITY_NID, W.ENTITY_ID
															FROM ROML_WORK W
															WHERE W.WORK_ORDER = p_ORDER);
		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG('Cleared '||SQL%ROWCOUNT||' dependencies for newly orded entities.');
		END IF;
		-- now recurse
		ORDER_WORK_TABLE(p_ORDER+1);
	END IF;
END ORDER_WORK_TABLE;
-------------------------------------------------------------------------------
-- Resets sequence used to generate internal identifiers in ROML file
PROCEDURE RESET_SEQ_NBR IS
BEGIN
	g_SEQ_NBR := 0;
END RESET_SEQ_NBR;
-------------------------------------------------------------------------------
-- Gets the next seqeuence value to use for identifiers in ROML file
FUNCTION NEXT_SEQ_NBR RETURN PLS_INTEGER IS
BEGIN
	g_SEQ_NBR := g_SEQ_NBR+1;
	RETURN g_SEQ_NBR;
END NEXT_SEQ_NBR;
-------------------------------------------------------------------------------
-- Add "identifier" - used to reference objects in ROML file - to map so that
-- we re-use same identifier in other places in file that reference this entity
PROCEDURE ADD_ENTITY_IDENTIFIER
	(
	p_TABLE_NAME	IN VARCHAR2,
	p_ENTITY_ID		IN NUMBER,
	p_MAP			IN OUT NOCOPY UT.STRING_MAP,
	p_SEQUENCE		IN VARCHAR2 := NULL
	) IS
v_SEQ_NBR	PLS_INTEGER := NEXT_SEQ_NBR;
BEGIN
	p_MAP(p_TABLE_NAME||'-'||p_ENTITY_ID) := 
		-- store the text that we put into the ROML file - which includes
		-- the table name, a unique "sequence" number, and an optional
		-- database sequence name (used to generate ID value on import if
		-- necessary).
		c_ROML_REF||p_TABLE_NAME||'-'||TRIM(TO_CHAR(v_SEQ_NBR,'999990000'))
		||CASE WHEN p_SEQUENCE IS NOT NULL THEN '|'||p_SEQUENCE ELSE NULL END;
END ADD_ENTITY_IDENTIFIER;
-------------------------------------------------------------------------------
-- Get the "identifier" for the specified entity
FUNCTION GET_ENTITY_IDENTIFIER
	(
	p_TABLE_NAME	IN VARCHAR2,
	p_ENTITY_ID		IN NUMBER,
	p_MAP			IN OUT NOCOPY UT.STRING_MAP
	) RETURN VARCHAR2 IS
v_KEY	VARCHAR2(40) := p_TABLE_NAME||'-'||p_ENTITY_ID;
BEGIN
	IF p_MAP.EXISTS(v_KEY) THEN
		RETURN p_MAP(v_KEY);
	ELSE
		-- no mapping? just return ID as a numeric literal
		RETURN c_ROML_NUM||p_ENTITY_ID;
	END IF;
END GET_ENTITY_IDENTIFIER;
-------------------------------------------------------------------------------
-- Get the text for the specified column value that will be written to the
-- ROML file. This will be a representation of the value or an entity identifier
-- if this value is a reference to an object.
FUNCTION GET_FIELD_VALUE
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_VALUES			IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA			IN OUT NOCOPY t_TABLE_METADATA,
	p_COLUMN_NAME		IN VARCHAR2,
	p_ENTITY_MAP		IN OUT NOCOPY UT.STRING_MAP
	) RETURN VARCHAR2 IS
v_RULE_PARTS		GA.STRING_TABLE;
v_POS				PLS_INTEGER;
v_RULE_COLUMN		VARCHAR2(30);
v_RULE_VALUES		GA.STRING_TABLE;
v_COL_VALUE			VARCHAR2(4000);
v_RULE_APPLIES		BOOLEAN;
v_RULE_PART_APPLIES	BOOLEAN;
v_IDX				PLS_INTEGER;
v_JDX				PLS_INTEGER;
v_COL_PREFIX		VARCHAR2(30);
v_TABLE_NAME		VARCHAR2(30);
BEGIN
	IF GET_COL_VAL_STRING(p_VALUES, p_METADATA, p_COLUMN_NAME) IS NULL THEN
		RETURN c_ROML_NULL;
	END IF;
	
	-- see if this is an object reference - check rules
	FOR v_RULE IN (SELECT RULE, TABLE_NAME
					FROM ROML_COL_RULES_MAP
					WHERE COLUMN_NAME = p_COLUMN_NAME
						AND (ROML_ENTITY_NID = p_ROML_ENTITY_NID OR ROML_ENTITY_NID IS NULL)
					ORDER BY ROML_ENTITY_NID NULLS LAST) LOOP
		UT.TOKENS_FROM_STRING(v_RULE.RULE, ';', v_RULE_PARTS);
		
		-- default to true - reset below if a rule doesn't hold
		v_RULE_APPLIES := TRUE;
		
		-- check each part of the rule - all parts must apply for the
		-- rule to apply
		v_IDX := v_RULE_PARTS.FIRST;
		WHILE v_RULE_PARTS.EXISTS(v_IDX) LOOP
			-- default to false - set if we find that the part does apply
			v_RULE_PART_APPLIES := FALSE;
			
			-- Asterisk means always matches - no real rule
			IF v_RULE_PARTS(v_IDX) = '*' THEN
				v_RULE_PART_APPLIES := TRUE;
			ELSE
				v_POS := INSTR(v_RULE_PARTS(v_IDX), '=');
				v_RULE_COLUMN := SUBSTR(v_RULE_PARTS(v_IDX), 1, v_POS-1);
				-- get allowed values for this column
				UT.TOKENS_FROM_STRING(SUBSTR(v_RULE_PARTS(v_IDX), v_POS+1), ',', v_RULE_VALUES);
				
				-- loop through set of values - if any value is matched
				-- then this part applies
				v_COL_VALUE := GET_COL_VAL_STRING(p_VALUES, p_METADATA, v_RULE_COLUMN);
				v_JDX := v_RULE_VALUES.FIRST;
				WHILE v_RULE_VALUES.EXISTS(v_JDX) LOOP
					IF v_COL_VALUE = v_RULE_VALUES(v_JDX) THEN
						v_RULE_PART_APPLIES := TRUE;
						EXIT;
					END IF;
					v_JDX := v_RULE_VALUES.NEXT(v_JDX);
				END LOOP;
			END IF;
			
			-- if this part doesn't apply, the rule fails
			IF NOT v_RULE_PART_APPLIES THEN
				v_RULE_APPLIES := FALSE;
				EXIT;
			END IF;
			
			-- next part
			v_IDX := v_RULE_PARTS.NEXT(v_IDX);
		END LOOP;
		
		IF v_RULE_APPLIES THEN
			RETURN GET_ENTITY_IDENTIFIER(v_RULE.TABLE_NAME,
										 GET_COL_VAL_NUMBER(p_VALUES, p_METADATA, p_COLUMN_NAME),
										 p_ENTITY_MAP);
		END IF;
	END LOOP;
	
	-- if we get here then no rule matched. still could be an object reference
	IF SUBSTR(p_COLUMN_NAME, LENGTH(p_COLUMN_NAME)-2) = '_ID' THEN
		v_COL_PREFIX := SUBSTR(p_COLUMN_NAME, 1, LENGTH(p_COLUMN_NAME)-3);
		
		SELECT MAX(TABLE_NAME)
		INTO v_TABLE_NAME
		FROM ROML_PREFIX_MAP
		WHERE COLUMN_PREFIX = v_COL_PREFIX;
		
		IF v_TABLE_NAME IS NOT NULL THEN
			RETURN GET_ENTITY_IDENTIFIER(v_TABLE_NAME,
										 GET_COL_VAL_NUMBER(p_VALUES, p_METADATA, p_COLUMN_NAME),
										 p_ENTITY_MAP);
		END IF;
	END IF;
	
	-- if we get here, then definitely not an object reference. just return value
	RETURN GET_COL_VAL_ROML(p_VALUES, p_METADATA, p_COLUMN_NAME);

END GET_FIELD_VALUE;
-------------------------------------------------------------------------------
-- Write column values to ROML export file.
PROCEDURE EXPORT_VALUES
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_VALUES			IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA			IN OUT NOCOPY t_TABLE_METADATA,
	p_INDENT			IN VARCHAR2,
	p_ENTITY_MAP		IN OUT NOCOPY UT.STRING_MAP,
	p_RESULT			IN OUT NOCOPY CLOB
	) AS
v_IDX	PLS_INTEGER;
BEGIN
	-- Loop through all fields in result list, exporting each one
	v_IDX := p_METADATA.NAMES.FIRST;
	WHILE p_METADATA.NAMES.EXISTS(v_IDX) LOOP
		WRITE_TO_CLOB(p_RESULT,
					p_INDENT||p_METADATA.NAMES(v_IDX)||':'||
					GET_FIELD_VALUE(p_ROML_ENTITY_NID, p_VALUES,
									p_METADATA, p_METADATA.NAMES(v_IDX),
									p_ENTITY_MAP
									)
					);
		v_IDX := p_METADATA.NAMES.NEXT(v_IDX);
	END LOOP;
END EXPORT_VALUES;
-------------------------------------------------------------------------------
-- Forward declaration to support circular recursion
PROCEDURE EXPORT_SUB_TABLES
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_VALUES			IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA			IN OUT NOCOPY t_TABLE_METADATA,
	p_INDENT			IN VARCHAR2,
	p_ENTITY_MAP		IN OUT NOCOPY UT.STRING_MAP,
	p_INCLUDE_DATA 		IN BOOLEAN,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_RESULT 			IN OUT NOCOPY CLOB
	);
-------------------------------------------------------------------------------
-- Write data for records from sub-table to ROML export file
PROCEDURE EXPORT_SUB_TABLE_ROWS
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_TABLE_NAME		IN VARCHAR2,
	p_SAVE_ID			IN BOOLEAN,
	p_ID_COLUMN			IN VARCHAR2,
	p_USE_SEQ			IN VARCHAR2,
	p_RECORDS			IN OUT NOCOPY GA.REFCURSOR,
	p_METADATA			IN OUT NOCOPY t_TABLE_METADATA,
	p_INDENT			IN VARCHAR2,
	p_ENTITY_MAP		IN OUT NOCOPY UT.STRING_MAP,
	p_INCLUDE_DATA 		IN BOOLEAN,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_RESULT 			IN OUT NOCOPY CLOB
	) AS
v_VALS	STRING_COLLECTION;
BEGIN
	-- loop over all incoming records
	LOOP
		FETCH p_RECORDS INTO v_VALS;
		EXIT WHEN p_RECORDS%NOTFOUND;
		
		IF p_SAVE_ID THEN
			ADD_ENTITY_IDENTIFIER(p_TABLE_NAME,
								GET_COL_VAL_NUMBER(v_VALS, p_METADATA, p_ID_COLUMN),
								p_ENTITY_MAP, p_USE_SEQ);
		END IF;
		
		WRITE_TO_CLOB(p_RESULT, p_INDENT||'begin row');
		
		-- record column values for this row
		EXPORT_VALUES(p_ROML_ENTITY_NID, v_VALS, p_METADATA,
					p_INDENT||c_INDENT, p_ENTITY_MAP, p_RESULT);
		-- and get any child data for this record
		EXPORT_SUB_TABLES(p_ROML_ENTITY_NID, v_VALS, p_METADATA,
					p_INDENT||c_INDENT, p_ENTITY_MAP,
					p_INCLUDE_DATA, p_BEGIN_DATE, p_END_DATE,
					p_RESULT);
		
		WRITE_TO_CLOB(p_RESULT, p_INDENT||'end row');
	END LOOP;
END EXPORT_SUB_TABLE_ROWS;
-------------------------------------------------------------------------------
-- Write data for sub-tables to ROML export file
PROCEDURE EXPORT_SUB_TABLES
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_VALUES			IN OUT NOCOPY STRING_COLLECTION,
	p_METADATA			IN OUT NOCOPY t_TABLE_METADATA,
	p_INDENT			IN VARCHAR2,
	p_ENTITY_MAP		IN OUT NOCOPY UT.STRING_MAP,
	p_INCLUDE_DATA 		IN BOOLEAN,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_RESULT 			IN OUT NOCOPY CLOB
	) AS

v_INCLUDE_DATA	NUMBER(1) := UT.NUMBER_FROM_BOOLEAN(p_INCLUDE_DATA);
v_SQL				VARCHAR2(32767);
v_CHILD_RECORDS		GA.REFCURSOR;
v_CHILD_METADATA	t_TABLE_METADATA;

BEGIN
	FOR v_SUB_TBL IN (SELECT B.ROML_ENTITY_NID, B.TABLE_NAME, B.TABLE_ALIAS,
							B.DATE1_COL, B.DATE2_COL, B.IS_OBJECT, A.RELATIONSHIP,
							B.SAVE_ID, B.ID_COLUMN, B.USE_SEQ
						FROM ROML_ENTITY_DEPENDS A, ROML_ENTITY B
						WHERE A.ROML_ENTITY_NID = p_ROML_ENTITY_NID
							AND B.ROML_ENTITY_NID = A.DEP_ROML_ENTITY_NID
							AND B.IS_OBJECT = 0
							AND (NVL(B.IS_DATA,0) = 0 OR v_INCLUDE_DATA = 1)
						ORDER BY B.TABLE_NAME, A.RELATIONSHIP) LOOP
							
		IF LOGS.IS_DEBUG_ENABLED THEN
			LOGS.LOG_DEBUG(p_INDENT||'Gathering child data from '||v_SUB_TBL.TABLE_NAME);
		END IF;

		v_CHILD_METADATA := GET_TABLE_METADATA(v_SUB_TBL.TABLE_NAME);
			
		v_SQL := BUILD_SQL_FOR_SUBTABLE_ROWS(p_VALUES, p_METADATA,
											v_SUB_TBL.TABLE_NAME, v_SUB_TBL.RELATIONSHIP,
											v_SUB_TBL.DATE1_COL, v_SUB_TBL.DATE2_COL,
											v_CHILD_METADATA,
											p_BEGIN_DATE, p_END_DATE);
		TRACE_SQL(v_SQL);
		OPEN v_CHILD_RECORDS FOR v_SQL;
		
		WRITE_TO_CLOB(p_RESULT, p_INDENT||'begin subtable');
		WRITE_TO_CLOB(p_RESULT, p_INDENT||c_INDENT||'table_name:'||v_SUB_TBL.TABLE_NAME);
		WRITE_TO_CLOB(p_RESULT, p_INDENT||c_INDENT||'relationship:'||v_SUB_TBL.RELATIONSHIP);

		-- now dump the cursor contents to the CLOB
		EXPORT_SUB_TABLE_ROWS(v_SUB_TBL.ROML_ENTITY_NID, v_SUB_TBL.TABLE_NAME,
							UT.BOOLEAN_FROM_NUMBER(v_SUB_TBL.SAVE_ID), v_SUB_TBL.ID_COLUMN, v_SUB_TBL.USE_SEQ,
							v_CHILD_RECORDS, v_CHILD_METADATA,
							p_INDENT||c_INDENT, p_ENTITY_MAP,
							p_INCLUDE_DATA,	p_BEGIN_DATE, p_END_DATE,
							p_RESULT);
		
		WRITE_TO_CLOB(p_RESULT, p_INDENT||'end subtable');
		
	END LOOP;
END EXPORT_SUB_TABLES;
-------------------------------------------------------------------------------
-- Exports entire entity specification - including all child data - for a
-- single entity.
PROCEDURE EXPORT_ONE_OBJECT
	(
	p_ROML_ENTITY_NID	IN NUMBER,
	p_TABLE_NAME 		IN VARCHAR2,
	p_TABLE_ALIAS 		IN VARCHAR2,
	p_ENTITY_ID 		IN NUMBER,
	p_ENTITY_NAME 		IN VARCHAR2,
	p_ENTITY_MAP		IN OUT NOCOPY UT.STRING_MAP,
	p_INCLUDE_DATA 		IN BOOLEAN,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_RESULT 			IN OUT NOCOPY CLOB
	) AS
v_METADATA	t_TABLE_METADATA;
v_VALUES	STRING_COLLECTION;
BEGIN
	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Exporting '||GET_DESCRIPTOR(p_TABLE_NAME, p_ENTITY_NAME, p_ENTITY_ID));
	END IF;
	
	ADD_ENTITY_IDENTIFIER(p_TABLE_NAME, p_ENTITY_ID, p_ENTITY_MAP);
	GET_ENTITY_AS_COLL(p_TABLE_NAME, p_TABLE_ALIAS, p_ENTITY_ID, v_METADATA, v_VALUES);

	WRITE_TO_CLOB(p_RESULT, 'begin object');
	WRITE_TO_CLOB(p_RESULT, c_INDENT||'table_name:'||p_TABLE_NAME);
	WRITE_TO_CLOB(p_RESULT, c_INDENT||'table_alias:'||p_TABLE_ALIAS);
	
	EXPORT_VALUES(p_ROML_ENTITY_NID, v_VALUES, v_METADATA, c_INDENT, p_ENTITY_MAP, p_RESULT);
	
	EXPORT_SUB_TABLES(p_ROML_ENTITY_NID, v_VALUES, v_METADATA, c_INDENT, p_ENTITY_MAP, p_INCLUDE_DATA, p_BEGIN_DATE, p_END_DATE, p_RESULT);

	WRITE_TO_CLOB(p_RESULT, 'end object');

END EXPORT_ONE_OBJECT;
-------------------------------------------------------------------------------
-- Performs an export to ROML text format. Specified entities and date ranges
-- are used to construct the out-bound CLOB.
-- NOTE: This is the only public method in this package.
PROCEDURE DO_EXPORT
	(
	p_ROML_ENTITY_NID 	IN NUMBER,
	p_ENTITY_IDs 		IN NUMBER_COLLECTION,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE 			IN DATE,
	p_INCLUDE_DATA 		IN NUMBER,
	p_TRACE_ON 			IN NUMBER,
	p_FILE				OUT CLOB,
	p_PROCESS_ID 		OUT VARCHAR2,
	p_PROCESS_STATUS 	OUT NUMBER,
	p_MESSAGE 			OUT VARCHAR2
	) AS

v_INCLUDE_DATA		BOOLEAN := UT.BOOLEAN_FROM_NUMBER(p_INCLUDE_DATA);
v_TABLE_NAME		ROML_ENTITY.TABLE_NAME%TYPE;
v_TABLE_ALIAS		ROML_ENTITY.TABLE_ALIAS%TYPE;
v_ENTITY_NAME		VARCHAR2(4000);
v_PROGRESS_RANGE	PLS_INTEGER;
v_IDX				PLS_INTEGER;
v_SQL				VARCHAR2(32767);
v_COUNT				PLS_INTEGER;
v_ENTITY_MAP		UT.STRING_MAP;

BEGIN
	SAVEPOINT BEFORE_EXPORT;
	
	LOGS.START_PROCESS('Export ROML Data', p_BEGIN_DATE, p_END_DATE, p_TRACE_ON => p_TRACE_ON);
	LOGS.SET_PROCESS_TARGET_PARAMETER('ROML Entity #', p_ROML_ENTITY_NID);
	LOGS.SET_PROCESS_TARGET_PARAMETER('Entity IDs', TEXT_UTIL.TO_CHAR_NUMBER_LIST(p_ENTITY_IDs));
	LOGS.SET_PROCESS_TARGET_PARAMETER('Include Data',
							CASE WHEN v_INCLUDE_DATA THEN 'True' ELSE 'False' END);

	-- Security check!
	SD.VERIFY_ACTION_IS_ALLOWED(SD.g_ACTION_ROML_PUB_SUB);

	SELECT TABLE_NAME, TABLE_ALIAS
	INTO v_TABLE_NAME, v_TABLE_ALIAS
	FROM ROML_ENTITY
	WHERE ROML_ENTITY_NID = p_ROML_ENTITY_NID;
	
	LOGS.INIT_PROCESS_PROGRESS('Gathering Object Dependencies', 2, 'Steps', TRUE);
	v_PROGRESS_RANGE := LOGS.PUSH_PROGRESS_RANGE(p_ENTITY_IDs.COUNT);

    -- gather entities to export
	v_IDX := p_ENTITY_IDs.FIRST;
	WHILE p_ENTITY_IDs.EXISTS(v_IDX) LOOP
		-- determine entity name
		v_SQL := 'SELECT '||v_TABLE_ALIAS||'_NAME FROM '||v_TABLE_NAME||' WHERE '||v_TABLE_ALIAS||'_ID = '||p_ENTITY_IDs(v_IDX);
		EXECUTE IMMEDIATE v_SQL INTO v_ENTITY_NAME;

		-- walk dependency tree
		GET_DEPENDENCIES(p_ROML_ENTITY_NID, p_ENTITY_IDs(v_IDX), v_TABLE_NAME, v_TABLE_ALIAS, v_ENTITY_NAME,
							v_INCLUDE_DATA, p_BEGIN_DATE, p_END_DATE);
	
		-- onto the next one...
		LOGS.INCREMENT_PROCESS_PROGRESS(p_RANGE_INDEX => v_PROGRESS_RANGE);
		v_IDX := p_ENTITY_IDs.NEXT(v_IDX);
	END LOOP;

	LOGS.POP_PROGRESS_RANGE(v_PROGRESS_RANGE);
	LOGS.INCREMENT_PROCESS_PROGRESS(p_PROGRESS_DESCRIPTION => 'Generating Export Contents');

	-- identify correct order for export
	ORDER_WORK_TABLE;

	SELECT COUNT(1)
	INTO v_COUNT
	FROM ROML_WORK;
	v_PROGRESS_RANGE := LOGS.PUSH_PROGRESS_RANGE(v_COUNT);

	RESET_SEQ_NBR;
	
	-- start exporting the entities in dependency order
	DBMS_LOB.CREATETEMPORARY(p_FILE, TRUE);
	DBMS_LOB.OPEN(p_FILE, DBMS_LOB.LOB_READWRITE);
	FOR v_ENTITY IN (SELECT *
					 FROM ROML_WORK
					 ORDER BY WORK_ORDER, TABLE_NAME, ENTITY_NAME) LOOP
		EXPORT_ONE_OBJECT(v_ENTITY.ROML_ENTITY_NID, v_ENTITY.TABLE_NAME, v_ENTITY.TABLE_ALIAS,
							v_ENTITY.ENTITY_ID, v_ENTITY.ENTITY_NAME,
							v_ENTITY_MAP, v_INCLUDE_DATA, p_BEGIN_DATE, p_END_DATE, p_FILE);
		LOGS.INCREMENT_PROCESS_PROGRESS(p_RANGE_INDEX => v_PROGRESS_RANGE);
	END LOOP;
	DBMS_LOB.CLOSE(p_FILE);

	LOGS.POP_PROGRESS_RANGE(v_PROGRESS_RANGE);
	LOGS.INCREMENT_PROCESS_PROGRESS;

	-- Done!    
	p_PROCESS_ID := LOGS.CURRENT_PROCESS_ID;
	LOGS.STOP_PROCESS(p_MESSAGE, p_PROCESS_STATUS);
	COMMIT;
	
EXCEPTION
	WHEN OTHERS THEN
		ERRS.ABORT_PROCESS(p_SAVEPOINT_NAME => 'BEFORE_EXPORT');

END DO_EXPORT;
-------------------------------------------------------------------------------
-- Retrieve DML statements to rebuild metadata tables to current state
FUNCTION ROML_METADATA_DML RETURN CLOB IS
v_RET	CLOB;
BEGIN
	DBMS_LOB.CREATETEMPORARY(v_RET, TRUE);
	DBMS_LOB.OPEN(v_RET, DBMS_LOB.LOB_READWRITE);
	WRITE_TO_CLOB(v_RET, '-- clear out tables');
	WRITE_TO_CLOB(v_RET, 'delete roml_prefix_map;');
	WRITE_TO_CLOB(v_RET, 'delete roml_col_rules_map;');
	WRITE_TO_CLOB(v_RET, 'delete roml_entity_depends;');
	WRITE_TO_CLOB(v_RET, 'delete roml_entity;');
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '-- and then rebuild');

	-- ROML_ENTITY table
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '-- ROML_ENTITY');
	FOR v_REC IN (SELECT * FROM ROML_ENTITY ORDER BY ROML_ENTITY_NID) LOOP
		WRITE_TO_CLOB(v_RET, 'insert into roml_entity (roml_entity_nid, roml_entity_name, table_name, table_alias, is_object, is_data, save_id, id_column, use_seq, export_order, date1_col, date2_col)');
		WRITE_TO_CLOB(v_RET, '                 values ('||UT.GET_LITERAL_FOR_NUMBER(v_REC.ROML_ENTITY_NID)||', '||UT.GET_LITERAL_FOR_STRING(v_REC.ROML_ENTITY_NAME)||', '
														  ||UT.GET_LITERAL_FOR_STRING(v_REC.TABLE_NAME)||', '||UT.GET_LITERAL_FOR_STRING(v_REC.TABLE_ALIAS)||', '
														  ||UT.GET_LITERAL_FOR_NUMBER(v_REC.IS_OBJECT)||', '||UT.GET_LITERAL_FOR_NUMBER(v_REC.IS_DATA)||', '||UT.GET_LITERAL_FOR_NUMBER(v_REC.SAVE_ID)||', '
														  ||UT.GET_LITERAL_FOR_STRING(v_REC.ID_COLUMN)||', '||UT.GET_LITERAL_FOR_STRING(v_REC.USE_SEQ)||', '||UT.GET_LITERAL_FOR_NUMBER(v_REC.EXPORT_ORDER)||', '
														  ||UT.GET_LITERAL_FOR_STRING(v_REC.DATE1_COL)||', '||UT.GET_LITERAL_FOR_STRING(v_REC.DATE2_COL)||');');
	END LOOP;

	-- ROML_ENTITY_DEPENDS table
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '-- ROML_ENTITY_DEPENDS');
	FOR v_REC IN (SELECT * FROM ROML_ENTITY_DEPENDS ORDER BY ROML_ENTITY_NID, DEP_ROML_ENTITY_NID, RELATIONSHIP) LOOP
		WRITE_TO_CLOB(v_RET, 'insert into roml_entity_depends (roml_entity_nid, dep_roml_entity_nid, relationship)');
		WRITE_TO_CLOB(v_RET, '                         values ('||UT.GET_LITERAL_FOR_NUMBER(v_REC.ROML_ENTITY_NID)||', '||UT.GET_LITERAL_FOR_NUMBER(v_REC.DEP_ROML_ENTITY_NID)||', '
														  ||UT.GET_LITERAL_FOR_STRING(v_REC.RELATIONSHIP)||');');
	END LOOP;

	-- ROML_COLUMN_RULES_MAP table
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '-- ROML_COLUMN_RULES_MAP');
	FOR v_REC IN (SELECT * FROM ROML_COL_RULES_MAP ORDER BY COLUMN_NAME, RULE, ROML_ENTITY_NID) LOOP
		WRITE_TO_CLOB(v_RET, 'insert into roml_col_rules_map (column_name, rule, roml_entity_nid, table_name)');
		WRITE_TO_CLOB(v_RET, '                        values ('||UT.GET_LITERAL_FOR_STRING(v_REC.COLUMN_NAME)||', '||UT.GET_LITERAL_FOR_STRING(v_REC.RULE)||', '
														  ||UT.GET_LITERAL_FOR_NUMBER(v_REC.ROML_ENTITY_NID)||', '||UT.GET_LITERAL_FOR_STRING(v_REC.TABLE_NAME)||');');
	END LOOP;

	-- ROML_PREFIX_MAP table
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, '-- ROML_PREFIX_MAP');
	FOR v_REC IN (SELECT * FROM ROML_PREFIX_MAP ORDER BY COLUMN_PREFIX) LOOP
		WRITE_TO_CLOB(v_RET, 'insert into roml_prefix_map (column_prefix, table_name)');
		WRITE_TO_CLOB(v_RET, '                     values ('||UT.GET_LITERAL_FOR_STRING(v_REC.COLUMN_PREFIX)||', '||UT.GET_LITERAL_FOR_STRING(v_REC.TABLE_NAME)||');');
	END LOOP;

	-- Done!	
	WRITE_TO_CLOB(v_RET, '');
	WRITE_TO_CLOB(v_RET, 'commit;');
	
	DBMS_LOB.CLOSE(v_RET);
	RETURN v_RET;

END ROML_METADATA_DML;
-------------------------------------------------------------------------------
END ROML_EXPORT;
/
