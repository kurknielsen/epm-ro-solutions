CREATE OR REPLACE PACKAGE FML_UTIL IS
--Revision $Revision: 1.5 $

  -- Author  : JHUMPHRIES
  -- Created : 1/21/2008 9:16:44 AM
  -- Purpose : Utility functions (Currently only one) for text-substitution-based formula re-writing

c_MAX_ITERATORS CONSTANT BINARY_INTEGER := 10;
TYPE ITERATOR_DEPENDS IS TABLE OF PLS_INTEGER INDEX BY VARCHAR2(64);

c_SINGLE_ITER_NODEPENDS CONSTANT PLS_INTEGER := 0;
TYPE SINGLE_ITER_DEPENDS IS VARRAY(10) OF PLS_INTEGER;
c_SINGLE_ITER_DEPENDS CONSTANT SINGLE_ITER_DEPENDS := SINGLE_ITER_DEPENDS(1,2,4,8,16,32,64,128,256,512);

-- Constants for the valid values of the  p_PLSQL_BLOCK parameter in REBUILD_FORMULA
c_PLSQL_NO		CONSTANT PLS_INTEGER := 0;
c_PLSQL_YES		CONSTANT PLS_INTEGER := 1;
c_PLSQL_MULTI	CONSTANT PLS_INTEGER := 2;

FUNCTION WHAT_VERSION RETURN VARCHAR2;

/**
 * Determines if a value needs to be re-evaluated. This will perform a bitwise AND on
 * the mask of iterators on which p_NAME depends and the mask p_CHANGED_ITERATORS which
 * encodes which values have changed. If the result is non-zero then iterators on which
 * this value depends have changed.
 */
FUNCTION DEPENDS_CHANGED
	(
	p_ITERATOR_ID IN PLS_INTEGER,
	p_CHANGED_ITERATORS IN PLS_INTEGER,
	p_ITERATOR_DEPENDS IN ITERATOR_DEPENDS,
	p_NAME IN VARCHAR2
	) RETURN BOOLEAN;

/**
 * Combines dependencies. This performs a bitwise OR operation so that the returned mask
 * encodes a dependency on all iterators on which the parameter masks depend.
 */
FUNCTION COMBINE_DEPENDS
	(
	p_DEPENDS1 IN PLS_INTEGER,
	p_DEPENDS2 IN PLS_INTEGER
	) RETURN PLS_INTEGER;

/**
 * Rewrites a formula, substituting values from the current run-time context in place of
 * recognized identifiers. Identifier references can be simple name references, or in a
 * more formal syntax – ${name} – which allows the use of whitespace characters in the
 * identifier. The calling procedure can indicate that only the formal syntax is
 * supported.
 * @param p_FORMULA			 The formula, expression, or PL/SQL block to re-write.
 * @param p_VARIABLE_CACHE	 A map of identifiers and their corresponding values. Its
 *							 use is strictly read-only, but it is defined as IN OUT
 *							 NOCOPY for performance.
 * @param p_ITERATOR_DEPENDS A structure that has information on the dependencies of
 *							 identifiers on iterator values.
 * @param p_ITERATORS		 The iterator values on which p_FORMULA depends
 * @param p_RESULT			 The re-written formula
 * @param p_REQUIRE_FORMAL	 A flag indicating that valid identifier references must be
 *							 in the formal syntax (with curly braces) or must be to
 *							 identifiers whose names begin with a colon.
 * @param p_CASE_SENSITIVE	 A flag indicating that identifier references are case-
 *							 sensitive. If it is false then all names/keys in
 *							 p_VARIABLE_CACHE must be upper-case.
 * @param p_PLSQL_BLOCK		 A flag indicating whether p_FORMULA is a PL/SQL block. A
 *							 value of zero means it is a normal SQL expression. A value
 *							 of 1 indicates that it is a PL/SQL expression with a single
 *							 return value. A value of 2 indicates that it is a PL/SQL
 *							 expression with multiple return values.
 * @param p_TREAT_DOT_AS_FIELD_OR_METHOD A flag indicating whether dots/periods (.) should
 *  			be treated as part of an identifier or as an indicator of field/method
 *				access. If the formula being translated will result in PL/SQL code, this
 *				should likely be set to TRUE.
 */
PROCEDURE REBUILD_FORMULA
	(
	p_FORMULA 			IN VARCHAR2,
	p_VARIABLE_CACHE 	IN OUT NOCOPY UT.STRING_MAP,
	p_ITERATOR_DEPENDS 	IN ITERATOR_DEPENDS,
	p_ITERATORS 		OUT PLS_INTEGER,
	p_RESULT			OUT VARCHAR2,
	p_REQUIRE_FORMAL	IN BOOLEAN := FALSE,
	p_CASE_SENSITIVE	IN BOOLEAN := TRUE,
	p_PLSQL_BLOCK		IN PLS_INTEGER := c_PLSQL_NO,
	p_TREAT_DOT_AS_FIELD_OR_METHOD IN BOOLEAN := FALSE
    );

/**
 * This function is the same as the above procedure except that it ignores tracking
 * iterator dependencies. Since this means there is only one output value instead of two, it
 * is a function that returns that output (instead of a procedure with OUT parameter)
 */
FUNCTION REBUILD_FORMULA
	(
	p_FORMULA 			IN VARCHAR2,
	p_VARIABLE_CACHE 	IN OUT NOCOPY UT.STRING_MAP,
	p_REQUIRE_FORMAL	IN BOOLEAN := FALSE,
	p_CASE_SENSITIVE	IN BOOLEAN := TRUE,
	p_PLSQL_BLOCK		IN PLS_INTEGER := c_PLSQL_NO,
	p_TREAT_DOT_AS_FIELD_OR_METHOD IN BOOLEAN := FALSE
    ) RETURN VARCHAR2;

/**
 * This procedure logs the contents of an ITERATOR_DEPENDS as "Debug Detail".
 * The optional p_INFO parameter can be specified to show up as an additional label in the log.
 */
PROCEDURE LOG_ITERATOR_DEPENDS
	(
	p_ITERATOR_DEPENDS IN ITERATOR_DEPENDS,
	p_INFO IN VARCHAR2 DEFAULT NULL
	);

END FML_UTIL;
/
CREATE OR REPLACE PACKAGE BODY FML_UTIL IS
----------------------------------------------------------------------------------------------------
g_LOG_API_NAMES UT.STRING_MAP; -- initialized so that keys are the names of the LOG* and ALERT*
							   -- functions in the CALC_ENGINE package
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN '$Revision: 1.5 $';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
FUNCTION DEPENDS_CHANGED
	(
	p_ITERATOR_ID IN PLS_INTEGER,
	p_CHANGED_ITERATORS IN PLS_INTEGER,
	p_ITERATOR_DEPENDS IN ITERATOR_DEPENDS,
	p_NAME IN VARCHAR2
	) RETURN BOOLEAN IS
BEGIN
	IF p_ITERATOR_ID <= 1 THEN
		-- if this is the first iterator or there are no iterators, return
		-- true so that values always get evaluated
		RETURN TRUE;
	END IF;
	IF p_CHANGED_ITERATORS IS NULL THEN
		RETURN TRUE; -- no iterators? then all values are re-queried/calculated
	END IF;
	IF p_ITERATOR_DEPENDS.EXISTS(p_NAME) THEN
		-- Bitwise AND to see if any iterator that changed matches one on which this
		-- value depends
		RETURN BITAND(p_CHANGED_ITERATORS, p_ITERATOR_DEPENDS(p_NAME)) <> 0;
	ELSE
		-- name not in map? then it hasn't been evaluated - so do so now
		RETURN TRUE;
	END IF;
END DEPENDS_CHANGED;
---------------------------------------------------------------------------------------------------
FUNCTION COMBINE_DEPENDS
	(
	p_DEPENDS1 IN PLS_INTEGER,
	p_DEPENDS2 IN PLS_INTEGER
	) RETURN PLS_INTEGER IS
BEGIN
	-- bitwise OR operation
	RETURN p_DEPENDS1 - BITAND(p_DEPENDS1,p_DEPENDS2) + p_DEPENDS2;
END COMBINE_DEPENDS;
----------------------------------------------------------------------------------------------------
/**
 * Rewrites a formula, substituting values from the current run-time context in place of
 * recognized identifiers. Identifier references can be simple name references, or in a
 * more formal syntax – ${name} – which allows the use of whitespace characters in the
 * identifier. The calling procedure can indicate that only the formal syntax is
 * supported.
 * @param p_FORMULA		The formula, expression, or PL/SQL block to re-write.
 * @param p_VARIABLE_CACHE	A map of identifiers and their corresponding values. Its
 *				use is strictly read-only, but it is defined as IN OUT
 *				NOCOPY for performance.
 * @param p_ITERATOR_DEPENDS	A structure that has information on the dependencies of
 *				identifiers on iterator values.
 * @param p_ITERATORS		The iterator values on which p_FORMULA depends
 * @param p_RESULT		The re-written formula
 * @param p_REQUIRE_FORMAL	A flag indicating that valid identifier references must be
 *				in the formal syntax (with curly braces) or must be to
 *				identifiers whose names begin with a colon.
 * @param p_CASE_SENSITIVE	A flag indicating that identifier references are case-
 *				sensitive. If it is false then all names/keys in
 *				p_VARIABLE_CACHE must be upper-case.
 * @param p_PLSQL_BLOCK	A flag indicating whether p_FORMULA is a PL/SQL block. A
 *				value of zero means it is a normal SQL expression. A value
 *				of 1 indicates that it is a PL/SQL expression with a single
 *				return value. A value of 2 indicates that it is a PL/SQL
 *				expression with multiple return values.
 * @param p_TREAT_DOT_AS_FIELD_OR_METHOD A flag indicating whether dots/periods (.) should
 *  			be treated as part of an identifier or as an indicator of field/method
 *				access. If the formula being translated will result in PL/SQL code, this
 *				should likely be set to TRUE.
 */
PROCEDURE REBUILD_FORMULA
	(
	p_FORMULA 			IN VARCHAR2,
	p_VARIABLE_CACHE 	IN OUT NOCOPY UT.STRING_MAP,
	p_ITERATOR_DEPENDS 	IN ITERATOR_DEPENDS,
	p_ITERATORS 		OUT PLS_INTEGER,
	p_RESULT			OUT VARCHAR2,
	p_REQUIRE_FORMAL	IN BOOLEAN := FALSE,
	p_CASE_SENSITIVE	IN BOOLEAN := TRUE,
	p_PLSQL_BLOCK		IN PLS_INTEGER := c_PLSQL_NO,
	p_TREAT_DOT_AS_FIELD_OR_METHOD IN BOOLEAN := FALSE
    ) AS
v_FORMULA VARCHAR2(32767) := '';
v_CHAR CHAR(1);
v_TOKEN VARCHAR2(256) := '';
v_IDENT VARCHAR2(256);
v_BREAK BOOLEAN := TRUE;
v_BREAK_NEXT BOOLEAN := FALSE;
v_LAST_CHAR_DOLLAR BOOLEAN := FALSE;
v_IS_FORMAL_ID BOOLEAN := FALSE;
v_IS_ID BOOLEAN := FALSE;
v_IS_NUM BOOLEAN := FALSE;
v_IS_STR BOOLEAN := FALSE;
v_IS_QUOT BOOLEAN := FALSE;
v_CUR_OUTPUT_IDX PLS_INTEGER := 1;
v_ITERATORS PLS_INTEGER := c_SINGLE_ITER_NODEPENDS;

	PROCEDURE ADD_TOKEN_TO_REBUILT_FORMULA AS
	BEGIN
		-- if it is an ID, then substitute it if we have a value for it
		IF v_IS_ID AND g_LOG_API_NAMES.EXISTS(UPPER(v_TOKEN)) THEN
			-- prefix log API names so they resolve to correct package reference
			v_TOKEN := 'CALC_ENGINE.'||v_TOKEN;
		ELSIF (v_IS_FORMAL_ID OR (v_IS_ID AND (NOT p_REQUIRE_FORMAL OR SUBSTR(v_TOKEN,1,1) = ':')))
			  -- if treating dots as field/method access and identifier starts with dot, then do
			  -- not re-write it since it represents a field/method name, not a variable that should
			  -- be rewritten.
		      AND (SUBSTR(v_TOKEN,1,1) <> '.' OR NOT p_TREAT_DOT_AS_FIELD_OR_METHOD) THEN
			-- we have a valid identifier that we will try to substitute if we have a value for it
			IF v_IS_FORMAL_ID THEN
				-- strip off "${" and "}"
				v_IDENT := SUBSTR(v_TOKEN,3,LENGTH(v_TOKEN)-3);
			ELSE
				v_IDENT := v_TOKEN;
			END IF;
			-- if case-insensitive, look for upper case names
			IF NOT p_CASE_SENSITIVE THEN
				v_IDENT := UPPER(v_IDENT);
			END IF;
			-- now get the value
			IF p_VARIABLE_CACHE.EXISTS(v_IDENT) THEN
				v_TOKEN := p_VARIABLE_CACHE(v_IDENT);
				-- prefix with a space if case cache contains a negative number:
				-- if cache has Y = -1 and formula is "0-Y", we don't want
				-- "0--1" because double-minus-sign indicates a comment
				IF SUBSTR(v_TOKEN,1,1) = '-' THEN
					v_TOKEN := ' '||v_TOKEN;
				END IF;
				-- update dependencies
				IF p_ITERATOR_DEPENDS.EXISTS(v_IDENT) THEN
					v_ITERATORS := COMBINE_DEPENDS(v_ITERATORS, p_ITERATOR_DEPENDS(v_IDENT));
				END IF;
			END IF;
		END IF;
		v_FORMULA := v_FORMULA||v_TOKEN;
	END ADD_TOKEN_TO_REBUILT_FORMULA;

BEGIN
	IF p_FORMULA IS NULL THEN
		p_ITERATORS := c_SINGLE_ITER_NODEPENDS; -- null formula depends on nothing
		RETURN; -- nothing to do
	END IF;

	FOR v_INDEX IN 1..LENGTH(p_FORMULA) LOOP
    	v_CHAR := SUBSTR(p_FORMULA,v_INDEX,1);

		-- "${" indicates the start of a formal identifier reference
		IF v_LAST_CHAR_DOLLAR THEN
			IF v_CHAR = '{' THEN
				v_LAST_CHAR_DOLLAR := FALSE;
				v_IS_FORMAL_ID := TRUE;
            	v_TOKEN := v_TOKEN||v_CHAR;
			ELSE
				v_BREAK := TRUE;
			END IF;
		-- formal identifier references end with "}"
		ELSIF v_IS_FORMAL_ID THEN
			IF v_BREAK_NEXT THEN
				v_BREAK := TRUE;
			ELSE
				IF v_CHAR = '}' THEN
					v_BREAK_NEXT := TRUE;
				END IF;
            	v_TOKEN := v_TOKEN||v_CHAR;
			END IF;
		-- other identifier references end with first invalid character
        ELSIF v_IS_ID THEN
        	IF (UPPER(v_CHAR) >= 'A' AND UPPER(v_CHAR) <= 'Z') OR (v_CHAR >= '0' AND v_CHAR <= '9')
					 -- don't allow dots in identifier if they indicate field/method access
             		 OR (v_CHAR = '.' AND NOT p_TREAT_DOT_AS_FIELD_OR_METHOD) OR v_CHAR = '_' THEN
            	v_TOKEN := v_TOKEN||v_CHAR;
			ELSE
            	v_BREAK := TRUE;
            END IF;
		-- numbers end with first invalid character
        ELSIF v_IS_NUM THEN
			IF (v_CHAR >= '0' AND v_CHAR <= '9') OR v_CHAR = '.' THEN
            	v_TOKEN := v_TOKEN||v_CHAR;
			ELSE
            	v_BREAK := TRUE;
            END IF;
		-- strings end with single quote: '
		ELSIF v_IS_STR THEN
        	IF v_BREAK_NEXT THEN
            	v_BREAK := TRUE;
			ELSE
	        	IF v_CHAR = '''' THEN
                	v_BREAK_NEXT := TRUE;
				END IF;
            	v_TOKEN := v_TOKEN||v_CHAR;
			END IF;
		-- quoted identifiers end with double quote: "
		ELSIF v_IS_QUOT THEN
        	IF v_BREAK_NEXT THEN
            	v_BREAK := TRUE;
			ELSE
	        	IF v_CHAR = '"' THEN
                	v_BREAK_NEXT := TRUE;
				END IF;
            	v_TOKEN := v_TOKEN||v_CHAR;
			END IF;
		-- append bind variable or local variable reference
		ELSIF v_CHAR = '?' AND p_PLSQL_BLOCK <> c_PLSQL_NO THEN
			IF p_PLSQL_BLOCK = c_PLSQL_MULTI THEN
				v_TOKEN := v_TOKEN||'l_var$'||v_CUR_OUTPUT_IDX;
				v_CUR_OUTPUT_IDX := v_CUR_OUTPUT_IDX+1;
			ELSE
				v_TOKEN := v_TOKEN||':result';
			END IF;
			v_BREAK := FALSE;
		-- otherwise
        ELSIF NOT v_BREAK THEN
            IF (UPPER(v_CHAR) >= 'A' AND UPPER(v_CHAR) <= 'Z') OR v_CHAR = '_' OR v_CHAR = ':'
               OR (v_CHAR >= '0' AND v_CHAR <= '9') OR v_CHAR = '.' OR v_CHAR = ''''
			   OR v_CHAR = '"' OR v_CHAR = '$' THEN
            	v_BREAK := TRUE;
			ELSE
            	v_TOKEN := v_TOKEN||v_CHAR;
            END IF;
        END IF;
        --break flag indicates we are starting a new token:
    	IF v_BREAK THEN
        	v_BREAK := FALSE;
            v_BREAK_NEXT := FALSE;

			ADD_TOKEN_TO_REBUILT_FORMULA;

        	v_TOKEN := v_CHAR;
			-- reset flags
			v_LAST_CHAR_DOLLAR := FALSE;
			v_IS_FORMAL_ID := FALSE;
			v_IS_ID := FALSE;
			v_IS_NUM := FALSE;
			v_IS_STR := FALSE;
			v_IS_QUOT := FALSE;
			-- determine the current token type
            IF (UPPER(v_CHAR) >= 'A' AND UPPER(v_CHAR) <= 'Z')
			   OR (v_CHAR = '.' AND p_TREAT_DOT_AS_FIELD_OR_METHOD)
			   OR v_CHAR = '_' OR v_CHAR = ':' THEN
			    -- if dots indicate field/method access, default to identifier for this token
				-- (which will represent field/method) - otherwise, default to number (below).
				v_IS_ID := TRUE;
			ELSIF (v_CHAR >= '0' AND v_CHAR <= '9') OR v_CHAR = '.' THEN
            	v_IS_NUM := TRUE;
			ELSIF v_CHAR = '$' THEN
                v_LAST_CHAR_DOLLAR := TRUE;
			ELSIF v_CHAR = '''' THEN
                v_IS_STR := TRUE;
            ELSIF v_CHAR = '"' THEN
                v_IS_QUOT := TRUE;
            END IF;
        END IF;
    END LOOP;

    --end of string? then finish processing final token
	ADD_TOKEN_TO_REBUILT_FORMULA;

	IF p_PLSQL_BLOCK <> c_PLSQL_NO THEN
		IF SUBSTR(v_FORMULA,-1,1) <> ';' THEN
			v_FORMULA := v_FORMULA||';';
		END IF;
		-- enclose in BEGIN ... END; and add local var references for multi-value PL/SQL expression
		DECLARE
			v_PREFIX VARCHAR2(32767);
			v_SUFFIX VARCHAR2(32767);
		BEGIN
			IF p_PLSQL_BLOCK = c_PLSQL_MULTI THEN
				-- include declarations
				IF v_CUR_OUTPUT_IDX > 1 THEN
					v_PREFIX := 'DECLARE ';
				END IF;
				-- end the block with the construction of a collection return value
				v_SUFFIX := ' :result := NUMBER_COLLECTION(';
				-- add the variable declarations and subsequent return value references
				FOR v_IDX IN 1..(v_CUR_OUTPUT_IDX-1) LOOP
					v_PREFIX := v_PREFIX||'l_var$'||v_IDX||' NUMBER; ';
					IF v_IDX > 1 THEN
						v_SUFFIX := v_SUFFIX||', ';
					END IF;
					v_SUFFIX := v_SUFFIX||'l_var$'||v_IDX;
				END LOOP;
				v_SUFFIX := v_SUFFIX||'); ';
			END IF;
			v_PREFIX := v_PREFIX||'BEGIN ';
			v_SUFFIX := v_SUFFIX||' END;';
			v_FORMULA := v_PREFIX||v_FORMULA||v_SUFFIX;
		END;
	END IF;

    -- done
	p_ITERATORS := v_ITERATORS;
	p_RESULT := v_FORMULA;
END REBUILD_FORMULA;
----------------------------------------------------------------------------------------------------
/**
 * This function is the same as the above procedure except that it ignores tracking
 * iterator dependencies. Since this means there is only one output value instead of two, it
 * is a function that returns that output (instead of a procedure with OUT parameter)
 */
FUNCTION REBUILD_FORMULA
	(
	p_FORMULA 			IN VARCHAR2,
	p_VARIABLE_CACHE 	IN OUT NOCOPY UT.STRING_MAP,
	p_REQUIRE_FORMAL	IN BOOLEAN := FALSE,
	p_CASE_SENSITIVE	IN BOOLEAN := TRUE,
	p_PLSQL_BLOCK		IN PLS_INTEGER := c_PLSQL_NO,
	p_TREAT_DOT_AS_FIELD_OR_METHOD IN BOOLEAN := FALSE
    ) RETURN VARCHAR2 IS
v_ITERATOR_DEPENDS ITERATOR_DEPENDS;
v_ITERATORS PLS_INTEGER;
v_RESULT VARCHAR2(32767);
BEGIN
	REBUILD_FORMULA(p_FORMULA, p_VARIABLE_CACHE,
					v_ITERATOR_DEPENDS, v_ITERATORS,
					v_RESULT, p_REQUIRE_FORMAL,
					p_CASE_SENSITIVE, p_PLSQL_BLOCK,
					p_TREAT_DOT_AS_FIELD_OR_METHOD);
	RETURN v_RESULT;
END REBUILD_FORMULA;
----------------------------------------------------------------------------------------------------
/**
 * This procedure logs the contents of an ITERATOR_DEPENDS as "Debug Detail".
 * The optional p_INFO parameter can be specified to show up as an additional label in the log.
 */
PROCEDURE LOG_ITERATOR_DEPENDS
	(
	p_ITERATOR_DEPENDS IN ITERATOR_DEPENDS,
	p_INFO IN VARCHAR2 DEFAULT NULL
	) AS
	v_NAME VARCHAR2(256);
BEGIN
	IF LOGS.IS_DEBUG_DETAIL_ENABLED THEN
		LOGS.LOG_DEBUG_DETAIL('----- Iterator Depends '||p_INFO||'---------');
		LOGS.LOG_DEBUG_DETAIL('name => depends');
		v_NAME := p_ITERATOR_DEPENDS.FIRST;
		WHILE v_NAME IS NOT NULL LOOP
			LOGS.LOG_DEBUG_DETAIL(v_NAME||' => '||p_ITERATOR_DEPENDS(v_NAME));
			v_NAME := p_ITERATOR_DEPENDS.NEXT(v_NAME);
		END LOOP;
		LOGS.LOG_DEBUG_DETAIL('----- End Iterator Depends '||p_INFO||'---------');
	END IF;
END;
---------------------------------------------------------------------------------------------------
BEGIN
	-- Rvalue is just a dummy value - we are mainly interested in the keys. We are using a
	-- hash table (table index by varchar) to model a set
	g_LOG_API_NAMES('LOG_FATAL') := '*';
	g_LOG_API_NAMES('LOG_ERROR') := '*';
	g_LOG_API_NAMES('LOG_WARN') := '*';
	g_LOG_API_NAMES('LOG_INFO') := '*';
	g_LOG_API_NAMES('LOG_DEBUG') := '*';
	g_LOG_API_NAMES('DIE') := '*';
	g_LOG_API_NAMES('ALERT_FATAL') := '*';
	g_LOG_API_NAMES('ALERT_ERROR') := '*';
	g_LOG_API_NAMES('ALERT_WARN') := '*';
	g_LOG_API_NAMES('ALERT_NOTICE') := '*';
END FML_UTIL;
/
