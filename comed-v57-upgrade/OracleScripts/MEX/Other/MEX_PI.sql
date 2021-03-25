CREATE OR REPLACE package MEX_PI is

  -- Author  : LDUMITRIU
  -- Created : 05/11/2005 1424:57I:48
  -- Purpose :

 ----------------------------------------------------------------------------------------------------
 PROCEDURE PARSE_TXT_FILES(p_CSV     IN CLOB,
                            p_RECORDS OUT MEX_CA_PI_DATA_TBL,
                            p_MESSAGE OUT VARCHAR2);

end MEX_PI;
/

CREATE OR REPLACE package body MEX_PI IS

-------------------------------------------------------------------------------------------------------
  PROCEDURE PARSE_TXT_FILES(p_CSV     IN CLOB,
                            p_RECORDS OUT MEX_CA_PI_DATA_TBL,
                            p_MESSAGE OUT VARCHAR2) AS

    v_LINES    PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS     PARSE_UTIL.STRING_TABLE;
    v_IDX      BINARY_INTEGER;
    v_DATE     DATE;
    v_STR_DATE VARCHAR2(22);
    v_VALUE    NUMBER;

  BEGIN

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST + 1; --Skip the first line -- it has binary stuff on it.
    p_RECORDS := MEX_CA_PI_DATA_TBL();

    WHILE v_LINES.EXISTS(v_IDX) LOOP
      PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
--	  ut.debug_trace(V_lines(v_idx));

      --take care of dates that do not have time
      v_STR_DATE := v_COLS(2);
      IF LENGTH(v_STR_DATE) = 9 OR LENGTH(v_STR_DATE) = 10 THEN
        v_STR_DATE := v_STR_DATE || ' 12:00:00 AM';
      END IF;

      v_DATE := TO_DATE(v_STR_DATE, 'MM/DD/YYYY HH:MI:SS AM');

      --take care of values in scientific notation
      v_VALUE := TO_NUMBER(v_COLS(3));
      v_VALUE := ROUND(v_VALUE,3);


      /*IF (v_VALUE(3)) LIKE '%E+' THEN
        v_VALUE := TRUNC(v_VALUE,-10);
      END IF;*/

      p_RECORDS.EXTEND();
      p_RECORDS(p_RECORDS.LAST) := MEX_CA_PI_DATA(TAG => v_COLS(1),
                                                  DTE => v_DATE,
                                                  VAL => v_VALUE);

      v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      p_MESSAGE := 'Error in MEX_PI.PARSE_TXT_FILES: ' || SQLERRM;

  END PARSE_TXT_FILES;
  -----------------------------------------------------------------------------------------------------
end MEX_PI;
/

