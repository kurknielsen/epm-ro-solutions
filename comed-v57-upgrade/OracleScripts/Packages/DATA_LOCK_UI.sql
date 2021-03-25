CREATE OR REPLACE PACKAGE DATA_LOCK_UI AS
--Revision $Revision: 1.4 $

-- UI package for Data Locking

FUNCTION WHAT_VERSION RETURN VARCHAR;

-- Called from the Entity Manager for the Data Lock Group Entity's Put Procedure.
--   Calls through to the IO.PUT_DATA_LOCK_GROUP procedure, but makes sure that if IS_AUTOMATIC
--   is 1, then only AUTOLOCK_DATE_FORMULA is set, or if IS_AUTOMATIC is 0 that
--   LOCK_LIMIT_DATE_FORMULA is set
PROCEDURE PUT_DATA_LOCK_GROUP
	(
	o_OID OUT NUMBER,
	p_DATA_LOCK_GROUP_NAME IN VARCHAR2,
	p_DATA_LOCK_GROUP_ALIAS IN VARCHAR2,
	p_DATA_LOCK_GROUP_DESC IN VARCHAR2,
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_DATA_LOCK_GROUP_INTERVAL IN VARCHAR2,
	p_IS_AUTOMATIC IN NUMBER,
	p_AUTOLOCK_DATE_FORMULA IN VARCHAR2,
	p_LOCK_LIMIT_DATE_FORMULA IN VARCHAR2,
	p_LOCK_STATE IN VARCHAR2,
	p_LAST_PROCESSED_INTERVAL IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2
	);

-- Gets the data for the "Tables to Lock" sub-tab of the Data Lock Group
--    Entity in the Entity Manager.
PROCEDURE GET_DATA_LOCK_GROUP_TABLES
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Gets the list of Lockable Tables for the Table Filter on the Data Lock Group
--    Criteria report.
PROCEDURE GET_LOCKABLE_TABLE_LIST
	(
	p_CURSOR OUT GA.REFCURSOR
	);

-- Gets the data for the Master Grid of the Data Lock Group Criteria Report.
PROCEDURE GET_DATA_LOCK_GROUP_ITEM_SUMM
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);

-- Put Procedure for the Master Grid of the Data Lock Group Criteria Report.
-- It ONLY gets called when there are no criteria columns for the System Table
--  (For example, Measurement Source Data).  For most System Tables, this upper
--  Grid is not editable.  In the event that this procedure is called, however,
--  an item is inserted/deleted into/from the ITEM table depending on whether the
--  IS_INCLUDED flag is checked.  Nothing is inserted in the CRITERIA table.
PROCEDURE PUT_DATA_LOCK_GROUP_ITEM_SUMM
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_IS_SELECTED IN NUMBER
	);

-- Gets the data for the Detail Grid of the Data Lock Group Criteria Report.
PROCEDURE GET_DATA_LOCK_GROUP_ITEM_DETL
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- PUT Procedure for the Detail Grid of the Data Lock Group Criteria Report.
PROCEDURE PUT_DATA_LOCK_GROUP_ITEM
	(
	p_DATA_LOCK_GROUP_ITEM_ID IN NUMBER,
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN CHAR,
	p_ENTITY_ID IN NUMBER,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION
	);

-- DELETE Procedure for the Detail Grid of the Data Lock Group Criteria Report.
PROCEDURE DEL_DATA_LOCK_GROUP_ITEM
	(
	p_DATA_LOCK_GROUP_ITEM_ID IN NUMBER
	);

-- Get the contents of the 'Apply Data Lock Group' report
PROCEDURE GET_APPLY_DATA_LOCK_GRP_REPORT
	(
	p_TIME_ZONE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Get all possible dates between current last processed interval (exclusive)
-- and value of group's lock limit (inclusive).
PROCEDURE GET_DATES_FOR_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Applies specified data lock group through the provided date
PROCEDURE APPLY_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_APPLY_THROUGH IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2
	);

-- Retrieve a list of all entities for the specified System Table. This
-- will enumerate entities to which the
PROCEDURE ENTITIES_FOR_TABLE
	(
	p_TABLE_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Populates the 'Lock State Summary' view
PROCEDURE GET_LOCK_STATE_SUMMARY_REPORT
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);

-- Save changes to 'Lock State Summary' view which allows users to change the
-- lock state for summary records in the lock summary table (which implicitly
-- updates lock state of applicable date records)
PROCEDURE PUT_LOCK_STATE_SUMMARY_REPORT
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOCK_STATE IN VARCHAR2,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION
	);

-- Populates the top grid of the 'By Data Criteria' report in the 'Lock/Unlock Data' view
PROCEDURE LOCK_BY_CRITERIA_SUMMARY
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);

-- Populates the bottom grid of the 'By Data Criteria' report in the 'Lock/Unlock Data' view
PROCEDURE LOCK_BY_CRITERIA_DETAIL
	(
	p_TABLE_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Populates the summary grid of the 'By Data Lock Group' report in the 'Lock/Unlock Data' view
PROCEDURE LOCK_BY_DATA_LOCK_GROUP_SUMMRY
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

-- Populates the detail grid of the 'By Data Lock Group' report in the 'Lock/Unlock Data' view
PROCEDURE LOCK_BY_DATA_LOCK_GROUP_DETAIL
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);

-- Update data lock state using data criteria
PROCEDURE LOCK_BY_CRITERIA
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN STRING_COLLECTION,
	p_ENTITY_ID IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION,
	p_LOCK_STATE IN VARCHAR2,
	p_MESSAGE OUT VARCHAR2
	);

-- Update data lock state using a data lock group as a template
PROCEDURE LOCK_BY_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_LOCK_STATE IN VARCHAR2,
	p_MESSAGE OUT VARCHAR2
	);

--
PROCEDURE GET_LOCK_WARNING_BY_CRITERIA
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN STRING_COLLECTION,
	p_ENTITY_ID IN NUMBER_COLLECTION,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_WORK_ID OUT NUMBER,
	p_WARNING_MESSAGE OUT VARCHAR2
	);

PROCEDURE GET_LOCK_WARN_BY_DATA_LOCK_GRP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_WORK_ID OUT NUMBER,
	p_WARNING_MESSAGE OUT VARCHAR2
	);

PROCEDURE GET_WARNING_LIST
	(
	p_WORK_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);
	
PROCEDURE COPY_DATA_LOCK_GROUP
	(
	p_ENTITY_ID IN NUMBER,
	p_NEW_ENTITY_ID OUT NUMBER,
	p_NEW_ENTITY_NAME OUT VARCHAR2
	);

END DATA_LOCK_UI;
/
CREATE OR REPLACE PACKAGE BODY DATA_LOCK_UI AS
----------------------------------------------------------------------------------------------------
c_LOCK_WARNING_MESSAGE CONSTANT VARCHAR2(1000) :=
							'You do not have privileges to update the lock state for all selected'||UTL_TCP.CRLF||
							'entities. You may proceed, but these entities will be ignored. Would you'||UTL_TCP.CRLF||
							'like to see a list of entities whose lock states will not be updated?';

CURSOR g_cur_LOCK_SUMMARY_COLS(p_TABLE_ID IN NUMBER) IS
	SELECT T.DB_TABLE_NAME, C.COLUMN_NAME, COLS.DATA_TYPE
	FROM SYSTEM_TABLE T, USER_CONS_COLUMNS C, USER_TAB_COLUMNS COLS
	WHERE T.TABLE_ID = p_TABLE_ID
		AND C.CONSTRAINT_NAME = DATA_LOCK.GET_LOCK_SUMMARY_KEY(p_TABLE_ID)
		AND C.TABLE_NAME = T.LOCK_SUMMARY_TABLE_NAME
		AND C.COLUMN_NAME NOT IN (NVL(T.ENTITY_ID_COLUMN_NAME,' '), 'BEGIN_DATE', 'END_DATE')
		AND COLS.TABLE_NAME = C.TABLE_NAME
		AND COLS.COLUMN_NAME = C.COLUMN_NAME
	ORDER BY C.POSITION;

CURSOR g_cur_DLG_ITEMS(p_DATA_LOCK_GROUP_ID IN NUMBER) IS
	SELECT I.*, ST.DB_TABLE_NAME
	FROM DATA_LOCK_GROUP_ITEM I, SYSTEM_TABLE ST
	WHERE I.DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID
		AND ST.TABLE_ID = I.TABLE_ID;

TYPE t_WARN_MAP IS TABLE OF DATE INDEX BY VARCHAR2(9);
g_WARN_MAP t_WARN_MAP;
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
	RETURN '$Revision: 1.4 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
-- Gets the list of Lockable Tables for the Table Filter on the Data Lock Group
--    Criteria report.
PROCEDURE GET_LOCKABLE_TABLE_LIST
	(
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT CASE AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED(TABLE_ID)
				WHEN 1 THEN TABLE_NAME
				ELSE '<html><i>'||TABLE_NAME||'</i></html>'
				END as TABLE_NAME,
			TABLE_ID,
			AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED(TABLE_ID) as ENABLED
		FROM SYSTEM_TABLE
		WHERE LOCK_SUMMARY_TABLE_NAME IS NOT NULL
			AND AUDIT_TRAIL.IS_TABLE_LOCKABLE(TABLE_ID) = 1
		ORDER BY AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED(TABLE_ID) DESC, TABLE_NAME;
END GET_LOCKABLE_TABLE_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_LOCK_DISABLED_MESSAGE
	(
	p_TABLE_ID IN NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	IF NOT UT.BOOLEAN_FROM_NUMBER(AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED(p_TABLE_ID)) THEN
		-- warn user that this table is not enabled for locking

		IF g_WARN_MAP.EXISTS(TRIM(TO_CHAR(p_TABLE_ID))) THEN
			-- wait at least one minute between warnings for the same table
			IF SYSDATE < g_WARN_MAP(TRIM(TO_CHAR(p_TABLE_ID))) + 1/1440 THEN
				RETURN;
			END IF;
		END IF;

		p_MESSAGE := '<html><p><strong>'||TEXT_UTIL.TO_CHAR_ENTITY(p_TABLE_ID, EC.ED_SYSTEM_TABLE, TRUE)||
					'</strong> does not currently have locking enabled.</p>'||
					'<p>Changes to lock state will not take effect until locking is enabled for this table.</p></html>';

		g_WARN_MAP(TRIM(TO_CHAR(p_TABLE_ID))) := SYSDATE;
	END IF;
END GET_LOCK_DISABLED_MESSAGE;
----------------------------------------------------------------------------------------------------
-- Called from the Entity Manager for the Data Lock Group Entity's Put Procedure.
--   Calls through to the IO.PUT_DATA_LOCK_GROUP procedure, but makes sure that if IS_AUTOMATIC
--   is 1, then only AUTOLOCK_DATE_FORMULA is set, or if IS_AUTOMATIC is 0 that
--   LOCK_LIMIT_DATE_FORMULA is set.
PROCEDURE PUT_DATA_LOCK_GROUP
	(
	o_OID OUT NUMBER,
	p_DATA_LOCK_GROUP_NAME IN VARCHAR2,
	p_DATA_LOCK_GROUP_ALIAS IN VARCHAR2,
	p_DATA_LOCK_GROUP_DESC IN VARCHAR2,
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_DATA_LOCK_GROUP_INTERVAL IN VARCHAR2,
	p_IS_AUTOMATIC IN NUMBER,
	p_AUTOLOCK_DATE_FORMULA IN VARCHAR2,
	p_LOCK_LIMIT_DATE_FORMULA IN VARCHAR2,
	p_LOCK_STATE IN VARCHAR2,
	p_LAST_PROCESSED_INTERVAL IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_WEEK_BEGIN IN VARCHAR2
	) AS
	v_IS_AUTOMATIC NUMBER := NVL(p_IS_AUTOMATIC,0);
BEGIN
	IF v_IS_AUTOMATIC = 1 THEN ASSERT(p_AUTOLOCK_DATE_FORMULA IS NOT NULL, 'Autolock Date Formula cannot be null.'); END IF;
	IF v_IS_AUTOMATIC = 0 THEN ASSERT(p_LOCK_LIMIT_DATE_FORMULA IS NOT NULL, 'Lock Limit Date Formula cannot be null.'); END IF;

	--Data Level Security is handled in here.
	IO.PUT_DATA_LOCK_GROUP(o_OID,
		p_DATA_LOCK_GROUP_NAME,
		p_DATA_LOCK_GROUP_ALIAS,
		p_DATA_LOCK_GROUP_DESC,
		p_DATA_LOCK_GROUP_ID,
		p_DATA_LOCK_GROUP_INTERVAL,
		v_IS_AUTOMATIC,
		CASE v_IS_AUTOMATIC WHEN 1 THEN p_AUTOLOCK_DATE_FORMULA ELSE NULL END,
		CASE v_IS_AUTOMATIC WHEN 0 THEN p_LOCK_LIMIT_DATE_FORMULA ELSE NULL END,
		p_LOCK_STATE,
		p_LAST_PROCESSED_INTERVAL,
		p_TIME_ZONE,
		p_WEEK_BEGIN);

END PUT_DATA_LOCK_GROUP;
----------------------------------------------------------------------------------------------------
-- Gets the data for the "Tables to Lock" sub-tab of the Data Lock Group
--    Entity in the Entity Manager.
PROCEDURE GET_DATA_LOCK_GROUP_TABLES
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	-- Do not return anything if an entity is not selected.
	IF p_DATA_LOCK_GROUP_ID < 0 THEN
		OPEN p_CURSOR FOR
			SELECT NULL FROM DUAL
			WHERE 1 = 0;
		RETURN;
	END IF;

	OPEN p_CURSOR FOR
		SELECT CASE AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED(T.TABLE_ID)
				WHEN 1 THEN T.TABLE_NAME
				ELSE '<html><i>'||T.TABLE_NAME||'</i></html>'
				END as TABLE_NAME,
			T.TABLE_ID,
			AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED(T.TABLE_ID) as IS_ENABLED,
			(SELECT CASE COUNT(1) WHEN 0 THEN 0 ELSE 1 END
			FROM DATA_LOCK_GROUP_ITEM
			WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID
			AND TABLE_ID = T.TABLE_ID) AS IS_INCLUDED
		FROM SYSTEM_TABLE T
		WHERE T.LOCK_SUMMARY_TABLE_NAME IS NOT NULL
			AND AUDIT_TRAIL.IS_TABLE_LOCKABLE(T.TABLE_ID) = 1
		ORDER BY AUDIT_TRAIL.IS_TABLE_LOCKING_ENABLED(T.TABLE_ID) DESC, T.TABLE_NAME;

END GET_DATA_LOCK_GROUP_TABLES;
----------------------------------------------------------------------------------------------------
-- Gets the data for the Master Grid of the Data Lock Group Criteria Report.
PROCEDURE GET_DATA_LOCK_GROUP_ITEM_SUMM
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	) AS
	v_WORK_ID	RTO_WORK.WORK_ID%TYPE;
BEGIN
	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT,p_DATA_LOCK_GROUP_ID,EC.ED_DATA_LOCK_GROUP);

	SD.ENUMERATE_ENTITIES(SD.g_ACTION_SELECT_ENT, p_ENTITY_DOMAIN_ID, v_WORK_ID);

	GET_LOCK_DISABLED_MESSAGE(p_TABLE_ID, p_MESSAGE);

	OPEN p_CURSOR FOR
		SELECT X.ENTITY_TYPE,
			X.ENTITY_NAME,
			X.ENTITY_ID,
			p_DATA_LOCK_GROUP_ID AS DATA_LOCK_GROUP_ID,
			COUNT(I.DATA_LOCK_GROUP_ITEM_ID) AS NUM_CRITERIA,
			CASE WHEN COUNT(I.DATA_LOCK_GROUP_ITEM_ID) > 0 THEN 1 ELSE 0 END AS IS_SELECTED
		FROM
			(SELECT 'E' AS ENTITY_TYPE,
				WORK_DATA AS ENTITY_NAME,
				WORK_XID AS ENTITY_ID
			FROM RTO_WORK
			WHERE WORK_ID = v_WORK_ID
				AND WORK_XID > 0
			UNION ALL
			SELECT 'R',
				REALM_NAME,
				REALM_ID
			FROM SYSTEM_REALM
			WHERE REALM_CALC_TYPE = EM.c_REALM_CALC_TYPE_SYSTEM
				AND (ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID OR REALM_ID = SD.g_ALL_DATA_REALM_ID)
			UNION ALL
			SELECT 'G',
				ENTITY_GROUP_NAME,
				ENTITY_GROUP_ID
			FROM ENTITY_GROUP
				WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID) X,
			DATA_LOCK_GROUP_ITEM I
		WHERE I.DATA_LOCK_GROUP_ID(+) = p_DATA_LOCK_GROUP_ID
			AND I.TABLE_ID(+) = p_TABLE_ID
			AND I.ENTITY_DOMAIN_ID(+) = p_ENTITY_DOMAIN_ID
			AND I.ENTITY_TYPE(+) = X.ENTITY_TYPE
			AND I.ENTITY_ID(+) = X.ENTITY_ID
		GROUP BY X.ENTITY_TYPE, X.ENTITY_NAME, X.ENTITY_ID
		ORDER BY 1,2;

	UT.PURGE_RTO_WORK(v_WORK_ID);
END GET_DATA_LOCK_GROUP_ITEM_SUMM;
----------------------------------------------------------------------------------------------------
-- Put Procedure for the Master Grid of the Data Lock Group Criteria Report.
-- It ONLY gets called when there are no criteria columns for the System Table
--  (For example, Measurement Source Data).  For most System Tables, this upper
--  Grid is not editable.  In the event that this procedure is called, however,
--  an item is inserted/deleted into/from the ITEM table depending on whether the
--  IS_INCLUDED flag is checked.  Nothing is inserted in the CRITERIA table.
PROCEDURE PUT_DATA_LOCK_GROUP_ITEM_SUMM
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_IS_SELECTED IN NUMBER
	) AS
	v_COUNT BINARY_INTEGER;
BEGIN
	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT,p_DATA_LOCK_GROUP_ID,EC.ED_DATA_LOCK_GROUP);

	--If the entity is selected, see if there is a record for it, and add one if there is not.
	IF UT.BOOLEAN_FROM_NUMBER(p_IS_SELECTED) THEN
		SELECT COUNT(1) INTO v_COUNT
		FROM DATA_LOCK_GROUP_ITEM
		WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID
			AND TABLE_ID = p_TABLE_ID
			AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND ENTITY_TYPE = p_ENTITY_TYPE
			AND ENTITY_ID = p_ENTITY_ID;

		IF v_COUNT = 0 THEN
			PUT_DATA_LOCK_GROUP_ITEM(0, p_DATA_LOCK_GROUP_ID, p_TABLE_ID, p_ENTITY_DOMAIN_ID, p_ENTITY_TYPE, p_ENTITY_ID, NULL, NULL);
		END IF;

	-- If the entity is not selected, just be sure to delete its items.
	ELSE
		DELETE DATA_LOCK_GROUP_ITEM
		WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID
			AND TABLE_ID = p_TABLE_ID
			AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND ENTITY_TYPE = p_ENTITY_TYPE
			AND ENTITY_ID = p_ENTITY_ID;
	END IF;

END PUT_DATA_LOCK_GROUP_ITEM_SUMM;
----------------------------------------------------------------------------------------------------
FUNCTION GET_CRITERIA_COLUMN_EXPRESSION
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_COLUMN_TYPE IN VARCHAR2,
	p_FORCE_ID_NAME IN BOOLEAN := FALSE
	) RETURN VARCHAR2 IS
BEGIN
	--Cast Numeric columns to NUMBER so that the special combos on the grids will recognize
	-- them as ID values.
		-- Note that we translate any <All> values to a -1 for numeric columns.
	RETURN '	MAX(CASE WHEN C.COLUMN_NAME = '''||p_COLUMN_NAME||'''
				THEN '||CASE WHEN p_COLUMN_TYPE = 'NUMBER' THEN 'CASE C.COLUMN_VALUE WHEN '''||CONSTANTS.ALL_STRING||''' THEN '||CONSTANTS.ALL_ID||' ELSE TO_NUMBER(C.COLUMN_VALUE) END' ELSE 'C.COLUMN_VALUE' END||'
				ELSE NULL
				END) AS '||CASE WHEN p_FORCE_ID_NAME AND p_COLUMN_NAME = 'SCHEDULE_TYPE' THEN 'SCHEDULE_TYPE_ID' ELSE p_COLUMN_NAME END;
			-- The above line is a HACK because the Special combos in the grid cannot handle an "Item Combo" that
			-- doesn't end in _ID.  So we are renaming the SCHEDULE_TYPE column to SCHEDULE_TYPE_ID, and we translate
			-- back in the save procedure.

END GET_CRITERIA_COLUMN_EXPRESSION;
----------------------------------------------------------------------------------------------------
-- Gets the data for the Detail Grid of the Data Lock Group Criteria Report.
PROCEDURE GET_DATA_LOCK_GROUP_ITEM_DETL
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
	v_SQL VARCHAR2(4000);
	v_HAS_COLS BOOLEAN := FALSE;
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT,p_DATA_LOCK_GROUP_ID,EC.ED_DATA_LOCK_GROUP);

	--Start the SQL for the ref cursor
	v_SQL := 'SELECT I.DATA_LOCK_GROUP_ITEM_ID';

	--Get a column for each key that isn't the Entity ID, or Begin/End/As of Date.
	FOR v_COL IN g_cur_LOCK_SUMMARY_COLS(p_TABLE_ID) LOOP
		v_SQL := v_SQL||','||UTL_TCP.CRLF||GET_CRITERIA_COLUMN_EXPRESSION(v_COL.COLUMN_NAME, v_COL.DATA_TYPE, TRUE);
		v_HAS_COLS := TRUE;
	END LOOP;

	IF v_HAS_COLS THEN
		--Finish out the SQL for the ref cursor
		v_SQL := v_SQL||UTL_TCP.CRLF||
			'FROM DATA_LOCK_GROUP_ITEM I, DATA_LOCK_GROUP_ITEM_CRITERIA C
			WHERE I.DATA_LOCK_GROUP_ID = '||p_DATA_LOCK_GROUP_ID||'
				AND I.TABLE_ID = '||p_TABLE_ID||'
				AND I.ENTITY_DOMAIN_ID = '||p_ENTITY_DOMAIN_ID||'
				AND I.ENTITY_TYPE = '''||p_ENTITY_TYPE||'''
				AND I.ENTITY_ID = '||p_ENTITY_ID||'
				AND C.DATA_LOCK_GROUP_ITEM_ID = I.DATA_LOCK_GROUP_ITEM_ID
			GROUP BY I.DATA_LOCK_GROUP_ITEM_ID';

		LOGS.LOG_DEBUG('SQL = '||v_SQL);
		OPEN p_CURSOR FOR v_SQL;
	ELSE
		-- If there were no columns, we have a special result set.
		OPEN p_CURSOR FOR
			SELECT '<html><i>(No selection of criteria is required.  Please select entities in the upper grid.)</i></html>' AS MESSAGE
			FROM DUAL;
	END IF;

END GET_DATA_LOCK_GROUP_ITEM_DETL;
----------------------------------------------------------------------------------------------------
-- PUT Procedure for the Detail Grid of the Data Lock Group Criteria Report.
PROCEDURE PUT_DATA_LOCK_GROUP_ITEM
	(
	p_DATA_LOCK_GROUP_ITEM_ID IN NUMBER,
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN CHAR,
	p_ENTITY_ID IN NUMBER,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION
	) AS
	v_DATA_LOCK_GROUP_ITEM_ID DATA_LOCK_GROUP_ITEM.DATA_LOCK_GROUP_ITEM_ID%TYPE;
	v_COLUMN_NAME DATA_LOCK_GROUP_ITEM_CRITERIA.COLUMN_NAME%TYPE;
	v_COLUMN_VALUE DATA_LOCK_GROUP_ITEM_CRITERIA.COLUMN_VALUE%TYPE;
BEGIN
	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT,p_DATA_LOCK_GROUP_ID,EC.ED_DATA_LOCK_GROUP);

	-- Insert the DATA_LOCK_GROUP_ITEM record if it did not exist.
	IF NVL(p_DATA_LOCK_GROUP_ITEM_ID,0) = 0 THEN
		SELECT OID.NEXTVAL INTO v_DATA_LOCK_GROUP_ITEM_ID FROM DUAL;

		INSERT INTO DATA_LOCK_GROUP_ITEM(DATA_LOCK_GROUP_ITEM_ID, DATA_LOCK_GROUP_ID, TABLE_ID, ENTITY_DOMAIN_ID, ENTITY_TYPE, ENTITY_ID)
		VALUES(v_DATA_LOCK_GROUP_ITEM_ID, p_DATA_LOCK_GROUP_ID, p_TABLE_ID, p_ENTITY_DOMAIN_ID, p_ENTITY_TYPE, p_ENTITY_ID);
	ELSE
		v_DATA_LOCK_GROUP_ITEM_ID := p_DATA_LOCK_GROUP_ITEM_ID;
	END IF;

	-- Now handle the Item Criteria.
	IF p_COL_NAME_LIST IS NOT NULL AND p_COL_DATA_LIST IS NOT NULL THEN
		ASSERT(p_COL_NAME_LIST.COUNT = p_COL_DATA_LIST.COUNT, 'COL_NAME_LIST and COL_DATA_LIST must be collections of the same size.');

		DELETE DATA_LOCK_GROUP_ITEM_CRITERIA WHERE DATA_LOCK_GROUP_ITEM_ID = v_DATA_LOCK_GROUP_ITEM_ID;

		FOR i IN p_COL_NAME_LIST.FIRST .. p_COL_NAME_LIST.LAST LOOP
			v_COLUMN_NAME := p_COL_NAME_LIST(i);

			IF UPPER(v_COLUMN_NAME) <> 'DATA_LOCK_GROUP_ITEM_ID' THEN
				v_COLUMN_VALUE := NVL(p_COL_DATA_LIST(i), CONSTANTS.ALL_STRING);

				--Check for a value of '-1' and assume this should really be <All>.
				IF v_COLUMN_VALUE = '-1' THEN v_COLUMN_VALUE := CONSTANTS.ALL_STRING; END IF;

				--Translate the SCHEDULE_TYPE_ID column back into its true name: SCHEDULE_TYPE
				-- (See GET_DATA_LOCK_GROUP_ITEM_DETL for more information.)
				IF v_COLUMN_NAME = 'SCHEDULE_TYPE_ID' THEN v_COLUMN_NAME := 'SCHEDULE_TYPE'; END IF;

				INSERT INTO DATA_LOCK_GROUP_ITEM_CRITERIA(DATA_LOCK_GROUP_ITEM_ID, COLUMN_NAME, COLUMN_VALUE)
				VALUES(v_DATA_LOCK_GROUP_ITEM_ID, v_COLUMN_NAME, v_COLUMN_VALUE);
			END IF;
		END LOOP;
	END IF;

END PUT_DATA_LOCK_GROUP_ITEM;
----------------------------------------------------------------------------------------------------
-- DELETE Procedure for the Detail Grid of the Data Lock Group Criteria Report.
PROCEDURE DEL_DATA_LOCK_GROUP_ITEM
	(
	p_DATA_LOCK_GROUP_ITEM_ID IN NUMBER
	) AS
	v_DATA_LOCK_GROUP_ID DATA_LOCK_GROUP.DATA_LOCK_GROUP_ID%TYPE;
BEGIN
	-- Get the Data Lock Group ID for DLS check.
	BEGIN
		SELECT DATA_LOCK_GROUP_ID
		INTO v_DATA_LOCK_GROUP_ID
		FROM DATA_LOCK_GROUP_ITEM
		WHERE DATA_LOCK_GROUP_ITEM_ID = p_DATA_LOCK_GROUP_ITEM_ID;
	EXCEPTION
		--If this item doesn't exist, we don't need to delete it.
		WHEN NO_DATA_FOUND THEN
			ERRS.LOG_AND_CONTINUE(p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
			RETURN;
	END;

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_UPDATE_ENT,v_DATA_LOCK_GROUP_ID,EC.ED_DATA_LOCK_GROUP);

	DELETE DATA_LOCK_GROUP_ITEM WHERE DATA_LOCK_GROUP_ITEM_ID = p_DATA_LOCK_GROUP_ITEM_ID;

END DEL_DATA_LOCK_GROUP_ITEM;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_APPLY_DATA_LOCK_GRP_REPORT
	(
	p_TIME_ZONE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	) AS
v_IDs	ID_TABLE;
BEGIN
	v_IDs := SD.GET_ALLOWED_ENTITY_ID_TABLE(SD.g_ACTION_SELECT_ENT, EC.ED_DATA_LOCK_GROUP);

	OPEN p_CURSOR FOR
		SELECT DLG.DATA_LOCK_GROUP_NAME,
			DLG.DATA_LOCK_GROUP_ID,
			DLG.IS_AUTOMATIC,
			CASE DATE_UTIL.IS_SUB_DAILY_NUM(DLG.DATA_LOCK_GROUP_INTERVAL)
				WHEN 1 THEN FROM_CUT_AS_HED(DLG.LAST_PROCESSED_INTERVAL, p_TIME_ZONE, 'MI5')
				ELSE FROM_CUT_AS_HED(DLG.LAST_PROCESSED_INTERVAL, GA.CUT_TIME_ZONE, 'DD')
				END as LAST_PROCESSED_DATE
		FROM DATA_LOCK_GROUP DLG,
			TABLE(CAST(v_IDs as ID_TABLE)) IDs
		WHERE IDs.ID IN (DLG.DATA_LOCK_GROUP_ID, SD.g_ALL_DATA_ENTITY_ID)
		ORDER BY 1;

END GET_APPLY_DATA_LOCK_GRP_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_DATES_FOR_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR
	) AS
v_GROUP			DATA_LOCK_GROUP%ROWTYPE;
v_WORK_ID		RTO_WORK.WORK_ID%TYPE;
v_START_DATE	DATE;
v_FINISH_DATE	DATE;
v_INTERVAL		VARCHAR2(16);
v_SEQ			PLS_INTEGER := 0;
BEGIN
	SELECT * INTO v_GROUP
	FROM DATA_LOCK_GROUP
	WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID;

	UT.GET_RTO_WORK_ID(v_WORK_ID);

	-- Result always includes a "blank" to indicate no-op
	INSERT INTO RTO_WORK (WORK_ID, WORK_SEQ, WORK_DATA) VALUES (v_WORK_ID, v_SEQ, '');
	v_SEQ := v_SEQ+1;

	IF NVL(v_GROUP.IS_AUTOMATIC,0) = 0 THEN
		-- manual lock groups get a list of dates between current date and the lock limit

		v_INTERVAL := GET_INTERVAL_ABBREVIATION(v_GROUP.DATA_LOCK_GROUP_INTERVAL);
		-- group has never been locked? then start with begin date parameter
		IF v_GROUP.LAST_PROCESSED_INTERVAL IS NULL THEN
			IF INTERVAL_IS_ATLEAST_DAILY(v_INTERVAL) THEN
				v_START_DATE := TRUNC(p_BEGIN_DATE);
			ELSE
				-- sub-daily? convert begin date to CUT
				v_START_DATE := TO_CUT(TRUNC(p_BEGIN_DATE), p_TIME_ZONE)+1/86400;
			END IF;
			v_START_DATE := DATE_UTIL.HED_TRUNC(v_START_DATE, v_INTERVAL, v_GROUP.WEEK_BEGIN, TRUE);
		ELSE
			v_START_DATE := v_GROUP.LAST_PROCESSED_INTERVAL;
			v_START_DATE := DATE_UTIL.HED_TRUNC(v_START_DATE, v_INTERVAL, v_GROUP.WEEK_BEGIN, TRUE);
			-- increment start date because the selection excludes current "locked through" date
			v_START_DATE := DATE_UTIL.ADVANCE_DATE(v_START_DATE, v_INTERVAL, v_GROUP.WEEK_BEGIN);
		END IF;

		-- determine the limit date
		v_FINISH_DATE := DATA_LOCK.GET_LOCK_GROUP_DATE(v_GROUP.DATA_LOCK_GROUP_NAME,
													v_GROUP.LOCK_LIMIT_DATE_FORMULA,
													v_INTERVAL,
													v_GROUP.WEEK_BEGIN);

		-- Now create list of valid dates that can be locked
		WHILE v_START_DATE <= v_FINISH_DATE LOOP
			INSERT INTO RTO_WORK (WORK_ID, WORK_SEQ, WORK_DATA)
			VALUES (v_WORK_ID, v_SEQ, CASE DATE_UTIL.IS_SUB_DAILY_NUM(v_INTERVAL)
										WHEN 1 THEN FROM_CUT_AS_HED(v_START_DATE, p_TIME_ZONE, 'MI5')
										ELSE FROM_CUT_AS_HED(v_START_DATE, GA.CUT_TIME_ZONE, 'DD')
										END);
			v_SEQ := v_SEQ+1;
			-- on to the next date
			v_START_DATE := DATE_UTIL.ADVANCE_DATE(v_START_DATE, v_INTERVAL, v_GROUP.WEEK_BEGIN);
		END LOOP;
	END IF;

	OPEN p_CURSOR FOR
		SELECT WORK_DATA
		FROM RTO_WORK
		WHERE WORK_ID = v_WORK_ID
		ORDER BY WORK_SEQ;

	UT.PURGE_RTO_WORK(v_WORK_ID);
END GET_DATES_FOR_DATA_LOCK_GROUP;
----------------------------------------------------------------------------------------------------
PROCEDURE APPLY_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_APPLY_THROUGH IN VARCHAR2,
	p_TIME_ZONE IN VARCHAR2
	) AS
v_APPLY_THROUGH	DATE;
v_LIMIT			DATE;
v_GROUP			DATA_LOCK_GROUP%ROWTYPE;
v_DATE			VARCHAR2(10);
v_TIME			VARCHAR2(10);
BEGIN
	-- Make sure user is allowed to do this
	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_APPLY_DATA_LOCK_GROUP, p_DATA_LOCK_GROUP_ID, EC.ED_DATA_LOCK_GROUP);

	SELECT * INTO v_GROUP
	FROM DATA_LOCK_GROUP
	WHERE DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID;

	ASSERT(NVL(v_GROUP.IS_AUTOMATIC,0) = 0,
			v_GROUP.DATA_LOCK_GROUP_NAME||' is an Automatic Data Lock Group and cannot be applied manually');

	-- Convert specified date to an actual date value
	v_DATE := SUBSTR(p_APPLY_THROUGH,1,10);
	v_TIME := SUBSTR(p_APPLY_THROUGH,12);
	v_APPLY_THROUGH := DATE_TIME_AS_CUT(v_DATE, v_TIME, p_TIME_ZONE, 1);
	IF v_TIME IS NULL THEN
		-- day+ values represented as 1-sec past midnight
		v_APPLY_THROUGH := v_APPLY_THROUGH + 1/86400;
	END IF;

	-- Now make sure that specified date does not exceed lock limit
	v_LIMIT := DATA_LOCK.GET_LOCK_GROUP_DATE(v_GROUP.DATA_LOCK_GROUP_NAME,
											 v_GROUP.LOCK_LIMIT_DATE_FORMULA,
											 GET_INTERVAL_ABBREVIATION(v_GROUP.DATA_LOCK_GROUP_INTERVAL),
											 v_GROUP.WEEK_BEGIN);
	ASSERT(v_APPLY_THROUGH <= v_LIMIT,
			'The specified date, '||TEXT_UTIL.TO_CHAR_TIME(v_APPLY_THROUGH)||', exceeds the lock limit for Data Lock Group: '||
			v_GROUP.DATA_LOCK_GROUP_NAME||', '||TEXT_UTIL.TO_CHAR_TIME(v_LIMIT));

	-- Finally - lock it!
	DATA_LOCK.APPLY_DATA_LOCK_GROUP(p_DATA_LOCK_GROUP_ID, v_APPLY_THROUGH);

END APPLY_DATA_LOCK_GROUP;
----------------------------------------------------------------------------------------------------
PROCEDURE ENTITIES_FOR_TABLE
	(
	p_TABLE_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
v_DOMAIN_ID	SYSTEM_TABLE.ENTITY_DOMAIN_ID%TYPE;
v_WORK_ID	RTO_WORK.WORK_ID%TYPE;
BEGIN
	SELECT ENTITY_DOMAIN_ID INTO v_DOMAIN_ID
	FROM SYSTEM_TABLE
	WHERE TABLE_ID = p_TABLE_ID;

	SD.ENUMERATE_ENTITIES(TO_NUMBER(NULL), v_DOMAIN_ID, v_WORK_ID);

	OPEN p_CURSOR FOR
		SELECT WORK_DATA as ENTITY_NAME,
			WORK_XID as ENTITY_ID
		FROM RTO_WORK
		WHERE WORK_ID = v_WORK_ID
			AND WORK_XID <> 0
		ORDER BY WORK_DATA;

	UT.PURGE_RTO_WORK(v_WORK_ID);
END ENTITIES_FOR_TABLE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ACTION_NAME
	(
	p_DB_TABLE_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS

	v_RET	SYSTEM_ACTION.ACTION_NAME%TYPE;

BEGIN
	v_RET := CASE p_DB_TABLE_NAME
			WHEN 'IT_SCHEDULE' THEN SD.g_ACTION_TXN_LOCK_STATE
			WHEN 'IT_TRAIT_SCHEDULE' THEN SD.g_ACTION_BAO_LOCK_STATE
			WHEN 'BILLING_STATEMENT' THEN SD.g_ACTION_PSE_BILL_LOCK_STATE
			WHEN 'MARKET_PRICE_VALUE' THEN SD.g_ACTION_MKT_PRICE_LOCK_STATE
			WHEN 'MEASUREMENT_SOURCE_VALUE' THEN SD.g_ACTION_MSRMNT_SRC_LOCK_STATE
			WHEN 'TX_SUB_STATION_METER_PT_VALUE' THEN SD.g_ACTION_SSMETER_LOCK_STATE
			ELSE NULL
			END;

	IF v_RET IS NULL THEN
		ERRS.RAISE_BAD_ARGUMENT('DB Table Name', p_DB_TABLE_NAME, 'Specified table is not valid for locking/unlocking');
	END IF;

	RETURN v_RET;

END GET_ACTION_NAME;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ENUM_ACTION_NAME
	(
	p_DB_TABLE_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS
BEGIN
	IF p_DB_TABLE_NAME = 'CALCULATION_RUN' THEN
		RETURN SD.g_ACTION_SELECT_ENT;
	ELSE
		RETURN GET_ACTION_NAME(p_DB_TABLE_NAME);
	END IF;
END GET_ENUM_ACTION_NAME;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_LOCK_STATE_SUMMARY_REPORT
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	) AS
v_TABLE			SYSTEM_TABLE%ROWTYPE;
v_ENTITY_IDs	NUMBER_COLLECTION;
v_SQL			VARCHAR2(32767);
v_ORDER_BY		VARCHAR2(256);
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;
v_USE_BEGIN_DATE DATE;
v_USE_END_DATE	DATE;
v_INTERVAL		VARCHAR2(16);
v_SCHED_DATES	BOOLEAN;
v_IDX			PLS_INTEGER;
v_ORDER_COL		PLS_INTEGER;
v_BEGIN_DATE_COL PLS_INTEGER;
BEGIN
	IF p_ENTITY_ID IS NULL OR p_ENTITY_ID.COUNT = 0 THEN
		-- nothing to do
		OPEN p_CURSOR FOR SELECT NULL FROM DUAL WHERE 0=1;
		RETURN;
	END IF;

	GET_LOCK_DISABLED_MESSAGE(p_TABLE_ID, p_MESSAGE);

	SELECT * INTO v_TABLE
	FROM SYSTEM_TABLE
	WHERE TABLE_ID = p_TABLE_ID;

	UT.CUT_DATE_RANGE(CONSTANTS.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE, p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);
	v_ENTITY_IDs := SD.GET_ALLOWED_IDS_FROM_SELECTION(SD.g_ACTION_SELECT_ENT, v_TABLE.ENTITY_DOMAIN_ID, p_ENTITY_ID);

	-- loop through selected entities, building query piece at a time
	v_IDX := v_ENTITY_IDs.FIRST;
	WHILE v_ENTITY_IDs.EXISTS(v_IDX) LOOP
		IF v_SQL IS NOT NULL THEN
			v_SQL := v_SQL||' UNION ALL ';
		END IF;
		v_ORDER_BY := NULL;
		v_ORDER_COL := 0;

		IF v_TABLE.DB_TABLE_NAME = 'IT_TRAIT_SCHEDULE' THEN
			-- this table's interval depends on the trait group, which we don't know
			-- so we'll use NULL interval and rely on sched dates to determine format
			-- (i.e. second-past-midnight means day, otherwise show minutes)
			v_INTERVAL := NULL;
			v_SCHED_DATES := TRUE;
		ELSE
			BEGIN
				DATE_UTIL.GET_DATA_INTERVAL_INFO(v_TABLE.DB_TABLE_NAME, v_ENTITY_IDs(V_IDX), UT.c_EMPTY_MAP, v_INTERVAL, v_SCHED_DATES);
				v_INTERVAL := NVL(GET_INTERVAL_ABBREVIATION(v_INTERVAL),'HH');
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					ERRS.LOG_AND_CONTINUE(v_ENTITY_IDs(v_IDX), p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
			END;
		END IF;

		v_SQL := v_SQL||' SELECT CASE LOCK_STATE WHEN ''L'' THEN ''Locked'' WHEN ''R'' THEN ''Restricted'' ELSE ''Unlocked'' END as LOCK_STATE';
		-- Query will have "X_" prefix for actual data, which should be hidden. Other columns have "display" values
		-- that can be left un-hidden. The hidden data will be in the form of PL/SQL literal values.
		-- In addition to "X_*" columns, there are three other columns that should be hidden and are passed to
		-- the save procedure for the report: ENTITY_ID, CUT_BEGIN_DATE, and CUT_END_DATE

		-- Add entity ID column if there is one
		IF v_TABLE.ENTITY_ID_COLUMN_NAME IS NOT NULL THEN
			v_SQL := v_SQL||','||UTL_TCP.CRLF||
					v_TABLE.ENTITY_ID_COLUMN_NAME||' as ENTITY_ID,'||
					-- include "display" value for this column
					AUDIT_TRAIL.GET_DISPLAY_EXPRESSION(v_TABLE.DB_TABLE_NAME, v_TABLE.ENTITY_ID_COLUMN_NAME);
			v_ORDER_BY := '2'; -- order by entity display value
			v_ORDER_COL := 2;  -- increment by two to accound for these two columns
		END IF;

		-- Add begin and end date columns if this table is temporal
		IF v_TABLE.DATE1_COLUMN_NAME IS NOT NULL THEN
			v_SQL := v_SQL||', '||UTL_TCP.CRLF||
					'BEGIN_DATE as CUT_BEGIN_DATE, END_DATE as CUT_END_DATE, ';

			-- include "display" values for these date columns
			IF v_INTERVAL IS NULL AND v_SCHED_DATES THEN
				-- no interval? we can still figure out the format if they are "scheduling" dates
				-- because they'll be one second past midnight for day and greater formats. So we
				-- format as day in that case and format as minute otherwise.
				v_SQL := v_SQL||'FROM_CUT_AS_HED(BEGIN_DATE, '||UT.GET_LITERAL_FOR_STRING(p_TIME_ZONE)||', CASE WHEN TO_CHAR(BEGIN_DATE,''HH24MISS'')=''000001'' THEN ''DD'' ELSE ''MI5'' END) as DISP_BEGIN_DATE,
								FROM_CUT_AS_HED(END_DATE, '||UT.GET_LITERAL_FOR_STRING(p_TIME_ZONE)||', CASE WHEN TO_CHAR(END_DATE,''HH24MISS'')=''000001'' THEN ''DD'' ELSE ''MI5'' END) as DISP_END_DATE';
			ELSE
				v_SQL := v_SQL||'FROM_CUT_AS_HED(BEGIN_DATE, '||UT.GET_LITERAL_FOR_STRING(p_TIME_ZONE)||', '||UT.GET_LITERAL_FOR_STRING(v_INTERVAL)||') as DISP_BEGIN_DATE,
								FROM_CUT_AS_HED(END_DATE, '||UT.GET_LITERAL_FOR_STRING(p_TIME_ZONE)||', '||UT.GET_LITERAL_FOR_STRING(v_INTERVAL)||') as DISP_END_DATE';
			END IF;

			v_BEGIN_DATE_COL := v_ORDER_COL+1; -- remember the begin date column
			v_ORDER_COL := v_ORDER_COL+4;  -- increment by four to accound for these four columns
		END IF;

		--Get a column for each key that isn't the Entity ID, or Begin/End/As of Date.
		FOR v_COL IN g_cur_LOCK_SUMMARY_COLS(p_TABLE_ID) LOOP
			v_SQL := v_SQL||','||UTL_TCP.CRLF||
					-- build PL/SQL literal value
					'UT.GET_LITERAL_FOR_'||CASE WHEN v_COL.DATA_TYPE LIKE '%CHAR%' THEN 'STRING' ELSE v_COL.DATA_TYPE END||
						'('||v_COL.COLUMN_NAME||') as X_'||v_COL.COLUMN_NAME||', '||
					-- and build display value using same logic as audit trail
					AUDIT_TRAIL.GET_DISPLAY_EXPRESSION(v_COL.DB_TABLE_NAME, v_COL.COLUMN_NAME);
			-- include the display values in order by clause
			v_ORDER_COL := v_ORDER_COL+2; -- increment by two each time
			IF v_ORDER_BY IS NOT NULL THEN
				v_ORDER_BY := v_ORDER_BY||',';
			END IF;
			v_ORDER_BY := v_ORDER_BY||v_ORDER_COL;
		END LOOP;

		-- add begin date to order by clause
		IF v_BEGIN_DATE_COL IS NOT NULL THEN
			IF v_ORDER_BY IS NOT NULL THEN
				v_ORDER_BY := v_ORDER_BY||',';
			END IF;
			v_ORDER_BY := v_ORDER_BY||v_BEGIN_DATE_COL; -- order by CUT_BEGIN_DATE column
		END IF;

		-- finish building SQL
		v_SQL := v_SQL||UTL_TCP.CRLF||
				' FROM '||v_TABLE.LOCK_SUMMARY_TABLE_NAME||
				' WHERE '||v_TABLE.ENTITY_ID_COLUMN_NAME||' = '||UT.GET_LITERAL_FOR_NUMBER(v_ENTITY_IDs(v_IDX));

		IF INTERVAL_IS_ATLEAST_DAILY(v_INTERVAL) THEN
			v_USE_BEGIN_DATE := TRUNC(p_BEGIN_DATE,v_INTERVAL);
			v_USE_END_DATE := TRUNC(p_END_DATE,v_INTERVAL);
			-- advance end date to last second of the interval
			v_USE_END_DATE := DATE_UTIL.ADVANCE_DATE(v_USE_END_DATE, v_INTERVAL) - 1/86400;
		ELSE
			-- just use time-zone shifted begin and end dates
			v_USE_BEGIN_DATE := v_BEGIN_DATE;
			v_USE_END_DATE := v_END_DATE;
		END IF;

		v_SQL := v_SQL||' AND BEGIN_DATE <= '||UT.GET_LITERAL_FOR_DATE(v_USE_END_DATE)||
						' AND NVL(END_DATE,'||UT.GET_LITERAL_FOR_DATE(CONSTANTS.HIGH_DATE)||') >= '||UT.GET_LITERAL_FOR_DATE(v_USE_BEGIN_DATE);

		-- onto next entity
		v_IDX := v_ENTITY_IDs.NEXT(v_IDX);
	END LOOP;

	-- tack on order by clause
	IF v_ORDER_BY IS NOT NULL THEN
		v_SQL := v_SQL||' ORDER BY '||v_ORDER_BY;
	END IF;

	LOGS.LOG_DEBUG('SQL = '||v_SQL);
	OPEN p_CURSOR FOR v_SQL;

END GET_LOCK_STATE_SUMMARY_REPORT;
----------------------------------------------------------------------------------------------------
-- Verify that user has appropriate privileges. Return TRUE if user has appropriate privileges or
-- FALSE otherwise. If p_RAISE_EXCEPTION is TRUE, this will raise an exception instead of returning
-- FALSE. If p_WORK_ID is not null and p_RAISE_EXCEPTION is FALSE, this will record details of
-- the entity to RTO_WORK for entities that fail validation.
FUNCTION VALIDATE_PRIVILEGES
	(
	p_TABLE_NAME		IN VARCHAR2,
	p_ENTITY_DOMAIN_ID	IN NUMBER,
	p_ENTITY_ID			IN NUMBER,
	p_SOURCE_DOMAIN_ID	IN NUMBER,
	p_SOURCE_ENTITY_ID	IN NUMBER,
	p_CRITERIA			IN UT.STRING_MAP,
	p_BEGIN_DATE		IN DATE,
	p_END_DATE			IN DATE,
	p_WORK_ID			IN NUMBER := NULL,
	p_RAISE_EXCEPTION	IN BOOLEAN := TRUE
	) RETURN BOOLEAN IS
v_SRC_NAME	VARCHAR2(1000);
v_NAME		VARCHAR2(1000);
v_ACTION_ID	SYSTEM_ACTION.ACTION_ID%TYPE;
v_DOMAIN_ID	CALCULATION_PROCESS.CONTEXT_DOMAIN_ID%TYPE;
v_ENTITY_ID	NUMBER(9);
v_REALM_ID	CALCULATION_PROCESS.CONTEXT_REALM_ID%TYPE;
v_GROUP_ID	CALCULATION_PROCESS.CONTEXT_GROUP_ID%TYPE;
v_WORK_ID	RTO_WORK.WORK_ID%TYPE;
v_COUNT		PLS_INTEGER;
v_ACTION_NAME SYSTEM_ACTION.ACTION_NAME%TYPE;
BEGIN
	IF p_TABLE_NAME = 'CALCULATION_RUN' THEN
		IF SD.GET_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT, p_ENTITY_ID, p_ENTITY_DOMAIN_ID) THEN
			ENTITY_UTIL.GET_CALC_PROCESS_SECURITY_INFO(p_ENTITY_ID, ENTITY_UTIL.c_ACTION_TYPE_LK_STATE,
														v_ACTION_ID, v_DOMAIN_ID, v_REALM_ID, v_GROUP_ID);
			IF NVL(v_DOMAIN_ID,CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED THEN
				-- check if action is allowed
				IF SD.GET_ACTION_IS_ALLOWED(v_ACTION_ID) THEN
					RETURN TRUE;
				ELSIF p_RAISE_EXCEPTION THEN
					ERRS.RAISE_NO_PRIVILEGE_ACTION(EI.GET_ENTITY_NAME(EC.ED_SYSTEM_ACTION, v_ACTION_ID));
				END IF;
			ELSE
				-- if process has a context domain, we need to actually check the
				-- criteria map to see what context entity is being locked.
				IF p_CRITERIA.EXISTS('CONTEXT_ENTITY_ID') THEN
					IF p_CRITERIA('CONTEXT_ENTITY_ID') <> CONSTANTS.LITERAL_NULL THEN

						v_ENTITY_ID := TO_NUMBER(p_CRITERIA('CONTEXT_ENTITY_ID'));
						IF SD.GET_ENTITY_IS_ALLOWED(v_ACTION_ID, v_ENTITY_ID, v_DOMAIN_ID) THEN
							RETURN TRUE;
						ELSIF p_RAISE_EXCEPTION THEN
							ERRS.RAISE_NO_PRIVILEGE_ACTION(EI.GET_ENTITY_NAME(EC.ED_SYSTEM_ACTION, v_ACTION_ID), v_DOMAIN_ID, v_ENTITY_ID);
						ELSE
							-- build extra info text that identifies the context entity
							v_NAME := TEXT_UTIL.TO_CHAR_ENTITY(v_ENTITY_ID, v_DOMAIN_ID, TRUE);
						END IF;

					END IF;
				ELSE
					-- not specified? that implies all - so see to what IDs user actually
					-- has access. We'll return TRUE (i.e. valid) if user does have
					-- access to at least one
					SD.ENUMERATE_ENTITIES(v_ACTION_ID, v_DOMAIN_ID, v_WORK_ID,
								v_REALM_ID, v_GROUP_ID, p_BEGIN_DATE, p_END_DATE, TRUE);
					SELECT COUNT(1)
					INTO v_COUNT
					FROM RTO_WORK
					WHERE WORK_ID = v_WORK_ID;
					-- go ahead and clean up
					UT.PURGE_RTO_WORK(v_WORK_ID);

					IF v_COUNT > 0 THEN
						RETURN TRUE;
					ELSIF p_RAISE_EXCEPTION THEN
						ERRS.RAISE_NO_PRIVILEGE_ACTION(EI.GET_ENTITY_NAME(EC.ED_SYSTEM_ACTION, v_ACTION_ID));
					END IF;

				END IF;
			END IF;
		END IF;
	ELSE
		-- not CALCULATION_RUN? then this is really easy to figure out
		v_ACTION_NAME := GET_ACTION_NAME(p_TABLE_NAME);

		IF NVL(p_ENTITY_DOMAIN_ID,CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED THEN
			-- simply 'no-entity' test
			IF SD.GET_ACTION_IS_ALLOWED(v_ACTION_NAME) THEN
				RETURN TRUE;
			ELSIF p_RAISE_EXCEPTION THEN
				ERRS.RAISE_NO_PRIVILEGE_ACTION(v_ACTION_NAME);
			END IF;
		ELSE
			-- entity test
			IF SD.GET_ENTITY_IS_ALLOWED(v_ACTION_NAME, p_ENTITY_ID, p_ENTITY_DOMAIN_ID) THEN
				RETURN TRUE;
			ELSIF p_RAISE_EXCEPTION THEN
				ERRS.RAISE_NO_PRIVILEGE_ACTION(v_ACTION_NAME, p_ENTITY_DOMAIN_ID, p_ENTITY_ID);
			END IF;
		END IF;
	END IF;

	IF p_WORK_ID IS NOT NULL THEN
		-- Haven't returned yet? Then validation failed - record message to
		-- RTO_WORK and return FALSE
		v_SRC_NAME := TEXT_UTIL.TO_CHAR_ENTITY(p_SOURCE_ENTITY_ID, p_SOURCE_DOMAIN_ID, TRUE);
		IF v_NAME IS NULL THEN
			v_NAME := TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_ID, p_ENTITY_DOMAIN_ID, TRUE);
		ELSE
			-- incorporate details already specified in v_NAME above
			v_NAME := TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_ID, p_ENTITY_DOMAIN_ID, TRUE)||' for '||v_NAME;
		END IF;
		-- work_data is the "source" specification and work_data2 is single entity.
		-- these will be the same when user specifies row with entity_type = 'E'
		-- unless they specify a sub-station or sub-station meter (in which case
		-- single entity will be a meter data point).
		INSERT INTO RTO_WORK (WORK_ID, WORK_DATA, WORK_DATA2)
		VALUES (p_WORK_ID, v_SRC_NAME, v_NAME);
	END IF;

	RETURN FALSE;

END VALIDATE_PRIVILEGES;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_LOCK_STATE_SUMMARY_REPORT
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE IN DATE,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_LOCK_STATE IN VARCHAR2,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION
	) AS

v_TABLE			SYSTEM_TABLE%ROWTYPE;
v_IDX			PLS_INTEGER;
v_CRITERIA		UT.STRING_MAP;
v_DUMMY_B		BOOLEAN;
v_DUMMY_N		PLS_INTEGER;

BEGIN
	SELECT * INTO v_TABLE
	FROM SYSTEM_TABLE
	WHERE TABLE_ID = p_TABLE_ID;

	v_IDX := p_COL_NAME_LIST.FIRST;
	WHILE p_COL_NAME_LIST.EXISTS(v_IDX) LOOP
		-- columns starting with "X_" indicate the ones we want, and they are
		-- already in PL/SQL literal form, so just stash the value into the
		-- criteria map
		IF SUBSTR(p_COL_NAME_LIST(v_IDX),1,2) = 'X_' THEN
			v_CRITERIA(SUBSTR(p_COL_NAME_LIST(v_IDX),3)) := p_COL_DATA_LIST(v_IDX);
		END IF;
		v_IDX := p_COL_NAME_LIST.NEXT(v_IDX);
	END LOOP;

	-- validate security
	v_DUMMY_B := VALIDATE_PRIVILEGES(v_TABLE.DB_TABLE_NAME, v_TABLE.ENTITY_DOMAIN_ID, p_ENTITY_ID, NULL, NULL, v_CRITERIA, p_BEGIN_DATE, p_END_DATE);

	-- update locks
	v_DUMMY_N := DATA_LOCK.UPDATE_LOCK_STATE(p_TABLE_ID, p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE, v_CRITERIA, SUBSTR(p_LOCK_STATE,1,1));

END PUT_LOCK_STATE_SUMMARY_REPORT;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCK_BY_CRITERIA_SUMMARY
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	) AS
	v_ACTION_NAME	SYSTEM_ACTION.ACTION_NAME%TYPE;
	v_WORK_ID		RTO_WORK.WORK_ID%TYPE;
BEGIN
	v_ACTION_NAME := GET_ENUM_ACTION_NAME(ENTITY_UTIL.DB_TABLE_NAME_FOR_TABLE(p_TABLE_ID));
	SD.ENUMERATE_ENTITIES(v_ACTION_NAME, p_ENTITY_DOMAIN_ID, v_WORK_ID);

	GET_LOCK_DISABLED_MESSAGE(p_TABLE_ID, p_MESSAGE);

	OPEN p_CURSOR FOR
		SELECT 'E' AS ENTITY_TYPE,
			WORK_DATA AS ENTITY_NAME,
			WORK_XID AS ENTITY_ID
		FROM RTO_WORK
		WHERE WORK_ID = v_WORK_ID
			AND WORK_XID > 0
		UNION ALL
		SELECT 'R',
			REALM_NAME,
			REALM_ID
		FROM SYSTEM_REALM
		WHERE REALM_CALC_TYPE = EM.c_REALM_CALC_TYPE_SYSTEM
			AND (ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID OR REALM_ID = SD.g_ALL_DATA_REALM_ID)
		UNION ALL
		SELECT 'G',
			ENTITY_GROUP_NAME,
			ENTITY_GROUP_ID
		FROM ENTITY_GROUP
			WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		ORDER BY 1,2;

	UT.PURGE_RTO_WORK(v_WORK_ID);
END LOCK_BY_CRITERIA_SUMMARY;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCK_BY_CRITERIA_DETAIL
	(
	p_TABLE_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS

	v_SQL VARCHAR2(4000);
	v_HAS_COLS BOOLEAN := FALSE;

BEGIN
	-- Queries a single row with all blank values - one for each key column in the
	-- lock summary table

	--Start the SQL for the ref cursor
	v_SQL := 'SELECT ';

	--Get a column for each key that isn't the Entity ID, or Begin/End/As of Date.
	FOR v_COL IN g_cur_LOCK_SUMMARY_COLS(p_TABLE_ID) LOOP
		IF NOT v_HAS_COLS THEN
			v_HAS_COLS := TRUE;
		ELSE
			v_SQL := v_SQL||','||UTL_TCP.CRLF;
		END IF;

		v_SQL := v_SQL||'NULL as '||CASE WHEN V_COL.COLUMN_NAME = 'SCHEDULE_TYPE' THEN 'SCHEDULE_TYPE_ID' ELSE v_COL.COLUMN_NAME END;
			-- The above line is a HACK because the Special combos in the grid cannot handle an "Item Combo" that
			-- doesn't end in _ID.  So we are renaming the SCHEDULE_TYPE column to SCHEDULE_TYPE_ID, and we translate
			-- back in the save procedure.
	END LOOP;

	IF v_HAS_COLS THEN
		--Finish out the SQL for the ref cursor
		v_SQL := v_SQL||UTL_TCP.CRLF||
			'FROM DUAL';

		LOGS.LOG_DEBUG('SQL = '||v_SQL);
		OPEN p_CURSOR FOR v_SQL;
	ELSE
		-- If there were no columns, we have a special result set.
		OPEN p_CURSOR FOR
			SELECT NULL FROM DUAL WHERE 0=1;
	END IF;

END LOCK_BY_CRITERIA_DETAIL;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCK_BY_DATA_LOCK_GROUP_SUMMRY
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
	v_WORK_ID	RTO_WORK.WORK_ID%TYPE;
BEGIN
	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT,p_DATA_LOCK_GROUP_ID,EC.ED_DATA_LOCK_GROUP);

	OPEN p_CURSOR FOR
		SELECT I.TABLE_ID,
			T.TABLE_NAME,
			I.ENTITY_DOMAIN_ID,
			ED.ENTITY_DOMAIN_NAME,
			I.ENTITY_TYPE,
			I.ENTITY_ID,
			ENTITY_NAME_FROM_IDS(CASE I.ENTITY_TYPE
									WHEN 'R' THEN EC.ED_SYSTEM_REALM
									WHEN 'G' THEN EC.ED_ENTITY_GROUP
									ELSE I.ENTITY_DOMAIN_ID
									END, I.ENTITY_ID) as ENTITY_NAME,
			p_DATA_LOCK_GROUP_ID AS DATA_LOCK_GROUP_ID,
			COUNT(I.DATA_LOCK_GROUP_ITEM_ID) AS NUM_CRITERIA
		FROM DATA_LOCK_GROUP_ITEM I,
			ENTITY_DOMAIN ED,
			SYSTEM_TABLE T
		WHERE I.DATA_LOCK_GROUP_ID = p_DATA_LOCK_GROUP_ID
			AND ED.ENTITY_DOMAIN_ID = I.ENTITY_DOMAIN_ID
			AND T.TABLE_ID = I.TABLE_ID
		GROUP BY I.TABLE_ID,
			T.TABLE_NAME,
			I.ENTITY_DOMAIN_ID,
			ED.ENTITY_DOMAIN_NAME,
			I.ENTITY_TYPE,
			I.ENTITY_ID
		ORDER BY 2,4,5,7;

	UT.PURGE_RTO_WORK(v_WORK_ID);

END LOCK_BY_DATA_LOCK_GROUP_SUMMRY;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCK_BY_DATA_LOCK_GROUP_DETAIL
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_SQL VARCHAR2(4000);
	v_OUTER_SQL	VARCHAR2(4000);
	v_HAS_COLS BOOLEAN := FALSE;

BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT,p_DATA_LOCK_GROUP_ID,EC.ED_DATA_LOCK_GROUP);

	GET_LOCK_DISABLED_MESSAGE(p_TABLE_ID, p_MESSAGE);

	--Start the SQL for the ref cursor
	v_OUTER_SQL := 'SELECT ';
	v_SQL := 'SELECT ';

	--Get a column for each key that isn't the Entity ID, or Begin/End/As of Date.
	FOR v_COL IN g_cur_LOCK_SUMMARY_COLS(p_TABLE_ID) LOOP
		IF NOT v_HAS_COLS THEN
			v_HAS_COLS := TRUE;
		ELSE
			v_OUTER_SQL := v_OUTER_SQL||','||UTL_TCP.CRLF;
			v_SQL := v_SQL||','||UTL_TCP.CRLF;
		END IF;

		-- Outer query converts values to display values using same logic as audit trail
		v_OUTER_SQL := v_OUTER_SQL||AUDIT_TRAIL.GET_DISPLAY_EXPRESSION(v_COL.DB_TABLE_NAME, v_COL.COLUMN_NAME, p_NAME_SUFFIX => NULL, p_ALLOW_ALL_ID => TRUE);

		-- Inner query transposes rows in DATA_LOCK_GROUP_ITEM_CRITERIA
		v_SQL := v_SQL||GET_CRITERIA_COLUMN_EXPRESSION(v_COL.COLUMN_NAME, v_COL.DATA_TYPE);
	END LOOP;

	IF v_HAS_COLS THEN
		--Finish out the SQL for the ref cursor
		v_SQL := v_SQL||UTL_TCP.CRLF||
			'FROM DATA_LOCK_GROUP_ITEM I, DATA_LOCK_GROUP_ITEM_CRITERIA C
			WHERE I.DATA_LOCK_GROUP_ID = '||p_DATA_LOCK_GROUP_ID||'
				AND I.TABLE_ID = '||p_TABLE_ID||'
				AND I.ENTITY_DOMAIN_ID = '||p_ENTITY_DOMAIN_ID||'
				AND I.ENTITY_TYPE = '''||p_ENTITY_TYPE||'''
				AND I.ENTITY_ID = '||p_ENTITY_ID||'
				AND C.DATA_LOCK_GROUP_ITEM_ID = I.DATA_LOCK_GROUP_ITEM_ID
			GROUP BY I.DATA_LOCK_GROUP_ITEM_ID';
		-- combine w/ outer query portion
		v_OUTER_SQL := v_OUTER_SQL||' FROM ('||v_SQL||')';

		LOGS.LOG_DEBUG('SQL = '||v_OUTER_SQL);
		OPEN p_CURSOR FOR v_OUTER_SQL;
	ELSE
		-- If there were no columns, we have a special result set.
		OPEN p_CURSOR FOR
			SELECT '<html><i>(No selection of criteria is required.  Please select entities in the upper grid.)</i></html>' AS MESSAGE
			FROM DUAL;
	END IF;

END LOCK_BY_DATA_LOCK_GROUP_DETAIL;
----------------------------------------------------------------------------------------------------
FUNCTION LOCK_CALCULATION_RUN
	(
	p_TABLE_ID		IN NUMBER,
	p_ENTITY_TYPE	IN VARCHAR2,
	p_ENTITY_ID		IN NUMBER,
	p_BEGIN_DATE	IN DATE,
	p_END_DATE		IN DATE,
	p_CUT_BEGIN_DATE IN DATE,
	p_CUT_END_DATE	IN DATE,
	p_TIME_ZONE		IN VARCHAR2,
	p_CRITERIA		IN UT.STRING_MAP,
	p_LOCK_STATE	IN CHAR
	) RETURN PLS_INTEGER AS

	v_PROCS_WORK_ID				RTO_WORK.WORK_ID%TYPE;
	v_CONTEXT_ENTITIES_WORK_ID	RTO_WORK.WORK_ID%TYPE;
	v_ROWCOUNT					PLS_INTEGER := 0;
	v_ACTION_ID					SYSTEM_ACTION.ACTION_ID%TYPE;
	v_DOMAIN_ID					CALCULATION_PROCESS.CONTEXT_DOMAIN_ID%TYPE;
	v_REALM_ID					CALCULATION_PROCESS.CONTEXT_REALM_ID%TYPE;
	v_GROUP_ID					CALCULATION_PROCESS.CONTEXT_GROUP_ID%TYPE;
	v_CRITERIA					UT.STRING_MAP := p_CRITERIA;
	v_ENTITY_ID					NUMBER(9);
	v_CONTEXT_ENTITY_ID			NUMBER(9);
	--=======================================================================
	PROCEDURE DO_LOCK IS
	BEGIN
		v_ROWCOUNT := v_ROWCOUNT + DATA_LOCK.UPDATE_LOCK_STATE(p_TABLE_ID, EC.ED_CALC_PROCESS,
									'E', v_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE,
									p_TIME_ZONE, TRUE, v_CRITERIA, p_LOCK_STATE);
	END DO_LOCK;
	--=======================================================================
BEGIN
	-- expand group or realm references to list of entities
	v_PROCS_WORK_ID := ENTITY_UTIL.EXPAND_ENTITY(EC.ED_CALC_PROCESS,
											p_ENTITY_TYPE,
											p_ENTITY_ID,
											SD.g_ACTION_SELECT_ENT,
											p_BEGIN_DATE,
											p_END_DATE,
											TRUE);

	-- To lock calculation run data, user must have 'Select Entity' privilege
	-- on Calculation Process and must have appropriate privileges as defined
	-- in CALCULATION_PROCESS_SECURITY on the context entity
	FOR v_ENTITY IN ENTITY_UTIL.g_cur_ENTITY_IDs(v_PROCS_WORK_ID) LOOP
		v_ENTITY_ID := v_ENTITY.ENTITY_ID;
		IF SD.GET_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT, v_ENTITY.ENTITY_ID, Ec.ED_CALC_PROCESS) THEN
			ENTITY_UTIL.GET_CALC_PROCESS_SECURITY_INFO(v_ENTITY.ENTITY_ID, ENTITY_UTIL.c_ACTION_TYPE_LK_STATE,
														v_ACTION_ID, v_DOMAIN_ID, v_REALM_ID, v_GROUP_ID);
			IF NVL(v_DOMAIN_ID,CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED THEN
				-- check if action is allowed
				IF SD.GET_ACTION_IS_ALLOWED(v_ACTION_ID) THEN
					DO_LOCK;
				END IF;
			ELSE
				-- if process has a context domain, we need to actually check the
				-- criteria map to see what context entity is being locked.
				IF p_CRITERIA.EXISTS('CONTEXT_ENTITY_ID') THEN
					IF p_CRITERIA('CONTEXT_ENTITY_ID') <> CONSTANTS.LITERAL_NULL THEN

						v_CONTEXT_ENTITY_ID := TO_NUMBER(p_CRITERIA('CONTEXT_ENTITY_ID'));
						-- if allowed, lock it
						IF SD.GET_ENTITY_IS_ALLOWED(v_ACTION_ID, v_CONTEXT_ENTITY_ID, v_DOMAIN_ID) THEN
							DO_LOCK;
						END IF;

					END IF;
				ELSE
					-- not specified? that implies all - so see to what IDs user actually
					-- has access. We'll return TRUE (i.e. valid) if user does have
					-- access to at least one
					SD.ENUMERATE_ENTITIES(v_ACTION_ID, v_DOMAIN_ID, v_CONTEXT_ENTITIES_WORK_ID,
								v_REALM_ID, v_GROUP_ID, p_BEGIN_DATE, p_END_DATE, TRUE);

					FOR v_CONTEXT_ENTITY IN ENTITY_UTIL.g_cur_ENTITY_IDs(v_CONTEXT_ENTITIES_WORK_ID) LOOP
						-- apply lock for each allowed context entity
						v_CRITERIA('CONTEXT_ENTITY_ID') := UT.GET_LITERAL_FOR_NUMBER(v_CONTEXT_ENTITY.ENTITY_ID);
						DO_LOCK;
					END LOOP;

					UT.PURGE_RTO_WORK(v_CONTEXT_ENTITIES_WORK_ID);

				END IF;
			END IF;
		END IF;

	END LOOP;

	UT.PURGE_RTO_WORK(v_PROCS_WORK_ID);

	RETURN v_ROWCOUNT;

END LOCK_CALCULATION_RUN;
----------------------------------------------------------------------------------------------------
FUNCTION LOCK_DATA
	(
	p_TABLE_ID			IN NUMBER,
	p_ENTITY_DOMAIN_ID	IN NUMBER,
	p_ENTITY_TYPE		IN VARCHAR2,
	p_ENTITY_ID			IN NUMBER,
	p_BEGIN_DATE		IN DATE,
	p_END_DATE			IN DATE,
	p_CUT_BEGIN_DATE	IN DATE,
	p_CUT_END_DATE		IN DATE,
	p_TIME_ZONE			IN VARCHAR2,
	p_CRITERIA			IN UT.STRING_MAP,
	p_LOCK_STATE		IN VARCHAR2
	) RETURN PLS_INTEGER AS
v_DB_TABLE	SYSTEM_TABLE.DB_TABLE_NAME%TYPE := ENTITY_UTIL.DB_TABLE_NAME_FOR_TABLE(p_TABLE_ID);
v_ACTION_ID	SYSTEM_ACTION.ACTION_ID%TYPE;
v_LOCK_STATE CHAR := SUBSTR(p_LOCK_STATE,1,1);
BEGIN
	IF v_DB_TABLE = 'CALCULATION_RUN' THEN
		-- need special logic to handle the context entity ID and the way
		-- security actions are defined for calculation run data
		RETURN LOCK_CALCULATION_RUN(p_TABLE_ID, p_ENTITY_TYPE, p_ENTITY_ID, p_BEGIN_DATE, p_END_DATE,
									p_CUT_BEGIN_DATE, p_CUT_END_DATE, p_TIME_ZONE,
									p_CRITERIA, v_LOCK_STATE);
	ELSE
		v_ACTION_ID := ENTITY_UTIL.GET_ACTION_ID(GET_ACTION_NAME(v_DB_TABLE));
		RETURN DATA_LOCK.UPDATE_LOCK_STATE(p_TABLE_ID, p_ENTITY_DOMAIN_ID, p_ENTITY_TYPE,
									p_ENTITY_ID, p_CUT_BEGIN_DATE, p_CUT_END_DATE,
									p_TIME_ZONE, TRUE, p_CRITERIA, v_LOCK_STATE,
									p_ACTION_ID => v_ACTION_ID);
	END IF;
END LOCK_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE CRITERIA_FROM_COLLECTIONS
	(
	p_TABLE_ID		IN NUMBER,
	p_COL_NAME_LIST	IN STRING_COLLECTION,
	p_COL_DATA_LIST	IN STRING_COLLECTION,
	p_CRITERIA_MAP	IN OUT NOCOPY UT.STRING_MAP
	) AS
CURSOR cur_CRITERIA IS
	SELECT N.COLUMN_NAME, V.COLUMN_VALUE, C.DATA_TYPE
		-- get column names - translate SCHEDULE_TYPE_ID to SCHEDULE_TYPE
	FROM (SELECT CASE WHEN COLUMN_VALUE = 'SCHEDULE_TYPE_ID' THEN 'SCHEDULE_TYPE'
					ELSE COLUMN_VALUE
					END as COLUMN_NAME,
				ROWNUM as COL_IDX
			FROM TABLE(CAST(p_COL_NAME_LIST as STRING_COLLECTION))) N,
		-- get column values - translate negative ones to "ALL"
		(SELECT CASE WHEN COLUMN_VALUE = '-1' THEN CONSTANTS.ALL_STRING
					ELSE COLUMN_VALUE
					END as COLUMN_VALUE,
				ROWNUM as COL_IDX
			FROM TABLE(CAST(p_COL_DATA_LIST as STRING_COLLECTION))) V,
		-- join in other tables we'll need to convert column values into PL/SQL literals
		SYSTEM_TABLE ST,
		USER_TAB_COLS C
	WHERE V.COL_IDX = N.COL_IDX
		AND NVL(V.COLUMN_VALUE,' ') <> CONSTANTS.ALL_STRING -- can skip "ALL" values as these will be filled in by API
		AND ST.TABLE_ID = p_TABLE_ID
		AND C.TABLE_NAME = ST.DB_TABLE_NAME
		AND C.COLUMN_NAME = N.COLUMN_NAME;
BEGIN
	IF p_COL_NAME_LIST IS NOT NULL THEN
		ASSERT(p_COL_DATA_LIST IS NOT NULL, 'No column values have been specified (COL_DATA_LIST is NULL).');
		ASSERT(p_COL_NAME_LIST.COUNT = p_COL_DATA_LIST.COUNT, 'COL_NAME_LIST and COL_DATA_LIST must be collections of the same size.');
		-- collect the critera
		FOR v_CRITERIA IN cur_CRITERIA LOOP
			IF v_CRITERIA.COLUMN_VALUE IS NULL THEN
				p_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := CONSTANTS.LITERAL_NULL;
			ELSIF v_CRITERIA.DATA_TYPE = 'NUMBER' THEN
				p_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := UT.GET_LITERAL_FOR_NUMBER(TO_NUMBER(v_CRITERIA.COLUMN_VALUE));
			ELSE -- DATA_TYPE indicates string
				p_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := UT.GET_LITERAL_FOR_STRING(v_CRITERIA.COLUMN_VALUE);
			END IF;
		END LOOP;
	END IF;
END CRITERIA_FROM_COLLECTIONS;
----------------------------------------------------------------------------------------------------
PROCEDURE CRITERIA_FROM_DLG_ITEM
	(
	p_ITEM_ID		IN NUMBER,
	p_TABLE_ID		IN NUMBER,
	p_CRITERIA_MAP	IN OUT NOCOPY UT.STRING_MAP
	) AS

CURSOR cur_CRITERIA IS
	SELECT CR.COLUMN_NAME, CR.COLUMN_VALUE, C.DATA_TYPE
	FROM DATA_LOCK_GROUP_ITEM_CRITERIA CR, SYSTEM_TABLE ST, USER_TAB_COLS C
	WHERE CR.DATA_LOCK_GROUP_ITEM_ID = p_ITEM_ID
		AND CR.COLUMN_VALUE <> CONSTANTS.ALL_STRING -- can skip "ALL" values as these will be filled in by API
		AND ST.TABLE_ID = p_TABLE_ID
		AND C.TABLE_NAME = ST.DB_TABLE_NAME
		AND C.COLUMN_NAME = CR.COLUMN_NAME;
BEGIN
	FOR v_CRITERIA IN cur_CRITERIA LOOP
		IF v_CRITERIA.COLUMN_VALUE IS NULL THEN
			p_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := CONSTANTS.LITERAL_NULL;
		ELSIF v_CRITERIA.DATA_TYPE = 'NUMBER' THEN
			p_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := UT.GET_LITERAL_FOR_NUMBER(TO_NUMBER(v_CRITERIA.COLUMN_VALUE));
		ELSE -- DATA_TYPE indicates string
			p_CRITERIA_MAP(v_CRITERIA.COLUMN_NAME) := UT.GET_LITERAL_FOR_STRING(v_CRITERIA.COLUMN_VALUE);
		END IF;
	END LOOP;
END CRITERIA_FROM_DLG_ITEM;
----------------------------------------------------------------------------------------------------
FUNCTION GET_LOCK_MESSAGE
	(
	p_ROWCOUNT IN PLS_INTEGER,
	p_LOCK_STATE IN VARCHAR2
	) RETURN VARCHAR2 IS
BEGIN
	RETURN p_ROWCOUNT||' record'||CASE WHEN p_ROWCOUNT <> 1 THEN 's' ELSE NULL END||' '||
			CASE UPPER(SUBSTR(p_LOCK_STATE,1,1))
				WHEN 'L' THEN 'locked'
				WHEN 'R' THEN 'marked as restricted'
				WHEN 'U' THEN 'unlocked'
				ELSE 'updated' -- ???
				END||'.';
END GET_LOCK_MESSAGE;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCK_BY_CRITERIA
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN STRING_COLLECTION,
	p_ENTITY_ID IN NUMBER_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION,
	p_LOCK_STATE IN VARCHAR2,
	p_MESSAGE OUT VARCHAR2
	) AS

v_CRITERIA_MAP	UT.STRING_MAP;
v_IDX			PLS_INTEGER;
v_ROWCOUNT		PLS_INTEGER := 0;
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;

BEGIN

	UT.CUT_DATE_RANGE(CONSTANTS.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE,
						p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	CRITERIA_FROM_COLLECTIONS(p_TABLE_ID, p_COL_NAME_LIST, p_COL_DATA_LIST, v_CRITERIA_MAP);

	v_IDX := p_ENTITY_TYPE.FIRST;
	WHILE p_ENTITY_TYPE.EXISTS(v_IDX) LOOP
		-- lock the data
		v_ROWCOUNT := v_ROWCOUNT + LOCK_DATA(p_TABLE_ID, p_ENTITY_DOMAIN_ID,
											p_ENTITY_TYPE(v_IDX), p_ENTITY_ID(v_IDX),
											p_BEGIN_DATE, p_END_DATE, v_BEGIN_DATE, v_END_DATE,
											p_TIME_ZONE, v_CRITERIA_MAP, p_LOCK_STATE);

		v_IDX := p_ENTITY_TYPE.NEXT(v_IDX);
	END LOOP;

	p_MESSAGE := GET_LOCK_MESSAGE(v_ROWCOUNT, p_LOCK_STATE);

END LOCK_BY_CRITERIA;
----------------------------------------------------------------------------------------------------
PROCEDURE LOCK_BY_DATA_LOCK_GROUP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_TIME_ZONE IN VARCHAR2,
	p_LOCK_STATE IN VARCHAR2,
	p_MESSAGE OUT VARCHAR2
	) AS

v_CRITERIA_MAP	UT.STRING_MAP;
v_ROWCOUNT		PLS_INTEGER := 0;
v_BEGIN_DATE	DATE;
v_END_DATE		DATE;

BEGIN

	UT.CUT_DATE_RANGE(CONSTANTS.ELECTRIC_MODEL, p_BEGIN_DATE, p_END_DATE,
						p_TIME_ZONE, v_BEGIN_DATE, v_END_DATE);

	FOR v_ITEM IN g_cur_DLG_ITEMS(p_DATA_LOCK_GROUP_ID) LOOP
		-- collect the critera
		v_CRITERIA_MAP.DELETE;
		CRITERIA_FROM_DLG_ITEM(v_ITEM.DATA_LOCK_GROUP_ITEM_ID, v_ITEM.TABLE_ID, v_CRITERIA_MAP);
		-- lock the data
		v_ROWCOUNT := v_ROWCOUNT + LOCK_DATA(v_ITEM.TABLE_ID, v_ITEM.ENTITY_DOMAIN_ID,
											v_ITEM.ENTITY_TYPE, v_ITEM.ENTITY_ID,
											p_BEGIN_DATE, p_END_DATE, v_BEGIN_DATE, v_END_DATE,
											p_TIME_ZONE, v_CRITERIA_MAP, p_LOCK_STATE);
	END LOOP;

	p_MESSAGE := GET_LOCK_MESSAGE(v_ROWCOUNT, p_LOCK_STATE);

END LOCK_BY_DATA_LOCK_GROUP;
----------------------------------------------------------------------------------------------------
FUNCTION VALIDATE_PRIVILEGES
	(
	p_TABLE_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_CRITERIA IN UT.STRING_MAP,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_WORK_ID IN NUMBER
	) RETURN BOOLEAN IS
v_TMP_WORK_ID	RTO_WORK.WORK_ID%TYPE;
v_ALL_VALID		BOOLEAN := TRUE;
v_SRC_DOMAIN_ID	ENTITY_DOMAIN.ENTITY_DOMAIN_ID%TYPE := CASE p_ENTITY_TYPE WHEN 'R' THEN EC.ED_SYSTEM_REALM WHEN 'G' THEN EC.ED_ENTITY_GROUP ELSE p_ENTITY_DOMAIN_ID END;
v_CUR_DOMAIN_ID	ENTITY_DOMAIN.ENTITY_DOMAIN_ID%TYPE := p_ENTITY_DOMAIN_ID;
BEGIN
	-- expand group or realm references to list of entities
	v_TMP_WORK_ID := ENTITY_UTIL.EXPAND_ENTITY(p_ENTITY_DOMAIN_ID,
											p_ENTITY_TYPE,
											p_ENTITY_ID,
											TO_NUMBER(NULL),
											p_BEGIN_DATE,
											p_END_DATE,
											TRUE);
	-- Now we need to expand meter and sub-station domains to instead include all assigned meter points
	IF p_ENTITY_DOMAIN_ID IN (EC.ED_SUB_STATION, EC.ED_SUB_STATION_METER) THEN
		ENTITY_UTIL.EXPAND_WORKSET_METER_POINTS(p_ENTITY_DOMAIN_ID, v_TMP_WORK_ID);
		v_CUR_DOMAIN_ID := EC.ED_SUB_STATION_METER_POINT;
	END IF;

	FOR v_ENTITY IN ENTITY_UTIL.g_cur_ENTITY_IDs(v_TMP_WORK_ID) LOOP

		IF NOT VALIDATE_PRIVILEGES(p_TABLE_NAME, v_CUR_DOMAIN_ID, v_ENTITY.ENTITY_ID,
								v_SRC_DOMAIN_ID, p_ENTITY_ID, p_CRITERIA,
								p_BEGIN_DATE, p_END_DATE, p_WORK_ID, FALSE) THEN
			v_ALL_VALID := FALSE;
		END IF;

	END LOOP;

	UT.PURGE_RTO_WORK(v_TMP_WORK_ID);

	RETURN v_ALL_VALID;
END VALIDATE_PRIVILEGES;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_LOCK_WARNING_BY_CRITERIA
	(
	p_TABLE_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_TYPE IN STRING_COLLECTION,
	p_ENTITY_ID IN NUMBER_COLLECTION,
	p_COL_NAME_LIST IN STRING_COLLECTION,
	p_COL_DATA_LIST IN STRING_COLLECTION,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_WORK_ID OUT NUMBER,
	p_WARNING_MESSAGE OUT VARCHAR2
	) AS
v_CRITERIA_MAP	UT.STRING_MAP;
v_IDX			PLS_INTEGER;
v_TABLE_NAME	VARCHAR2(30) := ENTITY_UTIL.DB_TABLE_NAME_FOR_TABLE(p_TABLE_ID);
v_ALL_VALID		BOOLEAN := TRUE;
BEGIN
	UT.GET_RTO_WORK_ID(p_WORK_ID);

	CRITERIA_FROM_COLLECTIONS(p_TABLE_ID, p_COL_NAME_LIST, p_COL_DATA_LIST, v_CRITERIA_MAP);

	-- validate selections
	v_IDX := p_ENTITY_TYPE.FIRST;
	WHILE p_ENTITY_TYPE.EXISTS(v_IDX) LOOP

		IF NOT VALIDATE_PRIVILEGES(v_TABLE_NAME, p_ENTITY_DOMAIN_ID, p_ENTITY_TYPE(v_IDX),
									p_ENTITY_ID(v_IDX), v_CRITERIA_MAP,
									p_BEGIN_DATE, p_END_DATE, p_WORK_ID) THEN
			v_ALL_VALID := FALSE;
		END IF;

		v_IDX := p_ENTITY_TYPE.NEXT(v_IDX);
	END LOOP;

	IF NOT v_ALL_VALID THEN
		-- show warning
		p_WARNING_MESSAGE := c_LOCK_WARNING_MESSAGE;
	ELSE
		p_WORK_ID := NULL;
	END IF;

END GET_LOCK_WARNING_BY_CRITERIA;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_LOCK_WARN_BY_DATA_LOCK_GRP
	(
	p_DATA_LOCK_GROUP_ID IN NUMBER,
	p_BEGIN_DATE IN DATE,
	p_END_DATE IN DATE,
	p_WORK_ID OUT NUMBER,
	p_WARNING_MESSAGE OUT VARCHAR2
	) AS

v_CRITERIA_MAP	UT.STRING_MAP;
v_ALL_VALID		BOOLEAN := TRUE;

BEGIN
	UT.GET_RTO_WORK_ID(p_WORK_ID);

	FOR v_ITEM IN g_cur_DLG_ITEMS(p_DATA_LOCK_GROUP_ID) LOOP
		-- collect the critera
		v_CRITERIA_MAP.DELETE;
		CRITERIA_FROM_DLG_ITEM(v_ITEM.DATA_LOCK_GROUP_ITEM_ID, v_ITEM.TABLE_ID, v_CRITERIA_MAP);

		-- validate selections
		IF NOT VALIDATE_PRIVILEGES(v_ITEM.DB_TABLE_NAME, v_ITEM.ENTITY_DOMAIN_ID, v_ITEM.ENTITY_TYPE,
									v_ITEM.ENTITY_ID, v_CRITERIA_MAP,
									p_BEGIN_DATE, p_END_DATE, p_WORK_ID) THEN
			v_ALL_VALID := FALSE;
		END IF;

	END LOOP;

	IF NOT v_ALL_VALID THEN
		-- show warning
		p_WARNING_MESSAGE := c_LOCK_WARNING_MESSAGE;
	ELSE
		p_WORK_ID := NULL;
	END IF;

END GET_LOCK_WARN_BY_DATA_LOCK_GRP;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_WARNING_LIST
	(
	p_WORK_ID IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT WORK_DATA as SPECIFIED_ENTITY,
			WORK_DATA2 as IGNORED_ENTITY
		FROM RTO_WORK
		WHERE WORK_ID = p_WORK_ID
		ORDER BY 1,2;
END GET_WARNING_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE COPY_DATA_LOCK_GROUP
(
	p_ENTITY_ID IN NUMBER,
	p_NEW_ENTITY_ID OUT NUMBER,
	p_NEW_ENTITY_NAME OUT VARCHAR2
) AS

v_ITEM_ID NUMBER(9);

CURSOR cur_GROUP_ITEMS IS
	SELECT ITM.*
	FROM DATA_LOCK_GROUP_ITEM ITM
	WHERE ITM.DATA_LOCK_GROUP_ID = p_ENTITY_ID;
	
v_GROUP_ITEM cur_GROUP_ITEMS%ROWTYPE;

BEGIN

	ENTITY_UTIL.COPY_ENTITY(p_ENTITY_ID, 
							'DATA_LOCK_GROUP',
							p_NEW_ENTITY_ID, 
							p_NEW_ENTITY_NAME);
	
	FOR v_GROUP_ITEM IN cur_GROUP_ITEMS LOOP
	
		SELECT OID.NEXTVAL
		INTO v_ITEM_ID
		FROM DUAL;
		
		INSERT INTO DATA_LOCK_GROUP_ITEM ( DATA_LOCK_GROUP_ITEM_ID, DATA_LOCK_GROUP_ID,
			TABLE_ID, ENTITY_DOMAIN_ID, ENTITY_TYPE, ENTITY_ID)
		VALUES( v_ITEM_ID, p_NEW_ENTITY_ID, v_GROUP_ITEM.TABLE_ID, v_GROUP_ITEM.ENTITY_DOMAIN_ID,
			v_GROUP_ITEM.ENTITY_TYPE, v_GROUP_ITEM.ENTITY_ID);
		
		INSERT INTO DATA_LOCK_GROUP_ITEM_CRITERIA (DATA_LOCK_GROUP_ITEM_ID, COLUMN_NAME, COLUMN_VALUE)
		SELECT v_ITEM_ID, COLUMN_NAME, COLUMN_VALUE
		FROM DATA_LOCK_GROUP_ITEM_CRITERIA
		WHERE DATA_LOCK_GROUP_ITEM_ID = v_GROUP_ITEM.DATA_LOCK_GROUP_ITEM_ID;
		
	END LOOP;
							
	 

END COPY_DATA_LOCK_GROUP;
----------------------------------------------------------------------------------------------------
END DATA_LOCK_UI;
/
