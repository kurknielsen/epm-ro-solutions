CREATE OR REPLACE PACKAGE BODY ML IS
-----------------------------------------------------------------------------------------------------------
-- A unique string that demarcates boundaries of parts in a multi-part email
-- The string should not appear inside the body of any part of the email.
-- Customize this if needed or generate this randomly dynamically.
BOUNDARY CONSTANT VARCHAR2(256) := '-----7D81B75CCC90D2974F7A1CBD';
-- A MIME type that denotes multi-part email (MIME) messages.
MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary="' || BOUNDARY || '"';

FIRST_BOUNDARY CONSTANT VARCHAR2(256) := '--' || BOUNDARY || UTL_TCP.CRLF;
LAST_BOUNDARY  CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' || UTL_TCP.CRLF;

MAX_BASE64_LINE_WIDTH CONSTANT PLS_INTEGER := 76 / 4 * 3;

-- Customize the signature that will appear in the email's MIME header.
-- Useful for versioning.
MAILER_ID VARCHAR2(256) := 'Retail Operations Mailer (Oracle UTL_SMTP)'; --@@Implementation Override--
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR IS
BEGIN
RETURN '$Revision: 1.9 $';
END WHAT_VERSION;
----------------------------------------------------------------------------------------------------
-- E-mail Routines
------------------
-- These routines simply populate the EMAIL_LOG table with an e-mail. The mail() and end_mail()
-- routines have a boolean parameter that indicates whether the e-mail should be sent immediately.
-- If this flag is true, the e-mail will be processed. Otherwise, its status in the log will be set
-- to Pending, and the next job that processes pending e-mails will send it.
-----------------------------------------------------------------------------------------------------------
-- Return the next email address in the list of email addresses, separated
-- by either a "," or a ";".  The format of mailbox may be in one of these:
--   someone@some-domain
--   "Someone at some domain" <someone@some-domain>
--   Someone at some domain <someone@some-domain>
FUNCTION GET_ADDRESS(ADDR_LIST IN OUT VARCHAR2) RETURN VARCHAR2 IS

	ADDR VARCHAR2(256);
	I    PLS_INTEGER;
	------------------------------
	FUNCTION LOOKUP_UNQUOTED_CHAR
	(
		STR  IN VARCHAR2,
		CHRS IN VARCHAR2
	) RETURN PLS_INTEGER AS
		C            VARCHAR2(5);
		I            PLS_INTEGER;
		LEN          PLS_INTEGER;
		INSIDE_QUOTE BOOLEAN;
	BEGIN
		INSIDE_QUOTE := FALSE;
		I := 1;
		LEN := LENGTH(STR);
		WHILE (I <= LEN) LOOP

			C := SUBSTR(STR, I, 1);

			IF (INSIDE_QUOTE) THEN
				IF (C = '"') THEN
					INSIDE_QUOTE := FALSE;
				ELSIF (C = '\') THEN
					I := I + 1; -- Skip the quote character
				END IF;
			ELSIF (C = '"') THEN
				INSIDE_QUOTE := TRUE;
			ELSIF (INSTR(CHRS, C) >= 1) THEN
				RETURN I;
			END IF;

			I := I + 1;

		END LOOP;

		RETURN 0;

	END LOOKUP_UNQUOTED_CHAR;
	------------------------------
BEGIN

	ADDR_LIST := LTRIM(ADDR_LIST);
	I := LOOKUP_UNQUOTED_CHAR(ADDR_LIST, ',;');
	IF (I >= 1) THEN
		ADDR := SUBSTR(ADDR_LIST, 1, I - 1);
		ADDR_LIST := SUBSTR(ADDR_LIST, I + 1);
	ELSE
		ADDR := ADDR_LIST;
		ADDR_LIST := '';
	END IF;

	I := LOOKUP_UNQUOTED_CHAR(ADDR, '<');
	IF (I >= 1) THEN
		ADDR := SUBSTR(ADDR, I + 1);
		I := INSTR(ADDR, '>');
		IF (I >= 1) THEN
			ADDR := SUBSTR(ADDR, 1, I - 1);
		END IF;
	END IF;

	RETURN ADDR;

END GET_ADDRESS;
-----------------------------------------------------------------------------------------------------------
PROCEDURE MAIL
	(
	CATEGORY         IN VARCHAR2,
	SENDER           IN VARCHAR2,
	SUBJECT          IN VARCHAR2,
	MESSAGE          IN VARCHAR2,
	TO_RECIPIENTS    IN VARCHAR2,
	CC_RECIPIENTS    IN VARCHAR2 := NULL,
	BCC_RECIPIENTS   IN VARCHAR2 := NULL,
	SEND_DATE        IN DATE := NULL,
	PRIORITY         IN PLS_INTEGER := NULL
	) AS
EMAIL EMAIL_REC;
BEGIN

	EMAIL := BEGIN_MAIL(CATEGORY, SENDER, SUBJECT, TO_RECIPIENTS, CC_RECIPIENTS, BCC_RECIPIENTS, PRIORITY);
	ATTACH_TEXT(EMAIL, MESSAGE);
	END_MAIL(EMAIL, SEND_DATE);

END MAIL;
-----------------------------------------------------------------------------------------------------------
FUNCTION BEGIN_MAIL
	(
	CATEGORY IN VARCHAR2,
	SENDER   IN VARCHAR2,
	SUBJECT  IN VARCHAR2,
	PRIORITY IN PLS_INTEGER := NULL
	) RETURN EMAIL_REC IS
EMAIL      EMAIL_REC;
EMAIL_ID NUMBER(9);
MY_SENDER  VARCHAR2(32767) := SENDER;
FROM_ADDR  VARCHAR2(32767);
BEGIN

	SELECT MLID.NEXTVAL INTO EMAIL_ID FROM DUAL;
	FROM_ADDR := GET_ADDRESS(MY_SENDER);

	INSERT INTO EMAIL_LOG
		(EMAIL_ID, EMAIL_CATEGORY, EMAIL_STATUS, FROM_ADDRESS, SUBJECT, PRIORITY, ENTRY_DATE)
	VALUES
		(BEGIN_MAIL.EMAIL_ID, CATEGORY, c_STATUS_PENDING, FROM_ADDR, BEGIN_MAIL.SUBJECT, BEGIN_MAIL.PRIORITY, SYSDATE);

	EMAIL.EMAIL_ID := EMAIL_ID;
	EMAIL.ATTACHMENT_COUNT := 0;
	EMAIL.CURRENT_ATTACHMENT := NULL;
	RETURN EMAIL;

END BEGIN_MAIL;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ADD_RECIPIENT
	(
	EMAIL          IN OUT NOCOPY EMAIL_REC,
	RECIPIENT_TYPE IN VARCHAR2,
	RECIPIENT_ADDR IN VARCHAR2
	) AS
BEGIN
	INSERT INTO EMAIL_LOG_RECIPIENT
		(EMAIL_ID, RECIPIENT_TYPE, RECIPIENT_ADDRESS)
	VALUES
		(EMAIL.EMAIL_ID, ADD_RECIPIENT.RECIPIENT_TYPE, ADD_RECIPIENT.RECIPIENT_ADDR);
END ADD_RECIPIENT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ADD_RECIPIENT
	(
	EMAIL          IN OUT NOCOPY EMAIL_REC,
	RECIPIENT_ADDR IN VARCHAR2
	) AS
BEGIN
	ADD_RECIPIENT(EMAIL, c_TO, RECIPIENT_ADDR);
END ADD_RECIPIENT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ADD_CC_RECIPIENT
	(
	EMAIL          IN OUT NOCOPY EMAIL_REC,
	RECIPIENT_ADDR IN VARCHAR2
	) AS
BEGIN
	ADD_RECIPIENT(EMAIL, c_CC, RECIPIENT_ADDR);
END ADD_CC_RECIPIENT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ADD_BCC_RECIPIENT
	(
	EMAIL          IN OUT NOCOPY EMAIL_REC,
	RECIPIENT_ADDR IN VARCHAR2
	) AS
BEGIN
	ADD_RECIPIENT(EMAIL, c_BCC, RECIPIENT_ADDR);
END ADD_BCC_RECIPIENT;
-----------------------------------------------------------------------------------------------------------
FUNCTION BEGIN_MAIL
	(
	CATEGORY       IN VARCHAR2,
	SENDER         IN VARCHAR2,
	SUBJECT        IN VARCHAR2,
	TO_RECIPIENTS  IN VARCHAR2,
	CC_RECIPIENTS  IN VARCHAR2 := NULL,
	BCC_RECIPIENTS IN VARCHAR2 := NULL,
	PRIORITY       IN PLS_INTEGER := NULL
	) RETURN EMAIL_REC IS

MY_RECIPIENTS VARCHAR2(32767);
EMAIL         EMAIL_REC;
BEGIN
	EMAIL := BEGIN_MAIL(CATEGORY, SENDER, SUBJECT, PRIORITY);

	-- TO:
	MY_RECIPIENTS := TO_RECIPIENTS;
	WHILE MY_RECIPIENTS IS NOT NULL LOOP
		ADD_RECIPIENT(EMAIL, GET_ADDRESS(MY_RECIPIENTS));
	END LOOP;
	-- CC:
	MY_RECIPIENTS := CC_RECIPIENTS;
	WHILE MY_RECIPIENTS IS NOT NULL LOOP
		ADD_CC_RECIPIENT(EMAIL, GET_ADDRESS(MY_RECIPIENTS));
	END LOOP;
	-- BCC:
	MY_RECIPIENTS := BCC_RECIPIENTS;
	WHILE MY_RECIPIENTS IS NOT NULL LOOP
		ADD_BCC_RECIPIENT(EMAIL, GET_ADDRESS(MY_RECIPIENTS));
	END LOOP;

	RETURN EMAIL;
END BEGIN_MAIL;
-----------------------------------------------------------------------------------------------------------
PROCEDURE WRITE_TEXT
	(
	EMAIL   IN OUT NOCOPY EMAIL_REC,
	MESSAGE IN VARCHAR2
	) AS
BEGIN
	DBMS_LOB.WRITEAPPEND(EMAIL.CURRENT_ATTACHMENT, LENGTH(MESSAGE), MESSAGE);
END WRITE_TEXT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE WRITE_CLOB
	(
	EMAIL   IN OUT NOCOPY EMAIL_REC,
	MESSAGE IN CLOB
	) AS
BEGIN
	DBMS_LOB.APPEND(EMAIL.CURRENT_ATTACHMENT, MESSAGE);
END WRITE_CLOB;
-----------------------------------------------------------------------------------------------------------
FUNCTION B64ENCODE(MSG IN RAW) RETURN VARCHAR2 IS
BEGIN
	RETURN UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(MSG));
END B64ENCODE;
-----------------------------------------------------------------------------------------------------------
PROCEDURE WRITE_RAW_BASE64
	(
	EMAIL   IN OUT NOCOPY EMAIL_REC,
	MESSAGE IN RAW
	) AS
I   PLS_INTEGER;
LEN PLS_INTEGER;
BEGIN

	-- Split the Base64-encoded attachment into multiple lines
	I := 1;
	LEN := UTL_RAW.LENGTH(MESSAGE);
	WHILE (I <= LEN) LOOP
		IF (I + MAX_BASE64_LINE_WIDTH < LEN) THEN
			WRITE_TEXT(EMAIL, B64ENCODE(UTL_RAW.SUBSTR(MESSAGE, I, MAX_BASE64_LINE_WIDTH)));
		ELSE
			WRITE_TEXT(EMAIL, B64ENCODE(UTL_RAW.SUBSTR(MESSAGE, I, LEN - I + 1)));
		END IF;
		WRITE_TEXT(EMAIL, UTL_TCP.CRLF);
		I := I + MAX_BASE64_LINE_WIDTH;
	END LOOP;

END WRITE_RAW_BASE64;
-----------------------------------------------------------------------------------------------------------
PROCEDURE WRITE_BLOB_BASE64
	(
	EMAIL   IN OUT NOCOPY EMAIL_REC,
	MESSAGE IN BLOB
	) AS
I   PLS_INTEGER;
LEN PLS_INTEGER;
BEGIN

	-- Split the Base64-encoded attachment into multiple lines
	I := 1;
	LEN := DBMS_LOB.GETLENGTH(MESSAGE);
	WHILE (I <= LEN) LOOP
		IF (I + MAX_BASE64_LINE_WIDTH < LEN) THEN
			WRITE_TEXT(EMAIL, B64ENCODE(DBMS_LOB.SUBSTR(MESSAGE, MAX_BASE64_LINE_WIDTH, I)));
		ELSE
			WRITE_TEXT(EMAIL, B64ENCODE(DBMS_LOB.SUBSTR(MESSAGE, LEN - I + 1, I)));
		END IF;
		WRITE_TEXT(EMAIL, UTL_TCP.CRLF);
		I := I + MAX_BASE64_LINE_WIDTH;
	END LOOP;

END WRITE_BLOB_BASE64;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ATTACH_TEXT
	(
	EMAIL     IN OUT NOCOPY EMAIL_REC,
	DATA      IN VARCHAR2,
	MIME_TYPE IN VARCHAR2 := CONSTANTS.MIME_TYPE_TEXT,
	INLINE    IN BOOLEAN := TRUE,
	FILENAME  IN VARCHAR2 := NULL
	) AS
BEGIN
	BEGIN_ATTACHMENT(EMAIL, MIME_TYPE, INLINE, FILENAME);
	WRITE_TEXT(EMAIL, DATA);
	END_ATTACHMENT(EMAIL);
END ATTACH_TEXT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ATTACH_CLOB
	(
	EMAIL     IN OUT NOCOPY EMAIL_REC,
	DATA      IN CLOB,
	MIME_TYPE IN VARCHAR2 := CONSTANTS.MIME_TYPE_TEXT,
	INLINE    IN BOOLEAN := TRUE,
	FILENAME  IN VARCHAR2 := NULL
	) AS
BEGIN
	BEGIN_ATTACHMENT(EMAIL, MIME_TYPE, INLINE, FILENAME);
	WRITE_CLOB(EMAIL, DATA);
	END_ATTACHMENT(EMAIL);
END ATTACH_CLOB;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ATTACH_RAW
	(
	EMAIL     IN OUT NOCOPY EMAIL_REC,
	DATA      IN RAW,
	MIME_TYPE IN VARCHAR2 := CONSTANTS.MIME_TYPE_BINARY,
	INLINE    IN BOOLEAN := TRUE,
	FILENAME  IN VARCHAR2 := NULL
	) AS
BEGIN
	BEGIN_ATTACHMENT(EMAIL, MIME_TYPE, INLINE, FILENAME, c_BASE64_ENCODING);
	WRITE_RAW_BASE64(EMAIL, DATA);
	END_ATTACHMENT(EMAIL);
END ATTACH_RAW;
-----------------------------------------------------------------------------------------------------------
PROCEDURE ATTACH_BLOB
	(
	EMAIL     IN OUT NOCOPY EMAIL_REC,
	DATA      IN BLOB,
	MIME_TYPE IN VARCHAR2 := CONSTANTS.MIME_TYPE_BINARY,
	INLINE    IN BOOLEAN := TRUE,
	FILENAME  IN VARCHAR2 := NULL
	) AS
BEGIN
	BEGIN_ATTACHMENT(EMAIL, MIME_TYPE, INLINE, FILENAME, c_BASE64_ENCODING);
	WRITE_BLOB_BASE64(EMAIL, DATA);
	END_ATTACHMENT(EMAIL);
END ATTACH_BLOB;
-----------------------------------------------------------------------------------------------------------
PROCEDURE BEGIN_ATTACHMENT
	(
	EMAIL        IN OUT NOCOPY EMAIL_REC,
	MIME_TYPE    IN VARCHAR2 := CONSTANTS.MIME_TYPE_TEXT,
	INLINE       IN BOOLEAN := TRUE,
	FILENAME     IN VARCHAR2 := NULL,
	TRANSFER_ENC IN VARCHAR2 := NULL
	) AS

	V_IS_INLINE NUMBER(1);
BEGIN
	EMAIL.ATTACHMENT_COUNT := EMAIL.ATTACHMENT_COUNT + 1;

	IF INLINE THEN
		V_IS_INLINE := 1;
	ELSE
		V_IS_INLINE := 0;
	END IF;

	INSERT INTO EMAIL_LOG_ATTACHMENT
		(EMAIL_ID, CONTENT_ORDER, FILE_NAME, CONTENT_TYPE, IS_INLINE, TRANSFER_ENCODING, CONTENTS)
	VALUES
		(EMAIL.EMAIL_ID, EMAIL.ATTACHMENT_COUNT, FILENAME, MIME_TYPE, V_IS_INLINE, TRANSFER_ENC, NULL);

	DBMS_LOB.CREATETEMPORARY(EMAIL.CURRENT_ATTACHMENT, TRUE);
	DBMS_LOB.OPEN(EMAIL.CURRENT_ATTACHMENT, DBMS_LOB.LOB_READWRITE);

END BEGIN_ATTACHMENT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE END_ATTACHMENT(EMAIL IN OUT NOCOPY EMAIL_REC) AS
BEGIN
	DBMS_LOB.CLOSE(EMAIL.CURRENT_ATTACHMENT);

	UPDATE EMAIL_LOG_ATTACHMENT
	SET CONTENTS = EMAIL.CURRENT_ATTACHMENT
	WHERE EMAIL_ID = EMAIL.EMAIL_ID
		  AND CONTENT_ORDER = EMAIL.ATTACHMENT_COUNT;

	IF DBMS_LOB.ISTEMPORARY(EMAIL.CURRENT_ATTACHMENT) = 1 THEN
		DBMS_LOB.FREETEMPORARY(EMAIL.CURRENT_ATTACHMENT);
	END IF;

	EMAIL.CURRENT_ATTACHMENT := NULL;

END END_ATTACHMENT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE END_MAIL
	(
	EMAIL		IN OUT NOCOPY EMAIL_REC,
	SEND_DATE   IN DATE := NULL
	) AS
BEGIN
	UPDATE EMAIL_LOG
	SET EMAIL_STATUS = c_STATUS_QUEUED,
		SEND_DATE    = NVL(END_MAIL.SEND_DATE, SYSDATE)
	WHERE EMAIL_ID = EMAIL.EMAIL_ID;
END END_MAIL;
-----------------------------------------------------------------------------------------------------------
-- SMTP Routines
----------------
-- These routines actually process an entry in the EMAIL_LOG table and send it to an SMTP server.
-- They utilize the UTL_SMTP Oracle package for sending the data.
-----------------------------------------------------------------------------------------------------------
-- Initialize info for SMTP server
PROCEDURE GET_SMTP_INFO
	(
	HOST   OUT VARCHAR2,
	PORT   OUT PLS_INTEGER,
	DOMAIN OUT VARCHAR2
	) AS

	TMP_STR VARCHAR2(256);
BEGIN
	-- SMTP Server Host Name/IP Address
	HOST := TRIM(GET_DICTIONARY_VALUE('Server Host', 0, 'System', 'SMTP'));

	-- SMTP Server Port Number
	TMP_STR := GET_DICTIONARY_VALUE('Server Port', 0, 'System', 'SMTP');
	IF NOT TMP_STR IS NULL THEN
		BEGIN
			PORT := TRIM(TO_NUMBER(TMP_STR));
		EXCEPTION
			WHEN OTHERS THEN
				NULL; -- ignore exception - use default port number
		END;
	END IF;
	-- assign default port
	IF PORT IS NULL THEN
		PORT := 25;
	END IF;

	-- E-mail Domain
	DOMAIN := TRIM(GET_DICTIONARY_VALUE('Client Domain', 0, 'System', 'SMTP'));

END GET_SMTP_INFO;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_RESET_SESSION(CONN IN OUT NOCOPY UTL_SMTP.CONNECTION) AS
BEGIN
	UTL_SMTP.RSET(CONN);
END SMTP_RESET_SESSION;
-----------------------------------------------------------------------------------------------------------
FUNCTION SMTP_AUTH_PLAIN
	(
	CONN     IN OUT UTL_SMTP.CONNECTION,
	USERID   IN VARCHAR2,
	PASSWORD IN VARCHAR2
	) RETURN BOOLEAN IS

	RESPONSE UTL_SMTP.REPLY;
	AUTHCODE VARCHAR2(200);

BEGIN
	AUTHCODE := CD.BASE64ENCODE(USERID || CHR(0) || USERID || CHR(0) || PASSWORD);
	RESPONSE := UTL_SMTP.COMMAND(CONN, 'AUTH', 'PLAIN ' || AUTHCODE);

	IF TRUNC(RESPONSE.CODE / 100) = 2 THEN
		RETURN TRUE; -- success
	END IF;

	RETURN FALSE;
END SMTP_AUTH_PLAIN;
-----------------------------------------------------------------------------------------------------------
FUNCTION SMTP_AUTH_LOGIN
	(
	CONN     IN OUT UTL_SMTP.CONNECTION,
	USERID   IN VARCHAR2,
	PASSWORD IN VARCHAR2
	) RETURN BOOLEAN IS

	RESPONSE UTL_SMTP.REPLY;

BEGIN
	RESPONSE := UTL_SMTP.COMMAND(CONN, 'AUTH', 'LOGIN');

	IF TRUNC(RESPONSE.CODE / 100) = 3 THEN
		-- username prompt
		RESPONSE := UTL_SMTP.COMMAND(CONN, CD.BASE64ENCODE(USERID));

		IF TRUNC(RESPONSE.CODE / 100) = 3 THEN
			-- password prompt
			RESPONSE := UTL_SMTP.COMMAND(CONN, CD.BASE64ENCODE(PASSWORD));

			IF TRUNC(RESPONSE.CODE / 100) = 2 THEN
				RETURN TRUE; -- success
			END IF;
		END IF;
	END IF;

	RETURN FALSE;
END SMTP_AUTH_LOGIN;
-----------------------------------------------------------------------------------------------------------
FUNCTION COMPUTE_CRAM_MD5_DIGEST
	(
	PASSWORD  IN VARCHAR2,
	CHALLENGE IN VARCHAR2
	) RETURN VARCHAR2 AS
LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.SmtpAuthMethods.cramMD5digest(java.lang.String,java.lang.String) return java.lang.String';
-----------------------------------------------------------------------------------------------------------
FUNCTION SMTP_AUTH_CRAMMD5
	(
	CONN     IN OUT UTL_SMTP.CONNECTION,
	USERID   IN VARCHAR2,
	PASSWORD IN VARCHAR2
	) RETURN BOOLEAN IS

	RESPONSE  UTL_SMTP.REPLY;
	CHALLENGE VARCHAR2(512);
	DIGEST    VARCHAR2(64);

BEGIN
	RESPONSE := UTL_SMTP.COMMAND(CONN, 'AUTH', 'CRAM-MD5');

	IF TRUNC(RESPONSE.CODE / 100) = 3 THEN
		-- MD5 challenge
		CHALLENGE := CD.BASE64DECODE(RESPONSE.TEXT);
		DIGEST := COMPUTE_CRAM_MD5_DIGEST(PASSWORD, CHALLENGE);
		RESPONSE := UTL_SMTP.COMMAND(CONN, CD.BASE64ENCODE(USERID || ' ' || DIGEST));

		IF TRUNC(RESPONSE.CODE / 100) = 2 THEN
			RETURN TRUE; -- success
		END IF;
	END IF;

	RETURN FALSE;
END SMTP_AUTH_CRAMMD5;
-----------------------------------------------------------------------------------------------------------
FUNCTION NTLM_INIT_MESSAGE(HOSTNAME IN VARCHAR2) RETURN VARCHAR2 AS
LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.SmtpAuthMethods.initMsgNTLM(java.lang.String) return java.lang.String';
-----------------------------------------------------------------------------------------------------------
FUNCTION NTLM_RESPONSE_MESSAGE
	(
	HOSTNAME  IN VARCHAR2,
	USERID    IN VARCHAR2,
	PASSWORD  IN VARCHAR2,
	CHALLENGE IN VARCHAR2,
	USEV2     IN NUMBER
	) RETURN VARCHAR2 AS
LANGUAGE JAVA NAME 'com.newenergyassoc.ro.oracleStoredProcs.SmtpAuthMethods.responseMsgNTLM(java.lang.String,java.lang.String,java.lang.String,java.lang.String,int) return java.lang.String';
-----------------------------------------------------------------------------------------------------------
FUNCTION SMTP_AUTH_NTLM
	(
	CONN     IN OUT UTL_SMTP.CONNECTION,
	USERID   IN VARCHAR2,
	PASSWORD IN VARCHAR2
	) RETURN BOOLEAN IS

	RESPONSE   UTL_SMTP.REPLY;
	CHALLENGE  VARCHAR2(512);
	MESSAGE    VARCHAR2(1024);
	HOSTNAME   VARCHAR2(64);
	HOSTDOMAIN VARCHAR2(64);
	USERDOMAIN VARCHAR2(64);
	FULLHOST   VARCHAR2(128);
	FULLUSER   VARCHAR2(128);
	USEV2B     BOOLEAN;
	USEV2      NUMBER;

BEGIN
	-- Get Domain names for server and default Domain name for users
	HOSTNAME := GET_DICTIONARY_VALUE('Client Hostname', 0, 'System', 'SMTP', 'NTLM');
	HOSTDOMAIN := GET_DICTIONARY_VALUE('Client Domain', 0, 'System', 'SMTP', 'NTLM');
	USERDOMAIN := GET_DICTIONARY_VALUE('User Domain', 0, 'System', 'SMTP', 'NTLM');
	USEV2B := NVL(GET_DICTIONARY_VALUE('Use NTLMv2', 0, 'System', 'SMTP', 'NTLM'), '0') = '1';
	IF USEV2B THEN
		USEV2 := 1;
	ELSE
		USEV2 := 0;
	END IF;

	FULLHOST := HOSTDOMAIN || '\' || HOSTNAME;
	-- if user-name from external credentials doesn't already specify
	-- domain, then add default user domain from system dictionary
	IF NVL(INSTR(USERID, '\'), 0) = 0 THEN
		FULLUSER := USERDOMAIN || '\' || USERID;
	ELSE
		FULLUSER := USERID;
	END IF;

	MESSAGE := NTLM_INIT_MESSAGE(FULLHOST);
	RESPONSE := UTL_SMTP.COMMAND(CONN, 'AUTH', 'NTLM ' || MESSAGE);

	IF TRUNC(RESPONSE.CODE / 100) = 3 THEN
		-- server challenge
		CHALLENGE := RESPONSE.TEXT;
		MESSAGE := NTLM_RESPONSE_MESSAGE(FULLHOST, FULLUSER, PASSWORD, CHALLENGE, USEV2);
		RESPONSE := UTL_SMTP.COMMAND(CONN, MESSAGE);

		IF TRUNC(RESPONSE.CODE / 100) = 2 THEN
			RETURN TRUE; -- success
		END IF;
	END IF;

	RETURN FALSE;
END SMTP_AUTH_NTLM;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_LOGIN
	(
	CONN     IN OUT UTL_SMTP.CONNECTION,
	DOMAIN   IN VARCHAR2,
	USERID   IN VARCHAR2,
	PASSWORD IN VARCHAR2
	) AS

	RESPONSES UTL_SMTP.REPLIES;
	IDX       BINARY_INTEGER;
	AUTH_STR  VARCHAR2(128) := NULL;
	METHODS   GA.STRING_TABLE;
	LOGGED_IN BOOLEAN := FALSE;

BEGIN
	RESPONSES := UTL_SMTP.EHLO(CONN, DOMAIN);

	IDX := RESPONSES.FIRST;
	WHILE RESPONSES.EXISTS(IDX) LOOP
		IF UPPER(SUBSTR(RESPONSES(IDX).TEXT, 1, 4)) = 'AUTH' THEN
			AUTH_STR := UPPER(SUBSTR(RESPONSES(IDX).TEXT, 6));
			EXIT;
		END IF;
		IDX := RESPONSES.NEXT(IDX);
	END LOOP;

	IF AUTH_STR IS NULL THEN
		-- can't find AUTH response?
		LOGS.LOG_INFO('AUTH extension does not appear to be supported - no authorization will be used');
		LOGGED_IN := TRUE;
	ELSE
		UT.TOKENS_FROM_STRING(AUTH_STR, ' ', METHODS);
		IDX := METHODS.FIRST;
		WHILE METHODS.EXISTS(IDX) AND NOT LOGGED_IN LOOP
			BEGIN
				IF UPPER(METHODS(IDX)) = 'PLAIN' THEN
					LOGGED_IN := SMTP_AUTH_PLAIN(CONN, USERID, PASSWORD);
				ELSIF UPPER(METHODS(IDX)) = 'LOGIN' THEN
					LOGGED_IN := SMTP_AUTH_LOGIN(CONN, USERID, PASSWORD);
				ELSIF UPPER(METHODS(IDX)) = 'CRAM-MD5' THEN
					LOGGED_IN := SMTP_AUTH_CRAMMD5(CONN, USERID, PASSWORD);
				ELSIF UPPER(METHODS(IDX)) = 'NTLM' THEN
					LOGGED_IN := SMTP_AUTH_NTLM(CONN, USERID, PASSWORD);
				END IF;
			EXCEPTION
				WHEN OTHERS THEN
					ERRS.LOG_AND_CONTINUE('Error while trying to login using ' || UPPER(METHODS(IDX)) || ' method');
					SMTP_RESET_SESSION(CONN);
			END;
			IDX := METHODS.NEXT(IDX);
		END LOOP;
	END IF;

	IF NOT LOGGED_IN THEN
		-- no method that we support?
		LOGS.LOG_INFO('Supported AUTH methods (PLAIN, LOGIN, CRAM-MD5, NTLM) either failed or were not found in server''s accepted methods: ' ||
						AUTH_STR);
	END IF;

END SMTP_LOGIN;
-----------------------------------------------------------------------------------------------------------
FUNCTION SMTP_BEGIN_SESSION RETURN UTL_SMTP.CONNECTION IS
	CONN     UTL_SMTP.CONNECTION;
	HOST     VARCHAR2(256);
	PORT     PLS_INTEGER;
	DOMAIN   VARCHAR2(256);
	USERID   VARCHAR2(32);
	PASSWORD VARCHAR2(32);
	CREDID   NUMBER(9);
BEGIN
	-- open SMTP connection
	GET_SMTP_INFO(HOST, PORT, DOMAIN);

	CONN := UTL_SMTP.OPEN_CONNECTION(HOST, PORT);
	-- get credentials first
	CREDID := SECURITY_CONTROLS.GET_EXTERNAL_CREDENTIAL_ID(EC.ES_SMTP, NULL);
	IF CREDID IS NOT NULL THEN
		SECURITY_CONTROLS.GET_EXTERNAL_UNAME_PASSWORD(CREDID, USERID, PASSWORD);
	END IF;

	IF USERID IS NULL OR PASSWORD IS NULL THEN
		-- problem getting credentials - do anonymous transaction
		LOGS.LOG_INFO('No credentials found for ''SMTP AUTH'' - no authorization will be used');
		UTL_SMTP.HELO(CONN, DOMAIN);
	ELSE
		PASSWORD := SECURITY_CONTROLS.DECODE(PASSWORD);
		-- otherwise login
		SMTP_LOGIN(CONN, DOMAIN, USERID, PASSWORD);
	END IF;
	RETURN CONN;
END SMTP_BEGIN_SESSION;
-----------------------------------------------------------------------------------------------------------
-- Write a MIME header
PROCEDURE SMTP_WRITE_MIME_HEADER
	(
	CONN  IN OUT NOCOPY UTL_SMTP.CONNECTION,
	NAME  IN VARCHAR2,
	VALUE IN VARCHAR2
	) AS
BEGIN
	UTL_SMTP.WRITE_DATA(CONN, NAME || ': ' || VALUE || UTL_TCP.CRLF);
END SMTP_WRITE_MIME_HEADER;
-----------------------------------------------------------------------------------------------------------
-- Mark a message-part boundary.  Set <last> to TRUE for the last boundary.
PROCEDURE SMTP_WRITE_BOUNDARY
	(
	CONN IN OUT NOCOPY UTL_SMTP.CONNECTION,
	LAST IN BOOLEAN := FALSE
	) AS
BEGIN
	IF LAST THEN
		UTL_SMTP.WRITE_DATA(CONN, LAST_BOUNDARY);
	ELSE
		UTL_SMTP.WRITE_DATA(CONN, FIRST_BOUNDARY);
	END IF;
END SMTP_WRITE_BOUNDARY;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_WRITE_CONTENT_HEADERS
	(
	CONN         IN OUT NOCOPY UTL_SMTP.CONNECTION,
	MIME_TYPE    IN VARCHAR2 := CONSTANTS.MIME_TYPE_TEXT,
	FILENAME     IN VARCHAR2 := NULL,
	INLINE       IN BOOLEAN := TRUE,
	TRANSFER_ENC IN VARCHAR2 := NULL
	) AS
BEGIN
	SMTP_WRITE_MIME_HEADER(CONN, 'Content-Type', MIME_TYPE);

	IF FILENAME IS NOT NULL THEN
		IF INLINE THEN
			SMTP_WRITE_MIME_HEADER(CONN, 'Content-Disposition', 'inline; filename="' || FILENAME || '"');
		ELSE
			SMTP_WRITE_MIME_HEADER(CONN, 'Content-Disposition', 'attachment; filename="' || FILENAME || '"');
		END IF;
	END IF;

	IF (TRANSFER_ENC IS NOT NULL) THEN
		SMTP_WRITE_MIME_HEADER(CONN, 'Content-Transfer-Encoding', TRANSFER_ENC);
	END IF;
END SMTP_WRITE_CONTENT_HEADERS;
-----------------------------------------------------------------------------------------------------------
FUNCTION GET_RECIPIENT_LIST(RECIPIENTS IN GA.BIG_STRING_TABLE) RETURN VARCHAR2 IS
	RECIPIENT_LIST VARCHAR2(32767) := NULL;
	I              BINARY_INTEGER;
BEGIN
	I := RECIPIENTS.FIRST;
	WHILE RECIPIENTS.EXISTS(I) LOOP
		IF RECIPIENT_LIST IS NULL THEN
			RECIPIENT_LIST := RECIPIENTS(I);
		ELSE
			RECIPIENT_LIST := RECIPIENT_LIST || ';' || RECIPIENTS(I);
		END IF;
		I := RECIPIENTS.NEXT(I);
	END LOOP;

	RETURN RECIPIENT_LIST;
END GET_RECIPIENT_LIST;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_BEGIN_MAIL
	(
	CONN           IN OUT NOCOPY UTL_SMTP.CONNECTION,
	SENDER         IN VARCHAR2,
	SUBJECT        IN VARCHAR2,
	TO_RECIPIENTS  IN GA.BIG_STRING_TABLE,
	CC_RECIPIENTS  IN GA.BIG_STRING_TABLE,
	BCC_RECIPIENTS IN GA.BIG_STRING_TABLE,
	MIME_TYPE      IN VARCHAR2 := CONSTANTS.MIME_TYPE_TEXT,
	FILENAME       IN VARCHAR2 := NULL,
	INLINE         IN BOOLEAN := TRUE,
	TRANSFER_ENC   IN VARCHAR2 := NULL,
	PRIORITY       IN BINARY_INTEGER := NULL
	) AS

	I               BINARY_INTEGER;
	FIXED_SUBJECT VARCHAR2(2000);

BEGIN

	-- Specify sender's address (our server allows bogus address
	-- as long as it is a full email address (xxx@yyy.com).
	UTL_SMTP.MAIL(CONN, SENDER);

	-- Specify recipient(s) of the email.
	-- TO:
	I := TO_RECIPIENTS.FIRST;
	WHILE TO_RECIPIENTS.EXISTS(I) LOOP
		UTL_SMTP.RCPT(CONN, TO_RECIPIENTS(I));
		I := TO_RECIPIENTS.NEXT(I);
	END LOOP;
	-- CC:
	I := CC_RECIPIENTS.FIRST;
	WHILE CC_RECIPIENTS.EXISTS(I) LOOP
		UTL_SMTP.RCPT(CONN, CC_RECIPIENTS(I));
		I := CC_RECIPIENTS.NEXT(I);
	END LOOP;
	-- BCC:
	I := BCC_RECIPIENTS.FIRST;
	WHILE BCC_RECIPIENTS.EXISTS(I) LOOP
		UTL_SMTP.RCPT(CONN, BCC_RECIPIENTS(I));
		I := BCC_RECIPIENTS.NEXT(I);
	END LOOP;

	-- Start body of email
	UTL_SMTP.OPEN_DATA(CONN);

	-- Set "From" MIME header
	SMTP_WRITE_MIME_HEADER(CONN, 'From', SENDER);

	-- Set "To" MIME header
	SMTP_WRITE_MIME_HEADER(CONN, c_TO, GET_RECIPIENT_LIST(TO_RECIPIENTS));

	-- Set "Cc" MIME header
	IF CC_RECIPIENTS IS NOT NULL THEN
		SMTP_WRITE_MIME_HEADER(CONN, c_CC, GET_RECIPIENT_LIST(CC_RECIPIENTS));
	END IF;

	-- Set "Subject" MIME header
	FIXED_SUBJECT := REPLACE(SUBJECT, CHR(10), ''); -- strip out newline and carriage return characters
	FIXED_SUBJECT := REPLACE(FIXED_SUBJECT, CHR(13), '');
	SMTP_WRITE_MIME_HEADER(CONN, 'Subject', FIXED_SUBJECT);

	-- Set Content headers
	SMTP_WRITE_CONTENT_HEADERS(CONN, MIME_TYPE, FILENAME, INLINE, TRANSFER_ENC);

	-- Set "X-Mailer" MIME header
	SMTP_WRITE_MIME_HEADER(CONN, 'X-Mailer', MAILER_ID);

	-- Set priority:
	--   High      Normal       Low
	--   1     2     3     4     5
	IF (PRIORITY IS NOT NULL) THEN
		SMTP_WRITE_MIME_HEADER(CONN,
							   'X-Priority',
							   GREATEST(LEAST(PRIORITY, c_PRIORITY_LOWEST), c_PRIORITY_HIGHEST));
	END IF;

	-- Send an empty line to denotes end of MIME headers and
	-- beginning of message body.
	UTL_SMTP.WRITE_DATA(CONN, UTL_TCP.CRLF);

	IF (LOWER(MIME_TYPE) LIKE 'multipart/mixed%') THEN
		UTL_SMTP.WRITE_DATA(CONN, 'This is a multi-part message in MIME format.' || UTL_TCP.CRLF);
	END IF;

END SMTP_BEGIN_MAIL;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_BEGIN_ATTACHMENT
	(
	CONN         IN OUT NOCOPY UTL_SMTP.CONNECTION,
	MIME_TYPE    IN VARCHAR2 := CONSTANTS.MIME_TYPE_TEXT,
	FILENAME     IN VARCHAR2 := NULL,
	INLINE       IN BOOLEAN := TRUE,
	TRANSFER_ENC IN VARCHAR2 := NULL
	) AS
BEGIN
	SMTP_WRITE_BOUNDARY(CONN);

	SMTP_WRITE_CONTENT_HEADERS(CONN, MIME_TYPE, FILENAME, INLINE, TRANSFER_ENC);

	UTL_SMTP.WRITE_DATA(CONN, UTL_TCP.CRLF);
END SMTP_BEGIN_ATTACHMENT;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_WRITE_DATA
	(
	CONN    IN OUT NOCOPY UTL_SMTP.CONNECTION,
	MESSAGE IN CLOB
	) AS

	I   PLS_INTEGER;
	LEN PLS_INTEGER;

BEGIN
	IF MESSAGE IS NULL THEN
		RETURN;
	END IF;
	-- read data from the CLOB and write it to the SMTP connection
	I := 1;
	LEN := DBMS_LOB.GETLENGTH(MESSAGE);
	WHILE (I < LEN) LOOP
		UTL_SMTP.WRITE_DATA(CONN, DBMS_LOB.SUBSTR(MESSAGE, 32000, I));
		I := I + 32000;
	END LOOP;

END SMTP_WRITE_DATA;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_END_ATTACHMENT
	(
	CONN IN OUT NOCOPY UTL_SMTP.CONNECTION,
	LAST IN BOOLEAN := FALSE
	) AS
BEGIN
	UTL_SMTP.WRITE_DATA(CONN, UTL_TCP.CRLF);
	IF (LAST) THEN
		SMTP_WRITE_BOUNDARY(CONN, LAST);
	END IF;
END SMTP_END_ATTACHMENT;

-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_END_MAIL(CONN IN OUT NOCOPY UTL_SMTP.CONNECTION) AS
BEGIN
	UTL_SMTP.CLOSE_DATA(CONN);
END SMTP_END_MAIL;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_END_SESSION(CONN IN OUT NOCOPY UTL_SMTP.CONNECTION) AS
BEGIN
	UTL_SMTP.QUIT(CONN);
END SMTP_END_SESSION;
-----------------------------------------------------------------------------------------------------------
FUNCTION GET_RECIPIENTS
	(
	EMAIL_ID       IN NUMBER,
	RECIPIENT_TYPE IN VARCHAR2
	) RETURN GA.BIG_STRING_TABLE IS

	RECIPIENT_LIST GA.BIG_STRING_TABLE;
	I              BINARY_INTEGER := 1;
	CURSOR RECIPIENTS IS
		SELECT RECIPIENT_ADDRESS
		FROM EMAIL_LOG_RECIPIENT
		WHERE EMAIL_ID = GET_RECIPIENTS.EMAIL_ID
			  AND RECIPIENT_TYPE = GET_RECIPIENTS.RECIPIENT_TYPE
		ORDER BY RECIPIENT_ADDRESS;

BEGIN
	FOR RECIPIENT IN RECIPIENTS LOOP
		RECIPIENT_LIST(I) := RECIPIENT.RECIPIENT_ADDRESS;
		I := I + 1;
	END LOOP;

	RETURN RECIPIENT_LIST;
END GET_RECIPIENTS;
-----------------------------------------------------------------------------------------------------------
PROCEDURE SMTP_SEND_MAIL
	(
	CONN     IN OUT NOCOPY UTL_SMTP.CONNECTION,
	EMAIL_ID IN NUMBER
	) AS

	TO_RECIPIENTS    GA.BIG_STRING_TABLE;
	CC_RECIPIENTS    GA.BIG_STRING_TABLE;
	BCC_RECIPIENTS   GA.BIG_STRING_TABLE;
	EMAIL_REC        EMAIL_LOG%ROWTYPE;
	ATTACHMENT_COUNT BINARY_INTEGER;
	LAST_INDEX       BINARY_INTEGER;
	BEGUN_MAIL       BOOLEAN := FALSE;
	CURSOR ATTACHMENTS IS
		SELECT *
		FROM EMAIL_LOG_ATTACHMENT
		WHERE EMAIL_ID = SMTP_SEND_MAIL.EMAIL_ID
		ORDER BY CONTENT_ORDER;
BEGIN
	SELECT * INTO EMAIL_REC FROM EMAIL_LOG WHERE EMAIL_ID = SMTP_SEND_MAIL.EMAIL_ID;

	SELECT COUNT(*) INTO ATTACHMENT_COUNT FROM EMAIL_LOG_ATTACHMENT WHERE EMAIL_ID = SMTP_SEND_MAIL.EMAIL_ID;

	SELECT MAX(CONTENT_ORDER) INTO LAST_INDEX FROM EMAIL_LOG_ATTACHMENT WHERE EMAIL_ID = SMTP_SEND_MAIL.EMAIL_ID;

	TO_RECIPIENTS := GET_RECIPIENTS(EMAIL_ID, c_TO);
	CC_RECIPIENTS := GET_RECIPIENTS(EMAIL_ID, c_CC);
	BCC_RECIPIENTS := GET_RECIPIENTS(EMAIL_ID, c_BCC);

	-- if there is only one attachment - then it is the message body
	-- so we don't need a multi-part mime type and we write the attachment
	-- directly to the message w/out worrying about attachment boundaries...
	FOR ATTACHMENT IN ATTACHMENTS LOOP
		IF NOT BEGUN_MAIL THEN
			BEGUN_MAIL := TRUE;
			IF ATTACHMENT_COUNT > 1 THEN
				SMTP_BEGIN_MAIL(CONN,
								EMAIL_REC.FROM_ADDRESS,
								EMAIL_REC.SUBJECT,
								TO_RECIPIENTS,
								CC_RECIPIENTS,
								BCC_RECIPIENTS,
								MULTIPART_MIME_TYPE,
								NULL,
								TRUE,
								NULL,
								EMAIL_REC.PRIORITY);
			ELSE
				SMTP_BEGIN_MAIL(CONN,
								EMAIL_REC.FROM_ADDRESS,
								EMAIL_REC.SUBJECT,
								TO_RECIPIENTS,
								CC_RECIPIENTS,
								BCC_RECIPIENTS,
								ATTACHMENT.CONTENT_TYPE,
								ATTACHMENT.FILE_NAME,
								ATTACHMENT.IS_INLINE = 1,
								ATTACHMENT.TRANSFER_ENCODING,
								EMAIL_REC.PRIORITY);
			END IF;
		END IF;

		IF ATTACHMENT_COUNT > 1 THEN
			SMTP_BEGIN_ATTACHMENT(CONN,
								  ATTACHMENT.CONTENT_TYPE,
								  ATTACHMENT.FILE_NAME,
								  ATTACHMENT.IS_INLINE = 1,
								  ATTACHMENT.TRANSFER_ENCODING);
		END IF;

		SMTP_WRITE_DATA(CONN, ATTACHMENT.CONTENTS);

		IF ATTACHMENT_COUNT > 1 THEN
			SMTP_END_ATTACHMENT(CONN, ATTACHMENT.CONTENT_ORDER = LAST_INDEX);
		END IF;

	END LOOP;

	IF BEGUN_MAIL THEN
		SMTP_END_MAIL(CONN);
	END IF;

	UPDATE EMAIL_LOG SET EMAIL_STATUS = c_STATUS_SENT WHERE EMAIL_ID = SMTP_SEND_MAIL.EMAIL_ID;

EXCEPTION
	WHEN OTHERS THEN
		ERRS.LOG_AND_RAISE('Sending e-mail ID = '||EMAIL_ID);
END SMTP_SEND_MAIL;
-----------------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_QUEUED AS
PRAGMA AUTONOMOUS_TRANSACTION;
	EMAIL_IDS   ID_TABLE;
	I           BINARY_INTEGER;
	CONN        UTL_SMTP.CONNECTION;
BEGIN

	UPDATE EMAIL_LOG
	SET EMAIL_STATUS = c_STATUS_IN_PROCESS
	WHERE EMAIL_STATUS = c_STATUS_QUEUED
		  AND NVL(SEND_DATE,CONSTANTS.LOW_DATE) < SYSDATE
	RETURNING ID_TYPE(EMAIL_ID) BULK COLLECT INTO EMAIL_IDS;

	-- release lock and commit status changes
	COMMIT;

	IF EMAIL_IDS.COUNT = 0 THEN
		RETURN; -- nothing to do
	END IF;

	BEGIN
		CONN := SMTP_BEGIN_SESSION();
	EXCEPTION
		WHEN OTHERS THEN
			-- revert status
			BEGIN
				UPDATE EMAIL_LOG
				SET EMAIL_STATUS = c_STATUS_QUEUED
				WHERE EMAIL_ID IN (SELECT ID FROM TABLE(CAST(EMAIL_IDS AS ID_TABLE)));
				-- commit the update
				COMMIT;
			EXCEPTION
				WHEN OTHERS THEN
					ERRS.LOG_AND_CONTINUE;
			END;
			-- re-raise
			ERRS.LOG_AND_RAISE('Starting SMTP session');
	END;

	-- send the e-mails
	I := EMAIL_IDS.FIRST;
	WHILE EMAIL_IDS.EXISTS(I) LOOP
		SMTP_SEND_MAIL(CONN, EMAIL_IDS(I).ID);
		I := EMAIL_IDS.NEXT(I);
	END LOOP;

	SMTP_END_SESSION(CONN);

	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		-- revert status to Pending
		BEGIN
			UPDATE EMAIL_LOG
			SET EMAIL_STATUS = c_STATUS_QUEUED
			WHERE EMAIL_ID IN (SELECT ID FROM TABLE(CAST(EMAIL_IDS AS ID_TABLE)))
				AND EMAIL_STATUS <> c_STATUS_SENT; -- don't revert status of e-mails that were successfully sent
			-- commit the update
			COMMIT;
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE;
		END;
		-- disconnect SMTP session
		BEGIN
			SMTP_RESET_SESSION(CONN);
			SMTP_END_SESSION(CONN);
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE('Ending SMTP Session');
		END;
		-- Re-raise
		ERRS.LOG_AND_RAISE('Sending E-mails');
END PROCESS_QUEUED;
-----------------------------------------------------------------------------------------------------------
PROCEDURE PROCESS_AN_EMAIL(EMAIL_ID IN NUMBER) AS
	PRAGMA AUTONOMOUS_TRANSACTION;
	CONN UTL_SMTP.CONNECTION;
BEGIN
	UPDATE EMAIL_LOG SET EMAIL_STATUS = c_STATUS_IN_PROCESS WHERE EMAIL_ID = PROCESS_AN_EMAIL.EMAIL_ID;

	IF SQL%NOTFOUND THEN
		ROLLBACK; -- roll back autonomous transaction
		RETURN; -- nothing to send because specified email does not exist
	END IF;

	BEGIN
		CONN := SMTP_BEGIN_SESSION();
	EXCEPTION
		WHEN OTHERS THEN
			ERRS.LOG_AND_RAISE('Starting SMTP session');
	END;

	SMTP_SEND_MAIL(CONN, EMAIL_ID);
	COMMIT; -- don't want to rollback record of sending the e-mail if next line throws an exception

	SMTP_END_SESSION(CONN);
	COMMIT;

EXCEPTION
	WHEN OTHERS THEN
		-- disconnect SMTP session
		BEGIN
			SMTP_RESET_SESSION(CONN);
			SMTP_END_SESSION(CONN);
		EXCEPTION
			WHEN OTHERS THEN
				ERRS.LOG_AND_CONTINUE('Ending SMTP Session');
		END;
		-- re-raise (which implicitly rolls back, which will revert the e-mail status if necessary)
		ERRS.LOG_AND_RAISE('Sending E-mail');
END PROCESS_AN_EMAIL;
-----------------------------------------------------------------------------------------------------------
END ML;
/

