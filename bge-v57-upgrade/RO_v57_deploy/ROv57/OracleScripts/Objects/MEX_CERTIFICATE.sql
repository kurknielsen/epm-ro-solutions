CREATE OR REPLACE TYPE MEX_CERTIFICATE AS OBJECT
(
	-- base64-encoded and encrypted certificate file 
	CERTIFICATE			CLOB,
	-- base64-encoded and encrypted certificate password
	CERT_PASSWORD		VARCHAR2(32),
	-- the type of certificate - should be 'Authentication' or 'Signature'
	CERT_TYPE			VARCHAR2(32)
);
/
CREATE OR REPLACE TYPE MEX_CERTIFICATE_TBL AS TABLE OF MEX_CERTIFICATE;
/
