CREATE OR REPLACE PROCEDURE TRANSLATE_OLD_DICTIONARY_KEYS
	(
	p_KEY1 IN VARCHAR2,
	p_KEY2 IN VARCHAR2,
	p_KEY3 IN VARCHAR2,
	p_NEW_MODULE OUT VARCHAR2,
	p_NEW_KEY1 OUT VARCHAR2,
	p_NEW_KEY2 OUT VARCHAR2,
	p_NEW_KEY3 OUT VARCHAR2,
	p_NEW_SETTING_NAME OUT VARCHAR2
	) AS
--Revision: $Revision: 1.4 $

--	For backwards compatibility, the old functions that accessed the SYSTEM_DICTIONARY
--  table are still supported. This function translates between the old keys (the 3 input
--  parameters) and the new one for the table's current structure (the 5 output parameters)

BEGIN
	-- module should be the first non-blank ('?') key, unless there is only one non-blank
	-- key - in which case that it the setting name and module is blank.
	p_NEW_MODULE := 
             	CASE
             	WHEN p_KEY1 <> '?' THEN
            		CASE
            		WHEN p_KEY2 <> '?' OR p_KEY3 <> '?' THEN
            			p_KEY1
            		ELSE
            			'?'
            		END
            	WHEN p_KEY2 <> '?' THEN
            		CASE
            		WHEN p_KEY3 <> '?' THEN
            			p_KEY2
            		ELSE
            			'?'
            		END
            	ELSE
            		'?'
            	END;
	-- if there were all three keys specified, then the new key1 is the middle one
	p_NEW_KEY1 := 
            	CASE
            	WHEN p_KEY1 <> '?' AND p_KEY2 <> '?' AND p_KEY3 <> '?' THEN
            		p_KEY2
            	ELSE
            		'?'
            	END;
	-- there were only three keys before - now there are five. So these next two are always
	-- going to be blank
	p_NEW_KEY2 := '?';
	p_NEW_KEY3 := '?';
	-- the setting name is the last key specified
	p_NEW_SETTING_NAME := 
            	CASE
            	WHEN p_KEY1 <> '?' THEN
            		CASE
            		WHEN p_KEY3 <>'?' THEN
            			p_KEY3
            		WHEN p_KEY2 <> '?' THEN
            			p_KEY2
            		ELSE
            			p_KEY1
            		END
            	WHEN p_KEY2 <> '?' THEN
            		CASE
            		WHEN p_KEY3 <> '?' THEN
            			p_KEY3
            		ELSE
            			p_KEY2
            		END	
            	ELSE
            		p_KEY3
            	END;
END TRANSLATE_OLD_DICTIONARY_KEYS;
/
