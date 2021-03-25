CREATE OR REPLACE FUNCTION GET_DICTIONARY_VALUE
	(
	p_SETTING_NAME IN VARCHAR2,
	p_MODEL_ID IN NUMBER := 0,
	p_MODULE IN VARCHAR2 := '?',
	p_KEY1 IN VARCHAR2 := '?',
	p_KEY2 IN VARCHAR2 := '?',
	p_KEY3 IN VARCHAR2 := '?',
	p_MATCH_CASE IN NUMBER := 0
	) RETURN VARCHAR2 AS
--Revision: $Revision: 1.4 $

--	Answer the value associated with the key.

v_VALUE SYSTEM_DICTIONARY.VALUE%TYPE;
BEGIN

	IF p_MATCH_CASE = 0 THEN
    		SELECT VALUE INTO v_VALUE
    		FROM SYSTEM_DICTIONARY
		   	WHERE MODEL_ID = p_MODEL_ID
    			AND UPPER(MODULE) = UPPER(p_MODULE)
    			AND UPPER(KEY1) = UPPER(p_KEY1)
    	   		AND UPPER(KEY2) = UPPER(p_KEY2)
    			AND UPPER(KEY3) = UPPER(p_KEY3)
    			AND UPPER(SETTING_NAME) = UPPER(p_SETTING_NAME);
	ELSE --Match Case
    		SELECT VALUE INTO v_VALUE
    		FROM SYSTEM_DICTIONARY
		   	WHERE MODEL_ID = p_MODEL_ID
    			AND MODULE = p_MODULE
    			AND KEY1 = p_KEY1
    	   		AND KEY2 = p_KEY2
    			AND KEY3 = p_KEY3
    			AND SETTING_NAME = p_SETTING_NAME;
	END IF;

	RETURN v_VALUE;

	EXCEPTION
		WHEN NO_DATA_FOUND THEN
        	IF p_MODEL_ID <> 0 THEN
            	RETURN GET_DICTIONARY_VALUE(p_SETTING_NAME, 0, p_MODULE, p_KEY1, p_KEY2, p_KEY3, p_MATCH_CASE);
            ELSE
				RETURN NULL;
            END IF;

END GET_DICTIONARY_VALUE;
/
