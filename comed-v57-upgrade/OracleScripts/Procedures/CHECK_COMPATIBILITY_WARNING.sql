CREATE OR REPLACE PROCEDURE CHECK_COMPATIBILITY_WARNING
	(
	p_UI_VERSION IN VARCHAR2,
	p_IS_COMPATIBLE OUT NUMBER,
	p_SCHEMA_VERSION OUT VARCHAR2
	) AS
	
	v_IS_COMP	APPLICATION_USER_PREFERENCES.VALUE%TYPE;
	v_LOG_LEVEL	PROCESS_LOG_EVENT.EVENT_LEVEL%TYPE;
BEGIN

	p_IS_COMPATIBLE := 1;
	p_SCHEMA_VERSION := GET_DICTIONARY_VALUE('RTO_VERSION');
		
	IF NOT REGEXP_LIKE(UPPER(p_SCHEMA_VERSION), UPPER('^' || p_UI_VERSION)) THEN
	-- VERSIONS DON'T APPEAR TO MATCH UP, CHECK THE USER PREFERENCES
	
		SP.GET_USER_PREFERENCE('Website',p_UI_VERSION,'?','?','versionCompatible',v_IS_COMP);
		
		IF v_IS_COMP IS NULL OR NOT UT.BOOLEAN_FROM_STRING(v_IS_COMP) THEN
			p_IS_COMPATIBLE := 0;
			v_LOG_LEVEL := LOGS.c_LEVEL_WARN;
		ELSE
			v_LOG_LEVEL := LOGS.c_LEVEL_DEBUG;
		END IF;

		-- log the warning
		LOGS.LOG_EVENT(v_LOG_LEVEL, 'Client version "'||p_UI_VERSION||'" may be incompatible with database version "'||p_SCHEMA_VERSION||'"');
	END IF;

END CHECK_COMPATIBILITY_WARNING;
/