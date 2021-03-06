CREATE OR REPLACE FUNCTION VALUE_AT_KEY_3
	(
	p_KEY1 IN VARCHAR,
	p_KEY2 IN VARCHAR,
	p_KEY3 IN VARCHAR,
	p_MATCH_CASE IN NUMBER := 0
	) RETURN VARCHAR IS
--Revision: $Revision: 1.24 $

-- DEPRECATED 9/27/2004 Use GET_DICTIONARY_VALUE for current function.
--	Answer the value associated with the key.

v_MODULE VARCHAR2(64);
v_KEY1 VARCHAR2(64);
v_KEY2 VARCHAR2(64);
v_KEY3 VARCHAR2(64);
v_SETTING_NAME VARCHAR2(64);

BEGIN
	TRANSLATE_OLD_DICTIONARY_KEYS(p_KEY1,p_KEY2,p_KEY3,v_MODULE,v_KEY1,v_KEY2,v_KEY3,v_SETTING_NAME);
	RETURN GET_DICTIONARY_VALUE(v_SETTING_NAME,0,v_MODULE,v_KEY1,v_KEY2,v_KEY3,p_MATCH_CASE);
END VALUE_AT_KEY_3;
/
