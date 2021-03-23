CREATE OR REPLACE FUNCTION CDI_GET_DATE_RANGE_INTERVAL
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE IN DATE,
   p_INTERVAL IN VARCHAR2,
   p_INCREMENT IN NUMBER DEFAULT 1
   ) RETURN DATE_COLLECTION PIPELINED AS
-- p_INTERVAL (yearly - Y, monthly - M, daily - D, hourly - H)
-- p_INCREMENT is a number to possibly increment by every 2 or 3 days or months
v_DATE DATE := p_BEGIN_DATE;
BEGIN
   IF SUBSTR(UPPER(p_INTERVAL), 1, 1) = 'Y' THEN
      LOOP
         PIPE ROW(v_DATE);
         v_DATE := ADD_MONTHS(v_DATE, 12 * p_INCREMENT);
         EXIT WHEN v_DATE > p_END_DATE;
      END LOOP;
   ELSIF SUBSTR(UPPER(p_INTERVAL), 1, 1) = 'M' THEN
      LOOP
         PIPE ROW(v_DATE);
         v_DATE := ADD_MONTHS(v_DATE, 1 * p_INCREMENT);
         EXIT WHEN v_DATE > p_END_DATE;
      END LOOP;
   ELSIF SUBSTR(UPPER(p_INTERVAL), 1, 1) = 'D' THEN
      LOOP
         PIPE ROW(v_DATE);
         v_DATE := v_DATE + (1 * p_INCREMENT);
         EXIT WHEN v_DATE > p_END_DATE;
      END LOOP;
   ELSIF SUBSTR(UPPER(p_INTERVAL), 1, 1) = 'H' THEN
      LOOP
         PIPE ROW(v_DATE);
         v_DATE := v_DATE + (1/24 * p_INCREMENT);
         EXIT WHEN v_DATE > p_END_DATE;
      END LOOP;
   END IF;
   RETURN;
END CDI_GET_DATE_RANGE_INTERVAL;
/
