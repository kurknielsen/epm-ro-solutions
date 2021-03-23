CREATE OR REPLACE TYPE MM_CREDENTIALS_SET AS OBJECT
(
	CREDENTIALS		MEX_CREDENTIALS_TBL,
	LOGGER			MM_LOGGER_ADAPTER,
	IDX				NUMBER,
	MEMBER FUNCTION HAS_NEXT RETURN BOOLEAN,
	MEMBER FUNCTION GET_NEXT(SELF IN OUT MM_CREDENTIALS_SET) RETURN MEX_CREDENTIALS,
	CONSTRUCTOR FUNCTION MM_CREDENTIALS_SET (p_CREDENTIALS MEX_CREDENTIALS_TBL,
											 p_LOGGER MM_LOGGER_ADAPTER)
											RETURN SELF AS RESULT
)
/
CREATE OR REPLACE TYPE BODY MM_CREDENTIALS_SET IS
----------------------------------------------------------------------------
MEMBER FUNCTION HAS_NEXT RETURN BOOLEAN IS
BEGIN
	RETURN SELF.CREDENTIALS.EXISTS(SELF.IDX);
END HAS_NEXT;
----------------------------------------------------------------------------
MEMBER FUNCTION GET_NEXT(SELF IN OUT MM_CREDENTIALS_SET) RETURN MEX_CREDENTIALS IS
v_CRED MEX_CREDENTIALS;
BEGIN
	v_CRED := SELF.CREDENTIALS(SELF.IDX);
	-- update logger for current credentials
	SELF.LOGGER.EXTERNAL_ACCOUNT_NAME := v_CRED.EXTERNAL_ACCOUNT_NAME;
	-- increment internal counter to next set of credentials
	SELF.IDX := SELF.CREDENTIALS.NEXT(SELF.IDX);

	RETURN v_CRED;
END GET_NEXT;
----------------------------------------------------------------------------
CONSTRUCTOR FUNCTION MM_CREDENTIALS_SET (p_CREDENTIALS MEX_CREDENTIALS_TBL,
										 p_LOGGER MM_LOGGER_ADAPTER)
										RETURN SELF AS RESULT IS
BEGIN
	SELF.CREDENTIALS := p_CREDENTIALS;
	SELF.LOGGER := p_LOGGER;
	SELF.IDX := p_CREDENTIALS.FIRST;

	RETURN;
END;
----------------------------------------------------------------------------
END;
/
