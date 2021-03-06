CREATE OR REPLACE PACKAGE GUI_UTIL IS
--Revision $Revision: 1.6 $

  -- AUTHOR  : JHUMPHRIES
  -- CREATED : 9/15/2008 2:46:14 PM
  -- PURPOSE : Helper methods invoked from Mighty Framework UI. Many of these pass through
  --			to other utility packages or other APIs that are not directly invokable by UI due to
  -- 			security concerns

FUNCTION WHAT_VERSION RETURN VARCHAR;

-- Return the DB_TABLE_NAME for a System Table.
FUNCTION DB_TABLE_NAME_FOR_TABLE
	(
	p_TABLE_ID IN NUMBER
	) RETURN VARCHAR2;

-- Purge a workset
PROCEDURE PURGE_RTO_WORK
	(
	p_WORK_ID IN NUMBER
	);

-- Get a cursor with N number of empty rows specified by p_ROW_NUMBER.
-- This procedure can be useful when building false levels in Mighty Trees.
PROCEDURE EMPTY_ROWS
	(
	p_ROW_NUMBER IN NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

FUNCTION IS_ENTITY_NUMEROUS
	(
	p_ENTITY_TYPE IN VARCHAR2
	) RETURN NUMBER;

PROCEDURE ENTITY_LIST
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SEARCH_STRING IN VARCHAR,
	p_SEARCH_OPTION IN VARCHAR,
	p_SEARCH_TYPE	IN NUMBER,
	p_FIND_VALUE 	IN VARCHAR2,
	p_INCLUDE_INACTIVE IN NUMBER,
	p_HIDE_NOT_ASSIGNED IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_TARGET_ENTITY_JUMP_ACTION
	(
	p_ENTITY_TYPE IN VARCHAR2,
	p_PARENT_REPORT_ID IN NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE COPY_ENTITY
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_REPORT_ID IN NUMBER,
	p_NEW_ENTITY_ID OUT NUMBER,
	p_NEW_ENTITY_NAME OUT VARCHAR2,
	p_MESSAGE OUT VARCHAR2
	);

PROCEDURE DELETE_ENTITY
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_REPORT_ID IN NUMBER
	);

PROCEDURE ENTITY_TREE_LIST
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SEARCH_STRING IN VARCHAR,
	p_SEARCH_OPTION IN VARCHAR,
	p_SEARCH_TYPE	IN NUMBER,
	p_FIND_ENTITY_ID IN NUMBER,
	p_INCLUDE_INACTIVE IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

FUNCTION GET_ENTITY_TYPE
	(
	p_DOMAIN_ID IN NUMBER
	)RETURN VARCHAR2;

PROCEDURE GET_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_EXTERNAL_IDENTIFIER OUT VARCHAR2
	);

PROCEDURE ENTITY_DOMAINS_FROM_LIST
	(
	p_ENTITY_TYPES IN VARCHAR2,
	p_INCLUDE_ALL IN NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

FUNCTION IS_EXTERNAL_SYSTEM_ENABLED
	(
		p_EXTERNAL_SYSTEM_ID IN NUMBER
	) RETURN NUMBER;

FUNCTION IS_SCHED_MGMT_ENABLED
	RETURN NUMBER;

PROCEDURE SEARCH_ENTITY_LIST
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SEARCH_STRING IN VARCHAR,
	p_SEARCH_OPTION IN VARCHAR,
	p_SEARCH_TYPE	IN NUMBER,
	p_FIND_VALUE 	IN VARCHAR2,
	p_INCLUDE_INACTIVE IN NUMBER,
	p_HIDE_NOT_ASSIGNED IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	);

FUNCTION FIX_SEARCH_STRING(p_SEARCH_STRING IN VARCHAR2) RETURN VARCHAR2;

PROCEDURE GET_ENTITY_ID
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID OUT NUMBER
	);

END GUI_UTIL;
/
CREATE OR REPLACE PACKAGE BODY GUI_UTIL IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
	RETURN '$Revision: 1.6 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
FUNCTION DB_TABLE_NAME_FOR_TABLE
	(
	p_TABLE_ID IN NUMBER
	) RETURN VARCHAR2 AS
BEGIN
	RETURN ENTITY_UTIL.DB_TABLE_NAME_FOR_TABLE(p_TABLE_ID);
END DB_TABLE_NAME_FOR_TABLE;
----------------------------------------------------------------------------------------------------
-- Purge a workset
PROCEDURE PURGE_RTO_WORK
	(
	p_WORK_ID IN NUMBER
	) AS
BEGIN
	UT.PURGE_RTO_WORK(p_WORK_ID);
END PURGE_RTO_WORK;
----------------------------------------------------------------------------------------------------
-- Get a cursor with N number of empty rows specified by p_ROW_NUMBER.
-- This procedure can be useful when building complex Mighty Trees.
PROCEDURE EMPTY_ROWS
	(
	p_ROW_NUMBER IN NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS
BEGIN
	OPEN p_CURSOR FOR
		SELECT LEVEL AS ROW_NBR FROM DUAL CONNECT BY LEVEL <= p_ROW_NUMBER;
END EMPTY_ROWS;
----------------------------------------------------------------------------------------------------
FUNCTION IS_ENTITY_NUMEROUS
	(
	p_ENTITY_TYPE IN VARCHAR2
	) RETURN NUMBER AS
BEGIN
	RETURN NVL(GET_DICTIONARY_VALUE(p_ENTITY_TYPE,0,'Entity Manager','Show Find in Tree'), 0);
END IS_ENTITY_NUMEROUS;
----------------------------------------------------------------------------------------------------
PROCEDURE ENTITY_LIST
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SEARCH_STRING IN VARCHAR,
	p_SEARCH_OPTION IN VARCHAR,
	p_SEARCH_TYPE	IN NUMBER,
	p_FIND_VALUE 	IN VARCHAR2,
	p_INCLUDE_INACTIVE IN NUMBER,
	p_HIDE_NOT_ASSIGNED IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

	v_TYPE VARCHAR2(64);

BEGIN

	IF p_ENTITY_DOMAIN_ID IS NULL THEN

		OPEN p_CURSOR
		FOR SELECT NULL "ENTITY_DOMAIN_ID",
				NULL "ENTITY_ID",
				NULL "ENTITY_ALIAS"
		FROM DUAL;

	ELSE

		v_TYPE := ENTITY_UTIL.GET_ENTITY_TYPE(p_ENTITY_DOMAIN_ID);

		EXECUTE IMMEDIATE 'BEGIN ENTITY_LIST.' || v_TYPE
			|| '(:str, :opt, :type, :val, :inactive, :notassigned, :stat, :cur); END;'
			USING IN p_SEARCH_STRING, IN p_SEARCH_OPTION, IN NVL(p_SEARCH_TYPE, CONSTANTS.SEARCH_TYPE_NORMAL), IN p_FIND_VALUE,
				IN p_INCLUDE_INACTIVE, IN p_HIDE_NOT_ASSIGNED, OUT p_STATUS, OUT p_CURSOR;

	END IF;

END ENTITY_LIST;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_TARGET_ENTITY_JUMP_ACTION
	(
	p_ENTITY_TYPE IN VARCHAR2,
	p_PARENT_REPORT_ID IN NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

	v_WORK_ID NUMBER(9);

	v_TARGET_IO_TBL NUMBER(9);
	v_PARENT_REPORT_ID NUMBER(9);
	v_ACTION_ID NUMBER(9);

BEGIN

	v_WORK_ID := SO.ENUMERATE_HIERARCHY(0, SO.g_UNLIMITED_DEPTH, FALSE, FALSE, FALSE,
		p_INCLUDED_CATEGORIES => STRING_COLLECTION('IO Table', 'Report', 'System View', 'Module'));

	SELECT MAX(OBJECT_ID) INTO v_TARGET_IO_TBL
	FROM (SELECT SO.OBJECT_ID,
			CASE WHEN PARENT_OBJECT_ID = p_PARENT_REPORT_ID THEN 1 -- GIVE PREFERENCE TO THE
				ELSE 0 END SAME_REPORT							-- IO TABLE IN THE SAME REPORT
		FROM SYSTEM_OBJECT SO, RTO_WORK W
		WHERE SO.OBJECT_ID = W.WORK_XID
			AND W.WORK_ID = v_WORK_ID
			AND SO.OBJECT_CATEGORY = 'IO Table'
			AND UPPER(SO.OBJECT_NAME) = UPPER(p_ENTITY_TYPE)
		ORDER BY SAME_REPORT DESC, SO.OBJECT_ORDER ASC, SO.OBJECT_ID ASC)
	WHERE ROWNUM = 1;

	IF v_TARGET_IO_TBL IS NOT NULL THEN -- FOUND THE IO TABLE
		SELECT SO.PARENT_OBJECT_ID INTO v_PARENT_REPORT_ID
		FROM SYSTEM_OBJECT SO
		WHERE OBJECT_ID = v_TARGET_IO_TBL;

		-- FIRST LOOK FOR JUMP HERE TO BE A CHILD OF THE IO TABLE
		SO.ID_FOR_SYSTEM_OBJECT(v_TARGET_IO_TBL, CONSTANTS.JUMP_HERE_ACTION_NAME, 0,
			CONSTANTS.SO_ACTION_CATEOGRY, 'Default', FALSE, v_ACTION_ID);

		-- THEN LOOK FOR IT TO BE A CHILD OF THE REPORT
		IF NVL(v_ACTION_ID, GA.NO_DATA_FOUND) = GA.NO_DATA_FOUND THEN
			SO.ID_FOR_SYSTEM_OBJECT(v_PARENT_REPORT_ID, CONSTANTS.JUMP_HERE_ACTION_NAME, 0,
				CONSTANTS.SO_ACTION_CATEOGRY, 'Default', FALSE, v_ACTION_ID);
		END IF;

		-- STILL NULL?  WE CAN'T FIND THE JUMP HERE ACTION
		IF NVL(v_ACTION_ID, GA.NO_DATA_FOUND) = GA.NO_DATA_FOUND THEN
			ERRS.RAISE(MSGCODES.c_ERR_JUMP_ACTION);
		END IF;

		SO.GET_SO_HIERARCHY(v_ACTION_ID, 1, SO.g_UNLIMITED_DEPTH,
							CONSTANTS.SO_ACTION_CATEOGRY, p_CURSOR);
	ELSE
		-- CAN'T FIND THE TARGET IO TABLE
		ERRS.RAISE(MSGCODES.c_ERR_TARGET_IO_TABLE);
	END IF;

	UT.PURGE_RTO_WORK(v_WORK_ID);

END GET_TARGET_ENTITY_JUMP_ACTION;
----------------------------------------------------------------------------------------------------
PROCEDURE COPY_ENTITY
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_REPORT_ID IN NUMBER,
	p_NEW_ENTITY_ID OUT NUMBER,
	p_NEW_ENTITY_NAME OUT VARCHAR2,
	p_MESSAGE OUT VARCHAR2
	) AS

	v_COPY_PROC VARCHAR2(256);

	v_PARAMS STORED_PROC_PARAMETER_TABLE;

	v_IO_TABLE_ID NUMBER(9);

BEGIN

	SO.ID_FOR_SYSTEM_OBJECT(p_REPORT_ID, UPPER(p_ENTITY_TYPE), 0,
		CONSTANTS.SO_IO_TBL_CATEGORY, 'Default', FALSE, v_IO_TABLE_ID);

	v_IO_TABLE_ID := SO.RESOLVE_OBJECT_ID(v_IO_TABLE_ID);

	BEGIN
		SELECT COPY_PROC.ATTRIBUTE_VAL INTO v_COPY_PROC
		FROM SYSTEM_OBJECT SO,
			SYSTEM_OBJECT_ATTRIBUTE COPY_PROC
		WHERE SO.OBJECT_ID = v_IO_TABLE_ID
			AND COPY_PROC.OBJECT_ID = SO.OBJECT_ID
			AND COPY_PROC.ATTRIBUTE_ID = 209;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_COPY_PROC := NULL;
	END;

	IF v_COPY_PROC IS NOT NULL THEN
		UT.GET_STORED_PROC_PARAMETERS(v_COPY_PROC, 0 , v_PARAMS);
		IF (v_PARAMS.COUNT = 3) THEN
			EXECUTE IMMEDIATE 'BEGIN ' || v_COPY_PROC || '(:ID, :NEW_ID, :NEW_NAME); END;'
			USING IN p_ENTITY_ID, OUT p_NEW_ENTITY_ID, OUT p_NEW_ENTITY_NAME;
		ELSE
			EXECUTE IMMEDIATE 'BEGIN ' || v_COPY_PROC || '(:ID, :NEW_ID, :NEW_NAME, :MESSAGE); END;'
			USING IN p_ENTITY_ID, OUT p_NEW_ENTITY_ID, OUT p_NEW_ENTITY_NAME, OUT p_MESSAGE;
		END IF;
	ELSE
		ENTITY_UTIL.COPY_ENTITY(p_ENTITY_ID, p_ENTITY_TYPE,
			p_NEW_ENTITY_ID, p_NEW_ENTITY_NAME);
	END IF;

END COPY_ENTITY;
----------------------------------------------------------------------------------------------------
PROCEDURE DELETE_ENTITY
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_REPORT_ID IN NUMBER
	) AS

	v_DELETE_PROC VARCHAR2(256);

	v_IO_TABLE_ID NUMBER(9);
	v_STATUS NUMBER(9);

BEGIN

	SO.ID_FOR_SYSTEM_OBJECT(p_REPORT_ID, UPPER(p_ENTITY_TYPE), 0,
		CONSTANTS.SO_IO_TBL_CATEGORY, 'Default', FALSE, v_IO_TABLE_ID);

	v_IO_TABLE_ID := SO.RESOLVE_OBJECT_ID(v_IO_TABLE_ID);

	BEGIN
		SELECT DELETE_PROC.ATTRIBUTE_VAL INTO v_DELETE_PROC
		FROM SYSTEM_OBJECT SO,
			SYSTEM_OBJECT_ATTRIBUTE DELETE_PROC
		WHERE SO.OBJECT_ID = v_IO_TABLE_ID
			AND DELETE_PROC.OBJECT_ID = SO.OBJECT_ID
			AND DELETE_PROC.ATTRIBUTE_ID = 203;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_DELETE_PROC := NULL;
	END;

	IF v_DELETE_PROC IS NOT NULL THEN
		IF SUBSTR(v_DELETE_PROC, 1, 6) = 'DE.DEL' THEN
			-- REDIRECTING TO A DE PROCEDURE USING A DIFFERENT TYPE
			EXECUTE IMMEDIATE 'BEGIN ' || v_DELETE_PROC || '(:ID, :STATUS); END;'
			USING IN p_ENTITY_ID, OUT v_STATUS;

			ERRS.VALIDATE_STATUS(v_DELETE_PROC, v_STATUS);
		ELSE

			EXECUTE IMMEDIATE 'BEGIN ' || v_DELETE_PROC || '(:ID); END;'
			USING IN p_ENTITY_ID;
		END IF;
	ELSE
		EXECUTE IMMEDIATE 'BEGIN DE.DEL_' || p_ENTITY_TYPE || '(:ID, :STATUS); END;'
		USING IN p_ENTITY_ID, OUT v_STATUS;

		ERRS.VALIDATE_STATUS('DE.DEL_' || p_ENTITY_TYPE, v_STATUS);
	END IF;

END DELETE_ENTITY;
----------------------------------------------------------------------------------------------------
-- THIS IS JUST A WRAPPER TO ENTITY_LIST, BUT WE NEED FIND_ENTITY_ID
-- TO DO REVERSE LOOKUP IN THE TREE
PROCEDURE ENTITY_TREE_LIST
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SEARCH_STRING IN VARCHAR,
	p_SEARCH_OPTION IN VARCHAR,
	p_SEARCH_TYPE	IN NUMBER,
	p_FIND_ENTITY_ID IN NUMBER,
	p_INCLUDE_INACTIVE IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	) AS

BEGIN
		ENTITY_LIST(p_ENTITY_DOMAIN_ID, p_SEARCH_STRING, p_SEARCH_OPTION, p_SEARCH_TYPE,
			TO_CHAR(p_FIND_ENTITY_ID), p_INCLUDE_INACTIVE, 0, p_STATUS, p_CURSOR);

END ENTITY_TREE_LIST;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_TYPE
	(
	p_DOMAIN_ID IN NUMBER
	)RETURN VARCHAR2 IS

BEGIN

	RETURN ENTITY_UTIL.GET_ENTITY_TYPE(p_DOMAIN_ID);

END GET_ENTITY_TYPE;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_EXTERNAL_IDENTIFIER OUT VARCHAR2
	) AS

BEGIN

	p_EXTERNAL_IDENTIFIER := EI.GET_ENTITY_IDENTIFIER(p_ENTITY_DOMAIN_ID, p_ENTITY_ID);

END GET_ENTITY_IDENTIFIER;
----------------------------------------------------------------------------------------------------
PROCEDURE ENTITY_DOMAINS_FROM_LIST
      (
      p_ENTITY_TYPES IN VARCHAR2,
      p_INCLUDE_ALL IN NUMBER,
      p_CURSOR OUT GA.REFCURSOR
      ) AS

v_STRING_COLL  STRING_COLLECTION;

BEGIN

      UT.STRING_COLLECTION_FROM_STRING(p_ENTITY_TYPES, '|', v_STRING_COLL);

      OPEN p_CURSOR FOR
            SELECT CONSTANTS.ALL_STRING "ENTITY_DOMAIN_NAME", CONSTANTS.ALL_ID "ENTITY_DOMAIN_ID" FROM DUAL WHERE p_INCLUDE_ALL = 1
            UNION ALL
            SELECT NVL(ED.ENTITY_DOMAIN_ALIAS,ED.ENTITY_DOMAIN_NAME) "ENTITY_DOMAIN_NAME",ED.ENTITY_DOMAIN_ID "ENTITY_DOMAIN_ID"
            FROM ENTITY_DOMAIN ED, TABLE(CAST(v_STRING_COLL AS STRING_COLLECTION)) ENTITY_TYPES
            WHERE ED.ENTITY_DOMAIN_TABLE_ALIAS = UPPER(ENTITY_TYPES.COLUMN_VALUE);


END ENTITY_DOMAINS_FROM_LIST;
----------------------------------------------------------------------------------------------------
FUNCTION IS_EXTERNAL_SYSTEM_ENABLED
	(
		p_EXTERNAL_SYSTEM_ID IN NUMBER
	) RETURN NUMBER
AS
	v_IS_ENABLED NUMBER;
BEGIN
	SELECT S.IS_ENABLED
	INTO v_IS_ENABLED
	FROM EXTERNAL_SYSTEM S
	WHERE S.EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;

	RETURN v_IS_ENABLED;
END IS_EXTERNAL_SYSTEM_ENABLED;
----------------------------------------------------------------------------------------------------
FUNCTION IS_SCHED_MGMT_ENABLED
	RETURN NUMBER
AS
	v_IS_ENABLED NUMBER;
BEGIN
	SELECT MAX(S.IS_ENABLED)
	INTO v_IS_ENABLED
	FROM EXTERNAL_SYSTEM S
	WHERE S.EXTERNAL_SYSTEM_ID = EC.ES_SCHEDULE_MANAGEMENT;

	RETURN NVL(v_IS_ENABLED, 0);
END IS_SCHED_MGMT_ENABLED;
----------------------------------------------------------------------------------------------------
PROCEDURE SEARCH_ENTITY_LIST
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SEARCH_STRING IN VARCHAR,
	p_SEARCH_OPTION IN VARCHAR,
	p_SEARCH_TYPE	IN NUMBER,
	p_FIND_VALUE 	IN VARCHAR2,
	p_INCLUDE_INACTIVE IN NUMBER,
	p_HIDE_NOT_ASSIGNED IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR,
	p_MESSAGE OUT VARCHAR2
	) AS

BEGIN

	IF p_ENTITY_DOMAIN_ID IS NULL THEN
		p_MESSAGE := 'Please select an entity domain before opening the find dialog.';

		OPEN p_CURSOR FOR
		SELECT NULL
		FROM DUAL;
	ELSE
		ENTITY_LIST(p_ENTITY_DOMAIN_ID,
					p_SEARCH_STRING,
					p_SEARCH_OPTION,
					p_SEARCH_TYPE,
					p_FIND_VALUE,
					p_INCLUDE_INACTIVE,
					p_HIDE_NOT_ASSIGNED,
					p_STATUS,
					p_CURSOR);
	END IF;

END SEARCH_ENTITY_LIST;
----------------------------------------------------------------------------------------------------
FUNCTION FIX_SEARCH_STRING(p_SEARCH_STRING IN VARCHAR2) RETURN VARCHAR2 AS
BEGIN
	IF INSTR(p_SEARCH_STRING,'%') >= 1 OR INSTR(p_SEARCH_STRING,'_') >= 1 THEN
		RETURN p_SEARCH_STRING;
	ELSE
		RETURN '%'||p_SEARCH_STRING||'%';
	END IF;
END FIX_SEARCH_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_ID
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_TYPE IN VARCHAR2,
	p_ENTITY_ID OUT NUMBER
	) AS
	
	v_ENTITY_DOMAIN_ID NUMBER(9) := ENTITY_UTIL.GET_DOMAIN_ID_FOR_TYPE(p_ENTITY_TYPE);
	
BEGIN

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_SELECT_ENT, p_ENTITY_ID, v_ENTITY_DOMAIN_ID);
	
	p_ENTITY_ID := EI.GET_ID_FROM_NAME(p_ENTITY_NAME, v_ENTITY_DOMAIN_ID);
	
END GET_ENTITY_ID;
----------------------------------------------------------------------------------------------------
END GUI_UTIL;
/
