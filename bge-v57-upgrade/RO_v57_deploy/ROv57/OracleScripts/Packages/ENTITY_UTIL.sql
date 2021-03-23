CREATE OR REPLACE PACKAGE ENTITY_UTIL IS
--Revision $Revision: 1.8 $

  -- AUTHOR  : JHUMPHRIES
  -- CREATED : 9/15/2008 2:19:40 PM
  -- PURPOSE : Utility procedures/functions for dealing with Entities

FUNCTION WHAT_VERSION RETURN VARCHAR;

TYPE ENTITY_DOMAIN_INFO IS RECORD (
	ENTITY_DOMAIN_ID	ENTITY_DOMAIN.ENTITY_DOMAIN_ID%TYPE,
	ENTITY_DOMAIN_TABLE_NAME ENTITY_DOMAIN.ENTITY_DOMAIN_TABLE%TYPE,
	ENTITY_DOMAIN_TABLE_ALIAS ENTITY_DOMAIN.ENTITY_DOMAIN_ALIAS%TYPE,
	ENTITY_DOMAIN_TABLE_PREFIX NERO_TABLE_PROPERTY_INDEX.PRIMARY_ID_COLUMN%TYPE
);

-- Action type constants
c_ACTION_TYPE_SELECT	CONSTANT NUMBER(1) := 1;
c_ACTION_TYPE_RUN		CONSTANT NUMBER(1) := 2;
c_ACTION_TYPE_PURGE		CONSTANT NUMBER(1) := 3;
c_ACTION_TYPE_LK_STATE	CONSTANT NUMBER(1) := 4;

-- Calc.Process default action names
-- these are used as defaults when the calculation process has a context domain
c_DEFAULT_VIEW_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Select Calculation Process for Entity';
c_DEFAULT_RUN_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Run Calculation Process for Entity';
c_DEFAULT_PURGE_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Purge Calculation Process for Entity';
c_DEFAULT_LK_STATE_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Update Calculation Process Lock State for Entity';
-- these are used as defaults when the calculation process context domain is 'Not Assigned'
c_DEFAULT_VIEW_NA_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Select Calculation Process';
c_DEFAULT_RUN_NA_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Run Calculation Process';
c_DEFAULT_PURGE_NA_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Purge Calculation Process';
c_DEFAULT_LK_ST_NA_ACTION_NAME CONSTANT SYSTEM_ACTION.ACTION_NAME%TYPE := 'Update Calculation Process Lock State';


-- Cursor to enumerate entities (IDs and names) in RTO_WORK
CURSOR g_cur_ENTITIES(p_WORK_ID IN NUMBER) IS
	SELECT WORK_XID as ENTITY_ID, WORK_DATA as ENTITY_NAME
	FROM RTO_WORK
	WHERE WORK_ID = p_WORK_ID;
-- Cursor to enumerate entities (IDs only) in RTO_WORK
CURSOR g_cur_ENTITY_IDs(p_WORK_ID IN NUMBER) IS
	SELECT WORK_XID as ENTITY_ID
	FROM RTO_WORK
	WHERE WORK_ID = p_WORK_ID;

-- Expand an entity reference that could point to a realm or group. Return
-- a WORK_ID that points to a workset wherein WORK_XID is the entity ID.
-- If p_ACTION_ID is not null then the workset will be filtered to only
-- include entities to which the current session has privileges for the
-- specified action.
-- Allowed values for p_ENTITY_TYPE follow:
-- 'E' - Indicates that p_ENTITY_ID is a single entity ID
-- 'G' - Indicates that p_ENTITY_ID is an Entity Group ID
-- 'R' - Indicates that p_ENTITY_ID is a System Realm ID
FUNCTION EXPAND_ENTITY
	(
	p_ENTITY_DOMAIN_ID 		IN NUMBER,
	p_ENTITY_TYPE 			IN VARCHAR2,
	p_ENTITY_ID 			IN NUMBER,
	p_ACTION_ID 			IN NUMBER := NULL,
	p_BEGIN_DATE			IN DATE := NULL,
	p_END_DATE				IN DATE := NULL,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) RETURN NUMBER;
FUNCTION EXPAND_ENTITY
	(
	p_ENTITY_DOMAIN_ID 		IN NUMBER,
	p_ENTITY_TYPE 			IN VARCHAR2,
	p_ENTITY_ID 			IN NUMBER,
	p_ACTION_NAME 			IN VARCHAR2,
	p_BEGIN_DATE			IN DATE := NULL,
	p_END_DATE				IN DATE := NULL,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) RETURN NUMBER;

-- Expand a set of meter or sub-station IDs into a set of constituent
-- meter data point IDs. The meter or sub-station IDs are specified by the
-- WORK_XID column of the workset indicated by p_WORK_ID. These entries
-- will be replaced by a workset that contains meter data point IDs in
-- WORK_XID (using the same WORK_ID). If p_ACTION_ID is not null then the
-- workset will be filtered to only include meter data points to which
-- the current session has privileges for the specified action.
PROCEDURE EXPAND_WORKSET_METER_POINTS
	(
	p_ENTITY_DOMAIN_ID	IN NUMBER,
	p_WORK_ID			IN NUMBER,
	p_ACTION_ID			IN NUMBER := NULL
	);

-- Return the DB_TABLE_NAME for a System Table.
FUNCTION DB_TABLE_NAME_FOR_TABLE
	(
	p_TABLE_ID IN NUMBER
	) RETURN VARCHAR2;

-- Gets the System Table ID for the specified database table name.
-- %param p_DB_TABLE_NAME	The name of the database table
-- %return The ID for the SYstem Table that corresponds to p_DB_TABLE_NAME
FUNCTION TABLE_ID_FOR_DB_TABLE
	(
	p_DB_TABLE_NAME IN VARCHAR2
	) RETURN NUMBER;

-- Return the ACTION_ID for the named System Action. Returns
-- NULL if no action by the specified name exists.
FUNCTION GET_ACTION_ID
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN NUMBER;

-- Return information about the specified calculation process.
-- The returned action ID will be one of the "select", "purge", "run",
-- or "update lock state" action associated with the process.
-- Which action ID is returned is determined by the value of
-- p_ACTION_TYPE specified. See c_ACTION_TYPE_* constants for
-- available values.
PROCEDURE GET_CALC_PROCESS_SECURITY_INFO
	(
	p_CALC_PROCESS_ID	IN NUMBER,
	p_ACTION_TYPE     	IN NUMBER,
	p_ACTION_ID			OUT NUMBER,
	p_CONTEXT_DOMAIN_ID	OUT NUMBER,
	p_CONTEXT_REALM_ID	OUT NUMBER,
	p_CONTEXT_GROUP_ID	OUT NUMBER
	);

	FUNCTION GET_REFERRED_DOMAIN_TABLE
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2;

FUNCTION GET_REFERRED_DOMAIN_TABLE
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN VARCHAR2;

FUNCTION GET_REFERRED_DOMAIN_ID
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN NUMBER;

FUNCTION GET_REFERRED_DOMAIN_ID
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN NUMBER;

FUNCTION GET_REFERRED_DOMAIN_INFO
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ENTITY_DOMAIN_INFO;

FUNCTION GET_REFERRED_DOMAIN_INFO
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN ENTITY_DOMAIN_INFO;

FUNCTION GET_DOMAIN_INFO
	(
	p_DOMAIN_ID IN NUMBER
	) RETURN ENTITY_DOMAIN_INFO;

FUNCTION GET_REFERRED_DOMAIN_ALIAS
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN VARCHAR2;

FUNCTION GET_REFERRED_DOMAIN_ALIAS
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2;

FUNCTION HAS_NOT_ASSIGNED
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN NUMBER;

FUNCTION HAS_NOT_ASSIGNED
	(
	p_DOMAIN_ID IN NUMBER
	) RETURN NUMBER;

FUNCTION GET_COPY_OF_ENTITY_NAME
	(
	p_ENTITY_NAME      VARCHAR2,
	p_ENTITY_DOMAIN_ID NUMBER
	) RETURN VARCHAR2;

PROCEDURE COPY_COMMON_SUBTABS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SOURCE_ENTITY_ID IN NUMBER,
	p_DEST_ENTITY_ID IN NUMBER
	);

PROCEDURE COPY_ENTITY_SUBTABS
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_NEW_ENTITY_ID IN NUMBER
	);

PROCEDURE COPY_ENTITY_TABLE
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_NEW_ENTITY_ID IN NUMBER,
	p_NEW_ENTITY_NAME IN VARCHAR2
	);

PROCEDURE COPY_ENTITY
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_NEW_ENTITY_ID OUT NUMBER,
	p_NEW_ENTITY_NAME OUT VARCHAR2
	);

FUNCTION GET_ENTITY_TYPE
	(
	p_DOMAIN_ID IN NUMBER
	)RETURN VARCHAR2;

FUNCTION GET_DOMAIN_ID_FOR_TYPE
	(
	p_ENTITY_TYPE IN VARCHAR2
	) RETURN VARCHAR2;

FUNCTION RESOLVE_ENTITY_NAME_CONFLICT
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2;

-- Deletes any Usage Factors after the End Date, and Terminates any
--    Usage Factors spanning the End Date.  This procedure currently works for
--    CUSTOMER, ACCOUNT, and METER domains, since they are the only ones with
--    Usage Factor tables.
PROCEDURE TERMINATE_USAGE_FACTOR
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_END_DATE IN DATE,
	p_CASE_ID IN NUMBER := GA.BASE_CASE_ID
	);

END ENTITY_UTIL;
/
CREATE OR REPLACE PACKAGE BODY ENTITY_UTIL IS
---------------------------------------------------------------------------------------------------
-- IDs for default actions for Calculation Process security
g_DEFAULT_CALC_ACTION_IDs	UT.STRING_MAP;
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
	RETURN '$Revision: 1.8 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_TABLE_DOMAIN_ID
	(
	p_TABLE_NAME IN VARCHAR2
	) RETURN NUMBER IS

	v_RET ENTITY_DOMAIN.ENTITY_DOMAIN_ID%TYPE := NULL;

BEGIN

	IF p_TABLE_NAME IS NOT NULL THEN
		SELECT MAX(ED.ENTITY_DOMAIN_ID) INTO v_RET
		FROM ENTITY_DOMAIN ED
		WHERE ED.ENTITY_DOMAIN_TABLE = p_TABLE_NAME;
	END IF;

	RETURN v_RET;

END GET_ENTITY_TABLE_DOMAIN_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_TABLE_NAME
	(
	p_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2 IS

	v_RET ENTITY_DOMAIN.ENTITY_DOMAIN_TABLE%TYPE;

BEGIN

	IF p_DOMAIN_ID IS NOT NULL THEN
		SELECT MAX(ED.ENTITY_DOMAIN_TABLE) INTO v_RET
		FROM ENTITY_DOMAIN ED
		WHERE ED.ENTITY_DOMAIN_ID = p_DOMAIN_ID;
	END IF;

	RETURN v_RET;

END GET_ENTITY_TABLE_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION EXPAND_ENTITY
	(
	p_ENTITY_DOMAIN_ID 		IN NUMBER,
	p_ENTITY_TYPE 			IN VARCHAR2,
	p_ENTITY_ID 			IN NUMBER,
	p_ACTION_ID 			IN NUMBER := NULL,
	p_BEGIN_DATE			IN DATE := NULL,
	p_END_DATE				IN DATE := NULL,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) RETURN NUMBER IS
v_WORK_ID	RTO_WORK.WORK_ID%TYPE;
BEGIN
	IF p_ENTITY_TYPE = 'G' THEN
		-- get all group members
		IF p_ACTION_ID IS NULL THEN
			SD.ENUMERATE_ENTITY_GROUP_MEMBERS(p_ENTITY_ID, TRUNC(p_BEGIN_DATE-1/86400), TRUNC(p_END_DATE-1/86400), v_WORK_ID, p_IGNORE_GROUP_PRIVS, TRUE);
		ELSE
			-- intersect group with allowed entities per specified action ID
			SD.ENUMERATE_ENTITIES(p_ACTION_ID, p_ENTITY_DOMAIN_ID, v_WORK_ID, NULL, p_ENTITY_ID, TRUNC(p_BEGIN_DATE-1/86400), TRUNC(p_END_DATE-1/86400), p_IGNORE_GROUP_PRIVS);
		END IF;
	ELSIF p_ENTITY_TYPE = 'R' THEN
		-- get all realm members
		IF p_ENTITY_ID = SD.g_ALL_DATA_REALM_ID OR p_ACTION_ID IS NOT NULL THEN
			-- find intersection of specified realm with allowed entities per specified action ID
			SD.ENUMERATE_ENTITIES(p_ACTION_ID, p_ENTITY_DOMAIN_ID, v_WORK_ID, p_ENTITY_ID);
		ELSE
			SD.ENUMERATE_SYSTEM_REALM_MEMBERS(p_ENTITY_ID, v_WORK_ID);
		END IF;
	ELSE -- p_ENTITY_TYPE = 'E'
		UT.GET_RTO_WORK_ID(v_WORK_ID);
		-- if action ID specified, only allow this entry if it user has correct privileges
		IF p_ACTION_ID IS NULL OR SD.GET_ENTITY_IS_ALLOWED(p_ACTION_ID, p_ENTITY_ID, p_ENTITY_DOMAIN_ID) THEN
			-- just one entity so record single work entry with the ID
			INSERT INTO RTO_WORK (WORK_ID, WORK_XID) VALUES (v_WORK_ID, p_ENTITY_ID);
		END IF;
	END IF;

	RETURN v_WORK_ID;
END EXPAND_ENTITY;
----------------------------------------------------------------------------------------------------
FUNCTION EXPAND_ENTITY
	(
	p_ENTITY_DOMAIN_ID 		IN NUMBER,
	p_ENTITY_TYPE 			IN VARCHAR2,
	p_ENTITY_ID 			IN NUMBER,
	p_ACTION_NAME 			IN VARCHAR2,
	p_BEGIN_DATE			IN DATE := NULL,
	p_END_DATE				IN DATE := NULL,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) RETURN NUMBER IS
BEGIN
	RETURN EXPAND_ENTITY(p_ENTITY_DOMAIN_ID, p_ENTITY_TYPE, p_ENTITY_ID, GET_ACTION_ID(p_ACTION_NAME),
							p_BEGIN_DATE, p_END_DATE, p_IGNORE_GROUP_PRIVS);
END EXPAND_ENTITY;
----------------------------------------------------------------------------------------------------
PROCEDURE EXPAND_WORKSET_METER_POINTS
	(
	p_ENTITY_DOMAIN_ID	IN NUMBER,
	p_WORK_ID			IN NUMBER,
	p_ACTION_ID			IN NUMBER := NULL
	) AS
v_ALLOWED_IDs	ID_TABLE;
BEGIN
	IF p_ENTITY_DOMAIN_ID NOT IN (EC.ED_SUB_STATION, EC.ED_SUB_STATION_METER) THEN
		ERRS.RAISE_BAD_ARGUMENT('Entity Domain',
								TEXT_UTIL.TO_CHAR_ENTITY(p_ENTITY_DOMAIN_ID, EC.ED_ENTITY_DOMAIN),
								'Meter points can only be expanded from a set of sub-stations or sub-station meters'
								);
	END IF;

	-- determine allowed meter point IDs
	IF p_ACTION_ID IS NULL THEN
		v_ALLOWED_IDs := ID_TABLE();
		v_ALLOWED_IDs.EXTEND();
		v_ALLOWED_IDs(v_ALLOWED_IDs.LAST) := ID_TYPE(SD.g_ALL_DATA_ENTITY_ID);
	ELSE
		v_ALLOWED_IDs := SD.GET_ALLOWED_ENTITY_ID_TABLE(p_ACTION_ID, EC.ED_SUB_STATION_METER_POINT);
	END IF;

	-- mark current entries
	UPDATE RTO_WORK SET WORK_SEQ = 1 WHERE WORK_ID = p_WORK_ID;
	-- enumerate meter points
	IF p_ENTITY_DOMAIN_ID = EC.ED_SUB_STATION THEN
		INSERT INTO RTO_WORK (WORK_ID, WORK_SEQ, WORK_XID)
		SELECT p_WORK_ID, 2, P.METER_POINT_ID
		FROM RTO_WORK W, TX_SUB_STATION_METER_POINT P, TX_SUB_STATION_METER M,
			TABLE(CAST(v_ALLOWED_IDs as ID_TABLE)) IDs
		WHERE W.WORK_ID = p_WORK_ID
			AND W.WORK_SEQ = 1
			AND M.SUB_STATION_ID = W.WORK_XID
			AND P.SUB_STATION_METER_ID = M.METER_ID
			AND IDs.ID IN (P.METER_POINT_ID, SD.g_ALL_DATA_ENTITY_ID);
	ELSE -- p_ITEM.ENTITY_DOMAIN_ID = EC.ED_SUB_STATION_METER
		INSERT INTO RTO_WORK (WORK_ID, WORK_SEQ, WORK_XID)
		SELECT p_WORK_ID, 2, P.METER_POINT_ID
		FROM RTO_WORK W, TX_SUB_STATION_METER_POINT P,
			TABLE(CAST(v_ALLOWED_IDs as ID_TABLE)) IDs
		WHERE W.WORK_ID = p_WORK_ID
			AND W.WORK_SEQ = 1
			AND P.SUB_STATION_METER_ID = W.WORK_XID
			AND IDs.ID IN (P.METER_POINT_ID, SD.g_ALL_DATA_ENTITY_ID);
	END IF;
	-- remove old entries
	DELETE RTO_WORK WHERE WORK_ID = p_WORK_ID AND WORK_SEQ = 1;

END EXPAND_WORKSET_METER_POINTS;
----------------------------------------------------------------------------------------------------
-- Return the DB_TABLE_NAME for a System Table.
FUNCTION DB_TABLE_NAME_FOR_TABLE
	(
	p_TABLE_ID IN NUMBER
	) RETURN VARCHAR2 AS
v_RET	SYSTEM_TABLE.DB_TABLE_NAME%TYPE;
BEGIN
	SELECT DB_TABLE_NAME INTO v_RET FROM SYSTEM_TABLE WHERE TABLE_ID = p_TABLE_ID;
	RETURN v_RET;
END DB_TABLE_NAME_FOR_TABLE;
---------------------------------------------------------------------------------------------------
-- Return the SYSTEM_TABLE.TABLE_ID for the specified database table name
FUNCTION TABLE_ID_FOR_DB_TABLE
	(
	p_DB_TABLE_NAME IN VARCHAR2
	) RETURN NUMBER IS
v_TABLE_ID	SYSTEM_TABLE.TABLE_ID%TYPE;
BEGIN
	SELECT TABLE_ID
	INTO v_TABLE_ID
	FROM SYSTEM_TABLE
	WHERE DB_TABLE_NAME = p_DB_TABLE_NAME;

	RETURN v_TABLE_ID;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'System Table for '||p_DB_TABLE_NAME, TRUE);
END TABLE_ID_FOR_DB_TABLE;
----------------------------------------------------------------------------------
FUNCTION GET_ACTION_ID
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN NUMBER IS
v_RET SYSTEM_ACTION.ACTION_ID%TYPE;
BEGIN
	-- MAX will return NULL if no such action exists
	SELECT MAX(ACTION_ID) INTO v_RET
	FROM SYSTEM_ACTION
	WHERE ACTION_NAME = p_ACTION_NAME;

	RETURN v_RET;
END GET_ACTION_ID;
---------------------------------------------------------------------------------------------------
FUNCTION GET_DEFAULT_ACTION_ID
	(
	p_ACTION_TYPE IN NUMBER,
	p_DOMAIN_NA IN BOOLEAN
	) RETURN NUMBER IS
v_ACTION_NAME SYSTEM_ACTION.ACTION_NAME%TYPE;
BEGIN
	IF p_DOMAIN_NA THEN
		v_ACTION_NAME := CASE p_ACTION_TYPE WHEN c_ACTION_TYPE_RUN THEN c_DEFAULT_RUN_NA_ACTION_NAME
											WHEN c_ACTION_TYPE_PURGE THEN c_DEFAULT_PURGE_NA_ACTION_NAME
											WHEN c_ACTION_TYPE_LK_STATE THEN c_DEFAULT_LK_ST_NA_ACTION_NAME
											ELSE /* c_ACTION_TYPE_SELECT */ c_DEFAULT_VIEW_NA_ACTION_NAME
											END;
	ELSE
		v_ACTION_NAME := CASE p_ACTION_TYPE WHEN c_ACTION_TYPE_RUN THEN c_DEFAULT_RUN_ACTION_NAME
											WHEN c_ACTION_TYPE_PURGE THEN c_DEFAULT_PURGE_ACTION_NAME
											WHEN c_ACTION_TYPE_LK_STATE THEN c_DEFAULT_LK_STATE_ACTION_NAME
											ELSE /* c_ACTION_TYPE_SELECT */ c_DEFAULT_VIEW_ACTION_NAME
											END;
	END IF;

	IF NOT g_DEFAULT_CALC_ACTION_IDs.EXISTS(v_ACTION_NAME) THEN
		g_DEFAULT_CALC_ACTION_IDs(v_ACTION_NAME) := EI.GET_ID_FROM_NAME(v_ACTION_NAME, EC.ED_SYSTEM_ACTION);
	END IF;

	RETURN g_DEFAULT_CALC_ACTION_IDs(v_ACTION_NAME);

END GET_DEFAULT_ACTION_ID;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_CALC_PROCESS_SECURITY_INFO
	(
	p_CALC_PROCESS_ID	IN NUMBER,
	p_ACTION_TYPE     	IN NUMBER,
	p_ACTION_ID			OUT NUMBER,
	p_CONTEXT_DOMAIN_ID	OUT NUMBER,
	p_CONTEXT_REALM_ID	OUT NUMBER,
	p_CONTEXT_GROUP_ID	OUT NUMBER
	) AS
BEGIN
	-- get the appropriate system action
	SELECT CASE p_ACTION_TYPE WHEN c_ACTION_TYPE_RUN THEN CPS.RUN_ACTION_ID
							  WHEN c_ACTION_TYPE_PURGE THEN CPS.PURGE_ACTION_ID
							  WHEN c_ACTION_TYPE_LK_STATE THEN CPS.LOCK_STATE_ACTION_ID
							  ELSE /* c_ACTION_TYPE_SELECT */ CPS.SELECT_ACTION_ID
							  END,
			CP.CONTEXT_DOMAIN_ID,
			CP.CONTEXT_REALM_ID,
			CP.CONTEXT_GROUP_ID
	INTO p_ACTION_ID, p_CONTEXT_DOMAIN_ID, p_CONTEXT_REALM_ID, p_CONTEXT_GROUP_ID
	FROM CALCULATION_PROCESS CP, CALCULATION_PROCESS_SECURITY CPS
	WHERE CP.CALC_PROCESS_ID = p_CALC_PROCESS_ID
		AND CPS.CALC_PROCESS_ID(+) = CP.CALC_PROCESS_ID;

	IF p_ACTION_ID IS NULL THEN
		p_ACTION_ID := GET_DEFAULT_ACTION_ID(p_ACTION_TYPE,
											-- Not Assigned context domain gets different default actions
											NVL(p_CONTEXT_DOMAIN_ID,CONSTANTS.NOT_ASSIGNED) = CONSTANTS.NOT_ASSIGNED
											);
	END IF;

END GET_CALC_PROCESS_SECURITY_INFO;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_TABLE
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2 IS

	v_TABLE_NAME ENTITY_DOMAIN.ENTITY_DOMAIN_TABLE%TYPE;

BEGIN
	v_TABLE_NAME := GET_ENTITY_TABLE_NAME(p_ENTITY_DOMAIN_ID);

	RETURN GET_REFERRED_DOMAIN_TABLE(p_COLUMN_NAME, v_TABLE_NAME);
END GET_REFERRED_DOMAIN_TABLE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_TABLE
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS

	v_REF_TABLE ENTITY_DOMAIN.ENTITY_DOMAIN_TABLE%TYPE;
	v_REF_TABLE_ALIAS ENTITY_DOMAIN.ENTITY_DOMAIN_ALIAS%TYPE := NULL;
	v_ENTITY_ALIAS_GUESS ENTITY_DOMAIN.ENTITY_DOMAIN_ALIAS%TYPE := NULL;

BEGIN

	-- WE GUESS THE ENTITY ALIAS BASED ON THE COLUMN NAME WITHOUT '_ID'
	v_ENTITY_ALIAS_GUESS := SUBSTR(p_COLUMN_NAME, 1, LENGTH(p_COLUMN_NAME) - 3);

	-- 1ST STEP: TRY TO RESOLVE REFERRED TABLE BASED ON FK CONSTRAINTS
	BEGIN

	  SELECT TABLE_NAME
	  INTO v_REF_TABLE
	  FROM (SELECT RC.TABLE_NAME,
              -- also get the number of columns in this foreign key
              (SELECT COUNT(1)
                     FROM USER_CONS_COLUMNS U
                     WHERE U.OWNER = USER
                           AND U.CONSTRAINT_NAME = C.CONSTRAINT_NAME
                           AND U.TABLE_NAME = C.TABLE_NAME) AS NUMCOLS
       FROM USER_CONSTRAINTS C,
              USER_CONS_COLUMNS CC,
              USER_CONSTRAINTS RC
       -- first find all out-going foreign keys from this table and column
       WHERE C.OWNER = USER
              AND C.TABLE_NAME = p_TABLE_NAME
              AND C.CONSTRAINT_TYPE = 'R' -- R indicates foreign key constraint
              AND C.R_OWNER = USER
              AND CC.OWNER = USER
              AND CC.CONSTRAINT_NAME = C.CONSTRAINT_NAME
              AND CC.TABLE_NAME = C.TABLE_NAME
              AND CC.COLUMN_NAME = p_COLUMN_NAME
              AND CC.POSITION = 1
              -- get the referenced table
              AND RC.OWNER = USER
              AND RC.CONSTRAINT_NAME = C.R_CONSTRAINT_NAME)
		WHERE NUMCOLS = 1; -- throw away composite foreign keys - we only want the
                   -- one that contains p_COLUMN_NAME and no others

		RETURN v_REF_TABLE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_REF_TABLE := NULL;
	END;

	-- NOW CHECK THE SYSTEM DICTIONARY
	v_REF_TABLE_ALIAS := GET_DICTIONARY_VALUE(v_ENTITY_ALIAS_GUESS, 0, 'System',
					'System Realm', 'Domain Aliases', p_TABLE_NAME);

	-- not found? see if there is a general mapping (not specific to source table)
	IF v_REF_TABLE_ALIAS IS NULL THEN
		v_REF_TABLE_ALIAS := GET_DICTIONARY_VALUE(v_ENTITY_ALIAS_GUESS, 0,
						'System', 'System Realm', 'Domain Aliases');
	END IF;

	IF v_REF_TABLE_ALIAS IS NOT NULL THEN
		BEGIN

		  SELECT ED.ENTITY_DOMAIN_TABLE INTO v_REF_TABLE
		  FROM ENTITY_DOMAIN ED
		  WHERE ED.ENTITY_DOMAIN_TABLE_ALIAS = v_REF_TABLE_ALIAS;

		  RETURN v_REF_TABLE;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_REF_TABLE := NULL;
		END;
	END IF;

	-- NOW TRY ONCE MORE USING THE GUESS BASED ON COLUMN NAME AS THE TABLE ALIAS
	BEGIN

		SELECT ED.ENTITY_DOMAIN_TABLE INTO v_REF_TABLE
		FROM ENTITY_DOMAIN ED
		WHERE ED.ENTITY_DOMAIN_TABLE_ALIAS = v_ENTITY_ALIAS_GUESS;

		RETURN v_REF_TABLE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- fall through below to return null
	END;

	-- NOTHING ABOVE WORKED, RETURN NULL
	RETURN NULL;

END GET_REFERRED_DOMAIN_TABLE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_ID
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN NUMBER IS

	v_REFERRED_TABLE VARCHAR2(32);

BEGIN
	v_REFERRED_TABLE := GET_REFERRED_DOMAIN_TABLE(p_COLUMN_NAME,
												p_ENTITY_DOMAIN_ID);

	RETURN GET_ENTITY_TABLE_DOMAIN_ID(v_REFERRED_TABLE);
END GET_REFERRED_DOMAIN_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_ID
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN NUMBER IS

	v_REFERRED_TABLE VARCHAR2(32);

BEGIN
	v_REFERRED_TABLE := GET_REFERRED_DOMAIN_TABLE(p_COLUMN_NAME,
												p_TABLE_NAME);

	RETURN GET_ENTITY_TABLE_DOMAIN_ID(v_REFERRED_TABLE);
END GET_REFERRED_DOMAIN_ID;
----------------------------------------------------------------------------------------------------
FUNCTION GET_DOMAIN_INFO
	(
	p_DOMAIN_ID IN NUMBER
	) RETURN ENTITY_DOMAIN_INFO IS

	v_RET ENTITY_DOMAIN_INFO;

BEGIN

	SELECT ED.ENTITY_DOMAIN_ID,
		ED.ENTITY_DOMAIN_TABLE,
		ED.ENTITY_DOMAIN_TABLE_ALIAS,
		SUBSTR(NI.PRIMARY_ID_COLUMN, 1, LENGTH(NI.PRIMARY_ID_COLUMN)-3)
	INTO v_RET
	FROM ENTITY_DOMAIN ED, NERO_TABLE_PROPERTY_INDEX NI
	WHERE ED.ENTITY_DOMAIN_ID = p_DOMAIN_ID
		AND NI.TABLE_NAME = ED.ENTITY_DOMAIN_TABLE;

	RETURN v_RET;

END GET_DOMAIN_INFO;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_INFO
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN ENTITY_DOMAIN_INFO IS

	v_ENT_DOM_ID NUMBER(9) := NULL;

BEGIN

	v_ENT_DOM_ID := GET_REFERRED_DOMAIN_ID(p_COLUMN_NAME, p_TABLE_NAME);

	IF v_ENT_DOM_ID IS NOT NULL THEN
		RETURN GET_DOMAIN_INFO(v_ENT_DOM_ID);
	END IF;

	RETURN NULL;

END GET_REFERRED_DOMAIN_INFO;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_INFO
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ENTITY_DOMAIN_INFO IS

	v_ENT_DOM_ID NUMBER(9) := NULL;

BEGIN

	v_ENT_DOM_ID := GET_REFERRED_DOMAIN_ID(p_COLUMN_NAME, p_ENTITY_DOMAIN_ID);

	IF v_ENT_DOM_ID IS NOT NULL THEN
		RETURN GET_DOMAIN_INFO(v_ENT_DOM_ID);
	END IF;

	RETURN NULL;

END GET_REFERRED_DOMAIN_INFO;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_ALIAS
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2 IS

	v_INFO ENTITY_DOMAIN_INFO;

BEGIN
	v_INFO := GET_REFERRED_DOMAIN_INFO(p_COLUMN_NAME,
											p_ENTITY_DOMAIN_ID);

	IF v_INFO.ENTITY_DOMAIN_ID IS NOT NULL THEN
		RETURN v_INFO.ENTITY_DOMAIN_TABLE_ALIAS;
	ELSE
		RETURN NULL;
	END IF;
END GET_REFERRED_DOMAIN_ALIAS;
----------------------------------------------------------------------------------------------------
FUNCTION GET_REFERRED_DOMAIN_ALIAS
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS

	v_INFO ENTITY_DOMAIN_INFO;

BEGIN
	v_INFO := GET_REFERRED_DOMAIN_INFO(p_COLUMN_NAME,
											p_TABLE_NAME);

	IF v_INFO.ENTITY_DOMAIN_ID IS NOT NULL THEN
		RETURN v_INFO.ENTITY_DOMAIN_TABLE_ALIAS;
	ELSE
		RETURN NULL;
	END IF;
END GET_REFERRED_DOMAIN_ALIAS;
----------------------------------------------------------------------------------------------------
FUNCTION HAS_NOT_ASSIGNED
	(
	p_COLUMN_NAME IN VARCHAR2,
	p_TABLE_NAME IN VARCHAR2
	) RETURN NUMBER IS
v_COUNT PLS_INTEGER;
BEGIN
	-- check SYSTEM_LABEL to see if this column is an "exception"
	SELECT COUNT(1)
	INTO v_COUNT
	FROM SYSTEM_LABEL
	WHERE MODEL_ID = CONSTANTS.GLOBAL_MODEL
		AND MODULE = 'Entity Manager'
		AND KEY1 = 'Ignore Not Assigned'
		AND KEY2 = p_TABLE_NAME
		AND KEY3 = '?'
		AND VALUE = p_COLUMN_NAME;

	IF v_COUNT > 0 THEN
		-- we are ignoring this reference - return zero
		RETURN 0;
	END IF;

	-- If we're not setup to ignore this reference, check to see if it even
	-- references a domain with Not Assigned.
	RETURN HAS_NOT_ASSIGNED(GET_REFERRED_DOMAIN_ID(p_COLUMN_NAME, p_TABLE_NAME));
END HAS_NOT_ASSIGNED;
----------------------------------------------------------------------------------------------------
FUNCTION HAS_NOT_ASSIGNED
	(
	p_DOMAIN_ID IN NUMBER
	) RETURN NUMBER IS
BEGIN

	RETURN UT.NUMBER_FROM_BOOLEAN(EI.GET_ENTITY_NAME(p_DOMAIN_ID, 0, 1) IS NOT NULL);

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		RETURN UT.NUMBER_FROM_BOOLEAN(FALSE);
END HAS_NOT_ASSIGNED;
----------------------------------------------------------------------------------------------------
FUNCTION GET_COPY_OF_ENTITY_NAME
	(
	p_ENTITY_NAME      VARCHAR2,
	p_ENTITY_DOMAIN_ID NUMBER
	) RETURN VARCHAR2 IS
v_NAME 		  				VARCHAR2(1000);

BEGIN

	v_NAME := 'COPY OF ' || p_ENTITY_NAME;

	v_NAME := RESOLVE_ENTITY_NAME_CONFLICT(v_NAME, p_ENTITY_DOMAIN_ID);

	RETURN v_NAME;
END GET_COPY_OF_ENTITY_NAME;
----------------------------------------------------------------------------------------------------
PROCEDURE COPY_COMMON_SUBTABS
(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SOURCE_ENTITY_ID IN NUMBER,
	p_DEST_ENTITY_ID IN NUMBER
) AS
	v_INCLUDE_NOTES NUMBER(1);
	v_INCLUDE_CONTACTS NUMBER(1);
	v_INCLUDE_GROUPS NUMBER(1);
	v_INCLUDE_ATTRIBUTES NUMBER(1);
	v_INCLUDE_EXTERN_INDENTS NUMBER(1);
BEGIN

	SELECT NVL(ED.INCLUDE_CONTACT_ADDRESS,0),
	    NVL(ED.INCLUDE_GROUPS,0),
		NVL(ED.INCLUDE_ENTITY_ATTRIBUTE,0),
		NVL(ED.INCLUDE_EXTERNAL_IDENTIFIER,0),
		NVL(ED.INCLUDE_NOTES,0)
	INTO v_INCLUDE_CONTACTS,
		v_INCLUDE_GROUPS,
		v_INCLUDE_ATTRIBUTES,
		v_INCLUDE_EXTERN_INDENTS,
		v_INCLUDE_NOTES
	FROM ENTITY_DOMAIN ED
	WHERE ED.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	-- BRING OVER CONTACTS AND ADDRESSES
	IF v_INCLUDE_CONTACTS = 1 THEN
		INSERT INTO ENTITY_DOMAIN_ADDRESS( ENTITY_DOMAIN_ID, OWNER_ENTITY_ID,
									CATEGORY_ID, STREET, GEOGRAPHY_ID, ENTRY_DATE)
		SELECT ENTITY_DOMAIN_ID, p_DEST_ENTITY_ID, CATEGORY_ID, STREET, GEOGRAPHY_ID, SYSDATE
		FROM ENTITY_DOMAIN_ADDRESS
		WHERE OWNER_ENTITY_ID = p_SOURCE_ENTITY_ID
			AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

		INSERT INTO ENTITY_DOMAIN_CONTACT ( ENTITY_DOMAIN_ID, OWNER_ENTITY_ID, CATEGORY_ID,
										CONTACT_ID, ENTRY_DATE)
		SELECT ENTITY_DOMAIN_ID, p_DEST_ENTITY_ID, CATEGORY_ID, CONTACT_ID, SYSDATE
		FROM ENTITY_DOMAIN_CONTACT
		WHERE OWNER_ENTITY_ID = p_SOURCE_ENTITY_ID
			AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
	END IF;

	-- BRING OVER GROUPS (NO ORDERED LISTS)
	IF v_INCLUDE_GROUPS = 1 THEN
		INSERT INTO ENTITY_GROUP_ASSIGNMENT ( ENTITY_GROUP_ID, ENTITY_ID, BEGIN_DATE,
											 END_DATE, ENTRY_DATE)
		SELECT EGA.ENTITY_GROUP_ID, p_DEST_ENTITY_ID,
			EGA.BEGIN_DATE, EGA.END_DATE, SYSDATE
		FROM ENTITY_GROUP EG,
			ENTITY_GROUP_ASSIGNMENT EGA
		WHERE EG.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND EG.IS_MATRIX = 0
			AND EGA.ENTITY_GROUP_ID = EG.ENTITY_GROUP_ID
			AND EGA.ENTITY_ID = p_SOURCE_ENTITY_ID;
	END IF;

	-- BRING OVER ATTRIBUTES
	IF v_INCLUDE_ATTRIBUTES = 1 THEN
		INSERT INTO TEMPORAL_ENTITY_ATTRIBUTE (OWNER_ENTITY_ID,  ATTRIBUTE_ID,
									BEGIN_DATE, ENTITY_DOMAIN_ID, ATTRIBUTE_NAME,
									END_DATE, ATTRIBUTE_VAL, ENTRY_DATE)
		SELECT p_DEST_ENTITY_ID, ATTRIBUTE_ID, BEGIN_DATE,
			ENTITY_DOMAIN_ID, ATTRIBUTE_NAME, END_DATE,
			ATTRIBUTE_VAL, SYSDATE
		FROM TEMPORAL_ENTITY_ATTRIBUTE
		WHERE OWNER_ENTITY_ID = p_SOURCE_ENTITY_ID
			AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;
	END IF;

	-- BRING OVER EXTERNAL IDENTIFIERS
	IF v_INCLUDE_EXTERN_INDENTS = 1 THEN
		INSERT INTO EXTERNAL_SYSTEM_IDENTIFIER (EXTERNAL_SYSTEM_ID, ENTITY_DOMAIN_ID,
										ENTITY_ID, IDENTIFIER_TYPE, EXTERNAL_IDENTIFIER, ENTRY_DATE)
		SELECT EXTERNAL_SYSTEM_ID, ENTITY_DOMAIN_ID, p_DEST_ENTITY_ID, IDENTIFIER_TYPE,
				EXTERNAL_IDENTIFIER, SYSDATE
		FROM EXTERNAL_SYSTEM_IDENTIFIER
		WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
			AND ENTITY_ID = p_SOURCE_ENTITY_ID;
	END IF;

	IF v_INCLUDE_NOTES = 1 THEN
	   INSERT INTO ENTITY_NOTE (ENTITY_DOMAIN_ID, ENTITY_ID, NOTE_TYPE,
	   						 NOTE_DATE, NOTE_AUTHOR_ID, NOTE_TEXT)
	   SELECT ENTITY_DOMAIN_ID, p_DEST_ENTITY_ID, NOTE_TYPE, NOTE_DATE, NOTE_AUTHOR_ID, NOTE_TEXT
	   FROM ENTITY_NOTE
	   WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
	  		AND ENTITY_ID = p_SOURCE_ENTITY_ID;
	END IF;

END COPY_COMMON_SUBTABS;
----------------------------------------------------------------------------------------------------
PROCEDURE COPY_ENTITY_SUBTABS
(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_NEW_ENTITY_ID IN NUMBER
) AS

	CURSOR cur_COPY_TBL IS
	SELECT DISTINCT TABLE_NAME.ATTRIBUTE_VAL "TABLE_NAME",
		ENTITY_ID_COLUMN.ATTRIBUTE_VAL "OWNER_ID_COLUMN"
	FROM SYSTEM_OBJECT IO_TABLES,
		SYSTEM_OBJECT IO_SUBTABS,
		SYSTEM_OBJECT_ATTRIBUTE TABLE_NAME,
		SYSTEM_OBJECT_ATTRIBUTE ENTITY_ID_COLUMN
	WHERE IO_TABLES.OBJECT_CATEGORY = CONSTANTS.SO_IO_TBL_CATEGORY
		AND UPPER(IO_TABLES.OBJECT_NAME) = UPPER(p_ENTITY_TYPE)
		AND IO_SUBTABS.PARENT_OBJECT_ID = IO_TABLES.OBJECT_ID
		AND IO_SUBTABS.OBJECT_CATEGORY = CONSTANTS.SO_IO_SUBTAB_CATEGORY
		AND TABLE_NAME.OBJECT_ID = IO_SUBTABS.OBJECT_ID
		AND TABLE_NAME.ATTRIBUTE_ID = 605
		AND ENTITY_ID_COLUMN.OBJECT_ID = IO_SUBTABS.OBJECT_ID
		AND ENTITY_ID_COLUMN.ATTRIBUTE_ID = 606
	ORDER BY TABLE_NAME;

	v_DML VARCHAR2(1000);
	v_COLUMNS VARCHAR2(300);

	CURSOR cur_TBL_COLS (TBL_NAME VARCHAR2, OWNER_ID_COLUMN VARCHAR2) IS
	SELECT UTC.COLUMN_NAME
	FROM USER_TAB_COLUMNS UTC
	WHERE UTC.TABLE_NAME = TBL_NAME
		AND UTC.COLUMN_NAME <> OWNER_ID_COLUMN;

	v_CURR_TABLE VARCHAR2(100);

BEGIN

	FOR v_COPY_TBL_REC IN cur_COPY_TBL LOOP

		IF v_CURR_TABLE IS NULL OR v_CURR_TABLE = v_COPY_TBL_REC.TABLE_NAME THEN
			-- GATHER ALL THE COLUMNS FOR THAT TABLE
			v_COLUMNS := '';

			FOR v_TBL_COL IN cur_TBL_COLS(v_COPY_TBL_REC.TABLE_NAME, v_COPY_TBL_REC.OWNER_ID_COLUMN) LOOP
				v_COLUMNS := v_COLUMNS || ', ' || v_TBL_COL.COLUMN_NAME;
			END LOOP;
		END IF;

		v_DML := 'INSERT INTO ' || v_COPY_TBL_REC.TABLE_NAME || ' (' ||
			  v_COPY_TBL_REC.OWNER_ID_COLUMN || v_COLUMNS || ') ' ||
			  'SELECT ' || p_NEW_ENTITY_ID || v_COLUMNS || ' FROM ' ||
			  v_COPY_TBL_REC.TABLE_NAME || ' WHERE ' || v_COPY_TBL_REC.OWNER_ID_COLUMN ||
			  ' = ' || p_ENTITY_ID;

		EXECUTE IMMEDIATE v_DML;

	END LOOP;
END COPY_ENTITY_SUBTABS;
----------------------------------------------------------------------------------------------------
PROCEDURE COPY_ENTITY_TABLE
(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_NEW_ENTITY_ID IN NUMBER,
	p_NEW_ENTITY_NAME IN VARCHAR2
) AS

	v_TABLE_NAME VARCHAR2(256);
	v_TABLE_ALIAS VARCHAR2(256);

	CURSOR cur_COLUMNS (TBL_NAME VARCHAR2, TBL_ALIAS VARCHAR2) IS
	SELECT COLS.COLUMN_NAME
	FROM USER_TAB_COLUMNS COLS
	WHERE COLS.TABLE_NAME = TBL_NAME
		AND COLS.COLUMN_NAME <> (TBL_ALIAS || '_ID')
		AND COLS.COLUMN_NAME <> (TBL_ALIAS || '_NAME');

	v_DML VARCHAR2(2300);
	v_COLUMNS VARCHAR2(1000);

BEGIN

	SELECT TBLS.TABLE_NAME, SUBSTR(TBLS.PRIMARY_ID_COLUMN, 1, LENGTH(TBLS.PRIMARY_ID_COLUMN)-3)
		INTO v_TABLE_NAME, v_TABLE_ALIAS
	FROM ENTITY_DOMAIN ED, NERO_TABLE_PROPERTY_INDEX TBLS
	WHERE ED.ENTITY_DOMAIN_TABLE_ALIAS = p_ENTITY_TYPE
		AND TBLS.TABLE_NAME = ED.ENTITY_DOMAIN_TABLE;

	FOR v_COLUMN IN cur_COLUMNS ( v_TABLE_NAME, v_TABLE_ALIAS) LOOP
		v_COLUMNS := v_COLUMNS || ', ' || v_COLUMN.COLUMN_NAME;
	END LOOP;

	v_DML := 'INSERT INTO ' || v_TABLE_NAME || '(' || v_TABLE_ALIAS || '_ID'
		|| ', ' || v_TABLE_ALIAS || '_NAME' || v_COLUMNS || ') ' ||
		'SELECT ' || p_NEW_ENTITY_ID || ', ''' || p_NEW_ENTITY_NAME || '''' || v_COLUMNS ||
		' FROM ' || v_TABLE_NAME || ' WHERE ' || v_TABLE_ALIAS || '_ID = ' ||
		 p_ENTITY_ID;

	EXECUTE IMMEDIATE v_DML;

END COPY_ENTITY_TABLE;
----------------------------------------------------------------------------------------------------
PROCEDURE COPY_ENTITY
(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_TYPE IN VARCHAR2,
	p_NEW_ENTITY_ID OUT NUMBER,
	p_NEW_ENTITY_NAME OUT VARCHAR2
) AS

	v_DOMAIN_ID NUMBER(9);

BEGIN

	v_DOMAIN_ID := GET_DOMAIN_ID_FOR_TYPE(p_ENTITY_TYPE);

	SD.VERIFY_ENTITY_IS_ALLOWED(SD.g_ACTION_CREATE_ENT, p_ENTITY_ID, v_DOMAIN_ID);

	p_NEW_ENTITY_NAME := GET_COPY_OF_ENTITY_NAME(
							EI.GET_ENTITY_NAME(v_DOMAIN_ID, p_ENTITY_ID),
							v_DOMAIN_ID);

	SELECT OID.NEXTVAL INTO p_NEW_ENTITY_ID FROM DUAL;

	COPY_ENTITY_TABLE(p_ENTITY_ID, p_ENTITY_TYPE,
		p_NEW_ENTITY_ID, p_NEW_ENTITY_NAME);
	COPY_ENTITY_SUBTABS(p_ENTITY_ID, p_ENTITY_TYPE, p_NEW_ENTITY_ID);
	COPY_COMMON_SUBTABS(v_DOMAIN_ID, p_ENTITY_ID, p_NEW_ENTITY_ID);

END COPY_ENTITY;
----------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_TYPE
(
	p_DOMAIN_ID IN NUMBER
) RETURN VARCHAR2 IS

	v_TYPE NERO_TABLE_PROPERTY_INDEX.ALIAS%TYPE;

BEGIN

	SELECT NVL(NTPI.ALIAS, NTPI.TABLE_NAME)
	INTO v_TYPE
	FROM ENTITY_DOMAIN ED,
		NERO_TABLE_PROPERTY_INDEX NTPI
	WHERE ED.ENTITY_DOMAIN_ID = p_DOMAIN_ID
		AND NTPI.TABLE_NAME = ED.ENTITY_DOMAIN_TABLE;

	RETURN v_TYPE;

END GET_ENTITY_TYPE;
----------------------------------------------------------------------------------------------------
FUNCTION GET_DOMAIN_ID_FOR_TYPE
	(
	p_ENTITY_TYPE IN VARCHAR2
	) RETURN VARCHAR2 IS

	v_DOMAIN_ID NUMBER(9);

BEGIN
	SELECT ED.ENTITY_DOMAIN_ID INTO v_DOMAIN_ID
	FROM ENTITY_DOMAIN ED
	WHERE ED.ENTITY_DOMAIN_TABLE_ALIAS = p_ENTITY_TYPE;

	RETURN v_DOMAIN_ID;

END GET_DOMAIN_ID_FOR_TYPE;
----------------------------------------------------------------------------------------------------
FUNCTION RESOLVE_ENTITY_NAME_CONFLICT
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2 IS

	v_NAME 		  				VARCHAR2(1000);
	v_NAME_SUFFIX 				VARCHAR2(12);
	v_TABLE_NAME  				VARCHAR2(32);
	v_PRIMARY_NAME_COLUMN 		VARCHAR2(32);
	v_PRIMARY_NAME_COLUMN_SIZE 	NUMBER(9);
	v_SQL         				VARCHAR2(1000);
	v_COUNT       				NUMBER(9);
	v_ATTEMPT     				NUMBER(9) := 0;

BEGIN

	ASSERT(p_ENTITY_NAME IS NOT NULL, 'ENTITY_NAME must not be null.');
	ASSERT(p_ENTITY_DOMAIN_ID IS NOT NULL, 'ENTITY_DOMAIN_ID must not be null.');

	SELECT MAX(A.ENTITY_DOMAIN_TABLE), MAX(A.PRIMARY_NAME_COLUMN)
	INTO v_TABLE_NAME, v_PRIMARY_NAME_COLUMN
	FROM ENTITY_DOMAIN_PROPERTY A
	WHERE A.ENTITY_DOMAIN_ID = P_ENTITY_DOMAIN_ID;

	IF v_TABLE_NAME IS NOT NULL AND v_PRIMARY_NAME_COLUMN IS NOT NULL THEN

		SELECT MIN(A.DATA_LENGTH)
		INTO v_PRIMARY_NAME_COLUMN_SIZE
		FROM USER_TAB_COLS A
		WHERE A.TABLE_NAME = v_TABLE_NAME
		  AND A.COLUMN_NAME = v_PRIMARY_NAME_COLUMN;

		LOOP
			IF v_ATTEMPT > 0 THEN
				v_NAME_SUFFIX := ' (' || v_ATTEMPT || ')';
			END IF;

			v_NAME := TRIM(SUBSTR(p_ENTITY_NAME, 1, v_PRIMARY_NAME_COLUMN_SIZE - NVL(LENGTH(v_NAME_SUFFIX), 0))) || v_NAME_SUFFIX;

			v_SQL := 'SELECT COUNT(1) FROM ' || v_TABLE_NAME || ' WHERE ' || v_PRIMARY_NAME_COLUMN || ' = :1';
			EXECUTE IMMEDIATE v_SQL	INTO v_COUNT USING v_NAME;

			EXIT WHEN v_COUNT = 0;
			v_ATTEMPT := v_ATTEMPT + 1;
		END LOOP;
	ELSE
		-- Raise exception
		ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY, 'No ENTITY_DOMAIN for Id = ' || P_ENTITY_DOMAIN_ID);
	END IF;

	RETURN v_NAME;

END RESOLVE_ENTITY_NAME_CONFLICT;
----------------------------------------------------------------------------------------------------
PROCEDURE TERMINATE_USAGE_FACTOR
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_END_DATE IN DATE,
	p_CASE_ID IN NUMBER := GA.BASE_CASE_ID
	) AS
	v_TABLE_NAME VARCHAR2(30);
	v_ENTITY_ID_COL VARCHAR2(30);
	v_END_DATE DATE := TRUNC(p_END_DATE);
	v_SQL VARCHAR2(4000);
	v_DOMAIN_INFO ENTITY_DOMAIN_INFO;
	v_COUNT NUMBER(1);
	v_WHERE_CASE_ID VARCHAR2(256) := '';
BEGIN

	v_DOMAIN_INFO := GET_DOMAIN_INFO(p_ENTITY_DOMAIN_ID);
	v_TABLE_NAME := v_DOMAIN_INFO.ENTITY_DOMAIN_TABLE_PREFIX||'_USAGE_FACTOR';
	v_ENTITY_ID_COL := v_DOMAIN_INFO.ENTITY_DOMAIN_TABLE_PREFIX||'_ID';

	--Make sure there is an appropriate usage factor table
	SELECT COUNT(1) INTO v_COUNT FROM USER_TABLES WHERE TABLE_NAME = v_TABLE_NAME;
	IF v_COUNT = 0 THEN
		ERRS.RAISE_BAD_ARGUMENT('ENTITY_DOMAIN_ID',p_ENTITY_DOMAIN_ID,'Specified domain must have a valid Usage Factor table.  '||v_TABLE_NAME||' does not exist.');
	END IF;

	--See if it has a Case ID
	SELECT COUNT(1) INTO v_COUNT
	FROM USER_TAB_COLS
	WHERE TABLE_NAME = v_TABLE_NAME
		AND COLUMN_NAME = 'CASE_ID';

	IF v_COUNT = 1 THEN
		v_WHERE_CASE_ID := ' CASE_ID = '||UT.GET_LITERAL_FOR_NUMBER(p_CASE_ID)|| ' AND ';
	END IF;

	--Delete any usage factor associations that start after the end date.
	v_SQL := 'DELETE '||v_TABLE_NAME||
		' WHERE '||v_WHERE_CASE_ID||v_ENTITY_ID_COL||' = '||UT.GET_LITERAL_FOR_NUMBER(p_ENTITY_ID)||
		'   AND BEGIN_DATE > '||UT.GET_LITERAL_FOR_DATE(v_END_DATE);

	LOGS.LOG_DEBUG('Deleting Usage Factors: '||v_SQL);
	EXECUTE IMMEDIATE v_SQL;

	--Terminate any usage factor associations that cross the end date boundary.
	v_SQL := 'UPDATE '||v_TABLE_NAME||
		' SET END_DATE = '||UT.GET_LITERAL_FOR_DATE(v_END_DATE)||
		' WHERE '||v_WHERE_CASE_ID||v_ENTITY_ID_COL||' = '||UT.GET_LITERAL_FOR_NUMBER(p_ENTITY_ID)||
		'   AND (END_DATE IS NULL OR END_DATE > '||UT.GET_LITERAL_FOR_DATE(p_END_DATE)||')';

	LOGS.LOG_DEBUG('Truncating Usage Factor: '||v_SQL);
	EXECUTE IMMEDIATE v_SQL;

EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE('Error terminating usage factor: '||v_SQL);

END TERMINATE_USAGE_FACTOR;
----------------------------------------------------------------------------------------------------
END ENTITY_UTIL;
/