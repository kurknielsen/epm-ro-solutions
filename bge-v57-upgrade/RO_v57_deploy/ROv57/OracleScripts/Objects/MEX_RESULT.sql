CREATE OR REPLACE TYPE MEX_RESULT AS OBJECT
(
    STATUS_CODE NUMBER(1),
    REQUESTID VARCHAR2(64),
    HEADER_NAMES STRING_COLLECTION,
    HEADER_VALUES STRING_COLLECTION,
    COOKIES MEX_COOKIE_TBL,
    RESPONSE_CONTENTTYPE VARCHAR2(64),
    RESPONSE CLOB,

	-- looks up a cookie by name
    MEMBER FUNCTION GET_COOKIE(p_COOKIE_NAME IN VARCHAR2) RETURN MEX_COOKIE,
	
	-- looks up a header value by name - if there are multiple headers with this name,
	-- this will return the value only for the first one
    MEMBER FUNCTION GET_HEADER(p_HEADER_NAME IN VARCHAR2) RETURN VARCHAR2,

	-- looks up a header value by name - if there are multiple headers with this name,
	-- this returns all of them in a collection
    MEMBER FUNCTION GET_HEADER_VALUES(p_HEADER_NAME IN VARCHAR2) RETURN STRING_COLLECTION,
	
	-- constructor- this will parse out the success flag, the response content-type, and
	-- all cookies from the specified headers
    CONSTRUCTOR FUNCTION MEX_RESULT(p_HEADER_NAMES IN STRING_COLLECTION,
                                    p_HEADER_VALUES IN STRING_COLLECTION,
                                    p_RESPONSE IN CLOB) 
                                    RETURN SELF AS RESULT,
	-- constructor- this indicates an error result
    CONSTRUCTOR FUNCTION MEX_RESULT(p_ERROR_MESSAGE IN VARCHAR2) 
                                    RETURN SELF AS RESULT
);
/
CREATE OR REPLACE TYPE BODY MEX_RESULT IS
-----------------------------------------------------------------------------
MEMBER FUNCTION GET_COOKIE
	(
	p_COOKIE_NAME IN VARCHAR2
	) RETURN MEX_COOKIE IS
v_IDX NUMBER;
v_COOKIE_NAME VARCHAR2(64) := UPPER(p_COOKIE_NAME);
BEGIN
	v_IDX := SELF.COOKIES.FIRST;
	WHILE SELF.COOKIES.EXISTS(v_IDX) LOOP
		-- found the header?
		IF UPPER(SELF.COOKIES(v_IDX).NAME) = v_COOKIE_NAME THEN	
			-- return the corresponding value
			RETURN SELF.COOKIES(v_IDX);
		END IF;
		v_IDX := SELF.COOKIES.NEXT(v_IDX);
	END LOOP;
	-- never found such a header - return null
	RETURN NULL;
END GET_COOKIE;
-----------------------------------------------------------------------------
MEMBER FUNCTION GET_HEADER
	(
	p_HEADER_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS
v_IDX NUMBER;
v_HEADER_NAME VARCHAR2(64) := UPPER(p_HEADER_NAME);
BEGIN
	v_IDX := SELF.HEADER_NAMES.FIRST;
	WHILE SELF.HEADER_NAMES.EXISTS(v_IDX) LOOP
		-- found the header?
		IF UPPER(SELF.HEADER_NAMES(v_IDX)) = v_HEADER_NAME THEN	
			-- return the corresponding value
			RETURN SELF.HEADER_VALUES(v_IDX);
		END IF;
		v_IDX := SELF.HEADER_NAMES.NEXT(v_IDX);
	END LOOP;
	-- never found such a header - return null
	RETURN NULL;
END GET_HEADER;
-----------------------------------------------------------------------------
MEMBER FUNCTION GET_HEADER_VALUES
	(
	p_HEADER_NAME IN VARCHAR2
	) RETURN STRING_COLLECTION IS
v_IDX NUMBER;
v_HEADER_NAME VARCHAR2(64) := UPPER(p_HEADER_NAME);
v_RET STRING_COLLECTION := STRING_COLLECTION();
BEGIN
	v_IDX := SELF.HEADER_NAMES.FIRST;
	WHILE SELF.HEADER_NAMES.EXISTS(v_IDX) LOOP
		-- found the header?
		IF UPPER(SELF.HEADER_NAMES(v_IDX)) = v_HEADER_NAME THEN	
			-- add to return value list
			v_RET.EXTEND();
			v_RET(v_RET.LAST) := SELF.HEADER_VALUES(v_IDX);
		END IF;
		v_IDX := SELF.HEADER_NAMES.NEXT(v_IDX);
	END LOOP;
	-- finished examining headers - return accumulated list
	RETURN v_RET;
END GET_HEADER_VALUES;
-----------------------------------------------------------------------------
CONSTRUCTOR FUNCTION MEX_RESULT
	(
	p_HEADER_NAMES IN STRING_COLLECTION,
	p_HEADER_VALUES IN STRING_COLLECTION,
	p_RESPONSE IN CLOB
	) RETURN SELF AS RESULT IS
v_COOKIE_HEADERS STRING_COLLECTION;
v_IDX BINARY_INTEGER;
v_TOKENS PARSE_UTIL.BIG_STRING_TABLE_MP;
v_COOKIE_VALS MEX_UTIL.PARAMETER_MAP;
v_SECURE NUMBER(1);
v_HIDDEN NUMBER(1);
v_EXPIRES VARCHAR2(64);
v_DOMAIN VARCHAR2(128);
v_PATH VARCHAR2(1024);
v_JDX BINARY_INTEGER;
v_NAME VARCHAR2(256);
v_VALUE VARCHAR2(4000);
v_POS BINARY_INTEGER;
BEGIN
	SELF.HEADER_NAMES := p_HEADER_NAMES;
	SELF.HEADER_VALUES := p_HEADER_VALUES;
	SELF.RESPONSE := p_RESPONSE;
	
	-- now determine some of the other fields from the headers
	SELF.REQUESTID := GET_HEADER('MEX-Request-Id');
	SELF.RESPONSE_CONTENTTYPE := GET_HEADER('Content-Type');
	IF NVL(GET_HEADER('MEX-Error-Flag'), '0') = '1' THEN
		SELF.STATUS_CODE := 1;
	ELSE
		SELF.STATUS_CODE := 0;
	END IF;
	-- and now the cookies
	SELF.COOKIES := MEX_COOKIE_TBL();
	v_COOKIE_HEADERS := GET_HEADER_VALUES('Set-Cookie');
	-- parse cookies out of headers
	v_IDX := v_COOKIE_HEADERS.FIRST;
	WHILE v_COOKIE_HEADERS.EXISTS(v_IDX) LOOP
		PARSE_UTIL.TOKENS_FROM_BIG_STRING(v_COOKIE_HEADERS(v_IDX), ';', v_TOKENS);
		-- reset some attributes
		v_SECURE := 0; v_HIDDEN := 0;
		v_EXPIRES := NULL; v_DOMAIN := NULL; v_PATH := NULL;
		v_COOKIE_VALS.DELETE;
		-- now parse this header
		v_JDX := v_TOKENS.FIRST;
		WHILE v_TOKENS.EXISTS(v_JDX) LOOP
			v_VALUE := v_TOKENS(v_JDX);
			v_POS := INSTR(v_VALUE,'=');
			IF v_POS > 1 THEN
				v_NAME := SUBSTR(v_VALUE, 1, v_POS-1);
				v_VALUE := SUBSTR(v_VALUE, v_POS+1);
				IF UPPER(v_NAME) = 'EXPIRES' THEN
					v_EXPIRES := v_VALUE;
				ELSIF UPPER(v_NAME) = 'DOMAIN' THEN
					v_DOMAIN := v_VALUE;
				ELSIF UPPER(v_NAME) = 'PATH' THEN
					v_PATH := v_VALUE;
				ELSE
					-- this is a cookie value
					v_COOKIE_VALS(v_NAME) := v_VALUE;
				END IF;
			ELSIF UPPER(v_VALUE) = 'SECURE' THEN
				v_SECURE := 1;
			ELSIF UPPER(v_VALUE) = 'HTTPONLY' THEN
				v_HIDDEN := 1;
			END IF;
			v_JDX := v_TOKENS.NEXT(v_JDX);
		END LOOP;
		-- now create cookie objects from this info
		v_NAME := v_COOKIE_VALS.FIRST;
		WHILE v_COOKIE_VALS.EXISTS(v_NAME) LOOP
			SELF.COOKIES.EXTEND();
			-- add the new cookie
			SELF.COOKIES(SELF.COOKIES.LAST) := MEX_COOKIE(v_NAME, v_COOKIE_VALS(v_NAME), v_EXPIRES, v_DOMAIN, v_PATH, v_SECURE, v_HIDDEN);
			v_NAME := v_COOKIE_VALS.NEXT(v_NAME);
		END LOOP;
		-- now to the next header...
		v_IDX := v_COOKIE_HEADERS.NEXT(v_IDX);
	END LOOP;
	-- done!
	RETURN;
END;
-----------------------------------------------------------------------------
CONSTRUCTOR FUNCTION MEX_RESULT
	(
	p_ERROR_MESSAGE IN VARCHAR2
	) RETURN SELF AS RESULT AS
BEGIN
	SELF.REQUESTID := '?';
	SELF.HEADER_NAMES := STRING_COLLECTION();
	SELF.HEADER_VALUES := STRING_COLLECTION();
	SELF.COOKIES := MEX_COOKIE_TBL();
	SELF.STATUS_CODE := 1;
	SELF.RESPONSE_CONTENTTYPE := 'text/plain';
	SELF.RESPONSE := p_ERROR_MESSAGE;
	-- done!
	RETURN;
END;
-----------------------------------------------------------------------------
END;
/
