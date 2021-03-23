CREATE OR REPLACE PACKAGE CD IS
--Revision $Revision: 1.17 $

-- Codecs Package (Encoding/Decoding)

FUNCTION WHAT_VERSION RETURN VARCHAR;

FUNCTION ENDECRYPT
	(
    p_PLAINTXT IN VARCHAR2,
    p_CIPHER_KEY IN VARCHAR2
    ) RETURN VARCHAR2;
FUNCTION ENDECRYPT_TO_RAW
	(
    p_PLAINTXT IN VARCHAR2,
    p_CIPHER_KEY IN RAW
    ) RETURN RAW;
FUNCTION ENDECRYPT_FROM_RAW
	(
    p_PLAINTXT IN RAW,
    p_CIPHER_KEY IN RAW
    ) RETURN VARCHAR2;
FUNCTION ENDECRYPT
	(
    p_PLAINTXT IN BLOB,
    p_CIPHER_KEY IN RAW
    ) RETURN BLOB;

-- again, several versions
FUNCTION BASE64ENCODE
	(
    p_PLAINTXT IN VARCHAR2
    ) RETURN VARCHAR2;
FUNCTION BASE64ENCODE_FROM_RAW
	(
    p_PLAINTXT IN RAW
    ) RETURN VARCHAR2;
FUNCTION BASE64ENCODE
	(
    p_PLAINTXT IN BLOB
    ) RETURN CLOB;

-- yet again, several versions
FUNCTION BASE64DECODE
	(
    p_CODETXT IN VARCHAR2
    ) RETURN VARCHAR2;
FUNCTION BASE64DECODE_TO_RAW
	(
    p_CODETXT IN VARCHAR2
    ) RETURN RAW;
FUNCTION BASE64DECODE
	(
    p_CODETXT IN CLOB
    ) RETURN BLOB;

-- other procedures...
FUNCTION URL_ENCODE
	(
    p_STRING IN VARCHAR2,
	p_QUERY_STRING IN BOOLEAN := FALSE
    ) RETURN VARCHAR2;

FUNCTION URL_ENCODE
	(
    p_STRING IN CLOB,
	p_QUERY_STRING IN BOOLEAN := FALSE
    ) RETURN CLOB;

FUNCTION HEX_ENCODE
	(
	p_DATA IN RAW
	) RETURN VARCHAR2;

FUNCTION HEX_DECODE
	(
	p_DATA IN VARCHAR2
	) RETURN RAW;

FUNCTION BIT_XOR
	(
    p_NUM1 IN NUMBER,
    p_NUM2 IN NUMBER
    ) RETURN NUMBER;

-- Adds MEX request data to a query string
-- from CLOB
PROCEDURE BUILD_QUERY_STRING
	(
    p_VAR_NAME IN VARCHAR2,
    p_VAR_VALUE IN CLOB,
    p_QUERY_STRING IN OUT NOCOPY CLOB,
    p_PRETTY_QUERY_STRING IN OUT NOCOPY CLOB,
    p_EXCLUDE_FROM_PRETTY IN BOOLEAN := FALSE,
	p_VAR_PRETTY_VALUE IN CLOB := NULL,
	p_BASE64_ENCODE IN BOOLEAN := FALSE
    );
-- from varchar
PROCEDURE BUILD_QUERY_STRING
	(
    p_VAR_NAME IN VARCHAR2,
    p_VAR_VALUE IN VARCHAR2,
    p_QUERY_STRING IN OUT NOCOPY CLOB,
    p_PRETTY_QUERY_STRING IN OUT NOCOPY CLOB,
    p_EXCLUDE_FROM_PRETTY IN BOOLEAN := FALSE,
	p_VAR_PRETTY_VALUE IN VARCHAR2 := NULL,
	p_BASE64_ENCODE IN BOOLEAN := FALSE
    );

-- Adds MEX binary request data to a query string - binary data will always be base-64 encoded
PROCEDURE BUILD_QUERY_STRING
	(
    p_VAR_NAME IN VARCHAR2,
    p_VAR_VALUE IN BLOB,
    p_QUERY_STRING IN OUT NOCOPY CLOB,
    p_PRETTY_QUERY_STRING IN OUT NOCOPY CLOB,
    p_EXCLUDE_FROM_PRETTY IN BOOLEAN := FALSE,
	p_VAR_PRETTY_VALUE IN CLOB := NULL
    );

END CD;
/
CREATE OR REPLACE PACKAGE BODY CD IS
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
    RETURN '$Revision: 1.17 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
FUNCTION BYTE_TO_RAW
	(
	p_BYTE IN BINARY_INTEGER
	) RETURN RAW IS
BEGIN
	RETURN UTL_RAW.SUBSTR(UTL_RAW.CAST_FROM_BINARY_INTEGER(p_BYTE, UTL_RAW.LITTLE_ENDIAN),1,1);
END BYTE_TO_RAW;
----------------------------------------------------------------------------------------------------
FUNCTION RAW_TO_BYTE
	(
	p_RAW IN RAW
	) RETURN BINARY_INTEGER IS
BEGIN
	RETURN UTL_RAW.CAST_TO_BINARY_INTEGER(p_RAW, UTL_RAW.LITTLE_ENDIAN);
END RAW_TO_BYTE;
----------------------------------------------------------------------------------------------------
FUNCTION BIT_XOR
	(
    p_NUM1 IN NUMBER,
    p_NUM2 IN NUMBER
    ) RETURN NUMBER IS
BEGIN
	IF p_NUM1 IS NULL OR p_NUM2 IS NULL THEN
		RETURN NULL;
	END IF;

	RETURN p_NUM1 + p_NUM2 - BITAND(p_NUM1, p_NUM2)*2;
END;
----------------------------------------------------------------------------------------------------
PROCEDURE RC4INIT
	(
	p_PWD IN VARCHAR2,
    p_SBOX IN OUT NOCOPY GA.NUMBER_TABLE
    ) AS
   --::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   --:::  Initializes the sbox array from a VARCHAR for use by ENDECRYPT  :::
   --::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
v_KEY GA.NUMBER_TABLE;
v_TEMP NUMBER;
v_B NUMBER;
v_LEN NUMBER;

BEGIN
	v_LEN := LENGTH(p_PWD);
    FOR v_A IN 0..255 LOOP
    	v_KEY(v_A) := ASCII(SUBSTR(p_PWD, MOD(v_A,v_LEN)+1, 1));
        p_SBOX(v_A) := v_A;
	END LOOP;

	v_B := 0;
    FOR v_A IN 0..255 LOOP
    	v_B := MOD(v_B + p_SBOX(v_A) + v_KEY(v_A), 256);
        v_TEMP := p_SBOX(v_A);
        p_SBOX(v_A) := p_SBOX(v_B);
        p_SBOX(v_B) := v_TEMP;
    END LOOP;

END RC4INIT;
----------------------------------------------------------------------------------------------------
PROCEDURE RC4INIT_RAW
	(
	p_PWD IN RAW,
    p_SBOX IN OUT NOCOPY GA.NUMBER_TABLE
    ) AS
   --::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   --:::  Initializes the sbox array from a RAW for use by ENDECRYPT    :::
   --::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
v_KEY GA.NUMBER_TABLE;
v_TEMP NUMBER;
v_B NUMBER;
v_LEN NUMBER;

BEGIN
	v_LEN := UTL_RAW.LENGTH(p_PWD);
    FOR v_A IN 0..255 LOOP
    	v_KEY(v_A) := RAW_TO_BYTE(UTL_RAW.SUBSTR(p_PWD, MOD(v_A,v_LEN)+1, 1));
        p_SBOX(v_A) := v_A;
	END LOOP;

	v_B := 0;
    FOR v_A IN 0..255 LOOP
    	v_B := MOD(v_B + p_SBOX(v_A) + v_KEY(v_A), 256);
        v_TEMP := p_SBOX(v_A);
        p_SBOX(v_A) := p_SBOX(v_B);
        p_SBOX(v_B) := v_TEMP;
    END LOOP;

END RC4INIT_RAW;
----------------------------------------------------------------------------------------------------
FUNCTION ENDECRYPT
	(
    p_PLAINTXT IN VARCHAR2,
    p_CIPHER_KEY IN VARCHAR2
    ) RETURN VARCHAR2 IS
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   --:::  This routine does all the work. Call it both to ENcrypt    :::
   --:::  and to DEcrypt your data.                                  :::
   --:::  This version will encrypt/decrypt using all VARCHARs       :::
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
v_SBOX GA.NUMBER_TABLE;
v_TEMP BINARY_INTEGER;
v_A BINARY_INTEGER;
v_I BINARY_INTEGER;
v_J BINARY_INTEGER;
v_K BINARY_INTEGER;
v_CIPHERBY BINARY_INTEGER;
v_CIPHER VARCHAR2(1024) := '';

BEGIN
	IF p_PLAINTXT IS NULL THEN
		RETURN NULL;
	END IF;

	v_I := 0;
    v_J := 0;

    RC4INIT (p_CIPHER_KEY, v_SBOX);

    FOR v_A IN 1..LENGTH(p_PLAINTXT) LOOP
        v_I := MOD(v_I + 1, 256);
        v_J := MOD(v_J + v_SBOX(v_I), 256);
        v_TEMP := v_SBOX(v_I);
        v_SBOX(v_I) := v_SBOX(v_J);
        v_SBOX(v_J) := v_TEMP;

   		v_K := v_SBOX(MOD(v_SBOX(v_I)+v_SBOX(v_J), 256));

        v_CIPHERBY := BIT_XOR(ASCII(SUBSTR(p_PLAINTXT, v_A, 1)), v_K);
        v_CIPHER := v_CIPHER||CHR(v_CIPHERBY);
	END LOOP;

    RETURN v_CIPHER;

END ENDECRYPT;
----------------------------------------------------------------------------------------------------
FUNCTION ENDECRYPT_TO_RAW
	(
    p_PLAINTXT IN VARCHAR2,
    p_CIPHER_KEY IN RAW
    ) RETURN RAW IS
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   --:::  This routine does all the work. Call it both to ENcrypt    :::
   --:::  and to DEcrypt your data.                                  :::
   --:::  This version will encrypt a VARCHAR to a RAW               :::
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
v_SBOX GA.NUMBER_TABLE;
v_TEMP BINARY_INTEGER;
v_A BINARY_INTEGER;
v_I BINARY_INTEGER;
v_J BINARY_INTEGER;
v_K BINARY_INTEGER;
v_CIPHERBY BINARY_INTEGER;
v_CIPHER RAW(1024) := NULL;

BEGIN
	IF p_PLAINTXT IS NULL THEN
		RETURN NULL;
	END IF;

	v_I := 0;
    v_J := 0;

    RC4INIT_RAW (p_CIPHER_KEY, v_SBOX);

    FOR v_A IN 1..LENGTH(p_PLAINTXT) LOOP
        v_I := MOD(v_I + 1, 256);
        v_J := MOD(v_J + v_SBOX(v_I), 256);
        v_TEMP := v_SBOX(v_I);
        v_SBOX(v_I) := v_SBOX(v_J);
        v_SBOX(v_J) := v_TEMP;

   		v_K := v_SBOX(MOD(v_SBOX(v_I)+v_SBOX(v_J), 256));

        v_CIPHERBY := BIT_XOR(ASCII(SUBSTR(p_PLAINTXT, v_A, 1)), v_K);
		v_CIPHER := UTL_RAW.CONCAT(v_CIPHER, BYTE_TO_RAW(v_CIPHERBY));
	END LOOP;

    RETURN v_CIPHER;

END ENDECRYPT_TO_RAW;
----------------------------------------------------------------------------------------------------
FUNCTION ENDECRYPT_FROM_RAW
	(
    p_PLAINTXT IN RAW,
    p_CIPHER_KEY IN RAW
    ) RETURN VARCHAR2 IS
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   --:::  This routine does all the work. Call it both to ENcrypt    :::
   --:::  and to DEcrypt your data.                                  :::
   --:::  This version will decrypt a RAW to a VARCHAR               :::
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
v_SBOX GA.NUMBER_TABLE;
v_TEMP BINARY_INTEGER;
v_A BINARY_INTEGER;
v_I BINARY_INTEGER;
v_J BINARY_INTEGER;
v_K BINARY_INTEGER;
v_CIPHERBY BINARY_INTEGER;
v_CIPHER VARCHAR2(1024) := '';

BEGIN
	IF p_PLAINTXT IS NULL THEN
		RETURN NULL;
	END IF;

	v_I := 0;
    v_J := 0;

    RC4INIT_RAW (p_CIPHER_KEY, v_SBOX);

    FOR v_A IN 1..UTL_RAW.LENGTH(p_PLAINTXT) LOOP
        v_I := MOD(v_I + 1, 256);
        v_J := MOD(v_J + v_SBOX(v_I), 256);
        v_TEMP := v_SBOX(v_I);
        v_SBOX(v_I) := v_SBOX(v_J);
        v_SBOX(v_J) := v_TEMP;

   		v_K := v_SBOX(MOD(v_SBOX(v_I)+v_SBOX(v_J), 256));

        v_CIPHERBY := BIT_XOR(RAW_TO_BYTE(UTL_RAW.SUBSTR(p_PLAINTXT, v_A, 1)), v_K);
        v_CIPHER := v_CIPHER||CHR(v_CIPHERBY);
	END LOOP;

    RETURN v_CIPHER;

END ENDECRYPT_FROM_RAW;
----------------------------------------------------------------------------------------------------
FUNCTION ENDECRYPT
	(
    p_PLAINTXT IN BLOB,
    p_CIPHER_KEY IN RAW
    ) RETURN BLOB IS
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
   --:::  This routine does all the work. Call it both to ENcrypt    :::
   --:::  and to DEcrypt your data.                                  :::
   --:::  This version will encrypt/decrypt a BLOB                   :::
   --:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
v_SBOX GA.NUMBER_TABLE;
v_TEMP BINARY_INTEGER;
v_LEN BINARY_INTEGER;
v_A BINARY_INTEGER;
v_I BINARY_INTEGER;
v_J BINARY_INTEGER;
v_K BINARY_INTEGER;
v_CIPHERBY BINARY_INTEGER;
v_CIPHER BLOB;

BEGIN
	DBMS_LOB.CREATETEMPORARY(v_CIPHER, TRUE);

	IF p_PLAINTXT IS NULL THEN
		RETURN v_CIPHER;
	END IF;
	v_LEN := DBMS_LOB.GETLENGTH(p_PLAINTXT);
	IF v_LEN = 0 THEN
		RETURN v_CIPHER;
	END IF;

	DBMS_LOB.OPEN(v_CIPHER, DBMS_LOB.LOB_READWRITE);

	v_I := 0;
    v_J := 0;

    RC4INIT_RAW (p_CIPHER_KEY, v_SBOX);

    FOR v_A IN 1..v_LEN LOOP
        v_I := MOD(v_I + 1, 256);
        v_J := MOD(v_J + v_SBOX(v_I), 256);
        v_TEMP := v_SBOX(v_I);
        v_SBOX(v_I) := v_SBOX(v_J);
        v_SBOX(v_J) := v_TEMP;

   		v_K := v_SBOX(MOD(v_SBOX(v_I)+v_SBOX(v_J), 256));

        v_CIPHERBY := BIT_XOR(RAW_TO_BYTE(DBMS_LOB.SUBSTR(p_PLAINTXT, 1, v_A)), v_K);
		DBMS_LOB.WRITEAPPEND(v_CIPHER, 1, BYTE_TO_RAW(v_CIPHERBY));
	END LOOP;

	DBMS_LOB.CLOSE(v_CIPHER);

    RETURN v_CIPHER;
END ENDECRYPT;
----------------------------------------------------------------------------------------------------
FUNCTION HEX_DIGIT
	(
    p_DIGIT IN NUMBER
    ) RETURN CHAR IS
v_DIGIT NUMBER := MOD(p_DIGIT,16);
BEGIN
	IF v_DIGIT > 9 THEN
    	RETURN CHR(ASCII('a')+v_DIGIT-10);
    ELSE
    	RETURN CHR(ASCII('0')+v_DIGIT);
    END IF;
END HEX_DIGIT;
----------------------------------------------------------------------------------------------------
FUNCTION HEX_BYTE
	(
	p_BYTE IN NUMBER
	) RETURN VARCHAR2 IS
BEGIN
    RETURN HEX_DIGIT(FLOOR(p_BYTE/16))||HEX_DIGIT(MOD(p_BYTE,16));
END HEX_BYTE;
----------------------------------------------------------------------------------------------------
FUNCTION HEX_VALUE
	(
    p_CHAR IN CHAR
    ) RETURN VARCHAR2 IS
BEGIN
	RETURN HEX_BYTE(ASCII(p_CHAR));
END HEX_VALUE;
----------------------------------------------------------------------------------------------------
FUNCTION URL_ENCODE
	(
    p_STRING IN VARCHAR2,
	p_QUERY_STRING IN BOOLEAN := FALSE
    ) RETURN VARCHAR2 IS
v_RET VARCHAR2(32767) := '';
v_CHAR CHAR(1);
BEGIN
	IF p_STRING IS NULL THEN
		RETURN NULL;
	END IF;


	FOR v_INDEX IN 1..LENGTH(p_STRING) LOOP
    	v_CHAR := SUBSTR(p_STRING,v_INDEX,1);
		IF (v_CHAR >= '0' AND v_CHAR <= '9') OR
           (v_CHAR >= 'a' AND v_CHAR <= 'z') OR
           (v_CHAR >= 'A' AND v_CHAR <= 'Z') OR
           v_CHAR = '-' OR v_CHAR = '_' OR v_CHAR = '*' THEN
			v_RET := v_RET||v_CHAR;
		ELSIF p_QUERY_STRING AND v_CHAR = ' ' THEN
		 	v_RET := v_RET||'+';
		ELSE
        	v_RET := v_RET||'%'||HEX_VALUE(v_CHAR);
		END IF;
    END LOOP;
    RETURN v_RET;
END URL_ENCODE;
----------------------------------------------------------------------------------------------------
FUNCTION URL_ENCODE
	(
    p_STRING IN CLOB,
	p_QUERY_STRING IN BOOLEAN := FALSE
    ) RETURN CLOB IS
v_RET CLOB;
v_BUFFER VARCHAR2(10000);
v_RESULT VARCHAR2(30000);
v_LEN   PLS_INTEGER;
v_INDEX PLS_INTEGER := 1;
BEGIN
    DBMS_LOB.CREATETEMPORARY(v_RET,TRUE);
    DBMS_LOB.OPEN(v_RET,DBMS_LOB.LOB_READWRITE);

	v_LEN := DBMS_LOB.GETLENGTH(p_STRING);
	WHILE v_INDEX <= v_LEN LOOP
    	v_BUFFER := DBMS_LOB.SUBSTR(p_STRING,10000,v_INDEX);
		v_RESULT := URL_ENCODE(v_BUFFER, p_QUERY_STRING);
		DBMS_LOB.WRITEAPPEND(v_RET, LENGTH(v_RESULT), v_RESULT);
		v_INDEX := v_INDEX+10000;
	END LOOP;

    DBMS_LOB.CLOSE(v_RET);
    RETURN v_RET;
END URL_ENCODE;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64CHAR
	(
    p_DIGIT IN NUMBER
    ) RETURN VARCHAR2 IS
    -- digit should be between 0 and 63 inclusive, however this function
    -- also accepts digit 64 as the "padding" digit (since all base64 encoded
    -- strings have a length that is a multiple of four) - all other input
    -- will have undefined results
BEGIN
	IF p_DIGIT >= 0 AND p_DIGIT <= 25 THEN
    	RETURN CHR(ASCII('A')+p_DIGIT);
    ELSIF p_DIGIT >= 26 AND p_DIGIT <= 51 THEN
    	RETURN CHR(ASCII('a')+p_DIGIT-26);
    ELSIF p_DIGIT >= 52 AND p_DIGIT <= 61 THEN
    	RETURN CHR(ASCII('0')+p_DIGIT-52);
    ELSIF p_DIGIT = 62 THEN
    	RETURN '+';
    ELSIF p_DIGIT = 63 THEN
    	RETURN '/';
    ELSIF p_DIGIT = 64 THEN
    	RETURN '=';
    END IF;
END BASE64CHAR;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64ENCODE
	(
    p_PLAINTXT IN VARCHAR2
    ) RETURN VARCHAR2 IS
v_I BINARY_INTEGER;
v_NEWSTR VARCHAR2(4000) := '';
v_THREE VARCHAR2(3);
v_VALS8B0 BINARY_INTEGER;
v_VALS8B1 BINARY_INTEGER;
v_VALS8B2 BINARY_INTEGER;
v_VALS6B0 BINARY_INTEGER;
v_VALS6B1 BINARY_INTEGER;
v_VALS6B2 BINARY_INTEGER;
v_VALS6B3 BINARY_INTEGER;
v_NUMPAD BINARY_INTEGER;
BEGIN
	IF p_PLAINTXT IS NULL THEN
		RETURN NULL;
	END IF;

	v_I := 1;
	WHILE v_I <= LENGTH(p_PLAINTXT) LOOP
		v_THREE := SUBSTR(p_PLAINTXT,v_I,3);
	    v_NUMPAD := 3-LENGTH(v_THREE);
	    v_VALS8B0 := ASCII(SUBSTR(v_THREE,1,1));
	    IF v_NUMPAD > 1 THEN v_VALS8B1 := 0; ELSE v_VALS8B1 := ASCII(SUBSTR(v_THREE,2,1)); END IF;
	    IF v_NUMPAD > 0 THEN v_VALS8B2 := 0; ELSE v_VALS8B2 := ASCII(SUBSTR(v_THREE,3,1)); END IF;
	    v_VALS6B0 := (v_VALS8B0-MOD(v_VALS8B0,4)) / 4;
	    v_VALS6B1 := MOD(v_VALS8B0,4)*16 + ((v_VALS8B1-MOD(v_VALS8B1,16)) / 16);
	    IF v_NUMPAD > 1 THEN v_VALS6B2 := 64; ELSE v_VALS6B2 := MOD(v_VALS8B1,16)*4 + ((v_VALS8B2-MOD(v_VALS8B2,64)) / 64); END IF;
	    IF v_NUMPAD > 0 THEN v_VALS6B3 := 64; ELSE v_VALS6B3 := MOD(v_VALS8B2,64); END IF;
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B0);
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B1);
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B2);
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B3);
		v_I := v_I + 3;
	END LOOP;
	RETURN v_NEWSTR;
END BASE64ENCODE;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64ENCODE_FROM_RAW
	(
    p_PLAINTXT IN RAW
    ) RETURN VARCHAR2 IS
v_I BINARY_INTEGER;
v_LEN BINARY_INTEGER;
v_NEWSTR VARCHAR2(4000) := '';
v_THREE RAW(3);
v_VALS8B0 BINARY_INTEGER;
v_VALS8B1 BINARY_INTEGER;
v_VALS8B2 BINARY_INTEGER;
v_VALS6B0 BINARY_INTEGER;
v_VALS6B1 BINARY_INTEGER;
v_VALS6B2 BINARY_INTEGER;
v_VALS6B3 BINARY_INTEGER;
v_NUMPAD BINARY_INTEGER;
BEGIN
	IF p_PLAINTXT IS NULL THEN
		RETURN NULL;
	END IF;

	v_I := 1;
	v_LEN := UTL_RAW.LENGTH(p_PLAINTXT);
	WHILE v_I <= v_LEN LOOP
		v_THREE := UTL_RAW.SUBSTR(p_PLAINTXT,v_I,LEAST(3,v_LEN-v_I+1));
	    v_NUMPAD := 3-UTL_RAW.LENGTH(v_THREE);
	    v_VALS8B0 := RAW_TO_BYTE(UTL_RAW.SUBSTR(v_THREE,1,1));
	    IF v_NUMPAD > 1 THEN v_VALS8B1 := 0; ELSE v_VALS8B1 := RAW_TO_BYTE(UTL_RAW.SUBSTR(v_THREE,2,1)); END IF;
	    IF v_NUMPAD > 0 THEN v_VALS8B2 := 0; ELSE v_VALS8B2 := RAW_TO_BYTE(UTL_RAW.SUBSTR(v_THREE,3,1)); END IF;
	    v_VALS6B0 := (v_VALS8B0-MOD(v_VALS8B0,4)) / 4;
	    v_VALS6B1 := MOD(v_VALS8B0,4)*16 + ((v_VALS8B1-MOD(v_VALS8B1,16)) / 16);
	    IF v_NUMPAD > 1 THEN v_VALS6B2 := 64; ELSE v_VALS6B2 := MOD(v_VALS8B1,16)*4 + ((v_VALS8B2-MOD(v_VALS8B2,64)) / 64); END IF;
	    IF v_NUMPAD > 0 THEN v_VALS6B3 := 64; ELSE v_VALS6B3 := MOD(v_VALS8B2,64); END IF;
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B0);
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B1);
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B2);
	    v_NEWSTR := v_NEWSTR || BASE64CHAR(v_VALS6B3);
		v_I := v_I + 3;
	END LOOP;
	RETURN v_NEWSTR;
END BASE64ENCODE_FROM_RAW;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64ENCODE
	(
    p_PLAINTXT IN BLOB
    ) RETURN CLOB IS
v_I BINARY_INTEGER;
v_NEWSTR CLOB;
v_LEN BINARY_INTEGER;
v_THREE RAW(3);
v_VALS8B0 BINARY_INTEGER;
v_VALS8B1 BINARY_INTEGER;
v_VALS8B2 BINARY_INTEGER;
v_VALS6B0 BINARY_INTEGER;
v_VALS6B1 BINARY_INTEGER;
v_VALS6B2 BINARY_INTEGER;
v_VALS6B3 BINARY_INTEGER;
v_NUMPAD BINARY_INTEGER;
BEGIN
	DBMS_LOB.CREATETEMPORARY(v_NEWSTR, TRUE);

	IF p_PLAINTXT IS NULL THEN
		RETURN NULL;
	END IF;
	v_LEN := DBMS_LOB.GETLENGTH(p_PLAINTXT);
	IF v_LEN = 0 THEN
		RETURN v_NEWSTR;
	END IF;

	DBMS_LOB.OPEN(v_NEWSTR, DBMS_LOB.LOB_READWRITE);

	v_I := 1;
	WHILE v_I <= v_LEN LOOP
		v_THREE := DBMS_LOB.SUBSTR(p_PLAINTXT,LEAST(3,v_LEN-v_I+1),v_I);
	    v_NUMPAD := 3-UTL_RAW.LENGTH(v_THREE);
	    v_VALS8B0 := RAW_TO_BYTE(UTL_RAW.SUBSTR(v_THREE,1,1));
	    IF v_NUMPAD > 1 THEN v_VALS8B1 := 0; ELSE v_VALS8B1 := RAW_TO_BYTE(UTL_RAW.SUBSTR(v_THREE,2,1)); END IF;
	    IF v_NUMPAD > 0 THEN v_VALS8B2 := 0; ELSE v_VALS8B2 := RAW_TO_BYTE(UTL_RAW.SUBSTR(v_THREE,3,1)); END IF;
	    v_VALS6B0 := (v_VALS8B0-MOD(v_VALS8B0,4)) / 4;
	    v_VALS6B1 := MOD(v_VALS8B0,4)*16 + ((v_VALS8B1-MOD(v_VALS8B1,16)) / 16);
	    IF v_NUMPAD > 1 THEN v_VALS6B2 := 64; ELSE v_VALS6B2 := MOD(v_VALS8B1,16)*4 + ((v_VALS8B2-MOD(v_VALS8B2,64)) / 64); END IF;
	    IF v_NUMPAD > 0 THEN v_VALS6B3 := 64; ELSE v_VALS6B3 := MOD(v_VALS8B2,64); END IF;
		DBMS_LOB.WRITEAPPEND(v_NEWSTR, 1, BASE64CHAR(v_VALS6B0));
	    DBMS_LOB.WRITEAPPEND(v_NEWSTR, 1, BASE64CHAR(v_VALS6B1));
	    DBMS_LOB.WRITEAPPEND(v_NEWSTR, 1, BASE64CHAR(v_VALS6B2));
	    DBMS_LOB.WRITEAPPEND(v_NEWSTR, 1, BASE64CHAR(v_VALS6B3));
		v_I := v_I + 3;
	END LOOP;

	DBMS_LOB.CLOSE(v_NEWSTR);

	RETURN v_NEWSTR;
END BASE64ENCODE;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64DIGIT
	(
    p_CHAR IN VARCHAR2
    ) RETURN NUMBER IS
v_CHAR CHAR(1);
BEGIN
	-- char should be a valid base64 digit, but *not* the "padding" digit - any
    -- other input to this function will have undefined results
    v_CHAR := SUBSTR(p_CHAR,1,1);
    IF v_CHAR = '/' THEN
    	RETURN 63;
    ELSIF v_CHAR = '+' THEN
    	RETURN 62;
    ELSIF v_CHAR >= '0' AND v_CHAR <= '9' THEN
    	RETURN ASCII(v_CHAR)-ASCII('0')+52;
    ELSIF v_CHAR >= 'a' AND v_CHAR <= 'z' THEN
    	RETURN ASCII(v_CHAR)-ASCII('a')+26;
    ELSIF v_CHAR >= 'A' AND v_CHAR <= 'Z' THEN
    	RETURN ASCII(v_CHAR)-ASCII('A');
    END IF;
END BASE64DIGIT;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64DECODE
	(
    p_CODETXT IN VARCHAR2
    ) RETURN VARCHAR2 IS
v_CODETXT VARCHAR2(32767);
v_I BINARY_INTEGER;
v_NEWSTR VARCHAR2(4000) := '';
v_FOUR VARCHAR2(4);
v_VALS8B0 BINARY_INTEGER;
v_VALS8B1 BINARY_INTEGER;
v_VALS8B2 BINARY_INTEGER;
v_VALS6B0 BINARY_INTEGER;
v_VALS6B1 BINARY_INTEGER;
v_VALS6B2 BINARY_INTEGER;
v_VALS6B3 BINARY_INTEGER;
v_NUMPAD BINARY_INTEGER;
BEGIN
	IF p_CODETXT IS NULL THEN
		RETURN NULL;
	END IF;

	--Strip whitespace from Codetxt.
	v_CODETXT := REGEXP_REPLACE(p_CODETXT, '\s');

	v_I := 1;
	WHILE v_I <= LENGTH(v_CODETXT) LOOP
    	v_FOUR := SUBSTR(v_CODETXT,v_I,4);
		v_FOUR := REPLACE(v_FOUR, '=', '');
        v_NUMPAD := 4-LENGTH(v_FOUR);
        v_VALS6B0 := BASE64DIGIT(SUBSTR(v_FOUR,1,1));
        v_VALS6B1 := BASE64DIGIT(SUBSTR(v_FOUR,2,1));
        IF v_NUMPAD > 1 THEN v_VALS6B2 := 0; ELSE v_VALS6B2 := BASE64DIGIT(SUBSTR(v_FOUR,3,1)); END IF;
        IF v_NUMPAD > 0 THEN v_VALS6B3 := 0; ELSE v_VALS6B3 := BASE64DIGIT(SUBSTR(v_FOUR,4,1)); END IF;
        v_VALS8B0 := v_VALS6B0*4 + ((v_VALS6B1-MOD(v_VALS6B1,16)) / 16);
        v_VALS8B1 := MOD(v_VALS6B1,16)*16 + ((v_VALS6B2-MOD(v_VALS6B2,4)) / 4);
        v_VALS8B2 := MOD(v_VALS6B2,4)*64 + v_VALS6B3;
        v_NEWSTR := v_NEWSTR || CHR(v_VALS8B0);
        IF v_NUMPAD < 2 THEN v_NEWSTR := v_NEWSTR || CHR(v_VALS8B1); END IF;
        IF v_NUMPAD < 1 THEN v_NEWSTR := v_NEWSTR || CHR(v_VALS8B2); END IF;
		v_I := v_I + 4;
	END LOOP;
	RETURN v_NEWSTR;
END BASE64DECODE;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64DECODE_TO_RAW
	(
    p_CODETXT IN VARCHAR2
    ) RETURN RAW IS
v_CODETXT VARCHAR2(32767);
v_I BINARY_INTEGER;
v_NEWSTR RAW(4000) := NULL;
v_FOUR VARCHAR2(4);
v_VALS8B0 BINARY_INTEGER;
v_VALS8B1 BINARY_INTEGER;
v_VALS8B2 BINARY_INTEGER;
v_VALS6B0 BINARY_INTEGER;
v_VALS6B1 BINARY_INTEGER;
v_VALS6B2 BINARY_INTEGER;
v_VALS6B3 BINARY_INTEGER;
v_NUMPAD BINARY_INTEGER;
BEGIN
	IF p_CODETXT IS NULL THEN
		RETURN NULL;
	END IF;

	--Strip whitespace from Codetxt.
	v_CODETXT := REGEXP_REPLACE(p_CODETXT, '\s');

	v_I := 1;
	WHILE v_I <= LENGTH(v_CODETXT) LOOP
    	v_FOUR := SUBSTR(v_CODETXT,v_I,4);
		v_FOUR := REPLACE(v_FOUR, '=', '');
        v_NUMPAD := 4-LENGTH(v_FOUR);
        v_VALS6B0 := BASE64DIGIT(SUBSTR(v_FOUR,1,1));
        v_VALS6B1 := BASE64DIGIT(SUBSTR(v_FOUR,2,1));
        IF v_NUMPAD > 1 THEN v_VALS6B2 := 0; ELSE v_VALS6B2 := BASE64DIGIT(SUBSTR(v_FOUR,3,1)); END IF;
        IF v_NUMPAD > 0 THEN v_VALS6B3 := 0; ELSE v_VALS6B3 := BASE64DIGIT(SUBSTR(v_FOUR,4,1)); END IF;
        v_VALS8B0 := v_VALS6B0*4 + ((v_VALS6B1-MOD(v_VALS6B1,16)) / 16);
        v_VALS8B1 := MOD(v_VALS6B1,16)*16 + ((v_VALS6B2-MOD(v_VALS6B2,4)) / 4);
        v_VALS8B2 := MOD(v_VALS6B2,4)*64 + v_VALS6B3;
        v_NEWSTR := UTL_RAW.CONCAT(v_NEWSTR,BYTE_TO_RAW(v_VALS8B0));
        IF v_NUMPAD < 2 THEN v_NEWSTR := UTL_RAW.CONCAT(v_NEWSTR,BYTE_TO_RAW(v_VALS8B1)); END IF;
        IF v_NUMPAD < 1 THEN v_NEWSTR := UTL_RAW.CONCAT(v_NEWSTR,BYTE_TO_RAW(v_VALS8B2)); END IF;
		v_I := v_I + 4;
	END LOOP;
	RETURN v_NEWSTR;
END BASE64DECODE_TO_RAW;
----------------------------------------------------------------------------------------------------
FUNCTION BASE64DECODE
	(
    p_CODETXT IN CLOB
    ) RETURN BLOB IS
v_CODETXT CLOB;
v_I BINARY_INTEGER;
v_NEWSTR BLOB;
v_LEN BINARY_INTEGER;
v_FOUR VARCHAR2(4);
v_VALS8B0 BINARY_INTEGER;
v_VALS8B1 BINARY_INTEGER;
v_VALS8B2 BINARY_INTEGER;
v_VALS6B0 BINARY_INTEGER;
v_VALS6B1 BINARY_INTEGER;
v_VALS6B2 BINARY_INTEGER;
v_VALS6B3 BINARY_INTEGER;
v_NUMPAD BINARY_INTEGER;
BEGIN
	DBMS_LOB.CREATETEMPORARY(v_NEWSTR, TRUE);

	IF p_CODETXT IS NULL THEN
		RETURN NULL;
	END IF;

	--Strip whitespace from Codetxt.
	v_CODETXT := REGEXP_REPLACE(p_CODETXT, '\s');

	v_LEN := DBMS_LOB.GETLENGTH(v_CODETXT);
	IF v_LEN = 0 THEN
		RETURN v_NEWSTR;
	END IF;

	DBMS_LOB.OPEN(v_NEWSTR, DBMS_LOB.LOB_READWRITE);

	v_I := 1;
	WHILE v_I <= v_LEN LOOP
    	v_FOUR := DBMS_LOB.SUBSTR(v_CODETXT,LEAST(4,v_LEN-v_I+1),v_I);
		v_FOUR := REPLACE(v_FOUR, '=', '');
        v_NUMPAD := 4-LENGTH(v_FOUR);
        v_VALS6B0 := BASE64DIGIT(SUBSTR(v_FOUR,1,1));
        v_VALS6B1 := BASE64DIGIT(SUBSTR(v_FOUR,2,1));
        IF v_NUMPAD > 1 THEN v_VALS6B2 := 0; ELSE v_VALS6B2 := BASE64DIGIT(SUBSTR(v_FOUR,3,1)); END IF;
        IF v_NUMPAD > 0 THEN v_VALS6B3 := 0; ELSE v_VALS6B3 := BASE64DIGIT(SUBSTR(v_FOUR,4,1)); END IF;
        v_VALS8B0 := v_VALS6B0*4 + ((v_VALS6B1-MOD(v_VALS6B1,16)) / 16);
        v_VALS8B1 := MOD(v_VALS6B1,16)*16 + ((v_VALS6B2-MOD(v_VALS6B2,4)) / 4);
        v_VALS8B2 := MOD(v_VALS6B2,4)*64 + v_VALS6B3;
        DBMS_LOB.WRITEAPPEND(v_NEWSTR,1,BYTE_TO_RAW(v_VALS8B0));
        IF v_NUMPAD < 2 THEN DBMS_LOB.WRITEAPPEND(v_NEWSTR,1,BYTE_TO_RAW(v_VALS8B1)); END IF;
        IF v_NUMPAD < 1 THEN DBMS_LOB.WRITEAPPEND(v_NEWSTR,1,BYTE_TO_RAW(v_VALS8B2)); END IF;
		v_I := v_I + 4;
	END LOOP;

	DBMS_LOB.CLOSE(v_NEWSTR);

	RETURN v_NEWSTR;
END BASE64DECODE;
----------------------------------------------------------------------------------------------------
-- Append the source CLOB to the destination CLOB, but in Base64 and URL-encoded form
PROCEDURE BASE64_APPEND(p_DEST IN OUT NOCOPY CLOB, p_SRC IN CLOB) AS
v_I   PLS_INTEGER;
v_LEN PLS_INTEGER;
v_DATA VARCHAR2(4092); -- big enough to hold worst case of 1023 bytes after base64 and URL encoding
BEGIN
    v_I := 1;
    v_LEN := DBMS_LOB.GETLENGTH(p_SRC);
    WHILE v_I <= v_LEN LOOP
		-- buffer length is multiple of 3 since base64 encoding uses chunks of 3 bytes
    	IF v_I + 1023 < v_LEN THEN
			v_DATA := URL_ENCODE(
						BASE64ENCODE(
							DBMS_LOB.SUBSTR(p_SRC, 1023, v_I)
						),
						TRUE
					  );
       	ELSE
			v_DATA := URL_ENCODE(
						BASE64ENCODE(
							DBMS_LOB.SUBSTR(p_SRC, v_LEN-v_I+1, v_I)
						),
						TRUE
					  );
       	END IF;

		DBMS_LOB.WRITEAPPEND(p_DEST, LENGTH(v_DATA), v_DATA);
       	v_I := v_I + 1023;
    END LOOP;
END BASE64_APPEND;
----------------------------------------------------------------------------------------------------
-- Append the source BLOB to the destination CLOB, but in Base64 and URL-encoded form
PROCEDURE APPEND(p_DEST IN OUT NOCOPY CLOB, p_SRC IN BLOB) AS
v_I   PLS_INTEGER;
v_LEN PLS_INTEGER;
v_DATA VARCHAR2(4092); -- big enough to hold worst case of 1023 bytes after base64 and URL encoding
BEGIN
    v_I := 1;
    v_LEN := DBMS_LOB.GETLENGTH(p_SRC);
    WHILE v_I <= v_LEN LOOP
		-- buffer length is multiple of 3 since base64 encoding uses chunks of 3 bytes
    	IF v_I + 1023 < v_LEN THEN
			v_DATA := URL_ENCODE(
						UTL_RAW.CAST_TO_VARCHAR2(
							UTL_ENCODE.BASE64_ENCODE(
								DBMS_LOB.SUBSTR(p_SRC, 1023, v_I)
							)
						),
						TRUE
					  );
       	ELSE
			v_DATA := URL_ENCODE(
						UTL_RAW.CAST_TO_VARCHAR2(
							UTL_ENCODE.BASE64_ENCODE(
							DBMS_LOB.SUBSTR(p_SRC, v_LEN-v_I+1, v_I)
							)
						),
						TRUE
					  );
       	END IF;

		DBMS_LOB.WRITEAPPEND(p_DEST, LENGTH(v_DATA), v_DATA);
       	v_I := v_I + 1023;
    END LOOP;
END APPEND;
----------------------------------------------------------------------------------------------------
-- Append the source CLOB to the destination CLOB, but in URL-encoded form
PROCEDURE APPEND(p_DEST IN OUT NOCOPY CLOB, p_SRC IN CLOB) AS
v_I   PLS_INTEGER;
v_LEN PLS_INTEGER;
v_DATA VARCHAR2(3072); -- big enough to hold worst case of 1024 bytes after URL encoding
BEGIN
    v_I := 1;
    v_LEN := DBMS_LOB.GETLENGTH(p_SRC);
    WHILE v_I <= v_LEN LOOP
		-- buffer length is multiple of 3 since base64 encoding uses chunks of 3 bytes
    	IF v_I + 1024 < v_LEN THEN
			v_DATA := URL_ENCODE(
						DBMS_LOB.SUBSTR(p_SRC, 1024, v_I),
						TRUE
					  );
       	ELSE
			v_DATA := URL_ENCODE(
						DBMS_LOB.SUBSTR(p_SRC, v_LEN-v_I+1, v_I),
						TRUE
					  );
       	END IF;

		DBMS_LOB.WRITEAPPEND(p_DEST, LENGTH(v_DATA), v_DATA);
       	v_I := v_I + 1024;
    END LOOP;
END APPEND;
----------------------------------------------------------------------------------------------------
PROCEDURE INTERNAL_BUILD_QUERY_STRING
	(
    p_VAR_NAME IN VARCHAR2,
	p_VAR_IS_BINARY IN BOOLEAN,
    p_VAR_VALUE IN CLOB,
    p_VAR_BINARY_VALUE IN BLOB,
    p_QUERY_STRING IN OUT NOCOPY CLOB,
    p_PRETTY_QUERY_STRING IN OUT NOCOPY CLOB,
    p_EXCLUDE_FROM_PRETTY IN BOOLEAN,
	p_VAR_PRETTY_VALUE IN CLOB,
	p_BASE64_ENCODE IN BOOLEAN
    ) AS
v_TEXT VARCHAR2(32767);
BEGIN
	-- build encoded query string
	IF DBMS_LOB.GETLENGTH(p_QUERY_STRING) > 0 THEN
    	DBMS_LOB.WRITEAPPEND(p_QUERY_STRING,1,'&');
	END IF;
    v_TEXT := URL_ENCODE(p_VAR_NAME,TRUE);
    DBMS_LOB.WRITEAPPEND(p_QUERY_STRING,LENGTH(v_TEXT)+1,v_TEXT||'=');

	IF p_VAR_IS_BINARY THEN
		APPEND(p_QUERY_STRING,p_VAR_BINARY_VALUE);
	ELSIF p_BASE64_ENCODE THEN
		BASE64_APPEND(p_QUERY_STRING,p_VAR_VALUE);
	ELSE
		APPEND(p_QUERY_STRING,p_VAR_VALUE);
	END IF;

    -- then build the "pretty" query string
    IF NOT p_EXCLUDE_FROM_PRETTY THEN
		DBMS_LOB.WRITEAPPEND(p_PRETTY_QUERY_STRING,LENGTH(p_VAR_NAME)+1,p_VAR_NAME||'=');
		IF p_VAR_PRETTY_VALUE IS NOT NULL THEN
			DBMS_LOB.APPEND(p_PRETTY_QUERY_STRING,p_VAR_PRETTY_VALUE);
		ELSIF p_VAR_IS_BINARY THEN
			v_TEXT := '<binary data: '||TRIM(TO_CHAR(DBMS_LOB.GETLENGTH(p_VAR_BINARY_VALUE),'9G999G999G999'))||' bytes>';
			DBMS_LOB.WRITEAPPEND(p_PRETTY_QUERY_STRING,LENGTH(v_TEXT),v_TEXT);
		ELSE
			DBMS_LOB.APPEND(p_PRETTY_QUERY_STRING,p_VAR_VALUE);
		END IF;
	    DBMS_LOB.WRITEAPPEND(p_PRETTY_QUERY_STRING,2,CHR(10)||CHR(13));
	END IF;
END INTERNAL_BUILD_QUERY_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE BUILD_QUERY_STRING
	(
    p_VAR_NAME IN VARCHAR2,
    p_VAR_VALUE IN CLOB,
    p_QUERY_STRING IN OUT NOCOPY CLOB,
    p_PRETTY_QUERY_STRING IN OUT NOCOPY CLOB,
    p_EXCLUDE_FROM_PRETTY IN BOOLEAN := FALSE,
	p_VAR_PRETTY_VALUE IN CLOB := NULL,
	p_BASE64_ENCODE IN BOOLEAN := FALSE
    ) AS
BEGIN
	INTERNAL_BUILD_QUERY_STRING(p_VAR_NAME,FALSE,p_VAR_VALUE,NULL,p_QUERY_STRING,p_PRETTY_QUERY_STRING,
					   			p_EXCLUDE_FROM_PRETTY,p_VAR_PRETTY_VALUE,p_BASE64_ENCODE);
END BUILD_QUERY_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE BUILD_QUERY_STRING
	(
    p_VAR_NAME IN VARCHAR2,
    p_VAR_VALUE IN VARCHAR2,
    p_QUERY_STRING IN OUT NOCOPY CLOB,
    p_PRETTY_QUERY_STRING IN OUT NOCOPY CLOB,
    p_EXCLUDE_FROM_PRETTY IN BOOLEAN := FALSE,
	p_VAR_PRETTY_VALUE IN VARCHAR2 := NULL,
	p_BASE64_ENCODE IN BOOLEAN := FALSE
    ) AS
BEGIN
	BUILD_QUERY_STRING(p_VAR_NAME,TO_CLOB(p_VAR_VALUE),p_QUERY_STRING,p_PRETTY_QUERY_STRING,p_EXCLUDE_FROM_PRETTY,TO_CLOB(p_VAR_PRETTY_VALUE),p_BASE64_ENCODE);
END BUILD_QUERY_STRING;
----------------------------------------------------------------------------------------------------
PROCEDURE BUILD_QUERY_STRING
	(
    p_VAR_NAME IN VARCHAR2,
    p_VAR_VALUE IN BLOB,
    p_QUERY_STRING IN OUT NOCOPY CLOB,
    p_PRETTY_QUERY_STRING IN OUT NOCOPY CLOB,
    p_EXCLUDE_FROM_PRETTY IN BOOLEAN := FALSE,
	p_VAR_PRETTY_VALUE IN CLOB := NULL
    ) AS
BEGIN
	INTERNAL_BUILD_QUERY_STRING(p_VAR_NAME,TRUE,NULL,p_VAR_VALUE,p_QUERY_STRING,p_PRETTY_QUERY_STRING,
							    p_EXCLUDE_FROM_PRETTY,p_VAR_PRETTY_VALUE,TRUE);
END BUILD_QUERY_STRING;
----------------------------------------------------------------------------------------------------
FUNCTION HEX_ENCODE
	(
	p_DATA IN RAW
	) RETURN VARCHAR2 IS
v_LEN BINARY_INTEGER;
v_IDX BINARY_INTEGER;
v_RET VARCHAR2(32767) := '';
BEGIN
	IF p_DATA IS NULL THEN
		RETURN NULL;
	END IF;

	v_LEN := UTL_RAW.LENGTH(p_DATA);
	FOR v_IDX IN 1..v_LEN LOOP
		v_RET := v_RET||HEX_BYTE(UTL_RAW.CAST_TO_BINARY_INTEGER(UTL_RAW.SUBSTR(p_DATA,v_IDX,1),UTL_RAW.LITTLE_ENDIAN));
	END LOOP;

	RETURN v_RET;
END HEX_ENCODE;
----------------------------------------------------------------------------------------------------
FUNCTION DECODE_HEX_DIGIT
	(
	p_DIGIT IN VARCHAR2
	) RETURN BINARY_INTEGER IS
v_DIGIT BINARY_INTEGER;
BEGIN
	v_DIGIT := ASCII(UPPER(p_DIGIT));
	IF v_DIGIT BETWEEN ASCII('0') AND ASCII('9') THEN
		RETURN v_DIGIT - ASCII('0');
	ELSE
		RETURN v_DIGIT - ASCII('A') + 10;
	END IF;
END DECODE_HEX_DIGIT;
----------------------------------------------------------------------------------------------------
FUNCTION DECODE_HEX_BYTE
	(
	p_BYTE IN VARCHAR2
	) RETURN RAW IS
v_BYTE BINARY_INTEGER;
BEGIN
	v_BYTE := DECODE_HEX_DIGIT(SUBSTR(p_BYTE,1,1))*16 + DECODE_HEX_DIGIT(SUBSTR(p_BYTE,2,1));

	RETURN UTL_RAW.SUBSTR(UTL_RAW.CAST_FROM_BINARY_INTEGER(v_BYTE, UTL_RAW.LITTLE_ENDIAN), 1, 1);
END DECODE_HEX_BYTE;
----------------------------------------------------------------------------------------------------
FUNCTION HEX_DECODE
	(
	p_DATA IN VARCHAR2
	) RETURN RAW IS
v_LEN BINARY_INTEGER;
v_IDX BINARY_INTEGER;
v_RET RAW(32767) := NULL;
BEGIN
	IF p_DATA IS NULL THEN
		RETURN NULL;
	END IF;

	v_LEN := LENGTH(p_DATA);
	v_IDX := 1;
	WHILE v_IDX <= v_LEN LOOP
		IF v_RET IS NULL THEN
			v_RET := DECODE_HEX_BYTE(SUBSTR(p_DATA,v_IDX,2));
		ELSE
			v_RET := UTL_RAW.CONCAT(v_RET, DECODE_HEX_BYTE(SUBSTR(p_DATA,v_IDX,2)));
		END IF;
		v_IDX := v_IDX+2;
	END LOOP;

	RETURN v_RET;
END HEX_DECODE;
----------------------------------------------------------------------------------------------------
END CD;
/
