CREATE OR REPLACE FUNCTION GET_SYSTEM_STATE_NUM
	(
	p_SETTING_NAME IN VARCHAR2
	) RETURN NUMBER IS
-- Revision: $Revision: 1.2 $
	v_RTN NUMBER;
BEGIN
	SELECT NUMBER_VAL
	INTO v_RTN
	FROM SYSTEM_STATE
	WHERE SETTING_NAME = p_SETTING_NAME;
	RETURN v_RTN;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.LOG_AND_CONTINUE(p_EXTRA_MESSAGE => 'Setting '||p_SETTING_NAME||' not found.', p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
		RETURN NULL;
END;
/
CREATE OR REPLACE FUNCTION GET_SYSTEM_STATE_STR
	(
	p_SETTING_NAME IN VARCHAR2
	) RETURN VARCHAR2 IS
-- Revision: $Revision: 1.2 $
	v_RTN SYSTEM_STATE.STRING_VAL%TYPE;
BEGIN
	SELECT STRING_VAL
	INTO v_RTN
	FROM SYSTEM_STATE
	WHERE SETTING_NAME = p_SETTING_NAME;
	RETURN v_RTN;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.LOG_AND_CONTINUE(p_EXTRA_MESSAGE => 'Setting '||p_SETTING_NAME||' not found.', p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
		RETURN NULL;
END;
/
CREATE OR REPLACE FUNCTION GET_SYSTEM_STATE_DATE
	(
	p_SETTING_NAME IN VARCHAR2
	) RETURN DATE IS
-- Revision: $Revision: 1.2 $
	v_RTN DATE;
BEGIN
	SELECT DATE_VAL
	INTO v_RTN
	FROM SYSTEM_STATE
	WHERE SETTING_NAME = p_SETTING_NAME;
	RETURN v_RTN;
EXCEPTION
	WHEN NO_DATA_FOUND THEN
		ERRS.LOG_AND_CONTINUE(p_EXTRA_MESSAGE => 'Setting '||p_SETTING_NAME||' not found.', p_LOG_LEVEL => LOGS.c_LEVEL_DEBUG);
		RETURN NULL;
END;
/
