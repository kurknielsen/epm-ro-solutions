CREATE OR REPLACE TRIGGER ZAU_ALTER_OBJECT_TRIGGER
	BEFORE CREATE OR DROP OR ALTER ON SCHEMA
DECLARE
	v_SQLTEXT      ORA_NAME_LIST_T;
	v_SQLTEXTCOUNT BINARY_INTEGER;
	v_TEXT         VARCHAR2(32767) := '';
	v_VERB		   VARCHAR2(16);
	v_PLSQL		   VARCHAR2(4000);
BEGIN
	IF ORA_DICT_OBJ_TYPE = 'TRIGGER' AND ORA_DICT_OBJ_NAME LIKE 'ZAU%' THEN
		-- get DDL command text
		v_SQLTEXTCOUNT := ORA_SQL_TXT(v_SQLTEXT);
		FOR I IN 1 .. v_SQLTEXTCOUNT LOOP
			-- Can’t fit anymore in VARCHAR2(4000)?
			IF NVL(LENGTH(v_TEXT), 0) + NVL(LENGTH(v_SQLTEXT(I)), 0) > 32767 THEN
				v_TEXT := v_TEXT || SUBSTR(v_SQLTEXT(I), 1, 32767 - NVL(LENGTH(v_TEXT), 0) - 3) || '...';
				EXIT;
			ELSE
				v_TEXT := v_TEXT || v_SQLTEXT(I);
			END IF;
		END LOOP;
		-- log it
		v_TEXT := REPLACE(v_TEXT,CHR(0),NULL); -- remove errant null-terminator - which is found when
											-- DDL comes in via 'execute immediate'

		IF ORA_SYSEVENT = 'CREATE' THEN
			v_VERB := 'created';
		ELSIF ORA_SYSEVENT = 'DROP' THEN
			v_VERB := 'dropped';
		ELSE -- ALTER
			IF REGEXP_INSTR(UPPER(v_TEXT),'\sENABLE(\s|$)') > 0 THEN
				v_VERB := 'enabled';
			ELSIF REGEXP_INSTR(UPPER(v_TEXT),'\sDISABLE(\s|$)') > 0 THEN
				v_VERB := 'disabled';
			ELSE
				v_VERB := 'altered';
			END IF;
		END IF;

		-- Do this dynamically so this trigger won't get invalidated when LOGS, UT, or other
		-- packages are recreated (when this becomes invalid, nothing else will compile successfully)
		v_PLSQL := 'BEGIN
					LOGS.LOG_NOTICE(:1, p_SOURCE_NAME => :2);
					LOGS.POST_EVENT_DETAILS(:3, :4, :5);
					END;';
		EXECUTE IMMEDIATE v_PLSQL USING IN 'Audit trigger '||v_VERB, IN 'TRIGGER '||ORA_DICT_OBJ_NAME,
										IN 'Trigger DDL', CONSTANTS.MIME_TYPE_TEXT, TO_CLOB(v_TEXT);
	END IF;
END ZAU_ALTER_OBJECT_TRIGGER;
/
