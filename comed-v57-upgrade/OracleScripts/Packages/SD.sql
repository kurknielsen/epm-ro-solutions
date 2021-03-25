CREATE OR REPLACE PACKAGE SD AS
--Revision $Revision: 1.22 $

-- Security Data level Package

FUNCTION WHAT_VERSION RETURN VARCHAR;

----------------------------------------------------------------------------------------------------
-- UI procedures
----------------------------------------------------------------------------------------------------

PROCEDURE GET_ENTITY_COL_NAMES
	(
	p_REALM_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_ENTITY_COL_VALS
	(
	p_REALM_ID IN NUMBER,
    p_ENTITY_COLUMN IN VARCHAR2,
	p_INCLUDE_SELECTED_ONLY IN NUMBER,
	p_IS_EXCLUDING_VALS OUT NUMBER,
	p_VALS_ARE_IDs OUT NUMBER,
	p_ALLOW_REFS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE GET_ENTITY_COLUMNS_FOR_REALM
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SORT_ALPHABETICAL IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE REALM_LIST_FOR_ENTITY_DOMAIN
	(
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_DOMAIN_ID IN NUMBER,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    );

 PROCEDURE PUT_ENTITY_COL_VALS
	(
    p_REALM_ID IN NUMBER,
    p_ENTITY_COLUMN IN VARCHAR2,
	p_IS_SELECTED IN NUMBER,
	p_OLD_IS_SELECTED IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2
    );

PROCEDURE REALM_LIST
	(
    p_ENTITY_DOMAIN_ID IN NUMBER,
    p_STATUS OUT NUMBER,
    p_CURSOR IN OUT GA.REFCURSOR
    );

PROCEDURE GET_ENTITIES_IN_REALM
	(
	p_REALM_ID IN NUMBER,
	p_STATUS OUT NUMBER,
	p_CURSOR IN OUT GA.REFCURSOR
	);

PROCEDURE PROC_HAS_DATA_LEVEL_ACCESS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_RESULT OUT NUMBER
	);

PROCEDURE PROC_ACTION_EXISTS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_RESULT OUT NUMBER
	);

----------------------------------------------------------------------------------------------------
-- Data-Level Security API
----------------------------------------------------------------------------------------------------

-- Get the list of entity IDs to which the current user has access for the specified
-- action. If the user has access to all data, then this list will contain only
-- a single value: g_ALL_DATA_ENTITY_ID
FUNCTION GET_ALLOWED_ENTITY_ID_TABLE
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE;
FUNCTION GET_ALLOWED_ENTITY_ID_TABLE
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE;

-- Same as above except that DOMAIN_ID is not needed. This will result in an
-- error if the specified action's domain is set to <ALL>
-- @deprecated - use GET_ALLOWED_ENTITY_ID_TABLE(VARCHAR2,NUMBER) instead
FUNCTION GET_ALLOWED_ENTITY_ID_TABLE
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN ID_TABLE;

-- Return true if the current user has access to the specified entity for the
-- specified action.
FUNCTION GET_ENTITY_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN BOOLEAN;
FUNCTION GET_ENTITY_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN BOOLEAN;

-- Same as above except that DOMAIN_ID is not needed. This will result in an
-- error if the specified action's domain is set to <ALL>
-- @deprecated - use GET_ENTITY_IS_ALLOWED(VARCHAR2,NUMBER,NUMBER) instead
FUNCTION GET_ENTITY_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER
	) RETURN BOOLEAN;
	
-- Similar to the above, except that instead of returning a boolean that
-- indicates whether the user has access, an exception will simply be raised
-- if the user does not have access.
PROCEDURE VERIFY_ENTITY_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	);
PROCEDURE VERIFY_ENTITY_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	);

-- Return true if the current user has access to the specified action. The
-- specified action must have a domain of Not Assigned (i.e. it is a Yes/No
-- privilege, not a realm-based privilege).
FUNCTION GET_ACTION_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN BOOLEAN;
FUNCTION GET_ACTION_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER
	) RETURN BOOLEAN;

-- Similar to the above, except that instead of returning a boolean that
-- indicates whether the user has access, an exception will simply be raised
-- if the user does not have access.
PROCEDURE VERIFY_ACTION_IS_ALLOWED
	(
	p_ACTION_NAME IN VARCHAR2
	);
PROCEDURE VERIFY_ACTION_IS_ALLOWED
	(
	p_ACTION_ID IN NUMBER
	);

-- Same as GET_ENTITY_IS_ALLOWED above but returns NUMBER instead of BOOLEAN
-- @deprecated - use GET_ENTITY_IS_ALLOWED(VARCHAR2,NUMBER,NUMBER) instead
FUNCTION HAS_DATA_LEVEL_ACCESS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_ID IN NUMBER
	) RETURN NUMBER;

-- Get the list of realm IDs to which the current user has access for the specified
-- action. If the user has access to all data, then this list will contain only
-- a single value: g_ALL_DATA_REALM_ID. This can be useful in cases where a very
-- large number of entities is expected. In these cases, instead of using
-- GET_ALLOWED_ENTITY_ID_TABLE, you would use GET_ALLOWED_REALM_ID_TABLE and join
-- that to SYSTEM_REALM_ENTITY. This allows you to use large numbers of entities
-- in a query that would otherwise require too much memory if all entity IDs were
-- placed in an in-memory collection.
FUNCTION GET_ALLOWED_REALM_ID_TABLE
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE;
FUNCTION GET_ALLOWED_REALM_ID_TABLE
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE;

-- Returns 1 if a System Action with the specified name exists, 0 otherwise
FUNCTION ACTION_EXISTS
	(
	p_ACTION_NAME IN VARCHAR2
	) RETURN NUMBER;

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
	) RETURN NUMBER_COLLECTION;

-- Same as above, except a NUMBER_COLLECTION is used as the selection rather
-- than a VARCHAR2.
FUNCTION GET_ALLOWED_IDS_FROM_SELECTION
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_SELECTED_ITEMS IN NUMBER_COLLECTION,
	p_RAISE_EXCEPTION IN BOOLEAN := TRUE
	) RETURN NUMBER_COLLECTION;

-- Return true if the current user has access to at least one of the specified realms
-- for the specified action and domain. This will also return true if the user has
-- access to the All Data realm.
FUNCTION IS_ALLOWED_FOR_REALMS
	(
	p_ACTION_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_REALMS IN ID_TABLE
	) RETURN BOOLEAN;
FUNCTION IS_ALLOWED_FOR_REALMS
	(
	p_ACTION_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_REALMS IN ID_TABLE
	) RETURN BOOLEAN;

----------------------------------------------------------------------------------------------------
-- Enumeration and Membership Methods
----------------------------------------------------------------------------------------------------

-- Enumerate all entities to which user has specified privilege. Unlike
-- GET_ALLOWED_ENTITY_ID_TABLE, this will expand 'all data' to all the actual
-- domain members. Furthermore, it can optionally intersect the resulting list
-- of entities with those in the specified realm and/or group. If a group ID
-- is specified then begin and end dates must also be specified since group
-- assignments are temporal. If a group ID is specified, and p_IGNORE_GROUP_PRIVS is
-- false (the default) then the enumeration will exclude entities assigned to
-- elements of the group hierarchy to which the current user does not have
-- 'Select Entity' privilege. Finally, it returns a WORK_ID instead of an ID_TABLE.
-- RTO_WORK will be populated with WORK_XID as the entity ID and WORK_DATA as the
-- entity name.
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
	);
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
	);

-- Enumerate all entities that belong to a specified realm. If the specified
-- realm is 'all data' then this will enumerate all entities in the realm's
-- domain. On return, RTO_WORK will be populated with WORK_XID as the entity ID
-- and WORK_DATA as the entity name.
PROCEDURE ENUMERATE_SYSTEM_REALM_MEMBERS
	(
	p_REALM_ID	IN NUMBER,
	p_WORK_ID	OUT NUMBER
	);

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
	);
	
-- Is the specified entity a member of the specified realm?
FUNCTION IS_MEMBER_OF_SYSTEM_REALM
	(
	p_ENTITY_ID	IN NUMBER,
	p_REALM_ID	IN NUMBER
	) RETURN BOOLEAN;

-- Enumerate all entities that belong to a group. This will return all entities
-- that are assigned to the entire hierarchy of the specified group and its
-- sub-tree of child groups. Since this relationship is temporal, a date range
-- is required. All entities assigned to this group for any period that overlaps
-- the specified date range will be included in the final enumeration. On return,
-- RTO_WORK will be populated with WORK_XID as the entity ID and WORK_DATA as the
-- entity name. If p_IGNORE_GROUP_PRIVS is false (the default) then the enumeration
-- will exclude entities assigned to elements of the group hierarchy to which the
-- current user does not have 'Select Entity' privilege. If p_IGNORE_MEMBER_PRIVS
-- is false (the default) it will also exclude members to which the current user
-- does not have 'Select Entity' privilege.
PROCEDURE ENUMERATE_ENTITY_GROUP_MEMBERS
	(
	p_GROUP_ID				IN NUMBER,
	p_BEGIN_DATE			IN DATE,
	p_END_DATE				IN DATE,
	p_WORK_ID				OUT NUMBER,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE,
	p_IGNORE_MEMBER_PRIVS	IN BOOLEAN := FALSE
	);

-- Is the specified entity a member of the specified group or its sub-tree during
-- the specified date range? If p_IGNORE_GROUP_PRIVS is false (the default) then this
-- method will not search elements of the group hierarchy to which the current user
-- does not have 'Select Entity' privilege.
FUNCTION IS_MEMBER_OF_ENTITY_GROUP
	(
	p_ENTITY_ID				IN NUMBER,
	p_GROUP_ID				IN NUMBER,
	p_BEGIN_DATE			IN DATE,
	p_END_DATE				IN DATE,
	p_IGNORE_GROUP_PRIVS	IN BOOLEAN := FALSE
	) RETURN BOOLEAN;

----------------------------------------------------------------------------------------------------
-- Other Security-Related Utility Methods
----------------------------------------------------------------------------------------------------

FUNCTION GET_REALM_QUERY
	(
	p_REALM_ID IN NUMBER,
	p_OPTIONAL_COLUMNS IN VARCHAR2 := NULL
	) RETURN VARCHAR2;

PROCEDURE POPULATE_ENTITIES_FOR_REALM
	(
	p_REALM_ID IN NUMBER
	);

PROCEDURE POPULATE_REALMS_FOR_DOMAIN
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_STATUS OUT NUMBER
	);

FUNCTION GET_REALMS_FOR_ENTITY_FIELDS
	(
	p_FIELDS_MAP UT.STRING_MAP,
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN ID_TABLE;

PROCEDURE LIST_ACTIONS_BY_DOMAIN
	(
	p_ENTITY_DOMAIN_ID IN VARCHAR2,
	p_STATUS OUT NUMBER,
	p_CURSOR OUT GA.REFCURSOR
	);

----------------------------------------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------------------------------------

g_ALL_DATA_REALM_ID 	CONSTANT NUMBER(9) := 1;
g_ALL_DATA_ENTITY_ID	CONSTANT NUMBER(9) := -998;
g_ALL_ENTITY_DOMAINS_ID	CONSTANT NUMBER(9) := -1;
g_ALL_DATA_STRING		CONSTANT VARCHAR2(8) := 'ALLDATA!';

--------------------
-- Action Names
--------------------

-- Entity Actions
g_ACTION_SELECT_ENT CONSTANT VARCHAR2(32) := 'Select Entity';
g_ACTION_CREATE_ENT CONSTANT VARCHAR2(32) := 'Create Entity';
g_ACTION_UPDATE_ENT CONSTANT VARCHAR2(32) := 'Update Entity';
g_ACTION_DELETE_ENT CONSTANT VARCHAR2(32) := 'Delete Entity';
-- Audit Trail actions
g_ACTION_SELECT_AUDIT CONSTANT VARCHAR2(32) := 'Select Audit Trail';
g_ACTION_UPDATE_AUDIT CONSTANT VARCHAR2(32) := 'Update Audit Trail';
-- Alert actions
g_ACTION_SELECT_ALERT_OCCUR CONSTANT VARCHAR2(32) := 'Select Alert Occurrences';
g_ACTION_CREATE_ALERT_OCCUR CONSTANT VARCHAR2(32) := 'Create Alert Occurrences';
g_ACTION_UPDATE_ALERT_OCCUR CONSTANT VARCHAR2(32) := 'Update Alert Occurrences';
--Scheduling actions
g_ACTION_TXN_SELECT 	CONSTANT VARCHAR2(32) := 'Select Electric Scheduling';
g_ACTION_TXN_UPDATE 	CONSTANT VARCHAR2(32) := 'Update Electric Scheduling';
g_ACTION_TXN_DELETE 	CONSTANT VARCHAR2(32) := 'Delete Electric Scheduling';
g_ACTION_TXN_LOCK_STATE CONSTANT VARCHAR2(40) := 'Update Electric Scheduling Lock State';
g_ACTION_BAO_UPDATE 	CONSTANT VARCHAR2(32) := 'Update Bids and Offers';
g_ACTION_BAO_LOCK_STATE	CONSTANT VARCHAR2(40) := 'Update Bids and Offers Lock State';
g_ACTION_BAO_ACCEPT 	CONSTANT VARCHAR2(32) := 'Accept Bids and Offers';
g_ACTION_BAO_ACCEPT_EXT	CONSTANT VARCHAR2(32) := 'Accept External Bids and Offers';
g_ACTION_SSMETER_SELECT	CONSTANT VARCHAR2(32) := 'Select Sub-Station Meter';
g_ACTION_SSMETER_UPDATE	CONSTANT VARCHAR2(32) := 'Update Sub-Station Meter';
g_ACTION_SSMETER_LOCK_STATE CONSTANT VARCHAR2(40) := 'Update Sub-Station Meter Lock State';
g_ACTION_MSRMNT_SRC_SELECT CONSTANT VARCHAR2(32) := 'Select Measurement Source';
g_ACTION_MSRMNT_SRC_UPDATE CONSTANT VARCHAR2(32) := 'Update Measurement Source';
g_ACTION_MSRMNT_SRC_LOCK_STATE CONSTANT VARCHAR2(40) := 'Update Measurement Source Lock State';
--Billing actions
g_ACTION_PSE_BILL_SELECT 		CONSTANT VARCHAR2(32) := 'Select PSE Billing';
g_ACTION_PSE_BILL_CALCULATE 	CONSTANT VARCHAR2(32) := 'Calculate PSE Billing';
g_ACTION_PSE_BILL_LOCK_STATE 	CONSTANT VARCHAR2(32) := 'Update PSE Billing Lock State';
g_ACTION_PSE_BILL_DISPUTES_INT  CONSTANT VARCHAR2(40) := 'Update PSE Billing Disputes Internal';
g_ACTION_PSE_BILL_DISPUTES_EXT  CONSTANT VARCHAR2(40) := 'Update PSE Billing Disputes External';

g_ACTION_PSE_INVOICE_DUE_DATE	CONSTANT VARCHAR2(32) := 'Update PSE Invoice Due Dates';
g_ACTION_PSE_INVOICE_LINE_ITEM	CONSTANT VARCHAR2(32) := 'Update PSE Invoice Line Items';
g_ACTION_PSE_BILL_STATUS		CONSTANT VARCHAR2(32) := 'Update PSE Billing Status';
g_ACTION_PSE_INVOICE_STATUS 	CONSTANT VARCHAR2(32) := 'Update PSE Invoice Status';
g_ACTION_PSE_INVOICE_HEADER 	CONSTANT VARCHAR2(32) := 'Update PSE Invoice Header';
g_ACTION_PSE_INVOICE_ATTCH   	CONSTANT VARCHAR2(32) := 'Update PSE Invoice Attachments';
g_ACTION_PSE_INVOICE_APPROVE 	CONSTANT VARCHAR2(32) := 'Approve PSE Invoice';
g_ACTION_PSE_INVOICE_SEND    	CONSTANT VARCHAR2(32) := 'Send PSE Invoice';

--Market Price actions
g_ACTION_MKT_PRICE_SELECT		CONSTANT VARCHAR2(32) := 'Select Market Price Data';
g_ACTION_MKT_PRICE_UPDATE		CONSTANT VARCHAR2(32) := 'Update Market Price Data';
g_ACTION_MKT_PRICE_LOCK_STATE	CONSTANT VARCHAR2(40) := 'Update Market Price Data Lock State';
--Other Security actions
g_ACTION_CALC_SECURITY		CONSTANT VARCHAR2(64) := 'Manage Calculation Process Security';
g_ACTION_MANAGE_MSGCODES	CONSTANT VARCHAR2(64) := 'Manage Message Definitions';
g_ACTION_MANAGE_USERS_ROLES	CONSTANT VARCHAR2(64) := 'Manage Users and Roles';
g_ACTION_MANAGE_ALL_CREDS	CONSTANT VARCHAR2(64) := 'Manage All Credentials';
g_ACTION_MANAGE_EMAIL_LOG	CONSTANT VARCHAR2(64) := 'Manage E-mail Log';
g_ACTION_UPDATE_RESTRICTED	CONSTANT VARCHAR2(64) := 'Update Restricted Data';
g_ACTION_APPLY_DATA_LOCK_GROUP CONSTANT VARCHAR2(64) := 'Apply Data Lock Group';
--Statement Type actions
g_ACTION_STATEMENT_TYPE_LIST CONSTANT VARCHAR2(32) := 'Select by Statement Type';
--Process Log actions
g_ACTION_SELECT_ALL_PROCESSES CONSTANT VARCHAR(32) := 'Select All Processes';
g_ACTION_SELECT_SESSIONS 	  CONSTANT VARCHAR(32) := 'Select Sessions';
g_ACTION_KILL_SESSION		  CONSTANT VARCHAR(32) := 'Kill Session';
g_ACTION_TERMINATE_ANY        CONSTANT VARCHAR(32) := 'Terminate Any Process';
g_ACTION_TRUNCATE_TRACE       CONSTANT VARCHAR(32) := 'Truncate Trace';
--Background Job actions
g_ACTION_MANAGE_ALL_JOBS      CONSTANT VARCHAR2(32) := 'Manage All Jobs';

--DR Billing Actions
g_ACTION_CALC_PROGRAM_BILLING CONSTANT VARCHAR2(40) := 'Calculate Program Billing Results';
g_ACTION_SELECT_PROG_BILLING CONSTANT VARCHAR2(40) := 'Select Program Billing Results';

--DER Aggregator/Disaggregator Actions
g_ACTION_UPDATE_EXT_DER_RST   CONSTANT VARCHAR2(32) := 'Update External DER Results';
g_ACTION_SELECT_DER_RESULTS	  CONSTANT VARCHAR2(32) := 'Select DER Results';
g_ACTION_ACCEPT_EXT_DER_RST	  CONSTANT VARCHAR2(32) := 'Accept External DER Results';

--DER Capability Report Actions
g_ACTION_SELECT_DER_RST_DET CONSTANT VARCHAR2(32) := 'Select DER Result Details';

--DER Capacity Forecasting
g_ACTION_RUN_DER_FORECAST     CONSTANT VARCHAR2(32) := 'Run Any DER Capacity Forecast';
--Schedule Management Mapping
g_ACTION_UPDATE_SCHED_MAN_MAP CONSTANT VARCHAR2(64) := 'Update Schedule Management Mapping';

--Set Incumbent Entity
g_ACTION_UPDATE_INCUMBENT_ENT CONSTANT VARCHAR2(32) := 'Updated Incumbent Entity';

--Financial Settlements
g_ACTION_RUN_ANY_FIN_SETTLEMNT CONSTANT VARCHAR2(32) := 'Run Any Financial Settlement';

-- ROML Import/Export
g_ACTION_ROML_PUB_SUB CONSTANT VARCHAR2(64) := 'ROML Publish/Subscribe';

-- CSB Bill Case
g_ACTION_BILL_CASE_EDIT CONSTANT VARCHAR2(32) := 'Bill Case Edit';
g_ACTION_BILL_CASE_VIEW CONSTANT VARCHAR2(32) := 'Bill Case View';

-- CSB Bill Case Manual Line Item
g_ACTION_BIL_CASE_MAN_LIN_EDIT CONSTANT VARCHAR2(64) := 'Bill Case Manual Line Item Edit';

-- Empty string literal is used in SYSTEM_REALM_COLUMN.COLUMN_VALS to indicate no
-- values are selected
c_EMPTY_COLUMN_VALS VARCHAR2(4) := '''''';

END SD;
/
