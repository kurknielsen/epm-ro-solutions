CREATE OR REPLACE PACKAGE DATA_LOCK IS
--Revision $Revision: 1.3 $

  -- Author  : JHUMPHRIES
  -- Created : 8/26/2008
  -- Purpose : API for locking/unlocking/restricting data

FUNCTION WHAT_VERSION RETURN VARCHAR2;

-- Constants for Lock State, for use with UPDATE_LOCK_STATE
c_LOCK_STATE_LOCKED		CONSTANT CHAR := 'L';
c_LOCK_STATE_RESTRICTED	CONSTANT CHAR := 'R';
c_LOCK_STATE_UNLOCKED	CONSTANT CHAR := 'U';

-- Constants for behavior, for use with HANDLE_DATA_LOCKED_EXCEPTION
c_BEHAVIOR_ERROR		CONSTANT VARCHAR2(16) := 'ERROR';
c_BEHAVIOR_WARN			CONSTANT VARCHAR2(16) := 'WARNING';
c_BEHAVIOR_IGNORE		CONSTANT VARCHAR2(16) := 'IGNORE';

-- Constants for "apply when" parameter for overloaded for of UPDATE_LOCK_STATE
c_APPLY_ON_LAST			CONSTANT PLS_INTEGER := 1;
c_APPLY_ON_OVERLAP		CONSTANT PLS_INTEGER := 0;

-- Gets the key constraint name for the specified table's corresponding lock
-- summary table.
-- %param p_TABLE_ID		The ID of the System Table entity whose lock summary key constraint
--							is to be returned.
-- %return	The name of the primary or unique constraint that represents the key for the lock
-- 			summary table of the specified System Table.
FUNCTION GET_LOCK_SUMMARY_KEY
	(
	p_TABLE_ID IN NUMBER
	) RETURN VARCHAR2;

-- Changes the lock state of data records.
-- %param p_TABLE_ID		The ID of a System Table entity.
-- %param p_ENTITY_ID		The entity ID is the value of the table's entity ID column (if it has
--							one).
-- %param p_CUT_BEGIN_DATE	The CUT begin date. This should actually be a local date if the data
--							interval is daily or greater. It should be a "Scheduling" date (i.e.
--							one second past midnight) if the underlying data is stored using
--							"Scheduling" dates.
-- %param p_CUT_END_DATE	The CUT end date. These dates represent the date range of records to
--							lock/unlock.
-- %param p_CRITERIA		The criteria map specifies values for additional columns in the table
--							for identifying precisely which records are to be locked/unlocked.
-- %param p_LOCK_STATE		The new lock state. This should be one of the c_LOCK_STATE_* constants.
-- %return	The number of data records effected.
FUNCTION UPDATE_LOCK_STATE
	(
	p_TABLE_ID		 IN NUMBER,
	p_ENTITY_ID		 IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE	 IN DATE,
	p_CRITERIA		 IN UT.STRING_MAP,
	p_LOCK_STATE	 IN CHAR
	) RETURN PLS_INTEGER;

-- Changes the lock state of data records for a hierarchy, group, or realm of entities. Since a
-- realm can contain entities with differing intervals, date handling in this method has special
-- logic:
-- <ul>
-- <li>The specified date range can be specified in CUT or local time. Local time is specified
-- via a time zone parameter. A flag indicates whether the dates are CUT or local.</li>
-- <li>Realms and groups can contain a heterogeneous mix of intervals. In other words, they could
-- indicate some daily transactions and some hourly or sub-hourly transactions. Since data is locked
-- in local time for day and greater intervals and CUT for sub-daily intervals, the logic will
-- convert the specified date range to/from CUT as needed.</li>
-- <li>If a single hour is indicated by the date range, but daily (or greater) interval data is to
-- be updated, then the invoker must indicate when to apply the update. There are two options:
--    <ol>
--    <li><strong>Overlap</strong>: This indicates that any/all overlapping intervals are updated.
--    So when the data interval is daily, all days that overlap the specified date range are updated.
--    This is the default.</li>
--    <li><strong>Last</strong>: This indicates that the data is updated if and only if the "last"
--    portion of the interval is included in the specfied date range. So if the date range indicates
--    2008/09/01 06:00 -> 2008/09/07 06:00 and the data being updated is daily, then only the days
--    of 2008/09/01 -> 2008/09/06 will be updated. The days of 2008/09/02 -> 2008/09/06 are entirely
--    included in the specified date range, so they will be updated. The range includes the last portion
--    of 2008/09/01 (i.e. the last 5-minutes) so it is included. The range does not include the last
--    potion of 2008/09/07; it ends at hour ending 6. So 2008/09/07 will not be updated.</li>
--    </ol>
-- </li>
-- <li>Date range values are interpreted as "Scheduling" dates. This means that a date value that
-- represents precisely midnight actually indicates HE 24 of the previous day. For example, a date
-- value of 2010/01/01 00:00 indicates 2009/12/31 24:00. To indicate the "day" of 2010/01/01, simply
-- increment the date by one second: 2010/01/01 00:00:01</li>
-- </ul>
-- %param p_TABLE_ID		The ID of a System Table entity.
-- %param p_ENTITY_DOMAIN_ID The domain ID of the specified entity. This must be the same as the
--							domain of the specifed System Table *unless* the System Table's domain
--							indicates Sub-Station Meter Data Point, in which case this domain could
--							indicate Sub-Station or Sub-Station Meter.
-- %param p_ENTITY_TYPE		The type of the specified entity ID. This can be one of 'E', 'G', or 'R'
--							to indicate a single entity ID, a group ID, or a realm ID (respectively)
--							for the	specified domain.
-- %param p_ENTITY_ID		The entity ID is the value of the table's entity ID column (if it has
--							one).
-- %param p_BEGIN_DATE		The begin date.
-- %param p_END_DATE		The end date. These dates represent the date range of records to
--							lock/unlock.
-- %param p_TIME_ZONE		The time zone to use when converting from local to CUT and vice versa.
-- %param p_DATES_ARE_CUT	A flag that indicates whether the date range is in CUT time or in local
--							time represented by p_TIME_ZONE.
-- %param p_CRITERIA		The criteria map specifies values for additional columns in the table
--							for identifying precisely which records are to be locked/unlocked.
-- %param p_LOCK_STATE		The new lock state. This should be one of the c_LOCK_STATE_* constants.
-- %param p_WEEK_BEGIN		The way week intervals should be represented. For example, if weeks should
--							indicate Thursday -> Wednesday then this value would indicate Thursday. The
--							default value (NULL) indicates to use current NLS settings for week semantics.
-- %param p_APPLY_WHEN		This value indicates when data should be updated in cases where the specified
--							date range only partially includes a data interval. Use of the c_APPLY_*
--							constants.
-- %param p_ACTION_ID		An optional System Action ID used to filter the list of entities. Lock states
--							will only be updated for entities to which the current user has privileges
--							per the specified action.
-- %return	The number of data records effected.
FUNCTION UPDATE_LOCK_STATE
	(
	p_TABLE_ID		 	IN NUMBER,
	p_ENTITY_DOMAIN_ID	IN NUMBER,
	p_ENTITY_TYPE		IN CHAR,
	p_ENTITY_ID		 	IN NUMBER,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE	 		IN DATE,
	p_TIME_ZONE			IN VARCHAR2,
	p_DATES_ARE_CUT		IN BOOLEAN,
	p_CRITERIA		 	IN UT.STRING_MAP,
	p_LOCK_STATE	 	IN CHAR,
	p_WEEK_BEGIN		IN VARCHAR2 := NULL,
	p_APPLY_WHEN		IN PLS_INTEGER := c_APPLY_ON_OVERLAP,
	p_ACTION_ID			IN NUMBER := NULL
	) RETURN PLS_INTEGER;

-- Verify that data records are unlocked. If any matching record is locked then an exception will
-- be raised. If any matching record is restricted and the current user does not have privileges
-- to update restricted data then an exception will be raised.
-- %param p_TABLE_ID		The ID of a System Table entity.
-- %param p_ENTITY_ID		The entity ID is the value of the table's entity ID column (if it has
--							one).
-- %param p_CUT_BEGIN_DATE	The CUT begin date.
-- %param p_CUT_END_DATE	The CUT end date. These dates represent the date range of records to
--							check.
-- %param p_CRITERIA		The criteria map specifies values for additional columns in the table
--							for identifying precisely which records are to be checked.
PROCEDURE VERIFY_DATA_IS_UNLOCKED
	(
	p_TABLE_ID		 IN NUMBER,
	p_ENTITY_ID		 IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE	 IN DATE,
	p_CRITERIA		 IN UT.STRING_MAP
	);

-- Handle a data locked condition. This must be invoked from an exception handler block that has
-- caught a MSGCODES.e_DATA_LOCKED exception. The parameter will indicate how the exception
-- is handled.
-- %param p_BEHAVIOR		This should be one of the c_BEHAVIOR_* constants and indicates
--							the kind of logging performed and whether or not the exception
--							is re-raised.
PROCEDURE HANDLE_DATA_LOCKED_EXCEPTION
	(
	p_BEHAVIOR IN VARCHAR2
	);

-- Verify that bulk DML did not produce errors. This is invoked after using a LOG ERRORS clause
-- with a DML statement. This procedure will ignore all MSGCODES.e_ERR_DATA_LOCKED exceptions.
-- If the error log table contains another exception it will be re-raised.
-- %param p_ERR_TABLE_NAME	The name of the error table into which errors were logged.
-- %param p_SAVEPOINT_NAME	If an exception is to be re-raised and a savepoint name is specified
--							a ROLLBACK TO operation will performed to rollback to that savepoint.
-- %param p_TAG				If a tag was used with the LOG ERRORS clause it should be specified
--							here so that this method only checks the appropriate entries in the
--							log table.
PROCEDURE VERIFY_BULK_DML
	(
	p_ERR_TABLE_NAME	IN VARCHAR2,
	p_SAVEPOINT_NAME	IN VARCHAR2 := NULL,
	p_TAG				IN VARCHAR2 := NULL
	);

-- Apply a data-lock group. This will advance the group's 'locked through' date and will update
-- the lock state of all data described by the group between the group's prior 'locked through'
-- date and the new one.
-- %param p_DATA_LOCK_GROUP_ID	The ID of the Data Lock Group entity to apply.
-- %param p_LOCKED_THROUGH_DATE	The new 'locked through' data for this group.
PROCEDURE APPLY_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID	IN NUMBER,
	p_LOCKED_THROUGH_DATE	IN DATE
	);

-- Apply all automatic data-lock groups as necessary. This procedure will evaluate the auto-lock
-- date formula for all automatic data-lock groups. Any groups that result in a new date (i.e.
-- greater than the group's existing 'locked through' date) will be applied through the new date.
PROCEDURE APPLY_AUTO_DATA_LOCK_GROUPS;

-- Get CUT date represented by specified date formula. This function is used to evaluate the
-- auto-lock and lock limit formulae for data lock groups.
FUNCTION GET_LOCK_GROUP_DATE
	(
	p_DATA_LOCK_GROUP_NAME	IN VARCHAR2,
	p_DATE_FML		IN VARCHAR2,
	p_INTERVAL_ABBR	IN VARCHAR2,
	p_WEEK_BEGIN	IN VARCHAR2
	) RETURN DATE;

END DATA_LOCK;
/
CREATE OR REPLACE PACKAGE BODY DATA_LOCK IS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.3 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE INSURE_LOCKABLE
	(
	p_SYSTEM_TABLE IN SYSTEM_TABLE%ROWTYPE
	) AS
BEGIN
	ASSERT(UT.BOOLEAN_FROM_NUMBER(AUDIT_TRAIL.IS_TABLE_LOCKABLE(p_SYSTEM_TABLE.TABLE_ID)),
			'Specified System Table is not lockable: '||p_SYSTEM_TABLE.TABLE_NAME);
END INSURE_LOCKABLE;
---------------------------------------------------------------------------------------------------
FUNCTION GET_TABLE_KEY
	(
	p_TABLE_NAME IN VARCHAR2
	) RETURN VARCHAR2 AS
v_RET VARCHAR2(30);
BEGIN
	-- find primary/unique constraint
	SELECT CONSTRAINT_NAME
	INTO v_RET
	FROM USER_CONSTRAINTS
	WHERE OWNER = USER
		AND TABLE_NAME = p_TABLE_NAME
		AND CONSTRAINT_TYPE IN ('P','U');

	RETURN v_RET;

EXCEPTION
	WHEN TOO_MANY_ROWS THEN
		ERRS.RAISE(MSGCODES.c_ERR_TOO_MANY_ENTRIES, 'Key/unique constraint on table: '||p_TABLE_NAME);
	WHEN NO_DATA_FOUND THEN
		ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'Key/unique constraint on table: '||p_TABLE_NAME);
END GET_TABLE_KEY;
---------------------------------------------------------------------------------------------------
FUNCTION GET_LOCK_SUMMARY_KEY
	(
	p_TABLE_ID IN NUMBER
	) RETURN VARCHAR2 AS
v_SYSTEM_TABLE	SYSTEM_TABLE%ROWTYPE;
BEGIN
	SELECT *
	INTO v_SYSTEM_TABLE
	FROM SYSTEM_TABLE
	WHERE TABLE_ID = p_TABLE_ID;

	INSURE_LOCKABLE(v_SYSTEM_TABLE);
	RETURN GET_TABLE_KEY(v_SYSTEM_TABLE.LOCK_SUMMARY_TABLE_NAME);

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'System Table with ID = '||p_TABLE_ID);
END GET_LOCK_SUMMARY_KEY;
---------------------------------------------------------------------------------------------------
-- Validate criteria for locking. This will raise an exception if any of the parameters have
-- invalid values - like an invalid table ID, a table that is not lockable, or criteria that
-- reference invalid column names
-- %param p_TABLE_ID			The ID of the System Table entry
-- %param p_CRITERIA			The criteria for locking
-- %param p_SYSTEM_TABLE		Returns the full entry from SYSTEM_TABLE for the specified ID
-- %param p_KEY_COLS			Returns the list of key columns in the associated lock summary
--								table
-- %param p_MISSING_KEY_COLS	Returns the list of key columns in the associated lock summary
--								table that are missing from the criteria
PROCEDURE VALIDATE_CRITERIA
	(
	p_TABLE_ID		 	IN NUMBER,
	p_CRITERIA		 	IN UT.STRING_MAP,
	p_SYSTEM_TABLE	 	OUT SYSTEM_TABLE%ROWTYPE,
	p_KEY_COLS			OUT STRING_COLLECTION,
	p_MISSING_KEY_COLS	OUT STRING_COLLECTION
	) AS
v_SUMMARY_TBL_KEY	VARCHAR2(30);
v_CRITERIA_KEYS		STRING_COLLECTION;
v_KEY				VARCHAR2(4000);
BEGIN
	SELECT * INTO p_SYSTEM_TABLE
	FROM SYSTEM_TABLE
	WHERE TABLE_ID = p_TABLE_ID;

	-- First validate the parameters:

	-- Make sure table is lockable and has a lock summary table specified
	INSURE_LOCKABLE(p_SYSTEM_TABLE);
	ASSERT(p_SYSTEM_TABLE.LOCK_SUMMARY_TABLE_NAME IS NOT NULL,
			'No lock summary table is defined for System Table: '||p_SYSTEM_TABLE.TABLE_NAME);

	-- Make sure that criteria does *not* include entity or date columns
	IF p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME IS NOT NULL THEN
		ASSERT(NOT p_CRITERIA.EXISTS(p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME),
				'Criteria cannot include entity ID column: '||p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME,
				MSGCODES.c_ERR_ARGUMENT);
	END IF;
	IF p_SYSTEM_TABLE.DATE1_COLUMN_NAME IS NOT NULL THEN
		ASSERT(NOT p_CRITERIA.EXISTS(p_SYSTEM_TABLE.DATE1_COLUMN_NAME),
				'Criteria cannot include key date column: '||p_SYSTEM_TABLE.DATE1_COLUMN_NAME,
				MSGCODES.c_ERR_ARGUMENT);
	END IF;

	-- Make sure that criteria does *not* include invalid columns. Do so by collecting
	-- criteria column names into a collection, query for key columns in lock summary
	-- table, and then can use multiset operator to find invalid columns
	v_CRITERIA_KEYS := STRING_COLLECTION();
	v_KEY := p_CRITERIA.FIRST;
	WHILE p_CRITERIA.EXISTS(v_KEY) LOOP
		v_CRITERIA_KEYS.EXTEND;
		v_CRITERIA_KEYS(v_CRITERIA_KEYS.LAST) := v_KEY;
		v_KEY := p_CRITERIA.NEXT(v_KEY);
	END LOOP;
	-- Find summary table key
	v_SUMMARY_TBL_KEY := GET_TABLE_KEY(p_SYSTEM_TABLE.LOCK_SUMMARY_TABLE_NAME);
	-- Get constraint columns
	SELECT COLUMN_NAME
	BULK COLLECT INTO p_KEY_COLS
	FROM USER_CONS_COLUMNS
	WHERE OWNER = USER
		AND CONSTRAINT_NAME = v_SUMMARY_TBL_KEY
		AND TABLE_NAME = p_SYSTEM_TABLE.LOCK_SUMMARY_TABLE_NAME
		-- don't include
		AND COLUMN_NAME NOT IN (NVL(p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME,' '), 'BEGIN_DATE', 'END_DATE');

	-- go ahead and populate OUT parameter with set of missing keys
	p_MISSING_KEY_COLS := p_KEY_COLS MULTISET EXCEPT v_CRITERIA_KEYS;

	-- now find criteria columns that are *not* in the summary table's key
	v_CRITERIA_KEYS := v_CRITERIA_KEYS MULTISET EXCEPT p_KEY_COLS;

	-- if any columns are not in the key, they are invalid columns
	IF v_CRITERIA_KEYS.COUNT > 0 THEN
		ERRS.RAISE(MSGCODES.c_ERR_ARGUMENT,
			'Criteria specifies invalid column names: '||TEXT_UTIL.TO_CHAR_STRING_LIST(v_CRITERIA_KEYS));
	END IF;

END VALIDATE_CRITERIA;
---------------------------------------------------------------------------------------------------
-- Enumerates all configured column values to be used to "fill in the blanks" when a criteria
-- map is incomplete. This uses configuration in the System Dictionary at Global -> System ->
-- Data Locking -> Column Val Enumeration. The value in the system dictionary can contain a list
-- of numeric values, a list of string values, a SQL query that returns either strings or numbers,
-- or an indicator to query for the actual distinct set of values in the table. If no configuration
-- is found for the specified column, it is assumed that the column is an entity reference, and this
-- will return a list of entity IDs using UT.GET_REFERRED_DOMAIN to resolve the reference.
-- %param p_TABLE_NAME	The name of the table that contains the column
-- %param p_COLUMN_NAME	The name of the column whose possible values will be enumerated
-- %return 	A WORK_ID. The values will be in the WORK_DATA column of RTO_WORK for this ID.
FUNCTION ENUMERATE_COLUMN_CRITERIA
	(
	p_TABLE_NAME IN VARCHAR2,
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE
	) RETURN NUMBER IS

v_CONF			SYSTEM_DICTIONARY.VALUE%TYPE;
v_REF_DOMAIN_ID	ENTITY_DOMAIN.ENTITY_DOMAIN_ID%TYPE;
v_WORK_ID		RTO_WORK.WORK_ID%TYPE;
v_CAN_BE_NULL	VARCHAR2(1) := 'N';
v_HAS_NULL		BOOLEAN := FALSE;
v_SQL			VARCHAR2(4000);
v_VARS			UT.STRING_MAP;
v_IS_NUM		BOOLEAN;
v_NUM_VAL		NUMBER;
v_STR_VAL		VARCHAR2(4000);
cur_SQL			GA.REFCURSOR;

	--=======================================================================================
	PROCEDURE RETURN_TOKEN(p_TOKEN IN VARCHAR2) AS
	BEGIN
		-- track to see if a NULL is present in the enumeration if needed
		IF NOT v_HAS_NULL AND v_CAN_BE_NULL = 'Y' THEN
			IF UPPER(p_TOKEN) IN (CONSTANTS.LITERAL_NULL, CONSTANTS.LITERAL_EMTPY_STRING) THEN
				v_HAS_NULL := TRUE;
			END IF;
		END IF;

		-- now add to return set
		IF v_WORK_ID IS NULL THEN
			UT.GET_RTO_WORK_ID(v_WORK_ID);
		END IF;
		INSERT INTO RTO_WORK (WORK_ID, WORK_DATA) VALUES (v_WORK_ID, p_TOKEN);
	END RETURN_TOKEN;
	--=======================================================================================
	PROCEDURE PARSE_INTO_TOKENS(p_VALS IN VARCHAR2) AS
		v_LENGTH	PLS_INTEGER := LENGTH(p_VALS);
		v_COMMA		PLS_INTEGER := -1;
		v_PAREN		PLS_INTEGER := -1;
		v_PAREN_CLS	PLS_INTEGER := -1;
		v_QUOTE		PLS_INTEGER := -1;
		v_DBLQUOTE	PLS_INTEGER := -1;
		v_NEXT		PLS_INTEGER;
		v_PAREN_CNT	PLS_INTEGER := 0;
		v_START		PLS_INTEGER := 1;
		v_CUR		PLS_INTEGER := 1;
	BEGIN
		-- can't use UT.TOKENS_FROM_STRING because we need to parse out string literals
		-- and possibly SQL expressions
		LOOP
			IF v_CUR > v_LENGTH THEN
				-- we're done - return the last token before exiting the loop
				RETURN_TOKEN(SUBSTR(p_VALS, v_START, v_LENGTH-v_START+1));
				EXIT;
			END IF;

			-- try to determine end of current token

			-- only look if we don't already know the location of the next character
			IF v_PAREN <> 0 AND v_PAREN < v_CUR THEN
				v_PAREN := INSTR(p_VALS, '(', v_CUR);
			END IF;
			IF v_QUOTE <> 0 AND v_QUOTE < v_CUR THEN
				v_QUOTE := INSTR(p_VALS, '''', v_CUR);
			END IF;
			IF v_DBLQUOTE <> 0 AND v_DBLQUOTE < v_CUR THEN
				v_DBLQUOTE := INSTR(p_VALS, '"', v_CUR);
			END IF;

			-- not concerned with matching parentheses unless we've found
			-- an open parenthesis and not concerned with commas while we are
			-- in a parenthetic expression
			IF v_PAREN_CNT > 0 THEN
				IF v_PAREN_CLS <> 0 AND v_PAREN_CLS < v_CUR THEN
					v_PAREN_CLS := INSTR(p_VALS, ')', v_CUR);
				END IF;
				v_COMMA := -1;
			ELSE
				IF v_COMMA <> 0 AND v_COMMA < v_CUR THEN
					v_COMMA := INSTR(p_VALS, ',', v_CUR);
				END IF;
				v_PAREN_CLS := -1;
			END IF;

			-- comma is the next character? (don't worry about commas if we are inside
			-- parenthetic expression, though)
			IF v_COMMA > 0 AND (v_PAREN = 0 OR v_COMMA < v_PAREN)
				AND (v_QUOTE = 0 OR v_COMMA < v_QUOTE)
				AND (v_DBLQUOTE = 0 OR v_COMMA < v_DBLQUOTE) THEN

				-- return this token
				RETURN_TOKEN(SUBSTR(p_VALS, v_START, v_COMMA-v_START));

				-- next token...
				v_CUR := v_COMMA+1;
				v_START := v_CUR;

			-- open parenthesis is the next character?
			ELSIF v_PAREN > 0 AND (v_PAREN_CLS <= 0 OR v_PAREN < v_PAREN_CLS)
				AND (v_QUOTE = 0 OR v_PAREN < v_QUOTE)
				AND (v_DBLQUOTE = 0 OR v_PAREN < v_DBLQUOTE) THEN

				v_PAREN_CNT := v_PAREN_CNT+1; -- we are now inside parenthetic expression
				v_CUR := v_PAREN+1;

			-- close parenthesis is the next character?
			ELSIF v_PAREN_CLS > 0 AND (v_QUOTE = 0 OR v_PAREN_CLS < v_QUOTE)
				AND (v_DBLQUOTE = 0 OR v_PAREN_CLS < v_DBLQUOTE) THEN

				v_PAREN_CNT := v_PAREN_CNT-1; -- we are now inside parenthetic expression
				v_CUR := v_PAREN_CLS+1;

			-- single quote is the next character?
			ELSIF v_QUOTE > 0 AND (v_DBLQUOTE = 0 OR v_QUOTE < v_DBLQUOTE) THEN

				-- try to get terminating quote
				v_NEXT := INSTR(p_VALS, '''', v_QUOTE+1);
				IF v_NEXT = 0 THEN
					-- no terminating single quote? then take the rest of the string
					v_CUR := v_LENGTH+1;
				ELSE
					v_CUR := v_NEXT+1;
				END IF;

			-- double quote is the next character?
			ELSIF v_DBLQUOTE > 0 THEN

				-- try to get terminating quote
				v_NEXT := INSTR(p_VALS, '"', v_DBLQUOTE+1);
				IF v_NEXT = 0 THEN
					-- no terminating double quote? then take the rest of the string
					v_CUR := v_LENGTH+1;
				ELSE
					v_CUR := v_NEXT+1;
				END IF;

			ELSE

				-- no next character - this is the last token
				v_CUR := v_LENGTH+1;

			END IF;

		END LOOP;
	END PARSE_INTO_TOKENS;
	--=======================================================================================

BEGIN
	-- See if value can be NULL
	SELECT NULLABLE
	INTO v_CAN_BE_NULL
	FROM USER_TAB_COLS
	WHERE TABLE_NAME = p_TABLE_NAME
	AND COLUMN_NAME = p_COLUMN_NAME;

	-- load enumeration config from system dictionary
	v_CONF := GET_DICTIONARY_VALUE(p_COLUMN_NAME, CONSTANTS.GLOBAL_MODEL, 'System', 'Data Locking', 'Column Enumeration', p_TABLE_NAME);
	IF v_CONF IS NULL THEN
		-- try again, but w/out table name to see if a "general" config exists for columns with this name
		v_CONF := GET_DICTIONARY_VALUE(p_COLUMN_NAME, CONSTANTS.GLOBAL_MODEL, 'System', 'Data Locking', 'Column Enumeration');
	END IF;

	IF v_CONF IS NULL THEN
		v_REF_DOMAIN_ID := ENTITY_UTIL.GET_REFERRED_DOMAIN_ID(p_COLUMN_NAME, p_TABLE_NAME);
		IF v_REF_DOMAIN_ID IS NULL THEN
			-- no way to enumerate values!!!
			ERRS.RAISE(MSGCODES.c_ERR_CANNOT_ENUM_COL_VALS, p_TABLE_NAME||'.'||p_COLUMN_NAME);
		END IF;
		-- no configuration? must be an entity reference, so enumerate all entities
		SD.ENUMERATE_ENTITIES(TO_NUMBER(NULL), -- NULL action ID indicates to enumerate all
							  v_REF_DOMAIN_ID, -- determine domain
							  v_WORK_ID);

		-- update the workset so that WORK_DATA has what this method needs to return
		UPDATE RTO_WORK
			SET WORK_DATA = UT.GET_LITERAL_FOR_NUMBER(WORK_XID)
		WHERE WORK_ID = v_WORK_ID;

	ELSIF SUBSTR(v_CONF,1,1) IN ('#','*') THEN

		IF LENGTH(v_CONF) = 1 THEN
			-- no SQL query specified, so query for distinct values
			IF v_CAN_BE_NULL = 'Y' THEN
				-- if it can be NULL, make sure to include NULL - we don't need to use DISTINCT
				-- here because the UNION operator will make sure the results are distinct
				v_SQL := 'SELECT '||p_COLUMN_NAME||' FROM '||p_TABLE_NAME||' UNION SELECT NULL FROM DUAL';
			ELSE
				-- can't be NULL? just query distinct values
				v_SQL := 'SELECT DISTINCT '||p_COLUMN_NAME||' FROM '||p_TABLE_NAME;
			END IF;
		ELSE
			v_VARS('ENTITY_ID') := UT.GET_LITERAL_FOR_NUMBER(p_ENTITY_ID);
			v_VARS('BEGIN_DATE') := UT.GET_LITERAL_FOR_DATE(p_BEGIN_DATE);
			v_VARS('END_DATE') := UT.GET_LITERAL_FOR_DATE(p_END_DATE);
			-- evaluate any references in the specified SQL query
			v_SQL := FML_UTIL.REBUILD_FORMULA(SUBSTR(v_CONF,2), v_VARS, TRUE, FALSE);
		END IF;

		-- evaluate query and loop over results
		v_IS_NUM := SUBSTR(v_CONF,1,1) = '#';
		OPEN cur_SQL FOR v_SQL;
		BEGIN
			LOOP
				IF v_IS_NUM THEN
					FETCH cur_SQL INTO v_NUM_VAL;
					v_STR_VAL := UT.GET_LITERAL_FOR_NUMBER(v_NUM_VAL);
				ELSE
					FETCH cur_SQL INTO v_STR_VAL;
					v_STR_VAL := UT.GET_LITERAL_FOR_STRING(v_STR_VAL);
				END IF;

				EXIT WHEN cur_SQL%NOTFOUND;

				-- add this value to return set
				RETURN_TOKEN(v_STR_VAL);

			END LOOP;
			CLOSE cur_SQL;

		EXCEPTION
			WHEN OTHERS THEN
				BEGIN
					CLOSE cur_SQL; -- make sure we close this
				EXCEPTION
					WHEN OTHERS THEN
						ERRS.LOG_AND_CONTINUE;
				END;
				ERRS.LOG_AND_RAISE;
		END;

	ELSE

		-- parse the list of values
		PARSE_INTO_TOKENS(v_CONF);

	END IF;

	-- if column allows NULL but we didn't encounter one, return it now
	IF NOT v_HAS_NULL AND v_CAN_BE_NULL = 'Y' THEN
		RETURN_TOKEN(CONSTANTS.LITERAL_NULL);
	END IF;

	-- Done!
	RETURN v_WORK_ID;

END ENUMERATE_COLUMN_CRITERIA;
---------------------------------------------------------------------------------------------------
FUNCTION BUILD_WHERE_CLAUSE
	(
	p_SYSTEM_TABLE	 	IN SYSTEM_TABLE%ROWTYPE,
	p_ENTITY_ID		 	IN NUMBER,
	p_CUT_BEGIN_DATE 	IN DATE,
	p_CUT_END_DATE	 	IN DATE,
	p_CRITERIA		 	IN UT.STRING_MAP,
	p_FOR_SUMMARY_TBL	IN BOOLEAN := FALSE
	) RETURN VARCHAR2 AS
v_RET	VARCHAR2(32767);
v_WHERE	VARCHAR2(32767);
BEGIN
	IF p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME IS NOT NULL THEN
		v_RET := p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME||' = '||UT.GET_LITERAL_FOR_NUMBER(p_ENTITY_ID);
	END IF;

	IF p_SYSTEM_TABLE.DATE1_COLUMN_NAME IS NOT NULL THEN
		IF v_RET IS NOT NULL THEN
			v_RET := v_RET||' AND ';
		END IF;
		IF p_FOR_SUMMARY_TBL THEN
			-- summary table has begin and end dates, not specified date1 column name
			v_RET := v_RET||'BEGIN_DATE <= '||UT.GET_LITERAL_FOR_DATE(p_CUT_END_DATE)||
						' AND END_DATE >= '||UT.GET_LITERAL_FOR_DATE(p_CUT_BEGIN_DATE);
		ELSE
			v_RET := v_RET||p_SYSTEM_TABLE.DATE1_COLUMN_NAME||' BETWEEN '||
						UT.GET_LITERAL_FOR_DATE(p_CUT_BEGIN_DATE)||' AND '||UT.GET_LITERAL_FOR_DATE(p_CUT_END_DATE);
		END IF;
	END IF;

	v_WHERE := UT.MAP_TO_WHERE_CLAUSE(p_CRITERIA);
	IF v_WHERE IS NOT NULL THEN
		IF v_RET IS NOT NULL THEN
			v_RET := v_RET||' AND ';
		END IF;
		v_RET := v_RET||v_WHERE;
	END IF;

	RETURN v_RET;

END BUILD_WHERE_CLAUSE;
---------------------------------------------------------------------------------------------------
-- Private version that actually updates the lock summary table and updates the lock state of
-- actual table data. This version does not validate criteria nor does it "fill it out" to make
-- sure that all lock summary key columns are accounted for.
FUNCTION UPDATE_LOCK_STATE
	(
	p_SYSTEM_TABLE	 	IN SYSTEM_TABLE%ROWTYPE,
	p_ENTITY_ID		 	IN NUMBER,
	p_CUT_BEGIN_DATE 	IN DATE,
	p_CUT_END_DATE	 	IN DATE,
	p_CRITERIA		 	IN UT.STRING_MAP,
	p_LOCK_STATE	 	IN CHAR
	) RETURN PLS_INTEGER AS
v_KEY_COLS		UT.STRING_MAP := p_CRITERIA;
v_DATA_COLS		UT.STRING_MAP;
v_INTERVAL		VARCHAR2(32);
v_SCHED_DATES	BOOLEAN;
v_DML			VARCHAR2(32767);
v_WHERE			VARCHAR2(32767);
v_COL			VARCHAR2(30);
BEGIN
	IF p_SYSTEM_TABLE.DATE1_COLUMN_NAME IS NOT NULL THEN
		IF p_SYSTEM_TABLE.DATE2_COLUMN_NAME IS NOT NULL THEN
			-- table has begin AND end dates? then interval is daily and we're not using scheduling dates
			v_INTERVAL := 'Day';
		ELSE
			-- Figure out the interval of the data
			DATE_UTIL.GET_DATA_INTERVAL_INFO(p_SYSTEM_TABLE.DB_TABLE_NAME, p_ENTITY_ID,
											 p_CRITERIA, v_INTERVAL, v_SCHED_DATES);
		END IF;

		-- the table is temporal - so use temporal data APIs in UT package
		IF p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME IS NOT NULL THEN
			v_KEY_COLS(p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME) := UT.GET_LITERAL_FOR_NUMBER(p_ENTITY_ID);
		END IF;
		v_DATA_COLS('LOCK_STATE') := UT.GET_LITERAL_FOR_STRING(p_LOCK_STATE);

		UT.PUT_TEMPORAL_DATA(p_SYSTEM_TABLE.LOCK_SUMMARY_TABLE_NAME, p_CUT_BEGIN_DATE, p_CUT_END_DATE, FALSE, FALSE,
							v_KEY_COLS, v_DATA_COLS, p_INTERVAL => v_INTERVAL);
	ELSE
		-- not temporal? build simple merge to upsert this record into summary table
		v_DML := 'MERGE INTO '||p_SYSTEM_TABLE.LOCK_SUMMARY_TABLE_NAME||' USING (SELECT 1 FROM DUAL) ON ('||
				BUILD_WHERE_CLAUSE(p_SYSTEM_TABLE, p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE, p_CRITERIA, TRUE)||')'||
				' WHEN MATCHED THEN UPDATE SET LOCK_STATE = '||UT.GET_LITERAL_FOR_STRING(p_LOCK_STATE)||
				' WHEN NOT MATCHED THEN INSERT (LOCK_STATE';
		v_WHERE := 'VALUES ('||UT.GET_LITERAL_FOR_STRING(p_LOCK_STATE);
		-- now add column names and values to the insert portion of this MERGE statement
		IF p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME IS NOT NULL THEN
			v_DML := v_DML||', '||p_SYSTEM_TABLE.ENTITY_ID_COLUMN_NAME;
			v_WHERE := v_WHERE||', '||UT.GET_LITERAL_FOR_NUMBER(p_ENTITY_ID);
		END IF;
		v_COL := p_CRITERIA.FIRST;
		WHILE p_CRITERIA.EXISTS(v_COL) LOOP
			v_DML := v_DML||', '||v_COL;
			v_WHERE := v_WHERE||', '||p_CRITERIA(v_COL);
			-- onto the next column...
			v_COL := p_CRITERIA.NEXT(v_COL);
		END LOOP;
		-- now perform the merge statement to upsert a record into the lock summary table
		EXECUTE IMMEDIATE v_DML||')'||v_WHERE||')';
	END IF;

	-- Now update the table data and return count of affected records
	v_DML := 'UPDATE '||p_SYSTEM_TABLE.DB_TABLE_NAME||' SET LOCK_STATE = '||UT.GET_LITERAL_FOR_STRING(p_LOCK_STATE);
	v_WHERE := BUILD_WHERE_CLAUSE(p_SYSTEM_TABLE, p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE, p_CRITERIA);
	IF v_WHERE IS NOT NULL THEN
		v_DML := v_DML||' WHERE '||v_WHERE;
	END IF;

	EXECUTE IMMEDIATE v_DML;
	RETURN SQL%ROWCOUNT;

END UPDATE_LOCK_STATE;
---------------------------------------------------------------------------------------------------
-- Private version that does not validate criteria - this is a recursive procedure. The recursion
-- is used to flesh out criteria in the case where criteria is missing one or more key columns.
FUNCTION UPDATE_LOCK_STATE
	(
	p_SYSTEM_TABLE	 	IN SYSTEM_TABLE%ROWTYPE,
	p_ENTITY_ID		 	IN NUMBER,
	p_CUT_BEGIN_DATE 	IN DATE,
	p_CUT_END_DATE	 	IN DATE,
	p_CRITERIA		 	IN UT.STRING_MAP,
	p_KEY_COLS			IN STRING_COLLECTION,
	p_MISSING_KEY_COLS	IN STRING_COLLECTION,
	p_LOCK_STATE	 	IN CHAR
	) RETURN PLS_INTEGER AS
v_COUNT				PLS_INTEGER := 0;
v_CUR_COL			VARCHAR2(32);
v_NEXT_MISSING_COLS	STRING_COLLECTION;
v_NEXT_CRITERIA		UT.STRING_MAP;
v_WORK_ID			RTO_WORK.WORK_ID%TYPE;
BEGIN
	IF p_MISSING_KEY_COLS.COUNT = 0 THEN
		-- criteria is fully populated - now call the version above that actually performs DML
		RETURN UPDATE_LOCK_STATE(p_SYSTEM_TABLE, p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE,
								 p_CRITERIA, p_LOCK_STATE);
	ELSE
		v_NEXT_CRITERIA := p_CRITERIA;
		v_NEXT_MISSING_COLS := p_MISSING_KEY_COLS;
		-- get first missing column
		v_CUR_COL := v_NEXT_MISSING_COLS(v_NEXT_MISSING_COLS.FIRST);
		-- remove from the collection for recursion
		v_NEXT_MISSING_COLS.DELETE(v_NEXT_MISSING_COLS.FIRST);

		-- Enumare the values
		v_WORK_ID := ENUMERATE_COLUMN_CRITERIA(p_SYSTEM_TABLE.DB_TABLE_NAME, v_CUR_COL,
												p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE);
		BEGIN
			-- for each value, recurse to update the lock state for this column value
			FOR v_VAL IN (SELECT WORK_DATA FROM RTO_WORK WHERE WORK_ID = v_WORK_ID) LOOP
				v_NEXT_CRITERIA(v_CUR_COL) := v_VAL.WORK_DATA;
				v_COUNT := v_COUNT + UPDATE_LOCK_STATE(p_SYSTEM_TABLE, p_ENTITY_ID,
													p_CUT_BEGIN_DATE, p_CUT_END_DATE,
													v_NEXT_CRITERIA, p_KEY_COLS,
													v_NEXT_MISSING_COLS, p_LOCK_STATE);
			END LOOP;
			UT.PURGE_RTO_WORK(v_WORK_ID);
		EXCEPTION
			WHEN OTHERS THEN
				-- clean up work table before propagating error up the call-stack
				BEGIN
					UT.PURGE_RTO_WORK(v_WORK_ID);
				EXCEPTION WHEN OTHERS THEN
					ERRS.LOG_AND_CONTINUE;
				END;
				ERRS.LOG_AND_RAISE;
		END;

		-- return the final count
		RETURN v_COUNT;
	END IF;
END UPDATE_LOCK_STATE;
---------------------------------------------------------------------------------------------------
FUNCTION UPDATE_LOCK_STATE
	(
	p_TABLE_ID		 IN NUMBER,
	p_ENTITY_ID		 IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE	 IN DATE,
	p_CRITERIA		 IN UT.STRING_MAP,
	p_LOCK_STATE	 IN CHAR
	) RETURN PLS_INTEGER AS
v_SYS_TABLE			SYSTEM_TABLE%ROWTYPE;
v_KEY_COLS			STRING_COLLECTION;
v_MISSING_KEY_COLS	STRING_COLLECTION;
BEGIN
	-- make sure lock state is valid
	ASSERT(p_LOCK_STATE IN (c_LOCK_STATE_LOCKED, c_LOCK_STATE_RESTRICTED, c_LOCK_STATE_UNLOCKED),
			'Invalid Lock State - received '||p_LOCK_STATE||' but expecting one of ('||
				c_LOCK_STATE_LOCKED||','||c_LOCK_STATE_RESTRICTED||','||c_LOCK_STATE_UNLOCKED||')',
			MSGCODES.c_ERR_ARGUMENT);

	-- make sure parameters are good
	VALIDATE_CRITERIA(p_TABLE_ID, p_CRITERIA, v_SYS_TABLE, v_KEY_COLS, v_MISSING_KEY_COLS);

	-- call internal version that does the work
	RETURN UPDATE_LOCK_STATE(v_SYS_TABLE, p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE, p_CRITERIA, v_KEY_COLS, v_MISSING_KEY_COLS, p_LOCK_STATE);

END UPDATE_LOCK_STATE;
---------------------------------------------------------------------------------------------------
FUNCTION UPDATE_LOCK_STATE
	(
	p_TABLE_ID		 	IN NUMBER,
	p_ENTITY_DOMAIN_ID	IN NUMBER,
	p_ENTITY_TYPE		IN CHAR,
	p_ENTITY_ID		 	IN NUMBER,
	p_BEGIN_DATE 		IN DATE,
	p_END_DATE	 		IN DATE,
	p_TIME_ZONE			IN VARCHAR2,
	p_DATES_ARE_CUT		IN BOOLEAN,
	p_CRITERIA		 	IN UT.STRING_MAP,
	p_LOCK_STATE	 	IN CHAR,
	p_WEEK_BEGIN		IN VARCHAR2 := NULL,
	p_APPLY_WHEN		IN PLS_INTEGER := c_APPLY_ON_OVERLAP,
	p_ACTION_ID			IN NUMBER := NULL
	) RETURN PLS_INTEGER IS
v_WORK_ID		NUMBER;
v_TABLE_DOMAIN_ID NUMBER;
v_TABLE_NAME	VARCHAR2(30);
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_ROWCOUNT		PLS_INTEGER := 0;
v_ENTITY_INTERVAL VARCHAR2(16);
v_ENTITY_SCHED_DATES BOOLEAN;
CURSOR cur_ENTITIES IS
	SELECT WORK_XID as ENTITY_ID
	FROM RTO_WORK
	WHERE WORK_ID = v_WORK_ID;
BEGIN
	-- Get info from the table - we need the table's domain because it may differ from item's domain. This can
	-- be the case where table's domain is Sub-Station Meter Data Point - which can have items with domains of
	-- Sub-Station and Sub-Station Meter.
	SELECT DB_TABLE_NAME, ENTITY_DOMAIN_ID
	INTO v_TABLE_NAME, v_TABLE_DOMAIN_ID
	FROM SYSTEM_TABLE
	WHERE TABLE_ID = p_TABLE_ID;

	IF v_TABLE_DOMAIN_ID = CONSTANTS.NOT_ASSIGNED THEN
		-- no entities so this will be easy.
		-- record single work entry with NULL entity ID
		UT.GET_RTO_WORK_ID(v_WORK_ID);
		INSERT INTO RTO_WORK (WORK_ID, WORK_XID) VALUES (v_WORK_ID, NULL);
	ELSE
		IF p_DATES_ARE_CUT THEN
			-- Convert to local time - for using group membership effective dates
			v_BEGIN_DATE := FROM_CUT(p_BEGIN_DATE, p_TIME_ZONE);
			v_END_DATE := FROM_CUT(p_END_DATE, p_TIME_ZONE);
		END IF;
		v_WORK_ID := ENTITY_UTIL.EXPAND_ENTITY(p_ENTITY_DOMAIN_ID,
												p_ENTITY_TYPE,
												p_ENTITY_ID,
												-- Don't apply action ID to sub-stations and meters. The action Id will be for meter data points,
												-- so we defer the use of the action ID to the point where we enumerate the meter data points
												-- belonging to specified sub-stations and meters.
												CASE WHEN p_ENTITY_DOMAIN_ID IN (EC.ED_SUB_STATION, EC.ED_SUB_STATION_METER)
													THEN NULL
													ELSE p_ACTION_ID
													END,
												TRUNC(v_BEGIN_DATE-1/86400),
												TRUNC(v_END_DATE-1/86400),
												TRUE);
	END IF;

	-- Now we need to expand meter and sub-station domains to instead include all assigned meter points
	IF p_ENTITY_DOMAIN_ID IN (EC.ED_SUB_STATION, EC.ED_SUB_STATION_METER) THEN
		ENTITY_UTIL.EXPAND_WORKSET_METER_POINTS(p_ENTITY_DOMAIN_ID, v_WORK_ID, p_ACTION_ID);
	END IF;

	FOR v_ENTITY IN cur_ENTITIES LOOP
		-- now figure out the dates and lock it!
		DATE_UTIL.GET_DATA_INTERVAL_INFO(v_TABLE_NAME, v_ENTITY.ENTITY_ID, p_CRITERIA, v_ENTITY_INTERVAL, v_ENTITY_SCHED_DATES);
		v_ENTITY_INTERVAL := GET_INTERVAL_ABBREVIATION(v_ENTITY_INTERVAL);

		-- default the dates to parameters
		v_BEGIN_DATE := p_BEGIN_DATE;
		v_END_DATE := p_END_DATE;

		IF DATE_UTIL.IS_SUB_DAILY(v_ENTITY_INTERVAL) THEN
			IF NOT p_DATES_ARE_CUT THEN
				-- Convert to CUT time for sub-daily intervals
				-- TO_CUT will truncate to the minute when the timestamp indicates one second past midnight because
				-- that is how it distinguishes between the two HE 2s on the 25-hour day - so we must add the second back
				-- to the begin date+time
				v_BEGIN_DATE := TO_CUT(p_BEGIN_DATE, p_TIME_ZONE)+1/86400;
				v_END_DATE := TO_CUT(p_END_DATE, p_TIME_ZONE);
			END IF;
		ELSE -- Daily or greater
			IF p_DATES_ARE_CUT THEN
				-- Convert to local time for daily and greater intervals
				v_BEGIN_DATE := FROM_CUT(p_BEGIN_DATE, p_TIME_ZONE);
				v_END_DATE := FROM_CUT(p_END_DATE, p_TIME_ZONE);
			END IF;
		END IF;

		-- calculate proper begin based on this entity's interval
		v_BEGIN_DATE := DATE_UTIL.HED_TRUNC(v_BEGIN_DATE, v_ENTITY_INTERVAL, p_WEEK_BEGIN, v_ENTITY_SCHED_DATES);

		-- only apply on last?
		IF p_APPLY_WHEN = c_APPLY_ON_LAST THEN
			DECLARE
				v_RANGE_BEGIN DATE;
				v_RANGE_END   DATE;
			BEGIN
				-- find extents of the last interval to be locked
				DATE_UTIL.GET_DATE_RANGE(v_END_DATE, v_ENTITY_INTERVAL, v_RANGE_BEGIN, v_RANGE_END, p_WEEK_BEGIN);
				-- If the end of the extent matches specified end date+time, then we can include last interval
				-- in lock set since it includes "last" portion.
				-- But if the end of the extent does not match, then we must back up the end date because the
				-- specified end date indicates a partial interval which will not be locked/unlocked due to
				-- p_APPLY_WHEN setting.
				IF v_RANGE_END <> v_END_DATE THEN
					v_END_DATE := DATE_UTIL.ADVANCE_DATE(v_END_DATE, v_ENTITY_INTERVAL, p_WEEK_BEGIN, -1);
				END IF;
			END;
		END IF;

		-- now calculate proper end based on this entity's interval
		v_END_DATE := DATE_UTIL.HED_TRUNC(v_END_DATE, v_ENTITY_INTERVAL, p_WEEK_BEGIN, v_ENTITY_SCHED_DATES);

		-- No-op if end date is before begin date. This can happen when "apply on last" and specified date range does
		-- cover any "last" portion of any interval. For example, the entity interval is "Day" and the specified date
		-- range indicates a single hour in the middle of the day. In this case, we lock nothing.
		IF v_END_DATE >= v_BEGIN_DATE THEN
			v_ROWCOUNT := v_ROWCOUNT + UPDATE_LOCK_STATE(p_TABLE_ID, v_ENTITY.ENTITY_ID, v_BEGIN_DATE, v_END_DATE, p_CRITERIA, p_LOCK_STATE);
		END IF;

	END LOOP;

	RETURN v_ROWCOUNT;

END UPDATE_LOCK_STATE;
---------------------------------------------------------------------------------------------------
PROCEDURE VERIFY_DATA_IS_UNLOCKED
	(
	p_TABLE_ID		 IN NUMBER,
	p_ENTITY_ID		 IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE	 IN DATE,
	p_CRITERIA		 IN UT.STRING_MAP
	) AS
v_SYS_TABLE			SYSTEM_TABLE%ROWTYPE;
v_KEY_COLS			STRING_COLLECTION;
v_MISSING_KEY_COLS	STRING_COLLECTION;
v_SQL				VARCHAR2(32767);
v_WHERE				VARCHAR2(32767);
v_BEGIN_DATE		DATE;
v_END_DATE			DATE;
BEGIN
	-- make sure parameters are good
	VALIDATE_CRITERIA(p_TABLE_ID, p_CRITERIA, v_SYS_TABLE, v_KEY_COLS, v_MISSING_KEY_COLS);

	v_WHERE := BUILD_WHERE_CLAUSE(v_SYS_TABLE, p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE, p_CRITERIA, TRUE);
	IF v_WHERE IS NOT NULL THEN
		v_WHERE := v_WHERE||' AND ';
	END IF;

	-- unlocked rows can be ignored - we're looking for locked data
	v_WHERE := v_WHERE||'LOCK_STATE <> '||UT.GET_LITERAL_FOR_STRING(c_LOCK_STATE_UNLOCKED)||
			-- restricted rows can also be ignored if current user can update restricted data
			CASE SECURITY_CONTROLS.CAN_UPDATE_RESTRICTED_DATA
				WHEN 1 THEN ' AND LOCK_STATE <> '||UT.GET_LITERAL_FOR_STRING(c_LOCK_STATE_RESTRICTED)
				ELSE NULL END;

	-- build a query that finds the range of locked data.
	v_SQL := 'SELECT MIN(BEGIN_DATE), MAX(END_DATE) '||
			'FROM '||v_SYS_TABLE.LOCK_SUMMARY_TABLE_NAME||' '||
			'WHERE '||v_WHERE;

	BEGIN
		EXECUTE IMMEDIATE v_SQL INTO v_BEGIN_DATE, v_END_DATE;
		IF v_BEGIN_DATE IS NOT NULL OR v_END_DATE IS NOT NULL THEN
			ERRS.RAISE(MSGCODES.c_ERR_DATA_LOCKED,
				'Some or all matching data between '||TEXT_UTIL.TO_CHAR_TIME(v_BEGIN_DATE)||' and '||TEXT_UTIL.TO_CHAR_TIME(v_END_DATE)||' '||GA.CUT_TIME_ZONE);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- no matching rows? that means that data is not locked - return successfully
			RETURN;
	END;
END VERIFY_DATA_IS_UNLOCKED;
---------------------------------------------------------------------------------------------------
PROCEDURE HANDLE_DATA_LOCKED_EXCEPTION
	(
	p_BEHAVIOR IN VARCHAR2
	) AS
BEGIN

	ASSERT(UPPER(p_BEHAVIOR) IN (c_BEHAVIOR_ERROR, c_BEHAVIOR_WARN, c_BEHAVIOR_IGNORE),
			'Behavior must be '||c_BEHAVIOR_ERROR||', '||c_BEHAVIOR_WARN||', or '||c_BEHAVIOR_IGNORE,
			MSGCODES.c_ERR_ARGUMENT);

	IF UPPER(p_BEHAVIOR) = c_BEHAVIOR_ERROR THEN
		ERRS.LOG_AND_RAISE;
	ELSE
		ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => CASE UPPER(p_BEHAVIOR)
												WHEN c_BEHAVIOR_WARN THEN LOGS.c_LEVEL_WARN
												ELSE LOGS.c_LEVEL_DEBUG_DETAIL
												END);
	END IF;

END HANDLE_DATA_LOCKED_EXCEPTION;
---------------------------------------------------------------------------------------------------
PROCEDURE VERIFY_BULK_DML
	(
	p_ERR_TABLE_NAME	IN VARCHAR2,
	p_SAVEPOINT_NAME	IN VARCHAR2 := NULL,
	p_TAG				IN VARCHAR2 := NULL
	) AS

v_SQL		VARCHAR2(32767);
v_SQLCODE	PLS_INTEGER;
v_SQLERRM	VARCHAR2(4000);

BEGIN

	v_SQL := 'SELECT MAX(ORA_ERR_NUMBER$), MAX(ORA_ERR_MESG$) FROM '||p_ERR_TABLE_NAME||' WHERE ORA_ERR_NUMBER$ <> :n AND ROWNUM=1';

	IF p_TAG IS NOT NULL THEN
		v_SQL := v_SQL||' AND ORA_ERR_TAG$ = :t';
		EXECUTE IMMEDIATE v_SQL INTO v_SQLCODE, v_SQLERRM USING MSGCODES.n_ERR_DATA_LOCKED, p_TAG;
	ELSE
		EXECUTE IMMEDIATE v_SQL INTO v_SQLCODE, v_SQLERRM USING MSGCODES.n_ERR_DATA_LOCKED;
	END IF;

	IF v_SQLCODE IS NOT NULL THEN
		-- If a savepoint name was specified then rollback to it
		IF p_SAVEPOINT_NAME IS NOT NULL THEN
			BEGIN
				ERRS.ROLLBACK_TO(p_SAVEPOINT_NAME);
			EXCEPTION
				WHEN OTHERS THEN
					ERRS.LOG_AND_CONTINUE('Attempting rollback to '||p_SAVEPOINT_NAME);
			END;
		END IF;

		-- now raise the DML exception
		ERRS.RERAISE(v_SQLCODE, v_SQLERRM);
	END IF;

END VERIFY_BULK_DML;
---------------------------------------------------------------------------------------------------
PROCEDURE APPLY_DATA_LOCK_GROUP_ITEM
	(
	p_ITEM				IN DATA_LOCK_GROUP_ITEM%ROWTYPE,
	p_TIME_ZONE			IN VARCHAR2,
	p_WEEK_BEGIN		IN VARCHAR2,
	p_BEGIN_DATE		IN DATE,
	p_END_DATE			IN DATE,
	p_DATES_ARE_CUT		IN BOOLEAN,
	p_LOCK_STATE		IN CHAR
	) AS
v_CRITERIA_MAP	UT.STRING_MAP;
v_ROWCOUNT		PLS_INTEGER;
CURSOR cur_CRITERIA IS
	SELECT CR.COLUMN_NAME, CR.COLUMN_VALUE, C.DATA_TYPE
	FROM DATA_LOCK_GROUP_ITEM_CRITERIA CR, SYSTEM_TABLE ST, USER_TAB_COLS C
	WHERE CR.DATA_LOCK_GROUP_ITEM_ID = p_ITEM.DATA_LOCK_GROUP_ITEM_ID
		AND CR.COLUMN_VALUE <> CONSTANTS.ALL_STRING -- can skip "ALL" values as these will be filled in by API
		AND ST.TABLE_ID = p_ITEM.TABLE_ID
		AND C.TABLE_NAME = ST.DB_TABLE_NAME
		AND C.COLUMN_NAME = CR.COLUMN_NAME;
BEGIN
	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Applying Data Lock Group Item - ID = '||p_ITEM.DATA_LOCK_GROUP_ITEM_ID);
	END IF;

	-- collect the critera
	FOR v_CRITERIA IN cur_CRITERIA LOOP
		IF v_CRITERIA.COLUMN_VALUE IS NULL THEN
			v_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := CONSTANTS.LITERAL_NULL;
		ELSIF v_CRITERIA.DATA_TYPE = 'NUMBER' THEN
			v_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := UT.GET_LITERAL_FOR_NUMBER(TO_NUMBER(v_CRITERIA.COLUMN_VALUE));
		ELSE -- DATA_TYPE indicates string
			v_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := UT.GET_LITERAL_FOR_STRING(v_CRITERIA.COLUMN_VALUE);
		END IF;
	END LOOP;

	v_ROWCOUNT := UPDATE_LOCK_STATE(p_ITEM.TABLE_ID, p_ITEM.ENTITY_DOMAIN_ID, p_ITEM.ENTITY_TYPE, p_ITEM.ENTITY_ID,
								  p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, p_DATES_ARE_CUT, v_CRITERIA_MAP, p_LOCK_STATE,
								  p_WEEK_BEGIN, c_APPLY_ON_LAST);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Updated '||v_ROWCOUNT||' records to lock state '||p_LOCK_STATE);
	END IF;
END APPLY_DATA_LOCK_GROUP_ITEM;
---------------------------------------------------------------------------------------------------
PROCEDURE APPLY_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID	IN NUMBER,
	p_LOCKED_THROUGH_DATE	IN DATE
	) AS
v_GROUP				DATA_LOCK_GROUP%ROWTYPE;
v_NEW_DATE			DATE;
v_BEGIN_DATE		DATE;
v_END_DATE			DATE;
v_DATES_ARE_CUT		BOOLEAN;
CURSOR cur_ITEMS IS
	SELECT *
	FROM DATA_LOCK_GROUP_ITEM
	WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID;
BEGIN
	SAVEPOINT BEFORE_APPLY;

	SELECT * INTO v_GROUP FROM DATA_LOCK_GROUP WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID;

	-- make sure locked through date is valid per group's defined interval
	v_NEW_DATE := DATE_UTIL.HED_TRUNC(p_LOCKED_THROUGH_DATE, GET_INTERVAL_ABBREVIATION(v_GROUP.DATA_LOCK_GROUP_INTERVAL), v_GROUP.WEEK_BEGIN, TRUE);

	IF INTERVAL_IS_ATLEAST_DAILY(v_GROUP.DATA_LOCK_GROUP_INTERVAL) THEN
		-- take last processed date and advance it - that is where we start
		v_BEGIN_DATE := DATE_UTIL.ADVANCE_DATE(v_GROUP.LAST_PROCESSED_INTERVAL, v_GROUP.DATA_LOCK_GROUP_INTERVAL, v_GROUP.WEEK_BEGIN);
		-- find the ending date+time for the new locked-through interval
		v_END_DATE := DATE_UTIL.GET_INTERVAL_END_DATE(v_NEW_DATE, GET_INTERVAL_ABBREVIATION(v_GROUP.DATA_LOCK_GROUP_INTERVAL), v_GROUP.WEEK_BEGIN);
		v_DATES_ARE_CUT := FALSE;
	ELSE
		-- sub-daily dates are stored as interval-ending and in CUT
		v_BEGIN_DATE := v_GROUP.LAST_PROCESSED_INTERVAL+1/86400;
		v_END_DATE := v_NEW_DATE;
		v_DATES_ARE_CUT := TRUE;
	END IF;

	IF v_BEGIN_DATE IS NULL THEN
		v_BEGIN_DATE := LOW_DATE;
	END IF;

	LOGS.LOG_INFO('Applying '||TEXT_UTIL.TO_CHAR_ENTITY(p_DATA_LOCK_GROUP_ID, EC.ED_DATA_LOCK_GROUP, TRUE),
				p_SOURCE_DATE => v_NEW_DATE, p_SOURCE_DOMAIN_ID => EC.ED_DATA_LOCK_GROUP, p_SOURCE_ENTITY_ID => p_DATA_LOCK_GROUP_ID);

	IF LOGS.IS_DEBUG_ENABLED THEN
		LOGS.LOG_DEBUG('Begin Date: '||TEXT_UTIL.TO_CHAR_TIME(v_BEGIN_DATE)||' '||CASE WHEN v_DATES_ARE_CUT THEN GA.CUT_TIME_ZONE ELSE v_GROUP.TIME_ZONE END);
		LOGS.LOG_DEBUG('End Date: '||TEXT_UTIL.TO_CHAR_TIME(v_END_DATE)||' '||CASE WHEN v_DATES_ARE_CUT THEN GA.CUT_TIME_ZONE ELSE v_GROUP.TIME_ZONE END);
	END IF;

	-- apply all items
	FOR v_ITEM IN cur_ITEMS LOOP
		APPLY_DATA_LOCK_GROUP_ITEM(v_ITEM, v_GROUP.TIME_ZONE, v_GROUP.WEEK_BEGIN,
							   v_BEGIN_DATE, v_END_DATE, v_DATES_ARE_CUT, v_GROUP.LOCK_STATE);
	END LOOP;

	-- and then update the group's last-processed-interval of record
	UPDATE DATA_LOCK_GROUP
	SET LAST_PROCESSED_INTERVAL = v_NEW_DATE
	WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID;

EXCEPTION
	WHEN OTHERS THEN
		-- don't want exception to result in partial lock
		ERRS.LOG_AND_RAISE(p_SAVEPOINT_NAME => 'BEFORE_APPLY');
END APPLY_DATA_LOCK_GROUP;
---------------------------------------------------------------------------------------------------
PROCEDURE APPLY_AUTO_DATA_LOCK_GROUPS AS
	v_NEW_DATE	DATE;
	v_DLG_NAME	VARCHAR2(2000);
	CURSOR cur_AUTO_GROUPS IS
		SELECT DATA_LOCK_GROUP_ID,
			DATA_LOCK_GROUP_NAME,
			AUTOLOCK_DATE_FORMULA,
			LAST_PROCESSED_INTERVAL,
			DATA_LOCK_GROUP_INTERVAL,
			WEEK_BEGIN
		FROM DATA_LOCK_GROUP
		WHERE IS_AUTOMATIC = 1;
BEGIN
	FOR v_AUTO_GROUP IN cur_AUTO_GROUPS LOOP
		v_DLG_NAME := TEXT_UTIL.TO_CHAR_ENTITY(v_AUTO_GROUP.DATA_LOCK_GROUP_ID, EC.ED_DATA_LOCK_GROUP, TRUE);

		BEGIN
			v_NEW_DATE := GET_LOCK_GROUP_DATE(v_AUTO_GROUP.DATA_LOCK_GROUP_NAME,
											  v_AUTO_GROUP.AUTOLOCK_DATE_FORMULA,
											  GET_INTERVAL_ABBREVIATION(v_AUTO_GROUP.DATA_LOCK_GROUP_INTERVAL),
											  v_AUTO_GROUP.WEEK_BEGIN);
		EXCEPTION
			WHEN MSGCODES.e_ERR_INVALID_DATE THEN
				ERRS.LOG_AND_CONTINUE;
				v_NEW_DATE := NULL;
		END;

		-- apply the group if needed
		IF v_NEW_DATE IS NOT NULL AND v_NEW_DATE > v_AUTO_GROUP.LAST_PROCESSED_INTERVAL THEN
			LOGS.LOG_NOTICE('Automatically applying Data Lock Group: '||v_AUTO_GROUP.DATA_LOCK_GROUP_NAME||
							' through '||TEXT_UTIL.TO_CHAR_TIME(v_NEW_DATE));
			BEGIN
				APPLY_DATA_LOCK_GROUP(v_AUTO_GROUP.DATA_LOCK_GROUP_ID, v_NEW_DATE);
			EXCEPTION
				WHEN OTHERS THEN
					ERRS.LOG_AND_CONTINUE('Could not auto-apply Data Lock Group: '||v_AUTO_GROUP.DATA_LOCK_GROUP_NAME||
										' through '||TEXT_UTIL.TO_CHAR_TIME(v_NEW_DATE));
			END;
		END IF;
	END LOOP;
END APPLY_AUTO_DATA_LOCK_GROUPS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_LOCK_GROUP_DATE
	(
	p_DATA_LOCK_GROUP_NAME	IN VARCHAR2,
	p_DATE_FML				IN VARCHAR2,
	p_INTERVAL_ABBR			IN VARCHAR2,
	p_WEEK_BEGIN			IN VARCHAR2
	) RETURN DATE IS
v_SQL	VARCHAR2(4020);
v_DATE	DATE;
BEGIN
	-- evaluate this group's formula
	v_SQL := 'SELECT ('||p_DATE_FML||') FROM DUAL';
	EXECUTE IMMEDIATE v_SQL INTO v_DATE;

	-- restrict the date to match the group's interval
	IF INTERVAL_IS_ATLEAST_DAILY(p_INTERVAL_ABBR)
	   AND v_DATE = TRUNC(v_DATE) THEN
		-- HED_TRUNC - used below - treats right-at-midnight as HE 24 of previous day. But
		-- if group's interval is day or greater and formula evaluates to right at midnight,
		-- we want it to mean that day. We can get HED_TRUNC to play nicely with this value
		-- by simply incrementing it by one second.
		v_DATE := v_DATE+1/86400;
	END IF;

	RETURN DATE_UTIL.HED_TRUNC(v_DATE, p_INTERVAL_ABBR, p_WEEK_BEGIN, TRUE);

EXCEPTION
	WHEN OTHERS THEN
		ERRS.RAISE_BAD_DATE(p_DATE_FML,
						'Data Formula for Data Lock Group: '||p_DATA_LOCK_GROUP_NAME);

END GET_LOCK_GROUP_DATE;
---------------------------------------------------------------------------------------------------
END DATA_LOCK;
/
