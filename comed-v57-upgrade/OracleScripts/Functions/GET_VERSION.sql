-- Author : ASINGH
-- Revision: $Revision: 1.3 $
-- This function returns the version of the current schema

CREATE OR REPLACE FUNCTION GET_VERSION
RETURN SYSTEM_DICTIONARY.VALUE%TYPE AS

  v_SETTING_NAME SYSTEM_DICTIONARY.SETTING_NAME%TYPE;
  v_MODEL_ID SYSTEM_DICTIONARY.MODEL_ID%TYPE;
  v_MATCH_CASE NUMBER;

BEGIN
  v_SETTING_NAME := 'RTO_VERSION';
  v_MODEL_ID     := 0;
  v_MATCH_CASE   := 0;
  RETURN GET_DICTIONARY_VALUE(v_SETTING_NAME,v_MODEL_ID,'?','?','?','?',v_MATCH_CASE);
END GET_VERSION;
/
