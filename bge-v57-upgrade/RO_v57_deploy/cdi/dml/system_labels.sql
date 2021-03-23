DECLARE
   PROCEDURE INSERT_SYSTEM_LABEL
      (
      p_MODEL_ID IN NUMBER,
      p_MODULE IN VARCHAR,
      p_KEY1 IN VARCHAR,
      p_KEY2 IN VARCHAR,
      p_KEY3 IN VARCHAR,
      p_POSITION IN NUMBER,
      p_VALUE IN VARCHAR,
      p_CODE IN VARCHAR,
      p_IS_DEFAULT IN NUMBER,
      p_IS_HIDDEN IN NUMBER
      ) AS
   v_POSITION NUMBER;
   v_COUNT NUMBER;
   BEGIN
      SELECT COUNT(VALUE) INTO v_COUNT
      FROM SYSTEM_LABEL
      WHERE MODEL_ID = p_MODEL_ID
         AND MODULE = p_MODULE
         AND KEY1 = p_KEY1
         AND KEY2 = p_KEY2
         AND KEY3 = p_KEY3
         AND VALUE = p_VALUE;
       -- already have that value in table, so we can safely skip it
      IF v_COUNT > 0 THEN RETURN; END IF;
       -- determine proper position that won't collide w/ existing entry
      SELECT NVL(MAX(POSITION),-1)+1 INTO v_POSITION
      FROM SYSTEM_LABEL
      WHERE MODEL_ID = p_MODEL_ID
         AND MODULE = p_MODULE
         AND KEY1 = p_KEY1
         AND KEY2 = p_KEY2
         AND KEY3 = p_KEY3;
      INSERT INTO SYSTEM_LABEL ( MODEL_ID, MODULE, KEY1, KEY2, KEY3, POSITION, VALUE, CODE, IS_DEFAULT, IS_HIDDEN ) VALUES (p_MODEL_ID, p_MODULE, p_KEY1, p_KEY2, p_KEY3, v_POSITION, p_VALUE, p_CODE, p_IS_DEFAULT, p_IS_HIDDEN);
   EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN NULL;
      WHEN OTHERS THEN RAISE;
   END INSERT_SYSTEM_LABEL;
BEGIN
   INSERT_SYSTEM_LABEL(1, 'Scheduling', 'TransactionDialog', 'Combo Lists', 'Transaction Type', 14, 'Ancillary', 14, 0, 0);
END;
/ 
