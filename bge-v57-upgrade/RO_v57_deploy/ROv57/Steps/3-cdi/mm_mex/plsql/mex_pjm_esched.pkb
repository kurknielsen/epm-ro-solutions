CREATE OR REPLACE PACKAGE BODY MEX_PJM_ESCHED IS

    -- Author  : KCHOPRA
    -- Created : 12/4/2004 5:43:02 PM
    -- Purpose :

    ----------------------------------------------------------------------------------------------------
    g_DEBUG_EXCHANGES VARCHAR2(8) := 'FALSE';
    g_REPORT_END_LINE CONSTANT VARCHAR2(16) := 'End of Report';
    g_SHORT_DATE_FORMAT CONSTANT VARCHAR2(12) := 'MM/DD/YYYY';
    g_DATETIME_FORMAT VARCHAR2(24);
----------------------------------------------------------------------------------------------------
FUNCTION WHAT_VERSION RETURN VARCHAR2 IS
BEGIN
    RETURN 'Revision: 1.17.5.1.0.7.p7';
END WHAT_VERSION;
---------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REAL_TIME_DAILY_TX_MSRS
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_LINES            PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS             PARSE_UTIL.STRING_TABLE;
    v_IDX              BINARY_INTEGER;

    v_PARTICIPANT_NAME VARCHAR2(64);
    v_TRANSACTION_ID   VARCHAR2(32);
    v_TRANSACTION_TYPE VARCHAR2(64);
    v_SELLER           VARCHAR2(32);
    v_BUYER            VARCHAR2(32);
    v_TRANSACTION_DATE DATE;
    v_ORG_ID           NUMBER;
    v_NERC_TAG         VARCHAR2(32);
    v_OASIS_ID         VARCHAR2(40);
    v_HOUR             NUMBER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    p_RECORDS := MEX_PJM_DAILY_TX_TBL();
    v_IDX     := v_LINES.FIRST;

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        --skip first 5 lines (header info)
         IF v_LINES(v_IDX) IS NOT NULL AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0
                AND v_IDX > 5 THEN
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            --data starts with line 6;
            v_ORG_ID           := v_COLS(1);
            v_PARTICIPANT_NAME := v_COLS(2);
            v_TRANSACTION_DATE := TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT);
            v_TRANSACTION_TYPE := v_COLS(4);
            v_TRANSACTION_ID   := v_COLS(5);
            v_NERC_TAG         := v_COLS(6); --Nerc Tag info
            v_OASIS_ID         := v_COLS(7);
            v_SELLER           := v_COLS(38);
            v_BUYER            := v_COLS(39);

            -- hourly data starts on 8th column and goes until col 32.
            FOR I IN 8 .. 32 LOOP
                --calculate the hour of the day
                IF I IN (8, 9) THEN
                    --hours 1 and 2
                    v_HOUR := I - 7;
                ELSIF I = 10 THEN
                    --second HE 2 column
                    IF TRUNC(v_TRANSACTION_DATE) =
                       TRUNC(DST_FALL_BACK_DATE(v_TRANSACTION_DATE)) THEN
                        v_HOUR := 25;
                    ELSE
                        v_HOUR := NULL; --ignore col 10 for the rest of the year
                    END IF;
                ELSE
                    --hours 3 to 24
                    v_HOUR := I - 8;
                END IF;

                --skip hour 03 for spring DST
               -- IF TRUNC(v_TRANSACTION_DATE) !=
                ---   TRUNC(dst_spring_ahead_date(v_TRANSACTION_DATE)) AND v_HOUR IS NOT NULL THEN
                IF v_HOUR IS NOT NULL AND v_COLS.EXISTS(I) THEN
                        p_RECORDS.EXTEND();
                        p_RECORDS(p_RECORDS.LAST) := MEX_PJM_DAILY_TX(PARTICIPANT_NAME  => v_PARTICIPANT_NAME,
                                                                      ORG_ID            => v_ORG_ID,
                                                                      TRANSACTION_ID    => v_TRANSACTION_ID,
                                                                      TRANSACTION_TYPE  => v_TRANSACTION_TYPE,
                                                                      STATUS            => v_NERC_TAG, --Nerc Tag info
                                                                      UP_TO_CONGESTION  => NULL,
                                                                      OASIS_ID          => v_OASIS_ID,
                                                                      SELLER            => v_SELLER,
                                                                      BUYER             => v_BUYER,
                                                                      TRANSACTION_DATE  => v_TRANSACTION_DATE,
                                                                      HOUR_ENDING       => v_HOUR,
                                                                      AMOUNT            => v_COLS(I),
                                                                      SOURCE_PNODE_NAME => NULL,
                                                                      SOURCE_PNODE_ID   => NULL,
                                                                      SINK_PNODE_NAME   => NULL,
                                                                      SINK_PNODE_ID     => NULL);
                --    END IF;
                END IF;
            END LOOP; --END LOOP OVER HOURS
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP; --END LOOP OVER LINES

EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_REAL_TIME_DAILY_TX_MSRS: ' ||
                     UT.GET_FULL_ERRM;
END PARSE_REAL_TIME_DAILY_TX_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_REAL_TIME_DAILY_TX
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_HEADERS PARSE_UTIL.STRING_TABLE;
    v_COLS PARSE_UTIL.STRING_TABLE;
    v_IDX BINARY_INTEGER;
    v_SEG_IDX BINARY_INTEGER;
    v_DATE DATE;
    v_PARTICIPANT_NAME VARCHAR2(64);

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    p_RECORDS := MEX_PJM_DAILY_TX_TBL();

    --don't parse unless there is more than one line
    IF v_LINES.COUNT > 1 THEN
        v_IDX     := v_LINES.FIRST;
        v_SEG_IDX := 1;

        WHILE v_LINES.EXISTS(v_IDX) LOOP
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            IF UPPER(v_COLS(1)) LIKE 'MARKET PARTICIPANT: %' THEN
                -- found beginning of new segment of report - so reset
                -- segment index
                v_SEG_IDX          := 1;
                v_PARTICIPANT_NAME := SUBSTR(v_LINES(v_IDX), LENGTH('Market Participant: ') + 1);
            END IF;

            -- 2nd line contains the service date for all values that follow
            IF v_SEG_IDX = 2 THEN
                DECLARE
                    v_POS1 BINARY_INTEGER;
                    v_POS2 BINARY_INTEGER;
                BEGIN
                    v_POS1 := INSTR(v_COLS(1), ' for ') + 4;
                    v_POS2 := INSTR(v_COLS(1), ' ', v_POS1 + 1);
                    v_DATE := TO_DATE(TRIM(SUBSTR(v_COLS(1), v_POS1, v_POS2 - v_POS1 + 1)), 'MM/DD/YYYY');
                END;

                -- 3rd line contains column headers for tabular data
                ELSIF v_SEG_IDX = 3 THEN
                    v_HEADERS := v_COLS;

                -- actual data begins on 4th line - everything above is header data
                ELSIF v_SEG_IDX >= 4 AND v_LINES(v_IDX) IS NOT NULL THEN

                      -- hourly data starts on 5th column and goes to end of line
                      FOR v_INDEX IN 5 .. v_HEADERS.LAST LOOP

                          IF v_HEADERS(v_INDEX) IS NOT NULL THEN
                              DECLARE
                                  v_HOUR NUMBER(2);
                              BEGIN
                                  IF UPPER(SUBSTR(v_HEADERS(v_INDEX), 1, 2)) = 'HR' THEN
                                      v_HOUR := TO_NUMBER(SUBSTR(v_HEADERS(v_INDEX), 3));
                                  ELSIF UPPER(SUBSTR(v_HEADERS(v_INDEX), 1, 3)) = 'DST' THEN
                                      v_HOUR := 25;
                                  ELSE
                                      v_HOUR := NULL; -- indicates to skip this column
                                  END IF;
                                IF v_HOUR IS NOT NULL AND v_COLS.EXISTS(v_INDEX) THEN
                                      p_RECORDS.EXTEND();
                                      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_DAILY_TX(PARTICIPANT_NAME => v_PARTICIPANT_NAME,
                                                                                  ORG_ID => NULL,
                                                                                  TRANSACTION_ID => v_COLS(1),
                                                                                  TRANSACTION_TYPE => v_COLS(2),
                                                                                  STATUS => NULL,
                                                                                  UP_TO_CONGESTION => NULL,
                                                                                  OASIS_ID => NULL,
                                                                                  SELLER => v_COLS(3),
                                                                                  BUYER => v_COLS(4),
                                                                                  TRANSACTION_DATE => v_DATE,
                                                                                  HOUR_ENDING => v_HOUR,
                                                                                  AMOUNT => v_COLS(v_INDEX),
                                                                                  SOURCE_PNODE_NAME => NULL,
                                                                                  SOURCE_PNODE_ID => NULL,
                                                                                  SINK_PNODE_NAME => NULL,
                                                                                  SINK_PNODE_ID => NULL);
                                  END IF;
                              END;
                          END IF;

                      END LOOP;

                  END IF;

                  v_SEG_IDX := v_SEG_IDX + 1;
                  v_IDX := v_LINES.NEXT(v_IDX);
              END LOOP;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_REAL_TIME_DAILY_TX: ' || UT.GET_FULL_ERRM;
END PARSE_REAL_TIME_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESCHED_W_WO_LOSSES_MSRS
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

    v_PARTICIPANT_NAME VARCHAR2(64);
    v_ESCHEDULE_ID     VARCHAR2(32);
    v_TRANSACTION_TYPE VARCHAR2(64);
    v_SELLER           VARCHAR2(32);
    v_BUYER            VARCHAR2(32);
    v_TRANSACTION_DATE DATE;
    v_ORG_ID           NUMBER;
    v_STATUS           VARCHAR2(32);
    v_HOUR             NUMBER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    p_RECORDS := MEX_PJM_DAILY_TX_TBL();
    v_IDX     := v_LINES.FIRST;

    --don't parse unless there is more than one line
    IF v_LINES.COUNT > 1 THEN
        WHILE v_LINES.EXISTS(v_IDX) LOOP
            --skip first 5 lines (header info)
            IF v_LINES(v_IDX) IS NOT NULL AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0
                AND v_IDX > 5 THEN
                PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

                --data starts with line 6;
                v_ORG_ID           := v_COLS(1);
                v_PARTICIPANT_NAME := v_COLS(2);
                v_TRANSACTION_DATE := TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT);
                v_ESCHEDULE_ID     := v_COLS(4);
                v_TRANSACTION_TYPE := v_COLS(5);
                v_STATUS           := v_COLS(6);
                v_SELLER           := v_COLS(7);
                v_BUYER            := v_COLS(8);

                -- hourly data starts on 9th column and goes until col 33.
                FOR I IN 9 .. 33 LOOP
                    --calculate the hour of the day
                    IF I IN (9, 10) THEN
                        --hours 1 and 2
                        v_HOUR := I - 8;
                    ELSIF I = 11 THEN
                        --second HE 2 column, which is non-zero on DST fall back
                        IF TRUNC(v_TRANSACTION_DATE) =
                           TRUNC(dst_fall_back_date(v_TRANSACTION_DATE)) THEN
                            v_HOUR := 25;
                        ELSE
                            v_HOUR := NULL; --ignore col 11 for the rest of the year
                        END IF;
                    ELSE
                        --hours 3 to 24
                        v_HOUR := I - 9;
                    END IF;

                    IF v_HOUR IS NOT NULL AND
                       v_COLS.EXISTS(I) THEN
                        p_RECORDS.EXTEND();
                        p_RECORDS(p_RECORDS.LAST) := MEX_PJM_DAILY_TX(PARTICIPANT_NAME  => v_PARTICIPANT_NAME,
                                                                      ORG_ID            => v_ORG_ID,
                                                                      TRANSACTION_ID    => v_ESCHEDULE_ID,
                                                                      TRANSACTION_TYPE  => v_TRANSACTION_TYPE,
                                                                      STATUS            => v_STATUS,
                                                                      UP_TO_CONGESTION  => NULL,
                                                                      OASIS_ID          => NULL,
                                                                      SELLER            => v_SELLER,
                                                                      BUYER             => v_BUYER,
                                                                      TRANSACTION_DATE  => v_TRANSACTION_DATE,
                                                                      HOUR_ENDING       => v_HOUR,
                                                                      AMOUNT            => v_COLS(I),
                                                                      SOURCE_PNODE_NAME => NULL,
                                                                      SOURCE_PNODE_ID   => NULL,
                                                                      SINK_PNODE_NAME   => NULL,
                                                                      SINK_PNODE_ID     => NULL);
                    END IF;

                END LOOP; --END LOOP OVER HOURS
            END IF;
            v_IDX := v_LINES.NEXT(v_IDX);
        END LOOP; --END LOOP OVER LINES
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_ESCHED_W_WO_LOSSES: ' ||
                     UT.GET_FULL_ERRM;
END PARSE_ESCHED_W_WO_LOSSES_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_ESCHED_W_WO_LOSSES
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
v_HEADERS PARSE_UTIL.STRING_TABLE;
v_COLS PARSE_UTIL.STRING_TABLE;
v_IDX BINARY_INTEGER;
v_SEG_IDX BINARY_INTEGER;
v_DATE DATE;
v_DATE_STR VARCHAR2(24);
v_PARTICIPANT_NAME VARCHAR2(64);

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;
    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    p_RECORDS := MEX_PJM_DAILY_TX_TBL();

    --don't parse unless there is more than one line
    IF v_LINES.COUNT > 1 THEN
        v_IDX     := v_LINES.FIRST;
        v_SEG_IDX := 1;

        WHILE v_LINES.EXISTS(v_IDX) LOOP
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            IF UPPER(v_COLS(1)) LIKE 'MARKET PARTICIPANT: %' THEN
                -- found beginning of new segment of report - so reset
                -- segment index
                v_SEG_IDX          := 1;
                v_PARTICIPANT_NAME := SUBSTR(v_LINES(v_IDX), LENGTH('Market Participant: ') + 1);
            END IF;

            -- 2nd line contains the service date for all values that follow
            IF v_SEG_IDX = 2 THEN
                DECLARE
                    v_POS1 BINARY_INTEGER;
                    v_POS2 BINARY_INTEGER;
                BEGIN

                    v_POS1 := INSTR(UPPER(v_LINES(v_IDX)), 'FOR') + 4;
                    v_POS2 := INSTR(UPPER(v_LINES(v_IDX)), ' ', v_POS1);
                    v_DATE_STR := SUBSTR(v_LINES(v_IDX), v_POS1, v_POS2-v_POS1);
                    v_DATE := TO_DATE(v_DATE_STR,'MM/DD/YYYY');
                END;

                -- 3rd line contains column headers for tabular data
                ELSIF v_SEG_IDX = 3 THEN
                    v_HEADERS := v_COLS;

                -- actual data begins on 4th line - everything above is header data
                ELSIF v_SEG_IDX >= 4 AND v_COLS.EXISTS(1) AND v_COLS.EXISTS(2) AND v_COLS(1) IS NOT NULL AND v_COLS(2) IS NOT NULL THEN
                      -- hourly data starts on 5th column and goes to end of line
                      FOR v_INDEX IN 5 .. v_HEADERS.LAST LOOP

                          IF v_HEADERS(v_INDEX) IS NOT NULL THEN
                              DECLARE
                                  v_HOUR NUMBER(2);
                              BEGIN
                                  IF UPPER(SUBSTR(v_HEADERS(v_INDEX), 1, 2)) = 'HR' THEN
                                      v_HOUR := TO_NUMBER(SUBSTR(v_HEADERS(v_INDEX), 3));
                                  ELSIF UPPER(SUBSTR(v_HEADERS(v_INDEX), 1, 3)) = 'DST' THEN
                                      v_HOUR := 25;
                                  ELSE
                                      v_HOUR := NULL; -- indicates to skip this column
                                  END IF;
                                IF v_HOUR IS NOT NULL AND v_COLS.EXISTS(v_INDEX) THEN
                                      p_RECORDS.EXTEND();
                                      p_RECORDS(p_RECORDS.LAST) := MEX_PJM_DAILY_TX(
                                                                v_PARTICIPANT_NAME,
                                                                NULL,
                                                                v_COLS(1),
                                                                v_COLS(2),
                                                                v_COLS(3),
                                                                NULL, NULL,
                                                                v_COLS(4),
                                                                v_COLS(5),
                                                                v_DATE,
                                                                v_HOUR,
                                                                v_COLS(v_INDEX),
                                                                NULL, NULL, NULL, NULL);
                                  END IF;
                              END;
                          END IF;

                      END LOOP;

                  END IF;

                  v_SEG_IDX := v_SEG_IDX + 1;
                  v_IDX := v_LINES.NEXT(v_IDX);
              END LOOP;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_ESCHED_W_WO_LOSSES: ' || UT.GET_FULL_ERRM;
END PARSE_ESCHED_W_WO_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_RECON_DATA
    (
    p_CSV IN CLOB,
    p_RECORDS OUT MEX_PJM_RECON_DATA_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

        v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
        v_COLS  PARSE_UTIL.STRING_TABLE;
        v_IDX   BINARY_INTEGER;
    BEGIN
        p_STATUS := MEX_UTIL.g_SUCCESS;
        PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
        v_IDX     := v_LINES.FIRST;
        p_RECORDS := MEX_PJM_RECON_DATA_TBL();
        WHILE v_LINES.EXISTS(v_IDX) LOOP
            PARSE_UTIL.TOKENS_FROM_STRING(v_LINES(v_IDX), ',', v_COLS);
            -- skip 1st four lines - they have column headers for data below
            -- rss IF v_IDX >= 5 AND v_LINES(v_IDX) IS NOT NULL THEN
            IF v_IDX >= 2 AND v_LINES(v_IDX) IS NOT NULL THEN
                  -- remaining lines contain charge determinant data
                p_RECORDS.EXTEND();
                p_RECORDS(p_RECORDS.LAST) := MEX_PJM_RECON_DATA(v_COLS(1),
                                                                TO_DATE(REPLACE(v_COLS(2),
                                                                                '"',
                                                                                ''),
                                                                        'DD-MON-YY'),
                                                                TO_NUMBER(v_COLS(3)),
                                                                TO_NUMBER(v_COLS(4)));
            END IF;
            v_IDX := v_LINES.NEXT(v_IDX);
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            p_STATUS  := SQLCODE;
            p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_RECON_DATA: ' ||
                                     UT.GET_FULL_ERRM;

    END PARSE_RECON_DATA;

----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_DAILY_TRANS_RPT_MSRS
    (
    p_CSV     IN CLOB,
    p_RECORDS OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS  OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_LINES   PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS    PARSE_UTIL.STRING_TABLE;
    v_IDX     BINARY_INTEGER;

    v_PARTICIPANT_NAME VARCHAR2(64);
    v_TRANSACTION_ID   VARCHAR2(32);
    v_TRANSACTION_TYPE VARCHAR2(64);
    v_SELLER           VARCHAR2(32);
    v_BUYER            VARCHAR2(32);
    v_TRANSACTION_DATE DATE;
    v_ORG_ID           NUMBER;
    v_UP_TO_CONG       VARCHAR2(4);
    v_OASIS_ID         VARCHAR2(40);
    v_HOUR             NUMBER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);
    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_PJM_DAILY_TX_TBL();

    WHILE v_LINES.EXISTS(v_IDX) LOOP
         --skip first 5 lines (header info)
         IF v_LINES(v_IDX) IS NOT NULL AND INSTR(v_LINES(v_IDX),g_REPORT_END_LINE) = 0
                AND v_IDX > 5 THEN
            PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

            --data starts with line 6;
            v_ORG_ID           := v_COLS(1);
            v_PARTICIPANT_NAME := v_COLS(2);
            v_TRANSACTION_DATE := TO_DATE(v_COLS(3), g_SHORT_DATE_FORMAT);
            v_TRANSACTION_TYPE := v_COLS(4);
            v_TRANSACTION_ID   := v_COLS(5);
            v_UP_TO_CONG       := v_COLS(6);
            v_OASIS_ID         := v_COLS(7);
            v_SELLER           := v_COLS(38);
            v_BUYER            := v_COLS(39);

            -- hourly data starts on 8th column and goes until col 32.
            FOR I IN 8 .. 32 LOOP
                --calculate the hour of the day
                IF I IN (8, 9) THEN
                    --hours 1 and 2
                    v_HOUR := I - 7;
                ELSIF I = 10 THEN
                    --second HE 2 column
                    IF TRUNC(v_TRANSACTION_DATE) =
                       TRUNC(dst_fall_back_date(v_TRANSACTION_DATE)) THEN
                        v_HOUR := 25;
                    ELSE
                        v_HOUR := NULL; --ignore col 10 for the rest of the year
                    END IF;
                ELSE
                    --hours 3 to 24
                    v_HOUR := I - 8;
                END IF;

                --skip hour 03 for spring DST
               --IF TRUNC(v_TRANSACTION_DATE) !=
               --    TRUNC(dst_spring_ahead_date(v_TRANSACTION_DATE)) AND v_HOUR IS NOT NULL THEN
                IF v_HOUR IS NOT NULL AND v_COLS.EXISTS(I) THEN
                       p_RECORDS.EXTEND();
                        p_RECORDS(p_RECORDS.LAST) := MEX_PJM_DAILY_TX(PARTICIPANT_NAME  => v_PARTICIPANT_NAME,
                                                                      ORG_ID            => v_ORG_ID,
                                                                      TRANSACTION_ID    => v_TRANSACTION_ID,
                                                                      TRANSACTION_TYPE  => v_TRANSACTION_TYPE,
                                                                      STATUS            => NULL,
                                                                      UP_TO_CONGESTION  => v_UP_TO_CONG,
                                                                      OASIS_ID          => v_OASIS_ID,
                                                                      SELLER            => v_SELLER,
                                                                      BUYER             => v_BUYER,
                                                                      TRANSACTION_DATE  => v_TRANSACTION_DATE,
                                                                      HOUR_ENDING       => v_HOUR,
                                                                      AMOUNT            => v_COLS(I),
                                                                      SOURCE_PNODE_NAME => NULL,
                                                                      SOURCE_PNODE_ID   => NULL,
                                                                      SINK_PNODE_NAME   => NULL,
                                                                      SINK_PNODE_ID     => NULL);
                END IF;
            END LOOP; --END LOOP OVER HOURS

        END IF;
            v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP; --END LOOP OVER LINES


EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_DAILY_TRANS_RPT_MSRS: ' ||
                     UT.GET_FULL_ERRM;

END PARSE_DAILY_TRANS_RPT_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_DAILY_TRANS_RPT
    (
    p_CSV IN CLOB,
    p_RECORDS OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS OUT NUMBER,
    p_MESSAGE OUT VARCHAR2
    ) AS

    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS PARSE_UTIL.STRING_TABLE;
    v_HEADERS PARSE_UTIL.STRING_TABLE;
    v_IDX BINARY_INTEGER;

    v_PARTICIPANT_NAME VARCHAR2(64);
    v_TRANSACTION_ID   VARCHAR2(32);
    v_TRANSACTION_TYPE VARCHAR2(32);
    v_SELLER           VARCHAR2(32);
    v_BUYER            VARCHAR2(32);
    v_TRANSACTION_DATE DATE;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_PJM_DAILY_TX_TBL();

    --don't parse unless there is more than one line
    IF v_LINES.COUNT > 1 THEN
      WHILE v_LINES.EXISTS(v_IDX) LOOP
          -- parse the market participant name out of this line
        v_PARTICIPANT_NAME := SUBSTR(v_LINES(v_IDX),LENGTH('Market Participant: ')+1);
        v_IDX := v_LINES.NEXT(v_IDX);
          -- parse the date out of the line
          -- the line looks like:
          --    Day-ahead Daily Energy Transactions Report for  12/01/2004 Created on 12/2/2004 14:57
          v_TRANSACTION_DATE := TO_DATE(SUBSTR(v_LINES(v_IDX),
                 LENGTH('Day-ahead Daily Energy Transactions Report for  '),
                 11), 'MM/DD/YYYY');

          -- Go to the line with the hours and count the number of columns.
          v_IDX := v_LINES.NEXT(v_IDX);
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
        v_HEADERS := v_COLS;

        -- Go to the start of the data.
          v_IDX := v_LINES.NEXT(v_IDX);

          -- read until line is null
          LOOP
              PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
              EXIT WHEN v_LINES(v_IDX) IS NULL;

              -- map the line to the MEX_PJM_DAILY_TRANS_RPT type
              v_TRANSACTION_ID   := v_COLS(1);
              v_TRANSACTION_TYPE := v_COLS(2);
              v_SELLER           := v_COLS(3);
              v_BUYER            := v_COLS(4);

             -- hourly data starts on 5th column and goes to end of line.
            -- Ignore any column that does not start with HR or DST.
            FOR v_INDEX IN 5 .. v_HEADERS.LAST LOOP

                IF v_HEADERS(v_INDEX) IS NOT NULL THEN
                    DECLARE
                        v_HOUR NUMBER(2);
                    BEGIN
                        IF UPPER(SUBSTR(v_HEADERS(v_INDEX), 1, 2)) = 'HR' THEN
                            v_HOUR := TO_NUMBER(SUBSTR(v_HEADERS(v_INDEX), 3));
                        ELSIF UPPER(SUBSTR(v_HEADERS(v_INDEX), 1, 3)) = 'DST' THEN
                            v_HOUR := 25;
                        ELSE
                            v_HOUR := NULL; -- indicates to skip this column
                        END IF;

                        IF v_HOUR IS NOT NULL AND v_COLS.EXISTS(v_INDEX) THEN
                            p_RECORDS.EXTEND();

                            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_DAILY_TX(PARTICIPANT_NAME => v_PARTICIPANT_NAME,
                                                                                  ORG_ID => NULL,
                                                                                  TRANSACTION_ID => v_TRANSACTION_ID,
                                                                                  TRANSACTION_TYPE => v_TRANSACTION_TYPE,
                                                                                  STATUS => NULL,
                                                                                  UP_TO_CONGESTION => NULL,
                                                                                  OASIS_ID => NULL,
                                                                                  SELLER => v_SELLER,
                                                                                  BUYER => v_BUYER,
                                                                                  TRANSACTION_DATE => v_TRANSACTION_DATE,
                                                                                  HOUR_ENDING => v_HOUR,
                                                                                  AMOUNT => v_COLS(v_INDEX),
                                                                                  SOURCE_PNODE_NAME => NULL,
                                                                                  SOURCE_PNODE_ID => NULL,
                                                                                  SINK_PNODE_NAME => NULL,
                                                                                  SINK_PNODE_ID => NULL);
                        END IF;
                    END;
                END IF;

            END LOOP;
              v_IDX := v_LINES.NEXT(v_IDX);

          END LOOP; -- end loop

          -- skip 7 lines
          FOR I IN 1 .. 8 LOOP
              v_IDX := v_LINES.NEXT(v_IDX);
          END LOOP;

      END LOOP; -- end while
  END IF;
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_DAILY_TRANS_RPT: ' ||
                                 UT.GET_FULL_ERRM;
END PARSE_DAILY_TRANS_RPT;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_CONTRACTS(p_CSV     IN CLOB,
                                                    p_RECORDS OUT MEX_ESCHED_CONTRACT_TBL,
                                                    p_STATUS  OUT NUMBER,
                                                    p_MESSAGE OUT VARCHAR2) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

    v_DATE_FORMAT VARCHAR2(32) := 'DD-MON-YYYY';

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    -- skip the header
  v_IDX     := v_LINES.FIRST;
  v_IDX := v_LINES.NEXT(v_IDX);

    p_RECORDS := MEX_ESCHED_CONTRACT_TBL();

    WHILE v_LINES.EXISTS(v_IDX) LOOP

        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

        p_RECORDS.EXTEND();
        p_RECORDS(p_RECORDS.LAST) := MEX_ESCHED_CONTRACT(CONTRACT_ID                => v_COLS(1),
                                                         CONTRACT_NAME              => v_COLS(2),
                                                         START_DATE                 => TO_DATE(v_COLS(3), v_DATE_FORMAT),
                                                         CONFIRMED_STOP_DATE        => TO_DATE(v_COLS(4), v_DATE_FORMAT),
                                                         PENDING_STOP_DATE          => TO_DATE(v_COLS(5), v_DATE_FORMAT),
                                                         SELLER_NAME                => v_COLS(6),
                                                         BUYER_NAME                 => v_COLS(7),
                                                         SOURCE                     => v_COLS(8),
                                                         SINK                       => v_COLS(9),
                                                         SERVICE_TYPE               => v_COLS(10),
                                                         SCHEDULE_CONFIRMATION_TYPE => v_COLS(11),
                                                         SELLER_FIRST_NAME          => v_COLS(12),
                                                         SELLER_LAST_NAME           => v_COLS(13),
                                                         SELLER_UPDATE_TIME         => TO_DATE(v_COLS(14), g_DATETIME_FORMAT),
                                                         BUYER_FIRST_NAME           => v_COLS(15),
                                                         BUYER_LAST_NAME            => v_COLS(16),
                                                         BUYER_UPDATE_TIME          => TO_DATE(v_COLS(17), g_DATETIME_FORMAT),
                                                         DAY_AHEAD_FLAG             => v_COLS(18),
                                                         COMMENTS                   => v_COLS(19));

      v_IDX := v_LINES.NEXT(v_IDX);
  END LOOP; -- end while
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_CONTRACTS: ' || UT.GET_FULL_ERRM;
END PARSE_CONTRACTS;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_SCHEDULES(p_CSV     IN CLOB,
                                                    p_RECORDS OUT MEX_PJM_ESCHED_SCHEDULE_TBL,
                                                    p_STATUS  OUT NUMBER,
                                                    p_MESSAGE OUT VARCHAR2) AS
    v_LINES               PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS                PARSE_UTIL.STRING_TABLE;
    v_IDX                 BINARY_INTEGER;
    v_SCHEDULE_VALS       MEX_PJM_ESCHED_SCHED_VAL_TBL;
    v_DATE_FORMAT         VARCHAR2(32) := 'DD-MON-YYYY';
    v_CONFIRMED_START_COL NUMBER(2) := 14;
    v_PENDING_START_COL   NUMBER(2) := 39;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX     := v_LINES.FIRST;
    p_RECORDS := MEX_PJM_ESCHED_SCHEDULE_TBL();

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);

        v_SCHEDULE_VALS := MEX_PJM_ESCHED_SCHED_VAL_TBL();
        FOR I IN 0 .. 24 LOOP
            v_SCHEDULE_VALS.EXTEND();
            v_SCHEDULE_VALS(v_SCHEDULE_VALS.LAST) := MEX_PJM_ESCHED_SCHED_VAL(HOUR                 => I,
                                                                                CONFIRMED_SEGMENT_MW => TO_NUMBER(v_COLS(I + v_CONFIRMED_START_COL)),
                                                                                PENDING_SEGMENT_MW   => TO_NUMBER(v_COLS(I + v_PENDING_START_COL)));
        END LOOP;

        p_RECORDS.EXTEND();
        p_RECORDS(p_RECORDS.LAST) := MEX_PJM_ESCHED_SCHEDULE(CONTRACT_ID                => v_COLS(1),
                                                             SCHEDULE_DATE              => TO_DATE(v_COLS(2), v_DATE_FORMAT),
                                                             SELLER_NAME                => v_COLS(3),
                                                             SELLER_STATUS              => v_COLS(4),
                                                             BUYER_NAME                 => v_COLS(5),
                                                             BUYER_STATUS               => v_COLS(6),
                                                             SELLER_FIRST_NAME          => v_COLS(7),
                                                             SELLER_LAST_NAME           => v_COLS(8),
                                                             SELLER_UPDATE_TIME         => TO_DATE(v_COLS(9), g_DATETIME_FORMAT),
                                                             BUYER_FIRST_NAME           => v_COLS(10),
                                                             BUYER_LAST_NAME            => v_COLS(11),
                                                             BUYER_UPDATE_TIME          => TO_DATE(v_COLS(12), g_DATETIME_FORMAT),
                                                             DAY_AHEAD_FLAG             => v_COLS(13),
                                                             SCHEDULE_VAL_TBL           => v_SCHEDULE_VALS,
                                                             CONFIRMED_SEGMENT_TOTAL_MW => TO_NUMBER(CASE WHEN UPPER(TRIM(v_COLS(64))) = 'NULL' THEN NULL ELSE v_COLS(64) END),
                                                             PENDING_SEGMENT_TOTAL_MW   => TO_NUMBER(CASE WHEN UPPER(TRIM(v_COLS(65))) = 'NULL' THEN NULL ELSE v_COLS(65) END));
      v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP; -- end while
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_SCHEDULES: ' || UT.GET_FULL_ERRM;
END PARSE_SCHEDULES;
----------------------------------------------------------------------------------------------------
PROCEDURE PARSE_COMPANIES(p_CSV     IN CLOB,
                            p_RECORDS OUT MEX_PJM_ESCHED_COMPANY_TBL,
                            p_STATUS  OUT NUMBER,
                            p_MESSAGE OUT VARCHAR2) AS
    v_LINES PARSE_UTIL.BIG_STRING_TABLE_MP;
    v_COLS  PARSE_UTIL.STRING_TABLE;
    v_IDX   BINARY_INTEGER;

BEGIN
    p_STATUS := MEX_UTIL.g_SUCCESS;

    PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CSV, v_LINES);

    v_IDX := v_LINES.FIRST;
    -- there's 4 header lines
    v_IDX := v_LINES.NEXT(v_IDX);
    v_IDX := v_LINES.NEXT(v_IDX);
    v_IDX := v_LINES.NEXT(v_IDX);
    v_IDX := v_LINES.NEXT(v_IDX);

    p_RECORDS := MEX_PJM_ESCHED_COMPANY_TBL();

    WHILE v_LINES.EXISTS(v_IDX) LOOP
        PARSE_UTIL.PARSE_DELIMITED_STRING(v_LINES(v_IDX), ',', v_COLS);
        IF v_COLS.COUNT >0 THEN
            p_RECORDS.EXTEND();
            p_RECORDS(p_RECORDS.LAST) := MEX_PJM_ESCHED_COMPANY(PARTICIPANT_NAME => v_COLS(1),
                                                                SHORT_NAME       => v_COLS(2),
                                                                ORG_ID           => v_COLS(3));
        END IF;
        v_IDX := v_LINES.NEXT(v_IDX);
    END LOOP; -- end while
EXCEPTION
    WHEN OTHERS THEN
        p_STATUS  := SQLCODE;
        p_MESSAGE := 'Error in MEX_PJM_ESCHED.PARSE_COMPANIES: ' || UT.GET_FULL_ERRM;
END PARSE_COMPANIES;
----------------------------------------------------------------------------------------------------
    PROCEDURE FETCH_REAL_TIME_DAILY_TX(p_BEGIN_DATE IN DATE,
                               p_END_DATE   IN DATE,
                               p_CRED           IN     MEX_CREDENTIALS,
                               p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
                               p_LOG_ONLY   IN  BINARY_INTEGER,
                               p_RECORDS    OUT MEX_PJM_DAILY_TX_TBL,
                               p_STATUS     OUT NUMBER,
                               p_MESSAGE    OUT VARCHAR2) AS
        v_RESP          CLOB := NULL;
        v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
    BEGIN
        v_PARAMS(MEX_PJM.c_Report_Type) := 'Interchange';
        v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_REAL_TIME_DLY_TRANS;
          v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
        v_PARAMS(MEX_PJM.c_ACTION) := 'download';

          MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                                      'esched', -- p_REQUEST_APP
                                      p_LOGGER,
                                      p_CRED,
                                      p_BEGIN_DATE,
                                      p_END_DATE,
                                      'download',  -- p_REQUEST_DIR
                                      v_RESP,
                                      p_STATUS,
                                      p_MESSAGE,
                                      p_LOG_ONLY => p_LOG_ONLY);
        IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
              PARSE_REAL_TIME_DAILY_TX(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
        END IF;
        IF NOT v_RESP IS NULL THEN
            DBMS_LOB.FREETEMPORARY(v_RESP);
        END IF;
    END FETCH_REAL_TIME_DAILY_TX;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_REAL_TIME_DAILY_TX_MSRS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_CRED           IN     MEX_CREDENTIALS,
    p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
    p_LOG_ONLY   IN  BINARY_INTEGER,
    p_RECORDS    OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2
    ) AS
v_RESP          CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

    v_PARAMS(MEX_PJM.c_Format) := 'c';
    v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_REAL_TIME_DLY_TRANS_MSRS;
    p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);

    MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                                'msrs', -- p_REQUEST_APP
                                p_LOGGER,
                                p_CRED,
                                p_BEGIN_DATE,
                                p_END_DATE,
                                'download',  -- p_REQUEST_DIR
                                v_RESP,
                                p_STATUS,
                                p_MESSAGE,
                                p_LOG_ONLY => p_LOG_ONLY);

    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_REAL_TIME_DAILY_TX_MSRS(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;
END FETCH_REAL_TIME_DAILY_TX_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ESCHED_W_WO_LOSSES_MSRS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_CRED       IN MEX_CREDENTIALS,
    p_LOGGER     IN OUT MM_LOGGER_ADAPTER,
    p_LOG_ONLY   IN BINARY_INTEGER,
    p_RECORDS    OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2
    ) AS
v_RESP          CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
    v_PARAMS(MEX_PJM.c_Format) := 'c';
    v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Version) := 'l';
    v_PARAMS(MEX_PJM.c_Report) := LOWER(REPLACE(g_ET_LOAD_LOSSES_MSRS, ' ', ''));
    p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);

--    MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
--                                'msrs', -- p_REQUEST_APP
--                                p_LOGGER,
--                                p_CRED,
--                                p_BEGIN_DATE,
--                                p_END_DATE,
--                                'download',  -- p_REQUEST_DIR
--                                v_RESP,
--                                p_STATUS,
--                                p_MESSAGE,
--                                p_LOG_ONLY => p_LOG_ONLY,
--                                p_IS_SANDBOX_CONFIG => TRUE
--                               );

    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_ESCHED_W_WO_LOSSES_MSRS(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;

    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;
END FETCH_ESCHED_W_WO_LOSSES_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_ESCHED_W_WO_LOSSES(p_BEGIN_DATE IN DATE,
                                   p_END_DATE   IN DATE,
                                   p_CRED          IN    MEX_CREDENTIALS,
                                   p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
                                   p_LOG_ONLY   IN  BINARY_INTEGER,
                                   p_RECORDS    OUT MEX_PJM_DAILY_TX_TBL,
                                   p_STATUS     OUT NUMBER,
                                   p_MESSAGE    OUT VARCHAR2) AS
v_RESP          CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
   v_PARAMS(MEX_PJM.c_Report_Type) := 'Interchange';
   v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
   v_PARAMS(MEX_PJM.c_Report_Name) := 'Load InSchedule With and Without Losses';
   v_PARAMS(MEX_PJM.c_ACTION) := 'download';

   MEX_PJM.RUN_PJM_BROWSERLESS( v_PARAMS,
                                'esched', -- p_REQUEST_APP
                                p_LOGGER,
                                p_CRED,
                                p_BEGIN_DATE,
                                p_END_DATE,
                                'download',  -- p_REQUEST_DIR
                                v_RESP,
                                p_STATUS,
                                p_MESSAGE,
                                p_LOG_ONLY => p_LOG_ONLY);
   IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
      PARSE_ESCHED_W_WO_LOSSES(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
   END IF;
   IF NOT v_RESP IS NULL THEN
      DBMS_LOB.FREETEMPORARY(v_RESP);
   END IF;

END FETCH_ESCHED_W_WO_LOSSES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_RECON_DATA(p_BEGIN_DATE IN DATE,
                           p_END_DATE   IN DATE,
                           p_CRED           IN     MEX_CREDENTIALS,
                           p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
                           p_LOG_ONLY   IN  BINARY_INTEGER,
                           p_RECORDS    OUT MEX_PJM_RECON_DATA_TBL,
                           p_STATUS     OUT NUMBER,
                           p_MESSAGE    OUT VARCHAR2) AS
        v_RESP          CLOB := NULL;
        v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
    BEGIN
        p_STATUS := GA.SUCCESS;
        v_PARAMS(MEX_PJM.c_Report_Type) := 'Reconciliation';
          v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
        v_PARAMS(MEX_PJM.c_Report_Name) := 'Reconciliation Data';
        v_PARAMS(MEX_PJM.c_ACTION) := 'download';

          MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                                      'esched', -- p_REQUEST_APP
                                      p_LOGGER,
                                      p_CRED,
                                      p_BEGIN_DATE,
                                      p_END_DATE,
                                      'download',  -- p_REQUEST_DIR
                                      v_RESP,
                                      p_STATUS,
                                      p_MESSAGE,
                                      p_LOG_ONLY => p_LOG_ONLY );
        IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
             PARSE_RECON_DATA(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
        END IF;
        IF NOT v_RESP IS NULL THEN
            DBMS_LOB.FREETEMPORARY(v_RESP);
        END IF;
    END FETCH_RECON_DATA;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_DAILY_TRANS_RPT_MSRS
    (
    p_BEGIN_DATE IN DATE,
    p_END_DATE   IN DATE,
    p_CRED           IN     MEX_CREDENTIALS,
    p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
    p_LOG_ONLY   IN  BINARY_INTEGER,
    p_RECORDS    OUT MEX_PJM_DAILY_TX_TBL,
    p_STATUS     OUT NUMBER,
    p_MESSAGE    OUT VARCHAR2
    ) AS
v_RESP          CLOB := NULL;
v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;

BEGIN

    v_PARAMS(MEX_PJM.c_Format) := 'c';
    v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report) := g_ET_DAY_AHEAD_DAILY_TRAN_MSRS;
    p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report);

    MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                                'msrs', -- p_REQUEST_APP
                                p_LOGGER,
                                p_CRED,
                                p_BEGIN_DATE,
                                p_END_DATE,
                                'download',  -- p_REQUEST_DIR
                                v_RESP,
                                p_STATUS,
                                p_MESSAGE,
                                p_LOG_ONLY => p_LOG_ONLY);

    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_DAILY_TRANS_RPT_MSRS(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;
END FETCH_DAILY_TRANS_RPT_MSRS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_DAILY_TRANS_RPT(p_BEGIN_DATE IN DATE,
                                 p_END_DATE  IN DATE,
                                 p_CRED           IN     MEX_CREDENTIALS,
                                 p_LOGGER    IN  OUT MM_LOGGER_ADAPTER,
                                 p_LOG_ONLY   IN  BINARY_INTEGER,
                                 p_RECORDS   OUT MEX_PJM_DAILY_TX_TBL,
                                 p_STATUS    OUT NUMBER,
                                 p_MESSAGE   OUT VARCHAR2) AS
    v_RESP CLOB := NULL;
    v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

    v_PARAMS(MEX_PJM.c_Report_Type) := 'Interchange';
    v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_Report_Name) := g_ET_DAY_AHEAD_DAILY_TRANS;
    p_LOGGER.EXCHANGE_NAME := v_PARAMS(MEX_PJM.c_Report_Name);
    v_PARAMS(MEX_PJM.c_ACTION) := 'download';

    MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                                'esched', -- p_REQUEST_APP
                                p_LOGGER,
                                p_CRED,
                                p_BEGIN_DATE,
                                p_END_DATE,
                                'download',  -- p_REQUEST_DIR
                                v_RESP,
                                p_STATUS,
                                p_MESSAGE,
                                p_LOG_ONLY => p_LOG_ONLY );
    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
       PARSE_DAILY_TRANS_RPT(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
    IF NOT v_RESP IS NULL THEN
       DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;
END FETCH_DAILY_TRANS_RPT;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_CONTRACTS(p_BEGIN_DATE  IN DATE,
                          p_END_DATE   IN  DATE,
                          p_CRED       IN     MEX_CREDENTIALS,
                          p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
                          p_LOG_ONLY   IN  BINARY_INTEGER,
                          p_RECORDS    OUT MEX_ESCHED_CONTRACT_TBL,
                          p_STATUS     OUT NUMBER,
                          p_MESSAGE    OUT VARCHAR2) AS
    v_RESP CLOB := NULL;
    v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
  p_STATUS := GA.SUCCESS;
  v_PARAMS(MEX_PJM.c_Report_Type) := 'Contracts';
  v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
  v_PARAMS(MEX_PJM.c_ACTION) := 'download';

  MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                              'esched', -- p_REQUEST_APP
                              p_LOGGER,
                              p_CRED,
                              p_BEGIN_DATE,
                              p_END_DATE,
                              'download',  -- p_REQUEST_DIR
                              v_RESP,
                              p_STATUS,
                              p_MESSAGE,
                              p_LOG_ONLY => p_LOG_ONLY);
    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_CONTRACTS(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;

END FETCH_CONTRACTS;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_SCHEDULES(p_BEGIN_DATE IN DATE,
                         p_END_DATE   IN DATE,
                         p_CRED       IN  MEX_CREDENTIALS,
                         p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
                         p_LOG_ONLY   IN  BINARY_INTEGER,
                         p_RECORDS    OUT MEX_PJM_ESCHED_SCHEDULE_TBL,
                         p_STATUS     OUT NUMBER,
                         p_MESSAGE    OUT VARCHAR2) AS
    v_RESP CLOB := NULL;
    v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN

    v_PARAMS(MEX_PJM.c_Report_Type) := 'Schedules';
    v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
    v_PARAMS(MEX_PJM.c_ACTION) := 'download';

    MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                                'esched', -- p_REQUEST_APP
                                p_LOGGER,
                                p_CRED,
                                p_BEGIN_DATE,
                                p_END_DATE,
                                'download',  -- p_REQUEST_DIR
                                v_RESP,
                                p_STATUS,
                                p_MESSAGE,
                                p_LOG_ONLY => p_LOG_ONLY);
    IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
        PARSE_SCHEDULES(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
    END IF;
    IF NOT v_RESP IS NULL THEN
        DBMS_LOB.FREETEMPORARY(v_RESP);
    END IF;

END FETCH_SCHEDULES;
----------------------------------------------------------------------------------------------------
PROCEDURE FETCH_COMPANIES(p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_CRED       IN     MEX_CREDENTIALS,
   p_LOGGER     IN  OUT MM_LOGGER_ADAPTER,
   p_LOG_ONLY   IN  BINARY_INTEGER,
   p_RECORDS    OUT MEX_PJM_ESCHED_COMPANY_TBL,
   p_STATUS     OUT NUMBER,
                        p_MESSAGE    OUT VARCHAR2) AS

   v_RESP CLOB := NULL;
   v_PARAMS MEX_Util.Parameter_Map := Mex_Switchboard.c_Empty_Parameter_Map;
BEGIN
   v_PARAMS(MEX_PJM.c_Report_Type) := 'Modeling Data';
   v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
   v_PARAMS(MEX_PJM.c_Report_Name) := 'Company Static Data';
   v_PARAMS(MEX_PJM.c_ACTION) := 'download';

   MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                               'esched', -- p_REQUEST_APP
                               p_LOGGER,
                               p_CRED,
                               p_BEGIN_DATE,
                               p_END_DATE,
                               'download',  -- p_REQUEST_DIR
                               v_RESP,
                               p_STATUS,
                               p_MESSAGE,
                               p_LOG_ONLY => p_LOG_ONLY );
   IF p_STATUS = Mex_Switchboard.c_Status_Success THEN
      PARSE_COMPANIES(v_RESP, p_RECORDS, p_STATUS, p_MESSAGE);
   END IF;
   IF NOT v_RESP IS NULL THEN
      DBMS_LOB.FREETEMPORARY(v_RESP);
   END IF;

END FETCH_COMPANIES;
-------------------------------------------------------------------------------
PROCEDURE PARSE_EDC_HRLY_DERATION
   (
   p_CONTAINER IN CLOB,
   p_LOGGER  IN OUT MM_LOGGER_ADAPTER,
   p_STATUS OUT NUMBER,
   p_MESSAGE OUT VARCHAR2
   ) AS

v_RECORDS PARSE_UTIL.BIG_STRING_TABLE_MP;
v_FIELDS  PARSE_UTIL.STRING_TABLE;
v_INDEX BINARY_INTEGER;
v_DAY DATE;
v_HOUR NUMBER(2);
v_DST NUMBER(1);
v_CUT_DATE DATE;
v_FIRST BOOLEAN := TRUE;
v_COUNT PLS_INTEGER := 0;

BEGIN

   p_LOGGER.LOG_INFO('Parse Hourly Deration Factors.');
   p_STATUS := MEX_UTIL.g_SUCCESS;

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CONTAINER, v_RECORDS);
   p_LOGGER.LOG_INFO('Record Count: ' || TO_CHAR(v_RECORDS.COUNT));

   v_INDEX := v_RECORDS.FIRST;
   WHILE v_RECORDS.EXISTS(v_INDEX) LOOP
      PARSE_UTIL.TOKENS_FROM_STRING(v_RECORDS(v_INDEX), ',', v_FIELDS);
      IF v_FIRST THEN
-- Skip First Record Containing Header Information --
        -- PBM - 10/12 - Update for new InSchedule - Needs Uppercase
         IF v_FIELDS.COUNT > 0 AND UPPER(v_FIELDS(1)) LIKE '%DAY%' THEN
            v_FIRST := FALSE;
         END IF;
      ELSE
         v_DAY := TO_DATE(v_FIELDS(1),'MM/DD/YY');
         v_HOUR := TO_NUMBER(v_FIELDS(2));
         v_DST := TO_NUMBER(v_FIELDS(3));
         IF v_DAY = TRUNC(DST_SPRING_AHEAD_DATE(v_DAY)) AND v_HOUR = 2 THEN
-- Input Skips Hour 3, But For Storing In RO As Hour-Ending Skip Hour 2 --
            v_CUT_DATE := v_DAY + (v_HOUR + 1) / 24;
         ELSE
            v_CUT_DATE := v_DAY + v_HOUR / 24;
         END IF;
         v_CUT_DATE := TO_CUT(v_CUT_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE);
         IF v_DST = 1 THEN v_CUT_DATE := v_CUT_DATE + 1 / 24; END IF;
         INSERT INTO PJM_EDC_HRLY_LOSS_DER_FACTOR(DAY, HOUR_ENDING, DST, CUT_DATE, EDC, LOSS_DERATION_FACTOR)
         VALUES(v_DAY, v_HOUR, v_DST, v_CUT_DATE, v_FIELDS(4), TO_NUMBER(v_FIELDS(5)));
         v_COUNT := v_COUNT + 1;
      END IF;
      v_INDEX := v_RECORDS.NEXT(v_INDEX);
   END LOOP;

   IF v_COUNT > 0 THEN COMMIT; END IF;
   p_LOGGER.LOG_INFO('Parse Hourly Deration Factors Complete.  Number Of Output Records Parsed: ' || TO_CHAR(v_COUNT));

EXCEPTION
   WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_EDC_HRLY_DERATION: ' || SQLERRM;
      p_LOGGER.LOG_ERROR(p_MESSAGE);
END PARSE_EDC_HRLY_DERATION;
-------------------------------------------------------------------------------
PROCEDURE FETCH_EDC_HRLY_DERATION
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_CRED       IN MEX_CREDENTIALS,
   p_LOGGER     IN OUT MM_LOGGER_ADAPTER,
   p_LOG_ONLY   IN BINARY_INTEGER,
   p_STATUS     OUT NUMBER,
   p_MESSAGE    OUT VARCHAR2
   ) AS

v_RESPONSE CLOB := NULL;
v_PARAMS MEX_UTIL.PARAMETER_MAP := MEX_SWITCHBOARD.c_EMPTY_PARAMETER_MAP;

BEGIN

   p_LOGGER.LOG_INFO('Fetch Hourly Deration Factors.');
   v_PARAMS(MEX_PJM.c_Report_Type) := 'Transmission Losses';
   v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
   v_PARAMS(MEX_PJM.c_Report_Name) := 'EDC Hourly Loss Deration Factor';
   v_PARAMS(MEX_PJM.c_ACTION) := 'download';
   p_LOGGER.LOG_INFO('Call MEX-PJM Browserless Interface');
   MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS, 'esched', p_LOGGER, p_CRED, p_BEGIN_DATE, p_END_DATE, 'download', v_RESPONSE, p_STATUS, p_MESSAGE, p_LOG_ONLY);
   p_LOGGER.LOG_INFO('MEX-PJM Browserless Interface Return Message: ' || INITCAP(REPLACE(p_MESSAGE,' =',':')));
   IF p_STATUS = MEX_SWITCHBOARD.c_STATUS_SUCCESS THEN
      p_LOGGER.LOG_INFO('Received ' || TO_CHAR(DBMS_LOB.GETLENGTH(v_RESPONSE)) || ' Bytes.');
-- Parse The Content Into Structures To Be Consumed By RO --
      PARSE_EDC_HRLY_DERATION(v_RESPONSE, p_LOGGER, p_STATUS, p_MESSAGE);
   END IF;
   IF v_RESPONSE IS NOT NULL THEN
      DBMS_LOB.FREETEMPORARY(v_RESPONSE);
   END IF;
   p_LOGGER.LOG_INFO('Fetch Hourly Deration Factors Complete.');

END FETCH_EDC_HRLY_DERATION;
-------------------------------------------------------------------------------
PROCEDURE SUBMIT_ESCHEDULE
   (
   p_BEGIN_DATE IN DATE,
   p_END_DATE   IN DATE,
   p_LOG_ONLY   IN NUMBER,
   p_CRED       IN MEX_CREDENTIALS,
   p_LOGGER     IN OUT MM_LOGGER_ADAPTER,
   p_CLOB       IN CLOB,
   p_STATUS     OUT NUMBER,
   p_MESSAGE    OUT VARCHAR2
   ) AS

v_RESP CLOB;
v_PARAMS MEX_UTIL.PARAMETER_MAP := MEX_SWITCHBOARD.c_EMPTY_PARAMETER_MAP;

BEGIN

   v_PARAMS(MEX_PJM.c_Report_Type) := 'Submit-eSchedule';
   v_PARAMS(MEX_PJM.c_DEBUG) := g_DEBUG_EXCHANGES;
   v_PARAMS(MEX_PJM.c_ACTION) := 'upload';

   MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS,
                               'esched', -- p_REQUEST_APP
                               p_LOGGER,
                               p_CRED,
                               p_BEGIN_DATE,
                               p_END_DATE,
                               'upload',  -- p_REQUEST_DIR
                               v_RESP,
                               p_STATUS,
                               p_MESSAGE,
                               p_CLOB,
                               'html',
                               p_LOG_ONLY => p_LOG_ONLY);

--   MEX_PJM.RUN_PJM_BROWSERLESS(v_PARAMS, 'esched', p_LOGGER, p_CRED, NULL, NULL, 'upload', v_RESP, p_STATUS, p_MESSAGE, p_CLOB, 'html', p_LOG_ONLY);
   p_MESSAGE := DBMS_LOB.SUBSTR(PARSE_UTIL.HTML_RESPONSE_TO_TEXT(v_RESP),32767,1);
   DBMS_LOB.FREETEMPORARY(v_RESP);

END SUBMIT_ESCHEDULE;
----------------------------------------------------------------------------------------------------
--@@Begin Implementation Override--
PROCEDURE PARSE_DERATION_FACTORS(p_CONTAINER IN CLOB, p_STATUS OUT NUMBER, p_MESSAGE OUT VARCHAR2) AS
v_RECORDS PARSE_UTIL.BIG_STRING_TABLE_MP;
v_FIELDS  PARSE_UTIL.STRING_TABLE;
v_INDEX BINARY_INTEGER;
v_DAY DATE;
v_HOUR NUMBER(2);
v_DST NUMBER(1);
v_CUT_DATE DATE;
v_FIRST BOOLEAN := TRUE;
v_COUNT PLS_INTEGER := 0;
BEGIN
   LOGS.LOG_INFO('Parse Hourly Deration Factors.');
   p_STATUS := MEX_UTIL.g_SUCCESS;

   PARSE_UTIL.PARSE_CLOB_INTO_LINES(p_CONTAINER, v_RECORDS);
   LOGS.LOG_INFO('Record Count: ' || TO_CHAR(v_RECORDS.COUNT));

   v_INDEX := v_RECORDS.FIRST;
   WHILE v_RECORDS.EXISTS(v_INDEX) LOOP
      PARSE_UTIL.TOKENS_FROM_STRING(v_RECORDS(v_INDEX), ',', v_FIELDS);
      IF v_FIRST THEN
-- Skip First Record Containing Header Information --
        -- PBM - 10/12 - Update for new InSchedule - Needs Uppercase
         IF v_FIELDS.COUNT > 0 AND UPPER(v_FIELDS(1)) LIKE '%DAY%' THEN
            v_FIRST := FALSE;
         END IF;
      ELSE
         v_DAY := TO_DATE(v_FIELDS(1),'MM/DD/YY');
         v_HOUR := TO_NUMBER(v_FIELDS(2));
         v_DST := TO_NUMBER(v_FIELDS(3));
         IF v_DAY = TRUNC(DST_SPRING_AHEAD_DATE(v_DAY)) AND v_HOUR = 2 THEN
-- Input Skips Hour 3, But For Storing In RO As Hour-Ending Skip Hour 2 --
            v_CUT_DATE := v_DAY + (v_HOUR + 1) / 24;
         ELSE
            v_CUT_DATE := v_DAY + v_HOUR / 24;
         END IF;
         v_CUT_DATE := TO_CUT(v_CUT_DATE, MM_PJM_UTIL.g_PJM_TIME_ZONE);
         IF v_DST = 1 THEN v_CUT_DATE := v_CUT_DATE + 1 / 24; END IF;
         INSERT INTO PJM_EDC_HRLY_LOSS_DER_FACTOR(DAY, HOUR_ENDING, DST, CUT_DATE, EDC, LOSS_DERATION_FACTOR)
         VALUES(v_DAY, v_HOUR, v_DST, v_CUT_DATE, v_FIELDS(4), TO_NUMBER(v_FIELDS(5)));
         v_COUNT := v_COUNT + 1;
      END IF;
      v_INDEX := v_RECORDS.NEXT(v_INDEX);
   END LOOP;

   IF v_COUNT > 0 THEN COMMIT; END IF;
   LOGS.LOG_INFO('Parse Hourly Deration Factors Complete.  Number Of Output Records Parsed: ' || TO_CHAR(v_COUNT));

EXCEPTION
   WHEN OTHERS THEN
      p_STATUS := SQLCODE;
      p_MESSAGE := 'Error in MEX_PJM_ESCHED_ML.PARSE_EDC_HRLY_DERATION: ' || SQLERRM;
      LOGS.LOG_ERROR(p_MESSAGE);
END PARSE_DERATION_FACTORS;
--@@End Implementation Override--

BEGIN
    g_DATETIME_FORMAT := GET_DICTIONARY_VALUE('Datetime Format',0,'MarketExchange','PJM');
END MEX_PJM_ESCHED;
/

