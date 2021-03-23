CREATE OR REPLACE PACKAGE EI IS
  --Revision $Revision: 1.5 $
  -- Purpose : Entity Identifier retrieval.
  -- Note: This package should be compiled before procedures or other packages that reference it.

FUNCTION WHAT_VERSION RETURN VARCHAR;

g_DEFAULT_IDENTIFIER_TYPE CONSTANT VARCHAR2(16) := 'Default';

FUNCTION GET_ENTITY_NAME
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2;

PROCEDURE GET_ENTITY_NAME
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

FUNCTION GET_ENTITY_ALIAS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2;

PROCEDURE GET_ENTITY_ALIAS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_ALIAS OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

FUNCTION GET_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2;

PROCEDURE GET_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_IDENTIFIER OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

FUNCTION GET_ENTITY_IDENTIFIER_EXTSYS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2;

PROCEDURE GET_ENTITY_IDENTIFIER_EXTSYS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_EXTERNAL_IDENTIFIER OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	);

FUNCTION GET_ID_FROM_NAME
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER;

PROCEDURE GET_ID_FROM_NAME
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

FUNCTION GET_ID_FROM_ALIAS
	(
	p_ENTITY_ALIAS IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER;

PROCEDURE GET_ID_FROM_ALIAS
	(
	p_ENTITY_ALIAS IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

FUNCTION GET_ID_FROM_IDENTIFIER
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER;

PROCEDURE GET_ID_FROM_IDENTIFIER
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	);

FUNCTION GET_ID_FROM_IDENTIFIER_EXTSYS
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER;

PROCEDURE GET_ID_FROM_IDENTIFIER_EXTSYS
	(
	p_EXTERNAL_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	);

FUNCTION GET_IDs_FROM_IDENTIFIER_EXTSYS
	(
	p_EXTERNAL_ID_PATTERN IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	) RETURN NUMBER_COLLECTION;

PROCEDURE GET_IDs_FROM_IDENTIFIER_EXTSYS
	(
	p_EXTERNAL_ID_PATTERN IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_ENTITY_IDs OUT NUMBER_COLLECTION,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	);

PROCEDURE PUT_EXTERNAL_SYSTEM_IDENTIFIER
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_OWNER_ENTITY_ID IN NUMBER,
	p_EXTERNAL_IDENTIFIER IN VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 := g_DEFAULT_IDENTIFIER_TYPE
	);

FUNCTION GET_ID_FROM_WS_IDENTIFIER
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	) RETURN NUMBER;

FUNCTION GET_IDs_FROM_WS_IDENTIFIERs
	(
	p_IDENTS STRING_COLLECTION,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	) RETURN NUMBER_COLLECTION;

FUNCTION GET_WS_IDENTIFIER_FROM_ID
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	) RETURN VARCHAR2;

PROCEDURE PUT_ENTITY_ALIAS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_ALIAS IN VARCHAR2
	);

PROCEDURE PUT_ENTITY_NAME
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2
	);

PROCEDURE PUT_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_IDENTIFIER IN VARCHAR2
	);

PROCEDURE PUT_WS_IDENTIFIER_FOR_ID
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	);

c_IDENTIFIED_BY_ID CONSTANT VARCHAR2(8) := 'ID';
c_IDENTIFIED_BY_NAME CONSTANT VARCHAR2(8) := 'NAME';
c_IDENTIFIED_BY_ALIAS CONSTANT VARCHAR2(8) := 'ALIAS';

END EI;
/
CREATE OR REPLACE PACKAGE BODY EI IS
---------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.5 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
FUNCTION GET_EXTERNAL_SYSTEM_NAME
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_NAME EXTERNAL_SYSTEM.EXTERNAL_SYSTEM_NAME%TYPE;
	v_ERROR_MESSAGE VARCHAR2(256);
BEGIN
	SELECT EXTERNAL_SYSTEM_NAME
	INTO v_NAME
	FROM EXTERNAL_SYSTEM
	WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;

	RETURN v_NAME;
EXCEPTION
	WHEN OTHERS THEN
		RETURN '(External System not defined for ID=' || p_EXTERNAL_SYSTEM_ID || ')';
END GET_EXTERNAL_SYSTEM_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_DOMAIN_NAME
	(
	p_ENTITY_DOMAIN_ID IN NUMBER
	) RETURN VARCHAR2 IS
	v_NAME ENTITY_DOMAIN.ENTITY_DOMAIN_NAME%TYPE;
	v_ERROR_MESSAGE VARCHAR2(256);
BEGIN
	SELECT ENTITY_DOMAIN_NAME
	INTO v_NAME
	FROM ENTITY_DOMAIN
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	RETURN v_NAME;
EXCEPTION
	WHEN OTHERS THEN
		RETURN '(Entity Domain not defined for ID=' || p_ENTITY_DOMAIN_ID || ')';
END GET_ENTITY_DOMAIN_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_NAME
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2 IS
v_SQL VARCHAR2(256);
v_RET VARCHAR2(512);
BEGIN
-- Get the Name of an Entity based on its ID.
	SELECT 'SELECT ' || PRIMARY_NAME_COLUMN
		|| ' FROM ' || ENTITY_DOMAIN_TABLE
		|| ' WHERE ' || PRIMARY_ID_COLUMN
		|| ' = ' || TO_CHAR(p_ENTITY_ID)
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL INTO v_RET;

	RETURN v_RET;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		IF p_QUIET = 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No Entity found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID) || ';ID=' || p_ENTITY_ID || '.');
		ELSE
			RETURN NULL;
		END IF;
END GET_ENTITY_NAME;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_NAME
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_NAME := GET_ENTITY_NAME(p_ENTITY_DOMAIN_ID, p_ENTITY_ID);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'No entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Id=' || p_ENTITY_ID || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Id=' || p_ENTITY_ID || '.';
END GET_ENTITY_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_ALIAS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2 IS
v_SQL VARCHAR2(256);
v_RET VARCHAR2(512);
BEGIN
-- Get the Alias of an Entity based on its ID.
	SELECT 'SELECT ' || PRIMARY_ALIAS_COLUMN
		|| ' FROM ' || ENTITY_DOMAIN_TABLE
		|| ' WHERE ' || PRIMARY_ID_COLUMN
		|| ' = ' || TO_CHAR(p_ENTITY_ID)
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL INTO v_RET;

	RETURN v_RET;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		IF p_QUIET = 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No Entity found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID) || ';ID=' || p_ENTITY_ID || '.');
		ELSE
			RETURN NULL;
		END IF;
END GET_ENTITY_ALIAS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_ALIAS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_ALIAS OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_ALIAS := GET_ENTITY_ALIAS(p_ENTITY_DOMAIN_ID, p_ENTITY_ID);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'No entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Id=' || p_ENTITY_ID || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Id=' || p_ENTITY_ID || '.';
END GET_ENTITY_ALIAS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2 IS
v_SQL VARCHAR2(256);
v_RET VARCHAR2(512);
BEGIN
	-- Get the External Identifier of an Entity based on its ID.
	-- If it doesn't even have an external identifier, return alias
	SELECT 'SELECT ' || NVL(PRIMARY_IDENT_COLUMN, PRIMARY_ALIAS_COLUMN)
		|| ' FROM ' || ENTITY_DOMAIN_TABLE
		|| ' WHERE ' || PRIMARY_ID_COLUMN
		|| ' = ' || TO_CHAR(p_ENTITY_ID)
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL INTO v_RET;

	RETURN v_RET;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		IF p_QUIET = 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No Entity found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID) || ';ID=' || p_ENTITY_ID || '.');
		ELSE
			RETURN NULL;
		END IF;
END GET_ENTITY_IDENTIFIER;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_IDENTIFIER OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_IDENTIFIER := GET_ENTITY_IDENTIFIER(p_ENTITY_DOMAIN_ID, p_ENTITY_ID);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'No entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Id=' || p_ENTITY_ID || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Id=' || p_ENTITY_ID || '.';
END GET_ENTITY_IDENTIFIER;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ENTITY_IDENTIFIER_EXTSYS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN VARCHAR2 IS
v_RET VARCHAR2(512);
BEGIN
-- Get the Identifier for an Entity based on its ID for a given External System and Identifier Type.
-- If one is not found, check for an Identifier for the External System and a Default Identifier Type.
-- If that is not found, just check for an Identifier on the Entity itself.

	SELECT EXTERNAL_IDENTIFIER
	INTO v_RET
	FROM EXTERNAL_SYSTEM_IDENTIFIER
	WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND ENTITY_ID = p_ENTITY_ID
		AND IDENTIFIER_TYPE = p_IDENTIFIER_TYPE;

	RETURN v_RET;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		-- Try looking for an actual identifier on the entity if we don't find a default identifier
		IF p_IDENTIFIER_TYPE = g_DEFAULT_IDENTIFIER_TYPE THEN
			RETURN GET_ENTITY_IDENTIFIER(p_ENTITY_DOMAIN_ID, p_ENTITY_ID, p_QUIET);
		-- Try looking for a default identifier if this special identifier type was found.
		ELSE
			RETURN GET_ENTITY_IDENTIFIER_EXTSYS(p_ENTITY_DOMAIN_ID, p_ENTITY_ID, p_EXTERNAL_SYSTEM_ID, g_DEFAULT_IDENTIFIER_TYPE, p_QUIET);
		END IF;
END GET_ENTITY_IDENTIFIER_EXTSYS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ENTITY_IDENTIFIER_EXTSYS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_EXTERNAL_IDENTIFIER OUT VARCHAR2,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_EXTERNAL_IDENTIFIER := GET_ENTITY_IDENTIFIER_EXTSYS(p_ENTITY_DOMAIN_ID, p_ENTITY_ID, p_EXTERNAL_SYSTEM_ID, p_IDENTIFIER_TYPE);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE :=
			'No entity was found for '
			||'External System=' || GET_EXTERNAL_SYSTEM_NAME(p_EXTERNAL_SYSTEM_ID)
			|| ';Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier Type=' || p_IDENTIFIER_TYPE
			|| ';Id=' || p_ENTITY_ID || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			||'External System=' || GET_EXTERNAL_SYSTEM_NAME(p_EXTERNAL_SYSTEM_ID)
			|| ';Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier Type=' || p_IDENTIFIER_TYPE
			|| ';Id=' || p_ENTITY_ID || '.';
END GET_ENTITY_IDENTIFIER_EXTSYS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ID_FROM_NAME
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER IS
	v_SQL VARCHAR2(256);
	v_RET NUMBER;
BEGIN
-- Get the ID of an Entity based on its Name.
	SELECT 'SELECT ' || PRIMARY_ID_COLUMN
		|| ' FROM ' || ENTITY_DOMAIN_TABLE
		|| ' WHERE ' || PRIMARY_NAME_COLUMN
		|| ' = ''' || REPLACE(p_ENTITY_NAME,'''','''''') || ''''
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL INTO v_RET;

	RETURN v_RET;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		IF p_QUIET = 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No Entity found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID) || ';Name=' || p_ENTITY_NAME || '.');
		ELSE
			RETURN NULL;
		END IF;
	WHEN TOO_MANY_ROWS THEN
		ERRS.RAISE(MSGCODES.c_ERR_TOO_MANY_ENTRIES,'More than one entity was found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
				|| ';Name=' || p_ENTITY_NAME ||'.');
END GET_ID_FROM_NAME;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ID_FROM_NAME
	(
	p_ENTITY_NAME IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_ID := GET_ID_FROM_NAME(p_ENTITY_NAME,p_ENTITY_DOMAIN_ID);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'No entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Name=' || p_ENTITY_NAME || '.';
	WHEN MSGCODES.e_ERR_TOO_MANY_ENTRIES THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'More than one entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Name=' || p_ENTITY_NAME || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Name=' || p_ENTITY_NAME || '.';
END GET_ID_FROM_NAME;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ID_FROM_ALIAS
	(
	p_ENTITY_ALIAS IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER IS
	v_SQL VARCHAR2(256);
	v_RET NUMBER;
BEGIN
-- Get the ID of an Entity based on its Name.
	SELECT 'SELECT ' || PRIMARY_ID_COLUMN
		|| ' FROM ' || ENTITY_DOMAIN_TABLE
		|| ' WHERE ' || PRIMARY_ALIAS_COLUMN
		|| ' = ''' || REPLACE(p_ENTITY_ALIAS,'''','''''') || ''''
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL INTO v_RET;

	RETURN v_RET;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		IF p_QUIET = 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No Entity found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID) || ';Alias=' || p_ENTITY_ALIAS || '.');
		ELSE
			RETURN NULL;
		END IF;
	WHEN TOO_MANY_ROWS THEN
		ERRS.RAISE(MSGCODES.c_ERR_TOO_MANY_ENTRIES,'More than one entity was found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
				|| ';Alias=' || p_ENTITY_ALIAS||'.');
END GET_ID_FROM_ALIAS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ID_FROM_ALIAS
	(
	p_ENTITY_ALIAS IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_ID := GET_ID_FROM_ALIAS(p_ENTITY_ALIAS,p_ENTITY_DOMAIN_ID);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'No entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Alias=' || p_ENTITY_ALIAS || '.';
	WHEN MSGCODES.e_ERR_TOO_MANY_ENTRIES THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'More than one entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Alias=' || p_ENTITY_ALIAS || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Alias=' || p_ENTITY_ALIAS || '.';
END GET_ID_FROM_ALIAS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ID_FROM_IDENTIFIER
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER IS
	v_SQL VARCHAR2(256);
	v_RET NUMBER;
	v_PRIMARY_IDENT_COLUMN VARCHAR(30);
BEGIN
	-- Get the ID of an Entity based on its External Identifier
	-- If it doesn't even have an external identifier, fall back to alias
	SELECT 'SELECT ' || PRIMARY_ID_COLUMN
		|| ' FROM ' || ENTITY_DOMAIN_TABLE
		|| ' WHERE ' || NVL(PRIMARY_IDENT_COLUMN, PRIMARY_ALIAS_COLUMN)
		|| ' = ''' || REPLACE(p_ENTITY_IDENTIFIER,'''','''''') || ''''
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL INTO v_RET;

	RETURN v_RET;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		IF p_QUIET = 0 THEN
			ERRS.RAISE(MSGCODES.c_ERR_NO_SUCH_ENTRY,'No Entity found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID) || ';Identifier=' || p_ENTITY_IDENTIFIER || '.');
		ELSE
			RETURN NULL;
		END IF;
	WHEN TOO_MANY_ROWS THEN
		ERRS.RAISE(MSGCODES.c_ERR_TOO_MANY_ENTRIES,'More than one entity was found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
				|| ';Identifier=' || p_ENTITY_IDENTIFIER || '.');
END GET_ID_FROM_IDENTIFIER;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ID_FROM_IDENTIFIER
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_ID := GET_ID_FROM_IDENTIFIER(p_ENTITY_IDENTIFIER,p_ENTITY_DOMAIN_ID);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'No entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier=' || p_ENTITY_IDENTIFIER || '.';
	WHEN MSGCODES.e_ERR_TOO_MANY_ENTRIES THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'More than one entity was found for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier=' || p_ENTITY_IDENTIFIER || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			|| 'Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier=' || p_ENTITY_IDENTIFIER || '.';
END GET_ID_FROM_IDENTIFIER;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ID_FROM_IDENTIFIER_EXTSYS
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE,
	p_QUIET IN NUMBER DEFAULT 0
	) RETURN NUMBER IS
	v_RET NUMBER;
BEGIN
-- Get the ID of an Entity based on its Identifier of a given type in a given External System.
-- If none is found, get the ID based on the Default Identifier in the given External System.
-- If none is found, get the ID based on the Entity Identifier of the Entity itself.

	SELECT ENTITY_ID
	INTO v_RET
	FROM EXTERNAL_SYSTEM_IDENTIFIER
	WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND IDENTIFIER_TYPE = p_IDENTIFIER_TYPE
		AND EXTERNAL_IDENTIFIER = p_ENTITY_IDENTIFIER;

	RETURN v_RET;

EXCEPTION
	WHEN NO_DATA_FOUND THEN
		IF p_IDENTIFIER_TYPE = g_DEFAULT_IDENTIFIER_TYPE THEN
			RETURN GET_ID_FROM_IDENTIFIER(p_ENTITY_IDENTIFIER, p_ENTITY_DOMAIN_ID, p_QUIET);
		ELSE
			RETURN GET_ID_FROM_IDENTIFIER_EXTSYS(p_ENTITY_IDENTIFIER, p_ENTITY_DOMAIN_ID, p_EXTERNAL_SYSTEM_ID, g_DEFAULT_IDENTIFIER_TYPE, p_QUIET);
		END IF;
	WHEN TOO_MANY_ROWS THEN
		ERRS.RAISE(MSGCODES.c_ERR_TOO_MANY_ENTRIES,'More than one entity was found for Entity Domain='
				|| GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
				|| ';Identifier=' || p_ENTITY_IDENTIFIER
				|| ';Identifier Type=' || p_IDENTIFIER_TYPE ||'.');
END GET_ID_FROM_IDENTIFIER_EXTSYS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_ID_FROM_IDENTIFIER_EXTSYS
	(
	p_EXTERNAL_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_ENTITY_ID OUT NUMBER,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_ID := GET_ID_FROM_IDENTIFIER_EXTSYS(p_EXTERNAL_IDENTIFIER,p_ENTITY_DOMAIN_ID,p_EXTERNAL_SYSTEM_ID,p_IDENTIFIER_TYPE);

EXCEPTION
	WHEN MSGCODES.e_ERR_NO_SUCH_ENTRY THEN
		p_STATUS := SQLCODE;
		p_MESSAGE :=
			'No entity was found for '
			||'External System=' || GET_EXTERNAL_SYSTEM_NAME(p_EXTERNAL_SYSTEM_ID)
			|| ';Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier Type=' || p_IDENTIFIER_TYPE
			|| ';Identifier=' || p_EXTERNAL_IDENTIFIER || '.';
	WHEN MSGCODES.e_ERR_TOO_MANY_ENTRIES THEN
		p_STATUS := SQLCODE;
		p_MESSAGE :=
			'More than one entity was found for '
			||'External System=' || GET_EXTERNAL_SYSTEM_NAME(p_EXTERNAL_SYSTEM_ID)
			|| ';Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier Type=' || p_IDENTIFIER_TYPE
			|| ';Identifier=' || p_EXTERNAL_IDENTIFIER || '.';
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			||'External System=' || GET_EXTERNAL_SYSTEM_NAME(p_EXTERNAL_SYSTEM_ID)
			|| ';Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier Type=' || p_IDENTIFIER_TYPE
			|| ';Identifier=' || p_EXTERNAL_IDENTIFIER || '.';
END GET_ID_FROM_IDENTIFIER_EXTSYS;
---------------------------------------------------------------------------------------------------
FUNCTION GET_IDs_FROM_IDENTIFIER_EXTSYS
	(
	p_EXTERNAL_ID_PATTERN IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	) RETURN NUMBER_COLLECTION IS
v_RET NUMBER_COLLECTION;
BEGIN
-- Get the ID of an Entity based on its Identifier of a given type in a given External System.
-- If none is found, get the ID based on the Default Identifier in the given External System.
-- If none is found, get the ID based on the Entity Identifier of the Entity itself.

	SELECT ENTITY_ID
	BULK COLLECT INTO v_RET
	FROM EXTERNAL_SYSTEM_IDENTIFIER
	WHERE EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID
		AND ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
		AND IDENTIFIER_TYPE = p_IDENTIFIER_TYPE
		AND EXTERNAL_IDENTIFIER LIKE p_EXTERNAL_ID_PATTERN;

	RETURN v_RET;
END GET_IDs_FROM_IDENTIFIER_EXTSYS;
---------------------------------------------------------------------------------------------------
PROCEDURE GET_IDs_FROM_IDENTIFIER_EXTSYS
	(
	p_EXTERNAL_ID_PATTERN IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_ENTITY_IDs OUT NUMBER_COLLECTION,
	p_STATUS OUT NUMBER,
	p_MESSAGE OUT VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 DEFAULT g_DEFAULT_IDENTIFIER_TYPE
	) AS
BEGIN
	p_STATUS := GA.SUCCESS;

	p_ENTITY_IDs := GET_IDs_FROM_IDENTIFIER_EXTSYS(p_EXTERNAL_ID_PATTERN,p_ENTITY_DOMAIN_ID,p_EXTERNAL_SYSTEM_ID,p_IDENTIFIER_TYPE);

EXCEPTION
	WHEN OTHERS THEN
		p_STATUS := SQLCODE;
		p_MESSAGE := 'Exception ' || SQLCODE || ':' || SQLERRM || ' occurred when searching for '
			||'External System=' || GET_EXTERNAL_SYSTEM_NAME(p_EXTERNAL_SYSTEM_ID)
			|| ';Entity Domain=' || GET_ENTITY_DOMAIN_NAME(p_ENTITY_DOMAIN_ID)
			|| ';Identifier Type=' || p_IDENTIFIER_TYPE
			|| ';Identifier Pattern=' || p_EXTERNAL_ID_PATTERN || '.';
END GET_IDs_FROM_IDENTIFIER_EXTSYS;
----------------------------------------------------------------------------------------------------
PROCEDURE PUT_EXTERNAL_SYSTEM_IDENTIFIER
	(
	p_EXTERNAL_SYSTEM_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_OWNER_ENTITY_ID IN NUMBER,
	p_EXTERNAL_IDENTIFIER IN VARCHAR2,
	p_IDENTIFIER_TYPE IN VARCHAR2 := g_DEFAULT_IDENTIFIER_TYPE
	) AS
BEGIN
	IF p_EXTERNAL_IDENTIFIER IS NULL THEN
    -- CLEAR AN EXISTING ENTRY
      DELETE EXTERNAL_SYSTEM_IDENTIFIER
      WHERE
         ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
         AND ENTITY_ID = p_OWNER_ENTITY_ID
         AND IDENTIFIER_TYPE = p_IDENTIFIER_TYPE
         AND EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;
	ELSE
    -- UPDATE AN EXISTING RECORD
      UPDATE EXTERNAL_SYSTEM_IDENTIFIER A
      SET
         A.EXTERNAL_IDENTIFIER = p_EXTERNAL_IDENTIFIER
      WHERE
         A.ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID
         AND A.ENTITY_ID = p_OWNER_ENTITY_ID
         AND A.IDENTIFIER_TYPE = p_IDENTIFIER_TYPE
         AND A.EXTERNAL_SYSTEM_ID = p_EXTERNAL_SYSTEM_ID;

    -- IF THE PREVIOUS UPDATE DID NOT FIND A MATCH, THEN INSERT A NEW RECORD.
    	IF SQL%NOTFOUND THEN
    		INSERT INTO EXTERNAL_SYSTEM_IDENTIFIER(
        		EXTERNAL_SYSTEM_ID,
                ENTITY_DOMAIN_ID,
                ENTITY_ID,
                IDENTIFIER_TYPE,
                EXTERNAL_IDENTIFIER,
                ENTRY_DATE)
    		VALUES (
          		p_EXTERNAL_SYSTEM_ID,
    			p_ENTITY_DOMAIN_ID,
    			p_OWNER_ENTITY_ID,
    			p_IDENTIFIER_TYPE,
    			p_EXTERNAL_IDENTIFIER,
    			SYSDATE);
    	END IF;
	END IF;

END PUT_EXTERNAL_SYSTEM_IDENTIFIER;
---------------------------------------------------------------------------------------------------
FUNCTION GET_ID_FROM_WS_IDENTIFIER
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	) RETURN NUMBER IS
v_ENTITY_ID NUMBER;
v_EXTERNAL_SYSTEM_ID NUMBER;
BEGIN

	IF p_IDENTIFIED_BY IS NULL THEN
		--The default behavior is to use the EXTERNAL_IDENTIFIER if one exists, otherwise use alias
		v_ENTITY_ID := GET_ID_FROM_IDENTIFIER(p_ENTITY_IDENTIFIER, p_ENTITY_DOMAIN_ID);
	ELSIF p_IDENTIFIED_BY = c_IDENTIFIED_BY_NAME THEN
		v_ENTITY_ID := GET_ID_FROM_NAME(p_ENTITY_IDENTIFIER, p_ENTITY_DOMAIN_ID);
	ELSIF p_IDENTIFIED_BY = c_IDENTIFIED_BY_ID THEN
		v_ENTITY_ID := TO_NUMBER(p_ENTITY_IDENTIFIER);
	ELSIF p_IDENTIFIED_BY = c_IDENTIFIED_BY_ALIAS THEN
		v_ENTITY_ID := GET_ID_FROM_ALIAS(p_ENTITY_IDENTIFIER, p_ENTITY_DOMAIN_ID);
	ELSE
		-- Assume that the p_IDENTIFIED_BY parameter is the name of an EXTERNAL_SYSTEM
		-- The one exception case is when the p_ENTITY_DOMAIN is EXTERNAL_SYSTEM. In this case we just use NAME.
		IF p_ENTITY_DOMAIN_ID = EC.ED_EXTERNAL_SYSTEM THEN
			v_ENTITY_ID := GET_ID_FROM_NAME(p_ENTITY_IDENTIFIER, EC.ED_EXTERNAL_SYSTEM);
		ELSE
			v_EXTERNAL_SYSTEM_ID := GET_ID_FROM_NAME(p_IDENTIFIED_BY, EC.ED_EXTERNAL_SYSTEM);
			v_ENTITY_ID := EI.GET_ID_FROM_IDENTIFIER_EXTSYS(p_ENTITY_IDENTIFIER, p_ENTITY_DOMAIN_ID, v_EXTERNAL_SYSTEM_ID);
		END IF;
	END IF;

	RETURN v_ENTITY_ID;
END GET_ID_FROM_WS_IDENTIFIER;
---------------------------------------------------------------------------------------------------
FUNCTION GET_IDs_FROM_WS_IDENTIFIERs
	(
	p_IDENTS STRING_COLLECTION,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	) RETURN NUMBER_COLLECTION AS
v_IDS NUMBER_COLLECTION;
BEGIN
	v_IDS := NUMBER_COLLECTION();
	FOR v_IDX IN p_IDENTS.FIRST..p_IDENTS.LAST LOOP
		v_IDS.EXTEND();
		v_IDS(v_IDX) := EI.GET_ID_FROM_WS_IDENTIFIER(p_IDENTS(v_IDX), p_ENTITY_DOMAIN_ID, p_IDENTIFIED_BY);
	END LOOP;
	RETURN v_IDS;
END GET_IDs_FROM_WS_IDENTIFIERs;
---------------------------------------------------------------------------------------------------
FUNCTION GET_WS_IDENTIFIER_FROM_ID
	(
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	) RETURN VARCHAR2 IS
v_WS_IDENTIFIER VARCHAR2(4000);
BEGIN

	IF p_IDENTIFIED_BY IS NULL THEN
		v_WS_IDENTIFIER := GET_ENTITY_IDENTIFIER(p_ENTITY_DOMAIN_ID, p_ENTITY_ID);
	ELSIF p_IDENTIFIED_BY = c_IDENTIFIED_BY_ID THEN
		v_WS_IDENTIFIER := p_ENTITY_ID;
	ELSIF p_IDENTIFIED_BY = c_IDENTIFIED_BY_ALIAS THEN
		v_WS_IDENTIFIER := GET_ENTITY_ALIAS(p_ENTITY_DOMAIN_ID, p_ENTITY_ID);
	ELSIF p_IDENTIFIED_BY = c_IDENTIFIED_BY_NAME THEN
		v_WS_IDENTIFIER := GET_ENTITY_NAME(p_ENTITY_DOMAIN_ID, p_ENTITY_ID);
	ELSE
		v_WS_IDENTIFIER := GET_ENTITY_IDENTIFIER_EXTSYS(p_ENTITY_DOMAIN_ID, p_ENTITY_ID, p_IDENTIFIED_BY);
	END IF;

	RETURN v_WS_IDENTIFIER;

END GET_WS_IDENTIFIER_FROM_ID;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_ENTITY_ALIAS
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_ALIAS IN VARCHAR2
	) IS
v_SQL VARCHAR2(512);
BEGIN
	SELECT 'UPDATE ' || ENTITY_DOMAIN_TABLE
		|| ' SET ' || PRIMARY_ALIAS_COLUMN
		|| ' = ''' || REPLACE(p_ENTITY_ALIAS,'''','''''') || ''''
		|| ' WHERE ' || PRIMARY_ID_COLUMN
		|| ' = ' || TO_CHAR(p_ENTITY_ID)
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL;

END PUT_ENTITY_ALIAS;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_ENTITY_NAME
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_NAME IN VARCHAR2
	) IS
v_SQL VARCHAR2(512);
BEGIN
	SELECT 'UPDATE ' || ENTITY_DOMAIN_TABLE
		|| ' SET ' || PRIMARY_NAME_COLUMN
		|| ' = ''' || REPLACE(p_ENTITY_NAME,'''','''''') || ''''
		|| ' WHERE ' || PRIMARY_ID_COLUMN
		|| ' = ' || TO_CHAR(p_ENTITY_ID)
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY E
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL;

END PUT_ENTITY_NAME;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_ENTITY_IDENTIFIER
	(
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_IDENTIFIER IN VARCHAR2
	) IS
v_SQL VARCHAR2(512);
BEGIN
	SELECT 'UPDATE ' || ENTITY_DOMAIN_TABLE
		|| ' SET ' || NVL(PRIMARY_IDENT_COLUMN, PRIMARY_ALIAS_COLUMN)
		|| ' = ''' || REPLACE(p_ENTITY_IDENTIFIER,'''','''''') || ''''
		|| ' WHERE ' || PRIMARY_ID_COLUMN
		|| ' = ' || TO_CHAR(p_ENTITY_ID)
	INTO v_SQL
	FROM ENTITY_DOMAIN_PROPERTY E
	WHERE ENTITY_DOMAIN_ID = p_ENTITY_DOMAIN_ID;

	EXECUTE IMMEDIATE v_SQL;

END PUT_ENTITY_IDENTIFIER;
---------------------------------------------------------------------------------------------------
PROCEDURE PUT_WS_IDENTIFIER_FOR_ID
	(
	p_ENTITY_IDENTIFIER IN VARCHAR2,
	p_ENTITY_ID IN NUMBER,
	p_ENTITY_DOMAIN_ID IN NUMBER,
	p_IDENTIFIED_BY IN VARCHAR2
	) IS
BEGIN
	IF (p_IDENTIFIED_BY IS NULL OR NOT p_IDENTIFIED_BY = c_IDENTIFIED_BY_ID) AND p_ENTITY_IDENTIFIER IS NOT NULL THEN
		IF p_IDENTIFIED_BY = c_IDENTIFIED_BY_ALIAS THEN
			PUT_ENTITY_ALIAS(p_ENTITY_DOMAIN_ID, p_ENTITY_ID, p_ENTITY_IDENTIFIER);
		ELSIF p_IDENTIFIED_BY = c_IDENTIFIED_BY_NAME THEN
			PUT_ENTITY_NAME(p_ENTITY_DOMAIN_ID, p_ENTITY_ID, p_ENTITY_IDENTIFIER);
		ELSIF p_IDENTIFIED_BY IS NULL THEN
			PUT_ENTITY_IDENTIFIER(p_ENTITY_DOMAIN_ID, p_ENTITY_ID, p_ENTITY_IDENTIFIER);
		ELSE
			PUT_EXTERNAL_SYSTEM_IDENTIFIER(p_IDENTIFIED_BY,
				p_ENTITY_DOMAIN_ID,
				p_ENTITY_ID,
				p_ENTITY_IDENTIFIER);
		END IF;
	END IF;
END PUT_WS_IDENTIFIER_FOR_ID;
---------------------------------------------------------------------------------------------------
END EI;
/
