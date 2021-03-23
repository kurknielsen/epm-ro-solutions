CREATE OR REPLACE PACKAGE BODY SD AS
----------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.8 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
PROCEDURE NULL_CURSOR
    (
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN

	OPEN p_CURSOR FOR
		SELECT NULL FROM DUAL;

END NULL_CURSOR;
----------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_COL_NAMES
	(
	p_REALM_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN

	p_STATUS := GA.SUCCESS;

	OPEN p_CURSOR FOR
		SELECT A.ENTITY_COLUMN "ENTITY_COLUMN"
		FROM SYSTEM_REALM_COLUMN A
		WHERE A.REALM_ID = p_REALM_ID
        ORDER BY 1;

END GET_ENTITY_COL_NAMES;
----------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_COLUMNS_FOR_REALM
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SORT_ALPHABETICAL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN

	p_STATUS := GA.SUCCESS;

	OPEN p_CURSOR FOR
		SELECT A.COLUMN_NAME
		FROM USER_TAB_COLUMNS A, ENTITY_DOMAIN B
		WHERE B.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND A.TABLE_NAME = B.ENTITY_DOMAIN_TABLE
		ORDER BY CASE WHEN p_SORT_ALPHABETICAL = 1 THEN A.COLUMN_NAME ELSE '' END,
				 CASE WHEN p_SORT_ALPHABETICAL = 0 THEN A.COLUMN_ID ELSE NULL END;

END GET_ENTITY_COLUMNS_FOR_REALM;
------------------------------------------------------------------------------------------------
FUNCTION PARSE_COLUMN_VALUES_INTO_WORK
	(
	p_COLUMN_VALS IN VARCHAR2
	) RETURN NUMBER IS

v_INSTR BOOLEAN := FALSE;
v_LEN 	PLS_INTEGER := NVL(LENGTH(p_COLUMN_VALS),0);
v_POS1	PLS_INTEGER := 1;
v_POS2	PLS_INTEGER := 0;
v_COMMA	PLS_INTEGER;
v_TICK	PLS_INTEGER;
v_DBLTICK PLS_INTEGER;
v_WORK_ID	NUMBER;
v_GOT_ONE	BOOLEAN := FALSE;
v_VALUE	VARCHAR2(4000);

BEGIN
	UT.GET_RTO_WORK_ID(v_WORK_ID);

	-- parse comma-separate list of string literals
	WHILE v_POS1 <= v_LEN LOOP
		IF v_INSTR THEN
			-- inside of a string? then we are looking for the terminating quote mark
			v_TICK := INSTR(p_COLUMN_VALS, '''', v_POS2+1);
			v_DBLTICK := INSTR(p_COLUMN_VALS, '''''', v_POS2+1);
			IF v_TICK = 0 AND v_COMMA = 0 THEN
				-- this shouldn't happen because it indicates unterminated string literal.
				-- we'll continue, silently ignoring the missing terminating tick mark.
				-- TODO log it?
				v_POS2 := v_LEN+1; -- this token extends to end of string
				v_GOT_ONE := TRUE; -- found the end of the string - which means end of token
			ELSIF v_TICK = 0 OR (v_DBLTICK > 0 AND v_DBLTICK < v_TICK) THEN
				v_POS2 := v_DBLTICK+1;
			ELSE
				-- tick mark terminates a string literal
				v_POS2 := v_TICK;
				v_INSTR := FALSE;
			END IF;
		ELSE
			-- find the next quote or comma
			v_TICK := INSTR(p_COLUMN_VALS, '''', v_POS2+1);
			v_COMMA := INSTR(p_COLUMN_VALS, ',', v_POS2+1);
			IF v_TICK = 0 AND v_COMMA = 0 THEN
				v_POS2 := v_LEN+1; -- this token extends to end of string
				v_GOT_ONE := TRUE; -- found the end of the string - which means end of token
			ELSIF v_TICK = 0 OR (v_COMMA > 0 AND v_COMMA < v_TICK) THEN
				v_POS2 := v_COMMA;
				v_GOT_ONE := TRUE; -- comma indicates the end of token
			ELSE
				-- tick mark starts a string literal
				v_POS2 := v_TICK;
				v_INSTR := TRUE;
			END IF;
		END IF;

		IF v_GOT_ONE THEN
			-- get the token and add to the work table
			v_VALUE := TRIM(SUBSTR(p_COLUMN_VALS, v_POS1, v_POS2-v_POS1));
			IF SUBSTR(v_VALUE,1,1) = '''' THEN
				-- this is a string? remove surrounding tick marks
				v_VALUE := SUBSTR(v_VALUE,2);
				-- there should be a terminating tick mark - if so, remove it
				IF SUBSTR(v_VALUE,-1) = '''' THEN
					v_VALUE := SUBSTR(v_VALUE,1,LENGTH(v_VALUE)-1);
				END IF;
				-- internal tick marks are escaped as two-in-a-row. unescape them
				v_VALUE := REPLACE(v_VALUE,'''''','''');
				-- finally, prefix with a tick mark (Excel-style) if this value starts
				-- with a tick mark or if it starts with '${'
				IF SUBSTR(v_VALUE,1,1) = '''' OR SUBSTR(v_VALUE,1,2) = '${' THEN
					v_VALUE := ''''||v_VALUE;
				END IF;
			END IF;

			INSERT INTO RTO_WORK (WORK_ID, WORK_DATA)
				VALUES (v_WORK_ID, v_VALUE);

			v_POS1 := v_POS2+1;
			-- reset this flag and scan for subsequent token
			v_GOT_ONE := FALSE;
			v_INSTR := FALSE;
		END IF;
	END LOOP;

	RETURN v_WORK_ID;
END PARSE_COLUMN_VALUES_INTO_WORK;
------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_COL_VALS
	(
	p_REALM_ID IN NUMBER,
    p_ENTITY_COLUMN IN VARCHAR2,
	p_INCLUDE_SELECTED_ONLY IN NUMBER,
	p_IS_EXCLUDING_VALS OUT NUMBER,
	p_VALS_ARE_IDs OUT NUMBER,
	p_ALLOW_REFS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

    v_ENTITY_DOMAIN_ID			ENTITY_DOMAIN.ENTITY_DOMAIN_ID%TYPE;
    v_COLUMN_VALS				SYSTEM_REALM_COLUMN.COLUMN_VALS%TYPE;
	v_SRC_ENTITY_DOMAIN_INFO	ENTITY_UTIL.ENTITY_DOMAIN_INFO;
	v_WORK_ID					RTO_WORK.wORK_ID%TYPE;
	v_REALM_CALC_TYPE			SYSTEM_REALM.REALM_CALC_TYPE%TYPE;

    v_ENTITY_COLUMN				SYSTEM_REALM_COLUMN.ENTITY_COLUMN%TYPE := p_ENTITY_COLUMN;
	v_ENTITY_ID_COL				VARCHAR2(42);
    v_ENTITY_NAME_COL			VARCHAR2(32);
    v_TABLE_NAME				VARCHAR2(64);

    v_SQL						VARCHAR2(32767) := '';
    v_IDX						PLS_INTEGER;

	v_VALS_ARE_IDs				BOOLEAN := FALSE;
	v_SELECTED_ONLY				BOOLEAN := UT.BOOLEAN_FROM_NUMBER(p_INCLUDE_SELECTED_ONLY);

BEGIN

	ASSERT(NVL(TRIM(v_ENTITY_COLUMN),'?') <> '?', 'Entity Column name cannot be blank');

	-- Get some info for this realm
	SELECT A.ENTITY_DOMAIN_ID, A.REALM_CALC_TYPE,
		B.IS_EXCLUDING_VALS, B.COLUMN_VALS,
		C.ENTITY_DOMAIN_TABLE
	INTO v_ENTITY_DOMAIN_ID, v_REALM_CALC_TYPE,
		p_IS_EXCLUDING_VALS, v_COLUMN_VALS,
		v_TABLE_NAME
	FROM SYSTEM_REALM A, SYSTEM_REALM_COLUMN B, ENTITY_DOMAIN C
	WHERE A.REALM_ID = p_REALM_ID
		AND B.REALM_ID = A.REALM_ID
    	AND UPPER(B.ENTITY_COLUMN) = UPPER(LTRIM(RTRIM(p_ENTITY_COLUMN)))
		AND C.ENTITY_DOMAIN_ID = A.ENTITY_DOMAIN_ID;

	-- check that user has permission to view realm details
	VERIFY_ENTITY_IS_ALLOWED(g_ACTION_SELECT_ENT, p_REALM_ID,
								 CASE v_REALM_CALC_TYPE WHEN EM.c_REALM_CALC_TYPE_SYSTEM THEN EC.ED_SYSTEM_REALM
								 						WHEN EM.c_REALM_CALC_TYPE_FML THEN EC.ED_FORMULA_REALM
														WHEN EM.c_REALM_CALC_TYPE_CALC THEN EC.ED_CALC_REALM
														END);

	p_ALLOW_REFS := UT.NUMBER_FROM_BOOLEAN(v_REALM_CALC_TYPE <> EM.c_REALM_CALC_TYPE_SYSTEM);

    -- The Entity Column selected in the filter
    v_ENTITY_COLUMN := p_ENTITY_COLUMN;

	IF v_COLUMN_VALS = c_EMPTY_COLUMN_VALS THEN
		v_COLUMN_VALS := NULL;
	END IF;
	v_WORK_ID := PARSE_COLUMN_VALUES_INTO_WORK(v_COLUMN_VALS);

 	--------------------------------------------------------------------------------------
 	-- If the Entity Column in the domain Table is an ID column, then we want to get the list
	-- of objects to which this ID is referring.
    --------------------------------------------------------------------------------------

	--If it is an ID column, try to look it up in the Entity Domain table
	IF SUBSTR(v_ENTITY_COLUMN, -3) = '_ID' THEN

        v_SRC_ENTITY_DOMAIN_INFO := ENTITY_UTIL.GET_REFERRED_DOMAIN_INFO(v_ENTITY_COLUMN, v_ENTITY_DOMAIN_ID);

        IF v_SRC_ENTITY_DOMAIN_INFO.ENTITY_DOMAIN_ID IS NOT NULL THEN

        	v_ENTITY_NAME_COL := v_SRC_ENTITY_DOMAIN_INFO.ENTITY_DOMAIN_TABLE_PREFIX || '_NAME';
			v_ENTITY_ID_COL :=  v_SRC_ENTITY_DOMAIN_INFO.ENTITY_DOMAIN_TABLE_PREFIX || '_ID';

            v_VALS_ARE_IDs := TRUE;
			v_TABLE_NAME := v_SRC_ENTITY_DOMAIN_INFO.ENTITY_DOMAIN_TABLE_NAME;

			-- add contract and billing entity references if appropriate for formula realms
			IF NVL(v_REALM_CALC_TYPE,0) = EM.c_REALM_CALC_TYPE_FML THEN
				IF v_SRC_ENTITY_DOMAIN_INFO.ENTITY_DOMAIN_ID = EC.ED_INTERCHANGE_CONTRACT THEN
					v_SQL := 'SELECT 0 as IS_SELECTED, 0 as UNAVAILABLE, NULL as ENTITY_ID, ''${:contract}'' as ENTITY_NAME FROM DUAL UNION ALL ';
				ELSIF v_SRC_ENTITY_DOMAIN_INFO.ENTITY_DOMAIN_ID = EC.ED_PSE THEN
					v_SQL := 'SELECT 0 as IS_SELECTED, 0 as UNAVAILABLE, NULL as ENTITY_ID, ''${:billing_entity}'' as ENTITY_NAME FROM DUAL UNION ALL ';
				END IF;
			END IF;

		END IF;

	END IF;

	IF NOT v_VALS_ARE_IDs THEN
    	-- PBM - 10/17 - Merge from the 4.1.2mmi branch. Hand editted a change made by John Cooper to avoid major conflicts.
    	v_ENTITY_NAME_COL := 'TO_CHAR('||v_ENTITY_COLUMN||')';
		v_ENTITY_ID_COL := 'NULL';
    END IF;

	p_VALS_ARE_IDs := CASE WHEN v_VALS_ARE_IDs THEN 1 ELSE 0 END;

    IF v_REALM_CALC_TYPE <> EM.c_REALM_CALC_TYPE_SYSTEM THEN
		-- add iterator selections
		FOR v_IDX IN 1..FML_UTIL.c_MAX_ITERATORS LOOP
			v_SQL := v_SQL||'SELECT 0 as IS_SELECTED, 0 as UNAVAILABLE, NULL as ENTITY_ID, ''${:iter'||v_IDX||'}'' as ENTITY_NAME FROM DUAL UNION ALL ';
		END LOOP;
	END IF;

	IF v_VALS_ARE_IDs THEN
		-- selected references
		v_SQL := v_SQL||'SELECT 1 as IS_SELECTED, 0 as UNAVAILABLE, NULL as ENTITY_ID, WORK_DATA as ENTITY_NAME'||
						' FROM RTO_WORK WHERE WORK_ID = :work_id AND SUBSTR(WORK_DATA,1,2) = ''${'' UNION ALL ';

		-- entity references
		IF v_SELECTED_ONLY THEN
			v_SQL := v_SQL||'SELECT 1 as IS_SELECTED, '||
							'	0 as UNAVAILABLE, TBL.'||v_ENTITY_ID_COL||' as ENTITY_ID, '||
							'	CASE WHEN SUBSTR(TBL.'||v_ENTITY_NAME_COL||',1,2) = ''${'' THEN ''''''''||TBL.'||v_ENTITY_NAME_COL||
							'		ELSE TBL.'||v_ENTITY_NAME_COL||' END as ENTITY_NAME '||
							'FROM '||v_TABLE_NAME||' TBL, RTO_WORK W '||
							'WHERE W.WORK_ID = :work_id AND W.WORK_DATA = TO_CHAR(TBL.'||v_ENTITY_ID_COL||')';
		ELSE
			v_SQL := v_SQL||'SELECT CASE WHEN W.WORK_DATA IS NULL THEN 0 ELSE 1 END as IS_SELECTED, '||
							'	0 as UNAVAILABLE, TBL.'||v_ENTITY_ID_COL||' as ENTITY_ID, '||
							'	CASE WHEN SUBSTR(TBL.'||v_ENTITY_NAME_COL||',1,2) = ''${'' THEN ''''''''||TBL.'||v_ENTITY_NAME_COL||
							'		ELSE TBL.'||v_ENTITY_NAME_COL||' END as ENTITY_NAME '||
							'FROM '||v_TABLE_NAME||' TBL, RTO_WORK W '||
							'WHERE W.WORK_ID(+) = :work_id AND W.WORK_DATA(+) = TO_CHAR(TBL.'||v_ENTITY_ID_COL||')';
		END IF;
	ELSE
		-- selected values
		v_SQL := v_SQL||'SELECT 1 as IS_SELECTED, CASE WHEN SUBSTR(WORK_DATA,1,2) = ''${'' THEN 0 ELSE 1 END as UNAVAILABLE, NULL as ENTITY_ID, WORK_DATA as ENTITY_NAME'||
						' FROM RTO_WORK WHERE WORK_ID = :work_id ';

		-- other values in the table
		v_SQL := v_SQL||'UNION ALL SELECT DISTINCT 0 as IS_SELECTED, 0 as UNAVAILABLE, NULL as ENTITY_ID, '||
						'	CASE WHEN SUBSTR('||v_ENTITY_NAME_COL||',1,2) = ''${'' THEN ''''''''||'||v_ENTITY_NAME_COL||
						'		ELSE TO_CHAR('||v_ENTITY_NAME_COL||') END as ENTITY_NAME '||
						' FROM '||v_TABLE_NAME;
	END IF;

	-- wrap query with grouping expressions to return the correct values for IS_SELECTED and UNAVAILABLE
	v_SQL := 'SELECT MAX(IS_SELECTED) as IS_SELECTED, MIN(UNAVAILABLE) as UNAVAILABLE, ENTITY_ID, ENTITY_NAME '||
			 'FROM ('||v_SQL||') GROUP BY ENTITY_ID, ENTITY_NAME';
	-- only show selected? add that criteria to SQL
	IF v_SELECTED_ONLY THEN
		v_SQL := v_SQL||' HAVING MAX(IS_SELECTED) = 1';
	END IF;
	-- and now the ORDER BY clause
	v_SQL := v_SQL||' ORDER BY ENTITY_NAME';

	LOGS.LOG_DEBUG(v_SQL);

	IF v_VALS_ARE_IDs THEN
		-- in this case, there are two bind variables - both are the WORK_ID
		OPEN p_CURSOR FOR v_SQL USING v_WORK_ID, v_WORK_ID;
	ELSE
		-- otherwise, just one bind variable
		OPEN p_CURSOR FOR v_SQL USING v_WORK_ID;
	END IF;

END GET_ENTITY_COL_VALS;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_ENTITY_COL_VALS
	(
    p_REALM_ID IN NUMBER,
    p_ENTITY_COLUMN IN VARCHAR2,
	p_IS_SELECTED IN NUMBER,
	p_OLD_IS_SELECTED IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2
    ) AS

v_COLUMN_VALS VARCHAR2(4000);
v_VALUE VARCHAR2(4000);

BEGIN

    IF p_IS_SELECTED = p_OLD_IS_SELECTED THEN
	   	RETURN; -- nothing to do
  	END IF;

	IF p_ENTITY_ID IS NOT NULL THEN
		-- use ID if present
		v_VALUE := '''' || p_ENTITY_ID || '''';
	ELSIF SUBSTR(p_ENTITY_NAME,1,2) = '${' THEN
		 -- special value - don't escape as literal string
		v_VALUE := p_ENTITY_NAME;
	ELSE
		IF SUBSTR(p_ENTITY_NAME,1,1) = '''' THEN
			-- leading quote indicates a string - strip the leading quote
			v_VALUE := SUBSTR(p_ENTITY_NAME,2);
		ELSE
			v_VALUE := p_ENTITY_NAME;
		END IF;
		-- escape as literal string
		v_VALUE := UT.GET_LITERAL_FOR_STRING(v_VALUE);
	END IF;

    -- get original column values, if there are any
    SELECT NVL(MAX(A.COLUMN_VALS),c_EMPTY_COLUMN_VALS)
    INTO v_COLUMN_VALS
    FROM SYSTEM_REALM_COLUMN A
    WHERE A.REALM_ID = p_REALM_ID
	    AND A.ENTITY_COLUMN = p_ENTITY_COLUMN;

    IF NVL(p_IS_SELECTED,0) = 0 THEN
        -- REMOVING occurence of the value from the string
		IF v_COLUMN_VALS = v_VALUE THEN
			v_COLUMN_VALS := c_EMPTY_COLUMN_VALS;
		ELSIF SUBSTR(v_COLUMN_VALS,1,LENGTH(v_VALUE)+1) = v_VALUE||',' THEN
			-- starts with?
			v_COLUMN_VALS := SUBSTR(v_COLUMN_VALS, LENGTH(v_VALUE)+2);
		ELSE
			-- embedded? then pull value's preceding quote, too
			v_COLUMN_VALS := REPLACE(v_COLUMN_VALS, ','||v_VALUE, NULL);
		END IF;
	ELSE
        -- ADDING occurrence of the value to the string
        IF NVL(TRIM(v_COLUMN_VALS),c_EMPTY_COLUMN_VALS) = c_EMPTY_COLUMN_VALS THEN
	        v_COLUMN_VALS := v_VALUE;
        ELSE
    	    v_COLUMN_VALS := v_COLUMN_VALS || ',' || v_VALUE;
        END IF;
	END IF;

    UPDATE SYSTEM_REALM_COLUMN SET
        	ENTITY_COLUMN = p_ENTITY_COLUMN,
			-- reset column values if a different column name has been chosen
			COLUMN_VALS = v_COLUMN_VALS,
			ENTRY_DATE = SYSDATE
        WHERE REALM_ID = p_REALM_ID
			AND ENTITY_COLUMN = p_ENTITY_COLUMN;

END PUT_ENTITY_COL_VALS;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REALM_WHERE_CLAUSE
	(
	p_REALM_ID IN NUMBER
	) RETURN VARCHAR2 IS
v_RET VARCHAR2(32767);
CURSOR cur_COLUMNS IS
	SELECT ENTITY_COLUMN, IS_EXCLUDING_VALS, COLUMN_VALS
	FROM SYSTEM_REALM_COLUMN
	WHERE REALM_ID = p_REALM_ID;
BEGIN
	-- get the realm's custom query - if it is just a question mark, that is
	-- equivalent to a NULL
	SELECT MAX(CASE WHEN CUSTOM_QUERY = '?' THEN NULL ELSE CUSTOM_QUERY END)
	INTO v_RET
	FROM SYSTEM_REALM
	WHERE REALM_ID = p_REALM_ID;

	FOR v_COLUMN IN cur_COLUMNS LOOP
		IF v_RET IS NULL THEN
			v_RET := 'WHERE ';
		ELSE
			v_RET := v_RET||' AND ';
		END IF;

		IF v_COLUMN.IS_EXCLUDING_VALS = 1 THEN
			v_RET := v_RET||'(TO_CHAR(TBL.'||v_COLUMN.ENTITY_COLUMN||') NOT IN ('||v_COLUMN.COLUMN_VALS||')'||
				' OR TBL.'||v_COLUMN.ENTITY_COLUMN||' IS NULL)';
		ELSE
			v_RET := v_RET||'TO_CHAR(TBL.'||v_COLUMN.ENTITY_COLUMN||') IN ('||v_COLUMN.COLUMN_VALS||')';
		END IF;
	END LOOP;

	LOGS.LOG_DEBUG(v_RET);
	RETURN v_RET;

END GET_REALM_WHERE_CLAUSE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REALM_QUERY
	(
	p_REALM_ID IN NUMBER,
	p_OPTIONAL_COLUMNS IN VARCHAR2 := NULL
	) RETURN VARCHAR2 IS
v_TBL_NAME VARCHAR2(32);
v_ID_COL_NAME VARCHAR2(32);
v_RET VARCHAR2(32767);
BEGIN
	SELECT N.TABLE_NAME, N.PRIMARY_ID_COLUMN
	INTO v_TBL_NAME, v_ID_COL_NAME
	FROM SYSTEM_REALM R, ENTITY_DOMAIN D, NERO_TABLE_PROPERTY_INDEX N
	WHERE R.REALM_ID = p_REALM_ID
		AND D.ENTITY_DOMAIN_ID = R.ENTITY_DOMAIN_ID
		AND N.TABLE_NAME = D.ENTITY_DOMAIN_TABLE;

	v_RET := 'SELECT ';
	IF p_OPTIONAL_COLUMNS IS NOT NULL THEN
		v_RET := v_RET||p_OPTIONAL_COLUMNS||', ';
	END IF;
	v_RET := v_RET||'TBL.'||v_ID_COL_NAME||' FROM '||v_TBL_NAME||' TBL ';
	v_RET := v_RET||GET_REALM_WHERE_CLAUSE(p_REALM_ID);

	LOGS.LOG_DEBUG(v_RET);
	RETURN v_RET;
END GET_REALM_QUERY;
----------------------------------------------------------------------------------------------------
PROCEDURE POPULATE_ENTITIES_FOR_REALM
	(
	p_REALM_ID IN NUMBER
	)
	AS

v_SQL VARCHAR2(32767);

BEGIN
	-- clear out existing list
	DELETE SYSTEM_REALM_ENTITY WHERE REALM_ID = p_REALM_ID;

	-- build SQL that will find all the matching entities
	v_SQL := GET_REALM_QUERY(p_REALM_ID, ':1, :2');
	-- turn into DML
	v_SQL := 'INSERT INTO SYSTEM_REALM_ENTITY (REALM_ID, ENTRY_DATE, ENTITY_ID) '||v_SQL;

	-- run it!
	EXECUTE IMMEDIATE v_SQL USING p_REALM_ID, SYSDATE;

END POPULATE_ENTITIES_FOR_REALM;
----------------------------------------------------------------------------------
PROCEDURE POPULATE_REALMS_FOR_DOMAIN
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	) AS
CURSOR c_REALMS IS
	SELECT A.REALM_ID
	FROM SYSTEM_REALM A
	WHERE A.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
BEGIN
	p_STATUS := GA.SUCCESS;
	FOR v_REALMS IN c_REALMS LOOP
		BEGIN
			POPULATE_ENTITIES_FOR_REALM(v_REALMS.REALM_ID);
		EXCEPTION
			WHEN OTHERS THEN
			-- we keep going, re-populating other realms, but remember the failure
			-- code so the whole operation can return that to the caller as an indication
			-- that one or more realms could not be populated
			p_STATUS := SQLCODE;
		END;
	END LOOP;
END POPULATE_REALMS_FOR_DOMAIN;
----------------------------------------------------------------------------------
FUNCTION GET_REALMS_FOR_ENTITY_FIELDS
	(
	p_FIELDS_MAP UT.STRING_MAP,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE IS
CURSOR cur_REALMS IS
	SELECT REALM_ID
	FROM SYSTEM_REALM
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND NVL(REALM_CALC_TYPE,0) = 0;
v_SQL VARCHAR2(32767);
v_WHERE VARCHAR2(32767);
v_RET ID_TABLE := ID_TABLE();
v_FIELDS UT.STRING_MAP;
v_COL VARCHAR2(32);
v_REALM_ID NUMBER;
BEGIN
	-- duplicate p_FIELDS, but include additional mappings that have 'TBL.' prefix
	v_COL := p_FIELDS_MAP.FIRST;
	WHILE p_FIELDS_MAP.EXISTS(v_COL) LOOP
		v_FIELDS(v_COL) := p_FIELDS_MAP(v_COL);
		v_FIELDS('TBL.'||v_COL) := p_FIELDS_MAP(v_COL);
		v_COL := p_FIELDS_MAP.NEXT(v_COL);
	END LOOP;

	FOR v_REALM IN cur_REALMS LOOP
		v_WHERE := GET_REALM_WHERE_CLAUSE(v_REALM.REALM_ID);
		-- this will use the values in v_FIELDS to substitute column references
		-- for actual values
		v_WHERE := FML_UTIL.REBUILD_FORMULA(v_WHERE, v_FIELDS, FALSE, FALSE);
		v_SQL := 'SELECT :1 FROM DUAL '||v_WHERE;

        BEGIN
        	EXECUTE IMMEDIATE v_SQL INTO v_REALM_ID USING v_REALM.REALM_ID;
        	v_RET.EXTEND();
        	v_RET(v_RET.LAST) := ID_TYPE(v_REALM_ID);
        EXCEPTION
        	WHEN NO_DATA_FOUND THEN
        		NULL; -- ignore this error and continue
        END;
	END LOOP;

	-- ALL entities belong to the 'All Data' realm
	v_RET.EXTEND();
	v_RET(v_RET.LAST) := ID_TYPE(g_ALL_DATA_REALM_ID);

	RETURN v_RET;
END GET_REALMS_FOR_ENTITY_FIELDS;
----------------------------------------------------------------------------------
PROCEDURE GET_IDs_FOR_ACTION
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ACTION_ID OUT NUMBER,
	p_ENTITY_DOMAIN_ID OUT NUMBER
	) AS
BEGIN
	-- MAX will return NULL if no such action exists
	SELECT MAX(ACTION_ID), MAX(ENTITY_DOMAIN_ID) INTO p_ACTION_ID, p_ENTITY_DOMAIN_ID
	FROM SYSTEM_ACTION
	WHERE ACTION_NAME = p_ACTION_NAME;
END GET_IDs_FOR_ACTION;
----------------------------------------------------------------------------------
FUNCTION GET_ALLOWED_ENTITY_ID_TABLE
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN ID_TABLE AS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
v_DOMAIN_ID SYSTEM_ACTION.ENTITY_DOMAIN_ID%TYPE;
BEGIN
    
    $if $$UNIT_TEST_MODE = 1 $then
        IF UNIT_TEST_UTIL.g_TEST_SECURITY_IDS IS NOT NULL THEN
            RETURN UNIT_TEST_UTIL.g_TEST_SECURITY_IDS;
        END IF;
    $end
    
	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	END IF;

	GET_IDs_FOR_ACTION(p_ACTION_NAME, v_ACTION_ID, v_DOMAIN_ID);

	IF v_ACTION_ID IS NULL THEN
		RETURN ID_TABLE(); -- empty list
	ELSE
		RETURN GET_ALLOWED_ENTITY_ID_TABLE(v_ACTION_ID, v_DOMAIN_ID);
	END IF;
END GET_ALLOWED_ENTITY_ID_TABLE;
----------------------------------------------------------------------------------
FUNCTION GET_ALLOWED_ENTITY_ID_TABLE
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE AS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
BEGIN

    $if $$UNIT_TEST_MODE = 1 $then
        IF UNIT_TEST_UTIL.g_TEST_SECURITY_IDS IS NOT NULL THEN
            RETURN UNIT_TEST_UTIL.g_TEST_SECURITY_IDS;
        END IF;
    $end

	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	END IF;

	v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(p_ACTION_NAME);

	IF v_ACTION_ID IS NULL THEN
		RETURN ID_TABLE(); -- empty list
	ELSE
		RETURN GET_ALLOWED_ENTITY_ID_TABLE(v_ACTION_ID, p_ENTITY_DOMAIN_ID);
	END IF;
END GET_ALLOWED_ENTITY_ID_TABLE;
----------------------------------------------------------------------------------
FUNCTION GET_ALLOWED_ENTITY_ID_TABLE
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE AS

v_IDS ID_TABLE := ID_TABLE();
v_IS_ALL_DATA NUMBER;

BEGIN

    $if $$UNIT_TEST_MODE = 1 $then
        IF UNIT_TEST_UTIL.g_TEST_SECURITY_IDS IS NOT NULL THEN
            RETURN UNIT_TEST_UTIL.g_TEST_SECURITY_IDS;
        END IF;
    $end

	-- super-user or no authorization to be enforced?
	-- then return all data
	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	END IF;

	IF NVL(p_ENTITY_DOMAIN_ID,g_ALL_ENTITY_DOMAINS_ID) = g_ALL_ENTITY_DOMAINS_ID THEN
		-- cannot request 'all domains' - return empty list
		RETURN ID_TABLE();
	END IF;

	--check for assignment to All Data.
	SELECT COUNT(1)
	INTO v_IS_ALL_DATA
	FROM SYSTEM_ACTION_ROLE
	WHERE ACTION_ID = p_ACTION_ID
		AND ROLE_ID IN (SELECT X.ID FROM TABLE(CAST(SECURITY_CONTROLS.CURRENT_ROLES() AS ID_TABLE)) X)
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND REALM_ID = g_ALL_DATA_REALM_ID;

	IF v_IS_ALL_DATA = 0 THEN

		--This was not All Data.  Just get the list.
		SELECT ID_TYPE(ENTITY_ID)
		BULK COLLECT INTO v_IDS
		FROM (SELECT DISTINCT A.ENTITY_ID
				FROM SYSTEM_REALM_ENTITY A, SYSTEM_ACTION_ROLE B
				WHERE B.ACTION_ID = p_ACTION_ID
					AND B.ROLE_ID IN (SELECT X.ID FROM TABLE(CAST(SECURITY_CONTROLS.CURRENT_ROLES() AS ID_TABLE)) X)
					AND B.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
					AND A.REALM_ID = B.REALM_ID);
	ELSE
		-- all data assigned? then just return a single record
		v_IDS.EXTEND();
		v_IDS(v_IDS.LAST) := ID_TYPE(g_ALL_DATA_ENTITY_ID);
	END IF;

	RETURN v_IDS;

END GET_ALLOWED_ENTITY_ID_TABLE;
----------------------------------------------------------------------------------
FUNCTION ACTION_EXISTS
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN NUMBER AS

v_COUNT NUMBER;

BEGIN

    SELECT COUNT(A.ACTION_NAME) into v_COUNT
	FROM SYSTEM_ACTION A
	WHERE A.ACTION_NAME = p_ACTION_NAME;

	RETURN CASE WHEN v_COUNT > 0 THEN 1 ELSE 0 END;

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;

END ACTION_EXISTS;
----------------------------------------------------------------------------------
FUNCTION HAS_DATA_LEVEL_ACCESS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER
	) RETURN NUMBER AS
BEGIN

	RETURN UT.NUMBER_FROM_BOOLEAN(GET_ENTITY_IS_ALLOWED(p_ACTION_NAME, p_ENTITY_ID));

EXCEPTION
	WHEN OTHERS THEN
		RETURN 0;

END HAS_DATA_LEVEL_ACCESS;
----------------------------------------------------------------------------------
FUNCTION GET_ENTITY_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER
	) RETURN BOOLEAN AS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
v_DOMAIN_ID SYSTEM_ACTION.ENTITY_DOMAIN_ID%TYPE;
BEGIN

    $if $$UNIT_TEST_MODE = 1 $then
        IF UNIT_TEST_UTIL.g_TEST_SECURITY_IDS IS NOT NULL THEN
            IF UT.ID_TABLE_CONTAINS(UNIT_TEST_UTIL.g_TEST_SECURITY_IDS, SD.g_ALL_DATA_ENTITY_ID) THEN
                RETURN TRUE;
            END IF;
                
            RETURN UT.ID_TABLE_CONTAINS(UNIT_TEST_UTIL.g_TEST_SECURITY_IDS, p_ENTITY_ID);
        END IF;
    $end 

	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN TRUE;
	END IF;

	GET_IDs_FOR_ACTION(p_ACTION_NAME, v_ACTION_ID, v_DOMAIN_ID);

	IF v_ACTION_ID IS NULL THEN
		RETURN FALSE;
	ELSE
		RETURN GET_ENTITY_IS_ALLOWED(v_ACTION_ID, p_ENTITY_ID, v_DOMAIN_ID);
	END IF;
END GET_ENTITY_IS_ALLOWED;
----------------------------------------------------------------------------------
FUNCTION GET_ENTITY_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN BOOLEAN AS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
BEGIN
    $if $$UNIT_TEST_MODE = 1 $then
        IF UNIT_TEST_UTIL.g_TEST_SECURITY_IDS IS NOT NULL THEN
            IF UT.ID_TABLE_CONTAINS(UNIT_TEST_UTIL.g_TEST_SECURITY_IDS, SD.g_ALL_DATA_ENTITY_ID) THEN
                RETURN TRUE;
            END IF;
        
            RETURN UT.ID_TABLE_CONTAINS(UNIT_TEST_UTIL.g_TEST_SECURITY_IDS, p_ENTITY_ID);
        END IF;
    $end 

	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN TRUE;
	END IF;

	v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(p_ACTION_NAME);

	IF v_ACTION_ID IS NULL THEN
		RETURN FALSE;
	ELSE
		RETURN GET_ENTITY_IS_ALLOWED(v_ACTION_ID, p_ENTITY_ID, p_ENTITY_DOMAIN_ID);
	END IF;
END GET_ENTITY_IS_ALLOWED;
----------------------------------------------------------------------------------
FUNCTION GET_ENTITY_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN BOOLEAN AS
v_IS_ALL_DATA NUMBER;
v_IS_ALLOWED NUMBER;
BEGIN
    $if $$UNIT_TEST_MODE = 1 $then
        IF UNIT_TEST_UTIL.g_TEST_SECURITY_IDS IS NOT NULL THEN
            IF UT.ID_TABLE_CONTAINS(UNIT_TEST_UTIL.g_TEST_SECURITY_IDS, SD.g_ALL_DATA_ENTITY_ID) THEN
                RETURN TRUE;
            END IF;
        
            RETURN UT.ID_TABLE_CONTAINS(UNIT_TEST_UTIL.g_TEST_SECURITY_IDS, p_ENTITY_ID);
        END IF;
    $end 
    
	-- super-user or no authorization to be enforced?
	-- then return true
	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN TRUE;
	END IF;

	-- NO NEED TO DO DLS ON SELECTING NEW ENTITIES, THERE'S NO ACTUAL DATA THERE
	IF p_ENTITY_ID = CONSTANTS.NEW_ENT_ID and p_ACTION_ID = ENTITY_UTIL.GET_ACTION_ID(SD.g_ACTION_SELECT_ENT) THEN
		RETURN TRUE;
	END IF;

	IF NVL(p_ENTITY_DOMAIN_ID,g_ALL_ENTITY_DOMAINS_ID) = g_ALL_ENTITY_DOMAINS_ID THEN
		-- cannot request 'all domains' if action is defined
		-- for all domains - return false
		RETURN FALSE;
	END IF;

	--check for assignment to All Data.
	SELECT COUNT(1)
	INTO v_IS_ALL_DATA
	FROM SYSTEM_ACTION_ROLE
	WHERE ACTION_ID = p_ACTION_ID
		AND ROLE_ID IN (SELECT X.ID FROM TABLE(CAST(SECURITY_CONTROLS.CURRENT_ROLES() AS ID_TABLE)) X)
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND REALM_ID = g_ALL_DATA_REALM_ID;

	IF v_IS_ALL_DATA = 0 THEN
		--This was not All Data so query the realms to
		-- see if they contain the specified entity
		SELECT COUNT(1)
		INTO v_IS_ALLOWED
		FROM SYSTEM_REALM_ENTITY A, SYSTEM_ACTION_ROLE B
		WHERE B.ACTION_ID = p_ACTION_ID
			AND B.ROLE_ID IN (SELECT X.ID FROM TABLE(CAST(SECURITY_CONTROLS.CURRENT_ROLES() AS ID_TABLE)) X)
			AND B.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND A.REALM_ID = B.REALM_ID
			AND A.ENTITY_ID = p_ENTITY_ID;

		RETURN v_IS_ALLOWED > 0;
	ELSE
		-- all data assigned? then return true
		RETURN TRUE;
	END IF;

END GET_ENTITY_IS_ALLOWED;
----------------------------------------------------------------------------------

PROCEDURE VERIFY_ENTITY_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) AS
BEGIN
	IF NOT GET_ENTITY_IS_ALLOWED(p_ACTION_NAME, p_ENTITY_ID, p_ENTITY_DOMAIN_ID) THEN
		ERRS.RAISE_NO_PRIVILEGE_ACTION(p_ACTION_NAME, p_ENTITY_DOMAIN_ID, p_ENTITY_ID);
	END IF;
END VERIFY_ENTITY_IS_ALLOWED;
----------------------------------------------------------------------------------
PROCEDURE VERIFY_ENTITY_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) AS
BEGIN
	IF NOT GET_ENTITY_IS_ALLOWED(p_ACTION_ID, p_ENTITY_ID, p_ENTITY_DOMAIN_ID) THEN
		ERRS.RAISE_NO_PRIVILEGE_ACTION(ENTITY_NAME_FROM_IDS(EC.ED_SYSTEM_ACTION, p_ACTION_ID),
										p_ENTITY_DOMAIN_ID, p_ENTITY_ID);
	END IF;
END VERIFY_ENTITY_IS_ALLOWED;
----------------------------------------------------------------------------------
FUNCTION GET_ACTION_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	RETURN GET_ENTITY_IS_ALLOWED(p_ACTION_NAME, g_ALL_DATA_ENTITY_ID, CONSTANTS.NOT_ASSIGNED);
END GET_ACTION_IS_ALLOWED;
----------------------------------------------------------------------------------
FUNCTION GET_ACTION_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER
	) RETURN BOOLEAN IS
BEGIN
	RETURN GET_ENTITY_IS_ALLOWED(p_ACTION_ID, g_ALL_DATA_ENTITY_ID, CONSTANTS.NOT_ASSIGNED);
END GET_ACTION_IS_ALLOWED;
----------------------------------------------------------------------------------
PROCEDURE VERIFY_ACTION_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2
	) AS
BEGIN
	IF NOT GET_ACTION_IS_ALLOWED(p_ACTION_NAME) THEN
		ERRS.RAISE_NO_PRIVILEGE_ACTION(p_ACTION_NAME);
	END IF;
END VERIFY_ACTION_IS_ALLOWED;
----------------------------------------------------------------------------------
PROCEDURE VERIFY_ACTION_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER
	) AS
BEGIN
	IF NOT GET_ACTION_IS_ALLOWED(p_ACTION_ID) THEN
		ERRS.RAISE_NO_PRIVILEGE_ACTION(ENTITY_NAME_FROM_IDS(EC.ED_SYSTEM_ACTION, p_ACTION_ID));
	END IF;
END VERIFY_ACTION_IS_ALLOWED;
----------------------------------------------------------------------------------
FUNCTION GET_ALLOWED_REALM_ID_TABLE
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE IS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
BEGIN
	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN ID_TABLE(ID_TYPE(g_ALL_DATA_REALM_ID));
	END IF;

	v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(p_ACTION_NAME);

	IF v_ACTION_ID IS NULL THEN
		RETURN ID_TABLE(); -- empty list
	ELSE
		RETURN GET_ALLOWED_REALM_ID_TABLE(v_ACTION_ID, p_ENTITY_DOMAIN_ID);
	END IF;
END GET_ALLOWED_REALM_ID_TABLE;
----------------------------------------------------------------------------------
FUNCTION GET_ALLOWED_REALM_ID_TABLE
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE IS
v_IDS ID_TABLE := ID_TABLE();
v_IS_ALL_DATA NUMBER;
BEGIN
	-- super-user or no authorization to be enforced?
	-- then return all data
	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	END IF;

	IF NVL(p_ENTITY_DOMAIN_ID,g_ALL_ENTITY_DOMAINS_ID) = g_ALL_ENTITY_DOMAINS_ID THEN
		-- cannot request 'all domains' - return empty list
		RETURN ID_TABLE();
	END IF;

	--check for assignment to All Data.
	SELECT COUNT(1)
	INTO v_IS_ALL_DATA
	FROM SYSTEM_ACTION_ROLE
	WHERE ACTION_ID = p_ACTION_ID
		AND ROLE_ID IN (SELECT X.ID FROM TABLE(CAST(SECURITY_CONTROLS.CURRENT_ROLES() AS ID_TABLE)) X)
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND REALM_ID = g_ALL_DATA_REALM_ID;

	IF v_IS_ALL_DATA = 0 THEN
		--This was not All Data.  Just get the list.
		SELECT ID_TYPE(REALM_ID)
		BULK COLLECT INTO v_IDS
		FROM (SELECT DISTINCT REALM_ID
				FROM SYSTEM_ACTION_ROLE
				WHERE ACTION_ID = p_ACTION_ID
					AND ROLE_ID IN (SELECT X.ID FROM TABLE(CAST(SECURITY_CONTROLS.CURRENT_ROLES() AS ID_TABLE)) X)
					AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID);
	ELSE
		-- all data assigned? then just return a single record
		v_IDS.EXTEND();
		v_IDS(v_IDS.LAST) := ID_TYPE(g_ALL_DATA_REALM_ID);
	END IF;

	RETURN v_IDS;
END GET_ALLOWED_REALM_ID_TABLE;
----------------------------------------------------------------------------------
FUNCTION IS_ALLOWED_FOR_REALMS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_REALMS IN ID_TABLE
	) RETURN BOOLEAN IS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
BEGIN
	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN TRUE;
	END IF;

	v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(p_ACTION_NAME);

	IF v_ACTION_ID IS NULL THEN
		RETURN FALSE;
	ELSE
		RETURN IS_ALLOWED_FOR_REALMS(v_ACTION_ID, p_ENTITY_DOMAIN_ID, p_REALMS);
	END IF;
END IS_ALLOWED_FOR_REALMS;
----------------------------------------------------------------------------------
FUNCTION IS_ALLOWED_FOR_REALMS
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_REALMS IN ID_TABLE
	) RETURN BOOLEAN IS
v_COUNT BINARY_INTEGER;
BEGIN
	IF NOT SECURITY_CONTROLS.IS_AUTH_ENABLED THEN
		RETURN TRUE;
	END IF;

	SELECT COUNT(1)
	INTO v_COUNT
	FROM SYSTEM_ACTION_ROLE A,
		TABLE(CAST(p_REALMS AS ID_TABLE)) X,
		TABLE(CAST(SECURITY_CONTROLS.CURRENT_ROLES() AS ID_TABLE)) Y
	WHERE A.ROLE_ID = Y.ID
		AND A.REALM_ID IN (X.ID,g_ALL_DATA_REALM_ID)
		AND A.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND A.ACTION_ID = p_ACTION_ID;

	RETURN v_COUNT > 0;
END IS_ALLOWED_FOR_REALMS;
----------------------------------------------------------------------------------
-- Private method which all other GET_ALLOWED_IDS_FROM_SELECTION procedures call.
FUNCTION GET_ALLOWED_IDS_FROM_SELECTION
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SELECTED_IDS IN NUMBER_COLLECTION,
	p_RAISE_EXCEPTION IN BOOLEAN
	) RETURN NUMBER_COLLECTION IS
	v_ALLOWED_IDS NUMBER_COLLECTION := NUMBER_COLLECTION();
BEGIN
	--Return nothing if this action is invalid.
	IF (p_ACTION_ID IS NULL AND SECURITY_CONTROLS.IS_AUTH_ENABLED) OR p_SELECTED_IDS IS NULL THEN
		NULL;
	--If this is the all data realm, just return all the selected IDs.
	ELSIF GET_ENTITY_IS_ALLOWED(p_ACTION_ID, g_ALL_DATA_ENTITY_ID, p_ENTITY_DOMAIN_ID) THEN
		v_ALLOWED_IDS := p_SELECTED_IDS;
	--Otherwise, check each ID before we add it.
	ELSE
		FOR i IN p_SELECTED_IDS.FIRST .. p_SELECTED_IDS.LAST LOOP
			--Check that we have access to this ID.
			IF GET_ENTITY_IS_ALLOWED(p_ACTION_ID, p_SELECTED_IDS(i), p_ENTITY_DOMAIN_ID) THEN
				v_ALLOWED_IDS.EXTEND();
				v_ALLOWED_IDS(v_ALLOWED_IDS.LAST) := p_SELECTED_IDS(i);
			ELSE
				IF p_RAISE_EXCEPTION THEN
					ERRS.RAISE_NO_PRIVILEGE_ACTION(ENTITY_NAME_FROM_IDS(EC.ED_SYSTEM_ACTION, p_ACTION_ID), -- get action name
													p_ENTITY_DOMAIN_ID, p_SELECTED_IDS(i) -- and entity ID
													);
				END IF;
			END IF;
		END LOOP;
	END IF;
	RETURN v_ALLOWED_IDS;

END GET_ALLOWED_IDS_FROM_SELECTION;
---------------------------------------------------------------------------------------------------------------
-- Filters a list of selected IDs per the specified action name and
-- current user's privileges.
-- An exception will be raised if the p_RAISE_EXCEPTION flag is set
-- the ID table contains an ID to which the current user has no access.
-- (Can be used instead of UT.ID_TABLE_FROM_STRING)
FUNCTION GET_ALLOWED_IDS_FROM_SELECTION
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SELECTED_ITEMS IN VARCHAR2,
	p_DELIMITER IN CHAR,
	p_RAISE_EXCEPTION IN BOOLEAN := TRUE
	) RETURN NUMBER_COLLECTION IS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
v_COLL NUMBER_COLLECTION;
BEGIN
	v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(p_ACTION_NAME);
	UT.NUMBER_COLL_FROM_STRING(p_SELECTED_ITEMS, p_DELIMITER, v_COLL);
	RETURN GET_ALLOWED_IDS_FROM_SELECTION(v_ACTION_ID, p_ENTITY_DOMAIN_ID, v_COLL, p_RAISE_EXCEPTION);
END GET_ALLOWED_IDS_FROM_SELECTION;
---------------------------------------------------------------------------------------------------------------
-- Same as above, except a NUMBER_COLLECTION is used as the selection rather
-- than a VARCHAR2.
FUNCTION GET_ALLOWED_IDS_FROM_SELECTION
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SELECTED_ITEMS IN NUMBER_COLLECTION,
	p_RAISE_EXCEPTION IN BOOLEAN := TRUE
	) RETURN NUMBER_COLLECTION IS
v_ACTION_ID SYSTEM_ACTION.ACTION_ID%TYPE;
BEGIN
	v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(p_ACTION_NAME);
	RETURN GET_ALLOWED_IDS_FROM_SELECTION(v_ACTION_ID, p_ENTITY_DOMAIN_ID, p_SELECTED_ITEMS, p_RAISE_EXCEPTION);
END GET_ALLOWED_IDS_FROM_SELECTION;
---------------------------------------------------------------------------------------------------------------
PROCEDURE PROC_HAS_DATA_LEVEL_ACCESS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_RESULT OUT NUMBER
	) AS
BEGIN
	p_RESULT := HAS_DATA_LEVEL_ACCESS(p_ACTION_NAME, p_ENTITY_ID);
END PROC_HAS_DATA_LEVEL_ACCESS;
----------------------------------------------------------------------------------------------------
PROCEDURE PROC_ACTION_EXISTS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_RESULT OUT NUMBER
	) AS
BEGIN
	p_RESULT := ACTION_EXISTS(p_ACTION_NAME);
END PROC_ACTION_EXISTS;

----------------------------------------------------------------------------------------------------
PROCEDURE REALM_LIST_FOR_ENTITY_DOMAIN
	(
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_DOMAIN_ID IN NUMBER,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    ) AS

    v_ENTITY_DOMAIN_ID NUMBER;

BEGIN

    p_STATUS := GA.SUCCESS;

    IF p_ENTITY_DOMAIN_ID = -1 THEN
   		v_ENTITY_DOMAIN_ID := p_DOMAIN_ID;
    ELSE
    	v_ENTITY_DOMAIN_ID := p_ENTITY_DOMAIN_ID;
    END IF;

    OPEN p_CURSOR FOR
			SELECT A.REALM_NAME "REALM_NAME", A.REALM_ID "REALM_ID", 0 "ORDER"
			FROM SYSTEM_REALM A
			WHERE A.REALM_ID = g_ALL_DATA_REALM_ID
			UNION ALL
			SELECT A.REALM_NAME "REALM_NAME", A.REALM_ID "REALM_ID", 1 "ORDER" FROM SYSTEM_REALM A
			WHERE A.REALM_ID != g_ALL_DATA_REALM_ID
				AND (A.ENTITY_DOMAIN_ID = v_ENTITY_DOMAIN_ID AND NVL(REALM_CALC_TYPE,0) = 0)
			ORDER BY 3,1;

END REALM_LIST_FOR_ENTITY_DOMAIN;
---------------------------------------------------------------------------------------------------------------------------
PROCEDURE REALM_LIST
	(
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    ) AS

    BEGIN

    p_STATUS := GA.SUCCESS;

	-- This proceude is to select Realm List based on the Entity Domain ID.
	-- It returns all the Realms that is applied to this domain along with a blank for the
	IF p_ENTITY_DOMAIN_ID IS NOT NULL THEN
    	OPEN p_CURSOR FOR
			SELECT A.REALM_NAME "REALM_NAME", A.REALM_ID "REALM_ID", 1 "ORDER"
			FROM SYSTEM_REALM A
			WHERE A.REALM_ID = g_ALL_DATA_REALM_ID
			UNION ALL
			SELECT A.REALM_NAME "REALM_NAME", A.REALM_ID "REALM_ID", 2 "ORDER" FROM SYSTEM_REALM A
			WHERE A.REALM_ID != g_ALL_DATA_REALM_ID
				AND (A.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID AND NVL(REALM_CALC_TYPE,0) <> 1)
        	UNION ALL
        	SELECT ' ' "REALM_NAME", -1 "REALM_ID", 0 "ORDER"
        	FROM DUAL
			ORDER BY 3,1;
	ELSE
		OPEN p_CURSOR FOR
			SELECT ' ' "REALM_NAME", -1 "REALM_ID", 0 "ORDER"
        	FROM DUAL
			UNION ALL
			SELECT A.REALM_NAME "REALM_NAME", A.REALM_ID "REALM_ID", 1 "ORDER"
			FROM SYSTEM_REALM A
			WHERE A.REALM_ID = g_ALL_DATA_REALM_ID
			ORDER BY 3,1;
	END IF;

END REALM_LIST;
--------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITIES_IN_REALM
	(
	p_REALM_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN
	p_STATUS := GA.SUCCESS;

	OPEN p_CURSOR FOR
		SELECT A.REALM_ID, B.REALM_NAME,
				A.ENTITY_ID, ENTITY_NAME_FROM_IDS(B.ENTITY_DOMAIN_ID, A.ENTITY_ID) "ENTITY_NAME"
		FROM SYSTEM_REALM_ENTITY A, SYSTEM_REALM B
		WHERE A.REALM_ID = p_REALM_ID
			AND A.REALM_ID = B.REALM_ID
		ORDER BY 4;

END GET_ENTITIES_IN_REALM;
---------------------------------------------------------------------------------------------------
PROCEDURE LIST_ACTIONS_BY_DOMAIN
	(
	p_ENTITY_DOMAIN_ID IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	-- If specified domain is 'Not Assigned', show actions with 'Not Assigned' domain
	-- otherwise show actions with specified domain AND include actions with a domain of 'ALL'
	OPEN p_CURSOR FOR
		SELECT ACTION_NAME, ACTION_ID
		FROM SYSTEM_ACTION
		WHERE (NVL(p_ENTITY_DOMAIN_ID,0) = 0 AND ENTITY_DOMAIN_ID = 0)
			OR (NVL(p_ENTITY_DOMAIN_ID,0) <> 0 AND ENTITY_DOMAIN_ID IN (g_ALL_ENTITY_DOMAINS_ID, p_ENTITY_DOMAIN_ID))
		ORDER BY 1;
END LIST_ACTIONS_BY_DOMAIN;
---------------------------------------------------------------------------------------------------
-- Enumerate all entities to which user has specified privilege. Unlike
-- GET_ALLOWED_ENTITY_ID_TABLE, this will expand 'all data' to all the actual
-- domain members. Furthermore, it can optionally intersect the resulting list
-- of entities with those in the specified realm and/or group. If a group ID
-- is specified then begin and end dates must also be specified since group
-- assignments are temporal. If a group ID is specified, and p_IGNORE_PRIVS is
-- false (the default) then the enumeration will exclude entities assigned to
-- elements of the group hierarchy to which the current user does not have
-- 'Select Entity' privilege. Finally, it returns a WORK_ID instead of an ID_TABLE.
-- RTO_WORK will be populated with WORK_XID as the entity ID and WORK_DATA as the
-- entity name.
PROCEDURE ENUMERATE_ENTITIES
	(
	p_ACTION_NAME			IN VARCHAR2,
	p_ENTITY_DOMAIN_ID		IN NUMBER,
	p_WORK_ID				OUT NUMBER,
	p_INTERSECT_REALM_ID	IN NUMBER := NULL,
	p_INTERSECT_GROUP_ID	IN NUMBER := NULL,
	p_BEGIN_DATE			IN DATE := NULL,
	p_END_DATE				IN DATE := NULL,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) AS
v_ACTION_ID	SYSTEM_ACTION.ACTION_ID%TYPE;
BEGIN
	IF p_ACTION_NAME IS NULL THEN
		-- null name? then return all entities, unfiltered by action
		v_ACTION_ID := NULL;
	ELSE
		v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(p_ACTION_NAME);

		-- bad action? return NULL work ID and do nothing
		IF v_ACTION_ID IS NULL THEN
			p_WORK_ID := NULL;
			RETURN;
		END IF;
	END IF;

	ENUMERATE_ENTITIES(v_ACTION_ID, p_ENTITY_DOMAIN_ID, p_WORK_ID, p_INTERSECT_REALM_ID,
					p_INTERSECT_GROUP_ID, p_BEGIN_DATE, p_END_DATE, p_IGNORE_GROUP_PRIVS);
END ENUMERATE_ENTITIES;
---------------------------------------------------------------------------------------------------
PROCEDURE ENUMERATE_ENTITIES
	(
	p_ACTION_ID				IN NUMBER,
	p_ENTITY_DOMAIN_ID		IN NUMBER,
	p_WORK_ID				OUT NUMBER,
	p_INTERSECT_REALM_ID	IN NUMBER := NULL,
	p_INTERSECT_GROUP_ID	IN NUMBER := NULL,
	p_BEGIN_DATE			IN DATE := NULL,
	p_END_DATE				IN DATE := NULL,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) AS
v_DOMAIN_ID 	ENTITY_DOMAIN.ENTITY_DOMAIN_ID%TYPE;
v_REALM_WORK_ID	RTO_WORK.WORK_ID%TYPE;
v_GROUP_WORK_ID	RTO_WORK.WORK_ID%TYPE;
v_IDs			ID_TABLE;
v_SQL			VARCHAR2(512);
v_WHERE			VARCHAR2(512);
v_TBL_NAME		VARCHAR2(32);
v_ID_COL_NAME	VARCHAR2(32);
BEGIN
	-- find members of intersecting realm - if specified
	IF p_INTERSECT_REALM_ID IS NOT NULL AND p_INTERSECT_REALM_ID <> g_ALL_DATA_REALM_ID THEN
		SELECT MAX(ENTITY_DOMAIN_ID)
		INTO v_DOMAIN_ID
		FROM SYSTEM_REALM
		WHERE REALM_ID = p_INTERSECT_REALM_ID;

		IF NVL(v_DOMAIN_ID,0) <> p_ENTITY_DOMAIN_ID THEN
			ERRS.RAISE_BAD_ARGUMENT('INTERSECT_REALM_ID',p_INTERSECT_REALM_ID,
									'Domain for '||TEXT_UTIL.TO_CHAR_ENTITY(p_INTERSECT_REALM_ID,EC.ED_SYSTEM_REALM)||
									' ('||TEXT_UTIL.TO_CHAR_ENTITY(v_DOMAIN_ID,EC.ED_ENTITY_DOMAIN)||') '||
									'must match specified domain: '||
									TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_DOMAIN_ID,EC.ED_ENTITY_DOMAIN));
		END IF;

		ENUMERATE_SYSTEM_REALM_MEMBERS(p_INTERSECT_REALM_ID, v_REALM_WORK_ID);
	END IF;

	-- find members of intersecting group - if specified
	IF p_INTERSECT_GROUP_ID IS NOT NULL THEN
		SELECT MAX(ENTITY_DOMAIN_ID)
		INTO v_DOMAIN_ID
		FROM ENTITY_GROUP
		WHERE ENTITY_GROUP_ID = p_INTERSECT_GROUP_ID;

		IF NVL(v_DOMAIN_ID,0) <> p_ENTITY_DOMAIN_ID THEN
			ERRS.RAISE_BAD_ARGUMENT('INTERSECT_GROUP_ID',p_INTERSECT_REALM_ID,
									'Domain for '||TEXT_UTIL.TO_CHAR_ENTITY(p_INTERSECT_GROUP_ID,EC.ED_ENTITY_GROUP)||
									' ('||TEXT_UTIL.TO_CHAR_ENTITY(v_DOMAIN_ID,EC.ED_ENTITY_DOMAIN)||') '||
									'must match specified domain: '||
									TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_DOMAIN_ID,EC.ED_ENTITY_DOMAIN));
		END IF;

		-- ignore member privileges since we're already figuring that based on specified action ID
		ENUMERATE_ENTITY_GROUP_MEMBERS(p_INTERSECT_GROUP_ID, p_BEGIN_DATE, p_END_DATE, v_GROUP_WORK_ID, p_IGNORE_GROUP_PRIVS, TRUE);
	END IF;

	-- dynamic SQL used to enumerate entities
	IF p_ACTION_ID IS NULL THEN
		v_IDs := ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	ELSE
		v_IDs := GET_ALLOWED_ENTITY_ID_TABLE(p_ACTION_ID, p_ENTITY_DOMAIN_ID);
	END IF;
	UT.GET_RTO_WORK_ID(p_WORK_ID);

	SELECT N.TABLE_NAME, N.PRIMARY_ID_COLUMN
	INTO v_TBL_NAME, v_ID_COL_NAME
	FROM ENTITY_DOMAIN D, NERO_TABLE_PROPERTY_INDEX N
	WHERE D.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND N.TABLE_NAME = D.ENTITY_DOMAIN_TABLE;

	v_SQL := 'INSERT INTO RTO_WORK (WORK_ID, WORK_XID, WORK_DATA) '||
			'SELECT :1, A.'||v_ID_COL_NAME||', A.'||SUBSTR(v_ID_COL_NAME,1,LENGTH(v_ID_COL_NAME)-3)||'_NAME '||
			'FROM '||v_TBL_NAME||' A, TABLE(CAST(:2 as ID_TABLE)) IDs ';
	v_WHERE := ' WHERE IDs.ID IN (:3, '||v_ID_COL_NAME||')';

	IF v_REALM_WORK_ID IS NOT NULL THEN
		v_SQL := v_SQL||', RTO_WORK R';
		v_WHERE := v_WHERE||' AND R.WORK_ID = :4 AND A.'||v_ID_COL_NAME||' = R.WORK_XID';
	END IF;
	IF v_GROUP_WORK_ID IS NOT NULL THEN
		v_SQL := v_SQL||', RTO_WORK G';
		v_WHERE := v_WHERE||' AND G.WORK_ID = :5 AND G.'||v_ID_COL_NAME||' = G.WORK_XID';
	END IF;

	IF v_REALM_WORK_ID IS NOT NULL AND v_GROUP_WORK_ID IS NOT NULL THEN
		EXECUTE IMMEDIATE v_SQL||v_WHERE
			USING p_WORK_ID, v_IDs, g_ALL_DATA_ENTITY_ID, v_REALM_WORK_ID, v_GROUP_WORK_ID;
	ELSIF v_REALM_WORK_ID IS NOT NULL THEN
		EXECUTE IMMEDIATE v_SQL||v_WHERE
			USING p_WORK_ID, v_IDs, g_ALL_DATA_ENTITY_ID, v_REALM_WORK_ID;
	ELSIF v_GROUP_WORK_ID IS NOT NULL THEN
		EXECUTE IMMEDIATE v_SQL||v_WHERE
			USING p_WORK_ID, v_IDs, g_ALL_DATA_ENTITY_ID, v_GROUP_WORK_ID;
	ELSE
		EXECUTE IMMEDIATE v_SQL||v_WHERE
			USING p_WORK_ID, v_IDs, g_ALL_DATA_ENTITY_ID;
	END IF;

EXCEPTION
	WHEN OTHERS THEN
		IF v_REALM_WORK_ID IS NOT NULL THEN
			UT.PURGE_RTO_WORK(v_REALM_WORK_ID);
		END IF;
		IF v_GROUP_WORK_ID IS NOT NULL THEN
			UT.PURGE_RTO_WORK(v_GROUP_WORK_ID);
		END IF;
		ERRS.LOG_AND_RAISE;

END ENUMERATE_ENTITIES;
---------------------------------------------------------------------------------------------------
-- Enumerate all entities that belong to a specified realm. If the specified
-- realm is 'all data' then this will enumerate all entities in the realm's
-- domain. On return, RTO_WORK will be populated with WORK_XID as the entity ID
-- and WORK_DATA as the entity name.
PROCEDURE ENUMERATE_SYSTEM_REALM_MEMBERS
	(
	p_REALM_ID	IN NUMBER,
	p_WORK_ID	OUT NUMBER
	) AS
BEGIN
	UT.GET_RTO_WORK_ID(p_WORK_ID);

	INSERT INTO RTO_WORK (WORK_ID, WORK_XID, WORK_DATA)
	SELECT p_WORK_ID, E.ENTITY_ID, ENTITY_NAME_FROM_IDS(R.ENTITY_DOMAIN_ID, E.ENTITY_ID)
	FROM SYSTEM_REALM R, SYSTEM_REALM_ENTITY E
	WHERE R.REALM_ID = p_REALM_ID
		AND E.REALM_ID = R.REALM_ID;

END ENUMERATE_SYSTEM_REALM_MEMBERS;
---------------------------------------------------------------------------------------------------
PROCEDURE ENUMERATE_UNION_OF_ENTITIES
	(
	p_GROUP_IDs				IN NUMBER_COLLECTION,
	p_REALM_IDs				IN NUMBER_COLLECTION,
	p_ENTITY_IDs			IN NUMBER_COLLECTION,
	p_ENTITY_DOMAIN_ID		IN NUMBER,
	p_WORK_ID				OUT NUMBER,
	p_BEGIN_DATE			IN DATE := NULL,
	p_END_DATE				IN DATE := NULL,
	p_IGNORE_GROUP_PRIVS 	IN BOOLEAN := FALSE,
	p_IGNORE_MEMBER_PRIVS	IN BOOLEAN := FALSE
	) AS

v_WORK_ID NUMBER(9);
v_COUNT NUMBER(9);
v_WORK_IDs NUMBER_COLLECTION := NUMBER_COLLECTION();

BEGIN
	UT.GET_RTO_WORK_ID(p_WORK_ID);
	-- Get the Entity Group members
	-- Keep the work ids
	IF p_GROUP_IDs IS NOT NULL THEN
		FOR v_IDX IN 1..p_GROUP_IDs.COUNT LOOP
			ENUMERATE_ENTITY_GROUP_MEMBERS(p_GROUP_IDs(v_IDX), p_BEGIN_DATE, p_END_DATE, v_WORK_ID, p_IGNORE_GROUP_PRIVS, p_IGNORE_MEMBER_PRIVS);
			v_WORK_IDs.EXTEND;
			v_WORK_IDs(v_IDX) := v_WORK_ID;
		END LOOP;
	END IF;
	
	v_COUNT := v_WORK_IDs.COUNT;
	-- Enumerate the system realm members 
	-- Keep the work ids
	IF p_REALM_IDs IS NOT NULL THEN 
		FOR v_IDX IN 1..p_REALM_IDs.COUNT LOOP
			ENUMERATE_SYSTEM_REALM_MEMBERS(p_REALM_IDs(v_IDX), v_WORK_ID);
			v_WORK_IDs.EXTEND;
			v_WORK_IDs(v_COUNT + v_IDX) := v_WORK_ID;
		END LOOP;
	END IF;
	
	INSERT INTO RTO_WORK(WORK_ID, WORK_XID, WORK_DATA)
	SELECT p_WORK_ID, WRK.WORK_XID, WRK.WORK_DATA 
		FROM RTO_WORK WRK, TABLE(CAST(v_WORK_IDs AS NUMBER_COLLECTION)) IDS 
		WHERE WRK.WORK_ID = IDS.COLUMN_VALUE
		UNION 
		SELECT p_WORK_ID, IDS.COLUMN_VALUE, ENTITY_NAME_FROM_IDS(p_ENTITY_DOMAIN_ID, IDS.COLUMN_VALUE)
		FROM TABLE(CAST(p_ENTITY_IDs AS NUMBER_COLLECTION)) IDS;
	
END ENUMERATE_UNION_OF_ENTITIES;
---------------------------------------------------------------------------------------------------
-- Is the specified entity a member of the specified realm?
FUNCTION IS_MEMBER_OF_SYSTEM_REALM
	(
	p_ENTITY_ID	IN NUMBER,
	p_REALM_ID	IN NUMBER
	) RETURN BOOLEAN IS
v_COUNT PLS_INTEGER;
BEGIN
	IF p_REALM_ID = g_ALL_DATA_REALM_ID THEN
		RETURN TRUE;
	ELSE
		SELECT COUNT(1)
		INTO v_COUNT
		FROM SYSTEM_REALM_ENTITY
		WHERE REALM_ID = p_REALM_ID
			AND ENTITY_ID = p_ENTITY_ID
			AND ROWNUM=1;

		RETURN v_COUNT > 0;
	END IF;

END IS_MEMBER_OF_SYSTEM_REALM;
---------------------------------------------------------------------------------------------------
-- Enumerate all entities that belong to a group. This will return all entities
-- that are assigned to the entire hierarchy of the specified group and its
-- sub-tree of child groups. Since this relationship is temporal, a date range
-- is required. All entities assigned to this group for any period that overlaps
-- the specified date range will be included in the final enumeration. On return,
-- RTO_WORK will be populated with WORK_XID as the entity ID and WORK_DATA as the
-- entity name. NOTE if p_IGNORE_PRIVS is false (the default) then the set of
-- members in RTO_WORK will ONLY include entities to which the current user has
-- 'Select Entity' privilege. Furthermore, it will not search elements of the group
-- hierarchy to which the user does not also have 'Select Entity' privilege.
PROCEDURE ENUMERATE_ENTITY_GROUP_MEMBERS
	(
	p_GROUP_ID				IN NUMBER,
	p_BEGIN_DATE			IN DATE,
	p_END_DATE				IN DATE,
	p_WORK_ID				OUT NUMBER,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE,
	p_IGNORE_MEMBER_PRIVS	IN BOOLEAN := FALSE
	) AS
v_GROUP_IDs		ID_TABLE;
v_ENTITY_IDs	ID_TABLE;
v_DOMAIN_ID		ENTITY_GROUP.ENTITY_DOMAIN_ID%TYPE;
v_IS_MATRIX		ENTITY_GROUP.IS_MATRIX%TYPE;
BEGIN
	UT.GET_RTO_WORK_ID(p_WORK_ID);

	SELECT NVL(IS_MATRIX, 0) INTO v_IS_MATRIX
	FROM ENTITY_GROUP E
	WHERE E.ENTITY_GROUP_ID = p_GROUP_ID;

	IF v_IS_MATRIX = 1 THEN
			ERRS.RAISE_BAD_ARGUMENT('GROUP', TEXT_UTIL.TO_CHAR_ENTITY(p_GROUP_ID, EC.ED_ENTITY_GROUP),
											'The specified entity group is a matrix; matrices are not supported.');
	END IF;

	-- ignoring group privileges? then set group list to 'all data'
	IF p_IGNORE_GROUP_PRIVS THEN
		v_GROUP_IDs := ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	ELSE
		v_GROUP_IDs := GET_ALLOWED_ENTITY_ID_TABLE(g_ACTION_SELECT_ENT, EC.ED_ENTITY_GROUP);
	END IF;

	-- ignoring member privileges? then set entity list to 'all data'
	IF p_IGNORE_MEMBER_PRIVS THEN
		v_ENTITY_IDs := ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	ELSE
		SELECT MAX(ENTITY_DOMAIN_ID)
		INTO v_DOMAIN_ID
		FROM ENTITY_GROUP
		WHERE ENTITY_GROUP_ID = p_GROUP_ID;

		v_ENTITY_IDs := GET_ALLOWED_ENTITY_ID_TABLE(g_ACTION_SELECT_ENT, v_DOMAIN_ID);
	END IF;

	INSERT INTO RTO_WORK (WORK_ID, WORK_XID, WORK_DATA)
	SELECT p_WORK_ID, A.ENTITY_ID, ENTITY_NAME_FROM_IDS(G.ENTITY_DOMAIN_ID, A.ENTITY_ID)
	FROM (SELECT ENTITY_GROUP_ID, ENTITY_DOMAIN_ID
			FROM ENTITY_GROUP, TABLE(CAST(v_GROUP_IDs as ID_TABLE)) IDs
			START WITH ENTITY_GROUP_ID = p_GROUP_ID
				AND IDs.ID IN (g_ALL_DATA_ENTITY_ID, ENTITY_GROUP_ID)
			CONNECT BY PARENT_GROUP_ID = PRIOR ENTITY_GROUP_ID
				AND IDs.ID IN (g_ALL_DATA_ENTITY_ID, ENTITY_GROUP_ID)
				-- filter out any improperly configured groups that have
				-- children with the wrong domain
				AND ENTITY_DOMAIN_ID = PRIOR ENTITY_DOMAIN_ID) G,
		ENTITY_GROUP_ASSIGNMENT A,
		TABLE(CAST(v_ENTITY_IDs as ID_TABLE)) IDs
	WHERE A.ENTITY_GROUP_ID = G.ENTITY_GROUP_ID
		-- find assignments that overlap the specified date range
		AND A.BEGIN_DATE <= p_END_DATE
		AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
		AND IDs.ID IN (g_ALL_DATA_ENTITY_ID, A.ENTITY_ID);

END ENUMERATE_ENTITY_GROUP_MEMBERS;
---------------------------------------------------------------------------------------------------
-- Is the specified entity a member of the specified group or its sub-tree during
-- the specified date range? If p_IGNORE_PRIVS is false (the default) then this
-- method will not search elements of the group hierarchy to which the current user
-- does not have 'Select Entity' privilege.
FUNCTION IS_MEMBER_OF_ENTITY_GROUP
	(
	p_ENTITY_ID				IN NUMBER,
	p_GROUP_ID				IN NUMBER,
	p_BEGIN_DATE			IN DATE,
	p_END_DATE				IN DATE,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) RETURN BOOLEAN IS
v_GROUP_IDs		ID_TABLE;
v_COUNT			PLS_INTEGER;
v_IS_MATRIX		ENTITY_GROUP.IS_MATRIX%TYPE;
BEGIN

	SELECT NVL(IS_MATRIX, 0) INTO v_IS_MATRIX
	FROM ENTITY_GROUP E
	WHERE E.ENTITY_GROUP_ID = p_GROUP_ID;

	IF v_IS_MATRIX = 1 THEN
			ERRS.RAISE_BAD_ARGUMENT('GROUP', TEXT_UTIL.TO_CHAR_ENTITY(p_GROUP_ID, EC.ED_ENTITY_GROUP),
											'The specified entity group is a matrix; matrices are not supported.');
	END IF;

	-- ignoring group privileges? then set group list to 'all data'
	IF p_IGNORE_GROUP_PRIVS THEN
		v_GROUP_IDs := ID_TABLE(ID_TYPE(g_ALL_DATA_ENTITY_ID));
	ELSE
		v_GROUP_IDs := GET_ALLOWED_ENTITY_ID_TABLE(g_ACTION_SELECT_ENT, EC.ED_ENTITY_GROUP);
	END IF;

	SELECT COUNT(1)
	INTO v_COUNT
	FROM (SELECT ENTITY_GROUP_ID, ENTITY_DOMAIN_ID
			FROM ENTITY_GROUP, TABLE(CAST(v_GROUP_IDs as ID_TABLE)) IDs
			START WITH ENTITY_GROUP_ID = p_GROUP_ID
				AND IDs.ID IN (g_ALL_DATA_ENTITY_ID, ENTITY_GROUP_ID)
			CONNECT BY PARENT_GROUP_ID = PRIOR ENTITY_GROUP_ID
				AND IDs.ID IN (g_ALL_DATA_ENTITY_ID, ENTITY_GROUP_ID)
				-- filter out any improperly configured groups that have
				-- children with the wrong domain
				AND ENTITY_DOMAIN_ID = PRIOR ENTITY_DOMAIN_ID) G,
		ENTITY_GROUP_ASSIGNMENT A
	WHERE A.ENTITY_GROUP_ID = G.ENTITY_GROUP_ID
		-- find assignments that overlap the specified date range
		AND A.BEGIN_DATE <= p_END_DATE
		AND NVL(A.END_DATE, CONSTANTS.HIGH_DATE) >= p_BEGIN_DATE
		AND A.ENTITY_ID = p_ENTITY_ID
		AND ROWNUM=1;

	RETURN v_COUNT > 0;

END IS_MEMBER_OF_ENTITY_GROUP;
---------------------------------------------------------------------------------------------------
END SD;
/
